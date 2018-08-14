#!/bin/sh

TOKIO_SRC_DIR=${TOKIO_SRC_DIR:-$(readlink -f $(dirname "$0"))}
TOKIO_INSTALL_DIR=${TOKIO_INSTALL_DIR:-$TOKIO_SRC_DIR}/bin

if [ "x$1" == "x" ]; then
    target="all"
else
    target="$1"
fi

HDF5_ROOT=/soft/libraries/hdf5/1.8.14/cnk-xl/current/

mkdir -p $TOKIO_INSTALL_DIR

# build IOR
if [ "$target" == "ior" -o "$target" == "all" ]; then
    echo ""
    echo "*********************"
    echo "***** IOR BUILD *****"
    echo "*********************"
    echo ""

    cd $TOKIO_SRC_DIR/ior
    test -d build && rm -rvf build
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$TOKIO_INSTALL_DIR/ior/install --without-gpfs --host=x86_64 CC=cc
    make || exit 1
    mv -v src/ior $TOKIO_INSTALL_DIR
fi

# build h5part (required by VPIC-IO and BD-CATS-IO
if [ "$target" == "h5part" -o "$target" == "all" ]; then
    echo ""
    echo "************************"
    echo "***** H5PART BUILD *****"
    echo "************************"
    echo ""

    module load cray-hdf5-parallel
    cd $TOKIO_SRC_DIR/h5part
    test -d build && rm -rvf build
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$TOKIO_SRC_DIR/h5part/install --enable-parallel --host=x86_64 CC=cc
    make install || exit 1
fi

# build VPIC-IO
if [ "$target" == "vpic-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** VPIC-IO BUILD *****"
    echo "*************************"
    echo ""

    module load cray-hdf5-parallel
    cd $TOKIO_SRC_DIR/vpic-io
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${TOKIO_SRC_DIR}/h5part/install"'@' Makefile.in > Makefile
    make clean
    make dynamic CC=cc || exit 1
    mkdir -p install
    mv -v vpicio_uni $TOKIO_INSTALL_DIR
fi

# build BDCATS-IO
if [ "$target" == "bdcats-io" -o "$target" == "all" ]; then
    echo ""
    echo "***************************"
    echo "***** BDCATS-IO BUILD *****"
    echo "***************************"
    echo ""

    module load cray-hdf5-parallel
    cd $TOKIO_SRC_DIR/bdcats-io
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${TOKIO_SRC_DIR}/h5part/install"'@' Makefile.in > Makefile
    make clean
    make dynamic CC=cc || exit 1
    mkdir -p install
    mv -v dbscan_read $TOKIO_INSTALL_DIR
fi

# build HACC-IO
if [ "$target" == "hacc-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** HACC-IO BUILD *****"
    echo "*************************"
    echo ""

    cd $TOKIO_SRC_DIR/hacc-io
    make clean
    make CXX=CC fpp || exit 1
    mkdir -p install
    mv -v hacc_io hacc_io_write hacc_io_read hacc_open_close $TOKIO_INSTALL_DIR
fi
