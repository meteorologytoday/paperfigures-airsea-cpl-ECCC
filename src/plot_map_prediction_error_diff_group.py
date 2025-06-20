import xarray as xr
import numpy as np
import pandas as pd
import argparse
import os.path
import tool_fig_config
import scipy
import scipy.stats
import cmocean


def expand_axis(arr, axis=0):
    
    _arr = np.array(arr)
    
    shape = np.array(arr.shape, dtype=int)
    shape[axis] += 1
    
    _arr = np.array(shape, dtype=arr.dtype)
    
    selector1 = [ slice(None, None) for _ in len(shape) ]
    selector2 = [ slice(None, None) for _ in len(shape) ]

    selector1[axis] = slice(0, -1)

    _arr[selector1] = arr
    
    selector1[axis] = -1
    selector2[axis] =  0
    _arr[selector1] = _arr[selector2]

    return arr




parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--input-dir', type=str, help='Input directory.', required=True)
parser.add_argument('--map-projection-name', type=str, help='Map projection', required=True, choices=["PlateCarree", "Orthographic"])
parser.add_argument('--model-versions', type=str, nargs=2, help='Input directory.', required=True)
parser.add_argument('--varset',  type=str, help='Input directory.', default="surf_inst")
parser.add_argument('--varname', type=str, help='Input directory.', default="mean_sea_level_pressure")
parser.add_argument('--year-rng', type=int, nargs=2, help='Range of years', required=True)
parser.add_argument('--months', type=int, nargs="+", help='Month to be processed.', required=True)
parser.add_argument('--level', type=int, help='Selected level if data is 3D.', default=None)
parser.add_argument('--pval-threshold', type=float, help='Month to be processed.', default=0.1)
parser.add_argument('--lead-window', type=int, help='Pentad to be processed.', required=True)
parser.add_argument('--output', type=str, help='Output directory.', default="")
parser.add_argument('--output-error', type=str, help='Output directory.', default="")
parser.add_argument('--plot-lat-rng', type=float, nargs=2, help='Plot range of latitude', default=[-90, 90])
parser.add_argument('--plot-lon-rng', type=float, nargs=2, help='Plot range of latitude', default=[0, 360])
parser.add_argument('--paper', type=int, default=0)


parser.add_argument('--no-display', action="store_true")
args = parser.parse_args()

print(args)

args.paper = args.paper == 1

data = []

var3D = False

selected_years = list(range(args.year_rng[0], args.year_rng[1]+1))
selected_months = args.months

