#!/bin/bash
trap "exit 1" 10
PROC="$$"
kaput() {
    echo "$@" >&2
    kill -10 $PROC
}

# Read either from file or stdin
[ "$#" -eq 1 ] && TEXT=$(cat $1) || TEXT=$(cat)

# Generate LINEes
LINES=$(echo "$TEXT" |
    # Remove comments, starting and trailing spaces, empty lines, merge multiple spaces into one
    sed 's/\s*#.*//; s/^\s*//; s/\s*$//; /^$/d; s/ \+/ /g' |
    # Replace '+' with ' + ', etc.
    sed 's/+/ + /; s/-/ - /' | 
    # Make separators uniform
    awk -F " |," 'BEGIN {OFS = " "} { $1 = $1; print }' |
    # Eliminate trailng and duplicated separators
    sed 's/ \+/ /g; s/ *$//' |
    # Detect labels
    sed -E 's/(.+):$/LABEL \1/' |
    tr '[:upper:]' '[:lower:]') 

# Predicates
isxreg() {
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

assert_gte() {
    LEN="${#INST[@]}"
    [ "$LEN" -ge "$1" ] || kaput "'${INST[@]}': expected to at least $1 elements, but it has $LEN"
}

assert_valid_label() {
    [ -z "${LABELS[$1]}" ] && kaput "${INST[@]}: unknown label '$1'"
}

assert_range() {
    # $1 - min, $2 - max, $3 - test value
    l=$(( "$1" )) ; r=$(( "$2" )) val=$(( "$3" ))
    [ "$val" -ge "$l" -a "$val" -le "$r" ] || kaput "${INST[@]}: '$val' not in valid range of [$l; $r]"
}

# Checks if arg fufills the predicate
# $1 - predicate, $2 - text
assert() {
    $($1 "$2") || kaput "'${INST[@]}': expected '$2' to match '$1'"
}

# Instruction element accessor
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
a_rest() {
    echo "${INST[@]:$1}"
}

# PHASE 1 ============= Macroinstructions that expand into multiple basic instructions.
LINES=$(echo "$LINES" | while read -r LINE; do
    INST=($LINE)
    case "$(a0)" in
        set) 
            assert_len 3 ; assert isxreg $(a1) ; assert isnum $(a2)
            echo -e "lui $(a1) 12345\naddi $(a1) $(a1) 678"
            ;;
        *) echo "$LINE" ;;
    esac
done)

# PHASE 2 ============= Calculating labels positions
ORG=0 ; NEXT="" ; declare -A LABELS
while read -r LINE; do
    INST=($LINE)

    EMIT="$LINE\n"
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
        dat)
            # Emit multiple dw instructions
            words=("${INST[@]:1}") ; count="${#INST[@]}" ; EMIT=""
            for word in "${words[@]}"
            do
                assert isnum "$word" ; assert_range 0 0xFFFFFFFF "$word"
                EMIT+="dw $word\n"
            done
            NEXT_ORG="$(( $ORG + $count ))"
            ;;
    esac

    [ -z "$EMIT" ] || NEXT+="${EMIT}"
    ORG=$NEXT_ORG
done <<< "$LINES"
LINES=$(echo -e "$NEXT")

# PHASE 3 ============= Code emitting
r_inst() {
   # $1 - funct7, $2 - rs2, $3 - rs1, $4 - funct3, $5 - rd, $6 - opcode
   echo "$(( ($1<<25) + ($2<<20) + ($3<<15) + ($4<<12) + ($5<<7) + $6 ))"
}
i_inst() {
    # $1 - imm12, $2  - rs1, $3 - funct3, $4 - rd, $5 - opcode
    echo "$(( (($1&0xFFF)<<20) + ($2<<15) + ($3<<12) + ($4<<7) + $5 ))"
}
s_inst() {
    # $1 - imm12, $2 - rs2, $3 - rs1, $4 - funct3, $5 - opcode
    imm="$(( $1 & 0xFFF ))"
    imm_1="$(( ($imm>>5) &  0x3F ))" # [11:5]
    imm_2="$(( $imm & 0x1F ))" # [4:0]
    echo "$(( ($imm_1<<25) + ($2<<20) + ($3<<15) + ($4<<12) + ($imm_2<<7) + $5 ))"
}
b_inst() {
    # $1 - imm12, $2 - rs2, $3 - rs1, $4 - funct3, $5 - opcode
    imm="$(( $1 & 0x1FFF ))"
    imm_1="$(( ($imm>>12) & 1 ))" # [12]
    imm_2="$(( ($imm>>5) & 0x3F ))" # [10:5]
    imm_3="$(( ($imm>>1) & 0xF ))" # [4:1]
    imm_4="$(( ($imm>>11) & 1 ))" # [11]
    echo "$(( ($imm_1<<31) + ($imm_2<<25) + ($2<<20) + ($3<<15) + ($4<<12) + ($imm_3<<8) + ($imm_4<<7) + $5 ))"
}
u_inst() {
    # $1 - imm20, $2 - rd, $3 - opcode
    imm="$(( $1 & 0xFFFFF ))"
    echo "$(( ($imm<<12) + ($2<<7) + $3 ))"
}
j_inst() {
    # $1 - imm20, $2 - rd, $3 - opcode
    imm="$(( $1 & 0x1FFFFF ))"
    imm_1="$(( ($imm>>20) & 1 ))" # [20]
    imm_2="$(( ($imm>>1) & 0x3FF ))"   # [10:1]
    imm_3="$(( ($imm>>11) & 1))"  # [11]
    imm_4="$(( ($imm>>12) & 0xFF ))" # [19:12]
    echo "$(( ($imm_1<<31) + ($imm_2<<21) + ($imm_3<<20) + ($imm_4<<12) + ($2<<7) + $3 ))"
}

