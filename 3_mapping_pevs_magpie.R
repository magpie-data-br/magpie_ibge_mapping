################################################################################
# MagPie-IBGE Forestry Mapping and Data Integration Script
#
# Author: Marluce da Cruz Scarabello
# Date: December 2024
#
# Description:
# This script processes forestry data from IBGE (1998–2023) and 
# integrates it with a spatial grid for detailed agricultural and environmental analysis. 
# The workflow includes cleaning and preprocessing data, mapping it to grid cells, 
# and adjusting values based on municipality-to-grid area shares. The resulting 
# dataset can be used directly in MagPie modeling or other spatially explicit analyses.
#
# Workflow:
# 1. Load and preprocess forestry data from IBGE.
# 2. Merge cleaned data with spatial grid mapping to allocate values to grid cells.
# 3. Apply conversion factors for specific forestry products.
# 4. Calculate adjusted values based on municipality-to-grid area shares.
# 5. Add new aggregated product categories (e.g., "timber").
# 6. Save the final processed dataset for downstream analysis.
#
# Input:
# - mapping_grid_municipio_adjust.csv: Grid mapping with municipality-to-grid shares.
# - PEVS_data_production_1998_to_2023.rds: Forestry production data from IBGE.
#
# Output:
# - forestry_products_1998_2023.csv: Final dataset with grid IDs, years, and 
#   adjusted forestry product values.
################################################################################

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

# Define paths
path <- getwd() # Get the current working directory

## Step 1: Load data ------------------------------------------------------
# Load auxiliary files
# Load grid mapping data
grid_mapping <- read.csv(paste0(path, "/data/mapping_grid_municipio_adjust.csv"))

# Load IBGE data
ibge_data <- readRDS(paste0(path, "/example_data/PEVS_data_production_1998_to_2023.rds")) %>% as.data.frame()

## Step 2: Pre-processing IBGE data ---------------------------------------
# Rename columns for easier interpretation
colnames(ibge_data)
colnames(ibge_data) <- c("cd_nivel_terri", "nm_nivel_terri", "cd_unidmedida", 
                         "nm_unidmedida", "value", "cd_mun", "nm_mun", 
                         "cd_var", "nm_var", "cd_year", "nm_year", "cd_prod", 
                         "nm_prod", "year")

# Filter and clean the data for analysis
cleaned_data <- ibge_data %>%
  select(cd_mun, nm_prod, nm_unidmedida, year, cd_year, value) %>%  # Select relevant columns
  mutate(value = gsub("-", 0, value),           # Replace "-" with 0
         value = gsub("\\.\\.\\.", 0, value),    # Replace "..." with 0
         value = as.numeric(value),
         cd_mun = as.integer(cd_mun),  # Convert municipality codes to integers
         nm_prod = as.character(nm_prod))  # Ensure product names are characters

## Step 3: Filter and add conversion factors ------------------------------

# Filter for relevant forestry products and add conversion factors
## Tonnes to m3: 2.06
## M3 to drymatter : 350
selected_data <- cleaned_data %>% filter(nm_prod %in% c("1.1 - Carvão vegetal","1.2 - Lenha","1.3 - Madeira em tora")) %>% 
  select(cd_mun,nm_prod,nm_unidmedida, year, cd_year, value) %>%
  mutate(MagPie_Prods = case_when(
    nm_prod == "1.1 - Carvão vegetal" ~ "woodfuel",
    nm_prod == "1.2 - Lenha" ~ "woodfuel",
    nm_prod == "1.3 - Madeira em tora" ~ "wood",
    TRUE ~ NA_character_  # NA
  ),
    conv_factor = case_when(
    nm_prod == "1.1 - Carvão vegetal" ~ 721,
    nm_prod == "1.2 - Lenha" ~ 350,
    nm_prod == "1.3 - Madeira em tora" ~ 350,
    TRUE ~ NA_real_  # NA
  ),
  drymatter_values = value * conv_factor )  # Calculate dry matter values


## Step 4: Merge with grid mapping and adjust values ----------------------
# Ensure municipality codes are integers for consistency
selected_data$cd_mun <- as.integer(selected_data$cd_mun)

# Merge the mapped data with grid data and calculate final adjusted values
mapped_grid_data <- selected_data %>%
  left_join(grid_mapping, by = "cd_mun") %>% # Join on municipality code
  mutate(value_final = drymatter_values * adjusted_share_mun_tocr) # Adjust the value using the share

# Select the final output columns
final_data <- mapped_grid_data %>%
  select(idsbrazil, year, MagPie_Prods, value_final) %>%
  group_by(idsbrazil, year,MagPie_Prods) %>%
  summarise(value_final = sum(value_final, na.rm = TRUE), .groups = "drop")

## Step 5: Add aggregated product category ("timber") ---------------------

# Calculate the total "timber" value (wood + woodfuel) for each grid and year
add_timber <- final_data %>%
   group_by(idsbrazil, year) %>%
   summarise(value_final = sum(value_final, na.rm = TRUE), .groups = "drop") %>%
   mutate(MagPie_Prods = "timber")  %>%
   select(idsbrazil, year, MagPie_Prods, value_final)

# Combine the original data with the new "timber" category
final_data2 <- rbind(final_data,add_timber)

head(final_data2)

colnames(final_data2) <- c("x.y.iso","t","kcr","value")
final_data2$x.y.iso <- gsub('[\\"]', '', final_data2$x.y.iso)

# Summarize results 
summary <- final_data2 %>%
  group_by(t,kcr) %>%
  summarise(total = sum(value, na.rm = TRUE) / 1e6)  # Summarize in millions

## Save file
write.table(final_data2,paste0(path, "/output/forestry_products_1998_2023.csv"), row.names = F, sep = ";")
