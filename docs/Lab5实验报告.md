# 练习1
> **Exercise 1** `i386_init` 通过将类型 `ENV_TYPE_FS` 传递给您的环境创建函数 `env_create` 来识别文件系统环境。修改 `env.c` 中的 `env_create`，使其赋予文件系统环境 I/O 权限，但绝不会将该权限赋予任何其他环境。             
```c
	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.*******************
	if(type==ENV_TYPE_FS){
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
	}
```
注意要取消注释开始的时候注释的那两行代码。

# 问题1
> **Question**         
> 1. 当您从一个环境切换到另一个环境时，您是否需要做任何其他事情来确保正确保存和恢复此 I/O 权限设置？为什么？

不需要，I/O权限位在标志寄存器eflags中，每次切换环境都会保存和恢复这个寄存器。

