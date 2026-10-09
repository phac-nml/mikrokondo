// Determine if sample is from a metagenomic sample or isolate
// Only true and false are read to stdout to be dcided from

process PARSE_MASH_CLASSIFY {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(mash_screen)
    path equivalent_taxa

    output:
    tuple val(meta), env('RESULT'), emit: mash_out
    path "versions.yml", emit: versions

    script:
    """
    RESULT=\$(mash_parse.py -r classify -i $mash_screen -e $equivalent_taxa)

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
