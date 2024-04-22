/*Shigatyper implementation

*/


process SHIGATYPER{
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(reads) // in mkkondo it will only work with assemblies

    output:
    tuple val(meta), path("${prefix}${params.shigatyper.tsv_ext}"), emit: tsv
    tuple val(meta), path("${prefix}-hits${params.shigatyper.tsv_ext}"), optional: true, emit: hits
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    export TMPDIR=\$PWD # set env temp dir to in the folder
    shigatyper $args --SE $reads --name $prefix
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        shigatyper: \$(echo \$(shigatyper --version 2>&1) | sed 's/^.*ShigaTyper //' )
    END_VERSIONS
    """
}


