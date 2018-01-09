#!/bin/bash

function running() {
    COMMAND_NAME=$(basename ${0})
    COMMAND_OUTPUT=$(ps ax | grep ${COMMAND_NAME} | grep -v grep | wc --lines)
    RETURN_CODE=${?}
    if [[ ${RETURN_CODE} -eq 0 && ${COMMAND_OUTPUT} -lt 1 ]]; then
        echo "The script is still running."
        exit 1
    fi
}

running

WAIT_TIME="1"
source $(dirname ${0})/*.conf

while [[ ${WAIT_TIME} != 0 ]]; do
    if [[ ${WAIT_TIME} -gt 120 ]]; then
        WAIT_TIME=1
    fi
    sleep ${WAIT_TIME}
    COMMAND_OUTPUT1=$(kubectl --all-namespaces --output wide get pods | grep -vi "running")
    RETURN_CODE=${?}
    if [[ ${RETURN_CODE} != 0 ]]; then
        WAIT_TIME=$(( WAIT_TIME + 30 ))
        SUBJECT="Monitoring FAILED!!"
        echo -e "Kubectl command could not be run completely.\n ${COMMAND_OUTPUT}" > ${LOG_FILE}
        COMMAND_OUTPUT2=$(EMAIL="${SENDER_NAME} <${SENDER}>" mutt -s "${SUBJECT}" -- ${RECIPIENT} < ${LOG_FILE})
        RETURN_CODE=${?}
        if [[ ${RETURN_CODE} -eq 0 ]]; then
            rm ${LOG_FILE}
            WAIT_TIME=0
        else
            echo "${COMMAND_OUTPUT}" >> ${LOG_FILE}
        fi
    fi
    if [[ $(echo ${COMMAND_OUTPUT1} | grep -vi namespace) != "" ]]; then
        SUBJECT="[WARRNING] POD FAILER."
        echo -e "One or more of our pods has a problem:\n${COMMAND_OUTPUT1}" >> ${LOG_FILE}
        COMMAND_OUTPUT2=$(EMAIL="${SENDER_NAME} <${SENDER}>" mutt -s "${SUBJECT}" -- ${RECIPIENT} < ${LOG_FILE})
        RETURN_CONE=${?}
        if [[ ${RETURN_CODE} -eq 0 ]]; then
            rm ${LOG_FILE}
            WAIT_TIME=0
        else
            echo "${COMMAND_OUTPUT}" >> ${LOG_FILE}
        fi
    else
        WAIT_TIME=0
    fi
done

