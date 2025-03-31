shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_PIPELINE_DIR/variant_calling/utility.sh

WORK_DIR=$1
OUTPUT_DIR=$2
Tumor_SRR_ID=$3
Normal_SRR_ID=$4
Patient_ID=$5

run_haplotypecaller \
    $WORK_DIR \
    $OUTPUT_DIR \
    $Tumor_SRR_ID \
    $Normal_SRR_ID \
    $Patient_ID

run_mutect2 \
    $WORK_DIR \
    $OUTPUT_DIR \
    $Tumor_SRR_ID \
    $Normal_SRR_ID \
    $Patient_ID

run_varscan \
    $WORK_DIR \
    $OUTPUT_DIR \
    $Tumor_SRR_ID \
    $Normal_SRR_ID \
    $Patient_ID