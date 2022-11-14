
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
f0100064:	e8 d1 46 00 00       	call   f010473a <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 4e 05 00 00       	call   f01005bc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 60 9b f7 ff    	lea    -0x864a0(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 08 36 00 00       	call   f010368a <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 2c 13 00 00       	call   f01013b3 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100087:	e8 9a 31 00 00       	call   f0103226 <env_init>
	trap_init();
f010008c:	e8 ac 36 00 00       	call   f010373d <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100091:	83 c4 08             	add    $0x8,%esp
f0100094:	6a 00                	push   $0x0
f0100096:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010009c:	e8 be 32 00 00       	call   f010335f <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a1:	83 c4 04             	add    $0x4,%esp
f01000a4:	c7 c0 44 d3 18 f0    	mov    $0xf018d344,%eax
f01000aa:	ff 30                	pushl  (%eax)
f01000ac:	e8 28 35 00 00       	call   f01035d9 <env_run>

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
f01000f2:	8d 83 7b 9b f7 ff    	lea    -0x86485(%ebx),%eax
f01000f8:	50                   	push   %eax
f01000f9:	e8 8c 35 00 00       	call   f010368a <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	56                   	push   %esi
f0100102:	57                   	push   %edi
f0100103:	e8 4b 35 00 00       	call   f0103653 <vcprintf>
	cprintf("\n");
f0100108:	8d 83 56 ab f7 ff    	lea    -0x854aa(%ebx),%eax
f010010e:	89 04 24             	mov    %eax,(%esp)
f0100111:	e8 74 35 00 00       	call   f010368a <cprintf>
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
f0100137:	8d 83 93 9b f7 ff    	lea    -0x8646d(%ebx),%eax
f010013d:	50                   	push   %eax
f010013e:	e8 47 35 00 00       	call   f010368a <cprintf>
	vcprintf(fmt, ap);
f0100143:	83 c4 08             	add    $0x8,%esp
f0100146:	56                   	push   %esi
f0100147:	ff 75 10             	pushl  0x10(%ebp)
f010014a:	e8 04 35 00 00       	call   f0103653 <vcprintf>
	cprintf("\n");
f010014f:	8d 83 56 ab f7 ff    	lea    -0x854aa(%ebx),%eax
f0100155:	89 04 24             	mov    %eax,(%esp)
f0100158:	e8 2d 35 00 00       	call   f010368a <cprintf>
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
f010022f:	0f b6 84 13 e0 9c f7 	movzbl -0x86320(%ebx,%edx,1),%eax
f0100236:	ff 
f0100237:	0b 83 e0 20 00 00    	or     0x20e0(%ebx),%eax
	shift ^= togglecode[data];
f010023d:	0f b6 8c 13 e0 9b f7 	movzbl -0x86420(%ebx,%edx,1),%ecx
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
f0100282:	8d 83 ad 9b f7 ff    	lea    -0x86453(%ebx),%eax
f0100288:	50                   	push   %eax
f0100289:	e8 fc 33 00 00       	call   f010368a <cprintf>
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
f01002c9:	0f b6 84 13 e0 9c f7 	movzbl -0x86320(%ebx,%edx,1),%eax
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
f01004ea:	e8 98 42 00 00       	call   f0104787 <memmove>
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
f01006cd:	8d 83 b9 9b f7 ff    	lea    -0x86447(%ebx),%eax
f01006d3:	50                   	push   %eax
f01006d4:	e8 b1 2f 00 00       	call   f010368a <cprintf>
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
f0100720:	8d 83 e0 9d f7 ff    	lea    -0x86220(%ebx),%eax
f0100726:	50                   	push   %eax
f0100727:	8d 83 fe 9d f7 ff    	lea    -0x86202(%ebx),%eax
f010072d:	50                   	push   %eax
f010072e:	8d b3 03 9e f7 ff    	lea    -0x861fd(%ebx),%esi
f0100734:	56                   	push   %esi
f0100735:	e8 50 2f 00 00       	call   f010368a <cprintf>
f010073a:	83 c4 0c             	add    $0xc,%esp
f010073d:	8d 83 d0 9e f7 ff    	lea    -0x86130(%ebx),%eax
f0100743:	50                   	push   %eax
f0100744:	8d 83 0c 9e f7 ff    	lea    -0x861f4(%ebx),%eax
f010074a:	50                   	push   %eax
f010074b:	56                   	push   %esi
f010074c:	e8 39 2f 00 00       	call   f010368a <cprintf>
f0100751:	83 c4 0c             	add    $0xc,%esp
f0100754:	8d 83 f8 9e f7 ff    	lea    -0x86108(%ebx),%eax
f010075a:	50                   	push   %eax
f010075b:	8d 83 15 9e f7 ff    	lea    -0x861eb(%ebx),%eax
f0100761:	50                   	push   %eax
f0100762:	56                   	push   %esi
f0100763:	e8 22 2f 00 00       	call   f010368a <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	8d 83 1c 9f f7 ff    	lea    -0x860e4(%ebx),%eax
f0100771:	50                   	push   %eax
f0100772:	8d 83 1f 9e f7 ff    	lea    -0x861e1(%ebx),%eax
f0100778:	50                   	push   %eax
f0100779:	56                   	push   %esi
f010077a:	e8 0b 2f 00 00       	call   f010368a <cprintf>
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
f010079f:	8d 83 2c 9e f7 ff    	lea    -0x861d4(%ebx),%eax
f01007a5:	50                   	push   %eax
f01007a6:	e8 df 2e 00 00       	call   f010368a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ab:	83 c4 08             	add    $0x8,%esp
f01007ae:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007b4:	8d 83 68 9f f7 ff    	lea    -0x86098(%ebx),%eax
f01007ba:	50                   	push   %eax
f01007bb:	e8 ca 2e 00 00       	call   f010368a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007c9:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007cf:	50                   	push   %eax
f01007d0:	57                   	push   %edi
f01007d1:	8d 83 90 9f f7 ff    	lea    -0x86070(%ebx),%eax
f01007d7:	50                   	push   %eax
f01007d8:	e8 ad 2e 00 00       	call   f010368a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007dd:	83 c4 0c             	add    $0xc,%esp
f01007e0:	c7 c0 79 4b 10 f0    	mov    $0xf0104b79,%eax
f01007e6:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007ec:	52                   	push   %edx
f01007ed:	50                   	push   %eax
f01007ee:	8d 83 b4 9f f7 ff    	lea    -0x8604c(%ebx),%eax
f01007f4:	50                   	push   %eax
f01007f5:	e8 90 2e 00 00       	call   f010368a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007fa:	83 c4 0c             	add    $0xc,%esp
f01007fd:	c7 c0 00 d1 18 f0    	mov    $0xf018d100,%eax
f0100803:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100809:	52                   	push   %edx
f010080a:	50                   	push   %eax
f010080b:	8d 83 d8 9f f7 ff    	lea    -0x86028(%ebx),%eax
f0100811:	50                   	push   %eax
f0100812:	e8 73 2e 00 00       	call   f010368a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	c7 c6 00 e0 18 f0    	mov    $0xf018e000,%esi
f0100820:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100826:	50                   	push   %eax
f0100827:	56                   	push   %esi
f0100828:	8d 83 fc 9f f7 ff    	lea    -0x86004(%ebx),%eax
f010082e:	50                   	push   %eax
f010082f:	e8 56 2e 00 00       	call   f010368a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100834:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100837:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010083d:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010083f:	c1 fe 0a             	sar    $0xa,%esi
f0100842:	56                   	push   %esi
f0100843:	8d 83 20 a0 f7 ff    	lea    -0x85fe0(%ebx),%eax
f0100849:	50                   	push   %eax
f010084a:	e8 3b 2e 00 00       	call   f010368a <cprintf>
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
f010086e:	8d 83 4c a0 f7 ff    	lea    -0x85fb4(%ebx),%eax
f0100874:	50                   	push   %eax
f0100875:	e8 10 2e 00 00       	call   f010368a <cprintf>
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
f0100898:	8d 83 45 9e f7 ff    	lea    -0x861bb(%ebx),%eax
f010089e:	50                   	push   %eax
f010089f:	e8 e6 2d 00 00       	call   f010368a <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a4:	89 ef                	mov    %ebp,%edi
	while(this_ebp!=0){
f01008a6:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
f01008a9:	8d 83 57 9e f7 ff    	lea    -0x861a9(%ebx),%eax
f01008af:	89 45 b8             	mov    %eax,-0x48(%ebp)
			cprintf(" %08x", *(this_ebp + 2 + i));
f01008b2:	8d 83 72 9e f7 ff    	lea    -0x8618e(%ebx),%eax
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
f01008d3:	e8 b2 2d 00 00       	call   f010368a <cprintf>
f01008d8:	8d 77 08             	lea    0x8(%edi),%esi
f01008db:	83 c7 1c             	add    $0x1c,%edi
f01008de:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f01008e1:	83 ec 08             	sub    $0x8,%esp
f01008e4:	ff 36                	pushl  (%esi)
f01008e6:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008e9:	e8 9c 2d 00 00       	call   f010368a <cprintf>
f01008ee:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f01008f1:	83 c4 10             	add    $0x10,%esp
f01008f4:	39 fe                	cmp    %edi,%esi
f01008f6:	75 e9                	jne    f01008e1 <mon_backtrace+0x5d>
		cprintf("\n");
f01008f8:	83 ec 0c             	sub    $0xc,%esp
f01008fb:	8d 83 56 ab f7 ff    	lea    -0x854aa(%ebx),%eax
f0100901:	50                   	push   %eax
f0100902:	e8 83 2d 00 00       	call   f010368a <cprintf>
		debuginfo_eip(eip, &info);
f0100907:	83 c4 08             	add    $0x8,%esp
f010090a:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010090d:	50                   	push   %eax
f010090e:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100911:	57                   	push   %edi
f0100912:	e8 19 33 00 00       	call   f0103c30 <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f0100917:	83 c4 0c             	add    $0xc,%esp
f010091a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010091d:	ff 75 d0             	pushl  -0x30(%ebp)
f0100920:	8d 83 78 9e f7 ff    	lea    -0x86188(%ebx),%eax
f0100926:	50                   	push   %eax
f0100927:	e8 5e 2d 00 00       	call   f010368a <cprintf>
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f010092c:	89 f8                	mov    %edi,%eax
f010092e:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100931:	50                   	push   %eax
f0100932:	ff 75 d8             	pushl  -0x28(%ebp)
f0100935:	ff 75 dc             	pushl  -0x24(%ebp)
f0100938:	8d 83 88 9e f7 ff    	lea    -0x86178(%ebx),%eax
f010093e:	50                   	push   %eax
f010093f:	e8 46 2d 00 00       	call   f010368a <cprintf>
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
f0100973:	8d 83 6c a0 f7 ff    	lea    -0x85f94(%ebx),%eax
f0100979:	50                   	push   %eax
f010097a:	e8 0b 2d 00 00       	call   f010368a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010097f:	8d 83 90 a0 f7 ff    	lea    -0x85f70(%ebx),%eax
f0100985:	89 04 24             	mov    %eax,(%esp)
f0100988:	e8 fd 2c 00 00       	call   f010368a <cprintf>

	if (tf != NULL)
f010098d:	83 c4 10             	add    $0x10,%esp
f0100990:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100994:	74 0e                	je     f01009a4 <monitor+0x45>
		print_trapframe(tf);
f0100996:	83 ec 0c             	sub    $0xc,%esp
f0100999:	ff 75 08             	pushl  0x8(%ebp)
f010099c:	e8 52 2e 00 00       	call   f01037f3 <print_trapframe>
f01009a1:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01009a4:	8d bb 95 9e f7 ff    	lea    -0x8616b(%ebx),%edi
f01009aa:	eb 4a                	jmp    f01009f6 <monitor+0x97>
f01009ac:	83 ec 08             	sub    $0x8,%esp
f01009af:	0f be c0             	movsbl %al,%eax
f01009b2:	50                   	push   %eax
f01009b3:	57                   	push   %edi
f01009b4:	e8 44 3d 00 00       	call   f01046fd <strchr>
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
f01009e7:	8d 83 9a 9e f7 ff    	lea    -0x86166(%ebx),%eax
f01009ed:	50                   	push   %eax
f01009ee:	e8 97 2c 00 00       	call   f010368a <cprintf>
f01009f3:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009f6:	8d 83 91 9e f7 ff    	lea    -0x8616f(%ebx),%eax
f01009fc:	89 c6                	mov    %eax,%esi
f01009fe:	83 ec 0c             	sub    $0xc,%esp
f0100a01:	56                   	push   %esi
f0100a02:	e8 be 3a 00 00       	call   f01044c5 <readline>
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
f0100a32:	e8 c6 3c 00 00       	call   f01046fd <strchr>
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
f0100a70:	e8 2a 3c 00 00       	call   f010469f <strcmp>
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
f0100a90:	8d 83 b7 9e f7 ff    	lea    -0x86149(%ebx),%eax
f0100a96:	50                   	push   %eax
f0100a97:	e8 ee 2b 00 00       	call   f010368a <cprintf>
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
f0100ad6:	e8 74 26 00 00       	call   f010314f <__x86.get_pc_thunk.dx>
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
f0100b43:	e8 bb 2a 00 00       	call   f0103603 <mc146818_read>
f0100b48:	89 c6                	mov    %eax,%esi
f0100b4a:	83 c7 01             	add    $0x1,%edi
f0100b4d:	89 3c 24             	mov    %edi,(%esp)
f0100b50:	e8 ae 2a 00 00       	call   f0103603 <mc146818_read>
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
f0100b67:	e8 e7 25 00 00       	call   f0103153 <__x86.get_pc_thunk.cx>
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
f0100bbe:	8d 81 b8 a0 f7 ff    	lea    -0x85f48(%ecx),%eax
f0100bc4:	50                   	push   %eax
f0100bc5:	68 36 03 00 00       	push   $0x336
f0100bca:	8d 81 a5 a8 f7 ff    	lea    -0x8575b(%ecx),%eax
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
f0100be8:	e8 6e 25 00 00       	call   f010315b <__x86.get_pc_thunk.di>
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
f0100c1c:	8d 83 dc a0 f7 ff    	lea    -0x85f24(%ebx),%eax
f0100c22:	50                   	push   %eax
f0100c23:	68 72 02 00 00       	push   $0x272
f0100c28:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0100c2e:	50                   	push   %eax
f0100c2f:	e8 7d f4 ff ff       	call   f01000b1 <_panic>
f0100c34:	50                   	push   %eax
f0100c35:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c38:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f0100c3e:	50                   	push   %eax
f0100c3f:	6a 5d                	push   $0x5d
f0100c41:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
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
f0100c89:	e8 ac 3a 00 00       	call   f010473a <memset>
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
f0100cd2:	8d 83 bf a8 f7 ff    	lea    -0x85741(%ebx),%eax
f0100cd8:	50                   	push   %eax
f0100cd9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100cdf:	50                   	push   %eax
f0100ce0:	68 8c 02 00 00       	push   $0x28c
f0100ce5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0100ceb:	50                   	push   %eax
f0100cec:	e8 c0 f3 ff ff       	call   f01000b1 <_panic>
		assert(pp < pages + npages);
f0100cf1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cf4:	8d 83 e0 a8 f7 ff    	lea    -0x85720(%ebx),%eax
f0100cfa:	50                   	push   %eax
f0100cfb:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100d01:	50                   	push   %eax
f0100d02:	68 8d 02 00 00       	push   $0x28d
f0100d07:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0100d0d:	50                   	push   %eax
f0100d0e:	e8 9e f3 ff ff       	call   f01000b1 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d13:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d16:	8d 83 00 a1 f7 ff    	lea    -0x85f00(%ebx),%eax
f0100d1c:	50                   	push   %eax
f0100d1d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100d23:	50                   	push   %eax
f0100d24:	68 8e 02 00 00       	push   $0x28e
f0100d29:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0100d2f:	50                   	push   %eax
f0100d30:	e8 7c f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != 0);
f0100d35:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d38:	8d 83 f4 a8 f7 ff    	lea    -0x8570c(%ebx),%eax
f0100d3e:	50                   	push   %eax
f0100d3f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100d45:	50                   	push   %eax
f0100d46:	68 91 02 00 00       	push   $0x291
f0100d4b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0100d51:	50                   	push   %eax
f0100d52:	e8 5a f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d57:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d5a:	8d 83 05 a9 f7 ff    	lea    -0x856fb(%ebx),%eax
f0100d60:	50                   	push   %eax
f0100d61:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100d67:	50                   	push   %eax
f0100d68:	68 92 02 00 00       	push   $0x292
f0100d6d:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0100d73:	50                   	push   %eax
f0100d74:	e8 38 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d79:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d7c:	8d 83 34 a1 f7 ff    	lea    -0x85ecc(%ebx),%eax
f0100d82:	50                   	push   %eax
f0100d83:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100d89:	50                   	push   %eax
f0100d8a:	68 93 02 00 00       	push   $0x293
f0100d8f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0100d95:	50                   	push   %eax
f0100d96:	e8 16 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d9b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d9e:	8d 83 1e a9 f7 ff    	lea    -0x856e2(%ebx),%eax
f0100da4:	50                   	push   %eax
f0100da5:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100dab:	50                   	push   %eax
f0100dac:	68 94 02 00 00       	push   $0x294
f0100db1:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
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
f0100e3b:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f0100e41:	50                   	push   %eax
f0100e42:	6a 5d                	push   $0x5d
f0100e44:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f0100e4a:	50                   	push   %eax
f0100e4b:	e8 61 f2 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e50:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e53:	8d 83 58 a1 f7 ff    	lea    -0x85ea8(%ebx),%eax
f0100e59:	50                   	push   %eax
f0100e5a:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100e60:	50                   	push   %eax
f0100e61:	68 95 02 00 00       	push   $0x295
f0100e66:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
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
f0100e83:	8d 83 a0 a1 f7 ff    	lea    -0x85e60(%ebx),%eax
f0100e89:	50                   	push   %eax
f0100e8a:	e8 fb 27 00 00       	call   f010368a <cprintf>
}
f0100e8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e92:	5b                   	pop    %ebx
f0100e93:	5e                   	pop    %esi
f0100e94:	5f                   	pop    %edi
f0100e95:	5d                   	pop    %ebp
f0100e96:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e97:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e9a:	8d 83 38 a9 f7 ff    	lea    -0x856c8(%ebx),%eax
f0100ea0:	50                   	push   %eax
f0100ea1:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100ea7:	50                   	push   %eax
f0100ea8:	68 9d 02 00 00       	push   $0x29d
f0100ead:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0100eb3:	50                   	push   %eax
f0100eb4:	e8 f8 f1 ff ff       	call   f01000b1 <_panic>
	assert(nfree_extmem > 0);
f0100eb9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ebc:	8d 83 4a a9 f7 ff    	lea    -0x856b6(%ebx),%eax
f0100ec2:	50                   	push   %eax
f0100ec3:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0100ec9:	50                   	push   %eax
f0100eca:	68 9e 02 00 00       	push   $0x29e
f0100ecf:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
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
f0100f6b:	e8 e7 21 00 00       	call   f0103157 <__x86.get_pc_thunk.si>
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
f0100fbb:	8d 86 c4 a1 f7 ff    	lea    -0x85e3c(%esi),%eax
f0100fc1:	50                   	push   %eax
f0100fc2:	68 20 01 00 00       	push   $0x120
f0100fc7:	8d 86 a5 a8 f7 ff    	lea    -0x8575b(%esi),%eax
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
f01010b9:	e8 7c 36 00 00       	call   f010473a <memset>
f01010be:	83 c4 10             	add    $0x10,%esp
f01010c1:	eb bc                	jmp    f010107f <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010c3:	50                   	push   %eax
f01010c4:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f01010ca:	50                   	push   %eax
f01010cb:	6a 5d                	push   $0x5d
f01010cd:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
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
f0101110:	8d 83 e8 a1 f7 ff    	lea    -0x85e18(%ebx),%eax
f0101116:	50                   	push   %eax
f0101117:	68 5a 01 00 00       	push   $0x15a
f010111c:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
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
f01011d6:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f01011dc:	50                   	push   %eax
f01011dd:	68 9c 01 00 00       	push   $0x19c
f01011e2:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
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
f0101205:	e8 51 1f 00 00       	call   f010315b <__x86.get_pc_thunk.di>
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
f0101268:	8d 83 08 a2 f7 ff    	lea    -0x85df8(%ebx),%eax
f010126e:	50                   	push   %eax
f010126f:	68 b6 01 00 00       	push   $0x1b6
f0101274:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
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
f01012dc:	8d 83 2c a2 f7 ff    	lea    -0x85dd4(%ebx),%eax
f01012e2:	50                   	push   %eax
f01012e3:	6a 56                	push   $0x56
f01012e5:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
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
f010133e:	e8 18 1e 00 00       	call   f010315b <__x86.get_pc_thunk.di>
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
f01013f0:	0f 85 c2 00 00 00    	jne    f01014b8 <mem_init+0x105>
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
f0101418:	8d 87 4c a2 f7 ff    	lea    -0x85db4(%edi),%eax
f010141e:	50                   	push   %eax
f010141f:	89 fb                	mov    %edi,%ebx
f0101421:	e8 64 22 00 00       	call   f010368a <cprintf>
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
f0101443:	e8 f2 32 00 00       	call   f010473a <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101448:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010144a:	83 c4 10             	add    $0x10,%esp
f010144d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101452:	76 6e                	jbe    f01014c2 <mem_init+0x10f>
	return (physaddr_t)kva - KERNBASE;
f0101454:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010145a:	83 ca 05             	or     $0x5,%edx
f010145d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101463:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101466:	c7 c3 08 e0 18 f0    	mov    $0xf018e008,%ebx
f010146c:	8b 03                	mov    (%ebx),%eax
f010146e:	c1 e0 03             	shl    $0x3,%eax
f0101471:	e8 5d f6 ff ff       	call   f0100ad3 <boot_alloc>
f0101476:	c7 c6 10 e0 18 f0    	mov    $0xf018e010,%esi
f010147c:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010147e:	83 ec 04             	sub    $0x4,%esp
f0101481:	8b 13                	mov    (%ebx),%edx
f0101483:	c1 e2 03             	shl    $0x3,%edx
f0101486:	52                   	push   %edx
f0101487:	6a 00                	push   $0x0
f0101489:	50                   	push   %eax
f010148a:	89 fb                	mov    %edi,%ebx
f010148c:	e8 a9 32 00 00       	call   f010473a <memset>
	page_init();
f0101491:	e8 cc fa ff ff       	call   f0100f62 <page_init>
	check_page_free_list(1);
f0101496:	b8 01 00 00 00       	mov    $0x1,%eax
f010149b:	e8 3f f7 ff ff       	call   f0100bdf <check_page_free_list>
	if (!pages)
f01014a0:	83 c4 10             	add    $0x10,%esp
f01014a3:	83 3e 00             	cmpl   $0x0,(%esi)
f01014a6:	74 36                	je     f01014de <mem_init+0x12b>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014ab:	8b 80 1c 23 00 00    	mov    0x231c(%eax),%eax
f01014b1:	be 00 00 00 00       	mov    $0x0,%esi
f01014b6:	eb 49                	jmp    f0101501 <mem_init+0x14e>
		totalmem = 16 * 1024 + ext16mem;
f01014b8:	05 00 40 00 00       	add    $0x4000,%eax
f01014bd:	e9 3f ff ff ff       	jmp    f0101401 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014c2:	50                   	push   %eax
f01014c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01014c6:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f01014cc:	50                   	push   %eax
f01014cd:	68 9c 00 00 00       	push   $0x9c
f01014d2:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01014d8:	50                   	push   %eax
f01014d9:	e8 d3 eb ff ff       	call   f01000b1 <_panic>
		panic("'pages' is a null pointer!");
f01014de:	83 ec 04             	sub    $0x4,%esp
f01014e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01014e4:	8d 83 5b a9 f7 ff    	lea    -0x856a5(%ebx),%eax
f01014ea:	50                   	push   %eax
f01014eb:	68 b1 02 00 00       	push   $0x2b1
f01014f0:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01014f6:	50                   	push   %eax
f01014f7:	e8 b5 eb ff ff       	call   f01000b1 <_panic>
		++nfree;
f01014fc:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014ff:	8b 00                	mov    (%eax),%eax
f0101501:	85 c0                	test   %eax,%eax
f0101503:	75 f7                	jne    f01014fc <mem_init+0x149>
	assert((pp0 = page_alloc(0)));
f0101505:	83 ec 0c             	sub    $0xc,%esp
f0101508:	6a 00                	push   $0x0
f010150a:	e8 42 fb ff ff       	call   f0101051 <page_alloc>
f010150f:	89 c3                	mov    %eax,%ebx
f0101511:	83 c4 10             	add    $0x10,%esp
f0101514:	85 c0                	test   %eax,%eax
f0101516:	0f 84 3b 02 00 00    	je     f0101757 <mem_init+0x3a4>
	assert((pp1 = page_alloc(0)));
f010151c:	83 ec 0c             	sub    $0xc,%esp
f010151f:	6a 00                	push   $0x0
f0101521:	e8 2b fb ff ff       	call   f0101051 <page_alloc>
f0101526:	89 c7                	mov    %eax,%edi
f0101528:	83 c4 10             	add    $0x10,%esp
f010152b:	85 c0                	test   %eax,%eax
f010152d:	0f 84 46 02 00 00    	je     f0101779 <mem_init+0x3c6>
	assert((pp2 = page_alloc(0)));
f0101533:	83 ec 0c             	sub    $0xc,%esp
f0101536:	6a 00                	push   $0x0
f0101538:	e8 14 fb ff ff       	call   f0101051 <page_alloc>
f010153d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101540:	83 c4 10             	add    $0x10,%esp
f0101543:	85 c0                	test   %eax,%eax
f0101545:	0f 84 50 02 00 00    	je     f010179b <mem_init+0x3e8>
	assert(pp1 && pp1 != pp0);
f010154b:	39 fb                	cmp    %edi,%ebx
f010154d:	0f 84 6a 02 00 00    	je     f01017bd <mem_init+0x40a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101553:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101556:	39 c3                	cmp    %eax,%ebx
f0101558:	0f 84 81 02 00 00    	je     f01017df <mem_init+0x42c>
f010155e:	39 c7                	cmp    %eax,%edi
f0101560:	0f 84 79 02 00 00    	je     f01017df <mem_init+0x42c>
	return (pp - pages) << PGSHIFT;
f0101566:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101569:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f010156f:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101571:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f0101577:	8b 10                	mov    (%eax),%edx
f0101579:	c1 e2 0c             	shl    $0xc,%edx
f010157c:	89 d8                	mov    %ebx,%eax
f010157e:	29 c8                	sub    %ecx,%eax
f0101580:	c1 f8 03             	sar    $0x3,%eax
f0101583:	c1 e0 0c             	shl    $0xc,%eax
f0101586:	39 d0                	cmp    %edx,%eax
f0101588:	0f 83 73 02 00 00    	jae    f0101801 <mem_init+0x44e>
f010158e:	89 f8                	mov    %edi,%eax
f0101590:	29 c8                	sub    %ecx,%eax
f0101592:	c1 f8 03             	sar    $0x3,%eax
f0101595:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101598:	39 c2                	cmp    %eax,%edx
f010159a:	0f 86 83 02 00 00    	jbe    f0101823 <mem_init+0x470>
f01015a0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015a3:	29 c8                	sub    %ecx,%eax
f01015a5:	c1 f8 03             	sar    $0x3,%eax
f01015a8:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01015ab:	39 c2                	cmp    %eax,%edx
f01015ad:	0f 86 92 02 00 00    	jbe    f0101845 <mem_init+0x492>
	fl = page_free_list;
f01015b3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015b6:	8b 88 1c 23 00 00    	mov    0x231c(%eax),%ecx
f01015bc:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01015bf:	c7 80 1c 23 00 00 00 	movl   $0x0,0x231c(%eax)
f01015c6:	00 00 00 
	assert(!page_alloc(0));
f01015c9:	83 ec 0c             	sub    $0xc,%esp
f01015cc:	6a 00                	push   $0x0
f01015ce:	e8 7e fa ff ff       	call   f0101051 <page_alloc>
f01015d3:	83 c4 10             	add    $0x10,%esp
f01015d6:	85 c0                	test   %eax,%eax
f01015d8:	0f 85 89 02 00 00    	jne    f0101867 <mem_init+0x4b4>
	page_free(pp0);
f01015de:	83 ec 0c             	sub    $0xc,%esp
f01015e1:	53                   	push   %ebx
f01015e2:	e8 f2 fa ff ff       	call   f01010d9 <page_free>
	page_free(pp1);
f01015e7:	89 3c 24             	mov    %edi,(%esp)
f01015ea:	e8 ea fa ff ff       	call   f01010d9 <page_free>
	page_free(pp2);
f01015ef:	83 c4 04             	add    $0x4,%esp
f01015f2:	ff 75 d0             	pushl  -0x30(%ebp)
f01015f5:	e8 df fa ff ff       	call   f01010d9 <page_free>
	assert((pp0 = page_alloc(0)));
f01015fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101601:	e8 4b fa ff ff       	call   f0101051 <page_alloc>
f0101606:	89 c7                	mov    %eax,%edi
f0101608:	83 c4 10             	add    $0x10,%esp
f010160b:	85 c0                	test   %eax,%eax
f010160d:	0f 84 76 02 00 00    	je     f0101889 <mem_init+0x4d6>
	assert((pp1 = page_alloc(0)));
f0101613:	83 ec 0c             	sub    $0xc,%esp
f0101616:	6a 00                	push   $0x0
f0101618:	e8 34 fa ff ff       	call   f0101051 <page_alloc>
f010161d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101620:	83 c4 10             	add    $0x10,%esp
f0101623:	85 c0                	test   %eax,%eax
f0101625:	0f 84 80 02 00 00    	je     f01018ab <mem_init+0x4f8>
	assert((pp2 = page_alloc(0)));
f010162b:	83 ec 0c             	sub    $0xc,%esp
f010162e:	6a 00                	push   $0x0
f0101630:	e8 1c fa ff ff       	call   f0101051 <page_alloc>
f0101635:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101638:	83 c4 10             	add    $0x10,%esp
f010163b:	85 c0                	test   %eax,%eax
f010163d:	0f 84 8a 02 00 00    	je     f01018cd <mem_init+0x51a>
	assert(pp1 && pp1 != pp0);
