#!/bin/bash
STEAMOS_BUILD_DIR="${1:-/tmp}"
NVIDIA_KERNEL_TYPE="${NVIDIA_KERNEL_TYPE:-NATIVE}"

# Ensure the script is being run as root
if [ "$EUID" -ne 0 ]; then
	echo "This script must be run with sudo."
	exit
fi


#If/else for LTS and Native should be implented here

echo "This script is in Alpha staging!"
echo "Installing pre-requirements (DKMS)"
echo "The LTS Kernel is recommended for NVIDIA!"

if [[ "${NVIDIA_KERNEL_TYPE}" == "NATIVE" ]]; then
	swupd bundle-add kernel-native-dkms
	clr-boot-manager update
else
	swupd bundle-add kernel-lts-dkms
fi

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
wget -P ${STEAMOS_BUILD_DIR} "https://download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run"
chmod +x ${STEAMOS_BUILD_DIR}/NVIDIA-Linux-x86_64-430.26.run

echo "Installing Nvidia drivers"

set -e
${STEAMOS_BUILD_DIR}/NVIDIA-Linux-x86_64-430.26.run \
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

rm -rf ${STEAMOS_BUILD_DIR}/NVIDIA*

#Recommending a repair due to official wiki
echo "Nvidia drivers installed! Please run: 'swupd repair --quick --bundles=lib-opengl' to repair your installation"
