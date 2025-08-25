import numpy as np
from matplotlib.patches import Rectangle
from shapely.geometry import Polygon

map_regions = {
    'AL': {
        'lon': [140, 230],  # 160E to 130W
        'lat': [40, 60],
        'color' : "magenta",
    },
    'IL': {
        'lon': [-30, 20],
        'lat': [55, 70],
        'color' : "magenta",
    },
    'ASH': {
        'lon': [-60, 20],
        'lat': [20, 50],
        'color' : "magenta",
    },

    'KCE': {
        'lon': [150, 230],  
        'lat': [30, 50],
        'color' : "black",
    },

    'GS': {
        'lon': [-75, -15],  
        'lat': [30, 55],
        'color' : "black",
    },


}

def make_box(lon_min, lon_max, lat_min, lat_max, npts=100):
    """Create a smooth polygon box along great-circle edges."""
    # Interpolate points along each edge
    lons_top = np.linspace(lon_min, lon_max, npts)
    lats_top = np.full_like(lons_top, lat_max)

    lons_right = np.full_like(lats_top, lon_max)
    lats_right = np.linspace(lat_max, lat_min, npts)

    lons_bottom = np.linspace(lon_max, lon_min, npts)
    lats_bottom = np.full_like(lons_bottom, lat_min)

    lons_left = np.full_like(lats_top, lon_min)
    lats_left = np.linspace(lat_min, lat_max, npts)

    lons = np.concatenate([lons_top, lons_right, lons_bottom, lons_left])
    lats = np.concatenate([lats_top, lats_right, lats_bottom, lats_left])

    return list(zip(lons, lats))

def plotRegions(ax, regions=list(map_regions.keys()), transform=None, verbose=True):
    
    
    for region in regions:
        
        if verbose:
            print("Plot region box: %s" % (region,))

        info = map_regions[region]
        
        lon0, lon1 = np.array(info['lon']) 
        lat0, lat1 = np.array(info['lat'])

        if lon1 < lon0:
            lon1 += 360.0
    

        coords = make_box(lon0, lon1, lat0, lat1)
        geom = Polygon(coords)
         
        ax.add_geometries([geom], crs=transform,
                      edgecolor=info["color"], facecolor="none", linestyle="solid", linewidth=2, label=region)

