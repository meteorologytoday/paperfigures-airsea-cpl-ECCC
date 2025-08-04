#!/bin/bash

source 000_setup.sh


finalfig_pdf_dir=$finalfig_dir/pdf
finalfig_png_dir=$finalfig_dir/png
finalfig_svg_dir=$finalfig_dir/svg


echo "Making output directory '${finalfig_dir}'..."
mkdir -p $finalfig_dir
mkdir -p $finalfig_pdf_dir
mkdir -p $finalfig_png_dir
mkdir -p $finalfig_svg_dir


echo "Copy static figures"
cp -r $staticfig_dir/* $fig_dir

echo "Making final figures... "

window_size=5

GEPS6_group=sub1

echo "Figure 1 and 2: Estd and Emean error"

for varname in "surf_avg-sst" "surf_inst-msl" "UVTZ-gh-850" "UVTZ-gh-500" ; do
for region in NPACATL ; do
for stat in Emean Eabsmean ; do
for month_str in "12,01,02" ; do

    region_proj=${region}-Orthographic
   

    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_${stat}_by_ym-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-0.svg                       \
        $fig_dir/fig_error_diff_${stat}_by_ym-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-1.svg                       \
        $fig_dir/fig_error_diff_${stat}_by_ym-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-2.svg                       \
        > $fig_dir/merged-${varname}-${region}-${stat}-${month_str}.svg

done
done
done
done

#svg_stack.py --direction=h \
#    $fig_dir/merged-surf_inst-msl-NPACATL-Eabsmean-12,01,02.svg \
#    $fig_dir/merged-surf_inst-msl-NPACATL-Emean-12,01,02.svg \
#    $fig_dir/merged-UVTZ-gh-500-NPACATL-Emean-12,01,02.svg \
#    > $fig_dir/merged-fig1.svg



svg_stack.py --direction=h \
    $fig_dir/merged-surf_avg-sst-NPACATL-Eabsmean-12,01,02.svg \
    $fig_dir/merged-surf_inst-msl-NPACATL-Eabsmean-12,01,02.svg \
    > $fig_dir/merged-dA-map.svg



echo "Figure: Timeseries"

if [ ] ; then
svg_stack.py --direction=h \
    $fig_dir/fig_error_ts_Eabsmean_by_ym-5/NH/surf_avg-sst_1998-2017_12,01,02.svg \
    $fig_dir/fig_error_ts_Eabsmean_by_ym-5/NH/surf_inst-msl_1998-2017_12,01,02.svg \
    > $fig_dir/merged-ts-ym.svg
fi

for region in KCE GS ; do

    input_dir=$fig_dir/fig_error_ts_Eabsmean_by_ym-5/$region

    svg_stack.py --direction=h \
        $input_dir/surf_avg-sst_1998-2017_12,01,02.svg \
        $input_dir/UVTZ-gh-850_1998-2017_12,01,02.svg  \
        $input_dir/AR-IWV_1998-2017_12,01,02.svg       \
        $input_dir/AR-IVT_1998-2017_12,01,02.svg       \
        > $fig_dir/merged-$region-ts-ym.svg

done
    
svg_stack.py --direction=v \
    $fig_dir/merged-KCE-ts-ym.svg \
    $fig_dir/merged-GS-ts-ym.svg \
    > $fig_dir/merged-KCE_GS-ts-ym.svg


svg_stack.py --direction=h \
    $fig_dir/fig_error_ts_Eabsmean_by_strictMJO-5/NH/AR-IVT_NonMJO.svg \
    $fig_dir/fig_error_ts_Eabsmean_by_strictMJO-5/NH/AR-IVT_P1234.svg  \
    $fig_dir/fig_error_ts_Eabsmean_by_strictMJO-5/NH/AR-IVT_P5678.svg  \
    > $fig_dir/merged-ts-strictMJO-IVT.svg

svg_stack.py --direction=h \
    $fig_dir/fig_error_ts_Eabsmean_by_ym-5/NPAC/surf_avg-sst_1998-2017_12,01,02.svg \
    $fig_dir/fig_error_ts_Eabsmean_by_ym-5/NATL/surf_avg-sst_1998-2017_12,01,02.svg \
    > $fig_dir/merged-ts-ym-ocnbasin.svg


#svg_stack.py --direction=h \
#    $fig_dir/merged-surf_inst-msl-NPACATL-Emean-12,01,02.svg \
#    $fig_dir/merged-surf_inst-msl-NPACATL-Eabsmean-12,01,02.svg \
#    > $fig_dir/merged-fig2.svg

svg_stack.py --direction=h \
    $fig_dir/merged-surf_avg-sst-NPACATL-Emean-12,01,02.svg \
    $fig_dir/merged-UVTZ-gh-850-NPACATL-Emean-12,01,02.svg \
    $fig_dir/merged-UVTZ-gh-500-NPACATL-Emean-12,01,02.svg \
    > $fig_dir/merged-dB-map.svg


echo "Figure 3: IVT dA and dB"
for varname in "AR-IVT" ; do
for region in NPACATL ; do
for projection in PlateCarree ; do
for month_str in "12,01,02" ; do
for lead_window in 2 ; do
    region_proj=${region}-${projection}
   
    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_Eabsmean_by_ym-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-${lead_window}.svg  \
        $fig_dir/fig_error_diff_Emean_by_ym-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-${lead_window}.svg  \
        > $fig_dir/merged-${varname}-${region}-dAdB-${month_str}-lead_window-${lead_window}.svg

done
done
done
done
done

if [ ] ; then
for varname in "AR-IVT" ; do
for region in NPACATL ; do
for stat in Emean Eabsmean ; do
for month_str in "12,01,02" ; do

    region_proj=${region}-PlateCarree
   

    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_worldmap_prediction_error_diff_${stat}_global_window-${window_size}-multimonths/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-0.svg                       \
        $fig_dir/fig_worldmap_prediction_error_diff_${stat}_global_window-${window_size}-multimonths/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-1.svg                       \
        $fig_dir/fig_worldmap_prediction_error_diff_${stat}_global_window-${window_size}-multimonths/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-2.svg                       \
        > $fig_dir/merged-${varname}-${region}-${stat}-${month_str}.svg

done
done
done
done
fi


if [ ] ; then
echo "Making overlaping figures..."
for region in NPACATL ; do
for category in nonMJO MJO; do
    region_proj=${region}-PlateCarree
   

    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_Emean_by_CAT2-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/surf_hf_avg-mslhf_msl_${category}_lead-window-0.svg \
        $fig_dir/fig_error_diff_Emean_by_CAT2-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/surf_hf_avg-mslhf_msl_${category}_lead-window-1.svg \
        $fig_dir/fig_error_diff_Emean_by_CAT2-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/surf_hf_avg-mslhf_msl_${category}_lead-window-2.svg \
        > $fig_dir/merged-overlaping-lhf_msl-${region}-Emean-${category}.svg
done
done

echo "2: Making overlaping figures..."
for lead_window in 0 1 2; do
for region in NPACATL ; do
for category in nonMJO MJO; do
    region_proj=${region}-PlateCarree
   

    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_Emean_by_CAT2-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/surf_avg-sst_msl_${category}_lead-window-${lead_window}.svg \
        $fig_dir/fig_error_diff_Emean_by_CAT2-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/surf_hf_avg-mslhf_msl_${category}_lead-window-${lead_window}.svg \
        > $fig_dir/merged-overlaping-sst_lhf_msl-${region}-Emean-${category}-lead-window-${lead_window}.svg
done
done
done
fi


echo "Figure 4: MJO dependency"
for region in NPACATL ; do
for projection in PlateCarree Orthographic ; do
for stat in Emean ; do
for month_str in "12,01,02" ; do
for lead_window in 2 ; do

    region_proj=${region}-${projection}

    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_${stat}_by_strictMJO-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/AR-IVT_gh-850_NonMJO_lead-window-2.svg  \
        $fig_dir/fig_error_diff_${stat}_by_strictMJO-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/AR-IVT_gh-850_P1234_lead-window-2.svg   \
        $fig_dir/fig_error_diff_${stat}_by_strictMJO-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/AR-IVT_gh-850_P5678_lead-window-2.svg   \
        > $fig_dir/merged-IVT-MJO-dependency-${projection}-${stat}-${month_str}-${lead_window}.svg
done
done
done
done
done

echo "Figure 5: Overlaping figures."
if [ ] ; then
for region in NPACATL ; do
for projection in Orthographic PlateCarree ; do
for category in "NonMJO"; do
for lead_window in 0 1 2 ; do

    region_proj=${region}-${projection}
    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_Emean_by_strictMJO-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/surf_hf_avg-mslhf_msl_${category}_lead-window-${lead_window}.svg \
        $fig_dir/fig_error_diff_Emean_by_strictMJO-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/surf_avg-sst_msl_${category}_lead-window-${lead_window}.svg \
        > $fig_dir/merged-AL-analysis-${region_proj}-Emean-${category}-lead-window-${lead_window}.svg
done
done
done
done
fi

for region in NPAC NATL NPACATL ; do
for projection in PlateCarree ; do
    
    for shading_varname in surf_avg-sst surf_hf_avg-mslhf ; do
    for category in "NonMJO"; do

        region_proj=${region}-${projection}
        svg_stack.py                                \
            --direction=h                           \
            $fig_dir/fig_error_diff_Emean_by_strictMJO-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${shading_varname}_gh-850_${category}_lead-window-0.svg \
            $fig_dir/fig_error_diff_Emean_by_strictMJO-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${shading_varname}_gh-850_${category}_lead-window-1.svg \
            > $fig_dir/merged-hf-analysis-${region_proj}-Emean-${category}-${shading_varname}.svg
    done
    done

    svg_stack.py --direction=v \
        $fig_dir/merged-hf-analysis-${region_proj}-Emean-${category}-surf_avg-sst.svg \
        $fig_dir/merged-hf-analysis-${region_proj}-Emean-${category}-surf_hf_avg-mslhf.svg \
        > $fig_dir/merged-hf-analysis-${region_proj}-Emean-${category}.svg

done
done


if [ ] ; then
echo "Making Figure of MJO ..."
for varname in "surf_inst-msl" ; do
for region in NPACATL ; do
for stat in Emean ; do
for category in MJO nonMJO ; do

    region_proj=${region}-Orthographic
   
    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_${stat}_by_CAT2-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_${category}_lead-window-0.svg                       \
        $fig_dir/fig_error_diff_${stat}_by_CAT2-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_${category}_lead-window-1.svg                       \
        $fig_dir/fig_error_diff_${stat}_by_CAT2-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_${category}_lead-window-2.svg                       \
        > $fig_dir/merged-${category}-${varname}-${region}-${stat}.svg

done
done
done
done



svg_stack.py --direction=h \
    $fig_dir/merged-nonMJO-surf_inst-msl-NPACATL-Emean.svg \
    $fig_dir/merged-MJO-surf_inst-msl-NPACATL-Emean.svg \
    > $fig_dir/merged-MJOfig-Emean.svg


svg_stack.py --direction=h \
    $fig_dir/fig_error_diff_Eabsmean_by_CAT2-5/group-GEPS6sub1/NPACATL-Orthographic/surf_inst-msl_nonMJO_lead-window-2.svg  \
    $fig_dir/fig_error_diff_Eabsmean_by_CAT2-5/group-GEPS6sub1/NPACATL-Orthographic/surf_inst-msl_MJO_lead-window-2.svg  \
    > $fig_dir/merged-MJOfig-Eabsmean.svg

fi

name_pairs=(
    merged-dA-map.svg                                                               fig01
#    merged-ts-ym.svg                                                                fig02
    merged-KCE_GS-ts-ym.svg                                                         fig02
    merged-dB-map.svg                                                               fig03
    merged-AR-IVT-NPACATL-dAdB-12,01,02-lead_window-2.svg                           fig04
    merged-IVT-MJO-dependency-PlateCarree-Emean-12,01,02-2.svg                      fig05
    merged-ts-strictMJO-IVT.svg                                                     fig06
    merged-hf-analysis-NPAC-PlateCarree-Emean-NonMJO.svg                            fig07
    MJO_categories.svg                                                              figS01
    merged-ts-ym-ocnbasin.svg                                                       figS02
    merged-hf-analysis-NATL-PlateCarree-Emean-NonMJO.svg                            figS03



#    merged-AL-analysis-NPACATL-PlateCarree-Emean-NonMJO-lead-window-0.svg           fig05
#    merged-AL-analysis-NPACATL-PlateCarree-Emean-NonMJO-lead-window-1.svg           fig06
#    merged-AL-analysis-NPACATL-PlateCarree-Emean-NonMJO-lead-window-2.svg           fig07
#    merged-overlaping-sst_lhf_msl-NPACATL-PlateCarree-Emean-1998-2017_12,01,02.svg  fig05

#    merged-overlaping-sst_lhf_msl-NPACATL-Orthographic-Emean-1998-2017_12,01,02.svg fig05


#    merged-AR-IVT-NPACATL-Eabsmean-12,01,02.svg                                     fig03
#    merged-AR-IVT-NPACATL-Emean-12,01,02.svg                                        fig04

#    merged-MJOfig-Emean.svg                                 fig03

#    merged-overlaping-sst_lhf_msl-NPACATL-Emean-nonMJO-lead-window-0.svg            fig04
#    merged-MJOfig-Eabsmean.svg                              fig05

#    merged-overlaping-lhf_msl-NPACATL-Emean-nonMJO.svg  fig06
#    merged-overlaping-sst_lhf_msl-NPACATL-Emean-nonMJO-lead-window-1.svg  figS01
#    merged-overlaping-sst_lhf_msl-NPACATL-Emean-nonMJO-lead-window-2.svg  figS02
)

N=$(( ${#name_pairs[@]} / 2 ))
echo "We have $N figure(s) to rename and convert into pdf files."
for i in $( seq 1 $N ) ; do

    {

    src_file="${name_pairs[$(( (i-1) * 2 + 0 ))]}"
    dst_file_pdf="${name_pairs[$(( (i-1) * 2 + 1 ))]}.pdf"
    dst_file_png="${name_pairs[$(( (i-1) * 2 + 1 ))]}.png"
    dst_file_svg="${name_pairs[$(( (i-1) * 2 + 1 ))]}.svg"
 
    echo "$src_file => $dst_file_svg"
    cp $fig_dir/$src_file $finalfig_svg_dir/$dst_file_svg
   
    echo "$src_file => $dst_file_pdf"
    cairosvg $fig_dir/$src_file -o $finalfig_pdf_dir/$dst_file_pdf

    echo "$src_file => $dst_file_png"
    magick $finalfig_pdf_dir/$dst_file_pdf $finalfig_png_dir/$dst_file_png

    } &
done

wait

echo "Done."
