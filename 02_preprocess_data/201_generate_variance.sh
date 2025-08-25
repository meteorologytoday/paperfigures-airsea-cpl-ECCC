#!/bin/bash

source 000_setup.sh 
source 999_trapkill.sh
nproc=10

year_beg=1998
year_end=2017

# Params:

# First two parameters are ECCC data. Fomrat: [raw/postprocessed] [group]
# Second two parameters are ERA5 data. Format: [frequency] [group]
# Last parameter is the variable name shared across ECCC and ERA5

params=(

    daily_mean sea_surface_temperature sea_surface_temperature
    daily_mean mean_surface_latent_heat_flux mean_surface_latent_heat_flux
)
nparams=3

half_window_size=2
output_root="$analysis_dir/output_analysis_variance_half-window-size-${half_window_size}"
for (( i=0 ; i < $(( ${#params[@]} / $nparams )) ; i++ )); do

    ERA5_freq="${params[$(( i * $nparams + 0 ))]}"
    ERA5_varset="${params[$(( i * $nparams + 1 ))]}"
    varname="${params[$(( i * $nparams + 2 ))]}"

    echo ":: ERA5_freq    = $ERA5_freq"
    echo ":: ERA5_varset  = $ERA5_varset"
    echo ":: varname = $varname"



    for year in $( seq $year_beg $year_end ); do

        date_ranges=(
          ${year}-01-01 ${year}-04-30
          ${year}-12-01 ${year}-12-31
        )

        date_nparams=2
        for (( j=0; j < $(( ${#date_ranges[@]} / $date_nparams )) ; j++ )); do
            
            date_beg="${date_ranges[$(( j * $date_nparams + 0 ))]}"
            date_end="${date_ranges[$(( j * $date_nparams + 1 ))]}"

            echo "Doing date range: $date_beg to $date_end"
            python3 src/generate_variance_timeseries.py  \
                --date-range $date_beg $date_end         \
                --ERA5-freq    $ERA5_freq                \
                --ERA5-varset  $ERA5_varset  \
                --varname $varname           \
                --output-root $output_root   \
                --half-window-size $half_window_size \
                --nproc $nproc

        done

    done
done

wait
