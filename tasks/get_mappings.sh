#!/bin/bash

gtf_file="${1:-${working_dir}/${reference_annotation}}"
output_file="${2:-${working_dir}/${mapping_file}}"

if [[ ! -f "$gtf_file" ]]; then
    echo "Error: GTF file not found! $gtf_file" >&2
    exit 1
fi

echo -e "gene_id\tgene_name\tgene_biotype" > "$output_file"

awk -F'\t' '
    BEGIN { OFS="\t" }
    /^#/ { next }  # Skip header lines
    {
        attr = $9  # Store attributes column
        gene_id = "NA"
        gene_name = "NA"
        gene_biotype = "NA"

        match(attr, /gene_id "[^"]+"/)
        if (RSTART) gene_id = substr(attr, RSTART+9, RLENGTH-10)

        match(attr, /gene_name "[^"]+"/)
        if (RSTART) gene_name = substr(attr, RSTART+11, RLENGTH-12)

        match(attr, /gene_biotype "[^"]+"/)
        if (RSTART) gene_biotype = substr(attr, RSTART+14, RLENGTH-15)

        if (gene_id != "NA" && !seen[gene_id]++) {
            print gene_id, gene_name, gene_biotype >> "'"$output_file"'"
        }
    }
' "$gtf_file"

echo "Mapping extraction complete. Output written to $output_file"