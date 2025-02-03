#!/bin/bash

# script very much in progress
# run count
# cellranger-arc must me in PATH
# no. of cpus determines memory

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="hello"
PARTITION="main"
NODES=1
TIME="23:05:00"
TASKS=2
CPUS=10
DRY="no"
JOB_ARRAY=""

process_file() {

    local samples=("${!1}")  # Array of samples for this batch
    local batch_number=$2     # Batch number (for job name differentiation)
    local samples_str=$(printf "%s " "${samples[@]}")

    export samples_str

    JOB_ARRAY="1-${#samples[@]}"

    $RUN_COMMAND -J "${JOB_NAME}_batch${batch_number}" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -a "$JOB_ARRAY" \
    'samples=($samples_str); \
     echo "Task ID: $((SLURM_ARRAY_TASK_ID-1))"; \
     echo "Sample: ${samples[((SLURM_ARRAY_TASK_ID-1))]}"'
}


SAMPLES=({1..10})

batch_number=1

for ((i = 0; i < ${#SAMPLES[@]}; i+=10)); do
    batch_samples=("${SAMPLES[@]:i:10}")  # Get the next 10 samples
    echo "Processing batch $batch_number with samples: ${batch_samples[*]}"
    
    # Call the process_file function with the current batch by passing the array name
    process_file batch_samples[@] $batch_number
    
    # Increment the batch number
    ((batch_number++))
done
