TOKIO Automated Benchmark Collection - TOKIO-ABC(tm)
================================================================================

Test Run Configurations
--------------------------------------------------------------------------------

The following tables describe the input parameters for each TOKIO-ABC benchmark
application running at NERSC and ALCF.  The results of these daily tests have
been documented in

    G. K. Lockwood, W. Yoo, S. Byna, N. J. Wright, S. Snyder, K. Harms, Z.
    Nault, and P. Carns, "UMAMI: A Recipe for Generating Meaningful Metrics
    through Holistic I/O Performance Analysis," in Proceedings of the 2nd Joint
    International Workshop on Parallel Data Storage & Data Intensive Scalable
    Computing Systems - PDSW-DISCS'17, 2017, pp. 55--60.

and

    G. K. Lockwood, S. Snyder, T. Wang, S. Byna, P. Carns, and N. J. Wright, "A
    Year in the Life of a Parallel File System," in Proceedings of the
    International Conference for High Performance Computing, Networking,
    Storage, and Analysis - SC'18, 2018.

### NERSC Edison

Benchmark | Nodes | Procs | MiB/proc  | I/O Motif
----------|-------|-------|-----------|------------------------------------
IOR       |   128 |  2048 |    1024.0 | POSIX; file per process; write
IOR       |   128 |  2048 |    1024.0 | POSIX; file per process; read
IOR       |   128 |  2048 |     256.0 | MPI-IO; shared file; write
IOR       |   128 |  2048 |     256.0 | MPI-IO; shared file; read
HACC-IO   |   128 |  2048 |    1048.0 | GLEAN; file per process; write
HACC-IO   |   128 |  2048 |    1048.0 | GLEAN; file per process; read
VPIC-IO   |   128 |  2048 |    1024.0 | pHDF5; shared file; write
BDCATS-IO |   128 |  2048 |     768.0 | pHDF5; shared file; read

### ALCF Mira

Benchmark | Nodes | Procs | MiB/proc  | I/O Motif
----------|-------|-------|-----------|------------------------------------
IOR       |  1024 | 16384 |      64.0 | POSIX; file per process; write
IOR       |  1024 | 16384 |      64.0 | POSIX; file per process; read
IOR       |  1024 | 16384 |      64.0 | MPI-IO; shared file; write
IOR       |  1024 | 16384 |      64.0 | MPI-IO; shared file; read
HACC-IO   |  1024 | 16384 |     131.0 | GLEAN; file per process; write
HACC-IO   |  1024 | 16384 |     131.0 | GLEAN; file per process; read
VPIC-IO   |  1024 | 16384 |      56.0 | pHDF5; shared file; write
BDCATS-IO |  1024 | 16384 |      48.0 | pHDF5; shared file; read

### NERSC Cori (KNL) - cscratch

Benchmark | Nodes | Procs | MiB/proc  | I/O Motif
----------|-------|-------|-----------|------------------------------------
IOR       |   256 |  4096 |    4096.0 | POSIX; file per process; write
IOR       |   256 |  4096 |    4096.0 | POSIX; file per process; read
IOR       |   256 |  4096 |     256.0 | MPI-IO; shared file; write
IOR       |   256 |  4096 |     256.0 | MPI-IO; shared file; read
HACC-IO   |   256 |  4096 |    2072.0 | GLEAN; file per process; write
HACC-IO   |   256 |  4096 |    2072.0 | GLEAN; file per process; read
VPIC-IO   |   256 |  4096 |    1024.0 | pHDF5; shared file; write
BDCATS-IO |   256 |  4096 |     768.0 | pHDF5; shared file; read

### NERSC Cori (Haswell) - cscratch

