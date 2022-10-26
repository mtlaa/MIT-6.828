
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
f0100057:	8d 83 98 07 ff ff    	lea    -0xf868(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 9f 0a 00 00       	call   f0100b02 <cprintf>
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
f010007f:	8d 83 b4 07 ff ff    	lea    -0xf84c(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 77 0a 00 00       	call   f0100b02 <cprintf>
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
f01000ca:	e8 93 15 00 00       	call   f0101662 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 6d 05 00 00       	call   f0100641 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 cf 07 ff ff    	lea    -0xf831(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 1a 0a 00 00       	call   f0100b02 <cprintf>
	
	unsigned int i = 0x00646c72;
f01000e8:	c7 45 f4 72 6c 64 00 	movl   $0x646c72,-0xc(%ebp)
	Lab1_exercise8_3:
    cprintf("H%x Wo%s\n", 57616, &i);
f01000ef:	83 c4 0c             	add    $0xc,%esp
f01000f2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01000f5:	50                   	push   %eax
f01000f6:	68 10 e1 00 00       	push   $0xe110
f01000fb:	8d 83 ea 07 ff ff    	lea    -0xf816(%ebx),%eax
f0100101:	50                   	push   %eax
f0100102:	e8 fb 09 00 00       	call   f0100b02 <cprintf>
	cprintf("x=%d y=%d\n", 3);
f0100107:	83 c4 08             	add    $0x8,%esp
f010010a:	6a 03                	push   $0x3
f010010c:	8d 83 f4 07 ff ff    	lea    -0xf80c(%ebx),%eax
f0100112:	50                   	push   %eax
f0100113:	e8 ea 09 00 00       	call   f0100b02 <cprintf>

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
f010012c:	e8 15 08 00 00       	call   f0100946 <monitor>
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
f010015d:	e8 e4 07 00 00       	call   f0100946 <monitor>
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
f0100177:	8d 83 ff 07 ff ff    	lea    -0xf801(%ebx),%eax
f010017d:	50                   	push   %eax
f010017e:	e8 7f 09 00 00       	call   f0100b02 <cprintf>
	vcprintf(fmt, ap);
f0100183:	83 c4 08             	add    $0x8,%esp
f0100186:	56                   	push   %esi
f0100187:	57                   	push   %edi
f0100188:	e8 3e 09 00 00       	call   f0100acb <vcprintf>
	cprintf("\n");
f010018d:	8d 83 3b 08 ff ff    	lea    -0xf7c5(%ebx),%eax
f0100193:	89 04 24             	mov    %eax,(%esp)
f0100196:	e8 67 09 00 00       	call   f0100b02 <cprintf>
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
f01001bc:	8d 83 17 08 ff ff    	lea    -0xf7e9(%ebx),%eax
f01001c2:	50                   	push   %eax
f01001c3:	e8 3a 09 00 00       	call   f0100b02 <cprintf>
	vcprintf(fmt, ap);
f01001c8:	83 c4 08             	add    $0x8,%esp
f01001cb:	56                   	push   %esi
f01001cc:	ff 75 10             	pushl  0x10(%ebp)
f01001cf:	e8 f7 08 00 00       	call   f0100acb <vcprintf>
	cprintf("\n");
f01001d4:	8d 83 3b 08 ff ff    	lea    -0xf7c5(%ebx),%eax
f01001da:	89 04 24             	mov    %eax,(%esp)
f01001dd:	e8 20 09 00 00       	call   f0100b02 <cprintf>
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
f01002b4:	0f b6 84 13 78 09 ff 	movzbl -0xf688(%ebx,%edx,1),%eax
f01002bb:	ff 
f01002bc:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f01002c2:	0f b6 8c 13 78 08 ff 	movzbl -0xf788(%ebx,%edx,1),%ecx
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
f0100307:	8d 83 31 08 ff ff    	lea    -0xf7cf(%ebx),%eax
f010030d:	50                   	push   %eax
f010030e:	e8 ef 07 00 00       	call   f0100b02 <cprintf>
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
f010034e:	0f b6 84 13 78 09 ff 	movzbl -0xf688(%ebx,%edx,1),%eax
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
f010056f:	e8 3b 11 00 00       	call   f01016af <memmove>
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
f0100752:	8d 83 3d 08 ff ff    	lea    -0xf7c3(%ebx),%eax
f0100758:	50                   	push   %eax
f0100759:	e8 a4 03 00 00       	call   f0100b02 <cprintf>
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
f01007a5:	8d 83 78 0a ff ff    	lea    -0xf588(%ebx),%eax
f01007ab:	50                   	push   %eax
f01007ac:	8d 83 96 0a ff ff    	lea    -0xf56a(%ebx),%eax
f01007b2:	50                   	push   %eax
f01007b3:	8d b3 9b 0a ff ff    	lea    -0xf565(%ebx),%esi
f01007b9:	56                   	push   %esi
f01007ba:	e8 43 03 00 00       	call   f0100b02 <cprintf>
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	8d 83 38 0b ff ff    	lea    -0xf4c8(%ebx),%eax
f01007c8:	50                   	push   %eax
f01007c9:	8d 83 a4 0a ff ff    	lea    -0xf55c(%ebx),%eax
f01007cf:	50                   	push   %eax
f01007d0:	56                   	push   %esi
f01007d1:	e8 2c 03 00 00       	call   f0100b02 <cprintf>
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
f01007f6:	8d 83 ad 0a ff ff    	lea    -0xf553(%ebx),%eax
f01007fc:	50                   	push   %eax
f01007fd:	e8 00 03 00 00       	call   f0100b02 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100802:	83 c4 08             	add    $0x8,%esp
f0100805:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010080b:	8d 83 60 0b ff ff    	lea    -0xf4a0(%ebx),%eax
f0100811:	50                   	push   %eax
f0100812:	e8 eb 02 00 00       	call   f0100b02 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100820:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100826:	50                   	push   %eax
f0100827:	57                   	push   %edi
f0100828:	8d 83 88 0b ff ff    	lea    -0xf478(%ebx),%eax
f010082e:	50                   	push   %eax
f010082f:	e8 ce 02 00 00       	call   f0100b02 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100834:	83 c4 0c             	add    $0xc,%esp
f0100837:	c7 c0 99 1a 10 f0    	mov    $0xf0101a99,%eax
f010083d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100843:	52                   	push   %edx
f0100844:	50                   	push   %eax
f0100845:	8d 83 ac 0b ff ff    	lea    -0xf454(%ebx),%eax
f010084b:	50                   	push   %eax
f010084c:	e8 b1 02 00 00       	call   f0100b02 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100851:	83 c4 0c             	add    $0xc,%esp
f0100854:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f010085a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100860:	52                   	push   %edx
f0100861:	50                   	push   %eax
f0100862:	8d 83 d0 0b ff ff    	lea    -0xf430(%ebx),%eax
f0100868:	50                   	push   %eax
f0100869:	e8 94 02 00 00       	call   f0100b02 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010086e:	83 c4 0c             	add    $0xc,%esp
f0100871:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f0100877:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010087d:	50                   	push   %eax
f010087e:	56                   	push   %esi
f010087f:	8d 83 f4 0b ff ff    	lea    -0xf40c(%ebx),%eax
f0100885:	50                   	push   %eax
f0100886:	e8 77 02 00 00       	call   f0100b02 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010088b:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010088e:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100894:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100896:	c1 fe 0a             	sar    $0xa,%esi
f0100899:	56                   	push   %esi
f010089a:	8d 83 18 0c ff ff    	lea    -0xf3e8(%ebx),%eax
f01008a0:	50                   	push   %eax
f01008a1:	e8 5c 02 00 00       	call   f0100b02 <cprintf>
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
f01008b6:	57                   	push   %edi
f01008b7:	56                   	push   %esi
f01008b8:	53                   	push   %ebx
f01008b9:	83 ec 28             	sub    $0x28,%esp
f01008bc:	e8 2b f9 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f01008c1:	81 c3 47 0a 01 00    	add    $0x10a47,%ebx
	// Your code here.
	cprintf("Stack backtrace:\n");
f01008c7:	8d 83 c6 0a ff ff    	lea    -0xf53a(%ebx),%eax
f01008cd:	50                   	push   %eax
f01008ce:	e8 2f 02 00 00       	call   f0100b02 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008d3:	89 ef                	mov    %ebp,%edi
	uint32_t *this_ebp = (uint32_t*)read_ebp();
	while(this_ebp!=0){
f01008d5:	83 c4 10             	add    $0x10,%esp
		uint32_t pre_ebp = *this_ebp;
		cprintf("  ebp %08x  eip %08x  args", this_ebp, *(this_ebp+1));
f01008d8:	8d 83 d8 0a ff ff    	lea    -0xf528(%ebx),%eax
f01008de:	89 45 dc             	mov    %eax,-0x24(%ebp)
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
f01008e1:	8d 83 f3 0a ff ff    	lea    -0xf50d(%ebx),%eax
f01008e7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	while(this_ebp!=0){
f01008ea:	eb 49                	jmp    f0100935 <mon_backtrace+0x82>
		uint32_t pre_ebp = *this_ebp;
f01008ec:	8b 07                	mov    (%edi),%eax
f01008ee:	89 45 e0             	mov    %eax,-0x20(%ebp)
		cprintf("  ebp %08x  eip %08x  args", this_ebp, *(this_ebp+1));
f01008f1:	83 ec 04             	sub    $0x4,%esp
f01008f4:	ff 77 04             	pushl  0x4(%edi)
f01008f7:	57                   	push   %edi
f01008f8:	ff 75 dc             	pushl  -0x24(%ebp)
f01008fb:	e8 02 02 00 00       	call   f0100b02 <cprintf>
f0100900:	8d 77 08             	lea    0x8(%edi),%esi
f0100903:	83 c7 1c             	add    $0x1c,%edi
f0100906:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f0100909:	83 ec 08             	sub    $0x8,%esp
f010090c:	ff 36                	pushl  (%esi)
f010090e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100911:	e8 ec 01 00 00       	call   f0100b02 <cprintf>
f0100916:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f0100919:	83 c4 10             	add    $0x10,%esp
f010091c:	39 fe                	cmp    %edi,%esi
f010091e:	75 e9                	jne    f0100909 <mon_backtrace+0x56>
		}
		cprintf("\n");
f0100920:	83 ec 0c             	sub    $0xc,%esp
f0100923:	8d 83 3b 08 ff ff    	lea    -0xf7c5(%ebx),%eax
f0100929:	50                   	push   %eax
f010092a:	e8 d3 01 00 00       	call   f0100b02 <cprintf>
		this_ebp = (uint32_t*)pre_ebp;
f010092f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100932:	83 c4 10             	add    $0x10,%esp
	while(this_ebp!=0){
f0100935:	85 ff                	test   %edi,%edi
f0100937:	75 b3                	jne    f01008ec <mon_backtrace+0x39>
	}
	return 0;
}
f0100939:	b8 00 00 00 00       	mov    $0x0,%eax
f010093e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100941:	5b                   	pop    %ebx
f0100942:	5e                   	pop    %esi
f0100943:	5f                   	pop    %edi
f0100944:	5d                   	pop    %ebp
f0100945:	c3                   	ret    

f0100946 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100946:	55                   	push   %ebp
f0100947:	89 e5                	mov    %esp,%ebp
f0100949:	57                   	push   %edi
f010094a:	56                   	push   %esi
f010094b:	53                   	push   %ebx
f010094c:	83 ec 68             	sub    $0x68,%esp
f010094f:	e8 98 f8 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100954:	81 c3 b4 09 01 00    	add    $0x109b4,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010095a:	8d 83 44 0c ff ff    	lea    -0xf3bc(%ebx),%eax
f0100960:	50                   	push   %eax
f0100961:	e8 9c 01 00 00       	call   f0100b02 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100966:	8d 83 68 0c ff ff    	lea    -0xf398(%ebx),%eax
f010096c:	89 04 24             	mov    %eax,(%esp)
f010096f:	e8 8e 01 00 00       	call   f0100b02 <cprintf>
f0100974:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100977:	8d bb fd 0a ff ff    	lea    -0xf503(%ebx),%edi
f010097d:	eb 4a                	jmp    f01009c9 <monitor+0x83>
f010097f:	83 ec 08             	sub    $0x8,%esp
f0100982:	0f be c0             	movsbl %al,%eax
f0100985:	50                   	push   %eax
f0100986:	57                   	push   %edi
f0100987:	e8 99 0c 00 00       	call   f0101625 <strchr>
f010098c:	83 c4 10             	add    $0x10,%esp
f010098f:	85 c0                	test   %eax,%eax
f0100991:	74 08                	je     f010099b <monitor+0x55>
			*buf++ = 0;
f0100993:	c6 06 00             	movb   $0x0,(%esi)
f0100996:	8d 76 01             	lea    0x1(%esi),%esi
f0100999:	eb 79                	jmp    f0100a14 <monitor+0xce>
		if (*buf == 0)
f010099b:	80 3e 00             	cmpb   $0x0,(%esi)
f010099e:	74 7f                	je     f0100a1f <monitor+0xd9>
		if (argc == MAXARGS-1) {
f01009a0:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009a4:	74 0f                	je     f01009b5 <monitor+0x6f>
		argv[argc++] = buf;
f01009a6:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009a9:	8d 48 01             	lea    0x1(%eax),%ecx
f01009ac:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009af:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01009b3:	eb 44                	jmp    f01009f9 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009b5:	83 ec 08             	sub    $0x8,%esp
f01009b8:	6a 10                	push   $0x10
f01009ba:	8d 83 02 0b ff ff    	lea    -0xf4fe(%ebx),%eax
f01009c0:	50                   	push   %eax
f01009c1:	e8 3c 01 00 00       	call   f0100b02 <cprintf>
f01009c6:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009c9:	8d 83 f9 0a ff ff    	lea    -0xf507(%ebx),%eax
f01009cf:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009d2:	83 ec 0c             	sub    $0xc,%esp
f01009d5:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009d8:	e8 10 0a 00 00       	call   f01013ed <readline>
f01009dd:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009df:	83 c4 10             	add    $0x10,%esp
f01009e2:	85 c0                	test   %eax,%eax
f01009e4:	74 ec                	je     f01009d2 <monitor+0x8c>
	argv[argc] = 0;
f01009e6:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009ed:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009f4:	eb 1e                	jmp    f0100a14 <monitor+0xce>
			buf++;
f01009f6:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009f9:	0f b6 06             	movzbl (%esi),%eax
f01009fc:	84 c0                	test   %al,%al
f01009fe:	74 14                	je     f0100a14 <monitor+0xce>
f0100a00:	83 ec 08             	sub    $0x8,%esp
f0100a03:	0f be c0             	movsbl %al,%eax
f0100a06:	50                   	push   %eax
f0100a07:	57                   	push   %edi
f0100a08:	e8 18 0c 00 00       	call   f0101625 <strchr>
f0100a0d:	83 c4 10             	add    $0x10,%esp
f0100a10:	85 c0                	test   %eax,%eax
f0100a12:	74 e2                	je     f01009f6 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a14:	0f b6 06             	movzbl (%esi),%eax
f0100a17:	84 c0                	test   %al,%al
f0100a19:	0f 85 60 ff ff ff    	jne    f010097f <monitor+0x39>
	argv[argc] = 0;
f0100a1f:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a22:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a29:	00 
	if (argc == 0)
f0100a2a:	85 c0                	test   %eax,%eax
f0100a2c:	74 9b                	je     f01009c9 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a2e:	83 ec 08             	sub    $0x8,%esp
f0100a31:	8d 83 96 0a ff ff    	lea    -0xf56a(%ebx),%eax
f0100a37:	50                   	push   %eax
f0100a38:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a3b:	e8 87 0b 00 00       	call   f01015c7 <strcmp>
f0100a40:	83 c4 10             	add    $0x10,%esp
f0100a43:	85 c0                	test   %eax,%eax
f0100a45:	74 38                	je     f0100a7f <monitor+0x139>
f0100a47:	83 ec 08             	sub    $0x8,%esp
f0100a4a:	8d 83 a4 0a ff ff    	lea    -0xf55c(%ebx),%eax
f0100a50:	50                   	push   %eax
f0100a51:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a54:	e8 6e 0b 00 00       	call   f01015c7 <strcmp>
f0100a59:	83 c4 10             	add    $0x10,%esp
f0100a5c:	85 c0                	test   %eax,%eax
f0100a5e:	74 1a                	je     f0100a7a <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a60:	83 ec 08             	sub    $0x8,%esp
f0100a63:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a66:	8d 83 1f 0b ff ff    	lea    -0xf4e1(%ebx),%eax
f0100a6c:	50                   	push   %eax
f0100a6d:	e8 90 00 00 00       	call   f0100b02 <cprintf>
f0100a72:	83 c4 10             	add    $0x10,%esp
f0100a75:	e9 4f ff ff ff       	jmp    f01009c9 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a7a:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100a7f:	83 ec 04             	sub    $0x4,%esp
f0100a82:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a85:	ff 75 08             	pushl  0x8(%ebp)
f0100a88:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a8b:	52                   	push   %edx
f0100a8c:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a8f:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a96:	83 c4 10             	add    $0x10,%esp
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	0f 89 28 ff ff ff    	jns    f01009c9 <monitor+0x83>
				break;
	}
}
f0100aa1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100aa4:	5b                   	pop    %ebx
f0100aa5:	5e                   	pop    %esi
f0100aa6:	5f                   	pop    %edi
f0100aa7:	5d                   	pop    %ebp
f0100aa8:	c3                   	ret    

f0100aa9 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100aa9:	55                   	push   %ebp
f0100aaa:	89 e5                	mov    %esp,%ebp
f0100aac:	53                   	push   %ebx
f0100aad:	83 ec 10             	sub    $0x10,%esp
f0100ab0:	e8 37 f7 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100ab5:	81 c3 53 08 01 00    	add    $0x10853,%ebx
	cputchar(ch);
f0100abb:	ff 75 08             	pushl  0x8(%ebp)
f0100abe:	e8 a0 fc ff ff       	call   f0100763 <cputchar>
	*cnt++;
}
f0100ac3:	83 c4 10             	add    $0x10,%esp
f0100ac6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ac9:	c9                   	leave  
f0100aca:	c3                   	ret    

f0100acb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100acb:	55                   	push   %ebp
f0100acc:	89 e5                	mov    %esp,%ebp
f0100ace:	53                   	push   %ebx
f0100acf:	83 ec 14             	sub    $0x14,%esp
f0100ad2:	e8 15 f7 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100ad7:	81 c3 31 08 01 00    	add    $0x10831,%ebx
	int cnt = 0;
f0100add:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100ae4:	ff 75 0c             	pushl  0xc(%ebp)
f0100ae7:	ff 75 08             	pushl  0x8(%ebp)
f0100aea:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100aed:	50                   	push   %eax
f0100aee:	8d 83 a1 f7 fe ff    	lea    -0x1085f(%ebx),%eax
f0100af4:	50                   	push   %eax
f0100af5:	e8 1c 04 00 00       	call   f0100f16 <vprintfmt>
	return cnt;
}
f0100afa:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100afd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b00:	c9                   	leave  
f0100b01:	c3                   	ret    

