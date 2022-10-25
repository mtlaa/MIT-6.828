
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
###	movl	%eax, %cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100025:	b8 2c 00 10 f0       	mov    $0xf010002c,%eax
	jmp	*%eax
f010002a:	ff e0                	jmp    *%eax

f010002c <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002c:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100031:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100036:	e8 68 00 00 00       	call   f01000a3 <i386_init>

f010003b <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003b:	eb fe                	jmp    f010003b <spin>

f010003d <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f010003d:	55                   	push   %ebp
f010003e:	89 e5                	mov    %esp,%ebp
f0100040:	56                   	push   %esi
f0100041:	53                   	push   %ebx
f0100042:	e8 72 01 00 00       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100047:	81 c3 c1 12 01 00    	add    $0x112c1,%ebx
f010004d:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100050:	83 ec 08             	sub    $0x8,%esp
f0100053:	56                   	push   %esi
f0100054:	8d 83 f8 06 ff ff    	lea    -0xf908(%ebx),%eax
f010005a:	50                   	push   %eax
f010005b:	e8 e6 09 00 00       	call   f0100a46 <cprintf>
	if (x > 0)
f0100060:	83 c4 10             	add    $0x10,%esp
f0100063:	85 f6                	test   %esi,%esi
f0100065:	7f 2b                	jg     f0100092 <test_backtrace+0x55>
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f0100067:	83 ec 04             	sub    $0x4,%esp
f010006a:	6a 00                	push   $0x0
f010006c:	6a 00                	push   $0x0
f010006e:	6a 00                	push   $0x0
f0100070:	e8 0b 08 00 00       	call   f0100880 <mon_backtrace>
f0100075:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f0100078:	83 ec 08             	sub    $0x8,%esp
f010007b:	56                   	push   %esi
f010007c:	8d 83 14 07 ff ff    	lea    -0xf8ec(%ebx),%eax
f0100082:	50                   	push   %eax
f0100083:	e8 be 09 00 00       	call   f0100a46 <cprintf>
}
f0100088:	83 c4 10             	add    $0x10,%esp
f010008b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010008e:	5b                   	pop    %ebx
f010008f:	5e                   	pop    %esi
f0100090:	5d                   	pop    %ebp
f0100091:	c3                   	ret    
		test_backtrace(x-1);
f0100092:	83 ec 0c             	sub    $0xc,%esp
f0100095:	8d 46 ff             	lea    -0x1(%esi),%eax
f0100098:	50                   	push   %eax
f0100099:	e8 9f ff ff ff       	call   f010003d <test_backtrace>
f010009e:	83 c4 10             	add    $0x10,%esp
f01000a1:	eb d5                	jmp    f0100078 <test_backtrace+0x3b>

f01000a3 <i386_init>:

void
i386_init(void)
{
f01000a3:	55                   	push   %ebp
f01000a4:	89 e5                	mov    %esp,%ebp
f01000a6:	53                   	push   %ebx
f01000a7:	83 ec 08             	sub    $0x8,%esp
f01000aa:	e8 0a 01 00 00       	call   f01001b9 <__x86.get_pc_thunk.bx>
f01000af:	81 c3 59 12 01 00    	add    $0x11259,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b5:	c7 c2 60 30 11 f0    	mov    $0xf0113060,%edx
f01000bb:	c7 c0 a0 36 11 f0    	mov    $0xf01136a0,%eax
f01000c1:	29 d0                	sub    %edx,%eax
f01000c3:	50                   	push   %eax
f01000c4:	6a 00                	push   $0x0
f01000c6:	52                   	push   %edx
f01000c7:	e8 da 14 00 00       	call   f01015a6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cc:	e8 3d 05 00 00       	call   f010060e <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d1:	83 c4 08             	add    $0x8,%esp
f01000d4:	68 ac 1a 00 00       	push   $0x1aac
f01000d9:	8d 83 2f 07 ff ff    	lea    -0xf8d1(%ebx),%eax
f01000df:	50                   	push   %eax
f01000e0:	e8 61 09 00 00       	call   f0100a46 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e5:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ec:	e8 4c ff ff ff       	call   f010003d <test_backtrace>
f01000f1:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f4:	83 ec 0c             	sub    $0xc,%esp
f01000f7:	6a 00                	push   $0x0
f01000f9:	e8 8c 07 00 00       	call   f010088a <monitor>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb f1                	jmp    f01000f4 <i386_init+0x51>

f0100103 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	57                   	push   %edi
f0100107:	56                   	push   %esi
f0100108:	53                   	push   %ebx
f0100109:	83 ec 0c             	sub    $0xc,%esp
f010010c:	e8 a8 00 00 00       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100111:	81 c3 f7 11 01 00    	add    $0x111f7,%ebx
f0100117:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f010011a:	c7 c0 a4 36 11 f0    	mov    $0xf01136a4,%eax
f0100120:	83 38 00             	cmpl   $0x0,(%eax)
f0100123:	74 0f                	je     f0100134 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100125:	83 ec 0c             	sub    $0xc,%esp
f0100128:	6a 00                	push   $0x0
f010012a:	e8 5b 07 00 00       	call   f010088a <monitor>
f010012f:	83 c4 10             	add    $0x10,%esp
f0100132:	eb f1                	jmp    f0100125 <_panic+0x22>
	panicstr = fmt;
f0100134:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f0100136:	fa                   	cli    
f0100137:	fc                   	cld    
	va_start(ap, fmt);
f0100138:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010013b:	83 ec 04             	sub    $0x4,%esp
f010013e:	ff 75 0c             	pushl  0xc(%ebp)
f0100141:	ff 75 08             	pushl  0x8(%ebp)
f0100144:	8d 83 4a 07 ff ff    	lea    -0xf8b6(%ebx),%eax
f010014a:	50                   	push   %eax
f010014b:	e8 f6 08 00 00       	call   f0100a46 <cprintf>
	vcprintf(fmt, ap);
f0100150:	83 c4 08             	add    $0x8,%esp
f0100153:	56                   	push   %esi
f0100154:	57                   	push   %edi
f0100155:	e8 b5 08 00 00       	call   f0100a0f <vcprintf>
	cprintf("\n");
f010015a:	8d 83 86 07 ff ff    	lea    -0xf87a(%ebx),%eax
f0100160:	89 04 24             	mov    %eax,(%esp)
f0100163:	e8 de 08 00 00       	call   f0100a46 <cprintf>
f0100168:	83 c4 10             	add    $0x10,%esp
f010016b:	eb b8                	jmp    f0100125 <_panic+0x22>

f010016d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010016d:	55                   	push   %ebp
f010016e:	89 e5                	mov    %esp,%ebp
f0100170:	56                   	push   %esi
f0100171:	53                   	push   %ebx
f0100172:	e8 42 00 00 00       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100177:	81 c3 91 11 01 00    	add    $0x11191,%ebx
	va_list ap;

	va_start(ap, fmt);
f010017d:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100180:	83 ec 04             	sub    $0x4,%esp
f0100183:	ff 75 0c             	pushl  0xc(%ebp)
f0100186:	ff 75 08             	pushl  0x8(%ebp)
f0100189:	8d 83 62 07 ff ff    	lea    -0xf89e(%ebx),%eax
f010018f:	50                   	push   %eax
f0100190:	e8 b1 08 00 00       	call   f0100a46 <cprintf>
	vcprintf(fmt, ap);
f0100195:	83 c4 08             	add    $0x8,%esp
f0100198:	56                   	push   %esi
f0100199:	ff 75 10             	pushl  0x10(%ebp)
f010019c:	e8 6e 08 00 00       	call   f0100a0f <vcprintf>
	cprintf("\n");
f01001a1:	8d 83 86 07 ff ff    	lea    -0xf87a(%ebx),%eax
f01001a7:	89 04 24             	mov    %eax,(%esp)
f01001aa:	e8 97 08 00 00       	call   f0100a46 <cprintf>
	va_end(ap);
}
f01001af:	83 c4 10             	add    $0x10,%esp
f01001b2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001b5:	5b                   	pop    %ebx
f01001b6:	5e                   	pop    %esi
f01001b7:	5d                   	pop    %ebp
f01001b8:	c3                   	ret    

f01001b9 <__x86.get_pc_thunk.bx>:
f01001b9:	8b 1c 24             	mov    (%esp),%ebx
f01001bc:	c3                   	ret    

f01001bd <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001c0:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c5:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	74 0b                	je     f01001d5 <serial_proc_data+0x18>
f01001ca:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d0:	0f b6 c0             	movzbl %al,%eax
}
f01001d3:	5d                   	pop    %ebp
f01001d4:	c3                   	ret    
		return -1;
f01001d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001da:	eb f7                	jmp    f01001d3 <serial_proc_data+0x16>

f01001dc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001dc:	55                   	push   %ebp
f01001dd:	89 e5                	mov    %esp,%ebp
f01001df:	56                   	push   %esi
f01001e0:	53                   	push   %ebx
f01001e1:	e8 d3 ff ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f01001e6:	81 c3 22 11 01 00    	add    $0x11122,%ebx
f01001ec:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f01001ee:	ff d6                	call   *%esi
f01001f0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f3:	74 2e                	je     f0100223 <cons_intr+0x47>
		if (c == 0)
f01001f5:	85 c0                	test   %eax,%eax
f01001f7:	74 f5                	je     f01001ee <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001f9:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f01001ff:	8d 51 01             	lea    0x1(%ecx),%edx
f0100202:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f0100208:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f010020f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100215:	75 d7                	jne    f01001ee <cons_intr+0x12>
			cons.wpos = 0;
f0100217:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f010021e:	00 00 00 
f0100221:	eb cb                	jmp    f01001ee <cons_intr+0x12>
	}
}
f0100223:	5b                   	pop    %ebx
f0100224:	5e                   	pop    %esi
f0100225:	5d                   	pop    %ebp
f0100226:	c3                   	ret    

f0100227 <kbd_proc_data>:
{
f0100227:	55                   	push   %ebp
f0100228:	89 e5                	mov    %esp,%ebp
f010022a:	56                   	push   %esi
f010022b:	53                   	push   %ebx
f010022c:	e8 88 ff ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100231:	81 c3 d7 10 01 00    	add    $0x110d7,%ebx
f0100237:	ba 64 00 00 00       	mov    $0x64,%edx
f010023c:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f010023d:	a8 01                	test   $0x1,%al
f010023f:	0f 84 06 01 00 00    	je     f010034b <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f0100245:	a8 20                	test   $0x20,%al
f0100247:	0f 85 05 01 00 00    	jne    f0100352 <kbd_proc_data+0x12b>
f010024d:	ba 60 00 00 00       	mov    $0x60,%edx
f0100252:	ec                   	in     (%dx),%al
f0100253:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100255:	3c e0                	cmp    $0xe0,%al
f0100257:	0f 84 93 00 00 00    	je     f01002f0 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f010025d:	84 c0                	test   %al,%al
f010025f:	0f 88 a0 00 00 00    	js     f0100305 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100265:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010026b:	f6 c1 40             	test   $0x40,%cl
f010026e:	74 0e                	je     f010027e <kbd_proc_data+0x57>
		data |= 0x80;
f0100270:	83 c8 80             	or     $0xffffff80,%eax
f0100273:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100275:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100278:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f010027e:	0f b6 d2             	movzbl %dl,%edx
f0100281:	0f b6 84 13 b8 08 ff 	movzbl -0xf748(%ebx,%edx,1),%eax
f0100288:	ff 
f0100289:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8c 13 b8 07 ff 	movzbl -0xf848(%ebx,%edx,1),%ecx
f0100296:	ff 
f0100297:	31 c8                	xor    %ecx,%eax
f0100299:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f010029f:	89 c1                	mov    %eax,%ecx
f01002a1:	83 e1 03             	and    $0x3,%ecx
f01002a4:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002ab:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002af:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002b2:	a8 08                	test   $0x8,%al
f01002b4:	74 0d                	je     f01002c3 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f01002b6:	89 f2                	mov    %esi,%edx
f01002b8:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002bb:	83 f9 19             	cmp    $0x19,%ecx
f01002be:	77 7a                	ja     f010033a <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002c0:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002c3:	f7 d0                	not    %eax
f01002c5:	a8 06                	test   $0x6,%al
f01002c7:	75 33                	jne    f01002fc <kbd_proc_data+0xd5>
f01002c9:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002cf:	75 2b                	jne    f01002fc <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f01002d1:	83 ec 0c             	sub    $0xc,%esp
f01002d4:	8d 83 7c 07 ff ff    	lea    -0xf884(%ebx),%eax
f01002da:	50                   	push   %eax
f01002db:	e8 66 07 00 00       	call   f0100a46 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e0:	b8 03 00 00 00       	mov    $0x3,%eax
f01002e5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ea:	ee                   	out    %al,(%dx)
f01002eb:	83 c4 10             	add    $0x10,%esp
f01002ee:	eb 0c                	jmp    f01002fc <kbd_proc_data+0xd5>
		shift |= E0ESC;
f01002f0:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f01002f7:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002fc:	89 f0                	mov    %esi,%eax
f01002fe:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100301:	5b                   	pop    %ebx
f0100302:	5e                   	pop    %esi
f0100303:	5d                   	pop    %ebp
f0100304:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100305:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010030b:	89 ce                	mov    %ecx,%esi
f010030d:	83 e6 40             	and    $0x40,%esi
f0100310:	83 e0 7f             	and    $0x7f,%eax
f0100313:	85 f6                	test   %esi,%esi
f0100315:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100318:	0f b6 d2             	movzbl %dl,%edx
f010031b:	0f b6 84 13 b8 08 ff 	movzbl -0xf748(%ebx,%edx,1),%eax
f0100322:	ff 
f0100323:	83 c8 40             	or     $0x40,%eax
f0100326:	0f b6 c0             	movzbl %al,%eax
f0100329:	f7 d0                	not    %eax
f010032b:	21 c8                	and    %ecx,%eax
f010032d:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f0100333:	be 00 00 00 00       	mov    $0x0,%esi
f0100338:	eb c2                	jmp    f01002fc <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f010033a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010033d:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100340:	83 fa 1a             	cmp    $0x1a,%edx
f0100343:	0f 42 f1             	cmovb  %ecx,%esi
f0100346:	e9 78 ff ff ff       	jmp    f01002c3 <kbd_proc_data+0x9c>
		return -1;
f010034b:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100350:	eb aa                	jmp    f01002fc <kbd_proc_data+0xd5>
		return -1;
f0100352:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100357:	eb a3                	jmp    f01002fc <kbd_proc_data+0xd5>

f0100359 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100359:	55                   	push   %ebp
f010035a:	89 e5                	mov    %esp,%ebp
f010035c:	57                   	push   %edi
f010035d:	56                   	push   %esi
f010035e:	53                   	push   %ebx
f010035f:	83 ec 1c             	sub    $0x1c,%esp
f0100362:	e8 52 fe ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100367:	81 c3 a1 0f 01 00    	add    $0x10fa1,%ebx
f010036d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100370:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100375:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010037a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010037f:	eb 09                	jmp    f010038a <cons_putc+0x31>
f0100381:	89 ca                	mov    %ecx,%edx
f0100383:	ec                   	in     (%dx),%al
f0100384:	ec                   	in     (%dx),%al
f0100385:	ec                   	in     (%dx),%al
f0100386:	ec                   	in     (%dx),%al
	     i++)
