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
* `b *地址`设置断点
* `b 函数名`在函数处设置断点
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
> 改成`cprintf(..., const char* fmt);`，不知是否正确。


> **练习九** 确定内核在哪里初始化它的堆栈，以及它的堆栈在内存中的确切位置。内核如何保留它的栈空间？堆栈指针初始化为指向该保留区域的哪个“末端”（即高地址端还是低地址端）？

```
f010002f:	bd 00 00 00 00     mov    $0x0,%ebp
f0100034:	bc 00 00 11 f0     mov    $0xf0110000,%esp
```
这两条指令初始化内核的堆栈，堆栈的栈底在`0xf0110000`，初始时栈顶`esp`也在`0xf0110000`。

在`kern/entry.S`中：
```
bootstack:
	.space		KSTKSIZE
```
在`inc/memlayout.h`中：
```cpp
// Kernel stack.
#define KSTACKTOP	KERNBASE
#define KSTKSIZE	(8*PGSIZE)   		// size of a kernel stack
#define KSTKGAP		(8*PGSIZE)   		// size of a kernel stack guard
```
在`inc/mmu.h`中：
```cpp
#define PGSIZE		4096		// bytes mapped by a page
```
所以内核的栈空间大小为32KB，即堆栈的确切位置为`0xf0108000 ~ 0xf0110000`。堆栈指针初始化为`0xf0110000`即高地址端。


> **练习十** 要熟悉 x86 上的 C 调用约定，请在 `obj/kern/kernel.asm` 中找到 `test_backtrace` 函数的地址，在此处设置断点，并检查内核启动后每次调用它时会发生什么。 `test_backtrace` 的每个递归嵌套级别将多少个 32 位字推入堆栈，这些字是什么？

调试结果如下：
```bash
(gdb) x/52x $esp
0xf010ff2c:     0xf01000a1      0x00000000      0x00000001      0xf010ff68
0xf010ff3c:     0xf010004a      0xf0111308      0x00000002      0xf010ff68
0xf010ff4c:     0xf01000a1      0x00000001      0x00000002      0xf010ff88
0xf010ff5c:     0xf010004a      0xf0111308      0x00000003      0xf010ff88
0xf010ff6c:     0xf01000a1      0x00000002      0x00000003      0xf010ffa8
0xf010ff7c:     0xf010004a      0xf0111308      0x00000004      0xf010ffa8
0xf010ff8c:     0xf01000a1      0x00000003      0x00000004      0x00000000
0xf010ff9c:     0xf010004a      0xf0111308      0x00000005      0xf010ffc8
0xf010ffac:     0xf01000a1      0x00000004      0x00000005      0x00000000
0xf010ffbc:     0xf010004a      0xf0111308      0x00010094      0xf010fff8
0xf010ffcc:     0xf0100124      0x00000005      0x00000003      0xf010ffec
```
每个递归嵌套级别会将8个32位字压入堆栈。从最后一行`0x00000005`开始往前看，5是参数，`0xf0100124`是`test_backtrace`在函数`i386_init`中的返回地址，`0xf010004a`是`call   f01001ec <__x86.get_pc_thunk.bx>`的返回地址，`0xf01000a1`是`test_backtrace`函数递归调用的返回地址。

> **练习十一** 实现上面指定的回溯功能。使用与示例中相同的格式，否则评分脚本会混淆。当你认为你的代码工作正常时，运行 `make grade` 以查看它的输出是否符合我们的评分脚本所期望的，如果不符合则修复它。    
> 如果使用 `read_ebp()`，请注意 GCC 可能会在 `mon_backtrace()` 的函数序言之前生成调用 `read_ebp()` 的“优化”代码，这会导致堆栈跟踪不完整（最近一次函数调用的堆栈帧丢失）。虽然我们已尝试禁用导致此重新排序的优化，但您可能需要检查 `mon_backtrace()` 的程序集并确保对 `read_ebp()` 的调用发生在函数序言之后。

做这个练习需要特别注意C函数调用做了哪些事，参考某大佬的[博客](https://www.cnblogs.com/gatsby123/p/9759153.html)，如下：
1. 执行call指令前，函数调用者将参数入栈，按照函数列表从右到左的顺序入栈
2. call指令会自动将当前eip入栈，ret指令将自动从栈中弹出该值到eip寄存器
3. 被调用函数负责：将ebp入栈，esp的值赋给ebp。所以反汇编一个函数会发现开头两个指令都是push %ebp, mov %esp,%ebp。
   
例如对于`mon_backtrace(0,0,0)`的调用：
```
高地址 +------------------+  <- esp + 5
      |    0x00000000    |
      +------------------+  <- esp + 4
      |    0x00000000    |
      +------------------+  <- esp + 3
      |    0x00000000    |
      +------------------+  <- esp + 2
      |       eip        |
      +------------------+  <- esp + 1
      |       ebp        |     <- 这个ebp是上个函数的！！！
低地址 +------------------+  <- esp (mon_backtrace 的 ebp)
```
代码如下：
```c
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	uint32_t *this_ebp = (uint32_t*)read_ebp();
	while(this_ebp!=0){     // 停止回溯的条件
		uint32_t pre_ebp = *this_ebp;
		cprintf("  ebp %08x  eip %08x  args", this_ebp, *(this_ebp+1));
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
		}
		cprintf("\n");
		this_ebp = (uint32_t*)pre_ebp;
	}
	return 0;
}
```
关于循环的条件，可以在`obj/kern/kernel.asm`反汇编文件中找到
```S
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp
```
在内核初始化堆栈的时候把0赋给了`ebp`，然后执行第一个函数`i386_init()`时函数序言把`ebp`也就是0入栈。


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

要完成本实验需要弄明白`Eipdebuginfo`和`Stab`结构体内变量的含义，`Eipdebuginfo`有注释很容易弄懂，关键是`Stab`:
```cpp
struct Stab {
	uint32_t n_strx;	// index into string table of name   符号索引
	uint8_t n_type;         // 是符号类型，FUN指函数名，SLINE指在text段中的行号
	uint8_t n_other;        // misc info (usually empty)
	uint16_t n_desc;        // 表示在文件中的行号
	uintptr_t n_value;	// 表示地址
	// 在这个实验中，如果n_type是FUN，那么n_value中的地址就是绝对地址，该函数的地址，就要根据这个地址找到对应的FUN
	// 如果n_type是SLINE，那么n_value是相对地址（相对于所在函数地址的偏移量）
};
```

对`kern/kdebug.c`中`debuginfo_eip`函数的补充：
```c
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline<=rline){
		info->eip_line = stabs[lline].n_desc;
	}else{
		return -1;
	}
```
```c
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	uint32_t *this_ebp = (uint32_t*)read_ebp();
	while(this_ebp!=0){
		uint32_t pre_ebp = *this_ebp;
		uintptr_t eip = *(this_ebp + 1);
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
		}
		cprintf("\n");
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
		// for (int i = 0; i < info.eip_fn_namelen;++i){
		// 	cprintf("%c", info.eip_fn_name[i]);
		// }
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
		this_ebp = (uint32_t *)pre_ebp;
	}
	return 0;
}
```
添加命令：
```c
static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{"backtrace", "Display the stack backtrace list", mon_backtrace},
};
```