#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export OMARCHY_ONLINE_INSTALL=true

ansi_art='                 ▄▄▄
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀
                                       ███   █▀                                  '

clear
echo -e "\n$ansi_art\n"

# Base distro: debian (default on this branch) or arch
OMARCHY_BASE="${OMARCHY_BASE:-debian}"

if [[ $OMARCHY_BASE == "arch" ]]; then
  OMARCHY_PM="pacman"
  OMARCHY_REF="${OMARCHY_ARCH_REF:-quattro}"
  export OMARCHY_MIRROR="${OMARCHY_MIRROR:-stable}"
else
  OMARCHY_PM="apt"
  OMARCHY_REF="${OMARCHY_REF:-debian-version}"
  export OMARCHY_MIRROR="${OMARCHY_MIRROR:-stable}"
fi

# Set mirror based on branch
if [[ $OMARCHY_REF == "dev" ]]; then
  export OMARCHY_MIRROR=edge
elif [[ $OMARCHY_REF == "rc" ]]; then
  export OMARCHY_MIRROR=rc
else
  export OMARCHY_MIRROR=stable
fi

if [[ $OMARCHY_PM == "apt" ]]; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git
else
  sudo pacman -Sy --noconfirm
fi

# Use custom repo if specified, otherwise default to the base distro's repo
if [[ $OMARCHY_BASE == "arch" ]]; then
  OMARCHY_REPO="${OMARCHY_REPO:-omacom/omarchy}"
else
  OMARCHY_REPO="${OMARCHY_REPO:-alfonsocv12/omarchy}"
fi

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git"
rm -rf ~/.local/share/omarchy/
git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

echo -e "\e[32mUsing branch: $OMARCHY_REF\e[0m"
cd ~/.local/share/omarchy
git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
cd -

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy/install.sh