f0100387:	83 c6 01             	add    $0x1,%esi
f010038a:	89 fa                	mov    %edi,%edx
f010038c:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010038d:	a8 20                	test   $0x20,%al
f010038f:	75 08                	jne    f0100399 <cons_putc+0x40>
f0100391:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100397:	7e e8                	jle    f0100381 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f0100399:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010039c:	89 f8                	mov    %edi,%eax
f010039e:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003a1:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003a6:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003a7:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ac:	bf 79 03 00 00       	mov    $0x379,%edi
f01003b1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003b6:	eb 09                	jmp    f01003c1 <cons_putc+0x68>
f01003b8:	89 ca                	mov    %ecx,%edx
f01003ba:	ec                   	in     (%dx),%al
f01003bb:	ec                   	in     (%dx),%al
f01003bc:	ec                   	in     (%dx),%al
f01003bd:	ec                   	in     (%dx),%al
f01003be:	83 c6 01             	add    $0x1,%esi
f01003c1:	89 fa                	mov    %edi,%edx
f01003c3:	ec                   	in     (%dx),%al
f01003c4:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003ca:	7f 04                	jg     f01003d0 <cons_putc+0x77>
f01003cc:	84 c0                	test   %al,%al
f01003ce:	79 e8                	jns    f01003b8 <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d0:	ba 78 03 00 00       	mov    $0x378,%edx
f01003d5:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003d9:	ee                   	out    %al,(%dx)
f01003da:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003df:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003e4:	ee                   	out    %al,(%dx)
f01003e5:	b8 08 00 00 00       	mov    $0x8,%eax
f01003ea:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f01003eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003ee:	89 fa                	mov    %edi,%edx
f01003f0:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003f6:	89 f8                	mov    %edi,%eax
f01003f8:	80 cc 07             	or     $0x7,%ah
f01003fb:	85 d2                	test   %edx,%edx
f01003fd:	0f 45 c7             	cmovne %edi,%eax
f0100400:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100403:	0f b6 c0             	movzbl %al,%eax
f0100406:	83 f8 09             	cmp    $0x9,%eax
f0100409:	0f 84 b9 00 00 00    	je     f01004c8 <cons_putc+0x16f>
f010040f:	83 f8 09             	cmp    $0x9,%eax
f0100412:	7e 74                	jle    f0100488 <cons_putc+0x12f>
f0100414:	83 f8 0a             	cmp    $0xa,%eax
f0100417:	0f 84 9e 00 00 00    	je     f01004bb <cons_putc+0x162>
f010041d:	83 f8 0d             	cmp    $0xd,%eax
f0100420:	0f 85 d9 00 00 00    	jne    f01004ff <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100426:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010042d:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100433:	c1 e8 16             	shr    $0x16,%eax
f0100436:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100439:	c1 e0 04             	shl    $0x4,%eax
f010043c:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100443:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f010044a:	cf 07 
f010044c:	0f 87 d4 00 00 00    	ja     f0100526 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100452:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f0100458:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045d:	89 ca                	mov    %ecx,%edx
f010045f:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100460:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f0100467:	8d 71 01             	lea    0x1(%ecx),%esi
f010046a:	89 d8                	mov    %ebx,%eax
f010046c:	66 c1 e8 08          	shr    $0x8,%ax
f0100470:	89 f2                	mov    %esi,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100478:	89 ca                	mov    %ecx,%edx
f010047a:	ee                   	out    %al,(%dx)
f010047b:	89 d8                	mov    %ebx,%eax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100480:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100483:	5b                   	pop    %ebx
f0100484:	5e                   	pop    %esi
f0100485:	5f                   	pop    %edi
f0100486:	5d                   	pop    %ebp
f0100487:	c3                   	ret    
	switch (c & 0xff) {
f0100488:	83 f8 08             	cmp    $0x8,%eax
f010048b:	75 72                	jne    f01004ff <cons_putc+0x1a6>
		if (crt_pos > 0) {
f010048d:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100494:	66 85 c0             	test   %ax,%ax
f0100497:	74 b9                	je     f0100452 <cons_putc+0xf9>
			crt_pos--;
f0100499:	83 e8 01             	sub    $0x1,%eax
f010049c:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a3:	0f b7 c0             	movzwl %ax,%eax
f01004a6:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004aa:	b2 00                	mov    $0x0,%dl
f01004ac:	83 ca 20             	or     $0x20,%edx
f01004af:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01004b5:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004b9:	eb 88                	jmp    f0100443 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f01004bb:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f01004c2:	50 
f01004c3:	e9 5e ff ff ff       	jmp    f0100426 <cons_putc+0xcd>
		cons_putc(' ');
f01004c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01004cd:	e8 87 fe ff ff       	call   f0100359 <cons_putc>
		cons_putc(' ');
f01004d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01004d7:	e8 7d fe ff ff       	call   f0100359 <cons_putc>
		cons_putc(' ');
f01004dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e1:	e8 73 fe ff ff       	call   f0100359 <cons_putc>
		cons_putc(' ');
f01004e6:	b8 20 00 00 00       	mov    $0x20,%eax
f01004eb:	e8 69 fe ff ff       	call   f0100359 <cons_putc>
		cons_putc(' ');
f01004f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f5:	e8 5f fe ff ff       	call   f0100359 <cons_putc>
f01004fa:	e9 44 ff ff ff       	jmp    f0100443 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004ff:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100506:	8d 50 01             	lea    0x1(%eax),%edx
f0100509:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f0100510:	0f b7 c0             	movzwl %ax,%eax
f0100513:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f0100519:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f010051d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100521:	e9 1d ff ff ff       	jmp    f0100443 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100526:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f010052c:	83 ec 04             	sub    $0x4,%esp
f010052f:	68 00 0f 00 00       	push   $0xf00
f0100534:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010053a:	52                   	push   %edx
f010053b:	50                   	push   %eax
f010053c:	e8 b2 10 00 00       	call   f01015f3 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100541:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f0100547:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010054d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100553:	83 c4 10             	add    $0x10,%esp
f0100556:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010055b:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010055e:	39 d0                	cmp    %edx,%eax
f0100560:	75 f4                	jne    f0100556 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100562:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f0100569:	50 
f010056a:	e9 e3 fe ff ff       	jmp    f0100452 <cons_putc+0xf9>

f010056f <serial_intr>:
{
f010056f:	e8 e7 01 00 00       	call   f010075b <__x86.get_pc_thunk.ax>
f0100574:	05 94 0d 01 00       	add    $0x10d94,%eax
	if (serial_exists)
f0100579:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100580:	75 02                	jne    f0100584 <serial_intr+0x15>
f0100582:	f3 c3                	repz ret 
{
f0100584:	55                   	push   %ebp
f0100585:	89 e5                	mov    %esp,%ebp
f0100587:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010058a:	8d 80 b5 ee fe ff    	lea    -0x1114b(%eax),%eax
f0100590:	e8 47 fc ff ff       	call   f01001dc <cons_intr>
}
f0100595:	c9                   	leave  
f0100596:	c3                   	ret    

f0100597 <kbd_intr>:
{
f0100597:	55                   	push   %ebp
f0100598:	89 e5                	mov    %esp,%ebp
f010059a:	83 ec 08             	sub    $0x8,%esp
f010059d:	e8 b9 01 00 00       	call   f010075b <__x86.get_pc_thunk.ax>
f01005a2:	05 66 0d 01 00       	add    $0x10d66,%eax
	cons_intr(kbd_proc_data);
f01005a7:	8d 80 1f ef fe ff    	lea    -0x110e1(%eax),%eax
f01005ad:	e8 2a fc ff ff       	call   f01001dc <cons_intr>
}
f01005b2:	c9                   	leave  
f01005b3:	c3                   	ret    

f01005b4 <cons_getc>:
{
f01005b4:	55                   	push   %ebp
f01005b5:	89 e5                	mov    %esp,%ebp
f01005b7:	53                   	push   %ebx
f01005b8:	83 ec 04             	sub    $0x4,%esp
f01005bb:	e8 f9 fb ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f01005c0:	81 c3 48 0d 01 00    	add    $0x10d48,%ebx
	serial_intr();
f01005c6:	e8 a4 ff ff ff       	call   f010056f <serial_intr>
	kbd_intr();
f01005cb:	e8 c7 ff ff ff       	call   f0100597 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005d0:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f01005d6:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005db:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f01005e1:	74 19                	je     f01005fc <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f01005e3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005e6:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f01005ec:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f01005f3:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005f4:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005fa:	74 06                	je     f0100602 <cons_getc+0x4e>
}
f01005fc:	83 c4 04             	add    $0x4,%esp
f01005ff:	5b                   	pop    %ebx
f0100600:	5d                   	pop    %ebp
f0100601:	c3                   	ret    
			cons.rpos = 0;
f0100602:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f0100609:	00 00 00 
f010060c:	eb ee                	jmp    f01005fc <cons_getc+0x48>

f010060e <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010060e:	55                   	push   %ebp
f010060f:	89 e5                	mov    %esp,%ebp
f0100611:	57                   	push   %edi
f0100612:	56                   	push   %esi
f0100613:	53                   	push   %ebx
f0100614:	83 ec 1c             	sub    $0x1c,%esp
f0100617:	e8 9d fb ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f010061c:	81 c3 ec 0c 01 00    	add    $0x10cec,%ebx
	was = *cp;
f0100622:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100629:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100630:	5a a5 
	if (*cp != 0xA55A) {
f0100632:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100639:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010063d:	0f 84 bc 00 00 00    	je     f01006ff <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f0100643:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f010064a:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010064d:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100654:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f010065a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010065f:	89 fa                	mov    %edi,%edx
f0100661:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100662:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100665:	89 ca                	mov    %ecx,%edx
f0100667:	ec                   	in     (%dx),%al
f0100668:	0f b6 f0             	movzbl %al,%esi
f010066b:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010066e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100673:	89 fa                	mov    %edi,%edx
f0100675:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100676:	89 ca                	mov    %ecx,%edx
f0100678:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100679:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010067c:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100682:	0f b6 c0             	movzbl %al,%eax
f0100685:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100687:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010068e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100693:	89 c8                	mov    %ecx,%eax
f0100695:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010069a:	ee                   	out    %al,(%dx)
f010069b:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006a0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006a5:	89 fa                	mov    %edi,%edx
f01006a7:	ee                   	out    %al,(%dx)
f01006a8:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006ad:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006b2:	ee                   	out    %al,(%dx)
f01006b3:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006b8:	89 c8                	mov    %ecx,%eax
f01006ba:	89 f2                	mov    %esi,%edx
f01006bc:	ee                   	out    %al,(%dx)
f01006bd:	b8 03 00 00 00       	mov    $0x3,%eax
f01006c2:	89 fa                	mov    %edi,%edx
f01006c4:	ee                   	out    %al,(%dx)
f01006c5:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006ca:	89 c8                	mov    %ecx,%eax
f01006cc:	ee                   	out    %al,(%dx)
f01006cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01006d2:	89 f2                	mov    %esi,%edx
f01006d4:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006d5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006da:	ec                   	in     (%dx),%al
f01006db:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006dd:	3c ff                	cmp    $0xff,%al
f01006df:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f01006e6:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006eb:	ec                   	in     (%dx),%al
f01006ec:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006f1:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006f2:	80 f9 ff             	cmp    $0xff,%cl
f01006f5:	74 25                	je     f010071c <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006fa:	5b                   	pop    %ebx
f01006fb:	5e                   	pop    %esi
f01006fc:	5f                   	pop    %edi
f01006fd:	5d                   	pop    %ebp
f01006fe:	c3                   	ret    
		*cp = was;
f01006ff:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100706:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f010070d:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100710:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f0100717:	e9 38 ff ff ff       	jmp    f0100654 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f010071c:	83 ec 0c             	sub    $0xc,%esp
f010071f:	8d 83 88 07 ff ff    	lea    -0xf878(%ebx),%eax
f0100725:	50                   	push   %eax
f0100726:	e8 1b 03 00 00       	call   f0100a46 <cprintf>
f010072b:	83 c4 10             	add    $0x10,%esp
}
f010072e:	eb c7                	jmp    f01006f7 <cons_init+0xe9>

f0100730 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100730:	55                   	push   %ebp
f0100731:	89 e5                	mov    %esp,%ebp
f0100733:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100736:	8b 45 08             	mov    0x8(%ebp),%eax
f0100739:	e8 1b fc ff ff       	call   f0100359 <cons_putc>
}
f010073e:	c9                   	leave  
f010073f:	c3                   	ret    

f0100740 <getchar>:

int
getchar(void)
{
f0100740:	55                   	push   %ebp
f0100741:	89 e5                	mov    %esp,%ebp
f0100743:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100746:	e8 69 fe ff ff       	call   f01005b4 <cons_getc>
f010074b:	85 c0                	test   %eax,%eax
f010074d:	74 f7                	je     f0100746 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010074f:	c9                   	leave  
f0100750:	c3                   	ret    

f0100751 <iscons>:

int
iscons(int fdnum)
{
f0100751:	55                   	push   %ebp
f0100752:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100754:	b8 01 00 00 00       	mov    $0x1,%eax
f0100759:	5d                   	pop    %ebp
f010075a:	c3                   	ret    

f010075b <__x86.get_pc_thunk.ax>:
f010075b:	8b 04 24             	mov    (%esp),%eax
f010075e:	c3                   	ret    

f010075f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075f:	55                   	push   %ebp
f0100760:	89 e5                	mov    %esp,%ebp
f0100762:	56                   	push   %esi
f0100763:	53                   	push   %ebx
f0100764:	e8 50 fa ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100769:	81 c3 9f 0b 01 00    	add    $0x10b9f,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010076f:	83 ec 04             	sub    $0x4,%esp
f0100772:	8d 83 b8 09 ff ff    	lea    -0xf648(%ebx),%eax
f0100778:	50                   	push   %eax
f0100779:	8d 83 d6 09 ff ff    	lea    -0xf62a(%ebx),%eax
f010077f:	50                   	push   %eax
f0100780:	8d b3 db 09 ff ff    	lea    -0xf625(%ebx),%esi
f0100786:	56                   	push   %esi
f0100787:	e8 ba 02 00 00       	call   f0100a46 <cprintf>
f010078c:	83 c4 0c             	add    $0xc,%esp
f010078f:	8d 83 44 0a ff ff    	lea    -0xf5bc(%ebx),%eax
f0100795:	50                   	push   %eax
f0100796:	8d 83 e4 09 ff ff    	lea    -0xf61c(%ebx),%eax
f010079c:	50                   	push   %eax
f010079d:	56                   	push   %esi
f010079e:	e8 a3 02 00 00       	call   f0100a46 <cprintf>
	return 0;
}
f01007a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007ab:	5b                   	pop    %ebx
f01007ac:	5e                   	pop    %esi
f01007ad:	5d                   	pop    %ebp
f01007ae:	c3                   	ret    

f01007af <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007af:	55                   	push   %ebp
f01007b0:	89 e5                	mov    %esp,%ebp
f01007b2:	57                   	push   %edi
f01007b3:	56                   	push   %esi
f01007b4:	53                   	push   %ebx
f01007b5:	83 ec 18             	sub    $0x18,%esp
f01007b8:	e8 fc f9 ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f01007bd:	81 c3 4b 0b 01 00    	add    $0x10b4b,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007c3:	8d 83 ed 09 ff ff    	lea    -0xf613(%ebx),%eax
f01007c9:	50                   	push   %eax
f01007ca:	e8 77 02 00 00       	call   f0100a46 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007cf:	83 c4 08             	add    $0x8,%esp
f01007d2:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007d8:	8d 83 6c 0a ff ff    	lea    -0xf594(%ebx),%eax
f01007de:	50                   	push   %eax
f01007df:	e8 62 02 00 00       	call   f0100a46 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e4:	83 c4 0c             	add    $0xc,%esp
f01007e7:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007ed:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007f3:	50                   	push   %eax
f01007f4:	57                   	push   %edi
f01007f5:	8d 83 94 0a ff ff    	lea    -0xf56c(%ebx),%eax
f01007fb:	50                   	push   %eax
f01007fc:	e8 45 02 00 00       	call   f0100a46 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100801:	83 c4 0c             	add    $0xc,%esp
f0100804:	c7 c0 e9 19 10 f0    	mov    $0xf01019e9,%eax
f010080a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100810:	52                   	push   %edx
f0100811:	50                   	push   %eax
f0100812:	8d 83 b8 0a ff ff    	lea    -0xf548(%ebx),%eax
f0100818:	50                   	push   %eax
f0100819:	e8 28 02 00 00       	call   f0100a46 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010081e:	83 c4 0c             	add    $0xc,%esp
f0100821:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100827:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010082d:	52                   	push   %edx
f010082e:	50                   	push   %eax
f010082f:	8d 83 dc 0a ff ff    	lea    -0xf524(%ebx),%eax
f0100835:	50                   	push   %eax
f0100836:	e8 0b 02 00 00       	call   f0100a46 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010083b:	83 c4 0c             	add    $0xc,%esp
f010083e:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f0100844:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010084a:	50                   	push   %eax
f010084b:	56                   	push   %esi
f010084c:	8d 83 00 0b ff ff    	lea    -0xf500(%ebx),%eax
f0100852:	50                   	push   %eax
f0100853:	e8 ee 01 00 00       	call   f0100a46 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100858:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010085b:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100861:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100863:	c1 fe 0a             	sar    $0xa,%esi
f0100866:	56                   	push   %esi
f0100867:	8d 83 24 0b ff ff    	lea    -0xf4dc(%ebx),%eax
f010086d:	50                   	push   %eax
f010086e:	e8 d3 01 00 00       	call   f0100a46 <cprintf>
	return 0;
}
f0100873:	b8 00 00 00 00       	mov    $0x0,%eax
f0100878:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010087b:	5b                   	pop    %ebx
f010087c:	5e                   	pop    %esi
f010087d:	5f                   	pop    %edi
f010087e:	5d                   	pop    %ebp
f010087f:	c3                   	ret    

f0100880 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100880:	55                   	push   %ebp
f0100881:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100883:	b8 00 00 00 00       	mov    $0x0,%eax
f0100888:	5d                   	pop    %ebp
f0100889:	c3                   	ret    

f010088a <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010088a:	55                   	push   %ebp
f010088b:	89 e5                	mov    %esp,%ebp
f010088d:	57                   	push   %edi
f010088e:	56                   	push   %esi
f010088f:	53                   	push   %ebx
f0100890:	83 ec 68             	sub    $0x68,%esp
f0100893:	e8 21 f9 ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100898:	81 c3 70 0a 01 00    	add    $0x10a70,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010089e:	8d 83 50 0b ff ff    	lea    -0xf4b0(%ebx),%eax
f01008a4:	50                   	push   %eax
f01008a5:	e8 9c 01 00 00       	call   f0100a46 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008aa:	8d 83 74 0b ff ff    	lea    -0xf48c(%ebx),%eax
f01008b0:	89 04 24             	mov    %eax,(%esp)
f01008b3:	e8 8e 01 00 00       	call   f0100a46 <cprintf>
f01008b8:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008bb:	8d bb 0a 0a ff ff    	lea    -0xf5f6(%ebx),%edi
f01008c1:	eb 4a                	jmp    f010090d <monitor+0x83>
f01008c3:	83 ec 08             	sub    $0x8,%esp
f01008c6:	0f be c0             	movsbl %al,%eax
f01008c9:	50                   	push   %eax
f01008ca:	57                   	push   %edi
f01008cb:	e8 99 0c 00 00       	call   f0101569 <strchr>
f01008d0:	83 c4 10             	add    $0x10,%esp
f01008d3:	85 c0                	test   %eax,%eax
f01008d5:	74 08                	je     f01008df <monitor+0x55>
			*buf++ = 0;
f01008d7:	c6 06 00             	movb   $0x0,(%esi)
f01008da:	8d 76 01             	lea    0x1(%esi),%esi
f01008dd:	eb 79                	jmp    f0100958 <monitor+0xce>
		if (*buf == 0)
f01008df:	80 3e 00             	cmpb   $0x0,(%esi)
f01008e2:	74 7f                	je     f0100963 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f01008e4:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01008e8:	74 0f                	je     f01008f9 <monitor+0x6f>
		argv[argc++] = buf;
f01008ea:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01008ed:	8d 48 01             	lea    0x1(%eax),%ecx
f01008f0:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01008f3:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01008f7:	eb 44                	jmp    f010093d <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008f9:	83 ec 08             	sub    $0x8,%esp
f01008fc:	6a 10                	push   $0x10
f01008fe:	8d 83 0f 0a ff ff    	lea    -0xf5f1(%ebx),%eax
f0100904:	50                   	push   %eax
f0100905:	e8 3c 01 00 00       	call   f0100a46 <cprintf>
f010090a:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010090d:	8d 83 06 0a ff ff    	lea    -0xf5fa(%ebx),%eax
f0100913:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100916:	83 ec 0c             	sub    $0xc,%esp
f0100919:	ff 75 a4             	pushl  -0x5c(%ebp)
f010091c:	e8 10 0a 00 00       	call   f0101331 <readline>
f0100921:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100923:	83 c4 10             	add    $0x10,%esp
f0100926:	85 c0                	test   %eax,%eax
f0100928:	74 ec                	je     f0100916 <monitor+0x8c>
	argv[argc] = 0;
f010092a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100931:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100938:	eb 1e                	jmp    f0100958 <monitor+0xce>
			buf++;
f010093a:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010093d:	0f b6 06             	movzbl (%esi),%eax
f0100940:	84 c0                	test   %al,%al
f0100942:	74 14                	je     f0100958 <monitor+0xce>
f0100944:	83 ec 08             	sub    $0x8,%esp
f0100947:	0f be c0             	movsbl %al,%eax
f010094a:	50                   	push   %eax
f010094b:	57                   	push   %edi
f010094c:	e8 18 0c 00 00       	call   f0101569 <strchr>
f0100951:	83 c4 10             	add    $0x10,%esp
f0100954:	85 c0                	test   %eax,%eax
f0100956:	74 e2                	je     f010093a <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100958:	0f b6 06             	movzbl (%esi),%eax
f010095b:	84 c0                	test   %al,%al
f010095d:	0f 85 60 ff ff ff    	jne    f01008c3 <monitor+0x39>
	argv[argc] = 0;
f0100963:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100966:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f010096d:	00 
	if (argc == 0)
f010096e:	85 c0                	test   %eax,%eax
f0100970:	74 9b                	je     f010090d <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100972:	83 ec 08             	sub    $0x8,%esp
f0100975:	8d 83 d6 09 ff ff    	lea    -0xf62a(%ebx),%eax
f010097b:	50                   	push   %eax
f010097c:	ff 75 a8             	pushl  -0x58(%ebp)
f010097f:	e8 87 0b 00 00       	call   f010150b <strcmp>
f0100984:	83 c4 10             	add    $0x10,%esp
f0100987:	85 c0                	test   %eax,%eax
f0100989:	74 38                	je     f01009c3 <monitor+0x139>
f010098b:	83 ec 08             	sub    $0x8,%esp
f010098e:	8d 83 e4 09 ff ff    	lea    -0xf61c(%ebx),%eax
f0100994:	50                   	push   %eax
f0100995:	ff 75 a8             	pushl  -0x58(%ebp)
f0100998:	e8 6e 0b 00 00       	call   f010150b <strcmp>
f010099d:	83 c4 10             	add    $0x10,%esp
f01009a0:	85 c0                	test   %eax,%eax
f01009a2:	74 1a                	je     f01009be <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009a4:	83 ec 08             	sub    $0x8,%esp
f01009a7:	ff 75 a8             	pushl  -0x58(%ebp)
f01009aa:	8d 83 2c 0a ff ff    	lea    -0xf5d4(%ebx),%eax
f01009b0:	50                   	push   %eax
f01009b1:	e8 90 00 00 00       	call   f0100a46 <cprintf>
f01009b6:	83 c4 10             	add    $0x10,%esp
f01009b9:	e9 4f ff ff ff       	jmp    f010090d <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009be:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f01009c3:	83 ec 04             	sub    $0x4,%esp
f01009c6:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01009c9:	ff 75 08             	pushl  0x8(%ebp)
f01009cc:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009cf:	52                   	push   %edx
f01009d0:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009d3:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f01009da:	83 c4 10             	add    $0x10,%esp
f01009dd:	85 c0                	test   %eax,%eax
f01009df:	0f 89 28 ff ff ff    	jns    f010090d <monitor+0x83>
				break;
	}
}
f01009e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009e8:	5b                   	pop    %ebx
f01009e9:	5e                   	pop    %esi
f01009ea:	5f                   	pop    %edi
f01009eb:	5d                   	pop    %ebp
f01009ec:	c3                   	ret    

