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


> **练习四** 理解C语言中的指针。   
> 阅读 *The C Programming Language* 中的 5.1（指针和地址）到 5.5（字符指针和函数）。然后下载 [pointers.c](https://pdos.csail.mit.edu/6.828/2018/labs/lab1/pointers.c) 的代码，运行它，并确保您了解所有打印值的来源。特别是，确保您了解打印的第 1 行和第 6 行中的指针地址来自哪里，打印的第 2 到第 4 行中的所有值是如何到达那里的，以及为什么第 5 行中打印的值看似损坏。    
> 除非精通C语言，这个练习最好做一做。

其中`3[c] = 302;`为访问数组c的第三个元素。    
`b = (int *) a + 1;`指针b为地址a+4（因为是int类型的指针，int：4B）    
`c = (int *) ((char *) a + 1);`指针c为地址a+1（因为加的时候是char类型指针，char：1B）


> **练习五** 再次跟踪引导加载程序的前几条指令，并确定如果引导加载程序的链接地址错误，第一条指令是会“中断”还是错误的运行。   
> 将`boot/Makefrag`中的链接地址`-Ttext 0x7C00`改成错误的，运行`make clean`，用`make`重新编译，再次跟踪引导程序看看会发生什么。不要忘记将链接地址更改回来，然后再次清理并且重新编译！

把Makefrag中的0x7c00改为0x7c40。发现在运行到切换32位模式的指令`ljmp $0x8,$0x7c32`变成`[   0:7c2d] => 0x7c2d:  ljmp   $0x8,$0x7c72`，后面的目标地址刚好相差40。并且在这里开始无法继续执行后面的指令，发生了错误。

> **练习六** 可以使用 GDB 的 `x` 命令检查内存。 GDB 手册有完整的细节，但现在，只需知道命令 `x/Nx ADDR` 是打印内存*ADDR*开始的*N*个字。在GNU汇编中，一个字是2B。   
> 退出 QEMU/GDB 并重新启动它们。在 BIOS 进入引导加载程序时检查 0x00100000 处的 8 个内存字，然后在引导加载程序进入内核时再次检查。为什么它们不同？

进入引导加载程序时：
```bash
(gdb) x/8x 0x100000
0x100000:       0x00000000      0x00000000      0x00000000      0x00000000
0x100010:       0x00000000      0x00000000      0x00000000      0x00000000
```
进入内核后：
```bash
(gdb) x/8x 0x100000
0x100000:       0x1badb002      0x00000000      0xe4524ffe      0x7205c766
0x100010:       0x34000004      0x2000b812      0x220f0011      0xc0200fd8
```
在引导加载程序执行过程中，把磁盘中的**内核读入了内存**，所以内存里的内容改变了。


> **练习七** 使用 QEMU 和 GDB 跟踪到 JOS 内核，并在 `movl %eax, %cr0`指令处停止。检查地址 `0x00100000` 和 `0xf0100000` 处的内存(使用`x/Nx ADDR`)。然后使用 `stepi` GDB 命令单步执行该指令。再次检查 `0x00100000` 和 `0xf0100000` 处的内存。了解发生了什么。    
> 如果建立的映射错误，第一条无法正常执行的指令是什么？可以注释掉 `kern/entry.S` 中的 `movl %eax, %cr0` ，调试找到答案。    
> 
> *注*：`cr0`是一个控制寄存器，例如最后一位（最低位）`PE`是CPU是实模式还是保护模式的标志(Protedted Enable)；第一位（最高位）`PG`是分页允许位(Paging Enable)。

内核在指令`movl %eax, %cr0`执行之前：
```bash
=> 0x100025:    mov    %eax,%cr0
0x00100025 in ?? ()
(gdb) x/8x 0x100000
0x100000:       0x1badb002      0x00000000      0xe4524ffe      0x7205c766
0x100010:       0x34000004      0x2000b812      0x220f0011      0xc0200fd8
(gdb) x/8x 0xf0100000
0xf0100000 <_start+4026531828>: 0x00000000      0x00000000      0x00000000
0x00000000
0xf0100010 <entry+4>:   0x00000000      0x00000000      0x00000000      0x00000000   
```
物理内存中存放了加载的内核，虚拟内存为空（还没有设`CR0_PG`）

执行之后：
```bash
(gdb) x/8x 0x100000
0x100000:       0x1badb002      0x00000000      0xe4524ffe      0x7205c766
0x100010:       0x34000004      0x2000b812      0x220f0011      0xc0200fd8
(gdb) x/8x 0xf0100000
0xf0100000 <_start+4026531828>: 0x1badb002      0x00000000      0xe4524ffe      0x7205c766
0xf0100010 <entry+4>:   0x34000004      0x2000b812      0x220f0011      0xc0200fd8   
```
可以发现物理内存和虚拟内存中内容一样，它们建立了映射。

注释掉`movl %eax, %cr0`后：
```bash
(gdb)
=> 0x100025:    mov    $0xf010002c,%eax
0x00100025 in ?? ()
(gdb)
=> 0x10002a:    jmp    *%eax
0x0010002a in ?? ()
(gdb)
=> 0xf010002c <relocated>:      add    %al,(%eax)
relocated () at kern/entry.S:74
74              movl    $0x0,%ebp                       # nuke frame pointer
(gdb)
Remote connection closed
```
```bash
GNUmakefile:165: recipe for target 'qemu-gdb' failed
```
第一条无法正常运行的指令`jmp    *%eax`，这条指令的目的是跳转到虚拟内存空间。`add    %al,(%eax)`是发生错误产生的指令。

> **练习八** 我们省略了一段使用`%o`形式的打印八进制数字所必需的代码。找到并填写此代码片段。

要补充的代码在`lib/printfmt.c`中：
```c
// (unsigned) octal
case 'o':
    // Replace this with your code.
    putch('X', putdat);
    putch('X', putdat);
    putch('X', putdat);
    break;
```
参照上面的无符号十进制：
```c
// unsigned decimal
case 'u':
    num = getuint(&ap, lflag);
    base = 10;
    goto number;
```

**我们要写的代码为：**
```c
case 'o':
    num = getuint(&ap, lflag);
    base = 8;
    goto number;
```
