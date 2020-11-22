jmp start

SLCTR_NULL equ 0h
SLCTR_CODE equ 8h
SLCTR_VIDEO equ 10h
SLCTR_STACK equ 18h
SLCTR_DATA equ 20h

KEY_ESC equ 1bh
KEY_BACKSPACE equ 08h
KEY_SHIFT equ 10h
KEY_SHIFT_UP equ 11h
KEY_CAPSLOCK equ 14h
KEY_CTRL equ 12h
KEY_CTRL_UP equ 13h

KEY_TAB equ 09h
KEY_ENTER equ 0dh

keyboard_map db 0h, KEY_ESC, "1234567890-=", KEY_BACKSPACE, KEY_TAB, "qwertyuiop[]", KEY_ENTER, KEY_CTRL, "asdfghjkl;'`", KEY_SHIFT, "\zxcvbnm,./", KEY_SHIFT, "*", 0h, " ", KEY_CAPSLOCK, 0h

[bits 32]
clock_int:
    pushad
    mov al, 0x20
    out 0xa0, al
    out 0x20, al
    popad
    call clock
    iret

keyboard_int:
    pushad
    cli
    mov al, 0x20
    out 0xa0, al
    out 0x20, al
    mov al, 0xad
    out 0x64, al
    xor eax, eax
    in al, 0x64
    test al, 0x01
    jz .end
    in al, 0x60
    call got_key
    call display
.end:
    mov al, 0xae
    out 0x64, al
    sti
    popad
    iret

start:
    mov edx, SLCTR_VIDEO
    mov ds, edx
    mov edx, SLCTR_DATA
    mov es, edx
    mov edx, 0
    call set_len
    call set_shift
    call set_capslock
    call set_esc
    call set_esc_point
    call set_tmp
    call set_ctrl
    call set_history_len
    call set_time_tick
    call clear
    call init_int
.tail:
    jmp $

init_int:
    pushf
    push eax
    cli
    mov al, 11111100b
    out 0x21, al
    mov al, 11111111b
    out 0xa1, al
    pop eax
    popf
    sti
    ret

clock:
    pushad
    call get_time_tick
    inc edx
    call set_time_tick
    cmp edx, 7000
    jl .finish
    call get_esc
    cmp edx, 0
    jnz .finish
    mov edx, 0
    call set_time_tick
    call set_len
    call set_history_len
    call display
.finish:
    popad
    ret

got_key:
    pushad
    cmp eax, 0xaa
    jz .shift_up
    cmp eax, 0xb6
    jz .shift_up
    cmp eax, 0x9d
    jz .ctrl_up
    cmp eax, 0x3a
    jg .finish
    mov ebx, keyboard_map
    mov cl, byte [cs:ebx+eax]
    xor eax, eax
    mov al, cl
    cmp eax, 0
    jz .finish
    cmp eax, 20h
    jl .control
    call got_char
    jmp .finish
.shift_up:
    mov eax, KEY_SHIFT_UP
    jmp .control
.ctrl_up:
    mov eax, KEY_CTRL_UP
    jmp .control
.control:
    call got_control
.finish:
    popad
    ret

got_char:
    pushad
    call get_esc
    cmp edx, 2
    jz .finish
    call get_ctrl
    cmp edx, 0
    jz .not_ctrl
    call get_esc
    cmp edx, 0
    jnz .finish
    cmp eax, 'z'
    jnz .finish
    call undo
    jmp .finish
.not_ctrl:
    cmp eax, 'a'
    jl .continue
    cmp eax, 'z'
    jg .continue
    call get_capslock
    mov ebx, edx
    call get_shift
    xor ebx, edx
    cmp ebx, 0
    jz .continue
    sub al, 20h
.continue:
    call get_len
    mov byte [es:edx], al
    inc edx
    call set_len
    call get_esc
    cmp edx, 0
    jnz .finish
    mov ah, al
    mov al, 0
    call dodo
.finish:
    popad
    ret

got_control:
    pushad
    cmp eax, KEY_ESC
    jz .kesc
    cmp eax, KEY_BACKSPACE
    jz .backspace
    cmp eax, KEY_SHIFT
    jz .shift
    cmp eax, KEY_SHIFT_UP
    jz .shift_up
    cmp eax, KEY_CAPSLOCK
    jz .capslock
    cmp eax, KEY_TAB
    jz .tab
    cmp eax, KEY_ENTER
    jz .kenter
    cmp eax, KEY_CTRL
    jz .ctrl
    cmp eax, KEY_CTRL_UP
    jz .ctrl_up
.kesc:
    call get_esc
    cmp edx, 1
    jg .kesc_finish
    jz .kesc_find
.kesc_input:
    mov edx, 1
    call set_esc
    call get_len
    call set_esc_point
    jmp .finish
.kesc_find:
    ; mov edx, 2
    ; call set_esc
    jmp .finish
