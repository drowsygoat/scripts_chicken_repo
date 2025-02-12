#!/bin/bash

# Script to setup and submit a SLURM job with custom job settings and user input.

source /cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/scripts_chicken_repo/helpers_shell.sh

# User email and compute account settings
COMPUTE_ACCOUNT=${COMPUTE_ACCOUNT}  # Compute account variable

# Capture the current timestamp
# TIMESTAMP=$(TIMESTAMP:-$(date +%Y%m%d_%H%M%S))
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Clear any previous settings for these variables
unset TASKS JOB_TIME PARTITION CPUS NODES MEMORY DRY_RUN

# Default values for job settings  
JOB_NAME="noname_job"
NTASKS=1
NTASKS_PER_NODE=1
PARTITION="shared"
NODES=1
INTERACTIVE=0
CPUS=1
DRY_RUN=0

# Function to display help
function show_help() {
    echo ""
    echo "Usage: run_shell_command.sh [options] -- '[command]'"
    echo ""
    echo "Options:"
    echo "  -J, --job-name         Specify the job name (string)"
    echo "  -n, --ntasks           Set the number of tasks (integer)"
    echo "  -m, --ntasks-per-node  Set the number of tasks per node (integer)"
    echo "  -t, --time             Specify the job time in [D-HH:MM:SS] format"
    echo "  -p, --partition        Partition to run the job on (string)"
    echo "                         Options: core, node, shared, long, main, memory, devel"
    echo "  -N, --nodes            Specify the number of nodes (integer)"
    echo "  -i, --interactive      Run the job in interactive mode (no arguments)"
    echo "  -c, --cpu              Specify the number of CPUs (integer)"
    echo "  -M, --memory           Set the memory allocation for SLURM (e.g., 8G, 32G)"
    echo "  -o, --modules          List of modules to load (comma-separated, e.g., 'python,gcc')"
    echo "  -a, --array            Define job array specification (e.g., '1-10%2')"
    echo "  -d, --dry-run          Enable dry run mode"
    echo "                         Options: dry, with_eval, no"
    echo "  -h, --help             Display this help message and exit"
    echo ""
    echo "Notes:"
    echo "  - The '[command]' should be enclosed in quotes and placed after '--'."
    echo "  - Dry run options:"
    echo "      dry       : Prints the command without executing it."
    echo "      with_eval : Prints and evaluates the command."
    echo "      no        : Executes the command without printing."
    echo ""
    exit 0
}

if [ $# -eq 0 ]; then
    echo "No arguments provided. Displaying help:"
    # Call a function to display help
    show_help
    exit 1
fi

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -J|--job-name)
            JOB_NAME="$2"
            shift 2
            ;;
        -n|--ntasks)
            NTASKS="$2"
            shift 2
            ;;
        -m|--ntasks-per-node)
            NTASKS_PER_NODE="$2"
            shift 2
            ;;
        -t|--time)
            JOB_TIME="$2"
            shift 2
            ;;
        -p|--partition)
            PARTITION="$2"
            shift 2
            ;;
        -N|--nodes)
            NODES="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=1
            shift
            ;;
        -c|--cpu)
            CPUS="$2"
            shift 2
            ;;
        -M|--memory)
            MEMORY="$2"
            shift 2
            ;;
        -o|--modules)
            MODULES="$2"
            shift 2
            ;;
        -a|--array)
            JOB_ARRAY="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Invalid option: $1" 1>&2
            show_help
            ;;
    esac
done

# Display parsed options (for debugging purposes)
# echo "Job Name: $JOB_NAME"
# echo "Number of Tasks: $NTASKS"
# echo "Tasks per Node: $NTASKS_PER_NODE"
# echo "Job Time: $JOB_TIME"
# echo "Partition: $PARTITION"
# echo "Nodes: $NODES"
# echo "Interactive Mode: $INTERACTIVE"
# echo "CPUs: $CPUS"
# echo "Memory: $MEMORY"
# echo "Modules: $MODULES"
# echo "Job Array: $JOB_ARRAY"
# echo "Dry Run: $DRY_RUN"

# Example of using parsed options (modify as needed)
if [[ $DRY_RUN -eq 1 ]]; then
    echo "Dry run mode enabled. No actual job submission will occur."
fi

# Remaining arguments are treated as the command to run
ARGUMENTS="$@"

# Set the job name to the first argument if not explicitly set
JOB_NAME=${JOB_NAME:-$(echo $ARGUMENTS | awk '{print $1}')}

# Set default job time based on the partition
if [[ $PARTITION =~ (core|node|shared|long|main|memory|devel) ]]; then
    JOB_TIME=${JOB_TIME:-23:59:00}
else 
    JOB_TIME=${JOB_TIME:-00:10:00} 
fi

# Color settings for output using tput
color_key=$CYAN   # Blue color for keys
color_value=$RED  # Green color for values
color_reset=$NC   # Reset to default terminal color

