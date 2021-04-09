#!/usr/bin/python
import argparse
import os
import sys
import glob
import pprint

def dir2sid():

    parser = argparse.ArgumentParser(description="Compile list of paired sequence reads")

    parser.add_argument('-r','--read-dir', dest='read_dir',
                        action='store', required=True, type=str)
    parser.add_argument('-s','--spliton', dest='spliton', default="_R",
                        action='store', required=False, type=str)
    parser.add_argument('-o','--output-dir', dest='output_dir',
                        action='store', required=True, type=str)
    args = parser.parse_args()

    search_dir = os.path.join(args.read_dir,"*.fastq*")
    files  = glob.glob(search_dir)
    label  = lambda fname:  os.path.basename(fname.split(args.spliton)[0]) 
    files.sort()
    n = len(files)
    if n%2 != 0:
        raise Exception,"Uneven number of read, reads should paired"
    file_pairs = dict( (label(files[i]), files[i:i+2]) for i in range(0, len(files), 2))
    with open(os.path.join(args.output_dir,'sid_fastq_pair.list'),'w') as fp:
        for tag, reads in file_pairs.items():
            print >>fp,"{}\t{}\t{}".format(tag, reads[0],reads[1])
    

dir2sid()
