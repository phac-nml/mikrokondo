/* Generate fasta stats with seqkit
*/


process SEQKIT_STATS {
    tag "$meta.id"
    label 'process_single'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(contigs), path(trimmed_reads)

    output:
    tuple val(meta), path(contigs), path(trimmed_reads), path("*${params.seqkit.report_ext}"), emit: stats
    path "versions.yml", emit: versions


    script:
    def prefix =  task.ext.prefix ?: "${meta.id}"
    """
    seqkit stats -T ${contigs} > ${prefix}${params.seqkit.report_ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit version | sed 's/seqkit v//' )
    END_VERSIONS
    """

    stub:
    """
    touch stub_${params.seqkit.report_ext}
    touch versions.yml
    """


}
