# A-spatially-explicit-dataset-of-agriculture-liming-across-the-contiguous-United-States

This repository includes the code used to create the analysis and figures in 
**Tsao et al. (2026)** A spatially explicit dataset of agriculture liming across the contiguous United States (manuscript under review)

and our data product 
Tsao, et al., (2025). Agricultural lime application across the contiguous United States, 1930–1987 [Data set]. Zenodo.

## Data Sources
The raw data used in this study are collected from Haines et al. (2018) https://www.icpsr.umich.edu/web/ICPSR/studies/35206

## Workflow Overview

# Main data processing, Analysis
- Liming_Data_Processing_Analysis.ipynb
This notebook contains the code for all our dataprocessing from the source raw data to the shapefile data product.
This includes the temporal interpolation, spatial filling, and visualization to reproduce the figures in our manuscript,
as well as the machine learning statistical analysis.

# County level climate, soil, lithology, predictors extraction
- average_PRISM_1978_1987.sh (this code averages the climate data from PRISM within the 1978-1987 when we conduct our spatial analysis) 
- extract_zonal_downscale.sh (this code performs the county level average from the different rasters file, used in the machine learning statistical analysis)



# cropland area calculation
- compute_county_cropland_area.py  (this code calculate the cropland area for each county based on the pixel-level cropland density product of Ye et al. (2024),
  which is necessary for us to rasterize our shapefiles)
- run_compute_county_cropland_area.sh  (this executes the above python code)

# Rasterization of data product
- split_shapefile_yearly.sh (this code makes the shapefile data product into yearly separate files)
- rasterize_shapefile.sh   (this code rasterize the yearly shapefiles into pixel-level data product, by incorporating the calculated county level cropland area
  and pixel-level cropland density)

