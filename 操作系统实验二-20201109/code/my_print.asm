section .text
global my_putchar
global my_print
global my_puts

my_putchar:
    push edx
    push ecx
    push ebx
    push eax
    push ebp
    mov ebp, esp
    mov edx, 1
    lea ecx, [ebp+24]
    mov ebx, 1
    mov eax, 4
    int 80h
    pop ebp
    pop eax
    pop ebx
    pop ecx
    pop edx
    ret

my_print:
    push edx
    push ecx
    push ebx
    push eax
    push ebp
    mov ebp, esp
    mov edx, [ebp+28]
    mov ecx, [ebp+24]
    mov ebx, 1
    mov eax, 4
    int 80h
    pop ebp
    pop eax
    pop ebx
    pop ecx
    pop edx
    ret

my_puts:
    push edx
    push ecx
    push ebx
    push eax
    push ebp
    mov ebp, esp
    mov eax, [ebp+24]
    call strlen
    mov edx, eax
    mov ecx, [ebp+24]
    mov ebx, 1
    mov eax, 4
    int 80h
    pop ebp
    pop eax
    pop ebx
    pop ecx
    pop edx
    ret

strlen:
    push ebx
    mov ebx, eax
.next:
    cmp BYTE[ebx], 0
    jz .finish
    inc ebx
    jmp .next
.finish:
    sub ebx, eax
    mov eax, ebx
    pop ebx
    ret
