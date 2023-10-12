// sub sample reads to set depth


process SEQTK_SAMPLE{
    tag "${meta.id}"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(reads), val(sample_fraction)

    output:
    // TODO outputting sample fraction to match cardinality of non sampled read set, need to find a better solution...
    tuple val(meta), path("*${params.seqtk.reads_ext}"), val(sample_fraction), emit: sampled_reads
    path "versions.yml", emit: versions

    script:
    def paired_read_size = 2
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cmd = ""

    if(!meta.single_end && reads.size() == paired_read_size){ // make sure there are actually two read sets
        cmd = "seqtk sample -s ${params.seqtk.seed} $args ${reads[0]} $sample_fraction | gzip --no-name > ${prefix}_R1${params.seqtk.reads_ext}" + \
        "\nseqtk sample -s ${params.seqtk.seed} $args ${reads[1]} $sample_fraction | gzip --no-name > ${prefix}_R2${params.seqtk.reads_ext}"
    }else{
        cmd = "seqtk sample -s ${params.seqtk.seed} $args ${reads[0]} $sample_fraction | gzip --no-name > ${prefix}${params.seqtk.reads_ext}\n"
    }
    // * HEREDOC string looks weird, but this is due to the version string not being output properly, but this seemed to fix the issue
    """
    $cmd
    cat <<-END_VERSIONS > versions.yml\n"${task.process}":\n    seqtk: \$(echo \$(seqtk 2>&1) | sed 's/^.*Version: //; s/ .*\$//')\nEND_VERSIONS
    """
}
