#!/bin/bash

cp ./usr/share/xsessions/* /usr/share/xsessions
cp ./System/bin/* /System/bin
cp -R ./System/etc/* /System/etc

mkdir -p /Library/Preferences 2>/dev/null
cp ./Library/Preferences/* /Library/Preferences

mkdir -p /Library/Services 2>/dev/null
cp ./Library/Services/* /Library/Services
