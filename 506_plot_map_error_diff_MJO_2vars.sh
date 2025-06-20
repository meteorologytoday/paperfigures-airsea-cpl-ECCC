#!/bin/bash

source 999_trapkill.sh
source 000_setup.sh

fig_fmt=svg
batch_cnt_limit=10


days_per_window=5
lead_windows=6

classify_method=strictMJO

params=(
#    precip mtp 0 precip mtp 0
#    AR IVT 0 precip mtp 0
    AR IVT 0 surf_inst msl 0
    surf_avg sst 0  surf_inst msl 0
    surf_hf_avg mslhf 0  surf_inst msl 0

)

region_params=(
    NPAC    PlateCarree    0  70    80  230 
    NATL    PlateCarree    0  70   -90   20 
    NPACATL PlateCarree   20  70  -250   20
#    NPACATL Orthographic  0 90  -250 20 

#    GLOBAL  PlateCarree  -90 90 -250 109.99 
#    NPAC    PlateCarree  -20 70 80 270 
)
region_nparams=6

nparams=6
#for GEPS6_group in GEPS6sub1 GEPS6sub2 GEPS6 ; do
for GEPS6_group in GEPS6sub1 ; do
for (( i=0 ; i < $(( ${#params[@]} / $nparams )) ; i++ )); do
for (( j=0 ; j < $(( ${#region_params[@]} / $region_nparams )) ; j++ )); do

    ECCC_varset="${params[$(( i * $nparams + 0 ))]}"
    varname="${params[$(( i * $nparams + 1 ))]}"
    level="${params[$(( i * $nparams + 2 ))]}"

    cntr_ECCC_varset="${params[$(( i * $nparams + 3 ))]}"
    cntr_varname="${params[$(( i * $nparams + 4 ))]}"
    cntr_level="${params[$(( i * $nparams + 5 ))]}"


    echo ":: ECCC_varset  = $ECCC_varset"
    echo ":: varname = $varname"
    echo ":: level = $level"
 
    echo ":: cntr_ECCC_varset  = $cntr_ECCC_varset"
    echo ":: cntr_varname = $cntr_varname"
    echo ":: cntr_level = $cntr_level"
    
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

    if [ "$cntr_level" = "0" ] ; then
        cntr_level_str=""
    else
        cntr_level_str="-${cntr_level}"
    fi 


    output_dir=$fig_dir/fig_error_diff_Emean_by_${classify_method}-$days_per_window/group-${GEPS6_group}/$region_name-${region_projection}
    output_error_dir=$fig_dir/fig_error_diff_Eabsmean_by_${classify_method}-$days_per_window/group-${GEPS6_group}/$region_name-${region_projection}

    mkdir -p $output_dir
    mkdir -p $output_error_dir

    input_dir=$data_dir/analysis/output_analysis_map_by_${classify_method}_window-${days_per_window}-leadwindow-${lead_windows}

    for categories in "NonMJO" "P1234" "P5678" ; do
        
        for lead_window in $( seq 0 2 ) ; do
           
            category_str=$( echo "$categories" | sed -r "s/ /,/g" ) 
            output=$output_dir/${ECCC_varset}-${varname}${level_str}_${cntr_varname}${cntr_level_str}_${category_str}_lead-window-${lead_window}.${fig_fmt}
            output_error=$output_error_dir/${ECCC_varset}-${varname}${level_str}_${cntr_varname}${cntr_level_str}_${category_str}_lead-window-${lead_window}.${fig_fmt}

            numbering_Emean=-1
            numbering_Eabs=-1
           
            # Arbitrary numbering for paper
            if [[ "$varname" = "sst" && "$cntr_varname" = "msl" ]] ; then
                numbering_Emean=$(( 0 + $lead_window ))
            fi

            if [[ "$varname" = "mslhf" && "$cntr_varname" = "msl" ]] ; then
                numbering_Emean=$(( 2 + $lead_window ))
            fi

            if [ -f "$output" ] && [ -f "$output_error" ] ; then
                echo "Output file $output and $output_error exist. Skip."
            else
                python3 src/plot_map_prediction_error_diff_group_by_category.py \
                    --paper $paper \
                    --input-dir $input_dir \
                    --map-projection-name $region_projection \
                    --model-versions GEPS5 $GEPS6_group \
                    --category $categories \
                    --category-label "\$\\phi_{\\mathrm{${categories}}}\$" \
                    --lead-window $lead_window \
                    --varset $ECCC_varset \
                    --varname $varname \
                    --level $level \
                    --cntr-varset  $cntr_ECCC_varset \
                    --cntr-varname $cntr_varname \
                    --cntr-level   $cntr_level \
                    --no-display \
                    --output $output \
                    --output-error $output_error \
                    --thumbnail-numbering-Emean $numbering_Emean \
                    --thumbnail-numbering-Eabs $numbering_Eabs \
                    --pval-threshold 0.1 \
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
