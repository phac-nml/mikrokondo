# Assembly Polishing

## subworkflows/local/polish_assemblies

## Steps
1. Final polishing proceeds differently depending on whether the sample is Illumina or Pacbio.

  - **Illumina** A custom script is implemented to iteratively polish assemblies with reads based on a set number of iterations (DEFAULT 3). 
     - Polishing uses [Pilon](https://github.com/broadinstitute/pilon) and [minimap2](https://github.com/lh3/minimap2), with reads being mapped back to the polished assembly each time.
  - **Nanopore** [Medaka](https://github.com/nanoporetech/medaka) consensus is used to polish reads, a model must be specified by the user for polishing.
  - **Pacbio** No addtional polishing is performed, outputs of Pacbio data still need to be tested.

## Input
- cleaned reads
- Assembly

## Outputs
- Polished assemblies
- Reads used to polish
