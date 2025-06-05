# compi-rnaseq-pipeline [![license](https://img.shields.io/badge/license-MIT-brightgreen)](https://github.com/sing-group/compi-rnaseq-pipeline) [![license](https://img.shields.io/badge/version-2.2.0-brightgreen)](https://github.com/sing-group/compi-rnaseq-pipeline) [![dockerhub](https://img.shields.io/badge/hub-docker-blue)](https://hub.docker.com/r/singgroup/compi-rnaseq) [![compihub](https://img.shields.io/badge/hub-compi-blue)](https://www.sing-group.org/compihub/explore/5d09fb2a1713f3002fde86e2)

A Compi RNA-Seq pipeline to perform differential expression using DElite and enrichment analysis using RCPA and pathfindR.

A Docker image is available for this pipeline in [this Docker Hub repository](https://hub.docker.com/r/singgroup/compi-rnaseq). To run the pipeline locally, see the [required dependencies](DEPENDENCIES.md).

## Table of contents

- [Using the Compi RNA-Seq pipeline image in Linux](#using-the-compi-rna-seq-pipeline-image-in-linux)
    - [Initialize the working directory](#initialize-the-working-directory)
- [Running the pipeline with sample data](#running-the-pipeline-with-sample-data)
    - [Additional Compi execution parameters](#additional-compi-execution-parameters)
- [Pipeline configuration](#pipeline-configuration)
    - [HTSeq or featureCounts choice](#htseq-or-featurecounts-choice)
    - [Qualimap](#qualimap)
    - [DElite](#delite)
    - [pathfindR and RCPA inputs](#pathfindr-and-rcpa-inputs)
    - [pathfindR](#pathfindr)
    - [RCPA](#rcpa)
    - [Optional tasks](#optional-tasks)
        - [Trimmomatic](#trimmomatic)
        - [Batch correction](#batch-correction)
- [Team](#team)
- [Publications](#publications)
    - [Related work](#related-work)

## Using the Compi RNA-Seq pipeline image in Linux

To perform an analysis, users must first:

1. Initialize a working directory with the files required by the pipeline.
2. Add the input data to be analyzed (FASTQ reads, genomes, configuration files, etc.).
3. Configure the pipeline parameters.

This section provides a comprehensive guide on how to perform these steps and describes the tools and scripts included in the pipeline image to do so easily.

### Initialize the working directory

To start a new analysis, the first step is to build the directory tree in your local file system. This directory tree will be referred to as the working directory, and its structure is recognized and used by the pipeline during the analysis.

To build the working directory, adapt the first line of the following code and run it:
```sh
WORKING_DIRECTORY=/path/to/the/working-directory

mkdir -p ${WORKING_DIRECTORY}

docker run --rm \
    -v ${WORKING_DIRECTORY}:${WORKING_DIRECTORY} \
    -u "$(id -u)":"$(id -g)" \
    --entrypoint=/bin/bash \
        singgroup/compi-rnaseq \
            init_working_dir.sh ${WORKING_DIRECTORY}
```

After running this command, the selected working directory should have the following structure:
```
├── compi.parameters
├── config
│   ├── contrasts.tsv
│   ├── pathfindR.csv
│   └── rcpa.txt
├── genes
├── genome
├── pipeline.png
├── README.txt
├── run.sh
├── run-trimmomatic-1.sh
├── run-trimmomatic-2.sh
└── samples
    └── metadata.tsv
```

Where:
- `README.txt` contains the next steps you need to follow to run the analysis.
- `pipeline.png` contains the pipeline graph.
- `compi.parameters` contains the paths and parameters needed for the analysis.
- `run.sh` is the script to run the analysis.
- `samples` is the folder where the input FASTQ files must be placed.
  - It must also contain a `metadata.tsv` file with the sample metadata (names and groups).
- `genome` is the folder where the input genome must be placed.
- `genes` is the folder where the input GTF annotation file must be placed.
- `config` is the folder where the input configuration files must be placed. It may contain:
  - An optional file called `contrasts.tsv` with the DEA contrasts to be performed (if not provided, the pipeline generates all combinations based on the information in the `metadata.tsv` file).
  - A file called `pathfindR.tsv` indicating the gene sets for enrichment (KEGG, Reactome, BioCarta, GO-All, GO-BP, GO-CC, or GO-MF; all for Homo sapiens) and the protein-protein interaction network (Biogrid, STRING, GeneMania, IntAct, KEGG, or mmu_STRING) for the pathfindR analysis. It is a two-column CSV file where the first column is the gene set and the second is the protein-protein interaction network. Lines starting with `#` are skipped, and one pathfindR analysis for each line will be executed.
  - An optional file called `rcpa.txt` with additional parameters for RCPA.

## Running the pipeline with sample data

It is possible to test the pipeline using our sample data available [here](https://static.sing-group.org/data/compi-rnaseq-pipeline/data-compi-rnaseq-pipeline-v2_chr_X.zip) or [here](https://static.sing-group.org/data/compi-rnaseq-pipeline/data-compi-rnaseq-pipeline-v2_HCC1395.zip).

Download any of the ZIP files and decompress them in your local file system. Edit the `compi.parameters` file to update the `working_dir` parameter so that it points to to the path where you have the decompressed data.

Then, to execute the pipeline using Docker, run the following command changing the `/path/to/rna-seq-docker/data/` to the path where you have the decompressed data.

```bash
./run.sh /path/to/rna-seq-docker/data/compi.parameters
```

Pipeline results will be created in a directory called `compi` inside the main data directory.

### Additional Compi execution parameters

The pipeline execution can be customized (e.g. setting the maximum number of parallel tasks, partial executions, and so on) by providing an additional parameter to the `run.sh` script. Below are some examples:

#### Run a single task with 2 maximum parallel executions

```bash
./run.sh /path/to/rna-seq-docker/data/compi.parameters "--single-task samtools --num-tasks 2"
```

#### Partial execution between two tasks

```bash
./run.sh /path/to/rna-seq-docker/data/compi.parameters "--from prepare-deas --until add-mappings"
```

## Pipeline configuration

Analyses can be customized by changing the pipeline configuration in the Compi parameters file (i.e. `compi.parameters`). 

Some tasks (DElite, pathfindR, and RCPA) require or accept additional configuration files placed at the `config` directory of the working directory.

This subsection explains the main configuration parameters to customize the pipeline execution and include optional tasks.

### HTSeq or featureCounts choice

By default, the software used for counting reads is featureCounts. This is because *featurecounts* is the default value of the `counts_method` parameter. To change it, include `counts_method=htseq` in your Compi parameters file.

### Qualimap

This tool may require more RAM memory than the default setting. To increase it, include the `qualimap_additional_args` in the Compi parameters file with the value `--java-mem-size=2G`.

### DElite

By default, the `delite` task runs DElite on each possible group/condition combination based on the information in the `metadata.tsv` file. 

Optionally, users may provide a file called `config/contrasts.tsv` with the DEA contrasts that must be performed. Example:

```
reference	comparison
A	B
```

Additional DElite parameters may be specified in the `delite_additional_args` Compi parameter. Users are encouraged to have a look at the [DElite official documentation](https://gitlab.com/soc-fogg-cro-aviano/delite) for further information about its parameters and defautl values. To do so, include it in the Compi parameters file as follows:

```
delite_additional_args=lowcounts=var var=0.3 combine=bonferroni
```

### pathfindR and RCPA inputs

Both `pathfindr` and `rcpa` tasks use the DEA results produced by DElite as inputs. Each DElite execution creates a directory at `working_dir/dea/A_B/DElite_<timestamp>` with a specific timestamp. This guarantees that if DElite is run several times previous results are not overwriten.

By default, the `pathfindr` and `rcpa` tasks will take the most recent directory. To force the pipeline to run on a specific DElite results directory, include `pathway_delite_folder=<DElite_folder>` in the Compi parameters file to set the specific directory that must be used.

In addition, both tasks require a single DEA results file as input, and default files are different in each case:

- `pathfindr` uses `DEGs_filtered_DElite_lancaster`. This means that pathfindR analyzes the filtered file resulting from integrating DEA results with the Lancaster method.
- `rcpa` uses `DEGs_unfiltered_DElite_lancaster`. This means that RCPA analyzes the unfiltered file (i.e. it contains all genes) resulting from integrating DEA results with the Lancaster method.

To change this default behaviour, include `pathfindr_delite_file_prefix=<prefix>` or `rcpa_delite_file_prefix=<prefix>` in the Compi parameters file. Example:

```
pathfindr_delite_file_prefix=DEGs_filtered_edgeR
rcpa_delite_file_prefix=DEGs_unfiltered_DESeq2
```

Note that it is recommended to use *_unfiltered_* files in the case of RCPA due to the way in which most method works. Using *_filtered_* files with RCPA may cause some methods to not work (e.g. ORA).

### pathfindR

The `pathfindr` task requires that users provide a file called `config/pathfindr.csv` at the working directory. This file specifies which databases and protein interaction networks must be used by pathfindR. Lines starting with `#` are ommited. This way, the pathfindR task will run one analysis for each DEA contrast and each line in this file. Example:

```
KEGG,Biogrid
KEGG,STRING
#Reactome,Biogrid
#BioCarta,Biogrid
#GO-All,Biogrid
#GO-BP,Biogrid
#GO-CC,Biogrid
#GO-MF,Biogrid
```

### RCPA

The pipeline has three parameters for the `rcpa` task that can be provided in the Compi parameters file:
- `rcpa_database` (default to *KEGG*): The database to be used for the pathway analysis. Options: KEGG or GO.
- `rcpa_geneset_analysis_methods` (default to *fgsea,gsa,ora,ks,wilcox*): The methods to be used for the pathway analysis. Several methods can be specified as a comma-separated list. Options: fgsea, gsa, ora, ks, wilcox.
- `rcpa_pathway_analysis_methods` (default to *spia,cepaORA,cepaGSA*): The methods to be used for the pathway analysis. Several methods can be specified as a comma-separated list. Options: spia, cepaORA, cepaGSA.

Additional configuration parameters for each method may be provided by users in a file called `config/rcpa.txt` at the working directory. This file must include one line for each parameter in the following format: `<method_name>.<parameter_name>=<parameter_value>`. Example:
```
ora.pThreshold=0.01
```

Users are encouraged to have a look at the official [RCPA package documentation](https://cran.r-project.org/web/packages/RCPA/index.html) as well as at [this comprehensive paper](https://currentprotocols.onlinelibrary.wiley.com/doi/10.1002/cpz1.1036) at Current Protocols about all its functionalities.

### Optional tasks

#### Trimmomatic

By default, Trimmomatic tasks (`trimmomatic`, `trimmomatic-fastqc`, and `trimmomatic-move`) are skipped. To enable them, include `enable_trimmomatic` in your Compi parameters file.

The Trimmomatic configuration is specified using the `trimmomatic_parameters` parameter, whose default value is `ILLUMINACLIP:/Trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10 SLIDINGWINDOW:4:15 MINLEN:36`. This string must contain the parameters to pass to Trimmomatic as a space-separated string. Look at the [Trimmomatic manual](https://github.com/usadellab/Trimmomatic) for more information about this.

Usually, users may run first all tasks until `trimmomatic-fastqc` (several times) until a suitable trimming configuration is found. Once that happens, they may go ahead with the pipeline execution to run the remaining tasks. To facilitate this, the working directory created with the `init_working_dir.sh` as well as the sample datasets include two scripts to do this: `run-trimmomatic-1.sh` and `run-trimmomatic-2.sh`.

#### Batch correction

By default, batch correction tasks (`batch-correction-all`, `pca-batch-correction`) are skipped. To enable them, include the `batch_correction` parameter in your Compi parameters file to specify the factor (column in metadata) for batch correction (or *interaction* to use a combination of all of them). Its default value is *none*, meaning that no batch correction is applied.

## Team

The Compi RNA-Seq pipeline is developed by the [SING Research Group](https://www.sing-group.org/) (Universidade de Vigo) and Molecular Biology and Transcriptomics Unit (IRCCS Mondino Foundation):
- Hugo López-Fernández [![ORCID](https://info.orcid.org/wp-content/uploads/2020/12/orcid_16x16.gif)](https://orcid.org/0000-0002-6476-7206)
- Rosalinda Di Gerlando [![ORCID](https://info.orcid.org/wp-content/uploads/2020/12/orcid_16x16.gif)](https://orcid.org/0000-0002-7834-0342)

## Publications

- R. Di Gerlando; S. Gagliardi; H. López-Fernández (2025) A new Compi pipeline for RNA-Seq differential expression analysis. 19th International Conference on Practical Applications of Computational Biology & Bioinformatics: PACBB 2025. Lille, France. 25 - June

### Related work

- H. López-Fernández; A. Blanco-Míguez; F. Fdez-Riverola; B. Sánchez; A. Lourenço (2019) [DEWE: a novel tool for executing differential expression RNA-Seq workflows in biomedical research](https://doi.org/10.1016/j.compbiomed.2019.02.021). Computers in Biology and Medicine. Volume 107, pp. 197-205. ISSN: 0010-4825
