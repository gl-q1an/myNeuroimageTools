# UKB Functional Connectivity
# There is a difference between using nilearn and directly calculating the pearson correlation results
# See https://neurostars.org/t/connectivitymeasure-function-in-nilearn-compare-with-corrcoef-in-matlab/3659/2

import os
import pandas as pd
import numpy as np
import argparse
import matplotlib.pyplot as plt
import seaborn as sns
import datetime

Header = "===============================\n"
Header +="||UKB Functional Connectivity||\n"
Header +="===============================\n"
Header += str(datetime.datetime.now())

describe_dict = {
    "args_all":Header,
    "describe":"Convert time series csv to functional connectivity matrix",
    "cortical": "The input time series csv of cortical",
    "subcortical": "The input time series csv of subcortical",
    "output" : "The output npy (One-dimensional vectors in the upper triangle excluding the diagonal)",
    "visualize" : "The picture format and file path"
}

def indentify_args(describe_dict):
    parser = argparse.ArgumentParser(description=describe_dict["describe"])
    parser.add_argument("-c","--corical", help=describe_dict["cortical"])
    parser.add_argument("-s","--subcorical", help=describe_dict["subcortical"])
    parser.add_argument("-o","--output", required=True, help=describe_dict["output"])
    parser.add_argument("-v", "--visualize", help=describe_dict["visualize"])
    args = parser.parse_args()
    return args

def TimeSeries2FC(ts_df):
    bold_signals = bold_signals.iloc[:, 1:]
    fc_matrix = bold_signals.T.corr(method='pearson')
    return fc_matrix

def TimeSeries2FC_nilearn(ts_df):
    from nilearn.connectome import ConnectivityMeasure
    connectivity_measure = "correlation"
    correlation_measure = ConnectivityMeasure(kind=connectivity_measure, vectorize=False, discard_diagonal=False)
    ts_df.set_index('label_name', inplace=True)
    ts_nd = ts_df.to_numpy()
    correlation_matrix = correlation_measure.fit_transform([ts_nd.T])[0]
    z_transformed_matrix = np.arctanh(correlation_matrix)
    return z_transformed_matrix

args=indentify_args(describe_dict)

df = pd.DataFrame()

if args.cortical is None:
    cortical_df = pd.read_csv(args.cortical)
    df = pd.concat([df,cortical_df],axis=0)

if args.subcortical is None:
    subcortical_df = pd.read_csv(args.cortical)
    df = pd.concat([df,subcortical_df],axis=0)

if args.outdir is None:
    outdir = "."
else:
    outdir = args.output

# RUN
fc_matrix=TimeSeries2FC(df)
fc_matrix.to_csv(outdir, index=False)

if args.visualize is not None:
    plt.figure(figsize=(10, 8))
    sns.heatmap(fc_matrix, cmap='coolwarm', vmin=-1, vmax=1)
    plt.title('Functional Connectivity Matrix')
    plt.xlabel('Brain Regions')
    plt.ylabel('Brain Regions')
    plt.savefig(args.visualize, dpi=300, bbox_inches='tight')