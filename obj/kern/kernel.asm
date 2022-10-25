
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
f0100045:	e8 91 01 00 00       	call   f01001db <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 18 07 ff ff    	lea    -0xf8e8(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 05 0a 00 00       	call   f0100a68 <cprintf>
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
f0100073:	e8 2a 08 00 00       	call   f01008a2 <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	56                   	push   %esi
f010007f:	8d 83 34 07 ff ff    	lea    -0xf8cc(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 dd 09 00 00       	call   f0100a68 <cprintf>
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
f01000ad:	e8 29 01 00 00       	call   f01001db <__x86.get_pc_thunk.bx>
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
f01000ca:	e8 f9 14 00 00       	call   f01015c8 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 5c 05 00 00       	call   f0100630 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 4f 07 ff ff    	lea    -0xf8b1(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 80 09 00 00       	call   f0100a68 <cprintf>
	
	unsigned int i = 0x00646c72;
f01000e8:	c7 45 f4 72 6c 64 00 	movl   $0x646c72,-0xc(%ebp)
	Lab1_exercise8_3:
    cprintf("H%x Wo%s", 57616, &i);
f01000ef:	83 c4 0c             	add    $0xc,%esp
f01000f2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01000f5:	50                   	push   %eax
f01000f6:	68 10 e1 00 00       	push   $0xe110
f01000fb:	8d 83 6a 07 ff ff    	lea    -0xf896(%ebx),%eax
f0100101:	50                   	push   %eax
f0100102:	e8 61 09 00 00       	call   f0100a68 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f0100107:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f010010e:	e8 2d ff ff ff       	call   f0100040 <test_backtrace>
f0100113:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100116:	83 ec 0c             	sub    $0xc,%esp
f0100119:	6a 00                	push   $0x0
f010011b:	e8 8c 07 00 00       	call   f01008ac <monitor>
f0100120:	83 c4 10             	add    $0x10,%esp
f0100123:	eb f1                	jmp    f0100116 <i386_init+0x70>

f0100125 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100125:	55                   	push   %ebp
f0100126:	89 e5                	mov    %esp,%ebp
f0100128:	57                   	push   %edi
f0100129:	56                   	push   %esi
f010012a:	53                   	push   %ebx
f010012b:	83 ec 0c             	sub    $0xc,%esp
f010012e:	e8 a8 00 00 00       	call   f01001db <__x86.get_pc_thunk.bx>
f0100133:	81 c3 d5 11 01 00    	add    $0x111d5,%ebx
f0100139:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f010013c:	c7 c0 a4 36 11 f0    	mov    $0xf01136a4,%eax
f0100142:	83 38 00             	cmpl   $0x0,(%eax)
f0100145:	74 0f                	je     f0100156 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100147:	83 ec 0c             	sub    $0xc,%esp
f010014a:	6a 00                	push   $0x0
f010014c:	e8 5b 07 00 00       	call   f01008ac <monitor>
f0100151:	83 c4 10             	add    $0x10,%esp
f0100154:	eb f1                	jmp    f0100147 <_panic+0x22>
	panicstr = fmt;
f0100156:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f0100158:	fa                   	cli    
f0100159:	fc                   	cld    
	va_start(ap, fmt);
f010015a:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010015d:	83 ec 04             	sub    $0x4,%esp
f0100160:	ff 75 0c             	pushl  0xc(%ebp)
f0100163:	ff 75 08             	pushl  0x8(%ebp)
f0100166:	8d 83 73 07 ff ff    	lea    -0xf88d(%ebx),%eax
f010016c:	50                   	push   %eax
f010016d:	e8 f6 08 00 00       	call   f0100a68 <cprintf>
	vcprintf(fmt, ap);
f0100172:	83 c4 08             	add    $0x8,%esp
f0100175:	56                   	push   %esi
f0100176:	57                   	push   %edi
f0100177:	e8 b5 08 00 00       	call   f0100a31 <vcprintf>
	cprintf("\n");
f010017c:	8d 83 af 07 ff ff    	lea    -0xf851(%ebx),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 de 08 00 00       	call   f0100a68 <cprintf>
f010018a:	83 c4 10             	add    $0x10,%esp
f010018d:	eb b8                	jmp    f0100147 <_panic+0x22>

f010018f <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010018f:	55                   	push   %ebp
f0100190:	89 e5                	mov    %esp,%ebp
f0100192:	56                   	push   %esi
f0100193:	53                   	push   %ebx
f0100194:	e8 42 00 00 00       	call   f01001db <__x86.get_pc_thunk.bx>
f0100199:	81 c3 6f 11 01 00    	add    $0x1116f,%ebx
	va_list ap;

	va_start(ap, fmt);
f010019f:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f01001a2:	83 ec 04             	sub    $0x4,%esp
f01001a5:	ff 75 0c             	pushl  0xc(%ebp)
f01001a8:	ff 75 08             	pushl  0x8(%ebp)
f01001ab:	8d 83 8b 07 ff ff    	lea    -0xf875(%ebx),%eax
f01001b1:	50                   	push   %eax
f01001b2:	e8 b1 08 00 00       	call   f0100a68 <cprintf>
	vcprintf(fmt, ap);
f01001b7:	83 c4 08             	add    $0x8,%esp
f01001ba:	56                   	push   %esi
f01001bb:	ff 75 10             	pushl  0x10(%ebp)
f01001be:	e8 6e 08 00 00       	call   f0100a31 <vcprintf>
	cprintf("\n");
f01001c3:	8d 83 af 07 ff ff    	lea    -0xf851(%ebx),%eax
f01001c9:	89 04 24             	mov    %eax,(%esp)
f01001cc:	e8 97 08 00 00       	call   f0100a68 <cprintf>
	va_end(ap);
}
f01001d1:	83 c4 10             	add    $0x10,%esp
f01001d4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001d7:	5b                   	pop    %ebx
f01001d8:	5e                   	pop    %esi
f01001d9:	5d                   	pop    %ebp
f01001da:	c3                   	ret    

f01001db <__x86.get_pc_thunk.bx>:
f01001db:	8b 1c 24             	mov    (%esp),%ebx
f01001de:	c3                   	ret    

f01001df <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001df:	55                   	push   %ebp
f01001e0:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e2:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001e7:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001e8:	a8 01                	test   $0x1,%al
f01001ea:	74 0b                	je     f01001f7 <serial_proc_data+0x18>
f01001ec:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001f1:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001f2:	0f b6 c0             	movzbl %al,%eax
}
f01001f5:	5d                   	pop    %ebp
f01001f6:	c3                   	ret    
		return -1;
f01001f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001fc:	eb f7                	jmp    f01001f5 <serial_proc_data+0x16>

f01001fe <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001fe:	55                   	push   %ebp
f01001ff:	89 e5                	mov    %esp,%ebp
f0100201:	56                   	push   %esi
f0100202:	53                   	push   %ebx
f0100203:	e8 d3 ff ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f0100208:	81 c3 00 11 01 00    	add    $0x11100,%ebx
f010020e:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100210:	ff d6                	call   *%esi
f0100212:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100215:	74 2e                	je     f0100245 <cons_intr+0x47>
		if (c == 0)
f0100217:	85 c0                	test   %eax,%eax
f0100219:	74 f5                	je     f0100210 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010021b:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100221:	8d 51 01             	lea    0x1(%ecx),%edx
f0100224:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010022a:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f0100231:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100237:	75 d7                	jne    f0100210 <cons_intr+0x12>
			cons.wpos = 0;
f0100239:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f0100240:	00 00 00 
f0100243:	eb cb                	jmp    f0100210 <cons_intr+0x12>
	}
}
f0100245:	5b                   	pop    %ebx
f0100246:	5e                   	pop    %esi
f0100247:	5d                   	pop    %ebp
f0100248:	c3                   	ret    

f0100249 <kbd_proc_data>:
{
f0100249:	55                   	push   %ebp
f010024a:	89 e5                	mov    %esp,%ebp
f010024c:	56                   	push   %esi
f010024d:	53                   	push   %ebx
f010024e:	e8 88 ff ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f0100253:	81 c3 b5 10 01 00    	add    $0x110b5,%ebx
f0100259:	ba 64 00 00 00       	mov    $0x64,%edx
f010025e:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f010025f:	a8 01                	test   $0x1,%al
f0100261:	0f 84 06 01 00 00    	je     f010036d <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f0100267:	a8 20                	test   $0x20,%al
f0100269:	0f 85 05 01 00 00    	jne    f0100374 <kbd_proc_data+0x12b>
f010026f:	ba 60 00 00 00       	mov    $0x60,%edx
f0100274:	ec                   	in     (%dx),%al
f0100275:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100277:	3c e0                	cmp    $0xe0,%al
f0100279:	0f 84 93 00 00 00    	je     f0100312 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f010027f:	84 c0                	test   %al,%al
f0100281:	0f 88 a0 00 00 00    	js     f0100327 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100287:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010028d:	f6 c1 40             	test   $0x40,%cl
f0100290:	74 0e                	je     f01002a0 <kbd_proc_data+0x57>
		data |= 0x80;
f0100292:	83 c8 80             	or     $0xffffff80,%eax
f0100295:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100297:	83 e1 bf             	and    $0xffffffbf,%ecx
f010029a:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f01002a0:	0f b6 d2             	movzbl %dl,%edx
f01002a3:	0f b6 84 13 d8 08 ff 	movzbl -0xf728(%ebx,%edx,1),%eax
f01002aa:	ff 
f01002ab:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f01002b1:	0f b6 8c 13 d8 07 ff 	movzbl -0xf828(%ebx,%edx,1),%ecx
f01002b8:	ff 
f01002b9:	31 c8                	xor    %ecx,%eax
f01002bb:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f01002c1:	89 c1                	mov    %eax,%ecx
f01002c3:	83 e1 03             	and    $0x3,%ecx
f01002c6:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002cd:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002d1:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002d4:	a8 08                	test   $0x8,%al
f01002d6:	74 0d                	je     f01002e5 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f01002d8:	89 f2                	mov    %esi,%edx
f01002da:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002dd:	83 f9 19             	cmp    $0x19,%ecx
f01002e0:	77 7a                	ja     f010035c <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002e2:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002e5:	f7 d0                	not    %eax
f01002e7:	a8 06                	test   $0x6,%al
f01002e9:	75 33                	jne    f010031e <kbd_proc_data+0xd5>
f01002eb:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002f1:	75 2b                	jne    f010031e <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f01002f3:	83 ec 0c             	sub    $0xc,%esp
f01002f6:	8d 83 a5 07 ff ff    	lea    -0xf85b(%ebx),%eax
f01002fc:	50                   	push   %eax
f01002fd:	e8 66 07 00 00       	call   f0100a68 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100302:	b8 03 00 00 00       	mov    $0x3,%eax
f0100307:	ba 92 00 00 00       	mov    $0x92,%edx
f010030c:	ee                   	out    %al,(%dx)
f010030d:	83 c4 10             	add    $0x10,%esp
f0100310:	eb 0c                	jmp    f010031e <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100312:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f0100319:	be 00 00 00 00       	mov    $0x0,%esi
}
f010031e:	89 f0                	mov    %esi,%eax
f0100320:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100323:	5b                   	pop    %ebx
f0100324:	5e                   	pop    %esi
f0100325:	5d                   	pop    %ebp
f0100326:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100327:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010032d:	89 ce                	mov    %ecx,%esi
f010032f:	83 e6 40             	and    $0x40,%esi
f0100332:	83 e0 7f             	and    $0x7f,%eax
f0100335:	85 f6                	test   %esi,%esi
f0100337:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010033a:	0f b6 d2             	movzbl %dl,%edx
f010033d:	0f b6 84 13 d8 08 ff 	movzbl -0xf728(%ebx,%edx,1),%eax
f0100344:	ff 
f0100345:	83 c8 40             	or     $0x40,%eax
f0100348:	0f b6 c0             	movzbl %al,%eax
f010034b:	f7 d0                	not    %eax
f010034d:	21 c8                	and    %ecx,%eax
f010034f:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f0100355:	be 00 00 00 00       	mov    $0x0,%esi
f010035a:	eb c2                	jmp    f010031e <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f010035c:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010035f:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100362:	83 fa 1a             	cmp    $0x1a,%edx
f0100365:	0f 42 f1             	cmovb  %ecx,%esi
f0100368:	e9 78 ff ff ff       	jmp    f01002e5 <kbd_proc_data+0x9c>
		return -1;
f010036d:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100372:	eb aa                	jmp    f010031e <kbd_proc_data+0xd5>
		return -1;
f0100374:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100379:	eb a3                	jmp    f010031e <kbd_proc_data+0xd5>

f010037b <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010037b:	55                   	push   %ebp
f010037c:	89 e5                	mov    %esp,%ebp
f010037e:	57                   	push   %edi
f010037f:	56                   	push   %esi
f0100380:	53                   	push   %ebx
f0100381:	83 ec 1c             	sub    $0x1c,%esp
f0100384:	e8 52 fe ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f0100389:	81 c3 7f 0f 01 00    	add    $0x10f7f,%ebx
f010038f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100392:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100397:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010039c:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003a1:	eb 09                	jmp    f01003ac <cons_putc+0x31>
f01003a3:	89 ca                	mov    %ecx,%edx
f01003a5:	ec                   	in     (%dx),%al
f01003a6:	ec                   	in     (%dx),%al
f01003a7:	ec                   	in     (%dx),%al
f01003a8:	ec                   	in     (%dx),%al
	     i++)
