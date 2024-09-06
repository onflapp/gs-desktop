#!/bin/bash

if type apt 2>/dev/null ;then
  sudo apt update
  exit $?
fi

if type dnf 2>/dev/null ;then
  sudo dnf update
  exit $?
fi
