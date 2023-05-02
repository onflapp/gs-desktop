#!/bin/bash

curl https://twilightedge.com/downloads/PikoPixel.Sources.1.0-b10a.tar.gz --output PikoPixel.tgz
tar -xvf ./PikoPixel.tgz
cd ./PikoPixel.Sources*/PikoPixel
make && sudo -E make install
