################################################################################
# MagPie-IBGE Livestock Mapping and Data Integration Script
#
# Author: Marluce da Cruz Scarabello
# Date: December 2024
#
# Description:
# This script processes livestock data from IBGE (1998–2023) and integrates it 
# with a spatial grid for detailed agricultural analysis. The workflow includes 
# cleaning and preprocessing livestock herd data, mapping it to grid cells, and 
# adjusting values based on municipality-to-grid area shares. The resulting dataset 
# can be used directly in MagPie modeling or other spatially explicit analyses.
#
# Workflow:
# 1. Load and preprocess IBGE livestock data.
# 2. Merge cleaned data with grid mapping to allocate values to grid cells.
# 3. Calculate adjusted livestock values using proportional area shares.
# 4. Aggregate data by grid cells and years for analysis.
# 5. Save the final dataset in a CSV format.
#
# Input:
# - mapping_grid_municipio_adjust.csv: Grid mapping with municipality-to-grid shares.
# - PPM_data_livestock_1998_to_2023.rds: Livestock herd data (data from IBGE).
#
# Output:
# - livestock_herd_bovine_1998_2023.csv: Final dataset with grid IDs, years, and 
#   adjusted livestock herd values.

rm(list=ls())

# List of required packages
required_packages <- c("dplyr")

# Identify missing packages
missing_packages <- setdiff(required_packages, installed.packages()[, "Package"])

# Install missing packages
if (length(missing_packages) > 0) {
  message("Installing required packages...")
  install.packages(missing_packages)
} else {
  message("All required packages are already installed.")
}

library(dplyr)

# Define paths
path <- getwd() # Get the current working directory

## Step 1: Load data ------------------------------------------------------
# Load auxiliary files
# Load grid mapping data
grid_mapping <- read.csv(paste0(path, "/data/mapping_grid_municipio_adjust.csv"))

# Load IBGE data
ibge_data <- readRDS(paste0(path, "/example_data/PPM_data_livestock_1998_to_2023.rds")) %>% as.data.frame()

## Step 2: Pre-processing IBGE data ---------------------------------------
# Rename columns for easier interpretation
colnames(ibge_data)
colnames(ibge_data) <- c("cd_nivel_terri", "nm_nivel_terri", "cd_unidmedida", 
                         "nm_unidmedida", "value", "cd_mun", "nm_mun", 
                         "cd_var", "nm_var", "cd_year", "nm_year", "cd_herd", 
                         "nm_herd", "year")

# Filter and clean the data for analysis
cleaned_data <- ibge_data %>%
  select(cd_mun, nm_herd, year, cd_year, value) %>%  # Select relevant columns
  mutate(value = gsub("-", 0, value),           # Substitui "-" por NA
         value = gsub("\\.\\.\\.", 0, value),   # Substitui "..." por NA
         value = as.numeric(value),
         cd_mun = as.integer(cd_mun),  # Convert municipality codes to integers
         nm_herd = as.character(nm_herd))  # Ensure product names are characters

## Step 3:  Merge  ---------------------------------
# Merge cleaned IBGE data with the bovine mapping
mapped_data <- cleaned_data %>% filter(nm_herd == 'Bovino') %>% 
  select(cd_mun, year, cd_year, value)  # Select relevant columns after the merge

# Ensure municipality codes are integers for consistency
mapped_data$cd_mun <- as.integer(mapped_data$cd_mun)

# Merge the mapped data with grid data and calculate final adjusted values
mapped_grid_data <- mapped_data %>%
  left_join(grid_mapping, by = "cd_mun") %>% # Join on municipality code
  mutate(value_final = value * adjusted_share_mun_tocr) # Adjust the value using the share

# Select the final output columns
final_data <- mapped_grid_data %>%
  select(idsbrazil, year, value_final) %>%
  group_by(idsbrazil, year) %>%
  summarise(value_final = sum(value_final, na.rm = TRUE), .groups = "drop")

colnames(final_data) <- c("x.y.iso","t","value")
final_data$x.y.iso <- gsub('[\\"]', '', final_data$x.y.iso)
final_data$x.y.iso <- gsub('[\\"]', '', final_data$x.y.iso)


# Summarize results 
summary <- final_data %>%
  group_by(t) %>%
  summarise(total = sum(value, na.rm = TRUE) / 1e6)  # Summarize in millions

## Save file
write.table(final_data,paste0(path, "/output/livestock_herd_bovine_1998_2023.csv"), row.names = F, sep = ";")
