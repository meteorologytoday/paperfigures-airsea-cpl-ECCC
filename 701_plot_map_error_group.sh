#!/bin/bash

source 999_trapkill.sh
source 000_setup.sh

fig_fmt=svg
batch_cnt_limit=31
#batch_cnt_limit=1




days_per_window=5
lead_windows=6

#days_per_window=1
#lead_windows=5



params=(
    
    surf_avg sst        0
    AR IVT            0
#    AR IWV            0
    
#    UVTZ gh           200
    UVTZ gh           500
    surf_inst msl       0

    
#    surf_avg ci 0
#    precip mtp 0
    
#    surf_hf_avg mslhf 0
#    surf_hf_avg msshf 0
#    AR IVT_x          0
#    AR IVT_y          0
    
)

region_params=(
    NPACATL PlateCarree  20 75  -250 25 
    NPACATL Orthographic 0  90  -250 20 
#    GLOBAL  PlateCarree  -90 90 -250 109.99 
    #NH 20 90 30 389.99 
#    WORLD -90 90 0 359.99
)
region_nparams=6

nparams=3
for group in GEPS6sub1 GEPS5 ; do
#for GEPS6_group in GEPS6sub1 ; do #GEPS6sub1offset1  ; do
for (( i=0 ; i < $(( ${#params[@]} / $nparams )) ; i++ )); do
for (( j=0 ; j < $(( ${#region_params[@]} / $region_nparams )) ; j++ )); do

    ECCC_varset="${params[$(( i * $nparams + 0 ))]}"
    varname="${params[$(( i * $nparams + 1 ))]}"
    level="${params[$(( i * $nparams + 2 ))]}"

    echo ":: ECCC_varset  = $ECCC_varset"
    echo ":: varname = $varname"
    echo ":: level = $level"
    
    region_name="${region_params[$(( j * $region_nparams + 0 ))]}"
    region_projection="${region_params[$(( j * $region_nparams + 1 ))]}"
    region_lat_min="${region_params[$(( j * $region_nparams + 2 ))]}"
    region_lat_max="${region_params[$(( j * $region_nparams + 3 ))]}"
    region_lon_min="${region_params[$(( j * $region_nparams + 4 ))]}"
    region_lon_max="${region_params[$(( j * $region_nparams + 5 ))]}"
    
    echo ":: region_name = $region_name"
    echo ":: region_projection = $region_projection"
    echo ":: region_lat_min = $region_lat_min"
    echo ":: region_lat_max = $region_lat_max"
    echo ":: region_lon_min = $region_lon_min"
    echo ":: region_lon_max = $region_lon_max"


    if [ "$level" = "0" ] ; then
        level_str=""
    else
        level_str="-${level}"
    fi 

    output_dir=$fig_dir/fig_error_Emean_by_ym-$days_per_window/group-${group}/$region_name-${region_projection}
    output_error_dir=$fig_dir/fig_error_Eabsmean_by_ym-$days_per_window/group-${group}/$region_name-${region_projection}

    mkdir -p $output_dir
    mkdir -p $output_error_dir


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
 
        for lead_window in $( seq 0 2 ); do #$(( $lead_windows - 1 )) )  ; do
        #for lead_window in $( seq 0 2 ) ; do
           
            m_str=$( echo "$selected_months" | sed -r "s/ /,/g" ) 
            output=$output_dir/${ECCC_varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}_lead-window-${lead_window}.${fig_fmt}
            output_error=$output_error_dir/${ECCC_varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}_lead-window-${lead_window}.${fig_fmt}


            numbering_Emean=-1
            numbering_Eabs=-1
           
            # Arbitrary numbering for paper
 
            if [ "$varname" = "sst" ] ; then
                numbering_Eabs=$(( 0 + $lead_window ))
                numbering_Emean=$(( 0 + $lead_window ))
            fi
            
            if [ "$varname" = "msl" ] ; then
                numbering_Eabs=$(( 3 + $lead_window ))
                numbering_Emean=$(( 3 + $lead_window ))
            fi

            if [ "$varname-$level" = "gh-500" ] ; then
                numbering_Emean=$(( 6 + $lead_window ))
            fi

            if [ "$varname" = "IVT" ] ; then
                numbering_Eabs=$(( 0  ))
                numbering_Emean=$(( 1 ))
            fi

            plot_region_box="false"
            if [ "$region_projection" = "Orthographic" ] && [ "$lead_window" = "2" ] && ( [ "$varname" = "msl" ] || [ "$varname-$level" = "gh-500" ] ) ; then
                plot_region_box="true"
                echo "!!!!! Add Region Box !!!!!"
            fi 

            if [ -f "$output" ] && [ -f "$output_error" ] ; then
                echo "Output file $output and $output_error exist. Skip."
            else
                python3 src/plot_map_prediction_error_diff_group_by_category.py \
                    --paper $paper \
                    --input-dir $input_dir \
                    --map-projection-name $region_projection \
                    --model-versions $group \
                    --category $categories \
                    --category-label "$category_label" \
                    --lead-window $lead_window \
                    --varset $ECCC_varset \
                    --varname $varname \
                    --level $level \
                    --no-display \
                    --output $output \
                    --output-error $output_error \
                    --thumbnail-numbering-Emean $numbering_Emean \
                    --thumbnail-numbering-Eabs $numbering_Eabs \
                    --plot-region-box $plot_region_box \
                    --plot-lat-rng $region_lat_min $region_lat_max \
                    --plot-lon-rng $region_lon_min $region_lon_max & 

#                    --plot-lat-rng 0 65    \
#                    --plot-lon-rng 110 250  &


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
done
done

wait


echo "Done."
