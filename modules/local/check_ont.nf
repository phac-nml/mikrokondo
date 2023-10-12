// Module to append a unique id to each header in an ont fastq to make sure flye can assemble

process CHECK_ONT{
    tag "$meta.id"
    label "process_single"


    // TODO add to publish dir
    // TODO perhaps reads should just be dedupped by header...

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
    output_name = "test.unique_headers.fastq.gz"
    """
    touch ${output_name}
    touch versions.yml
    """


}
