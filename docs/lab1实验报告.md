# Part 1: PC Bootstrap

## 练习2
> **练习2** 使用GDB的`si`(Step Instruction)命令跟踪ROM BIOS中的更多指令，并尝试猜测它可能在做什么。您可能需要查看[Phil Storrs I/O端口描述](http://web.archive.org/web/20040404164813/members.iweb.net.au/~pstorr/pcbook/book2/book2.htm)，以及[6.828参考资料页](https://pdos.csail.mit.edu/6.828/2018/reference.html)上的其他资料。无需弄清楚所有细节，只需大致了解BIOS首先在做什么。

> 准备：打开两个终端，都执行`cd 6.828/lab`，第一个终端执行`make qemu-gdb`，第二个终端执行`make gdb`，第二个终端用来跟踪ROM BIOS中的更多指令。


AT & T 汇编语法，对于指令的操作数，加`$`代表常量，加`%`代表寄存器，且左为源操作数，右为目的操作数。
```bash
The target architecture is assumed to be i8086
[f000:fff0]    0xffff0: ljmp   $0xf000,$0xe05b
0x0000fff0 in ?? ()   
+ symbol-file obj/kern/kernel
(gdb) si
[f000:e05b]    0xfe05b: cmpl   $0x0,%cs:0x6ac8
0x0000e05b in ?? ()     // 把0和0x6ac8比较？
(gdb) si
[f000:e062]    0xfe062: jne    0xfd2e1
0x0000e062 in ?? ()     // 条件转移
(gdb) si
[f000:e066]    0xfe066: xor    %dx,%dx
0x0000e066 in ?? ()     // 异或
(gdb) si
[f000:e068]    0xfe068: mov    %dx,%ss
0x0000e068 in ?? ()     // 传数指令
(gdb) si
[f000:e06a]    0xfe06a: mov    $0x7000,%esp
0x0000e06a in ?? ()
(gdb) si
[f000:e070]    0xfe070: mov    $0xf34c2,%edx
0x0000e070 in ?? ()
(gdb) si
[f000:e076]    0xfe076: jmp    0xfd15c
0x0000e076 in ?? ()     // 无条件转移
(gdb) si
[f000:d15c]    0xfd15c: mov    %eax,%ecx
0x0000d15c in ?? ()
(gdb) si
[f000:d15f]    0xfd15f: cli
0x0000d15f in ?? ()     // Clear Interupt,该指令的作用是禁止中断发生【关中断指令】
(gdb) si
[f000:d160]    0xfd160: cld
0x0000d160 in ?? ()     // 将标志寄存器flag的方向标志位df清零
(gdb) si
[f000:d161]    0xfd161: mov    $0x8f,%eax
0x0000d161 in ?? ()
(gdb) si
[f000:d167]    0xfd167: out    %al,$0x70
0x0000d167 in ?? ()     // OUT指令是把CPU寄存器中存储的数据输出到指定端口号的端口。【输出指令】
(gdb) si
[f000:d169]    0xfd169: in     $0x71,%al
0x0000d169 in ?? ()     // IN 指令通过指定的端口号输入数据。【输入指令】
(gdb) si
[f000:d16b]    0xfd16b: in     $0x92,%al
0x0000d16b in ?? ()
```
从地址`0xfe05b`开始执行了很多指令。`cmpl`和`jne`共同完成条件转移指令。

> **练习三** 熟悉[GDB命令](https://pdos.csail.mit.edu/6.828/2018/labguide.html)。    
> 在地址 0x7c00 处设置断点，该地址将加载引导扇区。继续执行直到该断点。跟踪 `boot/boot.S` 中的代码，使用源代码和反汇编文件 `obj/boot/boot.asm` 跟踪您所在的位置。还可以在 GDB 中使用 `x/i` 命令来反汇编引导加载程序中的指令序列，并将原始引导加载程序源代码与 `obj/boot/boot.asm` 和 GDB 中的反汇编进行比较。    
> 跟踪到 `boot/main.c` 中的 `bootmain()`，然后跟踪到 `readsect()`。确定与 `readsect()` 中的每个语句相对应的确切汇编指令。跟踪 `readsect()` 的其余部分并返回 `bootmain()`，并确定从磁盘读取内核剩余扇区的 for 循环的开始和结束。找出循环结束时将运行的代码，在此处设置断点，然后继续执行该断点。然后逐步完成引导加载程序的其余部分。

一些GDB命令：
* `c`执行到下一个断点
* `si N`执行接下来N条指令
* `b *`设置断点
* `info break`查看所有断点
* `d`删除所有断点，可选加`N`删除指定断点

for循环开始`7d51:	               	cmp    %esi,%ebx`   

结束`7d69:	               	jmp    7d51 <bootmain+0x3c>`