#!/bin/bash
export PATH="/sbin:$PATH"

echo "Enter new image file to create"
FILE=`NSSavePanel`

if [ -z "$FILE" ];then
  echo "no file selected"
  exit 1
fi

SIZE=`NSTextField "Size in MB:" "10"`
if [ -z "$SIZE" ];then
  echo "no size set"
  exit 1
fi

TYPE=`NSTextField "File system (msdos,vfat,exfat,ext3):" "vfat"`
if [ -z "$TYPE" ];then
  echo "no type set"
  exit 1
fi

echo ""
echo "creating new file at $FILE"
dd if=/dev/zero of=$FILE bs=$SIZE count=1 || exit 1

echo ""
echo "making file system"
/sbin/mkfs -t $TYPE $FILE || exit 1

echo ""
echo "DONE"
nxworkspace --select "$FILE"
