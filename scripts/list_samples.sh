#/bin/bash

cat ${1} | cut -f1 | awk 'NR>1{print $0}'
