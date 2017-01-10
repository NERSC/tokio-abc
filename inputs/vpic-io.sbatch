#!/bin/bash
#
#  This will be folded into a run-cron-benchmarks-$NERSC_HOST.sh someday.  But
#  that day is not today.
#
#SBATCH -J vpicio-tokio-abc
# 2304 procs = 96 nodes on Edison, 72 on Cori/Haswell, 36 on Cori/KNL(@64c)
#SBATCH -N 96
#SBATCH -p regular
#SBATCH -t 1:30:00

vpic_exe="${SLURM_SUBMIT_DIR}/../vpic-io/install/vpicio_uni"
bdcats_exe="${SLURM_SUBMIT_DIR}/../bdcats-io/install/dbscan_read"
TOKIO_LOGPATH="$SLURM_SUBMIT_DIR"
export DARSHAN_LOGPATH="$TOKIO_LOGPATH"

### So we can set Lustre striping of the shared file output
module load lustre-cray_ari_s
for out_dir in "/scratch1/scratchdirs/$USER/striped" "/scratch2/scratchdirs/$USER/striped" "/scratch3/scratchdirs/$USER/striped"
do
    mkdir -p $out_dir
    lfs setstripe -c -1 $out_dir
done

for vpic_outdir in "/scratch1/scratchdirs/$USER/striped" "/scratch2/scratchdirs/$USER/striped" "/scratch3/scratchdirs/$USER/striped"
do
    if [ ! -d "$vpic_outdir" ]; then
        mkdir -p "$vpic_outdir"
    fi
    lfs setstripe -c -1 "$vpic_outdir"
    echo "Began $vpic_exe at $(date)"
    srun -n 2304 "$vpic_exe" "${vpic_outdir}/vpic-io.hdf5" > "${TOKIO_LOGPATH}/vpicio.$SLURM_JOBID.out"
    echo "Finished $vpic_exe at $(date)"
    sleep 15
    echo "Began $bdcats_exe at $(date)"
    srun -n 2304 "$bdcats_exe" -f "${vpic_outdir}/vpic-io.hdf5" -d '/Step#0/x' -d '/Step#0/y' -d '/Step#0/z' -d '/Step#0/px' -d '/Step#0/py' -d '/Step#0/pz' > "${TOKIO_LOGPATH}/bdcatsio.$SLURM_JOBID.out"
    echo "Finished $bdcats_exe at $(date)"
    rm -v ${vpic_outdir}
done
