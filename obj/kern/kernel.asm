
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 68 00 00 00       	call   f01000a6 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 a2 01 00 00       	call   f01001ec <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 18 07 ff ff    	lea    -0xf8e8(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 16 0a 00 00       	call   f0100a79 <cprintf>
	if (x > 0)
f0100063:	83 c4 10             	add    $0x10,%esp
f0100066:	85 f6                	test   %esi,%esi
f0100068:	7f 2b                	jg     f0100095 <test_backtrace+0x55>
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f010006a:	83 ec 04             	sub    $0x4,%esp
f010006d:	6a 00                	push   $0x0
f010006f:	6a 00                	push   $0x0
f0100071:	6a 00                	push   $0x0
f0100073:	e8 3b 08 00 00       	call   f01008b3 <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	56                   	push   %esi
f010007f:	8d 83 34 07 ff ff    	lea    -0xf8cc(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 ee 09 00 00       	call   f0100a79 <cprintf>
}
f010008b:	83 c4 10             	add    $0x10,%esp
f010008e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100091:	5b                   	pop    %ebx
f0100092:	5e                   	pop    %esi
f0100093:	5d                   	pop    %ebp
f0100094:	c3                   	ret    
		test_backtrace(x-1);
f0100095:	83 ec 0c             	sub    $0xc,%esp
f0100098:	8d 46 ff             	lea    -0x1(%esi),%eax
f010009b:	50                   	push   %eax
f010009c:	e8 9f ff ff ff       	call   f0100040 <test_backtrace>
f01000a1:	83 c4 10             	add    $0x10,%esp
f01000a4:	eb d5                	jmp    f010007b <test_backtrace+0x3b>

f01000a6 <i386_init>:

void
i386_init(void)
{
f01000a6:	55                   	push   %ebp
f01000a7:	89 e5                	mov    %esp,%ebp
f01000a9:	53                   	push   %ebx
f01000aa:	83 ec 18             	sub    $0x18,%esp
f01000ad:	e8 3a 01 00 00       	call   f01001ec <__x86.get_pc_thunk.bx>
f01000b2:	81 c3 56 12 01 00    	add    $0x11256,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b8:	c7 c2 60 30 11 f0    	mov    $0xf0113060,%edx
f01000be:	c7 c0 a0 36 11 f0    	mov    $0xf01136a0,%eax
f01000c4:	29 d0                	sub    %edx,%eax
f01000c6:	50                   	push   %eax
f01000c7:	6a 00                	push   $0x0
f01000c9:	52                   	push   %edx
f01000ca:	e8 0a 15 00 00       	call   f01015d9 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 6d 05 00 00       	call   f0100641 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 4f 07 ff ff    	lea    -0xf8b1(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 91 09 00 00       	call   f0100a79 <cprintf>
	
	unsigned int i = 0x00646c72;
f01000e8:	c7 45 f4 72 6c 64 00 	movl   $0x646c72,-0xc(%ebp)
	Lab1_exercise8_3:
    cprintf("H%x Wo%s\n", 57616, &i);
f01000ef:	83 c4 0c             	add    $0xc,%esp
f01000f2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01000f5:	50                   	push   %eax
f01000f6:	68 10 e1 00 00       	push   $0xe110
f01000fb:	8d 83 6a 07 ff ff    	lea    -0xf896(%ebx),%eax
f0100101:	50                   	push   %eax
f0100102:	e8 72 09 00 00       	call   f0100a79 <cprintf>
	cprintf("x=%d y=%d\n", 3);
f0100107:	83 c4 08             	add    $0x8,%esp
f010010a:	6a 03                	push   $0x3
f010010c:	8d 83 74 07 ff ff    	lea    -0xf88c(%ebx),%eax
f0100112:	50                   	push   %eax
f0100113:	e8 61 09 00 00       	call   f0100a79 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f0100118:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f010011f:	e8 1c ff ff ff       	call   f0100040 <test_backtrace>
f0100124:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100127:	83 ec 0c             	sub    $0xc,%esp
f010012a:	6a 00                	push   $0x0
f010012c:	e8 8c 07 00 00       	call   f01008bd <monitor>
f0100131:	83 c4 10             	add    $0x10,%esp
f0100134:	eb f1                	jmp    f0100127 <i386_init+0x81>

f0100136 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100136:	55                   	push   %ebp
f0100137:	89 e5                	mov    %esp,%ebp
f0100139:	57                   	push   %edi
f010013a:	56                   	push   %esi
f010013b:	53                   	push   %ebx
f010013c:	83 ec 0c             	sub    $0xc,%esp
f010013f:	e8 a8 00 00 00       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100144:	81 c3 c4 11 01 00    	add    $0x111c4,%ebx
f010014a:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f010014d:	c7 c0 a4 36 11 f0    	mov    $0xf01136a4,%eax
f0100153:	83 38 00             	cmpl   $0x0,(%eax)
f0100156:	74 0f                	je     f0100167 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100158:	83 ec 0c             	sub    $0xc,%esp
f010015b:	6a 00                	push   $0x0
f010015d:	e8 5b 07 00 00       	call   f01008bd <monitor>
f0100162:	83 c4 10             	add    $0x10,%esp
f0100165:	eb f1                	jmp    f0100158 <_panic+0x22>
	panicstr = fmt;
f0100167:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f0100169:	fa                   	cli    
f010016a:	fc                   	cld    
	va_start(ap, fmt);
f010016b:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	ff 75 0c             	pushl  0xc(%ebp)
f0100174:	ff 75 08             	pushl  0x8(%ebp)
f0100177:	8d 83 7f 07 ff ff    	lea    -0xf881(%ebx),%eax
f010017d:	50                   	push   %eax
f010017e:	e8 f6 08 00 00       	call   f0100a79 <cprintf>
	vcprintf(fmt, ap);
f0100183:	83 c4 08             	add    $0x8,%esp
f0100186:	56                   	push   %esi
f0100187:	57                   	push   %edi
f0100188:	e8 b5 08 00 00       	call   f0100a42 <vcprintf>
	cprintf("\n");
f010018d:	8d 83 bb 07 ff ff    	lea    -0xf845(%ebx),%eax
f0100193:	89 04 24             	mov    %eax,(%esp)
f0100196:	e8 de 08 00 00       	call   f0100a79 <cprintf>
f010019b:	83 c4 10             	add    $0x10,%esp
f010019e:	eb b8                	jmp    f0100158 <_panic+0x22>

f01001a0 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp
f01001a3:	56                   	push   %esi
f01001a4:	53                   	push   %ebx
f01001a5:	e8 42 00 00 00       	call   f01001ec <__x86.get_pc_thunk.bx>
f01001aa:	81 c3 5e 11 01 00    	add    $0x1115e,%ebx
	va_list ap;

	va_start(ap, fmt);
f01001b0:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f01001b3:	83 ec 04             	sub    $0x4,%esp
f01001b6:	ff 75 0c             	pushl  0xc(%ebp)
f01001b9:	ff 75 08             	pushl  0x8(%ebp)
f01001bc:	8d 83 97 07 ff ff    	lea    -0xf869(%ebx),%eax
f01001c2:	50                   	push   %eax
f01001c3:	e8 b1 08 00 00       	call   f0100a79 <cprintf>
	vcprintf(fmt, ap);
f01001c8:	83 c4 08             	add    $0x8,%esp
f01001cb:	56                   	push   %esi
f01001cc:	ff 75 10             	pushl  0x10(%ebp)
f01001cf:	e8 6e 08 00 00       	call   f0100a42 <vcprintf>
	cprintf("\n");
f01001d4:	8d 83 bb 07 ff ff    	lea    -0xf845(%ebx),%eax
f01001da:	89 04 24             	mov    %eax,(%esp)
f01001dd:	e8 97 08 00 00       	call   f0100a79 <cprintf>
	va_end(ap);
}
f01001e2:	83 c4 10             	add    $0x10,%esp
f01001e5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001e8:	5b                   	pop    %ebx
f01001e9:	5e                   	pop    %esi
f01001ea:	5d                   	pop    %ebp
f01001eb:	c3                   	ret    

f01001ec <__x86.get_pc_thunk.bx>:
f01001ec:	8b 1c 24             	mov    (%esp),%ebx
f01001ef:	c3                   	ret    

f01001f0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001f0:	55                   	push   %ebp
f01001f1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001f3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001f8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001f9:	a8 01                	test   $0x1,%al
f01001fb:	74 0b                	je     f0100208 <serial_proc_data+0x18>
f01001fd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100202:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100203:	0f b6 c0             	movzbl %al,%eax
}
f0100206:	5d                   	pop    %ebp
f0100207:	c3                   	ret    
		return -1;
f0100208:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010020d:	eb f7                	jmp    f0100206 <serial_proc_data+0x16>

f010020f <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010020f:	55                   	push   %ebp
f0100210:	89 e5                	mov    %esp,%ebp
f0100212:	56                   	push   %esi
f0100213:	53                   	push   %ebx
f0100214:	e8 d3 ff ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100219:	81 c3 ef 10 01 00    	add    $0x110ef,%ebx
f010021f:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100221:	ff d6                	call   *%esi
f0100223:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100226:	74 2e                	je     f0100256 <cons_intr+0x47>
		if (c == 0)
f0100228:	85 c0                	test   %eax,%eax
f010022a:	74 f5                	je     f0100221 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010022c:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100232:	8d 51 01             	lea    0x1(%ecx),%edx
f0100235:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010023b:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f0100242:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100248:	75 d7                	jne    f0100221 <cons_intr+0x12>
			cons.wpos = 0;
f010024a:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f0100251:	00 00 00 
f0100254:	eb cb                	jmp    f0100221 <cons_intr+0x12>
	}
}
f0100256:	5b                   	pop    %ebx
f0100257:	5e                   	pop    %esi
f0100258:	5d                   	pop    %ebp
f0100259:	c3                   	ret    

f010025a <kbd_proc_data>:
{
f010025a:	55                   	push   %ebp
f010025b:	89 e5                	mov    %esp,%ebp
f010025d:	56                   	push   %esi
f010025e:	53                   	push   %ebx
f010025f:	e8 88 ff ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100264:	81 c3 a4 10 01 00    	add    $0x110a4,%ebx
f010026a:	ba 64 00 00 00       	mov    $0x64,%edx
f010026f:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100270:	a8 01                	test   $0x1,%al
f0100272:	0f 84 06 01 00 00    	je     f010037e <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f0100278:	a8 20                	test   $0x20,%al
f010027a:	0f 85 05 01 00 00    	jne    f0100385 <kbd_proc_data+0x12b>
f0100280:	ba 60 00 00 00       	mov    $0x60,%edx
f0100285:	ec                   	in     (%dx),%al
f0100286:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100288:	3c e0                	cmp    $0xe0,%al
f010028a:	0f 84 93 00 00 00    	je     f0100323 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f0100290:	84 c0                	test   %al,%al
f0100292:	0f 88 a0 00 00 00    	js     f0100338 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100298:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010029e:	f6 c1 40             	test   $0x40,%cl
f01002a1:	74 0e                	je     f01002b1 <kbd_proc_data+0x57>
		data |= 0x80;
f01002a3:	83 c8 80             	or     $0xffffff80,%eax
f01002a6:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002a8:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002ab:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f01002b1:	0f b6 d2             	movzbl %dl,%edx
f01002b4:	0f b6 84 13 f8 08 ff 	movzbl -0xf708(%ebx,%edx,1),%eax
f01002bb:	ff 
f01002bc:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f01002c2:	0f b6 8c 13 f8 07 ff 	movzbl -0xf808(%ebx,%edx,1),%ecx
f01002c9:	ff 
f01002ca:	31 c8                	xor    %ecx,%eax
f01002cc:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f01002d2:	89 c1                	mov    %eax,%ecx
f01002d4:	83 e1 03             	and    $0x3,%ecx
f01002d7:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002de:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002e2:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002e5:	a8 08                	test   $0x8,%al
f01002e7:	74 0d                	je     f01002f6 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f01002e9:	89 f2                	mov    %esi,%edx
f01002eb:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002ee:	83 f9 19             	cmp    $0x19,%ecx
f01002f1:	77 7a                	ja     f010036d <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002f3:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002f6:	f7 d0                	not    %eax
f01002f8:	a8 06                	test   $0x6,%al
f01002fa:	75 33                	jne    f010032f <kbd_proc_data+0xd5>
f01002fc:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100302:	75 2b                	jne    f010032f <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100304:	83 ec 0c             	sub    $0xc,%esp
f0100307:	8d 83 b1 07 ff ff    	lea    -0xf84f(%ebx),%eax
f010030d:	50                   	push   %eax
f010030e:	e8 66 07 00 00       	call   f0100a79 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100313:	b8 03 00 00 00       	mov    $0x3,%eax
f0100318:	ba 92 00 00 00       	mov    $0x92,%edx
f010031d:	ee                   	out    %al,(%dx)
f010031e:	83 c4 10             	add    $0x10,%esp
f0100321:	eb 0c                	jmp    f010032f <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100323:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f010032a:	be 00 00 00 00       	mov    $0x0,%esi
}
f010032f:	89 f0                	mov    %esi,%eax
f0100331:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100334:	5b                   	pop    %ebx
f0100335:	5e                   	pop    %esi
f0100336:	5d                   	pop    %ebp
f0100337:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100338:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010033e:	89 ce                	mov    %ecx,%esi
f0100340:	83 e6 40             	and    $0x40,%esi
f0100343:	83 e0 7f             	and    $0x7f,%eax
f0100346:	85 f6                	test   %esi,%esi
f0100348:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010034b:	0f b6 d2             	movzbl %dl,%edx
f010034e:	0f b6 84 13 f8 08 ff 	movzbl -0xf708(%ebx,%edx,1),%eax
f0100355:	ff 
f0100356:	83 c8 40             	or     $0x40,%eax
f0100359:	0f b6 c0             	movzbl %al,%eax
f010035c:	f7 d0                	not    %eax
f010035e:	21 c8                	and    %ecx,%eax
f0100360:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f0100366:	be 00 00 00 00       	mov    $0x0,%esi
f010036b:	eb c2                	jmp    f010032f <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f010036d:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100370:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100373:	83 fa 1a             	cmp    $0x1a,%edx
f0100376:	0f 42 f1             	cmovb  %ecx,%esi
f0100379:	e9 78 ff ff ff       	jmp    f01002f6 <kbd_proc_data+0x9c>
		return -1;
f010037e:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100383:	eb aa                	jmp    f010032f <kbd_proc_data+0xd5>
		return -1;
f0100385:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010038a:	eb a3                	jmp    f010032f <kbd_proc_data+0xd5>

