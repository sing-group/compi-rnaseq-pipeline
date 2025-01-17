#!/bin/bash

# ${scripts_dir}/join_all.sh ${working_dir}/${samples_feature_counts_dir} ${working_dir}/compi/counts.tsv ${working_dir}/${samples_dir}/${metadata_file}

${scripts_dir}/join_all.sh ${working_dir}/${samples_htseqcount_dir} ${working_dir}/${all_counts_dir}/counts.tsv ${working_dir}/${samples_dir}/${metadata_file} 
