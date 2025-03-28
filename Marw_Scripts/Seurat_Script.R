# Load required libraries
{library("Seurat")
  library("hdf5r")
  library("DoubletFinder")
  library("tidyverse")
  library("Signac")
  library("GenomicRanges")
  library("scDblFinder")
  library("patchwork")}

# Define base directory and sample IDs
base_dir <- "/cfs/klemming/projects/supr/sllstore2017078/kaczma-workingdir/RR/scAnalysis/single_cell_gal7b/count_arc_cb/"
sample_ids <- sprintf("ID%02d", c(1:13, 15:20))  # Excluding ID14

gtf_file <- "/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT/Gallus_gallus.bGalGal1.mat.broiler.GRCg7b.112.gtf.gz"
dry_run <- FALSE
path_results <- "/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT"

###############
# Initialize an empty list to store Seurat objects
datasets <- list()

# Loop through all the sample directories
for (sample_id in sample_ids) {
  # Define the sample directory path dynamically based on the sample ID
  sample_dir <- file.path(base_dir, sample_id)
  
  # Check if the sample directory exists
  if (!dir.exists(sample_dir)) {
    message("Skipping missing sample: ", sample_id)
    next
  }
  
  # Define file paths
  h5_path <- file.path(sample_dir, "outs", "filtered_feature_bc_matrix.h5")
  atac_fragments <- file.path(sample_dir, "outs", "atac_fragments.tsv.gz")
  metadata_path <- file.path(sample_dir, "outs", "per_barcode_metrics.csv")
  sample_name <- basename(sample_dir)

  # Step 3: Load RNA and ATAC counts
  counts <- Read10X_h5(h5_path)
  rna_counts <- counts$`Gene Expression`
  atac_counts <- counts$Peaks

  # Step 4: Create Seurat object for RNA (if desired)
  seurat_obj <- NULL
  include_RNA <- TRUE  # Set according to your need
  
  if (include_RNA) {
    message("Creating Seurat object for RNA assay for sample: ", sample_id)
    seurat_obj <- CreateSeuratObject(counts = rna_counts, assay = "RNA", project = sample_name)
  }
  
  # Step 5: Import GTF file for gene annotations
  gtf <- rtracklayer::import(gtf_file, format = "gtf")
  gene.coords <- gtf[gtf$type == "gene"]
  mcols(gene.coords) <- mcols(gene.coords)[, colSums(!is.na(mcols(gene.coords))) > 0]
  
  # Step 6: Add ATAC assay (if desired and file exists)
  include_ATAC <- TRUE  # Set according to your need
  
  if (include_ATAC && file.exists(atac_fragments)) {
    message("Adding ATAC assay for sample: ", sample_id)
    atac_assay <- CreateChromatinAssay(
      counts = atac_counts,
      sep = c(":", "-"),
      fragments = atac_fragments,
      annotation = gene.coords)
    if (is.null(seurat_obj)) {
      seurat_obj <- CreateSeuratObject(assays = list(ATAC = atac_assay))
    } else {
      seurat_obj[["ATAC"]] <- atac_assay
    }
  } else if (include_ATAC) {
    warning("ATAC fragments file not found for sample ", sample_id, ": ", atac_fragments)
  }
  
  # Step 7: Add metadata (if desired and file exists)
  include_metadata <- TRUE  # Set according to your need
  
  if (include_metadata && file.exists(metadata_path)) {
    message("Adding metadata for sample: ", sample_id)
    metadata <- read.csv(metadata_path, row.names = 1)
    seurat_obj <- AddMetaData(seurat_obj, metadata = metadata)
  } else if (include_metadata) {
    warning("Metadata file not found for sample ", sample_id, ": ", metadata_path)
  }
  
  # Store Seurat object for later processing
  datasets[[sample_id]] <- seurat_obj}

