#!/bin/bash
### This submit script is intended to be run from a subdirectory of the
### repository root, e.g., /home/$USER/this-repo/runs.  If you want to do
### something different, export REPO_BASE_DIR before invoking this script.

### implicit that this script is run from a subdirectory of the repo base
REPO_BASE_DIR="${REPO_BASE_DIR:-$(readlink -f $PWD/..)}"
TOKIO_BIN_DIR="${TOKIO_BIN_DIR:-${REPO_BASE_DIR}/bin}"
TOKIO_INPUTS_DIR="${REPO_BASE_DIR}/inputs"
TOKIO_JOB_DIR=${TOKIO_JOB_DIR:-$PWD}
TOKIO_PARAMS_FILE="${TOKIO_PARAMS_FILE:-$NERSC_HOST.params}"

### if not running in Slurm, just do a dry run
if [ -z "$SLURM_JOBID" ]; then
    srun_exe="echo srun"
    rm_exe="echo rm"
    rmdir_exe="echo rmdir"
    mkdir_exe="echo mkdir"
    lfs_exe="echo lfs"
    export TOKIO_JOBID="0000000" # export so that `envsubst` sees it
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
    export TOKIO_JOBID="$SLURM_JOBID" # export so that `envsubst` sees it
    function printlog() {
        echo "[$(date)] $@"
    }
    function printerr() {
        echo "[$(date)] $@" >&2
    }
fi

### the following assumes Darshan was configured with
###    --with-log-path-by-env=DARSHAN_LOGPATH
export DARSHAN_LOGPATH="$TOKIO_JOB_DIR"
printlog "Darshan logs will go to $DARSHAN_LOGPATH"

### Enable extra verbosity in MPI-IO to get insight into collective buffering
export MPICH_MPIIO_HINTS_DISPLAY=1
export MPICH_MPIIO_STATS=1

################################################################################
###  Basic parameter validation
################################################################################

if [ ! -d "$TOKIO_BIN_DIR" ]; then
    printerr "TOKIO_BIN_DIR=[$TOKIO_BIN_DIR] doesn't exist; likely to fail"
fi

if [ -z "$TOKIO_PARAMS_FILE" ]; then
    printerr "Undefined TOKIO_PARAMS_FILE" >&2; exit 1
    exit 1
fi
if [ ! -f "$TOKIO_PARAMS_FILE" ]; then
    TOKIO_PARAMS_FILE="$TOKIO_INPUTS_DIR/$TOKIO_PARAMS_FILE"
fi
if [ ! -f "$TOKIO_PARAMS_FILE" ]; then
    printerr "TOKIO_PARAMS_FILE=[$TOKIO_PARAMS_FILE] not found"
    exit 1
else
    printlog "Using TOKIO_PARAMS_FILE=[$TOKIO_PARAMS_FILE]"
fi

################################################################################
###  Helper functions to read and execute system-specific parameter sets
################################################################################

function setup_outdir() {
    if [ -z "$1" ]; then
        return 1
    else
        OUT_DIR=$1
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

    if [ -d "$OUT_DIR" ]; then
        printerr "$OUT_DIR already exists; striping may be affected"
    else
        ### if this is a private DataWarp namespace, we must create the
        ### directory in all namespaces
        if [[ ! -z "$DW_JOB_PRIVATE" && "$OUT_DIR" =~ $DW_JOB_PRIVATE ]]; then
            $srun_exe --ntasks-per-node=1 bash -c "mkdir -p ${OUT_DIR}"
        else
            $mkdir_exe -p $OUT_DIR || return 1
        fi

    fi

    ### set striping if necessary
    if lfs getstripe "$OUT_DIR" >/dev/null 2>&1; then
        $lfs_exe setstripe -c $stripe_ct "$OUT_DIR"
    fi
}

