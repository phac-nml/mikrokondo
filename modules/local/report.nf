/*Generate mikrokondo report

*/

import groovy.json.JsonSlurper
import groovy.json.JsonBuilder
import java.nio.file.Paths


process REPORT{
    tag "Report Generation"
    label "process_single"

    input:
    val test_in

    output:
    path output_file_path, emit: final_report

    exec:
    if (workflow.stubRun){
        // may need to add in a return here
        def report_name = "final_report.json"
        def output_file_path = Paths.get("$task.workDir", report_name)
        output_file = file(output_file_path).newWriter()
        output_file.write("")
        output_file.close()
        return
    }

    def sample_data = [:] // Where to aggregate and create json data
    def data_stride = 3 // report values added in groups of three, e.g sample meta info, parameters, output file of interest
    def headers_list = 'headers' // ! TODO this string exists twice, need to fix that
    def arr_size = test_in.size()
    def qc_species_tag = "QCParameterSelection"
    def mikrokondo_version = workflow.manifest.version
    def mk_version_fields = "MikrokondoVersion"
    for(long i = 0; i < arr_size; i=i+data_stride){
        def meta_data = test_in[i]
        def report_tag = test_in[i+1]
        def report_value = test_in[i+2]

        if(!sample_data.containsKey(meta_data.sample)){
            sample_data[meta_data.sample] = [:]
            sample_data[meta_data.sample]["meta"] = [:]
        }

        update_map_values(sample_data, meta_data, "metagenomic")
        update_map_values(sample_data, meta_data, "id")
        update_map_values(sample_data, meta_data, "sample")
        update_map_values(sample_data, meta_data, "external_id")
        update_map_values(sample_data, meta_data, "assembly")
        update_map_values(sample_data, meta_data, "hybrid")
        update_map_values(sample_data, meta_data, "single_end")
        update_map_values(sample_data, meta_data, "merge")
        update_map_values(sample_data, meta_data, "downsampled")

        if(!sample_data[meta_data.sample].containsKey(meta_data.id)){
            sample_data[meta_data.sample][meta_data.id] = [:]
        }

        if(report_value instanceof Path){
            def extension = report_value.getExtension()
            if(!check_file_params(report_tag, extension)){
                continue
            }
            def output_data = parse_data(report_value, extension, report_tag, headers_list)
            if(output_data){
                report_value = output_data
            }
        }
        sample_data[meta_data.sample][meta_data.id][report_tag.report_tag] = report_value
        // Add in mikrokondo version field for each sample so that it can be stored externally with the sample
        sample_data[meta_data.sample][meta_data.id][mk_version_fields] = mikrokondo_version
    }


    def search_phrases = qc_params_species()

    // Add in quality information in place
    generate_qc_data(sample_data, search_phrases, qc_species_tag)
    create_action_call(sample_data, qc_species_tag)


    def json_converted_data = new JsonBuilder(sample_data).toPrettyString()
    def report_name = "final_report.json"

    output_file_path = task.workDir.resolve(report_name)
    output_file = file(output_file_path).newWriter()
    output_file.write(json_converted_data)
    output_file.close()

}


def generate_coverage_data(sample_data, bp_field, species){
    /*Generate QC fields based base pairs count
    sample_data: is the sample to get data for
    bp_field: is the base count data from seqtk
    */
    sample_data.each {
        entry -> if(entry.key != "meta" && entry.key != "QualityAnalysis"){ // TODO add to constants
            def base_counts_p = false
            def base_pairs = null
            def base_pairs_t = traverse_values(entry.value, bp_field)
            if(species == null){
                return null // break statement is not allowed here...
            }

            if(base_pairs_t != null){
                base_counts_p = true
                base_pairs = base_pairs_t.toLong()
            }

            def q_length = recurse_keys(entry.value, params.QCReportFields.length)
            if(q_length != null){ // incase the value returned is null
                    q_length = q_length.toLong()
            }

            // Add naive coverage value if required
            if(base_counts_p && q_length != null){
                def cov = base_pairs / q_length;
                entry.value[params.coverage_calc_fields.auto_cov] = cov.round(2)
            }

            // Add fixed genome coverage for species if desired
            def species_data_pos = 1;
            if(base_counts_p
                && species[species_data_pos] != null
                && species[species_data_pos].containsKey("fixed_genome_size")
                && species[species_data_pos].fixed_genome_size != null){

                def length = species[species_data_pos].fixed_genome_size.toLong()
                def cov = base_pairs / length
                entry.value[params.coverage_calc_fields.fixed_cov] = cov.round(2)
            }

        }
    }
    return sample_data
}