for model_version in args.model_versions:
    
    print("# model_version : ", model_version)

    filenames = []

    for year in selected_years:

        for month in selected_months:
            filenames.append(
                os.path.join(args.input_dir, model_version, "ECCC-S2S_{model_version:s}_{varset:s}::{varname:s}_{yyyymm:s}.nc".format(
                    model_version = model_version,
                    varset  = args.varset,
                    varname = args.varname,
                    yyyymm = pd.Timestamp(year=year, month=month, day=1).strftime("%Y-%m"),
                ))
            )

    print("Reading to load the following files:")
    print(filenames)
    ds = xr.open_mfdataset(filenames, concat_dim="start_ym", combine="nested", engine="netcdf4")
    ds = ds.sel(lead_window=args.lead_window)

    """
    merge_ds = []
    for filename in filenames:
        _ds = xr.open_dataset(filename, engine="netcdf4")
        _ds = _ds.sel(lead_window=args.lead_window)
        merge_ds.append(_ds)

    ds = xr.merge(merge_ds)
    """
    print(ds)


    ds_varnames = dict(
        Emean    = "%s_Emean" % args.varname,
        E2mean   = "%s_E2mean" % args.varname,
        Eabsmean    = "%s_Eabsmean" % args.varname,
        Eabs2mean   = "%s_Eabs2mean" % args.varname,

    )
    
    print(ds[ds_varnames["Emean"]].dims)

    if "level" in ds[ds_varnames["Emean"]].dims:

        print("This is 3D variable!!!!")
        var3D = True
        if args.level is None:
            
            raise Exception("Data is 3D but `--level` is not given.")

        print("Selecting level = %d" % (args.level,))
        ds = ds.sel(level=args.level)


    # Emean
    total_Emean  = ds[ds_varnames["Emean"]].weighted(ds["total_cnt"]).mean(dim="start_ym").rename("total_Emean")
    total_E2mean = ds[ds_varnames["E2mean"]].weighted(ds["total_cnt"]).mean(dim="start_ym").rename("total_E2mean")
    total_Evar = total_E2mean - total_Emean ** 2
    _total_Evar = total_Evar.to_numpy()
    print("Negative total_Evar (possibly due to precision error): ", _total_Evar[_total_Evar < 0])

    print("Fix the small negative ones...")
    _total_Evar[(np.abs(_total_Evar) < 1e-5) & (_total_Evar < 0)] = 0

    print("Negative total_Evar after fixed: ", _total_Evar[_total_Evar < 0])


    # Eabs
    total_Eabsmean  = ds[ds_varnames["Eabsmean"]].weighted(ds["total_cnt"]).mean(dim="start_ym").rename("total_Eabsmean")
    total_Eabs2mean = ds[ds_varnames["Eabs2mean"]].weighted(ds["total_cnt"]).mean(dim="start_ym").rename("total_Eabs2mean")
    total_Eabsvar = total_Eabs2mean - total_Eabsmean ** 2
    _total_Eabsvar = total_Eabsvar.to_numpy()
    print("Negative total_Eabsvar (possibly due to precision error): ", _total_Eabsvar[_total_Eabsvar < 0])

    print("Fix the small negative ones...")
    _total_Eabsvar[(np.abs(_total_Eabsvar) < 1e-5) & (_total_Eabsvar < 0)] = 0

    print("Negative total_Evar after fixed: ", _total_Eabsvar[_total_Eabsvar < 0])
 


    
    total_cnt = ds["total_cnt"].sum(dim="start_ym").rename("total_cnt")
    total_ddof = ds["ddof"].sum(dim="start_ym").rename("total_ddof")

    print("TOTALDDOF: ", total_ddof.to_numpy())


    total_Estd = np.sqrt(total_Evar)
    total_Estderr = total_Estd / total_ddof**0.5

    total_Estd = total_Estd.rename("total_Estd")
    total_Estderr = total_Estderr.rename("total_Estderr")
    
    total_Eabsstd = np.sqrt(total_Eabsvar).rename("total_Eabsstd")



    new_ds = xr.merge([total_Emean, total_Estd, total_Estderr, total_Eabsmean, total_Eabs2mean, total_Eabsstd])
    new_ds = xr.concat([new_ds, new_ds.isel(longitude=slice(0, 1))], dim="longitude")
    new_longitude = new_ds.coords["longitude"].to_numpy()
    new_longitude[-1] = new_longitude[-2] + (new_longitude[1] - new_longitude[0])
    new_ds = new_ds.assign_coords(longitude=new_longitude)

    # total_cnt has to be done sepearately. Otherwise the isel longitude will append another dimension
    new_ds = xr.merge([new_ds, total_cnt, total_ddof])

    data.append(new_ds)

# Do student T-test
diff_ds = data[1] - data[0]
ds_ref = data[0]

pval = np.zeros_like(diff_ds["total_Estd"])
pval_Eabs = np.zeros_like(diff_ds["total_Eabsstd"])

print("Compute p values for Emean")

npdata = []
for i in range(2):
    npdata.append(dict(
        mean = data[i]["total_Emean"].to_numpy(),
        std  = data[i]["total_Estd"].to_numpy(),
        ddof = np.max(data[i]["total_ddof"].to_numpy()),
    ))
 
for j in range(ds_ref.dims["latitude"]):
    for i in range(ds_ref.dims["longitude"]):
        
        _tmp = scipy.stats.ttest_ind_from_stats(
            mean1 = npdata[0]["mean"][j, i],
            std1  = npdata[0]["std"][j, i],
            nobs1 = npdata[0]["ddof"], #* 0 + len(selected_years) * len(selected_months) * 4 * 4, # 4 members, weekly
            mean2 = npdata[1]["mean"][j, i],
            std2  = npdata[1]["std"][j, i],
            nobs2 = npdata[1]["ddof"],# * 0 + len(selected_years) * len(selected_months) * 4 * 4, # 4 members, weekly
            equal_var = False,
            alternative = "two-sided",
        )
        
        pval[j, i] = _tmp.pvalue
        



