#!/bin/bash
#
#  This will be folded into a run-cron-benchmarks-$NERSC_HOST.sh someday.  But
#  that day is not today.
#
#SBATCH -J tokio-abc-ior
#SBATCH -N 144
#SBATCH -p debug
#SBATCH -t 30:00

ior_exe="${SLURM_SUBMIT_DIR}/../ior/install/bin/ior"

# note the different scratch file systems here-------------------------.
#                                                                      |
srun -n 2304 -N  96 "$ior_exe" -s 4096 -H -o "/scratch1/scratchdirs/$USER/ior.out" -f "mpiio1m2.in"
srun -n 2304 -N  96 "$ior_exe" -s 4096 -H -o "/scratch2/scratchdirs/$USER/ior.out" -f "mpiio1m2.in"
srun -n 3456 -N 144 "$ior_exe" -s 4096 -H -o "/scratch3/scratchdirs/$USER/ior.out" -f "mpiio1m2.in" 
srun -n  768 -N  32 "$ior_exe" -s 4096 -H -o "/scratch1/scratchdirs/$USER/ior.out" -f "posix1m2.in" 
srun -n  768 -N  32 "$ior_exe" -s 4096 -H -o "/scratch2/scratchdirs/$USER/ior.out" -f "posix1m2.in" 
srun -n 1152 -N  48 "$ior_exe" -s 4096 -H -o "/scratch3/scratchdirs/$USER/ior.out" -f "posix1m2.in" 
