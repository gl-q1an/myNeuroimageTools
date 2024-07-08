# This script is used to extract files from stat in Freesufer

import pandas as pd
import os
import glob

fs_dir = "fs/dir"
fs_ind_list = [ind for ind in os.listdir(fs_dir) if os.path.isdir(os.path.join(fs_dir, ind)) and ind.startswith('sub-')]
output = "output/csv"

# Read .stas file and generate dataframe
def read_stats(statsfile,collist):
    df = pd.read_csv(statsfile, sep="\s+", comment="#", header=None)
    with open(statsfile,'r') as file:
        lines=file.readlines()
        column_line = ""
        for line in lines:
            if line.startswith('# ColHeaders'):
                column_line = line.strip()
        column_names = column_line.lstrip('# ColHeaders').strip().split()
        df.columns = column_names
    if statsfile.startswith('lh') or statsfile.startswith('rh'):
        prefix = statsfile[:2]
        df['StructName'] = prefix + '_' + df['StructName']
    df_stats = pd.DataFrame({'ID': ["IDtoModify"]})
    for metric in collist:
        for i in range(len(df)):
            struct = df.iloc[i]['StructName']
            colname = f"{metric}_{struct}"
            value = df.iloc[i][metric]
            df_stats[colname] = value
    return df_stats

# extract_icv(Estimated Total Intracranial Volume) fron aseg.stats
def extract_icv(asegfile):
    with open(asegfile, 'r') as file:
        lines = file.readlines()
        line_34 = lines[33]
        elements = line_34.split(',')
        icv = float(elements[-2].strip())
    return icv

# make indivitual's df to one raw
def df_comb(path,stats_list,col_list):
    df_result = pd.DataFrame({'ID': ["IDtoModify"]})
    for file in stats_list:
        stats_file = os.path.join(path,file)
        df = read_stats(stats_file,col_list)
        df_result = pd.merge(df_result,df,on="ID")
    return df_result

# Ind Proces (Customed)
def ind_process(ind_id, fs_dir):
    cortical_file = ["lh.aparc.stats","rh.aparc.stats"]
    cortical_collist = ["SurfArea", "GrayVol", "ThickAvg"]
    subcortical_file = ["aseg.stats"]
    subcortical_collist =["Volume_mm3"]

    path_pattern = os.path.join(fs_dir,f"{ind_id}*","stats")
    path_list = glob.glob(path_pattern)
    path = path_list[0]

    df1 = df_comb(path,cortical_file,cortical_collist)
    df2 = df_comb(path,subcortical_file,subcortical_collist)

    df_i = pd.merge(df1,df2,on="ID")
    df_i["ID"] = ind_id

    df_i["ICV"] = extract_icv(os.path.join(path,"aseg.stats"))
    return df_i

df_result = pd.DataFrame()
for ind in fs_ind_list:
    ind_fs = ind_process(ind,fs_dir)
    df_result = pd.concat([df_result, ind_fs], ignore_index=True)

df_result.to_csv(output, index=None)