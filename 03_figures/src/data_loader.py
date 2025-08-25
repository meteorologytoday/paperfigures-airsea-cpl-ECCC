import xarray as xr
import numpy as np
import pandas as pd
import tool_fig_config
import scipy
import scipy.stats
import cmocean
from pathlib import Path

def loadVariable(
    input_dir,
    model_version,
    varset,
    varname,
    selected_categories, 
    lead_window,
    level,
    verbose=False,
):
    var3D = False
    filenames = []
    for category in selected_categories:
        filenames.append(
            Path(input_dir) / model_version / "ECCC-S2S_{model_version:s}_{varset:s}::{varname:s}_category-{category:s}.nc".format(
                model_version = model_version,
                varset  = varset,
                varname = varname,
                category = category,
            )
        )

    if verbose:
        print("===== Reading to load the following files: =====")
        for i, filename in enumerate(filenames):
            print("[%d] %s" % (i+1, filename,))

    ds = xr.open_mfdataset(filenames, concat_dim="category", combine="nested", engine="netcdf4")
    print(ds)
    ds = ds.sel(lead_window=lead_window)

    ds_varnames = dict(
        Emean        = "%s_Emean" % varname,
        E2mean       = "%s_E2mean" % varname,
        #Eabsmean     = "%s_Eabsmean" % varname,
        #Eabs2mean    = "%s_Eabs2mean" % varname,
        REGMEANVARmean = "%s_REGMEANVARmean" % varname,
        REGPATTVARmean = "%s_REGPATTVARmean" % varname,
        REGMEANVAR2mean = "%s_REGMEANVAR2mean" % varname,
        REGPATTVAR2mean = "%s_REGPATTVAR2mean" % varname,
        REGVARmean = "%s_REGVARmean" % varname,
        REGVAR2mean = "%s_REGVAR2mean" % varname,
        #REGTOTmean = "%s_REGTOTmean" % varname,
        #REGTOT2mean = "%s_REGTOT2mean" % varname,
        #REGREFmean = "%s_REGREFmean" % varname,
        #REGREF2mean = "%s_REGREF2mean" % varname,
        
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
    #total_Eabsmean  = ds[ds_varnames["Eabsmean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_Eabsmean")
    #total_Eabs2mean = ds[ds_varnames["Eabs2mean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_Eabs2mean")
    #total_Eabsvar = total_Eabs2mean - total_Eabsmean ** 2
    #_total_Eabsvar = total_Eabsvar.to_numpy()
    #print("Negative total_Eabsvar (possibly due to precision error): ", _total_Eabsvar[_total_Eabsvar < 0])

    #print("Fix the small negative ones...")
    #_total_Eabsvar[(np.abs(_total_Eabsvar) < 1e-5) & (_total_Eabsvar < 0)] = 0

    #print("Negative total_Evar after fixed: ", _total_Eabsvar[_total_Eabsvar < 0])
 
    total_cnt = ds["total_cnt"].sum(dim="category").rename("total_cnt")
    total_ddof = ds["ddof"].sum(dim="category").rename("total_ddof")

    total_Estd = np.sqrt(total_Evar).rename("total_Estd")
    total_Estderr = (total_Estd / total_ddof**0.5).rename("total_Estderr")

    #total_Eabsstd = np.sqrt(total_Eabsvar).rename("total_Eabsstd")

    # REGIONAL RMSE
    total_REGMEANVARmean  = ds[ds_varnames["REGMEANVARmean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGMEANVARmean")
    total_REGMEANVAR2mean = ds[ds_varnames["REGMEANVAR2mean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGMEANVAR2mean")
    total_REGMEANVARvar = total_REGMEANVAR2mean - total_REGMEANVARmean ** 2
    total_REGMEANVARvar = total_REGMEANVARvar.rename("total_REGMEANVARvar")
    total_REGMEANVARstderr = (total_REGMEANVARvar**0.5 / total_ddof**0.5).rename("total_REGMEANVARstderr")
    #_total_RMSEvar = total_RMSEvar.to_numpy()
    #print("Negative total_RMSEvar (possibly due to precision error): ", _total_RMSEvar[_total_RMSEvar < 0])
    #print("Fix the small negative ones...")
    #_total_RMSEvar[(np.abs(_total_RMSEvar) < 1e-5) & (_total_RMSEvar < 0)] = 0
    #total_RMSEstd = np.sqrt(total_RMSEvar).rename("total_RMSEstd")

    total_REGPATTVARmean  = ds[ds_varnames["REGPATTVARmean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGPATTVARmean")
    total_REGPATTVAR2mean = ds[ds_varnames["REGPATTVAR2mean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGPATTVAR2mean")
    total_REGPATTVARvar = total_REGPATTVAR2mean - total_REGPATTVARmean ** 2
    total_REGPATTVARvar = total_REGPATTVARvar.rename("total_REGPATTVARvar")
    total_REGPATTVARstderr = (total_REGPATTVARvar**0.5 / total_ddof**0.5).rename("total_REGPATTVARstderr")
    
 
    total_REGVARmean  = ds[ds_varnames["REGVARmean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGVARmean")
    total_REGVAR2mean = ds[ds_varnames["REGVAR2mean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGVAR2mean")
    total_REGVARvar = (total_REGVAR2mean - total_REGVARmean ** 2).rename("total_REGVARvar")
    total_REGVARstderr = (total_REGVARvar**0.5 / total_ddof**0.5).rename("total_REGVARstderr")
   
    #total_REGTOTmean   = ds[ds_varnames["REGTOTmean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGTOTmean")
    #total_REGTOT2mean  = ds[ds_varnames["REGTOT2mean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGTOT2mean")
    #total_REGREFmean   = ds[ds_varnames["REGREFmean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGREFmean")
    #total_REGREF2mean  = ds[ds_varnames["REGREF2mean"]].weighted(ds["total_cnt"]).mean(dim="category").rename("total_REGREF2mean")

    #total_REGTOTvar = (total_REGTOT2mean - total_REGTOTmean ** 2).rename("total_REGTOTvar")
    #total_REGREFvar = (total_REGREF2mean - total_REGREFmean ** 2).rename("total_REGREFvar")

    new_ds = xr.merge([
        total_Emean,    total_Estd,      total_Estderr,
     #   total_Eabsmean, total_Eabs2mean, total_Eabsstd,
    ])
   
    # Concat this for plotting issue 
    new_ds = xr.concat([new_ds, new_ds.isel(longitude=slice(0, 1))], dim="longitude")
    new_longitude = new_ds.coords["longitude"].to_numpy()
    new_longitude[-1] = new_longitude[-2] + (new_longitude[1] - new_longitude[0])
    new_ds = new_ds.assign_coords(longitude=new_longitude)

    # total_cnt has to be done sepearately. Otherwise the isel longitude will append another dimension
    new_ds = xr.merge([
        new_ds, total_cnt, total_ddof,
        total_REGMEANVARmean,  total_REGPATTVARmean, total_REGVARmean,
        total_REGMEANVARvar, total_REGPATTVARvar, total_REGVARvar,
        total_REGMEANVARstderr, total_REGPATTVARstderr, total_REGVARstderr,
        #total_REGTOTvar, total_REGREFvar,
    ])

    return new_ds, var3D


def loadVariable_leadwindowrange(
    input_dir,
    model_version,
    varset,
    varname,
    selected_categories, 
    lead_window_range,
    level,
    verbose = False,
    lat_rng = None,
    lon_rng = None,
):

    merge_ds = []
    var3D = None
    for lead_window in range(lead_window_range[0], lead_window_range[1]+1):

        ds, var3D = loadVariable(
            input_dir,
            model_version,
            varset,
            varname,
            selected_categories, 
            lead_window,
            level,
            verbose=verbose,
        )

        if lat_rng is not None and lon_rng is not None:
            lat = ds.coords["latitude"]
            lon = ds.coords["longitude"] % 360.0
            wgt = xr.apply_ufunc(np.cos, lat * np.pi/180.0)
            
            ds = ds.where(
                ( lat >= lat_rng[0] ) 
                & ( lat <= lat_rng[1] ) 
                & ( lon >= lon_rng[0] ) 
                & ( lon <= lon_rng[1] ) 
            ).weighted(wgt).mean(dim=["latitude", "longitude"], skipna=True)

        ds = ds.expand_dims(dim={'lead_window': [lead_window,]}, axis=0).compute()
        
        merge_ds.append(ds)
    
    
    new_ds = xr.merge(merge_ds)
    
    return new_ds, var3D
