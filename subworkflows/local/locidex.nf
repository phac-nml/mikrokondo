include { LOCIDEX_EXTRACT } from "../../modules/local/locidex_extract.nf"
include { LOCIDEX_SEARCH } from "../../modules/local/locidex_search.nf"
include { LOCIDEX_REPORT } from "../../modules/local/locidex_report.nf"
include { LOCIDEX_SELECT } from "../../modules/local/locidex_select.nf"
include { LOCIDEX_SUMMARIZE } from "../../modules/local/locidex_summarize.nf"

workflow LOCIDEX {
    take:
    contigs // val(meta), path(contigs)
    top_hit // val(meta), val(top_hit)

    main:
    reports = Channel.empty()
    versions = Channel.empty()

    paired_species = top_hit.join(contigs)
    paired_dbs = Channel.empty()

    if(params.force_allele_scheme == null && params.locidex.allele_database == null && !params.skip_allele_calling){
        error("Allele calling is enabled, but no locidex database directory has been configured.")
    }

    def manifest_file = [] // Default empty values for entries
    def config_file = []

    if(params.force_allele_scheme != null){
        // allele scheme over rides the the manifest file
        def config_file_in = [params.allele_scheme, params.locidex.config_data_file].join(File.separator)
        config_file = file(config_file_in, checkIfExists: true)
    }else{
        def manifest_file_in = [params.locidex.allele_database, params.locidex.manifest_name].join(File.separator)
        manifest_file = file(manifest_file_in, checkIfExists: true)
    }

    matched_dbs = LOCIDEX_SELECT(paired_species, manifest_file, config_file)


    paired = matched_dbs.db_data.branch{
        paired: it[3] // position 3 is a bool showing if a db is matched
        fallthrough: true
    }

    reports = reports.mix(paired.paired.map{
        meta, contigs, scheme, paired -> tuple(meta, params.allele_scheme_selected, scheme)
    })

    // Pull out databases that have a path only
    paired_dbs = paired.paired.map {
        meta, contigs, scheme, paired -> tuple(meta, contigs, file(scheme, checkIfExists: true))
    }



    paired.fallthrough.subscribe {
        log.info "No allele scheme identified for ${it[0].id}."
    }

    reports = reports.mix(matched_dbs.config_data.map{
        meta, output_config -> tuple(meta, params.locidex, output_config)
    })

    extracted_lx = LOCIDEX_EXTRACT(paired_dbs)
    versions = versions.mix(extracted_lx.versions)

    allele_calls = LOCIDEX_SEARCH(extracted_lx.extracted_seqs)
    versions = versions.mix(allele_calls.versions)

    report_lx = LOCIDEX_REPORT(allele_calls.allele_calls)
    versions = versions.mix(report_lx.versions)

    summary_lx = LOCIDEX_SUMMARIZE(report_lx.report.map{ meta, report -> tuple(meta, file(report))})
    reports = reports.mix(summary_lx.map{
        meta, summary -> tuple(meta, params.locidex_summary, summary)
    })

    emit:
    versions
    reports

}
