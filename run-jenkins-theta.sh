#!/bin/bash -x
#

JENKINS_WD=$PWD
AUTOMATED_WD=/projects/AutomatedBench/tokio-abc/
THETA_DLOGS=/lus/theta-fs0/logs/darshan/theta/

# ensure system darshan module is loaded
module load darshan

# configure and build
./build-cron-benchmarks-theta.sh
rc=$?

if [ $rc -eq 0 ];
then
  # copy binaries to PFS
  cp -r bin ${AUTOMATED_WD}/.

  # copy inputs to PFS
  cp -r inputs ${AUTOMATED_WD}/.

  # clear output directory
  rm -rf ${AUTOMATED_WD}/tmp/*

  # capture jenkins executor env in output logs
  module list
  env

  # submit to cobalt
  jid=$(qsub --cwd ${AUTOMATED_WD}/runs --env TOKIO_BASE_DIR=${AUTOMATED_WD} --run_project ${JENKINS_WD}/run-cron-benchmarks-theta.sh)
  rc=$?
  echo "Running as job: $jid"
  if [ $rc -eq 0 ]; then
    qstat -lf $jid
    cqwait $jid
    # check error code
    sleep 5
    exit_code=$(sed -n 's/.* exit code of \([0-9]\); initiating job cleanup and removal/\1/p' ${AUTOMATED_WD}/runs/${jid}.cobaltlog)
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

  # copy system darshan logs over
  # check today AND yesterday to make sure we get all of them
  today=`date "+%s"`
  yesterday=$(( today - 86400 ))
  cp -v ${THETA_DLOGS}/`date -d@${today} +"%Y"`/`date -d@${today} +"%-m"`/`date -d@${today} +"%-d"`/*id${jid}* ${AUTOMATED_WD}/runs/darshan-logs/
  cp -v ${THETA_DLOGS}/`date -d@${yesterday} +"%Y"`/`date -d@${yesterday} +"%-m"`/`date -d@${yesterday} +"%-d"`/*id${jid}* ${AUTOMATED_WD}/runs/darshan-logs/

  # print cobalt log in jenkins to simplify any debugging
  cat ${AUTOMATED_WD}/runs/${jid}.cobaltlog
else
  # return the failure from the build script
  echo "Build failed: $rc"
fi

exit $rc
