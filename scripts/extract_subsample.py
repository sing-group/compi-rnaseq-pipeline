import pandas as pd
import sys

if len(sys.argv) != 4:
    raise ValueError("Exactly 3 arguments are required: <metadata_path> <counts_path> <filtered_counts_path>")

metadata_path = sys.argv[1]
counts_path = sys.argv[2]
filtered_counts_path = sys.argv[3]

metadata = pd.read_csv(metadata_path, sep='\t')
samples_to_keep = set(metadata['sample'])

counts = pd.read_csv(counts_path, sep='\t')

filtered_counts = counts[['gene'] + [col for col in counts.columns if col in samples_to_keep]]

filtered_counts.to_csv(filtered_counts_path, sep='\t', index=False)
