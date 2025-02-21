#!/bin/bash

rm -f ${working_dir}/${pathfindr_file} && touch ${working_dir}/${pathfindr_file}

for dir in $(ls ${working_dir}/${dea_dir}); do
    for gene_set_and_pin in $(cat ${working_dir}/${user_pathfindr_file} | grep -v '#'); do
        echo -e "${dir},${gene_set_and_pin}" >> ${working_dir}/${pathfindr_file}
    done
done

