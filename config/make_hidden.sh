#!/bin/sh

SHOW="Applications Developer System Library home media"

cd /
echo "" > .hidden || exit 1

for DD in * ;do
  found=""
  for XX in $SHOW ;do
    if [ "$XX" = "$DD" ];then
      found="Y"
    fi
  done
  if [ -z "$found" ];then
    echo $DD >> .hidden
  fi
done
