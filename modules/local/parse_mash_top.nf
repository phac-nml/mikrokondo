// Determine if sample is from a metagenomic sample or isolate
// Only true and false are read to stdout to be dcided from

// TODO need to add better 'top-hit' handling to the mash parsing script as sometimes the top hit is actually ambiguous e.g. proportions are equal

process PARSE_MASH_TOP {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(mash_screen)

    output:
    tuple val(meta), env('RESULT'), emit: mash_out
    path "versions.yml", emit: versions

    script:
    """
    RESULT=\$(mash_parse.py -r top -i $mash_screen)

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
