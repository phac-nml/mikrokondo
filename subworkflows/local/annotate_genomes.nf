// annotate genomes
include { BAKTA_ANNOTATE } from '../../modules/local/bakta_annotate.nf'
include { ABRICATE_RUN } from "../../modules/nf-core/abricate/run/main.nf"
include { MOBSUITE_RECON } from "../../modules/local/mob_recon.nf"
include { STARAMR } from "../../modules/local/staramr.nf"

workflow ANNOTATE_GENOMES {
    take:
    contig_data // val(meta), path(assembly)
    // TODO add in species so that point finder can run

    main:
    versions = channel.empty()
    reports = channel.empty()
    // TODO add outputs to report channels
    embl = channel.empty()
    faa = channel.empty()
    ffn = channel.empty()
    fna = channel.empty()
    gbff = channel.empty()
    gff = channel.empty()
    hypotheticals_tsv = channel.empty()
    hypotheticals_faa = channel.empty()
    tsv = channel.empty()
    txt = channel.empty()
    abricate_report = channel.empty()

    if(!params.skip_bakta){
        db_file = Channel.value("${params.bakta.db}")
        annotated = BAKTA_ANNOTATE(contig_data, db_file,
            [], [], [], [], [], []) // empty channels for optional arguments
        embl = BAKTA_ANNOTATE.out.embl
        faa = BAKTA_ANNOTATE.out.faa
        ffn = BAKTA_ANNOTATE.out.ffn
        fna = BAKTA_ANNOTATE.out.fna
        gbff = BAKTA_ANNOTATE.out.gbff
        gff = BAKTA_ANNOTATE.out.gff
        hypotheticals_tsv = BAKTA_ANNOTATE.out.hypotheticals_tsv
        hypotheticals_faa = BAKTA_ANNOTATE.out.hypotheticals_faa
        tsv = BAKTA_ANNOTATE.out.tsv
        txt = BAKTA_ANNOTATE.out.txt
        versions = versions.mix(annotated.versions)
    }

    if(!params.skip_abricate){
        abricated = ABRICATE_RUN(contig_data)
        abricate_report = abricated.report
        versions = versions.mix(abricated.versions)
        reports = reports.mix(abricated.report.map{
            meta, report -> tuple(meta, params.abricate_params, report);
        })
    }

    if(!params.skip_mobrecon){
        mobrecon = MOBSUITE_RECON(contig_data)
        versions = versions.mix(mobrecon.versions)
        reports = reports.mix(mobrecon.mobtyper_results.map{
            meta, report -> tuple(meta, params.mobsuite_recon, report)
        })
    }

    if(!params.skip_staramr){
        // TODO make db optional to pass in
        if(params.staramr.db){
            db_star = Channel.value("${params.staramr.db}")
            staramr_ = STARAMR(contig_data, db_star)
        }else{
            staramr_ = STARAMR(contig_data, []) // pass nothing for database as it will use what is in the container
        }

        versions = versions.mix(staramr_.versions)
    }



    emit:
    abricate_report = abricate_report
    embl = embl
    faa = faa
    ffn = ffn
    fna = fna
    gbff = gbff
    gff = gff
    hypotheticals_tsv = hypotheticals_tsv
    hypotheticals_faa = hypotheticals_faa
    tsv = tsv
    txt = txt
    reports
    versions
}
