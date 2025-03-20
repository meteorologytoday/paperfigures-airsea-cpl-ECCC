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

echo "Figure 1: Estd error"
svg_stack.py                                \
    --direction=h                           \
    $fig_dir/fig_worldmap_prediction_error_diff_Estd_global_pentad-5-multimonths/group-GEPS6sub1/NPAC/surf_inst-msl_1998-2017_10,11,12,1,2,3_lead-pentad-1.svg                       \
    $fig_dir/fig_worldmap_prediction_error_diff_Estd_global_pentad-5-multimonths/group-GEPS6sub1/NATL/surf_inst-msl_1998-2017_10,11,12,1,2,3_lead-pentad-1.svg                       \
    > $fig_dir/merged-Estd-msl.svg

svg_stack.py                                \
    --direction=h                           \
    $fig_dir/fig_worldmap_prediction_error_diff_Estd_global_pentad-5-multimonths/group-GEPS6sub1/NPAC/UVTZ-gh-850_1998-2017_10,11,12,1,2,3_lead-pentad-1.svg \
    $fig_dir/fig_worldmap_prediction_error_diff_Estd_global_pentad-5-multimonths/group-GEPS6sub1/NATL/UVTZ-gh-850_1998-2017_10,11,12,1,2,3_lead-pentad-1.svg \
    > $fig_dir/merged-Estd-850.svg

svg_stack.py \
    --direction=v \
    $fig_dir/merged-Estd-msl.svg \
    $fig_dir/merged-Estd-850.svg \
    > $fig_dir/merged-Estd-msl850.svg


echo "Figure 2: Cpl effect"
svg_stack.py                                \
    --direction=h                           \
    $fig_dir/fig_worldmap_prediction_error_diff_global_pentad-5-multimonths/group-GEPS6sub1/NPAC/surf_inst-msl_1998-2017_10,11,12,1,2,3_lead-pentad-1.svg                       \
    $fig_dir/fig_worldmap_prediction_error_diff_global_pentad-5-multimonths/group-GEPS6sub1/NATL/surf_inst-msl_1998-2017_10,11,12,1,2,3_lead-pentad-1.svg                       \
    > $fig_dir/merged-Emean-msl.svg

svg_stack.py                                \
    --direction=h                           \
    $fig_dir/fig_worldmap_prediction_error_diff_global_pentad-5-multimonths/group-GEPS6sub1/NPAC/UVTZ-gh-850_1998-2017_10,11,12,1,2,3_lead-pentad-1.svg \
    $fig_dir/fig_worldmap_prediction_error_diff_global_pentad-5-multimonths/group-GEPS6sub1/NATL/UVTZ-gh-850_1998-2017_10,11,12,1,2,3_lead-pentad-1.svg \
    > $fig_dir/merged-Emean-850.svg

svg_stack.py \
    --direction=v \
    $fig_dir/merged-Emean-msl.svg \
    $fig_dir/merged-Emean-850.svg \
    > $fig_dir/merged-Emean-msl850.svg




name_pairs=(
    merged-Estd-msl850.svg      fig01
    merged-Emean-msl850.svg     fig02
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
