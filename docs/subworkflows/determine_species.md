# Determine Species

## subworkflows/local/determine_species

## Steps
1. **Taxonomic classification** is completed using [Mash](https://github.com/marbl/Mash) (DEFAULT), [mash_screen.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/mash_screen.nf), or [Kraken2](https://github.com/DerrickWood/kraken2) (OPTIONAL, or when samples are flagged metagenomic), [kraken.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/kraken.nf). Species classification and subsequent subtyping can be skipped by passing `--skip_species_classification true` on the command line. To select Kraken2 for speciation rather than mash you add `--run_kraken true` to your command line arguments.

>NOTE:
>If species specific subtyping tools are to be executed by the pipeline, **Mash must be the chosen classifier**

## Input
- metadata
- assembled contigs

## Output
- Mash/Kraken2 report
- software versions
