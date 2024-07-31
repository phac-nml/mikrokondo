/* Locidex report from the seq-store

*/

process LOCIDEX_REPORT {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(seq_store)

    output:
    tuple val(meta), path(output_name), emit: report
    path "versions.yml", emit: versions

    script:
    output_name = "${meta.id}${params.locidex.report_suffix}"
    def is_compressed = seq_store.getName().endsWith(".gz")
    def seq_store_name = seq_store.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $seq_store > $seq_store_name
    fi
    locidex report -i $seq_store_name -o . --name ${meta.id} \\
    --mode ${params.locidex.report_mode} \\
    --prop ${params.locidex.report_prop} \\
    --max_ambig ${params.locidex.report_max_ambig} \\
    --max_stop ${params.locidex.report_max_stop} \\
    --force

    gzip -c report.json > $output_name
    rm report.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex report: \$(echo \$(locidex report -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """

}
