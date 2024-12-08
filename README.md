# MagPie-IBGE Crop Mapping

This repository provides a workflow for mapping agricultural data between MagPie crops and IBGE crops, integrating grid-based spatial data, and processing historical crop data from IBGE.

# Repository Structure
```bash

.
├── data/                         
│   ├── mapping_crops.rds                  # Mapping file between MagPie and IBGE crops
│   ├── mapping_grid_municipio_adjust.csv  # Grid-to-municipality mapping file
├── example_data/                 
│   └── PAM_data_planted_area_1998_to_2023.rds  # Example IBGE crop data (planted area)
│   └── PPM_data_livestock_1998_to_2023.rds  # Example IBGE Animal data 
│   └── PEVS_data_production_1998_to_2023.rds  # Example IBGE forestry data 
├── output/                       
│   └── crop_planted_area_1998_2023.csv    # Final output for PAM data
├── 1_mapping_pam_magpie.R                # Script for processing PAM (Planted Area)
├── 2_mapping_ppm_magpie.R                # Script for processing PPM (Animal)
├── 3_mapping_pevs_magpie.R               # Script for processing PEVS (Forestry Extraction and Silviculture)
└── README.md                             # This README file
```

# Prerequisites
* R version ≥ 4.0.0
* Required R packages:
  * dplyr

Install required packages if they are not already installed:
```R
install.packages("dplyr")
```

# Usage
# 1. Clone the Repository
```bash
git clone https://github.com/yourusername/magpie_ibge_mapping.git
cd magpie_ibge_mapping
```

# 2. Run the Script
Open 1_mapping_pam_magpie.R in your R environment, ensure the working directory is set correctly, and execute the script step by step. The script will:

* Load data from the data/ and example_data/ folders.
* Process and clean the IBGE crop data.
* Merge data with the MagPie crop mapping and grid mapping.
* Save the results to the output/ directory.

# 3. Output
The final output file contains:

* idsbrazil: Spatial grid identifiers
* year: Year of the data
* MagPie_Crops: MagPie crop categories
* value_final: Adjusted crop values
