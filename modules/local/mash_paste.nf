// Merge all mash outputs into one main sketch

process MASH_PASTE{
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(sketches) // getting all output sketches

    output:
    tuple val(meta), path("${params.mash.final_sketch_name}${params.mash.sketch_ext}")

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mash paste ${params.mash.final_sketch_name} $sketches
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mash: \$( mash --version )
    END_VERSIONS
    """
}
