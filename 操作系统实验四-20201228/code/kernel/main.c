
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            main.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"


/*======================================================================*
                            kernel_main
 *======================================================================*/
PUBLIC int kernel_main()
{
	disp_str("-----\"kernel_main\" begins-----\n");

	TASK*		p_task		= task_table;
	PROCESS*	p_proc		= proc_table;
	char*		p_task_stack	= task_stack + STACK_SIZE_TOTAL;
	u16		selector_ldt	= SELECTOR_LDT_FIRST;
	int i;
	for (i = 0; i < NR_TASKS; i++) {
		strcpy(p_proc->p_name, p_task->name);	// name of the process
		p_proc->pid = i;			// pid

		p_proc->ldt_sel = selector_ldt;

		memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3],
		       sizeof(DESCRIPTOR));
		p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5;
		memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3],
		       sizeof(DESCRIPTOR));
		p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK << 5;
		p_proc->regs.cs	= ((8 * 0) & SA_RPL_MASK & SA_TI_MASK)
			| SA_TIL | RPL_TASK;
		p_proc->regs.ds	= ((8 * 1) & SA_RPL_MASK & SA_TI_MASK)
			| SA_TIL | RPL_TASK;
		p_proc->regs.es	= ((8 * 1) & SA_RPL_MASK & SA_TI_MASK)
			| SA_TIL | RPL_TASK;
		p_proc->regs.fs	= ((8 * 1) & SA_RPL_MASK & SA_TI_MASK)
			| SA_TIL | RPL_TASK;
		p_proc->regs.ss	= ((8 * 1) & SA_RPL_MASK & SA_TI_MASK)
			| SA_TIL | RPL_TASK;
		p_proc->regs.gs	= (SELECTOR_KERNEL_GS & SA_RPL_MASK)
			| RPL_TASK;

		p_proc->regs.eip = (u32)p_task->initial_eip;
		p_proc->regs.esp = (u32)p_task_stack;
		p_proc->regs.eflags = 0x1202; /* IF=1, IOPL=1 */

		p_task_stack -= p_task->stacksize;
		p_proc++;
		p_task++;
		selector_ldt += 1 << 3;
	}

	proc_table[0].priority = 20;
	proc_table[1].priority = 30;
	proc_table[2].priority = 30;
	proc_table[3].priority = 30;
	proc_table[4].priority = 40;
	proc_table[5].priority = 0;

	proc_table[0].ticks = 0;
	proc_table[1].ticks = 0;
	proc_table[2].ticks = 0;
	proc_table[3].ticks = 0;
	proc_table[4].ticks = 0;
	proc_table[5].ticks = 0;

	proc_table[0].color = 0x09;
	proc_table[1].color = 0x0a;
	proc_table[2].color = 0x0b;
	proc_table[3].color = 0x0c;
	proc_table[4].color = 0x0d;
	proc_table[5].color = 0x0f;

	read_lock.value = 1;
	read_lock.size = 0;
	write_lock.value = 1;
	write_lock.size = 0;
	reader_num_lock.value = 3; // 同时读者数量
	reader_num_lock.size = 0;
	writer_num_lock.value = 1;
	writer_num_lock.size = 0;
	queue_lock.value = 1;
	queue_lock.size = 0;
	reader_count = writer_count = 0;

	ready_queue_size = 0;
	for (i = 0; i < NR_TASKS - 1; ++i) {
		ready_queue_push(proc_table[i].pid);
	}

	k_reenter = 0;
	ticks = 0;

	p_proc_ready	= proc_table;

	init_clock();
    init_keyboard();

	disp_pos = 0;
	for (i = 0; i < 80 * 25; ++i) {
		disp_str(" ");
	}
	disp_pos = 0;

	restart();

	while(1){}
}

void read_first_reader () {
	while (1) {
		signal_p(&reader_num_lock);
		signal_p(&read_lock);
		if (!reader_count) signal_p(&write_lock);
		reader_count++;
		if (!p_proc_ready->ticks) p_proc_ready->ticks = p_proc_ready->priority;
		print_task(READ, BEGIN);
		signal_v(&read_lock);

		print_task(READ, ING);
		while (p_proc_ready->ticks);

		signal_p(&read_lock);
		reader_count--;
		if (!reader_count) signal_v(&write_lock);
		print_task(READ, END);
		signal_v(&read_lock);
		signal_v(&reader_num_lock);
		sleep(400);
	}
}

void read_first_writer () {
	while (1) {
		signal_p(&write_lock);
		print_task(WRITE, BEGIN);
		if (!p_proc_ready->ticks) p_proc_ready->ticks = p_proc_ready->priority;
		print_task(WRITE, ING);
		while (p_proc_ready->ticks);
		print_task(WRITE, END);
		signal_v(&write_lock);
	}
}

void write_first_reader () {
	while (1) {
		
	}
}

void write_first_writer () {
	while (1) {
		
	}
}

void F () {
	while (1) {
		clear();
		sleep(20000);
	}
}

void print_task (char* s1, char* s2) {
	disp_color_str(p_proc_ready->p_name, p_proc_ready->color);
	disp_color_str(s1, p_proc_ready->color);
	disp_color_str(s2, p_proc_ready->color);
	disp_color_str(CRLF, p_proc_ready->color);
}
