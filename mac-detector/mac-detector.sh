#!/bin/bash

# Set data file and plenty of temp files
prog=$(basename $0 | awk -F '[.]' '{print $1}')
datfile=/tmp/${prog}.dat
tmpfile1=/tmp/${prog}.tmp1
tmpfile2=/tmp/${prog}.tmp2
tmpfile3=/tmp/${prog}.tmp3

# Scan for definitive list of MAC addresses on network
nmap -sn 192.168.1.* | grep "MAC Address:" | awk '{print $3}' | tr '[:upper:]' '[:lower:]' | sort > $tmpfile1

# Just create the data file if this is the first run
if [ ! -f $datfile ] ; then mv $tmpfile1 $datfile ; rm -f $tmpfile1 ; exit ; fi

# Determine if any new MAC addresses have appeared
diff $datfile $tmpfile1 | egrep "^> " | awk '{print $2}' > $tmpfile2

# Report if new MAC addresses have appeared
if [ -s $tmpfile2 ] ; then
  echo "New MAC address(es) on network:"
  echo ""

  # Resolve MAC addresses to IP addresses for easier investigation
  for mac in $(cat $tmpfile2) ; do
    ip=$(arp -n | grep $mac | awk '{print $1}')
    echo $mac $ip
  done

  # Add new MAC addresses to data file
  cat $datfile > $tmpfile3
  cat $tmpfile2 >> $tmpfile3
  cat $tmpfile3 | sort > $datfile
fi

#Remove temp files
rm -f $tmpfile1 $tmpfile2 $tmpfile3
