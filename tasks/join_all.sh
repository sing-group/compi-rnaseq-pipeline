#!/bin/bash

if [ "$counts_method" == "htseq" ]; then
    ${scripts_dir}/join_all.sh ${working_dir}/${samples_htseqcount_dir} ${working_dir}/${all_counts_dir}/counts.tsv ${working_dir}/${samples_dir}/${metadata_file}
elif [ "$counts_method" == "featurecounts" ]; then
    ${scripts_dir}/join_all.sh ${working_dir}/${samples_feature_counts_dir} ${working_dir}/${all_counts_dir}/counts.tsv ${working_dir}/${samples_dir}/${metadata_file}
else
    echo "Error: counts_method must be either 'htseq' or 'featurecounts'"
    exit -1
fi
