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
