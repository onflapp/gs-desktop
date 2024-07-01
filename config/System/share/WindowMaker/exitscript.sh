#!/usr/bin/env bash

PID=`cat /tmp/$UID-picom.pid 2>/dev/null`
if [ -n "$PID" ];then
  echo "stopping picom on $PID"
  kill "$PID" 2>/dev/null
  rm /tmp/$UID-picom.pid
fi