f01009ed <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009ed:	55                   	push   %ebp
f01009ee:	89 e5                	mov    %esp,%ebp
f01009f0:	53                   	push   %ebx
f01009f1:	83 ec 10             	sub    $0x10,%esp
f01009f4:	e8 c0 f7 ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f01009f9:	81 c3 0f 09 01 00    	add    $0x1090f,%ebx
	cputchar(ch);
f01009ff:	ff 75 08             	pushl  0x8(%ebp)
f0100a02:	e8 29 fd ff ff       	call   f0100730 <cputchar>
	*cnt++;
}
f0100a07:	83 c4 10             	add    $0x10,%esp
f0100a0a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a0d:	c9                   	leave  
f0100a0e:	c3                   	ret    

f0100a0f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a0f:	55                   	push   %ebp
f0100a10:	89 e5                	mov    %esp,%ebp
f0100a12:	53                   	push   %ebx
f0100a13:	83 ec 14             	sub    $0x14,%esp
f0100a16:	e8 9e f7 ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100a1b:	81 c3 ed 08 01 00    	add    $0x108ed,%ebx
	int cnt = 0;
f0100a21:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a28:	ff 75 0c             	pushl  0xc(%ebp)
f0100a2b:	ff 75 08             	pushl  0x8(%ebp)
f0100a2e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a31:	50                   	push   %eax
f0100a32:	8d 83 e5 f6 fe ff    	lea    -0x1091b(%ebx),%eax
f0100a38:	50                   	push   %eax
f0100a39:	e8 1c 04 00 00       	call   f0100e5a <vprintfmt>
	return cnt;
}
f0100a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a41:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a44:	c9                   	leave  
f0100a45:	c3                   	ret    

f0100a46 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a46:	55                   	push   %ebp
f0100a47:	89 e5                	mov    %esp,%ebp
f0100a49:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a4c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a4f:	50                   	push   %eax
f0100a50:	ff 75 08             	pushl  0x8(%ebp)
f0100a53:	e8 b7 ff ff ff       	call   f0100a0f <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a58:	c9                   	leave  
f0100a59:	c3                   	ret    

f0100a5a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a5a:	55                   	push   %ebp
f0100a5b:	89 e5                	mov    %esp,%ebp
f0100a5d:	57                   	push   %edi
f0100a5e:	56                   	push   %esi
f0100a5f:	53                   	push   %ebx
f0100a60:	83 ec 14             	sub    $0x14,%esp
f0100a63:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a66:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a69:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a6c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a6f:	8b 32                	mov    (%edx),%esi
f0100a71:	8b 01                	mov    (%ecx),%eax
f0100a73:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a76:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a7d:	eb 2f                	jmp    f0100aae <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100a7f:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100a82:	39 c6                	cmp    %eax,%esi
f0100a84:	7f 49                	jg     f0100acf <stab_binsearch+0x75>
f0100a86:	0f b6 0a             	movzbl (%edx),%ecx
f0100a89:	83 ea 0c             	sub    $0xc,%edx
f0100a8c:	39 f9                	cmp    %edi,%ecx
f0100a8e:	75 ef                	jne    f0100a7f <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a90:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a93:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a96:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a9a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a9d:	73 35                	jae    f0100ad4 <stab_binsearch+0x7a>
			*region_left = m;
f0100a9f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100aa2:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100aa4:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100aa7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100aae:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100ab1:	7f 4e                	jg     f0100b01 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100ab3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ab6:	01 f0                	add    %esi,%eax
f0100ab8:	89 c3                	mov    %eax,%ebx
f0100aba:	c1 eb 1f             	shr    $0x1f,%ebx
f0100abd:	01 c3                	add    %eax,%ebx
f0100abf:	d1 fb                	sar    %ebx
f0100ac1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ac4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ac7:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100acb:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100acd:	eb b3                	jmp    f0100a82 <stab_binsearch+0x28>
			l = true_m + 1;
