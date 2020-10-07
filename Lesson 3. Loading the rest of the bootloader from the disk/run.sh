#!/bin/bash

./makeimage.sh
qemu-system-i386 -drive file=KekOS.img,index=0,media=disk,format=raw