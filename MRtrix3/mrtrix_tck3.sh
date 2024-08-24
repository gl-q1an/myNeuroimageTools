#!/bin/bash

set -e

tck_dir=~/project/tcken/share_tck
dwi_connect=~/project/tcken/dwi_connect
atlas_sub=~/project/tcken/atlas_sub

activate=~/project/program/sys/minconda3/bin/activate
env=neuroimage

source ${activate} ${env}

for dir in /home/q1an/project/tcken/atlas_sub/sub*;do
    
    sub=$(basename ${dir})
    

    if [ -d "${tck_dir}/${sub}" ]; then
        echo "${sub} begins at $(date)"
        mkdir -p ${dwi_connect}/${sub}

        tck2connectome -symmetric -zero_diagonal -scale_invnodevol \
            -tck_weights_in \
            ${tck_dir}/${sub}/${sub}_sift_1M.txt \
            ${tck_dir}/${sub}/${sub}_fibs_10M_angle45_maxlen200_act.tck \
            ${atlas_sub}/${sub}/${sub}_T1wspace_Schaefer400_TianS4.nii.gz \
            ${dwi_connect}/${sub}/${sub}_dwi-connect_Schaefer400-TianS4.csv \
            -out_assignment ${dwi_connect}/${sub}/assignments_${sub}_parcels.csv

        echo "${sub} finished at $(date)"
    else
        echo "${sub} is not exist!" | tee ${dwi_connect}/${sub}.log
    fi

done