f01003a9:	83 c6 01             	add    $0x1,%esi
f01003ac:	89 fa                	mov    %edi,%edx
f01003ae:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003af:	a8 20                	test   $0x20,%al
f01003b1:	75 08                	jne    f01003bb <cons_putc+0x40>
f01003b3:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003b9:	7e e8                	jle    f01003a3 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f01003bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003be:	89 f8                	mov    %edi,%eax
f01003c0:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003c3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003c8:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003c9:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ce:	bf 79 03 00 00       	mov    $0x379,%edi
f01003d3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003d8:	eb 09                	jmp    f01003e3 <cons_putc+0x68>
f01003da:	89 ca                	mov    %ecx,%edx
f01003dc:	ec                   	in     (%dx),%al
f01003dd:	ec                   	in     (%dx),%al
f01003de:	ec                   	in     (%dx),%al
f01003df:	ec                   	in     (%dx),%al
f01003e0:	83 c6 01             	add    $0x1,%esi
f01003e3:	89 fa                	mov    %edi,%edx
f01003e5:	ec                   	in     (%dx),%al
f01003e6:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003ec:	7f 04                	jg     f01003f2 <cons_putc+0x77>
f01003ee:	84 c0                	test   %al,%al
f01003f0:	79 e8                	jns    f01003da <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003f2:	ba 78 03 00 00       	mov    $0x378,%edx
f01003f7:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003fb:	ee                   	out    %al,(%dx)
f01003fc:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100401:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100406:	ee                   	out    %al,(%dx)
f0100407:	b8 08 00 00 00       	mov    $0x8,%eax
f010040c:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010040d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100410:	89 fa                	mov    %edi,%edx
f0100412:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100418:	89 f8                	mov    %edi,%eax
f010041a:	80 cc 07             	or     $0x7,%ah
f010041d:	85 d2                	test   %edx,%edx
f010041f:	0f 45 c7             	cmovne %edi,%eax
f0100422:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100425:	0f b6 c0             	movzbl %al,%eax
f0100428:	83 f8 09             	cmp    $0x9,%eax
f010042b:	0f 84 b9 00 00 00    	je     f01004ea <cons_putc+0x16f>
f0100431:	83 f8 09             	cmp    $0x9,%eax
f0100434:	7e 74                	jle    f01004aa <cons_putc+0x12f>
f0100436:	83 f8 0a             	cmp    $0xa,%eax
f0100439:	0f 84 9e 00 00 00    	je     f01004dd <cons_putc+0x162>
f010043f:	83 f8 0d             	cmp    $0xd,%eax
f0100442:	0f 85 d9 00 00 00    	jne    f0100521 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100448:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010044f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100455:	c1 e8 16             	shr    $0x16,%eax
f0100458:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010045b:	c1 e0 04             	shl    $0x4,%eax
f010045e:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100465:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f010046c:	cf 07 
f010046e:	0f 87 d4 00 00 00    	ja     f0100548 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100474:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f010047a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047f:	89 ca                	mov    %ecx,%edx
f0100481:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100482:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f0100489:	8d 71 01             	lea    0x1(%ecx),%esi
f010048c:	89 d8                	mov    %ebx,%eax
f010048e:	66 c1 e8 08          	shr    $0x8,%ax
f0100492:	89 f2                	mov    %esi,%edx
f0100494:	ee                   	out    %al,(%dx)
f0100495:	b8 0f 00 00 00       	mov    $0xf,%eax
f010049a:	89 ca                	mov    %ecx,%edx
f010049c:	ee                   	out    %al,(%dx)
f010049d:	89 d8                	mov    %ebx,%eax
f010049f:	89 f2                	mov    %esi,%edx
f01004a1:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004a5:	5b                   	pop    %ebx
f01004a6:	5e                   	pop    %esi
f01004a7:	5f                   	pop    %edi
f01004a8:	5d                   	pop    %ebp
f01004a9:	c3                   	ret    
	switch (c & 0xff) {
f01004aa:	83 f8 08             	cmp    $0x8,%eax
f01004ad:	75 72                	jne    f0100521 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f01004af:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01004b6:	66 85 c0             	test   %ax,%ax
f01004b9:	74 b9                	je     f0100474 <cons_putc+0xf9>
			crt_pos--;
f01004bb:	83 e8 01             	sub    $0x1,%eax
f01004be:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004c5:	0f b7 c0             	movzwl %ax,%eax
f01004c8:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004cc:	b2 00                	mov    $0x0,%dl
f01004ce:	83 ca 20             	or     $0x20,%edx
f01004d1:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01004d7:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004db:	eb 88                	jmp    f0100465 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f01004dd:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f01004e4:	50 
f01004e5:	e9 5e ff ff ff       	jmp    f0100448 <cons_putc+0xcd>
		cons_putc(' ');
f01004ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ef:	e8 87 fe ff ff       	call   f010037b <cons_putc>
		cons_putc(' ');
f01004f4:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f9:	e8 7d fe ff ff       	call   f010037b <cons_putc>
		cons_putc(' ');
f01004fe:	b8 20 00 00 00       	mov    $0x20,%eax
f0100503:	e8 73 fe ff ff       	call   f010037b <cons_putc>
		cons_putc(' ');
f0100508:	b8 20 00 00 00       	mov    $0x20,%eax
f010050d:	e8 69 fe ff ff       	call   f010037b <cons_putc>
		cons_putc(' ');
f0100512:	b8 20 00 00 00       	mov    $0x20,%eax
f0100517:	e8 5f fe ff ff       	call   f010037b <cons_putc>
f010051c:	e9 44 ff ff ff       	jmp    f0100465 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100521:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100528:	8d 50 01             	lea    0x1(%eax),%edx
f010052b:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f0100532:	0f b7 c0             	movzwl %ax,%eax
f0100535:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010053b:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100543:	e9 1d ff ff ff       	jmp    f0100465 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100548:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	68 00 0f 00 00       	push   $0xf00
f0100556:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010055c:	52                   	push   %edx
f010055d:	50                   	push   %eax
f010055e:	e8 b2 10 00 00       	call   f0101615 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100563:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f0100569:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010056f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100575:	83 c4 10             	add    $0x10,%esp
f0100578:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010057d:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100580:	39 d0                	cmp    %edx,%eax
f0100582:	75 f4                	jne    f0100578 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100584:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f010058b:	50 
f010058c:	e9 e3 fe ff ff       	jmp    f0100474 <cons_putc+0xf9>

f0100591 <serial_intr>:
{
f0100591:	e8 e7 01 00 00       	call   f010077d <__x86.get_pc_thunk.ax>
f0100596:	05 72 0d 01 00       	add    $0x10d72,%eax
	if (serial_exists)
f010059b:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f01005a2:	75 02                	jne    f01005a6 <serial_intr+0x15>
f01005a4:	f3 c3                	repz ret 
{
f01005a6:	55                   	push   %ebp
f01005a7:	89 e5                	mov    %esp,%ebp
f01005a9:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01005ac:	8d 80 d7 ee fe ff    	lea    -0x11129(%eax),%eax
f01005b2:	e8 47 fc ff ff       	call   f01001fe <cons_intr>
}
f01005b7:	c9                   	leave  
f01005b8:	c3                   	ret    

f01005b9 <kbd_intr>:
{
f01005b9:	55                   	push   %ebp
f01005ba:	89 e5                	mov    %esp,%ebp
f01005bc:	83 ec 08             	sub    $0x8,%esp
f01005bf:	e8 b9 01 00 00       	call   f010077d <__x86.get_pc_thunk.ax>
f01005c4:	05 44 0d 01 00       	add    $0x10d44,%eax
	cons_intr(kbd_proc_data);
f01005c9:	8d 80 41 ef fe ff    	lea    -0x110bf(%eax),%eax
f01005cf:	e8 2a fc ff ff       	call   f01001fe <cons_intr>
}
f01005d4:	c9                   	leave  
f01005d5:	c3                   	ret    

f01005d6 <cons_getc>:
{
f01005d6:	55                   	push   %ebp
f01005d7:	89 e5                	mov    %esp,%ebp
f01005d9:	53                   	push   %ebx
f01005da:	83 ec 04             	sub    $0x4,%esp
f01005dd:	e8 f9 fb ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f01005e2:	81 c3 26 0d 01 00    	add    $0x10d26,%ebx
	serial_intr();
f01005e8:	e8 a4 ff ff ff       	call   f0100591 <serial_intr>
	kbd_intr();
f01005ed:	e8 c7 ff ff ff       	call   f01005b9 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005f2:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005fd:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100603:	74 19                	je     f010061e <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100605:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100608:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f010060e:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f0100615:	00 
		if (cons.rpos == CONSBUFSIZE)
f0100616:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f010061c:	74 06                	je     f0100624 <cons_getc+0x4e>
}
f010061e:	83 c4 04             	add    $0x4,%esp
f0100621:	5b                   	pop    %ebx
f0100622:	5d                   	pop    %ebp
f0100623:	c3                   	ret    
			cons.rpos = 0;
f0100624:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010062b:	00 00 00 
f010062e:	eb ee                	jmp    f010061e <cons_getc+0x48>

f0100630 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	57                   	push   %edi
f0100634:	56                   	push   %esi
f0100635:	53                   	push   %ebx
f0100636:	83 ec 1c             	sub    $0x1c,%esp
f0100639:	e8 9d fb ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f010063e:	81 c3 ca 0c 01 00    	add    $0x10cca,%ebx
	was = *cp;
f0100644:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010064b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100652:	5a a5 
	if (*cp != 0xA55A) {
f0100654:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010065b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010065f:	0f 84 bc 00 00 00    	je     f0100721 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f0100665:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f010066c:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010066f:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100676:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f010067c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100681:	89 fa                	mov    %edi,%edx
f0100683:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100684:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100687:	89 ca                	mov    %ecx,%edx
f0100689:	ec                   	in     (%dx),%al
f010068a:	0f b6 f0             	movzbl %al,%esi
f010068d:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100690:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100695:	89 fa                	mov    %edi,%edx
f0100697:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100698:	89 ca                	mov    %ecx,%edx
f010069a:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010069b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010069e:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f01006a4:	0f b6 c0             	movzbl %al,%eax
f01006a7:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f01006a9:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006b0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01006b5:	89 c8                	mov    %ecx,%eax
f01006b7:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006bc:	ee                   	out    %al,(%dx)
f01006bd:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006c2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006c7:	89 fa                	mov    %edi,%edx
f01006c9:	ee                   	out    %al,(%dx)
f01006ca:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006cf:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006d4:	ee                   	out    %al,(%dx)
f01006d5:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006da:	89 c8                	mov    %ecx,%eax
f01006dc:	89 f2                	mov    %esi,%edx
f01006de:	ee                   	out    %al,(%dx)
f01006df:	b8 03 00 00 00       	mov    $0x3,%eax
f01006e4:	89 fa                	mov    %edi,%edx
f01006e6:	ee                   	out    %al,(%dx)
f01006e7:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006ec:	89 c8                	mov    %ecx,%eax
f01006ee:	ee                   	out    %al,(%dx)
f01006ef:	b8 01 00 00 00       	mov    $0x1,%eax
f01006f4:	89 f2                	mov    %esi,%edx
f01006f6:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006f7:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006fc:	ec                   	in     (%dx),%al
f01006fd:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006ff:	3c ff                	cmp    $0xff,%al
f0100701:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f0100708:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010070d:	ec                   	in     (%dx),%al
f010070e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100713:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100714:	80 f9 ff             	cmp    $0xff,%cl
f0100717:	74 25                	je     f010073e <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f0100719:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010071c:	5b                   	pop    %ebx
f010071d:	5e                   	pop    %esi
f010071e:	5f                   	pop    %edi
f010071f:	5d                   	pop    %ebp
f0100720:	c3                   	ret    
		*cp = was;
f0100721:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100728:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f010072f:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100732:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f0100739:	e9 38 ff ff ff       	jmp    f0100676 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f010073e:	83 ec 0c             	sub    $0xc,%esp
f0100741:	8d 83 b1 07 ff ff    	lea    -0xf84f(%ebx),%eax
f0100747:	50                   	push   %eax
f0100748:	e8 1b 03 00 00       	call   f0100a68 <cprintf>
f010074d:	83 c4 10             	add    $0x10,%esp
}
f0100750:	eb c7                	jmp    f0100719 <cons_init+0xe9>

f0100752 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100752:	55                   	push   %ebp
f0100753:	89 e5                	mov    %esp,%ebp
f0100755:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100758:	8b 45 08             	mov    0x8(%ebp),%eax
f010075b:	e8 1b fc ff ff       	call   f010037b <cons_putc>
}
f0100760:	c9                   	leave  
f0100761:	c3                   	ret    

f0100762 <getchar>:

int
getchar(void)
{
f0100762:	55                   	push   %ebp
f0100763:	89 e5                	mov    %esp,%ebp
f0100765:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100768:	e8 69 fe ff ff       	call   f01005d6 <cons_getc>
f010076d:	85 c0                	test   %eax,%eax
f010076f:	74 f7                	je     f0100768 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100771:	c9                   	leave  
f0100772:	c3                   	ret    

f0100773 <iscons>:

int
iscons(int fdnum)
{
f0100773:	55                   	push   %ebp
f0100774:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100776:	b8 01 00 00 00       	mov    $0x1,%eax
f010077b:	5d                   	pop    %ebp
f010077c:	c3                   	ret    

f010077d <__x86.get_pc_thunk.ax>:
f010077d:	8b 04 24             	mov    (%esp),%eax
f0100780:	c3                   	ret    

f0100781 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100781:	55                   	push   %ebp
f0100782:	89 e5                	mov    %esp,%ebp
f0100784:	56                   	push   %esi
f0100785:	53                   	push   %ebx
f0100786:	e8 50 fa ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f010078b:	81 c3 7d 0b 01 00    	add    $0x10b7d,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100791:	83 ec 04             	sub    $0x4,%esp
f0100794:	8d 83 d8 09 ff ff    	lea    -0xf628(%ebx),%eax
f010079a:	50                   	push   %eax
f010079b:	8d 83 f6 09 ff ff    	lea    -0xf60a(%ebx),%eax
f01007a1:	50                   	push   %eax
f01007a2:	8d b3 fb 09 ff ff    	lea    -0xf605(%ebx),%esi
f01007a8:	56                   	push   %esi
f01007a9:	e8 ba 02 00 00       	call   f0100a68 <cprintf>
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	8d 83 64 0a ff ff    	lea    -0xf59c(%ebx),%eax
f01007b7:	50                   	push   %eax
f01007b8:	8d 83 04 0a ff ff    	lea    -0xf5fc(%ebx),%eax
f01007be:	50                   	push   %eax
f01007bf:	56                   	push   %esi
f01007c0:	e8 a3 02 00 00       	call   f0100a68 <cprintf>
	return 0;
}
f01007c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ca:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007cd:	5b                   	pop    %ebx
f01007ce:	5e                   	pop    %esi
f01007cf:	5d                   	pop    %ebp
f01007d0:	c3                   	ret    

f01007d1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007d1:	55                   	push   %ebp
f01007d2:	89 e5                	mov    %esp,%ebp
f01007d4:	57                   	push   %edi
f01007d5:	56                   	push   %esi
f01007d6:	53                   	push   %ebx
f01007d7:	83 ec 18             	sub    $0x18,%esp
f01007da:	e8 fc f9 ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f01007df:	81 c3 29 0b 01 00    	add    $0x10b29,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007e5:	8d 83 0d 0a ff ff    	lea    -0xf5f3(%ebx),%eax
f01007eb:	50                   	push   %eax
f01007ec:	e8 77 02 00 00       	call   f0100a68 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007f1:	83 c4 08             	add    $0x8,%esp
f01007f4:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007fa:	8d 83 8c 0a ff ff    	lea    -0xf574(%ebx),%eax
f0100800:	50                   	push   %eax
f0100801:	e8 62 02 00 00       	call   f0100a68 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100806:	83 c4 0c             	add    $0xc,%esp
f0100809:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010080f:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100815:	50                   	push   %eax
f0100816:	57                   	push   %edi
f0100817:	8d 83 b4 0a ff ff    	lea    -0xf54c(%ebx),%eax
f010081d:	50                   	push   %eax
f010081e:	e8 45 02 00 00       	call   f0100a68 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100823:	83 c4 0c             	add    $0xc,%esp
f0100826:	c7 c0 09 1a 10 f0    	mov    $0xf0101a09,%eax
f010082c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100832:	52                   	push   %edx
f0100833:	50                   	push   %eax
f0100834:	8d 83 d8 0a ff ff    	lea    -0xf528(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 28 02 00 00       	call   f0100a68 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100840:	83 c4 0c             	add    $0xc,%esp
f0100843:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100849:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010084f:	52                   	push   %edx
f0100850:	50                   	push   %eax
f0100851:	8d 83 fc 0a ff ff    	lea    -0xf504(%ebx),%eax
f0100857:	50                   	push   %eax
f0100858:	e8 0b 02 00 00       	call   f0100a68 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010085d:	83 c4 0c             	add    $0xc,%esp
f0100860:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f0100866:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010086c:	50                   	push   %eax
f010086d:	56                   	push   %esi
f010086e:	8d 83 20 0b ff ff    	lea    -0xf4e0(%ebx),%eax
f0100874:	50                   	push   %eax
f0100875:	e8 ee 01 00 00       	call   f0100a68 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010087a:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010087d:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100883:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100885:	c1 fe 0a             	sar    $0xa,%esi
f0100888:	56                   	push   %esi
f0100889:	8d 83 44 0b ff ff    	lea    -0xf4bc(%ebx),%eax
f010088f:	50                   	push   %eax
f0100890:	e8 d3 01 00 00       	call   f0100a68 <cprintf>
	return 0;
}
f0100895:	b8 00 00 00 00       	mov    $0x0,%eax
f010089a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010089d:	5b                   	pop    %ebx
f010089e:	5e                   	pop    %esi
f010089f:	5f                   	pop    %edi
f01008a0:	5d                   	pop    %ebp
f01008a1:	c3                   	ret    

f01008a2 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008a2:	55                   	push   %ebp
f01008a3:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01008a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008aa:	5d                   	pop    %ebp
f01008ab:	c3                   	ret    

f01008ac <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008ac:	55                   	push   %ebp
f01008ad:	89 e5                	mov    %esp,%ebp
f01008af:	57                   	push   %edi
f01008b0:	56                   	push   %esi
f01008b1:	53                   	push   %ebx
f01008b2:	83 ec 68             	sub    $0x68,%esp
f01008b5:	e8 21 f9 ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f01008ba:	81 c3 4e 0a 01 00    	add    $0x10a4e,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008c0:	8d 83 70 0b ff ff    	lea    -0xf490(%ebx),%eax
f01008c6:	50                   	push   %eax
f01008c7:	e8 9c 01 00 00       	call   f0100a68 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008cc:	8d 83 94 0b ff ff    	lea    -0xf46c(%ebx),%eax
f01008d2:	89 04 24             	mov    %eax,(%esp)
f01008d5:	e8 8e 01 00 00       	call   f0100a68 <cprintf>
f01008da:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008dd:	8d bb 2a 0a ff ff    	lea    -0xf5d6(%ebx),%edi
f01008e3:	eb 4a                	jmp    f010092f <monitor+0x83>
f01008e5:	83 ec 08             	sub    $0x8,%esp
f01008e8:	0f be c0             	movsbl %al,%eax
f01008eb:	50                   	push   %eax
f01008ec:	57                   	push   %edi
f01008ed:	e8 99 0c 00 00       	call   f010158b <strchr>
f01008f2:	83 c4 10             	add    $0x10,%esp
f01008f5:	85 c0                	test   %eax,%eax
f01008f7:	74 08                	je     f0100901 <monitor+0x55>
			*buf++ = 0;
f01008f9:	c6 06 00             	movb   $0x0,(%esi)
f01008fc:	8d 76 01             	lea    0x1(%esi),%esi
f01008ff:	eb 79                	jmp    f010097a <monitor+0xce>
		if (*buf == 0)
f0100901:	80 3e 00             	cmpb   $0x0,(%esi)
f0100904:	74 7f                	je     f0100985 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100906:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f010090a:	74 0f                	je     f010091b <monitor+0x6f>
		argv[argc++] = buf;
f010090c:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010090f:	8d 48 01             	lea    0x1(%eax),%ecx
f0100912:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100915:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100919:	eb 44                	jmp    f010095f <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010091b:	83 ec 08             	sub    $0x8,%esp
f010091e:	6a 10                	push   $0x10
f0100920:	8d 83 2f 0a ff ff    	lea    -0xf5d1(%ebx),%eax
f0100926:	50                   	push   %eax
f0100927:	e8 3c 01 00 00       	call   f0100a68 <cprintf>
f010092c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010092f:	8d 83 26 0a ff ff    	lea    -0xf5da(%ebx),%eax
f0100935:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100938:	83 ec 0c             	sub    $0xc,%esp
f010093b:	ff 75 a4             	pushl  -0x5c(%ebp)
f010093e:	e8 10 0a 00 00       	call   f0101353 <readline>
f0100943:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100945:	83 c4 10             	add    $0x10,%esp
f0100948:	85 c0                	test   %eax,%eax
f010094a:	74 ec                	je     f0100938 <monitor+0x8c>
	argv[argc] = 0;
f010094c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100953:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f010095a:	eb 1e                	jmp    f010097a <monitor+0xce>
			buf++;
f010095c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010095f:	0f b6 06             	movzbl (%esi),%eax
f0100962:	84 c0                	test   %al,%al
f0100964:	74 14                	je     f010097a <monitor+0xce>
f0100966:	83 ec 08             	sub    $0x8,%esp
f0100969:	0f be c0             	movsbl %al,%eax
f010096c:	50                   	push   %eax
f010096d:	57                   	push   %edi
f010096e:	e8 18 0c 00 00       	call   f010158b <strchr>
f0100973:	83 c4 10             	add    $0x10,%esp
f0100976:	85 c0                	test   %eax,%eax
f0100978:	74 e2                	je     f010095c <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f010097a:	0f b6 06             	movzbl (%esi),%eax
f010097d:	84 c0                	test   %al,%al
f010097f:	0f 85 60 ff ff ff    	jne    f01008e5 <monitor+0x39>
	argv[argc] = 0;
f0100985:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100988:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f010098f:	00 
	if (argc == 0)
f0100990:	85 c0                	test   %eax,%eax
f0100992:	74 9b                	je     f010092f <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100994:	83 ec 08             	sub    $0x8,%esp
f0100997:	8d 83 f6 09 ff ff    	lea    -0xf60a(%ebx),%eax
f010099d:	50                   	push   %eax
f010099e:	ff 75 a8             	pushl  -0x58(%ebp)
f01009a1:	e8 87 0b 00 00       	call   f010152d <strcmp>
f01009a6:	83 c4 10             	add    $0x10,%esp
f01009a9:	85 c0                	test   %eax,%eax
f01009ab:	74 38                	je     f01009e5 <monitor+0x139>
f01009ad:	83 ec 08             	sub    $0x8,%esp
f01009b0:	8d 83 04 0a ff ff    	lea    -0xf5fc(%ebx),%eax
f01009b6:	50                   	push   %eax
f01009b7:	ff 75 a8             	pushl  -0x58(%ebp)
f01009ba:	e8 6e 0b 00 00       	call   f010152d <strcmp>
f01009bf:	83 c4 10             	add    $0x10,%esp
f01009c2:	85 c0                	test   %eax,%eax
f01009c4:	74 1a                	je     f01009e0 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009c6:	83 ec 08             	sub    $0x8,%esp
f01009c9:	ff 75 a8             	pushl  -0x58(%ebp)
f01009cc:	8d 83 4c 0a ff ff    	lea    -0xf5b4(%ebx),%eax
f01009d2:	50                   	push   %eax
f01009d3:	e8 90 00 00 00       	call   f0100a68 <cprintf>
f01009d8:	83 c4 10             	add    $0x10,%esp
f01009db:	e9 4f ff ff ff       	jmp    f010092f <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009e0:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f01009e5:	83 ec 04             	sub    $0x4,%esp
f01009e8:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01009eb:	ff 75 08             	pushl  0x8(%ebp)
f01009ee:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009f1:	52                   	push   %edx
f01009f2:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009f5:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f01009fc:	83 c4 10             	add    $0x10,%esp
f01009ff:	85 c0                	test   %eax,%eax
f0100a01:	0f 89 28 ff ff ff    	jns    f010092f <monitor+0x83>
				break;
	}
}
f0100a07:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a0a:	5b                   	pop    %ebx
f0100a0b:	5e                   	pop    %esi
f0100a0c:	5f                   	pop    %edi
f0100a0d:	5d                   	pop    %ebp
f0100a0e:	c3                   	ret    

