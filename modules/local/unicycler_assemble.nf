// Assemble long and short reads together
// Borrowing from: https://github.com/nf-core/modules/blob/master/modules/nf-core/unicycler/main.nf

process UNICYCLER_ASSEMBLE {
    tag "$meta.id"
    label "process_high"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"

    input:
    tuple val(meta), path(shortreads), path(longreads)

    output:
    tuple val(meta), path("*${params.unicycler.scaffolds_ext}"), emit: scaffolds
    tuple val(meta), path("*${params.unicycler.assembly_ext}"), emit: assembly
    tuple val(meta), path("*${params.unicycler.log_ext}"), emit: log
    path  "versions.yml", emit: versions


    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def short_reads = shortreads ? ( meta.single_end ? "-s $shortreads" : "-1 ${shortreads[0]} -2 ${shortreads[1]}" ) : ""
    def long_reads  = longreads ? "-l $longreads" : ""
    def maxmem = task.memory.toGiga() * params.unicycler.mem_modifier // Unicycler is quite memory hungry and it may be due to how it implement spades... this can likely be addressed in a PR for unicycler
    def threads_use = task.cpus * params.unicycler.threads_increase_factor // Adding more threads to see if this addresses tput error
    // TODO add to trouble shooting more information about SPADES memory and threads issues
    //println "Memory given to SPADEs: $maxmem"
    // TODO need to add log parser to identify why something failed, e.g. move the spades log to a publish dir
    """
    unicycler --threads $threads_use $args $short_reads $long_reads --spades_options "-m ${maxmem.toInteger()}" --out .
    #unicycler --threads $threads_use $args $short_reads $long_reads --out .
    mv assembly.fasta ${prefix}.scaffolds.fa
    gzip -n ${prefix}.scaffolds.fa
    mv assembly.gfa ${prefix}.assembly.gfa
    gzip -n ${prefix}.assembly.gfa
    mv unicycler.log ${prefix}.unicycler.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        unicycler: \$(echo \$(unicycler --version 2>&1) | sed 's/^.*Unicycler v//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.unicycler.scaffolds_ext}
    touch stub${params.unicycler.assembly_ext}
    touch stub${params.unicycler.log_ext}
    touch versions.yml
    """

}
