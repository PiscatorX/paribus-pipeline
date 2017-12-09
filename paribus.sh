#! /bin/bash

export PATH=$PATH:/global/mb/amw/soft/fasta-splitter-0.2.4
export PATH=/global/mb/amw/soft/ImageMagick-7.0.5-3/install/bin:/opt/exp_soft/bioinf/uparse_helpers/:$PATH
export PATH=$PATH:/global/mb/amw/soft/amw-src
export PATH=$PATH:/global/mb/amw/soft/amw-src/fastqc_combine
export PATH=~/bin:$PATH

raw_reads_dir="$1"
process_dir="$2"

#raw_reads_dir=RawReadX 
#process_dir=Red_Tide

if [ -d "$raw_reads_dir" ]

then
    
    sid_fastq_pair_list=$raw_reads_dir/sid_fastq_pair.list
    uparse_dir=$process_dir/uparse
    taxonomy_dir=$process_dir/tax
    alignment_dir=$process_dir/align
    greengenes_db=/global/mb/amw/dbs/gg_13_8_otus
    gold_db=/global/mb/amw/dbs/gold.fa
    fastqc_dir=$process_dir/fastqc
else
    echo pass
    #exit 1

fi

mkdir  -p  "$process_dir"

# #this automaticaly creates the seqid pair file
seq2sid.py -d $raw_reads_dir  
mkdir -p $fastqc_dir

#fastqc --extract -f fastq -o $fastqc_dir -t 6 $raw_reads_dir/*

#fastqc_combine.pl -v --out $fastqc_dir --skip --files "$fastqc_dir/*_fastqc"

renamed_dir=$uparse_dir"/renamed"
mkdir -p $renamed_dir
while read sid_fastq_pair; 
do sid=`echo $sid_fastq_pair | awk -F ' ' '{print $1}'`; 
fastq_r1=`echo $sid_fastq_pair | awk -F ' ' '{print $2}'`;
fastq_r2=`echo $sid_fastq_pair | awk -F ' ' '{print $3}'`;
fastq_r1_renamed=$renamed_dir"/"$(basename $fastq_r1);
fastq_r2_renamed=$renamed_dir"/"$(basename $fastq_r2);
rename_fastq_headers.sh $sid $fastq_r1 $fastq_r2 $fastq_r1_renamed $fastq_r2_renamed;
done < $sid_fastq_pair_list

# fastq_maxdiffs=5
# merged_dir=$uparse_dir"/merged"
# mkdir -p $merged_dir

# while read sid_fastq_pair;
# do sid=`echo $sid_fastq_pair | awk -F ' ' '{print $1}'`;
# fastq_r1=`echo $sid_fastq_pair | awk -F ' ' '{print $2}'`;
# fastq_r2=`echo $sid_fastq_pair | awk -F ' ' '{print $3}'`;
#    fastq_r1_renamed=$renamed_dir"/"$(basename $fastq_r1);
# fastq_r2_renamed=$renamed_dir"/"$(basename $fastq_r2);
# usearch -fastq_mergepairs $fastq_r1_renamed -reverse $fastq_r2_renamed -fastq_maxdiffs $fastq_maxdiffs -fastqout $merged_dir"/"$sid".merged.fastq";
# done < $sid_fastq_pair_list


# fastq_maxee=0.05
# filtered_dir=$uparse_dir"/filtered"
# mkdir -p $filtered_dir

# while read sid_fastq_pair;
# do sid=`echo $sid_fastq_pair | awk -F ' ' '{print $1}'`;  
# usearch -fastq_filter $merged_dir"/"$sid".merged.fastq" -fastq_maxee $fastq_maxee -fastqout $filtered_dir"/"$sid".merged.filtered.fastq"  ;
# done < $sid_fastq_pair_list

# filtered_fastqc_dir=$uparse_dir"/filtered.fastqc"
# mkdir -p $filtered_fastqc_dir
# fastqc --extract -f fastq -o $uparse_dir"/filtered.fastqc" -t 6 $filtered_dir/*.fastq

# fastqc_combine.pl -v --out $filtered_fastqc_dir --skip --files "$filtered_fastqc_dir/*_fastqc"



# filtered_fasta_dir=$uparse_dir"/filtered.fasta"
# mkdir $filtered_fasta_dir
# for i in `ls -1 $filtered_dir/*.fastq`;
# do filename=$(basename "$i");
# base="${filename%.*}"; 
# seqtk seq -A $i > $filtered_fasta_dir/$base.fa;
# done

# cat $filtered_fasta_dir/*.fa > $uparse_dir/filtered_all.fa


# usearch -fastx_uniques $uparse_dir/filtered_all.fa -fastaout $uparse_dir/filtered_all.uniques.sorted.fa -sizeout -relabel Uniq


# usearch -cluster_otus $uparse_dir/filtered_all.uniques.sorted.fa -relabel OTU_ -otus  $uparse_dir/otus_raw.fa

# usearch -otutab $uparse_dir/filtered_all.fa -otus $uparse_dir/otus_raw.fa -otutabout $uparse_dir/otutab.txt -biomout $uparse_dir/otutab.json \
#         -mapout $uparse_dir/map.txt -notmatched $uparse_dir/unmapped.fa -dbmatched $uparse_dir/otus_with_sizes.fa -sizeout


# Create ZOTUs by denoising (error-correction)
# usearch -unoise3 $uparse_dir/filtered_all.uniques.sorted.fa -zotus $uparse_dir/zotus.fa

# Create OTU table for ZOTUs
# usearch -otutab $uparse_dir/filtered_all.fa -zotus $uparse_dir/zotus.fa  -strand plus -otutabout $uparse_dir/zotutab.txt

# Create OTU table for 97% OTUs

# mkdir $taxonomy_dir

# assign_taxonomy.py -i $uparse_dir/otus_repsetOUT.fa -o $taxonomy_dir -r $greengenes_db/rep_set/97_otus.fasta -t $greengenes_db/taxonomy/97_otu_taxonomy.txt -m uclust

# biom convert -i $uparse_dir/otus_table.tab.txt --table-type="OTU table" --to-json -o $process_dir/otus_table.biom

# biom add-metadata -i $process_dir/otus_table.biom -o $process_dir/otus_table.tax.biom --observation-metadata-fp $taxonomy_dir/otus_repsetOUT_tax_assignments.txt --observation-header OTUID,taxonomy,confidence --sc-separated taxonomy --float-fields confidence --output-as-json

# mkdir $alignment_dir
# align_seqs.py -m pynast -i $uparse_dir/otus_repsetOUT.fa -o $alignment_dir -t $greengenes_db/rep_set_aligned/97_otus.fasta


# filter_alignment.py -i $alignment_dir/otus_repsetOUT_aligned.fasta -o $alignment_dir/filtered
# make_phylogeny.py -i $alignment_dir/filtered/otus_repsetOUT_aligned_pfiltered.fasta -o $process_dir/otus_repsetOUT_aligned_pfiltered.tre

# biom summarize-table -i $process_dir/otus_table.tax.biom -o $process_dir/otus_table.tax.biom.summary.quantative

# biom summarize-table --qualitative -i $process_dir/otus_table.tax.biom -o $process_dir/otus_table.tax.biom.summary.qualitative

