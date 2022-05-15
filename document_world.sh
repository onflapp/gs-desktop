#!/bin/bash

D=`pwd`

cd ../gnustep-base/Documentation
make install

cd "$D"
cd ../gnustep-gui/Documentation
make install

cd "$D"
cd ../gnustep-make/Documentation
make install

cd "$D"
cd ../gnustep-back/Documentation
make install

cd "$D"
cd ../libs-dbuskit/Documentation
make install

cd /Library/Documentation
find . -name '*.gsdoc' -exec rm {} \;
find . -name '*.igsdoc' -exec rm {} \;
