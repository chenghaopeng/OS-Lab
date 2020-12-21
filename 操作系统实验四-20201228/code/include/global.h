
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            global.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* EXTERN is defined as extern except in global.c */
#ifdef	GLOBAL_VARIABLES_HERE
#undef	EXTERN
#define	EXTERN
#endif

EXTERN	int		ticks;

EXTERN	int		disp_pos;
EXTERN	u8		gdt_ptr[6];	// 0~15:Limit  16~47:Base
EXTERN	DESCRIPTOR	gdt[GDT_SIZE];
EXTERN	u8		idt_ptr[6];	// 0~15:Limit  16~47:Base
EXTERN	GATE		idt[IDT_SIZE];

EXTERN	u32		k_reenter;

EXTERN	TSS		tss;
EXTERN	PROCESS*	p_proc_ready;

extern	PROCESS		proc_table[];
extern	char		task_stack[];
extern  TASK            task_table[];
extern	irq_handler	irq_table[];

extern int ready_queue[];
extern int ready_queue_size;
extern void ready_queue_push(int);
extern void ready_queue_pop();
extern void ready_queue_remove(int);
extern int ready_queue_find(int);
extern void ready_queue_find_remove(int);
extern int ready_queue_front();

extern SEMAPHORE read_lock;
extern SEMAPHORE reader_num_lock;
extern SEMAPHORE write_lock;
extern SEMAPHORE writer_num_lock;
extern SEMAPHORE queue_lock;
extern int reader_count;
extern int writer_count;

extern char READ[];
extern char WRITE[];
extern char BEGIN[];
extern char ING[];
extern char END[];
extern char CRLF[];