f0100b02 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b02:	55                   	push   %ebp
f0100b03:	89 e5                	mov    %esp,%ebp
f0100b05:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b08:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b0b:	50                   	push   %eax
f0100b0c:	ff 75 08             	pushl  0x8(%ebp)
f0100b0f:	e8 b7 ff ff ff       	call   f0100acb <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b14:	c9                   	leave  
f0100b15:	c3                   	ret    

f0100b16 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b16:	55                   	push   %ebp
f0100b17:	89 e5                	mov    %esp,%ebp
f0100b19:	57                   	push   %edi
f0100b1a:	56                   	push   %esi
f0100b1b:	53                   	push   %ebx
f0100b1c:	83 ec 14             	sub    $0x14,%esp
f0100b1f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100b22:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100b25:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100b28:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b2b:	8b 32                	mov    (%edx),%esi
f0100b2d:	8b 01                	mov    (%ecx),%eax
f0100b2f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b32:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100b39:	eb 2f                	jmp    f0100b6a <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100b3b:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b3e:	39 c6                	cmp    %eax,%esi
f0100b40:	7f 49                	jg     f0100b8b <stab_binsearch+0x75>
f0100b42:	0f b6 0a             	movzbl (%edx),%ecx
f0100b45:	83 ea 0c             	sub    $0xc,%edx
f0100b48:	39 f9                	cmp    %edi,%ecx
f0100b4a:	75 ef                	jne    f0100b3b <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b4c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b4f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b52:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b56:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b59:	73 35                	jae    f0100b90 <stab_binsearch+0x7a>
			*region_left = m;
f0100b5b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b5e:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100b60:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100b63:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100b6a:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100b6d:	7f 4e                	jg     f0100bbd <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100b6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b72:	01 f0                	add    %esi,%eax
f0100b74:	89 c3                	mov    %eax,%ebx
f0100b76:	c1 eb 1f             	shr    $0x1f,%ebx
f0100b79:	01 c3                	add    %eax,%ebx
f0100b7b:	d1 fb                	sar    %ebx
f0100b7d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b80:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b83:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100b87:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b89:	eb b3                	jmp    f0100b3e <stab_binsearch+0x28>
			l = true_m + 1;
f0100b8b:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100b8e:	eb da                	jmp    f0100b6a <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100b90:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b93:	76 14                	jbe    f0100ba9 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100b95:	83 e8 01             	sub    $0x1,%eax
f0100b98:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b9b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100b9e:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100ba0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100ba7:	eb c1                	jmp    f0100b6a <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100ba9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bac:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100bae:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100bb2:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100bb4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100bbb:	eb ad                	jmp    f0100b6a <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100bbd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100bc1:	74 16                	je     f0100bd9 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100bc3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bc6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100bc8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bcb:	8b 0e                	mov    (%esi),%ecx
f0100bcd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bd0:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100bd3:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100bd7:	eb 12                	jmp    f0100beb <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100bd9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bdc:	8b 00                	mov    (%eax),%eax
f0100bde:	83 e8 01             	sub    $0x1,%eax
f0100be1:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100be4:	89 07                	mov    %eax,(%edi)
f0100be6:	eb 16                	jmp    f0100bfe <stab_binsearch+0xe8>
		     l--)
f0100be8:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100beb:	39 c1                	cmp    %eax,%ecx
f0100bed:	7d 0a                	jge    f0100bf9 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100bef:	0f b6 1a             	movzbl (%edx),%ebx
f0100bf2:	83 ea 0c             	sub    $0xc,%edx
f0100bf5:	39 fb                	cmp    %edi,%ebx
f0100bf7:	75 ef                	jne    f0100be8 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100bf9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bfc:	89 07                	mov    %eax,(%edi)
	}
}
f0100bfe:	83 c4 14             	add    $0x14,%esp
f0100c01:	5b                   	pop    %ebx
f0100c02:	5e                   	pop    %esi
f0100c03:	5f                   	pop    %edi
f0100c04:	5d                   	pop    %ebp
f0100c05:	c3                   	ret    

