#/bin/bash

if [ -f ${2} ] && [ -s ${2} ]; then
    cat ${2}
else
    cat ${1} | cut -f1 | awk 'NR>1{print $0}'
fi
