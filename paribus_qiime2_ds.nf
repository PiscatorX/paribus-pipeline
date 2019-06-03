#!/usr/bin/env nextflow

// params.rep_seqs = "/home/drewx/St.Helena.MetaT/Results/18S/SILVA/paribus.Out/dada2/dada2_rep_seqs.qza"
// params.table	= "/home/drewx/St.Helena.MetaT/Results/18S/SILVA/paribus.Out/dada2/dada2_table.qza"
// params.taxonomy = "/home/drewx/St.Helena.MetaT/Results/18S/SILVA/paribus.Out/feature_classifier/taxonomy.qza"

params.rep_seqs = "/home/drewx/Documents/DevOps/18S_silva/dada2/dada2_rep_seqs.qza"
params.table    = "/home/drewx/Documents/DevOps/18S_silva/dada2/dada2_table.qza"
params.taxonomy = "/home/drewx/Documents/DevOps/18S_silva/feature_classifier/taxonomy.qza"
params.rooted   = "/home/drewx/Documents/DevOps/18S_silva/phylogeny/rooted_tree.qza"
params.unrooted   = "/home/drewx/Documents/DevOps/18S_silva/phylogeny/unrooted_tree.qza"
params.sampling_d = 26969
params.sample_id  = "SHB_18S_silva"


//params.metadata = "/home/drewx/Documents/sea-biome/metadata/16S_sample-metadata.tsv"
params.metadata = "/home/drewx/St.Helena.MetaT/Raw/18S-Data/18S_sample-metadata.tsv"

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
      --p-exclude Metazoa \
      --o-filtered-table dada2_table_filterd.qza

    qiime feature-table summarize \
        --i-table dada2_table_filterd.qza \
        --o-visualization dada2_table_filterd.qzv \
        --m-sample-metadata-file ${metadata}
	
"""

}







// process  filter_repseqs{

//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "$output/dada2", mode: 'copy'
//     input:
// 	 file dada2_rep_seqs
// 	 file taxonomy2 
// 	 val  metadata
	 

//     output:
//          file("dada2_rep_seqs_filtered.qza") into (rep_seqs_filtered1,rep_seqs_filtered2,rep_seqs_filtered3)
//          file("dada2_rep_seqs_filtered.qzv")
// 	 file("rep_seqs")

// """
    
//     qiime taxa filter-seqs \
//         --i-sequences ${dada2_rep_seqs} \
// 	--i-taxonomy ${taxonomy2} \
// 	--p-exclude Metazoa \
// 	--o-filtered-sequences dada2_rep_seqs_filtered.qza

//     qiime feature-table tabulate-seqs \
//        --i-data dada2_rep_seqs_filtered.qza \
//        --o-visualization dada2_rep_seqs_filtered.qzv


//    qiime tools export \
//     --input-path ${dada2_rep_seqs} \
//     --output-path rep_seqs
  
// """
// }




// process taxa_barplot{

//     cpus params.ltp_cores
//     memory "${params.l_mem} GB"
//     publishDir path: "$output/taxonomy", mode: 'copy'
    
//     input:
// 	file dada2_table_filtered1
//         file taxonomy3
//         val  metadata
    
//     output:
// 	file("taxa_bar_plots.qzv") into taxa_bar_plots
    
// """    

//     qiime taxa barplot \
//     --i-table ${dada2_table_filtered1} \
//     --i-taxonomy ${taxonomy3} \
//     --m-metadata-file ${metadata} \
//     --o-visualization taxa_bar_plots.qzv

// """
    
// }



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

"""

    
}






// params.data     = "/home/andhlovu/St_Helena_Bay/metadata/18S_manifest.csv"
// params.data 	= "/home/drewx/Documents/sea-biome/reads.gz"
// params.classifier="/opt/DB_REF/SILVA/silva-132-99-515-806-nb-classifier.qza"
// params.classifier="/projects/andhlovu/DB_REF/SILVA_132_QIIME_release/silva-132-99-515-806-nb-classifier.qza"
// params.type     =  "SampleData[PairedEndSequencesWithQuality]"
// params.dada2    = true
// params.deblur   = false
// params.viz_reqs  = false
// data            = Channel.value(params.data)
// classifier      = Channel.value(params.classifier)
// metadata_cols   = Channel.value(["Experiment"])
// process importing_data{
//     cpus params.ltp_cores
//     publishDir path: "$output/reads_data", mode: 'copy'
//     memory "${params.m_mem} GB"    
//     input:
//         val  data
//         val  metadata
	

//     output:
// 	file("reads_demux.qza")  into (demux_reads1, demux_reads2) 

    
// """

//      qiime tools import \
// 	 --type ${params.type} \
// 	 --input-path ${data} \
// 	 --output-path reads_demux.qza \
// 	 --input-format PairedEndFastqManifestPhred33


