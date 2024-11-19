#!/usr/bin/env bash -x

#set -e
#set -u
set -o pipefail

mkdir -p filtered_blast_results
mkdir -p filtered_unanticipated_blast_results
mkdir -p filtered_PE_lca
mkdir -p filtered_unanticipated_PE_reads_lca


sample=${1}
blast=${2}
sample_R1=${3}
sample_R2=${4}
perc=${5}
known_genomes=${6}

export TAXONKIT_DB="/mnt/efs/databases/Blast/taxdump/"
# file (params.taxonkit_db)

# get the anticipated genome list
#infile="246_Blast_preferred_no_duplicated_218.tsv"
infile=${known_genomes}

# Declare an associative array (hash table)
declare -A anticipated_hash
# Read the file line by line and populate the hash
while IFS= read -r line; do
    key="${line}"   # Extract the key 
    value=1 
    anticipated_hash["$key"]="$value"
done < "$infile"

#aws s3 cp s3://genomics-workflow-core/Results/DSQC/20240419_DS-mNGS/02_blast/${sample}.nt.tsv ${blast}

#cut -f1 95pct/filtered_anticipated/${sample}_filtered.tsv | sort | uniq  > 95pct/filtered_anticipated_uniq/${sample}_filtered_uniq_reads.tsv

# filer Blast results >= 100% or 98% match?
awk -v var="$perc" '{if( $3>=var && $15==100 && $4==$13){print $0}}' ${blast} > filtered_blast_results/${sample}_filtered_blast.tsv 

: '
while IFS=$'\t' read -r -a line      
       do
        # print the entire line
        #echo ${line[@]} taxid
         org=("${line[@]:16}")

        # write filtered blast results
         target_value=""
         target_value=${org}  #${g[@]}
         if [[ ! -z "$target_value" && ! "${anticipated_hash[$target_value]}" ]]; then
           for l in "${line[@]}"
           do
             echo -ne "${l}\t" >>  filtered_unanticipated_blast_results/${sample}_unanticipated_blast.tsv
           done
           # Print a newline at the end
           echo ""  >>  filtered_unanticipated_blast_results/${sample}_unanticipated_blast.tsv
         fi
       done < filtered_blast_results/${sample}_filtered_blast.tsv 
'

header1=$(mktemp /tmp/header1.XXXXXX)
header2=$(mktemp /tmp/header2.XXXXXX)
inter=$(mktemp /tmp/inter.XXXXXX)

# print PE headers only
awk 'NR%4==1 {print $0}' ${sample_R1} | awk -F'@' '{print $2}' > ${header1}
awk 'NR%4==1 {print $0}' ${sample_R2} | awk -F'@' '{print $2}' > ${header2}

c=0
intersection=()
touch filtered_PE_lca/${sample}_PE_lca.tsv

