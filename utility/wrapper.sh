#!/bin/bash

# Check if at least one argument (the script to run) is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <script_to_run> [script_arguments...]"
    exit 1
fi

# Extract the script to run and its arguments
SCRIPT_TO_RUN=$1
shift
SCRIPT_ARGS="$@"



# Extract the filename without its extension
JOB_NAME=$(basename "$SCRIPT_TO_RUN")
JOB_NAME="${JOB_NAME%.*}"


# Submit the job using sbatch with the --wrap option
sbatch \
  -A MST109178 \
  -J $JOB_NAME \
  -p ngs372G \
  -c 56 \
  --mem=372g \
  --mail-user=hiiluann99.dump@gmail.com \
  --mail-type=FAIL \
  --wrap="bash ${SCRIPT_TO_RUN} ${SCRIPT_ARGS}"