f0100acf:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100ad2:	eb da                	jmp    f0100aae <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100ad4:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100ad7:	76 14                	jbe    f0100aed <stab_binsearch+0x93>
			*region_right = m - 1;
f0100ad9:	83 e8 01             	sub    $0x1,%eax
f0100adc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100adf:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ae2:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100ae4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100aeb:	eb c1                	jmp    f0100aae <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aed:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100af0:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100af2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100af6:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100af8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100aff:	eb ad                	jmp    f0100aae <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100b01:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b05:	74 16                	je     f0100b1d <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b07:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b0a:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b0c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b0f:	8b 0e                	mov    (%esi),%ecx
f0100b11:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b14:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b17:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100b1b:	eb 12                	jmp    f0100b2f <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100b1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b20:	8b 00                	mov    (%eax),%eax
f0100b22:	83 e8 01             	sub    $0x1,%eax
f0100b25:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b28:	89 07                	mov    %eax,(%edi)
f0100b2a:	eb 16                	jmp    f0100b42 <stab_binsearch+0xe8>
		     l--)
f0100b2c:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100b2f:	39 c1                	cmp    %eax,%ecx
f0100b31:	7d 0a                	jge    f0100b3d <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100b33:	0f b6 1a             	movzbl (%edx),%ebx
f0100b36:	83 ea 0c             	sub    $0xc,%edx
f0100b39:	39 fb                	cmp    %edi,%ebx
f0100b3b:	75 ef                	jne    f0100b2c <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100b3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b40:	89 07                	mov    %eax,(%edi)
	}
}
f0100b42:	83 c4 14             	add    $0x14,%esp
f0100b45:	5b                   	pop    %ebx
f0100b46:	5e                   	pop    %esi
f0100b47:	5f                   	pop    %edi
f0100b48:	5d                   	pop    %ebp
f0100b49:	c3                   	ret    

f0100b4a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b4a:	55                   	push   %ebp
f0100b4b:	89 e5                	mov    %esp,%ebp
f0100b4d:	57                   	push   %edi
f0100b4e:	56                   	push   %esi
f0100b4f:	53                   	push   %ebx
f0100b50:	83 ec 2c             	sub    $0x2c,%esp
f0100b53:	e8 fa 01 00 00       	call   f0100d52 <__x86.get_pc_thunk.cx>
f0100b58:	81 c1 b0 07 01 00    	add    $0x107b0,%ecx
f0100b5e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100b61:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100b64:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b67:	8d 81 9c 0b ff ff    	lea    -0xf464(%ecx),%eax
f0100b6d:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100b6f:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100b76:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100b79:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100b80:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100b83:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b8a:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100b90:	0f 86 f4 00 00 00    	jbe    f0100c8a <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b96:	c7 c0 49 5c 10 f0    	mov    $0xf0105c49,%eax
f0100b9c:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100ba2:	0f 86 88 01 00 00    	jbe    f0100d30 <debuginfo_eip+0x1e6>
f0100ba8:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100bab:	c7 c0 90 75 10 f0    	mov    $0xf0107590,%eax
f0100bb1:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100bb5:	0f 85 7c 01 00 00    	jne    f0100d37 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bbb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bc2:	c7 c0 c0 20 10 f0    	mov    $0xf01020c0,%eax
f0100bc8:	c7 c2 48 5c 10 f0    	mov    $0xf0105c48,%edx
f0100bce:	29 c2                	sub    %eax,%edx
f0100bd0:	c1 fa 02             	sar    $0x2,%edx
f0100bd3:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100bd9:	83 ea 01             	sub    $0x1,%edx
f0100bdc:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bdf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100be2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100be5:	83 ec 08             	sub    $0x8,%esp
f0100be8:	53                   	push   %ebx
f0100be9:	6a 64                	push   $0x64
f0100beb:	e8 6a fe ff ff       	call   f0100a5a <stab_binsearch>
	if (lfile == 0)
f0100bf0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bf3:	83 c4 10             	add    $0x10,%esp
f0100bf6:	85 c0                	test   %eax,%eax
f0100bf8:	0f 84 40 01 00 00    	je     f0100d3e <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bfe:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c01:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c04:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c07:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c0a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c0d:	83 ec 08             	sub    $0x8,%esp
f0100c10:	53                   	push   %ebx
f0100c11:	6a 24                	push   $0x24
f0100c13:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100c16:	c7 c0 c0 20 10 f0    	mov    $0xf01020c0,%eax
f0100c1c:	e8 39 fe ff ff       	call   f0100a5a <stab_binsearch>

	if (lfun <= rfun) {
f0100c21:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100c24:	83 c4 10             	add    $0x10,%esp
f0100c27:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100c2a:	7f 79                	jg     f0100ca5 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c2c:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c2f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c32:	c7 c2 c0 20 10 f0    	mov    $0xf01020c0,%edx
f0100c38:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100c3b:	8b 11                	mov    (%ecx),%edx
f0100c3d:	c7 c0 90 75 10 f0    	mov    $0xf0107590,%eax
f0100c43:	81 e8 49 5c 10 f0    	sub    $0xf0105c49,%eax
f0100c49:	39 c2                	cmp    %eax,%edx
f0100c4b:	73 09                	jae    f0100c56 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c4d:	81 c2 49 5c 10 f0    	add    $0xf0105c49,%edx
f0100c53:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c56:	8b 41 08             	mov    0x8(%ecx),%eax
f0100c59:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c5c:	83 ec 08             	sub    $0x8,%esp
f0100c5f:	6a 3a                	push   $0x3a
f0100c61:	ff 77 08             	pushl  0x8(%edi)
f0100c64:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c67:	e8 1e 09 00 00       	call   f010158a <strfind>
f0100c6c:	2b 47 08             	sub    0x8(%edi),%eax
f0100c6f:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c72:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c75:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c78:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100c7b:	c7 c2 c0 20 10 f0    	mov    $0xf01020c0,%edx
f0100c81:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100c85:	83 c4 10             	add    $0x10,%esp
f0100c88:	eb 29                	jmp    f0100cb3 <debuginfo_eip+0x169>
  	        panic("User address");
f0100c8a:	83 ec 04             	sub    $0x4,%esp
f0100c8d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c90:	8d 83 a6 0b ff ff    	lea    -0xf45a(%ebx),%eax
f0100c96:	50                   	push   %eax
f0100c97:	6a 7f                	push   $0x7f
f0100c99:	8d 83 b3 0b ff ff    	lea    -0xf44d(%ebx),%eax
f0100c9f:	50                   	push   %eax
f0100ca0:	e8 5e f4 ff ff       	call   f0100103 <_panic>
		info->eip_fn_addr = addr;
f0100ca5:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100ca8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cab:	eb af                	jmp    f0100c5c <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100cad:	83 ee 01             	sub    $0x1,%esi
f0100cb0:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100cb3:	39 f3                	cmp    %esi,%ebx
f0100cb5:	7f 3a                	jg     f0100cf1 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100cb7:	0f b6 10             	movzbl (%eax),%edx
f0100cba:	80 fa 84             	cmp    $0x84,%dl
f0100cbd:	74 0b                	je     f0100cca <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cbf:	80 fa 64             	cmp    $0x64,%dl
f0100cc2:	75 e9                	jne    f0100cad <debuginfo_eip+0x163>
f0100cc4:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100cc8:	74 e3                	je     f0100cad <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cca:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100ccd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cd0:	c7 c0 c0 20 10 f0    	mov    $0xf01020c0,%eax
f0100cd6:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100cd9:	c7 c0 90 75 10 f0    	mov    $0xf0107590,%eax
f0100cdf:	81 e8 49 5c 10 f0    	sub    $0xf0105c49,%eax
f0100ce5:	39 c2                	cmp    %eax,%edx
f0100ce7:	73 08                	jae    f0100cf1 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ce9:	81 c2 49 5c 10 f0    	add    $0xf0105c49,%edx
f0100cef:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cf1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100cf4:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cf7:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100cfc:	39 cb                	cmp    %ecx,%ebx
f0100cfe:	7d 4a                	jge    f0100d4a <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100d00:	8d 53 01             	lea    0x1(%ebx),%edx
f0100d03:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100d06:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d09:	c7 c0 c0 20 10 f0    	mov    $0xf01020c0,%eax
f0100d0f:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100d13:	eb 07                	jmp    f0100d1c <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100d15:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100d19:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100d1c:	39 d1                	cmp    %edx,%ecx
f0100d1e:	74 25                	je     f0100d45 <debuginfo_eip+0x1fb>
f0100d20:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d23:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100d27:	74 ec                	je     f0100d15 <debuginfo_eip+0x1cb>
	return 0;
f0100d29:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d2e:	eb 1a                	jmp    f0100d4a <debuginfo_eip+0x200>
		return -1;
f0100d30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d35:	eb 13                	jmp    f0100d4a <debuginfo_eip+0x200>
f0100d37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d3c:	eb 0c                	jmp    f0100d4a <debuginfo_eip+0x200>
		return -1;
f0100d3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d43:	eb 05                	jmp    f0100d4a <debuginfo_eip+0x200>
	return 0;
f0100d45:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d4a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d4d:	5b                   	pop    %ebx
f0100d4e:	5e                   	pop    %esi
f0100d4f:	5f                   	pop    %edi
f0100d50:	5d                   	pop    %ebp
f0100d51:	c3                   	ret    

f0100d52 <__x86.get_pc_thunk.cx>:
f0100d52:	8b 0c 24             	mov    (%esp),%ecx
f0100d55:	c3                   	ret    

f0100d56 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d56:	55                   	push   %ebp
f0100d57:	89 e5                	mov    %esp,%ebp
f0100d59:	57                   	push   %edi
f0100d5a:	56                   	push   %esi
f0100d5b:	53                   	push   %ebx
f0100d5c:	83 ec 2c             	sub    $0x2c,%esp
f0100d5f:	e8 ee ff ff ff       	call   f0100d52 <__x86.get_pc_thunk.cx>
f0100d64:	81 c1 a4 05 01 00    	add    $0x105a4,%ecx
f0100d6a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100d6d:	89 c7                	mov    %eax,%edi
f0100d6f:	89 d6                	mov    %edx,%esi
f0100d71:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d74:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d77:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d7a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d7d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100d80:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d85:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100d88:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100d8b:	39 d3                	cmp    %edx,%ebx
f0100d8d:	72 09                	jb     f0100d98 <printnum+0x42>
f0100d8f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100d92:	0f 87 83 00 00 00    	ja     f0100e1b <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d98:	83 ec 0c             	sub    $0xc,%esp
f0100d9b:	ff 75 18             	pushl  0x18(%ebp)
f0100d9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100da1:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100da4:	53                   	push   %ebx
f0100da5:	ff 75 10             	pushl  0x10(%ebp)
f0100da8:	83 ec 08             	sub    $0x8,%esp
f0100dab:	ff 75 dc             	pushl  -0x24(%ebp)
f0100dae:	ff 75 d8             	pushl  -0x28(%ebp)
f0100db1:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100db4:	ff 75 d0             	pushl  -0x30(%ebp)
f0100db7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100dba:	e8 f1 09 00 00       	call   f01017b0 <__udivdi3>
f0100dbf:	83 c4 18             	add    $0x18,%esp
f0100dc2:	52                   	push   %edx
f0100dc3:	50                   	push   %eax
f0100dc4:	89 f2                	mov    %esi,%edx
f0100dc6:	89 f8                	mov    %edi,%eax
f0100dc8:	e8 89 ff ff ff       	call   f0100d56 <printnum>
f0100dcd:	83 c4 20             	add    $0x20,%esp
f0100dd0:	eb 13                	jmp    f0100de5 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dd2:	83 ec 08             	sub    $0x8,%esp
f0100dd5:	56                   	push   %esi
f0100dd6:	ff 75 18             	pushl  0x18(%ebp)
f0100dd9:	ff d7                	call   *%edi
f0100ddb:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100dde:	83 eb 01             	sub    $0x1,%ebx
f0100de1:	85 db                	test   %ebx,%ebx
f0100de3:	7f ed                	jg     f0100dd2 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100de5:	83 ec 08             	sub    $0x8,%esp
f0100de8:	56                   	push   %esi
f0100de9:	83 ec 04             	sub    $0x4,%esp
f0100dec:	ff 75 dc             	pushl  -0x24(%ebp)
f0100def:	ff 75 d8             	pushl  -0x28(%ebp)
f0100df2:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100df5:	ff 75 d0             	pushl  -0x30(%ebp)
f0100df8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100dfb:	89 f3                	mov    %esi,%ebx
f0100dfd:	e8 ce 0a 00 00       	call   f01018d0 <__umoddi3>
f0100e02:	83 c4 14             	add    $0x14,%esp
f0100e05:	0f be 84 06 c1 0b ff 	movsbl -0xf43f(%esi,%eax,1),%eax
f0100e0c:	ff 
f0100e0d:	50                   	push   %eax
f0100e0e:	ff d7                	call   *%edi
}
f0100e10:	83 c4 10             	add    $0x10,%esp
f0100e13:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e16:	5b                   	pop    %ebx
f0100e17:	5e                   	pop    %esi
f0100e18:	5f                   	pop    %edi
f0100e19:	5d                   	pop    %ebp
f0100e1a:	c3                   	ret    
f0100e1b:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e1e:	eb be                	jmp    f0100dde <printnum+0x88>

f0100e20 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e20:	55                   	push   %ebp
f0100e21:	89 e5                	mov    %esp,%ebp
f0100e23:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e26:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e2a:	8b 10                	mov    (%eax),%edx
f0100e2c:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e2f:	73 0a                	jae    f0100e3b <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e31:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e34:	89 08                	mov    %ecx,(%eax)
f0100e36:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e39:	88 02                	mov    %al,(%edx)
}
f0100e3b:	5d                   	pop    %ebp
f0100e3c:	c3                   	ret    

f0100e3d <printfmt>:
{
f0100e3d:	55                   	push   %ebp
f0100e3e:	89 e5                	mov    %esp,%ebp
f0100e40:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100e43:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e46:	50                   	push   %eax
f0100e47:	ff 75 10             	pushl  0x10(%ebp)
f0100e4a:	ff 75 0c             	pushl  0xc(%ebp)
f0100e4d:	ff 75 08             	pushl  0x8(%ebp)
f0100e50:	e8 05 00 00 00       	call   f0100e5a <vprintfmt>
}
f0100e55:	83 c4 10             	add    $0x10,%esp
f0100e58:	c9                   	leave  
f0100e59:	c3                   	ret    

