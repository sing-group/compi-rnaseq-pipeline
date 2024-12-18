#!/bin/bash

# Directory containing the TSV files
input_dir="$1"

# Output file for the merged results
output_file="$2"

# Create the output file or overwrite if it exists
> "$output_file"

# Get the list of TSV files in the directory sorted numerically
files=($(ls "$input_dir"/*.tsv | sort))

# Read the first file and initialize the output file
first_file="${files[0]}"
cp "$first_file" "$output_file"

# Iterate over the remaining files and use 'join' to merge them on the first column
for file in "${files[@]:1}"; do
    # Join the current output with the next file
    join -t$'\t' -1 1 -2 1 "$output_file" "$file" > temp && mv temp "$output_file"
done

echo "Merge complete. Output written to $output_file"

# Extract the filenames without extensions for the header
header="gene"
for file in "${files[@]}"; do
    header="$header $(basename "$file" .tsv)"
done

# Prepend the header to the output file
sed -i "1i$header" "$output_file"

grep -v '__' "$output_file" > temp
mv temp "$output_file"
