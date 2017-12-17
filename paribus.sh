#! /bin/bash

color=34
while getopts ":r:p:h" opt;
do
    case ${opt} in	
      h) echo "Paribus is pipeline for analysis paired-end reads generated by Illumina Miseq"
	 echo "Usage:"
	 echo "    paribus.sh -h               Display this help message."
	 echo "    paribus.sh -r  <fastq reads directory> -p   <processing directory (default:paribus.o)>"  
	 exit 0
      ;;
      :) "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
      r) raw_reads_dir=${OPTARG%/}
	 
	 if [ ! -d $raw_reads_dir ]
	 then
	     echo "Failed to locate the reads directory: $raw_reads_dir "
	 fi
      ;;
      p) process_dir=${OPTARG%/}
      ;;
      d) ref_db=$OPTARG
      ;;
      t) ref_tax=$OPTARG
      ;;
      c)
	  ref_tax=/home/andhlovu/SILVA_128_QIIME_release/taxonomy/18S_only/97/consensus_taxonomy_7_levels.txt
	  ref_db=/home/andhlovu/SILVA_128_QIIME_release/rep_set/rep_set_18S_only/97/97_otus_18S.fasta
      ;;
      \?) echo "Usage: cmd [-h] [-r] [-p]"
      ;;
   esac
done
shift $((OPTIND -1))




if [ -z $raw_reads_dir ]
   
then
    echo "Invalid option: fastq reads directory [-r] is required" 1>&2
    echo "Usage:"
    echo "    paribus.sh -h               Display this help message."
    echo "    paribus.sh -r  <fastq reads directory> -p   <processing directory (default:paribus.o)>"
    echo "    -t    taxon assignment reference fasta file database (default: 97_otu.fasta )"
    exit 1
fi




if [ -z $process_dir ]   
then
    process_dir=paribus.o
fi


if [ -z $ref_db ]   
then
    ref_db=ref_db.fasta
fi




if [ -z $ref_tax ]   
then
    ref_tax=db_taxonomy.txt
fi


echo -e "\n\e[0;"$color"m Initialising directories\033[0m\n"
#Init directories
mkdir -p $process_dir
usearch_dir=$process_dir/usearch
mkdir -p $usearch_dir




# fastqc_dir=$process_dir/fastqc
# mkdir -p $fastqc_dir/raw_reads
# fastqc --extract -f fastq -o $fastqc_dir/raw_reads  $raw_reads_dir/*.fastq




seq2sid.py -r $raw_reads_dir -o $process_dir
sid_fastq_pair_list=$process_dir/sid_fastq_pair.list
if [ ! -e  "$sid_fastq_pair_list" ]
then
    echo "Sequences reads pair file does not exist: $sid_fastq_pair_list"
    echo "Exiting..."
    exit 1
fi



echo -e "\n\e[0;"$color"m Renaming read headers \033[0m\n"
renamed_dir=$usearch_dir"/renamed"
mkdir -p $renamed_dir
while read sid_fastq_pair; 
do
    sid=`echo $sid_fastq_pair | awk -F ' ' '{print $1}'`; 
    fastq_r1=`echo $sid_fastq_pair | awk -F ' ' '{print $2}'`;
    fastq_r2=`echo $sid_fastq_pair | awk -F ' ' '{print $3}'`;
    fastq_r1_renamed=$renamed_dir"/"$(basename $fastq_r1);
    fastq_r2_renamed=$renamed_dir"/"$(basename $fastq_r2);
    rename_fastq_headers.sh $sid $fastq_r1 $fastq_r2 $fastq_r1_renamed $fastq_r2_renamed;
done < $sid_fastq_pair_list

#TO BE DONE
#must optimize here there are too many file copies generate and variables assigned
#fastx_renamer  is cpu intensive definately a candidate for parrallelizing



echo -e "\n\e[0;"$color"m Merging reads \033[0m\n"
fastq_maxdiffs=10
merged_dir=${usearch_dir}/merged
unmerged_dir=${usearch_dir}/unmerged
reports=${process_dir}/reports
mkdir -p $merged_dir  $unmerged_dir $reports
while read sid_fastq_pair;
do sid=`echo $sid_fastq_pair | awk -F ' ' '{print $1}'`;
fastq_r1=`echo $sid_fastq_pair | awk -F ' ' '{print $2}'`;
fastq_r2=`echo $sid_fastq_pair | awk -F ' ' '{print $3}'`;
fastq_r1_renamed=$renamed_dir"/"$(basename $fastq_r1);
fastq_r2_renamed=$renamed_dir"/"$(basename $fastq_r2);
out_fwd=$(basename $fastq_r1);
out_rev=$(basename $fastq_r2); 
usearch -fastq_mergepairs $fastq_r1_renamed\
	-reverse $fastq_r2_renamed\
        -fastq_maxdiffs $fastq_maxdiffs\
	-fastqout $merged_dir"/"$sid".merged.fastq"\
	-tabbedout $reports/tabbedout_${sid}.txt\
	-report $reports/report_${sid}.txt\
	-alnout $reports/aln_${sid}.txt\
	-fastqout_notmerged_fwd $unmerged_dir/${out_fwd}\
	-fastqout_notmerged_rev $unmerged_dir/${out_rev}
