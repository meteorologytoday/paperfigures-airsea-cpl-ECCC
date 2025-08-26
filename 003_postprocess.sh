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

echo "Figure 1: dB"
for varname in "surf_avg-sst" "UVTZ-gh-850" "UVTZ-gh-500" ; do
for region in NPACATL ; do
for stat in Emean ; do
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

echo "Figure 2: IVT dB"
for varname in "AR-IVT_gh-850" ; do
for region in NPACATL ; do
for projection in PlateCarree ; do
for month_str in "12,01,02" ; do
for lead_window in 2 ; do
    region_proj=${region}-${projection}
   
    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_Emean_by_ym-${window_size}/group-GEPS6${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-${lead_window}.svg  \
        > $fig_dir/merged-${varname}-${region}-dB-${month_str}-lead_window-${lead_window}.svg

done
done
done
done
done



echo "Figure: Timeseries"
for region in KCE GS ; do

    input_dir=$fig_dir/fig_errorVar_ts_by_ym-5/$region

    svg_stack.py --direction=v \
        $input_dir/surf_avg-sst_1998-2017_12,01,02.svg    \
        $input_dir/surf_hf_avg-mslhf_1998-2017_12,01,02.svg  \
        $input_dir/AR-IVT_1998-2017_12,01,02.svg          \
        $input_dir/AR-IWV_1998-2017_12,01,02.svg          \
        $input_dir/UVTZ-gh-850_1998-2017_12,01,02.svg     \
        > $fig_dir/merged-$region-ts-ym.svg

done
    
svg_stack.py --direction=h \
    $fig_dir/merged-KCE-ts-ym.svg \
    $fig_dir/merged-GS-ts-ym.svg \
    > $fig_dir/merged-KCE_GS-ts-ym.svg


svg_stack.py --direction=h \
    $fig_dir/fig_errorVar_ts_by_strictMJO-5/KCE/AR-IVT_NonMJO.svg \
    $fig_dir/fig_errorVar_ts_by_strictMJO-5/KCE/AR-IVT_P1234.svg  \
    $fig_dir/fig_errorVar_ts_by_strictMJO-5/KCE/AR-IVT_P5678.svg  \
    > $fig_dir/merged-ts-strictMJO-IVT.svg

svg_stack.py --direction=h \
    $fig_dir/merged-surf_avg-sst-NPACATL-Emean-12,01,02.svg \
    $fig_dir/merged-UVTZ-gh-850-NPACATL-Emean-12,01,02.svg \
    $fig_dir/merged-UVTZ-gh-500-NPACATL-Emean-12,01,02.svg \
    > $fig_dir/merged-dB-map.svg



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


name_pairs=(
    merged-dB-map.svg                                                               fig01
    merged-AR-IVT_gh-850-NPACATL-dB-12,01,02-lead_window-2.svg                      fig02
    merged-IVT-MJO-dependency-PlateCarree-Emean-12,01,02-2.svg                      fig03
    merged-hf-analysis-NPAC-PlateCarree-Emean-NonMJO.svg                            fig04
    merged-KCE_GS-ts-ym.svg                                                         fig05
    merged-ts-strictMJO-IVT.svg                                                     fig06
    MJO_categories.svg                                                              figS01
    merged-hf-analysis-NATL-PlateCarree-Emean-NonMJO.svg                            figS02
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
