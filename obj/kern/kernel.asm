
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 c0 18 00       	mov    $0x18c000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 1b 01 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f010004c:	81 c3 d4 af 08 00    	add    $0x8afd4,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c0 00 e0 18 f0    	mov    $0xf018e000,%eax
f0100058:	c7 c2 00 d1 18 f0    	mov    $0xf018d100,%edx
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 f7 46 00 00       	call   f0104760 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 4e 05 00 00       	call   f01005bc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 80 9b f7 ff    	lea    -0x86480(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 2e 36 00 00       	call   f01036b0 <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 2c 13 00 00       	call   f01013b3 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100087:	e8 c0 31 00 00       	call   f010324c <env_init>
	trap_init();
f010008c:	e8 d2 36 00 00       	call   f0103763 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100091:	83 c4 08             	add    $0x8,%esp
f0100094:	6a 00                	push   $0x0
f0100096:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010009c:	e8 e4 32 00 00       	call   f0103385 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a1:	83 c4 04             	add    $0x4,%esp
f01000a4:	c7 c0 44 d3 18 f0    	mov    $0xf018d344,%eax
f01000aa:	ff 30                	pushl  (%eax)
f01000ac:	e8 4e 35 00 00       	call   f01035ff <env_run>

f01000b1 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b1:	55                   	push   %ebp
f01000b2:	89 e5                	mov    %esp,%ebp
f01000b4:	57                   	push   %edi
f01000b5:	56                   	push   %esi
f01000b6:	53                   	push   %ebx
f01000b7:	83 ec 0c             	sub    $0xc,%esp
f01000ba:	e8 a8 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f01000bf:	81 c3 61 af 08 00    	add    $0x8af61,%ebx
f01000c5:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000c8:	c7 c0 04 e0 18 f0    	mov    $0xf018e004,%eax
f01000ce:	83 38 00             	cmpl   $0x0,(%eax)
f01000d1:	74 0f                	je     f01000e2 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 82 08 00 00       	call   f010095f <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x22>
	panicstr = fmt;
f01000e2:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000e4:	fa                   	cli    
f01000e5:	fc                   	cld    
	va_start(ap, fmt);
f01000e6:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000e9:	83 ec 04             	sub    $0x4,%esp
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	8d 83 9b 9b f7 ff    	lea    -0x86465(%ebx),%eax
f01000f8:	50                   	push   %eax
f01000f9:	e8 b2 35 00 00       	call   f01036b0 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	56                   	push   %esi
f0100102:	57                   	push   %edi
f0100103:	e8 71 35 00 00       	call   f0103679 <vcprintf>
	cprintf("\n");
f0100108:	8d 83 76 ab f7 ff    	lea    -0x8548a(%ebx),%eax
f010010e:	89 04 24             	mov    %eax,(%esp)
f0100111:	e8 9a 35 00 00       	call   f01036b0 <cprintf>
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	eb b8                	jmp    f01000d3 <_panic+0x22>

f010011b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011b:	55                   	push   %ebp
f010011c:	89 e5                	mov    %esp,%ebp
f010011e:	56                   	push   %esi
f010011f:	53                   	push   %ebx
f0100120:	e8 42 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100125:	81 c3 fb ae 08 00    	add    $0x8aefb,%ebx
	va_list ap;

	va_start(ap, fmt);
f010012b:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010012e:	83 ec 04             	sub    $0x4,%esp
f0100131:	ff 75 0c             	pushl  0xc(%ebp)
f0100134:	ff 75 08             	pushl  0x8(%ebp)
f0100137:	8d 83 b3 9b f7 ff    	lea    -0x8644d(%ebx),%eax
f010013d:	50                   	push   %eax
f010013e:	e8 6d 35 00 00       	call   f01036b0 <cprintf>
	vcprintf(fmt, ap);
f0100143:	83 c4 08             	add    $0x8,%esp
f0100146:	56                   	push   %esi
f0100147:	ff 75 10             	pushl  0x10(%ebp)
f010014a:	e8 2a 35 00 00       	call   f0103679 <vcprintf>
	cprintf("\n");
f010014f:	8d 83 76 ab f7 ff    	lea    -0x8548a(%ebx),%eax
f0100155:	89 04 24             	mov    %eax,(%esp)
f0100158:	e8 53 35 00 00       	call   f01036b0 <cprintf>
	va_end(ap);
}
f010015d:	83 c4 10             	add    $0x10,%esp
f0100160:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100163:	5b                   	pop    %ebx
f0100164:	5e                   	pop    %esi
f0100165:	5d                   	pop    %ebp
f0100166:	c3                   	ret    

f0100167 <__x86.get_pc_thunk.bx>:
f0100167:	8b 1c 24             	mov    (%esp),%ebx
f010016a:	c3                   	ret    

f010016b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010016b:	55                   	push   %ebp
f010016c:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010016e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100173:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100174:	a8 01                	test   $0x1,%al
f0100176:	74 0b                	je     f0100183 <serial_proc_data+0x18>
f0100178:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010017d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010017e:	0f b6 c0             	movzbl %al,%eax
}
f0100181:	5d                   	pop    %ebp
f0100182:	c3                   	ret    
		return -1;
f0100183:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100188:	eb f7                	jmp    f0100181 <serial_proc_data+0x16>

f010018a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010018a:	55                   	push   %ebp
f010018b:	89 e5                	mov    %esp,%ebp
f010018d:	56                   	push   %esi
f010018e:	53                   	push   %ebx
f010018f:	e8 d3 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100194:	81 c3 8c ae 08 00    	add    $0x8ae8c,%ebx
f010019a:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	ff d6                	call   *%esi
f010019e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a1:	74 2e                	je     f01001d1 <cons_intr+0x47>
		if (c == 0)
f01001a3:	85 c0                	test   %eax,%eax
f01001a5:	74 f5                	je     f010019c <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a7:	8b 8b 04 23 00 00    	mov    0x2304(%ebx),%ecx
f01001ad:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b0:	89 93 04 23 00 00    	mov    %edx,0x2304(%ebx)
f01001b6:	88 84 0b 00 21 00 00 	mov    %al,0x2100(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001bd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c3:	75 d7                	jne    f010019c <cons_intr+0x12>
			cons.wpos = 0;
f01001c5:	c7 83 04 23 00 00 00 	movl   $0x0,0x2304(%ebx)
f01001cc:	00 00 00 
f01001cf:	eb cb                	jmp    f010019c <cons_intr+0x12>
	}
}
f01001d1:	5b                   	pop    %ebx
f01001d2:	5e                   	pop    %esi
f01001d3:	5d                   	pop    %ebp
f01001d4:	c3                   	ret    

