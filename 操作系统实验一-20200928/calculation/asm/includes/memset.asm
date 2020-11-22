; arg
; eax: address
; ebx: byte
; ecx: length

; ret
;

memset:
    push eax
    push ebx
    push ecx
.loop:
    cmp ecx, 0
    jz .finish
    mov BYTE[eax+ecx-1], bl
    dec ecx
    jmp .loop
.finish:
    pop ecx
    pop ebx
    pop eax
    ret
