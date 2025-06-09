#!/usr/bin/env bash -x

set -e
set -u
set -o pipefail

#mkdir unmapped_files
#mkdir fastq_files

sample=${1}
S3INPUTPATH=${2}
THRES=${3}


aws s3 cp ${S3INPUTPATH}/${sample}/bowtie2/${sample}_unmapped_include_overlap_R1.fastq.gz ${sample}_include_overlap_R1.fastq.gz 
aws s3 cp ${S3INPUTPATH}/${sample}/bowtie2/${sample}_unmapped_include_overlap_R2.fastq.gz ${sample}_include_overlap_R2.fastq.gz 

#aws s3 cp ${S3INPUTPATH}/${sample}/bowtie2/${sample}_unmapped_no_overlap.bam  ${sample}_unmapped_no_overlap.bam 

echo "${sample}"

S3DBPATH=${S3DBPATH:-"s3://maf-versioned/ninjamap/Index/MITI-001v3_20240604/db/"}
REFDBNAME=${REFDBNAME:-"MITI-001"}


LOCAL_DB_PATH="./reference"
mkdir -p ${LOCAL_DB_PATH}/
BOWTIE2_DB=${LOCAL_DB_PATH}/bowtie2_index/${REFDBNAME}


# Copy genome reference over  ${params.db_path}/${params.db}/db/
# Check the reference location

echo "Sync index files from aws s3"
aws s3 sync  ${S3DBPATH}/ ${LOCAL_DB_PATH}/

:<< "TEST"
# if there too many unmapped reads(950M) or too little reads (0.01M)
file_size=$(du -k "${sample}_include_overlap_R1.fastq.gz" | cut -f 1 )
    if [ $file_size -gt 0 ]; then  # && [ $file_size -lt 950000 ]; then
      echo "${sample}_unmapped_include_overlap_R1.fastq.gz exists. Removing the overlapped, discondant and containment pairs from the unmapped bin."
      bowtie2 \
          --very-sensitive \
          -X 3000 \
          -k 200 \
          --threads 8 \
          -x ${BOWTIE2_DB} \
          --end-to-end \
          --no-overlap \
          -1  ${sample}_include_overlap_R1.fastq.gz  \
          -2  ${sample}_include_overlap_R2.fastq.gz  | \
        samtools view \
              -@ 8 \
              -bh \
              -o ${sample}_unmapped_no_overlap.bam -
    fi 

# Ensure both reads in a pair are unmapped.
samtools view -b -f 12 ${sample}_unmapped_no_overlap.bam > ${sample}_unmapped.bam

# Convert bma to fastq files
samtools fastq -f 4 -1 ${sample}_R1.fastq -2 ${sample}_R2.fastq ${sample}_unmapped.bam

TEST

file_size=$(du -k "${sample}_include_overlap_R1.fastq.gz" | cut -f 1 )
    if [ $file_size -gt 0 ]; then  # && [ $file_size -lt 950000 ]; then
      echo "${sample}_unmapped_include_overlap_R1.fastq.gz exists. Removing the overlapped, discondant and containment pairs from the unmapped bin."
      bowtie2 \
          --very-sensitive \
          -X 3000 \
          --threads 8 \
          -x ${BOWTIE2_DB} \
          --end-to-end \
          -1  ${sample}_include_overlap_R1.fastq.gz  \
          -2  ${sample}_include_overlap_R2.fastq.gz  | \
        samtools view \
              -@ 8 \
              -bh \
              -o ${sample}_all.bam -
    fi 

# filter out all perfect alingments including unmapped reads
#($2 != 4) && 
samtools view -h ${sample}_all.bam | awk '($6 !~ /^([0-9]+M)+$/)' | samtools view -b > ${sample}.not_perfect.bam
# get all reads in a pair
samtools fastq -f 1 -1 ${sample}_R1.fastq  -2 ${sample}_R2.fastq  -s ${sample}.singletons.fastq  ${sample}.not_perfect.bam

#gunzip ${sample}_R1.fastq.gz
#gunzip ${sample}_R2.fastq.gz

# filter < 98% aligned
#bamParser_less_than.py -bam bam_files/${sample}.bam -id ${perc} -aln_len 100  -out bam_files/${sample}_${perc}.bam

# get reads in fastq
#samtools fastq -N -@16  bam_files/${sample}_${perc}.bam -0 /dev/null  | gzip > fastq_files/${sample}_${perc}.fastq.gz

# Extract PE reads only
#repair.sh in=fastq_files/${sample}_${perc}.fastq.gz out=${sample}_R1.fastq out2=${sample}_R2.fastq outs=${sample}_singleton.fastq

#R1size=$(du -k "${sample}_R1.fastq.gz" | cut -f 1)
#echo "The Read 1 Size is $R1size kb"


#R1_reads=$(zcat "${sample}_R1.fastq.gz" | echo $((`wc -l`/4)))
R1_reads=$(cat "${sample}_R1.fastq" | echo $((`wc -l`/4)))

if [ "${R1_reads}" -ge "$THRES" ]; then
    # randomly selet 10k reads
    touch ${sample}_stats.tsv 
    echo "${R1_reads}" > ${sample}_reads_stats.tsv 
    reformat.sh samplereadstarget=${THRES} sampleseed=123 fixheaders=t in=${sample}_R1.fastq.gz in2=${sample}_R2.fastq.gz out=${sample}_sampled_R1.fastq out2=${sample}_sampled_R2.fastq    
    # reformat to fasta 
    reformat.sh fixheaders=t in=${sample}_sampled_R1.fastq in2=${sample}_sampled_R2.fastq out=${sample}_PE.fasta 
else
    reformat.sh fixheaders=t in=${sample}_R1.fastq.gz in2=${sample}_R2.fastq.gz out=${sample}_sampled_R1.fastq out2=${sample}_sampled_R2.fastq    
    reformat.sh fixheaders=t in=${sample}_sampled_R1.fastq in2=${sample}_sampled_R2.fastq out=${sample}_PE.fasta 
fi
