#!/bin/bash

# Clone Boost repository
# TODO: use latest tag non-prerelease tag?
git clone https://github.com/boostorg/boost --branch boost-1.71.0
cd boost
git submodule update --init --recursive

# Setup Boost
./bootstrap.sh

# Fix Boost config for Emscripten
sed -i "s|using gcc ;|using gcc : : \"$(which em++)\" ;|" project-config.jam
sed -i "s|toolset.flags gcc.archive .AR \\\$(condition) : \\\$(archiver\[1\])|toolset.flags gcc.archive .AR \\\$(condition) : \"$(which emar)\"|" tools/build/src/tools/gcc.jam
sed -i "s|toolset.flags gcc.archive .RANLIB \\\$(condition) : \\\$(ranlib\[1\])|toolset.flags gcc.archive .RANLIB \\\$(condition) : \"$(which emranlib)\"|" tools/build/src/tools/gcc.jam

# Build Boost
./b2 link=static variant=release threading=single runtime-link=static program_options filesystem system thread headers

# Collect binaries
mkdir -p boost/bin.v2/wasm
find boost/bin.v2/libs -name '*.a' -exec cp -- "{}" boost/bin.v2/wasm \;

sudo apt install -y libftdi-dev

# Clone icestorm
git clone https://github.com/YosysHQ/icestorm
cd icestorm
make -j `nproc`
sudo make install
cd ..

# Clone nextpnr
git clone https://github.com/YosysHQ/nextpnr
cd nextpnr

# Apply patch
patch -p0 -f < CMakeLists.patch

# Build nextpnr
cmake . -DARCH=ice40
make -j `nproc`

# Build nextpnr with Emscripten
rm -rf CMakeCache.txt
emcmake cmake . -DARCH=ice40 -DBBA_IMPORT=./bba-export.cmake -DICESTORM_INSTALL_PREFIX=/usr/local -DBoost_INCLUDE_DIRS=../boost
make -j `nproc`