def n50_nrcontigs_decision(qual_data, nr_cont_p, n50_p, qual_message, reisolate, resequence){
    /*
        qual_data: the quality data string
        nr_cont_p: nr_contigs failed (true means it failed)
        n50_p: n50_value failed (true means it failed)
        qual_message: array of quality messges to be used
        reisolate: int of reisolation score
        resequence: int of reseqeunce score
    */

    if(nr_cont_p && n50_p){
        // both fialed :(
        if(qual_data && qual_data.containsKey("nr_contigs") && qual_data.nr_contigs.low){
            if(qual_data.n50_value.low){

                reseqeunce += 1
            }

        }else{
            if(!qual_data.n50_value.low){
                reisolate += 1
                resequence += 1
            }else{
                resequence += 1
            }
        }
    }else if(nr_cont_p){
        if(qual_data.nr_contigs.low){
            resequence += 1
        }else{
            resequence += 1
        }
    }else if(n50_p){
        if(!qual_data.n50_value.low){
            resequence += 1
        }
    }
    return [reisolate, resequence]

}


def populate_qual_message(qual_data){
    /*Takes in quality data, and converts it to a summary
    */
    def msg = ["Quality Summary"]
    for(i in qual_data){
        if(i.value instanceof Map && i.value.containsKey("message")){
            msg.add(i.value.message)
        }else{
            msg.add(i.value)
        }

    }
    return msg
}

