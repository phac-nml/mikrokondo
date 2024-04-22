/*
GZIP output files
*/

process GZIP_FILES {
    tag "${meta.id}"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(file_in)


    output:
    tuple val(meta), path(output_name), emit: zipped_file
    path "versions.yml", emit: versions


    script:
    output = file_in.getName()
    output_name = "${output}.gz"
    """
    gzip -c ${file_in} > ${output_name}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(echo \$(gzip --help 2>&1 | head -n 1 ) | sed -e 's/ (.*//')
    END_VERSIONS
    """


}
