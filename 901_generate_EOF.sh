#!/bin/bash

source 999_trapkill.sh
source 000_setup.sh

fig_fmt=svg

days_per_window=5
lead_windows=6

params=(
    surf_avg sst        0
)

region_params=(
    GS 0  90  -250 20
)
region_nparams=5

nparams=3
for GEPS6_group in GEPS6sub1 ; do 
for (( i=0 ; i < $(( ${#params[@]} / $nparams )) ; i++ )); do
for (( j=0 ; j < $(( ${#region_params[@]} / $region_nparams )) ; j++ )); do

    ECCC_varset="${params[$(( i * $nparams + 0 ))]}"
    varname="${params[$(( i * $nparams + 1 ))]}"
    level="${params[$(( i * $nparams + 2 ))]}"

    echo ":: ECCC_varset  = $ECCC_varset"
    echo ":: varname = $varname"
    echo ":: level = $level"
    
    region_name="${region_params[$(( j * $region_nparams + 0 ))]}"
    region_lat_min="${region_params[$(( j * $region_nparams + 1 ))]}"
    region_lat_max="${region_params[$(( j * $region_nparams + 2 ))]}"
    region_lon_min="${region_params[$(( j * $region_nparams + 3 ))]}"
    region_lon_max="${region_params[$(( j * $region_nparams + 4 ))]}"
    
    echo ":: region_name = $region_name"
    echo ":: region_lat_min = $region_lat_min"
    echo ":: region_lat_max = $region_lat_max"
    echo ":: region_lon_min = $region_lon_min"
    echo ":: region_lon_max = $region_lon_max"

    if [ "$level" = "0" ] ; then
        level_str=""
    else
        level_str="-${level}"
    fi 

    input_dir=$data_dir/analysis/output_analysis_map_by_ym_window-${days_per_window}-leadwindow-${lead_windows}
    output_dir=$gendata_dir/EOF_mean_diff_by_ym-$days_per_window/group-${GEPS6_group}/$region_name
    mkdir -p $output_dir

    for selected_months in "12 01 02"; do

        categories=""
        for year in $( seq $year_beg $year_end ); do 
           
            IFS=' ' read -r -a arr <<< "$selected_months" 
            for _month in $selected_months ; do
                categories="$categories $year-$_month"
            done
        done
 
        for lead_window in $( seq 0 2 ); do #$(( $lead_windows - 1 )) )  ; do
           
            m_str=$( echo "$selected_months" | sed -r "s/ /,/g" ) 
            output=$output_dir/${ECCC_varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}_lead-window-${lead_window}.nc
            
            numbering_Emean=-1
           
            if [ -f "$output" ] ; then
                echo "Output file $output and $output_error exist. Skip."
            else
                python3 src/generate_diff_group_PCA_by_category.py \
                    --input-dir $input_dir \
                    --model-versions GEPS5 $GEPS6_group \
                    --category $categories \
                    --category-label "$category_label" \
                    --lead-window $lead_window \
                    --varset $ECCC_varset \
                    --varname $varname \
                    --level $level \
                    --output $output \
                    --lat-rng $region_lat_min $region_lat_max \
                    --lon-rng $region_lon_min $region_lon_max 

            fi
        done
    done
done
done
done

wait


echo "Done."
