#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 10 -N 1
#SBATCH -t 12:00:00
#SBATCH -o /gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/zonal_stats_%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/zonal_stats_%A_%a.err
#SBATCH --job-name=zonal_stats
#SBATCH --mem=450G

# Load Miniconda and activate the environment
module purge
module load miniconda
conda activate my_env

# Define working directories
DATA_DIR="/gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/all_rasters"
SHAPEFILE="/gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/tl_2012_us_county/tl_2012_us_county.shp"
OUTPUT_DIR="/gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/zonal_stats_results"
OUTPUT_FILE="$OUTPUT_DIR/final_zonal_stats.csv"

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Run Python script
# Run Python script
python3 -u <<EOF
import os
import rasterio
from rasterio.warp import calculate_default_transform, reproject, Resampling
import geopandas as gpd
import rasterstats as rs
import pandas as pd

DATA_DIR = "/gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/all_rasters"
SHAPEFILE = "/gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/tl_2012_us_county/tl_2012_us_county.shp"
OUTPUT_DIR = "/gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/zonal_stats_results"
OUTPUT_FILE = f"{OUTPUT_DIR}/PRISM_1978_1987.csv"

os.makedirs(OUTPUT_DIR, exist_ok=True)


# Load counties shapefile

print("Loading county shapefile...", flush=True)

counties = gpd.read_file(SHAPEFILE)

counties['GEOID'] = counties['GEOID'].astype('Int64')

counties = counties[['GEOID', 'geometry']]



# Load main dataset (without geometry)

print("Loading attribute data...", flush=True)

df_no_geometry = pd.read_csv("/gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology/filled_df_no_geometry_redo_simple02262014.csv")

df_no_geometry.loc[df_no_geometry['GEOID'] == 12025, 'GEOID'] = 12086  # Update Miami-Dade FIPS



# Merge attribute data (keep original CRS)

filled_df = pd.merge(counties, df_no_geometry, how="right", on="GEOID").drop_duplicates()



# DataFrame to store raster statistics

stats_all_rasters = pd.DataFrame({'GEOID': filled_df['GEOID']})



# Get list of raster files

#raster_files = [f for f in os.listdir(DATA_DIR) if f.endswith(".tif")]
raster_files = ["ppt_1978_1987_avg.tif", "tmean_1978_1987_avg.tif"]



# Process rasters

for raster_file in raster_files:

    raster_path = os.path.join(DATA_DIR, raster_file)

    print(f"\nProcessing raster: {raster_file}", flush=True)



    with rasterio.open(raster_path) as src:

        raster_crs = src.crs

        raster_nodata = src.nodata

        print(f"Raster CRS: {raster_crs}", flush=True)



        # Reproject only counties, not filled_df

        counties_reprojected = counties.to_crs(raster_crs)



    try:

        # Compute zonal statistics

        print(f"Computing zonal statistics for {raster_file}...", flush=True)

        stats = rs.zonal_stats(

            counties_reprojected,

            raster_path,

            stats="mean",

            geojson_out=True,

            nodata=raster_nodata,

            all_touched=True

        )



        # Convert to DataFrame

        stats_df = pd.DataFrame([feature['properties'] for feature in stats])

        column_name = os.path.splitext(raster_file)[0]

        stats_df.rename(columns={"mean": column_name}, inplace=True)



        # Merge into temporary storage

        stats_all_rasters = stats_all_rasters.merge(stats_df[['GEOID', column_name]], on='GEOID', how='left')

        print(f"Finished processing {raster_file}.", flush=True)



    except Exception as e:

        print(f"Error processing {raster_file}: {e}", flush=True)

# Final merge

filled_df = filled_df.merge(stats_all_rasters, on="GEOID", how="left")
filled_df.to_csv(OUTPUT_FILE, index=False)


