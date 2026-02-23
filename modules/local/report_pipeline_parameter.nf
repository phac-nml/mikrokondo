process REPORT_PIPELINE_PARAMETERS {
    tag "Reporting pipeline parameters"
    label 'process_single'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(parameter_settings)

    output:
    tuple val(meta), path("*.mikrokondo.parameters.json"),       emit: parameter

    script:
    """
    cp ${parameter_settings} ${meta.id}.mikrokondo.parameters.json
    """

}
