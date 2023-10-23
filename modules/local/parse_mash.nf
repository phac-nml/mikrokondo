// Determine if sample is from a metagenomic sample or isolate
// Only true and false are read to stdout to be dcided from

// TODO need to add better 'top-hit' handling to the mash parsing script as sometimes the top hit is actually ambiguous e.g. proportions are equal

process PARSE_MASH{
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(mash_screen)
    val run_mode

    output:
    tuple val(meta), stdout, emit: mash_out
    path "versions.yml", emit: versions

    script:
    """
    mash_parse.py $run_mode $mash_screen

    # If no species identified, emit that from the pipeline
    #if [ \$? -ne 0 ] && [ "$run_mode" = "top" ]
    #then
    #    echo "No Species Identified"
    #fi
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
