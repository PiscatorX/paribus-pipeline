#! /bin/bash




#CLUSTER DEFAULTS
ref_tax=/home/andhlovu/SILVA_128_QIIME_release/taxonomy/18S_only/97/consensus_taxonomy_7_levels.txt
ref_db=/home/andhlovu/SILVA_128_QIIME_release/rep_set/rep_set_18S_only/97/97_otus_18S.fasta
ref_align=/home/andhlovu/SILVA_128_QIIME_release/core_alignment/core_alignment_SILVA128.fna
threads=$PBS_NUM_PPN




#THREADS
if [ -z $threads ]   
then
    threads=2
fi



color=34
while getopts ":r:p:m:h" opt;
do
    case ${opt} in	
      h) echo "Paribus is pipeline for analysis paired-end reads generated by Illumina Miseq"
	 echo "Usage:"
	 echo "    paribus.sh -h               Display this help message."
	 echo "    paribus.sh -r  < single end fastq reads directory> -p   <processing directory (default:paribus.o)>"  
	 exit 0
      ;;
      :) "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
      r) raw_reads_dir="${OPTARG%/}"
	 
	 if [ ! -d "${raw_reads_dir}" ]
	 then
	     echo "Failed to locate the reads directory: $raw_reads_dir "
	     exit 1
	 fi
      ;;
      p) process_dir="${OPTARG%/}"
      ;;
      m) mem="${OPTARG%/}"
      ;;
      d) ref_db=$OPTARG
      ;;
      t) ref_tax=$OPTARG
      ;;
      \?) echo "Usage: paribus_se.sh [-h] 
                [-r fastq reads directory] 
                [-p output directory] 
                [-m memory for rdp classifier]"
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
    echo "    -t taxon assignment reference fasta file database (default: 97_otu.fasta )"
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

if [ -z $mem ]   
then
    mem=2
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




