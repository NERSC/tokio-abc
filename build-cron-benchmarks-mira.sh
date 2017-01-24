#!/bin/sh

basedir=$(readlink -f $(dirname "$0"))

if [ "x$1" == "x" ]; then
    target="all"
else
    target="$1"
fi

if [ "$target" == "ior" -o "$target" == "all" ]; then
    # build IOR
    echo ""
    echo "*********************"
    echo "***** IOR BUILD *****"
    echo "*********************"
    echo ""

    cd $basedir/ior
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$basedir/ior/install --host=powerpc-bgq-linux
    make install
fi

if [ "$target" == "hacc-io" -o "$target" == "all" ]; then
    # build HACC-IO
    echo ""
    echo "*************************"
    echo "***** HACC-IO BUILD *****"
    echo "*************************"
    echo ""

    cd $basedir/hacc-io
    make CXX=mpicxx fpp
    mkdir -p install/bin
    mv -v hacc_io hacc_io_write hacc_io_read hacc_open_close install/bin
fi
