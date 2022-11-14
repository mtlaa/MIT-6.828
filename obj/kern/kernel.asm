
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
f0100064:	e8 42 47 00 00       	call   f01047ab <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 4e 05 00 00       	call   f01005bc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 e0 9b f7 ff    	lea    -0x86420(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 79 36 00 00       	call   f01036fb <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 2c 13 00 00       	call   f01013b3 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100087:	e8 0b 32 00 00       	call   f0103297 <env_init>
	trap_init();
f010008c:	e8 1d 37 00 00       	call   f01037ae <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100091:	83 c4 08             	add    $0x8,%esp
f0100094:	6a 00                	push   $0x0
f0100096:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010009c:	e8 2f 33 00 00       	call   f01033d0 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a1:	83 c4 04             	add    $0x4,%esp
f01000a4:	c7 c0 44 d3 18 f0    	mov    $0xf018d344,%eax
f01000aa:	ff 30                	pushl  (%eax)
f01000ac:	e8 99 35 00 00       	call   f010364a <env_run>

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
f01000f2:	8d 83 fb 9b f7 ff    	lea    -0x86405(%ebx),%eax
f01000f8:	50                   	push   %eax
f01000f9:	e8 fd 35 00 00       	call   f01036fb <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	56                   	push   %esi
f0100102:	57                   	push   %edi
f0100103:	e8 bc 35 00 00       	call   f01036c4 <vcprintf>
	cprintf("\n");
f0100108:	8d 83 d6 ab f7 ff    	lea    -0x8542a(%ebx),%eax
f010010e:	89 04 24             	mov    %eax,(%esp)
f0100111:	e8 e5 35 00 00       	call   f01036fb <cprintf>
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
f0100137:	8d 83 13 9c f7 ff    	lea    -0x863ed(%ebx),%eax
f010013d:	50                   	push   %eax
f010013e:	e8 b8 35 00 00       	call   f01036fb <cprintf>
	vcprintf(fmt, ap);
f0100143:	83 c4 08             	add    $0x8,%esp
f0100146:	56                   	push   %esi
f0100147:	ff 75 10             	pushl  0x10(%ebp)
f010014a:	e8 75 35 00 00       	call   f01036c4 <vcprintf>
	cprintf("\n");
f010014f:	8d 83 d6 ab f7 ff    	lea    -0x8542a(%ebx),%eax
f0100155:	89 04 24             	mov    %eax,(%esp)
f0100158:	e8 9e 35 00 00       	call   f01036fb <cprintf>
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
f010022f:	0f b6 84 13 60 9d f7 	movzbl -0x862a0(%ebx,%edx,1),%eax
f0100236:	ff 
f0100237:	0b 83 e0 20 00 00    	or     0x20e0(%ebx),%eax
	shift ^= togglecode[data];
f010023d:	0f b6 8c 13 60 9c f7 	movzbl -0x863a0(%ebx,%edx,1),%ecx
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
f0100282:	8d 83 2d 9c f7 ff    	lea    -0x863d3(%ebx),%eax
f0100288:	50                   	push   %eax
f0100289:	e8 6d 34 00 00       	call   f01036fb <cprintf>
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
f01002c9:	0f b6 84 13 60 9d f7 	movzbl -0x862a0(%ebx,%edx,1),%eax
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
f01004ea:	e8 09 43 00 00       	call   f01047f8 <memmove>
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
f01006cd:	8d 83 39 9c f7 ff    	lea    -0x863c7(%ebx),%eax
f01006d3:	50                   	push   %eax
f01006d4:	e8 22 30 00 00       	call   f01036fb <cprintf>
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
f0100720:	8d 83 60 9e f7 ff    	lea    -0x861a0(%ebx),%eax
f0100726:	50                   	push   %eax
f0100727:	8d 83 7e 9e f7 ff    	lea    -0x86182(%ebx),%eax
f010072d:	50                   	push   %eax
f010072e:	8d b3 83 9e f7 ff    	lea    -0x8617d(%ebx),%esi
f0100734:	56                   	push   %esi
f0100735:	e8 c1 2f 00 00       	call   f01036fb <cprintf>
f010073a:	83 c4 0c             	add    $0xc,%esp
f010073d:	8d 83 50 9f f7 ff    	lea    -0x860b0(%ebx),%eax
f0100743:	50                   	push   %eax
f0100744:	8d 83 8c 9e f7 ff    	lea    -0x86174(%ebx),%eax
f010074a:	50                   	push   %eax
f010074b:	56                   	push   %esi
f010074c:	e8 aa 2f 00 00       	call   f01036fb <cprintf>
f0100751:	83 c4 0c             	add    $0xc,%esp
f0100754:	8d 83 78 9f f7 ff    	lea    -0x86088(%ebx),%eax
f010075a:	50                   	push   %eax
f010075b:	8d 83 95 9e f7 ff    	lea    -0x8616b(%ebx),%eax
f0100761:	50                   	push   %eax
f0100762:	56                   	push   %esi
f0100763:	e8 93 2f 00 00       	call   f01036fb <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	8d 83 9c 9f f7 ff    	lea    -0x86064(%ebx),%eax
f0100771:	50                   	push   %eax
f0100772:	8d 83 9f 9e f7 ff    	lea    -0x86161(%ebx),%eax
f0100778:	50                   	push   %eax
f0100779:	56                   	push   %esi
f010077a:	e8 7c 2f 00 00       	call   f01036fb <cprintf>
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
f010079f:	8d 83 ac 9e f7 ff    	lea    -0x86154(%ebx),%eax
f01007a5:	50                   	push   %eax
f01007a6:	e8 50 2f 00 00       	call   f01036fb <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ab:	83 c4 08             	add    $0x8,%esp
f01007ae:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f01007b4:	8d 83 e8 9f f7 ff    	lea    -0x86018(%ebx),%eax
f01007ba:	50                   	push   %eax
f01007bb:	e8 3b 2f 00 00       	call   f01036fb <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007c9:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007cf:	50                   	push   %eax
f01007d0:	57                   	push   %edi
f01007d1:	8d 83 10 a0 f7 ff    	lea    -0x85ff0(%ebx),%eax
f01007d7:	50                   	push   %eax
f01007d8:	e8 1e 2f 00 00       	call   f01036fb <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007dd:	83 c4 0c             	add    $0xc,%esp
f01007e0:	c7 c0 e9 4b 10 f0    	mov    $0xf0104be9,%eax
f01007e6:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007ec:	52                   	push   %edx
f01007ed:	50                   	push   %eax
f01007ee:	8d 83 34 a0 f7 ff    	lea    -0x85fcc(%ebx),%eax
f01007f4:	50                   	push   %eax
f01007f5:	e8 01 2f 00 00       	call   f01036fb <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007fa:	83 c4 0c             	add    $0xc,%esp
f01007fd:	c7 c0 00 d1 18 f0    	mov    $0xf018d100,%eax
f0100803:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100809:	52                   	push   %edx
f010080a:	50                   	push   %eax
f010080b:	8d 83 58 a0 f7 ff    	lea    -0x85fa8(%ebx),%eax
f0100811:	50                   	push   %eax
f0100812:	e8 e4 2e 00 00       	call   f01036fb <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	c7 c6 00 e0 18 f0    	mov    $0xf018e000,%esi
f0100820:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100826:	50                   	push   %eax
f0100827:	56                   	push   %esi
f0100828:	8d 83 7c a0 f7 ff    	lea    -0x85f84(%ebx),%eax
f010082e:	50                   	push   %eax
f010082f:	e8 c7 2e 00 00       	call   f01036fb <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100834:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100837:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010083d:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010083f:	c1 fe 0a             	sar    $0xa,%esi
f0100842:	56                   	push   %esi
f0100843:	8d 83 a0 a0 f7 ff    	lea    -0x85f60(%ebx),%eax
f0100849:	50                   	push   %eax
f010084a:	e8 ac 2e 00 00       	call   f01036fb <cprintf>
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
f010086e:	8d 83 cc a0 f7 ff    	lea    -0x85f34(%ebx),%eax
f0100874:	50                   	push   %eax
f0100875:	e8 81 2e 00 00       	call   f01036fb <cprintf>
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
f0100898:	8d 83 c5 9e f7 ff    	lea    -0x8613b(%ebx),%eax
f010089e:	50                   	push   %eax
f010089f:	e8 57 2e 00 00       	call   f01036fb <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a4:	89 ef                	mov    %ebp,%edi
	while(this_ebp!=0){
f01008a6:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
f01008a9:	8d 83 d7 9e f7 ff    	lea    -0x86129(%ebx),%eax
f01008af:	89 45 b8             	mov    %eax,-0x48(%ebp)
			cprintf(" %08x", *(this_ebp + 2 + i));
f01008b2:	8d 83 f2 9e f7 ff    	lea    -0x8610e(%ebx),%eax
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
f01008d3:	e8 23 2e 00 00       	call   f01036fb <cprintf>
f01008d8:	8d 77 08             	lea    0x8(%edi),%esi
f01008db:	83 c7 1c             	add    $0x1c,%edi
f01008de:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f01008e1:	83 ec 08             	sub    $0x8,%esp
f01008e4:	ff 36                	pushl  (%esi)
f01008e6:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008e9:	e8 0d 2e 00 00       	call   f01036fb <cprintf>
f01008ee:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f01008f1:	83 c4 10             	add    $0x10,%esp
f01008f4:	39 fe                	cmp    %edi,%esi
f01008f6:	75 e9                	jne    f01008e1 <mon_backtrace+0x5d>
		cprintf("\n");
f01008f8:	83 ec 0c             	sub    $0xc,%esp
f01008fb:	8d 83 d6 ab f7 ff    	lea    -0x8542a(%ebx),%eax
f0100901:	50                   	push   %eax
f0100902:	e8 f4 2d 00 00       	call   f01036fb <cprintf>
		debuginfo_eip(eip, &info);
f0100907:	83 c4 08             	add    $0x8,%esp
f010090a:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010090d:	50                   	push   %eax
f010090e:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100911:	57                   	push   %edi
f0100912:	e8 8a 33 00 00       	call   f0103ca1 <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f0100917:	83 c4 0c             	add    $0xc,%esp
f010091a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010091d:	ff 75 d0             	pushl  -0x30(%ebp)
f0100920:	8d 83 f8 9e f7 ff    	lea    -0x86108(%ebx),%eax
f0100926:	50                   	push   %eax
f0100927:	e8 cf 2d 00 00       	call   f01036fb <cprintf>
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f010092c:	89 f8                	mov    %edi,%eax
f010092e:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100931:	50                   	push   %eax
f0100932:	ff 75 d8             	pushl  -0x28(%ebp)
f0100935:	ff 75 dc             	pushl  -0x24(%ebp)
f0100938:	8d 83 08 9f f7 ff    	lea    -0x860f8(%ebx),%eax
f010093e:	50                   	push   %eax
f010093f:	e8 b7 2d 00 00       	call   f01036fb <cprintf>
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
f0100973:	8d 83 ec a0 f7 ff    	lea    -0x85f14(%ebx),%eax
f0100979:	50                   	push   %eax
f010097a:	e8 7c 2d 00 00       	call   f01036fb <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010097f:	8d 83 10 a1 f7 ff    	lea    -0x85ef0(%ebx),%eax
f0100985:	89 04 24             	mov    %eax,(%esp)
f0100988:	e8 6e 2d 00 00       	call   f01036fb <cprintf>

	if (tf != NULL)
f010098d:	83 c4 10             	add    $0x10,%esp
f0100990:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100994:	74 0e                	je     f01009a4 <monitor+0x45>
		print_trapframe(tf);
f0100996:	83 ec 0c             	sub    $0xc,%esp
f0100999:	ff 75 08             	pushl  0x8(%ebp)
f010099c:	e8 c3 2e 00 00       	call   f0103864 <print_trapframe>
f01009a1:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01009a4:	8d bb 15 9f f7 ff    	lea    -0x860eb(%ebx),%edi
f01009aa:	eb 4a                	jmp    f01009f6 <monitor+0x97>
f01009ac:	83 ec 08             	sub    $0x8,%esp
f01009af:	0f be c0             	movsbl %al,%eax
f01009b2:	50                   	push   %eax
f01009b3:	57                   	push   %edi
f01009b4:	e8 b5 3d 00 00       	call   f010476e <strchr>
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
f01009e7:	8d 83 1a 9f f7 ff    	lea    -0x860e6(%ebx),%eax
f01009ed:	50                   	push   %eax
f01009ee:	e8 08 2d 00 00       	call   f01036fb <cprintf>
f01009f3:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009f6:	8d 83 11 9f f7 ff    	lea    -0x860ef(%ebx),%eax
f01009fc:	89 c6                	mov    %eax,%esi
f01009fe:	83 ec 0c             	sub    $0xc,%esp
f0100a01:	56                   	push   %esi
f0100a02:	e8 2f 3b 00 00       	call   f0104536 <readline>
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
f0100a32:	e8 37 3d 00 00       	call   f010476e <strchr>
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
f0100a70:	e8 9b 3c 00 00       	call   f0104710 <strcmp>
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
f0100a90:	8d 83 37 9f f7 ff    	lea    -0x860c9(%ebx),%eax
f0100a96:	50                   	push   %eax
f0100a97:	e8 5f 2c 00 00       	call   f01036fb <cprintf>
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
f0100ad6:	e8 e5 26 00 00       	call   f01031c0 <__x86.get_pc_thunk.dx>
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
f0100b43:	e8 2c 2b 00 00       	call   f0103674 <mc146818_read>
f0100b48:	89 c6                	mov    %eax,%esi
f0100b4a:	83 c7 01             	add    $0x1,%edi
f0100b4d:	89 3c 24             	mov    %edi,(%esp)
f0100b50:	e8 1f 2b 00 00       	call   f0103674 <mc146818_read>
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
f0100b67:	e8 58 26 00 00       	call   f01031c4 <__x86.get_pc_thunk.cx>
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
f0100bbe:	8d 81 38 a1 f7 ff    	lea    -0x85ec8(%ecx),%eax
f0100bc4:	50                   	push   %eax
f0100bc5:	68 39 03 00 00       	push   $0x339
f0100bca:	8d 81 25 a9 f7 ff    	lea    -0x856db(%ecx),%eax
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
f0100be8:	e8 df 25 00 00       	call   f01031cc <__x86.get_pc_thunk.di>
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
f0100c1c:	8d 83 5c a1 f7 ff    	lea    -0x85ea4(%ebx),%eax
f0100c22:	50                   	push   %eax
f0100c23:	68 75 02 00 00       	push   $0x275
f0100c28:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100c2e:	50                   	push   %eax
f0100c2f:	e8 7d f4 ff ff       	call   f01000b1 <_panic>
f0100c34:	50                   	push   %eax
f0100c35:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c38:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f0100c3e:	50                   	push   %eax
f0100c3f:	6a 5d                	push   $0x5d
f0100c41:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
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
f0100c89:	e8 1d 3b 00 00       	call   f01047ab <memset>
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
f0100cd2:	8d 83 3f a9 f7 ff    	lea    -0x856c1(%ebx),%eax
f0100cd8:	50                   	push   %eax
f0100cd9:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100cdf:	50                   	push   %eax
f0100ce0:	68 8f 02 00 00       	push   $0x28f
f0100ce5:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100ceb:	50                   	push   %eax
f0100cec:	e8 c0 f3 ff ff       	call   f01000b1 <_panic>
		assert(pp < pages + npages);
f0100cf1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cf4:	8d 83 60 a9 f7 ff    	lea    -0x856a0(%ebx),%eax
f0100cfa:	50                   	push   %eax
f0100cfb:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100d01:	50                   	push   %eax
f0100d02:	68 90 02 00 00       	push   $0x290
f0100d07:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100d0d:	50                   	push   %eax
f0100d0e:	e8 9e f3 ff ff       	call   f01000b1 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d13:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d16:	8d 83 80 a1 f7 ff    	lea    -0x85e80(%ebx),%eax
f0100d1c:	50                   	push   %eax
f0100d1d:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100d23:	50                   	push   %eax
f0100d24:	68 91 02 00 00       	push   $0x291
f0100d29:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100d2f:	50                   	push   %eax
f0100d30:	e8 7c f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != 0);
f0100d35:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d38:	8d 83 74 a9 f7 ff    	lea    -0x8568c(%ebx),%eax
f0100d3e:	50                   	push   %eax
f0100d3f:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100d45:	50                   	push   %eax
f0100d46:	68 94 02 00 00       	push   $0x294
f0100d4b:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100d51:	50                   	push   %eax
f0100d52:	e8 5a f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d57:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d5a:	8d 83 85 a9 f7 ff    	lea    -0x8567b(%ebx),%eax
f0100d60:	50                   	push   %eax
f0100d61:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100d67:	50                   	push   %eax
f0100d68:	68 95 02 00 00       	push   $0x295
f0100d6d:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100d73:	50                   	push   %eax
f0100d74:	e8 38 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d79:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d7c:	8d 83 b4 a1 f7 ff    	lea    -0x85e4c(%ebx),%eax
f0100d82:	50                   	push   %eax
f0100d83:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100d89:	50                   	push   %eax
f0100d8a:	68 96 02 00 00       	push   $0x296
f0100d8f:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100d95:	50                   	push   %eax
f0100d96:	e8 16 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d9b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d9e:	8d 83 9e a9 f7 ff    	lea    -0x85662(%ebx),%eax
f0100da4:	50                   	push   %eax
f0100da5:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100dab:	50                   	push   %eax
f0100dac:	68 97 02 00 00       	push   $0x297
f0100db1:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
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
f0100e3b:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f0100e41:	50                   	push   %eax
f0100e42:	6a 5d                	push   $0x5d
f0100e44:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f0100e4a:	50                   	push   %eax
f0100e4b:	e8 61 f2 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e50:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e53:	8d 83 d8 a1 f7 ff    	lea    -0x85e28(%ebx),%eax
f0100e59:	50                   	push   %eax
f0100e5a:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100e60:	50                   	push   %eax
f0100e61:	68 98 02 00 00       	push   $0x298
f0100e66:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
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
f0100e83:	8d 83 20 a2 f7 ff    	lea    -0x85de0(%ebx),%eax
f0100e89:	50                   	push   %eax
f0100e8a:	e8 6c 28 00 00       	call   f01036fb <cprintf>
}
f0100e8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e92:	5b                   	pop    %ebx
f0100e93:	5e                   	pop    %esi
f0100e94:	5f                   	pop    %edi
f0100e95:	5d                   	pop    %ebp
f0100e96:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e97:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e9a:	8d 83 b8 a9 f7 ff    	lea    -0x85648(%ebx),%eax
f0100ea0:	50                   	push   %eax
f0100ea1:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100ea7:	50                   	push   %eax
f0100ea8:	68 a0 02 00 00       	push   $0x2a0
f0100ead:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0100eb3:	50                   	push   %eax
f0100eb4:	e8 f8 f1 ff ff       	call   f01000b1 <_panic>
	assert(nfree_extmem > 0);
f0100eb9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ebc:	8d 83 ca a9 f7 ff    	lea    -0x85636(%ebx),%eax
f0100ec2:	50                   	push   %eax
f0100ec3:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0100ec9:	50                   	push   %eax
f0100eca:	68 a1 02 00 00       	push   $0x2a1
f0100ecf:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
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
f0100f6b:	e8 58 22 00 00       	call   f01031c8 <__x86.get_pc_thunk.si>
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
f0100fbb:	8d 86 44 a2 f7 ff    	lea    -0x85dbc(%esi),%eax
f0100fc1:	50                   	push   %eax
f0100fc2:	68 23 01 00 00       	push   $0x123
f0100fc7:	8d 86 25 a9 f7 ff    	lea    -0x856db(%esi),%eax
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
f01010b9:	e8 ed 36 00 00       	call   f01047ab <memset>
f01010be:	83 c4 10             	add    $0x10,%esp
f01010c1:	eb bc                	jmp    f010107f <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010c3:	50                   	push   %eax
f01010c4:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f01010ca:	50                   	push   %eax
f01010cb:	6a 5d                	push   $0x5d
f01010cd:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
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
f0101110:	8d 83 68 a2 f7 ff    	lea    -0x85d98(%ebx),%eax
f0101116:	50                   	push   %eax
f0101117:	68 5d 01 00 00       	push   $0x15d
f010111c:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
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
f01011d6:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f01011dc:	50                   	push   %eax
f01011dd:	68 9f 01 00 00       	push   $0x19f
f01011e2:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
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
f0101205:	e8 c2 1f 00 00       	call   f01031cc <__x86.get_pc_thunk.di>
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
f0101268:	8d 83 88 a2 f7 ff    	lea    -0x85d78(%ebx),%eax
f010126e:	50                   	push   %eax
f010126f:	68 b9 01 00 00       	push   $0x1b9
f0101274:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
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
f01012dc:	8d 83 ac a2 f7 ff    	lea    -0x85d54(%ebx),%eax
f01012e2:	50                   	push   %eax
f01012e3:	6a 56                	push   $0x56
f01012e5:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
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
f010133e:	e8 89 1e 00 00       	call   f01031cc <__x86.get_pc_thunk.di>
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
f0101418:	8d 87 cc a2 f7 ff    	lea    -0x85d34(%edi),%eax
f010141e:	50                   	push   %eax
f010141f:	89 fb                	mov    %edi,%ebx
f0101421:	e8 d5 22 00 00       	call   f01036fb <cprintf>
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
f0101443:	e8 63 33 00 00       	call   f01047ab <memset>
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
f0101490:	e8 16 33 00 00       	call   f01047ab <memset>
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
f01014b2:	e8 f4 32 00 00       	call   f01047ab <memset>
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
f01014ec:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f01014f2:	50                   	push   %eax
f01014f3:	68 9c 00 00 00       	push   $0x9c
f01014f8:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01014fe:	50                   	push   %eax
f01014ff:	e8 ad eb ff ff       	call   f01000b1 <_panic>
		panic("'pages' is a null pointer!");
f0101504:	83 ec 04             	sub    $0x4,%esp
f0101507:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010150a:	8d 83 db a9 f7 ff    	lea    -0x85625(%ebx),%eax
f0101510:	50                   	push   %eax
f0101511:	68 b4 02 00 00       	push   $0x2b4
f0101516:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
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
f01016d6:	e8 d0 30 00 00       	call   f01047ab <memset>
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
f0101780:	8d 83 f6 a9 f7 ff    	lea    -0x8560a(%ebx),%eax
f0101786:	50                   	push   %eax
f0101787:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010178d:	50                   	push   %eax
f010178e:	68 bc 02 00 00       	push   $0x2bc
f0101793:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0101799:	50                   	push   %eax
f010179a:	e8 12 e9 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f010179f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017a2:	8d 83 0c aa f7 ff    	lea    -0x855f4(%ebx),%eax
f01017a8:	50                   	push   %eax
f01017a9:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01017af:	50                   	push   %eax
f01017b0:	68 bd 02 00 00       	push   $0x2bd
f01017b5:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01017bb:	50                   	push   %eax
f01017bc:	e8 f0 e8 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01017c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017c4:	8d 83 22 aa f7 ff    	lea    -0x855de(%ebx),%eax
f01017ca:	50                   	push   %eax
f01017cb:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01017d1:	50                   	push   %eax
f01017d2:	68 be 02 00 00       	push   $0x2be
f01017d7:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01017dd:	50                   	push   %eax
f01017de:	e8 ce e8 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01017e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017e6:	8d 83 38 aa f7 ff    	lea    -0x855c8(%ebx),%eax
f01017ec:	50                   	push   %eax
f01017ed:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01017f3:	50                   	push   %eax
f01017f4:	68 c1 02 00 00       	push   $0x2c1
f01017f9:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01017ff:	50                   	push   %eax
f0101800:	e8 ac e8 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101805:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101808:	8d 83 08 a3 f7 ff    	lea    -0x85cf8(%ebx),%eax
f010180e:	50                   	push   %eax
f010180f:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0101815:	50                   	push   %eax
f0101816:	68 c2 02 00 00       	push   $0x2c2
f010181b:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0101821:	50                   	push   %eax
f0101822:	e8 8a e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101827:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010182a:	8d 83 4a aa f7 ff    	lea    -0x855b6(%ebx),%eax
f0101830:	50                   	push   %eax
f0101831:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0101837:	50                   	push   %eax
f0101838:	68 c3 02 00 00       	push   $0x2c3
f010183d:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0101843:	50                   	push   %eax
f0101844:	e8 68 e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101849:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010184c:	8d 83 67 aa f7 ff    	lea    -0x85599(%ebx),%eax
f0101852:	50                   	push   %eax
f0101853:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0101859:	50                   	push   %eax
f010185a:	68 c4 02 00 00       	push   $0x2c4
f010185f:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0101865:	50                   	push   %eax
f0101866:	e8 46 e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010186b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010186e:	8d 83 84 aa f7 ff    	lea    -0x8557c(%ebx),%eax
f0101874:	50                   	push   %eax
f0101875:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010187b:	50                   	push   %eax
f010187c:	68 c5 02 00 00       	push   $0x2c5
f0101881:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0101887:	50                   	push   %eax
f0101888:	e8 24 e8 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010188d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101890:	8d 83 a1 aa f7 ff    	lea    -0x8555f(%ebx),%eax
f0101896:	50                   	push   %eax
f0101897:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010189d:	50                   	push   %eax
f010189e:	68 cc 02 00 00       	push   $0x2cc
f01018a3:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01018a9:	50                   	push   %eax
f01018aa:	e8 02 e8 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f01018af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018b2:	8d 83 f6 a9 f7 ff    	lea    -0x8560a(%ebx),%eax
f01018b8:	50                   	push   %eax
f01018b9:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01018bf:	50                   	push   %eax
f01018c0:	68 d3 02 00 00       	push   $0x2d3
f01018c5:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01018cb:	50                   	push   %eax
f01018cc:	e8 e0 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01018d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018d4:	8d 83 0c aa f7 ff    	lea    -0x855f4(%ebx),%eax
f01018da:	50                   	push   %eax
f01018db:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01018e1:	50                   	push   %eax
f01018e2:	68 d4 02 00 00       	push   $0x2d4
f01018e7:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01018ed:	50                   	push   %eax
f01018ee:	e8 be e7 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01018f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018f6:	8d 83 22 aa f7 ff    	lea    -0x855de(%ebx),%eax
f01018fc:	50                   	push   %eax
f01018fd:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0101903:	50                   	push   %eax
f0101904:	68 d5 02 00 00       	push   $0x2d5
f0101909:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010190f:	50                   	push   %eax
f0101910:	e8 9c e7 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0101915:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101918:	8d 83 38 aa f7 ff    	lea    -0x855c8(%ebx),%eax
f010191e:	50                   	push   %eax
f010191f:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0101925:	50                   	push   %eax
f0101926:	68 d7 02 00 00       	push   $0x2d7
f010192b:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0101931:	50                   	push   %eax
f0101932:	e8 7a e7 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101937:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010193a:	8d 83 08 a3 f7 ff    	lea    -0x85cf8(%ebx),%eax
f0101940:	50                   	push   %eax
f0101941:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0101947:	50                   	push   %eax
f0101948:	68 d8 02 00 00       	push   $0x2d8
f010194d:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0101953:	50                   	push   %eax
f0101954:	e8 58 e7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101959:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010195c:	8d 83 a1 aa f7 ff    	lea    -0x8555f(%ebx),%eax
f0101962:	50                   	push   %eax
f0101963:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0101969:	50                   	push   %eax
f010196a:	68 d9 02 00 00       	push   $0x2d9
f010196f:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0101975:	50                   	push   %eax
f0101976:	e8 36 e7 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010197b:	50                   	push   %eax
f010197c:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f0101982:	50                   	push   %eax
f0101983:	6a 5d                	push   $0x5d
f0101985:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f010198b:	50                   	push   %eax
f010198c:	e8 20 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101991:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101994:	8d 83 b0 aa f7 ff    	lea    -0x85550(%ebx),%eax
f010199a:	50                   	push   %eax
f010199b:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01019a1:	50                   	push   %eax
f01019a2:	68 de 02 00 00       	push   $0x2de
f01019a7:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01019ad:	50                   	push   %eax
f01019ae:	e8 fe e6 ff ff       	call   f01000b1 <_panic>
	assert(pp && pp0 == pp);
