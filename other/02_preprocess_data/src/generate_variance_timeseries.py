from multiprocessing import Pool
import multiprocessing
from pathlib import Path
import numpy as np
import xarray as xr
import pandas as pd
import argparse


import traceback
import os
import pretty_latlon
pretty_latlon.default_fmt = "%d"

import ECCC_tools
ECCC_tools.init()

import ERA5_loader
import map_regions

def detrend(da, dim, deg):
    
    p = da.polyfit(dim=dim, deg=deg, skipna=True)
    trend = xr.polyval(da.coords[dim], p.polyfit_coefficients)
    
    da_detrended = da - trend

    return da_detrended




parser = argparse.ArgumentParser(
                    prog = 'make_ECCC_AR_objects.py',
                    description = 'Postprocess ECCO data (Mixed-Layer integrated).',
)

#parser.add_argument('--start-months', type=int, nargs="+", required=True)
parser.add_argument('--date-range', nargs=2, type=str, required=True)
parser.add_argument('--output-root', type=str, required=True)
parser.add_argument('--ERA5-varset', type=str, required=True)
parser.add_argument('--ERA5-freq', type=str, required=True)
parser.add_argument('--levels', nargs="+", type=int, help="If variable is 3D.", default=None)
parser.add_argument('--varname', type=str, required=True)
parser.add_argument('--half-window-size', type=int, help="Unit: day.", required=True)
parser.add_argument('--nproc', type=int, default=1)
args = parser.parse_args()
print(args)

output_root = args.output_root

ERA5_freq = args.ERA5_freq
ERA5_varset = args.ERA5_varset
ERA5_varname_long  = args.varname
ERA5_varname_short = ERA5_loader.ERA5_longshortname_mapping[ERA5_varname_long]


regions = list(map_regions.map_regions.keys()) 
regions.sort()

        
test_file = ""
ECCC_ds = ECCC_tools.open_dataset("raw", "surf_avg", "GEPS6", pd.Timestamp("2017-01-02"))

