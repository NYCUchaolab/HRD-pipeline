#!/usr/bin/bash
shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_PIPELINE_DIR/HRD_calculation/bam2seqz.parallel.sh

eval "$(conda shell.bash hook)"

run_ScarHRD(){
    cwd=$(pwd)

    WORK_DIR=$1
    OUTPUT_DIR=$2
    Patient_ID=$3


    cd $OUT_DIR

    conda activate $SCAR_ENV

    Rscript $HRD_PIPELINE_DIR/HRD_calculation/run_scarHRD.R \
        -i $WORK_DIR \
        -p $Patient_ID

    conda deactivate

    cd $cwd
    mv $OUTPUT_DIR/${Patient_ID}.small.seqz._HRDresults.txt $OUTPUT_DIR/${Patient_ID}_HRDresults.txt
    mv $OUTPUT_DIR/${Patient_ID}.small.seqz._info_seg.txt $OUTPUT_DIR/${Patient_ID}_info_seg.txt

}

WORK_DIR=$1
OUTPUT_DIR=$2
Tumor_SRR_ID=$3
Normal_SRR_ID=$4
Patient_ID=$5

bam2seqz \
    $WORK_DIR \
    $OUTPUT_DIR \
    $Tumor_SRR_ID \
    $Normal_SRR_ID \
    $Patient_ID 

run_ScarHRD \
    $WORK_DIR \
    $OUTPUT_DIR \
    $Patient_ID
