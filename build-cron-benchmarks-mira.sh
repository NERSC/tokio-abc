#!/bin/sh

basedir=$(readlink -f $(dirname "$0"))

if [ "x$1" == "x" ]; then
    target="all"
else
    target="$1"
fi

EXTRA_AC_FLAGS="--host=powerpc-bgq-linux"
HDF5_ROOT=/soft/libraries/hdf5/current/cnk-xl/current/
ZLIB_ROOT=/soft/libraries/alcf/current/xl/ZLIB

# build IOR
if [ "$target" == "ior" -o "$target" == "all" ]; then
    echo ""
    echo "*********************"
    echo "***** IOR BUILD *****"
    echo "*********************"
    echo ""

    cd $basedir/ior
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$basedir/ior/install $EXTRA_AC_FLAGS CC=mpixlc
    make install || exit 1
fi

# build h5part (required by VPIC-IO and BD-CATS-IO
if [ "$target" == "h5part" -o "$target" == "all" ]; then
    echo ""
    echo "************************"
    echo "***** H5PART BUILD *****"
    echo "************************"
    echo ""

    cd $basedir/h5part
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --enable-parallel --with-hdf5=$HDF5_ROOT --prefix=$basedir/h5part/install $EXTRA_AC_FLAGS CC=mpixlc
    make install || exit 1
fi

# build VPIC-IO
if [ "$target" == "vpic-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** VPIC-IO BUILD *****"
    echo "*************************"
    echo ""

    cd $basedir/vpic-io
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${basedir}/h5part/install"'@' Makefile.in > Makefile
    export VPIC_CFLAGS="-I${HDF5_ROOT}/include -I${ZLIB_ROOT}/include"
    export VPIC_LDFLAGS="-L${HDF5_ROOT}/lib -L${ZLIB_ROOT}/lib"
    export VPIC_LDLIBS="-lhdf5 -lz"
    make CC=mpixlc || exit 1
    mkdir -p install/bin
    mv -v vpicio_uni install/bin
fi

# build BDCATS-IO
if [ "$target" == "bdcats-io" -o "$target" == "all" ]; then
    echo ""
    echo "***************************"
    echo "***** BDCATS-IO BUILD *****"
    echo "***************************"
    echo ""

    cd $basedir/bdcats-io
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${basedir}/h5part/install"'@' Makefile.in > Makefile
    export BDCATS_CFLAGS="-I${HDF5_ROOT}/include -I${ZLIB_ROOT}/include"
    export BDCATS_LDFLAGS="-L${HDF5_ROOT}/lib -L${ZLIB_ROOT}/lib"
    export BDCATS_LDLIBS="-lhdf5 -lz"
    make CC=mpixlcxx || exit 1
    mkdir -p install/bin
    mv -v dbscan_read install/bin
fi

# build HACC-IO
if [ "$target" == "hacc-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** HACC-IO BUILD *****"
    echo "*************************"
    echo ""

    cd $basedir/hacc-io
    make CXX=mpixlcxx fpp || exit 1
    mkdir -p install/bin
    mv -v hacc_io hacc_io_write hacc_io_read hacc_open_close install/bin
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

