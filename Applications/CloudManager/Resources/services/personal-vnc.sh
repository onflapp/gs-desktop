#!/bin/sh

ip -o -4 a | awk '{print $4}'

env
/usr/bin/x11vnc
