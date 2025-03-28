import xarray as xr
import numpy as np
import pandas as pd
import argparse
import os.path
import tool_fig_config
import scipy
import scipy.stats
import cmocean

def loadVariable(
    model_version,
    varset,
    varname,
    selected_categories, 
    lead_window,
    level,
):

    filenames = []
    for category in selected_categories:
        filenames.append(
            os.path.join(args.input_dir, model_version, "ECCC-S2S_{model_version:s}_{varset:s}::{varname:s}_category-{category:s}.nc".format(
                model_version = model_version,
                varset  = varset,
                varname = varname,
                category = category,
            ))
        )

    print("Reading to load the following files:")
    print(filenames)
    ds = xr.open_mfdataset(filenames, concat_dim="category", combine="nested", engine="netcdf4")
    print(ds)
    ds = ds.sel(lead_window=lead_window)

    ds_varnames = dict(
        Emean    = "%s_Emean" % varname,
        E2mean   = "%s_E2mean" % varname,
        Eabsmean    = "%s_Eabsmean" % varname,
        Eabs2mean   = "%s_Eabs2mean" % varname,
    )
    

    if "level" in ds[ds_varnames["Emean"]].dims:

        print("This is 3D variable!!!!")
        var3D = True
        if level is None:
            
            raise Exception("Data is 3D but `--level` is not given.")

        print("Selecting level = %d" % (level,))
        ds = ds.sel(level=level)


    total_Emean  = ds[ds_varnames["Emean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_Emean")
    total_E2mean = ds[ds_varnames["E2mean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_E2mean")
    total_Evar = total_E2mean - total_Emean ** 2
    _total_Evar = total_Evar.to_numpy()
    print("Negative total_Evar (possibly due to precision error): ", _total_Evar[_total_Evar < 0])

    print("Fix the small negative ones...")
    _total_Evar[(np.abs(_total_Evar) < 1e-5) & (_total_Evar < 0)] = 0

    print("Number of negative total_Evar after fixed: ", np.sum(_total_Evar < 0))

    # Eabs
    total_Eabsmean  = ds[ds_varnames["Eabsmean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_Eabsmean")
    total_Eabs2mean = ds[ds_varnames["Eabs2mean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_Eabs2mean")
    total_Eabsvar = total_Eabs2mean - total_Eabsmean ** 2
    _total_Eabsvar = total_Eabsvar.to_numpy()
    print("Negative total_Eabsvar (possibly due to precision error): ", _total_Eabsvar[_total_Eabsvar < 0])

    print("Fix the small negative ones...")
    _total_Eabsvar[(np.abs(_total_Eabsvar) < 1e-5) & (_total_Eabsvar < 0)] = 0

    print("Negative total_Evar after fixed: ", _total_Eabsvar[_total_Eabsvar < 0])
 
    total_cnt = ds["total_cnt"].sum(dim="category").rename("total_cnt")
    total_ddof = ds["ddof"].sum(dim="category").rename("total_ddof")

    total_Estd = np.sqrt(total_Evar).rename("total_Estd")
    total_Estderr = (total_Estd / total_ddof**0.5).rename("total_Estderr")

    total_Eabsstd = np.sqrt(total_Eabsvar).rename("total_Eabsstd")


    new_ds = xr.merge([total_Emean, total_Estd, total_Estderr, total_Eabsmean, total_Eabs2mean, total_Eabsstd])
    new_ds = xr.concat([new_ds, new_ds.isel(longitude=slice(0, 1))], dim="longitude")
    new_longitude = new_ds.coords["longitude"].to_numpy()
    new_longitude[-1] = new_longitude[-2] + (new_longitude[1] - new_longitude[0])
    new_ds = new_ds.assign_coords(longitude=new_longitude)

    # total_cnt has to be done sepearately. Otherwise the isel longitude will append another dimension
    new_ds = xr.merge([new_ds, total_cnt, total_ddof])


    return new_ds

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--input-dir', type=str, help='Input directory.', required=True)
parser.add_argument('--map-projection-name', type=str, help='Map projection', required=True, choices=["PlateCarree", "Orthographic"])
parser.add_argument('--model-versions', type=str, nargs=2, help='Input directory.', required=True)
parser.add_argument('--varset',  type=str, help='Input directory.', default="surf_inst")
parser.add_argument('--varname', type=str, help='Input directory.', default="mean_sea_level_pressure")

parser.add_argument('--cntr-varset',  type=str, help='Input directory.', default=None)
parser.add_argument('--cntr-varname', type=str, help='Input directory.', default=None)
parser.add_argument('--cntr-level', type=int, help='Selected level if data is 3D.', default=None)

parser.add_argument('--extra-title', type=str, help='Input directory.', default="")
parser.add_argument('--category', type=str, nargs="+", help='categories needs to be count', required=True)
parser.add_argument('--level', type=int, help='Selected level if data is 3D.', default=None)
parser.add_argument('--pval-threshold', type=float, help='Month to be processed.', default=0.1)
parser.add_argument('--lead-window', type=int, help='Pentad to be processed.', required=True)
parser.add_argument('--output', type=str, help='Output directory.', default="")
parser.add_argument('--output-error', type=str, help='Output directory.', default="")
parser.add_argument('--plot-lat-rng', type=float, nargs=2, help='Plot range of latitude', default=[-90, 90])
parser.add_argument('--plot-lon-rng', type=float, nargs=2, help='Plot range of latitude', default=[0, 360])


parser.add_argument('--no-display', action="store_true")
args = parser.parse_args()

print(args)

has_cntr = (args.cntr_varset is not None) and (args.cntr_varname is not None)


data = []
cntr_data = []
var3D = False

selected_categories = args.category


for model_version in args.model_versions:
    print("# model_version : ", model_version)
    ds = loadVariable(
        model_version,
        args.varset,
        args.varname,
        selected_categories, 
        args.lead_window,
        args.level,
    )   
    data.append(ds)

    if has_cntr:
        cntr_data.append(
            loadVariable(
                model_version,
                args.cntr_varset,
                args.cntr_varname,
                selected_categories, 
                args.lead_window,
                args.cntr_level,
            ),
        )

# Do student T-test
diff_ds = data[1] - data[0]
ds_ref = data[0]

if has_cntr:
    diff_ds_cntr = cntr_data[1] - cntr_data[0]

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
        label = "$ P_\\mathrm{sfc} $",
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
from matplotlib import rcParams



from mpl_toolkits.axes_grid1.axes_divider import make_axes_locatable
import cartopy.crs as ccrs
from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER

rcParams['contour.negative_linestyle'] = 'dashed'

print("done")

from scipy.stats import ttest_ind_from_stats


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

fig.suptitle("[%s minus %s] category=%s, lead_window=%d.\np value = %.2f" % (
    args.model_versions[1],
    args.model_versions[0],
    ", ".join(args.category),
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


if has_cntr:

    cntr_plot_info = plot_infos[args.cntr_varname]
    _cntr = diff_ds_cntr["total_Emean"].to_numpy() / cntr_plot_info["factor"]
    cs = _ax.contour(coords["longitude"], coords["latitude"], _cntr, levels=cntr_plot_info["contour_levels"], colors="k",linewidths=1, transform=map_transform, alpha=0.8, zorder=10)
    _ax.clabel(cs, fmt="%.1f")

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



cax = tool_fig_config.addAxesNextToAxes(fig, _ax, "right", thickness=0.03, spacing=0.05)
cb = plt.colorbar(mappable, cax=cax, orientation="vertical", pad=0.00)

unit_str = "" if plot_info["unit"] == "" else " [ %s ]" % (plot_info["unit"],)

label = plot_info["label"]
if var3D:
    label = label % (args.level,)

cb.ax.set_ylabel("%s\n%s" % (label, unit_str), size=25)


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

    fig.suptitle("[%s minus %s] abs category=%s" % (
        args.model_versions[1],
        args.model_versions[0],
        ",".join(args.category),
    ), size=18)

    coords = diff_ds.coords

    diff_da = data[1]["total_Eabsmean"] - data[0]["total_Eabsmean"]

    _shading = diff_da.to_numpy() / plot_info["factor"]
    mappable = _ax.contourf(
        coords["longitude"], coords["latitude"],
        _shading,
        levels=plot_info["shading_levels"],
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


    label = plot_info["label"]
    if var3D:
        label = label % (args.level,)

    cb.ax.set_ylabel("%s\n%s" % (label, unit_str), size=25)


    if args.output_error != "":

        print("Saving output: ", args.output_error) 
        fig.savefig(args.output_error, dpi=200)

    print("Finished.")



