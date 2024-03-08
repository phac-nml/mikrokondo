# FAQ

## How is variable type determined from command line parameters?

In a situation where you are developing the pipeline or finding that the parameter passed on the command line is not working as expected, for example, example: the user wants a sample to have at least 1000 reads before going for assembly (`--min_reads 1000`) and samples with less than 1000 reads are passing onto the assembly step.

The way a variable type is determined from the command line can be found in the below [groovy code](https://github.com/nextflow-io/nextflow/blob/8c0566fc3a35c8d3a4e01a508a0667e471bab297/modules/nextflow/src/main/groovy/nextflow/cli/CmdRun.groovy#L506-L518). The snippet is also pasted below and is up to date as of 2023-10-16:

```
    static protected parseParamValue(String str ) {

        if ( str == null ) return null

        if ( str.toLowerCase() == 'true') return Boolean.TRUE
        if ( str.toLowerCase() == 'false' ) return Boolean.FALSE

        if ( str==~/\d+(\.\d+)?/ && str.isInteger() ) return str.toInteger()
        if ( str==~/\d+(\.\d+)?/ && str.isLong() ) return str.toLong()
        if ( str==~/\d+(\.\d+)?/ && str.isDouble() ) return str.toDouble()

        return str
    }
```

# Troubleshooting

## Common errors and how to (maybe) fix them

### null errors, or report generation failing on line 701

Currently there are compatibility issues between version 22 and 23.10.0 of nextflow with regards to parsing the `nextflow.config` file. I am currently working on addressing them now. if you happen to encounter issues please downgrade your nextflow install to 22.10.1.

### Permission denied on a python script (`bin/some_script.py`)

On some installs, a lack of permissions for python scripts are causing this error to occur. The easiest way to solve this issue is to execute `chmod +x bin/*.py` in the mikrokondo installation directory. This will add execution permissions to all of the scripts, if this solution does not work then please submit an issue.

### Random issues containing on resume `org.iq80.leveldb.impl.Version.retain()`

Sometimes the resume features of Nextflow don't work completely. The above error string typically implies that some output could not be gathered from a process and on subsequent resumes you will get an error. You can find out what process (and its work directory location) caused the error in the `nextflow.log` (normally it will be at the top of some long traceback in the log), and a work directory will be specified listing the directory causing the error. Delete this directory and resume the pipeline. **If you hate logs and you don't care about resuming** you can simply delete the work directory entirely.


### StarAMR

- Exit code 1, and an error involving ` stderr=FASTA-Reader: Ignoring invalid residues at position(s):`
  - This is likely not a problem with your data but with your databases, following the instructions listed [here](https://github.com/phac-nml/staramr/issues/200#issuecomment-1741082733) should fix the issue.
  - The command to download the proper databases mentioned in the issue is listed here: 
  `staramr db build --dir staramr_databases --resfinder-commit fa32d9a3cf0c12ec70ca4e90c45c0d590ee810bd --pointfinder-commit 8c694b9f336153e6d618b897b3b4930961521eb8 --plasmidfinder-commit c18e08c17a5988d4f075fc1171636e47546a323d`
  - **Passing in a database is optional as the one within the container will be used by default.**
  - If you continue to have problems with StarAMR you can skip it using `--skip_staramr`


### Common mash errors

- Mash exit code 139 or 255, you may see `org.iq80.leveldb.impl.Version.retain()` appearing on screen as well.
  - This indicates a segmentation fault, due to mash failing or alternatively some resource not being available. If you see that mash has run properly in the work directory output but Nextflow is saying the process failed and the `versions.yml` file is missing you likely have encountered some resource limit on your system. A simple solution is likely to reduce the number of `maxForks` available to the different Mash processes in the `conf/modules.config` file. Alternatively you may need to alter the number in some Nextflow environment variables e.g. `OMP_NUM_THREADS`, `USE_SIMPLE_THREADED_LEVEL3` and `OPENBLAS_NUM_THREADS`.

### Common spades issues

- Spades exit code 21
  - One potential cause of this issue (requires looking at the log files) is due to not enough reads being present. You can avoid samples with too few reads going to assembly by adjusting the `min_reads` parameter in the `nextflow.config`. It can also be adjusted from the command line with the flag `--min_reads 1000`

- Spades exit code 245
  - This could be due to multiple issues and typically results from a segmentation fault (OS Code 11). Try increasing the amount of memory spades is alloted ([base.config](https://github.com/phac-nml/mikrokondo/blob/main/conf/base.config)) if the issue persists try using a different Spades container/ create an issue.

### Common Kraken2 issues

- Kraken2 exit code 2
  - It is still a good idea to look at the output logs to verify your issue as they may say something like: `kraken2: database ("./kraken2_database") does not contain necessary file taxo.k2d` despite the taxo.k2d file being present. This is potentially caused by symlink issues, and one possible fix is to provide the absolute path to your Kraken2 database in the [nextflow.config](https://github.com/phac-nml/mikrokondo/blob/main/nextflow.config) or from the command line `--kraken.db /PATH/TO/DB`


### Common Docker issues

- Exit code 137:
  - Exit code 137, likely means your docker container used to much memory. You can adjust how much memory each process gets in the [base.config](https://github.com/phac-nml/mikrokondo/blob/main/conf/base.config) file, however there may be some underlying configuration you need to perform for Docker to solve this issue.

### CheckM fails

- CheckM exit code 1, could not find concatenated.tree or concatentated.pplacer.json
  - This is a sign that CheckM has run out of memory, make sure you are using your desired executor. You may need to adjust configuration settings.

### QUAST fails with a read-only error

- `[Errno 30] Read-only file system: '/usr/local/lib/python3.9/site-packages/quast_libs/gridss'`
  - This issue appears to be related to QUAST trying to download GRIDSS for structural variant detection and this action being incompatible with the container used to run QUAST. You may be able to resolve this be adding `--no-sv` as a QUAST command-line flag in Mikrokondo's `nextflow.config`, or by switching your container platform to singularity. Errors were observed with `apptainer version 1.2.3`, which were resolved by switching to singularity (`singularity-ce version 3.9.5` and `singularity-ce version a948062` resolved the issue).
