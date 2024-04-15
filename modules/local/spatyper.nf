/*Spatyper, taken from: https://github.com/nf-core/modules/blob/master/modules/nf-core/spatyper/main.nf

*/


process SPATYPER {
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(fasta)
    path repeats
    path repeat_order

    output:
    tuple val(meta), path("*${params.spatyper.tsv_ext}"), emit: tsv
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_args = repeats && repeat_order ? "-r ${repeats} -o ${repeat_order}" : ""
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi
    spaTyper $args $input_args --fasta $fasta_name --output ${prefix}${params.spatyper.tsv_ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spatyper: \$( echo \$(spaTyper --version 2>&1) | sed 's/^.*spaTyper //' )
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.spatyper.tsv_ext}
    touch versions.yml
    """
}
