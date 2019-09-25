#!/usr/bin/env python

import pandas as pd
import argparse
import pprint
import csv



class  GenPhyloSeq(object):

    def __init__(self):
        
        parser = argparse.ArgumentParser(description="""generate phyloseq table from taxonomy and feture-table""")
        parser.add_argument("taxonomy", help="taxonomy tsv file")
        parser.add_argument("feature_table",help ="feature table tsv file")
        parser.add_argument("-o", "--output", help ="output file", default="phyloseq_table.tsv")
        parser.add_argument("-s", "--silva", help ="silva file", action="store_true")
        parser.add_argument("-b", "--bacteria", help ="silva file", action="store_true")
        parser.add_argument("-t", "--taxonomy_out", help ="output file for reformated taxonomy", default="phyloseq_Tax.tsv")
        args, unknown = parser.parse_known_args()
        self.taxa_table_fp  = open(args.taxonomy)
        self.feature_table_fp  = open(args.feature_table)
        self.output_fp = open(args.output, "w")
        self.taxa_out_fp = open(args.taxonomy_out, "w")
        self.silva =  args.silva
        self.bacteria = args.bacteria
        
    def build_taxa_table(self):
       
       header  = next(self.taxa_table_fp).strip().split("\t")
       tsv_reader  = csv.DictReader(self.taxa_table_fp, header, delimiter='\t')
       series_data = []
       conf_data  = []
       for row in tsv_reader:
           name  = row['OTUID']
           if self.silva:
               data  = [name] + [ taxon.split('__')[1] for taxon in  row['Taxon'].strip().split(";") if taxon.strip() ]  
           else:
               data  = [name] + [ taxon for taxon in  row['Taxon'].strip().split(";") if taxon.strip() ]

           conf_data.append(row['Confidence'])
           series_data.append(pd.Series(data, name = name))

           
       df_taxon_combined = pd.concat(series_data, axis=1)   
       self.df_taxon_table = df_taxon_combined.T
       self.df_taxon_table['Confidence'] = conf_data
       table_cols = self.df_taxon_table.columns
       colnames = ["OTUID", "Kingdom" , "Supergroup" , "Division" , "Class" , "Order" , "Family" , "Genus" , "Species" ]
       if self.bacteria:
           colnames = ["OTUID","Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species" ]
       columns = dict(zip(table_cols, colnames ))
       self.df_taxon_table.rename(columns = dict(zip(table_cols, colnames )),  inplace=True)
       self.df_taxon_table.to_csv(self.taxa_out_fp, sep="\t", index=False)

       
    def merge_df(self):
        self.df_feture_table = pd.read_csv(self.feature_table_fp, header=1, delimiter="\t")
        self.tax_feature_merged = pd.merge(self.df_feture_table, self.df_taxon_table, on="OTUID")
        self.tax_feature_merged.to_csv(self.output_fp,sep="\t", index=False)
        print(self.tax_feature_merged.head(10))
        print(self.tax_feature_merged.tail(10))
        
        
if __name__  ==  "__main__":       
    phyloseq_tables = GenPhyloSeq()
    phyloseq_tables.build_taxa_table()
    phyloseq_tables.merge_df()
