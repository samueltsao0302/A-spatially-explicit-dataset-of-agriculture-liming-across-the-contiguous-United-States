#!/bin/bash
#SBATCH --job-name=rasterize_lime_1km
#SBATCH --output=rasterize_lime_1km.out
#SBATCH --error=rasterize_lime_1km.err
#SBATCH --time=04:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=2
#SBATCH -p day



# years you have:
#SBATCH --array=1910,1915,1920,1925,1930,1940,1950,1954,1959,1964,1969,1974,1978,1982,1987
module purge
module load miniconda
conda activate my_env
YEAR=$SLURM_ARRAY_TASK_ID
echo "=== Processing Year $YEAR ==="

YEARLY_DIR="/gpfs/gibbs/pi/hydro/st929/Liming_Project/liming_shapefiles/yearly"
CROPDENS="/gpfs/gibbs/pi/hydro/st929/Raster_data_for_prediction/Cropland_Area_USA/CropDensity/CropDensity_${YEAR}.tif"
LIME_GPKG="${YEARLY_DIR}/lime_${YEAR}.gpkg"
CROP_CSV="${YEARLY_DIR}/cropland_year_${YEAR}.csv"
OUTDIR="/gpfs/gibbs/pi/hydro/st929/Liming_Project/liming_rasters"
mkdir -p "$OUTDIR"
MERGED_GPKG="${OUTDIR}/lime_${YEAR}_merged.gpkg"
MERGED_LAYER="lime_${YEAR}"

RAW="$(mktemp ${OUTDIR}/raw_${YEAR}_XXXX.tif)"   # temp file
FINAL="${OUTDIR}/lime_${YEAR}_cropland_masked.tif"
if [ ! -f "$CROPDENS" ]; then
    echo "Missing CropDensity_${YEAR}.tif — skipping"
    exit 0
fi

if [ ! -f "$LIME_GPKG" ]; then
    echo "Missing $LIME_GPKG — skipping"
    exit 0
fi
if [ ! -f "$CROP_CSV" ]; then
    echo "Missing $CROP_CSV — skipping"
    exit 0
fi



python3 << EOF
import geopandas as gpd
import pandas as pd
import rasterio
YEAR = $YEAR
lime_path = "${LIME_GPKG}"
crop_path = "${CROP_CSV}"
out_path  = "${MERGED_GPKG}"
layer     = "${MERGED_LAYER}"
cropdens_path = "${CROPDENS}"
gdf = gpd.read_file(lime_path)
gdf["GEOID"] = gdf["GEOID"].astype(int)
crop = pd.read_csv(crop_path)
crop["GEOID"] = crop["GEOID"].astype(int)
merged = gdf.merge(crop, on="GEOID", how="left")
merged["LimeTons_per_km2"] = merged["LimeTons_metric"] / merged["cropland_area_km2"]
merged["LimeTons_per_km2"] = merged["LimeTons_per_km2"].fillna(0)

with rasterio.open(cropdens_path) as src:
    raster_crs = src.crs

merged = merged.to_crs(raster_crs)
merged.to_file(out_path, layer=layer, driver="GPKG")

print("Saved:", out_path)
EOF



# ---------------- Raster metadata ----------------
# Hard-coded resolution and bounding box

TR="1000 -1000"

BOUNDS="-2356095 277605 2257905 3172605"



# A. Rasterize

gdal_rasterize \
    -l "$MERGED_LAYER" \
    -a LimeTons_per_km2 \
    -tr $TR \
    -te $BOUNDS \
    -a_nodata -9999 \
    -ot Float32 \
    -co COMPRESS=LZW \
    "$MERGED_GPKG" \
    "$RAW"



# B. Mask by cropdensity

gdal_calc.py \
    -A "$RAW" \
    -B "$CROPDENS" \
    --outfile="$FINAL" \
    --calc="numpy.where(A==-9999, -9999, A*B)" \
    --type=Float32 \
    --NoDataValue=-9999 \
    --co=COMPRESS=LZW





# Remove temporary raw.tif

rm -f "$RAW"



echo "=== Done YEAR $YEAR → $FINAL ==="



