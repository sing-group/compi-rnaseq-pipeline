#!/bin/bash

head -1 ${working_dir}/${samples_dir}/${metadata_file} | grep --silent ${batch_correction}

if [ $? -ne 0 ]; then
    echo "${batch_correction} not found in metadata file"
    exit 1
fi

echo "Correcting for ${batch_correction}"

if [ ! -f ${working_dir}/compi/scripts/remove_batch_effects.R ]; then
    cp ${scripts_dir}/remove_batch_effects.R ${working_dir}/compi/scripts/remove_batch_effects.R
fi

docker run --rm -v ${working_dir}:${working_dir} ${sva_image} \
    Rscript ${working_dir}/compi/scripts/remove_batch_effects.R \
        ${working_dir}/${all_counts_dir}/counts.tsv \
        ${working_dir}/${samples_dir}/${metadata_file} \
        ${working_dir}/${all_counts_dir} \
        ${batch_correction}

if [ ! -f ${working_dir}/${all_counts_dir}/counts_before_batch_correction.tsv ]; then
    mv ${working_dir}/${all_counts_dir}/counts.tsv ${working_dir}/${all_counts_dir}/counts_before_batch_correction.tsv
fi

mv ${working_dir}/${all_counts_dir}/counts_corrected_combat_seq.tsv ${working_dir}/${all_counts_dir}/counts.tsv
