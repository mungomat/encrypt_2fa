#!/bin/bash
set -e 

if [ "$1" != "" ]
then
  disk="$1"
else
  disk="/dev/sda"
fi

# Install bootctl
bootctl install

# Add 'encrypt' support to initramfs
sed -i -e"s/\(^HOOKS=([^)]*\)/\0 encrypt/" /etc/mkinitcpio.conf

# Loader.conf
echo "default arch" > /boot/loader/loader.conf
echo "timeout 4" >> /boot/loader/loader.conf

# Arch-entry
PARTITION2="$( lsblk -n -l -p -o NAME,TYPE "$disk" | awk '$2 ~ /part/ {print $1}' | sed -n -e2p)"
UUID="$( lsblk -n -l -p -o TYPE,UUID "$PARTITION2" | awk '$1 ~ /part/ {print $2}' | head -n 1 )"
echo "title Archlinux" > /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
echo "options cryptdevice=UUID=${UUID}:cryptroot root=/dev/mapper/cryptroot rw" >> /boot/loader/entries/arch.conf

# Make initrams
mkinitcpio -p linux
