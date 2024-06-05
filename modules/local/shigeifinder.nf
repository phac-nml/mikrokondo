// Taking alot of code from: https://github.com/nf-core/modules/blob/master/modules/nf-core/shigeifinder/main.nf


process SHIGEIFINDER {
    tag "$meta.id"
    label 'process_low'
    afterScript "rm $tmp_file"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    fair true
    input:
    tuple val(meta), path(seqs)

    output:
    tuple val(meta), path("*${params.shigeifinder.tsv_ext}"), emit: tsv
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    tmp_file = "${prefix}.fa"
    def VERSION = params.shigeifinder.container_version // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    gunzip -c $seqs > $tmp_file
    shigeifinder $args --output ${prefix}.tsv -t $task.cpus -i $tmp_file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        shigeifinder: $VERSION
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.shigeifinder.tsv_ext}
    touch versions.yml
    """
}
