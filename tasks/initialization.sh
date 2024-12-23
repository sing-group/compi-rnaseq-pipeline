#!/bin/bash

mkdir -p ${working_dir}/${samples_alignment_dir}
mkdir -p ${working_dir}/${samples_htseqcount_dir}
mkdir -p ${working_dir}/${genome_index_dir}
mkdir -p ${working_dir}/${dea_dir}
touch ${working_dir}/${samples_files_list}

# Pulls the Docker images
for image in $(printenv | grep '_image=' | grep -v "grep" | cut -f1 -d'='); do
    image_value=${!image}

    if [[ -n "$image_value" ]]; then
        echo "Pulling Docker image: $image_value"
        docker pull "$image_value"
    else
        echo "Warning: Variable $image has an empty value"
    fi
done

# Creates the contrasts file if it does not exist
if [ -f ${working_dir}/${user_contrasts_file} ]; then
    echo "Contrasts file found: ${working_dir}/${user_contrasts_file}"
    cp ${working_dir}/${user_contrasts_file} ${working_dir}/${contrasts_file}
else
    echo "Contrasts file not found: ${working_dir}/${user_contrasts_file}"
    echo -e "reference\tcomparison" > ${working_dir}/${contrasts_file}

    conditions=$(cat ${working_dir}/${samples_dir}/${metadata_file} | awk 'NR>1 {print $2}' | sort -u)
    for c_1 in ${conditions}; do
        for c_2 in ${conditions}; do 
            if [[ "$c_1" < "$c_2" ]]; then 
                echo -e "${c_1}\t${c_2}" >> ${working_dir}/${contrasts_file}
            fi
        done
    done
fi