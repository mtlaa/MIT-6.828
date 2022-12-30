# 练习1
> **练习1** 修改 `kern/pmap.c` 中的 `mem_init()` 以分配和映射 `envs` 数组。该数组由`NENV` 个 `Env` 结构的实例组成，就像您分配 `pages` 数组的方式一样。与 `pages` 数组一样，内存支持环境也应该在 `UENVS`（在 `inc/memlayout.h` 中定义）以用户只读方式映射，以便用户进程可以从该数组中读取。

```c
    // 分配数组
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here. *****************************************
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
	memset(envs, 0, NENV * sizeof(struct Env));

    // 进行映射
    //////////////////////////////////////////////////////////////////////
	// Map the 'envs' array read-only by the user at linear address UENVS
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.  *******************************
	boot_map_region(kern_pgdir, UENVS, NENV * sizeof(struct Env), PADDR(envs), PTE_U | PTE_P);
```

# 练习2
> env_init()
```c
// 把所有 env 设为 free，env_id 设为0
// 按数组的顺序把它们加入 env_free_list 中
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.  ******************************
	envs[0].env_id = 0;
	envs[0].env_parent_id = 0;
	envs[0].env_status = ENV_FREE;
	envs[0].env_link = NULL;
	env_free_list = envs;
	struct Env *last=env_free_list;
	for (size_t i = 1; i < NENV; i++)
	{
		envs[i].env_id = 0;
		envs[i].env_parent_id = 0;
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = NULL;
		last->env_link = envs + i;
		last = last->env_link;
	}

	// Per-CPU part of the initialization
	env_init_percpu();
}
```
> env_setup_vm()
```c
static int
env_setup_vm(struct Env *e)
{	

	// 每个环境都有一个页目录，分为内核部分和用户部分，内核部分由继承内核页目录kern_pgdir而来（，用户部分由进程设定）？
	// 该函数只设置环境页目录的内核部分
	// 分配一个页面给该环境作为页目录，除了 PDX(UVPT) 处，这个页目录与内核页目录的内容相同
	int i;
	struct PageInfo *p = NULL;   // 该环境页目录的虚拟地址

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;

	// Now, set e->env_pgdir and initialize the page directory.
	//
	// Hint:
	//    - The VA space of all envs is identical above UTOP
	//	(except at UVPT, which we've set below).
	//	See inc/memlayout.h for permissions and layout.
	//	Can you use kern_pgdir as a template?  Hint: Yes.
	//	(Make sure you got the permissions right in Lab 2.)
	//    - The initial VA below UTOP is empty.
	//    - You do not need to make any more calls to page_alloc.
	//    - Note: In general, pp_ref is not maintained for
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.***********************************
	p->pp_ref++;
	e->env_pgdir = (pde_t *)page2kva(p);
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE); // 初始化新环境地址空间的内核部分。

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
```
> region_alloc()
```c
// 为环境 env分配 len字节的物理内存，并将其映射到环境地址空间的虚拟地址 va
// 不要用 0 或者其他的初始化被映射的物理页面
// 页面应该被用户和内核可写
// 如果分配失败应该 panic
// 注意：boot_map_region只用于静态页面的映射（也就是pages、envs数组这些分配后就不回收的），动态的页面映射要用page_insert
static void
region_alloc(struct Env *e, void *va, size_t len)
{
	// LAB 3: Your code here.*****************************
	// (But only if you need it for load_icode.)
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	size_t n = ROUNDUP(len, PGSIZE) / PGSIZE;
	void* rd_va = ROUNDDOWN(va, PGSIZE);
	for (size_t i = 0; i < n; ++i)
	{
		struct PageInfo *p = page_alloc(0);
		if(p==NULL){
			panic("region_alloc() memory exhaustion\n");
		}
		if(page_insert(e->env_pgdir, p, rd_va, PTE_U | PTE_W)<0){
			panic("region_alloc() memory exhaustion\n");
		}
		rd_va += PGSIZE;
	}
}
```
> load_icode()
```c
// 为一个用户进程设置初始程序二进制、堆栈和处理器标志。
// 这个函数只在运行第一个用户模式环境之前、内核初始化期间被调用
// 此函数将ELF二进制映像中的所有可加载段加载到环境的用户内存中，从ELF程序头中指示的适当虚拟地址开始。
// 同时，它将这些段中在程序头中标记为已映射但实际不存在于ELF文件（即程序的bss部分）的任何部分清零。
// 所有这些都与我们的引导加载程序非常相似，只是引导加载程序还需要从磁盘读取代码。请查看boot/main.c以获得想法。
// 最后，此函数为程序的初始堆栈映射一个页面。
// 如果遇到问题应该 panic 
//  - How might load_icode fail?  What might be wrong with the given input?
// 
// - struct Env *e 要操作的环境      - uint8_t *binary  ELF文件的首地址（虚拟地址）
// 加载binary地址开始处的ELF文件
static void
load_icode(struct Env *e, uint8_t *binary)
{
	// Hints:
	//  Load each program segment into virtual memory
	//  at the address specified in the ELF segment header.
	//  You should only load segments with ph->p_type == ELF_PROG_LOAD.
	//  Each segment's virtual address can be found in ph->p_va
	//  and its size in memory can be found in ph->p_memsz.
	//  The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	//
	//  All page protection bits should be user read/write for now.
	//  ELF segments are not necessarily page-aligned, but you can
	//  assume for this function that no two segments will touch
	//  the same virtual page.
	//
	//  You may find a function like region_alloc useful.
	//
	//  Loading the segments is much simpler if you can move data
	//  directly into the virtual addresses stored in the ELF binary.
	//  So which page directory should be in force during
	//  this function?
	//
	//  You must also do something with the program's entry point,
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.*************************************  加载一个elf文件中的段
	struct Elf *ELFHDR = (struct Elf *)binary;
	if(ELFHDR->e_magic!=ELF_MAGIC){
		panic("load_icode():input is not Elf\n");
	}
	struct Proghdr *ph = (struct Proghdr *)(binary + ELFHDR->e_phoff); // 所有段的数组(段表)
	size_t ph_num = ELFHDR->e_phnum;								   // 段数量

	lcr3(PADDR(e->env_pgdir));  // lcr3() 设置cr3寄存器值，cr3中存放的是当前的页目录物理地址

	for (size_t i = 0; i < ph_num;++i){
		if(ph[i].p_type==ELF_PROG_LOAD){
			region_alloc(e, (void *)ph[i].p_va, ph[i].p_memsz);
			memset((void *)ph[i].p_va, 0, ph[i].p_memsz);  // 保证任何其余的字节为0
			memcpy((void *)ph[i].p_va, binary+ph[i].p_offset, ph[i].p_filesz);  
			// 将binary + ph->p_offset开始的字节复制
		}
	}

	lcr3(PADDR(kern_pgdir));
	e->env_tf.tf_eip = ELFHDR->e_entry;

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.*************************************
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
}
```
> env_create()
```c
void
env_create(uint8_t *binary, enum EnvType type)
{
	// LAB 3: Your code here.*************************************
	struct Env *e;
	int r;
	if ((r=env_alloc(&e, 0)) != 0)
	{
		panic("env_create(): %e\n",r);
	}
	e->env_type = type;
	load_icode(e, binary);
}
```
> env_run()
```c
void
env_run(struct Env *e)
{
	// Step 1: If this is a context switch (a new environment is running):
	//	   1. Set the current environment (if any) back to
	//	      ENV_RUNNABLE if it is ENV_RUNNING (think about
	//	      what other states it can be in),
	//	   2. Set 'curenv' to the new environment,
	//	   3. Set its status to ENV_RUNNING,
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.

	// Hint: This function loads the new environment's state from
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.*********************************
	if(curenv!=NULL){
		if(curenv->env_status==ENV_RUNNING){
			curenv->env_status = ENV_RUNNABLE;
		}
	}
	curenv = e;
	curenv->env_status = ENV_RUNNING;
	curenv->env_runs++;
	lcr3(PADDR(curenv->env_pgdir));
	env_pop_tf(&curenv->env_tf);

	panic("env_run not yet implemented");
}
```