print("Compute p values for Eabs")

npdata = []
for i in range(2):
    npdata.append(dict(
        mean = data[i]["total_Eabsmean"].to_numpy(),
        std  = data[i]["total_Eabsstd"].to_numpy(),
        ddof = np.max(data[i]["total_ddof"].to_numpy()),
    ))
    
for j in range(ds_ref.dims["latitude"]):
    for i in range(ds_ref.dims["longitude"]):
        
        _tmp = scipy.stats.ttest_ind_from_stats(
            mean1 = npdata[0]["mean"][j, i],
            std1  = npdata[0]["std"][j, i],
            nobs1 = npdata[0]["ddof"], #* 0 + len(selected_years) * len(selected_months) * 4 * 4, # 4 members, weekly
            mean2 = npdata[1]["mean"][j, i],
            std2  = npdata[1]["std"][j, i],
            nobs2 = npdata[1]["ddof"],# * 0 + len(selected_years) * len(selected_months) * 4 * 4, # 4 members, weekly
            equal_var = False,
            alternative = "two-sided",
        )
        
        pval_Eabs[j, i] = _tmp.pvalue
        




plot_infos = dict(

     ci = dict(
        shading_levels = np.linspace(-1, 1, 21) * 10,
        contour_levels = np.linspace(0, 1, 11) * 10,
        factor = 1e-2,
        label = "SIC",
        unit  = "$\\%$",
    ),


    IWV = dict(
        shading_levels = np.linspace(-1, 1, 21) * 2,
        contour_levels = np.linspace(0, 1, 11) * 2,
        factor = 1.0,
        label = "IWV",
        unit  = "$\\mathrm{kg} / \\mathrm{m}^2$",
    ),

    IVT = dict(
        shading_levels = np.linspace(-1, 1, 21) * 30,
        contour_levels = np.linspace(0, 1, 11) * 30,
        factor = 1.0,
        label = "IVT",
        unit  = "$\\mathrm{kg} / \\mathrm{m} / \\mathrm{s}$",
    ),

    IVT_x = dict(
        shading_levels = np.linspace(-1, 1, 21) * 30,
        contour_levels = np.linspace(0, 1, 11) * 30,
        factor = 1.0,
        label = "$\\mathrm{IVT}_x$",
        unit  = "$\\mathrm{kg} / \\mathrm{m} / \\mathrm{s}$",
    ),



    IVT_y = dict(
        shading_levels = np.linspace(-1, 1, 21) * 30,
        contour_levels = np.linspace(0, 1, 11) * 30,
        factor = 1.0,
        label = "$\\mathrm{IVT}_y$",
        unit  = "$\\mathrm{kg} / \\mathrm{m} / \\mathrm{s}$",
    ),




    u10 = dict(
        shading_levels = np.linspace(-1, 1, 21) * 5,
        contour_levels = np.linspace(0, 1, 11) * 10,
        factor = 1.0,
        label = "$ u_\\mathrm{10m} $",
        unit  = "m / s",
    ),

    v10 = dict(
        shading_levels = np.linspace(-1, 1, 21) * 5,
        contour_levels = np.linspace(0, 1, 11) * 10,
        factor = 1.0,
        label = "$ v_\\mathrm{10m} $",
        unit  = "m / s",
    ),



    msl = dict(
        shading_levels = np.linspace(-1, 1, 21) * 2,
        contour_levels = np.linspace(0, 1, 11) * 5,
        factor = 1e2,
        label = "$ P_\\mathrm{MSL} $",
        unit  = "hPa",
    ),

    mslhf = dict(
        shading_levels = np.linspace(-1, 1, 21) * 50,
        contour_levels = np.linspace(0, 1, 11) * 50,
        factor = 1,
        label = "$ H_\\mathrm{lat} $",
        unit  = "$ \\mathrm{W} \\, / \\, \\mathrm{m}^2 $",
    ),

    msshf = dict(
        shading_levels = np.linspace(-1, 1, 21) * 50,
        contour_levels = np.linspace(0, 1, 11) * 50,
        factor = 1,
        label = "$ H_\\mathrm{sen} $",
        unit  = "$ \\mathrm{W} \\, / \\, \\mathrm{m}^2 $",
    ),

    mtp = dict(
        shading_levels = np.linspace(-1, 1, 21) * 1,
        contour_levels = np.linspace(0, 1, 5) * 2,
        factor = 1,
        label = "$P_{\\mathrm{rain}}$",
        unit  = "$ \\mathrm{mm} / \\mathrm{day} $",
    ),


    sst = dict(
        shading_levels = np.linspace(-1, 1, 21) * 1,
        contour_levels = np.linspace(0, 1, 5) * 1,
        factor = 1,
        label = "SST",
        unit  = "$ \\mathrm{K} $",
    ),

    gh = dict(
        shading_levels = np.linspace(-1, 1, 21) * 20,
        contour_levels = np.linspace(0, 1, 5) * 20,
        factor = 1,
        label = "$Z_{%d}$",
        unit  = "$ \\mathrm{m} $",
    ),


)

