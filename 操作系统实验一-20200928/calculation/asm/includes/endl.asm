; arg
; 

; ret
;

endl:
    push eax
    mov eax, 0Ah
    call putchar
    pop eax
    ret
