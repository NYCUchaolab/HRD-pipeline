#!/usr/bin/bash

shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_PIPELINE_DIR/preprocessing/utility.sh

shopt -s expand_aliases

SAMPLE_SHEET=$1
WORK_DIR=$2
OUT_DIR=$3

# skip first row
# first columns: SRR
#  csv file in .txt postfix

tail -n +2 $SAMPLE_SHEET | while IFS=, read -r srr _; do
    echo $srr
    download $srr $WORK_DIR $OUT_DIR
done



