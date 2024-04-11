process FASTQSCAN {
    tag "$meta.id"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"


    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${prefix}${params.fastqscan.json_ext}"), emit: json
    path "versions.yml", emit: versions


    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def script_run = null
    if(meta.hybrid){
        script_run = """
        r1_data=\$(zcat ${reads[0]} | fastq-scan $args)
        r2_data=\$(zcat ${reads[1]} | fastq-scan $args)
        se_data=\$(zcat ${reads[2]} | fastq-scan $args)
        combined_data=\$(zcat $reads | fastq-scan $args)
        echo {\\"$prefix\\": [ \\
            {\\"R1\\": \$r1_data }, \\
            {\\"R2\\": \$r2_data }, \\
            {\\"SE\\": \$se_data }, \\
            {\\"combined\\": \$combined } \\
        ]} > ${prefix}${params.fastqscan.json_ext}
        """
        //    + "zcat ${reads[1]} | fastq-scan $args > ${prefix}.R2${params.fastqscan.json_ext}\n" \
        //    + "zcat ${reads[2]} | fastq-scan $args > ${prefix}.SE${params.fastqscan.json_ext}" \

    }else if(!meta.single_end){
        script_run = """
        r1_data=\$(zcat ${reads[0]} | fastq-scan $args)
        r2_data=\$(zcat ${reads[1]} | fastq-scan $args)
        combined_data=\$(zcat $reads | fastq-scan $args)
        echo {\\"$prefix\\": [\\
            {\\"R1\\": \$r1_data }, \\
            {\\"R2\\": \$r2_data }, \\
            {\\"combined\\": \$combined_data } \\
        ]} > ${prefix}${params.fastqscan.json_ext}
        """
        //script_run = "zcat ${reads[0]} | fastq-scan $args > ${prefix}.R1${params.fastqscan.json_ext}\n" +\
        //    "zcat ${reads[1]} | fastq-scan $args > ${prefix}.R2${params.fastqscan.json_ext}"
    }else{
        script_run = """
        value=\$(zcat ${reads[0]} | fastq-scan $args)
        echo {\\"$prefix\\": [ \\
            {\\"SE\\": \$value }, \\
            {\\"combined\\": \$value }, \\
        ]} > ${prefix}${params.fastqscan.json_ext}
        """
    }

    """
    $script_run
    #for i in *.??.json;do name=\$(basename \$i | rev | cut -d. -f 2 | rev);echo "{\\"\$name\\":" \$(cat \$i) "},";done > ${prefix}${params.fastqscan.json_ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqscan: \$( echo \$(fastq-scan -v 2>&1) | sed 's/^.*fastq-scan //' )
    END_VERSIONS
    """
}
