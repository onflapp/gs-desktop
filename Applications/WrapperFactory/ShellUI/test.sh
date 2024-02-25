#!/bin/bash

# set values
echo "TEXTFIELD=Hello"

# read reply into variables
source /dev/stdin

echo "LOG:action [$1]"
echo "LOG:TEXTFIELD value [$TEXTFIELD]"
