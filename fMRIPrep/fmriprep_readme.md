# fMRIPrep README

Web: https://fmriprep.org/en/stable/

## Difference between skipping and not skipping Freesurfer

Freesufer's segmentation may be more accurate, but it is more time-consuming, so if the subsequent results involve the cortex, you can do it. If you just want to calculate functional connectivity, it will not have much impact and can be skipped.

## How to screen out individuals who fail QC

`sub-<id>_task-rest_desc-confounds_timeseries.tsv` that exists in `output/sub-<id>/func` contain many parameters about head motion. Head motion QC can be determined based on previous reports. 

Here we take "more than 25% of the frames exceeded 0.2 mm FD" as an example. See `fmriprep_2headmotion.py`

## How to extract time series from atlas

The reason for separating the extraction of time series and the construction of the connection matrix is ​​that UKB have time series that can be used directly, which is convenient for connecting with them.

## Reference

https://nilearn.github.io/stable/modules/generated/nilearn.interfaces.fmriprep.load_confounds.html

https://github.com/brainhack-school2022/brotherwood_project/tree/master