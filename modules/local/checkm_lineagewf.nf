// Checkm module for quality analysis: taking from the Nf-core module but also
// taking some inspiration from the bactopia module here: https://github.com/bactopia/bactopia/blob/master/modules/nf-core/checkm/lineagewf/main.nf

process CHECKM_LINEAGEWF {
    tag "$meta.id"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}/*"), emit: checkm_output
    tuple val(meta), path("${prefix}/${prefix}${params.checkm.results_ext}"), emit: checkm_results
    tuple val(meta), path("${prefix}/${params.checkm.lineage_ms}"), emit: lineage_ms
    path "versions.yml", emit: versions


    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(params.checkm.gzip_ext) ? true : false
    def fasta_name = fasta.getName().replace(params.checkm.gzip_ext, "")
    def file_ext = file(fasta_name).getExtension()
    """
    export MPLCONFIGDIR=$PWD
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi
    mkdir bins
    mv *.${file_ext} ./bins
    checkm lineage_wf ./bins/ ${prefix} --tab_table --threads ${params.checkm.threads} \\
        -x ${file_ext} \\
        --pplacer_threads ${params.checkm.threads} \\
        --alignment_file  ${prefix}/${prefix}${params.checkm.alignment_ext} \\
        --file ${prefix}/${prefix}${params.checkm.results_ext} \\
        $args
    rm -rf ./bins
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm: \$(echo \$(checkm -h 2>&1) | sed 's/.*CheckM v//;s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    mkdir test/bins/
    touch test/bins/genes.faa
    touch test/bins/genes.gff
    touch test/bins/hmmer.analyze.txt
    touch test/bins/hmmer.tree.txt
    touch test/test-results.txt
    touch test/lineage.ms
    touch versions.yml
    """

}
