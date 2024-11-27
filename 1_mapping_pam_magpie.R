################################################################################
# MagPie-IBGE Crop Mapping and Data Integration Script
#
# Author: Marluce da Cruz Scarabello
# Date: November, 2024
#
# Description:
# This script processes agricultural data from IBGE and maps it to MagPie crop 
# categories. It integrates IBGE's data (1998–2023) with a spatial 
# grid, allowing analysis of agricultural production at a finer resolution. 
# The output is a dataset ready for use in MagPie modeling or similar analyses.
#
# Steps:
# Run the step 2.1 ONLY when you run production data
# Input Files:
# - data/mapping_crops.rds: Mapping file linking MagPie crop categories to IBGE crops.
# - data/mapping_grid_municipio_adjust.csv: Spatial grid mapping for municipalities.
# - example_data/PAM_data_planted_area_1998_to_2023.rds: IBGE data on planted areas.
#
# Output:
# - crop_planted_area_1998_2023.csv: Final dataset containing grid IDs, MagPie crop 
#   categories, years, and adjusted crop values.
#
# Load necessary libraries
library(dplyr)

# Define paths
path <- getwd() # Get the current working directory

## Step 1: Load data ------------------------------------------------------
# Load auxiliary files
# Mapping between MagPie crops and IBGE crops
mapping_crops <- readRDS(paste0(path,"/data/mapping_crops2.rds")) %>%  as.data.frame()
# Load grid mapping data
grid_mapping <- read.csv(paste0(path, "/data/mapping_grid_municipio_adjust.csv"))

# Load IBGE data
ibge_data <- readRDS(paste0(path, "/example_data/PAM_data_planted_area_1998_to_2023.rds")) %>% as.data.frame()

## Step 2: Pre-processing IBGE data ---------------------------------------
# Rename columns for easier interpretation
colnames(ibge_data)
colnames(ibge_data) <- c("cd_nivel_terri", "nm_nivel_terri", "cd_unidmedida", 
                        "nm_unidmedida", "value", "cd_mun", "nm_mun", 
                        "cd_var", "nm_var", "cd_year", "nm_year", "cd_prod", 
                        "nm_prod", "year")

# Filter and clean the data for analysis
cleaned_data <- ibge_data %>%
  select(cd_mun, nm_prod, year, cd_year, value) %>%  # Select relevant columns
    mutate(value = gsub("-", 0, value),           # Substitui "-" por NA
           value = gsub("\\.\\.\\.", 0, value),   # Substitui "..." por NA
           value = as.numeric(value),
           cd_mun = as.integer(cd_mun),  # Convert municipality codes to integers
           nm_prod = as.character(nm_prod))  # Ensure product names are characters


# Step 2.1:  Production issue  ---------------------------------
# A partir do ano de 2001, as quantidades produzidas dos produtos: abacate, banana, 
# caqui, figo, goiaba, laranja, limão, maçã, mamão, manga, maracujá, marmelo, melancia, 
# melão, pêra, pêssego e tangerina passam a ser expressas em toneladas. Nos anos anteriores, 
# eram expressas em mil frutos, com exceção da banana, que era expressa em mil cachos.
# O rendimento médio passa a ser expresso em Kg/ha. Nos anos anteriores, era expresso em 
# frutos/ha, com exceção da banana, que era expressa em cachos/ha.
#production_dif_2001 <- c("Abacate", "Banana (cacho)", "Caqui", "Figo", "Goiaba", 
#                       "Laranja", "Limão", "Maçã", "Mamão", "Manga", 
#                       "Maracujá", "Marmelo", "Melancia", "Melão", "Pera", 
#                       "Pêssego")

# As quantidades produzidas de abacaxi e de coco-da-baía são expressas em mil frutos, 
# e o rendimento médio em frutos/ha.
#remove_production <- c("Abacaxi*","Coco-da-baía*")

#cleaned_data <- cleaned_data %>%
#  mutate(value = ifelse(nm_prod %in% production_dif_2001 & year < 2001, 0, value)) %>%
#  mutate(value = ifelse(nm_prod %in% remove_production, 0, value))

## Step 3:  Merge  ---------------------------------
# Merge cleaned IBGE data with the crop mapping
mapped_data <- cleaned_data %>%
  inner_join(mapping_crops, by = c("nm_prod" = "IBGE_Crops")) %>%  # Join on the crop name
  select(cd_mun, nm_prod, year, cd_year, value, MagPie_Crops)  # Select relevant columns after the merge

# Ensure municipality codes are integers for consistency
mapped_data$cd_mun <- as.integer(mapped_data$cd_mun)

# Merge the mapped data with grid data and calculate final adjusted values
mapped_grid_data <- mapped_data %>%
  left_join(grid_mapping, by = "cd_mun") %>% # Join on municipality code
  mutate(value_final = value * adjusted_share_mun_tocr) # Adjust the value using the share

# Select the final output columns
final_data <- mapped_grid_data %>%
  select(idsbrazil, year, MagPie_Crops, value_final)

colnames(final_data) <- c("x.y.iso","t","kcr","value")
final_data$x.y.iso <- gsub('[\\"]', '', final_data$x.y.iso)
final_data$x.y.iso <- gsub('[\\"]', '', final_data$x.y.iso)


# Summarize results for a specific crop (soybean example)
summary_soybean <- mapped_grid_data %>%
  filter(MagPie_Crops == "soybean") %>%
  group_by(year) %>%
  summarise(total = sum(value_final, na.rm = TRUE) / 1e6)  # Summarize in millions

## Save file
write.table(final_data2,"crop_planted_area_1998_2023.csv", row.names = F, sep = ";")
