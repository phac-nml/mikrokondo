// Bakta download db, meant as a cmd line utility only


process BAKTA_DB_DOWNLOAD {
    label 'process_single'
    storeDir "${params.bakta.db_output}"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    output:
    path "db*", emit: db
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    """
    bakta_db download --type ${params.bakta.db_type} --output ./
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bakta: \$(echo \$(bakta_db --version) 2>&1 | cut -f '2' -d ' ')
    END_VERSIONS
    """

}
