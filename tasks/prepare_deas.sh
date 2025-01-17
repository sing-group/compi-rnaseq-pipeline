#!/bin/bash

tail -n +2 ${working_dir}/${contrasts_file} | while IFS= read -r line; do
    dir=$(printf "%s" "$line" | sed 's#\t#_#')
    reference=$(printf "%s" "$line" | cut -f1)
    other=$(printf "%s" "$line" | cut -f2)

    echo -e "Processing contrasts line: $line"
    echo -e "\tReference: $reference"
    echo -e "\tVersus: $other"

    mkdir -p ${working_dir}/${dea_dir}/${dir}

    head -1 ${working_dir}/${samples_dir}/${metadata_file} > ${working_dir}/${dea_dir}/${dir}/metadata.tsv

    cat ${working_dir}/${samples_dir}/${metadata_file} | grep -E -e "(^|[[:space:],])$reference([[:space:],]|$)" -e "(^|[[:space:],])$other([[:space:],]|$)" >> ${working_dir}/${dea_dir}/${dir}/metadata.tsv
    
    echo ${reference} > ${working_dir}/${dea_dir}/${dir}/reference.txt

    python3 ${scripts_dir}/extract_subsample.py ${working_dir}/${dea_dir}/${dir}/metadata.tsv ${working_dir}/${all_counts_dir}/counts.tsv ${working_dir}/${dea_dir}/${dir}/counts.tsv
done
