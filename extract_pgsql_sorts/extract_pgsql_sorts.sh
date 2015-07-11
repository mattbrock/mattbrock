#!/bin/bash

PROG=$(basename $0)
PPROG=$(echo $PROG | awk -F '.' '{print $1}')
TMPFILE1=/tmp/$PPROG.tmp1
TMPFILE2=/tmp/$PPROG.tmp2
LOGFILE=$1

if [ -z "$1" ] ; then
  echo "Usage: $PROG LOGFILE"
  exit 
fi

cat /dev/null > $TMPFILE2

grep "temporary file" $LOGFILE > $TMPFILE1

cat $TMPFILE1 | while read LINE ; do
  NO1=$(echo $LINE | awk -F '[][-]' '{print $2}' )
  NO2=$(echo $LINE | awk -F '[][-]' '{print $4}' )
  cat $LOGFILE | awk -F '[][-]' "($2 ~ /$NO1/) && ($4 ~ /$NO2/) {print $0}" >> $TMPFILE2
  echo "" >> $TMPFILE2
done

cat $TMPFILE2

rm -f $TMPFILE1 $TMPFILE2
