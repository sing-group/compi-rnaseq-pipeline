#!/bin/bash
set -o nounset
set -o errexit

#
# Initializes the working directory.
#
# INPUTS:
# $1 : path to working dir.
#

if [ $# -ne 1 ]; then
	echo '[ERROR]: This script requires one argument (the path to the working dir)'
	exit 1
fi

sslash () {
  echo ${1} | tr -s '/'
}

wd=$(sslash "$1/")
samples=$(sslash "${wd}/samples")
genes=$(sslash "${wd}/genes")
genome=$(sslash "${wd}/genome")
config=$(sslash "${wd}/config")
contrasts=$(sslash "${config}/contrasts.tsv")
parameters=$(sslash "${wd}/parameters")

if [[ -d "${samples}" ]] && [[ -d "${genes}" ]] && [[ -d "${config}" ]] && [[ -d "${genome}" ]]
then
	echo '[WARNING]: Selected working-dir already exist'
	echo '           Please select another location or remove the existing one'
	exit 1
fi

mkdir -p ${samples} ${genes} ${genome} ${config}
touch "${samples}"/metadata.tsv
cp "/resources/init-working-dir/contrasts.tsv" "${config}"
cp "/resources/init-working-dir/parameters" "${wd}/compi.parameters"
cp "/resources/init-working-dir/run.sh" "${wd}"
cp "/resources/init-working-dir/README.txt" "${wd}"