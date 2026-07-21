// Process for selecting the relevant pointfinder DB for StarAMR

process IDENTIFY_STARAMR_SPECIES_PARAMS {
    tag "$meta.id"
    label "process_single"

    input:
    tuple val(meta), val(species)
    val(fallthrough_staramr_params)

    output:
    tuple val(meta), val(point_finder_val), val(staramr_param_val),  emit: staramr_param_val

    exec:
    if(workflow.stubRun){
        // may need to add in a return statment here
        point_finder_val = "stub"
        return
    }
    def species_data = species.split('_|\s') // tokenize string
    species_data = species_data*.toLowerCase()

    def overly_large_number = Integer.MAX_VALUE
    def databases = []
    // tokenize database options
    def shortest_entry = overly_large_number
    def point_finder_db_keys = params.staramr.point_finder_dbs.keySet() as List
    for(i in point_finder_db_keys){
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
            db_opt = point_finder_db_keys[db]
            break
        }
    }
    point_finder_val = db_opt

    // Define staramr parameters based on genus-level classification
    // No species level classification for staramr specific parameters
    def qc_report_options = params.staramr.point_finder_dbs.getOrDefault(point_finder_val, [params.QCReport.fallthrough])
    def qc_report_options_size = qc_report_options.size()

    if(qc_report_options_size == 0){
        /* No options identified and the possible selected options are empty, this corresponds to a case
         * where a point_finder database is identified. But no custom QC parameters are specified in the 
         * QCReport section for the organism. For instance helicobacter_pylori is not configured currently.
         * */

        log.info "Sample ${meta.id} will use the pointfinder database ${db_opt} and default QC parameters."
        staramr_param_val = "${fallthrough_staramr_params}"
    }else if(qc_report_options_size == 1){
            /* Only one option for values to be used here. This corresponds to Salmonella or Escherichia where
             * There is only one set of optoins to use.
             * */
        def qcreport_genus = qc_report_options[0] // Use the first and only option
        log.info "Sample ${meta.id} will use the starAMR custom parameters for ${qcreport_genus.search}"
        staramr_param_val = StarAMRFunctions.staramr_arg_builder(qcreport_genus)
    }else{
        /* Many possible options to pick from, and need to identify the best possible option. This coencides with the
         * case of Campylobacter where there could be seperate QC criteria for the two organisms. 
         *
         * If no best option is identified a warning can be written to screen and default parameters will be used.
         */

        def map_possible_values_tmp = qc_report_options.collectEntries{
            // This map is temporary and used to match the interface of the functions used in the later report functions.
                qc_opt -> [qc_opt.search, qc_opt]
            }
        def search_phrases = ReportFunctions.qc_params_species(map_possible_values_tmp)
        def shortest_token_search_params = ReportFunctions.get_shortest_token(search_phrases)
        def selected_species = ReportFunctions.get_species(species, search_phrases, shortest_token_search_params, params) // This function returns the fallthrough value to be used if no value is found
        if(selected_species[0] == params.QCReport.fallthrough.search){
            // Check if fallthrough value is set to trigger log message
            log.warn "Sample ${meta.id} could not identify species specific QC parameters to use for ${selected_species[0]}." 
        }else{
            log.info "Sample ${meta.id} will use the starAMR custom parameters for ${selected_species[0]}"
        }

        log.info "Sample ${meta.id} will use the pointfinder database ${db_opt} and default QC parameters."
        // qcreport_genus is already declared above, as groovy scopes lexically it seems
        def qcreport_genus = selected_species[1] // will either be species specific or the fallthrough categories
        staramr_param_val = StarAMRFunctions.staramr_arg_builder(qcreport_genus)

    }

}

//def staramr_arg_builder(qc_params){
//    /*
//     * qc_params: The map of the qc report parameters for the selected organism.
//     * */
//
//    def staramr_arguments = [
//        ["--genome-size-lower-bound", "staramr_genome_size_lower_bound"],
//        ["--genome-size-upper-bound", "staramr_genome_size_upper_bound"],
//        ["--percent-length-overlap-resfinder", "staramr_percent_length_overlap_resfinder"],
//        ["--percent-length-overlap-pointfinder", "staramr_percent_length_overlap_pointfinder"]
//    ]
//    def output_args = []
//    for(i in staramr_arguments){
//            def identified_value = qc_params[i[0]]
//            if(identified_value){
//                output_args << i[0]
//                output_args << identified_value
//            }
//        }
//    return output_args.join(' ')
//}


def tokenize_values(species, match_size){
    // Create tiled values to match on, e.g. input is Salmonella enterica entrica -> [Salmonella, Salmonella enterica, Salmonella enterica enterica]
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