print("Loading matplotlib...")

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
from mpl_toolkits.axes_grid1.axes_divider import make_axes_locatable
import cartopy.crs as ccrs
from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER

from matplotlib import rcParams

print("done")

from scipy.stats import ttest_ind_from_stats

rcParams['axes.titlepad'] = 10

projection_name = args.map_projection_name

if projection_name == "PlateCarree":

    plot_lon_l = args.plot_lon_rng[0] % 360.0
    plot_lon_r = args.plot_lon_rng[1] % 360.0
    plot_lat_b = args.plot_lat_rng[0]
    plot_lat_t = args.plot_lat_rng[1]

    if plot_lon_r == 0.0:
        plot_lon_r = 360.0 # exception

    # rotate
    if plot_lon_l > plot_lon_r:
        plot_lon_l -= 360.0
        


    cent_lon = (plot_lon_l + plot_lon_r) / 2
    map_projection = ccrs.PlateCarree(central_longitude=cent_lon)
    
elif projection_name == "Orthographic":
    
    map_projection = ccrs.Orthographic(260, 90)
    

map_transform = ccrs.PlateCarree()

h = 5
ncol = 1
nrow = 1

if projection_name == "PlateCarree":

    w_over_h = (plot_lon_r - plot_lon_l) / (plot_lat_t - plot_lat_b)

elif projection_name == "Orthographic":
    
    w_over_h = 1

w = h * w_over_h


figsize, gridspec_kw = tool_fig_config.calFigParams(
    w = w,
    h = h,
    wspace = 1.0,
    hspace = 0.5,
    w_left = 1.0,
    w_right = 2.2,
    h_bottom = 1.0,
    h_top = 1.0,
    ncol = ncol,
    nrow = nrow,
)


fig, ax = plt.subplots(
    nrow, ncol,
    figsize=figsize,
    subplot_kw=dict(projection=map_projection, aspect="auto"),
    gridspec_kw=gridspec_kw,
    constrained_layout=False,
    squeeze=False,
)

cmap = cmocean.cm.balance


_ax = ax[0, 0]

plot_info = plot_infos[args.varname]

if args.paper:

    label = plot_info["label"]
    if var3D:
        label = label % (args.level,)

    if np.all(np.array(args.months) == np.array([12, 1, 2])):
        start_time_label = "\\phi_{\\mathrm{DJF}}" 
    else:
        start_time_label = "\\phi"

    _ax.set_title("$\\Delta B ($%s$; %s, p = %d)$" % (
        label,
        start_time_label,
        args.lead_window+1,
    ), size=18)

else:

    _ax.set_title("[%s minus %s] %04d-%04d month=%s, lead_window=%d.\np value = %.2f" % (
        args.model_versions[1],
        args.model_versions[0],
        args.year_rng[0],
        args.year_rng[1],
        ", ".join([ "%02d" % m for m in args.months]),
        args.lead_window,
        args.pval_threshold,
    ), size=18)



coords = diff_ds.coords

