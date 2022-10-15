# [Lab1: Booting a PC](https://pdos.csail.mit.edu/6.828/2018/labs/lab1/)


## 引言

### 这个实验分为三部分：
* 第一部分主要是熟悉x86汇编语言、QEMU x86模拟器和PC的启动引导程序。
* 第二部分研究位于`lab/boot`目录下的6.828内核引导程序。
* 第三部分研究6.828内核的模板JOS，位于`lab/kernel`目录中。

# Part1: PC Bootstrap
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
```
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
