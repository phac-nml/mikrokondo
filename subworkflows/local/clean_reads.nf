// Workflow for the cleaning up reads
// TODO Kat can take in all hybrid assembly files at once
include { FASTP_TRIM } from '../../modules/local/fastp_trim.nf'
include { PARSE_FASTP } from '../../modules/local/parse_fastp.nf'
include { CHOPPER_TRIM } from '../../modules/local/chopper_trim.nf'
include { MASH_SCREEN } from '../../modules/local/mash_screen.nf'
include { MASH_ESTIMATE } from '../../modules/local/mash_estimate.nf'
include { REMOVE_CONTAMINANTS } from '../../modules/local/remove_contaminants.nf'
include { PARSE_MASH } from '../../modules/local/parse_mash.nf'
include { KAT_HIST } from '../../modules/local/kat_hist.nf'
include { PARSE_KAT } from '../../modules/local/parse_kat.nf'
include { CHECK_ONT } from '../../modules/local/check_ont.nf'
include { FASTQC } from '../../modules/nf-core/fastqc/main.nf'
include { SEQTK_SAMPLE } from '../../modules/local/seqtk_sample.nf'



workflow QC_READS {
    // TODO add in nanoplot for nanopore data
    take:
    reads // channel [[meta etc], [Read paths], opt: long reads]
    platform // platform opt

    main:
    reports = Channel.empty()
    versions = Channel.empty()
    def platform_comp = platform.toString()


    // TODO add in code to check that there are always enough reads left over after decontamination
    // TODO need to make sure that if one read is unmapped the other is not included as well
    deconned_reads = REMOVE_CONTAMINANTS(reads, file(params.r_contaminants.mega_mm2_idx), Channel.value(platform_comp))
    versions = versions.mix(REMOVE_CONTAMINANTS.out.versions)


    ch_meta_cleaned_reads = FASTP_TRIM(deconned_reads.reads) // can use the json output of this to decide if chopper should be run



    reports = reports.mix(ch_meta_cleaned_reads.fastp_json.map{
        meta, json -> tuple(meta, params.fastp, json)
    })
    versions = versions.mix(ch_meta_cleaned_reads.versions)


    fastp_data = PARSE_FASTP(ch_meta_cleaned_reads.fastp_json)


    passed_read_count = fastp_data.read_count.filter{
        it[1] >= params.min_reads // Read counts are at position 1
    }


    total_base_counts = fastp_data.base_count.map{
        meta, bases -> tuple(meta, bases)
    }

    filtered_samples = ch_meta_cleaned_reads.reads.join(passed_read_count).map{
        meta, reads, count -> tuple(meta, reads) // Only keeping reads that pass a threshold
    }

    // Adding this to to denote long reads for hybrid assembly outputs
    def hyb_lr = false
    if(platform_comp == params.opt_platforms.hybrid && (platform_comp == params.opt_platforms.ont || platform_comp == params.opt_platforms.pacbio)){
        hyb_lr = true
    }

    // TODO move subsampling into a seperate workflow
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Sampling depth estimation for each set of reads
    // It is requested that only sub-sampled reads go on for further analysis e.g. when calculating coverage only downsampled reads are used
    // TODO determine if metagenomic samples should be down sampled
    read_sketch = MASH_ESTIMATE(filtered_samples, Channel.value(hyb_lr))
    genome_sizes = read_sketch.gsize.map{
        meta, gsize -> tuple(meta, get_size(gsize))
    }

    def ch_prepped_reads = null
    if(params.platform == params.opt_platforms.hybrid && !params.skip_depth_sampling){
        log.warn "Down sampling of reads is not supported for hybrid genome assembly"
    }

    if(!params.skip_depth_sampling && params.platform != params.opt_platforms.hybrid){
        // Shovill downsampling method

        sample_fractions = genome_sizes.join(total_base_counts).map{
            meta, ge_size, base_count -> tuple(meta, sampling_fraction(ge_size, base_count, params.target_depth, meta.id))
        }


        reads_and_fractions = filtered_samples.join(sample_fractions)

        // Branch to take reads for sampling from here
        //reads_sample = sample_fractions.branch{
        def sample_frac_pos = 2

        reads_sample = reads_and_fractions.branch{
            sub_sample: it[sample_frac_pos] < 1.0 // less than 1 (double) the data should be sub sampled otherwise there is not enough data to hit depth requirements anyway
            other: true
        }

        // Log read sampling
        reads_sample.sub_sample.subscribe{
            log.info "Down sampling ${it[0].id} by a factor of ${it[sample_frac_pos]}."
        }
        reads_sample.other.subscribe{
            log.info "Not down sampling ${it[0].id} as estimated sample depth is already below targeted depth of ${params.target_depth}."
        }


        down_sampled_reads = SEQTK_SAMPLE(reads_sample.sub_sample)
        reports = reports.mix(down_sampled_reads.sampled_reads.map{
            meta, reads, down_sampling -> tuple(meta, params.seqtk, down_sampling)
        })

        reads_down_sampled_updated = down_sampled_reads.sampled_reads.map{
            meta, reads, sampling_factor ->
            meta.downsampled = true
            tuple(meta, reads, sampling_factor)
        }

        versions = versions.mix(down_sampled_reads.versions)

        ch_prepped_reads = reads_sample.other.mix(reads_down_sampled_updated).map{
            meta, reads, sampling_factor -> tuple(meta, reads)
        }


    }else{
        ch_prepped_reads = filtered_samples // put in un-downsampled reads
    }

    mash_screen_out = MASH_SCREEN(ch_prepped_reads, file(params.mash.mash_sketch))

    versions = versions.mix(mash_screen_out.versions)

    // Determine if sample is metagenomic
    def ch_cleaned_reads = null
    if(params.platform != params.opt_platforms.hybrid){
        // If metagenomic, no need to trying to classify the samples
        if(params.metagenomic_run){

            ch_cleaned_reads = ch_prepped_reads.map {
                meta, fastq -> tuple(add_meta_tag(meta, "true"), fastq)
            }

        }else{
            parsed_mash = PARSE_MASH(mash_screen_out.mash_data, Channel.value("classify")) // Classify is passed to tell the script to determine if the sample is metagenomic or not

            reports = reports.mix(parsed_mash.mash_out.map{
                meta, result -> tuple(meta, params.mash_meta, result)
            })
            // Update file metadata
            ch_cleaned_reads = ch_prepped_reads.join(parsed_mash.mash_out, remainder: true).map {
                meta, fastq, m_gen -> tuple(add_meta_tag(meta, m_gen), fastq)
                }
            }

    }else{
        // need to nuke single_end bool here as well, to allow for joining of the channels in the assembly runs
        ch_cleaned_reads = ch_prepped_reads.map {
            meta, fastq -> tuple(add_meta_tag(meta, "false"), fastq)
        }
    }

    if(params.platform == params.opt_platforms.ont && !params.skip_ont_header_cleaning){
        // Add unique ID to sample names if nanopore, to solve issue of if guppy stopped than started
        ch_cleaned_reads = CHECK_ONT(ch_cleaned_reads)
    }

    emit:
    trimmed_reads = ch_cleaned_reads // channel: [val(meta), [ reads ]]
    //genome_size = PARSE_KAT.out.genome_size
    genome_size = genome_sizes
    //heterozygozity = PARSE_KAT.out.heterozygozity
    reports = reports
    versions = versions
}

