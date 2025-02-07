#!/bin/bash
set -o nounset
set -o errexit

source ${tasks_dir}/functions.sh

MAP_IDS_SCRIPT=${working_dir}/compi/scripts/map_ids.R

# lock Rscript before copying to avoid errors when parallel tasks are running
cp_and_lock ${scripts_dir}/map_ids.R ${task_id} ${MAP_IDS_SCRIPT}

for DElite_folder in $(find ${working_dir}/${dea_dir}/${contrast_dir} -iname "DElite*" -type d); do
    echo "Processing DElite results folder: ${DElite_folder}"
    delite_files=$(ls ${DElite_folder}/DEGs_filtered*csv | grep -v "_with_genes_clean.csv")

    for file in ${delite_files[@]}; do
        echo "Processing DElite file: ${file}"

        docker run --rm -v ${working_dir}:${working_dir} ${annotationdbi_image} \
            Rscript ${MAP_IDS_SCRIPT} \
            ${file} \
            ${working_dir}/${mapping_file} \
            FALSE
    done
done
