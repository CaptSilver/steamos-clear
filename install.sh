#!/bin/bash

# Set the defaults. These can be overridden by specifying the value as an
# environment variable when running this script.
INCLUDE_OPENSSH= ${INCLUDE_OPENSSH:-true}
INCLUDE_SAKURA="${INCLUDE_SAKURA:-false}"
INCLUDE_PROTONFIX="${INCLUDE_PROTONFIX:-false}"
INCLUDE_GPU_DRIVERS="${INCLUDE_GPU_DRIVERS:-true}"
GPU_TYPE="${GPU_TYPE:-auto}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
STEAM_USER="${1:-steam}"
STEAMOS_BUILD_DIR="${STEAMOS_BUILD_DIR:-/tmp}"
export STEAM_USER

# Configure the default versions of the SteamOS packages to use. These generally
# don't ever need to be overridden.

STEAMOS_STEAM_VER="${STEAMOS_STEAM_VER:-1.0.0.61}"
STEAMOS_COMPOSITOR_VER="${STEAMOS_COMPOSITOR_VER:-1.35}"
STEAMOS_MODESWITCH_VER="${STEAMOS_MODESWITCH_VER:-1.10}"
STEAMOS_ALIENWAREWMI_VER="${STEAMOS_ALIENWAREWMI_VER:-2.58}"

# Ensure the script is being run as root
if [ "$EUID" -ne 0 ]; then
	echo "This script must be run with sudo."
	exit
fi

# Confirm from the user that it's OK to continue
if [[ "${NON_INTERACTIVE}" != "true" ]]; then
	echo "Options:"
	echo "  OpenSSH:      ${INCLUDE_OPENSSH}"
	echo "  Terminal:     ${INCLUDE_SAKURA}"
	echo "  Proton Fixes: ${INCLUDE_PROTONFIX}"
	echo "  GPU Drivers:  ${INCLUDE_GPU_DRIVERS}"
	echo "    GPU Type:   ${GPU_TYPE}"
	echo "  Steam User:   ${STEAM_USER}"
	echo ""
	echo "This script will configure a SteamOS-like experience on Ubuntu."
	read -p "Do you want to continue? [Yy] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Starting installation..."
	else
		echo "Aborting installation."
		exit
	fi
fi

#Need to install Pre-Requirements for compilation and downloading.
echo "Installing Requirements for installation"
swupd bundle-add wget devpkg-libX11 devpkg-SDL_image devpkg-systemd python3-basic

# Download the packages we need. If we fail at downloading, stop the script.
set -e
echo "Downloading SteamOS packages..."
wget -P ${STEAMOS_BUILD_DIR} "http://repo.steampowered.com/steam/pool/steam/s/steam/steam_${STEAMOS_STEAM_VER}.tar.gz"
wget -P ${STEAMOS_BUILD_DIR} "http://repo.steamstatic.com/steamos/pool/main/s/steamos-compositor/steamos-compositor_${STEAMOS_COMPOSITOR_VER}.tar.xz"
wget -P ${STEAMOS_BUILD_DIR} "http://repo.steamstatic.com/steamos/pool/main/s/steamos-modeswitch-inhibitor/steamos-modeswitch-inhibitor_${STEAMOS_MODESWITCH_VER}.tar.xz"
wget -P ${STEAMOS_BUILD_DIR} "http://repo.steamstatic.com/steamos/pool/main/s/steamos-base-files/steamos-base-files_${STEAMOS_ALIENWAREWMI_VER}.tar.xz"
set +e

# See if there is a 'steam' user account. If not, create it.
if ! grep "^${STEAM_USER}" /etc/passwd > /dev/null; then
	echo "Steam user '${STEAM_USER}' not found. Creating it..."
	useradd --disabled-password --gecos "" "${STEAM_USER}"
fi
STEAM_UID=$(grep "^${STEAM_USER}" /etc/passwd | cut -d':' -f3)
STEAM_GID=$(grep "^${STEAM_USER}" /etc/passwd | cut -d':' -f4)
echo "Steam user '${STEAM_USER}' found with UID ${STEAM_UID} and GID ${STEAM_GID}"

# Choosing from the guide in Proton (SteamPlay) Wiki https://github.com/ValveSoftware/Proton/wiki/Requirements
# Install the GPU drivers if it was specified by the user.
if [[ "${INCLUDE_GPU_DRIVERS}" == "true" ]]; then

	# Autodetect the GPU so we can install the appropriate drivers.
	if [[ "${GPU_TYPE}" == "auto" ]]; then
		echo "Auto-detecting GPU..."
		if lspci | grep -i vga | grep -iq nvidia; then
			echo "  Detected Nvidia GPU"
			GPU_TYPE="nvidia"
		elif lspci | grep -i vga | grep -iq amd; then
			echo "  Detected AMD GPU"
			GPU_TYPE="amd"
		elif lspci | grep -i vga | grep -iq intel; then
			GPU_TYPE="intel"
			echo "  Detected Intel GPU"
		else
			GPU_TYPE="none"
			echo "  Unable to determine GPU. Skipping driver install."
		fi
	fi

	# Install the GPU drivers.
	case "${GPU_TYPE}" in
		nvidia)
			echo "Installing the latest Nvidia drivers..."
			echo "NVIDIA driver installation is still disabled for now!"
			;;
		amd)
			echo "The latest AMD drivers are installed!"
			;;
		intel)
			echo "The latest Intel drivers are installed!"
			;;
		none)
			echo "GPU not detected."
			;;
		*)
			echo "Skipping GPU driver installation."
			;;
	esac