f0100a0f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a0f:	55                   	push   %ebp
f0100a10:	89 e5                	mov    %esp,%ebp
f0100a12:	53                   	push   %ebx
f0100a13:	83 ec 10             	sub    $0x10,%esp
f0100a16:	e8 c0 f7 ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f0100a1b:	81 c3 ed 08 01 00    	add    $0x108ed,%ebx
	cputchar(ch);
f0100a21:	ff 75 08             	pushl  0x8(%ebp)
f0100a24:	e8 29 fd ff ff       	call   f0100752 <cputchar>
	*cnt++;
}
f0100a29:	83 c4 10             	add    $0x10,%esp
f0100a2c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a2f:	c9                   	leave  
f0100a30:	c3                   	ret    

f0100a31 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a31:	55                   	push   %ebp
f0100a32:	89 e5                	mov    %esp,%ebp
f0100a34:	53                   	push   %ebx
f0100a35:	83 ec 14             	sub    $0x14,%esp
f0100a38:	e8 9e f7 ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f0100a3d:	81 c3 cb 08 01 00    	add    $0x108cb,%ebx
	int cnt = 0;
f0100a43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a4a:	ff 75 0c             	pushl  0xc(%ebp)
f0100a4d:	ff 75 08             	pushl  0x8(%ebp)
f0100a50:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a53:	50                   	push   %eax
f0100a54:	8d 83 07 f7 fe ff    	lea    -0x108f9(%ebx),%eax
f0100a5a:	50                   	push   %eax
f0100a5b:	e8 1c 04 00 00       	call   f0100e7c <vprintfmt>
	return cnt;
}
f0100a60:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a63:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a66:	c9                   	leave  
f0100a67:	c3                   	ret    

f0100a68 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a68:	55                   	push   %ebp
f0100a69:	89 e5                	mov    %esp,%ebp
f0100a6b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a6e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a71:	50                   	push   %eax
f0100a72:	ff 75 08             	pushl  0x8(%ebp)
f0100a75:	e8 b7 ff ff ff       	call   f0100a31 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a7a:	c9                   	leave  
f0100a7b:	c3                   	ret    

f0100a7c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a7c:	55                   	push   %ebp
f0100a7d:	89 e5                	mov    %esp,%ebp
f0100a7f:	57                   	push   %edi
f0100a80:	56                   	push   %esi
f0100a81:	53                   	push   %ebx
f0100a82:	83 ec 14             	sub    $0x14,%esp
f0100a85:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a88:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a8b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a8e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a91:	8b 32                	mov    (%edx),%esi
f0100a93:	8b 01                	mov    (%ecx),%eax
f0100a95:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a98:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a9f:	eb 2f                	jmp    f0100ad0 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100aa1:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100aa4:	39 c6                	cmp    %eax,%esi
f0100aa6:	7f 49                	jg     f0100af1 <stab_binsearch+0x75>
f0100aa8:	0f b6 0a             	movzbl (%edx),%ecx
f0100aab:	83 ea 0c             	sub    $0xc,%edx
f0100aae:	39 f9                	cmp    %edi,%ecx
f0100ab0:	75 ef                	jne    f0100aa1 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100ab2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ab5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ab8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100abc:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100abf:	73 35                	jae    f0100af6 <stab_binsearch+0x7a>
			*region_left = m;
f0100ac1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ac4:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100ac6:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100ac9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100ad0:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100ad3:	7f 4e                	jg     f0100b23 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ad8:	01 f0                	add    %esi,%eax
f0100ada:	89 c3                	mov    %eax,%ebx
f0100adc:	c1 eb 1f             	shr    $0x1f,%ebx
f0100adf:	01 c3                	add    %eax,%ebx
f0100ae1:	d1 fb                	sar    %ebx
f0100ae3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ae6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ae9:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100aed:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100aef:	eb b3                	jmp    f0100aa4 <stab_binsearch+0x28>
			l = true_m + 1;
f0100af1:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100af4:	eb da                	jmp    f0100ad0 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100af6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100af9:	76 14                	jbe    f0100b0f <stab_binsearch+0x93>
			*region_right = m - 1;
f0100afb:	83 e8 01             	sub    $0x1,%eax
f0100afe:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b01:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100b04:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100b06:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b0d:	eb c1                	jmp    f0100ad0 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b0f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b12:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100b14:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b18:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100b1a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b21:	eb ad                	jmp    f0100ad0 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100b23:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b27:	74 16                	je     f0100b3f <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b29:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b2c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b2e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b31:	8b 0e                	mov    (%esi),%ecx
f0100b33:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b36:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b39:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100b3d:	eb 12                	jmp    f0100b51 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100b3f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b42:	8b 00                	mov    (%eax),%eax
f0100b44:	83 e8 01             	sub    $0x1,%eax
f0100b47:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b4a:	89 07                	mov    %eax,(%edi)
f0100b4c:	eb 16                	jmp    f0100b64 <stab_binsearch+0xe8>
		     l--)
