// run kraken on input reads

process KRAKEN {
    tag "$meta.id"
    label "process_high"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"


    input:
    tuple val(meta), path(contigs)
    path db

    output:
    tuple val(meta), path("*.${params.kraken.classified_suffix}*"), optional: true, emit: classified_contigs
    tuple val(meta), path("*.${params.kraken.unclassified_suffix}*"), optional: true, emit: unclassified_contigs
    tuple val(meta), path("*.${params.kraken.output_suffix}.txt"), emit: kraken_output
    tuple val(meta), path("*${params.kraken.report_suffix}.txt"), emit: report
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    kraken2 --db $db --memory-mapping --threads $task.cpus --output ${meta.id}.${params.kraken.output_suffix}.txt --report ${prefix}.kraken2.${params.kraken.report_suffix}.txt --classified-out ${meta.id}.${params.kraken.classified_suffix}.fasta --unclassified-out ${meta.id}.${params.kraken.unclassified_suffix}.fasta $args --gzip-compressed $contigs
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(echo \$(kraken2 --version 2>&1) | sed 's/^.*Kraken version //; s/ .*\$//')
    END_VERSIONS
    """


}
