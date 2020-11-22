%include 'includes/strlen.asm'
%include 'includes/puts.asm'
%include 'includes/exit.asm'
%include 'includes/endl.asm'
%include 'includes/putchar.asm'
%include 'includes/getline.asm'
%include 'includes/memset.asm'
%include 'includes/max.asm'

SECTION .data
message db "Please input several numbers: (length 255 limited, -10^255 < result < 10^255)", 0h

SECTION .bss
input_string: resb 255
pointer: resb 1
num: resb 255
num_len: resb 1
num_flag: resb 1
sum: resb 255
sum_len: resb 1
sum_flag: resb 1
prod: resb 255
prod_len: resb 1
prod_flag: resb 1
tmp: resb 255
tmp_len: resb 1
tmp_flag: resb 1

SECTION .text
global _start

_start:
    mov eax, message
    call puts
    call endl

    mov eax, input_string
    mov ebx, 255
    call getline

    mov byte[pointer], 0
    
    mov eax, sum
    mov ebx, sum_len
    mov ecx, sum_flag
    call clear_number
    
    mov eax, prod
    mov ebx, prod_len
    mov ecx, prod_flag
    call clear_number
    mov byte[prod], 1
.loop:
    mov edx, 0
    call next_number
    mov eax, num
    mov ebx, num_len
    mov ecx, num_flag
    call beautify_number
    ; call print_number
    call my_add
    call my_mul
    cmp edx, 1
    jz .finish
    jmp .loop
.finish:
    mov eax, sum
    mov ebx, sum_len
    mov ecx, sum_flag
    call print_number
    mov eax, prod
    mov ebx, prod_len
    mov ecx, prod_flag
    call print_number

    mov eax, 0
    call exit

; arg
; 
; ret
; edx: EOF?
next_number:
    push eax
    push ebx
    push ecx
    push esi
    mov eax, num
    mov ebx, num_len
    mov ecx, num_flag
    call clear_number
    mov byte[num_len], 0
    mov esi, input_string
    xor eax, eax
    mov al, byte[pointer]
    add esi, eax
    cmp byte[esi], '-'
    jne .loop
    mov byte[num_flag], 1
    inc esi
    inc byte[pointer]
.loop:
    cmp byte[esi], ' '
    jz .reverse
    cmp byte[esi], 0Ah
    jz .eof
    mov al, byte[esi]
    sub al, 48
    xor ebx, ebx
    mov bl, byte[num_len]
    add ebx, num
    mov byte[ebx], al
    inc byte[num_len]
    inc esi
    inc byte[pointer]
    jmp .loop
.eof:
    mov edx, 1
.reverse:
    inc byte[pointer]
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    mov al, byte[num_len]
    mov ebx, num
    mov ecx, num
    add ecx, eax
    dec ecx
    mov esi, 2
    push edx
    xor edx, edx
    idiv esi
.reverse_loop:
    cmp eax, 0
    jz .finish
    xor edx, edx
    mov dl, byte[ebx]
    push edx
    mov dl, byte[ecx]
    mov byte[ebx], dl
    pop edx
    mov byte[ecx], dl
    dec eax
    inc ebx
    dec ecx
    jmp .reverse_loop
.finish:
    pop edx
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret

; arg
; eax: number
; ebx: len
; ecx: flag
clear_number:
    mov byte[ebx], 1
    mov byte[ecx], 0
    push ebx
    push ecx
    mov ebx, 0
    mov ecx, 255
    call memset
    pop ecx
    pop ebx
    ret

; arg
; eax: num
; ebx: len
; ecx: flag
beautify_number:
    push edx
    xor edx, edx
    mov dl, byte[ebx]
.loop:
    push ebx
    xor ebx, ebx
    mov bl, byte[eax+edx-1]
    cmp ebx, 0
    pop ebx
    jne .finish
    dec edx
    cmp edx, 0
    jne .loop
    ; all 0
    mov byte[ecx], 0
    mov edx, 1
.finish:
    mov byte[ebx], dl
    pop edx
    ret

; arg
; eax: num
; ebx: len
; ecx: flag
print_number:
    push eax
    push ecx
    push edx
    ; push eax
    ; mov al, byte[ebx]
    ; add eax, 48
    ; call putchar
    ; pop eax
    ; call endl
    xor edx, edx
    mov dl, byte[ebx]
    add edx, eax
    cmp byte[ecx], 0
    jz .loop
    push eax
    mov eax, '-'
    call putchar
    pop eax