f0101643:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f0101646:	0f 84 a3 02 00 00    	je     f01018ef <mem_init+0x53c>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010164c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010164f:	39 c7                	cmp    %eax,%edi
f0101651:	0f 84 ba 02 00 00    	je     f0101911 <mem_init+0x55e>
f0101657:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010165a:	0f 84 b1 02 00 00    	je     f0101911 <mem_init+0x55e>
	assert(!page_alloc(0));
f0101660:	83 ec 0c             	sub    $0xc,%esp
f0101663:	6a 00                	push   $0x0
f0101665:	e8 e7 f9 ff ff       	call   f0101051 <page_alloc>
f010166a:	83 c4 10             	add    $0x10,%esp
f010166d:	85 c0                	test   %eax,%eax
f010166f:	0f 85 be 02 00 00    	jne    f0101933 <mem_init+0x580>
f0101675:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101678:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f010167e:	89 f9                	mov    %edi,%ecx
f0101680:	2b 08                	sub    (%eax),%ecx
f0101682:	89 c8                	mov    %ecx,%eax
f0101684:	c1 f8 03             	sar    $0x3,%eax
f0101687:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010168a:	89 c1                	mov    %eax,%ecx
f010168c:	c1 e9 0c             	shr    $0xc,%ecx
f010168f:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0101695:	3b 0a                	cmp    (%edx),%ecx
f0101697:	0f 83 b8 02 00 00    	jae    f0101955 <mem_init+0x5a2>
	memset(page2kva(pp0), 1, PGSIZE);
f010169d:	83 ec 04             	sub    $0x4,%esp
f01016a0:	68 00 10 00 00       	push   $0x1000
f01016a5:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01016a7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016ac:	50                   	push   %eax
f01016ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016b0:	e8 85 30 00 00       	call   f010473a <memset>
	page_free(pp0);
f01016b5:	89 3c 24             	mov    %edi,(%esp)
f01016b8:	e8 1c fa ff ff       	call   f01010d9 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016bd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016c4:	e8 88 f9 ff ff       	call   f0101051 <page_alloc>
f01016c9:	83 c4 10             	add    $0x10,%esp
f01016cc:	85 c0                	test   %eax,%eax
f01016ce:	0f 84 97 02 00 00    	je     f010196b <mem_init+0x5b8>
	assert(pp && pp0 == pp);
f01016d4:	39 c7                	cmp    %eax,%edi
f01016d6:	0f 85 b1 02 00 00    	jne    f010198d <mem_init+0x5da>
	return (pp - pages) << PGSHIFT;
f01016dc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016df:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f01016e5:	89 fa                	mov    %edi,%edx
f01016e7:	2b 10                	sub    (%eax),%edx
f01016e9:	c1 fa 03             	sar    $0x3,%edx
f01016ec:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016ef:	89 d1                	mov    %edx,%ecx
f01016f1:	c1 e9 0c             	shr    $0xc,%ecx
f01016f4:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f01016fa:	3b 08                	cmp    (%eax),%ecx
f01016fc:	0f 83 ad 02 00 00    	jae    f01019af <mem_init+0x5fc>
	return (void *)(pa + KERNBASE);
f0101702:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101708:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f010170e:	80 38 00             	cmpb   $0x0,(%eax)
f0101711:	0f 85 ae 02 00 00    	jne    f01019c5 <mem_init+0x612>
f0101717:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f010171a:	39 d0                	cmp    %edx,%eax
f010171c:	75 f0                	jne    f010170e <mem_init+0x35b>
	page_free_list = fl;
f010171e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101721:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101724:	89 8b 1c 23 00 00    	mov    %ecx,0x231c(%ebx)
	page_free(pp0);
f010172a:	83 ec 0c             	sub    $0xc,%esp
f010172d:	57                   	push   %edi
f010172e:	e8 a6 f9 ff ff       	call   f01010d9 <page_free>
	page_free(pp1);
f0101733:	83 c4 04             	add    $0x4,%esp
f0101736:	ff 75 d0             	pushl  -0x30(%ebp)
f0101739:	e8 9b f9 ff ff       	call   f01010d9 <page_free>
	page_free(pp2);
f010173e:	83 c4 04             	add    $0x4,%esp
f0101741:	ff 75 cc             	pushl  -0x34(%ebp)
f0101744:	e8 90 f9 ff ff       	call   f01010d9 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101749:	8b 83 1c 23 00 00    	mov    0x231c(%ebx),%eax
f010174f:	83 c4 10             	add    $0x10,%esp
f0101752:	e9 95 02 00 00       	jmp    f01019ec <mem_init+0x639>
	assert((pp0 = page_alloc(0)));
f0101757:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010175a:	8d 83 76 a9 f7 ff    	lea    -0x8568a(%ebx),%eax
f0101760:	50                   	push   %eax
f0101761:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101767:	50                   	push   %eax
f0101768:	68 b9 02 00 00       	push   $0x2b9
f010176d:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0101773:	50                   	push   %eax
f0101774:	e8 38 e9 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0101779:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010177c:	8d 83 8c a9 f7 ff    	lea    -0x85674(%ebx),%eax
f0101782:	50                   	push   %eax
f0101783:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101789:	50                   	push   %eax
f010178a:	68 ba 02 00 00       	push   $0x2ba
f010178f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0101795:	50                   	push   %eax
f0101796:	e8 16 e9 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f010179b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010179e:	8d 83 a2 a9 f7 ff    	lea    -0x8565e(%ebx),%eax
f01017a4:	50                   	push   %eax
f01017a5:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01017ab:	50                   	push   %eax
f01017ac:	68 bb 02 00 00       	push   $0x2bb
f01017b1:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01017b7:	50                   	push   %eax
f01017b8:	e8 f4 e8 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01017bd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017c0:	8d 83 b8 a9 f7 ff    	lea    -0x85648(%ebx),%eax
f01017c6:	50                   	push   %eax
f01017c7:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01017cd:	50                   	push   %eax
f01017ce:	68 be 02 00 00       	push   $0x2be
f01017d3:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01017d9:	50                   	push   %eax
f01017da:	e8 d2 e8 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017df:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017e2:	8d 83 88 a2 f7 ff    	lea    -0x85d78(%ebx),%eax
f01017e8:	50                   	push   %eax
f01017e9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01017ef:	50                   	push   %eax
f01017f0:	68 bf 02 00 00       	push   $0x2bf
f01017f5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01017fb:	50                   	push   %eax
f01017fc:	e8 b0 e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101801:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101804:	8d 83 ca a9 f7 ff    	lea    -0x85636(%ebx),%eax
f010180a:	50                   	push   %eax
f010180b:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101811:	50                   	push   %eax
f0101812:	68 c0 02 00 00       	push   $0x2c0
f0101817:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010181d:	50                   	push   %eax
f010181e:	e8 8e e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101823:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101826:	8d 83 e7 a9 f7 ff    	lea    -0x85619(%ebx),%eax
f010182c:	50                   	push   %eax
f010182d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101833:	50                   	push   %eax
f0101834:	68 c1 02 00 00       	push   $0x2c1
f0101839:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010183f:	50                   	push   %eax
f0101840:	e8 6c e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101845:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101848:	8d 83 04 aa f7 ff    	lea    -0x855fc(%ebx),%eax
f010184e:	50                   	push   %eax
f010184f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101855:	50                   	push   %eax
f0101856:	68 c2 02 00 00       	push   $0x2c2
f010185b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0101861:	50                   	push   %eax
f0101862:	e8 4a e8 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101867:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010186a:	8d 83 21 aa f7 ff    	lea    -0x855df(%ebx),%eax
f0101870:	50                   	push   %eax
f0101871:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101877:	50                   	push   %eax
f0101878:	68 c9 02 00 00       	push   $0x2c9
f010187d:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0101883:	50                   	push   %eax
f0101884:	e8 28 e8 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0101889:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010188c:	8d 83 76 a9 f7 ff    	lea    -0x8568a(%ebx),%eax
f0101892:	50                   	push   %eax
f0101893:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101899:	50                   	push   %eax
f010189a:	68 d0 02 00 00       	push   $0x2d0
f010189f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01018a5:	50                   	push   %eax
f01018a6:	e8 06 e8 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01018ab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018ae:	8d 83 8c a9 f7 ff    	lea    -0x85674(%ebx),%eax
f01018b4:	50                   	push   %eax
f01018b5:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01018bb:	50                   	push   %eax
f01018bc:	68 d1 02 00 00       	push   $0x2d1
f01018c1:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01018c7:	50                   	push   %eax
f01018c8:	e8 e4 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01018cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018d0:	8d 83 a2 a9 f7 ff    	lea    -0x8565e(%ebx),%eax
f01018d6:	50                   	push   %eax
f01018d7:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01018dd:	50                   	push   %eax
f01018de:	68 d2 02 00 00       	push   $0x2d2
f01018e3:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01018e9:	50                   	push   %eax
f01018ea:	e8 c2 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01018ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018f2:	8d 83 b8 a9 f7 ff    	lea    -0x85648(%ebx),%eax
f01018f8:	50                   	push   %eax
f01018f9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01018ff:	50                   	push   %eax
f0101900:	68 d4 02 00 00       	push   $0x2d4
f0101905:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010190b:	50                   	push   %eax
f010190c:	e8 a0 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101911:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101914:	8d 83 88 a2 f7 ff    	lea    -0x85d78(%ebx),%eax
f010191a:	50                   	push   %eax
f010191b:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101921:	50                   	push   %eax
f0101922:	68 d5 02 00 00       	push   $0x2d5
f0101927:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010192d:	50                   	push   %eax
f010192e:	e8 7e e7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101933:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101936:	8d 83 21 aa f7 ff    	lea    -0x855df(%ebx),%eax
f010193c:	50                   	push   %eax
f010193d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0101943:	50                   	push   %eax
f0101944:	68 d6 02 00 00       	push   $0x2d6
f0101949:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010194f:	50                   	push   %eax
f0101950:	e8 5c e7 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101955:	50                   	push   %eax
f0101956:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f010195c:	50                   	push   %eax
f010195d:	6a 5d                	push   $0x5d
f010195f:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f0101965:	50                   	push   %eax
f0101966:	e8 46 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010196b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010196e:	8d 83 30 aa f7 ff    	lea    -0x855d0(%ebx),%eax
f0101974:	50                   	push   %eax
f0101975:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010197b:	50                   	push   %eax
f010197c:	68 db 02 00 00       	push   $0x2db
f0101981:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0101987:	50                   	push   %eax
f0101988:	e8 24 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp && pp0 == pp);
f010198d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101990:	8d 83 4e aa f7 ff    	lea    -0x855b2(%ebx),%eax
f0101996:	50                   	push   %eax
f0101997:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010199d:	50                   	push   %eax
f010199e:	68 dc 02 00 00       	push   $0x2dc
f01019a3:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01019a9:	50                   	push   %eax
f01019aa:	e8 02 e7 ff ff       	call   f01000b1 <_panic>
f01019af:	52                   	push   %edx
f01019b0:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f01019b6:	50                   	push   %eax
f01019b7:	6a 5d                	push   $0x5d
f01019b9:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f01019bf:	50                   	push   %eax
f01019c0:	e8 ec e6 ff ff       	call   f01000b1 <_panic>
		assert(c[i] == 0);
f01019c5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019c8:	8d 83 5e aa f7 ff    	lea    -0x855a2(%ebx),%eax
f01019ce:	50                   	push   %eax
f01019cf:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01019d5:	50                   	push   %eax
f01019d6:	68 df 02 00 00       	push   $0x2df
f01019db:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01019e1:	50                   	push   %eax
f01019e2:	e8 ca e6 ff ff       	call   f01000b1 <_panic>
		--nfree;
f01019e7:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01019ea:	8b 00                	mov    (%eax),%eax
f01019ec:	85 c0                	test   %eax,%eax
f01019ee:	75 f7                	jne    f01019e7 <mem_init+0x634>
	assert(nfree == 0);
f01019f0:	85 f6                	test   %esi,%esi
f01019f2:	0f 85 5b 08 00 00    	jne    f0102253 <mem_init+0xea0>
	cprintf("check_page_alloc() succeeded!\n");
f01019f8:	83 ec 0c             	sub    $0xc,%esp
f01019fb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019fe:	8d 83 a8 a2 f7 ff    	lea    -0x85d58(%ebx),%eax
f0101a04:	50                   	push   %eax
f0101a05:	e8 80 1c 00 00       	call   f010368a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a0a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a11:	e8 3b f6 ff ff       	call   f0101051 <page_alloc>
f0101a16:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a19:	83 c4 10             	add    $0x10,%esp
f0101a1c:	85 c0                	test   %eax,%eax
f0101a1e:	0f 84 51 08 00 00    	je     f0102275 <mem_init+0xec2>
	assert((pp1 = page_alloc(0)));
f0101a24:	83 ec 0c             	sub    $0xc,%esp
f0101a27:	6a 00                	push   $0x0
f0101a29:	e8 23 f6 ff ff       	call   f0101051 <page_alloc>
f0101a2e:	89 c7                	mov    %eax,%edi
f0101a30:	83 c4 10             	add    $0x10,%esp
f0101a33:	85 c0                	test   %eax,%eax
f0101a35:	0f 84 5c 08 00 00    	je     f0102297 <mem_init+0xee4>
	assert((pp2 = page_alloc(0)));
f0101a3b:	83 ec 0c             	sub    $0xc,%esp
f0101a3e:	6a 00                	push   $0x0
f0101a40:	e8 0c f6 ff ff       	call   f0101051 <page_alloc>
f0101a45:	89 c6                	mov    %eax,%esi
f0101a47:	83 c4 10             	add    $0x10,%esp
f0101a4a:	85 c0                	test   %eax,%eax
f0101a4c:	0f 84 67 08 00 00    	je     f01022b9 <mem_init+0xf06>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a52:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101a55:	0f 84 80 08 00 00    	je     f01022db <mem_init+0xf28>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a5b:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101a5e:	0f 84 99 08 00 00    	je     f01022fd <mem_init+0xf4a>
f0101a64:	39 c7                	cmp    %eax,%edi
f0101a66:	0f 84 91 08 00 00    	je     f01022fd <mem_init+0xf4a>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a6c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a6f:	8b 88 1c 23 00 00    	mov    0x231c(%eax),%ecx
f0101a75:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101a78:	c7 80 1c 23 00 00 00 	movl   $0x0,0x231c(%eax)
f0101a7f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a82:	83 ec 0c             	sub    $0xc,%esp
f0101a85:	6a 00                	push   $0x0
f0101a87:	e8 c5 f5 ff ff       	call   f0101051 <page_alloc>
f0101a8c:	83 c4 10             	add    $0x10,%esp
f0101a8f:	85 c0                	test   %eax,%eax
f0101a91:	0f 85 88 08 00 00    	jne    f010231f <mem_init+0xf6c>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a97:	83 ec 04             	sub    $0x4,%esp
f0101a9a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a9d:	50                   	push   %eax
f0101a9e:	6a 00                	push   $0x0
f0101aa0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aa3:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101aa9:	ff 30                	pushl  (%eax)
f0101aab:	e8 d8 f7 ff ff       	call   f0101288 <page_lookup>
f0101ab0:	83 c4 10             	add    $0x10,%esp
f0101ab3:	85 c0                	test   %eax,%eax
f0101ab5:	0f 85 86 08 00 00    	jne    f0102341 <mem_init+0xf8e>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101abb:	6a 02                	push   $0x2
f0101abd:	6a 00                	push   $0x0
f0101abf:	57                   	push   %edi
f0101ac0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac3:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101ac9:	ff 30                	pushl  (%eax)
f0101acb:	e8 65 f8 ff ff       	call   f0101335 <page_insert>
f0101ad0:	83 c4 10             	add    $0x10,%esp
f0101ad3:	85 c0                	test   %eax,%eax
f0101ad5:	0f 89 88 08 00 00    	jns    f0102363 <mem_init+0xfb0>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101adb:	83 ec 0c             	sub    $0xc,%esp
f0101ade:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ae1:	e8 f3 f5 ff ff       	call   f01010d9 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101ae6:	6a 02                	push   $0x2
f0101ae8:	6a 00                	push   $0x0
f0101aea:	57                   	push   %edi
f0101aeb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aee:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101af4:	ff 30                	pushl  (%eax)
f0101af6:	e8 3a f8 ff ff       	call   f0101335 <page_insert>
f0101afb:	83 c4 20             	add    $0x20,%esp
f0101afe:	85 c0                	test   %eax,%eax
f0101b00:	0f 85 7f 08 00 00    	jne    f0102385 <mem_init+0xfd2>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b06:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b09:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101b0f:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101b11:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0101b17:	8b 08                	mov    (%eax),%ecx
f0101b19:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101b1c:	8b 13                	mov    (%ebx),%edx
f0101b1e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b24:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b27:	29 c8                	sub    %ecx,%eax
f0101b29:	c1 f8 03             	sar    $0x3,%eax
f0101b2c:	c1 e0 0c             	shl    $0xc,%eax
f0101b2f:	39 c2                	cmp    %eax,%edx
f0101b31:	0f 85 70 08 00 00    	jne    f01023a7 <mem_init+0xff4>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b37:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b3c:	89 d8                	mov    %ebx,%eax
f0101b3e:	e8 1f f0 ff ff       	call   f0100b62 <check_va2pa>
f0101b43:	89 fa                	mov    %edi,%edx
f0101b45:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b48:	c1 fa 03             	sar    $0x3,%edx
f0101b4b:	c1 e2 0c             	shl    $0xc,%edx
f0101b4e:	39 d0                	cmp    %edx,%eax
f0101b50:	0f 85 73 08 00 00    	jne    f01023c9 <mem_init+0x1016>
	assert(pp1->pp_ref == 1);
f0101b56:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b5b:	0f 85 8a 08 00 00    	jne    f01023eb <mem_init+0x1038>
	assert(pp0->pp_ref == 1);
f0101b61:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b64:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b69:	0f 85 9e 08 00 00    	jne    f010240d <mem_init+0x105a>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b6f:	6a 02                	push   $0x2
f0101b71:	68 00 10 00 00       	push   $0x1000
f0101b76:	56                   	push   %esi
f0101b77:	53                   	push   %ebx
f0101b78:	e8 b8 f7 ff ff       	call   f0101335 <page_insert>
f0101b7d:	83 c4 10             	add    $0x10,%esp
f0101b80:	85 c0                	test   %eax,%eax
f0101b82:	0f 85 a7 08 00 00    	jne    f010242f <mem_init+0x107c>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b88:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b8d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b90:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101b96:	8b 00                	mov    (%eax),%eax
f0101b98:	e8 c5 ef ff ff       	call   f0100b62 <check_va2pa>
f0101b9d:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0101ba3:	89 f1                	mov    %esi,%ecx
f0101ba5:	2b 0a                	sub    (%edx),%ecx
f0101ba7:	89 ca                	mov    %ecx,%edx
f0101ba9:	c1 fa 03             	sar    $0x3,%edx
f0101bac:	c1 e2 0c             	shl    $0xc,%edx
f0101baf:	39 d0                	cmp    %edx,%eax
f0101bb1:	0f 85 9a 08 00 00    	jne    f0102451 <mem_init+0x109e>
	assert(pp2->pp_ref == 1);
f0101bb7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bbc:	0f 85 b1 08 00 00    	jne    f0102473 <mem_init+0x10c0>

	// should be no free memory
	assert(!page_alloc(0));
f0101bc2:	83 ec 0c             	sub    $0xc,%esp
f0101bc5:	6a 00                	push   $0x0
f0101bc7:	e8 85 f4 ff ff       	call   f0101051 <page_alloc>
f0101bcc:	83 c4 10             	add    $0x10,%esp
f0101bcf:	85 c0                	test   %eax,%eax
f0101bd1:	0f 85 be 08 00 00    	jne    f0102495 <mem_init+0x10e2>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bd7:	6a 02                	push   $0x2
f0101bd9:	68 00 10 00 00       	push   $0x1000
f0101bde:	56                   	push   %esi
f0101bdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101be2:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101be8:	ff 30                	pushl  (%eax)
f0101bea:	e8 46 f7 ff ff       	call   f0101335 <page_insert>
f0101bef:	83 c4 10             	add    $0x10,%esp
f0101bf2:	85 c0                	test   %eax,%eax
f0101bf4:	0f 85 bd 08 00 00    	jne    f01024b7 <mem_init+0x1104>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bfa:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c02:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101c08:	8b 00                	mov    (%eax),%eax
f0101c0a:	e8 53 ef ff ff       	call   f0100b62 <check_va2pa>
f0101c0f:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0101c15:	89 f1                	mov    %esi,%ecx
f0101c17:	2b 0a                	sub    (%edx),%ecx
f0101c19:	89 ca                	mov    %ecx,%edx
f0101c1b:	c1 fa 03             	sar    $0x3,%edx
f0101c1e:	c1 e2 0c             	shl    $0xc,%edx
f0101c21:	39 d0                	cmp    %edx,%eax
f0101c23:	0f 85 b0 08 00 00    	jne    f01024d9 <mem_init+0x1126>
	assert(pp2->pp_ref == 1);
f0101c29:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c2e:	0f 85 c7 08 00 00    	jne    f01024fb <mem_init+0x1148>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c34:	83 ec 0c             	sub    $0xc,%esp
f0101c37:	6a 00                	push   $0x0
f0101c39:	e8 13 f4 ff ff       	call   f0101051 <page_alloc>
f0101c3e:	83 c4 10             	add    $0x10,%esp
f0101c41:	85 c0                	test   %eax,%eax
f0101c43:	0f 85 d4 08 00 00    	jne    f010251d <mem_init+0x116a>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c49:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c4c:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101c52:	8b 10                	mov    (%eax),%edx
f0101c54:	8b 02                	mov    (%edx),%eax
f0101c56:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101c5b:	89 c3                	mov    %eax,%ebx
f0101c5d:	c1 eb 0c             	shr    $0xc,%ebx
f0101c60:	c7 c1 08 e0 18 f0    	mov    $0xf018e008,%ecx
f0101c66:	3b 19                	cmp    (%ecx),%ebx
f0101c68:	0f 83 d1 08 00 00    	jae    f010253f <mem_init+0x118c>
	return (void *)(pa + KERNBASE);
f0101c6e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c73:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c76:	83 ec 04             	sub    $0x4,%esp
f0101c79:	6a 00                	push   $0x0
f0101c7b:	68 00 10 00 00       	push   $0x1000
f0101c80:	52                   	push   %edx
f0101c81:	e8 cb f4 ff ff       	call   f0101151 <pgdir_walk>
f0101c86:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c89:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c8c:	83 c4 10             	add    $0x10,%esp
f0101c8f:	39 d0                	cmp    %edx,%eax
f0101c91:	0f 85 c4 08 00 00    	jne    f010255b <mem_init+0x11a8>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c97:	6a 06                	push   $0x6
f0101c99:	68 00 10 00 00       	push   $0x1000
f0101c9e:	56                   	push   %esi
f0101c9f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ca2:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101ca8:	ff 30                	pushl  (%eax)
f0101caa:	e8 86 f6 ff ff       	call   f0101335 <page_insert>
f0101caf:	83 c4 10             	add    $0x10,%esp
f0101cb2:	85 c0                	test   %eax,%eax
f0101cb4:	0f 85 c3 08 00 00    	jne    f010257d <mem_init+0x11ca>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cbd:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101cc3:	8b 18                	mov    (%eax),%ebx
f0101cc5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cca:	89 d8                	mov    %ebx,%eax
f0101ccc:	e8 91 ee ff ff       	call   f0100b62 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101cd1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101cd4:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0101cda:	89 f1                	mov    %esi,%ecx
f0101cdc:	2b 0a                	sub    (%edx),%ecx
f0101cde:	89 ca                	mov    %ecx,%edx
f0101ce0:	c1 fa 03             	sar    $0x3,%edx
f0101ce3:	c1 e2 0c             	shl    $0xc,%edx
f0101ce6:	39 d0                	cmp    %edx,%eax
f0101ce8:	0f 85 b1 08 00 00    	jne    f010259f <mem_init+0x11ec>
	assert(pp2->pp_ref == 1);
f0101cee:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cf3:	0f 85 c8 08 00 00    	jne    f01025c1 <mem_init+0x120e>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101cf9:	83 ec 04             	sub    $0x4,%esp
f0101cfc:	6a 00                	push   $0x0
f0101cfe:	68 00 10 00 00       	push   $0x1000
f0101d03:	53                   	push   %ebx
f0101d04:	e8 48 f4 ff ff       	call   f0101151 <pgdir_walk>
f0101d09:	83 c4 10             	add    $0x10,%esp
f0101d0c:	f6 00 04             	testb  $0x4,(%eax)
f0101d0f:	0f 84 ce 08 00 00    	je     f01025e3 <mem_init+0x1230>
	assert(kern_pgdir[0] & PTE_U);
f0101d15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d18:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101d1e:	8b 00                	mov    (%eax),%eax
f0101d20:	f6 00 04             	testb  $0x4,(%eax)
f0101d23:	0f 84 dc 08 00 00    	je     f0102605 <mem_init+0x1252>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d29:	6a 02                	push   $0x2
f0101d2b:	68 00 10 00 00       	push   $0x1000
f0101d30:	56                   	push   %esi
f0101d31:	50                   	push   %eax
f0101d32:	e8 fe f5 ff ff       	call   f0101335 <page_insert>
f0101d37:	83 c4 10             	add    $0x10,%esp
f0101d3a:	85 c0                	test   %eax,%eax
f0101d3c:	0f 85 e5 08 00 00    	jne    f0102627 <mem_init+0x1274>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d42:	83 ec 04             	sub    $0x4,%esp
f0101d45:	6a 00                	push   $0x0
f0101d47:	68 00 10 00 00       	push   $0x1000
f0101d4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d4f:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101d55:	ff 30                	pushl  (%eax)
f0101d57:	e8 f5 f3 ff ff       	call   f0101151 <pgdir_walk>
f0101d5c:	83 c4 10             	add    $0x10,%esp
f0101d5f:	f6 00 02             	testb  $0x2,(%eax)
f0101d62:	0f 84 e1 08 00 00    	je     f0102649 <mem_init+0x1296>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d68:	83 ec 04             	sub    $0x4,%esp
f0101d6b:	6a 00                	push   $0x0
f0101d6d:	68 00 10 00 00       	push   $0x1000
f0101d72:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d75:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101d7b:	ff 30                	pushl  (%eax)
f0101d7d:	e8 cf f3 ff ff       	call   f0101151 <pgdir_walk>
f0101d82:	83 c4 10             	add    $0x10,%esp
f0101d85:	f6 00 04             	testb  $0x4,(%eax)
f0101d88:	0f 85 dd 08 00 00    	jne    f010266b <mem_init+0x12b8>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d8e:	6a 02                	push   $0x2
f0101d90:	68 00 00 40 00       	push   $0x400000
f0101d95:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d98:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d9b:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101da1:	ff 30                	pushl  (%eax)
f0101da3:	e8 8d f5 ff ff       	call   f0101335 <page_insert>
f0101da8:	83 c4 10             	add    $0x10,%esp
f0101dab:	85 c0                	test   %eax,%eax
f0101dad:	0f 89 da 08 00 00    	jns    f010268d <mem_init+0x12da>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101db3:	6a 02                	push   $0x2
f0101db5:	68 00 10 00 00       	push   $0x1000
f0101dba:	57                   	push   %edi
f0101dbb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dbe:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101dc4:	ff 30                	pushl  (%eax)
f0101dc6:	e8 6a f5 ff ff       	call   f0101335 <page_insert>
f0101dcb:	83 c4 10             	add    $0x10,%esp
f0101dce:	85 c0                	test   %eax,%eax
f0101dd0:	0f 85 d9 08 00 00    	jne    f01026af <mem_init+0x12fc>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dd6:	83 ec 04             	sub    $0x4,%esp
f0101dd9:	6a 00                	push   $0x0
f0101ddb:	68 00 10 00 00       	push   $0x1000
f0101de0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de3:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101de9:	ff 30                	pushl  (%eax)
f0101deb:	e8 61 f3 ff ff       	call   f0101151 <pgdir_walk>
f0101df0:	83 c4 10             	add    $0x10,%esp
f0101df3:	f6 00 04             	testb  $0x4,(%eax)
f0101df6:	0f 85 d5 08 00 00    	jne    f01026d1 <mem_init+0x131e>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101dfc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dff:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101e05:	8b 18                	mov    (%eax),%ebx
f0101e07:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e0c:	89 d8                	mov    %ebx,%eax
f0101e0e:	e8 4f ed ff ff       	call   f0100b62 <check_va2pa>
f0101e13:	89 c2                	mov    %eax,%edx
f0101e15:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e18:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e1b:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0101e21:	89 f9                	mov    %edi,%ecx
f0101e23:	2b 08                	sub    (%eax),%ecx
f0101e25:	89 c8                	mov    %ecx,%eax
f0101e27:	c1 f8 03             	sar    $0x3,%eax
f0101e2a:	c1 e0 0c             	shl    $0xc,%eax
f0101e2d:	39 c2                	cmp    %eax,%edx
f0101e2f:	0f 85 be 08 00 00    	jne    f01026f3 <mem_init+0x1340>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e35:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e3a:	89 d8                	mov    %ebx,%eax
f0101e3c:	e8 21 ed ff ff       	call   f0100b62 <check_va2pa>
f0101e41:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e44:	0f 85 cb 08 00 00    	jne    f0102715 <mem_init+0x1362>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e4a:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101e4f:	0f 85 e2 08 00 00    	jne    f0102737 <mem_init+0x1384>
	assert(pp2->pp_ref == 0);
