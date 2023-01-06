# 练习1
> **Exercise 1** 在 `kern/pmap.c` 中实现 `mmio_map_region`。要了解它是如何使用的，请查看 `kern/lapic.c` 中 `lapic_init` 的开头。在运行 `mmio_map_region` 的测试之前，您还必须完成下一个练习。
```c
void *
mmio_map_region(physaddr_t pa, size_t size)
{
	// Where to start the next region.  Initially, this is the
	// beginning of the MMIO region.  Because this is static, its
	// value will be preserved between calls to mmio_map_region
	// (just like nextfree in boot_alloc).
	static uintptr_t base = MMIOBASE;


	// 保留base开始的size字节，并且把物理页面[pa,pa+size)映射到[base,base+size)
	// 页表项权限位使用PTE_W|PTE_PCD|PTE_PWT (缓存禁用和写入)创建映射
	// size不必是PGSIZE的倍数，需要ROUNDUP
	// 如果本次保留操作溢出（超过了MMIOLIM）则需要panic
	// 提示：使用boot_map_region函数
	// Your code here:******************
	size = ROUNDUP(size, PGSIZE);
	if(base+size>=MMIOLIM)
		panic("mmio_map_region reservation overflow MMIOLIM.\n");
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_PCD | PTE_PWT);
	base += size;
	return (void *)(base-size);
	// panic("mmio_map_region not implemented");
}
```

# 练习2
> **Exercise 2** 阅读 `kern/init.c` 中的 `boot_aps()` 和 `mp_main()`，以及 `kern/mpentry.S` 中的汇编代码。确保您了解 AP 引导期间的控制流传输。然后修改 `kern/pmap.c` 中 `page_init()` 的实现，避免将 `MPENTRY_PADDR` 处的页面添加到空闲列表中，这样我们就可以安全地在该物理地址复制和运行 AP 引导程序代码。您的代码应该通过更新的 `check_page_free_list()` 测试（但可能无法通过更新的 `check_kern_pgdir()` 测试，我们将很快修复）。
```c
void
page_init(void)
{
	// LAB 4:
	// Change your code to mark the physical page at MPENTRY_PADDR
	// as in use

	// Change the code to reflect this.***************************************************************
	// NB: DO NOT actually touch the physical memory corresponding to free pages!
	size_t i;
	// [IOPHYSMEM, EXTPHYSMEM) + [EXTPHYSMEM, truly_end) 都是已占用的地址，内核的开始物理地址为EXTPHYSMEM，
	// truly_end前面包括boot_alloc分配的页目录和pages数组
	physaddr_t truly_end = PADDR(boot_alloc(0));
	for (i = 0; i < npages; i++)
	{
		if(i==0){
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}else if(page2pa(pages+i)==MPENTRY_PADDR){
			// Lab 4 exercise 2
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}else{
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
```

# 问题1
> **Question**
> 1. 将 `kern/mpentry.S` 与 `boot/boot.S` 比较。请记住，`kern/mpentry.S` 被编译并链接到 `KERNBASE` 之上，就像内核中的其他所有内容一样，宏 `MPBOOTPHYS` 的目的是什么？为什么在 `kern/mpentry.S` 中有必要，而在 `boot/boot.S` 中没有？换句话说，如果在 `kern/mpentry.S` 中省略它会出什么问题？     
>提示：回想一下我们在 lab 1 中讨论过的链接地址和加载地址之间的区别。

宏`MPBOOTPHYS`的作用是得到`kern/mpentry.S`中变量的物理地址（`((s) - mpentry_start + MPENTRY_PADDR)`），`kern/mpentry.S`的链接地址是在`KERNBASE` 之上,加载地址为`MPENTRY_PADDR:0x7000`。`boot.S`中，由于没有启用分页机制，所以我们能够指定程序开始执行的地方以及程序加载的地址；但是，在`mpentry.S`的时候，由于主CPU已经处于保护模式下了，因此不能直接指定物理地址，需要把给定的线性地址映射到相应的物理地址（使用这个宏）。

