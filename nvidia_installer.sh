#!/bin/bash

#Check for root

#If/else for LTS and Native should be implented here

echo "This script is in Alpha staging!"
echo "Installing pre-requirements (DKMS)"
swupd install kernel-native-dkms
clr-boot-manager update

#Disabling nouveau drivers
echo "Disabling Nouveau drivers. If script does not complete, please delete /etc/modprobe.d/disable-nouveau.conf"
mkdir -p /etc/modprobe.d
printf "blacklist nouveau \noptions nouveau modeset=0 \n" | sudo tee --append /etc/modprobe.d/disable-nouveau.conf


#Setting up Dynamic Linking compatability

echo "include /etc/ld.so.conf.d/*.conf" |  sudo tee --append /etc/ld.so.conf
mkdir -p /etc/ld.so.conf.d
printf "/opt/nvidia/lib \n/opt/nvidia/lib32 \n" | sudo tee --append /etc/ld.so.conf.d/nvidia.conf

#Download drivers
#Implement check for latest by checking:
#https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt
echo "Downloading the Latest drivers from Nvidia"
wget -P /tmp "https://download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run"
chmod +x /tmp/NVIDIA-Linux-x86_64-430.26.run

echo "Installing Nvidia drivers"

set -e
/tmp/NVIDIA-Linux-x86_64-430.26.run \
--utility-prefix=/opt/nvidia \
--opengl-prefix=/opt/nvidia \
--compat32-prefix=/opt/nvidia \
--compat32-libdir=lib32 \
--x-prefix=/opt/nvidia \
--documentation-prefix=/opt/nvidia \
--no-precompiled-interface \
--no-nvidia-modprobe \
--no-distro-scripts \
--force-libglx-indirect \
--dkms \
--silent
set +e

#Implement clean process here

#Recommending a repair due to official wiki
echo "Nvidia drivers installed! Please run: 'swupd repair --quick --bundles=lib-opengl' to repair your installation"
