#!/bin/bash

#set -euoE pipefail

# Generate a line in seedfile for extracting read pairs for hitting a particular reference
# Example:
# bash make__seedfile.sh "20241120_DS057_B01,unmapped,Streptococcus pyogenes MGAS2096,s3://genomics-workflow-core/Results/DSQC/20241127_MITI-001_DS-mNGS"


input=${1:?"Specity sample_name,bin,ref_name,s3_path, e.g.,\"20241120_DS057_B01,unmapped,Streptococcus pyogenes MGAS2096,s3://genomics-workflow-core/Results/DSQC/20241127_MITI-001_DS-mNGS\""}

IFS=',' read -r -a array <<< "$input"

# Print each element in the array
#for element in "${array[@]}"
#do
#   printf "\"%s\"\n" "$element"
#done

echo "${array[0]}_${array[1]},${array[2]},${array[3]}/03_postprocess/${array[1]}/filtered_PE_lca/${array[0]}_PE_lca.tsv,${array[3]}/01_preprocess/${array[1]}/${array[0]}/${array[0]}_PE.fasta"
   

