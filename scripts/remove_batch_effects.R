library(sva)
library(ggplot2)

# Function to perform batch correction with ComBat_seq
batch_correct_with_combat_seq <- function(counts_data, metadata, batch_factors = NULL, use_interaction = TRUE, batch_factor_choice = NULL) {
  # If batch_factors is not specified, use all batch columns in metadata
  if (is.null(batch_factors)) {
    batch_factors <- grep("batch", colnames(metadata), value = TRUE)
  }
  
  # Ensure batch_factors contains at least one batch column
  if (length(batch_factors) == 0) {
    stop("No batch factor found in metadata.")
  }
  
  # Handle case where multiple batch factors are present
  if (length(batch_factors) > 1) {
    if (use_interaction) {
      # Use the interaction of batch factors
      interaction_term <- interaction(metadata[, batch_factors, drop = FALSE], drop = TRUE)
      print(interaction_term)
      metadata$batch_interaction <- interaction_term
      batch_factors <- "batch_interaction"  # Now use the combined interaction factor
    } else {
      # Use the specified batch factor (if provided)
      if (is.null(batch_factor_choice)) {
        stop("Please specify a batch factor when using multiple batch factors.")
      }
      batch_factors <- batch_factor_choice
    }
  }

  # Ensure batch_factors is a character vector
  batch_factors <- as.character(batch_factors)
  
  # Check if the specified batch factor exists in metadata
  if (!all(batch_factors %in% colnames(metadata))) {
    stop("Specified batch factor(s) not found in metadata.")
  }

  metadata$batch <- metadata[[batch_factors]]

  # Use ComBat_seq to perform batch correction
  corrected_counts <- ComBat_seq(
    counts = counts_data, 
    batch = metadata[[batch_factors]], 
    group = metadata$class,  # Biological condition (optional)
    full_mod = TRUE          # Use full model (batch + class)
  )

  return(list(metadata, corrected_counts))
}

# PCA plotting function with zero variance gene removal
plot_pca <- function(data, metadata, title) {
  # Remove genes with zero variance
  data <- data[apply(data, 1, var) > 1e-6, ]  # Apply variance filter to rows (genes)
  
  # Perform PCA
  pca <- prcomp(t(data), scale. = TRUE)
  pca_data <- as.data.frame(pca$x[, 1:2])  # Extract first two PCs
  colnames(pca_data) <- c("PC1", "PC2")
  pca_data$Sample <- rownames(pca_data)  # Add sample names as 'Sample' column
  
  # Ensure metadata matches PCA data
  metadata_ordered <- metadata[match(pca_data$Sample, metadata$sample), ]
  
  # Add Batch and Class columns from metadata
  pca_data$Batch <- metadata_ordered$batch
  pca_data$Class <- metadata_ordered$class
  
  # Plot PCA
  ggplot(pca_data, aes(x = PC1, y = PC2, color = Batch, shape = Class)) +
    geom_point(size = 4) +
    labs(title = title, x = "PC1", y = "PC2") +
    theme_minimal()
}

# Main script
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) {
  stop("Usage: Rscript script.R <counts_file> <metadata_file> <output_folder> <batch>")
}

counts_file <- args[1]
metadata_file <- args[2]
output_folder <- args[3]
batch_choice <- args[4]

# Create output folder if it doesn't exist
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}

# Load count matrix and metadata
counts <- as.matrix(read.table(counts_file, header = TRUE, row.names = 1, sep = "\t"))
metadata <- read.table(metadata_file, header = TRUE, sep = "\t")

# Determine batch handling
use_interaction <- FALSE
batch_factor_choice <- NULL
if (batch_choice == "interaction") {
  use_interaction <- TRUE
} else {
  if (!(batch_choice %in% colnames(metadata))) {
    stop("The specified batch column '", batch_choice, "' does not exist in the metadata.")
  }
  batch_factor_choice <- batch_choice
}

# Perform batch correction
result <- batch_correct_with_combat_seq(counts, metadata, use_interaction = use_interaction, batch_factor_choice = batch_factor_choice)
metadata <- result[[1]]
corrected_counts <- result[[2]]

# Save corrected counts
output_counts_file <- file.path(output_folder, "counts_corrected_combat_seq.tsv")
corrected_counts_df <- data.frame(gene = rownames(corrected_counts), corrected_counts)
write.table(corrected_counts_df, output_counts_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
cat("Batch-corrected counts saved to '", output_counts_file, "'\n", sep = "")

# Plot PCA before and after correction
p1 <- plot_pca(log2(counts + 1), metadata, "PCA Before Batch Correction")
p2 <- plot_pca(log2(corrected_counts + 1), metadata, "PCA After Batch Correction")

# Save PCA plots
output_pca_before <- file.path(output_folder, "pca_before.png")
output_pca_after <- file.path(output_folder, "pca_after.png")

ggsave(output_pca_before, p1, width = 8, height = 8)
ggsave(output_pca_after, p2, width = 8, height = 8)

cat("PCA plots saved to '", output_folder, "'\n", sep = "")
