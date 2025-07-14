#!/bin/sh

if type aptitude 2>/dev/null ;then
  aptitude
  exit
else
  echo "no package manager found"
  exit
fi