_shading = diff_ds["total_Emean"].to_numpy() / plot_info["factor"]
mappable = _ax.contourf(
    coords["longitude"], coords["latitude"],
    _shading,
    levels=plot_info["shading_levels"],
    cmap=cmap, 
    extend="both", 
    transform=map_transform,
)

"""
# Plot the standard deviation
_contour = ((data[0]["total_Estderr"]**2 + data[1]["total_Estderr"]**2)/2)**0.5 / plot_info["factor"]
#_contour = (data[0]["total_Estd"] + data[1]["total_Estd"]) / 2 / plot_info["factor"]
cs = _ax.contour(coords["longitude"], coords["latitude"], _contour, levels=plot_info["contour_levels"], colors="k", linestyles='-',linewidths=1, transform=proj, alpha=0.8, zorder=10)
_ax.clabel(cs, fmt="%.1f")
"""

#_contour = pval
#cs = _ax.contour(coords["longitude"], coords["latitude"], _contour, levels=[0.1,], colors="k", linestyles='-',linewidths=1, transform=proj, alpha=0.8, zorder=10)
#_ax.clabel(cs, fmt="%.1f")


# Plot the hatch to denote significant data
_dot = np.zeros_like(pval)
#_dot[:] = np.nan

_significant_idx =  (pval < args.pval_threshold) 
_dot[ _significant_idx                 ] = 0.75
_dot[ np.logical_not(_significant_idx) ] = 0.25

cs = _ax.contourf(coords["longitude"], coords["latitude"], _dot, colors='none', levels=[0, 0.5, 1], hatches=[None, "..."], transform=map_transform)

# Remove the contour lines for hatches 
for _, collection in enumerate(cs.collections):
    collection.set_edgecolor((.2, .2, .2))
    collection.set_linewidth(0.)

for __ax in [_ax, ]: 

    gl = __ax.gridlines(crs=map_transform, draw_labels=True,
                      linewidth=1, color='gray', alpha=0.5, linestyle='--')

    gl.xlabels_top   = False
    gl.ylabels_right = False

    #gl.xlocator = mticker.FixedLocator(np.arange(-180, 181, 30))
    #gl.xlocator = mticker.FixedLocator([120, 150, 180, -150, -120])#np.arange(-180, 181, 30))
    #gl.ylocator = mticker.FixedLocator([10, 20, 30, 40, 50])
    
    gl.xformatter = LONGITUDE_FORMATTER
    gl.yformatter = LATITUDE_FORMATTER
    gl.xlabel_style = {'size': 12, 'color': 'black'}
    gl.ylabel_style = {'size': 12, 'color': 'black'}

    __ax.set_global()
    #__ax.gridlines()
    __ax.coastlines(color='gray')

    if projection_name == "PlateCarree":
        __ax.set_extent([plot_lon_l, plot_lon_r, plot_lat_b, plot_lat_t], crs=map_transform)


cax = tool_fig_config.addAxesNextToAxes(fig, _ax, "right", thickness=0.3, spacing=0.3, flag_ratio_thickness=False, flag_ratio_spacing=False)
cb = plt.colorbar(mappable, cax=cax, orientation="vertical", pad=0.00)

unit_str = "" if plot_info["unit"] == "" else " [ %s ]" % (plot_info["unit"],)

if args.paper:
    label = unit_str

else:

    label = plot_info["label"]
    if var3D:
        label = label % (args.level,)
    
    label = "%s\n%s" % (label, unit_str)

cb.ax.set_ylabel(label, size=25)


if not args.no_display:
    plt.show()

if args.output != "":

    print("Saving output: ", args.output)    
    fig.savefig(args.output, dpi=200)

print("Finished.")

