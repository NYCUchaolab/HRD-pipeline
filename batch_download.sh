shopt -s expand_aliases

source $HRD_PIPELINE_CONFIG

shopt -s expand_aliases

FILE_LIST=$1
INPUT_DIR=$2
OUT_DIR=$3

while read -r file; do
    [[ -z "$file" ]] && continue  # Skip empty lines
    echo "Downloading: $file"
    bash $HRD_DIR/download.sh $INPUT_DIR/$file $OUT_DIR $OUT_DIR
done < "$FILE_LIST"