#!/bin/bash
#
# This submit script is intended to be submitted from the repository's base dir.
#
#SBATCH -J tokio-abc-cori-haswell
#SBATCH -N 32
#SBATCH -p debug
#SBATCH -t 00:30:00
#SBATCH -C haswell
#SBATCH --mail-user=glock@lbl.gov
#SBATCH --mail-type=END
#DW jobdw type=scratch access_mode=striped capacity=7TiB pool=sm_pool
#DW jobdw type=scratch access_mode=private capacity=7TiB pool=sm_pool

i=0
today=$(date "+%Y-%m-%d")
output_base_dir="${SLURM_SUBMIT_DIR}/runs.${NERSC_HOST}.$today"
while [ -d "${output_base_dir}.$i" ]; do
    let "i++"
done
export TOKIO_JOB_DIR="${output_base_dir}.$i"
echo "[$(date)] Outputting to $TOKIO_JOB_DIR"

export REPO_BASE_DIR="${SLURM_SUBMIT_DIR}"
export TOKIO_BIN_DIR="${REPO_BASE_DIR}/bin.cori-haswell"
export DARSHAN_LOGPATH="${TOKIO_JOB_DIR}"
export TOKIO_PARAMS_FILE="${REPO_BASE_DIR}/inputs/cori-haswell.params"

mkdir -p "$TOKIO_JOB_DIR" && cd "$TOKIO_JOB_DIR"
../run-cron-benchmarks-nersc.sh
