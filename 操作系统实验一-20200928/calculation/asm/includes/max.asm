; arg
; eax: number
; ebx: number

; ret
; eax: maximal number

max:
    cmp eax, ebx
    jl .less
    jmp .finish
.less:
    mov eax, ebx
.finish:
    ret
