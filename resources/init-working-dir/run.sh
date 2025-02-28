#!/bin/bash

function show_error() {
	tput setaf 1
	echo -e "${1}"
	tput sgr0
}

function get_compi_parameter {
    cat "${1}" | grep "${2}=" | cut -d'=' -f2
}

COMPI_RNA_SEQ_VERSION=${COMPI_RNA_SEQ_VERSION-2.0.0-SNAPSHOT}

FULL_COMPI_PARAMS_FILE=$1
ADDITIONAL_COMPI_PARAMS="${2:--num-tasks 5}"

if [ $# -ne 1 ] && [ $# -ne 2 ]; then
	show_error "[ERROR]: This script requires one argument (the path to the Compi parameters file)"
	exit 1
fi

if [[ ! -f "${FULL_COMPI_PARAMS_FILE}" ]]; then
	show_error "[ERROR]: The parameters file (${FULL_COMPI_PARAMS_FILE}) does not exist."
	exit 1
fi

# get the paths from the compi.parameters file
workingDir="$(get_compi_parameter ${FULL_COMPI_PARAMS_FILE} "working_dir")"

timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
mkdir -p ${workingDir}/compi/logs/${timestamp}

docker run -it --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v ~/.compi:/root/.compi \
		-v ${workingDir}:${workingDir} \
		-v ${FULL_COMPI_PARAMS_FILE}:${FULL_COMPI_PARAMS_FILE} \
		singgroup/compi-rnaseq:${COMPI_RNA_SEQ_VERSION} \
			--logs ${workingDir}/compi/logs/${timestamp}/tasks \
			-pa ${FULL_COMPI_PARAMS_FILE} \
			-r runner.xml \
			-o \
			${ADDITIONAL_COMPI_PARAMS} \
		2>&1 | tee ${workingDir}/compi/logs/${timestamp}/compi.log
