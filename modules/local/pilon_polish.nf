// Use pilon to polish consensus sequences from pilon


process PILON_POLISH {
    tag "$meta.id"
    label 'process_high'
    memory  {task.memory * task.attempt}
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"
    errorStrategy { task.attempt <= params.pilon.max_memory_multiplier ?: 'retry'}


    // NOTE some inputs not used, they are just there to maintain a common interface with other polishing programs
    input:
    tuple val(meta), path(reads), path(contigs), path(bam), path(bai) // may need to copy the bai into the work dir

    output:
    tuple val(meta), path("*${params.pilon.fasta_ext}"), path(reads), emit: pilon_fasta
    tuple val(meta), path("*${params.pilon.vcf_ext}"), emit: pilon_vcf
    tuple val(meta), path("*${params.pilon.changes_ext}"), emit: pilon_changes

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ""
    def unzipped_contigs = "unzipped_contigs.fasta"
    """
    gzip -d -c $contigs > $unzipped_contigs
    #pilon --genome $unzipped_contigs --bam $bam $args --output $prefix --outdir ./ --changes --vcf --vcfqe
    pilon -Xmx${task.memory.toGiga()}G --genome $unzipped_contigs --bam $bam $args --output $prefix --outdir ./ --changes --vcf --vcfqe
    gzip ${prefix}.fasta
    rm $unzipped_contigs
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pilon: \$(pilon --version 2>&1)
    END_VERSIONS
    """
}
