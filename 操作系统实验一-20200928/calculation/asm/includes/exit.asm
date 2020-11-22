; arg
; eax: exit code

; ret

exit:
    mov ebx, eax
    mov eax, 1
    int 80h
    ret
