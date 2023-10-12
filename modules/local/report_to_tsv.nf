/*Convert the generated mikrokondo report to a csv

*/

process REPORT_TO_TSV{
    tag "Report to TSV"


    input:
    path summary_report

    output:
    path("final_report.tsv"), emit: final_report

    script:
    """
    create_summary_csv.py -f ${summary_report} -o final_report.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
