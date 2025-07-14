#!/bin/bash

dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

for DD in `cat ./fedora.txt` ;do
  echo $DD
  dnf install --skip-broken -y $DD || exit 1
done