f01001d5 <kbd_proc_data>:
{
f01001d5:	55                   	push   %ebp
f01001d6:	89 e5                	mov    %esp,%ebp
f01001d8:	56                   	push   %esi
f01001d9:	53                   	push   %ebx
f01001da:	e8 88 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01001df:	81 c3 41 ae 08 00    	add    $0x8ae41,%ebx
f01001e5:	ba 64 00 00 00       	mov    $0x64,%edx
f01001ea:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001eb:	a8 01                	test   $0x1,%al
f01001ed:	0f 84 06 01 00 00    	je     f01002f9 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001f3:	a8 20                	test   $0x20,%al
f01001f5:	0f 85 05 01 00 00    	jne    f0100300 <kbd_proc_data+0x12b>
f01001fb:	ba 60 00 00 00       	mov    $0x60,%edx
f0100200:	ec                   	in     (%dx),%al
f0100201:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100203:	3c e0                	cmp    $0xe0,%al
f0100205:	0f 84 93 00 00 00    	je     f010029e <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f010020b:	84 c0                	test   %al,%al
f010020d:	0f 88 a0 00 00 00    	js     f01002b3 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100213:	8b 8b e0 20 00 00    	mov    0x20e0(%ebx),%ecx
f0100219:	f6 c1 40             	test   $0x40,%cl
f010021c:	74 0e                	je     f010022c <kbd_proc_data+0x57>
		data |= 0x80;
f010021e:	83 c8 80             	or     $0xffffff80,%eax
f0100221:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100223:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100226:	89 8b e0 20 00 00    	mov    %ecx,0x20e0(%ebx)
	shift |= shiftcode[data];
f010022c:	0f b6 d2             	movzbl %dl,%edx
f010022f:	0f b6 84 13 00 9d f7 	movzbl -0x86300(%ebx,%edx,1),%eax
f0100236:	ff 
f0100237:	0b 83 e0 20 00 00    	or     0x20e0(%ebx),%eax
	shift ^= togglecode[data];
f010023d:	0f b6 8c 13 00 9c f7 	movzbl -0x86400(%ebx,%edx,1),%ecx
f0100244:	ff 
f0100245:	31 c8                	xor    %ecx,%eax
f0100247:	89 83 e0 20 00 00    	mov    %eax,0x20e0(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f010024d:	89 c1                	mov    %eax,%ecx
f010024f:	83 e1 03             	and    $0x3,%ecx
f0100252:	8b 8c 8b 00 20 00 00 	mov    0x2000(%ebx,%ecx,4),%ecx
f0100259:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010025d:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100260:	a8 08                	test   $0x8,%al
f0100262:	74 0d                	je     f0100271 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f0100264:	89 f2                	mov    %esi,%edx
f0100266:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100269:	83 f9 19             	cmp    $0x19,%ecx
f010026c:	77 7a                	ja     f01002e8 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f010026e:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100271:	f7 d0                	not    %eax
f0100273:	a8 06                	test   $0x6,%al
f0100275:	75 33                	jne    f01002aa <kbd_proc_data+0xd5>
f0100277:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f010027d:	75 2b                	jne    f01002aa <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f010027f:	83 ec 0c             	sub    $0xc,%esp
f0100282:	8d 83 cd 9b f7 ff    	lea    -0x86433(%ebx),%eax
f0100288:	50                   	push   %eax
f0100289:	e8 22 34 00 00       	call   f01036b0 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100293:	ba 92 00 00 00       	mov    $0x92,%edx
f0100298:	ee                   	out    %al,(%dx)
f0100299:	83 c4 10             	add    $0x10,%esp
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd5>
		shift |= E0ESC;
f010029e:	83 8b e0 20 00 00 40 	orl    $0x40,0x20e0(%ebx)
		return 0;
f01002a5:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002aa:	89 f0                	mov    %esi,%eax
f01002ac:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5e                   	pop    %esi
f01002b1:	5d                   	pop    %ebp
f01002b2:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002b3:	8b 8b e0 20 00 00    	mov    0x20e0(%ebx),%ecx
f01002b9:	89 ce                	mov    %ecx,%esi
f01002bb:	83 e6 40             	and    $0x40,%esi
f01002be:	83 e0 7f             	and    $0x7f,%eax
f01002c1:	85 f6                	test   %esi,%esi
f01002c3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002c6:	0f b6 d2             	movzbl %dl,%edx
f01002c9:	0f b6 84 13 00 9d f7 	movzbl -0x86300(%ebx,%edx,1),%eax
f01002d0:	ff 
f01002d1:	83 c8 40             	or     $0x40,%eax
f01002d4:	0f b6 c0             	movzbl %al,%eax
f01002d7:	f7 d0                	not    %eax
f01002d9:	21 c8                	and    %ecx,%eax
f01002db:	89 83 e0 20 00 00    	mov    %eax,0x20e0(%ebx)
		return 0;
f01002e1:	be 00 00 00 00       	mov    $0x0,%esi
f01002e6:	eb c2                	jmp    f01002aa <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002e8:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002eb:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002ee:	83 fa 1a             	cmp    $0x1a,%edx
f01002f1:	0f 42 f1             	cmovb  %ecx,%esi
f01002f4:	e9 78 ff ff ff       	jmp    f0100271 <kbd_proc_data+0x9c>
		return -1;
f01002f9:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002fe:	eb aa                	jmp    f01002aa <kbd_proc_data+0xd5>
		return -1;
f0100300:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100305:	eb a3                	jmp    f01002aa <kbd_proc_data+0xd5>

f0100307 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100307:	55                   	push   %ebp
f0100308:	89 e5                	mov    %esp,%ebp
f010030a:	57                   	push   %edi
f010030b:	56                   	push   %esi
f010030c:	53                   	push   %ebx
f010030d:	83 ec 1c             	sub    $0x1c,%esp
f0100310:	e8 52 fe ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100315:	81 c3 0b ad 08 00    	add    $0x8ad0b,%ebx
f010031b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010031e:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100323:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100328:	b9 84 00 00 00       	mov    $0x84,%ecx
f010032d:	eb 09                	jmp    f0100338 <cons_putc+0x31>
f010032f:	89 ca                	mov    %ecx,%edx
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	ec                   	in     (%dx),%al
f0100334:	ec                   	in     (%dx),%al
	     i++)
f0100335:	83 c6 01             	add    $0x1,%esi
f0100338:	89 fa                	mov    %edi,%edx
f010033a:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033b:	a8 20                	test   $0x20,%al
f010033d:	75 08                	jne    f0100347 <cons_putc+0x40>
f010033f:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100345:	7e e8                	jle    f010032f <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f0100347:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010034a:	89 f8                	mov    %edi,%eax
f010034c:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100354:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100355:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010035a:	bf 79 03 00 00       	mov    $0x379,%edi
f010035f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100364:	eb 09                	jmp    f010036f <cons_putc+0x68>
f0100366:	89 ca                	mov    %ecx,%edx
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	ec                   	in     (%dx),%al
f010036b:	ec                   	in     (%dx),%al
f010036c:	83 c6 01             	add    $0x1,%esi
f010036f:	89 fa                	mov    %edi,%edx
f0100371:	ec                   	in     (%dx),%al
f0100372:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100378:	7f 04                	jg     f010037e <cons_putc+0x77>
f010037a:	84 c0                	test   %al,%al
f010037c:	79 e8                	jns    f0100366 <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010037e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100383:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010038d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100392:	ee                   	out    %al,(%dx)
f0100393:	b8 08 00 00 00       	mov    $0x8,%eax
f0100398:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100399:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010039c:	89 fa                	mov    %edi,%edx
f010039e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003a4:	89 f8                	mov    %edi,%eax
f01003a6:	80 cc 07             	or     $0x7,%ah
f01003a9:	85 d2                	test   %edx,%edx
f01003ab:	0f 45 c7             	cmovne %edi,%eax
f01003ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f01003b1:	0f b6 c0             	movzbl %al,%eax
f01003b4:	83 f8 09             	cmp    $0x9,%eax
f01003b7:	0f 84 b9 00 00 00    	je     f0100476 <cons_putc+0x16f>
f01003bd:	83 f8 09             	cmp    $0x9,%eax
f01003c0:	7e 74                	jle    f0100436 <cons_putc+0x12f>
f01003c2:	83 f8 0a             	cmp    $0xa,%eax
f01003c5:	0f 84 9e 00 00 00    	je     f0100469 <cons_putc+0x162>
f01003cb:	83 f8 0d             	cmp    $0xd,%eax
f01003ce:	0f 85 d9 00 00 00    	jne    f01004ad <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003d4:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f01003db:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e1:	c1 e8 16             	shr    $0x16,%eax
f01003e4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e7:	c1 e0 04             	shl    $0x4,%eax
f01003ea:	66 89 83 08 23 00 00 	mov    %ax,0x2308(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003f1:	66 81 bb 08 23 00 00 	cmpw   $0x7cf,0x2308(%ebx)
f01003f8:	cf 07 
f01003fa:	0f 87 d4 00 00 00    	ja     f01004d4 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100400:	8b 8b 10 23 00 00    	mov    0x2310(%ebx),%ecx
f0100406:	b8 0e 00 00 00       	mov    $0xe,%eax
f010040b:	89 ca                	mov    %ecx,%edx
f010040d:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010040e:	0f b7 9b 08 23 00 00 	movzwl 0x2308(%ebx),%ebx
f0100415:	8d 71 01             	lea    0x1(%ecx),%esi
f0100418:	89 d8                	mov    %ebx,%eax
f010041a:	66 c1 e8 08          	shr    $0x8,%ax
f010041e:	89 f2                	mov    %esi,%edx
f0100420:	ee                   	out    %al,(%dx)
f0100421:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100426:	89 ca                	mov    %ecx,%edx
f0100428:	ee                   	out    %al,(%dx)
f0100429:	89 d8                	mov    %ebx,%eax
f010042b:	89 f2                	mov    %esi,%edx
f010042d:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010042e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100431:	5b                   	pop    %ebx
f0100432:	5e                   	pop    %esi
f0100433:	5f                   	pop    %edi
f0100434:	5d                   	pop    %ebp
f0100435:	c3                   	ret    
	switch (c & 0xff) {
f0100436:	83 f8 08             	cmp    $0x8,%eax
f0100439:	75 72                	jne    f01004ad <cons_putc+0x1a6>
		if (crt_pos > 0) {
f010043b:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f0100442:	66 85 c0             	test   %ax,%ax
f0100445:	74 b9                	je     f0100400 <cons_putc+0xf9>
			crt_pos--;
f0100447:	83 e8 01             	sub    $0x1,%eax
f010044a:	66 89 83 08 23 00 00 	mov    %ax,0x2308(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100451:	0f b7 c0             	movzwl %ax,%eax
f0100454:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100458:	b2 00                	mov    $0x0,%dl
f010045a:	83 ca 20             	or     $0x20,%edx
f010045d:	8b 8b 0c 23 00 00    	mov    0x230c(%ebx),%ecx
f0100463:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100467:	eb 88                	jmp    f01003f1 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100469:	66 83 83 08 23 00 00 	addw   $0x50,0x2308(%ebx)
f0100470:	50 
f0100471:	e9 5e ff ff ff       	jmp    f01003d4 <cons_putc+0xcd>
		cons_putc(' ');
f0100476:	b8 20 00 00 00       	mov    $0x20,%eax
f010047b:	e8 87 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100480:	b8 20 00 00 00       	mov    $0x20,%eax
f0100485:	e8 7d fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010048a:	b8 20 00 00 00       	mov    $0x20,%eax
f010048f:	e8 73 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100494:	b8 20 00 00 00       	mov    $0x20,%eax
f0100499:	e8 69 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010049e:	b8 20 00 00 00       	mov    $0x20,%eax
f01004a3:	e8 5f fe ff ff       	call   f0100307 <cons_putc>
f01004a8:	e9 44 ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004ad:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f01004b4:	8d 50 01             	lea    0x1(%eax),%edx
f01004b7:	66 89 93 08 23 00 00 	mov    %dx,0x2308(%ebx)
f01004be:	0f b7 c0             	movzwl %ax,%eax
f01004c1:	8b 93 0c 23 00 00    	mov    0x230c(%ebx),%edx
f01004c7:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004cf:	e9 1d ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004d4:	8b 83 0c 23 00 00    	mov    0x230c(%ebx),%eax
f01004da:	83 ec 04             	sub    $0x4,%esp
f01004dd:	68 00 0f 00 00       	push   $0xf00
f01004e2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004e8:	52                   	push   %edx
f01004e9:	50                   	push   %eax
f01004ea:	e8 be 42 00 00       	call   f01047ad <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004ef:	8b 93 0c 23 00 00    	mov    0x230c(%ebx),%edx
f01004f5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004fb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100501:	83 c4 10             	add    $0x10,%esp
f0100504:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100509:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010050c:	39 d0                	cmp    %edx,%eax
f010050e:	75 f4                	jne    f0100504 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100510:	66 83 ab 08 23 00 00 	subw   $0x50,0x2308(%ebx)
f0100517:	50 
f0100518:	e9 e3 fe ff ff       	jmp    f0100400 <cons_putc+0xf9>

f010051d <serial_intr>:
{
f010051d:	e8 e7 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100522:	05 fe aa 08 00       	add    $0x8aafe,%eax
	if (serial_exists)
f0100527:	80 b8 14 23 00 00 00 	cmpb   $0x0,0x2314(%eax)
f010052e:	75 02                	jne    f0100532 <serial_intr+0x15>
f0100530:	f3 c3                	repz ret 
{
f0100532:	55                   	push   %ebp
f0100533:	89 e5                	mov    %esp,%ebp
f0100535:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100538:	8d 80 4b 51 f7 ff    	lea    -0x8aeb5(%eax),%eax
f010053e:	e8 47 fc ff ff       	call   f010018a <cons_intr>
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <kbd_intr>:
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	83 ec 08             	sub    $0x8,%esp
f010054b:	e8 b9 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100550:	05 d0 aa 08 00       	add    $0x8aad0,%eax
	cons_intr(kbd_proc_data);
f0100555:	8d 80 b5 51 f7 ff    	lea    -0x8ae4b(%eax),%eax
f010055b:	e8 2a fc ff ff       	call   f010018a <cons_intr>
}
f0100560:	c9                   	leave  
f0100561:	c3                   	ret    

f0100562 <cons_getc>:
{
f0100562:	55                   	push   %ebp
f0100563:	89 e5                	mov    %esp,%ebp
f0100565:	53                   	push   %ebx
f0100566:	83 ec 04             	sub    $0x4,%esp
f0100569:	e8 f9 fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010056e:	81 c3 b2 aa 08 00    	add    $0x8aab2,%ebx
	serial_intr();
f0100574:	e8 a4 ff ff ff       	call   f010051d <serial_intr>
	kbd_intr();
f0100579:	e8 c7 ff ff ff       	call   f0100545 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010057e:	8b 93 00 23 00 00    	mov    0x2300(%ebx),%edx
	return 0;
f0100584:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100589:	3b 93 04 23 00 00    	cmp    0x2304(%ebx),%edx
f010058f:	74 19                	je     f01005aa <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100591:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100594:	89 8b 00 23 00 00    	mov    %ecx,0x2300(%ebx)
f010059a:	0f b6 84 13 00 21 00 	movzbl 0x2100(%ebx,%edx,1),%eax
f01005a1:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005a2:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005a8:	74 06                	je     f01005b0 <cons_getc+0x4e>
}
f01005aa:	83 c4 04             	add    $0x4,%esp
f01005ad:	5b                   	pop    %ebx
f01005ae:	5d                   	pop    %ebp
f01005af:	c3                   	ret    
			cons.rpos = 0;
f01005b0:	c7 83 00 23 00 00 00 	movl   $0x0,0x2300(%ebx)
f01005b7:	00 00 00 
f01005ba:	eb ee                	jmp    f01005aa <cons_getc+0x48>

f01005bc <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005bc:	55                   	push   %ebp
f01005bd:	89 e5                	mov    %esp,%ebp
f01005bf:	57                   	push   %edi
f01005c0:	56                   	push   %esi
f01005c1:	53                   	push   %ebx
f01005c2:	83 ec 1c             	sub    $0x1c,%esp
f01005c5:	e8 9d fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01005ca:	81 c3 56 aa 08 00    	add    $0x8aa56,%ebx
	was = *cp;
f01005d0:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005d7:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005de:	5a a5 
	if (*cp != 0xA55A) {
f01005e0:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005e7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005eb:	0f 84 bc 00 00 00    	je     f01006ad <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005f1:	c7 83 10 23 00 00 b4 	movl   $0x3b4,0x2310(%ebx)
f01005f8:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005fb:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100602:	8b bb 10 23 00 00    	mov    0x2310(%ebx),%edi
f0100608:	b8 0e 00 00 00       	mov    $0xe,%eax
f010060d:	89 fa                	mov    %edi,%edx
f010060f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100610:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100613:	89 ca                	mov    %ecx,%edx
f0100615:	ec                   	in     (%dx),%al
f0100616:	0f b6 f0             	movzbl %al,%esi
f0100619:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100621:	89 fa                	mov    %edi,%edx
f0100623:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100624:	89 ca                	mov    %ecx,%edx
f0100626:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100627:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010062a:	89 bb 0c 23 00 00    	mov    %edi,0x230c(%ebx)
	pos |= inb(addr_6845 + 1);
f0100630:	0f b6 c0             	movzbl %al,%eax
f0100633:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100635:	66 89 b3 08 23 00 00 	mov    %si,0x2308(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010063c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100641:	89 c8                	mov    %ecx,%eax
f0100643:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010064e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100653:	89 fa                	mov    %edi,%edx
f0100655:	ee                   	out    %al,(%dx)
f0100656:	b8 0c 00 00 00       	mov    $0xc,%eax
f010065b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100660:	ee                   	out    %al,(%dx)
f0100661:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100666:	89 c8                	mov    %ecx,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
f010066b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100670:	89 fa                	mov    %edi,%edx
f0100672:	ee                   	out    %al,(%dx)
f0100673:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100678:	89 c8                	mov    %ecx,%eax
f010067a:	ee                   	out    %al,(%dx)
f010067b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100680:	89 f2                	mov    %esi,%edx
f0100682:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100683:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100688:	ec                   	in     (%dx),%al
f0100689:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010068b:	3c ff                	cmp    $0xff,%al
f010068d:	0f 95 83 14 23 00 00 	setne  0x2314(%ebx)
f0100694:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100699:	ec                   	in     (%dx),%al
f010069a:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010069f:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006a0:	80 f9 ff             	cmp    $0xff,%cl
f01006a3:	74 25                	je     f01006ca <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006a8:	5b                   	pop    %ebx
f01006a9:	5e                   	pop    %esi
f01006aa:	5f                   	pop    %edi
f01006ab:	5d                   	pop    %ebp
f01006ac:	c3                   	ret    
		*cp = was;
f01006ad:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006b4:	c7 83 10 23 00 00 d4 	movl   $0x3d4,0x2310(%ebx)
f01006bb:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006be:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006c5:	e9 38 ff ff ff       	jmp    f0100602 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006ca:	83 ec 0c             	sub    $0xc,%esp
f01006cd:	8d 83 d9 9b f7 ff    	lea    -0x86427(%ebx),%eax
f01006d3:	50                   	push   %eax
f01006d4:	e8 d7 2f 00 00       	call   f01036b0 <cprintf>
f01006d9:	83 c4 10             	add    $0x10,%esp
}
f01006dc:	eb c7                	jmp    f01006a5 <cons_init+0xe9>

f01006de <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006de:	55                   	push   %ebp
f01006df:	89 e5                	mov    %esp,%ebp
f01006e1:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01006e7:	e8 1b fc ff ff       	call   f0100307 <cons_putc>
}
f01006ec:	c9                   	leave  
f01006ed:	c3                   	ret    

f01006ee <getchar>:

int
getchar(void)
{
f01006ee:	55                   	push   %ebp
f01006ef:	89 e5                	mov    %esp,%ebp
f01006f1:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006f4:	e8 69 fe ff ff       	call   f0100562 <cons_getc>
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	74 f7                	je     f01006f4 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006fd:	c9                   	leave  
f01006fe:	c3                   	ret    

f01006ff <iscons>:

int
iscons(int fdnum)
{
f01006ff:	55                   	push   %ebp
f0100700:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100702:	b8 01 00 00 00       	mov    $0x1,%eax
f0100707:	5d                   	pop    %ebp
f0100708:	c3                   	ret    

f0100709 <__x86.get_pc_thunk.ax>:
f0100709:	8b 04 24             	mov    (%esp),%eax
f010070c:	c3                   	ret    

f010070d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010070d:	55                   	push   %ebp
f010070e:	89 e5                	mov    %esp,%ebp
f0100710:	56                   	push   %esi
f0100711:	53                   	push   %ebx
f0100712:	e8 50 fa ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100717:	81 c3 09 a9 08 00    	add    $0x8a909,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010071d:	83 ec 04             	sub    $0x4,%esp
f0100720:	8d 83 00 9e f7 ff    	lea    -0x86200(%ebx),%eax
f0100726:	50                   	push   %eax
f0100727:	8d 83 1e 9e f7 ff    	lea    -0x861e2(%ebx),%eax
f010072d:	50                   	push   %eax
f010072e:	8d b3 23 9e f7 ff    	lea    -0x861dd(%ebx),%esi
f0100734:	56                   	push   %esi
f0100735:	e8 76 2f 00 00       	call   f01036b0 <cprintf>
f010073a:	83 c4 0c             	add    $0xc,%esp
f010073d:	8d 83 f0 9e f7 ff    	lea    -0x86110(%ebx),%eax
f0100743:	50                   	push   %eax
f0100744:	8d 83 2c 9e f7 ff    	lea    -0x861d4(%ebx),%eax
f010074a:	50                   	push   %eax
f010074b:	56                   	push   %esi
f010074c:	e8 5f 2f 00 00       	call   f01036b0 <cprintf>
f0100751:	83 c4 0c             	add    $0xc,%esp
f0100754:	8d 83 18 9f f7 ff    	lea    -0x860e8(%ebx),%eax
f010075a:	50                   	push   %eax
f010075b:	8d 83 35 9e f7 ff    	lea    -0x861cb(%ebx),%eax
f0100761:	50                   	push   %eax
f0100762:	56                   	push   %esi
f0100763:	e8 48 2f 00 00       	call   f01036b0 <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	8d 83 3c 9f f7 ff    	lea    -0x860c4(%ebx),%eax
f0100771:	50                   	push   %eax
f0100772:	8d 83 3f 9e f7 ff    	lea    -0x861c1(%ebx),%eax
f0100778:	50                   	push   %eax
f0100779:	56                   	push   %esi
f010077a:	e8 31 2f 00 00       	call   f01036b0 <cprintf>
	return 0;
}
f010077f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100784:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100787:	5b                   	pop    %ebx
f0100788:	5e                   	pop    %esi
f0100789:	5d                   	pop    %ebp
f010078a:	c3                   	ret    

f010078b <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010078b:	55                   	push   %ebp
f010078c:	89 e5                	mov    %esp,%ebp
f010078e:	57                   	push   %edi
f010078f:	56                   	push   %esi
f0100790:	53                   	push   %ebx
f0100791:	83 ec 18             	sub    $0x18,%esp
f0100794:	e8 ce f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100799:	81 c3 87 a8 08 00    	add    $0x8a887,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010079f:	8d 83 4c 9e f7 ff    	lea    -0x861b4(%ebx),%eax
f01007a5:	50                   	push   %eax
f01007a6:	e8 05 2f 00 00       	call   f01036b0 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ab:	83 c4 08             	add    $0x8,%esp
f01007ae:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007b4:	8d 83 88 9f f7 ff    	lea    -0x86078(%ebx),%eax
f01007ba:	50                   	push   %eax
f01007bb:	e8 f0 2e 00 00       	call   f01036b0 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007c9:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007cf:	50                   	push   %eax
f01007d0:	57                   	push   %edi
f01007d1:	8d 83 b0 9f f7 ff    	lea    -0x86050(%ebx),%eax
f01007d7:	50                   	push   %eax
f01007d8:	e8 d3 2e 00 00       	call   f01036b0 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007dd:	83 c4 0c             	add    $0xc,%esp
f01007e0:	c7 c0 99 4b 10 f0    	mov    $0xf0104b99,%eax
f01007e6:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007ec:	52                   	push   %edx
f01007ed:	50                   	push   %eax
f01007ee:	8d 83 d4 9f f7 ff    	lea    -0x8602c(%ebx),%eax
f01007f4:	50                   	push   %eax
f01007f5:	e8 b6 2e 00 00       	call   f01036b0 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007fa:	83 c4 0c             	add    $0xc,%esp
f01007fd:	c7 c0 00 d1 18 f0    	mov    $0xf018d100,%eax
f0100803:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100809:	52                   	push   %edx
f010080a:	50                   	push   %eax
f010080b:	8d 83 f8 9f f7 ff    	lea    -0x86008(%ebx),%eax
f0100811:	50                   	push   %eax
f0100812:	e8 99 2e 00 00       	call   f01036b0 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	c7 c6 00 e0 18 f0    	mov    $0xf018e000,%esi
f0100820:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100826:	50                   	push   %eax
f0100827:	56                   	push   %esi
f0100828:	8d 83 1c a0 f7 ff    	lea    -0x85fe4(%ebx),%eax
f010082e:	50                   	push   %eax
f010082f:	e8 7c 2e 00 00       	call   f01036b0 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100834:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100837:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010083d:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010083f:	c1 fe 0a             	sar    $0xa,%esi
f0100842:	56                   	push   %esi
f0100843:	8d 83 40 a0 f7 ff    	lea    -0x85fc0(%ebx),%eax
f0100849:	50                   	push   %eax
f010084a:	e8 61 2e 00 00       	call   f01036b0 <cprintf>
	return 0;
}
f010084f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100854:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100857:	5b                   	pop    %ebx
f0100858:	5e                   	pop    %esi
f0100859:	5f                   	pop    %edi
f010085a:	5d                   	pop    %ebp
f010085b:	c3                   	ret    

f010085c <mon_showmappings>:
		this_ebp = (uint32_t *)pre_ebp;
	}
	return 0;
}

int mon_showmappings(int argc, char **argv, struct Trapframe *tf){
f010085c:	55                   	push   %ebp
f010085d:	89 e5                	mov    %esp,%ebp
f010085f:	53                   	push   %ebx
f0100860:	83 ec 10             	sub    $0x10,%esp
f0100863:	e8 ff f8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100868:	81 c3 b8 a7 08 00    	add    $0x8a7b8,%ebx
		}
		cprintf("Virtual address %#x map to Physical address %#x . Permisson: PTE_U = %d , PTE_W = %d\n",
		 low, PTE_ADDR(*pte),*pte&PTE_U,*pte&PTE_W);
	}
	*/
	cprintf("This command is not implement.\n");
f010086e:	8d 83 6c a0 f7 ff    	lea    -0x85f94(%ebx),%eax
f0100874:	50                   	push   %eax
f0100875:	e8 36 2e 00 00       	call   f01036b0 <cprintf>
	return 0;
}
f010087a:	b8 00 00 00 00       	mov    $0x0,%eax
f010087f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100882:	c9                   	leave  
f0100883:	c3                   	ret    

f0100884 <mon_backtrace>:
{
f0100884:	55                   	push   %ebp
f0100885:	89 e5                	mov    %esp,%ebp
f0100887:	57                   	push   %edi
f0100888:	56                   	push   %esi
f0100889:	53                   	push   %ebx
f010088a:	83 ec 48             	sub    $0x48,%esp
f010088d:	e8 d5 f8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100892:	81 c3 8e a7 08 00    	add    $0x8a78e,%ebx
	cprintf("Stack backtrace:\n");
f0100898:	8d 83 65 9e f7 ff    	lea    -0x8619b(%ebx),%eax
f010089e:	50                   	push   %eax
f010089f:	e8 0c 2e 00 00       	call   f01036b0 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a4:	89 ef                	mov    %ebp,%edi
	while(this_ebp!=0){
f01008a6:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
f01008a9:	8d 83 77 9e f7 ff    	lea    -0x86189(%ebx),%eax
f01008af:	89 45 b8             	mov    %eax,-0x48(%ebp)
			cprintf(" %08x", *(this_ebp + 2 + i));
f01008b2:	8d 83 92 9e f7 ff    	lea    -0x8616e(%ebx),%eax
f01008b8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	while(this_ebp!=0){
f01008bb:	e9 8a 00 00 00       	jmp    f010094a <mon_backtrace+0xc6>
		uint32_t pre_ebp = *this_ebp;
f01008c0:	8b 07                	mov    (%edi),%eax
f01008c2:	89 45 c0             	mov    %eax,-0x40(%ebp)
		uintptr_t eip = *(this_ebp + 1);
f01008c5:	8b 47 04             	mov    0x4(%edi),%eax
f01008c8:	89 45 bc             	mov    %eax,-0x44(%ebp)
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
f01008cb:	83 ec 04             	sub    $0x4,%esp
f01008ce:	50                   	push   %eax
f01008cf:	57                   	push   %edi
f01008d0:	ff 75 b8             	pushl  -0x48(%ebp)
f01008d3:	e8 d8 2d 00 00       	call   f01036b0 <cprintf>
f01008d8:	8d 77 08             	lea    0x8(%edi),%esi
f01008db:	83 c7 1c             	add    $0x1c,%edi
f01008de:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f01008e1:	83 ec 08             	sub    $0x8,%esp
f01008e4:	ff 36                	pushl  (%esi)
f01008e6:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008e9:	e8 c2 2d 00 00       	call   f01036b0 <cprintf>
f01008ee:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f01008f1:	83 c4 10             	add    $0x10,%esp
f01008f4:	39 fe                	cmp    %edi,%esi
f01008f6:	75 e9                	jne    f01008e1 <mon_backtrace+0x5d>
		cprintf("\n");
f01008f8:	83 ec 0c             	sub    $0xc,%esp
f01008fb:	8d 83 76 ab f7 ff    	lea    -0x8548a(%ebx),%eax
f0100901:	50                   	push   %eax
f0100902:	e8 a9 2d 00 00       	call   f01036b0 <cprintf>
		debuginfo_eip(eip, &info);
f0100907:	83 c4 08             	add    $0x8,%esp
f010090a:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010090d:	50                   	push   %eax
f010090e:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100911:	57                   	push   %edi
f0100912:	e8 3f 33 00 00       	call   f0103c56 <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f0100917:	83 c4 0c             	add    $0xc,%esp
f010091a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010091d:	ff 75 d0             	pushl  -0x30(%ebp)
f0100920:	8d 83 98 9e f7 ff    	lea    -0x86168(%ebx),%eax
f0100926:	50                   	push   %eax
f0100927:	e8 84 2d 00 00       	call   f01036b0 <cprintf>
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f010092c:	89 f8                	mov    %edi,%eax
f010092e:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100931:	50                   	push   %eax
f0100932:	ff 75 d8             	pushl  -0x28(%ebp)
f0100935:	ff 75 dc             	pushl  -0x24(%ebp)
f0100938:	8d 83 a8 9e f7 ff    	lea    -0x86158(%ebx),%eax
f010093e:	50                   	push   %eax
f010093f:	e8 6c 2d 00 00       	call   f01036b0 <cprintf>
		this_ebp = (uint32_t *)pre_ebp;
f0100944:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100947:	83 c4 20             	add    $0x20,%esp
	while(this_ebp!=0){
f010094a:	85 ff                	test   %edi,%edi
f010094c:	0f 85 6e ff ff ff    	jne    f01008c0 <mon_backtrace+0x3c>
}
f0100952:	b8 00 00 00 00       	mov    $0x0,%eax
f0100957:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010095a:	5b                   	pop    %ebx
f010095b:	5e                   	pop    %esi
f010095c:	5f                   	pop    %edi
f010095d:	5d                   	pop    %ebp
f010095e:	c3                   	ret    

f010095f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010095f:	55                   	push   %ebp
f0100960:	89 e5                	mov    %esp,%ebp
f0100962:	57                   	push   %edi
f0100963:	56                   	push   %esi
f0100964:	53                   	push   %ebx
f0100965:	83 ec 68             	sub    $0x68,%esp
f0100968:	e8 fa f7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010096d:	81 c3 b3 a6 08 00    	add    $0x8a6b3,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100973:	8d 83 8c a0 f7 ff    	lea    -0x85f74(%ebx),%eax
f0100979:	50                   	push   %eax
f010097a:	e8 31 2d 00 00       	call   f01036b0 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010097f:	8d 83 b0 a0 f7 ff    	lea    -0x85f50(%ebx),%eax
f0100985:	89 04 24             	mov    %eax,(%esp)
f0100988:	e8 23 2d 00 00       	call   f01036b0 <cprintf>

	if (tf != NULL)
f010098d:	83 c4 10             	add    $0x10,%esp
f0100990:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100994:	74 0e                	je     f01009a4 <monitor+0x45>
		print_trapframe(tf);
f0100996:	83 ec 0c             	sub    $0xc,%esp
f0100999:	ff 75 08             	pushl  0x8(%ebp)
f010099c:	e8 78 2e 00 00       	call   f0103819 <print_trapframe>
f01009a1:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01009a4:	8d bb b5 9e f7 ff    	lea    -0x8614b(%ebx),%edi
f01009aa:	eb 4a                	jmp    f01009f6 <monitor+0x97>
f01009ac:	83 ec 08             	sub    $0x8,%esp
f01009af:	0f be c0             	movsbl %al,%eax
f01009b2:	50                   	push   %eax
f01009b3:	57                   	push   %edi
f01009b4:	e8 6a 3d 00 00       	call   f0104723 <strchr>
f01009b9:	83 c4 10             	add    $0x10,%esp
f01009bc:	85 c0                	test   %eax,%eax
f01009be:	74 08                	je     f01009c8 <monitor+0x69>
			*buf++ = 0;
f01009c0:	c6 06 00             	movb   $0x0,(%esi)
f01009c3:	8d 76 01             	lea    0x1(%esi),%esi
f01009c6:	eb 76                	jmp    f0100a3e <monitor+0xdf>
		if (*buf == 0)
f01009c8:	80 3e 00             	cmpb   $0x0,(%esi)
f01009cb:	74 7c                	je     f0100a49 <monitor+0xea>
		if (argc == MAXARGS-1) {
f01009cd:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009d1:	74 0f                	je     f01009e2 <monitor+0x83>
		argv[argc++] = buf;
f01009d3:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009d6:	8d 48 01             	lea    0x1(%eax),%ecx
f01009d9:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009dc:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01009e0:	eb 41                	jmp    f0100a23 <monitor+0xc4>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009e2:	83 ec 08             	sub    $0x8,%esp
f01009e5:	6a 10                	push   $0x10
f01009e7:	8d 83 ba 9e f7 ff    	lea    -0x86146(%ebx),%eax
f01009ed:	50                   	push   %eax
f01009ee:	e8 bd 2c 00 00       	call   f01036b0 <cprintf>
f01009f3:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009f6:	8d 83 b1 9e f7 ff    	lea    -0x8614f(%ebx),%eax
f01009fc:	89 c6                	mov    %eax,%esi
f01009fe:	83 ec 0c             	sub    $0xc,%esp
f0100a01:	56                   	push   %esi
f0100a02:	e8 e4 3a 00 00       	call   f01044eb <readline>
		if (buf != NULL)
f0100a07:	83 c4 10             	add    $0x10,%esp
f0100a0a:	85 c0                	test   %eax,%eax
f0100a0c:	74 f0                	je     f01009fe <monitor+0x9f>
f0100a0e:	89 c6                	mov    %eax,%esi
	argv[argc] = 0;
f0100a10:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a17:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a1e:	eb 1e                	jmp    f0100a3e <monitor+0xdf>
			buf++;
f0100a20:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a23:	0f b6 06             	movzbl (%esi),%eax
f0100a26:	84 c0                	test   %al,%al
f0100a28:	74 14                	je     f0100a3e <monitor+0xdf>
f0100a2a:	83 ec 08             	sub    $0x8,%esp
f0100a2d:	0f be c0             	movsbl %al,%eax
f0100a30:	50                   	push   %eax
f0100a31:	57                   	push   %edi
f0100a32:	e8 ec 3c 00 00       	call   f0104723 <strchr>
f0100a37:	83 c4 10             	add    $0x10,%esp
f0100a3a:	85 c0                	test   %eax,%eax
f0100a3c:	74 e2                	je     f0100a20 <monitor+0xc1>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a3e:	0f b6 06             	movzbl (%esi),%eax
f0100a41:	84 c0                	test   %al,%al
f0100a43:	0f 85 63 ff ff ff    	jne    f01009ac <monitor+0x4d>
	argv[argc] = 0;
f0100a49:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a4c:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a53:	00 
	if (argc == 0)
f0100a54:	85 c0                	test   %eax,%eax
f0100a56:	74 9e                	je     f01009f6 <monitor+0x97>
f0100a58:	8d b3 20 20 00 00    	lea    0x2020(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a63:	89 7d a0             	mov    %edi,-0x60(%ebp)
f0100a66:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a68:	83 ec 08             	sub    $0x8,%esp
f0100a6b:	ff 36                	pushl  (%esi)
f0100a6d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a70:	e8 50 3c 00 00       	call   f01046c5 <strcmp>
f0100a75:	83 c4 10             	add    $0x10,%esp
f0100a78:	85 c0                	test   %eax,%eax
f0100a7a:	74 28                	je     f0100aa4 <monitor+0x145>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a7c:	83 c7 01             	add    $0x1,%edi
f0100a7f:	83 c6 0c             	add    $0xc,%esi
f0100a82:	83 ff 04             	cmp    $0x4,%edi
f0100a85:	75 e1                	jne    f0100a68 <monitor+0x109>
f0100a87:	8b 7d a0             	mov    -0x60(%ebp),%edi
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a8a:	83 ec 08             	sub    $0x8,%esp
f0100a8d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a90:	8d 83 d7 9e f7 ff    	lea    -0x86129(%ebx),%eax
f0100a96:	50                   	push   %eax
f0100a97:	e8 14 2c 00 00       	call   f01036b0 <cprintf>
f0100a9c:	83 c4 10             	add    $0x10,%esp
f0100a9f:	e9 52 ff ff ff       	jmp    f01009f6 <monitor+0x97>
f0100aa4:	89 f8                	mov    %edi,%eax
f0100aa6:	8b 7d a0             	mov    -0x60(%ebp),%edi
			return commands[i].func(argc, argv, tf);
f0100aa9:	83 ec 04             	sub    $0x4,%esp
f0100aac:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100aaf:	ff 75 08             	pushl  0x8(%ebp)
f0100ab2:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ab5:	52                   	push   %edx
f0100ab6:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100ab9:	ff 94 83 28 20 00 00 	call   *0x2028(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ac0:	83 c4 10             	add    $0x10,%esp
f0100ac3:	85 c0                	test   %eax,%eax
f0100ac5:	0f 89 2b ff ff ff    	jns    f01009f6 <monitor+0x97>
				break;
	}
}
f0100acb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ace:	5b                   	pop    %ebx
f0100acf:	5e                   	pop    %esi
f0100ad0:	5f                   	pop    %edi
f0100ad1:	5d                   	pop    %ebp
f0100ad2:	c3                   	ret    

f0100ad3 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100ad3:	55                   	push   %ebp
f0100ad4:	89 e5                	mov    %esp,%ebp
f0100ad6:	e8 9a 26 00 00       	call   f0103175 <__x86.get_pc_thunk.dx>
f0100adb:	81 c2 45 a5 08 00    	add    $0x8a545,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ae1:	83 ba 18 23 00 00 00 	cmpl   $0x0,0x2318(%edx)
f0100ae8:	74 0e                	je     f0100af8 <boot_alloc+0x25>
	// LAB 2: Your code here.********************************************************************

	// 两步：1、分配一个足够大的页面  2、更新 nextfree ，要为4096的整数倍
	// 并不需要真正的分配内存，就只是先占个坑
	// 如果n>0，就返回分配空间的首地址
	if(n>0){
f0100aea:	85 c0                	test   %eax,%eax
f0100aec:	75 24                	jne    f0100b12 <boot_alloc+0x3f>
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
		return result;
	}
	// 如果n==0，就返回nextfree
	if(n==0){
		return nextfree;
f0100aee:	8b 8a 18 23 00 00    	mov    0x2318(%edx),%ecx
	}

	return NULL;
}
f0100af4:	89 c8                	mov    %ecx,%eax
f0100af6:	5d                   	pop    %ebp
f0100af7:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100af8:	c7 c1 00 e0 18 f0    	mov    $0xf018e000,%ecx
f0100afe:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100b04:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b0a:	89 8a 18 23 00 00    	mov    %ecx,0x2318(%edx)
f0100b10:	eb d8                	jmp    f0100aea <boot_alloc+0x17>
		result = nextfree;
f0100b12:	8b 8a 18 23 00 00    	mov    0x2318(%edx),%ecx
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100b18:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0100b1f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b24:	89 82 18 23 00 00    	mov    %eax,0x2318(%edx)
		return result;
f0100b2a:	eb c8                	jmp    f0100af4 <boot_alloc+0x21>

f0100b2c <nvram_read>:
{
f0100b2c:	55                   	push   %ebp
f0100b2d:	89 e5                	mov    %esp,%ebp
f0100b2f:	57                   	push   %edi
f0100b30:	56                   	push   %esi
f0100b31:	53                   	push   %ebx
f0100b32:	83 ec 18             	sub    $0x18,%esp
f0100b35:	e8 2d f6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100b3a:	81 c3 e6 a4 08 00    	add    $0x8a4e6,%ebx
f0100b40:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b42:	50                   	push   %eax
f0100b43:	e8 e1 2a 00 00       	call   f0103629 <mc146818_read>
f0100b48:	89 c6                	mov    %eax,%esi
f0100b4a:	83 c7 01             	add    $0x1,%edi
f0100b4d:	89 3c 24             	mov    %edi,(%esp)
f0100b50:	e8 d4 2a 00 00       	call   f0103629 <mc146818_read>
f0100b55:	c1 e0 08             	shl    $0x8,%eax
f0100b58:	09 f0                	or     %esi,%eax
}
f0100b5a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b5d:	5b                   	pop    %ebx
f0100b5e:	5e                   	pop    %esi
f0100b5f:	5f                   	pop    %edi
f0100b60:	5d                   	pop    %ebp
f0100b61:	c3                   	ret    

f0100b62 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b62:	55                   	push   %ebp
f0100b63:	89 e5                	mov    %esp,%ebp
f0100b65:	56                   	push   %esi
f0100b66:	53                   	push   %ebx
f0100b67:	e8 0d 26 00 00       	call   f0103179 <__x86.get_pc_thunk.cx>
f0100b6c:	81 c1 b4 a4 08 00    	add    $0x8a4b4,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b72:	89 d3                	mov    %edx,%ebx
f0100b74:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b77:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b7a:	a8 01                	test   $0x1,%al
f0100b7c:	74 5a                	je     f0100bd8 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b7e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
// 这个宏把真实的物理地址转化为‘Remapped Physical Memory’段的虚拟地址，与 PADDR 相反

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b83:	89 c6                	mov    %eax,%esi
f0100b85:	c1 ee 0c             	shr    $0xc,%esi
f0100b88:	c7 c3 08 e0 18 f0    	mov    $0xf018e008,%ebx
f0100b8e:	3b 33                	cmp    (%ebx),%esi
f0100b90:	73 2b                	jae    f0100bbd <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b92:	c1 ea 0c             	shr    $0xc,%edx
f0100b95:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b9b:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100ba2:	89 c2                	mov    %eax,%edx
f0100ba4:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ba7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bac:	85 d2                	test   %edx,%edx
f0100bae:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100bb3:	0f 44 c2             	cmove  %edx,%eax
}
f0100bb6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100bb9:	5b                   	pop    %ebx
f0100bba:	5e                   	pop    %esi
f0100bbb:	5d                   	pop    %ebp
f0100bbc:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bbd:	50                   	push   %eax
f0100bbe:	8d 81 d8 a0 f7 ff    	lea    -0x85f28(%ecx),%eax
f0100bc4:	50                   	push   %eax
f0100bc5:	68 38 03 00 00       	push   $0x338
f0100bca:	8d 81 c5 a8 f7 ff    	lea    -0x8573b(%ecx),%eax
f0100bd0:	50                   	push   %eax
f0100bd1:	89 cb                	mov    %ecx,%ebx
f0100bd3:	e8 d9 f4 ff ff       	call   f01000b1 <_panic>
		return ~0;
f0100bd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bdd:	eb d7                	jmp    f0100bb6 <check_va2pa+0x54>

f0100bdf <check_page_free_list>:
{
f0100bdf:	55                   	push   %ebp
f0100be0:	89 e5                	mov    %esp,%ebp
f0100be2:	57                   	push   %edi
f0100be3:	56                   	push   %esi
f0100be4:	53                   	push   %ebx
f0100be5:	83 ec 3c             	sub    $0x3c,%esp
f0100be8:	e8 94 25 00 00       	call   f0103181 <__x86.get_pc_thunk.di>
f0100bed:	81 c7 33 a4 08 00    	add    $0x8a433,%edi
f0100bf3:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bf6:	84 c0                	test   %al,%al
f0100bf8:	0f 85 dd 02 00 00    	jne    f0100edb <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100bfe:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100c01:	83 b8 1c 23 00 00 00 	cmpl   $0x0,0x231c(%eax)
f0100c08:	74 0c                	je     f0100c16 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c0a:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100c11:	e9 2f 03 00 00       	jmp    f0100f45 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100c16:	83 ec 04             	sub    $0x4,%esp
f0100c19:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c1c:	8d 83 fc a0 f7 ff    	lea    -0x85f04(%ebx),%eax
f0100c22:	50                   	push   %eax
f0100c23:	68 74 02 00 00       	push   $0x274
f0100c28:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100c2e:	50                   	push   %eax
f0100c2f:	e8 7d f4 ff ff       	call   f01000b1 <_panic>
f0100c34:	50                   	push   %eax
f0100c35:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c38:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f0100c3e:	50                   	push   %eax
f0100c3f:	6a 5d                	push   $0x5d
f0100c41:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f0100c47:	50                   	push   %eax
f0100c48:	e8 64 f4 ff ff       	call   f01000b1 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c4d:	8b 36                	mov    (%esi),%esi
f0100c4f:	85 f6                	test   %esi,%esi
f0100c51:	74 40                	je     f0100c93 <check_page_free_list+0xb4>

// (pp - pages)为页号，(pp - pages) << PGSHIFT 为页号左移12位，也就是该页的物理地址
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c53:	89 f0                	mov    %esi,%eax
f0100c55:	2b 07                	sub    (%edi),%eax
f0100c57:	c1 f8 03             	sar    $0x3,%eax
f0100c5a:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c5d:	89 c2                	mov    %eax,%edx
f0100c5f:	c1 ea 16             	shr    $0x16,%edx
f0100c62:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c65:	73 e6                	jae    f0100c4d <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100c67:	89 c2                	mov    %eax,%edx
f0100c69:	c1 ea 0c             	shr    $0xc,%edx
f0100c6c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c6f:	3b 11                	cmp    (%ecx),%edx
f0100c71:	73 c1                	jae    f0100c34 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100c73:	83 ec 04             	sub    $0x4,%esp
f0100c76:	68 80 00 00 00       	push   $0x80
f0100c7b:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c80:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c85:	50                   	push   %eax
f0100c86:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c89:	e8 d2 3a 00 00       	call   f0104760 <memset>
f0100c8e:	83 c4 10             	add    $0x10,%esp
f0100c91:	eb ba                	jmp    f0100c4d <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100c93:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c98:	e8 36 fe ff ff       	call   f0100ad3 <boot_alloc>
f0100c9d:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ca0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ca3:	8b 97 1c 23 00 00    	mov    0x231c(%edi),%edx
		assert(pp >= pages);
f0100ca9:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0100caf:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100cb1:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f0100cb7:	8b 00                	mov    (%eax),%eax
f0100cb9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100cbc:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cbf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cc2:	bf 00 00 00 00       	mov    $0x0,%edi
f0100cc7:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cca:	e9 08 01 00 00       	jmp    f0100dd7 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100ccf:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cd2:	8d 83 df a8 f7 ff    	lea    -0x85721(%ebx),%eax
f0100cd8:	50                   	push   %eax
f0100cd9:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100cdf:	50                   	push   %eax
f0100ce0:	68 8e 02 00 00       	push   $0x28e
f0100ce5:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100ceb:	50                   	push   %eax
f0100cec:	e8 c0 f3 ff ff       	call   f01000b1 <_panic>
		assert(pp < pages + npages);
f0100cf1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cf4:	8d 83 00 a9 f7 ff    	lea    -0x85700(%ebx),%eax
f0100cfa:	50                   	push   %eax
f0100cfb:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100d01:	50                   	push   %eax
f0100d02:	68 8f 02 00 00       	push   $0x28f
f0100d07:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100d0d:	50                   	push   %eax
f0100d0e:	e8 9e f3 ff ff       	call   f01000b1 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d13:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d16:	8d 83 20 a1 f7 ff    	lea    -0x85ee0(%ebx),%eax
f0100d1c:	50                   	push   %eax
f0100d1d:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100d23:	50                   	push   %eax
f0100d24:	68 90 02 00 00       	push   $0x290
f0100d29:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100d2f:	50                   	push   %eax
f0100d30:	e8 7c f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != 0);
f0100d35:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d38:	8d 83 14 a9 f7 ff    	lea    -0x856ec(%ebx),%eax
f0100d3e:	50                   	push   %eax
f0100d3f:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100d45:	50                   	push   %eax
f0100d46:	68 93 02 00 00       	push   $0x293
f0100d4b:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100d51:	50                   	push   %eax
f0100d52:	e8 5a f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d57:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d5a:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100d60:	50                   	push   %eax
f0100d61:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100d67:	50                   	push   %eax
f0100d68:	68 94 02 00 00       	push   $0x294
f0100d6d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100d73:	50                   	push   %eax
f0100d74:	e8 38 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d79:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d7c:	8d 83 54 a1 f7 ff    	lea    -0x85eac(%ebx),%eax
f0100d82:	50                   	push   %eax
f0100d83:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100d89:	50                   	push   %eax
f0100d8a:	68 95 02 00 00       	push   $0x295
f0100d8f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100d95:	50                   	push   %eax
f0100d96:	e8 16 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d9b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d9e:	8d 83 3e a9 f7 ff    	lea    -0x856c2(%ebx),%eax
f0100da4:	50                   	push   %eax
f0100da5:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100dab:	50                   	push   %eax
f0100dac:	68 96 02 00 00       	push   $0x296
f0100db1:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100db7:	50                   	push   %eax
f0100db8:	e8 f4 f2 ff ff       	call   f01000b1 <_panic>
	if (PGNUM(pa) >= npages)
f0100dbd:	89 c6                	mov    %eax,%esi
f0100dbf:	c1 ee 0c             	shr    $0xc,%esi
f0100dc2:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100dc5:	76 70                	jbe    f0100e37 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100dc7:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dcc:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100dcf:	77 7f                	ja     f0100e50 <check_page_free_list+0x271>
			++nfree_extmem;
f0100dd1:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dd5:	8b 12                	mov    (%edx),%edx
f0100dd7:	85 d2                	test   %edx,%edx
f0100dd9:	0f 84 93 00 00 00    	je     f0100e72 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100ddf:	39 d1                	cmp    %edx,%ecx
f0100de1:	0f 87 e8 fe ff ff    	ja     f0100ccf <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100de7:	39 d3                	cmp    %edx,%ebx
f0100de9:	0f 86 02 ff ff ff    	jbe    f0100cf1 <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100def:	89 d0                	mov    %edx,%eax
f0100df1:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100df4:	a8 07                	test   $0x7,%al
f0100df6:	0f 85 17 ff ff ff    	jne    f0100d13 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100dfc:	c1 f8 03             	sar    $0x3,%eax
f0100dff:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100e02:	85 c0                	test   %eax,%eax
f0100e04:	0f 84 2b ff ff ff    	je     f0100d35 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e0a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e0f:	0f 84 42 ff ff ff    	je     f0100d57 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e15:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e1a:	0f 84 59 ff ff ff    	je     f0100d79 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e20:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e25:	0f 84 70 ff ff ff    	je     f0100d9b <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e2b:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e30:	77 8b                	ja     f0100dbd <check_page_free_list+0x1de>
			++nfree_basemem;
f0100e32:	83 c7 01             	add    $0x1,%edi
f0100e35:	eb 9e                	jmp    f0100dd5 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e37:	50                   	push   %eax
f0100e38:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e3b:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f0100e41:	50                   	push   %eax
f0100e42:	6a 5d                	push   $0x5d
f0100e44:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f0100e4a:	50                   	push   %eax
f0100e4b:	e8 61 f2 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e50:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e53:	8d 83 78 a1 f7 ff    	lea    -0x85e88(%ebx),%eax
f0100e59:	50                   	push   %eax
f0100e5a:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100e60:	50                   	push   %eax
f0100e61:	68 97 02 00 00       	push   $0x297
f0100e66:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100e6c:	50                   	push   %eax
f0100e6d:	e8 3f f2 ff ff       	call   f01000b1 <_panic>
f0100e72:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100e75:	85 ff                	test   %edi,%edi
f0100e77:	7e 1e                	jle    f0100e97 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100e79:	85 f6                	test   %esi,%esi
f0100e7b:	7e 3c                	jle    f0100eb9 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e7d:	83 ec 0c             	sub    $0xc,%esp
f0100e80:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e83:	8d 83 c0 a1 f7 ff    	lea    -0x85e40(%ebx),%eax
f0100e89:	50                   	push   %eax
f0100e8a:	e8 21 28 00 00       	call   f01036b0 <cprintf>
}
f0100e8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e92:	5b                   	pop    %ebx
f0100e93:	5e                   	pop    %esi
f0100e94:	5f                   	pop    %edi
f0100e95:	5d                   	pop    %ebp
f0100e96:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e97:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e9a:	8d 83 58 a9 f7 ff    	lea    -0x856a8(%ebx),%eax
f0100ea0:	50                   	push   %eax
f0100ea1:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100ea7:	50                   	push   %eax
f0100ea8:	68 9f 02 00 00       	push   $0x29f
f0100ead:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100eb3:	50                   	push   %eax
f0100eb4:	e8 f8 f1 ff ff       	call   f01000b1 <_panic>
	assert(nfree_extmem > 0);
f0100eb9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ebc:	8d 83 6a a9 f7 ff    	lea    -0x85696(%ebx),%eax
f0100ec2:	50                   	push   %eax
f0100ec3:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0100ec9:	50                   	push   %eax
f0100eca:	68 a0 02 00 00       	push   $0x2a0
f0100ecf:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0100ed5:	50                   	push   %eax
f0100ed6:	e8 d6 f1 ff ff       	call   f01000b1 <_panic>
	if (!page_free_list)
f0100edb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100ede:	8b 80 1c 23 00 00    	mov    0x231c(%eax),%eax
f0100ee4:	85 c0                	test   %eax,%eax
f0100ee6:	0f 84 2a fd ff ff    	je     f0100c16 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100eec:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100eef:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ef2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ef5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100ef8:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100efb:	c7 c3 10 e0 18 f0    	mov    $0xf018e010,%ebx
f0100f01:	89 c2                	mov    %eax,%edx
f0100f03:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100f05:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100f0b:	0f 95 c2             	setne  %dl
f0100f0e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100f11:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100f15:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100f17:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f1b:	8b 00                	mov    (%eax),%eax
f0100f1d:	85 c0                	test   %eax,%eax
f0100f1f:	75 e0                	jne    f0100f01 <check_page_free_list+0x322>
		*tp[1] = 0;
f0100f21:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f24:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100f2a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f30:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f32:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f35:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100f38:	89 87 1c 23 00 00    	mov    %eax,0x231c(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f3e:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f45:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f48:	8b b0 1c 23 00 00    	mov    0x231c(%eax),%esi
f0100f4e:	c7 c7 10 e0 18 f0    	mov    $0xf018e010,%edi
	if (PGNUM(pa) >= npages)
f0100f54:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f0100f5a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f5d:	e9 ed fc ff ff       	jmp    f0100c4f <check_page_free_list+0x70>

f0100f62 <page_init>:
{
f0100f62:	55                   	push   %ebp
f0100f63:	89 e5                	mov    %esp,%ebp
f0100f65:	57                   	push   %edi
f0100f66:	56                   	push   %esi
f0100f67:	53                   	push   %ebx
f0100f68:	83 ec 2c             	sub    $0x2c,%esp
f0100f6b:	e8 0d 22 00 00       	call   f010317d <__x86.get_pc_thunk.si>
f0100f70:	81 c6 b0 a0 08 00    	add    $0x8a0b0,%esi
	physaddr_t truly_end = PADDR(boot_alloc(0));
f0100f76:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f7b:	e8 53 fb ff ff       	call   f0100ad3 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100f80:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f85:	76 33                	jbe    f0100fba <page_init+0x58>
	return (physaddr_t)kva - KERNBASE;
f0100f87:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f8c:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f8f:	8b 86 1c 23 00 00    	mov    0x231c(%esi),%eax
f0100f95:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < npages; i++)
f0100f98:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
f0100f9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fa1:	c7 c3 08 e0 18 f0    	mov    $0xf018e008,%ebx
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
f0100fa7:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0100fad:	89 55 d8             	mov    %edx,-0x28(%ebp)
			page_free_list = &pages[i];
f0100fb0:	89 55 d0             	mov    %edx,-0x30(%ebp)
			pages[i].pp_ref = 1;
f0100fb3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100fb6:	89 c1                	mov    %eax,%ecx
	for (i = 0; i < npages; i++)
f0100fb8:	eb 55                	jmp    f010100f <page_init+0xad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fba:	50                   	push   %eax
f0100fbb:	8d 86 e4 a1 f7 ff    	lea    -0x85e1c(%esi),%eax
f0100fc1:	50                   	push   %eax
f0100fc2:	68 22 01 00 00       	push   $0x122
f0100fc7:	8d 86 c5 a8 f7 ff    	lea    -0x8573b(%esi),%eax
f0100fcd:	50                   	push   %eax
f0100fce:	89 f3                	mov    %esi,%ebx
f0100fd0:	e8 dc f0 ff ff       	call   f01000b1 <_panic>
f0100fd5:	8d 04 cd 00 00 00 00 	lea    0x0(,%ecx,8),%eax
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
f0100fdc:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100fdf:	89 c2                	mov    %eax,%edx
f0100fe1:	03 17                	add    (%edi),%edx
	return (pp - pages) << PGSHIFT;
f0100fe3:	89 c7                	mov    %eax,%edi
f0100fe5:	c1 e7 09             	shl    $0x9,%edi
f0100fe8:	39 7d dc             	cmp    %edi,-0x24(%ebp)
f0100feb:	76 08                	jbe    f0100ff5 <page_init+0x93>
f0100fed:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f0100ff3:	77 35                	ja     f010102a <page_init+0xc8>
			pages[i].pp_ref = 0;
f0100ff5:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100ffb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ffe:	89 3a                	mov    %edi,(%edx)
			page_free_list = &pages[i];
f0101000:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101003:	03 02                	add    (%edx),%eax
f0101005:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101008:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
	for (i = 0; i < npages; i++)
f010100c:	83 c1 01             	add    $0x1,%ecx
f010100f:	39 0b                	cmp    %ecx,(%ebx)
f0101011:	76 25                	jbe    f0101038 <page_init+0xd6>
		if(i==0){
f0101013:	85 c9                	test   %ecx,%ecx
f0101015:	75 be                	jne    f0100fd5 <page_init+0x73>
			pages[i].pp_ref = 1;
f0101017:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010101a:	8b 00                	mov    (%eax),%eax
f010101c:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0101022:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101028:	eb e2                	jmp    f010100c <page_init+0xaa>
			pages[i].pp_ref = 1;
f010102a:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0101030:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0101036:	eb d4                	jmp    f010100c <page_init+0xaa>
f0101038:	80 7d e3 00          	cmpb   $0x0,-0x1d(%ebp)
f010103c:	75 08                	jne    f0101046 <page_init+0xe4>
}
f010103e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101041:	5b                   	pop    %ebx
f0101042:	5e                   	pop    %esi
f0101043:	5f                   	pop    %edi
f0101044:	5d                   	pop    %ebp
f0101045:	c3                   	ret    
f0101046:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101049:	89 86 1c 23 00 00    	mov    %eax,0x231c(%esi)
f010104f:	eb ed                	jmp    f010103e <page_init+0xdc>

f0101051 <page_alloc>:
{
f0101051:	55                   	push   %ebp
f0101052:	89 e5                	mov    %esp,%ebp
f0101054:	56                   	push   %esi
f0101055:	53                   	push   %ebx
f0101056:	e8 0c f1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010105b:	81 c3 c5 9f 08 00    	add    $0x89fc5,%ebx
	if(page_free_list){
f0101061:	8b b3 1c 23 00 00    	mov    0x231c(%ebx),%esi
f0101067:	85 f6                	test   %esi,%esi
f0101069:	74 14                	je     f010107f <page_alloc+0x2e>
		page_free_list = freePage->pp_link;
f010106b:	8b 06                	mov    (%esi),%eax
f010106d:	89 83 1c 23 00 00    	mov    %eax,0x231c(%ebx)
		freePage->pp_link = NULL;
f0101073:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if(alloc_flags&ALLOC_ZERO){    // 只有这个条件满足时才把内存页面初始化为0
f0101079:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010107d:	75 09                	jne    f0101088 <page_alloc+0x37>
}
f010107f:	89 f0                	mov    %esi,%eax
f0101081:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101084:	5b                   	pop    %ebx
f0101085:	5e                   	pop    %esi
f0101086:	5d                   	pop    %ebp
f0101087:	c3                   	ret    
f0101088:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f010108e:	89 f2                	mov    %esi,%edx
f0101090:	2b 10                	sub    (%eax),%edx
f0101092:	89 d0                	mov    %edx,%eax
f0101094:	c1 f8 03             	sar    $0x3,%eax
f0101097:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010109a:	89 c1                	mov    %eax,%ecx
f010109c:	c1 e9 0c             	shr    $0xc,%ecx
f010109f:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f01010a5:	3b 0a                	cmp    (%edx),%ecx
f01010a7:	73 1a                	jae    f01010c3 <page_alloc+0x72>
			memset(page2kva(freePage), 0, PGSIZE);
f01010a9:	83 ec 04             	sub    $0x4,%esp
f01010ac:	68 00 10 00 00       	push   $0x1000
f01010b1:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01010b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010b8:	50                   	push   %eax
f01010b9:	e8 a2 36 00 00       	call   f0104760 <memset>
f01010be:	83 c4 10             	add    $0x10,%esp
f01010c1:	eb bc                	jmp    f010107f <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010c3:	50                   	push   %eax
f01010c4:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f01010ca:	50                   	push   %eax
f01010cb:	6a 5d                	push   $0x5d
f01010cd:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f01010d3:	50                   	push   %eax
f01010d4:	e8 d8 ef ff ff       	call   f01000b1 <_panic>

f01010d9 <page_free>:
{
f01010d9:	55                   	push   %ebp
f01010da:	89 e5                	mov    %esp,%ebp
f01010dc:	53                   	push   %ebx
f01010dd:	83 ec 04             	sub    $0x4,%esp
f01010e0:	e8 82 f0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01010e5:	81 c3 3b 9f 08 00    	add    $0x89f3b,%ebx
f01010eb:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_ref||pp->pp_link){
f01010ee:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010f3:	75 18                	jne    f010110d <page_free+0x34>
f01010f5:	83 38 00             	cmpl   $0x0,(%eax)
f01010f8:	75 13                	jne    f010110d <page_free+0x34>
	pp->pp_link = page_free_list;
f01010fa:	8b 8b 1c 23 00 00    	mov    0x231c(%ebx),%ecx
f0101100:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0101102:	89 83 1c 23 00 00    	mov    %eax,0x231c(%ebx)
}
f0101108:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010110b:	c9                   	leave  
f010110c:	c3                   	ret    
		panic("Page is free, have not to free\n");
f010110d:	83 ec 04             	sub    $0x4,%esp
f0101110:	8d 83 08 a2 f7 ff    	lea    -0x85df8(%ebx),%eax
f0101116:	50                   	push   %eax
f0101117:	68 5c 01 00 00       	push   $0x15c
f010111c:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101122:	50                   	push   %eax
f0101123:	e8 89 ef ff ff       	call   f01000b1 <_panic>

f0101128 <page_decref>:
{
f0101128:	55                   	push   %ebp
f0101129:	89 e5                	mov    %esp,%ebp
f010112b:	83 ec 08             	sub    $0x8,%esp
f010112e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101131:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101135:	83 e8 01             	sub    $0x1,%eax
f0101138:	66 89 42 04          	mov    %ax,0x4(%edx)
f010113c:	66 85 c0             	test   %ax,%ax
f010113f:	74 02                	je     f0101143 <page_decref+0x1b>
}
f0101141:	c9                   	leave  
f0101142:	c3                   	ret    
		page_free(pp);
f0101143:	83 ec 0c             	sub    $0xc,%esp
f0101146:	52                   	push   %edx
f0101147:	e8 8d ff ff ff       	call   f01010d9 <page_free>
f010114c:	83 c4 10             	add    $0x10,%esp
}
f010114f:	eb f0                	jmp    f0101141 <page_decref+0x19>

f0101151 <pgdir_walk>:
{
f0101151:	55                   	push   %ebp
f0101152:	89 e5                	mov    %esp,%ebp
f0101154:	57                   	push   %edi
f0101155:	56                   	push   %esi
f0101156:	53                   	push   %ebx
f0101157:	83 ec 0c             	sub    $0xc,%esp
f010115a:	e8 08 f0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010115f:	81 c3 c1 9e 08 00    	add    $0x89ec1,%ebx
f0101165:	8b 75 0c             	mov    0xc(%ebp),%esi
	size_t pgt_index = PTX(va);  // 页表索引
f0101168:	89 f7                	mov    %esi,%edi
f010116a:	c1 ef 0c             	shr    $0xc,%edi
f010116d:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
	size_t pgdir_index = PDX(va);  // 页目录索引
f0101173:	c1 ee 16             	shr    $0x16,%esi
	pde_t* pde = pgdir+pgdir_index;   // 页目录项指针
f0101176:	c1 e6 02             	shl    $0x2,%esi
f0101179:	03 75 08             	add    0x8(%ebp),%esi
	if (!*pde & PTE_P)
f010117c:	83 3e 00             	cmpl   $0x0,(%esi)
f010117f:	75 2f                	jne    f01011b0 <pgdir_walk+0x5f>
		if(!create)
f0101181:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101185:	74 67                	je     f01011ee <pgdir_walk+0x9d>
		struct PageInfo *new_page = page_alloc(1);
f0101187:	83 ec 0c             	sub    $0xc,%esp
f010118a:	6a 01                	push   $0x1
f010118c:	e8 c0 fe ff ff       	call   f0101051 <page_alloc>
		if(!new_page)
f0101191:	83 c4 10             	add    $0x10,%esp
f0101194:	85 c0                	test   %eax,%eax
f0101196:	74 5d                	je     f01011f5 <pgdir_walk+0xa4>
		new_page->pp_ref++;
f0101198:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010119d:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f01011a3:	2b 02                	sub    (%edx),%eax
f01011a5:	c1 f8 03             	sar    $0x3,%eax
f01011a8:	c1 e0 0c             	shl    $0xc,%eax
		*pde = page2pa(new_page) | PTE_P | PTE_W | PTE_U;   // 更新页目录项,为什么要设置 PTE_W  PTE_U 这两位?
f01011ab:	83 c8 07             	or     $0x7,%eax
f01011ae:	89 06                	mov    %eax,(%esi)
	pte = (pte_t *)KADDR(PTE_ADDR(*pde));
f01011b0:	8b 06                	mov    (%esi),%eax
f01011b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01011b7:	89 c1                	mov    %eax,%ecx
f01011b9:	c1 e9 0c             	shr    $0xc,%ecx
f01011bc:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f01011c2:	3b 0a                	cmp    (%edx),%ecx
f01011c4:	73 0f                	jae    f01011d5 <pgdir_walk+0x84>
	return pte + pgt_index;    // 返回页表项的指针
f01011c6:	8d 84 b8 00 00 00 f0 	lea    -0x10000000(%eax,%edi,4),%eax
}
f01011cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011d0:	5b                   	pop    %ebx
f01011d1:	5e                   	pop    %esi
f01011d2:	5f                   	pop    %edi
f01011d3:	5d                   	pop    %ebp
f01011d4:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011d5:	50                   	push   %eax
f01011d6:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f01011dc:	50                   	push   %eax
f01011dd:	68 9e 01 00 00       	push   $0x19e
f01011e2:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01011e8:	50                   	push   %eax
f01011e9:	e8 c3 ee ff ff       	call   f01000b1 <_panic>
			return NULL;
f01011ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01011f3:	eb d8                	jmp    f01011cd <pgdir_walk+0x7c>
			return NULL;
f01011f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01011fa:	eb d1                	jmp    f01011cd <pgdir_walk+0x7c>

f01011fc <boot_map_region>:
{
f01011fc:	55                   	push   %ebp
f01011fd:	89 e5                	mov    %esp,%ebp
f01011ff:	57                   	push   %edi
f0101200:	56                   	push   %esi
f0101201:	53                   	push   %ebx
f0101202:	83 ec 1c             	sub    $0x1c,%esp
f0101205:	e8 77 1f 00 00       	call   f0103181 <__x86.get_pc_thunk.di>
f010120a:	81 c7 16 9e 08 00    	add    $0x89e16,%edi
f0101210:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0101213:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101216:	8b 45 08             	mov    0x8(%ebp),%eax
	for (size_t i = 0; i < size/PGSIZE;++i){
f0101219:	c1 e9 0c             	shr    $0xc,%ecx
f010121c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010121f:	89 c3                	mov    %eax,%ebx
f0101221:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t *pte = pgdir_walk(pgdir, (void*)va, 1);
f0101226:	89 d7                	mov    %edx,%edi
f0101228:	29 c7                	sub    %eax,%edi
		*pte = pa | perm | PTE_P;  // 要修改va对应的页表项，使其指向pa
f010122a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010122d:	83 c8 01             	or     $0x1,%eax
f0101230:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (size_t i = 0; i < size/PGSIZE;++i){
f0101233:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f0101236:	74 48                	je     f0101280 <boot_map_region+0x84>
		pte_t *pte = pgdir_walk(pgdir, (void*)va, 1);
f0101238:	83 ec 04             	sub    $0x4,%esp
f010123b:	6a 01                	push   $0x1
f010123d:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0101240:	50                   	push   %eax
f0101241:	ff 75 e0             	pushl  -0x20(%ebp)
f0101244:	e8 08 ff ff ff       	call   f0101151 <pgdir_walk>
		if(!pte)
f0101249:	83 c4 10             	add    $0x10,%esp
f010124c:	85 c0                	test   %eax,%eax
f010124e:	74 12                	je     f0101262 <boot_map_region+0x66>
		*pte = pa | perm | PTE_P;  // 要修改va对应的页表项，使其指向pa
f0101250:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101253:	09 da                	or     %ebx,%edx
f0101255:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f0101257:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (size_t i = 0; i < size/PGSIZE;++i){
f010125d:	83 c6 01             	add    $0x1,%esi
f0101260:	eb d1                	jmp    f0101233 <boot_map_region+0x37>
			panic("boot_map_region(): out of memory\n");
f0101262:	83 ec 04             	sub    $0x4,%esp
f0101265:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101268:	8d 83 28 a2 f7 ff    	lea    -0x85dd8(%ebx),%eax
f010126e:	50                   	push   %eax
f010126f:	68 b8 01 00 00       	push   $0x1b8
f0101274:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010127a:	50                   	push   %eax
f010127b:	e8 31 ee ff ff       	call   f01000b1 <_panic>
}
f0101280:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101283:	5b                   	pop    %ebx
f0101284:	5e                   	pop    %esi
f0101285:	5f                   	pop    %edi
f0101286:	5d                   	pop    %ebp
f0101287:	c3                   	ret    

f0101288 <page_lookup>:
{
f0101288:	55                   	push   %ebp
f0101289:	89 e5                	mov    %esp,%ebp
f010128b:	56                   	push   %esi
f010128c:	53                   	push   %ebx
f010128d:	e8 d5 ee ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0101292:	81 c3 8e 9d 08 00    	add    $0x89d8e,%ebx
f0101298:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);   // 只返回va对应的页表项，不分配新的页表页
f010129b:	83 ec 04             	sub    $0x4,%esp
f010129e:	6a 00                	push   $0x0
f01012a0:	ff 75 0c             	pushl  0xc(%ebp)
f01012a3:	ff 75 08             	pushl  0x8(%ebp)
f01012a6:	e8 a6 fe ff ff       	call   f0101151 <pgdir_walk>
	if(pte_store){
f01012ab:	83 c4 10             	add    $0x10,%esp
f01012ae:	85 f6                	test   %esi,%esi
f01012b0:	74 02                	je     f01012b4 <page_lookup+0x2c>
		*pte_store = pte;
f01012b2:	89 06                	mov    %eax,(%esi)
	if(pte){
f01012b4:	85 c0                	test   %eax,%eax
f01012b6:	74 39                	je     f01012f1 <page_lookup+0x69>
f01012b8:	8b 00                	mov    (%eax),%eax
f01012ba:	c1 e8 0c             	shr    $0xc,%eax

// pa为物理地址，PGNUM(pa)为该页的页号，函数功能与 page2pa 相反
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012bd:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f01012c3:	39 02                	cmp    %eax,(%edx)
f01012c5:	76 12                	jbe    f01012d9 <page_lookup+0x51>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01012c7:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f01012cd:	8b 12                	mov    (%edx),%edx
f01012cf:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01012d2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012d5:	5b                   	pop    %ebx
f01012d6:	5e                   	pop    %esi
f01012d7:	5d                   	pop    %ebp
f01012d8:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01012d9:	83 ec 04             	sub    $0x4,%esp
f01012dc:	8d 83 4c a2 f7 ff    	lea    -0x85db4(%ebx),%eax
f01012e2:	50                   	push   %eax
f01012e3:	6a 56                	push   $0x56
f01012e5:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f01012eb:	50                   	push   %eax
f01012ec:	e8 c0 ed ff ff       	call   f01000b1 <_panic>
	return NULL;
f01012f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01012f6:	eb da                	jmp    f01012d2 <page_lookup+0x4a>

f01012f8 <page_remove>:
{
f01012f8:	55                   	push   %ebp
f01012f9:	89 e5                	mov    %esp,%ebp
f01012fb:	53                   	push   %ebx
f01012fc:	83 ec 18             	sub    $0x18,%esp
f01012ff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0101302:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101305:	50                   	push   %eax
f0101306:	53                   	push   %ebx
f0101307:	ff 75 08             	pushl  0x8(%ebp)
f010130a:	e8 79 ff ff ff       	call   f0101288 <page_lookup>
	if (!pp)
f010130f:	83 c4 10             	add    $0x10,%esp
f0101312:	85 c0                	test   %eax,%eax
f0101314:	75 05                	jne    f010131b <page_remove+0x23>
}
f0101316:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101319:	c9                   	leave  
f010131a:	c3                   	ret    
	page_decref(pp);
f010131b:	83 ec 0c             	sub    $0xc,%esp
f010131e:	50                   	push   %eax
f010131f:	e8 04 fe ff ff       	call   f0101128 <page_decref>
	*pte = 0;
f0101324:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101327:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010132d:	0f 01 3b             	invlpg (%ebx)
f0101330:	83 c4 10             	add    $0x10,%esp
f0101333:	eb e1                	jmp    f0101316 <page_remove+0x1e>

f0101335 <page_insert>:
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	57                   	push   %edi
f0101339:	56                   	push   %esi
f010133a:	53                   	push   %ebx
f010133b:	83 ec 10             	sub    $0x10,%esp
f010133e:	e8 3e 1e 00 00       	call   f0103181 <__x86.get_pc_thunk.di>
f0101343:	81 c7 dd 9c 08 00    	add    $0x89cdd,%edi
f0101349:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f010134c:	6a 01                	push   $0x1
f010134e:	ff 75 10             	pushl  0x10(%ebp)
f0101351:	ff 75 08             	pushl  0x8(%ebp)
f0101354:	e8 f8 fd ff ff       	call   f0101151 <pgdir_walk>
	if (!pte)
f0101359:	83 c4 10             	add    $0x10,%esp
f010135c:	85 c0                	test   %eax,%eax
f010135e:	74 4c                	je     f01013ac <page_insert+0x77>
f0101360:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;   // 引用计数的增加必须在 page_remove 前面！！  this is an elegant way to handle
f0101362:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	pp->pp_link = NULL;
f0101367:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if(*pte&PTE_P){
f010136d:	f6 00 01             	testb  $0x1,(%eax)
f0101370:	75 27                	jne    f0101399 <page_insert+0x64>
	return (pp - pages) << PGSHIFT;
f0101372:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0101378:	2b 30                	sub    (%eax),%esi
f010137a:	89 f0                	mov    %esi,%eax
f010137c:	c1 f8 03             	sar    $0x3,%eax
f010137f:	c1 e0 0c             	shl    $0xc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
f0101382:	8b 55 14             	mov    0x14(%ebp),%edx
f0101385:	83 ca 01             	or     $0x1,%edx
f0101388:	09 d0                	or     %edx,%eax
f010138a:	89 03                	mov    %eax,(%ebx)
	return 0;
f010138c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101391:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101394:	5b                   	pop    %ebx
f0101395:	5e                   	pop    %esi
f0101396:	5f                   	pop    %edi
f0101397:	5d                   	pop    %ebp
f0101398:	c3                   	ret    
		page_remove(pgdir, va);
f0101399:	83 ec 08             	sub    $0x8,%esp
f010139c:	ff 75 10             	pushl  0x10(%ebp)
f010139f:	ff 75 08             	pushl  0x8(%ebp)
f01013a2:	e8 51 ff ff ff       	call   f01012f8 <page_remove>
f01013a7:	83 c4 10             	add    $0x10,%esp
f01013aa:	eb c6                	jmp    f0101372 <page_insert+0x3d>
		return -E_NO_MEM;
f01013ac:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01013b1:	eb de                	jmp    f0101391 <page_insert+0x5c>

f01013b3 <mem_init>:
{
f01013b3:	55                   	push   %ebp
f01013b4:	89 e5                	mov    %esp,%ebp
f01013b6:	57                   	push   %edi
f01013b7:	56                   	push   %esi
f01013b8:	53                   	push   %ebx
f01013b9:	83 ec 3c             	sub    $0x3c,%esp
f01013bc:	e8 48 f3 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f01013c1:	05 5f 9c 08 00       	add    $0x89c5f,%eax
f01013c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f01013c9:	b8 15 00 00 00       	mov    $0x15,%eax
f01013ce:	e8 59 f7 ff ff       	call   f0100b2c <nvram_read>
f01013d3:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01013d5:	b8 17 00 00 00       	mov    $0x17,%eax
f01013da:	e8 4d f7 ff ff       	call   f0100b2c <nvram_read>
f01013df:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013e1:	b8 34 00 00 00       	mov    $0x34,%eax
f01013e6:	e8 41 f7 ff ff       	call   f0100b2c <nvram_read>
f01013eb:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01013ee:	85 c0                	test   %eax,%eax
f01013f0:	0f 85 e8 00 00 00    	jne    f01014de <mem_init+0x12b>
		totalmem = 1 * 1024 + extmem;
f01013f6:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013fc:	85 f6                	test   %esi,%esi
f01013fe:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101401:	89 c1                	mov    %eax,%ecx
f0101403:	c1 e9 02             	shr    $0x2,%ecx
f0101406:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101409:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f010140f:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101411:	89 c2                	mov    %eax,%edx
f0101413:	29 da                	sub    %ebx,%edx
f0101415:	52                   	push   %edx
f0101416:	53                   	push   %ebx
f0101417:	50                   	push   %eax
f0101418:	8d 87 6c a2 f7 ff    	lea    -0x85d94(%edi),%eax
f010141e:	50                   	push   %eax
f010141f:	89 fb                	mov    %edi,%ebx
f0101421:	e8 8a 22 00 00       	call   f01036b0 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);    // 初始占一整页
f0101426:	b8 00 10 00 00       	mov    $0x1000,%eax
f010142b:	e8 a3 f6 ff ff       	call   f0100ad3 <boot_alloc>
f0101430:	c7 c6 0c e0 18 f0    	mov    $0xf018e00c,%esi
f0101436:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);   // 初始化为0
f0101438:	83 c4 0c             	add    $0xc,%esp
f010143b:	68 00 10 00 00       	push   $0x1000
f0101440:	6a 00                	push   $0x0
f0101442:	50                   	push   %eax
f0101443:	e8 18 33 00 00       	call   f0104760 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101448:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010144a:	83 c4 10             	add    $0x10,%esp
f010144d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101452:	0f 86 90 00 00 00    	jbe    f01014e8 <mem_init+0x135>
	return (physaddr_t)kva - KERNBASE;
f0101458:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010145e:	83 ca 05             	or     $0x5,%edx
f0101461:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101467:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010146a:	c7 c3 08 e0 18 f0    	mov    $0xf018e008,%ebx
f0101470:	8b 03                	mov    (%ebx),%eax
f0101472:	c1 e0 03             	shl    $0x3,%eax
f0101475:	e8 59 f6 ff ff       	call   f0100ad3 <boot_alloc>
f010147a:	c7 c6 10 e0 18 f0    	mov    $0xf018e010,%esi
f0101480:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101482:	83 ec 04             	sub    $0x4,%esp
f0101485:	8b 13                	mov    (%ebx),%edx
f0101487:	c1 e2 03             	shl    $0x3,%edx
f010148a:	52                   	push   %edx
f010148b:	6a 00                	push   $0x0
f010148d:	50                   	push   %eax
f010148e:	89 fb                	mov    %edi,%ebx
f0101490:	e8 cb 32 00 00       	call   f0104760 <memset>
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f0101495:	b8 00 80 01 00       	mov    $0x18000,%eax
f010149a:	e8 34 f6 ff ff       	call   f0100ad3 <boot_alloc>
f010149f:	c7 c2 44 d3 18 f0    	mov    $0xf018d344,%edx
f01014a5:	89 02                	mov    %eax,(%edx)
	memset(envs, 0, NENV * sizeof(struct Env));
f01014a7:	83 c4 0c             	add    $0xc,%esp
f01014aa:	68 00 80 01 00       	push   $0x18000
f01014af:	6a 00                	push   $0x0
f01014b1:	50                   	push   %eax
f01014b2:	e8 a9 32 00 00       	call   f0104760 <memset>
	page_init();
f01014b7:	e8 a6 fa ff ff       	call   f0100f62 <page_init>
	check_page_free_list(1);
f01014bc:	b8 01 00 00 00       	mov    $0x1,%eax
f01014c1:	e8 19 f7 ff ff       	call   f0100bdf <check_page_free_list>
	if (!pages)
f01014c6:	83 c4 10             	add    $0x10,%esp
f01014c9:	83 3e 00             	cmpl   $0x0,(%esi)
f01014cc:	74 36                	je     f0101504 <mem_init+0x151>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014d1:	8b 80 1c 23 00 00    	mov    0x231c(%eax),%eax
f01014d7:	be 00 00 00 00       	mov    $0x0,%esi
f01014dc:	eb 49                	jmp    f0101527 <mem_init+0x174>
		totalmem = 16 * 1024 + ext16mem;
f01014de:	05 00 40 00 00       	add    $0x4000,%eax
f01014e3:	e9 19 ff ff ff       	jmp    f0101401 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014e8:	50                   	push   %eax
f01014e9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01014ec:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f01014f2:	50                   	push   %eax
f01014f3:	68 9c 00 00 00       	push   $0x9c
f01014f8:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01014fe:	50                   	push   %eax
f01014ff:	e8 ad eb ff ff       	call   f01000b1 <_panic>
		panic("'pages' is a null pointer!");
f0101504:	83 ec 04             	sub    $0x4,%esp
f0101507:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010150a:	8d 83 7b a9 f7 ff    	lea    -0x85685(%ebx),%eax
f0101510:	50                   	push   %eax
f0101511:	68 b3 02 00 00       	push   $0x2b3
f0101516:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010151c:	50                   	push   %eax
f010151d:	e8 8f eb ff ff       	call   f01000b1 <_panic>
		++nfree;
f0101522:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101525:	8b 00                	mov    (%eax),%eax
f0101527:	85 c0                	test   %eax,%eax
f0101529:	75 f7                	jne    f0101522 <mem_init+0x16f>
	assert((pp0 = page_alloc(0)));
f010152b:	83 ec 0c             	sub    $0xc,%esp
f010152e:	6a 00                	push   $0x0
f0101530:	e8 1c fb ff ff       	call   f0101051 <page_alloc>
f0101535:	89 c3                	mov    %eax,%ebx
f0101537:	83 c4 10             	add    $0x10,%esp
f010153a:	85 c0                	test   %eax,%eax
f010153c:	0f 84 3b 02 00 00    	je     f010177d <mem_init+0x3ca>
	assert((pp1 = page_alloc(0)));
f0101542:	83 ec 0c             	sub    $0xc,%esp
f0101545:	6a 00                	push   $0x0
f0101547:	e8 05 fb ff ff       	call   f0101051 <page_alloc>
f010154c:	89 c7                	mov    %eax,%edi
f010154e:	83 c4 10             	add    $0x10,%esp
f0101551:	85 c0                	test   %eax,%eax
f0101553:	0f 84 46 02 00 00    	je     f010179f <mem_init+0x3ec>
	assert((pp2 = page_alloc(0)));
f0101559:	83 ec 0c             	sub    $0xc,%esp
f010155c:	6a 00                	push   $0x0
f010155e:	e8 ee fa ff ff       	call   f0101051 <page_alloc>
f0101563:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101566:	83 c4 10             	add    $0x10,%esp
f0101569:	85 c0                	test   %eax,%eax
f010156b:	0f 84 50 02 00 00    	je     f01017c1 <mem_init+0x40e>
	assert(pp1 && pp1 != pp0);
f0101571:	39 fb                	cmp    %edi,%ebx
f0101573:	0f 84 6a 02 00 00    	je     f01017e3 <mem_init+0x430>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101579:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010157c:	39 c3                	cmp    %eax,%ebx
f010157e:	0f 84 81 02 00 00    	je     f0101805 <mem_init+0x452>
f0101584:	39 c7                	cmp    %eax,%edi
f0101586:	0f 84 79 02 00 00    	je     f0101805 <mem_init+0x452>
	return (pp - pages) << PGSHIFT;
f010158c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010158f:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0101595:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101597:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f010159d:	8b 10                	mov    (%eax),%edx
f010159f:	c1 e2 0c             	shl    $0xc,%edx
f01015a2:	89 d8                	mov    %ebx,%eax
f01015a4:	29 c8                	sub    %ecx,%eax
f01015a6:	c1 f8 03             	sar    $0x3,%eax
f01015a9:	c1 e0 0c             	shl    $0xc,%eax
f01015ac:	39 d0                	cmp    %edx,%eax
f01015ae:	0f 83 73 02 00 00    	jae    f0101827 <mem_init+0x474>
f01015b4:	89 f8                	mov    %edi,%eax
f01015b6:	29 c8                	sub    %ecx,%eax
f01015b8:	c1 f8 03             	sar    $0x3,%eax
f01015bb:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01015be:	39 c2                	cmp    %eax,%edx
f01015c0:	0f 86 83 02 00 00    	jbe    f0101849 <mem_init+0x496>
f01015c6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015c9:	29 c8                	sub    %ecx,%eax
f01015cb:	c1 f8 03             	sar    $0x3,%eax
f01015ce:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01015d1:	39 c2                	cmp    %eax,%edx
f01015d3:	0f 86 92 02 00 00    	jbe    f010186b <mem_init+0x4b8>
	fl = page_free_list;
f01015d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015dc:	8b 88 1c 23 00 00    	mov    0x231c(%eax),%ecx
f01015e2:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01015e5:	c7 80 1c 23 00 00 00 	movl   $0x0,0x231c(%eax)
f01015ec:	00 00 00 
	assert(!page_alloc(0));
f01015ef:	83 ec 0c             	sub    $0xc,%esp
f01015f2:	6a 00                	push   $0x0
f01015f4:	e8 58 fa ff ff       	call   f0101051 <page_alloc>
f01015f9:	83 c4 10             	add    $0x10,%esp
f01015fc:	85 c0                	test   %eax,%eax
f01015fe:	0f 85 89 02 00 00    	jne    f010188d <mem_init+0x4da>
	page_free(pp0);
f0101604:	83 ec 0c             	sub    $0xc,%esp
f0101607:	53                   	push   %ebx
f0101608:	e8 cc fa ff ff       	call   f01010d9 <page_free>
	page_free(pp1);
f010160d:	89 3c 24             	mov    %edi,(%esp)
f0101610:	e8 c4 fa ff ff       	call   f01010d9 <page_free>
	page_free(pp2);
f0101615:	83 c4 04             	add    $0x4,%esp
f0101618:	ff 75 d0             	pushl  -0x30(%ebp)
f010161b:	e8 b9 fa ff ff       	call   f01010d9 <page_free>
	assert((pp0 = page_alloc(0)));
f0101620:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101627:	e8 25 fa ff ff       	call   f0101051 <page_alloc>
f010162c:	89 c7                	mov    %eax,%edi
f010162e:	83 c4 10             	add    $0x10,%esp
f0101631:	85 c0                	test   %eax,%eax
f0101633:	0f 84 76 02 00 00    	je     f01018af <mem_init+0x4fc>
	assert((pp1 = page_alloc(0)));
f0101639:	83 ec 0c             	sub    $0xc,%esp
f010163c:	6a 00                	push   $0x0
f010163e:	e8 0e fa ff ff       	call   f0101051 <page_alloc>
f0101643:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101646:	83 c4 10             	add    $0x10,%esp
f0101649:	85 c0                	test   %eax,%eax
f010164b:	0f 84 80 02 00 00    	je     f01018d1 <mem_init+0x51e>
	assert((pp2 = page_alloc(0)));
f0101651:	83 ec 0c             	sub    $0xc,%esp
f0101654:	6a 00                	push   $0x0
f0101656:	e8 f6 f9 ff ff       	call   f0101051 <page_alloc>
f010165b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010165e:	83 c4 10             	add    $0x10,%esp
f0101661:	85 c0                	test   %eax,%eax
f0101663:	0f 84 8a 02 00 00    	je     f01018f3 <mem_init+0x540>
	assert(pp1 && pp1 != pp0);
f0101669:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f010166c:	0f 84 a3 02 00 00    	je     f0101915 <mem_init+0x562>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101672:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101675:	39 c7                	cmp    %eax,%edi
f0101677:	0f 84 ba 02 00 00    	je     f0101937 <mem_init+0x584>
f010167d:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101680:	0f 84 b1 02 00 00    	je     f0101937 <mem_init+0x584>
	assert(!page_alloc(0));
f0101686:	83 ec 0c             	sub    $0xc,%esp
f0101689:	6a 00                	push   $0x0
f010168b:	e8 c1 f9 ff ff       	call   f0101051 <page_alloc>
f0101690:	83 c4 10             	add    $0x10,%esp
f0101693:	85 c0                	test   %eax,%eax
f0101695:	0f 85 be 02 00 00    	jne    f0101959 <mem_init+0x5a6>
f010169b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010169e:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f01016a4:	89 f9                	mov    %edi,%ecx
f01016a6:	2b 08                	sub    (%eax),%ecx
f01016a8:	89 c8                	mov    %ecx,%eax
f01016aa:	c1 f8 03             	sar    $0x3,%eax
f01016ad:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01016b0:	89 c1                	mov    %eax,%ecx
f01016b2:	c1 e9 0c             	shr    $0xc,%ecx
f01016b5:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f01016bb:	3b 0a                	cmp    (%edx),%ecx
f01016bd:	0f 83 b8 02 00 00    	jae    f010197b <mem_init+0x5c8>
	memset(page2kva(pp0), 1, PGSIZE);
f01016c3:	83 ec 04             	sub    $0x4,%esp
f01016c6:	68 00 10 00 00       	push   $0x1000
f01016cb:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01016cd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016d2:	50                   	push   %eax
f01016d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016d6:	e8 85 30 00 00       	call   f0104760 <memset>
	page_free(pp0);
f01016db:	89 3c 24             	mov    %edi,(%esp)
f01016de:	e8 f6 f9 ff ff       	call   f01010d9 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016e3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016ea:	e8 62 f9 ff ff       	call   f0101051 <page_alloc>
f01016ef:	83 c4 10             	add    $0x10,%esp
f01016f2:	85 c0                	test   %eax,%eax
f01016f4:	0f 84 97 02 00 00    	je     f0101991 <mem_init+0x5de>
	assert(pp && pp0 == pp);
f01016fa:	39 c7                	cmp    %eax,%edi
f01016fc:	0f 85 b1 02 00 00    	jne    f01019b3 <mem_init+0x600>
	return (pp - pages) << PGSHIFT;
f0101702:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101705:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f010170b:	89 fa                	mov    %edi,%edx
f010170d:	2b 10                	sub    (%eax),%edx
f010170f:	c1 fa 03             	sar    $0x3,%edx
f0101712:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101715:	89 d1                	mov    %edx,%ecx
f0101717:	c1 e9 0c             	shr    $0xc,%ecx
f010171a:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f0101720:	3b 08                	cmp    (%eax),%ecx
f0101722:	0f 83 ad 02 00 00    	jae    f01019d5 <mem_init+0x622>
	return (void *)(pa + KERNBASE);
f0101728:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f010172e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101734:	80 38 00             	cmpb   $0x0,(%eax)
f0101737:	0f 85 ae 02 00 00    	jne    f01019eb <mem_init+0x638>
f010173d:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101740:	39 d0                	cmp    %edx,%eax
f0101742:	75 f0                	jne    f0101734 <mem_init+0x381>
	page_free_list = fl;
f0101744:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101747:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010174a:	89 8b 1c 23 00 00    	mov    %ecx,0x231c(%ebx)
	page_free(pp0);
f0101750:	83 ec 0c             	sub    $0xc,%esp
f0101753:	57                   	push   %edi
f0101754:	e8 80 f9 ff ff       	call   f01010d9 <page_free>
	page_free(pp1);
f0101759:	83 c4 04             	add    $0x4,%esp
f010175c:	ff 75 d0             	pushl  -0x30(%ebp)
f010175f:	e8 75 f9 ff ff       	call   f01010d9 <page_free>
	page_free(pp2);
f0101764:	83 c4 04             	add    $0x4,%esp
f0101767:	ff 75 cc             	pushl  -0x34(%ebp)
f010176a:	e8 6a f9 ff ff       	call   f01010d9 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010176f:	8b 83 1c 23 00 00    	mov    0x231c(%ebx),%eax
f0101775:	83 c4 10             	add    $0x10,%esp
f0101778:	e9 95 02 00 00       	jmp    f0101a12 <mem_init+0x65f>
	assert((pp0 = page_alloc(0)));
f010177d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101780:	8d 83 96 a9 f7 ff    	lea    -0x8566a(%ebx),%eax
f0101786:	50                   	push   %eax
f0101787:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010178d:	50                   	push   %eax
f010178e:	68 bb 02 00 00       	push   $0x2bb
f0101793:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101799:	50                   	push   %eax
f010179a:	e8 12 e9 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f010179f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017a2:	8d 83 ac a9 f7 ff    	lea    -0x85654(%ebx),%eax
f01017a8:	50                   	push   %eax
f01017a9:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01017af:	50                   	push   %eax
f01017b0:	68 bc 02 00 00       	push   $0x2bc
f01017b5:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01017bb:	50                   	push   %eax
f01017bc:	e8 f0 e8 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01017c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017c4:	8d 83 c2 a9 f7 ff    	lea    -0x8563e(%ebx),%eax
f01017ca:	50                   	push   %eax
f01017cb:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01017d1:	50                   	push   %eax
f01017d2:	68 bd 02 00 00       	push   $0x2bd
f01017d7:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01017dd:	50                   	push   %eax
f01017de:	e8 ce e8 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01017e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017e6:	8d 83 d8 a9 f7 ff    	lea    -0x85628(%ebx),%eax
f01017ec:	50                   	push   %eax
f01017ed:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01017f3:	50                   	push   %eax
f01017f4:	68 c0 02 00 00       	push   $0x2c0
f01017f9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01017ff:	50                   	push   %eax
f0101800:	e8 ac e8 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101805:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101808:	8d 83 a8 a2 f7 ff    	lea    -0x85d58(%ebx),%eax
f010180e:	50                   	push   %eax
f010180f:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0101815:	50                   	push   %eax
f0101816:	68 c1 02 00 00       	push   $0x2c1
f010181b:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101821:	50                   	push   %eax
f0101822:	e8 8a e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101827:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010182a:	8d 83 ea a9 f7 ff    	lea    -0x85616(%ebx),%eax
f0101830:	50                   	push   %eax
f0101831:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0101837:	50                   	push   %eax
f0101838:	68 c2 02 00 00       	push   $0x2c2
f010183d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101843:	50                   	push   %eax
f0101844:	e8 68 e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101849:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010184c:	8d 83 07 aa f7 ff    	lea    -0x855f9(%ebx),%eax
f0101852:	50                   	push   %eax
f0101853:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0101859:	50                   	push   %eax
f010185a:	68 c3 02 00 00       	push   $0x2c3
f010185f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101865:	50                   	push   %eax
f0101866:	e8 46 e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010186b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010186e:	8d 83 24 aa f7 ff    	lea    -0x855dc(%ebx),%eax
f0101874:	50                   	push   %eax
f0101875:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010187b:	50                   	push   %eax
f010187c:	68 c4 02 00 00       	push   $0x2c4
f0101881:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101887:	50                   	push   %eax
f0101888:	e8 24 e8 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010188d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101890:	8d 83 41 aa f7 ff    	lea    -0x855bf(%ebx),%eax
f0101896:	50                   	push   %eax
f0101897:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010189d:	50                   	push   %eax
f010189e:	68 cb 02 00 00       	push   $0x2cb
f01018a3:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01018a9:	50                   	push   %eax
f01018aa:	e8 02 e8 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f01018af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018b2:	8d 83 96 a9 f7 ff    	lea    -0x8566a(%ebx),%eax
f01018b8:	50                   	push   %eax
f01018b9:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01018bf:	50                   	push   %eax
f01018c0:	68 d2 02 00 00       	push   $0x2d2
f01018c5:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01018cb:	50                   	push   %eax
f01018cc:	e8 e0 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01018d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018d4:	8d 83 ac a9 f7 ff    	lea    -0x85654(%ebx),%eax
f01018da:	50                   	push   %eax
f01018db:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01018e1:	50                   	push   %eax
f01018e2:	68 d3 02 00 00       	push   $0x2d3
f01018e7:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01018ed:	50                   	push   %eax
f01018ee:	e8 be e7 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01018f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018f6:	8d 83 c2 a9 f7 ff    	lea    -0x8563e(%ebx),%eax
f01018fc:	50                   	push   %eax
f01018fd:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0101903:	50                   	push   %eax
f0101904:	68 d4 02 00 00       	push   $0x2d4
f0101909:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010190f:	50                   	push   %eax
f0101910:	e8 9c e7 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0101915:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101918:	8d 83 d8 a9 f7 ff    	lea    -0x85628(%ebx),%eax
f010191e:	50                   	push   %eax
f010191f:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0101925:	50                   	push   %eax
f0101926:	68 d6 02 00 00       	push   $0x2d6
f010192b:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101931:	50                   	push   %eax
f0101932:	e8 7a e7 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101937:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010193a:	8d 83 a8 a2 f7 ff    	lea    -0x85d58(%ebx),%eax
f0101940:	50                   	push   %eax
f0101941:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0101947:	50                   	push   %eax
f0101948:	68 d7 02 00 00       	push   $0x2d7
f010194d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101953:	50                   	push   %eax
f0101954:	e8 58 e7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101959:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010195c:	8d 83 41 aa f7 ff    	lea    -0x855bf(%ebx),%eax
f0101962:	50                   	push   %eax
f0101963:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0101969:	50                   	push   %eax
f010196a:	68 d8 02 00 00       	push   $0x2d8
f010196f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101975:	50                   	push   %eax
f0101976:	e8 36 e7 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010197b:	50                   	push   %eax
f010197c:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f0101982:	50                   	push   %eax
f0101983:	6a 5d                	push   $0x5d
f0101985:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f010198b:	50                   	push   %eax
f010198c:	e8 20 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101991:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101994:	8d 83 50 aa f7 ff    	lea    -0x855b0(%ebx),%eax
f010199a:	50                   	push   %eax
f010199b:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01019a1:	50                   	push   %eax
f01019a2:	68 dd 02 00 00       	push   $0x2dd
f01019a7:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01019ad:	50                   	push   %eax
f01019ae:	e8 fe e6 ff ff       	call   f01000b1 <_panic>
	assert(pp && pp0 == pp);
f01019b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019b6:	8d 83 6e aa f7 ff    	lea    -0x85592(%ebx),%eax
f01019bc:	50                   	push   %eax
f01019bd:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01019c3:	50                   	push   %eax
f01019c4:	68 de 02 00 00       	push   $0x2de
f01019c9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01019cf:	50                   	push   %eax
f01019d0:	e8 dc e6 ff ff       	call   f01000b1 <_panic>
f01019d5:	52                   	push   %edx
f01019d6:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f01019dc:	50                   	push   %eax
f01019dd:	6a 5d                	push   $0x5d
f01019df:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f01019e5:	50                   	push   %eax
f01019e6:	e8 c6 e6 ff ff       	call   f01000b1 <_panic>
		assert(c[i] == 0);
f01019eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019ee:	8d 83 7e aa f7 ff    	lea    -0x85582(%ebx),%eax
f01019f4:	50                   	push   %eax
f01019f5:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01019fb:	50                   	push   %eax
f01019fc:	68 e1 02 00 00       	push   $0x2e1
f0101a01:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0101a07:	50                   	push   %eax
f0101a08:	e8 a4 e6 ff ff       	call   f01000b1 <_panic>
		--nfree;
f0101a0d:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a10:	8b 00                	mov    (%eax),%eax
f0101a12:	85 c0                	test   %eax,%eax
f0101a14:	75 f7                	jne    f0101a0d <mem_init+0x65a>
	assert(nfree == 0);
f0101a16:	85 f6                	test   %esi,%esi
f0101a18:	0f 85 5b 08 00 00    	jne    f0102279 <mem_init+0xec6>
	cprintf("check_page_alloc() succeeded!\n");
f0101a1e:	83 ec 0c             	sub    $0xc,%esp
f0101a21:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a24:	8d 83 c8 a2 f7 ff    	lea    -0x85d38(%ebx),%eax
f0101a2a:	50                   	push   %eax
f0101a2b:	e8 80 1c 00 00       	call   f01036b0 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a30:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a37:	e8 15 f6 ff ff       	call   f0101051 <page_alloc>
f0101a3c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a3f:	83 c4 10             	add    $0x10,%esp
f0101a42:	85 c0                	test   %eax,%eax
f0101a44:	0f 84 51 08 00 00    	je     f010229b <mem_init+0xee8>
	assert((pp1 = page_alloc(0)));
f0101a4a:	83 ec 0c             	sub    $0xc,%esp
f0101a4d:	6a 00                	push   $0x0
f0101a4f:	e8 fd f5 ff ff       	call   f0101051 <page_alloc>
f0101a54:	89 c7                	mov    %eax,%edi
f0101a56:	83 c4 10             	add    $0x10,%esp
f0101a59:	85 c0                	test   %eax,%eax
f0101a5b:	0f 84 5c 08 00 00    	je     f01022bd <mem_init+0xf0a>
	assert((pp2 = page_alloc(0)));
f0101a61:	83 ec 0c             	sub    $0xc,%esp
f0101a64:	6a 00                	push   $0x0
f0101a66:	e8 e6 f5 ff ff       	call   f0101051 <page_alloc>
f0101a6b:	89 c6                	mov    %eax,%esi
f0101a6d:	83 c4 10             	add    $0x10,%esp
f0101a70:	85 c0                	test   %eax,%eax
f0101a72:	0f 84 67 08 00 00    	je     f01022df <mem_init+0xf2c>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a78:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101a7b:	0f 84 80 08 00 00    	je     f0102301 <mem_init+0xf4e>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a81:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101a84:	0f 84 99 08 00 00    	je     f0102323 <mem_init+0xf70>
f0101a8a:	39 c7                	cmp    %eax,%edi
f0101a8c:	0f 84 91 08 00 00    	je     f0102323 <mem_init+0xf70>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a92:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a95:	8b 88 1c 23 00 00    	mov    0x231c(%eax),%ecx
f0101a9b:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101a9e:	c7 80 1c 23 00 00 00 	movl   $0x0,0x231c(%eax)
f0101aa5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101aa8:	83 ec 0c             	sub    $0xc,%esp
f0101aab:	6a 00                	push   $0x0
f0101aad:	e8 9f f5 ff ff       	call   f0101051 <page_alloc>
f0101ab2:	83 c4 10             	add    $0x10,%esp
f0101ab5:	85 c0                	test   %eax,%eax
f0101ab7:	0f 85 88 08 00 00    	jne    f0102345 <mem_init+0xf92>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101abd:	83 ec 04             	sub    $0x4,%esp
f0101ac0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101ac3:	50                   	push   %eax
f0101ac4:	6a 00                	push   $0x0
f0101ac6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac9:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101acf:	ff 30                	pushl  (%eax)
f0101ad1:	e8 b2 f7 ff ff       	call   f0101288 <page_lookup>
f0101ad6:	83 c4 10             	add    $0x10,%esp
f0101ad9:	85 c0                	test   %eax,%eax
f0101adb:	0f 85 86 08 00 00    	jne    f0102367 <mem_init+0xfb4>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101ae1:	6a 02                	push   $0x2
f0101ae3:	6a 00                	push   $0x0
f0101ae5:	57                   	push   %edi
f0101ae6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ae9:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101aef:	ff 30                	pushl  (%eax)
f0101af1:	e8 3f f8 ff ff       	call   f0101335 <page_insert>
f0101af6:	83 c4 10             	add    $0x10,%esp
f0101af9:	85 c0                	test   %eax,%eax
f0101afb:	0f 89 88 08 00 00    	jns    f0102389 <mem_init+0xfd6>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b01:	83 ec 0c             	sub    $0xc,%esp
f0101b04:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b07:	e8 cd f5 ff ff       	call   f01010d9 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b0c:	6a 02                	push   $0x2
f0101b0e:	6a 00                	push   $0x0
f0101b10:	57                   	push   %edi
f0101b11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b14:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101b1a:	ff 30                	pushl  (%eax)
f0101b1c:	e8 14 f8 ff ff       	call   f0101335 <page_insert>
f0101b21:	83 c4 20             	add    $0x20,%esp
f0101b24:	85 c0                	test   %eax,%eax
f0101b26:	0f 85 7f 08 00 00    	jne    f01023ab <mem_init+0xff8>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b2c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b2f:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101b35:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101b37:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0101b3d:	8b 08                	mov    (%eax),%ecx
f0101b3f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101b42:	8b 13                	mov    (%ebx),%edx
f0101b44:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b4a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b4d:	29 c8                	sub    %ecx,%eax
f0101b4f:	c1 f8 03             	sar    $0x3,%eax
f0101b52:	c1 e0 0c             	shl    $0xc,%eax
f0101b55:	39 c2                	cmp    %eax,%edx
f0101b57:	0f 85 70 08 00 00    	jne    f01023cd <mem_init+0x101a>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b5d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b62:	89 d8                	mov    %ebx,%eax
f0101b64:	e8 f9 ef ff ff       	call   f0100b62 <check_va2pa>
f0101b69:	89 fa                	mov    %edi,%edx
f0101b6b:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b6e:	c1 fa 03             	sar    $0x3,%edx
f0101b71:	c1 e2 0c             	shl    $0xc,%edx
f0101b74:	39 d0                	cmp    %edx,%eax
f0101b76:	0f 85 73 08 00 00    	jne    f01023ef <mem_init+0x103c>
	assert(pp1->pp_ref == 1);
f0101b7c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b81:	0f 85 8a 08 00 00    	jne    f0102411 <mem_init+0x105e>
	assert(pp0->pp_ref == 1);
f0101b87:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b8a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b8f:	0f 85 9e 08 00 00    	jne    f0102433 <mem_init+0x1080>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b95:	6a 02                	push   $0x2
f0101b97:	68 00 10 00 00       	push   $0x1000
f0101b9c:	56                   	push   %esi
f0101b9d:	53                   	push   %ebx
f0101b9e:	e8 92 f7 ff ff       	call   f0101335 <page_insert>
f0101ba3:	83 c4 10             	add    $0x10,%esp
f0101ba6:	85 c0                	test   %eax,%eax
f0101ba8:	0f 85 a7 08 00 00    	jne    f0102455 <mem_init+0x10a2>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bae:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bb3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101bb6:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101bbc:	8b 00                	mov    (%eax),%eax
f0101bbe:	e8 9f ef ff ff       	call   f0100b62 <check_va2pa>
f0101bc3:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0101bc9:	89 f1                	mov    %esi,%ecx
f0101bcb:	2b 0a                	sub    (%edx),%ecx
f0101bcd:	89 ca                	mov    %ecx,%edx
f0101bcf:	c1 fa 03             	sar    $0x3,%edx
f0101bd2:	c1 e2 0c             	shl    $0xc,%edx
f0101bd5:	39 d0                	cmp    %edx,%eax
f0101bd7:	0f 85 9a 08 00 00    	jne    f0102477 <mem_init+0x10c4>
	assert(pp2->pp_ref == 1);
f0101bdd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101be2:	0f 85 b1 08 00 00    	jne    f0102499 <mem_init+0x10e6>

	// should be no free memory
	assert(!page_alloc(0));
f0101be8:	83 ec 0c             	sub    $0xc,%esp
f0101beb:	6a 00                	push   $0x0
f0101bed:	e8 5f f4 ff ff       	call   f0101051 <page_alloc>
f0101bf2:	83 c4 10             	add    $0x10,%esp
f0101bf5:	85 c0                	test   %eax,%eax
f0101bf7:	0f 85 be 08 00 00    	jne    f01024bb <mem_init+0x1108>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bfd:	6a 02                	push   $0x2
f0101bff:	68 00 10 00 00       	push   $0x1000
f0101c04:	56                   	push   %esi
f0101c05:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c08:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101c0e:	ff 30                	pushl  (%eax)
f0101c10:	e8 20 f7 ff ff       	call   f0101335 <page_insert>
f0101c15:	83 c4 10             	add    $0x10,%esp
f0101c18:	85 c0                	test   %eax,%eax
f0101c1a:	0f 85 bd 08 00 00    	jne    f01024dd <mem_init+0x112a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c20:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c25:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c28:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101c2e:	8b 00                	mov    (%eax),%eax
f0101c30:	e8 2d ef ff ff       	call   f0100b62 <check_va2pa>
f0101c35:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0101c3b:	89 f1                	mov    %esi,%ecx
f0101c3d:	2b 0a                	sub    (%edx),%ecx
f0101c3f:	89 ca                	mov    %ecx,%edx
f0101c41:	c1 fa 03             	sar    $0x3,%edx
f0101c44:	c1 e2 0c             	shl    $0xc,%edx
f0101c47:	39 d0                	cmp    %edx,%eax
f0101c49:	0f 85 b0 08 00 00    	jne    f01024ff <mem_init+0x114c>
	assert(pp2->pp_ref == 1);
f0101c4f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c54:	0f 85 c7 08 00 00    	jne    f0102521 <mem_init+0x116e>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c5a:	83 ec 0c             	sub    $0xc,%esp
f0101c5d:	6a 00                	push   $0x0
f0101c5f:	e8 ed f3 ff ff       	call   f0101051 <page_alloc>
f0101c64:	83 c4 10             	add    $0x10,%esp
f0101c67:	85 c0                	test   %eax,%eax
f0101c69:	0f 85 d4 08 00 00    	jne    f0102543 <mem_init+0x1190>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c6f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c72:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101c78:	8b 10                	mov    (%eax),%edx
f0101c7a:	8b 02                	mov    (%edx),%eax
f0101c7c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101c81:	89 c3                	mov    %eax,%ebx
f0101c83:	c1 eb 0c             	shr    $0xc,%ebx
f0101c86:	c7 c1 08 e0 18 f0    	mov    $0xf018e008,%ecx
f0101c8c:	3b 19                	cmp    (%ecx),%ebx
f0101c8e:	0f 83 d1 08 00 00    	jae    f0102565 <mem_init+0x11b2>
	return (void *)(pa + KERNBASE);
f0101c94:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c9c:	83 ec 04             	sub    $0x4,%esp
f0101c9f:	6a 00                	push   $0x0
f0101ca1:	68 00 10 00 00       	push   $0x1000
f0101ca6:	52                   	push   %edx
f0101ca7:	e8 a5 f4 ff ff       	call   f0101151 <pgdir_walk>
f0101cac:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101caf:	8d 51 04             	lea    0x4(%ecx),%edx
f0101cb2:	83 c4 10             	add    $0x10,%esp
f0101cb5:	39 d0                	cmp    %edx,%eax
f0101cb7:	0f 85 c4 08 00 00    	jne    f0102581 <mem_init+0x11ce>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cbd:	6a 06                	push   $0x6
f0101cbf:	68 00 10 00 00       	push   $0x1000
f0101cc4:	56                   	push   %esi
f0101cc5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cc8:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101cce:	ff 30                	pushl  (%eax)
f0101cd0:	e8 60 f6 ff ff       	call   f0101335 <page_insert>
f0101cd5:	83 c4 10             	add    $0x10,%esp
f0101cd8:	85 c0                	test   %eax,%eax
f0101cda:	0f 85 c3 08 00 00    	jne    f01025a3 <mem_init+0x11f0>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ce0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ce3:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101ce9:	8b 18                	mov    (%eax),%ebx
f0101ceb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cf0:	89 d8                	mov    %ebx,%eax
f0101cf2:	e8 6b ee ff ff       	call   f0100b62 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101cf7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101cfa:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0101d00:	89 f1                	mov    %esi,%ecx
f0101d02:	2b 0a                	sub    (%edx),%ecx
f0101d04:	89 ca                	mov    %ecx,%edx
f0101d06:	c1 fa 03             	sar    $0x3,%edx
f0101d09:	c1 e2 0c             	shl    $0xc,%edx
f0101d0c:	39 d0                	cmp    %edx,%eax
f0101d0e:	0f 85 b1 08 00 00    	jne    f01025c5 <mem_init+0x1212>
	assert(pp2->pp_ref == 1);
f0101d14:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d19:	0f 85 c8 08 00 00    	jne    f01025e7 <mem_init+0x1234>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d1f:	83 ec 04             	sub    $0x4,%esp
f0101d22:	6a 00                	push   $0x0
f0101d24:	68 00 10 00 00       	push   $0x1000
f0101d29:	53                   	push   %ebx
f0101d2a:	e8 22 f4 ff ff       	call   f0101151 <pgdir_walk>
f0101d2f:	83 c4 10             	add    $0x10,%esp
f0101d32:	f6 00 04             	testb  $0x4,(%eax)
f0101d35:	0f 84 ce 08 00 00    	je     f0102609 <mem_init+0x1256>
	assert(kern_pgdir[0] & PTE_U);
f0101d3b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d3e:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101d44:	8b 00                	mov    (%eax),%eax
f0101d46:	f6 00 04             	testb  $0x4,(%eax)
f0101d49:	0f 84 dc 08 00 00    	je     f010262b <mem_init+0x1278>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d4f:	6a 02                	push   $0x2
f0101d51:	68 00 10 00 00       	push   $0x1000
f0101d56:	56                   	push   %esi
f0101d57:	50                   	push   %eax
f0101d58:	e8 d8 f5 ff ff       	call   f0101335 <page_insert>
f0101d5d:	83 c4 10             	add    $0x10,%esp
f0101d60:	85 c0                	test   %eax,%eax
f0101d62:	0f 85 e5 08 00 00    	jne    f010264d <mem_init+0x129a>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d68:	83 ec 04             	sub    $0x4,%esp
f0101d6b:	6a 00                	push   $0x0
f0101d6d:	68 00 10 00 00       	push   $0x1000
f0101d72:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d75:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101d7b:	ff 30                	pushl  (%eax)
f0101d7d:	e8 cf f3 ff ff       	call   f0101151 <pgdir_walk>
f0101d82:	83 c4 10             	add    $0x10,%esp
f0101d85:	f6 00 02             	testb  $0x2,(%eax)
f0101d88:	0f 84 e1 08 00 00    	je     f010266f <mem_init+0x12bc>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d8e:	83 ec 04             	sub    $0x4,%esp
f0101d91:	6a 00                	push   $0x0
f0101d93:	68 00 10 00 00       	push   $0x1000
f0101d98:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d9b:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101da1:	ff 30                	pushl  (%eax)
f0101da3:	e8 a9 f3 ff ff       	call   f0101151 <pgdir_walk>
f0101da8:	83 c4 10             	add    $0x10,%esp
f0101dab:	f6 00 04             	testb  $0x4,(%eax)
f0101dae:	0f 85 dd 08 00 00    	jne    f0102691 <mem_init+0x12de>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101db4:	6a 02                	push   $0x2
f0101db6:	68 00 00 40 00       	push   $0x400000
f0101dbb:	ff 75 d0             	pushl  -0x30(%ebp)
f0101dbe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc1:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101dc7:	ff 30                	pushl  (%eax)
f0101dc9:	e8 67 f5 ff ff       	call   f0101335 <page_insert>
f0101dce:	83 c4 10             	add    $0x10,%esp
f0101dd1:	85 c0                	test   %eax,%eax
f0101dd3:	0f 89 da 08 00 00    	jns    f01026b3 <mem_init+0x1300>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101dd9:	6a 02                	push   $0x2
f0101ddb:	68 00 10 00 00       	push   $0x1000
f0101de0:	57                   	push   %edi
f0101de1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de4:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101dea:	ff 30                	pushl  (%eax)
f0101dec:	e8 44 f5 ff ff       	call   f0101335 <page_insert>
f0101df1:	83 c4 10             	add    $0x10,%esp
f0101df4:	85 c0                	test   %eax,%eax
f0101df6:	0f 85 d9 08 00 00    	jne    f01026d5 <mem_init+0x1322>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dfc:	83 ec 04             	sub    $0x4,%esp
f0101dff:	6a 00                	push   $0x0
f0101e01:	68 00 10 00 00       	push   $0x1000
f0101e06:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e09:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101e0f:	ff 30                	pushl  (%eax)
f0101e11:	e8 3b f3 ff ff       	call   f0101151 <pgdir_walk>
f0101e16:	83 c4 10             	add    $0x10,%esp
f0101e19:	f6 00 04             	testb  $0x4,(%eax)
f0101e1c:	0f 85 d5 08 00 00    	jne    f01026f7 <mem_init+0x1344>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e25:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101e2b:	8b 18                	mov    (%eax),%ebx
f0101e2d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e32:	89 d8                	mov    %ebx,%eax
f0101e34:	e8 29 ed ff ff       	call   f0100b62 <check_va2pa>
f0101e39:	89 c2                	mov    %eax,%edx
f0101e3b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e3e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e41:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0101e47:	89 f9                	mov    %edi,%ecx
f0101e49:	2b 08                	sub    (%eax),%ecx
f0101e4b:	89 c8                	mov    %ecx,%eax
f0101e4d:	c1 f8 03             	sar    $0x3,%eax
f0101e50:	c1 e0 0c             	shl    $0xc,%eax
f0101e53:	39 c2                	cmp    %eax,%edx
f0101e55:	0f 85 be 08 00 00    	jne    f0102719 <mem_init+0x1366>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e5b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e60:	89 d8                	mov    %ebx,%eax
f0101e62:	e8 fb ec ff ff       	call   f0100b62 <check_va2pa>
f0101e67:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e6a:	0f 85 cb 08 00 00    	jne    f010273b <mem_init+0x1388>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e70:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101e75:	0f 85 e2 08 00 00    	jne    f010275d <mem_init+0x13aa>
	assert(pp2->pp_ref == 0);
f0101e7b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e80:	0f 85 f9 08 00 00    	jne    f010277f <mem_init+0x13cc>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e86:	83 ec 0c             	sub    $0xc,%esp
f0101e89:	6a 00                	push   $0x0
f0101e8b:	e8 c1 f1 ff ff       	call   f0101051 <page_alloc>
f0101e90:	83 c4 10             	add    $0x10,%esp
f0101e93:	39 c6                	cmp    %eax,%esi
f0101e95:	0f 85 06 09 00 00    	jne    f01027a1 <mem_init+0x13ee>
f0101e9b:	85 c0                	test   %eax,%eax
f0101e9d:	0f 84 fe 08 00 00    	je     f01027a1 <mem_init+0x13ee>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ea3:	83 ec 08             	sub    $0x8,%esp
f0101ea6:	6a 00                	push   $0x0
f0101ea8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eab:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f0101eb1:	ff 33                	pushl  (%ebx)
f0101eb3:	e8 40 f4 ff ff       	call   f01012f8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101eb8:	8b 1b                	mov    (%ebx),%ebx
f0101eba:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ebf:	89 d8                	mov    %ebx,%eax
f0101ec1:	e8 9c ec ff ff       	call   f0100b62 <check_va2pa>
f0101ec6:	83 c4 10             	add    $0x10,%esp
f0101ec9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ecc:	0f 85 f1 08 00 00    	jne    f01027c3 <mem_init+0x1410>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ed2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ed7:	89 d8                	mov    %ebx,%eax
f0101ed9:	e8 84 ec ff ff       	call   f0100b62 <check_va2pa>
f0101ede:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ee1:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0101ee7:	89 f9                	mov    %edi,%ecx
f0101ee9:	2b 0a                	sub    (%edx),%ecx
f0101eeb:	89 ca                	mov    %ecx,%edx
f0101eed:	c1 fa 03             	sar    $0x3,%edx
f0101ef0:	c1 e2 0c             	shl    $0xc,%edx
f0101ef3:	39 d0                	cmp    %edx,%eax
f0101ef5:	0f 85 ea 08 00 00    	jne    f01027e5 <mem_init+0x1432>
	assert(pp1->pp_ref == 1);
f0101efb:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101f00:	0f 85 01 09 00 00    	jne    f0102807 <mem_init+0x1454>
	assert(pp2->pp_ref == 0);
f0101f06:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f0b:	0f 85 18 09 00 00    	jne    f0102829 <mem_init+0x1476>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f11:	6a 00                	push   $0x0
f0101f13:	68 00 10 00 00       	push   $0x1000
f0101f18:	57                   	push   %edi
f0101f19:	53                   	push   %ebx
f0101f1a:	e8 16 f4 ff ff       	call   f0101335 <page_insert>
f0101f1f:	83 c4 10             	add    $0x10,%esp
f0101f22:	85 c0                	test   %eax,%eax
f0101f24:	0f 85 21 09 00 00    	jne    f010284b <mem_init+0x1498>
	assert(pp1->pp_ref);
f0101f2a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f2f:	0f 84 38 09 00 00    	je     f010286d <mem_init+0x14ba>
	assert(pp1->pp_link == NULL);
f0101f35:	83 3f 00             	cmpl   $0x0,(%edi)
f0101f38:	0f 85 51 09 00 00    	jne    f010288f <mem_init+0x14dc>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f3e:	83 ec 08             	sub    $0x8,%esp
f0101f41:	68 00 10 00 00       	push   $0x1000
f0101f46:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f49:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f0101f4f:	ff 33                	pushl  (%ebx)
f0101f51:	e8 a2 f3 ff ff       	call   f01012f8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f56:	8b 1b                	mov    (%ebx),%ebx
f0101f58:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f5d:	89 d8                	mov    %ebx,%eax
f0101f5f:	e8 fe eb ff ff       	call   f0100b62 <check_va2pa>
f0101f64:	83 c4 10             	add    $0x10,%esp
f0101f67:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f6a:	0f 85 41 09 00 00    	jne    f01028b1 <mem_init+0x14fe>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f75:	89 d8                	mov    %ebx,%eax
f0101f77:	e8 e6 eb ff ff       	call   f0100b62 <check_va2pa>
f0101f7c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f7f:	0f 85 4e 09 00 00    	jne    f01028d3 <mem_init+0x1520>
	assert(pp1->pp_ref == 0);
f0101f85:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f8a:	0f 85 65 09 00 00    	jne    f01028f5 <mem_init+0x1542>
	assert(pp2->pp_ref == 0);
f0101f90:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f95:	0f 85 7c 09 00 00    	jne    f0102917 <mem_init+0x1564>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f9b:	83 ec 0c             	sub    $0xc,%esp
f0101f9e:	6a 00                	push   $0x0
f0101fa0:	e8 ac f0 ff ff       	call   f0101051 <page_alloc>
f0101fa5:	83 c4 10             	add    $0x10,%esp
f0101fa8:	39 c7                	cmp    %eax,%edi
f0101faa:	0f 85 89 09 00 00    	jne    f0102939 <mem_init+0x1586>
f0101fb0:	85 c0                	test   %eax,%eax
f0101fb2:	0f 84 81 09 00 00    	je     f0102939 <mem_init+0x1586>

	// should be no free memory
	assert(!page_alloc(0));
f0101fb8:	83 ec 0c             	sub    $0xc,%esp
f0101fbb:	6a 00                	push   $0x0
f0101fbd:	e8 8f f0 ff ff       	call   f0101051 <page_alloc>
f0101fc2:	83 c4 10             	add    $0x10,%esp
f0101fc5:	85 c0                	test   %eax,%eax
f0101fc7:	0f 85 8e 09 00 00    	jne    f010295b <mem_init+0x15a8>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fcd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101fd0:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101fd6:	8b 08                	mov    (%eax),%ecx
f0101fd8:	8b 11                	mov    (%ecx),%edx
f0101fda:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fe0:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0101fe6:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101fe9:	2b 18                	sub    (%eax),%ebx
f0101feb:	89 d8                	mov    %ebx,%eax
f0101fed:	c1 f8 03             	sar    $0x3,%eax
f0101ff0:	c1 e0 0c             	shl    $0xc,%eax
f0101ff3:	39 c2                	cmp    %eax,%edx
f0101ff5:	0f 85 82 09 00 00    	jne    f010297d <mem_init+0x15ca>
	kern_pgdir[0] = 0;
f0101ffb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102001:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102004:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102009:	0f 85 90 09 00 00    	jne    f010299f <mem_init+0x15ec>
	pp0->pp_ref = 0;
f010200f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102012:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102018:	83 ec 0c             	sub    $0xc,%esp
f010201b:	50                   	push   %eax
f010201c:	e8 b8 f0 ff ff       	call   f01010d9 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102021:	83 c4 0c             	add    $0xc,%esp
f0102024:	6a 01                	push   $0x1
f0102026:	68 00 10 40 00       	push   $0x401000
f010202b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010202e:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f0102034:	ff 33                	pushl  (%ebx)
f0102036:	e8 16 f1 ff ff       	call   f0101151 <pgdir_walk>
f010203b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010203e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102041:	8b 1b                	mov    (%ebx),%ebx
f0102043:	8b 53 04             	mov    0x4(%ebx),%edx
f0102046:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f010204c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010204f:	c7 c1 08 e0 18 f0    	mov    $0xf018e008,%ecx
f0102055:	8b 09                	mov    (%ecx),%ecx
f0102057:	89 d0                	mov    %edx,%eax
f0102059:	c1 e8 0c             	shr    $0xc,%eax
f010205c:	83 c4 10             	add    $0x10,%esp
f010205f:	39 c8                	cmp    %ecx,%eax
f0102061:	0f 83 5a 09 00 00    	jae    f01029c1 <mem_init+0x160e>
	assert(ptep == ptep1 + PTX(va));
f0102067:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010206d:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0102070:	0f 85 67 09 00 00    	jne    f01029dd <mem_init+0x162a>
	kern_pgdir[PDX(va)] = 0;
f0102076:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f010207d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102080:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102086:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102089:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f010208f:	2b 18                	sub    (%eax),%ebx
f0102091:	89 d8                	mov    %ebx,%eax
f0102093:	c1 f8 03             	sar    $0x3,%eax
f0102096:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102099:	89 c2                	mov    %eax,%edx
f010209b:	c1 ea 0c             	shr    $0xc,%edx
f010209e:	39 d1                	cmp    %edx,%ecx
f01020a0:	0f 86 59 09 00 00    	jbe    f01029ff <mem_init+0x164c>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020a6:	83 ec 04             	sub    $0x4,%esp
f01020a9:	68 00 10 00 00       	push   $0x1000
f01020ae:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01020b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020b8:	50                   	push   %eax
f01020b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020bc:	e8 9f 26 00 00       	call   f0104760 <memset>
	page_free(pp0);
f01020c1:	83 c4 04             	add    $0x4,%esp
f01020c4:	ff 75 d0             	pushl  -0x30(%ebp)
f01020c7:	e8 0d f0 ff ff       	call   f01010d9 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020cc:	83 c4 0c             	add    $0xc,%esp
f01020cf:	6a 01                	push   $0x1
f01020d1:	6a 00                	push   $0x0
f01020d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020d6:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f01020dc:	ff 30                	pushl  (%eax)
f01020de:	e8 6e f0 ff ff       	call   f0101151 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01020e3:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f01020e9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01020ec:	2b 10                	sub    (%eax),%edx
f01020ee:	c1 fa 03             	sar    $0x3,%edx
f01020f1:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01020f4:	89 d1                	mov    %edx,%ecx
f01020f6:	c1 e9 0c             	shr    $0xc,%ecx
f01020f9:	83 c4 10             	add    $0x10,%esp
f01020fc:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f0102102:	3b 08                	cmp    (%eax),%ecx
f0102104:	0f 83 0e 09 00 00    	jae    f0102a18 <mem_init+0x1665>
	return (void *)(pa + KERNBASE);
f010210a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102110:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102113:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102119:	f6 00 01             	testb  $0x1,(%eax)
f010211c:	0f 85 0f 09 00 00    	jne    f0102a31 <mem_init+0x167e>
f0102122:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102125:	39 d0                	cmp    %edx,%eax
f0102127:	75 f0                	jne    f0102119 <mem_init+0xd66>
	kern_pgdir[0] = 0;
f0102129:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010212c:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102132:	8b 00                	mov    (%eax),%eax
f0102134:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010213a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010213d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102143:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102146:	89 93 1c 23 00 00    	mov    %edx,0x231c(%ebx)

	// free the pages we took
	page_free(pp0);
f010214c:	83 ec 0c             	sub    $0xc,%esp
f010214f:	50                   	push   %eax
f0102150:	e8 84 ef ff ff       	call   f01010d9 <page_free>
	page_free(pp1);
f0102155:	89 3c 24             	mov    %edi,(%esp)
f0102158:	e8 7c ef ff ff       	call   f01010d9 <page_free>
	page_free(pp2);
f010215d:	89 34 24             	mov    %esi,(%esp)
f0102160:	e8 74 ef ff ff       	call   f01010d9 <page_free>

	cprintf("check_page() succeeded!\n");
f0102165:	8d 83 5f ab f7 ff    	lea    -0x854a1(%ebx),%eax
f010216b:	89 04 24             	mov    %eax,(%esp)
f010216e:	e8 3d 15 00 00       	call   f01036b0 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f0102173:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102179:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010217b:	83 c4 10             	add    $0x10,%esp
f010217e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102183:	0f 86 ca 08 00 00    	jbe    f0102a53 <mem_init+0x16a0>
f0102189:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010218c:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102192:	8b 0a                	mov    (%edx),%ecx
f0102194:	c1 e1 03             	shl    $0x3,%ecx
f0102197:	83 ec 08             	sub    $0x8,%esp
f010219a:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f010219c:	05 00 00 00 10       	add    $0x10000000,%eax
f01021a1:	50                   	push   %eax
f01021a2:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021a7:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f01021ad:	8b 00                	mov    (%eax),%eax
f01021af:	e8 48 f0 ff ff       	call   f01011fc <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01021b4:	c7 c0 00 10 11 f0    	mov    $0xf0111000,%eax
f01021ba:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01021bd:	83 c4 10             	add    $0x10,%esp
f01021c0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021c5:	0f 86 a4 08 00 00    	jbe    f0102a6f <mem_init+0x16bc>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01021cb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01021ce:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f01021d4:	83 ec 08             	sub    $0x8,%esp
f01021d7:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01021d9:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01021dc:	05 00 00 00 10       	add    $0x10000000,%eax
f01021e1:	50                   	push   %eax
f01021e2:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021e7:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021ec:	8b 03                	mov    (%ebx),%eax
f01021ee:	e8 09 f0 ff ff       	call   f01011fc <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0x100000000 - KERNBASE, 0, PTE_W);
f01021f3:	83 c4 08             	add    $0x8,%esp
f01021f6:	6a 02                	push   $0x2
f01021f8:	6a 00                	push   $0x0
f01021fa:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021ff:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102204:	8b 03                	mov    (%ebx),%eax
f0102206:	e8 f1 ef ff ff       	call   f01011fc <boot_map_region>
	pgdir = kern_pgdir;
f010220b:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010220d:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f0102213:	8b 00                	mov    (%eax),%eax
f0102215:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102218:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010221f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102224:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102227:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f010222d:	8b 00                	mov    (%eax),%eax
f010222f:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102232:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102235:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi
f010223b:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f010223e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102243:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102246:	0f 86 84 08 00 00    	jbe    f0102ad0 <mem_init+0x171d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010224c:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102252:	89 f0                	mov    %esi,%eax
f0102254:	e8 09 e9 ff ff       	call   f0100b62 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102259:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102260:	0f 86 2a 08 00 00    	jbe    f0102a90 <mem_init+0x16dd>
f0102266:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102269:	39 d0                	cmp    %edx,%eax
f010226b:	0f 85 3d 08 00 00    	jne    f0102aae <mem_init+0x16fb>
	for (i = 0; i < n; i += PGSIZE)
f0102271:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102277:	eb ca                	jmp    f0102243 <mem_init+0xe90>
	assert(nfree == 0);
f0102279:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010227c:	8d 83 88 aa f7 ff    	lea    -0x85578(%ebx),%eax
f0102282:	50                   	push   %eax
f0102283:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102289:	50                   	push   %eax
f010228a:	68 ee 02 00 00       	push   $0x2ee
f010228f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102295:	50                   	push   %eax
f0102296:	e8 16 de ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f010229b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010229e:	8d 83 96 a9 f7 ff    	lea    -0x8566a(%ebx),%eax
f01022a4:	50                   	push   %eax
f01022a5:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01022ab:	50                   	push   %eax
f01022ac:	68 4c 03 00 00       	push   $0x34c
f01022b1:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01022b7:	50                   	push   %eax
f01022b8:	e8 f4 dd ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01022bd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022c0:	8d 83 ac a9 f7 ff    	lea    -0x85654(%ebx),%eax
f01022c6:	50                   	push   %eax
f01022c7:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01022cd:	50                   	push   %eax
f01022ce:	68 4d 03 00 00       	push   $0x34d
f01022d3:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01022d9:	50                   	push   %eax
f01022da:	e8 d2 dd ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01022df:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022e2:	8d 83 c2 a9 f7 ff    	lea    -0x8563e(%ebx),%eax
f01022e8:	50                   	push   %eax
f01022e9:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01022ef:	50                   	push   %eax
f01022f0:	68 4e 03 00 00       	push   $0x34e
f01022f5:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01022fb:	50                   	push   %eax
f01022fc:	e8 b0 dd ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0102301:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102304:	8d 83 d8 a9 f7 ff    	lea    -0x85628(%ebx),%eax
f010230a:	50                   	push   %eax
f010230b:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102311:	50                   	push   %eax
f0102312:	68 51 03 00 00       	push   $0x351
f0102317:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010231d:	50                   	push   %eax
f010231e:	e8 8e dd ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102323:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102326:	8d 83 a8 a2 f7 ff    	lea    -0x85d58(%ebx),%eax
f010232c:	50                   	push   %eax
f010232d:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102333:	50                   	push   %eax
f0102334:	68 52 03 00 00       	push   $0x352
f0102339:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010233f:	50                   	push   %eax
f0102340:	e8 6c dd ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102345:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102348:	8d 83 41 aa f7 ff    	lea    -0x855bf(%ebx),%eax
f010234e:	50                   	push   %eax
f010234f:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102355:	50                   	push   %eax
f0102356:	68 59 03 00 00       	push   $0x359
f010235b:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102361:	50                   	push   %eax
f0102362:	e8 4a dd ff ff       	call   f01000b1 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102367:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010236a:	8d 83 e8 a2 f7 ff    	lea    -0x85d18(%ebx),%eax
f0102370:	50                   	push   %eax
f0102371:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102377:	50                   	push   %eax
f0102378:	68 5c 03 00 00       	push   $0x35c
f010237d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102383:	50                   	push   %eax
f0102384:	e8 28 dd ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102389:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010238c:	8d 83 20 a3 f7 ff    	lea    -0x85ce0(%ebx),%eax
f0102392:	50                   	push   %eax
f0102393:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102399:	50                   	push   %eax
f010239a:	68 5f 03 00 00       	push   $0x35f
f010239f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01023a5:	50                   	push   %eax
f01023a6:	e8 06 dd ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01023ab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023ae:	8d 83 50 a3 f7 ff    	lea    -0x85cb0(%ebx),%eax
f01023b4:	50                   	push   %eax
f01023b5:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01023bb:	50                   	push   %eax
f01023bc:	68 63 03 00 00       	push   $0x363
f01023c1:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01023c7:	50                   	push   %eax
f01023c8:	e8 e4 dc ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023d0:	8d 83 80 a3 f7 ff    	lea    -0x85c80(%ebx),%eax
f01023d6:	50                   	push   %eax
f01023d7:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01023dd:	50                   	push   %eax
f01023de:	68 64 03 00 00       	push   $0x364
f01023e3:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01023e9:	50                   	push   %eax
f01023ea:	e8 c2 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01023ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023f2:	8d 83 a8 a3 f7 ff    	lea    -0x85c58(%ebx),%eax
f01023f8:	50                   	push   %eax
f01023f9:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01023ff:	50                   	push   %eax
f0102400:	68 65 03 00 00       	push   $0x365
f0102405:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010240b:	50                   	push   %eax
f010240c:	e8 a0 dc ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102411:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102414:	8d 83 93 aa f7 ff    	lea    -0x8556d(%ebx),%eax
f010241a:	50                   	push   %eax
f010241b:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102421:	50                   	push   %eax
f0102422:	68 66 03 00 00       	push   $0x366
f0102427:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010242d:	50                   	push   %eax
f010242e:	e8 7e dc ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0102433:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102436:	8d 83 a4 aa f7 ff    	lea    -0x8555c(%ebx),%eax
f010243c:	50                   	push   %eax
f010243d:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102443:	50                   	push   %eax
f0102444:	68 67 03 00 00       	push   $0x367
f0102449:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010244f:	50                   	push   %eax
f0102450:	e8 5c dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102455:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102458:	8d 83 d8 a3 f7 ff    	lea    -0x85c28(%ebx),%eax
f010245e:	50                   	push   %eax
f010245f:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102465:	50                   	push   %eax
f0102466:	68 6a 03 00 00       	push   $0x36a
f010246b:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102471:	50                   	push   %eax
f0102472:	e8 3a dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102477:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010247a:	8d 83 14 a4 f7 ff    	lea    -0x85bec(%ebx),%eax
f0102480:	50                   	push   %eax
f0102481:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102487:	50                   	push   %eax
f0102488:	68 6b 03 00 00       	push   $0x36b
f010248d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102493:	50                   	push   %eax
f0102494:	e8 18 dc ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102499:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010249c:	8d 83 b5 aa f7 ff    	lea    -0x8554b(%ebx),%eax
f01024a2:	50                   	push   %eax
f01024a3:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01024a9:	50                   	push   %eax
f01024aa:	68 6c 03 00 00       	push   $0x36c
f01024af:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01024b5:	50                   	push   %eax
f01024b6:	e8 f6 db ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01024bb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024be:	8d 83 41 aa f7 ff    	lea    -0x855bf(%ebx),%eax
f01024c4:	50                   	push   %eax
f01024c5:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01024cb:	50                   	push   %eax
f01024cc:	68 6f 03 00 00       	push   $0x36f
f01024d1:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01024d7:	50                   	push   %eax
f01024d8:	e8 d4 db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024e0:	8d 83 d8 a3 f7 ff    	lea    -0x85c28(%ebx),%eax
f01024e6:	50                   	push   %eax
f01024e7:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01024ed:	50                   	push   %eax
f01024ee:	68 72 03 00 00       	push   $0x372
f01024f3:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01024f9:	50                   	push   %eax
f01024fa:	e8 b2 db ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102502:	8d 83 14 a4 f7 ff    	lea    -0x85bec(%ebx),%eax
f0102508:	50                   	push   %eax
f0102509:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010250f:	50                   	push   %eax
f0102510:	68 73 03 00 00       	push   $0x373
f0102515:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010251b:	50                   	push   %eax
f010251c:	e8 90 db ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102521:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102524:	8d 83 b5 aa f7 ff    	lea    -0x8554b(%ebx),%eax
f010252a:	50                   	push   %eax
f010252b:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102531:	50                   	push   %eax
f0102532:	68 74 03 00 00       	push   $0x374
f0102537:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010253d:	50                   	push   %eax
f010253e:	e8 6e db ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102543:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102546:	8d 83 41 aa f7 ff    	lea    -0x855bf(%ebx),%eax
f010254c:	50                   	push   %eax
f010254d:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102553:	50                   	push   %eax
f0102554:	68 78 03 00 00       	push   $0x378
f0102559:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010255f:	50                   	push   %eax
f0102560:	e8 4c db ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102565:	50                   	push   %eax
f0102566:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102569:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f010256f:	50                   	push   %eax
f0102570:	68 7b 03 00 00       	push   $0x37b
f0102575:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010257b:	50                   	push   %eax
f010257c:	e8 30 db ff ff       	call   f01000b1 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102581:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102584:	8d 83 44 a4 f7 ff    	lea    -0x85bbc(%ebx),%eax
f010258a:	50                   	push   %eax
f010258b:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102591:	50                   	push   %eax
f0102592:	68 7c 03 00 00       	push   $0x37c
f0102597:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010259d:	50                   	push   %eax
f010259e:	e8 0e db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01025a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025a6:	8d 83 84 a4 f7 ff    	lea    -0x85b7c(%ebx),%eax
f01025ac:	50                   	push   %eax
f01025ad:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01025b3:	50                   	push   %eax
f01025b4:	68 7f 03 00 00       	push   $0x37f
f01025b9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01025bf:	50                   	push   %eax
f01025c0:	e8 ec da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01025c5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025c8:	8d 83 14 a4 f7 ff    	lea    -0x85bec(%ebx),%eax
f01025ce:	50                   	push   %eax
f01025cf:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01025d5:	50                   	push   %eax
f01025d6:	68 80 03 00 00       	push   $0x380
f01025db:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01025e1:	50                   	push   %eax
f01025e2:	e8 ca da ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01025e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025ea:	8d 83 b5 aa f7 ff    	lea    -0x8554b(%ebx),%eax
f01025f0:	50                   	push   %eax
f01025f1:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01025f7:	50                   	push   %eax
f01025f8:	68 81 03 00 00       	push   $0x381
f01025fd:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102603:	50                   	push   %eax
f0102604:	e8 a8 da ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102609:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010260c:	8d 83 c4 a4 f7 ff    	lea    -0x85b3c(%ebx),%eax
f0102612:	50                   	push   %eax
f0102613:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102619:	50                   	push   %eax
f010261a:	68 82 03 00 00       	push   $0x382
f010261f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102625:	50                   	push   %eax
f0102626:	e8 86 da ff ff       	call   f01000b1 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010262b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010262e:	8d 83 c6 aa f7 ff    	lea    -0x8553a(%ebx),%eax
f0102634:	50                   	push   %eax
f0102635:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010263b:	50                   	push   %eax
f010263c:	68 83 03 00 00       	push   $0x383
f0102641:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102647:	50                   	push   %eax
f0102648:	e8 64 da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010264d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102650:	8d 83 d8 a3 f7 ff    	lea    -0x85c28(%ebx),%eax
f0102656:	50                   	push   %eax
f0102657:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010265d:	50                   	push   %eax
f010265e:	68 86 03 00 00       	push   $0x386
f0102663:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102669:	50                   	push   %eax
f010266a:	e8 42 da ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010266f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102672:	8d 83 f8 a4 f7 ff    	lea    -0x85b08(%ebx),%eax
f0102678:	50                   	push   %eax
f0102679:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010267f:	50                   	push   %eax
f0102680:	68 87 03 00 00       	push   $0x387
f0102685:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010268b:	50                   	push   %eax
f010268c:	e8 20 da ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102691:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102694:	8d 83 2c a5 f7 ff    	lea    -0x85ad4(%ebx),%eax
f010269a:	50                   	push   %eax
f010269b:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01026a1:	50                   	push   %eax
f01026a2:	68 88 03 00 00       	push   $0x388
f01026a7:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01026ad:	50                   	push   %eax
f01026ae:	e8 fe d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01026b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026b6:	8d 83 64 a5 f7 ff    	lea    -0x85a9c(%ebx),%eax
f01026bc:	50                   	push   %eax
f01026bd:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01026c3:	50                   	push   %eax
f01026c4:	68 8b 03 00 00       	push   $0x38b
f01026c9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01026cf:	50                   	push   %eax
f01026d0:	e8 dc d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01026d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026d8:	8d 83 9c a5 f7 ff    	lea    -0x85a64(%ebx),%eax
f01026de:	50                   	push   %eax
f01026df:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01026e5:	50                   	push   %eax
f01026e6:	68 8e 03 00 00       	push   $0x38e
f01026eb:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01026f1:	50                   	push   %eax
f01026f2:	e8 ba d9 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026f7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026fa:	8d 83 2c a5 f7 ff    	lea    -0x85ad4(%ebx),%eax
f0102700:	50                   	push   %eax
f0102701:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102707:	50                   	push   %eax
f0102708:	68 8f 03 00 00       	push   $0x38f
f010270d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102713:	50                   	push   %eax
f0102714:	e8 98 d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102719:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010271c:	8d 83 d8 a5 f7 ff    	lea    -0x85a28(%ebx),%eax
f0102722:	50                   	push   %eax
f0102723:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102729:	50                   	push   %eax
f010272a:	68 92 03 00 00       	push   $0x392
f010272f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102735:	50                   	push   %eax
f0102736:	e8 76 d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010273b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010273e:	8d 83 04 a6 f7 ff    	lea    -0x859fc(%ebx),%eax
f0102744:	50                   	push   %eax
f0102745:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010274b:	50                   	push   %eax
f010274c:	68 93 03 00 00       	push   $0x393
f0102751:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102757:	50                   	push   %eax
f0102758:	e8 54 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 2);
f010275d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102760:	8d 83 dc aa f7 ff    	lea    -0x85524(%ebx),%eax
f0102766:	50                   	push   %eax
f0102767:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010276d:	50                   	push   %eax
f010276e:	68 95 03 00 00       	push   $0x395
f0102773:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102779:	50                   	push   %eax
f010277a:	e8 32 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f010277f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102782:	8d 83 ed aa f7 ff    	lea    -0x85513(%ebx),%eax
f0102788:	50                   	push   %eax
f0102789:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010278f:	50                   	push   %eax
f0102790:	68 96 03 00 00       	push   $0x396
f0102795:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010279b:	50                   	push   %eax
f010279c:	e8 10 d9 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01027a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027a4:	8d 83 34 a6 f7 ff    	lea    -0x859cc(%ebx),%eax
f01027aa:	50                   	push   %eax
f01027ab:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01027b1:	50                   	push   %eax
f01027b2:	68 99 03 00 00       	push   $0x399
f01027b7:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01027bd:	50                   	push   %eax
f01027be:	e8 ee d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01027c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027c6:	8d 83 58 a6 f7 ff    	lea    -0x859a8(%ebx),%eax
f01027cc:	50                   	push   %eax
f01027cd:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01027d3:	50                   	push   %eax
f01027d4:	68 9d 03 00 00       	push   $0x39d
f01027d9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01027df:	50                   	push   %eax
f01027e0:	e8 cc d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027e5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027e8:	8d 83 04 a6 f7 ff    	lea    -0x859fc(%ebx),%eax
f01027ee:	50                   	push   %eax
f01027ef:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01027f5:	50                   	push   %eax
f01027f6:	68 9e 03 00 00       	push   $0x39e
f01027fb:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102801:	50                   	push   %eax
f0102802:	e8 aa d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102807:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010280a:	8d 83 93 aa f7 ff    	lea    -0x8556d(%ebx),%eax
f0102810:	50                   	push   %eax
f0102811:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102817:	50                   	push   %eax
f0102818:	68 9f 03 00 00       	push   $0x39f
f010281d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102823:	50                   	push   %eax
f0102824:	e8 88 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102829:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010282c:	8d 83 ed aa f7 ff    	lea    -0x85513(%ebx),%eax
f0102832:	50                   	push   %eax
f0102833:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102839:	50                   	push   %eax
f010283a:	68 a0 03 00 00       	push   $0x3a0
f010283f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102845:	50                   	push   %eax
f0102846:	e8 66 d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010284b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010284e:	8d 83 7c a6 f7 ff    	lea    -0x85984(%ebx),%eax
f0102854:	50                   	push   %eax
f0102855:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010285b:	50                   	push   %eax
f010285c:	68 a3 03 00 00       	push   $0x3a3
f0102861:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102867:	50                   	push   %eax
f0102868:	e8 44 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref);
f010286d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102870:	8d 83 fe aa f7 ff    	lea    -0x85502(%ebx),%eax
f0102876:	50                   	push   %eax
f0102877:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010287d:	50                   	push   %eax
f010287e:	68 a4 03 00 00       	push   $0x3a4
f0102883:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102889:	50                   	push   %eax
f010288a:	e8 22 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_link == NULL);
f010288f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102892:	8d 83 0a ab f7 ff    	lea    -0x854f6(%ebx),%eax
f0102898:	50                   	push   %eax
f0102899:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010289f:	50                   	push   %eax
f01028a0:	68 a5 03 00 00       	push   $0x3a5
f01028a5:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01028ab:	50                   	push   %eax
f01028ac:	e8 00 d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01028b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028b4:	8d 83 58 a6 f7 ff    	lea    -0x859a8(%ebx),%eax
f01028ba:	50                   	push   %eax
f01028bb:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01028c1:	50                   	push   %eax
f01028c2:	68 a9 03 00 00       	push   $0x3a9
f01028c7:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01028cd:	50                   	push   %eax
f01028ce:	e8 de d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01028d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028d6:	8d 83 b4 a6 f7 ff    	lea    -0x8594c(%ebx),%eax
f01028dc:	50                   	push   %eax
f01028dd:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01028e3:	50                   	push   %eax
f01028e4:	68 aa 03 00 00       	push   $0x3aa
f01028e9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01028ef:	50                   	push   %eax
f01028f0:	e8 bc d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f01028f5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028f8:	8d 83 1f ab f7 ff    	lea    -0x854e1(%ebx),%eax
f01028fe:	50                   	push   %eax
f01028ff:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102905:	50                   	push   %eax
f0102906:	68 ab 03 00 00       	push   $0x3ab
f010290b:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102911:	50                   	push   %eax
f0102912:	e8 9a d7 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102917:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010291a:	8d 83 ed aa f7 ff    	lea    -0x85513(%ebx),%eax
f0102920:	50                   	push   %eax
f0102921:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102927:	50                   	push   %eax
f0102928:	68 ac 03 00 00       	push   $0x3ac
f010292d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102933:	50                   	push   %eax
f0102934:	e8 78 d7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102939:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010293c:	8d 83 dc a6 f7 ff    	lea    -0x85924(%ebx),%eax
f0102942:	50                   	push   %eax
f0102943:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102949:	50                   	push   %eax
f010294a:	68 af 03 00 00       	push   $0x3af
f010294f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102955:	50                   	push   %eax
f0102956:	e8 56 d7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010295b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010295e:	8d 83 41 aa f7 ff    	lea    -0x855bf(%ebx),%eax
f0102964:	50                   	push   %eax
f0102965:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010296b:	50                   	push   %eax
f010296c:	68 b2 03 00 00       	push   $0x3b2
f0102971:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102977:	50                   	push   %eax
f0102978:	e8 34 d7 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010297d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102980:	8d 83 80 a3 f7 ff    	lea    -0x85c80(%ebx),%eax
f0102986:	50                   	push   %eax
f0102987:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f010298d:	50                   	push   %eax
f010298e:	68 b5 03 00 00       	push   $0x3b5
f0102993:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102999:	50                   	push   %eax
f010299a:	e8 12 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f010299f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029a2:	8d 83 a4 aa f7 ff    	lea    -0x8555c(%ebx),%eax
f01029a8:	50                   	push   %eax
f01029a9:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01029af:	50                   	push   %eax
f01029b0:	68 b7 03 00 00       	push   $0x3b7
f01029b5:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01029bb:	50                   	push   %eax
f01029bc:	e8 f0 d6 ff ff       	call   f01000b1 <_panic>
f01029c1:	52                   	push   %edx
f01029c2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029c5:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f01029cb:	50                   	push   %eax
f01029cc:	68 be 03 00 00       	push   $0x3be
f01029d1:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01029d7:	50                   	push   %eax
f01029d8:	e8 d4 d6 ff ff       	call   f01000b1 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01029dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029e0:	8d 83 30 ab f7 ff    	lea    -0x854d0(%ebx),%eax
f01029e6:	50                   	push   %eax
f01029e7:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01029ed:	50                   	push   %eax
f01029ee:	68 bf 03 00 00       	push   $0x3bf
f01029f3:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01029f9:	50                   	push   %eax
f01029fa:	e8 b2 d6 ff ff       	call   f01000b1 <_panic>
f01029ff:	50                   	push   %eax
f0102a00:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a03:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f0102a09:	50                   	push   %eax
f0102a0a:	6a 5d                	push   $0x5d
f0102a0c:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f0102a12:	50                   	push   %eax
f0102a13:	e8 99 d6 ff ff       	call   f01000b1 <_panic>
f0102a18:	52                   	push   %edx
f0102a19:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a1c:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f0102a22:	50                   	push   %eax
f0102a23:	6a 5d                	push   $0x5d
f0102a25:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f0102a2b:	50                   	push   %eax
f0102a2c:	e8 80 d6 ff ff       	call   f01000b1 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102a31:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a34:	8d 83 48 ab f7 ff    	lea    -0x854b8(%ebx),%eax
f0102a3a:	50                   	push   %eax
f0102a3b:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102a41:	50                   	push   %eax
f0102a42:	68 c9 03 00 00       	push   $0x3c9
f0102a47:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102a4d:	50                   	push   %eax
f0102a4e:	e8 5e d6 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a53:	50                   	push   %eax
f0102a54:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a57:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f0102a5d:	50                   	push   %eax
f0102a5e:	68 c7 00 00 00       	push   $0xc7
f0102a63:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102a69:	50                   	push   %eax
f0102a6a:	e8 42 d6 ff ff       	call   f01000b1 <_panic>
f0102a6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a72:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102a78:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f0102a7e:	50                   	push   %eax
f0102a7f:	68 dc 00 00 00       	push   $0xdc
f0102a84:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102a8a:	50                   	push   %eax
f0102a8b:	e8 21 d6 ff ff       	call   f01000b1 <_panic>
f0102a90:	ff 75 c0             	pushl  -0x40(%ebp)
f0102a93:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a96:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f0102a9c:	50                   	push   %eax
f0102a9d:	68 06 03 00 00       	push   $0x306
f0102aa2:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102aa8:	50                   	push   %eax
f0102aa9:	e8 03 d6 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102aae:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ab1:	8d 83 00 a7 f7 ff    	lea    -0x85900(%ebx),%eax
f0102ab7:	50                   	push   %eax
f0102ab8:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102abe:	50                   	push   %eax
f0102abf:	68 06 03 00 00       	push   $0x306
f0102ac4:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102aca:	50                   	push   %eax
f0102acb:	e8 e1 d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102ad0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ad3:	c7 c0 44 d3 18 f0    	mov    $0xf018d344,%eax
f0102ad9:	8b 00                	mov    (%eax),%eax
f0102adb:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102ade:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102ae1:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
f0102ae6:	8d 98 00 00 40 21    	lea    0x21400000(%eax),%ebx
f0102aec:	89 fa                	mov    %edi,%edx
f0102aee:	89 f0                	mov    %esi,%eax
f0102af0:	e8 6d e0 ff ff       	call   f0100b62 <check_va2pa>
f0102af5:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102afc:	76 22                	jbe    f0102b20 <mem_init+0x176d>
f0102afe:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102b01:	39 d0                	cmp    %edx,%eax
f0102b03:	75 39                	jne    f0102b3e <mem_init+0x178b>
f0102b05:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102b0b:	81 ff 00 80 c1 ee    	cmp    $0xeec18000,%edi
f0102b11:	75 d9                	jne    f0102aec <mem_init+0x1739>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b13:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102b16:	c1 e7 0c             	shl    $0xc,%edi
f0102b19:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102b1e:	eb 57                	jmp    f0102b77 <mem_init+0x17c4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b20:	ff 75 cc             	pushl  -0x34(%ebp)
f0102b23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b26:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f0102b2c:	50                   	push   %eax
f0102b2d:	68 0b 03 00 00       	push   $0x30b
f0102b32:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102b38:	50                   	push   %eax
f0102b39:	e8 73 d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102b3e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b41:	8d 83 34 a7 f7 ff    	lea    -0x858cc(%ebx),%eax
f0102b47:	50                   	push   %eax
f0102b48:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102b4e:	50                   	push   %eax
f0102b4f:	68 0b 03 00 00       	push   $0x30b
f0102b54:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102b5a:	50                   	push   %eax
f0102b5b:	e8 51 d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102b60:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102b66:	89 f0                	mov    %esi,%eax
f0102b68:	e8 f5 df ff ff       	call   f0100b62 <check_va2pa>
f0102b6d:	39 c3                	cmp    %eax,%ebx
f0102b6f:	75 51                	jne    f0102bc2 <mem_init+0x180f>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b71:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b77:	39 fb                	cmp    %edi,%ebx
f0102b79:	72 e5                	jb     f0102b60 <mem_init+0x17ad>
f0102b7b:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b80:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102b83:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102b89:	89 da                	mov    %ebx,%edx
f0102b8b:	89 f0                	mov    %esi,%eax
f0102b8d:	e8 d0 df ff ff       	call   f0100b62 <check_va2pa>
f0102b92:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102b95:	39 c2                	cmp    %eax,%edx
f0102b97:	75 4b                	jne    f0102be4 <mem_init+0x1831>
f0102b99:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b9f:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102ba5:	75 e2                	jne    f0102b89 <mem_init+0x17d6>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102ba7:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102bac:	89 f0                	mov    %esi,%eax
f0102bae:	e8 af df ff ff       	call   f0100b62 <check_va2pa>
f0102bb3:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102bb6:	75 4e                	jne    f0102c06 <mem_init+0x1853>
	for (i = 0; i < NPDENTRIES; i++) {
f0102bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bbd:	e9 8f 00 00 00       	jmp    f0102c51 <mem_init+0x189e>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bc2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bc5:	8d 83 68 a7 f7 ff    	lea    -0x85898(%ebx),%eax
f0102bcb:	50                   	push   %eax
f0102bcc:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102bd2:	50                   	push   %eax
f0102bd3:	68 0f 03 00 00       	push   $0x30f
f0102bd8:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102bde:	50                   	push   %eax
f0102bdf:	e8 cd d4 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102be4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102be7:	8d 83 90 a7 f7 ff    	lea    -0x85870(%ebx),%eax
f0102bed:	50                   	push   %eax
f0102bee:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102bf4:	50                   	push   %eax
f0102bf5:	68 13 03 00 00       	push   $0x313
f0102bfa:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102c00:	50                   	push   %eax
f0102c01:	e8 ab d4 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c06:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c09:	8d 83 d8 a7 f7 ff    	lea    -0x85828(%ebx),%eax
f0102c0f:	50                   	push   %eax
f0102c10:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102c16:	50                   	push   %eax
f0102c17:	68 14 03 00 00       	push   $0x314
f0102c1c:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102c22:	50                   	push   %eax
f0102c23:	e8 89 d4 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102c28:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102c2c:	74 52                	je     f0102c80 <mem_init+0x18cd>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c2e:	83 c0 01             	add    $0x1,%eax
f0102c31:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102c36:	0f 87 bb 00 00 00    	ja     f0102cf7 <mem_init+0x1944>
		switch (i) {
f0102c3c:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102c41:	72 0e                	jb     f0102c51 <mem_init+0x189e>
f0102c43:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102c48:	76 de                	jbe    f0102c28 <mem_init+0x1875>
f0102c4a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c4f:	74 d7                	je     f0102c28 <mem_init+0x1875>
			if (i >= PDX(KERNBASE)) {
f0102c51:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c56:	77 4a                	ja     f0102ca2 <mem_init+0x18ef>
				assert(pgdir[i] == 0);
f0102c58:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102c5c:	74 d0                	je     f0102c2e <mem_init+0x187b>
f0102c5e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c61:	8d 83 9a ab f7 ff    	lea    -0x85466(%ebx),%eax
f0102c67:	50                   	push   %eax
f0102c68:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102c6e:	50                   	push   %eax
f0102c6f:	68 24 03 00 00       	push   $0x324
f0102c74:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102c7a:	50                   	push   %eax
f0102c7b:	e8 31 d4 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102c80:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c83:	8d 83 78 ab f7 ff    	lea    -0x85488(%ebx),%eax
f0102c89:	50                   	push   %eax
f0102c8a:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102c90:	50                   	push   %eax
f0102c91:	68 1d 03 00 00       	push   $0x31d
f0102c96:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102c9c:	50                   	push   %eax
f0102c9d:	e8 0f d4 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102ca2:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102ca5:	f6 c2 01             	test   $0x1,%dl
f0102ca8:	74 2b                	je     f0102cd5 <mem_init+0x1922>
				assert(pgdir[i] & PTE_W);
f0102caa:	f6 c2 02             	test   $0x2,%dl
f0102cad:	0f 85 7b ff ff ff    	jne    f0102c2e <mem_init+0x187b>
f0102cb3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cb6:	8d 83 89 ab f7 ff    	lea    -0x85477(%ebx),%eax
f0102cbc:	50                   	push   %eax
f0102cbd:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102cc3:	50                   	push   %eax
f0102cc4:	68 22 03 00 00       	push   $0x322
f0102cc9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102ccf:	50                   	push   %eax
f0102cd0:	e8 dc d3 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102cd5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cd8:	8d 83 78 ab f7 ff    	lea    -0x85488(%ebx),%eax
f0102cde:	50                   	push   %eax
f0102cdf:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102ce5:	50                   	push   %eax
f0102ce6:	68 21 03 00 00       	push   $0x321
f0102ceb:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102cf1:	50                   	push   %eax
f0102cf2:	e8 ba d3 ff ff       	call   f01000b1 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102cf7:	83 ec 0c             	sub    $0xc,%esp
f0102cfa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102cfd:	8d 87 08 a8 f7 ff    	lea    -0x857f8(%edi),%eax
f0102d03:	50                   	push   %eax
f0102d04:	89 fb                	mov    %edi,%ebx
f0102d06:	e8 a5 09 00 00       	call   f01036b0 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102d0b:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102d11:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102d13:	83 c4 10             	add    $0x10,%esp
f0102d16:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d1b:	0f 86 44 02 00 00    	jbe    f0102f65 <mem_init+0x1bb2>
	return (physaddr_t)kva - KERNBASE;
f0102d21:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102d26:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102d29:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d2e:	e8 ac de ff ff       	call   f0100bdf <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102d33:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102d36:	83 e0 f3             	and    $0xfffffff3,%eax
f0102d39:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102d3e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102d41:	83 ec 0c             	sub    $0xc,%esp
f0102d44:	6a 00                	push   $0x0
f0102d46:	e8 06 e3 ff ff       	call   f0101051 <page_alloc>
f0102d4b:	89 c6                	mov    %eax,%esi
f0102d4d:	83 c4 10             	add    $0x10,%esp
f0102d50:	85 c0                	test   %eax,%eax
f0102d52:	0f 84 29 02 00 00    	je     f0102f81 <mem_init+0x1bce>
	assert((pp1 = page_alloc(0)));
f0102d58:	83 ec 0c             	sub    $0xc,%esp
f0102d5b:	6a 00                	push   $0x0
f0102d5d:	e8 ef e2 ff ff       	call   f0101051 <page_alloc>
f0102d62:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102d65:	83 c4 10             	add    $0x10,%esp
f0102d68:	85 c0                	test   %eax,%eax
f0102d6a:	0f 84 33 02 00 00    	je     f0102fa3 <mem_init+0x1bf0>
	assert((pp2 = page_alloc(0)));
f0102d70:	83 ec 0c             	sub    $0xc,%esp
f0102d73:	6a 00                	push   $0x0
f0102d75:	e8 d7 e2 ff ff       	call   f0101051 <page_alloc>
f0102d7a:	89 c7                	mov    %eax,%edi
f0102d7c:	83 c4 10             	add    $0x10,%esp
f0102d7f:	85 c0                	test   %eax,%eax
f0102d81:	0f 84 3e 02 00 00    	je     f0102fc5 <mem_init+0x1c12>
	page_free(pp0);
f0102d87:	83 ec 0c             	sub    $0xc,%esp
f0102d8a:	56                   	push   %esi
f0102d8b:	e8 49 e3 ff ff       	call   f01010d9 <page_free>
	return (pp - pages) << PGSHIFT;
f0102d90:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d93:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102d99:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102d9c:	2b 08                	sub    (%eax),%ecx
f0102d9e:	89 c8                	mov    %ecx,%eax
f0102da0:	c1 f8 03             	sar    $0x3,%eax
f0102da3:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102da6:	89 c1                	mov    %eax,%ecx
f0102da8:	c1 e9 0c             	shr    $0xc,%ecx
f0102dab:	83 c4 10             	add    $0x10,%esp
f0102dae:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102db4:	3b 0a                	cmp    (%edx),%ecx
f0102db6:	0f 83 2b 02 00 00    	jae    f0102fe7 <mem_init+0x1c34>
	memset(page2kva(pp1), 1, PGSIZE);
f0102dbc:	83 ec 04             	sub    $0x4,%esp
f0102dbf:	68 00 10 00 00       	push   $0x1000
f0102dc4:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102dc6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102dcb:	50                   	push   %eax
f0102dcc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dcf:	e8 8c 19 00 00       	call   f0104760 <memset>
	return (pp - pages) << PGSHIFT;
f0102dd4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dd7:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102ddd:	89 f9                	mov    %edi,%ecx
f0102ddf:	2b 08                	sub    (%eax),%ecx
f0102de1:	89 c8                	mov    %ecx,%eax
f0102de3:	c1 f8 03             	sar    $0x3,%eax
f0102de6:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102de9:	89 c1                	mov    %eax,%ecx
f0102deb:	c1 e9 0c             	shr    $0xc,%ecx
f0102dee:	83 c4 10             	add    $0x10,%esp
f0102df1:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102df7:	3b 0a                	cmp    (%edx),%ecx
f0102df9:	0f 83 fe 01 00 00    	jae    f0102ffd <mem_init+0x1c4a>
	memset(page2kva(pp2), 2, PGSIZE);
f0102dff:	83 ec 04             	sub    $0x4,%esp
f0102e02:	68 00 10 00 00       	push   $0x1000
f0102e07:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102e09:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e0e:	50                   	push   %eax
f0102e0f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e12:	e8 49 19 00 00       	call   f0104760 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102e17:	6a 02                	push   $0x2
f0102e19:	68 00 10 00 00       	push   $0x1000
f0102e1e:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102e21:	53                   	push   %ebx
f0102e22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e25:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102e2b:	ff 30                	pushl  (%eax)
f0102e2d:	e8 03 e5 ff ff       	call   f0101335 <page_insert>
	assert(pp1->pp_ref == 1);
f0102e32:	83 c4 20             	add    $0x20,%esp
f0102e35:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e3a:	0f 85 d3 01 00 00    	jne    f0103013 <mem_init+0x1c60>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e40:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102e47:	01 01 01 
f0102e4a:	0f 85 e5 01 00 00    	jne    f0103035 <mem_init+0x1c82>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102e50:	6a 02                	push   $0x2
f0102e52:	68 00 10 00 00       	push   $0x1000
f0102e57:	57                   	push   %edi
f0102e58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e5b:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102e61:	ff 30                	pushl  (%eax)
f0102e63:	e8 cd e4 ff ff       	call   f0101335 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e68:	83 c4 10             	add    $0x10,%esp
f0102e6b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102e72:	02 02 02 
f0102e75:	0f 85 dc 01 00 00    	jne    f0103057 <mem_init+0x1ca4>
	assert(pp2->pp_ref == 1);
f0102e7b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102e80:	0f 85 f3 01 00 00    	jne    f0103079 <mem_init+0x1cc6>
	assert(pp1->pp_ref == 0);
f0102e86:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102e89:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102e8e:	0f 85 07 02 00 00    	jne    f010309b <mem_init+0x1ce8>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102e94:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102e9b:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102e9e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ea1:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102ea7:	89 f9                	mov    %edi,%ecx
f0102ea9:	2b 08                	sub    (%eax),%ecx
f0102eab:	89 c8                	mov    %ecx,%eax
f0102ead:	c1 f8 03             	sar    $0x3,%eax
f0102eb0:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102eb3:	89 c1                	mov    %eax,%ecx
f0102eb5:	c1 e9 0c             	shr    $0xc,%ecx
f0102eb8:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102ebe:	3b 0a                	cmp    (%edx),%ecx
f0102ec0:	0f 83 f7 01 00 00    	jae    f01030bd <mem_init+0x1d0a>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ec6:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102ecd:	03 03 03 
f0102ed0:	0f 85 fd 01 00 00    	jne    f01030d3 <mem_init+0x1d20>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102ed6:	83 ec 08             	sub    $0x8,%esp
f0102ed9:	68 00 10 00 00       	push   $0x1000
f0102ede:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ee1:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102ee7:	ff 30                	pushl  (%eax)
f0102ee9:	e8 0a e4 ff ff       	call   f01012f8 <page_remove>
	assert(pp2->pp_ref == 0);
f0102eee:	83 c4 10             	add    $0x10,%esp
f0102ef1:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ef6:	0f 85 f9 01 00 00    	jne    f01030f5 <mem_init+0x1d42>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102efc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102eff:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102f05:	8b 08                	mov    (%eax),%ecx
f0102f07:	8b 11                	mov    (%ecx),%edx
f0102f09:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102f0f:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102f15:	89 f7                	mov    %esi,%edi
f0102f17:	2b 38                	sub    (%eax),%edi
f0102f19:	89 f8                	mov    %edi,%eax
f0102f1b:	c1 f8 03             	sar    $0x3,%eax
f0102f1e:	c1 e0 0c             	shl    $0xc,%eax
f0102f21:	39 c2                	cmp    %eax,%edx
f0102f23:	0f 85 ee 01 00 00    	jne    f0103117 <mem_init+0x1d64>
	kern_pgdir[0] = 0;
f0102f29:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102f2f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f34:	0f 85 ff 01 00 00    	jne    f0103139 <mem_init+0x1d86>
	pp0->pp_ref = 0;
f0102f3a:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102f40:	83 ec 0c             	sub    $0xc,%esp
f0102f43:	56                   	push   %esi
f0102f44:	e8 90 e1 ff ff       	call   f01010d9 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102f49:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f4c:	8d 83 9c a8 f7 ff    	lea    -0x85764(%ebx),%eax
f0102f52:	89 04 24             	mov    %eax,(%esp)
f0102f55:	e8 56 07 00 00       	call   f01036b0 <cprintf>
}
f0102f5a:	83 c4 10             	add    $0x10,%esp
f0102f5d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f60:	5b                   	pop    %ebx
f0102f61:	5e                   	pop    %esi
f0102f62:	5f                   	pop    %edi
f0102f63:	5d                   	pop    %ebp
f0102f64:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f65:	50                   	push   %eax
f0102f66:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f69:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f0102f6f:	50                   	push   %eax
f0102f70:	68 f0 00 00 00       	push   $0xf0
f0102f75:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102f7b:	50                   	push   %eax
f0102f7c:	e8 30 d1 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0102f81:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f84:	8d 83 96 a9 f7 ff    	lea    -0x8566a(%ebx),%eax
f0102f8a:	50                   	push   %eax
f0102f8b:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102f91:	50                   	push   %eax
f0102f92:	68 e4 03 00 00       	push   $0x3e4
f0102f97:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102f9d:	50                   	push   %eax
f0102f9e:	e8 0e d1 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0102fa3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fa6:	8d 83 ac a9 f7 ff    	lea    -0x85654(%ebx),%eax
f0102fac:	50                   	push   %eax
f0102fad:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102fb3:	50                   	push   %eax
f0102fb4:	68 e5 03 00 00       	push   $0x3e5
f0102fb9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102fbf:	50                   	push   %eax
f0102fc0:	e8 ec d0 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0102fc5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fc8:	8d 83 c2 a9 f7 ff    	lea    -0x8563e(%ebx),%eax
f0102fce:	50                   	push   %eax
f0102fcf:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0102fd5:	50                   	push   %eax
f0102fd6:	68 e6 03 00 00       	push   $0x3e6
f0102fdb:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0102fe1:	50                   	push   %eax
f0102fe2:	e8 ca d0 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fe7:	50                   	push   %eax
f0102fe8:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f0102fee:	50                   	push   %eax
f0102fef:	6a 5d                	push   $0x5d
f0102ff1:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f0102ff7:	50                   	push   %eax
f0102ff8:	e8 b4 d0 ff ff       	call   f01000b1 <_panic>
f0102ffd:	50                   	push   %eax
f0102ffe:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f0103004:	50                   	push   %eax
f0103005:	6a 5d                	push   $0x5d
f0103007:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f010300d:	50                   	push   %eax
f010300e:	e8 9e d0 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0103013:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103016:	8d 83 93 aa f7 ff    	lea    -0x8556d(%ebx),%eax
f010301c:	50                   	push   %eax
f010301d:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103023:	50                   	push   %eax
f0103024:	68 eb 03 00 00       	push   $0x3eb
f0103029:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f010302f:	50                   	push   %eax
f0103030:	e8 7c d0 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103035:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103038:	8d 83 28 a8 f7 ff    	lea    -0x857d8(%ebx),%eax
f010303e:	50                   	push   %eax
f010303f:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103045:	50                   	push   %eax
f0103046:	68 ec 03 00 00       	push   $0x3ec
f010304b:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0103051:	50                   	push   %eax
f0103052:	e8 5a d0 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103057:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010305a:	8d 83 4c a8 f7 ff    	lea    -0x857b4(%ebx),%eax
f0103060:	50                   	push   %eax
f0103061:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103067:	50                   	push   %eax
f0103068:	68 ee 03 00 00       	push   $0x3ee
f010306d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0103073:	50                   	push   %eax
f0103074:	e8 38 d0 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0103079:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010307c:	8d 83 b5 aa f7 ff    	lea    -0x8554b(%ebx),%eax
f0103082:	50                   	push   %eax
f0103083:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103089:	50                   	push   %eax
f010308a:	68 ef 03 00 00       	push   $0x3ef
f010308f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0103095:	50                   	push   %eax
f0103096:	e8 16 d0 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f010309b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010309e:	8d 83 1f ab f7 ff    	lea    -0x854e1(%ebx),%eax
f01030a4:	50                   	push   %eax
f01030a5:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01030ab:	50                   	push   %eax
f01030ac:	68 f0 03 00 00       	push   $0x3f0
f01030b1:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01030b7:	50                   	push   %eax
f01030b8:	e8 f4 cf ff ff       	call   f01000b1 <_panic>
f01030bd:	50                   	push   %eax
f01030be:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f01030c4:	50                   	push   %eax
f01030c5:	6a 5d                	push   $0x5d
f01030c7:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f01030cd:	50                   	push   %eax
f01030ce:	e8 de cf ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01030d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030d6:	8d 83 70 a8 f7 ff    	lea    -0x85790(%ebx),%eax
f01030dc:	50                   	push   %eax
f01030dd:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f01030e3:	50                   	push   %eax
f01030e4:	68 f2 03 00 00       	push   $0x3f2
f01030e9:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f01030ef:	50                   	push   %eax
f01030f0:	e8 bc cf ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01030f5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030f8:	8d 83 ed aa f7 ff    	lea    -0x85513(%ebx),%eax
f01030fe:	50                   	push   %eax
f01030ff:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103105:	50                   	push   %eax
f0103106:	68 f4 03 00 00       	push   $0x3f4
f010310b:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0103111:	50                   	push   %eax
f0103112:	e8 9a cf ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103117:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010311a:	8d 83 80 a3 f7 ff    	lea    -0x85c80(%ebx),%eax
f0103120:	50                   	push   %eax
f0103121:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103127:	50                   	push   %eax
f0103128:	68 f7 03 00 00       	push   $0x3f7
f010312d:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0103133:	50                   	push   %eax
f0103134:	e8 78 cf ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0103139:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010313c:	8d 83 a4 aa f7 ff    	lea    -0x8555c(%ebx),%eax
f0103142:	50                   	push   %eax
f0103143:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103149:	50                   	push   %eax
f010314a:	68 f9 03 00 00       	push   $0x3f9
f010314f:	8d 83 c5 a8 f7 ff    	lea    -0x8573b(%ebx),%eax
f0103155:	50                   	push   %eax
f0103156:	e8 56 cf ff ff       	call   f01000b1 <_panic>

f010315b <tlb_invalidate>:
{
f010315b:	55                   	push   %ebp
f010315c:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010315e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103161:	0f 01 38             	invlpg (%eax)
}
f0103164:	5d                   	pop    %ebp
f0103165:	c3                   	ret    

f0103166 <user_mem_check>:
{
f0103166:	55                   	push   %ebp
f0103167:	89 e5                	mov    %esp,%ebp
}
f0103169:	b8 00 00 00 00       	mov    $0x0,%eax
f010316e:	5d                   	pop    %ebp
f010316f:	c3                   	ret    

f0103170 <user_mem_assert>:
{
f0103170:	55                   	push   %ebp
f0103171:	89 e5                	mov    %esp,%ebp
}
f0103173:	5d                   	pop    %ebp
f0103174:	c3                   	ret    

f0103175 <__x86.get_pc_thunk.dx>:
f0103175:	8b 14 24             	mov    (%esp),%edx
f0103178:	c3                   	ret    

f0103179 <__x86.get_pc_thunk.cx>:
f0103179:	8b 0c 24             	mov    (%esp),%ecx
f010317c:	c3                   	ret    

f010317d <__x86.get_pc_thunk.si>:
f010317d:	8b 34 24             	mov    (%esp),%esi
f0103180:	c3                   	ret    

f0103181 <__x86.get_pc_thunk.di>:
f0103181:	8b 3c 24             	mov    (%esp),%edi
f0103184:	c3                   	ret    

f0103185 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103185:	55                   	push   %ebp
f0103186:	89 e5                	mov    %esp,%ebp
f0103188:	53                   	push   %ebx
f0103189:	e8 eb ff ff ff       	call   f0103179 <__x86.get_pc_thunk.cx>
f010318e:	81 c1 92 7e 08 00    	add    $0x87e92,%ecx
f0103194:	8b 55 08             	mov    0x8(%ebp),%edx
f0103197:	8b 5d 10             	mov    0x10(%ebp),%ebx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010319a:	85 d2                	test   %edx,%edx
f010319c:	74 41                	je     f01031df <envid2env+0x5a>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010319e:	89 d0                	mov    %edx,%eax
f01031a0:	25 ff 03 00 00       	and    $0x3ff,%eax
f01031a5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01031a8:	c1 e0 05             	shl    $0x5,%eax
f01031ab:	03 81 24 23 00 00    	add    0x2324(%ecx),%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01031b1:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01031b5:	74 3a                	je     f01031f1 <envid2env+0x6c>
f01031b7:	39 50 48             	cmp    %edx,0x48(%eax)
f01031ba:	75 35                	jne    f01031f1 <envid2env+0x6c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01031bc:	84 db                	test   %bl,%bl
f01031be:	74 12                	je     f01031d2 <envid2env+0x4d>
f01031c0:	8b 91 20 23 00 00    	mov    0x2320(%ecx),%edx
f01031c6:	39 c2                	cmp    %eax,%edx
f01031c8:	74 08                	je     f01031d2 <envid2env+0x4d>
f01031ca:	8b 5a 48             	mov    0x48(%edx),%ebx
f01031cd:	39 58 4c             	cmp    %ebx,0x4c(%eax)
f01031d0:	75 2f                	jne    f0103201 <envid2env+0x7c>
		*env_store = 0;
		return -E_BAD_ENV;
	}

	*env_store = e;
f01031d2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01031d5:	89 03                	mov    %eax,(%ebx)
	return 0;
f01031d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031dc:	5b                   	pop    %ebx
f01031dd:	5d                   	pop    %ebp
f01031de:	c3                   	ret    
		*env_store = curenv;
f01031df:	8b 81 20 23 00 00    	mov    0x2320(%ecx),%eax
f01031e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031e8:	89 01                	mov    %eax,(%ecx)
		return 0;
f01031ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01031ef:	eb eb                	jmp    f01031dc <envid2env+0x57>
		*env_store = 0;
f01031f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031f4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01031fa:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01031ff:	eb db                	jmp    f01031dc <envid2env+0x57>
		*env_store = 0;
f0103201:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103204:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010320a:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010320f:	eb cb                	jmp    f01031dc <envid2env+0x57>

f0103211 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103211:	55                   	push   %ebp
f0103212:	89 e5                	mov    %esp,%ebp
f0103214:	e8 f0 d4 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f0103219:	05 07 7e 08 00       	add    $0x87e07,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f010321e:	8d 80 e0 1f 00 00    	lea    0x1fe0(%eax),%eax
f0103224:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103227:	b8 23 00 00 00       	mov    $0x23,%eax
f010322c:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010322e:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0103230:	b8 10 00 00 00       	mov    $0x10,%eax
f0103235:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103237:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103239:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f010323b:	ea 42 32 10 f0 08 00 	ljmp   $0x8,$0xf0103242
	asm volatile("lldt %0" : : "r" (sel));
f0103242:	b8 00 00 00 00       	mov    $0x0,%eax
f0103247:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f010324a:	5d                   	pop    %ebp
f010324b:	c3                   	ret    

f010324c <env_init>:
{
f010324c:	55                   	push   %ebp
f010324d:	89 e5                	mov    %esp,%ebp
	env_init_percpu();
f010324f:	e8 bd ff ff ff       	call   f0103211 <env_init_percpu>
}
f0103254:	5d                   	pop    %ebp
f0103255:	c3                   	ret    

f0103256 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103256:	55                   	push   %ebp
f0103257:	89 e5                	mov    %esp,%ebp
f0103259:	56                   	push   %esi
f010325a:	53                   	push   %ebx
f010325b:	e8 07 cf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103260:	81 c3 c0 7d 08 00    	add    $0x87dc0,%ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103266:	8b b3 28 23 00 00    	mov    0x2328(%ebx),%esi
f010326c:	85 f6                	test   %esi,%esi
f010326e:	0f 84 03 01 00 00    	je     f0103377 <env_alloc+0x121>
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103274:	83 ec 0c             	sub    $0xc,%esp
f0103277:	6a 01                	push   $0x1
f0103279:	e8 d3 dd ff ff       	call   f0101051 <page_alloc>
f010327e:	83 c4 10             	add    $0x10,%esp
f0103281:	85 c0                	test   %eax,%eax
f0103283:	0f 84 f5 00 00 00    	je     f010337e <env_alloc+0x128>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103289:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010328c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103291:	0f 86 c7 00 00 00    	jbe    f010335e <env_alloc+0x108>
	return (physaddr_t)kva - KERNBASE;
f0103297:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010329d:	83 ca 05             	or     $0x5,%edx
f01032a0:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01032a6:	8b 46 48             	mov    0x48(%esi),%eax
f01032a9:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01032ae:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01032b3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01032b8:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01032bb:	89 f2                	mov    %esi,%edx
f01032bd:	2b 93 24 23 00 00    	sub    0x2324(%ebx),%edx
f01032c3:	c1 fa 05             	sar    $0x5,%edx
f01032c6:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032cc:	09 d0                	or     %edx,%eax
f01032ce:	89 46 48             	mov    %eax,0x48(%esi)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01032d1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032d4:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f01032d7:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f01032de:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f01032e5:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01032ec:	83 ec 04             	sub    $0x4,%esp
f01032ef:	6a 44                	push   $0x44
f01032f1:	6a 00                	push   $0x0
f01032f3:	56                   	push   %esi
f01032f4:	e8 67 14 00 00       	call   f0104760 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01032f9:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f01032ff:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f0103305:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f010330b:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f0103312:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103318:	8b 46 44             	mov    0x44(%esi),%eax
f010331b:	89 83 28 23 00 00    	mov    %eax,0x2328(%ebx)
	*newenv_store = e;
f0103321:	8b 45 08             	mov    0x8(%ebp),%eax
f0103324:	89 30                	mov    %esi,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103326:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103329:	8b 83 20 23 00 00    	mov    0x2320(%ebx),%eax
f010332f:	83 c4 10             	add    $0x10,%esp
f0103332:	ba 00 00 00 00       	mov    $0x0,%edx
f0103337:	85 c0                	test   %eax,%eax
f0103339:	74 03                	je     f010333e <env_alloc+0xe8>
f010333b:	8b 50 48             	mov    0x48(%eax),%edx
f010333e:	83 ec 04             	sub    $0x4,%esp
f0103341:	51                   	push   %ecx
f0103342:	52                   	push   %edx
f0103343:	8d 83 e9 ab f7 ff    	lea    -0x85417(%ebx),%eax
f0103349:	50                   	push   %eax
f010334a:	e8 61 03 00 00       	call   f01036b0 <cprintf>
	return 0;
f010334f:	83 c4 10             	add    $0x10,%esp
f0103352:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103357:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010335a:	5b                   	pop    %ebx
f010335b:	5e                   	pop    %esi
f010335c:	5d                   	pop    %ebp
f010335d:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010335e:	50                   	push   %eax
f010335f:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f0103365:	50                   	push   %eax
f0103366:	68 b9 00 00 00       	push   $0xb9
f010336b:	8d 83 de ab f7 ff    	lea    -0x85422(%ebx),%eax
f0103371:	50                   	push   %eax
f0103372:	e8 3a cd ff ff       	call   f01000b1 <_panic>
		return -E_NO_FREE_ENV;
f0103377:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010337c:	eb d9                	jmp    f0103357 <env_alloc+0x101>
		return -E_NO_MEM;
f010337e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103383:	eb d2                	jmp    f0103357 <env_alloc+0x101>

f0103385 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103385:	55                   	push   %ebp
f0103386:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0103388:	5d                   	pop    %ebp
f0103389:	c3                   	ret    

f010338a <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010338a:	55                   	push   %ebp
f010338b:	89 e5                	mov    %esp,%ebp
f010338d:	57                   	push   %edi
f010338e:	56                   	push   %esi
f010338f:	53                   	push   %ebx
f0103390:	83 ec 2c             	sub    $0x2c,%esp
f0103393:	e8 cf cd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103398:	81 c3 88 7c 08 00    	add    $0x87c88,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010339e:	8b 93 20 23 00 00    	mov    0x2320(%ebx),%edx
f01033a4:	3b 55 08             	cmp    0x8(%ebp),%edx
f01033a7:	75 17                	jne    f01033c0 <env_free+0x36>
		lcr3(PADDR(kern_pgdir));
f01033a9:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f01033af:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01033b1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033b6:	76 46                	jbe    f01033fe <env_free+0x74>
	return (physaddr_t)kva - KERNBASE;
f01033b8:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01033bd:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01033c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01033c3:	8b 48 48             	mov    0x48(%eax),%ecx
f01033c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01033cb:	85 d2                	test   %edx,%edx
f01033cd:	74 03                	je     f01033d2 <env_free+0x48>
f01033cf:	8b 42 48             	mov    0x48(%edx),%eax
f01033d2:	83 ec 04             	sub    $0x4,%esp
f01033d5:	51                   	push   %ecx
f01033d6:	50                   	push   %eax
f01033d7:	8d 83 fe ab f7 ff    	lea    -0x85402(%ebx),%eax
f01033dd:	50                   	push   %eax
f01033de:	e8 cd 02 00 00       	call   f01036b0 <cprintf>
f01033e3:	83 c4 10             	add    $0x10,%esp
f01033e6:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	if (PGNUM(pa) >= npages)
f01033ed:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f01033f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (PGNUM(pa) >= npages)
f01033f6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01033f9:	e9 9f 00 00 00       	jmp    f010349d <env_free+0x113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033fe:	50                   	push   %eax
f01033ff:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f0103405:	50                   	push   %eax
f0103406:	68 68 01 00 00       	push   $0x168
f010340b:	8d 83 de ab f7 ff    	lea    -0x85422(%ebx),%eax
f0103411:	50                   	push   %eax
f0103412:	e8 9a cc ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103417:	50                   	push   %eax
f0103418:	8d 83 d8 a0 f7 ff    	lea    -0x85f28(%ebx),%eax
f010341e:	50                   	push   %eax
f010341f:	68 77 01 00 00       	push   $0x177
f0103424:	8d 83 de ab f7 ff    	lea    -0x85422(%ebx),%eax
f010342a:	50                   	push   %eax
f010342b:	e8 81 cc ff ff       	call   f01000b1 <_panic>
f0103430:	83 c6 04             	add    $0x4,%esi
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103433:	39 fe                	cmp    %edi,%esi
f0103435:	74 24                	je     f010345b <env_free+0xd1>
			if (pt[pteno] & PTE_P)
f0103437:	f6 06 01             	testb  $0x1,(%esi)
f010343a:	74 f4                	je     f0103430 <env_free+0xa6>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010343c:	83 ec 08             	sub    $0x8,%esp
f010343f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103442:	01 f0                	add    %esi,%eax
f0103444:	c1 e0 0a             	shl    $0xa,%eax
f0103447:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010344a:	50                   	push   %eax
f010344b:	8b 45 08             	mov    0x8(%ebp),%eax
f010344e:	ff 70 5c             	pushl  0x5c(%eax)
f0103451:	e8 a2 de ff ff       	call   f01012f8 <page_remove>
f0103456:	83 c4 10             	add    $0x10,%esp
f0103459:	eb d5                	jmp    f0103430 <env_free+0xa6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010345b:	8b 45 08             	mov    0x8(%ebp),%eax
f010345e:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103461:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103464:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f010346b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010346e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103471:	3b 10                	cmp    (%eax),%edx
f0103473:	73 6f                	jae    f01034e4 <env_free+0x15a>
		page_decref(pa2page(pa));
f0103475:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103478:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f010347e:	8b 00                	mov    (%eax),%eax
f0103480:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103483:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103486:	50                   	push   %eax
f0103487:	e8 9c dc ff ff       	call   f0101128 <page_decref>
f010348c:	83 c4 10             	add    $0x10,%esp
f010348f:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f0103493:	8b 45 dc             	mov    -0x24(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103496:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f010349b:	74 5f                	je     f01034fc <env_free+0x172>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010349d:	8b 45 08             	mov    0x8(%ebp),%eax
f01034a0:	8b 40 5c             	mov    0x5c(%eax),%eax
f01034a3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034a6:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01034a9:	a8 01                	test   $0x1,%al
f01034ab:	74 e2                	je     f010348f <env_free+0x105>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01034ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01034b2:	89 c2                	mov    %eax,%edx
f01034b4:	c1 ea 0c             	shr    $0xc,%edx
f01034b7:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01034ba:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01034bd:	39 11                	cmp    %edx,(%ecx)
f01034bf:	0f 86 52 ff ff ff    	jbe    f0103417 <env_free+0x8d>
	return (void *)(pa + KERNBASE);
f01034c5:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034cb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034ce:	c1 e2 14             	shl    $0x14,%edx
f01034d1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01034d4:	8d b8 00 10 00 f0    	lea    -0xffff000(%eax),%edi
f01034da:	f7 d8                	neg    %eax
f01034dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034df:	e9 53 ff ff ff       	jmp    f0103437 <env_free+0xad>
		panic("pa2page called with invalid pa");
f01034e4:	83 ec 04             	sub    $0x4,%esp
f01034e7:	8d 83 4c a2 f7 ff    	lea    -0x85db4(%ebx),%eax
f01034ed:	50                   	push   %eax
f01034ee:	6a 56                	push   $0x56
f01034f0:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f01034f6:	50                   	push   %eax
f01034f7:	e8 b5 cb ff ff       	call   f01000b1 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01034fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01034ff:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103502:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103507:	76 57                	jbe    f0103560 <env_free+0x1d6>
	e->env_pgdir = 0;
f0103509:	8b 55 08             	mov    0x8(%ebp),%edx
f010350c:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f0103513:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103518:	c1 e8 0c             	shr    $0xc,%eax
f010351b:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0103521:	3b 02                	cmp    (%edx),%eax
f0103523:	73 54                	jae    f0103579 <env_free+0x1ef>
	page_decref(pa2page(pa));
f0103525:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103528:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f010352e:	8b 12                	mov    (%edx),%edx
f0103530:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103533:	50                   	push   %eax
f0103534:	e8 ef db ff ff       	call   f0101128 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103539:	8b 45 08             	mov    0x8(%ebp),%eax
f010353c:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f0103543:	8b 83 28 23 00 00    	mov    0x2328(%ebx),%eax
f0103549:	8b 55 08             	mov    0x8(%ebp),%edx
f010354c:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f010354f:	89 93 28 23 00 00    	mov    %edx,0x2328(%ebx)
}
f0103555:	83 c4 10             	add    $0x10,%esp
f0103558:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010355b:	5b                   	pop    %ebx
f010355c:	5e                   	pop    %esi
f010355d:	5f                   	pop    %edi
f010355e:	5d                   	pop    %ebp
f010355f:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103560:	50                   	push   %eax
f0103561:	8d 83 e4 a1 f7 ff    	lea    -0x85e1c(%ebx),%eax
f0103567:	50                   	push   %eax
f0103568:	68 85 01 00 00       	push   $0x185
f010356d:	8d 83 de ab f7 ff    	lea    -0x85422(%ebx),%eax
f0103573:	50                   	push   %eax
f0103574:	e8 38 cb ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f0103579:	83 ec 04             	sub    $0x4,%esp
f010357c:	8d 83 4c a2 f7 ff    	lea    -0x85db4(%ebx),%eax
f0103582:	50                   	push   %eax
f0103583:	6a 56                	push   $0x56
f0103585:	8d 83 d1 a8 f7 ff    	lea    -0x8572f(%ebx),%eax
f010358b:	50                   	push   %eax
f010358c:	e8 20 cb ff ff       	call   f01000b1 <_panic>

f0103591 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103591:	55                   	push   %ebp
f0103592:	89 e5                	mov    %esp,%ebp
f0103594:	53                   	push   %ebx
f0103595:	83 ec 10             	sub    $0x10,%esp
f0103598:	e8 ca cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010359d:	81 c3 83 7a 08 00    	add    $0x87a83,%ebx
	env_free(e);
f01035a3:	ff 75 08             	pushl  0x8(%ebp)
f01035a6:	e8 df fd ff ff       	call   f010338a <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01035ab:	8d 83 a8 ab f7 ff    	lea    -0x85458(%ebx),%eax
f01035b1:	89 04 24             	mov    %eax,(%esp)
f01035b4:	e8 f7 00 00 00       	call   f01036b0 <cprintf>
f01035b9:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f01035bc:	83 ec 0c             	sub    $0xc,%esp
f01035bf:	6a 00                	push   $0x0
f01035c1:	e8 99 d3 ff ff       	call   f010095f <monitor>
f01035c6:	83 c4 10             	add    $0x10,%esp
f01035c9:	eb f1                	jmp    f01035bc <env_destroy+0x2b>

f01035cb <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035cb:	55                   	push   %ebp
f01035cc:	89 e5                	mov    %esp,%ebp
f01035ce:	53                   	push   %ebx
f01035cf:	83 ec 08             	sub    $0x8,%esp
f01035d2:	e8 90 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01035d7:	81 c3 49 7a 08 00    	add    $0x87a49,%ebx
	asm volatile(
f01035dd:	8b 65 08             	mov    0x8(%ebp),%esp
f01035e0:	61                   	popa   
f01035e1:	07                   	pop    %es
f01035e2:	1f                   	pop    %ds
f01035e3:	83 c4 08             	add    $0x8,%esp
f01035e6:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01035e7:	8d 83 14 ac f7 ff    	lea    -0x853ec(%ebx),%eax
f01035ed:	50                   	push   %eax
f01035ee:	68 ae 01 00 00       	push   $0x1ae
f01035f3:	8d 83 de ab f7 ff    	lea    -0x85422(%ebx),%eax
f01035f9:	50                   	push   %eax
f01035fa:	e8 b2 ca ff ff       	call   f01000b1 <_panic>

f01035ff <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01035ff:	55                   	push   %ebp
f0103600:	89 e5                	mov    %esp,%ebp
f0103602:	53                   	push   %ebx
f0103603:	83 ec 08             	sub    $0x8,%esp
f0103606:	e8 5c cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010360b:	81 c3 15 7a 08 00    	add    $0x87a15,%ebx
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f0103611:	8d 83 20 ac f7 ff    	lea    -0x853e0(%ebx),%eax
f0103617:	50                   	push   %eax
f0103618:	68 cd 01 00 00       	push   $0x1cd
f010361d:	8d 83 de ab f7 ff    	lea    -0x85422(%ebx),%eax
f0103623:	50                   	push   %eax
f0103624:	e8 88 ca ff ff       	call   f01000b1 <_panic>

f0103629 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103629:	55                   	push   %ebp
f010362a:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010362c:	8b 45 08             	mov    0x8(%ebp),%eax
f010362f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103634:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103635:	ba 71 00 00 00       	mov    $0x71,%edx
f010363a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010363b:	0f b6 c0             	movzbl %al,%eax
}
f010363e:	5d                   	pop    %ebp
f010363f:	c3                   	ret    

f0103640 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103640:	55                   	push   %ebp
f0103641:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103643:	8b 45 08             	mov    0x8(%ebp),%eax
f0103646:	ba 70 00 00 00       	mov    $0x70,%edx
f010364b:	ee                   	out    %al,(%dx)
f010364c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010364f:	ba 71 00 00 00       	mov    $0x71,%edx
f0103654:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103655:	5d                   	pop    %ebp
f0103656:	c3                   	ret    

f0103657 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103657:	55                   	push   %ebp
f0103658:	89 e5                	mov    %esp,%ebp
f010365a:	53                   	push   %ebx
f010365b:	83 ec 10             	sub    $0x10,%esp
f010365e:	e8 04 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103663:	81 c3 bd 79 08 00    	add    $0x879bd,%ebx
	cputchar(ch);
f0103669:	ff 75 08             	pushl  0x8(%ebp)
f010366c:	e8 6d d0 ff ff       	call   f01006de <cputchar>
	*cnt++;
}
f0103671:	83 c4 10             	add    $0x10,%esp
f0103674:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103677:	c9                   	leave  
f0103678:	c3                   	ret    

f0103679 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103679:	55                   	push   %ebp
f010367a:	89 e5                	mov    %esp,%ebp
f010367c:	53                   	push   %ebx
f010367d:	83 ec 14             	sub    $0x14,%esp
f0103680:	e8 e2 ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103685:	81 c3 9b 79 08 00    	add    $0x8799b,%ebx
	int cnt = 0;
f010368b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103692:	ff 75 0c             	pushl  0xc(%ebp)
f0103695:	ff 75 08             	pushl  0x8(%ebp)
f0103698:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010369b:	50                   	push   %eax
f010369c:	8d 83 37 86 f7 ff    	lea    -0x879c9(%ebx),%eax
f01036a2:	50                   	push   %eax
f01036a3:	e8 37 09 00 00       	call   f0103fdf <vprintfmt>
	return cnt;
}
f01036a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036ab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036ae:	c9                   	leave  
f01036af:	c3                   	ret    

f01036b0 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036b0:	55                   	push   %ebp
f01036b1:	89 e5                	mov    %esp,%ebp
f01036b3:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01036b6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01036b9:	50                   	push   %eax
f01036ba:	ff 75 08             	pushl  0x8(%ebp)
f01036bd:	e8 b7 ff ff ff       	call   f0103679 <vcprintf>
	va_end(ap);

	return cnt;
}
f01036c2:	c9                   	leave  
f01036c3:	c3                   	ret    

f01036c4 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01036c4:	55                   	push   %ebp
f01036c5:	89 e5                	mov    %esp,%ebp
f01036c7:	57                   	push   %edi
f01036c8:	56                   	push   %esi
f01036c9:	53                   	push   %ebx
f01036ca:	83 ec 04             	sub    $0x4,%esp
f01036cd:	e8 95 ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01036d2:	81 c3 4e 79 08 00    	add    $0x8794e,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01036d8:	c7 83 64 2b 00 00 00 	movl   $0xf0000000,0x2b64(%ebx)
f01036df:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01036e2:	66 c7 83 68 2b 00 00 	movw   $0x10,0x2b68(%ebx)
f01036e9:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f01036eb:	66 c7 83 c6 2b 00 00 	movw   $0x68,0x2bc6(%ebx)
f01036f2:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01036f4:	c7 c0 00 a3 11 f0    	mov    $0xf011a300,%eax
f01036fa:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103700:	8d b3 60 2b 00 00    	lea    0x2b60(%ebx),%esi
f0103706:	66 89 70 2a          	mov    %si,0x2a(%eax)
f010370a:	89 f2                	mov    %esi,%edx
f010370c:	c1 ea 10             	shr    $0x10,%edx
f010370f:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103712:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103716:	83 e2 f0             	and    $0xfffffff0,%edx
f0103719:	83 ca 09             	or     $0x9,%edx
f010371c:	83 e2 9f             	and    $0xffffff9f,%edx
f010371f:	83 ca 80             	or     $0xffffff80,%edx
f0103722:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103725:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103728:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f010372c:	83 e1 c0             	and    $0xffffffc0,%ecx
f010372f:	83 c9 40             	or     $0x40,%ecx
f0103732:	83 e1 7f             	and    $0x7f,%ecx
f0103735:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103738:	c1 ee 18             	shr    $0x18,%esi
f010373b:	89 f1                	mov    %esi,%ecx
f010373d:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103740:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103744:	83 e2 ef             	and    $0xffffffef,%edx
f0103747:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f010374a:	b8 28 00 00 00       	mov    $0x28,%eax
f010374f:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103752:	8d 83 e8 1f 00 00    	lea    0x1fe8(%ebx),%eax
f0103758:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010375b:	83 c4 04             	add    $0x4,%esp
f010375e:	5b                   	pop    %ebx
f010375f:	5e                   	pop    %esi
f0103760:	5f                   	pop    %edi
f0103761:	5d                   	pop    %ebp
f0103762:	c3                   	ret    

f0103763 <trap_init>:
{
f0103763:	55                   	push   %ebp
f0103764:	89 e5                	mov    %esp,%ebp
	trap_init_percpu();
f0103766:	e8 59 ff ff ff       	call   f01036c4 <trap_init_percpu>
}
f010376b:	5d                   	pop    %ebp
f010376c:	c3                   	ret    

f010376d <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010376d:	55                   	push   %ebp
f010376e:	89 e5                	mov    %esp,%ebp
f0103770:	56                   	push   %esi
f0103771:	53                   	push   %ebx
f0103772:	e8 f0 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103777:	81 c3 a9 78 08 00    	add    $0x878a9,%ebx
f010377d:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103780:	83 ec 08             	sub    $0x8,%esp
f0103783:	ff 36                	pushl  (%esi)
f0103785:	8d 83 3c ac f7 ff    	lea    -0x853c4(%ebx),%eax
f010378b:	50                   	push   %eax
f010378c:	e8 1f ff ff ff       	call   f01036b0 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103791:	83 c4 08             	add    $0x8,%esp
f0103794:	ff 76 04             	pushl  0x4(%esi)
f0103797:	8d 83 4b ac f7 ff    	lea    -0x853b5(%ebx),%eax
f010379d:	50                   	push   %eax
f010379e:	e8 0d ff ff ff       	call   f01036b0 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01037a3:	83 c4 08             	add    $0x8,%esp
f01037a6:	ff 76 08             	pushl  0x8(%esi)
f01037a9:	8d 83 5a ac f7 ff    	lea    -0x853a6(%ebx),%eax
f01037af:	50                   	push   %eax
f01037b0:	e8 fb fe ff ff       	call   f01036b0 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01037b5:	83 c4 08             	add    $0x8,%esp
f01037b8:	ff 76 0c             	pushl  0xc(%esi)
f01037bb:	8d 83 69 ac f7 ff    	lea    -0x85397(%ebx),%eax
f01037c1:	50                   	push   %eax
f01037c2:	e8 e9 fe ff ff       	call   f01036b0 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01037c7:	83 c4 08             	add    $0x8,%esp
f01037ca:	ff 76 10             	pushl  0x10(%esi)
f01037cd:	8d 83 78 ac f7 ff    	lea    -0x85388(%ebx),%eax
f01037d3:	50                   	push   %eax
f01037d4:	e8 d7 fe ff ff       	call   f01036b0 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01037d9:	83 c4 08             	add    $0x8,%esp
f01037dc:	ff 76 14             	pushl  0x14(%esi)
f01037df:	8d 83 87 ac f7 ff    	lea    -0x85379(%ebx),%eax
f01037e5:	50                   	push   %eax
f01037e6:	e8 c5 fe ff ff       	call   f01036b0 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01037eb:	83 c4 08             	add    $0x8,%esp
f01037ee:	ff 76 18             	pushl  0x18(%esi)
f01037f1:	8d 83 96 ac f7 ff    	lea    -0x8536a(%ebx),%eax
f01037f7:	50                   	push   %eax
f01037f8:	e8 b3 fe ff ff       	call   f01036b0 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01037fd:	83 c4 08             	add    $0x8,%esp
f0103800:	ff 76 1c             	pushl  0x1c(%esi)
f0103803:	8d 83 a5 ac f7 ff    	lea    -0x8535b(%ebx),%eax
f0103809:	50                   	push   %eax
f010380a:	e8 a1 fe ff ff       	call   f01036b0 <cprintf>
}
f010380f:	83 c4 10             	add    $0x10,%esp
f0103812:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103815:	5b                   	pop    %ebx
f0103816:	5e                   	pop    %esi
f0103817:	5d                   	pop    %ebp
f0103818:	c3                   	ret    

f0103819 <print_trapframe>:
{
f0103819:	55                   	push   %ebp
f010381a:	89 e5                	mov    %esp,%ebp
f010381c:	57                   	push   %edi
f010381d:	56                   	push   %esi
f010381e:	53                   	push   %ebx
f010381f:	83 ec 14             	sub    $0x14,%esp
f0103822:	e8 40 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103827:	81 c3 f9 77 08 00    	add    $0x877f9,%ebx
f010382d:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f0103830:	56                   	push   %esi
f0103831:	8d 83 db ad f7 ff    	lea    -0x85225(%ebx),%eax
f0103837:	50                   	push   %eax
f0103838:	e8 73 fe ff ff       	call   f01036b0 <cprintf>
	print_regs(&tf->tf_regs);
f010383d:	89 34 24             	mov    %esi,(%esp)
f0103840:	e8 28 ff ff ff       	call   f010376d <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103845:	83 c4 08             	add    $0x8,%esp
f0103848:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f010384c:	50                   	push   %eax
f010384d:	8d 83 f6 ac f7 ff    	lea    -0x8530a(%ebx),%eax
f0103853:	50                   	push   %eax
f0103854:	e8 57 fe ff ff       	call   f01036b0 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103859:	83 c4 08             	add    $0x8,%esp
f010385c:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f0103860:	50                   	push   %eax
f0103861:	8d 83 09 ad f7 ff    	lea    -0x852f7(%ebx),%eax
f0103867:	50                   	push   %eax
f0103868:	e8 43 fe ff ff       	call   f01036b0 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010386d:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f0103870:	83 c4 10             	add    $0x10,%esp
f0103873:	83 fa 13             	cmp    $0x13,%edx
f0103876:	0f 86 e9 00 00 00    	jbe    f0103965 <print_trapframe+0x14c>
	return "(unknown trap)";
f010387c:	83 fa 30             	cmp    $0x30,%edx
f010387f:	8d 83 b4 ac f7 ff    	lea    -0x8534c(%ebx),%eax
f0103885:	8d 8b c0 ac f7 ff    	lea    -0x85340(%ebx),%ecx
f010388b:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010388e:	83 ec 04             	sub    $0x4,%esp
f0103891:	50                   	push   %eax
f0103892:	52                   	push   %edx
f0103893:	8d 83 1c ad f7 ff    	lea    -0x852e4(%ebx),%eax
f0103899:	50                   	push   %eax
f010389a:	e8 11 fe ff ff       	call   f01036b0 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010389f:	83 c4 10             	add    $0x10,%esp
f01038a2:	39 b3 40 2b 00 00    	cmp    %esi,0x2b40(%ebx)
f01038a8:	0f 84 c3 00 00 00    	je     f0103971 <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
f01038ae:	83 ec 08             	sub    $0x8,%esp
f01038b1:	ff 76 2c             	pushl  0x2c(%esi)
f01038b4:	8d 83 3d ad f7 ff    	lea    -0x852c3(%ebx),%eax
f01038ba:	50                   	push   %eax
f01038bb:	e8 f0 fd ff ff       	call   f01036b0 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f01038c0:	83 c4 10             	add    $0x10,%esp
f01038c3:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01038c7:	0f 85 c9 00 00 00    	jne    f0103996 <print_trapframe+0x17d>
			tf->tf_err & 1 ? "protection" : "not-present");
f01038cd:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f01038d0:	89 c2                	mov    %eax,%edx
f01038d2:	83 e2 01             	and    $0x1,%edx
f01038d5:	8d 8b cf ac f7 ff    	lea    -0x85331(%ebx),%ecx
f01038db:	8d 93 da ac f7 ff    	lea    -0x85326(%ebx),%edx
f01038e1:	0f 44 ca             	cmove  %edx,%ecx
f01038e4:	89 c2                	mov    %eax,%edx
f01038e6:	83 e2 02             	and    $0x2,%edx
f01038e9:	8d 93 e6 ac f7 ff    	lea    -0x8531a(%ebx),%edx
f01038ef:	8d bb ec ac f7 ff    	lea    -0x85314(%ebx),%edi
f01038f5:	0f 44 d7             	cmove  %edi,%edx
f01038f8:	83 e0 04             	and    $0x4,%eax
f01038fb:	8d 83 f1 ac f7 ff    	lea    -0x8530f(%ebx),%eax
f0103901:	8d bb 06 ae f7 ff    	lea    -0x851fa(%ebx),%edi
f0103907:	0f 44 c7             	cmove  %edi,%eax
f010390a:	51                   	push   %ecx
f010390b:	52                   	push   %edx
f010390c:	50                   	push   %eax
f010390d:	8d 83 4b ad f7 ff    	lea    -0x852b5(%ebx),%eax
f0103913:	50                   	push   %eax
f0103914:	e8 97 fd ff ff       	call   f01036b0 <cprintf>
f0103919:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010391c:	83 ec 08             	sub    $0x8,%esp
f010391f:	ff 76 30             	pushl  0x30(%esi)
f0103922:	8d 83 5a ad f7 ff    	lea    -0x852a6(%ebx),%eax
f0103928:	50                   	push   %eax
f0103929:	e8 82 fd ff ff       	call   f01036b0 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010392e:	83 c4 08             	add    $0x8,%esp
f0103931:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103935:	50                   	push   %eax
f0103936:	8d 83 69 ad f7 ff    	lea    -0x85297(%ebx),%eax
f010393c:	50                   	push   %eax
f010393d:	e8 6e fd ff ff       	call   f01036b0 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103942:	83 c4 08             	add    $0x8,%esp
f0103945:	ff 76 38             	pushl  0x38(%esi)
f0103948:	8d 83 7c ad f7 ff    	lea    -0x85284(%ebx),%eax
f010394e:	50                   	push   %eax
f010394f:	e8 5c fd ff ff       	call   f01036b0 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103954:	83 c4 10             	add    $0x10,%esp
f0103957:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f010395b:	75 50                	jne    f01039ad <print_trapframe+0x194>
}
f010395d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103960:	5b                   	pop    %ebx
f0103961:	5e                   	pop    %esi
f0103962:	5f                   	pop    %edi
f0103963:	5d                   	pop    %ebp
f0103964:	c3                   	ret    
		return excnames[trapno];
f0103965:	8b 84 93 60 20 00 00 	mov    0x2060(%ebx,%edx,4),%eax
f010396c:	e9 1d ff ff ff       	jmp    f010388e <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103971:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103975:	0f 85 33 ff ff ff    	jne    f01038ae <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010397b:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010397e:	83 ec 08             	sub    $0x8,%esp
f0103981:	50                   	push   %eax
f0103982:	8d 83 2e ad f7 ff    	lea    -0x852d2(%ebx),%eax
f0103988:	50                   	push   %eax
f0103989:	e8 22 fd ff ff       	call   f01036b0 <cprintf>
f010398e:	83 c4 10             	add    $0x10,%esp
f0103991:	e9 18 ff ff ff       	jmp    f01038ae <print_trapframe+0x95>
		cprintf("\n");
f0103996:	83 ec 0c             	sub    $0xc,%esp
f0103999:	8d 83 76 ab f7 ff    	lea    -0x8548a(%ebx),%eax
f010399f:	50                   	push   %eax
f01039a0:	e8 0b fd ff ff       	call   f01036b0 <cprintf>
f01039a5:	83 c4 10             	add    $0x10,%esp
f01039a8:	e9 6f ff ff ff       	jmp    f010391c <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01039ad:	83 ec 08             	sub    $0x8,%esp
f01039b0:	ff 76 3c             	pushl  0x3c(%esi)
f01039b3:	8d 83 8b ad f7 ff    	lea    -0x85275(%ebx),%eax
f01039b9:	50                   	push   %eax
f01039ba:	e8 f1 fc ff ff       	call   f01036b0 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01039bf:	83 c4 08             	add    $0x8,%esp
f01039c2:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f01039c6:	50                   	push   %eax
f01039c7:	8d 83 9a ad f7 ff    	lea    -0x85266(%ebx),%eax
f01039cd:	50                   	push   %eax
f01039ce:	e8 dd fc ff ff       	call   f01036b0 <cprintf>
f01039d3:	83 c4 10             	add    $0x10,%esp
}
f01039d6:	eb 85                	jmp    f010395d <print_trapframe+0x144>

f01039d8 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01039d8:	55                   	push   %ebp
f01039d9:	89 e5                	mov    %esp,%ebp
f01039db:	57                   	push   %edi
f01039dc:	56                   	push   %esi
f01039dd:	53                   	push   %ebx
f01039de:	83 ec 0c             	sub    $0xc,%esp
f01039e1:	e8 81 c7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01039e6:	81 c3 3a 76 08 00    	add    $0x8763a,%ebx
f01039ec:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01039ef:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01039f0:	9c                   	pushf  
f01039f1:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01039f2:	f6 c4 02             	test   $0x2,%ah
f01039f5:	74 1f                	je     f0103a16 <trap+0x3e>
f01039f7:	8d 83 ad ad f7 ff    	lea    -0x85253(%ebx),%eax
f01039fd:	50                   	push   %eax
f01039fe:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103a04:	50                   	push   %eax
f0103a05:	68 a8 00 00 00       	push   $0xa8
f0103a0a:	8d 83 c6 ad f7 ff    	lea    -0x8523a(%ebx),%eax
f0103a10:	50                   	push   %eax
f0103a11:	e8 9b c6 ff ff       	call   f01000b1 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103a16:	83 ec 08             	sub    $0x8,%esp
f0103a19:	56                   	push   %esi
f0103a1a:	8d 83 d2 ad f7 ff    	lea    -0x8522e(%ebx),%eax
f0103a20:	50                   	push   %eax
f0103a21:	e8 8a fc ff ff       	call   f01036b0 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103a26:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103a2a:	83 e0 03             	and    $0x3,%eax
f0103a2d:	83 c4 10             	add    $0x10,%esp
f0103a30:	66 83 f8 03          	cmp    $0x3,%ax
f0103a34:	75 1d                	jne    f0103a53 <trap+0x7b>
		// Trapped from user mode.
		assert(curenv);
f0103a36:	c7 c0 40 d3 18 f0    	mov    $0xf018d340,%eax
f0103a3c:	8b 00                	mov    (%eax),%eax
f0103a3e:	85 c0                	test   %eax,%eax
f0103a40:	74 68                	je     f0103aaa <trap+0xd2>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103a42:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103a47:	89 c7                	mov    %eax,%edi
f0103a49:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103a4b:	c7 c0 40 d3 18 f0    	mov    $0xf018d340,%eax
f0103a51:	8b 30                	mov    (%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103a53:	89 b3 40 2b 00 00    	mov    %esi,0x2b40(%ebx)
	print_trapframe(tf);
f0103a59:	83 ec 0c             	sub    $0xc,%esp
f0103a5c:	56                   	push   %esi
f0103a5d:	e8 b7 fd ff ff       	call   f0103819 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103a62:	83 c4 10             	add    $0x10,%esp
f0103a65:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103a6a:	74 5d                	je     f0103ac9 <trap+0xf1>
		env_destroy(curenv);
f0103a6c:	83 ec 0c             	sub    $0xc,%esp
f0103a6f:	c7 c6 40 d3 18 f0    	mov    $0xf018d340,%esi
f0103a75:	ff 36                	pushl  (%esi)
f0103a77:	e8 15 fb ff ff       	call   f0103591 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103a7c:	8b 06                	mov    (%esi),%eax
f0103a7e:	83 c4 10             	add    $0x10,%esp
f0103a81:	85 c0                	test   %eax,%eax
f0103a83:	74 06                	je     f0103a8b <trap+0xb3>
f0103a85:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103a89:	74 59                	je     f0103ae4 <trap+0x10c>
f0103a8b:	8d 83 50 af f7 ff    	lea    -0x850b0(%ebx),%eax
f0103a91:	50                   	push   %eax
f0103a92:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103a98:	50                   	push   %eax
f0103a99:	68 c0 00 00 00       	push   $0xc0
f0103a9e:	8d 83 c6 ad f7 ff    	lea    -0x8523a(%ebx),%eax
f0103aa4:	50                   	push   %eax
f0103aa5:	e8 07 c6 ff ff       	call   f01000b1 <_panic>
		assert(curenv);
f0103aaa:	8d 83 ed ad f7 ff    	lea    -0x85213(%ebx),%eax
f0103ab0:	50                   	push   %eax
f0103ab1:	8d 83 eb a8 f7 ff    	lea    -0x85715(%ebx),%eax
f0103ab7:	50                   	push   %eax
f0103ab8:	68 ae 00 00 00       	push   $0xae
f0103abd:	8d 83 c6 ad f7 ff    	lea    -0x8523a(%ebx),%eax
f0103ac3:	50                   	push   %eax
f0103ac4:	e8 e8 c5 ff ff       	call   f01000b1 <_panic>
		panic("unhandled trap in kernel");
f0103ac9:	83 ec 04             	sub    $0x4,%esp
f0103acc:	8d 83 f4 ad f7 ff    	lea    -0x8520c(%ebx),%eax
f0103ad2:	50                   	push   %eax
f0103ad3:	68 97 00 00 00       	push   $0x97
f0103ad8:	8d 83 c6 ad f7 ff    	lea    -0x8523a(%ebx),%eax
f0103ade:	50                   	push   %eax
f0103adf:	e8 cd c5 ff ff       	call   f01000b1 <_panic>
	env_run(curenv);
f0103ae4:	83 ec 0c             	sub    $0xc,%esp
f0103ae7:	50                   	push   %eax
f0103ae8:	e8 12 fb ff ff       	call   f01035ff <env_run>

f0103aed <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103aed:	55                   	push   %ebp
f0103aee:	89 e5                	mov    %esp,%ebp
f0103af0:	57                   	push   %edi
f0103af1:	56                   	push   %esi
f0103af2:	53                   	push   %ebx
f0103af3:	83 ec 0c             	sub    $0xc,%esp
f0103af6:	e8 6c c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103afb:	81 c3 25 75 08 00    	add    $0x87525,%ebx
f0103b01:	8b 7d 08             	mov    0x8(%ebp),%edi
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103b04:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b07:	ff 77 30             	pushl  0x30(%edi)
f0103b0a:	50                   	push   %eax
f0103b0b:	c7 c6 40 d3 18 f0    	mov    $0xf018d340,%esi
f0103b11:	8b 06                	mov    (%esi),%eax
f0103b13:	ff 70 48             	pushl  0x48(%eax)
f0103b16:	8d 83 7c af f7 ff    	lea    -0x85084(%ebx),%eax
f0103b1c:	50                   	push   %eax
f0103b1d:	e8 8e fb ff ff       	call   f01036b0 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103b22:	89 3c 24             	mov    %edi,(%esp)
f0103b25:	e8 ef fc ff ff       	call   f0103819 <print_trapframe>
	env_destroy(curenv);
f0103b2a:	83 c4 04             	add    $0x4,%esp
f0103b2d:	ff 36                	pushl  (%esi)
f0103b2f:	e8 5d fa ff ff       	call   f0103591 <env_destroy>
}
f0103b34:	83 c4 10             	add    $0x10,%esp
f0103b37:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b3a:	5b                   	pop    %ebx
f0103b3b:	5e                   	pop    %esi
f0103b3c:	5f                   	pop    %edi
f0103b3d:	5d                   	pop    %ebp
f0103b3e:	c3                   	ret    

f0103b3f <syscall>:
f0103b3f:	55                   	push   %ebp
f0103b40:	89 e5                	mov    %esp,%ebp
f0103b42:	53                   	push   %ebx
f0103b43:	83 ec 08             	sub    $0x8,%esp
f0103b46:	e8 1c c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b4b:	81 c3 d5 74 08 00    	add    $0x874d5,%ebx
f0103b51:	8d 83 a0 af f7 ff    	lea    -0x85060(%ebx),%eax
f0103b57:	50                   	push   %eax
f0103b58:	6a 49                	push   $0x49
f0103b5a:	8d 83 b8 af f7 ff    	lea    -0x85048(%ebx),%eax
f0103b60:	50                   	push   %eax
f0103b61:	e8 4b c5 ff ff       	call   f01000b1 <_panic>

f0103b66 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103b66:	55                   	push   %ebp
f0103b67:	89 e5                	mov    %esp,%ebp
f0103b69:	57                   	push   %edi
f0103b6a:	56                   	push   %esi
f0103b6b:	53                   	push   %ebx
f0103b6c:	83 ec 14             	sub    $0x14,%esp
f0103b6f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103b72:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103b75:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b78:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103b7b:	8b 32                	mov    (%edx),%esi
f0103b7d:	8b 01                	mov    (%ecx),%eax
f0103b7f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103b82:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103b89:	eb 2f                	jmp    f0103bba <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103b8b:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103b8e:	39 c6                	cmp    %eax,%esi
f0103b90:	7f 49                	jg     f0103bdb <stab_binsearch+0x75>
f0103b92:	0f b6 0a             	movzbl (%edx),%ecx
f0103b95:	83 ea 0c             	sub    $0xc,%edx
f0103b98:	39 f9                	cmp    %edi,%ecx
f0103b9a:	75 ef                	jne    f0103b8b <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103b9c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103b9f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103ba2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103ba6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103ba9:	73 35                	jae    f0103be0 <stab_binsearch+0x7a>
			*region_left = m;
f0103bab:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103bae:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0103bb0:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0103bb3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103bba:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103bbd:	7f 4e                	jg     f0103c0d <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0103bbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103bc2:	01 f0                	add    %esi,%eax
f0103bc4:	89 c3                	mov    %eax,%ebx
f0103bc6:	c1 eb 1f             	shr    $0x1f,%ebx
f0103bc9:	01 c3                	add    %eax,%ebx
f0103bcb:	d1 fb                	sar    %ebx
f0103bcd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103bd0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103bd3:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103bd7:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0103bd9:	eb b3                	jmp    f0103b8e <stab_binsearch+0x28>
			l = true_m + 1;
f0103bdb:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103bde:	eb da                	jmp    f0103bba <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0103be0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103be3:	76 14                	jbe    f0103bf9 <stab_binsearch+0x93>
			*region_right = m - 1;
f0103be5:	83 e8 01             	sub    $0x1,%eax
f0103be8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103beb:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103bee:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103bf0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103bf7:	eb c1                	jmp    f0103bba <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103bf9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103bfc:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103bfe:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103c02:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0103c04:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103c0b:	eb ad                	jmp    f0103bba <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103c0d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103c11:	74 16                	je     f0103c29 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103c13:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c16:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103c18:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103c1b:	8b 0e                	mov    (%esi),%ecx
f0103c1d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103c20:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103c23:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0103c27:	eb 12                	jmp    f0103c3b <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103c29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103c2c:	8b 00                	mov    (%eax),%eax
f0103c2e:	83 e8 01             	sub    $0x1,%eax
f0103c31:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103c34:	89 07                	mov    %eax,(%edi)
f0103c36:	eb 16                	jmp    f0103c4e <stab_binsearch+0xe8>
		     l--)
