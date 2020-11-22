; arg
; eax: string

; ret
;

puts:
    push edx
    push ecx
    push ebx
    push eax

    mov ecx, eax
    call strlen
    mov edx, eax
    mov ebx, 1
    mov eax, 4
    int 80h

    pop eax
    pop ebx
    pop ecx
    pop edx
    ret
