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