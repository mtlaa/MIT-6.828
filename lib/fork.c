// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	// cprintf("jin le pgfault\n");
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
	// if((err&FEC_WR)==0||(uvpt[PGNUM(addr)]&PTE_COW)==0)
	// 	panic("pgfault():not a write fault or not a COW page\n");
	if((err&FEC_PR)==0)
		panic("pgfault():not a write fault\n");
	if((uvpt[PGNUM(addr)]&PTE_COW)==0)
		panic("pgfault():not a COW page\n");

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

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
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
		r = sys_page_map(0, (void *)addr, envid, (void *)addr, PTE_SYSCALL);
		if (r < 0)
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

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
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
	// for (uintptr_t addr = 0; addr < USTACKTOP;addr+=PGSIZE)
	// {
	// 	if (uvpd[PDX(addr)] & PTE_P && uvpt[PGNUM(addr)] & PTE_P)
	// 	{
	// 		if(duppage(child_id,PGNUM(addr))<0)
	// 			panic("in fork(), duppage() error.\n");
	// 	}
	// }

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

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