f010038c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010038c:	55                   	push   %ebp
f010038d:	89 e5                	mov    %esp,%ebp
f010038f:	57                   	push   %edi
f0100390:	56                   	push   %esi
f0100391:	53                   	push   %ebx
f0100392:	83 ec 1c             	sub    $0x1c,%esp
f0100395:	e8 52 fe ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f010039a:	81 c3 6e 0f 01 00    	add    $0x10f6e,%ebx
f01003a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f01003a3:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003a8:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01003ad:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003b2:	eb 09                	jmp    f01003bd <cons_putc+0x31>
f01003b4:	89 ca                	mov    %ecx,%edx
f01003b6:	ec                   	in     (%dx),%al
f01003b7:	ec                   	in     (%dx),%al
f01003b8:	ec                   	in     (%dx),%al
f01003b9:	ec                   	in     (%dx),%al
	     i++)
f01003ba:	83 c6 01             	add    $0x1,%esi
f01003bd:	89 fa                	mov    %edi,%edx
f01003bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003c0:	a8 20                	test   $0x20,%al
f01003c2:	75 08                	jne    f01003cc <cons_putc+0x40>
f01003c4:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003ca:	7e e8                	jle    f01003b4 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f01003cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003cf:	89 f8                	mov    %edi,%eax
f01003d1:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d4:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003d9:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003da:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003df:	bf 79 03 00 00       	mov    $0x379,%edi
f01003e4:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003e9:	eb 09                	jmp    f01003f4 <cons_putc+0x68>
f01003eb:	89 ca                	mov    %ecx,%edx
f01003ed:	ec                   	in     (%dx),%al
f01003ee:	ec                   	in     (%dx),%al
f01003ef:	ec                   	in     (%dx),%al
f01003f0:	ec                   	in     (%dx),%al
f01003f1:	83 c6 01             	add    $0x1,%esi
f01003f4:	89 fa                	mov    %edi,%edx
f01003f6:	ec                   	in     (%dx),%al
f01003f7:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003fd:	7f 04                	jg     f0100403 <cons_putc+0x77>
f01003ff:	84 c0                	test   %al,%al
f0100401:	79 e8                	jns    f01003eb <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100403:	ba 78 03 00 00       	mov    $0x378,%edx
f0100408:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010040c:	ee                   	out    %al,(%dx)
f010040d:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100412:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100417:	ee                   	out    %al,(%dx)
f0100418:	b8 08 00 00 00       	mov    $0x8,%eax
f010041d:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010041e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100421:	89 fa                	mov    %edi,%edx
f0100423:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100429:	89 f8                	mov    %edi,%eax
f010042b:	80 cc 07             	or     $0x7,%ah
f010042e:	85 d2                	test   %edx,%edx
f0100430:	0f 45 c7             	cmovne %edi,%eax
f0100433:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100436:	0f b6 c0             	movzbl %al,%eax
f0100439:	83 f8 09             	cmp    $0x9,%eax
f010043c:	0f 84 b9 00 00 00    	je     f01004fb <cons_putc+0x16f>
f0100442:	83 f8 09             	cmp    $0x9,%eax
f0100445:	7e 74                	jle    f01004bb <cons_putc+0x12f>
f0100447:	83 f8 0a             	cmp    $0xa,%eax
f010044a:	0f 84 9e 00 00 00    	je     f01004ee <cons_putc+0x162>
f0100450:	83 f8 0d             	cmp    $0xd,%eax
f0100453:	0f 85 d9 00 00 00    	jne    f0100532 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100459:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100460:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100466:	c1 e8 16             	shr    $0x16,%eax
f0100469:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010046c:	c1 e0 04             	shl    $0x4,%eax
f010046f:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100476:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f010047d:	cf 07 
f010047f:	0f 87 d4 00 00 00    	ja     f0100559 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100485:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f010048b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100490:	89 ca                	mov    %ecx,%edx
f0100492:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100493:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f010049a:	8d 71 01             	lea    0x1(%ecx),%esi
f010049d:	89 d8                	mov    %ebx,%eax
f010049f:	66 c1 e8 08          	shr    $0x8,%ax
f01004a3:	89 f2                	mov    %esi,%edx
f01004a5:	ee                   	out    %al,(%dx)
f01004a6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004ab:	89 ca                	mov    %ecx,%edx
f01004ad:	ee                   	out    %al,(%dx)
f01004ae:	89 d8                	mov    %ebx,%eax
f01004b0:	89 f2                	mov    %esi,%edx
f01004b2:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004b3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004b6:	5b                   	pop    %ebx
f01004b7:	5e                   	pop    %esi
f01004b8:	5f                   	pop    %edi
f01004b9:	5d                   	pop    %ebp
f01004ba:	c3                   	ret    
	switch (c & 0xff) {
f01004bb:	83 f8 08             	cmp    $0x8,%eax
f01004be:	75 72                	jne    f0100532 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f01004c0:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01004c7:	66 85 c0             	test   %ax,%ax
f01004ca:	74 b9                	je     f0100485 <cons_putc+0xf9>
			crt_pos--;
f01004cc:	83 e8 01             	sub    $0x1,%eax
f01004cf:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d6:	0f b7 c0             	movzwl %ax,%eax
f01004d9:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004dd:	b2 00                	mov    $0x0,%dl
f01004df:	83 ca 20             	or     $0x20,%edx
f01004e2:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01004e8:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004ec:	eb 88                	jmp    f0100476 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f01004ee:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f01004f5:	50 
f01004f6:	e9 5e ff ff ff       	jmp    f0100459 <cons_putc+0xcd>
		cons_putc(' ');
f01004fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100500:	e8 87 fe ff ff       	call   f010038c <cons_putc>
		cons_putc(' ');
f0100505:	b8 20 00 00 00       	mov    $0x20,%eax
f010050a:	e8 7d fe ff ff       	call   f010038c <cons_putc>
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 73 fe ff ff       	call   f010038c <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 69 fe ff ff       	call   f010038c <cons_putc>
		cons_putc(' ');
f0100523:	b8 20 00 00 00       	mov    $0x20,%eax
f0100528:	e8 5f fe ff ff       	call   f010038c <cons_putc>
f010052d:	e9 44 ff ff ff       	jmp    f0100476 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100532:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100539:	8d 50 01             	lea    0x1(%eax),%edx
f010053c:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f0100543:	0f b7 c0             	movzwl %ax,%eax
f0100546:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010054c:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f0100550:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100554:	e9 1d ff ff ff       	jmp    f0100476 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100559:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f010055f:	83 ec 04             	sub    $0x4,%esp
f0100562:	68 00 0f 00 00       	push   $0xf00
f0100567:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010056d:	52                   	push   %edx
f010056e:	50                   	push   %eax
f010056f:	e8 b2 10 00 00       	call   f0101626 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100574:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010057a:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100580:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100586:	83 c4 10             	add    $0x10,%esp
f0100589:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010058e:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100591:	39 d0                	cmp    %edx,%eax
f0100593:	75 f4                	jne    f0100589 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100595:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f010059c:	50 
f010059d:	e9 e3 fe ff ff       	jmp    f0100485 <cons_putc+0xf9>

f01005a2 <serial_intr>:
{
f01005a2:	e8 e7 01 00 00       	call   f010078e <__x86.get_pc_thunk.ax>
f01005a7:	05 61 0d 01 00       	add    $0x10d61,%eax
	if (serial_exists)
f01005ac:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f01005b3:	75 02                	jne    f01005b7 <serial_intr+0x15>
f01005b5:	f3 c3                	repz ret 
{
f01005b7:	55                   	push   %ebp
f01005b8:	89 e5                	mov    %esp,%ebp
f01005ba:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01005bd:	8d 80 e8 ee fe ff    	lea    -0x11118(%eax),%eax
f01005c3:	e8 47 fc ff ff       	call   f010020f <cons_intr>
}
f01005c8:	c9                   	leave  
f01005c9:	c3                   	ret    

f01005ca <kbd_intr>:
{
f01005ca:	55                   	push   %ebp
f01005cb:	89 e5                	mov    %esp,%ebp
f01005cd:	83 ec 08             	sub    $0x8,%esp
f01005d0:	e8 b9 01 00 00       	call   f010078e <__x86.get_pc_thunk.ax>
f01005d5:	05 33 0d 01 00       	add    $0x10d33,%eax
	cons_intr(kbd_proc_data);
f01005da:	8d 80 52 ef fe ff    	lea    -0x110ae(%eax),%eax
f01005e0:	e8 2a fc ff ff       	call   f010020f <cons_intr>
}
f01005e5:	c9                   	leave  
f01005e6:	c3                   	ret    

f01005e7 <cons_getc>:
{
f01005e7:	55                   	push   %ebp
f01005e8:	89 e5                	mov    %esp,%ebp
f01005ea:	53                   	push   %ebx
f01005eb:	83 ec 04             	sub    $0x4,%esp
f01005ee:	e8 f9 fb ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f01005f3:	81 c3 15 0d 01 00    	add    $0x10d15,%ebx
	serial_intr();
f01005f9:	e8 a4 ff ff ff       	call   f01005a2 <serial_intr>
	kbd_intr();
f01005fe:	e8 c7 ff ff ff       	call   f01005ca <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100603:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f0100609:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f010060e:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100614:	74 19                	je     f010062f <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100616:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100619:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f010061f:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f0100626:	00 
		if (cons.rpos == CONSBUFSIZE)
f0100627:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f010062d:	74 06                	je     f0100635 <cons_getc+0x4e>
}
f010062f:	83 c4 04             	add    $0x4,%esp
f0100632:	5b                   	pop    %ebx
f0100633:	5d                   	pop    %ebp
f0100634:	c3                   	ret    
			cons.rpos = 0;
f0100635:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010063c:	00 00 00 
f010063f:	eb ee                	jmp    f010062f <cons_getc+0x48>

f0100641 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100641:	55                   	push   %ebp
f0100642:	89 e5                	mov    %esp,%ebp
f0100644:	57                   	push   %edi
f0100645:	56                   	push   %esi
f0100646:	53                   	push   %ebx
f0100647:	83 ec 1c             	sub    $0x1c,%esp
f010064a:	e8 9d fb ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f010064f:	81 c3 b9 0c 01 00    	add    $0x10cb9,%ebx
	was = *cp;
f0100655:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010065c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100663:	5a a5 
	if (*cp != 0xA55A) {
f0100665:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010066c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100670:	0f 84 bc 00 00 00    	je     f0100732 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f0100676:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f010067d:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100680:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100687:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f010068d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100692:	89 fa                	mov    %edi,%edx
f0100694:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100695:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100698:	89 ca                	mov    %ecx,%edx
f010069a:	ec                   	in     (%dx),%al
f010069b:	0f b6 f0             	movzbl %al,%esi
f010069e:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006a1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006a6:	89 fa                	mov    %edi,%edx
f01006a8:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a9:	89 ca                	mov    %ecx,%edx
f01006ab:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01006ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01006af:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f01006b5:	0f b6 c0             	movzbl %al,%eax
f01006b8:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f01006ba:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01006c6:	89 c8                	mov    %ecx,%eax
f01006c8:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006cd:	ee                   	out    %al,(%dx)
f01006ce:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006d3:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006d8:	89 fa                	mov    %edi,%edx
f01006da:	ee                   	out    %al,(%dx)
f01006db:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006e0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006e5:	ee                   	out    %al,(%dx)
f01006e6:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006eb:	89 c8                	mov    %ecx,%eax
f01006ed:	89 f2                	mov    %esi,%edx
f01006ef:	ee                   	out    %al,(%dx)
f01006f0:	b8 03 00 00 00       	mov    $0x3,%eax
f01006f5:	89 fa                	mov    %edi,%edx
f01006f7:	ee                   	out    %al,(%dx)
f01006f8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006fd:	89 c8                	mov    %ecx,%eax
f01006ff:	ee                   	out    %al,(%dx)
f0100700:	b8 01 00 00 00       	mov    $0x1,%eax
f0100705:	89 f2                	mov    %esi,%edx
f0100707:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100708:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010070d:	ec                   	in     (%dx),%al
f010070e:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100710:	3c ff                	cmp    $0xff,%al
f0100712:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f0100719:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010071e:	ec                   	in     (%dx),%al
f010071f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100724:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100725:	80 f9 ff             	cmp    $0xff,%cl
f0100728:	74 25                	je     f010074f <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010072a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010072d:	5b                   	pop    %ebx
f010072e:	5e                   	pop    %esi
f010072f:	5f                   	pop    %edi
f0100730:	5d                   	pop    %ebp
f0100731:	c3                   	ret    
		*cp = was;
f0100732:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100739:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f0100740:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100743:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f010074a:	e9 38 ff ff ff       	jmp    f0100687 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f010074f:	83 ec 0c             	sub    $0xc,%esp
f0100752:	8d 83 bd 07 ff ff    	lea    -0xf843(%ebx),%eax
f0100758:	50                   	push   %eax
f0100759:	e8 1b 03 00 00       	call   f0100a79 <cprintf>
f010075e:	83 c4 10             	add    $0x10,%esp
}
f0100761:	eb c7                	jmp    f010072a <cons_init+0xe9>

f0100763 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100763:	55                   	push   %ebp
f0100764:	89 e5                	mov    %esp,%ebp
f0100766:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100769:	8b 45 08             	mov    0x8(%ebp),%eax
f010076c:	e8 1b fc ff ff       	call   f010038c <cons_putc>
}
f0100771:	c9                   	leave  
f0100772:	c3                   	ret    

f0100773 <getchar>:

int
getchar(void)
{
f0100773:	55                   	push   %ebp
f0100774:	89 e5                	mov    %esp,%ebp
f0100776:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100779:	e8 69 fe ff ff       	call   f01005e7 <cons_getc>
f010077e:	85 c0                	test   %eax,%eax
f0100780:	74 f7                	je     f0100779 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100782:	c9                   	leave  
f0100783:	c3                   	ret    

f0100784 <iscons>:

int
iscons(int fdnum)
{
f0100784:	55                   	push   %ebp
f0100785:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100787:	b8 01 00 00 00       	mov    $0x1,%eax
f010078c:	5d                   	pop    %ebp
f010078d:	c3                   	ret    

f010078e <__x86.get_pc_thunk.ax>:
f010078e:	8b 04 24             	mov    (%esp),%eax
f0100791:	c3                   	ret    

f0100792 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100792:	55                   	push   %ebp
f0100793:	89 e5                	mov    %esp,%ebp
f0100795:	56                   	push   %esi
f0100796:	53                   	push   %ebx
f0100797:	e8 50 fa ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f010079c:	81 c3 6c 0b 01 00    	add    $0x10b6c,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007a2:	83 ec 04             	sub    $0x4,%esp
f01007a5:	8d 83 f8 09 ff ff    	lea    -0xf608(%ebx),%eax
f01007ab:	50                   	push   %eax
f01007ac:	8d 83 16 0a ff ff    	lea    -0xf5ea(%ebx),%eax
f01007b2:	50                   	push   %eax
f01007b3:	8d b3 1b 0a ff ff    	lea    -0xf5e5(%ebx),%esi
f01007b9:	56                   	push   %esi
f01007ba:	e8 ba 02 00 00       	call   f0100a79 <cprintf>
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	8d 83 84 0a ff ff    	lea    -0xf57c(%ebx),%eax
f01007c8:	50                   	push   %eax
f01007c9:	8d 83 24 0a ff ff    	lea    -0xf5dc(%ebx),%eax
f01007cf:	50                   	push   %eax
f01007d0:	56                   	push   %esi
f01007d1:	e8 a3 02 00 00       	call   f0100a79 <cprintf>
	return 0;
}
f01007d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01007db:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007de:	5b                   	pop    %ebx
f01007df:	5e                   	pop    %esi
f01007e0:	5d                   	pop    %ebp
f01007e1:	c3                   	ret    

f01007e2 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007e2:	55                   	push   %ebp
f01007e3:	89 e5                	mov    %esp,%ebp
f01007e5:	57                   	push   %edi
f01007e6:	56                   	push   %esi
f01007e7:	53                   	push   %ebx
f01007e8:	83 ec 18             	sub    $0x18,%esp
f01007eb:	e8 fc f9 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f01007f0:	81 c3 18 0b 01 00    	add    $0x10b18,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007f6:	8d 83 2d 0a ff ff    	lea    -0xf5d3(%ebx),%eax
f01007fc:	50                   	push   %eax
f01007fd:	e8 77 02 00 00       	call   f0100a79 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100802:	83 c4 08             	add    $0x8,%esp
f0100805:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010080b:	8d 83 ac 0a ff ff    	lea    -0xf554(%ebx),%eax
f0100811:	50                   	push   %eax
f0100812:	e8 62 02 00 00       	call   f0100a79 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100820:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100826:	50                   	push   %eax
f0100827:	57                   	push   %edi
f0100828:	8d 83 d4 0a ff ff    	lea    -0xf52c(%ebx),%eax
f010082e:	50                   	push   %eax
f010082f:	e8 45 02 00 00       	call   f0100a79 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100834:	83 c4 0c             	add    $0xc,%esp
f0100837:	c7 c0 19 1a 10 f0    	mov    $0xf0101a19,%eax
f010083d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100843:	52                   	push   %edx
f0100844:	50                   	push   %eax
f0100845:	8d 83 f8 0a ff ff    	lea    -0xf508(%ebx),%eax
f010084b:	50                   	push   %eax
f010084c:	e8 28 02 00 00       	call   f0100a79 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100851:	83 c4 0c             	add    $0xc,%esp
f0100854:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f010085a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100860:	52                   	push   %edx
f0100861:	50                   	push   %eax
f0100862:	8d 83 1c 0b ff ff    	lea    -0xf4e4(%ebx),%eax
f0100868:	50                   	push   %eax
f0100869:	e8 0b 02 00 00       	call   f0100a79 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010086e:	83 c4 0c             	add    $0xc,%esp
f0100871:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f0100877:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010087d:	50                   	push   %eax
f010087e:	56                   	push   %esi
f010087f:	8d 83 40 0b ff ff    	lea    -0xf4c0(%ebx),%eax
f0100885:	50                   	push   %eax
f0100886:	e8 ee 01 00 00       	call   f0100a79 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010088b:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010088e:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100894:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100896:	c1 fe 0a             	sar    $0xa,%esi
f0100899:	56                   	push   %esi
f010089a:	8d 83 64 0b ff ff    	lea    -0xf49c(%ebx),%eax
f01008a0:	50                   	push   %eax
f01008a1:	e8 d3 01 00 00       	call   f0100a79 <cprintf>
	return 0;
}
f01008a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ae:	5b                   	pop    %ebx
f01008af:	5e                   	pop    %esi
f01008b0:	5f                   	pop    %edi
f01008b1:	5d                   	pop    %ebp
f01008b2:	c3                   	ret    

f01008b3 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008b3:	55                   	push   %ebp
f01008b4:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01008b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01008bb:	5d                   	pop    %ebp
f01008bc:	c3                   	ret    

f01008bd <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008bd:	55                   	push   %ebp
f01008be:	89 e5                	mov    %esp,%ebp
f01008c0:	57                   	push   %edi
f01008c1:	56                   	push   %esi
f01008c2:	53                   	push   %ebx
f01008c3:	83 ec 68             	sub    $0x68,%esp
f01008c6:	e8 21 f9 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f01008cb:	81 c3 3d 0a 01 00    	add    $0x10a3d,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008d1:	8d 83 90 0b ff ff    	lea    -0xf470(%ebx),%eax
f01008d7:	50                   	push   %eax
f01008d8:	e8 9c 01 00 00       	call   f0100a79 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008dd:	8d 83 b4 0b ff ff    	lea    -0xf44c(%ebx),%eax
f01008e3:	89 04 24             	mov    %eax,(%esp)
f01008e6:	e8 8e 01 00 00       	call   f0100a79 <cprintf>
f01008eb:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008ee:	8d bb 4a 0a ff ff    	lea    -0xf5b6(%ebx),%edi
f01008f4:	eb 4a                	jmp    f0100940 <monitor+0x83>
f01008f6:	83 ec 08             	sub    $0x8,%esp
f01008f9:	0f be c0             	movsbl %al,%eax
f01008fc:	50                   	push   %eax
f01008fd:	57                   	push   %edi
f01008fe:	e8 99 0c 00 00       	call   f010159c <strchr>
f0100903:	83 c4 10             	add    $0x10,%esp
f0100906:	85 c0                	test   %eax,%eax
f0100908:	74 08                	je     f0100912 <monitor+0x55>
			*buf++ = 0;
f010090a:	c6 06 00             	movb   $0x0,(%esi)
f010090d:	8d 76 01             	lea    0x1(%esi),%esi
f0100910:	eb 79                	jmp    f010098b <monitor+0xce>
		if (*buf == 0)
f0100912:	80 3e 00             	cmpb   $0x0,(%esi)
f0100915:	74 7f                	je     f0100996 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100917:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f010091b:	74 0f                	je     f010092c <monitor+0x6f>
		argv[argc++] = buf;
f010091d:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100920:	8d 48 01             	lea    0x1(%eax),%ecx
f0100923:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100926:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010092a:	eb 44                	jmp    f0100970 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010092c:	83 ec 08             	sub    $0x8,%esp
f010092f:	6a 10                	push   $0x10
f0100931:	8d 83 4f 0a ff ff    	lea    -0xf5b1(%ebx),%eax
f0100937:	50                   	push   %eax
f0100938:	e8 3c 01 00 00       	call   f0100a79 <cprintf>
f010093d:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100940:	8d 83 46 0a ff ff    	lea    -0xf5ba(%ebx),%eax
f0100946:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100949:	83 ec 0c             	sub    $0xc,%esp
f010094c:	ff 75 a4             	pushl  -0x5c(%ebp)
f010094f:	e8 10 0a 00 00       	call   f0101364 <readline>
f0100954:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100956:	83 c4 10             	add    $0x10,%esp
f0100959:	85 c0                	test   %eax,%eax
f010095b:	74 ec                	je     f0100949 <monitor+0x8c>
	argv[argc] = 0;
f010095d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100964:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f010096b:	eb 1e                	jmp    f010098b <monitor+0xce>
			buf++;
f010096d:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100970:	0f b6 06             	movzbl (%esi),%eax
f0100973:	84 c0                	test   %al,%al
f0100975:	74 14                	je     f010098b <monitor+0xce>
f0100977:	83 ec 08             	sub    $0x8,%esp
f010097a:	0f be c0             	movsbl %al,%eax
f010097d:	50                   	push   %eax
f010097e:	57                   	push   %edi
f010097f:	e8 18 0c 00 00       	call   f010159c <strchr>
f0100984:	83 c4 10             	add    $0x10,%esp
f0100987:	85 c0                	test   %eax,%eax
f0100989:	74 e2                	je     f010096d <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f010098b:	0f b6 06             	movzbl (%esi),%eax
f010098e:	84 c0                	test   %al,%al
f0100990:	0f 85 60 ff ff ff    	jne    f01008f6 <monitor+0x39>
	argv[argc] = 0;
f0100996:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100999:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009a0:	00 
	if (argc == 0)
f01009a1:	85 c0                	test   %eax,%eax
f01009a3:	74 9b                	je     f0100940 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009a5:	83 ec 08             	sub    $0x8,%esp
f01009a8:	8d 83 16 0a ff ff    	lea    -0xf5ea(%ebx),%eax
f01009ae:	50                   	push   %eax
f01009af:	ff 75 a8             	pushl  -0x58(%ebp)
f01009b2:	e8 87 0b 00 00       	call   f010153e <strcmp>
f01009b7:	83 c4 10             	add    $0x10,%esp
f01009ba:	85 c0                	test   %eax,%eax
f01009bc:	74 38                	je     f01009f6 <monitor+0x139>
f01009be:	83 ec 08             	sub    $0x8,%esp
f01009c1:	8d 83 24 0a ff ff    	lea    -0xf5dc(%ebx),%eax
f01009c7:	50                   	push   %eax
f01009c8:	ff 75 a8             	pushl  -0x58(%ebp)
f01009cb:	e8 6e 0b 00 00       	call   f010153e <strcmp>
f01009d0:	83 c4 10             	add    $0x10,%esp
f01009d3:	85 c0                	test   %eax,%eax
f01009d5:	74 1a                	je     f01009f1 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009d7:	83 ec 08             	sub    $0x8,%esp
f01009da:	ff 75 a8             	pushl  -0x58(%ebp)
f01009dd:	8d 83 6c 0a ff ff    	lea    -0xf594(%ebx),%eax
f01009e3:	50                   	push   %eax
f01009e4:	e8 90 00 00 00       	call   f0100a79 <cprintf>
f01009e9:	83 c4 10             	add    $0x10,%esp
f01009ec:	e9 4f ff ff ff       	jmp    f0100940 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009f1:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f01009f6:	83 ec 04             	sub    $0x4,%esp
f01009f9:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01009fc:	ff 75 08             	pushl  0x8(%ebp)
f01009ff:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a02:	52                   	push   %edx
f0100a03:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a06:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a0d:	83 c4 10             	add    $0x10,%esp
f0100a10:	85 c0                	test   %eax,%eax
f0100a12:	0f 89 28 ff ff ff    	jns    f0100940 <monitor+0x83>
				break;
	}
}
f0100a18:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a1b:	5b                   	pop    %ebx
f0100a1c:	5e                   	pop    %esi
f0100a1d:	5f                   	pop    %edi
f0100a1e:	5d                   	pop    %ebp
f0100a1f:	c3                   	ret    

