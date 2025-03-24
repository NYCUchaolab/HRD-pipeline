#!/usr/bin/sh

sbatch?(){
    sbatch_status=$1
    script=$2
    shift 2

    if [ $sbatch_status -eq 1 ]; then
        echo "SBATCH!!!"
        echo "sbatch $script $@"

    else
        echo "not SBATCH"
        echo "bash $script $@"
    fi
}

