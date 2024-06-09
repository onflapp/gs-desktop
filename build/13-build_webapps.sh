#!/bin/sh

mkdir -p /Applications/WebApps 2>/dev/null
cp -R --preserve=mode ../../gs-webbrowser/Applications/*.app /Applications/WebApps/