function delete_outdir() {
    OUT_FILE="$1"

    ### if this is a private DataWarp namespace, we must delete all matches
    ### from all namespaces
    if [[ ! -z "$DW_JOB_PRIVATE" && "$OUT_FILE" =~ $DW_JOB_PRIVATE ]]; then
        printlog "Deleting ${OUT_FILE}* and directory $(dirname $OUT_FILE) from all namespaces"
        $srun_exe --ntasks-per-node=1 bash -c "rm -f ${OUT_FILE}*; rmdir $(dirname $OUT_FILE)"
#       printlog "Not deleting anything due to burst buffer bug"
#       return 1
#   elif [[ ! -z "$DW_JOB_STRIPED" && "$OUT_FILE" =~ $DW_JOB_STRIPED ]]; then
#       printlog "Not deleting anything due to burst buffer bug"
#       return 1
    else
        printlog "Deleting ${OUT_FILE}*"
        $rm_exe -rf ${OUT_FILE}*
        printlog "Deleting directory $(dirname $OUT_FILE)"
        $rmdir_exe --ignore-fail-on-non-empty $(dirname $OUT_FILE)
    fi
}

function run_ior() {
    shift ### first argument is the benchmark name itself
    FS_NAME="$1"
    IOR_API="$(awk '{print tolower($0)}' <<< $2)"
    READ_OR_WRITE="$(awk '{print tolower($0)}' <<< $3)"
    OUT_FILE="$4"
    SEGMENT_CT="$5"
    NNODES="$6"
    NPROCS="$7"

    if [ "$READ_OR_WRITE" == "write" ]; then
        IOR_CLI_ARGS="-k -w"
        if [ "$IOR_API" == "posix" ]; then
            setup_outdir "$(dirname "$OUT_FILE")" 1
        elif [ "$IOR_API" == "mpiio" ]; then
            setup_outdir "$(dirname "$OUT_FILE")" -1
        else
            printerr "Unknown API [$IOR_API]"
        fi
    elif [ "$READ_OR_WRITE" == "read" ]; then
        IOR_CLI_ARGS="-r"
    else
        printerr "Unknown read-or-write parameter [$READ_OR_WRITE]"
        IOR_CLI_ARGS=""
        if [ "$IOR_API" == "posix" ]; then
            setup_outdir "$(dirname "$OUT_FILE")" 1
        elif [ "$IOR_API" == "mpiio" ]; then
            setup_outdir "$(dirname "$OUT_FILE")" -1
        fi
        # warn, but attempt to run r+w
    fi

    printlog "Submitting IOR: ${FS_NAME}-${IOR_API}"
    MPICH_MPIIO_HINTS="*:romio_cb_read=enable:romio_cb_write=enable" \
        $srun_exe -n ${NPROCS} \
         -N ${NNODES} \
         "${TOKIO_BIN_DIR}/ior" -H \
                    $IOR_CLI_ARGS \
                    -o "${OUT_FILE}" \
                    -s $SEGMENT_CT \
                    -f "${TOKIO_INPUTS_DIR}/${IOR_API}1m2.in" | tee "${TOKIO_JOB_DIR}/ior_${READ_OR_WRITE}-${FS_NAME}-${IOR_API}.${TOKIO_JOBID}.out"
    ret_val=$?
    printlog "Completed IOR: ${FS_NAME}-${IOR_API}"
    return $ret_val
}

function clean_ior() {
    shift ### first argument is the benchmark name itself
    OUT_FILE="$4"
    if [ ! -z "$OUT_FILE" ]; then
        delete_outdir "$OUT_FILE"
    fi
}

function run_haccio() {
    shift ### first argument is the benchmark name itself
    FS_NAME="$1"
    HACC_EXE="$2"
    OUT_FILE="$3"
    NNODES="$4"
    NPROCS="$5"
    NPARTS="${6:-28256364}"

    setup_outdir "$(dirname "$OUT_FILE")" 1
    printlog "Submitting HACC-IO: ${FS_NAME}-${HACC_EXE}"
    $srun_exe -n ${NPROCS} -N ${NNODES} "${TOKIO_BIN_DIR}/${HACC_EXE}" "$NPARTS" "${OUT_FILE}" | tee "${TOKIO_JOB_DIR}/haccio-${FS_NAME}-${HACC_EXE}.${TOKIO_JOBID}.out"
    ret_val=$?
    printlog "Completed HACC-IO: ${FS_NAME}-${HACC_EXE}"
    return $ret_val
}

