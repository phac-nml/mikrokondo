// Assemble reads with spades


process SPADES_ASSEMBLE {
    tag "$meta.id"
    label 'process_high'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    fair true
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*${params.spades.scaffolds_ext}"), optional:true, emit: scaffolds
    tuple val(meta), path("*${params.spades.contigs_ext}"), optional:true, emit: contigs
    tuple val(meta), path("*${params.spades.transcripts_ext}"), optional:true, emit: transcripts
    tuple val(meta), path("*${params.spades.gene_clusters_ext}"), optional:true, emit: gene_clusters
    tuple val(meta), path("*${params.spades.assembly_graphs_ext}"), optional:true, emit: graphs
    tuple val(meta), path("*${params.spades.log_ext}"), emit: log
    path  "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    if(meta.metagenomic){
        if(meta.single_end){
            log.info "${meta.id} was determined to be a metagenomic sample \
but does not contain paired end reads. Currently only metaspades is \
implemented and requires paired end reads. Therefore typical De-Novo assembly will be performed"
        }else{
            log.info "Using metaspades for sample ${meta.id}"
            args = args + " --meta"
        }
    }else if (!meta.single_end){
        args = args + " --isolate"
    }

    def prefix = task.ext.prefix ?: "$meta.id"
    def maxmem = task.memory.toGiga()
    def illumina_reads = reads ? ( meta.single_end ? "-s ${reads[0]}" : "-1 ${reads[0]} -2 ${reads[1]}" ) : ""
    """
    spades.py $args --threads $task.cpus --memory $maxmem $illumina_reads -o ./
    mv spades.log ${prefix}.spades.log
    if [ -f scaffolds.fasta ]; then
        mv scaffolds.fasta ${prefix}.scaffolds.fasta
        gzip -n ${prefix}.scaffolds.fasta
    fi
    if [ -f contigs.fasta ]; then
        mv contigs.fasta ${prefix}.contigs.fasta
        gzip -n ${prefix}.contigs.fasta
    fi
    if [ -f transcripts.fasta ]; then
        mv transcripts.fasta ${prefix}.transcripts.fasta
        gzip -n ${prefix}.transcripts.fasta
    fi
    if [ -f assembly_graph_with_scaffolds.gfa ]; then
        mv assembly_graph_with_scaffolds.gfa ${prefix}.assembly.gfa
        gzip -n ${prefix}.assembly.gfa
    fi
    if [ -f gene_clusters.fasta ]; then
        mv gene_clusters.fasta ${prefix}.gene_clusters.fasta
        gzip -n ${prefix}.gene_clusters.fasta
    fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed 's/^.*SPAdes genome assembler v//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.spades.scaffolds_ext}
    touch stub${params.spades.contigs_ext}
    touch stub${params.spades.transcripts_ext}
    touch stub${params.spades.gene_clusters_ext}
    touch stub${params.spades.assembly_graphs_ext}
    touch stub${params.spades.log_ext}
    touch versions.yml
    """


}