f0100e5a <vprintfmt>:
{
f0100e5a:	55                   	push   %ebp
f0100e5b:	89 e5                	mov    %esp,%ebp
f0100e5d:	57                   	push   %edi
f0100e5e:	56                   	push   %esi
f0100e5f:	53                   	push   %ebx
f0100e60:	83 ec 2c             	sub    $0x2c,%esp
f0100e63:	e8 51 f3 ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f0100e68:	81 c3 a0 04 01 00    	add    $0x104a0,%ebx
f0100e6e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e71:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e74:	e9 8e 03 00 00       	jmp    f0101207 <.L35+0x48>
		padc = ' ';
f0100e79:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100e7d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100e84:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0100e8b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100e92:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e97:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100e9a:	8d 47 01             	lea    0x1(%edi),%eax
f0100e9d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ea0:	0f b6 17             	movzbl (%edi),%edx
f0100ea3:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100ea6:	3c 55                	cmp    $0x55,%al
f0100ea8:	0f 87 e1 03 00 00    	ja     f010128f <.L22>
f0100eae:	0f b6 c0             	movzbl %al,%eax
f0100eb1:	89 d9                	mov    %ebx,%ecx
f0100eb3:	03 8c 83 50 0c ff ff 	add    -0xf3b0(%ebx,%eax,4),%ecx
f0100eba:	ff e1                	jmp    *%ecx

f0100ebc <.L67>:
f0100ebc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100ebf:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100ec3:	eb d5                	jmp    f0100e9a <vprintfmt+0x40>

f0100ec5 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100ec8:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100ecc:	eb cc                	jmp    f0100e9a <vprintfmt+0x40>

f0100ece <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ece:	0f b6 d2             	movzbl %dl,%edx
f0100ed1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100ed4:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0100ed9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100edc:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100ee0:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100ee3:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100ee6:	83 f9 09             	cmp    $0x9,%ecx
f0100ee9:	77 55                	ja     f0100f40 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0100eeb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100eee:	eb e9                	jmp    f0100ed9 <.L29+0xb>

f0100ef0 <.L26>:
			precision = va_arg(ap, int);
f0100ef0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ef3:	8b 00                	mov    (%eax),%eax
f0100ef5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ef8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100efb:	8d 40 04             	lea    0x4(%eax),%eax
f0100efe:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100f04:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f08:	79 90                	jns    f0100e9a <vprintfmt+0x40>
				width = precision, precision = -1;
f0100f0a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f0d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f10:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f17:	eb 81                	jmp    f0100e9a <vprintfmt+0x40>

f0100f19 <.L27>:
f0100f19:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f1c:	85 c0                	test   %eax,%eax
f0100f1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f23:	0f 49 d0             	cmovns %eax,%edx
f0100f26:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f2c:	e9 69 ff ff ff       	jmp    f0100e9a <vprintfmt+0x40>

f0100f31 <.L23>:
f0100f31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0100f34:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f3b:	e9 5a ff ff ff       	jmp    f0100e9a <vprintfmt+0x40>
f0100f40:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f43:	eb bf                	jmp    f0100f04 <.L26+0x14>

f0100f45 <.L33>:
			lflag++;
f0100f45:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0100f4c:	e9 49 ff ff ff       	jmp    f0100e9a <vprintfmt+0x40>

f0100f51 <.L30>:
			putch(va_arg(ap, int), putdat);
f0100f51:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f54:	8d 78 04             	lea    0x4(%eax),%edi
f0100f57:	83 ec 08             	sub    $0x8,%esp
f0100f5a:	56                   	push   %esi
f0100f5b:	ff 30                	pushl  (%eax)
f0100f5d:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f60:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100f63:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100f66:	e9 99 02 00 00       	jmp    f0101204 <.L35+0x45>

f0100f6b <.L32>:
			err = va_arg(ap, int);
f0100f6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f6e:	8d 78 04             	lea    0x4(%eax),%edi
f0100f71:	8b 00                	mov    (%eax),%eax
f0100f73:	99                   	cltd   
f0100f74:	31 d0                	xor    %edx,%eax
f0100f76:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f78:	83 f8 06             	cmp    $0x6,%eax
f0100f7b:	7f 27                	jg     f0100fa4 <.L32+0x39>
f0100f7d:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0100f84:	85 d2                	test   %edx,%edx
f0100f86:	74 1c                	je     f0100fa4 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0100f88:	52                   	push   %edx
f0100f89:	8d 83 e2 0b ff ff    	lea    -0xf41e(%ebx),%eax
f0100f8f:	50                   	push   %eax
f0100f90:	56                   	push   %esi
f0100f91:	ff 75 08             	pushl  0x8(%ebp)
f0100f94:	e8 a4 fe ff ff       	call   f0100e3d <printfmt>
f0100f99:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100f9c:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100f9f:	e9 60 02 00 00       	jmp    f0101204 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0100fa4:	50                   	push   %eax
f0100fa5:	8d 83 d9 0b ff ff    	lea    -0xf427(%ebx),%eax
f0100fab:	50                   	push   %eax
f0100fac:	56                   	push   %esi
f0100fad:	ff 75 08             	pushl  0x8(%ebp)
f0100fb0:	e8 88 fe ff ff       	call   f0100e3d <printfmt>
f0100fb5:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fb8:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100fbb:	e9 44 02 00 00       	jmp    f0101204 <.L35+0x45>

f0100fc0 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0100fc0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc3:	83 c0 04             	add    $0x4,%eax
f0100fc6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100fc9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fcc:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100fce:	85 ff                	test   %edi,%edi
f0100fd0:	8d 83 d2 0b ff ff    	lea    -0xf42e(%ebx),%eax
f0100fd6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100fd9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fdd:	0f 8e b5 00 00 00    	jle    f0101098 <.L36+0xd8>
f0100fe3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100fe7:	75 08                	jne    f0100ff1 <.L36+0x31>
f0100fe9:	89 75 0c             	mov    %esi,0xc(%ebp)
f0100fec:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fef:	eb 6d                	jmp    f010105e <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ff1:	83 ec 08             	sub    $0x8,%esp
f0100ff4:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ff7:	57                   	push   %edi
f0100ff8:	e8 49 04 00 00       	call   f0101446 <strnlen>
f0100ffd:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101000:	29 c2                	sub    %eax,%edx
f0101002:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101005:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101008:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010100c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010100f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101012:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101014:	eb 10                	jmp    f0101026 <.L36+0x66>
					putch(padc, putdat);
f0101016:	83 ec 08             	sub    $0x8,%esp
f0101019:	56                   	push   %esi
f010101a:	ff 75 e0             	pushl  -0x20(%ebp)
f010101d:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101020:	83 ef 01             	sub    $0x1,%edi
f0101023:	83 c4 10             	add    $0x10,%esp
f0101026:	85 ff                	test   %edi,%edi
f0101028:	7f ec                	jg     f0101016 <.L36+0x56>
f010102a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010102d:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101030:	85 d2                	test   %edx,%edx
f0101032:	b8 00 00 00 00       	mov    $0x0,%eax
f0101037:	0f 49 c2             	cmovns %edx,%eax
f010103a:	29 c2                	sub    %eax,%edx
f010103c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010103f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101042:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101045:	eb 17                	jmp    f010105e <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101047:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010104b:	75 30                	jne    f010107d <.L36+0xbd>
					putch(ch, putdat);
f010104d:	83 ec 08             	sub    $0x8,%esp
f0101050:	ff 75 0c             	pushl  0xc(%ebp)
f0101053:	50                   	push   %eax
f0101054:	ff 55 08             	call   *0x8(%ebp)
f0101057:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010105a:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010105e:	83 c7 01             	add    $0x1,%edi
f0101061:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101065:	0f be c2             	movsbl %dl,%eax
f0101068:	85 c0                	test   %eax,%eax
f010106a:	74 52                	je     f01010be <.L36+0xfe>
f010106c:	85 f6                	test   %esi,%esi
f010106e:	78 d7                	js     f0101047 <.L36+0x87>
f0101070:	83 ee 01             	sub    $0x1,%esi
f0101073:	79 d2                	jns    f0101047 <.L36+0x87>
f0101075:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101078:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010107b:	eb 32                	jmp    f01010af <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010107d:	0f be d2             	movsbl %dl,%edx
f0101080:	83 ea 20             	sub    $0x20,%edx
f0101083:	83 fa 5e             	cmp    $0x5e,%edx
f0101086:	76 c5                	jbe    f010104d <.L36+0x8d>
					putch('?', putdat);
f0101088:	83 ec 08             	sub    $0x8,%esp
f010108b:	ff 75 0c             	pushl  0xc(%ebp)
f010108e:	6a 3f                	push   $0x3f
f0101090:	ff 55 08             	call   *0x8(%ebp)
f0101093:	83 c4 10             	add    $0x10,%esp
f0101096:	eb c2                	jmp    f010105a <.L36+0x9a>
f0101098:	89 75 0c             	mov    %esi,0xc(%ebp)
f010109b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010109e:	eb be                	jmp    f010105e <.L36+0x9e>
				putch(' ', putdat);
f01010a0:	83 ec 08             	sub    $0x8,%esp
f01010a3:	56                   	push   %esi
f01010a4:	6a 20                	push   $0x20
f01010a6:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01010a9:	83 ef 01             	sub    $0x1,%edi
f01010ac:	83 c4 10             	add    $0x10,%esp
f01010af:	85 ff                	test   %edi,%edi
f01010b1:	7f ed                	jg     f01010a0 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01010b3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01010b6:	89 45 14             	mov    %eax,0x14(%ebp)
f01010b9:	e9 46 01 00 00       	jmp    f0101204 <.L35+0x45>
f01010be:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01010c1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010c4:	eb e9                	jmp    f01010af <.L36+0xef>

f01010c6 <.L31>:
f01010c6:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01010c9:	83 f9 01             	cmp    $0x1,%ecx
f01010cc:	7e 40                	jle    f010110e <.L31+0x48>
		return va_arg(*ap, long long);
f01010ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d1:	8b 50 04             	mov    0x4(%eax),%edx
f01010d4:	8b 00                	mov    (%eax),%eax
f01010d6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010d9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01010df:	8d 40 08             	lea    0x8(%eax),%eax
f01010e2:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01010e5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010e9:	79 55                	jns    f0101140 <.L31+0x7a>
				putch('-', putdat);
f01010eb:	83 ec 08             	sub    $0x8,%esp
f01010ee:	56                   	push   %esi
f01010ef:	6a 2d                	push   $0x2d
f01010f1:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01010f4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01010f7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01010fa:	f7 da                	neg    %edx
f01010fc:	83 d1 00             	adc    $0x0,%ecx
f01010ff:	f7 d9                	neg    %ecx
f0101101:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101104:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101109:	e9 db 00 00 00       	jmp    f01011e9 <.L35+0x2a>
	else if (lflag)
f010110e:	85 c9                	test   %ecx,%ecx
f0101110:	75 17                	jne    f0101129 <.L31+0x63>
		return va_arg(*ap, int);
f0101112:	8b 45 14             	mov    0x14(%ebp),%eax
f0101115:	8b 00                	mov    (%eax),%eax
f0101117:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010111a:	99                   	cltd   
f010111b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010111e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101121:	8d 40 04             	lea    0x4(%eax),%eax
f0101124:	89 45 14             	mov    %eax,0x14(%ebp)
f0101127:	eb bc                	jmp    f01010e5 <.L31+0x1f>
		return va_arg(*ap, long);
f0101129:	8b 45 14             	mov    0x14(%ebp),%eax
f010112c:	8b 00                	mov    (%eax),%eax
f010112e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101131:	99                   	cltd   
f0101132:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101135:	8b 45 14             	mov    0x14(%ebp),%eax
f0101138:	8d 40 04             	lea    0x4(%eax),%eax
f010113b:	89 45 14             	mov    %eax,0x14(%ebp)
f010113e:	eb a5                	jmp    f01010e5 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101140:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101143:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101146:	b8 0a 00 00 00       	mov    $0xa,%eax
f010114b:	e9 99 00 00 00       	jmp    f01011e9 <.L35+0x2a>

f0101150 <.L37>:
f0101150:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101153:	83 f9 01             	cmp    $0x1,%ecx
f0101156:	7e 15                	jle    f010116d <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0101158:	8b 45 14             	mov    0x14(%ebp),%eax
f010115b:	8b 10                	mov    (%eax),%edx
f010115d:	8b 48 04             	mov    0x4(%eax),%ecx
f0101160:	8d 40 08             	lea    0x8(%eax),%eax
f0101163:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101166:	b8 0a 00 00 00       	mov    $0xa,%eax
f010116b:	eb 7c                	jmp    f01011e9 <.L35+0x2a>
	else if (lflag)
f010116d:	85 c9                	test   %ecx,%ecx
f010116f:	75 17                	jne    f0101188 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0101171:	8b 45 14             	mov    0x14(%ebp),%eax
f0101174:	8b 10                	mov    (%eax),%edx
f0101176:	b9 00 00 00 00       	mov    $0x0,%ecx
f010117b:	8d 40 04             	lea    0x4(%eax),%eax
f010117e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101181:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101186:	eb 61                	jmp    f01011e9 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101188:	8b 45 14             	mov    0x14(%ebp),%eax
f010118b:	8b 10                	mov    (%eax),%edx
f010118d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101192:	8d 40 04             	lea    0x4(%eax),%eax
f0101195:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101198:	b8 0a 00 00 00       	mov    $0xa,%eax
f010119d:	eb 4a                	jmp    f01011e9 <.L35+0x2a>

f010119f <.L34>:
			putch('X', putdat);
f010119f:	83 ec 08             	sub    $0x8,%esp
f01011a2:	56                   	push   %esi
f01011a3:	6a 58                	push   $0x58
f01011a5:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01011a8:	83 c4 08             	add    $0x8,%esp
f01011ab:	56                   	push   %esi
f01011ac:	6a 58                	push   $0x58
f01011ae:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01011b1:	83 c4 08             	add    $0x8,%esp
f01011b4:	56                   	push   %esi
f01011b5:	6a 58                	push   $0x58
f01011b7:	ff 55 08             	call   *0x8(%ebp)
			break;
f01011ba:	83 c4 10             	add    $0x10,%esp
f01011bd:	eb 45                	jmp    f0101204 <.L35+0x45>

f01011bf <.L35>:
			putch('0', putdat);
f01011bf:	83 ec 08             	sub    $0x8,%esp
f01011c2:	56                   	push   %esi
f01011c3:	6a 30                	push   $0x30
f01011c5:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011c8:	83 c4 08             	add    $0x8,%esp
f01011cb:	56                   	push   %esi
f01011cc:	6a 78                	push   $0x78
f01011ce:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01011d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d4:	8b 10                	mov    (%eax),%edx
f01011d6:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f01011db:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01011de:	8d 40 04             	lea    0x4(%eax),%eax
f01011e1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01011e4:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01011e9:	83 ec 0c             	sub    $0xc,%esp
f01011ec:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01011f0:	57                   	push   %edi
f01011f1:	ff 75 e0             	pushl  -0x20(%ebp)
f01011f4:	50                   	push   %eax
f01011f5:	51                   	push   %ecx
f01011f6:	52                   	push   %edx
f01011f7:	89 f2                	mov    %esi,%edx
f01011f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01011fc:	e8 55 fb ff ff       	call   f0100d56 <printnum>
			break;
f0101201:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101204:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101207:	83 c7 01             	add    $0x1,%edi
f010120a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010120e:	83 f8 25             	cmp    $0x25,%eax
f0101211:	0f 84 62 fc ff ff    	je     f0100e79 <vprintfmt+0x1f>
			if (ch == '\0')
f0101217:	85 c0                	test   %eax,%eax
f0101219:	0f 84 91 00 00 00    	je     f01012b0 <.L22+0x21>
			putch(ch, putdat);
f010121f:	83 ec 08             	sub    $0x8,%esp
f0101222:	56                   	push   %esi
f0101223:	50                   	push   %eax
f0101224:	ff 55 08             	call   *0x8(%ebp)
f0101227:	83 c4 10             	add    $0x10,%esp
f010122a:	eb db                	jmp    f0101207 <.L35+0x48>

f010122c <.L38>:
f010122c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f010122f:	83 f9 01             	cmp    $0x1,%ecx
f0101232:	7e 15                	jle    f0101249 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0101234:	8b 45 14             	mov    0x14(%ebp),%eax
f0101237:	8b 10                	mov    (%eax),%edx
f0101239:	8b 48 04             	mov    0x4(%eax),%ecx
f010123c:	8d 40 08             	lea    0x8(%eax),%eax
f010123f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101242:	b8 10 00 00 00       	mov    $0x10,%eax
f0101247:	eb a0                	jmp    f01011e9 <.L35+0x2a>
	else if (lflag)
f0101249:	85 c9                	test   %ecx,%ecx
f010124b:	75 17                	jne    f0101264 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f010124d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101250:	8b 10                	mov    (%eax),%edx
f0101252:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101257:	8d 40 04             	lea    0x4(%eax),%eax
f010125a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010125d:	b8 10 00 00 00       	mov    $0x10,%eax
f0101262:	eb 85                	jmp    f01011e9 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101264:	8b 45 14             	mov    0x14(%ebp),%eax
f0101267:	8b 10                	mov    (%eax),%edx
f0101269:	b9 00 00 00 00       	mov    $0x0,%ecx
f010126e:	8d 40 04             	lea    0x4(%eax),%eax
f0101271:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101274:	b8 10 00 00 00       	mov    $0x10,%eax
f0101279:	e9 6b ff ff ff       	jmp    f01011e9 <.L35+0x2a>

f010127e <.L25>:
			putch(ch, putdat);
f010127e:	83 ec 08             	sub    $0x8,%esp
f0101281:	56                   	push   %esi
f0101282:	6a 25                	push   $0x25
f0101284:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101287:	83 c4 10             	add    $0x10,%esp
f010128a:	e9 75 ff ff ff       	jmp    f0101204 <.L35+0x45>

f010128f <.L22>:
			putch('%', putdat);
f010128f:	83 ec 08             	sub    $0x8,%esp
f0101292:	56                   	push   %esi
f0101293:	6a 25                	push   $0x25
f0101295:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101298:	83 c4 10             	add    $0x10,%esp
f010129b:	89 f8                	mov    %edi,%eax
f010129d:	eb 03                	jmp    f01012a2 <.L22+0x13>
f010129f:	83 e8 01             	sub    $0x1,%eax
f01012a2:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01012a6:	75 f7                	jne    f010129f <.L22+0x10>
f01012a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012ab:	e9 54 ff ff ff       	jmp    f0101204 <.L35+0x45>
}
f01012b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012b3:	5b                   	pop    %ebx
f01012b4:	5e                   	pop    %esi
f01012b5:	5f                   	pop    %edi
f01012b6:	5d                   	pop    %ebp
f01012b7:	c3                   	ret    