function clean_haccio() {
    shift ### first argument is the benchmark name itself
    OUT_FILE="$3"
    if [ ! -z "$OUT_FILE" ]; then
        delete_outdir "$OUT_FILE"
    fi
}

function run_vpicio() {
    shift ### first argument is the benchmark name itself
    FS_NAME="$1"
    VPIC_EXE="$2"
    OUT_FILE="$3"
    NNODES="$4"
    NPROCS="$5"
    NPARTS="$6"

    setup_outdir "$(dirname "$OUT_FILE")" -1

    if [[ "$VPIC_EXE" =~ dbscan_read.* ]]; then
        extra_args="-d /Step#0/x -d /Step#0/y -d /Step#0/z -d /Step#0/px -d /Step#0/py -d /Step#0/pz -f ${OUT_FILE}"
    elif [[ "$VPIC_EXE" =~ vpicio_uni.* ]]; then
        extra_args="${OUT_FILE} ${NPARTS}"
    else
        printerr "Unknown VPIC exe [$VPIC_EXE]; not passing any extra CLI args" >&2
        extra_args="${OUT_FILE}"
    fi
    printlog "Submitting VPIC-IO: ${FS_NAME}-$(basename ${VPIC_EXE})"
    MPICH_MPIIO_HINTS="*:romio_cb_read=disable:romio_cb_write=disable" \
        $srun_exe -n ${NPROCS} -N ${NNODES} "${TOKIO_BIN_DIR}/${VPIC_EXE}" $extra_args | tee "${TOKIO_JOB_DIR}/vpicio-${FS_NAME}-$(basename ${VPIC_EXE}).${TOKIO_JOBID}.out"
    ret_val=$?
    printlog "Completed VPIC-IO: ${FS_NAME}-$(basename ${VPIC_EXE})"
    return $ret_val
}

function clean_vpicio() {
    shift ### first argument is the benchmark name itself
    OUT_FILE="$3"
    if [ ! -z "$OUT_FILE" ]; then
        delete_outdir "$OUT_FILE"
    fi
}

################################################################################
### Begin running benchmarks
################################################################################

### Load contents of parameters file into an array
PARAM_LINES=()
while read -r parameters; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    PARAM_LINES+=("$parameters")
done <<< "$(envsubst < "$TOKIO_PARAMS_FILE")"

### Dispatch benchmarks for each line in the parameters file
global_ret_val=0
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    benchmark=$(awk '{print $1}' <<< $parameters)
    if [ "$benchmark" == "ior" ]; then
        run_ior $parameters
        ret_val=$?
    elif [ "$benchmark" == "haccio" -o "$benchmark" == "hacc-io" ]; then
        run_haccio $parameters
        ret_val=$?
    elif [ "$benchmark" == "vpicio" -o "$benchmark" == "vpic-io" ]; then
        run_vpicio $parameters
        ret_val=$?
    fi
    [ $ret_val -ne 0 ] && global_ret_val=$ret_val
done

### Dispatch cleaning process for each line in the parameters file
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    benchmark=$(awk '{print $1}' <<< $parameters)
    if [ "$benchmark" == "ior" ]; then
        clean_ior $parameters
        ret_val=$?
    elif [ "$benchmark" == "haccio" -o "$benchmark" == "hacc-io" ]; then
        clean_haccio $parameters
        ret_val=$?
    elif [ "$benchmark" == "vpicio" -o "$benchmark" == "vpic-io" ]; then
        clean_vpicio $parameters
        ret_val=$?
    fi
done

exit $global_ret_val
