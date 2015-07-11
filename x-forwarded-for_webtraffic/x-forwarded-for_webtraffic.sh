#!/bin/bash

ngrep -il -d eth0 -W byline "x-forwarded-for" "port 80" | grep -i x-forwarded-for | awk -F '[., ]' '{printf( "%s.%s.%s.%s\n", $2,$3,$4,$5 );}' > /tmp/ngrep.tmp &

watch -tn 10 'cat /tmp/ngrep.tmp | sort -n | uniq -c | sort -nr | head -30'