f0103c38:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103c3b:	39 c1                	cmp    %eax,%ecx
f0103c3d:	7d 0a                	jge    f0103c49 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103c3f:	0f b6 1a             	movzbl (%edx),%ebx
f0103c42:	83 ea 0c             	sub    $0xc,%edx
f0103c45:	39 fb                	cmp    %edi,%ebx
f0103c47:	75 ef                	jne    f0103c38 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103c49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c4c:	89 07                	mov    %eax,(%edi)
	}
}
f0103c4e:	83 c4 14             	add    $0x14,%esp
f0103c51:	5b                   	pop    %ebx
f0103c52:	5e                   	pop    %esi
f0103c53:	5f                   	pop    %edi
f0103c54:	5d                   	pop    %ebp
f0103c55:	c3                   	ret    

f0103c56 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103c56:	55                   	push   %ebp
f0103c57:	89 e5                	mov    %esp,%ebp
f0103c59:	57                   	push   %edi
f0103c5a:	56                   	push   %esi
f0103c5b:	53                   	push   %ebx
f0103c5c:	83 ec 4c             	sub    $0x4c,%esp
f0103c5f:	e8 1d f5 ff ff       	call   f0103181 <__x86.get_pc_thunk.di>
f0103c64:	81 c7 bc 73 08 00    	add    $0x873bc,%edi
f0103c6a:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103c6d:	8d 87 c7 af f7 ff    	lea    -0x85039(%edi),%eax
f0103c73:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0103c75:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103c7c:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103c7f:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103c86:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c89:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f0103c8c:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103c93:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0103c98:	0f 87 2c 01 00 00    	ja     f0103dca <debuginfo_eip+0x174>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103c9e:	a1 00 00 20 00       	mov    0x200000,%eax
f0103ca3:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = usd->stab_end;
f0103ca6:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103cab:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0103cb1:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f0103cb4:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f0103cba:	89 5d bc             	mov    %ebx,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103cbd:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103cc0:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f0103cc3:	0f 83 e9 01 00 00    	jae    f0103eb2 <debuginfo_eip+0x25c>
f0103cc9:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0103ccd:	0f 85 e6 01 00 00    	jne    f0103eb9 <debuginfo_eip+0x263>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103cd3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103cda:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f0103cdd:	29 d8                	sub    %ebx,%eax
f0103cdf:	c1 f8 02             	sar    $0x2,%eax
f0103ce2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103ce8:	83 e8 01             	sub    $0x1,%eax
f0103ceb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103cee:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103cf1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103cf4:	ff 75 08             	pushl  0x8(%ebp)
f0103cf7:	6a 64                	push   $0x64
f0103cf9:	89 d8                	mov    %ebx,%eax
f0103cfb:	e8 66 fe ff ff       	call   f0103b66 <stab_binsearch>
	if (lfile == 0)