f01012b8 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012b8:	55                   	push   %ebp
f01012b9:	89 e5                	mov    %esp,%ebp
f01012bb:	53                   	push   %ebx
f01012bc:	83 ec 14             	sub    $0x14,%esp
f01012bf:	e8 f5 ee ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f01012c4:	81 c3 44 00 01 00    	add    $0x10044,%ebx
f01012ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01012cd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012d0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012d3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012d7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012e1:	85 c0                	test   %eax,%eax
f01012e3:	74 2b                	je     f0101310 <vsnprintf+0x58>
f01012e5:	85 d2                	test   %edx,%edx
f01012e7:	7e 27                	jle    f0101310 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012e9:	ff 75 14             	pushl  0x14(%ebp)
f01012ec:	ff 75 10             	pushl  0x10(%ebp)
f01012ef:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012f2:	50                   	push   %eax
f01012f3:	8d 83 18 fb fe ff    	lea    -0x104e8(%ebx),%eax
f01012f9:	50                   	push   %eax
f01012fa:	e8 5b fb ff ff       	call   f0100e5a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101302:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101305:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101308:	83 c4 10             	add    $0x10,%esp
}
f010130b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010130e:	c9                   	leave  
f010130f:	c3                   	ret    
		return -E_INVAL;
f0101310:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101315:	eb f4                	jmp    f010130b <vsnprintf+0x53>

f0101317 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101317:	55                   	push   %ebp
f0101318:	89 e5                	mov    %esp,%ebp
f010131a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010131d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101320:	50                   	push   %eax
f0101321:	ff 75 10             	pushl  0x10(%ebp)
f0101324:	ff 75 0c             	pushl  0xc(%ebp)
f0101327:	ff 75 08             	pushl  0x8(%ebp)
f010132a:	e8 89 ff ff ff       	call   f01012b8 <vsnprintf>
	va_end(ap);

	return rc;
}
f010132f:	c9                   	leave  
f0101330:	c3                   	ret    

f0101331 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101331:	55                   	push   %ebp
f0101332:	89 e5                	mov    %esp,%ebp
f0101334:	57                   	push   %edi
f0101335:	56                   	push   %esi
f0101336:	53                   	push   %ebx
f0101337:	83 ec 1c             	sub    $0x1c,%esp
f010133a:	e8 7a ee ff ff       	call   f01001b9 <__x86.get_pc_thunk.bx>
f010133f:	81 c3 c9 ff 00 00    	add    $0xffc9,%ebx
f0101345:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101348:	85 c0                	test   %eax,%eax
f010134a:	74 13                	je     f010135f <readline+0x2e>
		cprintf("%s", prompt);
f010134c:	83 ec 08             	sub    $0x8,%esp
f010134f:	50                   	push   %eax
f0101350:	8d 83 e2 0b ff ff    	lea    -0xf41e(%ebx),%eax
f0101356:	50                   	push   %eax
f0101357:	e8 ea f6 ff ff       	call   f0100a46 <cprintf>
f010135c:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010135f:	83 ec 0c             	sub    $0xc,%esp
f0101362:	6a 00                	push   $0x0
f0101364:	e8 e8 f3 ff ff       	call   f0100751 <iscons>
f0101369:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010136c:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010136f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101374:	eb 46                	jmp    f01013bc <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101376:	83 ec 08             	sub    $0x8,%esp
f0101379:	50                   	push   %eax
f010137a:	8d 83 a8 0d ff ff    	lea    -0xf258(%ebx),%eax
f0101380:	50                   	push   %eax
f0101381:	e8 c0 f6 ff ff       	call   f0100a46 <cprintf>
			return NULL;
f0101386:	83 c4 10             	add    $0x10,%esp
f0101389:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010138e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101391:	5b                   	pop    %ebx
f0101392:	5e                   	pop    %esi
f0101393:	5f                   	pop    %edi
f0101394:	5d                   	pop    %ebp
f0101395:	c3                   	ret    
			if (echoing)
f0101396:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010139a:	75 05                	jne    f01013a1 <readline+0x70>
			i--;
f010139c:	83 ef 01             	sub    $0x1,%edi
f010139f:	eb 1b                	jmp    f01013bc <readline+0x8b>
				cputchar('\b');
f01013a1:	83 ec 0c             	sub    $0xc,%esp
f01013a4:	6a 08                	push   $0x8
f01013a6:	e8 85 f3 ff ff       	call   f0100730 <cputchar>
f01013ab:	83 c4 10             	add    $0x10,%esp
f01013ae:	eb ec                	jmp    f010139c <readline+0x6b>
			buf[i++] = c;
f01013b0:	89 f0                	mov    %esi,%eax
f01013b2:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f01013b9:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01013bc:	e8 7f f3 ff ff       	call   f0100740 <getchar>
f01013c1:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01013c3:	85 c0                	test   %eax,%eax
f01013c5:	78 af                	js     f0101376 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013c7:	83 f8 08             	cmp    $0x8,%eax
f01013ca:	0f 94 c2             	sete   %dl
f01013cd:	83 f8 7f             	cmp    $0x7f,%eax
f01013d0:	0f 94 c0             	sete   %al
f01013d3:	08 c2                	or     %al,%dl
f01013d5:	74 04                	je     f01013db <readline+0xaa>
f01013d7:	85 ff                	test   %edi,%edi
f01013d9:	7f bb                	jg     f0101396 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013db:	83 fe 1f             	cmp    $0x1f,%esi
f01013de:	7e 1c                	jle    f01013fc <readline+0xcb>
f01013e0:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01013e6:	7f 14                	jg     f01013fc <readline+0xcb>
			if (echoing)
f01013e8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013ec:	74 c2                	je     f01013b0 <readline+0x7f>
				cputchar(c);
f01013ee:	83 ec 0c             	sub    $0xc,%esp
f01013f1:	56                   	push   %esi
f01013f2:	e8 39 f3 ff ff       	call   f0100730 <cputchar>
f01013f7:	83 c4 10             	add    $0x10,%esp
f01013fa:	eb b4                	jmp    f01013b0 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01013fc:	83 fe 0a             	cmp    $0xa,%esi
f01013ff:	74 05                	je     f0101406 <readline+0xd5>
f0101401:	83 fe 0d             	cmp    $0xd,%esi
f0101404:	75 b6                	jne    f01013bc <readline+0x8b>
			if (echoing)
f0101406:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010140a:	75 13                	jne    f010141f <readline+0xee>
			buf[i] = 0;
f010140c:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f0101413:	00 
			return buf;
f0101414:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f010141a:	e9 6f ff ff ff       	jmp    f010138e <readline+0x5d>
				cputchar('\n');
f010141f:	83 ec 0c             	sub    $0xc,%esp
f0101422:	6a 0a                	push   $0xa
f0101424:	e8 07 f3 ff ff       	call   f0100730 <cputchar>
f0101429:	83 c4 10             	add    $0x10,%esp
f010142c:	eb de                	jmp    f010140c <readline+0xdb>

f010142e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010142e:	55                   	push   %ebp
f010142f:	89 e5                	mov    %esp,%ebp
f0101431:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101434:	b8 00 00 00 00       	mov    $0x0,%eax
f0101439:	eb 03                	jmp    f010143e <strlen+0x10>
		n++;
f010143b:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f010143e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101442:	75 f7                	jne    f010143b <strlen+0xd>
	return n;
}
f0101444:	5d                   	pop    %ebp
f0101445:	c3                   	ret    

f0101446 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101446:	55                   	push   %ebp
f0101447:	89 e5                	mov    %esp,%ebp
f0101449:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010144c:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010144f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101454:	eb 03                	jmp    f0101459 <strnlen+0x13>
		n++;
f0101456:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101459:	39 d0                	cmp    %edx,%eax
f010145b:	74 06                	je     f0101463 <strnlen+0x1d>
f010145d:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101461:	75 f3                	jne    f0101456 <strnlen+0x10>
	return n;
}
f0101463:	5d                   	pop    %ebp
f0101464:	c3                   	ret    

f0101465 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101465:	55                   	push   %ebp
f0101466:	89 e5                	mov    %esp,%ebp
f0101468:	53                   	push   %ebx
f0101469:	8b 45 08             	mov    0x8(%ebp),%eax
f010146c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010146f:	89 c2                	mov    %eax,%edx
f0101471:	83 c1 01             	add    $0x1,%ecx
f0101474:	83 c2 01             	add    $0x1,%edx
f0101477:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010147b:	88 5a ff             	mov    %bl,-0x1(%edx)
f010147e:	84 db                	test   %bl,%bl
f0101480:	75 ef                	jne    f0101471 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101482:	5b                   	pop    %ebx
f0101483:	5d                   	pop    %ebp
f0101484:	c3                   	ret    

f0101485 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101485:	55                   	push   %ebp
f0101486:	89 e5                	mov    %esp,%ebp
f0101488:	53                   	push   %ebx
f0101489:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010148c:	53                   	push   %ebx
f010148d:	e8 9c ff ff ff       	call   f010142e <strlen>
f0101492:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101495:	ff 75 0c             	pushl  0xc(%ebp)
f0101498:	01 d8                	add    %ebx,%eax
f010149a:	50                   	push   %eax
f010149b:	e8 c5 ff ff ff       	call   f0101465 <strcpy>
	return dst;
}
f01014a0:	89 d8                	mov    %ebx,%eax
f01014a2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014a5:	c9                   	leave  
f01014a6:	c3                   	ret    

f01014a7 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014a7:	55                   	push   %ebp
f01014a8:	89 e5                	mov    %esp,%ebp
f01014aa:	56                   	push   %esi
f01014ab:	53                   	push   %ebx
f01014ac:	8b 75 08             	mov    0x8(%ebp),%esi
f01014af:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014b2:	89 f3                	mov    %esi,%ebx
f01014b4:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014b7:	89 f2                	mov    %esi,%edx
f01014b9:	eb 0f                	jmp    f01014ca <strncpy+0x23>
		*dst++ = *src;
f01014bb:	83 c2 01             	add    $0x1,%edx
f01014be:	0f b6 01             	movzbl (%ecx),%eax
f01014c1:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014c4:	80 39 01             	cmpb   $0x1,(%ecx)
f01014c7:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01014ca:	39 da                	cmp    %ebx,%edx
f01014cc:	75 ed                	jne    f01014bb <strncpy+0x14>
	}
	return ret;
}
f01014ce:	89 f0                	mov    %esi,%eax
f01014d0:	5b                   	pop    %ebx
f01014d1:	5e                   	pop    %esi
f01014d2:	5d                   	pop    %ebp
f01014d3:	c3                   	ret    

