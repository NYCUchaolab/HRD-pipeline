#!/bin/bash

#!/usr/bin/bash

shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_DIR/utility/logger.sh


parse_SRA_samplesheet(){
    local sample_sheet="$1"
    
    log 1 "Parsing SRA sample sheet: $sample_sheet"
    
    # Declare variables
    Patient_ID=""
    Tumor_SRR_ID=""
    Normal_SRR_ID=""
    
    # Enable case-insensitive matching

    
    # Process the sample sheet line by line
    while IFS=$'\t' read -r Run alignment_software analyte_type Assay_Type \
        AvgSpotLen Bases BioProject BioSample biospecimen_repository biospecimen_repository_sample_id \
        Bytes Center_Name Consent_Code Consent DATASTORE_filetype DATASTORE_provider DATASTORE_region \
        Experiment gap_accession Instrument Is_Tumor Library_Name LibraryLayout LibrarySelection \
        LibrarySource Organism Platform ReleaseDate create_date version Sample_Name sex SRA_Study \
        study_design study_name submitted_subject_id; do

        shopt -s nocasematch

        Patient_ID="$submitted_subject_id"
        # Check if it's a tumor or normal sample based on the assay type
        if [[ $Is_Tumor =~ 'Yes' ]]; then
            log 1 "Detected Tumor sample: $Sample_Name ($submitted_subject_id)"
            Tumor_SRR_ID="$Run"
        elif [[ "$Is_Tumor" =~ "No" ]]; then
            log 1 "Detected Normal sample: $Sample_Name ($submitted_subject_id)"
            Normal_SRR_ID="$Run"
        else
            log 0 "ERROR: Unrecognized value '$Is_Tumor' for Is_Tumor in sample: $Sample_Name (Patient ID: $submitted_subject_id)"
            log 0 "Expected values are 'yes' or 'no'. Please check the data for any inconsistencies."
            # exit 1
        fi
    done < <(tail -n +2 "$sample_sheet")
    
    # Disable case-insensitive matching
    shopt -u nocasematch
    
    # Log the extracted information
    log 1 "Patient ID: ${Patient_ID}"
    log 1 "Tumor SRR ID: ${Tumor_SRR_ID}"
    log 1 "Normal SRR ID: ${Normal_SRR_ID}"
    
    # Return the extracted information
    # echo "$Patient_ID $Tumor_SRR_ID $Normal_SRR_ID"
}