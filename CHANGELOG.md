# phac-nml/mikrokondo: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### `Updated`

- Adding GitHub CI tests against Nextflow `24.10.3`. [PR #195](https://github.com/phac-nml/mikrokondo/pull/195)
- Updating GithubCI tests and nf-tests to fix nf-core linting issues and improve performance of CI testing. [PR #196](https://github.com/phac-nml/mikrokondo/pull/196)
  - Removed testing against Nextflow `latest-everything` to reduce time of tests.

## [0.9.4] - 2025-09-25

### `Added`

- Added a IRIDA Next specific parameter: `max_samples`. `max_samples` is used to limit the number of samples the pipeline will run with. When the number of samples is >= `max_samples` all processes are skipped an an error file is produced `max_samples_exceeded.error.txt`. [PR 191](https://github.com/phac-nml/mikrokondo/pull/191)

## [0.9.3] - 2025-09-12

### `Fixed`

- Locidex failures in due to incorrect container logic in IRIDANext. [PR 192](https://github.com/phac-nml/mikrokondo/pull/192)

## [0.9.2] - 2025-09-12

### `Updated`

- Updated locidex to version 0.4.0. [PR 189](https://github.com/phac-nml/mikrokondo/pull/189)

### `Changed`

- Renamed metadata field `TotalLoci` to `TotalLociInSchme`. [PR 189](https://github.com/phac-nml/mikrokondo/pull/189)

- Renamed metadata field `AllelesPresent` to `LociPresent`. [PR 189](https://github.com/phac-nml/mikrokondo/pull/189)

- Locidex default report mode is now `conservative` mode instead of normal. [PR 189](https://github.com/phac-nml/mikrokondo/pull/189)

### `Added`

- Metadata fields, `locidex_loci_no_blast_hit`, `locidex_loci_single_blast_hit`, `locidex_loci_with_mulitple_values`, `locidex_loci_no_nucleotide_hits` and `locidex_loci_no_protein_hits`. [PR 189](https://github.com/phac-nml/mikrokondo/pull/189)

## [0.9.1] - 2025-08-15

### `Fixed`

- Fixed issue with incorrect cardinality of elements passed to channel in hybrid assemblies. [PR 184](https://github.com/phac-nml/mikrokondo/pull/184)

## [0.9.0] - 2025-08-11

### `Changed`

- Changed default search parameter for **Escherichia coli** to **Escherichia**. [PR 181](https://github.com/phac-nml/mikrokondo/pull/181/files)

- Removed individual seven gene mlst results from IRIDANext config. [PR 180](https://github.com/phac-nml/mikrokondo/pull/180)

- `fastq_scan.py` script was refactored to reduce resource usage. [PR 179](https://github.com/phac-nml/mikrokondo/pull/179)

### `Fixed`

- Added missing `report_tag` value to `rasusa` in the `nextflow.config` file which was causing [Issue #182](https://github.com/phac-nml/mikrokondo/issues/182). [PR 181](https://github.com/phac-nml/mikrokondo/pull/181/files)

## [0.8.1] - 2025-07-04

### `Added`

- When `--skip_version_gathering` is `false`, a `{sample}.mikrokondo.parameters.json` and `{sample}.mikrokondo.software.version.yml` is generated. These files collect all the software versions used in the pipeline and the parameters selected. Note: Parameters are recorded at the pipeline level, individual sample parameters are not included.

## [0.8.0] - 2025-06-19

### `Changed`

- Added `predicted_primary_type_name`, `predicted_primary_type_method`, `predicted_secondary_type_name`, and `predicted_secondary_type_method` fields, which are output to Irida Next as `PrimaryTypeID`, `PrimaryTypeIDMethod`, `SecondaryTypeID`, and `SecondaryTypeIDMethod`, respectively. [PR 168](https://github.com/phac-nml/mikrokondo/pull/168)

## [0.7.1] - 2025-05-22

### `Changed`

- Fixed container string for `ectyper` docker and singularity containers. [PR 173](https://github.com/phac-nml/mikrokondo/pull/173)

## [0.7.0] - 2025-05-21

### `Changed`

- Renamed `n50 Status` and `n50 Value` to `qc_status_assembly_n50` and `n50_value` respectively. [PR 166](https://github.com/phac-nml/mikrokondo/pull/166)

- Added the ECTyper speciation results to shigella outputs. [PR 166](https://github.com/phac-nml/mikrokondo/pull/166)

### `Update`

- Update SISTR docker/singularity build (1->2). [PR 170](https://github.com/phac-nml/mikrokondo/pull/170)

- Update ECTyper docker/singularity build (3->4). [PR 170](https://github.com/phac-nml/mikrokondo/pull/170)

## [0.6.1] - 2025-04-28

### `Fixed`

- Updated new parameter positions in `nextflow_schema.json`

## [0.6.0] - 2025-04-25

### `Changed`

- Updated StarAMR to latest release v0.11.0 and modified tests to reflect new outputs. [PR 153](https://github.com/phac-nml/mikrokondo/pull/153)

- Changed the name of multiple metadata fields mentioned in [issue 148](https://github.com/phac-nml/mikrokondo/issues/148). [PR 159](https://github.com/phac-nml/mikrokondo/pull/159).

- Updated ECTyper to version 2.0.0 and SISTR to version 1.1.3 [PR 161](https://github.com/phac-nml/mikrokondo/pull/161).

- Shigella samples are now fed into ECTyper version 2.0.0 [PR 161](https://github.com/phac-nml/mikrokondo/pull/161).

### `Added`

- Added mikrokondo version to the output reports. [PR 160](https://github.com/phac-nml/mikrokondo/pull/160)

- Added new control flow parameter `fail_on_metagenomic` which prevents samples from undergoing additional downstream processing. [PR 158](https://github.com/phac-nml/mikrokondo/pull/158)

- Added additional logic for setting the `predicted_id` and `predicted_id_method` fields. [PR 159](https://github.com/phac-nml/mikrokondo/pull/159)

## [0.5.1] - 2025-02-25

### `Added`

- Added a configuration file `conf/equivalent_taxa.json` for denoting equivalent taxa to prevent falsely flagging samples as metagenomic when multiple genera are present. [PR 150](https://github.com/phac-nml/mikrokondo/pull/150)

## [0.5.0] - 2024-11-27

### `Added`

- Added RASUSA for down sampling of Nanopore or PacBio data. [PR 125](https://github.com/phac-nml/mikrokondo/pull/125)

- Added a new `sample_name` field to the `schema_input.json` file: [PR 140](https://github.com/phac-nml/mikrokondo/pull/140)

- Incorporated a `--skip_read_merging` parameter to prevent read merging [PR 140](https://github.com/phac-nml/mikrokondo/pull/140)

### `Changed`

- Added a `sample_name` field, `sample` still exists but is used to incorporate additional names/identifiers in IRIDANext [PR 140](https://github.com/phac-nml/mikrokondo/pull/140)

- RASUSA now used for down sampling of Nanopore or PacBio data. [PR 125](https://github.com/phac-nml/mikrokondo/pull/125)

- Default _Listeria_ quality control parameters apply only to _monocytogenes_ now. [PR 142](https://github.com/phac-nml/mikrokondo/pull/142)

### `Updated`

- Documentation and workflow diagram has been updated. [PR 123](https://github.com/phac-nml/mikrokondo/pull/123)

- Documentation and Readme has been updated. [PR 126](https://github.com/phac-nml/mikrokondo/pull/126)

- Adjusted `schema_input.json` to allow for non-gzipped inputs. [PR 137](https://github.com/phac-nml/mikrokondo/pull/137)

- Updated github actions workflows for nf-core version 3.0.1. [PR 137](https://github.com/phac-nml/mikrokondo/pull/137)

## [0.4.2] - 2024-09-25

### `Fixed`

- Fixed broken link in readme. [PR 117](https://github.com/phac-nml/mikrokondo/pull/117)

- Fixed ectyper parameter types in the `nextflow_schema.json` from `number` to `integer`. [PR 121](https://github.com/phac-nml/mikrokondo/pull/121)

## [0.4.1] - 2024-09-16

### `Fixed`

- Fixed null species ID in QCMessage when no organism qc data available. [PR 111](https://github.com/phac-nml/mikrokondo/pull/111)

### `Changed`

- Removed missing alleles from final report fixing issue [112](https://github.com/phac-nml/mikrokondo/issues/112).

- Changed default option for `override_allele_scheme` from `null` to "" (evaluates to false). [PR 109](https://github.com/phac-nml/mikrokondo/pull/109)

## [0.4.0] - 2024-09-04

### `Changed`

- Removed quay.io docker repo tags [PR 94](https://github.com/phac-nml/mikrokondo/pull/94)

### `Updated`

- Added QCMessage and QCSummary fields for metagenomic sequencing runs. See [PR 103](https://github.com/phac-nml/mikrokondo/pull/103)

- Updated TSeemann's MLST default container to use version 2.23.0 of `mlst`. See [PR 97](https://github.com/phac-nml/mikrokondo/pull/97)

- Moved allele schema parameters under one option in the nextflow_schema.json. See [PR 104](https://github.com/phac-nml/mikrokondo/pull/104)

### `Fixed`

- Fixed typo in metagenomic QC message. See [PR 103](https://github.com/phac-nml/mikrokondo/pull/103)

- Fixed spelling issues issues in config values. See [PR 95](https://github.com/phac-nml/mikrokondo/pull/95)

- Fixed the headers specified in the nextflow.config file for Kraken2. See [PR 96](https://github.com/phac-nml/mikrokondo/pull/96)

### `Added`

- Added additional organism QC parameters to defaults. See [PR 105](https://github.com/phac-nml/mikrokondo/pull/105)

- Updated locidex to version 0.2.3. See [PR 96](https://github.com/phac-nml/mikrokondo/pull/96)

- Added module for automatic selection of locidex databases through configuration of a locidex database collection. See [PR 96](https://github.com/phac-nml/mikrokondo/pull/96)

- Added module for summary of basic allele metrics, listing of missing alleles and reporting of specific alleles. See [PR 96](https://github.com/phac-nml/mikrokondo/pull/96)

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

[0.9.4]: https://github.com/phac-nml/mikrokondo/releases/tag/0.9.4
[0.9.3]: https://github.com/phac-nml/mikrokondo/releases/tag/0.9.3
[0.9.2]: https://github.com/phac-nml/mikrokondo/releases/tag/0.9.2
[0.9.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.9.1
[0.9.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.9.0
[0.8.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.8.1
[0.8.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.8.0
[0.7.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.7.1
[0.7.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.7.0
[0.6.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.6.1
[0.6.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.6.0
[0.5.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.5.1
[0.5.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.5.0
[0.4.2]: https://github.com/phac-nml/mikrokondo/releases/tag/0.4.2
[0.4.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.4.1
[0.4.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.4.0
[0.3.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.3.0
[0.2.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.2.1
[0.2.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.2.0
[0.1.2]: https://github.com/phac-nml/mikrokondo/releases/tag/0.1.2
[0.1.1]: https://github.com/phac-nml/mikrokondo/releases/tag/0.1.1
[0.1.0]: https://github.com/phac-nml/mikrokondo/releases/tag/0.1.0
