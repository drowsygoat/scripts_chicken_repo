# Load required libraries
library(dplyr)
library(readr)
library(stringr)
library(tibble)

# Define the base directory where all IDx folders are located
base_dir <- "/cfs/klemming/projects/snic/sllstore2017078/kaczma-workingdir/RR/scAnalysis/single_cell_gal7b/count_arc"

# Find all barcode_metrics.csv files within the IDx folders
metric_files <- list.files(path = base_dir, pattern = "barcode_metrics.csv$", recursive = TRUE, full.names = TRUE)

# Check if files are found
if (length(metric_files) == 0) {
  stop("No 'barcode_metrics.csv' files found in the specified directory.")
}

# Function to read and process each file
read_metrics <- function(file_path) {
  # Extract sample ID from the folder name (IDx)
  sample_id <- str_extract(file_path, "ID\\d+")
  
  # Read the CSV file
  data <- read_csv(file_path, show_col_types = FALSE)
  
  # Add a sample column with the extracted ID
  data <- data %>%
    mutate(sample = sample_id)
  
  return(data)
}

# Read all files and combine into a single tibble
combined_metrics <- metric_files %>%
  lapply(read_metrics) %>%
  bind_rows()

# Display first few rows of the combined data
print(head(combined_metrics))

# Save the combined tibble to a CSV file
output_file <- "combined_barcode_metrics.rds"
saveRDS(combined_metrics, output_file)

cat("Combined metrics saved to:", output_file, "\n")