#!/bin/bash

echo 'Invoking nasm...'
nasm -f bin -o boot2.bin stage2.asm
nasm -f bin -o boot.bin stage1.asm