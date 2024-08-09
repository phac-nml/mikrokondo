/* Locidex search function for the allele calling

*/

process LOCIDEX_SEARCH {

    tag "$meta.id"
    label "process_medium"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(fasta), path(db)

    output:
    tuple val(meta), path("${output_json}"), emit: allele_calls
    tuple val(meta), path("${output_gbk}"), emit: annotations, optional: true
    path "versions.yml", emit: versions

    script:
    // Large portion of arguments cutout due to causing issues when running
    output_json = "${meta.id}${params.locidex.seq_store_suffix}"
    output_gbk = "${meta.id}${params.locidex.gbk_suffix}"

    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    locidex search -q ${fasta_name} \\
    --n_threads ${task.cpus} \\
    -o . \\
    -d ${db} --force \\
    --min_evalue ${params.locidex.min_evalue} \\
    --min_dna_len ${params.locidex.min_dna_len} \\
    --min_aa_len ${params.locidex.min_aa_len} \\
    --max_dna_len ${params.locidex.max_dna_len} \\
    --min_dna_ident ${params.locidex.min_dna_ident} \\
    --min_aa_ident ${params.locidex.min_aa_ident} \\
    --min_dna_match_cov ${params.locidex.min_dna_match_cov} \\
    --min_aa_match_cov ${params.locidex.min_aa_match_cov} \\
    --max_target_seqs ${params.locidex.max_target_seqs}

    test -f seq_store.json && gzip -c seq_store.json > $output_json && rm seq_store.json
    test -f annotations.gbk && gzip -c annotations.gbk > $output_gbk && rm annotations.gbk

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex search: \$(echo \$(locidex search -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """
}
