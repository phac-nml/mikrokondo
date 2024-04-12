/*seperate kraken2 contigs into their seperate values

TODO need to add in test for if data could not be binned further
*/


process BIN_KRAKEN2{
    tag "$meta.id"
    label "process_low"
    cache 'deep' // ! Deep caching is required to not bungle up the later metadata updates on resumes
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(contigs), path(kraken_report), path(kraken_output)
    val taxonomic_level

    output:
    tuple val(meta), path("${prefix}_*${params.kraken_bin.fasta_ext}"), emit: binned_fastas

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    kraken2_bin.py ${kraken_report} ${kraken_output} ${contigs} ${taxonomic_level}
    for i in *_binned.fasta
    do
        mv \$i ${prefix}_\$i
        gzip ${prefix}_\$i
    done
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    prefix = "stub"
    """
    touch stub_Escherichia${params.kraken_bin.fasta_ext}
    touch stub_Salmonella${params.kraken_bin.fasta_ext}
    touch versions.yml
    """
}
