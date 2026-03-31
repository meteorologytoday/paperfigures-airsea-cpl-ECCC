import numpy as np
import xarray as xr
import pandas as pd

import ECCC_tools
ECCC_tools.init(data_root="data")


date_beg = "1998-01-01"
date_end = "2017-12-31"

model_versions = ["GEPS5", "GEPS6"]


stats = dict()

for model_version in model_versions:

    cnts = np.zeros((12,), dtype=int)
    mds = [ [] for _ in range(12) ]

    for reforecast_date in pd.date_range(date_beg, date_end, freq="D", inclusive="both"):
        test = ECCC_tools.modelVersionReforecastDateToModelVersionDate(model_version, reforecast_date)

        if test is not None:
            
            m_idx = reforecast_date.month-1
            
            cnts[m_idx] += 1
            md_str = reforecast_date.strftime("%m/%d")
    
            if md_str not in mds[m_idx]:
                mds[m_idx].append(md_str)
        

    
   

    stats[model_version] = dict( cnts = cnts , mds=mds)

    
for model_version, stat in stats.items():
    
    print(f"Model version: {model_version:s}")

    cnts = stat["cnts"]
    for i in range(12):
        print("Month %d : %d pts" % (i+1, cnts[i]))
        print("Dates: ")
        for j, md in enumerate(stat["mds"][i]):
            print("    %s" % (md,))
            


