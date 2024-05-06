// StarAMR

process STARAMR {
    tag "${meta.id}"
    label "process_medium"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(fasta), val(point_finder_db)
    path db

    output:
    tuple val(meta), path("$prefix/summary${params.staramr.tsv_ext}"), emit: summary
    tuple val(meta), path("$prefix/detailed_summary${params.staramr.tsv_ext}"), emit: detailed_summary
    tuple val(meta), path("$prefix/resfinder${params.staramr.tsv_ext}"), emit: resfinder
    tuple val(meta), path("$prefix/pointfinder${params.staramr.tsv_ext}"), emit: point_finder, optional: true
    tuple val(meta), path("$prefix/plasmidfinder${params.staramr.tsv_ext}"), emit: plasmid_finder
    tuple val(meta), path("$prefix/mlst${params.staramr.tsv_ext}"), emit: mlst
    tuple val(meta), path("$prefix/settings${params.staramr.txt_ext}"), emit: settings
    tuple val(meta), path("$prefix/results${params.staramr.xlsx_ext}"), emit: results_xlsx
    tuple val(meta), path("$prefix/hits/*"), emit: hits, optional: true
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    def db_ = ""
    prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    if(db){
        db_ = "-d $db"
    }else{
        log.info "Using default database in StarAMR for ${meta.id}"
    }


    if(point_finder_db){
        log.info "Using ${point_finder_db} pointfinder database for ${meta.id} in StarAMR."
        args = args + "--pointfinder-organism $point_finder_db"
    }else{
        log.info "No relevant pointfinder database could be identified for $meta.id"
    }
    """
    export TMPDIR=\$PWD # set env temp dir to in the folder
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    # Trim line endings to fit the blastDB, and keep contig headers unique, thank you to Dillon Barker for the awk!!
    awk '/>/ {print substr(\$0, 1, 49 - length(NR))"_" NR} \$0!~">" {print \$0}' $fasta_name > temp.fasta
    mv temp.fasta $fasta_name
    staramr search $args -o $prefix $db_ $fasta_name
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        staramr: \$(echo \$(staramr -V 2>&1) | sed 's/^.*staramr //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    prefix = "stub"
    """
    mkdir stub
    touch stub/summary${params.staramr.tsv_ext}
    touch stub/detailed_summary${params.staramr.tsv_ext}
    touch stub/resfinder${params.staramr.tsv_ext}
    touch stub/pointfinder${params.staramr.tsv_ext}
    touch stub/plasmidfinder${params.staramr.tsv_ext}
    touch stub/mlst${params.staramr.tsv_ext}
    touch stub/settings${params.staramr.txt_ext}
    touch stub/results${params.staramr.xlsx_ext}
    touch versions.yml
    """




}
