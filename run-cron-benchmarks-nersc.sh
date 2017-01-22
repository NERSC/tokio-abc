#!/bin/bash
### To run on NERSC Cori, do something like (for KNL)
###
###    sbatch --bb=./bb-multi.conf -C knl omnibus.sbatch
###
### or (for Haswell)
###
###    sbatch --bb=./bb-multi.conf -C haswell omnibus.sbatch
###
### 2304 procs = 96 nodes on Edison, 72 on Cori/Haswell, 36 on Cori/KNL(@64c)
### 1536 procs = 64 nodes on Edison, 48 on Cori/Haswell, 24 on Cori/KNL(@64c)
#SBATCH -J tokio-abc
#SBATCH -N 96
#SBATCH -p regular
#SBATCH -t 04:00:00
#SBATCH --mail-user=glock@lbl.gov --mail-type=END

REPO_BASE=$SLURM_SUBMIT_DIR

module load lustre-cray_ari_s

function run_edison() {
mkdir -p /scratch1/scratchdirs/$USER/striped
lfs setstripe -c -1 /scratch1/scratchdirs/$USER/striped
mkdir -p /scratch2/scratchdirs/$USER/striped
lfs setstripe -c -1 /scratch2/scratchdirs/$USER/striped
mkdir -p /scratch3/scratchdirs/$USER/striped
lfs setstripe -c -1 /scratch3/scratchdirs/$USER/striped

mkdir -p /scratch1/scratchdirs/$USER/nostriped
lfs setstripe -c 1 /scratch1/scratchdirs/$USER/nostriped
mkdir -p /scratch2/scratchdirs/$USER/nostriped
lfs setstripe -c 1 /scratch2/scratchdirs/$USER/nostriped
mkdir -p /scratch3/scratchdirs/$USER/nostriped
lfs setstripe -c 1 /scratch3/scratchdirs/$USER/nostriped

srun -n 1536 -N 96 $REPO_BASE/ior/install/bin/ior -s 4096 -H -o /scratch1/scratchdirs/$USER/striped/ior.out -f mpiio1m2.in
srun -n 1536 -N 96 $REPO_BASE/ior/install/bin/ior -s 4096 -H -o /scratch2/scratchdirs/$USER/striped/ior.out -f mpiio1m2.in
srun -n 1536 -N 96 $REPO_BASE/ior/install/bin/ior -s 4096 -H -o /scratch3/scratchdirs/$USER/striped/ior.out -f mpiio1m2.in
srun -n 1536 -N 96 $REPO_BASE/ior/install/bin/ior -s 4096 -H -o /scratch1/scratchdirs/$USER/nostriped/ior.out -f posix1m2.in
srun -n 1536 -N 96 $REPO_BASE/ior/install/bin/ior -s 4096 -H -o /scratch2/scratchdirs/$USER/nostriped/ior.out -f posix1m2.in
srun -n 1536 -N 96 $REPO_BASE/ior/install/bin/ior -s 4096 -H -o /scratch3/scratchdirs/$USER/nostriped/ior.out -f posix1m2.in
rm -rf /scratch1/scratchdirs/$USER/striped/ior.out*
rm -rf /scratch2/scratchdirs/$USER/striped/ior.out*
rm -rf /scratch3/scratchdirs/$USER/striped/ior.out*
rm -rf /scratch1/scratchdirs/$USER/nostriped/ior.out*
rm -rf /scratch2/scratchdirs/$USER/nostriped/ior.out*
rm -rf /scratch3/scratchdirs/$USER/nostriped/ior.out*

srun -n 1536 -N 96 $REPO_BASE/hacc-io/install/hacc_io_write 20971520 /scratch1/scratchdirs/$USER/nostriped/haccio-write.out
srun -n 1536 -N 96 $REPO_BASE/hacc-io/install/hacc_io_write 20971520 /scratch2/scratchdirs/$USER/nostriped/haccio-write.out
srun -n 1536 -N 96 $REPO_BASE/hacc-io/install/hacc_io_write 20971520 /scratch3/scratchdirs/$USER/nostriped/haccio-write.out
srun -n 1536 -N 96 $REPO_BASE/hacc-io/install/hacc_io_read 20971520 /scratch1/scratchdirs/$USER/nostriped/haccio-read.out
srun -n 1536 -N 96 $REPO_BASE/hacc-io/install/hacc_io_read 20971520 /scratch2/scratchdirs/$USER/nostriped/haccio-read.out
srun -n 1536 -N 96 $REPO_BASE/hacc-io/install/hacc_io_read 20971520 /scratch3/scratchdirs/$USER/nostriped/haccio-read.out
rm -rf /scratch1/scratchdirs/$USER/nostriped/haccio-write.out*
rm -rf /scratch2/scratchdirs/$USER/nostriped/haccio-write.out*
rm -rf /scratch3/scratchdirs/$USER/nostriped/haccio-write.out*
rm -rf /scratch1/scratchdirs/$USER/nostriped/haccio-read.out*
rm -rf /scratch2/scratchdirs/$USER/nostriped/haccio-read.out*
rm -rf /scratch3/scratchdirs/$USER/nostriped/haccio-read.out*

srun -n 1536 -N 96 $REPO_BASE/vpic-io/install/vpicio_uni_dyn /scratch1/scratchdirs/$USER/striped/vpicio.hdf5
srun -n 1536 -N 96 $REPO_BASE/vpic-io/install/vpicio_uni_dyn /scratch2/scratchdirs/$USER/striped/vpicio.hdf5
srun -n 1536 -N 96 $REPO_BASE/vpic-io/install/vpicio_uni_dyn /scratch3/scratchdirs/$USER/striped/vpicio.hdf5
srun -n 1536 -N 96 $REPO_BASE/vpic-io/install/dbscan_read -d '/Step#0/x' -d '/Step#0/y' -d '/Step#0/z' -d '/Step#0/px' -d '/Step#0/py' -d '/Step#0/pz' -f /scratch1/scratchdirs/$USER/striped/vpicio.hdf5
srun -n 1536 -N 96 $REPO_BASE/vpic-io/install/dbscan_read -d '/Step#0/x' -d '/Step#0/y' -d '/Step#0/z' -d '/Step#0/px' -d '/Step#0/py' -d '/Step#0/pz' -f /scratch2/scratchdirs/$USER/striped/vpicio.hdf5
srun -n 1536 -N 96 $REPO_BASE/vpic-io/install/dbscan_read -d '/Step#0/x' -d '/Step#0/y' -d '/Step#0/z' -d '/Step#0/px' -d '/Step#0/py' -d '/Step#0/pz' -f /scratch3/scratchdirs/$USER/striped/vpicio.hdf5
rm -rf /scratch1/scratchdirs/$USER/striped/vpicio.hdf5*
rm -rf /scratch2/scratchdirs/$USER/striped/vpicio.hdf5*
rm -rf /scratch3/scratchdirs/$USER/striped/vpicio.hdf5*
rm -rf /scratch1/scratchdirs/$USER/striped/vpicio.hdf5*
rm -rf /scratch2/scratchdirs/$USER/striped/vpicio.hdf5*
rm -rf /scratch3/scratchdirs/$USER/striped/vpicio.hdf5*
}

