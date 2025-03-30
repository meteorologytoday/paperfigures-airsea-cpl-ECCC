#!/bin/bash
py=python3
sh=bash


fig_dir=figures
finalfig_dir=./final_figures
data_dir=./data
gendata_dir=./gendata
lib_dir=./lib
export PYTHONPATH=$( realpath "$( pwd )/${lib_dir}"):$PYTHONPATH


mkdir -p $fig_dir
mkdir -p $gendata_dir

days_per_window=5
lead_windows=6

paper=1


year_beg=1998
year_end=2017


