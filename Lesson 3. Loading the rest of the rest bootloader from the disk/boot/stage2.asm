bits 16

org 0x10000

mov si, msg
mov cx, msglen
call puts

jmp $

msg: db "Stage 2 running!", 13, 10
msglen: equ $ - msg

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