#!/bin/bash

trap "exit 1" 10
PROC="$$"
kaput() {
    echo "$@" >&2
    kill -10 $PROC
}

# Read either from file or stdin
[ "$#" -eq 1 ] && TEXT=$(cat $1) || TEXT=$(cat)

# Generate LINEens
LINES=$(echo "$TEXT" |
    # Remove comments, starting and trailing spaces, empty lines, merge multiple spaces into one
    sed 's/\s*#.*//; s/^\s*//; s/\s*$//; /^$/d; s/ \+/ /g' |
    # Make separators uniform
    awk -F " |,|\\\(|\\\)" 'BEGIN {OFS = " "} { $1 = $1; print }' |
    # Eliminate trailng and duplicated separators
    sed 's/ \+/ /g; s/ *$//' |
    # Detect labels
    sed -E 's/(.+):$/LABEL \1/' |
    tr '[:upper:]' '[:lower:]') 

# Predicates
isreg() {
    [[ "$1" =~ ^x[0-9]+$ ]]
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
islabel() {
    [[ "$1" =~ ^[a-z]([a-z]|[0-9]|_)*$ ]]
}

# Conversions
asnum() {
    ishex "$1" && printf "%d" "$1" || "$1"    
}

# Checks if current instruction has expected number of elements.
assert_len() {
    LEN="${#INST[@]}"
    [ "$LEN" -eq "$1" ] || kaput "'${INST[@]}': expected to have $1 elements, but it has $LEN"
}

assert_valid_label() {
    [ -z "${LABELS[$1]}" ] && kaput "${INST[@]}: unknown label '$1'"
}

# Checks if arg fufills the predicate
# $1 - predicate, $2 - text
assert() {
    $($1 "$2") || kaput "'${INST[@]}': expected '$2' to match '$1'"
}

a0() {
    echo ${INST[0]}
}
a1() {
    echo ${INST[1]}
}
a2() {
    echo ${INST[2]}
}
a3() {
    echo ${INST[3]}
}
a4() {
    echo ${INST[4]}
}

# PHASE 1 ============= Macroinstructions that expand into multiple basic instructions.
LINES=$(echo "$LINES" | while read -r LINE; do
    INST=($LINE)
    case "$(a0)" in
        set) 
            assert_len 3 ; assert isreg $(a1) ; assert isnum $(a2)
            echo -e "lui $(a1) 12345\naddi $(a1) $(a1) 678"
            ;;
        *) echo "$LINE" ;;
    esac
done)


# PHASE 2 ============= Calculating labels positions
ORG=0 ; NEXT="" ; declare -A LABELS
while read -r LINE; do
    INST=($LINE)

    EMIT=$LINE
    NEXT_ORG=$(( $ORG+4 ))

    case "$(a0)" in
        label) 
            assert_len 2 ; assert islabel $(a1)
            # Save label address
            LABELS[$(a1)]=$ORG ; EMIT="" ; NEXT_ORG=$ORG
            ;;
        org)
            assert_len 2 ; assert isnum $(a1)
            NEXT_ORG=$(asnum $(a1))
            ;;
    esac

    [ -z "$EMIT" ] || NEXT+="${EMIT}\n"
    ORG=$NEXT_ORG
done <<< "$LINES"
LINES=$(echo -e "$NEXT")

# PHASE 3 ============= Code emitting
ORG=0
while read -r LINE; do
    INST=($LINE)
    NEXT_ORG=$(( $ORG+4 ))
    
    echo "$ORG, $LINE"
    case "$(a0)" in
        addi) 
            # ADDI xA, xB, imm12
            assert_len 4 ; assert isreg $(a1) ; assert isreg $(a2) ; assert isnum $(a3)
            echo "JES ADDI" ;;
        lui) 
            # LUI xA, imm20
            assert_len 3 ; assert isreg $(a1) ; assert isnum $(a2)
            echo "JES LUI" ;;
        lb)
            # LB xA, OFF(xB)
            assert_len 4 ; assert isreg $(a1) ; assert isnum $(a2) ; assert isreg $(a3)
            echo "JES LB" ;;
        jal)
            # JAL xA, label
            assert_len 3 ; assert isreg $(a1) ; assert islabel $(a2) ; assert_valid_label $(a2)
            ADDR=${LABELS[$(a2)]}
            echo "JAL $(a2) --> $ADDR"
            ;;
        org) 
            NEXT_ORG=$(asnum $(a1)) ;;
    esac

    ORG=$NEXT_ORG
done <<< "$LINES"