#!/bin/bash
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#

export DEBIAN_FRONTEND=noninteractive

# Add apt repos

# Detect Ubuntu VERSION_ID from /etc/os-release (e.g., "20.04") and format to "2004"
UBUNTU_VERSION_ID=$(. /etc/os-release && echo "$VERSION_ID")
NVIDIA_REPO_VERSION=$(echo "$UBUNTU_VERSION_ID" | sed 's/\.//')

# Apt dependencies; needed for add-apt-repository and curl downloads to work
apt-get -y update
apt-get --no-install-recommends -y install ca-certificates curl apt-transport-https lsb-release gnupg software-properties-common

## CUDA
curl -L -o /etc/apt/preferences.d/cuda-repository-pin-600 "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${NVIDIA_REPO_VERSION}/x86_64/cuda-ubuntu${NVIDIA_REPO_VERSION}.pin"
apt-key adv --fetch-keys "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${NVIDIA_REPO_VERSION}/x86_64/3bf863cc.pub"
add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${NVIDIA_REPO_VERSION}/x86_64/ /"

## PowerShell
curl -L -o packages-microsoft-prod.deb https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION_ID}/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm -f packages-microsoft-prod.deb
add-apt-repository universe

## Azure CLI
mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    tee /etc/apt/keyrings/microsoft.gpg > /dev/null
chmod go+r /etc/apt/keyrings/microsoft.gpg

AZ_DIST=$(lsb_release -cs)
echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" |
    tee /etc/apt/sources.list.d/azure-cli.list

apt-get -y update
apt-get -y upgrade

# Add apt packages

## vcpkg prerequisites
APT_PACKAGES="git curl zip unzip tar"

## essentials
APT_PACKAGES="$APT_PACKAGES \
  autoconf autoconf-archive \
  autopoint \
  build-essential \
  cmake \
  gcc g++ gfortran \
  libnuma1 libnuma-dev \
  libtool libtool-bin libltdl-dev \
  libudev-dev \
"

## vcpkg_find_acquire_program
APT_PACKAGES="$APT_PACKAGES \
  bison libbison-dev \
  flex \
  gperf \
  nasm \
  ninja-build \
  pkg-config \
  python3 \
  ruby-full \
  swig \
  yasm \
"

## mesa and X essentials
APT_PACKAGES="$APT_PACKAGES \
  mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev libgles2-mesa-dev \
  libx11-dev \
  libxaw7-dev \
  libxcursor-dev \
  libxi-dev \
  libxinerama-dev \
  libxkbcommon-x11-dev \
  libxrandr-dev \
  libxt-dev \
  libxxf86vm-dev \
  xutils-dev \
"

## required by qt5-base
APT_PACKAGES="$APT_PACKAGES libxext-dev libxfixes-dev libxrender-dev \
  libxcb1-dev libx11-xcb-dev libxcb-glx0-dev libxcb-util0-dev"

## required by qt5-base for qt5-x11extras
APT_PACKAGES="$APT_PACKAGES libxkbcommon-dev libxcb-keysyms1-dev \
  libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev \
  libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev \
  libxcb-render-util0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xinput-dev"

## required by xcb feature in qtbase
APT_PACKAGES="$APT_PACKAGES libxcb-cursor-dev"

## required by libhdfs3
APT_PACKAGES="$APT_PACKAGES libkrb5-dev"

## required by kf5windowsystem
APT_PACKAGES="$APT_PACKAGES libxcb-res0-dev"

## required by kf5globalaccel
APT_PACKAGES="$APT_PACKAGES libxcb-keysyms1-dev libxcb-xkb-dev libxcb-record0-dev"

## required by mesa
APT_PACKAGES="$APT_PACKAGES python3-setuptools python3-mako libxcb-dri3-dev libxcb-present-dev"

## required by some packages to install additional python packages
APT_PACKAGES="$APT_PACKAGES python3-pip python3-venv python3-jinja2"

## required by qtwebengine
APT_PACKAGES="$APT_PACKAGES nodejs"

## required by qtwayland
APT_PACKAGES="$APT_PACKAGES libwayland-dev"

## required by all GN projects
APT_PACKAGES="$APT_PACKAGES python-is-python3"

## required by libctl
APT_PACKAGES="$APT_PACKAGES guile-2.2-dev"

## required by gtk
APT_PACKAGES="$APT_PACKAGES libxdamage-dev libselinux1-dev"

## required by at-spi2-atk
APT_PACKAGES="$APT_PACKAGES libxtst-dev"

## required by bond
APT_PACKAGES="$APT_PACKAGES haskell-stack"

## required by boringssl
APT_PACKAGES="$APT_PACKAGES golang-go"

## required by libdecor and mesa
APT_PACKAGES="$APT_PACKAGES wayland-protocols"

## required by robotraconteur
APT_PACKAGES="$APT_PACKAGES libbluetooth-dev"

## CUDA
APT_PACKAGES="$APT_PACKAGES cuda-compiler-12-8 cuda-libraries-dev-12-8 cuda-driver-dev-12-8 \
  cuda-cudart-dev-12-8 libcublas-12-8 libcurand-dev-12-8 cuda-nvml-dev-12-8 libcudnn9-dev-cuda-12 \
  libnccl2 libnccl-dev"

## PowerShell + Azure
APT_PACKAGES="$APT_PACKAGES powershell azcopy azure-cli"

## Additionally required/installed by Azure DevOps Scale Set Agents, skip on WSL
if [[ $(grep microsoft /proc/version) ]]; then
echo "Skipping install of ADO prerequisites on WSL."
else
APT_PACKAGES="$APT_PACKAGES libkrb5-3 zlib1g libicu70 debsums liblttng-ust1"
fi

apt-get --no-install-recommends -y install $APT_PACKAGES

az --version