# Helper functions
hexinst() {
    printf "%08x" "$1"
}
xreg_to_num() {
    echo "$(echo $1 | cut -c 2-)"
}
to_param_list () {
    declare -n outlist=$1
    declare -n inhash=$2
    for param in "${!inhash[@]}"; do
        outlist+=( "--$param ${inhash[$param]}" )
    done
}
imm_rest() {
    imm=$(a_rest $1)
    to_param_list list LABELS
    out=$(./imm.sh ${list[@]} ${imm[@]})
    [ $? -ne 0 ] && kaput "${INST[@]}: Unable to parse immediate '$imm'. Error: $out."
    echo "$out"
}

# Opcode lookup
declare -A OPS=( \
    ["OPIMM"]=19 ["LUI"]=55 ["AUIPC"]=23 ["OP"]=51 ["JAL"]=111 \
    ["JALR"]=103 ["BRANCH"]=99 ["LOAD"]=3 ["STORE"]=35 \
)
declare -A OPIMM_FUNCT3=( \
    ["addi"]=0 ["slti"]=2 ["sltiu"]=3 ["xori"]=4 ["ori"]=6 \
    ["andi"]=7 ["slli"]=1 ["srli"]=5 ["srai"]=5 \
)
declare -A OP_FUNCT3=( \
    ["add"]=0 ["sub"]=0 ["sll"]=1 ["slt"]=2 ["sltu"]=3 \
    ["xor"]=4 ["srl"]=5 ["sra"]=5 ["or"]=6 ["and"]=7 \
)
declare -A LOAD_FUNCT3=( \
    ["lb"]=0 ["lh"]=1 ["lw"]=2 ["lbu"]=3 ["lhu"]=4 \
)
declare -A STORE_FUNCT3=( \
    ["sb"]=0 ["sh"]=1 ["sw"]=2 \
)
declare -A BRANCH_FUNCT3=( \
    ["beq"]=0 ["bne"]=1 ["blt"]=4 ["bge"]=5 ["bltu"]=6 ["bgeu"]=7 \
)

