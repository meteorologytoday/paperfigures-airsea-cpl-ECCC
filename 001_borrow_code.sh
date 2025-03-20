#!/bin/bash

source 000_setup.sh


source_dir=/home/t2hsu/SO2_t2hsu/project-assess-S2S-atmocn-coupling


cp -r $source_dir/lib/* $lib_dir/
cp -r $source_dir/gendata/*.txt $gendata_dir/
cp -r $source_dir/data/*.txt $data_dir/
