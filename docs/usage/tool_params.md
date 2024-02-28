# Tool Specific Parameters
To access tool specific parameters from the command line you must use the dot operator. For organization and readability sake, the below documentation is nested to indicate where the dot operator is used. For example:
```
- quast
    - min_contig_length NUM
```
Translates to `--quast.min_contig_length NUM` on the CLI.

>**Note:** Easily changed parameters are bolded. Sensible defaults are provided.

### Abricate
Screens contigs for antimicrobial and virulence genes. If you wish to use a different Abricate database you may need to update the container you use.

- abricate
    - singularity: Abricate singularity container
    - docker: Abricate docker container
    - **args**: Can be a string of additional command line arguments to pass to abricate
    - report_tag: determines the name of the Abricate output in the final summary file. **Do no touch this unless doing pipeline development.**
    - header_p: This field tells the report module that the Abricate output contains headers. **Do no touch this unless doing pipeline development.**

### Raw Read Metrics 
A custom Python script that gathers quality metrics for each fastq file.

- raw_reads
    - high_precision: When set to true, floating point precision of values output are accurate down to very small decimal places. Recommended to leave this setting as false (use the standard floats), it is much faster and having such precise decimal places is not needed for this module.
    - report_tag: this field determines the name of the Raw Read Metric field in the final summary report. **Do no touch this unless doing pipeline development.**

### Coreutils
In cases where a process uses bash scripting only, Nextflow by default will utilize system binaries when they are available and no container is specified. For reproducability, we have chosen to use containers in such cases. When a better container is available, you can direct the pipeline to use it via below commands:

- coreutils
    - singularity: coreutils singularity container
    - docker: coreutils docker container


### Python
Some scripts require Python3, therefore a well tested Python3 container is provided for reproducability. However, as all the scripts within mikrokondo use only the standard library you can swap these containers to use any python interpreter version. For instance, swapping in **pypy3** may result a massive performance boost from the scripts, though this is currently untested.

- python3
    - singularity: Python3 singularity container
    - docker: Python3 docker container

### KAT
Kat was previously used to estimate genome size, however at the time of writing KAT appears to be only infrequently updated and newer versions would have issues running/sometimes giving an incorrect output due to failures in peak recognition. Therefore, KAT has been removed from the pipeline, It's code still remains but it **will be removed in the future**.

### Seqtk
Seqtk is used for both the sub-sampling of reads and conversion of fasta files to fastq files in mikrokondo. The usage of seqtk to convert a fasta to a fastq is needed in certain typing tools requiring reads as input (this was a design decision for generalizability of the pipeline).

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
Chopper was originally used for trimming of Nanopore reads, but FastP was able to do the same work so Chopper is no longer used. Its code currently remains but it cannot be run in the pipeline.

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
Usef for paired end read assembly

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
Unicycler is an option provided for hybrid assembly, it is a great option and outputs an excellent assembly but it requires **A lot** of resources. Which is why the alternate hybrid assembly option using Flye->Racon->Pilon is available. As well there can be a fairly cryptic Spades error generated by Unicycler that usaully relates to memory usage, it will typically say something involving `tputs`.

- unicycler
    - singularity: The Singularity container containing Unicycler.
    - docker: The Docker container containing Unicycler.
    - scaffolds_ext: The scaffolds file extension output by unicycler. Do not alter this field unless doing pipeline development.
    - assembly_ext: The assembly extension output by Unicycler. Do not alter this field unless doing pipeline development.
    - log_ext: The log file output by Unicycler. Do not alter this field unless doing pipeline development.
    - outdir: The output directory the Unicycler data is sent to. Do not alter this field unless doing pipeline development.
    - mem_modifier: Specifies a high amount of memory for Unicycler to prevent a common spades error that is fairly cryptic. Do not alter this field unless doing pipeline development.
    - threads_increase_factor: Factor to increase the number of threads passed to Unicycler. Do not alter this field unless doing pipeline development.


### Mob-suite Recon
mob-suite recon provides annotation of plasmids in the assembly data.

- mobsuite_recon
    - singularity: The singularity container containing mob-suite recon.
    - docker: The Docker container containing mob-suite recon.
    - **args**: Additional arguments to pass to mobsuite.
    - fasta_ext: The file extension for FASTAs. Do not alter this field unless doing pipeline development.
    - results_ext: The file extension for results in mob-suite. Do not alter this field unless doing pipeline development.
    - mob_results_file: The final results to be included in the final report by mob-suite. Do not alter this field unless doing pipeline development.
    - report_tag: The field name of mob-suite data in the final report. Do not alter this field unless doing pipeline development.
    - header_p: Default is `true` and indicates that the results output by mob-suite contains a header. Do not alter this field unless doing pipeline development.

## StarAMR
StarAMR provides annotation of antimicrobial resistance genes within your data. The process will alter FASTA headers of input files to ensure the header length <50 characters long.

- staramr
    - singularity: The singularity container containing staramr.
    - docker: The Docker container containing starmar.
    - **db**: The database for StarAMR. The default value of `null` tells the pipeline to use the database included in the StarAMR container. However you can specify a path to a valid StarAMR datbase and use that instead.
    - tsv_ext: File extension of the reports from StarAMR. Do not alter this field unless doing pipeline development.
    - txt_ext: File extension of the text reports from StarAMR. Do not alter this field unless doing pipeline development.
    - xlsx_ext: File extension of the excel spread sheet from StarAMR. Do not alter this field unless doing pipeline development.
    - **args**: Additional arguments to pass to StarAMR. Do not alter this field unless doing pipeline development.
    - point_finder_dbs: A list containing the valid databases StarAMR supports for pointfinder. The way they are structured matches what StarAMR needs for input. Do not alter this field unless doing pipeline development. Do not alter this field unless doing pipeline development.
    - report_tag: The field name of StarAMR in the final summary report. Do not alter this field unless doing pipeline development.
    - header_p: Indicates the final report from StarAMR contains a header line. Do not alter this field unless doing pipeline development.

### Bakta
Bakta is used to provide annotation of genomes, it is very reliable but it can be slow.

- bakta
    - singularity: The singularity container containing Bakta.
    - docker: The Docker container containing Bakta.
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
Performs typing of *Staphylococcus* species.

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
*in-silico Shigella* typing. 
>**NOTE:** It is unlikely this subtyper will be triggered as GTDB has merged *E.coli* and *Shigella* in an updated sketch. An updated version of ECTyper will be released soon to address the shortfalls of this sketch. If you are relying on *Shigella* detection add `--run_kraken true` to your command line or update the value in the `.nextflow.config` as Kraken2 (while slower) can still detect *Shigella*.

- shigeifinder
    - singularity: The Singularity container containing Shigeifinder.
    - docker: The path to the Docker container containing Shigeifinder.
    - container_version: The version number **to be updated with the containers** as Shigeifinder does not currently have a version number tracked in the command.
    - tsv_ext: Extension of output report.
    - report_tag: The name of the output report for shigeifinder.
    - header_p: Denotes that the output from Shigeifinder includes header values.


### Shigatyper (Replaced with Shigeifinder)
Code still remains but it will likely be removed later on.

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