f0100a20 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
f0100a23:	53                   	push   %ebx
f0100a24:	83 ec 10             	sub    $0x10,%esp
f0100a27:	e8 c0 f7 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100a2c:	81 c3 dc 08 01 00    	add    $0x108dc,%ebx
	cputchar(ch);
f0100a32:	ff 75 08             	pushl  0x8(%ebp)
f0100a35:	e8 29 fd ff ff       	call   f0100763 <cputchar>
	*cnt++;
}
f0100a3a:	83 c4 10             	add    $0x10,%esp
f0100a3d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a40:	c9                   	leave  
f0100a41:	c3                   	ret    

f0100a42 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a42:	55                   	push   %ebp
f0100a43:	89 e5                	mov    %esp,%ebp
f0100a45:	53                   	push   %ebx
f0100a46:	83 ec 14             	sub    $0x14,%esp
f0100a49:	e8 9e f7 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100a4e:	81 c3 ba 08 01 00    	add    $0x108ba,%ebx
	int cnt = 0;
f0100a54:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a5b:	ff 75 0c             	pushl  0xc(%ebp)
f0100a5e:	ff 75 08             	pushl  0x8(%ebp)
f0100a61:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a64:	50                   	push   %eax
f0100a65:	8d 83 18 f7 fe ff    	lea    -0x108e8(%ebx),%eax
f0100a6b:	50                   	push   %eax
f0100a6c:	e8 1c 04 00 00       	call   f0100e8d <vprintfmt>
	return cnt;
}
f0100a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a74:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a77:	c9                   	leave  
f0100a78:	c3                   	ret    

f0100a79 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a79:	55                   	push   %ebp
f0100a7a:	89 e5                	mov    %esp,%ebp
f0100a7c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a7f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a82:	50                   	push   %eax
f0100a83:	ff 75 08             	pushl  0x8(%ebp)
f0100a86:	e8 b7 ff ff ff       	call   f0100a42 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a8b:	c9                   	leave  
f0100a8c:	c3                   	ret    

f0100a8d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a8d:	55                   	push   %ebp
f0100a8e:	89 e5                	mov    %esp,%ebp
f0100a90:	57                   	push   %edi
f0100a91:	56                   	push   %esi
f0100a92:	53                   	push   %ebx
f0100a93:	83 ec 14             	sub    $0x14,%esp
f0100a96:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a99:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a9c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a9f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100aa2:	8b 32                	mov    (%edx),%esi
f0100aa4:	8b 01                	mov    (%ecx),%eax
f0100aa6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100aa9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100ab0:	eb 2f                	jmp    f0100ae1 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100ab2:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100ab5:	39 c6                	cmp    %eax,%esi
f0100ab7:	7f 49                	jg     f0100b02 <stab_binsearch+0x75>
f0100ab9:	0f b6 0a             	movzbl (%edx),%ecx
f0100abc:	83 ea 0c             	sub    $0xc,%edx
f0100abf:	39 f9                	cmp    %edi,%ecx
f0100ac1:	75 ef                	jne    f0100ab2 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100ac3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ac6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ac9:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100acd:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100ad0:	73 35                	jae    f0100b07 <stab_binsearch+0x7a>
			*region_left = m;
f0100ad2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ad5:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100ad7:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100ada:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100ae1:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100ae4:	7f 4e                	jg     f0100b34 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100ae6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ae9:	01 f0                	add    %esi,%eax
f0100aeb:	89 c3                	mov    %eax,%ebx
f0100aed:	c1 eb 1f             	shr    $0x1f,%ebx
f0100af0:	01 c3                	add    %eax,%ebx
f0100af2:	d1 fb                	sar    %ebx
f0100af4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100af7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100afa:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100afe:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b00:	eb b3                	jmp    f0100ab5 <stab_binsearch+0x28>
			l = true_m + 1;
