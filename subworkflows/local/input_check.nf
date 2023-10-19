//
// Check input samplesheet and get read channels
//

include { COMBINE_DATA } from '../../modules/local/combine_data.nf'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    // TODO add in automatic gzipping of all samples in
    versions = Channel.empty()
    reads_in = Channel.fromPath(samplesheet)
            .splitCsv ( header:true, sep:',' )
            .map { create_fastq_channel(it) }

    if(params.opt_platforms.ont == params.platform && params.nanopore_chemistry == null){
        exit 1, "ERROR: Nanopore data was selected without a model being specified."
    }
    // Group together samples for processing
    grouped_tuples = reads_in.groupTuple()
    // TODO for grouping samples together need to check that they are both fastq's
    grouped_tuples = grouped_tuples.map{
        it -> group_reads(it)
    }

    reads_combined = grouped_tuples.branch{
        merge_reads: it[0].merge
        reads: true
    }

    merged_reads = COMBINE_DATA(reads_combined.merge_reads)
    versions = versions.mix(merged_reads.versions)

    reformatted_reads = merged_reads.reads.map{
        meta, f_reads, r_reads, l_reads, assembly -> format_merged_reads(meta, f_reads, r_reads, l_reads, assembly)
    }
    reformatted_reads.subscribe{
        log.info "Merged Reads: $it"
    }

    emit:
    reads = reads_combined.reads.concat(reformatted_reads) // channel: [ val(meta), [ reads ] ]
    versions = versions // channel: [ versions.yml ]
}

def format_merged_reads(LinkedHashMap meta, sun.nio.fs.UnixPath f_reads, sun.nio.fs.UnixPath r_reads, sun.nio.fs.UnixPath l_reads, sun.nio.fs.UnixPath assembly){
    /*Reformat reads that have been merged together
    */

    if(meta.hybrid){
        return tuple(meta, [f_reads, r_reads], l_reads)
    }else if(meta.single_end){
        return tuple(meta, l_reads)
    }else if(meta.assembly){
        return tuple(meta, assembly)
    }else{
        return tuple(meta, [f_reads, r_reads])
    }
}


def group_reads(ArrayList sequencing_data){
    /*
    Split up groups to merge reads if needed
    This function is not written the best... but I am still learning groovy so this will have to do

    TODO add in test of all inputs and assembly combining
    TODO look for a better alternative!!
    TODO make test case for nanopore
    TODO make test case for hybrid

    */

    def meta = sequencing_data[0]
    def data_arr_pos = 1
    def forward_reads = []
    def reverse_reads = []
    def long_reads = []
    def assembly_fasta = []
    def return_value = null
    def number_vals = 0
    def non_duplicated_amount = 1
    meta.merge = false
    if(meta.hybrid){
        // ! TODO add in test
        //def paired_end = sequencing_data[data_arr_pos]
        //def paired_end = sequencing_data[data_arr_pos]
        def paired_end = sequencing_data[data_arr_pos][0]
        //def single_end = sequencing_data[data_arr_pos + 1] // Hybrid data is offset one position
        def single_end = sequencing_data[data_arr_pos][0][data_arr_pos] // Hybrid data is offset one position

        //for(int i = 0; i < single_end.size(); i++){
        for(int i = 0; i < single_end.size(); i++){
            log.info "Paired data: ${paired_end[i]}"
            log.info "single end data: ${single_end[i]}"
            forward_reads << paired_end[i][0]
            reverse_reads << paired_end[i][1]
            long_reads << single_end[i]
            number_vals++
        }
    }else if(meta.single_end){
        // single ended reads
        for(reads in sequencing_data[data_arr_pos]){
            long_reads << reads
            number_vals++
        }
    }else if(meta.assembly){

        for(reads in sequencing_data[data_arr_pos]){
            assembly_fasta << reads
            number_vals++
        }
    }else{
        // paired end reads
        for(reads in sequencing_data[data_arr_pos]){
            // 0 and 1 here denote the forward and reverse reads
            forward_reads << reads[0]
            reverse_reads << reads[1]
            number_vals++
        }
    }

    if(number_vals > non_duplicated_amount){
        meta.merge = true
        return_value = [meta, forward_reads, reverse_reads, long_reads, assembly_fasta]
    }else{
        if(meta.single_end){
            // Single end return value
            return_value = [meta, long_reads[0]]
        }else if(meta.hybrid){
            // Hybrid data return value
            return_value = [meta, [forward_reads[0], reverse_reads[0]], long_reads[0]]
        }else if(meta.assembly){

            return_value = [meta, assembly_fasta[0]]

        }else{
            // Paired end return value
            return_value = [meta, [forward_reads[0], reverse_reads[0]]]
        }
    }
    return return_value
}


