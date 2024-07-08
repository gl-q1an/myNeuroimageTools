#!/bin/bash

set -e

export project_dir=~/project/mri_net/mridata
export process_dir=${project_dir}/dti_mrtrix
export biddata_dir=${project_dir}/biddata

for file in $(ls ${biddata_dir});do
    if [[ "$file" == "sub-wh"* ]] && [[ ! -d ${process_dir}/$file ]]; then
        bash ${project_dir}/scripts/mrtrix_step1.sh $file
    fi
done 
