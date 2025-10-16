#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mikrokondo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/mk-kondo/mikrokondo
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

// Enable for testing purposes only
// nextflow.enable.strict = true

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



process MAX_SAMPLES_CHECK {
    tag "max_samples_error"
    publishDir "${params.outdir}/error"

    input:
    val sample_count // number of samples provided to mikrokondo

    output:
    path output_file_path, emit: failure_report

    exec:
    def output_file =  "max_samples_exceeded.error.txt"
    output_file_path = task.workDir.resolve(output_file)
    file_out = file(output_file_path)
    file_out.text = """
    ${sample_count} samples were selected, which exceeds the maximum number of samples: ${params.max_samples}
    Please reduce samples to ${params.max_samples}.

    Pipeline maximum sample count threshold should only occur when running in IRIDA Next,
    please submit an issue if you encounter it elsewhere.

    This limit has been added for execution in IRIDA Next to prevent accidental generation of large compute bills.

    If running from command-line make sure that --max_samples 0
    """.stripIndent().trim()



}



println '\033[0;32m ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\033[0m'
println '\033[0;32m 888b     d888 d8b 888                      888    d8P                         888\033[0m'
println '\033[0;32m 8888b   d8888 Y8P 888                      888   d8P                          888\033[0m'
println '\033[0;32m 88888b.d88888     888                      888  d8P                           888\033[0m'
println '\033[0;32m 888Y88888P888 888 888  888 888d888 .d88b.  888d88K      .d88b.  88888b.   .d88888  .d88b.\033[0m'
println '\033[0;32m 888 Y888P 888 888 888 .88P 888P"  d88""88b 8888888b    d88""88b 888 "88b d88" 888 d88""88b\033[0m'
println '\033[0;32m 888  Y8P  888 888 888888K  888    888  888 888  Y88b   888  888 888  888 888  888 888  888\033[0m'
println '\033[0;32m 888   "   888 888 888 "88b 888    Y88..88P 888   Y88b  Y88..88P 888  888 Y88b 888 Y88..88P\033[0m'
println '\033[0;32m 888       888 888 888  888 888     "Y88P"  888    Y88b  "Y88P"  888  888  "Y88888  "Y88P"\033[0m'
println '\033[0;32m ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\033[0m'


include { validateParameters; paramsHelp; paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

if (params.help) {
    log.info paramsHelp ("nextflow run main.nf --input input_file.csv --outdir ./output_place --platform {platform}")
    exit 1
}

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

import groovy.json.JsonBuilder

// Function to save parameters as JSON
def saveParamsAsJson(outputDir) {
    def paramMap = [:]
    params.each { key, value ->
        paramMap[key] = value
    }

    def json = new JsonBuilder(paramMap)
    def jsonFile = file("${outputDir}/pipeline_parameters.json")
    jsonFile.text = json.toPrettyString()

    return paramMap
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CLEAN_ASSEMBLE_READS } from './workflows/CleanAssemble.nf'
include { POST_ASSEMBLY } from './workflows/PostAssembly.nf'
include { INPUT_CHECK } from './subworkflows/local/input_check.nf'
include { REPORT } from './modules/local/report.nf'
include { REPORT_AGGREGATE } from './modules/local/report_aggregate.nf'
include { GZIP_FILES } from './modules/local/gzip_files.nf'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'
include { REPORT_PIPELINE_PARAMETERS } from './modules/local/report_pipeline_parameter'



import org.slf4j.LoggerFactory;

//
// WORKFLOW: Run main mk-kondo/mikrokondo analysis pipeline
//


workflow MIKROKONDO {

    if(params.validate_params){
        //====Temporarily turn of logging for ScriptBinding process that throws warns
        // Probably better to disable the console appender briefly https://github.com/nextflow-io/nextflow/blob/6a0626f72455dfdef4135a119f48c3950bc6d9c6/modules/nextflow/src/main/groovy/nextflow/util/LoggerHelper.groovy#L110
        def logger2 = LoggerFactory.getLogger(nextflow.script.ScriptBinding)
        // This is working but if things get messy a better solution would be to look for a way to detach the console appender
        logger2.setLevel(ch.qos.logback.classic.Level.ERROR)
        validateParameters(monochrome_logs: params.monochrome_logs, monochromeLogs: params.monochrome_logs)
        logger2.setLevel(ch.qos.logback.classic.Level.DEBUG)
    }

    /*
        Dont bother checking the number of lines in the samples if max_samples == 0
        as we will not do anything with the limit.
    */

    def number_of_samples = file(params.input).readLines().size() - 1 // Remove 1 for header
    def unlimited_samples = (params.max_samples == 0) ? true : false

    if( unlimited_samples || number_of_samples <= params.max_samples){
        log.info paramsSummaryLog(workflow)

        ch_reports = Channel.empty()
        prepped_data = INPUT_CHECK()


        split_data = prepped_data.reads.branch{
            post_assembly: it[0].assembly // [0] dentoes the meta tag
            read_data: true
        }

        mk_out = CLEAN_ASSEMBLE_READS(split_data.read_data)

        assembly_data =  mk_out.final_assembly.mix(split_data.post_assembly.map{
            meta, contigs -> tuple(meta, contigs, []) // appending empty brackets to match cardinality of the first processes output
        })

        ps_out = POST_ASSEMBLY(assembly_data, mk_out.cleaned_reads, mk_out.versions)


        // Assemblies will be discared
        base_count_data = ps_out.quast_table.map{
            meta, reports, contigs -> tuple(meta, reports)
        }.join(mk_out.base_counts)

        ch_versions = ps_out.versions

        ch_reports = ch_reports.mix(mk_out.reports)
        ch_reports = ch_reports.mix(ps_out.reports)
        ch_reports_all = ch_reports.collect()

        if(!params.skip_report){
            REPORT(ch_reports_all)
            REPORT_AGGREGATE(REPORT.out.final_report)
            ch_versions = ch_versions.mix(REPORT_AGGREGATE.out.versions)

            updated_samples = REPORT_AGGREGATE.out.flat_samples.flatten().map{
                        sample ->
                            def name_trim = sample.getName()
                            def trimmed_name = name_trim.substring(0, name_trim.length() - params.report_aggregate.sample_flat_suffix.length())
                            def external_id_name = sample.getParent().getBaseName()
                            def output_map = [
                                "id": trimmed_name,
                                "sample": trimmed_name,
                                "external_id": external_id_name]

                            tuple(output_map, sample)
                        }

            GZIP_FILES(updated_samples)
            ch_versions = ch_versions.mix(GZIP_FILES.out.versions)
        }


        if(!params.skip_version_gathering){
            // Save all parameters to the software report JSON file
            def allParams = saveParamsAsJson("${params.outdir}")
            paramsSummaryChannel = Channel.fromPath(
                file("${params.outdir}/pipeline_parameters.json")
            )
            // Save all the software versions to a YAML file
            software_versions_channel = CUSTOM_DUMPSOFTWAREVERSIONS (
            ch_versions.unique().collectFile(name: 'collated_versions.yml')
            ).yml


            software_report_channel = prepped_data.reads.map{it -> it[0]
            }.combine(paramsSummaryChannel).combine(software_versions_channel)

            REPORT_PIPELINE_PARAMETERS(
            software_report_channel)
        }
    }else{
        MAX_SAMPLES_CHECK(channel.value(number_of_samples))
        log.info "Parameter --max_samples was set: See outdir/error/max_samples_exceeded.error.txt for more information."
    }

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    MIKROKONDO ()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
