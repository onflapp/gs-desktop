#!/bin/sh

rm build_world*.log

rm -fR /etc/skel/Library
rm -fR /System
rm -fR /Applications
rm -fR /Library
rm -fR /Developer

rm /etc/ld.so.conf.d/gs-desktop.conf
rm /usr/share/xsessions/gs-desktop-safe.desktop
rm /usr/share/xsessions/gs-desktop.desktop

rm /usr/bin/startgsde-safe
rm /usr/bin/startgsde

ldconfig
