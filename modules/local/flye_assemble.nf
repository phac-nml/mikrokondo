// Assemble reads with flye
// borrowed from https://github.com/nf-core/modules/blob/master/modules/nf-core/flye/main.nf



process FLYE_ASSEMBLE{
    tag "$meta.id"
    label 'process_high'
    label 'process_high_memory'
    label 'process_long'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    memory { task.memory * task.attempt}
    // TODO check if --debug flag should be added to flye to actually  turns off the debug logging?

    input:
    tuple val(meta), path(reads)
    val mode

    output:
    tuple val(meta), path("*${params.flye.fasta_ext}"), emit: contigs
    tuple val(meta), path("*${params.flye.gfa_ext}")  , emit: graphs
    tuple val(meta), path("*${params.flye.gv_ext}")   , emit: gv
    tuple val(meta), path("*${params.flye.txt_ext}")     , emit: txt
    tuple val(meta), path("*${params.flye.log_ext}")     , emit: log
    tuple val(meta), path("*${params.flye.json_ext}")    , emit: json
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ""
    if(meta.metagenomic){
        args = args + "--meta "
    }
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    flye $mode $reads --out-dir . --threads $task.cpus $args
    gzip -c assembly.fasta > ${prefix}.assembly.fasta.gz
    gzip -c assembly_graph.gfa > ${prefix}.assembly_graph.gfa.gz
    gzip -c assembly_graph.gv > ${prefix}.assembly_graph.gv.gz
    mv assembly_info.txt ${prefix}.assembly_info.txt
    mv flye.log ${prefix}.flye.log
    mv params.json ${prefix}.params.json
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$( flye --version )
    END_VERSIONS
    """

}
