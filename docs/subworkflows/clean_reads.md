# Read Quality Control

## subworkflows/local/clean_reads

## Steps
1. **Reads are decontaminated** using **minimap2**, against an 'sequencing off-target' index. This index contains:
	- Reads associated with Humans (de-hosting)  
	- Known sequencing controls (phiX)  
	- A **new index can be swapped in, or created** (see minimap2_index subworkflow). <!-- ADD LINK TO THIS SUBWORKFLOW -->
2. **FastQC** is run on reads to create summary outputs, **FastQC may not be retained** in later versions of MikroKondo.
3. **Read quality filtering and trimming** is performed using [FastP](https://github.com/OpenGene/fastp)  
	- Currently no adapters are specified within FastP when it is run and auto-detection is used. 
	- FastP parameters can be altered within the nextflow.config file. <!-- ADD LINK TO CHANGING PARAMETERS PAGE -->
	- Long read data is also run through FastP for gathering of summary data, however long read (un-paired reads) trimming is not performed and only summary metrics are generated. **Chopper** is currently integrated in MikroKondo but it has been removed from this workflow due to a lack of interest in quality trimming of long read data. It may be reintroduced in the future upon request.  
4. **Genome size estimation** is performed using [Kat](https://github.com/TGAC/KAT) k-mer spectra's are also generated.
5. **Read downsampling** (OPTIONAL) if toggled on, an estimated depth threshold can be specified to down sample large read sets. This step can be used to improve genome assembly quality, and is something that can be found in other assembly pipelines such as [Shovill](https://github.com/tseemann/shovill).   
	- Depth is estimated by using the estimated genome size output from [Kat](https://github.com/TGAC/KAT)  
	- Total basepairs are taken from [FastP](https://github.com/OpenGene/fastp)  
	- Read downsampling is then performed using [Seqtk](https://github.com/lh3/seqtk)   
6. **Metagenomic assesment** using a custom [Mash](https://github.com/marbl/Mash) 'sketch' file generated from the Genome Taxonomy Database [GTDB](https://gtdb.ecogenomic.org/) and the mash_screen module, the workflow will assess how many bacterial taxa are present in a sample (default of X percent to positively identify a taxa <!-- WHAT IS THE THRESHOLD OF DECIDING A SAMPLE HAS MORE THAN ONE TAXA?-->, to change this setting, see 'changing parameters')  <!-- ADD LINK TO CHANGING PARAMETERS PAGE -->. When more than 1 taxa are present, the metagenomic tag is set, which has further implications downstream in the 'Post Assembly' workflow. <!-- ADD LINK TO THIS WORKFLOW -->
7. **Nanopore ID screening** duplicate nanopore read ID's have been known to cause issues in the pipeline downstream. In order to bypass this issue, an option can be toggled where a script will read in nanopore reads and append a unique ID to the header.

## Input
- reads and metadata

## Outputs
- quality trimmed and deconned reads
- estimated genome size
- estimated heterozygozity
- software versions
