#!/bin/bash -x
#
# This script is executed on miralac4 by the Jenkins CI slave as 'crusher'
#
source /etc/profile.d/00softenv.sh 

# set dependencies
soft add +mpiwrapper-xl.legacy

JENKINS_WD=$PWD
PROJ_WD=/projects/radix-io/automated
day=$(date +"%Y%m%d")

# configure and build
./build-cron-benchmarks-mira.sh


if [ $? -eq 0 ];
then

  # copy binaries to PFS
  for bin in ior/install/bin/ior;
  do
    cp ${bin} ${PROJ_WD}/bin/.
  done

  # record df
  mmdf mira-fs1 > ${PROJ_WD}/runs/df_fs1_${day}.txt
  mmdf mira-fs0 > ${PROJ_WD}/runs/df_fs0_${day}.txt

  # record nsd status
  mmlsdisk mira-fs1 > ${PROJ_WD}/runs/disk_status_fs1_${day}.txt
  mmlsdisk mira-fs0 > ${PROJ_WD}/runs/disk_status_fs0_${day}.txt

  # submit to cobalt
  jid=$(qsub -A radix-io --cwd ${PROJ_WD}/runs -n 2048 -t 30 --mode script --env JENKINS_WD=${JENKINS_WD}:PROJ_WD=${PROJ_WD} --run_project ${JENKINS_WD}/run-cron-benchmarks-mira.sh)
  rc=$?
  echo "Running as job: $jid"
  if [ $? -eq 0 ]; then
    qstat -lf $jid
    cqwait $jid
    # check error code
    ec=$(sed -n 's/.* exit code of \([0-9]\); initiating job cleanup and removal/\1/p' ${PROJ_WD}/runs/${jid}.cobaltlog)
  fi
  if [ -n $exit_code  ] && [ "$ec" = "0" ]; then
    # return zero if the test script returned zero
    rc=0
    echo "Job succeeded: $rc"
  else
    # return something? if the test script failed
    rc=1
    echo "Job failed with: $ec"
  fi
else
  # return the failure from the build script
  rc=$?
  echo "Build failed: $rc"
fi

exit $rc
