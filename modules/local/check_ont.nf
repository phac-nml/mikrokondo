// Module to append a unique id to each header in an ont fastq to make sure flye can assemble

process CHECK_ONT{
    tag "$meta.id"
    label "process_single"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"


    // TODO add to publish dir
    // TODO perhaps reads should just be dedupped by header...
    // TODO Awk would be faster...

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path(output_name), emit: reads

    script:
    output_name = "${meta.id}.unique_headers.fastq.gz"
    """
    fix_ont.py $reads | gzip - > ${output_name}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    output_name = "stub.unique_headers.fastq.gz"
    """
    touch stub.unique_headers.fastq.gz
    touch versions.yml
    """


}
