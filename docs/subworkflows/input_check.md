# Input Verification

## subworkflows/local/input_check.nf


## Steps
1. Reads in the sample sheet and groups samples with shared IDs. 

2. Pipeline specific tags are added to each sample.

3. If there are samples that have duplicate ID's the **samples will be combined**.

## Input
- CSV formatted sample sheet

## Outputs
- A channel of reads and their associated tags
