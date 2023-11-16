/* Determine contamination present with mash

Mash outputs:
identity, shared-hashes, median-multiplicity, p-value, query-ID, query-comment
*/


process MASH_SCREEN {
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(reads)
    path sequences_sketch

    output:
    tuple val(meta), path("*${prefix_post}"), emit: mash_data
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO figure out how to pass some workflow data with the samples, I do not like how a workflow name is being used as a variable
    // It may need to be listed in the config file, but as It stands I do not like the implementation
    // TODO cleaner option is to pass a variable in determing the prefix as it is already decided
    prefix_post = task.process.toString().contains("QC_READS") ? prefix + params.mash.output_reads_ext : prefix + params.mash.output_taxa_ext
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
