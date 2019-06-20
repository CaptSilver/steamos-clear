#!/bin/bash
#Going to have to compile and install ffmpeg due to Netflix and youtube for a console experience
#Need BUILD_DIR var

echo "Downloading FFMPEG"

wget -P /tmp "https://ffmpeg.org/releases/ffmpeg-4.1.3.tar.bz2"

echo "Unpacking and Compiling FFMPEG"

tar jxf /tmp/ffmpeg-4.1.3.tar.bz2

pushd /tmp/ffmpeg-4.1.3
./configure --prefix=/usr/local --enable-shared && make && sudo make install
popd

echo "Cleaning UP!"
rm -rf /tmp/ffmpeg*