f01014d4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014d4:	55                   	push   %ebp
f01014d5:	89 e5                	mov    %esp,%ebp
f01014d7:	56                   	push   %esi
f01014d8:	53                   	push   %ebx
f01014d9:	8b 75 08             	mov    0x8(%ebp),%esi
f01014dc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014df:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01014e2:	89 f0                	mov    %esi,%eax
f01014e4:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014e8:	85 c9                	test   %ecx,%ecx
f01014ea:	75 0b                	jne    f01014f7 <strlcpy+0x23>
f01014ec:	eb 17                	jmp    f0101505 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014ee:	83 c2 01             	add    $0x1,%edx
f01014f1:	83 c0 01             	add    $0x1,%eax
f01014f4:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01014f7:	39 d8                	cmp    %ebx,%eax
f01014f9:	74 07                	je     f0101502 <strlcpy+0x2e>
f01014fb:	0f b6 0a             	movzbl (%edx),%ecx
f01014fe:	84 c9                	test   %cl,%cl
f0101500:	75 ec                	jne    f01014ee <strlcpy+0x1a>
		*dst = '\0';
f0101502:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101505:	29 f0                	sub    %esi,%eax
}
f0101507:	5b                   	pop    %ebx
f0101508:	5e                   	pop    %esi
f0101509:	5d                   	pop    %ebp
f010150a:	c3                   	ret    

f010150b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010150b:	55                   	push   %ebp
f010150c:	89 e5                	mov    %esp,%ebp
f010150e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101511:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101514:	eb 06                	jmp    f010151c <strcmp+0x11>
		p++, q++;
f0101516:	83 c1 01             	add    $0x1,%ecx
f0101519:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010151c:	0f b6 01             	movzbl (%ecx),%eax
f010151f:	84 c0                	test   %al,%al
f0101521:	74 04                	je     f0101527 <strcmp+0x1c>
f0101523:	3a 02                	cmp    (%edx),%al
f0101525:	74 ef                	je     f0101516 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101527:	0f b6 c0             	movzbl %al,%eax
f010152a:	0f b6 12             	movzbl (%edx),%edx
f010152d:	29 d0                	sub    %edx,%eax
}
f010152f:	5d                   	pop    %ebp
f0101530:	c3                   	ret    

f0101531 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101531:	55                   	push   %ebp
f0101532:	89 e5                	mov    %esp,%ebp
f0101534:	53                   	push   %ebx
f0101535:	8b 45 08             	mov    0x8(%ebp),%eax
f0101538:	8b 55 0c             	mov    0xc(%ebp),%edx
f010153b:	89 c3                	mov    %eax,%ebx
f010153d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101540:	eb 06                	jmp    f0101548 <strncmp+0x17>
		n--, p++, q++;
f0101542:	83 c0 01             	add    $0x1,%eax
f0101545:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101548:	39 d8                	cmp    %ebx,%eax
f010154a:	74 16                	je     f0101562 <strncmp+0x31>
f010154c:	0f b6 08             	movzbl (%eax),%ecx
f010154f:	84 c9                	test   %cl,%cl
f0101551:	74 04                	je     f0101557 <strncmp+0x26>
f0101553:	3a 0a                	cmp    (%edx),%cl
f0101555:	74 eb                	je     f0101542 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101557:	0f b6 00             	movzbl (%eax),%eax
f010155a:	0f b6 12             	movzbl (%edx),%edx
f010155d:	29 d0                	sub    %edx,%eax
}
f010155f:	5b                   	pop    %ebx
f0101560:	5d                   	pop    %ebp
f0101561:	c3                   	ret    
		return 0;
f0101562:	b8 00 00 00 00       	mov    $0x0,%eax
f0101567:	eb f6                	jmp    f010155f <strncmp+0x2e>

f0101569 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101569:	55                   	push   %ebp
f010156a:	89 e5                	mov    %esp,%ebp
f010156c:	8b 45 08             	mov    0x8(%ebp),%eax
f010156f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101573:	0f b6 10             	movzbl (%eax),%edx
f0101576:	84 d2                	test   %dl,%dl
f0101578:	74 09                	je     f0101583 <strchr+0x1a>
		if (*s == c)
f010157a:	38 ca                	cmp    %cl,%dl
f010157c:	74 0a                	je     f0101588 <strchr+0x1f>
	for (; *s; s++)
f010157e:	83 c0 01             	add    $0x1,%eax
f0101581:	eb f0                	jmp    f0101573 <strchr+0xa>
			return (char *) s;
	return 0;
f0101583:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101588:	5d                   	pop    %ebp
f0101589:	c3                   	ret    

f010158a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010158a:	55                   	push   %ebp
f010158b:	89 e5                	mov    %esp,%ebp
f010158d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101590:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101594:	eb 03                	jmp    f0101599 <strfind+0xf>
f0101596:	83 c0 01             	add    $0x1,%eax
f0101599:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010159c:	38 ca                	cmp    %cl,%dl
f010159e:	74 04                	je     f01015a4 <strfind+0x1a>
f01015a0:	84 d2                	test   %dl,%dl
f01015a2:	75 f2                	jne    f0101596 <strfind+0xc>
			break;
	return (char *) s;
}
f01015a4:	5d                   	pop    %ebp
f01015a5:	c3                   	ret    

f01015a6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015a6:	55                   	push   %ebp
f01015a7:	89 e5                	mov    %esp,%ebp
f01015a9:	57                   	push   %edi
f01015aa:	56                   	push   %esi
f01015ab:	53                   	push   %ebx
f01015ac:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015af:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015b2:	85 c9                	test   %ecx,%ecx
f01015b4:	74 13                	je     f01015c9 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015b6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015bc:	75 05                	jne    f01015c3 <memset+0x1d>
f01015be:	f6 c1 03             	test   $0x3,%cl
f01015c1:	74 0d                	je     f01015d0 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015c3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015c6:	fc                   	cld    
f01015c7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015c9:	89 f8                	mov    %edi,%eax
f01015cb:	5b                   	pop    %ebx
f01015cc:	5e                   	pop    %esi
f01015cd:	5f                   	pop    %edi
f01015ce:	5d                   	pop    %ebp
f01015cf:	c3                   	ret    
		c &= 0xFF;
f01015d0:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015d4:	89 d3                	mov    %edx,%ebx
f01015d6:	c1 e3 08             	shl    $0x8,%ebx
f01015d9:	89 d0                	mov    %edx,%eax
f01015db:	c1 e0 18             	shl    $0x18,%eax
f01015de:	89 d6                	mov    %edx,%esi
f01015e0:	c1 e6 10             	shl    $0x10,%esi
f01015e3:	09 f0                	or     %esi,%eax
f01015e5:	09 c2                	or     %eax,%edx
f01015e7:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01015e9:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01015ec:	89 d0                	mov    %edx,%eax
f01015ee:	fc                   	cld    
f01015ef:	f3 ab                	rep stos %eax,%es:(%edi)
f01015f1:	eb d6                	jmp    f01015c9 <memset+0x23>

f01015f3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015f3:	55                   	push   %ebp
f01015f4:	89 e5                	mov    %esp,%ebp
f01015f6:	57                   	push   %edi
f01015f7:	56                   	push   %esi
f01015f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01015fb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015fe:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101601:	39 c6                	cmp    %eax,%esi
f0101603:	73 35                	jae    f010163a <memmove+0x47>
f0101605:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101608:	39 c2                	cmp    %eax,%edx
f010160a:	76 2e                	jbe    f010163a <memmove+0x47>
		s += n;
		d += n;
f010160c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010160f:	89 d6                	mov    %edx,%esi
f0101611:	09 fe                	or     %edi,%esi
f0101613:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101619:	74 0c                	je     f0101627 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010161b:	83 ef 01             	sub    $0x1,%edi
f010161e:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101621:	fd                   	std    
f0101622:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101624:	fc                   	cld    
f0101625:	eb 21                	jmp    f0101648 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101627:	f6 c1 03             	test   $0x3,%cl
f010162a:	75 ef                	jne    f010161b <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010162c:	83 ef 04             	sub    $0x4,%edi
f010162f:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101632:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101635:	fd                   	std    
f0101636:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101638:	eb ea                	jmp    f0101624 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010163a:	89 f2                	mov    %esi,%edx
f010163c:	09 c2                	or     %eax,%edx
f010163e:	f6 c2 03             	test   $0x3,%dl
f0101641:	74 09                	je     f010164c <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101643:	89 c7                	mov    %eax,%edi
f0101645:	fc                   	cld    
f0101646:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101648:	5e                   	pop    %esi
f0101649:	5f                   	pop    %edi
f010164a:	5d                   	pop    %ebp
f010164b:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010164c:	f6 c1 03             	test   $0x3,%cl
f010164f:	75 f2                	jne    f0101643 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101651:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101654:	89 c7                	mov    %eax,%edi
f0101656:	fc                   	cld    
f0101657:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101659:	eb ed                	jmp    f0101648 <memmove+0x55>

f010165b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010165b:	55                   	push   %ebp
f010165c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010165e:	ff 75 10             	pushl  0x10(%ebp)
f0101661:	ff 75 0c             	pushl  0xc(%ebp)
f0101664:	ff 75 08             	pushl  0x8(%ebp)
f0101667:	e8 87 ff ff ff       	call   f01015f3 <memmove>
}
f010166c:	c9                   	leave  
f010166d:	c3                   	ret    

f010166e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010166e:	55                   	push   %ebp
f010166f:	89 e5                	mov    %esp,%ebp
f0101671:	56                   	push   %esi
f0101672:	53                   	push   %ebx
f0101673:	8b 45 08             	mov    0x8(%ebp),%eax
f0101676:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101679:	89 c6                	mov    %eax,%esi
f010167b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010167e:	39 f0                	cmp    %esi,%eax
f0101680:	74 1c                	je     f010169e <memcmp+0x30>
		if (*s1 != *s2)
f0101682:	0f b6 08             	movzbl (%eax),%ecx
f0101685:	0f b6 1a             	movzbl (%edx),%ebx
f0101688:	38 d9                	cmp    %bl,%cl
f010168a:	75 08                	jne    f0101694 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010168c:	83 c0 01             	add    $0x1,%eax
f010168f:	83 c2 01             	add    $0x1,%edx
f0101692:	eb ea                	jmp    f010167e <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0101694:	0f b6 c1             	movzbl %cl,%eax
f0101697:	0f b6 db             	movzbl %bl,%ebx
f010169a:	29 d8                	sub    %ebx,%eax
f010169c:	eb 05                	jmp    f01016a3 <memcmp+0x35>
	}

	return 0;
f010169e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016a3:	5b                   	pop    %ebx
f01016a4:	5e                   	pop    %esi
f01016a5:	5d                   	pop    %ebp
f01016a6:	c3                   	ret    

f01016a7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016a7:	55                   	push   %ebp
f01016a8:	89 e5                	mov    %esp,%ebp
f01016aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016b0:	89 c2                	mov    %eax,%edx
f01016b2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016b5:	39 d0                	cmp    %edx,%eax
f01016b7:	73 09                	jae    f01016c2 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016b9:	38 08                	cmp    %cl,(%eax)
f01016bb:	74 05                	je     f01016c2 <memfind+0x1b>
	for (; s < ends; s++)
f01016bd:	83 c0 01             	add    $0x1,%eax
f01016c0:	eb f3                	jmp    f01016b5 <memfind+0xe>
			break;
	return (void *) s;
}
f01016c2:	5d                   	pop    %ebp
f01016c3:	c3                   	ret    

f01016c4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016c4:	55                   	push   %ebp
f01016c5:	89 e5                	mov    %esp,%ebp
f01016c7:	57                   	push   %edi
f01016c8:	56                   	push   %esi
f01016c9:	53                   	push   %ebx
f01016ca:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01016cd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016d0:	eb 03                	jmp    f01016d5 <strtol+0x11>
		s++;
f01016d2:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01016d5:	0f b6 01             	movzbl (%ecx),%eax
f01016d8:	3c 20                	cmp    $0x20,%al
f01016da:	74 f6                	je     f01016d2 <strtol+0xe>
f01016dc:	3c 09                	cmp    $0x9,%al
f01016de:	74 f2                	je     f01016d2 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01016e0:	3c 2b                	cmp    $0x2b,%al
f01016e2:	74 2e                	je     f0101712 <strtol+0x4e>
	int neg = 0;
f01016e4:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01016e9:	3c 2d                	cmp    $0x2d,%al
f01016eb:	74 2f                	je     f010171c <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016ed:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01016f3:	75 05                	jne    f01016fa <strtol+0x36>
f01016f5:	80 39 30             	cmpb   $0x30,(%ecx)
f01016f8:	74 2c                	je     f0101726 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016fa:	85 db                	test   %ebx,%ebx
f01016fc:	75 0a                	jne    f0101708 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016fe:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101703:	80 39 30             	cmpb   $0x30,(%ecx)
f0101706:	74 28                	je     f0101730 <strtol+0x6c>
		base = 10;
f0101708:	b8 00 00 00 00       	mov    $0x0,%eax
f010170d:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101710:	eb 50                	jmp    f0101762 <strtol+0x9e>
		s++;
f0101712:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101715:	bf 00 00 00 00       	mov    $0x0,%edi
f010171a:	eb d1                	jmp    f01016ed <strtol+0x29>
		s++, neg = 1;
f010171c:	83 c1 01             	add    $0x1,%ecx
f010171f:	bf 01 00 00 00       	mov    $0x1,%edi
f0101724:	eb c7                	jmp    f01016ed <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101726:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010172a:	74 0e                	je     f010173a <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010172c:	85 db                	test   %ebx,%ebx
f010172e:	75 d8                	jne    f0101708 <strtol+0x44>
		s++, base = 8;
f0101730:	83 c1 01             	add    $0x1,%ecx
f0101733:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101738:	eb ce                	jmp    f0101708 <strtol+0x44>
		s += 2, base = 16;
f010173a:	83 c1 02             	add    $0x2,%ecx
f010173d:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101742:	eb c4                	jmp    f0101708 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101744:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101747:	89 f3                	mov    %esi,%ebx
f0101749:	80 fb 19             	cmp    $0x19,%bl
f010174c:	77 29                	ja     f0101777 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010174e:	0f be d2             	movsbl %dl,%edx
f0101751:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101754:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101757:	7d 30                	jge    f0101789 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101759:	83 c1 01             	add    $0x1,%ecx
f010175c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101760:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101762:	0f b6 11             	movzbl (%ecx),%edx
f0101765:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101768:	89 f3                	mov    %esi,%ebx
f010176a:	80 fb 09             	cmp    $0x9,%bl
f010176d:	77 d5                	ja     f0101744 <strtol+0x80>
			dig = *s - '0';