f0101e55:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e5a:	0f 85 f9 08 00 00    	jne    f0102759 <mem_init+0x13a6>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e60:	83 ec 0c             	sub    $0xc,%esp
f0101e63:	6a 00                	push   $0x0
f0101e65:	e8 e7 f1 ff ff       	call   f0101051 <page_alloc>
f0101e6a:	83 c4 10             	add    $0x10,%esp
f0101e6d:	39 c6                	cmp    %eax,%esi
f0101e6f:	0f 85 06 09 00 00    	jne    f010277b <mem_init+0x13c8>
f0101e75:	85 c0                	test   %eax,%eax
f0101e77:	0f 84 fe 08 00 00    	je     f010277b <mem_init+0x13c8>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e7d:	83 ec 08             	sub    $0x8,%esp
f0101e80:	6a 00                	push   $0x0
f0101e82:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e85:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f0101e8b:	ff 33                	pushl  (%ebx)
f0101e8d:	e8 66 f4 ff ff       	call   f01012f8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e92:	8b 1b                	mov    (%ebx),%ebx
f0101e94:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e99:	89 d8                	mov    %ebx,%eax
f0101e9b:	e8 c2 ec ff ff       	call   f0100b62 <check_va2pa>
f0101ea0:	83 c4 10             	add    $0x10,%esp
f0101ea3:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ea6:	0f 85 f1 08 00 00    	jne    f010279d <mem_init+0x13ea>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101eac:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eb1:	89 d8                	mov    %ebx,%eax
f0101eb3:	e8 aa ec ff ff       	call   f0100b62 <check_va2pa>
f0101eb8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ebb:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0101ec1:	89 f9                	mov    %edi,%ecx
f0101ec3:	2b 0a                	sub    (%edx),%ecx
f0101ec5:	89 ca                	mov    %ecx,%edx
f0101ec7:	c1 fa 03             	sar    $0x3,%edx
f0101eca:	c1 e2 0c             	shl    $0xc,%edx
f0101ecd:	39 d0                	cmp    %edx,%eax
f0101ecf:	0f 85 ea 08 00 00    	jne    f01027bf <mem_init+0x140c>
	assert(pp1->pp_ref == 1);
f0101ed5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101eda:	0f 85 01 09 00 00    	jne    f01027e1 <mem_init+0x142e>
	assert(pp2->pp_ref == 0);
f0101ee0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ee5:	0f 85 18 09 00 00    	jne    f0102803 <mem_init+0x1450>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101eeb:	6a 00                	push   $0x0
f0101eed:	68 00 10 00 00       	push   $0x1000
f0101ef2:	57                   	push   %edi
f0101ef3:	53                   	push   %ebx
f0101ef4:	e8 3c f4 ff ff       	call   f0101335 <page_insert>
f0101ef9:	83 c4 10             	add    $0x10,%esp
f0101efc:	85 c0                	test   %eax,%eax
f0101efe:	0f 85 21 09 00 00    	jne    f0102825 <mem_init+0x1472>
	assert(pp1->pp_ref);
f0101f04:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f09:	0f 84 38 09 00 00    	je     f0102847 <mem_init+0x1494>
	assert(pp1->pp_link == NULL);
f0101f0f:	83 3f 00             	cmpl   $0x0,(%edi)
f0101f12:	0f 85 51 09 00 00    	jne    f0102869 <mem_init+0x14b6>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f18:	83 ec 08             	sub    $0x8,%esp
f0101f1b:	68 00 10 00 00       	push   $0x1000
f0101f20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f23:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f0101f29:	ff 33                	pushl  (%ebx)
f0101f2b:	e8 c8 f3 ff ff       	call   f01012f8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f30:	8b 1b                	mov    (%ebx),%ebx
f0101f32:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f37:	89 d8                	mov    %ebx,%eax
f0101f39:	e8 24 ec ff ff       	call   f0100b62 <check_va2pa>
f0101f3e:	83 c4 10             	add    $0x10,%esp
f0101f41:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f44:	0f 85 41 09 00 00    	jne    f010288b <mem_init+0x14d8>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f4a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f4f:	89 d8                	mov    %ebx,%eax
f0101f51:	e8 0c ec ff ff       	call   f0100b62 <check_va2pa>
f0101f56:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f59:	0f 85 4e 09 00 00    	jne    f01028ad <mem_init+0x14fa>
	assert(pp1->pp_ref == 0);
f0101f5f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f64:	0f 85 65 09 00 00    	jne    f01028cf <mem_init+0x151c>
	assert(pp2->pp_ref == 0);
f0101f6a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f6f:	0f 85 7c 09 00 00    	jne    f01028f1 <mem_init+0x153e>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f75:	83 ec 0c             	sub    $0xc,%esp
f0101f78:	6a 00                	push   $0x0
f0101f7a:	e8 d2 f0 ff ff       	call   f0101051 <page_alloc>
f0101f7f:	83 c4 10             	add    $0x10,%esp
f0101f82:	39 c7                	cmp    %eax,%edi
f0101f84:	0f 85 89 09 00 00    	jne    f0102913 <mem_init+0x1560>
f0101f8a:	85 c0                	test   %eax,%eax
f0101f8c:	0f 84 81 09 00 00    	je     f0102913 <mem_init+0x1560>

	// should be no free memory
	assert(!page_alloc(0));
f0101f92:	83 ec 0c             	sub    $0xc,%esp
f0101f95:	6a 00                	push   $0x0
f0101f97:	e8 b5 f0 ff ff       	call   f0101051 <page_alloc>
f0101f9c:	83 c4 10             	add    $0x10,%esp
f0101f9f:	85 c0                	test   %eax,%eax
f0101fa1:	0f 85 8e 09 00 00    	jne    f0102935 <mem_init+0x1582>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fa7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101faa:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0101fb0:	8b 08                	mov    (%eax),%ecx
f0101fb2:	8b 11                	mov    (%ecx),%edx
f0101fb4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fba:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0101fc0:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101fc3:	2b 18                	sub    (%eax),%ebx
f0101fc5:	89 d8                	mov    %ebx,%eax
f0101fc7:	c1 f8 03             	sar    $0x3,%eax
f0101fca:	c1 e0 0c             	shl    $0xc,%eax
f0101fcd:	39 c2                	cmp    %eax,%edx
f0101fcf:	0f 85 82 09 00 00    	jne    f0102957 <mem_init+0x15a4>
	kern_pgdir[0] = 0;
f0101fd5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fdb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101fde:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fe3:	0f 85 90 09 00 00    	jne    f0102979 <mem_init+0x15c6>
	pp0->pp_ref = 0;
f0101fe9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101fec:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ff2:	83 ec 0c             	sub    $0xc,%esp
f0101ff5:	50                   	push   %eax
f0101ff6:	e8 de f0 ff ff       	call   f01010d9 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ffb:	83 c4 0c             	add    $0xc,%esp
f0101ffe:	6a 01                	push   $0x1
f0102000:	68 00 10 40 00       	push   $0x401000
f0102005:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102008:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f010200e:	ff 33                	pushl  (%ebx)
f0102010:	e8 3c f1 ff ff       	call   f0101151 <pgdir_walk>
f0102015:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102018:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010201b:	8b 1b                	mov    (%ebx),%ebx
f010201d:	8b 53 04             	mov    0x4(%ebx),%edx
f0102020:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0102026:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102029:	c7 c1 08 e0 18 f0    	mov    $0xf018e008,%ecx
f010202f:	8b 09                	mov    (%ecx),%ecx
f0102031:	89 d0                	mov    %edx,%eax
f0102033:	c1 e8 0c             	shr    $0xc,%eax
f0102036:	83 c4 10             	add    $0x10,%esp
f0102039:	39 c8                	cmp    %ecx,%eax
f010203b:	0f 83 5a 09 00 00    	jae    f010299b <mem_init+0x15e8>
	assert(ptep == ptep1 + PTX(va));
f0102041:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102047:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f010204a:	0f 85 67 09 00 00    	jne    f01029b7 <mem_init+0x1604>
	kern_pgdir[PDX(va)] = 0;
f0102050:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102057:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010205a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102060:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102063:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102069:	2b 18                	sub    (%eax),%ebx
f010206b:	89 d8                	mov    %ebx,%eax
f010206d:	c1 f8 03             	sar    $0x3,%eax
f0102070:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102073:	89 c2                	mov    %eax,%edx
f0102075:	c1 ea 0c             	shr    $0xc,%edx
f0102078:	39 d1                	cmp    %edx,%ecx
f010207a:	0f 86 59 09 00 00    	jbe    f01029d9 <mem_init+0x1626>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102080:	83 ec 04             	sub    $0x4,%esp
f0102083:	68 00 10 00 00       	push   $0x1000
f0102088:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010208d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102092:	50                   	push   %eax
f0102093:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102096:	e8 9f 26 00 00       	call   f010473a <memset>
	page_free(pp0);
f010209b:	83 c4 04             	add    $0x4,%esp
f010209e:	ff 75 d0             	pushl  -0x30(%ebp)
f01020a1:	e8 33 f0 ff ff       	call   f01010d9 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020a6:	83 c4 0c             	add    $0xc,%esp
f01020a9:	6a 01                	push   $0x1
f01020ab:	6a 00                	push   $0x0
f01020ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020b0:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f01020b6:	ff 30                	pushl  (%eax)
f01020b8:	e8 94 f0 ff ff       	call   f0101151 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01020bd:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f01020c3:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01020c6:	2b 10                	sub    (%eax),%edx
f01020c8:	c1 fa 03             	sar    $0x3,%edx
f01020cb:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01020ce:	89 d1                	mov    %edx,%ecx
f01020d0:	c1 e9 0c             	shr    $0xc,%ecx
f01020d3:	83 c4 10             	add    $0x10,%esp
f01020d6:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f01020dc:	3b 08                	cmp    (%eax),%ecx
f01020de:	0f 83 0e 09 00 00    	jae    f01029f2 <mem_init+0x163f>
	return (void *)(pa + KERNBASE);
f01020e4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020ed:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020f3:	f6 00 01             	testb  $0x1,(%eax)
f01020f6:	0f 85 0f 09 00 00    	jne    f0102a0b <mem_init+0x1658>
f01020fc:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01020ff:	39 d0                	cmp    %edx,%eax
f0102101:	75 f0                	jne    f01020f3 <mem_init+0xd40>
	kern_pgdir[0] = 0;
f0102103:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102106:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f010210c:	8b 00                	mov    (%eax),%eax
f010210e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102114:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102117:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010211d:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102120:	89 93 1c 23 00 00    	mov    %edx,0x231c(%ebx)

	// free the pages we took
	page_free(pp0);
f0102126:	83 ec 0c             	sub    $0xc,%esp
f0102129:	50                   	push   %eax
f010212a:	e8 aa ef ff ff       	call   f01010d9 <page_free>
	page_free(pp1);
f010212f:	89 3c 24             	mov    %edi,(%esp)
f0102132:	e8 a2 ef ff ff       	call   f01010d9 <page_free>
	page_free(pp2);
f0102137:	89 34 24             	mov    %esi,(%esp)
f010213a:	e8 9a ef ff ff       	call   f01010d9 <page_free>

	cprintf("check_page() succeeded!\n");
f010213f:	8d 83 3f ab f7 ff    	lea    -0x854c1(%ebx),%eax
f0102145:	89 04 24             	mov    %eax,(%esp)
f0102148:	e8 3d 15 00 00       	call   f010368a <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f010214d:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102153:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102155:	83 c4 10             	add    $0x10,%esp
f0102158:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010215d:	0f 86 ca 08 00 00    	jbe    f0102a2d <mem_init+0x167a>
f0102163:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102166:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f010216c:	8b 0a                	mov    (%edx),%ecx
f010216e:	c1 e1 03             	shl    $0x3,%ecx
f0102171:	83 ec 08             	sub    $0x8,%esp
f0102174:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102176:	05 00 00 00 10       	add    $0x10000000,%eax
f010217b:	50                   	push   %eax
f010217c:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102181:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102187:	8b 00                	mov    (%eax),%eax
f0102189:	e8 6e f0 ff ff       	call   f01011fc <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010218e:	c7 c0 00 10 11 f0    	mov    $0xf0111000,%eax
f0102194:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102197:	83 c4 10             	add    $0x10,%esp
f010219a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010219f:	0f 86 a4 08 00 00    	jbe    f0102a49 <mem_init+0x1696>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01021a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01021a8:	c7 c3 0c e0 18 f0    	mov    $0xf018e00c,%ebx
f01021ae:	83 ec 08             	sub    $0x8,%esp
f01021b1:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01021b3:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01021b6:	05 00 00 00 10       	add    $0x10000000,%eax
f01021bb:	50                   	push   %eax
f01021bc:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021c1:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021c6:	8b 03                	mov    (%ebx),%eax
f01021c8:	e8 2f f0 ff ff       	call   f01011fc <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0x100000000 - KERNBASE, 0, PTE_W);
f01021cd:	83 c4 08             	add    $0x8,%esp
f01021d0:	6a 02                	push   $0x2
f01021d2:	6a 00                	push   $0x0
f01021d4:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021d9:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021de:	8b 03                	mov    (%ebx),%eax
f01021e0:	e8 17 f0 ff ff       	call   f01011fc <boot_map_region>
	pgdir = kern_pgdir;
f01021e5:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021e7:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f01021ed:	8b 00                	mov    (%eax),%eax
f01021ef:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01021f2:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021f9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102201:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102207:	8b 00                	mov    (%eax),%eax
f0102209:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f010220c:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f010220f:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi
f0102215:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0102218:	bb 00 00 00 00       	mov    $0x0,%ebx
f010221d:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102220:	0f 86 84 08 00 00    	jbe    f0102aaa <mem_init+0x16f7>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102226:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010222c:	89 f0                	mov    %esi,%eax
f010222e:	e8 2f e9 ff ff       	call   f0100b62 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102233:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f010223a:	0f 86 2a 08 00 00    	jbe    f0102a6a <mem_init+0x16b7>
f0102240:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102243:	39 d0                	cmp    %edx,%eax
f0102245:	0f 85 3d 08 00 00    	jne    f0102a88 <mem_init+0x16d5>
	for (i = 0; i < n; i += PGSIZE)
f010224b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102251:	eb ca                	jmp    f010221d <mem_init+0xe6a>
	assert(nfree == 0);
