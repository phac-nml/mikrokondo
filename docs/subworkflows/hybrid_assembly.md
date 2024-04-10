# Hybrid Assembly

## subworkflows/local/hybrid_assembly

## Choice of 2 workflows
1. **DEFAULT**
    A. [Flye](https://github.com/fenderglass/Flye) assembly [flye_assembly.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/flye_assemble.nf)
    B. [Bandage](https://rrwick.github.io/Bandage/) creates a bandage plot of the assembly [bandage_image.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/bandage_image.nf)
    C. [Minimap2](https://github.com/lh3/minimap2) creates an index of the contigs (minimap2_index.nf), then maps long reads to this index [minimap2_map.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/minimap2_map.nf)
    D. [Racon](https://github.com/isovic/racon) uses the short reads to iteratively polish contigs [pilon_iter.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/pilon_polisher.nf)
2. **OPTIONAL**
    A. [Unicycler](https://github.com/rrwick/Unicycler) assembly [unicycler_assemble.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/unicycler_assemble.nf)
    B. [Bandage](https://rrwick.github.io/Bandage/) creates a bandage plot of the assembly [bandage_image.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/bandage_image.nf)

## Input
- metadata
- short reads
- long reads

## Output
- contigs (pilon, unicycler)
- vcf data (pilon)
- software versions
