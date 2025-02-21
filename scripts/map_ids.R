## Script input parameters:
##  1.- DElite results: path to the CSV file with DEA results from DElite (1st column must be the gene_ensembl_id)
##  2.- Gene mappings: path to the TSV file with gene mappings (3 columns: gene_ensembl_id, gene_name, gene_biotype)
##  3.- Debug: a logical value to print debug information and store the full annotations file for debugging purposes

library(org.Hs.eg.db)

args <- commandArgs(TRUE)

if (length(args) != 3) {
    stop("Usage: Rscript mapping.R <DElite_results_file> <gene_mappings_file> <debug>")
}

delite_results <- args[1]
gene_mappings <- args[2]
debug <- as.logical(args[3])
if (is.na(debug)) {
    print("Invalid debug mode, must be TRUE or FALSE")
}

delite_results_mod <- gsub(".csv", "_with_annotations_full.csv", delite_results)
delite_results_mod_clean <- gsub(".csv", "_with_genes_clean.csv", delite_results)

print(paste('Processing DElite results: ', delite_results, sep=""))

tsv <- read.table(file = delite_results, sep = ",", header = TRUE)
mapping <- read.table(file = gene_mappings, sep = "\t", header = TRUE)

if (nrow(tsv) == 0) {
    print("DElite results file is empty")
    q("no", status = 0)
}

#
# 1. Add gene mappings to the DEA results by using the mappings file
#

merged_tsv <- merge(tsv, mapping, by.x = "X", by.y = "gene_id", all.x = TRUE)
colnames(merged_tsv)[1] <- "gene_ensembl_id"
colnames(merged_tsv)[ncol(merged_tsv) - 1] <- "gtf_gene_name"
colnames(merged_tsv)[ncol(merged_tsv)] <- "gtf_gene_biotype"
merged_tsv <- merged_tsv[order(merged_tsv$padj), ]

#
# This function is a wrapper around AnnotationDbi::mapIds that allows for mapping multiple columns at once
# using "first" or "asNA" for the multiVals parameter.
# 
# The function also handles the behaviour of AnnotationDbi::mapIds when any of the keys are not found in 
# the database. By default, the function raises an error, which is not raises if at least one key is mapped.
#
multipleMapIds <- function(db, keys, keytype, multiVals, columns) {
    mapping_list <- lapply(columns, function(column) {
        tryCatch({
            AnnotationDbi::mapIds(db, keys = keys, column = column, keytype = keytype, multiVals = multiVals)
        }, error = function(e) {
            rep(NA, length(keys))
        })
    })
    
    mapping_df <- data.frame(keys)
    colnames(mapping_df) <- keytype
    
    for (i in seq_along(columns)) {
        mapping_df[[columns[i]]] <- as.vector(mapping_list[[i]])
    }
    
    return(mapping_df)
}

#
# 2. For those genes without a gene name, try to find it using the org.Hs.eg.db package
# and map the gene_ensembl_id to SYMBOL (i.e. gene name) and ENTREZID (i.e. gene ID, for RCPA)
#

unmapped_ensembl_ids = merged_tsv[is.na(merged_tsv[["gtf_gene_name"]]),]$gene_ensembl_id
if (length(unmapped_ensembl_ids) == 0) {
    print("All genes have a gene name in the GTF mapping file")
    merged_tsv_2 <- merged_tsv
    merged_tsv_2$gene_entrez_id_1 <- NA
} else {
    print(paste("There are ", length(unmapped_ensembl_ids), " genes without a gene name, obtainig them trough AnnotationDbi", sep=""))

    mapping_df <- multipleMapIds(
        org.Hs.eg.db, 
        unmapped_ensembl_ids, 
        "ENSEMBL", 
        "first", 
        c("ENTREZID", "SYMBOL")
    )
    colnames(mapping_df) <- c("gene_ensembl_id", "gene_entrez_id_1", "gene_name")

    merged_tsv_2 <- merge(merged_tsv, mapping_df, by.x = "gene_ensembl_id", by.y = "gene_ensembl_id", all.x = TRUE)
}

#
# 3. For those genes that do not have gene_entrez_id_1 but have gtf_gene_name, use this column (gtf_gene_name) 
# to try to find the ENTREZID using AnnotationDbi::mapIds
#

missing_entrezid <- merged_tsv_2[is.na(merged_tsv_2$gene_entrez_id_1) & !is.na(merged_tsv_2$gtf_gene_name), ]$gtf_gene_name

if (length(missing_entrezid) == 0) {
    print("All genes have been mapped into a gene entrez id")
    merged_tsv_3 <- merged_tsv_2
    merged_tsv_3$gene_entrez_id_2 <- NA
} else {
    print(paste("There are ", length(missing_entrezid), " genes without a gene entrez id, obtainig them trough AnnotationDbi", sep=""))

    mapping_df_2 <- multipleMapIds(
        org.Hs.eg.db, 
        missing_entrezid, 
        "SYMBOL", 
        "first", 
        c("ENTREZID")
    )
    colnames(mapping_df_2) <- c("gene_name", "gene_entrez_id_2")

    merged_tsv_3 <- merge(merged_tsv_2, mapping_df_2, by.x = "gtf_gene_name", by.y = "gene_name", all.x = TRUE)
}

#
# 4. Now we will create two new columns: final_gene_name and final_gene_entrezid
# final_gene_name is the result of the following logic: put gtf_gene_name if it is not NA, otherwise put gene_name
# final_gene_entrezid is the result of the following logic: put gene_entrez_id_1 if it is not NA, otherwise put gene_entrez_id_2
#
merged_tsv_3$final_gene_name <- ifelse(is.na(merged_tsv_3$gtf_gene_name), merged_tsv_3$gene_name, merged_tsv_3$gtf_gene_name)
merged_tsv_3$final_gene_entrezid <- ifelse(is.na(merged_tsv_3$gene_entrez_id_1), merged_tsv_3$gene_entrez_id_2, merged_tsv_3$gene_entrez_id_1)

if (debug) {
    write.table(merged_tsv_3, row.names = FALSE, file = delite_results_mod, sep = ",")
}

#
# 5. Clean the data frame by removing the columns that are not needed
# The final dataframe must have only "final_gene_name","final_gene_entrezid","gtf_gene_biotype" and the original DEA columns
# And gtf_gene_biotype must be gene_biotype
#

original_columns <- setdiff(colnames(tsv), "X")
merged_tsv_3_clean <- merged_tsv_3[, c("gene_ensembl_id", "final_gene_name", "final_gene_entrezid", "gtf_gene_biotype", original_columns)]
colnames(merged_tsv_3_clean)[1] <- "gtf_gene_id"
colnames(merged_tsv_3_clean)[2] <- "gene_name"
colnames(merged_tsv_3_clean)[3] <- "gene_entrezid"
colnames(merged_tsv_3_clean)[4] <- "gene_biotype"
write.table(merged_tsv_3_clean, row.names = FALSE, file = delite_results_mod_clean, sep = ",")
