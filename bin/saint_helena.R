#!/usr/bin/env Rscript
rm(list=ls())
cat("\f")

library(vegan)
library(phyloseq)
library(ggplot2)
library(argparse)
library(dplyr)
library(GGally)
library(ggExtra)
library(reshape2)
library(ggpubr)
library(cowplot)

StHelena_Bay_CTD <- read.csv("~/St.Helena.MetaT/Raw/StHelena_Bay_CTD.csv")
setwd("/home/drewx/Documents/DevOps/CTD")

days <- unlist(levels(factor(StHelena_Bay_CTD$day)))

sampling_data <- list()

for (i in seq(1:length(days))){
  
  data <- StHelena_Bay_CTD[StHelena_Bay_CTD$day == days[i],]
  ordered <- data[order(data$Depth, decreasing=FALSE),]
  row_df <- data.frame(ordered[ordered$Depth > 0.5,][1,])
  if( i == 1){
    ctd_df <- row_df
  }
  else{
    ctd_df <-rbind(ctd_df, row_df)
  }
}

seasurface <- ctd_df[c("day","Temperature","Chl.a","Oxygen","OxygenSAT")]
seasurface$sampling_day <- paste0("D",0:4)

seasurface_melt <- melt(seasurface[,-c(1)])
p <- ggline(seasurface_melt, x= "sampling_day", y = "value", group = "variable" ) + geom_line()
p <- p + facet_wrap(~variable, scales = "free") +
  theme(axis.text=element_text(size=16),
        axis.title=element_text(size=18, face = "bold"),
        strip.text.x = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(size = 14))
p
ggsave2("ctd_data.pdf")
dev.off()


for (i in seq(1:length(days))){
  
  data <- StHelena_Bay_CTD[StHelena_Bay_CTD$day == days[i],]
  ordered <- data[order(data$Depth, decreasing=FALSE),]
  row_df <- data.frame(ordered[ordered$Depth > 25,][1,])
  if( i == 1){
    ctd_df25 <- row_df
  }
  else{
    ctd_df25 <-rbind(ctd_df25, row_df)
  }
}

deep25 <- ctd_df25[c("Temperature","Chl.a","Oxygen","OxygenSAT")]
deep25$sampling_day <- paste0("D",0:4)

deep25_melt <- melt(deep25)
p2 <- ggline(deep25_melt, x= "sampling_day", y = "value", group = "variable" ) + geom_line()
p2 <- p2 + facet_wrap(~variable, scales = "free") +
  theme(axis.text=element_text(size=16),
        axis.title=element_text(size=18, face = "bold"),
        strip.text.x = element_text(size = 14, face = "bold"),
          axis.text.x = element_text(size = 14))
p2
ggsave2("ctd_data25m.pdf")
dev.off()

ctd_df$Depth <- 0
ctd_df$sampling_day <- paste0("D",0:4)
ctd_df25$Depth <- 25
ctd_df25$sampling_day <- paste0("D",0:4)
ctd_table <- rbind(ctd_df, ctd_df25)
ctd_table_melt <- melt(ctd_table)

ctd_table$Depth <- factor(ctd_table$Depth)
temp <- ggline(ctd_table, y="Temperature", x = "sampling_day", group = "Depth", color = "Depth", size = 2, show_guide  = F) +
  theme(axis.text=element_text(size=16),
        axis.title=element_text(size=18, face = "bold"),
        strip.text.x = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(size = 14)) +
       scale_color_manual(values = c("green", "blue"))

chlo <- ggline(ctd_table, y="Chl.a", x = "sampling_day", group = "Depth", color = "Depth", size = 2) +
  theme(axis.text=element_text(size=16),
        axis.title=element_text(size=18, face = "bold"),
        strip.text.x = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(size = 14)) +
  scale_color_manual(values = c("green", "blue"))

oxy <- ggline(ctd_table, y="Oxygen", x = "sampling_day", group = "Depth", color = "Depth", size = 2) +
  theme(axis.text=element_text(size=16),
        axis.title=element_text(size=18, face = "bold"),
        strip.text.x = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(size = 14)) +
  scale_color_manual(values = c("green", "blue"))

oxySAT <- ggline(ctd_table, y="OxygenSAT", x = "sampling_day", group = "Depth", color = "Depth", size = 2) +
  theme(axis.text=element_text(size=16),
        axis.title=element_text(size=18, face = "bold"),
        strip.text.x = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(size = 14)) +
  scale_color_manual(values = c("green", "blue"))

ggarrange(temp, chlo, oxy, oxySAT, 
          labels = c("A", "B", "C", "D"),
          ncol = 2, nrow = 2)

ggsave2("ctd_data25mv0m.pdf")
dev.off()

