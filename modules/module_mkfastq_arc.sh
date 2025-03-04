#!/bin/bash

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME=${1:-mkfastq}
PARTITION="main"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
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

SAMPLE_SHEET_ATAC="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/mkfastq_sample_sheets_cb/atac_cb.csv"

SAMPLE_SHEET_GEX="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/mkfastq_sample_sheets_cb/gex_cb.csv"

process_file() {
    local input=$1
    local sample_sheet=$2

    echo "BCL folder: $input"
    echo "Sample sheet: $sample_sheet"

    export input sample_sheet

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" \
    'cellranger-arc mkfastq --run=$input \
                            --csv=$sample_sheet
    '
}

cd "$JOB_NAME"

mkdir ATAC
cd ATAC
process_file $BCL_DIR $SAMPLE_SHEET_ATAC

mkdir GEX
cd GEX
process_file $BCL_DIR $SAMPLE_SHEET_GEX