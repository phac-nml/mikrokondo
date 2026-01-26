# Assembly Quality Control

## subworkflows/local/qc_assembly

## Steps

1. **Generate assembly quality metrics** [QUAST](https://github.com/ablab/quast) is used to generate summary assembly metrics such as: N50 value, number of contigs,average depth of coverage and genome size.

2. **Assembly filtering** Using a custom nexflow DSL (Groovy)script, assemblies are filtered to meet quality thresholds.

   - See [nextflow.config](https://github.com/phac-nml/mikrokondo/blob/main/nextflow.config) in the `quast_filter` section to see what defaults are currently implemented, or to set your own.

3. **Contamination detection** [CheckM2](https://github.com/chklovski/CheckM2) is run to identify a percent contamination score and build up evidence for signs of contamination in a sample.

   - CheckM2 can be skipped by adding `--skip_checkm` to the command-line options as the data it generates may not be needed, and it can have a long run time.

4. **Classic seven gene MLST** [mlst](https://github.com/tseemann/mlst) is run and its outputs are contained within the final report.

   - This step can be skipped by adding `--skip_mlst` to the commmand line options.

## Input

- cleaned reads (`fastq`) from the `FinalReads` dir
  - This is the final reads file from the last step in the `Clean Reads` workflow (taking into account any skip flags that have been used)
- Contig file (`fasta`) from the `FinalAssembly` dir
  - This is the final contig file from the last step in the CleanAssemble workflow (taking into account any skip flags that have been used)

## Outputs

- Assembly
  - Quality
    - CheckM2
      - SAMPLE
        - diamond_output
        - protein_files
        - SAMPLE.checkm2.quality.log
        - SAMPLE.quality_report.checkm2.quality.tsv
    - Quast
      - SAMPLE
- Subtyping
  - SevenGeneMLST
  - mlst
