#TODO: 
# [ ] read sample sheet and extract Tumor/ Normal Name
# [ ] get base_dir, get filepath
# [ ] script

source /home/hiiluann99/playground/HRD/HRD_pipeline/preprocessing/config.sh

# read sample sheet
# get Tumor_SRR_ID, Normal_SRR_ID and Patient_ID
Tumor_SRR_ID=SRR22816205
Normal_SRR_ID=SRR22816189
Patient_ID=SU2CLC-MDA-1563
WORK_DIR=$1

sequenza-utils bam2seqz \
    -t ${WORK_DIR}/${Tumor_SRR_ID}_sorted_du_bqsr.bam \
    -n ${WORK_DIR}/${Normal_SRR_ID}_sorted_du_bqsr.bam \
    --fasta $REF_GENOME \
    -gc $GC50 \
    -o ${WORK_DIR}/${Patient_ID}.seqz.gz

sequenza-utils seqz_binning \
    --seqz ${WORK_DIR}/${Patient_ID}.seqz.gz \
    -w 50 \
    -o ${WORK_DIR}/${Patient_ID}.small.seqz.gz

    # -t ${WORK_DIR}/${Tumor_SRR_ID}.sorted.du.bqsr.bam \
    # -n ${WORK_DIR}/${Normal_SRR_ID}.sorted.du.bqsr.bam \