f0102253:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102256:	8d 83 68 aa f7 ff    	lea    -0x85598(%ebx),%eax
f010225c:	50                   	push   %eax
f010225d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102263:	50                   	push   %eax
f0102264:	68 ec 02 00 00       	push   $0x2ec
f0102269:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010226f:	50                   	push   %eax
f0102270:	e8 3c de ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0102275:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102278:	8d 83 76 a9 f7 ff    	lea    -0x8568a(%ebx),%eax
f010227e:	50                   	push   %eax
f010227f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102285:	50                   	push   %eax
f0102286:	68 4a 03 00 00       	push   $0x34a
f010228b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102291:	50                   	push   %eax
f0102292:	e8 1a de ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0102297:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010229a:	8d 83 8c a9 f7 ff    	lea    -0x85674(%ebx),%eax
f01022a0:	50                   	push   %eax
f01022a1:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01022a7:	50                   	push   %eax
f01022a8:	68 4b 03 00 00       	push   $0x34b
f01022ad:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01022b3:	50                   	push   %eax
f01022b4:	e8 f8 dd ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01022b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022bc:	8d 83 a2 a9 f7 ff    	lea    -0x8565e(%ebx),%eax
f01022c2:	50                   	push   %eax
f01022c3:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01022c9:	50                   	push   %eax
f01022ca:	68 4c 03 00 00       	push   $0x34c
f01022cf:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01022d5:	50                   	push   %eax
f01022d6:	e8 d6 dd ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01022db:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022de:	8d 83 b8 a9 f7 ff    	lea    -0x85648(%ebx),%eax
f01022e4:	50                   	push   %eax
f01022e5:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01022eb:	50                   	push   %eax
f01022ec:	68 4f 03 00 00       	push   $0x34f
f01022f1:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01022f7:	50                   	push   %eax
f01022f8:	e8 b4 dd ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022fd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102300:	8d 83 88 a2 f7 ff    	lea    -0x85d78(%ebx),%eax
f0102306:	50                   	push   %eax
f0102307:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010230d:	50                   	push   %eax
f010230e:	68 50 03 00 00       	push   $0x350
f0102313:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102319:	50                   	push   %eax
f010231a:	e8 92 dd ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010231f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102322:	8d 83 21 aa f7 ff    	lea    -0x855df(%ebx),%eax
f0102328:	50                   	push   %eax
f0102329:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010232f:	50                   	push   %eax
f0102330:	68 57 03 00 00       	push   $0x357
f0102335:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010233b:	50                   	push   %eax
f010233c:	e8 70 dd ff ff       	call   f01000b1 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102341:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102344:	8d 83 c8 a2 f7 ff    	lea    -0x85d38(%ebx),%eax
f010234a:	50                   	push   %eax
f010234b:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102351:	50                   	push   %eax
f0102352:	68 5a 03 00 00       	push   $0x35a
f0102357:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010235d:	50                   	push   %eax
f010235e:	e8 4e dd ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102363:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102366:	8d 83 00 a3 f7 ff    	lea    -0x85d00(%ebx),%eax
f010236c:	50                   	push   %eax
f010236d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102373:	50                   	push   %eax
f0102374:	68 5d 03 00 00       	push   $0x35d
f0102379:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010237f:	50                   	push   %eax
f0102380:	e8 2c dd ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102385:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102388:	8d 83 30 a3 f7 ff    	lea    -0x85cd0(%ebx),%eax
f010238e:	50                   	push   %eax
f010238f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102395:	50                   	push   %eax
f0102396:	68 61 03 00 00       	push   $0x361
f010239b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01023a1:	50                   	push   %eax
f01023a2:	e8 0a dd ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023a7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023aa:	8d 83 60 a3 f7 ff    	lea    -0x85ca0(%ebx),%eax
f01023b0:	50                   	push   %eax
f01023b1:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01023b7:	50                   	push   %eax
f01023b8:	68 62 03 00 00       	push   $0x362
f01023bd:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01023c3:	50                   	push   %eax
f01023c4:	e8 e8 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01023c9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023cc:	8d 83 88 a3 f7 ff    	lea    -0x85c78(%ebx),%eax
f01023d2:	50                   	push   %eax
f01023d3:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01023d9:	50                   	push   %eax
f01023da:	68 63 03 00 00       	push   $0x363
f01023df:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01023e5:	50                   	push   %eax
f01023e6:	e8 c6 dc ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01023eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023ee:	8d 83 73 aa f7 ff    	lea    -0x8558d(%ebx),%eax
f01023f4:	50                   	push   %eax
f01023f5:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01023fb:	50                   	push   %eax
f01023fc:	68 64 03 00 00       	push   $0x364
f0102401:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102407:	50                   	push   %eax
f0102408:	e8 a4 dc ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f010240d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102410:	8d 83 84 aa f7 ff    	lea    -0x8557c(%ebx),%eax
f0102416:	50                   	push   %eax
f0102417:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010241d:	50                   	push   %eax
f010241e:	68 65 03 00 00       	push   $0x365
f0102423:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102429:	50                   	push   %eax
f010242a:	e8 82 dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010242f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102432:	8d 83 b8 a3 f7 ff    	lea    -0x85c48(%ebx),%eax
f0102438:	50                   	push   %eax
f0102439:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010243f:	50                   	push   %eax
f0102440:	68 68 03 00 00       	push   $0x368
f0102445:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010244b:	50                   	push   %eax
f010244c:	e8 60 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102451:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102454:	8d 83 f4 a3 f7 ff    	lea    -0x85c0c(%ebx),%eax
f010245a:	50                   	push   %eax
f010245b:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102461:	50                   	push   %eax
f0102462:	68 69 03 00 00       	push   $0x369
f0102467:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010246d:	50                   	push   %eax
f010246e:	e8 3e dc ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102473:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102476:	8d 83 95 aa f7 ff    	lea    -0x8556b(%ebx),%eax
f010247c:	50                   	push   %eax
f010247d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102483:	50                   	push   %eax
f0102484:	68 6a 03 00 00       	push   $0x36a
f0102489:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010248f:	50                   	push   %eax
f0102490:	e8 1c dc ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102495:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102498:	8d 83 21 aa f7 ff    	lea    -0x855df(%ebx),%eax
f010249e:	50                   	push   %eax
f010249f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01024a5:	50                   	push   %eax
f01024a6:	68 6d 03 00 00       	push   $0x36d
f01024ab:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01024b1:	50                   	push   %eax
f01024b2:	e8 fa db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024b7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024ba:	8d 83 b8 a3 f7 ff    	lea    -0x85c48(%ebx),%eax
f01024c0:	50                   	push   %eax
f01024c1:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01024c7:	50                   	push   %eax
f01024c8:	68 70 03 00 00       	push   $0x370
f01024cd:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01024d3:	50                   	push   %eax
f01024d4:	e8 d8 db ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024d9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024dc:	8d 83 f4 a3 f7 ff    	lea    -0x85c0c(%ebx),%eax
f01024e2:	50                   	push   %eax
f01024e3:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01024e9:	50                   	push   %eax
f01024ea:	68 71 03 00 00       	push   $0x371
f01024ef:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01024f5:	50                   	push   %eax
f01024f6:	e8 b6 db ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01024fb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024fe:	8d 83 95 aa f7 ff    	lea    -0x8556b(%ebx),%eax
f0102504:	50                   	push   %eax
f0102505:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010250b:	50                   	push   %eax
f010250c:	68 72 03 00 00       	push   $0x372
f0102511:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102517:	50                   	push   %eax
f0102518:	e8 94 db ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010251d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102520:	8d 83 21 aa f7 ff    	lea    -0x855df(%ebx),%eax
f0102526:	50                   	push   %eax
f0102527:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010252d:	50                   	push   %eax
f010252e:	68 76 03 00 00       	push   $0x376
f0102533:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102539:	50                   	push   %eax
f010253a:	e8 72 db ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010253f:	50                   	push   %eax
f0102540:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102543:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f0102549:	50                   	push   %eax
f010254a:	68 79 03 00 00       	push   $0x379
f010254f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102555:	50                   	push   %eax
f0102556:	e8 56 db ff ff       	call   f01000b1 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010255b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010255e:	8d 83 24 a4 f7 ff    	lea    -0x85bdc(%ebx),%eax
f0102564:	50                   	push   %eax
f0102565:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010256b:	50                   	push   %eax
f010256c:	68 7a 03 00 00       	push   $0x37a
f0102571:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102577:	50                   	push   %eax
f0102578:	e8 34 db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010257d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102580:	8d 83 64 a4 f7 ff    	lea    -0x85b9c(%ebx),%eax
f0102586:	50                   	push   %eax
f0102587:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010258d:	50                   	push   %eax
f010258e:	68 7d 03 00 00       	push   $0x37d
f0102593:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102599:	50                   	push   %eax
f010259a:	e8 12 db ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010259f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025a2:	8d 83 f4 a3 f7 ff    	lea    -0x85c0c(%ebx),%eax
f01025a8:	50                   	push   %eax
f01025a9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01025af:	50                   	push   %eax
f01025b0:	68 7e 03 00 00       	push   $0x37e
f01025b5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01025bb:	50                   	push   %eax
f01025bc:	e8 f0 da ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01025c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025c4:	8d 83 95 aa f7 ff    	lea    -0x8556b(%ebx),%eax
f01025ca:	50                   	push   %eax
f01025cb:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01025d1:	50                   	push   %eax
f01025d2:	68 7f 03 00 00       	push   $0x37f
f01025d7:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01025dd:	50                   	push   %eax
f01025de:	e8 ce da ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01025e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025e6:	8d 83 a4 a4 f7 ff    	lea    -0x85b5c(%ebx),%eax
f01025ec:	50                   	push   %eax
f01025ed:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01025f3:	50                   	push   %eax
f01025f4:	68 80 03 00 00       	push   $0x380
f01025f9:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01025ff:	50                   	push   %eax
f0102600:	e8 ac da ff ff       	call   f01000b1 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102605:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102608:	8d 83 a6 aa f7 ff    	lea    -0x8555a(%ebx),%eax
f010260e:	50                   	push   %eax
f010260f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102615:	50                   	push   %eax
f0102616:	68 81 03 00 00       	push   $0x381
f010261b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102621:	50                   	push   %eax
f0102622:	e8 8a da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102627:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010262a:	8d 83 b8 a3 f7 ff    	lea    -0x85c48(%ebx),%eax
f0102630:	50                   	push   %eax
f0102631:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102637:	50                   	push   %eax
f0102638:	68 84 03 00 00       	push   $0x384
f010263d:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102643:	50                   	push   %eax
f0102644:	e8 68 da ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102649:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010264c:	8d 83 d8 a4 f7 ff    	lea    -0x85b28(%ebx),%eax
f0102652:	50                   	push   %eax
f0102653:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102659:	50                   	push   %eax
f010265a:	68 85 03 00 00       	push   $0x385
f010265f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102665:	50                   	push   %eax
f0102666:	e8 46 da ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010266b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010266e:	8d 83 0c a5 f7 ff    	lea    -0x85af4(%ebx),%eax
f0102674:	50                   	push   %eax
f0102675:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010267b:	50                   	push   %eax
f010267c:	68 86 03 00 00       	push   $0x386
f0102681:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102687:	50                   	push   %eax
f0102688:	e8 24 da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010268d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102690:	8d 83 44 a5 f7 ff    	lea    -0x85abc(%ebx),%eax
f0102696:	50                   	push   %eax
f0102697:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010269d:	50                   	push   %eax
f010269e:	68 89 03 00 00       	push   $0x389
f01026a3:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01026a9:	50                   	push   %eax
f01026aa:	e8 02 da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01026af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026b2:	8d 83 7c a5 f7 ff    	lea    -0x85a84(%ebx),%eax
f01026b8:	50                   	push   %eax
f01026b9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01026bf:	50                   	push   %eax
f01026c0:	68 8c 03 00 00       	push   $0x38c
f01026c5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01026cb:	50                   	push   %eax
f01026cc:	e8 e0 d9 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026d4:	8d 83 0c a5 f7 ff    	lea    -0x85af4(%ebx),%eax
f01026da:	50                   	push   %eax
f01026db:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01026e1:	50                   	push   %eax
f01026e2:	68 8d 03 00 00       	push   $0x38d
f01026e7:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01026ed:	50                   	push   %eax
f01026ee:	e8 be d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01026f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026f6:	8d 83 b8 a5 f7 ff    	lea    -0x85a48(%ebx),%eax
f01026fc:	50                   	push   %eax
f01026fd:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102703:	50                   	push   %eax
f0102704:	68 90 03 00 00       	push   $0x390
f0102709:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010270f:	50                   	push   %eax
f0102710:	e8 9c d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102715:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102718:	8d 83 e4 a5 f7 ff    	lea    -0x85a1c(%ebx),%eax
f010271e:	50                   	push   %eax
f010271f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102725:	50                   	push   %eax
f0102726:	68 91 03 00 00       	push   $0x391
f010272b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102731:	50                   	push   %eax
f0102732:	e8 7a d9 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 2);
f0102737:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010273a:	8d 83 bc aa f7 ff    	lea    -0x85544(%ebx),%eax
f0102740:	50                   	push   %eax
f0102741:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102747:	50                   	push   %eax
f0102748:	68 93 03 00 00       	push   $0x393
f010274d:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102753:	50                   	push   %eax
f0102754:	e8 58 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102759:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010275c:	8d 83 cd aa f7 ff    	lea    -0x85533(%ebx),%eax
f0102762:	50                   	push   %eax
f0102763:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102769:	50                   	push   %eax
f010276a:	68 94 03 00 00       	push   $0x394
f010276f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102775:	50                   	push   %eax
f0102776:	e8 36 d9 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f010277b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010277e:	8d 83 14 a6 f7 ff    	lea    -0x859ec(%ebx),%eax
f0102784:	50                   	push   %eax
f0102785:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010278b:	50                   	push   %eax
f010278c:	68 97 03 00 00       	push   $0x397
f0102791:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102797:	50                   	push   %eax
f0102798:	e8 14 d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010279d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027a0:	8d 83 38 a6 f7 ff    	lea    -0x859c8(%ebx),%eax
f01027a6:	50                   	push   %eax
f01027a7:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01027ad:	50                   	push   %eax
f01027ae:	68 9b 03 00 00       	push   $0x39b
f01027b3:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01027b9:	50                   	push   %eax
f01027ba:	e8 f2 d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027c2:	8d 83 e4 a5 f7 ff    	lea    -0x85a1c(%ebx),%eax
f01027c8:	50                   	push   %eax
f01027c9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01027cf:	50                   	push   %eax
f01027d0:	68 9c 03 00 00       	push   $0x39c
f01027d5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01027db:	50                   	push   %eax
f01027dc:	e8 d0 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01027e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027e4:	8d 83 73 aa f7 ff    	lea    -0x8558d(%ebx),%eax
f01027ea:	50                   	push   %eax
f01027eb:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01027f1:	50                   	push   %eax
f01027f2:	68 9d 03 00 00       	push   $0x39d
f01027f7:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01027fd:	50                   	push   %eax
f01027fe:	e8 ae d8 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102803:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102806:	8d 83 cd aa f7 ff    	lea    -0x85533(%ebx),%eax
f010280c:	50                   	push   %eax
f010280d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102813:	50                   	push   %eax
f0102814:	68 9e 03 00 00       	push   $0x39e
f0102819:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010281f:	50                   	push   %eax
f0102820:	e8 8c d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102825:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102828:	8d 83 5c a6 f7 ff    	lea    -0x859a4(%ebx),%eax
f010282e:	50                   	push   %eax
f010282f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102835:	50                   	push   %eax
f0102836:	68 a1 03 00 00       	push   $0x3a1
f010283b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102841:	50                   	push   %eax
f0102842:	e8 6a d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref);
f0102847:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010284a:	8d 83 de aa f7 ff    	lea    -0x85522(%ebx),%eax
f0102850:	50                   	push   %eax
f0102851:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102857:	50                   	push   %eax
f0102858:	68 a2 03 00 00       	push   $0x3a2
f010285d:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102863:	50                   	push   %eax
f0102864:	e8 48 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_link == NULL);
f0102869:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010286c:	8d 83 ea aa f7 ff    	lea    -0x85516(%ebx),%eax
f0102872:	50                   	push   %eax
f0102873:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102879:	50                   	push   %eax
f010287a:	68 a3 03 00 00       	push   $0x3a3
f010287f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102885:	50                   	push   %eax
f0102886:	e8 26 d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010288b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010288e:	8d 83 38 a6 f7 ff    	lea    -0x859c8(%ebx),%eax
f0102894:	50                   	push   %eax
f0102895:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010289b:	50                   	push   %eax
f010289c:	68 a7 03 00 00       	push   $0x3a7
f01028a1:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01028a7:	50                   	push   %eax
f01028a8:	e8 04 d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01028ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028b0:	8d 83 94 a6 f7 ff    	lea    -0x8596c(%ebx),%eax
f01028b6:	50                   	push   %eax
f01028b7:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01028bd:	50                   	push   %eax
f01028be:	68 a8 03 00 00       	push   $0x3a8
f01028c3:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01028c9:	50                   	push   %eax
f01028ca:	e8 e2 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f01028cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028d2:	8d 83 ff aa f7 ff    	lea    -0x85501(%ebx),%eax
f01028d8:	50                   	push   %eax
f01028d9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01028df:	50                   	push   %eax
f01028e0:	68 a9 03 00 00       	push   $0x3a9
f01028e5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01028eb:	50                   	push   %eax
f01028ec:	e8 c0 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01028f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028f4:	8d 83 cd aa f7 ff    	lea    -0x85533(%ebx),%eax
f01028fa:	50                   	push   %eax
f01028fb:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102901:	50                   	push   %eax
f0102902:	68 aa 03 00 00       	push   $0x3aa
f0102907:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010290d:	50                   	push   %eax
f010290e:	e8 9e d7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102913:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102916:	8d 83 bc a6 f7 ff    	lea    -0x85944(%ebx),%eax
f010291c:	50                   	push   %eax
f010291d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102923:	50                   	push   %eax
f0102924:	68 ad 03 00 00       	push   $0x3ad
f0102929:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010292f:	50                   	push   %eax
f0102930:	e8 7c d7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102935:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102938:	8d 83 21 aa f7 ff    	lea    -0x855df(%ebx),%eax
f010293e:	50                   	push   %eax
f010293f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102945:	50                   	push   %eax
f0102946:	68 b0 03 00 00       	push   $0x3b0
f010294b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102951:	50                   	push   %eax
f0102952:	e8 5a d7 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102957:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010295a:	8d 83 60 a3 f7 ff    	lea    -0x85ca0(%ebx),%eax
f0102960:	50                   	push   %eax
f0102961:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102967:	50                   	push   %eax
f0102968:	68 b3 03 00 00       	push   $0x3b3
f010296d:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102973:	50                   	push   %eax
f0102974:	e8 38 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0102979:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010297c:	8d 83 84 aa f7 ff    	lea    -0x8557c(%ebx),%eax
f0102982:	50                   	push   %eax
f0102983:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102989:	50                   	push   %eax
f010298a:	68 b5 03 00 00       	push   $0x3b5
f010298f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102995:	50                   	push   %eax
f0102996:	e8 16 d7 ff ff       	call   f01000b1 <_panic>
f010299b:	52                   	push   %edx
f010299c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010299f:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f01029a5:	50                   	push   %eax
f01029a6:	68 bc 03 00 00       	push   $0x3bc
f01029ab:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01029b1:	50                   	push   %eax
f01029b2:	e8 fa d6 ff ff       	call   f01000b1 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01029b7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029ba:	8d 83 10 ab f7 ff    	lea    -0x854f0(%ebx),%eax
f01029c0:	50                   	push   %eax
f01029c1:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01029c7:	50                   	push   %eax
f01029c8:	68 bd 03 00 00       	push   $0x3bd
f01029cd:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01029d3:	50                   	push   %eax
f01029d4:	e8 d8 d6 ff ff       	call   f01000b1 <_panic>
f01029d9:	50                   	push   %eax
f01029da:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029dd:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f01029e3:	50                   	push   %eax
f01029e4:	6a 5d                	push   $0x5d
f01029e6:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f01029ec:	50                   	push   %eax
f01029ed:	e8 bf d6 ff ff       	call   f01000b1 <_panic>
f01029f2:	52                   	push   %edx
f01029f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029f6:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f01029fc:	50                   	push   %eax
f01029fd:	6a 5d                	push   $0x5d
f01029ff:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f0102a05:	50                   	push   %eax
f0102a06:	e8 a6 d6 ff ff       	call   f01000b1 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102a0b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a0e:	8d 83 28 ab f7 ff    	lea    -0x854d8(%ebx),%eax
f0102a14:	50                   	push   %eax
f0102a15:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102a1b:	50                   	push   %eax
f0102a1c:	68 c7 03 00 00       	push   $0x3c7
f0102a21:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102a27:	50                   	push   %eax
f0102a28:	e8 84 d6 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a2d:	50                   	push   %eax
f0102a2e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a31:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f0102a37:	50                   	push   %eax
f0102a38:	68 c5 00 00 00       	push   $0xc5
f0102a3d:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102a43:	50                   	push   %eax
f0102a44:	e8 68 d6 ff ff       	call   f01000b1 <_panic>
f0102a49:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a4c:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102a52:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f0102a58:	50                   	push   %eax
f0102a59:	68 da 00 00 00       	push   $0xda
f0102a5e:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102a64:	50                   	push   %eax
f0102a65:	e8 47 d6 ff ff       	call   f01000b1 <_panic>
f0102a6a:	ff 75 c0             	pushl  -0x40(%ebp)
f0102a6d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a70:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f0102a76:	50                   	push   %eax
f0102a77:	68 04 03 00 00       	push   $0x304
f0102a7c:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102a82:	50                   	push   %eax
f0102a83:	e8 29 d6 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a88:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a8b:	8d 83 e0 a6 f7 ff    	lea    -0x85920(%ebx),%eax
f0102a91:	50                   	push   %eax
f0102a92:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102a98:	50                   	push   %eax
f0102a99:	68 04 03 00 00       	push   $0x304
f0102a9e:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102aa4:	50                   	push   %eax
f0102aa5:	e8 07 d6 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102aaa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aad:	c7 c0 44 d3 18 f0    	mov    $0xf018d344,%eax
f0102ab3:	8b 00                	mov    (%eax),%eax
f0102ab5:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102ab8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102abb:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
f0102ac0:	8d 98 00 00 40 21    	lea    0x21400000(%eax),%ebx
f0102ac6:	89 fa                	mov    %edi,%edx
f0102ac8:	89 f0                	mov    %esi,%eax
f0102aca:	e8 93 e0 ff ff       	call   f0100b62 <check_va2pa>
f0102acf:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102ad6:	76 22                	jbe    f0102afa <mem_init+0x1747>
f0102ad8:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102adb:	39 d0                	cmp    %edx,%eax
f0102add:	75 39                	jne    f0102b18 <mem_init+0x1765>
f0102adf:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102ae5:	81 ff 00 80 c1 ee    	cmp    $0xeec18000,%edi
f0102aeb:	75 d9                	jne    f0102ac6 <mem_init+0x1713>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102aed:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102af0:	c1 e7 0c             	shl    $0xc,%edi
f0102af3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102af8:	eb 57                	jmp    f0102b51 <mem_init+0x179e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102afa:	ff 75 cc             	pushl  -0x34(%ebp)
f0102afd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b00:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f0102b06:	50                   	push   %eax
f0102b07:	68 09 03 00 00       	push   $0x309
f0102b0c:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102b12:	50                   	push   %eax
f0102b13:	e8 99 d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102b18:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b1b:	8d 83 14 a7 f7 ff    	lea    -0x858ec(%ebx),%eax
f0102b21:	50                   	push   %eax
f0102b22:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102b28:	50                   	push   %eax
f0102b29:	68 09 03 00 00       	push   $0x309
f0102b2e:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102b34:	50                   	push   %eax
f0102b35:	e8 77 d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102b3a:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102b40:	89 f0                	mov    %esi,%eax
f0102b42:	e8 1b e0 ff ff       	call   f0100b62 <check_va2pa>
f0102b47:	39 c3                	cmp    %eax,%ebx
f0102b49:	75 51                	jne    f0102b9c <mem_init+0x17e9>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b4b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b51:	39 fb                	cmp    %edi,%ebx
f0102b53:	72 e5                	jb     f0102b3a <mem_init+0x1787>
f0102b55:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b5a:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102b5d:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102b63:	89 da                	mov    %ebx,%edx
f0102b65:	89 f0                	mov    %esi,%eax
f0102b67:	e8 f6 df ff ff       	call   f0100b62 <check_va2pa>
f0102b6c:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102b6f:	39 c2                	cmp    %eax,%edx
f0102b71:	75 4b                	jne    f0102bbe <mem_init+0x180b>
f0102b73:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b79:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102b7f:	75 e2                	jne    f0102b63 <mem_init+0x17b0>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b81:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b86:	89 f0                	mov    %esi,%eax
f0102b88:	e8 d5 df ff ff       	call   f0100b62 <check_va2pa>
f0102b8d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b90:	75 4e                	jne    f0102be0 <mem_init+0x182d>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b92:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b97:	e9 8f 00 00 00       	jmp    f0102c2b <mem_init+0x1878>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102b9c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b9f:	8d 83 48 a7 f7 ff    	lea    -0x858b8(%ebx),%eax
f0102ba5:	50                   	push   %eax
f0102ba6:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102bac:	50                   	push   %eax
f0102bad:	68 0d 03 00 00       	push   $0x30d
f0102bb2:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102bb8:	50                   	push   %eax
f0102bb9:	e8 f3 d4 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102bbe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bc1:	8d 83 70 a7 f7 ff    	lea    -0x85890(%ebx),%eax
f0102bc7:	50                   	push   %eax
f0102bc8:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102bce:	50                   	push   %eax
f0102bcf:	68 11 03 00 00       	push   $0x311
f0102bd4:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102bda:	50                   	push   %eax
f0102bdb:	e8 d1 d4 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102be0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102be3:	8d 83 b8 a7 f7 ff    	lea    -0x85848(%ebx),%eax
f0102be9:	50                   	push   %eax
f0102bea:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102bf0:	50                   	push   %eax
f0102bf1:	68 12 03 00 00       	push   $0x312
f0102bf6:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102bfc:	50                   	push   %eax
f0102bfd:	e8 af d4 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102c02:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102c06:	74 52                	je     f0102c5a <mem_init+0x18a7>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c08:	83 c0 01             	add    $0x1,%eax
f0102c0b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102c10:	0f 87 bb 00 00 00    	ja     f0102cd1 <mem_init+0x191e>
		switch (i) {
f0102c16:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102c1b:	72 0e                	jb     f0102c2b <mem_init+0x1878>
f0102c1d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102c22:	76 de                	jbe    f0102c02 <mem_init+0x184f>
f0102c24:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c29:	74 d7                	je     f0102c02 <mem_init+0x184f>
			if (i >= PDX(KERNBASE)) {
f0102c2b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c30:	77 4a                	ja     f0102c7c <mem_init+0x18c9>
				assert(pgdir[i] == 0);
f0102c32:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102c36:	74 d0                	je     f0102c08 <mem_init+0x1855>
f0102c38:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c3b:	8d 83 7a ab f7 ff    	lea    -0x85486(%ebx),%eax
f0102c41:	50                   	push   %eax
f0102c42:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102c48:	50                   	push   %eax
f0102c49:	68 22 03 00 00       	push   $0x322
f0102c4e:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102c54:	50                   	push   %eax
f0102c55:	e8 57 d4 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102c5a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c5d:	8d 83 58 ab f7 ff    	lea    -0x854a8(%ebx),%eax
f0102c63:	50                   	push   %eax
f0102c64:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102c6a:	50                   	push   %eax
f0102c6b:	68 1b 03 00 00       	push   $0x31b
f0102c70:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102c76:	50                   	push   %eax
f0102c77:	e8 35 d4 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102c7c:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102c7f:	f6 c2 01             	test   $0x1,%dl
f0102c82:	74 2b                	je     f0102caf <mem_init+0x18fc>
				assert(pgdir[i] & PTE_W);
f0102c84:	f6 c2 02             	test   $0x2,%dl
f0102c87:	0f 85 7b ff ff ff    	jne    f0102c08 <mem_init+0x1855>
f0102c8d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c90:	8d 83 69 ab f7 ff    	lea    -0x85497(%ebx),%eax
f0102c96:	50                   	push   %eax
f0102c97:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102c9d:	50                   	push   %eax
f0102c9e:	68 20 03 00 00       	push   $0x320
f0102ca3:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102ca9:	50                   	push   %eax
f0102caa:	e8 02 d4 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102caf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cb2:	8d 83 58 ab f7 ff    	lea    -0x854a8(%ebx),%eax
f0102cb8:	50                   	push   %eax
f0102cb9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102cbf:	50                   	push   %eax
f0102cc0:	68 1f 03 00 00       	push   $0x31f
f0102cc5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102ccb:	50                   	push   %eax
f0102ccc:	e8 e0 d3 ff ff       	call   f01000b1 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102cd1:	83 ec 0c             	sub    $0xc,%esp
f0102cd4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102cd7:	8d 87 e8 a7 f7 ff    	lea    -0x85818(%edi),%eax
f0102cdd:	50                   	push   %eax
f0102cde:	89 fb                	mov    %edi,%ebx
f0102ce0:	e8 a5 09 00 00       	call   f010368a <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102ce5:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102ceb:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102ced:	83 c4 10             	add    $0x10,%esp
f0102cf0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cf5:	0f 86 44 02 00 00    	jbe    f0102f3f <mem_init+0x1b8c>
	return (physaddr_t)kva - KERNBASE;
f0102cfb:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102d00:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102d03:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d08:	e8 d2 de ff ff       	call   f0100bdf <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102d0d:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102d10:	83 e0 f3             	and    $0xfffffff3,%eax
f0102d13:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102d18:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102d1b:	83 ec 0c             	sub    $0xc,%esp
f0102d1e:	6a 00                	push   $0x0
f0102d20:	e8 2c e3 ff ff       	call   f0101051 <page_alloc>
f0102d25:	89 c6                	mov    %eax,%esi
f0102d27:	83 c4 10             	add    $0x10,%esp
f0102d2a:	85 c0                	test   %eax,%eax
f0102d2c:	0f 84 29 02 00 00    	je     f0102f5b <mem_init+0x1ba8>
	assert((pp1 = page_alloc(0)));
f0102d32:	83 ec 0c             	sub    $0xc,%esp
f0102d35:	6a 00                	push   $0x0
f0102d37:	e8 15 e3 ff ff       	call   f0101051 <page_alloc>
f0102d3c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102d3f:	83 c4 10             	add    $0x10,%esp
f0102d42:	85 c0                	test   %eax,%eax
f0102d44:	0f 84 33 02 00 00    	je     f0102f7d <mem_init+0x1bca>
	assert((pp2 = page_alloc(0)));
f0102d4a:	83 ec 0c             	sub    $0xc,%esp
f0102d4d:	6a 00                	push   $0x0
f0102d4f:	e8 fd e2 ff ff       	call   f0101051 <page_alloc>
f0102d54:	89 c7                	mov    %eax,%edi
f0102d56:	83 c4 10             	add    $0x10,%esp
f0102d59:	85 c0                	test   %eax,%eax
f0102d5b:	0f 84 3e 02 00 00    	je     f0102f9f <mem_init+0x1bec>
	page_free(pp0);
f0102d61:	83 ec 0c             	sub    $0xc,%esp
f0102d64:	56                   	push   %esi
f0102d65:	e8 6f e3 ff ff       	call   f01010d9 <page_free>
	return (pp - pages) << PGSHIFT;
f0102d6a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d6d:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102d73:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102d76:	2b 08                	sub    (%eax),%ecx
f0102d78:	89 c8                	mov    %ecx,%eax
f0102d7a:	c1 f8 03             	sar    $0x3,%eax
f0102d7d:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d80:	89 c1                	mov    %eax,%ecx
f0102d82:	c1 e9 0c             	shr    $0xc,%ecx
f0102d85:	83 c4 10             	add    $0x10,%esp
f0102d88:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102d8e:	3b 0a                	cmp    (%edx),%ecx
f0102d90:	0f 83 2b 02 00 00    	jae    f0102fc1 <mem_init+0x1c0e>
	memset(page2kva(pp1), 1, PGSIZE);
f0102d96:	83 ec 04             	sub    $0x4,%esp
f0102d99:	68 00 10 00 00       	push   $0x1000
f0102d9e:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102da0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102da5:	50                   	push   %eax
f0102da6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102da9:	e8 8c 19 00 00       	call   f010473a <memset>
	return (pp - pages) << PGSHIFT;
f0102dae:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102db1:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102db7:	89 f9                	mov    %edi,%ecx
f0102db9:	2b 08                	sub    (%eax),%ecx
f0102dbb:	89 c8                	mov    %ecx,%eax
f0102dbd:	c1 f8 03             	sar    $0x3,%eax
f0102dc0:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102dc3:	89 c1                	mov    %eax,%ecx
f0102dc5:	c1 e9 0c             	shr    $0xc,%ecx
f0102dc8:	83 c4 10             	add    $0x10,%esp
f0102dcb:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102dd1:	3b 0a                	cmp    (%edx),%ecx
f0102dd3:	0f 83 fe 01 00 00    	jae    f0102fd7 <mem_init+0x1c24>
	memset(page2kva(pp2), 2, PGSIZE);
f0102dd9:	83 ec 04             	sub    $0x4,%esp
f0102ddc:	68 00 10 00 00       	push   $0x1000
f0102de1:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102de3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102de8:	50                   	push   %eax
f0102de9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dec:	e8 49 19 00 00       	call   f010473a <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102df1:	6a 02                	push   $0x2
f0102df3:	68 00 10 00 00       	push   $0x1000
f0102df8:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102dfb:	53                   	push   %ebx
f0102dfc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102dff:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102e05:	ff 30                	pushl  (%eax)
f0102e07:	e8 29 e5 ff ff       	call   f0101335 <page_insert>
	assert(pp1->pp_ref == 1);
f0102e0c:	83 c4 20             	add    $0x20,%esp
f0102e0f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e14:	0f 85 d3 01 00 00    	jne    f0102fed <mem_init+0x1c3a>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e1a:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102e21:	01 01 01 
f0102e24:	0f 85 e5 01 00 00    	jne    f010300f <mem_init+0x1c5c>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102e2a:	6a 02                	push   $0x2
f0102e2c:	68 00 10 00 00       	push   $0x1000
f0102e31:	57                   	push   %edi
f0102e32:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e35:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102e3b:	ff 30                	pushl  (%eax)
f0102e3d:	e8 f3 e4 ff ff       	call   f0101335 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e42:	83 c4 10             	add    $0x10,%esp
f0102e45:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102e4c:	02 02 02 
f0102e4f:	0f 85 dc 01 00 00    	jne    f0103031 <mem_init+0x1c7e>
	assert(pp2->pp_ref == 1);
f0102e55:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102e5a:	0f 85 f3 01 00 00    	jne    f0103053 <mem_init+0x1ca0>
	assert(pp1->pp_ref == 0);
f0102e60:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102e63:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102e68:	0f 85 07 02 00 00    	jne    f0103075 <mem_init+0x1cc2>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102e6e:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102e75:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102e78:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e7b:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102e81:	89 f9                	mov    %edi,%ecx
f0102e83:	2b 08                	sub    (%eax),%ecx
f0102e85:	89 c8                	mov    %ecx,%eax
f0102e87:	c1 f8 03             	sar    $0x3,%eax
f0102e8a:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e8d:	89 c1                	mov    %eax,%ecx
f0102e8f:	c1 e9 0c             	shr    $0xc,%ecx
f0102e92:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f0102e98:	3b 0a                	cmp    (%edx),%ecx
f0102e9a:	0f 83 f7 01 00 00    	jae    f0103097 <mem_init+0x1ce4>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ea0:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102ea7:	03 03 03 
f0102eaa:	0f 85 fd 01 00 00    	jne    f01030ad <mem_init+0x1cfa>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102eb0:	83 ec 08             	sub    $0x8,%esp
f0102eb3:	68 00 10 00 00       	push   $0x1000
f0102eb8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ebb:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102ec1:	ff 30                	pushl  (%eax)
f0102ec3:	e8 30 e4 ff ff       	call   f01012f8 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ec8:	83 c4 10             	add    $0x10,%esp
f0102ecb:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ed0:	0f 85 f9 01 00 00    	jne    f01030cf <mem_init+0x1d1c>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ed6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ed9:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0102edf:	8b 08                	mov    (%eax),%ecx
f0102ee1:	8b 11                	mov    (%ecx),%edx
f0102ee3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102ee9:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0102eef:	89 f7                	mov    %esi,%edi
f0102ef1:	2b 38                	sub    (%eax),%edi
f0102ef3:	89 f8                	mov    %edi,%eax
f0102ef5:	c1 f8 03             	sar    $0x3,%eax
f0102ef8:	c1 e0 0c             	shl    $0xc,%eax
f0102efb:	39 c2                	cmp    %eax,%edx
f0102efd:	0f 85 ee 01 00 00    	jne    f01030f1 <mem_init+0x1d3e>
	kern_pgdir[0] = 0;
f0102f03:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102f09:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f0e:	0f 85 ff 01 00 00    	jne    f0103113 <mem_init+0x1d60>
	pp0->pp_ref = 0;
f0102f14:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102f1a:	83 ec 0c             	sub    $0xc,%esp
f0102f1d:	56                   	push   %esi
f0102f1e:	e8 b6 e1 ff ff       	call   f01010d9 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102f23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f26:	8d 83 7c a8 f7 ff    	lea    -0x85784(%ebx),%eax
f0102f2c:	89 04 24             	mov    %eax,(%esp)
f0102f2f:	e8 56 07 00 00       	call   f010368a <cprintf>
}
f0102f34:	83 c4 10             	add    $0x10,%esp
f0102f37:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f3a:	5b                   	pop    %ebx
f0102f3b:	5e                   	pop    %esi
f0102f3c:	5f                   	pop    %edi
f0102f3d:	5d                   	pop    %ebp
f0102f3e:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f3f:	50                   	push   %eax
f0102f40:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f43:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f0102f49:	50                   	push   %eax
f0102f4a:	68 ee 00 00 00       	push   $0xee
f0102f4f:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102f55:	50                   	push   %eax
f0102f56:	e8 56 d1 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0102f5b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f5e:	8d 83 76 a9 f7 ff    	lea    -0x8568a(%ebx),%eax
f0102f64:	50                   	push   %eax
f0102f65:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102f6b:	50                   	push   %eax
f0102f6c:	68 e2 03 00 00       	push   $0x3e2
f0102f71:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102f77:	50                   	push   %eax
f0102f78:	e8 34 d1 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0102f7d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f80:	8d 83 8c a9 f7 ff    	lea    -0x85674(%ebx),%eax
f0102f86:	50                   	push   %eax
f0102f87:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102f8d:	50                   	push   %eax
f0102f8e:	68 e3 03 00 00       	push   $0x3e3
f0102f93:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102f99:	50                   	push   %eax
f0102f9a:	e8 12 d1 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0102f9f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fa2:	8d 83 a2 a9 f7 ff    	lea    -0x8565e(%ebx),%eax
f0102fa8:	50                   	push   %eax
f0102fa9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102faf:	50                   	push   %eax
f0102fb0:	68 e4 03 00 00       	push   $0x3e4
f0102fb5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0102fbb:	50                   	push   %eax
f0102fbc:	e8 f0 d0 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fc1:	50                   	push   %eax
f0102fc2:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f0102fc8:	50                   	push   %eax
f0102fc9:	6a 5d                	push   $0x5d
f0102fcb:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f0102fd1:	50                   	push   %eax
f0102fd2:	e8 da d0 ff ff       	call   f01000b1 <_panic>
f0102fd7:	50                   	push   %eax
f0102fd8:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f0102fde:	50                   	push   %eax
f0102fdf:	6a 5d                	push   $0x5d
f0102fe1:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f0102fe7:	50                   	push   %eax
f0102fe8:	e8 c4 d0 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102fed:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ff0:	8d 83 73 aa f7 ff    	lea    -0x8558d(%ebx),%eax
f0102ff6:	50                   	push   %eax
f0102ff7:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0102ffd:	50                   	push   %eax
f0102ffe:	68 e9 03 00 00       	push   $0x3e9
f0103003:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0103009:	50                   	push   %eax
f010300a:	e8 a2 d0 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010300f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103012:	8d 83 08 a8 f7 ff    	lea    -0x857f8(%ebx),%eax
f0103018:	50                   	push   %eax
f0103019:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f010301f:	50                   	push   %eax
f0103020:	68 ea 03 00 00       	push   $0x3ea
f0103025:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010302b:	50                   	push   %eax
f010302c:	e8 80 d0 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103031:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103034:	8d 83 2c a8 f7 ff    	lea    -0x857d4(%ebx),%eax
f010303a:	50                   	push   %eax
f010303b:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0103041:	50                   	push   %eax
f0103042:	68 ec 03 00 00       	push   $0x3ec
f0103047:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010304d:	50                   	push   %eax
f010304e:	e8 5e d0 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0103053:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103056:	8d 83 95 aa f7 ff    	lea    -0x8556b(%ebx),%eax
f010305c:	50                   	push   %eax
f010305d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0103063:	50                   	push   %eax
f0103064:	68 ed 03 00 00       	push   $0x3ed
f0103069:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010306f:	50                   	push   %eax
f0103070:	e8 3c d0 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f0103075:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103078:	8d 83 ff aa f7 ff    	lea    -0x85501(%ebx),%eax
f010307e:	50                   	push   %eax
f010307f:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0103085:	50                   	push   %eax
f0103086:	68 ee 03 00 00       	push   $0x3ee
f010308b:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f0103091:	50                   	push   %eax
f0103092:	e8 1a d0 ff ff       	call   f01000b1 <_panic>
f0103097:	50                   	push   %eax
f0103098:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f010309e:	50                   	push   %eax
f010309f:	6a 5d                	push   $0x5d
f01030a1:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f01030a7:	50                   	push   %eax
f01030a8:	e8 04 d0 ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01030ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030b0:	8d 83 50 a8 f7 ff    	lea    -0x857b0(%ebx),%eax
f01030b6:	50                   	push   %eax
f01030b7:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01030bd:	50                   	push   %eax
f01030be:	68 f0 03 00 00       	push   $0x3f0
f01030c3:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01030c9:	50                   	push   %eax
f01030ca:	e8 e2 cf ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01030cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030d2:	8d 83 cd aa f7 ff    	lea    -0x85533(%ebx),%eax
f01030d8:	50                   	push   %eax
f01030d9:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01030df:	50                   	push   %eax
f01030e0:	68 f2 03 00 00       	push   $0x3f2
f01030e5:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f01030eb:	50                   	push   %eax
f01030ec:	e8 c0 cf ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01030f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030f4:	8d 83 60 a3 f7 ff    	lea    -0x85ca0(%ebx),%eax
f01030fa:	50                   	push   %eax
f01030fb:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0103101:	50                   	push   %eax
f0103102:	68 f5 03 00 00       	push   $0x3f5
f0103107:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010310d:	50                   	push   %eax
f010310e:	e8 9e cf ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0103113:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103116:	8d 83 84 aa f7 ff    	lea    -0x8557c(%ebx),%eax
f010311c:	50                   	push   %eax
f010311d:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0103123:	50                   	push   %eax
f0103124:	68 f7 03 00 00       	push   $0x3f7
f0103129:	8d 83 a5 a8 f7 ff    	lea    -0x8575b(%ebx),%eax
f010312f:	50                   	push   %eax
f0103130:	e8 7c cf ff ff       	call   f01000b1 <_panic>

f0103135 <tlb_invalidate>:
{
f0103135:	55                   	push   %ebp
f0103136:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103138:	8b 45 0c             	mov    0xc(%ebp),%eax
f010313b:	0f 01 38             	invlpg (%eax)
}
f010313e:	5d                   	pop    %ebp
f010313f:	c3                   	ret    

f0103140 <user_mem_check>:
{
f0103140:	55                   	push   %ebp
f0103141:	89 e5                	mov    %esp,%ebp
}
f0103143:	b8 00 00 00 00       	mov    $0x0,%eax
f0103148:	5d                   	pop    %ebp
f0103149:	c3                   	ret    

f010314a <user_mem_assert>:
{
f010314a:	55                   	push   %ebp
f010314b:	89 e5                	mov    %esp,%ebp
}
f010314d:	5d                   	pop    %ebp
f010314e:	c3                   	ret    

f010314f <__x86.get_pc_thunk.dx>:
f010314f:	8b 14 24             	mov    (%esp),%edx
f0103152:	c3                   	ret    

f0103153 <__x86.get_pc_thunk.cx>:
f0103153:	8b 0c 24             	mov    (%esp),%ecx
f0103156:	c3                   	ret    

f0103157 <__x86.get_pc_thunk.si>:
f0103157:	8b 34 24             	mov    (%esp),%esi
f010315a:	c3                   	ret    

f010315b <__x86.get_pc_thunk.di>:
f010315b:	8b 3c 24             	mov    (%esp),%edi
f010315e:	c3                   	ret    

f010315f <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010315f:	55                   	push   %ebp
f0103160:	89 e5                	mov    %esp,%ebp
f0103162:	53                   	push   %ebx
f0103163:	e8 eb ff ff ff       	call   f0103153 <__x86.get_pc_thunk.cx>
f0103168:	81 c1 b8 7e 08 00    	add    $0x87eb8,%ecx
f010316e:	8b 55 08             	mov    0x8(%ebp),%edx
f0103171:	8b 5d 10             	mov    0x10(%ebp),%ebx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103174:	85 d2                	test   %edx,%edx
f0103176:	74 41                	je     f01031b9 <envid2env+0x5a>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103178:	89 d0                	mov    %edx,%eax
f010317a:	25 ff 03 00 00       	and    $0x3ff,%eax
f010317f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103182:	c1 e0 05             	shl    $0x5,%eax
f0103185:	03 81 24 23 00 00    	add    0x2324(%ecx),%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010318b:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010318f:	74 3a                	je     f01031cb <envid2env+0x6c>
f0103191:	39 50 48             	cmp    %edx,0x48(%eax)
f0103194:	75 35                	jne    f01031cb <envid2env+0x6c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103196:	84 db                	test   %bl,%bl
f0103198:	74 12                	je     f01031ac <envid2env+0x4d>
f010319a:	8b 91 20 23 00 00    	mov    0x2320(%ecx),%edx
f01031a0:	39 c2                	cmp    %eax,%edx
f01031a2:	74 08                	je     f01031ac <envid2env+0x4d>
f01031a4:	8b 5a 48             	mov    0x48(%edx),%ebx
f01031a7:	39 58 4c             	cmp    %ebx,0x4c(%eax)
f01031aa:	75 2f                	jne    f01031db <envid2env+0x7c>
		*env_store = 0;
		return -E_BAD_ENV;
	}

	*env_store = e;
f01031ac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01031af:	89 03                	mov    %eax,(%ebx)
	return 0;
f01031b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031b6:	5b                   	pop    %ebx
f01031b7:	5d                   	pop    %ebp
f01031b8:	c3                   	ret    
		*env_store = curenv;
