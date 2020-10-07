# Creating a disk image with a bootloader

## Dependencies

We would need the following things for this tutorial

* Linux. If you are running Windows, you would need to install WSL2. Refer to this guide from https://docs.microsoft.com/en-us/windows/wsl/install-win10
* Support for loopback devices. It should be supported by default on plently of linuxes, but everything can happen. WSL2 should support it. Ubuntu and Deepin also don't have any problems with loopback devices
* Sudo access. Using loop devices requires root access
* ```nasm```. On debian/ubuntu can be installed with ```sudo apt install nasm```
* ```tcc```. Tiny C Compiler that supports scripting using C language. Can be installed with ```sudo apt install tcc```
* ```mkdosfs``` and ```fdisk```

## Creating a disk image

The goal is to create a disk image (like .iso ones you use when you download a new OS) that will be used to store all operating system files. In this tutorial, 500 MB fat32 hard drive will be used. 

You would need Linux to run this tutorial. ```makeimage.sh``` is a shell script used to create disk image. ```root``` folder contains all files that should be copied to the root folder of the harddisk. The copy is done recursively, so ```root``` folder may contain folders, subfolders, subsubfolders, etc. 

You can run the following command to verify the image.
```
strings KekOS.img | grep "I am"
```
There is a single file on the disk that starts with these words. The output should be
```
I am just a simple text file. Go do what you are doing.
```

Here is a short explanation of some of the steps in ```makeimage.sh``` (if comments are not enough)

Create file with size 500MB filled with zeros and called KekOS.img
```
dd if=/dev/zero of=KekOS.img bs=516096c count=1000 2> /dev/null > /dev/null
```

Partition disk using fdisk
* Command "o": setup MBR (Master Boot Record, read more about it here: https://wiki.osdev.org/MBR)
* Command "n": make a new partition. We set it to be the first partition on the disk and use (almost) all disk space that is available
* Command "a": Set first partition to be bootable
* Command "w": Write changes
```
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
```

Mounting loopback devices. Read more about "https://en.wikipedia.org/wiki/Loop_device" on wikipedia
```
echo 'Setting up loopback device...'
sudo losetup -o32256 /dev/loop5757 KekOS.img > /dev/null
```

Using FAT32 filesystem as a main filesystem. Again, you can read about it here if you want to: https://en.wikipedia.org/wiki/File_Allocation_Table
```
sudo mkdosfs -F32 /dev/loop5757 > /dev/null
```

## Assembling the bootloader

Bootsector is the first thing that starts on the computer. The code that is used in this tutorial follows
```asm
bits 16

jmp $

times 510 - ($ - $$) db 0
dw 0xaa55
```
```bits 16``` instructs NASM to generate code for 16 bit CPU mode (real mode)

```jmp $``` is a jump instruction. It uses ```$``` as an offset. That means current location. This instruction will jump to itself, emulating ```while(true);``` loop

```times 510 - ($ - $$) db 0``` is used to fill the rest of the bootsector except for two last bytes with zeros. We don't need this space yet but we have to pad it so we can add next two bytes

```dw 0xaa55``` adds MBR signature to the disk

Scripts ```makebootloader.sh``` and ```cleanbootloader.sh``` (in the boot folder) are used to build the bootloader.

```nasm -f bin -o boot.bin stage1.asm``` assembles ```stage1.asm``` with code for the bootloader, storing resulting binary in ```boot.bin```. This file is later referred to as bootloader binary.

## Writing the bootloader to the disk

File ```writebootsector.c``` contains code for the utility that loads bootloader code into memory and writes it to the disk. Source is annotated and I encourage you to read it. We use ```tcc -run``` for running ```writebootsector.c`` without the need to compile it first. The source is annotated and I encourage you to read it.

## Homework

Nothing special yet, just read every file here and make sure that you understand every line of code written and your linux can run makeimage.sh script without any significant problems.

## References

1. https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script
2. https://wiki.osdev.org/Loopback_Device
3. https://wiki.osdev.org/MBR