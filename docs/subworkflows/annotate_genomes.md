# Genome Annotation

## subworflows/local/annotate_genomes

## Steps
1. **Genome annotation** is performed using [Bakta](https://github.com/oschwengers/bakta) (bakta_annotate.nf).

>NOTE:  
>A custom database for Bakta can be downloaded via the commandline using `bakta_download_db.nf`.  
>The `bakta_db` setting can be changed in the `nextflow.config` file, see 'Changing Pipeline settings' <!-- need to link that page here, also check the name of that setting -->

## Input
- contigs and metadata

## Output
- All associated Bakta outputs
- software versions
