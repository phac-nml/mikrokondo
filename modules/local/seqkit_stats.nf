/* Generate fasta stats with seqkit
*/


process SEQKIT_STATS {
    tag "$meta.id"
    label 'process_single'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(contigs), path(trimmed_reads)

    output:
    tuple val(meta), path(contigs), path(trimmed_reads), path("*${params.seqkit_stats.report_ext}"), emit: stats
    path "versions.yml", emit: versions


    script:
    def prefix =  task.ext.prefix ?: "${meta.id}"
    """
    seqkit stats -T ${contigs} > ${prefix}${params.seqkit_stats.report_ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit version | sed 's/seqkit v//' )
    END_VERSIONS
    """

    stub:
    """
    touch stub_${params.seqkit_stats.report_ext}
    touch versions.yml
    """


}
