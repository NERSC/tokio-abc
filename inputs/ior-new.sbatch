#!/bin/bash
#SBATCH -J ior2-tokio-abc
#SBATCH -N 144
#SBATCH -p regular
#SBATCH -t 1:30:00

read -r -d '' PARAM_SETS <<'EOF'
# fs_name  ior_api output_dir                           nnode nproc
# -------- ------- -----------------------------------  ----- -----
  scratch1 mpiio   /scratch1/scratchdirs/$USER/striped  96    2304
  scratch2 mpiio   /scratch2/scratchdirs/$USER/striped  96    2304
  scratch3 mpiio   /scratch3/scratchdirs/$USER/striped  144   3456
  scratch1 posix   /scratch1/scratchdirs/$USER/striped  32    768
  scratch2 posix   /scratch2/scratchdirs/$USER/striped  32    768
  scratch3 posix   /scratch3/scratchdirs/$USER/striped  48    1152
EOF

function run_ior() {
    FS_NAME="$1"
    IOR_API="$2"
    FS_PATH="$3"
    IOR_NNODES="$4"
    IOR_NPROCS="$5"

    echo "[$(date)] Submitting ${FS_NAME}-${IOR_API}"
    srun -n ${IOR_NPROCS} \
         -N ${IOR_NNODES} \
         "$ior_exe" -s 4096 \
                    -H \
                    -o "${FS_PATH}/ior-${IOR_API}.out" \
                    -f "${IOR_API}1m2.in" > "${TOKIO_LOGPATH}/ior-${FS_NAME}-${IOR_API}.${SLURM_JOBID}.out"
    echo "[$(date)] Completed ${FS_NAME}-${IOR_API}"
}

echo "$PARAM_SETS" | while read parameters
do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]
    then
        continue
    fi
    run_ior $parameters &
done

wait
