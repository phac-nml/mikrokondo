# Post assembly
## workflows/local/PostAssembly

This workflow is triggered in two ways: 1. when assemblies are used for initial input to the pipeline; and 2. after the `CleanAssemble.nf` workflow completes. Within this workflow, Quast, CheckM, species determination (Using Kraken2 or Mash), annotation and subtyping are all performed.

## Included sub-workflows

- `annotate_genomes.nf`
- `determine_species.nf`
- `polish_assemblies.nf`
- `qc_assemblies.nf`
- `split_metagenomic.nf`
- `subtype_genome.nf`

## Steps
1. **Determine type** using the `metagenomic_samples` flag, this workflow will direct assemblies to the following two paths:
	1. Isolate: proceeds to step 2.
	2. Metagenomic: runs the following two modules before proceeding to step 2.
        1.	[kraken.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/kraken.nf) runs kraken2 on contigs
        2.	[bin_kraken2.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/bin_kraken2.nf) bins contigs to respective genus level taxa.
2. **[QC assemblies](/mikrokondo/subworkflows/qc_assembly)** (OPTIONAL) runs quast and assigns quality metrics to generated assemblies.
3. **[Determine species](/mikrokondo/subworkflows/determine_species)** (OPTIONAL) runs classifier tool (default: [Mash](https://github.com/marbl/Mash)) to determine sample or binned species.
4. **[Subtype genome](/mikrokondo/subworkflows/subtype_genome)** (OPTIONAL) species specific subtyping tools are launched using a generated MASH screen report.
5. **[Annotate genome](/mikrokondo/subworkflows/genomes_annotate)** (OPTIONAL) tools for annotation and identification of genes of interest are launched as a part of this step.

## Input
- Contig file (fasta) from the `FinalAssembly` dir
	- This is the final contig file from the last step in the `CleanAssemble` workflow (taking into account any skip flags that have been used)

## Output
- Subtyping
    + TYPINGTOOL
        * SAMPLE
- FinalReports
    + Aggregated
        * Json
        * Tables
    + FlattenedReports
    + Sample
        * Json

>SUBTYPING:
>Within the subtyping directory there will be directories for each of the different subtyping tools used during that run. The number and type of tools will differ depending on the organisms present in the set of samples submitted to the pipeline


>FINAL REPORTS:
>Within mikrokondo, a number of reports have been created to collate the different tool outputs. These are a quicker way to view the final results for your sample runs.
