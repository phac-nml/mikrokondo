# FAQ

## How is variable type determined from command line parameters?

This may be a weird thing to but in the docs, but if you are developing the pipeline or somehow finding that a parameter passed on the command line is not working properly. For example you want a sample to have at least 1000 reads before going for assembly (`--min_reads 1000`) and samples with only one read are being assembled this may the source of your issue.

The way a variable type is determined from the command line can be found in the following [groovy code](https://github.com/nextflow-io/nextflow/blob/8c0566fc3a35c8d3a4e01a508a0667e471bab297/modules/nextflow/src/main/groovy/nextflow/cli/CmdRun.groovy#L506-L518). The snippet is also pasted below and is up to date as of 2023-10-16:

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

## Common errors and how to encounter them

### Troubleshooting

Common errors and potential fixes for modules will be detailed here.

### Common spades issues

- Spades exit code 21
  - One potential cause of this issue (requires looking at the log files) is due to not enough reads being present. You can avoid samples with too few reads going to assembly by adjusting the `min_reads` parameter in the `nextflow.config`. It can also be adjusted from the command line like so `--min_reads 1000`

- Spades exit code 245
  - This could be due to multiple issues and typically results from a segmentation fault (OS Code 11). Try increasing the amount of memory spades (`conf/base.config`) if the issue persists try using a different Spades container/ create an issue.

### Common Kraken2 issues

- Kraken2 exit code 2
  - It is still a good idea to look at the output logs to verify your issue as they may say something like: `kraken2: database ("./kraken2_database") does not contain necessary file taxo.k2d` despite the taxo.k2d file being present. This is potentially caused by symlink issues, and one possible fix is too to provide the absolute path to your Kraken2 database in the `nextflow.config` or from the command line `--kraken.db /PATH/TO/DB`


### Common Docker issues

- Exit code 137:
  - Exit code 137, likely means your docker container used to much memory. You can adjust how much memory each process gets in the `conf/base.config` file, however there may be some underlying configuration you need to perform for Docker to solve this issue.

