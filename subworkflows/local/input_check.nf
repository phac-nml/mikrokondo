//
// Check input samplesheet and get read channels
//

include { COMBINE_DATA } from '../../modules/local/combine_data.nf'
include { fromSamplesheet } from 'plugin/nf-validation'


workflow INPUT_CHECK {

    main:

    versions = Channel.empty()
    def sample_sheet = params.input

    // Thank you snvphylnfc for the ideas :)
    // https://github.com/phac-nml/snvphylnfc/blob/f1e5fae76af276acf0a8c98174978cb21ca5d7e0/workflows/snvphylnfc.nf#L98-L109
    def processedIDs = [] as Set

    reads_in = Channel.fromSamplesheet(
        "input", // apparentely input maps to params.input...
        parameters_schema: 'nextflow_schema.json',
        skip_duplicate_check: true)
    // Check that samplesheet does not contain more samples than sample limit
    reads_in.collect()
    .map { items ->
            if ((items.size() > params.max_samples) && !(params.max_samples == 0)) { // Default max_samples is 0, which is equivalent to "no-limit"
                error "Pipeline is being run with ${items.size()} items, which exceeds the limit of ${params.max_samples}"
            }
            return items
        }
    .flatten()
    reads_in = reads_in.map {
            // Create grouping value
            meta ->


                // Verify file names do not start with periods as the files can end up being treated as
                // hidden files causing odd issues later on in the pipeline

                if(meta[0].id == null){
                    // Remove any unallowed characters in the meta.id field
                    meta[0].id = meta[0].external_id.replaceAll(/\./, '_')
                    meta[0].id = meta[0].id.replaceAll(/[^A-Za-z0-9_\.\-]/, '_')
                }else {
                    meta[0].id = meta[0].id.replaceAll(/\./, '_')
                    meta[0].id = meta[0].id.replaceAll(/[^A-Za-z0-9_\.\-]/, '_')
                }


                if(processedIDs.contains(meta[0].id) && params.skip_read_merging){
                    // If the id is already contained and read merging is not to be
                    // performed, then we make the id's unique to proceed with processing
                    // read merging is set to false by default, so that when it is run
                    // in IRIDANext reads are only merged in irida next
                    while (processedIDs.contains(meta[0].id)) {
                        meta[0].id = "${meta[0].id}_${meta[0].external_id}"
                    }
                }
                processedIDs << meta[0].id
                tuple(meta[0].id, meta[0])
        }

    if(params.opt_platforms.ont == params.platform && params.nanopore_chemistry == null){
        exit 1, "ERROR: Nanopore data was selected without a model being specified."
    }

    if(params.opt_platforms.hybrid == params.platform
        && params.long_read_opt == params.opt_platforms.ont
        && params.nanopore_chemistry == null){
        exit 1, "ERROR: Nanopore data was selected without a model being specified."
    }

    // ========== Merge data with the same ID specified twice =====================
    grouped_tuples = reads_in.groupTuple(by: 0).branch {
            it ->
                merge_data: it[1].size() > 1
                format: true
            }

    reads_to_combine = grouped_tuples.merge_data.map{
        it -> group_reads(it)
    }

    merged_reads = COMBINE_DATA(reads_to_combine.map{
        meta -> tuple(meta, meta.fastq_1, meta.fastq_2, meta.long_reads, meta.assembly)
    })
    versions = versions.mix(merged_reads.versions)

    re_formatted_data = merged_reads.reads.map{
        meta, fastq_1, fastq_2, long_r, assembly -> tuple(meta.id, reset_combined_map(meta, fastq_1, fastq_2, long_r, assembly))
    }

    //============================ End of merging new data =================================

    data_to_format = grouped_tuples.format.map{
            id, meta -> tuple(id, meta[0]) // undoing tuple grouping
        }.mix(re_formatted_data)

    reads = data_to_format.map{
        it -> format_reads(it)
    }

    emit:
    reads // channel: [ val(meta), [ reads ] ]
    versions = versions // channel: [ versions.yml ]
}