Benchmark | Nodes | Procs | MiB/proc  | I/O Motif
----------|-------|-------|-----------|------------------------------------
IOR       |    32 |   512 |    8192.0 | POSIX; file per process; write
IOR       |    32 |   512 |    8192.0 | POSIX; file per process; read
IOR       |    32 |   512 |    2048.0 | MPI-IO; shared file; write
IOR       |    32 |   512 |    2048.0 | MPI-IO; shared file; read
HACC-IO   |    32 |   512 |    6168.0 | GLEAN; file per process; write
HACC-IO   |    32 |   512 |    6168.0 | GLEAN; file per process; read
VPIC-IO   |    32 |   512 |    1024.0 | pHDF5; shared file; write
BDCATS-IO |    32 |   512 |     768.0 | pHDF5; shared file; read

Overall Test Summary
--------------------------------------------------------------------------------

Platform    | File Sys   | Benchmark       | Read GiB | Write GiB
------------|------------|----------------:|---------:|----------:
Edison      |scratch1    |BD-CATS-IO       |   1536.0 |          
Edison      |scratch1    |HACC-IO/read     |   2096.0 |          
Edison      |scratch1    |HACC-IO/write    |          |    2096.0
Edison      |scratch1    |IOR/shared/write |          |     512.0
Edison      |scratch1    |IOR/fpp/write    |          |    2048.0
Edison      |scratch1    |IOR/shared/read  |    512.0 |          
Edison      |scratch1    |IOR/fpp/read     |   2048.0 |          
Edison      |scratch1    |VPIC-IO          |          |    2048.0
Edison      |scratch2    |BD-CATS-IO       |   1536.0 |          
Edison      |scratch2    |HACC-IO/read     |   2096.0 |          
Edison      |scratch2    |HACC-IO/write    |          |    2096.0
Edison      |scratch2    |IOR/shared/read  |    512.0 |          
Edison      |scratch2    |IOR/fpp/read     |   2048.0 |          
Edison      |scratch2    |IOR/shared/write |          |     512.0
Edison      |scratch2    |IOR/fpp/write    |          |    2048.0
Edison      |scratch2    |VPIC-IO          |          |    2048.0
Edison      |scratch3    |BD-CATS-IO       |   1536.0 |          
Edison      |scratch3    |HACC-IO/read     |   2096.0 |          
Edison      |scratch3    |HACC-IO/write    |          |    2096.0
Edison      |scratch3    |IOR/shared/write |          |     512.0
Edison      |scratch3    |IOR/fpp/write    |          |    2048.0
Edison      |scratch3    |IOR/shared/read  |    512.0 |          
Edison      |scratch3    |IOR/fpp/read     |   2048.0 |          
Edison      |scratch3    |VPIC-IO          |          |    2048.0
Mira        |mira-fs1    |BD-CATS-IO       |    768.0 |          
Mira        |mira-fs1    |HACC-IO/read     |   2096.0 |          
Mira        |mira-fs1    |HACC-IO/write    |          |    2096.0
Mira        |mira-fs1    |IOR/shared/write |          |    1024.0
Mira        |mira-fs1    |IOR/fpp/write    |          |    1024.0
Mira        |mira-fs1    |IOR/shared/read  |   1024.0 |          
Mira        |mira-fs1    |IOR/fpp/read     |   1024.0 |          
Mira        |mira-fs1    |VPIC-IO          |          |     896.0
Cori-KNL    |cscratch    |BD-CATS-IO       |   3072.0 |          
Cori-KNL    |cscratch    |HACC-IO/read     |   8288.0 |          
Cori-KNL    |cscratch    |HACC-IO/write    |          |    8288.0
Cori-KNL    |cscratch    |IOR/shared/write |          |    1024.0
Cori-KNL    |cscratch    |IOR/fpp/write    |          |   16384.0
Cori-KNL    |cscratch    |IOR/shared/read  |   1024.0 |          
Cori-KNL    |cscratch    |IOR/fpp/read     |  16384.0 |          
Cori-KNL    |cscratch    |VPIC-IO          |          |    4096.0
Cori-Haswell|cscratch    |BD-CATS-IO       |    384.0 |          
Cori-Haswell|cscratch    |HACC-IO/read     |   3084.0 |          
Cori-Haswell|cscratch    |HACC-IO/write    |          |    3084.0
Cori-Haswell|cscratch    |IOR/shared/write |          |    1024.0
Cori-Haswell|cscratch    |IOR/fpp/write    |          |    4096.0
Cori-Haswell|cscratch    |IOR/shared/read  |   1024.0 |          
Cori-Haswell|cscratch    |IOR/fpp/read     |   4096.0 |          
Cori-Haswell|cscratch    |VPIC-IO          |          |     512.0
Cori-KNL    |bb-shared   |BD-CATS-IO       |   4608.0 |          
Cori-KNL    |bb-shared   |HACC-IO/read     |  16480.0 |          
Cori-KNL    |bb-shared   |HACC-IO/write    |          |   16480.0
Cori-KNL    |bb-shared   |IOR/shared/write |          |    3072.0
Cori-KNL    |bb-shared   |IOR/shared/read  |   3072.0 |          
Cori-KNL    |bb-shared   |VPIC-IO          |          |    6144.0
Cori-KNL    |bb-private  |HACC-IO/read     |  20576.0 |          
Cori-KNL    |bb-private  |HACC-IO/write    |          |   20576.0
Cori-KNL    |bb-private  |IOR/fpp/write    |          |   16384.0
Cori-KNL    |bb-private  |IOR/fpp/read     |  16384.0 |          
Cori-Haswell|bb-shared   |BD-CATS-IO       |   1536.0 |          
Cori-Haswell|bb-shared   |HACC-IO/read     |   3084.0 |          
Cori-Haswell|bb-shared   |HACC-IO/write    |          |    3084.0
Cori-Haswell|bb-shared   |IOR/shared/write |          |    1024.0
Cori-Haswell|bb-shared   |IOR/shared/read  |   1024.0 |          
Cori-Haswell|bb-shared   |VPIC-IO          |          |    2048.0
Cori-Haswell|bb-private  |HACC-IO/read     |   3084.0 |          
Cori-Haswell|bb-private  |HACC-IO/write    |          |    3084.0
Cori-Haswell|bb-private  |IOR/fpp/write    |          |    4096.0
Cori-Haswell|bb-private  |IOR/fpp/read     |   4096.0 |          

