# Assembly

## subworkflows/local/assemble_reads

>**NOTE:**
>Hybrid assembly of long and short reads uses a different workflow that can be found [here](https://phac-nml.github.io/mikrokondo/subworkflows/hybrid_assembly/)

## Steps

1. **Assembly** proceeds differently depending whether paired-end short or long reads. If the samples are marked as metagenomic, then metagenomic assembly flags will be added to the corresponding assembler.
  - **Paired end assembly** is performed using [Spades](https://github.com/ablab/spades) (for more information see the module [spades_assemble.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/spades_assemble.nf))
  - **Long read assembly** is performed using [Flye](https://github.com/fenderglass/Flye) (for more information see the module [flye_assemble.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/flye_assemble.nf)

2. **Bandage plots** are generated using [Bandage](https://rrwick.github.io/Bandage/), these images were included as they can be informative of assembly quality in some situations [bandage_image.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/bandage_image.nf).

3. **Polishing** (OPTIONAL) can be performed on either short or long/hybrid assemblies. [Minimap2](https://github.com/lh3/minimap2) is used to create a contig index [minimap2_index.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/minimap2_index.nf) and then maps reads to that index [minimap2_map.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/minimap2_map.nf). Lastly, [Racon](https://github.com/isovic/racon) uses this output to perform contig polishing [racon_polish.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/racon_polish.nf). To turn off polishing add the following to your command line parameters `--skip_polishing`.

## Input
- cleaned reads
- metadata

## Outputs
- contigs
- assembly graphs
- polished contigs
- software versions
