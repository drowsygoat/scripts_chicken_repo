#!/bin/bash

# Load singularity module
ml PDC singularity

# Default base paths
LOCAL_BASE_PATH="/cfs/klemming/projects/supr/sllstore2017078/${USER}-workingdir"
CONTAINER_BASE_PATH="/mnt"
SANDBOXES_PATH="/cfs/klemming/projects/supr/sllstore2017078/${USER}-workingdir/singularity_sandboxes"

# Default Singularity options
SINGULARITY_OPTIONS=""

# Export host PATH to container
export SINGULARITYENV_APPEND_PATH="$PATH"

# Function to display usage
usage() {
    echo "Usage: $0 [-b] [-B <host_path>]... [-c] [-C] <sandbox_name> <command> [args...]"
    echo ""
    echo "Options:"
    echo "  -b          Bind your LOCAL_BASE_PATH to CONTAINER_BASE_PATH inside the container"
    echo "  -B <path>   Additional bind mount(s), can be repeated or comma-separated"
    echo "  -c          Use '--cleanenv' (reset container environment)"
    echo "  -C          Use '--contain' (isolated mount namespace)"
    echo "  -h          Show this help message"
    exit 1
}

# Parse options
USE_CUSTOM_PATHS=false
declare -a CUSTOM_BIND_PATHS
while getopts ":bcCB:h" opt; do
    case ${opt} in
        b)
            USE_CUSTOM_PATHS=true
            ;;
        B)
            CUSTOM_BIND_PATHS+=("$OPTARG")
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
            echo "Invalid option: -$OPTARG"
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

# Require at least sandbox + command
if [ "$#" -lt 2 ]; then
    echo "Error: Missing sandbox name or command."
    usage
fi

# First argument = sandbox name
SANDBOX_NAME="$1"
shift
COMMAND="$@"

# Validate sandbox
if [ ! -d "${SANDBOXES_PATH}/${SANDBOX_NAME}" ]; then
    echo "Error: Sandbox '${SANDBOX_NAME}' not found in '${SANDBOXES_PATH}'"
    exit 1
fi

# Handle additional bind paths (supporting comma-separated entries)
for entry in "${CUSTOM_BIND_PATHS[@]}"; do
    IFS=',' read -ra paths <<< "$entry"
    for path in "${paths[@]}"; do
        if [ -d "$path" ]; then
            SINGULARITY_OPTIONS+=" --bind ${path}:${path}"
        else
            echo "Warning: Skipping bind path '${path}' (not found)"
        fi
    done
done

# Working directory binding
if [ "$USE_CUSTOM_PATHS" = true ]; then
    SINGULARITY_OPTIONS+=" --bind ${LOCAL_BASE_PATH}:${CONTAINER_BASE_PATH}"
    CONTAINER_DIR="${CONTAINER_BASE_PATH}${PWD#$LOCAL_BASE_PATH}"
else
    SINGULARITY_OPTIONS+=" --bind ${PWD}:${PWD}"
    CONTAINER_DIR="${PWD}"
fi

# Log the run
echo "Running: singularity exec ${SINGULARITY_OPTIONS} --pwd ${CONTAINER_DIR} ${SANDBOXES_PATH}/${SANDBOX_NAME} ${COMMAND}"

# Execute
singularity exec ${SINGULARITY_OPTIONS} --pwd "${CONTAINER_DIR}" "${SANDBOXES_PATH}/${SANDBOX_NAME}" ${COMMAND}