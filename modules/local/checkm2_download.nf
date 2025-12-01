

process CHECKM2_DOWNLOAD{
  tag "CheckM2 Database Download"
  label 'process_medium'
  container "${workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer' ? task.ext.parameters.get('singularity') : task.ext.parameters.get('docker')}"

  output:
  path("**.dmnd"), emit: database
  path("versions.yml"), emit: versions

  script:
  """
  wget -O checkm2_db.tar.gz $params.checkm2.download_link
  tar -xvzf checkm2_db.tar.gz

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      wget: \$(wget --version | head -1 | cut -d ' ' -f 3)
      tar: \$(tar --version | grep tar | sed 's/.*) //g')
  END_VERSIONS
  """

    
  }
