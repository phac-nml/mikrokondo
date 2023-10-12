// Module for running ectyper
// borrowed from: https://github.com/nf-core/modules/blob/master/modules/nf-core/ectyper/main.nf



process ECTYPER{
    tag "$meta.id"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"
    // TODO add ECTyper temporary directory issues to docs

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}/*${params.ectyper.log_ext}"), emit: log
    tuple val(meta), path("${prefix}/*${params.ectyper.tsv_ext}"), emit: tsv
    tuple val(meta), path("${prefix}/*${params.ectyper.txt_ext}"), emit: txt, optional: true
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi
    mkdir $prefix
    ectyper $args --cores $task.cpus --output $prefix --input $fasta_name
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ectyper: \$(echo \$(ectyper --version 2>&1)  | sed 's/.*ectyper //; s/ .*\$//')
    END_VERSIONS
    """

}
