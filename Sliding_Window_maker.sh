#!/bin/bash

fimo=$1
window=20	# default
window=$2	# override default
step=5		# default
step=$3		# override default

name=`echo ${fimo} | rev | cut -d"/" -f1 | rev | cut -d"." -f1`

# First we find all the fimo regions within which we will generate the sliding windows
awk 'NR>1 {OFS="\t"; split($2, a, ":"); split(a[4], b, "-"); print a[3], b[1], b[2], a[1]}' ${fimo} | sort -k1,1 -k2,2n | uniq > ./${name}_Outputs/${name}_regions.bed

# Now we generate the windows based on user defined parameters or default of 20 and 5
bedtools makewindows -b ./${name}_Outputs/${name}_regions.bed -w ${window} -s ${step} > ./${name}_Outputs/${name}_w${window}_s${step}_region_windows.bed

# remove the regions.bed file
rm ./${name}_Outputs/${name}_regions.bed