// Listeria typing, taking module code from: https://github.com/nf-core/modules/blob/master/modules/nf-core/lissero/main.nf




process LISSERO {
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"
    afterScript "rm ${prefix}.fasta"
    // TODO add in log message saying what went wrong with the sample
    errorStrategy 'ignore' // TODO set a proper strategy once the issues with the mash parsing script are solved e.g. the ambiguous top hits

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*${params.lissero.tsv_ext}"), emit: tsv
    path "versions.yml", emit: versions



    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    gunzip -c $fasta > ${prefix}.fasta
    lissero $args ${prefix}.fasta > ${prefix}.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lissero: \$( echo \$(lissero --version 2>&1) | sed 's/^.*LisSero //' )
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.lissero.tsv_ext}
    touch versions.yml
    """
}