.kesc_finish:
    mov edx, 0
    call set_esc
    call get_esc_point
    call set_len
    jmp .finish
.backspace:
    call get_esc
    cmp edx, 1
    jz .backspace_esc_input
    jg .finish
    call get_len
    cmp edx, 0
    jz .finish
    dec edx
    mov al, 1
    mov ah, byte [es:edx]
    call dodo
    call set_len
    jmp .finish
.backspace_esc_input:
    call get_esc_point
    mov ebx, edx
    call get_len
    cmp edx, ebx
    jz .finish
    dec edx
    call set_len
    jmp .finish
.shift:
    mov edx, 1
    call set_shift
    jmp .finish
.shift_up:
    mov edx, 0
    call set_shift
    jmp .finish
.capslock:
    call get_capslock
    xor edx, 1
    call set_capslock
    jmp .finish
.tab:
    call got_char
    jmp .finish
.kenter:
    call get_esc
    cmp edx, 1
    jg .finish
    jz .enter_esc_input
    call got_char
    jmp .finish
.enter_esc_input:
    mov edx, 2
    call set_esc
    jmp .finish
.ctrl:
    mov edx, 1
    call set_ctrl
    jmp .finish
.ctrl_up:
    mov edx, 0
    call set_ctrl
    jmp .finish
.finish:
    popad
    ret

dodo:
    pushad
    call get_history_len
    inc edx
    call set_history_len
    push eax
    mov eax, edx
    mov edx, 2
    mul edx
    mov edx, 0xffff
    sub edx, 0x100
    sub edx, eax
    pop eax
    mov word [es:edx], ax
    call display
    popad
    ret

undo:
    pushad
    call get_history_len
    cmp edx, 0
    jz .finish
    mov eax, edx
    mov edx, 2
    mul edx
    mov edx, 0xffff
    sub edx, 0x100
    sub edx, eax
    xor eax, eax
    mov ax, word [es:edx]
    call get_history_len
    dec edx
    call set_history_len
    cmp al, 0
    jz .append
.delete:
    call get_len
    mov byte [es:edx], ah
    inc edx
    call set_len
    jmp .finish
.append:
    call get_len
    dec edx
    call set_len
    jmp .finish
.finish:
    call display
    popad
    ret

get_len:
    push eax
    mov eax, 0xffff
    sub eax, 4h
    mov edx, dword [es:eax]
    pop eax
    ret

set_len:
    push eax
    mov eax, 0xffff
    sub eax, 4h
    mov dword [es:eax], edx
    pop eax
    ret

get_shift:
    push eax
    mov eax, 0xffff
    sub eax, 8h
    mov edx, dword [es:eax]
    pop eax
    ret

set_shift:
    push eax
    mov eax, 0xffff
    sub eax, 8h
    mov dword [es:eax], edx
    pop eax
    ret

get_capslock:
    push eax
    mov eax, 0xffff
    sub eax, 0xc
    mov edx, dword [es:eax]
    pop eax
    ret

set_capslock:
    push eax
    mov eax, 0xffff
    sub eax, 0xc
    mov dword [es:eax], edx
    pop eax
    ret

get_esc:
    push eax
    mov eax, 0xffff
    sub eax, 0x10
    mov edx, dword [es:eax]
    pop eax
    ret

set_esc:
    push eax
    mov eax, 0xffff
    sub eax, 0x10
    mov dword [es:eax], edx
    pop eax
    ret

get_esc_point:
    push eax
    mov eax, 0xffff
    sub eax, 0x14
    mov edx, dword [es:eax]
    pop eax
    ret

set_esc_point:
    push eax
    mov eax, 0xffff
    sub eax, 0x14
    mov dword [es:eax], edx
    pop eax
    ret

get_tmp:
    push eax
    mov eax, 0xffff
    sub eax, 0x18
    mov edx, dword [es:eax]
    pop eax
    ret

set_tmp:
    push eax
    mov eax, 0xffff
    sub eax, 0x18
    mov dword [es:eax], edx
    pop eax
    ret

get_ctrl:
    push eax
    mov eax, 0xffff
    sub eax, 0x1c
    mov edx, dword [es:eax]
    pop eax
    ret

set_ctrl:
    push eax
    mov eax, 0xffff
    sub eax, 0x1c
    mov dword [es:eax], edx
    pop eax
    ret

get_history_len:
    push eax
    mov eax, 0xffff
    sub eax, 0x20
    mov edx, dword [es:eax]
    pop eax
    ret

set_history_len:
    push eax
    mov eax, 0xffff
    sub eax, 0x20
    mov dword [es:eax], edx
    pop eax
    ret

get_time_tick:
    push eax
    mov eax, 0xffff
    sub eax, 0x24
    mov edx, dword [es:eax]
    pop eax
    ret