done < $sid_fastq_pair_list

# usearch -fastq_mergepairs
# supports multiprocessing default is 10 cores
# -fastq_maxdiffs  Maximum number of mismatches in the alignment. Default 5. Consider increasing if you have long overlaps.
# -fastq_pctid  Minimum %id of alignment. Default 90. Consider decreasing if you have long overlaps.
# -fastq_nostagger  Discard staggered pairs. Default is to trim overhangs (non-biological sequence).
# -fastq_merge_maxee  Maximum expected errors in the merged read. Not recommended for OTU analysis.
# -fastq_minmergelen  Minimum length for the merged sequence. See Filtering artifacts by setting a merge length range.
# -fastq_maxmergelen  Maximum length for the merged sequence.
# -fastq_minqual  Discard merged read if any merged Q score is less than the given value. (No minimum by default).
# -fastq_minovlen  Discard pair if alignment is shorter than given value. Default 16.
# https://www.biostars.org/p/225683/




#*****************************************************************************************************************************#
echo -e "\n\e[0;"$color"m Joining unmerged reads \033[0m\n"
seq2sid.py -r $unmerged_dir -o $unmerged_dir
merged_dir_final=${usearch_dir}/merged_final
unmerged_fastq_pairs=$unmerged_dir/sid_fastq_pair.list
join_merged_dir=${usearch_dir}/join_merged
mkdir -p $join_merged_dir  $merged_dir_final
while read sid_fastq_pair;
do
    sid=`echo $sid_fastq_pair | awk -F ' ' '{print $1}'`;
    fastq_r1=`echo $sid_fastq_pair | awk -F ' ' '{print $2}'`;
    fastq_r2=`echo $sid_fastq_pair | awk -F ' ' '{print $3}'`;
    joined_fastq=${join_merged_dir}/${sid}_unmerged_tmp.fastq
    usearch -fastq_join $fastq_r1 -reverse $fastq_r2 -fastqout $joined_fastq

    grep "nohsp" $reports/tabbedout_${sid}.txt | cut -f 1 >  ${join_merged_dir}/$nohsp_${sid}.labels

    usearch -fastx_getseqs  $joined_fastq -labels ${join_merged_dir}/$nohsp_${sid}.labels -trunclabels -fastqout ${join_merged_dir}/${sid}_joined.fastq

    usearch -fastq_eestats2 ${merged_dir}/${sid}.merged.fastq  -ee_cutoffs 0.05,0.1,0.25,0.5,0.75,1.0 -output ${merged_dir}/${sid}_eestats2.txt ;

    cat ${join_merged_dir}/${sid}_joined.fastq  ${merged_dir}/${sid}.merged.fastq >  ${merged_dir_final}/${sid}.merged.fastq

    usearch -fastq_eestats2 ${merged_dir_final}/${sid}.merged.fastq  -ee_cutoffs 0.05,0.1,0.25,0.5,0.75,1.0 -output ${merged_dir_final}/${sid}_eestats2.txt ;

done < $unmerged_fastq_pairs
#*****************************************************************************************************************************#




# mkdir -p ${fastqc_dir}/merged_final
# fastqc --extract -f fastq -o ${fastqc_dir}/merged_final ${join_merged_dir}/*fastq



echo -e "\n\e[0;"$color"m Filtering reads \033[0m\n"
fastq_maxee=5
filtered_dir=${usearch_dir}/filtered
mkdir -p $filtered_dir
while read sid_fastq_pair
do
   sid=`echo $sid_fastq_pair | awk -F ' ' '{print $1}'`;

   usearch -fastq_filter ${merged_dir_final}/${sid}.merged.fastq -fastq_maxee $fastq_maxee   -fastqout ${filtered_dir}/${sid}.merged.filtered.fastq ;

   usearch -fastq_eestats2 ${filtered_dir}/${sid}.merged.filtered.fastq  -ee_cutoffs 5,6,7,8,9,10 -output ${filtered_dir}/${sid}_eestats2.txt ;
   
