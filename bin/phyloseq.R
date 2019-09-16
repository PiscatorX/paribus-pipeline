#!/usr/bin/env Rscript
rm(list=ls())
cat("\f")

library(vegan)
library(phyloseq)
library(ggplot2)
library(argparse)
library(dplyr)

otu_table_filename = "/home/drewx/Documents/DevOps/PR2/phyloseq/SHB_18S_feature_table.tsv"
taxa_filename =  "/home/drewx/Documents/DevOps/PR2/phyloseq/taxonomy_headers.tsv"
metadata_filename = "/home/drewx/St.Helena.MetaT/Raw/18S-Data/18S_metadata_phyloseq.tsv"
tree_filename = "/home/drewx/Documents/DevOps/PR2/phyloseq/tree.nwk"
outdir = "/home/drewx/Documents/DevOps/PR2_CTD"

setwd(outdir)
otu_table_matrix <- as.matrix(read.table(otu_table_filename, sep = "\t",  header=TRUE, row.names = 1))
taxonomy_matrix  <- as.matrix(read.table(file = taxa_filename, sep = "\t", header = TRUE, row.names = 1))
metadata <- read.table(metadata_filename, header = TRUE, row.names = 1)
phy_tree <- read_tree(tree_filename)

# Import all as phyloseq objects
otu <- otu_table(otu_table_matrix, taxa_are_rows = TRUE)
tax <- tax_table(taxonomy_matrix)
  meta <- sample_data(metadata)

taxa_names(otu)
taxa_names(tax)
taxa_names(phy_tree)
sample_names(otu)
sample_names(meta)

###################################### Ab(%) ###################################################
otu_table_matrix_df <- as.data.frame(otu_table_matrix)


for (sample in  colnames(otu_table_matrix_df)){
  print(sum(otu_table_matrix_df[sample]))
  break
}




######################################  0m  ###################################################
depth0m <-  rownames(metadata)[metadata$depth == 0]
OTU_0m <- otu_table(as.matrix(otu_table_matrix[,depth0m]), taxa_are_rows = TRUE) 
ps0m <- phyloseq(OTU_0m, tax, meta, phy_tree)
rarecurve(t(otu_table(ps0m)), step=50, cex=0.5)
ps0m_rarefied <- rarefy_even_depth(ps0m, rngseed=1, sample.size=0.9*min(sample_sums(ps0m_rarefied)), replace=F)
# ctd_metrics_plot <- plot_richness(ps_rarefied, x="day", color="depth", measures=c("Observed", "Chao1", "Simpson")) 
# ctd_metrics_plot$layers <- ctd_metrics_plot$layers[-1]
plot_bar(ps0m_rarefied, fill="Rank_3")


######################################  14m  #################################################
depth14m <-  rownames(metadata)[metadata$depth == 14]
OTU_14m <- otu_table(as.matrix(otu_table_matrix[,depth14m]), taxa_are_rows = TRUE)
ps14m <- phyloseq(OTU_14m, tax, meta, phy_tree)
rarecurve(t(otu_table(ps14m)), step=50, cex=0.5)
ps14m_rarefied <- rarefy_even_depth(ps14m, rngseed=1, sample.size=0.9*min(sample_sums(ps)), replace=F)



######################################  25m  #################################################
depth25m <-  rownames(metadata)[metadata$depth == 25]
OTU_25m <- otu_table(as.matrix(otu_table_matrix[,depth25m]), taxa_are_rows = TRUE)
ps25m <- phyloseq(OTU_25m, tax, meta, phy_tree)
rarecurve(t(otu_table(ps25m)), step=50, cex=0.5)
ps25m_rarefied <- rarefy_even_depth(ps25m, rngseed=1, sample.size=0.9*min(sample_sums(ps)), replace=F)



###############################################################################################
ps <- phyloseq(otu, tax, meta, phy_tree)

rarecurve(t(otu_table(ps)), step=50, cex=0.5)

ps_rarefied <- rarefy_even_depth(ps, rngseed=1, sample.size=0.9*min(sample_sums(ps)), replace=F)

rarecurve(t(otu_table(ps_rarefied)), step=50, cex=0.5)

plot_bar(ps_rarefied, fill="Rank_2")

