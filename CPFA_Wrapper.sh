#!/bin/bash

#gene_list=$1
#DHS_bed=$2
#genome=$3
#meme=$4
window=20
step=5
pair_max_distance=50
threads=`nproc`
let "threads -= 1"

###### sets the flag options that override the deafult above #######
ARGS=""
while [ $# -gt 0 ]
do
    unset OPTIND
    unset OPTARG
    while getopts w:s:p:t:  options
    do
    case $options in
            w)  window="$OPTARG"
                    ;;
            s)  step="$OPTARG"
                    ;;
            p)  pair_max_distance="$OPTARG"
                    ;;
			t)  threads="$OPTARG"
                    ;;
        esac
   done
   shift $((OPTIND-1))
   ARGS="${ARGS} $1 "
   shift
done


#### This part sets our file arguments ####

for ARG in $ARGS
do
	file_ext=`echo ${ARG} | rev | cut -d"." -f1 | rev`
	if [[ ${file_ext} == "fa" ]] || [[ ${file_ext} == "fasta" ]]
	then
		genome=${ARG}
	elif [[ ${file_ext} == "bed" ]]
	then
		DHS_bed=${ARG}
	elif [[ ${file_ext} == "meme" ]]
	then
		meme=${ARG}
	else
		gene_list=${ARG}
	fi
done


##### set name variables #####
name=`echo ${gene_list} | rev | cut -d"/" -f1 | rev | cut -d"." -f1`
fimo="./${name}_Outputs/${name}_fimo/${name}.txt"

echo "Flag options being used:"
echo "window size = "${window}
echo "step size = "${step}
echo "max cis-pair distance = "${pair_max_distance}
echo "threads = "${threads}
echo "Files being used:"
echo "gene list = "${gene_list}
echo "DHS regions file = "${DHS_bed}
echo "genome fasta file = "${genome}
echo "jaspar meme file = "${meme}


#################### create fasta file for BG if needed ####################
if [[ ! -f ./BG_Outputs/BG.fa ]]; then 
	bash Create_fasta_DHS_BG.sh ${DHS_bed} ${genome}; 
fi

#################### create fasta file for test set ####################
if [[ ! -f ./${name}_Outputs/${name}.fa ]]; then 
	bash Create_fasta_DHS_gene_set.sh ${gene_list} ${DHS_bed} ${genome}; 
fi

#################### run fimo on fastas ####################
# BG if needed
if [[ ! -d ./BG_Outputs/BG_fimo ]]; then 
	bash Generate_Cistrome_FIMO.sh ./BG_Outputs/BG.fa ${meme}; 
fi
# test
if [[ ! -d ./${name}_Outputs/${name}_fimo ]]; then 
	bash Generate_Cistrome_FIMO.sh ./${name}_Outputs/${name}.fa ${meme}; 
fi

#################### generate sliding window regions for DHS regions of interest ####################
# BG if needed
if [[ ! -f ./BG_Outputs/BG_w${window}_s${step}_region_windows.bed ]]; then 
	bash Sliding_Window_maker.sh ./BG_Outputs/BG_fimo/BG.txt ${window} ${step}; 
fi
# test
if [[ ! -f ./${name}_Outputs/${name}_w${window}_s${step}_region_windows.bed ]]; then 
	bash Sliding_Window_maker.sh ${fimo} ${window} ${step}; 
fi

#################### count frequencies of cis-pairs ####################
# BG if needed
if [[ ! -f ./BG_Outputs/Cis_Pair_Frequencies_BG_d${pair_max_distance} ]]; then 
	bash Cis_Pair_Frequency_Counter.sh ./BG_Outputs/BG_fimo/BG.txt ${pair_max_distance} ${threads}; 
fi
# test
if [[ ! -f ./${name}_Outputs/Cis_Pair_Frequencies_${name}_d${pair_max_distance} ]]; then 
	bash Cis_Pair_Frequency_Counter.sh ${fimo} ${pair_max_distance} ${threads};
fi

#################### calculate Fisher tests for cis-pair frequencies ####################
if [[ ! -f ./${name}_Outputs/${name}_merged_final ]] ; then 
	bash Fisher_Test_Cis_Pair_Frequencies.sh ./${name}_Outputs/Cis_Pair_Frequencies_${name}_d${pair_max_distance} ./BG_Outputs/Cis_Pair_Frequencies_BG_d${pair_max_distance};
fi

echo "Done with '"${name}"' pipeline"