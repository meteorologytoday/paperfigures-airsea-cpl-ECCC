# README

This repository contains the code to generate figures of article ``Impacts of Air-sea Coupling on Systematic Errors in Medium-Range Winter Forecasts over the North Pacific and North Atlantic'' (submitted to EGU-WCD).


User can download preprocessed data from zenodo repository [https://doi.org/10.5281/zenodo.16938865](https://doi.org/10.5281/zenodo.16938865). Extract the folder `analysis` into the folder `data`.

## Run order

- First run `002_make_figures.sh`.
- Then run `003_postprocess`.
- The produced paper figures will be in the folder `final_figures`.

## Plotting Codes

- `501_plot_map_error_diff_group.sh` plots one variable groupped by year-month.

