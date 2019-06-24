#!/bin/bash
#Need to review pre-reqs
#Needs desktop-dev to compile, :(
#Code has not been tested yet...

echo "Downloading Sakura!"
wget -P "/tmp" "https://launchpad.net/sakura/trunk/3.6.0/+download/sakura-3.6.0.tar.bz2"

echo "Decompressing package"
tar xvf "/tmp/sakura-3.6.0.tar.bz2" -C "/tmp"

echo "Compiling and Installing Sakura!"
pushd "/tmp/sakura-3.6.0"
./cmake ./
make
make install
popd

echo "Cleaning up"
rm -rf "/tmp/sakura*"