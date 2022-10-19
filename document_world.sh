#!/bin/bash

export PATH=/Library/bin:$PATH

D=`pwd`

cd ../gnustep-base/Documentation
make clean
make || exit 1
sudo -E make install

cd "$D"
cd ../gnustep-gui/Documentation

### fix missing headers
touch ../Headers/AppKit/NSCollectionViewLayout.h
touch ../Headers/AppKit/NSCollectionViewTransitionLayout.h
touch ../Headers/AppKit/NSCollectionViewGridLayout.h
touch ../Headers/AppKit/NSCollectionViewCompositionalLayout.h
touch ../Headers/AppKit/NSCollectionViewFlowLayout.h

make clean
make || exit 1
sudo -E make install

cd "$D"
cd ../gnustep-make/Documentation
make clean
make || exit 1
sudo -E make install

cd "$D"
cd ../gnustep-back/Documentation
make clean
make || exit 1
sudo -E make install

cd "$D"
cd ../libs-dbuskit/Documentation
make clean
make || exit 1
sudo -E make install

cd /Library/Documentation
#find . -name '*.gsdoc' -exec rm {} \;
#find . -name '*.igsdoc' -exec rm {} \;
