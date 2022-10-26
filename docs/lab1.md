# [Lab1: Booting a PC](https://pdos.csail.mit.edu/6.828/2018/labs/lab1/)


## 引言

### 这个实验分为三部分：
* 第一部分主要是熟悉x86汇编语言、QEMU x86模拟器和PC的启动引导程序。
* 第二部分研究位于`lab/boot`目录下的6.828内核引导程序。
* 第三部分研究6.828内核的模板JOS，位于`lab/kernel`目录中。

# Part 1: PC Bootstrap
第一个练习的目的是介绍x86汇编语言和PC引导过程，并且使用QEMU和QEMU/GDB进行调试。本实验的这个部分不用写任何代码，但应该仔细阅读这些代码并回答问题。

## 开始使用x86汇编语言
如果你还不熟悉汇编语言，在这节你可以快速的熟悉它。

> **练习1**  熟悉[6.828参考页面](https://pdos.csail.mit.edu/6.828/2018/reference.html)上的汇编语言资料。你现在不必阅读它们，但是在阅读和编写 x86汇编时，几乎肯定需要参考其中的一些内容。  
建议阅读 [Brennan's Guide to Inline Assembly](http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html)的 **The Syntax** 部分，它很好地描述了我们将在 JOS 中的 GNU 汇编程序中使用的 AT & T 汇编语法。

## 模拟 x86

实验不在一个真实的PC上开发操作系统，而是在模拟器中，这样可以简化调试。  

6.828 使用 [QEMU 模拟器](http://www.qemu.org/)，这是一个相对快速的模拟器。虽然 QEMU 的内置监视器只提供有限的调试支持，但 QEMU 可以作为 [GNU 调试器](http://www.gnu.org/software/gdb/)(GDB)的远程调试目标，我们将在本实验室中使用 GDB 来逐步完成早期引导过程。

接下来是 **qemu** 的安装，在实验环境配置中已经完成，不在赘述。

>退出qemu：**`Ctrl + a`** ，然后按 **`x`**

在安装完成后只有两个命令可以用：
* `help`
* `kerninfo`
```bash
K> help
help - Display this list of commands
kerninfo - Display information about the kernel
K> kerninfo
Special kernel symbols:
  _start                  0010000c (phys)
  entry  f010000c (virt)  0010000c (phys)
  etext  f01019e9 (virt)  001019e9 (phys)
  edata  f0113060 (virt)  00113060 (phys)
  end    f01136a0 (virt)  001136a0 (phys)
Kernel executable memory footprint: 78KB
```
## PC 的物理地址空间
现在我们将深入了解更多关于 PC 如何启动的细节。PC的物理地址空间是硬连接的，具有以下总体布局:
```
+------------------+  <- 0xFFFFFFFF (4GB)
|      32-bit      |
|  memory mapped   |
|     devices      |
|                  |
/\/\/\/\/\/\/\/\/\/\

/\/\/\/\/\/\/\/\/\/\
|                  |
|      Unused      |
|                  |
+------------------+  <- depends on amount of RAM
|                  |
|                  |
| Extended Memory  |
|                  |
|                  |
+------------------+  <- 0x00100000 (1MB)
|     BIOS ROM     |
+------------------+  <- 0x000F0000 (960KB)
|  16-bit devices, |
|  expansion ROMs  |
+------------------+  <- 0x000C0000 (768KB)
|   VGA Display    |
+------------------+  <- 0x000A0000 (640KB)
|                  |
|    Low Memory    |
|                  |
+------------------+  <- 0x00000000
```
第一代 PC 基于16位 Intel 8088处理器，只能寻址1 MB 的物理内存。因此，早期 PC 的物理地址空间将以0x00000000开始，但以`0x000FFFFF` 而不是`0xFFFFFFFF` 结束。标记为 “Low Memory” 的640kb 区域是早期个人电脑可以使用的唯一RAM ，事实上，最早期的个人电脑只能配置16kB、32kB 或64kb 的内存！

从`0x000A0000`到`0x000FFFF` 的 384kB 区域被硬件保留用于特殊用途，如显存和固件。这个保留区域中最重要的部分是基本输入/输出系统(Basic Input/Output System，BIOS) ，它占用从`0x000F0000`到`0x000FFFFF` 的64KB 区域。在早期PC中，BIOS被保存在真实的存储器(ROM)中，但是现在PC将 BIOS 保存在可更新的闪存中。BIOS 负责执行基本的系统初始化，比如激活显卡和检查内存。执行此初始化之后，BIOS 将从某个合适的位置(如软盘、硬盘、 CD-ROM 或网络)加载操作系统，并将机器的控制权传递给操作系统。

Intel 80286 和 Intel 80386 分别支持16MB和4GB物理地址空间。此时PC仍然保留了低于 1MB 物理地址空间的原始布局，以确保与现有软件的向下兼容。因此，现代PC的物理内存在`0x000A0000~0x00100000`有一个“hole”，而且内存被分为常规内存（conventional memory，前640KB，也叫低内存）和扩展内存（extended memory,0x00100000之后的内存）。此外，32位物理地址空间的最顶端的一些空间，现在通常被 BIOS 保留给32位 PCI 设备使用。

最新的x86处理器可以支持超过4GB 的物理内存，因此地址空间可以超过`0xFFFFFFFF`。但32位机器只支持4GB的直接寻址空间（2的32次方为4GB），所以要寻址超过4GB的内存，需要留出一些空间用来映射（间接寻址），这些空间通常设在32位可寻址空间的顶端（32-bit memory mapped devices）,这是第二个“hole”。

由于设计上的限制，JOS 将只使用物理内存的前256MB，并且假设我们只有32位物理内存空间。

## The ROM BIOS
这一部分将使用 QEMU 的调试工具来研究兼容 IA-32 的计算机如何启动。

打开两个终端，都`cd`到`lab`目录。第一个终端中输入`make qemu-gdb`,这将启动 QEMU，但是 QEMU 会在处理器执行第一条指令之前停止，并等待来自 GDB 的调试连接。第二个终端运行`make gdb`，可以看到：
```bash
mtlaa@DESKTOP-3IITF4D:~/6.828/lab$ make qemu-gdb
***
*** Now run 'make gdb'.
***
qemu-system-i386 -drive file=obj/kern/kernel.img,index=0,media=disk,format=raw -serial mon:stdio -gdb tcp::26000 -D qemu.log  -S
VNC server running on `127.0.0.1:5900'
```
```bash
mtlaa@DESKTOP-3IITF4D:~/6.828/lab$ make gdb
gdb -n -x .gdbinit
GNU gdb (Ubuntu 8.1.1-0ubuntu1) 8.1.1
Copyright (C) 2018 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word".
+ target remote localhost:26000
warning: No executable has been specified and target does not support
determining executable automatically.  Try using the "file" command.
warning: A handler for the OS ABI "GNU/Linux" is not built into this configuration
of GDB.  Attempting to continue with the default i8086 settings.

The target architecture is assumed to be i8086
[f000:fff0]    0xffff0: ljmp   $0xf000,$0xe05b
0x0000fff0 in ?? ()
+ symbol-file obj/kern/kernel
(gdb)
```
>我这里有两个警告，不知道对后续有没有影响。。。

```bash
[f000:fff0]    0xffff0: ljmp   $0xf000,$0xe05b
```
这一行是 GDB 对要执行的第一条指令（jmp）的反汇编。从这个输出可以得出以下结论:
* IBM PC 从物理地址`0x000ffff0`开始执行，该地址位于为 ROM BIOS 保留的64KB 区域的顶部。
* PC开始运行时`CS = 0xf000 and IP = 0xfff0`
  >CS和IP是8086CPU中两个关键的寄存器，它们指示了CPU当前要读取指令的地址。    
  `CS : 代码段寄存器；IP : 指令指针寄存器。`在8086机中，任意时刻，CPU将CS:IP指向的内容当作指令来执行。
  
  >CS可以看作基址寄存器，IP内存放指令的相对地址（偏移量）。CS中的地址左移4位后（末尾加4位0bit）与IP相加得到指令的地址。    
  左移4位是为了扩大寻址范围。    
  由此可得`jmp`的物理地址为`0x000ffff0`
* 要执行的第一条指令是`jmp`指令，它会通过设置寄存器的方式进行跳转，设置`CS=0xf000,IP=0xe05b`

为什么 QEMU 是这样开始执行的？因为这是英特尔8088处理器的方法，IBM 在他们最初的PC中使用了这个处理器。因为PC的 BIOS 是“硬连线”到物理地址范围0x000f0000-0x000ffff，这种设计确保 BIOS 总是在开机或任何系统重启后首先获得对机器的控制——这是至关重要的，因为在开机时，在机器的 RAM 中没有其他软件处理器可以执行。QEMU 模拟器带有自己的 BIOS，它将 BIOS 放在处理器的模拟物理地址空间中的这个位置。在处理器重置时，(模拟的)处理器进入实模式，并将 CS 设置为0xf000，将 IP 设置为0xfff0，因此执行从该(CS: IP)段地址开始。分段地址0xf000: fff0如何转换为物理地址？  **上面有讲**    

`0xffff0`是 BIOS ROM 内存区结束前的16个字节(0x100000)。BIOS 所做的第一件事就是向后 jmp 到 BIOS 中的一个前面的位置（BIOS ROM 区的低地址部分）。

> **练习2** 使用GDB的`si`(Step Instruction)命令跟踪ROM BIOS中的更多指令，并尝试猜测它可能在做什么。您可能需要查看[Phil Storrs I/O端口描述](http://web.archive.org/web/20040404164813/members.iweb.net.au/~pstorr/pcbook/book2/book2.htm)，以及[6.828参考资料页](https://pdos.csail.mit.edu/6.828/2018/reference.html)上的其他资料。无需弄清楚所有细节，只需大致了解BIOS首先在做什么。

当 BIOS 运行时，它设置一个中断描述符表并初始化各种设备，如 VGA 显示器。这就是在 QEMU 窗口中看到的`Starting SeaBIOS`消息的来源。

在初始化 PCI 总线和 BIOS 知道的所有重要设备之后，它将搜索可引导设备，如磁盘。最终，当它找到一个可引导磁盘时，BIOS 从磁盘中读取引导加载程序并将控制权转移给它。

# Part 2: The Boot Loader

磁盘分为扇区，每个扇区512B，是磁盘读写的最小单位。每个读写操作必须是一个或多个扇区大小，并在扇区边界上对齐。如果磁盘是可引导的，那么它的第一个扇区为引导扇区，存放引导程序。当BIOS找到一个引导磁盘时，会将引导扇区加载到物理地址`0x7c00`到`0x7dff`的内存中。然后使用`jmp`指令设置`CS:IP=0000:7c00`并将控制权转交给引导程序来执行引导。

以上为从软盘和硬盘的引导方式，从CD-ROM（光盘）引导更复杂。

对于6.828，将使用传统的从硬盘引导的机制。所以我们的引导程序最大只能是512B。引导程序由一个汇编语言源文件`boot/boot.S`和一个C语言源文件`boot/main.c`组成。仔细查看这些源文件，确保理解其中的内容。引导加载程序必须执行两个主要功能:
1. 首先，引导加载程序将处理器从实模式切换到32位保护模式，因为只有在这种模式下，软件才能访问处理器物理地址空间中超过1MB 的所有内存。(boot.S)
   > 实模式：CPU通电时默认进入的模式。寻址范围为20位，即1MB    
   保护模式：通过一系列设定转入保护模式。可寻址范围32位
2. 其次，从磁盘加载内核到内存。(main.c)

了解了引导加载程序的源代码之后，请查看文件 `obj/boot/boot.asm`。这个文件是我们的 `GNUmakefile` 在编译引导加载程序后创建的引导加载程序的反汇编。这个反汇编文件可以很容易地查看所有引导加载程序的代码在物理内存中的确切位置，并且可以更容易地跟踪在 GDB 中单步执行引导加载程序时发生的情况。同样，`obj/kern/kernel.asm` 包含 JOS 内核的反汇编，这对于调试通常很有用。

可以使用`b`命令在GDB中设置地址断点，例如`b *0x7c00`在地址0x7c00处设置断点。在断点处可以使用`c`命令使QEMU继续执行到下一个断点（或直到在 GDB 中按 Ctrl-C），使用`si N`可以继续执行N条指令。

要查看内存中的指令，可以使用 `x/i` 命令。该命令的语法为 `x/Ni ADDR`，其中 `N` 是要反汇编的连续指令数，`ADDR` 是开始反汇编的内存地址。

> **练习三** 熟悉[GDB命令](https://pdos.csail.mit.edu/6.828/2018/labguide.html)。    
> 在地址 0x7c00 处设置断点，该地址将加载引导扇区。继续执行直到该断点。跟踪 `boot/boot.S` 中的代码，使用源代码和反汇编文件 `obj/boot/boot.asm` 跟踪您所在的位置。还可以在 GDB 中使用 `x/i` 命令来反汇编引导加载程序中的指令序列，并将原始引导加载程序源代码与 `obj/boot/boot.asm` 和 GDB 中的反汇编进行比较。    
> 跟踪到 `boot/main.c` 中的 `bootmain()`，然后跟踪到 `readsect()`。确定与 `readsect()` 中的每个语句相对应的确切汇编指令。跟踪 `readsect()` 的其余部分并返回 `bootmain()`，并确定从磁盘读取内核剩余扇区的 for 循环的开始和结束。找出循环结束时将运行的代码，在此处设置断点，然后继续执行该断点。然后逐步完成引导加载程序的其余部分。

回答问题：
* 处理器在什么时候开始执行 32 位代码？究竟是什么导致从 16 位模式切换到 32 位模式？
  > 在地址`0x7c32`开始执行32位代码，这条指令是`mov    $0x10,%ax`。由指令`ljmp   $0x8,$0x7c32`跳转到32位代码区来切换32位模式。【汇编文件中`.code16/32`是告诉编译器接下来代码是16位还是32位】
* 引导加载程序执行的最后一条指令是什么，它刚刚加载的内核的第一条指令是什么？
  > 最后一条`0x7d6b:      call   *0x10018`。内核的第一条`0x10000c:    movw   $0x1234,0x472`。
* 内核的第一条指令在哪里？
  > `0x10000c`
* 引导加载程序如何决定它必须读取多少扇区才能从磁盘获取整个内核？它在哪里找到这些信息？
  > 通过ELF文件头获取内核的信息


## 加载内核
现在将在 `boot/main.c` 中更详细地查看引导加载程序的 C 语言部分。

> **练习四** 理解C语言中的指针。   
> 阅读 *The C Programming Language* 中的 5.1（指针和地址）到 5.5（字符指针和函数）。然后下载 [pointers.c](https://pdos.csail.mit.edu/6.828/2018/labs/lab1/pointers.c) 的代码，运行它，并确保您了解所有打印值的来源。特别是，确保您了解打印的第 1 行和第 6 行中的指针地址来自哪里，打印的第 2 到第 4 行中的所有值是如何到达那里的，以及为什么第 5 行中打印的值看似损坏。    
> 除非精通C语言，这个练习最好做一做。

要理解 `boot/main.c`，首先需要知道 ELF 二进制文件是什么。当编译和链接 C 程序（例如 JOS 内核）时，编译器会将每个 C 源 ('.c') 文件转换为一个目标 ('.o') 文件，其中包含二进制汇编语言指令。然后，链接器将所有编译的目标文件组合成一个二进制镜像，例如 `obj/kern/kernel`，在这种情况下，它是 ELF 格式的二进制文件，代表“可执行和可链接格式”。

有关此格式的完整信息可在我们的参考页面上的 [ELF 规范](https://pdos.csail.mit.edu/6.828/2018/readings/elf.pdf)中找到，但您无需在本课程中深入研究此格式的详细信息。

在6.828中，可以将 ELF 可执行文件视为带有加载信息的头部，后跟几个程序部分，每个部分都是加载到指定地址的内存中的连续代码或数据块。引导加载程序不会修改代码或数据；它将ELF到内存中并开始执行它。

ELF 二进制文件以一个固定长度的 ELF 头开始，然后是一个可变长度的程序标头，其中列出了要加载的每个程序段。这些 ELF 头文件的 C语言 定义在 `inc/elf.h` 中。我们感兴趣的程序部分是：
* `.text`：程序的可执行指令。
* `.rodata`：只读数据，例如 C 编译器生成的 ASCII 字符串常量。
* `.data`：数据部分保存程序的初始化数据，例如使用 `int x = 5;` 等初始化器声明的全局变量。

当链接器计算程序的内存布局时，它会在内存中紧跟 `.data` 的名为 `.bss` 的部分中为未初始化的全局变量（例如 `int x;`）保留空间。 C 要求“未初始化的”全局变量以零值开头。因此，无需在 ELF 二进制文件中存储 `.bss` 的内容；相反，链接器只记录 `.bss` 部分的地址和大小。加载程序或程序本身必须将 `.bss` 部分归零。

通过以下命令检查内核可执行文件中所有部分的名称、大小和链接地址的完整列表：`objdump -h obj/kern/kernel`

输入以上命令将看到比上面列出的更多的部分，但其他部分对我们并不重要。其他大多数是保存调试信息，这些信息通常包含在程序的可执行文件中，但不会由程序加载器加载到内存中。

请特别注意 `.text` 部分的“VMA”（链接地址）和“LMA”（加载地址）。一个部分的**加载地址**是该部分应该被加载到内存中的内存地址。

每个部分的**链接地址**是该部分期望执行的内存地址。链接器以各种方式对二进制文件中的链接地址进行编码，例如当代码需要全局变量的地址时，如果二进制文件从未链接的地址执行，则通常无法工作。（可以生成不包含任何此类绝对地址的与位置无关的代码。这在现代共享库中广泛使用，但它具有性能和复杂性成本，因此我们不会在 6.828 中使用它。）

**通常，链接地址和加载地址是相同的。**

引导加载程序使用 ELF 程序头来决定如何加载这些部分。程序头指定 ELF 对象的哪些部分要加载到内存中，以及每个部分的目标地址。可以用命令`objdump -x obj/kern/kernel`查看程序头。
```bash
Program Header:
    LOAD off    0x00001000 vaddr 0xf0100000 paddr 0x00100000 align 2**12
         filesz 0x0000759d memsz 0x0000759d flags r-x
    LOAD off    0x00009000 vaddr 0xf0108000 paddr 0x00108000 align 2**12
         filesz 0x0000b6a8 memsz 0x0000b6a8 flags rw-
   STACK off    0x00000000 vaddr 0x00000000 paddr 0x00000000 align 2**4
         filesz 0x00000000 memsz 0x00000000 flags rwx
```
其中需要加载到内存中的 ELF 对象区域是那些标记为“LOAD”的区域。给出了每个程序头的其他信息，例如虚拟地址（“vaddr”）、物理地址（“paddr”）和加载区域的大小（“memsz”和“filesz”）。

回到 `boot/main.c`，每个程序头的 `ph->p_pa` 字段包含段的目标物理地址。

BIOS 将引导扇区从地址 0x7c00 开始加载到内存中，因此这是引导扇区的加载地址。这也是引导扇区执行的地方，所以这也是它的链接地址。我们通过在 `boot/Makefrag` 中将 `-Ttext 0x7C00` 传递给链接器来设置链接地址，因此链接器将在生成的代码中生成正确的内存地址。

> **练习五** 再次跟踪引导加载程序的前几条指令，并确定如果引导加载程序的链接地址错误，第一条指令是会“中断”还是错误的运行。   
> 将`boot/Makefrag`中的链接地址`-Ttext 0x7C00`改成错误的，运行`make clean`，用`make`重新编译，再次跟踪引导程序看看会发生什么。不要忘记将链接地址更改回来，然后再次清理并且重新编译！

不同于引导程序，内核的加载地址和链接地址不同：内核告诉引导加载程序将其加载到低地址，但它期望从高地址开始执行。

ELF头部中还包含一个重要的字段`e_entry`，该字段保存程序入口的链接地址：程序代码开始执行的内存地址。使用命令`objdump -f obj/kern/kernel`查看内核的入口`start address 0x0010000c`，这和练习三的内核执行的第一条指令位置相符。

现在应该能够理解 `boot/main.c` 中的 ELF 加载程序，就是把内核的每个部分加载到该部分加载地址的内存中，然后跳转到内核的入口开始执行。

> **练习六** 可以使用 GDB 的 `x` 命令检查内存。 GDB 手册有完整的细节，但现在，只需知道命令 `x/Nx ADDR` 是打印内存*ADDR*开始的*N*个字。在GNU汇编中，一个字是2B。   
> 退出 QEMU/GDB 并重新启动它们。在 BIOS 进入引导加载程序时检查 0x00100000 处的 8 个内存字，然后在引导加载程序进入内核时再次检查。为什么它们不同？

# Part 3: The Kernel

本部分将更详细地研究最小的 JOS 内核。与引导加载程序一样，内核从一些汇编语言代码开始，这些代码设置了一些东西，以便 C 语言代码可以正确执行。

## 使用虚拟内存解决位置依赖性
引导加载程序的加载地址和链接地址相同，但内核的加载地址和链接地址之间存在较大差异。链接内核比链接引导加载程序更复杂，内核链接地址和加载地址在 `kern/kernel.ld` 的开头。


操作系统内核通常链接并运行在非常高的虚拟地址，例如 0xf0100000，以便将处理器虚拟地址空间的较低部分留给用户程序使用。下一个实验会更加清楚这样做的原因。

许多机器在地址 0xf0100000 处没有任何物理内存（虚拟内存都远大于物理内存），因此内核并不存储在地址0xf0100000。相反，计算机将使用处理器的内存管理硬件将**虚拟地址** 0xf0100000（内核代码预期运行的**链接地址**）映射到**物理地址** 0x00100000（引导加载程序将内核加载到物理内存中的位置，**加载地址**）。

这样，内核的虚拟地址足够高，可以为用户进程留出足够的地址空间，而且它将被加载到 PC 物理内存中 1MB（0x00100000） 位置的物理内存中，就在 BIOS ROM 内存区的上方。

实际上，在下一个实验中，我们将映射PC物理内存底部整个256MB的内存空间，把虚拟内存空间`0xf0000000~0xffffffff`分别映射到物理内存空间`0x00000000~0x0fffffff`,这刚好是256MB，所以JOS只能使用前256MB内存。

现在，我们只映射前 4MB 的物理内存，这足以让我们启动并运行。我们使用 `kern/entrypgdir.c` 中手写的（固定的）、静态初始化的页目录和页表来执行此操作。现在，不必了解其工作原理的细节，只需了解它所实现的效果即可。在 `kern/entry.S` 设置 `CR0_PG` 标志之前，内存引用是物理地址（严格来说，它们是线性地址，但 `boot/boot.S` 设置了从线性地址到物理地址的恒等映射，也就是线性地址和物理地址之间相差一个固定的值）。一旦设置了 `CR0_PG`，内存引用就变成了虚拟地址。`entry_pgdir` 将 `0xf0000000~ 0xf0400000` 范围内的虚拟地址转换为物理地址 `0x00000000~0x00400000`，同样也将将虚拟地址 `0x00000000~0x00400000` 转换为物理地址 `0x00000000~0x00400000`。任何不在这两个虚拟地址范围之一的虚拟地址都会导致硬件异常，由于我们还没有设置中断处理，这将导致 QEMU 转储机器状态并退出（如果您没有使用6.828补丁版本的QEMU，则会无休止地重新启动）。

> **练习七** 使用 QEMU 和 GDB 跟踪到 JOS 内核，并在 `movl %eax, %cr0`指令处停止。检查地址 `0x00100000` 和 `0xf0100000` 处的内存(使用`x/Nx ADDR`)。然后使用 `stepi` GDB 命令单步执行该指令。再次检查 `0x00100000` 和 `0xf0100000` 处的内存。了解发生了什么。    
> 如果建立的映射错误，第一条无法正常执行的指令是什么？可以注释掉 `kern/entry.S` 中的 `movl %eax, %cr0` ，调试找到答案。    
> 
> *注*：`cr0`是一个控制寄存器，例如最后一位（最低位）`PE`是CPU是实模式还是保护模式的标志(Protedted Enable)；第一位（最高位）`PG`是分页允许位(Paging Enable)。

## 格式化打印到控制台
在操作系统内核中，我们必须自己实现所有 I/O 操作。

通读 `kern/printf.c`、`lib/printfmt.c` 和 `kern/console.c`，确保您了解它们之间的关系。在后面的实验中将会清楚为什么 `printfmt.c` 位于单独的 `lib` 目录中。

> **练习八** 我们省略了一段使用`%o`形式的打印八进制数字所必需的代码。找到并填写此代码片段。

回答下列问题：
1. 解释`printf.c`和`console.c`之间的接口。具体来说，`console.c` 导出什么函数？ `printf.c` 是如何使用这个函数的？
   > `console.c`调用`printf.c`的`cprintf`函数。`printf.c`调用`console.c`的`cputchar`函数，封装为`putch`函数，用于向控制台输出一个字符。
2. 解释如下来自`console.c`中的代码：
```c
// crt_pos是要显示的字符数+屏幕上已经显示的字符数
// CRT_SIZE=CRT_ROWS(行数)*CRT_COLS(列数),为显示器可显示的字符总数
// crt_buf代表当前显示的内容，是一个长度为CRT_SIZE的一维数组
1      if (crt_pos >= CRT_SIZE) {  // 如果屏幕显示不下，需要清除一行（更准确的说是清除CRT_COLS个字符，固定这么多个）
2              int i;
               // memmove(目的，源，长度)用于字节拷贝，把 2~n行 拷贝到 1~n-1行，即把第一行覆盖掉，第n行不变
3              memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
               // 这个for循环负责清除最后CRT_COLS个字符（可能是最后一整行），即用空格填充
4              for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
5                      crt_buf[i] = 0x0700 | ' '; // 为什么要用’或运算‘？
               // 使crt_pos回到可以显示的起始点
6              crt_pos -= CRT_COLS;
7      }
```
> 见注释

3. 对于以下问题，您可能需要查阅Lecture 2的[notes](https://pdos.csail.mit.edu/6.828/2018/lec/l-x86.html)。这些notes涵盖了 GCC 在 x86 上的调用规定。
逐步跟踪以下代码的执行：    
```c
    int x = 1, y = 3, z = 4;
    cprintf("x %d, y %x, z %d\n", x, y, z);
```
* 在对 `cprintf()` 的调用中，`fmt` 指向什么？`ap`指向什么？
* 列出（按执行顺序）对 `cons_putc`、`va_arg` 和 `vcprintf` 的每个调用。对于 `cons_putc`，也要列出它的参数。对于 `va_arg`，列出调用前后 `ap` 指向的内容。对于 `vcprintf` 列出它的两个参数的值。
* *注* VA_LIST的用法：   
（1）首先在函数里定义一个VA_LIST型的变量，这个变量是指向参数的指针。   
（2）va_start(args, fmt)：将args指向第一个参数fmt。   
（3）va_arg(args, 参数类型)：args指向下一个参数。VA_ARG的第二个参数是你要返回的参数的类型（如果函数有多个可变参数的，依次调用VA_ARG获取各个参数）。  
（4）va_end(args)：将args置为无效。

  > 这是该函数的声明`int cprintf(const char *fmt, ...);`,`fmt`指向要打印的内容，即`"x %d, y %x, z %d\n"`；`ap`是一个`va_list`变量，指向可变参数列表的一个参数。调用过程如下：   
  ```c
  cprintf("x %d, y %x, z %d\n", x, y, z)
  vcprintf("x %d, y %x, z %d\n",ap)  // ap指向参数fmt,即"x %d, y %x, z %d\n"
  vprintfmt()->
  cons_putc('x')->cons_putc(' ')->
  va_arg(*ap,int)  // 调用前fmt,调用后 x
  ->cons_putc('1')->cons_putc(',')->cons_putc(' ')
  ->cons_putc('y')->cons_putc(' ')->
  va_arg(*ap,int)  // 调用前 x,调用后 y
  ->cons_putc('3')->cons_putc(',')->cons_putc(' ')
  ->cons_putc('z')->cons_putc(' ')->
  va_arg(*ap,int)  // 调用前 y,调用后 z
  ->cons_putc('4')  
  ```
  

4. 运行以下代码：
```c
    unsigned int i = 0x00646c72;
    cprintf("H%x Wo%s", 57616, &i);
```
输出是什么？按照上一个问题的方式解释如何得出这个输出。需要参照将字节映射到字符的 ASCII 表。

这样的输出取决于 x86 是 `little-endian`（小端存储）。如果 x86 是 `big-endian`（大端存储），您会把 `i` 设置成什么以产生相同的输出？您是否需要将 `57616` 更改为其他值？

*注*：小端存储就是把低位字节(右边的)排放在内存的低地址端，高位字节(左边的)排放在内存的高地址端。
对于`0x00646c72`，如果是小端，地址从左到右是升高，那内存中内容为`72 6c 64 00`,如果是大端，则为`00 64 6c 72`。
> 输出为`He110 World`。`%x`是十六进制输出，`57616`的十六进制数为`0xe110`，`%s`为字符串输出，`i = 0x00646c72`为小端存储`72 6c 64 00`,对照ASCII码为`r l d \0`.   
> 若为大端存储，`57616`不需要改，因为它的十六进制数没变。需要把`i`设为`0x726c6400`.

5. 下述代码中，`y=`之后会打印什么？ （注意：答案不是特定值。）为什么会发生这种情况？
```c
    cprintf("x=%d y=%d", 3);
```
> 输出为`x=3 y=-267321364`，因为没有指定第三个参数，`va_arg`获取到的下一个参数是错误的。

6. 假设 GCC 更改了它的调用约定，使它按声明顺序将参数推送到堆栈上，即最后一个参数被最后推送。您将如何更改 `cprintf` 或其接口，以便仍然可以向它传递**可变数量**的参数？
   > 改成`cprintf(..., const char* fmt);`，本人猜想不知是否正确。

> ***挑战*** 增强控制台以允许以不同颜色打印文本。执行此操作的传统方法是使其解释嵌入在打印到控制台的文本字符串中的 ANSI 转义序列，但您可以使用任何您喜欢的机制。在 6.828 参考页面和网络其他地方有大量关于 VGA 显示硬件编程的信息。如果您真的很喜欢挑战困难，您可以尝试将 VGA 硬件切换到图形模式并让控制台将文本绘制到图形帧缓冲区上。

## 堆栈
在本实验的最后一个练习中，我们将更详细地探索 C 语言在 x86 上使用堆栈的方式，并在此过程中编写一个有用的新的内核监视函数，该函数打印堆栈的回溯：一个从嵌套调用指令中保存的指令指针（IP）值列表，这些指令指向当前执行点。

> **练习九** 确定内核在哪里初始化它的堆栈，以及它的堆栈在内存中的确切位置。内核如何保留它的栈空间？堆栈指针初始化为指向该保留区域的哪个“末端”（即高地址端还是低地址端）？

x86堆栈的栈底是高地址端，栈是往低地址方向生长。x86 堆栈指针（`esp` 寄存器）指向当前正在使用的堆栈的最低位置。为堆栈保留的区域中在该位置以下的所有堆栈内存都是空闲的。**将值压入堆栈涉及减少堆栈指针，然后将值写入堆栈指针指向的位置。从堆栈中弹出一个值涉及读取堆栈指针指向的值，然后增加堆栈指针。** 在 32 位模式下，堆栈只能保存 32 位的值，而 `esp` 总是能被 4 整除。各种 x86 指令（例如 `call`）是“硬连线”方式使用堆栈指针寄存器。

相反，`ebp`基指针寄存器主要通过软件约定与堆栈相关联。在进入 C 语言的函数时，函数调用处理代码通常将前一个函数的基指针压入堆栈来保存它，然后在当前函数执行期间将当前 `esp` 值复制到 `ebp` 中。如果程序中的所有函数都遵循这个约定，那么在程序执行期间，都可以通过跟踪保存的 `ebp` 指针链来确定函数的调用序列。此功能很有用，例如，当特定函数由于传递了错误的参数而导致程序崩溃，但您不确定是谁传递了错误的参数，堆栈回溯可让您找到有问题的函数。

> **练习十** 要熟悉 x86 上的 C 调用约定，请在 `obj/kern/kernel.asm` 中找到 `test_backtrace` 函数的地址，在此处设置断点，并检查内核启动后每次调用它时会发生什么。 `test_backtrace` 的每个递归嵌套级别将多少个 32 位字推入堆栈，这些字是什么？

上面的练习应该为您提供实现堆栈回溯功能所需的信息，你应该完成`kern/monitor.c`中的`mon_backtrace()`函数。`inc/x86.h` 中的 `read_ebp()` 函数很有用。您还必须将这个堆栈回溯功能挂接到内核监视器的命令列表中，以便用户可以交互地调用它。

堆栈回溯函数应显示以下格式的函数调用列表：
```
Stack backtrace:
  ebp f0109e58  eip f0100a62  args 00000001 f0109e80 f0109e98 f0100ed2 00000031
  ebp f0109ed8  eip f01000d6  args 00000000 00000000 f0100058 f0109f28 00000061
  ...
```
每行包含一个 `ebp`、`eip` 和 `args`。 `ebp` 值为该函数的堆栈的基指针（该函数栈空间的起始地址）：即在进入函数之后的堆栈指针（esp）。`eip` 值是函数的返回地址，即调用者在被调用函数执行完后要执行的指令地址。最后，在 `args` 之后列出的五个十六进制值是所讨论函数的前五个参数，它们会在函数被调用之前被压入堆栈（由调用者从右往左把参数依次压入堆栈）。当然，如果调用函数时使用的参数少于五个，那么并非所有五个值都有用。

打印的第一行反映了当前正在执行的函数，即 `mon_backtrace` 本身，第二行反映了调用 `mon_backtrace` 的函数，第三行反映了调用该函数的函数，依此类推。您应该打印所有未完成的堆栈帧。通过研究 `kern/entry.S`，您会发现有一种简单的方法可以判断何时停止。

以下是您在 K&R 第 5 章中读到的一些具体要点，这些要点值得记住，以供以下练习和将来的实验使用。
* 如果`int *p = (int*)100;`，那么`(int)p + 1 = 101` 而 `int(p + 1) = 104`。将整数加到指针时，如第二种情况，整数隐式乘以指针指向的对象的大小。
* `p[i]`与`*(p+i)`的定义相同，指的是p指向的内存中的第i个对象。
* `&p[i]`等同于`p+i`，为 p 指向的内存中第 i 个对象的地址。

尽管大多数 C 程序从不需要在指针和整数之间进行转换，但操作系统经常这样做。每当您看到涉及内存地址的加法时，请询问自己是整数加法还是指针加法，并确保所添加的值被适当地相乘。

> **练习十一** 实现上面指定的回溯功能。使用与示例中相同的格式，否则评分脚本会混淆。当你认为你的代码工作正常时，运行 `make grade` 以查看它的输出是否符合我们的评分脚本所期望的，如果不符合则修复它。    
> 如果使用 `read_ebp()`，请注意 GCC 可能会在 `mon_backtrace()` 的函数序言之前生成调用 `read_ebp()` 的“优化”代码，这会导致堆栈跟踪不完整（最近一次函数调用的堆栈帧丢失）。虽然我们已尝试禁用导致此重新排序的优化，但您可能需要检查 `mon_backtrace()` 的程序集并确保对 `read_ebp()` 的调用发生在函数序言之后。

此时，堆栈回溯函数应该为您提供执行 `mon_backtrace()` 的函数调用者的地址。但是，在实践中，您通常想知道与这些地址对应的函数名称。例如，您可能想知道哪些函数可能包含导致内核崩溃的错误。

为了帮助您实现此功能，我们提供了函数 `debuginfo_eip()`，它在符号表中查找 `eip` 并返回该地址的调试信息。这个函数在 `kern/kdebug.c` 中定义。

> **练习十二** 修改堆栈回溯函数，为每个 `eip` 显示与该 `eip` 对应的**函数名称、源文件名和行号**。    
> 在 `debuginfo_eip` 中，`__STAB_*` 来自哪里？这个问题的答案很长，为了帮助您找到答案，以下是您可能想做的一些事情：
> * 在文件 `kern/kernel.ld` 中查找 `__STAB_*`
> * 运行`objdump -h obj/kern/kernel`
> * 运行`objdump -G obj/kern/kernel`
> * 运行`gcc -pipe -nostdinc -O2 -fno-builtin -I. -MD -Wall -Wno-format -DJOS_KERNEL -gstabs -c -S kern/init.c`，并查看 `init.s`
> * 查看引导加载程序是否将符号表加载到内存中作为加载内核二进制文件的一部分   
>
> 通过插入对 `stab_binsearch` 的调用来查找地址的行号，完成 `debuginfo_eip` 的实现。   
> 向内核监视器(JOS kernel monitor)添加一个回溯命令，并扩展您的 `mon_backtrace` 实现以调用 `debuginfo_eip` 并为列表的每个调用打印对应的信息：
> ```
> K> backtrace
> Stack backtrace:
>  ebp f010ff78  eip f01008ae  args 00000001 f010ff8c 00000000 f0110580 00000000
>         kern/monitor.c:143: monitor+106
>  ebp f010ffd8  eip f0100193  args 00000000 00001aac 00000660 00000000 00000000
>         kern/init.c:49: i386_init+59
>  ebp f010fff8  eip f010003d  args 00000000 00000000 0000ffff 10cf9a00 0000ffff
>         kern/entry.S:70: <unknown>+0
>  K> 
> ```
> 每行给出堆栈帧的 `eip` 的文件名和该文件中的行号，然后是函数的名称和 `eip` 从函数的第一条指令的偏移量（例如，`monitor+106` 表示返回的 `eip` 是从`monitor`开始的第106字节）。    
> 请务必在单独的行上打印文件和函数名称，以避免混淆评分脚本。    
> 您可能会发现回溯中缺少某些功能。例如，您可能会看到对  `monitor()` 的调用，而没有对 `runcmd()` 的调用。这是因为编译器内联了一些函数调用。其他优化可能会导致您看到意外的行号。如果您从 `GNUMakefile` 中删除 `-O2`，则回溯可能更有意义（但您的内核将运行得更慢）。