# Display settings
# echo -e "Here are the current settings:"
echo -e "${color_key}Job name: ${color_value}$JOB_NAME${color_reset}"
echo -e "${color_key}Number of tasks: ${color_value}$NTASKS${color_reset}"
echo -e "${color_key}Number of cpus: ${color_value}$CPUS${color_reset}"
echo -e "${color_key}Number of nodes: ${color_value}$NODES${color_reset}"
echo -e "${color_key}Job time: ${color_value}$JOB_TIME${color_reset}"
echo -e "${color_key}Partition: ${color_value}$PARTITION${color_reset}"
echo -e "${color_key}E-mail: ${color_value}$USER_E_MAIL${color_reset}"
echo -e "${color_key}Account: ${color_value}$COMPUTE_ACCOUNT${color_reset}"

if [ -n "${DRY_RUN:-}" ]; then
    echo -e "${color_key}Dry run: ${color_value}Yes${color_reset}"
else
    echo -e "${color_key}Dry run: ${color_value}No${color_reset}"
fi

if [ -n "${MEMORY:-}" ]; then
    echo -e "${color_key}Memory allocation: ${color_value}$MEMORY${color_reset}"
else
    echo -e "${color_key}Memory allocation: ${color_value}Not specified${color_reset}"
fi

if [ -n "${JOB_ARRAY:-}" ]; then
    echo -e "${color_key}Job array: ${color_value}$JOB_ARRAY${color_reset}"
else
    echo -e "${color_key}Job array: ${color_value}Not specified${color_reset}"
fi

if [ -n "${NTASKS_PER_NODE:-}" ]; then
    echo -e "${color_key}Tasks per node: ${color_value}$NTASKS_PER_NODE${color_reset}"
else
    echo -e "${color_key}Tasks per node: ${color_value}Not specified${color_reset}"
fi


SBATCH_SCRIPT="${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}/${JOB_NAME}_${TIMESTAMP}.sh"

# Create the SLURM job script with the specified parameters
if [[ $DRY_RUN == "dry" ]]; then
  echo -e "Command to evaluate:" 
  echo -e "$ARGUMENTS" 
  exit 0
elif [[ $DRY_RUN == "with_eval" ]]; then
  echo -e "\nEvaluating: $ARGUMENTS" 
  echo -e "Loading modules"
  load_modules
  echo "Check... OK"
  eval "$ARGUMENTS"
  echo -e "Finished."
  exit 0
fi

# Prepare the directory and SLURM script for the job
mkdir -p ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}

# creating script file
cat <<EOF > "$SBATCH_SCRIPT"
#!/bin/bash -eu
#SBATCH -A ${COMPUTE_ACCOUNT}
#SBATCH -J ${JOB_NAME}
#SBATCH -o ${SLURM_HISTORY}/%x_${TIMESTAMP}/%x_%j_${TIMESTAMP}.out
#SBATCH -t ${JOB_TIME}
#SBATCH -p ${PARTITION}
#SBATCH -n ${NTASKS}
#SBATCH -N ${NODES}
#SBATCH -c ${CPUS}
#SBATCH --mail-user=${USER_E_MAIL:-lecka@liu.se}
#SBATCH --mail-type=BEGIN
EOF

if [ -n "${MEMORY:-}" ]; then
  echo "#SBATCH --mem ${MEMORY}" >> "$SBATCH_SCRIPT"
fi

if [ -n "${JOB_ARRAY:-}" ]; then
  echo "#SBATCH -array ${JOB_ARRAY}" >> "$SBATCH_SCRIPT"
fi

if [ -n "${NTASKS_PER_NODE:-}" ]; then
  echo "#SBATCH --ntasks-per-node ${NTASKS_PER_NODE}" >> "$SBATCH_SCRIPT"
fi

cat <<EOF >> "$SBATCH_SCRIPT"
load_modules
echo "Job \${SLURM_JOB_ID} for job name \${JOB_NAME} is running..."
start=\$(date +%s)
eval "\$ARGUMENTS"
echo "Job \${SLURM_JOB_ID} for job name \${JOB_NAME} finished."
end=\$(date +%s)
runtime=\$((end-start))
echo "Runtime: \$((runtime/3600)) hours and \$(((runtime%3600)/60)) minutes."
EOF

# Log the expanded command
expanded_command=$(eval echo "$ARGUMENTS")
# echo -e "\nRunning:"
echo ${BRIGHT_MAGENTA}
echo -e "$expanded_command" | tee "${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}/command.log"
echo ${NC}

if [[ $INTERACTIVE == 1 ]]; then
  countdown 3
fi

# Find a module file either in $HOME or the current working directory
temp_modules="$(get_module_file_path)"

# Check if the function was successful and the variable is not empty
if [ -n "$temp_modules" ]; then
    echo "temp_modules is set to: $temp_modules"
    export temp_modules
else
    echo "No valid module file found or get_module_file_path encountered an issue."
fi

# Check if the MODULES variable is set and export it
if [ -n "$MODULES" ]; then
    echo $MODULES
    export MODULES
fi

# Export other variables
export ARGUMENTS SLURM_JOB_ID JOB_NAME

# Export functions
export -f load_modules

echo -e "Script to run:\n $SBATCH_SCRIPT"
chmod +x "$SBATCH_SCRIPT"

JOB_ID=$(sbatch --parsable "$SBATCH_SCRIPT")

if [ -z "$JOB_ID" ]; then
    echo "Failed to submit job. Please check the SLURM script for errors."
    exit 1
fi

if [[ $INTERACTIVE == 1 ]]; then
  interactive_mode
fi

remove_if_empty "${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}"
