// Determine if sample is from a metagenomic sample or isolate
// Only true and false are read to stdout to be dcided from

// TODO need to add better 'top-hit' handling to the mash parsing script as sometimes the top hit is actually ambiguous e.g. proportions are equal

process PARSE_MASH{
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(mash_screen)
    path equivalent_taxa
    val run_mode

    output:
    tuple val(meta), stdout, emit: mash_out
    path "versions.yml", emit: versions

    script:
    def taxa_path = equivalent_taxa && equivalent_taxa.exists() ? "-e $equivalent_taxa" : ""
    """
    mash_parse.py -r $run_mode -i $mash_screen $taxa_path

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
