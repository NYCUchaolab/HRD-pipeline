#!/usr/bin/bash

shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_PIPELINE_DIR/preprocessing/utility.sh


shopt -s expand_aliases

SAMPLE_SHEET=$1
WORK_DIR=$2
OUT_DIR=$3

# skip first row
# first columns: SRR
#  csv file in .txt postfix
while IFS=$'\t' read -r Run alignment_software analyte_type Assay_Type \
    AvgSpotLen Bases BioProject BioSample biospecimen_repository biospecimen_repository_sample_id \
    Bytes Center_Name Consent_Code Consent DATASTORE_filetype DATASTORE_provider DATASTORE_region \
    Experiment gap_accession Instrument Is_Tumor Library_Name LibraryLayout LibrarySelection \
    LibrarySource Organism Platform ReleaseDate create_date version Sample_Name sex SRA_Study \
    study_design study_name submitted_subject_id; do

    echo $Run
    download $Run $WORK_DIR $OUT_DIR
    
done < <(tail -n +2 $SAMPLE_SHEET)



