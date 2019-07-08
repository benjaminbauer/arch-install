#!/bin/sh

# enable proxy, prior to downloading this gist in virtualbox behind NTLM proxy
# export http_proxy=http://10.0.2.2:3128
# export https_proxy=http://10.0.2.2:3128
# download this GIST with:
# shorten it with git.io
# curl -L <URL> > arch-install.sh
# then source the file and call the needed functions

partition() {
  # partitioning for EFI system
  ## label as gpt
  parted /dev/sda mklabel gpt
  ## make an EFI system partition (ESP)
  parted /dev/sda mkpart primary fat32 0% 300MiB
  ## make it the boot partition
  parted /dev/sda set 1 boot on
  ## make the main partition fill the remaining disk space
  parted /dev/sda mkpart primary xfs 300MiB 100%

  # format the partitions
  mkfs -t fat /dev/sda1
  mkfs -t xfs /dev/sda2
}

mount_drives() {
  # mount sda2
  mount /dev/sda2 /mnt
  # create /boot on sda2
  mkdir -p /mnt/boot
  # mount esp in /boot, since I boot direclty from an EFI Stub
  mount /dev/sda1 /mnt/boot/
}

unmount_drives() {
  umount /dev/sda1
}

base_install() {
  pacman -Sy --noconfirm reflector
  # take the 20 most recently updated servers and select the 10 fastest as the new mirrorlist
  reflector -c DE -c CH -c AT -l 20 --fastest 10 --save /etc/pacmand.d/mirrorlist

  mount_drives
  # install the base system
  pacstrap /mnt base
  
  # persist the fstab
  genfstab -U -p /mnt > /mnt/etc/fstab
}

setup_systemd-boot() {
  # setup bootloader
  bootctl --path=/boot install
  
  #create entry for bootctl
  cat <<BOOTENTRY > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/sda2 rw
BOOTENTRY
  
  # adjust loader.cong 
  cat <<LOADERCONF > /boot/loader/loader.conf
default  arch
timeout  4
console-mode max
editor   no
LOADERCONF
}

base_setup() {
  # switch into the installed system
  arch-chroot /mnt
  
  if [ -z ${new_hostname+x} ] ; then
    echo "new_hostname is unset"
    echo -n "enter a hostname: "
    read new_hostname
  fi
  
  if [ -z ${new_default_user+x} ] ; then
    echo "new_default_user is unset"
    echo -n "enter the default user: "
    read new_default_user
  fi

  # set time zone
  # is that still needed? ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
  # what about this? # hwclock --systohc
  timedatectl set-timezone Europe/Berlin

  # TODO setup eth0 network interface
  # systemctl enable dhcpcd@eth0.service

  # enable de_DE.UTF-8 UFT8 locale
  sed -i '/de_DE.UTF-8/s/^#//g' /etc/locale.gen
  # enable en_US.UTF-8 UFT8 locale
  sed -i '/en_US.UTF-8/s/^#//g' /etc/locale.gen
  #generate locales
  locale-gen
  #set locale
  localectl set-locale LANG=en_US.UTF-8

  # TODO set keyboard layout to AltGr Intl?
  
  hostnamectl set-hostname $new_hostname
  
  cat <<HOSTSENTRIES > /etc/hosts
127.0.0.1      localhost.localdomain    localhost
::1            ipv6-localhost           ipv6-localhost
HOSTSENTRIES

  # Set the root password:
  passwd

  # create default user
  useradd -m -g users -G wheel -s /bin/zsh $new_default_user
  passwd $new_default_user
  
  # install sudo and zsh (as dependency, so they get "adopted" later by a metapackage)
  pacman -S --nonconfirm --asdeps sudo zsh
  # allow members of wheel to invoke sudo
  sed -i '/wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers
  
  setup_systemd-boot
  
  # leave chroot environment
  exit
}

finish_install() {
  # TODO in case of virtualbox: Change the boot order and unmount arch.iso
  umount_drives
  reboot
}
