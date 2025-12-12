# Configuration

## Configuration files overview

The following files contain configuration settings:

- `conf/base.config`: Where cpu, memory and time parameters can be set for the different workflow processes. **You will likely need to adjust parameters within this file for your computing environment**.

- `conf/modules.config`: contains error strategy, output director structure and execution instruction parameters. **It is unadvised to alter this file unless involved in pipeline development, or tuning to a system.**

- `conf/equivalent_taxa.json`: Contains a set of keys to arrays containing the query notes from the mash sketch denoting "equivalent taxa". This typically contains a list of organisms that are genetically similar but phenotypically distinct, as mobile elements or genome segments may be shared across organisms. e.g. _Shigella_ and _Escherichia_

- `nextflow.config`: contains default tool settings that tie to CLI options. These options can be directly set within the `params` section of this file in cases when a user has optimized their pipeline usage and has identified the flags they will use every time the pipeline is run.

### Base configuration (conf/base.config)

Within this file computing resources can be configured for each process. Mikrokondo uses labels to define resource requirements for each process, here are their definitions:

- `process_single`: processes requiring only a single core and low memory (e.g., listing of directories).
- `process_low`: processes that would typically run easily on a small laptop (e.g., staging of data in a Python script).
- `process_medium`: processes that would typically run on a desktop computer equipped for playing newer video games (Memory or computationally intensive applications that can be parallelized, e.g., rendering, processing large files in memory or running BLAST).
- `process_high`: processes that would typically run on a high performance desktop computer (Memory or computationally intensive application, e.g., performing _de novo_ assembly or performing BLAST searches on large databases).
- `process_long`: modifies/overwrites the amount of time allowed for any of the above processes to allow for certain jobs to take longer (e.g., performing _de novo_ assembly with less computational resources or performing global alignments on divergent sequences).
- `process_high_memory`: modifies/overwrites the amount of memory given to any process and grant significantly more memory to any process (Aids in metagenomic assembly or clustering of large datasets).

For actual resource amounts allotted to each process definition, see the `conf/base.config` file _Process-specific resource requirements_ section.

### Hardcoded tool configuration (nextflow.config)

