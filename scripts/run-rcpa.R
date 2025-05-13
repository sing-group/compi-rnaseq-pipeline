unloadNamespace("RCPA")
library(RCPA)
library(SummarizedExperiment)
library(ggplot2)
library(gridExtra)
library(org.Hs.eg.db)

# Function to read properties file into a named list
read_properties <- function(file_path) {
  properties <- list()
  
  # Read lines from the file, ignoring empty lines
  lines <- readLines(file_path, warn = FALSE)
  lines <- lines[lines != ""] # Remove empty lines
  
  for (line in lines) {
    # Skip lines starting with a '#'
    if (grepl("^#", line)) next

    # Skip lines that don't contain an '=' sign
    if (!grepl("=", line)) next
    
    # Split the line into key and value
    parts <- strsplit(line, "=")[[1]]
    key <- trimws(parts[1])
    value <- trimws(parts[2])
    
    # Convert comma-separated values into a vector
    if (grepl(",", value)) {
      value <- strsplit(value, ",")[[1]]
      value <- trimws(value) # Trim whitespace from each element
    }
    
    # Assign to list
    properties[[key]] <- value
  }

  return(properties)
}

check_required_keys <- function(properties_map, required_keys) {
  # Find missing keys
  missing_keys <- setdiff(required_keys, names(properties_map))
  
  if (length(missing_keys) > 0) {
    stop(paste("Missing required keys:", paste(missing_keys, collapse = ", ")))
  } else {
    message("All required keys are present.")
  }
}

load_delite_dea_results <- function(properties_map) {
  res <- read.table(properties_map$delite_dea_results, header = TRUE, sep = ",", quote = "\"")
  meta_df <- read.delim(properties_map$metadata_file, stringsAsFactors = TRUE)
  num_samples <- nrow(meta_df)

  # Remove rows with NA in pvalue column
  res <- res[!is.na(res$pvalue),]

  # Remove rows with duplicated gene_entrezid
  res <- res[!duplicated(res$gene_entrezid),]

  DERes <- data.frame(
      ID = as.character(res$gene_entrezid),
      logFC = as.numeric(res$logFC),
      p.value = as.numeric(res$pvalue),
      pFDR = as.numeric(res$padj),
      statistic = as.numeric(res$logFC), ### Or replace with other statistics used to rank the genes in the enrichment analysis
      logFCSE = 1,   ### just for placeholder, not using this column in runGeneSetAnalysis or runPathwayAnalysis
      avgExpr = 1,   ### just for placeholder, not using this column in runGeneSetAnalysis or runPathwayAnalysis
      sampleSize = num_samples,
      stringsAsFactors = F
  ) %>% drop_na()

  ### Put row names for DERes
  rownames(DERes) <- DERes$ID

  ### Create a SummarizedExperiment object
  DEResult <- SummarizedExperiment::SummarizedExperiment(
      rowData = DERes,
      assays = list(counts = matrix(0, nrow = nrow(DERes), ncol = num_samples)) ## placeholder for assay data, not using this in runGeneSetAnalysis or runPathwayAnalysis
  )

  comparison <- setdiff(unique(meta_df$class), properties_map$reference)
  meta_df$class <- factor(meta_df$class, levels = c(comparison, properties_map$reference))

  design <- model.matrix(~ 0 + class, data = meta_df)
  colnames(design) <- paste0("condition", levels(meta_df$class))
  rownames(design) <- meta_df$sample

  contrast_name <- paste0("condition", comparison, "-condition", properties_map$reference)
  contrast <- matrix(
    c(1, -1), 
    nrow = 2,
    dimnames = list(paste0("condition", levels(meta_df$class)), contrast_name)
  )

  metadata(DEResult)$DEAnalysis.design <- design
  attr(metadata(DEResult)$DEAnalysis.design, "contrasts") <- list(class = "contr.treatment")
  metadata(DEResult)$DEAnalysis.contrast <- contrast

  return(DEResult)
}

process_enrichment_analysis_result <- function(enrichment_analysis_result, work_dir, method, genesets) {
    # Create work_dir/method if not exists
    output_dir <- file.path(work_dir, method)
    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }
    
    enrichment_analysis_result <- enrichment_analysis_result[order(enrichment_analysis_result$pFDR),]
    write.table(
        enrichment_analysis_result, 
        file = file.path(output_dir, "results.csv"), 
        sep = ",", 
        quote = FALSE, 
        row.names = FALSE
    )

    pdf(file.path(output_dir, "volcano.pdf"))
    plot <- RCPA::plotVolcanoPathway(enrichment_analysis_result, sideToLabel = "left", topToLabel = 20, pThreshold = 0.95) + ggtitle(method)
    print(plot)
    dev.off()

    # Select the top 20 pathways from the results
    resultsToPlot <- list(method = enrichment_analysis_result[1:min(20, nrow(enrichment_analysis_result)),])
    selected <- enrichment_analysis_result$ID[order(enrichment_analysis_result$pFDR)]
    selected <- selected[1:min(20, nrow(enrichment_analysis_result))]

    pdf(file.path(output_dir, "forest.pdf"))
    plot <- RCPA::plotForest(resultsList = resultsToPlot, yAxis = "name", statLims = c(-4, 8))
    print(plot)
    dev.off()

    pltHtml <- RCPA::plotPathwayNetwork(
      resultsToPlot,
      genesets = genesets,
      selectedPathways = selected,
      edgeThreshold = 0.75,
      mode = "continuous",
      statistic = "normalizedScore",
      file = paste0(output_dir, "/pathway_network.html")
    )
}