f0100c06 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c06:	55                   	push   %ebp
f0100c07:	89 e5                	mov    %esp,%ebp
f0100c09:	57                   	push   %edi
f0100c0a:	56                   	push   %esi
f0100c0b:	53                   	push   %ebx
f0100c0c:	83 ec 2c             	sub    $0x2c,%esp
f0100c0f:	e8 fa 01 00 00       	call   f0100e0e <__x86.get_pc_thunk.cx>
f0100c14:	81 c1 f4 06 01 00    	add    $0x106f4,%ecx
f0100c1a:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100c1d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100c20:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c23:	8d 81 90 0c ff ff    	lea    -0xf370(%ecx),%eax
f0100c29:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100c2b:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100c32:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100c35:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100c3c:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100c3f:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c46:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100c4c:	0f 86 f4 00 00 00    	jbe    f0100d46 <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c52:	c7 c0 69 5e 10 f0    	mov    $0xf0105e69,%eax
f0100c58:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100c5e:	0f 86 88 01 00 00    	jbe    f0100dec <debuginfo_eip+0x1e6>
f0100c64:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100c67:	c7 c0 d0 77 10 f0    	mov    $0xf01077d0,%eax
f0100c6d:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100c71:	0f 85 7c 01 00 00    	jne    f0100df3 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c77:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c7e:	c7 c0 b4 21 10 f0    	mov    $0xf01021b4,%eax
f0100c84:	c7 c2 68 5e 10 f0    	mov    $0xf0105e68,%edx
f0100c8a:	29 c2                	sub    %eax,%edx
f0100c8c:	c1 fa 02             	sar    $0x2,%edx
f0100c8f:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100c95:	83 ea 01             	sub    $0x1,%edx
f0100c98:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c9b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c9e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ca1:	83 ec 08             	sub    $0x8,%esp
f0100ca4:	53                   	push   %ebx
f0100ca5:	6a 64                	push   $0x64
f0100ca7:	e8 6a fe ff ff       	call   f0100b16 <stab_binsearch>
	if (lfile == 0)
f0100cac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100caf:	83 c4 10             	add    $0x10,%esp
f0100cb2:	85 c0                	test   %eax,%eax
f0100cb4:	0f 84 40 01 00 00    	je     f0100dfa <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100cba:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100cbd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cc0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100cc3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100cc6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cc9:	83 ec 08             	sub    $0x8,%esp
f0100ccc:	53                   	push   %ebx
f0100ccd:	6a 24                	push   $0x24
f0100ccf:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100cd2:	c7 c0 b4 21 10 f0    	mov    $0xf01021b4,%eax
f0100cd8:	e8 39 fe ff ff       	call   f0100b16 <stab_binsearch>

	if (lfun <= rfun) {
f0100cdd:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100ce0:	83 c4 10             	add    $0x10,%esp
f0100ce3:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100ce6:	7f 79                	jg     f0100d61 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ce8:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100ceb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cee:	c7 c2 b4 21 10 f0    	mov    $0xf01021b4,%edx
f0100cf4:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100cf7:	8b 11                	mov    (%ecx),%edx
f0100cf9:	c7 c0 d0 77 10 f0    	mov    $0xf01077d0,%eax
f0100cff:	81 e8 69 5e 10 f0    	sub    $0xf0105e69,%eax
f0100d05:	39 c2                	cmp    %eax,%edx
f0100d07:	73 09                	jae    f0100d12 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d09:	81 c2 69 5e 10 f0    	add    $0xf0105e69,%edx
f0100d0f:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d12:	8b 41 08             	mov    0x8(%ecx),%eax
f0100d15:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d18:	83 ec 08             	sub    $0x8,%esp
f0100d1b:	6a 3a                	push   $0x3a
f0100d1d:	ff 77 08             	pushl  0x8(%edi)
f0100d20:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d23:	e8 1e 09 00 00       	call   f0101646 <strfind>
f0100d28:	2b 47 08             	sub    0x8(%edi),%eax
f0100d2b:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d2e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d31:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100d34:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100d37:	c7 c2 b4 21 10 f0    	mov    $0xf01021b4,%edx
f0100d3d:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100d41:	83 c4 10             	add    $0x10,%esp
f0100d44:	eb 29                	jmp    f0100d6f <debuginfo_eip+0x169>
  	        panic("User address");
f0100d46:	83 ec 04             	sub    $0x4,%esp
f0100d49:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d4c:	8d 83 9a 0c ff ff    	lea    -0xf366(%ebx),%eax
f0100d52:	50                   	push   %eax
f0100d53:	6a 7f                	push   $0x7f
f0100d55:	8d 83 a7 0c ff ff    	lea    -0xf359(%ebx),%eax
f0100d5b:	50                   	push   %eax
f0100d5c:	e8 d5 f3 ff ff       	call   f0100136 <_panic>
		info->eip_fn_addr = addr;
f0100d61:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100d64:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100d67:	eb af                	jmp    f0100d18 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100d69:	83 ee 01             	sub    $0x1,%esi
f0100d6c:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100d6f:	39 f3                	cmp    %esi,%ebx
f0100d71:	7f 3a                	jg     f0100dad <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100d73:	0f b6 10             	movzbl (%eax),%edx
f0100d76:	80 fa 84             	cmp    $0x84,%dl
f0100d79:	74 0b                	je     f0100d86 <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d7b:	80 fa 64             	cmp    $0x64,%dl
f0100d7e:	75 e9                	jne    f0100d69 <debuginfo_eip+0x163>
f0100d80:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100d84:	74 e3                	je     f0100d69 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d86:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100d89:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d8c:	c7 c0 b4 21 10 f0    	mov    $0xf01021b4,%eax
f0100d92:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100d95:	c7 c0 d0 77 10 f0    	mov    $0xf01077d0,%eax
f0100d9b:	81 e8 69 5e 10 f0    	sub    $0xf0105e69,%eax
f0100da1:	39 c2                	cmp    %eax,%edx
f0100da3:	73 08                	jae    f0100dad <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100da5:	81 c2 69 5e 10 f0    	add    $0xf0105e69,%edx
f0100dab:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100dad:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100db0:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100db3:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100db8:	39 cb                	cmp    %ecx,%ebx
f0100dba:	7d 4a                	jge    f0100e06 <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100dbc:	8d 53 01             	lea    0x1(%ebx),%edx
f0100dbf:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100dc2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dc5:	c7 c0 b4 21 10 f0    	mov    $0xf01021b4,%eax
f0100dcb:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100dcf:	eb 07                	jmp    f0100dd8 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100dd1:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100dd5:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100dd8:	39 d1                	cmp    %edx,%ecx
f0100dda:	74 25                	je     f0100e01 <debuginfo_eip+0x1fb>
f0100ddc:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100ddf:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100de3:	74 ec                	je     f0100dd1 <debuginfo_eip+0x1cb>
	return 0;
f0100de5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dea:	eb 1a                	jmp    f0100e06 <debuginfo_eip+0x200>
		return -1;
f0100dec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100df1:	eb 13                	jmp    f0100e06 <debuginfo_eip+0x200>
f0100df3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100df8:	eb 0c                	jmp    f0100e06 <debuginfo_eip+0x200>
		return -1;
f0100dfa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dff:	eb 05                	jmp    f0100e06 <debuginfo_eip+0x200>
	return 0;
f0100e01:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e06:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e09:	5b                   	pop    %ebx
f0100e0a:	5e                   	pop    %esi
f0100e0b:	5f                   	pop    %edi
f0100e0c:	5d                   	pop    %ebp
f0100e0d:	c3                   	ret    

f0100e0e <__x86.get_pc_thunk.cx>:
f0100e0e:	8b 0c 24             	mov    (%esp),%ecx
f0100e11:	c3                   	ret    

f0100e12 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e12:	55                   	push   %ebp
f0100e13:	89 e5                	mov    %esp,%ebp
f0100e15:	57                   	push   %edi
f0100e16:	56                   	push   %esi
f0100e17:	53                   	push   %ebx
f0100e18:	83 ec 2c             	sub    $0x2c,%esp
f0100e1b:	e8 ee ff ff ff       	call   f0100e0e <__x86.get_pc_thunk.cx>
f0100e20:	81 c1 e8 04 01 00    	add    $0x104e8,%ecx
f0100e26:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100e29:	89 c7                	mov    %eax,%edi
f0100e2b:	89 d6                	mov    %edx,%esi
f0100e2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e30:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100e33:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e36:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e39:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100e3c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e41:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100e44:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100e47:	39 d3                	cmp    %edx,%ebx
f0100e49:	72 09                	jb     f0100e54 <printnum+0x42>
f0100e4b:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100e4e:	0f 87 83 00 00 00    	ja     f0100ed7 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e54:	83 ec 0c             	sub    $0xc,%esp
f0100e57:	ff 75 18             	pushl  0x18(%ebp)
f0100e5a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e5d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100e60:	53                   	push   %ebx
f0100e61:	ff 75 10             	pushl  0x10(%ebp)
f0100e64:	83 ec 08             	sub    $0x8,%esp
f0100e67:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e6a:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e6d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e70:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e73:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100e76:	e8 e5 09 00 00       	call   f0101860 <__udivdi3>
f0100e7b:	83 c4 18             	add    $0x18,%esp
f0100e7e:	52                   	push   %edx
f0100e7f:	50                   	push   %eax
f0100e80:	89 f2                	mov    %esi,%edx
f0100e82:	89 f8                	mov    %edi,%eax
f0100e84:	e8 89 ff ff ff       	call   f0100e12 <printnum>
f0100e89:	83 c4 20             	add    $0x20,%esp
f0100e8c:	eb 13                	jmp    f0100ea1 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e8e:	83 ec 08             	sub    $0x8,%esp
f0100e91:	56                   	push   %esi
f0100e92:	ff 75 18             	pushl  0x18(%ebp)
f0100e95:	ff d7                	call   *%edi
f0100e97:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100e9a:	83 eb 01             	sub    $0x1,%ebx
f0100e9d:	85 db                	test   %ebx,%ebx
f0100e9f:	7f ed                	jg     f0100e8e <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ea1:	83 ec 08             	sub    $0x8,%esp
f0100ea4:	56                   	push   %esi
f0100ea5:	83 ec 04             	sub    $0x4,%esp
f0100ea8:	ff 75 dc             	pushl  -0x24(%ebp)
f0100eab:	ff 75 d8             	pushl  -0x28(%ebp)
f0100eae:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100eb1:	ff 75 d0             	pushl  -0x30(%ebp)
f0100eb4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100eb7:	89 f3                	mov    %esi,%ebx
f0100eb9:	e8 c2 0a 00 00       	call   f0101980 <__umoddi3>
f0100ebe:	83 c4 14             	add    $0x14,%esp
f0100ec1:	0f be 84 06 b5 0c ff 	movsbl -0xf34b(%esi,%eax,1),%eax
f0100ec8:	ff 
f0100ec9:	50                   	push   %eax
f0100eca:	ff d7                	call   *%edi
}
f0100ecc:	83 c4 10             	add    $0x10,%esp
f0100ecf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ed2:	5b                   	pop    %ebx
f0100ed3:	5e                   	pop    %esi
f0100ed4:	5f                   	pop    %edi
f0100ed5:	5d                   	pop    %ebp
f0100ed6:	c3                   	ret    
f0100ed7:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100eda:	eb be                	jmp    f0100e9a <printnum+0x88>

f0100edc <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100edc:	55                   	push   %ebp
f0100edd:	89 e5                	mov    %esp,%ebp
f0100edf:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ee2:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ee6:	8b 10                	mov    (%eax),%edx
f0100ee8:	3b 50 04             	cmp    0x4(%eax),%edx
f0100eeb:	73 0a                	jae    f0100ef7 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100eed:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100ef0:	89 08                	mov    %ecx,(%eax)
f0100ef2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ef5:	88 02                	mov    %al,(%edx)
}
f0100ef7:	5d                   	pop    %ebp
f0100ef8:	c3                   	ret    