f01031b9:	8b 81 20 23 00 00    	mov    0x2320(%ecx),%eax
f01031bf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031c2:	89 01                	mov    %eax,(%ecx)
		return 0;
f01031c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01031c9:	eb eb                	jmp    f01031b6 <envid2env+0x57>
		*env_store = 0;
f01031cb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031ce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01031d4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01031d9:	eb db                	jmp    f01031b6 <envid2env+0x57>
		*env_store = 0;
f01031db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031de:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01031e4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01031e9:	eb cb                	jmp    f01031b6 <envid2env+0x57>

f01031eb <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01031eb:	55                   	push   %ebp
f01031ec:	89 e5                	mov    %esp,%ebp
f01031ee:	e8 16 d5 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f01031f3:	05 2d 7e 08 00       	add    $0x87e2d,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f01031f8:	8d 80 e0 1f 00 00    	lea    0x1fe0(%eax),%eax
f01031fe:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103201:	b8 23 00 00 00       	mov    $0x23,%eax
f0103206:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0103208:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010320a:	b8 10 00 00 00       	mov    $0x10,%eax
f010320f:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103211:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103213:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0103215:	ea 1c 32 10 f0 08 00 	ljmp   $0x8,$0xf010321c
	asm volatile("lldt %0" : : "r" (sel));
f010321c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103221:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103224:	5d                   	pop    %ebp
f0103225:	c3                   	ret    

f0103226 <env_init>:
{
f0103226:	55                   	push   %ebp
f0103227:	89 e5                	mov    %esp,%ebp
	env_init_percpu();
f0103229:	e8 bd ff ff ff       	call   f01031eb <env_init_percpu>
}
f010322e:	5d                   	pop    %ebp
f010322f:	c3                   	ret    

f0103230 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103230:	55                   	push   %ebp
f0103231:	89 e5                	mov    %esp,%ebp
f0103233:	56                   	push   %esi
f0103234:	53                   	push   %ebx
f0103235:	e8 2d cf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010323a:	81 c3 e6 7d 08 00    	add    $0x87de6,%ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103240:	8b b3 28 23 00 00    	mov    0x2328(%ebx),%esi
f0103246:	85 f6                	test   %esi,%esi
f0103248:	0f 84 03 01 00 00    	je     f0103351 <env_alloc+0x121>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010324e:	83 ec 0c             	sub    $0xc,%esp
f0103251:	6a 01                	push   $0x1
f0103253:	e8 f9 dd ff ff       	call   f0101051 <page_alloc>
f0103258:	83 c4 10             	add    $0x10,%esp
f010325b:	85 c0                	test   %eax,%eax
f010325d:	0f 84 f5 00 00 00    	je     f0103358 <env_alloc+0x128>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103263:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0103266:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010326b:	0f 86 c7 00 00 00    	jbe    f0103338 <env_alloc+0x108>
	return (physaddr_t)kva - KERNBASE;
f0103271:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103277:	83 ca 05             	or     $0x5,%edx
f010327a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103280:	8b 46 48             	mov    0x48(%esi),%eax
f0103283:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103288:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f010328d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103292:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103295:	89 f2                	mov    %esi,%edx
f0103297:	2b 93 24 23 00 00    	sub    0x2324(%ebx),%edx
f010329d:	c1 fa 05             	sar    $0x5,%edx
f01032a0:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032a6:	09 d0                	or     %edx,%eax
f01032a8:	89 46 48             	mov    %eax,0x48(%esi)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01032ab:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032ae:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f01032b1:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f01032b8:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f01032bf:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01032c6:	83 ec 04             	sub    $0x4,%esp
f01032c9:	6a 44                	push   $0x44
f01032cb:	6a 00                	push   $0x0
f01032cd:	56                   	push   %esi
f01032ce:	e8 67 14 00 00       	call   f010473a <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01032d3:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f01032d9:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f01032df:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f01032e5:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f01032ec:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01032f2:	8b 46 44             	mov    0x44(%esi),%eax
f01032f5:	89 83 28 23 00 00    	mov    %eax,0x2328(%ebx)
	*newenv_store = e;
f01032fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01032fe:	89 30                	mov    %esi,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103300:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103303:	8b 83 20 23 00 00    	mov    0x2320(%ebx),%eax
f0103309:	83 c4 10             	add    $0x10,%esp
f010330c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103311:	85 c0                	test   %eax,%eax
f0103313:	74 03                	je     f0103318 <env_alloc+0xe8>
f0103315:	8b 50 48             	mov    0x48(%eax),%edx
f0103318:	83 ec 04             	sub    $0x4,%esp
f010331b:	51                   	push   %ecx
f010331c:	52                   	push   %edx
f010331d:	8d 83 c9 ab f7 ff    	lea    -0x85437(%ebx),%eax
f0103323:	50                   	push   %eax
f0103324:	e8 61 03 00 00       	call   f010368a <cprintf>
	return 0;
f0103329:	83 c4 10             	add    $0x10,%esp
f010332c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103331:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103334:	5b                   	pop    %ebx
f0103335:	5e                   	pop    %esi
f0103336:	5d                   	pop    %ebp
f0103337:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103338:	50                   	push   %eax
f0103339:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f010333f:	50                   	push   %eax
f0103340:	68 b9 00 00 00       	push   $0xb9
f0103345:	8d 83 be ab f7 ff    	lea    -0x85442(%ebx),%eax
f010334b:	50                   	push   %eax
f010334c:	e8 60 cd ff ff       	call   f01000b1 <_panic>
		return -E_NO_FREE_ENV;
f0103351:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103356:	eb d9                	jmp    f0103331 <env_alloc+0x101>
		return -E_NO_MEM;
f0103358:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010335d:	eb d2                	jmp    f0103331 <env_alloc+0x101>

f010335f <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010335f:	55                   	push   %ebp
f0103360:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0103362:	5d                   	pop    %ebp
f0103363:	c3                   	ret    

f0103364 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103364:	55                   	push   %ebp
f0103365:	89 e5                	mov    %esp,%ebp
f0103367:	57                   	push   %edi
f0103368:	56                   	push   %esi
f0103369:	53                   	push   %ebx
f010336a:	83 ec 2c             	sub    $0x2c,%esp
f010336d:	e8 f5 cd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103372:	81 c3 ae 7c 08 00    	add    $0x87cae,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103378:	8b 93 20 23 00 00    	mov    0x2320(%ebx),%edx
f010337e:	3b 55 08             	cmp    0x8(%ebp),%edx
f0103381:	75 17                	jne    f010339a <env_free+0x36>
		lcr3(PADDR(kern_pgdir));
f0103383:	c7 c0 0c e0 18 f0    	mov    $0xf018e00c,%eax
f0103389:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010338b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103390:	76 46                	jbe    f01033d8 <env_free+0x74>
	return (physaddr_t)kva - KERNBASE;
f0103392:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103397:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010339a:	8b 45 08             	mov    0x8(%ebp),%eax
f010339d:	8b 48 48             	mov    0x48(%eax),%ecx
f01033a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01033a5:	85 d2                	test   %edx,%edx
f01033a7:	74 03                	je     f01033ac <env_free+0x48>
f01033a9:	8b 42 48             	mov    0x48(%edx),%eax
f01033ac:	83 ec 04             	sub    $0x4,%esp
f01033af:	51                   	push   %ecx
f01033b0:	50                   	push   %eax
f01033b1:	8d 83 de ab f7 ff    	lea    -0x85422(%ebx),%eax
f01033b7:	50                   	push   %eax
f01033b8:	e8 cd 02 00 00       	call   f010368a <cprintf>
f01033bd:	83 c4 10             	add    $0x10,%esp
f01033c0:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	if (PGNUM(pa) >= npages)
f01033c7:	c7 c0 08 e0 18 f0    	mov    $0xf018e008,%eax
f01033cd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (PGNUM(pa) >= npages)
f01033d0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01033d3:	e9 9f 00 00 00       	jmp    f0103477 <env_free+0x113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033d8:	50                   	push   %eax
f01033d9:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f01033df:	50                   	push   %eax
f01033e0:	68 68 01 00 00       	push   $0x168
f01033e5:	8d 83 be ab f7 ff    	lea    -0x85442(%ebx),%eax
f01033eb:	50                   	push   %eax
f01033ec:	e8 c0 cc ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01033f1:	50                   	push   %eax
f01033f2:	8d 83 b8 a0 f7 ff    	lea    -0x85f48(%ebx),%eax
f01033f8:	50                   	push   %eax
f01033f9:	68 77 01 00 00       	push   $0x177
f01033fe:	8d 83 be ab f7 ff    	lea    -0x85442(%ebx),%eax
f0103404:	50                   	push   %eax
f0103405:	e8 a7 cc ff ff       	call   f01000b1 <_panic>
f010340a:	83 c6 04             	add    $0x4,%esi
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010340d:	39 fe                	cmp    %edi,%esi
f010340f:	74 24                	je     f0103435 <env_free+0xd1>
			if (pt[pteno] & PTE_P)
f0103411:	f6 06 01             	testb  $0x1,(%esi)
f0103414:	74 f4                	je     f010340a <env_free+0xa6>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103416:	83 ec 08             	sub    $0x8,%esp
f0103419:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010341c:	01 f0                	add    %esi,%eax
f010341e:	c1 e0 0a             	shl    $0xa,%eax
f0103421:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103424:	50                   	push   %eax
f0103425:	8b 45 08             	mov    0x8(%ebp),%eax
f0103428:	ff 70 5c             	pushl  0x5c(%eax)
f010342b:	e8 c8 de ff ff       	call   f01012f8 <page_remove>
f0103430:	83 c4 10             	add    $0x10,%esp
f0103433:	eb d5                	jmp    f010340a <env_free+0xa6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103435:	8b 45 08             	mov    0x8(%ebp),%eax
f0103438:	8b 40 5c             	mov    0x5c(%eax),%eax
f010343b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010343e:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103445:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103448:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010344b:	3b 10                	cmp    (%eax),%edx
f010344d:	73 6f                	jae    f01034be <env_free+0x15a>
		page_decref(pa2page(pa));
f010344f:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103452:	c7 c0 10 e0 18 f0    	mov    $0xf018e010,%eax
f0103458:	8b 00                	mov    (%eax),%eax
f010345a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010345d:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103460:	50                   	push   %eax
f0103461:	e8 c2 dc ff ff       	call   f0101128 <page_decref>
f0103466:	83 c4 10             	add    $0x10,%esp
f0103469:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f010346d:	8b 45 dc             	mov    -0x24(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103470:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103475:	74 5f                	je     f01034d6 <env_free+0x172>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103477:	8b 45 08             	mov    0x8(%ebp),%eax
f010347a:	8b 40 5c             	mov    0x5c(%eax),%eax
f010347d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103480:	8b 04 10             	mov    (%eax,%edx,1),%eax
f0103483:	a8 01                	test   $0x1,%al
f0103485:	74 e2                	je     f0103469 <env_free+0x105>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103487:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010348c:	89 c2                	mov    %eax,%edx
f010348e:	c1 ea 0c             	shr    $0xc,%edx
f0103491:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0103494:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103497:	39 11                	cmp    %edx,(%ecx)
f0103499:	0f 86 52 ff ff ff    	jbe    f01033f1 <env_free+0x8d>
	return (void *)(pa + KERNBASE);
f010349f:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034a5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034a8:	c1 e2 14             	shl    $0x14,%edx
f01034ab:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01034ae:	8d b8 00 10 00 f0    	lea    -0xffff000(%eax),%edi
f01034b4:	f7 d8                	neg    %eax
f01034b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034b9:	e9 53 ff ff ff       	jmp    f0103411 <env_free+0xad>
		panic("pa2page called with invalid pa");
f01034be:	83 ec 04             	sub    $0x4,%esp
f01034c1:	8d 83 2c a2 f7 ff    	lea    -0x85dd4(%ebx),%eax
f01034c7:	50                   	push   %eax
f01034c8:	6a 56                	push   $0x56
f01034ca:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f01034d0:	50                   	push   %eax
f01034d1:	e8 db cb ff ff       	call   f01000b1 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01034d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01034d9:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01034dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034e1:	76 57                	jbe    f010353a <env_free+0x1d6>
	e->env_pgdir = 0;
f01034e3:	8b 55 08             	mov    0x8(%ebp),%edx
f01034e6:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f01034ed:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f01034f2:	c1 e8 0c             	shr    $0xc,%eax
f01034f5:	c7 c2 08 e0 18 f0    	mov    $0xf018e008,%edx
f01034fb:	3b 02                	cmp    (%edx),%eax
f01034fd:	73 54                	jae    f0103553 <env_free+0x1ef>
	page_decref(pa2page(pa));
f01034ff:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103502:	c7 c2 10 e0 18 f0    	mov    $0xf018e010,%edx
f0103508:	8b 12                	mov    (%edx),%edx
f010350a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010350d:	50                   	push   %eax
f010350e:	e8 15 dc ff ff       	call   f0101128 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103513:	8b 45 08             	mov    0x8(%ebp),%eax
f0103516:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f010351d:	8b 83 28 23 00 00    	mov    0x2328(%ebx),%eax
f0103523:	8b 55 08             	mov    0x8(%ebp),%edx
f0103526:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f0103529:	89 93 28 23 00 00    	mov    %edx,0x2328(%ebx)
}
f010352f:	83 c4 10             	add    $0x10,%esp
f0103532:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103535:	5b                   	pop    %ebx
f0103536:	5e                   	pop    %esi
f0103537:	5f                   	pop    %edi
f0103538:	5d                   	pop    %ebp
f0103539:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010353a:	50                   	push   %eax
f010353b:	8d 83 c4 a1 f7 ff    	lea    -0x85e3c(%ebx),%eax
f0103541:	50                   	push   %eax
f0103542:	68 85 01 00 00       	push   $0x185
f0103547:	8d 83 be ab f7 ff    	lea    -0x85442(%ebx),%eax
f010354d:	50                   	push   %eax
f010354e:	e8 5e cb ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f0103553:	83 ec 04             	sub    $0x4,%esp
f0103556:	8d 83 2c a2 f7 ff    	lea    -0x85dd4(%ebx),%eax
f010355c:	50                   	push   %eax
f010355d:	6a 56                	push   $0x56
f010355f:	8d 83 b1 a8 f7 ff    	lea    -0x8574f(%ebx),%eax
f0103565:	50                   	push   %eax
f0103566:	e8 46 cb ff ff       	call   f01000b1 <_panic>

f010356b <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f010356b:	55                   	push   %ebp
f010356c:	89 e5                	mov    %esp,%ebp
f010356e:	53                   	push   %ebx
f010356f:	83 ec 10             	sub    $0x10,%esp
f0103572:	e8 f0 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103577:	81 c3 a9 7a 08 00    	add    $0x87aa9,%ebx
	env_free(e);
f010357d:	ff 75 08             	pushl  0x8(%ebp)
f0103580:	e8 df fd ff ff       	call   f0103364 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103585:	8d 83 88 ab f7 ff    	lea    -0x85478(%ebx),%eax
f010358b:	89 04 24             	mov    %eax,(%esp)
f010358e:	e8 f7 00 00 00       	call   f010368a <cprintf>
f0103593:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0103596:	83 ec 0c             	sub    $0xc,%esp
f0103599:	6a 00                	push   $0x0
f010359b:	e8 bf d3 ff ff       	call   f010095f <monitor>
f01035a0:	83 c4 10             	add    $0x10,%esp
f01035a3:	eb f1                	jmp    f0103596 <env_destroy+0x2b>

f01035a5 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035a5:	55                   	push   %ebp
f01035a6:	89 e5                	mov    %esp,%ebp
f01035a8:	53                   	push   %ebx
f01035a9:	83 ec 08             	sub    $0x8,%esp
f01035ac:	e8 b6 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01035b1:	81 c3 6f 7a 08 00    	add    $0x87a6f,%ebx
	asm volatile(
f01035b7:	8b 65 08             	mov    0x8(%ebp),%esp
f01035ba:	61                   	popa   
f01035bb:	07                   	pop    %es
f01035bc:	1f                   	pop    %ds
f01035bd:	83 c4 08             	add    $0x8,%esp
f01035c0:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01035c1:	8d 83 f4 ab f7 ff    	lea    -0x8540c(%ebx),%eax
f01035c7:	50                   	push   %eax
f01035c8:	68 ae 01 00 00       	push   $0x1ae
f01035cd:	8d 83 be ab f7 ff    	lea    -0x85442(%ebx),%eax
f01035d3:	50                   	push   %eax
f01035d4:	e8 d8 ca ff ff       	call   f01000b1 <_panic>

f01035d9 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01035d9:	55                   	push   %ebp
f01035da:	89 e5                	mov    %esp,%ebp
f01035dc:	53                   	push   %ebx
f01035dd:	83 ec 08             	sub    $0x8,%esp
f01035e0:	e8 82 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01035e5:	81 c3 3b 7a 08 00    	add    $0x87a3b,%ebx
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f01035eb:	8d 83 00 ac f7 ff    	lea    -0x85400(%ebx),%eax
f01035f1:	50                   	push   %eax
f01035f2:	68 cd 01 00 00       	push   $0x1cd
f01035f7:	8d 83 be ab f7 ff    	lea    -0x85442(%ebx),%eax
f01035fd:	50                   	push   %eax
f01035fe:	e8 ae ca ff ff       	call   f01000b1 <_panic>

f0103603 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103603:	55                   	push   %ebp
f0103604:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103606:	8b 45 08             	mov    0x8(%ebp),%eax
f0103609:	ba 70 00 00 00       	mov    $0x70,%edx
f010360e:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010360f:	ba 71 00 00 00       	mov    $0x71,%edx
f0103614:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103615:	0f b6 c0             	movzbl %al,%eax
}
f0103618:	5d                   	pop    %ebp
f0103619:	c3                   	ret    

f010361a <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010361a:	55                   	push   %ebp
f010361b:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010361d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103620:	ba 70 00 00 00       	mov    $0x70,%edx
f0103625:	ee                   	out    %al,(%dx)
f0103626:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103629:	ba 71 00 00 00       	mov    $0x71,%edx
f010362e:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010362f:	5d                   	pop    %ebp
f0103630:	c3                   	ret    

f0103631 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103631:	55                   	push   %ebp
f0103632:	89 e5                	mov    %esp,%ebp
f0103634:	53                   	push   %ebx
f0103635:	83 ec 10             	sub    $0x10,%esp
f0103638:	e8 2a cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010363d:	81 c3 e3 79 08 00    	add    $0x879e3,%ebx
	cputchar(ch);
f0103643:	ff 75 08             	pushl  0x8(%ebp)
f0103646:	e8 93 d0 ff ff       	call   f01006de <cputchar>
	*cnt++;
}
f010364b:	83 c4 10             	add    $0x10,%esp
f010364e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103651:	c9                   	leave  
f0103652:	c3                   	ret    

f0103653 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103653:	55                   	push   %ebp
f0103654:	89 e5                	mov    %esp,%ebp
f0103656:	53                   	push   %ebx
f0103657:	83 ec 14             	sub    $0x14,%esp
f010365a:	e8 08 cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010365f:	81 c3 c1 79 08 00    	add    $0x879c1,%ebx
	int cnt = 0;
f0103665:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010366c:	ff 75 0c             	pushl  0xc(%ebp)
f010366f:	ff 75 08             	pushl  0x8(%ebp)
f0103672:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103675:	50                   	push   %eax
f0103676:	8d 83 11 86 f7 ff    	lea    -0x879ef(%ebx),%eax
f010367c:	50                   	push   %eax
f010367d:	e8 37 09 00 00       	call   f0103fb9 <vprintfmt>
	return cnt;
}
f0103682:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103685:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103688:	c9                   	leave  
f0103689:	c3                   	ret    

f010368a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010368a:	55                   	push   %ebp
f010368b:	89 e5                	mov    %esp,%ebp
f010368d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103690:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103693:	50                   	push   %eax
f0103694:	ff 75 08             	pushl  0x8(%ebp)
f0103697:	e8 b7 ff ff ff       	call   f0103653 <vcprintf>
	va_end(ap);

	return cnt;
}
f010369c:	c9                   	leave  
f010369d:	c3                   	ret    

f010369e <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010369e:	55                   	push   %ebp
f010369f:	89 e5                	mov    %esp,%ebp
f01036a1:	57                   	push   %edi
f01036a2:	56                   	push   %esi
f01036a3:	53                   	push   %ebx
f01036a4:	83 ec 04             	sub    $0x4,%esp
f01036a7:	e8 bb ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01036ac:	81 c3 74 79 08 00    	add    $0x87974,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01036b2:	c7 83 64 2b 00 00 00 	movl   $0xf0000000,0x2b64(%ebx)
f01036b9:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01036bc:	66 c7 83 68 2b 00 00 	movw   $0x10,0x2b68(%ebx)
f01036c3:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f01036c5:	66 c7 83 c6 2b 00 00 	movw   $0x68,0x2bc6(%ebx)
f01036cc:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01036ce:	c7 c0 00 a3 11 f0    	mov    $0xf011a300,%eax
f01036d4:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f01036da:	8d b3 60 2b 00 00    	lea    0x2b60(%ebx),%esi
f01036e0:	66 89 70 2a          	mov    %si,0x2a(%eax)
f01036e4:	89 f2                	mov    %esi,%edx
f01036e6:	c1 ea 10             	shr    $0x10,%edx
f01036e9:	88 50 2c             	mov    %dl,0x2c(%eax)
f01036ec:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f01036f0:	83 e2 f0             	and    $0xfffffff0,%edx
f01036f3:	83 ca 09             	or     $0x9,%edx
f01036f6:	83 e2 9f             	and    $0xffffff9f,%edx
f01036f9:	83 ca 80             	or     $0xffffff80,%edx
f01036fc:	88 55 f3             	mov    %dl,-0xd(%ebp)
f01036ff:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103702:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103706:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103709:	83 c9 40             	or     $0x40,%ecx
f010370c:	83 e1 7f             	and    $0x7f,%ecx
f010370f:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103712:	c1 ee 18             	shr    $0x18,%esi
f0103715:	89 f1                	mov    %esi,%ecx
f0103717:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010371a:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f010371e:	83 e2 ef             	and    $0xffffffef,%edx
f0103721:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103724:	b8 28 00 00 00       	mov    $0x28,%eax
f0103729:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f010372c:	8d 83 e8 1f 00 00    	lea    0x1fe8(%ebx),%eax
f0103732:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103735:	83 c4 04             	add    $0x4,%esp
f0103738:	5b                   	pop    %ebx
f0103739:	5e                   	pop    %esi
f010373a:	5f                   	pop    %edi
f010373b:	5d                   	pop    %ebp
f010373c:	c3                   	ret    

f010373d <trap_init>:
{
f010373d:	55                   	push   %ebp
f010373e:	89 e5                	mov    %esp,%ebp
	trap_init_percpu();
f0103740:	e8 59 ff ff ff       	call   f010369e <trap_init_percpu>
}
f0103745:	5d                   	pop    %ebp
f0103746:	c3                   	ret    

f0103747 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103747:	55                   	push   %ebp
f0103748:	89 e5                	mov    %esp,%ebp
f010374a:	56                   	push   %esi
f010374b:	53                   	push   %ebx
f010374c:	e8 16 ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103751:	81 c3 cf 78 08 00    	add    $0x878cf,%ebx
f0103757:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010375a:	83 ec 08             	sub    $0x8,%esp
f010375d:	ff 36                	pushl  (%esi)
f010375f:	8d 83 1c ac f7 ff    	lea    -0x853e4(%ebx),%eax
f0103765:	50                   	push   %eax
f0103766:	e8 1f ff ff ff       	call   f010368a <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010376b:	83 c4 08             	add    $0x8,%esp
f010376e:	ff 76 04             	pushl  0x4(%esi)
f0103771:	8d 83 2b ac f7 ff    	lea    -0x853d5(%ebx),%eax
f0103777:	50                   	push   %eax
f0103778:	e8 0d ff ff ff       	call   f010368a <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010377d:	83 c4 08             	add    $0x8,%esp
f0103780:	ff 76 08             	pushl  0x8(%esi)
f0103783:	8d 83 3a ac f7 ff    	lea    -0x853c6(%ebx),%eax
f0103789:	50                   	push   %eax
f010378a:	e8 fb fe ff ff       	call   f010368a <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010378f:	83 c4 08             	add    $0x8,%esp
f0103792:	ff 76 0c             	pushl  0xc(%esi)
f0103795:	8d 83 49 ac f7 ff    	lea    -0x853b7(%ebx),%eax
f010379b:	50                   	push   %eax
f010379c:	e8 e9 fe ff ff       	call   f010368a <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01037a1:	83 c4 08             	add    $0x8,%esp
f01037a4:	ff 76 10             	pushl  0x10(%esi)
f01037a7:	8d 83 58 ac f7 ff    	lea    -0x853a8(%ebx),%eax
f01037ad:	50                   	push   %eax
f01037ae:	e8 d7 fe ff ff       	call   f010368a <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01037b3:	83 c4 08             	add    $0x8,%esp
f01037b6:	ff 76 14             	pushl  0x14(%esi)
f01037b9:	8d 83 67 ac f7 ff    	lea    -0x85399(%ebx),%eax
f01037bf:	50                   	push   %eax
f01037c0:	e8 c5 fe ff ff       	call   f010368a <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01037c5:	83 c4 08             	add    $0x8,%esp
f01037c8:	ff 76 18             	pushl  0x18(%esi)
f01037cb:	8d 83 76 ac f7 ff    	lea    -0x8538a(%ebx),%eax
f01037d1:	50                   	push   %eax
f01037d2:	e8 b3 fe ff ff       	call   f010368a <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01037d7:	83 c4 08             	add    $0x8,%esp
f01037da:	ff 76 1c             	pushl  0x1c(%esi)
f01037dd:	8d 83 85 ac f7 ff    	lea    -0x8537b(%ebx),%eax
f01037e3:	50                   	push   %eax
f01037e4:	e8 a1 fe ff ff       	call   f010368a <cprintf>
}
f01037e9:	83 c4 10             	add    $0x10,%esp
f01037ec:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01037ef:	5b                   	pop    %ebx
f01037f0:	5e                   	pop    %esi
f01037f1:	5d                   	pop    %ebp
f01037f2:	c3                   	ret    

f01037f3 <print_trapframe>:
{
f01037f3:	55                   	push   %ebp
f01037f4:	89 e5                	mov    %esp,%ebp
f01037f6:	57                   	push   %edi
f01037f7:	56                   	push   %esi
f01037f8:	53                   	push   %ebx
f01037f9:	83 ec 14             	sub    $0x14,%esp
f01037fc:	e8 66 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103801:	81 c3 1f 78 08 00    	add    $0x8781f,%ebx
f0103807:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f010380a:	56                   	push   %esi
f010380b:	8d 83 bb ad f7 ff    	lea    -0x85245(%ebx),%eax
f0103811:	50                   	push   %eax
f0103812:	e8 73 fe ff ff       	call   f010368a <cprintf>
	print_regs(&tf->tf_regs);
f0103817:	89 34 24             	mov    %esi,(%esp)
f010381a:	e8 28 ff ff ff       	call   f0103747 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010381f:	83 c4 08             	add    $0x8,%esp
f0103822:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103826:	50                   	push   %eax
f0103827:	8d 83 d6 ac f7 ff    	lea    -0x8532a(%ebx),%eax
f010382d:	50                   	push   %eax
f010382e:	e8 57 fe ff ff       	call   f010368a <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103833:	83 c4 08             	add    $0x8,%esp
f0103836:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f010383a:	50                   	push   %eax
f010383b:	8d 83 e9 ac f7 ff    	lea    -0x85317(%ebx),%eax
f0103841:	50                   	push   %eax
f0103842:	e8 43 fe ff ff       	call   f010368a <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103847:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f010384a:	83 c4 10             	add    $0x10,%esp
f010384d:	83 fa 13             	cmp    $0x13,%edx
f0103850:	0f 86 e9 00 00 00    	jbe    f010393f <print_trapframe+0x14c>
	return "(unknown trap)";
f0103856:	83 fa 30             	cmp    $0x30,%edx
f0103859:	8d 83 94 ac f7 ff    	lea    -0x8536c(%ebx),%eax
f010385f:	8d 8b a0 ac f7 ff    	lea    -0x85360(%ebx),%ecx
f0103865:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103868:	83 ec 04             	sub    $0x4,%esp
f010386b:	50                   	push   %eax
f010386c:	52                   	push   %edx
f010386d:	8d 83 fc ac f7 ff    	lea    -0x85304(%ebx),%eax
f0103873:	50                   	push   %eax
f0103874:	e8 11 fe ff ff       	call   f010368a <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103879:	83 c4 10             	add    $0x10,%esp
f010387c:	39 b3 40 2b 00 00    	cmp    %esi,0x2b40(%ebx)
f0103882:	0f 84 c3 00 00 00    	je     f010394b <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
f0103888:	83 ec 08             	sub    $0x8,%esp
f010388b:	ff 76 2c             	pushl  0x2c(%esi)
f010388e:	8d 83 1d ad f7 ff    	lea    -0x852e3(%ebx),%eax
f0103894:	50                   	push   %eax
f0103895:	e8 f0 fd ff ff       	call   f010368a <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f010389a:	83 c4 10             	add    $0x10,%esp
f010389d:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01038a1:	0f 85 c9 00 00 00    	jne    f0103970 <print_trapframe+0x17d>
			tf->tf_err & 1 ? "protection" : "not-present");
