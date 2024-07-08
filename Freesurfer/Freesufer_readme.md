# Freesufer

Freesurfer is easy to run: `recon-all -s ${sub_id} -i ${sub_t1_niigzfile} -all -qcache`

This part includes 1. using a custom atlas, 2. extract cortical morphological indices for subsequent analysis.

If you are doing volume space analysis, it is not recommended to convert from the individual cortical space atlas, which may result in the loss of some ROIs.

The construction of network morphology indicators is mostly based on fs results and usually it is also easy to run, such as https://github.com/isebenius/MIND.