f0100ef9 <printfmt>:
{
f0100ef9:	55                   	push   %ebp
f0100efa:	89 e5                	mov    %esp,%ebp
f0100efc:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100eff:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f02:	50                   	push   %eax
f0100f03:	ff 75 10             	pushl  0x10(%ebp)
f0100f06:	ff 75 0c             	pushl  0xc(%ebp)
f0100f09:	ff 75 08             	pushl  0x8(%ebp)
f0100f0c:	e8 05 00 00 00       	call   f0100f16 <vprintfmt>
}
f0100f11:	83 c4 10             	add    $0x10,%esp
f0100f14:	c9                   	leave  
f0100f15:	c3                   	ret    

f0100f16 <vprintfmt>:
{
f0100f16:	55                   	push   %ebp
f0100f17:	89 e5                	mov    %esp,%ebp
f0100f19:	57                   	push   %edi
f0100f1a:	56                   	push   %esi
f0100f1b:	53                   	push   %ebx
f0100f1c:	83 ec 2c             	sub    $0x2c,%esp
f0100f1f:	e8 c8 f2 ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0100f24:	81 c3 e4 03 01 00    	add    $0x103e4,%ebx
f0100f2a:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100f2d:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100f30:	e9 8e 03 00 00       	jmp    f01012c3 <.L35+0x48>
		padc = ' ';
f0100f35:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100f39:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100f40:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0100f47:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100f4e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f53:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f56:	8d 47 01             	lea    0x1(%edi),%eax
f0100f59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f5c:	0f b6 17             	movzbl (%edi),%edx
f0100f5f:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100f62:	3c 55                	cmp    $0x55,%al
f0100f64:	0f 87 e1 03 00 00    	ja     f010134b <.L22>
f0100f6a:	0f b6 c0             	movzbl %al,%eax
f0100f6d:	89 d9                	mov    %ebx,%ecx
f0100f6f:	03 8c 83 44 0d ff ff 	add    -0xf2bc(%ebx,%eax,4),%ecx
f0100f76:	ff e1                	jmp    *%ecx

f0100f78 <.L67>:
f0100f78:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100f7b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100f7f:	eb d5                	jmp    f0100f56 <vprintfmt+0x40>

f0100f81 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0100f81:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100f84:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f88:	eb cc                	jmp    f0100f56 <vprintfmt+0x40>

f0100f8a <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8a:	0f b6 d2             	movzbl %dl,%edx
f0100f8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100f90:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0100f95:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f98:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f9c:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f9f:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100fa2:	83 f9 09             	cmp    $0x9,%ecx
f0100fa5:	77 55                	ja     f0100ffc <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0100fa7:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100faa:	eb e9                	jmp    f0100f95 <.L29+0xb>

f0100fac <.L26>:
			precision = va_arg(ap, int);
f0100fac:	8b 45 14             	mov    0x14(%ebp),%eax
f0100faf:	8b 00                	mov    (%eax),%eax
f0100fb1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100fb4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb7:	8d 40 04             	lea    0x4(%eax),%eax
f0100fba:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100fbd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100fc0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fc4:	79 90                	jns    f0100f56 <vprintfmt+0x40>
				width = precision, precision = -1;
f0100fc6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100fc9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fcc:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100fd3:	eb 81                	jmp    f0100f56 <vprintfmt+0x40>

f0100fd5 <.L27>:
f0100fd5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fd8:	85 c0                	test   %eax,%eax
f0100fda:	ba 00 00 00 00       	mov    $0x0,%edx
f0100fdf:	0f 49 d0             	cmovns %eax,%edx
f0100fe2:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100fe5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fe8:	e9 69 ff ff ff       	jmp    f0100f56 <vprintfmt+0x40>

f0100fed <.L23>:
f0100fed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0100ff0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100ff7:	e9 5a ff ff ff       	jmp    f0100f56 <vprintfmt+0x40>
f0100ffc:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100fff:	eb bf                	jmp    f0100fc0 <.L26+0x14>

f0101001 <.L33>:
			lflag++;
f0101001:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101005:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101008:	e9 49 ff ff ff       	jmp    f0100f56 <vprintfmt+0x40>

f010100d <.L30>:
			putch(va_arg(ap, int), putdat);
f010100d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101010:	8d 78 04             	lea    0x4(%eax),%edi
f0101013:	83 ec 08             	sub    $0x8,%esp
f0101016:	56                   	push   %esi
f0101017:	ff 30                	pushl  (%eax)
f0101019:	ff 55 08             	call   *0x8(%ebp)
			break;
f010101c:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010101f:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0101022:	e9 99 02 00 00       	jmp    f01012c0 <.L35+0x45>

f0101027 <.L32>:
			err = va_arg(ap, int);
f0101027:	8b 45 14             	mov    0x14(%ebp),%eax
f010102a:	8d 78 04             	lea    0x4(%eax),%edi
f010102d:	8b 00                	mov    (%eax),%eax
f010102f:	99                   	cltd   
f0101030:	31 d0                	xor    %edx,%eax
f0101032:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101034:	83 f8 06             	cmp    $0x6,%eax
f0101037:	7f 27                	jg     f0101060 <.L32+0x39>
f0101039:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0101040:	85 d2                	test   %edx,%edx
f0101042:	74 1c                	je     f0101060 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0101044:	52                   	push   %edx
f0101045:	8d 83 d6 0c ff ff    	lea    -0xf32a(%ebx),%eax
f010104b:	50                   	push   %eax
f010104c:	56                   	push   %esi
f010104d:	ff 75 08             	pushl  0x8(%ebp)
f0101050:	e8 a4 fe ff ff       	call   f0100ef9 <printfmt>
f0101055:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101058:	89 7d 14             	mov    %edi,0x14(%ebp)
f010105b:	e9 60 02 00 00       	jmp    f01012c0 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0101060:	50                   	push   %eax
f0101061:	8d 83 cd 0c ff ff    	lea    -0xf333(%ebx),%eax
f0101067:	50                   	push   %eax
f0101068:	56                   	push   %esi
f0101069:	ff 75 08             	pushl  0x8(%ebp)
f010106c:	e8 88 fe ff ff       	call   f0100ef9 <printfmt>
f0101071:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101074:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0101077:	e9 44 02 00 00       	jmp    f01012c0 <.L35+0x45>

f010107c <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f010107c:	8b 45 14             	mov    0x14(%ebp),%eax
f010107f:	83 c0 04             	add    $0x4,%eax
f0101082:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101085:	8b 45 14             	mov    0x14(%ebp),%eax
f0101088:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010108a:	85 ff                	test   %edi,%edi
f010108c:	8d 83 c6 0c ff ff    	lea    -0xf33a(%ebx),%eax
f0101092:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101095:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101099:	0f 8e b5 00 00 00    	jle    f0101154 <.L36+0xd8>
f010109f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01010a3:	75 08                	jne    f01010ad <.L36+0x31>
f01010a5:	89 75 0c             	mov    %esi,0xc(%ebp)
f01010a8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010ab:	eb 6d                	jmp    f010111a <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f01010ad:	83 ec 08             	sub    $0x8,%esp
f01010b0:	ff 75 d0             	pushl  -0x30(%ebp)
f01010b3:	57                   	push   %edi
f01010b4:	e8 49 04 00 00       	call   f0101502 <strnlen>
f01010b9:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01010bc:	29 c2                	sub    %eax,%edx
f01010be:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01010c1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01010c4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01010c8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010cb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01010ce:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01010d0:	eb 10                	jmp    f01010e2 <.L36+0x66>
					putch(padc, putdat);
f01010d2:	83 ec 08             	sub    $0x8,%esp
f01010d5:	56                   	push   %esi
f01010d6:	ff 75 e0             	pushl  -0x20(%ebp)
f01010d9:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01010dc:	83 ef 01             	sub    $0x1,%edi
f01010df:	83 c4 10             	add    $0x10,%esp
f01010e2:	85 ff                	test   %edi,%edi
f01010e4:	7f ec                	jg     f01010d2 <.L36+0x56>
f01010e6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01010e9:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01010ec:	85 d2                	test   %edx,%edx
f01010ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f3:	0f 49 c2             	cmovns %edx,%eax
f01010f6:	29 c2                	sub    %eax,%edx
f01010f8:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01010fb:	89 75 0c             	mov    %esi,0xc(%ebp)
f01010fe:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101101:	eb 17                	jmp    f010111a <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101103:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101107:	75 30                	jne    f0101139 <.L36+0xbd>
					putch(ch, putdat);
f0101109:	83 ec 08             	sub    $0x8,%esp
f010110c:	ff 75 0c             	pushl  0xc(%ebp)
f010110f:	50                   	push   %eax
f0101110:	ff 55 08             	call   *0x8(%ebp)
f0101113:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101116:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010111a:	83 c7 01             	add    $0x1,%edi
f010111d:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101121:	0f be c2             	movsbl %dl,%eax
f0101124:	85 c0                	test   %eax,%eax
f0101126:	74 52                	je     f010117a <.L36+0xfe>
f0101128:	85 f6                	test   %esi,%esi
f010112a:	78 d7                	js     f0101103 <.L36+0x87>
f010112c:	83 ee 01             	sub    $0x1,%esi
f010112f:	79 d2                	jns    f0101103 <.L36+0x87>
f0101131:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101134:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101137:	eb 32                	jmp    f010116b <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0101139:	0f be d2             	movsbl %dl,%edx
f010113c:	83 ea 20             	sub    $0x20,%edx
f010113f:	83 fa 5e             	cmp    $0x5e,%edx
f0101142:	76 c5                	jbe    f0101109 <.L36+0x8d>
					putch('?', putdat);
f0101144:	83 ec 08             	sub    $0x8,%esp
f0101147:	ff 75 0c             	pushl  0xc(%ebp)
f010114a:	6a 3f                	push   $0x3f
f010114c:	ff 55 08             	call   *0x8(%ebp)
f010114f:	83 c4 10             	add    $0x10,%esp
f0101152:	eb c2                	jmp    f0101116 <.L36+0x9a>
f0101154:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101157:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010115a:	eb be                	jmp    f010111a <.L36+0x9e>
				putch(' ', putdat);
f010115c:	83 ec 08             	sub    $0x8,%esp
f010115f:	56                   	push   %esi
f0101160:	6a 20                	push   $0x20
f0101162:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0101165:	83 ef 01             	sub    $0x1,%edi
f0101168:	83 c4 10             	add    $0x10,%esp
f010116b:	85 ff                	test   %edi,%edi
f010116d:	7f ed                	jg     f010115c <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f010116f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101172:	89 45 14             	mov    %eax,0x14(%ebp)
f0101175:	e9 46 01 00 00       	jmp    f01012c0 <.L35+0x45>
f010117a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010117d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101180:	eb e9                	jmp    f010116b <.L36+0xef>

f0101182 <.L31>:
f0101182:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101185:	83 f9 01             	cmp    $0x1,%ecx
f0101188:	7e 40                	jle    f01011ca <.L31+0x48>
		return va_arg(*ap, long long);
f010118a:	8b 45 14             	mov    0x14(%ebp),%eax
f010118d:	8b 50 04             	mov    0x4(%eax),%edx
f0101190:	8b 00                	mov    (%eax),%eax
f0101192:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101195:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101198:	8b 45 14             	mov    0x14(%ebp),%eax
f010119b:	8d 40 08             	lea    0x8(%eax),%eax
f010119e:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01011a1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011a5:	79 55                	jns    f01011fc <.L31+0x7a>
				putch('-', putdat);
f01011a7:	83 ec 08             	sub    $0x8,%esp
f01011aa:	56                   	push   %esi
f01011ab:	6a 2d                	push   $0x2d
f01011ad:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011b0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011b3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01011b6:	f7 da                	neg    %edx
f01011b8:	83 d1 00             	adc    $0x0,%ecx
f01011bb:	f7 d9                	neg    %ecx
f01011bd:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01011c0:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011c5:	e9 db 00 00 00       	jmp    f01012a5 <.L35+0x2a>
	else if (lflag)
f01011ca:	85 c9                	test   %ecx,%ecx
f01011cc:	75 17                	jne    f01011e5 <.L31+0x63>
		return va_arg(*ap, int);
f01011ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d1:	8b 00                	mov    (%eax),%eax
f01011d3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011d6:	99                   	cltd   
f01011d7:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011da:	8b 45 14             	mov    0x14(%ebp),%eax
f01011dd:	8d 40 04             	lea    0x4(%eax),%eax
f01011e0:	89 45 14             	mov    %eax,0x14(%ebp)
f01011e3:	eb bc                	jmp    f01011a1 <.L31+0x1f>
		return va_arg(*ap, long);
f01011e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e8:	8b 00                	mov    (%eax),%eax
f01011ea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011ed:	99                   	cltd   
f01011ee:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f4:	8d 40 04             	lea    0x4(%eax),%eax
f01011f7:	89 45 14             	mov    %eax,0x14(%ebp)
f01011fa:	eb a5                	jmp    f01011a1 <.L31+0x1f>
			num = getint(&ap, lflag);
f01011fc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011ff:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101202:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101207:	e9 99 00 00 00       	jmp    f01012a5 <.L35+0x2a>

f010120c <.L37>:
f010120c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f010120f:	83 f9 01             	cmp    $0x1,%ecx
f0101212:	7e 15                	jle    f0101229 <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0101214:	8b 45 14             	mov    0x14(%ebp),%eax
f0101217:	8b 10                	mov    (%eax),%edx
f0101219:	8b 48 04             	mov    0x4(%eax),%ecx
f010121c:	8d 40 08             	lea    0x8(%eax),%eax
f010121f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101222:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101227:	eb 7c                	jmp    f01012a5 <.L35+0x2a>
	else if (lflag)
f0101229:	85 c9                	test   %ecx,%ecx
f010122b:	75 17                	jne    f0101244 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f010122d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101230:	8b 10                	mov    (%eax),%edx
f0101232:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101237:	8d 40 04             	lea    0x4(%eax),%eax
f010123a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010123d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101242:	eb 61                	jmp    f01012a5 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101244:	8b 45 14             	mov    0x14(%ebp),%eax
f0101247:	8b 10                	mov    (%eax),%edx
f0101249:	b9 00 00 00 00       	mov    $0x0,%ecx
f010124e:	8d 40 04             	lea    0x4(%eax),%eax
f0101251:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101254:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101259:	eb 4a                	jmp    f01012a5 <.L35+0x2a>

f010125b <.L34>:
			putch('X', putdat);
f010125b:	83 ec 08             	sub    $0x8,%esp
f010125e:	56                   	push   %esi
f010125f:	6a 58                	push   $0x58
f0101261:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0101264:	83 c4 08             	add    $0x8,%esp
f0101267:	56                   	push   %esi
f0101268:	6a 58                	push   $0x58
f010126a:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f010126d:	83 c4 08             	add    $0x8,%esp
f0101270:	56                   	push   %esi
f0101271:	6a 58                	push   $0x58
f0101273:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101276:	83 c4 10             	add    $0x10,%esp
f0101279:	eb 45                	jmp    f01012c0 <.L35+0x45>

f010127b <.L35>:
			putch('0', putdat);
f010127b:	83 ec 08             	sub    $0x8,%esp
f010127e:	56                   	push   %esi
f010127f:	6a 30                	push   $0x30
f0101281:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101284:	83 c4 08             	add    $0x8,%esp
f0101287:	56                   	push   %esi
f0101288:	6a 78                	push   $0x78
f010128a:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010128d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101290:	8b 10                	mov    (%eax),%edx
f0101292:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101297:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010129a:	8d 40 04             	lea    0x4(%eax),%eax
f010129d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012a0:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01012a5:	83 ec 0c             	sub    $0xc,%esp
f01012a8:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01012ac:	57                   	push   %edi
f01012ad:	ff 75 e0             	pushl  -0x20(%ebp)
f01012b0:	50                   	push   %eax
f01012b1:	51                   	push   %ecx
f01012b2:	52                   	push   %edx
f01012b3:	89 f2                	mov    %esi,%edx
f01012b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01012b8:	e8 55 fb ff ff       	call   f0100e12 <printnum>
			break;
f01012bd:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01012c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01012c3:	83 c7 01             	add    $0x1,%edi
f01012c6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01012ca:	83 f8 25             	cmp    $0x25,%eax
f01012cd:	0f 84 62 fc ff ff    	je     f0100f35 <vprintfmt+0x1f>
			if (ch == '\0')
f01012d3:	85 c0                	test   %eax,%eax
f01012d5:	0f 84 91 00 00 00    	je     f010136c <.L22+0x21>
			putch(ch, putdat);
f01012db:	83 ec 08             	sub    $0x8,%esp
f01012de:	56                   	push   %esi
f01012df:	50                   	push   %eax
f01012e0:	ff 55 08             	call   *0x8(%ebp)
f01012e3:	83 c4 10             	add    $0x10,%esp
f01012e6:	eb db                	jmp    f01012c3 <.L35+0x48>

f01012e8 <.L38>:
f01012e8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01012eb:	83 f9 01             	cmp    $0x1,%ecx
f01012ee:	7e 15                	jle    f0101305 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01012f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01012f3:	8b 10                	mov    (%eax),%edx
f01012f5:	8b 48 04             	mov    0x4(%eax),%ecx
f01012f8:	8d 40 08             	lea    0x8(%eax),%eax
f01012fb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012fe:	b8 10 00 00 00       	mov    $0x10,%eax
f0101303:	eb a0                	jmp    f01012a5 <.L35+0x2a>
	else if (lflag)
f0101305:	85 c9                	test   %ecx,%ecx
f0101307:	75 17                	jne    f0101320 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0101309:	8b 45 14             	mov    0x14(%ebp),%eax
f010130c:	8b 10                	mov    (%eax),%edx
f010130e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101313:	8d 40 04             	lea    0x4(%eax),%eax
f0101316:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101319:	b8 10 00 00 00       	mov    $0x10,%eax
f010131e:	eb 85                	jmp    f01012a5 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101320:	8b 45 14             	mov    0x14(%ebp),%eax
f0101323:	8b 10                	mov    (%eax),%edx
f0101325:	b9 00 00 00 00       	mov    $0x0,%ecx
f010132a:	8d 40 04             	lea    0x4(%eax),%eax
f010132d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101330:	b8 10 00 00 00       	mov    $0x10,%eax
f0101335:	e9 6b ff ff ff       	jmp    f01012a5 <.L35+0x2a>

f010133a <.L25>:
			putch(ch, putdat);
f010133a:	83 ec 08             	sub    $0x8,%esp
f010133d:	56                   	push   %esi
f010133e:	6a 25                	push   $0x25
f0101340:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101343:	83 c4 10             	add    $0x10,%esp
f0101346:	e9 75 ff ff ff       	jmp    f01012c0 <.L35+0x45>

f010134b <.L22>:
			putch('%', putdat);
f010134b:	83 ec 08             	sub    $0x8,%esp
f010134e:	56                   	push   %esi
f010134f:	6a 25                	push   $0x25
f0101351:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101354:	83 c4 10             	add    $0x10,%esp
f0101357:	89 f8                	mov    %edi,%eax
f0101359:	eb 03                	jmp    f010135e <.L22+0x13>
f010135b:	83 e8 01             	sub    $0x1,%eax
f010135e:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101362:	75 f7                	jne    f010135b <.L22+0x10>
f0101364:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101367:	e9 54 ff ff ff       	jmp    f01012c0 <.L35+0x45>
}
f010136c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010136f:	5b                   	pop    %ebx
f0101370:	5e                   	pop    %esi
f0101371:	5f                   	pop    %edi
f0101372:	5d                   	pop    %ebp
f0101373:	c3                   	ret    

