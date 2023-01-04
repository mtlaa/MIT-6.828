# Lab 4：抢占式多任务处理
# 引言
在本实验中，您将在多个同时活动的用户模式环境中实现抢占式多任务处理。

在 A 部分，您将为 JOS 添加多处理器支持，实现循环调度，并添加基本的环境管理系统调用（创建和销毁环境以及分配/映射内存的调用）。

在 B 部分，您将实现类 Unix 的 `fork()`，它允许用户模式环境创建其自身的副本。

最后，在 C 部分中，您将添加对进程间通信 (IPC) 的支持，允许不同的用户模式环境显式地相互通信和同步。您还将添加对硬件时钟中断和抢占的支持。

## 开始
把`lab3`分支合并到`origin/lab4`分支，其中包含以下几个新的源文件：
- `kern/cpu.h` 多处理器支持的内核私有定义
- `kern/mpconfig.c`读取多处理器配置的代码
- `kern/lapic.c`驱动每个处理器中本地 APIC 单元的内核代码
- `kern/mpentry.S` 非引导 CPU 的汇编语言入口代码
- `kern/spinlock.h` 自旋锁的内核私有定义，包括大内核锁
- `kern/spinlock.c`实现自旋锁的内核代码
- `kern/sched.c` 您将要实现的调度程序的代码框架

# Part A:多处理器支持和协作式多任务处理
在本实验的第一部分，您将首先扩展 JOS 以在多处理器系统上运行，然后实现一些新的 JOS 内核系统调用以允许用户级环境创建额外的新环境。您还将实施协作循环调度，允许内核在当前环境自愿放弃 CPU（或退出）时从一个环境切换到另一个环境。后面在Part C，您将实现抢占式调度，它允许内核在经过特定时间后从环境中重新控制 CPU，即使环境不合作也是如此。

## 多处理器支持
我们将使 JOS 支持“对称多处理”（SMP），这是一种多处理器模型，其中所有 CPU 对系统资源（如内存和 I/O 总线）具有同等的访问权限。虽然所有 CPU 在 SMP 中的功能都相同，但在引导过程中它们可以分为两种类型：`引导处理器 (BSP)` 负责初始化系统和引导操作系统；只有在操作系统启动并运行后，`应用处理器 (AP)` 才会被 BSP 激活。哪个处理器是BSP是由硬件和BIOS决定的。到目前为止，所有现有的 JOS 代码都已在 BSP 上运行。

在 SMP 系统中，每个 CPU 都有一个伴随的本地 APIC (`LAPIC`) 单元。LAPIC 单元负责在整个系统中传递中断。LAPIC 还为其连接的 CPU 提供唯一标识符。在本实验中，我们使用 LAPIC 单元的以下基本功能（在`kern/lapic.c` 中）：
- 读取 LAPIC 标识符 (APIC ID) 以了解我们的代码当前运行在哪个 CPU 上（参见`cpunum()`）。
- 将`STARTUP`处理器间中断 (IPI) 从 BSP 发送到 AP 以启动其他 CPU（参见 `lapic_startap()`）。
- 在 Part C，我们对 LAPIC 的内置定时器进行编程以触发时钟中断以支持抢占式多任务处理（请参阅 `lapic_init()`）。

处理器使用 内存映射I/O (MMIO) 访问其 LAPIC。在 MMIO 中，一部分物理内存被硬连线到某些 I/O 设备的寄存器，因此通常用于访问内存的 load/store 指令可用于访问设备寄存器。您已经在物理地址 `0xA0000`处看到一个 IO hole（我们使用它来写入 VGA 显示缓冲区）。LAPIC 位于一个从物理地址 `0xFE000000`（比 4GB 少 32MB）开始的 hole 中，因此我们在 `KERNBASE` 使用我们通常的直接映射访问它太高了。JOS 虚拟内存映射在`MMIOBASE`留下 4MB 的空隙所以我们有一个地方可以像这样映射设备。由于后面的实验引入了更多的 MMIO 区域，您将编写一个简单的函数来从该区域分配空间并将设备内存映射到它。

