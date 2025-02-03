# Function to find a unique file based on a pattern in specified directories
function find_module_file() {
    local file_pattern=$1
    local search_dirs=("$@")
    local file
    local found_files
    local files_array

    for dir in "${search_dirs[@]:1}"; do
        # Search for files matching the pattern in the specified directory, non-recursively
        found_files=$(find "$dir" -maxdepth 1 -type f -regex "$file_pattern")

        # Convert search results to an array
        IFS=$'\n' read -r -d '' -a files_array <<< "$found_files"

        # Check if exactly one unique file is found
        if [ "${#files_array[@]}" -eq 1 ]; then
            file="${files_array[0]}"
            echo "$file"
            return 0
        fi
    done

    # If no unique file is found
    echo "Error: No unique $file_pattern file found or multiple files present in the specified directories."
    return 1
}

function get_module_file_path() {
    local file_pattern=".*temp_modules.*"
    local search_dirs=("$PWD" "$HOME")
    local found_files=()

    for dir in "${search_dirs[@]}"; do
        # echo "Searching in directory: $dir"  # Debug: Show which directory is being searched
        
        # Capture the output of the find command
        while IFS= read -r file; do
            # echo "Found file: $file"  # Debug: Show each found file
            found_files+=("$file")
        done < <(find "$dir" -maxdepth 1 -type f -regex "$file_pattern")

        # Check if exactly one unique file is found
        if [ "${#found_files[@]}" -eq 1 ]; then
            echo "${found_files[@]}"
            return 0
        elif [ "${#found_files[@]}" -gt 1 ]; then
            echo "Multiple files found, please refine your search criteria."
            return 1
        fi
    done

    echo "Error: No unique $file_pattern file found or multiple files present in the specified directories." >&2
    return 1
}

function print_job_status() {
    current_status=$(sacct --brief --jobs $JOB_ID | awk -v job_id="$JOB_ID" '$1 == job_id {print $1, $2}')
    if [[ "$last_status" != "$current_status" ]]; then
        echo ""
        echo -n "Monitoring job status for Job ID: $current_status"
        last_status="$current_status"
    else
        echo -n "."
    fi
}


function is_job_active() {
    local active_jobs=$(sacct --jobs $JOB_ID | grep -E "RUNNING|PENDING" | wc -l)
    return $(( active_jobs == 0 ))
}

function is_completed() {
    local completed_jobs=$(sacct --jobs $JOB_ID | grep -E "COMPLETED" | wc -l)
    return $(( completed_jobs == 0 ))
}


function interactive_mode() {
    tput setaf 3
    echo -e "Job ID $JOB_ID submitted at $TIMESTAMP.\nPress 'c' at any time to cancel.\nPress 'q' at any time to stop monitoring.\nCancelling will discard the log files."
    tput sgr 0

    read -t 5 -n 1 input
    if [[ $input = "c" ]]; then
        # User pressed 'c', cancel the job using scancel
        scancel $JOB_ID
        rm -rf ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}
        tput setaf 1
        echo ""
        echo "Operation canceled by the user."
        tput sgr 0
        exit 1
    else
        unset input
    fi

    # Monitor job status until completion
    last_status="init"
    while is_job_active; do
        print_job_status # Poll every -t seconds
        read -t 5 -n 1 -s input
        if [[ $input = "c" ]]; then
            # User pressed 'c', cancel the job using scancel
            scancel $JOB_ID
            rm -rf ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}
            tput setaf 1
            echo ""
            echo "Operation canceled by the user."
            tput sgr 0
            exit 1
        elif [[ $input = "q" ]]; then
            # User pressed 'q', exit with status 0
            tput setaf 1
            echo ""
            echo "Monitoring stopped by the user."
            tput sgr 0
            exit 0
        else
            unset input
        fi
    done

    # Final job status and statistics
    echo ""
    echo "Job $JOB_ID has finished. Fetching final statistics..."
    echo ""

    sacct --format=elapsed,jobname,reqcpus,reqmem,state -j $JOB_ID

    echo ""
    echo "Runtime was $runtimeh hours ($runtimem minutes)."
    echo ""
    echo -e "Job completed.\n"
}


# Function to remove directory if it is empty
function remove_if_empty() {
    local dir=$1

    # Check if directory exists
    if [[ -d "$dir" ]]; then
        # Check if directory is empty
        if [[ -z "$(ls -A "$dir")" ]]; then
            # Remove the directory forcefully
            rmdir "$dir" && echo "Directory '$dir' was empty and has been removed."
        fi
    fi
}

# Function to perform countdown before starting a job
function countdown() {
    local duration=$1

    echo -n "Job will start in "

    # Countdown loop
    for ((i=duration; i>0; i--)); do
        echo -n "$i... "
        read -t 1 -n 1 -s -r response
        if [ $? = 0 ]; then
            # If the user presses a key, exit with a message
            echo -e "\nOperation canceled by the user."
            exit 1
        fi
    done
    echo -e "\nJob is starting now..."
}


# Function to load modules
function load_modules() {
    if [ -n "${MODULES+x}" ]; then
        # Convert comma-separated string to array
        IFS=',' read -ra module_array <<< "$MODULES"
        
        echo "Loading modules from MODULES variable: ${MODULES}"
        for module in "${module_array[@]}"; do
            echo "Loading module: $module"
            module load "$module"
        done
    elif [ -n "${temp_modules+x}" ]; then
        echo "Using modules from ${temp_modules}"
        cat "${temp_modules}"
        source "${temp_modules}"
    fi
}

# Define foreground color variables using tput
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

# Define bright foreground color variables using tput
BRIGHT_BLACK=$(tput setaf 8)  # Often appears as gray
BRIGHT_RED=$(tput setaf 9)
BRIGHT_GREEN=$(tput setaf 10)
BRIGHT_YELLOW=$(tput setaf 11)
BRIGHT_BLUE=$(tput setaf 12)
BRIGHT_MAGENTA=$(tput setaf 13)
BRIGHT_CYAN=$(tput setaf 14)
BRIGHT_WHITE=$(tput setaf 15)

# Define background color variables using tput
BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

# Define bright background color variables using tput
BG_BRIGHT_BLACK=$(tput setab 8)  # Often appears as gray
BG_BRIGHT_RED=$(tput setab 9)
BG_BRIGHT_GREEN=$(tput setab 10)
BG_BRIGHT_YELLOW=$(tput setab 11)
BG_BRIGHT_BLUE=$(tput setab 12)
BG_BRIGHT_MAGENTA=$(tput setab 13)
BG_BRIGHT_CYAN=$(tput setab 14)
BG_BRIGHT_WHITE=$(tput setab 15)

# Reset color
NC=$(tput sgr0)  # No Color