ctd_chlmax_0m <- subsuface_chl(StHelena_Bay_CTD, 0, chl_max = TRUE)[c("day","Temperature","Chl.a","Oxygen","OxygenSAT")]
ctd_chlmax_0m$Sampling_day <- paste0("D",0:4)


temp1 <-  ggplot(ctd_chlmax_0m) +
          geom_point(aes(x = day, y= Temperature, shape = 20, colour = "orange"), size = 2) +
          geom_line(aes(x = day, y = Temperature,  colour = "orange"), size = 1) +
          scale_shape_identity() +
          theme(axis.line = element_line(colour = "black"),
            panel.grid.minor = element_blank(),
            panel.background = element_blank(),
            axis.text=element_text(size=16),
            axis.title=element_text(size=18, face = "bold"),
            axis.text.x = element_text(size = 16))

ggsave2("Temp.pdf")
dev.off()


chloma1 <-  ggplot(ctd_chlmax_0m) +
                  geom_point(aes(x = day, y= Chl.a, shape = 20, color = "green"), size = 2) +
                  geom_line(aes(x = day, y = Chl.a,  color = "green"), size = 1) +
                  scale_shape_identity() +
                  ylab("Subsurface Chl a  maxima ") +
                  xlab("Days since sampling start")+
                  theme(axis.line = element_line(colour = "black"),
                        panel.grid.minor = element_blank(),
                        panel.background = element_blank(),
                        axis.text=element_text(size=16),
                        axis.title=element_text(size=18, face = "bold"),
                        axis.text.x = element_text(size = 16))
chloma1

ggsave2("sub_chlo_max.pdf")
dev.off()

       

lm_temp_chla <- lm(Chl.a ~ Temperature, data = ctd_chlmax_0m)
lm_temp_chla
#y = intercept + (Beta * Chl.a)
summary(lm_temp_chla)







# 
# for (i in seq(1:length(seasurface))){
#   for (j in seq(1:length(seasurface))){
#     if (i ==j ){next}
#   print(cor(seasurface[i], seasurface[j]))
#   cat("\n")
#   }
# }
# 
# ggcorr(seasurface, palette = "RdBu", label = TRUE)
# ggpairs(seasurface[-c(1,6)])
# 
# 
# ggcorr(deep25, palette = "RdBu", label = TRUE)
# ggpairs(deep25[-c(5)])
# 
# 
# p <- ggscatter(seasurface, x = "Temperature", y = "Chl.a",
#           add = "reg.line",                                 # Add regression line
#           conf.int = TRUE,                                  # Add confidence interval
#           add.params = list(color = "blue",
#                             fill = "lightgray")
# )+
#   stat_cor(method = "pearson") + border()  # Add correlation coefficient
# 
# p <- p + rremove("legend")
# 
# xplot <- ggdensity(seasurface, "Chl.a", fill="green")
# yplot <- ggdensity(seasurface, "Temperature", fill="orange") + rotate()
# yplot <- yplot + clean_theme() + rremove("legend")
# xplot <- xplot + clean_theme() + rremove("legend")
# library(cowplot)
# plot_grid(xplot, NULL, p, yplot, ncol = 2, align = "hv", 
#           rel_widths = c(2, 1), rel_heights = c(1, 2))
# 
# 
# 
# xplot <- ggdensity(deep25, "Chl.a", fill="green")
# yplot <- ggdensity(deep25, "Temperature", fill="orange") + rotate()
# yplot <- yplot + clean_theme() + rremove("legend")
# xplot <- xplot + clean_theme() + rremove("legend")
# library(cowplot)
# plot_grid(xplot, NULL, p, yplot, ncol = 2, align = "hv", 
#           rel_widths = c(2, 1), rel_heights = c(1, 2))
# 
# 
# 
# 
# ggMarginal(p, type = "density")
# 
# ggscatter(seasurface, x = "OxygenSAT", y = "Temperature",
#           add = "reg.line",                                 # Add regression line
#           conf.int = TRUE,                                  # Add confidence interval
#           add.params = list(color = "blue",
#                             fill = "lightgray")
# )+
#   stat_cor(method = "pearson")  # Add correlation coefficient
# 
# 
# 
#   
# otu_table_filename = "/home/drewx/Documents/DevOps/18S_silva/phyloseq/SHB_18S_silva_feature_table.tsv"
# taxa_filename =  "/home/drewx/Documents/DevOps/18S_silva/phyloseq/taxonomy.tsv"
# metadata_filename = "/home/drewx/St.Helena.MetaT/Raw/18S-Data/18S_metadata_phyloseq.tsv"
# tree_filename = "/home/drewx/Documents/DevOps/18S_silva/phyloseq/tree.nwk"
# outdir = "/home/drewx/Documents/DevOps/CTD"
# 
# setwd(outdir)
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