> **Exercise 1** 在 `kern/pmap.c` 中实现 `mmio_map_region`。要了解它是如何使用的，请查看 `kern/lapic.c` 中 `lapic_init` 的开头。在运行 `mmio_map_region` 的测试之前，您还必须完成下一个练习。

### 应用处理器引导程序
在启动 AP 之前，BSP 应该首先收集有关多处理器系统的信息，例如 CPU 总数、它们的 APIC ID 和 LAPIC 单元的 MMIO 地址。 `kern/mpconfig.c` 中的 `mp_init()` 函数通过读取驻留在 BIOS 内存区域中的 MP 配置表来检索此信息。

`boot_aps()`函数（在`kern/init.c`中）驱动 AP 引导过程。AP 在实模式下启动，很像引导加载程序在`boot/boot.S`中启动的方式，因此`boot_aps()` 将 AP 入口代码 ( `kern/mpentry.S` ) 复制到在实模式下可寻址的内存位置。与引导加载程序不同，我们可以控制 AP 从何处开始执行代码；我们将入口代码复制到`0x7000` ( `MPENTRY_PADDR`)，但是 640KB 以下的任何未使用的、页面对齐的物理地址都可以使用。

之后，`boot_aps()` 通过向相应 AP 的 LAPIC 单元发送 `STARTUP` IPI 以及 AP 应开始运行其入口代码（在我们的例子中为 `MPENTRY_PADDR`）的初始 `CS:IP` 地址，一个接一个地激活 AP。 `kern/mpentry.S` 中的入口代码与 `boot/boot.S` 中的入口代码非常相似。经过一些简单的设置后，它将 AP 置于启用分页的保护模式，然后调用 C 设置例程 `mp_main()`（也在 `kern/init.c` 中）。 `boot_aps()` 等待 AP 在其 `struct CpuInfo` 的 `cpu_status` 字段为 `CPU_STARTED` 标志，然后继续唤醒下一个。

> **Exercise 2** 阅读 `kern/init.c` 中的 `boot_aps()` 和 `mp_main()`，以及 `kern/mpentry.S` 中的汇编代码。确保您了解 AP 引导期间的控制流传输。然后修改 `kern/pmap.c` 中 `page_init()` 的实现，避免将 `MPENTRY_PADDR` 处的页面添加到空闲列表中，这样我们就可以安全地在该物理地址复制和运行 AP 引导程序代码。您的代码应该通过更新的 `check_page_free_list()` 测试（但可能无法通过更新的 `check_kern_pgdir()` 测试，我们将很快修复）。

> **Question**
> 1. 将 `kern/mpentry.S` 与 `boot/boot.S` 比较。请记住，`kern/mpentry.S` 被编译并链接到 `KERNBASE` 之上，就像内核中的其他所有内容一样，宏 `MPBOOTPHYS` 的目的是什么？为什么在 `kern/mpentry.S` 中有必要，而在 `boot/boot.S` 中没有？换句话说，如果在 `kern/mpentry.S` 中省略它会出什么问题？     
>提示：回想一下我们在 lab 1 中讨论过的链接地址和加载地址之间的区别。

### 每个CPU的状态和初始化
在编写多处理器操作系统时，区分每个处理器私有的 CPU 状态和整个系统共享的全局状态很重要。 `kern/cpu.h` 定义了每个 CPU 的大部分状态，包括存储每个 CPU 变量的 `struct CpuInfo`。 `cpunum()` 总是返回调用它的 CPU 的 ID，它可以用作 `cpus` 等数组的索引。或者，宏 `thiscpu` 是当前 CPU 的 `struct CpuInfo` 的指针。