f0100b02:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100b05:	eb da                	jmp    f0100ae1 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100b07:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b0a:	76 14                	jbe    f0100b20 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100b0c:	83 e8 01             	sub    $0x1,%eax
f0100b0f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b12:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100b15:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100b17:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b1e:	eb c1                	jmp    f0100ae1 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b20:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b23:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100b25:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b29:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100b2b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b32:	eb ad                	jmp    f0100ae1 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100b34:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b38:	74 16                	je     f0100b50 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b3a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b3d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b3f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b42:	8b 0e                	mov    (%esi),%ecx
f0100b44:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b47:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b4a:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100b4e:	eb 12                	jmp    f0100b62 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100b50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b53:	8b 00                	mov    (%eax),%eax
f0100b55:	83 e8 01             	sub    $0x1,%eax
f0100b58:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b5b:	89 07                	mov    %eax,(%edi)
f0100b5d:	eb 16                	jmp    f0100b75 <stab_binsearch+0xe8>
		     l--)
f0100b5f:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100b62:	39 c1                	cmp    %eax,%ecx
f0100b64:	7d 0a                	jge    f0100b70 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100b66:	0f b6 1a             	movzbl (%edx),%ebx
f0100b69:	83 ea 0c             	sub    $0xc,%edx
f0100b6c:	39 fb                	cmp    %edi,%ebx
f0100b6e:	75 ef                	jne    f0100b5f <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100b70:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b73:	89 07                	mov    %eax,(%edi)
	}
}
f0100b75:	83 c4 14             	add    $0x14,%esp
f0100b78:	5b                   	pop    %ebx
f0100b79:	5e                   	pop    %esi
f0100b7a:	5f                   	pop    %edi
f0100b7b:	5d                   	pop    %ebp
f0100b7c:	c3                   	ret    

f0100b7d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b7d:	55                   	push   %ebp
f0100b7e:	89 e5                	mov    %esp,%ebp
f0100b80:	57                   	push   %edi
f0100b81:	56                   	push   %esi
f0100b82:	53                   	push   %ebx
f0100b83:	83 ec 2c             	sub    $0x2c,%esp
f0100b86:	e8 fa 01 00 00       	call   f0100d85 <__x86.get_pc_thunk.cx>
f0100b8b:	81 c1 7d 07 01 00    	add    $0x1077d,%ecx
f0100b91:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100b94:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100b97:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b9a:	8d 81 dc 0b ff ff    	lea    -0xf424(%ecx),%eax
f0100ba0:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100ba2:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100ba9:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100bac:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100bb3:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100bb6:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bbd:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100bc3:	0f 86 f4 00 00 00    	jbe    f0100cbd <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bc9:	c7 c0 dd 5c 10 f0    	mov    $0xf0105cdd,%eax
f0100bcf:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100bd5:	0f 86 88 01 00 00    	jbe    f0100d63 <debuginfo_eip+0x1e6>
f0100bdb:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100bde:	c7 c0 2c 76 10 f0    	mov    $0xf010762c,%eax
f0100be4:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100be8:	0f 85 7c 01 00 00    	jne    f0100d6a <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bee:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bf5:	c7 c0 00 21 10 f0    	mov    $0xf0102100,%eax
f0100bfb:	c7 c2 dc 5c 10 f0    	mov    $0xf0105cdc,%edx
f0100c01:	29 c2                	sub    %eax,%edx
f0100c03:	c1 fa 02             	sar    $0x2,%edx
f0100c06:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100c0c:	83 ea 01             	sub    $0x1,%edx
f0100c0f:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c12:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c15:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c18:	83 ec 08             	sub    $0x8,%esp
f0100c1b:	53                   	push   %ebx
f0100c1c:	6a 64                	push   $0x64
f0100c1e:	e8 6a fe ff ff       	call   f0100a8d <stab_binsearch>
	if (lfile == 0)
f0100c23:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c26:	83 c4 10             	add    $0x10,%esp
f0100c29:	85 c0                	test   %eax,%eax
f0100c2b:	0f 84 40 01 00 00    	je     f0100d71 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c31:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c34:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c37:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c3a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c3d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c40:	83 ec 08             	sub    $0x8,%esp
f0100c43:	53                   	push   %ebx
f0100c44:	6a 24                	push   $0x24
f0100c46:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100c49:	c7 c0 00 21 10 f0    	mov    $0xf0102100,%eax
f0100c4f:	e8 39 fe ff ff       	call   f0100a8d <stab_binsearch>

	if (lfun <= rfun) {
f0100c54:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100c57:	83 c4 10             	add    $0x10,%esp
f0100c5a:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100c5d:	7f 79                	jg     f0100cd8 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c5f:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c62:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c65:	c7 c2 00 21 10 f0    	mov    $0xf0102100,%edx
f0100c6b:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100c6e:	8b 11                	mov    (%ecx),%edx
f0100c70:	c7 c0 2c 76 10 f0    	mov    $0xf010762c,%eax
f0100c76:	81 e8 dd 5c 10 f0    	sub    $0xf0105cdd,%eax
f0100c7c:	39 c2                	cmp    %eax,%edx
f0100c7e:	73 09                	jae    f0100c89 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c80:	81 c2 dd 5c 10 f0    	add    $0xf0105cdd,%edx
f0100c86:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c89:	8b 41 08             	mov    0x8(%ecx),%eax
f0100c8c:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c8f:	83 ec 08             	sub    $0x8,%esp
f0100c92:	6a 3a                	push   $0x3a
f0100c94:	ff 77 08             	pushl  0x8(%edi)
f0100c97:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c9a:	e8 1e 09 00 00       	call   f01015bd <strfind>
f0100c9f:	2b 47 08             	sub    0x8(%edi),%eax
f0100ca2:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ca5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ca8:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100cab:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100cae:	c7 c2 00 21 10 f0    	mov    $0xf0102100,%edx
f0100cb4:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100cb8:	83 c4 10             	add    $0x10,%esp
f0100cbb:	eb 29                	jmp    f0100ce6 <debuginfo_eip+0x169>
  	        panic("User address");
f0100cbd:	83 ec 04             	sub    $0x4,%esp
f0100cc0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cc3:	8d 83 e6 0b ff ff    	lea    -0xf41a(%ebx),%eax
f0100cc9:	50                   	push   %eax
f0100cca:	6a 7f                	push   $0x7f
f0100ccc:	8d 83 f3 0b ff ff    	lea    -0xf40d(%ebx),%eax
f0100cd2:	50                   	push   %eax
f0100cd3:	e8 5e f4 ff ff       	call   f0100136 <_panic>
		info->eip_fn_addr = addr;
f0100cd8:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100cdb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cde:	eb af                	jmp    f0100c8f <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ce0:	83 ee 01             	sub    $0x1,%esi
f0100ce3:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100ce6:	39 f3                	cmp    %esi,%ebx
f0100ce8:	7f 3a                	jg     f0100d24 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100cea:	0f b6 10             	movzbl (%eax),%edx
f0100ced:	80 fa 84             	cmp    $0x84,%dl
f0100cf0:	74 0b                	je     f0100cfd <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cf2:	80 fa 64             	cmp    $0x64,%dl
f0100cf5:	75 e9                	jne    f0100ce0 <debuginfo_eip+0x163>
f0100cf7:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100cfb:	74 e3                	je     f0100ce0 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cfd:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100d00:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d03:	c7 c0 00 21 10 f0    	mov    $0xf0102100,%eax
f0100d09:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100d0c:	c7 c0 2c 76 10 f0    	mov    $0xf010762c,%eax
f0100d12:	81 e8 dd 5c 10 f0    	sub    $0xf0105cdd,%eax
f0100d18:	39 c2                	cmp    %eax,%edx
f0100d1a:	73 08                	jae    f0100d24 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d1c:	81 c2 dd 5c 10 f0    	add    $0xf0105cdd,%edx
f0100d22:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d24:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100d27:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d2a:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100d2f:	39 cb                	cmp    %ecx,%ebx
f0100d31:	7d 4a                	jge    f0100d7d <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100d33:	8d 53 01             	lea    0x1(%ebx),%edx
f0100d36:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100d39:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d3c:	c7 c0 00 21 10 f0    	mov    $0xf0102100,%eax
f0100d42:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100d46:	eb 07                	jmp    f0100d4f <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100d48:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100d4c:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100d4f:	39 d1                	cmp    %edx,%ecx
f0100d51:	74 25                	je     f0100d78 <debuginfo_eip+0x1fb>
f0100d53:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d56:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100d5a:	74 ec                	je     f0100d48 <debuginfo_eip+0x1cb>
	return 0;
f0100d5c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d61:	eb 1a                	jmp    f0100d7d <debuginfo_eip+0x200>
		return -1;
f0100d63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d68:	eb 13                	jmp    f0100d7d <debuginfo_eip+0x200>
f0100d6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d6f:	eb 0c                	jmp    f0100d7d <debuginfo_eip+0x200>
		return -1;
f0100d71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d76:	eb 05                	jmp    f0100d7d <debuginfo_eip+0x200>
	return 0;
f0100d78:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d80:	5b                   	pop    %ebx
f0100d81:	5e                   	pop    %esi
f0100d82:	5f                   	pop    %edi
f0100d83:	5d                   	pop    %ebp
f0100d84:	c3                   	ret    

f0100d85 <__x86.get_pc_thunk.cx>:
f0100d85:	8b 0c 24             	mov    (%esp),%ecx
f0100d88:	c3                   	ret    

f0100d89 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d89:	55                   	push   %ebp
f0100d8a:	89 e5                	mov    %esp,%ebp
f0100d8c:	57                   	push   %edi
f0100d8d:	56                   	push   %esi
f0100d8e:	53                   	push   %ebx
f0100d8f:	83 ec 2c             	sub    $0x2c,%esp
f0100d92:	e8 ee ff ff ff       	call   f0100d85 <__x86.get_pc_thunk.cx>
f0100d97:	81 c1 71 05 01 00    	add    $0x10571,%ecx
f0100d9d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100da0:	89 c7                	mov    %eax,%edi
f0100da2:	89 d6                	mov    %edx,%esi
f0100da4:	8b 45 08             	mov    0x8(%ebp),%eax
f0100da7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100daa:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100dad:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100db0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100db3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100db8:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100dbb:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100dbe:	39 d3                	cmp    %edx,%ebx
f0100dc0:	72 09                	jb     f0100dcb <printnum+0x42>
f0100dc2:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100dc5:	0f 87 83 00 00 00    	ja     f0100e4e <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dcb:	83 ec 0c             	sub    $0xc,%esp
f0100dce:	ff 75 18             	pushl  0x18(%ebp)
f0100dd1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dd4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100dd7:	53                   	push   %ebx
f0100dd8:	ff 75 10             	pushl  0x10(%ebp)
f0100ddb:	83 ec 08             	sub    $0x8,%esp
f0100dde:	ff 75 dc             	pushl  -0x24(%ebp)
f0100de1:	ff 75 d8             	pushl  -0x28(%ebp)
f0100de4:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100de7:	ff 75 d0             	pushl  -0x30(%ebp)
f0100dea:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ded:	e8 ee 09 00 00       	call   f01017e0 <__udivdi3>
f0100df2:	83 c4 18             	add    $0x18,%esp
f0100df5:	52                   	push   %edx
f0100df6:	50                   	push   %eax
f0100df7:	89 f2                	mov    %esi,%edx
f0100df9:	89 f8                	mov    %edi,%eax
f0100dfb:	e8 89 ff ff ff       	call   f0100d89 <printnum>
f0100e00:	83 c4 20             	add    $0x20,%esp
f0100e03:	eb 13                	jmp    f0100e18 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e05:	83 ec 08             	sub    $0x8,%esp
f0100e08:	56                   	push   %esi
f0100e09:	ff 75 18             	pushl  0x18(%ebp)
f0100e0c:	ff d7                	call   *%edi
f0100e0e:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100e11:	83 eb 01             	sub    $0x1,%ebx
f0100e14:	85 db                	test   %ebx,%ebx
f0100e16:	7f ed                	jg     f0100e05 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e18:	83 ec 08             	sub    $0x8,%esp
f0100e1b:	56                   	push   %esi
f0100e1c:	83 ec 04             	sub    $0x4,%esp
f0100e1f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e22:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e25:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e28:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e2b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100e2e:	89 f3                	mov    %esi,%ebx
f0100e30:	e8 cb 0a 00 00       	call   f0101900 <__umoddi3>
f0100e35:	83 c4 14             	add    $0x14,%esp
f0100e38:	0f be 84 06 01 0c ff 	movsbl -0xf3ff(%esi,%eax,1),%eax
f0100e3f:	ff 
f0100e40:	50                   	push   %eax
f0100e41:	ff d7                	call   *%edi
}
f0100e43:	83 c4 10             	add    $0x10,%esp
f0100e46:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e49:	5b                   	pop    %ebx
f0100e4a:	5e                   	pop    %esi
f0100e4b:	5f                   	pop    %edi
f0100e4c:	5d                   	pop    %ebp
f0100e4d:	c3                   	ret    
f0100e4e:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e51:	eb be                	jmp    f0100e11 <printnum+0x88>

f0100e53 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e53:	55                   	push   %ebp
f0100e54:	89 e5                	mov    %esp,%ebp
f0100e56:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e59:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e5d:	8b 10                	mov    (%eax),%edx
f0100e5f:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e62:	73 0a                	jae    f0100e6e <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e64:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e67:	89 08                	mov    %ecx,(%eax)
f0100e69:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e6c:	88 02                	mov    %al,(%edx)
}
f0100e6e:	5d                   	pop    %ebp
f0100e6f:	c3                   	ret    

f0100e70 <printfmt>:
{
f0100e70:	55                   	push   %ebp
f0100e71:	89 e5                	mov    %esp,%ebp
f0100e73:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100e76:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e79:	50                   	push   %eax
f0100e7a:	ff 75 10             	pushl  0x10(%ebp)
f0100e7d:	ff 75 0c             	pushl  0xc(%ebp)
f0100e80:	ff 75 08             	pushl  0x8(%ebp)
f0100e83:	e8 05 00 00 00       	call   f0100e8d <vprintfmt>
}
f0100e88:	83 c4 10             	add    $0x10,%esp
f0100e8b:	c9                   	leave  
f0100e8c:	c3                   	ret    

