#!/bin/bash

cp ./usr/share/xsessions/* /usr/share/xsessions
cp ./System/bin/* /System/bin
cp -R ./System/etc/* /System/etc

mkdir -p /Library/Preferences 2>/dev/null
cp ./Library/Preferences/* /Library/Preferences

mkdir -p /Library/Preferences/.NextSpace 2>/dev/null
cp ./Library/Preferences/.NextSpace/* /Library/Preferences/.NextSpace

mkdir -p /Library/Services 2>/dev/null
cp ./Library/Services/* /Library/Services

cp ./System/share/WindowMaker/Icons/* /System/share/WindowMaker/Icons