以下是您应该注意的每个 CPU 状态：
- **每 CPU 的内核堆栈**        
  因为多个 CPU 可以同时陷入内核，所以我们需要为每个处理器提供一个单独的内核堆栈，以防止它们相互干扰执行。数组 `percpu_kstacks[NCPU][KSTKSIZE]` 为 NCPU 的内核堆栈保留空间。        
  在实验 2 中，您将`bootstack`所指的物理内存映射为位于`KSTACKTOP`正下方的BSP内核堆栈。同样，在本实验中，您将把每个 CPU 的内核堆栈映射到这个区域，保护页充当它们之间的缓冲区。 CPU 0 的堆栈仍然会从 `KSTACKTOP` 向下增长； CPU 1 的堆栈将从 CPU 0 堆栈底部下方的 `KSTKGAP` 字节开始，依此类推。 `inc/memlayout.h` 显示映射布局。
- **每 CPU TSS(任务状态段) 和 TSS 描述符**                 
  还需要每个 CPU 任务状态段 (TSS) 以指定每个 CPU 的内核堆栈所在的位置。 CPU i 的 TSS 存储在 `cpus[i].cpu_ts` 中，相应的 TSS 描述符定义在 GDT 条目 `gdt[(GD_TSS0 >> 3) + i]` 中。 `kern/trap.c` 中定义的全局 `ts` 变量将不再有用。
- **每 CPU 当前环境指针**             
  由于每个 CPU 可以同时运行不同的用户进程，我们重新定义了符号 `curenv` 来指代 `cpus[cpunum()].cpu_env`（或 `thiscpu->cpu_env`），它指向当前 CPU 上当前执行的环境。
- **每 CPU 系统寄存器**                
  所有寄存器，包括系统寄存器，都是 CPU 私有的。因此，初始化这些寄存器的指令，如`lcr3()`、`ltr()`、`lgdt()`、`lidt()`等，必须在每个CPU上执行一次。为此定义了函数 `env_init_percpu()` 和 `trap_init_percpu()`。                
  除此之外，如果您在您的解决方案中添加了任何额外的每个 CPU 状态或执行了任何额外的特定于 CPU 的初始化（例如，在 CPU 寄存器中设置新位）以挑战早期实验室中的问题，请务必复制它们在每个 CPU 上！

> **Exercise 3** 修改 `mem_init_mp()`（在 `kern/pmap.c` 中）以映射从 `KSTACKTOP` 开始的每个 CPU 堆栈，如 `inc/memlayout.h` 中所示。每个堆栈的大小是 `KSTKSIZE` 字节加上未映射保护页的 `KSTKGAP` 字节。您的代码应该通过 `check_kern_pgdir()` 中的新检查。

> **Exercise 4** `trap_init_percpu()` (`kern/trap.c`) 中的代码为 BSP 初始化 TSS 和 TSS 描述符。它在实验 3 中有效，但在其他 CPU 上运行时不正确。更改代码，使其可以在所有 CPU 上工作。 （注意：您的新代码不应再使用全局 `ts` 变量。） 

完成上述练习后，使用 `make qemu CPUS=4`（或 `make qemu-nox CPUS=4`）在具有 4 个 CPU 的 QEMU 中运行 JOS，您应该看到如下输出：
```
...
Physical memory: 66556K available, base = 640K, extended = 65532K
check_page_alloc() succeeded!
check_page() succeeded!
check_kern_pgdir() succeeded!
check_page_installed_pgdir() succeeded!
SMP: CPU 0 found 4 CPU(s)
enabled interrupts: 1 2
SMP: CPU 1 starting
SMP: CPU 2 starting
SMP: CPU 3 starting
```

### 锁
我们当前的代码在 `mp_main()` 中初始化 AP 后就会“自旋”（spin）。在让 AP 更进一步之前，我们首先需要解决多个 CPU 同时运行内核代码时的竞争条件。实现这一点的最简单方法是使用大内核锁。大内核锁是一个单一的全局锁，每当环境进入内核模式时就会持有，并在环境返回用户模式时释放。在此模型中，用户模式下的环境可以在任何可用的 CPU 上并发运行，但内核模式下只能运行一个环境；任何其他试图进入内核模式的环境都将被迫等待。

