// Polish assemblies with medaka

process MEDAKA_POLISH{
    tag "$meta.id"
    label 'process_high'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"
    afterScript 'rm -rf medaka' // clean up medaka output directory, having issues on resumes
    beforeScript 'rm -rf medaka' // Same reasoning as above
    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' } // May be having issues with medaka model copying

    input:
    tuple val(meta), path(reads), path(assembly)
    val model

    output:
    tuple val(meta), path("*${params.medaka.fasta_ext}"), path(reads), emit: medaka_polished
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def unzipped_assembly = "unzipped_assembly.fa"
    //TODO check if multiple read sets are ever need to be used in nanopore
    """
    gunzip -c $assembly > $unzipped_assembly
    medaka_consensus -f -m $model -d $unzipped_assembly -i $reads -b ${params.medaka.batch_size}
    mv $unzipped_assembly ${prefix}.fa
    gzip -n ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
