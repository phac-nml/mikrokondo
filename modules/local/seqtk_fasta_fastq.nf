/*Convert fasta to a fake fastq
*/


process SEQTK_FASTA_FASTQ{
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    fair true
    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}${params.seqtk.assembly_fastq}"), emit: fastq_reads
    path "versions.yml", emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqtk seq -F 'H' $fasta > ${prefix}.fastq
    gzip ${prefix}.fastq
    cat <<-END_VERSIONS > versions.yml\n"${task.process}":\n    seqtk: \$(echo \$(seqtk 2>&1) | sed 's/^.*Version: //; s/ .*\$//')\nEND_VERSIONS
    """

}
