#!/bin/bash

if ! cd ~/Pictures/Flickr_faves ; then
  logger "get_Flickr_faves: failed to cd to ~/Pictures/Flickr_faves; exiting"
  exit 1
fi

if ! curl -s "http://api.flickr.com/" > /dev/null 2>&1 ; then
  logger "get_Flickr_faves: couldn't connect to Yahoo API; exiting"
  exit 1
fi

curl -s "URL" | grep 'rel="enclosure"' | awk -F '"' '{print $6}' | xargs -L1 curl -s -O

find . -mtime +1 -exec rm -f {} +

NO_IMAGES=$(ls | wc -l | sed "s/ //g")

logger "get_Flickr_faves: completed; $NO_IMAGES images"
