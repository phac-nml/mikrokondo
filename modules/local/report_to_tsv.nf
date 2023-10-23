/*Convert the generated mikrokondo report to a csv

*/

process REPORT_TO_TSV{
    tag "Report to TSV"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    path summary_report

    output:
    path("final_report.tsv"), emit: final_report
    path "versions.yml", emit: versions

    script:
    """
    create_summary_csv.py -f ${summary_report} -o final_report.tsv
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
