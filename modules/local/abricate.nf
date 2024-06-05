/// Abricate module


process ABRICATE {
    tag "$meta.id"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"


    fair true
    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*.txt"), emit: report
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    abricate $assembly $args --threads $task.cpus > ${prefix}.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(echo \$(abricate --version 2>&1) | sed 's/^.*abricate //' )
    END_VERSIONS
    """

    stub:
    """
    touch abricate.txt
    touch versions.yml
    """
}
