# install.packages("remotes")
#remotes::install_github("MadsAlbertsen/ampvis2")
rm(list=ls())
library(dplyr)
library(ampvis2)
library(tidyverse)
library(ggpubr)
library(cowplot)
#Kingdom, Phylum, Class, Order, Family, Genus, Species


otu_table_filename = "/home/drewx/Documents/DevOps/16S/paribus.Out/phyloseq/SHB_16S_feature_table_headers.tsv"
metadata_filename = "/home/drewx/St.Helena.MetaT/Raw/16S-Data/16S_metadata_phyloseq.tsv"
setwd("/home/drewx/Dropbox/PhDX/Chapter4/Figures/16S/phyloseq")

myotutable <- read.csv(otu_table_filename,
                       header = TRUE,
                       
                       sep = "\t")


for (var in  c("Class","Order","Family","Genus","Species","Confidence")){
  myotutable[var] <- fct_explicit_na, na_level = "(Missing)")
  break
}


mymetadata <- read.delim(metadata_filename, sep="\t")
myotutable$A2511 <- 100 * (myotutable$A2511/sum(myotutable$A2511))
myotutable$J2515 <- 100 * (myotutable$J2515/sum(myotutable$J2515))

rownames(mymetadata) <- c("D1","D5")
#"Domain",  "Phylum",   "Class",  "Order",  "Fa   mily",   "Genus",  "Species"
  #D_0__      D_1__       D_2__     D_3__     D_4__       D_5__     D_6__ 

colnames(myotutable)[c(1,4)] <- c("OTU","Kingdom")
myotutable_trunx <-select(myotutable, -c("Confidence"))
mymetadata$date_fmt <- paste(mymetadata$year, mymetadata$month, mymetadata$day, sep = "-" )
mymetadata$date_fmt <- as.character(format(mymetadata$date_fmt, format = "%Y-%m-%d"))

SHB <- amp_load(otutable = myotutable_trunx,
            metadata = mymetadata)

###################################### 25m ###############################################
SHB_25m <- amp_subset_samples(SHB, depth %in% c(25))

colnames(SHB_25m$abund) <-  c("D1","D5")

#Kingdom ==> domain  
p25m_domain <- amp_heatmap(SHB_25m,
          tax_aggregate = "Kingdom",
          plot_values_size = 7,
          normalise = FALSE,
          rel_widths = c(0.4, 0.25),
          tax_show = 25) +
      theme(axis.text.x = element_text(angle = 0, face = "bold", size=16, vjust = 1),
         axis.text.y = element_text(size=16, face = "bold"))
p25m_domain

ggsave2("p25m_domain.pdf", width = 179, units = "mm")

dev.off()


p25m_class <- amp_heatmap(SHB_25m,
                           tax_aggregate = "Genus",
                           tax_add = "Kingdom",
                           plot_values_size = 7,
                           tax_empty = "remove",
                           rel_widths = c(0.3, 0.15),
                           normalise = FALSE,
                           tax_show = 20) +
  theme(axis.text.x = element_text(angle = 0, face = "bold", size=16, vjust = 1),
        axis.text.y = element_text(size=16, face = "bold"))
p25m_class
  
ggsave2("p25m_class.pdf", width = 179, units = "mm")

dev.off()

amp_core(SHB_25m, plotly = TRUE)


amp_timeseries(SHB_25m,
               tax_aggregate = "Kingdom",
               group_by = "SampleID",
               tax_empty = "remove",
               normalise = FALSE,
               time_variable = "date_fmt" )

#amp_venn(data,


data("AalborgWWTPs")

# Timeseries of the 5 most abundant OTUs based on the "Date" column

amp_venn(SHB_25m,
         group_by = "day",
         text_size = 5,
         cut_a = 0,
         cut_f = 0.1,
         normalise = FALSE, 
         detailed_output = TRUE)