def doJob(job_detail, detect_phase = False):


    result = dict(
        status="UNKNOWN",
        job_detail=job_detail,
    )
 
    
    try: 

        ERA5_varname  = job_detail['ERA5_varname']
        ERA5_varset   = job_detail['ERA5_varset']
        ERA5_freq     = job_detail['ERA5_freq']
        dt            = job_detail['dt']
        half_window_size = pd.Timedelta(days=job_detail['half_window_size'])

        output_root = Path(job_detail["output_root"])
        output_dir = output_root / ERA5_varset

        output_filename = "ERA5-variance_{varset:s}::{varname:s}-{date:s}.nc".format(
            varset        = ERA5_varset,
            varname       = ERA5_varname,
            date = dt.strftime("%Y-%m-%d"),
        )
        
        output_file = output_dir / output_filename
        
        result['output_file'] = output_file
 
        output_dir.mkdir(parents=True, exist_ok=True)

        # First round is just to decide which files
        # to be processed to enhance parallel job 
        # distribution. I use variable `phase` to label
        # this stage.
        file_exists = os.path.isfile(output_file)

        if detect_phase is True:
            result['need_work'] = not file_exists
            result['status'] = 'OK' 
            return result

        
        dts_load = list(pd.date_range(dt - half_window_size, dt + half_window_size, freq="D", inclusive="both"))
        ERA5_da = ERA5_loader.open_dataset_ERA5(
            dts_load,
            ERA5_freq,
            ERA5_varset,
        )[ERA5_varname].mean(dim="time")

        if ERA5_varname_long in [ "mean_surface_sensible_heat_flux", "mean_surface_latent_heat_flux" ]:
            reverse_sign = -1
            print("Var %s need to reverse sign. Now multiply it by %d. " % (ERA5_varname_long, reverse_sign,))
            ERA5_da *= reverse_sign

        if args.varname == "geopotential":
            ERA5_da /= 9.81 
        elif ERA5_varname_long == "total_precipitation":
            print("Var %s need to convert from meter to milli-meter. " % (ERA5_varname_long,))
            ERA5_da *= 1e3



        # Interpolation
        ERA5_da = ERA5_da.interp(
            coords=dict(
                latitude  = ECCC_ds.coords["latitude"],
                longitude = ECCC_ds.coords["longitude"],
            ),
        )
 
        lat = ERA5_da.coords["latitude"]
        lon = ERA5_da.coords["longitude"] % 360.0
        wgt = xr.apply_ufunc(np.cos, lat * np.pi/180.0)
 
        dim = (1, len(regions))


        XMEAN      = np.zeros(dim, dtype=float)
        XVARMEAN   = np.zeros(dim, dtype=float)
        XVARPATT   = np.zeros(dim, dtype=float)
      
        for r, region in enumerate(regions):
            
            lat_rng = np.array(map_regions.map_regions[region]["lat"])
            lon_rng = np.array(map_regions.map_regions[region]["lon"]) % 360.0

            region_idx = (
                ( lat >= lat_rng[0] )
                & ( lat <= lat_rng[1] )
                & ( lon >= lon_rng[0] )
                & ( lon <= lon_rng[1] )
            )
            
            _X   = ERA5_da.where(region_idx)
            _X_detrend = detrend(_X, dim="longitude", deg=1)


            mean_X   = _X_detrend.weighted(wgt).mean(dim=["longitude", "latitude"], skipna=True)
            anom_X   = _X_detrend - mean_X

            XMEAN[0, r]    = mean_X.to_numpy()
            XVARMEAN[0, r] = (mean_X**2.0).to_numpy()
            XVARPATT[0, r] = (anom_X**2.0).weighted(wgt).mean(dim=["longitude", "latitude"], skipna=True).to_numpy()

        # prepping for output
        coords=dict(
            region = regions,
            #latitude = lat,
            time   = [dt,],
        )

        _tmp = dict()
        _tmp["%s_XMEAN"  % ERA5_varname] = (["time", "region"], XMEAN)
        _tmp["%s_XVARMEAN" % ERA5_varname] = (["time", "region"], XVARMEAN)
        _tmp["%s_XVARPATT" % ERA5_varname] = (["time", "region"], XVARPATT)

        output_ds = xr.Dataset(
            data_vars = _tmp,
            coords    = coords,
            attrs = dict(
                description="S2S forecast data RMS.",
            ),
        )
        
        print("Output file: ", output_file)
        output_ds.to_netcdf(output_file, unlimited_dims="time")

        result['status'] = "OK"

    except Exception as e:
        
        result['status'] = "ERROR"
        #traceback.print_stack()
        traceback.print_exc()
        print(e)


    return result



failed_dates = []
input_args = []

dts = pd.date_range(args.date_range[0], args.date_range[1], freq="D", inclusive="both")


for dt in dts:
    
    job_detail = dict(
        dt = dt,
        ERA5_varset   = ERA5_varset,
        ERA5_varname  = ERA5_varname_short,
        ERA5_freq     = ERA5_freq,
        output_root   = args.output_root,
        half_window_size = args.half_window_size,
    )
    
    result = doJob(job_detail, detect_phase=True)
    
    if not result['need_work']:
        print("File `%s` already exist. Skip it." % (result['output_file'],))
        continue
    
    input_args.append((job_detail, False))
        
       

print("!!!!!!!!! There are %d jobs needs distribution. " % (len(input_args,)))

with Pool(processes=args.nproc) as pool:

    results = pool.starmap(doJob, input_args)

    for i, result in enumerate(results):
        if result['status'] != 'OK':
            print('!!! Failed to generate output file %s.' % (str(result['output_file']),))
            failed_dates.append(result['job_detail'])


print("Tasks finished.")

print("Failed output files: ")
for i, failed_detail in enumerate(failed_dates):
    print("%d : " % (i+1), failed_detail)

print("Done.")

