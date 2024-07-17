# FS_MIND.py
# See https://github.com/isebenius/MIND for details
# Usage: python FS_MIND.py -m MIND_DIR -i fs_sub_dir -a annot_name -o output_file -f

import os
import pandas as pd
import argparse
import numpy as np
import datetime

Header = "============================\n"
Header +="|| Freesufer MIND Network ||\n"
Header +="============================\n"
Header += str(datetime.datetime.now())

describe_dict = {
    "args_all":Header,
    "describe":"python FS_MIND.py MIND_DIR fs_sub_dir annot_name output_file",
    "MIND_DIR": "The path of MIND git directory",
    "input" : "This is the path to the Freesurfer folder containing all standard output directories (e.g. surf, mri, label)",
    "annot": "Select which parcellation to use in label. (e.g. 'aparc' means *h.aparc.annot)",
    "output": "The numpy file of the network",
    "figure": "Whether to generate the network file"
}

def indentify_args(describe_dict):
    parser = argparse.ArgumentParser(description=describe_dict["describe"])
    parser.add_argument("-m","--mind", required=True, help=describe_dict["MIND_DIR"])
    parser.add_argument("-i", "--input",required=True, help=describe_dict["input"])
    parser.add_argument("-a", "--annot", help=describe_dict["annot"])
    parser.add_argument("-o", "--output", help=describe_dict["output"])
    parser.add_argument("-f", "--figure", action='store_true', help=describe_dict["figure"])
    args = parser.parse_args()
    return args

args=indentify_args(describe_dict)

import sys
sys.path.insert(1, args.mind)
from MIND import compute_MIND

path_to_surf_dir = args.input
features = ['CT','MC','Vol','SD','SA']
parcellation = args.annot

mind_df = compute_MIND(path_to_surf_dir, features, parcellation) 

mind_array = mind_df.to_numpy()

np.save(args.output, mind_array)

if args.figure:
    import matplotlib.pyplot as plt
    from matplotlib.colors import LinearSegmentedColormap
    prefix = args.output[:-3]
    colors = ["#ffffff", "#1d8f8f"]
    cmap = LinearSegmentedColormap.from_list("custom_cmap", colors)
    plt.figure(figsize=(10, 10))
    plt.imshow(mind_df, cmap=cmap, vmin=0)
    plt.colorbar()
    plt.savefig(f"{prefix}png", format='png')
    plt.close()