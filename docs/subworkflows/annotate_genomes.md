# Genome Annotation

## subworflows/local/annotate_genomes

## Steps
1. **Genome annotation** is performed using [Bakta](https://github.com/oschwengers/bakta) [Bakta](bakta_annotate.nf), you must download a Bakta database and add its path to the `nextflow.config` file or add its path as a command line option. To skip running Bakta add `--skip_bakta true` to your command line options.
2. **Screening for antimicrobial resistance** with **Abricate**. [Abricate](https://github.com/tseemann/abricate) is used with the default options and default database, however you can specify a database by updating the `args` in the `nextflow.config` for Abricate. You can also skip running Abricate by adding `--skip_abricate true` to your command line options.
3. **Screening for plasmids** is performed using [Mob-suite](https://github.com/phac-nml/mob-suite) with default options.
2. **Selection of Pointfindr database**. This step is only ran if running [StarAMR](https://github.com/phac-nml/staramr). It will try and select the correct database based on the species identified earlier in the pipeline. If a database cannot be determined pointfinder will simply not be run.
3. **Exporting of StarAMR databases used**. The database info from StarAMR will be exported from the pipeline into a file and copied into the StarAMR directory **so that you can** validate the correct database has been used.
4. **Screening for antimicrobial resistance** with **StarAMR**. [StarAMR](https://github.com/phac-nml/staramr) is provided as an additional option to screen for antimicrobial resistance in ResFinder, PointFinder and PlasmidFinder databases. Passing in a database is optional as the one within the container will be used by default.

>NOTE:
>A custom database for Bakta can be downloaded via the commandline using `bakta_download_db.nf`.
>The `bakta_db` setting can be changed in the `nextflow.config` file, see 'Changing Pipeline settings' <!-- need to link that page here, also check the name of that setting -->

## Input
- contigs and metadata

## Output
- All associated Bakta outputs
- software versions
