#!/usr/bin/sh

shopt -s expand_aliases
eval "$(conda shell.bash hook)"

source $HRD_PIPELINE_CONFIG

run_mutect2(){
    INPUT_DIR=$1
    OUT_DIR=$2
    TUMOR_ID=$3
    NORMAL_ID=$4
    PATIENT_ID=$5

    conda activate $GATK_ENV

    # gatk --java-options "-XX:ParallelGCThreads=$THREAD -Xmx16G"

    (
        gatk Mutect2 -R $REF_GENOME \
            -L $LIBRARY_BED \
            -I $INPUT_DIR/${TUMOR_ID}.sorted.du.bqsr.bam \
            -I $INPUT_DIR/${NORMAL_ID}.sorted.du.bqsr.bam \
            -tumor $TUMOR_ID \
            -normal $NORMAL_ID \
            --germline-resource $GERMLINE_REF \
            -pon $PON \
            -O $OUT_DIR/${PATIENT_ID}.unfilter.vcf 

        gatk GetPileupSummaries -I $INPUT_DIR/${TUMOR_ID}.sorted.du.bqsr.bam \
            -V ${COMMON_REF} \
            -L ${COMMON_REF} 
            -O $OUT_DIR/${TUMOR_ID}.pileups.table 
        
        gatk GetPileupSummaries -I $INPUT_DIR/${NORMAL_ID}.sorted.du.bqsr.bam \
            -V ${COMMON_REF} \
            -L ${COMMON_REF} \
            -O $OUT_DIR/${NORMAL_ID}.pileups.table
    )

    wait 
    
    gatk CalculateContamination \
        -I $OUT_DIR/${TUMOR_ID}.pileups.table \
        -matched $OUT_DIR/${NORMAL_ID}.pileups.table \
        -O $OUT_DIR/${PATIENT_ID}.contamination.table \
        -tumor-segmentation $OUT_DIR/${PATIENT_ID}.segments.table

    gatk FilterMutectCalls \
        --reference ${REF_GENOME} \
        --output $OUT_DIR/${PATIENT_ID}.filtered.vcf \
        --variant $OUT_DIR/${PATIENT_ID}.unfilter.vcf \
        --tumor-segmentation $OUT_DIR/${PATIENT_ID}.segments.table \
        --contamination-table $OUT_DIR/${PATIENT_ID}.contamination.table


    wait

    conda deactivate
}

run_haplotypecaller(){
    WORK_DIR=$1
    OUT_DIR=$2
    NORMAL_ID=$4
    PATIENT_ID=$5

    conda activate $GATK_ENV

    gatk HaplotypeCaller \
        -R $REF_GENOME \
        -I $WORK_DIR/${NORMAL_ID}.sorted.du.bqsr.bam \
        -O $OUT_DIR/${PATIENT_ID}.germline.g.vcf.gz \
        -ERC GVCF \
        -L $LIBRARY_BED \
        --dbsnp $KNOWN_SITE_1

    gatk GenotypeGVCFs \
    -R $REF_GENOME \
    -L $LIBRARY_BED \
    --dbsnp $KNOWN_SITE_1 \
    -V $OUT_DIR/${PATIENT_ID}.germline.g.vcf.gz \
    -O $OUT_DIR/${PATIENT_ID}.germline.vcf.gz

    wait
    conda deactivate
}

run_varscan_preprocessing(){
    INPUT_DIR=$1
    OUT_DIR=$2
    TUMOR_ID=$3
    NORMAL_ID=$4
    PATIENT_ID=$5

    conda activate $VARS_ENV

    (
    samtools mpileup \
        -f $REF_GENOME \
        -q 1 -B \
        $INPUT_DIR/$TUMOR_ID.sorted.du.bqsr.bam > $OUT_DIR/$TUMOR_ID.pileup

    samtools mpileup \
        -f $REF_GENOME \
        -q 1 -B \
        $INPUT_DIR/$NORMAL_ID.sorted.du.bqsr.bam > $OUT_DIR/$NORMAL_ID.pileup
    )

    wait
    conda deactivate

} 

run_somatic_varscan(){
    INPUT_DIR=$1
    OUT_DIR=$2
    TUMOR_ID=$3
    NORMAL_ID=$4
    PATIENT_ID=$5

    conda activate $VARS_ENV

    varscan somatic \
        $OUT_DIR/$NORMAL_ID.pileup \
        $OUT_DIR/$TUMOR_ID.pileup \
        $OUT_DIR/$PATIENT_ID.somatic \
        --output-vcf \
        --min-var-freq 0.05

    (
        varscan processSomatic $OUT_DIR/${PATIENT_ID}.somatic.snp.vcf --min-tumor-freq 0.05
        varscan processSomatic $OUT_DIR/${PATIENT_ID}.somatic.indel.vcf --min-tumor-freq 0.05
    )

    wait 

    conda deactivate 
}

run_germline_varscan(){
    INPUT_DIR=$1
    OUT_DIR=$2
    TUMOR_ID=$3
    NORMAL_ID=$4
    PATIENT_ID=$5

    conda activate $VARS_ENV

    varscan somatic \
        $OUT_DIR/$NORMAL_ID.pileup \
        $OUT_DIR/$TUMOR_ID.pileup \
        $OUT_DIR/$PATIENT_ID.germline \
        --output-vcf \
        --min-var-freq 0.1

    (
        varscan processSomatic $OUT_DIR/${PATIENT_ID}.germline.snp.vcf --min-tumor-freq 0.1
        varscan processSomatic $OUT_DIR/${PATIENT_ID}.germline.indel.vcf --min-tumor-freq 0.1
    )

    wait 
    
    conda deactivate 
}

run_varscan(){
    INPUT_DIR=$1
    OUT_DIR=$2
    TUMOR_ID=$3
    NORMAL_ID=$4
    PATIENT_ID=$5

    run_varscan_preprocessing \
        $INPUT_DIR \
        $OUT_DIR \
        $TUMOR_ID \
        $NORMAL_ID \
        $PATIENT_ID

    (
        run_somatic_varscan \
            $INPUT_DIR \
            $OUT_DIR \
            $TUMOR_ID \
            $NORMAL_ID \
            $PATIENT_ID

        run_germline_varscan \
            $INPUT_DIR \
            $OUT_DIR \
            $TUMOR_ID \
            $NORMAL_ID \
            $PATIENT_ID
    )

    wait

}