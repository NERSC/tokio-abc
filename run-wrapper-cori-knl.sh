#!/bin/bash
#
# This submit script is intended to be submitted from the repository's base dir.
#
#SBATCH -J tokio-abc-cori-knl
#SBATCH -N 256
#SBATCH -p debug
#SBATCH -t 00:30:00
#SBATCH -C knl
#SBATCH --mail-user=glock@lbl.gov
#SBATCH --mail-type=END
#DW jobdw type=scratch access_mode=striped capacity=7TiB pool=sm_pool
#DW jobdw type=scratch access_mode=private capacity=7TiB pool=sm_pool

i=0
while [ -d runs.$i ]; do
    let "i++"
done
echo "[$(date)] Outputting to runs.$i"

export REPO_BASE_DIR="${SLURM_SUBMIT_DIR}"
export TOKIO_LOGPATH="${SLURM_SUBMIT_DIR}/runs.$i"
export DARSHAN_LOGPATH="${TOKIO_LOGPATH}"
export TOKIO_PARAMS_FILE="${REPO_BASE_DIR}/inputs/cori-knl.params"

mkdir -p "$TOKIO_LOGPATH" && cd "$TOKIO_LOGPATH"
../run-cron-benchmarks-nersc.sh
