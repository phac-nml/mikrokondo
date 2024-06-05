// Process for running 7 gene core mlst

process MLST {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    fair true
    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*${params.mlst.json_ext}"), emit: json
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    args = args + params.mlst.args
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mlst $args --json ${prefix}${params.mlst.json_ext} --label ${prefix} --threads $task.cpus $fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mlst: \$( echo \$(mlst --version 2>&1) | sed 's/mlst //' )
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.mlst.json_ext}
    touch versions.yml
    """
}
