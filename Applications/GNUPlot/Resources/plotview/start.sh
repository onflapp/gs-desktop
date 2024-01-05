#!/bin/bash

DIR="${0%/*}"
FILE="$2"
XID="$1"

export GNUTERM="x11 window \"$XID\""
gnuplot
