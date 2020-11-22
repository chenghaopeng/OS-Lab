org 0h
    jmp start

GDT_BEGIN:
SEG_DESC_NULL dd 0x00000000, 0x00000000
SEG_DESC_CODE dd 0x00004000, 0x00409a08 ;代码段0x00080000开始，长度0x04000h
SEG_DESC_VIDEO dd 0x8000ffff, 0x0040920b
SEG_DESC_STACK dd 0x00007b00, 0x00409600
SEG_DESC_DATA dd 0x0000ffff, 0x00409203
GDT_END:
GDT_SIZE equ (GDT_END - GDT_BEGIN) / 4

SLCTR_NULL equ SEG_DESC_NULL - GDT_BEGIN
SLCTR_CODE equ SEG_DESC_CODE - GDT_BEGIN
SLCTR_VIDEO equ SEG_DESC_VIDEO - GDT_BEGIN
SLCTR_STACK equ SEG_DESC_STACK - GDT_BEGIN
SLCTR_DATA equ SEG_DESC_DATA - GDT_BEGIN

GDTR:
GDT_BOUND dw GDT_END - GDT_BEGIN - 1
GDT_BASE dd 0x7000

start:
    ;读取“内核”
    mov ax, 8000h
    mov es, ax
    mov bx, 0
    mov ah, 2
    mov al, 10h
    mov ch, 0
    mov cl, 3
    mov dh, 0
    mov dl, 0
    int 13h

    ;开始跳保护模式
    mov ax, cs
    mov ss, ax
    mov sp, ax
    ;[ds:si]临时GDT
    mov ax, cs
    mov ds, ax
    mov si, GDT_BEGIN
    ;[es:di]目标GDT位置
    mov ax, [cs:GDT_BASE]
    mov dx, [cs:GDT_BASE + 2]
    mov bx, 16
    div bx
    mov es, ax
    mov di, 0
    ;复制GDT到目标位置
    mov cx, GDT_SIZE
    cld
    rep movsd
    ;加载GDT
    lgdt [cs:GDTR]
    ;关中断
    cli
    ;开地址线
    in al, 92h
    or al, 00000010b
    out 92h, al
    ;跳保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp dword SLCTR_CODE:0

times 512-($-$$) db 0
