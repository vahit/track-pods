#!/bin/bash

function running() {
    COMMAND_NAME=$(basename ${0})
    COMMAND_OUTPUT=$(ps ax | pgrep ${COMMAND_NAME} | wc --lines)
    RETURN_CODE=${?}
    if [[ ${RETURN_CODE} -eq 0 && ${COMMAND_OUTPUT} -gt 1 ]]; then
        echo "The script is still running."
        exit 1
    fi
}

running

WAIT_TIME="1"
source ${HOME}/.config/track-pods.conf

if [[ ! -z $EXCEPT ]]; then
    TMP_EXCEPT=$EXCEPT
    EXCEPT=$(echo $TMP_EXCEPT | sed 's/,/\\|/g')
fi

while [[ ${WAIT_TIME} != 0 ]]; do
    if [[ ${WAIT_TIME} -gt 120 ]]; then
        WAIT_TIME=1
    fi
    sleep ${WAIT_TIME}
    COMMAND_OUTPUT1=$(kubectl --all-namespaces --output wide get pods | grep -vi $EXCEPT 2>&1)
    RETURN_CODE=${?}
    if [[ ${RETURN_CODE} != 0 && ${COMMAND_OUTPUT1} != "" ]]; then
        WAIT_TIME=$(( WAIT_TIME + 30 ))
        SUBJECT="Monitoring FAILED!!"
        echo -e "Kubectl command could not be run completely.\n ${COMMAND_OUTPUT1}" >> "${LOG_FILE}"
        COMMAND_OUTPUT2=$(EMAIL="${SENDER_NAME} <${SENDER}>" mutt -s "${SUBJECT}" -- ${RECIPIENT} < "${LOG_FILE}")
        RETURN_CODE=${?}
        if [[ ${RETURN_CODE} -eq 0 ]]; then
            rm "${LOG_FILE}"
        else
            echo "${COMMAND_OUTPUT2}" >> "${LOG_FILE}"
        fi
    fi
    if [[ $(echo ${COMMAND_OUTPUT1}) != "" && ${RETURN_CODE} == 0 ]]; then
        COUNT=$(echo ${COMMAND_OUTPUT1} | wc --lines)
        SUBJECT="[WARRNING] POD FAILER.[${COUNT}]"
        echo -e "One or more of our pods has a problem:\n${COMMAND_OUTPUT1}" >> "${LOG_FILE}"
        COMMAND_OUTPUT2=$(EMAIL="${SENDER_NAME} <${SENDER}>" mutt -s "${SUBJECT}" -- ${RECIPIENT} < "${LOG_FILE}")
        RETURN_CODE=${?}
        if [[ ${RETURN_CODE} -eq 0 ]]; then
            rm "${LOG_FILE}"
            WAIT_TIME=0
        else
            echo "${COMMAND_OUTPUT2}" >> "${LOG_FILE}"
        fi
    else
        WAIT_TIME=0
    fi
done

exit 0
