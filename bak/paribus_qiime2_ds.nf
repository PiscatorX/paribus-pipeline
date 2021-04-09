#!/usr/bin/env nextflow
//home/drewx/Documents/DevOps/16S/paribus.Out
params.rep_seqs = "/home/drewx/Documents/DevOps/16S/paribus.Out/dada2/dada2_rep_seqs.qza"
params.table    = "/home/drewx/Documents/DevOps/16S/paribus.Out/dada2/dada2_table.qza"
params.taxonomy = "/home/drewx/Documents/DevOps/16S/paribus.Out/feature_classifier/taxonomy.qza"
params.rooted   = "/home/drewx/Documents/DevOps/16S/paribus.Out/phylogeny/rooted_tree.qza"
params.unrooted   = "/home/drewx/Documents/DevOps/16S/paribus.Out/phylogeny/unrooted_tree.qza"
//params.sampling_d = 174544
params.sampling_d = 80730
params.sample_id  = "SHB_16S"


// params.rep_seqs = "/home/drewx/Documents/DevOps/PR2/dada2/dada2_rep_seqs.qza"
// params.table    = "/home/drewx/Documents/DevOps/PR2/dada2/dada2_table.qza"
// params.taxonomy = "/home/drewx/Documents/DevOps/PR2/feature_classifier/taxonomy.qza"
// params.rooted   = "/home/drewx/Documents/DevOps/PR2/phylogeny/rooted_tree.qza"
// params.unrooted   = "/home/drewx/Documents/DevOps/PR2/phylogeny/unrooted_tree.qza"
// params.sampling_d = 26969
// params.sample_id  = "SHB_18S"




params.metadata = "/home/drewx/Documents/sea-biome/metadata/16S_sample-metadata.tsv"
//params.metadata = "/home/drewx/St.Helena.MetaT/Raw/18S-Data/18S_sample-metadata.tsv"

metadata        = Channel.value(params.metadata)
output		= "${PWD}"
dada2_rep_seqs  = Channel.fromPath(params.rep_seqs)
rooted_tree     = Channel.fromPath(params.rooted)
unrooted_tree     = Channel.fromPath(params.unrooted)
sampling_depth  = Channel.value(params.sampling_d)
sample_id       = Channel.value(params.sample_id)


Channel.fromPath(params.taxonomy).into{taxonomy1; taxonomy2; taxonomy3; taxonomy4}
Channel.fromPath(params.table)into{dada2_table1; dada2_table2}



log.info"""
table		=  ${params.table}
taxonomy 	=  ${params.taxonomy}	
"""


process filter_taxa{

    cpus params.ltp_cores
    memory "${params.l_mem} GB"
    publishDir path: "$output/dada2", mode: 'copy'

    input:
        file dada2_table1
        file taxonomy1
	val metadata
	val sample_id

    output:
	file("dada2_table_filterd.qza") into (dada2_table_filtered1, dada2_table_filtered2, dada2_table_filtered3)  
        file("dada2_table_filterd.qzv")

"""

   qiime taxa filter-table \
      --i-table ${dada2_table1} \
      --i-taxonomy ${taxonomy1} \
      --p-exclude mitochondria,chloroplast \
      --o-filtered-table dada2_table_filterd.qza

    qiime feature-table summarize \
        --i-table dada2_table_filterd.qza \
        --o-visualization dada2_table_filterd.qzv \
        --m-sample-metadata-file ${metadata}
	
"""
//--p-exclude Metazoa \
}




process taxa_barplot{

    cpus params.ltp_cores
    memory "${params.l_mem} GB"
    publishDir path: "$output/taxonomy", mode: 'copy'
    
    input:
	file dada2_table_filtered1
        file taxonomy3
        val  metadata
    
    output:
	file("taxa_bar_plots.qzv") into taxa_bar_plots
    
"""    

    qiime taxa barplot \
    --i-table ${dada2_table_filtered1} \
    --i-taxonomy ${taxonomy3} \
    --m-metadata-file ${metadata} \
    --o-visualization taxa_bar_plots.qzv

"""
    
}




process alpha_rarefaction{

   //echo true
   // errorStrategy 'ignore'
    cpus params.mtp_cores
    memory "${params.m_mem} GB"
    publishDir path: "$output/alpha_rarefaction", mode: 'copy'
    input:
        file dada2_table_filtered2
	val metadata
	val sampling_depth
        file rooted_tree 
        

   output:
       file("alpha_rarefaction.qzv") into alpha_rarefaction

"""

   
  qiime diversity alpha-rarefaction \
	  --i-table ${dada2_table_filtered2} \
	  --i-phylogeny ${rooted_tree} \
	  --p-max-depth ${sampling_depth} \
	  --m-metadata-file ${metadata} \
	  --o-visualization alpha_rarefaction.qzv
    
"""

}



// qiime feature-table filter-samples \
//   --i-table table.qza \
//   --m-metadata-file sample-metadata.tsv \
//   --p-where "Subject='subject-1'" \
//   --o-filtered-table subject-1-filtered-table.qza




process phyloseq_data{

    cpus params.ltp_cores
    memory "${params.l_mem} GB"
    publishDir path: output, mode: 'copy'
    
    input:
        file dada2_table_filtered3
        file taxonomy4
	file unrooted_tree
        val  sample_id
    
    output:
	file("phyloseq")
    

    
"""

    qiime tools export \
         --input-path ${dada2_table_filtered3} \
         --output-path phyloseq

    qiime tools export \
         --input-path ${taxonomy4} \
       	 --output-path phyloseq

    sed -i -e 's/Feature ID/#OTUID/' phyloseq/taxonomy.tsv

    biom add-metadata \
          -i phyloseq/feature-table.biom \
          --observation-metadata-fp phyloseq/taxonomy.tsv \
          --sc-separated Taxon \
          -o phyloseq/${sample_id}.biom

    sed -i -e 's/#OTUID/OTUID/' phyloseq/taxonomy.tsv

    biom convert \
         --to-tsv \
         --table-type="OTU table" \
         -i phyloseq/${sample_id}.biom \
         -o phyloseq/${sample_id}_feature_table.tsv 

    sed -i -e 's/#OTU ID/OTUID/' phyloseq/${sample_id}_feature_table.tsv 
   
    biom convert \
        --to-tsv \
        --header-key Taxon \
        --table-type="OTU table" \
        -i phyloseq/${sample_id}.biom \
        -o phyloseq/${sample_id}_otutable.tsv 

    qiime tools export \
         --input-path ${unrooted_tree} \
       	 --output-path phyloseq

    tax_headers.py  \
        phyloseq/taxonomy.tsv \
        phyloseq/${sample_id}_feature_table.tsv \
        -t phyloseq/taxonomy_headers.tsv \
        -o phyloseq/${sample_id}_feature_table_headers.tsv    

"""

    
}
