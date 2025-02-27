#!/bin/bash

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME=${1:-bcl_convert}
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=30
MODULES="PDC singularity"
DRY=${2:-with_eval}

if [ "$DRY" != "no" ]; then
    echo "Running in $DRY mode..."
else
    echo "Running in normal mode..."
fi

# if [ -d "$JOB_NAME" ]; then
#     echo "Error: Directory $JOB_NAME already exists." >&2
#     exit 1
# else
#     mkdir -p "$JOB_NAME"
# fi

BCL_DIR="/cfs/klemming/projects/snic/sllstore2017078/kaczma-workingdir/RR/scAnalysis/single_cell_gal7b/basecalls_cb/BMK231121-BS902-ZX01-0101-N1925-L004_bclfiles"

SAMPLE_SHEET_ATAC="/cfs/klemming/projects/snic/sllstore2017078/kaczma-workingdir/RR/scAnalysis/single_cell_gal7b/mkfastq_sample_sheets_cb/ATACSS.csv"

# SAMPLE_SHEET_GEX="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/mkfastq_sample_sheets_cb/gex_lib_bcl2fastq.csv"

process_file() {
    local input=$1
    local output=$2
    local sample_sheet=$3

    echo "BCL dir: $input"
    echo "fastq dir: $output"
    echo "Sample sheet: $sample_sheet"

    export input output sample_sheet
    echo "INPUT: $input"


    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o "$MODULES" -- \
    'sing_v2.sh bioinfo_toolkit bcl-convert \
                    --bcl-input-directory ${input} \
                    --output-directory ${output} \
                    --sample-sheet ${sample_sheet} \
                    --bcl-validate-sample-sheet-only true
    '
}

process_file $BCL_DIR "$JOB_NAME" $SAMPLE_SHEET_ATAC 
