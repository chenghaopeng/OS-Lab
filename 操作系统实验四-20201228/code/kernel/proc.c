
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                               proc.c
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
                              schedule
 *======================================================================*/
PUBLIC void schedule()
{
	int i;
	PROCESS* p;
	for (i = 0; i < NR_TASKS; ++i) {
		p = proc_table + i;
		if (p->sleep_duration > 0 && milli_diff(p->sleep_start) >= p->sleep_duration) {
			p->sleep_duration = 0;
			if (i != NR_TASKS - 1) {
				ready_queue_push(i);
			}
		}
	}
	p = proc_table + NR_TASKS - 1;
	if (p->sleep_duration > 0 && ready_queue_size > 0) {
		int x = ready_queue_front();
		ready_queue_pop();
		ready_queue_push(x);
		p_proc_ready = proc_table + x;
	}
	else {
		p_proc_ready = p;
	}
}

/*======================================================================*
                           sys_get_ticks
 *======================================================================*/
PUBLIC int sys_get_ticks()
{
	return ticks;
}

/*======================================================================*
                           sys_sleep
 *======================================================================*/
PUBLIC int sys_sleep(int milli_seconds)
{
	p_proc_ready->sleep_start = sys_get_ticks();
	p_proc_ready->sleep_duration = milli_seconds;
	int i = p_proc_ready->pid;
	if (i == NR_TASKS - 1) return 0;
	ready_queue_find_remove(i);
	schedule();
	return 0;
}

/*======================================================================*
                           sys_print
 *======================================================================*/
PUBLIC int sys_print(char* str)
{
	disp_str(str);
	return 0;
}

/*======================================================================*
                           sys_signal_p
 *======================================================================*/
PUBLIC int sys_signal_p(SEMAPHORE* s)
{
	// disp_str(p_proc_ready->p_name);
	// disp_int(s->value);
	if ((--s->value) >= 0) return 0;
	ready_queue_find_remove(p_proc_ready->pid);
	s->queue[s->size++] = p_proc_ready->pid;
	schedule();
	return 0;
}

/*======================================================================*
                           sys_signal_v
 *======================================================================*/
PUBLIC int sys_signal_v(SEMAPHORE* s)
{
	if ((++s->value) > 0 || s->size == 0) return 0;
	ready_queue_push(s->queue[0]);
	int i;
	for (i = 0; i < s->size - 1; ++i) {
		s->queue[i] = s->queue[i + 1];
	}
	s->size--;
	schedule();
	return 0;
}

/*======================================================================*
                           sys_clear
 *======================================================================*/
PUBLIC int sys_clear(SEMAPHORE* s)
{
	disp_pos = 0;
	int i;
	for (i = 0; i < 80 * 25; ++i) {
		disp_str(WHITESPACE);
	}
	disp_pos = 0;
	int cnt = 0, x = -1;
	PROCESS* p;
	for (p = proc_table; p < proc_table + NR_TASKS - 1; ++p) {
		if (p->ticks) {
			cnt++;
			if (x < 0) {
				x = p - proc_table;
			}
		}
	}
	if (x < 3) print_task(READ, NUM[cnt]);
	else print_task(WRITE, NUM[cnt]);
	return 0;
}
