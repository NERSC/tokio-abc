#!/bin/bash -x
#
# This script is executed on miralac4 by the Jenkins CI slave as 'crusher'
#
source /etc/profile.d/00softenv.sh 

# set dependencies
soft add +mpiwrapper-xl.legacy
export PATH=/soft/perftools/autoperf-20160802/scripts/xl.legacy:${PATH}

JENKINS_WD=$PWD
PROJ_WD=/projects/radix-io/automated
day=$(date +"%Y%m%d")

#TODO use new version of darshan

# configure and build
./build-cron-benchmarks-mira.sh
rc=$?

if [ $rc -eq 0 ];
then
  # TODO set dashan log directory

  # copy binaries to PFS
  cp -r bin ${PROJ_WD}/.

  # copy inputs to PFS
  cp -r inputs ${PROJ_WD}/.

  # clear output directory
  rm -rf ${PROJ_WD}/tmp/*

  # record df
  /usr/lpp/mmfs/bin/mmdf mira-fs1 > ${PROJ_WD}/runs/df_fs1_${day}.txt
  /usr/lpp/mmfs/bin/mmdf mira-fs0 > ${PROJ_WD}/runs/df_fs0_${day}.txt

  # record nsd status
  /usr/lpp/mmfs/bin/mmlsdisk mira-fs1 > ${PROJ_WD}/runs/disk_status_fs1_${day}.txt
  /usr/lpp/mmfs/bin/mmlsdisk mira-fs0 > ${PROJ_WD}/runs/disk_status_fs0_${day}.txt

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
else
  # return the failure from the build script
  echo "Build failed: $rc"
fi

exit $rc