###############
# Apply quality control filtering and process the data for each Seurat object
for (sample_id in names(datasets)) {
  seurat_obj <- datasets[[sample_id]]
  
  # Apply quality control filtering (e.g., min_nFeature_RNA, min_counts_atac)
  min_nFeature_RNA <- 1000
  min_counts_atac <- 1
  remove_failed_samples <- TRUE  # Set according to your need
  
  if (!is.null(seurat_obj)) {
    message("Applying quality control filtering for sample: ", sample_id)
    if ("nFeature_RNA" %in% colnames(seurat_obj@meta.data) &&
        "nCount_ATAC" %in% colnames(seurat_obj@meta.data)) {
      cells_to_keep <- which(
        seurat_obj$nFeature_RNA >= min_nFeature_RNA & 
        seurat_obj$nCount_ATAC >= min_counts_atac)
      if (length(cells_to_keep) == 0) {
        if (remove_failed_samples) {
          message("No cells passed filtering for sample ", sample_id, ". Sample will be removed.")
          next
        } else {
          warning("No cells passed filtering for sample ", sample_id, ". Returning unfiltered Seurat object.")
        }
      } else {
        seurat_obj <- subset(seurat_obj, cells = colnames(seurat_obj)[cells_to_keep])
        message("Seurat object created successfully for sample ", sample_id, " with ", ncol(seurat_obj), " high-quality cells.")
      }
    } else {
      warning("Quality metrics not found in Seurat object metadata for sample ", sample_id, ". Skipping filtering.")
    }
  }
  
  # Process data (e.g., normalization, feature selection, scaling, PCA, tSNE)
  seurat_obj <- RenameCells(seurat_obj, add.cell.id = sample_id)
  alldata <- PercentageFeatureSet(seurat_obj, "^RP[SL]", col.name = "percent_ribo")
  Bothdata <- PercentageFeatureSet(seurat_obj, "^MT-|^ND1|^ND3|^ND4|^ND5|^ND6|^ATP6$|^ATP8$|^CYTB|^COII|^COX3", col.name = "percent_mito")
  data.filt <- subset(Bothdata, percent_mito < 10)
  
  # Normalize data and fix it
  data.filt <- NormalizeData(data.filt)
  data.fix <- FindVariableFeatures(data.filt, selection.method = "vst", nfeatures = 2000)
  data.fix <- ScaleData(data.fix, vars.to.regress = c("nFeature_RNA", "percent_mito"), verbose = F)
  data.fix <- RunPCA(data.fix, verbose = F, npcs = 20)
  data.fix <- RunTSNE(
    data.fix,
    reduction = "pca",
    reduction.name = "tsne",
    reduction.key = "tSNE_")
  
  # Store processed Seurat object for later use
  datasets[[sample_id]] <- data.fix}

###############
# DoubletFinder for each sample
for (sample_id in names(datasets)) {
  data.fix <- datasets[[sample_id]]
  
  # DoubletFinder
  nExp <- round(ncol(data.fix) * 0.015)  # Set to 0.015 percent of total cells
  data.fix2 <- doubletFinder(data.fix, pN = 0.25, pK = 0.09, nExp = nExp, PCs = 1:10)
  
  # Name the DF prediction column
  DF.name <- colnames(data.fix2@meta.data)[grepl("DF.classification", colnames(data.fix2@meta.data))]
  data.fix2 <- data.fix2[, data.fix2@meta.data[, DF.name] == "Singlet"]
  
  # Update list with filtered object
  datasets[[sample_id]] <- data.fix2}

###############
# Merge all datasets after processing
if (length(datasets) > 1) {
  # Step 1: Merge the datasets
  merged_data <- Reduce(function(x, y) merge(x, y, add.cell.ids = c("Sample1", "Sample2")), datasets)
  
  # Step 2: Check if PCA is present in merged data, if not, run PCA
  if (!"pca" %in% names(merged_data@reductions)) {
    message("PCA not found in merged data. Running PCA...")
    merged_data <- RunPCA(merged_data, verbose = FALSE)
  }

  # Step 3: Integrate layers using CCA (after all samples are processed and QC is done)
  merged_data <- IntegrateLayers(object = merged_data, method = "CCA", orig.reduction = "pca", new.reduction = "integrated.cca", verbose = FALSE)

  # Step 4: Re-join layers after integration
  merged_data[["RNA"]] <- JoinLayers(merged_data[["RNA"]])

  # Step 5: Perform clustering on integrated data
  merged_data <- FindNeighbors(merged_data, reduction = "integrated.cca", dims = 1:30)
  merged_data <- FindClusters(merged_data, resolution = 1)

  # Step 6: Save the merged and integrated Seurat object
  saveRDS(merged_data, file.path(path_results, "merged_seurat_integrated_object.rds"))
  message("Integration and clustering complete. Saved merged Seurat object.")
} else {
  message("No samples to merge.")
}









#Check if PCA worked
for (sample_id in names(datasets)) {
  seurat_obj <- datasets[[sample_id]]
  
  # Check if PCA is available
  if (!"pca" %in% names(seurat_obj@reductions)) {
    message("PCA not found in Seurat object for sample: ", sample_id)
  } else {
    message("PCA is available for sample: ", sample_id)
  }}

###############
# Merge all datasets after processing
if (length(datasets) > 1) {
  merged_data <- Reduce(function(x, y) merge(x, y, add.cell.ids = c("Sample1", "Sample2")), datasets)
  
  # Integrate Layers using CCA (after all samples are processed and QC is done)
  merged_data <- IntegrateLayers(object = merged_data, method = CCAIntegration, orig.reduction = "pca", new.reduction = "integrated.cca", verbose = FALSE)
  
  # Re-join layers after integration
  merged_data[["RNA"]] <- JoinLayers(merged_data[["RNA"]])

  # Perform clustering on integrated data
  merged_data <- FindNeighbors(merged_data, reduction = "integrated.cca", dims = 1:30)
  merged_data <- FindClusters(merged_data, resolution = 1)

  # Save the merged and integrated Seurat object
  saveRDS(merged_data, file.path(path_results, "merged_seurat_integrated_object.rds"))
  message("Integration and clustering complete. Saved merged Seurat object.")
} else {
  message("No samples to merge.")}