def check_file_exists(String file_path){
    // Check if a file exists, exit if it does not
    if(file_path == null){
        exit 1, "ERROR: Please check input samplesheet -> $file_path is null. This could be due to forgetting to add Headers to your sample sheet or you could have empty rows in your sample sheet."
    }
    if(!file(file_path).exists()){
        exit 1, "ERROR: Please check input samplesheet -> $file_path does not exist. If your file in you sample sheet does not exist make sure you do not have spaces in your path name."
    }
    return true

}

def create_fastq_channel(LinkedHashMap row) {
    // Create channel of metadata
    // counts for each data type
    // TODO need to add in control for when there is an assembly and reads
    def paired_end_count = 3 // sample, fastq1, fastq2
    def single_end_count = 2 //sample, long_reads
    def hybrid_end_count = 4 // sample, fastq1, fastq2, long_reads
    def meta = [:]
    def values = row.count { key, value -> value != null && !value.isEmpty()}
    meta.id = row.sample
    meta.sample = row.sample // id can change later in the workflow if sample is split
    meta.hybrid = false
    meta.assembly = false
    meta.downsampled = false
    //meta.metagenomic = false

    // Check that the reads position and place matches what comes in for each sample
    if(values == paired_end_count
    && params.platform == params.opt_platforms.illumina
    && row.fastq_1 != null
    && row.fastq_2 != null){
        meta.single_end = false

    }else if(values == single_end_count
    && (params.platform == params.opt_platforms.ont || params.platform == params.opt_platforms.pacbio)
    && row.long_reads != null){

        meta.single_end = true

    }else{
        // fall through for if data is single ended
        meta.single_end = false
    }

    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    def files = null


    if (meta.single_end) {

        check_file_exists(row.long_reads)
        files = [ file(row.long_reads) ]

    }else if (!meta.single_end
    && (row.long_reads == null || row.long_reads.isEmpty())
    && (row.assembly == null || row.assembly.isEmpty())){

        check_file_exists(row.fastq_1)
        check_file_exists(row.fastq_2)
        files = [ file(row.fastq_1), file(row.fastq_2) ]

    }else if(!meta.single_end && row.long_reads != null && (row.assembly == null || row.assembly.isEmpty())){
        check_file_exists(row.long_reads)
        check_file_exists(row.fastq_1)
        check_file_exists(row.fastq_1)
        meta.hybrid = true
        files = [[ file(row.fastq_1), file(row.fastq_2) ], [file(row.long_reads)]]

    }else if(!meta.single_end && (row.assembly != null || !row.assembly.isEmpty()) && check_file_exists(row.assembly)){

        meta.assembly = true
        check_file_exists(row.assembly)
        files = [file(row.assembly)]

    }else{
        msg = "Please inspect your sample sheet, inputs could not be determined: $meta $row" + \
        "The platform of $params.platform may not be supported as well"
        exit 1, msg
    }

    fastq_meta = [meta, files]
    //println "Assembly formatted: $fastq_meta"
    // add in other read data if available
    return fastq_meta
}
