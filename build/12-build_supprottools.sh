#!/bin/sh

cp -R --preserve=mode ../Helpers/*.app /System/Applications

mkdir -p /Library/Scripts 2>/dev/null
cp --preserve=mode ../Scripts/* /Library/Scripts/
chmod 0755 /Library/Scripts/*
