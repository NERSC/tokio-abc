This document is a placeholder until I can upload the scripts we will want to
use in our automated IOR testing.   The following notes describe the automated
IOR runs currently being run on a weekly basis on all three Lustre file systems
on NERSC's Edison system.

### mpiio1m2all3

- job script is called `mpiio1m2all3.slurm`
- shared-file read+write whose concurrency depends on file system size
    - edison scratch1:
        -   **2,304 processes** (ppn=24 \* 96, where 96 used to be the OST
            count...)
        -   **9.00 TiB aggregate size** (1 MiB blocks, 96 \* 1024 / 24 segments,
            2304 processes)
    - edison scratch2:
        -   **2,304 processes** (ppn=24 \* 96, where 96 used to be the OST
            count...)
        -   **9.00 TiB aggregate size** (1 MiB blocks, 96 \* 1024 / 24 segments,
            2304 processes)
    - edison scratch3:
        -   **3,456 processes** (ppn=24 \* 144, where 144 used to be the OSt
            count...)
        -   **13.500 TiB aggregate size** (1 MiB blocks, 96 \* 1024 / 24
            segments, 2304 processes)
- IOR input deck in `mpiio1m2.in`
    - shared-file I/O
    - MPI-IO API
    - MPI-IO hints specified:
        -   romio\_cb\_read=enable
        -   romio\_cb\_write=enable
    - collective=1
    - **1,048,576-byte (1 MiB) blocks**
    - **1,048,576-byte (1 MiB) transfers**

### posix1m2all3

- job script is called `posix1m2all3.slurm`
- file per process read+write whose concurrency depends on file system size
- edison scratch1:
    -   **768 processes** (ppn=24 \* 32, where 32 is the current OST count
        with GridRAID)
    -   **3.00 TiB aggregate size** (1 MiB blocks, 96 \* 1024 / 24 segments,
        768 processes)
- edison scratch2:
    -  **768 processes** (ppn=24 \* 32, where 32 is the current OST count
        with GridRAID)
    -   **3.00 TiB aggregate size** (1 MiB blocks, 96 \* 1024 / 24 segments,
        768 processes)
- edison scratch3:
    -   **1,152 processes** (ppn=24 \* 48, where 48 is the current OST count
        with GridRAID)
    -   **4.500 TiB aggregate size** (1 MiB blocks, 96 \* 1024 / 24
        segments, 1152 processes)
- IOR input deck in `1m2.in`
    - file per process I/O
    - POSIX API
    - Cray IOBUF hints passed
        -   Note that *not all versions of IOR used for these tests were linked
            against IOBUF*!
        -   Darshan appears to have been used in the binary compiled on
            September 6, 2016, so jobs run after that date do not use IOBUF
        -   `IOBUF_PARAMS="*/IOR*:count=2:size=32m:direct"`
    - buffered I/O (`useO_DIRECT=0`), but this may be overridden by Cray iobuf (see above)
    - **1,048,576-byte (1 MiB) blocks**
    - **1,048,576-byte (1 MiB) transfers**

### mpiio1node\_all3

- job script is called `mpiio1node_all3.slurm`
- shared-file read+write with constant concurrency (1 node):
    -   **24 processes** (ppn=24, `srun -N 1`)
    -   **96.00 GiB aggregate size** (1 MiB blocks, 96 \* 1024 / 24
        segments, 24 processes)
- IOR input deck `mpiio1node.in`
    - shared-file I/O
    - MPI-IO API
    - MPI-IO hints specified:
        -   romio\_cb\_read=disable
        -   romio\_cb\_write=enable
    - collective=1
    - **1,048,576-byte (1 MiB) blocks**
    - **1,048,576-byte (1 MiB) transfers**

### posix1node\_all3

- job script is called `posix1node_all3.slurm`
- file-per-process read+write with constant concurrency (1 node):
    -   **24 processes** (ppn=24, `srun -N 1`)
    -   **96.00 GiB aggregate size** (1 MiB blocks, 96 \* 1024 / 24
        segments, 24 processes)
- IOR input deck is the same as posix1m2all3 (`1m2.in`)
