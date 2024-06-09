#!/bin/sh
set -e

for DD in `ls -1 *-fetch_*.sh`; do
  echo $DD
  ./$DD || exit
done
