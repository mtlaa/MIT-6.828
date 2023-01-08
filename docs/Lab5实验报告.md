# 练习1
> **Exercise 1** `i386_init` 通过将类型 `ENV_TYPE_FS` 传递给您的环境创建函数 `env_create` 来识别文件系统环境。修改 `env.c` 中的 `env_create`，使其赋予文件系统环境 I/O 权限，但绝不会将该权限赋予任何其他环境。             
```c
	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.*******************
	if(type==ENV_TYPE_FS){
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
	}
```
注意要取消注释开始的时候注释的那两行代码。

# 问题1
> **Question**         
> 1. 当您从一个环境切换到另一个环境时，您是否需要做任何其他事情来确保正确保存和恢复此 I/O 权限设置？为什么？

不需要，I/O权限位在标志寄存器eflags中，每次切换环境都会保存和恢复这个寄存器。

# 练习2
> **Exercise 2** 在 `fs/bc.c` 中实现 `bc_pgfault` 和 `flush_block` 函数。

`bc_pgfault`
```c
	// Allocate a page in the disk map region, read the contents
	// of the block from the disk into that page.
	// Hint: first round addr to page boundary. fs/ide.c has code to read
	// the disk.
	//
	// LAB 5: you code here:*******************
	addr = ROUNDDOWN(addr, PGSIZE);
	if((r=sys_page_alloc(0, addr, PTE_P | PTE_U | PTE_W))<0)
		panic("in bc_pgfault, sys_page_alloc: %e\n", r);
	if((r=ide_read(blockno*8,addr,8))<0)
		panic("in bc_pgfault, ide_read: %e\n", r);
```
`flush_block`
```c
void
flush_block(void *addr)
{
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;
	int r;
	if (addr < (void *)DISKMAP || addr >= (void *)(DISKMAP + DISKSIZE))
		panic("flush_block of bad va %08x", addr);

	// LAB 5: Your code here.******************
	// panic("flush_block not implemented");
	if(!va_is_mapped(addr)||!va_is_dirty(addr))
		return;
	addr = ROUNDDOWN(addr, PGSIZE);
	if ((r = ide_write(blockno * 8, addr, 8)) < 0)
		panic("in flush_block, ide_write: %e\n", r);
	if((r=sys_page_map(0,addr,0,addr,uvpt[PGNUM(addr)] & PTE_SYSCALL))<0)
		panic("in flush_block, sys_page_map: %e\n", r);
	
}
```

# 练习3
> **Exercise 3** 以`free_block`为模型实现`fs/fs.c`中的`alloc_block`，它应该在位图中找到一个空闲的磁盘块，标记为已使用，并返回该块的编号。分配块时，应立即使用 `flush_block` 将更改的位图块(块号 2 )刷新到磁盘，以帮助文件系统保持一致性。  
```c
int
alloc_block(void)
{
	// The bitmap consists of one or more blocks.  A single bitmap block
	// contains the in-use bits for BLKBITSIZE blocks.  There are
	// super->s_nblocks blocks in the disk altogether.

	// LAB 5: Your code here.********************
	// panic("alloc_block not implemented");
	uint32_t blockno = 3;
	for (blockno; blockno < super->s_nblocks;++blockno)
	{
		if(block_is_free(blockno)){
			bitmap[blockno / 32] &= ~(1 << (blockno % 32));
			flush_block(diskaddr(2));
			return blockno;
		}
	}
	return -E_NO_DISK;
}
```

# 练习4
> **Exercise 4** 实现 `file_block_walk` 和 `file_get_block`。 `file_block_walk` 从文件中的块偏移映射到 `struct File` 或间接块中该块的指针，非常类似于 `pgdir_walk` 对页表所做的。 `file_get_block` 更进一步，映射到实际的磁盘块，必要时分配一个新的块。 