// Workflow for assembling reads
// TODO add in read sub-sampling to reduce errors

include { SEQTK_SIZE } from "../../modules/local/seqtk_size.nf"
include { SPADES_ASSEMBLE } from "../../modules/local/spades_assemble.nf"
include { FLYE_ASSEMBLE } from "../../modules/local/flye_assemble.nf"
include { MINIMAP2_INDEX } from "../../modules/local/minimap2_index.nf"
include { MINIMAP2_MAP } from "../../modules/local/minimap2_map.nf"
include { RACON_POLISH } from "../../modules/local/racon_polish.nf"
include { BANDAGE_IMAGE } from "../../modules/local/bandage_image.nf"


workflow ASSEMBLE_READS{
    take:
    sample_data // tuple val(meta), path(reads)

    main:
    versions = Channel.empty()
    final_contigs = Channel.empty()
    reports = Channel.empty()

    // no report channel here?
    base_counts = SEQTK_SIZE(sample_data)
    reports = reports.mix(base_counts.base_counts.map{
        meta, file_bc -> tuple(meta, params.seqtk_size, extract_base_count(meta, file_bc));
    })

    versions = versions.mix(base_counts.versions)


    def platform_comp = params.platform.replaceAll("\\s", "").toString() // strip whitespace from entries
    if(platform_comp == params.opt_platforms.illumina){
        ch_assembled = SPADES_ASSEMBLE(sample_data)

    }else if(platform_comp == params.opt_platforms.ont || platform_comp == params.opt_platforms.pacbio){
        def options = ["hq", "corr", "raw"]
        def read_type = "hq"
        if(params.flye_read_type in options){
            read_type = params.flye_read_type
        }else{
            log.warn "No read type quality type specified for flye. Defualting to reads as high-quality if Nanopre or hifi if pacbio."
        }
        def def_mode = params.flye[params.platform][read_type]
        ch_assembled = FLYE_ASSEMBLE(sample_data, Channel.value(def_mode))


    }
    else{
        log.error "Platform not recognized in workflow ASSEMBLE_READS: $platform_comp"
        exit(0)
    }
    versions = versions.mix(ch_assembled.versions)


    // TODO test output
    BANDAGE_IMAGE(ch_assembled.graphs)
    versions = versions.mix(BANDAGE_IMAGE.out.versions)


    if(!params.skip_polishing){
        // TODO move this too polishing
        // RACON is next and is common in all steps
        minimap2_idx = MINIMAP2_INDEX(ch_assembled.contigs)
        //TODO Move mapping to its own workflow
        versions = versions.mix(minimap2_idx.versions)
        ch_mapping_data = sample_data.join(minimap2_idx.index)
        //Decided to leave Racon out of the polishing work flow but to wrap this in statement in a optional value in the future
        output_paf = Channel.value(true)
        mapped_data = MINIMAP2_MAP(ch_mapping_data.join(ch_assembled.contigs), output_paf)
        versions = versions.mix(mapped_data.versions)
        racon_out = RACON_POLISH(mapped_data.mapped_data)
        final_contigs = racon_out.racon_polished
        versions = versions.mix(racon_out.versions)
    }else{
        final_contigs = ch_assembled.contigs
    }

    emit:
    contigs = ch_assembled.contigs
    graphs = ch_assembled.graphs
    final_contigs = final_contigs
    base_counts = base_counts.base_counts
    versions = versions
    reports = reports
}


def extract_base_count(meta, data){
    //TODO add in error handler for toLong()
    def base_count_pos = 1;

    def rows = data.splitCsv(header: false, sep: '\t') // only one line should be present
    if(rows.size() > 1){
        log.error "Seqtk size output multiple rows. Output is incorrect for: ${meta.id}. Bailing out"
        exit 1
    }
    def base_count = rows[0][base_count_pos];
    def base_long = base_count.toLong();
    return base_long
}
