#!/usr/bin/env Rscript

library(vegan)
library(phyloseq)
library(ggplot2)
library(argparse)


setwd("/home/drewx/Documents/DevOps/16S")
pdf("rarecurve_16S_raw.pdf")
otu_table_filename = "/home/drewx/Documents/DevOps/16S/paribus.Out/phyloseq/SHB_16S_feature_table.tsv"
taxa_filename =  "/home/drewx/Documents/DevOps/16S/paribus.Out/phyloseq/taxonomy.tsv"
metadata_filename = "/home/drewx/St.Helena.MetaT/Raw/16S-Data/16S_metadata_phyloseq.tsv"
tree_filename = "/home/drewx/Documents/DevOps/16S/paribus.Out/phyloseq/tree.nwk"

otu_table_matrix <- as.matrix(read.table(otu_table_filename, sep = "\t",  header=TRUE, row.names = 1))
taxonomy_matrix  <- as.matrix(read.table(file = taxa_filename, sep = "\t", header = TRUE, row.names = 1))
metadata <- read.table(metadata_filename, header = TRUE, row.names = 1)
phy_tree <- read_tree(tree_filename)

# Import all as phyloseq objects
OTU <- otu_table(otu_table_matrix, taxa_are_rows = TRUE)
TAX <- tax_table(taxonomy_matrix)
META <- sample_data(metadata)

taxa_names(OTU)
taxa_names(TAX)
taxa_names(phy_tree)

sample_names(OTU)
sample_names(META)

ps <- phyloseq(OTU, TAX, META, phy_tree)

rarecurve(t(otu_table(ps)), step=50, cex=0.5)

print(ps)
dev.off()

pdf("rarecurve_16S_90_perc.pdf")

ps_rarefied <- rarefy_even_depth(ps, rngseed=1, sample.size=0.9*min(sample_sums(ps)), replace=F)

rarecurve(t(otu_table(ps_rarefied)), step=50, cex=0.5)

print(ps_rarefied)
dev.off()


theme_set(theme_bw())

p1 <- plot_richness(ps_rarefied, x="DaysSinceExperimentStart", measures = c("Observed", "Chao1", "Shannon", "Simpson" )) 
est_p1 <- estimate_richness(ps_rarefied, measures = c("Observed", "Chao1", "Shannon", "Simpson" ))
p1$layers <- p1$layers[-1]

p1 + geom_point(size=5) +
  theme(strip.text.x = element_text(size = 16, face = "bold"),
        axis.title.x = element_text(size = 16, face = "bold"),
        axis.text.x = element_text(size = 16, angle = 0),
        axis.text.y = element_text(size = 16),
        axis.title.y = element_text(size = 16, face = "bold"),
        legend.text = element_text(size = 16),
        legend.title = element_text(size = 16, face = "bold")) +
  xlab("Number of days since start") +
  scale_x_continuous(breaks = c(1,5))
  

ggsave("16S_alpha_diversity.pdf",
       height = 90,
       width=179,
       units = "mm") 