// Action: Reisolate and resequence, resequence, all good.
def create_action_call(sample_data, species_tag){
    /*Define criteria used to create base sketches

    TODO Need to test a falthrough sample (e.g. unspeciated to see what happens)

    TODO if this become unwieldly, I should make a matrix of passed conditions that can look up the correct value
    based on conditions passed.

    ***** LOGIC ****
    contamination checkm resequence and reisolate

    // Are reads provided?
        // Coverage low, need to resequence

        // Low quality, need to resequence

    // Genome length to long, reisolate and resequence
        // length to low, resequencing needed e.g. top up run likely needed


    // High n50, low # of contigs likely all is good -> check n50 if it is low or high then check if nr_contigs is low
    // flip this, nr_contigs is too high, reisolate and resequence
        // if nr_contigs is low, check n50 values. if n50 is high good news.
            // nr_contigs is low, n50 is low, check genome size if low top up may be needed likely need to resequence


    TODO creating a logic heavy function that needs to be refactored

    For addressing the defect, the Passed and failed messeges have been broken up, all that remains is to have the
    final summary, checks passed and checks failed
    */

    for(val in sample_data){
            def contamination_fail = 2
            def final_message = ""

            def resequence = 0
            def reisolate = 0
            def qual_data = val.value["QualityAnalysis"]
            def meta_data = val.value["meta"]
            def sample_status = "FAILED"

            if(meta_data.metagenomic){
                // nothing to do here
                if(params.metagenomic_run){
                    final_message = "No QC Summary is provided for metagenomic samples."
                    qc_summary = "No quality control criteria is applied for metagenomic samples."
                    sample_status = "NA"
                }else if(params.fail_on_metagenomic){
                    qc_summary = "[FAILED] Sample was determined to be metagenomic and 'fail_on_metagenomic' was set to true."
                    final_message = "[FAILED] Sample was determined to be metagenomic and this was not specified as" +
                    " a metagenomic run indicating contamination REISOLATION AND RESEQUENCING RECOMMENDED." +
                    "There is additionally a possibility that your sample could not be identified as it is novel and " +
                    "not included in the program used to taxonomically classify your pipeline (however this is an unlikely culprit)."
                }else{
                    qc_summary = "[FAILED] Sample was determined to be metagenomic and this was not specified as a metagenomic run indicating contamination."
                    final_message = "[FAILED] Sample was determined to be metagenomic and this was not specified as" +
                    " a metagenomic run indicating contamination REISOLATION AND RESEQUENCING RECOMMENDED." +
                    "There is additionally a possibility that your sample could not be identified as it is novel and " +
                    "not included in the program used to taxonomically classify your pipeline (however this is an unlikely culprit)."
                }
                sample_data[val.key]["QCStatus"] = sample_status
                sample_data[val.key]["QCSummary"] = qc_summary
                sample_data[val.key]["QCMessage"] = final_message
                continue
            }

            def qual_message = []
            def failed_p = false
            def checks_failed = 0
            def checks = 0
            def checks_ignored = 0
            def n50_failed = false
            def nr_contigs_failed = false



            // ! TODO Summing of ignored checks is messy and the logic can likely be cleaned up
            if(qual_data && qual_data.containsKey("checkm_contamination") && !qual_data.checkm_contamination.status){
                reisolate = reisolate + contamination_fail
                resequence += 1
                failed_p = true
                checks_failed += 1
            }else if (qual_data && (!qual_data.containsKey("checkm_contamination") || !qual_data.checkm_contamination.status)){
                checks_ignored += 1
            }else if(qual_data == null){
                checks_ignored += 1
            }
            checks += 1

            if(!meta_data.assembly){
                // We should have reads as we assembled it
                if(qual_data && qual_data.containsKey("raw_average_quality") && !qual_data.raw_average_quality.status){
                    resequence += 1
                    checks_failed += 1
                }else if (qual_data && (!qual_data.containsKey("raw_average_quality") || !qual_data.raw_average_quality.status)){
                    checks_ignored += 1
                }else if(qual_data == null){
                    checks_ignored += 1
                }
                checks += 1

                if(qual_data && qual_data.containsKey("average_coverage") && !qual_data.average_coverage.status){

                    if(meta_data.downsampled){
                        qual_message.add("The sample may have been downsampled too aggressively, if this is the cause please re-run sample with a different target depth.")
                    }
                    checks_failed += 1
                    resequence += 1
                }else if(qual_data && (!qual_data.containsKey("average_coverage") || !qual_data.average_coverage.status)){
                    checks_ignored += 1
                }else if(qual_data == null){
                    checks_ignored += 1
                }
                checks += 1
            }

            if(qual_data && qual_data.containsKey("length") && !qual_data.length.status){
                if(qual_data.length.low){
                    resequence += 1
                    checks_failed += 1
                }else{
                    resequence += 1
                    reisolate = reisolate + contamination_fail
                    checks_failed += 1
                }
            }else if (qual_data && (!qual_data.containsKey("length") || !qual_data.length.status)){
                checks_ignored += 1
            }else if(qual_data == null){
                checks_ignored += 1
            }
            checks += 1

            if(qual_data && qual_data.containsKey("nr_contigs") && !qual_data.nr_contigs.status){
                checks_failed += 1
                nr_contigs_failed = true
            }else if (qual_data && (!qual_data.containsKey("nr_contigs") || !qual_data.nr_contigs.status)){
                checks_ignored += 1
            }else if(qual_data == null){
                checks_ignored += 1
            }
            checks += 1

            if(qual_data && qual_data.containsKey("n50_value") && !qual_data.n50_value.status){
                checks_failed += 1
                n50_failed = true
            }else if (qual_data && (!qual_data.containsKey("n50_value") || !qual_data.n50_value.status)){
                checks_ignored += 1
            }else if(qual_data == null){
                checks_ignored += 1
            }
            checks += 1


            (reisolate, resequence) = n50_nrcontigs_decision(qual_data, nr_contigs_failed, n50_failed, qual_message, reisolate, resequence)
            //qual_message.add("Quality Conclusion")

            add_secondary_message(params.assembly_status.report_tag,
                                "Assembly failed, this may be an issue with your data or the pipeline. Please check the log or the outputs in the samples work directory.",
                                val.value)

            add_secondary_message(params.filtered_reads.report_tag, "Sample did not have enough reads. (${params.min_reads}< present)", val.value)

            // TODO can reisolate be incremented without resequence? need to make sure no
            if(reisolate >= contamination_fail){
                qual_message.add("[FAILED] Sample is likely contaminated, REISOLATION AND RESEQUENCING RECOMMENDED")
            }else if(resequence > 0 && reisolate > 0){
                qual_message.add("[FAILED] RESEQUENCING IS RECOMMENDED. Further screening may be required as some evidence of CONTAMINATION was present")
            }else if(resequence > 0){
                qual_message.add("[FAILED] RESEQUENCING IS RECOMMENDED")
            }else if(checks_ignored > 0 || checks_failed > 0){
                qual_message.add("[FAILED] Checks had to be ignored")
            }else{
                qual_message.add("[PASSED] All Checks passed")
                sample_status = "PASSED"
            }

            def organism_criteria = sample_data[val.key][species_tag]
            def tests_passed = "Passed Tests: ${checks - checks_failed - checks_ignored}/${checks}"
            qual_message.add(tests_passed)


            def species_selected = val.value[val.key][params.top_hit_species.report_tag]
            if(species_selected == null){
                species_selected = organism_criteria
            }
            def species_id = "Species ID: ${species_selected}"
            qual_message.add(species_id)

            // Qual summary not final message
            final_message = qual_message.join("\n")
            def terminal_message = populate_qual_message(qual_data).join("\n")
            log.info "\n$val.key\n${terminal_message}\n${sample_status}\n${final_message}"

            // Reseq recommended should go to a seperate field
            // Requested output should be: [PASS|FAILED] Species ID: [species] [Tests passed] [Organism criteria available]
            qc_message = "${sample_status} ${species_id}; ${tests_passed}; Organism QC Criteria: ${organism_criteria}"

            sample_data[val.key]["QCSummary"] = qc_message
            sample_data[val.key]["QCStatus"] = sample_status
            sample_data[val.key]["QCMessage"] = final_message
        }

}