# 练习4
> trapentry.S
```asm
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 TRAPHANDLER为需要传错误代码的异常用，TRAPHANDLER_NOEC无需错误代码
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
	movl %eax,%es   // 将 `GD_KD` 加载到 `%ds` 和 `%es`
	pushl %esp    // `pushl %esp` 将指向 `Trapframe` 的指针作为参数传递给 `trap()`
	call trap
```
> trap_init() 初始化IDT表
```c
void
trap_init(void)
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.**************************
	void Trap_DIVIDE();
	void Trap_DEBUG();
	void Trap_NMI();
	void Trap_BRKPT();
	void Trap_OFLOW();
	void Trap_BOUND();
	void Trap_ILLOP();
	void Trap_DEVICE();
	void Trap_DBLFLT();
	void Trap_COPROC();
	void Trap_TSS();
	void Trap_SEGNP();
	void Trap_STACK();
	void Trap_GPFLT();
	void Trap_PGFLT();
	void Trap_RES();
	void Trap_FPERR();
	void Trap_syscall();
	SETGATE(idt[0], 0, GD_KT, Trap_DIVIDE, 0);
	SETGATE(idt[1], 0, GD_KT, Trap_DEBUG, 0);
	SETGATE(idt[2], 0, GD_KT, Trap_NMI, 0);
	SETGATE(idt[3], 0, GD_KT, Trap_BRKPT, 0);
	SETGATE(idt[4], 0, GD_KT, Trap_OFLOW, 0);
	SETGATE(idt[5], 0, GD_KT, Trap_BOUND, 0);
	SETGATE(idt[6], 0, GD_KT, Trap_ILLOP, 0);
	SETGATE(idt[7], 0, GD_KT, Trap_DEVICE, 0);
	SETGATE(idt[8], 0, GD_KT, Trap_DBLFLT, 0);
	SETGATE(idt[9], 0, GD_KT, Trap_COPROC, 0);
	SETGATE(idt[10], 0, GD_KT, Trap_TSS, 0);
	SETGATE(idt[11], 0, GD_KT, Trap_SEGNP, 0);
	SETGATE(idt[12], 0, GD_KT, Trap_STACK, 0);
	SETGATE(idt[13], 0, GD_KT, Trap_GPFLT, 0);
	SETGATE(idt[14], 0, GD_KT, Trap_PGFLT, 0);
	SETGATE(idt[15], 0, GD_KT, Trap_RES, 0);
	SETGATE(idt[16], 0, GD_KT, Trap_FPERR, 0);
	SETGATE(idt[T_SYSCALL], 0, GD_KT, Trap_syscall, 3);
	// Per-CPU setup
	trap_init_percpu();
}
```

