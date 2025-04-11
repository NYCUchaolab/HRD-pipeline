#!/usr/bin/bash

shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_DIR/utility/logger.sh
source $HRD_DIR/utility/read_samplesheet.sh

WORK_DIR=$1
shift 1  # Remove the first two parameters so that $@ now contains only the SRR IDs
SRR_IDs=("$@")
VERBOSE=1

for ID in "${SRR_IDs[@]}"; do
    if [ ! -f "$WORK_DIR/${ID}.report.pdf" ]; then 
        log 0 "$ID missing"
    fi
done


wait