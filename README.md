NF-DSQC
====================

This pipeline is based on the results of ninjaMap. It blasts both of the unampped and missed reads on a defined community and retruns the LCA counts.

# MITI Drug Substance QC batch job
### Input file paths must be defined using '--seedfile' parameter.
### Below is an example seedfile showing the sample name and s3 path in a csv file without headers. 

```
DS001,s3://genomics-workflow-core/Results/Ninjamap/MITI-001/20240223_DS-mNGS_updated
DS003,s3://genomics-workflow-core/Results/Ninjamap/MITI-001/20240223_DS-mNGS_updated
```

### Example 1: The batch submission example using --seedfile option

```{bash}
aws batch submit-job \
    --job-name nf-DSQC \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command="FischbachLab/nf-DSQC, \
"--seedfile", "s3://nextflow-pipelines/nf-DSQC/test/test_seedfile.csv"
"--project","20240223", \
"--outdir","s3://genomics-workflow-core/Results/DSQC/" "
```

### Example 2: aws batch job parameters can also be configured using the -params-file option. A copy of the params will be automatically saved to a json file (parameters.json) in the run output bucket.
```{bash}
aws batch submit-job \
    --job-name nf-ninjamap-MITI \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command="fischbachlab/nf-ninjamap, \
    "-params-file", "s3://genomics-workflow-core/Results/Ninjamap/parameters/example_parameters.json" " 
```

#### The structure of the output directory
```
01_preprocess/
02_blast/
03_postprocess/
04_report/
```
### Example: The QC report and pdf tree files are saved in the 04_REPORT
```
s3://genomics-workflow-core/Results/DSQC/project_name/04_report/missed/
s3://genomics-workflow-core/Results/DSQC/project_name/04_report/unmapped/

```
