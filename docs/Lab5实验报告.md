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

`file_block_walk`
```c
// 查找文件 f 中第 filebno块 的磁盘块号slot，设置 *ppdiskbno 指向那个slot
// 这里的slot可能是f->f_direct[]中的一个直接块或者是一个indirect block
// 当alloc==ture，如果必要的话这个函数会分配一个间接块
// returns：
// 0 成功 （but note that *ppdiskbno might equal 0）
// 。。。。。。
// 与pgdir_walk类似,该函数就是找到指向 文件某个块的块号 的指针
static int
file_block_walk(struct File *f, uint32_t filebno, uint32_t **ppdiskbno, bool alloc)
{
	// LAB 5: Your code here.
	// panic("file_block_walk not implemented");
	if(filebno>=NDIRECT+NINDIRECT)
		return -E_INVAL;
	if(filebno<NDIRECT){
		// 直接块
		*ppdiskbno = f->f_direct + filebno;
	}
	else
	{
		// 间接块
		if(f->f_indirect==0){
			// 需要分配一个间接块
			if(!alloc)
				return -E_NOT_FOUND;
			int r = alloc_block();
			if(r<0)
				return -E_NO_DISK;
			f->f_indirect = r;
		}
		*ppdiskbno = (uint32_t *)diskaddr(f->f_indirect) + (filebno - NDIRECT);	
	}
	return 0;
}
```
`file_get_block`
```c
// 设置 *blk 为文件f第filebno块 在内存中的地址
// 使用 file_block_walk and alloc_block.
int
file_get_block(struct File *f, uint32_t filebno, char **blk)
{
	// LAB 5: Your code here.
	// panic("file_get_block not implemented");
	if(filebno>=(NDIRECT+NINDIRECT))
		return -E_INVAL;
	uint32_t *pdiskbno;
	int r;
	if((r=file_block_walk(f,filebno,&pdiskbno,1))<0)
		panic("in file_get_block() file_block_walk:%e\n", r);
	if(*pdiskbno==0){
		// 需要分配一个块
		r = alloc_block();
		if(r<0)
			return -E_NO_DISK;
		*pdiskbno = r;
	}
	*blk = (char*)diskaddr(*pdiskbno);
	return 0;
}
```

# 练习5
> **Exercise 5** 在 `fs/serv.c` 中实现 `serve_read`。
```c
// 依据fileid查找打开文件 struct OpenFile ，这里面存有 struct File 和 struct Fd 
// （Fd里存有current seek position，开始读取的位置）
// 调用file_read 从 o->o_fd->fd_offset 位置开始读取 req->req_n 字节到 ret->ret_buf
// 更新相应的 seek position (o->o_fd->fd_offset)
// 返回实际读取的字节数
int
serve_read(envid_t envid, union Fsipc *ipc)
{
	// union 共用体结构允许不同数据类型存储在同一内存位置，但同一时间只允许存在一种类型的值
	struct Fsreq_read *req = &ipc->read;
	struct Fsret_read *ret = &ipc->readRet;        // req和ret指向同一个地址

	if (debug)
		cprintf("serve_read %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

	// Lab 5: Your code here:**************
	int r;
	struct OpenFile *o;
	if ((r = openfile_lookup(envid, req->req_fileid, &o)) < 0)
		return r;
	r = file_read(o->o_file, (void *)ret->ret_buf, req->req_n, o->o_fd->fd_offset);
	if(r>0)
		o->o_fd->fd_offset += r;      // 更新相应的 seek position (o->o_fd->fd_offset)
	return r;
}
```

# 练习6
> **Exercise 6** 在 `fs/serv.c` 中实现 `serve_write`，在 `lib/file.c` 中实现 `devfile_write`。  

