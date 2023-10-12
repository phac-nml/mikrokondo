/*
If enabled, parse the mash output and launch ECTyper or sistr acordingly

Currently, the output form of the mash sketch using the taxonomy info from GTDB will be used,
This creates an output similar to the kraken report

2023-06-05: Matthew Wells
*/

// TODO add spatyper and staramr
// TODO shigeifinder does not type shigella, that is shigatyper which will be added
//include { PARSE_MASH } from "../../modules/local/parse_mash.nf"
include { ECTYPER } from "../../modules/local/ectyper.nf"
include { SISTR } from "../../modules/local/sistr.nf"
include { LISSERO } from "../../modules/local/lissero.nf"
//include { SHIGEIFINDER } from "../../modules/local/shigeifinder.nf"
include { SHIGATYPER } from "../../modules/local/shigatyper.nf"
include { SEQTK_FASTA_FASTQ } from "../../modules/local/seqtk_fasta_fastq.nf"
include { KLEBORATE } from "../../modules/local/kleborate.nf"
include { SPATYPER } from "../../modules/local/spatyper.nf"



// TODO add in torsts mlst
workflow SUBTYPE_GENOME{

    take:
    contigs // val(meta), path(contigs),
    //taxon_data // val(meta) path(taxon info [mash]) adding kraken support in the future
    top_hit // val(meta) path(taxon info [mash]) adding kraken support in the future

    main:
    reports = Channel.empty()
    versions = Channel.empty()

    //top_hit = PARSE_MASH(taxon_data, Channel.value("top"))
    //reports = reports.mix(add_report_tag(top_hit.mash_out, params.mash_species))
    //versions = versions.mix(top_hit.versions)

    ch_contigs_mash = top_hit.join(contigs)

    isolates = ch_contigs_mash.branch{
        ecoli: it[1].contains(params.QCReport.escherichia.search)
        salmonella: it[1].contains(params.QCReport.salmonella.search)
        listeria: it[1].contains(params.QCReport.listeria.search)
        shigella: it[1].contains(params.QCReport.shigella.search)
        klebsiella: it[1].contains(params.QCReport.klebsiella.search)
        staphylococcus: it[1].contains(params.QCReport.staphylococcus.search)
        fallthrough: true
    }

    ec_typer_results = ECTYPER(isolates.ecoli.map{
        meta, result, contigs -> tuple(meta, contigs)
    })


    sistr_results = SISTR(isolates.salmonella.map{
        meta, result, contigs -> tuple(meta, contigs)
    })

    lissero_results = LISSERO(isolates.listeria.map{
        meta, result, contigs -> tuple(meta, contigs)
    })

    //shigatyper requries reads only
    fastq_reads = SEQTK_FASTA_FASTQ(isolates.shigella.map{
        meta, result, contigs -> tuple(meta, contigs)
    })
    shigatyper_results = SHIGATYPER(fastq_reads.fastq_reads)

    kleborate_results = KLEBORATE(isolates.klebsiella.map{
        meta, result, contigs -> tuple(meta, contigs)
    })

    // SpaTyper specific args are the repeast and repaat order
    ch_repeats = params.spatyper.repeats ? file(params.spatyper.repeats) : []
    ch_repeat_order = params.spatyper.repeat_order ? file(params.spatyper.repeat_order) : []

    spatyper_results = SPATYPER(isolates.staphylococcus.map{
        meta, results, contigs -> tuple(meta, contigs)
    }, repeats=ch_repeats, repeat_order=ch_repeat_order)

    versions = versions.mix(
                SPATYPER.out.versions,
                KLEBORATE.out.versions,
                ECTYPER.out.versions,
                SISTR.out.versions,
                LISSERO.out.versions,
                //SHIGEIFINDER.out.versions)
                SHIGATYPER.out.versions)

    isolates.fallthrough.subscribe{
        log.info "Sample ${it[0].id} could not be serotyped, sample identified as: ${it[1]}"
    }

    reports = reports.mix(
        add_report_tag(spatyper_results.tsv, params.spatyper),
        add_report_tag(kleborate_results.txt, params.kleborate),
        add_report_tag(ec_typer_results.tsv, params.ectyper),
        add_report_tag(sistr_results.tsv, params.sistr),
        add_report_tag(lissero_results.tsv, params.lissero),
        //add_report_tag(shigeifinder_results.tsv, params.shigeifinder))
        add_report_tag(shigatyper_results.tsv, params.shigeifinder))

    emit:
    reports = reports
    versions = versions

}

def add_report_tag(channel_data, report_params){
    return channel_data.map{
        meta, report -> tuple(meta, report_params, report)
    }
}