f0100e8d <vprintfmt>:
{
f0100e8d:	55                   	push   %ebp
f0100e8e:	89 e5                	mov    %esp,%ebp
f0100e90:	57                   	push   %edi
f0100e91:	56                   	push   %esi
f0100e92:	53                   	push   %ebx
f0100e93:	83 ec 2c             	sub    $0x2c,%esp
f0100e96:	e8 51 f3 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100e9b:	81 c3 6d 04 01 00    	add    $0x1046d,%ebx
f0100ea1:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100ea4:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100ea7:	e9 8e 03 00 00       	jmp    f010123a <.L35+0x48>
		padc = ' ';
f0100eac:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100eb0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100eb7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0100ebe:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100ec5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100eca:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100ecd:	8d 47 01             	lea    0x1(%edi),%eax
f0100ed0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ed3:	0f b6 17             	movzbl (%edi),%edx
f0100ed6:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100ed9:	3c 55                	cmp    $0x55,%al
f0100edb:	0f 87 e1 03 00 00    	ja     f01012c2 <.L22>
f0100ee1:	0f b6 c0             	movzbl %al,%eax
f0100ee4:	89 d9                	mov    %ebx,%ecx
f0100ee6:	03 8c 83 90 0c ff ff 	add    -0xf370(%ebx,%eax,4),%ecx
f0100eed:	ff e1                	jmp    *%ecx

f0100eef <.L67>:
f0100eef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100ef2:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100ef6:	eb d5                	jmp    f0100ecd <vprintfmt+0x40>

f0100ef8 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100efb:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100eff:	eb cc                	jmp    f0100ecd <vprintfmt+0x40>

f0100f01 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0100f01:	0f b6 d2             	movzbl %dl,%edx
f0100f04:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100f07:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0100f0c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f0f:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f13:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f16:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f19:	83 f9 09             	cmp    $0x9,%ecx
f0100f1c:	77 55                	ja     f0100f73 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0100f1e:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100f21:	eb e9                	jmp    f0100f0c <.L29+0xb>

f0100f23 <.L26>:
			precision = va_arg(ap, int);
f0100f23:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f26:	8b 00                	mov    (%eax),%eax
f0100f28:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2e:	8d 40 04             	lea    0x4(%eax),%eax
f0100f31:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f34:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100f37:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f3b:	79 90                	jns    f0100ecd <vprintfmt+0x40>
				width = precision, precision = -1;
f0100f3d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f40:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f43:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f4a:	eb 81                	jmp    f0100ecd <vprintfmt+0x40>

f0100f4c <.L27>:
f0100f4c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f4f:	85 c0                	test   %eax,%eax
f0100f51:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f56:	0f 49 d0             	cmovns %eax,%edx
f0100f59:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f5c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f5f:	e9 69 ff ff ff       	jmp    f0100ecd <vprintfmt+0x40>

f0100f64 <.L23>:
f0100f64:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0100f67:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f6e:	e9 5a ff ff ff       	jmp    f0100ecd <vprintfmt+0x40>
f0100f73:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f76:	eb bf                	jmp    f0100f37 <.L26+0x14>

f0100f78 <.L33>:
			lflag++;
f0100f78:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0100f7f:	e9 49 ff ff ff       	jmp    f0100ecd <vprintfmt+0x40>

f0100f84 <.L30>:
			putch(va_arg(ap, int), putdat);
f0100f84:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f87:	8d 78 04             	lea    0x4(%eax),%edi
f0100f8a:	83 ec 08             	sub    $0x8,%esp
f0100f8d:	56                   	push   %esi
f0100f8e:	ff 30                	pushl  (%eax)
f0100f90:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f93:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100f96:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100f99:	e9 99 02 00 00       	jmp    f0101237 <.L35+0x45>

f0100f9e <.L32>:
			err = va_arg(ap, int);
f0100f9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa1:	8d 78 04             	lea    0x4(%eax),%edi
f0100fa4:	8b 00                	mov    (%eax),%eax
f0100fa6:	99                   	cltd   
f0100fa7:	31 d0                	xor    %edx,%eax
f0100fa9:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fab:	83 f8 06             	cmp    $0x6,%eax
f0100fae:	7f 27                	jg     f0100fd7 <.L32+0x39>
f0100fb0:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0100fb7:	85 d2                	test   %edx,%edx
f0100fb9:	74 1c                	je     f0100fd7 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0100fbb:	52                   	push   %edx
f0100fbc:	8d 83 22 0c ff ff    	lea    -0xf3de(%ebx),%eax
f0100fc2:	50                   	push   %eax
f0100fc3:	56                   	push   %esi
f0100fc4:	ff 75 08             	pushl  0x8(%ebp)
f0100fc7:	e8 a4 fe ff ff       	call   f0100e70 <printfmt>
f0100fcc:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fcf:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100fd2:	e9 60 02 00 00       	jmp    f0101237 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0100fd7:	50                   	push   %eax
f0100fd8:	8d 83 19 0c ff ff    	lea    -0xf3e7(%ebx),%eax
f0100fde:	50                   	push   %eax
f0100fdf:	56                   	push   %esi
f0100fe0:	ff 75 08             	pushl  0x8(%ebp)
f0100fe3:	e8 88 fe ff ff       	call   f0100e70 <printfmt>
f0100fe8:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100feb:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100fee:	e9 44 02 00 00       	jmp    f0101237 <.L35+0x45>

f0100ff3 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0100ff3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff6:	83 c0 04             	add    $0x4,%eax
f0100ff9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100ffc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fff:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101001:	85 ff                	test   %edi,%edi
f0101003:	8d 83 12 0c ff ff    	lea    -0xf3ee(%ebx),%eax
f0101009:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010100c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101010:	0f 8e b5 00 00 00    	jle    f01010cb <.L36+0xd8>
f0101016:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010101a:	75 08                	jne    f0101024 <.L36+0x31>
f010101c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010101f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101022:	eb 6d                	jmp    f0101091 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101024:	83 ec 08             	sub    $0x8,%esp
f0101027:	ff 75 d0             	pushl  -0x30(%ebp)
f010102a:	57                   	push   %edi
f010102b:	e8 49 04 00 00       	call   f0101479 <strnlen>
f0101030:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101033:	29 c2                	sub    %eax,%edx
f0101035:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101038:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010103b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010103f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101042:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101045:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101047:	eb 10                	jmp    f0101059 <.L36+0x66>
					putch(padc, putdat);
f0101049:	83 ec 08             	sub    $0x8,%esp
f010104c:	56                   	push   %esi
f010104d:	ff 75 e0             	pushl  -0x20(%ebp)
f0101050:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101053:	83 ef 01             	sub    $0x1,%edi
f0101056:	83 c4 10             	add    $0x10,%esp
f0101059:	85 ff                	test   %edi,%edi
f010105b:	7f ec                	jg     f0101049 <.L36+0x56>
f010105d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101060:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101063:	85 d2                	test   %edx,%edx
f0101065:	b8 00 00 00 00       	mov    $0x0,%eax
f010106a:	0f 49 c2             	cmovns %edx,%eax
f010106d:	29 c2                	sub    %eax,%edx
f010106f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101072:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101075:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101078:	eb 17                	jmp    f0101091 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010107a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010107e:	75 30                	jne    f01010b0 <.L36+0xbd>
					putch(ch, putdat);
f0101080:	83 ec 08             	sub    $0x8,%esp
f0101083:	ff 75 0c             	pushl  0xc(%ebp)
f0101086:	50                   	push   %eax
f0101087:	ff 55 08             	call   *0x8(%ebp)
f010108a:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010108d:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101091:	83 c7 01             	add    $0x1,%edi
f0101094:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101098:	0f be c2             	movsbl %dl,%eax
f010109b:	85 c0                	test   %eax,%eax
f010109d:	74 52                	je     f01010f1 <.L36+0xfe>
f010109f:	85 f6                	test   %esi,%esi
f01010a1:	78 d7                	js     f010107a <.L36+0x87>
f01010a3:	83 ee 01             	sub    $0x1,%esi
f01010a6:	79 d2                	jns    f010107a <.L36+0x87>
f01010a8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010ab:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01010ae:	eb 32                	jmp    f01010e2 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01010b0:	0f be d2             	movsbl %dl,%edx
f01010b3:	83 ea 20             	sub    $0x20,%edx
f01010b6:	83 fa 5e             	cmp    $0x5e,%edx
f01010b9:	76 c5                	jbe    f0101080 <.L36+0x8d>
					putch('?', putdat);
f01010bb:	83 ec 08             	sub    $0x8,%esp
f01010be:	ff 75 0c             	pushl  0xc(%ebp)
f01010c1:	6a 3f                	push   $0x3f
f01010c3:	ff 55 08             	call   *0x8(%ebp)
f01010c6:	83 c4 10             	add    $0x10,%esp
f01010c9:	eb c2                	jmp    f010108d <.L36+0x9a>
f01010cb:	89 75 0c             	mov    %esi,0xc(%ebp)
f01010ce:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010d1:	eb be                	jmp    f0101091 <.L36+0x9e>
				putch(' ', putdat);
f01010d3:	83 ec 08             	sub    $0x8,%esp
f01010d6:	56                   	push   %esi
f01010d7:	6a 20                	push   $0x20
f01010d9:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01010dc:	83 ef 01             	sub    $0x1,%edi
f01010df:	83 c4 10             	add    $0x10,%esp
f01010e2:	85 ff                	test   %edi,%edi
f01010e4:	7f ed                	jg     f01010d3 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01010e6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01010e9:	89 45 14             	mov    %eax,0x14(%ebp)
f01010ec:	e9 46 01 00 00       	jmp    f0101237 <.L35+0x45>
f01010f1:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01010f4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010f7:	eb e9                	jmp    f01010e2 <.L36+0xef>

f01010f9 <.L31>:
f01010f9:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01010fc:	83 f9 01             	cmp    $0x1,%ecx
f01010ff:	7e 40                	jle    f0101141 <.L31+0x48>
		return va_arg(*ap, long long);
f0101101:	8b 45 14             	mov    0x14(%ebp),%eax
f0101104:	8b 50 04             	mov    0x4(%eax),%edx
f0101107:	8b 00                	mov    (%eax),%eax
f0101109:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010110c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010110f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101112:	8d 40 08             	lea    0x8(%eax),%eax
f0101115:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101118:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010111c:	79 55                	jns    f0101173 <.L31+0x7a>
				putch('-', putdat);
f010111e:	83 ec 08             	sub    $0x8,%esp
f0101121:	56                   	push   %esi
f0101122:	6a 2d                	push   $0x2d
f0101124:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101127:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010112a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010112d:	f7 da                	neg    %edx
f010112f:	83 d1 00             	adc    $0x0,%ecx
f0101132:	f7 d9                	neg    %ecx
f0101134:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101137:	b8 0a 00 00 00       	mov    $0xa,%eax
f010113c:	e9 db 00 00 00       	jmp    f010121c <.L35+0x2a>
	else if (lflag)
f0101141:	85 c9                	test   %ecx,%ecx
f0101143:	75 17                	jne    f010115c <.L31+0x63>
		return va_arg(*ap, int);
f0101145:	8b 45 14             	mov    0x14(%ebp),%eax
f0101148:	8b 00                	mov    (%eax),%eax
f010114a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010114d:	99                   	cltd   
f010114e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101151:	8b 45 14             	mov    0x14(%ebp),%eax
f0101154:	8d 40 04             	lea    0x4(%eax),%eax
f0101157:	89 45 14             	mov    %eax,0x14(%ebp)
f010115a:	eb bc                	jmp    f0101118 <.L31+0x1f>
		return va_arg(*ap, long);
f010115c:	8b 45 14             	mov    0x14(%ebp),%eax
f010115f:	8b 00                	mov    (%eax),%eax
f0101161:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101164:	99                   	cltd   
f0101165:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101168:	8b 45 14             	mov    0x14(%ebp),%eax
f010116b:	8d 40 04             	lea    0x4(%eax),%eax
f010116e:	89 45 14             	mov    %eax,0x14(%ebp)
f0101171:	eb a5                	jmp    f0101118 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101173:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101176:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101179:	b8 0a 00 00 00       	mov    $0xa,%eax
f010117e:	e9 99 00 00 00       	jmp    f010121c <.L35+0x2a>

f0101183 <.L37>:
f0101183:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101186:	83 f9 01             	cmp    $0x1,%ecx
f0101189:	7e 15                	jle    f01011a0 <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f010118b:	8b 45 14             	mov    0x14(%ebp),%eax
f010118e:	8b 10                	mov    (%eax),%edx
f0101190:	8b 48 04             	mov    0x4(%eax),%ecx
f0101193:	8d 40 08             	lea    0x8(%eax),%eax
f0101196:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101199:	b8 0a 00 00 00       	mov    $0xa,%eax
f010119e:	eb 7c                	jmp    f010121c <.L35+0x2a>
	else if (lflag)
f01011a0:	85 c9                	test   %ecx,%ecx
f01011a2:	75 17                	jne    f01011bb <.L37+0x38>
		return va_arg(*ap, unsigned int);
f01011a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a7:	8b 10                	mov    (%eax),%edx
f01011a9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011ae:	8d 40 04             	lea    0x4(%eax),%eax
f01011b1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011b4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011b9:	eb 61                	jmp    f010121c <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01011bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01011be:	8b 10                	mov    (%eax),%edx
f01011c0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011c5:	8d 40 04             	lea    0x4(%eax),%eax
f01011c8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011cb:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011d0:	eb 4a                	jmp    f010121c <.L35+0x2a>

f01011d2 <.L34>:
			putch('X', putdat);
f01011d2:	83 ec 08             	sub    $0x8,%esp
f01011d5:	56                   	push   %esi
f01011d6:	6a 58                	push   $0x58
f01011d8:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01011db:	83 c4 08             	add    $0x8,%esp
f01011de:	56                   	push   %esi
f01011df:	6a 58                	push   $0x58
f01011e1:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01011e4:	83 c4 08             	add    $0x8,%esp
f01011e7:	56                   	push   %esi
f01011e8:	6a 58                	push   $0x58
f01011ea:	ff 55 08             	call   *0x8(%ebp)
			break;
f01011ed:	83 c4 10             	add    $0x10,%esp
f01011f0:	eb 45                	jmp    f0101237 <.L35+0x45>

f01011f2 <.L35>:
			putch('0', putdat);
f01011f2:	83 ec 08             	sub    $0x8,%esp
f01011f5:	56                   	push   %esi
f01011f6:	6a 30                	push   $0x30
f01011f8:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011fb:	83 c4 08             	add    $0x8,%esp
f01011fe:	56                   	push   %esi
f01011ff:	6a 78                	push   $0x78
f0101201:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101204:	8b 45 14             	mov    0x14(%ebp),%eax
f0101207:	8b 10                	mov    (%eax),%edx
f0101209:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010120e:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101211:	8d 40 04             	lea    0x4(%eax),%eax
f0101214:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101217:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010121c:	83 ec 0c             	sub    $0xc,%esp
f010121f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101223:	57                   	push   %edi
f0101224:	ff 75 e0             	pushl  -0x20(%ebp)
f0101227:	50                   	push   %eax
f0101228:	51                   	push   %ecx
f0101229:	52                   	push   %edx
f010122a:	89 f2                	mov    %esi,%edx
f010122c:	8b 45 08             	mov    0x8(%ebp),%eax
f010122f:	e8 55 fb ff ff       	call   f0100d89 <printnum>
			break;
f0101234:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101237:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010123a:	83 c7 01             	add    $0x1,%edi
f010123d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101241:	83 f8 25             	cmp    $0x25,%eax
f0101244:	0f 84 62 fc ff ff    	je     f0100eac <vprintfmt+0x1f>
			if (ch == '\0')
f010124a:	85 c0                	test   %eax,%eax
f010124c:	0f 84 91 00 00 00    	je     f01012e3 <.L22+0x21>
			putch(ch, putdat);
f0101252:	83 ec 08             	sub    $0x8,%esp
f0101255:	56                   	push   %esi
f0101256:	50                   	push   %eax
f0101257:	ff 55 08             	call   *0x8(%ebp)
f010125a:	83 c4 10             	add    $0x10,%esp
f010125d:	eb db                	jmp    f010123a <.L35+0x48>

f010125f <.L38>:
f010125f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101262:	83 f9 01             	cmp    $0x1,%ecx
f0101265:	7e 15                	jle    f010127c <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0101267:	8b 45 14             	mov    0x14(%ebp),%eax
f010126a:	8b 10                	mov    (%eax),%edx
f010126c:	8b 48 04             	mov    0x4(%eax),%ecx
f010126f:	8d 40 08             	lea    0x8(%eax),%eax
f0101272:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101275:	b8 10 00 00 00       	mov    $0x10,%eax
f010127a:	eb a0                	jmp    f010121c <.L35+0x2a>
	else if (lflag)
f010127c:	85 c9                	test   %ecx,%ecx
f010127e:	75 17                	jne    f0101297 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0101280:	8b 45 14             	mov    0x14(%ebp),%eax
f0101283:	8b 10                	mov    (%eax),%edx
f0101285:	b9 00 00 00 00       	mov    $0x0,%ecx
f010128a:	8d 40 04             	lea    0x4(%eax),%eax
f010128d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101290:	b8 10 00 00 00       	mov    $0x10,%eax
f0101295:	eb 85                	jmp    f010121c <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101297:	8b 45 14             	mov    0x14(%ebp),%eax
f010129a:	8b 10                	mov    (%eax),%edx
f010129c:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012a1:	8d 40 04             	lea    0x4(%eax),%eax
f01012a4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012a7:	b8 10 00 00 00       	mov    $0x10,%eax
f01012ac:	e9 6b ff ff ff       	jmp    f010121c <.L35+0x2a>

f01012b1 <.L25>:
			putch(ch, putdat);
f01012b1:	83 ec 08             	sub    $0x8,%esp
f01012b4:	56                   	push   %esi
f01012b5:	6a 25                	push   $0x25
f01012b7:	ff 55 08             	call   *0x8(%ebp)
			break;
f01012ba:	83 c4 10             	add    $0x10,%esp
f01012bd:	e9 75 ff ff ff       	jmp    f0101237 <.L35+0x45>

f01012c2 <.L22>:
			putch('%', putdat);
f01012c2:	83 ec 08             	sub    $0x8,%esp
f01012c5:	56                   	push   %esi
f01012c6:	6a 25                	push   $0x25
f01012c8:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012cb:	83 c4 10             	add    $0x10,%esp
f01012ce:	89 f8                	mov    %edi,%eax
f01012d0:	eb 03                	jmp    f01012d5 <.L22+0x13>
f01012d2:	83 e8 01             	sub    $0x1,%eax
f01012d5:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01012d9:	75 f7                	jne    f01012d2 <.L22+0x10>
f01012db:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012de:	e9 54 ff ff ff       	jmp    f0101237 <.L35+0x45>
}
f01012e3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012e6:	5b                   	pop    %ebx
f01012e7:	5e                   	pop    %esi
f01012e8:	5f                   	pop    %edi
f01012e9:	5d                   	pop    %ebp
f01012ea:	c3                   	ret    

