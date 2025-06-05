#!/usr/bin/env bash

SEEDFILE=${1:?"Specity a seedfile name, e.g., seedfile.csv \n Its format is \n DS050_unmapped,Clostridium botulinum,s3://genomics-workflow-core/Results/DSQC/20241009_MITI-001_DS-mNGS_HL735BGXW_Q30-L50_debug/03_postprocess/unmapped/filtered_PE_lca/20240927_DS050_B01_PE_lca.tsv,s3://genomics-workflow-core/Results/DSQC/20241009_MITI-001_DS-mNGS_HL735BGXW_Q30-L50_debug/01_preprocess/unmapped/20240927_DS050_B01/20240927_DS050_B01_PE.fasta"}


mkdir -p header
mkdir -p target_reads


while IFS=',' read -r -a Array
do
   case "${Array[0]}" in \#*) continue ;; esac
   echo "${Array[0]}"
   DS="${Array[0]}"
   ref="${Array[1]}"
   # blast_results="${Array[2]}"
   echo ${Array[2]}
   echo ${Array[3]}

   ref2=$(echo "$ref" | sed 's/ /_/g')

   echo ${ref2}

# download 
aws s3 cp ${Array[3]} fasta/${DS}_PE.fasta
aws s3 cp ${Array[2]} LCA/${DS}_LCA.tsv

grep "$ref;" LCA/${DS}_LCA.tsv |  cut -f1 | sort | uniq  |  awk -F'_' '{print $1":"$2":"$3":"$4":"$5":"$6":"$7" "$8":"$9":"$10":"$11"+"$12}' > header/${DS}_${ref2}_headers.txt


# find pairs
cut -f1 -d" " header/${DS}_${ref2}_headers.txt | uniq | sed 's/:/_/g'  >header/${DS}_${ref2}_headers_PE.txt 

# get reads in fasta
filterbyname.sh in=fasta/${DS}_PE.fasta  out=target_reads/${DS}_${ref2}.fasta substring=t names=header/${DS}_${ref2}_headers_PE.txt include=t  overwrite=t


done < ${SEEDFILE}
