/*
    Downsample long reads with Rasusa
*/

process RASUSA {
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(reads), val(sample_fraction)

    output:
    tuple val(meta), path("*${params.rasusa.reads_ext}"), val(sample_fraction), emit: sampled_reads
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    rasusa reads -f ${sample_fraction} -s ${params.rasusa.seed} -O g -o ${prefix}${params.rasusa.reads_ext} ${reads.join(" ")}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rasusa: \$(rasusa --version 2>&1 | sed -e "s/rasusa //g")
    END_VERSIONS
    """
}