f01012eb <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012eb:	55                   	push   %ebp
f01012ec:	89 e5                	mov    %esp,%ebp
f01012ee:	53                   	push   %ebx
f01012ef:	83 ec 14             	sub    $0x14,%esp
f01012f2:	e8 f5 ee ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f01012f7:	81 c3 11 00 01 00    	add    $0x10011,%ebx
f01012fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101300:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101303:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101306:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010130a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010130d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101314:	85 c0                	test   %eax,%eax
f0101316:	74 2b                	je     f0101343 <vsnprintf+0x58>
f0101318:	85 d2                	test   %edx,%edx
f010131a:	7e 27                	jle    f0101343 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010131c:	ff 75 14             	pushl  0x14(%ebp)
f010131f:	ff 75 10             	pushl  0x10(%ebp)
f0101322:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101325:	50                   	push   %eax
f0101326:	8d 83 4b fb fe ff    	lea    -0x104b5(%ebx),%eax
f010132c:	50                   	push   %eax
f010132d:	e8 5b fb ff ff       	call   f0100e8d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101332:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101335:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101338:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010133b:	83 c4 10             	add    $0x10,%esp
}
f010133e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101341:	c9                   	leave  
f0101342:	c3                   	ret    
		return -E_INVAL;
f0101343:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101348:	eb f4                	jmp    f010133e <vsnprintf+0x53>

f010134a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010134a:	55                   	push   %ebp
f010134b:	89 e5                	mov    %esp,%ebp
f010134d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101350:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101353:	50                   	push   %eax
f0101354:	ff 75 10             	pushl  0x10(%ebp)
f0101357:	ff 75 0c             	pushl  0xc(%ebp)
f010135a:	ff 75 08             	pushl  0x8(%ebp)
f010135d:	e8 89 ff ff ff       	call   f01012eb <vsnprintf>
	va_end(ap);

	return rc;
}
f0101362:	c9                   	leave  
f0101363:	c3                   	ret    

f0101364 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101364:	55                   	push   %ebp
f0101365:	89 e5                	mov    %esp,%ebp
f0101367:	57                   	push   %edi
f0101368:	56                   	push   %esi
f0101369:	53                   	push   %ebx
f010136a:	83 ec 1c             	sub    $0x1c,%esp
f010136d:	e8 7a ee ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0101372:	81 c3 96 ff 00 00    	add    $0xff96,%ebx
f0101378:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010137b:	85 c0                	test   %eax,%eax
f010137d:	74 13                	je     f0101392 <readline+0x2e>
		cprintf("%s", prompt);
f010137f:	83 ec 08             	sub    $0x8,%esp
f0101382:	50                   	push   %eax
f0101383:	8d 83 22 0c ff ff    	lea    -0xf3de(%ebx),%eax
f0101389:	50                   	push   %eax
f010138a:	e8 ea f6 ff ff       	call   f0100a79 <cprintf>
f010138f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101392:	83 ec 0c             	sub    $0xc,%esp
f0101395:	6a 00                	push   $0x0
f0101397:	e8 e8 f3 ff ff       	call   f0100784 <iscons>
f010139c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010139f:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01013a2:	bf 00 00 00 00       	mov    $0x0,%edi
f01013a7:	eb 46                	jmp    f01013ef <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01013a9:	83 ec 08             	sub    $0x8,%esp
f01013ac:	50                   	push   %eax
f01013ad:	8d 83 e8 0d ff ff    	lea    -0xf218(%ebx),%eax
f01013b3:	50                   	push   %eax
f01013b4:	e8 c0 f6 ff ff       	call   f0100a79 <cprintf>
			return NULL;
f01013b9:	83 c4 10             	add    $0x10,%esp
f01013bc:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01013c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013c4:	5b                   	pop    %ebx
f01013c5:	5e                   	pop    %esi
f01013c6:	5f                   	pop    %edi
f01013c7:	5d                   	pop    %ebp
f01013c8:	c3                   	ret    
			if (echoing)
f01013c9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013cd:	75 05                	jne    f01013d4 <readline+0x70>
			i--;
f01013cf:	83 ef 01             	sub    $0x1,%edi
f01013d2:	eb 1b                	jmp    f01013ef <readline+0x8b>
				cputchar('\b');
f01013d4:	83 ec 0c             	sub    $0xc,%esp
f01013d7:	6a 08                	push   $0x8
f01013d9:	e8 85 f3 ff ff       	call   f0100763 <cputchar>
f01013de:	83 c4 10             	add    $0x10,%esp
f01013e1:	eb ec                	jmp    f01013cf <readline+0x6b>
			buf[i++] = c;
f01013e3:	89 f0                	mov    %esi,%eax
f01013e5:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f01013ec:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01013ef:	e8 7f f3 ff ff       	call   f0100773 <getchar>
f01013f4:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01013f6:	85 c0                	test   %eax,%eax
f01013f8:	78 af                	js     f01013a9 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013fa:	83 f8 08             	cmp    $0x8,%eax
f01013fd:	0f 94 c2             	sete   %dl
f0101400:	83 f8 7f             	cmp    $0x7f,%eax
f0101403:	0f 94 c0             	sete   %al
f0101406:	08 c2                	or     %al,%dl
f0101408:	74 04                	je     f010140e <readline+0xaa>
f010140a:	85 ff                	test   %edi,%edi
f010140c:	7f bb                	jg     f01013c9 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010140e:	83 fe 1f             	cmp    $0x1f,%esi
f0101411:	7e 1c                	jle    f010142f <readline+0xcb>
f0101413:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101419:	7f 14                	jg     f010142f <readline+0xcb>
			if (echoing)
f010141b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010141f:	74 c2                	je     f01013e3 <readline+0x7f>
				cputchar(c);
f0101421:	83 ec 0c             	sub    $0xc,%esp
f0101424:	56                   	push   %esi
f0101425:	e8 39 f3 ff ff       	call   f0100763 <cputchar>
f010142a:	83 c4 10             	add    $0x10,%esp
f010142d:	eb b4                	jmp    f01013e3 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f010142f:	83 fe 0a             	cmp    $0xa,%esi
f0101432:	74 05                	je     f0101439 <readline+0xd5>
f0101434:	83 fe 0d             	cmp    $0xd,%esi
f0101437:	75 b6                	jne    f01013ef <readline+0x8b>
			if (echoing)
f0101439:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010143d:	75 13                	jne    f0101452 <readline+0xee>
			buf[i] = 0;
f010143f:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f0101446:	00 
			return buf;
f0101447:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f010144d:	e9 6f ff ff ff       	jmp    f01013c1 <readline+0x5d>
				cputchar('\n');
f0101452:	83 ec 0c             	sub    $0xc,%esp
f0101455:	6a 0a                	push   $0xa
f0101457:	e8 07 f3 ff ff       	call   f0100763 <cputchar>
f010145c:	83 c4 10             	add    $0x10,%esp
f010145f:	eb de                	jmp    f010143f <readline+0xdb>

f0101461 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101461:	55                   	push   %ebp
f0101462:	89 e5                	mov    %esp,%ebp
f0101464:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101467:	b8 00 00 00 00       	mov    $0x0,%eax
f010146c:	eb 03                	jmp    f0101471 <strlen+0x10>
		n++;
f010146e:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101471:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101475:	75 f7                	jne    f010146e <strlen+0xd>
	return n;
}
f0101477:	5d                   	pop    %ebp
f0101478:	c3                   	ret    

f0101479 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101479:	55                   	push   %ebp
f010147a:	89 e5                	mov    %esp,%ebp
f010147c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010147f:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101482:	b8 00 00 00 00       	mov    $0x0,%eax
f0101487:	eb 03                	jmp    f010148c <strnlen+0x13>
		n++;
f0101489:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010148c:	39 d0                	cmp    %edx,%eax
f010148e:	74 06                	je     f0101496 <strnlen+0x1d>
f0101490:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101494:	75 f3                	jne    f0101489 <strnlen+0x10>
	return n;
}
f0101496:	5d                   	pop    %ebp
f0101497:	c3                   	ret    

f0101498 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101498:	55                   	push   %ebp
f0101499:	89 e5                	mov    %esp,%ebp
f010149b:	53                   	push   %ebx
f010149c:	8b 45 08             	mov    0x8(%ebp),%eax
f010149f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014a2:	89 c2                	mov    %eax,%edx
f01014a4:	83 c1 01             	add    $0x1,%ecx
f01014a7:	83 c2 01             	add    $0x1,%edx
f01014aa:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01014ae:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014b1:	84 db                	test   %bl,%bl
f01014b3:	75 ef                	jne    f01014a4 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014b5:	5b                   	pop    %ebx
f01014b6:	5d                   	pop    %ebp
f01014b7:	c3                   	ret    

f01014b8 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014b8:	55                   	push   %ebp
f01014b9:	89 e5                	mov    %esp,%ebp
f01014bb:	53                   	push   %ebx
f01014bc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014bf:	53                   	push   %ebx
f01014c0:	e8 9c ff ff ff       	call   f0101461 <strlen>
f01014c5:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01014c8:	ff 75 0c             	pushl  0xc(%ebp)
f01014cb:	01 d8                	add    %ebx,%eax
f01014cd:	50                   	push   %eax
f01014ce:	e8 c5 ff ff ff       	call   f0101498 <strcpy>
	return dst;
}
f01014d3:	89 d8                	mov    %ebx,%eax
f01014d5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014d8:	c9                   	leave  
f01014d9:	c3                   	ret    

f01014da <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014da:	55                   	push   %ebp
f01014db:	89 e5                	mov    %esp,%ebp
f01014dd:	56                   	push   %esi
f01014de:	53                   	push   %ebx
f01014df:	8b 75 08             	mov    0x8(%ebp),%esi
f01014e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014e5:	89 f3                	mov    %esi,%ebx
f01014e7:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014ea:	89 f2                	mov    %esi,%edx
f01014ec:	eb 0f                	jmp    f01014fd <strncpy+0x23>
		*dst++ = *src;
f01014ee:	83 c2 01             	add    $0x1,%edx
f01014f1:	0f b6 01             	movzbl (%ecx),%eax
f01014f4:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014f7:	80 39 01             	cmpb   $0x1,(%ecx)
f01014fa:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01014fd:	39 da                	cmp    %ebx,%edx
f01014ff:	75 ed                	jne    f01014ee <strncpy+0x14>
	}
	return ret;
}
f0101501:	89 f0                	mov    %esi,%eax
f0101503:	5b                   	pop    %ebx
f0101504:	5e                   	pop    %esi
f0101505:	5d                   	pop    %ebp
f0101506:	c3                   	ret    

