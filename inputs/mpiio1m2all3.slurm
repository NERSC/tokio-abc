#!/bin/ksh
#SBATCH -n 8064
#SBATCH --tasks-per-node=24
#SBATCH -t 00:30:00
#SBATCH -J mpiio1m2all3
#SBATCH -o mpiio1m2all3.o%j

DIR=$PWD
SLURM_JOB_ID=${SLURM_JOB_ID:-$$}

PPN=24   # number of cores per node

SCRDIR=./singdir
SEGMENTS=$(( 96 * 1024/$PPN ))         # write 96 GB on each 64 GB node
set -A NOST 0 96 96 144                    # OSTs per file system
JOB=mpiio1m2

. /etc/profile.d/modules.sh
module load lustre-cray_ari_s
module list

for FS in 1 2 3; do
  mkdir -p /scratch${FS}/scratchdirs/$LOGNAME/tmp
  cd /scratch${FS}/scratchdirs/$LOGNAME/tmp || exit
  rm -rf $SCRDIR; mkdir $SCRDIR
  lfs setstripe -s 4m -c -1 $SCRDIR   # stripe single shared file on all OSTs
  RANKS=$(( $PPN*${NOST[$FS]} ))
  OUT=${DIR}/FS${FS}_${JOB}_${RANKS}ranks_${PPN}ppn_${NOST[$FS]}osts_${SLURM_JOB_ID}
  cp -p $DIR/${JOB}.in $DIR/mpiiohints .
  srun -n $RANKS -N ${NOST[$FS]} ${DIR}/../IOR -s $SEGMENTS -H -f ${JOB}.in < /dev/null > ${OUT}.IOR &
done

wait

#ZZ for sending data to benchmark/monitor table
touch $SCRATCH/Edison_Perf/IOR/$SLURM_JOB_ID

#clean up
for FS in 1 2 3; do
  cd /scratch${FS}/scratchdirs/$LOGNAME/tmp || exit
  rm -rf $SCRDIR
done

