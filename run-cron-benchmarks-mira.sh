#!/bin/bash -x

basedir=${basedir:-$(readlink -f $(dirname "$0"))}

ior_exe=$basedir/ior/install/bin/ior
ior_outdir=$SCRATCH/tmp

# run ior shared file configuration
runjob -n 8192 -p 16 --block $COBALT_PARTNAME --verbose=INFO : $ior_exe -a MPIIO -w -r -c -b 4M -t 4M -s 8 -v -o $ior_outdir/ior.dat

# TODO run simple hacc-io, ls, etc tests

