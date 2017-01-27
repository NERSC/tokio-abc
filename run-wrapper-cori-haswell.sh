#!/bin/bash
#
# This submit script is intended to be submitted from the repository's base dir.
#
#SBATCH -J tokio-abc
#SBATCH -N 96
#SBATCH -p regular
#SBATCH -t 02:00:00
#SBATCH -C haswell
#DW jobdw type=scratch access_mode=striped capacity=7TiB pool=sm_pool
#DW jobdw type=scratch access_mode=private capacity=7TiB pool=sm_pool

export REPO_BASE_DIR="${SLURM_SUBMIT_DIR}"
export TOKIO_LOGPATH="${SLURM_SUBMIT_DIR}/runs"
export DARSHAN_LOGPATH="${TOKIO_LOGPATH}"
export NERSC_HOST="${NERSC_HOST}"

mkdir -p runs && cd runs
../run-cron-benchmarks-nersc.sh