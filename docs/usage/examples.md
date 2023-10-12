# Command Line Examples

Some example commands of running mikrokondo are provided below:

## Running paired-end illumina data skipping Bakta
`nextflow run main.nf --input sample_sheet.csv --skip_bakta true --platform illumina --outdir ../test_illumina -profile singularity -resume`

The above command would run paired-end Illumina data, using Singulairty as a container service, using resume (e.g if picks up where the pipeline left off if being run again), skipping Bakta and outputting results in a folder called `test_illumina` one directory back from where the pipeline is run. **Note: your sample sheet does not need to be called sample_sheet.csv**

## Running paired-end illumina data using Kraken2 for classifying the top species hit

`nextflow run main.nf --input sample_sheet.csv --skip_bakta true --run_kraken true --platform illumina --outdir ../test_illumina_kraken -profile singularity -resume`

The above command would run paired-end Illumina data, using Singulairty as a container service, using resume (e.g if picks up where the pipeline left off if being run again), skipping Bakta, using kraken2 to classify the species top hit and outputting results in a folder called `test_illumina_kraken` one directory back from where the pipeline is run. **Note: your sample sheet does not need to be called sample_sheet.csv**

## Running nanopore data
`nextflow run main.nf --input sample_sheet.csv --skip_ont_header_cleaning true --nanopore_chemistry r941_min_hac_g507 --platform nanopore --outdir ../test_nanopore -profile docker -resume`

The above command would run single-end Nanopore data using Docker as a container service, using resume (e.g if picks up where the pipeline left off if being run again), outputting data into a folder called `../test_nanopore` and skipping the process of verifying all Nanopore fastq data headers are unique. **Note: your sample sheet does not need to be called sample_sheet.csv**

## Running a hybrid assembly using Unicycler
`nextflow run main.nf --input sample_sheet.csv --hybrid_unicycler true --nanopore_chemistry r941_min_hac_g507 --platform hybrid --outdir ../test_hybrid -profile apptainer -resume`

The above command would run single-end Nanopore and paired-end Illumina data using apptainer as a container service, using resume (e.g if picks up where the pipeline left off if being run again), outputting data into a folder called `../test_hybrid` and using Unicycler for assembly. **Note: your sample sheet does not need to be called sample_sheet.csv**

## Running a hybrid assembly without Unicycler
`nextflow run main.nf --input sample_sheet.csv --platform hybrid --outdir ../test_hybrid -profile singularity -resume`

The above command would run single-end Nanopore and paired-end Illumina data using singularity as a container service, using resume (e.g if picks up where the pipeline left off if being run again), outputting data into a folder called `../test_hybrid`. **Note: your sample sheet does not need to be called sample_sheet.csv**

## Running metagenomic Nanopore data
`nextflow run main.nf --skip_depth_sampling true --input sample_sheet.csv --skip_polishing true --skip_bakta true --metagenomic_run true --nanopore_chemistry r941_prom_hac_g507 --platform nanopore --outdir ../test_nanopore_meta -profile singularity -resume`

The above command would run single-end Nanopore and paired-end Illumina data using singularity as a container service, using resume (e.g if picks up where the pipeline left off if being run again), outputting data into a folder call `../test_nanopore_meta`, all samples would be labeled treated as metagenomic, assembly polishing would be turned off and annotation of assemblies with Bakta would not be performed, depth sampling would not be performed either. **Note: your sample sheet does not need to be called sample_sheet.csv**