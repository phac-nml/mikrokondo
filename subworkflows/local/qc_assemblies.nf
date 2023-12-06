// Run annotate and apply QC metrics
include { QUAST } from "../../modules/local/quast_assembly.nf"
include { CHECKM_LINEAGEWF } from "../../modules/local/checkm_lineagewf.nf"
include { MLST } from "../../modules/local/mlst.nf"

workflow QC_ASSEMBLIES {
    take:
    assembled_reads // tuple val(meta), path(contigs), path(reads)


    main:

    versions = Channel.empty()
    reports = Channel.empty()

    quast_data = QUAST(assembled_reads)
    versions = versions.mix(quast_data.versions)

    reports = reports.mix(quast_data.quast_table.map{
        meta, report, contigs -> tuple(meta, params.quast, report)
    })




    if(!params.skip_checkm){
        CHECKM_LINEAGEWF(assembled_reads.map{
            meta, contigs, reads -> tuple(meta, contigs)
        })
        reports = reports.mix(CHECKM_LINEAGEWF.out.checkm_results.map{
            meta, results -> tuple(meta, params.checkm, results)
        })
        versions = versions.mix(CHECKM_LINEAGEWF.out.versions)
    }

    if(!params.skip_mlst){
        MLST(assembled_reads.map{
            meta, contigs, reads -> tuple(meta, contigs)
        })
        reports = reports.mix(MLST.out.json.map{
            meta, json -> tuple(meta, params.mlst, json)
        })
        versions = versions.mix(MLST.out.versions)
    }



    // Filter out assemvlies that do not meet quast criteria
    //// TODO update meta tag to hold fail or pass value, hard stop should be nothing there
    //// TODO add in do not bother processing further for e.g. when something only has 10,000 bases
    //ch_assembly_filtered = quast_data.quast_table.filter {
    //    meta, report, contigs -> filter_quast_assembly(meta, report)
    //}


    emit:
    filtered_assemblies = quast_data.quast_table
    reports = reports
    versions = versions
}


// need to create groovy func for getting csv data
def filter_quast_assembly(meta, csv_path){
    def quast_header = params.quast_filter.sample_header
    def rows = csv_path.splitCsv(header: true, sep: '\t')
    if(rows[0][params.quast_filter.n50_field].toLong() >= params.quast_filter.n50_value
    && rows[0][params.quast_filter.nr_contigs_field].toLong() >= params.quast_filter.nr_contigs_value){
        return true
    }
    log.info "${meta.id} did not meet assembly quality thresholds and will be excluded from further analyses."
    return false
}
