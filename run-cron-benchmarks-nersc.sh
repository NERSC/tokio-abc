#!/bin/bash
### This submit script is intended to be run from a subdirectory of the
### repository root, e.g., /home/$USER/this-repo/runs.  If you want to do
### something different, export REPO_BASE_DIR before invoking this script.

### implicit that this script is run from a subdirectory of the repo base
export REPO_BASE_DIR=${REPO_BASE_DIR:-$(readlink -f $PWD/..)}

### if not running in Slurm, just do a dry run
if [ -z "$SLURM_JOBID" ]; then
    srun_exe="echo srun"
    rm_exe="echo rm"
    rmdir_exe="echo rmdir"
    mkdir_exe="echo mkdir"
    lfs_exe="echo lfs"
    export TOKIO_JOBID="0000000"
    export TOKIO_JOBDIR="$PWD"
    export DW_JOB_STRIPED='$DW_JOB_STRIPED' # export so that `envsubst` sees it
    export DW_JOB_PRIVATE='$DW_JOB_PRIVATE' # export so that `envsubst` sees it
    function printlog() {
        :
    }
    function printerr() {
        echo "[$(date)] $@" >&2
    }
else
    srun_exe="srun"
    rm_exe="rm"
    rmdir_exe="rmdir"
    mkdir_exe="mkdir"
    lfs_exe="lfs"
    export TOKIO_JOBID="$SLURM_JOBID"
    export TOKIO_JOBDIR="$SLURM_SUBMIT_DIR"
    function printlog() {
        echo "[$(date)] $@"
    }
    function printerr() {
        echo "[$(date)] $@" >&2
    }
fi

### location to dump the stderr/stdout of each benchmark
export TOKIO_LOGPATH=${TOKIO_LOGPATH:-$TOKIO_JOBDIR}

### the following assumes Darshan was configured with
###    --with-log-path-by-env=DARSHAN_LOGPATH
export DARSHAN_LOGPATH="$TOKIO_LOGPATH"
printlog "Darshan logs will go to $DARSHAN_LOGPATH"

### Enable extra verbosity in MPI-IO to get insight into collective buffering
export MPICH_MPIIO_HINTS_DISPLAY=1
export MPICH_MPIIO_STATS=1

### these paths should not require site-specific modification
ior_exe="${REPO_BASE_DIR}/ior/install/bin/ior"
hacc_exe_path="${REPO_BASE_DIR}/hacc-io/install"
vpic_exe_path="${REPO_BASE_DIR}"

################################################################################
###  System-specific input and setup parameters
################################################################################

###  Edison  ###################################################################

if [ "$NERSC_HOST" == "edison" -o "$NERSC_HOST" == "edison-mini" -o "$NERSC_HOST" == "edison-micro" ]; then
    IOR_PARAMS_FILE="${REPO_BASE_DIR}/inputs/ior-${NERSC_HOST}.params"
    HACCIO_PARAMS_FILE="${REPO_BASE_DIR}/inputs/haccio-${NERSC_HOST}.params"
    VPICIO_PARAMS_FILE="${REPO_BASE_DIR}/inputs/vpicio-${NERSC_HOST}.params"

###  Cori  #####################################################################
elif [ "$NERSC_HOST" == "cori" -o "$NERSC_HOST" == "cori-mini" -o "$NERSC_HOST" == "cori-micro" ]; then
    IOR_PARAMS_FILE="${REPO_BASE_DIR}/inputs/ior-${NERSC_HOST}.params"
    HACCIO_PARAMS_FILE="${REPO_BASE_DIR}/inputs/haccio-${NERSC_HOST}.params"
    VPICIO_PARAMS_FILE="${REPO_BASE_DIR}/inputs/vpicio-${NERSC_HOST}.params"

###  Undefined #################################################################
elif [ -z "$NERSC_HOST" ]; then
    printerr "Undefined NERSC_HOST" >&2
    exit 1

