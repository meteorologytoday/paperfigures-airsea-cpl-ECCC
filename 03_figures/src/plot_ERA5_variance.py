
print("Loading library... ", end="")
import xarray as xr
import numpy as np
import pandas as pd
import argparse
import tool_fig_config
import scipy
import map_regions
from pathlib import Path
print("Done.")

#gendata/analysis/output_analysis_variance/sst/ERA5-variance_sea_surface_temperature::sst-2017-03-31.nc
def genFilename(
    root,
    varset,
    varname,
    dt,
):

    root = Path(root)
    dt_str = dt.strftime("%Y-%m-%d")
    return root / varset / f"ERA5-variance_{varset:s}::{varname:s}-{dt_str:s}.nc"



if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--input-root', type=str, help='Input directory.', required=True)
    parser.add_argument('--varset',  type=str, help='Input directory.', default="surf_inst")
    parser.add_argument('--varname', type=str, help='Input directory.', default="mean_sea_level_pressure")
    parser.add_argument('--year-range', type=int, nargs=2, help='Year range', required=True)
    parser.add_argument('--region', type=str, help='Output directory.', required=True)
    parser.add_argument('--output', type=str, help='Output directory.', default="")

    parser.add_argument('--thumbnail-numbering-style', type=str, default="abc", choices=["abc", "123"])
    parser.add_argument('--no-display', action="store_true")
    parser.add_argument('--cached-file', type=str, help='Output directory.', default=None)
    parser.add_argument('--ignore-cached', action="store_true")

    args = parser.parse_args()

    print(args)

    data = []
   

    load_cache = (args.cached_file is not None) and (not args.ignore_cached) and Path(args.cached_file).exists()

    if load_cache:
        print("Load cached file: ", args.cached_file)
        data = xr.open_dataset(args.cached_file)

    else: 
        input_root = Path(args.input_root)
        years = np.arange(args.year_range[0], args.year_range[1])
        for year in years:
            
            fnames = []
            
            for dt in pd.date_range(f"{year:04d}-12-01", f"{year+1:04d}-04-30", inclusive="both"):
            
                fnames.append(
                    genFilename(input_root, args.varset, args.varname, dt)
                )

            ds = xr.open_mfdataset(fnames).sel(region=args.region)
            ds = ds.groupby("time.month").mean("time")
            ds = ds.expand_dims(dict(year = [year,]))
      
            data.append(ds)
           
        data = xr.merge(data)

        if args.cached_file is not None:
            print("Output cached file: ", args.cached_file)
            data.to_netcdf(args.cached_file)

    print("Merged data:", data) 

    varname = f"{args.varname:s}_XVARPATT"
    print("Total")

    da = data[varname].sel(month=[12, 1, 2, 3, 4])
    y    = da.mean().to_numpy()
    yerr = da.std().to_numpy()

    print("Total mean: ", y)
    print("Total std: ", yerr)

    print("Loading matplotlib...", end="")

    import matplotlib as mplt
    if args.no_display:
        mplt.use("Agg")
    else:
        mplt.use("TkAgg")


    import matplotlib.pyplot as plt
    from matplotlib.patches import Rectangle
    import matplotlib.transforms as transforms
    from matplotlib.dates import DateFormatter
    import matplotlib.ticker as mticker
    from matplotlib import rcParams

    from mpl_toolkits.axes_grid1.axes_divider import make_axes_locatable

    print("done")

    ncol = 1
    nrow = 1

    h = 4
    w = 6

    figsize, gridspec_kw = tool_fig_config.calFigParams(
        w = w,
        h = h,
        wspace = 1.0,
        hspace = 0.5,
        w_left = 1.0,
        w_right = 1.0,
        h_bottom = 1.0,
        h_top = 1.0,
        ncol = ncol,
        nrow = nrow,
    )

    fig, ax = plt.subplots(
        nrow, ncol,
        figsize=figsize,
        subplot_kw=dict(aspect="auto"),
        gridspec_kw=gridspec_kw,
        constrained_layout=False,
        squeeze=False,
    )
    
    _ax = ax[0, 0]
    
    varname = f"{args.varname:s}_XVARPATT"

    da = data[varname].sel(month=[12, 1, 2, 3, 4])

    x    = np.arange(len(da.coords["month"]))
    y    = da.mean(dim="year").to_numpy()
    yerr = da.std(dim="year").to_numpy()

    lc = "red"

    _ax.errorbar(
        x,
        y,
        yerr = yerr,
        capsize=5,
        marker="o",
        markersize=12,
        markeredgewidth=2,
        linewidth=2,
        linestyle="solid",
        color=lc,
        markerfacecolor='none',
    )

    _ax.set_xticks(x, labels=["%02d" % (m,) for m in da.coords["month"].to_numpy()])

    """

    for i, (year, ds) in enumerate(zip(years, data)):
       
        x = ds.coords["month"]
        y = ds[f"{args.varname:s}_XVARPATT"].to_numpy()
        
        _ax.plot(x, y, marker="o", markersize=15, color="#888888")
    """

    _ax.grid()
    _ax.set_ylabel("[ $\\mathrm{K}^2$ ]")
    if not args.no_display:
        plt.show()

    if args.output != "":

        print("Saving output: ", args.output)    
        fig.savefig(args.output, dpi=200)

    print("Finished.")

