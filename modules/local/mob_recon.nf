// MobRecon adapted from: https://github.com/nf-core/modules/blob/master/modules/nf-core/mobsuite/recon/main.nf

process MOBSUITE_RECON {
    tag "$meta.id"
    label 'process_medium'

    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}/chromosome${params.mobsuite_recon.fasta_ext}"), emit: chromosome
    tuple val(meta), path("${prefix}/${params.mobsuite_recon.contig_report}")   , emit: contig_report
    tuple val(meta), path("${prefix}/plasmid_*${params.mobsuite_recon.fasta_ext}"), emit: plasmids, optional: true
    tuple val(meta), path("${prefix}/${params.mobsuite_recon.mob_results_file}"), emit: mobtyper_results, optional: true
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    mob_recon --infile $fasta_name $args --num_threads $task.cpus --outdir results --sample_id $prefix
    mv results ${prefix}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mobsuite: \$(echo \$(mob_recon --version 2>&1) | sed 's/^.*mob_recon //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    prefix = "stub"
    """
    mkdir stub
    touch stub/chromosome${params.mobsuite_recon.fasta_ext}
    touch stub/${params.mobsuite_recon.contig_report}
    touch stub/plasmid_stub${params.mobsuite_recon.fasta_ext}
    touch stub/${params.mobsuite_recon.mob_results_file}
    touch versions.yml
    """
}
