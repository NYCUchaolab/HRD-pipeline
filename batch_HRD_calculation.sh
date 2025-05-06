shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG

shopt -s expand_aliases

FILE_LIST=$1
INPUT_DIR=$2
WORK_DIR=$3
OUT_DIR=$4

while read -r file; do
    [[ -z "$file" ]] && continue  # Skip empty lines
    bash $HRD_DIR/paired_hrd_score.sh $INPUT_DIR/$file $WORK_DIR $OUT_DIR
done < "$FILE_LIST"