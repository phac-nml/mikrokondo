/*Raw read summary metrics
*/


process READ_SCAN{
    label 'process_medium'
    tag "${meta.id}"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(reads), path(l_reads)

    output:
    tuple val(meta), path("${prefix}.json"), emit: json
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def script_run = null
    if(meta.hybrid){
        script_run = "-f ${reads[0]} ${reads[1]} ${l_reads} -n R1 R2 SE"
        log.info "Read Scan R1: ${reads[0]} R2: ${reads[1]} SE: ${l_reads}"
    }else if(!meta.single_end){
        script_run = "-f ${reads[0]} ${reads[1]} -n R1 R2"
        log.info "Read Scan R1: ${reads[0]} R2: ${reads[1]}"
    }else{
        script_run = "-f ${reads[0]} -n SE"
        log.info "Read Scan SE: ${reads[0]}"
    }

    """
    fastq_scan.py ${script_run} -p ${params.raw_reads.high_precision} > ${prefix}.json
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """


}
