# make sure the system time is correct
# TODO understand what this does
# timedatectl set-ntp true

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

# mount sda2
mount /dev/sda2 /mnt
# create /boot on sda2
mkdir /mnt/boot
# mount esp in /boot, since I boot direclty from an EFI Stub
mount /dev/sda1 /mnt/boot/

# TODO: select a good mirror before installing

# install the base system
pacstrap /mnt base

# persist the fstab
genfstab -U -p /mnt > /mnt/etc/fstab

# switch into the installed system
arch-chroot /mnt

# set time zone
#TODO use timedatectl set-timezone Asia/Shanghai instead?
# ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# TODO setup eth0 network interface
# systemctl enable dhcpcd@eth0.service

# TODO understand what this does
# hwclock --systohc

# TODO Uncomment en_US.UTF-8 UTF-8 and other needed locales in /etc/locale.gen, and generate them with:
# locale-gen

# TODO set keyboard layout
# /etc/vconsole.conf
# KEYMAP=de-latin1

# TODO create hostname, use hostnamectl instead?
# /etc/hostname

# TODO Add matching entries to hosts(5):

# /etc/hosts
# 127.0.0.1       localhost
# ::1             localhost
# 127.0.1.1       myhostname.localdomain  myhostname

# TODO Set the root password:
# passwd

# TODO create my user
# TODO install zsh
# useradd -m -g users -G wheel -s /bin/zsh $USERNAME
# passwd $USERNAME
# TODO install sudo
pacman -S sudo
# TODO allow wheel to sudo


# TODO setup systemd-boot
# bootctl --path=/boot install

# TODO reboot
# TODO in case of virtualbox: Change the boot order and unmount arch.iso
# exit
# umount /dev/sda1
# reboot
