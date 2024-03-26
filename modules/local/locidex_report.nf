/* Locidex report from the seq-store

*/


process LOCIDEX_REPORT {
    tag "$meta.id"
    label "process_low"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(seq_store)

    output:
    tuple val(meta), path(output_name), emit: report
    path "versions.yml", emit: versions

    script:
    output_name = "${meta.id}${params.locidex.report_suffix}"
    """
    locidex report -i $seq_store -o . --name ${meta.id} \\
    --mode ${params.locidex.report_mode} \\
    --prop ${params.locidex.report_prop} \\
    --max_ambig ${params.locidex.report_max_ambig} \\
    --max_stop ${params.locidex.report_max_stop} \\
    --force

    mv profile.json $output_name

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex report: \$(echo \$(locidex report -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """

}
