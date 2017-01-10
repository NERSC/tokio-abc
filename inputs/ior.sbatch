#!/bin/bash
#
#  This will be folded into a run-cron-benchmarks-$NERSC_HOST.sh someday.  But
#  that day is not today.
#
#SBATCH -J ior-tokio-abc
#SBATCH -N 144
#SBATCH -p regular
#SBATCH -t 1:30:00

ior_exe="${SLURM_SUBMIT_DIR}/../ior/install/bin/ior"
TOKIO_LOGPATH="$SLURM_SUBMIT_DIR"
export DARSHAN_LOGPATH="$TOKIO_LOGPATH"

### So we can set Lustre striping of the shared file output
module load lustre-cray_ari_s
for out_dir in "/scratch1/scratchdirs/$USER/striped" "/scratch2/scratchdirs/$USER/striped" "/scratch3/scratchdirs/$USER/striped"
do
    mkdir -p $out_dir
    lfs setstripe -c -1 $out_dir
    lfs getstripe $out_dir
done

# note the different scratch file systems here--------.
#                                                     |
srun -n 2304 -N  96 "$ior_exe" -s 4096 -H -o "/scratch1/scratchdirs/$USER/striped/ior.out" -f "mpiio1m2.in" > "${TOKIO_LOGPATH}/ior-scratch1-ssf.$SLURM_JOBID.out"
srun -n 2304 -N  96 "$ior_exe" -s 4096 -H -o "/scratch2/scratchdirs/$USER/striped/ior.out" -f "mpiio1m2.in" > "${TOKIO_LOGPATH}/ior-scratch2-ssf.$SLURM_JOBID.out"
srun -n 3456 -N 144 "$ior_exe" -s 4096 -H -o "/scratch3/scratchdirs/$USER/striped/ior.out" -f "mpiio1m2.in" > "${TOKIO_LOGPATH}/ior-scratch3-ssf.$SLURM_JOBID.out"

# 32+32+48 < 144, so we can run all file-per-process runs concurrently
srun -n  768 -N  32 "$ior_exe" -s 4096 -H -o "/scratch1/scratchdirs/$USER/ior.out" -f "posix1m2.in" > "${TOKIO_LOGPATH}/ior-scratch1-fpp.$SLURM_JOBID.out" &
srun -n  768 -N  32 "$ior_exe" -s 4096 -H -o "/scratch2/scratchdirs/$USER/ior.out" -f "posix1m2.in" > "${TOKIO_LOGPATH}/ior-scratch2-fpp.$SLURM_JOBID.out" &
srun -n 1152 -N  48 "$ior_exe" -s 4096 -H -o "/scratch3/scratchdirs/$USER/ior.out" -f "posix1m2.in" > "${TOKIO_LOGPATH}/ior-scratch3-fpp.$SLURM_JOBID.out" &

wait

rm -rvf /scratch1/scratchdirs/$USER/striped
rm -rvf /scratch2/scratchdirs/$USER/striped
rm -rvf /scratch3/scratchdirs/$USER/striped
