// SISTR on the cluster! taking from https://github.com/nf-core/modules/blob/master/modules/nf-core/sistr/main.nf agina


process SISTR {
    tag "$meta.id"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*${params.sistr.tsv_ext}")         , emit: tsv
    tuple val(meta), path("*${params.sistr.allele_fasta_ext}"), emit: allele_fasta
    tuple val(meta), path("*${params.sistr.allele_json_ext}") , emit: allele_json
    tuple val(meta), path("*${params.sistr.cgmlst_ext}")  , emit: cgmlst_csv
    path "versions.yml"                    , emit: versions

    script:
    def args = ""
    if(params.sistr.full_cgmlst){
        args << "--use-full-cgmlst-db"
    }
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    sistr \\
        --qc \\
        $args \\
        --threads $task.cpus \\
        --alleles-output ${prefix}-allele.json \\
        --novel-alleles ${prefix}-allele.fasta \\
        --cgmlst-profiles ${prefix}-cgmlst.csv \\
        --output-prediction ${prefix} \\
        --output-format tab \\
        $fasta_name

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sistr: \$(echo \$(sistr --version 2>&1) | sed 's/^.*sistr_cmd //; s/ .*\$//' )
    END_VERSIONS
    """

    stub:
    """
    touch stub${params.sistr.tsv_ext}
    touch stub${params.sistr.allele_fasta_ext}
    touch stub${params.sistr.allele_json_ext}
    touch stub${params.sistr.cgmlst_ext}
    touch versions.yml
    """
}