f0101507 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101507:	55                   	push   %ebp
f0101508:	89 e5                	mov    %esp,%ebp
f010150a:	56                   	push   %esi
f010150b:	53                   	push   %ebx
f010150c:	8b 75 08             	mov    0x8(%ebp),%esi
f010150f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101512:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101515:	89 f0                	mov    %esi,%eax
f0101517:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010151b:	85 c9                	test   %ecx,%ecx
f010151d:	75 0b                	jne    f010152a <strlcpy+0x23>
f010151f:	eb 17                	jmp    f0101538 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101521:	83 c2 01             	add    $0x1,%edx
f0101524:	83 c0 01             	add    $0x1,%eax
f0101527:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f010152a:	39 d8                	cmp    %ebx,%eax
f010152c:	74 07                	je     f0101535 <strlcpy+0x2e>
f010152e:	0f b6 0a             	movzbl (%edx),%ecx
f0101531:	84 c9                	test   %cl,%cl
f0101533:	75 ec                	jne    f0101521 <strlcpy+0x1a>
		*dst = '\0';
f0101535:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101538:	29 f0                	sub    %esi,%eax
}
f010153a:	5b                   	pop    %ebx
f010153b:	5e                   	pop    %esi
f010153c:	5d                   	pop    %ebp
f010153d:	c3                   	ret    

f010153e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010153e:	55                   	push   %ebp
f010153f:	89 e5                	mov    %esp,%ebp
f0101541:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101544:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101547:	eb 06                	jmp    f010154f <strcmp+0x11>
		p++, q++;
f0101549:	83 c1 01             	add    $0x1,%ecx
f010154c:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010154f:	0f b6 01             	movzbl (%ecx),%eax
f0101552:	84 c0                	test   %al,%al
f0101554:	74 04                	je     f010155a <strcmp+0x1c>
f0101556:	3a 02                	cmp    (%edx),%al
f0101558:	74 ef                	je     f0101549 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010155a:	0f b6 c0             	movzbl %al,%eax
f010155d:	0f b6 12             	movzbl (%edx),%edx
f0101560:	29 d0                	sub    %edx,%eax
}
f0101562:	5d                   	pop    %ebp
f0101563:	c3                   	ret    

f0101564 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101564:	55                   	push   %ebp
f0101565:	89 e5                	mov    %esp,%ebp
f0101567:	53                   	push   %ebx
f0101568:	8b 45 08             	mov    0x8(%ebp),%eax
f010156b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010156e:	89 c3                	mov    %eax,%ebx
f0101570:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101573:	eb 06                	jmp    f010157b <strncmp+0x17>
		n--, p++, q++;
f0101575:	83 c0 01             	add    $0x1,%eax
f0101578:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010157b:	39 d8                	cmp    %ebx,%eax
f010157d:	74 16                	je     f0101595 <strncmp+0x31>
f010157f:	0f b6 08             	movzbl (%eax),%ecx
f0101582:	84 c9                	test   %cl,%cl
f0101584:	74 04                	je     f010158a <strncmp+0x26>
f0101586:	3a 0a                	cmp    (%edx),%cl
f0101588:	74 eb                	je     f0101575 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010158a:	0f b6 00             	movzbl (%eax),%eax
f010158d:	0f b6 12             	movzbl (%edx),%edx
f0101590:	29 d0                	sub    %edx,%eax
}
f0101592:	5b                   	pop    %ebx
f0101593:	5d                   	pop    %ebp
f0101594:	c3                   	ret    
		return 0;
f0101595:	b8 00 00 00 00       	mov    $0x0,%eax
f010159a:	eb f6                	jmp    f0101592 <strncmp+0x2e>

f010159c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010159c:	55                   	push   %ebp
f010159d:	89 e5                	mov    %esp,%ebp
f010159f:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015a6:	0f b6 10             	movzbl (%eax),%edx
f01015a9:	84 d2                	test   %dl,%dl
f01015ab:	74 09                	je     f01015b6 <strchr+0x1a>
		if (*s == c)
f01015ad:	38 ca                	cmp    %cl,%dl
f01015af:	74 0a                	je     f01015bb <strchr+0x1f>
	for (; *s; s++)
f01015b1:	83 c0 01             	add    $0x1,%eax
f01015b4:	eb f0                	jmp    f01015a6 <strchr+0xa>
			return (char *) s;
	return 0;
f01015b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015bb:	5d                   	pop    %ebp
f01015bc:	c3                   	ret    

f01015bd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015bd:	55                   	push   %ebp
f01015be:	89 e5                	mov    %esp,%ebp
f01015c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015c7:	eb 03                	jmp    f01015cc <strfind+0xf>
f01015c9:	83 c0 01             	add    $0x1,%eax
f01015cc:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01015cf:	38 ca                	cmp    %cl,%dl
f01015d1:	74 04                	je     f01015d7 <strfind+0x1a>
f01015d3:	84 d2                	test   %dl,%dl
f01015d5:	75 f2                	jne    f01015c9 <strfind+0xc>
			break;
	return (char *) s;
}
f01015d7:	5d                   	pop    %ebp
f01015d8:	c3                   	ret    

f01015d9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015d9:	55                   	push   %ebp
f01015da:	89 e5                	mov    %esp,%ebp
f01015dc:	57                   	push   %edi
f01015dd:	56                   	push   %esi
f01015de:	53                   	push   %ebx
f01015df:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015e2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015e5:	85 c9                	test   %ecx,%ecx
f01015e7:	74 13                	je     f01015fc <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015e9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015ef:	75 05                	jne    f01015f6 <memset+0x1d>
f01015f1:	f6 c1 03             	test   $0x3,%cl
f01015f4:	74 0d                	je     f0101603 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015f9:	fc                   	cld    
f01015fa:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015fc:	89 f8                	mov    %edi,%eax
f01015fe:	5b                   	pop    %ebx
f01015ff:	5e                   	pop    %esi
f0101600:	5f                   	pop    %edi
f0101601:	5d                   	pop    %ebp
f0101602:	c3                   	ret    
		c &= 0xFF;
f0101603:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101607:	89 d3                	mov    %edx,%ebx
f0101609:	c1 e3 08             	shl    $0x8,%ebx
f010160c:	89 d0                	mov    %edx,%eax
f010160e:	c1 e0 18             	shl    $0x18,%eax
f0101611:	89 d6                	mov    %edx,%esi
f0101613:	c1 e6 10             	shl    $0x10,%esi
f0101616:	09 f0                	or     %esi,%eax
f0101618:	09 c2                	or     %eax,%edx
f010161a:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f010161c:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010161f:	89 d0                	mov    %edx,%eax
f0101621:	fc                   	cld    
f0101622:	f3 ab                	rep stos %eax,%es:(%edi)
f0101624:	eb d6                	jmp    f01015fc <memset+0x23>

f0101626 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101626:	55                   	push   %ebp
f0101627:	89 e5                	mov    %esp,%ebp
f0101629:	57                   	push   %edi
f010162a:	56                   	push   %esi
f010162b:	8b 45 08             	mov    0x8(%ebp),%eax
f010162e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101631:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101634:	39 c6                	cmp    %eax,%esi
f0101636:	73 35                	jae    f010166d <memmove+0x47>
f0101638:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010163b:	39 c2                	cmp    %eax,%edx
f010163d:	76 2e                	jbe    f010166d <memmove+0x47>
		s += n;
		d += n;
f010163f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101642:	89 d6                	mov    %edx,%esi
f0101644:	09 fe                	or     %edi,%esi
f0101646:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010164c:	74 0c                	je     f010165a <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010164e:	83 ef 01             	sub    $0x1,%edi
f0101651:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101654:	fd                   	std    
f0101655:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101657:	fc                   	cld    
f0101658:	eb 21                	jmp    f010167b <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010165a:	f6 c1 03             	test   $0x3,%cl
f010165d:	75 ef                	jne    f010164e <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010165f:	83 ef 04             	sub    $0x4,%edi
f0101662:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101665:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101668:	fd                   	std    
f0101669:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010166b:	eb ea                	jmp    f0101657 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010166d:	89 f2                	mov    %esi,%edx
f010166f:	09 c2                	or     %eax,%edx
f0101671:	f6 c2 03             	test   $0x3,%dl
f0101674:	74 09                	je     f010167f <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101676:	89 c7                	mov    %eax,%edi
f0101678:	fc                   	cld    
f0101679:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010167b:	5e                   	pop    %esi
f010167c:	5f                   	pop    %edi
f010167d:	5d                   	pop    %ebp
f010167e:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010167f:	f6 c1 03             	test   $0x3,%cl
f0101682:	75 f2                	jne    f0101676 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101684:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101687:	89 c7                	mov    %eax,%edi
f0101689:	fc                   	cld    
f010168a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010168c:	eb ed                	jmp    f010167b <memmove+0x55>

f010168e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010168e:	55                   	push   %ebp
f010168f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101691:	ff 75 10             	pushl  0x10(%ebp)
f0101694:	ff 75 0c             	pushl  0xc(%ebp)
f0101697:	ff 75 08             	pushl  0x8(%ebp)
f010169a:	e8 87 ff ff ff       	call   f0101626 <memmove>
}
f010169f:	c9                   	leave  
f01016a0:	c3                   	ret    

f01016a1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016a1:	55                   	push   %ebp
f01016a2:	89 e5                	mov    %esp,%ebp
f01016a4:	56                   	push   %esi
f01016a5:	53                   	push   %ebx
f01016a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016ac:	89 c6                	mov    %eax,%esi
f01016ae:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016b1:	39 f0                	cmp    %esi,%eax
f01016b3:	74 1c                	je     f01016d1 <memcmp+0x30>
		if (*s1 != *s2)
f01016b5:	0f b6 08             	movzbl (%eax),%ecx
f01016b8:	0f b6 1a             	movzbl (%edx),%ebx
f01016bb:	38 d9                	cmp    %bl,%cl
f01016bd:	75 08                	jne    f01016c7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01016bf:	83 c0 01             	add    $0x1,%eax
f01016c2:	83 c2 01             	add    $0x1,%edx
f01016c5:	eb ea                	jmp    f01016b1 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01016c7:	0f b6 c1             	movzbl %cl,%eax
f01016ca:	0f b6 db             	movzbl %bl,%ebx
f01016cd:	29 d8                	sub    %ebx,%eax
f01016cf:	eb 05                	jmp    f01016d6 <memcmp+0x35>
	}

	return 0;
f01016d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016d6:	5b                   	pop    %ebx
f01016d7:	5e                   	pop    %esi
f01016d8:	5d                   	pop    %ebp
f01016d9:	c3                   	ret    

f01016da <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016da:	55                   	push   %ebp
f01016db:	89 e5                	mov    %esp,%ebp
f01016dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01016e0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016e3:	89 c2                	mov    %eax,%edx
f01016e5:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016e8:	39 d0                	cmp    %edx,%eax
f01016ea:	73 09                	jae    f01016f5 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016ec:	38 08                	cmp    %cl,(%eax)
f01016ee:	74 05                	je     f01016f5 <memfind+0x1b>
	for (; s < ends; s++)
f01016f0:	83 c0 01             	add    $0x1,%eax
f01016f3:	eb f3                	jmp    f01016e8 <memfind+0xe>
			break;
	return (void *) s;
}
f01016f5:	5d                   	pop    %ebp
f01016f6:	c3                   	ret    

f01016f7 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016f7:	55                   	push   %ebp
f01016f8:	89 e5                	mov    %esp,%ebp
f01016fa:	57                   	push   %edi
f01016fb:	56                   	push   %esi
f01016fc:	53                   	push   %ebx
f01016fd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101700:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101703:	eb 03                	jmp    f0101708 <strtol+0x11>
		s++;
f0101705:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101708:	0f b6 01             	movzbl (%ecx),%eax
f010170b:	3c 20                	cmp    $0x20,%al
f010170d:	74 f6                	je     f0101705 <strtol+0xe>
f010170f:	3c 09                	cmp    $0x9,%al
f0101711:	74 f2                	je     f0101705 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101713:	3c 2b                	cmp    $0x2b,%al
f0101715:	74 2e                	je     f0101745 <strtol+0x4e>
	int neg = 0;
f0101717:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010171c:	3c 2d                	cmp    $0x2d,%al
f010171e:	74 2f                	je     f010174f <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101720:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101726:	75 05                	jne    f010172d <strtol+0x36>
f0101728:	80 39 30             	cmpb   $0x30,(%ecx)
f010172b:	74 2c                	je     f0101759 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010172d:	85 db                	test   %ebx,%ebx
f010172f:	75 0a                	jne    f010173b <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101731:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101736:	80 39 30             	cmpb   $0x30,(%ecx)
f0101739:	74 28                	je     f0101763 <strtol+0x6c>
		base = 10;
f010173b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101740:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101743:	eb 50                	jmp    f0101795 <strtol+0x9e>
		s++;
f0101745:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101748:	bf 00 00 00 00       	mov    $0x0,%edi
f010174d:	eb d1                	jmp    f0101720 <strtol+0x29>
		s++, neg = 1;
f010174f:	83 c1 01             	add    $0x1,%ecx
f0101752:	bf 01 00 00 00       	mov    $0x1,%edi
f0101757:	eb c7                	jmp    f0101720 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101759:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010175d:	74 0e                	je     f010176d <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010175f:	85 db                	test   %ebx,%ebx
f0101761:	75 d8                	jne    f010173b <strtol+0x44>
		s++, base = 8;
f0101763:	83 c1 01             	add    $0x1,%ecx
f0101766:	bb 08 00 00 00       	mov    $0x8,%ebx
f010176b:	eb ce                	jmp    f010173b <strtol+0x44>
		s += 2, base = 16;
f010176d:	83 c1 02             	add    $0x2,%ecx
f0101770:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101775:	eb c4                	jmp    f010173b <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101777:	8d 72 9f             	lea    -0x61(%edx),%esi
f010177a:	89 f3                	mov    %esi,%ebx
f010177c:	80 fb 19             	cmp    $0x19,%bl
f010177f:	77 29                	ja     f01017aa <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101781:	0f be d2             	movsbl %dl,%edx
f0101784:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101787:	3b 55 10             	cmp    0x10(%ebp),%edx
f010178a:	7d 30                	jge    f01017bc <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010178c:	83 c1 01             	add    $0x1,%ecx
f010178f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101793:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101795:	0f b6 11             	movzbl (%ecx),%edx
f0101798:	8d 72 d0             	lea    -0x30(%edx),%esi
f010179b:	89 f3                	mov    %esi,%ebx
f010179d:	80 fb 09             	cmp    $0x9,%bl
f01017a0:	77 d5                	ja     f0101777 <strtol+0x80>
			dig = *s - '0';
