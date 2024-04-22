// Dump database versions for StarAMR


process STARAMR_DUMP_DB_VERSIONS {
    tag "StarAMR DB Versions"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"
    cache false

    input:
    path(db)

    output:
    path("StarAMRDBVersions.txt"), emit: db_versions
    path "versions.yml", emit: versions


    script:
    def args = ""
    if(db){
        args = args + " $db"
    }
    """
    staramr db info $args > StarAMRDBVersions.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        staramr: \$(echo \$(staramr -V 2>&1) | sed 's/^.*staramr //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch StarAMRDBVersions.txt
    touch versions.yml
    """

}