f0103d00:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103d03:	83 c4 08             	add    $0x8,%esp
f0103d06:	85 c0                	test   %eax,%eax
f0103d08:	0f 84 b2 01 00 00    	je     f0103ec0 <debuginfo_eip+0x26a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103d0e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103d11:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d14:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103d17:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103d1a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103d1d:	ff 75 08             	pushl  0x8(%ebp)
f0103d20:	6a 24                	push   $0x24
f0103d22:	89 d8                	mov    %ebx,%eax
f0103d24:	e8 3d fe ff ff       	call   f0103b66 <stab_binsearch>

	if (lfun <= rfun) {
f0103d29:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103d2c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103d2f:	83 c4 08             	add    $0x8,%esp
f0103d32:	39 d0                	cmp    %edx,%eax
f0103d34:	0f 8f b6 00 00 00    	jg     f0103df0 <debuginfo_eip+0x19a>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103d3a:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0103d3d:	8d 1c 8b             	lea    (%ebx,%ecx,4),%ebx
f0103d40:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f0103d43:	8b 0b                	mov    (%ebx),%ecx
f0103d45:	89 cb                	mov    %ecx,%ebx
f0103d47:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103d4a:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f0103d4d:	39 cb                	cmp    %ecx,%ebx
f0103d4f:	73 06                	jae    f0103d57 <debuginfo_eip+0x101>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103d51:	03 5d b4             	add    -0x4c(%ebp),%ebx
f0103d54:	89 5e 08             	mov    %ebx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103d57:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103d5a:	8b 4b 08             	mov    0x8(%ebx),%ecx
f0103d5d:	89 4e 10             	mov    %ecx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103d60:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0103d63:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103d66:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103d69:	83 ec 08             	sub    $0x8,%esp
f0103d6c:	6a 3a                	push   $0x3a
f0103d6e:	ff 76 08             	pushl  0x8(%esi)
f0103d71:	89 fb                	mov    %edi,%ebx
f0103d73:	e8 cc 09 00 00       	call   f0104744 <strfind>
f0103d78:	2b 46 08             	sub    0x8(%esi),%eax
f0103d7b:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103d7e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103d81:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103d84:	83 c4 08             	add    $0x8,%esp
f0103d87:	ff 75 08             	pushl  0x8(%ebp)
f0103d8a:	6a 44                	push   $0x44
f0103d8c:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103d8f:	89 f8                	mov    %edi,%eax
f0103d91:	e8 d0 fd ff ff       	call   f0103b66 <stab_binsearch>
	if(lline<=rline){
f0103d96:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103d99:	83 c4 10             	add    $0x10,%esp
f0103d9c:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103d9f:	0f 8f 22 01 00 00    	jg     f0103ec7 <debuginfo_eip+0x271>
		info->eip_line = stabs[lline].n_desc;
f0103da5:	89 d0                	mov    %edx,%eax
f0103da7:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103daa:	c1 e2 02             	shl    $0x2,%edx
f0103dad:	0f b7 4c 17 06       	movzwl 0x6(%edi,%edx,1),%ecx
f0103db2:	89 4e 04             	mov    %ecx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103db5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103db8:	8d 54 17 04          	lea    0x4(%edi,%edx,1),%edx
f0103dbc:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103dc0:	bf 01 00 00 00       	mov    $0x1,%edi
f0103dc5:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103dc8:	eb 48                	jmp    f0103e12 <debuginfo_eip+0x1bc>
		stabstr_end = __STABSTR_END__;
f0103dca:	c7 c0 b0 0c 11 f0    	mov    $0xf0110cb0,%eax
f0103dd0:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0103dd3:	c7 c0 c1 e2 10 f0    	mov    $0xf010e2c1,%eax
f0103dd9:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stab_end = __STAB_END__;
f0103ddc:	c7 c0 c0 e2 10 f0    	mov    $0xf010e2c0,%eax
		stabs = __STAB_BEGIN__;
f0103de2:	c7 c3 e4 61 10 f0    	mov    $0xf01061e4,%ebx
f0103de8:	89 5d b8             	mov    %ebx,-0x48(%ebp)
f0103deb:	e9 cd fe ff ff       	jmp    f0103cbd <debuginfo_eip+0x67>
		info->eip_fn_addr = addr;
f0103df0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103df3:	89 46 10             	mov    %eax,0x10(%esi)
		lline = lfile;
f0103df6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103df9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103dfc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103dff:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103e02:	e9 62 ff ff ff       	jmp    f0103d69 <debuginfo_eip+0x113>
f0103e07:	83 e8 01             	sub    $0x1,%eax
f0103e0a:	83 ea 0c             	sub    $0xc,%edx
f0103e0d:	89 f9                	mov    %edi,%ecx
f0103e0f:	88 4d c4             	mov    %cl,-0x3c(%ebp)
f0103e12:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0103e15:	39 c3                	cmp    %eax,%ebx
f0103e17:	7f 24                	jg     f0103e3d <debuginfo_eip+0x1e7>
	       && stabs[lline].n_type != N_SOL
f0103e19:	0f b6 0a             	movzbl (%edx),%ecx
f0103e1c:	80 f9 84             	cmp    $0x84,%cl
f0103e1f:	74 46                	je     f0103e67 <debuginfo_eip+0x211>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103e21:	80 f9 64             	cmp    $0x64,%cl
f0103e24:	75 e1                	jne    f0103e07 <debuginfo_eip+0x1b1>
f0103e26:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0103e2a:	74 db                	je     f0103e07 <debuginfo_eip+0x1b1>
f0103e2c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e2f:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103e33:	74 3b                	je     f0103e70 <debuginfo_eip+0x21a>
f0103e35:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103e38:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e3b:	eb 33                	jmp    f0103e70 <debuginfo_eip+0x21a>
f0103e3d:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103e40:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103e43:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103e46:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103e4b:	39 da                	cmp    %ebx,%edx
f0103e4d:	0f 8d 80 00 00 00    	jge    f0103ed3 <debuginfo_eip+0x27d>
		for (lline = lfun + 1;
f0103e53:	83 c2 01             	add    $0x1,%edx
f0103e56:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103e59:	89 d0                	mov    %edx,%eax
f0103e5b:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103e5e:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103e61:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0103e65:	eb 32                	jmp    f0103e99 <debuginfo_eip+0x243>
f0103e67:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e6a:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103e6e:	75 1d                	jne    f0103e8d <debuginfo_eip+0x237>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103e70:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103e73:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103e76:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103e79:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103e7c:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f0103e7f:	29 f8                	sub    %edi,%eax
f0103e81:	39 c2                	cmp    %eax,%edx
f0103e83:	73 bb                	jae    f0103e40 <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103e85:	89 f8                	mov    %edi,%eax
f0103e87:	01 d0                	add    %edx,%eax
f0103e89:	89 06                	mov    %eax,(%esi)
f0103e8b:	eb b3                	jmp    f0103e40 <debuginfo_eip+0x1ea>
f0103e8d:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103e90:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e93:	eb db                	jmp    f0103e70 <debuginfo_eip+0x21a>
			info->eip_fn_narg++;
f0103e95:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0103e99:	39 c3                	cmp    %eax,%ebx
f0103e9b:	7e 31                	jle    f0103ece <debuginfo_eip+0x278>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103e9d:	0f b6 0a             	movzbl (%edx),%ecx
f0103ea0:	83 c0 01             	add    $0x1,%eax
f0103ea3:	83 c2 0c             	add    $0xc,%edx
f0103ea6:	80 f9 a0             	cmp    $0xa0,%cl
f0103ea9:	74 ea                	je     f0103e95 <debuginfo_eip+0x23f>
	return 0;
f0103eab:	b8 00 00 00 00       	mov    $0x0,%eax
f0103eb0:	eb 21                	jmp    f0103ed3 <debuginfo_eip+0x27d>
		return -1;
f0103eb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103eb7:	eb 1a                	jmp    f0103ed3 <debuginfo_eip+0x27d>
f0103eb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ebe:	eb 13                	jmp    f0103ed3 <debuginfo_eip+0x27d>
		return -1;
f0103ec0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ec5:	eb 0c                	jmp    f0103ed3 <debuginfo_eip+0x27d>
		return -1;
f0103ec7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ecc:	eb 05                	jmp    f0103ed3 <debuginfo_eip+0x27d>
	return 0;
f0103ece:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ed3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ed6:	5b                   	pop    %ebx
f0103ed7:	5e                   	pop    %esi
f0103ed8:	5f                   	pop    %edi
f0103ed9:	5d                   	pop    %ebp
f0103eda:	c3                   	ret    

f0103edb <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103edb:	55                   	push   %ebp
f0103edc:	89 e5                	mov    %esp,%ebp
f0103ede:	57                   	push   %edi
f0103edf:	56                   	push   %esi
f0103ee0:	53                   	push   %ebx
f0103ee1:	83 ec 2c             	sub    $0x2c,%esp
f0103ee4:	e8 90 f2 ff ff       	call   f0103179 <__x86.get_pc_thunk.cx>
f0103ee9:	81 c1 37 71 08 00    	add    $0x87137,%ecx
f0103eef:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103ef2:	89 c7                	mov    %eax,%edi
f0103ef4:	89 d6                	mov    %edx,%esi
f0103ef6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ef9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103efc:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103eff:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103f02:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103f05:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103f0a:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0103f0d:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0103f10:	39 d3                	cmp    %edx,%ebx
f0103f12:	72 09                	jb     f0103f1d <printnum+0x42>
f0103f14:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103f17:	0f 87 83 00 00 00    	ja     f0103fa0 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103f1d:	83 ec 0c             	sub    $0xc,%esp
f0103f20:	ff 75 18             	pushl  0x18(%ebp)
f0103f23:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f26:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103f29:	53                   	push   %ebx
f0103f2a:	ff 75 10             	pushl  0x10(%ebp)
f0103f2d:	83 ec 08             	sub    $0x8,%esp
f0103f30:	ff 75 dc             	pushl  -0x24(%ebp)
f0103f33:	ff 75 d8             	pushl  -0x28(%ebp)
f0103f36:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103f39:	ff 75 d0             	pushl  -0x30(%ebp)
f0103f3c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103f3f:	e8 1c 0a 00 00       	call   f0104960 <__udivdi3>
f0103f44:	83 c4 18             	add    $0x18,%esp
f0103f47:	52                   	push   %edx
f0103f48:	50                   	push   %eax
f0103f49:	89 f2                	mov    %esi,%edx
f0103f4b:	89 f8                	mov    %edi,%eax
f0103f4d:	e8 89 ff ff ff       	call   f0103edb <printnum>
f0103f52:	83 c4 20             	add    $0x20,%esp
f0103f55:	eb 13                	jmp    f0103f6a <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103f57:	83 ec 08             	sub    $0x8,%esp
f0103f5a:	56                   	push   %esi
f0103f5b:	ff 75 18             	pushl  0x18(%ebp)
f0103f5e:	ff d7                	call   *%edi
f0103f60:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103f63:	83 eb 01             	sub    $0x1,%ebx
f0103f66:	85 db                	test   %ebx,%ebx
f0103f68:	7f ed                	jg     f0103f57 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103f6a:	83 ec 08             	sub    $0x8,%esp
f0103f6d:	56                   	push   %esi
f0103f6e:	83 ec 04             	sub    $0x4,%esp
f0103f71:	ff 75 dc             	pushl  -0x24(%ebp)
f0103f74:	ff 75 d8             	pushl  -0x28(%ebp)
f0103f77:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103f7a:	ff 75 d0             	pushl  -0x30(%ebp)
f0103f7d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103f80:	89 f3                	mov    %esi,%ebx
f0103f82:	e8 f9 0a 00 00       	call   f0104a80 <__umoddi3>
f0103f87:	83 c4 14             	add    $0x14,%esp
f0103f8a:	0f be 84 06 d1 af f7 	movsbl -0x8502f(%esi,%eax,1),%eax
f0103f91:	ff 
f0103f92:	50                   	push   %eax
f0103f93:	ff d7                	call   *%edi
}
f0103f95:	83 c4 10             	add    $0x10,%esp
f0103f98:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f9b:	5b                   	pop    %ebx
f0103f9c:	5e                   	pop    %esi
f0103f9d:	5f                   	pop    %edi
f0103f9e:	5d                   	pop    %ebp
f0103f9f:	c3                   	ret    
f0103fa0:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103fa3:	eb be                	jmp    f0103f63 <printnum+0x88>

f0103fa5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103fa5:	55                   	push   %ebp
f0103fa6:	89 e5                	mov    %esp,%ebp
f0103fa8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103fab:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103faf:	8b 10                	mov    (%eax),%edx
f0103fb1:	3b 50 04             	cmp    0x4(%eax),%edx
f0103fb4:	73 0a                	jae    f0103fc0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103fb6:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103fb9:	89 08                	mov    %ecx,(%eax)
f0103fbb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fbe:	88 02                	mov    %al,(%edx)
}
f0103fc0:	5d                   	pop    %ebp
f0103fc1:	c3                   	ret    

f0103fc2 <printfmt>:
{
f0103fc2:	55                   	push   %ebp
f0103fc3:	89 e5                	mov    %esp,%ebp
f0103fc5:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103fc8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103fcb:	50                   	push   %eax
f0103fcc:	ff 75 10             	pushl  0x10(%ebp)
f0103fcf:	ff 75 0c             	pushl  0xc(%ebp)
f0103fd2:	ff 75 08             	pushl  0x8(%ebp)
f0103fd5:	e8 05 00 00 00       	call   f0103fdf <vprintfmt>
}
f0103fda:	83 c4 10             	add    $0x10,%esp
f0103fdd:	c9                   	leave  
f0103fde:	c3                   	ret    

f0103fdf <vprintfmt>:
{
f0103fdf:	55                   	push   %ebp
f0103fe0:	89 e5                	mov    %esp,%ebp
f0103fe2:	57                   	push   %edi
f0103fe3:	56                   	push   %esi
f0103fe4:	53                   	push   %ebx
f0103fe5:	83 ec 2c             	sub    $0x2c,%esp
f0103fe8:	e8 7a c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103fed:	81 c3 33 70 08 00    	add    $0x87033,%ebx
f0103ff3:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ff6:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103ff9:	e9 c3 03 00 00       	jmp    f01043c1 <.L35+0x48>
		padc = ' ';
f0103ffe:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0104002:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0104009:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0104010:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0104017:	b9 00 00 00 00       	mov    $0x0,%ecx
f010401c:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010401f:	8d 47 01             	lea    0x1(%edi),%eax
f0104022:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104025:	0f b6 17             	movzbl (%edi),%edx
f0104028:	8d 42 dd             	lea    -0x23(%edx),%eax
f010402b:	3c 55                	cmp    $0x55,%al
f010402d:	0f 87 16 04 00 00    	ja     f0104449 <.L22>
f0104033:	0f b6 c0             	movzbl %al,%eax
f0104036:	89 d9                	mov    %ebx,%ecx
f0104038:	03 8c 83 5c b0 f7 ff 	add    -0x84fa4(%ebx,%eax,4),%ecx
f010403f:	ff e1                	jmp    *%ecx

f0104041 <.L69>:
f0104041:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0104044:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0104048:	eb d5                	jmp    f010401f <vprintfmt+0x40>

f010404a <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f010404a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010404d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104051:	eb cc                	jmp    f010401f <vprintfmt+0x40>

f0104053 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0104053:	0f b6 d2             	movzbl %dl,%edx
f0104056:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0104059:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010405e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104061:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104065:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104068:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010406b:	83 f9 09             	cmp    $0x9,%ecx
f010406e:	77 55                	ja     f01040c5 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0104070:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0104073:	eb e9                	jmp    f010405e <.L29+0xb>

f0104075 <.L26>:
			precision = va_arg(ap, int);
f0104075:	8b 45 14             	mov    0x14(%ebp),%eax
f0104078:	8b 00                	mov    (%eax),%eax
f010407a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010407d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104080:	8d 40 04             	lea    0x4(%eax),%eax
f0104083:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104086:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0104089:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010408d:	79 90                	jns    f010401f <vprintfmt+0x40>
				width = precision, precision = -1;
f010408f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104092:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104095:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f010409c:	eb 81                	jmp    f010401f <vprintfmt+0x40>

f010409e <.L27>:
f010409e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040a1:	85 c0                	test   %eax,%eax
f01040a3:	ba 00 00 00 00       	mov    $0x0,%edx
f01040a8:	0f 49 d0             	cmovns %eax,%edx
f01040ab:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01040ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040b1:	e9 69 ff ff ff       	jmp    f010401f <vprintfmt+0x40>

f01040b6 <.L23>:
f01040b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01040b9:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01040c0:	e9 5a ff ff ff       	jmp    f010401f <vprintfmt+0x40>
f01040c5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01040c8:	eb bf                	jmp    f0104089 <.L26+0x14>

f01040ca <.L33>:
			lflag++;
f01040ca:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01040ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01040d1:	e9 49 ff ff ff       	jmp    f010401f <vprintfmt+0x40>

f01040d6 <.L30>:
			putch(va_arg(ap, int), putdat);
f01040d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01040d9:	8d 78 04             	lea    0x4(%eax),%edi
f01040dc:	83 ec 08             	sub    $0x8,%esp
f01040df:	56                   	push   %esi
f01040e0:	ff 30                	pushl  (%eax)
f01040e2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01040e5:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01040e8:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01040eb:	e9 ce 02 00 00       	jmp    f01043be <.L35+0x45>

f01040f0 <.L32>:
			err = va_arg(ap, int);
f01040f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01040f3:	8d 78 04             	lea    0x4(%eax),%edi
f01040f6:	8b 00                	mov    (%eax),%eax
f01040f8:	99                   	cltd   
f01040f9:	31 d0                	xor    %edx,%eax
f01040fb:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01040fd:	83 f8 06             	cmp    $0x6,%eax
f0104100:	7f 27                	jg     f0104129 <.L32+0x39>
f0104102:	8b 94 83 b0 20 00 00 	mov    0x20b0(%ebx,%eax,4),%edx
f0104109:	85 d2                	test   %edx,%edx
f010410b:	74 1c                	je     f0104129 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f010410d:	52                   	push   %edx
f010410e:	8d 83 fd a8 f7 ff    	lea    -0x85703(%ebx),%eax
f0104114:	50                   	push   %eax
f0104115:	56                   	push   %esi
f0104116:	ff 75 08             	pushl  0x8(%ebp)
f0104119:	e8 a4 fe ff ff       	call   f0103fc2 <printfmt>
f010411e:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104121:	89 7d 14             	mov    %edi,0x14(%ebp)
f0104124:	e9 95 02 00 00       	jmp    f01043be <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0104129:	50                   	push   %eax
f010412a:	8d 83 e9 af f7 ff    	lea    -0x85017(%ebx),%eax
f0104130:	50                   	push   %eax
f0104131:	56                   	push   %esi
f0104132:	ff 75 08             	pushl  0x8(%ebp)
f0104135:	e8 88 fe ff ff       	call   f0103fc2 <printfmt>
f010413a:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010413d:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0104140:	e9 79 02 00 00       	jmp    f01043be <.L35+0x45>

f0104145 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0104145:	8b 45 14             	mov    0x14(%ebp),%eax
f0104148:	83 c0 04             	add    $0x4,%eax
f010414b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010414e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104151:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104153:	85 ff                	test   %edi,%edi
f0104155:	8d 83 e2 af f7 ff    	lea    -0x8501e(%ebx),%eax
f010415b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010415e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104162:	0f 8e b5 00 00 00    	jle    f010421d <.L36+0xd8>
f0104168:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010416c:	75 08                	jne    f0104176 <.L36+0x31>
f010416e:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104171:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104174:	eb 6d                	jmp    f01041e3 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104176:	83 ec 08             	sub    $0x8,%esp
f0104179:	ff 75 cc             	pushl  -0x34(%ebp)
f010417c:	57                   	push   %edi
f010417d:	e8 7e 04 00 00       	call   f0104600 <strnlen>
f0104182:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104185:	29 c2                	sub    %eax,%edx
f0104187:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010418a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010418d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104191:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104194:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104197:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104199:	eb 10                	jmp    f01041ab <.L36+0x66>
					putch(padc, putdat);
f010419b:	83 ec 08             	sub    $0x8,%esp
f010419e:	56                   	push   %esi
f010419f:	ff 75 e0             	pushl  -0x20(%ebp)
f01041a2:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01041a5:	83 ef 01             	sub    $0x1,%edi
f01041a8:	83 c4 10             	add    $0x10,%esp
f01041ab:	85 ff                	test   %edi,%edi
f01041ad:	7f ec                	jg     f010419b <.L36+0x56>
f01041af:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01041b2:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01041b5:	85 d2                	test   %edx,%edx
f01041b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01041bc:	0f 49 c2             	cmovns %edx,%eax
f01041bf:	29 c2                	sub    %eax,%edx
f01041c1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01041c4:	89 75 0c             	mov    %esi,0xc(%ebp)
f01041c7:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01041ca:	eb 17                	jmp    f01041e3 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01041cc:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01041d0:	75 30                	jne    f0104202 <.L36+0xbd>
					putch(ch, putdat);
f01041d2:	83 ec 08             	sub    $0x8,%esp
f01041d5:	ff 75 0c             	pushl  0xc(%ebp)
f01041d8:	50                   	push   %eax
f01041d9:	ff 55 08             	call   *0x8(%ebp)
f01041dc:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01041df:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01041e3:	83 c7 01             	add    $0x1,%edi
f01041e6:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01041ea:	0f be c2             	movsbl %dl,%eax
f01041ed:	85 c0                	test   %eax,%eax
f01041ef:	74 52                	je     f0104243 <.L36+0xfe>
f01041f1:	85 f6                	test   %esi,%esi
f01041f3:	78 d7                	js     f01041cc <.L36+0x87>
f01041f5:	83 ee 01             	sub    $0x1,%esi
f01041f8:	79 d2                	jns    f01041cc <.L36+0x87>
f01041fa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041fd:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104200:	eb 32                	jmp    f0104234 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0104202:	0f be d2             	movsbl %dl,%edx
f0104205:	83 ea 20             	sub    $0x20,%edx
f0104208:	83 fa 5e             	cmp    $0x5e,%edx
f010420b:	76 c5                	jbe    f01041d2 <.L36+0x8d>
					putch('?', putdat);
f010420d:	83 ec 08             	sub    $0x8,%esp
f0104210:	ff 75 0c             	pushl  0xc(%ebp)
f0104213:	6a 3f                	push   $0x3f
f0104215:	ff 55 08             	call   *0x8(%ebp)
f0104218:	83 c4 10             	add    $0x10,%esp
f010421b:	eb c2                	jmp    f01041df <.L36+0x9a>
f010421d:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104220:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104223:	eb be                	jmp    f01041e3 <.L36+0x9e>
				putch(' ', putdat);
f0104225:	83 ec 08             	sub    $0x8,%esp
f0104228:	56                   	push   %esi
f0104229:	6a 20                	push   $0x20
f010422b:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010422e:	83 ef 01             	sub    $0x1,%edi
f0104231:	83 c4 10             	add    $0x10,%esp
f0104234:	85 ff                	test   %edi,%edi
f0104236:	7f ed                	jg     f0104225 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0104238:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010423b:	89 45 14             	mov    %eax,0x14(%ebp)
f010423e:	e9 7b 01 00 00       	jmp    f01043be <.L35+0x45>
f0104243:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104246:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104249:	eb e9                	jmp    f0104234 <.L36+0xef>

f010424b <.L31>:
f010424b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010424e:	83 f9 01             	cmp    $0x1,%ecx
f0104251:	7e 40                	jle    f0104293 <.L31+0x48>
		return va_arg(*ap, long long);
f0104253:	8b 45 14             	mov    0x14(%ebp),%eax
f0104256:	8b 50 04             	mov    0x4(%eax),%edx
f0104259:	8b 00                	mov    (%eax),%eax
f010425b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010425e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104261:	8b 45 14             	mov    0x14(%ebp),%eax
f0104264:	8d 40 08             	lea    0x8(%eax),%eax
f0104267:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010426a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010426e:	79 55                	jns    f01042c5 <.L31+0x7a>
				putch('-', putdat);
f0104270:	83 ec 08             	sub    $0x8,%esp
f0104273:	56                   	push   %esi
f0104274:	6a 2d                	push   $0x2d
f0104276:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104279:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010427c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010427f:	f7 da                	neg    %edx
f0104281:	83 d1 00             	adc    $0x0,%ecx
f0104284:	f7 d9                	neg    %ecx
f0104286:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104289:	b8 0a 00 00 00       	mov    $0xa,%eax
f010428e:	e9 10 01 00 00       	jmp    f01043a3 <.L35+0x2a>
	else if (lflag)
f0104293:	85 c9                	test   %ecx,%ecx
f0104295:	75 17                	jne    f01042ae <.L31+0x63>
		return va_arg(*ap, int);
f0104297:	8b 45 14             	mov    0x14(%ebp),%eax
f010429a:	8b 00                	mov    (%eax),%eax
f010429c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010429f:	99                   	cltd   
f01042a0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01042a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01042a6:	8d 40 04             	lea    0x4(%eax),%eax
f01042a9:	89 45 14             	mov    %eax,0x14(%ebp)
f01042ac:	eb bc                	jmp    f010426a <.L31+0x1f>
		return va_arg(*ap, long);
f01042ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01042b1:	8b 00                	mov    (%eax),%eax
f01042b3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01042b6:	99                   	cltd   
f01042b7:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01042ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01042bd:	8d 40 04             	lea    0x4(%eax),%eax
f01042c0:	89 45 14             	mov    %eax,0x14(%ebp)
f01042c3:	eb a5                	jmp    f010426a <.L31+0x1f>
			num = getint(&ap, lflag);
f01042c5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01042c8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01042cb:	b8 0a 00 00 00       	mov    $0xa,%eax
f01042d0:	e9 ce 00 00 00       	jmp    f01043a3 <.L35+0x2a>

f01042d5 <.L37>:
f01042d5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01042d8:	83 f9 01             	cmp    $0x1,%ecx
f01042db:	7e 18                	jle    f01042f5 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f01042dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01042e0:	8b 10                	mov    (%eax),%edx
f01042e2:	8b 48 04             	mov    0x4(%eax),%ecx
f01042e5:	8d 40 08             	lea    0x8(%eax),%eax
f01042e8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01042eb:	b8 0a 00 00 00       	mov    $0xa,%eax
f01042f0:	e9 ae 00 00 00       	jmp    f01043a3 <.L35+0x2a>
	else if (lflag)
f01042f5:	85 c9                	test   %ecx,%ecx
f01042f7:	75 1a                	jne    f0104313 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f01042f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01042fc:	8b 10                	mov    (%eax),%edx
f01042fe:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104303:	8d 40 04             	lea    0x4(%eax),%eax
f0104306:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104309:	b8 0a 00 00 00       	mov    $0xa,%eax
f010430e:	e9 90 00 00 00       	jmp    f01043a3 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104313:	8b 45 14             	mov    0x14(%ebp),%eax
f0104316:	8b 10                	mov    (%eax),%edx
f0104318:	b9 00 00 00 00       	mov    $0x0,%ecx
f010431d:	8d 40 04             	lea    0x4(%eax),%eax
f0104320:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104323:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104328:	eb 79                	jmp    f01043a3 <.L35+0x2a>

f010432a <.L34>:
f010432a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010432d:	83 f9 01             	cmp    $0x1,%ecx
f0104330:	7e 15                	jle    f0104347 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f0104332:	8b 45 14             	mov    0x14(%ebp),%eax
f0104335:	8b 10                	mov    (%eax),%edx
f0104337:	8b 48 04             	mov    0x4(%eax),%ecx
f010433a:	8d 40 08             	lea    0x8(%eax),%eax
f010433d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104340:	b8 08 00 00 00       	mov    $0x8,%eax
f0104345:	eb 5c                	jmp    f01043a3 <.L35+0x2a>
	else if (lflag)
f0104347:	85 c9                	test   %ecx,%ecx
f0104349:	75 17                	jne    f0104362 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f010434b:	8b 45 14             	mov    0x14(%ebp),%eax
f010434e:	8b 10                	mov    (%eax),%edx
f0104350:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104355:	8d 40 04             	lea    0x4(%eax),%eax
f0104358:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010435b:	b8 08 00 00 00       	mov    $0x8,%eax
f0104360:	eb 41                	jmp    f01043a3 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104362:	8b 45 14             	mov    0x14(%ebp),%eax
f0104365:	8b 10                	mov    (%eax),%edx
f0104367:	b9 00 00 00 00       	mov    $0x0,%ecx
f010436c:	8d 40 04             	lea    0x4(%eax),%eax
f010436f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104372:	b8 08 00 00 00       	mov    $0x8,%eax
f0104377:	eb 2a                	jmp    f01043a3 <.L35+0x2a>

f0104379 <.L35>:
			putch('0', putdat);
f0104379:	83 ec 08             	sub    $0x8,%esp
f010437c:	56                   	push   %esi
f010437d:	6a 30                	push   $0x30
f010437f:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104382:	83 c4 08             	add    $0x8,%esp
f0104385:	56                   	push   %esi
f0104386:	6a 78                	push   $0x78
f0104388:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010438b:	8b 45 14             	mov    0x14(%ebp),%eax
f010438e:	8b 10                	mov    (%eax),%edx
f0104390:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0104395:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104398:	8d 40 04             	lea    0x4(%eax),%eax
f010439b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010439e:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01043a3:	83 ec 0c             	sub    $0xc,%esp
f01043a6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01043aa:	57                   	push   %edi
f01043ab:	ff 75 e0             	pushl  -0x20(%ebp)
f01043ae:	50                   	push   %eax
f01043af:	51                   	push   %ecx
f01043b0:	52                   	push   %edx
f01043b1:	89 f2                	mov    %esi,%edx
f01043b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01043b6:	e8 20 fb ff ff       	call   f0103edb <printnum>
			break;
f01043bb:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01043be:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01043c1:	83 c7 01             	add    $0x1,%edi
f01043c4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01043c8:	83 f8 25             	cmp    $0x25,%eax
f01043cb:	0f 84 2d fc ff ff    	je     f0103ffe <vprintfmt+0x1f>
			if (ch == '\0')
f01043d1:	85 c0                	test   %eax,%eax
f01043d3:	0f 84 91 00 00 00    	je     f010446a <.L22+0x21>
			putch(ch, putdat);
f01043d9:	83 ec 08             	sub    $0x8,%esp
f01043dc:	56                   	push   %esi
f01043dd:	50                   	push   %eax
f01043de:	ff 55 08             	call   *0x8(%ebp)
f01043e1:	83 c4 10             	add    $0x10,%esp
f01043e4:	eb db                	jmp    f01043c1 <.L35+0x48>

f01043e6 <.L38>:
f01043e6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01043e9:	83 f9 01             	cmp    $0x1,%ecx
f01043ec:	7e 15                	jle    f0104403 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01043ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01043f1:	8b 10                	mov    (%eax),%edx
f01043f3:	8b 48 04             	mov    0x4(%eax),%ecx
f01043f6:	8d 40 08             	lea    0x8(%eax),%eax
f01043f9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01043fc:	b8 10 00 00 00       	mov    $0x10,%eax
f0104401:	eb a0                	jmp    f01043a3 <.L35+0x2a>
	else if (lflag)
f0104403:	85 c9                	test   %ecx,%ecx
f0104405:	75 17                	jne    f010441e <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0104407:	8b 45 14             	mov    0x14(%ebp),%eax
f010440a:	8b 10                	mov    (%eax),%edx
f010440c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104411:	8d 40 04             	lea    0x4(%eax),%eax
f0104414:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104417:	b8 10 00 00 00       	mov    $0x10,%eax
f010441c:	eb 85                	jmp    f01043a3 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010441e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104421:	8b 10                	mov    (%eax),%edx
f0104423:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104428:	8d 40 04             	lea    0x4(%eax),%eax
f010442b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010442e:	b8 10 00 00 00       	mov    $0x10,%eax
f0104433:	e9 6b ff ff ff       	jmp    f01043a3 <.L35+0x2a>

f0104438 <.L25>:
			putch(ch, putdat);
f0104438:	83 ec 08             	sub    $0x8,%esp
f010443b:	56                   	push   %esi
f010443c:	6a 25                	push   $0x25
f010443e:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104441:	83 c4 10             	add    $0x10,%esp
f0104444:	e9 75 ff ff ff       	jmp    f01043be <.L35+0x45>

f0104449 <.L22>:
			putch('%', putdat);
f0104449:	83 ec 08             	sub    $0x8,%esp
f010444c:	56                   	push   %esi
f010444d:	6a 25                	push   $0x25
f010444f:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104452:	83 c4 10             	add    $0x10,%esp
f0104455:	89 f8                	mov    %edi,%eax
f0104457:	eb 03                	jmp    f010445c <.L22+0x13>
f0104459:	83 e8 01             	sub    $0x1,%eax
f010445c:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0104460:	75 f7                	jne    f0104459 <.L22+0x10>
f0104462:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104465:	e9 54 ff ff ff       	jmp    f01043be <.L35+0x45>
}
f010446a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010446d:	5b                   	pop    %ebx
f010446e:	5e                   	pop    %esi
f010446f:	5f                   	pop    %edi
f0104470:	5d                   	pop    %ebp
f0104471:	c3                   	ret    

f0104472 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104472:	55                   	push   %ebp
f0104473:	89 e5                	mov    %esp,%ebp
f0104475:	53                   	push   %ebx
f0104476:	83 ec 14             	sub    $0x14,%esp
f0104479:	e8 e9 bc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010447e:	81 c3 a2 6b 08 00    	add    $0x86ba2,%ebx
f0104484:	8b 45 08             	mov    0x8(%ebp),%eax
f0104487:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010448a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010448d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104491:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104494:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010449b:	85 c0                	test   %eax,%eax
f010449d:	74 2b                	je     f01044ca <vsnprintf+0x58>
f010449f:	85 d2                	test   %edx,%edx
f01044a1:	7e 27                	jle    f01044ca <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01044a3:	ff 75 14             	pushl  0x14(%ebp)
f01044a6:	ff 75 10             	pushl  0x10(%ebp)
f01044a9:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01044ac:	50                   	push   %eax
f01044ad:	8d 83 85 8f f7 ff    	lea    -0x8707b(%ebx),%eax
f01044b3:	50                   	push   %eax
f01044b4:	e8 26 fb ff ff       	call   f0103fdf <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01044b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01044bc:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01044bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01044c2:	83 c4 10             	add    $0x10,%esp
}
f01044c5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01044c8:	c9                   	leave  
f01044c9:	c3                   	ret    
		return -E_INVAL;
