/*Trim poor quality reads with Fastp
*/



process FASTP_TRIM{
    tag "$meta.id"
    label "process_medium" // fastp uses very little memory in reality, but for duplicate analysis it is better to give it more memory
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    fair true
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*${params.fastp.fastq_ext}"), emit: reads
    tuple val(meta), path("*${params.fastp.json_ext}"), emit: fastp_json
    tuple val(meta), path("*${params.fastp.html_ext}"), emit: fastp_html
    path "versions.yml", emit: versions


    script:
    def args = task.ext.args ?: ""
    /*
        Below `instanceof nextflow.processor.TaskPath` is used as a way to allow for single read sets,
        without altering the metadata entering the process. Allowing for the process to be more genralizable
        to the hybrid assembly workflow without a significant refactoring to the rest of the pipeline

        There may be a change in the future that allows for this kludge to be avoided

        TODO In a future release check if this has been addressed/consider it in refactors
    */
    if(params.fastp.dedup_reads){
        args = args + "-D "
    }
    if(meta.single_end || reads instanceof nextflow.processor.TaskPath) {
        args = args + "${params.fastp.args.single_end} -i ${reads[0]} -o ${reads[0].simpleName}${params.fastp.fastq_ext}"
    }else{
        args = args + "${params.fastp.args.illumina} -i ${reads[0]} -I ${reads[1]} -o ${reads[0].simpleName}.R1${params.fastp.fastq_ext} -O ${reads[1].simpleName}.R2${params.fastp.fastq_ext}"
    }
    """
    fastp ${args} --json ${meta.id}.json --html ${meta.id}.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.fastp.fastq_ext}
    touch stub${params.fastp.json_ext}
    touch stub${params.fastp.html_ext}
    touch versions.yml
    """

}

