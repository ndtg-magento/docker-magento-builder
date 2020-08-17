#!/bin/sh
set -e

run_thread() {
    # Random number between 3 and 6
    PROCESS=${1}

    WAITING_TIME=${2}

    if [ -z "${WAITING_TIME}" ]; then
        WAITING_TIME=3
    fi

    SLEEP_TIME=$(( ($RANDOM % 3) + $WAITING_TIME ))

    echo "${PROCESS} will sleep for ${SLEEP_TIME} seconds."

    sleep ${SLEEP_TIME}

    echo "${PROCESS} sleep done! Running Process."

    "${PROCESS}"
}
