import pandas as pd
import numpy as np
import argparse

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--no-display', action="store_true")
    parser.add_argument('--hist-output', type=str, default="MJO_MAG_HIST_1.svg")
    args = parser.parse_args()



    mjo_datafile = "data/omi.era5.1x.webpage.4023.txt.csv"
    mjo_date_to_category_file = "gendata/MJO_date_to_category.csv"
    mjo_category_file = "gendata/MJO_category.csv"

    print("Reading file: ", mjo_datafile)
    df_mjo_data = pd.read_csv(mjo_datafile)
    print(df_mjo_data)
        
    category_to_phase = { i : ("P%d" % i) for i in range(1, 9)}

    categories = ["NoMJO", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]

    df_mjo_data["category"] = df_mjo_data.apply(lambda row: category_to_phase[int(row['phase'])] if row['magnitude'] >= 1 else "NoMJO", axis=1)


    mjo_date = pd.to_datetime(df_mjo_data['date'])


    for selected_months in [
        [10, 11, 12, 1, 2],
    ]:

        df_mjo_data = df_mjo_data[
            mjo_date.dt.month.isin(selected_months)
            & (mjo_date.dt.year >= 1998)
            & (mjo_date.dt.year <= 2017)
        ]

        df_mjo_date_to_category_file = df_mjo_data

        print("Output file: ", mjo_date_to_category_file)
        df_mjo_date_to_category_file.to_csv(mjo_date_to_category_file)


        df_MJO_category = pd.DataFrame.from_dict(dict(
            category = categories,

        ))

        print("Output file: ", mjo_category_file)
        df_MJO_category.to_csv(mjo_category_file)



    print("Statistics: ")
    N_total = len(df_mjo_data)
    print("There are %d dates." % (N_total,))
    for i, row in df_MJO_category.iterrows():
        print("[%d] `%s` => %d " % (i+1, row['category'], len(df_mjo_data[df_mjo_data['category'] == row['category']])))
    #unique_values, counts = np.unique(data, return_counts=True)

    bin_edges = np.linspace(0, 4, 40+1)

    hists = dict()

    for category in categories:
        
        _data = df_mjo_data[df_mjo_data['category'] == category]['magnitude'].to_numpy()
        hist, _ = np.histogram(_data, bin_edges)

        hists[category] = hist


    print("Loading matplotlib...")

    import matplotlib as mplt
    if args.no_display:
        mplt.use("Agg")
    else:
        mplt.use("TkAgg")


    import matplotlib.pyplot as plt

    print("done")
    plt.style.use('seaborn-v0_8-colorblind')#tableau-colorblind10')

    fig, ax = plt.subplots(1, 1, figsize=(6, 4))

    bin_centers = (bin_edges[1:] + bin_edges[:-1])/2
    bottom = np.zeros_like(bin_centers)

    for category, hist in hists.items():
        ax.bar(bin_centers, hist, width=bin_edges[1:] - bin_edges[:-1], bottom=bottom, label=category)
        bottom += hist

    ax.legend()
    ax.set_xlabel("MJO Magnitude")
    ax.set_ylabel("Frequency")
    ax.set_title("Histogram of MJO Magnitude")

    print("Output statistic figure: ", args.hist_output)
    fig.savefig(args.hist_output)