# 练习3
> **Exercise 3** 修改 `mem_init_mp()`（在 `kern/pmap.c` 中）以映射从 `KSTACKTOP` 开始的每个 CPU 堆栈，如 `inc/memlayout.h` 中所示。每个堆栈的大小是 `KSTKSIZE` 字节加上未映射保护页的 `KSTKGAP` 字节。您的代码应该通过 `check_kern_pgdir()` 中的新检查。
```c
// 映射每个CPU的堆栈到虚拟内存[KSTACKTOP-PTSIZE, KSTACKTOP)
static void
mem_init_mp(void)
{
	// Map per-CPU stacks starting at KSTACKTOP, for up to 'NCPU' CPUs.
	//
	// For CPU i, use the physical memory that 'percpu_kstacks[i]' refers
	// to as its kernel stack. CPU i's kernel stack grows down from virtual
	// address kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP), and is
	// divided into two pieces, just like the single stack you set up in
	// mem_init:
	//     * [kstacktop_i - KSTKSIZE, kstacktop_i)
	//          -- backed by physical memory
	//     * [kstacktop_i - (KSTKSIZE + KSTKGAP), kstacktop_i - KSTKSIZE)
	//          -- not backed; so if the kernel overflows its stack,
	//             it will fault rather than overwrite another CPU's stack.
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:*************************
	for (size_t i = 0; i < NCPU;++i){
		uintptr_t kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
	}
}
```

# 练习4
> **Exercise 4** `trap_init_percpu()` (`kern/trap.c`) 中的代码为 BSP 初始化 TSS 和 TSS 描述符。它在实验 3 中有效，但在其他 CPU 上运行时不正确。更改代码，使其可以在所有 CPU 上工作。 （注意：您的新代码不应再使用全局 `ts` 变量。） 

~~注意，`trap_init_percpu()`只被调用一次就初始化所有CPU~~，并不是，每个cpu都会执行这些初始化代码，所以该函数只需要初始化当前cpu就行
```c
// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
	// The example code here sets up the Task State Segment (TSS) and
	// the TSS descriptor for CPU 0. But it is incorrect if we are
	// running on other CPUs because each CPU has its own kernel stack.
	// Fix the code so that it works for all CPUs.
	//
	// Hints:
	//   - The macro "thiscpu" always refers to the current CPU's
	//     struct CpuInfo;
	//   - The ID of the current CPU is given by cpunum() or
	//     thiscpu->cpu_id;
	//   - Use "thiscpu->cpu_ts" as the TSS for the current CPU,
	//     rather than the global "ts" variable;
	//   - Use gdt[(GD_TSS0 >> 3) + i] for CPU i's TSS descriptor;
	//   - You mapped the per-CPU kernel stacks in mem_init_mp()
	//   - Initialize cpu_ts.ts_iomb to prevent unauthorized environments
	//     from doing IO (0 is not the correct value!)
	//
	// ltr sets a 'busy' flag in the TSS selector, so if you
	// accidentally load the same TSS on more than one CPU, you'll
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:************
	// modify
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - thiscpu->cpu_id * (KSTKSIZE + KSTKGAP);
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+cpunum()] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+cpunum()].sd_s = 0;

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (cpunum() << 3));

	// Load the IDT
	lidt(&idt_pd);
}
```

# 问题2
> **Question 2** 似乎使用大内核锁可以保证一次只有一个 CPU 可以运行内核代码。为什么我们仍然需要为每个 CPU 提供单独的内核堆栈？描述一个使用共享内核栈会出错的场景，即使有大内核锁的保护。

因为内核堆栈中可能会存放上次运行的信息以及该CPU的私有数据，所以需要为每个CPU提供单独的内核堆栈。

# 练习6
`sched_yield()`
```c
// Choose a user environment to run and run it.
void
sched_yield(void)
{
	struct Env *idle;

	// LAB 4: Your code here.**********************
	size_t start = 0, i,next;
	if (curenv)
	{
		start = ENVX(curenv->env_id);
	}
	for (i = 0; i < NENV;++i)
	{
		next = (start + i) % NENV;
		if(envs[next].env_status==ENV_RUNNABLE){
			env_run(envs + next);
		}
	}
	if(curenv&&curenv->env_status==ENV_RUNNING&&thiscpu->cpu_env==curenv)
		env_run(curenv);

	// sched_halt never returns
	sched_halt();
}
```
`syscall()`
```c
	case SYS_yield:
		sys_yield();
		return 0;
```
`kern/init.c`中的`i386_init()`,注意，因为`user_primes`程序会调用`fork()`(还未实现，会panic)，所以需要注释掉不创建该环境，才可以得到正常的结果。
```c
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	// ENV_CREATE(user_primes, ENV_TYPE_USER);
#endif // TEST*
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);

	// Schedule and run the first user environment!
	sched_yield();
```

