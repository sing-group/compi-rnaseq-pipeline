# compi-rnaseq-pipeline [![license](https://img.shields.io/badge/license-MIT-brightgreen)](https://github.com/sing-group/compi-rnaseq-pipeline) [![dockerhub](https://img.shields.io/badge/hub-docker-blue)](https://hub.docker.com/r/singgroup/compi-rnaseq) [![compihub](https://img.shields.io/badge/hub-compi-blue)](https://www.sing-group.org/compihub/explore/5d09fb2a1713f3002fde86e2)

A Compi RNA-Seq pipeline to perform differential expression using DElite.

A Docker image is available for this pipeline in [this Docker Hub repository](https://hub.docker.com/r/singgroup/compi-rnaseq). In order to run the pipeline locally, have a look at the [required dependencies](DEPENDENCIES.md).

# Using the Compi RNA-Seq pipeline image in Linux

To perform an analysis users must first:

1. Initialize a working directory with the files required by the pipeline.
2. Add the input data to be analyzed (fastQ reads, genomes, configuration files, and so on).
3. Configure the pipeline parameters.

This section provides a comprehensive guide on how to perform these steps and the tools and scripts included in the pipeline image to do it easily.

## Initialize the working directory

To start a new analysis, the first thing to do is build the directory tree in your local file system. This directory tree will be referred as the working directory and its structure is recognized and used by the pipeline during the analysis.

To build the working directory adapt the first line of the following code and run it:
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

After completing any of the above options, the selected working directory should have the following structure:
```
/path/to/the/working-directory
├── compi.parameters
├── config
│   └── contrasts.tsv
├── genes
├── genome
├── README.txt
├── run.sh
└── samples
    └── metadata.tsv
```

Where:
- `README.txt` contains the next steps you need to do to run the analysis.
- `compi.parameters` contains the paths and parameters needed for the analysis.
- `run.sh` is the script to run the analysis.
- `samples` is the folder where the input FASTQ files must be placed. It must also contain a `metadata.tsv` file with the samples metadata (names and groups).
- `genome` is the folder where the input genome must be placed.
- `genes` is the folder where the input GTF annotation file must be placed.
- `config` is the folder wher the input configuration files must be placed. It may contain an optional file called `contrasts.tsv` with the DEA contrasts that must be performed (if not provided, the pipeline generates all combinations based on the information in the `metadata.tsv` file).

# Running the pipeline with sample data

It is possible to test the pipeline using our sample data available [here](https://static.sing-group.org/data/compi-rnaseq-pipeline/data-compi-rnaseq-pipeline-2.0_chr_X.zip) or [here](https://static.sing-group.org/data/compi-rnaseq-pipeline/data-compi-rnaseq-pipeline-2.0_HCC1395.zip). 

Download any of the ZIP files and decompress them in your local file system. Edit the `compi.parameters` file to update the `working_dir` parameter so that it points to to the path where you have the decompressed data.

Then, to execute the pipeline using Docker, run the following command changing the `/path/to/rna-seq-docker/data/` to the path where you have the decompressed data.

```bash
./run.sh /path/to/rna-seq-docker/data/compi.parameters
```

Pipeline results will be created in a directory called `compi` inside the main data directory.

## Additional execution parameters

The pipeline execution can be customized (e.g. setting the maximum number of parallel tasks, partial executions, and so on) by providing an additional parameter to the `run.sh` script. Below are some examples:

### Run a single task with 2 maximum parallel executions

```bash
./run.sh /path/to/rna-seq-docker/data/compi.parameters "--single-task samtools --num-tasks 2"
```

### Partial execution between two tasks

```bash
./run.sh /path/to/rna-seq-docker/data/compi.parameters "--from prepare-deas --until add-mappings"
```

# Team

The Compi RNA-Seq pipeline is developed by the [SING Research Group](https://www.sing-group.org/) (Universidade de Vigo) and Molecular Biology and Transcriptomics Unit (IRCCS Mondino Foundation):
- Hugo López-Fernández [![ORCID](https://info.orcid.org/wp-content/uploads/2020/12/orcid_16x16.gif)](https://orcid.org/0000-0002-6476-7206)
- Rosalinda Di Gerlando [![ORCID](https://info.orcid.org/wp-content/uploads/2020/12/orcid_16x16.gif)](https://orcid.org/0000-0002-7834-0342)
  