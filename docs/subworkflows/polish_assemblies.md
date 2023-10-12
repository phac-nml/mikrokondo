# Assembly Polishing

## subworkflows/local/polish_assemblies

## Steps
1. Final polishing proceeds differently depending on whether the sample is Illumina or Pacbio.
  - **Illumina** A custom script is implemented which iteratively polishes assemblies with reads based on a set amount of iterations specified by the user. polishing uses Pilon and minimap2, with reads being mapped back to the polished assembly each time.
  - **Nanopore** Medaka consensus is used to polish reads, a model must be specified by the user for polishing
  - **Pacbio** No addtional polishing is performed, outputs of Pacbio data still need to be tested.

## Input
- cleaned reads
- Assembly

## Outputs
- Polished assemblies and the reads used to polish them
