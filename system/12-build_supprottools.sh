#!/bin/bash

cp -R --preserve=mode ../Helpers/*.app /System/Applications

mkdir -p /Applications/Utilities/Admin 2>/dev/null
cp -R --preserve=mode ../Admin/* /Applications/Utilities/Admin

mkdir -p /Library/Scripts 2>/dev/null
cp --preserve=mode ../Scripts/* /Library/Scripts/
chmod 0755 /Library/Scripts/*
