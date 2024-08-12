/*
Locidex provides the option to select a database from a group of databases, by
using a manifest file. To prevent copying all databases each time an allele database
needs to be selected this file will read only the "manifest" file of the databases and
to pick the correct allele scheme.


Locidex Manifest is setup as:
    {
        db_name: [
            {
                "path": path/to/db/relative/to/manifest
                # DB Config data, the newest db data will be selected as versions are not standardized
                "config": {
                    "db_name": "Locidex Database 1",
                    "db_version": "1.0.0",
                    "db_date": "yyyy-MM-dd",
                    "db_author": "test1",
                    "db_desc": "test1",
                    "db_num_seqs": 53,
                    "is_nucl": true,
                    "is_prot": true,
                    "nucleotide_db_name": "nucleotide",
                    "protein_db_name": "protein"
                }
            }
        ]
    }
*/

import groovy.json.JsonSlurper
import groovy.json.JsonBuilder
import java.text.SimpleDateFormat


process LOCIDEX_SELECT {
    tag "$meta.id"
    label "process_single"

    input:
    tuple val(meta), val(top_hit), val(contigs)
    // TODO update locidex to allow for file passed in
    val manifest // This is a json file to be parsed
    val config // optional path to a database file

    output:
    tuple val(meta), val(contigs), val(scheme), val(paired_p), emit: db_data
    tuple val(meta), path(output_config), emit: config_data

    exec:

    report_name = "${meta.id}_${params.locidex.db_config_output_name}"
    output_config = task.workDir.resolve(report_name)

    if(params.allele_scheme == null && params.locidex.allele_database == null){
        error("Allele calling is enabled but there is no allele scheme or locidex allele database location present.")
    }

    if(config){ // non null channel should evaluate to true
        // Create output summary data for a locidex allele database if an allele scheme is passed in directly
        def jsonSlurper = new JsonSlurper()
        String json_data = config.text
        def locidex_config_data = jsonSlurper.parseText(json_data)
        write_config_data(locidex_config_data, output_config)
        scheme = params.allele_scheme // reset the schem path to the passed allele scheme
        paired_p = true
        output_config
        paired_p
        scheme

    }else{

        // Tokenize the "top_hit" or species value to identify all relevant match parts of the string
        def species_data = top_hit.split('_|\s').collect{ it.toLowerCase() }

        // De-serialize the manifest file from the database location
        def jsonSlurper = new JsonSlurper()
        String json_data = manifest.text
        def allele_db_data = jsonSlurper.parseText(json_data)
        def allele_db_keys = allele_db_data.keySet() as String[]

        // Tokenize all database keys for lookup of species top hit in the database names
        def shortest_entry = Integer.MAX_VALUE
        def databases = allele_db_keys.collect{
                            key ->  // Tokenize the database key and normalize the values into lowercase
                                    def db_tokens = key.split('_|\s').collect{ it.toLowerCase() }

                                    // Get the shortest string from the tokenized string (db_tokens), db_tokens.min
                                    // iterates over the tokens, and returns the shortest entry based on its size. Size
                                    // is called again to to get the length of the shortest string, then Math.min is called
                                    // to compare the current shortest_entry with what was identified in the db_tokens
                                    // updating the variable in the outer scope with the smallest value
                                    shortest_entry = Math.min(shortest_entry, db_tokens.min{ it.size() }.size())
                                    new Tuple(db_tokens, key) }

        def DB_TOKES_POS = 0
        def DB_KEY = 1

        // Remove characters that are shorter then the shortest database token as they cannot be part of a match
        // This eliminates tokens that are part of a taxonomic string like `_s` or `spp`
        species_data = species_data.findAll { it.size() >= shortest_entry }

        def DB_SELECTION_SCORE_POS = 1
        def DB_DATA_POS = 0
        def MINIMUM_MATCH_SCORE = 1.0
        def matched_databases = databases.collect {
            db ->
                def match_size = db[DB_TOKES_POS].size()
                def tokens = window_string(species_data, match_size)
                def score_out = compare_lists(db[DB_TOKES_POS], tokens)
                new Tuple(db[DB_KEY],  score_out * match_size) // Add size multiplier to prioritize longer exact matches
        }.sort{dp -> dp[DB_SELECTION_SCORE_POS]}.findAll{ dt -> dt[DB_SELECTION_SCORE_POS] >= MINIMUM_MATCH_SCORE }.reverse() // Sort is in descending order by default


        paired_p = false // Sets predicate for db identification as false by default
        scheme = null


        /*
            A database "configuration" is required for mikrokondos continuation as it simplifies final reporting.
            `selected_db` contains default values required for reporting a locidex database notifying the user that a
            database could not be selected.
        */
        def selected_db = [(params.locidex.manifest_config_key): [(params.locidex.manifest_config_name): "No Database Selected", (params.locidex.database_config_value_date): "No Database Selected", (params.locidex.manifest_config_version): "No Database Selected"]]

        def too_many_databases = matched_databases.size() >= 2 && matched_databases[0][DB_SELECTION_SCORE_POS] == matched_databases[1][DB_SELECTION_SCORE_POS] ? true : false

        if(too_many_databases){
            log.info "Cannot pick an optimal locidex database for ${meta.id}. Tied between ${matched_databases[0][DB_DATA_POS]} and ${matched_databases[1][DB_DATA_POS]}"
        }

        if(!matched_databases.isEmpty() && !too_many_databases){
            // Check first and last databases to verify an optimal match is chosen
            paired_p = true
            def best_database = matched_databases[0][DB_DATA_POS]
            selected_db = select_locidex_db_path(allele_db_data[best_database], best_database)
            scheme = join_database_paths(selected_db)
        }

        // pulling out the config value so that it matches the default selected db format
        // and to remove a level of nesting from the output JSON as it is unnecessary
        write_config_data(selected_db[params.locidex.manifest_config_key], output_config)
        output_config
    }

}


