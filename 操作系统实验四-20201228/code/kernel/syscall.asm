
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                               syscall.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                     Forrest Yu, 2005
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%include "sconst.inc"

_NR_get_ticks       equ 0 ; 要跟 global.c 中 sys_call_table 的定义相对应！
_NR_sleep           equ 1
_NR_print           equ 2
_NR_signal_p        equ 3
_NR_signal_v        equ 4

INT_VECTOR_SYS_CALL equ 0x90

; 导出符号
global	get_ticks
global	sleep
global	print
global	signal_p
global	signal_v

bits 32
[section .text]

; ====================================================================
;                              get_ticks
; ====================================================================
get_ticks:
	mov	eax, _NR_get_ticks
	int	INT_VECTOR_SYS_CALL
	ret

; ====================================================================
;                              sleep
; ====================================================================
sleep:
	mov ebx, [esp + 4]
	mov	eax, _NR_sleep
	int	INT_VECTOR_SYS_CALL
	ret

; ====================================================================
;                              print
; ====================================================================
print:
	mov ebx, [esp + 4]
	mov	eax, _NR_print
	int	INT_VECTOR_SYS_CALL
	ret

; ====================================================================
;                              signal_p
; ====================================================================
signal_p:
	mov ebx, [esp + 4]
	mov	eax, _NR_signal_p
	int	INT_VECTOR_SYS_CALL
	ret

; ====================================================================
;                              signal_v
; ====================================================================
signal_v:
	mov ebx, [esp + 4]
	mov	eax, _NR_signal_v
	int	INT_VECTOR_SYS_CALL
	ret

