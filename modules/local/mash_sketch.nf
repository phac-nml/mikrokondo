// Run mash sketch on a genome and include comments and ID


process MASH_SKETCH{
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(fasta), val(comment)

    output:
    tuple val(meta), path("*${params.mash.sketch_ext}"), emit: sketches

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mash sketch $fasta -I '${prefix}' -C '${comment}' -o ${prefix} -k ${params.mash.sketch_kmer_size}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mash: \$( mash --version )
    END_VERSIONS
    """
}
