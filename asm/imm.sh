#!/bin/bash
trap "exit 1" 10
PROC="$$"
kaput() {
    echo "$@" >&2
    kill -10 $PROC
}

declare -A LABELS

while [ $# -gt 0 ]
do
    if [[ "$1" =~ ^--.*$ ]]
    then
        # Label load
        label="$(echo $1 | cut -c 3-)" ; shift ; addr="$1"
        LABELS["$label"]="$addr" ; shift
    else
        # Calculations
        shift
    fi
done

echo "2137"