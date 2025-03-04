#!/bin/bash
#Script takes all barcode_metric.csv files, labels them with ID & combines them into one giant csv
# Define the main directory path
main_dir="/cfs/klemming/projects/supr/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/count_arc_cb"

# Output file name
output_file="/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/R/Rworkdir/CB/combined_per_barcode_metrics.csv"

# Initialize a variable to track if the combined file already has a header
header_written=false

# Loop through subdirectories ID01 to ID20 (you can modify this range as needed)
for i in {01..20}; do
    # Format subdirectory name (ID01, ID02, ..., ID20)
    sub_dir="${main_dir}/ID${i}"
    
    # Debugging: Show which subdirectory is being processed
    echo "Processing $sub_dir"

    # Check if the subdirectory exists
    if [ -d "$sub_dir" ]; then
        # Path to the per_barcode_metrics.csv file inside the 'outs' folder
        file_path="${sub_dir}/outs/per_barcode_metrics.csv"
        
        # Debugging: Show file path
        echo "Looking for file at $file_path"

        # Check if the file exists
        if [ -f "$file_path" ]; then
            # Add a Sample_ID column with the current subdirectory ID (e.g., ID01)
            if [ "$header_written" = false ]; then
                # Add Sample_ID column and copy the first file with header to the output file
                awk -v sample_id="ID${i}" 'BEGIN {FS=OFS=","} {print sample_id, $0}' "$file_path" > "$output_file"
                header_written=true
                echo "Header written from $file_path with Sample_ID"
            else
                # Append data excluding the header from subsequent files and add the Sample_ID column
                awk -v sample_id="ID${i}" 'BEGIN {FS=OFS=","} NR > 1 {print sample_id, $0}' "$file_path" >> "$output_file"
                echo "Appended data from $file_path with Sample_ID"
            fi
        else
            echo "File per_barcode_metrics.csv not found in $file_path"
        fi
    else
        echo "Sub-directory $sub_dir not found"
    fi
done

# Final message
echo "Combined CSV saved to $output_file"
