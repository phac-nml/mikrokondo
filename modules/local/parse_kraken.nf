

process PARSE_KRAKEN {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(kraken_report)

    output:
    tuple val(meta), env('RESULT'), emit: kraken_top
    path "versions.yml", emit: versions

    script:
    """
    RESULT=\$(kraken2_tophit.py $kraken_report $params.kraken.tophit_level)
    # If no species identified or there is an error, emit that from the pipeline
    # if [ RESULT -ne 0 ]
    # then
    #     RESULT="No Species Identified"
    # fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    echo "stub"
    touch versions.yml
    """

}
