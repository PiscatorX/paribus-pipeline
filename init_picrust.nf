params.rep_seqs =  "/home/andhlovu/MB-16SGG/SILVA/dada2/dada2_rep_seqs.qza"
params.table    =  "/home/andhlovu/MB-16SGG/SILVA/dada2/dada2_table.qza"
params.gg_otus	=  "${DB_REF}Greengenes/gg_13_5_otus/rep_set/99_otus.fasta"
output		=  "${PWD}"
gg_otus		=  Channel.fromPath(params.gg_otus)

dada2_rep_seqs  =  Channel.fromPath(params.rep_seqs)
rooted_tree     =  Channel.fromPath(params.rooted)
unrooted_tree   =  Channel.fromPath(params.unrooted)
sampling_depth  =  Channel.value(params.sampling_d)
sample_id       =  Channel.value(params.sample_id)
dada2_rep_seqs  = Channel.fromPath(params.rep_seqs)




process get_picrust{
    
    cpus params.htp_cores
    memory "${params.m_mem} GB"
    publishDir path: "$output/picrust", mode: 'move'


   input:
        file gg_otus
        file dada2_rep_seqs
	file dada2_table
   
   output:
       file("*")


"""

    qiime tools import \
      --input-path ${gg_otus} \
      --output-path gg_13_5_otu_99.qza \
      --type 'FeatureData[Sequence]'
    
    qiime vsearch cluster-features-closed-reference \
      --i-sequences ${dada2_rep_seqs} \
      --i-table ${dada2_table} \
      --i-reference-sequences gg_13_5_otu_99.qza \
      --p-perc-identity 1 \
      --p-threads 0 \
      --output-dir closedRef_forPICRUSt \

"""

}