f01019b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019b6:	8d 83 ce aa f7 ff    	lea    -0x85532(%ebx),%eax
f01019bc:	50                   	push   %eax
f01019bd:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01019c3:	50                   	push   %eax
f01019c4:	68 df 02 00 00       	push   $0x2df
f01019c9:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01019cf:	50                   	push   %eax
f01019d0:	e8 dc e6 ff ff       	call   f01000b1 <_panic>
f01019d5:	52                   	push   %edx
f01019d6:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f01019dc:	50                   	push   %eax
f01019dd:	6a 5d                	push   $0x5d
f01019df:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f01019e5:	50                   	push   %eax
f01019e6:	e8 c6 e6 ff ff       	call   f01000b1 <_panic>
		assert(c[i] == 0);
f01019eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019ee:	8d 83 de aa f7 ff    	lea    -0x85522(%ebx),%eax
f01019f4:	50                   	push   %eax
f01019f5:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01019fb:	50                   	push   %eax
f01019fc:	68 e2 02 00 00       	push   $0x2e2
f0101a01:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
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
f0101a18:	0f 85 65 08 00 00    	jne    f0102283 <mem_init+0xed0>
	cprintf("check_page_alloc() succeeded!\n");
f0101a1e:	83 ec 0c             	sub    $0xc,%esp
f0101a21:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a24:	8d 83 28 a3 f7 ff    	lea    -0x85cd8(%ebx),%eax
f0101a2a:	50                   	push   %eax
f0101a2b:	e8 cb 1c 00 00       	call   f01036fb <cprintf>
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
f0101a44:	0f 84 5b 08 00 00    	je     f01022a5 <mem_init+0xef2>
	assert((pp1 = page_alloc(0)));
f0101a4a:	83 ec 0c             	sub    $0xc,%esp
f0101a4d:	6a 00                	push   $0x0
f0101a4f:	e8 fd f5 ff ff       	call   f0101051 <page_alloc>
f0101a54:	89 c7                	mov    %eax,%edi
f0101a56:	83 c4 10             	add    $0x10,%esp
f0101a59:	85 c0                	test   %eax,%eax
f0101a5b:	0f 84 66 08 00 00    	je     f01022c7 <mem_init+0xf14>
	assert((pp2 = page_alloc(0)));
f0101a61:	83 ec 0c             	sub    $0xc,%esp
f0101a64:	6a 00                	push   $0x0
f0101a66:	e8 e6 f5 ff ff       	call   f0101051 <page_alloc>
f0101a6b:	89 c6                	mov    %eax,%esi
f0101a6d:	83 c4 10             	add    $0x10,%esp
f0101a70:	85 c0                	test   %eax,%eax
f0101a72:	0f 84 71 08 00 00    	je     f01022e9 <mem_init+0xf36>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a78:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101a7b:	0f 84 8a 08 00 00    	je     f010230b <mem_init+0xf58>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a81:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101a84:	0f 84 a3 08 00 00    	je     f010232d <mem_init+0xf7a>
f0101a8a:	39 c7                	cmp    %eax,%edi
f0101a8c:	0f 84 9b 08 00 00    	je     f010232d <mem_init+0xf7a>

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
f0101ab7:	0f 85 92 08 00 00    	jne    f010234f <mem_init+0xf9c>

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
f0101adb:	0f 85 90 08 00 00    	jne    f0102371 <mem_init+0xfbe>

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
f0101afb:	0f 89 92 08 00 00    	jns    f0102393 <mem_init+0xfe0>

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
f0101b26:	0f 85 89 08 00 00    	jne    f01023b5 <mem_init+0x1002>
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
f0101b57:	0f 85 7a 08 00 00    	jne    f01023d7 <mem_init+0x1024>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b5d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b62:	89 d8                	mov    %ebx,%eax
f0101b64:	e8 f9 ef ff ff       	call   f0100b62 <check_va2pa>
f0101b69:	89 fa                	mov    %edi,%edx
f0101b6b:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b6e:	c1 fa 03             	sar    $0x3,%edx
f0101b71:	c1 e2 0c             	shl    $0xc,%edx
f0101b74:	39 d0                	cmp    %edx,%eax
f0101b76:	0f 85 7d 08 00 00    	jne    f01023f9 <mem_init+0x1046>
	assert(pp1->pp_ref == 1);
f0101b7c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b81:	0f 85 94 08 00 00    	jne    f010241b <mem_init+0x1068>
	assert(pp0->pp_ref == 1);
f0101b87:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b8a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b8f:	0f 85 a8 08 00 00    	jne    f010243d <mem_init+0x108a>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b95:	6a 02                	push   $0x2
f0101b97:	68 00 10 00 00       	push   $0x1000
f0101b9c:	56                   	push   %esi
f0101b9d:	53                   	push   %ebx
f0101b9e:	e8 92 f7 ff ff       	call   f0101335 <page_insert>
f0101ba3:	83 c4 10             	add    $0x10,%esp
f0101ba6:	85 c0                	test   %eax,%eax
f0101ba8:	0f 85 b1 08 00 00    	jne    f010245f <mem_init+0x10ac>
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
f0101bd7:	0f 85 a4 08 00 00    	jne    f0102481 <mem_init+0x10ce>
	assert(pp2->pp_ref == 1);
f0101bdd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101be2:	0f 85 bb 08 00 00    	jne    f01024a3 <mem_init+0x10f0>

	// should be no free memory
	assert(!page_alloc(0));
f0101be8:	83 ec 0c             	sub    $0xc,%esp
f0101beb:	6a 00                	push   $0x0
f0101bed:	e8 5f f4 ff ff       	call   f0101051 <page_alloc>
f0101bf2:	83 c4 10             	add    $0x10,%esp
f0101bf5:	85 c0                	test   %eax,%eax
f0101bf7:	0f 85 c8 08 00 00    	jne    f01024c5 <mem_init+0x1112>

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
f0101c1a:	0f 85 c7 08 00 00    	jne    f01024e7 <mem_init+0x1134>
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
f0101c49:	0f 85 ba 08 00 00    	jne    f0102509 <mem_init+0x1156>
	assert(pp2->pp_ref == 1);
f0101c4f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c54:	0f 85 d1 08 00 00    	jne    f010252b <mem_init+0x1178>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c5a:	83 ec 0c             	sub    $0xc,%esp
f0101c5d:	6a 00                	push   $0x0
f0101c5f:	e8 ed f3 ff ff       	call   f0101051 <page_alloc>
f0101c64:	83 c4 10             	add    $0x10,%esp
f0101c67:	85 c0                	test   %eax,%eax
f0101c69:	0f 85 de 08 00 00    	jne    f010254d <mem_init+0x119a>

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
f0101c8e:	0f 83 db 08 00 00    	jae    f010256f <mem_init+0x11bc>
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
f0101cb7:	0f 85 ce 08 00 00    	jne    f010258b <mem_init+0x11d8>

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
f0101cda:	0f 85 cd 08 00 00    	jne    f01025ad <mem_init+0x11fa>
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
f0101d0e:	0f 85 bb 08 00 00    	jne    f01025cf <mem_init+0x121c>
	assert(pp2->pp_ref == 1);
f0101d14:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d19:	0f 85 d2 08 00 00    	jne    f01025f1 <mem_init+0x123e>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d1f:	83 ec 04             	sub    $0x4,%esp
f0101d22:	6a 00                	push   $0x0
f0101d24:	68 00 10 00 00       	push   $0x1000
f0101d29:	53                   	push   %ebx
f0101d2a:	e8 22 f4 ff ff       	call   f0101151 <pgdir_walk>
f0101d2f:	83 c4 10             	add    $0x10,%esp
f0101d32:	f6 00 04             	testb  $0x4,(%eax)
f0101d35:	0f 84 d8 08 00 00    	je     f0102613 <mem_init+0x1260>
	assert(kern_pgdir[0] & PTE_U);
f0101d3b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d3e:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101d44:	8b 00                	mov    (%eax),%eax
f0101d46:	f6 00 04             	testb  $0x4,(%eax)
f0101d49:	0f 84 e6 08 00 00    	je     f0102635 <mem_init+0x1282>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d4f:	6a 02                	push   $0x2
f0101d51:	68 00 10 00 00       	push   $0x1000
f0101d56:	56                   	push   %esi
f0101d57:	50                   	push   %eax
f0101d58:	e8 d8 f5 ff ff       	call   f0101335 <page_insert>
f0101d5d:	83 c4 10             	add    $0x10,%esp
f0101d60:	85 c0                	test   %eax,%eax
f0101d62:	0f 85 ef 08 00 00    	jne    f0102657 <mem_init+0x12a4>
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
f0101d88:	0f 84 eb 08 00 00    	je     f0102679 <mem_init+0x12c6>
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
f0101dae:	0f 85 e7 08 00 00    	jne    f010269b <mem_init+0x12e8>

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
f0101dd3:	0f 89 e4 08 00 00    	jns    f01026bd <mem_init+0x130a>

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
f0101df6:	0f 85 e3 08 00 00    	jne    f01026df <mem_init+0x132c>
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
f0101e1c:	0f 85 df 08 00 00    	jne    f0102701 <mem_init+0x134e>

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
f0101e55:	0f 85 c8 08 00 00    	jne    f0102723 <mem_init+0x1370>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e5b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e60:	89 d8                	mov    %ebx,%eax
f0101e62:	e8 fb ec ff ff       	call   f0100b62 <check_va2pa>
f0101e67:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e6a:	0f 85 d5 08 00 00    	jne    f0102745 <mem_init+0x1392>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e70:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101e75:	0f 85 ec 08 00 00    	jne    f0102767 <mem_init+0x13b4>
	assert(pp2->pp_ref == 0);
f0101e7b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e80:	0f 85 03 09 00 00    	jne    f0102789 <mem_init+0x13d6>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e86:	83 ec 0c             	sub    $0xc,%esp
f0101e89:	6a 00                	push   $0x0
f0101e8b:	e8 c1 f1 ff ff       	call   f0101051 <page_alloc>
f0101e90:	83 c4 10             	add    $0x10,%esp
f0101e93:	39 c6                	cmp    %eax,%esi
f0101e95:	0f 85 10 09 00 00    	jne    f01027ab <mem_init+0x13f8>
f0101e9b:	85 c0                	test   %eax,%eax
f0101e9d:	0f 84 08 09 00 00    	je     f01027ab <mem_init+0x13f8>

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
f0101ecc:	0f 85 fb 08 00 00    	jne    f01027cd <mem_init+0x141a>
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
f0101ef5:	0f 85 f4 08 00 00    	jne    f01027ef <mem_init+0x143c>
	assert(pp1->pp_ref == 1);
f0101efb:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101f00:	0f 85 0b 09 00 00    	jne    f0102811 <mem_init+0x145e>
	assert(pp2->pp_ref == 0);
f0101f06:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f0b:	0f 85 22 09 00 00    	jne    f0102833 <mem_init+0x1480>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f11:	6a 00                	push   $0x0
f0101f13:	68 00 10 00 00       	push   $0x1000
f0101f18:	57                   	push   %edi
f0101f19:	53                   	push   %ebx
f0101f1a:	e8 16 f4 ff ff       	call   f0101335 <page_insert>
f0101f1f:	83 c4 10             	add    $0x10,%esp
f0101f22:	85 c0                	test   %eax,%eax
f0101f24:	0f 85 2b 09 00 00    	jne    f0102855 <mem_init+0x14a2>
	assert(pp1->pp_ref);
f0101f2a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f2f:	0f 84 42 09 00 00    	je     f0102877 <mem_init+0x14c4>
	assert(pp1->pp_link == NULL);
f0101f35:	83 3f 00             	cmpl   $0x0,(%edi)
f0101f38:	0f 85 5b 09 00 00    	jne    f0102899 <mem_init+0x14e6>

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
f0101f6a:	0f 85 4b 09 00 00    	jne    f01028bb <mem_init+0x1508>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f75:	89 d8                	mov    %ebx,%eax
f0101f77:	e8 e6 eb ff ff       	call   f0100b62 <check_va2pa>
f0101f7c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f7f:	0f 85 58 09 00 00    	jne    f01028dd <mem_init+0x152a>
	assert(pp1->pp_ref == 0);
f0101f85:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f8a:	0f 85 6f 09 00 00    	jne    f01028ff <mem_init+0x154c>
	assert(pp2->pp_ref == 0);
f0101f90:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f95:	0f 85 86 09 00 00    	jne    f0102921 <mem_init+0x156e>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f9b:	83 ec 0c             	sub    $0xc,%esp
f0101f9e:	6a 00                	push   $0x0
f0101fa0:	e8 ac f0 ff ff       	call   f0101051 <page_alloc>
f0101fa5:	83 c4 10             	add    $0x10,%esp
f0101fa8:	39 c7                	cmp    %eax,%edi
f0101faa:	0f 85 93 09 00 00    	jne    f0102943 <mem_init+0x1590>
f0101fb0:	85 c0                	test   %eax,%eax
f0101fb2:	0f 84 8b 09 00 00    	je     f0102943 <mem_init+0x1590>

	// should be no free memory
	assert(!page_alloc(0));
f0101fb8:	83 ec 0c             	sub    $0xc,%esp
f0101fbb:	6a 00                	push   $0x0
f0101fbd:	e8 8f f0 ff ff       	call   f0101051 <page_alloc>
f0101fc2:	83 c4 10             	add    $0x10,%esp
f0101fc5:	85 c0                	test   %eax,%eax
f0101fc7:	0f 85 98 09 00 00    	jne    f0102965 <mem_init+0x15b2>

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
f0101ff5:	0f 85 8c 09 00 00    	jne    f0102987 <mem_init+0x15d4>
	kern_pgdir[0] = 0;
f0101ffb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102001:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102004:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102009:	0f 85 9a 09 00 00    	jne    f01029a9 <mem_init+0x15f6>
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
f0102061:	0f 83 64 09 00 00    	jae    f01029cb <mem_init+0x1618>
	assert(ptep == ptep1 + PTX(va));
f0102067:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010206d:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0102070:	0f 85 71 09 00 00    	jne    f01029e7 <mem_init+0x1634>
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
f01020a0:	0f 86 63 09 00 00    	jbe    f0102a09 <mem_init+0x1656>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020a6:	83 ec 04             	sub    $0x4,%esp
f01020a9:	68 00 10 00 00       	push   $0x1000
f01020ae:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01020b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020b8:	50                   	push   %eax
f01020b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020bc:	e8 ea 26 00 00       	call   f01047ab <memset>
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
f0102104:	0f 83 18 09 00 00    	jae    f0102a22 <mem_init+0x166f>
	return (void *)(pa + KERNBASE);
f010210a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102110:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102113:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102119:	f6 00 01             	testb  $0x1,(%eax)
f010211c:	0f 85 19 09 00 00    	jne    f0102a3b <mem_init+0x1688>
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
f0102165:	8d 83 bf ab f7 ff    	lea    -0x85441(%ebx),%eax
f010216b:	89 04 24             	mov    %eax,(%esp)
f010216e:	e8 88 15 00 00       	call   f01036fb <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f0102173:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102179:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010217b:	83 c4 10             	add    $0x10,%esp
f010217e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102183:	0f 86 d4 08 00 00    	jbe    f0102a5d <mem_init+0x16aa>
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
	boot_map_region(kern_pgdir, UENVS, NENV * sizeof(struct Env), PADDR(envs), PTE_U | PTE_P);
f01021b4:	c7 c0 44 d3 18 f0    	mov    $0xf018d344,%eax
f01021ba:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01021bc:	83 c4 10             	add    $0x10,%esp
f01021bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021c4:	0f 86 af 08 00 00    	jbe    f0102a79 <mem_init+0x16c6>
f01021ca:	83 ec 08             	sub    $0x8,%esp
f01021cd:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f01021cf:	05 00 00 00 10       	add    $0x10000000,%eax
f01021d4:	50                   	push   %eax
f01021d5:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01021da:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021df:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01021e2:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f01021e8:	8b 00                	mov    (%eax),%eax
f01021ea:	e8 0d f0 ff ff       	call   f01011fc <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01021ef:	c7 c0 00 10 11 f0    	mov    $0xf0111000,%eax
f01021f5:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01021f8:	83 c4 10             	add    $0x10,%esp
f01021fb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102200:	0f 86 8f 08 00 00    	jbe    f0102a95 <mem_init+0x16e2>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102206:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102209:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f010220f:	83 ec 08             	sub    $0x8,%esp
f0102212:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f0102214:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102217:	05 00 00 00 10       	add    $0x10000000,%eax
f010221c:	50                   	push   %eax
f010221d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102222:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102227:	8b 03                	mov    (%ebx),%eax
f0102229:	e8 ce ef ff ff       	call   f01011fc <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0x100000000 - KERNBASE, 0, PTE_W);
f010222e:	83 c4 08             	add    $0x8,%esp
f0102231:	6a 02                	push   $0x2
f0102233:	6a 00                	push   $0x0
f0102235:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010223a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010223f:	8b 03                	mov    (%ebx),%eax
f0102241:	e8 b6 ef ff ff       	call   f01011fc <boot_map_region>
	pgdir = kern_pgdir;
f0102246:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102248:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f010224e:	8b 00                	mov    (%eax),%eax
f0102250:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102253:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010225a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010225f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102262:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102268:	8b 00                	mov    (%eax),%eax
f010226a:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f010226d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102270:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi
f0102276:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0102279:	bb 00 00 00 00       	mov    $0x0,%ebx
f010227e:	e9 57 08 00 00       	jmp    f0102ada <mem_init+0x1727>
	assert(nfree == 0);
