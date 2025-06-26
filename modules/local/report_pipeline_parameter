process REPORT_PIPELINE_PARAMETERS {
    tag "Reporting pipeline parameters"
    label 'process_single'

    input:
    tuple val(meta), path(software_versions)

    output:
    tuple val(meta), path("*.mikrokondo.yml"), emit: versions

    script:
    """
    cp ${software_versions} ${meta.id}.mikrokondo.yml
    """

}
