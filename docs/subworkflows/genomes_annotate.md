# Genome Annotation

## subworkflows/local/annotate_genomes

## Steps
1. **Genome annotation** is performed using [Bakta](https://github.com/oschwengers/bakta) within [bakta_annotate.nf](https://github.com/phac-nml/mikrokondo/blob/main/modules/local/bakta_annotate.nf)

    - You must download a Bakta database and add its path to the [nextflow.config](https://github.com/phac-nml/mikrokondo/blob/main/nextflow.config) file or add its path as a command line option
    - To skip running Bakta add `--skip_bakta true` to your command line options.

2. **Screening for antimicrobial resistance** [Abricate](https://github.com/tseemann/abricate) is used with the default options and default database, however you can specify a database by updating the `args` in the [nextflow.config](https://github.com/phac-nml/mikrokondo/blob/main/nextflow.config) for Abricate.

    - You can skip running Abricate by adding `--skip_abricate true` to your command line options.

3. **Screening for plasmids** is performed using [Mob-suite](https://github.com/phac-nml/mob-suite) with default options.

4. **Selection of Pointfindr database**. This step is only ran if running [StarAMR](https://github.com/phac-nml/staramr). It will try and select the correct database based on the species identified earlier in the pipeline. If a database cannot be determined pointfinder will simply not be run.

5. **Exporting of StarAMR databases used**. To provide a method of user validation for automatic database selection, the database info from StarAMR will be exported from the pipeline into the file `StarAMRDBVersions.txt` and placed in the StarAMR directory.

6. **Screening for antimicrobial resistance** with **StarAMR**. [StarAMR](https://github.com/phac-nml/staramr) is provided as an additional option to screen for antimicrobial resistance in ResFinder, PointFinder and PlasmidFinder databases. Passing in a database is optional as the one within the container will be used by default.
    - You can skip running StarAMR by adding the following flag `--skip_starmar`

>NOTE:
>A custom database for Bakta can be downloaded via the commandline using `bakta_download_db.nf`.
>The `bakta_db` setting can be changed in the `nextflow.config` file, see [bakta](/usage/tool_params/#bakta)

## Input
- Contig file (fasta) from the `FinalAssembly` dir
    - This is the final contig file from the last step in the CleanAssemble workflow (taking into account any skip flags that have been used)
- metadata from prior tools

## Output
- Assembly
    - Annotation
        - Abricate
        - Mobsuite
            - recon
                - SAMPLE
        - StarAMR
            - SAMPLE
