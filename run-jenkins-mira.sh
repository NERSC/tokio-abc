#!/bin/bash
#
# This script is executed on miralac4 by the Jenkins CI slave as 'crusher'
#
source /etc/profile.d/00softenv.sh 

# set dependencies
soft add +mpiwrapper-xl.legacy

# configure and build
./build-cron-benchmarks-mira.sh

if [ $? -eq 0 ];
then
  # submit to cobale
  jid=$(qsub -A radix-io -n 2048 -t 30 --mode script --env SCRATCH=/projects/radix-io/automated ./run-cron-benchmarks-mira.sh)
  cqwait $jid
  # check error code
  exit_code=$(sed -n 's/.* exit code of \([0-9]\); initiating job cleanup and removal/\1/p' ${jid}.cobaltlog)
  if [ -n $exit_code  ] && [ "$ec" = "0" ]; then
    # return zero if the test script returned zero
    rc=0
  else
    # return something? if the test script failed
    rc=1
  fi
else
  # return the failure from the build script
  rc=$?
fi

exit $rc
