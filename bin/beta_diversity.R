# if (!requireNamespace("BiocManager", quietly = TRUE))
#   install.packages("BiocManager")
# BiocManager::install("biomformat")
library(biomformat)
library(vegan)

otu_table_filename = "/home/drewx/Documents/DevOps/18S_silva/phyloseq/SHB_18S_silva_feature_table.tsv"
taxa_filename =  "/home/drewx/Documents/DevOps/18S_silva/phyloseq/taxonomy.tsv"
metadata_filename = "/home/drewx/St.Helena.MetaT/Raw/18S-Data/18S_metadata_phyloseq.tsv"
tree_filename = "/home/drewx/Documents/DevOps/18S_silva/phyloseq/tree.nwk"
outdir = "/home/drewx/Documents/DevOps/CTD"

setwd(outdir)
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


rownames(META) 

otu_metadata <- META

get_dist <- function(otus, otu_metadata){

common_ids <- intersect(rownames(otus),rownames(otu_metadata))
print(common_ids)
otus = otus[common_ids,]
otu_metadata = otu_metadata[common_ids,]
euc_dist <- dist(otus)
bray_curtis_dist <- vegdist(otus)
cca_data <- cca(otus)
chisq_dist <- as.matrix(dist(cca_data$CA$u[,c(1:2)]))

pcoa_plots <- list()

pcoa_plots$pcoa_euc_dist <- cmdscale(euc_dist, k=2)
pcoa_plots$pcoa_bray <- cmdscale(bray_curtis_dist, k=2)
pcoa_plots$pcoa_chisq <- cca_data$CA$u[,c(1:2)]
my_colors <- colorRampPalette(c("red","blue"))(max(otu_metadata$DaysSinceExperimentStart))

for (i in 1:length(pcoa_plots)){
  pcoa <-  data.frame(pcoa_plots[i])
  name <- names(pcoa_plots)[i]
  print(name)
  (pcoa[,1],pcoa[,2], col=my_colors[otu_metadata$DaysSinceExperimentStart], cex=3,  pch=16 )
  Sys.sleep(5)
}