f0100b4e:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100b51:	39 c1                	cmp    %eax,%ecx
f0100b53:	7d 0a                	jge    f0100b5f <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100b55:	0f b6 1a             	movzbl (%edx),%ebx
f0100b58:	83 ea 0c             	sub    $0xc,%edx
f0100b5b:	39 fb                	cmp    %edi,%ebx
f0100b5d:	75 ef                	jne    f0100b4e <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100b5f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b62:	89 07                	mov    %eax,(%edi)
	}
}
f0100b64:	83 c4 14             	add    $0x14,%esp
f0100b67:	5b                   	pop    %ebx
f0100b68:	5e                   	pop    %esi
f0100b69:	5f                   	pop    %edi
f0100b6a:	5d                   	pop    %ebp
f0100b6b:	c3                   	ret    

f0100b6c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b6c:	55                   	push   %ebp
f0100b6d:	89 e5                	mov    %esp,%ebp
f0100b6f:	57                   	push   %edi
f0100b70:	56                   	push   %esi
f0100b71:	53                   	push   %ebx
f0100b72:	83 ec 2c             	sub    $0x2c,%esp
f0100b75:	e8 fa 01 00 00       	call   f0100d74 <__x86.get_pc_thunk.cx>
f0100b7a:	81 c1 8e 07 01 00    	add    $0x1078e,%ecx
f0100b80:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100b83:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100b86:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b89:	8d 81 bc 0b ff ff    	lea    -0xf444(%ecx),%eax
f0100b8f:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100b91:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100b98:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100b9b:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100ba2:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100ba5:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bac:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100bb2:	0f 86 f4 00 00 00    	jbe    f0100cac <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bb8:	c7 c0 ad 5c 10 f0    	mov    $0xf0105cad,%eax
f0100bbe:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100bc4:	0f 86 88 01 00 00    	jbe    f0100d52 <debuginfo_eip+0x1e6>
f0100bca:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100bcd:	c7 c0 fc 75 10 f0    	mov    $0xf01075fc,%eax
f0100bd3:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100bd7:	0f 85 7c 01 00 00    	jne    f0100d59 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bdd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100be4:	c7 c0 dc 20 10 f0    	mov    $0xf01020dc,%eax
f0100bea:	c7 c2 ac 5c 10 f0    	mov    $0xf0105cac,%edx
f0100bf0:	29 c2                	sub    %eax,%edx
f0100bf2:	c1 fa 02             	sar    $0x2,%edx
f0100bf5:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100bfb:	83 ea 01             	sub    $0x1,%edx
f0100bfe:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c01:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c04:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c07:	83 ec 08             	sub    $0x8,%esp
f0100c0a:	53                   	push   %ebx
f0100c0b:	6a 64                	push   $0x64
f0100c0d:	e8 6a fe ff ff       	call   f0100a7c <stab_binsearch>
	if (lfile == 0)
f0100c12:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c15:	83 c4 10             	add    $0x10,%esp
f0100c18:	85 c0                	test   %eax,%eax
f0100c1a:	0f 84 40 01 00 00    	je     f0100d60 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c20:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c23:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c26:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c29:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c2c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c2f:	83 ec 08             	sub    $0x8,%esp
f0100c32:	53                   	push   %ebx
f0100c33:	6a 24                	push   $0x24
f0100c35:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100c38:	c7 c0 dc 20 10 f0    	mov    $0xf01020dc,%eax
f0100c3e:	e8 39 fe ff ff       	call   f0100a7c <stab_binsearch>

	if (lfun <= rfun) {
f0100c43:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100c46:	83 c4 10             	add    $0x10,%esp
f0100c49:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100c4c:	7f 79                	jg     f0100cc7 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c4e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c51:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c54:	c7 c2 dc 20 10 f0    	mov    $0xf01020dc,%edx
f0100c5a:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100c5d:	8b 11                	mov    (%ecx),%edx
f0100c5f:	c7 c0 fc 75 10 f0    	mov    $0xf01075fc,%eax
f0100c65:	81 e8 ad 5c 10 f0    	sub    $0xf0105cad,%eax
f0100c6b:	39 c2                	cmp    %eax,%edx
f0100c6d:	73 09                	jae    f0100c78 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c6f:	81 c2 ad 5c 10 f0    	add    $0xf0105cad,%edx
f0100c75:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c78:	8b 41 08             	mov    0x8(%ecx),%eax
f0100c7b:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c7e:	83 ec 08             	sub    $0x8,%esp
f0100c81:	6a 3a                	push   $0x3a
f0100c83:	ff 77 08             	pushl  0x8(%edi)
f0100c86:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c89:	e8 1e 09 00 00       	call   f01015ac <strfind>
f0100c8e:	2b 47 08             	sub    0x8(%edi),%eax
f0100c91:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c94:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c97:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c9a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100c9d:	c7 c2 dc 20 10 f0    	mov    $0xf01020dc,%edx
f0100ca3:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100ca7:	83 c4 10             	add    $0x10,%esp
f0100caa:	eb 29                	jmp    f0100cd5 <debuginfo_eip+0x169>
  	        panic("User address");
f0100cac:	83 ec 04             	sub    $0x4,%esp
f0100caf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cb2:	8d 83 c6 0b ff ff    	lea    -0xf43a(%ebx),%eax
f0100cb8:	50                   	push   %eax
f0100cb9:	6a 7f                	push   $0x7f
f0100cbb:	8d 83 d3 0b ff ff    	lea    -0xf42d(%ebx),%eax
f0100cc1:	50                   	push   %eax
f0100cc2:	e8 5e f4 ff ff       	call   f0100125 <_panic>
		info->eip_fn_addr = addr;
f0100cc7:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100cca:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ccd:	eb af                	jmp    f0100c7e <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ccf:	83 ee 01             	sub    $0x1,%esi
f0100cd2:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100cd5:	39 f3                	cmp    %esi,%ebx
f0100cd7:	7f 3a                	jg     f0100d13 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100cd9:	0f b6 10             	movzbl (%eax),%edx
f0100cdc:	80 fa 84             	cmp    $0x84,%dl
f0100cdf:	74 0b                	je     f0100cec <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100ce1:	80 fa 64             	cmp    $0x64,%dl
f0100ce4:	75 e9                	jne    f0100ccf <debuginfo_eip+0x163>
f0100ce6:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100cea:	74 e3                	je     f0100ccf <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cec:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100cef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cf2:	c7 c0 dc 20 10 f0    	mov    $0xf01020dc,%eax
f0100cf8:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100cfb:	c7 c0 fc 75 10 f0    	mov    $0xf01075fc,%eax
f0100d01:	81 e8 ad 5c 10 f0    	sub    $0xf0105cad,%eax
f0100d07:	39 c2                	cmp    %eax,%edx
f0100d09:	73 08                	jae    f0100d13 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d0b:	81 c2 ad 5c 10 f0    	add    $0xf0105cad,%edx
f0100d11:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d13:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100d16:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d19:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100d1e:	39 cb                	cmp    %ecx,%ebx
f0100d20:	7d 4a                	jge    f0100d6c <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100d22:	8d 53 01             	lea    0x1(%ebx),%edx
f0100d25:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100d28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d2b:	c7 c0 dc 20 10 f0    	mov    $0xf01020dc,%eax
f0100d31:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100d35:	eb 07                	jmp    f0100d3e <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100d37:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100d3b:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100d3e:	39 d1                	cmp    %edx,%ecx
f0100d40:	74 25                	je     f0100d67 <debuginfo_eip+0x1fb>
f0100d42:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d45:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100d49:	74 ec                	je     f0100d37 <debuginfo_eip+0x1cb>
	return 0;
f0100d4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d50:	eb 1a                	jmp    f0100d6c <debuginfo_eip+0x200>
		return -1;
f0100d52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d57:	eb 13                	jmp    f0100d6c <debuginfo_eip+0x200>
f0100d59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d5e:	eb 0c                	jmp    f0100d6c <debuginfo_eip+0x200>
		return -1;
f0100d60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d65:	eb 05                	jmp    f0100d6c <debuginfo_eip+0x200>
	return 0;
f0100d67:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d6c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d6f:	5b                   	pop    %ebx
f0100d70:	5e                   	pop    %esi
f0100d71:	5f                   	pop    %edi
f0100d72:	5d                   	pop    %ebp
f0100d73:	c3                   	ret    

f0100d74 <__x86.get_pc_thunk.cx>:
f0100d74:	8b 0c 24             	mov    (%esp),%ecx
f0100d77:	c3                   	ret    

f0100d78 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d78:	55                   	push   %ebp
f0100d79:	89 e5                	mov    %esp,%ebp
f0100d7b:	57                   	push   %edi
f0100d7c:	56                   	push   %esi
f0100d7d:	53                   	push   %ebx
f0100d7e:	83 ec 2c             	sub    $0x2c,%esp
f0100d81:	e8 ee ff ff ff       	call   f0100d74 <__x86.get_pc_thunk.cx>
f0100d86:	81 c1 82 05 01 00    	add    $0x10582,%ecx
f0100d8c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100d8f:	89 c7                	mov    %eax,%edi
f0100d91:	89 d6                	mov    %edx,%esi
f0100d93:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d96:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d99:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d9c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d9f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100da2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100da7:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100daa:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100dad:	39 d3                	cmp    %edx,%ebx
f0100daf:	72 09                	jb     f0100dba <printnum+0x42>
f0100db1:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100db4:	0f 87 83 00 00 00    	ja     f0100e3d <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dba:	83 ec 0c             	sub    $0xc,%esp
f0100dbd:	ff 75 18             	pushl  0x18(%ebp)
f0100dc0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dc3:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100dc6:	53                   	push   %ebx
f0100dc7:	ff 75 10             	pushl  0x10(%ebp)
f0100dca:	83 ec 08             	sub    $0x8,%esp
f0100dcd:	ff 75 dc             	pushl  -0x24(%ebp)
f0100dd0:	ff 75 d8             	pushl  -0x28(%ebp)
f0100dd3:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100dd6:	ff 75 d0             	pushl  -0x30(%ebp)
f0100dd9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ddc:	e8 ef 09 00 00       	call   f01017d0 <__udivdi3>
f0100de1:	83 c4 18             	add    $0x18,%esp
f0100de4:	52                   	push   %edx
f0100de5:	50                   	push   %eax
f0100de6:	89 f2                	mov    %esi,%edx
f0100de8:	89 f8                	mov    %edi,%eax
f0100dea:	e8 89 ff ff ff       	call   f0100d78 <printnum>
f0100def:	83 c4 20             	add    $0x20,%esp
f0100df2:	eb 13                	jmp    f0100e07 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100df4:	83 ec 08             	sub    $0x8,%esp
f0100df7:	56                   	push   %esi
f0100df8:	ff 75 18             	pushl  0x18(%ebp)
f0100dfb:	ff d7                	call   *%edi
f0100dfd:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100e00:	83 eb 01             	sub    $0x1,%ebx
f0100e03:	85 db                	test   %ebx,%ebx
f0100e05:	7f ed                	jg     f0100df4 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e07:	83 ec 08             	sub    $0x8,%esp
f0100e0a:	56                   	push   %esi
f0100e0b:	83 ec 04             	sub    $0x4,%esp
f0100e0e:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e11:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e14:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e17:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e1a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100e1d:	89 f3                	mov    %esi,%ebx
f0100e1f:	e8 cc 0a 00 00       	call   f01018f0 <__umoddi3>
f0100e24:	83 c4 14             	add    $0x14,%esp
f0100e27:	0f be 84 06 e1 0b ff 	movsbl -0xf41f(%esi,%eax,1),%eax
f0100e2e:	ff 
f0100e2f:	50                   	push   %eax
f0100e30:	ff d7                	call   *%edi
}
f0100e32:	83 c4 10             	add    $0x10,%esp
f0100e35:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e38:	5b                   	pop    %ebx
f0100e39:	5e                   	pop    %esi
f0100e3a:	5f                   	pop    %edi
f0100e3b:	5d                   	pop    %ebp
f0100e3c:	c3                   	ret    
f0100e3d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e40:	eb be                	jmp    f0100e00 <printnum+0x88>

f0100e42 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e42:	55                   	push   %ebp
f0100e43:	89 e5                	mov    %esp,%ebp
f0100e45:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e48:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e4c:	8b 10                	mov    (%eax),%edx
f0100e4e:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e51:	73 0a                	jae    f0100e5d <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e53:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e56:	89 08                	mov    %ecx,(%eax)
f0100e58:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e5b:	88 02                	mov    %al,(%edx)
}
f0100e5d:	5d                   	pop    %ebp
f0100e5e:	c3                   	ret    

f0100e5f <printfmt>:
{
f0100e5f:	55                   	push   %ebp
f0100e60:	89 e5                	mov    %esp,%ebp
f0100e62:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100e65:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e68:	50                   	push   %eax
f0100e69:	ff 75 10             	pushl  0x10(%ebp)
f0100e6c:	ff 75 0c             	pushl  0xc(%ebp)
f0100e6f:	ff 75 08             	pushl  0x8(%ebp)
f0100e72:	e8 05 00 00 00       	call   f0100e7c <vprintfmt>
}
f0100e77:	83 c4 10             	add    $0x10,%esp
f0100e7a:	c9                   	leave  
f0100e7b:	c3                   	ret    