//     qiime demux summarize \
//          --i-data reads_demux.qza \
// 	 --o-visualization reads_demux.qzv


// """

// }



// process dada2{

//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "$output/dada2", mode: 'copy'
//     input:
// 	 file demux_reads1
//          val  metadata
	 
//     output:
// 	file("dada2_rep_seqs.qza") into dada2_rep_seqs
// 	file("dada2_rep_seqs.qzv") into dada2_rep_viz
//         file("dada2_table.qza") into dada2_table
//         file("dada2_stats.*") into dada2_stats
// 	file("dada2_table.*") into dada2_table_data
	
// """
 
//     qiime dada2 denoise-paired \
// 	  --i-demultiplexed-seqs ${demux_reads1} \
// 	  --p-n-threads ${params.htp_cores}\
// 	  --p-trim-left-r 0 \
//           --p-trunc-len-f 0 \
//           --p-trunc-len-r 0 \
//           --p-max-ee 2.5 \
// 	  --o-representative-sequences dada2_rep_seqs.qza \
// 	  --o-table dada2_table.qza \
// 	  --o-denoising-stats dada2_stats.qza \
// 	  --verbose

//     qiime metadata tabulate \
// 	--m-input-file dada2_stats.qza \
// 	--o-visualization dada2_stats.qzv

//     qiime feature-table summarize \
//         --i-table dada2_table.qza \
//         --o-visualization dada2_table.qzv \
//         --m-sample-metadata-file ${metadata}

   
//     qiime feature-table tabulate-seqs \
//        --i-data dada2_rep_seqs.qza \
//        --o-visualization dada2_rep_seqs.qzv


// """
    
// }



// process phylogeny{

//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "$output/phylogeny", mode: 'copy'
//     input:
//         file dada2_rep_seqs

//     output:
//         file("aligned_rep_seqs.qza") into aligned
// 	file("masked_aligned_rep_seqs.qza") into masked_aligned
// 	file("unrooted_tree.qza") into unrooted_tree 
// 	file("rooted_tree.qza") into rooted_tree
	 

// """
//     qiime phylogeny align-to-tree-mafft-fasttree \
// 	  --p-n-threads ${params.mtp_cores} \
// 	  --i-sequences ${dada2_rep_seqs}  \
// 	  --o-alignment aligned_rep_seqs.qza \
// 	  --o-masked-alignment masked_aligned_rep_seqs.qza \
// 	  --o-tree unrooted_tree.qza \
// 	  --o-rooted-tree rooted_tree.qza \
// 	  --verbose

// """


// }



// process  core_metrics_phylogenetic{

//     //echo true
//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "$output/", mode: 'copy'
//     input:
//         val  metadata 
//         file dada2_table
// 	file rooted_tree

//     output:
//         file("core_metrics") into (core_metrics1,  core_metrics2, core_metrics3)

    
// """

//     qiime diversity core-metrics-phylogenetic \
//     	  --i-phylogeny ${rooted_tree} \
//     	  --i-table ${dada2_table} \
//     	  --p-sampling-depth 500 \
//     	  --m-metadata-file ${metadata} \
//     	  --output-dir core_metrics \
//     	  --verbose

//     qiime metadata tabulate \
//     	 --m-input-file core_metrics/faith_pd_vector.qza \
//          --o-visualization core_metrics/faith_pd_vector.qzv

// """

// }




// process  feature_classifier{
	 
//      // errorStrategy 'ignore'
//     cpus params.htp_cores
//     memory "${params.h_mem} GB"
//     publishDir path: "$output/feature_classifier", mode: 'copy'
//     input:
//          val classifier
// 	 file dada2_rep_seqs
 	 
//     output:
//         file("taxonomy.qza") into taxonomy
//         file("taxonomy.qzv") into taxonomy_viz
    
// """
    
//    qiime feature-classifier classify-sklearn \
//    	 --i-classifier ${classifier} \
//    	 --i-reads ${dada2_rep_seqs} \
//          --p-n-jobs ${params.mtp_cores}  \
//    	 --o-classification taxonomy.qza

//    qiime metadata tabulate \
//       --m-input-file taxonomy.qza \
//       --o-visualization taxonomy.qzv

// """

// }
















































    
// process alpha_div_sig_pd{

//     errorStrategy 'ignore'
//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "$output/phylogeny", mode: 'copy'
//     input:
//         file core_metrics1
// 	val  metadata

//     when:
//         params.viz_reqs == true

// """
	
//    qiime diversity alpha-group-significance \
// 	 --i-alpha-diversity ${core_metrics1}/faith_pd_vector.qza \
// 	 --m-metadata-file ${metadata} \
// 	 --o-visualization ${core_metrics1}/faith-pd-group-significance.qzv\
// 	 --verbose


