#!/bin/bash

for DD in `cat ./debian.txt` ;do
  echo $DD
  apt-get install -y $DD || exit 1
done