# 问题3
> **Question**            
> 3. 在您的 `env_run()` 实现中，您应该调用 `lcr3()`。在调用 `lcr3()` 之前和之后，您的代码引用（至少应该引用）变量 `e`，即 `env_run` 的参数。加载 `%cr3` 寄存器后，MMU 使用的寻址上下文会立即更改。但是虚拟地址（即 `e`）相对于给定的地址上下文具有——地址上下文指定虚拟地址映射到的物理地址。为什么在寻址切换之前和之后都可以解引用指针 `e`？                

在调用`lcr3()`之前，使用的是内核页目录寻址，`struct Env *e`这个指针以及所指内存是在内核模式下创建、初始化的，所以在之前当然能解引用`e`。在调用之后会切换到环境页目录寻址，在`env_setup_vm()`中设置了环境的页目录，包含继承内核页目录的部分（该部分包含`e`的映射）和该环境的私有部分，所以也可以寻址到（解引用）`e`。

# 问题4
> **Question**                           
> 4. 每当内核从一个环境切换到另一个环境时，它必须确保保存旧环境的寄存器，以便以后可以正确恢复它们。为什么？这发生在哪里？

在执行一个环境时会产生一些与该环境有关的状态、临时数据会保存在寄存器中，切换环境时保存它们这样恢复时可以恢复到上次执行的状态。发生在`trap()`函数的`curenv->env_tf = *tf;`

# 练习7
`sys_exofork`
```c
static envid_t
sys_exofork(void)
{
	// LAB 4: Your code here.*******************
	// panic("sys_exofork not implemented");
	// 使用env_alloc()创建一个新环境，状态设置为ENV_NOT_RUNNABLE，寄存器env_tf由当前环境拷贝而来
	struct Env *e;
	int err = env_alloc(&e, curenv->env_id);
	if(err!=0){
		return err;
	}
	e->env_status = ENV_NOT_RUNNABLE;
	e->env_tf = curenv->env_tf;
	e->env_tf.tf_regs.reg_eax = 0;   // 这行代码必不可少！！为什么？？？？？？？？？！！！！！！！
	// 代码执行到此处是因为当前环境调用了sys_exofork()系统调用，创建的新环境复制了当前环境的env_tf
	// 新环境和当前环境（父）就有了相同的寄存器状态，就相当于新环境也调用sys_exofork()系统调用（其实并没有）
	// lab3中我们知道eax寄存器会保存系统调用的返回值，父环境应该返回新环境的id，子环境应该返回0
	// 所以要把子环境的eax寄存器设为0  【新的进程从sys_exofork()的返回值应该为0】
	return e->env_id;
}
```
`sys_env_set_status`
```c
static int
sys_env_set_status(envid_t envid, int status)
{
	// LAB 4: Your code here.*******************
	// panic("sys_env_set_status not implemented");
	if(status!=ENV_RUNNABLE&&status!=ENV_NOT_RUNNABLE)
		return -E_INVAL;
	struct Env *e;
	if(envid2env(envid,&e,1)==-E_BAD_ENV)
		return -E_BAD_ENV;
	e->env_status = status;
	return 0;
}
```
`sys_page_alloc`
```c
static int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	// LAB 4: Your code here.***********
	// panic("sys_page_alloc not implemented");
	struct Env *e;
	if(envid2env(envid,&e,1)==-E_BAD_ENV)
		return -E_BAD_ENV;
	if((uintptr_t)va>=UTOP||((uintptr_t)va)%PGSIZE!=0)
		return -E_INVAL;
	if((perm&PTE_P)!=PTE_P||(perm&PTE_U)!=PTE_U||((perm|PTE_AVAIL)>PTE_SYSCALL))
		return -E_INVAL;
	struct PageInfo *p = page_alloc(1);
	if(!p)
		return -E_NO_MEM;
	if(page_insert(e->env_pgdir, p, va, perm)==-E_NO_MEM){
		page_free(p);
		return -E_NO_MEM;
	}
	return 0;
}
```
`sys_page_map`
```c
static int
sys_page_map(envid_t srcenvid, void *srcva,
	     envid_t dstenvid, void *dstva, int perm)
{
	// LAB 4: Your code here.************************
	// panic("sys_page_map not implemented");
	struct Env *srce, *dste;
	if(envid2env(srcenvid,&srce,1)==-E_BAD_ENV||envid2env(dstenvid,&dste,1)==-E_BAD_ENV)
		return -E_BAD_ENV;
	if((uintptr_t)srcva>=UTOP||(uintptr_t)dstva>=UTOP||
		((uintptr_t)srcva)%PGSIZE!=0||((uintptr_t)dstva)%PGSIZE!=0)
		return -E_INVAL;
	if((perm&PTE_P)!=PTE_P||(perm&PTE_U)!=PTE_U||((perm|PTE_AVAIL)>PTE_SYSCALL))
		return -E_INVAL;
	struct PageInfo *p;
	pte_t *src_pte;
	p = page_lookup(srce->env_pgdir, srcva, &src_pte);
	if(!p)
		return -E_INVAL;
	if(perm&PTE_W&&((*src_pte)&PTE_W)!=PTE_W)
		return -E_INVAL;
	return page_insert(dste->env_pgdir, p, dstva, perm);
}
```
`sys_page_unmap`
```c
static int
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.*******************
	// panic("sys_page_unmap not implemented");
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
	if((uintptr_t)va>=UTOP||((uintptr_t)va)%PGSIZE!=0)
		return -E_INVAL;
	page_remove(e->env_pgdir, va);
	return 0;
}
```
运行`make run-dumbfork`
```bash
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
[00001000] new env 00001001
0: I am the parent!
0: I am the child!
1: I am the parent!
...
18: I am the child!
19: I am the child!
[00001001] exiting gracefully
[00001001] free env 00001001
No runnable environments in the system!
Welcome to the JOS kernel monitor!
```

