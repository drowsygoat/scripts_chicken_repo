# Load required libraries
library("Seurat")
library("hdf5r")
library("DoubletFinder")
library("tidyverse")
library("Signac")
library("GenomicRanges")
library("scDblFinder")
library("patchwork")
library("rtracklayer")

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
  include_ATAC <- FALSE  # Set according to your need
  
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

  # Step 8: Subset 10% of random cells from each sample
  if (ncol(seurat_obj) > 1000) {
    message("Subsetting 10% of random cells for sample: ", sample_id)
    set.seed(123)  # Set a seed for reproducibility
    num_cells_to_sample <- round(0.1 * ncol(seurat_obj))  # 10% of total cells
    random_cells <- sample(colnames(seurat_obj), num_cells_to_sample)
    seurat_obj <- subset(seurat_obj, cells = random_cells)
    
    # Ensure that dimnames are correctly assigned after subsetting
    rownames(seurat_obj) <- rownames(rna_counts)  # Restore feature names
    colnames(seurat_obj) <- random_cells  # Restore cell names
  } else {
    message("Sample has less than 1000 cells. Using all cells for sample: ", sample_id)
  }
  
  # Store Seurat object for later processing
  datasets[[sample_id]] <- seurat_obj
}

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
  seurat_obj <- PercentageFeatureSet(seurat_obj, "^RP[SL]", col.name = "percent_ribo")
  seurat_obj <- PercentageFeatureSet(seurat_obj, "^MT-|^ND1|^ND3|^ND4|^ND5|^ND6|^ATP6$|^ATP8$|^CYTB|^COII|^COX3", col.name = "percent_mito")
  data.filt <- subset(seurat_obj, percent_mito < 10)
  
  # Normalize data and fix it later
  data.filt <- NormalizeData(data.filt)
  data.fix <- FindVariableFeatures(data.filt, selection.method = "vst", nfeatures = 2000)
  data.fix <- ScaleData(data.fix, vars.to.regress = c("nFeature_RNA", "percent_mito"), verbose = F)
  #data.fix <- RunPCA(data.fix, verbose = F, npcs = 20)
  #data.fix <- RunTSNE(
   # data.fix,
   # reduction = "pca",
   # reduction.name = "tsne",
   # reduction.key = "tSNE_")
  
  # Store processed Seurat object for later use
  datasets[[sample_id]] <- data.fix
}

###############
# DoubletFinder for each sample
for (sample_id in names(datasets)) {
  data.fix <- datasets[[sample_id]]
  
  # Check if PCA is available, and if not, run PCA
  if (!"pca" %in% names(data.fix@reductions)) {
    message("PCA not found for sample ", sample_id, ". Running PCA...")
    data.fix <- RunPCA(data.fix, verbose = FALSE, npcs = 20)
  }

  # DoubletFinder
  nExp <- round(ncol(data.fix) * 0.015)  # Set to 0.015 percent of total cells
  data.fix2 <- DoubletFinder::doubletFinder(data.fix, pN = 0.25, pK = 0.09, nExp = nExp, PCs = 1:10)
  
  # Name the DF prediction column
  DF.name <- colnames(data.fix2@meta.data)[grepl("DF.classification", colnames(data.fix2@meta.data))]
  data.fix2 <- data.fix2[, data.fix2@meta.data[, DF.name] == "Singlet"]
  
  # Update list with filtered object
  datasets[[sample_id]] <- data.fix2
}

############### 
# Merge all datasets after processing
if (length(datasets) > 1) {
  # Step 1: Rename the cells to ensure unique identifiers before merging
  for (i in 1:length(datasets)) {
    datasets[[i]] <- RenameCells(datasets[[i]], add.cell.id = paste("Sample_", i, sep = ""))
  }
  
  # Step 2: Identify integration anchors
  integration_anchors <- FindIntegrationAnchors(object.list = datasets, dims = 1:30, anchor.features = 2000, reduction = "cca")
  
  # Step 3: Integrate the datasets using the anchors
  merged_data <- IntegrateData(anchorset = integration_anchors, dims = 1:30)

  # Step 6: Save the merged and integrated Seurat object
  saveRDS(merged_data, file.path(path_results, "MSIO2.rds"))
  message("Integration and clustering complete. Saved merged Seurat object.")
} else {
  message("No samples to merge.")
}
