# Assembly Quality Control

## subworkflows/local/qc_assembly

## Steps
1. **Generate assembly quality metrics** using **QUAST**. QUAST is used to generate summary assembly metrics such as: N50 value, number of contigs,average depth of coverage and genome size.
2. **Assembly filtering** a script implemented using the nextflow DSL (Groovy) then filters assemblies that meet quality thresholds, so that only assemblies meeting some given set of criteria are used in down stream processing.
3. **Contamination detection** using CheckM, CheckM is run to identify a percent contamination score and build up evidence for signs of contamination in a sample. CheckM can be skipped by adding `--skip_checkm` to you command-line options as the data it generates may not be needed, and it can have a long run time.
4. **Classic seven gene MLST** using **mlst**. (mlst)[https://github.com/tseemann/mlst] is run and its outputs are contained within the final report. This step can be skipped by adding `--skip_mlst` to the commmand line options.


## Input
- cleaned reads and metadata
- polished contigs and metadata

## Outputs
- filtered contigs
- software versions
