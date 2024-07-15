# Head Motion QC
# Quality Control Standards:
#   more than 25% of the frames exceeded 0.2 mm FD
# run python fmriprep_2headmotion.py -b bid_result_dir -o output_dir/result.csv

import os
import pandas as pd
import argparse
import glob
import datetime

Header = "===========================\n"
Header +="||     Head Motion QC    ||\n"
Header +="===========================\n"
Header += str(datetime.datetime.now())

describe_dict = {
    "args_all":Header,
    "describe":"Quality Control Standards:more than 25% of the frames exceeded 0.2 mm FD",
    "bidresdir": "The output directionary of fMRIPrep",
    "label" : "Only do QC on some individuals;txt file with one ID per line;or a space delimited list of participant ID or a single ID",
    "output": "A csv file, the first col is ID, and the second is whether passed QC"
}

def indentify_args(describe_dict):
    parser = argparse.ArgumentParser(description=describe_dict["describe"])
    parser.add_argument("-b","--bidresdir", required=True, help=describe_dict["bidresdir"])
    parser.add_argument("-l", "--label",default=None, help=describe_dict["label"])
    parser.add_argument("-o", "--output", help=describe_dict["output"])
    args = parser.parse_args()
    return args

def filter_confounds(confounds_file):
    # more than 25% of the frames exceeded 0.2 mm FD
    confounds_df = pd.read_csv(confounds_file, sep='\t')
    fd_threshold = 0.2
    ratio_threshold = 0.25
    fd = confounds_df['framewise_displacement'].fillna(0)
    num_exceeding_frames = (fd > fd_threshold).sum()
    total_frames = len(fd)
    exceeding_ratio = num_exceeding_frames / total_frames
    if exceeding_ratio < ratio_threshold:
        return 1
    else:
        return 0

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
    
if args.output is None:
    output = "fmriprep_headmotion.csv"
else:
    output = args.output

# RUN
result_dict={}
for i in label:
    if not i.startswith("sub-"):
        i = "sub-" + i
    confounds_pattern = glob.glob(os.path.join(bid_res_dir,i,"func","*confounds*.tsv"))
    if len(confounds_pattern) == 1:
        confounds_file = confounds_pattern[0]
        result_dict[i] = filter_confounds(confounds_file)
    else:
        result_dict[i] = -9
        print(f"Warning: Skip {i}")


df = pd.DataFrame(list(result_dict.items()), columns=['ID', 'HeadMotionQC'])
df.to_csv(output,index=None)