.loop:
    cmp edx, eax
    jz .finish
    dec edx
    xor ecx, ecx
    mov cl, byte[edx]
    add ecx, 48
    push eax
    mov eax, ecx
    call putchar
    pop eax
    jmp .loop
.finish:
    pop edx
    pop ecx
    pop eax
    call endl
    ret

; arg
; sum, num
; ret
; edx
unsigned_compare:
    mov edx, 0
    push eax
    push ebx
    push ecx
    push esi
    xor eax, eax
    xor ebx, ebx
    mov al, byte[sum_len]
    mov bl, byte[num_len]
    cmp eax, ebx
    jz .length_equal
    cmp eax, ebx
    jl .less
    mov edx, 1
    jmp .finish
.less:
    ; mov edx, 0
    jmp .finish
.length_equal:
    mov eax, 0
.loop:
    cmp eax, ebx
    jz .finish
    xor esi, esi
    xor ecx, ecx
    mov cl, byte[sum+ebx-1]
    mov esi, ecx
    mov cl, byte[num+ebx-1]
    dec ebx
    cmp esi, ecx
    jz .loop
    cmp esi, ecx
    jl .finish
    mov edx, 1
.finish:
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret

; ret
; eax: max length
max_length:
    push ebx
    xor eax, eax
    xor ebx, ebx
    mov al, byte[sum_len]
    mov bl, byte[num_len]
    call max
    pop ebx
    ret

unsigned_add:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    call max_length
    mov ecx, eax
    xor eax, eax
    mov ebx, 10
    xor esi, esi
.loop:
    cmp esi, ecx
    jz .carry
    mov al, byte[num+esi]
    add al, byte[sum+esi]
    xor edx, edx
    idiv ebx
    mov byte[sum+esi], dl
    add al, byte[sum+esi+1]
    mov byte[sum+esi+1], al
    inc esi
    jmp .loop
.carry:
    mov al, byte[sum+ecx]
    cmp eax, 0
    jz .continue
    add ecx, 1
.continue:
    mov byte[sum_len], cl
.finish:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

pos_minus:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    xor ecx, ecx
    mov cl, byte[sum_len]
    xor eax, eax
    xor esi, esi
.loop:
    cmp esi, ecx
    jz .continue
    mov al, byte[sum+esi]
    sub al, byte[num+esi]
    cmp al, 0
    jl .borrow
    jmp .borrow_ok
.borrow:
    push eax
    mov al, byte[sum+esi+1]
    sub al, 1
    mov byte[sum+esi+1], al
    pop eax
    add al, 10
.borrow_ok:
    mov byte[sum+esi], al
    inc esi
    jmp .loop
.continue:
    mov eax, sum
    mov ebx, sum_len
    mov ecx, sum_flag
    call beautify_number
.finish:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

neg_minus:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    xor ecx, ecx
    mov cl, byte[num_len]
    xor eax, eax
    xor esi, esi
.loop:
    cmp esi, ecx
    jz .continue
    mov al, byte[sum+esi]
    sub al, byte[num+esi]
    cmp al, 0
    jg .borrow
    jmp .borrow_ok
.borrow:
    push eax
    mov al, byte[sum+esi+1]
    add al, 1
    mov byte[sum+esi+1], al
    pop eax
    sub al, 10
.borrow_ok:
    xor ebx, ebx
    mov bl, al
    mov al, 0
    sub al, bl
    mov byte[sum+esi], al
    inc esi
    jmp .loop
.continue:
    mov al, byte[num_len]
    mov byte[sum_len], al
    mov al, byte[num_flag]
    mov byte[sum_flag], al
    mov eax, sum
    mov ebx, sum_len
    mov ecx, sum_flag
    call beautify_number
.finish:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

my_add:
    push eax
    push ebx
    push edx
    xor eax, eax
    xor ebx, ebx
    mov al, byte[sum_flag]
    mov bl, byte[num_flag]
    cmp eax, ebx
    jne .signed
    call unsigned_add
    jmp .finish
.signed:
    call unsigned_compare
    cmp edx, 0
    jz .neg
    call pos_minus
    jmp .finish
.neg:
    call neg_minus
    jmp .finish
.finish:
    pop edx
    pop ebx
    pop eax
    ret

