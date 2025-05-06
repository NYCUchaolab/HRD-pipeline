shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG
source $HRD_DIR/utility/logger.sh
source $HRD_DIR/utility/read_samplesheet.sh

shopt -s expand_aliases

FILE_LIST=$1
INPUT_DIR=$2
WORK_DIR=$3
OUT_DIR=$4

declare -a SRA_INFO_ARRAY

while read -r file; do
    [[ -z "$file" ]] && continue  # Skip empty lines
    parse_SRA_samplesheet $INPUT_DIR/$file
    SRA_INFO_ARRAY+=("$Tumor_SRR_ID")
    SRA_INFO_ARRAY+=("$Normal_SRR_ID")
    echo "$Tumor_SRR_ID"
    echo "$Normal_SRR_ID"
done < "$FILE_LIST"

bash $HRD_DIR/utility/wrapper_mod.sh \
    $HRD_PIPELINE_DIR/preprocessing/fastqc.sh \
    $WORK_DIR \
    $OUTPUT_DIR \
    ${SRA_INFO_ARRAY[@]} \







