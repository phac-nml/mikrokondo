# Input Verification

## subworkflows/local/input_check.nf


## Steps
1. Intake Sample sheet CSV and group samples with same ID. Sample metadata specific to the pipeline is added. A metadata field will additionally be created for samples containing the read data and sample information such as the samples name, and if the sample contains paired reads (Illumina) or long reads (Nanopore or Pacbio). Verification of workflows with Pacbio reads still needs to be performed as of 2023-07-19.
2. If there are samples that contain duplicate ID's the samples will be combined.


## Input
- CSV formatted sample sheet

## Outputs
- A channel of reads and their associated metadata
