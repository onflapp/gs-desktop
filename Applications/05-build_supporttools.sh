#!/bin/bash

D=`pwd`

mkdir -p /Applications/Utilities 2>/dev/null
cp -R ./Convertors /Applications/Utilities/

mkdir -p /Library/Scripts 2>/dev/null
cp ./Scripts/* /Library/Scripts/
chmod 0755 /Library/Scripts/*
