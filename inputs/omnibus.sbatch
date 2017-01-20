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

### if not running in slurm, just do a dry run
if [ -z "$SLURM_JOBID" ]; then
    srun_exe="echo srun"
    rm_exe="echo rm"
    mkdir_exe="echo mkdir"
    lfs_exe="echo lfs"
    SLURM_JOBID="0000000"
    SLURM_SUBMIT_DIR=$PWD
    DW_JOB_STRIPED='$DW_JOB_STRIPED'
    DW_JOB_PRIVATE='$DW_JOB_PRIVATE'
else
    srun_exe="srun"
    rm_exe="rm"
    mkdir_exe="mkdir"
    lfs_exe="lfs"
fi

ior_exe="${SLURM_SUBMIT_DIR}/../ior/install/bin/ior"
hacc_exe_path="${SLURM_SUBMIT_DIR}/../hacc-io/install"
vpic_exe_path="${SLURM_SUBMIT_DIR}/../vpic-io/install"

TOKIO_LOGPATH="$SLURM_SUBMIT_DIR"
export DARSHAN_LOGPATH="$TOKIO_LOGPATH"

################################################################################
###  System-specific input and setup parameters
################################################################################

###  Edison  ###################################################################

if [ "$NERSC_HOST" == "edison" ]; then
### Set up a directory with wide striping
module load lustre-cray_ari_s
for out_dir in "/scratch1/scratchdirs/$USER/striped" \
               "/scratch2/scratchdirs/$USER/striped" \
               "/scratch3/scratchdirs/$USER/striped"
do
    $mkdir_exe -p $out_dir && $lfs_exe setstripe -c -1 $out_dir
done

### Set up a directory with no striping (for file-per-process)
module load lustre-cray_ari_s
for out_dir in "/scratch1/scratchdirs/$USER/nostriped" \
               "/scratch2/scratchdirs/$USER/nostriped" \
               "/scratch3/scratchdirs/$USER/nostriped"
do
    $mkdir_exe -p $out_dir && $lfs_exe setstripe -c 1 $out_dir
done


read -r -d '' IOR_PARAM_SETS <<EOF
# fs_name  ior_api output_file                                       nnode nproc
# -------- ------- ------------------------------------------------- ----- -----
  scratch1 mpiio   /scratch1/scratchdirs/$USER/striped/ior.out       96     1536
  scratch2 mpiio   /scratch2/scratchdirs/$USER/striped/ior.out       96     1536
  scratch3 mpiio   /scratch3/scratchdirs/$USER/striped/ior.out       96     1536
  scratch1 posix   /scratch1/scratchdirs/$USER/nostriped/ior.out     96     1536
  scratch2 posix   /scratch2/scratchdirs/$USER/nostriped/ior.out     96     1536
  scratch3 posix   /scratch3/scratchdirs/$USER/nostriped/ior.out     96     1536
EOF

read -r -d '' HACC_PARAM_SETS <<EOF
# fs_name  hacc_exe      output_file                                            nnode nproc
# -------- ------------  ------------------------------------------------------ ----- -----
  scratch1 hacc_io_write /scratch1/scratchdirs/$USER/nostriped/haccio-write.out 96    1536
  scratch2 hacc_io_write /scratch2/scratchdirs/$USER/nostriped/haccio-write.out 96    1536
  scratch3 hacc_io_write /scratch3/scratchdirs/$USER/nostriped/haccio-write.out 96    1536
  scratch1 hacc_io_read  /scratch1/scratchdirs/$USER/nostriped/haccio-read.out  96    1536
  scratch2 hacc_io_read  /scratch2/scratchdirs/$USER/nostriped/haccio-read.out  96    1536
  scratch3 hacc_io_read  /scratch3/scratchdirs/$USER/nostriped/haccio-read.out  96    1536
EOF

read -r -d '' VPIC_PARAM_SETS <<EOF
# fs_name  vpic_exe       output_file                                     nnod nproc
# -------- -------------- ----------------------------------------------- ---- -----
  scratch1 vpicio_uni_dyn /scratch1/scratchdirs/$USER/striped/vpicio.hdf5 96   1536
  scratch2 vpicio_uni_dyn /scratch2/scratchdirs/$USER/striped/vpicio.hdf5 96   1536
  scratch3 vpicio_uni_dyn /scratch3/scratchdirs/$USER/striped/vpicio.hdf5 96   1536
  scratch1 dbscan_read    /scratch1/scratchdirs/$USER/striped/vpicio.hdf5 96   1536
  scratch2 dbscan_read    /scratch2/scratchdirs/$USER/striped/vpicio.hdf5 96   1536
  scratch3 dbscan_read    /scratch3/scratchdirs/$USER/striped/vpicio.hdf5 96   1536
