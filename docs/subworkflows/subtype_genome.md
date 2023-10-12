# Genome Sub-typing

## subworkflows/local/subtype_genome

## Steps
1. **Parsing of Mash report** is done to determine the species present in the sample.
2. **Species specific subtyping** tools are launched requiring the pipelines outputted **Mash** screen report. Currently subtyping tools for *E.coli*, *Salmonella*, *Listeria spp.* and *Shigella spp.* are supported.

## Note of importance
If a sample cannot be subtyped, it merely passes through the pipeline and is not typed. A log message will instead be displayed notifying the user the sample cannot be typed however.

## Input
- contigs and meta data
- Mash report

## Output
- software versions
