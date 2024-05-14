# Clean Assemble
## workflows/local/CleanAssemble

## Included sub-workflows

- `assemble_reads.nf`
- `clean_reads.nf`
- `hybrid_assembly.nf`
- `input_check.nf`
- `polish_assemblies.nf`


## Steps
1. **[QC reads](/mikrokondo/subworkflows/clean_reads)** subworkflow steps in brief are listed below, for further information see [clean_reads.nf](https://github.com/phac-nml/mikrokondo/blob/main/subworkflows/local/clean_reads.nf)
	- Reads are checked for known sequencing contamination
	- Quality metrics are calculated
	- Reads are trimmed
	- Coverage is estimated
	- Read set subsampled to set level (OPTIONAL)
	- Read set is assessed to be either an isolate or metagenomic sample (from presence of multiple taxa)

2. **[Assemble reads](/mikrokondo/subworkflows/assemble_reads)** using the `params.platform` flag, read sets will be diverted to either the assemble_reads (short reads) or hybrid_assembly (short and/or long reads) workflow. Though the data is handled differently in eash subworklow, both generate a contigs file and a bandage image, with an option of initial polishing via Racon. See [assemble_reads.nf](https://github.com/phac-nml/mikrokondo/blob/main/subworkflows/local/assemble_reads.nf) and [hybrid_assembly.nf](https://github.com/phac-nml/mikrokondo/blob/main/subworkflows/local/hybrid_assembly.nf) subworkflow pages for more details.

3. **[Polish assembles](/mikrokondo/subworkflows/polish_assemblies)** (OPTIONAL) Polishing of contigs can be added [polish_assemblies.nf](https://github.com/phac-nml/mikrokondo/blob/main/subworkflows/local/polish_assemblies.nf). To make changes to the default workflow, see setting 'optional flags' page.

## Input
- Next generation sequencing reads:
	+ Short read - Illumina
	+ Long read:
		* Nanopore
		* Pacbio

## Output
- Reads
   + FinalReads
       * SAMPLE
   + **Processing**
       * Dehosting
           - Trimmed
               - FastP
               - MashSketches
   + Quality
       * RawReadQuality
       * Trimmed
           - FastP
           - MashScreen
- Assembly
    + Assembling
		* Bandage
		* ConsensusGeneration
			- Polishing
				- Pilon
					- BAMs
					- Changes
					- Fasta
					- VCF
			- Racon
				- Consensus
		* Spades
			- Contigs
			- GeneClusters
			- Graphs
			- Logs
			- Scaffolds
			- Transcripts
	+ FinalAssembly
		* SAMPLE

>NOTE:
>Bolded directories contain the nested structure of tool output. The further into the structure you go, the further along the workflow that that tool was run.
>