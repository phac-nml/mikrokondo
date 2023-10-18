// StarAMR

process STARAMR {
    tag "${meta.id}"
    label "process_medium"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.containers.get('singularity') : task.ext.containers.get('docker')}"
    afterScript 'rm temp.fasta'

    input:
    tuple val(meta), path(fasta)
    path db

    output:
    tuple val(meta), path("$prefix/summary${params.staramr.tsv_ext}"), emit: summary
    tuple val(meta), path("$prefix/detailed_summary${params.staramr.tsv_ext}"), emit: detailed_summary
    tuple val(meta), path("$prefix/resfinder${params.staramr.tsv_ext}"), emit: resfinder
    tuple val(meta), path("$prefix/pointfinder${params.staramr.tsv_ext}"), emit: point_finder
    tuple val(meta), path("$prefix/plasmidfinder${params.staramr.tsv_ext}"), emit: plasmid_finder
    tuple val(meta), path("$prefix/mlst${params.staramr.tsv_ext}"), emit: mlst
    tuple val(meta), path("$prefix/settings${params.staramr.txt_ext}"), emit: settings
    tuple val(meta), path("$prefix/results${params.staramr.xlsx_ext}"), emit: results_xlsx
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def db_ = ""
    prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    if(db){
        db_ = "-d $db"
    }
    """
    export TMPDIR=\$PWD # set env temp dir to in the folder
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    # Trim line endings to fit the blastDB, and keep contig headers unique, thank you to Dillon Barker for the awk!!
    awk '/>/ {print substr(\$0, 1, 49 - length(NR))"_" NR} \$0!~">" {print \$0}' $fasta_name > temp.fasta

    staramr search $args -o $prefix $db_ temp.fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        staramr: \$(echo \$(staramr -V 2>&1) | sed 's/^.*staramr //; s/ .*\$//')
    END_VERSIONS
    """





}
