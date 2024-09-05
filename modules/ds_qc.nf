// pre-processing missed reads
process SamplePreprocess_missed {
  tag "${sample}"

  container params.docker_container

  publishDir "${params.outdir}/${params.project}/01_preprocess/missed/${sample}"

  input:
  tuple val(sample), val(path)

  output:
  tuple  val(sample), path("${sample}_PE.fasta"), emit: out_ch1
  tuple  val(sample), path("${sample}_R1.fastq"), path("${sample}_R2.fastq"), emit: out_ch2

  script:
  """
  bash preprocess_missed.sh ${sample} ${path} ${params.bam_perc_identity}
  """
}


// pre-processing unmapped reads
process SamplePreprocess_unmapped {
  tag "${sample}"

  container params.docker_container

  publishDir "${params.outdir}/${params.project}/01_preprocess/unmapped/${sample}"

  input:
  tuple val(sample), val(path)

  output:
  tuple  val(sample), path("${sample}_PE.fasta"), emit: out_ch1
  tuple  val(sample), path("${sample}_sampled_R1.fastq"), path("${sample}_sampled_R2.fastq"), emit: out_ch2

  script:
  """
  bash preprocess_unmapped.sh ${sample} ${path} ${params.unmapped_read_thres}
  """
}

/*  
* NOT USED
* Executes a BLAST job for each sample 
*/
process cat_reads {
    tag "${sample}"

    container params.docker_container

    publishDir "${params.outdir}/${params.project}/01_preprocess/${sample}"

    input:
    tuple val(sample), path(unmapped_R1), path(unmapped_R2), path(missed_R1), path(missed_R2)

    output:
    tuple val(sample), path("${sample}_reads_R1.fastq"), path("${sample}_reads_R2.fastq"), emit: cat_reads_out_ch

    script:
    """
    cat ${unmapped_R1} ${missed_R1} > ${sample}_reads_R1.fastq 
    cat ${unmapped_R2} ${missed_R2} > ${sample}_reads_R1.fastq 
    """

}


/* 
* Executes a BLAST job for each sample 
*/
process BLASTS_missed {
    tag "${sample}"

    container params.docker_container_blast

    publishDir "${params.outdir}/${params.project}/02_blast/missed/", mode: 'copy', pattern: "*.tsv"

    input:
    tuple val(sample), file(fasta_file)

    output:
    tuple val(sample), path ("${sample}.nt.tsv"), emit: BLASTS_out_ch

    script:
    """
    export BLASTDB="/mnt/efs/databases/Blast/nt/db"
    blastn \
      -num_threads $task.cpus \
      -query $fasta_file \
      -db ${params.blast_db} \
      -dbsize 1000000 \
      -num_alignments 100 \
      -perc_identity 98 \
      -evalue 1e-10 \
      -outfmt "6 std qlen slen qcovs sscinames staxids" > ${sample}.nt.tsv
    """
}

/* 
* Executes a BLAST job for each sample 
*/
process BLASTS_unmapped {
    tag "${sample}"

    container params.docker_container_blast

    publishDir "${params.outdir}/${params.project}/02_blast/unmapped/", mode: 'copy', pattern: "*.tsv"

    input:
    tuple val(sample), file(fasta_file)

    output:
    tuple val(sample), path ("${sample}.nt.tsv"), emit: BLASTS_out_ch

    script:
    """
    export BLASTDB="/mnt/efs/databases/Blast/nt/db"
    blastn \
      -num_threads $task.cpus \
      -query $fasta_file \
      -db ${params.blast_db} \
      -dbsize 1000000 \
      -num_alignments 100 \
      -perc_identity 98 \
      -evalue 1e-10 \
      -outfmt "6 std qlen slen qcovs sscinames staxids" > ${sample}.nt.tsv
    """
}



/* 
* Check each pair of reads and perform LCA
*/
process SamplePostprocess_blast_ready {
  tag {sample}

  container params.docker_container_taxonkit

  publishDir "${params.outdir}/${params.project}/03_postprocess/"

  input:
    tuple val(sample), path(blast), path(R1), path(R2)

  output:
    path "${sample}_reads_uniq.tsv", emit: postprocess_out_ch
    path "filtered_PE_lca/${sample}_PE_lca.tsv" 

  script:
  """
  bash -x postprocess.sh ${sample} ${blast} ${R1} ${R2} ${params.blast_perc_identity}
  """
}

/* 
* Check each pair of reads and perform LCA
*/
process SamplePostprocess_unmapped {
  tag {sample}

  container params.docker_container_taxonkit

  publishDir "${params.outdir}/${params.project}/03_postprocess/unmapped/"

  input:
    tuple val(sample), path(blast), path(R1), path(R2)

  output:
    path "${sample}_reads_uniq.tsv", emit: postprocess_out_ch
    path "filtered_PE_lca/${sample}_PE_lca.tsv" 

  script:
  """
  bash -x postprocess.sh ${sample} ${blast} ${R1} ${R2} ${params.blast_perc_identity}
  """
}
/* 
* Check each pair of reads and perform LCA
*/
process SamplePostprocess_missed {
  tag {sample}

  container params.docker_container_taxonkit

  publishDir "${params.outdir}/${params.project}/03_postprocess/missed/"

  input:
    tuple val(sample), path(blast), path(R1), path(R2)

  output:
    path "${sample}_reads_uniq.tsv", emit: postprocess_out_ch
    path "filtered_PE_lca/${sample}_PE_lca.tsv" 

  script:
  """
  bash postprocess.sh ${sample} ${blast} ${R1} ${R2} ${params.blast_perc_identity}
  """
}
/*
Generate final report
${sampleNameList} 
val  sampleNameList 
bash DSQC_report.sh lca_dir ${params.project} "unmapped" 
*/
process Report_unmapped {
  tag "${params.project}"

  container params.docker_container_report

  publishDir "${params.outdir}/${params.project}/04_report/unmapped/", mode: 'copy', pattern: "*.csv"
  publishDir "${params.outdir}/${params.project}/04_report/unmapped/stats", mode: 'copy', pattern: "*.tsv"

  input:
    path "lca_dir/*"
  
  output:
    path "${params.project}_unmapped.csv"
    path "${sample}_reads_stats.tsv", optional: true

  script:
  """
  export R_HOME="/opt/conda/bin/"
  merge_results.R lca_dir "${params.project}_unmapped.csv"
  """
}
/*
  bash DSQC_report.sh lca_dir ${params.project} "missed"
  merge_results.R lca_dir "${params.project}_missed.csv"
 sed -i -e '/^[0-9]*
 /d' "${params.project}_missed.csv"
  sed -i -e '/^,/d' "${params.project}_missed.csv"
*/
process Report_missed {
  tag "${params.project}"

  container params.docker_container_report

  publishDir "${params.outdir}/${params.project}/04_report/missed/"

  input:
    path "lca_dir/*"

  output:
    path "${params.project}_missed.csv"

  script:
  """
  export R_HOME="/opt/conda/bin/"
  merge_results.R lca_dir "${params.project}_missed.csv"
  """
}

