# Running MikroKondo

## Usage

MikroKondo can be run like most other nextflow pipelines. The most basic usage is as follows:
`nextflow run main.nf --input PATH_TO_SAMPLE_SHEET --outdir OUTPUT_DIR --platform SEQUENCING_PLATFORM  -profile CONTAINER_TYPE`

Many parameters can be altered or accessed from the command line. For a full list of parameters to be altered please refer to the `nextflow.config` file in the repo.

## Input

This pipeline requires the following as input:

### Sample files (gzip)
This pipeline requires sample files to be gzipped (symlinks may be problematic).

### Samplesheet (CSV)
Mikrokondo requires a sample sheet to be run. This FOFN (file of file names) contains the samples names and allows a user to combine read-sets based on that name if provided. The sample-sheet can utilize the following header fields:

- sample
- fastq_1
- fastq_2
- long_reads
- assembly


Example layouts for different sample-sheets include:

_Illumina paired-end data_

|sample|fastq_1|fastq_2|
|------|-------|-------|
|sample_name|path_to_forward_reads|path_to_reversed_reads|

_Nanopore_

|sample|long_reads|
|------|----------|
|sample_name|path_to_reads|

_Hybrid Assembly_

|sample|fastq_1|fastq_2|long_reads|
|-------|-------|------|----------|
|sample_name|path_to_forward_reads|path_to_reversed_reads|path_to_long_reads|

_Starting with assembly only_

|sample|assembly|
|------|--------|
|sample_name|path_to_assembly|

_Example merging paired-end data_

|sample|fastq_1|fastq_2|
|------|-------|-------|
|my_sample|path_to_forward_reads_1|path_to_reversed_reads_1|
|my_sample|path_to_forward_reads_2|path_to_reversed_reads_2|

*The value of `my_sample` is repeated twice allowing sample to be merged on the common key. This works for nanopore data, hybrid assembly data and assemblies*

## Command line arguments

> **Note:** All the below settings can be permanently changed in the `nextflow.config` file within the `params` section. For example, to permanently set a nanopore chemistry and use Kraken for speciation:
```
--run_kraken = true // Note the lack of quotes
--nanopore_chemistry "r1041_e82_400bps_hac_v4.2.0" // Note the quotes used here
```

#### Nf-core boiler plate options

- `--publish_dir_mode`: Method used to save pipeline results to output directory
- `--email`: Email address for completion summary.
- `--email_on_fail`: An email address to send a summary email to when the pipeline is completed - ONLY sent if the pipeline does not exit successfully.
- `--plaintext_email`: Send plain-text email instead of HTML.
- `--monochrome_logs`: Do not use coloured log outputs.
- `--hook_url`: Incoming hook URL for messaging service. Currently, MS Teams and Slack are supported.
- `--help`: Display help text.
- `--version`: Display version and exit.
- `--validate_params`: Boolean whether to validate parameters against the schema at runtime.
- `--show_hidden_params`: By default, parameters set as _hidden_ in the schema are not shown on the command line when a user runs with `--help`. Specifying this option will tell the pipeline to show all parameters.

#### General tool options
- `--fly_read_type VALUE`: Flye allows for different assembly options. The default value is set too `hq` (High quality for Nanopore reads, and HiFi for bacterial reads). User options include `hq`, `corr` and `raw`, and a default value can be specified in the `nextflow.config` file.
- `--hybrid_unicycler true`: to use unicycler for assembly instead of Flye->Racon>Pilon.
    >**Note:** You may need to check the `conf/base.config` `process_high_memory` declaration and provide it upwards of 1000GB of memory if you get errors mentioning `tputs`. This error is not very clear sadly but increasing resources available to the process will help.
