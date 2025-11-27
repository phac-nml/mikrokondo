
process CHECKM2 {
  tag "$meta.id"
  label 'process_medium'
  container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"
    
  input:
  tuple val(meta), path(fasta)


  output:
  tuple val(meta), path("${prefix}/**"), emit: checkm_output
  tuple val(meta), path("${prefix}/quality_report.tsv"), emit: checkm_results
  path "versions.yml", emit: versions


  script:
  def args = task.ext.args ?: ''
  prefix = task.ext.prefix ?: "${meta.id}" 
  def is_compressed = fasta.getName().endsWith(params.checkm.gzip_ext) ? true : false
  """
  mkdir $prefix
  echo $fasta > input_file.txt 

  checkm2 predict --threads ${task.cpus} \
  --input input_file.txt \
  --output-directory $prefix \
  $args
  

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      checkm2: \$(checkm2 --version)
  END_VERSIONS
  """
  }
