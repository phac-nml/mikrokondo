process GROUPBY_OUTPUT {
    tag "$meta.id"
    label 'process_single'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(tabular_file)
    val key

    output:
    tuple val(meta), path("groupby/*"), emit: grouped_tabular_file
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p groupby
    groupby_output.py $args -k '${key}' -i ${tabular_file} -o groupby/${prefix}.grouped.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch test.grouped.tsv
    touch versions.yml
    """
}