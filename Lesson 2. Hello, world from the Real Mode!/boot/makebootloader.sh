#!/bin/bash

echo 'Invoking nasm...'
nasm -f bin -o boot.bin stage1.asm