# Command line and Configuration Usage


## Configuration files

When cloning the pipeline from github a directory labeled `conf/` will be present. Within the `conf/` folder two configuration files are of interest to the user:

- base.config: Where cpu, memory and time parameters can be set for the different workflow processes. **You will likely need to adjust parameters within this file for you computing environment**.

- modules.config: Where process specific parameters are set. It is unadvised to touch this configuration file unless performing pipeline development.

### Base configuration (conf/base.config)
Within this file computing resources can be configured for each process. Different labels are listed defining different resources for different Nextflow processes. The defined labels you are encouraged to modify are:

- `process_single`: Resource definitions for processes requiring only a single core and low memory (listing of directories).
- `process_low`: Resource definitions for processes that would typically run easily on a small laptop (Staging of data in a Python script).
- `process_medium`: Resource definitions for processes that would typically run on a desktop computer equipped for playing newer video games (Memory or computationally intensive applications that can be parallelized, rendering, processing large files in memory or running BLAST).
- `process_high`: Resource definition for processes that would typically run on a high performance desktop computer (Memory our computationally intensive application like running performing *de novo* assembly or performing BLAST searches on large databases).
- `process_long`: Modifies/overwrites the amount of time allowed for any of the above processes. Allows for certain jobs to take longer (Performing *de novo* assembly with less computational resources or performing global alignments on divergent sequences).
- `process_high_memory`: Modifies/overwrites the amount of memory given to any process. Grants significantly more memory to any process (Aids in metagenomic assembly or clustering of large datasets).

## Containers

Different container services can be specified from the command line when running mikrokondo in the `-profile` option. This option is specified at the end of your command line argument. Examples of different container services are specified below:

- For Docker: `nextflow run main.nf MY_OPTIONS -profile docker`
- For Singularity: `nextflow run main.nf MY_OPTIONS -profile singularity`
- For Apptainer: `nextflow run main.nf MY_OPTIONS -profile apptainer`
- For Shifter: `nextflow run main.nf MY_OPTIONS -profile shifter`
- For Charliecloud: `nextflow run main.nf MY_OPTIONS -profile charliecloud`
- For Gitpod: `nextflow run main.nf MY_OPTIONS -profile gitpod`
- For Podman: `nextflow run main.nf MY_OPTIONS -profile podman`

## Requirements

1. Running MikroKondo requires have Nextflow installed, a Python interpreter 3.10=> and singularity or docker installed (only singularity is supported currently).
    - Note Nextflow only runs on linux
    - The easiest way to install Nextflow is using conda simply enter:
    `conda create -n nextflow nextflow -c bioconda -c conda-forge -c default`

## Downloading the pipeline
1. To download MikroKondo simply clone the repository

## Running MikroKondo
### Samplesheet
Mikrokondo requires a sample sheet to be run A.K.A FOFN (file of file names). Having The sample sheet contains the samples name and allows a user to combine read-sets based on a sample name if provided. The sample-sheet utilizes the following header fields however: sample, fastq_1, fastq_2, long_reads and assembly. **The sample sheet must be in csv format and sample files must be gzipped on input**

- The example layouts for different sample-sheets include:

    **Illumina paired-end data**

    |sample|fastq_1|fastq_2|
    |------|-------|-------|
    |sample_name|path_to_forward_reads|path_to_reversed_reads|

    **Nanopore**

    |sample|long_reads|
    |------|----------|
    |sample_name|path_to_reads|

    **Hybrid Assembly**

    |sample|fastq_1|fastq_2|long_reads|
    |-------|-------|------|----------|
    |sample_name|path_to_forward_reads|path_to_reversed_reads|path_to_long_reads|

    **Starting with assembly only**

    |sample|assembly|
    |------|--------|
    |sample_name|path_to_assembly|

## Boiler plate options
Boiler plate options that are provided thanks to nf-core are listed below:

- publish_dir_mode: Method used to save pipeline results to output directory
- email: Email address for completion summary.
- email_on_fail: An email address to send a summary email to when the pipeline is completed - ONLY sent if the pipeline does not exit successfully.
- plaintext_email: Send plain-text email instead of HTML.
- monochrome_logs: Do not use coloured log outputs.
- hook_url: Incoming hook URL for messaging service. Currently, MS Teams and Slack are supported.
- help: Display help text.
- version: Display version and exit.
- validate_params: Boolean whether to validate parameters against the schema at runtime.
- show_hidden_params: By default, parameters set as _hidden_ in the schema are not shown on the command line when a user runs with `--help`. Specifying this option will tell the pipeline to show all parameters.

## Configuration/Command line Arguments

Within the nextflow.config file the pipeline uses, the params section can be altered by users within the nextflow.config file or from the commandline
**TODO usage needs to be better written, just putting in basic info**

MikroKondo can be run like most other nextflow pipelines. The most basic usage is as follows:
 `nextflow run main.nf --input {USER INPUT SHEET HERE} --outdir {Output directory} --nanopore_chemistry {specify medaka model for polishing with ONT data} --platform {illumina, nanopore, pacbio, hybrid} {Optional parameters} -profile {singularity or docker} {optional -resume}`

Mentioned above is an optional parameters section, many parameters can be altered or accessed from the command line. For a full list of parameters to be altered please refer to the `nextflow.config` file in the repo.

## Platform specification
Mikrokondo allows for sequencing data from three platforms (must be FastQ): Illumina (paired end only), Nanopore and Pacbio (Pacbio path needs better testing). To specify which platform you are using from the command line you can enter:
- `--platform illumina` for Illumina.
- `--platform nanopore` for Nanopore.
- `--platform pacbio` for Pacbio
- `--platform hybrid` for hybrid assemblies.
    - **If you pick denote your run as using a hybrid platform you must also add in the long_read_opt parameter the defualt value is nanopore**. `--long_read_opt nanopore` for nanopore or `--long_read_opt pacbio` for pacbio.