f0100e7c <vprintfmt>:
{
f0100e7c:	55                   	push   %ebp
f0100e7d:	89 e5                	mov    %esp,%ebp
f0100e7f:	57                   	push   %edi
f0100e80:	56                   	push   %esi
f0100e81:	53                   	push   %ebx
f0100e82:	83 ec 2c             	sub    $0x2c,%esp
f0100e85:	e8 51 f3 ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f0100e8a:	81 c3 7e 04 01 00    	add    $0x1047e,%ebx
f0100e90:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e93:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e96:	e9 8e 03 00 00       	jmp    f0101229 <.L35+0x48>
		padc = ' ';
f0100e9b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100e9f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100ea6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0100ead:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100eb4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100eb9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100ebc:	8d 47 01             	lea    0x1(%edi),%eax
f0100ebf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ec2:	0f b6 17             	movzbl (%edi),%edx
f0100ec5:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100ec8:	3c 55                	cmp    $0x55,%al
f0100eca:	0f 87 e1 03 00 00    	ja     f01012b1 <.L22>
f0100ed0:	0f b6 c0             	movzbl %al,%eax
f0100ed3:	89 d9                	mov    %ebx,%ecx
f0100ed5:	03 8c 83 6c 0c ff ff 	add    -0xf394(%ebx,%eax,4),%ecx
f0100edc:	ff e1                	jmp    *%ecx

f0100ede <.L67>:
f0100ede:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100ee1:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100ee5:	eb d5                	jmp    f0100ebc <vprintfmt+0x40>

f0100ee7 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100eea:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100eee:	eb cc                	jmp    f0100ebc <vprintfmt+0x40>

f0100ef0 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef0:	0f b6 d2             	movzbl %dl,%edx
f0100ef3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100ef6:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0100efb:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100efe:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f02:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f05:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f08:	83 f9 09             	cmp    $0x9,%ecx
f0100f0b:	77 55                	ja     f0100f62 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0100f0d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100f10:	eb e9                	jmp    f0100efb <.L29+0xb>

f0100f12 <.L26>:
			precision = va_arg(ap, int);
f0100f12:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f15:	8b 00                	mov    (%eax),%eax
f0100f17:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1d:	8d 40 04             	lea    0x4(%eax),%eax
f0100f20:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f23:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100f26:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f2a:	79 90                	jns    f0100ebc <vprintfmt+0x40>
				width = precision, precision = -1;
f0100f2c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f2f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f32:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f39:	eb 81                	jmp    f0100ebc <vprintfmt+0x40>

f0100f3b <.L27>:
f0100f3b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f3e:	85 c0                	test   %eax,%eax
f0100f40:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f45:	0f 49 d0             	cmovns %eax,%edx
f0100f48:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f4e:	e9 69 ff ff ff       	jmp    f0100ebc <vprintfmt+0x40>

f0100f53 <.L23>:
f0100f53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0100f56:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f5d:	e9 5a ff ff ff       	jmp    f0100ebc <vprintfmt+0x40>
f0100f62:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f65:	eb bf                	jmp    f0100f26 <.L26+0x14>

f0100f67 <.L33>:
			lflag++;
f0100f67:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f6b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0100f6e:	e9 49 ff ff ff       	jmp    f0100ebc <vprintfmt+0x40>

f0100f73 <.L30>:
			putch(va_arg(ap, int), putdat);
f0100f73:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f76:	8d 78 04             	lea    0x4(%eax),%edi
f0100f79:	83 ec 08             	sub    $0x8,%esp
f0100f7c:	56                   	push   %esi
f0100f7d:	ff 30                	pushl  (%eax)
f0100f7f:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f82:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100f85:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100f88:	e9 99 02 00 00       	jmp    f0101226 <.L35+0x45>

f0100f8d <.L32>:
			err = va_arg(ap, int);
f0100f8d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f90:	8d 78 04             	lea    0x4(%eax),%edi
f0100f93:	8b 00                	mov    (%eax),%eax
f0100f95:	99                   	cltd   
f0100f96:	31 d0                	xor    %edx,%eax
f0100f98:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f9a:	83 f8 06             	cmp    $0x6,%eax
f0100f9d:	7f 27                	jg     f0100fc6 <.L32+0x39>
f0100f9f:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0100fa6:	85 d2                	test   %edx,%edx
f0100fa8:	74 1c                	je     f0100fc6 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0100faa:	52                   	push   %edx
f0100fab:	8d 83 70 07 ff ff    	lea    -0xf890(%ebx),%eax
f0100fb1:	50                   	push   %eax
f0100fb2:	56                   	push   %esi
f0100fb3:	ff 75 08             	pushl  0x8(%ebp)
f0100fb6:	e8 a4 fe ff ff       	call   f0100e5f <printfmt>
f0100fbb:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fbe:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100fc1:	e9 60 02 00 00       	jmp    f0101226 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0100fc6:	50                   	push   %eax
f0100fc7:	8d 83 f9 0b ff ff    	lea    -0xf407(%ebx),%eax
f0100fcd:	50                   	push   %eax
f0100fce:	56                   	push   %esi
f0100fcf:	ff 75 08             	pushl  0x8(%ebp)
f0100fd2:	e8 88 fe ff ff       	call   f0100e5f <printfmt>
f0100fd7:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fda:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100fdd:	e9 44 02 00 00       	jmp    f0101226 <.L35+0x45>

f0100fe2 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0100fe2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe5:	83 c0 04             	add    $0x4,%eax
f0100fe8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100feb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fee:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100ff0:	85 ff                	test   %edi,%edi
f0100ff2:	8d 83 f2 0b ff ff    	lea    -0xf40e(%ebx),%eax
f0100ff8:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100ffb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fff:	0f 8e b5 00 00 00    	jle    f01010ba <.L36+0xd8>
f0101005:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101009:	75 08                	jne    f0101013 <.L36+0x31>
f010100b:	89 75 0c             	mov    %esi,0xc(%ebp)
f010100e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101011:	eb 6d                	jmp    f0101080 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101013:	83 ec 08             	sub    $0x8,%esp
f0101016:	ff 75 d0             	pushl  -0x30(%ebp)
f0101019:	57                   	push   %edi
f010101a:	e8 49 04 00 00       	call   f0101468 <strnlen>
f010101f:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101022:	29 c2                	sub    %eax,%edx
f0101024:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101027:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010102a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010102e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101031:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101034:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101036:	eb 10                	jmp    f0101048 <.L36+0x66>
					putch(padc, putdat);
f0101038:	83 ec 08             	sub    $0x8,%esp
f010103b:	56                   	push   %esi
f010103c:	ff 75 e0             	pushl  -0x20(%ebp)
f010103f:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101042:	83 ef 01             	sub    $0x1,%edi
f0101045:	83 c4 10             	add    $0x10,%esp
f0101048:	85 ff                	test   %edi,%edi
f010104a:	7f ec                	jg     f0101038 <.L36+0x56>
f010104c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010104f:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101052:	85 d2                	test   %edx,%edx
f0101054:	b8 00 00 00 00       	mov    $0x0,%eax
f0101059:	0f 49 c2             	cmovns %edx,%eax
f010105c:	29 c2                	sub    %eax,%edx
f010105e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101061:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101064:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101067:	eb 17                	jmp    f0101080 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101069:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010106d:	75 30                	jne    f010109f <.L36+0xbd>
					putch(ch, putdat);
f010106f:	83 ec 08             	sub    $0x8,%esp
f0101072:	ff 75 0c             	pushl  0xc(%ebp)
f0101075:	50                   	push   %eax
f0101076:	ff 55 08             	call   *0x8(%ebp)
f0101079:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010107c:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101080:	83 c7 01             	add    $0x1,%edi
f0101083:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101087:	0f be c2             	movsbl %dl,%eax
f010108a:	85 c0                	test   %eax,%eax
f010108c:	74 52                	je     f01010e0 <.L36+0xfe>
f010108e:	85 f6                	test   %esi,%esi
f0101090:	78 d7                	js     f0101069 <.L36+0x87>
f0101092:	83 ee 01             	sub    $0x1,%esi
f0101095:	79 d2                	jns    f0101069 <.L36+0x87>
f0101097:	8b 75 0c             	mov    0xc(%ebp),%esi
f010109a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010109d:	eb 32                	jmp    f01010d1 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010109f:	0f be d2             	movsbl %dl,%edx
f01010a2:	83 ea 20             	sub    $0x20,%edx
f01010a5:	83 fa 5e             	cmp    $0x5e,%edx
f01010a8:	76 c5                	jbe    f010106f <.L36+0x8d>
					putch('?', putdat);
f01010aa:	83 ec 08             	sub    $0x8,%esp
f01010ad:	ff 75 0c             	pushl  0xc(%ebp)
f01010b0:	6a 3f                	push   $0x3f
f01010b2:	ff 55 08             	call   *0x8(%ebp)
f01010b5:	83 c4 10             	add    $0x10,%esp
f01010b8:	eb c2                	jmp    f010107c <.L36+0x9a>
f01010ba:	89 75 0c             	mov    %esi,0xc(%ebp)
f01010bd:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010c0:	eb be                	jmp    f0101080 <.L36+0x9e>
				putch(' ', putdat);
f01010c2:	83 ec 08             	sub    $0x8,%esp
f01010c5:	56                   	push   %esi
f01010c6:	6a 20                	push   $0x20
f01010c8:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01010cb:	83 ef 01             	sub    $0x1,%edi
f01010ce:	83 c4 10             	add    $0x10,%esp
f01010d1:	85 ff                	test   %edi,%edi
f01010d3:	7f ed                	jg     f01010c2 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01010d5:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01010d8:	89 45 14             	mov    %eax,0x14(%ebp)
f01010db:	e9 46 01 00 00       	jmp    f0101226 <.L35+0x45>
f01010e0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01010e3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010e6:	eb e9                	jmp    f01010d1 <.L36+0xef>

f01010e8 <.L31>:
f01010e8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01010eb:	83 f9 01             	cmp    $0x1,%ecx
f01010ee:	7e 40                	jle    f0101130 <.L31+0x48>
		return va_arg(*ap, long long);
f01010f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f3:	8b 50 04             	mov    0x4(%eax),%edx
f01010f6:	8b 00                	mov    (%eax),%eax
f01010f8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010fb:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101101:	8d 40 08             	lea    0x8(%eax),%eax
f0101104:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101107:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010110b:	79 55                	jns    f0101162 <.L31+0x7a>
				putch('-', putdat);
f010110d:	83 ec 08             	sub    $0x8,%esp
f0101110:	56                   	push   %esi
f0101111:	6a 2d                	push   $0x2d
f0101113:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101116:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101119:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010111c:	f7 da                	neg    %edx
f010111e:	83 d1 00             	adc    $0x0,%ecx
f0101121:	f7 d9                	neg    %ecx
f0101123:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101126:	b8 0a 00 00 00       	mov    $0xa,%eax
f010112b:	e9 db 00 00 00       	jmp    f010120b <.L35+0x2a>
	else if (lflag)
f0101130:	85 c9                	test   %ecx,%ecx
f0101132:	75 17                	jne    f010114b <.L31+0x63>
		return va_arg(*ap, int);
f0101134:	8b 45 14             	mov    0x14(%ebp),%eax
f0101137:	8b 00                	mov    (%eax),%eax
f0101139:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010113c:	99                   	cltd   
f010113d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101140:	8b 45 14             	mov    0x14(%ebp),%eax
f0101143:	8d 40 04             	lea    0x4(%eax),%eax
f0101146:	89 45 14             	mov    %eax,0x14(%ebp)
f0101149:	eb bc                	jmp    f0101107 <.L31+0x1f>
		return va_arg(*ap, long);
f010114b:	8b 45 14             	mov    0x14(%ebp),%eax
f010114e:	8b 00                	mov    (%eax),%eax
f0101150:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101153:	99                   	cltd   
f0101154:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101157:	8b 45 14             	mov    0x14(%ebp),%eax
f010115a:	8d 40 04             	lea    0x4(%eax),%eax
f010115d:	89 45 14             	mov    %eax,0x14(%ebp)
f0101160:	eb a5                	jmp    f0101107 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101162:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101165:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101168:	b8 0a 00 00 00       	mov    $0xa,%eax
f010116d:	e9 99 00 00 00       	jmp    f010120b <.L35+0x2a>

f0101172 <.L37>:
f0101172:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101175:	83 f9 01             	cmp    $0x1,%ecx
f0101178:	7e 15                	jle    f010118f <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f010117a:	8b 45 14             	mov    0x14(%ebp),%eax
f010117d:	8b 10                	mov    (%eax),%edx
f010117f:	8b 48 04             	mov    0x4(%eax),%ecx
f0101182:	8d 40 08             	lea    0x8(%eax),%eax
f0101185:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101188:	b8 0a 00 00 00       	mov    $0xa,%eax
f010118d:	eb 7c                	jmp    f010120b <.L35+0x2a>
	else if (lflag)
f010118f:	85 c9                	test   %ecx,%ecx
f0101191:	75 17                	jne    f01011aa <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0101193:	8b 45 14             	mov    0x14(%ebp),%eax
f0101196:	8b 10                	mov    (%eax),%edx
f0101198:	b9 00 00 00 00       	mov    $0x0,%ecx
f010119d:	8d 40 04             	lea    0x4(%eax),%eax
f01011a0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011a3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011a8:	eb 61                	jmp    f010120b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01011aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ad:	8b 10                	mov    (%eax),%edx
f01011af:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011b4:	8d 40 04             	lea    0x4(%eax),%eax
f01011b7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011ba:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011bf:	eb 4a                	jmp    f010120b <.L35+0x2a>

f01011c1 <.L34>:
			putch('X', putdat);
f01011c1:	83 ec 08             	sub    $0x8,%esp
f01011c4:	56                   	push   %esi
f01011c5:	6a 58                	push   $0x58
f01011c7:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01011ca:	83 c4 08             	add    $0x8,%esp
f01011cd:	56                   	push   %esi
f01011ce:	6a 58                	push   $0x58
f01011d0:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01011d3:	83 c4 08             	add    $0x8,%esp
f01011d6:	56                   	push   %esi
f01011d7:	6a 58                	push   $0x58
f01011d9:	ff 55 08             	call   *0x8(%ebp)
			break;
f01011dc:	83 c4 10             	add    $0x10,%esp
f01011df:	eb 45                	jmp    f0101226 <.L35+0x45>

f01011e1 <.L35>:
			putch('0', putdat);
f01011e1:	83 ec 08             	sub    $0x8,%esp
f01011e4:	56                   	push   %esi
f01011e5:	6a 30                	push   $0x30
f01011e7:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011ea:	83 c4 08             	add    $0x8,%esp
f01011ed:	56                   	push   %esi
f01011ee:	6a 78                	push   $0x78
f01011f0:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01011f3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f6:	8b 10                	mov    (%eax),%edx
f01011f8:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f01011fd:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101200:	8d 40 04             	lea    0x4(%eax),%eax
f0101203:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101206:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010120b:	83 ec 0c             	sub    $0xc,%esp
f010120e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101212:	57                   	push   %edi
f0101213:	ff 75 e0             	pushl  -0x20(%ebp)
f0101216:	50                   	push   %eax
f0101217:	51                   	push   %ecx
f0101218:	52                   	push   %edx
f0101219:	89 f2                	mov    %esi,%edx
f010121b:	8b 45 08             	mov    0x8(%ebp),%eax
f010121e:	e8 55 fb ff ff       	call   f0100d78 <printnum>
			break;
f0101223:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101226:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101229:	83 c7 01             	add    $0x1,%edi
f010122c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101230:	83 f8 25             	cmp    $0x25,%eax
f0101233:	0f 84 62 fc ff ff    	je     f0100e9b <vprintfmt+0x1f>
			if (ch == '\0')
f0101239:	85 c0                	test   %eax,%eax
f010123b:	0f 84 91 00 00 00    	je     f01012d2 <.L22+0x21>
			putch(ch, putdat);
f0101241:	83 ec 08             	sub    $0x8,%esp
f0101244:	56                   	push   %esi
f0101245:	50                   	push   %eax
f0101246:	ff 55 08             	call   *0x8(%ebp)
f0101249:	83 c4 10             	add    $0x10,%esp
f010124c:	eb db                	jmp    f0101229 <.L35+0x48>

f010124e <.L38>:
f010124e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101251:	83 f9 01             	cmp    $0x1,%ecx
f0101254:	7e 15                	jle    f010126b <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0101256:	8b 45 14             	mov    0x14(%ebp),%eax
f0101259:	8b 10                	mov    (%eax),%edx
f010125b:	8b 48 04             	mov    0x4(%eax),%ecx
f010125e:	8d 40 08             	lea    0x8(%eax),%eax
f0101261:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101264:	b8 10 00 00 00       	mov    $0x10,%eax
f0101269:	eb a0                	jmp    f010120b <.L35+0x2a>
	else if (lflag)
f010126b:	85 c9                	test   %ecx,%ecx
f010126d:	75 17                	jne    f0101286 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f010126f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101272:	8b 10                	mov    (%eax),%edx
f0101274:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101279:	8d 40 04             	lea    0x4(%eax),%eax
f010127c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010127f:	b8 10 00 00 00       	mov    $0x10,%eax
f0101284:	eb 85                	jmp    f010120b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101286:	8b 45 14             	mov    0x14(%ebp),%eax
f0101289:	8b 10                	mov    (%eax),%edx
f010128b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101290:	8d 40 04             	lea    0x4(%eax),%eax
f0101293:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101296:	b8 10 00 00 00       	mov    $0x10,%eax
f010129b:	e9 6b ff ff ff       	jmp    f010120b <.L35+0x2a>

f01012a0 <.L25>:
			putch(ch, putdat);
f01012a0:	83 ec 08             	sub    $0x8,%esp
f01012a3:	56                   	push   %esi
f01012a4:	6a 25                	push   $0x25
f01012a6:	ff 55 08             	call   *0x8(%ebp)
			break;
f01012a9:	83 c4 10             	add    $0x10,%esp
f01012ac:	e9 75 ff ff ff       	jmp    f0101226 <.L35+0x45>

f01012b1 <.L22>:
			putch('%', putdat);
f01012b1:	83 ec 08             	sub    $0x8,%esp
f01012b4:	56                   	push   %esi
f01012b5:	6a 25                	push   $0x25
f01012b7:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012ba:	83 c4 10             	add    $0x10,%esp
f01012bd:	89 f8                	mov    %edi,%eax
f01012bf:	eb 03                	jmp    f01012c4 <.L22+0x13>
f01012c1:	83 e8 01             	sub    $0x1,%eax
f01012c4:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01012c8:	75 f7                	jne    f01012c1 <.L22+0x10>
f01012ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012cd:	e9 54 ff ff ff       	jmp    f0101226 <.L35+0x45>
}
f01012d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012d5:	5b                   	pop    %ebx
f01012d6:	5e                   	pop    %esi
f01012d7:	5f                   	pop    %edi
f01012d8:	5d                   	pop    %ebp
f01012d9:	c3                   	ret    