ORG=0
while read -r LINE; do
    INST=($LINE)
    NEXT_ORG=$(( $ORG+4 ))
    
    #echo "$ORG, $LINE"
    case "$(a0)" in
        addi | slti | sltiu | xori | ori | andi | slli | srli) 
            # _ xA, xB, imm12
            assert_gte 4 ; assert isxreg $(a1) ; assert isxreg $(a2)
            imm=$(imm_rest 3)
            [ "$(a0)" == "slli" -o "$(a0)" == "srli" ] && assert_range 0 31 $imm || assert_range -2048 2047 $imm
            r_dest=$(xreg_to_num $(a1)) ; r_src=$(xreg_to_num $(a2))
            [ "$(a0)" == "slli" -o "$(a0)" == "srli" ] && imm=$(( $imm & 0x1F ))
            code=$(hexinst $(i_inst $imm $r_src ${OPIMM_FUNCT3["$(a0)"]} $r_dest ${OPS["OPIMM"]}))
            ;;
        srai)
            # srai xA, xB, imm12
            assert_gte 4 ; assert isxreg $(a1) ; assert isxreg $(a2) 
            imm=$(imm_rest 3) ; assert_range 0 31 $imm
            r_dest=$(xreg_to_num $(a1)) ; r_src=$(xreg_to_num $(a2))
            imm=$(( ($imm & 0x1F) + (1<<10) ))
            code=$(hexinst $(i_inst $imm $r_src ${OPIMM_FUNCT3["srai"]} $r_dest ${OPS["OPIMM"]}))
            ;;
        lui) 
            # LUI xA, imm20
            assert_gte 3 ; assert isxreg $(a1)
            imm=$(imm_rest 2) ; assert_range 0 0xFFFFF $imm
            r_dest=$(xreg_to_num $(a1))
            code=$(hexinst $(u_inst $imm $r_dest ${OPS["LUI"]}))
            ;;
        auipc)
            # AUIPC xA, imm20
            assert_gte 3 ; assert isxreg $(a1)
            imm=$(imm_rest 2) ; assert_range 0 0xFFFFF $imm
            r_dest="$(xreg_to_num $(a1))"
            code=$(hexinst $(u_inst $imm $r_dest ${OPS["AUIPC"]}))
            ;;
        add | slt | sltu | and | or | xor | sll | srl)
            # _ xDEST, xA, xB 
            assert_len 4 ; assert isxreg $(a1) ; assert isxreg $(a2) ; assert isxreg $(a3)
            r_dest=$(xreg_to_num $(a1)) ; r_a=$(xreg_to_num $(a2)) ; r_b=$(xreg_to_num $(a3))
            code=$(hexinst $(r_inst 0 $r_b $r_a ${OP_FUNCT3["$(a0)"]} $r_dest ${OPS["OP"]}))
            ;;
        sub | sra)
            # _ xDEST, xA, xB 
            assert_len 4 ; assert isxreg $(a1) ; assert isxreg $(a2) ; assert isxreg $(a3)
            r_dest=$(xreg_to_num $(a1)) ; r_a=$(xreg_to_num $(a2)) ; r_b=$(xreg_to_num $(a3))
            code=$(hexinst $(r_inst 0x20 $r_b $r_a ${OP_FUNCT3["$(a0)"]} $r_dest ${OPS["OP"]}))
            ;;
        lb | lh | lw | lbu | lhu)
            # {LB|LH|LW|LBU|LHU} xTARGET, xBASE, OFFSET
            assert_gte 4 ; assert isxreg $(a1) ; assert isxreg $(a2)
            offset=$(imm_rest 3) ; assert_range -2048 2047 $offset
            r_dest=$(xreg_to_num $(a1)) ; r_base=$(xreg_to_num $(a2))
            code=$(hexinst $(i_inst $offset $r_base ${LOAD_FUNCT3["$(a0)"]} $r_dest ${OPS["LOAD"]}))
            ;;
        sb | sh | sw)
            # {SB|SH|SW} xSRC, xBASE, OFFSET
            assert_gte 4 ; assert isxreg $(a1) ; assert isxreg $(a2)
            offset=$(imm_rest 3) ; assert_range -2048 2047 $offset
            r_src=$(xreg_to_num $(a1)) ; r_base=$(xreg_to_num $(a2))
            code=$(hexinst $(s_inst $offset $r_src $r_base ${STORE_FUNCT3["$(a0)"]} ${OPS["STORE"]}))
            ;;
        jal)
            # JAL xA, label
            assert_len 3 ; assert isxreg $(a1) ; assert islabel $(a2) ; assert_valid_label $(a2)
            r_dest=$(xreg_to_num $(a1)) ; addr=${LABELS[$(a2)]}
            # TODO: Might wanna check if offset is multiple of two
            offset=$(( $addr-$ORG )) ; assert_range -1048576 1048575 $offset
            code=$(hexinst $(j_inst $offset $r_dest ${OPS["JAL"]}))
            ;;
        jalr)
            # JALR xA, xB, imm12
            assert_gte 4 ; assert isxreg $(a1) ; assert isxreg $(a2)
            offset=$(imm_rest 3) ; assert_range -2048 2047 $offset
            r_dest=$(xreg_to_num $(a1)) ; r_base=$(xreg_to_num $(a2))
            code=$(hexinst $(i_inst $offset $r_base 0 $r_dest ${OPS["JALR"]}))
            ;;
        beq | bne | blt | bltu | bge | bgeu)
            # BRANCH xA, xB, label
            assert_len 4 ; assert isxreg $(a1) ; assert isxreg $(a2) ; assert islabel $(a3) ; assert_valid_label $(a3)
            r_a=$(xreg_to_num $(a1)) ; r_b=$(xreg_to_num $(a2)) ; addr=${LABELS[$(a3)]}
            offset=$(( $addr-$ORG )) ; assert_range -4096 4095 $offset
            code=$(hexinst $(b_inst $offset $r_b $r_a ${BRANCH_FUNCT3["$(a0)"]} ${OPS["BRANCH"]}))
            ;;
        org) 
            NEXT_ORG=$(asnum $(a1)) 
            ;;
        dw)
            assert_len 2 ; assert isnum $(a1) ; assert_range 0 0xFFFFFFFF $(a1)
            code=$(hexinst $(a1))
            ;;
        *)
            kaput "Invalid instruction '${INST[@]}'"
            ;;
    esac
    echo "mem[$(($ORG / 4))] = 'h$code;"
    ORG=$NEXT_ORG
done <<< "$LINES"
