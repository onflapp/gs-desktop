#!/bin/sh
set -e

for DD in `ls -1 *-build_*.sh`; do
  echo $DD
  ./$DD || exit 1
done