f0102283:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102286:	8d 83 e8 aa f7 ff    	lea    -0x85518(%ebx),%eax
f010228c:	50                   	push   %eax
f010228d:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102293:	50                   	push   %eax
f0102294:	68 ef 02 00 00       	push   $0x2ef
f0102299:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010229f:	50                   	push   %eax
f01022a0:	e8 0c de ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f01022a5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022a8:	8d 83 f6 a9 f7 ff    	lea    -0x8560a(%ebx),%eax
f01022ae:	50                   	push   %eax
f01022af:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01022b5:	50                   	push   %eax
f01022b6:	68 4d 03 00 00       	push   $0x34d
f01022bb:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01022c1:	50                   	push   %eax
f01022c2:	e8 ea dd ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01022c7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022ca:	8d 83 0c aa f7 ff    	lea    -0x855f4(%ebx),%eax
f01022d0:	50                   	push   %eax
f01022d1:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01022d7:	50                   	push   %eax
f01022d8:	68 4e 03 00 00       	push   $0x34e
f01022dd:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01022e3:	50                   	push   %eax
f01022e4:	e8 c8 dd ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01022e9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022ec:	8d 83 22 aa f7 ff    	lea    -0x855de(%ebx),%eax
f01022f2:	50                   	push   %eax
f01022f3:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01022f9:	50                   	push   %eax
f01022fa:	68 4f 03 00 00       	push   $0x34f
f01022ff:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102305:	50                   	push   %eax
f0102306:	e8 a6 dd ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f010230b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010230e:	8d 83 38 aa f7 ff    	lea    -0x855c8(%ebx),%eax
f0102314:	50                   	push   %eax
f0102315:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010231b:	50                   	push   %eax
f010231c:	68 52 03 00 00       	push   $0x352
f0102321:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102327:	50                   	push   %eax
f0102328:	e8 84 dd ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010232d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102330:	8d 83 08 a3 f7 ff    	lea    -0x85cf8(%ebx),%eax
f0102336:	50                   	push   %eax
f0102337:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010233d:	50                   	push   %eax
f010233e:	68 53 03 00 00       	push   $0x353
f0102343:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102349:	50                   	push   %eax
f010234a:	e8 62 dd ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010234f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102352:	8d 83 a1 aa f7 ff    	lea    -0x8555f(%ebx),%eax
f0102358:	50                   	push   %eax
f0102359:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010235f:	50                   	push   %eax
f0102360:	68 5a 03 00 00       	push   $0x35a
f0102365:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010236b:	50                   	push   %eax
f010236c:	e8 40 dd ff ff       	call   f01000b1 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102371:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102374:	8d 83 48 a3 f7 ff    	lea    -0x85cb8(%ebx),%eax
f010237a:	50                   	push   %eax
f010237b:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102381:	50                   	push   %eax
f0102382:	68 5d 03 00 00       	push   $0x35d
f0102387:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010238d:	50                   	push   %eax
f010238e:	e8 1e dd ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102393:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102396:	8d 83 80 a3 f7 ff    	lea    -0x85c80(%ebx),%eax
f010239c:	50                   	push   %eax
f010239d:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01023a3:	50                   	push   %eax
f01023a4:	68 60 03 00 00       	push   $0x360
f01023a9:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01023af:	50                   	push   %eax
f01023b0:	e8 fc dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01023b5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023b8:	8d 83 b0 a3 f7 ff    	lea    -0x85c50(%ebx),%eax
f01023be:	50                   	push   %eax
f01023bf:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01023c5:	50                   	push   %eax
f01023c6:	68 64 03 00 00       	push   $0x364
f01023cb:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01023d1:	50                   	push   %eax
f01023d2:	e8 da dc ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023d7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023da:	8d 83 e0 a3 f7 ff    	lea    -0x85c20(%ebx),%eax
f01023e0:	50                   	push   %eax
f01023e1:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01023e7:	50                   	push   %eax
f01023e8:	68 65 03 00 00       	push   $0x365
f01023ed:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01023f3:	50                   	push   %eax
f01023f4:	e8 b8 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01023f9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023fc:	8d 83 08 a4 f7 ff    	lea    -0x85bf8(%ebx),%eax
f0102402:	50                   	push   %eax
f0102403:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102409:	50                   	push   %eax
f010240a:	68 66 03 00 00       	push   $0x366
f010240f:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102415:	50                   	push   %eax
f0102416:	e8 96 dc ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f010241b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010241e:	8d 83 f3 aa f7 ff    	lea    -0x8550d(%ebx),%eax
f0102424:	50                   	push   %eax
f0102425:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010242b:	50                   	push   %eax
f010242c:	68 67 03 00 00       	push   $0x367
f0102431:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102437:	50                   	push   %eax
f0102438:	e8 74 dc ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f010243d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102440:	8d 83 04 ab f7 ff    	lea    -0x854fc(%ebx),%eax
f0102446:	50                   	push   %eax
f0102447:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010244d:	50                   	push   %eax
f010244e:	68 68 03 00 00       	push   $0x368
f0102453:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102459:	50                   	push   %eax
f010245a:	e8 52 dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010245f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102462:	8d 83 38 a4 f7 ff    	lea    -0x85bc8(%ebx),%eax
f0102468:	50                   	push   %eax
f0102469:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010246f:	50                   	push   %eax
f0102470:	68 6b 03 00 00       	push   $0x36b
f0102475:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010247b:	50                   	push   %eax
f010247c:	e8 30 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102481:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102484:	8d 83 74 a4 f7 ff    	lea    -0x85b8c(%ebx),%eax
f010248a:	50                   	push   %eax
f010248b:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102491:	50                   	push   %eax
f0102492:	68 6c 03 00 00       	push   $0x36c
f0102497:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010249d:	50                   	push   %eax
f010249e:	e8 0e dc ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01024a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024a6:	8d 83 15 ab f7 ff    	lea    -0x854eb(%ebx),%eax
f01024ac:	50                   	push   %eax
f01024ad:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01024b3:	50                   	push   %eax
f01024b4:	68 6d 03 00 00       	push   $0x36d
f01024b9:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01024bf:	50                   	push   %eax
f01024c0:	e8 ec db ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01024c5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024c8:	8d 83 a1 aa f7 ff    	lea    -0x8555f(%ebx),%eax
f01024ce:	50                   	push   %eax
f01024cf:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01024d5:	50                   	push   %eax
f01024d6:	68 70 03 00 00       	push   $0x370
f01024db:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01024e1:	50                   	push   %eax
f01024e2:	e8 ca db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024ea:	8d 83 38 a4 f7 ff    	lea    -0x85bc8(%ebx),%eax
f01024f0:	50                   	push   %eax
f01024f1:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01024f7:	50                   	push   %eax
f01024f8:	68 73 03 00 00       	push   $0x373
f01024fd:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102503:	50                   	push   %eax
f0102504:	e8 a8 db ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102509:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010250c:	8d 83 74 a4 f7 ff    	lea    -0x85b8c(%ebx),%eax
f0102512:	50                   	push   %eax
f0102513:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102519:	50                   	push   %eax
f010251a:	68 74 03 00 00       	push   $0x374
f010251f:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102525:	50                   	push   %eax
f0102526:	e8 86 db ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f010252b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010252e:	8d 83 15 ab f7 ff    	lea    -0x854eb(%ebx),%eax
f0102534:	50                   	push   %eax
f0102535:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010253b:	50                   	push   %eax
f010253c:	68 75 03 00 00       	push   $0x375
f0102541:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102547:	50                   	push   %eax
f0102548:	e8 64 db ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010254d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102550:	8d 83 a1 aa f7 ff    	lea    -0x8555f(%ebx),%eax
f0102556:	50                   	push   %eax
f0102557:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010255d:	50                   	push   %eax
f010255e:	68 79 03 00 00       	push   $0x379
f0102563:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102569:	50                   	push   %eax
f010256a:	e8 42 db ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010256f:	50                   	push   %eax
f0102570:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102573:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f0102579:	50                   	push   %eax
f010257a:	68 7c 03 00 00       	push   $0x37c
f010257f:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102585:	50                   	push   %eax
f0102586:	e8 26 db ff ff       	call   f01000b1 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010258b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010258e:	8d 83 a4 a4 f7 ff    	lea    -0x85b5c(%ebx),%eax
f0102594:	50                   	push   %eax
f0102595:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010259b:	50                   	push   %eax
f010259c:	68 7d 03 00 00       	push   $0x37d
f01025a1:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01025a7:	50                   	push   %eax
f01025a8:	e8 04 db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01025ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025b0:	8d 83 e4 a4 f7 ff    	lea    -0x85b1c(%ebx),%eax
f01025b6:	50                   	push   %eax
f01025b7:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01025bd:	50                   	push   %eax
f01025be:	68 80 03 00 00       	push   $0x380
f01025c3:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01025c9:	50                   	push   %eax
f01025ca:	e8 e2 da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01025cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025d2:	8d 83 74 a4 f7 ff    	lea    -0x85b8c(%ebx),%eax
f01025d8:	50                   	push   %eax
f01025d9:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01025df:	50                   	push   %eax
f01025e0:	68 81 03 00 00       	push   $0x381
f01025e5:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01025eb:	50                   	push   %eax
f01025ec:	e8 c0 da ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01025f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025f4:	8d 83 15 ab f7 ff    	lea    -0x854eb(%ebx),%eax
f01025fa:	50                   	push   %eax
f01025fb:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102601:	50                   	push   %eax
f0102602:	68 82 03 00 00       	push   $0x382
f0102607:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010260d:	50                   	push   %eax
f010260e:	e8 9e da ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102613:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102616:	8d 83 24 a5 f7 ff    	lea    -0x85adc(%ebx),%eax
f010261c:	50                   	push   %eax
f010261d:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102623:	50                   	push   %eax
f0102624:	68 83 03 00 00       	push   $0x383
f0102629:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010262f:	50                   	push   %eax
f0102630:	e8 7c da ff ff       	call   f01000b1 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102635:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102638:	8d 83 26 ab f7 ff    	lea    -0x854da(%ebx),%eax
f010263e:	50                   	push   %eax
f010263f:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102645:	50                   	push   %eax
f0102646:	68 84 03 00 00       	push   $0x384
f010264b:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102651:	50                   	push   %eax
f0102652:	e8 5a da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102657:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010265a:	8d 83 38 a4 f7 ff    	lea    -0x85bc8(%ebx),%eax
f0102660:	50                   	push   %eax
f0102661:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102667:	50                   	push   %eax
f0102668:	68 87 03 00 00       	push   $0x387
f010266d:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102673:	50                   	push   %eax
f0102674:	e8 38 da ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102679:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010267c:	8d 83 58 a5 f7 ff    	lea    -0x85aa8(%ebx),%eax
f0102682:	50                   	push   %eax
f0102683:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102689:	50                   	push   %eax
f010268a:	68 88 03 00 00       	push   $0x388
f010268f:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102695:	50                   	push   %eax
f0102696:	e8 16 da ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010269b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010269e:	8d 83 8c a5 f7 ff    	lea    -0x85a74(%ebx),%eax
f01026a4:	50                   	push   %eax
f01026a5:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01026ab:	50                   	push   %eax
f01026ac:	68 89 03 00 00       	push   $0x389
f01026b1:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01026b7:	50                   	push   %eax
f01026b8:	e8 f4 d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01026bd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026c0:	8d 83 c4 a5 f7 ff    	lea    -0x85a3c(%ebx),%eax
f01026c6:	50                   	push   %eax
f01026c7:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01026cd:	50                   	push   %eax
f01026ce:	68 8c 03 00 00       	push   $0x38c
f01026d3:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01026d9:	50                   	push   %eax
f01026da:	e8 d2 d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01026df:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026e2:	8d 83 fc a5 f7 ff    	lea    -0x85a04(%ebx),%eax
f01026e8:	50                   	push   %eax
f01026e9:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01026ef:	50                   	push   %eax
f01026f0:	68 8f 03 00 00       	push   $0x38f
f01026f5:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01026fb:	50                   	push   %eax
f01026fc:	e8 b0 d9 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102701:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102704:	8d 83 8c a5 f7 ff    	lea    -0x85a74(%ebx),%eax
f010270a:	50                   	push   %eax
f010270b:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102711:	50                   	push   %eax
f0102712:	68 90 03 00 00       	push   $0x390
f0102717:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010271d:	50                   	push   %eax
f010271e:	e8 8e d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102723:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102726:	8d 83 38 a6 f7 ff    	lea    -0x859c8(%ebx),%eax
f010272c:	50                   	push   %eax
f010272d:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102733:	50                   	push   %eax
f0102734:	68 93 03 00 00       	push   $0x393
f0102739:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010273f:	50                   	push   %eax
f0102740:	e8 6c d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102745:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102748:	8d 83 64 a6 f7 ff    	lea    -0x8599c(%ebx),%eax
f010274e:	50                   	push   %eax
f010274f:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102755:	50                   	push   %eax
f0102756:	68 94 03 00 00       	push   $0x394
f010275b:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102761:	50                   	push   %eax
f0102762:	e8 4a d9 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 2);
f0102767:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010276a:	8d 83 3c ab f7 ff    	lea    -0x854c4(%ebx),%eax
f0102770:	50                   	push   %eax
f0102771:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102777:	50                   	push   %eax
f0102778:	68 96 03 00 00       	push   $0x396
f010277d:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102783:	50                   	push   %eax
f0102784:	e8 28 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102789:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010278c:	8d 83 4d ab f7 ff    	lea    -0x854b3(%ebx),%eax
f0102792:	50                   	push   %eax
f0102793:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102799:	50                   	push   %eax
f010279a:	68 97 03 00 00       	push   $0x397
f010279f:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01027a5:	50                   	push   %eax
f01027a6:	e8 06 d9 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01027ab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ae:	8d 83 94 a6 f7 ff    	lea    -0x8596c(%ebx),%eax
f01027b4:	50                   	push   %eax
f01027b5:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01027bb:	50                   	push   %eax
f01027bc:	68 9a 03 00 00       	push   $0x39a
f01027c1:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01027c7:	50                   	push   %eax
f01027c8:	e8 e4 d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01027cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027d0:	8d 83 b8 a6 f7 ff    	lea    -0x85948(%ebx),%eax
f01027d6:	50                   	push   %eax
f01027d7:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01027dd:	50                   	push   %eax
f01027de:	68 9e 03 00 00       	push   $0x39e
f01027e3:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01027e9:	50                   	push   %eax
f01027ea:	e8 c2 d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027f2:	8d 83 64 a6 f7 ff    	lea    -0x8599c(%ebx),%eax
f01027f8:	50                   	push   %eax
f01027f9:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01027ff:	50                   	push   %eax
f0102800:	68 9f 03 00 00       	push   $0x39f
f0102805:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010280b:	50                   	push   %eax
f010280c:	e8 a0 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102811:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102814:	8d 83 f3 aa f7 ff    	lea    -0x8550d(%ebx),%eax
f010281a:	50                   	push   %eax
f010281b:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102821:	50                   	push   %eax
f0102822:	68 a0 03 00 00       	push   $0x3a0
f0102827:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010282d:	50                   	push   %eax
f010282e:	e8 7e d8 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102833:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102836:	8d 83 4d ab f7 ff    	lea    -0x854b3(%ebx),%eax
f010283c:	50                   	push   %eax
f010283d:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102843:	50                   	push   %eax
f0102844:	68 a1 03 00 00       	push   $0x3a1
f0102849:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010284f:	50                   	push   %eax
f0102850:	e8 5c d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102855:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102858:	8d 83 dc a6 f7 ff    	lea    -0x85924(%ebx),%eax
f010285e:	50                   	push   %eax
f010285f:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102865:	50                   	push   %eax
f0102866:	68 a4 03 00 00       	push   $0x3a4
f010286b:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102871:	50                   	push   %eax
f0102872:	e8 3a d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref);
f0102877:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010287a:	8d 83 5e ab f7 ff    	lea    -0x854a2(%ebx),%eax
f0102880:	50                   	push   %eax
f0102881:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102887:	50                   	push   %eax
f0102888:	68 a5 03 00 00       	push   $0x3a5
f010288d:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102893:	50                   	push   %eax
f0102894:	e8 18 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_link == NULL);
f0102899:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010289c:	8d 83 6a ab f7 ff    	lea    -0x85496(%ebx),%eax
f01028a2:	50                   	push   %eax
f01028a3:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01028a9:	50                   	push   %eax
f01028aa:	68 a6 03 00 00       	push   $0x3a6
f01028af:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01028b5:	50                   	push   %eax
f01028b6:	e8 f6 d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01028bb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028be:	8d 83 b8 a6 f7 ff    	lea    -0x85948(%ebx),%eax
f01028c4:	50                   	push   %eax
f01028c5:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01028cb:	50                   	push   %eax
f01028cc:	68 aa 03 00 00       	push   $0x3aa
f01028d1:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01028d7:	50                   	push   %eax
f01028d8:	e8 d4 d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01028dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028e0:	8d 83 14 a7 f7 ff    	lea    -0x858ec(%ebx),%eax
f01028e6:	50                   	push   %eax
f01028e7:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01028ed:	50                   	push   %eax
f01028ee:	68 ab 03 00 00       	push   $0x3ab
f01028f3:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01028f9:	50                   	push   %eax
f01028fa:	e8 b2 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f01028ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102902:	8d 83 7f ab f7 ff    	lea    -0x85481(%ebx),%eax
f0102908:	50                   	push   %eax
f0102909:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010290f:	50                   	push   %eax
f0102910:	68 ac 03 00 00       	push   $0x3ac
f0102915:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010291b:	50                   	push   %eax
f010291c:	e8 90 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102921:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102924:	8d 83 4d ab f7 ff    	lea    -0x854b3(%ebx),%eax
f010292a:	50                   	push   %eax
f010292b:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102931:	50                   	push   %eax
f0102932:	68 ad 03 00 00       	push   $0x3ad
f0102937:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010293d:	50                   	push   %eax
f010293e:	e8 6e d7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102943:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102946:	8d 83 3c a7 f7 ff    	lea    -0x858c4(%ebx),%eax
f010294c:	50                   	push   %eax
f010294d:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102953:	50                   	push   %eax
f0102954:	68 b0 03 00 00       	push   $0x3b0
f0102959:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010295f:	50                   	push   %eax
f0102960:	e8 4c d7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102965:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102968:	8d 83 a1 aa f7 ff    	lea    -0x8555f(%ebx),%eax
f010296e:	50                   	push   %eax
f010296f:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102975:	50                   	push   %eax
f0102976:	68 b3 03 00 00       	push   $0x3b3
f010297b:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102981:	50                   	push   %eax
f0102982:	e8 2a d7 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102987:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010298a:	8d 83 e0 a3 f7 ff    	lea    -0x85c20(%ebx),%eax
f0102990:	50                   	push   %eax
f0102991:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102997:	50                   	push   %eax
f0102998:	68 b6 03 00 00       	push   $0x3b6
f010299d:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01029a3:	50                   	push   %eax
f01029a4:	e8 08 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f01029a9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029ac:	8d 83 04 ab f7 ff    	lea    -0x854fc(%ebx),%eax
f01029b2:	50                   	push   %eax
f01029b3:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01029b9:	50                   	push   %eax
f01029ba:	68 b8 03 00 00       	push   $0x3b8
f01029bf:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01029c5:	50                   	push   %eax
f01029c6:	e8 e6 d6 ff ff       	call   f01000b1 <_panic>
f01029cb:	52                   	push   %edx
f01029cc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029cf:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f01029d5:	50                   	push   %eax
f01029d6:	68 bf 03 00 00       	push   $0x3bf
f01029db:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01029e1:	50                   	push   %eax
f01029e2:	e8 ca d6 ff ff       	call   f01000b1 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01029e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029ea:	8d 83 90 ab f7 ff    	lea    -0x85470(%ebx),%eax
f01029f0:	50                   	push   %eax
f01029f1:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01029f7:	50                   	push   %eax
f01029f8:	68 c0 03 00 00       	push   $0x3c0
f01029fd:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102a03:	50                   	push   %eax
f0102a04:	e8 a8 d6 ff ff       	call   f01000b1 <_panic>
f0102a09:	50                   	push   %eax
f0102a0a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a0d:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f0102a13:	50                   	push   %eax
f0102a14:	6a 5d                	push   $0x5d
f0102a16:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f0102a1c:	50                   	push   %eax
f0102a1d:	e8 8f d6 ff ff       	call   f01000b1 <_panic>
f0102a22:	52                   	push   %edx
f0102a23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a26:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f0102a2c:	50                   	push   %eax
f0102a2d:	6a 5d                	push   $0x5d
f0102a2f:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f0102a35:	50                   	push   %eax
f0102a36:	e8 76 d6 ff ff       	call   f01000b1 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102a3b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a3e:	8d 83 a8 ab f7 ff    	lea    -0x85458(%ebx),%eax
f0102a44:	50                   	push   %eax
f0102a45:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102a4b:	50                   	push   %eax
f0102a4c:	68 ca 03 00 00       	push   $0x3ca
f0102a51:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102a57:	50                   	push   %eax
f0102a58:	e8 54 d6 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a5d:	50                   	push   %eax
f0102a5e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a61:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f0102a67:	50                   	push   %eax
f0102a68:	68 c7 00 00 00       	push   $0xc7
f0102a6d:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102a73:	50                   	push   %eax
f0102a74:	e8 38 d6 ff ff       	call   f01000b1 <_panic>
f0102a79:	50                   	push   %eax
f0102a7a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a7d:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f0102a83:	50                   	push   %eax
f0102a84:	68 d0 00 00 00       	push   $0xd0
f0102a89:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102a8f:	50                   	push   %eax
f0102a90:	e8 1c d6 ff ff       	call   f01000b1 <_panic>
f0102a95:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a98:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102a9e:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f0102aa4:	50                   	push   %eax
f0102aa5:	68 dd 00 00 00       	push   $0xdd
f0102aaa:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102ab0:	50                   	push   %eax
f0102ab1:	e8 fb d5 ff ff       	call   f01000b1 <_panic>
f0102ab6:	ff 75 c0             	pushl  -0x40(%ebp)
f0102ab9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102abc:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f0102ac2:	50                   	push   %eax
f0102ac3:	68 07 03 00 00       	push   $0x307
f0102ac8:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102ace:	50                   	push   %eax
f0102acf:	e8 dd d5 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102ad4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ada:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102add:	76 3f                	jbe    f0102b1e <mem_init+0x176b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102adf:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102ae5:	89 f0                	mov    %esi,%eax
f0102ae7:	e8 76 e0 ff ff       	call   f0100b62 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102aec:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102af3:	76 c1                	jbe    f0102ab6 <mem_init+0x1703>
f0102af5:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102af8:	39 d0                	cmp    %edx,%eax
f0102afa:	74 d8                	je     f0102ad4 <mem_init+0x1721>
f0102afc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aff:	8d 83 60 a7 f7 ff    	lea    -0x858a0(%ebx),%eax
f0102b05:	50                   	push   %eax
f0102b06:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102b0c:	50                   	push   %eax
f0102b0d:	68 07 03 00 00       	push   $0x307
f0102b12:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102b18:	50                   	push   %eax
f0102b19:	e8 93 d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102b1e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b21:	c7 c0 44 d3 18 f0    	mov    $0xf018d344,%eax
f0102b27:	8b 00                	mov    (%eax),%eax
f0102b29:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102b2c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b2f:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
f0102b34:	8d 98 00 00 40 21    	lea    0x21400000(%eax),%ebx
f0102b3a:	89 fa                	mov    %edi,%edx
f0102b3c:	89 f0                	mov    %esi,%eax
f0102b3e:	e8 1f e0 ff ff       	call   f0100b62 <check_va2pa>
f0102b43:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102b4a:	76 3d                	jbe    f0102b89 <mem_init+0x17d6>
f0102b4c:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102b4f:	39 d0                	cmp    %edx,%eax
f0102b51:	75 54                	jne    f0102ba7 <mem_init+0x17f4>
f0102b53:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102b59:	81 ff 00 80 c1 ee    	cmp    $0xeec18000,%edi
f0102b5f:	75 d9                	jne    f0102b3a <mem_init+0x1787>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b61:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102b64:	c1 e7 0c             	shl    $0xc,%edi
f0102b67:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102b6c:	39 fb                	cmp    %edi,%ebx
f0102b6e:	73 7b                	jae    f0102beb <mem_init+0x1838>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102b70:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102b76:	89 f0                	mov    %esi,%eax
f0102b78:	e8 e5 df ff ff       	call   f0100b62 <check_va2pa>
f0102b7d:	39 c3                	cmp    %eax,%ebx
f0102b7f:	75 48                	jne    f0102bc9 <mem_init+0x1816>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b81:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b87:	eb e3                	jmp    f0102b6c <mem_init+0x17b9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b89:	ff 75 cc             	pushl  -0x34(%ebp)
f0102b8c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b8f:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f0102b95:	50                   	push   %eax
f0102b96:	68 0c 03 00 00       	push   $0x30c
f0102b9b:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102ba1:	50                   	push   %eax
f0102ba2:	e8 0a d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102ba7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102baa:	8d 83 94 a7 f7 ff    	lea    -0x8586c(%ebx),%eax
f0102bb0:	50                   	push   %eax
f0102bb1:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102bb7:	50                   	push   %eax
f0102bb8:	68 0c 03 00 00       	push   $0x30c
f0102bbd:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102bc3:	50                   	push   %eax
f0102bc4:	e8 e8 d4 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bc9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bcc:	8d 83 c8 a7 f7 ff    	lea    -0x85838(%ebx),%eax
f0102bd2:	50                   	push   %eax
f0102bd3:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102bd9:	50                   	push   %eax
f0102bda:	68 10 03 00 00       	push   $0x310
f0102bdf:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102be5:	50                   	push   %eax
f0102be6:	e8 c6 d4 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102beb:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102bf0:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102bf3:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102bf9:	89 da                	mov    %ebx,%edx
f0102bfb:	89 f0                	mov    %esi,%eax
f0102bfd:	e8 60 df ff ff       	call   f0100b62 <check_va2pa>
f0102c02:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102c05:	39 c2                	cmp    %eax,%edx
f0102c07:	75 26                	jne    f0102c2f <mem_init+0x187c>
f0102c09:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102c0f:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102c15:	75 e2                	jne    f0102bf9 <mem_init+0x1846>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c17:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102c1c:	89 f0                	mov    %esi,%eax
f0102c1e:	e8 3f df ff ff       	call   f0100b62 <check_va2pa>
f0102c23:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c26:	75 29                	jne    f0102c51 <mem_init+0x189e>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c28:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c2d:	eb 6d                	jmp    f0102c9c <mem_init+0x18e9>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c2f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c32:	8d 83 f0 a7 f7 ff    	lea    -0x85810(%ebx),%eax
f0102c38:	50                   	push   %eax
f0102c39:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102c3f:	50                   	push   %eax
f0102c40:	68 14 03 00 00       	push   $0x314
f0102c45:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102c4b:	50                   	push   %eax
f0102c4c:	e8 60 d4 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c51:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c54:	8d 83 38 a8 f7 ff    	lea    -0x857c8(%ebx),%eax
f0102c5a:	50                   	push   %eax
f0102c5b:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102c61:	50                   	push   %eax
f0102c62:	68 15 03 00 00       	push   $0x315
f0102c67:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102c6d:	50                   	push   %eax
f0102c6e:	e8 3e d4 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102c73:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102c77:	74 52                	je     f0102ccb <mem_init+0x1918>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c79:	83 c0 01             	add    $0x1,%eax
f0102c7c:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102c81:	0f 87 bb 00 00 00    	ja     f0102d42 <mem_init+0x198f>
		switch (i) {
f0102c87:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102c8c:	72 0e                	jb     f0102c9c <mem_init+0x18e9>
f0102c8e:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102c93:	76 de                	jbe    f0102c73 <mem_init+0x18c0>
f0102c95:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c9a:	74 d7                	je     f0102c73 <mem_init+0x18c0>
			if (i >= PDX(KERNBASE)) {
f0102c9c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102ca1:	77 4a                	ja     f0102ced <mem_init+0x193a>
				assert(pgdir[i] == 0);
f0102ca3:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102ca7:	74 d0                	je     f0102c79 <mem_init+0x18c6>
f0102ca9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cac:	8d 83 fa ab f7 ff    	lea    -0x85406(%ebx),%eax
f0102cb2:	50                   	push   %eax
f0102cb3:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102cb9:	50                   	push   %eax
f0102cba:	68 25 03 00 00       	push   $0x325
f0102cbf:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102cc5:	50                   	push   %eax
f0102cc6:	e8 e6 d3 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102ccb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cce:	8d 83 d8 ab f7 ff    	lea    -0x85428(%ebx),%eax
f0102cd4:	50                   	push   %eax
f0102cd5:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102cdb:	50                   	push   %eax
f0102cdc:	68 1e 03 00 00       	push   $0x31e
f0102ce1:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102ce7:	50                   	push   %eax
f0102ce8:	e8 c4 d3 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102ced:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102cf0:	f6 c2 01             	test   $0x1,%dl
f0102cf3:	74 2b                	je     f0102d20 <mem_init+0x196d>
				assert(pgdir[i] & PTE_W);
f0102cf5:	f6 c2 02             	test   $0x2,%dl
f0102cf8:	0f 85 7b ff ff ff    	jne    f0102c79 <mem_init+0x18c6>
f0102cfe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d01:	8d 83 e9 ab f7 ff    	lea    -0x85417(%ebx),%eax
f0102d07:	50                   	push   %eax
f0102d08:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102d0e:	50                   	push   %eax
f0102d0f:	68 23 03 00 00       	push   $0x323
f0102d14:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102d1a:	50                   	push   %eax
f0102d1b:	e8 91 d3 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102d20:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d23:	8d 83 d8 ab f7 ff    	lea    -0x85428(%ebx),%eax
f0102d29:	50                   	push   %eax
f0102d2a:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102d30:	50                   	push   %eax
f0102d31:	68 22 03 00 00       	push   $0x322
f0102d36:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102d3c:	50                   	push   %eax
f0102d3d:	e8 6f d3 ff ff       	call   f01000b1 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102d42:	83 ec 0c             	sub    $0xc,%esp
f0102d45:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d48:	8d 87 68 a8 f7 ff    	lea    -0x85798(%edi),%eax
f0102d4e:	50                   	push   %eax
f0102d4f:	89 fb                	mov    %edi,%ebx
f0102d51:	e8 a5 09 00 00       	call   f01036fb <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102d56:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102d5c:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102d5e:	83 c4 10             	add    $0x10,%esp
f0102d61:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d66:	0f 86 44 02 00 00    	jbe    f0102fb0 <mem_init+0x1bfd>
	return (physaddr_t)kva - KERNBASE;
f0102d6c:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102d71:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102d74:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d79:	e8 61 de ff ff       	call   f0100bdf <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102d7e:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102d81:	83 e0 f3             	and    $0xfffffff3,%eax
f0102d84:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102d89:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102d8c:	83 ec 0c             	sub    $0xc,%esp
f0102d8f:	6a 00                	push   $0x0
f0102d91:	e8 bb e2 ff ff       	call   f0101051 <page_alloc>
f0102d96:	89 c6                	mov    %eax,%esi
f0102d98:	83 c4 10             	add    $0x10,%esp
f0102d9b:	85 c0                	test   %eax,%eax
f0102d9d:	0f 84 29 02 00 00    	je     f0102fcc <mem_init+0x1c19>
	assert((pp1 = page_alloc(0)));
f0102da3:	83 ec 0c             	sub    $0xc,%esp
f0102da6:	6a 00                	push   $0x0
f0102da8:	e8 a4 e2 ff ff       	call   f0101051 <page_alloc>
f0102dad:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102db0:	83 c4 10             	add    $0x10,%esp
f0102db3:	85 c0                	test   %eax,%eax
f0102db5:	0f 84 33 02 00 00    	je     f0102fee <mem_init+0x1c3b>
	assert((pp2 = page_alloc(0)));
f0102dbb:	83 ec 0c             	sub    $0xc,%esp
f0102dbe:	6a 00                	push   $0x0
f0102dc0:	e8 8c e2 ff ff       	call   f0101051 <page_alloc>
f0102dc5:	89 c7                	mov    %eax,%edi
f0102dc7:	83 c4 10             	add    $0x10,%esp
f0102dca:	85 c0                	test   %eax,%eax
f0102dcc:	0f 84 3e 02 00 00    	je     f0103010 <mem_init+0x1c5d>
	page_free(pp0);
f0102dd2:	83 ec 0c             	sub    $0xc,%esp
f0102dd5:	56                   	push   %esi
f0102dd6:	e8 fe e2 ff ff       	call   f01010d9 <page_free>
	return (pp - pages) << PGSHIFT;
f0102ddb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dde:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102de4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102de7:	2b 08                	sub    (%eax),%ecx
f0102de9:	89 c8                	mov    %ecx,%eax
f0102deb:	c1 f8 03             	sar    $0x3,%eax
f0102dee:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102df1:	89 c1                	mov    %eax,%ecx
f0102df3:	c1 e9 0c             	shr    $0xc,%ecx
f0102df6:	83 c4 10             	add    $0x10,%esp
f0102df9:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102dff:	3b 0a                	cmp    (%edx),%ecx
f0102e01:	0f 83 2b 02 00 00    	jae    f0103032 <mem_init+0x1c7f>
	memset(page2kva(pp1), 1, PGSIZE);
f0102e07:	83 ec 04             	sub    $0x4,%esp
f0102e0a:	68 00 10 00 00       	push   $0x1000
f0102e0f:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102e11:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e16:	50                   	push   %eax
f0102e17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e1a:	e8 8c 19 00 00       	call   f01047ab <memset>
	return (pp - pages) << PGSHIFT;
f0102e1f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e22:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102e28:	89 f9                	mov    %edi,%ecx
f0102e2a:	2b 08                	sub    (%eax),%ecx
f0102e2c:	89 c8                	mov    %ecx,%eax
f0102e2e:	c1 f8 03             	sar    $0x3,%eax
f0102e31:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e34:	89 c1                	mov    %eax,%ecx
f0102e36:	c1 e9 0c             	shr    $0xc,%ecx
f0102e39:	83 c4 10             	add    $0x10,%esp
f0102e3c:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102e42:	3b 0a                	cmp    (%edx),%ecx
f0102e44:	0f 83 fe 01 00 00    	jae    f0103048 <mem_init+0x1c95>
	memset(page2kva(pp2), 2, PGSIZE);
f0102e4a:	83 ec 04             	sub    $0x4,%esp
f0102e4d:	68 00 10 00 00       	push   $0x1000
f0102e52:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102e54:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e59:	50                   	push   %eax
f0102e5a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e5d:	e8 49 19 00 00       	call   f01047ab <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102e62:	6a 02                	push   $0x2
f0102e64:	68 00 10 00 00       	push   $0x1000
f0102e69:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102e6c:	53                   	push   %ebx
f0102e6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e70:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102e76:	ff 30                	pushl  (%eax)
f0102e78:	e8 b8 e4 ff ff       	call   f0101335 <page_insert>
	assert(pp1->pp_ref == 1);
f0102e7d:	83 c4 20             	add    $0x20,%esp
f0102e80:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e85:	0f 85 d3 01 00 00    	jne    f010305e <mem_init+0x1cab>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e8b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102e92:	01 01 01 
f0102e95:	0f 85 e5 01 00 00    	jne    f0103080 <mem_init+0x1ccd>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102e9b:	6a 02                	push   $0x2
f0102e9d:	68 00 10 00 00       	push   $0x1000
f0102ea2:	57                   	push   %edi
f0102ea3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ea6:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102eac:	ff 30                	pushl  (%eax)
f0102eae:	e8 82 e4 ff ff       	call   f0101335 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102eb3:	83 c4 10             	add    $0x10,%esp
f0102eb6:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ebd:	02 02 02 
f0102ec0:	0f 85 dc 01 00 00    	jne    f01030a2 <mem_init+0x1cef>
	assert(pp2->pp_ref == 1);
f0102ec6:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ecb:	0f 85 f3 01 00 00    	jne    f01030c4 <mem_init+0x1d11>
	assert(pp1->pp_ref == 0);
f0102ed1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ed4:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102ed9:	0f 85 07 02 00 00    	jne    f01030e6 <mem_init+0x1d33>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102edf:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102ee6:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102ee9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eec:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102ef2:	89 f9                	mov    %edi,%ecx
f0102ef4:	2b 08                	sub    (%eax),%ecx
f0102ef6:	89 c8                	mov    %ecx,%eax
f0102ef8:	c1 f8 03             	sar    $0x3,%eax
f0102efb:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102efe:	89 c1                	mov    %eax,%ecx
f0102f00:	c1 e9 0c             	shr    $0xc,%ecx
f0102f03:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102f09:	3b 0a                	cmp    (%edx),%ecx
f0102f0b:	0f 83 f7 01 00 00    	jae    f0103108 <mem_init+0x1d55>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f11:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102f18:	03 03 03 
f0102f1b:	0f 85 fd 01 00 00    	jne    f010311e <mem_init+0x1d6b>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102f21:	83 ec 08             	sub    $0x8,%esp
f0102f24:	68 00 10 00 00       	push   $0x1000
f0102f29:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f2c:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102f32:	ff 30                	pushl  (%eax)
f0102f34:	e8 bf e3 ff ff       	call   f01012f8 <page_remove>
	assert(pp2->pp_ref == 0);
f0102f39:	83 c4 10             	add    $0x10,%esp
f0102f3c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102f41:	0f 85 f9 01 00 00    	jne    f0103140 <mem_init+0x1d8d>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f47:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102f4a:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102f50:	8b 08                	mov    (%eax),%ecx
f0102f52:	8b 11                	mov    (%ecx),%edx
f0102f54:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102f5a:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102f60:	89 f7                	mov    %esi,%edi
f0102f62:	2b 38                	sub    (%eax),%edi
f0102f64:	89 f8                	mov    %edi,%eax
f0102f66:	c1 f8 03             	sar    $0x3,%eax
f0102f69:	c1 e0 0c             	shl    $0xc,%eax
f0102f6c:	39 c2                	cmp    %eax,%edx
f0102f6e:	0f 85 ee 01 00 00    	jne    f0103162 <mem_init+0x1daf>
	kern_pgdir[0] = 0;
f0102f74:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102f7a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f7f:	0f 85 ff 01 00 00    	jne    f0103184 <mem_init+0x1dd1>
	pp0->pp_ref = 0;
f0102f85:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102f8b:	83 ec 0c             	sub    $0xc,%esp
f0102f8e:	56                   	push   %esi
f0102f8f:	e8 45 e1 ff ff       	call   f01010d9 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102f94:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f97:	8d 83 fc a8 f7 ff    	lea    -0x85704(%ebx),%eax
f0102f9d:	89 04 24             	mov    %eax,(%esp)
f0102fa0:	e8 56 07 00 00       	call   f01036fb <cprintf>
}
f0102fa5:	83 c4 10             	add    $0x10,%esp
f0102fa8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fab:	5b                   	pop    %ebx
f0102fac:	5e                   	pop    %esi
f0102fad:	5f                   	pop    %edi
f0102fae:	5d                   	pop    %ebp
f0102faf:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fb0:	50                   	push   %eax
f0102fb1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fb4:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f0102fba:	50                   	push   %eax
f0102fbb:	68 f1 00 00 00       	push   $0xf1
f0102fc0:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102fc6:	50                   	push   %eax
f0102fc7:	e8 e5 d0 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0102fcc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fcf:	8d 83 f6 a9 f7 ff    	lea    -0x8560a(%ebx),%eax
f0102fd5:	50                   	push   %eax
f0102fd6:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102fdc:	50                   	push   %eax
f0102fdd:	68 e5 03 00 00       	push   $0x3e5
f0102fe2:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0102fe8:	50                   	push   %eax
f0102fe9:	e8 c3 d0 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0102fee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ff1:	8d 83 0c aa f7 ff    	lea    -0x855f4(%ebx),%eax
f0102ff7:	50                   	push   %eax
f0102ff8:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0102ffe:	50                   	push   %eax
f0102fff:	68 e6 03 00 00       	push   $0x3e6
f0103004:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010300a:	50                   	push   %eax
f010300b:	e8 a1 d0 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0103010:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103013:	8d 83 22 aa f7 ff    	lea    -0x855de(%ebx),%eax
f0103019:	50                   	push   %eax
f010301a:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0103020:	50                   	push   %eax
f0103021:	68 e7 03 00 00       	push   $0x3e7
f0103026:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010302c:	50                   	push   %eax
f010302d:	e8 7f d0 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103032:	50                   	push   %eax
f0103033:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f0103039:	50                   	push   %eax
f010303a:	6a 5d                	push   $0x5d
f010303c:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f0103042:	50                   	push   %eax
f0103043:	e8 69 d0 ff ff       	call   f01000b1 <_panic>
f0103048:	50                   	push   %eax
f0103049:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f010304f:	50                   	push   %eax
f0103050:	6a 5d                	push   $0x5d
f0103052:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f0103058:	50                   	push   %eax
f0103059:	e8 53 d0 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f010305e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103061:	8d 83 f3 aa f7 ff    	lea    -0x8550d(%ebx),%eax
f0103067:	50                   	push   %eax
f0103068:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010306e:	50                   	push   %eax
f010306f:	68 ec 03 00 00       	push   $0x3ec
f0103074:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010307a:	50                   	push   %eax
f010307b:	e8 31 d0 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103080:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103083:	8d 83 88 a8 f7 ff    	lea    -0x85778(%ebx),%eax
f0103089:	50                   	push   %eax
f010308a:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0103090:	50                   	push   %eax
f0103091:	68 ed 03 00 00       	push   $0x3ed
f0103096:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010309c:	50                   	push   %eax
f010309d:	e8 0f d0 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01030a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030a5:	8d 83 ac a8 f7 ff    	lea    -0x85754(%ebx),%eax
f01030ab:	50                   	push   %eax
f01030ac:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01030b2:	50                   	push   %eax
f01030b3:	68 ef 03 00 00       	push   $0x3ef
f01030b8:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01030be:	50                   	push   %eax
f01030bf:	e8 ed cf ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01030c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030c7:	8d 83 15 ab f7 ff    	lea    -0x854eb(%ebx),%eax
f01030cd:	50                   	push   %eax
f01030ce:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01030d4:	50                   	push   %eax
f01030d5:	68 f0 03 00 00       	push   $0x3f0
f01030da:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01030e0:	50                   	push   %eax
f01030e1:	e8 cb cf ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f01030e6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030e9:	8d 83 7f ab f7 ff    	lea    -0x85481(%ebx),%eax
f01030ef:	50                   	push   %eax
f01030f0:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f01030f6:	50                   	push   %eax
f01030f7:	68 f1 03 00 00       	push   $0x3f1
f01030fc:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f0103102:	50                   	push   %eax
f0103103:	e8 a9 cf ff ff       	call   f01000b1 <_panic>
f0103108:	50                   	push   %eax
f0103109:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f010310f:	50                   	push   %eax
f0103110:	6a 5d                	push   $0x5d
f0103112:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f0103118:	50                   	push   %eax
f0103119:	e8 93 cf ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010311e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103121:	8d 83 d0 a8 f7 ff    	lea    -0x85730(%ebx),%eax
f0103127:	50                   	push   %eax
f0103128:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f010312e:	50                   	push   %eax
f010312f:	68 f3 03 00 00       	push   $0x3f3
f0103134:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010313a:	50                   	push   %eax
f010313b:	e8 71 cf ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0103140:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103143:	8d 83 4d ab f7 ff    	lea    -0x854b3(%ebx),%eax
f0103149:	50                   	push   %eax
f010314a:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0103150:	50                   	push   %eax
f0103151:	68 f5 03 00 00       	push   $0x3f5
f0103156:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010315c:	50                   	push   %eax
f010315d:	e8 4f cf ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103162:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103165:	8d 83 e0 a3 f7 ff    	lea    -0x85c20(%ebx),%eax
f010316b:	50                   	push   %eax
f010316c:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0103172:	50                   	push   %eax
f0103173:	68 f8 03 00 00       	push   $0x3f8
f0103178:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f010317e:	50                   	push   %eax
f010317f:	e8 2d cf ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0103184:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103187:	8d 83 04 ab f7 ff    	lea    -0x854fc(%ebx),%eax
f010318d:	50                   	push   %eax
f010318e:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0103194:	50                   	push   %eax
f0103195:	68 fa 03 00 00       	push   $0x3fa
f010319a:	8d 83 25 a9 f7 ff    	lea    -0x856db(%ebx),%eax
f01031a0:	50                   	push   %eax
f01031a1:	e8 0b cf ff ff       	call   f01000b1 <_panic>

f01031a6 <tlb_invalidate>:
{
f01031a6:	55                   	push   %ebp
f01031a7:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01031a9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031ac:	0f 01 38             	invlpg (%eax)
}
f01031af:	5d                   	pop    %ebp
f01031b0:	c3                   	ret    

f01031b1 <user_mem_check>:
{
f01031b1:	55                   	push   %ebp
f01031b2:	89 e5                	mov    %esp,%ebp
}
f01031b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01031b9:	5d                   	pop    %ebp
f01031ba:	c3                   	ret    

f01031bb <user_mem_assert>:
{
f01031bb:	55                   	push   %ebp
f01031bc:	89 e5                	mov    %esp,%ebp
}
f01031be:	5d                   	pop    %ebp
f01031bf:	c3                   	ret    

f01031c0 <__x86.get_pc_thunk.dx>:
f01031c0:	8b 14 24             	mov    (%esp),%edx
f01031c3:	c3                   	ret    

f01031c4 <__x86.get_pc_thunk.cx>:
f01031c4:	8b 0c 24             	mov    (%esp),%ecx
f01031c7:	c3                   	ret    

f01031c8 <__x86.get_pc_thunk.si>:
f01031c8:	8b 34 24             	mov    (%esp),%esi
f01031cb:	c3                   	ret    

f01031cc <__x86.get_pc_thunk.di>:
f01031cc:	8b 3c 24             	mov    (%esp),%edi
f01031cf:	c3                   	ret    

f01031d0 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01031d0:	55                   	push   %ebp
f01031d1:	89 e5                	mov    %esp,%ebp
f01031d3:	53                   	push   %ebx
f01031d4:	e8 eb ff ff ff       	call   f01031c4 <__x86.get_pc_thunk.cx>
f01031d9:	81 c1 47 7e 08 00    	add    $0x87e47,%ecx
f01031df:	8b 55 08             	mov    0x8(%ebp),%edx
f01031e2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01031e5:	85 d2                	test   %edx,%edx
f01031e7:	74 41                	je     f010322a <envid2env+0x5a>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01031e9:	89 d0                	mov    %edx,%eax
f01031eb:	25 ff 03 00 00       	and    $0x3ff,%eax
f01031f0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01031f3:	c1 e0 05             	shl    $0x5,%eax
f01031f6:	03 81 24 23 00 00    	add    0x2324(%ecx),%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01031fc:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0103200:	74 3a                	je     f010323c <envid2env+0x6c>
f0103202:	39 50 48             	cmp    %edx,0x48(%eax)
f0103205:	75 35                	jne    f010323c <envid2env+0x6c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103207:	84 db                	test   %bl,%bl
f0103209:	74 12                	je     f010321d <envid2env+0x4d>
f010320b:	8b 91 20 23 00 00    	mov    0x2320(%ecx),%edx
f0103211:	39 c2                	cmp    %eax,%edx
f0103213:	74 08                	je     f010321d <envid2env+0x4d>
f0103215:	8b 5a 48             	mov    0x48(%edx),%ebx
f0103218:	39 58 4c             	cmp    %ebx,0x4c(%eax)
f010321b:	75 2f                	jne    f010324c <envid2env+0x7c>
		*env_store = 0;
		return -E_BAD_ENV;
	}

	*env_store = e;