def reset_combined_map(LinkedHashMap meta, Path f_reads, Path r_reads, Path long_reads, Path assembly){
    /*Re-format the data to make it similar to make it match the input format again

    */

    def new_meta = meta
    new_meta.merge = true

    // Converting paths back to strings so that the data fits in the format data function
    if(meta.fastq_1){
        new_meta.fastq_1 = f_reads.toString()
    }
    if(meta.fastq_2){
        new_meta.fastq_2 = r_reads.toString()
    }
    if(meta.long_reads){
        new_meta.long_reads = long_reads.toString()
    }
    if(meta.assembly){
        new_meta.assembly = assembly.toString()
    }

    return new_meta

}

def check_file_exists(def file_path){
    if(!file(file_path).exists()){
        exit 1, "ERROR: Please check input samplesheet -> $file_path does not exist. Check that you do not have spaces in your path."
    }
    return true
}

def format_reads(ArrayList sheet_data){
    def meta = [:]
    def error_occured = false
    meta.id = sheet_data[0] // id is first value
    //meta.sample = sheet_data[1].external_id
    meta.sample = sheet_data[0]
    meta.external_id = sheet_data[1].external_id

    meta.hybrid = false
    meta.assembly = false
    meta.downsampled = false
    meta.single_end = false
    meta.merge = false
    def sequencing_data = sheet_data[1]
    if(sequencing_data.containsKey("merge")){
        meta.merge = sequencing_data.merge
    }
    def ret_val = null

    // A map could probably clean this up
    if(sequencing_data.fastq_1 && sequencing_data.fastq_2 && sequencing_data.long_reads && !sequencing_data.assembly){
        if(params.platform != params.opt_platforms.hybrid){
            log.warn "Short and long reads have been specified for ${meta.id} but a hybrid assembly has not been specified. Exiting now."
            error_occured = true
        }
        meta.hybrid = true
        check_file_exists(sequencing_data.fastq_1)
        check_file_exists(sequencing_data.fastq_2)
        check_file_exists(sequencing_data.long_reads)
        ret_val = tuple(meta, [file(sequencing_data.fastq_1), file(sequencing_data.fastq_2)], file(sequencing_data.long_reads))

    }else if(sequencing_data.long_reads){
        meta.single_end = true
        if(![params.opt_platforms.ont, params.opt_platforms.pacbio].contains(params.platform)){
            log.warn "Long reads have been specified for ${meta.id} but no single end read platform has been ($params.opt_platforms.ont or $params.opt_platforms.pacbio) exiting now."
            error_occured = true
        }
        check_file_exists(sequencing_data.long_reads)
        ret_val = tuple(meta, file(sequencing_data.long_reads))

    }else if(sequencing_data.assembly){
        if(sequencing_data.fastq_1 || sequencing_data.fastq_2 || sequencing_data.long_reads){
            log.warn "Additional sequencing data has been provided alongside assembly $meta.id, but reference guided assemblies are not currently supported."
            error_occured = true
        }
        check_file_exists(sequencing_data.assembly)
        meta.assembly = true
        ret_val = tuple(meta, file(sequencing_data.assembly))

    }else if(sequencing_data.fastq_1 || sequencing_data.fastq_2){ // using or here to capture any chances taht only one read set is specified
        if(params.platform != params.opt_platforms.illumina){
            log.warn "Paired end read data has been specified for ${meta.id}, but the sequencing platform specified is not ${params.opt_platforms.illumina}"
            error_occured = true
        }
        check_file_exists(sequencing_data.fastq_1)
        check_file_exists(sequencing_data.fastq_2)
        ret_val = tuple(meta, [file(sequencing_data.fastq_1), file(sequencing_data.fastq_2)])

    }else{
        log.warning "Cannot determine what type of data is presented for $meta.id, more that one read type is specified"
        error_occured = true
    }

    if(error_occured){
        exit 1
    }

    return ret_val

}

def group_reads(ArrayList read_data){
    def id = read_data[0]
    def sample_data = read_data[1]
    def reads_combine = [:]
    // File fields to merge
    log.info "Merging data for ${id}"
    def fields_merge = ["fastq_1", "fastq_2", "long_reads", "assembly"]
    for(item in sample_data[0]){
        if(!fields_merge.contains(item.key)){
            // copy over remaining metadata
            reads_combine[item.key] = item.value
        }
    }

    for(group in sample_data){
        for(item in fields_merge){
            if(!reads_combine.containsKey(item)){
                reads_combine[item] = []
            }
            if(group[item] && check_file_exists(group[item])){
                reads_combine[item] << file(group[item])
            }
        }
    }
    log.info "Merging ${reads_combine}"
    return reads_combine
}


