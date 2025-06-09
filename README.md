NF-DSQC
====================

This pipeline is based on the results of ninjaMap. It blasts both of the unampped and missed reads on a defined community and retruns the LCA counts.


## A DSQC workflow is [here](workflow.md) 


# MITI Drug Substance QC batch job
### Below is an example seedfile showing the sample name and s3 path in a csv file without headers. 

```
DS001,s3://genomics-workflow-core/Results/Ninjamap/MITI-001/20240223_DS-mNGS_updated
DS003,s3://genomics-workflow-core/Results/Ninjamap/MITI-001/20240223_DS-mNGS_updated
```

### Example 1: The batch submission example using --seedfile option

```{bash}
aws batch submit-job \
    --job-name nf-dsqc \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command="FischbachLab/nf-dsqc, \
"--db","MITI-001v3_20240604", \
"--db_prefix", "MITI-001", \
"--db_path", "s3://maf-versioned/ninjamap/Index", \
"--seedfile", "s3://nextflow-pipelines/nf-DSQC/test/test_seedfile.csv"
"--project","20240223", \
"--outdir","s3://genomics-workflow-core/Results/DSQC/" "
```

### Example 2: The aws batch job parameters can also be configured using the -params-file option. A copy of the params will be automatically saved to a json file (parameters.json) in the run output bucket.
```{bash}
aws batch submit-job \
    --job-name nf-dsqc \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command="fischbachlab/nf-dsqc, \
    "-params-file", "s3://genomics-workflow-core/Results/DSQC/parameters/example_parameters.json" " 
```

#### The structure of the output directory
```
01_preprocess/
02_blast/
03_postprocess/
04_report/
```
### Example output: The QC reports of missed reads and unmapped are saved in the 04_REPORT/missed/ and 04_report/unmapped/, respectively.
```
s3://genomics-workflow-core/Results/DSQC/project_name/04_report/missed/
s3://genomics-workflow-core/Results/DSQC/project_name/04_report/unmapped/
```
Sample BLAST LCA output
```
LCA,Rank,20231116_DS003_B04_REDO,20231128_DS004_C05_REDO
Bacillota,phylum,1,1
Bacteriophage sp.,species,1,1
Bifidobacterium breve,species,0,2
Bifidobacterium longum subsp. longum KACC 91563,strain,0,1
Blautia producta ATCC 27340 = DSM 2950,strain,1,0
Blautia producta,species,62,0
Caudoviricetes sp.,species,7,7
Clostridia,class,0,3
Clostridiaceae bacterium,species,0,1
Faecalitalea cylindroides T2-87,strain,0,1
Lachnospiraceae bacterium,species,2,1
Lachnospiraceae,family,0,1
Oscillospiraceae bacterium D1,species,0,2
root,no rank,1,3
Segatella hominis,species,0,2
Subdoligranulum variabile,species,0,2
uncultured bacterium,species,2,1
uncultured human fecal virus,species,3,4
uncultured organism,species,0,1
unidentified plasmid,species,0,1
Viruses,superkingdom,1,1
```