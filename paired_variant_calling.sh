#!/usr/bin/bash

shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_DIR/utility/logger.sh
source $HRD_DIR/utility/read_samplesheet.sh

sample_sheet=$1
WORK_DIR=$2
OUTPUT_DIR=$3
parse_SRA_samplesheet $sample_sheet

bash $HRD_DIR/utility/wrapper.sh \
    $HRD_PIPELINE_DIR/variant_calling/run.sh \
    $Tumor_SRR_ID \
    $WORK_DIR \
    $OUTPUT_DIR

sleep 1

bash 
    $HRD_PIPELINE_DIR/variant_calling/run.sh \
    $Normal_SRR_ID \
    $WORK_DIR \
    $OUTPUT_DIR

sleep 1