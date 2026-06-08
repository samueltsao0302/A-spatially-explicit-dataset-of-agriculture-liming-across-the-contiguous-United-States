#!/bin/bash
#SBATCH --job-name=compute_lime_1km
#SBATCH --output=compute_lime_1km.out
#SBATCH --error=compute_lime_1km.err
#SBATCH --time=04:00:00
#SBATCH --mem=32G
#SBATCH -n 1 -c 8
#SBATCH -p day
#SBATCH --array=1910,1915,1920,1925,1930,1940,1950,1954,1959,1964,1969,1974,1978,1982,1987



module load miniconda
conda activate my_env

YEAR=$SLURM_ARRAY_TASK_ID
echo "Running cropland computation for year $YEAR"
python compute_county_cropland_area.py $YEAR

