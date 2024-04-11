process SEQTK_SIZE{
    tag "${meta.id}"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(reads)

    output:

    tuple val(meta), path(output), emit: base_counts
    path "versions.yml", emit: versions

    script:
    def paired_read_size = 2
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    output = "${meta.id}_basecounts.txt"
    """
    seqtk size ${reads.join(" ")} > ${output}
    cat <<-END_VERSIONS > versions.yml\n"${task.process}":\n    seqtk: \$(echo \$(seqtk 2>&1) | sed 's/^.*Version: //; s/ .*\$//')\nEND_VERSIONS
    """

    stub:
    """
    touch stub${params.seqtk.reads_ext}
    touch versions.yml
    """
}