f01038a7:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f01038aa:	89 c2                	mov    %eax,%edx
f01038ac:	83 e2 01             	and    $0x1,%edx
f01038af:	8d 8b af ac f7 ff    	lea    -0x85351(%ebx),%ecx
f01038b5:	8d 93 ba ac f7 ff    	lea    -0x85346(%ebx),%edx
f01038bb:	0f 44 ca             	cmove  %edx,%ecx
f01038be:	89 c2                	mov    %eax,%edx
f01038c0:	83 e2 02             	and    $0x2,%edx
f01038c3:	8d 93 c6 ac f7 ff    	lea    -0x8533a(%ebx),%edx
f01038c9:	8d bb cc ac f7 ff    	lea    -0x85334(%ebx),%edi
f01038cf:	0f 44 d7             	cmove  %edi,%edx
f01038d2:	83 e0 04             	and    $0x4,%eax
f01038d5:	8d 83 d1 ac f7 ff    	lea    -0x8532f(%ebx),%eax
f01038db:	8d bb e6 ad f7 ff    	lea    -0x8521a(%ebx),%edi
f01038e1:	0f 44 c7             	cmove  %edi,%eax
f01038e4:	51                   	push   %ecx
f01038e5:	52                   	push   %edx
f01038e6:	50                   	push   %eax
f01038e7:	8d 83 2b ad f7 ff    	lea    -0x852d5(%ebx),%eax
f01038ed:	50                   	push   %eax
f01038ee:	e8 97 fd ff ff       	call   f010368a <cprintf>
f01038f3:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01038f6:	83 ec 08             	sub    $0x8,%esp
f01038f9:	ff 76 30             	pushl  0x30(%esi)
f01038fc:	8d 83 3a ad f7 ff    	lea    -0x852c6(%ebx),%eax
f0103902:	50                   	push   %eax
f0103903:	e8 82 fd ff ff       	call   f010368a <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103908:	83 c4 08             	add    $0x8,%esp
f010390b:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010390f:	50                   	push   %eax
f0103910:	8d 83 49 ad f7 ff    	lea    -0x852b7(%ebx),%eax
f0103916:	50                   	push   %eax
f0103917:	e8 6e fd ff ff       	call   f010368a <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010391c:	83 c4 08             	add    $0x8,%esp
f010391f:	ff 76 38             	pushl  0x38(%esi)
f0103922:	8d 83 5c ad f7 ff    	lea    -0x852a4(%ebx),%eax
f0103928:	50                   	push   %eax
f0103929:	e8 5c fd ff ff       	call   f010368a <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010392e:	83 c4 10             	add    $0x10,%esp
f0103931:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0103935:	75 50                	jne    f0103987 <print_trapframe+0x194>
}
f0103937:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010393a:	5b                   	pop    %ebx
f010393b:	5e                   	pop    %esi
f010393c:	5f                   	pop    %edi
f010393d:	5d                   	pop    %ebp
f010393e:	c3                   	ret    
		return excnames[trapno];
f010393f:	8b 84 93 60 20 00 00 	mov    0x2060(%ebx,%edx,4),%eax
f0103946:	e9 1d ff ff ff       	jmp    f0103868 <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010394b:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f010394f:	0f 85 33 ff ff ff    	jne    f0103888 <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103955:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103958:	83 ec 08             	sub    $0x8,%esp
f010395b:	50                   	push   %eax
f010395c:	8d 83 0e ad f7 ff    	lea    -0x852f2(%ebx),%eax
f0103962:	50                   	push   %eax
f0103963:	e8 22 fd ff ff       	call   f010368a <cprintf>
f0103968:	83 c4 10             	add    $0x10,%esp
f010396b:	e9 18 ff ff ff       	jmp    f0103888 <print_trapframe+0x95>
		cprintf("\n");
f0103970:	83 ec 0c             	sub    $0xc,%esp
f0103973:	8d 83 56 ab f7 ff    	lea    -0x854aa(%ebx),%eax
f0103979:	50                   	push   %eax
f010397a:	e8 0b fd ff ff       	call   f010368a <cprintf>
f010397f:	83 c4 10             	add    $0x10,%esp
f0103982:	e9 6f ff ff ff       	jmp    f01038f6 <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103987:	83 ec 08             	sub    $0x8,%esp
f010398a:	ff 76 3c             	pushl  0x3c(%esi)
f010398d:	8d 83 6b ad f7 ff    	lea    -0x85295(%ebx),%eax
f0103993:	50                   	push   %eax
f0103994:	e8 f1 fc ff ff       	call   f010368a <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103999:	83 c4 08             	add    $0x8,%esp
f010399c:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f01039a0:	50                   	push   %eax
f01039a1:	8d 83 7a ad f7 ff    	lea    -0x85286(%ebx),%eax
f01039a7:	50                   	push   %eax
f01039a8:	e8 dd fc ff ff       	call   f010368a <cprintf>
f01039ad:	83 c4 10             	add    $0x10,%esp
}
f01039b0:	eb 85                	jmp    f0103937 <print_trapframe+0x144>

f01039b2 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01039b2:	55                   	push   %ebp
f01039b3:	89 e5                	mov    %esp,%ebp
f01039b5:	57                   	push   %edi
f01039b6:	56                   	push   %esi
f01039b7:	53                   	push   %ebx
f01039b8:	83 ec 0c             	sub    $0xc,%esp
f01039bb:	e8 a7 c7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01039c0:	81 c3 60 76 08 00    	add    $0x87660,%ebx
f01039c6:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01039c9:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01039ca:	9c                   	pushf  
f01039cb:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01039cc:	f6 c4 02             	test   $0x2,%ah
f01039cf:	74 1f                	je     f01039f0 <trap+0x3e>
f01039d1:	8d 83 8d ad f7 ff    	lea    -0x85273(%ebx),%eax
f01039d7:	50                   	push   %eax
f01039d8:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f01039de:	50                   	push   %eax
f01039df:	68 a8 00 00 00       	push   $0xa8
f01039e4:	8d 83 a6 ad f7 ff    	lea    -0x8525a(%ebx),%eax
f01039ea:	50                   	push   %eax
f01039eb:	e8 c1 c6 ff ff       	call   f01000b1 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01039f0:	83 ec 08             	sub    $0x8,%esp
f01039f3:	56                   	push   %esi
f01039f4:	8d 83 b2 ad f7 ff    	lea    -0x8524e(%ebx),%eax
f01039fa:	50                   	push   %eax
f01039fb:	e8 8a fc ff ff       	call   f010368a <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103a00:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103a04:	83 e0 03             	and    $0x3,%eax
f0103a07:	83 c4 10             	add    $0x10,%esp
f0103a0a:	66 83 f8 03          	cmp    $0x3,%ax
f0103a0e:	75 1d                	jne    f0103a2d <trap+0x7b>
		// Trapped from user mode.
		assert(curenv);
f0103a10:	c7 c0 40 d3 18 f0    	mov    $0xf018d340,%eax
f0103a16:	8b 00                	mov    (%eax),%eax
f0103a18:	85 c0                	test   %eax,%eax
f0103a1a:	74 68                	je     f0103a84 <trap+0xd2>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103a1c:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103a21:	89 c7                	mov    %eax,%edi
f0103a23:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103a25:	c7 c0 40 d3 18 f0    	mov    $0xf018d340,%eax
f0103a2b:	8b 30                	mov    (%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103a2d:	89 b3 40 2b 00 00    	mov    %esi,0x2b40(%ebx)
	print_trapframe(tf);
f0103a33:	83 ec 0c             	sub    $0xc,%esp
f0103a36:	56                   	push   %esi
f0103a37:	e8 b7 fd ff ff       	call   f01037f3 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103a3c:	83 c4 10             	add    $0x10,%esp
f0103a3f:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103a44:	74 5d                	je     f0103aa3 <trap+0xf1>
		env_destroy(curenv);
f0103a46:	83 ec 0c             	sub    $0xc,%esp
f0103a49:	c7 c6 40 d3 18 f0    	mov    $0xf018d340,%esi
f0103a4f:	ff 36                	pushl  (%esi)
f0103a51:	e8 15 fb ff ff       	call   f010356b <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103a56:	8b 06                	mov    (%esi),%eax
f0103a58:	83 c4 10             	add    $0x10,%esp
f0103a5b:	85 c0                	test   %eax,%eax
f0103a5d:	74 06                	je     f0103a65 <trap+0xb3>
f0103a5f:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103a63:	74 59                	je     f0103abe <trap+0x10c>
f0103a65:	8d 83 30 af f7 ff    	lea    -0x850d0(%ebx),%eax
f0103a6b:	50                   	push   %eax
f0103a6c:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0103a72:	50                   	push   %eax
f0103a73:	68 c0 00 00 00       	push   $0xc0
f0103a78:	8d 83 a6 ad f7 ff    	lea    -0x8525a(%ebx),%eax
f0103a7e:	50                   	push   %eax
f0103a7f:	e8 2d c6 ff ff       	call   f01000b1 <_panic>
		assert(curenv);
f0103a84:	8d 83 cd ad f7 ff    	lea    -0x85233(%ebx),%eax
f0103a8a:	50                   	push   %eax
f0103a8b:	8d 83 cb a8 f7 ff    	lea    -0x85735(%ebx),%eax
f0103a91:	50                   	push   %eax
f0103a92:	68 ae 00 00 00       	push   $0xae
f0103a97:	8d 83 a6 ad f7 ff    	lea    -0x8525a(%ebx),%eax
f0103a9d:	50                   	push   %eax
f0103a9e:	e8 0e c6 ff ff       	call   f01000b1 <_panic>
		panic("unhandled trap in kernel");
f0103aa3:	83 ec 04             	sub    $0x4,%esp
f0103aa6:	8d 83 d4 ad f7 ff    	lea    -0x8522c(%ebx),%eax
f0103aac:	50                   	push   %eax
f0103aad:	68 97 00 00 00       	push   $0x97
f0103ab2:	8d 83 a6 ad f7 ff    	lea    -0x8525a(%ebx),%eax
f0103ab8:	50                   	push   %eax
f0103ab9:	e8 f3 c5 ff ff       	call   f01000b1 <_panic>
	env_run(curenv);
f0103abe:	83 ec 0c             	sub    $0xc,%esp
f0103ac1:	50                   	push   %eax
f0103ac2:	e8 12 fb ff ff       	call   f01035d9 <env_run>

f0103ac7 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103ac7:	55                   	push   %ebp
f0103ac8:	89 e5                	mov    %esp,%ebp
f0103aca:	57                   	push   %edi
f0103acb:	56                   	push   %esi
f0103acc:	53                   	push   %ebx
f0103acd:	83 ec 0c             	sub    $0xc,%esp
f0103ad0:	e8 92 c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103ad5:	81 c3 4b 75 08 00    	add    $0x8754b,%ebx
f0103adb:	8b 7d 08             	mov    0x8(%ebp),%edi
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103ade:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ae1:	ff 77 30             	pushl  0x30(%edi)
f0103ae4:	50                   	push   %eax
f0103ae5:	c7 c6 40 d3 18 f0    	mov    $0xf018d340,%esi
f0103aeb:	8b 06                	mov    (%esi),%eax
f0103aed:	ff 70 48             	pushl  0x48(%eax)
f0103af0:	8d 83 5c af f7 ff    	lea    -0x850a4(%ebx),%eax
f0103af6:	50                   	push   %eax
f0103af7:	e8 8e fb ff ff       	call   f010368a <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103afc:	89 3c 24             	mov    %edi,(%esp)
f0103aff:	e8 ef fc ff ff       	call   f01037f3 <print_trapframe>
	env_destroy(curenv);
f0103b04:	83 c4 04             	add    $0x4,%esp
f0103b07:	ff 36                	pushl  (%esi)
f0103b09:	e8 5d fa ff ff       	call   f010356b <env_destroy>
}
f0103b0e:	83 c4 10             	add    $0x10,%esp
f0103b11:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b14:	5b                   	pop    %ebx
f0103b15:	5e                   	pop    %esi
f0103b16:	5f                   	pop    %edi
f0103b17:	5d                   	pop    %ebp
f0103b18:	c3                   	ret    

f0103b19 <syscall>:
f0103b19:	55                   	push   %ebp
f0103b1a:	89 e5                	mov    %esp,%ebp
f0103b1c:	53                   	push   %ebx
f0103b1d:	83 ec 08             	sub    $0x8,%esp
f0103b20:	e8 42 c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b25:	81 c3 fb 74 08 00    	add    $0x874fb,%ebx
f0103b2b:	8d 83 80 af f7 ff    	lea    -0x85080(%ebx),%eax
f0103b31:	50                   	push   %eax
f0103b32:	6a 49                	push   $0x49
f0103b34:	8d 83 98 af f7 ff    	lea    -0x85068(%ebx),%eax
f0103b3a:	50                   	push   %eax
f0103b3b:	e8 71 c5 ff ff       	call   f01000b1 <_panic>

f0103b40 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103b40:	55                   	push   %ebp
f0103b41:	89 e5                	mov    %esp,%ebp
f0103b43:	57                   	push   %edi
f0103b44:	56                   	push   %esi
f0103b45:	53                   	push   %ebx
f0103b46:	83 ec 14             	sub    $0x14,%esp
f0103b49:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103b4c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103b4f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b52:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103b55:	8b 32                	mov    (%edx),%esi
f0103b57:	8b 01                	mov    (%ecx),%eax
f0103b59:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103b5c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103b63:	eb 2f                	jmp    f0103b94 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103b65:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103b68:	39 c6                	cmp    %eax,%esi
f0103b6a:	7f 49                	jg     f0103bb5 <stab_binsearch+0x75>
f0103b6c:	0f b6 0a             	movzbl (%edx),%ecx
f0103b6f:	83 ea 0c             	sub    $0xc,%edx
f0103b72:	39 f9                	cmp    %edi,%ecx
f0103b74:	75 ef                	jne    f0103b65 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103b76:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103b79:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103b7c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103b80:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103b83:	73 35                	jae    f0103bba <stab_binsearch+0x7a>
			*region_left = m;
f0103b85:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103b88:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0103b8a:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0103b8d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103b94:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103b97:	7f 4e                	jg     f0103be7 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0103b99:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103b9c:	01 f0                	add    %esi,%eax
f0103b9e:	89 c3                	mov    %eax,%ebx
f0103ba0:	c1 eb 1f             	shr    $0x1f,%ebx
f0103ba3:	01 c3                	add    %eax,%ebx
f0103ba5:	d1 fb                	sar    %ebx
f0103ba7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103baa:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103bad:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103bb1:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0103bb3:	eb b3                	jmp    f0103b68 <stab_binsearch+0x28>
			l = true_m + 1;
f0103bb5:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103bb8:	eb da                	jmp    f0103b94 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0103bba:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103bbd:	76 14                	jbe    f0103bd3 <stab_binsearch+0x93>
			*region_right = m - 1;
f0103bbf:	83 e8 01             	sub    $0x1,%eax
f0103bc2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103bc5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103bc8:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103bca:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103bd1:	eb c1                	jmp    f0103b94 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103bd3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103bd6:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103bd8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103bdc:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0103bde:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103be5:	eb ad                	jmp    f0103b94 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103be7:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103beb:	74 16                	je     f0103c03 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103bed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bf0:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103bf2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103bf5:	8b 0e                	mov    (%esi),%ecx
f0103bf7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103bfa:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103bfd:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0103c01:	eb 12                	jmp    f0103c15 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103c03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103c06:	8b 00                	mov    (%eax),%eax
f0103c08:	83 e8 01             	sub    $0x1,%eax
f0103c0b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103c0e:	89 07                	mov    %eax,(%edi)
f0103c10:	eb 16                	jmp    f0103c28 <stab_binsearch+0xe8>
		     l--)
f0103c12:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103c15:	39 c1                	cmp    %eax,%ecx
f0103c17:	7d 0a                	jge    f0103c23 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103c19:	0f b6 1a             	movzbl (%edx),%ebx
f0103c1c:	83 ea 0c             	sub    $0xc,%edx
f0103c1f:	39 fb                	cmp    %edi,%ebx
f0103c21:	75 ef                	jne    f0103c12 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103c23:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c26:	89 07                	mov    %eax,(%edi)
	}
}
f0103c28:	83 c4 14             	add    $0x14,%esp
f0103c2b:	5b                   	pop    %ebx
f0103c2c:	5e                   	pop    %esi
f0103c2d:	5f                   	pop    %edi
f0103c2e:	5d                   	pop    %ebp
f0103c2f:	c3                   	ret    

f0103c30 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103c30:	55                   	push   %ebp
f0103c31:	89 e5                	mov    %esp,%ebp
f0103c33:	57                   	push   %edi
f0103c34:	56                   	push   %esi
f0103c35:	53                   	push   %ebx
f0103c36:	83 ec 4c             	sub    $0x4c,%esp
f0103c39:	e8 1d f5 ff ff       	call   f010315b <__x86.get_pc_thunk.di>
f0103c3e:	81 c7 e2 73 08 00    	add    $0x873e2,%edi
f0103c44:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103c47:	8d 87 a7 af f7 ff    	lea    -0x85059(%edi),%eax
f0103c4d:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0103c4f:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103c56:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103c59:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103c60:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c63:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f0103c66:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103c6d:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0103c72:	0f 87 2c 01 00 00    	ja     f0103da4 <debuginfo_eip+0x174>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103c78:	a1 00 00 20 00       	mov    0x200000,%eax
f0103c7d:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = usd->stab_end;
f0103c80:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103c85:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0103c8b:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f0103c8e:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f0103c94:	89 5d bc             	mov    %ebx,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103c97:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103c9a:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f0103c9d:	0f 83 e9 01 00 00    	jae    f0103e8c <debuginfo_eip+0x25c>
f0103ca3:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0103ca7:	0f 85 e6 01 00 00    	jne    f0103e93 <debuginfo_eip+0x263>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103cad:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103cb4:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f0103cb7:	29 d8                	sub    %ebx,%eax
f0103cb9:	c1 f8 02             	sar    $0x2,%eax
f0103cbc:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103cc2:	83 e8 01             	sub    $0x1,%eax
f0103cc5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103cc8:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103ccb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103cce:	ff 75 08             	pushl  0x8(%ebp)
f0103cd1:	6a 64                	push   $0x64
f0103cd3:	89 d8                	mov    %ebx,%eax
f0103cd5:	e8 66 fe ff ff       	call   f0103b40 <stab_binsearch>
	if (lfile == 0)
