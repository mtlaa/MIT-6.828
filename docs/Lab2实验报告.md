# 练习1
> **练习1** 在文件 `kern/pmap.c` 中，你必须实现以下函数的代码。    
> `boot_alloc()`   
> `mem_init()` (only up to the call to check_page_free_list(1))   
> `page_init()`   
> `page_alloc()`   
> `page_free()`  

注：memset使用虚拟地址初始化内存

`boot_alloc()`
```c
static void *
boot_alloc(uint32_t n)
{
    // 静态局部变量，在多次调用boot_alloc中nextfree是同一个变量
	static char *nextfree;	// virtual address of next byte of free memory
	char *result;
	if (!nextfree) {
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
	}
	// LAB 2: Your code here.********************************************************************

	// 两步：1、分配一个足够大的页面  2、更新 nextfree ，要为4096的整数倍
	// 并不需要真正的分配内存，就只是先占个坑
	// 如果n>0，就返回分配空间的首地址
	if(n>0){
		result = nextfree;
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
		return result;
	}
	// 如果n==0，就返回nextfree
	if(n==0){
		return nextfree;
	}

	return NULL;
}
```

`mem_init()`
```c
    // 这里可以模仿上面对初始页目录的分配与初始化（kern_pgdir）
    // Your code goes here:*****************************************************************
	// 分配一个有npages个struct PageInfo的数组，用 memset 把所有字段初始化为0
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
	memset(pages, 0, npages * sizeof(struct PageInfo));
```

`page_init()`
```c
// 参考lab1 Part1 中物理内存的布局
// |                  |
// | Extended Memory  |                             扩展内存
// |                  |
// |                  |
// +------------------+  <- 0x00100000 (1MB)     ------------------
// |     BIOS ROM     |                              
// +------------------+  <- 0x000F0000 (960KB)
// |  16-bit devices, |
// |  expansion ROMs  |                            IO hole
// +------------------+  <- 0x000C0000 (768KB)
// |   VGA Display    |
// +------------------+  <- 0x000A0000 (640KB)   -------------------
// |                  |
// |    Low Memory    |                            base memory  基础内存
// |                  |
// +------------------+  <- 0x00000000           --------------------

void
page_init(void)
{
	//  1) 第一个物理页面应该标记为被使用的，
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) 其余的基础内存标记为空闲的   [PGSIZE, npages_basemem * PGSIZE)
	//  3) IO hole [IOPHYSMEM, EXTPHYSMEM), 不应该被分配，标记为被使用
	//  4) 扩展内存 [EXTPHYSMEM, ...)，扩展内存中已经加载了内核、
    //    分配了（通过boot_alloc）初始页目录和 npages个struct PageInfo所占的页面，它们已被使用
	//     
	//
	// Change the code to reflect this.***************************************************************
	// NB: DO NOT actually touch the physical memory corresponding to free pages!
	size_t i;
	// [IOPHYSMEM, EXTPHYSMEM) + [EXTPHYSMEM, truly_end) 都是已占用的地址，内核的开始物理地址为EXTPHYSMEM，
	// truly_end前面包括boot_alloc分配的页目录和pages数组
	physaddr_t truly_end = PADDR(boot_alloc(0));    // boot_alloc(0)会返回内核虚拟地址nextfree
	for (i = 0; i < npages; i++)
	{
		if(i==0){   // （1）
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){    // (3) (4)
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}else{   // (2) 与 其他的扩展内存
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
```

`page_alloc()`
```c
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in ******************************************************
	// 从page_free_list空闲列表中摘出一个空闲页的PageInfo，标记为使用（pp_link=NULL），memset初始化为0
	// 注意，不要增加pp_ref引用计数，应该由上层调用者增加
	if(page_free_list){
		struct PageInfo *freePage = page_free_list;
		page_free_list = freePage->pp_link;
		freePage->pp_link = NULL;
		if(alloc_flags&ALLOC_ZERO){    // 只有这个条件满足时才把内存页面初始化为0
			memset(page2kva(freePage), 0, PGSIZE);
		}
		return freePage;
	}
	return 0;
}
```

`page_free()`
```c
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
	// Fill this function in ******************************************************
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref||pp->pp_link){
		panic("Page is free, have not to free\n");
	}
	// 把页面的PageInfo接回page_free_list中
	pp->pp_link = page_free_list;
	page_free_list = pp;
}
```

