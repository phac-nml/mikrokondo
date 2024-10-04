# Installation

## Dependencies
- Python (3.10>=)
- Nextflow (22.10.1>=)
- Container service (Docker, Singularity, Apptainer have been tested)
- The source code: `git clone https://github.com/phac-nml/mikrokondo.git`

**Dependencies can be installed with Conda (e.g. Nextflow and Python)**.

## To install mikrokondo
Once all dependencies are installed (see below for instructions), to download the pipeline run:

`git clone https://github.com/phac-nml/mikrokondo.git`

## Installing Nextflow
Nextflow is required to run mikrokondo (requires Linux), and instructions for its installation can be found at either: [Nextflow Home](https://www.nextflow.io/) or  [Nextflow Documentation](https://www.nextflow.io/docs/latest/getstarted.html#installation)

## Container Engine
Nextflow and Mikrokondo require the use of containers to run the pipeline, such as: Docker, Singularity (now apptainer), podman, gitpod, sifter and charliecloud.

> **NOTE:** Singularity was adopted by the Linux Foundation and is now called Apptainer. Singularity still exists, however newer installs will likely use Apptainer.

## Docker or Singularity?
Docker requires root privileges which can can make it a hassle to install on computing clusters, while there are workarounds, Apptainer/Singularity does not. Therefore, using Apptainer/Singularity is the recommended method for running the mikrokondo pipeline.

### Issues
Containers are not perfect, below is a list of some issues you may face using containers in mikrokondo, fixes for each issue will be detailed here as they are identified.

- **Exit code 137,** usually means the docker container used to much memory.

## Resources to download
- [GTDB Mash Sketch](https://zenodo.org/record/8408361): required for speciation and determination when sample is metagenomic
- [Decontamination Index](https://zenodo.org/record/8408557): Required for decontamination of reads (this is a minimap2 index)
- [Kraken2 std database](https://benlangmead.github.io/aws-indexes/k2): Required for binning of metagenomic data and is an alternative to using Mash for speciation
- [Bakta database](https://zenodo.org/record/7669534): Running Bakta is optional and there is a light database option, however the full one is recommended. You will have to unzip and un-tar the database for usage.

### Fields to update with resources
It is recommended to store the above resources within the `databases` folder in the mikrokondo folder, this allows for a simple update to the names of the database in `nextflow.config` rather than a need for a full path description.

Below shows where to update database resources in the `params` section of the `nextflow.config` file:

```
// Bakta db path, note the quotation marks
bakta_db = "/PATH/TO/BAKTA/DB"

// Decontamination minimap2 index, note the quotation marks
dehosting_idx = "/PATH/TO/DECONTAMINATION/INDEX"

// kraken db path, not the quotation marks
kraken2_db = "/PATH/TO/KRAKEN/DATABASE/"

// GTDB Mash sketch, note the quotation marks
mash_sketch = "/PATH/TO/MASH/SKETCH/"

```
