#!/usr/bin/env bash
#
#  Called directly by cron.  Should have a crontab entry that looks something like
#
#     20 16   *  *   * /home/jane/tokio-abc/run-wrapper-submit-nersc.sh edison
#
#  If NERSC_HOST is not defined (it is not within the cron environment), you can
#  pass a value for it to this script as argv[1].
#
REPO_BASE_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"

cd "$REPO_BASE_DIR"

if [ -z "$NERSC_HOST" -a ! -z "$1" ]; then
    export NERSC_HOST="$1"
fi

if [ "$NERSC_HOST" == "edison" ]; then
    scripts=("run-wrapper-edison-scratch1.sh"
             "run-wrapper-edison-scratch2.sh"
             "run-wrapper-edison-scratch3.sh")
elif [ "$NERSC_HOST" == "cori" ]; then
    scripts=("run-wrapper-cori-knl-bb-shared.sh"
             "run-wrapper-cori-knl-bb-private.sh"
             "run-wrapper-cori-knl-cscratch.sh"
             "run-wrapper-cori-haswell-bb-shared.sh"
             "run-wrapper-cori-haswell-bb-private.sh"
             "run-wrapper-cori-haswell-cscratch.sh")
elif [ "$NERSC_HOST" == "gerty" ]; then
    scripts=("run-wrapper-gerty-knl-bb-shared.sh"
             "run-wrapper-gerty-knl-bb-private.sh"
             "run-wrapper-gerty-knl-gscratch.sh"
             "run-wrapper-gerty-haswell-bb-shared.sh"
             "run-wrapper-gerty-haswell-bb-private.sh"
             "run-wrapper-gerty-haswell-gscratch.sh")
else
    echo "Unknown NERSC_HOST=[$NERSC_HOST]; aborting" >&2
    exit 1
fi

tmpf=""
for i in ${scripts[@]}; do
    ### find the job name
    jobname="$(awk '/^#SBATCH *-J / {print $3}' $i)"

    ### cache the queue status
    if [ -z "$tmpf" -o ! -f "$tmpf" ]; then
        tmpf="$(mktemp)"
        squeue -u $USER -o "%i %P %j %u %t %M %D %R" > "$tmpf"
    fi

    ### try to figure out of a job with the same name is already in queue
    if grep -q "$jobname" "$tmpf"; then
        is_running="$(awk 'BEGIN { running=0 } /'$jobname'/ { if ( $5 == "R" || $5 == "PD" || $5 == "CF" ) { running=1 } } END { print running }' "$tmpf")"
        # PD (pending), R (running), CA (cancelled), CF(configuring)
        if [ "$is_running" -ne 0 ]; then
            echo "$jobname ($i) is already in the queue; skipping"
            continue
        else
            echo "$jobname ($i) is in the queue but isn't running; submit new"
        fi
    fi
    sbatch $i
done
rm $tmpf
tmpf=""