# 练习5
> 修改trap_dispatch() ,该函数根据trapno判断不同的异常，进行分发
```c
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.****************
	switch (tf->tf_trapno)
	{
	case T_PGFLT:
		page_fault_handler(tf);
		break;

	default:
		break;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
}
```

# 练习6
> 测试breakpoint失败，查看文件`jos.out.breakpoint`，发现中断类型`trap 0x0000000d General Protection`，这是因为我们在用户模式进行`int3`进入更高特权等级的内核，要求CPL<=DPL，所以DPL应该设置为3，将`trap_init`函数里的改成`SETGATE(idt[3], 0, GD_KT, Trap_BRKPT, 3)`即可。
```c
SETGATE(idt[3], 0, GD_KT, Trap_BRKPT, 3);

```
```c
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.****************
	switch (tf->tf_trapno)
	{
	case T_BRKPT:
		monitor(tf);
		return;
	case T_PGFLT:
		page_fault_handler(tf);
		return;

	default:
		break;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
}
```
> 问题：      
> 3. 断点测试用例将生成断点异常或一般保护错误，具体取决于您在 IDT 中初始化断点条目的方式（即，您从 `trap_init` 调用 `SETGATE`）。为什么？您需要如何设置它才能使断点异常按上面指定的方式工作，以及什么不正确的设置会导致它触发一般保护错误？ 

测试breakpoint失败，查看文件`jos.out.breakpoint`，发现中断类型`trap 0x0000000d General Protection`，为一般保护错，这是因为我们在用户模式进行`int3`进入更高特权等级的内核，要求CPL<=DPL，所以DPL应该设置为3，将`trap_init`函数里的改成`SETGATE(idt[3], 0, GD_KT, Trap_BRKPT, 3)`即可。

> 4. 您认为这些机制的意义何在，特别是考虑到 `user/softint` 测试程序的作用？

避免用户代码使用特权指令。

# 练习7
在`trap_dispatch`中，使用从寄存器保存的值作为参数传递，返回值保存到`%eax`
```c
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,
		tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
		return;
```
在`kern/syscall.c` 的`syscall()`中，系统调用号定义在`inc/syscall.h`中，调用参数顺序一致
```c
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.*********************
	// panic("syscall not implemented");

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
	case SYS_cgetc:
		return sys_cgetc();
	case SYS_env_destroy:
		return sys_env_destroy((envid_t)a1);
	case SYS_getenvid:
		return sys_getenvid();
	default:
		return -E_INVAL;
	}
}
```