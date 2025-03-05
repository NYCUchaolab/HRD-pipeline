#TODO: 
# [ ] read sample sheet and extract Tumor/ Normal Name
# [ ] get base_dir, get filepath
# [ ] script

source /home/hiiluann99/playground/HRD/HRD_pipeline/preprocessing/config.sh

CHR="chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY"

# read sample sheet
# get Tumor_SRR_ID, Normal_SRR_ID and Patient_ID
Tumor_SRR_ID=SRR22816205
Normal_SRR_ID=SRR22816189
Patient_ID=SU2CLC-MDA-1563
WORK_DIR=$1
OUTPUT_DIR=$2

# sequenza-utils bam2seqz \
#     -t ${WORK_DIR}/${Tumor_SRR_ID}_sorted_du_bqsr.bam \
#     -n ${WORK_DIR}/${Normal_SRR_ID}_sorted_du_bqsr.bam \
#     --fasta $REF_GENOME \
#     -C $CHR \
#     --parallel 24 \
#     -gc $GC50 \
#     -o ${OUTPUT_DIR}/${Patient_ID}.seqz.gz

# merge seqz with sequenza-utils seqz_merge -o output.seqz.gz -1 first.seqz.gz -2 second.seqz.gz

# 依次合併其他染色體
# FIRST_CHR=$(echo $CHR | awk '{print $1}')
# cp ${OUTPUT_DIR}/${Patient_ID}_${FIRST_CHR}.seqz.gz ${OUTPUT_DIR}/${Patient_ID}.seqz.gz  

# for c in $CHR; do
#     if [[ $c != $FIRST_CHR ]]; then  # 避免重複合併第一個染色體
#         echo "Merging ${OUTPUT_DIR}/${Patient_ID}.seqz.gz with ${OUTPUT_DIR}/${Patient_ID}_$c.seqz.gz ..."
#         sequenza-utils seqz_merge \
#             -o ${OUTPUT_DIR}/${Patient_ID}.temp.seqz.gz \
#             -1 ${OUTPUT_DIR}/${Patient_ID}.seqz.gz \
#             -2 ${OUTPUT_DIR}/${Patient_ID}_$c.seqz.gz 
        
#         mv ${OUTPUT_DIR}/${Patient_ID}.temp.seqz.gz ${OUTPUT_DIR}/${Patient_ID}.seqz.gz  # 更新 merged 文件
#     fi
# done

sequenza-utils seqz_binning \
    --seqz ${OUTPUT_DIR}/${Patient_ID}.seqz.gz \
    -w 50 \
    -o ${OUTPUT_DIR}/${Patient_ID}.small.seqz.gz

    # -t ${WORK_DIR}/${Tumor_SRR_ID}.sorted.du.bqsr.bam \
    # -n ${WORK_DIR}/${Normal_SRR_ID}.sorted.du.bqsr.bam \