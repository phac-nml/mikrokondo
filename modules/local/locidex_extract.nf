/*
Locidex ectract fastas for allele calling

*/



process LOCIDEX_EXTRACT {
    // TODO awaiting containers
    tag "$meta.id"
    label "process_low"

    input:
    tuple val(meta), path(fasta), path(db)

    output:
    tuple val(meta), path("${params.locidex.extraction_dir}/*${params.locidex.extracted_seqs_suffix}"), path(db), emit: extracted_seqs
    path "versions.yml", emit: versions

    script:
    def prefix = "${meta.id}"
    """
    locidex extract --mode ${params.locidex.extraction_mode} \\
    -i ${fasta} \\
    --n_threads ${task.cpus} \\
    -o ${params.locidex.extraction_dir} -d ${db} --force \\
    --min_evalue ${params.locidex.min_evalue} \\
    --min_dna_len ${params.locidex.min_dna_len} \\
    --min_aa_len ${params.locidex.min_aa_len} \\
    --max_dna_len ${params.locidex.min_dna_len} \\
    --min_dna_ident ${params.locidex.min_dna_ident} \\
    --min_aa_ident ${params.locidex.min_aa_ident} \\
    --min_dna_match_cov ${params.locidex.min_dna_match_cov} \\
    --min_aa_match_cov ${params.locidex.min_aa_match_cov} \\
    --max_target_seqs ${params.locidex.max_target_seqs}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex extract: \$(echo \$(locidex extract -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """
}
