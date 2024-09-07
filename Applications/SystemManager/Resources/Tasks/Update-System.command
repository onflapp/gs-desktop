#!/bin/bash

if type apt 2>/dev/null ;then
  sudo apt update
  sudo apt upgrade
  exit $?
fi

if type dnf 2>/dev/null ;then
  sudo dnf update
  exit $?
fi
