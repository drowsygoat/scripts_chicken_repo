#!/bin/bash

# Load singularity module
ml singularity

# Default local and container base paths
LOCAL_BASE_PATH="/cfs/klemming/projects/snic/sllstore2017078/kaczma-workingdir"
CONTAINER_BASE_PATH="/mnt"
SANDBOXES_PATH="/cfs/klemming/projects/supr/sllstore2017078/kaczma-workingdir/singularity_sandboxes"

# Default Singularity options
SINGULARITY_OPTIONS=""

# Log directory for special cases (e.g., bcl-convert)
LOG_DIR="/cfs/klemming/projects/snic/sllstore2017078/${USER}-workingdir/singularity_logs"

# Function to display usage information
usage() {
    echo "Usage: $0 [-b] [-B <host_path>]... [-c] [-C] <sandbox_name> <command> [options...]"
    echo ""
    echo "Options:"
    echo "  -b  Use custom bind paths for LOCAL_BASE_PATH and CONTAINER_BASE_PATH"
    echo "  -B  Bind additional custom paths (can be used multiple times)"
    echo "  -c  Use the --cleanenv option for Singularity"
    echo "  -C  Use the --contain option for Singularity"
    echo "  -h  Display this help message"
    exit 1
}

# Parse options
USE_CUSTOM_PATHS=false
declare -a CUSTOM_BIND_PATHS
while getopts ":bcCB:hB:" opt; do
    case ${opt} in
        b)
            USE_CUSTOM_PATHS=true
            ;;
        B)
            CUSTOM_BIND_PATHS+=("$OPTARG")  # Store multiple paths in an array
            ;;
        c)
            SINGULARITY_OPTIONS+=" --cleanenv"
            ;;
        C)
            SINGULARITY_OPTIONS+=" --contain"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

# Check if enough arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Error: Missing arguments."
    usage
fi

# Assign first argument to the sandbox name
SANDBOX_NAME=$1
shift

# The remaining arguments are the command and its options
COMMAND="$@"

# Validate that the sandbox exists
if [ ! -d "${SANDBOXES_PATH}/${SANDBOX_NAME}" ]; then
    echo "Error: Sandbox '${SANDBOX_NAME}' not found in '${SANDBOXES_PATH}'"
    exit 1
fi

# Determine the bind path and working directory
if [ "$USE_CUSTOM_PATHS" = true ]; then
    # If -b is used, bind LOCAL_BASE_PATH to CONTAINER_BASE_PATH
    SINGULARITY_OPTIONS+=" --bind ${LOCAL_BASE_PATH}:${CONTAINER_BASE_PATH}"
    CONTAINER_DIR="${CONTAINER_BASE_PATH}${PWD#$LOCAL_BASE_PATH}"
else
    # Default behavior: bind current working directory
    SINGULARITY_OPTIONS+=" --bind ${PWD}:${PWD}"
    CONTAINER_DIR="${PWD}"
fi

# Add multiple custom bind paths if provided
for path in "${CUSTOM_BIND_PATHS[@]}"; do
    if [ -d "$path" ]; then
        SINGULARITY_OPTIONS+=" --bind ${path}:${path}"
    else
        echo "Warning: Skipping bind path '${path}' (not found)."
    fi
done

# Special handling for bcl-convertsingularity build --fakeroot lolcow.sif lolcow.def
if [[ "$COMMAND" == bcl-convert* ]]; then
    # Ensure a writable directory is available for logs
    mkdir -p "$LOG_DIR"

    # Bind the log directory to /var/log/bcl-convert inside the container
    SINGULARITY_OPTIONS+=" --bind ${LOG_DIR}:/var/log/bcl-convert"
fi

# Log the command being run (optional)
echo "Running: singularity exec ${SINGULARITY_OPTIONS} --pwd ${CONTAINER_DIR} ${SANDBOXES_PATH}/${SANDBOX_NAME} ${COMMAND}"

# Run the Singularity command
singularity exec ${SINGULARITY_OPTIONS} --pwd "${CONTAINER_DIR}" "${SANDBOXES_PATH}/${SANDBOX_NAME}" ${COMMAND}
