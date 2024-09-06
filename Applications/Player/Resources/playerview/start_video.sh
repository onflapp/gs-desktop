#!/bin/sh

unset TERM
XID="$1"
vlc -q -I rc --vout xvideo --rc-show-pos --no-playlist-autostart --drawable-xid "$XID" "$2"
