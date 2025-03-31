<<<<<<< HEAD
#!/usr/bin/sh

=======
>>>>>>> Variant_calling
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

<<<<<<< HEAD
=======
sbatch? 1 script.sh 1 2 3 4
sbatch? 2 script2.sh 5 6 7 8
>>>>>>> Variant_calling
