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
