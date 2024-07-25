# phac-nml/mikrokondo: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### `Changed`

- Removed quay.io docker repo tags [PR 94](https://github.com/phac-nml/mikrokondo/pull/94)

### `Fixed`

- Fixed spelling issues issues in config values. See [PR 95](https://github.com/phac-nml/mikrokondo/pull/95)


## [0.3.0] - 2024-07-04

### `Changed`

- Reformatted QCSummary fields and added a QCMessage field containing the old summary message. See [PR 85](https://github.com/phac-nml/mikrokondo/pull/85)

- Changed default Python3 image to use the StarAMR image. See [PR 90](https://github.com/phac-nml/mikrokondo/pull/90)

- Stripped identifier from taxonomic identification from string. See [PR 90](https://github.com/phac-nml/mikrokondo/pull/90)

- Removed retry logic from processes and switched them to ignore. See [PR 91](https://github.com/phac-nml/mikrokondo/pull/91)

### `Fixed`

- Updated samtools/minimap2 container fixing CI issues and issues running the pipeline with Docker. See [PR 85](https://github.com/phac-nml/mikrokondo/pull/85)

- Removed task.maxRetries from error handling to prevent StackOverflow addressing [PR 91](https://github.com/phac-nml/mikrokondo/pull/91)

### `Added`

- Altered name of stored `SpeciesTopHit` field in the irida-next.config, and added a field displaying the field name used addressing [PR 90](https://github.com/phac-nml/mikrokondo/pull/90)


## [0.2.1] - 2024-06-03

### `Fixed`

- Parsed table values would not show up properly if values were missing resolving issue See [PR 83](https://github.com/phac-nml/mikrokondo/pull/83)
- Fixed mismatched description for minimap2 and mash databases. See [PR 83](https://github.com/phac-nml/mikrokondo/pull/83)

## [0.2.0] - 2024-05-14

### `Added`

- Updated documentation for params. See [PR 66](https://github.com/phac-nml/mikrokondo/pull/66)

- Fixed param typos in schema, config and docs. See [PR 66](https://github.com/phac-nml/mikrokondo/pull/66)

- Added parameter to skip length filtering of sequences. See [PR 66](https://github.com/phac-nml/mikrokondo/pull/66)

- Added locidex for allele calling. See [PR 62](https://github.com/phac-nml/mikrokondo/pull/62)

- Updated directory output structure and names. See [PR 66](https://github.com/phac-nml/mikrokondo/pull/66)

- Added tests for Kraken2 contig binning. See [PR 66](https://github.com/phac-nml/mikrokondo/pull/66)

### `Fixed`

- If you select to filter contigs by length, those contigs will now be used for subsequent analysis. See [PR 66](https://github.com/phac-nml/mikrokondo/pull/66)

- Matched ECTyper and SISTR parameters to what is set in the current IRIDA. See [PR 68](https://github.com/phac-nml/mikrokondo/pull/68)

- Updated StarAMR point finder DB selection to resolve error when in db selection when a database is not selected addressing issue. See [PR 74](https://github.com/phac-nml/mikrokondo/pull/74)

- Fixed calculation of SeqtkBaseCount value include counts for both pairs of paired-end reads. See [PR 65](https://github.com/phac-nml/mikrokondo/pull/65).

## `Changed`

- Changed the specific files and metadata to store within IRIDA Next. See [PR 65](https://github.com/phac-nml/mikrokondo/pull/65)

- Added separate report fields for (PASSED|FAILED|WARNING) values and for the the actual value. See [PR 65](https://github.com/phac-nml/mikrokondo/pull/65)

- Updated StarAMR to version 0.10.0. See [PR 74](https://github.com/phac-nml/mikrokondo/pull/74)

## [0.1.2] - 2024-05-02

### Changed

- Changed default values for database parameters `--dehosting_idx`, `--mash_sketch`, `--kraken2_db`, and `--bakta_db` to null. See [PR 71](https://github.com/phac-nml/mikrokondo/pull/71)
- Enabled checking for existence of database files in JSON Schema to avoid issues with staging non-existent files in Azure. See [PR 71](https://github.com/phac-nml/mikrokondo/pull/71).
- Set `--kraken2_db` to be a required parameter for the pipeline. See [PR 71](https://github.com/phac-nml/mikrokondo/pull/71)
- Hide bakta parameters from IRIDA Next UI. See [PR 71](https://github.com/phac-nml/mikrokondo/pull/71)

## [0.1.1] - 2024-04-22

### Changed

- Switched the resource labels for **parse_fastp**, **select_pointfinder**, **report**, and **parse_kat** from `process_low` to `process_single` as they are all configured to run on the local Nextflow machine. See [PR 67](https://github.com/phac-nml/mikrokondo/pull/67)

## [0.1.0] - 2024-03-22

Initial release of phac-nml/mikrokondo. Mikrokondo currently supports: read trimming and quality control, contamination detection, assembly (isolate, metagenomic or hybrid), annotation, AMR detection and subtyping of genomic sequencing data targeting bacterial or metagenomic data.

- Bumped version number to 0.1.0

- Updated docs to include awesome-page plugin and restructured readme.

- Updated coverage defaults for Shigella, Escherichia and Vibrio

- Updated file outputs to match the nf-iridanext plug-in

- Incorporated IRIDANext plug-in

- Upgraded nf-validation to latest version 2.0.0

- Added message to final summary report notifying user if an assembly does not have any contigs exceeding the minimum contig length parameter

- Added contig count check before running Quast to ensure empty files are not passed in.

- Added process to filter contigs based on a minimum required contig length.

- Added option to force sample to be implemented as an isolate

- Changed salmonella default default coverage to 40

- Added integration testing using [nf-test](https://www.nf-test.com/).

[0.3.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.3.0
[0.2.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.2.1
[0.2.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.2.0
[0.1.2]: https://github.com/phac-nml/mikrokondo/releases/tag/0.1.2
[0.1.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.1.1
[0.1.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.1.0
