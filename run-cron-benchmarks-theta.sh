#!/bin/bash -x
#COBALT -A AutomatedBench
#COBALT -n 128
#COBALT -t 60
#COBALT --mode script

### This submit script is intended to be run from a subdirectory of the
### repository root, e.g., /home/$USER/this-repo/runs.  If you want to do
### something different, export TOKIO_BASE_DIR before invoking this script.

### implicit that this script is run from a subdirectory of the repo base
### also implicit that TOKIO_BASE_DIR has valid bin and input directories
TOKIO_BASE_DIR="${TOKIO_BASE_DIR:-$(readlink -f $PWD/..)}"
TOKIO_BIN_DIR="${TOKIO_BIN_DIR:-${TOKIO_BASE_DIR}/bin}"
TOKIO_INPUTS_DIR="${TOKIO_INPUTS_DIR:-${TOKIO_BASE_DIR}/inputs}"
TOKIO_SCRATCH_DIR="${TOKIO_SCRATCH_DIR:-${TOKIO_BASE_DIR}/tmp}"
TOKIO_PARAMS_FILE="${TOKIO_INPUTS_DIR}/theta.params"

export TOKIO_SCRATCH_DIR # export so that `envsubst` sees it

function printlog() {
    echo "[$(date)] $@"
}
function printerr() {
    echo "[$(date)] $@" >&2
}

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

    if [ -d "$OUT_DIR" ]; then
        printerr "$OUT_DIR already exists; striping may be affected"
    else
        mkdir -p $OUT_DIR || return 1
    fi

    ### set striping if necessary
    if lfs getstripe "$OUT_DIR" >/dev/null 2>&1; then
        lfs setstripe -c $stripe_ct "$OUT_DIR"
    fi
}

function delete_outdir() {
    OUT_FILE="$1"

    printlog "Deleting ${OUT_FILE}*"
    rm -rf ${OUT_FILE}*
    printlog "Deleting directory $(dirname $OUT_FILE)"
    rmdir --ignore-fail-on-non-empty $(dirname $OUT_FILE)
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
    aprun -n $NPROCS -N 16 \
        --env MPICH_MPIIO_HINTS="*:romio_cb_read=enable:romio_cb_write=enable" \
            "${TOKIO_BIN_DIR}/ior" -H \
                $IOR_CLI_ARGS \
                -o "${OUT_FILE}" \
                -s $SEGMENT_CT \
                -f "${TOKIO_INPUTS_DIR}/${IOR_API}1m2.in"
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
    aprun -n $NPROCS -N 16 \
        "${TOKIO_BIN_DIR}/${HACC_EXE}" "$NPARTS" "${OUT_FILE}"
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
    aprun -n $NPROCS -N 16 \
        --env MPICH_MPIIO_HINTS="*:romio_cb_read=disable:romio_cb_write=disable" \
            ${TOKIO_BIN_DIR}/${VPIC_EXE} $extra_args
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
