
![Pipeline](images/20230630_Mikrokondo-logo_v4.svg "Logo")
# Welcome to mikrokondo!

## What is mikrokondo?

Mikrokondo is a tidy workflow for performing routine bioinformatic assessment of sequencing reads and assemblies, such as: read pre-processing, assessing contamination, assembly, quality assessment of assemblies, and pathogen-specific typing. It is easily configurable, provides dynamic dispatch of species specific workflows and produces common outputs.

## What is the target audience?

This workflow can be used in sequencing and reference laboratories as a part of an automated quality and initial bioinformatics assessment protocol.

## Is mikrokondo right for me?

Mikrokondo is purpose built to provide sequencing and clinical laboratories with an all encompassing workflow to provide a standardized workflow that can provide the initial quality assessment of sequencing reads and assemblies, and initial pathogen-specific typing. It has been designed to be configurable so that new tools and quality metrics can be easily incorporated into the workflow to allow for automation of these routine tasks regardless of pathogen of interest. It currently accepts Illumina, Nanopore or Pacbio (Pacbio data only partially tested) sequencing data. It is capable of hybrid assembly or accepting pre-assembled genomes.

This workflow will detect what pathogen(s) is present and apply the applicable metrics and genotypic typing where appropriate, generating easy to read and understand reports. If your group is regularly sequencing or analyzing genomic sequences, implementation of this workflow will automate the hands-on time time usually required for these common bioinformatic tasks.

## Whole genome and Metagenomic samples typical workflow differences

This pipeline has been written to automatically detect if a sample contains more than one organism. Whether it is intentional (as in shotgun metagenomics) or contamination, a sample with more than one organism detected via Mash will be marked as `metagenomic`. 

Typical workflow for **whole genome sample** (one organism):

1. Reads are cleaned of human DNA, trimmed and one organism is detected
2. Reads are assembled into contigs, then polished
3. Assemblies are run through quality tools
4. Assemblies are speciated with appropriate tool
5. Species specific subtyping tools are called based on speciation from step 4.

Typical workflow for **metagenomic sample** (greater than one organism):

1. Reads are cleaned of human DNA, trimmed and multiple organisms are detected
2. Reads are assembled into contigs, then polished
3. Assemblies undergo contig binning (via Kraken2)
4. Each bin is run through quality tools
5. Each bin is speciated with appropriate tool
6. Species specific subtyping tools are called on each bin based on speciation from step 5.

## Workflow Schematics (Subject to change)

![Pipeline](images/mikrokondo_mermaid.svg "Workflow")
