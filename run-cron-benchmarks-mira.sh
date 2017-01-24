#!/bin/bash -x

basedir=$(readlink -f $(dirname "$0"))

ior_exe=${PROJ_WD:-$basedir/ior/install}/bin/ior
ior_outdir=${PROJ_WD:-/projects/radix-io/snyder}/tmp

function printl() {
    echo "[$(date)] $@"
}

read -r -d '' IOR_PARAM_SETS <<EOF
# ior_api output_file               nproc
# ------- ------------------------- -----
  mpiio   $ior_outdir/ior-mpiio.out 256
EOF
#  posix   $ior_outdir/ior-posix.out 256

################################################################################
###  Helper functions to read and execute system-specific parameter sets
################################################################################

function run_ior() {
    IOR_API="$1"
    OUT_FILE="$2"
    NPROCS="$3"

    printl "Submitting IOR: $IOR_API"
    runjob -n $NPROCS -p 16 --block $COBALT_PARTNAME --verbose=INFO : \
        $ior_exe -s 128 \
                 -H \
                 -o "$OUT_FILE" \
                 -f $basedir/inputs/"${IOR_API}1m2.in"
    printl "Completed IOR: $IOR_API"
}

function clean_ior() {
    OUT_FILE="$2"
    # no cleanup necessary due to IOR's keepFile option being disabled
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