`kern/spinlock.h` 声明了大内核锁，即`kernel_lock`。它还提供了 `lock_kernel()` 和 `unlock_kernel()` 以获取和释放锁。您应该在四个位置应用大内核锁：
- 在 `i386_init()` 中，在 BSP 唤醒其他 CPU 之前获取锁。
- 在`mp_main()`中，初始化AP后获取锁，然后调用`sched_yield()`在这个AP上开始运行环境。
- 在 `trap()` 中，从用户模式陷入时获取锁。要确定trap是发生在用户模式还是内核模式，请检查 `tf_cs` 的低位。
- 在 `env_run()` 中，在切换到用户模式之前立即释放锁。不要太早或太晚这样做，否则您将遇到竞争或死锁。

> **Exercise 5** 如上所述，通过在适当的位置调用 `lock_kernel()` 和 `unlock_kernel()` 来应用大内核锁。

现在还不能检查练习5是否正确，在下一个练习中实现调度程序后才可以检查。

> **Question 2** 似乎使用大内核锁可以保证一次只有一个 CPU 可以运行内核代码。为什么我们仍然需要为每个 CPU 提供单独的内核堆栈？描述一个使用共享内核栈会出错的场景，即使有大内核锁的保护。

## 循环调度
您在本实验中的下一个任务是更改 JOS 内核，以便它可以以“循环”方式在多个环境之间切换。 JOS 中的循环调度工作如下：
- `kern/sched.c` 中的函数 `sched_yield()` 负责选择一个新的环境来运行。它以循环方式顺序搜索 `envs[]` 数组，每次搜索起始位置从先前运行的环境之后开始（如果没有先前运行的环境，则从数组的开头开始），选择它找到的第一个状态为 `ENV_RUNNABLE` 的环境（请参阅`inc/env.h`)，并调用 `env_run()` 跳转到该环境。
- `sched_yield()` 绝不能同时在两个 CPU 上运行相同的环境。它可以判断环境当前正在某个 CPU（可能是当前 CPU）上运行，因为该环境的状态将为 `ENV_RUNNING`。
- 我们为您实现了一个新的系统调用，`sys_yield()`，用户环境可以调用它来调用内核的 `sched_yield()` 函数，从而主动放弃 CPU ，让给其他环境。

> **Exercise 6** 如上所述，在 `sched_yield()` 中实现循环调度。不要忘记修改 `syscall()` 以分派 `sys_yield()`系统调用。                 
> 确保在 `mp_main` 中调用 `sched_yield()`。                           
> 修改 `kern/init.c` 以创建三个（或更多！）运行程序 `user/yield.c` 的环境。                   
> 运行 `make qemu`。在终止之前，您应该看到环境在彼此之间来回切换五次，如下所示。                  
> 也可以指定 CPU 数量进行测试：`make qemu CPUS=2`。                 
> ```
>...
>Hello, I am environment 00001000.
>Hello, I am environment 00001001.
>Hello, I am environment 00001002.
>Back in environment 00001000, iteration 0.
>Back in environment 00001001, iteration 0.
>Back in environment 00001002, iteration 0.
>Back in environment 00001000, iteration 1.
>Back in environment 00001001, iteration 1.
>Back in environment 00001002, iteration 1.
>...
>```
>`yield.c` 程序退出后，系统中将没有可运行的环境，调度程序应该调用 JOS 内核监视器。如果上述任何一种情况都没有发生，请在继续之前修复您的代码。

> **Question**            
> 3. 在您的 `env_run()` 实现中，您应该调用 `lcr3()`。在调用 `lcr3()` 之前和之后，您的代码引用（至少应该引用）变量 `e`，即 `env_run` 的参数。加载 `%cr3` 寄存器后，MMU 使用的寻址上下文会立即更改。但是虚拟地址（即 `e`）相对于给定的地址上下文具有——地址上下文指定虚拟地址映射到的物理地址。为什么在寻址切换之前和之后都可以解引用指针 `e`？                
> 4. 每当内核从一个环境切换到另一个环境时，它必须确保保存旧环境的寄存器，以便以后可以正确恢复它们。为什么？这发生在哪里？