f01012da <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012da:	55                   	push   %ebp
f01012db:	89 e5                	mov    %esp,%ebp
f01012dd:	53                   	push   %ebx
f01012de:	83 ec 14             	sub    $0x14,%esp
f01012e1:	e8 f5 ee ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f01012e6:	81 c3 22 00 01 00    	add    $0x10022,%ebx
f01012ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ef:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012f2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012f5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012f9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012fc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101303:	85 c0                	test   %eax,%eax
f0101305:	74 2b                	je     f0101332 <vsnprintf+0x58>
f0101307:	85 d2                	test   %edx,%edx
f0101309:	7e 27                	jle    f0101332 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010130b:	ff 75 14             	pushl  0x14(%ebp)
f010130e:	ff 75 10             	pushl  0x10(%ebp)
f0101311:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101314:	50                   	push   %eax
f0101315:	8d 83 3a fb fe ff    	lea    -0x104c6(%ebx),%eax
f010131b:	50                   	push   %eax
f010131c:	e8 5b fb ff ff       	call   f0100e7c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101321:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101324:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101327:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010132a:	83 c4 10             	add    $0x10,%esp
}
f010132d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101330:	c9                   	leave  
f0101331:	c3                   	ret    
		return -E_INVAL;
f0101332:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101337:	eb f4                	jmp    f010132d <vsnprintf+0x53>

f0101339 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101339:	55                   	push   %ebp
f010133a:	89 e5                	mov    %esp,%ebp
f010133c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010133f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101342:	50                   	push   %eax
f0101343:	ff 75 10             	pushl  0x10(%ebp)
f0101346:	ff 75 0c             	pushl  0xc(%ebp)
f0101349:	ff 75 08             	pushl  0x8(%ebp)
f010134c:	e8 89 ff ff ff       	call   f01012da <vsnprintf>
	va_end(ap);

	return rc;
}
f0101351:	c9                   	leave  
f0101352:	c3                   	ret    

f0101353 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101353:	55                   	push   %ebp
f0101354:	89 e5                	mov    %esp,%ebp
f0101356:	57                   	push   %edi
f0101357:	56                   	push   %esi
f0101358:	53                   	push   %ebx
f0101359:	83 ec 1c             	sub    $0x1c,%esp
f010135c:	e8 7a ee ff ff       	call   f01001db <__x86.get_pc_thunk.bx>
f0101361:	81 c3 a7 ff 00 00    	add    $0xffa7,%ebx
f0101367:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010136a:	85 c0                	test   %eax,%eax
f010136c:	74 13                	je     f0101381 <readline+0x2e>
		cprintf("%s", prompt);
f010136e:	83 ec 08             	sub    $0x8,%esp
f0101371:	50                   	push   %eax
f0101372:	8d 83 70 07 ff ff    	lea    -0xf890(%ebx),%eax
f0101378:	50                   	push   %eax
f0101379:	e8 ea f6 ff ff       	call   f0100a68 <cprintf>
f010137e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101381:	83 ec 0c             	sub    $0xc,%esp
f0101384:	6a 00                	push   $0x0
f0101386:	e8 e8 f3 ff ff       	call   f0100773 <iscons>
f010138b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010138e:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101391:	bf 00 00 00 00       	mov    $0x0,%edi
f0101396:	eb 46                	jmp    f01013de <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101398:	83 ec 08             	sub    $0x8,%esp
f010139b:	50                   	push   %eax
f010139c:	8d 83 c4 0d ff ff    	lea    -0xf23c(%ebx),%eax
f01013a2:	50                   	push   %eax
f01013a3:	e8 c0 f6 ff ff       	call   f0100a68 <cprintf>
			return NULL;
f01013a8:	83 c4 10             	add    $0x10,%esp
f01013ab:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01013b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013b3:	5b                   	pop    %ebx
f01013b4:	5e                   	pop    %esi
f01013b5:	5f                   	pop    %edi
f01013b6:	5d                   	pop    %ebp
f01013b7:	c3                   	ret    
			if (echoing)
f01013b8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013bc:	75 05                	jne    f01013c3 <readline+0x70>
			i--;
f01013be:	83 ef 01             	sub    $0x1,%edi
f01013c1:	eb 1b                	jmp    f01013de <readline+0x8b>
				cputchar('\b');
f01013c3:	83 ec 0c             	sub    $0xc,%esp
f01013c6:	6a 08                	push   $0x8
f01013c8:	e8 85 f3 ff ff       	call   f0100752 <cputchar>
f01013cd:	83 c4 10             	add    $0x10,%esp
f01013d0:	eb ec                	jmp    f01013be <readline+0x6b>
			buf[i++] = c;
f01013d2:	89 f0                	mov    %esi,%eax
f01013d4:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f01013db:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01013de:	e8 7f f3 ff ff       	call   f0100762 <getchar>
f01013e3:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01013e5:	85 c0                	test   %eax,%eax
f01013e7:	78 af                	js     f0101398 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013e9:	83 f8 08             	cmp    $0x8,%eax
f01013ec:	0f 94 c2             	sete   %dl
f01013ef:	83 f8 7f             	cmp    $0x7f,%eax
f01013f2:	0f 94 c0             	sete   %al
f01013f5:	08 c2                	or     %al,%dl
f01013f7:	74 04                	je     f01013fd <readline+0xaa>
f01013f9:	85 ff                	test   %edi,%edi
f01013fb:	7f bb                	jg     f01013b8 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013fd:	83 fe 1f             	cmp    $0x1f,%esi
f0101400:	7e 1c                	jle    f010141e <readline+0xcb>
f0101402:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101408:	7f 14                	jg     f010141e <readline+0xcb>
			if (echoing)
f010140a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010140e:	74 c2                	je     f01013d2 <readline+0x7f>
				cputchar(c);
f0101410:	83 ec 0c             	sub    $0xc,%esp
f0101413:	56                   	push   %esi
f0101414:	e8 39 f3 ff ff       	call   f0100752 <cputchar>
f0101419:	83 c4 10             	add    $0x10,%esp
f010141c:	eb b4                	jmp    f01013d2 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f010141e:	83 fe 0a             	cmp    $0xa,%esi
f0101421:	74 05                	je     f0101428 <readline+0xd5>
f0101423:	83 fe 0d             	cmp    $0xd,%esi
f0101426:	75 b6                	jne    f01013de <readline+0x8b>
			if (echoing)
f0101428:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010142c:	75 13                	jne    f0101441 <readline+0xee>
			buf[i] = 0;
f010142e:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f0101435:	00 
			return buf;
f0101436:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f010143c:	e9 6f ff ff ff       	jmp    f01013b0 <readline+0x5d>
				cputchar('\n');
f0101441:	83 ec 0c             	sub    $0xc,%esp
f0101444:	6a 0a                	push   $0xa
f0101446:	e8 07 f3 ff ff       	call   f0100752 <cputchar>
f010144b:	83 c4 10             	add    $0x10,%esp
f010144e:	eb de                	jmp    f010142e <readline+0xdb>

f0101450 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101450:	55                   	push   %ebp
f0101451:	89 e5                	mov    %esp,%ebp
f0101453:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101456:	b8 00 00 00 00       	mov    $0x0,%eax
f010145b:	eb 03                	jmp    f0101460 <strlen+0x10>
		n++;
f010145d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101460:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101464:	75 f7                	jne    f010145d <strlen+0xd>
	return n;
}
f0101466:	5d                   	pop    %ebp
f0101467:	c3                   	ret    

f0101468 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101468:	55                   	push   %ebp
f0101469:	89 e5                	mov    %esp,%ebp
f010146b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010146e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101471:	b8 00 00 00 00       	mov    $0x0,%eax
f0101476:	eb 03                	jmp    f010147b <strnlen+0x13>
		n++;
f0101478:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010147b:	39 d0                	cmp    %edx,%eax
f010147d:	74 06                	je     f0101485 <strnlen+0x1d>
f010147f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101483:	75 f3                	jne    f0101478 <strnlen+0x10>
	return n;
}
f0101485:	5d                   	pop    %ebp
f0101486:	c3                   	ret    

f0101487 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101487:	55                   	push   %ebp
f0101488:	89 e5                	mov    %esp,%ebp
f010148a:	53                   	push   %ebx
f010148b:	8b 45 08             	mov    0x8(%ebp),%eax
f010148e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101491:	89 c2                	mov    %eax,%edx
f0101493:	83 c1 01             	add    $0x1,%ecx
f0101496:	83 c2 01             	add    $0x1,%edx
f0101499:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010149d:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014a0:	84 db                	test   %bl,%bl
f01014a2:	75 ef                	jne    f0101493 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014a4:	5b                   	pop    %ebx
f01014a5:	5d                   	pop    %ebp
f01014a6:	c3                   	ret    

f01014a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014a7:	55                   	push   %ebp
f01014a8:	89 e5                	mov    %esp,%ebp
f01014aa:	53                   	push   %ebx
f01014ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014ae:	53                   	push   %ebx
f01014af:	e8 9c ff ff ff       	call   f0101450 <strlen>
f01014b4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01014b7:	ff 75 0c             	pushl  0xc(%ebp)
f01014ba:	01 d8                	add    %ebx,%eax
f01014bc:	50                   	push   %eax
f01014bd:	e8 c5 ff ff ff       	call   f0101487 <strcpy>
	return dst;
}
f01014c2:	89 d8                	mov    %ebx,%eax
f01014c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014c7:	c9                   	leave  
f01014c8:	c3                   	ret    

f01014c9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014c9:	55                   	push   %ebp
f01014ca:	89 e5                	mov    %esp,%ebp
f01014cc:	56                   	push   %esi
f01014cd:	53                   	push   %ebx
f01014ce:	8b 75 08             	mov    0x8(%ebp),%esi
f01014d1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014d4:	89 f3                	mov    %esi,%ebx
f01014d6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014d9:	89 f2                	mov    %esi,%edx
f01014db:	eb 0f                	jmp    f01014ec <strncpy+0x23>
		*dst++ = *src;
f01014dd:	83 c2 01             	add    $0x1,%edx
f01014e0:	0f b6 01             	movzbl (%ecx),%eax
f01014e3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014e6:	80 39 01             	cmpb   $0x1,(%ecx)
f01014e9:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01014ec:	39 da                	cmp    %ebx,%edx
f01014ee:	75 ed                	jne    f01014dd <strncpy+0x14>
	}
	return ret;
}
f01014f0:	89 f0                	mov    %esi,%eax
f01014f2:	5b                   	pop    %ebx
f01014f3:	5e                   	pop    %esi
f01014f4:	5d                   	pop    %ebp
f01014f5:	c3                   	ret    

f01014f6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014f6:	55                   	push   %ebp
f01014f7:	89 e5                	mov    %esp,%ebp
f01014f9:	56                   	push   %esi
f01014fa:	53                   	push   %ebx
f01014fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01014fe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101501:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101504:	89 f0                	mov    %esi,%eax
f0101506:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010150a:	85 c9                	test   %ecx,%ecx
f010150c:	75 0b                	jne    f0101519 <strlcpy+0x23>
f010150e:	eb 17                	jmp    f0101527 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101510:	83 c2 01             	add    $0x1,%edx
f0101513:	83 c0 01             	add    $0x1,%eax
f0101516:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101519:	39 d8                	cmp    %ebx,%eax
f010151b:	74 07                	je     f0101524 <strlcpy+0x2e>
f010151d:	0f b6 0a             	movzbl (%edx),%ecx
f0101520:	84 c9                	test   %cl,%cl
f0101522:	75 ec                	jne    f0101510 <strlcpy+0x1a>
		*dst = '\0';