f010321d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103220:	89 03                	mov    %eax,(%ebx)
	return 0;
f0103222:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103227:	5b                   	pop    %ebx
f0103228:	5d                   	pop    %ebp
f0103229:	c3                   	ret    
		*env_store = curenv;
f010322a:	8b 81 20 23 00 00    	mov    0x2320(%ecx),%eax
f0103230:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103233:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103235:	b8 00 00 00 00       	mov    $0x0,%eax
f010323a:	eb eb                	jmp    f0103227 <envid2env+0x57>
		*env_store = 0;
f010323c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010323f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103245:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010324a:	eb db                	jmp    f0103227 <envid2env+0x57>
		*env_store = 0;
f010324c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010324f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103255:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010325a:	eb cb                	jmp    f0103227 <envid2env+0x57>

f010325c <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010325c:	55                   	push   %ebp
f010325d:	89 e5                	mov    %esp,%ebp
f010325f:	e8 a5 d4 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f0103264:	05 bc 7d 08 00       	add    $0x87dbc,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f0103269:	8d 80 e0 1f 00 00    	lea    0x1fe0(%eax),%eax
f010326f:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103272:	b8 23 00 00 00       	mov    $0x23,%eax
f0103277:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0103279:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010327b:	b8 10 00 00 00       	mov    $0x10,%eax
f0103280:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103282:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103284:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0103286:	ea 8d 32 10 f0 08 00 	ljmp   $0x8,$0xf010328d
	asm volatile("lldt %0" : : "r" (sel));
f010328d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103292:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103295:	5d                   	pop    %ebp
f0103296:	c3                   	ret    

f0103297 <env_init>:
{
f0103297:	55                   	push   %ebp
f0103298:	89 e5                	mov    %esp,%ebp
	env_init_percpu();
f010329a:	e8 bd ff ff ff       	call   f010325c <env_init_percpu>
}
f010329f:	5d                   	pop    %ebp
f01032a0:	c3                   	ret    

f01032a1 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01032a1:	55                   	push   %ebp
f01032a2:	89 e5                	mov    %esp,%ebp
f01032a4:	56                   	push   %esi
f01032a5:	53                   	push   %ebx
f01032a6:	e8 bc ce ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01032ab:	81 c3 75 7d 08 00    	add    $0x87d75,%ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01032b1:	8b b3 28 23 00 00    	mov    0x2328(%ebx),%esi
f01032b7:	85 f6                	test   %esi,%esi
f01032b9:	0f 84 03 01 00 00    	je     f01033c2 <env_alloc+0x121>
	if (!(p = page_alloc(ALLOC_ZERO)))
f01032bf:	83 ec 0c             	sub    $0xc,%esp
f01032c2:	6a 01                	push   $0x1
f01032c4:	e8 88 dd ff ff       	call   f0101051 <page_alloc>
f01032c9:	83 c4 10             	add    $0x10,%esp
f01032cc:	85 c0                	test   %eax,%eax
f01032ce:	0f 84 f5 00 00 00    	je     f01033c9 <env_alloc+0x128>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01032d4:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01032d7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032dc:	0f 86 c7 00 00 00    	jbe    f01033a9 <env_alloc+0x108>
	return (physaddr_t)kva - KERNBASE;
f01032e2:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01032e8:	83 ca 05             	or     $0x5,%edx
f01032eb:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01032f1:	8b 46 48             	mov    0x48(%esi),%eax
f01032f4:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01032f9:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01032fe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103303:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103306:	89 f2                	mov    %esi,%edx
f0103308:	2b 93 24 23 00 00    	sub    0x2324(%ebx),%edx
f010330e:	c1 fa 05             	sar    $0x5,%edx
f0103311:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103317:	09 d0                	or     %edx,%eax
f0103319:	89 46 48             	mov    %eax,0x48(%esi)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f010331c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010331f:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f0103322:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f0103329:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f0103330:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103337:	83 ec 04             	sub    $0x4,%esp
f010333a:	6a 44                	push   $0x44
f010333c:	6a 00                	push   $0x0
f010333e:	56                   	push   %esi
f010333f:	e8 67 14 00 00       	call   f01047ab <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103344:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f010334a:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f0103350:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f0103356:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f010335d:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103363:	8b 46 44             	mov    0x44(%esi),%eax
f0103366:	89 83 28 23 00 00    	mov    %eax,0x2328(%ebx)
	*newenv_store = e;
f010336c:	8b 45 08             	mov    0x8(%ebp),%eax
f010336f:	89 30                	mov    %esi,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103371:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103374:	8b 83 20 23 00 00    	mov    0x2320(%ebx),%eax
f010337a:	83 c4 10             	add    $0x10,%esp
f010337d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103382:	85 c0                	test   %eax,%eax
f0103384:	74 03                	je     f0103389 <env_alloc+0xe8>
f0103386:	8b 50 48             	mov    0x48(%eax),%edx
f0103389:	83 ec 04             	sub    $0x4,%esp
f010338c:	51                   	push   %ecx
f010338d:	52                   	push   %edx
f010338e:	8d 83 49 ac f7 ff    	lea    -0x853b7(%ebx),%eax
f0103394:	50                   	push   %eax
f0103395:	e8 61 03 00 00       	call   f01036fb <cprintf>
	return 0;
f010339a:	83 c4 10             	add    $0x10,%esp
f010339d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033a2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01033a5:	5b                   	pop    %ebx
f01033a6:	5e                   	pop    %esi
f01033a7:	5d                   	pop    %ebp
f01033a8:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033a9:	50                   	push   %eax
f01033aa:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f01033b0:	50                   	push   %eax
f01033b1:	68 b9 00 00 00       	push   $0xb9
f01033b6:	8d 83 3e ac f7 ff    	lea    -0x853c2(%ebx),%eax
f01033bc:	50                   	push   %eax
f01033bd:	e8 ef cc ff ff       	call   f01000b1 <_panic>
		return -E_NO_FREE_ENV;
f01033c2:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01033c7:	eb d9                	jmp    f01033a2 <env_alloc+0x101>
		return -E_NO_MEM;
f01033c9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01033ce:	eb d2                	jmp    f01033a2 <env_alloc+0x101>

f01033d0 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01033d0:	55                   	push   %ebp
f01033d1:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f01033d3:	5d                   	pop    %ebp
f01033d4:	c3                   	ret    

f01033d5 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033d5:	55                   	push   %ebp
f01033d6:	89 e5                	mov    %esp,%ebp
f01033d8:	57                   	push   %edi
f01033d9:	56                   	push   %esi
f01033da:	53                   	push   %ebx
f01033db:	83 ec 2c             	sub    $0x2c,%esp
f01033de:	e8 84 cd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01033e3:	81 c3 3d 7c 08 00    	add    $0x87c3d,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033e9:	8b 93 20 23 00 00    	mov    0x2320(%ebx),%edx
f01033ef:	3b 55 08             	cmp    0x8(%ebp),%edx
f01033f2:	75 17                	jne    f010340b <env_free+0x36>
		lcr3(PADDR(kern_pgdir));
f01033f4:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f01033fa:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01033fc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103401:	76 46                	jbe    f0103449 <env_free+0x74>
	return (physaddr_t)kva - KERNBASE;
f0103403:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103408:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010340b:	8b 45 08             	mov    0x8(%ebp),%eax
f010340e:	8b 48 48             	mov    0x48(%eax),%ecx
f0103411:	b8 00 00 00 00       	mov    $0x0,%eax
f0103416:	85 d2                	test   %edx,%edx
f0103418:	74 03                	je     f010341d <env_free+0x48>
f010341a:	8b 42 48             	mov    0x48(%edx),%eax
f010341d:	83 ec 04             	sub    $0x4,%esp
f0103420:	51                   	push   %ecx
f0103421:	50                   	push   %eax
f0103422:	8d 83 5e ac f7 ff    	lea    -0x853a2(%ebx),%eax
f0103428:	50                   	push   %eax
f0103429:	e8 cd 02 00 00       	call   f01036fb <cprintf>
f010342e:	83 c4 10             	add    $0x10,%esp
f0103431:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	if (PGNUM(pa) >= npages)
f0103438:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f010343e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (PGNUM(pa) >= npages)
f0103441:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103444:	e9 9f 00 00 00       	jmp    f01034e8 <env_free+0x113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103449:	50                   	push   %eax
f010344a:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f0103450:	50                   	push   %eax
f0103451:	68 68 01 00 00       	push   $0x168
f0103456:	8d 83 3e ac f7 ff    	lea    -0x853c2(%ebx),%eax
f010345c:	50                   	push   %eax
f010345d:	e8 4f cc ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103462:	50                   	push   %eax
f0103463:	8d 83 38 a1 f7 ff    	lea    -0x85ec8(%ebx),%eax
f0103469:	50                   	push   %eax
f010346a:	68 77 01 00 00       	push   $0x177
f010346f:	8d 83 3e ac f7 ff    	lea    -0x853c2(%ebx),%eax
f0103475:	50                   	push   %eax
f0103476:	e8 36 cc ff ff       	call   f01000b1 <_panic>
f010347b:	83 c6 04             	add    $0x4,%esi
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010347e:	39 fe                	cmp    %edi,%esi
f0103480:	74 24                	je     f01034a6 <env_free+0xd1>
			if (pt[pteno] & PTE_P)
f0103482:	f6 06 01             	testb  $0x1,(%esi)
f0103485:	74 f4                	je     f010347b <env_free+0xa6>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103487:	83 ec 08             	sub    $0x8,%esp
f010348a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010348d:	01 f0                	add    %esi,%eax
f010348f:	c1 e0 0a             	shl    $0xa,%eax
f0103492:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103495:	50                   	push   %eax
f0103496:	8b 45 08             	mov    0x8(%ebp),%eax
f0103499:	ff 70 5c             	pushl  0x5c(%eax)
f010349c:	e8 57 de ff ff       	call   f01012f8 <page_remove>
f01034a1:	83 c4 10             	add    $0x10,%esp
f01034a4:	eb d5                	jmp    f010347b <env_free+0xa6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01034a9:	8b 40 5c             	mov    0x5c(%eax),%eax
f01034ac:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034af:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f01034b6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01034b9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01034bc:	3b 10                	cmp    (%eax),%edx
f01034be:	73 6f                	jae    f010352f <env_free+0x15a>
		page_decref(pa2page(pa));
f01034c0:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034c3:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f01034c9:	8b 00                	mov    (%eax),%eax
f01034cb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01034ce:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01034d1:	50                   	push   %eax
f01034d2:	e8 51 dc ff ff       	call   f0101128 <page_decref>
f01034d7:	83 c4 10             	add    $0x10,%esp
f01034da:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f01034de:	8b 45 dc             	mov    -0x24(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034e1:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01034e6:	74 5f                	je     f0103547 <env_free+0x172>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01034e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01034eb:	8b 40 5c             	mov    0x5c(%eax),%eax
f01034ee:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034f1:	8b 04 10             	mov    (%eax,%edx,1),%eax
f01034f4:	a8 01                	test   $0x1,%al
f01034f6:	74 e2                	je     f01034da <env_free+0x105>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01034f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01034fd:	89 c2                	mov    %eax,%edx
f01034ff:	c1 ea 0c             	shr    $0xc,%edx
f0103502:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0103505:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103508:	39 11                	cmp    %edx,(%ecx)
f010350a:	0f 86 52 ff ff ff    	jbe    f0103462 <env_free+0x8d>
	return (void *)(pa + KERNBASE);
f0103510:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103516:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103519:	c1 e2 14             	shl    $0x14,%edx
f010351c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010351f:	8d b8 00 10 00 f0    	lea    -0xffff000(%eax),%edi
f0103525:	f7 d8                	neg    %eax
f0103527:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010352a:	e9 53 ff ff ff       	jmp    f0103482 <env_free+0xad>
		panic("pa2page called with invalid pa");
f010352f:	83 ec 04             	sub    $0x4,%esp
f0103532:	8d 83 ac a2 f7 ff    	lea    -0x85d54(%ebx),%eax
f0103538:	50                   	push   %eax
f0103539:	6a 56                	push   $0x56
f010353b:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f0103541:	50                   	push   %eax
f0103542:	e8 6a cb ff ff       	call   f01000b1 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103547:	8b 45 08             	mov    0x8(%ebp),%eax
f010354a:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010354d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103552:	76 57                	jbe    f01035ab <env_free+0x1d6>
	e->env_pgdir = 0;
f0103554:	8b 55 08             	mov    0x8(%ebp),%edx
f0103557:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f010355e:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103563:	c1 e8 0c             	shr    $0xc,%eax
f0103566:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f010356c:	3b 02                	cmp    (%edx),%eax
f010356e:	73 54                	jae    f01035c4 <env_free+0x1ef>
	page_decref(pa2page(pa));
f0103570:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103573:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0103579:	8b 12                	mov    (%edx),%edx
f010357b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010357e:	50                   	push   %eax
f010357f:	e8 a4 db ff ff       	call   f0101128 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103584:	8b 45 08             	mov    0x8(%ebp),%eax
f0103587:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f010358e:	8b 83 28 23 00 00    	mov    0x2328(%ebx),%eax
f0103594:	8b 55 08             	mov    0x8(%ebp),%edx
f0103597:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f010359a:	89 93 28 23 00 00    	mov    %edx,0x2328(%ebx)
}
f01035a0:	83 c4 10             	add    $0x10,%esp
f01035a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01035a6:	5b                   	pop    %ebx
f01035a7:	5e                   	pop    %esi
f01035a8:	5f                   	pop    %edi
f01035a9:	5d                   	pop    %ebp
f01035aa:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035ab:	50                   	push   %eax
f01035ac:	8d 83 44 a2 f7 ff    	lea    -0x85dbc(%ebx),%eax
f01035b2:	50                   	push   %eax
f01035b3:	68 85 01 00 00       	push   $0x185
f01035b8:	8d 83 3e ac f7 ff    	lea    -0x853c2(%ebx),%eax
f01035be:	50                   	push   %eax
f01035bf:	e8 ed ca ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f01035c4:	83 ec 04             	sub    $0x4,%esp
f01035c7:	8d 83 ac a2 f7 ff    	lea    -0x85d54(%ebx),%eax
f01035cd:	50                   	push   %eax
f01035ce:	6a 56                	push   $0x56
f01035d0:	8d 83 31 a9 f7 ff    	lea    -0x856cf(%ebx),%eax
f01035d6:	50                   	push   %eax
f01035d7:	e8 d5 ca ff ff       	call   f01000b1 <_panic>

