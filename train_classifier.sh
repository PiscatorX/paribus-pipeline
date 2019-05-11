#!/bin/bash
set -e

usage()
{
 
  echo -e "\nTrain q2-feature-classifier"
  echo -e "Usage:"
  echo -e "  $0  -i  <reference reads> -t  <taxonomy>"  
  echo -e "  $0  -h  Display this help message.\n"
  exit 1
  
}

 
while getopts "i:t:o:h" opt;      
do
    case ${opt} in	
      h) usage
      ;;
      :) "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
      i) reference="${OPTARG%/}"
	 
	 if [ ! -f "${reference}" ]
	 then
	     echo "Failed to locate the reference sequences: ${reference}"
	     usage
	 elif [[ ${reference} != *"fna"* ]]
	 then

	 echo -e "\n\nFail! expected 'fna' extension in sequence file: ${reference} \n\n"

	 exit 1
	 fi

      ;;
      t) taxonomy="${OPTARG%/}"

 	 if [ ! -f "${taxonomy}" ]
	 then
	     echo "Failed to locate the reference taxonomy file: ${taxonomy}"
	     exit 1
	 fi
      ;;
      o) output_dir="${OPTARG%/}"
	 
      ;;
      d) ref_db=$OPTARG
      ;;
      t) ref_tax=$OPTARG
      ;;
      \?) echo -e "\nUnknown argument provided\n"
	  usage
      ;;
   esac
done

shift "$((OPTIND -1))"

for arg in taxonomy reference
do
    if [ -z  "${!arg}" ]
    then
	echo -e "missing argument for ${arg}"
	missing_arg=true
    fi
done


if [[ ${missing_arg} = true ]]
  then
     usage
fi


if [ -z "$output_dir" ]
   
then
    output_dir=$PWD
    
elif [ ! -d "$output_dir" ]
then     
     mkdir -pv "$output_dir"
     
fi


reference_fname=$(basename ${reference})
q2_reference=${output_dir}/${reference_fname/fna/qza}
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path ${reference} \
  --output-path ${q2_reference}


taxonomy_fname=$(basename ${taxonomy})
q2_taxonomy=${output_dir}/${taxonomy_fname/txt/qza}
qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path ${taxonomy} \
  --output-path ${q2_taxonomy}


qiime feature-classifier extract-reads \
     --i-sequences ${q2_reference} \
     --p-f-primer GCGGTAATTCCAGCTCCAA \
     --p-r-primer AATCCRAGAATTTCACCTCT \
     --o-reads "${output_dir}/ref_seqs.qza"


reference_fname=$(basename ${reference})
q2_classifier=${output_dir}/${reference_fname/fna/q2_classfier}
qiime feature-classifier fit-classifier-naive-bayes \
      --i-reference-reads "${output_dir}/ref_seqs.qza" \
      --i-reference-taxonomy ${q2_taxonomy} \
      --o-classifier ${q2_classifier}
