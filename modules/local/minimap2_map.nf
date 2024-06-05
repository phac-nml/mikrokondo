// Map reads with minimap2
// TODO refactoring for minimap2 modules needed
// TODO minimap2 can index and map in one step

process MINIMAP2_MAP {
    tag "$meta.id"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    fair true
    input:
    tuple val(meta), path(reads), path(index), path(contigs)
    val paf_out

    output:
    tuple val(meta), path(reads), path("*{${params.minimap2.mapped_paf_ext},${params.minimap2.mapped_sam_ext}}"), path(contigs), emit: mapped_data
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    // TODO add in platfrom selector for hybrid platrforms
    def platform_compare = params.platform == params.opt_platforms.hybrid ? params.long_read_opt : null // an optional param to add to a work flow


    // Set setting to an optional platform for hybrid assemblies
    def platform_comp = params.platform == params.opt_platforms.hybrid ? platform_compare : params.platform
    if(platform_comp == params.opt_platforms.illumina){
        mapping_setting = params.r_contaminants.mm2_illumina;
    }else if(platform_comp == params.opt_platforms.ont){
        mapping_setting = params.r_contaminants.mm2_ont;
    }else if( platform_comp == params.opt_platforms.pacbio){
        mapping_setting = params.r_contaminants.mm2_pac;
    }else{
        log.error "$task.process - Platform $platform_comp is unknown, mapping to assembly will proceed with nanopore settings";
        mapping_setting = params.r_contaminants.mm2_ont
    }


    def mapped_ext = paf_out ? ".paf" : ".sam"
    args = paf_out ? args : args + " -a"
    //def reads_in = meta.single_end ? "$reads" : "${reads[0]} ${reads[1]}"
    def reads_in = reads.size() ? "$reads" : "${reads[0]} ${reads[1]}"
    """
    minimap2 $mapping_setting $args $index $reads_in > ${meta.id}${mapped_ext}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """

    stub:
    def mapped_ext = paf_out ? ".paf" : ".sam"
    """
    touch stub${mapped_ext}
    touch versions.yml
    """
}
