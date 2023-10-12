//Workflow for additional polishing

//include { PILON_POLISH } from "../../modules/local/pilon_polish"
include { PILON_ITER } from "../../modules/local/pilon_polisher.nf"
include { MINIMAP2_INDEX } from "../../modules/local/minimap2_index.nf"
include { MINIMAP2_MAP } from "../../modules/local/minimap2_map.nf"
include { SAM_TO_BAM } from "../../modules/local/sam_to_bam.nf"
include { MEDAKA_POLISH } from "../../modules/local/medaka_polish.nf"


workflow POLISH_ASSEMBLIES{

    take:
    sample_data // tuple val(meta), path reads
    assembled_data // tuple val(meta), path contigs

    main:
    versions = Channel.empty()
    ch_sample_assem = sample_data.join(assembled_data)


    if(params.platform == params.opt_platforms.illumina){
        //ch_pilon_polish = sample_data.join(assembled_data)

        PILON_ITER(ch_sample_assem)
        versions = versions.mix(PILON_ITER.out.versions)
        ch_fasta_reads = PILON_ITER.out.pilon_fasta

    }else if(params.platform == params.opt_platforms.ont){
        MEDAKA_POLISH(ch_sample_assem, Channel.value(params.nanopore_chemistry))
        versions = versions.mix(MEDAKA_POLISH.out.versions)
        ch_fasta_reads = MEDAKA_POLISH.out.medaka_polished

    }else{
        log.warn "No additional polishing step availble for ${params.platform} no addittional polishing will be performed."
        // TODO verify pacbio works
        ch_fasta_reads = assembled_data.join(sample_data)
    }

    emit:
    assemblies = ch_fasta_reads
    versions = versions
}

