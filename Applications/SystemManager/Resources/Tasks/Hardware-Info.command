#!/bin/sh

inxi -Fxz
echo "---"
lspci -v
