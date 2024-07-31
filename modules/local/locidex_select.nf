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
    tuple val(meta), val(top_hit), path(contigs)
    path manifest // This is a json file to be parsed

    output:
    tuple val(meta), path(contigs), path(scheme), val(paired_p), emit: db_data
    tuple val(meta), path(output_config), emit: config_data

    exec:
    if(params.allele_scheme == null && params.locidex.allele_database == null){
        exit 1, "Allele calling is enabled but there is no allele scheme or locidex allele database location present."
    }

    // Tokenize the "top_hit" or species value to identify all relevant match parts of the string
    def species_data = top_hit.split('_|\s')
    species_data = species_data*.toLowerCase()

    // De-serialize the manifest file from the database location
    def jsonSlurper = new JsonSlurper()
    def data = file(manifest)
    String json_data = data.text
    def allele_db_data = jsonSlurper.parseText(json_data)
    def allele_db_keys = allele_db_data.keySet() as String[]

    // Tokenize all database keys for lookup of species top hit in the database names
    def databases = []
    def shortest_token = Integer.MAX_VALUE
    for(i in allele_db_keys){
        def db_tokens = i.split('_|\s')
        for(g in db_tokens){
            def tok_size = g.size()
            if(tok_size < shortest_entry){
                shortest_entry = tok_size
            }
        }
        databases.add(new Tuple(db_tokens*.toLowerCase(), i))
    }
    def db_tokes_pos = 0
    def db_key = 1

    // Remove spurious characters from tokenized string
    species_data = species_data.findAll { it.size() >= shortest_entry }

    // A default locidex database is set to null as there should be no option set
    // a default database can be set, but this process will then be skipped
    def db_opt = null


    paired_p = false // Sets predicate for db identification as false by default
    scheme = null
    output_config = task.workDir.resolve("${meta.id}_${params.locidex.db_config_output_name}")
    for(db in databases){
        def match_size = db[db_tokes_pos].size() // Prevent single token matches
        def tokens = tokenize_values(species_data, match_size)
        def db_found = compare_lists(db[db_tokes_pos], tokens)
        if(db_found){
            def selected_db = select_locidex_db_path(database[db[db_key]], db[db_key])
            /// Write selected allele database info to a file for the final report
            write_config_data(selected_db, output_config)
            scheme = join_database_paths(selected_db)
            paired_p = db_found
            break
        }
    }

    if(!paired_p){
        write_config_data(["No database selected."], output_config)
    }

    paired_p
    scheme
    output_config
}


def write_config_data(db_data, output_name){
    /// Config data for db to use
    def json_data = new JsonBuilder(db_data).toPrettyString()
    def output_file = file(output_config_path).newWriter()
    output_file.write(json_data)
    output_file.close()
}

def join_database_paths(db_path){
    /// Database paths are relative to the manifest, hopefully this will not offer many issue on cloud executors
    def input_dir_path = [params.allele_database, db_path[params.locidex.manifest_db_path]].join(File.separator)
    return file(input_dir_path, checkIfExists: true)
}

def select_locidex_db_path(db_values, db_name){
    /// Select the optimal locidex database by parsing date fields for the organism
    /// Database fields are labeled by date, so the most recent will be shown
    /// Db value is an object containing the path fields and the config fields
    /// db_values: is the list of database config information in the manifest


    def database_entries = db_values.size()
    def default_date = new SimpleDateFormat(params.locidex.date_format_string).parse("0001-01-01")
    def max_date = default_date
    def max_date_idx = 0
    def idx = 0
    def dates = []

    // Validate all input fields
    for(value in db_values){
        if(!value.containsKey(params.locidex.manifest_db_path)){
            exit 1, "Missing path value in locidex config for: ${db_name}"
        }
        if(!value.containsKey(params.locidex.manifest_config_key)){
            exit 1, "Missing config data for locidex database entry: ${db_name}"
        }
        if(!value[params.locidex.manifest_config_key].containsKey(params.locidex.database_config_value_date)){
            exit 1, "Missing date created value for locidex database entry: ${db_name}"
        }
        def date_value = value[params.locidex.manifest_config_key][params.locidex.database_config_value_date]
        def date_check = new SimpleDateFormat(params.locidex.date_format_string).parse(date_value)
        dates << date_check
        if(date_check > max_date){
            max_date = date_check
            max_date_idx = idx
        }
        idx += 1
    }
    if(idx == 1){
        return db_values[0]
    }

    def max_date_count = dates.count(max_date)
    if(max_date_count > 1){
        exit 1, "There are multiple versions of the most recent database for ${db_name}. Mikrokondo could not determine the best database to pick."
    }
    return db_values[max_date_idx]
}


def tokenize_values(species, match_size){
    // Tokenize the species values to find the right match
    def tokens = []
    def adj_match_size = match_size - 1
    for(int spot = 0; spot < species.size()-adj_match_size; spot = spot + 1){
        tokens.add(species[spot..spot + adj_match_size])
    }
    return tokens
}

def compare_lists(db_tokens, species_tokens){
    // compare the various tokens till the right db is found
    //! This allows for matches on shorter than optimal matches
    for(i in species_tokens){
        if(i == db_tokens){
            return true
        }
    }
    return false
}

