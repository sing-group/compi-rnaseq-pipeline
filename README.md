# compi-rnaseq-pipeline

A compi RNA-Seq pipeline to perform differential expression using ballgown.

A Docker image is available for this pipeline in [this Docker Hub repository](https://hub.docker.com/r/singgroup/compi-rnaseq). In order to run the pipeline locally, have a look at the [required dependencies](DEPENDENCIES.md).

# Running the pipeline with sample data

It is possible to test the pipeline using our sample data available [here](https://static.sing-group.org/data/data-compi-rnaseq-pipeline-1.0.0.zip). Download the ZIP file and decompress it in your local file system. Then, to execute the pipeline using Docker, run the following command changing the `/path/to/rna-seq-docker/data/` to the path where you have the decompressed data.

```bash
docker run --rm -it -v /path/to/rna-seq-docker/data/:/data singgroup/compi-rnaseq -pa /data/parameters
```

Pipeline results will be created in a directory called `compi` inside the main data directory.

Alternatively, it is also possible to execute the pipeline using Singularity. To do so, run the following command changing the `/path/to/rna-seq-docker/data/` to the path where you have the decompressed data.

```bash
singularity run -B /path/to/rna-seq-docker/data/:/data docker://singgroup/compi-rnaseq -pa /data/parameters
```

