# MagPie-IBGE Crop Mapping

This repository provides a comprehensive workflow for integrating agricultural, livestock, and forestry data from IBGE with the MagPie modeling framework.

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
install.packages(c("dplyr", "tidyr", "readr"))
```

# Usage
# 1. Clone the Repository
```bash
git clone https://github.com/yourusername/magpie_ibge_mapping.git
cd magpie_ibge_mapping
```

# 2. Run the Script

Each script focuses on specific data sources and processing steps:

1_mapping_pam_magpie.R: Processes PAM data (Planted Area), performs cleaning, and maps to MagPie crops.
2_mapping_ppm_magpie.R: Handles PPM data (Animal).
3_mapping_pevs_magpie.R: Processes PEVS data (Forestry Extraction and Silviculture) for integration with MagPie forestry products.

Open the desired script in your R environment, set the working directory correctly, and execute the script step by step.

# 3. Output
Each script generates outputs saved to the output/ directory. The outputs include:

PAM Data: Crop-planted area mapped to MagPie categories by year and spatial grid.
PPM Data: Bovine herd mapped to MagPie categories.
PEVS Data: Forestry and silviculture data integrated with MagPie categories.
All results are aligned with spatial grid identifiers and prepared for integration with MagPie models.
