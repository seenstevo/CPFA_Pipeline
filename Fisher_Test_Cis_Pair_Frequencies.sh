#!/bin/bash

# we want to pass the test cis pair frequencies and the background
test=$1
bg=$2

name=`echo ${test} | rev | cut -d"/" -f1 | rev | cut -d"_" -f4,5`

# first we format the cis pairs such that each pair is unified in first column
awk '{OFS="\t"; print $1":"$2, $3}' ${test} > ${test}_tmp
awk '{OFS="\t"; print $1":"$2, $3}' ${bg} > ${bg}_tmp

# the outputs should already be sorted so now we can do an outer join
join ${bg}_tmp ${test}_tmp -a 1 -a 2 -e "0" -o 0,1.2,2.2 > ${name}_BG_merged
rm ${test}_tmp ${bg}_tmp

# get the totals for all cis pairs in test and bg results
test_total=`awk '{t+=$3} END {print t}' ${name}_BG_merged`	# make this only 1 awk line
bg_total=`awk '{t+=$2} END {print t}' ${name}_BG_merged`

echo -n "" > ./${name}_Outputs/${name}_expected
while read p; do 
	test_pos=`echo ${p} | cut -d" " -f3`; 
	bg_pos=`echo ${p} | cut -d" " -f2`; 
	test_neg=`expr ${test_total} - ${test_pos}`; 
	bg_neg=`expr ${bg_total} - ${bg_pos}`; 
	Rscript fisher_motif_test.R ${test_pos} ${bg_pos} ${test_neg} ${bg_neg};
	awk -vt="${bg_total}" -vp="${bg_pos}" -vtt="${test_total}" 'BEGIN {print (p/t)*tt}' >> ./${name}_Outputs/${name}_expected;
done < ${name}_BG_merged > ./${name}_Outputs/${name}_fisher_test

paste ${name}_BG_merged ./${name}_Outputs/${name}_fisher_test ./${name}_Outputs/${name}_expected | \
awk 'BEGIN {OFS="\t"; print "cis-pair1", "cis-pair2", "BG_Freq", "Test_Freq", "Fisher_pvalue", "Expected_value"} {OFS="\t"; print $1, $2, $3, $5, $6}' | \
sed 's/:/\t/g' > ./${name}_Outputs/${name}_merged_final

# cleanup
rm ${name}_BG_merged; rm ./${name}_Outputs/${name}_expected; rm ./${name}_Outputs/${name}_fisher_test




