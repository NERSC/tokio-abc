#!/bin/bash

set -e

TOKIO_SRC_DIR=$(readlink -f $(dirname "$0"))
TOKIO_INSTALL_DIR=${TOKIO_INSTALL_DIR:-$TOKIO_SRC_DIR}/bin
TOKIO_INSTALL_SUFFIX=""     ### .cori-knl, .cori-haswell, .edison -- see below

if [ "x$1" == "x" ]; then
    target="all"
else
    target="$1"
fi

if [ "$NERSC_HOST" == "edison" ]; then
    module load autoconf automake
    TOKIO_INSTALL_SUFFIX=".edison"
elif [ "$NERSC_HOST" == "cori" ]; then
    if [ ! -z "$CRAY_CPU_TARGET" -a "$CRAY_CPU_TARGET" == "mic-knl" ]; then
        EXTRA_AC_FLAGS="--host=x86_64-knl-linux"
        TOKIO_INSTALL_SUFFIX=".cori-knl"
    else
        TOKIO_INSTALL_SUFFIX=".cori-haswell"
    fi
fi

### Ensure binary directory exists
if [ ! -d "${TOKIO_INSTALL_DIR}${TOKIO_INSTALL_SUFFIX}" ]; then
    mkdir -p ${TOKIO_INSTALL_DIR}${TOKIO_INSTALL_SUFFIX}
fi

### Build IOR
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
    ../configure --prefix=$TOKIO_SRC_DIR/ior/install --without-gpfs $EXTRA_AC_FLAGS
    make || exit 1
    mv -v src/ior "${TOKIO_INSTALL_DIR}${TOKIO_INSTALL_SUFFIX}/"
fi

### Build H5Part (required by VPIC-IO and BD-CATS-IO)
if [ "$target" == "h5part" -o "$target" == "all" ]; then
    echo ""
    echo "************************"
    echo "***** H5PART BUILD *****"
    echo "************************"
    echo ""

    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd $TOKIO_SRC_DIR/h5part
    mkdir -p build
    ./bootstrap
    cd build
    ../configure --prefix=$TOKIO_SRC_DIR/h5part/install --enable-parallel $EXTRA_AC_FLAGS
    make install || exit 1
fi

### Build VPIC-IO
if [ "$target" == "vpic-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** VPIC-IO BUILD *****"
    echo "*************************"
    echo ""

    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd "${TOKIO_SRC_DIR}/vpic-io"
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${TOKIO_SRC_DIR}/h5part/install"'@' Makefile.in > Makefile
    make dynamic || exit 1
    mkdir -p install
    mv -v vpicio_uni "${TOKIO_INSTALL_DIR}${TOKIO_INSTALL_SUFFIX}/"
fi

### Build BDCATS-IO
if [ "$target" == "bdcats-io" -o "$target" == "all" ]; then
    echo ""
    echo "***************************"
    echo "***** BDCATS-IO BUILD *****"
    echo "***************************"
    echo ""

    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd "${TOKIO_SRC_DIR}/bdcats-io"
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${TOKIO_SRC_DIR}/h5part/install"'@' Makefile.in > Makefile
    make dynamic || exit 1
    mkdir -p install
    mv -v dbscan_read "${TOKIO_INSTALL_DIR}${TOKIO_INSTALL_SUFFIX}/"
fi

### Build HACC-IO
if [ "$target" == "hacc-io" -o "$target" == "all" ]; then
    echo ""
    echo "*************************"
    echo "***** HACC-IO BUILD *****"
    echo "*************************"
    echo ""

    cd $TOKIO_SRC_DIR/hacc-io
    make CXX=CC fpp || exit 1
    mkdir -p install
    mv -v hacc_io hacc_io_write hacc_io_read hacc_open_close "${TOKIO_INSTALL_DIR}${TOKIO_INSTALL_SUFFIX}/"
fi

### Cleanup option
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
    if [ -d "${TOKIO_INSTALL_DIR}${TOKIO_INSTALL_SUFFIX}" ]; then
        rm -r "${TOKIO_INSTALL_DIR}${TOKIO_INSTALL_SUFFIX}"
    fi
fi
