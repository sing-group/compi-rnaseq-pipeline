#!/bin/bash

tail -n +2 ${working_dir}/${contrasts_file} | while IFS= read -r line; do
    word_grep=$(printf "%s" "$line" | sed 's#\t#|#')
    dir=$(echo ${word_grep} | sed 's#|#_#')
    reference=$(printf "%s" "$line" | cut -f1)

    echo -e "Processing contrasts line: $line"
    echo -e "\tReference: $reference"

    mkdir -p ${working_dir}/${dea_dir}/${dir}

    head -1 ${working_dir}/${samples_dir}/${metadata_file} > ${working_dir}/${dea_dir}/${dir}/metadata.tsv
    cat ${working_dir}/${samples_dir}/${metadata_file} |grep -E "(^|[[:space:],])${word_grep}([[:space:],]|$)" >> ${working_dir}/${dea_dir}/${dir}/metadata.tsv
    echo ${reference} > ${working_dir}/${dea_dir}/${dir}/reference.txt

    # ${scripts_dir}/join_all.sh ${working_dir}/${samples_htseqcount_dir} ${working_dir}/${dea_dir}/${dir}/counts.tsv ${working_dir}/${dea_dir}/${dir}/metadata.tsv
    # don't join all files because we need to use the batch corrected all counts file
    # filter out the metadata file by condition (word_grep) and then filter out the all counts file by the samples remaining in the metadata file
    python3 ${scripts_dir}/extract_subsample.py ${working_dir}/${dea_dir}/${dir}/metadata.tsv ${working_dir}/${all_counts_dir}/counts.tsv ${working_dir}/${dea_dir}/${dir}/counts.tsv
done
