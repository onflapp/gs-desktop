#!/bin/bash

mkdir -p /Applications/Utilities/Helpers 2>/dev/null
cp -R --preserve=mode ../Helpers/*.app /Applications/Utilities/Helpers

mkdir -p /Applications/Utilities/Admin 2>/dev/null
cp -R --preserve=mode ../Admin/* /Applications/Utilities/Admin

mkdir -p /Library/Scripts 2>/dev/null
cp --preserve=mode ../Scripts/* /Library/Scripts/
chmod 0755 /Library/Scripts/*