def add_secondary_message(report_tag, message, data){
    if(data.containsKey(report_tag)){
        if(!data.value[report_tag]){
            data.add(message)
        }
    }
}

def qc_params_species(){
    // TODO make sure these are all unique
    def search_phrases = [];
    params.QCReport.each{k, v ->
        if(v.search in search_phrases){
            log.error "Duplicate search phrase ${v.search} included in your QCReport parameters. Bailing out as erroneous results could be included by accident. If you have fixed the issue re-run the pipeline with -resume to pick up where you left off."
            exit 1
        }
        search_phrases.add([v.search, v])
    }

    return search_phrases;
}

def convert_type(type, val){
    def val_
    switch (type.toUpperCase()){
        case 'INTEGER':
            try{
                val_ = val.toLong()
            }catch (NumberFormatException ex){
                val_ = null
            }
        break;
        case 'FLOAT':
            try{
                val_ = val.toFloat()
            }catch (NumberFormatException ex){
                val_ = null
            }
        break;
        case 'BOOL':
            val_ = val.toBoolean()
        default:
        val_ = val
        break;
    }
    return val_;
}

def recurse_keys(value, keys_rk){
    def temp = traverse_values(value, keys_rk.path)
    def value_found = true

    if(temp == null){
        value_found = false;
    }

    def ret_val = null
    if(value_found){
        ret_val = convert_type(keys_rk.coerce_type, temp)
    }

    return ret_val
}

def traverse_values(value, path){

    def temp = value

    if(path instanceof String){
        temp = temp[path]
        return temp
    }

    for(key in path){
        def key_val = key.toString() // Calling `toString` to convert a gstring to a plain string type as the gstring method is not overloaded properly
        if(key_val.isNumber()){
            key_val = key_val.toInteger()
        }

        if(temp.getClass() in ArrayList && key_val.getClass() in Number){
            temp = temp[key_val]
        }else if(temp.containsKey(key_val)){
            temp = temp[key_val]
        }else{
            temp = null
            break
        }
    }
    return temp
}


def get_predicted_id(value_data, species_data){
    def predicted_id = value_data[params.top_hit_species.report_tag]
    def predicted_method = value_data[params.top_hit_method.report_tag]

    if(species_data[1].IDField == null && species_data[1].IDTool == null){
        return [predicted_id, predicted_method]
    }

    // The comparison to null in brackets returns a boolean value that can be used for bitwise comparisons
    if((species_data[1].IDField != null) ^ (species_data[1].IDTool != null)){
        log.warn "Both IDfield and IDTool must be set for ${species_data[0]}. IDField: ${species_data[1].IDField} IDTool: ${species_data[1].IDTool}"
        return [predicted_id, predicted_method]
    }

    def species_value = traverse_values(value_data, species_data[1].IDField)
    if(species_value == null){
        return [predicted_id, predicted_method]
    }
    predicted_id = species_value
    predicted_method = species_data[1].IDTool

    return [predicted_id, predicted_method]
}


