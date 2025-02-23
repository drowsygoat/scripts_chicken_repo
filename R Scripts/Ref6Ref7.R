###Set for Gal7
setwd ("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/Gal7")
###Set for Gal6
setwd ("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/Gal6")
###############
library("ggplot2")
library("dplyr")
library("ggbeeswarm")
library("stringr")

##############################################
#####################GAL7#####################
##############################################
bc7_metric_files <- list.files("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/Gal7", pattern = "bar", full.names = T)
k <- list()
for (i in seq(bc7_metric_files)){id7 <- str_extract(bc7_metric_files[i], "per_barcode_metrics\\d+") 
  id7 <- paste0("ID_", gsub("per_barcode_metrics", "", id7))
k[[i]] <- read.csv(bc7_metric_files[i])     
k[[i]]$sample <- id7}
bc7_metrics_combined <- as_tibble(base::do.call("rbind",k))
bc7_metrics <- bc7_metrics_combined %>% filter(is_cell == 1) %>% filter(atac_raw_reads > 10000) %>% filter(atac_raw_reads < 50000)
head(bc7_metrics)
colnames(bc7_metrics)
print(bc7_metrics$sample)
####################################
####################################
FNplotA7 <- ggplot(bc7_metrics, aes(x=sample, y=atac_TSS_fragments)) + 
  geom_quasirandom(dodge.width = 0.9, varwidth = TRUE, size = 1, show.legend = F, color = "black") +
  geom_violin(position = position_dodge(width = 0.5), alpha = 0.8, draw_quantiles = c(0.25,0.5,0.75), trim = TRUE, scale = "width", na.rm = FALSE, orientation = NA, show.legend = NA, inherit.aes = TRUE, linewidth = 0.1) +
    geom_boxplot(outlier.shape = NA, position = position_dodge(width = 0.5), lwd = 0.6, fatten = 0.4, alpha = 0.7) +
    theme_grey(base_size = 10) + theme(axis.text.x = element_text(angle = 70, vjust = 0.5)) 
ggsave("FNplotA7.jpeg")
getwd()

##############################################
#####################GAL6#####################
##############################################
bc6_metric_files <- list.files("/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/Gal6", pattern = "bar", full.names = T)
k <- list()
for (i in seq(bc6_metric_files)){id6 <- str_extract(bc6_metric_files[i], "per_barcode_metrics\\d+")
  id6 <- paste0("ID_", gsub("per_barcode_metrics", "", id6))
k[[i]] <- read.csv(bc6_metric_files[i])     
k[[i]]$sample <- id6}
bc6_metrics_combined <- as_tibble(base::do.call("rbind",k))
bc6_metrics <- bc6_metrics_combined %>% filter(is_cell == 1) %>% filter(atac_raw_reads > 10000) %>% filter(atac_raw_reads < 50000) ##Don't trim the ATAC_TSS_FRAGS, instead to this so all TSS_FRAGS are in!
head(bc6_metrics)
colnames(bc6_metrics)
print(bc6_metrics$sample)
####################################
####################################
FNplotA6 <- ggplot(bc6_metrics, aes(x=sample, y=atac_TSS_fragments)) + 
  geom_quasirandom(dodge.width = 0.9, varwidth = TRUE, size = 1, show.legend = F, color = "black") +
  geom_violin(position = position_dodge(width = 0.5), alpha = 0.8, draw_quantiles = c(0.25,0.5,0.75), trim = TRUE, scale = "width", na.rm = FALSE, orientation = NA, show.legend = NA, inherit.aes = TRUE, linewidth = 0.1) +
    geom_boxplot(outlier.shape = NA, position = position_dodge(width = 0.5), lwd = 0.6, fatten = 0.4, alpha = 0.7) +
    theme_grey(base_size = 10) + theme(axis.text.x = element_text(angle = 70, vjust = 0.5)) 
ggsave("FNplotA6.jpeg")
getwd()

##############################################
#################GAL6 & GAL7##################
##############################################
Metrics6a <- bc6_metrics %>% mutate(type = 'ref6')
Metrics7a <- bc7_metrics %>% mutate(type = 'ref7')
ComboMetrics <- bind_rows(Metrics6a, Metrics7a)

FNComboMetricsFILL <- ggplot(ComboMetrics, aes(x=sample, y=atac_TSS_fragments, fill = type)) + 
  geom_quasirandom(alpha = 0.3, dodge.width = 0.9, varwidth = TRUE, size = 0.3, show.legend = F, color = "black") +
  geom_violin(position = position_dodge(width = 0.9), alpha = 0.3, draw_quantiles = c(0.25,0.5,0.75), trim = TRUE, scale = "width", na.rm = FALSE, orientation = NA, show.legend = NA, inherit.aes = TRUE, linewidth = 0.1) +
    geom_boxplot(outlier.shape = NA, position = position_dodge(width = 0.9), lwd = 0.6, fatten = 0.2, alpha = 0.5) +
    theme_grey(base_size = 5) + theme(axis.text.x = element_text(angle = 70, vjust = 0.5)) +
    labs(title = "Ref6 vs Ref7 in TSS_fragments", color = "Sample Type") +  # Adding title and legend label
    theme_grey(base_size = 5) +
  theme(
    axis.text.x = element_text(angle = 70, vjust = 0.7, size = 9),  # Adjust size of x-axis tick labels
    axis.text.y = element_text(size = 10),  # Adjust size of y-axis tick labels
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 14),  # Increase y-axis title size
    plot.title = element_text(size = 16, hjust = 0.5)  # Increase title size and center it
  )
ggsave("FNComboMetricsFILL.jpeg", height = 10, width =18)
getwd()
####################################
#################################END