`serve_write`
```c
// 把 req->req_n 个字节从 req->req_buf 写到 req_fileid 所代表的文件中的 current seek position
// 并且更新相应的 seek position (o->o_fd->fd_offset)
// 有必要的话扩充文件大小(这已经在file_write中实现了)
// 返回写入的字节数
int
serve_write(envid_t envid, struct Fsreq_write *req)
{
	if (debug)
		cprintf("serve_write %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

	// LAB 5: Your code here.******************
	// panic("serve_write not implemented");
	int r;
	struct OpenFile *o;
	if ((r = openfile_lookup(envid, req->req_fileid, &o)) < 0)
		return r;
	r = file_write(o->o_file, req->req_buf, req->req_n, o->o_fd->fd_offset);
	if(r>0)
		o->o_fd->fd_offset += r;      // 更新相应的 seek position (o->o_fd->fd_offset)
	return r;
}
```
`devfile_write`
```c
// Write at most 'n' bytes from 'buf' to 'fd' at the current seek position.
//
// Returns:
//	 The number of bytes successfully written.
//	 < 0 on error.
static ssize_t
devfile_write(struct Fd *fd, const void *buf, size_t n)
{
	// Make an FSREQ_WRITE request to the file system server.  Be
	// careful: fsipcbuf.write.req_buf is only so large, but
	// remember that write is always allowed to write *fewer*
	// bytes than requested.
	// 注意:buf的大小(即n)可能远大于 sizeof(fsipcbuf.write.req_buf) _____________________
	// LAB 5: Your code here******************
	// panic("devfile_write not implemented");
	int r;
	size_t buf_size = sizeof(fsipcbuf.write.req_buf);
	ssize_t write_count = 0;
	for (size_t i = 0; i < (n + buf_size - 1) / buf_size; ++i)
	{
		size_t thisn = MIN(buf_size, n - i * buf_size);
		memmove(fsipcbuf.write.req_buf, buf + i * buf_size, thisn);
		fsipcbuf.write.req_n = thisn;
		fsipcbuf.write.req_fileid = fd->fd_file.id;
		if((r=fsipc(FSREQ_WRITE,NULL))<0)
			return r;
		write_count += r;
	}
	return write_count;
}
```

# 练习7
> **Exercise 7** `spawn` 依赖于新的系统调用 `sys_env_set_trapframe` 来初始化新创建环境的状态。在 `kern/syscall.c` 中实现 `sys_env_set_trapframe`（不要忘记在 `syscall()` 中调度新的系统调用）。
```c
static int
sys_env_set_trapframe(envid_t envid, struct Trapframe *tf)
{
	// LAB 5: Your code here.***********************
	// Remember to check whether the user has supplied us with a good
	// address!
	// panic("sys_env_set_trapframe not implemented");
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
	if(tf){
		e->env_tf = *tf;
		e->env_tf.tf_eflags &= ~FL_IOPL_MASK;     // IOPL of 0
		e->env_tf.tf_eflags |= FL_IF;     // interrupts enabled
		e->env_tf.tf_cs = GD_UT | 3;	  // CPL=3 ,CPL保存在cs寄存器的最低两位
	}
	return 0;
}
```

# 练习8
> **Exercise 8** 更改 `lib/fork.c` 中的 `duppage` 以遵循新约定。如果页表条目设置了 `PTE_SHARE` 位，则直接复制映射即可。 （你应该使用 `PTE_SYSCALL`，而不是 `0xfff`来屏蔽掉页表条目中的相关位。`0xfff` 会包含已访问和脏的位。）         
> 同样，在 `lib/spawn.c` 中实现 `copy_shared_pa​​ges`。它应该遍历当前进程中的所有页表条目（就像 `fork` 所做的那样），将任何设置了 `PTE_SHARE` 位的页映射复制到子进程中。

`duppage`
```c
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	// cprintf("jin le duppage\n");
	// LAB 4: Your code here.**************
	// panic("duppage not implemented");
	// 0 该页面为 PTE_SHARE,直接复制映射
	// 1 该页面只读,直接复制映射,不用设PTE_COW
	// 2 该页面为可写或者COW,父子环境的pte都要标记为PTE_COW
	uintptr_t addr = pn * PGSIZE;
	if(uvpt[pn]&PTE_SHARE){
		r = sys_page_map(0, (void *)addr, envid, (void *)addr, uvpt[pn]&(PTE_SYSCALL|PTE_SHARE));
		if(r<0)
			panic("duppage():%e\n", r);
	}else if((uvpt[pn]&PTE_W)||(uvpt[pn]&PTE_COW)){
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
`copy_shared_pa​​ges`
```c
static int
copy_shared_pages(envid_t child)
{
	// LAB 5: Your code here.***************
	for (uintptr_t addr = 0; addr < UTOP;addr+=PGSIZE)
	{
		if((uvpd[PDX(addr)]&PTE_P)&&(uvpt[PGNUM(addr)]&PTE_P)
			&&(uvpt[PGNUM(addr)]&PTE_U)&&(uvpt[PGNUM(addr)]&PTE_SHARE)){
			int r = sys_page_map(0, (void *)addr, child, (void *)addr, uvpt[PGNUM(addr)] & (PTE_SYSCALL | PTE_SHARE));
			if(r<0)
				return r;
		}
	}
	return 0;
}
```