def get_size(file){
    def values = file.splitText()
    return values[0].toLong()
}

def sampling_fraction(ge_size, base_count, sample_depth, sample_name){
    /*
    Sampling code adapted from shovil
    */
    def depth_to_high_p = 1.0
    def default_sampling_amount = depth_to_high_p // set equal to when depth is too high, aka do not sample
    def adjusted_size = (sample_depth * ge_size)
    def sampling_factor = adjusted_size / base_count
    sampling_factor = sampling_factor.round(3)
    log.info "Sample name: ${sample_name}"
    log.info "Genome size: ${ge_size} Base Count: ${base_count}"
    log.info "Sampling fraction: $sampling_factor"
    if(ge_size == 0){
        log.warn "Something went wrong with sample ${sample_name}, the estimated genome size is ${ge_size}. Not downsampling"
    }

    if(sampling_factor >= depth_to_high_p){
        // The sample already has less depth than what is targeted

        sampling_factor = default_sampling_amount // branch from here
    }
    return sampling_factor
}

def add_meta_tag(meta_map, meta_flag){
    /*
    Add a boolean flag for if data is metagenomic or not
    */
    def meta = [:] + meta_map
    //meta.id = meta_map.id
    //meta.single_end = meta_map.single_end
    meta.metagenomic = meta_flag.toBoolean()
    return meta
}