At NERSC, 
- VPIC must be run with `MPICH_MPIIO_HINTS='*:romio_cb_write=disable'` to keep
  its walltime low
- Conversely, IOR must be run with
  `MPICH_MPIIO_HINTS='*:romio_cb_write=enable:romio_cb_read=enable'` to ensure
  the shared-file I/Os are sufficiently fast.

Benchmark Descriptions
--------------------------------------------------------------------------------

### IOR

The amount of data and the pattern by which it is accessed by the IOR benchmark
code is primarily a product of three configuration parameters:

- `transferSize` (or the -t CLI option)
- `blockSize` (or the -b CLI option)
- `segmentCount` (or the -s CLI option)
- `numTasks` (or the -N CLI option, or whatever is passed to mpirun/srun/aprun)

As an example, the absolute performance of the Lustre file system on NERSC's
Cori was achieved using the following job:

    srun -N 960 -n 3840 --ntasks-per-node=4 ./ior \
        -a POSIX \
        -F \
        -C \
        -e \
        -g \
        -b 4m \
        -t 4m \
        -s 1638 \
        -o $SCRATCH/IOR_file \
        -v \

where

- `-a POSIX` uses the POSIX API (this is the default option)
- `-F` uses file-per-process I/O (not default)
- `-C` reorders tasks between read and write to ensure nodes read data written
   by their neighbors
- `-e` uses fsync after write to ensure the timing reflects the full write time
- `-g` uses `MPI_Barrier()` after the write and read phases
- `-b 4m` uses a 4 MiB block size
- `-t 4m` uses 4 MiB transactions
- `-s 1638` uses 1,638 segments and was chosen so that the job writes out 24 TiB
- `-o $SCRATCH/IOR_file` writes to the `$SCRATCH` file system
- `-v` increases verbosity a little

### HACC-IO

Both read and write versions of the HACC-IO benchmark take two command-line
arguments:

