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


echo "Making final figures... "

window_size=5

GEPS6_group=sub1


echo "Figure 1 and 2: Estd and Emean error"

for varname in "surf_inst-msl" "UVTZ-gh-850" "UVTZ-gh-500" ; do
for region in NPACATL ; do
for stat in Emean Eabsmean ; do
for month_str in "12,1,2" ; do

    region_proj=${region}-Orthographic
   

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

svg_stack.py --direction=h \
    $fig_dir/merged-surf_inst-msl-NPACATL-Emean-12,1,2.svg \
    $fig_dir/merged-UVTZ-gh-850-NPACATL-Emean-12,1,2.svg \
    > $fig_dir/merged-fig1.svg


for varname in "AR-IVT" ; do
for region in NPACATL ; do
for stat in Emean Eabsmean ; do
for month_str in "12,1,2" ; do

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


echo "Making Figure 3 stuff..."
for region in NPACATL ; do
for stat in Emean ; do
for month_str in "12,1,2" ; do

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
    $fig_dir/merged-MJO-surf_inst-msl-NPACATL-Emean.svg \
    $fig_dir/merged-nonMJO-surf_inst-msl-NPACATL-Emean.svg \
    > $fig_dir/merged-MJOfig-Emean.svg


svg_stack.py --direction=h \
    $fig_dir/fig_error_diff_Eabsmean_by_CAT2-5/group-GEPS6sub1/NPACATL-Orthographic/surf_inst-msl_MJO_lead-window-2.svg  \
    $fig_dir/fig_error_diff_Eabsmean_by_CAT2-5/group-GEPS6sub1/NPACATL-Orthographic/surf_inst-msl_nonMJO_lead-window-2.svg  \
    > $fig_dir/merged-MJOfig-Eabsmean.svg




name_pairs=(
    merged-surf_inst-msl-NPACATL-Eabsmean-12,1,2.svg   fig01
    merged-fig1.svg                                    fig02
    merged-AR-IVT-NPACATL-Emean-12,1,2.svg             fig03
    merged-MJOfig-Emean.svg                            fig04
    merged-MJOfig-Eabsmean.svg                         fig05
    merged-overlaping-lhf_msl-NPACATL-Emean-nonMJO.svg fig06
    merged-UVTZ-gh-500-NPACATL-Emean-12,1,2.svg        figS01
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
