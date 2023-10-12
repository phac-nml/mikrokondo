

process PARSE_KRAKEN {
    tag "$meta.id"
    label "process_low"

    input:
    tuple val(meta), path(kraken_report)

    output:
    tuple val(meta), stdout, emit: kraken_top
    path "versions.yml", emit: versions

    script:
    """
    kraken2_tophit.py $kraken_report $params.kraken.tophit_level
    # If no species identified or there is an error, emit that from the pipeline
    # if [ \$? -ne 0 ]
    # then
    #     echo "No Species Identified"
    # fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

}
