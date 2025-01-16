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

    ${scripts_dir}/join_all.sh ${working_dir}/${samples_htseqcount_dir} ${working_dir}/${dea_dir}/${dir}/counts.tsv ${working_dir}/${dea_dir}/${dir}/metadata.tsv
done
