/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 对于需要错误代码的异常使用 TRAPHANDLER
 */

#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 不需要错误代码的使用 TRAPHANDLER_NOEC
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(Trap_DIVIDE,0)
TRAPHANDLER_NOEC(Trap_DEBUG,1)
TRAPHANDLER_NOEC(Trap_NMI,2)
TRAPHANDLER_NOEC(Trap_BRKPT,3)
TRAPHANDLER_NOEC(Trap_OFLOW,4)
TRAPHANDLER_NOEC(Trap_BOUND,5)
TRAPHANDLER_NOEC(Trap_ILLOP,6)
TRAPHANDLER_NOEC(Trap_DEVICE,7)
TRAPHANDLER(Trap_DBLFLT,8)
TRAPHANDLER_NOEC(Trap_COPROC,9)
TRAPHANDLER(Trap_TSS,10)
TRAPHANDLER(Trap_SEGNP,11)
TRAPHANDLER(Trap_STACK,12)
TRAPHANDLER(Trap_GPFLT,13)
TRAPHANDLER(Trap_PGFLT,14)
TRAPHANDLER(Trap_RES,15)
TRAPHANDLER_NOEC(Trap_FPERR,16)

TRAPHANDLER_NOEC(Trap_syscall,48)



/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
	pushl %es  	// 对照Trapframe，在TRAPHANDLER中以及push了 tf_trapno，所以还需要push tf_es和tf_ds
	pushal      // push所有通用寄存器，对应Trapframe的struct PushRegs tf_regs;
	movl $GD_KD,%eax
	movl %eax,%ds
	movl %eax,%es
	pushl %esp
	call trap