# 练习8
> **Exercise 8** 实现 `sys_env_set_pgfault_upcall` 系统调用。在查找目标环境的环境 ID 时一定要启用权限检查，因为这是一个“危险”的系统调用。
```c
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.**************
	// panic("sys_env_set_pgfault_upcall not implemented");
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
	e->env_pgfault_upcall = func;
	return 0;
}
```

# 练习9
> **Exercise 9** 在 `kern/trap.c` 中实现 `page_fault_handler` 中的代码，以将页面错误分派给用户模式处理程序。写入异常堆栈时一定要采取适当的预防措施。 （如果用户环境用完异常堆栈上的空间会怎样？）
```c
void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.
	if((tf->tf_cs&3)==0){
		// 如果是内核模式的页面错误
		panic("page fault in kernel-mode.\n");
	}

	// LAB 4: Your code here.******************
	if (curenv->env_pgfault_upcall )
	{
		uintptr_t uxs_top = UXSTACKTOP - sizeof(struct UTrapframe);
		if (tf->tf_esp >= UXSTACKTOP - PGSIZE && tf->tf_esp <= UXSTACKTOP - 1)
		{
			uxs_top = tf->tf_esp - 4 - sizeof(struct UTrapframe);
		}
		// 检查栈是否溢出、异常栈有没有分配、该环境是否可以访问该异常栈
		user_mem_assert(curenv, (void *)uxs_top, sizeof(struct UTrapframe), PTE_W | PTE_U);
		// 设置异常栈
		struct UTrapframe *utf_ptr = (struct UTrapframe *)uxs_top;
		utf_ptr->utf_esp = tf->tf_esp;    // 栈上保存发生页面错误时的esp和eip，这样就可以在处理完错误后恢复运行
		utf_ptr->utf_eflags = tf->tf_eflags;
		utf_ptr->utf_eip = tf->tf_eip;
		utf_ptr->utf_regs = tf->tf_regs;
		utf_ptr->utf_err = tf->tf_err;
		utf_ptr->utf_fault_va = fault_va;

		// 修改环境的运行内容
		curenv->env_tf.tf_esp = uxs_top;
		curenv->env_tf.tf_eip = (uintptr_t)curenv->env_pgfault_upcall;   // 修改环境的eip为页面错误处理程序的入口
		env_run(curenv);
		
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}
```

