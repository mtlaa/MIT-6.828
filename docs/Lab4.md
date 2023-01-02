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

## 应用处理器引导程序
在启动 AP 之前，BSP 应该首先收集有关多处理器系统的信息，例如 CPU 总数、它们的 APIC ID 和 LAPIC 单元的 MMIO 地址。 `kern/mpconfig.c` 中的 `mp_init()` 函数通过读取驻留在 BIOS 内存区域中的 MP 配置表来检索此信息。

`boot_aps()`函数（在`kern/init.c`中）驱动 AP 引导过程。AP 在实模式下启动，很像引导加载程序在`boot/boot.S`中启动的方式，因此`boot_aps()` 将 AP 入口代码 ( `kern/mpentry.S` ) 复制到在实模式下可寻址的内存位置。与引导加载程序不同，我们可以控制 AP 从何处开始执行代码；我们将入口代码复制到`0x7000` ( `MPENTRY_PADDR`)，但是 640KB 以下的任何未使用的、页面对齐的物理地址都可以使用。

之后，`boot_aps()` 通过向相应 AP 的 LAPIC 单元发送 `STARTUP` IPI 以及 AP 应开始运行其入口代码（在我们的例子中为 `MPENTRY_PADDR`）的初始 `CS:IP` 地址，一个接一个地激活 AP。 `kern/mpentry.S` 中的入口代码与 `boot/boot.S` 中的入口代码非常相似。经过一些简单的设置后，它将 AP 置于启用分页的保护模式，然后调用 C 设置例程 `mp_main()`（也在 `kern/init.c` 中）。 `boot_aps()` 等待 AP 在其 `struct CpuInfo` 的 `cpu_status` 字段为 `CPU_STARTED` 标志，然后继续唤醒下一个。

> **Exercise 2** 阅读 `kern/init.c` 中的 `boot_aps()` 和 `mp_main()`，以及 `kern/mpentry.S` 中的汇编代码。确保您了解 AP 引导期间的控制流传输。然后修改 `kern/pmap.c` 中 `page_init()` 的实现，避免将 `MPENTRY_PADDR` 处的页面添加到空闲列表中，这样我们就可以安全地在该物理地址复制和运行 AP 引导程序代码。您的代码应该通过更新的 `check_page_free_list()` 测试（但可能无法通过更新的 `check_kern_pgdir()` 测试，我们将很快修复）。

> **Question**
> 1. 将 `kern/mpentry.S` 与 `boot/boot.S` 比较。请记住，`kern/mpentry.S` 被编译并链接到 `KERNBASE` 之上，就像内核中的其他所有内容一样，宏 `MPBOOTPHYS` 的目的是什么？为什么在 `kern/mpentry.S` 中有必要，而在 `boot/boot.S` 中没有？换句话说，如果在 `kern/mpentry.S` 中省略它会出什么问题？     
>提示：回想一下我们在 lab 1 中讨论过的链接地址和加载地址之间的区别。

## 每个CPU的状态和初始化
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

## 锁定