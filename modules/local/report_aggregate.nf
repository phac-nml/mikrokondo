/*Convert the generated mikrokondo report to a csv

*/

process REPORT_AGGREGATE{
    tag "Creating alternate output formats"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    fair true
    input:
    path summary_report

    output:
    path("final_report.tsv"), emit: final_report
    path("final_report_transposed.tsv"), emit: final_report_transposed
    path("final_report_flattened.json"), emit: flattened_files
    path("*${sample_flat_suffix}"), emit: flat_samples
    path "versions.yml", emit: versions

    script:
    sample_flat_suffix = params.report_aggregate.sample_flat_suffix
    """
    report_summaries.py -f ${summary_report} -o final_report.tsv -s ${sample_flat_suffix}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch final_report.tsv
    touch versions.yml
    """
}
