# phac-nml/mikrokondo: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### `Added`

### `Fixed`

### `Dependencies`

### `Deprecated`
