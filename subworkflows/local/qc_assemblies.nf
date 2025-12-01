// Run annotate and apply QC metrics
include { QUAST } from "../../modules/local/quast_assembly.nf"
include { SEQKIT_STATS } from "../../modules/local/seqkit_stats.nf"
include { SEQKIT_FILTER } from "../../modules/local/seqkit_filter.nf"
include { CHECKM2 } from "../../modules/local/checkm2.nf"
include { CHECKM2_DOWNLOAD } from "../../modules/local/checkm2_download.nf"
include { MLST } from "../../modules/local/mlst.nf"


process PUBLISH_FINAL_ASSEMBLIES {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"


    input:
    tuple val(meta), path(contigs), path(reads)

    output:
    tuple val(meta), path("*/*"), emit: final_assembly
    path "versions.yml", emit: versions

    script:
    """
    mkdir ${meta.sample}
    for i in ${contigs.join(" ")}
    do
        mv \$i ${meta.sample}/
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mkdir: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
        mv: \$(echo \$(touch --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
    END_VERSIONS
    """
}

workflow QC_ASSEMBLIES {
    take:
    assembled_reads // tuple val(meta), path(contigs), path(reads)


    main:

    versions = Channel.empty()
    reports = Channel.empty()

    seqkit_stats = SEQKIT_STATS(assembled_reads)

    versions = versions.mix(seqkit_stats.versions)
    reports = reports.mix(seqkit_stats.stats.map{
        meta, contigs, reads, report -> tuple(meta, params.seqkit, report)
    })

    seqkit_stats_checked = seqkit_stats.stats.map{
                                meta, contigs, reads, report -> tuple(meta, contigs, reads, check_contig_length(meta, report))
                            }.branch{
                                meta, contigs, reads, passed_p ->
                                    passed: passed_p
                                    failed: true
                            }

    reports = reports.mix(seqkit_stats_checked.passed.map{
        meta, contigs, reads, passed -> tuple(meta, params.contigs_too_short, false)
    })

    reports = reports.mix(seqkit_stats_checked.failed.map{
        meta, contigs, reads, passed -> tuple(meta, params.contigs_too_short, true)
    })


    // TODO need to add in QC message channel so failed messages are collated together
    pre_checked_data = seqkit_stats_checked.passed.map{
        meta, contigs, reads, contig_length -> tuple(meta, contigs, reads)
    }

    quast_data = QUAST(pre_checked_data)
    versions = versions.mix(quast_data.versions)
    reports = reports.mix(quast_data.quast_table.map{
        meta, report, contigs -> tuple(meta, params.quast, report)
    })

    min_length = Channel.value(params.quast.min_contig_length)

    if(!params.skip_length_filtering_contigs){
        filterd_contigs = SEQKIT_FILTER(pre_checked_data, min_length)
        versions = versions.mix(filterd_contigs.versions)
        assembled_reads = filterd_contigs.filtered_sequences
    }



    pub_final_assembly = PUBLISH_FINAL_ASSEMBLIES(assembled_reads)
    versions = versions.mix(pub_final_assembly.versions)

    if(!params.skip_checkm){
      def ch_checkmdb = null

      if(params.download_checkm2_db && params.checkm2_db != null){
          log.warn "CheckM2 database passed and download checkm2 database selected. Using passed database: $params.checkm2_db"
          ch_checkmdb = file(params.checkm2_db, checkIfExists: true)
      }else if(params.download_checkm2_db){
          // should only run once
          checkm2_data = CHECKM2_DOWNLOAD()
          ch_checkmdb = checkm2_data.database // convert database to value channel
          versions = versions.mix(checkm2_data.versions)
      }else if(params.checkm2_db != null){
          ch_checkmdb = file(params.checkm2_db, checkIfExists: true)
      }else{
          error("CheckM2 selected to be run, but no database selected is selected and params.download_checkm2_db != true")
      }

      checkm_data = CHECKM2(assembled_reads.map{
          meta, contigs, reads -> tuple(meta, contigs)
      }, ch_checkmdb)

      reports = reports.mix(checkm_data.checkm_results.map{
          meta, results -> tuple(meta, params.checkm2, results)
      })
      versions = versions.mix(checkm_data.versions)
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

    emit:
    quast_data = quast_data.quast_table
    reports = reports
    versions = versions
}


def check_contig_length(meta, report){
    def rows = report.splitCsv(header: true, sep: '\t')
    def row = rows[0] // Only one row out as only one sample in
    if(rows.size > 1){
        log.error "${meta.id} had multiple entries present for contig stats"
        exit 1
    }

    if(row[params.seqkit.filter_field].toLong() < params.quast.min_contig_length){
        log.warn "${meta.id} Max contig length is less than the minimum contig length specified for quast (${params.quast.min_contig_length}). Sample will not progress through the rest of the workflow."
        return false
    }
    return true

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
