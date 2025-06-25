process UNIQUE_SOFTWARE_VERSIONS {
    tag "SoftwareVersions per Sample"
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
