#!/usr/bin/env bash -x

set -e
set -u
set -o pipefail

#mkdir unmapped_files
#mkdir fastq_files

sample=${1}
S3INPUTPATH=${2}
THRES=${3}


aws s3 cp ${S3INPUTPATH}/${sample}/bowtie2/${sample}_unmapped_R1.fastq.gz  ${sample}_R1.fastq.gz 
aws s3 cp ${S3INPUTPATH}/${sample}/bowtie2/${sample}_unmapped_R2.fastq.gz  ${sample}_R2.fastq.gz 


echo "${sample}"

#gunzip ${sample}_R1.fastq.gz
#gunzip ${sample}_R2.fastq.gz

# filter < 98% aligned
#bamParser_less_than.py -bam bam_files/${sample}.bam -id ${perc} -aln_len 100  -out bam_files/${sample}_${perc}.bam

# get reads in fastq
#samtools fastq -N -@16  bam_files/${sample}_${perc}.bam -0 /dev/null  | gzip > fastq_files/${sample}_${perc}.fastq.gz

# Extract PE reads only
#repair.sh in=fastq_files/${sample}_${perc}.fastq.gz out=${sample}_R1.fastq out2=${sample}_R2.fastq outs=${sample}_singleton.fastq


R1_reads=$(zcat "${sample}_R1.fastq.gz" | echo $((`wc -l`/4)))

#R1size=$(du -k "${sample}_R1.fastq.gz" | cut -f 1)
#echo "The Read 1 Size is $R1size kb"

if [ "${R1_reads}" -ge "$THRES" ]; then
    # randomly selet 10000 reads
    touch ${sample}_stats.tsv 
    echo "${R1_reads}" > ${sample}_reads_stats.tsv 
    reformat.sh samplereadstarget=10000 sampleseed=123 fixheaders=t in=${sample}_R1.fastq.gz in2=${sample}_R2.fastq.gz out=${sample}_sampled_R1.fastq out2=${sample}_sampled_R2.fastq    
    # reformat to fasta 
    reformat.sh fixheaders=t in=${sample}_sampled_R1.fastq in2=${sample}_sampled_R2.fastq out=${sample}_PE.fasta 
else
    reformat.sh fixheaders=t in=${sample}_R1.fastq.gz in2=${sample}_R2.fastq.gz out=${sample}_sampled_R1.fastq out2=${sample}_sampled_R2.fastq    
    reformat.sh fixheaders=t in=${sample}_sampled_R1.fastq in2=${sample}_sampled_R2.fastq out=${sample}_PE.fasta 
fi
