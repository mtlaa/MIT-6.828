# Lab 3: 用户环境

# 引言
在本实验中，您将实现运行受保护的用户模式环境（即“进程”）所需的基本内核工具。您将增强 JOS 内核设置数据结构以跟踪用户环境、创建单个用户环境、将程序映像加载到其中并开始运行。您还将使 JOS 内核处理用户环境运行时的任何系统调用并处理它导致的任何其他异常。

注意：在本实验中，环境(*environment*)和进程(*process*)这两个术语是可以互换的——它们都指的是允许你运行的程序的抽象。我们引入术语“环境”而不是传统术语“进程”是为了强调 JOS 环境和 UNIX 进程提供不同的接口，并且不提供相同的语义。

## 开始
合并`origin/lab3`分支，Lab 3 包含一些新的源文件，你应该浏览它们：
* `inc/env.h`	    用户模式环境的公共定义    
        `trap.h`	陷阱(陷入，trap)处理的公共定义    
        `syscall.h`	从用户环境到内核的系统调用的公共定义    
        `lib.h`	    用户模式支持库的公共定义   
* `kern/env.h`	    用户模式环境的内核私有定义      
        `env.c`	    实现用户模式环境的内核代码     
        `trap.h`	陷阱(陷入，trap)处理的内核私有定义     
        `trap.c`	陷阱(陷入，trap)处理的代码      
        `trapentry.S`	汇编语言陷阱处理程序入口点     
        `syscall.h`	系统调用的内核私有定义       
        `syscall.c`	实现系统调用的代码      
* `lib/Makefrag`	用于构建用户模式库`obj/lib/libjos.a`的 `Makefile` 片段      
    `entry.S`	用户环境的汇编语言入口点     
    `libmain.c`	从 `entry.S` 调用的用户模式库设置代码     
    `syscall.c`	用户模式系统调用的存根函数（stub function 就是存根函数，也就是模拟函数：在你真正实现函数功能前，你将结果返回，模拟真实的函数调用。）    
    `console.c`	提供控制台 I/O 的`putchar` 和 `getchar` 的用户模式实现     
    `exit.c`	`exit` 的用户模式实现    
    `panic.c`	`panic` 的用户模式实现    

## 实验要求
这个实验分为A、B两部分。先完成 Part A 的代码，在完成 Part B 的代码。

与实验 2 一样，您需要完成实验中描述的所有常规练习和至少一个挑战题。