f010176f:	0f be d2             	movsbl %dl,%edx
f0101772:	83 ea 30             	sub    $0x30,%edx
f0101775:	eb dd                	jmp    f0101754 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101777:	8d 72 bf             	lea    -0x41(%edx),%esi
f010177a:	89 f3                	mov    %esi,%ebx
f010177c:	80 fb 19             	cmp    $0x19,%bl
f010177f:	77 08                	ja     f0101789 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0101781:	0f be d2             	movsbl %dl,%edx
f0101784:	83 ea 37             	sub    $0x37,%edx
f0101787:	eb cb                	jmp    f0101754 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101789:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010178d:	74 05                	je     f0101794 <strtol+0xd0>
		*endptr = (char *) s;
f010178f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101792:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0101794:	89 c2                	mov    %eax,%edx
f0101796:	f7 da                	neg    %edx
f0101798:	85 ff                	test   %edi,%edi
f010179a:	0f 45 c2             	cmovne %edx,%eax
}
f010179d:	5b                   	pop    %ebx
f010179e:	5e                   	pop    %esi
f010179f:	5f                   	pop    %edi
f01017a0:	5d                   	pop    %ebp
f01017a1:	c3                   	ret    
f01017a2:	66 90                	xchg   %ax,%ax
f01017a4:	66 90                	xchg   %ax,%ax
f01017a6:	66 90                	xchg   %ax,%ax
f01017a8:	66 90                	xchg   %ax,%ax
f01017aa:	66 90                	xchg   %ax,%ax
f01017ac:	66 90                	xchg   %ax,%ax
f01017ae:	66 90                	xchg   %ax,%ax

f01017b0 <__udivdi3>:
f01017b0:	55                   	push   %ebp
f01017b1:	57                   	push   %edi
f01017b2:	56                   	push   %esi
f01017b3:	53                   	push   %ebx
f01017b4:	83 ec 1c             	sub    $0x1c,%esp
f01017b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017bb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01017bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017c3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01017c7:	85 d2                	test   %edx,%edx
f01017c9:	75 35                	jne    f0101800 <__udivdi3+0x50>
f01017cb:	39 f3                	cmp    %esi,%ebx
f01017cd:	0f 87 bd 00 00 00    	ja     f0101890 <__udivdi3+0xe0>
f01017d3:	85 db                	test   %ebx,%ebx
f01017d5:	89 d9                	mov    %ebx,%ecx
f01017d7:	75 0b                	jne    f01017e4 <__udivdi3+0x34>
f01017d9:	b8 01 00 00 00       	mov    $0x1,%eax
f01017de:	31 d2                	xor    %edx,%edx
f01017e0:	f7 f3                	div    %ebx
f01017e2:	89 c1                	mov    %eax,%ecx
f01017e4:	31 d2                	xor    %edx,%edx
f01017e6:	89 f0                	mov    %esi,%eax
f01017e8:	f7 f1                	div    %ecx
f01017ea:	89 c6                	mov    %eax,%esi
f01017ec:	89 e8                	mov    %ebp,%eax
f01017ee:	89 f7                	mov    %esi,%edi
f01017f0:	f7 f1                	div    %ecx
f01017f2:	89 fa                	mov    %edi,%edx
f01017f4:	83 c4 1c             	add    $0x1c,%esp
f01017f7:	5b                   	pop    %ebx
f01017f8:	5e                   	pop    %esi
f01017f9:	5f                   	pop    %edi
f01017fa:	5d                   	pop    %ebp
f01017fb:	c3                   	ret    
f01017fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101800:	39 f2                	cmp    %esi,%edx
f0101802:	77 7c                	ja     f0101880 <__udivdi3+0xd0>
f0101804:	0f bd fa             	bsr    %edx,%edi
f0101807:	83 f7 1f             	xor    $0x1f,%edi
f010180a:	0f 84 98 00 00 00    	je     f01018a8 <__udivdi3+0xf8>
f0101810:	89 f9                	mov    %edi,%ecx
f0101812:	b8 20 00 00 00       	mov    $0x20,%eax
f0101817:	29 f8                	sub    %edi,%eax
f0101819:	d3 e2                	shl    %cl,%edx
f010181b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010181f:	89 c1                	mov    %eax,%ecx
f0101821:	89 da                	mov    %ebx,%edx
f0101823:	d3 ea                	shr    %cl,%edx
f0101825:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101829:	09 d1                	or     %edx,%ecx
f010182b:	89 f2                	mov    %esi,%edx
f010182d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101831:	89 f9                	mov    %edi,%ecx
f0101833:	d3 e3                	shl    %cl,%ebx
f0101835:	89 c1                	mov    %eax,%ecx
f0101837:	d3 ea                	shr    %cl,%edx
f0101839:	89 f9                	mov    %edi,%ecx
f010183b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010183f:	d3 e6                	shl    %cl,%esi
f0101841:	89 eb                	mov    %ebp,%ebx
f0101843:	89 c1                	mov    %eax,%ecx
f0101845:	d3 eb                	shr    %cl,%ebx
f0101847:	09 de                	or     %ebx,%esi
f0101849:	89 f0                	mov    %esi,%eax
f010184b:	f7 74 24 08          	divl   0x8(%esp)
f010184f:	89 d6                	mov    %edx,%esi
f0101851:	89 c3                	mov    %eax,%ebx
f0101853:	f7 64 24 0c          	mull   0xc(%esp)
f0101857:	39 d6                	cmp    %edx,%esi
f0101859:	72 0c                	jb     f0101867 <__udivdi3+0xb7>
f010185b:	89 f9                	mov    %edi,%ecx
f010185d:	d3 e5                	shl    %cl,%ebp
f010185f:	39 c5                	cmp    %eax,%ebp
f0101861:	73 5d                	jae    f01018c0 <__udivdi3+0x110>
f0101863:	39 d6                	cmp    %edx,%esi
f0101865:	75 59                	jne    f01018c0 <__udivdi3+0x110>
f0101867:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010186a:	31 ff                	xor    %edi,%edi
f010186c:	89 fa                	mov    %edi,%edx
f010186e:	83 c4 1c             	add    $0x1c,%esp
f0101871:	5b                   	pop    %ebx
f0101872:	5e                   	pop    %esi
f0101873:	5f                   	pop    %edi
f0101874:	5d                   	pop    %ebp
f0101875:	c3                   	ret    
f0101876:	8d 76 00             	lea    0x0(%esi),%esi
f0101879:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101880:	31 ff                	xor    %edi,%edi
f0101882:	31 c0                	xor    %eax,%eax
f0101884:	89 fa                	mov    %edi,%edx
f0101886:	83 c4 1c             	add    $0x1c,%esp
f0101889:	5b                   	pop    %ebx
f010188a:	5e                   	pop    %esi
f010188b:	5f                   	pop    %edi
f010188c:	5d                   	pop    %ebp
f010188d:	c3                   	ret    
f010188e:	66 90                	xchg   %ax,%ax
f0101890:	31 ff                	xor    %edi,%edi
f0101892:	89 e8                	mov    %ebp,%eax
f0101894:	89 f2                	mov    %esi,%edx
f0101896:	f7 f3                	div    %ebx
f0101898:	89 fa                	mov    %edi,%edx
f010189a:	83 c4 1c             	add    $0x1c,%esp
f010189d:	5b                   	pop    %ebx
f010189e:	5e                   	pop    %esi
f010189f:	5f                   	pop    %edi
f01018a0:	5d                   	pop    %ebp
f01018a1:	c3                   	ret    
f01018a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018a8:	39 f2                	cmp    %esi,%edx
f01018aa:	72 06                	jb     f01018b2 <__udivdi3+0x102>
f01018ac:	31 c0                	xor    %eax,%eax
f01018ae:	39 eb                	cmp    %ebp,%ebx
f01018b0:	77 d2                	ja     f0101884 <__udivdi3+0xd4>
f01018b2:	b8 01 00 00 00       	mov    $0x1,%eax
f01018b7:	eb cb                	jmp    f0101884 <__udivdi3+0xd4>
f01018b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01018c0:	89 d8                	mov    %ebx,%eax
f01018c2:	31 ff                	xor    %edi,%edi
f01018c4:	eb be                	jmp    f0101884 <__udivdi3+0xd4>
f01018c6:	66 90                	xchg   %ax,%ax
f01018c8:	66 90                	xchg   %ax,%ax
f01018ca:	66 90                	xchg   %ax,%ax
f01018cc:	66 90                	xchg   %ax,%ax
f01018ce:	66 90                	xchg   %ax,%ax

f01018d0 <__umoddi3>:
f01018d0:	55                   	push   %ebp
f01018d1:	57                   	push   %edi
f01018d2:	56                   	push   %esi
f01018d3:	53                   	push   %ebx
f01018d4:	83 ec 1c             	sub    $0x1c,%esp
f01018d7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01018db:	8b 74 24 30          	mov    0x30(%esp),%esi
f01018df:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01018e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01018e7:	85 ed                	test   %ebp,%ebp
f01018e9:	89 f0                	mov    %esi,%eax
f01018eb:	89 da                	mov    %ebx,%edx
f01018ed:	75 19                	jne    f0101908 <__umoddi3+0x38>
f01018ef:	39 df                	cmp    %ebx,%edi
f01018f1:	0f 86 b1 00 00 00    	jbe    f01019a8 <__umoddi3+0xd8>
f01018f7:	f7 f7                	div    %edi
f01018f9:	89 d0                	mov    %edx,%eax
f01018fb:	31 d2                	xor    %edx,%edx
f01018fd:	83 c4 1c             	add    $0x1c,%esp
f0101900:	5b                   	pop    %ebx
f0101901:	5e                   	pop    %esi
f0101902:	5f                   	pop    %edi
f0101903:	5d                   	pop    %ebp
f0101904:	c3                   	ret    
f0101905:	8d 76 00             	lea    0x0(%esi),%esi
f0101908:	39 dd                	cmp    %ebx,%ebp
f010190a:	77 f1                	ja     f01018fd <__umoddi3+0x2d>
f010190c:	0f bd cd             	bsr    %ebp,%ecx
f010190f:	83 f1 1f             	xor    $0x1f,%ecx
f0101912:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101916:	0f 84 b4 00 00 00    	je     f01019d0 <__umoddi3+0x100>
f010191c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101921:	89 c2                	mov    %eax,%edx
f0101923:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101927:	29 c2                	sub    %eax,%edx
f0101929:	89 c1                	mov    %eax,%ecx
f010192b:	89 f8                	mov    %edi,%eax
f010192d:	d3 e5                	shl    %cl,%ebp
f010192f:	89 d1                	mov    %edx,%ecx
f0101931:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101935:	d3 e8                	shr    %cl,%eax
f0101937:	09 c5                	or     %eax,%ebp
f0101939:	8b 44 24 04          	mov    0x4(%esp),%eax
f010193d:	89 c1                	mov    %eax,%ecx
f010193f:	d3 e7                	shl    %cl,%edi
f0101941:	89 d1                	mov    %edx,%ecx
f0101943:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101947:	89 df                	mov    %ebx,%edi
f0101949:	d3 ef                	shr    %cl,%edi
f010194b:	89 c1                	mov    %eax,%ecx
f010194d:	89 f0                	mov    %esi,%eax
f010194f:	d3 e3                	shl    %cl,%ebx
f0101951:	89 d1                	mov    %edx,%ecx
f0101953:	89 fa                	mov    %edi,%edx
f0101955:	d3 e8                	shr    %cl,%eax
f0101957:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010195c:	09 d8                	or     %ebx,%eax
f010195e:	f7 f5                	div    %ebp
f0101960:	d3 e6                	shl    %cl,%esi
f0101962:	89 d1                	mov    %edx,%ecx
f0101964:	f7 64 24 08          	mull   0x8(%esp)
f0101968:	39 d1                	cmp    %edx,%ecx
f010196a:	89 c3                	mov    %eax,%ebx
f010196c:	89 d7                	mov    %edx,%edi
f010196e:	72 06                	jb     f0101976 <__umoddi3+0xa6>
f0101970:	75 0e                	jne    f0101980 <__umoddi3+0xb0>
f0101972:	39 c6                	cmp    %eax,%esi
f0101974:	73 0a                	jae    f0101980 <__umoddi3+0xb0>
f0101976:	2b 44 24 08          	sub    0x8(%esp),%eax
f010197a:	19 ea                	sbb    %ebp,%edx
f010197c:	89 d7                	mov    %edx,%edi
f010197e:	89 c3                	mov    %eax,%ebx
f0101980:	89 ca                	mov    %ecx,%edx
f0101982:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101987:	29 de                	sub    %ebx,%esi
f0101989:	19 fa                	sbb    %edi,%edx
f010198b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010198f:	89 d0                	mov    %edx,%eax
f0101991:	d3 e0                	shl    %cl,%eax
f0101993:	89 d9                	mov    %ebx,%ecx
f0101995:	d3 ee                	shr    %cl,%esi
f0101997:	d3 ea                	shr    %cl,%edx
f0101999:	09 f0                	or     %esi,%eax
f010199b:	83 c4 1c             	add    $0x1c,%esp
f010199e:	5b                   	pop    %ebx
f010199f:	5e                   	pop    %esi
f01019a0:	5f                   	pop    %edi
f01019a1:	5d                   	pop    %ebp
f01019a2:	c3                   	ret    
f01019a3:	90                   	nop
f01019a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019a8:	85 ff                	test   %edi,%edi
f01019aa:	89 f9                	mov    %edi,%ecx
f01019ac:	75 0b                	jne    f01019b9 <__umoddi3+0xe9>
f01019ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01019b3:	31 d2                	xor    %edx,%edx
f01019b5:	f7 f7                	div    %edi
f01019b7:	89 c1                	mov    %eax,%ecx
f01019b9:	89 d8                	mov    %ebx,%eax
f01019bb:	31 d2                	xor    %edx,%edx
f01019bd:	f7 f1                	div    %ecx
f01019bf:	89 f0                	mov    %esi,%eax
f01019c1:	f7 f1                	div    %ecx
f01019c3:	e9 31 ff ff ff       	jmp    f01018f9 <__umoddi3+0x29>
f01019c8:	90                   	nop
f01019c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019d0:	39 dd                	cmp    %ebx,%ebp
f01019d2:	72 08                	jb     f01019dc <__umoddi3+0x10c>
f01019d4:	39 f7                	cmp    %esi,%edi
f01019d6:	0f 87 21 ff ff ff    	ja     f01018fd <__umoddi3+0x2d>
f01019dc:	89 da                	mov    %ebx,%edx
f01019de:	89 f0                	mov    %esi,%eax
f01019e0:	29 f8                	sub    %edi,%eax
f01019e2:	19 ea                	sbb    %ebp,%edx
f01019e4:	e9 14 ff ff ff       	jmp    f01018fd <__umoddi3+0x2d>
