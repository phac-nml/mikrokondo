# Genome Sub-typing

## subworkflows/local/subtype_genome

## Steps
1. **Species specific subtyping** tools are launched according to the pipeline's **Mash** screen report. 

   - Currently subtyping tools for *E.coli*, *Salmonella*, *Listeria spp.*, *Staphylococcus spp.*, *Klebsiella spp.* and *Shigella spp.* are supported. 
   - Subtyping can be disabled from the command line by passing `--skip_subtyping true` on the command line.

> **NOTE**
> If a sample cannot be subtyped, it merely passes through the pipeline and is not typed. A log message will instead be displayed notifying the user the sample cannot be typed.

## Input
- contigs and associated tags
- Mash report

## Output
- software versions
