// Module to parse the kat dist output
import groovy.json.JsonSlurper


process PARSE_KAT {
    tag "$meta.id"
    label "process_single"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), val(json)

    output:
    tuple val(meta), val(est_genome_size), emit: genome_size
    tuple val(meta), val(est_heterozygozity), emit: heterozygozity

    exec:
    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    The outputs of the json are tied to KAT's output json structure, if
    Kat's fields ever change in an updated container this may be the
    issue.
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */
    def jsonSlurper = new JsonSlurper();
    def data = file(json)
    String data_json = data.text
    def json_data = jsonSlurper.parseText(data_json)
    est_heterozygozity = json_data.est_het_rate
    est_genome_size = json_data.est_genome_size
    if(est_genome_size.toLong() == 0){
        log.warn "Estimated genome size for ${meta.id} is ${est_genome_size}. This is likely a quirk of KAT and not the pipeline."
        log.warn "Try re-starting the pipeline without resume for the sample that failed. Or perhaps try a different Kat container if the issue persists"
    }
    log.info "Sample: ${meta.id}"
    log.info "  Heterozygozity: ${est_heterozygozity}"
    log.info "  Size: ${est_genome_size}"
}
