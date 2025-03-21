#!/bin/bash

source 999_trapkill.sh
source 000_setup.sh

fig_fmt=svg
batch_cnt_limit=5


year_beg=1998
year_end=2017



days_per_pentad=5
lead_pentads=6


params=(
    surf_inst msl
    AR IVT_x
    AR IVT_y
    AR IVT
)
#    surf_inst msl

#    surf_inst u10
params=(
    hf_surf_inst mslhf
    hf_surf_inst msshf
)

params=(
    surf_inst msl     0
    UVTZ gh           850
    AR IVT            0
    surf_avg sst      0
#    AR IWV            0


#    surf_hf_avg mslhf 0
#    surf_hf_avg msshf 0
#    UVTZ gh           500
#    AR IVT_x          0
#    AR IVT_y          0
)

region_params=(
    NATL 20 80 -90  20
    NPAC 20 80 110 250
#    NH 0 90 0 359.99
    WORLD -90 90 0 359.99

)
region_nparams=5

nparams=3
#for GEPS6_group in GEPS6sub1 GEPS6sub2 GEPS6 ; do
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


    if ! [ "$level" = "0" ] ; then
        level_str="-${level}"
    fi 

    output_dir=$fig_dir/fig_worldmap_prediction_error_diff_global_pentad-$days_per_pentad-multimonths/group-${GEPS6_group}/$region_name
    output_error_dir=$fig_dir/fig_worldmap_prediction_error_diff_Estd_global_pentad-$days_per_pentad-multimonths/group-${GEPS6_group}/$region_name

    mkdir -p $output_dir
    mkdir -p $output_error_dir


    input_dir=$data_dir/analysis/output_analysis_map_pentad-${days_per_pentad}-leadpentad-${lead_pentads}

    for months in "10 11 12 1 2 3" ; do
        
        for lead_pentad in $( seq 0 $(( $lead_pentads - 1 )) )  ; do
           
            m_str=$( echo "$months" | sed -r "s/ /,/g" ) 
            output=$output_dir/${ECCC_varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}_lead-pentad-${lead_pentad}.${fig_fmt}
            output_error=$output_error_dir/${ECCC_varset}-${varname}${level_str}_${year_beg}-${year_end}_${m_str}_lead-pentad-${lead_pentad}.${fig_fmt}


            if [ -f "$output" ] && [ -f "$output_error" ] ; then
                echo "Output file $output and $output_error exist. Skip."
            else
                python3 src/plot_map_prediction_error_diff_group.py \
                    --input-dir $input_dir \
                    --model-versions GEPS5 $GEPS6_group \
                    --year-rng $year_beg $year_end \
                    --months $months \
                    --lead-pentad $lead_pentad \
                    --varset $ECCC_varset \
                    --varname $varname \
                    --level $level \
                    --no-display \
                    --output $output \
                    --output-error $output_error \
                    --plot-lat-rng $region_lat_min $region_lat_max \
                    --plot-lon-rng $region_lon_min $region_lon_max  &

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