###  Unknown  ##################################################################
else
    printerr "Unknown NERSC_HOST [$NERSC_HOST]" >&2
    exit 1
fi

################################################################################
###  Helper functions to read and execute system-specific parameter sets
################################################################################

function setup_outdir() {
    if [ -z "$1" ]; then
        return 1
    else
        out_dir=$1
    fi
    if [ -z "$2" ]; then
        stripe_ct=1
    else
        stripe_ct=$2
    fi
    ### load lfs module if necessary
    if ! which lfs >/dev/null 2>&1; then
        module load lustre-cray_ari_s
    fi

    if [ -d "$out_dir" ]; then
        printerr "$out_dir already exists; striping may be affected"
    else
        mkdir -p $out_dir || return 1
    fi

    ### set striping if necessary
    if lfs getstripe "$out_dir" >/dev/null 2>&1; then
        $lfs_exe setstripe -c $stripe_ct "$out_dir"
    fi
}

function run_ior() {
    FS_NAME="$1"
    IOR_API="$2"
    READ_OR_WRITE="$3"
    OUT_FILE="$4"
    NNODES="$5"
    NPROCS="$6"

    if [ "$READ_OR_WRITE" == "write" ]; then
        IOR_CLI_ARGS="-k -w"
        setup_outdir "$(dirname "$OUT_FILE")" 1
    elif [ "$READ_OR_WRITE" == "read" ]; then
        IOR_CLI_ARGS="-r"
    else
        printerr "Unknown read-or-write parameter [$READ_OR_WRITE]"
        IOR_CLI_ARGS=""
        setup_outdir "$(dirname "$OUT_FILE")" 1
        # warn, but attempt to run r+w
    fi

    printlog "Submitting IOR: ${FS_NAME}-${IOR_API}"
    MPICH_MPIIO_HINTS="*:romio_cb_read=enable:romio_cb_write=enable" \
        $srun_exe -n ${NPROCS} \
         -N ${NNODES} \
         "$ior_exe" -H \
                    $IOR_CLI_ARGS \
                    -o "${OUT_FILE}" \
                    -f "${REPO_BASE_DIR}/inputs/${IOR_API}1m2.in" | tee "${TOKIO_LOGPATH}/ior_${READ_OR_WRITE}-${FS_NAME}-${IOR_API}.${TOKIO_JOBID}.out"
    printlog "Completed IOR: ${FS_NAME}-${IOR_API}"
}

function clean_ior() {
    OUT_FILE="$4"
    if [ ! -z "$OUT_FILE" ]; then
        printlog "Deleting ${OUT_FILE}*"
        ### if this is a private DataWarp namespace, we must delete all matches
        ### from all namespaces
        if [[ ! -z "$DW_JOB_PRIVATE" && "$OUT_FILE" =~ $DW_JOB_PRIVATE ]]; then
            $srun_exe --ntasks-per-node=1 bash -c "rm -f ${OUT_FILE}*; rmdir $(dirname $OUT_FILE)"
        else
            $rm_exe -rf ${OUT_FILE}*
            $rmdir_exe $(dirname $OUT_FILE)
        fi
    fi
}

function run_haccio() {
    FS_NAME="$1"
    HACC_EXE="$2"
    OUT_FILE="$3"
    NNODES="$4"
    NPROCS="$5"

    setup_outdir "$(dirname "$OUT_FILE")" 1
    printlog "Submitting HACC-IO: ${FS_NAME}-${HACC_EXE}"
    $srun_exe -n ${NPROCS} -N ${NNODES} "${hacc_exe_path}/${HACC_EXE}" 28256364 "${OUT_FILE}" | tee "${TOKIO_LOGPATH}/haccio-${FS_NAME}-${HACC_EXE}.${TOKIO_JOBID}.out"
    printlog "Completed HACC-IO: ${FS_NAME}-${HACC_EXE}"
}

