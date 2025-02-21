#!/bin/bash

set -o nounset
set -o errexit

dea=$(echo ${pathfindr_task} | awk -F ',' '{print $1}')
gene_set=$(echo ${pathfindr_task} | awk -F ',' '{print $2}')
pin=$(echo ${pathfindr_task} | awk -F ',' '{print $3}')
echo "Running pathfindr for DEA: ${dea}, gene set: ${gene_set}, and pin: ${pin}"

source ${tasks_dir}/functions.sh

pathfindR_script=${working_dir}/compi/scripts/run-pathfindR.R

# lock Rscript before copying to avoid errors when parallel tasks are running
cp_and_lock ${scripts_dir}/run-pathfindR.R ${task_id} ${pathfindR_script}

delite_dir=$(ls -1 ${working_dir}/${dea_dir}/${dea} | grep DElite* | head -1)

if [ -z ${delite_dir} ]; then
    echo "No DElite directory found for DEA: ${working_dir}/${dea_dir}/${dea}"
    exit 1
elif [ ! -f ${working_dir}/${dea_dir}/${dea}/${delite_dir}/${pathfindr_delite_file_prefix}_with_genes_clean.csv ]; then
    echo "No DElite file found for DEA: ${working_dir}/${dea_dir}/${dea}/${delite_dir}/${pathfindr_delite_file_prefix}_with_genes_clean.csv"
    exit 1
fi

results_dir=${dea_dir}/${dea}/pathfindR/${gene_set}_${pin}
skip_pathfindR_existing=${skip_pathfindR_existing:-no}
if [ ${skip_pathfindR_existing} == "yes" ] && [ -d ${working_dir}/${results_dir} ]; then
    echo "Skipping pathfindR for DEA: ${dea} and gene set: ${gene_set} as results already exist and flag skip_pathfindR_existing is set to yes"
    exit 0
fi

mkdir -p ${working_dir}/compi/cache/pathfindR

docker run --rm -v ${working_dir}:${working_dir} -w ${working_dir} \
    -v ${working_dir}/compi/cache/pathfindR:/root/.cache/R/BiocFileCache \
    --entrypoint=Rscript pegi3s/r_pathfindr_tmp_devel \
        ${pathfindR_script} \
            ${dea_dir}/${dea}/${delite_dir}/${pathfindr_delite_file_prefix}_with_genes_clean.csv \
            ${dea_dir}/${dea}/counts.tsv \
            ${dea_dir}/${dea}/metadata.tsv \
            ${dea_dir}/${dea}/reference.txt \
            ${results_dir} ${gene_set} ${pin}
