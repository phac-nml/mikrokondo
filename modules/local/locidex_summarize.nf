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
    GZIPInputStream report_gz = new GZIPInputStream(new FileInputStream(new java.io.File(report.toString())))
    BufferedReader br = new BufferedReader(new InputStreamReader(report_gz))
    String report_text = null
    StringBuilder text = new StringBuilder()
    while((line = br.readLine()) != null){
        text.append(line)
    }
    report_text = text.toString()

    def report_data = json_in.parseText(report_text)
    check_key(report_data, params.locidex_summary.data_key, meta)
    def data = report_data[params.locidex_summary.data_key]

    check_key(data, params.locidex_summary.data_sample_key, meta)
    check_key(data, params.locidex_summary.data_profile_key, meta)

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

    def reportable_alleles = [:]
    if(!params.locidex_summary.reportable_alleles.isEmpty()){
        for(key in params.locidex_summary.reportable_alleles){
            if(allele_data.containsKey(key) && allele_data[key] != params.locidex_summary.missing_allele_value){
                reportable_alleles[key] = allele_data[key]
            }
        }
    }

    def output_data = ["TotalLoci": total_loci,
                    "AllelesPresent": alleles_contained,
                    "MissingAllelesCount": missing_alleles.size(),
                    "ReportableAlleles": reportable_alleles,
                    "MissingAlleles": missing_alleles ]
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
