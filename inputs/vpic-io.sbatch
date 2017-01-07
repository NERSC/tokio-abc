#!/bin/bash
#
#  This will be folded into a run-cron-benchmarks-$NERSC_HOST.sh someday.  But
#  that day is not today.
#
#SBATCH -J tokio-abc-ior
#SBATCH -N 96
#SBATCH -p debug
#SBATCH -t 30:00

vpic_exe="${SLURM_SUBMIT_DIR}/../vpic-io/install/vpicio_uni"
bdcats_exe="${SLURM_SUBMIT_DIR}/../bdcats-io/install/dbscan_read"

# 2304 = 96 nodes on Edison, 72 on Cori/Haswell, 36 on Cori/KNL(@64c)

for vpic_outdir in "/scratch1/scratchdirs/$USER" "/scratch2/scratchdirs/$USER" "/scratch3/scratchdirs/$USER"
do
    srun -n 2304 "$vpic_exe" "${vpic_outdir}/vpic-io.hdf5"
    srun -n 2304 "$bdcats_exe" -f "${vpic_outdir}/vpic-io.hdf5" -d '/Step#0/x' -d '/Step#0/y' -d '/Step#0/z' -d '/Step#0/px' -d '/Step#0/py' -d '/Step#0/pz'
    rm -v "${vpic_outdir}/vpic-io.hdf5"
done
