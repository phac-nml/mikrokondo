/*
A workflow to determine the sample composition after assembly
*/
include { KRAKEN } from '../../modules/local/kraken.nf'
include { PARSE_KRAKEN } from '../../modules/local/parse_kraken.nf'
include { MASH_SCREEN } from '../../modules/local/mash_screen.nf'
include { PARSE_MASH } from "../../modules/local/parse_mash.nf"


workflow DETERMINE_SPECIES {

    take:
    contigs // Channel[[meta], contigs]
    // TODO add in logic to parser to add in "no species determined" if the top hit script fails
    // TODO can try using ifEmpty operator or exit codes in the modules themselves

    main:
    def id_method = null
    reports = Channel.empty()
    results = Channel.empty()
    versions = Channel.empty()
    taxon_identifications = Channel.empty()

    def TAXON_PREFIX_STRIP = ~/^\w__/

    if (params.run_kraken){
        log.info "Running kraken2 for contigs classification"
        KRAKEN(contigs, params.kraken.db ? file(params.kraken.db) : error("--kraken2_db ${params.kraken.db} is invalid"))
        id_method = "Kraken2"
        // join contigs for classification
        split_contigs = KRAKEN.out.classified_contigs.join(KRAKEN.out.report).join(KRAKEN.out.kraken_output)
        results = results.mix(KRAKEN.out.report)
        reports = reports.mix(KRAKEN.out.report.map{
            meta, report -> tuple(meta, params.kraken, report)
        })

        parsed = PARSE_KRAKEN(KRAKEN.out.report)
        taxon_identifications = parsed.kraken_top
        versions = versions.mix(parsed.versions)
        versions = versions.mix(KRAKEN.out.versions)

    }else {
        log.info "Using mash screen for sample classification"
        id_method = "Mash"
        MASH_SCREEN(contigs, params.mash.mash_sketch ? file(params.mash.mash_sketch) : error("--mash_sketch ${params.mash_sketch} is invalid"))
        results = results.mix(MASH_SCREEN.out.mash_data)

        MASH_SCREEN.out.mash_data
        parsed = PARSE_MASH(MASH_SCREEN.out.mash_data, [], Channel.value("top"))
        parsed.mash_out.view()
        taxon_identifications = parsed.mash_out
        versions = versions.mix(MASH_SCREEN.out.versions)
        versions = versions.mix(parsed.versions)
    }

    top_hit = taxon_identifications.map{meta, output -> tuple(meta, output - TAXON_PREFIX_STRIP)}
    reports = reports.mix( top_hit.map{
        meta, report -> tuple(meta, params.top_hit_species, report)
        }
    )


    // Create a channel identifying pipelines output ID
    id_channel = top_hit.map{
        meta, output -> tuple(meta, params.top_hit_method, id_method)
    }
    reports = reports.mix(id_channel)



    emit:
    top_hit = top_hit
    results = results
    reports = reports
    versions = versions

}
