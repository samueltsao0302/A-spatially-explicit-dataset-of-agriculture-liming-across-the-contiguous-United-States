#!/usr/bin/env python3
import geopandas as gpd
import rasterio
from rasterstats import zonal_stats
import pandas as pd
import sys
import os

if len(sys.argv) < 2:
    raise SystemExit("Usage: python compute_cropland_one_year.py <YEAR>")
YEAR = int(sys.argv[1])

YEARLY_GPKG = f"/gpfs/gibbs/pi/hydro/st929/Liming_Project/liming_shapefiles/yearly/lime_{YEAR}.gpkg"
CROPDENS = f"/gpfs/gibbs/pi/hydro/st929/Raster_data_for_prediction/Cropland_Area_USA/CropDensity/CropDensity_{YEAR}.tif"
OUT = f"/gpfs/gibbs/pi/hydro/st929/Liming_Project/liming_shapefiles/yearly/cropland_year_{YEAR}.csv"

print(f"Processing YEAR {YEAR}")
print("Reading:", YEARLY_GPKG)


gdf = gpd.read_file(YEARLY_GPKG)
gdf["GEOID"] = gdf["GEOID"].astype(int)

with rasterio.open(CROPDENS) as src:
    raster_crs = src.crs          # ❗ USE THIS CRS
    pixel_area = abs(src.res[0] * src.res[1])

# ❗ Reproject counties to raster CRS
gdf = gdf.to_crs(raster_crs)
# =====================

# ZONAL STATISTICS

# =====================

with rasterio.open(CROPDENS) as src:
    pixel_area = abs(src.res[0] * src.res[1])
    zs = zonal_stats(
        gdf,
        CROPDENS,
        stats=["sum"],
        nodata=0.0,
        geojson_out=False
    )
rows = []
for i, row in enumerate(zs):
    val = row["sum"]
    if val is None:
        val = 0.0
    area_m2 = val * pixel_area
    rows.append({
        "GEOID": int(gdf.loc[i, "GEOID"]),
        "year": YEAR,
        "cropland_fraction_sum": val,
        "cropland_area_m2": area_m2,
        "cropland_area_km2": area_m2 / 1e6
    })

df = pd.DataFrame(rows)
df.to_csv(OUT, index=False)
print(f"Done YEAR {YEAR} → wrote {OUT}")


