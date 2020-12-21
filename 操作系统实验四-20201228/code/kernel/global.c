
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            global.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#define GLOBAL_VARIABLES_HERE

#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "proc.h"
#include "global.h"


PUBLIC	PROCESS			proc_table[NR_TASKS];

PUBLIC	char			task_stack[STACK_SIZE_TOTAL];

PUBLIC	TASK	task_table[NR_TASKS] = {
                    {read_first_reader, STACK_SIZE_TESTA, "A"},
					{read_first_reader, STACK_SIZE_TESTB, "B"},
					{read_first_reader, STACK_SIZE_TESTC, "C"},
                    {read_first_writer, STACK_SIZE_TESTD, "D"},
					{read_first_writer, STACK_SIZE_TESTE, "E"},
					{F, STACK_SIZE_TESTF, "F"}
                };

PUBLIC	irq_handler		irq_table[NR_IRQ];

PUBLIC	system_call		sys_call_table[NR_SYS_CALL] = {sys_get_ticks, sys_sleep, sys_print, sys_signal_p, sys_signal_v};

PUBLIC int ready_queue[NR_TASKS];
PUBLIC int ready_queue_size;
PUBLIC void ready_queue_push(int x) {
    ready_queue[ready_queue_size++] = x;
}
PUBLIC void ready_queue_pop() {
    if (ready_queue_size > 0) {
        ready_queue_remove(0);
    }
}
PUBLIC void ready_queue_remove(int x) {
    if (x < 0 || x >= ready_queue_size) return;
    for (; x < ready_queue_size - 1; ++x) {
        ready_queue[x] = ready_queue[x + 1];
    }
    ready_queue_size--;
}
PUBLIC int ready_queue_find(int x) {
    int i;
    for (i = 0; i < ready_queue_size; ++i) {
        if (x == ready_queue[i]) {
            return i;
        }
    }
    return -1;
}
PUBLIC void ready_queue_find_remove(int x) {
    ready_queue_remove(ready_queue_find(x));
}
PUBLIC int ready_queue_front() {
    return ready_queue[0];
}

PUBLIC SEMAPHORE read_lock;
PUBLIC SEMAPHORE reader_num_lock;
PUBLIC SEMAPHORE write_lock;
PUBLIC SEMAPHORE writer_num_lock;
PUBLIC SEMAPHORE queue_lock;
PUBLIC int reader_count;
PUBLIC int writer_count;

PUBLIC char READ[] = " read ";
PUBLIC char WRITE[] = " write";
PUBLIC char BEGIN[] = " begin";
PUBLIC char ING[] = " ing  ";
PUBLIC char END[] = " end  ";
PUBLIC char CRLF[] = "\n";
