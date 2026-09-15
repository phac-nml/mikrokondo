// StarAMR

process STARAMR {
    tag "${meta.id}"
    label "process_medium"
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(fasta), val(point_finder_db), val(staramr_param_val)
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

    def db_ = ""
    prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    def args = []
    
    if(db){
        db_ = "-d $db"
    }else{
        log.info "Using default database in StarAMR for ${meta.id}"
    }


    if(params.staramr.no_exclude_genes){
        args << "--no-exclude-genes"
    }

    if(params.staramr.exclude_negatives){
        args << "--exclude-negatives"
    }

    if(params.staramr.exclude_resistance_phenotypes){
        args << "--exclude-resistance-phenotypes"
    }

    // Species specific staramr's parameters: 
    // Defined in the subworkflow process select_pointfinder (modules/local/select_pointfinder.nf)

    if(point_finder_db){
        log.info "Using ${point_finder_db} pointfinder database for ${meta.id} in StarAMR."
        args << "--pointfinder-organism $point_finder_db"
    }else{
        log.info "No relevant pointfinder database could be identified for $meta.id"
    }
    if(staramr_param_val instanceof Collection) {
        args.addAll(staramr_param_val)
    } else if(staramr_param_val) {
        args << staramr_param_val
    }
    
    """
    export TMPDIR=\$PWD # set env temp dir to in the folder
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    staramr search \\
        --minimum-contig-length ${params.staramr.minimum_contig_length} \\
        --minimum-N50-value ${params.staramr.minimum_N50_value} \\
        --unacceptable-number-contigs ${params.staramr.unacceptable_number_contigs} \\
        --pid-threshold ${params.staramr.pid_threshold} \\
        --percent-length-overlap-plasmidfinder ${params.staramr.percent_length_overlap_plasmidfinder} \\
        ${args.join(' ')} -o $prefix $db_ $fasta_name
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
