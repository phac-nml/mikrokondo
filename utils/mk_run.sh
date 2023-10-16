#! /usr/bin/env bash

#### Initialize an environment up here, e.g. initialize conda if needed


#### Specify singularity cache path
export NXF_SINGULARITY_CACHEDIR=/PATH/TO/SINGULARITY/CACHE

export OMP_NUM_THREADS=32
export USE_SIMPLE_THREADED_LEVEL3=32
export OPENBLAS_NUM_THREADS=1


#### Specify path to where pipeline is downloaded too
WORKFLOW_DIR=/PATH/TO/PIPELINE/INSTALL

#### Specify any othe constants you would like to pass here
#### e.g. anything you would not like to hard code into your config file


#### '#' indicate required arguments
#### If you have any required arguments, create a variable initialized to `#` here
INPUT_SHEET="#"
OUTDIR="#"
PLATFORM="#"



##### Checks to make sure required arguments are passed
# first arg is variable to check, second is the string to print to indicate missing value
check_arg(){
    if [ "$1" = "#"  ]
    then
        echo "Missing argument for" "$2"
        Help
        exit
    fi
}


### Help message function
Help(){
    echo "-i | --input_sheet: input sheet of samples"
    echo "-o | --output-directory: output directory"
    echo "-p | --platform: The sequencing platform used e.g. illumina, nanopore, pacbio, hybrid"
    echo "-h | --help: Print this message and exit"
    exit 1
}

#### Command line parser, you can add options below
while true;
do
    case "$1" in
        -i | --input-sheet) INPUT_SHEET=$2; shift 2;;
        -o | --output-directory) OUTDIR=$2; shift 2;;
        -p | --platform); PLATFORM=$2; shift 2;;
        -h | --help) Help exit;; # `Help` refers to the help function above
        -- ) shift; break;;
        *) break;;
    esac
done


check_arg ${INPUT_SHEET} "--input-sheet"
check_arg ${OUTDIR} "--output-directory"

# Place to create a log file
LOG_OUT=$(dirname ${INPUT_SHEET} | xargs realpath | xargs dirname)
# Where to create nextflow work directory
export NXF_WORK=${OUTDIR}/work

# ~~~~~~~~~~~~~~~~ Create a command to run here ~~~~~~~~~~~~~~~~~~~~~
#### Update nextflow CLI as needed
# nextflow -log ${LOG_OUT} run ${WORKFLOW_DIR} --input ${INPUT_SHEET} --outdir ${OUTDIR} --platform illumina -profile singularity
#### e.g. a nanopore command
# nextflow -log ${LOG_OUT} run ${WORKFLOW_DIR} --input ${INPUT_SHEET} --outdir ${OUTDIR} --platform nanopore --nanopore_chemistry SOME_MEDAKA_MODLE -profile singularity
nextflow -log ${LOG_OUT} run ${WORKFLOW_DIR} --input ${INPUT_SHEET} --outdir ${OUTDIR} --platform $PLATFORM -profile singularity
