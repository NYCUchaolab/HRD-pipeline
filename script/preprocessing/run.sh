
#!/usr/bin/bash

shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_PIPELINE_DIR/preprocessing/utility.sh

SRR_ID=$1
WORK_DIR=$2
OUTPUT_DIR=$3
VERBOSE=1

# download fastq file another script
# download $SRR_ID $NGC $WORK_DIR $OUTPUT_DIR 

sra2fastq $SRR_ID $WORK_DIR $OUTPUT_DIR

wait

run_fastqc $SRR_ID $OUTPUT_DIR $OUTPUT_DIR

wait

trimming $OUTPUT_DIR $OUTPUT_DIR $SRR_ID 

wait 

bwa_mapping \
    ${OUTPUT_DIR}/${SRR_ID}_R1_paired.fastq.gz \
    ${OUTPUT_DIR}/${SRR_ID}_R2_paired.fastq.gz \
    ${OUTPUT_DIR}/${SRR_ID}.bam \
    $SRR_ID

# wait

bam_sorting ${OUTPUT_DIR}/${SRR_ID}.bam ${OUTPUT_DIR}/$SRR_ID.sorted.bam

wait

mark_duplicate \
    ${OUTPUT_DIR}/${SRR_ID}.sorted.bam \
    ${OUTPUT_DIR}/${SRR_ID}.sorted.du.bam \
    ${OUTPUT_DIR}/${SRR_ID}.matrix.txt 

wait
rm ${OUTPUT_DIR}/${SRR_ID}.sorted.bam
rm ${OUTPUT_DIR}/${SRR_ID}.sorted.bai

bqsr ${OUTPUT_DIR}/${SRR_ID}.sorted.du.bam \
    ${OUTPUT_DIR}/${SRR_ID}.sorted.du.bqsr.bam \
    ${OUTPUT_DIR}/${SRR_ID}.recalibration_report.txt

wait

rm ${OUTPUT_DIR}/${SRR_ID}.sorted.du.bam
rm ${OUTPUT_DIR}/${SRR_ID}.sorted.du.bai

bamqc ${SRR_ID} ${OUTPUT_DIR}/${SRR_ID}.sorted.du.bqsr.bam ${OUTPUT_DIR}

wait