f01035dc <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01035dc:	55                   	push   %ebp
f01035dd:	89 e5                	mov    %esp,%ebp
f01035df:	53                   	push   %ebx
f01035e0:	83 ec 10             	sub    $0x10,%esp
f01035e3:	e8 7f cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01035e8:	81 c3 38 7a 08 00    	add    $0x87a38,%ebx
	env_free(e);
f01035ee:	ff 75 08             	pushl  0x8(%ebp)
f01035f1:	e8 df fd ff ff       	call   f01033d5 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01035f6:	8d 83 08 ac f7 ff    	lea    -0x853f8(%ebx),%eax
f01035fc:	89 04 24             	mov    %eax,(%esp)
f01035ff:	e8 f7 00 00 00       	call   f01036fb <cprintf>
f0103604:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0103607:	83 ec 0c             	sub    $0xc,%esp
f010360a:	6a 00                	push   $0x0
f010360c:	e8 4e d3 ff ff       	call   f010095f <monitor>
f0103611:	83 c4 10             	add    $0x10,%esp
f0103614:	eb f1                	jmp    f0103607 <env_destroy+0x2b>

f0103616 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103616:	55                   	push   %ebp
f0103617:	89 e5                	mov    %esp,%ebp
f0103619:	53                   	push   %ebx
f010361a:	83 ec 08             	sub    $0x8,%esp
f010361d:	e8 45 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103622:	81 c3 fe 79 08 00    	add    $0x879fe,%ebx
	asm volatile(
f0103628:	8b 65 08             	mov    0x8(%ebp),%esp
f010362b:	61                   	popa   
f010362c:	07                   	pop    %es
f010362d:	1f                   	pop    %ds
f010362e:	83 c4 08             	add    $0x8,%esp
f0103631:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103632:	8d 83 74 ac f7 ff    	lea    -0x8538c(%ebx),%eax
f0103638:	50                   	push   %eax
f0103639:	68 ae 01 00 00       	push   $0x1ae
f010363e:	8d 83 3e ac f7 ff    	lea    -0x853c2(%ebx),%eax
f0103644:	50                   	push   %eax
f0103645:	e8 67 ca ff ff       	call   f01000b1 <_panic>

f010364a <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010364a:	55                   	push   %ebp
f010364b:	89 e5                	mov    %esp,%ebp
f010364d:	53                   	push   %ebx
f010364e:	83 ec 08             	sub    $0x8,%esp
f0103651:	e8 11 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103656:	81 c3 ca 79 08 00    	add    $0x879ca,%ebx
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f010365c:	8d 83 80 ac f7 ff    	lea    -0x85380(%ebx),%eax
f0103662:	50                   	push   %eax
f0103663:	68 cd 01 00 00       	push   $0x1cd
f0103668:	8d 83 3e ac f7 ff    	lea    -0x853c2(%ebx),%eax
f010366e:	50                   	push   %eax
f010366f:	e8 3d ca ff ff       	call   f01000b1 <_panic>

f0103674 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103674:	55                   	push   %ebp
f0103675:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103677:	8b 45 08             	mov    0x8(%ebp),%eax
f010367a:	ba 70 00 00 00       	mov    $0x70,%edx
f010367f:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103680:	ba 71 00 00 00       	mov    $0x71,%edx
f0103685:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103686:	0f b6 c0             	movzbl %al,%eax
}
f0103689:	5d                   	pop    %ebp
f010368a:	c3                   	ret    

f010368b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010368b:	55                   	push   %ebp
f010368c:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010368e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103691:	ba 70 00 00 00       	mov    $0x70,%edx
f0103696:	ee                   	out    %al,(%dx)
f0103697:	8b 45 0c             	mov    0xc(%ebp),%eax
f010369a:	ba 71 00 00 00       	mov    $0x71,%edx
f010369f:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01036a0:	5d                   	pop    %ebp
f01036a1:	c3                   	ret    

f01036a2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01036a2:	55                   	push   %ebp
f01036a3:	89 e5                	mov    %esp,%ebp
f01036a5:	53                   	push   %ebx
f01036a6:	83 ec 10             	sub    $0x10,%esp
f01036a9:	e8 b9 ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01036ae:	81 c3 72 79 08 00    	add    $0x87972,%ebx
	cputchar(ch);
f01036b4:	ff 75 08             	pushl  0x8(%ebp)
f01036b7:	e8 22 d0 ff ff       	call   f01006de <cputchar>
	*cnt++;
}
f01036bc:	83 c4 10             	add    $0x10,%esp
f01036bf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036c2:	c9                   	leave  
f01036c3:	c3                   	ret    

f01036c4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036c4:	55                   	push   %ebp
f01036c5:	89 e5                	mov    %esp,%ebp
f01036c7:	53                   	push   %ebx
f01036c8:	83 ec 14             	sub    $0x14,%esp
f01036cb:	e8 97 ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01036d0:	81 c3 50 79 08 00    	add    $0x87950,%ebx
	int cnt = 0;
f01036d6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01036dd:	ff 75 0c             	pushl  0xc(%ebp)
f01036e0:	ff 75 08             	pushl  0x8(%ebp)
f01036e3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036e6:	50                   	push   %eax
f01036e7:	8d 83 82 86 f7 ff    	lea    -0x8797e(%ebx),%eax
f01036ed:	50                   	push   %eax
f01036ee:	e8 37 09 00 00       	call   f010402a <vprintfmt>
	return cnt;
}
f01036f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036f6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036f9:	c9                   	leave  
f01036fa:	c3                   	ret    

f01036fb <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036fb:	55                   	push   %ebp
f01036fc:	89 e5                	mov    %esp,%ebp
f01036fe:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103701:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103704:	50                   	push   %eax
f0103705:	ff 75 08             	pushl  0x8(%ebp)
f0103708:	e8 b7 ff ff ff       	call   f01036c4 <vcprintf>
	va_end(ap);

	return cnt;
}
f010370d:	c9                   	leave  
f010370e:	c3                   	ret    

f010370f <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010370f:	55                   	push   %ebp
f0103710:	89 e5                	mov    %esp,%ebp
f0103712:	57                   	push   %edi
f0103713:	56                   	push   %esi
f0103714:	53                   	push   %ebx
f0103715:	83 ec 04             	sub    $0x4,%esp
f0103718:	e8 4a ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010371d:	81 c3 03 79 08 00    	add    $0x87903,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103723:	c7 83 64 2b 00 00 00 	movl   $0xf0000000,0x2b64(%ebx)
f010372a:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010372d:	66 c7 83 68 2b 00 00 	movw   $0x10,0x2b68(%ebx)
f0103734:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103736:	66 c7 83 c6 2b 00 00 	movw   $0x68,0x2bc6(%ebx)
f010373d:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f010373f:	c7 c0 00 a3 11 f0    	mov    $0xf011a300,%eax
f0103745:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f010374b:	8d b3 60 2b 00 00    	lea    0x2b60(%ebx),%esi
f0103751:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103755:	89 f2                	mov    %esi,%edx
f0103757:	c1 ea 10             	shr    $0x10,%edx
f010375a:	88 50 2c             	mov    %dl,0x2c(%eax)
f010375d:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103761:	83 e2 f0             	and    $0xfffffff0,%edx
f0103764:	83 ca 09             	or     $0x9,%edx
f0103767:	83 e2 9f             	and    $0xffffff9f,%edx
f010376a:	83 ca 80             	or     $0xffffff80,%edx
f010376d:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103770:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103773:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103777:	83 e1 c0             	and    $0xffffffc0,%ecx
f010377a:	83 c9 40             	or     $0x40,%ecx
f010377d:	83 e1 7f             	and    $0x7f,%ecx
f0103780:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103783:	c1 ee 18             	shr    $0x18,%esi
f0103786:	89 f1                	mov    %esi,%ecx
f0103788:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010378b:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f010378f:	83 e2 ef             	and    $0xffffffef,%edx
f0103792:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103795:	b8 28 00 00 00       	mov    $0x28,%eax
f010379a:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f010379d:	8d 83 e8 1f 00 00    	lea    0x1fe8(%ebx),%eax
f01037a3:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01037a6:	83 c4 04             	add    $0x4,%esp
f01037a9:	5b                   	pop    %ebx
f01037aa:	5e                   	pop    %esi
f01037ab:	5f                   	pop    %edi
f01037ac:	5d                   	pop    %ebp
f01037ad:	c3                   	ret    

f01037ae <trap_init>:
{
f01037ae:	55                   	push   %ebp
f01037af:	89 e5                	mov    %esp,%ebp
	trap_init_percpu();
f01037b1:	e8 59 ff ff ff       	call   f010370f <trap_init_percpu>
}
f01037b6:	5d                   	pop    %ebp
f01037b7:	c3                   	ret    

f01037b8 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01037b8:	55                   	push   %ebp
f01037b9:	89 e5                	mov    %esp,%ebp
f01037bb:	56                   	push   %esi
f01037bc:	53                   	push   %ebx
f01037bd:	e8 a5 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01037c2:	81 c3 5e 78 08 00    	add    $0x8785e,%ebx
f01037c8:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01037cb:	83 ec 08             	sub    $0x8,%esp
f01037ce:	ff 36                	pushl  (%esi)
f01037d0:	8d 83 9c ac f7 ff    	lea    -0x85364(%ebx),%eax
f01037d6:	50                   	push   %eax
f01037d7:	e8 1f ff ff ff       	call   f01036fb <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01037dc:	83 c4 08             	add    $0x8,%esp
f01037df:	ff 76 04             	pushl  0x4(%esi)
f01037e2:	8d 83 ab ac f7 ff    	lea    -0x85355(%ebx),%eax
f01037e8:	50                   	push   %eax
f01037e9:	e8 0d ff ff ff       	call   f01036fb <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01037ee:	83 c4 08             	add    $0x8,%esp
f01037f1:	ff 76 08             	pushl  0x8(%esi)
f01037f4:	8d 83 ba ac f7 ff    	lea    -0x85346(%ebx),%eax
f01037fa:	50                   	push   %eax
f01037fb:	e8 fb fe ff ff       	call   f01036fb <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103800:	83 c4 08             	add    $0x8,%esp
f0103803:	ff 76 0c             	pushl  0xc(%esi)
f0103806:	8d 83 c9 ac f7 ff    	lea    -0x85337(%ebx),%eax
f010380c:	50                   	push   %eax
f010380d:	e8 e9 fe ff ff       	call   f01036fb <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103812:	83 c4 08             	add    $0x8,%esp
f0103815:	ff 76 10             	pushl  0x10(%esi)
f0103818:	8d 83 d8 ac f7 ff    	lea    -0x85328(%ebx),%eax
f010381e:	50                   	push   %eax
f010381f:	e8 d7 fe ff ff       	call   f01036fb <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103824:	83 c4 08             	add    $0x8,%esp
f0103827:	ff 76 14             	pushl  0x14(%esi)
f010382a:	8d 83 e7 ac f7 ff    	lea    -0x85319(%ebx),%eax
f0103830:	50                   	push   %eax
f0103831:	e8 c5 fe ff ff       	call   f01036fb <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103836:	83 c4 08             	add    $0x8,%esp
f0103839:	ff 76 18             	pushl  0x18(%esi)
f010383c:	8d 83 f6 ac f7 ff    	lea    -0x8530a(%ebx),%eax
f0103842:	50                   	push   %eax
f0103843:	e8 b3 fe ff ff       	call   f01036fb <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103848:	83 c4 08             	add    $0x8,%esp
f010384b:	ff 76 1c             	pushl  0x1c(%esi)
f010384e:	8d 83 05 ad f7 ff    	lea    -0x852fb(%ebx),%eax
f0103854:	50                   	push   %eax
f0103855:	e8 a1 fe ff ff       	call   f01036fb <cprintf>
}
f010385a:	83 c4 10             	add    $0x10,%esp
f010385d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103860:	5b                   	pop    %ebx
f0103861:	5e                   	pop    %esi
f0103862:	5d                   	pop    %ebp
f0103863:	c3                   	ret    

f0103864 <print_trapframe>:
{
f0103864:	55                   	push   %ebp
f0103865:	89 e5                	mov    %esp,%ebp
f0103867:	57                   	push   %edi
f0103868:	56                   	push   %esi
f0103869:	53                   	push   %ebx
f010386a:	83 ec 14             	sub    $0x14,%esp
f010386d:	e8 f5 c8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103872:	81 c3 ae 77 08 00    	add    $0x877ae,%ebx
f0103878:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f010387b:	56                   	push   %esi
f010387c:	8d 83 3b ae f7 ff    	lea    -0x851c5(%ebx),%eax
f0103882:	50                   	push   %eax
f0103883:	e8 73 fe ff ff       	call   f01036fb <cprintf>
	print_regs(&tf->tf_regs);
f0103888:	89 34 24             	mov    %esi,(%esp)
f010388b:	e8 28 ff ff ff       	call   f01037b8 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103890:	83 c4 08             	add    $0x8,%esp
f0103893:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103897:	50                   	push   %eax
f0103898:	8d 83 56 ad f7 ff    	lea    -0x852aa(%ebx),%eax
f010389e:	50                   	push   %eax
f010389f:	e8 57 fe ff ff       	call   f01036fb <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01038a4:	83 c4 08             	add    $0x8,%esp
f01038a7:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f01038ab:	50                   	push   %eax
f01038ac:	8d 83 69 ad f7 ff    	lea    -0x85297(%ebx),%eax
f01038b2:	50                   	push   %eax
f01038b3:	e8 43 fe ff ff       	call   f01036fb <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01038b8:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f01038bb:	83 c4 10             	add    $0x10,%esp
f01038be:	83 fa 13             	cmp    $0x13,%edx
f01038c1:	0f 86 e9 00 00 00    	jbe    f01039b0 <print_trapframe+0x14c>
	return "(unknown trap)";
f01038c7:	83 fa 30             	cmp    $0x30,%edx
f01038ca:	8d 83 14 ad f7 ff    	lea    -0x852ec(%ebx),%eax
f01038d0:	8d 8b 20 ad f7 ff    	lea    -0x852e0(%ebx),%ecx
f01038d6:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01038d9:	83 ec 04             	sub    $0x4,%esp
f01038dc:	50                   	push   %eax
f01038dd:	52                   	push   %edx
f01038de:	8d 83 7c ad f7 ff    	lea    -0x85284(%ebx),%eax
f01038e4:	50                   	push   %eax
f01038e5:	e8 11 fe ff ff       	call   f01036fb <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01038ea:	83 c4 10             	add    $0x10,%esp
f01038ed:	39 b3 40 2b 00 00    	cmp    %esi,0x2b40(%ebx)
f01038f3:	0f 84 c3 00 00 00    	je     f01039bc <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
f01038f9:	83 ec 08             	sub    $0x8,%esp
f01038fc:	ff 76 2c             	pushl  0x2c(%esi)
f01038ff:	8d 83 9d ad f7 ff    	lea    -0x85263(%ebx),%eax
f0103905:	50                   	push   %eax
f0103906:	e8 f0 fd ff ff       	call   f01036fb <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f010390b:	83 c4 10             	add    $0x10,%esp
f010390e:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103912:	0f 85 c9 00 00 00    	jne    f01039e1 <print_trapframe+0x17d>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103918:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f010391b:	89 c2                	mov    %eax,%edx
f010391d:	83 e2 01             	and    $0x1,%edx
f0103920:	8d 8b 2f ad f7 ff    	lea    -0x852d1(%ebx),%ecx
f0103926:	8d 93 3a ad f7 ff    	lea    -0x852c6(%ebx),%edx
f010392c:	0f 44 ca             	cmove  %edx,%ecx
f010392f:	89 c2                	mov    %eax,%edx
f0103931:	83 e2 02             	and    $0x2,%edx
f0103934:	8d 93 46 ad f7 ff    	lea    -0x852ba(%ebx),%edx
f010393a:	8d bb 4c ad f7 ff    	lea    -0x852b4(%ebx),%edi
f0103940:	0f 44 d7             	cmove  %edi,%edx
f0103943:	83 e0 04             	and    $0x4,%eax
f0103946:	8d 83 51 ad f7 ff    	lea    -0x852af(%ebx),%eax
f010394c:	8d bb 66 ae f7 ff    	lea    -0x8519a(%ebx),%edi
f0103952:	0f 44 c7             	cmove  %edi,%eax
f0103955:	51                   	push   %ecx
f0103956:	52                   	push   %edx
f0103957:	50                   	push   %eax
f0103958:	8d 83 ab ad f7 ff    	lea    -0x85255(%ebx),%eax
f010395e:	50                   	push   %eax
f010395f:	e8 97 fd ff ff       	call   f01036fb <cprintf>
f0103964:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103967:	83 ec 08             	sub    $0x8,%esp
f010396a:	ff 76 30             	pushl  0x30(%esi)
f010396d:	8d 83 ba ad f7 ff    	lea    -0x85246(%ebx),%eax
f0103973:	50                   	push   %eax
f0103974:	e8 82 fd ff ff       	call   f01036fb <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103979:	83 c4 08             	add    $0x8,%esp
f010397c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103980:	50                   	push   %eax
f0103981:	8d 83 c9 ad f7 ff    	lea    -0x85237(%ebx),%eax
f0103987:	50                   	push   %eax
f0103988:	e8 6e fd ff ff       	call   f01036fb <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010398d:	83 c4 08             	add    $0x8,%esp
f0103990:	ff 76 38             	pushl  0x38(%esi)
f0103993:	8d 83 dc ad f7 ff    	lea    -0x85224(%ebx),%eax
f0103999:	50                   	push   %eax
f010399a:	e8 5c fd ff ff       	call   f01036fb <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010399f:	83 c4 10             	add    $0x10,%esp
f01039a2:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f01039a6:	75 50                	jne    f01039f8 <print_trapframe+0x194>
}
f01039a8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039ab:	5b                   	pop    %ebx
f01039ac:	5e                   	pop    %esi
f01039ad:	5f                   	pop    %edi
f01039ae:	5d                   	pop    %ebp
f01039af:	c3                   	ret    
		return excnames[trapno];
f01039b0:	8b 84 93 60 20 00 00 	mov    0x2060(%ebx,%edx,4),%eax
f01039b7:	e9 1d ff ff ff       	jmp    f01038d9 <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01039bc:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01039c0:	0f 85 33 ff ff ff    	jne    f01038f9 <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01039c6:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01039c9:	83 ec 08             	sub    $0x8,%esp
f01039cc:	50                   	push   %eax
f01039cd:	8d 83 8e ad f7 ff    	lea    -0x85272(%ebx),%eax
f01039d3:	50                   	push   %eax
f01039d4:	e8 22 fd ff ff       	call   f01036fb <cprintf>
f01039d9:	83 c4 10             	add    $0x10,%esp
f01039dc:	e9 18 ff ff ff       	jmp    f01038f9 <print_trapframe+0x95>
		cprintf("\n");
f01039e1:	83 ec 0c             	sub    $0xc,%esp
f01039e4:	8d 83 d6 ab f7 ff    	lea    -0x8542a(%ebx),%eax
f01039ea:	50                   	push   %eax
f01039eb:	e8 0b fd ff ff       	call   f01036fb <cprintf>
f01039f0:	83 c4 10             	add    $0x10,%esp
f01039f3:	e9 6f ff ff ff       	jmp    f0103967 <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01039f8:	83 ec 08             	sub    $0x8,%esp
f01039fb:	ff 76 3c             	pushl  0x3c(%esi)
f01039fe:	8d 83 eb ad f7 ff    	lea    -0x85215(%ebx),%eax
f0103a04:	50                   	push   %eax
f0103a05:	e8 f1 fc ff ff       	call   f01036fb <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103a0a:	83 c4 08             	add    $0x8,%esp
f0103a0d:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f0103a11:	50                   	push   %eax
f0103a12:	8d 83 fa ad f7 ff    	lea    -0x85206(%ebx),%eax
f0103a18:	50                   	push   %eax
f0103a19:	e8 dd fc ff ff       	call   f01036fb <cprintf>
f0103a1e:	83 c4 10             	add    $0x10,%esp
}
f0103a21:	eb 85                	jmp    f01039a8 <print_trapframe+0x144>

f0103a23 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103a23:	55                   	push   %ebp
f0103a24:	89 e5                	mov    %esp,%ebp
f0103a26:	57                   	push   %edi
f0103a27:	56                   	push   %esi
f0103a28:	53                   	push   %ebx
f0103a29:	83 ec 0c             	sub    $0xc,%esp
f0103a2c:	e8 36 c7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103a31:	81 c3 ef 75 08 00    	add    $0x875ef,%ebx
f0103a37:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103a3a:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103a3b:	9c                   	pushf  
f0103a3c:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103a3d:	f6 c4 02             	test   $0x2,%ah
f0103a40:	74 1f                	je     f0103a61 <trap+0x3e>
f0103a42:	8d 83 0d ae f7 ff    	lea    -0x851f3(%ebx),%eax
f0103a48:	50                   	push   %eax
f0103a49:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0103a4f:	50                   	push   %eax
f0103a50:	68 a8 00 00 00       	push   $0xa8
f0103a55:	8d 83 26 ae f7 ff    	lea    -0x851da(%ebx),%eax
f0103a5b:	50                   	push   %eax
f0103a5c:	e8 50 c6 ff ff       	call   f01000b1 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103a61:	83 ec 08             	sub    $0x8,%esp
f0103a64:	56                   	push   %esi
f0103a65:	8d 83 32 ae f7 ff    	lea    -0x851ce(%ebx),%eax
f0103a6b:	50                   	push   %eax
f0103a6c:	e8 8a fc ff ff       	call   f01036fb <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103a71:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103a75:	83 e0 03             	and    $0x3,%eax
f0103a78:	83 c4 10             	add    $0x10,%esp
f0103a7b:	66 83 f8 03          	cmp    $0x3,%ax
f0103a7f:	75 1d                	jne    f0103a9e <trap+0x7b>
		// Trapped from user mode.
		assert(curenv);
f0103a81:	c7 c0 40 d3 18 f0    	mov    $0xf018d340,%eax
f0103a87:	8b 00                	mov    (%eax),%eax
f0103a89:	85 c0                	test   %eax,%eax
f0103a8b:	74 68                	je     f0103af5 <trap+0xd2>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103a8d:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103a92:	89 c7                	mov    %eax,%edi
f0103a94:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103a96:	c7 c0 40 d3 18 f0    	mov    $0xf018d340,%eax
f0103a9c:	8b 30                	mov    (%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103a9e:	89 b3 40 2b 00 00    	mov    %esi,0x2b40(%ebx)
	print_trapframe(tf);
f0103aa4:	83 ec 0c             	sub    $0xc,%esp
f0103aa7:	56                   	push   %esi
f0103aa8:	e8 b7 fd ff ff       	call   f0103864 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103aad:	83 c4 10             	add    $0x10,%esp
f0103ab0:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103ab5:	74 5d                	je     f0103b14 <trap+0xf1>
		env_destroy(curenv);
f0103ab7:	83 ec 0c             	sub    $0xc,%esp
f0103aba:	c7 c6 40 d3 18 f0    	mov    $0xf018d340,%esi
f0103ac0:	ff 36                	pushl  (%esi)
f0103ac2:	e8 15 fb ff ff       	call   f01035dc <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103ac7:	8b 06                	mov    (%esi),%eax
f0103ac9:	83 c4 10             	add    $0x10,%esp
f0103acc:	85 c0                	test   %eax,%eax
f0103ace:	74 06                	je     f0103ad6 <trap+0xb3>
f0103ad0:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ad4:	74 59                	je     f0103b2f <trap+0x10c>
f0103ad6:	8d 83 b0 af f7 ff    	lea    -0x85050(%ebx),%eax
f0103adc:	50                   	push   %eax
f0103add:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0103ae3:	50                   	push   %eax
f0103ae4:	68 c0 00 00 00       	push   $0xc0
f0103ae9:	8d 83 26 ae f7 ff    	lea    -0x851da(%ebx),%eax
f0103aef:	50                   	push   %eax
f0103af0:	e8 bc c5 ff ff       	call   f01000b1 <_panic>
		assert(curenv);
f0103af5:	8d 83 4d ae f7 ff    	lea    -0x851b3(%ebx),%eax
f0103afb:	50                   	push   %eax
f0103afc:	8d 83 4b a9 f7 ff    	lea    -0x856b5(%ebx),%eax
f0103b02:	50                   	push   %eax
f0103b03:	68 ae 00 00 00       	push   $0xae
f0103b08:	8d 83 26 ae f7 ff    	lea    -0x851da(%ebx),%eax
f0103b0e:	50                   	push   %eax
f0103b0f:	e8 9d c5 ff ff       	call   f01000b1 <_panic>
		panic("unhandled trap in kernel");
f0103b14:	83 ec 04             	sub    $0x4,%esp
f0103b17:	8d 83 54 ae f7 ff    	lea    -0x851ac(%ebx),%eax
f0103b1d:	50                   	push   %eax
f0103b1e:	68 97 00 00 00       	push   $0x97
f0103b23:	8d 83 26 ae f7 ff    	lea    -0x851da(%ebx),%eax
f0103b29:	50                   	push   %eax
f0103b2a:	e8 82 c5 ff ff       	call   f01000b1 <_panic>
	env_run(curenv);
f0103b2f:	83 ec 0c             	sub    $0xc,%esp
f0103b32:	50                   	push   %eax
f0103b33:	e8 12 fb ff ff       	call   f010364a <env_run>

f0103b38 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103b38:	55                   	push   %ebp
f0103b39:	89 e5                	mov    %esp,%ebp
f0103b3b:	57                   	push   %edi
f0103b3c:	56                   	push   %esi
f0103b3d:	53                   	push   %ebx
f0103b3e:	83 ec 0c             	sub    $0xc,%esp
f0103b41:	e8 21 c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b46:	81 c3 da 74 08 00    	add    $0x874da,%ebx
f0103b4c:	8b 7d 08             	mov    0x8(%ebp),%edi
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103b4f:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b52:	ff 77 30             	pushl  0x30(%edi)
f0103b55:	50                   	push   %eax
f0103b56:	c7 c6 40 d3 18 f0    	mov    $0xf018d340,%esi
f0103b5c:	8b 06                	mov    (%esi),%eax
f0103b5e:	ff 70 48             	pushl  0x48(%eax)
f0103b61:	8d 83 dc af f7 ff    	lea    -0x85024(%ebx),%eax
f0103b67:	50                   	push   %eax
f0103b68:	e8 8e fb ff ff       	call   f01036fb <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103b6d:	89 3c 24             	mov    %edi,(%esp)
f0103b70:	e8 ef fc ff ff       	call   f0103864 <print_trapframe>
	env_destroy(curenv);
f0103b75:	83 c4 04             	add    $0x4,%esp
f0103b78:	ff 36                	pushl  (%esi)
f0103b7a:	e8 5d fa ff ff       	call   f01035dc <env_destroy>
}
f0103b7f:	83 c4 10             	add    $0x10,%esp
f0103b82:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b85:	5b                   	pop    %ebx
f0103b86:	5e                   	pop    %esi
f0103b87:	5f                   	pop    %edi
f0103b88:	5d                   	pop    %ebp
f0103b89:	c3                   	ret    

