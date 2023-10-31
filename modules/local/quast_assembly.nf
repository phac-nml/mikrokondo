// Run quast on assembled genomes


process QUAST {
    tag "$meta.id"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"


    input:
    tuple val(meta), path(contigs), path(trimmed_reads)

    output:
    tuple val(meta), path("${prefix}/*"), path(contigs), emit: quast_data
    tuple val(meta), path("${prefix}/${params.quast.report_prefix}${prefix}${params.quast.report_ext}"), path(contigs), emit: quast_table
    path "versions.yml", emit: versions

    script:
    // TODO clean up this messy control flow logic that was written on the fly to decide read parameters
    def args =  task.ext.args ?: ""
    def reads = null
    prefix = meta.id

    def long_read_string = "--single"
    if (params.platform == params.opt_platforms.ont){
        long_read_string = "--nanopore"
    }else if(params.platform == params.opt_platforms.pacbio){
        long_read_string = "--pacbio"
    }

    if(trimmed_reads == []){ // Check if reads were provided to quast or an empty list a.k.a an empty list
        reads = ""
    }else if(params.platform != params.opt_platforms.hybrid){
        reads = meta.single_end ? " ${long_read_string} ${trimmed_reads[0]}" : " --pe1 ${trimmed_reads[0]} --pe2 ${trimmed_reads[1]}"
    }else{
        reads = " --pe1 ${trimmed_reads[0]} --pe2 ${trimmed_reads[1]}  ${long_read_string} ${trimmed_reads[2]}"
    }

    args = args + reads
    """
    export MPLCONFIGDIR=\$PWD
    export OPENBLAS_NUM_THREADS=1
    export OMP_NUM_THREADS=1
    export GOTO_NUM_THREADS=1
    quast $args --threads $task.cpus --output-dir ${prefix} ${contigs.join(' ')}
    for i in ${prefix}/*${params.quast.report_base}.*
    do
        mv \$i \${i/$params.quast.report_base/$prefix}
    done
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    prefix = "stub"
    """
    mkdir stub
    touch stub/stuff.stuff
    echo -e "${params.quast_filter.n50_field}\t${params.quast_filter.nr_contigs_field}\n1000000\t500" > stub/${params.quast.report_prefix}${prefix}${params.quast.report_ext}
    touch versions.yml
    """

}
