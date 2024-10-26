#!/usr/bin/env Rscript

library(tidyverse)

# how to run the script
# Rscript merge_blast_counts.R input_dir report_name

args <- commandArgs(trailingOnly = TRUE)

folder_path <-  args[1] 
output_file <-  args[2] 

files <- list.files(path = folder_path, pattern = "\\_reads_uniq.tsv$", full.names = TRUE)

# reads all files
dataframes <- lapply(files, function(file) read_tsv(file, col_names = TRUE)) # FALSE))

# merge the data frames
merged_df <- Reduce(function(x, y) merge(x, y, by.x = 1, by.y = 1,  all= TRUE), dataframes)

# Replace NA values with 0
merged_df[is.na(merged_df)] <- 0  # Replace NA values with 0

# Add headers
#colnames(merged_df) <- c("Reference Name") #, "DS003", "DS004", "DS005", "DS006", "DS007", "DS008", "DS009", "DS010" ) 

merged_df <- separate(merged_df, col="LCA", into=c('LCA', 'Rank'), sep=';')

#merged_df <- separate(merged_df, col=X1, into=c('LCA', 'Rank'), sep=';')

head(merged_df)

# print the merged file
write_csv(merged_df, output_file)