## Nanopore Data
If you are using nanopore you must specify a model to use in Medaka for polishing (unless you turned on the skip_polishing option). A list of allowed models can be found here: [Medaka models python script](https://github.com/nanoporetech/medaka/blob/master/medaka/options.py) or [Medaka models available for download](https://github.com/nanoporetech/medaka/tree/master/medaka/data)

A model can be specified like so `--nanopore_chemistry YOUR_MODEL_HERE`. A real example would look like this -> `--nanopore_chemistry r1041_e82_400bps_hac_v4.2.0`

No default model is specified to prevent tiny errors that may affect data, but if your lab is using the same setting every time you can update the value in the `nextflow.config` labeled `nanopore_chemistry`.
An example of an update would be:
```
nanopore_chemistry = "r1041_e82_400bps_hac_v4.2.0" // Note the quotes around the value
```

## Assembly with Flye (Nanopore and Pacbio)
As Flye provides different assembly optoins for Nanopore or Pacbio reads of varying qualities the `--fly_read_type` parameter can be altered from the command line. The default value is set too `hq` (High quality for Nanopore reads, and HiFi for bacterial reads). User options include `hq`, `corr` and `raw`, and a default value can be specified in the `nextflow.config` file.

## Running Kraken2 instead of Mash
If you really like Kraken2 for speciation, you can enable it over Mash at the command line by specifying:
`--run_kraken true`

If you wish to update this value for every run in the `nextflow.config` file you can update it to say:
```
run_kraken = true // Note the lack of quotes
```

## Run Unicycler instead of Flye->Racon->Pilon
To use Unicycler specify on the command line `--hybrid_unicycler true`. If you would like to update this value so that the pipeline always uses Unicycler you can adjust the `nextflow.config` file like so:

### Potential error with Unicycler
You may need to check the `conf/base.config` `process_high_memory` declaration and provide it upwards of 1000GB of memory if you get errors mentioning `tputs`. This error is not very clear sadly but increasing resources available to the process will help.

```
hybrid_unicycler = true // Note the lack of quotes
```

## Minimum number of reads for assembly
The `min_reads` option in the `nextflow.config` file is set to a limit of 1000. This means that after FastP has run 1000 reads must be present for the sample to proceed to assembly. If this values is not met, the sample does not proceed for assembly or pipeline steps. You can lower or raise this value from the command line like so: `--min_reads 100`

If you wish to update this value in your `nextflow.config` file you can alter the value like so.
```
min_reads = 1000 // Note the lack of quotes
```

## Target Depth
If you have not opted to skip down sampling you reads (elaborated on in the next section). You can set a target depth for sampling, e.g. if you set your `target_depth` value to 100 and sample has an estimated depth of 200bp your reads would be sampled to try and achieve a target depth of 100. If your sample has an estimated depth of 80 and your `target_depth` is 100, no downsampling will occur.

To set you target depth from the command line enter `--target_depth 100` (or whatever number you want it to be). To update this value in your `nextflow.config` you can update it like so.
```
target_depth = 100 // Note the lack of quotes
```

## Specify all samples as metagenomic
You can specify your samples are metagenomic directly which will affect the report, the pipeline will skip running mash to see if your samples are metagenomic and proceed with metagenomic assembly.

To toggle on a metagenomic assembly simply enter `--metagenomic_run true`. To update the `nextflow.config` file to always run your samples as metagenomic simply change the `metagenomic_run` variable like so.
```
metagenomic_run = true // Note the lack of quotes
```

## Skip Options
Numerous steps within mikrokondo can be turned off without compromising the stability of the pipeline. This skip options can reduce run-time of the pipeline or allow for completion of the pipeline despite errors. Currently these include

- `skip_report`
    - This option can be toggled on to prevent the generation of the final summary report, containing a condensed output the different tools run within the pipeline.
- `skip_version_gathering`
    - Version information of each tool ran within the pipeline is collated as the pipeline runs before a final report is generated. While this is nice, it can be a time consuming process (a few minutes at worse) but when performing developing the pipeline turning this step off can make recurrent runs of the pipeline easier.
- `skip_subtyping`
    - Subtyping tools such as: ECTyper, SISTR etc. are automatically triggered in the pipeline but if subtyping information is of no interest to you e.g. your target organism does not have a subtyping tool installed within mikrokondo you can turn this step off.
- `skip_abricate`
    - Abricate (AMR detection) is included within the pipeline. It can be turned off if this step gives you trouble, however it is quite fast to run.
- `skip_bakta`
    - Bakta is a full annotation pipeline that outputs a lot of very useful information. However it can be quite slow to run and requires a database to be specified. If this information is of no further interest to you, it is better to disable this process.
- `skip_checkm`
    - CheckM is solely used as part of contamination detection within mikrokondo, its run time and resource usage can be quite lengthy.
- `skip_depth_sampling`
    - The genome size of the reads is estimated using mash, and reads can be down-sampled to a target depth in order to get a better assembly. If this is of no interest to you, this step can be skipped entirely. **If you have specified that your run is metagenomic, down sampling is turned off**.
- `skip_ont_header_cleaning`
    - In rare situations you may have Nanopore data fail in the pipeline due to duplicate headers, while rare it can be quite annoying for an assembly that has already been going on for more than 5 hours to fail. So there is a process in mikrokondo to make each Nanopore read header unique and avoid this issue, it is slow and usually unneeded so it is **best to run the pipeline with this step disabled**.
- `skip_polishing`
    - If you are running a metagenomic assembly or you are having issues with any of the polishing steps you can disable polishing and retrieve your assembly directly from Spades or Flye with no additional polishing. **This does not apply to hybrid assemblies**.
- `skip_species_classification`
    - This step prevents Mash or Kraken2 from being run on your assembled genome, this also **prevents the subtyping workflow** from triggering
- `skip_mobrecon`
  - This step allows you to skip running Mobsuite recon on your data.

** All of the above options can be turned on by entering `--{skip_option} true` in the command line arguments to the pipeline (where optional parameters can be added)** e.g. To skip read sub-sampling add to the command line arguments `--skip_depth_sampling true`

### Slurm options
- `slurm_p`
    - if set to true, the slurm executor will be used.
- `slurm_profile`
    - A string to allowing the user to specify which slurm partition to use

### Max Resources
TODO this are the nextflow defaults
TODO make it known what should stay and what can be routinely changed


## Tool Specific Parameters
**NOTE:** to access tool specific parameters from the command line you must use the dot operator. e.g. In order to set the min contig length you would like Quast to use for generating report metrics from the command line you would specify `--quast.min_contig_length 500`

All parameters below are nested, to denote the path to each parameter the options will be denoted nested so that at the top-level is the first level of the parameter, then sub bullets will be nested within that parameter.

The example below is to show how parameters are denoted.

```
- tool
    - tool_param1
        - tool_param2
```

If as an example if, the `--quast.min_contig_lenth` parameter would be written as:

```
- quast
    - min_contig_length
```

Note: Parameters that are bolded are ones that can be freely changed. Sensible defaults are provided however

### Abricate
Screens contigs for antimicrobial and virulence genes.

- abricate
    - **args**: Can be a string of additional command line arguments to pass to abricate
    - report_tag: This field determines the name of the Abricate output in the final summary file. Do no touch this unless doing pipeline development.
    - header_p: This field tells the report module that the Abricate output contains headers. Do no touch this unless doing pipeline development.

### Raw Read Metrics
A custom Python script that gathers quality metrics for each fastq file.

- raw_reads
    - high_precision: When set to true, floating point precision of values output are accurate down to very small decimal places. Leave this setting as false to use the standard floats in Python, as it is much faster and having such precise decimal places does not quite make sense for the purpose this module fills.
    - report_tag: this field determines the name of the Raw Read Metric field in the final summary report. Do no touch this unless doing pipeline development.

### Coreutils
Some processes only utilize bash scripting, normally Nextflow will utilize system binaries if they are available and no container is specified. But in the case of a process where only scripting and binutils are being utilized as container was specified for reproducibility.

- coreutils
    - singularity: coreutils singularity container
    - docker: coreutils docker container

### KAT
Kat was previously used to estimate genome size, however at the time of writing KAT appears to be only infrequently updated and newer versions would have issues running/sometimes giving an incorrect output due to failures in peak recognition KAT has been removed from the pipeline. It's code still remains but it **will be removed in the future**.

### Seqtk
Seqtk is used for both the sub-sampling of reads and conversion of fasta files to fastq files in mikrokondo. The usage of seqtk to convert a fasta to a fastq is needed to use Shigatyper as it requires fastq files as input, and do pass the reads to Shigatyper could results in a reduction of generalizability of the subtyping workflow.

- seqtk
    - singularity: singularity container for seqtk
    - docker: docker container for seqtk
    - seed: A seed value for sub-sampling
    - reads_ext: Extension of reads after sub-sampling, do not touch alter this unless doing pipeline development.
    - assembly_fastq: Extension of the fastas after being converted to fastq files. Do no touch this unless doing pipeline development.
    - report_tag: Name of seqtk data in the final summary report. Do no touch this unless doing pipeline development.

### FastP
Fastp is fast and widely used program for gathering of read quality metrics, adapter trimming, read filtering and read trimming. FastP has extensive options for configuration which are detailed in their documentation, but sensible defaults have been set. **Adapter trimming in Fastp is performed using overlap analysis, however if you do not trust this you can specify the sequencing adapters used directly in the additional arguments for Fastp**.

- fastp
    - singulartiy: singularity container for FastP
    - docker: docker container for FastP
    - fastq_ext: extension of the output Fastp trimmed reads, do not touch this unless doing pipeline development.
    - html_ext: Extension of the html report output by fastp, do no touch unless doing pipeline development.
    - json_ext: Extension of json report output by FastP do not touch unless doing pipeline development.
    - report_tag: Title of FastP data in the summary report.
    - **average_quality_e**: If a read/read-pair quality is less than this value it is discarded
    - **cut_mean_quality**: The quality to trim reads too
    - **qualified_quality_phred**: the quality of a base to be qualified if filtering by unqualified bases
    - **unqualified_percent_limit**: The percent amount of bases that are allowed to be unqualified in a read. This parameter is affected by the above qualified_quality_phred parameter
    - **illumina_length_min**: The minimum read length to be allowed in illumina data
    - **single_end_length_min**: the minimum read length allowed in Pacbio or Nanopore data
    - **dedup_reads**: A parameter to be turned on to allow for deduplication of reads.
    - **illumina_args**: The command string passed to Fastp when using illumina data, if you override this parameter other set parameters such as average_quality_e must be overridden as well as the command string will be passed to FastP as written
    - **single_end_args**: The command string passed to FastP if single end data is used e.g. Pacbio or Nanopore data. If this option is overridden you must specify all parameters passed to Fastp as this string is passed to FastP as written.
    - report_exclude_fields: Fields in the summary json to be excluded from the final aggregated report. Do not alter this field unless doing pipeline development

### Chopper
Chopper was originally used for trimming of Nanopore reads, but FastP was able to do the same workd so Chopper is no longer used. Its code still but it cannot be run in the pipeline.

### Flye
Flye is used for assembly of Nanopore data.

- flye
    - nanopore
        - raw: corresponds to the option in Flye of `--nano-raw`
        - corr: corresponds to the option in Flye of `--nano-corr`
        - hq: corresponds to the option in Flye of `--nano-hq`
    - pacbio
        - raw: corresponds to the option in Flye of `--pacbio-raw`
        - corr: corresponds to the option in Flye of `--pacbio-corr`
        - hifi: corresponds to the option in Flye of `--pacbio-hifi`
    - singularity: Singularity container for Flye
    - docker: Docker container for Flye
    - fasta_ext: The file extension for fasta files. Do not alter this field unless doing pipeline development
    - gfa_ext: The file extension for gfa files. Do not alter this field unless doing pipeline development
    - gv_ext: The file extension for gv files. Do not alter this field unless doing pipeline development
    - txt_ext: the file extension for txt files. Do not alter this field unless doing pipeline development
    - log_ext: the file extension for the Flye log files. Do not alter this field unless doing pipeline development
    - json_ext: the file extension for the Flye json files. Do not alter this field unless doing pipeline development
    - **polishing_iterations**: The number of polishing iterations for Flye.
    - ext_args: Extra commandline options to pass to Flye

### Spades
Usef for parired end read assembly

- spades
    - singularity: Singularity container for spades
    - docker: Docker container for spades
    - scaffolds_ext: The file extension for the scaffolds file. Do not alter this field unless doing pipeline development
    - contigs_ext: The file extension containing assembled contigs. Do not alter this field unless doing pipeline development
    - transcripts_ext: The file extension for the assembled transcripts. Do not alter this field unless doing pipeline development
    - assembly_graphs_ext: the file extension of the assembly graphs. Do not alter this field unless doing pipeline development
    - log_ext: The file extension for the log files. Do not alter this field unless doing pipeline development
    - outdir: The name of the output directory for assemblies. Do not alter this field unless doing pipeline development

### FastQC
This is a defualt tool added to nf-core pipelines. This feature will likely be removed in the future but for those fond of it, the outputs of FastQC still remain.

- fastqc
    - html_ext: The file extension of the fastqc html file. Do not alter this field unless doing pipeline development
    - zip_ext: The file extension of the zipped FastQC outputs. Do not alter this field unless doing pipeline development

### Quast
Quast is used to gather assembly metrics which automated quality control criteria are the applied too.

- quast
    - singularity: Singularity container for quast.
    - docker: Docker container for quast.
    - suffix: The suffix attached to quast outputs. Do not alter this field unless doing pipeline development.
    - report_base: The base term for output quast files to be used in reporting. Do not alter this field unless doing pipeline development.
    - report_prefix: The prefix of the quast outputs to be used in reporting. Do not alter this field unless doing pipeline development.
    - **min_contig_length**: The minimum length of for contigs to be used in quasts generation of metrics. Do not alter this field unless doing pipeline development.
    - **args**: A command string to past to quast, altering this is unadvised as certain options may affect your reporting output. This string will be passed to quast verbatim. Do not alter this field unless doing pipeline development.
    - header_p: This tells the pipeline that the Quast report outputs contains a header. Do not alter this field unless doing pipeline development.

### Quast Filter
Assemblies can be prevented from going into further analyses based on the Quast output. The options for the mentioned filter are listed here.

- quast_filter
    - n50_field: The name of the field to search for and filter. Do not alter this field unless doing pipeline development.
    - n50_value: The minimum value the field specified is allowed to contain.
    - nr_contigs_field: The name of field in the Quast report to fiter on. Do not alter this field unless doing pipeline development.
    - nr_contigs_value: The minimum number of contigs an assembly must have to proceed further through the pipeline.
    - sample_header: The column name in the Quast output containing the sample information. Do not alter this field unless doing pipeline development.

### CheckM
CheckM is used within the pipeline for assesing contamination in assemblies.

- checkm
    - singularity: Singularity container containing CheckM
    - docker: Docker container containing CheckM
    - alignment_ext: Extension on the genes alignment within CheckM. Do not alter this field unless doing pipeline development.
    - results_ext: The extension of the file containing the CheckM results. Do not alter this field unless doing pipeline development.
    - tsv_ext: The extension containing the tsv results from CheckM. Do not alter this field unless doing pipeline development.
    - folder_name: The name of the folder containing the outputs from CheckM. Do not alter this field unless doing pipeline development.
    - gzip_ext: The compression extension for CheckM. Do not alter this field unless doing pipeline development.
    - lineage_ms: The name of the lineages.ms file output by CheckM. Do not alter this field unless doing pipeline development.
    - threads: The number of threads to use in CheckM. Do not alter this field unless doing pipeline development.
    - report_tag: The name of the CheckM data in the summary report. Do not alter this field unless doing pipeline development.
    - header_p: Denotes that the result used by the pipeline in generation of the summary report contains a header. Do not alter this field unless doing pipeline development.

### Kraken2
Kraken2 can be used a substitute for mash in speciation of samples, and it is used to bin contigs of metagenomic samples.

- kraken
    - singularity: Singularity container for the Kraken2.
    - docker: Docker container for Kraken2.
    - classified_suffix: Suffix for classified data from Kraken2. Do not alter this field unless doing pipeline development.
    - unclassified_suffix: Suffic for unclassified data from Kraken2. Do not alter this field unless doing pipeline development.
    - report_suffix: The name of the report output by Kraken2.
    - output_suffix: The name of the output file from Kraken2. Do not alter this field unless doing pipeline development.
    - **tophit_level**: The taxonomic level to classify a sample at. e.g. default is `S` for species but you could use `S1` or `F`.
    - save_output_fastqs: Option to save the output fastq files from Kraken2. Do not alter this field unless doing pipeline development.
    - save_read_assignments: Option to save how Kraken2 assigns reads. Do not alter this field unless doing pipeline development.
    - **run_kraken_quick**: This option can be set to `true` if one wishes to run Kraken2 in quick mode.
    - report_tag: The name of the Kraken2 data in the final report. Do not alter this field unless doing pipeline development.
    - header_p: Tell the pipeline that the file used for reporting does or does not contain header data. Do not alter this field unless doing pipeline development.
    - headers: A list of headers in the Kraken2 report.  Do not alter this field unless doing pipeline development.


### Seven Gene MLST
Run Torstein Tseemans seven gene MLST program.

- mlst
    - singularity: Singularity container for mlst.
    - docker: Docker container for mlst.
    - **args**: Addtional arguments to pass to mlst.
    - tsv_ext: Extension of the mlst tabular file.  Do not alter this field unless doing pipeline development.
    - json_ext: Extension of the mlst output JSON file.  Do not alter this field unless doing pipeline development.
    - report_tag: Name of the data outputs in the final report.  Do not alter this field unless doing pipeline development.

### Mash
Mash is used repeatedly througout the pipeline for estimation of genome size from reads, contamination detection and for determining the final species of an assembly.

- mash
    - singularity: Singularity container for mash.
    - docker: Docker container for mash.
    - mash_ext: Extension of the mash screen file. Do not alter this field unless doing pipeline development.
    - output_reads_ext: Extension of mash outputs when run on reads. Do not alter this field unless doing pipeline development.
    - output_taxa_ext: Extension of mash output when run on contigs. Do not alter this field unless doing pipeline development.
    - mash_sketch: The GTDB sketch used by the pipeline, this sketch is special as it contains the taxonomic paths in the classification step of the pipeline. It can as of 2023-10-05 be found here: https://zenodo.org/record/8408361
    - sketch_ext: File extension of a mash sketch. Do not alter this field unless doing pipeline development.
    - json_ext: File extension of json data output by Mash. Do not alter this field unless doing pipeline development.
    - sketch_kmer_size: The size of the kmers used in the sketching in genome size estimation.
    - **min_kmer**: The minimum number of kmer copies required to pass the noise filter. this value is used in estimation of genome size from reads. The default value is 10 as it seems to work well for Illumina data.
    - final_sketch_name: **to be removed** This parameter was originally part of a subworkflow included in the pipeline for generation of the GTDB sketch. But this has been removed and replaced with scripting.
    - report_tag: Report tag for Mash in the summary report. Do not alter this field unless doing pipeline development.
    - header_p: Tells the pipeline if the output data contains headers. Do not alter this field unless doing pipeline development.
    - headers: A list of the headers the output of mash should contain. Do not alter this field unless doing pipeline development.

### Mash Meta
This process is used to determine if a sample is metagenomic or not.

- mash_meta.
    - report_tag: The name of this output field in the summary report.  Do not alter this field unless doing pipeline development.

### top_hit_species:
As Kraken2 of Mash can be used for determining the species present in the pipeline, the share a common report tag.

- top_hig_species
    - report_tag: The name of the determined species in the final report. Do not alter this field unless doing pipeline development.

### Contamination Removal
This step is used to remove contaminants from read data, it exists to perform dehosting, and removal of kitomes.

- r_contaminants
    - singularity: Singularity container used to perform dehosting, this container contains minimap2 and samtools.
    - docker: Docker container used to perform dehosting, this container contains minimap2 and samtools.
    - phix_fa: The path to file containing the phiX fasta.
    - homo_sapiens_fa: The path to file containing the human genomes fasta.
    - pacbio_mg: The path to file containg the pacbio sequencing control.
    - output_ext: The extension of the deconned fastq files. Do not alter this field unless doing pipeline development.
    - mega_mm2_idx: The path to the minimap2 index used for dehosting. Do not alter this field unless doing pipeline development.
    - mm2_illumina: The arguments passed to minimap2 for Illumina data. Do not alter this field unless doing pipeline development.
    - mm2_pac: The arguments passed to minimap2 for Pacbio Data. Do not alter this field unless doing pipeline development.
    - mm2_ont: The arguments passed to minimap2 for Nanopore data. Do not alter this field unless doing pipeline development.
    - samtools_output_ext: The extension of the output from samtools. Do not alter this field unless doing pipeline development.
    - samtools_singletons_ext: The extension of singelton reads from samtools.  Do not alter this field unless doing pipeline development.
    - output_ext: The name of the files output from samtools. Do not alter this field unless doing pipeline development.
    - output_dir: The directory where deconned reads are placed. Do not alter this field unless doing pipeline development.

### Minimap2
Minimap2 is used frequently throughout the pipeline for decontamination and mapping reads back to assemblies for polishing.

- minimap2
    - singularity: The singularity container for minimap2, the same one is used for contmaination removal.
    - docker: The Docker container for minimap2, the same one is used for contmaination removal.
    - index_outdir: The directory where created indices are output. Do not alter this field unless doing pipeline development.
    - index_ext: The file extension of create indices. Do not alter this field unless doing pipeline development.

### Samtools
Samtools is used for sam to bam conversion in the pipeline.

- samtools
    - singularity: The Singularity container containing samtools, the same container is used as the one in contamination removal.
    - docker: The Docker container containing samtools, the same container is used as the on in contamination removal.
    - bam_ext: The extension of the bam file from samtools. Do not alter this field unless doing pipeline development.
    - bai_ext: the extension of the bam index from samtools. Do not alter this field unless doing pipeline development.

### Racon
Racon is used as a first pass for polishing assemblies.

- racon
    - singularity: The Singularity container containing racon.
    - docker: The Docker container containing racon.
    - consensus_suffix: The suffix for racons outputs.  Do not alter this field unless doing pipeline development.
    - consensus_ext: The file extension for the racon consensus sequence. Do not alter this field unless doing pipeline development.
    - outdir: The directory containing the polished sequences.  Do not alter this field unless doing pipeline development.

### Pilon
Pilon was added to the pipeline, but it is run iteratively which at the time of writing this pipeline was not well supported in Nextflow so a seperate script and containers are provided to utilize Pilon. The code for Pilon remains in the pipeline so that when able to do so easily, iterative Pilon polishing can be integrated directly into the pipeline.

### Pilon Iterative Polishing
This process is a wrapper around minimap2, samtools and Pilon for iterative polishing containers are built **but if you ever have problems with this step, disabling polishing will fix your issue (at the cost of polishing)**.

- pilon_iterative
    - singularity: The container containing the iterative pilon program. If you ever have issues with the singularity image you can use the Docker image as Nextflow will automatically convert the docker image into a singularity image.
    - docker: The Docker container for the Pilon iterative polisher.
    - outdir: The directory where polished data is output. Do not alter this field unless doing pipeline development.
    - fasta_ext: File extension for the fasta to be polished. Do not alter this field unless doing pipeline development.
    - fasta_outdir: The output directory name for the polished fastas. Do not alter this field unless doing pipeline development.
    - vcf_ext: File extension for the VCF output by Pilon. Do not alter this field unless doing pipeline development.
    - vcf_outdir: output directory containing the VCF files from Pilon. Do not alter this field unless doing pipeline development.
    - bam_ext: Bam file extension.  Do not alter this field unless doing pipeline development.
    - bai_ext: Bam index file extension. Do not alter this field unless doing pipeline development.
    - changes_ext: File extensions for the pilon output containing the changes applied to the assembly. Do not alter this field unless doing pipeline development.
    - changes_outdir: The output directory for the pilon changes.  Do not alter this field unless doing pipeline development.
    - max_memory_multiplier: On failure this program will try again with more memory, the mulitplier is the factor that the amount of memory passed to the program will be increased by. Do not alter this field unless doing pipeline development.
    - **max_polishing_illumina**: Number of iterations for polishing an illuina assembly with illumina reads.
    - **max_polishing_nanopre**: Number of iterations to polish a Nanopore assembly with (will use illumina reads if provided).
    - **max_polishing_pacbio**: Number iterations to polish assembly with (will use illumina reads if provided).

### Medaka Polishing
Medaka is used for polishing of Nanopore assemblies, make sure you specify a medaka model when using the pipeline so the correct settings are applied. If you have issues with Medaka running, try disabling resume or alternatively **disable polishing** as Medaka can be troublesome to run.

- medaka
    - singularity: Singularity container with Medaka.
    - docker: Docker container with Medaka.
    - model: This parameter will be autofilled with the model specified at the top level by the `nanopore_chemistry` option. Do not alter this field unless doing pipeline development.
    - fasta_ext: Polished fasta output. Do not alter this field unless doing pipeline development.
    - batch_size: The batch size passed to medaka, this can improve performance. Do not alter this field unless doing pipeline development.

### Unicycler
Unicycler is an option provided for hybrid assembly, it is a great option and outputs an excellent assembly but it requires **alot** of resources. Which is why the alternate hybrid assembly option using Flye->Racon->Pilon is available. As well there can be a fairly cryptic Spades error generated by Unicycler that usaully relates to memory usage, It will typically say something involving `tputs`.

- unicycler
    - singularity: The Singularity container containing Unicycler.
    - docker: The Docker container containing Unicycler.
    - scaffolds_ext: The scaffolds file extension output by unicycler. Do not alter this field unless doing pipeline development.
    - assembly_ext: The assembly extension output by Unicycler. Do not alter this field unless doing pipeline development.
    - log_ext: The log file output by Unicycler. Do not alter this field unless doing pipeline development.
    - outdir: The output directory the Unicycler data is sent to. Do not alter this field unless doing pipeline development.
    - mem_modifier: Specifies a high amount of memory for Unicycler to prevent a common spades error that is fairly cryptic. Do not alter this field unless doing pipeline development.
    - threads_increase_factor: Factor to increase the number of threads passed to Unicycler. Do not alter this field unless doing pipeline development.


### Bakta
Bakta is use to provide annotation of genomes, it is very reliable but it can be slow.

- bakta
    - singularity: The singularity container containing Bakta.
    - docker: The Docker container containing Bakta.
    - db_type: The database option to download, current options are `light` or `full`
    - **db**: the path where the downloaded Bakta database should be downloaded.
    - output_dir: The name of the folder where Bakta data is saved too. Do not alter this field unless doing pipeline development.
    - embl_ext: File extension of embl file. Do not alter this field unless doing pipeline development.
    - faa_ext: File extension of faa file. Do not alter this field unless doing pipeline development.
    - ffn_ext: File extension of the ffn file. Do not alter this field unless doing pipeline development.
    - fna_ext: File extension of the fna file. Do not alter this field unless doing pipeline development.
    - gbff_ext: File extension of gbff file. Do not alter this field unless doing pipeline development.
    - gff_ext: File extension of GFF file. Do not alter this field unless doing pipeline development.
    - threads: Number of threads for Bakta to use, remember more is not always better. Do not alter this field unless doing pipeline development.
    - hypotheticals_tsv_ext: File extension for hypothetical genes. Do not alter this field unless doing pipeline development.
    - hypotheticals_faa_ext: File extension of hypothetical genes fasta. Do not alter this field unless doing pipeline development.
    - tsv_ext: The file extension of the final bakta tsv report. Do not alter this field unless doing pipeline development.
    - txt_ext: The file extension of the txt report. Do not alter this field unless doing pipeline development.
    - min_contig_length: The minimum contig length to be annotated by Bakta.

### Bandage
Bandage is included to make bandage plots of the initial assemblies e.g. Spades, Flye or Unicycler. These images can be useful in determining the quality of an assembly.

- bandage
    - singularity: The path to the singularity image containing bandage.
    - docker: The path to the docker file containing bandage.
    - svg_ext: The extension of the SVG file created by bandage. Do not alter this field unless doing pipeline development.
    - outdir: The output directory of the bandage images.

### Subtyping Report
All sub typing report tools contain a common report tag so that they can be identified by the program.

- subtyping_report
    - report_tag: Subtyping report name. Do not alter this field unless doing pipeline development.

### ECTyper
ECTyper is used to perform *in-silico* typing of *Escherichia coli* and is automatically triggered by the pipeline.

- ectyper
    - singularity: The path to the singularity container containing ECTyper.
    - docker: The path to the Docker container containing ECTyper.
    - log_ext: File extension of the ECTyper log file. Do not alter this field unless doing pipeline development.
    - tsv_ext: File extension of the ECTyper text file. Do not alter this field unless doing pipeline development.
    - txt_ext: Text file extension of ECTyper output. Do not alter this field unless doing pipeline development.
    - report_tag: Report tag for ECTyper data. Do not alter this field unless doing pipeline development.
    - header_p: denotes if the table output from ECTyper contains a header. Do not alter this field unless doing pipeline development.

### Kleborate
Kleborate performs automatic typing of *Kelbsiella*.

- kleborate
    - singularity: The path to the singularity container containing Kleborate.
    - docker: The path to the docker container containing Kleborate.
    - txt_ext: The subtyping report tag for Kleborate. Do not alter this field unless doing pipeline development.
    - report_tag: The report tag for Kleborate. Do not alter this field unless doing pipeline development.
    - header_p: Denotes the Kleborate table contains a header. Do not alter this field unless doing pipeline development.

### Spatyper
Performa typing of *Staphylococcus* species.

- spatyper
    - singularity: The path to the singularity container containing Spatyper.
    - docker: The path to docker container containing Spatyper.
    - tsv_ext: The file extension of the Spatyper output. Do not alter this field unless doing pipeline development.
    - report_tag: The report tag for Spatyper. Do not alter this field unless doing pipeline development.
    - header_p: denotes whether or not the output table contains a header. Do not alter this field unless doing pipeline development.
    - repeats: An optional file specifying repeats can be passed to Spatyper.
    - repeat_order: An optional file containing a repeat ordet to pass to Spatyper.

### SISTR
*In-silico Salmonella* serotype prediction.

- sistr
    - singularity: The path to the singularity container containing SISTR.
    - docker: The path to the Docker container containing SISTR.
    - tsv_ext: The file extension of the SISTR output. Do not alter this field unless doing pipeline development.
    - allele_fasta_ext: The extension of the alleles identified by SISTR. Do not alter this field unless doing pipeline development.
    - allele_json_ext: The extension to the output JSON file from SISTR. Do not alter this field unless doing pipeline development.
    - cgmlst_tag: The extension of the CGMLST file from SISTR. Do not alter this field unless doing pipeline development.
    - report_tag: The report tag for SISTR. Do not alter this field unless doing pipeline development.
    - header_p: Denotes whether or not the output table contains a header. Do not alter this field unless doing pipeline development.

### Lissero
*in-silico Listeria* typing.

- lissero
    - singularity: The path to the singularity container containing Lissero.
    - docker: The path to the docker container containing Lissero.
    - tsv_ext: The file extension of the Lissero output. Do not alter this field unless doing pipeline development.
    - report_tag: The report tag for Lissero. Do not alter this field unless doing pipeline development.
    - header_p: Denotes if the output table of Lissero contains a header. Do not alter this field unless doing pipeline development.

### Shigeifinder
Shigeifinder was added then removed. The code still remains but it will removed at a later date.

### Shigatyper
*in-silico Shigella* typing. **NOTE:** It is unlikely this subtyper will be triggered as GTDB has merged *E.coli* and *Shigella* and updated sketch and updated ECTyper will be released soon to address the shortfalls of this sketch.

- shigatyper
    - singularity: The Singularity container containing Shigatyper.
    - docker: The path to the Docker container containing Shigatyper.
    - tsv_ext: The tsv file extension. Do not alter this field unless doing pipeline development.
    - report_tag: The report tag for Shigatyper. Do not alter this field unless doing pipeline development.
    - header_p: Denotes if the report output contains a header. Do not alter this field unless doing pipeline development.

### Kraken2 Contig Binning
Bins contigs based on the Kraken2 output for contaminated/metagenomic samples. This is implemeted by using a custom script.

- kraken_bin
    - **taxonomic_level**: The taxonomic level to bin contigs at. Binning at species level is not recommended the default is to bin at a genus level which is specied by a character of `G`. To bin at a higher level such as family you would specify `F`.
    - fasta_ext: The extension of the fasta files output. Do not alter this field unless doing pipeline development.


## Quality Control Report
Tread carefully here, as this will require modification of the `nextflow.config` file. **Make sure you have saved a back up of your `nextflow.config` file before playing with these option**

#### After you have backed up you `nextflow.config` please proceed

### QCReport field desciption
The section of interest is the `QCReport` fields in the params section of the `nextflow.config`. There are multiple sections with values that can be modified or you can add data for a different organism. The default values in the pipeline are set up for **Illumina data** so you may need to adjust setting for Nanopore or Pacbio data.

An example of the QCReport structure is shown below. With annotation describing the values. **NOTE** The values below do not affect the running of the pipeline, these values only affect the final quality messages output by the pipeline.
```
QCReport {
    escherichia // Generic top level name fo the field, it is name is technically arbitrary but it nice field name keeps things organized
    {
        search = "Escherichia coli" // The phrase that is searched for in the species_top_hit field mentioned above. The search is for containment so if you wanted to look for E.coli and E.albertii you could just set the value too "Escherichia"
        raw_average_quality = 30 // Minimum raw average quality of all bases in the sequencing data. This value is generated before the decontamination procedure.
        min_n50 = 95000 // The minimum n50 value allowed from quast
        max_n50 = 6000000 // The maximum n50 value allowed from quast
        min_nr_contigs = 1 // the minimum number of contigs a sample is allowed to have, a value of 1 works as a sanity check
        max_nr_contigs = 500 // The maximum number of contigs the organism in the search field is allowed to have. to many contigs could indicate a bad assembly or contamination
        min_length = 4500000 // The minimum genome length allowed for the organism specified in the search field
        max_length = 6000000 // The maxmimum genome length the organism in the search field is allowed to have
        max_checkm_contamination = 3.0 // The maximum level of allowed contamination allowed by CheckM
        min_average_coverage = 30 // The minimum average coverage allowed
    }
    // DO NOT REMOVE THE FALLTRHOUGH FIELD AS IT IS NEEDED TO CAPTURE OTHER ORGANISMS
    fallthrough // The fallthrough field exist as a default value to capture organisms where no quality control data has been specified
    {
        search = "No organism specific QC data available."
        raw_average_quality = 30
        min_n50 = null
        max_n50 = null
        min_nr_contigs = null
        max_nr_contigs = null
        min_length = null
        max_length = null
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
}
```

### Example adding quality control data for *Salmonella*

If you wanted to add quality control data for *Salmonella* you can start off by using the template below:

```
VAR_NAME { // Replace VAR name with the genus name of your sample, only use ASCII (a-zA-Z) alphabet characters in the name and replace spaces, punctuation and other special characters with underscores (_)
    search = "Search phrase" // Search phrase for your species top_hit, Note the quotes
    raw_average_quality = // 30 is a default value please change it as needed
    min_n50 = // Set your minimum n50 value
    max_n50 = // Set a maximum n50 value
    min_nr_contigs = // Set a minimum number of contigs
    max_nr_contigs = // The maximum number of contings
    min_length = // Set a minimum genome length
    max_length = // set a maximum genome length
    max_checkm_contamination = // Set a maximum level of contamination to use
    min_average_coverage = // Set the minimum coverage value
}
```

For *Salmonella* I would fill in the values like so.
```
salmonella {
    search = "Salmonella"
    raw_average_quality = 30
    min_n50 = 95000
    max_n50 = 6000000
    min_nr_contigs = 1
    max_nr_contigs = 200
    min_length = 4400000
    max_length = 6000000
    max_checkm_contamination = 3.0
    min_average_coverage = 30
}
```


After having my values filled out, I can simply add them to the QCReport section in the `nextflow.config` file.

```
    QCReport {
        escherichia {
            search = "Escherichia coli"
            raw_average_quality = 30
            min_n50 = 95000
            max_n50 = 6000000
            min_nr_contigs = 1
            max_nr_contigs = 500
            min_length = 4500000
            max_length = 6000000
            max_checkm_contamination = 3.0
            min_average_coverage = 30
        } salmonella { // NOTE watch the opening and closing brackets
            search = "Salmonella"
            raw_average_quality = 30
            min_n50 = 95000
            max_n50 = 6000000
            min_nr_contigs = 1
            max_nr_contigs = 200
            min_length = 4400000
            max_length = 6000000
            max_checkm_contamination = 3.0
            min_average_coverage = 30
        }
        fallthrough {
            search = "No organism specific QC data available."
            raw_average_quality = 30
            min_n50 = null
            max_n50 = null
            min_nr_contigs = null
            max_nr_contigs = null
            min_length = null
            max_length = null
            max_checkm_contamination = 3.0
            min_average_coverage = 30
        }
    }
```

### The current default settings are listed below
```
QCReport {
    escherichia {
        search = "Escherichia coli"
        raw_average_quality = 30
        min_n50 = 95000
        max_n50 = 6000000
        min_nr_contigs = 1
        max_nr_contigs = 500
        min_length = 4500000
        max_length = 6000000
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
    salmonella {
        search = "Salmonella"
        raw_average_quality = 30
        min_n50 = 95000
        max_n50 = 6000000
        min_nr_contigs = 1
        max_nr_contigs = 200
        min_length = 4400000
        max_length = 6000000
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
    shigella {
        search = "Shigella"
        raw_average_quality = 30
        min_n50 = 17500
        max_n50 =  5000000
        min_nr_contigs = 1
        max_nr_contigs = 500
        min_length = 4300000
        max_length = 5000000
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
    listeria {
        search = "Listeria"
        raw_average_quality = 30
        min_n50 = 45000
        max_n50 = 3200000
        min_nr_contigs = 1
        max_nr_contigs = 200
        min_length = 2700000
        max_length = 3200000
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
    campylobacter {
        search = "Campylobacter"
        raw_average_quality = 30
        min_n50 = 9500
        max_n50 = 2000000
        min_nr_contigs = 1
        max_nr_contigs = 150
        min_length = 1400000
        max_length = 2000000
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
    vibrio {
        search = "Vibrio"
        raw_average_quality = 30
        min_n50 = 95000
        max_n50 = 4300000
        min_nr_contigs = 1
        max_nr_contigs = 150
        min_length = 3800000
        max_length = 4300000
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
    // Some of these defaults are made up
    klebsiella {
        search = "Klebsiella"
        raw_average_quality = 30
        min_n50 = 100000
        max_n50 = 6000000
        min_nr_contigs = 1
        max_nr_contigs = 500
        min_length = 4500000
        max_length = 6000000
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
    staphylococcus {
        search = "Staphylococcus"
        raw_average_quality = 30
        min_n50 = 100000
        max_n50 = 3500000
        min_nr_contigs = 1
        max_nr_contigs = 550
        min_length = 2000000
        max_length = 3500000
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
    fallthrough {
        search = "No organism specific QC data available."
        raw_average_quality = 30
        min_n50 = null
        max_n50 = null
        min_nr_contigs = null
        max_nr_contigs = null
        min_length = null
        max_length = null
        max_checkm_contamination = 3.0
        min_average_coverage = 30
    }
}
```


## Quality Control Fields
This section affects the behaviours of the final summary quality control messages and is noted in the `QCReportFields` within the `nextflow.config`. **I would advise against manipulating this section unless you really know what you are doing**.

TODO test what happens if no quality msg is available for the bool fields types.

Each value in the QC report fields contains the following fields.

- Field name
    - path: path to the information in the summary report JSON
    - coerce_type: Type to be coreced too, can be a Float, Integer, or Bool
    - compare_fields: A list of fields corresponding to fields in the `QCReport` section of the `nextflow.config`. If two values are specified it will be assumed you wish to check that a value is in between a range of values.
    - comp_type: The comparison type specified, 'ge' for greater or equal, 'le' for less than or equal, 'bool' for true or false or 'range' for checking if a value is between two values.
    - on: A boolean value for disabling a comparison
    - low_msg: A message for if a value is less than its compared value (optional)
    - high_msg: A message for if value is above a certain value (optional)

An example of what these fields look like is:

```
QCReportFields {
    raw_average_quality {
        path = [params.raw_reads.report_tag, "combined", "qual_mean"]
        coerce_type = 'Float'
        compare_fields = ['raw_average_quality']
        comp_type = "ge"
        on = true
        low_msg = "Base quality is poor, resequencing is recommended."
    }
}
```

