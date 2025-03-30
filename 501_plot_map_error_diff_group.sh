#!/bin/bash

source 999_trapkill.sh
source 000_setup.sh

fig_fmt=svg
batch_cnt_limit=40


year_beg=1998
year_end=2017



days_per_window=5
lead_windows=6


params=(
    precip mtp 0
    UVTZ gh           850
    surf_avg ci 0
    surf_inst msl     0

    UVTZ gh           500
    AR IVT            0
    surf_avg sst     0
    surf_hf_avg mslhf 0
    surf_hf_avg msshf 0


#    AR IWV            0


#    surf_hf_avg mslhf 0
#    surf_hf_avg msshf 0
#    UVTZ gh           500
#    AR IVT_x          0
#    AR IVT_y          0

)

region_params=(
    NPACATL PlateCarree  20 70 -250 20 
    NPACATL Orthographic 20 90 -250 20 
#    NPAC    PlateCarree 20 70 110 250
#    NATL    PlateCarree 20 70 -90  20


    #NH 20 90 30 389.99 
#    WORLD -90 90 0 359.99
)
region_nparams=6

nparams=3
#for GEPS6_group in GEPS6sub1 GEPS6sub2 GEPS6 ; do
for GEPS6_group in GEPS6sub1  ; do
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

    output_dir=$fig_dir/fig_worldmap_prediction_error_diff_Emean_global_window-$days_per_window-multimonths/group-${GEPS6_group}/$region_name-${region_projection}
    output_error_dir=$fig_dir/fig_worldmap_prediction_error_diff_Eabsmean_global_window-$days_per_window-multimonths/group-${GEPS6_group}/$region_name-${region_projection}

    mkdir -p $output_dir
    mkdir -p $output_error_dir


    input_dir=$data_dir/analysis/output_analysis_map_window-${days_per_window}-leadwindow-${lead_windows}

    for months in "12 1 2"; do
        
        #for lead_window in $( seq 0 $(( $lead_windows - 1 )) )  ; do
        for lead_window in $( seq 0 2 ) ; do
           
            m_str=$( echo "$months" | sed -r "s/ /,/g" ) 
            output=$output_dir/${ECCC_varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}_lead-window-${lead_window}.${fig_fmt}
            output_error=$output_error_dir/${ECCC_varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}_lead-window-${lead_window}.${fig_fmt}

            

            if [ -f "$output" ] && [ -f "$output_error" ] ; then
                echo "Output file $output and $output_error exist. Skip."
            else
                python3 src/plot_map_prediction_error_diff_group.py \
                    --paper $paper \
                    --input-dir $input_dir \
                    --map-projection-name $region_projection \
                    --model-versions GEPS5 $GEPS6_group \
                    --year-rng $year_beg $year_end \
                    --months $months \
                    --lead-window $lead_window \
                    --varset $ECCC_varset \
                    --varname $varname \
                    --level $level \
                    --no-display \
                    --output $output \
                    --output-error $output_error \
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