f0101374 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101374:	55                   	push   %ebp
f0101375:	89 e5                	mov    %esp,%ebp
f0101377:	53                   	push   %ebx
f0101378:	83 ec 14             	sub    $0x14,%esp
f010137b:	e8 6c ee ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f0101380:	81 c3 88 ff 00 00    	add    $0xff88,%ebx
f0101386:	8b 45 08             	mov    0x8(%ebp),%eax
f0101389:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010138c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010138f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101393:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101396:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010139d:	85 c0                	test   %eax,%eax
f010139f:	74 2b                	je     f01013cc <vsnprintf+0x58>
f01013a1:	85 d2                	test   %edx,%edx
f01013a3:	7e 27                	jle    f01013cc <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01013a5:	ff 75 14             	pushl  0x14(%ebp)
f01013a8:	ff 75 10             	pushl  0x10(%ebp)
f01013ab:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01013ae:	50                   	push   %eax
f01013af:	8d 83 d4 fb fe ff    	lea    -0x1042c(%ebx),%eax
f01013b5:	50                   	push   %eax
f01013b6:	e8 5b fb ff ff       	call   f0100f16 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01013bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01013be:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01013c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013c4:	83 c4 10             	add    $0x10,%esp
}
f01013c7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013ca:	c9                   	leave  
f01013cb:	c3                   	ret    
		return -E_INVAL;
f01013cc:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01013d1:	eb f4                	jmp    f01013c7 <vsnprintf+0x53>

f01013d3 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013d3:	55                   	push   %ebp
f01013d4:	89 e5                	mov    %esp,%ebp
f01013d6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013d9:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013dc:	50                   	push   %eax
f01013dd:	ff 75 10             	pushl  0x10(%ebp)
f01013e0:	ff 75 0c             	pushl  0xc(%ebp)
f01013e3:	ff 75 08             	pushl  0x8(%ebp)
f01013e6:	e8 89 ff ff ff       	call   f0101374 <vsnprintf>
	va_end(ap);

	return rc;
}
f01013eb:	c9                   	leave  
f01013ec:	c3                   	ret    

f01013ed <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013ed:	55                   	push   %ebp
f01013ee:	89 e5                	mov    %esp,%ebp
f01013f0:	57                   	push   %edi
f01013f1:	56                   	push   %esi
f01013f2:	53                   	push   %ebx
f01013f3:	83 ec 1c             	sub    $0x1c,%esp
f01013f6:	e8 f1 ed ff ff       	call   f01001ec <__x86.get_pc_thunk.bx>
f01013fb:	81 c3 0d ff 00 00    	add    $0xff0d,%ebx
f0101401:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101404:	85 c0                	test   %eax,%eax
f0101406:	74 13                	je     f010141b <readline+0x2e>
		cprintf("%s", prompt);
f0101408:	83 ec 08             	sub    $0x8,%esp
f010140b:	50                   	push   %eax
f010140c:	8d 83 d6 0c ff ff    	lea    -0xf32a(%ebx),%eax
f0101412:	50                   	push   %eax
f0101413:	e8 ea f6 ff ff       	call   f0100b02 <cprintf>
f0101418:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010141b:	83 ec 0c             	sub    $0xc,%esp
f010141e:	6a 00                	push   $0x0
f0101420:	e8 5f f3 ff ff       	call   f0100784 <iscons>
f0101425:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101428:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010142b:	bf 00 00 00 00       	mov    $0x0,%edi
f0101430:	eb 46                	jmp    f0101478 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101432:	83 ec 08             	sub    $0x8,%esp
f0101435:	50                   	push   %eax
f0101436:	8d 83 9c 0e ff ff    	lea    -0xf164(%ebx),%eax
f010143c:	50                   	push   %eax
f010143d:	e8 c0 f6 ff ff       	call   f0100b02 <cprintf>
			return NULL;
f0101442:	83 c4 10             	add    $0x10,%esp
f0101445:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010144a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010144d:	5b                   	pop    %ebx
f010144e:	5e                   	pop    %esi
f010144f:	5f                   	pop    %edi
f0101450:	5d                   	pop    %ebp
f0101451:	c3                   	ret    
			if (echoing)
f0101452:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101456:	75 05                	jne    f010145d <readline+0x70>
			i--;
