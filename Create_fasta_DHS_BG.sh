#!/bin/bash

# If a user specified BG is wanted then run the "gene_set" script using the BG gene list as input
DHS_bed=$1
genome=$2

# create ouput directory for BG files
mkdir ./BG_Outputs

# We will take a random set of DHS regions (10000), however we also limit these to <2kbp as we do for the test DHS regions.
shuf ${DHS_bed} | awk '($5<2000)' | head -10000 | bedtools getfasta -name -fi ${genome} -bed stdin -fo ./BG_Outputs/BG.fa


## we will add a second stage for extracting promoter regions when DHS is not available or not desired