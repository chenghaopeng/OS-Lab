; arg
; eax: char

; ret
;

putchar:
    push edx
    push ecx
    push ebx
    push eax

    mov eax, 4
    mov ebx, 1
    mov ecx, esp
    mov edx, 1
    int 80h

    pop eax
    pop ebx
    pop ecx
    pop edx

    ret