f0101458:	83 ef 01             	sub    $0x1,%edi
f010145b:	eb 1b                	jmp    f0101478 <readline+0x8b>
				cputchar('\b');
f010145d:	83 ec 0c             	sub    $0xc,%esp
f0101460:	6a 08                	push   $0x8
f0101462:	e8 fc f2 ff ff       	call   f0100763 <cputchar>
f0101467:	83 c4 10             	add    $0x10,%esp
f010146a:	eb ec                	jmp    f0101458 <readline+0x6b>
			buf[i++] = c;
f010146c:	89 f0                	mov    %esi,%eax
f010146e:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f0101475:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101478:	e8 f6 f2 ff ff       	call   f0100773 <getchar>
f010147d:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010147f:	85 c0                	test   %eax,%eax
f0101481:	78 af                	js     f0101432 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101483:	83 f8 08             	cmp    $0x8,%eax
f0101486:	0f 94 c2             	sete   %dl
f0101489:	83 f8 7f             	cmp    $0x7f,%eax
f010148c:	0f 94 c0             	sete   %al
f010148f:	08 c2                	or     %al,%dl
f0101491:	74 04                	je     f0101497 <readline+0xaa>
f0101493:	85 ff                	test   %edi,%edi
f0101495:	7f bb                	jg     f0101452 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101497:	83 fe 1f             	cmp    $0x1f,%esi
f010149a:	7e 1c                	jle    f01014b8 <readline+0xcb>
f010149c:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01014a2:	7f 14                	jg     f01014b8 <readline+0xcb>
			if (echoing)
f01014a4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014a8:	74 c2                	je     f010146c <readline+0x7f>
				cputchar(c);
f01014aa:	83 ec 0c             	sub    $0xc,%esp
f01014ad:	56                   	push   %esi
f01014ae:	e8 b0 f2 ff ff       	call   f0100763 <cputchar>
f01014b3:	83 c4 10             	add    $0x10,%esp
f01014b6:	eb b4                	jmp    f010146c <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01014b8:	83 fe 0a             	cmp    $0xa,%esi
f01014bb:	74 05                	je     f01014c2 <readline+0xd5>
f01014bd:	83 fe 0d             	cmp    $0xd,%esi
f01014c0:	75 b6                	jne    f0101478 <readline+0x8b>
			if (echoing)
f01014c2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014c6:	75 13                	jne    f01014db <readline+0xee>
			buf[i] = 0;
f01014c8:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f01014cf:	00 
			return buf;
f01014d0:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f01014d6:	e9 6f ff ff ff       	jmp    f010144a <readline+0x5d>
				cputchar('\n');
f01014db:	83 ec 0c             	sub    $0xc,%esp
f01014de:	6a 0a                	push   $0xa
f01014e0:	e8 7e f2 ff ff       	call   f0100763 <cputchar>
f01014e5:	83 c4 10             	add    $0x10,%esp
f01014e8:	eb de                	jmp    f01014c8 <readline+0xdb>

f01014ea <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01014f5:	eb 03                	jmp    f01014fa <strlen+0x10>
		n++;
f01014f7:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01014fa:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014fe:	75 f7                	jne    f01014f7 <strlen+0xd>
	return n;
}
f0101500:	5d                   	pop    %ebp
f0101501:	c3                   	ret    

f0101502 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101502:	55                   	push   %ebp
f0101503:	89 e5                	mov    %esp,%ebp
f0101505:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101508:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010150b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101510:	eb 03                	jmp    f0101515 <strnlen+0x13>
		n++;
f0101512:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101515:	39 d0                	cmp    %edx,%eax
f0101517:	74 06                	je     f010151f <strnlen+0x1d>
f0101519:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010151d:	75 f3                	jne    f0101512 <strnlen+0x10>
	return n;
}
f010151f:	5d                   	pop    %ebp
f0101520:	c3                   	ret    

f0101521 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101521:	55                   	push   %ebp
f0101522:	89 e5                	mov    %esp,%ebp
f0101524:	53                   	push   %ebx
f0101525:	8b 45 08             	mov    0x8(%ebp),%eax
f0101528:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010152b:	89 c2                	mov    %eax,%edx
f010152d:	83 c1 01             	add    $0x1,%ecx
f0101530:	83 c2 01             	add    $0x1,%edx
f0101533:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101537:	88 5a ff             	mov    %bl,-0x1(%edx)
f010153a:	84 db                	test   %bl,%bl
f010153c:	75 ef                	jne    f010152d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010153e:	5b                   	pop    %ebx
f010153f:	5d                   	pop    %ebp
f0101540:	c3                   	ret    

f0101541 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101541:	55                   	push   %ebp
f0101542:	89 e5                	mov    %esp,%ebp
f0101544:	53                   	push   %ebx
f0101545:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101548:	53                   	push   %ebx
f0101549:	e8 9c ff ff ff       	call   f01014ea <strlen>
f010154e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101551:	ff 75 0c             	pushl  0xc(%ebp)
f0101554:	01 d8                	add    %ebx,%eax
f0101556:	50                   	push   %eax
f0101557:	e8 c5 ff ff ff       	call   f0101521 <strcpy>
	return dst;
}
f010155c:	89 d8                	mov    %ebx,%eax
f010155e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101561:	c9                   	leave  
f0101562:	c3                   	ret    

f0101563 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101563:	55                   	push   %ebp
f0101564:	89 e5                	mov    %esp,%ebp
f0101566:	56                   	push   %esi
f0101567:	53                   	push   %ebx
f0101568:	8b 75 08             	mov    0x8(%ebp),%esi
f010156b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010156e:	89 f3                	mov    %esi,%ebx
f0101570:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101573:	89 f2                	mov    %esi,%edx
f0101575:	eb 0f                	jmp    f0101586 <strncpy+0x23>
		*dst++ = *src;
f0101577:	83 c2 01             	add    $0x1,%edx
f010157a:	0f b6 01             	movzbl (%ecx),%eax
f010157d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101580:	80 39 01             	cmpb   $0x1,(%ecx)
f0101583:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101586:	39 da                	cmp    %ebx,%edx
f0101588:	75 ed                	jne    f0101577 <strncpy+0x14>
	}
	return ret;
}
f010158a:	89 f0                	mov    %esi,%eax
f010158c:	5b                   	pop    %ebx
f010158d:	5e                   	pop    %esi
f010158e:	5d                   	pop    %ebp
f010158f:	c3                   	ret    

f0101590 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101590:	55                   	push   %ebp
f0101591:	89 e5                	mov    %esp,%ebp
f0101593:	56                   	push   %esi
f0101594:	53                   	push   %ebx
f0101595:	8b 75 08             	mov    0x8(%ebp),%esi
f0101598:	8b 55 0c             	mov    0xc(%ebp),%edx
f010159b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010159e:	89 f0                	mov    %esi,%eax
f01015a0:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01015a4:	85 c9                	test   %ecx,%ecx
f01015a6:	75 0b                	jne    f01015b3 <strlcpy+0x23>
f01015a8:	eb 17                	jmp    f01015c1 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01015aa:	83 c2 01             	add    $0x1,%edx
f01015ad:	83 c0 01             	add    $0x1,%eax
f01015b0:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01015b3:	39 d8                	cmp    %ebx,%eax
f01015b5:	74 07                	je     f01015be <strlcpy+0x2e>
f01015b7:	0f b6 0a             	movzbl (%edx),%ecx
f01015ba:	84 c9                	test   %cl,%cl
f01015bc:	75 ec                	jne    f01015aa <strlcpy+0x1a>
		*dst = '\0';
f01015be:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01015c1:	29 f0                	sub    %esi,%eax
}
f01015c3:	5b                   	pop    %ebx
f01015c4:	5e                   	pop    %esi
f01015c5:	5d                   	pop    %ebp
f01015c6:	c3                   	ret    

f01015c7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01015c7:	55                   	push   %ebp
f01015c8:	89 e5                	mov    %esp,%ebp
f01015ca:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015cd:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01015d0:	eb 06                	jmp    f01015d8 <strcmp+0x11>
		p++, q++;
f01015d2:	83 c1 01             	add    $0x1,%ecx
f01015d5:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01015d8:	0f b6 01             	movzbl (%ecx),%eax
f01015db:	84 c0                	test   %al,%al
f01015dd:	74 04                	je     f01015e3 <strcmp+0x1c>
f01015df:	3a 02                	cmp    (%edx),%al
f01015e1:	74 ef                	je     f01015d2 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015e3:	0f b6 c0             	movzbl %al,%eax
f01015e6:	0f b6 12             	movzbl (%edx),%edx
f01015e9:	29 d0                	sub    %edx,%eax
}
f01015eb:	5d                   	pop    %ebp
f01015ec:	c3                   	ret    

f01015ed <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015ed:	55                   	push   %ebp
f01015ee:	89 e5                	mov    %esp,%ebp
f01015f0:	53                   	push   %ebx
f01015f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015f7:	89 c3                	mov    %eax,%ebx
f01015f9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01015fc:	eb 06                	jmp    f0101604 <strncmp+0x17>
		n--, p++, q++;
f01015fe:	83 c0 01             	add    $0x1,%eax
f0101601:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101604:	39 d8                	cmp    %ebx,%eax
f0101606:	74 16                	je     f010161e <strncmp+0x31>
f0101608:	0f b6 08             	movzbl (%eax),%ecx
f010160b:	84 c9                	test   %cl,%cl
f010160d:	74 04                	je     f0101613 <strncmp+0x26>
f010160f:	3a 0a                	cmp    (%edx),%cl
f0101611:	74 eb                	je     f01015fe <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101613:	0f b6 00             	movzbl (%eax),%eax
f0101616:	0f b6 12             	movzbl (%edx),%edx
f0101619:	29 d0                	sub    %edx,%eax
}
f010161b:	5b                   	pop    %ebx
f010161c:	5d                   	pop    %ebp
f010161d:	c3                   	ret    
		return 0;
f010161e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101623:	eb f6                	jmp    f010161b <strncmp+0x2e>

f0101625 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101625:	55                   	push   %ebp
f0101626:	89 e5                	mov    %esp,%ebp
f0101628:	8b 45 08             	mov    0x8(%ebp),%eax
f010162b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010162f:	0f b6 10             	movzbl (%eax),%edx
f0101632:	84 d2                	test   %dl,%dl
f0101634:	74 09                	je     f010163f <strchr+0x1a>
		if (*s == c)
f0101636:	38 ca                	cmp    %cl,%dl
f0101638:	74 0a                	je     f0101644 <strchr+0x1f>
	for (; *s; s++)
f010163a:	83 c0 01             	add    $0x1,%eax
f010163d:	eb f0                	jmp    f010162f <strchr+0xa>
			return (char *) s;
	return 0;
f010163f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101644:	5d                   	pop    %ebp
f0101645:	c3                   	ret    

f0101646 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101646:	55                   	push   %ebp
f0101647:	89 e5                	mov    %esp,%ebp
f0101649:	8b 45 08             	mov    0x8(%ebp),%eax
f010164c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101650:	eb 03                	jmp    f0101655 <strfind+0xf>
f0101652:	83 c0 01             	add    $0x1,%eax
f0101655:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101658:	38 ca                	cmp    %cl,%dl
f010165a:	74 04                	je     f0101660 <strfind+0x1a>
f010165c:	84 d2                	test   %dl,%dl
f010165e:	75 f2                	jne    f0101652 <strfind+0xc>
			break;
	return (char *) s;
}
f0101660:	5d                   	pop    %ebp
f0101661:	c3                   	ret    

