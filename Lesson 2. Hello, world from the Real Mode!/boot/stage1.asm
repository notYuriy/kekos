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

mov si, msg
mov cx, msglen
call puts
jmp $


msg: db "Hello, World from the Real mode!"
msglen: equ $ - msg

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