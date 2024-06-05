// Process for selecting the relevant pointfinder DB for StarAMR

process IDENTIFY_POINTDB {
    tag "$meta.id"
    label "process_single"

    fair true
    input:
    tuple val(meta), val(species)

    output:
    tuple val(meta), val(point_finder_val), emit: pointfinder_db

    exec:
    if(workflow.stubRun){
        // may need to add in a return statment here
        point_finder_val = "stub"
        return
    }
    def species_data = species.split('_|\s') // tokenize string
    species_data = species_data*.toLowerCase()

    def overly_large_number = 100000
    def databases = []
    // tokenize database options
    def shortest_entry = overly_large_number
    for(i in params.staramr.point_finder_dbs){
        def db_tokens = i.split('_|\s')

        for(g in db_tokens){
            def tok_size = g.size()
            if(tok_size < shortest_entry){
                shortest_entry = tok_size
            }
        }

        databases.add(db_tokens*.toLowerCase())
    }

    // Remove spurious characters and strings that may affect database identification e.g. Entercoccus_B -> it would get rid of the B
    species_data = species_data.findAll { it.size() >= shortest_entry }

    def db_opt = params.staramr.point_finder_db_default

    // Find exact match
    for(int db in 0..databases.size()-1){
        def match_size = databases[db].size() // if match size is a single value, only need to match one value
        // tile the species list
        def tokens = tokenize_values(species_data, match_size)
        def db_found = compare_lists(databases[db], tokens)
        if(db_found){
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