# theme_set(theme_bw())
# 
# p1 <- plot_richness(ps.rarefied, x="day", color="depth", measures=c("Observed")) 
# p1$layers <- p1$layers[-1]
# p1 + geom_point(size=5, aes(colour=factor(depth)))
# 
# #!/usr/bin/env Rscript
# 
# library(vegan)
# library(phyloseq)
# library(ggplot2)
# library(argparse)
# 
# 
# otu_table_filename = "/home/drewx/Documents/DevOps/18S_silva/phyloseq/SHB_18S_silva_feature_table.tsv"
# taxa_filename =  "/home/drewx/Documents/DevOps/18S_silva/phyloseq/taxonomy.tsv"
# metadata_filename = "/home/drewx/St.Helena.MetaT/Raw/18S-Data/18S_metadata_phyloseq.tsv"
# tree_filename = "/home/drewx/Documents/DevOps/18S_silva/phyloseq/tree.nwk"
# 
# otu_table_matrix <- as.matrix(read.table(otu_table_filename, sep = "\t",  header=TRUE, row.names = 1))
# taxonomy_matrix  <- as.matrix(read.table(file = taxa_filename, sep = "\t", header = TRUE, row.names = 1))
# metadata <- read.table(metadata_filename, header = TRUE, row.names = 1)
# phy_tree <- read_tree(tree_filename)
# 
# # Import all as phyloseq objects
# OTU <- otu_table(otu_table_matrix, taxa_are_rows = TRUE)
# TAX <- tax_table(taxonomy_matrix)
# META <- sample_data(metadata)
# 
# taxa_names(OTU)
# taxa_names(TAX)
# taxa_names(phy_tree)
# 
# sample_names(OTU)
# sample_names(META)
# 
# ps <- phyloseq(OTU, TAX, META, phy_tree)
# 
# rarecurve(t(otu_table(ps)), step=50, cex=0.5)
# 
# ps_rarefied <- rarefy_even_depth(ps, rngseed=1, sample.size=0.9*min(sample_sums(ps)), replace=F)
# 
# rarecurve(t(otu_table(ps_rarefied)), step=50, cex=0.5)
# 
# theme_set(theme_bw())
# #, "Chao1", "Shannon", "Simpson"
# 

# ctd_metrics_plot <- plot_richness(ps_rarefied, x="day", color="depth", measures=c("Observed", "Chao1", "Simpson")) 
# ctd_metrics_plot$layers <- ctd_metrics_plot$layers[-1]
# 
#       
# ctd_metrics_melt <- ctd_metrics_plot$data
# 
# p1 <- ggplot(ctd_metrics_melt, aes(x = day, y = value, group = factor(depth))) 
# p1 <- p1 + 
#   geom_point(aes(colour=factor(depth)), size=4) +
#   geom_line(aes(linetype=factor(depth)), size= 0.5) +
#   theme_bw() +
#   theme(strip.text.x = element_text(size = 14, face = "bold"),
#       axis.title.x = element_text(size = 14, face = "bold"),
#       axis.title.y = element_text(size = 14, face = "bold"),
#       axis.text.x = element_text(size = 14, angle = 0),
#       axis.text.y = element_text(size = 14),
#       legend.text = element_text(size = 12),
#       legend.position = "top",
#       legend.title = element_text(size = 14, face = "bold"),
#       panel.grid = element_blank(),
#       panel.grid.major = element_line(size=0.1),
#       legend.box.background = element_rect(colour = "grey"))+ 
#         scale_linetype(label=NULL, breaks=NULL) +
#         scale_color_discrete(name="Depth (m)",labels=c("0", "14", "25"))+
#         ylab("Alpha divesity metric") +
#         xlab("Date (March 2018)")
#         
# p1 <- p1 + facet_wrap(~variable, scale="free_y")
# p1
# 
# ggsave("alpha_diversity.tiff",
#        width = 180,
#        heigh = 100,
#        units = "mm",
#        dpi = 1000,
#        compression = "lzw")
# 
# metrics_df <- data.frame(p1$data)
# 
# write.table(metrics_df, "alpha_diversity.tsv", row.names = FALSE, quote = FALSE, sep ="\t")
#         
# 
#   
# 
# 
#   
# 
#     
#     
#     
#   
#   ggsave("18S_alpha_div_simpson.pdf",
#            height = 90,
#            width=100,
#            units = "mm") 
#sample_frequency <- read.csv("~/Documents/DevOps/PR2/sample-frequency-detail.csv", header=FALSE)