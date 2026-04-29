// Assemble with shovill


process SHOVILL_ASSEMBLE {
    tag "$meta.id"
    label 'process_medium' // Shovill uses process medium as it does not need to handle large metagenomes
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}/*.contigs.fa"), emit: contigs
    tuple val(meta), path("${meta.id}/*.contigs.gfa"),  emit: graphs
    tuple val(meta), path("${meta.id}/shovill.corrections"), emit: corrections, optional: true
    tuple val(meta), path("${meta.id}/shovill.log"), emit: log
    tuple val(meta), path("${meta.id}/{velvet,megahit,spades,skesa}.fasta"), emit: raw_contigs
    path "versions.yml", emit: versions


    script:
    def args = task.ext.args ?: []
    if(params.shovill.plasmid_mode){
        args += "--plasmid"
    }

    if(params.shovill.opts){
        args += "--opts ${params.shovill.opts}"
    }

    if(params.shovill.kmers){
        args += "--kmers ${params.shovill.kmers}"
    }

    if(params.shovill.trim){
        args += "--trim"
    }

    if(params.shovill.no_read_correction){
        args += "--noreadcorr"
    }

    if(params.shovill.no_stitch){
        args += "--nostitch"
    }

    if(!params.skip_polishing){
        args += "--nocorr"
    }

    if(params.shovill.keepfiles){
        args += "--keepfiles"
    }

    // depth and minlen are hard coded to 0 as mikrokondo will perform the contig filtering and down-sampling
    """
    shovill --R1 ${reads[0]} --R2 ${reads[1]} --cpus $task.cpus \\
    --ram ${task.memory.toGiga()} --depth 0 \\
    --outdir ${meta.id} --force \\
    --minlen 0 \\
    --mincov ${params.shovill.minimum_coverage} \\
    ${args.join(' ')} --assembler $params.shovill_assembler

    mv ${meta.id}/contigs.fa ${meta.id}/${meta.id}.contigs.fa
    mv ${meta.id}/*.gfa ${meta.id}/${meta.id}.contigs.gfa

 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        shovill: \$(shovill --version 2>&1 | sed "s/^.shovill //")
    END_VERSIONS
    """

}