EOF

###  Cori  #####################################################################

elif [ "$NERSC_HOST" == "cori" ]; then
### Set up a directory with wide striping
module load lustre-cray_ari_s
$mkdir_exe -p $SCRATCH/striped && $lfs_exe setstripe -c -1 $SCRATCH/striped
### ...and with no striping
$mkdir_exe -p $SCRATCH/nostriped && $lfs_exe setstripe -c 1 $SCRATCH/nostriped

read -r -d '' IOR_PARAM_SETS <<EOF
# fs_name  ior_api output_file                                       nnode nproc
# -------- ------- ------------------------------------------------- ----- -----
  cscratch mpiio   /global/cscratch1/sd/$USER/striped/ior.out        96     1536
  cscratch posix   /global/cscratch1/sd/$USER/nostriped/ior.out      96     1536
  dwlg_str mpiio   $DW_JOB_STRIPED/ior.out                           96     1536
  dwlg_pri posix   $DW_JOB_PRIVATE/ior.out                           96     1536
EOF

read -r -d '' HACC_PARAM_SETS <<EOF
# fs_name  hacc_exe      output_file                                            nnode nproc
# -------- ------------  ------------------------------------------------------ ----- -----
  cscratch hacc_io_write /global/cscratch1/sd/$USER/nostriped/haccio-write.out 96    1536
  dwlg_str hacc_io_write $DW_JOB_STRIPED/haccio-write.out                      96    1536
  dwlg_pri hacc_io_write $DW_JOB_PRIVATE/haccio-write.out                      96    1536
  cscratch hacc_io_read  /global/cscratch1/sd/$USER/nostriped/haccio-write.out 96    1536
  dwlg_str hacc_io_read  $DW_JOB_STRIPED/haccio-write.out                      96    1536
  dwlg_pri hacc_io_read  $DW_JOB_PRIVATE/haccio-write.out                      96    1536
EOF

read -r -d '' VPIC_PARAM_SETS <<EOF
# fs_name  vpic_exe       output_file                                     nnod nproc
# -------- -------------- ----------------------------------------------- ---- -----
  cscratch vpicio_uni_dyn /global/cscratch1/sd/$USER/striped/vpicio.hdf5  96   1536
  dwlg_str vpicio_uni_dyn $DW_JOB_STRIPED/vpicio.hdf5                     96   1536
  cscratch dbscan_read    /global/cscratch1/sd/$USER/striped/vpicio.hdf5  96   1536
  dwlg_str dbscan_read    $DW_JOB_STRIPED/vpicio.hdf5                     96   1536
EOF

###  Undefined #################################################################

elif [ -z "$NERSC_HOST" ]; then
    echo "[$(date)] Undefined NERSC_HOST" >&2
    exit 1

###  Unknown  ##################################################################

else
    echo "[$(date)] Unknown NERSC_HOST [$NERSC_HOST]" >&2
    exit 1
fi

################################################################################
###  Helper functions to read and execute system-specific parameter sets
################################################################################
function run_ior() {
    FS_NAME="$1"
    IOR_API="$2"
    OUT_FILE="$3"
    NNODES="$4"
    NPROCS="$5"

    echo "[$(date)] Submitting IOR: ${FS_NAME}-${IOR_API}"
    $srun_exe -n ${NPROCS} \
         -N ${NNODES} \
         "$ior_exe" -s 4096 \
                    -H \
                    -o "${OUT_FILE}" \
                    -f "${IOR_API}1m2.in" | tee "${TOKIO_LOGPATH}/ior-${FS_NAME}-${IOR_API}.${SLURM_JOBID}.out"
    echo "[$(date)] Completed IOR: ${FS_NAME}-${IOR_API}"
}

function clean_ior() {
    OUT_FILE="$3"
    echo "[$(date)] Deleting ${OUT_FILE}*"
    ### if this is a private DataWarp namespace, we must delete all matches from
    ### all namespaces
    if [[ ! -z "$DW_JOB_PRIVATE" && "$OUT_FILE" =~ $DW_JOB_PRIVATE ]]; then
        srun --ntasks-per-node=1 bash -c "rm ${OUT_FILE}*"
    else
        $rm_exe -rf ${OUT_FILE}*
    fi
}

