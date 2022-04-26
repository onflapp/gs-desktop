#!/bin/bash
set -e

if [ -z "$CC" ];then
  . ../BUILD_SETTINGS.sh
fi

for DD in `ls -1 *-build_*.sh`; do
  echo $DD
  ./$DD || exit
done