f0101662 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101662:	55                   	push   %ebp
f0101663:	89 e5                	mov    %esp,%ebp
f0101665:	57                   	push   %edi
f0101666:	56                   	push   %esi
f0101667:	53                   	push   %ebx
f0101668:	8b 7d 08             	mov    0x8(%ebp),%edi
f010166b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010166e:	85 c9                	test   %ecx,%ecx
f0101670:	74 13                	je     f0101685 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101672:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101678:	75 05                	jne    f010167f <memset+0x1d>
f010167a:	f6 c1 03             	test   $0x3,%cl
f010167d:	74 0d                	je     f010168c <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010167f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101682:	fc                   	cld    
f0101683:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101685:	89 f8                	mov    %edi,%eax
f0101687:	5b                   	pop    %ebx
f0101688:	5e                   	pop    %esi
f0101689:	5f                   	pop    %edi
f010168a:	5d                   	pop    %ebp
f010168b:	c3                   	ret    
		c &= 0xFF;
f010168c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101690:	89 d3                	mov    %edx,%ebx
f0101692:	c1 e3 08             	shl    $0x8,%ebx
f0101695:	89 d0                	mov    %edx,%eax
f0101697:	c1 e0 18             	shl    $0x18,%eax
f010169a:	89 d6                	mov    %edx,%esi
f010169c:	c1 e6 10             	shl    $0x10,%esi
f010169f:	09 f0                	or     %esi,%eax
f01016a1:	09 c2                	or     %eax,%edx
f01016a3:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01016a5:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01016a8:	89 d0                	mov    %edx,%eax
f01016aa:	fc                   	cld    
f01016ab:	f3 ab                	rep stos %eax,%es:(%edi)
f01016ad:	eb d6                	jmp    f0101685 <memset+0x23>

f01016af <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016af:	55                   	push   %ebp
f01016b0:	89 e5                	mov    %esp,%ebp
f01016b2:	57                   	push   %edi
f01016b3:	56                   	push   %esi
f01016b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016ba:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016bd:	39 c6                	cmp    %eax,%esi
f01016bf:	73 35                	jae    f01016f6 <memmove+0x47>
f01016c1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016c4:	39 c2                	cmp    %eax,%edx
f01016c6:	76 2e                	jbe    f01016f6 <memmove+0x47>
		s += n;
		d += n;
f01016c8:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016cb:	89 d6                	mov    %edx,%esi
f01016cd:	09 fe                	or     %edi,%esi
f01016cf:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016d5:	74 0c                	je     f01016e3 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01016d7:	83 ef 01             	sub    $0x1,%edi
f01016da:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01016dd:	fd                   	std    
f01016de:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016e0:	fc                   	cld    
f01016e1:	eb 21                	jmp    f0101704 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016e3:	f6 c1 03             	test   $0x3,%cl
f01016e6:	75 ef                	jne    f01016d7 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016e8:	83 ef 04             	sub    $0x4,%edi
f01016eb:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016ee:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01016f1:	fd                   	std    
f01016f2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016f4:	eb ea                	jmp    f01016e0 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016f6:	89 f2                	mov    %esi,%edx
f01016f8:	09 c2                	or     %eax,%edx
f01016fa:	f6 c2 03             	test   $0x3,%dl
f01016fd:	74 09                	je     f0101708 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016ff:	89 c7                	mov    %eax,%edi
f0101701:	fc                   	cld    
f0101702:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101704:	5e                   	pop    %esi
f0101705:	5f                   	pop    %edi
f0101706:	5d                   	pop    %ebp
f0101707:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101708:	f6 c1 03             	test   $0x3,%cl
f010170b:	75 f2                	jne    f01016ff <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010170d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101710:	89 c7                	mov    %eax,%edi
f0101712:	fc                   	cld    
f0101713:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101715:	eb ed                	jmp    f0101704 <memmove+0x55>

f0101717 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101717:	55                   	push   %ebp
f0101718:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010171a:	ff 75 10             	pushl  0x10(%ebp)
f010171d:	ff 75 0c             	pushl  0xc(%ebp)
f0101720:	ff 75 08             	pushl  0x8(%ebp)
f0101723:	e8 87 ff ff ff       	call   f01016af <memmove>
}
f0101728:	c9                   	leave  
f0101729:	c3                   	ret    

f010172a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010172a:	55                   	push   %ebp
f010172b:	89 e5                	mov    %esp,%ebp
f010172d:	56                   	push   %esi
f010172e:	53                   	push   %ebx
f010172f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101732:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101735:	89 c6                	mov    %eax,%esi
f0101737:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010173a:	39 f0                	cmp    %esi,%eax
f010173c:	74 1c                	je     f010175a <memcmp+0x30>
		if (*s1 != *s2)
f010173e:	0f b6 08             	movzbl (%eax),%ecx
f0101741:	0f b6 1a             	movzbl (%edx),%ebx
f0101744:	38 d9                	cmp    %bl,%cl
f0101746:	75 08                	jne    f0101750 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101748:	83 c0 01             	add    $0x1,%eax
f010174b:	83 c2 01             	add    $0x1,%edx
f010174e:	eb ea                	jmp    f010173a <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0101750:	0f b6 c1             	movzbl %cl,%eax
f0101753:	0f b6 db             	movzbl %bl,%ebx
f0101756:	29 d8                	sub    %ebx,%eax
f0101758:	eb 05                	jmp    f010175f <memcmp+0x35>
	}

	return 0;
f010175a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010175f:	5b                   	pop    %ebx
f0101760:	5e                   	pop    %esi
f0101761:	5d                   	pop    %ebp
f0101762:	c3                   	ret    

f0101763 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101763:	55                   	push   %ebp
f0101764:	89 e5                	mov    %esp,%ebp
f0101766:	8b 45 08             	mov    0x8(%ebp),%eax
f0101769:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010176c:	89 c2                	mov    %eax,%edx
f010176e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101771:	39 d0                	cmp    %edx,%eax
f0101773:	73 09                	jae    f010177e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101775:	38 08                	cmp    %cl,(%eax)
f0101777:	74 05                	je     f010177e <memfind+0x1b>
	for (; s < ends; s++)
f0101779:	83 c0 01             	add    $0x1,%eax
f010177c:	eb f3                	jmp    f0101771 <memfind+0xe>
			break;
	return (void *) s;
}
f010177e:	5d                   	pop    %ebp
f010177f:	c3                   	ret    

f0101780 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101780:	55                   	push   %ebp
f0101781:	89 e5                	mov    %esp,%ebp
f0101783:	57                   	push   %edi
f0101784:	56                   	push   %esi
f0101785:	53                   	push   %ebx
f0101786:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101789:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010178c:	eb 03                	jmp    f0101791 <strtol+0x11>
		s++;
f010178e:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101791:	0f b6 01             	movzbl (%ecx),%eax
f0101794:	3c 20                	cmp    $0x20,%al
f0101796:	74 f6                	je     f010178e <strtol+0xe>
f0101798:	3c 09                	cmp    $0x9,%al
f010179a:	74 f2                	je     f010178e <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010179c:	3c 2b                	cmp    $0x2b,%al
f010179e:	74 2e                	je     f01017ce <strtol+0x4e>
	int neg = 0;
f01017a0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01017a5:	3c 2d                	cmp    $0x2d,%al
f01017a7:	74 2f                	je     f01017d8 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017a9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01017af:	75 05                	jne    f01017b6 <strtol+0x36>
f01017b1:	80 39 30             	cmpb   $0x30,(%ecx)
f01017b4:	74 2c                	je     f01017e2 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017b6:	85 db                	test   %ebx,%ebx
f01017b8:	75 0a                	jne    f01017c4 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01017ba:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01017bf:	80 39 30             	cmpb   $0x30,(%ecx)
f01017c2:	74 28                	je     f01017ec <strtol+0x6c>
		base = 10;
f01017c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01017c9:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01017cc:	eb 50                	jmp    f010181e <strtol+0x9e>
		s++;
f01017ce:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01017d1:	bf 00 00 00 00       	mov    $0x0,%edi
f01017d6:	eb d1                	jmp    f01017a9 <strtol+0x29>
		s++, neg = 1;
f01017d8:	83 c1 01             	add    $0x1,%ecx
f01017db:	bf 01 00 00 00       	mov    $0x1,%edi
f01017e0:	eb c7                	jmp    f01017a9 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017e2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01017e6:	74 0e                	je     f01017f6 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01017e8:	85 db                	test   %ebx,%ebx
f01017ea:	75 d8                	jne    f01017c4 <strtol+0x44>
		s++, base = 8;
f01017ec:	83 c1 01             	add    $0x1,%ecx
f01017ef:	bb 08 00 00 00       	mov    $0x8,%ebx
f01017f4:	eb ce                	jmp    f01017c4 <strtol+0x44>
		s += 2, base = 16;
f01017f6:	83 c1 02             	add    $0x2,%ecx
f01017f9:	bb 10 00 00 00       	mov    $0x10,%ebx
f01017fe:	eb c4                	jmp    f01017c4 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101800:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101803:	89 f3                	mov    %esi,%ebx
f0101805:	80 fb 19             	cmp    $0x19,%bl
f0101808:	77 29                	ja     f0101833 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010180a:	0f be d2             	movsbl %dl,%edx
f010180d:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101810:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101813:	7d 30                	jge    f0101845 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101815:	83 c1 01             	add    $0x1,%ecx
f0101818:	0f af 45 10          	imul   0x10(%ebp),%eax
f010181c:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010181e:	0f b6 11             	movzbl (%ecx),%edx
f0101821:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101824:	89 f3                	mov    %esi,%ebx
f0101826:	80 fb 09             	cmp    $0x9,%bl
f0101829:	77 d5                	ja     f0101800 <strtol+0x80>
			dig = *s - '0';
f010182b:	0f be d2             	movsbl %dl,%edx
f010182e:	83 ea 30             	sub    $0x30,%edx
f0101831:	eb dd                	jmp    f0101810 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101833:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101836:	89 f3                	mov    %esi,%ebx
f0101838:	80 fb 19             	cmp    $0x19,%bl
f010183b:	77 08                	ja     f0101845 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010183d:	0f be d2             	movsbl %dl,%edx
f0101840:	83 ea 37             	sub    $0x37,%edx
f0101843:	eb cb                	jmp    f0101810 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101845:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101849:	74 05                	je     f0101850 <strtol+0xd0>
		*endptr = (char *) s;
f010184b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010184e:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0101850:	89 c2                	mov    %eax,%edx
f0101852:	f7 da                	neg    %edx
f0101854:	85 ff                	test   %edi,%edi
f0101856:	0f 45 c2             	cmovne %edx,%eax
}
f0101859:	5b                   	pop    %ebx
f010185a:	5e                   	pop    %esi
f010185b:	5f                   	pop    %edi
f010185c:	5d                   	pop    %ebp
f010185d:	c3                   	ret    
f010185e:	66 90                	xchg   %ax,%ax

