
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            proto.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "proc.h"

/* klib.asm */
PUBLIC void	out_byte(u16 port, u8 value);
PUBLIC u8	in_byte(u16 port);
PUBLIC void	disp_str(char * info);
PUBLIC void	disp_color_str(char * info, int color);

/* protect.c */
PUBLIC void	init_prot();
PUBLIC u32	seg2phys(u16 seg);

/* klib.c */
PUBLIC void	delay(int time);

/* kernel.asm */
void restart();

/* main.c */
void read_first_reader();
void read_first_writer();
void write_first_reader();
void write_first_writer();
void F();

/* i8259.c */
PUBLIC void put_irq_handler(int irq, irq_handler handler);
PUBLIC void spurious_irq(int irq);

/* clock.c */
PUBLIC void clock_handler(int irq);
PUBLIC void init_clock();

/* keyboard.c */
PUBLIC void init_keyboard();

/* 以下是系统调用相关 */

/* proc.c */
PUBLIC  int     sys_get_ticks();        /* sys_call */
PUBLIC  int     sys_sleep(int);
PUBLIC  int     sys_print(char*);
PUBLIC  int     sys_signal_p(SEMAPHORE*);
PUBLIC  int     sys_signal_v(SEMAPHORE*);
PUBLIC  int     sys_clear();

/* syscall.asm */
PUBLIC  void    sys_call();
PUBLIC  int     get_ticks();
PUBLIC  int     sleep(int);
PUBLIC  int     print(char*);
PUBLIC  int     signal_p(SEMAPHORE*);
PUBLIC  int     signal_v(SEMAPHORE*);
PUBLIC  int     clear();

