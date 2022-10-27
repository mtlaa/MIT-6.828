# Homework: boot xv6
## Boot xv6
安装xv6

## 找到`_start`的地址并设置断点
`_start`是xv6内核的入口点。
```bash
mtlaa@DESKTOP-3IITF4D:~/6.828/xv6-public$ nm kernel | grep _start
8010a48c D _binary_entryother_start
8010a460 D _binary_initcode_start
0010000c T _start
```
`_start`的地址为`0010000c`

## 练习：栈上有什么？
在上述断点处停止时，查看寄存器和堆栈内容：
查看寄存器的内容：
```bash
(gdb) info reg
eax            0x0      0
ecx            0x0      0
edx            0x1f0    496
ebx            0x10094  65684
esp            0x7bdc   0x7bdc
ebp            0x7bf8   0x7bf8
esi            0x10094  65684
edi            0x0      0
eip            0x10000c 0x10000c
```

查看堆栈的内容：
```bash
(gdb) x/24x $esp
0x7bdc: 0x00007d8d      0x00000000      0x00000000      0x00000000
0x7bec: 0x00000000      0x00000000      0x00000000      0x00000000
0x7bfc: 0x00007c4d      0x8ec031fa      0x8ec08ed8      0xa864e4d0
0x7c0c: 0xb0fa7502      0xe464e6d1      0x7502a864      0xe6dfb0fa
0x7c1c: 0x16010f60      0x200f7c78      0xc88366c0      0xc0220f01
0x7c2c: 0x087c31ea      0x10b86600      0x8ed88e00      0x66d08ec0
```

