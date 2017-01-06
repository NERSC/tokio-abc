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

# build VPIC-IO
if [ "$target" == "vpic-io" -o "$target" == "all" ]; then
    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd "${basedir}/vpic-io"
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${basedir}/h5part/install"'@' Makefile.in > Makefile
    make || exit 1
    mkdir -p install
    mv -v vpicio_uni vpicio_uni_dyn install/
fi

# build BDCATS-IO
if [ "$target" == "bdcats-io" -o "$target" == "all" ]; then
    module load cray-hdf5-parallel ### assume HDF5 1.8 or higher
    cd "${basedir}/bdcats-io"
    sed -e 's@^H5PART_ROOT *=.*$@H5PART_ROOT='"${basedir}/h5part/install"'@' Makefile.in > Makefile
    make || exit 1
    mkdir -p install
    mv -v dbscan_read install/
fi

# build HACC-IO
if [ "$target" == "hacc-io" -o "$target" == "all" ]; then
    cd $basedir/hacc-io
    make CXX=CC fpp
    mkdir -p install
    mv -v hacc_io hacc_io_write hacc_io_read hacc_open_close install/
fi