fi

# Install steam and steam device support.
echo "Installing steam..."
tar xvf ${STEAMOS_BUILD_DIR}/steam_${STEAMOS_STEAM_VER}.tar.gz --strip-components=0 -C ${STEAMOS_BUILD_DIR}
pushd ${STEAMOS_BUILD_DIR}/steam/
make install
popd
rm ${STEAMOS_BUILD_DIR}/steam_${STEAMOS_STEAM_VER}.tar.gz
rm -rf ${STEAMOS_BUILD_DIR}/steam

# Enable Protonfix for ease of use w_${STEAMOS_STEAM_VER}ith certain games that needs tweaking.
# https://github.com/simons-public/protonfixes
# Installing Protonfix for ease of use
if [[ "${INCLUDE_PROTONFIX}" == "true" ]]; then
	echo "Installing protonfix..."
	pip3 install protonfixes --upgrade
	# Installing cefpython3 for visual progress bar
	pip install cefpython3
	# Edit Proton * user_settings.py
fi

# Install a terminal emulator that can be added from Big Picture Mode.
if [[ "${INCLUDE_SAKURA}" == "true" ]]; then
	echo "Sakura is unable to be installed at this time."
	#apt install sakura -y
fi

# Install openssh-server for remote administration
if [[ "${INCLUDE_OPENSSH}" == "true" ]]; then
	echo "Installing OpenSSH Server..."
	swupd bundle-add openssh-server
fi

# Enable automatic login. We use 'envsubst' to replace the user with ${STEAM_USER}.
echo "Enabling automatic login..."
mkdir -p /etc/gdm/
envsubst < ./conf/custom.conf > /etc/gdm/custom.conf

# Create our session switching scripts to allow rebooting to the desktop
echo "Creating reboot to session scripts..."
envsubst < ./conf/reboot-to-desktop-mode.sh > /usr/local/sbin/reboot-to-desktop-mode
envsubst < ./conf/reboot-to-steamos-mode.sh > /usr/local/sbin/reboot-to-steamos-mode
chmod +x /usr/local/sbin/reboot-to-desktop-mode
chmod +x /usr/local/sbin/reboot-to-steamos-mode

# Create the "steamos-fg" script as a workaround for games like Deadcells with the Steam compositor.
cp ./conf/steamos-fg.sh /usr/local/sbin/steamos-fg
chmod +x /usr/local/sbin/steamos-fg

# Create a sudoers rule to allow passwordless reboots between sessions.
echo "Creating sudoers rules to allow rebooting between sessions..."
mkdir -p /etc/sudoers.d
cp ./conf/reboot-sudoers.conf /etc/sudoers.d/steamos.conf
chmod 440 /etc/sudoers.d/steamos-reboot

# Install the steamos compositor, modeswitch, and themes
echo "Installing Compositor and Modeswitch"
tar xvf ${STEAMOS_BUILD_DIR}/steamos-compositor_${STEAMOS_COMPOSITOR_VER}.tar.xz --strip-components=0 -C ${STEAMOS_BUILD_DIR}
pushd ${STEAMOS_BUILD_DIR}/steamos-compositor-${STEAMOS_COMPOSITOR_VER}
./configure
make
make install
cp ./usr/bin/steamos-sessions /usr/bin/
chmod +x /usr/bin/steamos-sessions
mv ./usr/bin/steamos /usr/bin/
popd
rm ${STEAMOS_BUILD_DIR}/steamos-compositor_${STEAMOS_COMPOSITOR_VER}.tar.xz
rm -rf ${STEAMOS_BUILD_DIR}/steamos-compositor-${STEAMOS_COMPOSITOR_VER}

tar xvf ${STEAMOS_BUILD_DIR}/steamos-modeswitch-inhibitor_${STEAMOS_MODESWITCH_VER}.tar.xz --strip-components=0 -C ${STEAMOS_BUILD_DIR}
pushd ${STEAMOS_BUILD_DIR}/steamos-modeswitch-inhibitor-${STEAMOS_MODESWITCH_VER}
./configure
make
make install
popd
rm ${STEAMOS_BUILD_DIR}/steamos-modeswitch-inhibitor_${STEAMOS_MODESWITCH_VER}.tar.xz
rm -rf ${STEAMOS_BUILD_DIR}/steamos-modeswitch-inhibitor-${STEAMOS_MODESWITCH_VER}


# Install Alienware WMI Control
tar xvf ${STEAMOS_BUILD_DIR}/steamos-base-files_${STEAMOS_ALIENWAREWMI_VER}.tar.xz --strip-components=3 -C /usr/bin/ steamos-base-files-2.58/usr/bin/alienware_wmi_control.sh
rm ${STEAMOS_BUILD_DIR}/steamos-base-files_${STEAMOS_ALIENWAREWMI_VER}.tar.xz
chmod +x /usr/bin/alienware_wmi_control.sh

# Set the X session to use the installed steamos session
echo "Configuring the default session..."
mkdir -p "/usr/local/share/xsessions"
cp ./conf/steamos.desktop "/usr/local/share/xsessions/steamos.desktop"
cp ./conf/steamos-update "/usr/bin/steamos-update"
chmod +x /usr/bin/steamos-update
touch /etc/lsb-release

echo ""
echo "Installation complete! Press ENTER to reboot or CTRL+C to exit"
read -r
sudo reboot
