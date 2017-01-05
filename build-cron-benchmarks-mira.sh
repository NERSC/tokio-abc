#!/bin/sh

basedir=$(readlink -f $(dirname "$0"))

# build IOR
cd $basedir/ior
mkdir -p build
./bootstrap
cd build
../configure --prefix=$basedir/ior/install --host=powerpc-bgp-linux
make install

