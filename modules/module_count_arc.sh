#!/bin/bash

# run count
# cellranger-arc must me in PATH
# no. of cpus determines memory

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="count_arc"
PARTITION="shared"
NODES=1
TIME="3-10:05:00"
TASKS=1
CPUS=30
DRY="no"

ALL_LIBS="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/libraries/cumulative_libraries.csv"

SAMPLES=($(tail -n +2 "$ALL_LIBS" | awk -F, '{print $2}' | sort | uniq))

REF="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/mkref/bGalGal1_mat_broiler_GRCg7b"

process_file() {

    local sample=$1
    local libraries=$2
    local reference=$3

    export sample libraries reference

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" \
    'cellranger-arc count --id=$sample \
                          --reference=$reference \
                          --libraries=$libraries \
                          --localcores=10 \
                          --localmem=10'
}

#########
# PREPS #
#########

if [ -d "$JOB_NAME" ]; then
    echo "WARNING: Directory $JOB_NAME already exists." >&2
    # exit 1
else
    mkdir -p "$JOB_NAME"
fi
cd "$JOB_NAME"

########
# LOOP #
########

for SAMPLE in "${SAMPLES[@]}"; do

    if [[ ! $SAMPLE =~ ID3$ ]]; then
        continue
    fi

    # Create a CSV file for each SAMPLE
    LIBS="LIBS_${SAMPLE}.csv"

    # Add the header row to the LIBS file
    head -n 1 "$ALL_LIBS" | awk -F, -v OFS=',' '{print $1, $4, $3}' > "$LIBS"

    # Append the rows matching the current SAMPLE to the LIBS file
    awk -F, -v OFS=',' -v SAMPLE="$SAMPLE" '$2 == SAMPLE {print $1, $4, $3}' "$ALL_LIBS" >> "$LIBS"

    echo "Created library file: $LIBS"

    process_file $SAMPLE $LIBS $REF

done




