#!/bin/bash

#PBS -l jobtype=cluster_only
#PBS -l select=1:ncpus=16:mem=10gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00

set -u

# --------------------------------------------------
function get_lines() {
 FILE=$1
 OUT_FILE=$2
 START=${3:-1}
 STEP=${4:-1}

 if [ -z $FILE ]; then
   echo No input file
   exit 1
 fi

 if [ -z $OUT_FILE ]; then
   echo No output file
   exit 1
 fi

 if [[ ! -e $FILE ]]; then
   echo Bad file \"$FILE\"
   exit 1
 fi

 awk "NR==$START,NR==$(($START + $STEP - 1))" $FILE > $OUT_FILE
}

module load blast 
module load hmmer
module load muscle

TMP_FILES=$(mktemp)
get_lines $PARAMS $TMP_FILES ${PBS_ARRAY_INDEX:=1} $STEP_SIZE

NUM_FILES=$(lc $TMP_FILES)

echo $(date)
echo Processing \"$NUM_FILES\" input files

VIRSORTER="VirSorter/wrapper_phage_contigs_sorter_iPlant.pl"

i=0
while read FILE; do
  let i++
  printf "%3d: %s\n" $i $(basename $FILE)
  echo "$VIRSORTER -f $FILE --db $DB_CHOICE --wdir $OUT_DIR --data-dir $VIRSORTER_DB_DIR $CUSTOM_PHAGE_ARG"
done < $TMP_FILES

echo $(date)
echo Done.
