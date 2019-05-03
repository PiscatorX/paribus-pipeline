#!/usr/bin/env nextflow

params.data    = "/home/drewx/Documents/sea-biome/metadata/manifest.csv"
//params.data 	= "/home/drewx/Documents/sea-biome/reads.gz"
params.metadata = "/home/drewx/Documents/sea-biome/metadata/16S_sample-metadata.tsv"
params.classifier="/opt/DB_REF/SILVA/silva-132-99-515-806-nb-classifier.qza"
params.type     =  "SampleData[PairedEndSequencesWithQuality]"
params.dada2    = true
params.deblur   = false
params.viz_reqs  = false
data            = Channel.value(params.data)
metadata        = Channel.value(params.metadata)
output		= "${PWD}/paribus.Out"
classifier      = Channel.value(params.classifier)
metadata_cols   = Channel.value(["Experiment"])



// if (params.dada2 == params.deblur){

// error "params.dada2=${params.dada2} and params.deblur=${params.deblur} chose one option to set to `true`"
   
// }


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





repseqs = Channel.value("/home/drewx/St.Helena.MetaT/dada2/dada2_rep_seqs.qza")
feature_table   = Channel.value("/home/drewx/St.Helena.MetaT/dada2/dada2_table.qza")



// process phylogeny{

//     cpus params.mtp_cores
//     memory "${params.m_mem} GB"
//     publishDir path: "$output/phylogeny", mode: 'copy'
//     input:
//         val repseqs

//     output:
//         file("aligned_rep_seqs.qza") into aligned
// 	file("masked_aligned_rep_seqs.qza") into masked_aligned
// 	file("unrooted_tree.qza") into unrooted_tree 
// 	file("rooted_tree.qza") into rooted_tree
	 

// """
//     qiime phylogeny align-to-tree-mafft-fasttree \
// 	  --p-n-threads ${params.mtp_cores} \
// 	  --i-sequences ${repseqs}  \
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
//         val feature_table
//         val  metadata 
// 	file rooted_tree

//     output:
//         file("core_metrics") into (core_metrics1,  core_metrics2, core_metrics3)

    
// """

//     qiime diversity core-metrics-phylogenetic \
//     	  --i-phylogeny ${rooted_tree} \
//     	  --i-table ${feature_table} \
//     	  --p-sampling-depth 500 \
//     	  --m-metadata-file ${metadata} \
//     	  --output-dir core_metrics \
//     	  --verbose

//     qiime metadata tabulate \
//     	 --m-input-file core_metrics/faith_pd_vector.qza \
//          --o-visualization core_metrics/faith_pd_vector.qzv

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



process  feature_classifier{
	 
     // errorStrategy 'ignore'
    cpus params.mtp_cores
    memory "${params.m_mem} GB"
    publishDir path: "$output/feature_classifier", mode: 'copy'
    input:
         val classifier
	 val repseqs
 	 
    output:
        // file("taxonomy.qza") into taxonomy
        // file("taxonomy.qzv") into taxonomy_viz
    
"""
    
   /usr/bin/time -o classfier.time qiime feature-classifier classify-sklearn \
   	 --i-classifier ${classifier} \
   	 --i-reads ${repseqs} \
         --p-n-jobs ${params.mtp_cores}  \
   	 --o-classification taxonomy.qza

   qiime metadata tabulate \
      --m-input-file taxonomy.qza \
      --o-visualization taxonomy.qzv

"""

}





// qiime taxa barplot \
//       --i-table table.qza \
//       --i-taxonomy taxonomy.qza \
//       --m-metadata-file sample-metadata.tsv \
//       --o-visualization taxa-bar-plots.qzv




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




// qiime taxa collapse \
//       --i-table gut-table.qza \
//       --i-taxonomy taxonomy.qza \
//       --p-level 6 \
//       --o-collapsed-table gut-table-l6.qza




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

