#!/bin/bash

echo "=================="
echo " system config"
echo "=================="

mkdir -p /usr/share/xsessions 2>/dev/null
cp ./usr/share/xsessions/* /usr/share/xsessions
cp ./usr/local/bin/* /usr/local/bin
cp ./System/bin/* /System/bin
cp -R ./System/etc/* /System/etc
cp -R ./etc/skel/* /etc/skel

mkdir -p /Library/Preferences 2>/dev/null
cp ./Library/Preferences/* /Library/Preferences

mkdir -p /Library/Preferences/.NextSpace 2>/dev/null
cp ./Library/Preferences/.NextSpace/* /Library/Preferences/.NextSpace

mkdir -p /Library/Themes 2>/dev/null
cp -r ./Library/Themes/* /Library/Themes

cp ./System/share/WindowMaker/Icons/* /System/share/WindowMaker/Icons

./make_hidden.sh
echo "done"

echo "=================="
echo " gdomap service"
echo "=================="

systemctl daemon-reload
systemctl stop gdomap.service

cp ./etc/systemd/system/gdomap.service /etc/systemd/system

systemctl enable gdomap.service
systemctl start gdomap.service
systemctl --no-pager  status gdomap.service || exit 1

echo "done"
