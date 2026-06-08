#!/bin/bash
#SBATCH --job-name=split_lime_1km
#SBATCH --output=split_lime_1km.out
#SBATCH --error=split_lime_1km.err
#SBATCH --time=04:00:00
#SBATCH --mem=32G

#SBATCH -n 1 -c 8

#SBATCH -p day

GPKG="/gpfs/gibbs/pi/hydro/st929/Liming_Project/liming_shapefiles/lime_1910_1987.gpkg"
OUTDIR="/gpfs/gibbs/pi/hydro/st929/Liming_Project/liming_shapefiles/yearly"

mkdir -p "$OUTDIR"


source ~/bin/gdal3
# get unique years

YEARS=$(ogrinfo "$GPKG" -sql "SELECT DISTINCT year FROM lime_all" \
           | grep year | grep -oE '[0-9]{4}')
echo "Years found:"
echo $YEARS

for Y in $YEARS; do
    echo "Extracting year $Y..."
    ogr2ogr \
      "$OUTDIR/lime_${Y}.gpkg" \
      "$GPKG" \
      -sql "SELECT * FROM lime_all WHERE year=$Y"
done



echo "Done splitting GPKG."
