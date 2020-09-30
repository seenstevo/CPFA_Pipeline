#!/bin/bash

fasta=$1
meme=$2

name=`echo ${fasta} | rev | cut -d"/" -f1 | rev | cut -d"." -f1`

# create the nucleotide composition model
fasta-get-markov -m 1 ${fasta} ./${name}_Outputs/${name}.bg

# run fimo - we want this to be parallelised ideally
fimo -o ./${name}_Outputs/${name}_fimo --verbosity 1 --bgfile ./${name}_Outputs/${name}.bg ${meme} ${fasta}

# remove all file formats except the .txt
ls ./${name}_Outputs/${name}_fimo/* | grep -v -E ".txt" | xargs rm

# rename the fimo.txt file to the actual name
mv ./${name}_Outputs/${name}_fimo/fimo.txt ./${name}_Outputs/${name}_fimo/${name}.txt