function run_haccio() {
    FS_NAME="$1"
    HACC_EXE="$2"
    OUT_FILE="$3"
    NNODES="$4"
    NPROCS="$5"

    echo "[$(date)] Submitting HACC-IO: ${FS_NAME}-${HACC_EXE}"
    $srun_exe -n ${NPROCS} -N ${NNODES} "${hacc_exe_path}/${HACC_EXE}" 20971520 "${OUT_FILE}" | tee "${TOKIO_LOGPATH}/haccio-${FS_NAME}-${HACC_EXE}.${SLURM_JOBID}.out"
    echo "[$(date)] Completed HACC-IO: ${FS_NAME}-${HACC_EXE}"
}

function clean_haccio() {
    OUT_FILE="$3"
    echo "[$(date)] Deleting ${OUT_FILE}*"
    ### if this is a private DataWarp namespace, we must delete all matches from
    ### all namespaces
    if [[ ! -z "$DW_JOB_PRIVATE" && "$OUT_FILE" =~ $DW_JOB_PRIVATE ]]; then
        srun --ntasks-per-node=1 bash -c "rm ${OUT_FILE}*"
    else
        $rm_exe -rf ${OUT_FILE}*
    fi
}

function run_vpicio() {
    FS_NAME="$1"
    VPIC_EXE="$2"
    OUT_FILE="$3"
    NNODES="$4"
    NPROCS="$5"

    if [[ "$VPIC_EXE" =~ ^dbscan_read.* ]]; then
        extra_args="-d '/Step#0/x' -d '/Step#0/y' -d '/Step#0/z' -d '/Step#0/px' -d '/Step#0/py' -d '/Step#0/pz' -f"
    elif [[ "$VPIC_EXE" =~ ^vpicio_uni.* ]]; then
        extra_args=""
    else
        echo "[$(date)] Unknown VPIC exe [$VPIC_EXE]; not passing any extra CLI args" >&2
        extra_args=""
    fi
    echo "[$(date)] Submitting VPIC-IO: ${FS_NAME}-${VPIC_EXE}"
    $srun_exe -n ${NPROCS} -N ${NNODES} "${vpic_exe_path}/${VPIC_EXE}" $extra_args "${OUT_FILE}" | tee "${TOKIO_LOGPATH}/vpicio-${FS_NAME}-${VPIC_EXE}.${SLURM_JOBID}.out"
    echo "[$(date)] Completed VPIC-IO: ${FS_NAME}-${VPIC_EXE}"
}

function clean_vpicio() {
    OUT_FILE="$3"
    echo "[$(date)] Deleting ${OUT_FILE}*"
    ### if this is a private DataWarp namespace, we must delete all matches from
    ### all namespaces
    if [[ ! -z "$DW_JOB_PRIVATE" && "$OUT_FILE" =~ $DW_JOB_PRIVATE ]]; then
        srun --ntasks-per-node=1 bash -c "rm ${OUT_FILE}*"
    else
        $rm_exe -rf ${OUT_FILE}*
    fi
}

################################################################################
###  IOR - MPI-IO shared-file and POSIX file-per-process
################################################################################
echo "$IOR_PARAM_SETS" | while read parameters
do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]
    then
        continue
    fi
    run_ior $parameters
done
echo "$IOR_PARAM_SETS" | while read parameters
do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]
    then
        continue
    fi
    clean_ior $parameters
done

################################################################################
###  HACC-IO - Write and read using GLEAN file-per-process
################################################################################
echo "$HACC_PARAM_SETS" | while read parameters
do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]
    then
        continue
    fi
    run_haccio $parameters
done
echo "$HACC_PARAM_SETS" | while read parameters
do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]
    then
        continue
    fi
    clean_haccio $parameters
done

################################################################################
###  VPIC-IO - Write and read using HDF5 shared file (VPIC-IO and BD-CATS-IO)
################################################################################
echo "$VPIC_PARAM_SETS" | while read parameters
do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]
    then
        continue
    fi
    run_vpicio $parameters
done
echo "$VPIC_PARAM_SETS" | while read parameters
do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]
    then
        continue
    fi
    clean_vpicio $parameters
done


