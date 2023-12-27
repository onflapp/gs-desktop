#!/bin/bash

if type "aptitude" 2>/dev/null ;then
  aptitude
  exit
fi

echo "no package manager found"
exit
