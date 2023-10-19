// Process for selecting the relevant pointfinder DB for StarAMR

process IDENTIFY_POINTDB {
    tag "$meta.id"
    label "process_low"
    errorStrategy 'terminate'

    input:
    tuple val(meta), val(species)

    output:
    tuple val(meta), val(point_finder_val), emit: pointfinder_db

    exec:
    def species_data = species.split('_|\s') // tokenize string
    species_data = species_data*.toLowerCase()

    def databases = []
    // tokenize database options
    for(i in params.staramr.point_finder_dbs){
        def db_tokens = i.split('_|\s')
        databases.add(db_tokens*.toLowerCase())
    }

    def db_opt = null

    // Find exact match
    for(int db in 0..databases.size()-1){
        //println databases[db]
        def match_size = databases[db].size() // if match size is a single value, only need to match one value
        // tile the species list
        def tokens = tokenize_values(species_data, match_size)
        def db_found = compare_lists(databases[db], tokens)
        if(db_found){
            //println db_found
            //println params.staramr.point_finder_dbs[db]
            //println databases[db]
            db_opt = params.staramr.point_finder_dbs[db]
            break
        }
    }
    point_finder_val = db_opt
}


def tokenize_values(species, match_size){
    def tokens = []
    def adj_match_size = match_size - 1
    for(int spot = 0; spot < species.size()-adj_match_size; spot = spot + 1){
        tokens.add(species[spot..spot + adj_match_size])
    }
    return tokens
}

def compare_lists(db_tokens, species_tokens){
    // compare the various tokens till the right db is found
    for(i in species_tokens){
        if(i == db_tokens){
            return true
        }
    }
    return false
}
