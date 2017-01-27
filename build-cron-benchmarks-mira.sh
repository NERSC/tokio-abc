#!/bin/sh

TOKIO_SRC_DIR=${TOKIO_SRC_DIR:-$(readlink -f $(dirname "$0"))}
TOKIO_INSTALL_DIR=${TOKIO_INSTALL_DIR:-$TOKIO_SRC_DIR}/bin

if [ "x$1" == "x" ]; then
    target="all"
else
    target="$1"
fi

EXTRA_AC_FLAGS="--host=powerpc-bgq-linux"
HDF5_ROOT=/soft/libraries/hdf5/current/cnk-xl/current/
ZLIB_ROOT=/soft/libraries/alcf/current/xl/ZLIB

export PATH=/soft/buildtools/autotools/26april2013/gnu/fen/bin:$PATH

mkdir -p $TOKIO_INSTALL_DIR

# build IOR
if [ "$target" == "ior" -o "$target" == "all" ]; then
    echo ""
    echo "*********************"
    echo "***** IOR BUILD *****"
    echo "*********************"
    echo ""

    cd $TOKIO_SRC_DIR/ior
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$TOKIO_INSTALL_DIR $EXTRA_AC_FLAGS CC=mpixlc
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

    cd $TOKIO_SRC_DIR/h5part
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --enable-parallel --with-hdf5=$HDF5_ROOT --prefix=$TOKIO_SRC_DIR/h5part/install $EXTRA_AC_FLAGS CC=mpixlc
    make install || exit 1
fi

# build VPIC-IO
if [ "$target" == "vpic-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** VPIC-IO BUILD *****"
    echo "*************************"
    echo ""

    cd $TOKIO_SRC_DIR/vpic-io
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${TOKIO_SRC_DIR}/h5part/install"'@' Makefile.in > Makefile
    export VPIC_CFLAGS="-I${HDF5_ROOT}/include -I${ZLIB_ROOT}/include"
    export VPIC_LDFLAGS="-L${HDF5_ROOT}/lib -L${ZLIB_ROOT}/lib"
    export VPIC_LDLIBS="-lhdf5 -lz"
    make CC=mpixlc || exit 1
    mv -v vpicio_uni $TOKIO_INSTALL_DIR
fi

# build BDCATS-IO
if [ "$target" == "bdcats-io" -o "$target" == "all" ]; then
    echo ""
    echo "***************************"
    echo "***** BDCATS-IO BUILD *****"
    echo "***************************"
    echo ""

    cd $TOKIO_SRC_DIR/bdcats-io
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${TOKIO_SRC_DIR}/h5part/install"'@' Makefile.in > Makefile
    export BDCATS_CFLAGS="-I${HDF5_ROOT}/include -I${ZLIB_ROOT}/include"
    export BDCATS_LDFLAGS="-L${HDF5_ROOT}/lib -L${ZLIB_ROOT}/lib"
    export BDCATS_LDLIBS="-lhdf5 -lz"
    make CC=mpixlcxx || exit 1
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
    make CXX=mpixlcxx fpp || exit 1
    mv -v hacc_io hacc_io_write hacc_io_read hacc_open_close $TOKIO_INSTALL_DIR
fi

# cleanup option
if [ "$target" == "clean" ]; then
    cat .gitignore | while read line
    do
        if [[ $line == "#"* || -z "${line// }" ]]; then
            continue
        fi
        if [[ -e "$line" && $line != ".."* ]]; then
            rm -rfv ./$line
        else
            find ./ -name $line -type f -exec rm -v {} \;
        fi
    done
fi

