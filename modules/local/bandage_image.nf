// Create bandage images of spades assemblies

process BANDAGE_IMAGE {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(gfa)

    output:
    tuple val(meta), path("*${params.bandage.svg_ext}")
    path  "versions.yml"          , emit: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    gunzip -c $gfa > ${prefix}.gfa
    Bandage image  ${prefix}.gfa ${prefix}.svg $args
    rm ${prefix}.gfa
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bandage: \$(echo \$(Bandage --version 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch test${params.bandage.svg_ext}
    touch versions.yml
    """

}
