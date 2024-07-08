#!/bin/bash

mri_surf2surf --srcsubject fsaverage --trgsubject ${sub} --hemi lh --sval-annot ${annot_dir}/lh.HCP-MMP1.annot --tval ${fs_dir}/${sub}/label/lh.HCP-MMP1.annot
mri_surf2surf --srcsubject fsaverage --trgsubject ${sub} --hemi rh --sval-annot ${annot_dir}/rh.HCP-MMP1.annot --tval ${fs_dir}/${sub}/label/rh.HCP-MMP1.annot

mri_aparc2aseg --s ${sub} --volmask --annot HCP-MMP1 --annot-table ${annot_dir}/hcpmmp1_original.txt

mrconvert ${fs_dir}/${sub}/mri/HCP-MMP1+aseg.mgz ${sub}_HCP-MMP1+aseg.nii.gz

# NOT RECOMMENDED, You can use ANTs
labelconvert ${sub}_HCP-MMP1+aseg.nii.gz \
    ${annot_dir}/hcpmmp1_original.txt \
    ${annot_dir}/hcpmmp1_ordered.txt \
    ${sub}_HCP-MMP1+aseg_relabel.nii.gz
