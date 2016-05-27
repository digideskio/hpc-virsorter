#!/bin/bash

set -u

BIN="$( readlink -f -- "$( dirname -- "$0" )" )"
LOG="$$.log"
OUT_DIR=${OUT_DIR:-"virsorter-out"}
IN_DIR=${IN_DIR:-""}
VIRSORTER_DB_DIR=${DB_DIR:-"/rsgrps/bhurwitz/hurwitzlab/data/virsorter"}
DB_CHOICE=${DB_CHOICE:-1}
OPT_SEQ=${OPT_SEQ:-""}
STEP_SIZE=1
QUEUE="standard"
JOB_NAME="virsorter"
GROUP_NAME="bhurwitz"
JOB_TYPE="htc_only"

function HELP() {
  printf "Usage:\n  %s -i IN_DIR -o OUT_DIR\n\n" \ $(basename $0)

  echo "Required arguments:"
  echo " -i INPUT_DIR"
  echo ""
  echo "Options (default in parentheses):"
  echo " -g GROUP_NAME ($GROUP_NAME)"
  echo " -o OUT_DIR ($OUT_DIR)"
  echo " -d DB_DIR ($VIRSORTER_DB_DIR)"
  echo " -n JOB_NAME ($JOB_NAME)"
  echo " -q QUEUE ($QUEUE)"
  echo " -c DB_CHOICE ($DB_CHOICE)"
  echo " -s STEP_SIZE ($STEP_SIZE)"
  echo " -j JOB_TYPE ($JOB_TYPE)"
  echo " -a CUSTOM_PHAGE_SEQUENCE"
  echo ""
  exit 0
}

if [[ $# -lt 1 ]]; then
  HELP
fi

while getopts :a:c:d:g:j:i:n:o:q:s:h OPT; do
  case $OPT in
    a)
      OPT_SEQ="$OPTARG"
      ;;
    c)
      DB_CHOICE="$OPTARG"
      ;;
    d)
      VIRSORTER_DB_DIR="$OPTARG"
      ;;
    g)
      GROUP_NAME="$OPTARG"
      ;;
    j)
      JOB_TYPE="$OPTARG"
      ;;
    i)
      IN_DIR="$OPTARG"
      ;;
    h)
      HELP
      ;;
    n)
      JOB_NAME="$OPTARG"
      ;;
    o)
      OUT_DIR="$OPTARG"
      ;;
    q)
      QUEUE="$OPTARG"
      ;;
    s)
      STEP_SIZE="$OPTARG"
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument."
      exit 1
      ;;
    \?)
      echo "Error: Invalid option: -${OPTARG:-""}"
      exit 1
  esac
done

echo "Invocation: $0 $@" 

if [[ ${#IN_DIR} -lt 1 ]]; then
  echo "IN_DIR not defined." 
  exit 1
fi

if [[ ! -d $IN_DIR ]]; then
  echo "IN_DIR \"$IN_DIR\" does not exist." 
  exit 1
fi

if [[ ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

if [[ $DB_CHOICE -lt 1 ]] || [[ $DB_CHOICE -gt 2 ]]; then
  echo "DB_CHOICE \"$DB_CHOICE\" must be 1 or 2." 
  exit 1
fi

function lc() {
  wc -l $1 | cut -d ' ' -f 1
}

export PARAMS="$$.params"

if [[ -e $PARAMS ]]; then
  echo "Removing old param file \"$PARAMS\"" 
  rm -f $PARAMS
fi

find $IN_DIR -type f > $PARAMS
NUM_FILES=$(lc $PARAMS)

echo "Found \"$NUM_FILES\" files in \"$IN_DIR\""

ARGS="-W group_list=$GROUP_NAME"

if [[ $NUM_FILES -gt 1 ]]; then
  JOB_ARG="$ARGS -J 1-$NUM_FILES"

  if [[ $STEP_SIZE -gt 1 ]]; then
    JOB_ARG="$JOB_ARGS:$STEP_SIZE"
  fi

  ARGS="$ARGS $JOB_ARG"
fi

CWD=$(pwd)
PBS_DIR=$CWD/pbs

if [[ ! -d $PBS_DIR ]]; then
  mkdir -p $PBS_DIR
fi

CUSTOM_PHAGE_ARG=""
if [[ -n $OPT_SEQ ]]; then
  CUSTOM_PHAGE_ARG="--cp $OPT_SEQ"
fi

echo "IN_DIR            \"$IN_DIR\""      
echo "OUT_DIR           \"$OUT_DIR\""      
echo "CUSTOM_PHAGE_ARG  \"$CUSTOM_PHAGE_ARG\""
echo "VIRSORTER_DB_DIR  \"$VIRSORTER_DB_DIR\""
echo "DB_CHOICE         \"$DB_CHOICE\""
echo "STEP_SIZE         \"$STEP_SIZE\""
echo "JOB_TYPE          \"$JOB_TYPE\""
echo "QUEUE             \"$QUEUE\""
echo "JOB_NAME          \"$JOB_NAME\""
echo "NUM_FILES         \"$NUM_FILES\""
echo "GROUP_NAME        \"$GROUP_NAME\""

export CUSTOM_PHAGE_ARG
export IN_DIR
export OUT_DIR
export VIRSORTER_DB_DIR
export DB_CHOICE
export STEP_SIZE

JOB=$(qsub -l jobtype=$JOB_TYPE -q $QUEUE -N $JOB_NAME $ARGS -j oe -o $PBS_DIR -v PARAMS,STEP_SIZE,CUSTOM_PHAGE_ARG,IN_DIR,OUT_DIR,VIRSORTER_DB_DIR,DB_CHOICE run-virsorter.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB.\"
else
  echo -e "\nError submitting job\n$JOB\n"
fi
