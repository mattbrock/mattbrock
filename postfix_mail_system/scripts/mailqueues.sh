#!/bin/bash

ssh="ssh -o CheckHostIP=no -o StrictHostKeyChecking=no -q -tt"
domain="internal.company.com"
echo="echo -en"

$echo "{ \"mailqueues\": {\n"

i=1
for mailserver in mail1 mail2 mail3 mail4 mx1 ; do

  active=$($ssh ${mailserver}.${domain} "sudo find /var/spool/postfix/active -ignore_readdir_race -type f" | wc -l 2>/dev/null)
  deferred=$($ssh ${mailserver}.${domain} "sudo find /var/spool/postfix/deferred -ignore_readdir_race -type f" | wc -l 2>/dev/null)

  $echo "    \"$mailserver\": {\n"
  $echo "      \"activemailqueue\": \"${active}\",\n"
  $echo "      \"deferredmailqueue\": \"${deferred}\"\n    }"
  [ $i -lt 5 ] && $echo ","
  $echo "\n"

  i=$(($i+1))

done

$echo "} }\n"
