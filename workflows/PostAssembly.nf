/* A workflow for post assembly workflow steps

2023-07-25: Matthew Wells
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)


// nf-core modules
include { MULTIQC } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'



// Sub workflows for assembly
include { QC_ASSEMBLIES as QC_ASSEMBLY } from '../subworkflows/local/qc_assemblies'
//include { QC_ASSEMBLIES as QC_HYBRID_ASSEMBLY } from '../subworkflows/local/qc_assemblies'
include { DETERMINE_SPECIES } from '../subworkflows/local/determine_species'
include { POLISH_ASSEMBLIES } from '../subworkflows/local/polish_assemblies'
include { HYBRID_ASSEMBLY } from '../subworkflows/local/hybrid_assembly'
include { ANNOTATE_GENOMES } from '../subworkflows/local/annotate_genomes.nf'
include { SUBTYPE_GENOME } from '../subworkflows/local/subtype_genome.nf'
include { SPLIT_METAGENOMIC } from '../subworkflows/local/split_metagenomic.nf'

ch_multiqc_config = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo = params.multiqc_logo ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

// TODO add in read binning for metagenomic workflow afterwards


workflow POST_ASSEMBLY {
    take:
        final_assembly // meta, contigs
        ch_cleaned_reads // meta, reads
        ch_versions

    main:

    ch_reports = Channel.empty()
    metagenomic_samples = final_assembly.branch{
        metagenomic: it[0].metagenomic // seperate out metagenomic samples
        isolate: true
    }

    divided_samples = SPLIT_METAGENOMIC(metagenomic_samples.metagenomic)
    // TODO when output is formalized mix this info back in
    // TODO test with mash turned on

    ch_final_assembly = metagenomic_samples.isolate.mix(divided_samples.divided_contigs.map{
        meta, contigs -> tuple(meta, contigs, []) // empty brackets as no reads to add
    })

    QC_ASSEMBLY(ch_final_assembly)
    ch_versions = ch_versions.mix(QC_ASSEMBLY.out.versions)
    ch_reports = ch_reports.mix(QC_ASSEMBLY.out.reports)

    // take quast data used for filtering is not needed along side the channel
    ch_filtered_contigs = QC_ASSEMBLY.out.filtered_assemblies.map{
        meta, quast_files, contigs -> tuple(meta, contigs)
    }

    ch_speciation = Channel.empty()
    if(!params.skip_species_classification){
        ch_speciation = DETERMINE_SPECIES(ch_filtered_contigs)
        ch_versions = ch_versions.mix(ch_speciation.versions)
        ch_reports = ch_reports.mix(ch_speciation.reports)

    }else{
        log.info "Skipping running of Kraken2 or mash for speciation"
    }

    //if(!params.skip_subtyping && !params.run_kraken && !params.skip_species_classification){
    if(!params.skip_subtyping && !params.skip_species_classification){
        //SUBTYPE_GENOME(ch_filtered_contigs, ch_speciation.results)
        SUBTYPE_GENOME(ch_filtered_contigs, ch_speciation.top_hit)
        ch_reports = ch_reports.mix(SUBTYPE_GENOME.out.reports)
        ch_versions = ch_versions.mix(SUBTYPE_GENOME.out.versions)

    }else if(params.run_kraken && !params.skip_subtyping){
        log.warn "Automatic subtyping of serotypes is not supported with kraken classification."
    }else{
        log.info "No subtyping of assemblies performed"
    }


    ANNOTATE_GENOMES(ch_filtered_contigs)
    ch_reports = ch_reports.mix(ANNOTATE_GENOMES.out.reports)
    ch_versions = ch_versions.mix(ANNOTATE_GENOMES.out.versions)

    if(!params.skip_version_gathering){
        CUSTOM_DUMPSOFTWAREVERSIONS (
            ch_versions.unique().collectFile(name: 'collated_versions.yml')
        )
    }



    //ch_reports.subscribe { println "reports: $it" }
    //ch_reports.groupTuple().subscribe{
    //    println "reports: $it"
    //}

    //
    // MODULE: MultiQC
    //
    //workflow_summary    = WorkflowMikrokondo.paramsSummaryMultiqc(workflow, summary_params)
    //ch_workflow_summary = Channel.value(workflow_summary)

    //methods_description    = WorkflowMikrokondo.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    //ch_methods_description = Channel.value(methods_description)

    //ch_multiqc_files = Channel.empty()
    //ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    //ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    //ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    //ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    //MULTIQC (
    //    ch_multiqc_files.collect(),
    //    ch_multiqc_config.toList(),
    //    ch_multiqc_custom_config.toList(),
    //    ch_multiqc_logo.toList()
    //)
    //multiqc_report = MULTIQC.out.report.toList()

    emit:
    reports = ch_reports

}


workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}
