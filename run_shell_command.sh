#!/bin/bash

# Script to setup and submit a SLURM job with custom job settings and user input.

source /cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/SmoothR/inst/shell_helpers/helpers_shell.sh

# User email and compute account settings
COMPUTE_ACCOUNT=${COMPUTE_ACCOUNT}  # Compute account variable

# Capture the current timestamp
# TIMESTAMP=$(TIMESTAMP:-$(date +%Y%m%d_%H%M%S))
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Clear any previous settings for these variables
unset TASKS JOB_TIME PARTITION CPUS NODES MEMORY DRY_RUN

# Default values for job settings

NODES="1"
CPUS="1"
NTASKS="1" 
PARTITION="shared"
INTERACTIVE=0

function display_help() {
    echo "Usage: $(basename $0) [options] -- [command]"
    echo "Options:"
    echo "  -J [job_name]"
    echo "  -n [num_threads]"
    echo "  -t [job_time]"
    echo "  -p [core|node|shared|long|main|memory|devel]"
    echo "  -h"
    echo "  -d [no|dry|with_eval]"
}

# Add this at the beginning of your getopts loop
if [ $# -eq 0 ]; then
    echo "No arguments provided. Displaying help:"
    # Call a function to display help
    display_help
    exit 1
fi

# Parse command-line options using getopts
while getopts "J:n:t:p:N:m:a:ic:d:o:" opt; do
  case ${opt} in
    J )
      JOB_NAME=${OPTARG} 
      ;;
    n )
      NTASKS=${OPTARG}  
      ;;
    m )
      NTASKS_PER_NODE=${OPTARG}  
      ;;
    t )
      JOB_TIME=${OPTARG}  
      ;;
    p )
      PARTITION=${OPTARG}  
      ;;
    N )
      NODES=${OPTARG}  
      ;;
    i )
      INTERACTIVE=1  
      ;;
    c )
      CPUS=${OPTARG}
      ;;
    m )
      MEMORY=${OPTARG}  
      ;;
    o )
      MODULES=${OPTARG}  
      ;;
    a )
      JOB_ARRAY=${OPTARG}  
      ;;
    d )
      DRY_RUN=${OPTARG}  
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done

# Shift off the options and optional --
shift $((OPTIND -1))

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
color_value=$RED # Green color for values
color_reset=$NC    # Reset to default terminal color

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
if [[ ! -n "${DRY_RUN:-}" ]]; then
    echo -e "${color_key}Dry run: ${color_value}No${color_reset}"
else
    echo -e "${color_key}Dry run: ${color_value}$DRY_RUN${color_reset}"
fi


SBATCH_SCRIPT="${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}/${JOB_NAME}_${TIMESTAMP}.sh"

# Create the SLURM job script with the specified parameters
if [[ $DRY_RUN == "dry" ]]; then
  echo -e "Command to evaluate:" 
  echo -e "$ARGUMENTS" 
  exit 0
elif [[ $DRY_RUN == "with_eval" ]]; then
  echo -e "Evaluating:" 
  echo -e "$ARGUMENTS"
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





# echo -e "\nRunning:"
echo ${BRIGHT_MAGENTA}
echo -e "$ARGUMENTS" | tee ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}/command.log
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



# echo -e "\033[?1000l"