f01044ca:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01044cf:	eb f4                	jmp    f01044c5 <vsnprintf+0x53>

f01044d1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01044d1:	55                   	push   %ebp
f01044d2:	89 e5                	mov    %esp,%ebp
f01044d4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01044d7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01044da:	50                   	push   %eax
f01044db:	ff 75 10             	pushl  0x10(%ebp)
f01044de:	ff 75 0c             	pushl  0xc(%ebp)
f01044e1:	ff 75 08             	pushl  0x8(%ebp)
f01044e4:	e8 89 ff ff ff       	call   f0104472 <vsnprintf>
	va_end(ap);

	return rc;
}
f01044e9:	c9                   	leave  
f01044ea:	c3                   	ret    

f01044eb <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01044eb:	55                   	push   %ebp
f01044ec:	89 e5                	mov    %esp,%ebp
f01044ee:	57                   	push   %edi
f01044ef:	56                   	push   %esi
f01044f0:	53                   	push   %ebx
f01044f1:	83 ec 1c             	sub    $0x1c,%esp
f01044f4:	e8 6e bc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01044f9:	81 c3 27 6b 08 00    	add    $0x86b27,%ebx
f01044ff:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104502:	85 c0                	test   %eax,%eax
f0104504:	74 13                	je     f0104519 <readline+0x2e>
		cprintf("%s", prompt);
