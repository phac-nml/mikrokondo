# Assembly Quality Control

## subworkflows/local/qc_assembly

## Steps
1. **Generate assembly quality metrics** using **QUAST**. QUAST is used to generate summary assembly metrics such as: N50 value, number of contigs and genome size.
2. **Assembly filtering** a script implemented using the nextflow DSL (Groovy) then filters assemblies that meet quality thresholds, so that only assemblies meeting some given set of criteria are used in down stream processing.

## Input
- cleaned reads and metadata
- polished contigs and metadata

## Outputs
- filtered contigs
- software versions
