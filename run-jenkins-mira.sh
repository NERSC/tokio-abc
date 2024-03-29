#!/bin/bash -x
#
# This script is executed on miralac4 by the Jenkins CI slave as 'crusher'
#
source /etc/profile.d/00softenv.sh 

# set dependencies
soft add +mpiwrapper-xl.legacy
export PATH=/bgsys/drivers/V1R2M2/ppc64/comm/bin/xl.legacy:${PATH}

JENKINS_WD=$PWD
PROJ_WD=/projects/radix-io/automated
day=$(date +"%Y%m%d")

# use Darshan 3.1.3 install
DARSHAN3_ROOT=/projects/radix-io/soft/darshan/darshan-3.1.3/install
export PATH=${DARSHAN3_ROOT}/bin:${PATH}
export MPICC_PROFILE=${DARSHAN3_ROOT}/share/mpi-profile/darshan-bg-cc
export MPICXX_PROFILE=${DARSHAN3_ROOT}/share/mpi-profile/darshan-bg-cxx

# XXX skip build until we sort out vpic/bdcats weirdness
# configure and build
#./build-cron-benchmarks-mira.sh
rc=$?

if [ $rc -eq 0 ];
then
  # XXX copy working binaries until we sort out vpic/bdcats weirdness
  # copy binaries to PFS
  #cp -r bin ${PROJ_WD}/.
  cp ${PROJ_WD}/bin/tmp_bin/* ${PROJ_WD}/bin/

  # copy inputs to PFS
  cp -r inputs ${PROJ_WD}/.

  # clear output directory
  rm -rf ${PROJ_WD}/tmp/*

  # record df
  /usr/lpp/mmfs/bin/mmdf mira-fs1 > ${PROJ_WD}/runs/gpfs-logs/df_fs1_${day}.txt
  /usr/lpp/mmfs/bin/mmdf mira-fs0 > ${PROJ_WD}/runs/gpfs-logs/df_fs0_${day}.txt

  # record nsd status
  /usr/lpp/mmfs/bin/mmlsdisk mira-fs1 > ${PROJ_WD}/runs/gpfs-logs/disk_status_fs1_${day}.txt
  /usr/lpp/mmfs/bin/mmlsdisk mira-fs0 > ${PROJ_WD}/runs/gpfs-logs/disk_status_fs0_${day}.txt

  # capture crusher's env in output logs
  cat ~/.soft
  env

  # submit to cobalt
  jid=$(qsub --cwd ${PROJ_WD}/runs --env TOKIO_JOB_DIR=${PROJ_WD} --run_project ${JENKINS_WD}/run-cron-benchmarks-mira.sh)
  rc=$?
  echo "Running as job: $jid"
  if [ $rc -eq 0 ]; then
    qstat -lf $jid
    cqwait $jid
    # check error code
    exit_code=$(sed -n 's/.* exit code of \([0-9]\); initiating job cleanup and removal/\1/p' ${PROJ_WD}/runs/${jid}.cobaltlog)
  fi
  if [ -z $exit_code ] || [ "$exit_code" != "0" ] ; then
    # return something? if the test script failed
    rc=1
    echo "Job failed with: $exit_code"
  else
    # return zero if the test script returned zero
    rc=0
    echo "Job succeeded: $rc"
  fi

  # print cobalt log in jenkins to simplify any debugging
  cat ${PROJ_WD}/runs/${jid}.cobaltlog

  # gather i/o stats from darshan logs for all successful runs
  ${JENKINS_WD}/utils/extract-darshan-perf.py ${PROJ_WD}/runs/darshan-logs/*id${jid}* >> ${PROJ_WD}/data/tokio-abc.dat
else
  # return the failure from the build script
  echo "Build failed: $rc"
fi

exit $rc
