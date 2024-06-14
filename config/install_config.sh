#!/bin/sh

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

ln -s /System/bin/startgsde-safe /usr/bin/startgsde-safe
ln -s /System/bin/startgsde /usr/bin/startgsde

chmod 4755 /Library/bin/gdomap

./make_hidden.sh
echo "done"
