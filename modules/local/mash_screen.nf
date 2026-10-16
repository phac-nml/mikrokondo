/* Determine contamination present with mash

Mash outputs:
identity, shared-hashes, median-multiplicity, p-value, query-ID, query-comment
*/


process MASH_SCREEN {
    tag "$meta.id"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(reads)
    path sequences_sketch

    output:
    tuple val(meta), path("*${prefix_post}"), emit: mash_data
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    prefix_post = prefix // Initialize variable so it exists everywhere
    if(task.process.toString().contains("QC_READS") || task.process.toString().contains("QC_LONG_READS")){
      prefix_post = prefix + params.mash.output_reads_ext
      if(meta.hybrid && task.process.toString().contains("QC_LONG_READS")){
        prefix_post = "${prefix}.longreads.${params.mash.output_reads_ext}"
      }
    }else{
      prefix_post = prefix + params.mash.output_taxa_ext
    }
    """
    mash screen $args -p $task.cpus $sequences_sketch $reads > ${prefix_post}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mash: \$( mash --version )
    END_VERSIONS
    """

    stub:
    prefix = "stub"
    prefix_post = task.process.toString().contains("QC_READS") ? prefix + params.mash.output_reads_ext : prefix + params.mash.output_taxa_ext
    """
    touch stub${prefix_post}
    touch versions.yml
    """
}
