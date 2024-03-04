# mk-kondo/mikrokondo: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0dev - [date]

Initial release of mk-kondo/mikrokondo, created with the [nf-core](https://nf-co.re/) template.

### `Added`

Upgraded nf-validation to latest version 2.0.0

Added message to final summary report notifying user if an assembly does not have any contigs exceeding the minimum contig length parameter

Added contig count check before running Quast to ensure empty files are not passed in.

Added process to filter contigs based on a minimum required contig length.

Added option to force sample to be implemented as an isolate

Changed salmonella default default coverage to 40

Added integration testing using [nf-test](https://www.nf-test.com/).

### `Fixed`

### `Dependencies`

### `Deprecated`
