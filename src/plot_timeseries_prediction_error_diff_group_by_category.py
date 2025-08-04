import xarray as xr
import numpy as np
import pandas as pd
import argparse
import tool_fig_config
import cmocean
import data_loader

def drop_element(arr, drop_elm):
    new_arr = []
    
    for elm in arr:
        if elm == drop_elm:
            continue

        new_arr.append(elm)


    return np.array(new_arr)



parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--input-dir', type=str, help='Input directory.', required=True)
parser.add_argument('--model-versions', type=str, nargs="+", help='Input directory.', required=True)
parser.add_argument('--varset',  type=str, help='Input directory.', default="surf_inst")
parser.add_argument('--varname', type=str, help='Input directory.', default="mean_sea_level_pressure")

parser.add_argument('--extra-title', type=str, help='Input directory.', default="")
parser.add_argument('--category', type=str, nargs="+", help='categories needs to be count', required=True)
parser.add_argument('--category-label', type=str, help='categories needs to be count', default=None)
parser.add_argument('--start-time-label', type=str, help='categories needs to be count', default=None)
parser.add_argument('--level', type=int, help='Selected level if data is 3D.', default=None)
parser.add_argument('--pval-threshold', type=float, help='Month to be processed.', default=0.1)
parser.add_argument('--lead-window-range', type=int, nargs=2, help='Pentad to be processed.', required=True)
parser.add_argument('--output', type=str, help='Output directory.', default="")
parser.add_argument('--output-error', type=str, help='Output directory.', default="")
parser.add_argument('--lat-rng', type=float, nargs=2, help='Plot range of latitude', default=[-90, 90])
parser.add_argument('--lon-rng', type=float, nargs=2, help='Plot range of latitude', default=[0, 360])
parser.add_argument('--paper', type=int, default=0)
parser.add_argument('--font-size-factor', type=float, default=None)

parser.add_argument('--thumbnail-numbering-style', type=str, default="abc", choices=["abc", "123"])
parser.add_argument('--thumbnail-numbering-Eabs', type=int, default=-1)

parser.add_argument('--no-display', action="store_true")
args = parser.parse_args()

print(args)

args.paper = args.paper == 1

font_size_factor = 1

data = []
var3D = False

selected_categories = args.category

for model_version in args.model_versions:
    
    print("# model_version : ", model_version)
    ds, var3D = data_loader.loadVariable_leadwindowrange(
        args.input_dir,
        model_version,
        args.varset,
        args.varname,
        selected_categories, 
        args.lead_window_range,
        args.level,
        verbose=False,
        #lat_rng = args.lat_rng,
        #lon_rng = args.lon_rng,
    )   

    lat = ds.coords["latitude"]
    lon = ds.coords["longitude"] % 360.0
    wgt = xr.apply_ufunc(np.cos, lat * np.pi/180.0)
    
    ds = ds.where(
        ( lat >= args.lat_rng[0] ) 
        & ( lat <= args.lat_rng[1] ) 
        & ( lon >= args.lon_rng[0] ) 
        & ( lon <= args.lon_rng[1] ) 
    )

    ds = ds**2
    ds = ds.weighted(wgt).mean(dim=["latitude", "longitude"], skipna=True)
    ds = ds**0.5

    data.append(ds)

plot_infos = dict(

    mtp = dict(
        shading_levels = np.linspace(-1, 1, 21) * 1,
        contour_levels = drop_element(np.linspace(-1, 1, 9) * 2, 0.0),
        factor = 1,
        label = "$P_{\\mathrm{rain}}$",
        unit  = "$ \\mathrm{mm} / \\mathrm{day} $",
    ),


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
        contour_levels = drop_element(np.linspace(-1, 1, 13) * 30, 0.0),
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
        contour_levels = drop_element(np.linspace(-1, 1, 21) * 5, 0.0),
        factor = 1e2,
        label = "MSLP",#$ P_\\mathrm{MSL} $",
        unit  = "hPa",
    ),

    mslhf = dict(
        shading_levels = np.linspace(-1, 1, 13) * 30,
        contour_levels = np.linspace(0, 1, 11) * 30,
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

rcParams['contour.negative_linestyle'] = 'dashed'

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
    w_right = 2.5,
    h_bottom = 1.0,
    h_top = 1.0,
    ncol = ncol,
    nrow = nrow,
)


fig, ax = plt.subplots(
    nrow, ncol,
    figsize=figsize,
    gridspec_kw=gridspec_kw,
    constrained_layout=False,
    squeeze=False,
)

_ax = ax[0, 0]
plot_info = plot_infos[args.varname]

if args.paper:

    label = plot_info["label"]
    if var3D:
        label = label % (args.level,)

    print("label")

        
    start_time_label = "$\\phi$"
    
    if args.category[0] == "MJO":
        start_time_label = "$\\phi_{\\mathrm{MJO}}$" 
    elif args.category[0] == "nonMJO":
        start_time_label = "$\\phi_{\\mathrm{xMJO}}$" 
   
    if args.category_label is not None:
        start_time_label = args.category_label

    thumbnail_str = ""

    if args.thumbnail_numbering_Eabs != -1:
        if args.thumbnail_numbering_style == "abc":
            thumbnail_str = "({number:s}) ".format(
                number = "abcdefghijklmnopqrstuvwxyz"[args.thumbnail_numbering_Eabs],
            )
        elif args.thumbnail_numbering_style == "123":
            thumbnail_str = "({number:d}) ".format(
                number = args.thumbnail_numbering_Eabs + 1,
            )
    _ax.set_title("%sMean $ \\alpha ($%s$; $%s$)$" % (
        thumbnail_str,
        label,
        start_time_label,
    ), size=18 * font_size_factor)


else:

    _ax.set_title("Abs error category=%s." % (
        ", ".join(args.category),
    ), size=18 * font_size_factor)






x = None
for i, (ds, model_version) in enumerate(zip(data, args.model_versions)):

    print("model_version: ", model_version)

    coords = ds.coords
    x = coords["lead_window"].to_numpy() + 1
    #y = ds["total_Eabsmean"].to_numpy()
    y = ds["total_Emean"].to_numpy()
    
    _ax.plot(
        x,
        y / plot_info["factor"],
        marker="o",
        markersize=12,
        linewidth=2,
        label="%s" % (model_version,),
    )

_ax.set_xlabel("Lead Pentad")
_ax.set_xticks(x)

_ax.legend()
_ax.grid()

unit_str = "" if plot_info["unit"] == "" else " [ %s ]" % (plot_info["unit"],)

if args.paper:
    label = unit_str
else:
    label = plot_info["label"]
    if var3D:
        label = label % (args.level,)
    
    label = "%s\n%s" % (label, unit_str)

_ax.set_ylabel(label, size=25 * font_size_factor)

if not args.no_display:
    plt.show()

if args.output != "":

    print("Saving output: ", args.output)    
    fig.savefig(args.output, dpi=200)

print("Finished.")