function run_cori_knl() {
mkdir -p /global/cscratch1/sd/$USER/striped
lfs setstripe -c -1 /global/cscratch1/sd/$USER/striped
mkdir -p /global/cscratch1/sd/$USER/nostriped
lfs setstripe -c 1 /global/cscratch1/sd/$USER/nostriped
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../ior/install/bin/ior -s 4096 -H -o /global/cscratch1/sd/$USER/striped/ior.out -f $SLURM_SUBMIT_DIR/../inputs/mpiio1m2.in
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../ior/install/bin/ior -s 4096 -H -o /global/cscratch1/sd/$USER/nostriped/ior.out -f $SLURM_SUBMIT_DIR/../inputs/posix1m2.in
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../ior/install/bin/ior -s 4096 -H -o $DW_JOB_STRIPED/ior.out -f $SLURM_SUBMIT_DIR/../inputs/mpiio1m2.in
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../ior/install/bin/ior -s 4096 -H -o $DW_JOB_PRIVATE/ior.out -f $SLURM_SUBMIT_DIR/../inputs/posix1m2.in
rm -rf /global/cscratch1/sd/$USER/striped/ior.out*
rm -rf /global/cscratch1/sd/$USER/nostriped/ior.out*
rm -rf $DW_JOB_STRIPED/ior.out*
rm -rf $DW_JOB_PRIVATE/ior.out*
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../hacc-io/install/hacc_io_write 20971520 /global/cscratch1/sd/$USER/nostriped/haccio.out
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../hacc-io/install/hacc_io_write 20971520 $DW_JOB_STRIPED/haccio.out
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../hacc-io/install/hacc_io_write 20971520 $DW_JOB_PRIVATE/haccio.out
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../hacc-io/install/hacc_io_read 20971520 /global/cscratch1/sd/$USER/nostriped/haccio.out
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../hacc-io/install/hacc_io_read 20971520 $DW_JOB_STRIPED/haccio.out
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../hacc-io/install/hacc_io_read 20971520 $DW_JOB_PRIVATE/haccio.out
rm -rf /global/cscratch1/sd/$USER/nostriped/haccio.out*
rm -rf $DW_JOB_STRIPED/haccio.out*
rm -rf $DW_JOB_PRIVATE/haccio.out*
rm -rf /global/cscratch1/sd/$USER/nostriped/haccio.out*
rm -rf $DW_JOB_STRIPED/haccio.out*
rm -rf $DW_JOB_PRIVATE/haccio.out*
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../vpic-io/install/vpicio_uni_dyn /global/cscratch1/sd/$USER/striped/vpicio.hdf5
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../vpic-io/install/vpicio_uni_dyn $DW_JOB_STRIPED/vpicio.hdf5
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../bdcats-io/install/dbscan_read -d '/Step#0/x' -d '/Step#0/y' -d '/Step#0/z' -d '/Step#0/px' -d '/Step#0/py' -d '/Step#0/pz' -f /global/cscratch1/sd/$USER/striped/vpicio.hdf5
srun -n 1536 -N 96 $SLURM_SUBMIT_DIR/../bdcats-io/install/dbscan_read -d '/Step#0/x' -d '/Step#0/y' -d '/Step#0/z' -d '/Step#0/px' -d '/Step#0/py' -d '/Step#0/pz' -f $DW_JOB_STRIPED/vpicio.hdf5
rm -rf /global/cscratch1/sd/$USER/striped/vpicio.hdf5*
rm -rf $DW_JOB_STRIPED/vpicio.hdf5*
rm -rf /global/cscratch1/sd/$USER/striped/vpicio.hdf5*
rm -rf $DW_JOB_STRIPED/vpicio.hdf5*
}

if [ "$NERSC_HOST" == "edison" ]; then
    run_edison
elif [ "$NERSC_HOST" == "cori" ]; then
    run_cori_knl
else
    echo "Unknown NERSC_HOST(=$NERSC_HOST)" >&2
    exit 1
fi