完成上述函数后把`mem_init()`中的`panic("mem_init: This function is not finished\n");`注释掉，执行`make grade`进行评分。
```bash
Physical page allocator: OK 

Score: 20/70
GNUmakefile:201: recipe for target 'grade' failed
make: *** [grade] Error 1
```

# 问题1
> **Question 1** 假设下面的 JOS 内核代码是正确的，变量 `x` 应该有什么类型，`uintptr_t` 还是 `physaddr_t`？
> ```c
>   mystery_t x;
>	char* value = return_a_pointer();
>	*value = 10;
>	x = (mystery_t) value;
>```

总结：
| C type | Address type |
| :------ | :-------: |
| T*     |	Virtual     |
| uintptr_t  |	Virtual |
| physaddr_t  |	Physical |

`value`本身是一个指针，为虚拟地址，若`x`要保留这个含义，那么应该是`uintptr_t`类型。


# 练习4

页表项的格式     
![](https://pdos.csail.mit.edu/6.828/2018/readings/i386/fig5-10.gif)

> **练习4** 在文件 `kern/pmap.c` 中，您必须实现以下函数的代码。      
> `pgdir_walk()`    
> `boot_map_region()`    
> `page_lookup()`     
> `page_remove()`     
> `page_insert()`     
> 从 `mem_init()` 调用的 `check_page()` 测试您的页表管理例程。在继续 Part 3 之前，您应该确保它报告成功。

`pgdir_walk()`:这个函数的任务是找到虚拟地址`va`对应的页表项的指针（虚拟地址）；若保存该页表项的页表还没有分配(*pde & PTE_P==0)，那么分配一个页作为页表，然后再返回`va`对应的页表项的指针
```c
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in ************************************
	// pgdir 指向页目录（顶级页表），函数需要返回指向线性地址“va”的页表项（PTE）的指针。（需要查两级页表）
	// 有可能二级页表页不存在，此时如果 create == false 则返回NULL，否则：
	// 使用page_alloc分配一个页面，如果分配失败返回NULL，否则：
	// 增加引用计数,更新页目录项，返回指向线性地址“va”的页表项（PTE）的指针。
	// 注意:页表项和页目录项中存放的是物理地址
	size_t pgdir_index = PDX(va);  // 页目录索引
	size_t pgt_index = PTX(va);  // 页表索引
	pde_t* pde = pgdir+pgdir_index;   // 页目录项指针
	pte_t *pte;   // 页表页的指针
	if (!*pde & PTE_P)
	{
	    // 二级页表不存在,需要分配一页创建一个页表
		if(!create)
			return NULL;
		struct PageInfo *new_page = page_alloc(1);
		if(!new_page)
			return NULL;
		new_page->pp_ref++;
		*pde = page2pa(new_page) | PTE_P | PTE_W | PTE_U;   // 更新页目录项,为什么要设置 PTE_W  PTE_U 这两位?
		// PTE_W 可写位  PTE_U 用户
	}
	// 二级页表存在 和 分配新页表 后的共同操作
	pte = (pte_t *)KADDR(PTE_ADDR(*pde));
	return pte + pgt_index;    // 返回页表项的指针
}
```
关于更新页目录项,为什么要设置 PTE_W  PTE_U 这两位?
> 设置权限，由于一级页表和二级页表都有权限控制，所以一般的做法是，放宽一级页表的权限，主要由二级页表来控制权限，所以对页目录项（由一级页表访问二级页表）的权限直接`| PTE_P | PTE_W | PTE_U`设置以放宽权限；对页表项（由二级页表项访问内存）的权限使用`| perm | PTE_P`来设置，达到最终控制访存的目的，`perm`的使用在后面的函数可以看到。



`boot_map_region()`:这个函数的任务就是要 修改`va`对应的页表项使其指向物理地址`pa`对应的物理页面，建立映射
```c
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// 将虚拟地址空间的[va, va+size)映射到以pgdir为根的页表中的物理地址[pa, pa+size)。 
	// 上述过程：就是要修改va对应的页表项，使其指向pa
	// size是PGSIZE的倍数，va和pa都是页对齐的。
	// 使用pgdir_walk函数
	// Fill this function in *********************************
	for (size_t i = 0; i < size/PGSIZE;++i){
		pte_t *pte = pgdir_walk(pgdir, (void*)va, 1);
		if(!pte)
			panic("boot_map_region(): out of memory\n");
		va = va + PGSIZE;
		// "Use permission bits perm|PTE_P for the entries." 这句话说明
		// 使用 pa | perm | PTE_P 设置页表项的比特位
		*pte = pa | perm | PTE_P;  // 要修改va对应的页表项，使其指向pa
		pa += PGSIZE;
	}
}
```

`page_lookup()`:这个函数的功能就是查询虚拟地址`va`对应的物理页面的`PageInfo`
```c
// 返回映射在虚拟地址'va'的页面。如果pte_store不是0，那么我们就在其中存储这个页面的pte地址。 
// 这是由page_remove使用的，可以用来验证syscall参数的页面权限，但不应被大多数调用者使用。
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in ***********************************
	pte_t *pte = pgdir_walk(pgdir, va, 0);   // 只返回va对应的页表项，不分配新的页表页
	if(pte_store){
		*pte_store = pte;
	}
	if(pte){
		return pa2page(PTE_ADDR(*pte));
	}
	return NULL;
}
```

`page_remove()`:取消`va`与其物理页面的映射关系，把`va`对应的页表项清0
```c
void
page_remove(pde_t *pgdir, void *va)
{
	// Fill this function in ****************************
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
	if (!pp)
		return;
	page_decref(pp);
	*pte = 0;
	tlb_invalidate(pgdir, va);  // The TLB must be invalidated if you remove an entry from the page table.
}
```

`page_insert()`:建立虚拟地址`va`与物理页`pp`的映射关系
```c
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in *********************
	// 获取va对应的页表项地址，有三种情况：1、页表项已经存在，后面需要remove  2、分配了一个新的页表页，返回一个空的页表项
	// 								3、内存不足，分配页表失败，此时pte==NULL
	pte_t *pte = pgdir_walk(pgdir, va, 1);   
	if (!pte)    // case 3
		return -E_NO_MEM;
	pp->pp_ref++;   // 引用计数的增加必须在 page_remove 前面！！  this is an elegant way to handle
	// 原因：在 Corner-case 条件下，即相同的 pp 重新映射到相同的 va 时
	// 若pp的引用计数为 1 ，在page_remove中会把 pp 释放掉,即把页面 pp 接回了 page_free_list中
	// 这样 should be no free memory "assert(!page_alloc(0));" 这条判断就为false
	// assertion failed: !page_alloc(0)
	pp->pp_link = NULL;
	if(*pte&PTE_P){    // case 1
		// 如果尝试用如下方式避免相同的重新分配，也会报错：kernel panic at kern/pmap.c:833: assertion failed: *pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U
		// if(PTE_ADDR(*pte)==page2pa(pp))
		// 	return 0;    // 如果在相同的pgdir中把相同的"pp"重新映射到相同的“va” 则什么也不做
		page_remove(pgdir, va);
	}
	*pte = page2pa(pp) | perm | PTE_P;   // 建立映射
	return 0;
}
```

`make grade`结果：
```
running JOS: (1.3s) 
  Physical page allocator: OK 
  Page management: OK 

Score: 40/70
```

# 练习5
> **练习5** 在`mem_init()`中的` check_page()`调用后完成缺失的代码。     
> 你的代码应该能通过 `check_kern_pgdir()` 和 `check_page_installed_pgdir()` 检查。

```c
	//////////////////////////////////////////////////////////////////////
	// Now we set up virtual memory

	//////////////////////////////////////////////////////////////////////
	// Map 'pages' read-only by the user at linear address UPAGES
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here: *********************************
	// PADDR(pages) 为pages数组的物理地址     
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
	// 权限： ”PTE_U“说明用户可以读，”PTE_W“说明内核可以写， PTE_U | PTE_W 说明用户可以写 
	// 只要 PTE_P 位有效，内核就可以读
 	//////////////////////////////////////////////////////////////////////
	// Use the physical memory that 'bootstack' refers to as the kernel
	// stack.  The kernel stack grows down from virtual address KSTACKTOP.
	// We consider the entire range from [KSTACKTOP-PTSIZE, KSTACKTOP)
	// to be the kernel stack, but break this into two pieces:
	//     * [KSTACKTOP-KSTKSIZE, KSTACKTOP) -- backed by physical memory
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here: ********************************
	// bootstack是一个指针（虚拟地址），PADDR(bootstack)是其对应的物理地址
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: ************************************
	boot_map_region(kern_pgdir, KERNBASE, 0x100000000 - KERNBASE, 0, PTE_W);
```
读懂英文注释应该就能写出来。
```
running JOS: (1.9s) 
  Physical page allocator: OK 
  Page management: OK 
  Kernel page directory: OK 
  Page management 2: OK 
Score: 70/70
```
