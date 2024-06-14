#!/bin/sh

cp -Ra ../Helpers/*.app /System/Applications

mkdir -p /Library/Scripts 2>/dev/null
cp -a ../Scripts/* /Library/Scripts/
chmod 0755 /Library/Scripts/*
