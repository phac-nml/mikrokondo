// Dump database versions for StarAMR


process STARAMR_DUMP_DB_VERSIONS {
    tag "StarAMR DB Versions"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"
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

}