f0103b8a <syscall>:
f0103b8a:	55                   	push   %ebp
f0103b8b:	89 e5                	mov    %esp,%ebp
f0103b8d:	53                   	push   %ebx
f0103b8e:	83 ec 08             	sub    $0x8,%esp
f0103b91:	e8 d1 c5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b96:	81 c3 8a 74 08 00    	add    $0x8748a,%ebx
f0103b9c:	8d 83 00 b0 f7 ff    	lea    -0x85000(%ebx),%eax
f0103ba2:	50                   	push   %eax
f0103ba3:	6a 49                	push   $0x49
f0103ba5:	8d 83 18 b0 f7 ff    	lea    -0x84fe8(%ebx),%eax
f0103bab:	50                   	push   %eax
f0103bac:	e8 00 c5 ff ff       	call   f01000b1 <_panic>

f0103bb1 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103bb1:	55                   	push   %ebp
f0103bb2:	89 e5                	mov    %esp,%ebp
f0103bb4:	57                   	push   %edi
f0103bb5:	56                   	push   %esi
f0103bb6:	53                   	push   %ebx
f0103bb7:	83 ec 14             	sub    $0x14,%esp
f0103bba:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103bbd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103bc0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103bc3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103bc6:	8b 32                	mov    (%edx),%esi
f0103bc8:	8b 01                	mov    (%ecx),%eax
f0103bca:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103bcd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103bd4:	eb 2f                	jmp    f0103c05 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103bd6:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103bd9:	39 c6                	cmp    %eax,%esi
f0103bdb:	7f 49                	jg     f0103c26 <stab_binsearch+0x75>
f0103bdd:	0f b6 0a             	movzbl (%edx),%ecx
f0103be0:	83 ea 0c             	sub    $0xc,%edx
f0103be3:	39 f9                	cmp    %edi,%ecx
f0103be5:	75 ef                	jne    f0103bd6 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103be7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103bea:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103bed:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103bf1:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103bf4:	73 35                	jae    f0103c2b <stab_binsearch+0x7a>
			*region_left = m;
f0103bf6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103bf9:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0103bfb:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0103bfe:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103c05:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103c08:	7f 4e                	jg     f0103c58 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0103c0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103c0d:	01 f0                	add    %esi,%eax
f0103c0f:	89 c3                	mov    %eax,%ebx
f0103c11:	c1 eb 1f             	shr    $0x1f,%ebx
f0103c14:	01 c3                	add    %eax,%ebx
f0103c16:	d1 fb                	sar    %ebx
f0103c18:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103c1b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103c1e:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103c22:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0103c24:	eb b3                	jmp    f0103bd9 <stab_binsearch+0x28>
			l = true_m + 1;
f0103c26:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103c29:	eb da                	jmp    f0103c05 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0103c2b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103c2e:	76 14                	jbe    f0103c44 <stab_binsearch+0x93>
			*region_right = m - 1;
f0103c30:	83 e8 01             	sub    $0x1,%eax
f0103c33:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103c36:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103c39:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103c3b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103c42:	eb c1                	jmp    f0103c05 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103c44:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103c47:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103c49:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103c4d:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0103c4f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103c56:	eb ad                	jmp    f0103c05 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103c58:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103c5c:	74 16                	je     f0103c74 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103c5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c61:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103c63:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103c66:	8b 0e                	mov    (%esi),%ecx
f0103c68:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103c6b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103c6e:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0103c72:	eb 12                	jmp    f0103c86 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103c74:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103c77:	8b 00                	mov    (%eax),%eax
f0103c79:	83 e8 01             	sub    $0x1,%eax
f0103c7c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103c7f:	89 07                	mov    %eax,(%edi)
f0103c81:	eb 16                	jmp    f0103c99 <stab_binsearch+0xe8>
		     l--)
f0103c83:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103c86:	39 c1                	cmp    %eax,%ecx
f0103c88:	7d 0a                	jge    f0103c94 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103c8a:	0f b6 1a             	movzbl (%edx),%ebx
f0103c8d:	83 ea 0c             	sub    $0xc,%edx
f0103c90:	39 fb                	cmp    %edi,%ebx
f0103c92:	75 ef                	jne    f0103c83 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103c94:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c97:	89 07                	mov    %eax,(%edi)
	}
}
f0103c99:	83 c4 14             	add    $0x14,%esp
f0103c9c:	5b                   	pop    %ebx
f0103c9d:	5e                   	pop    %esi
f0103c9e:	5f                   	pop    %edi
f0103c9f:	5d                   	pop    %ebp
f0103ca0:	c3                   	ret    

f0103ca1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103ca1:	55                   	push   %ebp
f0103ca2:	89 e5                	mov    %esp,%ebp
f0103ca4:	57                   	push   %edi
f0103ca5:	56                   	push   %esi
f0103ca6:	53                   	push   %ebx
f0103ca7:	83 ec 4c             	sub    $0x4c,%esp
f0103caa:	e8 1d f5 ff ff       	call   f01031cc <__x86.get_pc_thunk.di>
f0103caf:	81 c7 71 73 08 00    	add    $0x87371,%edi
f0103cb5:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103cb8:	8d 87 27 b0 f7 ff    	lea    -0x84fd9(%edi),%eax
f0103cbe:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0103cc0:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103cc7:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103cca:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103cd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cd4:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f0103cd7:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103cde:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0103ce3:	0f 87 2c 01 00 00    	ja     f0103e15 <debuginfo_eip+0x174>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103ce9:	a1 00 00 20 00       	mov    0x200000,%eax
f0103cee:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = usd->stab_end;
f0103cf1:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103cf6:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0103cfc:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f0103cff:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f0103d05:	89 5d bc             	mov    %ebx,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103d08:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103d0b:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f0103d0e:	0f 83 e9 01 00 00    	jae    f0103efd <debuginfo_eip+0x25c>
f0103d14:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0103d18:	0f 85 e6 01 00 00    	jne    f0103f04 <debuginfo_eip+0x263>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103d1e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103d25:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f0103d28:	29 d8                	sub    %ebx,%eax
f0103d2a:	c1 f8 02             	sar    $0x2,%eax
f0103d2d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103d33:	83 e8 01             	sub    $0x1,%eax
f0103d36:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103d39:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103d3c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103d3f:	ff 75 08             	pushl  0x8(%ebp)
f0103d42:	6a 64                	push   $0x64
f0103d44:	89 d8                	mov    %ebx,%eax
f0103d46:	e8 66 fe ff ff       	call   f0103bb1 <stab_binsearch>
	if (lfile == 0)
f0103d4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103d4e:	83 c4 08             	add    $0x8,%esp
f0103d51:	85 c0                	test   %eax,%eax
f0103d53:	0f 84 b2 01 00 00    	je     f0103f0b <debuginfo_eip+0x26a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103d59:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103d5c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d5f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103d62:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103d65:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103d68:	ff 75 08             	pushl  0x8(%ebp)
f0103d6b:	6a 24                	push   $0x24
f0103d6d:	89 d8                	mov    %ebx,%eax
f0103d6f:	e8 3d fe ff ff       	call   f0103bb1 <stab_binsearch>

	if (lfun <= rfun) {
f0103d74:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103d77:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103d7a:	83 c4 08             	add    $0x8,%esp
f0103d7d:	39 d0                	cmp    %edx,%eax
f0103d7f:	0f 8f b6 00 00 00    	jg     f0103e3b <debuginfo_eip+0x19a>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103d85:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0103d88:	8d 1c 8b             	lea    (%ebx,%ecx,4),%ebx
f0103d8b:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f0103d8e:	8b 0b                	mov    (%ebx),%ecx
f0103d90:	89 cb                	mov    %ecx,%ebx
f0103d92:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103d95:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f0103d98:	39 cb                	cmp    %ecx,%ebx
f0103d9a:	73 06                	jae    f0103da2 <debuginfo_eip+0x101>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103d9c:	03 5d b4             	add    -0x4c(%ebp),%ebx
f0103d9f:	89 5e 08             	mov    %ebx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103da2:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103da5:	8b 4b 08             	mov    0x8(%ebx),%ecx
f0103da8:	89 4e 10             	mov    %ecx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103dab:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0103dae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103db1:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103db4:	83 ec 08             	sub    $0x8,%esp
f0103db7:	6a 3a                	push   $0x3a
f0103db9:	ff 76 08             	pushl  0x8(%esi)
f0103dbc:	89 fb                	mov    %edi,%ebx
f0103dbe:	e8 cc 09 00 00       	call   f010478f <strfind>
f0103dc3:	2b 46 08             	sub    0x8(%esi),%eax
f0103dc6:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103dc9:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103dcc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103dcf:	83 c4 08             	add    $0x8,%esp
f0103dd2:	ff 75 08             	pushl  0x8(%ebp)
f0103dd5:	6a 44                	push   $0x44
f0103dd7:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103dda:	89 f8                	mov    %edi,%eax
f0103ddc:	e8 d0 fd ff ff       	call   f0103bb1 <stab_binsearch>
	if(lline<=rline){
f0103de1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103de4:	83 c4 10             	add    $0x10,%esp
f0103de7:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103dea:	0f 8f 22 01 00 00    	jg     f0103f12 <debuginfo_eip+0x271>
		info->eip_line = stabs[lline].n_desc;
f0103df0:	89 d0                	mov    %edx,%eax
f0103df2:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103df5:	c1 e2 02             	shl    $0x2,%edx
f0103df8:	0f b7 4c 17 06       	movzwl 0x6(%edi,%edx,1),%ecx
f0103dfd:	89 4e 04             	mov    %ecx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103e00:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103e03:	8d 54 17 04          	lea    0x4(%edi,%edx,1),%edx
f0103e07:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103e0b:	bf 01 00 00 00       	mov    $0x1,%edi
f0103e10:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103e13:	eb 48                	jmp    f0103e5d <debuginfo_eip+0x1bc>
		stabstr_end = __STABSTR_END__;
f0103e15:	c7 c0 7c 0d 11 f0    	mov    $0xf0110d7c,%eax
f0103e1b:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0103e1e:	c7 c0 8d e3 10 f0    	mov    $0xf010e38d,%eax
f0103e24:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stab_end = __STAB_END__;
f0103e27:	c7 c0 8c e3 10 f0    	mov    $0xf010e38c,%eax
		stabs = __STAB_BEGIN__;
f0103e2d:	c7 c3 44 62 10 f0    	mov    $0xf0106244,%ebx
f0103e33:	89 5d b8             	mov    %ebx,-0x48(%ebp)
f0103e36:	e9 cd fe ff ff       	jmp    f0103d08 <debuginfo_eip+0x67>
		info->eip_fn_addr = addr;
f0103e3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e3e:	89 46 10             	mov    %eax,0x10(%esi)
		lline = lfile;
f0103e41:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103e44:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103e47:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e4a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103e4d:	e9 62 ff ff ff       	jmp    f0103db4 <debuginfo_eip+0x113>
f0103e52:	83 e8 01             	sub    $0x1,%eax
f0103e55:	83 ea 0c             	sub    $0xc,%edx
f0103e58:	89 f9                	mov    %edi,%ecx
f0103e5a:	88 4d c4             	mov    %cl,-0x3c(%ebp)
f0103e5d:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0103e60:	39 c3                	cmp    %eax,%ebx
f0103e62:	7f 24                	jg     f0103e88 <debuginfo_eip+0x1e7>
	       && stabs[lline].n_type != N_SOL
f0103e64:	0f b6 0a             	movzbl (%edx),%ecx
f0103e67:	80 f9 84             	cmp    $0x84,%cl
f0103e6a:	74 46                	je     f0103eb2 <debuginfo_eip+0x211>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103e6c:	80 f9 64             	cmp    $0x64,%cl
f0103e6f:	75 e1                	jne    f0103e52 <debuginfo_eip+0x1b1>
f0103e71:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0103e75:	74 db                	je     f0103e52 <debuginfo_eip+0x1b1>
f0103e77:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e7a:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103e7e:	74 3b                	je     f0103ebb <debuginfo_eip+0x21a>
f0103e80:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103e83:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e86:	eb 33                	jmp    f0103ebb <debuginfo_eip+0x21a>
f0103e88:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103e8b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103e8e:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103e91:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103e96:	39 da                	cmp    %ebx,%edx
f0103e98:	0f 8d 80 00 00 00    	jge    f0103f1e <debuginfo_eip+0x27d>
		for (lline = lfun + 1;
f0103e9e:	83 c2 01             	add    $0x1,%edx
f0103ea1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103ea4:	89 d0                	mov    %edx,%eax
f0103ea6:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103ea9:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103eac:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0103eb0:	eb 32                	jmp    f0103ee4 <debuginfo_eip+0x243>
f0103eb2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103eb5:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103eb9:	75 1d                	jne    f0103ed8 <debuginfo_eip+0x237>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103ebb:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103ebe:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103ec1:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103ec4:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103ec7:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f0103eca:	29 f8                	sub    %edi,%eax
f0103ecc:	39 c2                	cmp    %eax,%edx
f0103ece:	73 bb                	jae    f0103e8b <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103ed0:	89 f8                	mov    %edi,%eax
f0103ed2:	01 d0                	add    %edx,%eax
f0103ed4:	89 06                	mov    %eax,(%esi)
f0103ed6:	eb b3                	jmp    f0103e8b <debuginfo_eip+0x1ea>
f0103ed8:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103edb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103ede:	eb db                	jmp    f0103ebb <debuginfo_eip+0x21a>
			info->eip_fn_narg++;
f0103ee0:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0103ee4:	39 c3                	cmp    %eax,%ebx
f0103ee6:	7e 31                	jle    f0103f19 <debuginfo_eip+0x278>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103ee8:	0f b6 0a             	movzbl (%edx),%ecx
f0103eeb:	83 c0 01             	add    $0x1,%eax
f0103eee:	83 c2 0c             	add    $0xc,%edx
f0103ef1:	80 f9 a0             	cmp    $0xa0,%cl
f0103ef4:	74 ea                	je     f0103ee0 <debuginfo_eip+0x23f>
	return 0;
f0103ef6:	b8 00 00 00 00       	mov    $0x0,%eax
f0103efb:	eb 21                	jmp    f0103f1e <debuginfo_eip+0x27d>
		return -1;
f0103efd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103f02:	eb 1a                	jmp    f0103f1e <debuginfo_eip+0x27d>
f0103f04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103f09:	eb 13                	jmp    f0103f1e <debuginfo_eip+0x27d>
		return -1;
f0103f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103f10:	eb 0c                	jmp    f0103f1e <debuginfo_eip+0x27d>
		return -1;
f0103f12:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103f17:	eb 05                	jmp    f0103f1e <debuginfo_eip+0x27d>
	return 0;
f0103f19:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103f1e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f21:	5b                   	pop    %ebx
f0103f22:	5e                   	pop    %esi
f0103f23:	5f                   	pop    %edi
f0103f24:	5d                   	pop    %ebp
f0103f25:	c3                   	ret    

f0103f26 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103f26:	55                   	push   %ebp
f0103f27:	89 e5                	mov    %esp,%ebp
f0103f29:	57                   	push   %edi
f0103f2a:	56                   	push   %esi
f0103f2b:	53                   	push   %ebx
f0103f2c:	83 ec 2c             	sub    $0x2c,%esp
f0103f2f:	e8 90 f2 ff ff       	call   f01031c4 <__x86.get_pc_thunk.cx>
f0103f34:	81 c1 ec 70 08 00    	add    $0x870ec,%ecx
f0103f3a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103f3d:	89 c7                	mov    %eax,%edi
f0103f3f:	89 d6                	mov    %edx,%esi
f0103f41:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f44:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103f47:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103f4a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103f4d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103f50:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103f55:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0103f58:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0103f5b:	39 d3                	cmp    %edx,%ebx
f0103f5d:	72 09                	jb     f0103f68 <printnum+0x42>
f0103f5f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103f62:	0f 87 83 00 00 00    	ja     f0103feb <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103f68:	83 ec 0c             	sub    $0xc,%esp
f0103f6b:	ff 75 18             	pushl  0x18(%ebp)
f0103f6e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f71:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103f74:	53                   	push   %ebx
f0103f75:	ff 75 10             	pushl  0x10(%ebp)
f0103f78:	83 ec 08             	sub    $0x8,%esp
f0103f7b:	ff 75 dc             	pushl  -0x24(%ebp)
f0103f7e:	ff 75 d8             	pushl  -0x28(%ebp)
f0103f81:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103f84:	ff 75 d0             	pushl  -0x30(%ebp)
f0103f87:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103f8a:	e8 21 0a 00 00       	call   f01049b0 <__udivdi3>
f0103f8f:	83 c4 18             	add    $0x18,%esp
f0103f92:	52                   	push   %edx
f0103f93:	50                   	push   %eax
f0103f94:	89 f2                	mov    %esi,%edx
f0103f96:	89 f8                	mov    %edi,%eax
f0103f98:	e8 89 ff ff ff       	call   f0103f26 <printnum>
f0103f9d:	83 c4 20             	add    $0x20,%esp
f0103fa0:	eb 13                	jmp    f0103fb5 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103fa2:	83 ec 08             	sub    $0x8,%esp
f0103fa5:	56                   	push   %esi
f0103fa6:	ff 75 18             	pushl  0x18(%ebp)
f0103fa9:	ff d7                	call   *%edi
f0103fab:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103fae:	83 eb 01             	sub    $0x1,%ebx
f0103fb1:	85 db                	test   %ebx,%ebx
f0103fb3:	7f ed                	jg     f0103fa2 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103fb5:	83 ec 08             	sub    $0x8,%esp
f0103fb8:	56                   	push   %esi
f0103fb9:	83 ec 04             	sub    $0x4,%esp
f0103fbc:	ff 75 dc             	pushl  -0x24(%ebp)
f0103fbf:	ff 75 d8             	pushl  -0x28(%ebp)
f0103fc2:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103fc5:	ff 75 d0             	pushl  -0x30(%ebp)
f0103fc8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103fcb:	89 f3                	mov    %esi,%ebx
f0103fcd:	e8 fe 0a 00 00       	call   f0104ad0 <__umoddi3>
f0103fd2:	83 c4 14             	add    $0x14,%esp
f0103fd5:	0f be 84 06 31 b0 f7 	movsbl -0x84fcf(%esi,%eax,1),%eax
f0103fdc:	ff 
f0103fdd:	50                   	push   %eax
f0103fde:	ff d7                	call   *%edi
}
f0103fe0:	83 c4 10             	add    $0x10,%esp
f0103fe3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103fe6:	5b                   	pop    %ebx
f0103fe7:	5e                   	pop    %esi
f0103fe8:	5f                   	pop    %edi
f0103fe9:	5d                   	pop    %ebp
f0103fea:	c3                   	ret    
f0103feb:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103fee:	eb be                	jmp    f0103fae <printnum+0x88>

f0103ff0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103ff0:	55                   	push   %ebp
f0103ff1:	89 e5                	mov    %esp,%ebp
f0103ff3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103ff6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103ffa:	8b 10                	mov    (%eax),%edx
f0103ffc:	3b 50 04             	cmp    0x4(%eax),%edx
f0103fff:	73 0a                	jae    f010400b <sprintputch+0x1b>
		*b->buf++ = ch;
f0104001:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104004:	89 08                	mov    %ecx,(%eax)
f0104006:	8b 45 08             	mov    0x8(%ebp),%eax
f0104009:	88 02                	mov    %al,(%edx)
}
f010400b:	5d                   	pop    %ebp
f010400c:	c3                   	ret    

f010400d <printfmt>:
{
f010400d:	55                   	push   %ebp
f010400e:	89 e5                	mov    %esp,%ebp
f0104010:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0104013:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104016:	50                   	push   %eax
f0104017:	ff 75 10             	pushl  0x10(%ebp)
f010401a:	ff 75 0c             	pushl  0xc(%ebp)
f010401d:	ff 75 08             	pushl  0x8(%ebp)
f0104020:	e8 05 00 00 00       	call   f010402a <vprintfmt>
}
f0104025:	83 c4 10             	add    $0x10,%esp
f0104028:	c9                   	leave  
f0104029:	c3                   	ret    

f010402a <vprintfmt>:
{
f010402a:	55                   	push   %ebp
f010402b:	89 e5                	mov    %esp,%ebp
f010402d:	57                   	push   %edi
f010402e:	56                   	push   %esi
f010402f:	53                   	push   %ebx
f0104030:	83 ec 2c             	sub    $0x2c,%esp
f0104033:	e8 2f c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104038:	81 c3 e8 6f 08 00    	add    $0x86fe8,%ebx
f010403e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104041:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104044:	e9 c3 03 00 00       	jmp    f010440c <.L35+0x48>
		padc = ' ';
f0104049:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010404d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0104054:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010405b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0104062:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104067:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010406a:	8d 47 01             	lea    0x1(%edi),%eax
f010406d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104070:	0f b6 17             	movzbl (%edi),%edx
f0104073:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104076:	3c 55                	cmp    $0x55,%al
f0104078:	0f 87 16 04 00 00    	ja     f0104494 <.L22>
f010407e:	0f b6 c0             	movzbl %al,%eax
f0104081:	89 d9                	mov    %ebx,%ecx
f0104083:	03 8c 83 bc b0 f7 ff 	add    -0x84f44(%ebx,%eax,4),%ecx
f010408a:	ff e1                	jmp    *%ecx

f010408c <.L69>:
f010408c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f010408f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0104093:	eb d5                	jmp    f010406a <vprintfmt+0x40>

f0104095 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0104095:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0104098:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010409c:	eb cc                	jmp    f010406a <vprintfmt+0x40>

f010409e <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f010409e:	0f b6 d2             	movzbl %dl,%edx
f01040a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01040a4:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f01040a9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01040ac:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01040b0:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01040b3:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01040b6:	83 f9 09             	cmp    $0x9,%ecx
f01040b9:	77 55                	ja     f0104110 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f01040bb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01040be:	eb e9                	jmp    f01040a9 <.L29+0xb>

f01040c0 <.L26>:
			precision = va_arg(ap, int);
f01040c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01040c3:	8b 00                	mov    (%eax),%eax
f01040c5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01040c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01040cb:	8d 40 04             	lea    0x4(%eax),%eax
f01040ce:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01040d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01040d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01040d8:	79 90                	jns    f010406a <vprintfmt+0x40>
				width = precision, precision = -1;
f01040da:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01040dd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01040e0:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f01040e7:	eb 81                	jmp    f010406a <vprintfmt+0x40>

f01040e9 <.L27>:
f01040e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040ec:	85 c0                	test   %eax,%eax
f01040ee:	ba 00 00 00 00       	mov    $0x0,%edx
f01040f3:	0f 49 d0             	cmovns %eax,%edx
f01040f6:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01040f9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040fc:	e9 69 ff ff ff       	jmp    f010406a <vprintfmt+0x40>

f0104101 <.L23>:
f0104101:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104104:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010410b:	e9 5a ff ff ff       	jmp    f010406a <vprintfmt+0x40>
f0104110:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104113:	eb bf                	jmp    f01040d4 <.L26+0x14>

f0104115 <.L33>:
			lflag++;
f0104115:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104119:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010411c:	e9 49 ff ff ff       	jmp    f010406a <vprintfmt+0x40>

f0104121 <.L30>:
			putch(va_arg(ap, int), putdat);
f0104121:	8b 45 14             	mov    0x14(%ebp),%eax
f0104124:	8d 78 04             	lea    0x4(%eax),%edi
f0104127:	83 ec 08             	sub    $0x8,%esp
f010412a:	56                   	push   %esi
f010412b:	ff 30                	pushl  (%eax)
f010412d:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104130:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104133:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0104136:	e9 ce 02 00 00       	jmp    f0104409 <.L35+0x45>

f010413b <.L32>:
			err = va_arg(ap, int);
f010413b:	8b 45 14             	mov    0x14(%ebp),%eax
f010413e:	8d 78 04             	lea    0x4(%eax),%edi
f0104141:	8b 00                	mov    (%eax),%eax
f0104143:	99                   	cltd   
f0104144:	31 d0                	xor    %edx,%eax
f0104146:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104148:	83 f8 06             	cmp    $0x6,%eax
f010414b:	7f 27                	jg     f0104174 <.L32+0x39>
f010414d:	8b 94 83 b0 20 00 00 	mov    0x20b0(%ebx,%eax,4),%edx
f0104154:	85 d2                	test   %edx,%edx
f0104156:	74 1c                	je     f0104174 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0104158:	52                   	push   %edx
f0104159:	8d 83 5d a9 f7 ff    	lea    -0x856a3(%ebx),%eax
f010415f:	50                   	push   %eax
f0104160:	56                   	push   %esi
f0104161:	ff 75 08             	pushl  0x8(%ebp)
f0104164:	e8 a4 fe ff ff       	call   f010400d <printfmt>
f0104169:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010416c:	89 7d 14             	mov    %edi,0x14(%ebp)
f010416f:	e9 95 02 00 00       	jmp    f0104409 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0104174:	50                   	push   %eax
f0104175:	8d 83 49 b0 f7 ff    	lea    -0x84fb7(%ebx),%eax
f010417b:	50                   	push   %eax
f010417c:	56                   	push   %esi
f010417d:	ff 75 08             	pushl  0x8(%ebp)
f0104180:	e8 88 fe ff ff       	call   f010400d <printfmt>
f0104185:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104188:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010418b:	e9 79 02 00 00       	jmp    f0104409 <.L35+0x45>

f0104190 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0104190:	8b 45 14             	mov    0x14(%ebp),%eax
f0104193:	83 c0 04             	add    $0x4,%eax
f0104196:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104199:	8b 45 14             	mov    0x14(%ebp),%eax
f010419c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010419e:	85 ff                	test   %edi,%edi
f01041a0:	8d 83 42 b0 f7 ff    	lea    -0x84fbe(%ebx),%eax
f01041a6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01041a9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01041ad:	0f 8e b5 00 00 00    	jle    f0104268 <.L36+0xd8>
f01041b3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01041b7:	75 08                	jne    f01041c1 <.L36+0x31>
f01041b9:	89 75 0c             	mov    %esi,0xc(%ebp)
f01041bc:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01041bf:	eb 6d                	jmp    f010422e <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f01041c1:	83 ec 08             	sub    $0x8,%esp
f01041c4:	ff 75 cc             	pushl  -0x34(%ebp)
f01041c7:	57                   	push   %edi
f01041c8:	e8 7e 04 00 00       	call   f010464b <strnlen>
f01041cd:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01041d0:	29 c2                	sub    %eax,%edx
f01041d2:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01041d5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01041d8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01041dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01041df:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01041e2:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01041e4:	eb 10                	jmp    f01041f6 <.L36+0x66>
					putch(padc, putdat);
f01041e6:	83 ec 08             	sub    $0x8,%esp
f01041e9:	56                   	push   %esi
f01041ea:	ff 75 e0             	pushl  -0x20(%ebp)
f01041ed:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01041f0:	83 ef 01             	sub    $0x1,%edi
f01041f3:	83 c4 10             	add    $0x10,%esp
f01041f6:	85 ff                	test   %edi,%edi
f01041f8:	7f ec                	jg     f01041e6 <.L36+0x56>
f01041fa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01041fd:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0104200:	85 d2                	test   %edx,%edx
f0104202:	b8 00 00 00 00       	mov    $0x0,%eax
f0104207:	0f 49 c2             	cmovns %edx,%eax
f010420a:	29 c2                	sub    %eax,%edx
f010420c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010420f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104212:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104215:	eb 17                	jmp    f010422e <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0104217:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010421b:	75 30                	jne    f010424d <.L36+0xbd>
					putch(ch, putdat);
f010421d:	83 ec 08             	sub    $0x8,%esp
f0104220:	ff 75 0c             	pushl  0xc(%ebp)
f0104223:	50                   	push   %eax
f0104224:	ff 55 08             	call   *0x8(%ebp)
f0104227:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010422a:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010422e:	83 c7 01             	add    $0x1,%edi
f0104231:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0104235:	0f be c2             	movsbl %dl,%eax
f0104238:	85 c0                	test   %eax,%eax
f010423a:	74 52                	je     f010428e <.L36+0xfe>
f010423c:	85 f6                	test   %esi,%esi
f010423e:	78 d7                	js     f0104217 <.L36+0x87>
f0104240:	83 ee 01             	sub    $0x1,%esi
f0104243:	79 d2                	jns    f0104217 <.L36+0x87>
f0104245:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104248:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010424b:	eb 32                	jmp    f010427f <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010424d:	0f be d2             	movsbl %dl,%edx
f0104250:	83 ea 20             	sub    $0x20,%edx
f0104253:	83 fa 5e             	cmp    $0x5e,%edx
f0104256:	76 c5                	jbe    f010421d <.L36+0x8d>
					putch('?', putdat);
f0104258:	83 ec 08             	sub    $0x8,%esp
f010425b:	ff 75 0c             	pushl  0xc(%ebp)
f010425e:	6a 3f                	push   $0x3f
f0104260:	ff 55 08             	call   *0x8(%ebp)
f0104263:	83 c4 10             	add    $0x10,%esp
f0104266:	eb c2                	jmp    f010422a <.L36+0x9a>
f0104268:	89 75 0c             	mov    %esi,0xc(%ebp)
f010426b:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010426e:	eb be                	jmp    f010422e <.L36+0x9e>
				putch(' ', putdat);
f0104270:	83 ec 08             	sub    $0x8,%esp
f0104273:	56                   	push   %esi
f0104274:	6a 20                	push   $0x20
f0104276:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0104279:	83 ef 01             	sub    $0x1,%edi
f010427c:	83 c4 10             	add    $0x10,%esp
f010427f:	85 ff                	test   %edi,%edi
f0104281:	7f ed                	jg     f0104270 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0104283:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104286:	89 45 14             	mov    %eax,0x14(%ebp)
f0104289:	e9 7b 01 00 00       	jmp    f0104409 <.L35+0x45>
f010428e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104291:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104294:	eb e9                	jmp    f010427f <.L36+0xef>

f0104296 <.L31>:
f0104296:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104299:	83 f9 01             	cmp    $0x1,%ecx
f010429c:	7e 40                	jle    f01042de <.L31+0x48>
		return va_arg(*ap, long long);
f010429e:	8b 45 14             	mov    0x14(%ebp),%eax
f01042a1:	8b 50 04             	mov    0x4(%eax),%edx
f01042a4:	8b 00                	mov    (%eax),%eax
f01042a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01042a9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01042ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01042af:	8d 40 08             	lea    0x8(%eax),%eax
f01042b2:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01042b5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01042b9:	79 55                	jns    f0104310 <.L31+0x7a>
				putch('-', putdat);
f01042bb:	83 ec 08             	sub    $0x8,%esp
f01042be:	56                   	push   %esi
f01042bf:	6a 2d                	push   $0x2d
f01042c1:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01042c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01042c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01042ca:	f7 da                	neg    %edx
f01042cc:	83 d1 00             	adc    $0x0,%ecx
f01042cf:	f7 d9                	neg    %ecx
f01042d1:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01042d4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01042d9:	e9 10 01 00 00       	jmp    f01043ee <.L35+0x2a>
	else if (lflag)
f01042de:	85 c9                	test   %ecx,%ecx
f01042e0:	75 17                	jne    f01042f9 <.L31+0x63>
		return va_arg(*ap, int);
f01042e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01042e5:	8b 00                	mov    (%eax),%eax
f01042e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01042ea:	99                   	cltd   
f01042eb:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01042ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01042f1:	8d 40 04             	lea    0x4(%eax),%eax
f01042f4:	89 45 14             	mov    %eax,0x14(%ebp)
f01042f7:	eb bc                	jmp    f01042b5 <.L31+0x1f>
		return va_arg(*ap, long);
f01042f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01042fc:	8b 00                	mov    (%eax),%eax
f01042fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104301:	99                   	cltd   
f0104302:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104305:	8b 45 14             	mov    0x14(%ebp),%eax
f0104308:	8d 40 04             	lea    0x4(%eax),%eax
f010430b:	89 45 14             	mov    %eax,0x14(%ebp)
f010430e:	eb a5                	jmp    f01042b5 <.L31+0x1f>
			num = getint(&ap, lflag);
f0104310:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104313:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0104316:	b8 0a 00 00 00       	mov    $0xa,%eax
f010431b:	e9 ce 00 00 00       	jmp    f01043ee <.L35+0x2a>

f0104320 <.L37>:
f0104320:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104323:	83 f9 01             	cmp    $0x1,%ecx
f0104326:	7e 18                	jle    f0104340 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0104328:	8b 45 14             	mov    0x14(%ebp),%eax
f010432b:	8b 10                	mov    (%eax),%edx
f010432d:	8b 48 04             	mov    0x4(%eax),%ecx
f0104330:	8d 40 08             	lea    0x8(%eax),%eax
f0104333:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104336:	b8 0a 00 00 00       	mov    $0xa,%eax
f010433b:	e9 ae 00 00 00       	jmp    f01043ee <.L35+0x2a>
	else if (lflag)
f0104340:	85 c9                	test   %ecx,%ecx
f0104342:	75 1a                	jne    f010435e <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0104344:	8b 45 14             	mov    0x14(%ebp),%eax
f0104347:	8b 10                	mov    (%eax),%edx
f0104349:	b9 00 00 00 00       	mov    $0x0,%ecx
f010434e:	8d 40 04             	lea    0x4(%eax),%eax
f0104351:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104354:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104359:	e9 90 00 00 00       	jmp    f01043ee <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010435e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104361:	8b 10                	mov    (%eax),%edx
f0104363:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104368:	8d 40 04             	lea    0x4(%eax),%eax
f010436b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010436e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104373:	eb 79                	jmp    f01043ee <.L35+0x2a>

f0104375 <.L34>:
f0104375:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104378:	83 f9 01             	cmp    $0x1,%ecx
f010437b:	7e 15                	jle    f0104392 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f010437d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104380:	8b 10                	mov    (%eax),%edx
f0104382:	8b 48 04             	mov    0x4(%eax),%ecx
f0104385:	8d 40 08             	lea    0x8(%eax),%eax
f0104388:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010438b:	b8 08 00 00 00       	mov    $0x8,%eax
f0104390:	eb 5c                	jmp    f01043ee <.L35+0x2a>
	else if (lflag)
f0104392:	85 c9                	test   %ecx,%ecx
f0104394:	75 17                	jne    f01043ad <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0104396:	8b 45 14             	mov    0x14(%ebp),%eax
f0104399:	8b 10                	mov    (%eax),%edx
f010439b:	b9 00 00 00 00       	mov    $0x0,%ecx
f01043a0:	8d 40 04             	lea    0x4(%eax),%eax
f01043a3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01043a6:	b8 08 00 00 00       	mov    $0x8,%eax
f01043ab:	eb 41                	jmp    f01043ee <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01043ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01043b0:	8b 10                	mov    (%eax),%edx
f01043b2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01043b7:	8d 40 04             	lea    0x4(%eax),%eax
f01043ba:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01043bd:	b8 08 00 00 00       	mov    $0x8,%eax
f01043c2:	eb 2a                	jmp    f01043ee <.L35+0x2a>

f01043c4 <.L35>:
			putch('0', putdat);
f01043c4:	83 ec 08             	sub    $0x8,%esp
f01043c7:	56                   	push   %esi
f01043c8:	6a 30                	push   $0x30
f01043ca:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01043cd:	83 c4 08             	add    $0x8,%esp
f01043d0:	56                   	push   %esi
f01043d1:	6a 78                	push   $0x78
f01043d3:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01043d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01043d9:	8b 10                	mov    (%eax),%edx
f01043db:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f01043e0:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01043e3:	8d 40 04             	lea    0x4(%eax),%eax
f01043e6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01043e9:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01043ee:	83 ec 0c             	sub    $0xc,%esp
f01043f1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01043f5:	57                   	push   %edi
f01043f6:	ff 75 e0             	pushl  -0x20(%ebp)
f01043f9:	50                   	push   %eax
f01043fa:	51                   	push   %ecx
f01043fb:	52                   	push   %edx
f01043fc:	89 f2                	mov    %esi,%edx
f01043fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0104401:	e8 20 fb ff ff       	call   f0103f26 <printnum>
			break;
f0104406:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0104409:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010440c:	83 c7 01             	add    $0x1,%edi
f010440f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104413:	83 f8 25             	cmp    $0x25,%eax
f0104416:	0f 84 2d fc ff ff    	je     f0104049 <vprintfmt+0x1f>
			if (ch == '\0')
f010441c:	85 c0                	test   %eax,%eax
f010441e:	0f 84 91 00 00 00    	je     f01044b5 <.L22+0x21>
			putch(ch, putdat);
f0104424:	83 ec 08             	sub    $0x8,%esp
f0104427:	56                   	push   %esi
f0104428:	50                   	push   %eax
f0104429:	ff 55 08             	call   *0x8(%ebp)
f010442c:	83 c4 10             	add    $0x10,%esp
f010442f:	eb db                	jmp    f010440c <.L35+0x48>

f0104431 <.L38>:
f0104431:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104434:	83 f9 01             	cmp    $0x1,%ecx
f0104437:	7e 15                	jle    f010444e <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0104439:	8b 45 14             	mov    0x14(%ebp),%eax
f010443c:	8b 10                	mov    (%eax),%edx
f010443e:	8b 48 04             	mov    0x4(%eax),%ecx
f0104441:	8d 40 08             	lea    0x8(%eax),%eax
f0104444:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104447:	b8 10 00 00 00       	mov    $0x10,%eax
f010444c:	eb a0                	jmp    f01043ee <.L35+0x2a>
	else if (lflag)
f010444e:	85 c9                	test   %ecx,%ecx
f0104450:	75 17                	jne    f0104469 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0104452:	8b 45 14             	mov    0x14(%ebp),%eax
f0104455:	8b 10                	mov    (%eax),%edx
f0104457:	b9 00 00 00 00       	mov    $0x0,%ecx
f010445c:	8d 40 04             	lea    0x4(%eax),%eax
f010445f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104462:	b8 10 00 00 00       	mov    $0x10,%eax
f0104467:	eb 85                	jmp    f01043ee <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104469:	8b 45 14             	mov    0x14(%ebp),%eax
f010446c:	8b 10                	mov    (%eax),%edx
f010446e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104473:	8d 40 04             	lea    0x4(%eax),%eax
f0104476:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104479:	b8 10 00 00 00       	mov    $0x10,%eax
f010447e:	e9 6b ff ff ff       	jmp    f01043ee <.L35+0x2a>

f0104483 <.L25>:
			putch(ch, putdat);
f0104483:	83 ec 08             	sub    $0x8,%esp
f0104486:	56                   	push   %esi
f0104487:	6a 25                	push   $0x25
f0104489:	ff 55 08             	call   *0x8(%ebp)
			break;
f010448c:	83 c4 10             	add    $0x10,%esp
f010448f:	e9 75 ff ff ff       	jmp    f0104409 <.L35+0x45>

f0104494 <.L22>:
			putch('%', putdat);
f0104494:	83 ec 08             	sub    $0x8,%esp
f0104497:	56                   	push   %esi
f0104498:	6a 25                	push   $0x25
f010449a:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010449d:	83 c4 10             	add    $0x10,%esp
f01044a0:	89 f8                	mov    %edi,%eax
f01044a2:	eb 03                	jmp    f01044a7 <.L22+0x13>
f01044a4:	83 e8 01             	sub    $0x1,%eax
f01044a7:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01044ab:	75 f7                	jne    f01044a4 <.L22+0x10>
f01044ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01044b0:	e9 54 ff ff ff       	jmp    f0104409 <.L35+0x45>
}
f01044b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01044b8:	5b                   	pop    %ebx
f01044b9:	5e                   	pop    %esi
f01044ba:	5f                   	pop    %edi
f01044bb:	5d                   	pop    %ebp
f01044bc:	c3                   	ret    

f01044bd <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01044bd:	55                   	push   %ebp
f01044be:	89 e5                	mov    %esp,%ebp
f01044c0:	53                   	push   %ebx
f01044c1:	83 ec 14             	sub    $0x14,%esp
f01044c4:	e8 9e bc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01044c9:	81 c3 57 6b 08 00    	add    $0x86b57,%ebx
f01044cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01044d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01044d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01044d8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01044dc:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01044df:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01044e6:	85 c0                	test   %eax,%eax
f01044e8:	74 2b                	je     f0104515 <vsnprintf+0x58>
f01044ea:	85 d2                	test   %edx,%edx
f01044ec:	7e 27                	jle    f0104515 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01044ee:	ff 75 14             	pushl  0x14(%ebp)
f01044f1:	ff 75 10             	pushl  0x10(%ebp)
f01044f4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01044f7:	50                   	push   %eax
f01044f8:	8d 83 d0 8f f7 ff    	lea    -0x87030(%ebx),%eax
f01044fe:	50                   	push   %eax
f01044ff:	e8 26 fb ff ff       	call   f010402a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104504:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104507:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010450a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010450d:	83 c4 10             	add    $0x10,%esp
}
f0104510:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104513:	c9                   	leave  
f0104514:	c3                   	ret    
		return -E_INVAL;
