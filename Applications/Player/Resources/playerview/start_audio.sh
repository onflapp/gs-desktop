#!/bin/bash

unset TERM
vlc -q -I rc --rc-show-pos --no-playlist-autostart "$1"
