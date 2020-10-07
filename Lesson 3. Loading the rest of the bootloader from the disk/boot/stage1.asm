bits 16

org 0x7c00

; Setting up stack
cli ; Disable interrupts
xor ax, ax ; Set ax to 0. This is more efficient than mov ax, 0
mov ss, ax ; Set ss to ax. Segment registers can only be updated with
; general purpose registers, so we can't just do mov ss, 0 or xor ss, ss
mov sp, 0x7c00 ; Set stack pointer to 0x7c00
sti ; Enable interrupts

; Set up all other segment registers with zeros
xor ax, ax
mov es, ax
mov ds, ax
mov fs, ax
mov gs, ax

; Printing welcoming message
mov si, msg
mov cx, msglen
call puts

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
; At this point disk reads are allowed

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

; Jumping to the second stage
mov ax, 0x1000
mov es, ax
mov ds, ax
mov fs, ax
mov gs, ax
mov ss, ax
mov sp, 0xffff
jmp 0x1000:0x0000 ; This also updates cs

; Message that is printed on startup
msg: db "Hello, friends!", 13, 10, "Stage 1 running, loading stage 2", 13, 10
msglen: equ $ - msg

; Message that is printed if INT 13h extensions are not supported
noextmsg: db "Disk read error: INT 13h extensions are not supported", 13, 10
noextmsglen: equ $ - noextmsg

; Message that is printed if there is a disk read error
diskreaderrmsg: db "Disk read error: failed to read the first track. Retrying...", 13, 10
diskreaderrmsglen: equ $ - diskreaderrmsg


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


; String address in si
; String size in cx
puts:
    pusha ; Save state of all registers
    ; We won't change this registers, hence we
    ; can set them once in the beginning
    mov ah, 0eh ; Function 0eh, teletype output
    xor bh, bh ; Page number 0
    mov bl, 0x0f ; White color
.looping:
    cmp cx, 0 ; Compare cx to 0
    je .done ; If cx and 0 are equal, jump to the .done label
    mov al, [si] ; Load al with byte at si
    int 10h ; Call BIOS
    inc si ; Increment si
    dec cx ; Decrement cx
    jmp .looping ; Jump at the beginning of the loop
.done:
    popa ; Restore the registers
    ret ; Return from the subroutine

times 510 - ($ - $$) db 0
dw 0xaa55

incbin "boot2.bin"