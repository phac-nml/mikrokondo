/*
    Gather some allele summary metrics from locidex.


    Empty loci are labeled as '-'
    We need to add the following fields:
    - count_loci_found (e.g. not '-')
    - count_loci_missing (e.g. '-')
    - total_loci (e.g. number of keys)
*/


import groovy.json.JsonSlurper
import groovy.json.JsonBuilder
import java.util.zip.GZIPInputStream
import java.io.BufferedReader
import java.io.FileInputStream
import java.io.File

process LOCIDEX_SUMMARIZE {
    tag "$meta.id"
    label "process_single"

    input:
    tuple val(meta), val(report)

    output:
    tuple val(meta), path("${meta.id}.json"), emit: summary


    exec:
    def json_in = new JsonSlurper()
    def report_data = report.withInputStream {
        it = new GZIPInputStream(it)
        return json_in.parse(it)
    }


    check_key(report_data, params.locidex_summary.data_key, meta)
    def data = report_data[params.locidex_summary.data_key]

    check_key(data, params.locidex_summary.data_sample_key, meta)
    check_key(data, params.locidex_summary.data_profile_key, meta)

    check_key(data, params.locidex_summary.data_metrics_key, meta)
    def profile_metrics = data[params.locidex_summary.data_metrics_key]

    check_key(profile_metrics, params.locidex_summary.metrics_loci_key, meta)
    def loci_data = profile_metrics[params.locidex_summary.metrics_loci_key]

    check_key(loci_data, params.locidex_summary.metrics_loci_missing_key, meta)
    def no_blast_hit = loci_data[params.locidex_summary.metrics_loci_missing_key]

    check_key(loci_data, params.locidex_summary.metrics_loci_single_hit_key, meta)
    def single_blast_hit = loci_data[params.locidex_summary.metrics_loci_single_hit_key]

    check_key(loci_data, params.locidex_summary.metrics_loci_multiple_blast_hits_key, meta)
    def loci_multiple_hits = loci_data[params.locidex_summary.metrics_loci_multiple_blast_hits_key]

    check_key(loci_data, params.locidex_summary.metrics_loci_no_nuc_blast_hits_key, meta)
    def loci_no_nuc_hits = loci_data[params.locidex_summary.metrics_loci_no_nuc_blast_hits_key]


    check_key(loci_data, params.locidex_summary.metrics_loci_no_prot_blast_hits_key, meta)
    def loci_no_prot_hits = loci_data[params.locidex_summary.metrics_loci_no_prot_blast_hits_key]


    def sample_name = data[params.locidex_summary.data_sample_key]
    def profile_data = data[params.locidex_summary.data_profile_key]
    check_key(profile_data, sample_name, meta) 
    def allele_data = profile_data[sample_name]

    
    // Length of allele data
    def total_loci = allele_data.size()
    
    def missing_alleles = allele_data.findAll { key, value -> value == params.locidex_summary.missing_allele_value}
    def alleles_contained = allele_data.count {key, value -> value != params.locidex_summary.missing_allele_value}
    def check_size = missing_alleles.size() + alleles_contained
    if(check_size != total_loci){
        error("Failed allelic tally check sum, please submit an issue and your locidex report. (Alleles Missing: ${missing_alleles.size()} + Alleles Present ${alleles_contained} != Total Alleles ${total_loci})")
    }
    


    def output_data = ["TotalLociInScheme": total_loci,
                    "LociPresent": alleles_contained,
                    "MissingAllelesCount": missing_alleles.size(), 
                    "LociNoBlastHit": no_blast_hit,
                    "LociSingleBlastHit": single_blast_hit,
                    "LociWithMultipleValues": loci_multiple_hits,
                    "LociNoNucleotideHits": loci_no_nuc_hits,
                    "LociNoProteinHits": loci_no_prot_hits]

    def json_out = new JsonBuilder(output_data).toPrettyString()

    def output_name = "${meta.id}.json"
    output_name = task.workDir.resolve(output_name)
    def output_writer = file(output_name).newWriter()
    output_writer.write(json_out)
    output_writer.close()


}


def check_key(data, key, meta){
    /*
        data: The linkedHashMap to process
        key: the key to validate
        meta: Meta map
    */

    if(!data.containsKey(key)){
        error("Missing ${key} from locidex report for ${meta.id}")
    }
}
