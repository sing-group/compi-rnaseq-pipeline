#!/bin/bash

mkdir -p ${working_dir}/${samples_alignment_dir}
mkdir -p ${working_dir}/${samples_htseqcount_dir}
mkdir -p ${working_dir}/${genome_index_dir}
touch ${working_dir}/${samples_files_list}

for image in $(printenv | grep '_image=' | grep -v "grep" | cut -f1 -d'='); do
    image_value=${!image}

    if [[ -n "$image_value" ]]; then
        echo "Pulling Docker image: $image_value"
        docker pull "$image_value"
    else
        echo "Warning: Variable $image has an empty value"
    fi
done
