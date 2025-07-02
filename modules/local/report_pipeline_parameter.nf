process REPORT_PIPELINE_PARAMETERS {
    tag "Reporting pipeline parameters"
    label 'process_single'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu%3A20.04' :
    'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(parameter_settings), path(software_versions)

    output:
    tuple val(meta), path("*.mikrokondo.parameters.json"),       emit: parameter
    tuple val(meta), path("*.mikrokondo.software.version.yml"),  emit: versions

    script:
    """
    cp ${parameter_settings} ${meta.id}.mikrokondo.parameters.json
    cp ${software_versions} ${meta.id}.mikrokondo.software.version.yml
    """

}
