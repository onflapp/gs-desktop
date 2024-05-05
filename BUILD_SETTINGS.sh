export CC=clang
export CXX=clang++
export LD="/usr/bin/ld.gold"
export LDFLAGS="-fuse-ld=$LD"
export OBJCFLAGS="-g -O0 -fblocks -Wno-error=implicit-function-declaration"
export NPROC=`nproc`
#export RELEASE_BUILD=yes
