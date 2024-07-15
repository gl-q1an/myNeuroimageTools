# TimeSeries/Connectome Extract
# You need to check whether the space you aligned is consistent with the space of the atlas.
# Default MNI152NLin2009cAsym
# run python fmriprep_3timeseries.py -b bid_result_dir -o output_dir -a atlas_path

import os
import pandas as pd
import argparse
import glob
import datetime
import numpy as np
import nibabel as nib
from nilearn.maskers import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure
from nilearn.interfaces.fmriprep import load_confounds_strategy

Header = "===========================\n"
Header +="|| TimeSeries/Connectome ||\n"
Header +="===========================\n"
Header += str(datetime.datetime.now())

describe_dict = {
    "args_all":Header,
    "describe":"Extract the time series from fMRIPrep and atlas",
    "bidresdir": "The output directionary of fMRIPrep",
    "atlas" : "Atlas in the same space",
    "label" : "Only do QC on some individuals;txt file with one ID per line;or a space delimited list of participant ID or a single ID",
    "outdir": "A output dir contain the result time series csv",
    "connect": "Do not generate TimeSeries, directly generate connection matrix"
}

def indentify_args(describe_dict):
    parser = argparse.ArgumentParser(description=describe_dict["describe"])
    parser.add_argument("-b","--bidresdir", required=True, help=describe_dict["bidresdir"])
    parser.add_argument("-a", "--atlas", required=True, help=describe_dict["atlas"])
    parser.add_argument("-l", "--label",default=None, help=describe_dict["label"])
    parser.add_argument("-o", "--outdir", help=describe_dict["outdir"])
    parser.add_argument("-c", "--connect", help=describe_dict["connect"], action="store_true")
    args = parser.parse_args()
    return args

def extact_timeseries_ind(bold_file, path_to_atlas,connectivity_measure = "correlation"):
    masker = NiftiLabelsMasker(labels_img=path_to_atlas, standardize="zscore_sample",standardize_confounds="zscore_sample",memory="nilearn_cache")
    img = nib.load(bold_file)
    conf, sample_mask = load_confounds_strategy(bold_file, denoise_strategy = 'simple', motion = 'basic', global_signal = 'basic')
    time_series = masker.fit_transform(img, confounds=conf, sample_mask=sample_mask)
    # You can remove the first 10 points here
    correlation_measure = ConnectivityMeasure(kind=connectivity_measure, standardize="zscore_sample")
    correlation_matrix = correlation_measure.fit_transform([time_series])[0]
    z_transformed_matrix = np.arctanh(correlation_matrix)
    np.fill_diagonal(z_transformed_matrix, 0)
    column_names = ['TimePoint_' + str(i) for i in sample_mask]
    index_names = ['ROI_' + str(int(i)) for i in masker.labels_]
    df = pd.DataFrame(time_series.T, columns=column_names, index=index_names)
    return df, z_transformed_matrix

args=indentify_args(describe_dict)

# READ the args
bid_res_dir=args.bidresdir
if not os.path.isdir(bid_res_dir):
    raise NotADirectoryError(f"The path '{bid_res_dir}' is not a directory.")

if args.label is None:
    label = [name for name in os.listdir(bid_res_dir) if os.path.isdir(os.path.join(bid_res_dir, name)) and name.startswith("sub-")]
elif os.path.isfile(args.label):
    with open(args.label, 'r') as file:
        lines = file.readlines()
    label = [line.strip() for line in lines]
else:
    label = args.label.split()
    
if args.outdir is None:
    outdir = "."
else:
    outdir = args.outdir

if not os.path.exists(outdir):
    os.makedirs(outdir)

# RUN
error_log=0
for i in label:
    if not i.startswith("sub-"):
        i = "sub-" + i
    bold_file_pattern = glob.glob(os.path.join(bid_res_dir,i,"func","*_task-rest_*_desc-preproc_bold.nii.gz"))

    if len(bold_file_pattern) == 0:
         raise ValueError("Error: There is no file matching bold file pattern")
    elif len(bold_file_pattern) != 1:
        print("The elements in bold file pattern are not exactly one.")
        print(f"Choose the first: {bold_file_pattern[0]}")
    
    if len(bold_file_pattern) != 1:
        if error_log == 0:
            error_log = 1
            now = datetime.datetime.now()
            formatted_now = now.strftime('%Y%m%d%H%M%S')
            error_log_path = os.path.join(outdir,f"error_sub{formatted_now}.log")
            with open(error_log_path, 'w') as f:
                f.write("No matching functional imaging:\n")
                f.write(f"{i}\n")
        else:
            with open(error_log_path, 'a') as f:
                f.write(f"{i}\n")
    else:
        bold_file = bold_file_pattern[0]
        df, z_transformed_matrix = extact_timeseries_ind(bold_file, args.atlas)
        if args.connect:
            np.save(os.path.join(outdir,f"{i}_z-connoect"), z_transformed_matrix, allow_pickle=True)
        else:
            np.save(os.path.join(outdir,f"{i}_z-connect"), z_transformed_matrix, allow_pickle=True)
            df.to_csv(os.path.join(outdir,f"{i}_timeseires.csv"))