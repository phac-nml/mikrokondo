// Combine reads with the same id

process COMBINE_DATA{
    tag "${meta.id}"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(forward_reads), path(reverse_reads), path(long_reads), path(assembly)

    output:
    tuple val(meta), path("out/${prefix}_R1.merged.fastq.gz"), path("out/${prefix}_R2.merged.fastq.gz"), path("out/${prefix}.merged.fastq.gz"), path("out/${prefix}.merged.fasta.gz"), emit: reads
    path "versions.yml", emit: versions


    script:
    // Adding an output directory to preven name collisions in case of some unlikely event
    prefix = task.ext.prefix ?: meta.id
    def cmd = null
    if(meta.hybrid){
        cmd = "cat ${forward_reads.join(' ')} > out/${prefix}_R1.merged.fastq.gz; " + \
            "cat ${reverse_reads.join(' ')} > out/${prefix}_R2.merged.fastq.gz; " +
            "cat ${long_reads.join(' ')} > out/${prefix}.merged.fastq.gz"
    }else if(meta.single_end){
        cmd = "cat ${long_reads.join(' ')} > out/${prefix}.merged.fastq.gz"
    }else if(meta.assembly){
        cmd = "cat ${assembly.join(' ')} > out/${prefix}.merged.fasta.gz"
    }else{
        cmd = "cat ${forward_reads.join(' ')} > out/${prefix}_R1.merged.fastq.gz; " +
            "cat ${reverse_reads.join(' ')} > out/${prefix}_R2.merged.fastq.gz"
    }
    // creating dummy outputs so that all outputs exist for any scenario
    """
    mkdir out
    $cmd
    touch out/${prefix}_R1.merged.fastq.gz
    touch out/${prefix}_R2.merged.fastq.gz
    touch out/${prefix}.merged.fastq.gz
    touch out/${prefix}.merged.fasta.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
        touch: \$(echo \$(touch --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
    END_VERSIONS
    """


}
