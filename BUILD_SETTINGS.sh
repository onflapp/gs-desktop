export CC=clang
export CXX=clang++
#export LD=/usr/bin/ld.gold
export LD=lld
export LDFLAGS="-fuse-ld=$LD"
export OBJCFLAGS="-fblocks"
#export RELEASE_BUILD=yes
