# Writing Hello, world in Real Mode using BIOS functions

## Invoking BIOS functions

In general, almost all IO in real mode can and should be done using BIOS interrupt functions. They all are called in a similar fashion: specific registers are initialized with values we pass as arguments to the bios function, and the call is done using software interrupt ```int <value>``` instruction. For example, here is how white character A can be printed to the screen

```nasm
; Output white character A
mov ah, 0eh ; Set register ah to 0eh 
; This value used to indicate specific function (Teletype output) performed
mov al, 'A' ; Set al to the character we want to write
mov bh, 0 ; Set bh to page number on which we are printing. Just use 0
mov bl, 0x0f ; Set bl to the foreground color. We use 0x0f to print
; white text.
int 10h ; Invoke CPU interrupt 10h (or 16 in decimal). The combination
; of interrupt vector number (in this case 10h) and ah register (0eh)
; is used to identify function that needs to be performed
jmp $ ; We are done, loop forever
```
We set ah, al, bh and bl register to indicate which function we want to perform and what arguments should be passed to the function. Finally, we trigger software interrupt 10h with ```int 10h```. This is one of the interrupt vectors used by BIOS routines.

## Printing strings

There is a special instruction for printing strings, however it doesn't work in teletype mode. This doesn't mean we can't implement function like this ourselves.

### Setting up stack

We start by setting up stack, as we need to call subroutines. For this, we need to change values of SS (Stack segment) and SP (Stack pointer). The first question is where the stack should be located. I chosen the value of 0x7c00, as 0x7c00-0x7e00 are reserved for first 512 bytes that are loaded on startup, and everything from 0x7e00 will be available for us to use.

The code for this portion looks like this:
```nasm
mov ss, ax ; Set ss to ax. Segment registers can only be updated with
; general purpose registers, so we can't just do mov ss, 0 or xor ss, ss
mov sp, 0x7c00 # Set stack pointer to 0x7c00
```
Additionally some machines may have bugs related to updating SP while interrupt flag is on. To deal with that, we disable interrupts using ```cli``` instruction and enable them again with ```sti``` instruction
```nasm
cli ; Disable interrupts
xor ax, ax ; Set ax to 0. This is more efficient than mov ax, 0
mov ss, ax ; Set ss to ax. Segment registers can only be updated with
; general purpose registers, so we can't just do mov ss, 0 or xor ss, ss
mov sp, 0x7c00 # Set stack pointer to 0x7c00
sti ; Enable interrupts
```

### Setting other segment registers

Other segment registers are also present on x86 and should be set. For instance, ```ds``` register is used as a base register when you load value from memory. ```    mov al, [si]``` instruction loads value from ```0x10 * ds + si```.

As such, we need to set all segment registers to proper values, otherwise we may (and probably will) encounter some bugs
```
; Set up all other segment registers with zeros
xor ax, ax
mov es, ax
mov ds, ax
mov fs, ax
mov gs, ax
```

### puts subroutine

Printing strings is done using ```puts``` subroutine. I encourage you to read the code for this subroutine and google all the instructions you don't understand.

## Running in qemu

QEMU is an open-source emulator. It supports emulating x86 architecture. QEMU for x86 can be installed with ```sudo apt install qemu-system-x86``` on debian-based linux systems.

To run code in QEMU, you should create an image and pass it to QEMU as an argument.

```bash
./makeimage.sh
qemu-system-i386 -drive file=KekOS.img,index=0,media=disk,format=raw
```
If you use WSL, graphical window that will pop up won't be supported, as WSL only supports command line apps. As such, we need to pass ```-nographic``` option for QEMU. This will make QEMU display text screen using terminal escapes
```bash
./makeimage.sh
qemu-system-i386 -drive file=KekOS.img,index=0,media=disk,format=raw -nographic
```

## Homework

1. Read all the code and make sure you understand it.
2. Build the whole thing on your system and run it successfully.
3. (*) Implement the function that will print contents of AX register in hexademical form. This would be useful in the future for the debugging purposes.