def range_comp(fields, qc_data, comp_val, qc_obj){
    if(qc_data == null){
        qc_obj.message ="[WARNING ${qc_obj.field}] No comparison available for ${qc_obj.field}. Sample value: ${comp_val}"
        qc_obj.status = true
        return qc_obj
    }

    def vals = [qc_data[fields[0]], qc_data[fields[1]]].sort()
    if(vals[0] == null){
        qc_obj.message ="[WARNING ${qc_obj.field}] No comparison of available for ${qc_obj.field}. Sample value: ${comp_val}"
        qc_obj.status = true
        return qc_obj
    }
    if(vals[0] <= comp_val && comp_val <= vals[1]){
        qc_obj.status = true
        qc_obj.message = "[PASSED ${qc_obj.field}] ${comp_val} is within acceptable QC range for ${qc_data.search} (${fields[0]}: ${vals[0]} - ${fields[1]} ${vals[1]})"
        qc_obj.qc_status = "PASSED"
    }else{
        if(comp_val < vals[0]){
            qc_obj.low = true
        }else{
            qc_obj.low = false
        }
        qc_obj.message = "[FAILED ${qc_obj.field}] ${comp_val} is outside the acceptable ranges for ${qc_data.search} (${fields[0]}: ${vals[0]} - ${fields[1]} ${vals[1]})"
        qc_obj.qc_status = "FAILED"
    }
    return qc_obj
}

def greater_equal_comp(fields, qc_data, comp_val, qc_obj){
    if(qc_data == null){
        qc_obj.message ="[WARNING ${qc_obj.field}] No comparison available for ${qc_obj.field}. Sample value: ${comp_val}"
        qc_obj.status = true
        return qc_obj
    }
    def vals = qc_data[fields[0]]
    if(vals == null){
        qc_obj.message ="[WARNING ${qc_obj.field}] No comparison available. Sample value: ${comp_val}"
        qc_obj.status = true
        return qc_obj
    }

    if(comp_val >= vals ){
        qc_obj.status = true
        qc_obj.message = "[PASSED ${qc_obj.field}] ${comp_val} meets QC parameter of => ${vals} for ${qc_data.search}"
        qc_obj.qc_status  = "PASSED"
    }else{
        qc_obj.low = true
        qc_obj.message = "[FAILED ${qc_obj.field}] ${comp_val} is less than QC parameter of ${vals} for ${qc_data.search}"
        qc_obj.qc_status  = "FAILED"
    }
    return qc_obj
}

def lesser_equal_comp(fields, qc_data, comp_val, qc_obj){
    // TODO  move checks into seperate function
    if(qc_data == null){
        qc_obj.message ="[WARNING ${qc_obj.field}] No comparison available for ${qc_obj.field}. Sample value: ${comp_val}"
        qc_obj.status = true
        return qc_obj
    }
    def vals = qc_data[fields[0]]
    if(vals == null){
        qc_obj.message = "[WARNING ${qc_obj.field}] No comparison available for ${qc_obj.field}. Sample value: ${comp_val}"
        qc_obj.status = true
        return qc_obj
    }

    if(comp_val <= vals ){
        qc_obj.status = true
        qc_obj.message = "[PASSED ${qc_obj.field}] ${comp_val} meets QC parameter of <= ${vals} for ${qc_data.search}"
        qc_obj.qc_status = "PASSED"
    }else{
        qc_obj.low = false
        qc_obj.message = "[FAILED ${qc_obj.field}] ${comp_val} is greater than than QC parameter of ${vals} for ${qc_data.search}"
        qc_obj.qc_status = "FAILED"
    }
    return qc_obj
}

def prep_qc_vals(qc_vals, qc_data, comp_val, field_val){
    // Low value is added to designate if a value was too low or too high if it fails a qc threshold
    def status = ["status": false, "message": "", "field": field_val, "low": false, "value": comp_val, "qc_status": "WARNING"]
    def comp_fields = qc_vals.compare_fields
    switch(qc_vals.comp_type.toUpperCase()){
        case 'GE':
            greater_equal_comp(comp_fields, qc_data, comp_val, status);
            break;
        case 'LE':
            lesser_equal_comp(comp_fields, qc_data, comp_val, status);
            break;
        case 'RANGE':
            range_comp(comp_fields, qc_data, comp_val, status)
            break;
        case 'NONE':
            if (comp_val && params.metagenomic_run){
                status.status = true
            }else if(comp_val){
                status.status = false
            }else{
                status.status = true
            }
            break;
        default:
            log.warn "Unknown comparison type: ${comp_fields}"
            break;
    }
    return status
}


