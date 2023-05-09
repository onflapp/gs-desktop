#!/bin/sh

echo "Use port 2121 to connect"
echo "login:ftp password:23322"

ip -o -4 a | awk '{print $4}'

BASEDIR="$HOME/Library/CloudManager"
mkdir -p "$BASEDIR"

if [ -d "$1" ];then
  D=`dirname $0`
  R="$1"
  cd "$BASEDIR" || exit 1
  /usr/sbin/vsftpd "$D/personal-ftp.conf" "-oanon_root=$R" "-olocal_root=$R" 
fi
