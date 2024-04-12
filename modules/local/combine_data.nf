// Combine reads with the same id

process COMBINE_DATA{
    tag "${meta.id}"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(fastq_1), path(fastq_2), path(long_reads), path(assembly)

    output:
    tuple val(meta), path("out/${prefix}_R1.merged.fastq.gz"), path("out/${prefix}_R2.merged.fastq.gz"), path("out/${prefix}.merged.fastq.gz"), path("out/${prefix}.merged.fasta.gz"), emit: reads
    path "versions.yml", emit: versions


    script:
    // Adding an output directory to preven name collisions in case of some unlikely event
    prefix = task.ext.prefix ?: meta.id
    def cmd_ = []
    def fields_merge = meta.fields_merge

    if(fastq_1){
        cmd_ << "cat ${meta.fastq_1.join(' ')} > out/${prefix}_R1.merged.fastq.gz;"
    }
    if(fastq_2){
        cmd_ << "cat ${meta.fastq_2.join(' ')} > out/${prefix}_R2.merged.fastq.gz;"
    }
    if(long_reads){
        cmd_ << "cat ${meta.fastq_2.join(' ')} > out/${prefix}.merged.fastq.gz;"
    }
    if(assembly){
        cmd_ << "cat ${meta.fastq_2.join(' ')} > out/${prefix}.merged.fastq.gz;"
    }
    def cmd = cmd_.join("\n")
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
