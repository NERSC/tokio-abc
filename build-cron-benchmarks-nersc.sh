#!/bin/sh

basedir=$(readlink -f $(dirname "$0"))

if [ "x$1" == "x" ]; then
    target="all"
else
    target="$1"
fi

# build IOR
if [ "$target" == "ior" -o "$target" == "all" ]; then
    cd $basedir/ior
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$basedir/ior/install --without-gpfs
    make install
fi

# build H5Part (required by VPIC-IO and BD-CATS-IO)
if [ "$target" == "h5part" -o "$target" == "all" ]; then
    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd $basedir/h5part
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$basedir/h5part/install --enable-parallel
    make install
fi
