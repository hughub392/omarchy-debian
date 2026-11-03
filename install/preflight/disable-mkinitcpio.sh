# Debian does not use mkinitcpio; initramfs-tools handles kernel hooks through
# dpkg maintainer scripts, so there are no pacman hooks to disable on Debian.

echo "mkinitcpio not used on Debian, skipping hook disable."

