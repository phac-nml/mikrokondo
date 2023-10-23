// Process for parsing the fastp json output
import groovy.json.JsonSlurper

process PARSE_FASTP{
    tag "$meta.id"
    label "process_low"

    input:
    tuple val(meta), val(json)

    output:
    tuple val(meta), val(total_reads_post), emit: read_count
    tuple val(meta), val(total_bases), emit: base_count

    exec:
    if (workflow.stubRun){
        total_reads_post = 100000
        total_bases = 10000000
        total_reads_post
        total_bases
    }else{
        // ! TODO add warning of fastp versions in the future
        /*
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        The outputs of the json are tied to Fastp's output json structure, if
        Fastp's fields ever change in an updated container this may be the
        issue with future fastp versions.

        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        */
        def jsonSlurper = new JsonSlurper();
        def data = file(json)
        String data_json = data.text
        def json_data = jsonSlurper.parseText(data_json)
        total_reads_post = json_data.summary.after_filtering.total_reads.toLong()
        total_bases = json_data.summary.after_filtering.total_bases.toLong()
        /*
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        Stating the variables to be filterd below as when testing running the pipeline
        on nextflow 23.04.1 unless some side effect occured with the variables nothing happened.

        E.g. when logging the variables they were set as outputs, but when I did nothing else
        besides set them (with our without a def) an error occured saying there was no output.
        Merely stating the variables below seems to have solved the issue however. I am guessing this
        has to do with Groovy or Nextflow interning variable but I do not know for sure currently.
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        */
        total_reads_post
        total_bases
        // if this data is not logged the process does not work???
        //log.info "Sample: ${meta.id}"
        //log.info "  Total Reads After Filtering: ${total_reads_post}"
        //log.info "  Total Bases After Filtering: ${total_bases}"
    }


}