## 环境创建的系统调用
虽然你的内核现在可以在多个用户级环境之间运行和切换，但它仍然仅限于内核最初设置的运行环境。您现在将实现必要的 JOS 系统调用，以允许用户环境创建和启动其他新用户环境。

Unix 提供 `fork()` 系统调用作为其进程创建原语。 Unix `fork()` 复制调用进程（父进程）的整个地址空间来创建一个新进程（子进程）。从用户空间观察到的两个对象之间的唯一区别是它们的进程 ID 和父进程 ID（由 `getpid` 和 `getppid` 返回）。在父进程中，`fork()` 返回子进程的 ID，而在子进程中，`fork()` 返回 0。默认情况下，每个进程都有自己的私有地址空间，两个进程对内存的修改对另一个进程是不可见的。

您将提供一组不同的、更原始的 JOS 系统调用来创建新的用户模式环境。通过这些系统调用，除了其他类型的环境创建之外，您还可以完全在用户空间中实现类似 Unix 的 `fork()`。您将为 JOS 编写的新系统调用如下：
- `sys_exofork`           
  这个系统调用创建了一个几乎是空白的新环境：在其地址空间的用户部分没有任何映射，并且它不可运行。在 `sys_exofork` 调用时，新环境将具有与父环境相同的注册状态。在父环境中，`sys_exofork` 将返回新创建环境的 `envid_t`（如果环境分配失败，则返回负错误代码）。然而，在子环境中，它将返回 0。（因为子环境开始时被标记为不可运行，所以 `sys_exofork` 实际上不会在子环境中返回，直到父环境标记子环境可运行后才允许这样做）
- `sys_env_set_status`               
  将指定环境的状态设置为 `ENV_RUNNABLE` 或 `ENV_NOT_RUNNABLE`。一旦其地址空间和寄存器状态已完全初始化,该系统调用通常用于标记新环境准备好运行。
- `sys_page_alloc`           
  分配一页物理内存并将其映射到给定环境地址空间中的给定虚拟地址。
- `sys_page_map`         
  将页面映射（不是页面的内容！）从一个环境的地址空间复制到另一个环境，保留内存共享安排，以便新旧映射都引用物理内存的同一页。(也就是让两个环境共享同一个物理页面)
- `sys_page_unmap`         
  取消映射到给定环境中给定虚拟地址的页面。

对于上面所有接受环境 ID 的系统调用，JOS 内核支持值 0 表示“当前环境”的约定。这个约定由 `kern/env.c` 中的 `envid2env()` 实现。

我们在测试程序 `user/dumbfork.c` 中提供了一个非常原始的类 Unix `fork()` 实现。该测试程序使用上述系统调用来创建和运行具有其自身地址空间副本的子环境。两个环境然后像上一个练习一样使用 `sys_yield` 来回切换。父级在 10 次迭代后退出，而子级在 20 次迭代后退出。

> **Exercise 7** 在 `kern/syscall.c` 中实现上面描述的系统调用，并确保 `syscall()` 调用它们。您将需要使用 `kern/pmap.c` 和 `kern/env.c` 中的各种函数，尤其是 `envid2env()`。现在，无论何时调用 `envid2env()`，在 `checkperm` 参数中传递 1。确保检查任何无效的系统调用参数，在这种情况下返回 `-E_INVAL`。使用 `user/dumbfork` 测试你的 JOS 内核并确保它在继续之前正常工作。

这就完成了实验的 A 部分；确保它在运行 `make grade` 时通过了所有 A 部分测试。如果您试图找出特定测试用例失败的原因，请运行 `./grade-lab4 -v`，它将向您显示内核构建的输出和 QEMU 为每个测试运行，直到测试失败。当测试失败时，脚本将停止，然后您可以检查 `jos.out` 以查看内核实际打印的内容。