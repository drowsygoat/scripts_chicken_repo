#!/bin/bash

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME=${1:-bcl2fastq}
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=30
MODULES="bcl2fastq2"
DRY=${2:-no}

if [ "$DRY" != "no" ]; then
    echo "Running in $DRY mode..."
else
    echo "Running in normal mode..."
fi

if [ -d "$JOB_NAME" ]; then
    echo "Error: Directory $JOB_NAME already exists." >&2
    exit 1
else
    mkdir -p "$JOB_NAME"
fi

BCL_DIR="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/basecalls_cb/BMK231121-BS902-ZX01-0101-N1925-L004_bclfiles"

SAMPLE_SHEET_ATAC="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/mkfastq_sample_sheets_cb/atac_lib_bcl2fastq.csv"

SAMPLE_SHEET_GEX="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/mkfastq_sample_sheets_cb/gex_lib_bcl2fastq.csv"

process_file() {
    local input=$1
    local output=$2
    local sample_sheet=$3
    local base_mask=$4

    echo "BCL dir: $input"
    echo "fastq dir: $output"
    echo "Sample sheet: $sample_sheet"
    echo "Base_mask: $base_mask"

    export input output sample_sheet base_mask

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o "$MODULES" --\
    'bcl2fastq --use-bases-mask=${base_mask} \
                --create-fastq-for-index-reads \
                --minimum-trimmed-read-length=8 \
                --mask-short-adapter-reads=8 \
                --ignore-missing-positions \
                --ignore-missing-controls \
                --ignore-missing-filter \
                --ignore-missing-bcls \
                -r 6 -w 6 \
                -R ${input} \
                --output-dir=${output} \
                --sample-sheet=${sample_sheet}
    '
}

cd "$JOB_NAME"
mkdir ATAC_CB_bcl2fastq
process_file $BCL_DIR ATAC_CB_bcl2fastq $SAMPLE_SHEET_ATAC 'Y101,I10,Y24,Y101'

mkdir GEX_CB_bcl2fastq
process_file $BCL_DIR GEX_CB_bcl2fastq $SAMPLE_SHEET_GEX 'Y101,I10,Y24,Y101'