if args.output_error != "":


    print("Plotting error differnce")

    ncol = 1
    nrow = 1


    figsize, gridspec_kw = tool_fig_config.calFigParams(
        w = w,
        h = h,
        wspace = 1.0,
        hspace = 0.5,
        w_left = 1.0,
        w_right = 2.2,
        h_bottom = 1.0,
        h_top = 1.0,
        ncol = ncol,
        nrow = nrow,
    )


    fig, ax = plt.subplots(
        nrow, ncol,
        figsize=figsize,
        subplot_kw=dict(projection=map_projection, aspect="auto"),
        gridspec_kw=gridspec_kw,
        constrained_layout=False,
        squeeze=False,
    )

    cmap = cmocean.cm.balance


    _ax = ax[0, 0]

    plot_info = plot_infos[args.varname]
    
    if args.paper:

        label = plot_info["label"]
        if var3D:
            label = label % (args.level,)

        if np.all(np.array(args.months) == np.array([12, 1, 2])):
            start_time_label = "\\phi_{\\mathrm{DJF}}" 
        else:
            start_time_label = "\\phi"

        _ax.set_title("$\\Delta A ($%s$; %s, p = %d)$" % (
            label,
            start_time_label,
            args.lead_window+1,
        ), size=18)


    else:

        _ax.set_title("[%s minus %s] abs %04d-%04d month=%s, lead_window=%d" % (
            args.model_versions[1],
            args.model_versions[0],
            args.year_rng[0],
            args.year_rng[1],
            ", ".join([ "%02d" % m for m in args.months]),
            args.lead_window,
        ), size=18)

    coords = diff_ds.coords

    diff_da = data[1]["total_Eabsmean"] - data[0]["total_Eabsmean"]

    _shading = diff_da.to_numpy() / plot_info["factor"]
    mappable = _ax.contourf(
        coords["longitude"], coords["latitude"],
        _shading,
        levels=plot_info["shading_levels"] * 0.5,
        cmap=cmap, 
        extend="both", 
        transform=map_transform,
    )
    
    _dot = np.zeros_like(pval_Eabs)
    _significant_idx =  (pval_Eabs < args.pval_threshold) 
    _dot[ _significant_idx                 ] = 0.75
    _dot[ np.logical_not(_significant_idx) ] = 0.25
    cs = _ax.contourf(coords["longitude"], coords["latitude"], _dot, colors='none', levels=[0, 0.5, 1], hatches=[None, "..."], transform=map_transform)

    # Remove the contour lines for hatches 
    for _, collection in enumerate(cs.collections):
        collection.set_edgecolor((.2, .2, .2))
        collection.set_linewidth(0.)


    for __ax in [_ax, ]: 

        gl = __ax.gridlines(crs=map_transform, draw_labels=True,
                          linewidth=1, color='gray', alpha=0.5, linestyle='--')

        gl.xlabels_top   = False
        gl.ylabels_right = False

        #gl.xlocator = mticker.FixedLocator(np.arange(-180, 181, 30))
        #gl.xlocator = mticker.FixedLocator([120, 150, 180, -150, -120])#np.arange(-180, 181, 30))
        #gl.ylocator = mticker.FixedLocator([10, 20, 30, 40, 50])
        
        gl.xformatter = LONGITUDE_FORMATTER
        gl.yformatter = LATITUDE_FORMATTER
        gl.xlabel_style = {'size': 12, 'color': 'black'}
        gl.ylabel_style = {'size': 12, 'color': 'black'}

        __ax.set_global()
        #__ax.gridlines()
        __ax.coastlines(color='gray')

        if projection_name == "PlateCarree":
            __ax.set_extent([plot_lon_l, plot_lon_r, plot_lat_b, plot_lat_t], crs=map_transform)



    cax = tool_fig_config.addAxesNextToAxes(fig, _ax, "right", thickness=0.03, spacing=0.05)
    cb = plt.colorbar(mappable, cax=cax, orientation="vertical", pad=0.00)

    unit_str = "" if plot_info["unit"] == "" else " [ %s ]" % (plot_info["unit"],)
    if args.paper:
        label = unit_str
    else:
        label = plot_info["label"]
        if var3D:
            label = label % (args.level,)
        
        label = "%s\n%s" % (label, unit_str)

    cb.ax.set_ylabel(label, size=25)



    label = plot_info["label"]
    if var3D:
        label = label % (args.level,)

    cb.ax.set_ylabel("%s\n%s" % (label, unit_str), size=25)


    if args.output_error != "":

        print("Saving output: ", args.output_error) 
        fig.savefig(args.output_error, dpi=200)

    print("Finished.")




