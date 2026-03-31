#!/bin/bash

source 000_setup.sh

python3 ./src/make_strictMJO_category.py      \
    --output-root $gendata_dir                \
    --hist-output $fig_dir/MJO_categories.svg \
    --no-display

