#!/bin/bash

function start_services {
  echo "making services"
  /Library/bin/make_services

  echo "about to start Notification Center"
  /Library/bin/gdnc --daemon &
  echo "$!" > /tmp/$UID-gdnc.pid

  echo "about to start Pasteboard Service"
  /Library/bin/gpbs --daemon &
  echo "$!" > /tmp/$UID-gpbs.pid
}

function start_workspace {
  echo "about to start Workspace"
  /Applications/GWorkspace.app/GWorkspace

  PID=`cat /tmp/$UID-wm.pid`
  if [ -n "x$PID" ];then
    echo "Workspace finished, killing WM at $PID"
    kill $PID
  fi

  PID=`cat /tmp/$UID-gdnc.pid`
  if [ -n "x$PID" ];then
    kill -9 $PID
  fi

  PID=`cat /tmp/$UID-gpbs.pid`
  if [ -n "x$PID" ];then
    kill -9 $PID
  fi
}

start_services
start_workspace