## 内联汇编
在本实验中，您可能会发现 GCC 的内联汇编语言（Inline Assembly）功能很有用，尽管也可以在不使用它的情况下完成本实验。但至少，您需要能够理解我们提供给您的源代码中已经存在的内联汇编语言（`asm`语句）的片段。您可以在课程参考资料页面上找到有关 [GCC 内联汇编语言的信息](https://pdos.csail.mit.edu/6.828/2018/reference.html)。

# Part A: 用户环境和异常处理
新包含的文件 `inc/env.h` 中包含 JOS 中用户环境的基本定义，现在阅读它。内核使用 `Env` 数据结构来跟踪每个用户环境。在本实验中，您最初将只创建一个环境，但您需要设计 JOS 内核以支持多环境；lab 4 将通过允许用户环境`fork`其他环境来利用此功能。

正如您在 `kern/env.c` 中看到的，内核维护三个与环境有关的主要全局变量：
```c
struct Env *envs = NULL;		// 所有环境
struct Env *curenv = NULL;		// 当前环境
static struct Env *env_free_list;	// 空闲环境列表
```

一旦 JOS 启动并运行，`envs` 指针就会指向一个表示系统中所有环境的 `Env` 结构数组。在我们的设计中，JOS 内核将支持最多同时运行 `NENV` 个环境，尽管在任何给定时间运行的环境通常要少得多（`NENV` 是 `inc/env.h` 中定义的常量）。一旦分配，`envs`数组将会包含`NENV` 个可能环境的每个 `Env` 数据结构的单个实例。

JOS 内核将所有不活动的 `Env` 结构保存在 `env_free_list` 中。这种设计允许轻松分配和释放环境，因为它们只需添加到空闲列表或从空闲列表中删除。

内核使用 `curenv` 指针在任何给定时间跟踪当前执行的环境。在启动期间，运行第一个环境之前，`curenv` 最初设置为 `NULL`。

## 环境状态
`Env` 结构在 `inc/env.h` 中定义如下（在未来的实验中会添加更多字段）：
```c
struct Env {
	struct Trapframe env_tf;	// Saved registers
	struct Env *env_link;		// Next free Env
	envid_t env_id;			// Unique environment identifier
	envid_t env_parent_id;		// env_id of this env's parent
	enum EnvType env_type;		// Indicates special system environments
	unsigned env_status;		// Status of the environment
	uint32_t env_runs;		// Number of times environment has run

	// Address space
	pde_t *env_pgdir;		// Kernel virtual address of page dir
};
```

以下是 `Env` 中各字段的用途：    
* `env_tf`：`Trapframe`结构在 `inc/trap.h` 中定义，在环境未运行时(即当内核或其他环境正在运行时)保存环境的寄存器值。当从用户模式切换到内核模式时，内核会保存这些，以便以后可以从中断的地方恢复环境。     
* `env_link`：这是 `env_free_list` 中下一个空闲环境 `Env` 的指针。 `env_free_list` 指向列表中的第一个空闲环境。    
* `env_id`：内核在此处存储一个值，该值唯一标识当前使用此 `Env` 结构的环境（即，使用 `envs` 数组中的此特定插槽）。该用户环境终止后，内核可能会将相同的 `Env` 结构重新分配给不同的环境 --- 但新环境将具有与旧环境不同的 `env_id`，即使新环境正在重新使用 `envs` 数组中的相同插槽。      
* `env_parent_id`：内核在此处存储创建此环境的环境的 `env_id`,即该环境的父环境的id。通过这种方式，环境可以形成“家谱”，这将有助于允许哪些环境对谁做什么的安全决策。     
* `env_type`：这用于区分特殊环境。对于大多数环境，它将是 `ENV_TYPE_USER`。我们将在以后的实验中为特殊系统服务环境介绍更多类型。     
* `env_status`：此变量包含以下值之一：
   * `ENV_FREE`:表示该 `Env` 结构处于非活动状态，因此位于 `env_free_list` 上。     
   * `ENV_RUNNABLE`:指示该 `Env` 结构代表正在等待上处理器运行的环境。（就绪态）   
   * `ENV_RUNNING`:指示该`Env`结构代表正在运行的环境。（运行态）     
   * `ENV_NOT_RUNNABLE`:指示该 `Env` 结构代表当前正处于活动状态的环境，但它当前尚未准备好运行：例如，因为它正在等待来自另一个环境的进程间通信(IPC)。（阻塞态、等待态）       
   * `ENV_DYING`:指示该 `Env` 结构代表一个僵尸环境。僵尸环境将在下一次陷入内核时被释放。在 Lab 4 之前我们不会使用这个标志。    
 * `env_pgdir`：这个变量保存了这个环境的页目录的内核虚拟地址。    
  
与 Unix 进程一样，JOS 环境结合了“线程”和“地址空间”的概念。线程主要由保存的寄存器（`env_tf` 字段）定义，地址空间由 `env_pgdir` 指向的页目录和页表定义。要运行环境，内核必须使用保存的寄存器和适当的地址空间来设置 CPU。

我们的 `struct Env` 类似于 xv6 中的 `struct proc`。两种结构都在 `Trapframe` 结构中保存环境（即进程）的用户模式寄存器状态。在 JOS 中，各个环境不像 xv6 中的进程那样拥有自己的内核堆栈。内核中一次只能有一个活动的 JOS 环境，因此 JOS 只需要一个内核堆栈。

## 分配环境数组
在实验 2 中，您在 `mem_init()` 中为 `pages[]` 数组分配了内存，这是内核用来跟踪哪些页是空闲的，哪些页是空闲的。您现在需要进一步修改 `mem_init()` 以分配一个类似的 `Env` 结构数组，称为 `envs`。

> **练习1** 修改 `kern/pmap.c` 中的 `mem_init()` 以分配和映射 `envs` 数组。该数组由`NENV` 个 `Env` 结构的实例组成，就像您分配 `pages` 数组的方式一样。与 `pages` 数组一样，内存支持环境也应该在 `UENVS`（在 `inc/memlayout.h` 中定义）以用户只读方式映射，以便用户进程可以从该数组中读取。

## 创建和运行环境
您现在将在 `kern/env.c` 中编写运行用户环境所需的代码。因为我们还没有文件系统，所以我们将设置内核以加载嵌入内核本身的静态二进制镜像。 JOS 将此二进制文件作为 ELF 可执行镜像嵌入内核中。

Lab 3 的`GNUmakefile` 在 `obj/user/` 目录中生成许多二进制镜像。如果您查看 `kern/Makefrag`，您会注意到一些将这些二进制文件直接“链接”到内核可执行文件中的操作，就好像它们是 `.o` 文件一样。链接器命令行上的 `-b binary`选项导致这些文件作为“原始”未解释的二进制文件而不是编译器生成的常规 `.o` 文件链接。（就链接器而言，这些文件根本不必是 ELF 镜像——它们可以是任何东西，例如文本文件或图片！）如果您在构建内核后查看 `obj/kern/kernel.sym`，您会注意到，链接器“神奇地”生成了许多名称晦涩的有趣符号，例如 `_binary_obj_user_hello_start`、`_binary_obj_user_hello_end` 和 `_binary_obj_user_hello_size`。链接器通过修改二进制文件的文件名来生成这些符号名；这些符号为常规内核代码提供了一种引用嵌入式二进制文件的方法。

在 `kern/init.c` 中的 `i386_init()` 中，您将看到在环境中运行这些二进制镜像之一的代码。但是，设置用户环境的关键函数并不完整；您需要填写它们。

> **练习2** 