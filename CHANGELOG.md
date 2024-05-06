# phac-nml/mikrokondo: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## `Unreleased`

### `Added`

- Updated documentation for params.

- Fixed param typos in schema, config and docs.

- Added parameter to skip length filtering of sequences

- Added locidex for allele calling

- Updated directory output structure and names

- Added tests for Kraken2 contig binning

### `Fixed`

- If you select to filter contigs by length, those contigs will now be used for subsequent analysis. This resolves issue [#55](https://github.com/phac-nml/mikrokondo/issues/55)

### `Dependencies`

### `Deprecated`


## v0.1.2 - [2024-05-02]

### Added

### Changed

- Changed default values for database parameters `--dehosting_idx`, `--mash_sketch`, `--kraken2_db`, and `--bakta_db` to null.
- Enabled checking for existance of database files in JSON Schema to avoid issues with staging non-existent files in Azure.
- Set `--kraken2_db` to be a required parameter for the pipeline.
- Hide bakta parameters from IRIDA Next UI.

## v0.1.1 - [2024-04-22]

### Added

### Changed

- Switched the resource labels for **parse_fastp**, **select_pointfinder**, **report**, and **parse_kat** from `process_low` to `process_single` as they are all configured to run on the local Nextflow machine.

## v0.1.0 - [2024-03-22]

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


