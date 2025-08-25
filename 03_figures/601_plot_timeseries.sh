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
    surf_hf_avg mslhf 0
    surf_avg sst        0
    AR IVT              0
    AR IWV              0
    UVTZ gh           850
#    surf_inst msl       0
#    UVTZ gh           500

)

region_params=(
#    GLOBAL  PlateCarree  -90 90 -250 109.99 
#    AL     30 50 150 230
#    IL     30 50 150 230
    KCE     30 50 150 230
    GS      30 55 285 345
#    NH      0 90 0 360
#    NPAC    0  70    80  230 
#    NATL    0  70   -90   20 


#    WORLD -90 90 0 359.99
)
region_nparams=5

nparams=3
for (( i=0 ; i < $(( ${#params[@]} / $nparams )) ; i++ )); do
for (( j=0 ; j < $(( ${#region_params[@]} / $region_nparams )) ; j++ )); do

    varset="${params[$(( i * $nparams + 0 ))]}"
    varname="${params[$(( i * $nparams + 1 ))]}"
    level="${params[$(( i * $nparams + 2 ))]}"

    echo ":: varset  = $varset"
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

    output_dir=$fig_dir/fig_errorVar_ts_by_ym-$days_per_window/$region_name
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
        output=$output_dir/${varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}.${fig_fmt}

        numbering=-1
        decomp=no
        if [ "$varname" = "sst"  ]  ; then    
            numbering=0
            decomp=yes
        elif [ "$varname" = "mslhf" ]  ; then
            numbering=1
            decomp=yes
        elif [ "$varname" = "IVT" ]  ; then
            numbering=2
        elif [ "$varname" = "IWV" ]  ; then
            numbering=3
        elif [ "$varname-$level" = "gh-850" ]  ; then
            numbering=4
        fi

        if [ "$region_name" = "GS" ]; then
            numbering=$(( $numbering + 5 ))
        fi  
        
        if [ -f "$output" ] && [ -f "$output_error" ] ; then
            echo "Output file $output and $output_error exist. Skip."
        else
            python3 src/plot_timeseries_prediction_error_diff_group_by_category.py \
                --paper $paper                              \
                --input-dir $input_dir                      \
                --model-versions GEPS5 GEPS6sub1            \
                --category $categories                      \
                --category-label "$category_label"          \
                --lead-window-range 0 4                     \
                --varset $varset                            \
                --varname $varname                          \
                --level $level                              \
                --no-display                                \
                --output $output                            \
                --thumbnail-numbering $numbering            \
                --spread-factor 1.0                         \
                --decomp $decomp                            \
                --region $region_name                       \
                --no-legend                                 &
           
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