# 练习10
> **Exercise 10** 在 `lib/pfentry.S` 中实现 `_pgfault_upcall` 例程。有趣的部分是返回到导致页面错误的用户代码中的原始点。您将直接返回那里，而无需通过内核返回。困难的部分是同时切换堆栈和重新加载 `EIP`。
```asm
	// LAB 4: Your code here.
	addl $8,%esp
	// 要把 trap time eip 恢复到原来的正常堆栈（trap time esp所指的地方）中
	// 这个操作要在恢复通用寄存器之前做，否则会破环寄存器中的内容
	movl 40(%esp),%eax      // 把 trap time esp 放到 eax寄存器中
	movl 32(%esp),%ecx      // 把 trap time eip 放到 ecx寄存器中
	movl %ecx,-4(%eax)      // 把 trap time eip 压入原来的堆栈
	popal
	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	addl $4,%esp
	popfl
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	popl %esp
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	lea -4(%esp),%esp
	ret
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
```

# 练习11
> **Exercise 11** 完成 `lib/pgfault.c` 中的 `set_pgfault_handler()`。
```c
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
	int r;
	if (_pgfault_handler == 0) {
		// First time through!
		// LAB 4: Your code here.***********************
		// panic("set_pgfault_handler not implemented");
		r = sys_page_alloc(sys_getenvid(), (void *)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P);
		if(r<0)
			panic("set_pgfault_handler():%e\n", r);
		sys_env_set_pgfault_upcall(0, _pgfault_upcall);   // 系统调用，为当前环境设置页面错误处理入口，0可以代表当前环境id
	}
	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
}
```

# 练习12
> **Exercise 12** 在 `lib/fork.c` 中实现 `fork`、`duppage` 和 `pgfault`。 

`fork()`
```c
envid_t
fork(void)
{
	// LAB 4: Your code here.****************
	// panic("fork not implemented");
	extern void _pgfault_upcall(void);
	set_pgfault_handler(pgfault);
	envid_t child_id = sys_exofork();
	if (child_id == 0)
	{
		thisenv = envs + ENVX(sys_getenvid());
		return 0;
	}
	if(child_id<0){
		panic("sys_exofork() err in fork():%e\n", child_id);
	}
	
	for (size_t i = 0; i < PGNUM(USTACKTOP);i++)
	{
		if(uvpd[PDX(i*PGSIZE)] & PTE_P && uvpt[i] & PTE_P){
			if(duppage(child_id,i)<0)
				panic("in fork(), duppage() error.\n");
		}
	}
	int r;
	// 异常堆栈直接分配一个新页面,且不需要设置PTE_COW
	if((r = sys_page_alloc(child_id, (void *)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P))<0)
		panic("sys_page_alloc():%e\n", r);
	// 为子环境设置用户页面错误入口点
	if((r = sys_env_set_pgfault_upcall(child_id, _pgfault_upcall))<0)
		panic("sys_env_set_pgfault_upcall():%e\n", r);
	if((r = sys_env_set_status(child_id, ENV_RUNNABLE))<0)
		panic("sys_env_set_status():%e\n", r);
	return child_id;
}
```
在`fork()`中碰到一个很难找的错误,我猜测是因为忽略了`volatile`关键字的作用导致的,如下:
```c
// 错误代码 ------------------------------------------
for (size_t i = 0; i < PGNUM(USTACKTOP);i++)
{
	pde_t pde = uvpd[PDX(i * PGSIZE)];
	pte_t pte = uvpt[i];
	if ((pde & PTE_P) && (pte & PTE_P))
	{
		if (duppage(child_id, i) < 0)
			panic("in fork(), duppage() error.\n");
	}
}
// ---------------------------------------------
// 正确代码
for (size_t i = 0; i < PGNUM(USTACKTOP);i++)
{
	pde_t pde = uvpd[PDX(i * PGSIZE)];
	if ((pde & PTE_P) && (uvpt[i] & PTE_P))
	{
		if (duppage(child_id, i) < 0)
			panic("in fork(), duppage() error.\n");
	}
}
```
两者的差别很小,但错误的代码会导致某些页面无法进入`duppage`标记为`PTE_COW`. `volatile`关键字指明该变量可能随时会改变,编译器不要优化该变量,每次都从其源地址取得变量值. 我把`uvpt[i]`赋值了,代码可能是拿旧的值进行了判断,所以会出错.

