#!/bin/bash

curl http://cenon.download/source/CenonLibrary-4.0.0-1.tar.bz2 --output CenonLibrary.bz2
bzip2 -dc ./CenonLibrary.bz2 | tar -xvf -
sudo mv ./Cenon /Library/ApplicationSupport/Cenon

curl http://cenon.download/source/Cenon-4.0.2.tar.bz2 --output Cenon.bz2
bzip2 -dc ./Cenon.bz2 | tar -xvf -
cd ./Cenon
make && sudo -E make install
