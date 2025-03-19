// Workflow for the cleaning up reads

include { FASTP_TRIM } from '../../modules/local/fastp_trim.nf'
include { PARSE_FASTP } from '../../modules/local/parse_fastp.nf'
include { CHOPPER_TRIM } from '../../modules/local/chopper_trim.nf'
include { MASH_SCREEN } from '../../modules/local/mash_screen.nf'
include { MASH_ESTIMATE } from '../../modules/local/mash_estimate.nf'
include { REMOVE_CONTAMINANTS } from '../../modules/local/remove_contaminants.nf'
include { PARSE_MASH } from '../../modules/local/parse_mash.nf'
include { CHECK_ONT } from '../../modules/local/check_ont.nf'
include { FASTQC } from '../../modules/nf-core/fastqc/main.nf'
include { SEQTK_SAMPLE } from '../../modules/local/seqtk_sample.nf'
include { RASUSA } from '../../modules/local/rasusa.nf'



process PUBLISH_FINAL_READS {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"


    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*/*"), emit: final_reads
    path "versions.yml", emit: versions

    script:
    """
    mkdir ${meta.sample}
    for i in ${reads.join(" ")}
    do
        mv \$i ${meta.sample}/
    done
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mkdir: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
        mv: \$(echo \$(touch --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
    END_VERSIONS
    """
}


workflow QC_READS {

    // TODO add in nanoplot for nanopore data
    take:
    reads // channel [[meta etc], [[Read paths], opt: long reads]]
    platform // platform opt

    main:
    reports = Channel.empty()
    versions = Channel.empty()
    def platform_comp = platform.toString()

    deconned_reads = REMOVE_CONTAMINANTS(reads, params.r_contaminants.mega_mm2_idx ? file(params.r_contaminants.mega_mm2_idx) : error("--dehosting_idx ${params.dehosting_idx} is invalid"), Channel.value(platform_comp))
    versions = versions.mix(REMOVE_CONTAMINANTS.out.versions)

    ch_meta_cleaned_reads = FASTP_TRIM(deconned_reads.reads) // can use the json output of this to decide if chopper should be run
    reports = reports.mix(ch_meta_cleaned_reads.fastp_json.map{
        meta, json -> tuple(meta, params.fastp, json)
    })
    versions = versions.mix(ch_meta_cleaned_reads.versions)


    fastp_data = PARSE_FASTP(ch_meta_cleaned_reads.fastp_json)


    reads_passed = fastp_data.read_count.branch{
        passed: it[1] >= params.min_reads
        failed: true
    }

    // This can be condensed to one line...
    reports = reports.mix(reads_passed.failed.map{
        meta, count -> tuple(meta, params.filtered_reads, false)
    })
    reports = reports.mix(reads_passed.passed.map{
        meta, count -> tuple(meta, params.filtered_reads, true)
    })


    total_base_counts = fastp_data.base_count.map{
        meta, bases -> tuple(meta, bases)
    }

    filtered_samples = ch_meta_cleaned_reads.reads.join(reads_passed.passed).map{
        meta, reads, count -> tuple(meta, reads) // Only keeping reads that pass a threshold
    }

    // Adding this to to denote long reads for hybrid assembly outputs
    def hyb_lr = false
    if(platform_comp == params.opt_platforms.hybrid && (platform_comp == params.opt_platforms.ont || platform_comp == params.opt_platforms.pacbio)){
        hyb_lr = true
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Sampling depth estimation for each set of reads
    // It is requested that only sub-sampled reads go on for further analysis e.g. when calculating coverage only downsampled reads are used
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

        to_down_sample = reads_sample.sub_sample.branch { it ->
            short_reads: !it[0].single_end
            long_reads: true
        }

        // Short reads and hybrid reads sets get sampled with seqtk still.
        //*~~~~~~~~~~~~~~~~~~~~~~~
        //* Seqtk is still being used for short reads and hybrid read sets until validation is finished.
        //* as rasusa can then be validated for the rest of the workflow afterwards
        //*~~~~~~~~~~~~~~~~~~~~~~~~
        down_sampled_reads_sr_hybr = SEQTK_SAMPLE(to_down_sample.short_reads)
        reports = reports.mix(down_sampled_reads_sr_hybr.sampled_reads.map{
            meta, reads, down_sampling -> tuple(meta, params.seqtk, down_sampling)
        })
        versions = versions.mix(down_sampled_reads_sr_hybr.versions)


        // Long reads get downsampled with RASUSA
        down_sampled_reads_lr = RASUSA(to_down_sample.long_reads)
        reports = reports.mix(down_sampled_reads_lr.sampled_reads.map{
            meta, reads, down_sampling -> tuple(meta, params.rasusa, down_sampling)
        })
        versions = versions.mix(down_sampled_reads_lr.versions)

        // Mix downsampled reads back into same channel
        down_sampled_reads = down_sampled_reads_sr_hybr.sampled_reads.mix(down_sampled_reads_lr.sampled_reads)

        reads_down_sampled_updated = down_sampled_reads.map{
            meta, reads, sampling_factor ->
            meta.downsampled = true
            tuple(meta, reads, sampling_factor)
        }

        ch_prepped_reads = reads_sample.other.mix(reads_down_sampled_updated).map{
            meta, reads, sampling_factor -> tuple(meta, reads)
        }


    }else{
        ch_prepped_reads = filtered_samples // put in un-downsampled reads
    }

    mash_screen_out = MASH_SCREEN(ch_prepped_reads, params.mash.mash_sketch ? file(params.mash.mash_sketch) : error("--mash_sketch ${params.mash_sketch} is invalid"))
    versions = versions.mix(mash_screen_out.versions)

    // Determine if sample is metagenomic
    def ch_cleaned_reads = null
    if(params.platform != params.opt_platforms.hybrid){
        // If metagenomic, no need to trying to classify the samples
        if(params.metagenomic_run){
            if (params.fail_on_metagenomic){
                logger.info "'fail_on_metagenomic' and 'metagenomic_run' are both true, ignoring 'fail_on_metagenomic'"
            }

            ch_cleaned_reads = ch_prepped_reads.map {
                meta, fastq -> tuple(add_meta_tag(meta, "true"), fastq)
            }

        }else if(params.skip_metagenomic_detection){
            if (params.fail_on_metagenomic){
                logger.info "'fail_on_metagenomic' and 'skip_metagenomic_detection' are true. Contamination may be missed."
            }
            ch_cleaned_reads = ch_prepped_reads.map {
                meta, fastq -> tuple(add_meta_tag(meta, "false"), fastq)
            }
        }
        else{
            def taxa_file = file([projectDir, "conf", "equivalent_taxa.json"].join(File.separator))
            parsed_mash = PARSE_MASH(mash_screen_out.mash_data, taxa_file, Channel.value("classify")) // Classify is passed to tell the script to determine if the sample is metagenomic or not

            // Update file metadata
            ch_cleaned_temp = ch_prepped_reads.join(parsed_mash.mash_out, remainder: true).map {
                meta, fastq, m_gen -> tuple(add_meta_tag(meta, m_gen), m_gen, fastq)
            }



            reports = reports.mix(ch_cleaned_temp.map{
                meta, result, reads-> tuple(meta, params.mash_meta, result)
            })

            ch_cleaned_reads = ch_cleaned_temp.map{
                meta, result, reads -> tuple(meta, reads)
            }

            // Check if samples are contaminated/metagenomic and save the user computational time
            if (params.fail_on_metagenomic){
                temp_channel = ch_cleaned_reads.branch{ v, fastq ->
                    metagenomic: v.metagenomic
                    non_metagenomic: true
                }

                // Keep non-metagenomic samples
                ch_cleaned_reads = temp_channel.non_metagenomic

                temp_channel.metagenomic.subscribe{
                    meta, reads ->
                        println "${meta.id} is not being assembled as sample was determined to be metagenomic and 'fail_on_metagenomic' is set to true."
                } // Sorry, you do not become MAGs
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

    published_reads = PUBLISH_FINAL_READS(ch_cleaned_reads)
    versions = versions.mix(published_reads.versions)


    emit:
    trimmed_reads = ch_cleaned_reads // channel: [val(meta), [ reads ]]
    genome_size = genome_sizes
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
    if(params.skip_metagenomic_detection){
        log.info "Forcing ${meta_map.id} to be analysed as an isolate as 'skip_metagenomic_detection' is set to true."
    }


    meta.metagenomic = meta_flag.toBoolean()

    return meta

}