`duppage()`
```c
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	// cprintf("jin le duppage\n");
	// LAB 4: Your code here.**************
	// panic("duppage not implemented");
	// 1 该页面只读,直接复制映射,不用设PTE_COW
	// 2 该页面为可写或者COW,父子环境的pte都要标记为PTE_COW
	uintptr_t addr = pn * PGSIZE;
	if((uvpt[pn]&PTE_W)||(uvpt[pn]&PTE_COW)){
		r = sys_page_map(0, (void *)addr, envid, (void *)addr, PTE_P | PTE_U | PTE_COW);
		if(r<0)
			panic("duppage():%e\n", r);
		r = sys_page_map(0, (void *)addr, 0, (void *)addr, PTE_P | PTE_U | PTE_COW);
		if(r<0)
			panic("duppage():%e\n", r);
	}
	else
	{
		r = sys_page_map(0, (void *)addr, envid, (void *)addr, PTE_P | PTE_U);
		if(r<0)
			panic("duppage():%e\n", r);
	}
	return 0;
}
```

`pgfault()`
```c
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;
	uintptr_t thispage = ROUNDDOWN((uint32_t)addr, PGSIZE);

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).
	// LAB 4: Your code here.****************
	if((err&FEC_WR)==0||(uvpt[PGNUM(addr)]&PTE_COW)==0)
		panic("pgfault():not a write fault or not a COW page\n");

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	// LAB 4: Your code here.************
	if((r=sys_page_alloc(0,(void*)PFTEMP,PTE_U|PTE_P|PTE_W))<0)
		panic("pgfault():%e\n", r);
	memcpy((void *)PFTEMP, (void *)thispage, PGSIZE);
	if((r=sys_page_unmap(0,(void*)thispage))<0)
		panic("pgfault():%e\n", r);
	if((r=sys_page_map(0,(void*)PFTEMP,0,(void*)thispage,PTE_P|PTE_U|PTE_W))<0)
		panic("pgfault():%e\n", r);
	if((r=sys_page_unmap(0,(void*)PFTEMP))<0)
		panic("pgfault():%e\n", r);
	// panic("pgfault not implemented");
}
```

`make grade`结果
```bash
faultread: OK (2.2s) 
faultwrite: OK (2.1s) 
faultdie: OK (2.4s) 
faultregs: OK (2.1s) 
faultalloc: OK (2.2s) 
faultallocbad: OK (2.1s) 
faultnostack: OK (2.0s) 
faultbadhandler: OK (2.0s) 
faultevilhandler: OK (2.5s) 
forktree: OK (2.2s) 
Part B score: 50/50
```

# 练习13
> **Exercise 13** 修改 `kern/trapentry.S` 和 `kern/trap.c` 以初始化 IDT 中的适当条目并为 IRQ 0 到 15 提供处理程序。然后修改 `kern/env.c` 中 `env_alloc()` 中的代码以确保用户环境始终在启用中断的情况下运行。            
> 还要取消注释 `sched_halt()` 中的 `sti` 指令，以便空闲 CPU 取消屏蔽中断。

初始化IDT条目和之前差不多,要注意的是外部中断都不会压入错误代码,所以用`TRAPHANDLER_NOEC`,还要外部中断是在(只在)用户模式下发生,所以在`SETGATE`的最后一个权限参数设为 3.

`env_alloc()`
```c
	// Enable interrupts while in user mode.
	// LAB 4: Your code here.***************
	e->env_tf.tf_eflags = FL_IF;
```
取消注释 `sched_halt()` 中的 `sti`

# 练习14
> **Exercise 14** 修改内核的 `trap_dispatch()` 函数，以便在发生时钟中断时调用 `sched_yield()` 来查找和运行不同的环境。  
```c
case IRQ_OFFSET+IRQ_TIMER:
	lapic_eoi();   // ??? 没有这个实现不了时钟中断
	sched_yield();
	return;
```


