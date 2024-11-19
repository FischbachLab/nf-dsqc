#!/usr/bin/env bash -x

set -e
set -u
set -o pipefail

mkdir -p bam_files
mkdir -p fastq_files
mkdir -p votes

sample=${1}
S3INPUTPATH=${2}
perc=${3}
THRES=${4}

# get bam file
aws s3 cp ${S3INPUTPATH}/${sample}/bowtie2/${sample}.sortedByCoord.bam  bam_files/${sample}.bam 
aws s3 cp ${S3INPUTPATH}/${sample}/bowtie2/${sample}.sortedByCoord.bam.bai  bam_files/${sample}.bam.bai

# get vote file
aws s3 cp  ${S3INPUTPATH}/${sample}/ninjaMap/${sample}.ninjaMap.votes.csv.gz votes/${sample}.votes.csv.gz


echo "${sample}"

# get headers for all voted reads (perfect reads)
zcat votes/${sample}.votes.csv.gz | awk  -F',' '{if($6=="False" && $7=="True") print $1}' | cut -f1 -d"_" | sort | uniq > ${sample}_headers.txt

# update headers
sed -i 's/$/\/1/'  ${sample}_headers.txt

# filter < 98% aligned
bamParser_less_than.py -bam bam_files/${sample}.bam -id ${perc} -aln_len 100  -out bam_files/${sample}_${perc}.bam

# get reads in fastq
samtools fastq -N -@16  bam_files/${sample}_${perc}.bam -0 /dev/null  | gzip > fastq_files/${sample}_${perc}.fastq.gz

# Extract PE reads only 
repair.sh in=fastq_files/${sample}_${perc}.fastq.gz out=fastq_files/${sample}_missed_R1.fastq out2=fastq_files/${sample}_missed_R2.fastq outs=fastq_files/${sample}_missed_singleton.fastq

# get all missed reads using the header file
filterbyname.sh -Xmx14g in=fastq_files/${sample}_missed_R1.fastq in2=fastq_files/${sample}_missed_R2.fastq out=${sample}_R1.fastq out2=${sample}_R2.fastq names=${sample}_headers.txt include=f ow=t

R1_reads=$(cat "${sample}_R1.fastq" | echo $((`wc -l`/4)))

if [ "${R1_reads}" -ge "$THRES" ]; then
    # randomly selet 10000 reads
    touch ${sample}_stats.tsv 
    echo "${R1_reads}" > ${sample}_reads_stats.tsv 
    reformat.sh samplereadstarget=${THRES} sampleseed=123 fixheaders=t in=${sample}_R1.fastq in2=${sample}_R2.fastq out=${sample}_sampled_R1.fastq out2=${sample}_sampled_R2.fastq
else
    reformat.sh fixheaders=t in=${sample}_R1.fastq in2=${sample}_R2.fastq out=${sample}_sampled_R1.fastq out2=${sample}_sampled_R2.fastq 
fi

# reformat to fasta
reformat.sh fixheaders=t in=${sample}_sampled_R1.fastq in2=${sample}_sampled_R2.fastq out=${sample}_PE.fasta 
