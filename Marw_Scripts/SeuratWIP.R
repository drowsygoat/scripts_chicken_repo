library("Seurat")
library("hdf5r")
library("tidyverse")
###Proto-Loop###
filename1 <- "/cfs/klemming/projects/supr/sllstore2017078/kaczma-workingdir/RR/scAnalysis/single_cell_gal7b/count_arc_cb/ID01/outs/"
ID01<- Seurat::Read10X_h5(
    filename = file.path(filename1, "filtered_feature_bc_matrix.h5"),
    use.names = T)
sdata.ID01 <- CreateSeuratObject(ID01, project = "ID01")

###Actual Loop###
base_path <- "/cfs/klemming/projects/supr/sllstore2017078/kaczma-workingdir/RR/scAnalysis/single_cell_gal7b/count_arc_cb"
seurat_objects <- list()
for (i in 1:20) {
  sample_id <- sprintf("ID%02d", i)
  sample_dir <- file.path(base_path, sample_id, "outs")
  if (dir.exists(sample_dir)) {
    h5_file <- file.path(sample_dir, "filtered_feature_bc_matrix.h5")
    if (file.exists(h5_file)) {
      sample_data <- Seurat::Read10X_h5(filename = h5_file, use.names = TRUE)
      seurat_objects[[sample_id]] <- CreateSeuratObject(sample_data, project = sample_id)
      cat("Loaded and created Seurat object for", sample_id, "\n")
    } else {
      cat("Skipping", sample_id, ": file not found at", h5_file, "\n")
    }
  } else {
    cat("Skipping", sample_id, ": directory not found at", sample_dir, "\n")}}
head(seurat_objects)
tail(seurat_objects)
seurat_objects$ID20 #check any ID
###TAKING SOME COUNTS###
mean(seurat_objects$ID01$nCount_RNA) 
#ID01: 6412   #ID02: 17883  #ID03:  24495   #ID04:  27711   #ID05:  14101   #ID06:  14150   
#ID07: 8748   #ID08:  7029  #ID09:  10565   #ID10:  10489   #ID11:  13548   #ID12:  12528   
#ID13: 11631  #ID14:  NaN   #ID15:  12875   #ID16:  15885   #ID17:  18583   #ID18:  20986   
#ID19: 17893  #ID20:  15735 ###MEAN = ~14733
mean(seurat_objects$ID01$nFeature_RNA)
#ID01: 3049   #ID02: 8229   #ID03:  10771   #ID04:  11902   #ID05:  6711    #ID06:  6669   
#ID07: 4301   #ID08: 3502   #ID09:  5230    #ID10:  5178    #ID11:  6518    #ID12:  6010 
#ID13: 5593   #ID14: NaN    #ID15:  6161    #ID16:  7412    #ID17:  8505    #ID18:  9372
#ID19: 8068   #ID20: 7376   ###MEAN = 6871
nrow(seurat_objects$ID01)
#ID01: 111851   #ID02: 167872   #ID03:  168432   #ID04:  171524   #ID05:  164509    #ID06:  166066  
#ID07: 160307   #ID08: 155863   #ID09:  161687   #ID10:  158348   #ID11:  156517    #ID12:  160306
#ID13: 153967   #ID14: NaN      #ID15:  162116   #ID16:  157404   #ID17:  158247    #ID18:  165767
#ID19: 146112   #ID20: 159476 ###MEAN = 
####################################
###Seurat Object workable via $ID###
seurat_objects <- list(seurat_objects[["ID01"]], seurat_objects[["ID02"]], 
                       seurat_objects[["ID03"]], seurat_objects[["ID04"]], 
                       seurat_objects[["ID05"]], seurat_objects[["ID06"]], 
                       seurat_objects[["ID07"]], seurat_objects[["ID08"]], 
                       seurat_objects[["ID09"]], seurat_objects[["ID10"]], 
                       seurat_objects[["ID11"]], seurat_objects[["ID12"]], 
                       seurat_objects[["ID13"]], seurat_objects[["ID14"]], 
                       seurat_objects[["ID15"]], seurat_objects[["ID16"]], 
                       seurat_objects[["ID17"]], seurat_objects[["ID18"]], 
                       seurat_objects[["ID19"]], seurat_objects[["ID20"]])

########################
###Merged & Filtered####
merged_seurat <- Reduce(function(x, y) merge(x, y), seurat_objects)
dim(merged_seurat) # 196600
object.size(merged_seurat) #15515842944 bytes = 15.5 GB!

SeuratFilt <- subset(merged_seurat, subset = nFeature_RNA > 1000)
#SeuratFilt <- subset(merged_seurat, subset = nFeature_RNA < 40000), only use for graphs
dim(SeuratFilt)    # 194535
table(SeuratFilt$orig.ident)
#ID01  ID02  ID03  ID04  ID05  ID06  ID07  ID08  ID09  ID10  ID11  ID12  ID13 
#3155  6694  5401  5692  9317 10735 18297 20000 18675 16333 13335 10187  7654 
#ID15  ID16  ID17  ID18  ID19  ID20 
#13163  8324  7257  8536  4440  9384

###########################
#######GRAPHS BELOW########
###########################
featsF <- c("nFeature_RNA")
VPlotF <- VlnPlot(SeuratFilt, group.by = "orig.ident", split.by = "orig.ident",features = featsF, pt.size = 0.1, ncol = 1)
ggsave("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT/VPlotF.jpeg")

############
############
SeuratFiltc <- subset(merged_seurat_object, subset = nCount_RNA < 75000)
dim(SeuratFiltc)   # 196381
featsC <- c("nCount_RNA")
VPlotC <- VlnPlot(SeuratFiltc, group.by = "orig.ident", split.by = "orig.ident",features = featsC, pt.size = 0.1, ncol = 1)
ggsave("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT/VPlotC.jpeg")

############
############ plot the different QC-measures as scatter plots
SeuratFiltf <- subset(SeuratFilt, subset = nCount_RNA < 75000)
FPlot <- FeatureScatter(SeuratFiltf, "nCount_RNA", "nFeature_RNA", group.by = "orig.ident", pt.size = .5)
ggsave("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT/FPlot.jpeg")

############ plot the percentage of counts per gene
############ WIP BELOW
C <- SeuratFilt[["RNA"]]$counts
dim(C)
C@x <- C@x / rep.int(colSums(C), diff(C@p)) * 100
most_expressed <- order(Matrix::rowSums(C), decreasing = T)[20:1]
# Create a jpeg file for saving the plot
jpeg("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/WorkdirRAT/BPlot.jpeg")#, width = 15, height = 10, res = 300)

par(mar = c(5, 8, 2, 1))  # Reduce margins

# Plot the boxplot MAKE Y AXIS VISABLE!
boxplot(as.matrix(t(C[most_expressed, ])),
    cex = 0.1, las = 1, xlab = "Percent counts per cell",
    col = (scales::hue_pal())(20)[20:1], horizontal = TRUE,
    cex.axis = 0.8, outline = FALSE)

# Close the jpeg device to save the file
dev.off()

#######################
######Ribo & Mito######
#######################
Metadata <- alldata[[]]
head(Metadata)
# Ribosomal
alldata <- PercentageFeatureSet(SeuratFilt, "^RP[SL]", col.name = "percent_ribo")
mean(alldata$percent_ribo) #0.517%
# Mitochondrial
alldata <- PercentageFeatureSet(merged_seurat, "^MT", col.name = "percent_mito")

mean(alldata$percent_mito) 
head(alldata)

