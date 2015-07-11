#!/bin/bash

progname=$(basename $0)
usage="Usage:\t$progname -f vCard_file \n\t$progname -h"

while getopts "f:h" options ; do
  case $options in
    f) vcard_file=$OPTARG ;;
    h) echo -e $usage ; exit ;;
  esac
done

if [ ! "$vcard_file" ] ; then
  echo -e $usage
  exit 1
fi

if [[ ! $(head -1 $vcard_file) =~ "BEGIN:VCARD" ]] ; then
  echo "$vcard_file does not appear to be a vCard file"
  exit 1
fi

if ! which base64 > /dev/null ; then
  echo "base64 is not installed"
  exit 1
fi

if ! which convert > /dev/null ; then
  echo "ImageMagick is not installed"
  echo "Either install it or comment out the ImageMagick stuff"
  exit 1
fi

if [ -d photos ] ; then
  echo "photos directory already exists"
  exit 1
fi

if ! mkdir photos ; then
  echo "Failed to create photos directory"
  exit 1
fi

regex1="^N:"
regex2="^PHOTO;"
regex3=":|;"

echo -ne "Extracting photos"
cat $vcard_file | while read line ; do
  if [[ $line =~ $regex1 ]] ; then
    filename=$(echo $line | awk -F '[:;]' '{printf("%s%s",$3,$2)}' | sed 's/[^a-zA-Z]//g')
    echo -ne "."
    cat /dev/null > photos/$filename.tmp
  elif [[ $line =~ $regex2 ]] ; then
    echo $line | sed 's/PHOTO;ENCODING=b;TYPE=JPEG://' >> photos/$filename.tmp
  elif [[ ! $line =~ $regex3 ]] ; then
    echo $line >> photos/$filename.tmp
  fi
done
echo -ne " done\n"

echo -ne "Removing empty photos..."
find photos -empty -exec rm -f {} +
echo -ne " done\n"

echo -ne "Converting photos"
cd photos
for file in *.tmp ; do
  filename=$(echo $file | awk -F '.' '{print $1}')
  echo -ne "."
  cat $file | tr -d '\n' | tr -d '' | base64 -d > $filename.jpg
  convert $filename.jpg -resize 201x201 $filename.jpg
  rm -f $file
done
echo -ne " done\n"