- `--metagenomic_run true`: users can specify samples are metagenomic via this flag, the pipeline will skip running the contamination mash check and proceed with metagenomic assembly.
- `--min_reads NUM`: refers to the minimum number of reads required after the fastP step to progress a set of sample reads to assembly (default: 1000).
- `--nanopore_chemistry YOUR_MODEL_HERE`: a Medaka model must be specified for polishing. A list of allowed models can be found here: [Medaka models python script](https://github.com/nanoporetech/medaka/blob/master/medaka/options.py) or [Medaka models available for download](https://github.com/nanoporetech/medaka/tree/master/medaka/data)
- `--run_kraken TRUE`: can be used to enable Kraken2 for speciation instead of Mash.
- `--target_depth`: refers to the target bp depth for a set of reads. When sample read sets have an estimated depth higher than this target, it is downsampled to achieve the depth. No downsampling occurs when estimated depth is lower than this value (default 100).


#### Skip Options

Numerous steps within mikrokondo can be turned off without compromising the stability of the pipeline. This skip options can reduce run-time of the pipeline or allow for completion of the pipeline despite errors.
** All of the above options can be turned on by entering `--{skip_option} true` in the command line arguments to the pipeline (where optional parameters can be added)**

- `--skip_abricate`: turn off abricate AMR detection
- `--skip_bakta`: turn off bakta annotation pipeline (generally a slow step, requiring a database to be specified).
- `--skip_checkm`: used as part of the contamination detection within mikrokondo, its run time and resource usage can be quite lengthy.
- `--skip_depth_sampling`: genome size of reads is estimated using mash and reads can be down-sampled to target depth in order to have a better assembly, if this is of no interest to you, this flag will skip this step entirely. **If you have specified that your run is metagenomic, down sampling is turned off.**
- `--skip_mobrecon`: turn off mob-suite recon.
- `--skip_ont_header_cleaning`: Nanopore data may fail in the pipeline due to duplicate headers, while rare it can cause assemblies to fail. Unlike the other options on this list, skipping header cleaning is defaulted to TRUE.
- `--skip_polishing`: if running a metagenomic assembly or encountering issues with polishing steps, this flag will disable polishing and retrieve assembly directly from Spades/Fly. **this does not apply to hybrid assemblies.**
- `--skip_report`: prevents the generation of the final summary report.
- `--skip_species_classification`: prevents Mash or Kraken2 being run on assembled genome, also **prevents subtyping workflow from triggering.**
- `--skip_starmar`: turn off starAMR AMR detection.
- `--skip_subtyping`: to turn off automatic triggering of subtyping in the pipeline (useful when target organism does not have a subtyping tool installed within mikrokondo).
- `--skip_version_gathering`: prevents the collation of tool versions. This process generally takes a couple minutes (at worst) but can be useful when during recurrent runs of the pipeline (like when testing settings).
- `--skip_report`: Prevents creation of final report summary report amalgamating outputs of all other files, this will also turnoff the creation of individual sub-reports.
- `--skip_metagenomic_detection`: Skips classification of sample as metagnomic and forces a sample to be analyzed as an isolate.
- `--skip_raw_read_metrics`: Prevents generation of raw read metrics, e.g. metrics generated about the reads before any trimming or filtering is performed.
- `--skip_mlst`: Skip seven gene MLST.

#### Datasets
Different databases/pre-computed files are required for usage within mikrokondo. These can be downloaded or created by the user, and if not configured within the `nextflow.config` file they can be passed in as files with the following command-line arguments.

- `--dehosting_idx`: The minimap2 index to be used for dehosting.
- `--mash_sketch`: The mash sketch to be used for contamination detection and speciation.
- `--bakta_db`: Bakta database for genome annotation.
- `--kraken2_db`: Kraken2 database that can be used for speciation and binning of meta-genomically assembled contigs.
- `--staramr_db`: An optional StarAMR database to be passed in, it is recommended to use the database packaged in the container.

#### FastP Arguments
For simplicity parameters affecting FastP have been moved to the top level. Each argument matches one listed within the [FastP](https://phac-nml.github.io/mikrokondo/usage/tool_params/#fastp) usage section with only a `fp_` being appended to the front of the argument. For a more detailed description of what each argument does please review the tool specific parameters for [FastP](https://phac-nml.github.io/mikrokondo/usage/tool_params/#fastp) here.

- `--fp_average_quality`: If a read/read-pair quality is less than this value it is discarded
- `--fp_cut_tail_mean_quality`: the quality threshold to trim reads to
- `--fp_cut_tail_window_size`: The window size to cut a tail with.
- `--fp_complexity_threshold`: The threshold for low complexity filter.
- `--fp_qualified_phred`: The quality of a base to be qualified if filtering by unqualified bases.
- `--fp_unqualified_percent_limit`: The percent amount of bases that are allowed to be unqualified in a read.
- `--fp_polyg_min_len`: The minimum length to detect a polyG tail.
- `--fp_polyx_min_len`: The minimum length to detect a polyX tail.
- `--fp_illumina_length_min`: The minimum read length to be allowed in illumina data.
- `--fp_illumina_length_max`: The maximum read length allowed for illumina data.
- `--fp_single_end_length_min`: the minimum read length allowed in Pacbio or Nanopore data.
- `--fp_dedup_reads`: A parameter to be turned on to allow for deduplication of reads.

#### Bakta Parameters
Top level parameters that can be passed to Bakta.

- `--ba_min_contig_length`: Minimum contig length to be analyzed by Bakta

#### Quast Parameters
Top level parameters that can be passed to Quast.

- `--qt_min_contig_length`: Minimum length of a contig to be analyzed within Quast.

#### Mash parameters
Top level parameters to be passed to Mash.

- `--mh_min_kmer`: The minimum time a kmer needs to appear to be used in genome size estimation by mash.


#### Containers

Different container services can be specified from the command line when running mikrokondo in the `-profile` option. This option is specified at the end of your command line argument. Examples of different container services are specified below:

- For Docker: `nextflow run main.nf MY_OPTIONS -profile docker`
- For Singularity: `nextflow run main.nf MY_OPTIONS -profile singularity`
- For Apptainer: `nextflow run main.nf MY_OPTIONS -profile apptainer`
- For Shifter: `nextflow run main.nf MY_OPTIONS -profile shifter`
- For Charliecloud: `nextflow run main.nf MY_OPTIONS -profile charliecloud`
- For Gitpod: `nextflow run main.nf MY_OPTIONS -profile gitpod`
- For Podman: `nextflow run main.nf MY_OPTIONS -profile podman`

#### Platform specification

- `--platform illumina` for Illumina.
- `--platform nanopore` for Nanopore.
- `--platform pacbio` for Pacbio
- `--platform hybrid` for hybrid assemblies.
   > **Note:** when denoting your run as using a hybrid platform, you must also add in the long_read_opt parameter as the default value is nanopore**. `--long_read_opt nanopore` for nanopore or `--long_read_opt pacbio` for pacbio.

#### Slurm options

- `slurm_p true`: slurm execurtor will be used.
- `slurm_profile STRING`: a string to allow the user to specify which slurm partition to use.

## Output

All output files will be written into the `outdir` (specified by the user). More explicit tool results can be found in both the [Workflow](/workflows/CleanAssemble/) and [Subworkflow](/subworkflows/assemble_reads/) sections of the docs. Here is a brief description of the outdir structure:

- **annotations** - dir containing all annotation tool output.
- **assembly** - dir containing all assembly tool related output, including quality, 7 gene MLST and taxon determination.
- **pipeline_info** - dir containing all pipeline related information including software versions used and execution reports.
- **ReadQuality** - dir containing all read tool related output, including contamination, fastq, mash, and subsampled read sets (when present)
- **subtyping** - dir containing all subtyping tool related output, including SISTR, ECtyper, etc.
- **SummaryReport** - dir containing collated results files for all tools, including:
   - Individual sample flattened json reports
   - **final_report** - All tool results for all samples in both .json (including a flattened version) and .tsv format
- **bco.json** - data providence file generated from the nf-prov plug-in
- **manifest.json** - data providence file generated from the nf-prov plug-in