; my_mul:
;     push eax
;     push ebx
;     push ecx
;     push edx
;     push esi
;     mov eax, tmp
;     mov ebx, tmp_len
;     mov ecx, tmp_flag
;     call clear_number
;     xor eax, eax
;     xor ebx, ebx
;     mov al, byte[prod_flag]
;     mov bl, byte[num_flag]
;     xor eax, ebx
;     mov byte[tmp_flag], al
;     xor ecx, ecx
;     xor edx, edx
;     mov cl, byte[prod_len]
;     mov dl, byte[num_len]
;     add ecx, edx
;     mov byte[tmp_len], cl
;     xor eax, eax
; .for_prod:
;     cmp eax, ecx
;     jz .continue
;     xor ebx, ebx
; .for_num:
;     cmp ebx, edx
;     jz .next_prod
;     push ecx
;     push edx
;     xor ecx, ecx
;     xor edx, edx
;     mov esi, tmp
;     add esi, eax
;     add esi, ebx
;     mov cl, byte[prod+eax]
;     mov dl, byte[num+ebx]
;     push eax
;     mov eax, edx
;     mul ecx
;     mov ecx, eax
;     pop eax
;     xor edx, edx
;     mov dl, byte[esi]
;     add edx, ecx
;     mov byte[esi], dl
;     pop edx
;     pop ecx
;     add ebx, 1
;     jmp .for_num
; .next_prod:
;     add eax, 1
;     jmp .for_prod
; .continue:
;     xor eax, eax
;     xor ebx, ebx
;     xor ecx, ecx
;     xor edx, edx
;     mov esi, 10
;     mov cl, byte[tmp_len]
; .loop:
;     cmp ebx, ecx
;     jz .finish
;     mov al, byte[tmp+ebx]
;     xor edx, edx
;     idiv esi
;     mov byte[tmp+ebx], dl
;     mov dl, byte[tmp+ebx+1]
;     add dl, al
;     mov byte[tmp+ebx+1], dl
;     inc ebx
;     jmp .loop
; .finish:
;     mov eax, tmp
;     mov ebx, tmp_len
;     mov ecx, tmp_flag
;     call beautify_number
;     call copy_result
;     pop esi
;     pop edx
;     pop ecx
;     pop ebx
;     pop eax
;     ret

my_mul:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    mov eax, tmp
    mov ebx, tmp_len
    mov ecx, tmp_flag
    call clear_number
    xor eax, eax
    xor ebx, ebx
    mov al, byte[prod_flag]
    mov bl, byte[num_flag]
    xor eax, ebx
    mov byte[tmp_flag], al
    xor ecx, ecx
    xor edx, edx
    mov cl, byte[prod_len]
    mov dl, byte[num_len]
    add ecx, edx
    mov byte[tmp_len], cl
    xor eax, eax
.for_prod:
    cmp eax, ecx
    jz .continue
    xor ebx, ebx
.for_num:
    cmp ebx, edx
    jz .next_prod
    push ecx
    push edx
    xor ecx, ecx
    xor edx, edx
    mov esi, tmp
    add esi, eax
    add esi, ebx
    mov cl, byte[prod+eax]
    mov dl, byte[num+ebx]
    push eax
    mov eax, edx
    mul ecx
    mov ecx, eax
    pop eax
    xor edx, edx

    push ecx
    push ebx
    push eax
    push esi
    mov ebx, 10
    mov eax, ecx
.carry:
    xor ecx, ecx
    mov cl, byte[esi]
    add eax, ecx
    xor edx, edx
    idiv ebx
    mov byte[esi], dl
    add esi, 1
    cmp eax, 0
    jz .carry_ok
    jmp .carry
.carry_ok:
    pop esi
    pop eax
    pop ebx
    pop ecx

    pop edx
    pop ecx
    add ebx, 1
    jmp .for_num
.next_prod:
    add eax, 1
    jmp .for_prod
.continue:
    mov eax, tmp
    mov ebx, tmp_len
    mov ecx, tmp_flag
    call beautify_number
    call copy_result
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

copy_result:
    push eax
    push ebx
    push ecx

    mov eax, prod
    mov ebx, prod_len
    mov ecx, prod_flag
    call clear_number

    xor eax, eax
    mov al, byte[tmp_flag]
    mov byte[prod_flag], al
    mov al, byte[tmp_len]
    mov byte[prod_len], al
    xor ebx, ebx
.loop:
    cmp ebx, eax
    jz .finish
    mov cl, byte[tmp+ebx]
    mov byte[prod+ebx], cl
    inc ebx
    jmp .loop
.finish:
    pop ecx
    pop ebx
    pop eax
    ret
    