f0103cda:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103cdd:	83 c4 08             	add    $0x8,%esp
f0103ce0:	85 c0                	test   %eax,%eax
f0103ce2:	0f 84 b2 01 00 00    	je     f0103e9a <debuginfo_eip+0x26a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103ce8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103ceb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103cee:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103cf1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103cf4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103cf7:	ff 75 08             	pushl  0x8(%ebp)
f0103cfa:	6a 24                	push   $0x24
f0103cfc:	89 d8                	mov    %ebx,%eax
f0103cfe:	e8 3d fe ff ff       	call   f0103b40 <stab_binsearch>

	if (lfun <= rfun) {
f0103d03:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103d06:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103d09:	83 c4 08             	add    $0x8,%esp
f0103d0c:	39 d0                	cmp    %edx,%eax
f0103d0e:	0f 8f b6 00 00 00    	jg     f0103dca <debuginfo_eip+0x19a>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103d14:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0103d17:	8d 1c 8b             	lea    (%ebx,%ecx,4),%ebx
f0103d1a:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f0103d1d:	8b 0b                	mov    (%ebx),%ecx
f0103d1f:	89 cb                	mov    %ecx,%ebx
f0103d21:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103d24:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f0103d27:	39 cb                	cmp    %ecx,%ebx
f0103d29:	73 06                	jae    f0103d31 <debuginfo_eip+0x101>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103d2b:	03 5d b4             	add    -0x4c(%ebp),%ebx
f0103d2e:	89 5e 08             	mov    %ebx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103d31:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103d34:	8b 4b 08             	mov    0x8(%ebx),%ecx
f0103d37:	89 4e 10             	mov    %ecx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103d3a:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0103d3d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103d40:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103d43:	83 ec 08             	sub    $0x8,%esp
f0103d46:	6a 3a                	push   $0x3a
f0103d48:	ff 76 08             	pushl  0x8(%esi)
f0103d4b:	89 fb                	mov    %edi,%ebx
f0103d4d:	e8 cc 09 00 00       	call   f010471e <strfind>
f0103d52:	2b 46 08             	sub    0x8(%esi),%eax
f0103d55:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103d58:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103d5b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103d5e:	83 c4 08             	add    $0x8,%esp
f0103d61:	ff 75 08             	pushl  0x8(%ebp)
f0103d64:	6a 44                	push   $0x44
f0103d66:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103d69:	89 f8                	mov    %edi,%eax
f0103d6b:	e8 d0 fd ff ff       	call   f0103b40 <stab_binsearch>
	if(lline<=rline){
f0103d70:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103d73:	83 c4 10             	add    $0x10,%esp
f0103d76:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103d79:	0f 8f 22 01 00 00    	jg     f0103ea1 <debuginfo_eip+0x271>
		info->eip_line = stabs[lline].n_desc;
f0103d7f:	89 d0                	mov    %edx,%eax
f0103d81:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103d84:	c1 e2 02             	shl    $0x2,%edx
f0103d87:	0f b7 4c 17 06       	movzwl 0x6(%edi,%edx,1),%ecx
f0103d8c:	89 4e 04             	mov    %ecx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103d8f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103d92:	8d 54 17 04          	lea    0x4(%edi,%edx,1),%edx
f0103d96:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103d9a:	bf 01 00 00 00       	mov    $0x1,%edi
f0103d9f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103da2:	eb 48                	jmp    f0103dec <debuginfo_eip+0x1bc>
		stabstr_end = __STABSTR_END__;
f0103da4:	c7 c0 78 0c 11 f0    	mov    $0xf0110c78,%eax
f0103daa:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0103dad:	c7 c0 89 e2 10 f0    	mov    $0xf010e289,%eax
f0103db3:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stab_end = __STAB_END__;
f0103db6:	c7 c0 88 e2 10 f0    	mov    $0xf010e288,%eax
		stabs = __STAB_BEGIN__;
f0103dbc:	c7 c3 c4 61 10 f0    	mov    $0xf01061c4,%ebx
f0103dc2:	89 5d b8             	mov    %ebx,-0x48(%ebp)
f0103dc5:	e9 cd fe ff ff       	jmp    f0103c97 <debuginfo_eip+0x67>
		info->eip_fn_addr = addr;
f0103dca:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dcd:	89 46 10             	mov    %eax,0x10(%esi)
		lline = lfile;
f0103dd0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103dd3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103dd6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103dd9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ddc:	e9 62 ff ff ff       	jmp    f0103d43 <debuginfo_eip+0x113>
f0103de1:	83 e8 01             	sub    $0x1,%eax
f0103de4:	83 ea 0c             	sub    $0xc,%edx
f0103de7:	89 f9                	mov    %edi,%ecx
f0103de9:	88 4d c4             	mov    %cl,-0x3c(%ebp)
f0103dec:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0103def:	39 c3                	cmp    %eax,%ebx
f0103df1:	7f 24                	jg     f0103e17 <debuginfo_eip+0x1e7>
	       && stabs[lline].n_type != N_SOL
f0103df3:	0f b6 0a             	movzbl (%edx),%ecx
f0103df6:	80 f9 84             	cmp    $0x84,%cl
f0103df9:	74 46                	je     f0103e41 <debuginfo_eip+0x211>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103dfb:	80 f9 64             	cmp    $0x64,%cl
f0103dfe:	75 e1                	jne    f0103de1 <debuginfo_eip+0x1b1>
f0103e00:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0103e04:	74 db                	je     f0103de1 <debuginfo_eip+0x1b1>
f0103e06:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e09:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103e0d:	74 3b                	je     f0103e4a <debuginfo_eip+0x21a>
f0103e0f:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103e12:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e15:	eb 33                	jmp    f0103e4a <debuginfo_eip+0x21a>
f0103e17:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103e1a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103e1d:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103e20:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103e25:	39 da                	cmp    %ebx,%edx
f0103e27:	0f 8d 80 00 00 00    	jge    f0103ead <debuginfo_eip+0x27d>
		for (lline = lfun + 1;
f0103e2d:	83 c2 01             	add    $0x1,%edx
f0103e30:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103e33:	89 d0                	mov    %edx,%eax
f0103e35:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103e38:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103e3b:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0103e3f:	eb 32                	jmp    f0103e73 <debuginfo_eip+0x243>
f0103e41:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e44:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103e48:	75 1d                	jne    f0103e67 <debuginfo_eip+0x237>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103e4a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103e4d:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103e50:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103e53:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103e56:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f0103e59:	29 f8                	sub    %edi,%eax
f0103e5b:	39 c2                	cmp    %eax,%edx
f0103e5d:	73 bb                	jae    f0103e1a <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103e5f:	89 f8                	mov    %edi,%eax
f0103e61:	01 d0                	add    %edx,%eax
f0103e63:	89 06                	mov    %eax,(%esi)
f0103e65:	eb b3                	jmp    f0103e1a <debuginfo_eip+0x1ea>
f0103e67:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103e6a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e6d:	eb db                	jmp    f0103e4a <debuginfo_eip+0x21a>
			info->eip_fn_narg++;
f0103e6f:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0103e73:	39 c3                	cmp    %eax,%ebx
f0103e75:	7e 31                	jle    f0103ea8 <debuginfo_eip+0x278>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103e77:	0f b6 0a             	movzbl (%edx),%ecx
f0103e7a:	83 c0 01             	add    $0x1,%eax
f0103e7d:	83 c2 0c             	add    $0xc,%edx
f0103e80:	80 f9 a0             	cmp    $0xa0,%cl
f0103e83:	74 ea                	je     f0103e6f <debuginfo_eip+0x23f>
	return 0;
f0103e85:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e8a:	eb 21                	jmp    f0103ead <debuginfo_eip+0x27d>
		return -1;
f0103e8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103e91:	eb 1a                	jmp    f0103ead <debuginfo_eip+0x27d>
f0103e93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103e98:	eb 13                	jmp    f0103ead <debuginfo_eip+0x27d>
		return -1;
f0103e9a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103e9f:	eb 0c                	jmp    f0103ead <debuginfo_eip+0x27d>
		return -1;
f0103ea1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ea6:	eb 05                	jmp    f0103ead <debuginfo_eip+0x27d>
	return 0;
f0103ea8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ead:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103eb0:	5b                   	pop    %ebx
f0103eb1:	5e                   	pop    %esi
f0103eb2:	5f                   	pop    %edi
f0103eb3:	5d                   	pop    %ebp
f0103eb4:	c3                   	ret    

f0103eb5 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103eb5:	55                   	push   %ebp
f0103eb6:	89 e5                	mov    %esp,%ebp
f0103eb8:	57                   	push   %edi
f0103eb9:	56                   	push   %esi
f0103eba:	53                   	push   %ebx
f0103ebb:	83 ec 2c             	sub    $0x2c,%esp
f0103ebe:	e8 90 f2 ff ff       	call   f0103153 <__x86.get_pc_thunk.cx>
f0103ec3:	81 c1 5d 71 08 00    	add    $0x8715d,%ecx
f0103ec9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103ecc:	89 c7                	mov    %eax,%edi
f0103ece:	89 d6                	mov    %edx,%esi
f0103ed0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ed3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ed6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ed9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103edc:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103edf:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103ee4:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0103ee7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0103eea:	39 d3                	cmp    %edx,%ebx
f0103eec:	72 09                	jb     f0103ef7 <printnum+0x42>
f0103eee:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103ef1:	0f 87 83 00 00 00    	ja     f0103f7a <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103ef7:	83 ec 0c             	sub    $0xc,%esp
f0103efa:	ff 75 18             	pushl  0x18(%ebp)
f0103efd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f00:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103f03:	53                   	push   %ebx
f0103f04:	ff 75 10             	pushl  0x10(%ebp)
f0103f07:	83 ec 08             	sub    $0x8,%esp
f0103f0a:	ff 75 dc             	pushl  -0x24(%ebp)
f0103f0d:	ff 75 d8             	pushl  -0x28(%ebp)
f0103f10:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103f13:	ff 75 d0             	pushl  -0x30(%ebp)
f0103f16:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103f19:	e8 22 0a 00 00       	call   f0104940 <__udivdi3>
f0103f1e:	83 c4 18             	add    $0x18,%esp
f0103f21:	52                   	push   %edx
f0103f22:	50                   	push   %eax
f0103f23:	89 f2                	mov    %esi,%edx
f0103f25:	89 f8                	mov    %edi,%eax
f0103f27:	e8 89 ff ff ff       	call   f0103eb5 <printnum>
f0103f2c:	83 c4 20             	add    $0x20,%esp
f0103f2f:	eb 13                	jmp    f0103f44 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103f31:	83 ec 08             	sub    $0x8,%esp
f0103f34:	56                   	push   %esi
f0103f35:	ff 75 18             	pushl  0x18(%ebp)
f0103f38:	ff d7                	call   *%edi
f0103f3a:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103f3d:	83 eb 01             	sub    $0x1,%ebx
f0103f40:	85 db                	test   %ebx,%ebx
f0103f42:	7f ed                	jg     f0103f31 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103f44:	83 ec 08             	sub    $0x8,%esp
f0103f47:	56                   	push   %esi
f0103f48:	83 ec 04             	sub    $0x4,%esp
f0103f4b:	ff 75 dc             	pushl  -0x24(%ebp)
f0103f4e:	ff 75 d8             	pushl  -0x28(%ebp)
f0103f51:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103f54:	ff 75 d0             	pushl  -0x30(%ebp)
f0103f57:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103f5a:	89 f3                	mov    %esi,%ebx
f0103f5c:	e8 ff 0a 00 00       	call   f0104a60 <__umoddi3>
f0103f61:	83 c4 14             	add    $0x14,%esp
f0103f64:	0f be 84 06 b1 af f7 	movsbl -0x8504f(%esi,%eax,1),%eax
f0103f6b:	ff 
f0103f6c:	50                   	push   %eax
f0103f6d:	ff d7                	call   *%edi
}
f0103f6f:	83 c4 10             	add    $0x10,%esp
f0103f72:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f75:	5b                   	pop    %ebx
f0103f76:	5e                   	pop    %esi
f0103f77:	5f                   	pop    %edi
f0103f78:	5d                   	pop    %ebp
f0103f79:	c3                   	ret    
f0103f7a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103f7d:	eb be                	jmp    f0103f3d <printnum+0x88>

f0103f7f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103f7f:	55                   	push   %ebp
f0103f80:	89 e5                	mov    %esp,%ebp
f0103f82:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103f85:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103f89:	8b 10                	mov    (%eax),%edx
f0103f8b:	3b 50 04             	cmp    0x4(%eax),%edx
f0103f8e:	73 0a                	jae    f0103f9a <sprintputch+0x1b>
		*b->buf++ = ch;
f0103f90:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103f93:	89 08                	mov    %ecx,(%eax)
f0103f95:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f98:	88 02                	mov    %al,(%edx)
}
f0103f9a:	5d                   	pop    %ebp
f0103f9b:	c3                   	ret    

f0103f9c <printfmt>:
{
f0103f9c:	55                   	push   %ebp
f0103f9d:	89 e5                	mov    %esp,%ebp
f0103f9f:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103fa2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103fa5:	50                   	push   %eax
f0103fa6:	ff 75 10             	pushl  0x10(%ebp)
f0103fa9:	ff 75 0c             	pushl  0xc(%ebp)
f0103fac:	ff 75 08             	pushl  0x8(%ebp)
f0103faf:	e8 05 00 00 00       	call   f0103fb9 <vprintfmt>
}
f0103fb4:	83 c4 10             	add    $0x10,%esp
f0103fb7:	c9                   	leave  
f0103fb8:	c3                   	ret    

f0103fb9 <vprintfmt>:
{
f0103fb9:	55                   	push   %ebp
f0103fba:	89 e5                	mov    %esp,%ebp
f0103fbc:	57                   	push   %edi
f0103fbd:	56                   	push   %esi
f0103fbe:	53                   	push   %ebx
f0103fbf:	83 ec 2c             	sub    $0x2c,%esp
f0103fc2:	e8 a0 c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103fc7:	81 c3 59 70 08 00    	add    $0x87059,%ebx
f0103fcd:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103fd0:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103fd3:	e9 c3 03 00 00       	jmp    f010439b <.L35+0x48>
		padc = ' ';
f0103fd8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0103fdc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103fe3:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0103fea:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103ff1:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ff6:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103ff9:	8d 47 01             	lea    0x1(%edi),%eax
f0103ffc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103fff:	0f b6 17             	movzbl (%edi),%edx
f0104002:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104005:	3c 55                	cmp    $0x55,%al
f0104007:	0f 87 16 04 00 00    	ja     f0104423 <.L22>
f010400d:	0f b6 c0             	movzbl %al,%eax
f0104010:	89 d9                	mov    %ebx,%ecx
f0104012:	03 8c 83 3c b0 f7 ff 	add    -0x84fc4(%ebx,%eax,4),%ecx
f0104019:	ff e1                	jmp    *%ecx

f010401b <.L69>:
f010401b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f010401e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0104022:	eb d5                	jmp    f0103ff9 <vprintfmt+0x40>

f0104024 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0104024:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0104027:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010402b:	eb cc                	jmp    f0103ff9 <vprintfmt+0x40>

f010402d <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f010402d:	0f b6 d2             	movzbl %dl,%edx
f0104030:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0104033:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0104038:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010403b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010403f:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104042:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104045:	83 f9 09             	cmp    $0x9,%ecx
f0104048:	77 55                	ja     f010409f <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010404a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010404d:	eb e9                	jmp    f0104038 <.L29+0xb>

f010404f <.L26>:
			precision = va_arg(ap, int);
f010404f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104052:	8b 00                	mov    (%eax),%eax
f0104054:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104057:	8b 45 14             	mov    0x14(%ebp),%eax
f010405a:	8d 40 04             	lea    0x4(%eax),%eax
f010405d:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104060:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0104063:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104067:	79 90                	jns    f0103ff9 <vprintfmt+0x40>
				width = precision, precision = -1;
f0104069:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010406c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010406f:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0104076:	eb 81                	jmp    f0103ff9 <vprintfmt+0x40>

f0104078 <.L27>:
f0104078:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010407b:	85 c0                	test   %eax,%eax
f010407d:	ba 00 00 00 00       	mov    $0x0,%edx
f0104082:	0f 49 d0             	cmovns %eax,%edx
f0104085:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104088:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010408b:	e9 69 ff ff ff       	jmp    f0103ff9 <vprintfmt+0x40>

f0104090 <.L23>:
f0104090:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104093:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010409a:	e9 5a ff ff ff       	jmp    f0103ff9 <vprintfmt+0x40>
f010409f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01040a2:	eb bf                	jmp    f0104063 <.L26+0x14>

f01040a4 <.L33>:
			lflag++;
f01040a4:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01040a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01040ab:	e9 49 ff ff ff       	jmp    f0103ff9 <vprintfmt+0x40>

f01040b0 <.L30>:
			putch(va_arg(ap, int), putdat);
f01040b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01040b3:	8d 78 04             	lea    0x4(%eax),%edi
f01040b6:	83 ec 08             	sub    $0x8,%esp
f01040b9:	56                   	push   %esi
f01040ba:	ff 30                	pushl  (%eax)
f01040bc:	ff 55 08             	call   *0x8(%ebp)
			break;
f01040bf:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01040c2:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01040c5:	e9 ce 02 00 00       	jmp    f0104398 <.L35+0x45>

f01040ca <.L32>:
			err = va_arg(ap, int);
f01040ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01040cd:	8d 78 04             	lea    0x4(%eax),%edi
f01040d0:	8b 00                	mov    (%eax),%eax
f01040d2:	99                   	cltd   
f01040d3:	31 d0                	xor    %edx,%eax
f01040d5:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01040d7:	83 f8 06             	cmp    $0x6,%eax
f01040da:	7f 27                	jg     f0104103 <.L32+0x39>
f01040dc:	8b 94 83 b0 20 00 00 	mov    0x20b0(%ebx,%eax,4),%edx
f01040e3:	85 d2                	test   %edx,%edx
f01040e5:	74 1c                	je     f0104103 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01040e7:	52                   	push   %edx
f01040e8:	8d 83 dd a8 f7 ff    	lea    -0x85723(%ebx),%eax
f01040ee:	50                   	push   %eax
f01040ef:	56                   	push   %esi
f01040f0:	ff 75 08             	pushl  0x8(%ebp)
f01040f3:	e8 a4 fe ff ff       	call   f0103f9c <printfmt>
f01040f8:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01040fb:	89 7d 14             	mov    %edi,0x14(%ebp)
f01040fe:	e9 95 02 00 00       	jmp    f0104398 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0104103:	50                   	push   %eax
f0104104:	8d 83 c9 af f7 ff    	lea    -0x85037(%ebx),%eax
f010410a:	50                   	push   %eax
f010410b:	56                   	push   %esi
f010410c:	ff 75 08             	pushl  0x8(%ebp)
f010410f:	e8 88 fe ff ff       	call   f0103f9c <printfmt>
f0104114:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104117:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010411a:	e9 79 02 00 00       	jmp    f0104398 <.L35+0x45>

f010411f <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f010411f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104122:	83 c0 04             	add    $0x4,%eax
f0104125:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104128:	8b 45 14             	mov    0x14(%ebp),%eax
f010412b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010412d:	85 ff                	test   %edi,%edi
f010412f:	8d 83 c2 af f7 ff    	lea    -0x8503e(%ebx),%eax
f0104135:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104138:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010413c:	0f 8e b5 00 00 00    	jle    f01041f7 <.L36+0xd8>
f0104142:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104146:	75 08                	jne    f0104150 <.L36+0x31>
f0104148:	89 75 0c             	mov    %esi,0xc(%ebp)
f010414b:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010414e:	eb 6d                	jmp    f01041bd <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104150:	83 ec 08             	sub    $0x8,%esp
f0104153:	ff 75 cc             	pushl  -0x34(%ebp)
f0104156:	57                   	push   %edi
f0104157:	e8 7e 04 00 00       	call   f01045da <strnlen>
f010415c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010415f:	29 c2                	sub    %eax,%edx
f0104161:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0104164:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104167:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010416b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010416e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104171:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104173:	eb 10                	jmp    f0104185 <.L36+0x66>
					putch(padc, putdat);
f0104175:	83 ec 08             	sub    $0x8,%esp
f0104178:	56                   	push   %esi
f0104179:	ff 75 e0             	pushl  -0x20(%ebp)
f010417c:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010417f:	83 ef 01             	sub    $0x1,%edi
f0104182:	83 c4 10             	add    $0x10,%esp
f0104185:	85 ff                	test   %edi,%edi
f0104187:	7f ec                	jg     f0104175 <.L36+0x56>
f0104189:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010418c:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010418f:	85 d2                	test   %edx,%edx
f0104191:	b8 00 00 00 00       	mov    $0x0,%eax
f0104196:	0f 49 c2             	cmovns %edx,%eax
f0104199:	29 c2                	sub    %eax,%edx
f010419b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010419e:	89 75 0c             	mov    %esi,0xc(%ebp)
f01041a1:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01041a4:	eb 17                	jmp    f01041bd <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01041a6:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01041aa:	75 30                	jne    f01041dc <.L36+0xbd>
					putch(ch, putdat);
f01041ac:	83 ec 08             	sub    $0x8,%esp
f01041af:	ff 75 0c             	pushl  0xc(%ebp)
f01041b2:	50                   	push   %eax
f01041b3:	ff 55 08             	call   *0x8(%ebp)
f01041b6:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01041b9:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01041bd:	83 c7 01             	add    $0x1,%edi
f01041c0:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01041c4:	0f be c2             	movsbl %dl,%eax
f01041c7:	85 c0                	test   %eax,%eax
f01041c9:	74 52                	je     f010421d <.L36+0xfe>
f01041cb:	85 f6                	test   %esi,%esi
f01041cd:	78 d7                	js     f01041a6 <.L36+0x87>
f01041cf:	83 ee 01             	sub    $0x1,%esi
f01041d2:	79 d2                	jns    f01041a6 <.L36+0x87>
f01041d4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041d7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01041da:	eb 32                	jmp    f010420e <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01041dc:	0f be d2             	movsbl %dl,%edx
f01041df:	83 ea 20             	sub    $0x20,%edx
f01041e2:	83 fa 5e             	cmp    $0x5e,%edx
f01041e5:	76 c5                	jbe    f01041ac <.L36+0x8d>
					putch('?', putdat);
f01041e7:	83 ec 08             	sub    $0x8,%esp
f01041ea:	ff 75 0c             	pushl  0xc(%ebp)
f01041ed:	6a 3f                	push   $0x3f
f01041ef:	ff 55 08             	call   *0x8(%ebp)
f01041f2:	83 c4 10             	add    $0x10,%esp
f01041f5:	eb c2                	jmp    f01041b9 <.L36+0x9a>
f01041f7:	89 75 0c             	mov    %esi,0xc(%ebp)
f01041fa:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01041fd:	eb be                	jmp    f01041bd <.L36+0x9e>
				putch(' ', putdat);
f01041ff:	83 ec 08             	sub    $0x8,%esp
f0104202:	56                   	push   %esi
f0104203:	6a 20                	push   $0x20
f0104205:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0104208:	83 ef 01             	sub    $0x1,%edi
f010420b:	83 c4 10             	add    $0x10,%esp
f010420e:	85 ff                	test   %edi,%edi
f0104210:	7f ed                	jg     f01041ff <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0104212:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104215:	89 45 14             	mov    %eax,0x14(%ebp)
f0104218:	e9 7b 01 00 00       	jmp    f0104398 <.L35+0x45>
f010421d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104220:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104223:	eb e9                	jmp    f010420e <.L36+0xef>

f0104225 <.L31>:
f0104225:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104228:	83 f9 01             	cmp    $0x1,%ecx
f010422b:	7e 40                	jle    f010426d <.L31+0x48>
		return va_arg(*ap, long long);
f010422d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104230:	8b 50 04             	mov    0x4(%eax),%edx
f0104233:	8b 00                	mov    (%eax),%eax
f0104235:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104238:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010423b:	8b 45 14             	mov    0x14(%ebp),%eax
f010423e:	8d 40 08             	lea    0x8(%eax),%eax
f0104241:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0104244:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104248:	79 55                	jns    f010429f <.L31+0x7a>
				putch('-', putdat);
f010424a:	83 ec 08             	sub    $0x8,%esp
f010424d:	56                   	push   %esi
f010424e:	6a 2d                	push   $0x2d
f0104250:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104253:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104256:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104259:	f7 da                	neg    %edx
f010425b:	83 d1 00             	adc    $0x0,%ecx
f010425e:	f7 d9                	neg    %ecx
f0104260:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104263:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104268:	e9 10 01 00 00       	jmp    f010437d <.L35+0x2a>
	else if (lflag)
f010426d:	85 c9                	test   %ecx,%ecx
f010426f:	75 17                	jne    f0104288 <.L31+0x63>
		return va_arg(*ap, int);
f0104271:	8b 45 14             	mov    0x14(%ebp),%eax
f0104274:	8b 00                	mov    (%eax),%eax
f0104276:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104279:	99                   	cltd   
f010427a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010427d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104280:	8d 40 04             	lea    0x4(%eax),%eax
f0104283:	89 45 14             	mov    %eax,0x14(%ebp)
f0104286:	eb bc                	jmp    f0104244 <.L31+0x1f>
		return va_arg(*ap, long);
f0104288:	8b 45 14             	mov    0x14(%ebp),%eax
f010428b:	8b 00                	mov    (%eax),%eax
f010428d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104290:	99                   	cltd   
f0104291:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104294:	8b 45 14             	mov    0x14(%ebp),%eax
f0104297:	8d 40 04             	lea    0x4(%eax),%eax
f010429a:	89 45 14             	mov    %eax,0x14(%ebp)
f010429d:	eb a5                	jmp    f0104244 <.L31+0x1f>
			num = getint(&ap, lflag);
f010429f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01042a2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01042a5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01042aa:	e9 ce 00 00 00       	jmp    f010437d <.L35+0x2a>

f01042af <.L37>:
f01042af:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01042b2:	83 f9 01             	cmp    $0x1,%ecx
f01042b5:	7e 18                	jle    f01042cf <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f01042b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01042ba:	8b 10                	mov    (%eax),%edx
f01042bc:	8b 48 04             	mov    0x4(%eax),%ecx
f01042bf:	8d 40 08             	lea    0x8(%eax),%eax
f01042c2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01042c5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01042ca:	e9 ae 00 00 00       	jmp    f010437d <.L35+0x2a>
	else if (lflag)
f01042cf:	85 c9                	test   %ecx,%ecx
f01042d1:	75 1a                	jne    f01042ed <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f01042d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01042d6:	8b 10                	mov    (%eax),%edx
f01042d8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01042dd:	8d 40 04             	lea    0x4(%eax),%eax
f01042e0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01042e3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01042e8:	e9 90 00 00 00       	jmp    f010437d <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01042ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01042f0:	8b 10                	mov    (%eax),%edx
f01042f2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01042f7:	8d 40 04             	lea    0x4(%eax),%eax
f01042fa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01042fd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104302:	eb 79                	jmp    f010437d <.L35+0x2a>

f0104304 <.L34>:
f0104304:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104307:	83 f9 01             	cmp    $0x1,%ecx
f010430a:	7e 15                	jle    f0104321 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f010430c:	8b 45 14             	mov    0x14(%ebp),%eax
f010430f:	8b 10                	mov    (%eax),%edx
f0104311:	8b 48 04             	mov    0x4(%eax),%ecx
f0104314:	8d 40 08             	lea    0x8(%eax),%eax
f0104317:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010431a:	b8 08 00 00 00       	mov    $0x8,%eax
f010431f:	eb 5c                	jmp    f010437d <.L35+0x2a>
	else if (lflag)
f0104321:	85 c9                	test   %ecx,%ecx
f0104323:	75 17                	jne    f010433c <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0104325:	8b 45 14             	mov    0x14(%ebp),%eax
f0104328:	8b 10                	mov    (%eax),%edx
f010432a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010432f:	8d 40 04             	lea    0x4(%eax),%eax
f0104332:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104335:	b8 08 00 00 00       	mov    $0x8,%eax
f010433a:	eb 41                	jmp    f010437d <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010433c:	8b 45 14             	mov    0x14(%ebp),%eax
f010433f:	8b 10                	mov    (%eax),%edx
f0104341:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104346:	8d 40 04             	lea    0x4(%eax),%eax
f0104349:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010434c:	b8 08 00 00 00       	mov    $0x8,%eax
f0104351:	eb 2a                	jmp    f010437d <.L35+0x2a>

f0104353 <.L35>:
			putch('0', putdat);
f0104353:	83 ec 08             	sub    $0x8,%esp
f0104356:	56                   	push   %esi
f0104357:	6a 30                	push   $0x30
f0104359:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010435c:	83 c4 08             	add    $0x8,%esp
f010435f:	56                   	push   %esi
f0104360:	6a 78                	push   $0x78
f0104362:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0104365:	8b 45 14             	mov    0x14(%ebp),%eax
f0104368:	8b 10                	mov    (%eax),%edx
f010436a:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010436f:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104372:	8d 40 04             	lea    0x4(%eax),%eax
f0104375:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104378:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010437d:	83 ec 0c             	sub    $0xc,%esp
f0104380:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104384:	57                   	push   %edi
f0104385:	ff 75 e0             	pushl  -0x20(%ebp)
f0104388:	50                   	push   %eax
f0104389:	51                   	push   %ecx
f010438a:	52                   	push   %edx
f010438b:	89 f2                	mov    %esi,%edx
f010438d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104390:	e8 20 fb ff ff       	call   f0103eb5 <printnum>
			break;
f0104395:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0104398:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010439b:	83 c7 01             	add    $0x1,%edi
f010439e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01043a2:	83 f8 25             	cmp    $0x25,%eax
f01043a5:	0f 84 2d fc ff ff    	je     f0103fd8 <vprintfmt+0x1f>
			if (ch == '\0')
f01043ab:	85 c0                	test   %eax,%eax
f01043ad:	0f 84 91 00 00 00    	je     f0104444 <.L22+0x21>
			putch(ch, putdat);
f01043b3:	83 ec 08             	sub    $0x8,%esp
f01043b6:	56                   	push   %esi
f01043b7:	50                   	push   %eax
f01043b8:	ff 55 08             	call   *0x8(%ebp)
f01043bb:	83 c4 10             	add    $0x10,%esp
f01043be:	eb db                	jmp    f010439b <.L35+0x48>

f01043c0 <.L38>:
f01043c0:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01043c3:	83 f9 01             	cmp    $0x1,%ecx
f01043c6:	7e 15                	jle    f01043dd <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01043c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01043cb:	8b 10                	mov    (%eax),%edx
f01043cd:	8b 48 04             	mov    0x4(%eax),%ecx
f01043d0:	8d 40 08             	lea    0x8(%eax),%eax
f01043d3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01043d6:	b8 10 00 00 00       	mov    $0x10,%eax
f01043db:	eb a0                	jmp    f010437d <.L35+0x2a>
	else if (lflag)
f01043dd:	85 c9                	test   %ecx,%ecx
f01043df:	75 17                	jne    f01043f8 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01043e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01043e4:	8b 10                	mov    (%eax),%edx
f01043e6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01043eb:	8d 40 04             	lea    0x4(%eax),%eax
f01043ee:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01043f1:	b8 10 00 00 00       	mov    $0x10,%eax
f01043f6:	eb 85                	jmp    f010437d <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01043f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01043fb:	8b 10                	mov    (%eax),%edx
f01043fd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104402:	8d 40 04             	lea    0x4(%eax),%eax
f0104405:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104408:	b8 10 00 00 00       	mov    $0x10,%eax
f010440d:	e9 6b ff ff ff       	jmp    f010437d <.L35+0x2a>

f0104412 <.L25>:
			putch(ch, putdat);
f0104412:	83 ec 08             	sub    $0x8,%esp
f0104415:	56                   	push   %esi
f0104416:	6a 25                	push   $0x25
f0104418:	ff 55 08             	call   *0x8(%ebp)
			break;
f010441b:	83 c4 10             	add    $0x10,%esp
f010441e:	e9 75 ff ff ff       	jmp    f0104398 <.L35+0x45>

f0104423 <.L22>:
			putch('%', putdat);
f0104423:	83 ec 08             	sub    $0x8,%esp
f0104426:	56                   	push   %esi
f0104427:	6a 25                	push   $0x25
f0104429:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010442c:	83 c4 10             	add    $0x10,%esp
f010442f:	89 f8                	mov    %edi,%eax
f0104431:	eb 03                	jmp    f0104436 <.L22+0x13>
f0104433:	83 e8 01             	sub    $0x1,%eax
f0104436:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010443a:	75 f7                	jne    f0104433 <.L22+0x10>
f010443c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010443f:	e9 54 ff ff ff       	jmp    f0104398 <.L35+0x45>
}
f0104444:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104447:	5b                   	pop    %ebx
f0104448:	5e                   	pop    %esi
f0104449:	5f                   	pop    %edi
f010444a:	5d                   	pop    %ebp
f010444b:	c3                   	ret    

f010444c <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010444c:	55                   	push   %ebp
f010444d:	89 e5                	mov    %esp,%ebp
f010444f:	53                   	push   %ebx
f0104450:	83 ec 14             	sub    $0x14,%esp
f0104453:	e8 0f bd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104458:	81 c3 c8 6b 08 00    	add    $0x86bc8,%ebx
f010445e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104461:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104464:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104467:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010446b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010446e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104475:	85 c0                	test   %eax,%eax
f0104477:	74 2b                	je     f01044a4 <vsnprintf+0x58>
f0104479:	85 d2                	test   %edx,%edx
f010447b:	7e 27                	jle    f01044a4 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010447d:	ff 75 14             	pushl  0x14(%ebp)
f0104480:	ff 75 10             	pushl  0x10(%ebp)
f0104483:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104486:	50                   	push   %eax
f0104487:	8d 83 5f 8f f7 ff    	lea    -0x870a1(%ebx),%eax
f010448d:	50                   	push   %eax
f010448e:	e8 26 fb ff ff       	call   f0103fb9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104493:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104496:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104499:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010449c:	83 c4 10             	add    $0x10,%esp
}
f010449f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01044a2:	c9                   	leave  
f01044a3:	c3                   	ret    
		return -E_INVAL;
f01044a4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01044a9:	eb f4                	jmp    f010449f <vsnprintf+0x53>

f01044ab <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01044ab:	55                   	push   %ebp
f01044ac:	89 e5                	mov    %esp,%ebp
f01044ae:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01044b1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01044b4:	50                   	push   %eax
f01044b5:	ff 75 10             	pushl  0x10(%ebp)
f01044b8:	ff 75 0c             	pushl  0xc(%ebp)
f01044bb:	ff 75 08             	pushl  0x8(%ebp)
f01044be:	e8 89 ff ff ff       	call   f010444c <vsnprintf>
	va_end(ap);

	return rc;
}
f01044c3:	c9                   	leave  
f01044c4:	c3                   	ret    

f01044c5 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01044c5:	55                   	push   %ebp
f01044c6:	89 e5                	mov    %esp,%ebp
f01044c8:	57                   	push   %edi
f01044c9:	56                   	push   %esi
f01044ca:	53                   	push   %ebx
f01044cb:	83 ec 1c             	sub    $0x1c,%esp
f01044ce:	e8 94 bc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01044d3:	81 c3 4d 6b 08 00    	add    $0x86b4d,%ebx
f01044d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01044dc:	85 c0                	test   %eax,%eax
f01044de:	74 13                	je     f01044f3 <readline+0x2e>
		cprintf("%s", prompt);
f01044e0:	83 ec 08             	sub    $0x8,%esp
f01044e3:	50                   	push   %eax
f01044e4:	8d 83 dd a8 f7 ff    	lea    -0x85723(%ebx),%eax
f01044ea:	50                   	push   %eax
f01044eb:	e8 9a f1 ff ff       	call   f010368a <cprintf>
f01044f0:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01044f3:	83 ec 0c             	sub    $0xc,%esp
f01044f6:	6a 00                	push   $0x0
f01044f8:	e8 02 c2 ff ff       	call   f01006ff <iscons>
f01044fd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104500:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104503:	bf 00 00 00 00       	mov    $0x0,%edi
f0104508:	eb 46                	jmp    f0104550 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010450a:	83 ec 08             	sub    $0x8,%esp
f010450d:	50                   	push   %eax
f010450e:	8d 83 94 b1 f7 ff    	lea    -0x84e6c(%ebx),%eax
f0104514:	50                   	push   %eax
f0104515:	e8 70 f1 ff ff       	call   f010368a <cprintf>
			return NULL;
f010451a:	83 c4 10             	add    $0x10,%esp
f010451d:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104522:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104525:	5b                   	pop    %ebx
f0104526:	5e                   	pop    %esi
f0104527:	5f                   	pop    %edi
f0104528:	5d                   	pop    %ebp
f0104529:	c3                   	ret    
			if (echoing)
f010452a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010452e:	75 05                	jne    f0104535 <readline+0x70>
			i--;
f0104530:	83 ef 01             	sub    $0x1,%edi
f0104533:	eb 1b                	jmp    f0104550 <readline+0x8b>
				cputchar('\b');
f0104535:	83 ec 0c             	sub    $0xc,%esp
f0104538:	6a 08                	push   $0x8
f010453a:	e8 9f c1 ff ff       	call   f01006de <cputchar>
f010453f:	83 c4 10             	add    $0x10,%esp
f0104542:	eb ec                	jmp    f0104530 <readline+0x6b>
			buf[i++] = c;
f0104544:	89 f0                	mov    %esi,%eax
f0104546:	88 84 3b e0 2b 00 00 	mov    %al,0x2be0(%ebx,%edi,1)
f010454d:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104550:	e8 99 c1 ff ff       	call   f01006ee <getchar>
f0104555:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0104557:	85 c0                	test   %eax,%eax
f0104559:	78 af                	js     f010450a <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010455b:	83 f8 08             	cmp    $0x8,%eax
f010455e:	0f 94 c2             	sete   %dl
f0104561:	83 f8 7f             	cmp    $0x7f,%eax
f0104564:	0f 94 c0             	sete   %al
f0104567:	08 c2                	or     %al,%dl
f0104569:	74 04                	je     f010456f <readline+0xaa>
f010456b:	85 ff                	test   %edi,%edi
f010456d:	7f bb                	jg     f010452a <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010456f:	83 fe 1f             	cmp    $0x1f,%esi
f0104572:	7e 1c                	jle    f0104590 <readline+0xcb>
f0104574:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010457a:	7f 14                	jg     f0104590 <readline+0xcb>
			if (echoing)
f010457c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104580:	74 c2                	je     f0104544 <readline+0x7f>
				cputchar(c);
f0104582:	83 ec 0c             	sub    $0xc,%esp
f0104585:	56                   	push   %esi
f0104586:	e8 53 c1 ff ff       	call   f01006de <cputchar>
f010458b:	83 c4 10             	add    $0x10,%esp
f010458e:	eb b4                	jmp    f0104544 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0104590:	83 fe 0a             	cmp    $0xa,%esi
f0104593:	74 05                	je     f010459a <readline+0xd5>
f0104595:	83 fe 0d             	cmp    $0xd,%esi
f0104598:	75 b6                	jne    f0104550 <readline+0x8b>
			if (echoing)
f010459a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010459e:	75 13                	jne    f01045b3 <readline+0xee>
			buf[i] = 0;
f01045a0:	c6 84 3b e0 2b 00 00 	movb   $0x0,0x2be0(%ebx,%edi,1)
f01045a7:	00 
			return buf;
f01045a8:	8d 83 e0 2b 00 00    	lea    0x2be0(%ebx),%eax
f01045ae:	e9 6f ff ff ff       	jmp    f0104522 <readline+0x5d>
				cputchar('\n');
f01045b3:	83 ec 0c             	sub    $0xc,%esp
f01045b6:	6a 0a                	push   $0xa
f01045b8:	e8 21 c1 ff ff       	call   f01006de <cputchar>
f01045bd:	83 c4 10             	add    $0x10,%esp
f01045c0:	eb de                	jmp    f01045a0 <readline+0xdb>

f01045c2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01045c2:	55                   	push   %ebp
f01045c3:	89 e5                	mov    %esp,%ebp
f01045c5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01045c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01045cd:	eb 03                	jmp    f01045d2 <strlen+0x10>
		n++;
f01045cf:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01045d2:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01045d6:	75 f7                	jne    f01045cf <strlen+0xd>
	return n;
}
f01045d8:	5d                   	pop    %ebp
f01045d9:	c3                   	ret    

f01045da <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01045da:	55                   	push   %ebp
f01045db:	89 e5                	mov    %esp,%ebp
f01045dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01045e0:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01045e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01045e8:	eb 03                	jmp    f01045ed <strnlen+0x13>
		n++;
f01045ea:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01045ed:	39 d0                	cmp    %edx,%eax
f01045ef:	74 06                	je     f01045f7 <strnlen+0x1d>
f01045f1:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01045f5:	75 f3                	jne    f01045ea <strnlen+0x10>
	return n;
}
f01045f7:	5d                   	pop    %ebp
f01045f8:	c3                   	ret    

f01045f9 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01045f9:	55                   	push   %ebp
f01045fa:	89 e5                	mov    %esp,%ebp
f01045fc:	53                   	push   %ebx
f01045fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104600:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104603:	89 c2                	mov    %eax,%edx
f0104605:	83 c1 01             	add    $0x1,%ecx
f0104608:	83 c2 01             	add    $0x1,%edx
f010460b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010460f:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104612:	84 db                	test   %bl,%bl
f0104614:	75 ef                	jne    f0104605 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104616:	5b                   	pop    %ebx
f0104617:	5d                   	pop    %ebp
f0104618:	c3                   	ret    

f0104619 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104619:	55                   	push   %ebp
f010461a:	89 e5                	mov    %esp,%ebp
f010461c:	53                   	push   %ebx
f010461d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104620:	53                   	push   %ebx
f0104621:	e8 9c ff ff ff       	call   f01045c2 <strlen>
f0104626:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104629:	ff 75 0c             	pushl  0xc(%ebp)
f010462c:	01 d8                	add    %ebx,%eax
f010462e:	50                   	push   %eax
f010462f:	e8 c5 ff ff ff       	call   f01045f9 <strcpy>
	return dst;
}
f0104634:	89 d8                	mov    %ebx,%eax
f0104636:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104639:	c9                   	leave  
f010463a:	c3                   	ret    

f010463b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010463b:	55                   	push   %ebp
f010463c:	89 e5                	mov    %esp,%ebp
f010463e:	56                   	push   %esi
f010463f:	53                   	push   %ebx
f0104640:	8b 75 08             	mov    0x8(%ebp),%esi
f0104643:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104646:	89 f3                	mov    %esi,%ebx
f0104648:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010464b:	89 f2                	mov    %esi,%edx
f010464d:	eb 0f                	jmp    f010465e <strncpy+0x23>
		*dst++ = *src;
f010464f:	83 c2 01             	add    $0x1,%edx
f0104652:	0f b6 01             	movzbl (%ecx),%eax
f0104655:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104658:	80 39 01             	cmpb   $0x1,(%ecx)
f010465b:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f010465e:	39 da                	cmp    %ebx,%edx
f0104660:	75 ed                	jne    f010464f <strncpy+0x14>
	}
	return ret;
}
f0104662:	89 f0                	mov    %esi,%eax
f0104664:	5b                   	pop    %ebx
f0104665:	5e                   	pop    %esi
f0104666:	5d                   	pop    %ebp
f0104667:	c3                   	ret    

