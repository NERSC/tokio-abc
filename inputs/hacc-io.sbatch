#!/bin/bash
#
#  This will be folded into a run-cron-benchmarks-$NERSC_HOST.sh someday.  But
#  that day is not today.
#
#SBATCH -J haccio-tokio-abc
# 2304 procs = 96 nodes on Edison, 72 on Cori/Haswell, 36 on Cori/KNL(@64c)
#SBATCH -N 96
#SBATCH -p debug
#SBATCH -t 00:30:00

hacc_write_exe="${SLURM_SUBMIT_DIR}/../hacc-io/install/hacc_io_write"
hacc_read_exe="${SLURM_SUBMIT_DIR}/../hacc-io/install/hacc_io_read"
TOKIO_LOGPATH="$SLURM_SUBMIT_DIR"
export DARSHAN_LOGPATH="$TOKIO_LOGPATH"

for hacc_outdir in "/scratch1/scratchdirs/$USER" "/scratch2/scratchdirs/$USER" "/scratch3/scratchdirs/$USER"
do
    srun -n 2304 "$hacc_write_exe" 20971520 "${hacc_outdir}/hacc.dat" > "${TOKIO_LOGPATH}/haccio_write.$SLURM_JOBID.out"
    sleep 15
    srun -n 2304 "$hacc_read_exe" 20971520 "${hacc_outdir}/hacc.dat" > "${TOKIO_LOGPATH}/haccio_read.$SLURM_JOBID.out"
    rm ${hacc_outdir}/hacc.dat*
done
