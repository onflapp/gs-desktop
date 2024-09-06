#!/bin/sh

unset TERM
#vlc -q -I rc --rc-show-pos --no-playlist-autostart "$1"
vlc -q -I rc --rc-show-pos "$1"
