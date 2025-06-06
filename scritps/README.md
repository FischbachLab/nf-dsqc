# How to extract the target reads based on DSQC-LCA-interrogation?

### &bull; The metadata format: a four-colum cvs file without headers
`Sample_name,bin_name,species_name,3_path_to_SQC_results`

```{bash}
20250325_DS078_A03_reseq,unmapped,Clostridium sp. M62/1,s3://genomics-workflow-core/Results/DSQC/20250418_MITI-001_DS-mNGS_HVFW7BGYW_Q30-L50_debug
20250325_DS081_H01_reseq,unmapped,Clostridioides difficile,s3://genomics-workflow-core/Results/DSQC/20250418_MITI-001_DS-mNGS_HVFW7BGYW_Q30-L50_debug
```


### &bull; Make a seedfile based on a metadata file. An example is at `https://docs.google.com/spreadsheets/d/1YavFNFE3vFU511MFFVl3-mNRN84-nPJkL-sDdsP4fMs/edit?gid=0#gid=0`

```{bash}
cat DSQC_reads_metadata.csv | xargs -I {} make_extract_dsqc_reads_seedfile.sh  {}  > DSQC_reads_seedfile.csv
```

### &bull; Extract target reads

```{bash}
bash dsqc_extract_target_reads_LCA.sh DSQC_reads_seedfile.csv
```

### &bull; All the extracted reads in fasta are in the folder `target_reads`
```{bash}
20250325_DS072_C02_reseq_unmapped_Clostridium_botulinum.fasta        
20250325_DS072_C02_reseq_unmapped_Clostridium_botulinum_A3_str__Loch_Maree.fasta 
20250325_DS081_H01_reseq_unmapped_Candidatus_Faecalibacterium_intestinigallinarum.fasta
20250325_DS081_H01_reseq_unmapped_Clostridioides_difficile.fasta
20250325_DS082_A02_reseq_unmapped_Candidatus_Scatomonas_sp_.fasta
20250325_DS082_A02_reseq_unmapped_Clostridiales_bacterium_CCNA10.fasta

```
### &bull; BLAST target reads against MITI-001v3 database  
```{bash}
aws batch submit-job \
    --job-name nf-blast-MITI-001v3 \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command="fischbachlab/nf-blast,\
"--query","s3://genomics-workflow-core/Results/Blast/data/20250325_DS072_C02_reseq_unmapped_Clostridium_botulinum_Prevot_594.fasta",\
"--project","TEST_MITI-001v3",\
"--sample_name","20250325_DS072_C02_reseq_unmapped_Clostridium_botulinum_Prevot_594",\
"--db","MITI-001v3_20240604",\
"--prefix","Test", \
"--outdir","s3://genomics-workflow-core/Results/Blast" "
```

#### &bull; Example BLAST outputs
```{bash}
# BLASTN 2.14.0+
# Query: NS500193_37_HVFW7BGYW_2_11103_23195_11057_1_N_0_GAACGCAATA_ACAGTAAGAT
# Database: /mnt/efs/databases/Blast/MITI-001v3_20240604/MITI-001v3_20240604
# Fields: query acc.ver, subject acc.ver, % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score, query length, subject length, % query coverage per subject
# 2 hits found
NS500193_37_HVFW7BGYW_2_11103_23195_11057_1_N_0_GAACGCAATA_ACAGTAAGAT	C-sporogenes-SH0001903_Node_0	100.000	50	0	0	1	50	2749027	2748978	2.42e-21	93.5	50	3934196	100
NS500193_37_HVFW7BGYW_2_11103_23195_11057_1_N_0_GAACGCAATA_ACAGTAAGAT	C-sporogenes-SH0001791_Node_0	100.000	50	0	0	1	50	2747689	2747640	2.42e-21	93.5	50	3932778	100
# BLASTN 2.14.0+
# Query: NS500193_37_HVFW7BGYW_2_11103_23195_11057_2_N_0_GAACGCAATA_ACAGTAAGAT
# Database: /mnt/efs/databases/Blast/MITI-001v3_20240604/MITI-001v3_20240604
# Fields: query acc.ver, subject acc.ver, % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score, query length, subject length, % query coverage per subject
# 2 hits found
NS500193_37_HVFW7BGYW_2_11103_23195_11057_2_N_0_GAACGCAATA_ACAGTAAGAT	C-sporogenes-SH0001903_Node_0	100.000	78	0	0	1	78	2748961	2749038	1.20e-36	145	78	3934196	100
NS500193_37_HVFW7BGYW_2_11103_23195_11057_2_N_0_GAACGCAATA_ACAGTAAGAT	C-sporogenes-SH0001791_Node_0	100.000	78	0	0	1	78	2747623	2747700	1.20e-36	145	78	3932778	100
# BLAST processed 2 queries
```
