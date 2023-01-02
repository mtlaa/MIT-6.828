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

注意，`trap_init_percpu()`只被调用一次就初始化所有CPU
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
	for (size_t i = 0; i < NCPU;++i)
	{
		cpus[i].cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		cpus[i].cpu_ts.ts_ss0 = GD_KD;
		cpus[i].cpu_ts.ts_iomb = sizeof(struct Taskstate);
		gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t)(&cpus[i].cpu_ts),
										sizeof(struct Taskstate) - 1, 0);
		gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
	}

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
```