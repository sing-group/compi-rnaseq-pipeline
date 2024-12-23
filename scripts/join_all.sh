#!/bin/bash

# Directory containing the TSV files
input_dir="$1"

# Output file for the merged results
output_file="$2"

# Metadata file containing valid sample names
metadata_file="$3"

# Ensure the metadata file exists
if [ ! -f "$metadata_file" ]; then
    echo "Error: Metadata file $metadata_file not found" >&2
    exit 1
fi

# Create the output file or overwrite if it exists
> "$output_file"

# Extract valid sample names from the metadata file
mapfile -t valid_samples < <(awk 'NR > 1 {print $1}' "$metadata_file")

# Ensure every sample has a corresponding file
missing_files=()
for sample in "${valid_samples[@]}"; do
    file="$input_dir/$sample.tsv"
    if [ ! -f "$file" ]; then
        missing_files+=("$sample")
    fi
done

# If any sample file is missing, exit with an error
if [ ${#missing_files[@]} -gt 0 ]; then
    echo "Error: Missing files for the following samples:" >&2
    printf '%s\n' "${missing_files[@]}" >&2
    exit 1
fi

# Collect the files to be processed
files=()
for sample in "${valid_samples[@]}"; do
    files+=("$input_dir/$sample.tsv")
done

# Read the first file and initialize the output file
first_file="${files[0]}"
cp "$first_file" "$output_file"

# Iterate over the remaining files and use 'join' to merge them on the first column
for file in "${files[@]:1}"; do
    join -t$'\t' -1 1 -2 1 "$output_file" "$file" > temp && mv temp "$output_file"
done

echo "Merge complete. Output written to $output_file"

# Extract the filenames without extensions for the header
header="gene"
for file in "${files[@]}"; do
    header="$header\t$(basename "$file" .tsv)"
done

# Prepend the header to the output file
sed -i "1i$header" "$output_file"

# Remove unwanted lines containing '__'
grep -v '__' "$output_file" > temp && mv temp "$output_file"
