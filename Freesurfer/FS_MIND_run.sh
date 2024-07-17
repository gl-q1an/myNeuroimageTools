#!/bin/bash

set -e

export MIND_DIR=$(dirname "$0")
export MIND_GIT_DIR=
export SUBJECTS_DIR=
export OUTPUT_DIR=
export ATLAS_PATH=

export activate=
export env=

mkdir -p 

fs_mind(){
    local sub=$1

    source ${activate} ${env}

    python ${MIND_DIR}/FS_MIND.py \
    -m ${MIND_GIT_DIR} \
    -i ${SUBJECTS_DIR}/${sub} \
    -a ${ATLAS_PATH} \
    -o ${OUTPUT_DIR}/${sub}_mindnet.npy \
    -f

    echo "${sub} is done successfully!"
}

export -f fs_mind

id_list=$(find ${SUBJECTS_DIR} -maxdepth 1 -type d -name 'sub-*' -printf "%f\n")
echo $id_list | xargs -n 1 | parallel --jobs ${jobs}  fs_mind {}