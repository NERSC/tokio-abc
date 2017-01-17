#!/bin/bash -x
#
# This script is executed on miralac4 by the Jenkins CI slave as 'crusher'
#
source /etc/profile.d/00softenv.sh 

# set dependencies
soft add +mpiwrapper-xl.legacy

JENKINS_WD=$PWD
PROJ_WD=/projects/radix-io/automated

# configure and build
./build-cron-benchmarks-mira.sh

# copy script to GPFS to apease cobalt
# cp ./run-cron-benchmarks-mira.sh ${PROJ_WD}

if [ $? -eq 0 ];
then
  # submit to cobale
  jid=$(qsub -A radix-io --cwd ${PROJ_WD}/runs -n 2048 -t 30 --mode script --env SCRATCH=${PROJ_WD} --run_project ${JENKINS_WD}/run-cron-benchmarks-mira.sh)
  rc=$?
  echo "Running as job: $jid"
  if [ $? -eq 0 ]; then
    cqwait $jid
    # check error code
    ec=$(sed -n 's/.* exit code of \([0-9]\); initiating job cleanup and removal/\1/p' ${jid}.cobaltlog)
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
