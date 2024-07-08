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

export FMRIPREP=~/project/program/neuroimagetools/sig_fMRIprep/fmriprep-23.2.1.simg
export BIDS_DIR=/workspace/biddata
export OUTPUT_DIR=/workspace/output
export WORK_DIR=/workspace
export FS_license=/workspace/license.txt

export SINGULARITYENV_TEMPLATEFLOW_HOME=/templateflow
export cpus=16

# Download singularity build /my_images/fmriprep-<version>.simg docker://nipreps/fmriprep:23.2.1

singularity run \
  -B ${TEMPLATEFLOW_HOME}:/templateflow \
  -B ${WORK_HOME}:/workspace \
  $FMRIPREP \
  $BIDS_DIR $OUTPUT_DIR participant \
  -w $WORK_DIR \
  --fs-no-reconall \
  --fs-license-file $FS_license \
  --omp-nthreads ${cpus} \
  --n_cpus ${cpus} \
  --skip_bids_validation