def get_shortest_token(search_params){

    def overly_large_number = 1000000000000;
    def shortest_entry = overly_large_number;
    for(i in search_params){
        def i_toks = i[0].split('_|\s')
        for(g in i_toks){
            def tok_size = g.size()
            if(tok_size < shortest_entry){
                shortest_entry = tok_size
            }
        }
    }
    return shortest_entry
}

def get_species(value, search_phrases, shortest_token){
    /*
        Get species data for the sample
        shortest_token: contains values to scrub from value to be searched for
    */


    def qc_data = [params.QCReport.fallthrough.search, params.QCReport.fallthrough];
    if(value == null){
        return qc_data
    }
    // search_term_val used to be 0...
    def search_term_val = 0 // location of where the search key is in the search phrases array

    // TODO matching here can likely be enhanced. wait for issue perhaps
    def comp_val_tokens = value.toLowerCase().split('_|\s').findAll{it.size() >= shortest_token};
    def comp_val = comp_val_tokens.join(" ")
    for(item in search_phrases){
        if(comp_val.contains(item[search_term_val].toLowerCase())){
            qc_data = item;
            break;
        }
    }
    return qc_data;
}

def get_qc_data_species(value_data, qc_data){
    def quality_messages = [:]

    params.QCReportFields.each{
        k, v ->
        if(v.on){ // only use the fields specified in the config
            def out = recurse_keys(value_data, v)
            if(out != null){
                def species_data = null
                if(qc_data == null){
                    species_data = params.QCReport.fallthrough
                }else{
                    species_data = qc_data[1]
                }
                def prepped_data = prep_qc_vals(v, species_data, out, k)
                quality_messages[k] = prepped_data
            }else{
                quality_messages[k] = ["field": k, "message": "[${k}] No data"]
            }
        }
    }

    return quality_messages;
}


def generate_qc_data(data, search_phrases, qc_species_tag){
    /*
    data: sample data in a LazyMap
    search_phrases: normalized search phrases from the nextflow.config
    */
    // TODO Need to update constants....

    def top_hit_tag = params.top_hit_species.report_tag;
    def quality_analysis = "QualityAnalysis"
    def shortest_token = get_shortest_token(search_phrases)
    def species_tag_location = 0
    def species_qc_params_location = 1
    for(k in data){
        if(!k.value.meta.metagenomic){
            def species = get_species(k.value[k.key][top_hit_tag], search_phrases, shortest_token)
            // update coverage first so its values can be used in generating qc messages
            generate_coverage_data(data[k.key], params.coverage_calc_fields.bp_field, species)
            data[k.key][quality_analysis] = get_qc_data_species(k.value[k.key], species)

            // More advanced logic to add in smarter typing information from select
            // tools that provide it.
            if(k.value[k.key][params.top_hit_species.report_tag] != null){
                def (predicted_id, predicted_method) = get_predicted_id(k.value[k.key], species)
                k.value[k.key][params.predicted_id_fields.predicted_id] = predicted_id
                k.value[k.key][params.predicted_id_fields.predicted_id_method] = predicted_method
            }

            def species_info = species[species_qc_params_location]

            def (primary_type_id, primary_type_id_method) = get_typing_id(k.value[k.key], species_info, species_info.PrimaryTypeID, species_info.PrimaryTypeIDMethod)
            k.value[k.key][params.typing_id_fields.PrimaryTypeID] = primary_type_id
            k.value[k.key][params.typing_id_fields.PrimaryTypeIDMethod] = primary_type_id_method

            def (secondary_type_id, secondary_type_id_method) = get_typing_id(k.value[k.key], species_info, species_info.SecondaryTypeID, species_info.SecondaryTypeIDMethod)

            k.value[k.key][params.typing_id_fields.SecondaryTypeID] = secondary_type_id
            k.value[k.key][params.typing_id_fields.SecondaryTypeIDMethod] = secondary_type_id_method

            data[k.key][qc_species_tag] = species[species_tag_location]
        }else{
            data[k.key][quality_analysis] = ["Metagenomic": ["message": null, "status": false]]
            data[k.key][quality_analysis]["Metagenomic"].message = "The sample was determined to be metagenomic, summary metrics will not be generated" +
                    " e.g. multiple genera are present in the sample. If your sample is supposed to be an isolate it is recommended" +
                    " you re-isolate and re-sequence this sample"
        }
    }

}



