#!/bin/bash

# Script to block IP addresses that are trying to determine the
# SASL password for Postfix in order to use our mail system
# for spamming.
#
# Database resets once per day as a result of log rotation.

accessfile=/etc/postfix/access_dynamic
tmpfile=$(mktemp)
difffile=$(mktemp)

# Fail if $accessfile does not exist for some weird reason
if [ ! -f $accessfile ] ; then
  echo "Error: $accessfile does not exist - exiting"
  rm -f $tmpfile $difffile
  exit 1
fi

# Find offending IP addresses
for ip in $(egrep "SASL.*authentication failed" /var/log/maillog | awk -F '[][]' '{print $4}' | sort | uniq | sort -n) ; do
  echo "$ip REJECT authentication abuse" >> $tmpfile
done

# If new IPs are found, update the Postfix access file
if ! diff $tmpfile $accessfile > $difffile ; then
  # Uncomment for debugging - cat $difffile
  cp -f $tmpfile $accessfile
  /sbin/postmap $accessfile
fi

# Remove temp files
rm -f $tmpfile $difffile
