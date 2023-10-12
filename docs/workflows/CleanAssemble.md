# Clean Assemble
## workflows/local/CleanAssemble

## Steps <!-- I need to add in the links to the workflow pages once they exist -->
1. **QC reads** subworkflow steps in brief are listed below, for further information see (clean_reads.nf)
	- Reads are checked for known sequencing contamination  
	- Quality metrics are calculated  
	- Reads are trimmed  
	- Coverage is estimated  
	- Sample is subsampled to set level (OPTIONAL)  
	- Read set is assessed to be either an isolate or metagenomic sample (from presence of multiple taxa)  

2. **Assemble reads** using the '<SOMETHING>' flag, read sets will be diverted to either the assemble_reads (short reads) or hybrid_assembly (short and/or long reads) workflow. Though the data is handled differently in eash subworklow, both generate a contigs file and a bandage image and have an option of initial polishing via Racon. See (assemble_reads.nf) and (hybrid_assembly.nf) subworkflow pages for more details. <!-- ADD IN LINKS TO PAGES -->  

3. **Polish assembles** (OPTIONAL) Polishing of contigs can be added (polish_assemblies.nf). To make changes to the default workflow, see setting 'optional flags' page <!-- ADD IN LINK TO PAGE -->

## Input
- Next generation sequencing reads:
	+ Short read - Illumina
	+ Long read:
		* Nanopore
		* :warning:Pacbio (untested)

## Output
- quality trimmed and deconned reads (fastq)
- estimated genome size
- estimated heterozygozity
- assembled contigs (fasta)
- bandage image (png)
- software versions