/*Read processing step of the pipeline


*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowMikrokondo.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo = params.multiqc_logo ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
//include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { QC_READS } from '../subworkflows/local/clean_reads'
include { QC_READS as QC_LONG_READS} from '../subworkflows/local/clean_reads'
include { ASSEMBLE_READS } from '../subworkflows/local/assemble_reads'
include { QC_ASSEMBLIES as QC_ASSEMBLY } from '../subworkflows/local/qc_assemblies'
include { QC_ASSEMBLIES as QC_HYBRID_ASSEMBLY } from '../subworkflows/local/qc_assemblies'
include { DETERMINE_SPECIES } from '../subworkflows/local/determine_species'
include { POLISH_ASSEMBLIES } from '../subworkflows/local/polish_assemblies'
include { HYBRID_ASSEMBLY } from '../subworkflows/local/hybrid_assembly'
include { ANNOTATE_GENOMES } from '../subworkflows/local/annotate_genomes.nf'
include { SUBTYPE_GENOME } from '../subworkflows/local/subtype_genome.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC                      } from '../modules/nf-core/fastqc/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'

include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

// Workflow object imported to silence warnings
// TODO keep exploring better options
include { BAKTA_DB_DOWNLOAD } from '../modules/local/bakta_download_db.nf'
include { MASH_SKETCH } from '../modules/local/mash_sketch.nf'
include { MASH_PASTE } from '../modules/local/mash_paste.nf'
include { PILON_POLISH } from '../modules/local/pilon_polish.nf'
include { READ_SCAN } from '../modules/local/read_summary.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



workflow CLEAN_ASSEMBLE_READS {
    take:
    prepped_input // meta, [reads]

    main:
    //TODO should preface workflows for when workflows are for metagenomics or isolates
    ch_versions = Channel.empty()
    ch_reports = Channel.empty()

    // Get quality metrics on Raw Reads (requirement)
    if(!params.skip_raw_read_metrics){

        raw_quality_info = READ_SCAN(prepped_input.map{
            val -> val[0].hybrid ? tuple(val[0], val[1], val[2]) : tuple(val[0], val[1], [])
        })

        ch_versions = ch_versions.mix(raw_quality_info.versions)
        ch_reports = ch_reports.mix(raw_quality_info.json.map{
            meta, json -> tuple(meta, params.raw_reads, json)
        })
    }

    // TODO change this up to use branches from the meta tag
    if(params.platform == params.opt_platforms.hybrid){


        divided_reads = prepped_input.multiMap{
            meta, s_reads, l_reads ->
            short_reads: tuple(meta, s_reads)
            long_reads: tuple(meta, l_reads)
        }

        log.info "Automatic determination of whether sample is metagenomic is not currently supported for samples used in hybrid assemblies"
        short_reads_trimmed = QC_READS(divided_reads.short_reads, params.opt_platforms.illumina)
        ch_versions = ch_versions.mix(QC_READS.out.versions)
        ch_reports = ch_reports.mix(QC_READS.out.reports)

        long_reads_trimmed = QC_LONG_READS(divided_reads.long_reads, params.long_read_opt)
        ch_reports = ch_reports.mix(QC_LONG_READS.out.reports)
        ch_versions = ch_versions.mix(QC_LONG_READS.out.versions)

        // Join cleaned reads back together
        ch_trimmed_reads = short_reads_trimmed.trimmed_reads.join(long_reads_trimmed.trimmed_reads)


        // Join long reads back in with the
        ch_assembled_reads = HYBRID_ASSEMBLY(ch_trimmed_reads)
        ch_output_data_asm = ch_assembled_reads.fasta
        ch_versions = ch_versions.mix(HYBRID_ASSEMBLY.out.versions)

        // TODO should long reads be sub-sampled in hybrid assembly?

        ch_final_assembly = ch_output_data_asm.map{
            meta, contigs, sr, lr -> tuple(meta, contigs, [sr[0], sr[1], lr])
        }


    }else{

        //QC_READS(INPUT_CHECK.out.reads, params.platform)
        QC_READS(prepped_input, params.platform)
        ch_versions = ch_versions.mix(QC_READS.out.versions)
        ch_reports = ch_reports.mix(QC_READS.out.reports)

        ch_trimmed_reads = QC_READS.out.trimmed_reads

        // Create empty channel for assemblies to further process
        ch_final_assembly = Channel.empty()

        // Isolate workflow
        ch_assembled_reads = ASSEMBLE_READS(ch_trimmed_reads)
        ch_versions = ch_versions.mix(ch_assembled_reads.versions)

        if(!params.skip_polishing){
            POLISH_ASSEMBLIES(ch_trimmed_reads, ch_assembled_reads.final_contigs)
            ch_final_assembly = POLISH_ASSEMBLIES.out.assemblies
            ch_versions = ch_versions.mix(POLISH_ASSEMBLIES.out.versions)
        }else{
            log.info "Skipping Polishing"
            ch_final_assembly = ch_assembled_reads.final_contigs
            ch_final_assembly = ch_final_assembly.join(ch_trimmed_reads)
        }

    }

    emit:
        final_assembly = ch_final_assembly
        cleaned_reads = ch_trimmed_reads
        versions = ch_versions
        reports = ch_reports
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//workflow.onComplete {
//    if (params.email || params.email_on_fail) {
//        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
//    }
//    NfcoreTemplate.summary(workflow, params, log)
//    if (params.hook_url) {
//        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
//    }
//}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
