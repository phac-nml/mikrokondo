# Read Quality Control

## subworkflows/local/clean_reads

## Steps
1. **Reads are decontaminated** using [minimap2](https://github.com/lh3/minimap2), against a 'sequencing off-target' index. This index contains:
	- Reads associated with Humans (de-hosting)
	- Known sequencing controls (phiX)

2. **Read quality filtering and trimming** is performed using [FastP](https://github.com/OpenGene/fastp)
	- Currently no adapters are specified within FastP when it is run and auto-detection is used.
	- FastP parameters can be altered within the [nextflow.config](https://github.com/phac-nml/mikrokondo/blob/main/nextflow.config) file.
	- Long read data is also run through FastP for gathering of summary data, however long read (un-paired reads) trimming is not performed and only summary metrics are generated. [Chopper](https://github.com/wdecoster/chopper) is currently integrated in MikroKondo but it has been removed from this workflow due to a lack of interest in quality trimming of long read data. It may be reintroduced in the future upon request.

3. **Genome size estimation** is performed using [Mash](https://github.com/marbl/Mash) Sketch of reads and estimated genome size is output.

4. **Read down sampling** (OPTIONAL) an estimated depth threshold can be specified to down sample large read sets. This step can be used to improve genome assembly quality, and is something that can be found in other assembly pipelines such as [Shovill](https://github.com/tseemann/shovill). To disable down sampling add `--skip_depth_sampling true` to your command line.
	- Depth is estimated by using the estimated genome size output from [Mash](https://github.com/marbl/Mash)
	- Total base pairs are taken from [FastP](https://github.com/OpenGene/fastp)
	- Read down sampling is then performed using [Seqtk](https://github.com/lh3/seqtk) (Illumina) or [Rasusa](https://github.com/mbhall88/rasusa) (Nanopore or Pacbio).

5. **Metagenomic assessment** using a custom [Mash](https://github.com/marbl/Mash) 'sketch' file generated from the Genome Taxonomy Database [GTDB](https://gtdb.ecogenomic.org/) and the mash_screen module, this step assesses how many bacterial genera are present in a sample (e.g. a contaminated or metagenomic sample may have more than one genus of bacteria present) with greater than 90% identity (according to Mash). When more than 1 taxa are present, the metagenomic tag is set, turning on metagenomic assembly in later steps. Additionally Kraken2 will be run on metagenomic assemblies and contigs will be binned at a defined taxonomic level (default level: genus).

6. **Nanopore ID screening** duplicate Nanopore read ID's have been known to cause issues in the pipeline downstream. In order to bypass this issue, an option can be toggled where a script will read in Nanopore reads and append a unique ID to the header, this process can be slow so default setting is to skip, `--skip_ont_header_cleaning true`.

## Input
- Next generation sequencing reads:
	+ Short read - Illumina
	+ Long read:
		* Nanopore
		* Pacbio
- User submitted sample sheet


## Outputs
- Reads
	- FinalReads
		- SAMPLE
	- Processing
		- Dehosting
			- Trimmed
				- FastP
					- Seqtk
				- MashSketches
	- Quality
		- RawReadQuality
		- Trimmed
			- FastP
			- MashScreen
