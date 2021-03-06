#!/bin/bash

set -eo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

setfont iso02-12x22

DISK="/dev/sda"
export EFI_PARTITION="${DISK}1"
export ROOT_PARTITION="${DISK}2"
export HOME_PARTITION="${DISK}3"

umount $EFI_PARTITION || true
umount $HOME_PARTITION || true
umount $ROOT_PARTITION || true

parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "EFI"    fat32 1MiB   500MiB
parted -s "$DISK" mkpart "SYSTEM" ext4  500MiB 50GiB
parted -s "$DISK" mkpart "HOME"   ext4  50GiB  100%
parted -s "$DISK" set 1 esp  on
parted -s "$DISK" set 1 boot on

mkfs.fat  -F32 "$EFI_PARTITION"
mkfs.ext4 -F   "$ROOT_PARTITION"
mkfs.ext4 -F   "$HOME_PARTITION"


echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch'   > /etc/pacman.d/mirrorlist
echo 'Server = http://mirrors.rutgers.edu/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

pacman -Syy

mount "$ROOT_PARTITION" /mnt

cp -v einstein.jpg /mnt/home/davis/pictures

mkdir -p /mnt/home
mount "$HOME_PARTITION" /mnt/home

mkdir -p /mnt/etc
genfstab -U -p /mnt > /mnt/etc/fstab

pacstrap /mnt base \
              linux \
              linux-headers \
              grub \
              sudo \
              wget \
              vim \
              openssh \
              base-devel \
              networkmanager \
              wpa_supplicant \
              wireless_tools \
              netctl \
              dialog \
              efibootmgr \
              dosfstools \
              os-prober \
              mtools \
              intel-ucode \
              xorg-server \
              xorg-xinit \
              nvidia \
              nvidia-utils \
              terminus-font \
              git\
              tmux \
              the_silver_searcher \
              bat \
              tig \
              tree \
	      powerline-fonts \
	      termite \
              zsh \
	      i3 \
	      firefox \
	      feh


cp -v ./chroot.sh /mnt
arch-chroot /mnt ./chroot.sh "$DISK"
rm /mnt/chroot.sh

umount -R /mnt
poweroff
