#!/bin/bash

source activate qiime2-2018.8

##importing data

# qiime tools import \
#       --type EMPSingleEndSequences \
#       --input-path emp-single-end-sequences \
#       --output-path emp-single-end-sequences.qza



##Demultiplexing sequences

# qiime demux emp-single \
#       --i-seqs emp-single-end-sequences.qza \
#       --m-barcodes-file sample-metadata.tsv \
#       --m-barcodes-column BarcodeSequence \
#       --o-per-sample-sequences demux.qza



##generate a summary of the demultiplexing results

# qiime demux summarize \
#       --i-data demux.qza \
#       --o-visualization demux.qzv

#qiime tools view demux.qzv



# qiime dada2 denoise-single \
#       --i-demultiplexed-seqs demux.qza \
#       --p-trim-left 0 \
#       --p-trunc-len 120 \
#       --o-representative-sequences rep-seqs-dada2.qza \
#       --o-table table-dada2.qza \
#       --o-denoising-stats stats-dada2.qza




qiime metadata tabulate \
      --m-input-file stats-dada2.qza \
      --o-visualization stats-dada2.qzv
