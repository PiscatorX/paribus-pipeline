#!/usr/bin/python
import argparse
import os
import sys
import glob
import pprint



def dir2sid(args):
       
    search_dir = os.path.join(args.read_dir,"*.fastq*")
    files  = glob.glob(search_dir)
    label  = lambda fname:  os.path.basename(fname.split(args.spliton)[0]) 
    files.sort()
    n = len(files)
    file_pairs = [ (label(files[i]), files[i]) for i in range(0, len(files)) ]
    
    with open(os.path.join(args.output_dir,'sid_fastq_pair.list'),'w') as fp:
        for tag, read in file_pairs:
            print >>fp,"{}\t{}".format(tag, read)    

            
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Compile list of paired sequence reads")
    parser.add_argument('read_dir', action='store', type=str)
    parser.add_argument('-s','--spliton', dest='spliton', default="_R",
                        action='store', required=False, type=str)
    parser.add_argument('-o','--output-dir', dest='output_dir',
                        action='store', required=True, type=str)
    args = parser.parse_args()
    
    dir2sid(args)
