#!/bin/bash

###This scrip runs a MultiQC on all web_summary.html files in sub-directories of input directory###
# Directory containing your web_summary.html files
input_directory="/cfs/klemming/projects/supr/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/count_arc_cb" 

# Output directory for multiqc results
output_directory="/cfs/klemming/projects/supr/sllstore2017078/marwe445-workingdir/test/MULTIQC_FASTQC/MULTIQC"

# Load the multiqc module
ml multiqc

# Find all web_summary.html files recursively and store them in a variable
web_summary_files=$(find "$input_directory" -type f -name "web_summary.html")

# Check if any web_summary.html files were found
if [ -z "$web_summary_files" ]; then
    echo "No web_summary.html files found in $input_directory"
    exit 1
fi

# Run multiqc on all found web_summary.html files and generate a single report
echo "Running MultiQC on all web_summary.html files"
multiqc $web_summary_files -o "$output_directory"

echo "MultiQC report generated in $output_directory"
