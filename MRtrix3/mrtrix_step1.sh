#!/bin/bash

set -e

: "
The format
-- project
    |-- biddata
    |   |-- sub-wh0115
    |        |-- anat
    |            |- sub-01_T1w.nii.gz
    |        |-- func
    |            |- sub-01_task-rest_bold.nii.gz
    |            |- sub-01_task-rest_bold.json
    |        |--dwi
    |            |- sub-01_acq-main_dir-PA_dwi.nii.gz
    |            |- sub-01_acq-main_dir-PA_dwi.json
    |            |- sub-01_acq-main_dir-PA_dwi.bval
    |            |- sub-01_acq-main_dir-PA_dwi.bvec
    |--fs_recon_all
    |   |-- sub-wh0115
    |       |-- label
    |       |-- mri
    |       |-- ...(The Freesurfer Files)
"

export project_dir=~/project/mri_net/mridata
export process_dir=${project_dir}/dti_mrtrix
export biddata_dir=${project_dir}/biddata
export fs_dir=${project_dir}/fs_recon_all
export SUBJECTS_DIR=${fs_dir}
export activate=~/miniconda3/bin/activate
export annot_dir=${project_dir}/annot_ref

sub_input=$1

mkdir -p ${process_dir}
mkdir ${process_dir}/${sub_input}

mrtrix_run(){
    # The sub contains the prefix "sub"
    local sub=$1
    source ${activate} mrtrix

    echo "The process of ${sub} begin at $(date)"

    # 1. prepro
    mkdir ${process_dir}/${sub}/step1_prepro
    cd ${process_dir}/${sub}/step1_prepro

    # 1.1Format convert
    mrconvert ${biddata_dir}/${sub}/dwi/${sub}_acq-main_dir-PA_dwi.nii.gz ${sub}_main_PA_dwi.mif \
        -fslgrad ${biddata_dir}/${sub}/dwi/${sub}_acq-main_dir-PA_dwi.bvec ${biddata_dir}/${sub}/dwi/${sub}_acq-main_dir-PA_dwi.bval

    # 1.2 Generate the mask
    # dwi2mask ${sub}_main_PA_dwi.mif - | maskfilter - dilate pre_0mask.mif -npass 3

    # 1.3 Denoise
    dwidenoise ${sub}_main_PA_dwi.mif ${sub}_main_PA_dwi_1dno.mif -noise pre1_noise.mif

    # 1.4 Degibbs
    mrdegibbs ${sub}_main_PA_dwi_1dno.mif ${sub}_main_PA_dwi_2dgi.mif

    # 1.5 Motion and distortion correlation
    dwifslpreproc ${sub}_main_PA_dwi_2dgi.mif ${sub}_main_PA_dwi_3proc.mif \
        -nocleanup -pe_dir PA -rpe_none \
        -eddy_options " --slm=linear --data_is_shelled --niter=5"
    
    # 1.6 Bias Field
    dwibiascorrect ants ${sub}_main_PA_dwi_3proc.mif ${sub}_main_PA_dwi_4biaf.mif -bias pre4_biaf.mif

    # 1.7 Alignment
    dwiextract ${sub}_main_PA_dwi_4biaf.mif - -bzero | mrmath - mean pre5_b0_align.nii -axis 3

    mrconvert ${fs_dir}/${sub}/mri/brain.mgz ${sub}_T1_bet.nii.gz

    flirt.fsl -dof 6 -cost normmi -ref ${sub}_T1_bet.nii.gz -in pre5_b0_align.nii -omat T_fsl.txt
    transformconvert T_fsl.txt pre5_b0_align.nii ${sub}_T1_bet.nii.gz flirt_import T_DWItoT1.txt
    mrtransform -linear T_DWItoT1.txt ${sub}_main_PA_dwi_4biaf.mif ${sub}_main_PA_dwi_5align.mif

    # 2. 5ttgen
    mkdir ${process_dir}/${sub}/step2_5ttgen
    cd ${process_dir}/${sub}/step2_5ttgen
    mv ${process_dir}/${sub}/step1_prepro/${sub}_main_PA_dwi_5align.mif ./

    mrconvert ${fs_dir}/${sub}/mri/aparc.a2009s+aseg.mgz aparc.a2009s+aseg.nii.gz
    5ttgen freesurfer aparc.a2009s+aseg.nii.gz ${sub}_5ttseg.mif
    5tt2gmwmi ${sub}_5ttseg.mif ${sub}_5tt_gmwmi.mif

    dwi2mask ${sub}_main_PA_dwi_5align.mif - | maskfilter - dilate dwi_mask.mif
    dwi2tensor -mask dwi_mask.mif ${sub}_main_PA_dwi_5align.mif dt.mif
    tensor2metric dt.mif -fa dt_fa.mif -ad dt_ad.mif
    mrthreshold -abs 0.2 dt_fa.mif - | mrcalc - dwi_mask.mif -mult dwi_wmMask.mif

    # dwi2response msmt_5tt ${sub}_main_PA_dwi_5align.mif ${sub}_5ttseg.mif ms_5tt_wm.txt ms_5tt_gm.txt ms_5tt_csf.txt -voxels ms_5tt_voxels.mif
    dwi2response dhollander ${sub}_main_PA_dwi_5align.mif dh_wm.txt dh_gm.txt dh_csf.txt -voxels voxels.mif

    # dwi2fod msmt_csd ${sub}_main_PA_dwi_5align.mif -mask dwi_mask.mif \
    #     ms_5tt_wm.txt dwi_wmCsd.mif \
    #     ms_5tt_gm.txt dwi_gmCsd.mif \
    #     ms_5tt_csf.txt dwi_csfCsd.mif
    dwi2fod msmt_csd ${sub}_main_PA_dwi_5align.mif -mask dwi_mask.mif \
        dh_wm.txt dwi_wmCsd.mif \
        dh_gm.txt dwi_gmCsd.mif \
        dh_csf.txt dwi_csfCsd.mif

    mtnormalise dwi_wmCsd.mif dwi_wmCsd_norm.mif dwi_csfCsd.mif dwi_csfCsd_norm.mif -mask dwi_mask.mif

    # Track_related! Skip!
    echo "Congratulations! All tasks of ${sub} are done without error! "
    echo "End at $(date)"
}

mrtrix_run ${sub_input} 2>&1 | tee ${process_dir}/${sub_input}/${sub_input}_mrtrix_process1.log