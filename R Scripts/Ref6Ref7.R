###Set for Gal7
setwd ("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/Gal7")
###Set for Gal6
setwd ("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/Gal6")
###############
library("ggplot2")
library("dplyr")
library("ggbeeswarm")
library("stringr")
###############Load all Files in.


##############################################
#####################GAL7#####################
##############################################
bc_metric_files <- list.files("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/Gal7", pattern = "bar", full.names = T)
k <- list()
for (i in seq(bc_metric_files)){id <- str_extract(bc_metric_files[i], "per_barcode_metrics\\d+") 
id <- paste0("ID_", gsub("per_barcode_metrics", "", be_metric_files))
#id <- paste0("ID_", gsub("per_barcode_metrics", "", bc_metric_files[i]))
k[[i]] <- read.csv(bc_metric_files[i])     
k[[i]]$sample <- id}
bc7_metrics_combined <- as_tibble(base::do.call("rbind",k))
bc7_metrics <- bc7_metrics_combined %>% filter(is_cell == 1) %>% filter(atac_raw_reads > 10000) %>% filter(atac_raw_reads < 50000)
#bc7_metrics$excluded_reason <- NULLbc_metrics$is_cell <- NULLbc_metrics <- bc_metrics %>% select(last_col(),everything())
head(bc7_metrics)
colnames(bc7_metrics)
print(bc7_metrics$sample)
####################################
####################################
plotA7 <- ggplot(bc7_metrics, aes(x=sample, y=atac_TSS_fragments)) + 
  geom_quasirandom(dodge.width = 0.9, varwidth = TRUE, size = 1, show.legend = F, color = "black") +
  geom_violin(position = position_dodge(width = 0.5), alpha = 0.8, draw_quantiles = c(0.25,0.5,0.75), trim = TRUE, scale = "width", na.rm = FALSE, orientation = NA, show.legend = NA, inherit.aes = TRUE, linewidth = 0.1) +
    geom_boxplot(outlier.shape = NA, position = position_dodge(width = 0.5), lwd = 0.6, fatten = 0.4, alpha = 0.7) +
    theme_grey(base_size = 10) + theme(axis.text.x = element_text(angle = 70, vjust = 0.5)) 
ggsave("plotA7.jpeg")

##############################################
#####################GAL6#####################
##############################################
bc_metric_files <- list.files("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/Gal6", pattern = "bar", full.names = T)
k <- list()
for (i in seq(bc_metric_files)){id <- str_extract(bc_metric_files[i], "per_barcode_metrics\\d+")    
k[[i]] <- read.csv(bc_metric_files[i])     
k[[i]]$sample <- id}
bc_metrics_combined <- as_tibble(base::do.call("rbind",k))
bc_metrics_combined
bc_metrics <- bc_metrics_combined %>% filter(is_cell == 1) %>% filter(atac_raw_reads > 10000) %>% filter(atac_raw_reads < 50000)
bc_metrics$excluded_reason <- NULLbc_metrics$is_cell <- NULLbc_metrics <- bc_metrics %>% select(last_col(),everything())
head(bc_metrics)
colnames(bc_metrics)
print(bc_metrics$sample)
####################################
####################################
NplotA6 <- ggplot(bc_metrics, aes(x=sample, y=atac_TSS_fragments)) + 
  geom_quasirandom(dodge.width = 0.9, varwidth = TRUE, size = 1, show.legend = F, color = "black") +
  geom_violin(position = position_dodge(width = 0.5), alpha = 0.8, draw_quantiles = c(0.25,0.5,0.75), trim = TRUE, scale = "width", na.rm = FALSE, orientation = NA, show.legend = NA, inherit.aes = TRUE, linewidth = 0.1) +
    geom_boxplot(outlier.shape = NA, position = position_dodge(width = 0.5), lwd = 0.6, fatten = 0.4, alpha = 0.7) +
    theme_grey(base_size = 10) + theme(axis.text.x = element_text(angle = 70, vjust = 0.5)) 
ggsave("NplotA6.jpeg")

##############################################
#################GAL6 & GAL7##################
##############################################
Metrics6a <- bc_metrics %>% mutate(type = 'ref6')
colnames(Metrics6a)
tail(Metrics6a$type)
Metrics7a <- bc7_metrics %>% mutate(type = 'ref7')
ComboMetrics <- bind_rows(Metrics6a, Metrics7a)

NComboplotATACFRAGS <- ggplot(ComboMetrics, aes(x=sample, y=atac_TSS_fragments, color = type)) + 
  geom_quasirandom(dodge.width = 0.9, varwidth = TRUE, size = 1, show.legend = F, color = "black") +
  geom_violin(position = position_dodge(width = 0.5), alpha = 0.8, draw_quantiles = c(0.25,0.5,0.75), trim = TRUE, scale = "width", na.rm = FALSE, orientation = NA, show.legend = NA, inherit.aes = TRUE, linewidth = 0.1) +
    geom_boxplot(outlier.shape = NA, position = position_dodge(width = 0.5), lwd = 0.6, fatten = 0.4, alpha = 0.7) +
    theme_grey(base_size = 10) + theme(axis.text.x = element_text(angle = 70, vjust = 0.5))
ggsave("NComboplotATACFRAGS.jpeg")
####################################
#################################END
