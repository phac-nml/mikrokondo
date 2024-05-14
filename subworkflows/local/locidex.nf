include { LOCIDEX_EXTRACT } from "../../modules/local/locidex_extract.nf"
include { LOCIDEX_SEARCH } from "../../modules/local/locidex_search.nf"
include { LOCIDEX_REPORT } from "../../modules/local/locidex_report.nf"



workflow LOCIDEX {
    take:
    contigs // val(meta), path(contigs)
    top_hit // val(meta), top_hit

    main:
    reports = Channel.empty()
    versions = Channel.empty()

    paired_species = top_hit.join(contigs)

    paired_dbs =  paired_species.map{
        meta, top_hit, contigs -> tuple(meta, contigs, id_scheme(top_hit))
    }.branch{
        paired: it[2]
        fallthrough: true
    }

    // TODO add to reports the database for allele calls to report
    paired_dbs.fallthrough.subscribe {
        log.info "No allele scheme identified for ${it[0].id}."
    }

    extracted_lx = LOCIDEX_EXTRACT(paired_dbs.paired)
    versions = versions.mix(extracted_lx.versions)

    allele_calls = LOCIDEX_SEARCH(extracted_lx.extracted_seqs)
    versions = versions.mix(allele_calls.versions)

    report_lx = LOCIDEX_REPORT(allele_calls.allele_calls)
    versions = versions.mix(report_lx.versions)

    emit:
    versions


}

def id_scheme(top_hit){
    /* Pick the correct allele scheme based off of the species top-hit
    */

    def selected_scheme = params.allele_scheme
    if(selected_scheme){
        return selected_scheme
    }

    for( scheme in params.locidex.schemes){
        search_param = scheme.value.search.search
        if(top_hit.contains(search_param)){
            selected_scheme = scheme.value.db ? file(scheme.value.db) : null // Need a value present that will send the scheme to the fallthrough case
            break
        }
    }

    return selected_scheme
}