f0104515:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010451a:	eb f4                	jmp    f0104510 <vsnprintf+0x53>

f010451c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010451c:	55                   	push   %ebp
f010451d:	89 e5                	mov    %esp,%ebp
f010451f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104522:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104525:	50                   	push   %eax
f0104526:	ff 75 10             	pushl  0x10(%ebp)
f0104529:	ff 75 0c             	pushl  0xc(%ebp)
f010452c:	ff 75 08             	pushl  0x8(%ebp)
f010452f:	e8 89 ff ff ff       	call   f01044bd <vsnprintf>
	va_end(ap);

	return rc;
}
f0104534:	c9                   	leave  
f0104535:	c3                   	ret    

f0104536 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104536:	55                   	push   %ebp
f0104537:	89 e5                	mov    %esp,%ebp
f0104539:	57                   	push   %edi
f010453a:	56                   	push   %esi
f010453b:	53                   	push   %ebx
f010453c:	83 ec 1c             	sub    $0x1c,%esp
f010453f:	e8 23 bc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104544:	81 c3 dc 6a 08 00    	add    $0x86adc,%ebx
f010454a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010454d:	85 c0                	test   %eax,%eax
f010454f:	74 13                	je     f0104564 <readline+0x2e>
		cprintf("%s", prompt);
f0104551:	83 ec 08             	sub    $0x8,%esp
f0104554:	50                   	push   %eax
f0104555:	8d 83 5d a9 f7 ff    	lea    -0x856a3(%ebx),%eax
f010455b:	50                   	push   %eax
f010455c:	e8 9a f1 ff ff       	call   f01036fb <cprintf>
f0104561:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104564:	83 ec 0c             	sub    $0xc,%esp
f0104567:	6a 00                	push   $0x0
f0104569:	e8 91 c1 ff ff       	call   f01006ff <iscons>
f010456e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104571:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104574:	bf 00 00 00 00       	mov    $0x0,%edi
f0104579:	eb 46                	jmp    f01045c1 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010457b:	83 ec 08             	sub    $0x8,%esp
f010457e:	50                   	push   %eax
f010457f:	8d 83 14 b2 f7 ff    	lea    -0x84dec(%ebx),%eax
f0104585:	50                   	push   %eax
f0104586:	e8 70 f1 ff ff       	call   f01036fb <cprintf>
			return NULL;
f010458b:	83 c4 10             	add    $0x10,%esp
f010458e:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104593:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104596:	5b                   	pop    %ebx
f0104597:	5e                   	pop    %esi
f0104598:	5f                   	pop    %edi
f0104599:	5d                   	pop    %ebp
f010459a:	c3                   	ret    
			if (echoing)
f010459b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010459f:	75 05                	jne    f01045a6 <readline+0x70>
			i--;
f01045a1:	83 ef 01             	sub    $0x1,%edi
f01045a4:	eb 1b                	jmp    f01045c1 <readline+0x8b>
				cputchar('\b');
f01045a6:	83 ec 0c             	sub    $0xc,%esp
f01045a9:	6a 08                	push   $0x8
f01045ab:	e8 2e c1 ff ff       	call   f01006de <cputchar>
f01045b0:	83 c4 10             	add    $0x10,%esp
f01045b3:	eb ec                	jmp    f01045a1 <readline+0x6b>
			buf[i++] = c;
f01045b5:	89 f0                	mov    %esi,%eax
f01045b7:	88 84 3b e0 2b 00 00 	mov    %al,0x2be0(%ebx,%edi,1)
f01045be:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01045c1:	e8 28 c1 ff ff       	call   f01006ee <getchar>
f01045c6:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01045c8:	85 c0                	test   %eax,%eax
f01045ca:	78 af                	js     f010457b <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01045cc:	83 f8 08             	cmp    $0x8,%eax
f01045cf:	0f 94 c2             	sete   %dl
f01045d2:	83 f8 7f             	cmp    $0x7f,%eax
f01045d5:	0f 94 c0             	sete   %al
f01045d8:	08 c2                	or     %al,%dl
f01045da:	74 04                	je     f01045e0 <readline+0xaa>
f01045dc:	85 ff                	test   %edi,%edi
f01045de:	7f bb                	jg     f010459b <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01045e0:	83 fe 1f             	cmp    $0x1f,%esi
f01045e3:	7e 1c                	jle    f0104601 <readline+0xcb>
f01045e5:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01045eb:	7f 14                	jg     f0104601 <readline+0xcb>
			if (echoing)
f01045ed:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01045f1:	74 c2                	je     f01045b5 <readline+0x7f>
				cputchar(c);
f01045f3:	83 ec 0c             	sub    $0xc,%esp
f01045f6:	56                   	push   %esi
f01045f7:	e8 e2 c0 ff ff       	call   f01006de <cputchar>
f01045fc:	83 c4 10             	add    $0x10,%esp
f01045ff:	eb b4                	jmp    f01045b5 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0104601:	83 fe 0a             	cmp    $0xa,%esi
f0104604:	74 05                	je     f010460b <readline+0xd5>
f0104606:	83 fe 0d             	cmp    $0xd,%esi
f0104609:	75 b6                	jne    f01045c1 <readline+0x8b>
			if (echoing)
f010460b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010460f:	75 13                	jne    f0104624 <readline+0xee>
			buf[i] = 0;
f0104611:	c6 84 3b e0 2b 00 00 	movb   $0x0,0x2be0(%ebx,%edi,1)
f0104618:	00 
			return buf;
f0104619:	8d 83 e0 2b 00 00    	lea    0x2be0(%ebx),%eax
f010461f:	e9 6f ff ff ff       	jmp    f0104593 <readline+0x5d>
				cputchar('\n');
f0104624:	83 ec 0c             	sub    $0xc,%esp
f0104627:	6a 0a                	push   $0xa
f0104629:	e8 b0 c0 ff ff       	call   f01006de <cputchar>
f010462e:	83 c4 10             	add    $0x10,%esp
f0104631:	eb de                	jmp    f0104611 <readline+0xdb>

f0104633 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104633:	55                   	push   %ebp
f0104634:	89 e5                	mov    %esp,%ebp
f0104636:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104639:	b8 00 00 00 00       	mov    $0x0,%eax
f010463e:	eb 03                	jmp    f0104643 <strlen+0x10>
		n++;
f0104640:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0104643:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104647:	75 f7                	jne    f0104640 <strlen+0xd>
	return n;
}
f0104649:	5d                   	pop    %ebp
f010464a:	c3                   	ret    

f010464b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010464b:	55                   	push   %ebp
f010464c:	89 e5                	mov    %esp,%ebp
f010464e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104651:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104654:	b8 00 00 00 00       	mov    $0x0,%eax
f0104659:	eb 03                	jmp    f010465e <strnlen+0x13>
		n++;
f010465b:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010465e:	39 d0                	cmp    %edx,%eax
f0104660:	74 06                	je     f0104668 <strnlen+0x1d>
f0104662:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104666:	75 f3                	jne    f010465b <strnlen+0x10>
	return n;
}
f0104668:	5d                   	pop    %ebp
f0104669:	c3                   	ret    

f010466a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010466a:	55                   	push   %ebp
f010466b:	89 e5                	mov    %esp,%ebp
f010466d:	53                   	push   %ebx
f010466e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104671:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104674:	89 c2                	mov    %eax,%edx
f0104676:	83 c1 01             	add    $0x1,%ecx
f0104679:	83 c2 01             	add    $0x1,%edx
f010467c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104680:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104683:	84 db                	test   %bl,%bl
f0104685:	75 ef                	jne    f0104676 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104687:	5b                   	pop    %ebx
f0104688:	5d                   	pop    %ebp
f0104689:	c3                   	ret    

f010468a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010468a:	55                   	push   %ebp
f010468b:	89 e5                	mov    %esp,%ebp
f010468d:	53                   	push   %ebx
f010468e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104691:	53                   	push   %ebx
f0104692:	e8 9c ff ff ff       	call   f0104633 <strlen>
f0104697:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010469a:	ff 75 0c             	pushl  0xc(%ebp)
f010469d:	01 d8                	add    %ebx,%eax
f010469f:	50                   	push   %eax
f01046a0:	e8 c5 ff ff ff       	call   f010466a <strcpy>
	return dst;
}
f01046a5:	89 d8                	mov    %ebx,%eax
f01046a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01046aa:	c9                   	leave  
f01046ab:	c3                   	ret    

f01046ac <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01046ac:	55                   	push   %ebp
f01046ad:	89 e5                	mov    %esp,%ebp
f01046af:	56                   	push   %esi
f01046b0:	53                   	push   %ebx
f01046b1:	8b 75 08             	mov    0x8(%ebp),%esi
f01046b4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01046b7:	89 f3                	mov    %esi,%ebx
f01046b9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01046bc:	89 f2                	mov    %esi,%edx
f01046be:	eb 0f                	jmp    f01046cf <strncpy+0x23>
		*dst++ = *src;
f01046c0:	83 c2 01             	add    $0x1,%edx
f01046c3:	0f b6 01             	movzbl (%ecx),%eax
f01046c6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01046c9:	80 39 01             	cmpb   $0x1,(%ecx)
f01046cc:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01046cf:	39 da                	cmp    %ebx,%edx
f01046d1:	75 ed                	jne    f01046c0 <strncpy+0x14>
	}
	return ret;
}
f01046d3:	89 f0                	mov    %esi,%eax
f01046d5:	5b                   	pop    %ebx
f01046d6:	5e                   	pop    %esi
f01046d7:	5d                   	pop    %ebp
f01046d8:	c3                   	ret    

f01046d9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01046d9:	55                   	push   %ebp
f01046da:	89 e5                	mov    %esp,%ebp
f01046dc:	56                   	push   %esi
f01046dd:	53                   	push   %ebx
f01046de:	8b 75 08             	mov    0x8(%ebp),%esi
f01046e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01046e4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01046e7:	89 f0                	mov    %esi,%eax
f01046e9:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01046ed:	85 c9                	test   %ecx,%ecx
f01046ef:	75 0b                	jne    f01046fc <strlcpy+0x23>
f01046f1:	eb 17                	jmp    f010470a <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01046f3:	83 c2 01             	add    $0x1,%edx
f01046f6:	83 c0 01             	add    $0x1,%eax
f01046f9:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01046fc:	39 d8                	cmp    %ebx,%eax
f01046fe:	74 07                	je     f0104707 <strlcpy+0x2e>
f0104700:	0f b6 0a             	movzbl (%edx),%ecx
f0104703:	84 c9                	test   %cl,%cl
f0104705:	75 ec                	jne    f01046f3 <strlcpy+0x1a>
		*dst = '\0';
f0104707:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010470a:	29 f0                	sub    %esi,%eax
}
f010470c:	5b                   	pop    %ebx
f010470d:	5e                   	pop    %esi
f010470e:	5d                   	pop    %ebp
f010470f:	c3                   	ret    

f0104710 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104710:	55                   	push   %ebp
f0104711:	89 e5                	mov    %esp,%ebp
f0104713:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104716:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104719:	eb 06                	jmp    f0104721 <strcmp+0x11>
		p++, q++;
f010471b:	83 c1 01             	add    $0x1,%ecx
f010471e:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0104721:	0f b6 01             	movzbl (%ecx),%eax
f0104724:	84 c0                	test   %al,%al
f0104726:	74 04                	je     f010472c <strcmp+0x1c>
f0104728:	3a 02                	cmp    (%edx),%al
f010472a:	74 ef                	je     f010471b <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010472c:	0f b6 c0             	movzbl %al,%eax
f010472f:	0f b6 12             	movzbl (%edx),%edx
f0104732:	29 d0                	sub    %edx,%eax
}
f0104734:	5d                   	pop    %ebp
f0104735:	c3                   	ret    

f0104736 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104736:	55                   	push   %ebp
f0104737:	89 e5                	mov    %esp,%ebp
f0104739:	53                   	push   %ebx
f010473a:	8b 45 08             	mov    0x8(%ebp),%eax
f010473d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104740:	89 c3                	mov    %eax,%ebx
f0104742:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104745:	eb 06                	jmp    f010474d <strncmp+0x17>
		n--, p++, q++;
f0104747:	83 c0 01             	add    $0x1,%eax
f010474a:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010474d:	39 d8                	cmp    %ebx,%eax
f010474f:	74 16                	je     f0104767 <strncmp+0x31>
f0104751:	0f b6 08             	movzbl (%eax),%ecx
f0104754:	84 c9                	test   %cl,%cl
f0104756:	74 04                	je     f010475c <strncmp+0x26>
f0104758:	3a 0a                	cmp    (%edx),%cl
f010475a:	74 eb                	je     f0104747 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010475c:	0f b6 00             	movzbl (%eax),%eax
f010475f:	0f b6 12             	movzbl (%edx),%edx
f0104762:	29 d0                	sub    %edx,%eax
}
f0104764:	5b                   	pop    %ebx
f0104765:	5d                   	pop    %ebp
f0104766:	c3                   	ret    
		return 0;
