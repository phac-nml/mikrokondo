# Bin Contigs

## subworkflows/local/split_metagenomic.nf
## Steps

1. **[Kraken2](https://github.com/DerrickWood/kraken2/wiki)** is run to generate output reports and separate classified contigs from unclassified.
2. **[A custom script](https://github.com/phac-nml/mikrokondo/blob/main/bin/kraken2_bin.py)** separates each classified group of contigs into separate files at a specified taxonomic level (default level: genus). Output files are labeled as `[Sample Name]_[Genus]` to allow for easy post processing.

## Input

- Contig file (fasta) from the `FinalAssembly` dir
	- This is the final contig file from the last step in the CleanAssemble workflow (taking into account any skip flags that have been used)
- metadata from prior tools

## Outputs
- Assembly
    - PostProcessing
        - Metagenomic
            - BinnedContigs
                - SAMPLE
                    - CONTIG
