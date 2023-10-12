// Convert a samfile to bam file and index it


process SAM_TO_BAM{
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path("*${params.samtools.bam_ext}"), path("*${params.samtools.bai_ext}"), emit: bam_data
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bam_name = "${prefix}${params.samtools.bam_ext}"
    def temp_bam = "temp_bam.bam"
    """
    samtools view -b1 $sam > $temp_bam
    samtools sort $temp_bam > $bam_name
    samtools index $bam_name
    rm $temp_bam
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version 2>&1)
    END_VERSIONS
    """

}