def get_typing_id(sample_data, species_info, species_info_type_id, species_info_type_id_method){
    /*
        sample_data: The aggregated user data
        species_info: QCParameters from the nextflow.config for the selectd species
        species_info_type_id: The Path to the requred information in the data. Taken from the QC Parameters
        species_info_type_id_method: The method name for the type id
    */

    def species_type_id_p = (species_info_type_id != null && species_info_type_id_method != null)
    def species_type_prepped = (species_info_type_id != null) ^ (species_info_type_id_method != null)
    if(!species_type_id_p){
       return ["", ""]
    }

    if(species_type_prepped){
        log.warn "Both ${species_info_type_id} and ${species_info_type_id_method} must be set for a type ID to be set."
        return ["", ""]
    }

    def selected_id = traverse_values(sample_data, species_info_type_id)
    if(selected_id){
        return [selected_id, species_info_type_id_method]
    }
    return ["", species_info_type_id_method]

}

def update_map_values(data, meta_data, tag){
    //TODO need to update values that exist if another one exists

    if(!data[meta_data.sample]["meta"].containsKey(tag)){
        data[meta_data.sample]["meta"][tag] = meta_data[tag]
    }else if(data[meta_data.sample]["meta"][tag] == null){ // is a specific case for null needed?
        data[meta_data.sample]["meta"][tag] = meta_data[tag]
    }else if(data[meta_data.sample]["meta"][tag] != meta_data[tag]){
        data[meta_data.sample]["meta"][tag] = meta_data[tag] // update to latest value if it does not match
    }
}


def check_file_params(param_data, extension){
    def header_tag = 'header_p'
    def report_tag_key = 'report_tag'
    def headers_list = 'headers'
    def info_tag = param_data.containsKey(report_tag_key) ? param_data.report_tag_key : param_data
    if(param_data.containsKey(header_tag) && extension.equals('json')){
        log.warn "The parameters specified for ${info_tag} state that it is a json file and has headers."
        log.warn "This does not quite make sense please update your configuration file to reflect the reported file type."
        log.warn "Report data for this file will not be added."
        return false
    }
    if(param_data.containsKey(header_tag) && !param_data[header_tag] && !param_data.containsKey(headers_list)){
        log.warn "The parameters for ${info_tag} indicate that it is not a tabular file without headers."
        log.warn "However no headers have been provided for the file in the config. Please update a 'headers' tag and array of field names to the config file."
        log.warn "Report data will not be added for this tool: ${param_data} extension: ${extension}"
        return false
    }
    return true
}

def parse_data(file_path, extension, report_data, headers_key){
    /*Select the correct parse based on the passed file type
    */
    // ? TODO should a check of existence be passed here?
    def headers = report_data.containsKey(headers_key) ? report_data[headers_key] : null
    def return_text = null
    switch(extension){
        case "tsv":
            return_text = table_values(file_path, report_data.header_p, '\t', headers)
            break
        case "tab":
            return_text = table_values(file_path, report_data.header_p, '\t', headers)
            break
        case "txt":
            return_text = table_values(file_path, report_data.header_p, '\t', headers)
            break
        case "csv":
            return_text = table_values(file_path, report_data.header_p, ',', headers)
            break
        case "json":
            //println "${file_path.getSimpleName()} is json"
            return_text = json_values(file_path, report_data)
            break
        case "screen":
            // Passsing on mash as the parser result is output
            //println "${file_path.getSimpleName()} is Mash output"
            //table_values(file_path, report_data.header_p, '\t', headers)
            break
        default:
            log.warn "I dont know what kind of file ${file_path} is. You may need to update the nextflow.config report settings \
Or the report module text parser."
            break
    }
    return return_text
}

def json_values(file_path, report_data){
    // Returns lazy map
    def delimiter = "."
    def exclude_field_tag = 'report_exclude_fields'
    def jsonSlurper = new JsonSlurper()
    String file_data = file_path.text
    def json_data = jsonSlurper.parseText(file_data)
    if (report_data.containsKey(exclude_field_tag)){
        json_paths = gather_json_paths(json_data, "", delimiter, [], report_data[exclude_field_tag])
        trim_json(json_data, json_paths, delimiter) // operates in place
    }
    return json_data
}

