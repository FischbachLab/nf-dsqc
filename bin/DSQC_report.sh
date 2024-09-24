#!/usr/bin/env bash -x

#set -e
#set -u
set -o pipefail

input_dir=${1}
report=${2}
tag=${3}
#sortedSampleList=${3}

Rscript merge_results.R ${input_dir} "${report}.csv"

sed -i -e '/^,*/d' "${report}.csv"
sed -i -e '/^[0-9]+/d' "${report}.csv"
sed -i -e '/^,.*/d' "${report}.csv"

#sed -i -e 's/;/,/' ${report}.csv

#sed -i -e "s/root/no rank/" -e "s/^\b1\b/root/" -e "s/cellular organisms/no rank/" -e "s/^\b131567\b/cellular organisms/" -e "/^0/d" ${report}.csv 

#aws s3 cp ${seed} seedfile.csv
#header2=$(cut -d, -f1 seedfile.csv | tr "\n" "," | sed 's/,\{1\}$//')
#IFS=',' read -r -a array2 <<< "$header2"
#echo "${header2[@]}"

#header1="LCA,Rank"
#sortedSampleList=$(echo ${sortedSampleList// /})
#sortedSampleList=${sortedSampleList%]*}
#header2=${sortedSampleList#[*}

#header="${header1},${header2}"
#echo "$header"

# replace the 1st line
#sed "1s/.*/$header/" "${report}.csv" > "updated_${report}.csv"

#rm "${report}.csv" 

#temp_file=$(mktemp)
#echo "$header" > "$temp_file" && cat "${report}.csv" >> "$temp_file" && mv "$temp_file" "${report}.csv"

#export TAXONKIT_DB="/mnt/efs/databases/Blast/taxdump/"
# file (params.taxonkit_db)
: <<'COMM'
# get the anticipated genome list
infile="/mnt/efs/databases/DSQC/246_Blast_preferred_no_duplicated_218.tsv"

# double check the final output
# Declare an associative array (hash table)
declare -A anticipated_hash
# Read the file line by line and populate the hash
while IFS= read -r line; do
    key="${line}"   # Extract the key 
    value=1 
    anticipated_hash["$key"]="$value"
done < "${infile}"


while IFS=$',' read -r -a line      
       do
        #echo ${line[@]} taxid
         taxon=("${line[0]}")

        # write filtered blast results
         target_value=""
         target_value=${taxon}
         if [[ ! -z "$target_value" && ! "${anticipated_hash[$target_value]}" ]]; then
           for l in "${line[@]}"
           do
             echo -ne "${l}," >>  "filtered_${report}.csv"
           done
           # Print a newline at the end
           echo ""  >>  "filtered_${report}.csv"
         fi
       done < "${report}.csv"

if [  -f "filtered_${report}.csv" ]; then
  echo "filtered_${report}.csv found!"
  sed -i s/,$// "filtered_${report}.csv"
  mv "filtered_${report}.csv" "${report}_${tag}.csv"
else
  cp "${report}.csv" "${report}_${tag}.csv"
fi
COMM

cp "${report}.csv" "${report}_${tag}.csv"
