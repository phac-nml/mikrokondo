// Polish assemblies with RACON
// borrowing from: https://github.com/nf-core/modules/blob/master/modules/nf-core/racon/main.nf

// TODO Racon has a script for re-naming reads built in, Idk how to access it or if it is in the container however
process RACON_POLISH {
    tag "${meta.id}"
    label 'process_high'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"
    afterScript "rm ${input_reads}"

    input:
    tuple val(meta), path(reads), path(sam), path(contigs)

    output:
    tuple val(meta), path("*${params.racon.consensus_ext}"), emit: racon_polished
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "$meta.id"
    def output_name = "${meta.id}${params.racon.consensus_suffix}"
    input_reads = "input_racon_reads.fastq.gz"
    """
    cat ${reads} > $input_reads
    racon -t $task.cpus $args $input_reads ${sam} ${contigs} > ${output_name}
    gzip $output_name
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        racon: \$( racon --version 2>&1 | sed 's/^.*v//' )
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.racon.consensus_ext}
    touch versions.yml
    """

}
