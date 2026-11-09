// Determine if sample is from a metagenomic sample or isolate
// Only true and false are read to stdout to be decided from

process PARSE_MASH_CLASSIFY {
    tag "$meta.id"
    label "process_low"
    // container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(mash_screen)
    path equivalent_taxa

    output:
    tuple val(meta), env('RESULT'), emit: mash_out
    path "versions.yml", emit: versions

    script:
    """
    RESULT=\$(MKRust mash-metagenomic -i $mash_screen -e $equivalent_taxa -p 0.9)

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
