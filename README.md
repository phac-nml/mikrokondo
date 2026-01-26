![Logo](docs/images/20230630_Mikrokondo-logo_v4.svg)

<!-- [![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX) -->

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.10.3-23aa62.svg)](https://www.nextflow.io/)
<!-- [![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/) -->
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
<!-- [![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/mk-kondo/mikrokondo) -->

- [Introduction](#introduction)
  - [What is mikrokondo?](#what-is-mikrokondo-)
  - [Is mikrokondo right for me?](#is-mikrokondo-right-for-me-)
  - [Citation](#citation)
    - [Contact](#contact)
- [Installing mikrokondo](#installing-mikrokondo)
  - [Step 1: Installing Nextflow](#step-1--installing-nextflow)
  - [Step 2: Choose a Container Engine](#step-2--choose-a-container-engine)
    - [Docker or Singularity?](#docker-or-singularity-)
  - [Step 3: Install dependencies](#step-3--install-dependencies)
    - [Dependencies listed](#dependencies-listed)
  - [Step 4: Further resources to download](#step-4--further-resources-to-download)
    - [Configuration and settings:](#configuration-and-settings-)
- [Getting Started](#getting-started)
  - [Usage](#usage)
    - [Data Input/formats](#data-input-formats)
    - [Output/Results](#output-results)
  - [Run example data](#run-example-data)
  - [Testing](#testing)
    - [Install nf-test](#install-nf-test)
    - [Run tests](#run-tests)
  - [Troubleshooting and FAQs:](#troubleshooting-and-faqs-)
  - [References](#references)
  - [Legal and Compliance Information:](#legal-and-compliance-information-)
  - [Updates and Release Notes:](#updates-and-release-notes-)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

# Introduction

## What is mikrokondo?

Mikrokondo is a tidy workflow for performing routine bioinformatic tasks like, read pre-processing, assessing contamination, assembly and quality assessment of assemblies. It is easily configurable, provides dynamic dispatch of species specific workflows and produces common outputs.

## Is mikrokondo right for me?

Mikrokondo is purpose built to provide sequencing and clinical laboratories with an all encompassing workflow to provide a standardized workflow that can provide the initial quality assessment of sequencing reads and assemblies, and initial pathogen-specific typing. It has been designed to be configurable so that new tools and quality metrics can be easily incorporated into the workflow to allow for automation of these routine tasks regardless of pathogen of interest. It currently accepts Illumina, Nanopore or Pacbio (Pacbio data only partially tested) sequencing data. It is capable of hybrid assembly or accepting pre-assembled genomes.

This workflow will detect what pathogen(s) is present and apply the applicable metrics and genotypic typing where appropriate, generating easy to read and understand reports. If your group is regularly sequencing or analyzing genomic sequences, implementation of this workflow will automate the hands-on time time usually required for these common bioinformatic tasks.

## Citation

This software (currently unpublished) can be cited as:

- Matthew Wells, James Robertson, Aaron Petkau, Christy-Lynn Peterson, Eric Marinier. "mikrokondo" Github <https://github.com/phac-nml/mikrokondo/>

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

### Contact

[Matthew Wells] : <matthew.wells@phac-aspc.gc.ca>

# Installing mikrokondo

## Step 1: Installing Nextflow

Nextflow is required to run mikrokondo (requires Linux), and instructions for its installation can be found at either: [Nextflow Home](https://www.nextflow.io/) or  [Nextflow Documentation](https://www.nextflow.io/docs/latest/getstarted.html#installation)

## Step 2: Choose a Container Engine

Nextflow and Mikrokondo only supports running the pipeline using containers such as: Docker, Singularity (now apptainer), podman, gitpod, shifter and charliecloud. Currently only usage with Singularity has been fully tested, (Docker and Apptainer have only been partially tested) but support for each of the container services exists.

>[!Note]
>Singularity was adopted by the Linux Foundation and is now called Apptainer. Singularity still exists, but it is likely newer installs will use Apptainer.

### Docker or Singularity?

Docker or Singularity (Apptainer) Docker requires root privileges which can can make it a hassle to install on computing clusters (there are workarounds). Apptainer/Singularity does not, so running the pipeline using Apptainer/Singularity is the recommended method for running the pipeline.

## Step 3: Install dependencies

Besides the Nextflow run time (requires Java), and container engine the dependencies required by mikrokondo are fairly minimal requiring only Python 3.10 (more recent Python versions will work as well) to run.

### Dependencies listed

- Python (3.10>=)
- Nextflow (22.10.1>=)
- Container service (Docker, Singularity, Apptainer have been tested)
- The source code: `git clone https://github.com/phac-nml/mikrokondo.git`

## Step 4: Further resources to download

- [GTDB Mash Sketch](https://zenodo.org/record/8408361): required for speciation and determination if sample is metagenomic
- [Decontamination Index](https://zenodo.org/records/13969103): Required for decontamination of reads (it is simply a minimap2 index)
- [Kraken2 database](https://benlangmead.github.io/aws-indexes/k2): Required for binning of metagenomic data and is an alternative to using Mash for speciation
- [Bakta database](https://zenodo.org/record/7669534): Running Bakta is optional and there is a light database option, however the full one is recommended. You will have to unzip and un-tar the database for usage. You can skip running Bakta however making the requirement of downloading this database **optional**.
- [StarAMR database](https://github.com/phac-nml/staramr#database-build): Running StarAMR is optional and requires downloading the StarAMR databases. Also if you wish to avoid downloading the database, the container for StarAMR has a database included which mikrokondo will default to using if one is not specified making this requirement **optional**.
- [CheckM2 database](https://zenodo.org/records/14897628/files/checkm2_database.tar.gz): The path to the downloaded and extracted CheckM2 database. This step is optional as the database can be downloaded automatically by setting the parameter `--download_checkm2_db` to true.

### Configuration and settings

The above downloadable resources must be updated in the following places in your `nextflow.config`. The spots to update in the params section of the `nextflow.config` are listed below:

```
// Bakta db path, note the quotation marks
bakta_db = "/PATH/TO/BAKTA/DB"

// Decontamination minimap2 index, note the quotation marks
dehosting_idx = "/PATH/TO/DECONTAMINATION/INDEX"

// kraken db path, not the quotation marks
kraken2_db = "/PATH/TO/KRAKEN/DATABASE/"

// GTDB Mash sketch, note the quotation marks
mash_sketch = "/PATH/TO/MASH/SKETCH/"

// STARAMR database path, note the quotation marks
// Passing in a StarAMR database is optional if one is not specified the database in the container will be used. You can just leave the db option as null if you do not wish to pass one
staramr_db = "/PATH/TO/STARMAR/DB"
```

The above parameters can be accessed for the command line as for passing arguments to the pipeline if not set in the `nextflow.config` file.

# Getting Started

## Usage

```
nextflow run main.nf --input PATH_TO_SAMPLE_SHEET --outdir OUTPUT_DIR --platform SEQUENCING_PLATFORM -profile CONTAINER_TYPE
```

Please check out the documentation for complete usage instructions here: [docs](https://phac-nml.github.io/mikrokondo/)

Under the usage section you can find example commands, instructions for configuration and a reference to a utility script to reduce command line bloat!

### Data Input/formats

Mikrokondo requires two things as input:

1. **Sample files** - fastq and fasta must be in gzip format
2. **Sample sheet** - this FOFN (file of file names) contains sample names and allows user to combine read-sets. The following header fields are accepted:
   - sample
   - fastq_1
   - fastq_2
   - long_reads
   - assembly

For more information see the [usage docs](https://phac-nml.github.io/mikrokondo/usage/installation/).

### Output/Results

All output files will be written into the `outdir` (specified by the user). More explicit tool results can be found in both the [Workflow](workflows/CleanAssemble/) and [Subworkflow](subworkflows/) sections of the docs. Here is a brief description of the outdir structure (though in brief the further into the structure you head, the further in the workflow the tool has been run):

- **Assembly** - contains all output files generated as a result of read assembly and tools using assembled contigs as input
  - **Annotation** - contains output files generated from tools applying annotation and/or gene characterization from assembled contigs
  - **Assembling** - contains output files generated as a part of the assembly process in nested order
  - **FinalAssembly** - this directory will always contain the final output contig files from the last step in the assembly process (will take into account any skip flags in the process)
  - **PostProcessing** - contains output files from intermediary tools that run after assembly but before annotation takes place in the workflow
  - **Quality** - contains all output files generated as a result of quality tools after assembly
- **Subtyping** - contains all output files from workflow subtyping tools, based off assembled contigs
- **FinalReports** - contains assorted reports including aggregated and flat reports
- **pipeline_info** - includes tool versions and other pipeline specific information
- **Reads** - contains all output files generated as a result of read processing and tools using reads as input
  - **FinalReads** - this directory will contain the final output read files from the last step in read processing (taking into account any skip flags used in the run)
  - **Processing** - contains output files from tools run to process reads in nested order
  - **Quality** - contains all output files generated from read quality tools

## Run example data

Three test profile with example data are provided and can be run like so:

- Assembly test profile: `nextflow run main.nf -profile test_assembly,<docker/singularity> --outdir <OUTDIR>`
- Illumina test profile: `nextflow run main.nf -profile test_illumina,<docker/singularity> --outdir <OUTDIR>`
- Nanopore test profile: `nextflow run main.nf -profile test_nanopore,<docker/singularity> --outdir <OUTDIR>`
- Pacbio test profile: `nextflow run main.nf -profile test_pacbio,<docker/singularity> --outdir <OUTDIR>`
  - The pacbio workflow has only been partially tested as it fails at Flye due to not enough reads being present.

## Testing

Integration tests are implemented using [nf-test](https://www.nf-test.com/). In order to run tests locally, please do the following:

### Install nf-test

```bash
# Only need to install package nf-test. Below is only for
# if you want to have nextflow and nf-test in a separate environment
conda create --name nextflow-testing nextflow nf-test
conda activate nextflow-testing
```

### Run tests

```bash
# From mikrokondo root directory
nf-test test
```

Add `--profile singularity` to switch from using docker by default to using singularity.

## Troubleshooting and FAQs

Within release 0.1.0, Bakta is currently skipped however it can be enabled from the command line or within the nextflow.config (please check the docs for more information). It has been disabled by default due issues in using the latest bakta database releases due to an issue with `amr_finder` there are fixes available and older databases still work however they have not been tested. A user can still enable Bakta themselves or fix the database. More information is provided here: <https://github.com/oschwengers/bakta/issues/268>

For a list of common issues or errors and their solutions, please read our [FAQ section](https://phac-nml.github.io/mikrokondo/troubleshooting/FAQ/).

## References

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

## Legal and Compliance Information

Copyright Government of Canada 2025

Written by: National Microbiology Laboratory, Public Health Agency of Canada

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

## Updates and Release Notes
