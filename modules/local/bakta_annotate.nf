// Run annototate assemblies with bakta


// TODO can use containerOptions to mount the path to the baktadb in the future
process BAKTA_ANNOTATE {
    tag "$meta.id"
    label 'process_high'
    container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

    input:
    tuple val(meta), path(fasta)
    path db
    path prodigal_tf
    path proteins
    path genus_name
    path species_name
    path strain_name
    path plasmid_name

    output:
    tuple val(meta), path("${prefix}${params.bakta.embl_ext}"), emit: embl
    tuple val(meta), path("${prefix}${params.bakta.faa_ext}"), emit: faa
    tuple val(meta), path("${prefix}${params.bakta.ffn_ext}"), emit: ffn
    tuple val(meta), path("${prefix}${params.bakta.fna_ext}"), emit: fna
    tuple val(meta), path("${prefix}${params.bakta.gbff_ext}"), emit: gbff
    tuple val(meta), path("${prefix}${params.bakta.gff_ext}"), emit: gff
    tuple val(meta), path("${prefix}${params.bakta.hypotheticals_tsv_ext}"), emit: hypotheticals_tsv
    tuple val(meta), path("${prefix}${params.bakta.hypotheticals_faa_ext}"), emit: hypotheticals_faa
    tuple val(meta), path("${prefix}${params.bakta.tsv_ext}"), emit: tsv
    tuple val(meta), path("${prefix}${params.bakta.txt_ext}"), emit: txt
    path "versions.yml", emit: versions


    script:

    def args = task.ext.args ?: ""
    if(meta.metagenomic){
        args = args + "--meta "
    }
    prefix = task.ext.prefix ?: "${meta.id}"
    // Args optional args are built below
    def proteins_opt = proteins ? "--proteins ${proteins[0]}" : ""
    def prodigal_tf = prodigal_tf ? "--prodigal-tf ${prodigal_tf[0]}" : ""
    def genus = genus_name ? "--genus ${genus_name}" : ""
    def species = species_name ? "--species ${species_name}" : ""
    def strain = strain_name ? "--strain ${strain_name}" : ""
    def plasmid = plasmid_name ? "--plasmid ${plasmid_name}" : ""
    args = args + genus + species + strain + plasmid + prodigal_tf + proteins_opt
    def threads = params.bakta.threads && params.bakta.threads > 0 ? params.bakta.threads : task.cpus
    """
    bakta --threads ${threads} --force --verbose --tmp-dir \$PWD --prefix $prefix $args --db $db --min-contig-length ${params.bakta.min_contig_length} $fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bakta: \$(echo \$(bakta --version) 2>&1 | cut -f '2' -d ' ')
    END_VERSIONS
    """

    stub:
    prefix = "stub"
    """
    touch stub.${params.bakta.embl_ext}
    touch stub.${params.bakta.faa_ext}
    touch stub.${params.bakta.ffn_ext}
    touch stub.${params.bakta.fna_ext}
    touch stub.${params.bakta.gbff_ext}
    touch stub.${params.bakta.gff_ext}
    touch stub.${params.bakta.hypotheticals_tsv_ext}
    touch stub.${params.bakta.hypotheticals_faa_ext}
    touch stub.${params.bakta.tsv_ext}
    touch stub.${params.bakta.txt_ext}
    touch versions.yml
    """
}
