#!/bin/bash

set -e

export project_dir=~/project/tcken
export process_dir=${project_dir}/share_tck
export activate=~

sub_input=$1

mkdir -p ${process_dir}
mkdir ${process_dir}/${sub_input}

mrtrix_run2(){
    # The sub contains the prefix "sub"
    local sub=$1
    source ${activate} neuroimage

    echo "The process of ${sub} BEGINS at $(date)"

    cd ${project_dir}/${sub}
    tckgen -algo iFOD2 -act ${sub}_5ttseg.mif -backtrack -crop_at_gmwmi \
        -cutoff 0.05 -angle 45 -minlength 20 -maxlength 200 -nthreads 100 \
        -seed_image dwi_wmMask.mif -select 10000000 \
        dwi_wmCsd_norm.mif \
        ${process_dir}/${sub}/${sub}_fibs_10M_angle45_maxlen200_act.tck

    cd ${process_dir}/${sub}

    tckedit ${sub}_fibs_10M_angle45_maxlen200_act.tck -number 200k ${sub}_200k_forcheck.tck
    
    tcksift2 -act ${project_dir}/${sub}/${sub}_5ttseg.mif  -nthreads 100 \
        -out_mu sift_mu.txt -out_coeffs sift_coeffs.txt \
        ${sub}_fibs_10M_angle45_maxlen200_act.tck \
        ${project_dir}/${sub}/dwi_wmCsd_norm.mif \
        ${sub}_sift_1M.txt
    
    echo "Congratulations! All tasks of ${sub} are done without error! "
    echo "End at $(date)"
}

mrtrix_run2 ${sub_input} 2>&1 | tee ${process_dir}/${sub_input}/${sub_input}_mrtrix_process2.log