f0101524:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101527:	29 f0                	sub    %esi,%eax
}
f0101529:	5b                   	pop    %ebx
f010152a:	5e                   	pop    %esi
f010152b:	5d                   	pop    %ebp
f010152c:	c3                   	ret    

f010152d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010152d:	55                   	push   %ebp
f010152e:	89 e5                	mov    %esp,%ebp
f0101530:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101533:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101536:	eb 06                	jmp    f010153e <strcmp+0x11>
		p++, q++;
f0101538:	83 c1 01             	add    $0x1,%ecx
f010153b:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010153e:	0f b6 01             	movzbl (%ecx),%eax
f0101541:	84 c0                	test   %al,%al
f0101543:	74 04                	je     f0101549 <strcmp+0x1c>
f0101545:	3a 02                	cmp    (%edx),%al
f0101547:	74 ef                	je     f0101538 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101549:	0f b6 c0             	movzbl %al,%eax
f010154c:	0f b6 12             	movzbl (%edx),%edx
f010154f:	29 d0                	sub    %edx,%eax
}
f0101551:	5d                   	pop    %ebp
f0101552:	c3                   	ret    

f0101553 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101553:	55                   	push   %ebp
f0101554:	89 e5                	mov    %esp,%ebp
f0101556:	53                   	push   %ebx
f0101557:	8b 45 08             	mov    0x8(%ebp),%eax
f010155a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010155d:	89 c3                	mov    %eax,%ebx
f010155f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101562:	eb 06                	jmp    f010156a <strncmp+0x17>
		n--, p++, q++;
f0101564:	83 c0 01             	add    $0x1,%eax
f0101567:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010156a:	39 d8                	cmp    %ebx,%eax
f010156c:	74 16                	je     f0101584 <strncmp+0x31>
f010156e:	0f b6 08             	movzbl (%eax),%ecx
f0101571:	84 c9                	test   %cl,%cl
f0101573:	74 04                	je     f0101579 <strncmp+0x26>
f0101575:	3a 0a                	cmp    (%edx),%cl
f0101577:	74 eb                	je     f0101564 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101579:	0f b6 00             	movzbl (%eax),%eax
f010157c:	0f b6 12             	movzbl (%edx),%edx
f010157f:	29 d0                	sub    %edx,%eax
}
f0101581:	5b                   	pop    %ebx
f0101582:	5d                   	pop    %ebp
f0101583:	c3                   	ret    
		return 0;
f0101584:	b8 00 00 00 00       	mov    $0x0,%eax
f0101589:	eb f6                	jmp    f0101581 <strncmp+0x2e>

f010158b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010158b:	55                   	push   %ebp
f010158c:	89 e5                	mov    %esp,%ebp
f010158e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101591:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101595:	0f b6 10             	movzbl (%eax),%edx
f0101598:	84 d2                	test   %dl,%dl
f010159a:	74 09                	je     f01015a5 <strchr+0x1a>
		if (*s == c)
f010159c:	38 ca                	cmp    %cl,%dl
f010159e:	74 0a                	je     f01015aa <strchr+0x1f>
	for (; *s; s++)
f01015a0:	83 c0 01             	add    $0x1,%eax
f01015a3:	eb f0                	jmp    f0101595 <strchr+0xa>
			return (char *) s;
	return 0;
f01015a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015aa:	5d                   	pop    %ebp
f01015ab:	c3                   	ret    

f01015ac <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015ac:	55                   	push   %ebp
f01015ad:	89 e5                	mov    %esp,%ebp
f01015af:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015b6:	eb 03                	jmp    f01015bb <strfind+0xf>
f01015b8:	83 c0 01             	add    $0x1,%eax
f01015bb:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01015be:	38 ca                	cmp    %cl,%dl
f01015c0:	74 04                	je     f01015c6 <strfind+0x1a>
f01015c2:	84 d2                	test   %dl,%dl
f01015c4:	75 f2                	jne    f01015b8 <strfind+0xc>
			break;
	return (char *) s;
}
f01015c6:	5d                   	pop    %ebp
f01015c7:	c3                   	ret    

f01015c8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015c8:	55                   	push   %ebp
f01015c9:	89 e5                	mov    %esp,%ebp
f01015cb:	57                   	push   %edi
f01015cc:	56                   	push   %esi
f01015cd:	53                   	push   %ebx
f01015ce:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015d1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015d4:	85 c9                	test   %ecx,%ecx
f01015d6:	74 13                	je     f01015eb <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015d8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015de:	75 05                	jne    f01015e5 <memset+0x1d>
f01015e0:	f6 c1 03             	test   $0x3,%cl
f01015e3:	74 0d                	je     f01015f2 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015e8:	fc                   	cld    
f01015e9:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015eb:	89 f8                	mov    %edi,%eax
f01015ed:	5b                   	pop    %ebx
f01015ee:	5e                   	pop    %esi
f01015ef:	5f                   	pop    %edi
f01015f0:	5d                   	pop    %ebp
f01015f1:	c3                   	ret    
		c &= 0xFF;
f01015f2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015f6:	89 d3                	mov    %edx,%ebx
f01015f8:	c1 e3 08             	shl    $0x8,%ebx
f01015fb:	89 d0                	mov    %edx,%eax
f01015fd:	c1 e0 18             	shl    $0x18,%eax
f0101600:	89 d6                	mov    %edx,%esi
f0101602:	c1 e6 10             	shl    $0x10,%esi
f0101605:	09 f0                	or     %esi,%eax
f0101607:	09 c2                	or     %eax,%edx
f0101609:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f010160b:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010160e:	89 d0                	mov    %edx,%eax
f0101610:	fc                   	cld    
f0101611:	f3 ab                	rep stos %eax,%es:(%edi)
f0101613:	eb d6                	jmp    f01015eb <memset+0x23>

f0101615 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101615:	55                   	push   %ebp
f0101616:	89 e5                	mov    %esp,%ebp
f0101618:	57                   	push   %edi
f0101619:	56                   	push   %esi
f010161a:	8b 45 08             	mov    0x8(%ebp),%eax
f010161d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101620:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101623:	39 c6                	cmp    %eax,%esi
f0101625:	73 35                	jae    f010165c <memmove+0x47>
f0101627:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010162a:	39 c2                	cmp    %eax,%edx
f010162c:	76 2e                	jbe    f010165c <memmove+0x47>
		s += n;
		d += n;
f010162e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101631:	89 d6                	mov    %edx,%esi
f0101633:	09 fe                	or     %edi,%esi
f0101635:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010163b:	74 0c                	je     f0101649 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010163d:	83 ef 01             	sub    $0x1,%edi
f0101640:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101643:	fd                   	std    
f0101644:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101646:	fc                   	cld    
f0101647:	eb 21                	jmp    f010166a <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101649:	f6 c1 03             	test   $0x3,%cl
f010164c:	75 ef                	jne    f010163d <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010164e:	83 ef 04             	sub    $0x4,%edi
f0101651:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101654:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101657:	fd                   	std    
f0101658:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010165a:	eb ea                	jmp    f0101646 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010165c:	89 f2                	mov    %esi,%edx
f010165e:	09 c2                	or     %eax,%edx
f0101660:	f6 c2 03             	test   $0x3,%dl
f0101663:	74 09                	je     f010166e <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101665:	89 c7                	mov    %eax,%edi
f0101667:	fc                   	cld    
f0101668:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010166a:	5e                   	pop    %esi
f010166b:	5f                   	pop    %edi
f010166c:	5d                   	pop    %ebp
f010166d:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010166e:	f6 c1 03             	test   $0x3,%cl
f0101671:	75 f2                	jne    f0101665 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101673:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101676:	89 c7                	mov    %eax,%edi
f0101678:	fc                   	cld    
f0101679:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010167b:	eb ed                	jmp    f010166a <memmove+0x55>

f010167d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010167d:	55                   	push   %ebp
f010167e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101680:	ff 75 10             	pushl  0x10(%ebp)
f0101683:	ff 75 0c             	pushl  0xc(%ebp)
f0101686:	ff 75 08             	pushl  0x8(%ebp)
f0101689:	e8 87 ff ff ff       	call   f0101615 <memmove>
}
f010168e:	c9                   	leave  
f010168f:	c3                   	ret    

f0101690 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101690:	55                   	push   %ebp
f0101691:	89 e5                	mov    %esp,%ebp
f0101693:	56                   	push   %esi
f0101694:	53                   	push   %ebx
f0101695:	8b 45 08             	mov    0x8(%ebp),%eax
f0101698:	8b 55 0c             	mov    0xc(%ebp),%edx
f010169b:	89 c6                	mov    %eax,%esi
f010169d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016a0:	39 f0                	cmp    %esi,%eax
f01016a2:	74 1c                	je     f01016c0 <memcmp+0x30>
		if (*s1 != *s2)
f01016a4:	0f b6 08             	movzbl (%eax),%ecx
f01016a7:	0f b6 1a             	movzbl (%edx),%ebx
f01016aa:	38 d9                	cmp    %bl,%cl
f01016ac:	75 08                	jne    f01016b6 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01016ae:	83 c0 01             	add    $0x1,%eax
f01016b1:	83 c2 01             	add    $0x1,%edx
f01016b4:	eb ea                	jmp    f01016a0 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01016b6:	0f b6 c1             	movzbl %cl,%eax
f01016b9:	0f b6 db             	movzbl %bl,%ebx
f01016bc:	29 d8                	sub    %ebx,%eax
f01016be:	eb 05                	jmp    f01016c5 <memcmp+0x35>
	}

	return 0;
f01016c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016c5:	5b                   	pop    %ebx
f01016c6:	5e                   	pop    %esi
f01016c7:	5d                   	pop    %ebp
f01016c8:	c3                   	ret    

f01016c9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016c9:	55                   	push   %ebp
f01016ca:	89 e5                	mov    %esp,%ebp
f01016cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01016cf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016d2:	89 c2                	mov    %eax,%edx
f01016d4:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016d7:	39 d0                	cmp    %edx,%eax
f01016d9:	73 09                	jae    f01016e4 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016db:	38 08                	cmp    %cl,(%eax)
f01016dd:	74 05                	je     f01016e4 <memfind+0x1b>
	for (; s < ends; s++)
f01016df:	83 c0 01             	add    $0x1,%eax
f01016e2:	eb f3                	jmp    f01016d7 <memfind+0xe>
			break;
	return (void *) s;
}
f01016e4:	5d                   	pop    %ebp
f01016e5:	c3                   	ret    

f01016e6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016e6:	55                   	push   %ebp
f01016e7:	89 e5                	mov    %esp,%ebp
f01016e9:	57                   	push   %edi
f01016ea:	56                   	push   %esi
f01016eb:	53                   	push   %ebx
f01016ec:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01016ef:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016f2:	eb 03                	jmp    f01016f7 <strtol+0x11>
		s++;
f01016f4:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01016f7:	0f b6 01             	movzbl (%ecx),%eax
f01016fa:	3c 20                	cmp    $0x20,%al
f01016fc:	74 f6                	je     f01016f4 <strtol+0xe>
f01016fe:	3c 09                	cmp    $0x9,%al
f0101700:	74 f2                	je     f01016f4 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101702:	3c 2b                	cmp    $0x2b,%al
f0101704:	74 2e                	je     f0101734 <strtol+0x4e>
	int neg = 0;
f0101706:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010170b:	3c 2d                	cmp    $0x2d,%al
f010170d:	74 2f                	je     f010173e <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010170f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101715:	75 05                	jne    f010171c <strtol+0x36>
f0101717:	80 39 30             	cmpb   $0x30,(%ecx)
f010171a:	74 2c                	je     f0101748 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010171c:	85 db                	test   %ebx,%ebx
f010171e:	75 0a                	jne    f010172a <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101720:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101725:	80 39 30             	cmpb   $0x30,(%ecx)
f0101728:	74 28                	je     f0101752 <strtol+0x6c>
		base = 10;
f010172a:	b8 00 00 00 00       	mov    $0x0,%eax
f010172f:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101732:	eb 50                	jmp    f0101784 <strtol+0x9e>
		s++;
f0101734:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101737:	bf 00 00 00 00       	mov    $0x0,%edi
f010173c:	eb d1                	jmp    f010170f <strtol+0x29>
		s++, neg = 1;
f010173e:	83 c1 01             	add    $0x1,%ecx
f0101741:	bf 01 00 00 00       	mov    $0x1,%edi
f0101746:	eb c7                	jmp    f010170f <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101748:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010174c:	74 0e                	je     f010175c <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010174e:	85 db                	test   %ebx,%ebx
f0101750:	75 d8                	jne    f010172a <strtol+0x44>
		s++, base = 8;
f0101752:	83 c1 01             	add    $0x1,%ecx
f0101755:	bb 08 00 00 00       	mov    $0x8,%ebx
f010175a:	eb ce                	jmp    f010172a <strtol+0x44>
		s += 2, base = 16;
f010175c:	83 c1 02             	add    $0x2,%ecx
f010175f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101764:	eb c4                	jmp    f010172a <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101766:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101769:	89 f3                	mov    %esi,%ebx
f010176b:	80 fb 19             	cmp    $0x19,%bl
f010176e:	77 29                	ja     f0101799 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101770:	0f be d2             	movsbl %dl,%edx
f0101773:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101776:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101779:	7d 30                	jge    f01017ab <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010177b:	83 c1 01             	add    $0x1,%ecx
f010177e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101782:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101784:	0f b6 11             	movzbl (%ecx),%edx
f0101787:	8d 72 d0             	lea    -0x30(%edx),%esi
f010178a:	89 f3                	mov    %esi,%ebx
f010178c:	80 fb 09             	cmp    $0x9,%bl
f010178f:	77 d5                	ja     f0101766 <strtol+0x80>
			dig = *s - '0';
f0101791:	0f be d2             	movsbl %dl,%edx
f0101794:	83 ea 30             	sub    $0x30,%edx
f0101797:	eb dd                	jmp    f0101776 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101799:	8d 72 bf             	lea    -0x41(%edx),%esi
f010179c:	89 f3                	mov    %esi,%ebx
f010179e:	80 fb 19             	cmp    $0x19,%bl
f01017a1:	77 08                	ja     f01017ab <strtol+0xc5>
			dig = *s - 'A' + 10;
