#!/bin/bash


nproc=1

while getopts "p:" arg ; do
    case $arg in
        p)
        echo "Set nproc=$OPTARG"
        nproc=$OPTARG
        ;;
    esac
done

echo "nproc = $nproc"

source 999_trapkill.sh
source 000_setup.sh

mkdir -p $fig_dir

plot_codes=(

    # Fig 1
    $sh 501_plot_map_error_diff_group.sh
    $sh 502_plot_map_error_by_ym_2var.sh
    $sh 506_plot_map_error_diff_MJO_2vars.sh
    $sh 601_plot_timeseries.sh
    $sh 602_plot_timeseries_by_MJO.sh
#    $sh 503_plot_map_error_diff_group_MJO.sh
#    $sh 504_plot_map_error_diff_group_2vars.sh
#    $sh 505_plot_map_error_diff_ymgroup_2vars.sh
 
)

nparams=2
N=$(( ${#plot_codes[@]} / $nparams ))
echo "We have $N file(s) to run..."
for i in $( seq 1 $(( ${#plot_codes[@]} / $nparams )) ) ; do
   
    echo "#### This is the $i-th command. ####"

    {
        PROG="${plot_codes[$(( (i-1) * $nparams + 0 ))]}"
        FILE="${plot_codes[$(( (i-1) * $nparams + 1 ))]}"
        echo "=====[ Running file: $FILE ]====="
        cmd="$PROG $FILE" 
        echo ">> $cmd"
        eval "$cmd"
        echo "Return code $?"
    } &

    proc_cnt=$(( $proc_cnt + 1 ))
    
    if (( $proc_cnt >= $nproc )) ; then
        echo "Max proc reached: $nproc"
        wait
        proc_cnt=0
    fi
         
done


wait

echo "Figures generation is complete."
echo "Please run 04_postprocess_figures.sh to postprocess the figures."