## Parse input parameters
args <- commandArgs(TRUE)

if (length(args) != 1) {
  stop("Please provide the path to the properties file as an argument.")
}

input_file <- args[1]
if (!file(input_file)) {
	stop(paste("Input file not found. Provided path: ", input_file, sep=""))
}

properties_map <- read_properties(input_file)

required_keys <- c("database", "geneset_analysis_methods", "pathway_analysis_methods", "reference", "delite_dea_results", "results_dir")
check_required_keys(properties_map, required_keys)

print(paste("[run-rcpa.R] Load", properties_map$database, "genesets", sep=" "))

if (properties_map$database == "KEGG" ) {
    genesets <- RCPA::getGeneSets(database = "KEGG", org = "hsa", useCache = FALSE)
} else if (properties_map$database == "GO" ) {
    genesets <- getGeneSets("GO", taxid = 9606, useCache = TRUE)

    # TODO: namespace The namespace of the GO terms. E.g, biological_process, molecular_function, cellular_component
    # namespace = c("biological_process", "molecular_function", "cellular_component")
} else {
    exit(paste0("Unknown database: ", properties_map$database))
}

DEResult <- load_delite_dea_results(properties_map)

if(length(properties_map$geneset_analysis_methods) > 1 || !is.na(properties_map$geneset_analysis_methods)) {
  print("[run-rcpa.R] Running gene set enrichment analyses")
  for (method in properties_map$geneset_analysis_methods) {
      tryCatch({
        print(paste0("[run-rcpa.R] Processing: ", method))
          result <- switch(method,
          "fgsea" = {
            fgseaArgsList <- list(minSize = 10, maxSize = Inf)
            runGeneSetAnalysis(DEResult, genesets, method = "fgsea", FgseaArgs = fgseaArgsList)
          },
          "ora" = {
            runGeneSetAnalysis(DEResult, genesets, method = "ora", ORAArgs = list(pThreshold = 0.05))
          },
          "ks" = runGeneSetAnalysis(DEResult, genesets, method = "ks"),
          "wilcox" = runGeneSetAnalysis(DEResult, genesets, method = "wilcox"),
          "gsa" = {
            GSAArgsList <- list(method = "maxmean", minsize = 15, maxsize = 500, nperms = 1000)
            runGeneSetAnalysis(DEResult, genesets, method = "gsa", GSAArgs = GSAArgsList)
          },
          {
            print(paste0("[run-rcpa.R] Unknown or unsupported method: ", method))
            NULL
          }
        )

        if (!is.null(result)) {
          process_enrichment_analysis_result(result, paste0(properties_map$results_dir, "/geneset_enrichment"), method, genesets)
        }
      },
      error = function(e) { message("[run-rcpa.R] Error in ", method, " analysis: ", e$message) }
    )
  }
}

if(length(properties_map$pathway_analysis_methods) > 1 || !is.na(properties_map$pathway_analysis_methods)) {
  print("[run-rcpa.R] Running topology-based enrichment analyses")
  for (method in properties_map$pathway_analysis_methods) {
      tryCatch({
        print(paste0("[run-rcpa.R] Processing: ", method))
          result <- switch(method,
          "spia" = {
            SPIANetwork <- RCPA::getSPIAKEGGNetwork(org = "hsa", updateCache = FALSE)
            SPIAArgsList <- list(nB = 1000, pThreshold = 0.05)
            set.seed(1)
            runPathwayAnalysis(summarizedExperiment = DEResult, network = SPIANetwork, method = "spia", SPIAArgs = SPIAArgsList)
          },
          "cepaORA" = {
            CePaNetwork <- RCPA::getCePaPathwayCatalogue(org = "hsa", updateCache = FALSE)
            CePaORAArgsList<- list(cen = "equal.weight", pThreshold = 0.05)
            set.seed(1)
            runPathwayAnalysis(DEResult, network = CePaNetwork, method = "cepaORA", CePaORAArgs = CePaORAArgsList)
          },
          "cepaGSA" = {
            CePaNetwork <- RCPA::getCePaPathwayCatalogue(org = "hsa", updateCache = FALSE)
            CePaORAArgsList<- list(cen = "equal.weight", pThreshold = 0.05)
            set.seed(1)
            runPathwayAnalysis(DEResult, network = CePaNetwork, method = "cepaGSA", CePaORAArgs = CePaORAArgsList)
          },
          {
            print(paste0("[run-rcpa.R] Unknown or unsupported method: ", method))
            NULL
          }
        )

        if (!is.null(result)) {
          process_enrichment_analysis_result(result, paste0(properties_map$results_dir, "/topology_based_enrichment"), method, genesets)
        }
      },
      error = function(e) { message("[run-rcpa.R] Error in ", method, " analysis: ", e$message) }
    )
  }
}
