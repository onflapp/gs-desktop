#!/bin/bash

unset TERM
XID="$1"
shift
vlc -q -I rc --rc-show-pos --drawable-xid "$XID" $@
#vlc -I rc --rc-fake-tty --rc-show-pos
#vlc --width 100 --no-autoscale --drawable-xid 0x1a1c516
