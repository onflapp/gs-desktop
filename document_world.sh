#!/bin/bash

export PATH=/Library/bin:/System/bin:$PATH

. /Developer/Makefiles/GNUstep.sh

D=`pwd`

echo "=================="
echo " gnustep documentation"
echo "=================="

cd ../gnustep-base/Documentation
make clean
make || exit 1
make install

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
make install

cd "$D"
cd ../gnustep-make/Documentation
make clean
make || exit 1
make install

cd "$D"
cd ../gnustep-back/Documentation
make clean
make || exit 1
make install

cd "$D"
cd ../libs-dbuskit/Documentation
make clean
make || exit 1
make install

cd /Library/Documentation
find . -name '*.igsdoc' -exec rm {} \;

echo "=================="
echo " steptalk documentation"
echo "=================="

cd "$D"
cd ../libs-steptalk/

T="/Library/Documentation/Developer/StepTalk"
mkdir -p "$T" 2>/dev/null

cp -R ./Documentation "$T"
cp -R ./Examples "$T"

echo "=================="
echo " gorm documentation"
echo "=================="

cd "$D"
cd ../apps-gorm/Documentation

make clean
make || exit 1
make install

echo "=================="
echo " GWorkspace documentation"
echo "=================="

cd "$D"
cd ../gs-workspace

T="/Library/Documentation/User"
cp ./Documentation/* "$T"

echo ""
echo " documentation has been installed to /Library/Documentation"
echo ""
