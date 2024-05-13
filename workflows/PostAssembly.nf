/* A workflow for post assembly workflow steps

2023-07-25: Matthew Wells
*/



// nf-core modules




// Sub workflows for assembly
include { QC_ASSEMBLIES as QC_ASSEMBLY } from '../subworkflows/local/qc_assemblies'
//include { QC_ASSEMBLIES as QC_HYBRID_ASSEMBLY } from '../subworkflows/local/qc_assemblies'
include { DETERMINE_SPECIES } from '../subworkflows/local/determine_species'
include { POLISH_ASSEMBLIES } from '../subworkflows/local/polish_assemblies'
include { HYBRID_ASSEMBLY } from '../subworkflows/local/hybrid_assembly'
include { ANNOTATE_GENOMES } from '../subworkflows/local/annotate_genomes.nf'
include { SUBTYPE_GENOME } from '../subworkflows/local/subtype_genome.nf'
include { SPLIT_METAGENOMIC } from '../subworkflows/local/split_metagenomic.nf'
include { LOCIDEX } from '../subworkflows/local/locidex.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



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

    ch_final_assembly = metagenomic_samples.isolate.mix(divided_samples.divided_contigs.map{
        meta, contigs -> tuple(meta, contigs, []) // empty brackets as no reads to add
    })


    QC_ASSEMBLY(ch_final_assembly)
    quast_data = QC_ASSEMBLY.out.quast_data.map{
        meta, report, contigs -> tuple(meta, report)
    }

    ch_versions = ch_versions.mix(QC_ASSEMBLY.out.versions)
    ch_reports = ch_reports.mix(QC_ASSEMBLY.out.reports)



    // take quast data used for filtering is not needed along side the channel
    ch_filtered_contigs = QC_ASSEMBLY.out.quast_data.map{
        meta, quast_files, contigs -> tuple(meta, contigs)
    }

    ch_speciation = Channel.empty()
    top_hit = channel.empty()
    if(!params.skip_species_classification){
        ch_speciation = DETERMINE_SPECIES(ch_filtered_contigs)
        top_hit = ch_speciation.top_hit
        ch_versions = ch_versions.mix(ch_speciation.versions)
        ch_reports = ch_reports.mix(ch_speciation.reports)

    }else{
        log.info "Skipping running of Kraken2 or mash for speciation"
    }

    //if(!params.skip_subtyping && !params.run_kraken && !params.skip_species_classification){
    if(!params.skip_subtyping && !params.skip_species_classification){
        SUBTYPE_GENOME(ch_filtered_contigs, top_hit)
        ch_reports = ch_reports.mix(SUBTYPE_GENOME.out.reports)
        ch_versions = ch_versions.mix(SUBTYPE_GENOME.out.versions)

    }else if(params.run_kraken && !params.skip_subtyping){
        log.warn "Automatic subtyping of serotypes is not supported with kraken classification."
    }else{
        log.info "No subtyping of assemblies performed"
    }


    if(!params.skip_allele_calling){
        if (!params.skip_species_classification || params.allele_scheme){
            LOCIDEX(ch_filtered_contigs, top_hit)
            ch_versions = LOCIDEX.out.versions
        }else{
            log.info "Skipping locidex since there is no '--allele_scheme' set and '--skip_species_classification' is enabled"
        }
    }

    ANNOTATE_GENOMES(ch_filtered_contigs, top_hit)
    ch_reports = ch_reports.mix(ANNOTATE_GENOMES.out.reports)
    ch_versions = ch_versions.mix(ANNOTATE_GENOMES.out.versions)


    emit:
    quast_table = QC_ASSEMBLY.out.quast_data
    reports = ch_reports
    versions = ch_versions
}
