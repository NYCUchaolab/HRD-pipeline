 #!/usr/bin/bash

shopt -s expand_aliases
eval "$(conda shell.bash hook)"

source $HRD_PIPELINE_CONFIG
# prefetch --> parallel-fastq-dump --> {downstream pipeline}


download(){
    conda activate $SRA_ENV

    SRA=$1
    WORK_DIR=$2
    # OUTPUT_DIR=$3

    prefetch --ngc $NGC_TOKEN $SRA -O $WORK_DIR

    # THREAD=20
    # {
        
    #     parallel-fastq-dump -t $THREAD --split-3 --gzip -s $WORK_DIR/$SRA/$SRA.sra -O $OUTPUT_DIR 
    #     wait
    #     rm -r $WORK_DIR/$SRA/
    # } 

    conda deactivate
}

# development batch script??  parallel-fastq-dump RAM ... 

sra2fastq(){
    conda activate $SRA_ENV

    SRA=$1
    WORK_DIR=$2
    OUTPUT_DIR=$3

    parallel-fastq-dump -t $THREAD --split-3 --gzip -s $WORK_DIR/$SRA/$SRA.sra -O $OUTPUT_DIR 
    wait
    rm -r $WORK_DIR/$SRA/

    conda deactivate
}


trimming(){

    conda activate $PRE1_ENV
    INPUT_DIR=$1
    OUTPUT_DIR=$2
    SAMPLE=$3

    READ_1=${SAMPLE}_1.fastq.gz
    READ_2=${SAMPLE}_2.fastq.gz

    trimmomatic PE -threads $TRIM_THREAD \
        -phred33 ${INPUT_DIR}/$READ_1 ${INPUT_DIR}/$READ_2 \
        ${OUTPUT_DIR}/${SAMPLE}_R1_paired.fastq.gz \
        ${OUTPUT_DIR}/${SAMPLE}_R1_unpaired.fastq.gz \
        ${OUTPUT_DIR}/${SAMPLE}_R2_paired.fastq.gz \
        ${OUTPUT_DIR}/${SAMPLE}_R2_unpaired.fastq.gz \
        ILLUMINACLIP:${ADAPTER}:2:30:10:8:true \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:5:20 MINLEN:30

    conda deactivate
}

bwa_mapping(){

    READ_1=$1
    READ_2=$2
    OUT_FILE=$3 ## {OUT_DIR/SAMPLE.bam}
    SAMPLE=$4

    conda activate $PRE1_ENV

    bwa mem -t $THREAD \
        -aM -T 0 -R "@RG\tID:$SAMPLE\tSM:$SAMPLE\tPL:ILLUMINA" \
        $BWA_REF_GENOME \
        $READ_1 \
        $READ_2 | samtools view -@ $THREAD -Shb -o $OUT_FILE - 

    conda deactivate 
}

bam_sorting(){

    BAM_FILE=$1
    OUT_FILE=$2

    conda activate $PRE1_ENV

    picard SortSam \
        CREATE_INDEX=true \
        INPUT=${BAM_FILE}\
        OUTPUT=${OUT_FILE} \
        SORT_ORDER=coordinate \
        VALIDATION_STRINGENCY=STRICT 
    
    conda deactivate 
}

mark_duplicate(){
    
    conda activate $PRE1_ENV
    BAM_FILE=$1
    OUT_FILE=$2
    MATRIX_FILE=$3

    picard MarkDuplicates \
        I=$BAM_FILE \
        O=$OUT_FILE \
        M=$MATRIX_FILE \
        REMOVE_DUPLICATES=false \
        CREATE_INDEX=true

        conda deactivate 
}

bqsr(){

    BAM_FILE=$1
    OUT_FILE=$2
    REPORT_FILE=$3

    conda activate $GATK_ENV
    gatk --java-options -Xmx64g BaseRecalibrator \
        -R $REF_GENOME \
        -I $BAM_FILE \
        -O $REPORT_FILE \
        --known-sites $KNOWN_SITE_1 \
        --known-sites $KNOWN_SITE_2

    wait

    gatk --java-options -Xmx64g ApplyBQSR \
        -R $REF_GENOME \
        -I $BAM_FILE \
        -O $OUT_FILE \
        --bqsr-recal-file $REPORT_FILE

    conda deactivate
}

