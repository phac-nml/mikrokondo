// Create indices for assemblies

process MINIMAP2_INDEX{
    tag "${meta.id}"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(contigs)

    output:
    tuple val(meta), path("${meta.id}${params.minimap2.index_ext}"), emit: index
    path "versions.yml", emit: versions

    script:
    """
    minimap2 -d ${meta.id}${params.minimap2.index_ext} $contigs
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """

}