f0104668 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104668:	55                   	push   %ebp
f0104669:	89 e5                	mov    %esp,%ebp
f010466b:	56                   	push   %esi
f010466c:	53                   	push   %ebx
f010466d:	8b 75 08             	mov    0x8(%ebp),%esi
f0104670:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104673:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104676:	89 f0                	mov    %esi,%eax
f0104678:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010467c:	85 c9                	test   %ecx,%ecx
f010467e:	75 0b                	jne    f010468b <strlcpy+0x23>
f0104680:	eb 17                	jmp    f0104699 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104682:	83 c2 01             	add    $0x1,%edx
f0104685:	83 c0 01             	add    $0x1,%eax
f0104688:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f010468b:	39 d8                	cmp    %ebx,%eax
f010468d:	74 07                	je     f0104696 <strlcpy+0x2e>
f010468f:	0f b6 0a             	movzbl (%edx),%ecx
f0104692:	84 c9                	test   %cl,%cl
f0104694:	75 ec                	jne    f0104682 <strlcpy+0x1a>
		*dst = '\0';
f0104696:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104699:	29 f0                	sub    %esi,%eax
}
f010469b:	5b                   	pop    %ebx
f010469c:	5e                   	pop    %esi
f010469d:	5d                   	pop    %ebp
f010469e:	c3                   	ret    

f010469f <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010469f:	55                   	push   %ebp
f01046a0:	89 e5                	mov    %esp,%ebp
f01046a2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01046a5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01046a8:	eb 06                	jmp    f01046b0 <strcmp+0x11>
		p++, q++;
f01046aa:	83 c1 01             	add    $0x1,%ecx
f01046ad:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01046b0:	0f b6 01             	movzbl (%ecx),%eax
f01046b3:	84 c0                	test   %al,%al
f01046b5:	74 04                	je     f01046bb <strcmp+0x1c>
f01046b7:	3a 02                	cmp    (%edx),%al
f01046b9:	74 ef                	je     f01046aa <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01046bb:	0f b6 c0             	movzbl %al,%eax
f01046be:	0f b6 12             	movzbl (%edx),%edx
f01046c1:	29 d0                	sub    %edx,%eax
}
f01046c3:	5d                   	pop    %ebp
f01046c4:	c3                   	ret    

f01046c5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01046c5:	55                   	push   %ebp
f01046c6:	89 e5                	mov    %esp,%ebp
f01046c8:	53                   	push   %ebx
f01046c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01046cc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01046cf:	89 c3                	mov    %eax,%ebx
f01046d1:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01046d4:	eb 06                	jmp    f01046dc <strncmp+0x17>
		n--, p++, q++;
f01046d6:	83 c0 01             	add    $0x1,%eax
f01046d9:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01046dc:	39 d8                	cmp    %ebx,%eax
f01046de:	74 16                	je     f01046f6 <strncmp+0x31>
f01046e0:	0f b6 08             	movzbl (%eax),%ecx
f01046e3:	84 c9                	test   %cl,%cl
f01046e5:	74 04                	je     f01046eb <strncmp+0x26>
f01046e7:	3a 0a                	cmp    (%edx),%cl
f01046e9:	74 eb                	je     f01046d6 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01046eb:	0f b6 00             	movzbl (%eax),%eax
f01046ee:	0f b6 12             	movzbl (%edx),%edx
f01046f1:	29 d0                	sub    %edx,%eax
}
f01046f3:	5b                   	pop    %ebx
f01046f4:	5d                   	pop    %ebp
f01046f5:	c3                   	ret    
		return 0;
f01046f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01046fb:	eb f6                	jmp    f01046f3 <strncmp+0x2e>

f01046fd <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01046fd:	55                   	push   %ebp
f01046fe:	89 e5                	mov    %esp,%ebp
f0104700:	8b 45 08             	mov    0x8(%ebp),%eax
f0104703:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104707:	0f b6 10             	movzbl (%eax),%edx
f010470a:	84 d2                	test   %dl,%dl
f010470c:	74 09                	je     f0104717 <strchr+0x1a>
		if (*s == c)
f010470e:	38 ca                	cmp    %cl,%dl
f0104710:	74 0a                	je     f010471c <strchr+0x1f>
	for (; *s; s++)
f0104712:	83 c0 01             	add    $0x1,%eax
f0104715:	eb f0                	jmp    f0104707 <strchr+0xa>
			return (char *) s;
	return 0;
f0104717:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010471c:	5d                   	pop    %ebp
f010471d:	c3                   	ret    

f010471e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010471e:	55                   	push   %ebp
f010471f:	89 e5                	mov    %esp,%ebp
f0104721:	8b 45 08             	mov    0x8(%ebp),%eax
f0104724:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104728:	eb 03                	jmp    f010472d <strfind+0xf>
f010472a:	83 c0 01             	add    $0x1,%eax
f010472d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104730:	38 ca                	cmp    %cl,%dl
f0104732:	74 04                	je     f0104738 <strfind+0x1a>
f0104734:	84 d2                	test   %dl,%dl
f0104736:	75 f2                	jne    f010472a <strfind+0xc>
			break;
	return (char *) s;
}
f0104738:	5d                   	pop    %ebp
f0104739:	c3                   	ret    

f010473a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010473a:	55                   	push   %ebp
f010473b:	89 e5                	mov    %esp,%ebp
f010473d:	57                   	push   %edi
f010473e:	56                   	push   %esi
f010473f:	53                   	push   %ebx
f0104740:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104743:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104746:	85 c9                	test   %ecx,%ecx
f0104748:	74 13                	je     f010475d <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010474a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104750:	75 05                	jne    f0104757 <memset+0x1d>
f0104752:	f6 c1 03             	test   $0x3,%cl
f0104755:	74 0d                	je     f0104764 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104757:	8b 45 0c             	mov    0xc(%ebp),%eax
f010475a:	fc                   	cld    
f010475b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010475d:	89 f8                	mov    %edi,%eax
f010475f:	5b                   	pop    %ebx
f0104760:	5e                   	pop    %esi
f0104761:	5f                   	pop    %edi
f0104762:	5d                   	pop    %ebp
f0104763:	c3                   	ret    
		c &= 0xFF;
f0104764:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104768:	89 d3                	mov    %edx,%ebx
f010476a:	c1 e3 08             	shl    $0x8,%ebx
f010476d:	89 d0                	mov    %edx,%eax
f010476f:	c1 e0 18             	shl    $0x18,%eax
f0104772:	89 d6                	mov    %edx,%esi
f0104774:	c1 e6 10             	shl    $0x10,%esi
f0104777:	09 f0                	or     %esi,%eax
f0104779:	09 c2                	or     %eax,%edx
f010477b:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f010477d:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104780:	89 d0                	mov    %edx,%eax
f0104782:	fc                   	cld    
f0104783:	f3 ab                	rep stos %eax,%es:(%edi)
f0104785:	eb d6                	jmp    f010475d <memset+0x23>

f0104787 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104787:	55                   	push   %ebp
f0104788:	89 e5                	mov    %esp,%ebp
f010478a:	57                   	push   %edi
f010478b:	56                   	push   %esi
f010478c:	8b 45 08             	mov    0x8(%ebp),%eax
f010478f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104792:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104795:	39 c6                	cmp    %eax,%esi
f0104797:	73 35                	jae    f01047ce <memmove+0x47>
f0104799:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010479c:	39 c2                	cmp    %eax,%edx
f010479e:	76 2e                	jbe    f01047ce <memmove+0x47>
		s += n;
		d += n;
f01047a0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047a3:	89 d6                	mov    %edx,%esi
f01047a5:	09 fe                	or     %edi,%esi
f01047a7:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01047ad:	74 0c                	je     f01047bb <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01047af:	83 ef 01             	sub    $0x1,%edi
f01047b2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01047b5:	fd                   	std    
f01047b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01047b8:	fc                   	cld    
f01047b9:	eb 21                	jmp    f01047dc <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047bb:	f6 c1 03             	test   $0x3,%cl
f01047be:	75 ef                	jne    f01047af <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01047c0:	83 ef 04             	sub    $0x4,%edi
f01047c3:	8d 72 fc             	lea    -0x4(%edx),%esi
f01047c6:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01047c9:	fd                   	std    
f01047ca:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047cc:	eb ea                	jmp    f01047b8 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047ce:	89 f2                	mov    %esi,%edx
f01047d0:	09 c2                	or     %eax,%edx
f01047d2:	f6 c2 03             	test   $0x3,%dl
f01047d5:	74 09                	je     f01047e0 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01047d7:	89 c7                	mov    %eax,%edi
f01047d9:	fc                   	cld    
f01047da:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01047dc:	5e                   	pop    %esi
f01047dd:	5f                   	pop    %edi
f01047de:	5d                   	pop    %ebp
f01047df:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047e0:	f6 c1 03             	test   $0x3,%cl
f01047e3:	75 f2                	jne    f01047d7 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01047e5:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01047e8:	89 c7                	mov    %eax,%edi
f01047ea:	fc                   	cld    
f01047eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047ed:	eb ed                	jmp    f01047dc <memmove+0x55>

f01047ef <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01047ef:	55                   	push   %ebp
f01047f0:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01047f2:	ff 75 10             	pushl  0x10(%ebp)
f01047f5:	ff 75 0c             	pushl  0xc(%ebp)
f01047f8:	ff 75 08             	pushl  0x8(%ebp)
f01047fb:	e8 87 ff ff ff       	call   f0104787 <memmove>
}
f0104800:	c9                   	leave  
f0104801:	c3                   	ret    

f0104802 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104802:	55                   	push   %ebp
f0104803:	89 e5                	mov    %esp,%ebp
f0104805:	56                   	push   %esi
f0104806:	53                   	push   %ebx
f0104807:	8b 45 08             	mov    0x8(%ebp),%eax
f010480a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010480d:	89 c6                	mov    %eax,%esi
f010480f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104812:	39 f0                	cmp    %esi,%eax
f0104814:	74 1c                	je     f0104832 <memcmp+0x30>
		if (*s1 != *s2)
f0104816:	0f b6 08             	movzbl (%eax),%ecx
f0104819:	0f b6 1a             	movzbl (%edx),%ebx
f010481c:	38 d9                	cmp    %bl,%cl
f010481e:	75 08                	jne    f0104828 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0104820:	83 c0 01             	add    $0x1,%eax
f0104823:	83 c2 01             	add    $0x1,%edx
f0104826:	eb ea                	jmp    f0104812 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0104828:	0f b6 c1             	movzbl %cl,%eax
f010482b:	0f b6 db             	movzbl %bl,%ebx
f010482e:	29 d8                	sub    %ebx,%eax
f0104830:	eb 05                	jmp    f0104837 <memcmp+0x35>
	}

	return 0;
f0104832:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104837:	5b                   	pop    %ebx
f0104838:	5e                   	pop    %esi
f0104839:	5d                   	pop    %ebp
f010483a:	c3                   	ret    

f010483b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010483b:	55                   	push   %ebp
f010483c:	89 e5                	mov    %esp,%ebp
f010483e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104841:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104844:	89 c2                	mov    %eax,%edx
f0104846:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104849:	39 d0                	cmp    %edx,%eax
f010484b:	73 09                	jae    f0104856 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f010484d:	38 08                	cmp    %cl,(%eax)
f010484f:	74 05                	je     f0104856 <memfind+0x1b>
	for (; s < ends; s++)
f0104851:	83 c0 01             	add    $0x1,%eax
f0104854:	eb f3                	jmp    f0104849 <memfind+0xe>
			break;
	return (void *) s;
}
f0104856:	5d                   	pop    %ebp
f0104857:	c3                   	ret    

f0104858 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104858:	55                   	push   %ebp
f0104859:	89 e5                	mov    %esp,%ebp
f010485b:	57                   	push   %edi
f010485c:	56                   	push   %esi
f010485d:	53                   	push   %ebx
f010485e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104861:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104864:	eb 03                	jmp    f0104869 <strtol+0x11>
		s++;
f0104866:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0104869:	0f b6 01             	movzbl (%ecx),%eax
f010486c:	3c 20                	cmp    $0x20,%al
f010486e:	74 f6                	je     f0104866 <strtol+0xe>
f0104870:	3c 09                	cmp    $0x9,%al
f0104872:	74 f2                	je     f0104866 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0104874:	3c 2b                	cmp    $0x2b,%al
f0104876:	74 2e                	je     f01048a6 <strtol+0x4e>
	int neg = 0;
f0104878:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010487d:	3c 2d                	cmp    $0x2d,%al
f010487f:	74 2f                	je     f01048b0 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104881:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104887:	75 05                	jne    f010488e <strtol+0x36>
f0104889:	80 39 30             	cmpb   $0x30,(%ecx)
f010488c:	74 2c                	je     f01048ba <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010488e:	85 db                	test   %ebx,%ebx
f0104890:	75 0a                	jne    f010489c <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104892:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0104897:	80 39 30             	cmpb   $0x30,(%ecx)
f010489a:	74 28                	je     f01048c4 <strtol+0x6c>
		base = 10;
f010489c:	b8 00 00 00 00       	mov    $0x0,%eax
f01048a1:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01048a4:	eb 50                	jmp    f01048f6 <strtol+0x9e>
		s++;
f01048a6:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01048a9:	bf 00 00 00 00       	mov    $0x0,%edi
f01048ae:	eb d1                	jmp    f0104881 <strtol+0x29>
		s++, neg = 1;
f01048b0:	83 c1 01             	add    $0x1,%ecx
f01048b3:	bf 01 00 00 00       	mov    $0x1,%edi
f01048b8:	eb c7                	jmp    f0104881 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01048ba:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01048be:	74 0e                	je     f01048ce <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01048c0:	85 db                	test   %ebx,%ebx
f01048c2:	75 d8                	jne    f010489c <strtol+0x44>
		s++, base = 8;
f01048c4:	83 c1 01             	add    $0x1,%ecx
f01048c7:	bb 08 00 00 00       	mov    $0x8,%ebx
f01048cc:	eb ce                	jmp    f010489c <strtol+0x44>
		s += 2, base = 16;
f01048ce:	83 c1 02             	add    $0x2,%ecx
f01048d1:	bb 10 00 00 00       	mov    $0x10,%ebx
f01048d6:	eb c4                	jmp    f010489c <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01048d8:	8d 72 9f             	lea    -0x61(%edx),%esi
f01048db:	89 f3                	mov    %esi,%ebx
f01048dd:	80 fb 19             	cmp    $0x19,%bl
f01048e0:	77 29                	ja     f010490b <strtol+0xb3>
			dig = *s - 'a' + 10;
f01048e2:	0f be d2             	movsbl %dl,%edx
f01048e5:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01048e8:	3b 55 10             	cmp    0x10(%ebp),%edx
f01048eb:	7d 30                	jge    f010491d <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01048ed:	83 c1 01             	add    $0x1,%ecx
f01048f0:	0f af 45 10          	imul   0x10(%ebp),%eax
f01048f4:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01048f6:	0f b6 11             	movzbl (%ecx),%edx
f01048f9:	8d 72 d0             	lea    -0x30(%edx),%esi
f01048fc:	89 f3                	mov    %esi,%ebx
f01048fe:	80 fb 09             	cmp    $0x9,%bl
f0104901:	77 d5                	ja     f01048d8 <strtol+0x80>
			dig = *s - '0';
f0104903:	0f be d2             	movsbl %dl,%edx
f0104906:	83 ea 30             	sub    $0x30,%edx
f0104909:	eb dd                	jmp    f01048e8 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f010490b:	8d 72 bf             	lea    -0x41(%edx),%esi
f010490e:	89 f3                	mov    %esi,%ebx
f0104910:	80 fb 19             	cmp    $0x19,%bl
f0104913:	77 08                	ja     f010491d <strtol+0xc5>
			dig = *s - 'A' + 10;
f0104915:	0f be d2             	movsbl %dl,%edx
f0104918:	83 ea 37             	sub    $0x37,%edx
f010491b:	eb cb                	jmp    f01048e8 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f010491d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104921:	74 05                	je     f0104928 <strtol+0xd0>
		*endptr = (char *) s;
f0104923:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104926:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0104928:	89 c2                	mov    %eax,%edx
f010492a:	f7 da                	neg    %edx
f010492c:	85 ff                	test   %edi,%edi
f010492e:	0f 45 c2             	cmovne %edx,%eax
}
f0104931:	5b                   	pop    %ebx
f0104932:	5e                   	pop    %esi
f0104933:	5f                   	pop    %edi
f0104934:	5d                   	pop    %ebp
f0104935:	c3                   	ret    
f0104936:	66 90                	xchg   %ax,%ax
f0104938:	66 90                	xchg   %ax,%ax
f010493a:	66 90                	xchg   %ax,%ax
f010493c:	66 90                	xchg   %ax,%ax
f010493e:	66 90                	xchg   %ax,%ax

f0104940 <__udivdi3>:
f0104940:	55                   	push   %ebp
f0104941:	57                   	push   %edi
f0104942:	56                   	push   %esi
f0104943:	53                   	push   %ebx
f0104944:	83 ec 1c             	sub    $0x1c,%esp
f0104947:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010494b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010494f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104953:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0104957:	85 d2                	test   %edx,%edx
f0104959:	75 35                	jne    f0104990 <__udivdi3+0x50>
f010495b:	39 f3                	cmp    %esi,%ebx
f010495d:	0f 87 bd 00 00 00    	ja     f0104a20 <__udivdi3+0xe0>
f0104963:	85 db                	test   %ebx,%ebx
f0104965:	89 d9                	mov    %ebx,%ecx
f0104967:	75 0b                	jne    f0104974 <__udivdi3+0x34>
f0104969:	b8 01 00 00 00       	mov    $0x1,%eax
f010496e:	31 d2                	xor    %edx,%edx
f0104970:	f7 f3                	div    %ebx
f0104972:	89 c1                	mov    %eax,%ecx
f0104974:	31 d2                	xor    %edx,%edx
f0104976:	89 f0                	mov    %esi,%eax
f0104978:	f7 f1                	div    %ecx
f010497a:	89 c6                	mov    %eax,%esi
f010497c:	89 e8                	mov    %ebp,%eax
f010497e:	89 f7                	mov    %esi,%edi
f0104980:	f7 f1                	div    %ecx
f0104982:	89 fa                	mov    %edi,%edx
f0104984:	83 c4 1c             	add    $0x1c,%esp
f0104987:	5b                   	pop    %ebx
f0104988:	5e                   	pop    %esi
f0104989:	5f                   	pop    %edi
f010498a:	5d                   	pop    %ebp
f010498b:	c3                   	ret    
f010498c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104990:	39 f2                	cmp    %esi,%edx
f0104992:	77 7c                	ja     f0104a10 <__udivdi3+0xd0>
f0104994:	0f bd fa             	bsr    %edx,%edi
f0104997:	83 f7 1f             	xor    $0x1f,%edi
f010499a:	0f 84 98 00 00 00    	je     f0104a38 <__udivdi3+0xf8>
f01049a0:	89 f9                	mov    %edi,%ecx
f01049a2:	b8 20 00 00 00       	mov    $0x20,%eax
f01049a7:	29 f8                	sub    %edi,%eax
f01049a9:	d3 e2                	shl    %cl,%edx
f01049ab:	89 54 24 08          	mov    %edx,0x8(%esp)
f01049af:	89 c1                	mov    %eax,%ecx
f01049b1:	89 da                	mov    %ebx,%edx
f01049b3:	d3 ea                	shr    %cl,%edx
f01049b5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01049b9:	09 d1                	or     %edx,%ecx
f01049bb:	89 f2                	mov    %esi,%edx
f01049bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01049c1:	89 f9                	mov    %edi,%ecx
f01049c3:	d3 e3                	shl    %cl,%ebx
f01049c5:	89 c1                	mov    %eax,%ecx
f01049c7:	d3 ea                	shr    %cl,%edx
f01049c9:	89 f9                	mov    %edi,%ecx
f01049cb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01049cf:	d3 e6                	shl    %cl,%esi
f01049d1:	89 eb                	mov    %ebp,%ebx
f01049d3:	89 c1                	mov    %eax,%ecx
f01049d5:	d3 eb                	shr    %cl,%ebx
f01049d7:	09 de                	or     %ebx,%esi
f01049d9:	89 f0                	mov    %esi,%eax
f01049db:	f7 74 24 08          	divl   0x8(%esp)
f01049df:	89 d6                	mov    %edx,%esi
f01049e1:	89 c3                	mov    %eax,%ebx
f01049e3:	f7 64 24 0c          	mull   0xc(%esp)
f01049e7:	39 d6                	cmp    %edx,%esi
f01049e9:	72 0c                	jb     f01049f7 <__udivdi3+0xb7>
f01049eb:	89 f9                	mov    %edi,%ecx
f01049ed:	d3 e5                	shl    %cl,%ebp
f01049ef:	39 c5                	cmp    %eax,%ebp
f01049f1:	73 5d                	jae    f0104a50 <__udivdi3+0x110>
f01049f3:	39 d6                	cmp    %edx,%esi
f01049f5:	75 59                	jne    f0104a50 <__udivdi3+0x110>
f01049f7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01049fa:	31 ff                	xor    %edi,%edi
f01049fc:	89 fa                	mov    %edi,%edx
f01049fe:	83 c4 1c             	add    $0x1c,%esp
f0104a01:	5b                   	pop    %ebx
f0104a02:	5e                   	pop    %esi
f0104a03:	5f                   	pop    %edi
f0104a04:	5d                   	pop    %ebp
f0104a05:	c3                   	ret    
f0104a06:	8d 76 00             	lea    0x0(%esi),%esi
f0104a09:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104a10:	31 ff                	xor    %edi,%edi
f0104a12:	31 c0                	xor    %eax,%eax
f0104a14:	89 fa                	mov    %edi,%edx
f0104a16:	83 c4 1c             	add    $0x1c,%esp
f0104a19:	5b                   	pop    %ebx
f0104a1a:	5e                   	pop    %esi
f0104a1b:	5f                   	pop    %edi
f0104a1c:	5d                   	pop    %ebp
f0104a1d:	c3                   	ret    
f0104a1e:	66 90                	xchg   %ax,%ax
f0104a20:	31 ff                	xor    %edi,%edi
f0104a22:	89 e8                	mov    %ebp,%eax
f0104a24:	89 f2                	mov    %esi,%edx
f0104a26:	f7 f3                	div    %ebx
f0104a28:	89 fa                	mov    %edi,%edx
f0104a2a:	83 c4 1c             	add    $0x1c,%esp
f0104a2d:	5b                   	pop    %ebx
f0104a2e:	5e                   	pop    %esi
f0104a2f:	5f                   	pop    %edi
f0104a30:	5d                   	pop    %ebp
f0104a31:	c3                   	ret    
f0104a32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104a38:	39 f2                	cmp    %esi,%edx
f0104a3a:	72 06                	jb     f0104a42 <__udivdi3+0x102>
f0104a3c:	31 c0                	xor    %eax,%eax
f0104a3e:	39 eb                	cmp    %ebp,%ebx
f0104a40:	77 d2                	ja     f0104a14 <__udivdi3+0xd4>
f0104a42:	b8 01 00 00 00       	mov    $0x1,%eax
f0104a47:	eb cb                	jmp    f0104a14 <__udivdi3+0xd4>
f0104a49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104a50:	89 d8                	mov    %ebx,%eax
f0104a52:	31 ff                	xor    %edi,%edi
f0104a54:	eb be                	jmp    f0104a14 <__udivdi3+0xd4>
f0104a56:	66 90                	xchg   %ax,%ax
f0104a58:	66 90                	xchg   %ax,%ax
f0104a5a:	66 90                	xchg   %ax,%ax
f0104a5c:	66 90                	xchg   %ax,%ax
f0104a5e:	66 90                	xchg   %ax,%ax

f0104a60 <__umoddi3>:
f0104a60:	55                   	push   %ebp
f0104a61:	57                   	push   %edi
f0104a62:	56                   	push   %esi
f0104a63:	53                   	push   %ebx
f0104a64:	83 ec 1c             	sub    $0x1c,%esp
f0104a67:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0104a6b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0104a6f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104a73:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104a77:	85 ed                	test   %ebp,%ebp
f0104a79:	89 f0                	mov    %esi,%eax
f0104a7b:	89 da                	mov    %ebx,%edx
f0104a7d:	75 19                	jne    f0104a98 <__umoddi3+0x38>
f0104a7f:	39 df                	cmp    %ebx,%edi
f0104a81:	0f 86 b1 00 00 00    	jbe    f0104b38 <__umoddi3+0xd8>
f0104a87:	f7 f7                	div    %edi
f0104a89:	89 d0                	mov    %edx,%eax
f0104a8b:	31 d2                	xor    %edx,%edx
f0104a8d:	83 c4 1c             	add    $0x1c,%esp
f0104a90:	5b                   	pop    %ebx
f0104a91:	5e                   	pop    %esi
f0104a92:	5f                   	pop    %edi
f0104a93:	5d                   	pop    %ebp
f0104a94:	c3                   	ret    
f0104a95:	8d 76 00             	lea    0x0(%esi),%esi
f0104a98:	39 dd                	cmp    %ebx,%ebp
f0104a9a:	77 f1                	ja     f0104a8d <__umoddi3+0x2d>
f0104a9c:	0f bd cd             	bsr    %ebp,%ecx
f0104a9f:	83 f1 1f             	xor    $0x1f,%ecx
f0104aa2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104aa6:	0f 84 b4 00 00 00    	je     f0104b60 <__umoddi3+0x100>
f0104aac:	b8 20 00 00 00       	mov    $0x20,%eax
f0104ab1:	89 c2                	mov    %eax,%edx
f0104ab3:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104ab7:	29 c2                	sub    %eax,%edx
f0104ab9:	89 c1                	mov    %eax,%ecx
f0104abb:	89 f8                	mov    %edi,%eax
f0104abd:	d3 e5                	shl    %cl,%ebp
f0104abf:	89 d1                	mov    %edx,%ecx
f0104ac1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104ac5:	d3 e8                	shr    %cl,%eax
f0104ac7:	09 c5                	or     %eax,%ebp
f0104ac9:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104acd:	89 c1                	mov    %eax,%ecx
f0104acf:	d3 e7                	shl    %cl,%edi
f0104ad1:	89 d1                	mov    %edx,%ecx
f0104ad3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104ad7:	89 df                	mov    %ebx,%edi
f0104ad9:	d3 ef                	shr    %cl,%edi
f0104adb:	89 c1                	mov    %eax,%ecx
f0104add:	89 f0                	mov    %esi,%eax
f0104adf:	d3 e3                	shl    %cl,%ebx
f0104ae1:	89 d1                	mov    %edx,%ecx
f0104ae3:	89 fa                	mov    %edi,%edx
f0104ae5:	d3 e8                	shr    %cl,%eax
f0104ae7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104aec:	09 d8                	or     %ebx,%eax
f0104aee:	f7 f5                	div    %ebp
f0104af0:	d3 e6                	shl    %cl,%esi
f0104af2:	89 d1                	mov    %edx,%ecx
f0104af4:	f7 64 24 08          	mull   0x8(%esp)
f0104af8:	39 d1                	cmp    %edx,%ecx
f0104afa:	89 c3                	mov    %eax,%ebx
f0104afc:	89 d7                	mov    %edx,%edi
f0104afe:	72 06                	jb     f0104b06 <__umoddi3+0xa6>
f0104b00:	75 0e                	jne    f0104b10 <__umoddi3+0xb0>
f0104b02:	39 c6                	cmp    %eax,%esi
f0104b04:	73 0a                	jae    f0104b10 <__umoddi3+0xb0>
f0104b06:	2b 44 24 08          	sub    0x8(%esp),%eax
f0104b0a:	19 ea                	sbb    %ebp,%edx
f0104b0c:	89 d7                	mov    %edx,%edi
f0104b0e:	89 c3                	mov    %eax,%ebx
f0104b10:	89 ca                	mov    %ecx,%edx
f0104b12:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104b17:	29 de                	sub    %ebx,%esi
f0104b19:	19 fa                	sbb    %edi,%edx
f0104b1b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0104b1f:	89 d0                	mov    %edx,%eax
f0104b21:	d3 e0                	shl    %cl,%eax
f0104b23:	89 d9                	mov    %ebx,%ecx
f0104b25:	d3 ee                	shr    %cl,%esi
f0104b27:	d3 ea                	shr    %cl,%edx
f0104b29:	09 f0                	or     %esi,%eax
f0104b2b:	83 c4 1c             	add    $0x1c,%esp
f0104b2e:	5b                   	pop    %ebx
f0104b2f:	5e                   	pop    %esi
f0104b30:	5f                   	pop    %edi
f0104b31:	5d                   	pop    %ebp
f0104b32:	c3                   	ret    
f0104b33:	90                   	nop
f0104b34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104b38:	85 ff                	test   %edi,%edi
f0104b3a:	89 f9                	mov    %edi,%ecx
f0104b3c:	75 0b                	jne    f0104b49 <__umoddi3+0xe9>
f0104b3e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104b43:	31 d2                	xor    %edx,%edx
f0104b45:	f7 f7                	div    %edi
f0104b47:	89 c1                	mov    %eax,%ecx
f0104b49:	89 d8                	mov    %ebx,%eax
f0104b4b:	31 d2                	xor    %edx,%edx
f0104b4d:	f7 f1                	div    %ecx
f0104b4f:	89 f0                	mov    %esi,%eax
f0104b51:	f7 f1                	div    %ecx
f0104b53:	e9 31 ff ff ff       	jmp    f0104a89 <__umoddi3+0x29>
f0104b58:	90                   	nop
f0104b59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104b60:	39 dd                	cmp    %ebx,%ebp
f0104b62:	72 08                	jb     f0104b6c <__umoddi3+0x10c>
f0104b64:	39 f7                	cmp    %esi,%edi
f0104b66:	0f 87 21 ff ff ff    	ja     f0104a8d <__umoddi3+0x2d>
f0104b6c:	89 da                	mov    %ebx,%edx
f0104b6e:	89 f0                	mov    %esi,%eax
f0104b70:	29 f8                	sub    %edi,%eax
f0104b72:	19 ea                	sbb    %ebp,%edx
f0104b74:	e9 14 ff ff ff       	jmp    f0104a8d <__umoddi3+0x2d>
