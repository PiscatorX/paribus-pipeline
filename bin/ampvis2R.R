# install.packages("remotes")
#remotes::install_github("MadsAlbertsen/ampvis2")
rm(list=ls())
library(ampvis2)
library(tidyverse)
library(ggpubr)
library(cowplot)

otu_table_filename = "~/Documents/DevOps/PR2/phyloseq/SHB_18S_feature_table_headers.tsv"
metadata_filename = "/home/drewx/St.Helena.MetaT/Raw/18S-Data/18S_metadata_phyloseq.tsv"
outdir = "/home/drewx/Documents/DevOps/PR2_CTD"

myotutable <- read.delim(otu_table_filename)
mymetadata <- read.delim(metadata_filename, sep="\t")
colnames(myotutable)[c(1,14)] <- c("OTU","Phylum")
myotutable_trunx <-select(myotutable, -c("Supergroup","Confidence"))
#Kingdom, Phylum, Class, Order, Family, Genus, Species
#"Kingdom"    "Supergroup"    "Class"      "Order"      "Family"     "Genus"      "Species"    
SHB <- amp_load(otutable = myotutable_trunx,
              metadata = mymetadata)

######################################## 0m ###############################################

SHB_0m <- amp_subset_samples(SHB, depth %in% c(0))

colnames(SHB_0m$abund) <- SHB_0m$metadata$DaysSinceSamplingStart

p0m <- amp_heatmap(SHB_0m,
                 tax_aggregate = "Genus",
                 plot_values_size = 5,
                 tax_empty = "remove",
                 rel_widths = c(0.4, 0.25),
                 tax_show = 25) +
  theme(axis.text.x = element_text(angle = 0,face = "bold", size=16, vjust = 1),
        axis.text.y = element_text(size=16, face = "bold"))
p0m 

ggsave2("p0m.pdf", width = 179, units = "mm")

###################################### 14m ###############################################

SHB_14m <- amp_subset_samples(SHB, depth %in% c(14))

colnames(SHB_14m$abund) <- SHB_14m$metadata$DaysSinceSamplingStart

p14m <- amp_heatmap(SHB_14m,
                  tax_aggregate = "Genus",
                  plot_values_size = 5,
                  tax_empty = "remove",
                  rel_widths = c(0.4, 0.25),
                  tax_show = 25) +
  theme(axis.text.x = element_text(angle = 0, face = "bold", size=16, vjust = 1),
        axis.text.y = element_text(size=16,	face = "bold"))

p14m

ggsave2("p14m.pdf", width = 179, units = "mm")

###################################### 25m ###############################################
SHB_25m <- amp_subset_samples(SHB, depth %in% c(25))

colnames(SHB_25m$abund) <- SHB_25m$metadata$DaysSinceSamplingStart

p25m <- amp_heatmap(SHB_25m,
          tax_aggregate = "Genus",
          plot_values_size = 5,
          tax_empty = "remove",
          rel_widths = c(0.4, 0.25),
          tax_show = 25) +
      theme(axis.text.x = element_text(angle = 0, face = "bold", size=16, vjust = 1),
         axis.text.y = element_text(size=16, face = "bold"))
p25m 

ggsave2("p25m.pdf", width = 179, units = "mm")
