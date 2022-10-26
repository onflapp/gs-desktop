#!/bin/sh
F=`realpath "$0"`
D=`dirname "$F"`
cd "$D"
exec /Library/bin/GSWrapper_Launcher $@
