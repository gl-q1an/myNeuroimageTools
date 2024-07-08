#!/bin/bash

# -- workdir
#  |-- bids_dir
#    |-- sub-001
#    |-- sub-002
#  |-- output
#  |-- templateflow
#  |--license.txt

export TEMPLATEFLOW_HOME=/media/user/32t/project/q1an/fmriproc/templateflow
export WORK_HOME=/media/user/32t/project/q1an/fmriproc/workspace
export BID_HOME=${WORK_HOME}/biddata

export FMRIPREP=~/project/program/neuroimagetools/sig_fMRIprep/fmriprep-23.2.1.simg
export BIDS_DIR=/workspace/biddata
export OUTPUT_DIR=/workspace/output
export WORK_DIR=/workspace
export FS_license=/workspace/license.txt

export SINGULARITYENV_TEMPLATEFLOW_HOME=/templateflow

# jobs refers to the number of parallel processes
# cpu refers to the cpu used in each process
export jobs=5
export cpus=8

fmriprep(){
    local participant=$1
    singularity run \
    -B ${TEMPLATEFLOW_HOME}:/templateflow \
    -B ${WORK_HOME}:/workspace \
    $FMRIPREP \
    $BIDS_DIR $OUTPUT_DIR participant \
    --participant-label ${participant} \
    -w $WORK_DIR \
    --fs-no-reconall \
    --fs-license-file $FS_license \
    --omp-nthreads ${cpus} \
    --n_cpus ${cpus} \
    --skip_bids_validation
}

export -f fmriprep

# Genetate ID list if neccesary
id_list=$(find ${BID_HOME} -maxdepth 1 -type d -name 'sub-*' -printf "%f\n")
echo $id_list | xargs -n 1 | parallel --jobs ${jobs}  fmriprep {}