// Remove phiX from reads and human contaminants from reads

process REMOVE_CONTAMINANTS {
    tag "$meta.id"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(reads)
    path contaminant_fa
    val platform

    output:
    tuple val(meta), path("*.${params.r_contaminants.samtools_output_suffix}${params.r_contaminants.output_ext}"), emit: reads
    path "versions.yml", emit: versions

    script:

    // set Minimap2 settings
    def mapping_setting = null
    // traditional if/else as I find it more readable
    def platform_comp = platform.toString()

    if(platform_comp == params.opt_platforms.illumina){
        mapping_setting = params.r_contaminants.mm2_illumina;
    }else if(platform_comp == params.opt_platforms.ont){
        mapping_setting = params.r_contaminants.mm2_ont;
    }else if( platform_comp == params.opt_platforms.pacbio){
        mapping_setting = params.r_contaminants.mm2_pac;
    }else{
        log.error "$task.process - Platform $params.platform is unknown, decontamination with minimap2 will proceed with nanopore settings";
        mapping_setting = params.r_contaminants.mm2_ont
    }
    def args = task.ext.args ?: ""
    // Set output names
    def minimap2_output = "${meta.id}${params.r_contaminants.mm2_output_ext}"
    def singled_ended = meta.single_end
    if(params.platform == params.opt_platforms.hybrid && (platform_comp == params.opt_platforms.ont || platform_comp == params.opt_platforms.pacbio)){
        singled_ended = true
    }

    def reads_in = singled_ended ? "$reads" : "${reads[0]} ${reads[1]}"
    def reads_out = null


    // over ride meta tag to be inclusive of hybrid assemblies and allow for joining channels on metadata
    def unmapped_flag_sam = 4
    def secondary_unmapped_flag_sam = 8
    def samtools_filtering = unmapped_flag_sam
    if(singled_ended){
        samtools_filtering = unmapped_flag_sam
        reads_out = "-0 ${meta.id}.${params.r_contaminants.samtools_output_suffix}${params.r_contaminants.samtools_output_ext}"

    }else{
        samtools_filtering = samtools_filtering + secondary_unmapped_flag_sam
        log.info "Paired end reads detected for sample ${meta.id}, Note: Singletons will be ignored for further analysis."
        reads_out = "-1 ${meta.id}.R1.${params.r_contaminants.samtools_output_suffix}${params.r_contaminants.samtools_output_ext} -2 ${meta.id}.R2.${params.r_contaminants.samtools_output_suffix}${params.r_contaminants.samtools_output_ext} -s ${meta.id}${params.r_contaminants.samtools_singletons_ext}"
    }
    def zip_singletons = singled_ended ? "" : "gzip *${params.r_contaminants.samtools_singletons_ext}"
    // TODO currently using a megaindex, but there may be a better way

    // -f4 in samtool view filters out unmapped reads
    // -N added to add /1 and /2 to reads with the same name
    def samtools_cmds = "-N -f${samtools_filtering}" // -f4 filters out unmapped reads
    """
    minimap2 $mapping_setting -y $args $contaminant_fa $reads_in > $minimap2_output
    samtools fastq $samtools_cmds $minimap2_output $reads_out
    gzip *${params.r_contaminants.samtools_output_ext}
    $zip_singletons
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch stub.${params.r_contaminants.samtools_output_suffix}${params.r_contaminants.output_ext}
    touch versions.yml
    """
}
