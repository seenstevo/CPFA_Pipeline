#!/bin/bash

# Give the gene list a sensible name that relates what the set are
gene_list=$1
DHS_bed=$2
genome=$3

name=`echo ${gene_list} | rev | cut -d"/" -f1 | rev | cut -d"." -f1`

mkdir ./${name}_Outputs

grep -f ${gene_list} ${DHS_bed} | awk '($5<2000)' | bedtools getfasta -name -fi ${genome} -bed stdin -fo ./${name}_Outputs/${name}.fa


## we will add a second stage for extracting promoter regions when DHS is not available or not desired