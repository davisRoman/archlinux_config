#!/bin/sh

set -ex

HOST=
USERNAME=
PASSWORD=
HOME_DIR="/home/${USERNAME}"
SWAP_SIZE=4096

echo DISK="$1", HOST="$HOST", USERNAME="$USERNAME", HOME_DIR="$HOME_DIR"

systemctl enable sshd
systemctl enable NetworkManager

mkinitcpio -p linux

mkdir -p /boot/EFI
mount "$EFI_PARTITION" /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

mkdir -p /boot/grub/locale
cp -v /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "$HOST" > /etc/hostname

useradd -m -g users -G wheel "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

ln -f -s /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
hwclock --systohc

echo en_US.UTF-8 UTF-8 > /etc/locale.gen
locale-gen

echo 'root ALL=(ALL) ALL' > /etc/sudoers
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

echo -e 'EDITOR=vim' > /etc/environment

dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_SIZE status=progress
chmod 600 /swapfile
mkswap /swapfile
cp -v /etc/fstab /etc/fstab.bak
echo /swapfile none swap defaults 0 0 >> /etc/fstab

#set terminus-font as default console font
cat << EOF > /etc/vconsole.conf
FONT=ter-p24n
FONT_MAP=8859-2
EOF
