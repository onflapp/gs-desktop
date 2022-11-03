#!/bin/bash

unset TERM
XID="$1"
shift
vlc -q -I rc --rc-show-pos --no-playlist-autostart --drawable-xid "$XID" $@
