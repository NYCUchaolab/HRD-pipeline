#!/usr/bin/sh

shopt -s expand_aliases
eval "$(conda shell.bash hook)"

source $HRD_PIPELINE_CONFIG

run_mutect2(){
    conda activate $GATK_ENV

    # gatk --java-options "-XX:ParallelGCThreads=$THREAD -Xmx16G"

    gatk Mutect2 -R $REF_GENOME \
        -L $LIBRARY_BED \
        -I $INPUT_DIR/${TUMOR_ID}_sorted_du_bqsr.bam \
        -I $INPUT_DIR/${NORMAL_ID}_sorted_du_bqsr.bam \
        -tumor $TUMOR_ID \
        -normal $NORMAL_ID \
        --germline-resource $GERMLINE_REF \
        -pon $PON \
        -O $OUT_DIR/${PATIENT_ID}_unfilter.vcf &

    (
        gatk GetPileupSummaries -I $INPUT_DIR/${TUMOR_ID}_sorted_du_bqsr.bam \
            -V ${COMMON_REF} \
            -L ${COMMON_REF} \
            -O $OUT_DIR/${TUMOR_ID}-pileups.table & 
        
        gatk GetPileupSummaries -I ${NORMAL_ID}_sorted_du_bqsr.bam \
            -V ${COMMON_REF} \
            -L ${COMMON_REF} \
            -O $OUT_DIR/${NORMAL_ID}-pileups.table &
    )

    wait 
    
    gatk CalculateContamination \
        -I $OUT_DIR/${TUMOR_ID}-pileups.table \
        -matched $OUT_DIR/${NORMAL_ID}-pileups.table \
        -O $OUT_DIR/${PATIENT_ID}_contamination.table \
        -tumor-segmentation $OUT_DIR/${PATIENT_ID}_segments.table

    gatk FilterMutectCalls -R ${myfasta} \
        -V $OUT_DIR/${PATIENT_ID}_unfiltered.vcf \
        --tumor-segmentation $OUT_DIR/${PATIENT_ID}_segments.table \
        --contamination-table $OUT_DIR/${PATIENT_ID}_contamination.table \
        -O $OUT_DIR/${PATIENT_ID}_filtered.vcf

    conda deactivate
}

run_haplotypecaller(){
    gatk HaplotypeCaller \
        -R $REF_GENOME \
        -I $WORK_DIR/${NORMAL_ID}_bqsr_du_bqsr.bam \
        -O $OUT_DIR/${PATIENT_ID}_germline.g.vcf.gz \
        -ERC GVCF \
        -L $LIBRARY_BED \
        --dbsnp $KNOWN_SITE_1

    gatk GenotypeGVCFs \
    -R $REF_GENOME \
    -L $LIBRARY_BED \
    --dbsnp $KNOWN_SITE_1 \
    -V $OUT_DIR/${PATIENT_ID}_germline.g.vcf.gz \
    -O $OUT_DIR/${PATIENT_ID}_germline.vcf.gz
}

run_varscan(){
    
}