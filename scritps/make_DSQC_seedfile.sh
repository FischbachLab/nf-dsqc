#!/bin/bash

set -euoE pipefail

# Generate a seedfile for all samples within an s3 project bucket for DSQC
# Example:
# bash  make_DSQC_seedfile.sh s3://genomics-workflow-core/Results/Ninjamap/MITI-001v3/20240311_MITI-001_DS-mNGS_HWLMNBGXV_Q25-L50_debug/ MITI-DSQC.seedfile.csv 


S3PATH=${1:?"Specity an s3 path"} 
SEEDFILE=${2:?"Specity a seedfile file name"}

sample=$(mktemp /tmp/tmp_sample_list.XXXXXX)

#echo -e "sampleName,Path" > $SEEDFILE

#single lane
aws s3 ls $S3PATH | rev | cut -d' ' -f1 | rev >$sample

#echo $S3PATH
#echo $sample

#echo -e "sampleName,Path"

for i in $(cat $sample);
do

    i=${i%/*}	
    S3=${S3PATH%/} 
      
    if [ ${i} != "aggregated_ninjamap_results" ] && [ ${i} != "pipeline_info" ];
    then
        echo "$i,$S3" >> $SEEDFILE
    fi  
done

rm $sample




