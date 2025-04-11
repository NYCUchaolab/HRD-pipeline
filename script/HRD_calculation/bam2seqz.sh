#TODO: 
# [ ] read sample sheet and extract Tumor/ Normal Name
# [ ] get base_dir, get filepath
# [ ] script


shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG

eval "$(conda shell.bash hook)"

# read sample sheet
# get Tumor_SRR_ID, Normal_SRR_ID and Patient_ID
WORK_DIR=$1
OUTPUT_DIR=$2
Tumor_SRR_ID=$3
Normal_SRR_ID=$4
Patient_ID=$5

conda activate $SEQZ_ENV

sequenza-utils bam2seqz \
    -t ${WORK_DIR}/${Tumor_SRR_ID}.sorted.du.bqsr.bam \
    -n ${WORK_DIR}/${Normal_SRR_ID}.sorted.du.bqsr.bam \
    --fasta $REF_GENOME \
    -gc $GC50 \
    -o ${WORK_DIR}/${Patient_ID}.seqz.gz

sequenza-utils seqz_binning \
    --seqz ${WORK_DIR}/${Patient_ID}.seqz.gz \
    -w 50 \
    -o ${WORK_DIR}/${Patient_ID}.small.seqz.gz

    # -t ${WORK_DIR}/${Tumor_SRR_ID}.sorted.du.bqsr.bam \
    # -n ${WORK_DIR}/${Normal_SRR_ID}.sorted.du.bqsr.bam \

conda deactivate