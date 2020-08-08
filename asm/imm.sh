#!/bin/bash
trap "exit 1" 10
PROC="$$"
kaput() {
    echo "$@" >&2
    kill -10 $PROC
}

declare -A LABELS
EXPR=()

islabel() {
    [[ "$1" =~ ^[a-z]([a-z]|[0-9]|_)*$ ]]
}
isdec() { 
    [[ "$1" =~ ^-?[0-9]+$ ]]  
}
ishex() { 
    [[ "$1" =~ ^0x([0-9]|[a-f])+$ ]] 
}
isnum() { 
    isdec "$1" || ishex "$1"
}

while [ $# -gt 0 ]
do
    if [[ "$1" =~ ^--.*$ ]]
    then
        label="$(echo $1 | cut -c 3-)" ; shift ; addr="$1"
        LABELS["$label"]="$addr"
    elif $(islabel "$1") 
    then
        value="${LABELS["$1"]}"
        [ -z "$value" ] && echo "Undefined label '$1'" && exit 1
        EXPR+=("$value")
    elif $(isnum "$1")
    then
        value=$(( "$1" ))
        EXPR+=( "$value" )  
    else
        [[ "$1" =~ ^\+|\-|\(|\)$ ]] || (echo "Unexpected symbol '$1'" && exit 1)
        EXPR+=( "$1" )
    fi
    shift
done

EXPR=${EXPR[@]}
bash -c "tmp=$(( $EXPR ))" > /dev/null 2>&1
[[ "$?" -ne 0 ]] && echo "'$EXPR' is not a valid expression" && exit 1
echo "$(( $EXPR ))"