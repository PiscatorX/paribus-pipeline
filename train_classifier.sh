#!/bin/bash


repset=$1
taxonomy=$2
if [[ ${repset} != *"fna"* ]]
then

echo -e "\n\nFail! expected 'fna' extension in sequence file: ${repset} \n\n"

exit 1

fi


qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path ${repset} \
  --output-path ${repset/fna/qza}

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --source-format HeaderlessTSVTaxonomyFormat \
  --input-path ${taxonomy} \
  --output-path ${taxonomy/txt/qza}
