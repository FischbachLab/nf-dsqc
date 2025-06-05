# How to extract the target reads based on DSQC-LCA-interrogation?

## metadata format: a four-colum cvs file without headers
```{bash}
20250325_DS078_A03_reseq,unmapped,Clostridium sp. M62/1,s3://genomics-workflow-core/Results/DSQC/20250418_MITI-001_DS-mNGS_HVFW7BGYW_Q30-L50_debug
20250325_DS081_H01_reseq,unmapped,Clostridioides difficile,s3://genomics-workflow-core/Results/DSQC/20250418_MITI-001_DS-mNGS_HVFW7BGYW_Q30-L50_debug
```


## make a seedfile based on a metadata file at `https://docs.google.com/spreadsheets/d/1YavFNFE3vFU511MFFVl3-mNRN84-nPJkL-sDdsP4fMs/edit?gid=0#gid=0`

```{bash}
cat DSQC_reads_metadata.csv | xargs -I {} make_extract_dsqc_reads_seedfile.sh  {}  > DSQC_reads_seedfile.csv
```

## Extract target reads

```{bash}
dsqc_extract_target_reads_LCA.sh DSQC_reads_seedfile.csv
```

## All the extracted reads in fasta are in folder target_reads
```{bash}
20250325_DS072_C02_reseq_unmapped_Clostridium_botulinum.fasta        
20250325_DS072_C02_reseq_unmapped_Clostridium_botulinum_A3_str__Loch_Maree.fasta 
20250325_DS081_H01_reseq_unmapped_Candidatus_Faecalibacterium_intestinigallinarum.fasta
20250325_DS081_H01_reseq_unmapped_Clostridioides_difficile.fasta
20250325_DS082_A02_reseq_unmapped_Candidatus_Scatomonas_sp_.fasta
20250325_DS082_A02_reseq_unmapped_Clostridiales_bacterium_CCNA10.fasta
```
