#!/bin/bash

cd ../../
git clone https://github.com/gnustep/libobjc2.git
cd ./libobjc2

git submodule init
git submodule update
