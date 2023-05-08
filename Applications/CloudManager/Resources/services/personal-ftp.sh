#!/bin/bash

ip a | grep inet

if [ -d "$1" ];then
  D=`dirname $0`
  R="$1"
  cd "$R" || exit 1
  /usr/sbin/vsftpd "-oanon_root=$R" "-olocal_root=$R"  "$D/personal-ftp.conf"
fi