f0104506:	83 ec 08             	sub    $0x8,%esp
f0104509:	50                   	push   %eax
f010450a:	8d 83 fd a8 f7 ff    	lea    -0x85703(%ebx),%eax
f0104510:	50                   	push   %eax
f0104511:	e8 9a f1 ff ff       	call   f01036b0 <cprintf>
f0104516:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104519:	83 ec 0c             	sub    $0xc,%esp
f010451c:	6a 00                	push   $0x0
f010451e:	e8 dc c1 ff ff       	call   f01006ff <iscons>
f0104523:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104526:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104529:	bf 00 00 00 00       	mov    $0x0,%edi
f010452e:	eb 46                	jmp    f0104576 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0104530:	83 ec 08             	sub    $0x8,%esp
f0104533:	50                   	push   %eax
f0104534:	8d 83 b4 b1 f7 ff    	lea    -0x84e4c(%ebx),%eax
f010453a:	50                   	push   %eax
f010453b:	e8 70 f1 ff ff       	call   f01036b0 <cprintf>
			return NULL;
f0104540:	83 c4 10             	add    $0x10,%esp
f0104543:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104548:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010454b:	5b                   	pop    %ebx
f010454c:	5e                   	pop    %esi
f010454d:	5f                   	pop    %edi
f010454e:	5d                   	pop    %ebp
f010454f:	c3                   	ret    
			if (echoing)