def write_config_data(db_data, output_name){
    /// Config data for db to use
    def json_data = new JsonBuilder(db_data).toPrettyString()
    def output_file = file(output_name).newWriter()
    output_file.write(json_data)
    output_file.close()
}

def join_database_paths(db_path){
    /// Database paths are relative to the manifest, hopefully this will not offer many issue on cloud executors
    def input_dir_path = [params.lx_allele_database, db_path[params.locidex.manifest_db_path]].join(File.separator)
    return input_dir_path
}


def validate_locidex_db(db_entry, db_name){
    /// Validate the required fields of a locidex database
    /// Errors if fields are missing

    if(!db_entry.containsKey(params.locidex.manifest_db_path)){
        error("Missing path value in locidex config for: ${db_name}")
    }

    if(!db_entry.containsKey(params.locidex.manifest_config_key)){
        error("Missing config data for locidex database entry: ${db_name}")
    }

    if(!db_entry[params.locidex.manifest_config_key].containsKey(params.locidex.manifest_config_name)){
        error ("Missing name value in locidex config for: ${db_name}")
    }

    if(!db_entry[params.locidex.manifest_config_key].containsKey(params.locidex.database_config_value_date)){
        error("Missing date created value for locidex database entry: ${db_name}")
    }

    return true
}

def select_locidex_db_path(db_values, db_name){
    /// Select the optimal locidex database by parsing date fields for the organism
    /// Database fields are labeled by date, so the most recent will be shown
    /// Db value is an object containing the path fields and the config fields
    /// db_values: is the list of database config information in the manifest


    def database_entries = db_values.size()
    def default_date = new SimpleDateFormat(params.locidex.date_format_string).parse("0001-01-01")
    def max_date = default_date
    def max_date_entry = null // No null check at the end as there is no way this value can be null without an error being raised elsewhere
    def dates = []
    // Validate all input fields
    for(idx in 0..<database_entries){
        def db_entry = db_values[idx]

        validate_locidex_db(db_entry, db_name)

        def date_value = db_entry[params.locidex.manifest_config_key][params.locidex.database_config_value_date]
        def date_check = null
        try{
            date_check = new SimpleDateFormat(params.locidex.date_format_string).parse(date_value)
        }catch (java.text.ParseException e){
            error("Date value ${date_value} does not meet format string required of ${params.locidex.date_format_string}")
        }

        dates.add(date_check)
        if(date_check > max_date){
            max_date = date_check
            max_date_entry = db_entry
        }
    }

    def max_date_count = dates.count(max_date)
    if(max_date_count > 1){
        error("There are multiple versions of the most recent database for ${db_name}. Mikrokondo could not determine the best database to pick.")
    }else if (max_date_count == 0){
        error("There are not databases created after the year ${default_date}. Please set the allele database parameter, or adjust the date your database was created in the 'config.json'")
    }

    return max_date_entry
}


def window_string(species, match_size){
    /*
        Generates all array slices of length match_size from the species array.

        e.g. spieces is an array of: ["1", "2", "3", "4"] and match_size is 2 the output will be.
            [
                ["1", "2"],
                ["2", "3"],
                ["3", "4"]
            ]
    */
    def tiles = []
    def adj_match_size = match_size - 1
    for(int spot = 0; spot < species.size()-adj_match_size; spot = spot + 1){
        tiles.add(species[spot..spot + adj_match_size])
    }
    return tiles
}

def compare_lists(db_string, species_tokens){
    /* compare the various windows till the right db is found

        The db_string is an array of tokenized db values e.g. ["1", "2"] and the species would be tokenized into
        would be [["1", "2"], ["2", "3"]], it would search through the windows of the spcies to see what matches
        the database value best e.g. ["1", "2"].

        This would match as true, however this allows for multiple matches to be found with similarly named databases.

        To get a "better match" we will create a simple score of the the "match size" / length of the the db string tokens

        lengths of the slices differ based on the number of tokens parsed from the  `top-hit` value passed to the pipeline.
    */

    for(window in species_tokens){
        if(window == db_string){
            // Can return on first match as any subsequent match would have the same score
            def match_val = window.size() / db_string.size().toFloat()
            return match_val
        }
    }
    return 0.0
}

