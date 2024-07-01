#!/usr/bin/env bash

PID=`cat /tmp/$UID-picom.pid 2>/dev/null`
if [ -n "$PID" ];then
  kill "$PID" 2>/dev/null
  rm /tmp/$UID-picom.pid
  sleep 1
fi

if [ -f "$HOME/Library/etc/picom.conf" ];then
  echo "about to start picom"
  sleep 1
  picom -b --conf $HOME/Library/etc/picom.conf --write-pid-path /tmp/$UID-picom.pid
fi
