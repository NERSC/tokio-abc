#!/bin/bash -x
#COBALT -A radix-io
#COBALT -n 1024
#COBALT -t 30
#COBALT --mode script

TOKIO_JOB_DIR=${TOKIO_JOB_DIR:-$(readlink -f $PWD/..)}
TOKIO_BIN_DIR=$TOKIO_JOB_DIR/bin
TOKIO_INPUTS_DIR=$TOKIO_JOB_DIR/inputs
TOKIO_OUT_DIR=${TOKIO_OUT_DIR:-$TOKIO_JOB_DIR/tmp}

error_code=0

function printlog() {
    echo "[$(date)] $@"
}
function printerr() {
    echo "[$(date)] $@" >&2
}

export MPICH_MPIIO_HINTS="*:romio_cb_read=enable:romio_cb_write=enable"

################################################################################
###  Helper functions to read and execute system-specific parameter sets
################################################################################

function run_ior() {
    IOR_API="$1"
    READ_OR_WRITE="$2"
    OUT_FILE="$3"
    NPROCS="$4"

    if [ "$READ_OR_WRITE" == "write" ]; then
        IOR_CLI_ARGS="-k -w"
    elif [ "$READ_OR_WRITE" == "read" ]; then
        IOR_CLI_ARGS="-r"
    else
        printerr "Unknown read-or-write parameter [$READ_OR_WRITE]"
        IOR_CLI_ARGS=""
        # warn, but attempt to run r+w
    fi

    if [ "$IOR_API" == "mpiio" ]; then
        ### Enable extra verbosity in MPI-IO to get insight into collective buffering
        export MPICH_MPIIO_HINTS_DISPLAY=1
        export MPICH_MPIIO_STATS=1
    fi

    printlog "Submitting IOR: $IOR_API-$READ_OR_WRITE"
    runjob -n $NPROCS -p 16 --block $COBALT_PARTNAME --envs BGLOCKLESSMPIO_F_TYPE=0x47504653 --verbose=INFO : \
        $TOKIO_BIN_DIR/ior \
            -H \
            $IOR_CLI_ARGS \
            -s 16 \
            -o $OUT_FILE \
            -f ${TOKIO_INPUTS_DIR}/${IOR_API}1m2.in
    ec=$?
    error_code=$((error_code + $ec))
    printlog "Completed IOR: $IOR_API-$READ_OR_WRITE [ec=$ec]"

    if [ "$IOR_API" == "mpiio" ]; then
        unset MPICH_MPIIO_HINTS_DISPLAY
        unset MPICH_MPIIO_STATS
    fi
}

function clean_ior() {
    OUT_FILE="$3"
    # no cleanup necessary due to IOR's keepFile option being disabled
}

# this many particles yields ~128 MiB/process
HACC_NUM_PARTICLES=3532026

function run_haccio() {
    HACC_EXE="$1"
    OUT_FILE="$2"
    NPROCS="$3"

    printlog "Submitting HACC-IO: ${HACC_EXE}"
    runjob -n $NPROCS -p 16 --block $COBALT_PARTNAME --envs BGLOCKLESSMPIO_F_TYPE=0x47504653 --verbose=INFO : \
        ${TOKIO_BIN_DIR}/${HACC_EXE} \
            $HACC_NUM_PARTICLES \
            $OUT_FILE
    ec=$?
    error_code=$((error_code + $ec))
    printlog "Completed HACC-IO: ${HACC_EXE} [ec=$ec]"
}

function clean_haccio() {
    OUT_FILE="$2"
    if [ ! -z "$OUT_FILE" ]; then
        printlog "Deleting ${OUT_FILE}*"
        rm -rf ${OUT_FILE}
    fi
}

function run_vpicio() {
    VPIC_EXE="$1"
    OUT_FILE="$2"
    NPROCS="$3"

    if [[ "$VPIC_EXE" =~ dbscan_read ]]; then
        exe_args="-d /Step#0/x -d /Step#0/y -d /Step#0/z -d /Step#0/px -d /Step#0/py -d /Step#0/pz -f $OUT_FILE"
    elif [[ "$VPIC_EXE" =~ vpicio_uni ]]; then
        exe_args="$OUT_FILE 1"
    else
        printerr "Unknown VPIC exe [$VPIC_EXE]; not passing any extra CLI args" >&2
        exe_args=""
    fi

    printlog "Submitting VPIC-IO: $VPIC_EXE"
    runjob -n $NPROCS -p 16 --block $COBALT_PARTNAME --envs BGLOCKLESSMPIO_F_TYPE=0x47504653 --verbose=INFO : \
        ${TOKIO_BIN_DIR}/${VPIC_EXE} \
            $exe_args
    ec=$?
    error_code=$((error_code + $ec))
    printlog "Completed VPIC-IO: $VPIC_EXE [ec=$ec]"
}

function clean_vpicio() {
    OUT_FILE="$2"
    if [ ! -z "$OUT_FILE" ]; then
        printlog "Deleting ${OUT_FILE}"
        rm -rf ${OUT_FILE}
    fi
}

################################################################################
###  IOR - MPI-IO shared-file and POSIX file-per-process
################################################################################

IOR_PARAMS_FILE="${TOKIO_INPUTS_DIR}/ior-mira.params"
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
done <<< "$(IOR_OUT_DIR="${TOKIO_OUT_DIR}" envsubst < "$IOR_PARAMS_FILE")"
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

HACCIO_PARAMS_FILE="${TOKIO_INPUTS_DIR}/haccio-mira.params"
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
done <<< "$(HACCIO_OUT_DIR="${TOKIO_OUT_DIR}" envsubst < "$HACCIO_PARAMS_FILE")"
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

VPICIO_PARAMS_FILE="${TOKIO_INPUTS_DIR}/vpicio-mira.params"
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
done <<< "$(VPICIO_OUT_DIR="${TOKIO_OUT_DIR}" envsubst < "$VPICIO_PARAMS_FILE")"
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

return $error_code