f01017a2:	0f be d2             	movsbl %dl,%edx
f01017a5:	83 ea 30             	sub    $0x30,%edx
f01017a8:	eb dd                	jmp    f0101787 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01017aa:	8d 72 bf             	lea    -0x41(%edx),%esi
f01017ad:	89 f3                	mov    %esi,%ebx
f01017af:	80 fb 19             	cmp    $0x19,%bl
f01017b2:	77 08                	ja     f01017bc <strtol+0xc5>
			dig = *s - 'A' + 10;
f01017b4:	0f be d2             	movsbl %dl,%edx
f01017b7:	83 ea 37             	sub    $0x37,%edx
f01017ba:	eb cb                	jmp    f0101787 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01017bc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017c0:	74 05                	je     f01017c7 <strtol+0xd0>
		*endptr = (char *) s;
f01017c2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017c5:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01017c7:	89 c2                	mov    %eax,%edx
f01017c9:	f7 da                	neg    %edx
f01017cb:	85 ff                	test   %edi,%edi
f01017cd:	0f 45 c2             	cmovne %edx,%eax
}
f01017d0:	5b                   	pop    %ebx
f01017d1:	5e                   	pop    %esi
f01017d2:	5f                   	pop    %edi
f01017d3:	5d                   	pop    %ebp
f01017d4:	c3                   	ret    
f01017d5:	66 90                	xchg   %ax,%ax
f01017d7:	66 90                	xchg   %ax,%ax
f01017d9:	66 90                	xchg   %ax,%ax
f01017db:	66 90                	xchg   %ax,%ax
f01017dd:	66 90                	xchg   %ax,%ax
f01017df:	90                   	nop

f01017e0 <__udivdi3>:
f01017e0:	55                   	push   %ebp
f01017e1:	57                   	push   %edi
f01017e2:	56                   	push   %esi
f01017e3:	53                   	push   %ebx
f01017e4:	83 ec 1c             	sub    $0x1c,%esp
f01017e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017eb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01017ef:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017f3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01017f7:	85 d2                	test   %edx,%edx
f01017f9:	75 35                	jne    f0101830 <__udivdi3+0x50>
f01017fb:	39 f3                	cmp    %esi,%ebx
f01017fd:	0f 87 bd 00 00 00    	ja     f01018c0 <__udivdi3+0xe0>
f0101803:	85 db                	test   %ebx,%ebx
f0101805:	89 d9                	mov    %ebx,%ecx
f0101807:	75 0b                	jne    f0101814 <__udivdi3+0x34>
f0101809:	b8 01 00 00 00       	mov    $0x1,%eax
f010180e:	31 d2                	xor    %edx,%edx
f0101810:	f7 f3                	div    %ebx
f0101812:	89 c1                	mov    %eax,%ecx
f0101814:	31 d2                	xor    %edx,%edx
f0101816:	89 f0                	mov    %esi,%eax
f0101818:	f7 f1                	div    %ecx
f010181a:	89 c6                	mov    %eax,%esi
f010181c:	89 e8                	mov    %ebp,%eax
f010181e:	89 f7                	mov    %esi,%edi
f0101820:	f7 f1                	div    %ecx
f0101822:	89 fa                	mov    %edi,%edx
f0101824:	83 c4 1c             	add    $0x1c,%esp
f0101827:	5b                   	pop    %ebx
f0101828:	5e                   	pop    %esi
f0101829:	5f                   	pop    %edi
f010182a:	5d                   	pop    %ebp
f010182b:	c3                   	ret    
f010182c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101830:	39 f2                	cmp    %esi,%edx
f0101832:	77 7c                	ja     f01018b0 <__udivdi3+0xd0>
f0101834:	0f bd fa             	bsr    %edx,%edi
f0101837:	83 f7 1f             	xor    $0x1f,%edi
f010183a:	0f 84 98 00 00 00    	je     f01018d8 <__udivdi3+0xf8>
f0101840:	89 f9                	mov    %edi,%ecx
f0101842:	b8 20 00 00 00       	mov    $0x20,%eax
f0101847:	29 f8                	sub    %edi,%eax
f0101849:	d3 e2                	shl    %cl,%edx
f010184b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010184f:	89 c1                	mov    %eax,%ecx
f0101851:	89 da                	mov    %ebx,%edx
f0101853:	d3 ea                	shr    %cl,%edx
f0101855:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101859:	09 d1                	or     %edx,%ecx
f010185b:	89 f2                	mov    %esi,%edx
f010185d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101861:	89 f9                	mov    %edi,%ecx
f0101863:	d3 e3                	shl    %cl,%ebx
f0101865:	89 c1                	mov    %eax,%ecx
f0101867:	d3 ea                	shr    %cl,%edx
f0101869:	89 f9                	mov    %edi,%ecx
f010186b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010186f:	d3 e6                	shl    %cl,%esi
f0101871:	89 eb                	mov    %ebp,%ebx
f0101873:	89 c1                	mov    %eax,%ecx
f0101875:	d3 eb                	shr    %cl,%ebx
f0101877:	09 de                	or     %ebx,%esi
f0101879:	89 f0                	mov    %esi,%eax
f010187b:	f7 74 24 08          	divl   0x8(%esp)
f010187f:	89 d6                	mov    %edx,%esi
f0101881:	89 c3                	mov    %eax,%ebx
f0101883:	f7 64 24 0c          	mull   0xc(%esp)
f0101887:	39 d6                	cmp    %edx,%esi
f0101889:	72 0c                	jb     f0101897 <__udivdi3+0xb7>
f010188b:	89 f9                	mov    %edi,%ecx
f010188d:	d3 e5                	shl    %cl,%ebp
f010188f:	39 c5                	cmp    %eax,%ebp
f0101891:	73 5d                	jae    f01018f0 <__udivdi3+0x110>
f0101893:	39 d6                	cmp    %edx,%esi
f0101895:	75 59                	jne    f01018f0 <__udivdi3+0x110>
f0101897:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010189a:	31 ff                	xor    %edi,%edi
f010189c:	89 fa                	mov    %edi,%edx
f010189e:	83 c4 1c             	add    $0x1c,%esp
f01018a1:	5b                   	pop    %ebx
f01018a2:	5e                   	pop    %esi
f01018a3:	5f                   	pop    %edi
f01018a4:	5d                   	pop    %ebp
f01018a5:	c3                   	ret    
f01018a6:	8d 76 00             	lea    0x0(%esi),%esi
f01018a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01018b0:	31 ff                	xor    %edi,%edi
f01018b2:	31 c0                	xor    %eax,%eax
f01018b4:	89 fa                	mov    %edi,%edx
f01018b6:	83 c4 1c             	add    $0x1c,%esp
f01018b9:	5b                   	pop    %ebx
f01018ba:	5e                   	pop    %esi
f01018bb:	5f                   	pop    %edi
f01018bc:	5d                   	pop    %ebp
f01018bd:	c3                   	ret    
f01018be:	66 90                	xchg   %ax,%ax
f01018c0:	31 ff                	xor    %edi,%edi
f01018c2:	89 e8                	mov    %ebp,%eax
f01018c4:	89 f2                	mov    %esi,%edx
f01018c6:	f7 f3                	div    %ebx
f01018c8:	89 fa                	mov    %edi,%edx
f01018ca:	83 c4 1c             	add    $0x1c,%esp
f01018cd:	5b                   	pop    %ebx
f01018ce:	5e                   	pop    %esi
f01018cf:	5f                   	pop    %edi
f01018d0:	5d                   	pop    %ebp
f01018d1:	c3                   	ret    
f01018d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018d8:	39 f2                	cmp    %esi,%edx
f01018da:	72 06                	jb     f01018e2 <__udivdi3+0x102>
f01018dc:	31 c0                	xor    %eax,%eax
f01018de:	39 eb                	cmp    %ebp,%ebx
f01018e0:	77 d2                	ja     f01018b4 <__udivdi3+0xd4>
f01018e2:	b8 01 00 00 00       	mov    $0x1,%eax
f01018e7:	eb cb                	jmp    f01018b4 <__udivdi3+0xd4>
f01018e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01018f0:	89 d8                	mov    %ebx,%eax
f01018f2:	31 ff                	xor    %edi,%edi
f01018f4:	eb be                	jmp    f01018b4 <__udivdi3+0xd4>
f01018f6:	66 90                	xchg   %ax,%ax
f01018f8:	66 90                	xchg   %ax,%ax
f01018fa:	66 90                	xchg   %ax,%ax
f01018fc:	66 90                	xchg   %ax,%ax
f01018fe:	66 90                	xchg   %ax,%ax

f0101900 <__umoddi3>:
f0101900:	55                   	push   %ebp
f0101901:	57                   	push   %edi
f0101902:	56                   	push   %esi
f0101903:	53                   	push   %ebx
f0101904:	83 ec 1c             	sub    $0x1c,%esp
f0101907:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010190b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010190f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101913:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101917:	85 ed                	test   %ebp,%ebp
f0101919:	89 f0                	mov    %esi,%eax
f010191b:	89 da                	mov    %ebx,%edx
f010191d:	75 19                	jne    f0101938 <__umoddi3+0x38>
f010191f:	39 df                	cmp    %ebx,%edi
f0101921:	0f 86 b1 00 00 00    	jbe    f01019d8 <__umoddi3+0xd8>
f0101927:	f7 f7                	div    %edi
f0101929:	89 d0                	mov    %edx,%eax
f010192b:	31 d2                	xor    %edx,%edx
f010192d:	83 c4 1c             	add    $0x1c,%esp
f0101930:	5b                   	pop    %ebx
f0101931:	5e                   	pop    %esi
f0101932:	5f                   	pop    %edi
f0101933:	5d                   	pop    %ebp
f0101934:	c3                   	ret    
f0101935:	8d 76 00             	lea    0x0(%esi),%esi
f0101938:	39 dd                	cmp    %ebx,%ebp
f010193a:	77 f1                	ja     f010192d <__umoddi3+0x2d>
f010193c:	0f bd cd             	bsr    %ebp,%ecx
f010193f:	83 f1 1f             	xor    $0x1f,%ecx
f0101942:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101946:	0f 84 b4 00 00 00    	je     f0101a00 <__umoddi3+0x100>
f010194c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101951:	89 c2                	mov    %eax,%edx
f0101953:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101957:	29 c2                	sub    %eax,%edx
f0101959:	89 c1                	mov    %eax,%ecx
f010195b:	89 f8                	mov    %edi,%eax
f010195d:	d3 e5                	shl    %cl,%ebp
f010195f:	89 d1                	mov    %edx,%ecx
f0101961:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101965:	d3 e8                	shr    %cl,%eax
f0101967:	09 c5                	or     %eax,%ebp
f0101969:	8b 44 24 04          	mov    0x4(%esp),%eax
f010196d:	89 c1                	mov    %eax,%ecx
f010196f:	d3 e7                	shl    %cl,%edi
f0101971:	89 d1                	mov    %edx,%ecx
f0101973:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101977:	89 df                	mov    %ebx,%edi
f0101979:	d3 ef                	shr    %cl,%edi
f010197b:	89 c1                	mov    %eax,%ecx
f010197d:	89 f0                	mov    %esi,%eax
f010197f:	d3 e3                	shl    %cl,%ebx
f0101981:	89 d1                	mov    %edx,%ecx
f0101983:	89 fa                	mov    %edi,%edx
f0101985:	d3 e8                	shr    %cl,%eax
f0101987:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010198c:	09 d8                	or     %ebx,%eax
f010198e:	f7 f5                	div    %ebp
f0101990:	d3 e6                	shl    %cl,%esi
f0101992:	89 d1                	mov    %edx,%ecx
f0101994:	f7 64 24 08          	mull   0x8(%esp)
f0101998:	39 d1                	cmp    %edx,%ecx
f010199a:	89 c3                	mov    %eax,%ebx
f010199c:	89 d7                	mov    %edx,%edi
f010199e:	72 06                	jb     f01019a6 <__umoddi3+0xa6>
f01019a0:	75 0e                	jne    f01019b0 <__umoddi3+0xb0>
f01019a2:	39 c6                	cmp    %eax,%esi
f01019a4:	73 0a                	jae    f01019b0 <__umoddi3+0xb0>
f01019a6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01019aa:	19 ea                	sbb    %ebp,%edx
f01019ac:	89 d7                	mov    %edx,%edi
f01019ae:	89 c3                	mov    %eax,%ebx
f01019b0:	89 ca                	mov    %ecx,%edx
f01019b2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01019b7:	29 de                	sub    %ebx,%esi
f01019b9:	19 fa                	sbb    %edi,%edx
f01019bb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01019bf:	89 d0                	mov    %edx,%eax
f01019c1:	d3 e0                	shl    %cl,%eax
f01019c3:	89 d9                	mov    %ebx,%ecx
f01019c5:	d3 ee                	shr    %cl,%esi
f01019c7:	d3 ea                	shr    %cl,%edx
f01019c9:	09 f0                	or     %esi,%eax
f01019cb:	83 c4 1c             	add    $0x1c,%esp
f01019ce:	5b                   	pop    %ebx
f01019cf:	5e                   	pop    %esi
f01019d0:	5f                   	pop    %edi
f01019d1:	5d                   	pop    %ebp
f01019d2:	c3                   	ret    
f01019d3:	90                   	nop
f01019d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019d8:	85 ff                	test   %edi,%edi
f01019da:	89 f9                	mov    %edi,%ecx
f01019dc:	75 0b                	jne    f01019e9 <__umoddi3+0xe9>
f01019de:	b8 01 00 00 00       	mov    $0x1,%eax
f01019e3:	31 d2                	xor    %edx,%edx
f01019e5:	f7 f7                	div    %edi
f01019e7:	89 c1                	mov    %eax,%ecx
f01019e9:	89 d8                	mov    %ebx,%eax
f01019eb:	31 d2                	xor    %edx,%edx
f01019ed:	f7 f1                	div    %ecx
f01019ef:	89 f0                	mov    %esi,%eax
f01019f1:	f7 f1                	div    %ecx
f01019f3:	e9 31 ff ff ff       	jmp    f0101929 <__umoddi3+0x29>
f01019f8:	90                   	nop
f01019f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a00:	39 dd                	cmp    %ebx,%ebp
f0101a02:	72 08                	jb     f0101a0c <__umoddi3+0x10c>
f0101a04:	39 f7                	cmp    %esi,%edi
f0101a06:	0f 87 21 ff ff ff    	ja     f010192d <__umoddi3+0x2d>
f0101a0c:	89 da                	mov    %ebx,%edx
f0101a0e:	89 f0                	mov    %esi,%eax
f0101a10:	29 f8                	sub    %edi,%eax
f0101a12:	19 ea                	sbb    %ebp,%edx
f0101a14:	e9 14 ff ff ff       	jmp    f010192d <__umoddi3+0x2d>
