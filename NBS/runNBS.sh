#!/bin/bash

set -e

export NETWORK_FILE=
# Use @ to swap the sub number
# e.g. data/sub-@_desc-anat-mind-net.txt
export INPUT_MATRIX=
# The first column is needed to copy the file, 
# the others are matrices required by NBS, 
# and column names are not required
# e.g.
# wh0115 1 0 23 122
# wh0117 0 1 20 117
export contrast=
# e.g. [1,-1,0,0,0]
export workname=
export workdir=
export node_coor=
export node_label=
export NBS_template=

preNBS(){
    local all_net_file=$1
    local IDmatrix=$2
    local workname=$3
    local workdir=$4
    local contrast=$5
    local node_coor=$6
    local node_label=$7
    local NBS_template=$8

    filebase=$(basename ${IDmatrix})
    filename="${filebase%.*}"
    mkdir -p ${workdir}/${workname}/netdir

    cut -f2- ${IDmatrix} > ${workdir}/${workname}/${filename}_matrix.txt

    for sub in $(awk '{print $1}' "$IDmatrix"); do
        ln -s "${all_net_file//@/$sub}" \ \
                ${workdir}/${workname}/netdir/${sub}_netlink.txt
    done

    sub_1st=$(awk 'NR==1 {print $1}' ${IDmatrix})

    # Write the matrix

    DESIGN_MATRIX=${workdir}/${workname}/${filename}_matrix.txt
    CONTRAST=${contrast}
    PREMS=5000
    P_ALPHA=0.05
    
    ## mind net
    NODE_COOR=${node_coor}
    NODE_LABEL=${node_label}

    > ${workdir}/${workname}/runNBS_${workname}.m
    NETWORK_FILE=${workdir}/${workname}/netdir/${sub_1st}_netlink.txt
    while read line;do
        eval "echo \"$line\"" >> ${workdir}/${workname}/runNBS_${workname}.m
    done < ${NBS_template}    
}

runNBS(){
    local mscript_file=$1
    local folder_path=$(dirname "${mscript_file}")
    local mscript_name=$(basename ${mscript_file})

    tmpfile=$(mktemp)

    matlab -nodisplay -nosplash -nodesktop -r "run('${mscript_file}'); exit;" | tee tmpfile

    awk '/It begins/ {flag=1} flag {print; if (NR >= (start + 10)) exit}' start=$(grep -n 'It begins' $tmpfile | cut -d: -f1) $tmpfile \
        > ${folder_path}/${mscript_name}.log
    echo '...' >> ${folder_path}/${mscript_name}.log
    tail -n 15 tmpfile >> ${folder_path}/${mscript_name}.log
}