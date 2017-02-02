#!/bin/bash

set -e

basedir=$(readlink -f $(dirname "$0"))

if [ "x$1" == "x" ]; then
    target="all"
else
    target="$1"
fi

if [ "$NERSC_HOST" == "edison" ]; then
    module load autoconf automake
fi

if [ ! -z "$CRAY_CPU_TARGET" -a "$CRAY_CPU_TARGET" == "mic-knl" ]; then
    EXTRA_AC_FLAGS="--host=x86_64-knl-linux"
fi

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
    ../configure --prefix=$basedir/ior/install --without-gpfs $EXTRA_AC_FLAGS
    make install || exit 1
fi

# build H5Part (required by VPIC-IO and BD-CATS-IO)
if [ "$target" == "h5part" -o "$target" == "all" ]; then
    echo ""
    echo "************************"
    echo "***** H5PART BUILD *****"
    echo "************************"
    echo ""

    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd $basedir/h5part
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$basedir/h5part/install --enable-parallel $EXTRA_AC_FLAGS
    make install || exit 1
fi

# build VPIC-IO
if [ "$target" == "vpic-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** VPIC-IO BUILD *****"
    echo "*************************"
    echo ""

    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd "${basedir}/vpic-io"
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${basedir}/h5part/install"'@' Makefile.in > Makefile
    export VPIC_CFLAGS="-D__LUSTRE_FS"
    make dynamic || exit 1
    mkdir -p install
    mv -v vpicio_uni vpicio_uni_dyn install/
fi

# build BDCATS-IO
if [ "$target" == "bdcats-io" -o "$target" == "all" ]; then
    echo ""
    echo "***************************"
    echo "***** BDCATS-IO BUILD *****"
    echo "***************************"
    echo ""

    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd "${basedir}/bdcats-io"
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${basedir}/h5part/install"'@' Makefile.in > Makefile
    make dynamic || exit 1
    mkdir -p install
    mv -v dbscan_read install/
fi

# build HACC-IO
if [ "$target" == "hacc-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** HACC-IO BUILD *****"
    echo "*************************"
    echo ""

    cd $basedir/hacc-io
    make CXX=CC fpp || exit 1
    mkdir -p install
    mv -v hacc_io hacc_io_write hacc_io_read hacc_open_close install/
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
