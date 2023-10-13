# Post assembly
## workflows/local/PostAssembly

This workflow is triggered if only assemblies are input to the pipeline and is triggered after the `CleanAssemble.nf` workflow. Here Quast, CheckM, species determination (Using Kraken2 or Mash), annotation and subtyping are all performed.

## Included sub-workflows

- `qc_assemblies.nf`
- `determine_species.nf`
- `split_metagenomic.nf`
- `subtype_genome.nf`

## Steps
1. **Determine type**
	a. Isolate: proceeds to step 2.
	b. Metagenomic: runs the following two modules before proceeding to step 2.
		i.	Kraken
		ii.	Bin contigs
2. **QC Assemblies** (OPTIONAL)
3. **Determine species** (OPTIONAL)
4. **Subtype genome** (OPTIONAL)
5. **Annotate genome** (OPTIONAL)
6. Multiqc? <!-- will this be in the final workflow? -->

## Input
- Contig file (fasta)

## Output
- Tab delimited file containing collated results from all subworkflows <!-- No idea if this is right -->
- JSON file containing output of workflow outputs
