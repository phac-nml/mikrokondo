// Filter contigs by length


process SEQKIT_FILTER {
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"


    input:
    tuple val(meta), path(contigs), path(reads)
    val min_length

    output:
    tuple val(meta), path("${prefix}${params.seqkit.fasta_ext}"), emit: filtered_sequences
    path "versions.yml", emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqkit seq -m ${min_length} ${contigs} | gzip > ${prefix}${params.seqkit.fasta_ext}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit version | sed 's/seqkit v//' )
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.seqkit.fasta.ext}
    touch versions.yml
    """
}
