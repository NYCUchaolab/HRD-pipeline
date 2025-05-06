#!/usr/bin/bash

shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_PIPELINE_DIR/preprocessing/utility.sh


WORK_DIR=$1
OUTPUT_DIR=$2
shift 2  # Remove the first two parameters so that $@ now contains only the SRR IDs
SRR_IDs=("$@")
VERBOSE=1

for SRR_ID in ${SRR_IDs[@]}; do
    # echo $SRR_ID
    bamqc $SRR_ID ${WORK_DIR}/${SRR_ID}.sorted.du.bqsr.bam $OUTPUT_DIR
done

wait