set_time_tick:
    push eax
    mov eax, 0xffff
    sub eax, 0x24
    mov dword [es:eax], edx
    pop eax
    ret

clear:
    pushad
    mov ecx, 0f20h
    mov eax, 0
.loop_1:
    cmp eax, 25
    jz .finish_1
    mov ebx, 0
.loop_2:
    cmp ebx, 80
    jz .finish_2
    call disp_char_ij
    inc ebx
    jmp .loop_2
.finish_2:
    inc eax
    jmp .loop_1
.finish_1:
    mov eax, 0
    call move_cursor
    popad
    ret

is_match:
    pushad
    call get_tmp
    cmp edx, 0
    jg .finish
    mov eax, ebx
    call get_esc_point
    sub edx, ebx
    mov ebx, edx ; ebx 左边的长度
    call get_len
    mov ecx, edx
    call get_esc_point
    sub ecx, edx ; ecx 右边的长度
    cmp ebx, ecx
    jl .finish
    call get_esc_point
    mov ebx, edx
    call get_len
.loop:
    cmp ebx, edx
    jz .found
    mov cl, byte [es:eax]
    mov ch, byte [es:ebx]
    cmp cl, ch
    jnz .finish
    inc eax
    inc ebx
    jmp .loop
.found:
    call get_len
    mov ecx, edx
    call get_esc_point
    sub ecx, edx
    mov edx, ecx
    call set_tmp
.finish:
    popad
    ret

display:
    pushad
    mov eax, 0
    call get_len
    mov ebx, edx
    mov edx, 0
.loop:
    cmp edx, ebx
    jz .finish
    cmp eax, 2000
    jge .finish
    xor ecx, ecx
    ;搞颜色
    push edx
    push ebx
    push eax
    mov ebx, edx
    call get_esc
    cmp edx, 1
    jl .white
    jz .tailred
    jg .findred
.tailred:
    call get_esc_point
    cmp ebx, edx
    jl .white
    jmp .red
.findred:
    call get_esc_point
    cmp ebx, edx
    jge .red
    call is_match
    call get_tmp
    cmp edx, 0
    jg .found_red
    jmp .white
.found_red:
    dec edx
    call set_tmp
    jmp .red
.white:
    mov ch, 07h
    jmp .color_finish
.red:
    mov ch, 0ch
    jmp .color_finish
.color_finish:
    pop eax
    pop ebx
    pop edx
    ;结束搞颜色
    mov cl, byte [es:edx]
    cmp cl, KEY_TAB
    jz .tab
    cmp cl, KEY_ENTER
    jz .enter
    call disp_char_x
    inc eax
    jmp .next
.tab:
    mov ch, 07h
    mov cl, 20h
    call disp_char_x
    inc eax
    cmp eax, 2000
    jge .finish
    call disp_char_x
    inc eax
    cmp eax, 2000
    jge .finish
    call disp_char_x
    inc eax
    cmp eax, 2000
    jge .finish
    call disp_char_x
    inc eax
    jmp .next
.enter:
    mov ch, 07h
    mov cl, 20h
    push eax
    push ebx
    push edx
    mov ebx, 80
    xor edx, edx
    idiv ebx
    cmp edx, 0
    pop edx
    pop ebx
    pop eax
    jnz .enter_loop
    call disp_char_x
    inc eax
    cmp eax, 2000
    jge .finish
.enter_loop:
    push eax
    push ebx
    push edx
    mov ebx, 80
    xor edx, edx
    idiv ebx
    cmp edx, 0
    pop edx
    pop ebx
    pop eax
    jz .next
    call disp_char_x
    inc eax
    cmp eax, 2000
    jge .finish
    jmp .enter_loop
.next:
    inc edx
    jmp .loop
.finish:
    call move_cursor
    mov ch, 07h
    mov cl, 20h
.clear:
    cmp eax, 2000
    jz .ok
    call disp_char_x
    inc eax
    jmp .clear
.ok:
    popad
    ret

move_cursor:
    pushad
    mov ebx, eax
    mov al, 0eh
    mov edx, 0x3d4
    out dx, al
    mov al, bh
    mov edx, 0x3d5
    out dx, al
    nop
    nop
    mov al, 0fh
    mov edx, 0x3d4
    out dx, al
    mov al, bl
    mov edx, 0x3d5
    out dx, al
    nop
    nop
    popad
    ret

disp_char_ij:
    push eax
    push ebx
    push ecx
    push edi
    mov edi, 80
    mul edi
    add eax, ebx
    shl eax, 1
    mov [ds:eax], cx
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret

disp_char_x:
    push eax
    push ebx
    push edx
    mov ebx, 80
    xor edx, edx
    idiv ebx
    mov ebx, edx
    call disp_char_ij
    pop edx
    pop ebx
    pop eax
    ret

times 8192-($-$$) db 0
