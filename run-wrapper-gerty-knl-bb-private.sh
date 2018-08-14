#!/bin/bash
#
# This submit script is intended to be submitted from the repository's base dir.
#
#SBATCH -J tokio-abc-gerty-knl-bb
#SBATCH -N 96
#SBATCH -t 01:00:00
#SBATCH -C knl
#SBATCH -p knl
#DW jobdw type=scratch access_mode=private(client_cache=no) capacity=9TiB pool=wlm_pool

module load dws
dwstat all

i=0
today=$(date "+%Y-%m-%d")
output_base_dir="${SLURM_SUBMIT_DIR}/runs.${NERSC_HOST}.$today"
while [ -d "${output_base_dir}.$i" ]; do
    let "i++"
done
export TOKIO_JOB_DIR="${output_base_dir}.$i"
echo "[$(date)] Outputting to $TOKIO_JOB_DIR"

export REPO_BASE_DIR="${SLURM_SUBMIT_DIR}"
export TOKIO_BIN_DIR="${REPO_BASE_DIR}/bin.${NERSC_HOST}-knl"
export DARSHAN_LOGPATH="${TOKIO_JOB_DIR}"
export TOKIO_PARAMS_FILE="${REPO_BASE_DIR}/inputs/${NERSC_HOST}-knl-bb-private.params"

mkdir -p "$TOKIO_JOB_DIR" && cd "$TOKIO_JOB_DIR"
../run-cron-benchmarks-nersc.sh
