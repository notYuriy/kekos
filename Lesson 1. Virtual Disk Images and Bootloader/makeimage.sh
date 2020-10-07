#!/bin/bash

# This script is used to create an FAT32 image with the operating system
# It uses sudo to mount loopback device

# Source: https://wiki.osdev.org/Loopback_Device
# You would need "Hard Disk Images" section

# Start by creating file KekOS.img full of zeros
# Disk size is ~500 Mb (516096 * 1000)
echo "Creating file KekOS.img..."
dd if=/dev/zero of=KekOS.img bs=516096c count=1000 2> /dev/null > /dev/null

# Partitioning disk
# This creates MBR Partition table.
# You can read more on MBR here: https://wiki.osdev.org/MBR
echo "Creating MBR..."

# Here we just invoke commands "o", "n", "a", and "p" by passing them
# to standard input (\n is used to run each command on a new line)
# n command requires 4 parameters, but we are fine with default values
# hence we just insert four \n

# Method of inputing values like this is taken from stack exchange. Link:
# https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script
echo 'Invoking loopdisk device...'
(
echo o # Create a new empty DOS partition table
echo n # Add a new partition
echo   # Partition type (Accept default: primary)
echo 1 # Partition number
echo   # First sector (Accept default)
echo   # Last sector (Accept default)
echo a
echo w # Write changes
) | fdisk -u -C1000 -S63 -H16 KekOS.img > /dev/null

# Mounting loopback device
# This would make "fake" device that will write/read from KekOS.img internally
# 5757 is a number that is rarely used, hence I decided to take it
echo 'Setting up loopback device...'
sudo losetup -o32256 /dev/loop5757 KekOS.img > /dev/null

# Formatting the partition with FAT32 filesystem.
echo 'Formatting the partition to FAT32...'
sudo mkdosfs -F32 /dev/loop5757 > /dev/null

# Mounting it as a directory

# Creating a directory for mount to use
echo 'Creating mountpoint...'
sudo mkdir /mnt/34cf72b97a0bf2fdc4beb2b8aba703f9 > /dev/null

# Mounting our loop device on this directory
echo 'Mounting FAT32 partition with system data...'
sudo mount -tvfat /dev/loop5757 /mnt/34cf72b97a0bf2fdc4beb2b8aba703f9 > /dev/null

# Copying files to the mounted partition
echo 'Copying files from /root directory to mounted partition...'
sudo cp -R root/* /mnt/34cf72b97a0bf2fdc4beb2b8aba703f9 > /dev/null

# Unmounting device
echo 'Unmounting device...'
sudo umount /dev/loop5757 > /dev/null

# Deleting loooback device
echo 'Deleting loopback device...'
sudo losetup -d /dev/loop5757 > /dev/null

# Deleting subdirectory that was used for mount
echo 'Removing mountpoint...'
sudo rm -rf /mnt/34cf72b97a0bf2fdc4beb2b8aba703f9 > /dev/null

# Building bootloader
echo 'Building bootloader...'
cd boot
./makebootloader.sh
cd ..

# Copying bootloader to the image
echo 'Copying bootloader...'
tcc -run writebootloader.c KekOS.img boot/boot.bin

# Cleaning files used for building bootloader
echo 'Cleaning files used to build bootloader...'
cd boot
./cleanbootloader.sh
cd ..

echo 'Done'