f0101860 <__udivdi3>:
f0101860:	55                   	push   %ebp
f0101861:	57                   	push   %edi
f0101862:	56                   	push   %esi
f0101863:	53                   	push   %ebx
f0101864:	83 ec 1c             	sub    $0x1c,%esp
f0101867:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010186b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010186f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101873:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101877:	85 d2                	test   %edx,%edx
f0101879:	75 35                	jne    f01018b0 <__udivdi3+0x50>
f010187b:	39 f3                	cmp    %esi,%ebx
f010187d:	0f 87 bd 00 00 00    	ja     f0101940 <__udivdi3+0xe0>
f0101883:	85 db                	test   %ebx,%ebx
f0101885:	89 d9                	mov    %ebx,%ecx
f0101887:	75 0b                	jne    f0101894 <__udivdi3+0x34>
f0101889:	b8 01 00 00 00       	mov    $0x1,%eax
f010188e:	31 d2                	xor    %edx,%edx
f0101890:	f7 f3                	div    %ebx
f0101892:	89 c1                	mov    %eax,%ecx
f0101894:	31 d2                	xor    %edx,%edx
f0101896:	89 f0                	mov    %esi,%eax
f0101898:	f7 f1                	div    %ecx
f010189a:	89 c6                	mov    %eax,%esi
f010189c:	89 e8                	mov    %ebp,%eax
f010189e:	89 f7                	mov    %esi,%edi
f01018a0:	f7 f1                	div    %ecx
f01018a2:	89 fa                	mov    %edi,%edx
f01018a4:	83 c4 1c             	add    $0x1c,%esp
f01018a7:	5b                   	pop    %ebx
f01018a8:	5e                   	pop    %esi
f01018a9:	5f                   	pop    %edi
f01018aa:	5d                   	pop    %ebp
f01018ab:	c3                   	ret    
f01018ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018b0:	39 f2                	cmp    %esi,%edx
f01018b2:	77 7c                	ja     f0101930 <__udivdi3+0xd0>
f01018b4:	0f bd fa             	bsr    %edx,%edi
f01018b7:	83 f7 1f             	xor    $0x1f,%edi
f01018ba:	0f 84 98 00 00 00    	je     f0101958 <__udivdi3+0xf8>
f01018c0:	89 f9                	mov    %edi,%ecx
f01018c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01018c7:	29 f8                	sub    %edi,%eax
f01018c9:	d3 e2                	shl    %cl,%edx
f01018cb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01018cf:	89 c1                	mov    %eax,%ecx
f01018d1:	89 da                	mov    %ebx,%edx
f01018d3:	d3 ea                	shr    %cl,%edx
f01018d5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01018d9:	09 d1                	or     %edx,%ecx
f01018db:	89 f2                	mov    %esi,%edx
f01018dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018e1:	89 f9                	mov    %edi,%ecx
f01018e3:	d3 e3                	shl    %cl,%ebx
f01018e5:	89 c1                	mov    %eax,%ecx
f01018e7:	d3 ea                	shr    %cl,%edx
f01018e9:	89 f9                	mov    %edi,%ecx
f01018eb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01018ef:	d3 e6                	shl    %cl,%esi
f01018f1:	89 eb                	mov    %ebp,%ebx
f01018f3:	89 c1                	mov    %eax,%ecx
f01018f5:	d3 eb                	shr    %cl,%ebx
f01018f7:	09 de                	or     %ebx,%esi
f01018f9:	89 f0                	mov    %esi,%eax
f01018fb:	f7 74 24 08          	divl   0x8(%esp)
f01018ff:	89 d6                	mov    %edx,%esi
f0101901:	89 c3                	mov    %eax,%ebx
f0101903:	f7 64 24 0c          	mull   0xc(%esp)
f0101907:	39 d6                	cmp    %edx,%esi
f0101909:	72 0c                	jb     f0101917 <__udivdi3+0xb7>
f010190b:	89 f9                	mov    %edi,%ecx
f010190d:	d3 e5                	shl    %cl,%ebp
f010190f:	39 c5                	cmp    %eax,%ebp
f0101911:	73 5d                	jae    f0101970 <__udivdi3+0x110>
f0101913:	39 d6                	cmp    %edx,%esi
f0101915:	75 59                	jne    f0101970 <__udivdi3+0x110>
f0101917:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010191a:	31 ff                	xor    %edi,%edi
f010191c:	89 fa                	mov    %edi,%edx
f010191e:	83 c4 1c             	add    $0x1c,%esp
f0101921:	5b                   	pop    %ebx
f0101922:	5e                   	pop    %esi
f0101923:	5f                   	pop    %edi
f0101924:	5d                   	pop    %ebp
f0101925:	c3                   	ret    
f0101926:	8d 76 00             	lea    0x0(%esi),%esi
f0101929:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101930:	31 ff                	xor    %edi,%edi
f0101932:	31 c0                	xor    %eax,%eax
f0101934:	89 fa                	mov    %edi,%edx
f0101936:	83 c4 1c             	add    $0x1c,%esp
f0101939:	5b                   	pop    %ebx
f010193a:	5e                   	pop    %esi
f010193b:	5f                   	pop    %edi
f010193c:	5d                   	pop    %ebp
f010193d:	c3                   	ret    
f010193e:	66 90                	xchg   %ax,%ax
f0101940:	31 ff                	xor    %edi,%edi
f0101942:	89 e8                	mov    %ebp,%eax
f0101944:	89 f2                	mov    %esi,%edx
f0101946:	f7 f3                	div    %ebx
f0101948:	89 fa                	mov    %edi,%edx
f010194a:	83 c4 1c             	add    $0x1c,%esp
f010194d:	5b                   	pop    %ebx
f010194e:	5e                   	pop    %esi
f010194f:	5f                   	pop    %edi
f0101950:	5d                   	pop    %ebp
f0101951:	c3                   	ret    
f0101952:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101958:	39 f2                	cmp    %esi,%edx
f010195a:	72 06                	jb     f0101962 <__udivdi3+0x102>
f010195c:	31 c0                	xor    %eax,%eax
f010195e:	39 eb                	cmp    %ebp,%ebx
f0101960:	77 d2                	ja     f0101934 <__udivdi3+0xd4>
f0101962:	b8 01 00 00 00       	mov    $0x1,%eax
f0101967:	eb cb                	jmp    f0101934 <__udivdi3+0xd4>
f0101969:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101970:	89 d8                	mov    %ebx,%eax
f0101972:	31 ff                	xor    %edi,%edi
f0101974:	eb be                	jmp    f0101934 <__udivdi3+0xd4>
f0101976:	66 90                	xchg   %ax,%ax
f0101978:	66 90                	xchg   %ax,%ax
f010197a:	66 90                	xchg   %ax,%ax
f010197c:	66 90                	xchg   %ax,%ax
f010197e:	66 90                	xchg   %ax,%ax

f0101980 <__umoddi3>:
f0101980:	55                   	push   %ebp
f0101981:	57                   	push   %edi
f0101982:	56                   	push   %esi
f0101983:	53                   	push   %ebx
f0101984:	83 ec 1c             	sub    $0x1c,%esp
f0101987:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010198b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010198f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101993:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101997:	85 ed                	test   %ebp,%ebp
f0101999:	89 f0                	mov    %esi,%eax
f010199b:	89 da                	mov    %ebx,%edx
f010199d:	75 19                	jne    f01019b8 <__umoddi3+0x38>
f010199f:	39 df                	cmp    %ebx,%edi
f01019a1:	0f 86 b1 00 00 00    	jbe    f0101a58 <__umoddi3+0xd8>
f01019a7:	f7 f7                	div    %edi
f01019a9:	89 d0                	mov    %edx,%eax
f01019ab:	31 d2                	xor    %edx,%edx
f01019ad:	83 c4 1c             	add    $0x1c,%esp
f01019b0:	5b                   	pop    %ebx
f01019b1:	5e                   	pop    %esi
f01019b2:	5f                   	pop    %edi
f01019b3:	5d                   	pop    %ebp
f01019b4:	c3                   	ret    
f01019b5:	8d 76 00             	lea    0x0(%esi),%esi
f01019b8:	39 dd                	cmp    %ebx,%ebp
f01019ba:	77 f1                	ja     f01019ad <__umoddi3+0x2d>
f01019bc:	0f bd cd             	bsr    %ebp,%ecx
f01019bf:	83 f1 1f             	xor    $0x1f,%ecx
f01019c2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01019c6:	0f 84 b4 00 00 00    	je     f0101a80 <__umoddi3+0x100>
f01019cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01019d1:	89 c2                	mov    %eax,%edx
f01019d3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019d7:	29 c2                	sub    %eax,%edx
f01019d9:	89 c1                	mov    %eax,%ecx
f01019db:	89 f8                	mov    %edi,%eax
f01019dd:	d3 e5                	shl    %cl,%ebp
f01019df:	89 d1                	mov    %edx,%ecx
f01019e1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01019e5:	d3 e8                	shr    %cl,%eax
f01019e7:	09 c5                	or     %eax,%ebp
f01019e9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019ed:	89 c1                	mov    %eax,%ecx
f01019ef:	d3 e7                	shl    %cl,%edi
f01019f1:	89 d1                	mov    %edx,%ecx
f01019f3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01019f7:	89 df                	mov    %ebx,%edi
f01019f9:	d3 ef                	shr    %cl,%edi
f01019fb:	89 c1                	mov    %eax,%ecx
f01019fd:	89 f0                	mov    %esi,%eax
f01019ff:	d3 e3                	shl    %cl,%ebx
f0101a01:	89 d1                	mov    %edx,%ecx
f0101a03:	89 fa                	mov    %edi,%edx
f0101a05:	d3 e8                	shr    %cl,%eax
f0101a07:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a0c:	09 d8                	or     %ebx,%eax
f0101a0e:	f7 f5                	div    %ebp
f0101a10:	d3 e6                	shl    %cl,%esi
f0101a12:	89 d1                	mov    %edx,%ecx
f0101a14:	f7 64 24 08          	mull   0x8(%esp)
f0101a18:	39 d1                	cmp    %edx,%ecx
f0101a1a:	89 c3                	mov    %eax,%ebx
f0101a1c:	89 d7                	mov    %edx,%edi
f0101a1e:	72 06                	jb     f0101a26 <__umoddi3+0xa6>
f0101a20:	75 0e                	jne    f0101a30 <__umoddi3+0xb0>
f0101a22:	39 c6                	cmp    %eax,%esi
f0101a24:	73 0a                	jae    f0101a30 <__umoddi3+0xb0>
f0101a26:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101a2a:	19 ea                	sbb    %ebp,%edx
f0101a2c:	89 d7                	mov    %edx,%edi
f0101a2e:	89 c3                	mov    %eax,%ebx
f0101a30:	89 ca                	mov    %ecx,%edx
f0101a32:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101a37:	29 de                	sub    %ebx,%esi
f0101a39:	19 fa                	sbb    %edi,%edx
f0101a3b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101a3f:	89 d0                	mov    %edx,%eax
f0101a41:	d3 e0                	shl    %cl,%eax
f0101a43:	89 d9                	mov    %ebx,%ecx
f0101a45:	d3 ee                	shr    %cl,%esi
f0101a47:	d3 ea                	shr    %cl,%edx
f0101a49:	09 f0                	or     %esi,%eax
f0101a4b:	83 c4 1c             	add    $0x1c,%esp
f0101a4e:	5b                   	pop    %ebx
f0101a4f:	5e                   	pop    %esi
f0101a50:	5f                   	pop    %edi
f0101a51:	5d                   	pop    %ebp
f0101a52:	c3                   	ret    
f0101a53:	90                   	nop
f0101a54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a58:	85 ff                	test   %edi,%edi
f0101a5a:	89 f9                	mov    %edi,%ecx
f0101a5c:	75 0b                	jne    f0101a69 <__umoddi3+0xe9>
f0101a5e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a63:	31 d2                	xor    %edx,%edx
f0101a65:	f7 f7                	div    %edi
f0101a67:	89 c1                	mov    %eax,%ecx
f0101a69:	89 d8                	mov    %ebx,%eax
f0101a6b:	31 d2                	xor    %edx,%edx
f0101a6d:	f7 f1                	div    %ecx
f0101a6f:	89 f0                	mov    %esi,%eax
f0101a71:	f7 f1                	div    %ecx
f0101a73:	e9 31 ff ff ff       	jmp    f01019a9 <__umoddi3+0x29>
f0101a78:	90                   	nop
f0101a79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a80:	39 dd                	cmp    %ebx,%ebp
f0101a82:	72 08                	jb     f0101a8c <__umoddi3+0x10c>
f0101a84:	39 f7                	cmp    %esi,%edi
f0101a86:	0f 87 21 ff ff ff    	ja     f01019ad <__umoddi3+0x2d>
f0101a8c:	89 da                	mov    %ebx,%edx
f0101a8e:	89 f0                	mov    %esi,%eax
f0101a90:	29 f8                	sub    %edi,%eax
f0101a92:	19 ea                	sbb    %ebp,%edx
f0101a94:	e9 14 ff ff ff       	jmp    f01019ad <__umoddi3+0x2d>
