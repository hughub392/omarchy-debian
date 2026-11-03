#!/bin/bash

# Build a Debian-based Omarchy live ISO.
#
# Pipeline:
#   1. debootstrap a Debian rootfs (default codename: trixie)
#   2. mount proc/sys/dev and chroot in to install live tooling, kernel and
#      the Omarchy package lists
#   3. mksquashfs the rootfs
#   4. assemble the ISO with GRUB (BIOS + UEFI)
#
# The resulting ISO boots a live Debian session whose boot entry runs the
# Omarchy installer (boot.sh -> install.sh) against the live environment.

set -e

DEBIAN_CODENAME="${1:-trixie}"
OMARCHY_ROOTFS="${2:-/tmp/omarchy-debian-rootfs}"
OMARCHY_ISO="${3:-/tmp/omarchy-debian.iso}"
OMARCHY_MIRROR="${OMARCHY_MIRROR:-https://deb.debian.org/debian}"
OMARCHY_ROOTFS_ISO="$OMARCHY_ROOTFS.iso"
OMARCHY_SRC="${OMARCHY_SRC:-$(cd "$(dirname "$0")/.." && pwd)}"

if [[ -z $OMARCHY_ROOTFS || -z $OMARCHY_ISO ]]; then
  echo "Usage: $0 [debootstrap-codename] [rootfs-dir] [iso-out]" >&2
  exit 1
fi

echo "debootstrapping Debian $DEBIAN_CODENAME into $OMARCHY_ROOTFS"
sudo debootstrap --arch=amd64 "$OMARCHY_MIRROR" "$OMARCHY_ROOTFS" "$DEBIAN_CODENAME"

mount -t proc /proc "$OMARCHY_ROOTFS/proc"
mount -t sysfs /sys "$OMARCHY_ROOTFS/sys"
mount -t tmpfs tmpfs "$OMARCHY_ROOTFS/dev"

chroot "$OMARCHY_ROOTFS" /bin/bash -c "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    linux-firmware \
    squashfs-tools \
    grub-pc \
    grub-efi-amd64 \
    efibootmgr \
    isolinux \
    syslinux \
    isolinux-utils \
    live-boot \
    systemd-sysv \
    initramfs-tools \
    dbus \
    dbus-x11 \
    network-manager
"

mkdir -p "$OMARCHY_ROOTFS/tmp/omarchy"
cp "$OMARCHY_SRC/install/omarchy-base.packages" "$OMARCHY_ROOTFS/tmp/omarchy/omarchy-base.packages"
cp "$OMARCHY_SRC/install/omarchy-other.packages" "$OMARCHY_ROOTFS/tmp/omarchy/omarchy-other.packages"

chroot "$OMARCHY_ROOTFS" /bin/bash -c "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends \
    \$(grep -v '^#' /tmp/omarchy/omarchy-base.packages | grep -v '^$' | tr '\n' ' ') \
    \$(grep -v '^#' /tmp/omarchy/omarchy-other.packages | grep -v '^$' | tr '\n' ' ')
"

umount "$OMARCHY_ROOTFS/dev"
umount "$OMARCHY_ROOTFS/sys"
umount "$OMARCHY_ROOTFS/proc"

echo "Building squashfs from $OMARCHY_ROOTFS"
mksquashfs "$OMARCHY_ROOTFS" "$OMARCHY_ROOTFS_ISO" -no-progress -comp gzip -noappend

echo "Assembling ISO with GRUB"
grub-mkrescue --output "$OMARCHY_ISO" "$OMARCHY_ROOTFS_ISO"

echo "Debian Omarchy ISO built at $OMARCHY_ISO"