f0104550:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104554:	75 05                	jne    f010455b <readline+0x70>
			i--;
f0104556:	83 ef 01             	sub    $0x1,%edi
f0104559:	eb 1b                	jmp    f0104576 <readline+0x8b>
				cputchar('\b');
f010455b:	83 ec 0c             	sub    $0xc,%esp
f010455e:	6a 08                	push   $0x8
f0104560:	e8 79 c1 ff ff       	call   f01006de <cputchar>
f0104565:	83 c4 10             	add    $0x10,%esp
f0104568:	eb ec                	jmp    f0104556 <readline+0x6b>
			buf[i++] = c;
f010456a:	89 f0                	mov    %esi,%eax
f010456c:	88 84 3b e0 2b 00 00 	mov    %al,0x2be0(%ebx,%edi,1)
f0104573:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104576:	e8 73 c1 ff ff       	call   f01006ee <getchar>
f010457b:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010457d:	85 c0                	test   %eax,%eax
f010457f:	78 af                	js     f0104530 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104581:	83 f8 08             	cmp    $0x8,%eax
f0104584:	0f 94 c2             	sete   %dl
f0104587:	83 f8 7f             	cmp    $0x7f,%eax
f010458a:	0f 94 c0             	sete   %al
f010458d:	08 c2                	or     %al,%dl
f010458f:	74 04                	je     f0104595 <readline+0xaa>
f0104591:	85 ff                	test   %edi,%edi
f0104593:	7f bb                	jg     f0104550 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104595:	83 fe 1f             	cmp    $0x1f,%esi
f0104598:	7e 1c                	jle    f01045b6 <readline+0xcb>
f010459a:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01045a0:	7f 14                	jg     f01045b6 <readline+0xcb>
			if (echoing)
