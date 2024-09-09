#!/usr/bin/env bash

if [ "$1" = "shell" ];then
  clear
  echo "Login as user $LOGNAME to continue"
  chsh
  exit
fi

if [ $UID -ne 0 ];then
  clear
  echo -e "\e[33;41m                                     "
  echo             "   Login as admin user to continue   "
  echo -e          "                                     \e[0m"
  echo ""
  export LOGIN="$LOGNAME"
  exec sudo -E $0 $1
fi

if [ "$1" = "info" ];then
  clear
  chfn "$LOGIN"
else
  clear
  read -p "enter login name to create: " NAME

  if [ -n "$NAME" ];then
    adduser $NAME
  fi
fi
