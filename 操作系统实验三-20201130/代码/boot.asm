org 07c00h
    mov ax, 9000h
    mov es, ax
    mov bx, 0
    mov ah, 2
    mov al, 1h
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    int 13h
    jmp 9000h:0h
times 510-($-$$) db 0
dw 0xaa55
