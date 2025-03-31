####Library Start
{   library(Seurat)
    library(patchwork)
    library(ggplot2)
    library(pheatmap)
    library(clustree)}

# Define the base path for your files
base_path <- "/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT"
alldata <- readRDS("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT/MSIO2.rds")

# Recalculate variable features and filter out those that aren't in the expression matrix
alldata <- ScaleData(alldata, vars.to.regress = c("nFeature_RNA", "nCount_RNA"), verbose = F)
alldata <- FindVariableFeatures(alldata, selection.method = "vst", nfeatures = 1000) # OG 2000
alldata <- RunPCA(alldata, features = VariableFeatures(alldata), npcs = 20)

# Use the CCA integration to create the neighborhood graph
alldata <- FindNeighbors(alldata, dims = 1:20, k.param = 60, prune.SNN = 1 / 15, reduction = "pca")
names(alldata@graphs)
alldata <- FindClusters(alldata, resolution = 2, algorithm = 1, graph.name = "integrated_snn")

# Run UMAP OR tSNE
alldata <- RunUMAP(alldata, dims = 1:10, verbose = F)
alldata <- RunTSNE(
    alldata,
    reduction = "pca",
    dims = 1:10,
    reduction.name = "tsne",
    reduction.key = "tSNE_")

# Make a directory for saving the plots if not already present
output_dir <- "/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT/Graphs/Clusters"
if (!dir.exists(output_dir)) dir.create(output_dir)

# Create an empty list to store the individual plots
sample_plots <- list()
head(alldata)

# Generate the individual plots per sample based on "orig.ident"
for (sample in unique(alldata$orig.ident)) {
  # Plot UMAP by sample
  sample_plot <- DimPlot(alldata, reduction = "tsne", group.by = "seurat_clusters", 
                         cells = WhichCells(alldata, expression = orig.ident == sample), label = TRUE) +
    ggtitle(paste("Sample", sample))
  
  # Store the plot in the list
  sample_plots[[as.character(sample)]] <- sample_plot
}

# Combine all the individual plots into one large plot using patchwork
combined_plot <- wrap_plots(sample_plots, ncol = 5)  # Adjust `ncol` to control number of plots per row

# Save the combined plot as a single image
ggsave(file.path(output_dir, "All_Samples_TSNE2.jpeg"), plot = combined_plot, device = "jpeg", width = 20, height = 16, dpi = 300)
