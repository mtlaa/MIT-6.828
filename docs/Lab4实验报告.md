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