
process CHECKM2 {
  tag "$meta.id"
  label 'process_medium'
  container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"
    
  input:
  tuple val(meta), path(fasta)
  path(database)


  output:
  tuple val(meta), path("${prefix}/**"), emit: checkm_output
  tuple val(meta), path("${prefix}/quality_report.tsv"), emit: checkm_results
  path "versions.yml", emit: versions


  script:
  def args = task.ext.args ?: ''
  prefix = task.ext.prefix ?: "${meta.id}" 
  def is_compressed = fasta.getName().endsWith("gz") ? true : false
  """
  mkdir $prefix

  checkm2 predict --threads ${task.cpus} \
  --input $fasta \
  --output-directory $prefix \
  --database_path $database \
  $args
  

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      checkm2: \$(checkm2 --version)
  END_VERSIONS
  """
  }
