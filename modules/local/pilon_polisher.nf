// In house iterative pilon polisher

process PILON_ITER {
    tag "$meta.id"
    label 'process_medium'
    memory  {task.memory * task.attempt}
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(reads), path(contigs)

    output:
    tuple val(meta), path("*${params.pilon_iterative.fasta_ext}"), path(reads), emit: pilon_fasta
    tuple val(meta), path("*${params.pilon_iterative.vcf_ext}"), emit: pilon_vcf
    tuple val(meta), path("*${params.pilon_iterative.changes_ext}"), emit: pilon_changes
    tuple val(meta), path("*${params.pilon_iterative.bam_ext}"), emit: bam
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def max_iterations = null
    switch (params.platform){
        case params.opt_platforms.illumina:
            max_iterations = params.pilon_iterative.max_polishing_illumina;
            break;
        case params.opt_platforms.hybrid:
            // Paired end reads are assumed to be illumina
            max_iterations = params.pilon_iterative.max_polishing_nanopore;
            break;
        case params.opt_platforms.nanopore:
            max_iterations = params.pilon_iterative.max_polishing_nanopore;
            break;
        case params.opt_platforms.pacbio:
            max_iterations = params.pilon_iterative.max_polishing_pacbio;
            break;
        default:
            log.warn "[$task.process] No preset for max iterative polishing rounds for ${params.platform}"
            log.warn "[$task.process] Setting max polishing rounds to ${params.pilon_iterative.max_polishing_nanopore}"
            max_iterations = params.pilon_iterative.max_polishing_nanopore;
            break;
    }
    def unzipped_contigs = "unzipped_contigs.fasta"
    log.info "Iteratively polishing ${prefix}"

    // numbered the files are named as {prefix}_{iteration}.blah
    // below is a convaluted shell string to get the last output sample
    // tail -n +2 removes the first line of the listed output (output starts at line 2)
    // TODO can set output to be related to max_polisihing runs
    """
    gzip -d -c $contigs > $unzipped_contigs
    pilonpolisher -c $unzipped_contigs -r $reads -a ${task.memory.toGiga()} -p ${prefix} -m ${max_iterations}
    # commands to get all put top entry in list to clean them up
    rm $unzipped_contigs
    rm $contigs
    ls -lr *_?.fasta | tail -n+2 | rev | cut -d' ' -f 1 | rev | xargs rm
    ls -lr *_?${params.pilon_iterative.vcf_ext} | tail -n+2 | rev | cut -d' ' -f 1 | rev | xargs rm
    ls -lr *_?${params.pilon_iterative.changes_ext} | tail -n+2 | rev | cut -d' ' -f 1 | rev | xargs rm
    ls -lr *_?${params.pilon_iterative.bam_ext} | tail -n+2 | rev | cut -d' ' -f 1 | rev | xargs rm
    mv ${prefix}_?.fasta ${prefix}_polished.fasta
    gzip *.fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pilonpolisher: No version statement listed
    END_VERSIONS
    """

    stub:
    """
    touch stub_polished_${params.pilon_iterative.fasta_ext}
    touch stub_polished_${params.pilon_iterative.vcf_ext}
    touch stub_polished_${params.pilon_iterative.changes_ext}
    touch stub_polished_${params.pilon_iterative.bam_ext}
    touch versions.yml
    """
}
