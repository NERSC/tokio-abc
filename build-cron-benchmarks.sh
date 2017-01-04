#!/bin/sh

basedir=$(realpath $(dirname "$0"))

# build IOR
cd $basedir/ior
mkdir -p build
./bootstrap
cd build
../configure --prefix=$basedir/ior/install
make install

# a

