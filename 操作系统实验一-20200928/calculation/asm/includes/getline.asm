; arg
; eax: address
; ebx: length

; ret
;

getline:
    push edx
    push ecx
    push ebx
    push eax

    mov edx, ebx
    mov ecx, eax
    mov ebx, 1
    mov eax, 3
    int 80h

    pop eax
    pop ebx
    pop ecx
    pop edx

    ret
