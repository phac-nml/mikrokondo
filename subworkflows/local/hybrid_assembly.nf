// Perform hybrid assembly
include { UNICYCLER_ASSEMBLE } from '../../modules/local/unicycler_assemble.nf'
include { MINIMAP2_INDEX } from '../../modules/local/minimap2_index.nf'
include { MINIMAP2_MAP } from '../../modules/local/minimap2_map.nf'
include { FLYE_ASSEMBLE } from "../../modules/local/flye_assemble.nf"
include { RACON_POLISH } from "../../modules/local/racon_polish.nf"
include { BANDAGE_IMAGE } from "../../modules/local/bandage_image.nf"
include { PILON_ITER } from "../../modules/local/pilon_polisher.nf"

workflow HYBRID_ASSEMBLY {

    take:
    reads // [meta, short_reads, long_reads]

    main:
    versions = Channel.empty()
    ch_contigs = Channel.empty()
    ch_uni_assembly = Channel.empty()
    ch_uni_log = Channel.empty()
    ch_pilon_vcf = Channel.empty()
    ch_pilon_changes = Channel.empty()

    if(params.hybrid_unicycler){
        log.info "Running Unicycler for hybrid assembly"
        unicycler_assembled = UNICYCLER_ASSEMBLE(reads)
        versions = versions.mix(unicycler_assembled.versions)
        ch_contigs = unicycler_assembled.scaffolds
        // Join in the reads to run unicycler in quast so that it matches pilon_polsihing output
        ch_contigs = ch_contigs.join(reads)
        ch_contigs.map{
            meta, contigs, sr, lr -> tuple(meta, contigs, sr + lr)
        }

        ch_uni_log = unicycler_assembled.log
        ch_uni_assembly = unicycler_assembled.assembly

        BANDAGE_IMAGE(unicycler_assembled.assembly)
        versions = versions.mix(BANDAGE_IMAGE.out.versions)
    }else{
        log.info "Running hybrid assembly using Flye->Racon then pilon polishing with short reads"
        def sequencing_mode = null
        if(params.long_read_opt == params.opt_platforms.ont){
            sequencing_mode = params.flye[params.long_read_opt].hq
        }

        ch_long_read_data = reads.map{
            meta, short_reads, long_reads -> tuple(meta, long_reads)
        }

        ch_short_read_data = reads.map{
            meta, short_reads, long_reads -> tuple(meta, short_reads)
        }

        FLYE_ASSEMBLE(ch_long_read_data, Channel.value(sequencing_mode))
        versions = versions.mix(FLYE_ASSEMBLE.out.versions)
        BANDAGE_IMAGE(FLYE_ASSEMBLE.out.graphs)
        minimap2_idx = MINIMAP2_INDEX(FLYE_ASSEMBLE.out.contigs)
        versions = versions.mix(MINIMAP2_INDEX.out.versions)
        mapping_data = ch_long_read_data.join(minimap2_idx.index)
        output_paf = Channel.value(true)
        /*
        Racon is polishing using POA's so long reads may work better for polishing here,
        but I need to grok the paper to decide.
        */
        mapped_data = MINIMAP2_MAP(mapping_data.join(FLYE_ASSEMBLE.out.contigs), output_paf)
        RACON_POLISH(mapped_data.mapped_data)
        versions = versions.mix(RACON_POLISH.out.versions)
        // after Racon run short read polishing using the iterative pilon approach
        ch_reads_racon = ch_short_read_data.join(RACON_POLISH.out.racon_polished)
        // TODO missing version string
        PILON_ITER(ch_reads_racon)
        versions = versions.mix(PILON_ITER.out.versions)
        ch_contigs = PILON_ITER.out.pilon_fasta
        ch_pilon_changes = PILON_ITER.out.pilon_changes
        ch_pilon_vcf = PILON_ITER.out.pilon_vcf

        // Merge back in long reads with short read data
        ch_contigs = ch_contigs.join(ch_long_read_data)
    }

    emit:
    fasta = ch_contigs
    vcf = ch_pilon_vcf
    changes = ch_pilon_vcf
    assembly = ch_uni_assembly
    log_unicycler = ch_uni_log
    versions = versions

    //versions = UNICYCLER_ASSEMBLE.out.versions

}