fastqc_dir=$process_dir/fastqc
mkdir -p $fastqc_dir/raw_reads
fastqc --extract -t $threads  -f fastq -o "${fastqc_dir}"/raw_reads "${raw_reads_dir}"/*.fastq




seq2sid_se.py "${raw_reads_dir}" -o "${process_dir}"
sid_fastq_pair_list=$process_dir/sid_fastq_pair.list
if [ ! -e  "$sid_fastq_pair_list" ]
then
    echo "Sequences reads pair file does not exist: $sid_fastq_pair_list"
    echo "Exiting..."
    exit 1
fi




echo -e "\n\e[0;"$color"m Renaming read headers \033[0m\n"
renamed_dir=$usearch_dir"/renamed"
raw_fasta=$usearch_dir"/raw_fasta"
mkdir -p $renamed_dir $raw_fasta

while read sid fastq_r1;
do
    echo $sid $fastq_r1    
    fastq_r1_renamed=$renamed_dir"/"$(basename $fastq_r1);
    echo $fastq_r1_renamed
    if [ -z "$TMPDIR" ]; then
	TMPDIR=/tmp
    fi
    echo $sid 
    echo $fastq_r1
    
    #fastx_toolkit needs to be setup in PATH
    #Sort out forward read
    
    basename=`basename $fastq_r1`
    fastx_renamer -Q33 -n COUNT -i $fastq_r1 -o $TMPDIR/${basename}_tmp
    sed "s/^\(@\|+\)\([0-9]*\)$/\1$sid \2;barcodelabel=$sid \/1/" $TMPDIR/${basename}_tmp > $TMPDIR/${basename}_renamed
    rm -f $TMPDIR/${basename}_tmp
    mv $TMPDIR/${basename}_renamed $fastq_r1_renamed
    echo $fastq_r1_renamed
    echo $TMPDIR
    usearch -fastq_eestats2 $fastq_r1_renamed  -ee_cutoffs 0.75,1,2,3,4,5 -output ${fastq_r1_renamed}_eestats2.txt
    fasta_fname="${basename%.*}".fasta
    usearch -fastq_filter $fastq_r1_renamed -fastaout ${raw_fasta}/${fasta_fname}
    
done < $sid_fastq_pair_list

cat ${raw_fasta}/*.fasta   >  ${raw_fasta}/raw_reads.fasta

#TO BE DONE
#must optimize here there are too many file copies generate and variables assigned
#fastx_renamer  is cpu intensive definately a candidate for parrallelizing




echo -e "\n\e[0;"$color"m Filtering reads \033[0m\n"
fastq_maxee=5
filtered_dir=${usearch_dir}/filtered
mkdir -p $filtered_dir
while read sid fastq_r1
do
    
   fastq_r1_renamed=$renamed_dir"/"$(basename $fastq_r1);
   fastq_r1=$(basename fastq_r1)
   fasta_fname="${fastq_r1%.*}".fasta
   usearch -fastq_filter ${fastq_r1_renamed} -fastq_maxee $fastq_maxee   -fastaout  ${filtered_dir}/${fasta_fname}
   
    
done < $sid_fastq_pair_list
cat $filtered_dir/*.fasta > $usearch_dir/filtered_all.fasta
-fastq_maxee $fastq_maxee
fastq_maxee E
Discard reads with > E total expected errors for all bases in the read after any truncation options have been applied.




echo -e "\n\e[0;"$color"m Dereplication \033[0m\n"
usearch -fastx_uniques $usearch_dir/filtered_all.fasta\
	-fastaout $usearch_dir/filtered_all.uniques.sorted.fasta\
	-sizeout -relabel Uniq\
        -threads $threads




echo -e "\n\e[0;"$color"m Picking OTUs \033[0m\n"
usearch -cluster_otus $usearch_dir/filtered_all.uniques.sorted.fasta\
	-relabel OTU_\
	-otus $usearch_dir/otus_raw.fasta\
        -minsize 1\
	-uparseout $usearch_dir/uparse.txt\
        -fulldp




# Create OTU table for 97% OTUs
echo -e "\n\e[0;"$color"m Create OTU table for 97% OTUs \033[0m\n"
usearch -otutab ${raw_fasta}/raw_reads.fasta\
        -otus	$usearch_dir/otus_raw.fasta\
	-otutabout $usearch_dir/otutab.txt\
	-biomout $usearch_dir/otutab.json\
        -mapout $usearch_dir/map.txt\
	-notmatched $usearch_dir/notmatched.fasta\
	-dbmatched $usearch_dir/otus.fasta\
        -threads $threads\
	-fulldp




echo -e "\n\e[0;"$color"m Assigning taxonomy UCLUST \033[0m\n"
taxonomy_dir_uclust=$process_dir/taxonomy/uclust
mkdir -p $taxonomy_dir_uclust
assign_taxonomy.py -v\
		   -i $usearch_dir/otus.fasta\
		   -o $taxonomy_dir_uclust\
		   -r $ref_db\
		   -t $ref_tax\
		   -m uclust




echo -e "\n\e[0;"$color"m Adding taxonomy data to BIOM file \033[0m\n"
process_out=$process_dir/uclust
mkdir -p $process_out
tag=$(basename $raw_reads_dir)
biom add-metadata\
     -i $usearch_dir/otutab.json\
     -o tax_${tag}_otus.biom\
     --observation-metadata-fp $taxonomy_dir_uclust/otus_tax_assignments.txt\
     --observation-header OTUID,taxonomy,confidence\
     --sc-separated taxonomy\
     --float-fields confidence\
     --output-as-json




summaries=$process_out/summaries
krona_plots=$process_out/Krona
mkdir -p $summaries $krona_plots
summarize_taxa.py -i tax_${tag}_otus.biom\
		  -m $usearch_dir/map.txt\
		  -o $summaries
summary2krona.py ${summaries}/${tag}_tax_otus_L6.txt\
		 -o ${summaries}/${tag}_krona.tsv
ktImportText ${summaries}/${tag}_krona.tsv\
	     -o ${krona_plots}/${tag}_krona.html



echo -e "\n\e[0;"$color"m Aligning the sequences \033[0m\n"
alignment_dir=$process_dir/align/uclust
mkdir -p $alignment_dir
align_seqs.py -m pynast\
	      -i $usearch_dir/otus.fasta\
	      -p 60\
	      -o $alignment_dir\
	      -t $ref_align




echo -e "\n\e[0;"$color"m Filtering the alignment  \033[0m\n"
filter_alignment.py -i $alignment_dir/otus_aligned.fasta\
		    -o $alignment_dir/filtered\
		    -e 0.10\
                    -g 0.80\
                    -s




echo -e "\n\e[0;"$color"m Reconstructing the phylogeny \033[0m\n"
make_phylogeny.py -i $alignment_dir/filtered/otus_aligned_pfiltered.fasta -o $process_out/otus_aligned_pfiltered.tre




echo -e "\n\e[0;"$color"m Biom table summarising \033[0m\n"
biom summarize-table -i $process_out/otus_table.tax.biom -o $process_out/otus_table.tax.biom.summary.quantative
biom summarize-table --qualitative -i $process_out/otus_table.tax.biom -o $process_out/otus_table.tax.biom.summary.qualitative




###############################################################################################################################
echo -e "\n\e[0;"$color"m Assigning taxonomy RDP \033[0m\n"
taxonomy_dir_rdp=$process_dir/taxonomy/rdp
mkdir -p $taxonomy_dir_rdp
assign_taxonomy.py -v\
		   -i $usearch_dir/otus.fasta\
		   -o $taxonomy_dir_rdp\
		   -r $ref_db\
		   -t $ref_tax\
		   -m rdp\
                   --rdp_max_memory $mem



echo -e "\n\e[0;"$color"m Adding taxonomy data to BIOM file \033[0m\n"
process_out=$process_dir/rdp
mkdir -p $process_out
tag=$(basename $raw_reads_dir)
biom add-metadata\
     -i $usearch_dir/otutab.json\
     -o $process_out/otus_table.tax.biom\
     --observation-metadata-fp $taxonomy_dir_rdp/otus_tax_assignments.txt\
     --observation-header OTUID,taxonomy,confidence\
     --sc-separated taxonomy\
     --float-fields confidence\
     --output-as-json




summaries=$process_out/summaries
krona_plots=$process_out/Krona
mkdir -p $summaries $krona_plots
summarize_taxa.py -i ${tag}_tax_otus.biom\
		  -m $usearch_dir/map.txt\
		  -o $summaries
summary2krona.py ${summaries}/${tag}_tax_otus_L6.txt\
		 -o ${summaries}/${tag}_krona.tsv
ktImportText ${summaries}/${tag}_krona.tsv\
	     -o ${krona_plots}/${tag}_krona.html



echo -e "\n\e[0;"$color"m Aligning the sequences \033[0m\n"
alignment_dir=$process_dir/align/rdp
mkdir -p $alignment_dir
align_seqs.py -m pynast\
	      -i $usearch_dir/otus.fasta\
	      -p 60\
	      -o $alignment_dir -t $ref_align




echo -e "\n\e[0;"$color"m Filtering the alignment  \033[0m\n"
filter_alignment.py -i $alignment_dir/otus_aligned.fasta\
		    -o $alignment_dir/filtered\
		    -e 0.10\
                    -g 0.80\
                    -s




echo -e "\n\e[0;"$color"m Reconstructing the phylogeny \033[0m\n"
make_phylogeny.py -i $alignment_dir/filtered/otus_aligned_pfiltered.fasta -o $process_dir/otus_aligned_pfiltered.tre




echo -e "\n\e[0;"$color"m Biom table summarising \033[0m\n"
biom summarize-table -i $process_out/otus_table.tax.biom -o $process_out/otus_table.tax.biom.summary.quantative
biom summarize-table --qualitative -i $process_out/otus_table.tax.biom -o $process_out/otus_table.tax.biom.summary.qualitative

