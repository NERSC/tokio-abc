# TOKIO Automated Benchmark Collection - TOKIO-ABC(tm)

## Introduction

TODO

## Test Matrix (NERSC)

Benchmark | Nodes | Procs | GiB/proc  | I/O Motif
----------|-------|-------|-----------|------------------------------------
IOR       |  96   | 1536  | 1.0       | POSIX; file per process; write
IOR       |  96   | 1536  | 1.0       | POSIX; file per process; read
IOR       |  96   | 1536  | 1.0       | MPI-IO; shared file; write
IOR       |  96   | 1536  | 1.0       | MPI-IO; shared file; read
HACC-IO   |  96   | 1536  | 1.0       | GLEAN; file per process; write
HACC-IO   |  96   | 1536  | 1.0       | GLEAN; file per process; read
VPIC-IO   |  96   | 1536  | 1.0       | pHDF5; shared file; write
BDCATS-IO |  96   | 1536  | 1.0       | pHDF5; shared file; read

The following table contains some estimates of how long each benchmark takes.
**It is determined by whatever timing information is reported by the
application**.  Specifically:

- IOR: the `Mean(s)` value reported after `Summary of all tests:`
- HACC-IO: the `MaxTime[sec]` value
- VPIC-IO: the `seconds elapsed in opening, writing, closing file` value
- BDCATS-IO: the `Data read time` value

Benchmark        | Total GiB | escratch1 | escratch2 | escratch3 | cscratch |  dw_lg/s |  dw_lg/p |
-----------------|-----------|-----------|-----------|-----------|----------|----------|----------|
IOR/write/shared |  384.00   |  68.3 sec |  33.3 sec |  33.3 sec | 22.1 sec |  8.0 sec |      N/A |
IOR/read/shared  |  384.00   |  36.8 sec |  46.6 sec |  36.1 sec |    - sec |  7.8 sec |      N/A |
IOR/write/fpp    | 1536.00   |  54.0 sec |  48.3 sec |  38.6 sec |  7.5 sec |      N/A |  2.0 sec |
IOR/read/fpp     | 1536.00   |  40.3 sec |  40.5 sec |  27.2 sec | 12.1 sec |      N/A |  1.7 sec |
HACC-IO/write    | 1572.00   |  66.1 sec |  66.1 sec |  42.3 sec |  7.6 sec |  9.6 sec |  8.6 sec |
HACC-IO/read     | 1572.00   |  44.4 sec |  44.3 sec |  28.2 sec | 13.4 sec |  8.1 sec |  8.2 sec |
VPIC-IO          | 1536.00   |  95.3 sec | 112.1 sec |  95.4 sec |  334 sec | 13.3 sec |      N/A |
BDCATS-IO        | 1152.02   |  64.1 sec |  69.9 sec |  45.4 sec |   28 sec |   24 sec |      N/A |

VPIC must be run with `MPICH_MPIIO_HINTS='*:romio_cb_write=disable'` to keep its
walltime low.  Conversely, IOR must be run with
`MPICH_MPIIO_HINTS='*:romio_cb_write=enable:romio_cb_read=enable'` to ensure the
shared-file I/Os are sufficiently fast.

Per discussion on January 27, we should target a 30 second walltime for each
benchmark to balance test throughput with LMT data (which is sampled at 5-second
intervals).  The proposed justification for our choice of benchmarking
parameters (as Glenn remembers it) would be:

1. determine how many compute nodes on NERSC are required to achieve X% of peak
   file system performance
2. choose a dataset size to hit the 30 second interval at this node count
3. use this dataset size on Mira
4. figure out how many Mira nodes are required to make this go at a reasonable
   rate
5. adjust expectations given the scheduling and size constraints on Mira

## Test Matrix (ALCF-Mira)

Benchmark | Nodes | Procs | MiB/proc  | I/O time | I/O Motif
----------|-------|-------|-----------|------------------------------------
IOR       |  1024 | 16384 | 64.0      | POSIX; file per process; write
IOR       |  1024 | 16384 | 64.0      | POSIX; file per process; read
IOR       |  1024 | 16384 | 64.0      | MPI-IO; shared file; write
IOR       |  1024 | 16384 | 64.0      | MPI-IO; shared file; read
HACC-IO   |  1024 | 16384 | ~128.0    | GLEAN; file per process; write
HACC-IO   |  1024 | 16384 | ~128.0    | GLEAN; file per process; read
VPIC-IO   |  1024 | 16384 | 56.0      | pHDF5; shared file; write
BDCATS-IO |  1024 | 16384 | 48.0      | pHDF5; shared file; read

The following table contains some estimates of how long each benchmark takes
to run on the mira-fs1 GPFS volume.
**It is determined by whatever timing information is reported by the
application**.  Specifically:

- IOR: the `Mean(s)` value reported after `Summary of all tests:`
- HACC-IO: the `MaxTime[sec]` value
- VPIC-IO: the `seconds elapsed in opening, writing, closing file` value
- BDCATS-IO: the `Data read time` value

NOTES:
 * No HACC-IO results just yet -- was accidentally running these in BG/Q subfile mode instead of FPP.
 * BDCATS-IO results are estimated using job scheduler timing info -- debug output wasn't enabled, so no timing output by the app.

Benchmark        | Total GiB | I/O time  | I/O b/w      |
-----------------|-----------|-----------|--------------|
IOR/write/shared |  1024.00  |  ~2 min   | ~12.5 GiB/s  |
IOR/read/shared  |  1024.00  |  ~2 min   | ~11.5 GiB/s  |
IOR/write/fpp    |  1024.00  |  ~2 min   | ~14.0 GiB/s  |
IOR/read/fpp     |  1024.00  |  ~2 min   | ~18.0 GiB/s  |
HACC-IO/write    | ~2048.00  |     N/A   |         N/A  |
HACC-IO/read     | ~2048.00  |     N/A   |         N/A  |
VPIC-IO          |   896.00  |  ~1 min   | ~21.5 GiB/s  |
BDCATS-IO        |   768.00  | ~30 sec   | ~25.0 GiB/s  |

## Benchmark Descriptions

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
above example will write out a total of 103,079,215,104 particles (1536
processes * 64 * 1048576 particles) or 3.000 TiB.  If the second parameter
is omitted, the default value is 32.  This corresponds to 1.0 GiB per process.
The benhcmark does not touch any other file systems or `$PWD`.

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
