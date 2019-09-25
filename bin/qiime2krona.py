#!/usr/bin/env python

import argparse
import itertools
import csv



class Qiime2Krona(object):

    def __init__(self):

        parser = argparse.ArgumentParser(description="""Convert  Qiime2  summary csv file to Krona tsv.""")
        parser.add_argument("qiime2_taxa_csv")
        args, unknown = parser.parse_known_args()
        self.qiime_taxa_fp =  open(args.qiime2_taxa_csv)
        self.filter_func = lambda x : x == 'BarcodeSequence'
        
        
    def extract_tables(self):
        
         header  = next(self.qiime_taxa_fp).split(",")
         csv_reader = csv.DictReader(self.qiime_taxa_fp,header)
         for row in csv_reader:
             sample_id  = row['index']
             fname = '_Krona.'.join([sample_id,'tsv'])
             file_obj = open(fname, "w")
             filtered_row = self.take_until(row, self.filter_func)
             for taxon,frequency in filtered_row.items():
                 if taxon.startswith("D"):
                     taxon ='\t'.join([ taxon.strip().split('__')[1:][0] for taxon in taxon.split(";") ]).strip()
                     print("{}\t{}".format(frequency, taxon), file=file_obj)
             print(fname)
             
    def take_until(self, row, predicate):
        filtered_row = {}
        for key, value in row.items():
            if predicate(key):
                return filtered_row 
            filtered_row[key] = value

        return filtered_row
    

if __name__ == "__main__":
    qiime2krona =  Qiime2Krona()
    qiime2krona.extract_tables()