f0104767:	b8 00 00 00 00       	mov    $0x0,%eax
f010476c:	eb f6                	jmp    f0104764 <strncmp+0x2e>

f010476e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010476e:	55                   	push   %ebp
f010476f:	89 e5                	mov    %esp,%ebp
f0104771:	8b 45 08             	mov    0x8(%ebp),%eax
f0104774:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104778:	0f b6 10             	movzbl (%eax),%edx
f010477b:	84 d2                	test   %dl,%dl
f010477d:	74 09                	je     f0104788 <strchr+0x1a>
		if (*s == c)
f010477f:	38 ca                	cmp    %cl,%dl
f0104781:	74 0a                	je     f010478d <strchr+0x1f>
	for (; *s; s++)
f0104783:	83 c0 01             	add    $0x1,%eax
f0104786:	eb f0                	jmp    f0104778 <strchr+0xa>
			return (char *) s;
	return 0;
f0104788:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010478d:	5d                   	pop    %ebp
f010478e:	c3                   	ret    

f010478f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010478f:	55                   	push   %ebp
f0104790:	89 e5                	mov    %esp,%ebp
f0104792:	8b 45 08             	mov    0x8(%ebp),%eax
f0104795:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104799:	eb 03                	jmp    f010479e <strfind+0xf>
f010479b:	83 c0 01             	add    $0x1,%eax
f010479e:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01047a1:	38 ca                	cmp    %cl,%dl
f01047a3:	74 04                	je     f01047a9 <strfind+0x1a>
f01047a5:	84 d2                	test   %dl,%dl
f01047a7:	75 f2                	jne    f010479b <strfind+0xc>
			break;
	return (char *) s;
}
f01047a9:	5d                   	pop    %ebp
f01047aa:	c3                   	ret    

f01047ab <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01047ab:	55                   	push   %ebp
f01047ac:	89 e5                	mov    %esp,%ebp
f01047ae:	57                   	push   %edi
f01047af:	56                   	push   %esi
f01047b0:	53                   	push   %ebx
f01047b1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01047b4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01047b7:	85 c9                	test   %ecx,%ecx
f01047b9:	74 13                	je     f01047ce <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01047bb:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01047c1:	75 05                	jne    f01047c8 <memset+0x1d>
f01047c3:	f6 c1 03             	test   $0x3,%cl
f01047c6:	74 0d                	je     f01047d5 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01047c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01047cb:	fc                   	cld    
f01047cc:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01047ce:	89 f8                	mov    %edi,%eax
f01047d0:	5b                   	pop    %ebx
f01047d1:	5e                   	pop    %esi
f01047d2:	5f                   	pop    %edi
f01047d3:	5d                   	pop    %ebp
f01047d4:	c3                   	ret    
		c &= 0xFF;
f01047d5:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01047d9:	89 d3                	mov    %edx,%ebx
f01047db:	c1 e3 08             	shl    $0x8,%ebx
f01047de:	89 d0                	mov    %edx,%eax
f01047e0:	c1 e0 18             	shl    $0x18,%eax
f01047e3:	89 d6                	mov    %edx,%esi
f01047e5:	c1 e6 10             	shl    $0x10,%esi
f01047e8:	09 f0                	or     %esi,%eax
f01047ea:	09 c2                	or     %eax,%edx
f01047ec:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01047ee:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01047f1:	89 d0                	mov    %edx,%eax
f01047f3:	fc                   	cld    
f01047f4:	f3 ab                	rep stos %eax,%es:(%edi)
f01047f6:	eb d6                	jmp    f01047ce <memset+0x23>

f01047f8 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01047f8:	55                   	push   %ebp
f01047f9:	89 e5                	mov    %esp,%ebp
f01047fb:	57                   	push   %edi
f01047fc:	56                   	push   %esi
f01047fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104800:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104803:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104806:	39 c6                	cmp    %eax,%esi
f0104808:	73 35                	jae    f010483f <memmove+0x47>
f010480a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010480d:	39 c2                	cmp    %eax,%edx
f010480f:	76 2e                	jbe    f010483f <memmove+0x47>
		s += n;
		d += n;
f0104811:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104814:	89 d6                	mov    %edx,%esi
f0104816:	09 fe                	or     %edi,%esi
f0104818:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010481e:	74 0c                	je     f010482c <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104820:	83 ef 01             	sub    $0x1,%edi
f0104823:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0104826:	fd                   	std    
f0104827:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104829:	fc                   	cld    
f010482a:	eb 21                	jmp    f010484d <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010482c:	f6 c1 03             	test   $0x3,%cl
f010482f:	75 ef                	jne    f0104820 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104831:	83 ef 04             	sub    $0x4,%edi
f0104834:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104837:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010483a:	fd                   	std    
f010483b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010483d:	eb ea                	jmp    f0104829 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010483f:	89 f2                	mov    %esi,%edx
f0104841:	09 c2                	or     %eax,%edx
f0104843:	f6 c2 03             	test   $0x3,%dl
f0104846:	74 09                	je     f0104851 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104848:	89 c7                	mov    %eax,%edi
f010484a:	fc                   	cld    
f010484b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010484d:	5e                   	pop    %esi
f010484e:	5f                   	pop    %edi
f010484f:	5d                   	pop    %ebp
f0104850:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104851:	f6 c1 03             	test   $0x3,%cl
f0104854:	75 f2                	jne    f0104848 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104856:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0104859:	89 c7                	mov    %eax,%edi
f010485b:	fc                   	cld    
f010485c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010485e:	eb ed                	jmp    f010484d <memmove+0x55>

f0104860 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104860:	55                   	push   %ebp
f0104861:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104863:	ff 75 10             	pushl  0x10(%ebp)
f0104866:	ff 75 0c             	pushl  0xc(%ebp)
f0104869:	ff 75 08             	pushl  0x8(%ebp)
f010486c:	e8 87 ff ff ff       	call   f01047f8 <memmove>
}
f0104871:	c9                   	leave  
f0104872:	c3                   	ret    

f0104873 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104873:	55                   	push   %ebp
f0104874:	89 e5                	mov    %esp,%ebp
f0104876:	56                   	push   %esi
f0104877:	53                   	push   %ebx
f0104878:	8b 45 08             	mov    0x8(%ebp),%eax
f010487b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010487e:	89 c6                	mov    %eax,%esi
f0104880:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104883:	39 f0                	cmp    %esi,%eax
f0104885:	74 1c                	je     f01048a3 <memcmp+0x30>
		if (*s1 != *s2)
f0104887:	0f b6 08             	movzbl (%eax),%ecx
f010488a:	0f b6 1a             	movzbl (%edx),%ebx
f010488d:	38 d9                	cmp    %bl,%cl
f010488f:	75 08                	jne    f0104899 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0104891:	83 c0 01             	add    $0x1,%eax
f0104894:	83 c2 01             	add    $0x1,%edx
f0104897:	eb ea                	jmp    f0104883 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0104899:	0f b6 c1             	movzbl %cl,%eax
f010489c:	0f b6 db             	movzbl %bl,%ebx
f010489f:	29 d8                	sub    %ebx,%eax
f01048a1:	eb 05                	jmp    f01048a8 <memcmp+0x35>
	}

	return 0;
f01048a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01048a8:	5b                   	pop    %ebx
f01048a9:	5e                   	pop    %esi
f01048aa:	5d                   	pop    %ebp
f01048ab:	c3                   	ret    

f01048ac <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01048ac:	55                   	push   %ebp
f01048ad:	89 e5                	mov    %esp,%ebp
f01048af:	8b 45 08             	mov    0x8(%ebp),%eax
f01048b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01048b5:	89 c2                	mov    %eax,%edx
f01048b7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01048ba:	39 d0                	cmp    %edx,%eax
f01048bc:	73 09                	jae    f01048c7 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01048be:	38 08                	cmp    %cl,(%eax)
f01048c0:	74 05                	je     f01048c7 <memfind+0x1b>
	for (; s < ends; s++)
f01048c2:	83 c0 01             	add    $0x1,%eax
f01048c5:	eb f3                	jmp    f01048ba <memfind+0xe>
			break;
	return (void *) s;
}
f01048c7:	5d                   	pop    %ebp
f01048c8:	c3                   	ret    

f01048c9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01048c9:	55                   	push   %ebp
f01048ca:	89 e5                	mov    %esp,%ebp
f01048cc:	57                   	push   %edi
f01048cd:	56                   	push   %esi
f01048ce:	53                   	push   %ebx
f01048cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01048d2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01048d5:	eb 03                	jmp    f01048da <strtol+0x11>
		s++;
f01048d7:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01048da:	0f b6 01             	movzbl (%ecx),%eax
f01048dd:	3c 20                	cmp    $0x20,%al
f01048df:	74 f6                	je     f01048d7 <strtol+0xe>
f01048e1:	3c 09                	cmp    $0x9,%al
f01048e3:	74 f2                	je     f01048d7 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01048e5:	3c 2b                	cmp    $0x2b,%al
f01048e7:	74 2e                	je     f0104917 <strtol+0x4e>
	int neg = 0;
f01048e9:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01048ee:	3c 2d                	cmp    $0x2d,%al
f01048f0:	74 2f                	je     f0104921 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01048f2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01048f8:	75 05                	jne    f01048ff <strtol+0x36>
f01048fa:	80 39 30             	cmpb   $0x30,(%ecx)
f01048fd:	74 2c                	je     f010492b <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01048ff:	85 db                	test   %ebx,%ebx
f0104901:	75 0a                	jne    f010490d <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104903:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0104908:	80 39 30             	cmpb   $0x30,(%ecx)
f010490b:	74 28                	je     f0104935 <strtol+0x6c>
		base = 10;
f010490d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104912:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104915:	eb 50                	jmp    f0104967 <strtol+0x9e>
		s++;
f0104917:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010491a:	bf 00 00 00 00       	mov    $0x0,%edi
f010491f:	eb d1                	jmp    f01048f2 <strtol+0x29>
		s++, neg = 1;
f0104921:	83 c1 01             	add    $0x1,%ecx
f0104924:	bf 01 00 00 00       	mov    $0x1,%edi
f0104929:	eb c7                	jmp    f01048f2 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010492b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010492f:	74 0e                	je     f010493f <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0104931:	85 db                	test   %ebx,%ebx
f0104933:	75 d8                	jne    f010490d <strtol+0x44>
		s++, base = 8;
f0104935:	83 c1 01             	add    $0x1,%ecx
f0104938:	bb 08 00 00 00       	mov    $0x8,%ebx
f010493d:	eb ce                	jmp    f010490d <strtol+0x44>
		s += 2, base = 16;
f010493f:	83 c1 02             	add    $0x2,%ecx
f0104942:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104947:	eb c4                	jmp    f010490d <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0104949:	8d 72 9f             	lea    -0x61(%edx),%esi
f010494c:	89 f3                	mov    %esi,%ebx
f010494e:	80 fb 19             	cmp    $0x19,%bl
f0104951:	77 29                	ja     f010497c <strtol+0xb3>
			dig = *s - 'a' + 10;
f0104953:	0f be d2             	movsbl %dl,%edx
f0104956:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104959:	3b 55 10             	cmp    0x10(%ebp),%edx
f010495c:	7d 30                	jge    f010498e <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010495e:	83 c1 01             	add    $0x1,%ecx
f0104961:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104965:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0104967:	0f b6 11             	movzbl (%ecx),%edx
f010496a:	8d 72 d0             	lea    -0x30(%edx),%esi
f010496d:	89 f3                	mov    %esi,%ebx
f010496f:	80 fb 09             	cmp    $0x9,%bl
f0104972:	77 d5                	ja     f0104949 <strtol+0x80>
			dig = *s - '0';
f0104974:	0f be d2             	movsbl %dl,%edx
f0104977:	83 ea 30             	sub    $0x30,%edx
f010497a:	eb dd                	jmp    f0104959 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f010497c:	8d 72 bf             	lea    -0x41(%edx),%esi
f010497f:	89 f3                	mov    %esi,%ebx
f0104981:	80 fb 19             	cmp    $0x19,%bl
f0104984:	77 08                	ja     f010498e <strtol+0xc5>
			dig = *s - 'A' + 10;
f0104986:	0f be d2             	movsbl %dl,%edx
f0104989:	83 ea 37             	sub    $0x37,%edx
f010498c:	eb cb                	jmp    f0104959 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f010498e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104992:	74 05                	je     f0104999 <strtol+0xd0>
		*endptr = (char *) s;
f0104994:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104997:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0104999:	89 c2                	mov    %eax,%edx
f010499b:	f7 da                	neg    %edx
f010499d:	85 ff                	test   %edi,%edi
f010499f:	0f 45 c2             	cmovne %edx,%eax
}
f01049a2:	5b                   	pop    %ebx
f01049a3:	5e                   	pop    %esi
f01049a4:	5f                   	pop    %edi
f01049a5:	5d                   	pop    %ebp
f01049a6:	c3                   	ret    
f01049a7:	66 90                	xchg   %ax,%ax
f01049a9:	66 90                	xchg   %ax,%ax
f01049ab:	66 90                	xchg   %ax,%ax
f01049ad:	66 90                	xchg   %ax,%ax
f01049af:	90                   	nop

f01049b0 <__udivdi3>:
f01049b0:	55                   	push   %ebp
f01049b1:	57                   	push   %edi
f01049b2:	56                   	push   %esi
f01049b3:	53                   	push   %ebx
f01049b4:	83 ec 1c             	sub    $0x1c,%esp
f01049b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01049bb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01049bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01049c3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01049c7:	85 d2                	test   %edx,%edx
f01049c9:	75 35                	jne    f0104a00 <__udivdi3+0x50>
f01049cb:	39 f3                	cmp    %esi,%ebx
f01049cd:	0f 87 bd 00 00 00    	ja     f0104a90 <__udivdi3+0xe0>
f01049d3:	85 db                	test   %ebx,%ebx
f01049d5:	89 d9                	mov    %ebx,%ecx
f01049d7:	75 0b                	jne    f01049e4 <__udivdi3+0x34>
f01049d9:	b8 01 00 00 00       	mov    $0x1,%eax
f01049de:	31 d2                	xor    %edx,%edx
f01049e0:	f7 f3                	div    %ebx
f01049e2:	89 c1                	mov    %eax,%ecx
f01049e4:	31 d2                	xor    %edx,%edx
f01049e6:	89 f0                	mov    %esi,%eax
f01049e8:	f7 f1                	div    %ecx
f01049ea:	89 c6                	mov    %eax,%esi
f01049ec:	89 e8                	mov    %ebp,%eax
f01049ee:	89 f7                	mov    %esi,%edi
f01049f0:	f7 f1                	div    %ecx
f01049f2:	89 fa                	mov    %edi,%edx
f01049f4:	83 c4 1c             	add    $0x1c,%esp
f01049f7:	5b                   	pop    %ebx
f01049f8:	5e                   	pop    %esi
f01049f9:	5f                   	pop    %edi
f01049fa:	5d                   	pop    %ebp
f01049fb:	c3                   	ret    
f01049fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104a00:	39 f2                	cmp    %esi,%edx
f0104a02:	77 7c                	ja     f0104a80 <__udivdi3+0xd0>
f0104a04:	0f bd fa             	bsr    %edx,%edi
f0104a07:	83 f7 1f             	xor    $0x1f,%edi
f0104a0a:	0f 84 98 00 00 00    	je     f0104aa8 <__udivdi3+0xf8>
f0104a10:	89 f9                	mov    %edi,%ecx
f0104a12:	b8 20 00 00 00       	mov    $0x20,%eax
f0104a17:	29 f8                	sub    %edi,%eax
f0104a19:	d3 e2                	shl    %cl,%edx
f0104a1b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104a1f:	89 c1                	mov    %eax,%ecx
f0104a21:	89 da                	mov    %ebx,%edx
f0104a23:	d3 ea                	shr    %cl,%edx
f0104a25:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0104a29:	09 d1                	or     %edx,%ecx
f0104a2b:	89 f2                	mov    %esi,%edx
f0104a2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104a31:	89 f9                	mov    %edi,%ecx
f0104a33:	d3 e3                	shl    %cl,%ebx
f0104a35:	89 c1                	mov    %eax,%ecx
f0104a37:	d3 ea                	shr    %cl,%edx
f0104a39:	89 f9                	mov    %edi,%ecx
f0104a3b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0104a3f:	d3 e6                	shl    %cl,%esi
f0104a41:	89 eb                	mov    %ebp,%ebx
f0104a43:	89 c1                	mov    %eax,%ecx
f0104a45:	d3 eb                	shr    %cl,%ebx
f0104a47:	09 de                	or     %ebx,%esi
f0104a49:	89 f0                	mov    %esi,%eax
f0104a4b:	f7 74 24 08          	divl   0x8(%esp)
f0104a4f:	89 d6                	mov    %edx,%esi
f0104a51:	89 c3                	mov    %eax,%ebx
f0104a53:	f7 64 24 0c          	mull   0xc(%esp)
f0104a57:	39 d6                	cmp    %edx,%esi
f0104a59:	72 0c                	jb     f0104a67 <__udivdi3+0xb7>
f0104a5b:	89 f9                	mov    %edi,%ecx
f0104a5d:	d3 e5                	shl    %cl,%ebp
f0104a5f:	39 c5                	cmp    %eax,%ebp
f0104a61:	73 5d                	jae    f0104ac0 <__udivdi3+0x110>
f0104a63:	39 d6                	cmp    %edx,%esi
f0104a65:	75 59                	jne    f0104ac0 <__udivdi3+0x110>
f0104a67:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0104a6a:	31 ff                	xor    %edi,%edi
f0104a6c:	89 fa                	mov    %edi,%edx
f0104a6e:	83 c4 1c             	add    $0x1c,%esp
f0104a71:	5b                   	pop    %ebx
f0104a72:	5e                   	pop    %esi
f0104a73:	5f                   	pop    %edi
f0104a74:	5d                   	pop    %ebp
f0104a75:	c3                   	ret    
f0104a76:	8d 76 00             	lea    0x0(%esi),%esi
f0104a79:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104a80:	31 ff                	xor    %edi,%edi
f0104a82:	31 c0                	xor    %eax,%eax
f0104a84:	89 fa                	mov    %edi,%edx
f0104a86:	83 c4 1c             	add    $0x1c,%esp
f0104a89:	5b                   	pop    %ebx
f0104a8a:	5e                   	pop    %esi
f0104a8b:	5f                   	pop    %edi
f0104a8c:	5d                   	pop    %ebp
f0104a8d:	c3                   	ret    
f0104a8e:	66 90                	xchg   %ax,%ax
f0104a90:	31 ff                	xor    %edi,%edi
f0104a92:	89 e8                	mov    %ebp,%eax
f0104a94:	89 f2                	mov    %esi,%edx
f0104a96:	f7 f3                	div    %ebx
f0104a98:	89 fa                	mov    %edi,%edx
f0104a9a:	83 c4 1c             	add    $0x1c,%esp
f0104a9d:	5b                   	pop    %ebx
f0104a9e:	5e                   	pop    %esi
f0104a9f:	5f                   	pop    %edi
f0104aa0:	5d                   	pop    %ebp
f0104aa1:	c3                   	ret    
f0104aa2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104aa8:	39 f2                	cmp    %esi,%edx
f0104aaa:	72 06                	jb     f0104ab2 <__udivdi3+0x102>
f0104aac:	31 c0                	xor    %eax,%eax
f0104aae:	39 eb                	cmp    %ebp,%ebx
f0104ab0:	77 d2                	ja     f0104a84 <__udivdi3+0xd4>
f0104ab2:	b8 01 00 00 00       	mov    $0x1,%eax
f0104ab7:	eb cb                	jmp    f0104a84 <__udivdi3+0xd4>
f0104ab9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104ac0:	89 d8                	mov    %ebx,%eax
f0104ac2:	31 ff                	xor    %edi,%edi
f0104ac4:	eb be                	jmp    f0104a84 <__udivdi3+0xd4>
f0104ac6:	66 90                	xchg   %ax,%ax
f0104ac8:	66 90                	xchg   %ax,%ax
f0104aca:	66 90                	xchg   %ax,%ax
f0104acc:	66 90                	xchg   %ax,%ax
f0104ace:	66 90                	xchg   %ax,%ax

f0104ad0 <__umoddi3>:
f0104ad0:	55                   	push   %ebp
f0104ad1:	57                   	push   %edi
f0104ad2:	56                   	push   %esi
f0104ad3:	53                   	push   %ebx
f0104ad4:	83 ec 1c             	sub    $0x1c,%esp
f0104ad7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0104adb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0104adf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104ae3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104ae7:	85 ed                	test   %ebp,%ebp
f0104ae9:	89 f0                	mov    %esi,%eax
f0104aeb:	89 da                	mov    %ebx,%edx
f0104aed:	75 19                	jne    f0104b08 <__umoddi3+0x38>
f0104aef:	39 df                	cmp    %ebx,%edi
f0104af1:	0f 86 b1 00 00 00    	jbe    f0104ba8 <__umoddi3+0xd8>
f0104af7:	f7 f7                	div    %edi
f0104af9:	89 d0                	mov    %edx,%eax
f0104afb:	31 d2                	xor    %edx,%edx
f0104afd:	83 c4 1c             	add    $0x1c,%esp
f0104b00:	5b                   	pop    %ebx
f0104b01:	5e                   	pop    %esi
f0104b02:	5f                   	pop    %edi
f0104b03:	5d                   	pop    %ebp
f0104b04:	c3                   	ret    
f0104b05:	8d 76 00             	lea    0x0(%esi),%esi
f0104b08:	39 dd                	cmp    %ebx,%ebp
f0104b0a:	77 f1                	ja     f0104afd <__umoddi3+0x2d>
f0104b0c:	0f bd cd             	bsr    %ebp,%ecx
f0104b0f:	83 f1 1f             	xor    $0x1f,%ecx
f0104b12:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104b16:	0f 84 b4 00 00 00    	je     f0104bd0 <__umoddi3+0x100>
f0104b1c:	b8 20 00 00 00       	mov    $0x20,%eax
f0104b21:	89 c2                	mov    %eax,%edx
f0104b23:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104b27:	29 c2                	sub    %eax,%edx
f0104b29:	89 c1                	mov    %eax,%ecx
f0104b2b:	89 f8                	mov    %edi,%eax
f0104b2d:	d3 e5                	shl    %cl,%ebp
f0104b2f:	89 d1                	mov    %edx,%ecx
f0104b31:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104b35:	d3 e8                	shr    %cl,%eax
f0104b37:	09 c5                	or     %eax,%ebp
f0104b39:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104b3d:	89 c1                	mov    %eax,%ecx
f0104b3f:	d3 e7                	shl    %cl,%edi
f0104b41:	89 d1                	mov    %edx,%ecx
f0104b43:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104b47:	89 df                	mov    %ebx,%edi
f0104b49:	d3 ef                	shr    %cl,%edi
f0104b4b:	89 c1                	mov    %eax,%ecx
f0104b4d:	89 f0                	mov    %esi,%eax
f0104b4f:	d3 e3                	shl    %cl,%ebx
f0104b51:	89 d1                	mov    %edx,%ecx
f0104b53:	89 fa                	mov    %edi,%edx
f0104b55:	d3 e8                	shr    %cl,%eax
f0104b57:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104b5c:	09 d8                	or     %ebx,%eax
f0104b5e:	f7 f5                	div    %ebp
f0104b60:	d3 e6                	shl    %cl,%esi
f0104b62:	89 d1                	mov    %edx,%ecx
f0104b64:	f7 64 24 08          	mull   0x8(%esp)
f0104b68:	39 d1                	cmp    %edx,%ecx
f0104b6a:	89 c3                	mov    %eax,%ebx
f0104b6c:	89 d7                	mov    %edx,%edi
f0104b6e:	72 06                	jb     f0104b76 <__umoddi3+0xa6>
f0104b70:	75 0e                	jne    f0104b80 <__umoddi3+0xb0>
f0104b72:	39 c6                	cmp    %eax,%esi
f0104b74:	73 0a                	jae    f0104b80 <__umoddi3+0xb0>
f0104b76:	2b 44 24 08          	sub    0x8(%esp),%eax
f0104b7a:	19 ea                	sbb    %ebp,%edx
f0104b7c:	89 d7                	mov    %edx,%edi
f0104b7e:	89 c3                	mov    %eax,%ebx
f0104b80:	89 ca                	mov    %ecx,%edx
f0104b82:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104b87:	29 de                	sub    %ebx,%esi
f0104b89:	19 fa                	sbb    %edi,%edx
f0104b8b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0104b8f:	89 d0                	mov    %edx,%eax
f0104b91:	d3 e0                	shl    %cl,%eax
f0104b93:	89 d9                	mov    %ebx,%ecx
f0104b95:	d3 ee                	shr    %cl,%esi
f0104b97:	d3 ea                	shr    %cl,%edx
f0104b99:	09 f0                	or     %esi,%eax
f0104b9b:	83 c4 1c             	add    $0x1c,%esp
f0104b9e:	5b                   	pop    %ebx
f0104b9f:	5e                   	pop    %esi
f0104ba0:	5f                   	pop    %edi
f0104ba1:	5d                   	pop    %ebp
f0104ba2:	c3                   	ret    
f0104ba3:	90                   	nop
f0104ba4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ba8:	85 ff                	test   %edi,%edi
f0104baa:	89 f9                	mov    %edi,%ecx
f0104bac:	75 0b                	jne    f0104bb9 <__umoddi3+0xe9>
f0104bae:	b8 01 00 00 00       	mov    $0x1,%eax
f0104bb3:	31 d2                	xor    %edx,%edx
f0104bb5:	f7 f7                	div    %edi
f0104bb7:	89 c1                	mov    %eax,%ecx
f0104bb9:	89 d8                	mov    %ebx,%eax
f0104bbb:	31 d2                	xor    %edx,%edx
f0104bbd:	f7 f1                	div    %ecx
f0104bbf:	89 f0                	mov    %esi,%eax
f0104bc1:	f7 f1                	div    %ecx
f0104bc3:	e9 31 ff ff ff       	jmp    f0104af9 <__umoddi3+0x29>
f0104bc8:	90                   	nop
f0104bc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104bd0:	39 dd                	cmp    %ebx,%ebp
f0104bd2:	72 08                	jb     f0104bdc <__umoddi3+0x10c>
f0104bd4:	39 f7                	cmp    %esi,%edi
f0104bd6:	0f 87 21 ff ff ff    	ja     f0104afd <__umoddi3+0x2d>
f0104bdc:	89 da                	mov    %ebx,%edx
f0104bde:	89 f0                	mov    %esi,%eax
f0104be0:	29 f8                	sub    %edi,%eax
f0104be2:	19 ea                	sbb    %ebp,%edx
f0104be4:	e9 14 ff ff ff       	jmp    f0104afd <__umoddi3+0x2d>
