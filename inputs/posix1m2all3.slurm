#!/bin/ksh
#SBATCH -n 2688
#SBATCH --tasks-per-node=24
#SBATCH -t 00:30:00
#SBATCH -J posix1m2all3
#SBATCH -o posix1m2all3.o%j

DIR=$PWD
SLURM_JOB_ID=${SLURM_JOB_ID:-$$}

PPN=24    # cores per node
FPO=8     # files per OST
REC=32m   # iobuf record size
export IOBUF_PARAMS="*/IOR*:count=2:size=${REC}:direct"

SCRDIR=./multdir
SEGMENTS=$(( 96 * 1024/$PPN ))               # write 96 GB on each 64 GB node
set -A NOST 0 96 96 144                    # OSTs per file system
set -A nodes 0 32 32 48
JOB=posix1m2

. /etc/profile.d/modules.sh
module load lustre-cray_ari_s
module list

for FS in 1 2 3; do
  mkdir -p /scratch${FS}/scratchdirs/$LOGNAME/tmp
  cd /scratch${FS}/scratchdirs/$LOGNAME/tmp || exit
  rm -rf $SCRDIR; mkdir $SCRDIR
  lfs setstripe -s 1m -c 1 $SCRDIR           # stripe count of 1
  RANKS=$(( $PPN*${nodes[$FS]} ))
  OUT=${DIR}/FS${FS}_${JOB}_${RANKS}ranks_${FPO}fpo_${PPN}ppn_${NOST[$FS]}osts_${SLURM_JOB_ID}
  cp -p $DIR/${JOB}.in .
  srun -n $RANKS -N ${nodes[$FS]} ${DIR}/../IOR -s $SEGMENTS -H -f ${JOB}.in < /dev/null > ${OUT}.IOR &
done

wait

echo " "
echo "IOBUF_PARAMS=$IOBUF_PARAMS" | tee -a ${OUT}.IOR

#ZZ for sending data to benchmark/monitor table
touch $SCRATCH/Edison_Perf/IOR/$SLURM_JOB_ID

#clean up
for FS in 1 2 3; do
   cd /scratch${FS}/scratchdirs/$LOGNAME/tmp || exit
   rm -rf $SCRDIR
done
