#!/bin/bash

source 999_trapkill.sh
source 000_setup.sh

fig_fmt=svg
batch_cnt_limit=21
#batch_cnt_limit=1

year_beg=1998
year_end=2017

params=(
    sea_surface_temperature sst
)

region_params=(
    KCE
)

nparams=2
region_nparams=1
for (( i=0 ; i < $(( ${#params[@]} / $nparams )) ; i++ )); do
for (( j=0 ; j < $(( ${#region_params[@]} / $region_nparams )) ; j++ )); do

    varset="${params[$(( i * $nparams + 0 ))]}"
    varname="${params[$(( i * $nparams + 1 ))]}"
    
    region_name="${region_params[$(( j * $region_nparams + 0 ))]}"

    echo ":: varset  = $varset"
    echo ":: varname = $varname"
    echo ":: region_name = $region_name"
    
    output_dir=$fig_dir/fig_ERA5_variance
    mkdir -p $output_dir

    input_root=$data_dir/analysis/output_analysis_variance

    output_filename=ERA5-variance_${varset}::${varname}_${year_beg}-${year_end}.${fig_fmt}
    output=$output_dir/$output_filename

    cached_file=$output_filename.nc

    if [ -f "$output" ]; then

        echo "Output file $output already exists. Skip."

    else
        python3 src/plot_ERA5_variance.py \
                    --input-root $input_root \
                    --varset $varset \
                    --varname $varname \
                    --year-range $year_beg $year_end  \
                    --no-display \
                    --output $output \
                    --thumbnail-numbering-style 123 \
                    --region $region_name \
                    --cached-file $cached_file &

        batch_cnt=$(( $batch_cnt + 1)) 
        if (( $batch_cnt >= $batch_cnt_limit )) ; then
            echo "Max batch_cnt reached: $batch_cnt"
            wait
            batch_cnt=0
        fi
       
    fi
 
    done
done

wait


echo "Done."
