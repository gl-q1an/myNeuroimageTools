#!/bin/bash

# Registration MNI atlas to indivitual space

set -e

export SUBJECTS_DIR=
export WORK_DIR=
export T1_MNI=mni_icbm152_t1_tal_nlin_asym_09c_brain.nii
export Atlas_MNI=Schaefer2018_400Parcels_7Networks_order_Tian_Subcortex_S4_3T_MNI152NLin2009cAsym_1mm.nii.gz
export T1_sub=${SUBJECTS_DIR}/@/@_t1_bet.nii.gz
export Atlas_sub=${SUBJECTS_DIR}/@/@_Schaefer400N7_tian54.nii.gz
export activate=~/miniconda3/bin/activate
export env=neuroimage

source ${activate} ${env}

mni2sub_ants(){
    local sub_id=$1
    local work_dir=$2
    local T1_MNI=$3
    local T1_sub=$4
    local Atlas_MNI=$5
    local Atlas_sub=$6

    echo "The process of ${sub_id} begin at $(date)"

    mkdir -p ${work_dir}
    mkdir -p $(dirname ${Atlas_sub})

    antsRegistrationSyNQuick.sh -d 3 -f ${T1_sub} -m ${T1_MNI} -o ${work_dir}/ants_${sub_id}_

    antsApplyTransforms -d 3 \
        -i ${Atlas_MNI} \
        -r ${T1_sub} \
        -o ${Atlas_sub} \
        -t ${work_dir}/ants_${sub_id}_1Warp.nii.gz \
        -t ${work_dir}/ants_${sub_id}_0GenericAffine.mat \
        -n NearestNeighbor
    
    echo "Congratulations! All tasks of ${sub_id} are done without error! "
    echo "End at $(date)"
}

export -f mni2sub_ants

id_list=$(find ${SUBJECTS_DIR} -maxdepth 1 -type d -name 'sub-*' -printf "%f\n")

echo $id_list |\
 xargs -n 1 bash -c 'mni2sub_ants "$0" "${WORK_DIR}/$0" "${T1_MNI}" "$(echo ${T1_sub} | sed "s/@/$0/")" "${Atlas_MNI}" "$(echo ${Atlas_sub} | sed "s/@/$0/")"'

# if you want run it parallelly
if false; then
    export jobs=10
    echo $id_list | xargs -n 1 | parallel --jobs ${jobs} \
        mni2sub_ants {} ${WORK_DIR}/{} ${T1_MNI} "$(echo ${T1_sub} | sed "s/@/{}/")" ${Atlas_MNI} "$(echo ${Atlas_sub} | sed "s/@/{}/")"
fi