All Command line arguments and defaults can be set and/or altered in the `nextflow.config` file, _params_ section. For a full list of parameters to be altered please refer to the `nextflow.config` file in the repo. Some common arguments have been listed in the [Common command line arguments](/usage/useage/#common-command-line-arguments) section of the docs and further description of tool parameters can also be found in [tool specific parameters](/usage/tool_params/).

> **Example:** if your laboratory typically sequences using Nanopore chemistry "r1041_e82_400bps_hac_v4.2.0", the following code would be substituted in the _params_ section of the `nextflow.config` file:
>
> ```
> nanopore_chemistry = "r1041_e82_400bps_hac_v4.2.0" // Note the quotes around the value
> ```
>
> With this change, you would no longer need to explicitly state the nanopore chemistry as an extra CLI argument when running mikrokondo.

## Quality control report configuration

> **WARNING:** Tread carefully here, as this will require modification of the `nextflow.config` file. **Make sure you have saved a back up of your `nextflow.config` file before playing with these option**

### QCReport field description

The section of interest is the `QCReport` fields in the params section of the `nextflow.config`. There are multiple sections with values that can be modified or you can add data for a different organism. The default values in the pipeline are set up for **Illumina data** so you may need to adjust settingS for Nanopore or Pacbio data.

> **WARNING:** It is best to only add `QCReport` values to mikrokondo, not remove existing ones as this may raise errors in the subtyping module.

An example of the QCReport structure is shown below. With annotation describing the values.

> **NOTE:** The values below do not affect the running of the pipeline, these values only affect the final quality messages output by the pipeline.

> **NOTE:** The term JSON path is used below to indicate the ordered set of keys required to reach a particular value in an aggregated JSON file created by mikrokondo. For example if you wished to specify the JSON path to the ECTyper species identification in mikrokondo you would enter `["ECTyperSubtyping", "0", "Species"]` as the JSON path which would point to a samples ECTyper speciation field in the following JSON structure from the `final_report.json` file generated by mikrokondo:

```
  "ECTyperSubtyping": {
    "0": {
      "Species": "Escherichia coli"
    }
  }
```

If you need to find a the JSON path required to point to a value, you can either look at the sample JSON output in `FinalReports/Aggregated/Json/final_report.json` file generated by mikrokondo to determine the required sequence of keys. However it is simpler to find the required JSON path value by looking in the `FinalReports/Sample/Json/final_report_flattened.json` file where you will see the key path listed and delimited by '.' e.g. `ECTyperSubtyping.0.Species` which would be re-written as `["ECTyperSubtyping, "0", "Species"]`.

```
QCReport {
    escherichia // Generic top level name fo the field, it is name is technically arbitrary but it nice field name keeps things organized
    {
        search = "Escherichia" // The phrase that is searched for in the species_top_hit field mentioned above. The search is for containment so if you wanted to look for E.coli and E.albertii you could just set the value to "Escherichia coli" or "Escherichia albertii"
        raw_average_quality = 30 // Minimum raw average quality of all bases in the sequencing data. This value is generated before the decontamination procedure.
        min_n50 = 95000 // The minimum n50 value allowed from quast
        max_n50 = 6000000 // The maximum n50 value allowed from quast
        min_nr_contigs = 1 // the minimum number of contigs a sample is allowed to have, a value of 1 works as a sanity check
        max_nr_contigs = 500 // The maximum number of contigs the organism in the search field is allowed to have. to many contigs could indicate a bad assembly or contamination
        min_length = 4500000 // The minimum genome length allowed for the organism specified in the search field
        max_length = 6000000 // The maximum genome length the organism in the search field is allowed to have
        max_checkm2_contamination = 3.0 // The maximum level of allowed contamination allowed by CheckM2
        min_average_coverage = 30 // The minimum average coverage allowed
        min_wgmlst_loci: The minimum number of wgMLST loci required per a sample
        min_illumina_read_length: The lowest mean illumina read length you can tolerated for your data
        max_illumina_read_length: The highest mean illumina read length you can tolerate for your sample
        min_long_read_length: The minimum mean read length allowed for long read data like pacbio and nanopore

        // If you wish to make use of IDField and IDTool you will need to set both values
        IDField = null // null|JSON path to relevant file results if null the mash or kraken2 results will be used
        IDTool = null // null|tool name used to create file result if null mash or kraken2 will be written
        // If PrimaryTypeID is set PrimaryTypeIDMethod must be as well
        PrimaryTypeID: null|JSON Path, Optional primary type to have displayed e.g. serotype
        PrimaryTypeIDMethod: null|String, Method used for Primary type e.g. ECTyper
        // If SecondaryTypeID is set SecondaryTypeIDMethod must be as well
        SecondaryTypeID: null|JSON Path, Secondary type information e.g. Clonal Complex
        SecondaryTypeIDMethod: null|String, method used for secondary type information e.g. 7 Gene
    }
    // DO NOT REMOVE THE FALLTRHOUGH FIELD AS IT IS NEEDED TO CAPTURE OTHER ORGANISMS
    fallthrough // The fallthrough field exist as a default value to capture organisms where no quality control data has been specified
    {
        search = "No organism specific QC data available."
        raw_average_quality = 30
        min_n50 = null
        max_n50 = null
        min_nr_contigs = null
        max_nr_contigs = null
        min_length = null
        max_length = null
        max_checkm2_contamination = 3.0
        min_average_coverage = 30
        min_illumina_read_length = 120
        max_illumina_read_length = 300 
        min_long_read_length = 300
        IDField = null
        IDTool = null
        PrimaryTypeID = null
        PrimaryTypeIDMethod = null
        SecondaryTypeID = null
        SecondaryTypeIDMethod = null
    }
}
```

### Example adding quality control data for _Salmonella_

If you wanted to add quality control data for _Salmonella_ you can start off by using the template below:

```
VAR_NAME { // Replace VAR name with the genus name of your sample, only use ASCII (a-zA-Z) alphabet characters in the name and replace spaces, punctuation and other special characters with underscores (_)
    search = "Search phrase" // Search phrase for your species top_hit, Note the quotes
    raw_average_quality = // 30 is a default value please change it as needed
    min_n50 = // Set your minimum n50 value
    max_n50 = // Set a maximum n50 value
    min_nr_contigs = // Set a minimum number of contigs
    max_nr_contigs = // The maximum number of contigs
    min_length = // Set a minimum genome length
    max_length = // set a maximum genome length
    max_checkm2_contamination = // Set a maximum level of contamination to use
    min_average_coverage = // Set the minimum coverage value
    IDField = null // Set a Json path found in the flattened report generated by mikrokondo to your tool result
    IDTool = null // Set a custom name for the ID method you want to set
}
```

For _Salmonella_ I would fill in the values like so.

```
salmonella {
    search = "Salmonella"
    raw_average_quality = 30
    min_n50 = 95000
    max_n50 = 6000000
    min_nr_contigs = 1
    max_nr_contigs = 200
    min_length = 4400000
    max_length = 6000000
    max_checkm2_contamination = 3.0
    min_average_coverage = 30
    IDField = [params.sistr.report_tag, "0", "Serovar"]
    IDTool = "SISTR"
}
```

After having my values filled out, I can simply add them to the QCReport section in the `nextflow.config` file.

```
    QCReport {
        escherichia {
            search = "Escherichia coli"
            raw_average_quality = 30
            min_n50 = 95000
            max_n50 = 6000000
            min_nr_contigs = 1
            max_nr_contigs = 500
            min_length = 4500000
            max_length = 6000000
            max_checkm2_contamination = 3.0
            min_average_coverage = 30
        } salmonella { // NOTE watch the opening and closing brackets
            search = "Salmonella"
            raw_average_quality = 30
            min_n50 = 95000
            max_n50 = 6000000
            min_nr_contigs = 1
            max_nr_contigs = 200
            min_length = 4400000
            max_length = 6000000
            max_checkm2_contamination = 3.0
            min_average_coverage = 30
        }
        fallthrough {
            search = "No organism specific QC data available."
            raw_average_quality = 30
            min_n50 = null
            max_n50 = null
            min_nr_contigs = null
            max_nr_contigs = null
            min_length = null
            max_length = null
            max_checkm2_contamination = 3.0
            min_average_coverage = 30
        }
    }
```

## Quality Control Fields

This section affects the behavior of the final summary quality control messages and is noted in the `QCReportFields` within the `nextflow.config`. **I would advise against manipulating this section unless you really know what you are doing**.

Each value in the QC report fields contains the following fields.

- Field name
  - path: path to the information in the summary report JSON
  - coerce_type: Type to be coerced too, can be a Float, Integer, or Bool
  - compare_fields: A list of fields corresponding to fields in the `QCReport` section of the `nextflow.config`. If two values are specified it will be assumed you wish to check that a value is in between a range of values.
  - comp_type: The comparison type specified, 'ge' for greater or equal, 'le' for less than or equal, 'bool' for true or false or 'range' for checking if a value is between two values.
  - on: A boolean value for disabling a comparison
  - low_msg: A message for if a value is less than its compared value (optional)
  - high_msg: A message for if value is above a certain value (optional)

An example of what these fields look like is:

```
QCReportFields {
    raw_average_quality {
        path = [params.raw_reads.report_tag, "combined", "qual_mean"]
        coerce_type = 'Float'
        compare_fields = ['raw_average_quality']
        comp_type = "ge"
        on = true
        low_msg = "Base quality is poor, resequencing is recommended."
    }
}
```

## Locidex Manifest File

Automated selection allele calling databases is supported within mikrokondo. This is accomplished with the help of Locidex itself, which offers a utility to generate a `manifest.json` file.

The directory of a database set for Locidex contains the following structure as the `manifest.json` keeps track of the paths relative too the location of the manifest file itself:

```
--|
  |- Database 1
  |- Database 2
  |- Database n
  |- manifest.json
```

An example `manifest.json` file can be found in the mikrokondo [test data sets here](https://github.com/phac-nml/mikrokondo/tree/main/tests/data/databases/locidex_dbs).

Internally the `manifest.json` contains the following structure. Modifications to what `locidex manifest` outputs can be made as long as all fields populated. In the below example the `manifest.json` file generated by locidex has been modified to create two separate entries for _Escherichia coli_ and _Shigella_.

```
{
  "Salmonella": [
    {
      "path": "wgmlst_salmonella",
      "config": {
        "db_name": "Salmonella",
        "db_version": "1.0.0",
        "db_date": "2024-03-17",
        "db_author": "Tester",
        "db_desc": "Salmonella Database",
        "db_num_seqs": 51251,
        "is_nucl": true,
        "is_prot": true,
        "nucleotide_db_name": "nucleotide",
        "protein_db_name": "protein"
      }
    }
  ],
  "Escherichia coli": [
    {
      "path": "wgmlst_escherichia_shigella",
      "config": {
        "db_name": "EC and Shigella",
        "db_version": "1.0.0",
        "db_date": "2024-04-30",
        "db_author": "Tester",
        "db_desc": "Shigella and E.coli",
        "db_num_seqs": 57692,
        "is_nucl": true,
        "is_prot": true,
        "nucleotide_db_name": "nucleotide",
        "protein_db_name": "protein"
      }
    }
  ],
  "Shigella": [
    {
      "path": "wgmlst_escherichia_shigella",
      "config": {
        "db_name": "EC and Shigella",
        "db_version": "1.0.0",
        "db_date": "2024-04-30",
        "db_author": "Tester",
        "db_desc": "Shigella and E.coli",
        "db_num_seqs": 57692,
        "is_nucl": true,
        "is_prot": true,
        "nucleotide_db_name": "nucleotide",
        "protein_db_name": "protein"
      }
    }
  ],
  "Listeria Monocytogenes": [
    {
      "path": "wgmlst_listeria",
      "config": {
        "db_name": "Listeria Monocytogenes wgMLST",
        "db_version": "1.0.0",
        "db_date": "2024-04-16",
        "db_author": "Tester",
        "db_desc": "Listeria Monocytogenes wgMLST",
        "db_num_seqs": 22404,
        "is_nucl": true,
        "is_prot": true,
        "nucleotide_db_name": "nucleotide",
        "protein_db_name": "protein"
      }
    }
  ]
}
```

### How automated selection works

Mikrokondo is able to identify the species that a sample represents internally, but in order to identify the correct WgMLST scheme to use for allele calling the top-level key in the `manifest.json` file must be a name that can be parsed from the speciation output of Mash or Kraken2 e.g. _Salmonella enterica_, _Campylobacter_A anatolicus_, _Escherichia_ etc.

> **Note:** The database and organism names are not case sensitive.

Mikrokondo will then be able to match the bacterial name outputs to what is in the `manifest.json`. In the following example below the three bacteria (_Salmonella enterica_, _Campylobacter_A anatolicus_, _Escherichia coli_) would all be matched to the correct scheme:

```
{
  "Salmonella": [
    ...
  ],
  "Escherichia coli": [
    ...
  ],
  "Campylobacter": [
    ...
  ]
}
```

This is because mikrokondo looks for the best exact match from the database names in the output species name. So spurious tokens like the `_A` in _Campylobacter_A anatolicus_ would be removed and the `Campylobacter` database would be selected. For Salmonella, as the key value `Salmonella` overlaps entirely with the _Salmonella_ of _Salmonella enterica_ the Salmonella database would be selected. If There was a `Salmonella Enterica` database that would be selected over the generic `Salmonella` scheme. The `Escherichia coli` database would be selected for _Escherichia coli_ as there they are a 100% match.