function clean_haccio() {
    OUT_FILE="$3"
    if [ ! -z "$OUT_FILE" ]; then
        printlog "Deleting ${OUT_FILE}*"
        ### if this is a private DataWarp namespace, we must delete all matches from
        ### all namespaces
        if [[ ! -z "$DW_JOB_PRIVATE" && "$OUT_FILE" =~ $DW_JOB_PRIVATE ]]; then
            $srun_exe --ntasks-per-node=1 bash -c "rm -f ${OUT_FILE}*; rmdir $(dirname $OUT_FILE)"
        else
            $rm_exe -rf ${OUT_FILE}*
            $rmdir_exe $(dirname $OUT_FILE)
        fi
    fi
}

function run_vpicio() {
    FS_NAME="$1"
    VPIC_EXE="$2"
    OUT_FILE="$3"
    NNODES="$4"
    NPROCS="$5"

    setup_outdir "$(dirname "$OUT_FILE")" -1

    if [[ "$VPIC_EXE" =~ dbscan_read.* ]]; then
        extra_args="-d /Step#0/x -d /Step#0/y -d /Step#0/z -d /Step#0/px -d /Step#0/py -d /Step#0/pz -f"
    elif [[ "$VPIC_EXE" =~ vpicio_uni.* ]]; then
        extra_args=""
    else
        printerr "Unknown VPIC exe [$VPIC_EXE]; not passing any extra CLI args" >&2
        extra_args=""
    fi
    printlog "Submitting VPIC-IO: ${FS_NAME}-$(basename ${VPIC_EXE})"
    $srun_exe -n ${NPROCS} -N ${NNODES} "${vpic_exe_path}/${VPIC_EXE}" $extra_args "${OUT_FILE}" | tee "${TOKIO_LOGPATH}/vpicio-${FS_NAME}-$(basename ${VPIC_EXE}).${TOKIO_JOBID}.out"
    printlog "Completed VPIC-IO: ${FS_NAME}-$(basename ${VPIC_EXE})"
}

function clean_vpicio() {
    OUT_FILE="$3"
    if [ ! -z "$OUT_FILE" ]; then
        printlog "Deleting ${OUT_FILE}*"
        $rm_exe -rf ${OUT_FILE}*
        $rmdir_exe $(dirname $OUT_FILE)
    fi
}

################################################################################
###  IOR - MPI-IO shared-file and POSIX file-per-process
################################################################################
if [ ! -f "$IOR_PARAMS_FILE" ]; then
    printerr "IOR_PARAMS_FILE=[$IOR_PARAMS_FILE] not found"
    IOR_PARAMS_FILE=/dev/null
fi
PARAM_LINES=()
while read -r parameters; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    PARAM_LINES+=("$parameters")
done <<< "$(envsubst < "$IOR_PARAMS_FILE")"
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    run_ior $parameters
done
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    clean_ior $parameters
done

################################################################################
###  HACC-IO - Write and read using GLEAN file-per-process
################################################################################
if [ ! -f "$HACCIO_PARAMS_FILE" ]; then
    printerr "HACCIO_PARAMS_FILE=[$HACCIO_PARAMS_FILE] not found"
    HACCIO_PARAMS_FILE=/dev/null
fi
PARAM_LINES=()
while read -r parameters; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    PARAM_LINES+=("$parameters")
done <<< "$(envsubst < "$HACCIO_PARAMS_FILE")"
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    run_haccio $parameters
done
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    clean_haccio $parameters
done

################################################################################
###  VPIC-IO - Write and read using HDF5 shared file (VPIC-IO and BD-CATS-IO)
################################################################################
if [ ! -f "$VPICIO_PARAMS_FILE" ]; then
    printerr "VPICIO_PARAMS_FILE=[$VPICIO_PARAMS_FILE] not found"
    VPICIO_PARAMS_FILE=/dev/null
fi
PARAM_LINES=()
while read -r parameters; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    PARAM_LINES+=("$parameters")
done <<< "$(envsubst < "$VPICIO_PARAMS_FILE")"
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    run_vpicio $parameters
done
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    clean_vpicio $parameters
done