// """

// }



// process alpha_div_sig_even{

//     //errorStrategy 'ignore'
//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "$output/phylogeny", mode: 'copy'
//     input:
//         file core_metrics2
// 	val  metadata

//     output:
// 	file("${core_metrics}/evenness-group-significance.qzv") into even_sig
	
//     when:
//        params.viz_reqs == true

// """
	
//     qiime diversity alpha-group-significance \
// 	  --i-alpha-diversity ${core_metrics2}/evenness_vector.qza \
// 	  --m-metadata-file ${metadata} \
// 	  --o-visualization ${core_metrics2}/evenness-group-significance.qzv

// """

// }





// process beta_div_sig{

//     echo true
//     //  errorStrategy 'ignore'
//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "${output}/phylogeny", mode: 'copy'
//     input:
//         val metadata
//         file core_metrics3
// 	each col from metadata_cols

//     output:
// 	file("${core_metrics3}/unweighted_unifrac_${col}.qzv") into unifrac_group_sig

//     when:
//        params.viz_reqs == true


// """

//     qiime diversity beta-group-significance \
// 	      --i-distance-matrix ${core_metrics3}/unweighted_unifrac_distance_matrix.qza \
// 	      --m-metadata-file ${metadata} \
// 	      --m-metadata-column ${col} \
// 	      --o-visualization ${core_metrics3}/unweighted_unifrac_${col}.qzv \
// 	      --p-pairwise
       
// """

// }


// process alpha_rarefaction{

//     echo true
//    // errorStrategy 'ignore'
//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "$output/alpha_rarefaction", mode: 'copy'
//     input:
//         val feature_table
// 	val  metadata
//         file rooted_tree 
        

//    output:
//        file("alpha_rarefaction.qzv") into alpha_rarefaction

// """

   
//   qiime diversity alpha-rarefaction \
// 	  --i-table ${feature_table} \
// 	  --i-phylogeny ${rooted_tree} \
// 	  --p-max-depth 500 \
// 	  --m-metadata-file ${metadata} \
// 	  --o-visualization alpha_rarefaction.qzv

    
// """

// }




// process  feature_classifier{
	 
//      // errorStrategy 'ignore'
//     cpus params.htp_cores
//     memory "${params.h_mem} GB"
//     publishDir path: "$output/feature_classifier", mode: 'copy'
//     input:
//          val classifier
// 	 val repseqs
 	 
//     output:
//         file("taxonomy.qza") into taxonomy
//         file("taxonomy.qzv") into taxonomy_viz
    
// """
    
//    qiime feature-classifier classify-sklearn \
//    	 --i-classifier ${classifier} \
//    	 --i-reads ${repseqs} \
//          --p-n-jobs ${params.mtp_cores}  \
//    	 --o-classification taxonomy.qza

//    qiime metadata tabulate \
//       --m-input-file taxonomy.qza \
//       --o-visualization taxonomy.qzv


// """

// }

// qiime taxa collapse \
//    --i-table gut-table.qza \
//    --i-taxonomy taxonomy.qza \
//    --p-level 6 \
//    --o-collapsed-table gut-table-l6.qza




// qiime feature-table filter-samples \
//       --i-table table.qza \
//       --m-metadata-file sample-metadata.tsv \
//       --p-where "BodySite='gut'" \
//       --o-filtered-table gut-table.qza




// qiime composition add-pseudocount \
//       --i-table gut-table.qza \
//       --o-composition-table comp-gut-table.qza




// qiime composition ancom \
//       --i-table comp-gut-table.qza \
//       --m-metadata-file sample-metadata.tsv \
//       --m-metadata-column Subject \
//       --o-visualization ancom-Subject.qzv








// qiime composition add-pseudocount \
//       --i-table gut-table-l6.qza \
//       --o-composition-table comp-gut-table-l6.qza




// qiime composition ancom \
//       --i-table comp-gut-table-l6.qza \
//       --m-metadata-file sample-metadata.tsv \
//       --m-metadata-column Subject \
//       --o-visualization l6-ancom-Subject.qzv


// qiime emperor plot \
//       --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
//       --m-metadata-file sample-metadata.tsv \
//       --p-custom-axes DaysSinceExperimentStart \
//       --o-visualization core-metrics-results/unweighted-unifrac-emperor-DaysSinceExperimentStart.qzv




// qiime emperor plot \
//       --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
//       --m-metadata-file sample-metadata.tsv \
//       --p-custom-axes DaysSinceExperimentStart \
//       --o-visualization core-metrics-results/bray-curtis-emperor-DaysSinceExperimentStart.qzv
