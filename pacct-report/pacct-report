#!/bin/bash

users=$(cat /etc/passwd | awk -F ':' '{print $1}' | sort)

echo "USERS' CONNECT TIMES"

for user in $users ; do
  ac=$(ac -d $user)
  [ -n "$ac" ] && echo -e "\n${user}:\n\n${ac}"
done

echo ""
echo "COMMANDS BY USER"
echo ""

for user in $users ; do
  comm=$(lastcomm --user $user | awk '{print $1}' | sort | uniq -c | sort -nr)
  if [ "$comm" ] ; then
    echo "$user:"
    echo "$comm"
  fi
done

echo ""
echo "COMMANDS BY FREQUENCY OF EXECUTION"
echo ""

sa | awk '{print $1, $6}' | sort -n | head -n -1 | sort -nr
