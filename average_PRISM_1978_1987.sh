#!/bin/bash
#SBATCH --job-name=avg_prism
#SBATCH --output=avg_prism_%j.out
#SBATCH --error=avg_prism_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1



source ~/bin/gdal3
# ---- Process PPT ----
# Change to working directory

cd /gpfs/gibbs/pi/hydro/st929/Liming_Project/info_extract_soil_lithology



mkdir -p all_rasters logs
echo "=== Averaging PPT (1978–1987) ==="

ppt_files=(
    PRISM_ppt_stable_4kmM2_1978_all_bil/PRISM_ppt_stable_4kmM2_1978_bil.bil
    PRISM_ppt_stable_4kmM2_1979_all_bil/PRISM_ppt_stable_4kmM2_1979_bil.bil
    PRISM_ppt_stable_4kmM2_1980_all_bil/PRISM_ppt_stable_4kmM2_1980_bil.bil
    PRISM_ppt_stable_4kmM3_1981_all_bil/PRISM_ppt_stable_4kmM3_1981_bil.bil
    PRISM_ppt_stable_4kmM3_1982_all_bil/PRISM_ppt_stable_4kmM3_1982_bil.bil
    PRISM_ppt_stable_4kmM3_1983_all_bil/PRISM_ppt_stable_4kmM3_1983_bil.bil
    PRISM_ppt_stable_4kmM3_1984_all_bil/PRISM_ppt_stable_4kmM3_1984_bil.bil
    PRISM_ppt_stable_4kmM3_1985_all_bil/PRISM_ppt_stable_4kmM3_1985_bil.bil
    PRISM_ppt_stable_4kmM3_1986_all_bil/PRISM_ppt_stable_4kmM3_1986_bil.bil
    PRISM_ppt_stable_4kmM3_1987_all_bil/PRISM_ppt_stable_4kmM3_1987_bil.bil
)



letters=(A B C D E F G H I J)

ppt_args=""

ppt_expr=""



for i in "${!ppt_files[@]}"; do
    var="${letters[$i]}"
    ppt_args+=" -$var ${ppt_files[$i]}"
    ppt_expr+="$var+"
done

ppt_expr=${ppt_expr%+}



gdal_calc.py $ppt_args \
  --calc="($ppt_expr)/10" \
  --outfile=all_rasters/ppt_1978_1987_avg.tif \
  --NoDataValue=-9999 --overwrite --quiet
echo "=== Averaging TMEAN (1978–1987) ==="

tmean_files=(
    PRISM_tmean_stable_4kmM3_1978_all_bil/PRISM_tmean_stable_4kmM3_1978_bil.bil
    PRISM_tmean_stable_4kmM3_1979_all_bil/PRISM_tmean_stable_4kmM3_1979_bil.bil
    PRISM_tmean_stable_4kmM3_1980_all_bil/PRISM_tmean_stable_4kmM3_1980_bil.bil
    PRISM_tmean_stable_4kmM3_1981_all_bil/PRISM_tmean_stable_4kmM3_1981_bil.bil
    PRISM_tmean_stable_4kmM3_1982_all_bil/PRISM_tmean_stable_4kmM3_1982_bil.bil
    PRISM_tmean_stable_4kmM3_1983_all_bil/PRISM_tmean_stable_4kmM3_1983_bil.bil
    PRISM_tmean_stable_4kmM3_1984_all_bil/PRISM_tmean_stable_4kmM3_1984_bil.bil
    PRISM_tmean_stable_4kmM3_1985_all_bil/PRISM_tmean_stable_4kmM3_1985_bil.bil
    PRISM_tmean_stable_4kmM3_1986_all_bil/PRISM_tmean_stable_4kmM3_1986_bil.bil
    PRISM_tmean_stable_4kmM3_1987_all_bil/PRISM_tmean_stable_4kmM3_1987_bil.bil
)




letters=(A B C D E F G H I J)

tmean_args=""

tmean_expr=""



for i in "${!tmean_files[@]}"; do
    var="${letters[$i]}"
    tmean_args+=" -$var ${tmean_files[$i]}"
    tmean_expr+="$var+"
done

tmean_expr=${tmean_expr%+}



gdal_calc.py $tmean_args \
  --calc="($tmean_expr)/10" \
  --outfile=all_rasters/tmean_1978_1987_avg.tif \
  --NoDataValue=-9999 --overwrite --quiet

echo "=== TMEAN averaging done ==="
