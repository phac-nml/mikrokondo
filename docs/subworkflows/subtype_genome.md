# Genome Sub-typing

## subworkflows/local/subtype_genome

## Steps

1. **Species specific subtyping** tools are launched according to the pipeline's **Mash** screen report.

   - Currently subtyping tools for _Escherichia_, _Salmonella_, _Listeria spp._, _Staphylococcus spp._, _Klebsiella spp._ and _Shigella spp._ are supported.
   - Subtyping can be disabled from the command line by passing `--skip_subtyping true` on the command line.

> **NOTE**
> If a sample cannot be subtyped, it merely passes through the pipeline and is not typed. A log message will instead be displayed notifying the user the sample cannot be typed.

## Input

- Contig file (fasta) from the `FinalAssembly` dir
  - This is the final contig file from the last step in the `CleanAssemble` workflow (taking into account any skip flags that have been used)
- Mash report from assembly speciation step in the `CleanAssemble` workflow

## Output

- Subtyping
  - ECTyper
    - SAMPLE
  - SevenGeneMLST
  - SISTR
  - Etc...
