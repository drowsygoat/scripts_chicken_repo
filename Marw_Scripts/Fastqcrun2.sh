#!/bin/bash

###This script runs all fastq files in sub-directories of listed input folder###
ml fastqc

# Directory containing your FASTQ files
input_directory="/cfs/klemming/projects/supr/sllstore2017078/original-files/cerebellum_single_cell_reupload/BMK231121-BS902-ZX01-0101/BMK_DATA_20250224154201_1/organized/"
# Directory for output folder
output_directory="/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/test/MULTIQC_FASTQC/NewCHCB"

# Find all FASTQ files in the input directory and its subdirectories
find "$input_directory" -type f \( -iname "*.fastq.gz" -o -iname "*.fq" \) | while read fastq_file; do
    # Check if the file exists (just to be safe)
    if [ -f "$fastq_file" ]; then
        # Skip files related to ID01
        if [[ "$fastq_file" == *"ID01"* ]]; then
            echo "Skipping $fastq_file as it's already done."
            continue  # Skip this file and move to the next
        fi

        echo "Running FastQC on $fastq_file"
        
        # Run FastQC on each file and specify the output directory
        fastqc "$fastq_file" -o "$output_directory"
    else
        echo "No FASTQ files found in $input_directory"
    fi
done