while IFS= read -r h1 && IFS= read -r h2 <&3; 
do 
   #echo ${h1} >> filtered_PE_genus/${sample}_PE_inter_ref_names.txt && echo ${h2} >> filtered_PE_genus/${sample}_PE_intersection_ref_names.txt 
    c=$((c+1))
   # echo "PE-$c" >> 98pct/filtered_PE_lca/${sample}_PE_intersection_ref_names.txt
   # get taxid only
   R1=$(grep -s ${h1} filtered_blast_results/${sample}_filtered_blast.tsv | cut -f17 | sort | uniq )
   R2=$(grep -s ${h2} filtered_blast_results/${sample}_filtered_blast.tsv | cut -f17 | sort | uniq )
   # get reads lengths
   LEN1=$(grep -s ${h1} filtered_blast_results/${sample}_filtered_blast.tsv | cut -f13 | head -n 1 )
   LEN2=$(grep -s ${h2} filtered_blast_results/${sample}_filtered_blast.tsv | cut -f13 | head -n 1 )

   # get taxid only
   # R1=$(grep ${h1} filtered_unanticipated_blast_results/${sample}_unanticipated_blast.tsv | cut -f17 | sort | uniq )
   # R2=$(grep ${h2} filtered_unanticipated_blast_results/${sample}_unanticipated_blast.tsv | cut -f17 | sort | uniq )
   # get reads lengths
   #LEN1=$(grep ${h1} filtered_unanticipated_blast_results/${sample}_unanticipated_blast.tsv | cut -f13 | head -n 1 )
   #LEN2=$(grep ${h2} filtered_unanticipated_blast_results/${sample}_unanticipated_blast.tsv | cut -f13 | head -n 1 )
   flag=0
   # check if grep result is not empty 
  if [[ -n "$R1" && -n "$R2" ]]; then
    #echo "$R1"
    #echo "$R2"
    declare -a taxa1=($R1)
    declare -a taxa2=($R2)

    for element in "${taxa1[@]}"
    do
      if [[  "${anticipated_hash[$element]}"  ]]; then
        #echo "$element"
        flag=1
        break
      fi
    done
    
    if [ $flag -eq 0 ]; then
      for element in "${taxa2[@]}"
      do
         if [[  "${anticipated_hash[$element]}"  ]]; then
         #echo "$element"
         flag=1
         break
         fi
      done
   fi

      if [ $flag -eq 0 ]; then
         #echo "+++++++++++++++++"   
         intersection=$(comm -12 <(echo "$R1") <(echo "$R2")) # >>  98pct/filtered_PE_lca/${sample}_PE_intersection_ref_names.txt
         comm -12 <(echo "$R1") <(echo "$R2") > ${inter}
         # >>  98pct/filtered_PE_lca/${sample}_PE_intersection_ref_names.txt
         n=$(comm -12 <(echo "$R1") <(echo "$R2") | wc -l)    
         #echo "$n"

         read=$(echo ${h1} | cut -f1 -d"/") 
         if [[ "$n" -eq 1 ]];
         then
            # no lca     
            #lca=$(echo -ne "${intersection}" | taxonkit name2taxid  | cut -f2- | taxonkit lineage  -r |   sed 's/;/\n/g' | tail -n1 | sed 's/\t/;/g' )
            lca=$(echo -ne "${intersection}" | taxonkit lineage  -r | sed 's/;/\n/g' | tail -n1 | sed 's/\t/;/g' )   
         else          
            reformated_intersection=$(cat ${inter} | sed ':a;N;$!ba;s/\n/\\n/g; s/;/\\n/g')
            #echo "${reformated_intersection}"
            if [[ -n "${reformated_intersection}" ]]; then
               #echo "${reformated_intersection}"
               #lca=$(echo -ne "${reformated_intersection}" |  taxonkit name2taxid |  cut -f2 | sed ':a;N;$!ba;s/\n/, /g' | taxonkit lca   | cut -f2 | taxonkit lineage -r |  sed 's/;/\n/g' | tail -n1 | sed 's/\t/;/g' )  
               lca=$(echo -ne "${reformated_intersection}" | sed ':a;N;$!ba;s/\n/, /g' | taxonkit lca | cut -f2 | taxonkit lineage -r |  sed 's/;/\n/g' | tail -n1 | sed 's/\t/;/g' )    
               #echo "$lca"
            fi 
         fi
       
         if [[ ! -z $lca ]]; then  
            printf "${read}\t${lca}\t${LEN1}\t${LEN2}\n" >> filtered_PE_lca/${sample}_PE_lca.tsv
            #echo "${read}\t${lca}\t${LEN1}\t${LEN2}"
         fi
     fi  
   fi
   done < ${header1}  3< ${header2}


# add header
printf "LCA\t${sample}\n" > ${sample}_reads_uniq.tsv
# get counts
cat filtered_PE_lca/${sample}_PE_lca.tsv | cut -f2 | sort | uniq -c | sed $'s/^ *\([0-9]*\) */\\1\t/' | awk -F'\t' '{print $2"\t"$1}'  >> ${sample}_reads_uniq.tsv

# remove the first numeric daata
sed -i 's/^[0-9]*;//' ${sample}_reads_uniq.tsv
sed -i '/^;/d' ${sample}_reads_uniq.tsv