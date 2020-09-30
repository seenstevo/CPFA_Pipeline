#!/bin/bash

fimo=$1
pair_max_distance=50
pair_max_distance=$2
threads=`nproc`
let "threads-=1"	#default
threads=$3		# user override

name=`echo ${fimo} | rev | cut -d"/" -f1 | rev | cut -d"." -f1`

# First generate a bed file of the FIMO hits
awk 'NR>1 {OFS="\t"; split($2, a, ":"); split(a[4], b, "-"); print a[3], b[1]+$3, b[1]+$4, a[1], $1, $8}' ${fimo} > ./${name}_Outputs/${name}.bed

# Now we assign a top FIMO hit to each window region
bedtools intersect -wo -F 0.8 -a ./${name}_Outputs/${name}_w*_s*_region_windows.bed -b ./${name}_Outputs/${name}.bed | awk '($10>7)' | \
awk 'BEGIN {START=""} {if($2!=START) {OFS="\t"; print $1, $2, $3, $4":"$5"-"$6, $7, $8; START=$2}}' > ./${name}_Outputs/${name}_window_top_hit

# This splits the window top hit file into chromosomes so we can analyse each individually (this might not be a good idea if genome assembly is incomplete - i.e. many scaffolds)
awk -vn="${name}" '{print > "./"n"_Outputs/Chr_Chunks_"$1}' ./${name}_Outputs/${name}_window_top_hit

# this function takes the window_top_hit input and collects the pairs of motifs that lie within a specified distance (or 50bp up or downstream as default)
process_pairs () {
	x=0; 
	while read p; do 
		let "x+=1"; start=`expr ${x} - 100`; end=`expr ${x} + 100`; 
		awk -vs="${start}" -ve="${end}" '(NR>s && NR<e)' $1 > $1_subset_file; 
		anchor=`echo ${p} | cut -d" " -f6`; 
		hits=`echo ${p} | awk -v d="${pair_max_distance}" '{OFS="\t"; print $1, $2-d, $3+d}' | bedtools intersect -wo -a stdin -b $1_subset_file | cut -f9`; 
		for hit in ${hits}; do 
			if [[ ${anchor} != ${hit} ]]; then 
				if [[ ${anchor} > ${hit} ]]; then 
					echo ${anchor} ${hit}; 
				fi; 
			fi; 
		done; 
	done < $1
}
export -f process_pairs

# now we can parallise the process by running a chromosome on each thread
ls ./${name}_Outputs/Chr_Chunks* | parallel --ungroup -j ${threads} "process_pairs {}" > ./${name}_Outputs/output

# this step actually counts the pairs frequencies from the combined outputs from each chromosome
sort ./${name}_Outputs/output | uniq -c | awk '{OFS="\t"; print $2, $3, $1}' > ./${name}_Outputs/Cis_Pair_Frequencies_${name}_d${pair_max_distance}

# Cleanup
rm ./${name}_Outputs/Chr_Chunks*; rm ./${name}_Outputs/output; rm ./${name}_Outputs/${name}.bed