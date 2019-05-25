#!/bin/bash

set -e

if [ "$1" != "" ]
then
  disk="$1"
else
  disk="/dev/sda"
fi

# Clear
sgdisk -og "$disk"
# Part1: 512M FAT EFI; Part2: Linux
sgdisk -n 1::+512M -t 1:EF00 -n 2:: -t 2:8300 "$disk"
# EFI
PARTITION1="$( lsblk -n -l -p -o NAME,TYPE "$disk" | awk '$2 ~ /part/ {print $1}' | sed -n -e1p)"
mkfs.vfat -F32 "$PARTITION1"
# Linux
PARTITION2="$( lsblk -n -l -p -o NAME,TYPE "$disk" | awk '$2 ~ /part/ {print $1}' | sed -n -e2p)"
mkfs.ext4 -F "$PARTITION2"

# Initial LUKS-Setup
cryptsetup -y -v luksFormat "$PARTITION2"
cryptsetup open "$PARTITION2" cryptroot
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mkdir /mnt/boot
mount "$PARTITION1" /mnt/boot

# Pacstrap
sed -i -e'1iServer = http://ftp-stud.hs-esslingen.de/pub/Mirrors/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
pacstrap /mnt
pacstrap /mnt dhclient

# Install
mkdir -p /mnt/root/install
cp base_install.sh  /mnt/root/install
(echo 'set -e'; echo 'cd /root/install'; echo "./base_install.sh $disk") | arch-chroot /mnt 

# umount
umount /mnt/boot
umount /mnt

