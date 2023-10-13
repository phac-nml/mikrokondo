# Genome Annotation

## subworflows/local/annotate_genomes

## Steps
1. **Genome annotation** is performed using [Bakta](https://github.com/oschwengers/bakta) [Bakta](bakta_annotate.nf), you must download a Bakta database and add its path to the `nextflow.config` file or add its path as a command line option. To skip running Bakta add `--skip_bakta true` to your command line options.
2. **Screening for antimicrobial resistance** with **Abricate**. Abricate [Abricate](https://github.com/tseemann/abricate) is used with the default options and default database, however you can specify a database by updating the `args` in the `nextflow.config` for Abricate. You can also skip running Abricate by adding `--skip_abricate true` to your command line options.

>NOTE:
>A custom database for Bakta can be downloaded via the commandline using `bakta_download_db.nf`.
>The `bakta_db` setting can be changed in the `nextflow.config` file, see 'Changing Pipeline settings' <!-- need to link that page here, also check the name of that setting -->

## Input
- contigs and metadata

## Output
- All associated Bakta outputs
- software versions
