//Trim pacbio and nanopore reads using nanofilter

process CHOPPER_TRIM{
    tag "${meta.id}"
    label "process_medium"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"


    fair true
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}${params.chopper.fastq_ext}"), emit: reads
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    // Catting all reads incase there are multiple per a sample
    """
    cat $reads | gunzip -c | chopper $args | gzip > ${meta.id}${params.chopper.fastq_ext}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chopper: \$(chopper --version 2>&1 | sed -e "s/chopper //g")
    END_VERSIONS
    """
}
