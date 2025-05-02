#!/bin/bash

set -o nounset
set -o errexit

dea=${contrast_dir}
echo "Running RCPA for DEA: ${dea}"

source ${tasks_dir}/functions.sh

rcpa_script=${working_dir}/compi/scripts/run-rcpa.R

# lock Rscript before copying to avoid errors when parallel tasks are running
cp_and_lock ${scripts_dir}/run-rcpa.R ${task_id} ${rcpa_script}

delite_dir=$(ls -1 ${working_dir}/${dea_dir}/${dea} | grep DElite* | head -1)

if [ -z ${delite_dir} ]; then
    echo "No DElite directory found for DEA: ${working_dir}/${dea_dir}/${dea}"
    exit 1
elif [ ! -f ${working_dir}/${dea_dir}/${dea}/${delite_dir}/${rcpa_delite_file_prefix}_with_genes_clean.csv ]; then
    echo "No DElite file found for DEA: ${working_dir}/${dea_dir}/${dea}/${delite_dir}/${rcpa_delite_file_prefix}_with_genes_clean.csv"
    exit 1
fi

results_dir=${working_dir}/${dea_dir}/${dea}/rcpa
skip_rcpa_existing=${skip_rcpa_existing:-no}
if [ ${skip_rcpa_existing} == "yes" ] && [ -d ${results_dir} ]; then
    echo "Skipping RCPA for DEA '${dea}' as results already exist and flag skip_rcpa_existing is set to yes"
    exit 0
else
    mkdir -p ${results_dir}
fi

rcpa_file=${results_dir}/rcpa.txt
touch ${rcpa_file}
echo "database=${rcpa_database}" > ${rcpa_file}
echo "geneset_analysis_methods=${rcpa_geneset_analysis_methods}" >> ${rcpa_file}
echo "pathway_analysis_methods=${rcpa_pathway_analysis_methods}" >> ${rcpa_file}

echo "metadata_file=${working_dir}/${dea_dir}/${dea}/metadata.tsv" >> ${rcpa_file}
echo "results_dir=${results_dir}" >> ${rcpa_file}
echo "delite_dea_results=${working_dir}/${dea_dir}/${dea}/${delite_dir}/${rcpa_delite_file_prefix}_with_genes_clean.csv" >> ${rcpa_file}

reference=$(cat ${working_dir}/${dea_dir}/${contrast_dir}/reference.txt)
echo "reference=${reference}" >> ${rcpa_file}

docker run --rm -v ${working_dir}:${working_dir} -w ${working_dir} \
    --entrypoint=Rscript ${rcpa_image} \
        ${rcpa_script} ${rcpa_file}
