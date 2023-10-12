# Bin Contigs

## subworkflows/local/split_metagenomic.nf
## Steps

1. **kraken2** is run to generate output reports and separate classified contigs from unclassified.
2. **A Python script** is run that separates each classified group of contigs into separate files at a specified taxonomic level (the default level is genus). Quite a few outputs can be generated from the process as each file is each file id is updated to be labeled as {Sample Name}_{Genus}

## Input
- contigs, reads and meta data
## Outputs
- metadata, binned contigs