def trim_json(json_data, paths, delimiter){
    def unique_paths = paths.unique()
    def temp = json_data
    def head = json_data
    for(path in paths){
        def last_key = null
        def tokenized_values = path.tokenize(delimiter)
        def values_size = tokenized_values.size()
        for(long i = 0; i < values_size - 1; i++){
            temp = temp[tokenized_values[i]]
        }
        temp.remove(tokenized_values[values_size-1])
        temp = head
    }
}

def gather_json_paths(json_data, parents, delimiter, list_paths, exclude_paths){
    /*Trim json fields that should be excluded to prevent generating a massive yaml

    */

    json_data.each{
        key, value ->
        def temp = parents + "${delimiter}${key}"
        if(json_data[key] instanceof Map && !exclude_paths.contains(key)){
            list_paths.addAll(gather_json_paths(json_data[key], temp, delimiter, list_paths, exclude_paths))
        }else if(exclude_paths.contains(key)){
            list_paths << temp
        }
    }
    return list_paths


}

def table_values(file_path, header_p, seperator, headers=null){
    /*
        create a map matching rows to columns

        returns a map
    */
    def missing_value = 'NoData'
    def default_index_col = "__default_index__"
    def rows_list = null
    def use_modified_headers_from_file = false
    def is_missing = { it == null || it == '' }
    def replace_missing = { is_missing(it) ? missing_value : it }

    // Reads two lines (up to one header line + one row) for making decisions on how to parse the file
    def file_lines = file_path.splitText(limit: 2)
    if (!header_p && headers == null) {
        throw new Exception("Header is not provided in file [header_p=${header_p}], but headers passed to function is null")
    } else if (!header_p) {
        if (file_lines.size() == 0) {
            // headers were not in the file, and file size is 0, so return missing data based
            // on passed headers (i.e., single row of empty values)
            rows_list = [headers.collectEntries { [(it): null] }]
        } else {
            // verify that passed headers and rows have same number
            def row_line = file_lines[0].replaceAll('(\n|\r\n)$', '')
            def row_line_columns = row_line.split(seperator, -1)
            if (headers.size() != row_line_columns.size()) {
                throw new Exception("Mismatched number of passed headers ${headers} and column values ${row_line_columns} for file ${file_path}")
            } else {
                rows_list = file_path.splitCsv(header: headers, sep:seperator)
            }
        }
    } else {
        // Headers exist in file

        if (file_lines.size() == 0) {
            throw new Exception("Attempting to parse empty file [${file_path}] as a table where header_p=${header_p}")
        }

        def header_line = file_lines[0].replaceAll('(\n|\r\n)$', '')
        def headers_from_file = header_line.split(seperator, -1)
        def total_missing_headers = headers_from_file.collect{ is_missing(it) ? 1 : 0 }.sum()

        if (total_missing_headers > 1) {
            throw new Exception("Attempting to parse tabular file with more than one missing header: [${file_path}]")
        } else if (is_missing(headers_from_file[0])) {
            // Case, single missing header as first column
            headers_from_file[0] = default_index_col
            use_modified_headers_from_file = true
        }

        if (file_lines.size() == 1) {
            // There is no row lines, only headers, so return missing data
            // (single row of empty values)
            rows_list = [headers_from_file.collectEntries { [(it): null] }]
        } else {
            // If there exists a row line, then make sure rows + headers match

            def row_line1 = file_lines[1].replaceAll('(\n|\r\n)$', '')
            def row_line1_columns = row_line1.split(seperator, -1)
            if (headers_from_file.size() != row_line1_columns.size()) {
                throw new Exception("Mismatched number of headers ${headers_from_file} and column values ${row_line1_columns} for file ${file_path}")
            }

            if (use_modified_headers_from_file) {
                rows_list = file_path.splitCsv(header: headers_from_file as List, sep:seperator, skip: 1)
            } else {
                rows_list = file_path.splitCsv(header: true, sep:seperator)
            }
        }
    }

    return rows_list.indexed().collectEntries { idx, row ->
        [(idx): row.collectEntries { k, v -> [(k): replace_missing(v)] }]
    }
}
