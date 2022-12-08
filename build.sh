#!/bin/bash
set -e

# Ensure all submodules are present (recursive)
git submodule update --init --recursive

# Create build directory
rm -rf build
mkdir -p build

# Apply Boost patches
patch -p0 -f < boost.patch

# Configure Boost
cd boost
./bootstrap.sh

# Fix Boost config for Emscripten
sed -i "s|using gcc ;|using gcc : : \"$(which em++)\" ;|" project-config.jam
sed -i "s|toolset.flags gcc.archive .AR \\\$(condition) : \\\$(archiver\[1\])|toolset.flags gcc.archive .AR \\\$(condition) : \"$(which emar)\"|" tools/build/src/tools/gcc.jam
sed -i "s|toolset.flags gcc.archive .RANLIB \\\$(condition) : \\\$(ranlib\[1\])|toolset.flags gcc.archive .RANLIB \\\$(condition) : \"$(which emranlib)\"|" tools/build/src/tools/gcc.jam

# Build Boost
./b2 link=static variant=release threading=single runtime-link=static program_options filesystem system thread headers

# Collect Boost binaries
mkdir -p bin.v2/wasm
find bin.v2/libs -name '*.a' -exec cp -- "{}" bin.v2/wasm \;

# Clean up Boost
cd tools/build
git checkout .
cd ../../..

# Build Project Icestorm
cd icestorm
make -j `nproc`
sudo make install
cd ..

# Build Project Trellis
cd trellis/libtrellis
cmake .
make -j `nproc`
sudo make install
cd ../..

# Apply patches
patch -p0 -f < nextpnr.patch
patch -p0 -f < nextpnr-ice40.patch

# Configure nextpnr
echo "Building nextpnr natively..."
cd nextpnr
ARCHITECTURES="ice40 ecp5"
cmake . -DARCH=$ARCHITECTURES

# Build nextpnr
(make -j `nproc` || true)

# Configure nextpnr-ice40 with Emscripten
echo "Building nextpnr-ice40 with Emscripten..."
rm -rf CMakeCache.txt
emcmake cmake . -DARCH=ice40 -DBBA_IMPORT=./bba-export.cmake -DBoost_INCLUDE_DIRS=../boost -DICESTORM_INSTALL_PREFIX=/usr/local

# Build nextpnr-ice40 with Emscripten
emmake make -j `nproc`

# Configure nextpnr-ecp5 with Emscripten
echo "Building nextpnr-ecp5 with Emscripten..."
rm -rf CMakeCache.txt
emcmake cmake . -DARCH=ecp5 -DBBA_IMPORT=./bba-export.cmake -DBoost_INCLUDE_DIRS=../boost -DTRELLIS_INSTALL_PREFIX=/usr/local -DTRELLIS_LIBDIR=/usr/local/lib/trellis

# Build nextpnr-ecp5 with Emscripten
emmake make -j `nproc`

# Patch Emscripten build output
sed -i 's|var FS=|var FS=Module.FS=|' nextpnr*.js
mv nextpnr*.js ../build
cp nextpnr*.wasm ../build

# Clean up
make clean
cd ..

# Undo patches
patch -p0 -f -R < boost.patch
patch -p0 -f -R < nextpnr.patch
patch -p0 -f -R < nextpnr-ice40.patch

# Build npm package
yarn run build
