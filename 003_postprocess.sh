#!/bin/bash

source 000_setup.sh

GEPS6_group=GEPS6sub1

finalfig_pdf_dir=$finalfig_dir/pdf
finalfig_png_dir=$finalfig_dir/png
finalfig_svg_dir=$finalfig_dir/svg
merged_dir=$fig_dir/merged-${GEPS6_group}


echo "Making output directory '${finalfig_dir}'..."
mkdir -p $finalfig_dir
mkdir -p $finalfig_pdf_dir
mkdir -p $finalfig_png_dir
mkdir -p $finalfig_svg_dir
mkdir -p $merged_dir

echo "Copy static figures"
cp -r $staticfig_dir/* $fig_dir

echo "Making final figures... "

window_size=5


echo "Figure 1: dB"
for varname in "surf_avg-sst" "UVTZ-gh-850" "UVTZ-gh-500" ; do
for region in NPACATL ; do
for stat in Emean ; do
for month_str in "12,01,02" ; do

    region_proj=${region}-Orthographic
    svg_stack.py      \
        --direction=v \
        $fig_dir/fig_error_diff_${stat}_by_ym-${window_size}/group-${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-0.svg  \
        $fig_dir/fig_error_diff_${stat}_by_ym-${window_size}/group-${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-1.svg  \
        $fig_dir/fig_error_diff_${stat}_by_ym-${window_size}/group-${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-2.svg  \
        > $merged_dir/merged-${varname}-${region}-${stat}-${month_str}.svg

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
        $fig_dir/fig_error_diff_Emean_by_ym-${window_size}/group-${GEPS6_group}/$region_proj/${varname}_1998-2017_${month_str}_lead-window-${lead_window}.svg  \
        > $merged_dir/merged-${varname}-${region}-dB-${month_str}-lead_window-${lead_window}.svg

done
done
done
done
done


echo "Figure: Timeseries"
for region in KCE GS ; do

    input_dir=$fig_dir/fig_errorVar_ts_by_ym-5/group-${GEPS6_group}/$region

    svg_stack.py --direction=v \
        $input_dir/surf_avg-sst_1998-2017_12,01,02.svg    \
        $input_dir/surf_hf_avg-mslhf_1998-2017_12,01,02.svg  \
        $input_dir/AR-IVT_1998-2017_12,01,02.svg          \
        $input_dir/AR-IWV_1998-2017_12,01,02.svg          \
        $input_dir/UVTZ-gh-850_1998-2017_12,01,02.svg     \
        > $merged_dir/merged-$region-ts-ym.svg

done
    
svg_stack.py --direction=h \
    $merged_dir/merged-KCE-ts-ym.svg \
    $merged_dir/merged-GS-ts-ym.svg \
    > $merged_dir/merged-KCE_GS-ts-ym.svg


for varname in AR-IVT AR-IWV surf_hf_avg-mslhf ; do
    svg_stack.py --direction=h \
        $fig_dir/fig_errorVar_ts_by_strictMJO-5/group-${GEPS6_group}/KCE/${varname}_NonMJO.svg \
        $fig_dir/fig_errorVar_ts_by_strictMJO-5/group-${GEPS6_group}/KCE/${varname}_P1234.svg  \
        $fig_dir/fig_errorVar_ts_by_strictMJO-5/group-${GEPS6_group}/KCE/${varname}_P5678.svg  \
        > $merged_dir/merged-ts-strictMJO-${varname}.svg
done

svg_stack.py --direction=v \
    $merged_dir/merged-ts-strictMJO-AR-IVT.svg \
    $merged_dir/merged-ts-strictMJO-surf_hf_avg-mslhf.svg \
    > $merged_dir/merged-ts-strictMJO.svg

svg_stack.py --direction=h \
    $merged_dir/merged-surf_avg-sst-NPACATL-Emean-12,01,02.svg \
    $merged_dir/merged-UVTZ-gh-850-NPACATL-Emean-12,01,02.svg \
    $merged_dir/merged-UVTZ-gh-500-NPACATL-Emean-12,01,02.svg \
    > $merged_dir/merged-dB-map.svg

svg_stack.py --direction=h \
    $fig_dir/fig_errorVar_ts_by_ym-5/group-${GEPS6_group}/GLOBAL/surf_avg-sst_1998-2017_12,01,02.svg \
    $fig_dir/fig_errorVar_ts_by_ym-5/group-${GEPS6_group}/NH/surf_avg-sst_1998-2017_12,01,02.svg \
    $fig_dir/fig_errorVar_ts_by_ym-5/group-${GEPS6_group}/SH/surf_avg-sst_1998-2017_12,01,02.svg \
    > $merged_dir/merged-SST-errorVar-largescale.svg

echo "Figure 3: MJO dependency"
for region in NPACATL ; do
for projection in PlateCarree ; do
for stat in Emean ; do
for month_str in "12,01,02" ; do
for lead_window in 2 ; do

    region_proj=${region}-${projection}

    svg_stack.py                                \
        --direction=v                           \
        $fig_dir/fig_error_diff_${stat}_by_strictMJO-${window_size}/group-${GEPS6_group}/$region_proj/AR-IVT_gh-850_NonMJO_lead-window-2.svg  \
        $fig_dir/fig_error_diff_${stat}_by_strictMJO-${window_size}/group-${GEPS6_group}/$region_proj/AR-IVT_gh-850_P1234_lead-window-2.svg   \
        $fig_dir/fig_error_diff_${stat}_by_strictMJO-${window_size}/group-${GEPS6_group}/$region_proj/AR-IVT_gh-850_P5678_lead-window-2.svg   \
        > $merged_dir/merged-IVT-MJO-dependency-${projection}-${stat}-${month_str}-${lead_window}.svg
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
        $fig_dir/fig_error_diff_Emean_by_strictMJO-${window_size}/group-${GEPS6_group}/$region_proj/surf_hf_avg-mslhf_msl_${category}_lead-window-${lead_window}.svg \
        $fig_dir/fig_error_diff_Emean_by_strictMJO-${window_size}/group-${GEPS6_group}/$region_proj/surf_avg-sst_msl_${category}_lead-window-${lead_window}.svg \
        > $merged_dir/merged-AL-analysis-${region_proj}-Emean-${category}-lead-window-${lead_window}.svg
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
            $fig_dir/fig_error_diff_Emean_by_strictMJO-${window_size}/group-${GEPS6_group}/$region_proj/${shading_varname}_gh-850_${category}_lead-window-0.svg \
            $fig_dir/fig_error_diff_Emean_by_strictMJO-${window_size}/group-${GEPS6_group}/$region_proj/${shading_varname}_gh-850_${category}_lead-window-1.svg \
            > $merged_dir/merged-hf-analysis-${region_proj}-Emean-${category}-${shading_varname}.svg
    done
    done

    svg_stack.py --direction=v \
        $merged_dir/merged-hf-analysis-${region_proj}-Emean-${category}-surf_avg-sst.svg \
        $merged_dir/merged-hf-analysis-${region_proj}-Emean-${category}-surf_hf_avg-mslhf.svg \
        > $merged_dir/merged-hf-analysis-${region_proj}-Emean-${category}.svg

done
done


name_pairs=(
    $merged_dir/merged-dB-map.svg                                                   fig01
    $merged_dir/merged-AR-IVT_gh-850-NPACATL-dB-12,01,02-lead_window-2.svg          fig02
    $merged_dir/merged-IVT-MJO-dependency-PlateCarree-Emean-12,01,02-2.svg          fig03
    $merged_dir/merged-ts-strictMJO.svg                                             fig04
    $merged_dir/merged-KCE_GS-ts-ym.svg                                             fig05
    $merged_dir/merged-hf-analysis-NPAC-PlateCarree-Emean-NonMJO.svg                fig06
    $fig_dir/MJO_categories.svg                                                     figS01
    $merged_dir/merged-SST-errorVar-largescale.svg                                  figS02
    $merged_dir/merged-hf-analysis-NATL-PlateCarree-Emean-NonMJO.svg                figS03
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
    cp $src_file $finalfig_svg_dir/$dst_file_svg
   
    echo "$src_file => $dst_file_pdf"
    cairosvg $src_file -o $finalfig_pdf_dir/$dst_file_pdf

    echo "$src_file => $dst_file_png"
    magick $finalfig_pdf_dir/$dst_file_pdf $finalfig_png_dir/$dst_file_png

    } &
done

wait

echo "Done."
