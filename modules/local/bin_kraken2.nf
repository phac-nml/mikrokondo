/*seperate kraken2 contigs into their seperate values

TODO need to add in test for if data could not be binned further
*/


process BIN_KRAKEN2{
    tag "$meta.id"
    label "process_low"
    cache 'deep' // ! Deep caching is required to not bungle up the later metadata updates on resumes
    //container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(contigs), path(kraken_report), path(kraken_output)
    val taxonomic_level

    output:
    tuple val(meta), path("${prefix}_*${params.kraken_bin.fasta_ext}"), emit: binned_fastas

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    MKRust kraken2-bin --report ${kraken_report} --kraken-output ${kraken_output} --contigs ${contigs} --prefix ${prefix} -t ${taxonomic_level}
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
