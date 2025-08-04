#!/bin/bash

source 999_trapkill.sh
source 000_setup.sh

#year_beg=2010

fig_fmt=svg
batch_cnt_limit=21
#batch_cnt_limit=1

days_per_window=5
lead_windows=6

classify_method=ym
classify_categories="ym"


params=(
    surf_avg sst        0
    surf_inst msl       0
    UVTZ gh           500
    UVTZ gh           850
    AR IVT              0
    AR IWV              0
)

region_params=(
#    GLOBAL  PlateCarree  -90 90 -250 109.99 
    KCE     30 50 150 230
    GS      30 55 285 345
    NH      0 90 0 360
    NPAC    0  70    80  230 
    NATL    0  70   -90   20 


#    WORLD -90 90 0 359.99
)
region_nparams=5

nparams=3
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

    output_dir=$fig_dir/fig_error_ts_Eabsmean_by_ym-$days_per_window/$region_name
    mkdir -p $output_dir

    input_dir=$data_dir/analysis/output_analysis_map_by_ym_window-${days_per_window}-leadwindow-${lead_windows}

    for selected_months in "12 01 02"; do

        if [ "$selected_months" = "12 01 02" ] ; then
            category_label='$\phi_{\mathrm{DJF}}$'
        fi
        
        categories=""
        for year in $( seq $year_beg $year_end ); do 
            IFS=' ' read -r -a arr <<< "$selected_months" 
            for _month in $selected_months ; do
                categories="$categories $year-$_month"
            done
        done
 
        m_str=$( echo "$selected_months" | sed -r "s/ /,/g" ) 
        output=$output_dir/${ECCC_varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}.${fig_fmt}

        numbering_Emean=-1
        numbering_Eabs=-1

        if [ "$varname" = "sst"  ]  ; then    
            numbering_Eabs=0
        elif [ "$varname" = "msl" ]  ; then
            numbering_Eabs=1
        fi 

        if [ -f "$output" ] && [ -f "$output_error" ] ; then
            echo "Output file $output and $output_error exist. Skip."
        else
            python3 src/plot_timeseries_prediction_error_diff_group_by_category.py \
                --paper $paper \
                --input-dir $input_dir \
                --model-versions GEPS5 GEPS6sub1 \
                --category $categories \
                --category-label "$category_label" \
                --lead-window-range 0 4 \
                --varset $ECCC_varset \
                --varname $varname \
                --level $level \
                --no-display \
                --output $output \
                --thumbnail-numbering-Eabs $numbering_Eabs \
                --lat-rng $region_lat_min $region_lat_max \
                --lon-rng $region_lon_min $region_lon_max & 



            batch_cnt=$(( $batch_cnt + 1)) 
            if (( $batch_cnt >= $batch_cnt_limit )) ; then
                echo "Max batch_cnt reached: $batch_cnt"
                wait
                batch_cnt=0
            fi
         
        fi
        
    done
done
done

wait


echo "Done."
