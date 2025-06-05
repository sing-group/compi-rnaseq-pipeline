#!/bin/bash

FULL_COMPI_PARAMS_FILE=$1
ADDITIONAL_COMPI_PARAMS="${2:--num-tasks 5} --after trimmomatic-fastqc"

grep --quiet '^enable_trimmomatic' ${FULL_COMPI_PARAMS_FILE}
if [[ $? == 1 ]]; then
    echo "Adding enable_trimmomatic into the specified Compi parameters file (${FULL_COMPI_PARAMS_FILE})"
    echo enable_trimmomatic >> ${FULL_COMPI_PARAMS_FILE}
fi

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

cd ${SCRIPT_DIR}

./run.sh ${FULL_COMPI_PARAMS_FILE} "${ADDITIONAL_COMPI_PARAMS}"
