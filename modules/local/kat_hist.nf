// Run kat hist

// TODO estimate coverage throught the following information from KAT:
//   N = Total no. of k-mers/Coverage
//     = Area under curve /mean coverage(14)

process KAT_HIST{
    tag "$meta.id"
    label "process_medium"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"


    input:
    tuple val(meta), path(reads)
    val long_reads_p

    output:
    tuple val(meta), path("*${params.kat.hist_ext}"), emit: hist
    tuple val(meta), path("*${params.kat.json_ext}"), emit: json
    tuple val(meta), path("*${params.kat.png_ext}"), emit: png, optional: true
    tuple val(meta), path("*${params.kat.postscript_ext}"), emit: postscript, optional: true
    tuple val(meta), path("*${params.kat.pdf_ext}"), emit: pdf, optional: true
    tuple val(meta), path("*${params.kat.jfhash_ext}*"), emit: jf_hash, optional: true
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""

    args = args + "-p ${params.kat.output_type}"
    def lr_flag = long_reads_p ? "LR" : "SR" // Tag to differentiate reads in hybrid assembly runs
    def hybrid_tag = params.platform == params.opt_platforms.hybrid ? ".${lr_flag}" : ""
    prefix = task.ext.prefix ?: "${meta.id}"
    prefix = prefix + hybrid_tag
    // TODO perhaps switch to reads[0] and only use forward strand
    """
    export MPLCONFIGDIR=\$PWD
    kat hist --threads $task.cpus $args --output_prefix ${prefix}.hist $reads
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kat: \$( kat hist --version | sed 's/kat //' )
    END_VERSIONS
    """
}

