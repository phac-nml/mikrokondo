#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mk-kondo/mikrokondo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/mk-kondo/mikrokondo
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

// TODO remove before PR to main
nextflow.enable.strict = true

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//params.fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

WorkflowMain.initialise(workflow, params, log)

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


// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CLEAN_ASSEMBLE_READS } from './workflows/CleanAssemble.nf'
include { POST_ASSEMBLY } from './workflows/PostAssembly.nf'
include { INPUT_CHECK } from './subworkflows/local/input_check.nf'
include { REPORT } from './modules/local/report.nf'
include { REPORT_TO_TSV } from './modules/local/report_to_tsv.nf'

workflow input_test {
    prepped_data = INPUT_CHECK(params.input)
}

//
// WORKFLOW: Run main mk-kondo/mikrokondo analysis pipeline
//
workflow MIKROKONDO {
    ch_reports = Channel.empty()
    prepped_data = INPUT_CHECK(ch_input)

    split_data = prepped_data.reads.branch{
        post_assembly: it[0].assembly // [0] dentoes the meta tag
        read_data: true
    }

    mk_out = CLEAN_ASSEMBLE_READS(split_data.read_data)

    assembly_data =  mk_out.final_assembly.mix(split_data.post_assembly.map{
        meta, contigs -> tuple(meta, contigs, []) // appending empty brackets to match cardinality of the first processes output
    })

    ps_out = POST_ASSEMBLY(assembly_data, mk_out.cleaned_reads, mk_out.versions)
    ch_reports = ch_reports.mix(mk_out.reports)
    ch_reports = ch_reports.mix(ps_out.reports)
    //ch_reports = ch_reports.groupTuple()
    ch_reports_all = ch_reports.collect()
    //ch_reports_all.view()
    if(!params.skip_report){
        REPORT(ch_reports_all)
        REPORT_TO_TSV(REPORT.out.final_report)
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
    //input_test()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
