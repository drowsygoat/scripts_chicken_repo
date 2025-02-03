#!/bin/bash

# Check if the required arguments are provided
if [ $# -lt 6 ]; then
    echo "Usage: $0 -c <chromosome> -s <start> -e <end>"
    exit 1
fi

# Parse command line arguments
while getopts "c:s:e:" opt; do
    case $opt in
        c) chromosome="$OPTARG"
        ;;
        s) start="$OPTARG"
        ;;
        e) end="$OPTARG"
        ;;
        *) echo "Invalid option: -$OPTARG" >&2
           echo "Usage: $0 -c <chromosome> -s <start> -e <end>"
           exit 1
        ;;
    esac
done

# Check if input is coming from stdin
if [ -t 0 ]; then
    echo "Error: No input provided. Please pipe a FASTQ file to the script." >&2
    exit 1
fi

# AWK script to extract sequence based on specified positions
awk -v chr="$chromosome" -v start="$start" -v end="$end" '
    BEGIN { 
        in_region = 0 
    }

    # Process header lines to check for the correct chromosome
    /^>/ {
        # If already in the correct region, stop processing further
        if (in_region) {
            exit
        }

        # Extract chromosome from the header
        split($0, fields, " ")
        current_chr = substr(fields[1], 2)

        # Set in_region flag if on the correct chromosome
        if (current_chr == chr) {
            in_region = 1
            sequence = ""  # Initialize sequence buffer
        }
    }

    # Accumulate sequence data if within the desired chromosome
    in_region && /^[^>]/ {
        sequence = sequence $0
    }

    # Extract and print the sequence once the region is complete
    END {
        if (in_region) {
            extracted_sequence = substr(sequence, start, end - start + 1)
            print extracted_sequence
            exit 0
        }
    }
'
