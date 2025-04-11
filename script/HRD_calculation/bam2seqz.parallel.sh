#!/usr/bin/bash

#TODO: 
# [ ] read sample sheet and extract Tumor/ Normal Name
# [ ] get base_dir, get filepath
# [ ] script

shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG

eval "$(conda shell.bash hook)"


bam2seqz(){
    CHR="chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY"

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
        -C $CHR \
        --parallel 24 \
        -gc $GC50 \
        -o ${OUTPUT_DIR}/${Patient_ID}.seqz.gz

    # merge seqz with sequenza-utils seqz_merge -o output.seqz.gz -1 first.seqz.gz -2 second.seqz.gz
    FILES=()
    for c in $CHR; do
        FILES+=("${WORK_DIR}/${Patient_ID}_$c.seqz.gz")
    done 
    ROUND=1

    # Hierarchical merging process
    while [ ${#FILES[@]} -gt 1 ]; do
        echo "Step $ROUND: Merging ${#FILES[@]} files..."
        NEW_FILES=()
        TEMP_FILES=()
        
        for ((i=0; i<${#FILES[@]}; i+=2)); do
            if [ $((i+1)) -lt ${#FILES[@]} ]; then
                OUTFILE="${OUTPUT_DIR}/${Patient_ID}.round${ROUND}.$((i/2)).seqz.gz"
                echo "Merging ${FILES[i]} + ${FILES[i+1]} → $OUTFILE"
                sequenza-utils seqz_merge -o $OUTFILE -1 ${FILES[i]} -2 ${FILES[i+1]} &
                NEW_FILES+=("$OUTFILE")
                TEMP_FILES+=("${FILES[i]}" "${FILES[i+1]}")
            else
                # If there's an odd file, carry it to the next round
                NEW_FILES+=("${FILES[i]}")
            fi
        done
        
        wait  # Wait for all parallel merges to finish
        echo "Cleaning up intermediate files..."
        echo ""
        for f in "${TEMP_FILES[@]}"; do
            rm -f "$f" "$f.tbi"
        done

        FILES=("${NEW_FILES[@]}")  # Update the list for the next round
        ROUND=$((ROUND + 1))
    done

    # Final output
    FINAL_FILE=${FILES[0]}
    mv $FINAL_FILE $OUTPUT_DIR/${Patient_ID}.seqz.gz
    mv ${FINAL_FILE}.tbi $OUTPUT_DIR/${Patient_ID}.seqz.gz.tbi

    sequenza-utils seqz_binning \
        --seqz ${OUTPUT_DIR}/${Patient_ID}.seqz.gz \
        -w 50 \
        -o ${OUTPUT_DIR}/${Patient_ID}.small.seqz.gz

    conda deactivate 
}