f01045a2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01045a6:	74 c2                	je     f010456a <readline+0x7f>
				cputchar(c);
f01045a8:	83 ec 0c             	sub    $0xc,%esp
f01045ab:	56                   	push   %esi
f01045ac:	e8 2d c1 ff ff       	call   f01006de <cputchar>
f01045b1:	83 c4 10             	add    $0x10,%esp
f01045b4:	eb b4                	jmp    f010456a <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01045b6:	83 fe 0a             	cmp    $0xa,%esi
f01045b9:	74 05                	je     f01045c0 <readline+0xd5>
f01045bb:	83 fe 0d             	cmp    $0xd,%esi
f01045be:	75 b6                	jne    f0104576 <readline+0x8b>
			if (echoing)
f01045c0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01045c4:	75 13                	jne    f01045d9 <readline+0xee>
			buf[i] = 0;
f01045c6:	c6 84 3b e0 2b 00 00 	movb   $0x0,0x2be0(%ebx,%edi,1)
f01045cd:	00 
			return buf;
f01045ce:	8d 83 e0 2b 00 00    	lea    0x2be0(%ebx),%eax
f01045d4:	e9 6f ff ff ff       	jmp    f0104548 <readline+0x5d>
				cputchar('\n');
f01045d9:	83 ec 0c             	sub    $0xc,%esp
f01045dc:	6a 0a                	push   $0xa
f01045de:	e8 fb c0 ff ff       	call   f01006de <cputchar>
f01045e3:	83 c4 10             	add    $0x10,%esp
f01045e6:	eb de                	jmp    f01045c6 <readline+0xdb>

f01045e8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01045e8:	55                   	push   %ebp
f01045e9:	89 e5                	mov    %esp,%ebp
f01045eb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01045ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01045f3:	eb 03                	jmp    f01045f8 <strlen+0x10>
		n++;
f01045f5:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01045f8:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01045fc:	75 f7                	jne    f01045f5 <strlen+0xd>
	return n;
}
f01045fe:	5d                   	pop    %ebp
f01045ff:	c3                   	ret    

f0104600 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104600:	55                   	push   %ebp
f0104601:	89 e5                	mov    %esp,%ebp
f0104603:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104606:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104609:	b8 00 00 00 00       	mov    $0x0,%eax
f010460e:	eb 03                	jmp    f0104613 <strnlen+0x13>
		n++;
f0104610:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104613:	39 d0                	cmp    %edx,%eax
f0104615:	74 06                	je     f010461d <strnlen+0x1d>
f0104617:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010461b:	75 f3                	jne    f0104610 <strnlen+0x10>
	return n;
}
f010461d:	5d                   	pop    %ebp
f010461e:	c3                   	ret    

f010461f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010461f:	55                   	push   %ebp
f0104620:	89 e5                	mov    %esp,%ebp
f0104622:	53                   	push   %ebx
f0104623:	8b 45 08             	mov    0x8(%ebp),%eax
f0104626:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104629:	89 c2                	mov    %eax,%edx
f010462b:	83 c1 01             	add    $0x1,%ecx
f010462e:	83 c2 01             	add    $0x1,%edx
f0104631:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104635:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104638:	84 db                	test   %bl,%bl
f010463a:	75 ef                	jne    f010462b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010463c:	5b                   	pop    %ebx
f010463d:	5d                   	pop    %ebp
f010463e:	c3                   	ret    

f010463f <strcat>:

char *
strcat(char *dst, const char *src)
{
f010463f:	55                   	push   %ebp
f0104640:	89 e5                	mov    %esp,%ebp
f0104642:	53                   	push   %ebx
f0104643:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104646:	53                   	push   %ebx
f0104647:	e8 9c ff ff ff       	call   f01045e8 <strlen>
f010464c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010464f:	ff 75 0c             	pushl  0xc(%ebp)
f0104652:	01 d8                	add    %ebx,%eax
f0104654:	50                   	push   %eax
f0104655:	e8 c5 ff ff ff       	call   f010461f <strcpy>
	return dst;
}
f010465a:	89 d8                	mov    %ebx,%eax
f010465c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010465f:	c9                   	leave  
f0104660:	c3                   	ret    

f0104661 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104661:	55                   	push   %ebp
f0104662:	89 e5                	mov    %esp,%ebp
f0104664:	56                   	push   %esi
f0104665:	53                   	push   %ebx
f0104666:	8b 75 08             	mov    0x8(%ebp),%esi
f0104669:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010466c:	89 f3                	mov    %esi,%ebx
f010466e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104671:	89 f2                	mov    %esi,%edx
f0104673:	eb 0f                	jmp    f0104684 <strncpy+0x23>
		*dst++ = *src;
f0104675:	83 c2 01             	add    $0x1,%edx
f0104678:	0f b6 01             	movzbl (%ecx),%eax
f010467b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010467e:	80 39 01             	cmpb   $0x1,(%ecx)
f0104681:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0104684:	39 da                	cmp    %ebx,%edx
f0104686:	75 ed                	jne    f0104675 <strncpy+0x14>
	}
	return ret;
}
f0104688:	89 f0                	mov    %esi,%eax
f010468a:	5b                   	pop    %ebx
f010468b:	5e                   	pop    %esi
f010468c:	5d                   	pop    %ebp
f010468d:	c3                   	ret    

f010468e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010468e:	55                   	push   %ebp
f010468f:	89 e5                	mov    %esp,%ebp
f0104691:	56                   	push   %esi
f0104692:	53                   	push   %ebx
f0104693:	8b 75 08             	mov    0x8(%ebp),%esi
f0104696:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104699:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010469c:	89 f0                	mov    %esi,%eax
f010469e:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01046a2:	85 c9                	test   %ecx,%ecx
f01046a4:	75 0b                	jne    f01046b1 <strlcpy+0x23>
f01046a6:	eb 17                	jmp    f01046bf <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01046a8:	83 c2 01             	add    $0x1,%edx
f01046ab:	83 c0 01             	add    $0x1,%eax
f01046ae:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01046b1:	39 d8                	cmp    %ebx,%eax
f01046b3:	74 07                	je     f01046bc <strlcpy+0x2e>
f01046b5:	0f b6 0a             	movzbl (%edx),%ecx
f01046b8:	84 c9                	test   %cl,%cl
f01046ba:	75 ec                	jne    f01046a8 <strlcpy+0x1a>
		*dst = '\0';
f01046bc:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01046bf:	29 f0                	sub    %esi,%eax
}
f01046c1:	5b                   	pop    %ebx
f01046c2:	5e                   	pop    %esi
f01046c3:	5d                   	pop    %ebp
f01046c4:	c3                   	ret    

f01046c5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01046c5:	55                   	push   %ebp
f01046c6:	89 e5                	mov    %esp,%ebp
f01046c8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01046cb:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01046ce:	eb 06                	jmp    f01046d6 <strcmp+0x11>
		p++, q++;
f01046d0:	83 c1 01             	add    $0x1,%ecx
f01046d3:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01046d6:	0f b6 01             	movzbl (%ecx),%eax
f01046d9:	84 c0                	test   %al,%al
f01046db:	74 04                	je     f01046e1 <strcmp+0x1c>
f01046dd:	3a 02                	cmp    (%edx),%al
f01046df:	74 ef                	je     f01046d0 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01046e1:	0f b6 c0             	movzbl %al,%eax
f01046e4:	0f b6 12             	movzbl (%edx),%edx
f01046e7:	29 d0                	sub    %edx,%eax
}
f01046e9:	5d                   	pop    %ebp
f01046ea:	c3                   	ret    

f01046eb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01046eb:	55                   	push   %ebp
f01046ec:	89 e5                	mov    %esp,%ebp
f01046ee:	53                   	push   %ebx
f01046ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01046f2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01046f5:	89 c3                	mov    %eax,%ebx
f01046f7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01046fa:	eb 06                	jmp    f0104702 <strncmp+0x17>
		n--, p++, q++;
f01046fc:	83 c0 01             	add    $0x1,%eax
f01046ff:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0104702:	39 d8                	cmp    %ebx,%eax
f0104704:	74 16                	je     f010471c <strncmp+0x31>
f0104706:	0f b6 08             	movzbl (%eax),%ecx
f0104709:	84 c9                	test   %cl,%cl
f010470b:	74 04                	je     f0104711 <strncmp+0x26>
f010470d:	3a 0a                	cmp    (%edx),%cl
f010470f:	74 eb                	je     f01046fc <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104711:	0f b6 00             	movzbl (%eax),%eax
f0104714:	0f b6 12             	movzbl (%edx),%edx
f0104717:	29 d0                	sub    %edx,%eax
}
f0104719:	5b                   	pop    %ebx
f010471a:	5d                   	pop    %ebp
f010471b:	c3                   	ret    
		return 0;
f010471c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104721:	eb f6                	jmp    f0104719 <strncmp+0x2e>

f0104723 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104723:	55                   	push   %ebp
f0104724:	89 e5                	mov    %esp,%ebp
f0104726:	8b 45 08             	mov    0x8(%ebp),%eax
f0104729:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010472d:	0f b6 10             	movzbl (%eax),%edx
f0104730:	84 d2                	test   %dl,%dl
f0104732:	74 09                	je     f010473d <strchr+0x1a>
		if (*s == c)
f0104734:	38 ca                	cmp    %cl,%dl
f0104736:	74 0a                	je     f0104742 <strchr+0x1f>
	for (; *s; s++)
f0104738:	83 c0 01             	add    $0x1,%eax
f010473b:	eb f0                	jmp    f010472d <strchr+0xa>
			return (char *) s;
	return 0;
f010473d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104742:	5d                   	pop    %ebp
f0104743:	c3                   	ret    

f0104744 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104744:	55                   	push   %ebp
f0104745:	89 e5                	mov    %esp,%ebp
f0104747:	8b 45 08             	mov    0x8(%ebp),%eax
f010474a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010474e:	eb 03                	jmp    f0104753 <strfind+0xf>
f0104750:	83 c0 01             	add    $0x1,%eax
f0104753:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104756:	38 ca                	cmp    %cl,%dl
f0104758:	74 04                	je     f010475e <strfind+0x1a>
f010475a:	84 d2                	test   %dl,%dl
f010475c:	75 f2                	jne    f0104750 <strfind+0xc>
			break;
	return (char *) s;
}
f010475e:	5d                   	pop    %ebp
f010475f:	c3                   	ret    

f0104760 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104760:	55                   	push   %ebp
f0104761:	89 e5                	mov    %esp,%ebp
f0104763:	57                   	push   %edi
f0104764:	56                   	push   %esi
f0104765:	53                   	push   %ebx
f0104766:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104769:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010476c:	85 c9                	test   %ecx,%ecx
f010476e:	74 13                	je     f0104783 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104770:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104776:	75 05                	jne    f010477d <memset+0x1d>
f0104778:	f6 c1 03             	test   $0x3,%cl
f010477b:	74 0d                	je     f010478a <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010477d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104780:	fc                   	cld    
f0104781:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104783:	89 f8                	mov    %edi,%eax
f0104785:	5b                   	pop    %ebx
f0104786:	5e                   	pop    %esi
f0104787:	5f                   	pop    %edi
f0104788:	5d                   	pop    %ebp
f0104789:	c3                   	ret    
		c &= 0xFF;
f010478a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010478e:	89 d3                	mov    %edx,%ebx
f0104790:	c1 e3 08             	shl    $0x8,%ebx
f0104793:	89 d0                	mov    %edx,%eax
f0104795:	c1 e0 18             	shl    $0x18,%eax
f0104798:	89 d6                	mov    %edx,%esi
f010479a:	c1 e6 10             	shl    $0x10,%esi
f010479d:	09 f0                	or     %esi,%eax
f010479f:	09 c2                	or     %eax,%edx
f01047a1:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01047a3:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01047a6:	89 d0                	mov    %edx,%eax
f01047a8:	fc                   	cld    
f01047a9:	f3 ab                	rep stos %eax,%es:(%edi)
f01047ab:	eb d6                	jmp    f0104783 <memset+0x23>

f01047ad <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01047ad:	55                   	push   %ebp
f01047ae:	89 e5                	mov    %esp,%ebp
f01047b0:	57                   	push   %edi
f01047b1:	56                   	push   %esi
f01047b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01047b5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01047b8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01047bb:	39 c6                	cmp    %eax,%esi
f01047bd:	73 35                	jae    f01047f4 <memmove+0x47>
f01047bf:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01047c2:	39 c2                	cmp    %eax,%edx
f01047c4:	76 2e                	jbe    f01047f4 <memmove+0x47>
		s += n;
		d += n;
f01047c6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047c9:	89 d6                	mov    %edx,%esi
f01047cb:	09 fe                	or     %edi,%esi
f01047cd:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01047d3:	74 0c                	je     f01047e1 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01047d5:	83 ef 01             	sub    $0x1,%edi
f01047d8:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01047db:	fd                   	std    
f01047dc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01047de:	fc                   	cld    
f01047df:	eb 21                	jmp    f0104802 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047e1:	f6 c1 03             	test   $0x3,%cl
f01047e4:	75 ef                	jne    f01047d5 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01047e6:	83 ef 04             	sub    $0x4,%edi
f01047e9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01047ec:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01047ef:	fd                   	std    
f01047f0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047f2:	eb ea                	jmp    f01047de <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047f4:	89 f2                	mov    %esi,%edx
f01047f6:	09 c2                	or     %eax,%edx
f01047f8:	f6 c2 03             	test   $0x3,%dl
f01047fb:	74 09                	je     f0104806 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01047fd:	89 c7                	mov    %eax,%edi
f01047ff:	fc                   	cld    
f0104800:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104802:	5e                   	pop    %esi
f0104803:	5f                   	pop    %edi
f0104804:	5d                   	pop    %ebp
f0104805:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104806:	f6 c1 03             	test   $0x3,%cl
f0104809:	75 f2                	jne    f01047fd <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010480b:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010480e:	89 c7                	mov    %eax,%edi
f0104810:	fc                   	cld    
f0104811:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104813:	eb ed                	jmp    f0104802 <memmove+0x55>

f0104815 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104815:	55                   	push   %ebp
f0104816:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104818:	ff 75 10             	pushl  0x10(%ebp)
f010481b:	ff 75 0c             	pushl  0xc(%ebp)
f010481e:	ff 75 08             	pushl  0x8(%ebp)
f0104821:	e8 87 ff ff ff       	call   f01047ad <memmove>
}
f0104826:	c9                   	leave  
f0104827:	c3                   	ret    

f0104828 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104828:	55                   	push   %ebp
f0104829:	89 e5                	mov    %esp,%ebp
f010482b:	56                   	push   %esi
f010482c:	53                   	push   %ebx
f010482d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104830:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104833:	89 c6                	mov    %eax,%esi
f0104835:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104838:	39 f0                	cmp    %esi,%eax
f010483a:	74 1c                	je     f0104858 <memcmp+0x30>
		if (*s1 != *s2)
f010483c:	0f b6 08             	movzbl (%eax),%ecx
f010483f:	0f b6 1a             	movzbl (%edx),%ebx
f0104842:	38 d9                	cmp    %bl,%cl
f0104844:	75 08                	jne    f010484e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0104846:	83 c0 01             	add    $0x1,%eax
f0104849:	83 c2 01             	add    $0x1,%edx
f010484c:	eb ea                	jmp    f0104838 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f010484e:	0f b6 c1             	movzbl %cl,%eax
f0104851:	0f b6 db             	movzbl %bl,%ebx
f0104854:	29 d8                	sub    %ebx,%eax
f0104856:	eb 05                	jmp    f010485d <memcmp+0x35>
	}

	return 0;
f0104858:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010485d:	5b                   	pop    %ebx
f010485e:	5e                   	pop    %esi
f010485f:	5d                   	pop    %ebp
f0104860:	c3                   	ret    

f0104861 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104861:	55                   	push   %ebp
f0104862:	89 e5                	mov    %esp,%ebp
f0104864:	8b 45 08             	mov    0x8(%ebp),%eax
f0104867:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010486a:	89 c2                	mov    %eax,%edx
f010486c:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010486f:	39 d0                	cmp    %edx,%eax
f0104871:	73 09                	jae    f010487c <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104873:	38 08                	cmp    %cl,(%eax)
f0104875:	74 05                	je     f010487c <memfind+0x1b>
	for (; s < ends; s++)
f0104877:	83 c0 01             	add    $0x1,%eax
f010487a:	eb f3                	jmp    f010486f <memfind+0xe>
			break;
	return (void *) s;
}
f010487c:	5d                   	pop    %ebp
f010487d:	c3                   	ret    

f010487e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010487e:	55                   	push   %ebp
f010487f:	89 e5                	mov    %esp,%ebp
f0104881:	57                   	push   %edi
f0104882:	56                   	push   %esi
f0104883:	53                   	push   %ebx
f0104884:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104887:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010488a:	eb 03                	jmp    f010488f <strtol+0x11>
		s++;
f010488c:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f010488f:	0f b6 01             	movzbl (%ecx),%eax
f0104892:	3c 20                	cmp    $0x20,%al
f0104894:	74 f6                	je     f010488c <strtol+0xe>
f0104896:	3c 09                	cmp    $0x9,%al
f0104898:	74 f2                	je     f010488c <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010489a:	3c 2b                	cmp    $0x2b,%al
f010489c:	74 2e                	je     f01048cc <strtol+0x4e>
	int neg = 0;
f010489e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01048a3:	3c 2d                	cmp    $0x2d,%al
f01048a5:	74 2f                	je     f01048d6 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01048a7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01048ad:	75 05                	jne    f01048b4 <strtol+0x36>
f01048af:	80 39 30             	cmpb   $0x30,(%ecx)
f01048b2:	74 2c                	je     f01048e0 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01048b4:	85 db                	test   %ebx,%ebx
f01048b6:	75 0a                	jne    f01048c2 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01048b8:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01048bd:	80 39 30             	cmpb   $0x30,(%ecx)
f01048c0:	74 28                	je     f01048ea <strtol+0x6c>
		base = 10;
f01048c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01048c7:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01048ca:	eb 50                	jmp    f010491c <strtol+0x9e>
		s++;
f01048cc:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01048cf:	bf 00 00 00 00       	mov    $0x0,%edi
f01048d4:	eb d1                	jmp    f01048a7 <strtol+0x29>
		s++, neg = 1;
f01048d6:	83 c1 01             	add    $0x1,%ecx
f01048d9:	bf 01 00 00 00       	mov    $0x1,%edi
f01048de:	eb c7                	jmp    f01048a7 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01048e0:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01048e4:	74 0e                	je     f01048f4 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01048e6:	85 db                	test   %ebx,%ebx
f01048e8:	75 d8                	jne    f01048c2 <strtol+0x44>
		s++, base = 8;
f01048ea:	83 c1 01             	add    $0x1,%ecx
f01048ed:	bb 08 00 00 00       	mov    $0x8,%ebx
f01048f2:	eb ce                	jmp    f01048c2 <strtol+0x44>
		s += 2, base = 16;
f01048f4:	83 c1 02             	add    $0x2,%ecx
f01048f7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01048fc:	eb c4                	jmp    f01048c2 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01048fe:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104901:	89 f3                	mov    %esi,%ebx
f0104903:	80 fb 19             	cmp    $0x19,%bl
f0104906:	77 29                	ja     f0104931 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0104908:	0f be d2             	movsbl %dl,%edx
f010490b:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010490e:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104911:	7d 30                	jge    f0104943 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0104913:	83 c1 01             	add    $0x1,%ecx
f0104916:	0f af 45 10          	imul   0x10(%ebp),%eax
f010491a:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010491c:	0f b6 11             	movzbl (%ecx),%edx
f010491f:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104922:	89 f3                	mov    %esi,%ebx
f0104924:	80 fb 09             	cmp    $0x9,%bl
f0104927:	77 d5                	ja     f01048fe <strtol+0x80>
			dig = *s - '0';
f0104929:	0f be d2             	movsbl %dl,%edx
f010492c:	83 ea 30             	sub    $0x30,%edx
f010492f:	eb dd                	jmp    f010490e <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0104931:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104934:	89 f3                	mov    %esi,%ebx
f0104936:	80 fb 19             	cmp    $0x19,%bl
f0104939:	77 08                	ja     f0104943 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010493b:	0f be d2             	movsbl %dl,%edx
f010493e:	83 ea 37             	sub    $0x37,%edx
f0104941:	eb cb                	jmp    f010490e <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0104943:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104947:	74 05                	je     f010494e <strtol+0xd0>
		*endptr = (char *) s;
f0104949:	8b 75 0c             	mov    0xc(%ebp),%esi
f010494c:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010494e:	89 c2                	mov    %eax,%edx
f0104950:	f7 da                	neg    %edx
f0104952:	85 ff                	test   %edi,%edi
f0104954:	0f 45 c2             	cmovne %edx,%eax
}
f0104957:	5b                   	pop    %ebx
f0104958:	5e                   	pop    %esi
f0104959:	5f                   	pop    %edi
f010495a:	5d                   	pop    %ebp
f010495b:	c3                   	ret    
f010495c:	66 90                	xchg   %ax,%ax
f010495e:	66 90                	xchg   %ax,%ax

f0104960 <__udivdi3>:
f0104960:	55                   	push   %ebp
f0104961:	57                   	push   %edi
f0104962:	56                   	push   %esi
f0104963:	53                   	push   %ebx
f0104964:	83 ec 1c             	sub    $0x1c,%esp
f0104967:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010496b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010496f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104973:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0104977:	85 d2                	test   %edx,%edx
f0104979:	75 35                	jne    f01049b0 <__udivdi3+0x50>
f010497b:	39 f3                	cmp    %esi,%ebx
f010497d:	0f 87 bd 00 00 00    	ja     f0104a40 <__udivdi3+0xe0>
f0104983:	85 db                	test   %ebx,%ebx
f0104985:	89 d9                	mov    %ebx,%ecx
f0104987:	75 0b                	jne    f0104994 <__udivdi3+0x34>
f0104989:	b8 01 00 00 00       	mov    $0x1,%eax
f010498e:	31 d2                	xor    %edx,%edx
f0104990:	f7 f3                	div    %ebx
f0104992:	89 c1                	mov    %eax,%ecx
f0104994:	31 d2                	xor    %edx,%edx
f0104996:	89 f0                	mov    %esi,%eax
f0104998:	f7 f1                	div    %ecx
f010499a:	89 c6                	mov    %eax,%esi
f010499c:	89 e8                	mov    %ebp,%eax
f010499e:	89 f7                	mov    %esi,%edi
f01049a0:	f7 f1                	div    %ecx
f01049a2:	89 fa                	mov    %edi,%edx
f01049a4:	83 c4 1c             	add    $0x1c,%esp
f01049a7:	5b                   	pop    %ebx
f01049a8:	5e                   	pop    %esi
f01049a9:	5f                   	pop    %edi
f01049aa:	5d                   	pop    %ebp
f01049ab:	c3                   	ret    
f01049ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01049b0:	39 f2                	cmp    %esi,%edx
f01049b2:	77 7c                	ja     f0104a30 <__udivdi3+0xd0>
f01049b4:	0f bd fa             	bsr    %edx,%edi
f01049b7:	83 f7 1f             	xor    $0x1f,%edi
f01049ba:	0f 84 98 00 00 00    	je     f0104a58 <__udivdi3+0xf8>
f01049c0:	89 f9                	mov    %edi,%ecx
f01049c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01049c7:	29 f8                	sub    %edi,%eax
f01049c9:	d3 e2                	shl    %cl,%edx
f01049cb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01049cf:	89 c1                	mov    %eax,%ecx
f01049d1:	89 da                	mov    %ebx,%edx
f01049d3:	d3 ea                	shr    %cl,%edx
f01049d5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01049d9:	09 d1                	or     %edx,%ecx
f01049db:	89 f2                	mov    %esi,%edx
f01049dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01049e1:	89 f9                	mov    %edi,%ecx
f01049e3:	d3 e3                	shl    %cl,%ebx
f01049e5:	89 c1                	mov    %eax,%ecx
f01049e7:	d3 ea                	shr    %cl,%edx
f01049e9:	89 f9                	mov    %edi,%ecx
f01049eb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01049ef:	d3 e6                	shl    %cl,%esi
f01049f1:	89 eb                	mov    %ebp,%ebx
f01049f3:	89 c1                	mov    %eax,%ecx
f01049f5:	d3 eb                	shr    %cl,%ebx
f01049f7:	09 de                	or     %ebx,%esi
f01049f9:	89 f0                	mov    %esi,%eax
f01049fb:	f7 74 24 08          	divl   0x8(%esp)
f01049ff:	89 d6                	mov    %edx,%esi
f0104a01:	89 c3                	mov    %eax,%ebx
f0104a03:	f7 64 24 0c          	mull   0xc(%esp)
f0104a07:	39 d6                	cmp    %edx,%esi
f0104a09:	72 0c                	jb     f0104a17 <__udivdi3+0xb7>
f0104a0b:	89 f9                	mov    %edi,%ecx
f0104a0d:	d3 e5                	shl    %cl,%ebp
f0104a0f:	39 c5                	cmp    %eax,%ebp
f0104a11:	73 5d                	jae    f0104a70 <__udivdi3+0x110>
f0104a13:	39 d6                	cmp    %edx,%esi
f0104a15:	75 59                	jne    f0104a70 <__udivdi3+0x110>
f0104a17:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0104a1a:	31 ff                	xor    %edi,%edi
f0104a1c:	89 fa                	mov    %edi,%edx
f0104a1e:	83 c4 1c             	add    $0x1c,%esp
f0104a21:	5b                   	pop    %ebx
f0104a22:	5e                   	pop    %esi
f0104a23:	5f                   	pop    %edi
f0104a24:	5d                   	pop    %ebp
f0104a25:	c3                   	ret    
f0104a26:	8d 76 00             	lea    0x0(%esi),%esi
f0104a29:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104a30:	31 ff                	xor    %edi,%edi
f0104a32:	31 c0                	xor    %eax,%eax
f0104a34:	89 fa                	mov    %edi,%edx
f0104a36:	83 c4 1c             	add    $0x1c,%esp
f0104a39:	5b                   	pop    %ebx
f0104a3a:	5e                   	pop    %esi
f0104a3b:	5f                   	pop    %edi
f0104a3c:	5d                   	pop    %ebp
f0104a3d:	c3                   	ret    
f0104a3e:	66 90                	xchg   %ax,%ax
f0104a40:	31 ff                	xor    %edi,%edi
f0104a42:	89 e8                	mov    %ebp,%eax
f0104a44:	89 f2                	mov    %esi,%edx
f0104a46:	f7 f3                	div    %ebx
f0104a48:	89 fa                	mov    %edi,%edx
f0104a4a:	83 c4 1c             	add    $0x1c,%esp
f0104a4d:	5b                   	pop    %ebx
f0104a4e:	5e                   	pop    %esi
f0104a4f:	5f                   	pop    %edi
f0104a50:	5d                   	pop    %ebp
f0104a51:	c3                   	ret    
f0104a52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104a58:	39 f2                	cmp    %esi,%edx
f0104a5a:	72 06                	jb     f0104a62 <__udivdi3+0x102>
f0104a5c:	31 c0                	xor    %eax,%eax
f0104a5e:	39 eb                	cmp    %ebp,%ebx
f0104a60:	77 d2                	ja     f0104a34 <__udivdi3+0xd4>
f0104a62:	b8 01 00 00 00       	mov    $0x1,%eax
f0104a67:	eb cb                	jmp    f0104a34 <__udivdi3+0xd4>
f0104a69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104a70:	89 d8                	mov    %ebx,%eax
f0104a72:	31 ff                	xor    %edi,%edi
f0104a74:	eb be                	jmp    f0104a34 <__udivdi3+0xd4>
f0104a76:	66 90                	xchg   %ax,%ax
f0104a78:	66 90                	xchg   %ax,%ax
f0104a7a:	66 90                	xchg   %ax,%ax
f0104a7c:	66 90                	xchg   %ax,%ax
f0104a7e:	66 90                	xchg   %ax,%ax

f0104a80 <__umoddi3>:
f0104a80:	55                   	push   %ebp
f0104a81:	57                   	push   %edi
f0104a82:	56                   	push   %esi
f0104a83:	53                   	push   %ebx
f0104a84:	83 ec 1c             	sub    $0x1c,%esp
f0104a87:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0104a8b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0104a8f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104a93:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104a97:	85 ed                	test   %ebp,%ebp
f0104a99:	89 f0                	mov    %esi,%eax
f0104a9b:	89 da                	mov    %ebx,%edx
f0104a9d:	75 19                	jne    f0104ab8 <__umoddi3+0x38>
f0104a9f:	39 df                	cmp    %ebx,%edi
f0104aa1:	0f 86 b1 00 00 00    	jbe    f0104b58 <__umoddi3+0xd8>
f0104aa7:	f7 f7                	div    %edi
f0104aa9:	89 d0                	mov    %edx,%eax
f0104aab:	31 d2                	xor    %edx,%edx
f0104aad:	83 c4 1c             	add    $0x1c,%esp
f0104ab0:	5b                   	pop    %ebx
f0104ab1:	5e                   	pop    %esi
f0104ab2:	5f                   	pop    %edi
f0104ab3:	5d                   	pop    %ebp
f0104ab4:	c3                   	ret    
f0104ab5:	8d 76 00             	lea    0x0(%esi),%esi
f0104ab8:	39 dd                	cmp    %ebx,%ebp
f0104aba:	77 f1                	ja     f0104aad <__umoddi3+0x2d>
f0104abc:	0f bd cd             	bsr    %ebp,%ecx
f0104abf:	83 f1 1f             	xor    $0x1f,%ecx
f0104ac2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104ac6:	0f 84 b4 00 00 00    	je     f0104b80 <__umoddi3+0x100>
f0104acc:	b8 20 00 00 00       	mov    $0x20,%eax
f0104ad1:	89 c2                	mov    %eax,%edx
f0104ad3:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104ad7:	29 c2                	sub    %eax,%edx
f0104ad9:	89 c1                	mov    %eax,%ecx
f0104adb:	89 f8                	mov    %edi,%eax
f0104add:	d3 e5                	shl    %cl,%ebp
f0104adf:	89 d1                	mov    %edx,%ecx
f0104ae1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104ae5:	d3 e8                	shr    %cl,%eax
f0104ae7:	09 c5                	or     %eax,%ebp
f0104ae9:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104aed:	89 c1                	mov    %eax,%ecx
f0104aef:	d3 e7                	shl    %cl,%edi
f0104af1:	89 d1                	mov    %edx,%ecx
f0104af3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104af7:	89 df                	mov    %ebx,%edi
f0104af9:	d3 ef                	shr    %cl,%edi
f0104afb:	89 c1                	mov    %eax,%ecx
f0104afd:	89 f0                	mov    %esi,%eax
f0104aff:	d3 e3                	shl    %cl,%ebx
f0104b01:	89 d1                	mov    %edx,%ecx
f0104b03:	89 fa                	mov    %edi,%edx
f0104b05:	d3 e8                	shr    %cl,%eax
f0104b07:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104b0c:	09 d8                	or     %ebx,%eax
f0104b0e:	f7 f5                	div    %ebp
f0104b10:	d3 e6                	shl    %cl,%esi
f0104b12:	89 d1                	mov    %edx,%ecx
f0104b14:	f7 64 24 08          	mull   0x8(%esp)
f0104b18:	39 d1                	cmp    %edx,%ecx
f0104b1a:	89 c3                	mov    %eax,%ebx
f0104b1c:	89 d7                	mov    %edx,%edi
f0104b1e:	72 06                	jb     f0104b26 <__umoddi3+0xa6>
f0104b20:	75 0e                	jne    f0104b30 <__umoddi3+0xb0>
f0104b22:	39 c6                	cmp    %eax,%esi
f0104b24:	73 0a                	jae    f0104b30 <__umoddi3+0xb0>
f0104b26:	2b 44 24 08          	sub    0x8(%esp),%eax
f0104b2a:	19 ea                	sbb    %ebp,%edx
f0104b2c:	89 d7                	mov    %edx,%edi
f0104b2e:	89 c3                	mov    %eax,%ebx
f0104b30:	89 ca                	mov    %ecx,%edx
f0104b32:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104b37:	29 de                	sub    %ebx,%esi
f0104b39:	19 fa                	sbb    %edi,%edx
f0104b3b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0104b3f:	89 d0                	mov    %edx,%eax
f0104b41:	d3 e0                	shl    %cl,%eax
f0104b43:	89 d9                	mov    %ebx,%ecx
f0104b45:	d3 ee                	shr    %cl,%esi
f0104b47:	d3 ea                	shr    %cl,%edx
f0104b49:	09 f0                	or     %esi,%eax
f0104b4b:	83 c4 1c             	add    $0x1c,%esp
f0104b4e:	5b                   	pop    %ebx
f0104b4f:	5e                   	pop    %esi
f0104b50:	5f                   	pop    %edi
f0104b51:	5d                   	pop    %ebp
f0104b52:	c3                   	ret    
f0104b53:	90                   	nop
f0104b54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104b58:	85 ff                	test   %edi,%edi
f0104b5a:	89 f9                	mov    %edi,%ecx
f0104b5c:	75 0b                	jne    f0104b69 <__umoddi3+0xe9>
f0104b5e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104b63:	31 d2                	xor    %edx,%edx
f0104b65:	f7 f7                	div    %edi
f0104b67:	89 c1                	mov    %eax,%ecx
f0104b69:	89 d8                	mov    %ebx,%eax
f0104b6b:	31 d2                	xor    %edx,%edx
f0104b6d:	f7 f1                	div    %ecx
f0104b6f:	89 f0                	mov    %esi,%eax
f0104b71:	f7 f1                	div    %ecx
f0104b73:	e9 31 ff ff ff       	jmp    f0104aa9 <__umoddi3+0x29>
f0104b78:	90                   	nop
f0104b79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104b80:	39 dd                	cmp    %ebx,%ebp
f0104b82:	72 08                	jb     f0104b8c <__umoddi3+0x10c>
f0104b84:	39 f7                	cmp    %esi,%edi
f0104b86:	0f 87 21 ff ff ff    	ja     f0104aad <__umoddi3+0x2d>
f0104b8c:	89 da                	mov    %ebx,%edx
f0104b8e:	89 f0                	mov    %esi,%eax
f0104b90:	29 f8                	sub    %edi,%eax
f0104b92:	19 ea                	sbb    %ebp,%edx
f0104b94:	e9 14 ff ff ff       	jmp    f0104aad <__umoddi3+0x2d>