f01017a3:	0f be d2             	movsbl %dl,%edx
f01017a6:	83 ea 37             	sub    $0x37,%edx
f01017a9:	eb cb                	jmp    f0101776 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01017ab:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017af:	74 05                	je     f01017b6 <strtol+0xd0>
		*endptr = (char *) s;
f01017b1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017b4:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01017b6:	89 c2                	mov    %eax,%edx
f01017b8:	f7 da                	neg    %edx
f01017ba:	85 ff                	test   %edi,%edi
f01017bc:	0f 45 c2             	cmovne %edx,%eax
}
f01017bf:	5b                   	pop    %ebx
f01017c0:	5e                   	pop    %esi
f01017c1:	5f                   	pop    %edi
f01017c2:	5d                   	pop    %ebp
f01017c3:	c3                   	ret    
f01017c4:	66 90                	xchg   %ax,%ax
f01017c6:	66 90                	xchg   %ax,%ax
f01017c8:	66 90                	xchg   %ax,%ax
f01017ca:	66 90                	xchg   %ax,%ax
f01017cc:	66 90                	xchg   %ax,%ax
f01017ce:	66 90                	xchg   %ax,%ax

f01017d0 <__udivdi3>:
f01017d0:	55                   	push   %ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	53                   	push   %ebx
f01017d4:	83 ec 1c             	sub    $0x1c,%esp
f01017d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017db:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01017df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017e3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01017e7:	85 d2                	test   %edx,%edx
f01017e9:	75 35                	jne    f0101820 <__udivdi3+0x50>
f01017eb:	39 f3                	cmp    %esi,%ebx
f01017ed:	0f 87 bd 00 00 00    	ja     f01018b0 <__udivdi3+0xe0>
f01017f3:	85 db                	test   %ebx,%ebx
f01017f5:	89 d9                	mov    %ebx,%ecx
f01017f7:	75 0b                	jne    f0101804 <__udivdi3+0x34>
f01017f9:	b8 01 00 00 00       	mov    $0x1,%eax
f01017fe:	31 d2                	xor    %edx,%edx
f0101800:	f7 f3                	div    %ebx
f0101802:	89 c1                	mov    %eax,%ecx
f0101804:	31 d2                	xor    %edx,%edx
f0101806:	89 f0                	mov    %esi,%eax
f0101808:	f7 f1                	div    %ecx
f010180a:	89 c6                	mov    %eax,%esi
f010180c:	89 e8                	mov    %ebp,%eax
f010180e:	89 f7                	mov    %esi,%edi
f0101810:	f7 f1                	div    %ecx
f0101812:	89 fa                	mov    %edi,%edx
f0101814:	83 c4 1c             	add    $0x1c,%esp
f0101817:	5b                   	pop    %ebx
f0101818:	5e                   	pop    %esi
f0101819:	5f                   	pop    %edi
f010181a:	5d                   	pop    %ebp
f010181b:	c3                   	ret    
f010181c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101820:	39 f2                	cmp    %esi,%edx
f0101822:	77 7c                	ja     f01018a0 <__udivdi3+0xd0>
f0101824:	0f bd fa             	bsr    %edx,%edi
f0101827:	83 f7 1f             	xor    $0x1f,%edi
f010182a:	0f 84 98 00 00 00    	je     f01018c8 <__udivdi3+0xf8>
f0101830:	89 f9                	mov    %edi,%ecx
f0101832:	b8 20 00 00 00       	mov    $0x20,%eax
f0101837:	29 f8                	sub    %edi,%eax
f0101839:	d3 e2                	shl    %cl,%edx
f010183b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010183f:	89 c1                	mov    %eax,%ecx
f0101841:	89 da                	mov    %ebx,%edx
f0101843:	d3 ea                	shr    %cl,%edx
f0101845:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101849:	09 d1                	or     %edx,%ecx
f010184b:	89 f2                	mov    %esi,%edx
f010184d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101851:	89 f9                	mov    %edi,%ecx
f0101853:	d3 e3                	shl    %cl,%ebx
f0101855:	89 c1                	mov    %eax,%ecx
f0101857:	d3 ea                	shr    %cl,%edx
f0101859:	89 f9                	mov    %edi,%ecx
f010185b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010185f:	d3 e6                	shl    %cl,%esi
f0101861:	89 eb                	mov    %ebp,%ebx
f0101863:	89 c1                	mov    %eax,%ecx
f0101865:	d3 eb                	shr    %cl,%ebx
f0101867:	09 de                	or     %ebx,%esi
f0101869:	89 f0                	mov    %esi,%eax
f010186b:	f7 74 24 08          	divl   0x8(%esp)
f010186f:	89 d6                	mov    %edx,%esi
f0101871:	89 c3                	mov    %eax,%ebx
f0101873:	f7 64 24 0c          	mull   0xc(%esp)
f0101877:	39 d6                	cmp    %edx,%esi
f0101879:	72 0c                	jb     f0101887 <__udivdi3+0xb7>
f010187b:	89 f9                	mov    %edi,%ecx
f010187d:	d3 e5                	shl    %cl,%ebp
f010187f:	39 c5                	cmp    %eax,%ebp
f0101881:	73 5d                	jae    f01018e0 <__udivdi3+0x110>
f0101883:	39 d6                	cmp    %edx,%esi
f0101885:	75 59                	jne    f01018e0 <__udivdi3+0x110>
f0101887:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010188a:	31 ff                	xor    %edi,%edi
f010188c:	89 fa                	mov    %edi,%edx
f010188e:	83 c4 1c             	add    $0x1c,%esp
f0101891:	5b                   	pop    %ebx
f0101892:	5e                   	pop    %esi
f0101893:	5f                   	pop    %edi
f0101894:	5d                   	pop    %ebp
f0101895:	c3                   	ret    
f0101896:	8d 76 00             	lea    0x0(%esi),%esi
f0101899:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01018a0:	31 ff                	xor    %edi,%edi
f01018a2:	31 c0                	xor    %eax,%eax
f01018a4:	89 fa                	mov    %edi,%edx
f01018a6:	83 c4 1c             	add    $0x1c,%esp
f01018a9:	5b                   	pop    %ebx
f01018aa:	5e                   	pop    %esi
f01018ab:	5f                   	pop    %edi
f01018ac:	5d                   	pop    %ebp
f01018ad:	c3                   	ret    
f01018ae:	66 90                	xchg   %ax,%ax
f01018b0:	31 ff                	xor    %edi,%edi
f01018b2:	89 e8                	mov    %ebp,%eax
f01018b4:	89 f2                	mov    %esi,%edx
f01018b6:	f7 f3                	div    %ebx
f01018b8:	89 fa                	mov    %edi,%edx
f01018ba:	83 c4 1c             	add    $0x1c,%esp
f01018bd:	5b                   	pop    %ebx
f01018be:	5e                   	pop    %esi
f01018bf:	5f                   	pop    %edi
f01018c0:	5d                   	pop    %ebp
f01018c1:	c3                   	ret    
f01018c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018c8:	39 f2                	cmp    %esi,%edx
f01018ca:	72 06                	jb     f01018d2 <__udivdi3+0x102>
f01018cc:	31 c0                	xor    %eax,%eax
f01018ce:	39 eb                	cmp    %ebp,%ebx
f01018d0:	77 d2                	ja     f01018a4 <__udivdi3+0xd4>
f01018d2:	b8 01 00 00 00       	mov    $0x1,%eax
f01018d7:	eb cb                	jmp    f01018a4 <__udivdi3+0xd4>
f01018d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01018e0:	89 d8                	mov    %ebx,%eax
f01018e2:	31 ff                	xor    %edi,%edi
f01018e4:	eb be                	jmp    f01018a4 <__udivdi3+0xd4>
f01018e6:	66 90                	xchg   %ax,%ax
f01018e8:	66 90                	xchg   %ax,%ax
f01018ea:	66 90                	xchg   %ax,%ax
f01018ec:	66 90                	xchg   %ax,%ax
f01018ee:	66 90                	xchg   %ax,%ax

f01018f0 <__umoddi3>:
f01018f0:	55                   	push   %ebp
f01018f1:	57                   	push   %edi
f01018f2:	56                   	push   %esi
f01018f3:	53                   	push   %ebx
f01018f4:	83 ec 1c             	sub    $0x1c,%esp
f01018f7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01018fb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01018ff:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101903:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101907:	85 ed                	test   %ebp,%ebp
f0101909:	89 f0                	mov    %esi,%eax
f010190b:	89 da                	mov    %ebx,%edx
f010190d:	75 19                	jne    f0101928 <__umoddi3+0x38>
f010190f:	39 df                	cmp    %ebx,%edi
f0101911:	0f 86 b1 00 00 00    	jbe    f01019c8 <__umoddi3+0xd8>
f0101917:	f7 f7                	div    %edi
f0101919:	89 d0                	mov    %edx,%eax
f010191b:	31 d2                	xor    %edx,%edx
f010191d:	83 c4 1c             	add    $0x1c,%esp
f0101920:	5b                   	pop    %ebx
f0101921:	5e                   	pop    %esi
f0101922:	5f                   	pop    %edi
f0101923:	5d                   	pop    %ebp
f0101924:	c3                   	ret    
f0101925:	8d 76 00             	lea    0x0(%esi),%esi
f0101928:	39 dd                	cmp    %ebx,%ebp
f010192a:	77 f1                	ja     f010191d <__umoddi3+0x2d>
f010192c:	0f bd cd             	bsr    %ebp,%ecx
f010192f:	83 f1 1f             	xor    $0x1f,%ecx
f0101932:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101936:	0f 84 b4 00 00 00    	je     f01019f0 <__umoddi3+0x100>
f010193c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101941:	89 c2                	mov    %eax,%edx
f0101943:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101947:	29 c2                	sub    %eax,%edx
f0101949:	89 c1                	mov    %eax,%ecx
f010194b:	89 f8                	mov    %edi,%eax
f010194d:	d3 e5                	shl    %cl,%ebp
f010194f:	89 d1                	mov    %edx,%ecx
f0101951:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101955:	d3 e8                	shr    %cl,%eax
f0101957:	09 c5                	or     %eax,%ebp
f0101959:	8b 44 24 04          	mov    0x4(%esp),%eax
f010195d:	89 c1                	mov    %eax,%ecx
f010195f:	d3 e7                	shl    %cl,%edi
f0101961:	89 d1                	mov    %edx,%ecx
f0101963:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101967:	89 df                	mov    %ebx,%edi
f0101969:	d3 ef                	shr    %cl,%edi
f010196b:	89 c1                	mov    %eax,%ecx
f010196d:	89 f0                	mov    %esi,%eax
f010196f:	d3 e3                	shl    %cl,%ebx
f0101971:	89 d1                	mov    %edx,%ecx
f0101973:	89 fa                	mov    %edi,%edx
f0101975:	d3 e8                	shr    %cl,%eax
f0101977:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010197c:	09 d8                	or     %ebx,%eax
f010197e:	f7 f5                	div    %ebp
f0101980:	d3 e6                	shl    %cl,%esi
f0101982:	89 d1                	mov    %edx,%ecx
f0101984:	f7 64 24 08          	mull   0x8(%esp)
f0101988:	39 d1                	cmp    %edx,%ecx
f010198a:	89 c3                	mov    %eax,%ebx
f010198c:	89 d7                	mov    %edx,%edi
f010198e:	72 06                	jb     f0101996 <__umoddi3+0xa6>
f0101990:	75 0e                	jne    f01019a0 <__umoddi3+0xb0>
f0101992:	39 c6                	cmp    %eax,%esi
f0101994:	73 0a                	jae    f01019a0 <__umoddi3+0xb0>
f0101996:	2b 44 24 08          	sub    0x8(%esp),%eax
f010199a:	19 ea                	sbb    %ebp,%edx
f010199c:	89 d7                	mov    %edx,%edi
f010199e:	89 c3                	mov    %eax,%ebx
f01019a0:	89 ca                	mov    %ecx,%edx
f01019a2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01019a7:	29 de                	sub    %ebx,%esi
f01019a9:	19 fa                	sbb    %edi,%edx
f01019ab:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01019af:	89 d0                	mov    %edx,%eax
f01019b1:	d3 e0                	shl    %cl,%eax
f01019b3:	89 d9                	mov    %ebx,%ecx
f01019b5:	d3 ee                	shr    %cl,%esi
f01019b7:	d3 ea                	shr    %cl,%edx
f01019b9:	09 f0                	or     %esi,%eax
f01019bb:	83 c4 1c             	add    $0x1c,%esp
f01019be:	5b                   	pop    %ebx
f01019bf:	5e                   	pop    %esi
f01019c0:	5f                   	pop    %edi
f01019c1:	5d                   	pop    %ebp
f01019c2:	c3                   	ret    
f01019c3:	90                   	nop
f01019c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019c8:	85 ff                	test   %edi,%edi
f01019ca:	89 f9                	mov    %edi,%ecx
f01019cc:	75 0b                	jne    f01019d9 <__umoddi3+0xe9>
f01019ce:	b8 01 00 00 00       	mov    $0x1,%eax
f01019d3:	31 d2                	xor    %edx,%edx
f01019d5:	f7 f7                	div    %edi
f01019d7:	89 c1                	mov    %eax,%ecx
f01019d9:	89 d8                	mov    %ebx,%eax
f01019db:	31 d2                	xor    %edx,%edx
f01019dd:	f7 f1                	div    %ecx
f01019df:	89 f0                	mov    %esi,%eax
f01019e1:	f7 f1                	div    %ecx
f01019e3:	e9 31 ff ff ff       	jmp    f0101919 <__umoddi3+0x29>
f01019e8:	90                   	nop
f01019e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019f0:	39 dd                	cmp    %ebx,%ebp
f01019f2:	72 08                	jb     f01019fc <__umoddi3+0x10c>
f01019f4:	39 f7                	cmp    %esi,%edi
f01019f6:	0f 87 21 ff ff ff    	ja     f010191d <__umoddi3+0x2d>
f01019fc:	89 da                	mov    %ebx,%edx
f01019fe:	89 f0                	mov    %esi,%eax
f0101a00:	29 f8                	sub    %edi,%eax
f0101a02:	19 ea                	sbb    %ebp,%edx
f0101a04:	e9 14 ff ff ff       	jmp    f010191d <__umoddi3+0x2d>
