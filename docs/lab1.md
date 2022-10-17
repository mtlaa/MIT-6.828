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
