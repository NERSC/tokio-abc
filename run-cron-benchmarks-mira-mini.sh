#!/bin/bash -x
#COBALT -A radix-io
#COBALT -n 16
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

function init_ior_tests() {
    printlog "Initializing IOR tests"
    mkdir -p $TOKIO_OUT_DIR/ior
}

function run_ior() {
    shift ### first argument is the benchmark name itself
    IOR_API="$1"
    READ_OR_WRITE="$2"
    OUT_FILE="$3"
    SEGMENT_CT="$4"
    NPROCS="$5"

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
    runjob -n $NPROCS -p 16 --block $COBALT_PARTNAME --envs BGLOCKLESSMPIO_F_TYPE=0x47504653 --envs DARSHAN_TOKIO_LOG_PATH=${TOKIO_JOB_DIR}/runs/darshan-logs --verbose=INFO : \
        $TOKIO_BIN_DIR/ior \
            -H \
            $IOR_CLI_ARGS \
            -s $SEGMENT_CT \
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

function cleanup_ior_tests() {
    printlog "Cleaning up IOR tests"
    rm -rf $TOKIO_OUT_DIR/ior
}

# this many particles yields ~96 MiB/process
HACC_NUM_PARTICLES=1986776

function init_haccio_tests() {
    printlog "Initializing HACC-IO tests"
    mkdir -p $TOKIO_OUT_DIR/hacc-io
}

function run_haccio() {
    shift ### first argument is the benchmark name itself
    HACC_EXE="$1"
    OUT_FILE="$2"
    NPROCS="$3"

    printlog "Submitting HACC-IO: ${HACC_EXE}"
    runjob -n $NPROCS -p 16 --block $COBALT_PARTNAME --envs BGLOCKLESSMPIO_F_TYPE=0x47504653 --envs DARSHAN_TOKIO_LOG_PATH=${TOKIO_JOB_DIR}/runs/darshan-logs --verbose=INFO : \
        ${TOKIO_BIN_DIR}/${HACC_EXE} \
            $HACC_NUM_PARTICLES \
            $OUT_FILE
    ec=$?
    error_code=$((error_code + $ec))
    printlog "Completed HACC-IO: ${HACC_EXE} [ec=$ec]"
}

function cleanup_haccio_tests() {
    printlog "Cleaning up HACC-IO tests"
    rm -rf $TOKIO_OUT_DIR/hacc-io
}

# this many particles (measured in units of 1048576 particles) yields 64 MiB/proc (1 TiB total)
VPIC_NUM_PARTICLES=2

function init_vpicio_tests() {
    printlog "Initializing VPIC-IO tests"
    mkdir -p $TOKIO_OUT_DIR/vpic-io
}

function run_vpicio() {
    shift ### first argument is the benchmark name itself
    VPIC_EXE="$1"
    OUT_FILE="$2"
    NPROCS="$3"

    if [[ "$VPIC_EXE" =~ dbscan_read ]]; then
        exe_args="-d /Step#0/x -d /Step#0/y -d /Step#0/z -d /Step#0/px -d /Step#0/py -d /Step#0/pz -f $OUT_FILE"
    elif [[ "$VPIC_EXE" =~ vpicio_uni ]]; then
        exe_args="$OUT_FILE $VPIC_NUM_PARTICLES"
    else
        printerr "Unknown VPIC exe [$VPIC_EXE]; not passing any extra CLI args" >&2
        exe_args=""
    fi

    printlog "Submitting VPIC-IO: $VPIC_EXE"
    runjob -n $NPROCS -p 16 --block $COBALT_PARTNAME --envs BGLOCKLESSMPIO_F_TYPE=0x47504653 --envs DARSHAN_TOKIO_LOG_PATH=${TOKIO_JOB_DIR}/runs/darshan-logs --verbose=INFO : \
        ${TOKIO_BIN_DIR}/${VPIC_EXE} \
            $exe_args
    ec=$?
    error_code=$((error_code + $ec))
    printlog "Completed VPIC-IO: $VPIC_EXE [ec=$ec]"
}

function cleanup_vpicio_tests() {
    printlog "Cleaning up VPIC-IO tests"
    rm -rf $TOKIO_OUT_DIR/vpic-io
}

################################################################################
### Begin running benchmarks
################################################################################

PARAMS_FILE="${TOKIO_INPUTS_DIR}/mira-mini.params"
if [ ! -f "$PARAMS_FILE" ]; then
    printerr "PARAMS_FILE=[$PARAMS_FILE] not found"
    exit 1
fi

### Initialize test environments
init_ior_tests
init_haccio_tests
init_vpicio_tests

### Load contents of parameters file into an array
PARAM_LINES=()
while read -r parameters; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    PARAM_LINES+=("$parameters")
done <<< "$(TOKIO_OUT_DIR="${TOKIO_OUT_DIR}" envsubst < "$PARAMS_FILE")"

### Dispatch benchmarks for each line in the parameters file
for parameters in "${PARAM_LINES[@]}"; do
    if [ -z "$parameters" ] || [[ "$parameters" =~ ^# ]]; then
        continue
    fi
    benchmark=$(awk '{print $1}' <<< $parameters)
    if [ "$benchmark" == "ior" ]; then
        run_ior $parameters
    elif [ "$benchmark" == "haccio" -o "$benchmark" == "hacc-io" ]; then
        run_haccio $parameters
    elif [ "$benchmark" == "vpicio" -o "$benchmark" == "vpic-io" ]; then
        run_vpicio $parameters
    fi
done

### Cleanup test environments
cleanup_ior_tests
cleanup_haccio_tests
cleanup_vpicio_tests

exit $error_code