- the number of particles, and
- the path to an output file

For example,

    srun -n 6144 ./hacc_io_write 20971520 $SCRATCH/hacc.dat

Each particle is 38 bytes, so the above example will generate a collection of
output files (one file per process by default), each containing 760 MiB of
particle data and a fixed-size (24. MiB) header.

When running the `hacc_io_read` benchmark, specify the same output file path
(e.g., `$SCRATCH/hacc.dat`) used when running `hacc_io_write`.  HACC-IO will
use this as the base file name and suffix per-rank identifiers on each file.

### VPIC-IO

VPIC-IO is an I/O kernel that emulates the writing of a checkpoint file as
performed by the [VPIC application][].  It is characterized by single
shared-file writes using the HDF5 library and MPI-IO, and it accepts one
or two command-line arguments:

- the path to an output file, and
- optionally, the number of particles per process in units of 1048576

For example,

    srun -n 1536 ./vpicio_uni $SCRATCH/vpic.hdf5 32

Each particle is 32 bytes (six 32-bit floats and two 32-bit integers), so the
above example will write out a total of 51,539,607,552 particles (1536
processes * 32 * 1048576 particles) or 1.500 TiB.  If the second parameter
is omitted, the default value is 32.  This corresponds to 1.0 GiB per process.
The benchmark does not touch any other file systems or `$PWD`.

The VPIC-IO benchmark was written by [Suren Byna] and depends on the
[H5Part library][].  The H5Part library included in this repository is derived
from [H5Part 1.6.6][] and requires HDF5 1.8.

### BD-CATS-IO

BD-CATS-IO is an I/O trace written by Suren that is derived from the
[BD-CATS clustering system][] which performs clustering analysis on large H5Part
files generated by VPIC (or VPIC-IO).

BD-CATS-IO requires you to specify at least two command line arguments when
running it:

- `-f /path/to/vpic.h5part` - the H5Part file to be read
- `-d "/ReadGroup/ReadDataset"` - the dataset in the given H5Part file to scan.
   Multiple `-d` arguments can/should be passed.

For example, the VPIC-IO kernel generates six datasets which can be scanned
using BD-CATS-IO by doing

    srun -n 32 ./dbscan_read -f $SCRATCH/vpicio.h5part -d '/Step#0/x' \
                                                       -d '/Step#0/y' \
                                                       -d '/Step#0/z' \
                                                       -d '/Step#0/px' \
                                                       -d '/Step#0/py' \
                                                       -d '/Step#0/pz'

[VPIC application]: https://github.com/losalamos/vpic
[Suren Byna]: https://sdm.lbl.gov/~sbyna/
[H5Part library]: http://vis.lbl.gov/Research/H5Part/
[H5Part 1.6.6]: https://codeforge.lbl.gov/projects/h5part/
[BD-CATS clustering system]: http://dx.doi.org/10.1145/2807591.2807616

Copyright and License
--------------------------------------------------------------------------------

Total Knowledge of I/O Copyright (c) 2017, The Regents of the University of
California, through Lawrence Berkeley National Laboratory (subject to receipt
of any required approvals from the U.S. Dept. of Energy).  All rights reserved.

If you have questions about your rights to use or distribute this software,
please contact Berkeley Lab's Innovation & Partnerships Office at IPO@lbl.gov.

NOTICE.  This Software was developed under funding from the U.S. Department of
Energy and the U.S. Government consequently retains certain rights. As such,
the U.S. Government has been granted for itself and others acting on its behalf
a paid-up, nonexclusive, irrevocable, worldwide license in the Software to
reproduce, distribute copies to the public, prepare derivative works, and
perform publicly and display publicly, and to permit other to do so.

For license terms, please see `LICENSE.md` included in this repository.  The
included benchmark application software (IOR, VPIC-IO, BD-CATS-IO, and HACC-IO)
are licensed separately from TOKIO-ABC.  Please see the `LICENSE` file included
in each application's subdirectory for the licensing terms of those software.