done < $sid_fastq_pair_list
#-fastq_maxee $fastq_maxee
# fastq_maxee E
# Discard reads with > E total expected errors for all bases in the read after any truncation options have been applied.




# mkdir -p ${fastqc_dir}/filtered
# fastqc --extract -f fastq -o ${fastqc_dir}/filtered  $filtered_dir/*fastq



echo -e "\n\e[0;"$color"m Converting fastq to fasta \033[0m\n"
filtered_fasta_dir=${usearch_dir}/filtered.fasta
mkdir -p $filtered_fasta_dir
for i in `ls -1 $filtered_dir/*.fastq`;
do
   filename=$(basename "$i");
   base="${filename%.*}"; 
   seqtk seq -A $i > $filtered_fasta_dir/$base.fa;
done
cat $filtered_fasta_dir/*.fa > $usearch_dir/filtered_all.fa



echo -e "\n\e[0;"$color"m Dereplication \033[0m\n"
usearch -fastx_uniques $usearch_dir/filtered_all.fa -fastaout $usearch_dir/filtered_all.uniques.sorted.fa -sizeout -relabel Uniq
#usearch -fastx_learn $usearch_dir/filtered_all.uniques.sorted.fa -output $reports/uniques_learn.txt



echo -e "\n\e[0;"$color"m Picking OTUs \033[0m\n"
usearch -cluster_otus $usearch_dir/filtered_all.uniques.sorted.fa\
	-relabel OTU_\
	-otus $usearch_dir/otus_raw.fa\
	-uparseout $usearch_dir/uparse.txt\
	-uparsealnout $usearch_dir/uparsealnout.txt\
        -minsize 1




# Create OTU table for 97% OTUs
echo -e "\n\e[0;"$color"m Create OTU table for 97% OTUs \033[0m\n"
usearch -otutab $usearch_dir/filtered_all.fa\
        -otus	$usearch_dir/otus_raw.fa\
	-otutabout $usearch_dir/otutab.txt\
	-biomout $usearch_dir/otutab.json\
        -mapout $usearch_dir/map.txt\
	-notmatched $usearch_dir/unmapped.fa\
	-dbmatched $usearch_dir/otus_with_sizes.fa\
	-sizeout




# Create ZOTUs by denoising (error-correction)
#usearch -unoise3 $usearch_dir/filtered_all.uniques.sorted.fa -zotus $usearch_dir/zotus.fa




# Create OTU table for ZOTUs
#usearch -otutab $usearch_dir/filtered_all.fa -zotus $usearch_dir/zotus.fa  -strand plus -otutabout $usearch_dir/zotutab.txt



echo -e "\n\e[0;"$color"m Assigning taxonomy \033[0m\n"
taxonomy_dir=$process_dir/taxonomy
ref_tax=/home/drewx/Documents/Paribus/consensus_taxonomy_7_levels.txt
ref_db=/home/drewx/Documents/Paribus/97_otus_18S.fasta
mkdir -p $taxonomy_dir
assign_taxonomy.py -v -i $usearch_dir/otus_with_sizes.fasta\
		   -o $taxonomy_dir\
		   -r $ref_db\
		   -t $ref_tax\
		   -m uclust



echo -e "\n\e[0;"$color"m Adding taxonomy data to BIOM file \033[0m\n"
biom add-metadata\
     -i $usearch_dir/otutab.json\
     -o $process_dir/otus_table.tax.biom\
     --observation-metadata-fp $taxonomy_dir/otus_with_sizes_tax_assignments.txt\
     --observation-header OTUID,taxonomy,confidence\
     --sc-separated taxonomy\
     --float-fields confidence\
     --output-as-json
     


alignment_dir=$process_dir/align
mkdir $alignment_dir
align_seqs.py -m pynast  -i $usearch_dir/otus_with_sizes.fasta -o $alignment_dir -t $greengenes_db/rep_set_aligned/97_otus.fasta


filter_alignment.py -i $alignment_dir/otus_with_sizes_aligned.fasta -o $alignment_dir/filtered

make_phylogeny.py -i $alignment_dir/filtered/otus_with_sizes_aligned_pfiltered.fasta -o $process_dir/otus_with_sizes_aligned_pfiltered.tre

biom summarize-table -i $process_dir/otus_table.tax.biom -o $process_dir/otus_table.tax.biom.summary.quantative

biom summarize-table --qualitative -i $process_dir/otus_table.tax.biom -o $process_dir/otus_table.tax.biom.summary.qualitative


