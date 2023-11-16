/*
Sketch reads to estimate the samples genome size
*/


process MASH_ESTIMATE{
    label 'process_low'
    tag "${prefix}"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(reads)
    val long_reads_p

    output:
    tuple val(meta), path("${prefix}${params.mash.sketch_ext}"), emit: sketch
    //tuple val(meta), path("${prefix}${params.mash.json_ext}"), emit: estimates
    tuple val(meta), path("genome_size.txt"), emit: gsize
    path "versions.yml", emit: versions

    script:
    def lr_flag = long_reads_p ? "LR" : "SR" // Tag to differentiate reads in hybrid assembly runs
    def hybrid_tag = params.platform == params.opt_platforms.hybrid ? ".${lr_flag}" : ""
    prefix = task.ext.prefix ?: "${meta.id}"
    prefix = prefix + hybrid_tag
    """
    mash sketch -r -m ${params.mash.min_kmer} -k ${params.mash.sketch_kmer_size} -o ${prefix} $reads 2>&1 | sed -n 's/Estimated genome size: //gp' | xargs -I size printf "%.f" size > genome_size.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mash: \$( mash --version )
    END_VERSIONS
    """

    stub:
    prefix = "stub"
    """
    touch stub${params.mash.sketch_ext}
    touch genome_size.txt
    echo "100000" > genome_size.txt
    touch versions.yml
    """
}
