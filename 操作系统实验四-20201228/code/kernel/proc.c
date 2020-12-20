
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
		p_proc_ready = proc_table + ready_queue_front();
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
	return 0;
}

/*======================================================================*
                           sys_signal_v
 *======================================================================*/
PUBLIC int sys_signal_v(SEMAPHORE* s)
{
	return 0;
}
