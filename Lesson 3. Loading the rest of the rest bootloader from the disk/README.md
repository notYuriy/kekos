# Loading the rest of the bootloader

## run.sh script

We start by adding run.sh script that simplifies running the image. Basically, it makes the image and runs qemu.

## Interaction with disk using BIOS

BIOS provides a set of function for interfacing with disks through ```int 13h``` software interrupt.

There are plenty of functions that are available. To use them, we need to set proper values for ```ah``` register. We will start by determining whether int13h extensions are supported.

Int13h extensions allows us to read from disk using sector numbers. Disk is separated in sectors by 512 bytes. The LBA of the block can be caluculated as block offset on the disk divivded by 512. For example, sector with first stage of the bootloader is located at LBA 0.

Without LBA extensions, we will have to rely on disk geometry or to handle them. For the sake of simplicity, we will only support BIOSes that support LBA disk addressing. This extension is present on almost all computers anyway.

The detection of int13h extensions is done in the following way:

```nasm
; Check the presence of int 0x13 extensions
; Procedure is described here: https://wiki.osdev.org/ATA_in_x86_RealMode_(BIOS)
mov ah, 0x41
mov bx, 0x55aa
; dl register is already set with the value we need
int 13h
jnc lba_disk_read_allowed
; Inform user that extensions are not supported on his computer
mov si, noextmsg
mov cx, noextmsglen
call puts
; Halt CPU
hlt
jmp $
lba_disk_read_allowed:
```

## DAP

To read bytes from the disk, we should first familiarize ourselves with the first structure structure in our journey called DAP. The format of it is as follows

| Field           | Size | Explanation                                                                       |
|-----------------|------|-----------------------------------------------------------------------------------|
| Size of the DAP | 1    | Size of the structure. For this layout, we always set it to 16 bytes              |
| Reserved        | 1    | Should be zero                                                                    |
| Sector count    | 2    | How many sectors should be read from the disk. Some BIOSes only allow values <127 |
| Memory address  | 2    | Memory address where the data from disk should be loaded                          |
| Memory segment  | 2    | Memory segment where the data from disk should be loaded                          |
| Starting LBA    | 8    | LBA of the first sector that should be loaded                                     |

## Unused track

Fdisk won't use the first track for partitions. This space can be used for storing the bootloader program. ```writebootloader.c``` loads everything aside from the first sector to lba 1. In geometry we use, first 64 sectors are remained unused. Hence, we can use up to 63 sectors.

In this tutorial, this space is used for storing second stage of the bootloader. Kernel and some drivers can also be stored if 32k is enough for them, but we will load kernel from FAT32 disk instead.

The DAP for loading unused part of the first track at 0x10000 looks like this

```nasm
; Disk Address Packet (DAP)
align 4 ; DAP needs to be 4 bytes aligned
dap:
.size:  db 16
        db 0
.count: dw 63      ; Load 63 sectors. We have exactly 64 sectors prior to the first partition
; and the first one is bootsector that is already loaded here
.addr:  dw 0x0000  ; Load at physical address 0x10000 (encoded as 0x1000:0x0000)
.seg:   dw 0x1000
.lba:   dq 1       ; Start from the first sector
```

## Using DAP to read from disk

Function ```ah = 42h``` in ```int 13h``` family can be used to load data from the disk with DAP. We need to set ```si``` register to the location of DAP (segment value is taken from ```ds``` register). ```dl``` should be equal to the device drive number we use. ```dl``` is also set to device drive number that was used for loading bootsector. Hence, if we will just keep value of the ```dl``` unchanged (and hence ```dx```), we can avoid worrying about it.

In this case, actual loading of the data can be done with this code

```nasm
; Reading from disk
disk_read:
mov si, dap
mov ah, 42h ; reading with DAP packet function
int 13h
; If carry flag is set, some error happened
jnc disk_read_done

mov si, diskreaderrmsg
mov cx, diskreaderrmsglen
call puts
jmp disk_read
disk_read_done:
```

First, we call function to read from disk. Then, if carry flag is set, we print an error message and trying to read again.


### Homework

As usual, make the whole thing build and run both in your head and on linux =)