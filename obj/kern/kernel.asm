
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 c0 72 01 00    	add    $0x172c0,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 80 90 11 f0    	mov    $0xf0119080,%edx
f0100058:	c7 c0 c0 96 11 f0    	mov    $0xf01196c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 cf 3c 00 00       	call   f0103d38 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 74 ce fe ff    	lea    -0x1318c(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 a5 30 00 00       	call   f0103127 <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 ff 12 00 00       	call   f0101386 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 b3 08 00 00       	call   f0100947 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 65 72 01 00    	add    $0x17265,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 96 11 f0    	mov    $0xf01196c4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 82 08 00 00       	call   f0100947 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 8f ce fe ff    	lea    -0x13171(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 41 30 00 00       	call   f0103127 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 00 30 00 00       	call   f01030f0 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 39 de fe ff    	lea    -0x121c7(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 29 30 00 00       	call   f0103127 <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 ff 71 01 00    	add    $0x171ff,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 a7 ce fe ff    	lea    -0x13159(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 fc 2f 00 00       	call   f0103127 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 b9 2f 00 00       	call   f01030f0 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 39 de fe ff    	lea    -0x121c7(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 e2 2f 00 00       	call   f0103127 <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 90 71 01 00    	add    $0x17190,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 98 1f 00 00    	mov    0x1f98(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
f010019e:	88 84 0b 94 1d 00 00 	mov    %al,0x1d94(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 98 1f 00 00 00 	movl   $0x0,0x1f98(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 45 71 01 00    	add    $0x17145,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 74 1d 00 00    	mov    0x1d74(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 74 1d 00 00    	mov    %ecx,0x1d74(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 f4 cf fe 	movzbl -0x1300c(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 74 1d 00 00    	or     0x1d74(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 f4 ce fe 	movzbl -0x1310c(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 74 1d 00 00    	mov    %eax,0x1d74(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f4 1c 00 00 	mov    0x1cf4(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 c1 ce fe ff    	lea    -0x1313f(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 b1 2e 00 00       	call   f0103127 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 74 1d 00 00 40 	orl    $0x40,0x1d74(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 74 1d 00 00    	mov    0x1d74(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 f4 cf fe 	movzbl -0x1300c(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 74 1d 00 00    	mov    %eax,0x1d74(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0f 70 01 00    	add    $0x1700f,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 9c 1f 00 00 	cmpw   $0x7cf,0x1f9c(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b a4 1f 00 00    	mov    0x1fa4(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b a0 1f 00 00    	mov    0x1fa0(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 9c 1f 00 00 	addw   $0x50,0x1f9c(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 9c 1f 00 00 	mov    %dx,0x1f9c(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 a0 1f 00 00    	mov    0x1fa0(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 a0 1f 00 00    	mov    0x1fa0(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 ae 38 00 00       	call   f0103d85 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 a0 1f 00 00    	mov    0x1fa0(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 9c 1f 00 00 	subw   $0x50,0x1f9c(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 02 6e 01 00       	add    $0x16e02,%eax
	if (serial_exists)
f010050f:	80 b8 a8 1f 00 00 00 	cmpb   $0x0,0x1fa8(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 47 8e fe ff    	lea    -0x171b9(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d4 6d 01 00       	add    $0x16dd4,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b1 8e fe ff    	lea    -0x1714f(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b6 6d 01 00    	add    $0x16db6,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 94 1f 00 00    	mov    0x1f94(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 98 1f 00 00    	cmp    0x1f98(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 94 1f 00 00    	mov    %ecx,0x1f94(%ebx)
f0100582:	0f b6 84 13 94 1d 00 	movzbl 0x1d94(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 5a 6d 01 00    	add    $0x16d5a,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 a4 1f 00 00 b4 	movl   $0x3b4,0x1fa4(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb a4 1f 00 00    	mov    0x1fa4(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb a0 1f 00 00    	mov    %edi,0x1fa0(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 9c 1f 00 00 	mov    %si,0x1f9c(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 a8 1f 00 00 	setne  0x1fa8(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 a4 1f 00 00 d4 	movl   $0x3d4,0x1fa4(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 cd ce fe ff    	lea    -0x13133(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 66 2a 00 00       	call   f0103127 <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	e8 50 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ff:	81 c3 0d 6c 01 00    	add    $0x16c0d,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 f4 d0 fe ff    	lea    -0x12f0c(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 12 d1 fe ff    	lea    -0x12eee(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 17 d1 fe ff    	lea    -0x12ee9(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 05 2a 00 00       	call   f0103127 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 e4 d1 fe ff    	lea    -0x12e1c(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 20 d1 fe ff    	lea    -0x12ee0(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 ee 29 00 00       	call   f0103127 <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 0c d2 fe ff    	lea    -0x12df4(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 29 d1 fe ff    	lea    -0x12ed7(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 d7 29 00 00       	call   f0103127 <cprintf>
f0100750:	83 c4 0c             	add    $0xc,%esp
f0100753:	8d 83 30 d2 fe ff    	lea    -0x12dd0(%ebx),%eax
f0100759:	50                   	push   %eax
f010075a:	8d 83 33 d1 fe ff    	lea    -0x12ecd(%ebx),%eax
f0100760:	50                   	push   %eax
f0100761:	56                   	push   %esi
f0100762:	e8 c0 29 00 00       	call   f0103127 <cprintf>
	return 0;
}
f0100767:	b8 00 00 00 00       	mov    $0x0,%eax
f010076c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010076f:	5b                   	pop    %ebx
f0100770:	5e                   	pop    %esi
f0100771:	5d                   	pop    %ebp
f0100772:	c3                   	ret    

f0100773 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100773:	55                   	push   %ebp
f0100774:	89 e5                	mov    %esp,%ebp
f0100776:	57                   	push   %edi
f0100777:	56                   	push   %esi
f0100778:	53                   	push   %ebx
f0100779:	83 ec 18             	sub    $0x18,%esp
f010077c:	e8 ce f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100781:	81 c3 8b 6b 01 00    	add    $0x16b8b,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100787:	8d 83 40 d1 fe ff    	lea    -0x12ec0(%ebx),%eax
f010078d:	50                   	push   %eax
f010078e:	e8 94 29 00 00       	call   f0103127 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100793:	83 c4 08             	add    $0x8,%esp
f0100796:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010079c:	8d 83 7c d2 fe ff    	lea    -0x12d84(%ebx),%eax
f01007a2:	50                   	push   %eax
f01007a3:	e8 7f 29 00 00       	call   f0103127 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a8:	83 c4 0c             	add    $0xc,%esp
f01007ab:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007b1:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007b7:	50                   	push   %eax
f01007b8:	57                   	push   %edi
f01007b9:	8d 83 a4 d2 fe ff    	lea    -0x12d5c(%ebx),%eax
f01007bf:	50                   	push   %eax
f01007c0:	e8 62 29 00 00       	call   f0103127 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007c5:	83 c4 0c             	add    $0xc,%esp
f01007c8:	c7 c0 79 41 10 f0    	mov    $0xf0104179,%eax
f01007ce:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007d4:	52                   	push   %edx
f01007d5:	50                   	push   %eax
f01007d6:	8d 83 c8 d2 fe ff    	lea    -0x12d38(%ebx),%eax
f01007dc:	50                   	push   %eax
f01007dd:	e8 45 29 00 00       	call   f0103127 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007e2:	83 c4 0c             	add    $0xc,%esp
f01007e5:	c7 c0 80 90 11 f0    	mov    $0xf0119080,%eax
f01007eb:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007f1:	52                   	push   %edx
f01007f2:	50                   	push   %eax
f01007f3:	8d 83 ec d2 fe ff    	lea    -0x12d14(%ebx),%eax
f01007f9:	50                   	push   %eax
f01007fa:	e8 28 29 00 00       	call   f0103127 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007ff:	83 c4 0c             	add    $0xc,%esp
f0100802:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f0100808:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010080e:	50                   	push   %eax
f010080f:	56                   	push   %esi
f0100810:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100816:	50                   	push   %eax
f0100817:	e8 0b 29 00 00       	call   f0103127 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010081c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010081f:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100825:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100827:	c1 fe 0a             	sar    $0xa,%esi
f010082a:	56                   	push   %esi
f010082b:	8d 83 34 d3 fe ff    	lea    -0x12ccc(%ebx),%eax
f0100831:	50                   	push   %eax
f0100832:	e8 f0 28 00 00       	call   f0103127 <cprintf>
	return 0;
}
f0100837:	b8 00 00 00 00       	mov    $0x0,%eax
f010083c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010083f:	5b                   	pop    %ebx
f0100840:	5e                   	pop    %esi
f0100841:	5f                   	pop    %edi
f0100842:	5d                   	pop    %ebp
f0100843:	c3                   	ret    

f0100844 <mon_showmappings>:
		this_ebp = (uint32_t *)pre_ebp;
	}
	return 0;
}

int mon_showmappings(int argc, char **argv, struct Trapframe *tf){
f0100844:	55                   	push   %ebp
f0100845:	89 e5                	mov    %esp,%ebp
f0100847:	53                   	push   %ebx
f0100848:	83 ec 10             	sub    $0x10,%esp
f010084b:	e8 ff f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100850:	81 c3 bc 6a 01 00    	add    $0x16abc,%ebx
		}
		cprintf("Virtual address %#x map to Physical address %#x . Permisson: PTE_U = %d , PTE_W = %d\n",
		 low, PTE_ADDR(*pte),*pte&PTE_U,*pte&PTE_W);
	}
	*/
	cprintf("This command is not supplement\n");
f0100856:	8d 83 60 d3 fe ff    	lea    -0x12ca0(%ebx),%eax
f010085c:	50                   	push   %eax
f010085d:	e8 c5 28 00 00       	call   f0103127 <cprintf>
	return 0;
}
f0100862:	b8 00 00 00 00       	mov    $0x0,%eax
f0100867:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010086a:	c9                   	leave  
f010086b:	c3                   	ret    

f010086c <mon_backtrace>:
{
f010086c:	55                   	push   %ebp
f010086d:	89 e5                	mov    %esp,%ebp
f010086f:	57                   	push   %edi
f0100870:	56                   	push   %esi
f0100871:	53                   	push   %ebx
f0100872:	83 ec 48             	sub    $0x48,%esp
f0100875:	e8 d5 f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010087a:	81 c3 92 6a 01 00    	add    $0x16a92,%ebx
	cprintf("Stack backtrace:\n");
f0100880:	8d 83 59 d1 fe ff    	lea    -0x12ea7(%ebx),%eax
f0100886:	50                   	push   %eax
f0100887:	e8 9b 28 00 00       	call   f0103127 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010088c:	89 ef                	mov    %ebp,%edi
	while(this_ebp!=0){
f010088e:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
f0100891:	8d 83 6b d1 fe ff    	lea    -0x12e95(%ebx),%eax
f0100897:	89 45 b8             	mov    %eax,-0x48(%ebp)
			cprintf(" %08x", *(this_ebp + 2 + i));
f010089a:	8d 83 86 d1 fe ff    	lea    -0x12e7a(%ebx),%eax
f01008a0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	while(this_ebp!=0){
f01008a3:	e9 8a 00 00 00       	jmp    f0100932 <mon_backtrace+0xc6>
		uint32_t pre_ebp = *this_ebp;
f01008a8:	8b 07                	mov    (%edi),%eax
f01008aa:	89 45 c0             	mov    %eax,-0x40(%ebp)
		uintptr_t eip = *(this_ebp + 1);
f01008ad:	8b 47 04             	mov    0x4(%edi),%eax
f01008b0:	89 45 bc             	mov    %eax,-0x44(%ebp)
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
f01008b3:	83 ec 04             	sub    $0x4,%esp
f01008b6:	50                   	push   %eax
f01008b7:	57                   	push   %edi
f01008b8:	ff 75 b8             	pushl  -0x48(%ebp)
f01008bb:	e8 67 28 00 00       	call   f0103127 <cprintf>
f01008c0:	8d 77 08             	lea    0x8(%edi),%esi
f01008c3:	83 c7 1c             	add    $0x1c,%edi
f01008c6:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f01008c9:	83 ec 08             	sub    $0x8,%esp
f01008cc:	ff 36                	pushl  (%esi)
f01008ce:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008d1:	e8 51 28 00 00       	call   f0103127 <cprintf>
f01008d6:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f01008d9:	83 c4 10             	add    $0x10,%esp
f01008dc:	39 fe                	cmp    %edi,%esi
f01008de:	75 e9                	jne    f01008c9 <mon_backtrace+0x5d>
		cprintf("\n");
f01008e0:	83 ec 0c             	sub    $0xc,%esp
f01008e3:	8d 83 39 de fe ff    	lea    -0x121c7(%ebx),%eax
f01008e9:	50                   	push   %eax
f01008ea:	e8 38 28 00 00       	call   f0103127 <cprintf>
		debuginfo_eip(eip, &info);
f01008ef:	83 c4 08             	add    $0x8,%esp
f01008f2:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008f5:	50                   	push   %eax
f01008f6:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008f9:	57                   	push   %edi
f01008fa:	e8 2c 29 00 00       	call   f010322b <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f01008ff:	83 c4 0c             	add    $0xc,%esp
f0100902:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100905:	ff 75 d0             	pushl  -0x30(%ebp)
f0100908:	8d 83 8c d1 fe ff    	lea    -0x12e74(%ebx),%eax
f010090e:	50                   	push   %eax
f010090f:	e8 13 28 00 00       	call   f0103127 <cprintf>
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f0100914:	89 f8                	mov    %edi,%eax
f0100916:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100919:	50                   	push   %eax
f010091a:	ff 75 d8             	pushl  -0x28(%ebp)
f010091d:	ff 75 dc             	pushl  -0x24(%ebp)
f0100920:	8d 83 9c d1 fe ff    	lea    -0x12e64(%ebx),%eax
f0100926:	50                   	push   %eax
f0100927:	e8 fb 27 00 00       	call   f0103127 <cprintf>
		this_ebp = (uint32_t *)pre_ebp;
f010092c:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010092f:	83 c4 20             	add    $0x20,%esp
	while(this_ebp!=0){
f0100932:	85 ff                	test   %edi,%edi
f0100934:	0f 85 6e ff ff ff    	jne    f01008a8 <mon_backtrace+0x3c>
}
f010093a:	b8 00 00 00 00       	mov    $0x0,%eax
f010093f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100942:	5b                   	pop    %ebx
f0100943:	5e                   	pop    %esi
f0100944:	5f                   	pop    %edi
f0100945:	5d                   	pop    %ebp
f0100946:	c3                   	ret    

f0100947 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100947:	55                   	push   %ebp
f0100948:	89 e5                	mov    %esp,%ebp
f010094a:	57                   	push   %edi
f010094b:	56                   	push   %esi
f010094c:	53                   	push   %ebx
f010094d:	83 ec 68             	sub    $0x68,%esp
f0100950:	e8 fa f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100955:	81 c3 b7 69 01 00    	add    $0x169b7,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010095b:	8d 83 80 d3 fe ff    	lea    -0x12c80(%ebx),%eax
f0100961:	50                   	push   %eax
f0100962:	e8 c0 27 00 00       	call   f0103127 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100967:	8d 83 a4 d3 fe ff    	lea    -0x12c5c(%ebx),%eax
f010096d:	89 04 24             	mov    %eax,(%esp)
f0100970:	e8 b2 27 00 00       	call   f0103127 <cprintf>
f0100975:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100978:	8d bb a9 d1 fe ff    	lea    -0x12e57(%ebx),%edi
f010097e:	eb 4a                	jmp    f01009ca <monitor+0x83>
f0100980:	83 ec 08             	sub    $0x8,%esp
f0100983:	0f be c0             	movsbl %al,%eax
f0100986:	50                   	push   %eax
f0100987:	57                   	push   %edi
f0100988:	e8 6e 33 00 00       	call   f0103cfb <strchr>
f010098d:	83 c4 10             	add    $0x10,%esp
f0100990:	85 c0                	test   %eax,%eax
f0100992:	74 08                	je     f010099c <monitor+0x55>
			*buf++ = 0;
f0100994:	c6 06 00             	movb   $0x0,(%esi)
f0100997:	8d 76 01             	lea    0x1(%esi),%esi
f010099a:	eb 79                	jmp    f0100a15 <monitor+0xce>
		if (*buf == 0)
f010099c:	80 3e 00             	cmpb   $0x0,(%esi)
f010099f:	74 7f                	je     f0100a20 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f01009a1:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009a5:	74 0f                	je     f01009b6 <monitor+0x6f>
		argv[argc++] = buf;
f01009a7:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009aa:	8d 48 01             	lea    0x1(%eax),%ecx
f01009ad:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009b0:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01009b4:	eb 44                	jmp    f01009fa <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009b6:	83 ec 08             	sub    $0x8,%esp
f01009b9:	6a 10                	push   $0x10
f01009bb:	8d 83 ae d1 fe ff    	lea    -0x12e52(%ebx),%eax
f01009c1:	50                   	push   %eax
f01009c2:	e8 60 27 00 00       	call   f0103127 <cprintf>
f01009c7:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009ca:	8d 83 a5 d1 fe ff    	lea    -0x12e5b(%ebx),%eax
f01009d0:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009d3:	83 ec 0c             	sub    $0xc,%esp
f01009d6:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009d9:	e8 e5 30 00 00       	call   f0103ac3 <readline>
f01009de:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009e0:	83 c4 10             	add    $0x10,%esp
f01009e3:	85 c0                	test   %eax,%eax
f01009e5:	74 ec                	je     f01009d3 <monitor+0x8c>
	argv[argc] = 0;
f01009e7:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009ee:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009f5:	eb 1e                	jmp    f0100a15 <monitor+0xce>
			buf++;
f01009f7:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009fa:	0f b6 06             	movzbl (%esi),%eax
f01009fd:	84 c0                	test   %al,%al
f01009ff:	74 14                	je     f0100a15 <monitor+0xce>
f0100a01:	83 ec 08             	sub    $0x8,%esp
f0100a04:	0f be c0             	movsbl %al,%eax
f0100a07:	50                   	push   %eax
f0100a08:	57                   	push   %edi
f0100a09:	e8 ed 32 00 00       	call   f0103cfb <strchr>
f0100a0e:	83 c4 10             	add    $0x10,%esp
f0100a11:	85 c0                	test   %eax,%eax
f0100a13:	74 e2                	je     f01009f7 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a15:	0f b6 06             	movzbl (%esi),%eax
f0100a18:	84 c0                	test   %al,%al
f0100a1a:	0f 85 60 ff ff ff    	jne    f0100980 <monitor+0x39>
	argv[argc] = 0;
f0100a20:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a23:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a2a:	00 
	if (argc == 0)
f0100a2b:	85 c0                	test   %eax,%eax
f0100a2d:	74 9b                	je     f01009ca <monitor+0x83>
f0100a2f:	8d b3 14 1d 00 00    	lea    0x1d14(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a35:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a3c:	83 ec 08             	sub    $0x8,%esp
f0100a3f:	ff 36                	pushl  (%esi)
f0100a41:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a44:	e8 54 32 00 00       	call   f0103c9d <strcmp>
f0100a49:	83 c4 10             	add    $0x10,%esp
f0100a4c:	85 c0                	test   %eax,%eax
f0100a4e:	74 29                	je     f0100a79 <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a50:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f0100a54:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a57:	83 c6 0c             	add    $0xc,%esi
f0100a5a:	83 f8 04             	cmp    $0x4,%eax
f0100a5d:	75 dd                	jne    f0100a3c <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a5f:	83 ec 08             	sub    $0x8,%esp
f0100a62:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a65:	8d 83 cb d1 fe ff    	lea    -0x12e35(%ebx),%eax
f0100a6b:	50                   	push   %eax
f0100a6c:	e8 b6 26 00 00       	call   f0103127 <cprintf>
f0100a71:	83 c4 10             	add    $0x10,%esp
f0100a74:	e9 51 ff ff ff       	jmp    f01009ca <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100a79:	83 ec 04             	sub    $0x4,%esp
f0100a7c:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a7f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a82:	ff 75 08             	pushl  0x8(%ebp)
f0100a85:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a88:	52                   	push   %edx
f0100a89:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a8c:	ff 94 83 1c 1d 00 00 	call   *0x1d1c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a93:	83 c4 10             	add    $0x10,%esp
f0100a96:	85 c0                	test   %eax,%eax
f0100a98:	0f 89 2c ff ff ff    	jns    f01009ca <monitor+0x83>
				break;
	}
}
f0100a9e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100aa1:	5b                   	pop    %ebx
f0100aa2:	5e                   	pop    %esi
f0100aa3:	5f                   	pop    %edi
f0100aa4:	5d                   	pop    %ebp
f0100aa5:	c3                   	ret    

f0100aa6 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100aa6:	55                   	push   %ebp
f0100aa7:	89 e5                	mov    %esp,%ebp
f0100aa9:	e8 e2 25 00 00       	call   f0103090 <__x86.get_pc_thunk.dx>
f0100aae:	81 c2 5e 68 01 00    	add    $0x1685e,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ab4:	83 ba ac 1f 00 00 00 	cmpl   $0x0,0x1fac(%edx)
f0100abb:	74 0e                	je     f0100acb <boot_alloc+0x25>
	// LAB 2: Your code here.********************************************************************

	// 两步：1、分配一个足够大的页面  2、更新 nextfree ，要为4096的整数倍
	// 并不需要真正的分配内存，就只是先占个坑
	// 如果n>0，就返回分配空间的首地址
	if(n>0){
f0100abd:	85 c0                	test   %eax,%eax
f0100abf:	75 24                	jne    f0100ae5 <boot_alloc+0x3f>
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
		return result;
	}
	// 如果n==0，就返回nextfree
	if(n==0){
		return nextfree;
f0100ac1:	8b 8a ac 1f 00 00    	mov    0x1fac(%edx),%ecx
	}

	return NULL;
}
f0100ac7:	89 c8                	mov    %ecx,%eax
f0100ac9:	5d                   	pop    %ebp
f0100aca:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100acb:	c7 c1 c0 96 11 f0    	mov    $0xf01196c0,%ecx
f0100ad1:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100ad7:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100add:	89 8a ac 1f 00 00    	mov    %ecx,0x1fac(%edx)
f0100ae3:	eb d8                	jmp    f0100abd <boot_alloc+0x17>
		result = nextfree;
f0100ae5:	8b 8a ac 1f 00 00    	mov    0x1fac(%edx),%ecx
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100aeb:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0100af2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100af7:	89 82 ac 1f 00 00    	mov    %eax,0x1fac(%edx)
		return result;
f0100afd:	eb c8                	jmp    f0100ac7 <boot_alloc+0x21>

f0100aff <nvram_read>:
{
f0100aff:	55                   	push   %ebp
f0100b00:	89 e5                	mov    %esp,%ebp
f0100b02:	57                   	push   %edi
f0100b03:	56                   	push   %esi
f0100b04:	53                   	push   %ebx
f0100b05:	83 ec 18             	sub    $0x18,%esp
f0100b08:	e8 42 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100b0d:	81 c3 ff 67 01 00    	add    $0x167ff,%ebx
f0100b13:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b15:	50                   	push   %eax
f0100b16:	e8 85 25 00 00       	call   f01030a0 <mc146818_read>
f0100b1b:	89 c6                	mov    %eax,%esi
f0100b1d:	83 c7 01             	add    $0x1,%edi
f0100b20:	89 3c 24             	mov    %edi,(%esp)
f0100b23:	e8 78 25 00 00       	call   f01030a0 <mc146818_read>
f0100b28:	c1 e0 08             	shl    $0x8,%eax
f0100b2b:	09 f0                	or     %esi,%eax
}
f0100b2d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b30:	5b                   	pop    %ebx
f0100b31:	5e                   	pop    %esi
f0100b32:	5f                   	pop    %edi
f0100b33:	5d                   	pop    %ebp
f0100b34:	c3                   	ret    

f0100b35 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b35:	55                   	push   %ebp
f0100b36:	89 e5                	mov    %esp,%ebp
f0100b38:	56                   	push   %esi
f0100b39:	53                   	push   %ebx
f0100b3a:	e8 55 25 00 00       	call   f0103094 <__x86.get_pc_thunk.cx>
f0100b3f:	81 c1 cd 67 01 00    	add    $0x167cd,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b45:	89 d3                	mov    %edx,%ebx
f0100b47:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b4a:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b4d:	a8 01                	test   $0x1,%al
f0100b4f:	74 5a                	je     f0100bab <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b51:	25 00 f0 ff ff       	and    $0xfffff000,%eax
// 这个宏把真实的物理地址转化为‘Remapped Physical Memory’段的虚拟地址，与 PADDR 相反

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b56:	89 c6                	mov    %eax,%esi
f0100b58:	c1 ee 0c             	shr    $0xc,%esi
f0100b5b:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0100b61:	3b 33                	cmp    (%ebx),%esi
f0100b63:	73 2b                	jae    f0100b90 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b65:	c1 ea 0c             	shr    $0xc,%edx
f0100b68:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b6e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b75:	89 c2                	mov    %eax,%edx
f0100b77:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b7a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b7f:	85 d2                	test   %edx,%edx
f0100b81:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b86:	0f 44 c2             	cmove  %edx,%eax
}
f0100b89:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b8c:	5b                   	pop    %ebx
f0100b8d:	5e                   	pop    %esi
f0100b8e:	5d                   	pop    %ebp
f0100b8f:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b90:	50                   	push   %eax
f0100b91:	8d 81 cc d3 fe ff    	lea    -0x12c34(%ecx),%eax
f0100b97:	50                   	push   %eax
f0100b98:	68 f7 02 00 00       	push   $0x2f7
f0100b9d:	8d 81 88 db fe ff    	lea    -0x12478(%ecx),%eax
f0100ba3:	50                   	push   %eax
f0100ba4:	89 cb                	mov    %ecx,%ebx
f0100ba6:	e8 ee f4 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100bab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bb0:	eb d7                	jmp    f0100b89 <check_va2pa+0x54>

f0100bb2 <check_page_free_list>:
{
f0100bb2:	55                   	push   %ebp
f0100bb3:	89 e5                	mov    %esp,%ebp
f0100bb5:	57                   	push   %edi
f0100bb6:	56                   	push   %esi
f0100bb7:	53                   	push   %ebx
f0100bb8:	83 ec 3c             	sub    $0x3c,%esp
f0100bbb:	e8 dc 24 00 00       	call   f010309c <__x86.get_pc_thunk.di>
f0100bc0:	81 c7 4c 67 01 00    	add    $0x1674c,%edi
f0100bc6:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bc9:	84 c0                	test   %al,%al
f0100bcb:	0f 85 dd 02 00 00    	jne    f0100eae <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100bd1:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100bd4:	83 b8 b0 1f 00 00 00 	cmpl   $0x0,0x1fb0(%eax)
f0100bdb:	74 0c                	je     f0100be9 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bdd:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100be4:	e9 2f 03 00 00       	jmp    f0100f18 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100be9:	83 ec 04             	sub    $0x4,%esp
f0100bec:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bef:	8d 83 f0 d3 fe ff    	lea    -0x12c10(%ebx),%eax
f0100bf5:	50                   	push   %eax
f0100bf6:	68 38 02 00 00       	push   $0x238
f0100bfb:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100c01:	50                   	push   %eax
f0100c02:	e8 92 f4 ff ff       	call   f0100099 <_panic>
f0100c07:	50                   	push   %eax
f0100c08:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c0b:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f0100c11:	50                   	push   %eax
f0100c12:	6a 59                	push   $0x59
f0100c14:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f0100c1a:	50                   	push   %eax
f0100c1b:	e8 79 f4 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c20:	8b 36                	mov    (%esi),%esi
f0100c22:	85 f6                	test   %esi,%esi
f0100c24:	74 40                	je     f0100c66 <check_page_free_list+0xb4>

// (pp - pages)为页号，(pp - pages) << PGSHIFT 为页号左移12位，也就是该页的物理地址
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c26:	89 f0                	mov    %esi,%eax
f0100c28:	2b 07                	sub    (%edi),%eax
f0100c2a:	c1 f8 03             	sar    $0x3,%eax
f0100c2d:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c30:	89 c2                	mov    %eax,%edx
f0100c32:	c1 ea 16             	shr    $0x16,%edx
f0100c35:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c38:	73 e6                	jae    f0100c20 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100c3a:	89 c2                	mov    %eax,%edx
f0100c3c:	c1 ea 0c             	shr    $0xc,%edx
f0100c3f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c42:	3b 11                	cmp    (%ecx),%edx
f0100c44:	73 c1                	jae    f0100c07 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100c46:	83 ec 04             	sub    $0x4,%esp
f0100c49:	68 80 00 00 00       	push   $0x80
f0100c4e:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c53:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c58:	50                   	push   %eax
f0100c59:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c5c:	e8 d7 30 00 00       	call   f0103d38 <memset>
f0100c61:	83 c4 10             	add    $0x10,%esp
f0100c64:	eb ba                	jmp    f0100c20 <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100c66:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c6b:	e8 36 fe ff ff       	call   f0100aa6 <boot_alloc>
f0100c70:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c73:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c76:	8b 97 b0 1f 00 00    	mov    0x1fb0(%edi),%edx
		assert(pp >= pages);
f0100c7c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100c82:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100c84:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100c8a:	8b 00                	mov    (%eax),%eax
f0100c8c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c8f:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c92:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c95:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c9a:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c9d:	e9 08 01 00 00       	jmp    f0100daa <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100ca2:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ca5:	8d 83 a2 db fe ff    	lea    -0x1245e(%ebx),%eax
f0100cab:	50                   	push   %eax
f0100cac:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100cb2:	50                   	push   %eax
f0100cb3:	68 52 02 00 00       	push   $0x252
f0100cb8:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100cbe:	50                   	push   %eax
f0100cbf:	e8 d5 f3 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100cc4:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cc7:	8d 83 c3 db fe ff    	lea    -0x1243d(%ebx),%eax
f0100ccd:	50                   	push   %eax
f0100cce:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100cd4:	50                   	push   %eax
f0100cd5:	68 53 02 00 00       	push   $0x253
f0100cda:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100ce0:	50                   	push   %eax
f0100ce1:	e8 b3 f3 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ce6:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ce9:	8d 83 14 d4 fe ff    	lea    -0x12bec(%ebx),%eax
f0100cef:	50                   	push   %eax
f0100cf0:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100cf6:	50                   	push   %eax
f0100cf7:	68 54 02 00 00       	push   $0x254
f0100cfc:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100d02:	50                   	push   %eax
f0100d03:	e8 91 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100d08:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d0b:	8d 83 d7 db fe ff    	lea    -0x12429(%ebx),%eax
f0100d11:	50                   	push   %eax
f0100d12:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100d18:	50                   	push   %eax
f0100d19:	68 57 02 00 00       	push   $0x257
f0100d1e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100d24:	50                   	push   %eax
f0100d25:	e8 6f f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d2a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d2d:	8d 83 e8 db fe ff    	lea    -0x12418(%ebx),%eax
f0100d33:	50                   	push   %eax
f0100d34:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100d3a:	50                   	push   %eax
f0100d3b:	68 58 02 00 00       	push   $0x258
f0100d40:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100d46:	50                   	push   %eax
f0100d47:	e8 4d f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d4c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d4f:	8d 83 48 d4 fe ff    	lea    -0x12bb8(%ebx),%eax
f0100d55:	50                   	push   %eax
f0100d56:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100d5c:	50                   	push   %eax
f0100d5d:	68 59 02 00 00       	push   $0x259
f0100d62:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100d68:	50                   	push   %eax
f0100d69:	e8 2b f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d6e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d71:	8d 83 01 dc fe ff    	lea    -0x123ff(%ebx),%eax
f0100d77:	50                   	push   %eax
f0100d78:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100d7e:	50                   	push   %eax
f0100d7f:	68 5a 02 00 00       	push   $0x25a
f0100d84:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100d8a:	50                   	push   %eax
f0100d8b:	e8 09 f3 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100d90:	89 c6                	mov    %eax,%esi
f0100d92:	c1 ee 0c             	shr    $0xc,%esi
f0100d95:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100d98:	76 70                	jbe    f0100e0a <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100d9a:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d9f:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100da2:	77 7f                	ja     f0100e23 <check_page_free_list+0x271>
			++nfree_extmem;
f0100da4:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100da8:	8b 12                	mov    (%edx),%edx
f0100daa:	85 d2                	test   %edx,%edx
f0100dac:	0f 84 93 00 00 00    	je     f0100e45 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100db2:	39 d1                	cmp    %edx,%ecx
f0100db4:	0f 87 e8 fe ff ff    	ja     f0100ca2 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100dba:	39 d3                	cmp    %edx,%ebx
f0100dbc:	0f 86 02 ff ff ff    	jbe    f0100cc4 <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dc2:	89 d0                	mov    %edx,%eax
f0100dc4:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100dc7:	a8 07                	test   $0x7,%al
f0100dc9:	0f 85 17 ff ff ff    	jne    f0100ce6 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100dcf:	c1 f8 03             	sar    $0x3,%eax
f0100dd2:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100dd5:	85 c0                	test   %eax,%eax
f0100dd7:	0f 84 2b ff ff ff    	je     f0100d08 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ddd:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100de2:	0f 84 42 ff ff ff    	je     f0100d2a <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100de8:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ded:	0f 84 59 ff ff ff    	je     f0100d4c <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100df3:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100df8:	0f 84 70 ff ff ff    	je     f0100d6e <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dfe:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e03:	77 8b                	ja     f0100d90 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100e05:	83 c7 01             	add    $0x1,%edi
f0100e08:	eb 9e                	jmp    f0100da8 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e0a:	50                   	push   %eax
f0100e0b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e0e:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f0100e14:	50                   	push   %eax
f0100e15:	6a 59                	push   $0x59
f0100e17:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f0100e1d:	50                   	push   %eax
f0100e1e:	e8 76 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e23:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e26:	8d 83 6c d4 fe ff    	lea    -0x12b94(%ebx),%eax
f0100e2c:	50                   	push   %eax
f0100e2d:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100e33:	50                   	push   %eax
f0100e34:	68 5b 02 00 00       	push   $0x25b
f0100e39:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100e3f:	50                   	push   %eax
f0100e40:	e8 54 f2 ff ff       	call   f0100099 <_panic>
f0100e45:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100e48:	85 ff                	test   %edi,%edi
f0100e4a:	7e 1e                	jle    f0100e6a <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100e4c:	85 f6                	test   %esi,%esi
f0100e4e:	7e 3c                	jle    f0100e8c <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e50:	83 ec 0c             	sub    $0xc,%esp
f0100e53:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e56:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f0100e5c:	50                   	push   %eax
f0100e5d:	e8 c5 22 00 00       	call   f0103127 <cprintf>
}
f0100e62:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e65:	5b                   	pop    %ebx
f0100e66:	5e                   	pop    %esi
f0100e67:	5f                   	pop    %edi
f0100e68:	5d                   	pop    %ebp
f0100e69:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e6a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e6d:	8d 83 1b dc fe ff    	lea    -0x123e5(%ebx),%eax
f0100e73:	50                   	push   %eax
f0100e74:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100e7a:	50                   	push   %eax
f0100e7b:	68 63 02 00 00       	push   $0x263
f0100e80:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100e86:	50                   	push   %eax
f0100e87:	e8 0d f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e8c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e8f:	8d 83 2d dc fe ff    	lea    -0x123d3(%ebx),%eax
f0100e95:	50                   	push   %eax
f0100e96:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0100e9c:	50                   	push   %eax
f0100e9d:	68 64 02 00 00       	push   $0x264
f0100ea2:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0100ea8:	50                   	push   %eax
f0100ea9:	e8 eb f1 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100eae:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100eb1:	8b 80 b0 1f 00 00    	mov    0x1fb0(%eax),%eax
f0100eb7:	85 c0                	test   %eax,%eax
f0100eb9:	0f 84 2a fd ff ff    	je     f0100be9 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ebf:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ec2:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ec5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ec8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100ecb:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ece:	c7 c3 d0 96 11 f0    	mov    $0xf01196d0,%ebx
f0100ed4:	89 c2                	mov    %eax,%edx
f0100ed6:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ed8:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ede:	0f 95 c2             	setne  %dl
f0100ee1:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ee4:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ee8:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100eea:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100eee:	8b 00                	mov    (%eax),%eax
f0100ef0:	85 c0                	test   %eax,%eax
f0100ef2:	75 e0                	jne    f0100ed4 <check_page_free_list+0x322>
		*tp[1] = 0;
f0100ef4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ef7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100efd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f00:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f03:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f05:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f08:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100f0b:	89 87 b0 1f 00 00    	mov    %eax,0x1fb0(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f11:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f18:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f1b:	8b b0 b0 1f 00 00    	mov    0x1fb0(%eax),%esi
f0100f21:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	if (PGNUM(pa) >= npages)
f0100f27:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100f2d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f30:	e9 ed fc ff ff       	jmp    f0100c22 <check_page_free_list+0x70>

f0100f35 <page_init>:
{
f0100f35:	55                   	push   %ebp
f0100f36:	89 e5                	mov    %esp,%ebp
f0100f38:	57                   	push   %edi
f0100f39:	56                   	push   %esi
f0100f3a:	53                   	push   %ebx
f0100f3b:	83 ec 2c             	sub    $0x2c,%esp
f0100f3e:	e8 55 21 00 00       	call   f0103098 <__x86.get_pc_thunk.si>
f0100f43:	81 c6 c9 63 01 00    	add    $0x163c9,%esi
	physaddr_t truly_end = PADDR(boot_alloc(0));
f0100f49:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f4e:	e8 53 fb ff ff       	call   f0100aa6 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100f53:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f58:	76 33                	jbe    f0100f8d <page_init+0x58>
	return (physaddr_t)kva - KERNBASE;
f0100f5a:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f5f:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f62:	8b 86 b0 1f 00 00    	mov    0x1fb0(%esi),%eax
f0100f68:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < npages; i++)
f0100f6b:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
f0100f6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f74:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
f0100f7a:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0100f80:	89 55 d8             	mov    %edx,-0x28(%ebp)
			page_free_list = &pages[i];
f0100f83:	89 55 d0             	mov    %edx,-0x30(%ebp)
			pages[i].pp_ref = 1;
f0100f86:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100f89:	89 c1                	mov    %eax,%ecx
	for (i = 0; i < npages; i++)
f0100f8b:	eb 55                	jmp    f0100fe2 <page_init+0xad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f8d:	50                   	push   %eax
f0100f8e:	8d 86 d8 d4 fe ff    	lea    -0x12b28(%esi),%eax
f0100f94:	50                   	push   %eax
f0100f95:	68 13 01 00 00       	push   $0x113
f0100f9a:	8d 86 88 db fe ff    	lea    -0x12478(%esi),%eax
f0100fa0:	50                   	push   %eax
f0100fa1:	89 f3                	mov    %esi,%ebx
f0100fa3:	e8 f1 f0 ff ff       	call   f0100099 <_panic>
f0100fa8:	8d 04 cd 00 00 00 00 	lea    0x0(,%ecx,8),%eax
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
f0100faf:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100fb2:	89 c2                	mov    %eax,%edx
f0100fb4:	03 17                	add    (%edi),%edx
	return (pp - pages) << PGSHIFT;
f0100fb6:	89 c7                	mov    %eax,%edi
f0100fb8:	c1 e7 09             	shl    $0x9,%edi
f0100fbb:	39 7d dc             	cmp    %edi,-0x24(%ebp)
f0100fbe:	76 08                	jbe    f0100fc8 <page_init+0x93>
f0100fc0:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f0100fc6:	77 35                	ja     f0100ffd <page_init+0xc8>
			pages[i].pp_ref = 0;
f0100fc8:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100fce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fd1:	89 3a                	mov    %edi,(%edx)
			page_free_list = &pages[i];
f0100fd3:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100fd6:	03 02                	add    (%edx),%eax
f0100fd8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fdb:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
	for (i = 0; i < npages; i++)
f0100fdf:	83 c1 01             	add    $0x1,%ecx
f0100fe2:	39 0b                	cmp    %ecx,(%ebx)
f0100fe4:	76 25                	jbe    f010100b <page_init+0xd6>
		if(i==0){
f0100fe6:	85 c9                	test   %ecx,%ecx
f0100fe8:	75 be                	jne    f0100fa8 <page_init+0x73>
			pages[i].pp_ref = 1;
f0100fea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fed:	8b 00                	mov    (%eax),%eax
f0100fef:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100ff5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100ffb:	eb e2                	jmp    f0100fdf <page_init+0xaa>
			pages[i].pp_ref = 1;
f0100ffd:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0101003:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0101009:	eb d4                	jmp    f0100fdf <page_init+0xaa>
f010100b:	80 7d e3 00          	cmpb   $0x0,-0x1d(%ebp)
f010100f:	75 08                	jne    f0101019 <page_init+0xe4>
}
f0101011:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101014:	5b                   	pop    %ebx
f0101015:	5e                   	pop    %esi
f0101016:	5f                   	pop    %edi
f0101017:	5d                   	pop    %ebp
f0101018:	c3                   	ret    
f0101019:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010101c:	89 86 b0 1f 00 00    	mov    %eax,0x1fb0(%esi)
f0101022:	eb ed                	jmp    f0101011 <page_init+0xdc>

f0101024 <page_alloc>:
{
f0101024:	55                   	push   %ebp
f0101025:	89 e5                	mov    %esp,%ebp
f0101027:	56                   	push   %esi
f0101028:	53                   	push   %ebx
f0101029:	e8 21 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010102e:	81 c3 de 62 01 00    	add    $0x162de,%ebx
	if(page_free_list){
f0101034:	8b b3 b0 1f 00 00    	mov    0x1fb0(%ebx),%esi
f010103a:	85 f6                	test   %esi,%esi
f010103c:	74 14                	je     f0101052 <page_alloc+0x2e>
		page_free_list = freePage->pp_link;
f010103e:	8b 06                	mov    (%esi),%eax
f0101040:	89 83 b0 1f 00 00    	mov    %eax,0x1fb0(%ebx)
		freePage->pp_link = NULL;
f0101046:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if(alloc_flags&ALLOC_ZERO){    // 只有这个条件满足时才把内存页面初始化为0
f010104c:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101050:	75 09                	jne    f010105b <page_alloc+0x37>
}
f0101052:	89 f0                	mov    %esi,%eax
f0101054:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101057:	5b                   	pop    %ebx
f0101058:	5e                   	pop    %esi
f0101059:	5d                   	pop    %ebp
f010105a:	c3                   	ret    
f010105b:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101061:	89 f2                	mov    %esi,%edx
f0101063:	2b 10                	sub    (%eax),%edx
f0101065:	89 d0                	mov    %edx,%eax
f0101067:	c1 f8 03             	sar    $0x3,%eax
f010106a:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010106d:	89 c1                	mov    %eax,%ecx
f010106f:	c1 e9 0c             	shr    $0xc,%ecx
f0101072:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101078:	3b 0a                	cmp    (%edx),%ecx
f010107a:	73 1a                	jae    f0101096 <page_alloc+0x72>
			memset(page2kva(freePage), 0, PGSIZE);
f010107c:	83 ec 04             	sub    $0x4,%esp
f010107f:	68 00 10 00 00       	push   $0x1000
f0101084:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101086:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010108b:	50                   	push   %eax
f010108c:	e8 a7 2c 00 00       	call   f0103d38 <memset>
f0101091:	83 c4 10             	add    $0x10,%esp
f0101094:	eb bc                	jmp    f0101052 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101096:	50                   	push   %eax
f0101097:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f010109d:	50                   	push   %eax
f010109e:	6a 59                	push   $0x59
f01010a0:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f01010a6:	50                   	push   %eax
f01010a7:	e8 ed ef ff ff       	call   f0100099 <_panic>

f01010ac <page_free>:
{
f01010ac:	55                   	push   %ebp
f01010ad:	89 e5                	mov    %esp,%ebp
f01010af:	53                   	push   %ebx
f01010b0:	83 ec 04             	sub    $0x4,%esp
f01010b3:	e8 97 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01010b8:	81 c3 54 62 01 00    	add    $0x16254,%ebx
f01010be:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_ref||pp->pp_link){
f01010c1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010c6:	75 18                	jne    f01010e0 <page_free+0x34>
f01010c8:	83 38 00             	cmpl   $0x0,(%eax)
f01010cb:	75 13                	jne    f01010e0 <page_free+0x34>
	pp->pp_link = page_free_list;
f01010cd:	8b 8b b0 1f 00 00    	mov    0x1fb0(%ebx),%ecx
f01010d3:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01010d5:	89 83 b0 1f 00 00    	mov    %eax,0x1fb0(%ebx)
}
f01010db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010de:	c9                   	leave  
f01010df:	c3                   	ret    
		panic("Page is free, have not to free\n");
f01010e0:	83 ec 04             	sub    $0x4,%esp
f01010e3:	8d 83 fc d4 fe ff    	lea    -0x12b04(%ebx),%eax
f01010e9:	50                   	push   %eax
f01010ea:	68 4d 01 00 00       	push   $0x14d
f01010ef:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01010f5:	50                   	push   %eax
f01010f6:	e8 9e ef ff ff       	call   f0100099 <_panic>

f01010fb <page_decref>:
{
f01010fb:	55                   	push   %ebp
f01010fc:	89 e5                	mov    %esp,%ebp
f01010fe:	83 ec 08             	sub    $0x8,%esp
f0101101:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101104:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101108:	83 e8 01             	sub    $0x1,%eax
f010110b:	66 89 42 04          	mov    %ax,0x4(%edx)
f010110f:	66 85 c0             	test   %ax,%ax
f0101112:	74 02                	je     f0101116 <page_decref+0x1b>
}
f0101114:	c9                   	leave  
f0101115:	c3                   	ret    
		page_free(pp);
f0101116:	83 ec 0c             	sub    $0xc,%esp
f0101119:	52                   	push   %edx
f010111a:	e8 8d ff ff ff       	call   f01010ac <page_free>
f010111f:	83 c4 10             	add    $0x10,%esp
}
f0101122:	eb f0                	jmp    f0101114 <page_decref+0x19>

f0101124 <pgdir_walk>:
{
f0101124:	55                   	push   %ebp
f0101125:	89 e5                	mov    %esp,%ebp
f0101127:	57                   	push   %edi
f0101128:	56                   	push   %esi
f0101129:	53                   	push   %ebx
f010112a:	83 ec 0c             	sub    $0xc,%esp
f010112d:	e8 1d f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101132:	81 c3 da 61 01 00    	add    $0x161da,%ebx
f0101138:	8b 75 0c             	mov    0xc(%ebp),%esi
	size_t pgt_index = PTX(va);  // 页表索引
f010113b:	89 f7                	mov    %esi,%edi
f010113d:	c1 ef 0c             	shr    $0xc,%edi
f0101140:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
	size_t pgdir_index = PDX(va);  // 页目录索引
f0101146:	c1 ee 16             	shr    $0x16,%esi
	pde_t* pde = pgdir+pgdir_index;   // 页目录项指针
f0101149:	c1 e6 02             	shl    $0x2,%esi
f010114c:	03 75 08             	add    0x8(%ebp),%esi
	if (!*pde & PTE_P)
f010114f:	83 3e 00             	cmpl   $0x0,(%esi)
f0101152:	75 2f                	jne    f0101183 <pgdir_walk+0x5f>
		if(!create)
f0101154:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101158:	74 67                	je     f01011c1 <pgdir_walk+0x9d>
		struct PageInfo *new_page = page_alloc(1);
f010115a:	83 ec 0c             	sub    $0xc,%esp
f010115d:	6a 01                	push   $0x1
f010115f:	e8 c0 fe ff ff       	call   f0101024 <page_alloc>
		if(!new_page)
f0101164:	83 c4 10             	add    $0x10,%esp
f0101167:	85 c0                	test   %eax,%eax
f0101169:	74 5d                	je     f01011c8 <pgdir_walk+0xa4>
		new_page->pp_ref++;
f010116b:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101170:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101176:	2b 02                	sub    (%edx),%eax
f0101178:	c1 f8 03             	sar    $0x3,%eax
f010117b:	c1 e0 0c             	shl    $0xc,%eax
		*pde = page2pa(new_page) | PTE_P | PTE_W | PTE_U;   // 更新页目录项,为什么要设置 PTE_W  PTE_U 这两位?
f010117e:	83 c8 07             	or     $0x7,%eax
f0101181:	89 06                	mov    %eax,(%esi)
	pte = (pte_t *)KADDR(PTE_ADDR(*pde));
f0101183:	8b 06                	mov    (%esi),%eax
f0101185:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010118a:	89 c1                	mov    %eax,%ecx
f010118c:	c1 e9 0c             	shr    $0xc,%ecx
f010118f:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101195:	3b 0a                	cmp    (%edx),%ecx
f0101197:	73 0f                	jae    f01011a8 <pgdir_walk+0x84>
	return pte + pgt_index;    // 返回页表项的指针
f0101199:	8d 84 b8 00 00 00 f0 	lea    -0x10000000(%eax,%edi,4),%eax
}
f01011a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a3:	5b                   	pop    %ebx
f01011a4:	5e                   	pop    %esi
f01011a5:	5f                   	pop    %edi
f01011a6:	5d                   	pop    %ebp
f01011a7:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011a8:	50                   	push   %eax
f01011a9:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f01011af:	50                   	push   %eax
f01011b0:	68 8f 01 00 00       	push   $0x18f
f01011b5:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01011bb:	50                   	push   %eax
f01011bc:	e8 d8 ee ff ff       	call   f0100099 <_panic>
			return NULL;
f01011c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c6:	eb d8                	jmp    f01011a0 <pgdir_walk+0x7c>
			return NULL;
f01011c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01011cd:	eb d1                	jmp    f01011a0 <pgdir_walk+0x7c>

f01011cf <boot_map_region>:
{
f01011cf:	55                   	push   %ebp
f01011d0:	89 e5                	mov    %esp,%ebp
f01011d2:	57                   	push   %edi
f01011d3:	56                   	push   %esi
f01011d4:	53                   	push   %ebx
f01011d5:	83 ec 1c             	sub    $0x1c,%esp
f01011d8:	e8 bf 1e 00 00       	call   f010309c <__x86.get_pc_thunk.di>
f01011dd:	81 c7 2f 61 01 00    	add    $0x1612f,%edi
f01011e3:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01011e6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011e9:	8b 45 08             	mov    0x8(%ebp),%eax
	for (size_t i = 0; i < size/PGSIZE;++i){
f01011ec:	c1 e9 0c             	shr    $0xc,%ecx
f01011ef:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01011f2:	89 c3                	mov    %eax,%ebx
f01011f4:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t *pte = pgdir_walk(pgdir, (void*)va, 1);
f01011f9:	89 d7                	mov    %edx,%edi
f01011fb:	29 c7                	sub    %eax,%edi
		*pte = pa | perm | PTE_P;  // 要修改va对应的页表项，使其指向pa
f01011fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101200:	83 c8 01             	or     $0x1,%eax
f0101203:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (size_t i = 0; i < size/PGSIZE;++i){
f0101206:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f0101209:	74 48                	je     f0101253 <boot_map_region+0x84>
		pte_t *pte = pgdir_walk(pgdir, (void*)va, 1);
f010120b:	83 ec 04             	sub    $0x4,%esp
f010120e:	6a 01                	push   $0x1
f0101210:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0101213:	50                   	push   %eax
f0101214:	ff 75 e0             	pushl  -0x20(%ebp)
f0101217:	e8 08 ff ff ff       	call   f0101124 <pgdir_walk>
		if(!pte)
f010121c:	83 c4 10             	add    $0x10,%esp
f010121f:	85 c0                	test   %eax,%eax
f0101221:	74 12                	je     f0101235 <boot_map_region+0x66>
		*pte = pa | perm | PTE_P;  // 要修改va对应的页表项，使其指向pa
f0101223:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101226:	09 da                	or     %ebx,%edx
f0101228:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f010122a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (size_t i = 0; i < size/PGSIZE;++i){
f0101230:	83 c6 01             	add    $0x1,%esi
f0101233:	eb d1                	jmp    f0101206 <boot_map_region+0x37>
			panic("boot_map_region(): out of memory\n");
f0101235:	83 ec 04             	sub    $0x4,%esp
f0101238:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010123b:	8d 83 1c d5 fe ff    	lea    -0x12ae4(%ebx),%eax
f0101241:	50                   	push   %eax
f0101242:	68 a9 01 00 00       	push   $0x1a9
f0101247:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010124d:	50                   	push   %eax
f010124e:	e8 46 ee ff ff       	call   f0100099 <_panic>
}
f0101253:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101256:	5b                   	pop    %ebx
f0101257:	5e                   	pop    %esi
f0101258:	5f                   	pop    %edi
f0101259:	5d                   	pop    %ebp
f010125a:	c3                   	ret    

f010125b <page_lookup>:
{
f010125b:	55                   	push   %ebp
f010125c:	89 e5                	mov    %esp,%ebp
f010125e:	56                   	push   %esi
f010125f:	53                   	push   %ebx
f0101260:	e8 ea ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101265:	81 c3 a7 60 01 00    	add    $0x160a7,%ebx
f010126b:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);   // 只返回va对应的页表项，不分配新的页表页
f010126e:	83 ec 04             	sub    $0x4,%esp
f0101271:	6a 00                	push   $0x0
f0101273:	ff 75 0c             	pushl  0xc(%ebp)
f0101276:	ff 75 08             	pushl  0x8(%ebp)
f0101279:	e8 a6 fe ff ff       	call   f0101124 <pgdir_walk>
	if(pte_store){
f010127e:	83 c4 10             	add    $0x10,%esp
f0101281:	85 f6                	test   %esi,%esi
f0101283:	74 02                	je     f0101287 <page_lookup+0x2c>
		*pte_store = pte;
f0101285:	89 06                	mov    %eax,(%esi)
	if(pte){
f0101287:	85 c0                	test   %eax,%eax
f0101289:	74 39                	je     f01012c4 <page_lookup+0x69>
f010128b:	8b 00                	mov    (%eax),%eax
f010128d:	c1 e8 0c             	shr    $0xc,%eax

// pa为物理地址，PGNUM(pa)为该页的页号，函数功能与 page2pa 相反
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101290:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101296:	39 02                	cmp    %eax,(%edx)
f0101298:	76 12                	jbe    f01012ac <page_lookup+0x51>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010129a:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f01012a0:	8b 12                	mov    (%edx),%edx
f01012a2:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01012a5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012a8:	5b                   	pop    %ebx
f01012a9:	5e                   	pop    %esi
f01012aa:	5d                   	pop    %ebp
f01012ab:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01012ac:	83 ec 04             	sub    $0x4,%esp
f01012af:	8d 83 40 d5 fe ff    	lea    -0x12ac0(%ebx),%eax
f01012b5:	50                   	push   %eax
f01012b6:	6a 52                	push   $0x52
f01012b8:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f01012be:	50                   	push   %eax
f01012bf:	e8 d5 ed ff ff       	call   f0100099 <_panic>
	return NULL;
f01012c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01012c9:	eb da                	jmp    f01012a5 <page_lookup+0x4a>

f01012cb <page_remove>:
{
f01012cb:	55                   	push   %ebp
f01012cc:	89 e5                	mov    %esp,%ebp
f01012ce:	53                   	push   %ebx
f01012cf:	83 ec 18             	sub    $0x18,%esp
f01012d2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f01012d5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012d8:	50                   	push   %eax
f01012d9:	53                   	push   %ebx
f01012da:	ff 75 08             	pushl  0x8(%ebp)
f01012dd:	e8 79 ff ff ff       	call   f010125b <page_lookup>
	if (!pp)
f01012e2:	83 c4 10             	add    $0x10,%esp
f01012e5:	85 c0                	test   %eax,%eax
f01012e7:	75 05                	jne    f01012ee <page_remove+0x23>
}
f01012e9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012ec:	c9                   	leave  
f01012ed:	c3                   	ret    
	page_decref(pp);
f01012ee:	83 ec 0c             	sub    $0xc,%esp
f01012f1:	50                   	push   %eax
f01012f2:	e8 04 fe ff ff       	call   f01010fb <page_decref>
	*pte = 0;
f01012f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012fa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101300:	0f 01 3b             	invlpg (%ebx)
f0101303:	83 c4 10             	add    $0x10,%esp
f0101306:	eb e1                	jmp    f01012e9 <page_remove+0x1e>

f0101308 <page_insert>:
{
f0101308:	55                   	push   %ebp
f0101309:	89 e5                	mov    %esp,%ebp
f010130b:	57                   	push   %edi
f010130c:	56                   	push   %esi
f010130d:	53                   	push   %ebx
f010130e:	83 ec 10             	sub    $0x10,%esp
f0101311:	e8 86 1d 00 00       	call   f010309c <__x86.get_pc_thunk.di>
f0101316:	81 c7 f6 5f 01 00    	add    $0x15ff6,%edi
f010131c:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f010131f:	6a 01                	push   $0x1
f0101321:	ff 75 10             	pushl  0x10(%ebp)
f0101324:	ff 75 08             	pushl  0x8(%ebp)
f0101327:	e8 f8 fd ff ff       	call   f0101124 <pgdir_walk>
	if (!pte)
f010132c:	83 c4 10             	add    $0x10,%esp
f010132f:	85 c0                	test   %eax,%eax
f0101331:	74 4c                	je     f010137f <page_insert+0x77>
f0101333:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;   // 引用计数的增加必须在 page_remove 前面！！  this is an elegant way to handle
f0101335:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	pp->pp_link = NULL;
f010133a:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if(*pte&PTE_P){
f0101340:	f6 00 01             	testb  $0x1,(%eax)
f0101343:	75 27                	jne    f010136c <page_insert+0x64>
	return (pp - pages) << PGSHIFT;
f0101345:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010134b:	2b 30                	sub    (%eax),%esi
f010134d:	89 f0                	mov    %esi,%eax
f010134f:	c1 f8 03             	sar    $0x3,%eax
f0101352:	c1 e0 0c             	shl    $0xc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
f0101355:	8b 55 14             	mov    0x14(%ebp),%edx
f0101358:	83 ca 01             	or     $0x1,%edx
f010135b:	09 d0                	or     %edx,%eax
f010135d:	89 03                	mov    %eax,(%ebx)
	return 0;
f010135f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101364:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101367:	5b                   	pop    %ebx
f0101368:	5e                   	pop    %esi
f0101369:	5f                   	pop    %edi
f010136a:	5d                   	pop    %ebp
f010136b:	c3                   	ret    
		page_remove(pgdir, va);
f010136c:	83 ec 08             	sub    $0x8,%esp
f010136f:	ff 75 10             	pushl  0x10(%ebp)
f0101372:	ff 75 08             	pushl  0x8(%ebp)
f0101375:	e8 51 ff ff ff       	call   f01012cb <page_remove>
f010137a:	83 c4 10             	add    $0x10,%esp
f010137d:	eb c6                	jmp    f0101345 <page_insert+0x3d>
		return -E_NO_MEM;
f010137f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101384:	eb de                	jmp    f0101364 <page_insert+0x5c>

f0101386 <mem_init>:
{
f0101386:	55                   	push   %ebp
f0101387:	89 e5                	mov    %esp,%ebp
f0101389:	57                   	push   %edi
f010138a:	56                   	push   %esi
f010138b:	53                   	push   %ebx
f010138c:	83 ec 3c             	sub    $0x3c,%esp
f010138f:	e8 5d f3 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0101394:	05 78 5f 01 00       	add    $0x15f78,%eax
f0101399:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f010139c:	b8 15 00 00 00       	mov    $0x15,%eax
f01013a1:	e8 59 f7 ff ff       	call   f0100aff <nvram_read>
f01013a6:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01013a8:	b8 17 00 00 00       	mov    $0x17,%eax
f01013ad:	e8 4d f7 ff ff       	call   f0100aff <nvram_read>
f01013b2:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013b4:	b8 34 00 00 00       	mov    $0x34,%eax
f01013b9:	e8 41 f7 ff ff       	call   f0100aff <nvram_read>
f01013be:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01013c1:	85 c0                	test   %eax,%eax
f01013c3:	0f 85 c2 00 00 00    	jne    f010148b <mem_init+0x105>
		totalmem = 1 * 1024 + extmem;
f01013c9:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013cf:	85 f6                	test   %esi,%esi
f01013d1:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013d4:	89 c1                	mov    %eax,%ecx
f01013d6:	c1 e9 02             	shr    $0x2,%ecx
f01013d9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01013dc:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01013e2:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013e4:	89 c2                	mov    %eax,%edx
f01013e6:	29 da                	sub    %ebx,%edx
f01013e8:	52                   	push   %edx
f01013e9:	53                   	push   %ebx
f01013ea:	50                   	push   %eax
f01013eb:	8d 87 60 d5 fe ff    	lea    -0x12aa0(%edi),%eax
f01013f1:	50                   	push   %eax
f01013f2:	89 fb                	mov    %edi,%ebx
f01013f4:	e8 2e 1d 00 00       	call   f0103127 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);    // 初始占一整页
f01013f9:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013fe:	e8 a3 f6 ff ff       	call   f0100aa6 <boot_alloc>
f0101403:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f0101409:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);   // 初始化为0
f010140b:	83 c4 0c             	add    $0xc,%esp
f010140e:	68 00 10 00 00       	push   $0x1000
f0101413:	6a 00                	push   $0x0
f0101415:	50                   	push   %eax
f0101416:	e8 1d 29 00 00       	call   f0103d38 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010141b:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010141d:	83 c4 10             	add    $0x10,%esp
f0101420:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101425:	76 6e                	jbe    f0101495 <mem_init+0x10f>
	return (physaddr_t)kva - KERNBASE;
f0101427:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010142d:	83 ca 05             	or     $0x5,%edx
f0101430:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101436:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101439:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f010143f:	8b 03                	mov    (%ebx),%eax
f0101441:	c1 e0 03             	shl    $0x3,%eax
f0101444:	e8 5d f6 ff ff       	call   f0100aa6 <boot_alloc>
f0101449:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f010144f:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101451:	83 ec 04             	sub    $0x4,%esp
f0101454:	8b 13                	mov    (%ebx),%edx
f0101456:	c1 e2 03             	shl    $0x3,%edx
f0101459:	52                   	push   %edx
f010145a:	6a 00                	push   $0x0
f010145c:	50                   	push   %eax
f010145d:	89 fb                	mov    %edi,%ebx
f010145f:	e8 d4 28 00 00       	call   f0103d38 <memset>
	page_init();
f0101464:	e8 cc fa ff ff       	call   f0100f35 <page_init>
	check_page_free_list(1);
f0101469:	b8 01 00 00 00       	mov    $0x1,%eax
f010146e:	e8 3f f7 ff ff       	call   f0100bb2 <check_page_free_list>
	if (!pages)
f0101473:	83 c4 10             	add    $0x10,%esp
f0101476:	83 3e 00             	cmpl   $0x0,(%esi)
f0101479:	74 36                	je     f01014b1 <mem_init+0x12b>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010147b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010147e:	8b 80 b0 1f 00 00    	mov    0x1fb0(%eax),%eax
f0101484:	be 00 00 00 00       	mov    $0x0,%esi
f0101489:	eb 49                	jmp    f01014d4 <mem_init+0x14e>
		totalmem = 16 * 1024 + ext16mem;
f010148b:	05 00 40 00 00       	add    $0x4000,%eax
f0101490:	e9 3f ff ff ff       	jmp    f01013d4 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101495:	50                   	push   %eax
f0101496:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101499:	8d 83 d8 d4 fe ff    	lea    -0x12b28(%ebx),%eax
f010149f:	50                   	push   %eax
f01014a0:	68 9b 00 00 00       	push   $0x9b
f01014a5:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01014ab:	50                   	push   %eax
f01014ac:	e8 e8 eb ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f01014b1:	83 ec 04             	sub    $0x4,%esp
f01014b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01014b7:	8d 83 3e dc fe ff    	lea    -0x123c2(%ebx),%eax
f01014bd:	50                   	push   %eax
f01014be:	68 77 02 00 00       	push   $0x277
f01014c3:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01014c9:	50                   	push   %eax
f01014ca:	e8 ca eb ff ff       	call   f0100099 <_panic>
		++nfree;
f01014cf:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014d2:	8b 00                	mov    (%eax),%eax
f01014d4:	85 c0                	test   %eax,%eax
f01014d6:	75 f7                	jne    f01014cf <mem_init+0x149>
	assert((pp0 = page_alloc(0)));
f01014d8:	83 ec 0c             	sub    $0xc,%esp
f01014db:	6a 00                	push   $0x0
f01014dd:	e8 42 fb ff ff       	call   f0101024 <page_alloc>
f01014e2:	89 c3                	mov    %eax,%ebx
f01014e4:	83 c4 10             	add    $0x10,%esp
f01014e7:	85 c0                	test   %eax,%eax
f01014e9:	0f 84 3b 02 00 00    	je     f010172a <mem_init+0x3a4>
	assert((pp1 = page_alloc(0)));
f01014ef:	83 ec 0c             	sub    $0xc,%esp
f01014f2:	6a 00                	push   $0x0
f01014f4:	e8 2b fb ff ff       	call   f0101024 <page_alloc>
f01014f9:	89 c7                	mov    %eax,%edi
f01014fb:	83 c4 10             	add    $0x10,%esp
f01014fe:	85 c0                	test   %eax,%eax
f0101500:	0f 84 46 02 00 00    	je     f010174c <mem_init+0x3c6>
	assert((pp2 = page_alloc(0)));
f0101506:	83 ec 0c             	sub    $0xc,%esp
f0101509:	6a 00                	push   $0x0
f010150b:	e8 14 fb ff ff       	call   f0101024 <page_alloc>
f0101510:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101513:	83 c4 10             	add    $0x10,%esp
f0101516:	85 c0                	test   %eax,%eax
f0101518:	0f 84 50 02 00 00    	je     f010176e <mem_init+0x3e8>
	assert(pp1 && pp1 != pp0);
f010151e:	39 fb                	cmp    %edi,%ebx
f0101520:	0f 84 6a 02 00 00    	je     f0101790 <mem_init+0x40a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101526:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101529:	39 c3                	cmp    %eax,%ebx
f010152b:	0f 84 81 02 00 00    	je     f01017b2 <mem_init+0x42c>
f0101531:	39 c7                	cmp    %eax,%edi
f0101533:	0f 84 79 02 00 00    	je     f01017b2 <mem_init+0x42c>
	return (pp - pages) << PGSHIFT;
f0101539:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010153c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101542:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101544:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f010154a:	8b 10                	mov    (%eax),%edx
f010154c:	c1 e2 0c             	shl    $0xc,%edx
f010154f:	89 d8                	mov    %ebx,%eax
f0101551:	29 c8                	sub    %ecx,%eax
f0101553:	c1 f8 03             	sar    $0x3,%eax
f0101556:	c1 e0 0c             	shl    $0xc,%eax
f0101559:	39 d0                	cmp    %edx,%eax
f010155b:	0f 83 73 02 00 00    	jae    f01017d4 <mem_init+0x44e>
f0101561:	89 f8                	mov    %edi,%eax
f0101563:	29 c8                	sub    %ecx,%eax
f0101565:	c1 f8 03             	sar    $0x3,%eax
f0101568:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010156b:	39 c2                	cmp    %eax,%edx
f010156d:	0f 86 83 02 00 00    	jbe    f01017f6 <mem_init+0x470>
f0101573:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101576:	29 c8                	sub    %ecx,%eax
f0101578:	c1 f8 03             	sar    $0x3,%eax
f010157b:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010157e:	39 c2                	cmp    %eax,%edx
f0101580:	0f 86 92 02 00 00    	jbe    f0101818 <mem_init+0x492>
	fl = page_free_list;
f0101586:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101589:	8b 88 b0 1f 00 00    	mov    0x1fb0(%eax),%ecx
f010158f:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101592:	c7 80 b0 1f 00 00 00 	movl   $0x0,0x1fb0(%eax)
f0101599:	00 00 00 
	assert(!page_alloc(0));
f010159c:	83 ec 0c             	sub    $0xc,%esp
f010159f:	6a 00                	push   $0x0
f01015a1:	e8 7e fa ff ff       	call   f0101024 <page_alloc>
f01015a6:	83 c4 10             	add    $0x10,%esp
f01015a9:	85 c0                	test   %eax,%eax
f01015ab:	0f 85 89 02 00 00    	jne    f010183a <mem_init+0x4b4>
	page_free(pp0);
f01015b1:	83 ec 0c             	sub    $0xc,%esp
f01015b4:	53                   	push   %ebx
f01015b5:	e8 f2 fa ff ff       	call   f01010ac <page_free>
	page_free(pp1);
f01015ba:	89 3c 24             	mov    %edi,(%esp)
f01015bd:	e8 ea fa ff ff       	call   f01010ac <page_free>
	page_free(pp2);
f01015c2:	83 c4 04             	add    $0x4,%esp
f01015c5:	ff 75 d0             	pushl  -0x30(%ebp)
f01015c8:	e8 df fa ff ff       	call   f01010ac <page_free>
	assert((pp0 = page_alloc(0)));
f01015cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015d4:	e8 4b fa ff ff       	call   f0101024 <page_alloc>
f01015d9:	89 c7                	mov    %eax,%edi
f01015db:	83 c4 10             	add    $0x10,%esp
f01015de:	85 c0                	test   %eax,%eax
f01015e0:	0f 84 76 02 00 00    	je     f010185c <mem_init+0x4d6>
	assert((pp1 = page_alloc(0)));
f01015e6:	83 ec 0c             	sub    $0xc,%esp
f01015e9:	6a 00                	push   $0x0
f01015eb:	e8 34 fa ff ff       	call   f0101024 <page_alloc>
f01015f0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015f3:	83 c4 10             	add    $0x10,%esp
f01015f6:	85 c0                	test   %eax,%eax
f01015f8:	0f 84 80 02 00 00    	je     f010187e <mem_init+0x4f8>
	assert((pp2 = page_alloc(0)));
f01015fe:	83 ec 0c             	sub    $0xc,%esp
f0101601:	6a 00                	push   $0x0
f0101603:	e8 1c fa ff ff       	call   f0101024 <page_alloc>
f0101608:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010160b:	83 c4 10             	add    $0x10,%esp
f010160e:	85 c0                	test   %eax,%eax
f0101610:	0f 84 8a 02 00 00    	je     f01018a0 <mem_init+0x51a>
	assert(pp1 && pp1 != pp0);
f0101616:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f0101619:	0f 84 a3 02 00 00    	je     f01018c2 <mem_init+0x53c>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010161f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101622:	39 c7                	cmp    %eax,%edi
f0101624:	0f 84 ba 02 00 00    	je     f01018e4 <mem_init+0x55e>
f010162a:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010162d:	0f 84 b1 02 00 00    	je     f01018e4 <mem_init+0x55e>
	assert(!page_alloc(0));
f0101633:	83 ec 0c             	sub    $0xc,%esp
f0101636:	6a 00                	push   $0x0
f0101638:	e8 e7 f9 ff ff       	call   f0101024 <page_alloc>
f010163d:	83 c4 10             	add    $0x10,%esp
f0101640:	85 c0                	test   %eax,%eax
f0101642:	0f 85 be 02 00 00    	jne    f0101906 <mem_init+0x580>
f0101648:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010164b:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101651:	89 f9                	mov    %edi,%ecx
f0101653:	2b 08                	sub    (%eax),%ecx
f0101655:	89 c8                	mov    %ecx,%eax
f0101657:	c1 f8 03             	sar    $0x3,%eax
f010165a:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010165d:	89 c1                	mov    %eax,%ecx
f010165f:	c1 e9 0c             	shr    $0xc,%ecx
f0101662:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101668:	3b 0a                	cmp    (%edx),%ecx
f010166a:	0f 83 b8 02 00 00    	jae    f0101928 <mem_init+0x5a2>
	memset(page2kva(pp0), 1, PGSIZE);
f0101670:	83 ec 04             	sub    $0x4,%esp
f0101673:	68 00 10 00 00       	push   $0x1000
f0101678:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010167a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010167f:	50                   	push   %eax
f0101680:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101683:	e8 b0 26 00 00       	call   f0103d38 <memset>
	page_free(pp0);
f0101688:	89 3c 24             	mov    %edi,(%esp)
f010168b:	e8 1c fa ff ff       	call   f01010ac <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101690:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101697:	e8 88 f9 ff ff       	call   f0101024 <page_alloc>
f010169c:	83 c4 10             	add    $0x10,%esp
f010169f:	85 c0                	test   %eax,%eax
f01016a1:	0f 84 97 02 00 00    	je     f010193e <mem_init+0x5b8>
	assert(pp && pp0 == pp);
f01016a7:	39 c7                	cmp    %eax,%edi
f01016a9:	0f 85 b1 02 00 00    	jne    f0101960 <mem_init+0x5da>
	return (pp - pages) << PGSHIFT;
f01016af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016b2:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01016b8:	89 fa                	mov    %edi,%edx
f01016ba:	2b 10                	sub    (%eax),%edx
f01016bc:	c1 fa 03             	sar    $0x3,%edx
f01016bf:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016c2:	89 d1                	mov    %edx,%ecx
f01016c4:	c1 e9 0c             	shr    $0xc,%ecx
f01016c7:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01016cd:	3b 08                	cmp    (%eax),%ecx
f01016cf:	0f 83 ad 02 00 00    	jae    f0101982 <mem_init+0x5fc>
	return (void *)(pa + KERNBASE);
f01016d5:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01016db:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01016e1:	80 38 00             	cmpb   $0x0,(%eax)
f01016e4:	0f 85 ae 02 00 00    	jne    f0101998 <mem_init+0x612>
f01016ea:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016ed:	39 d0                	cmp    %edx,%eax
f01016ef:	75 f0                	jne    f01016e1 <mem_init+0x35b>
	page_free_list = fl;
f01016f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016f4:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01016f7:	89 8b b0 1f 00 00    	mov    %ecx,0x1fb0(%ebx)
	page_free(pp0);
f01016fd:	83 ec 0c             	sub    $0xc,%esp
f0101700:	57                   	push   %edi
f0101701:	e8 a6 f9 ff ff       	call   f01010ac <page_free>
	page_free(pp1);
f0101706:	83 c4 04             	add    $0x4,%esp
f0101709:	ff 75 d0             	pushl  -0x30(%ebp)
f010170c:	e8 9b f9 ff ff       	call   f01010ac <page_free>
	page_free(pp2);
f0101711:	83 c4 04             	add    $0x4,%esp
f0101714:	ff 75 cc             	pushl  -0x34(%ebp)
f0101717:	e8 90 f9 ff ff       	call   f01010ac <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010171c:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
f0101722:	83 c4 10             	add    $0x10,%esp
f0101725:	e9 95 02 00 00       	jmp    f01019bf <mem_init+0x639>
	assert((pp0 = page_alloc(0)));
f010172a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010172d:	8d 83 59 dc fe ff    	lea    -0x123a7(%ebx),%eax
f0101733:	50                   	push   %eax
f0101734:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010173a:	50                   	push   %eax
f010173b:	68 7f 02 00 00       	push   $0x27f
f0101740:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0101746:	50                   	push   %eax
f0101747:	e8 4d e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010174c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010174f:	8d 83 6f dc fe ff    	lea    -0x12391(%ebx),%eax
f0101755:	50                   	push   %eax
f0101756:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010175c:	50                   	push   %eax
f010175d:	68 80 02 00 00       	push   $0x280
f0101762:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0101768:	50                   	push   %eax
f0101769:	e8 2b e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010176e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101771:	8d 83 85 dc fe ff    	lea    -0x1237b(%ebx),%eax
f0101777:	50                   	push   %eax
f0101778:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010177e:	50                   	push   %eax
f010177f:	68 81 02 00 00       	push   $0x281
f0101784:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010178a:	50                   	push   %eax
f010178b:	e8 09 e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101790:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101793:	8d 83 9b dc fe ff    	lea    -0x12365(%ebx),%eax
f0101799:	50                   	push   %eax
f010179a:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01017a0:	50                   	push   %eax
f01017a1:	68 84 02 00 00       	push   $0x284
f01017a6:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01017ac:	50                   	push   %eax
f01017ad:	e8 e7 e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017b5:	8d 83 9c d5 fe ff    	lea    -0x12a64(%ebx),%eax
f01017bb:	50                   	push   %eax
f01017bc:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01017c2:	50                   	push   %eax
f01017c3:	68 85 02 00 00       	push   $0x285
f01017c8:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01017ce:	50                   	push   %eax
f01017cf:	e8 c5 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01017d4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017d7:	8d 83 ad dc fe ff    	lea    -0x12353(%ebx),%eax
f01017dd:	50                   	push   %eax
f01017de:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01017e4:	50                   	push   %eax
f01017e5:	68 86 02 00 00       	push   $0x286
f01017ea:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01017f0:	50                   	push   %eax
f01017f1:	e8 a3 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01017f6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017f9:	8d 83 ca dc fe ff    	lea    -0x12336(%ebx),%eax
f01017ff:	50                   	push   %eax
f0101800:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0101806:	50                   	push   %eax
f0101807:	68 87 02 00 00       	push   $0x287
f010180c:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0101812:	50                   	push   %eax
f0101813:	e8 81 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101818:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010181b:	8d 83 e7 dc fe ff    	lea    -0x12319(%ebx),%eax
f0101821:	50                   	push   %eax
f0101822:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0101828:	50                   	push   %eax
f0101829:	68 88 02 00 00       	push   $0x288
f010182e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0101834:	50                   	push   %eax
f0101835:	e8 5f e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010183a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010183d:	8d 83 04 dd fe ff    	lea    -0x122fc(%ebx),%eax
f0101843:	50                   	push   %eax
f0101844:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010184a:	50                   	push   %eax
f010184b:	68 8f 02 00 00       	push   $0x28f
f0101850:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0101856:	50                   	push   %eax
f0101857:	e8 3d e8 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010185c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010185f:	8d 83 59 dc fe ff    	lea    -0x123a7(%ebx),%eax
f0101865:	50                   	push   %eax
f0101866:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010186c:	50                   	push   %eax
f010186d:	68 96 02 00 00       	push   $0x296
f0101872:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0101878:	50                   	push   %eax
f0101879:	e8 1b e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010187e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101881:	8d 83 6f dc fe ff    	lea    -0x12391(%ebx),%eax
f0101887:	50                   	push   %eax
f0101888:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010188e:	50                   	push   %eax
f010188f:	68 97 02 00 00       	push   $0x297
f0101894:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010189a:	50                   	push   %eax
f010189b:	e8 f9 e7 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01018a0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018a3:	8d 83 85 dc fe ff    	lea    -0x1237b(%ebx),%eax
f01018a9:	50                   	push   %eax
f01018aa:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01018b0:	50                   	push   %eax
f01018b1:	68 98 02 00 00       	push   $0x298
f01018b6:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01018bc:	50                   	push   %eax
f01018bd:	e8 d7 e7 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01018c2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018c5:	8d 83 9b dc fe ff    	lea    -0x12365(%ebx),%eax
f01018cb:	50                   	push   %eax
f01018cc:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01018d2:	50                   	push   %eax
f01018d3:	68 9a 02 00 00       	push   $0x29a
f01018d8:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01018de:	50                   	push   %eax
f01018df:	e8 b5 e7 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018e4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018e7:	8d 83 9c d5 fe ff    	lea    -0x12a64(%ebx),%eax
f01018ed:	50                   	push   %eax
f01018ee:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01018f4:	50                   	push   %eax
f01018f5:	68 9b 02 00 00       	push   $0x29b
f01018fa:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0101900:	50                   	push   %eax
f0101901:	e8 93 e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101906:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101909:	8d 83 04 dd fe ff    	lea    -0x122fc(%ebx),%eax
f010190f:	50                   	push   %eax
f0101910:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0101916:	50                   	push   %eax
f0101917:	68 9c 02 00 00       	push   $0x29c
f010191c:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0101922:	50                   	push   %eax
f0101923:	e8 71 e7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101928:	50                   	push   %eax
f0101929:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f010192f:	50                   	push   %eax
f0101930:	6a 59                	push   $0x59
f0101932:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f0101938:	50                   	push   %eax
f0101939:	e8 5b e7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010193e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101941:	8d 83 13 dd fe ff    	lea    -0x122ed(%ebx),%eax
f0101947:	50                   	push   %eax
f0101948:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010194e:	50                   	push   %eax
f010194f:	68 a1 02 00 00       	push   $0x2a1
f0101954:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010195a:	50                   	push   %eax
f010195b:	e8 39 e7 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101960:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101963:	8d 83 31 dd fe ff    	lea    -0x122cf(%ebx),%eax
f0101969:	50                   	push   %eax
f010196a:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0101970:	50                   	push   %eax
f0101971:	68 a2 02 00 00       	push   $0x2a2
f0101976:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010197c:	50                   	push   %eax
f010197d:	e8 17 e7 ff ff       	call   f0100099 <_panic>
f0101982:	52                   	push   %edx
f0101983:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f0101989:	50                   	push   %eax
f010198a:	6a 59                	push   $0x59
f010198c:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f0101992:	50                   	push   %eax
f0101993:	e8 01 e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101998:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010199b:	8d 83 41 dd fe ff    	lea    -0x122bf(%ebx),%eax
f01019a1:	50                   	push   %eax
f01019a2:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01019a8:	50                   	push   %eax
f01019a9:	68 a5 02 00 00       	push   $0x2a5
f01019ae:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01019b4:	50                   	push   %eax
f01019b5:	e8 df e6 ff ff       	call   f0100099 <_panic>
		--nfree;
f01019ba:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01019bd:	8b 00                	mov    (%eax),%eax
f01019bf:	85 c0                	test   %eax,%eax
f01019c1:	75 f7                	jne    f01019ba <mem_init+0x634>
	assert(nfree == 0);
f01019c3:	85 f6                	test   %esi,%esi
f01019c5:	0f 85 5b 08 00 00    	jne    f0102226 <mem_init+0xea0>
	cprintf("check_page_alloc() succeeded!\n");
f01019cb:	83 ec 0c             	sub    $0xc,%esp
f01019ce:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019d1:	8d 83 bc d5 fe ff    	lea    -0x12a44(%ebx),%eax
f01019d7:	50                   	push   %eax
f01019d8:	e8 4a 17 00 00       	call   f0103127 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019dd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019e4:	e8 3b f6 ff ff       	call   f0101024 <page_alloc>
f01019e9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019ec:	83 c4 10             	add    $0x10,%esp
f01019ef:	85 c0                	test   %eax,%eax
f01019f1:	0f 84 51 08 00 00    	je     f0102248 <mem_init+0xec2>
	assert((pp1 = page_alloc(0)));
f01019f7:	83 ec 0c             	sub    $0xc,%esp
f01019fa:	6a 00                	push   $0x0
f01019fc:	e8 23 f6 ff ff       	call   f0101024 <page_alloc>
f0101a01:	89 c7                	mov    %eax,%edi
f0101a03:	83 c4 10             	add    $0x10,%esp
f0101a06:	85 c0                	test   %eax,%eax
f0101a08:	0f 84 5c 08 00 00    	je     f010226a <mem_init+0xee4>
	assert((pp2 = page_alloc(0)));
f0101a0e:	83 ec 0c             	sub    $0xc,%esp
f0101a11:	6a 00                	push   $0x0
f0101a13:	e8 0c f6 ff ff       	call   f0101024 <page_alloc>
f0101a18:	89 c6                	mov    %eax,%esi
f0101a1a:	83 c4 10             	add    $0x10,%esp
f0101a1d:	85 c0                	test   %eax,%eax
f0101a1f:	0f 84 67 08 00 00    	je     f010228c <mem_init+0xf06>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a25:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101a28:	0f 84 80 08 00 00    	je     f01022ae <mem_init+0xf28>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a2e:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101a31:	0f 84 99 08 00 00    	je     f01022d0 <mem_init+0xf4a>
f0101a37:	39 c7                	cmp    %eax,%edi
f0101a39:	0f 84 91 08 00 00    	je     f01022d0 <mem_init+0xf4a>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a3f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a42:	8b 88 b0 1f 00 00    	mov    0x1fb0(%eax),%ecx
f0101a48:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101a4b:	c7 80 b0 1f 00 00 00 	movl   $0x0,0x1fb0(%eax)
f0101a52:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a55:	83 ec 0c             	sub    $0xc,%esp
f0101a58:	6a 00                	push   $0x0
f0101a5a:	e8 c5 f5 ff ff       	call   f0101024 <page_alloc>
f0101a5f:	83 c4 10             	add    $0x10,%esp
f0101a62:	85 c0                	test   %eax,%eax
f0101a64:	0f 85 88 08 00 00    	jne    f01022f2 <mem_init+0xf6c>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a6a:	83 ec 04             	sub    $0x4,%esp
f0101a6d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a70:	50                   	push   %eax
f0101a71:	6a 00                	push   $0x0
f0101a73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a76:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a7c:	ff 30                	pushl  (%eax)
f0101a7e:	e8 d8 f7 ff ff       	call   f010125b <page_lookup>
f0101a83:	83 c4 10             	add    $0x10,%esp
f0101a86:	85 c0                	test   %eax,%eax
f0101a88:	0f 85 86 08 00 00    	jne    f0102314 <mem_init+0xf8e>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a8e:	6a 02                	push   $0x2
f0101a90:	6a 00                	push   $0x0
f0101a92:	57                   	push   %edi
f0101a93:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a96:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a9c:	ff 30                	pushl  (%eax)
f0101a9e:	e8 65 f8 ff ff       	call   f0101308 <page_insert>
f0101aa3:	83 c4 10             	add    $0x10,%esp
f0101aa6:	85 c0                	test   %eax,%eax
f0101aa8:	0f 89 88 08 00 00    	jns    f0102336 <mem_init+0xfb0>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101aae:	83 ec 0c             	sub    $0xc,%esp
f0101ab1:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ab4:	e8 f3 f5 ff ff       	call   f01010ac <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101ab9:	6a 02                	push   $0x2
f0101abb:	6a 00                	push   $0x0
f0101abd:	57                   	push   %edi
f0101abe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac1:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ac7:	ff 30                	pushl  (%eax)
f0101ac9:	e8 3a f8 ff ff       	call   f0101308 <page_insert>
f0101ace:	83 c4 20             	add    $0x20,%esp
f0101ad1:	85 c0                	test   %eax,%eax
f0101ad3:	0f 85 7f 08 00 00    	jne    f0102358 <mem_init+0xfd2>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ad9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101adc:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ae2:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101ae4:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101aea:	8b 08                	mov    (%eax),%ecx
f0101aec:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101aef:	8b 13                	mov    (%ebx),%edx
f0101af1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101af7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101afa:	29 c8                	sub    %ecx,%eax
f0101afc:	c1 f8 03             	sar    $0x3,%eax
f0101aff:	c1 e0 0c             	shl    $0xc,%eax
f0101b02:	39 c2                	cmp    %eax,%edx
f0101b04:	0f 85 70 08 00 00    	jne    f010237a <mem_init+0xff4>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b0a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b0f:	89 d8                	mov    %ebx,%eax
f0101b11:	e8 1f f0 ff ff       	call   f0100b35 <check_va2pa>
f0101b16:	89 fa                	mov    %edi,%edx
f0101b18:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b1b:	c1 fa 03             	sar    $0x3,%edx
f0101b1e:	c1 e2 0c             	shl    $0xc,%edx
f0101b21:	39 d0                	cmp    %edx,%eax
f0101b23:	0f 85 73 08 00 00    	jne    f010239c <mem_init+0x1016>
	assert(pp1->pp_ref == 1);
f0101b29:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b2e:	0f 85 8a 08 00 00    	jne    f01023be <mem_init+0x1038>
	assert(pp0->pp_ref == 1);
f0101b34:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b37:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b3c:	0f 85 9e 08 00 00    	jne    f01023e0 <mem_init+0x105a>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b42:	6a 02                	push   $0x2
f0101b44:	68 00 10 00 00       	push   $0x1000
f0101b49:	56                   	push   %esi
f0101b4a:	53                   	push   %ebx
f0101b4b:	e8 b8 f7 ff ff       	call   f0101308 <page_insert>
f0101b50:	83 c4 10             	add    $0x10,%esp
f0101b53:	85 c0                	test   %eax,%eax
f0101b55:	0f 85 a7 08 00 00    	jne    f0102402 <mem_init+0x107c>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b5b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b60:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b63:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b69:	8b 00                	mov    (%eax),%eax
f0101b6b:	e8 c5 ef ff ff       	call   f0100b35 <check_va2pa>
f0101b70:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101b76:	89 f1                	mov    %esi,%ecx
f0101b78:	2b 0a                	sub    (%edx),%ecx
f0101b7a:	89 ca                	mov    %ecx,%edx
f0101b7c:	c1 fa 03             	sar    $0x3,%edx
f0101b7f:	c1 e2 0c             	shl    $0xc,%edx
f0101b82:	39 d0                	cmp    %edx,%eax
f0101b84:	0f 85 9a 08 00 00    	jne    f0102424 <mem_init+0x109e>
	assert(pp2->pp_ref == 1);
f0101b8a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b8f:	0f 85 b1 08 00 00    	jne    f0102446 <mem_init+0x10c0>

	// should be no free memory
	assert(!page_alloc(0));
f0101b95:	83 ec 0c             	sub    $0xc,%esp
f0101b98:	6a 00                	push   $0x0
f0101b9a:	e8 85 f4 ff ff       	call   f0101024 <page_alloc>
f0101b9f:	83 c4 10             	add    $0x10,%esp
f0101ba2:	85 c0                	test   %eax,%eax
f0101ba4:	0f 85 be 08 00 00    	jne    f0102468 <mem_init+0x10e2>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101baa:	6a 02                	push   $0x2
f0101bac:	68 00 10 00 00       	push   $0x1000
f0101bb1:	56                   	push   %esi
f0101bb2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bb5:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bbb:	ff 30                	pushl  (%eax)
f0101bbd:	e8 46 f7 ff ff       	call   f0101308 <page_insert>
f0101bc2:	83 c4 10             	add    $0x10,%esp
f0101bc5:	85 c0                	test   %eax,%eax
f0101bc7:	0f 85 bd 08 00 00    	jne    f010248a <mem_init+0x1104>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bcd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bd2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101bd5:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bdb:	8b 00                	mov    (%eax),%eax
f0101bdd:	e8 53 ef ff ff       	call   f0100b35 <check_va2pa>
f0101be2:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101be8:	89 f1                	mov    %esi,%ecx
f0101bea:	2b 0a                	sub    (%edx),%ecx
f0101bec:	89 ca                	mov    %ecx,%edx
f0101bee:	c1 fa 03             	sar    $0x3,%edx
f0101bf1:	c1 e2 0c             	shl    $0xc,%edx
f0101bf4:	39 d0                	cmp    %edx,%eax
f0101bf6:	0f 85 b0 08 00 00    	jne    f01024ac <mem_init+0x1126>
	assert(pp2->pp_ref == 1);
f0101bfc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c01:	0f 85 c7 08 00 00    	jne    f01024ce <mem_init+0x1148>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c07:	83 ec 0c             	sub    $0xc,%esp
f0101c0a:	6a 00                	push   $0x0
f0101c0c:	e8 13 f4 ff ff       	call   f0101024 <page_alloc>
f0101c11:	83 c4 10             	add    $0x10,%esp
f0101c14:	85 c0                	test   %eax,%eax
f0101c16:	0f 85 d4 08 00 00    	jne    f01024f0 <mem_init+0x116a>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c1c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c1f:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c25:	8b 10                	mov    (%eax),%edx
f0101c27:	8b 02                	mov    (%edx),%eax
f0101c29:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101c2e:	89 c3                	mov    %eax,%ebx
f0101c30:	c1 eb 0c             	shr    $0xc,%ebx
f0101c33:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101c39:	3b 19                	cmp    (%ecx),%ebx
f0101c3b:	0f 83 d1 08 00 00    	jae    f0102512 <mem_init+0x118c>
	return (void *)(pa + KERNBASE);
f0101c41:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c46:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c49:	83 ec 04             	sub    $0x4,%esp
f0101c4c:	6a 00                	push   $0x0
f0101c4e:	68 00 10 00 00       	push   $0x1000
f0101c53:	52                   	push   %edx
f0101c54:	e8 cb f4 ff ff       	call   f0101124 <pgdir_walk>
f0101c59:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c5c:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c5f:	83 c4 10             	add    $0x10,%esp
f0101c62:	39 d0                	cmp    %edx,%eax
f0101c64:	0f 85 c4 08 00 00    	jne    f010252e <mem_init+0x11a8>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c6a:	6a 06                	push   $0x6
f0101c6c:	68 00 10 00 00       	push   $0x1000
f0101c71:	56                   	push   %esi
f0101c72:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c75:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c7b:	ff 30                	pushl  (%eax)
f0101c7d:	e8 86 f6 ff ff       	call   f0101308 <page_insert>
f0101c82:	83 c4 10             	add    $0x10,%esp
f0101c85:	85 c0                	test   %eax,%eax
f0101c87:	0f 85 c3 08 00 00    	jne    f0102550 <mem_init+0x11ca>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c8d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c90:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c96:	8b 18                	mov    (%eax),%ebx
f0101c98:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c9d:	89 d8                	mov    %ebx,%eax
f0101c9f:	e8 91 ee ff ff       	call   f0100b35 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101ca4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ca7:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101cad:	89 f1                	mov    %esi,%ecx
f0101caf:	2b 0a                	sub    (%edx),%ecx
f0101cb1:	89 ca                	mov    %ecx,%edx
f0101cb3:	c1 fa 03             	sar    $0x3,%edx
f0101cb6:	c1 e2 0c             	shl    $0xc,%edx
f0101cb9:	39 d0                	cmp    %edx,%eax
f0101cbb:	0f 85 b1 08 00 00    	jne    f0102572 <mem_init+0x11ec>
	assert(pp2->pp_ref == 1);
f0101cc1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cc6:	0f 85 c8 08 00 00    	jne    f0102594 <mem_init+0x120e>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ccc:	83 ec 04             	sub    $0x4,%esp
f0101ccf:	6a 00                	push   $0x0
f0101cd1:	68 00 10 00 00       	push   $0x1000
f0101cd6:	53                   	push   %ebx
f0101cd7:	e8 48 f4 ff ff       	call   f0101124 <pgdir_walk>
f0101cdc:	83 c4 10             	add    $0x10,%esp
f0101cdf:	f6 00 04             	testb  $0x4,(%eax)
f0101ce2:	0f 84 ce 08 00 00    	je     f01025b6 <mem_init+0x1230>
	assert(kern_pgdir[0] & PTE_U);
f0101ce8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ceb:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cf1:	8b 00                	mov    (%eax),%eax
f0101cf3:	f6 00 04             	testb  $0x4,(%eax)
f0101cf6:	0f 84 dc 08 00 00    	je     f01025d8 <mem_init+0x1252>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cfc:	6a 02                	push   $0x2
f0101cfe:	68 00 10 00 00       	push   $0x1000
f0101d03:	56                   	push   %esi
f0101d04:	50                   	push   %eax
f0101d05:	e8 fe f5 ff ff       	call   f0101308 <page_insert>
f0101d0a:	83 c4 10             	add    $0x10,%esp
f0101d0d:	85 c0                	test   %eax,%eax
f0101d0f:	0f 85 e5 08 00 00    	jne    f01025fa <mem_init+0x1274>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d15:	83 ec 04             	sub    $0x4,%esp
f0101d18:	6a 00                	push   $0x0
f0101d1a:	68 00 10 00 00       	push   $0x1000
f0101d1f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d22:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d28:	ff 30                	pushl  (%eax)
f0101d2a:	e8 f5 f3 ff ff       	call   f0101124 <pgdir_walk>
f0101d2f:	83 c4 10             	add    $0x10,%esp
f0101d32:	f6 00 02             	testb  $0x2,(%eax)
f0101d35:	0f 84 e1 08 00 00    	je     f010261c <mem_init+0x1296>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d3b:	83 ec 04             	sub    $0x4,%esp
f0101d3e:	6a 00                	push   $0x0
f0101d40:	68 00 10 00 00       	push   $0x1000
f0101d45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d48:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d4e:	ff 30                	pushl  (%eax)
f0101d50:	e8 cf f3 ff ff       	call   f0101124 <pgdir_walk>
f0101d55:	83 c4 10             	add    $0x10,%esp
f0101d58:	f6 00 04             	testb  $0x4,(%eax)
f0101d5b:	0f 85 dd 08 00 00    	jne    f010263e <mem_init+0x12b8>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d61:	6a 02                	push   $0x2
f0101d63:	68 00 00 40 00       	push   $0x400000
f0101d68:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d6b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d6e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d74:	ff 30                	pushl  (%eax)
f0101d76:	e8 8d f5 ff ff       	call   f0101308 <page_insert>
f0101d7b:	83 c4 10             	add    $0x10,%esp
f0101d7e:	85 c0                	test   %eax,%eax
f0101d80:	0f 89 da 08 00 00    	jns    f0102660 <mem_init+0x12da>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d86:	6a 02                	push   $0x2
f0101d88:	68 00 10 00 00       	push   $0x1000
f0101d8d:	57                   	push   %edi
f0101d8e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d91:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d97:	ff 30                	pushl  (%eax)
f0101d99:	e8 6a f5 ff ff       	call   f0101308 <page_insert>
f0101d9e:	83 c4 10             	add    $0x10,%esp
f0101da1:	85 c0                	test   %eax,%eax
f0101da3:	0f 85 d9 08 00 00    	jne    f0102682 <mem_init+0x12fc>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101da9:	83 ec 04             	sub    $0x4,%esp
f0101dac:	6a 00                	push   $0x0
f0101dae:	68 00 10 00 00       	push   $0x1000
f0101db3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101db6:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101dbc:	ff 30                	pushl  (%eax)
f0101dbe:	e8 61 f3 ff ff       	call   f0101124 <pgdir_walk>
f0101dc3:	83 c4 10             	add    $0x10,%esp
f0101dc6:	f6 00 04             	testb  $0x4,(%eax)
f0101dc9:	0f 85 d5 08 00 00    	jne    f01026a4 <mem_init+0x131e>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101dcf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dd2:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101dd8:	8b 18                	mov    (%eax),%ebx
f0101dda:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ddf:	89 d8                	mov    %ebx,%eax
f0101de1:	e8 4f ed ff ff       	call   f0100b35 <check_va2pa>
f0101de6:	89 c2                	mov    %eax,%edx
f0101de8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101deb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101dee:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101df4:	89 f9                	mov    %edi,%ecx
f0101df6:	2b 08                	sub    (%eax),%ecx
f0101df8:	89 c8                	mov    %ecx,%eax
f0101dfa:	c1 f8 03             	sar    $0x3,%eax
f0101dfd:	c1 e0 0c             	shl    $0xc,%eax
f0101e00:	39 c2                	cmp    %eax,%edx
f0101e02:	0f 85 be 08 00 00    	jne    f01026c6 <mem_init+0x1340>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e08:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e0d:	89 d8                	mov    %ebx,%eax
f0101e0f:	e8 21 ed ff ff       	call   f0100b35 <check_va2pa>
f0101e14:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e17:	0f 85 cb 08 00 00    	jne    f01026e8 <mem_init+0x1362>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e1d:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101e22:	0f 85 e2 08 00 00    	jne    f010270a <mem_init+0x1384>
	assert(pp2->pp_ref == 0);
f0101e28:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e2d:	0f 85 f9 08 00 00    	jne    f010272c <mem_init+0x13a6>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e33:	83 ec 0c             	sub    $0xc,%esp
f0101e36:	6a 00                	push   $0x0
f0101e38:	e8 e7 f1 ff ff       	call   f0101024 <page_alloc>
f0101e3d:	83 c4 10             	add    $0x10,%esp
f0101e40:	39 c6                	cmp    %eax,%esi
f0101e42:	0f 85 06 09 00 00    	jne    f010274e <mem_init+0x13c8>
f0101e48:	85 c0                	test   %eax,%eax
f0101e4a:	0f 84 fe 08 00 00    	je     f010274e <mem_init+0x13c8>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e50:	83 ec 08             	sub    $0x8,%esp
f0101e53:	6a 00                	push   $0x0
f0101e55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e58:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101e5e:	ff 33                	pushl  (%ebx)
f0101e60:	e8 66 f4 ff ff       	call   f01012cb <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e65:	8b 1b                	mov    (%ebx),%ebx
f0101e67:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e6c:	89 d8                	mov    %ebx,%eax
f0101e6e:	e8 c2 ec ff ff       	call   f0100b35 <check_va2pa>
f0101e73:	83 c4 10             	add    $0x10,%esp
f0101e76:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e79:	0f 85 f1 08 00 00    	jne    f0102770 <mem_init+0x13ea>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e7f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e84:	89 d8                	mov    %ebx,%eax
f0101e86:	e8 aa ec ff ff       	call   f0100b35 <check_va2pa>
f0101e8b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e8e:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101e94:	89 f9                	mov    %edi,%ecx
f0101e96:	2b 0a                	sub    (%edx),%ecx
f0101e98:	89 ca                	mov    %ecx,%edx
f0101e9a:	c1 fa 03             	sar    $0x3,%edx
f0101e9d:	c1 e2 0c             	shl    $0xc,%edx
f0101ea0:	39 d0                	cmp    %edx,%eax
f0101ea2:	0f 85 ea 08 00 00    	jne    f0102792 <mem_init+0x140c>
	assert(pp1->pp_ref == 1);
f0101ea8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ead:	0f 85 01 09 00 00    	jne    f01027b4 <mem_init+0x142e>
	assert(pp2->pp_ref == 0);
f0101eb3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101eb8:	0f 85 18 09 00 00    	jne    f01027d6 <mem_init+0x1450>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101ebe:	6a 00                	push   $0x0
f0101ec0:	68 00 10 00 00       	push   $0x1000
f0101ec5:	57                   	push   %edi
f0101ec6:	53                   	push   %ebx
f0101ec7:	e8 3c f4 ff ff       	call   f0101308 <page_insert>
f0101ecc:	83 c4 10             	add    $0x10,%esp
f0101ecf:	85 c0                	test   %eax,%eax
f0101ed1:	0f 85 21 09 00 00    	jne    f01027f8 <mem_init+0x1472>
	assert(pp1->pp_ref);
f0101ed7:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101edc:	0f 84 38 09 00 00    	je     f010281a <mem_init+0x1494>
	assert(pp1->pp_link == NULL);
f0101ee2:	83 3f 00             	cmpl   $0x0,(%edi)
f0101ee5:	0f 85 51 09 00 00    	jne    f010283c <mem_init+0x14b6>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101eeb:	83 ec 08             	sub    $0x8,%esp
f0101eee:	68 00 10 00 00       	push   $0x1000
f0101ef3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef6:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101efc:	ff 33                	pushl  (%ebx)
f0101efe:	e8 c8 f3 ff ff       	call   f01012cb <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f03:	8b 1b                	mov    (%ebx),%ebx
f0101f05:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f0a:	89 d8                	mov    %ebx,%eax
f0101f0c:	e8 24 ec ff ff       	call   f0100b35 <check_va2pa>
f0101f11:	83 c4 10             	add    $0x10,%esp
f0101f14:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f17:	0f 85 41 09 00 00    	jne    f010285e <mem_init+0x14d8>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f1d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f22:	89 d8                	mov    %ebx,%eax
f0101f24:	e8 0c ec ff ff       	call   f0100b35 <check_va2pa>
f0101f29:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f2c:	0f 85 4e 09 00 00    	jne    f0102880 <mem_init+0x14fa>
	assert(pp1->pp_ref == 0);
f0101f32:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f37:	0f 85 65 09 00 00    	jne    f01028a2 <mem_init+0x151c>
	assert(pp2->pp_ref == 0);
f0101f3d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f42:	0f 85 7c 09 00 00    	jne    f01028c4 <mem_init+0x153e>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f48:	83 ec 0c             	sub    $0xc,%esp
f0101f4b:	6a 00                	push   $0x0
f0101f4d:	e8 d2 f0 ff ff       	call   f0101024 <page_alloc>
f0101f52:	83 c4 10             	add    $0x10,%esp
f0101f55:	39 c7                	cmp    %eax,%edi
f0101f57:	0f 85 89 09 00 00    	jne    f01028e6 <mem_init+0x1560>
f0101f5d:	85 c0                	test   %eax,%eax
f0101f5f:	0f 84 81 09 00 00    	je     f01028e6 <mem_init+0x1560>

	// should be no free memory
	assert(!page_alloc(0));
f0101f65:	83 ec 0c             	sub    $0xc,%esp
f0101f68:	6a 00                	push   $0x0
f0101f6a:	e8 b5 f0 ff ff       	call   f0101024 <page_alloc>
f0101f6f:	83 c4 10             	add    $0x10,%esp
f0101f72:	85 c0                	test   %eax,%eax
f0101f74:	0f 85 8e 09 00 00    	jne    f0102908 <mem_init+0x1582>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f7a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f7d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101f83:	8b 08                	mov    (%eax),%ecx
f0101f85:	8b 11                	mov    (%ecx),%edx
f0101f87:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f8d:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101f93:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f96:	2b 18                	sub    (%eax),%ebx
f0101f98:	89 d8                	mov    %ebx,%eax
f0101f9a:	c1 f8 03             	sar    $0x3,%eax
f0101f9d:	c1 e0 0c             	shl    $0xc,%eax
f0101fa0:	39 c2                	cmp    %eax,%edx
f0101fa2:	0f 85 82 09 00 00    	jne    f010292a <mem_init+0x15a4>
	kern_pgdir[0] = 0;
f0101fa8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fae:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101fb1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fb6:	0f 85 90 09 00 00    	jne    f010294c <mem_init+0x15c6>
	pp0->pp_ref = 0;
f0101fbc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101fbf:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fc5:	83 ec 0c             	sub    $0xc,%esp
f0101fc8:	50                   	push   %eax
f0101fc9:	e8 de f0 ff ff       	call   f01010ac <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fce:	83 c4 0c             	add    $0xc,%esp
f0101fd1:	6a 01                	push   $0x1
f0101fd3:	68 00 10 40 00       	push   $0x401000
f0101fd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fdb:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101fe1:	ff 33                	pushl  (%ebx)
f0101fe3:	e8 3c f1 ff ff       	call   f0101124 <pgdir_walk>
f0101fe8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101feb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fee:	8b 1b                	mov    (%ebx),%ebx
f0101ff0:	8b 53 04             	mov    0x4(%ebx),%edx
f0101ff3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101ff9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ffc:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0102002:	8b 09                	mov    (%ecx),%ecx
f0102004:	89 d0                	mov    %edx,%eax
f0102006:	c1 e8 0c             	shr    $0xc,%eax
f0102009:	83 c4 10             	add    $0x10,%esp
f010200c:	39 c8                	cmp    %ecx,%eax
f010200e:	0f 83 5a 09 00 00    	jae    f010296e <mem_init+0x15e8>
	assert(ptep == ptep1 + PTX(va));
f0102014:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010201a:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f010201d:	0f 85 67 09 00 00    	jne    f010298a <mem_init+0x1604>
	kern_pgdir[PDX(va)] = 0;
f0102023:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f010202a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010202d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102033:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102036:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010203c:	2b 18                	sub    (%eax),%ebx
f010203e:	89 d8                	mov    %ebx,%eax
f0102040:	c1 f8 03             	sar    $0x3,%eax
f0102043:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102046:	89 c2                	mov    %eax,%edx
f0102048:	c1 ea 0c             	shr    $0xc,%edx
f010204b:	39 d1                	cmp    %edx,%ecx
f010204d:	0f 86 59 09 00 00    	jbe    f01029ac <mem_init+0x1626>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102053:	83 ec 04             	sub    $0x4,%esp
f0102056:	68 00 10 00 00       	push   $0x1000
f010205b:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102060:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102065:	50                   	push   %eax
f0102066:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102069:	e8 ca 1c 00 00       	call   f0103d38 <memset>
	page_free(pp0);
f010206e:	83 c4 04             	add    $0x4,%esp
f0102071:	ff 75 d0             	pushl  -0x30(%ebp)
f0102074:	e8 33 f0 ff ff       	call   f01010ac <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102079:	83 c4 0c             	add    $0xc,%esp
f010207c:	6a 01                	push   $0x1
f010207e:	6a 00                	push   $0x0
f0102080:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102083:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102089:	ff 30                	pushl  (%eax)
f010208b:	e8 94 f0 ff ff       	call   f0101124 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102090:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102096:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102099:	2b 10                	sub    (%eax),%edx
f010209b:	c1 fa 03             	sar    $0x3,%edx
f010209e:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01020a1:	89 d1                	mov    %edx,%ecx
f01020a3:	c1 e9 0c             	shr    $0xc,%ecx
f01020a6:	83 c4 10             	add    $0x10,%esp
f01020a9:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01020af:	3b 08                	cmp    (%eax),%ecx
f01020b1:	0f 83 0e 09 00 00    	jae    f01029c5 <mem_init+0x163f>
	return (void *)(pa + KERNBASE);
f01020b7:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020bd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020c0:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020c6:	f6 00 01             	testb  $0x1,(%eax)
f01020c9:	0f 85 0f 09 00 00    	jne    f01029de <mem_init+0x1658>
f01020cf:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01020d2:	39 d0                	cmp    %edx,%eax
f01020d4:	75 f0                	jne    f01020c6 <mem_init+0xd40>
	kern_pgdir[0] = 0;
f01020d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020d9:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01020df:	8b 00                	mov    (%eax),%eax
f01020e1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020e7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020ea:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020f0:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01020f3:	89 93 b0 1f 00 00    	mov    %edx,0x1fb0(%ebx)

	// free the pages we took
	page_free(pp0);
f01020f9:	83 ec 0c             	sub    $0xc,%esp
f01020fc:	50                   	push   %eax
f01020fd:	e8 aa ef ff ff       	call   f01010ac <page_free>
	page_free(pp1);
f0102102:	89 3c 24             	mov    %edi,(%esp)
f0102105:	e8 a2 ef ff ff       	call   f01010ac <page_free>
	page_free(pp2);
f010210a:	89 34 24             	mov    %esi,(%esp)
f010210d:	e8 9a ef ff ff       	call   f01010ac <page_free>

	cprintf("check_page() succeeded!\n");
f0102112:	8d 83 22 de fe ff    	lea    -0x121de(%ebx),%eax
f0102118:	89 04 24             	mov    %eax,(%esp)
f010211b:	e8 07 10 00 00       	call   f0103127 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f0102120:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102126:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102128:	83 c4 10             	add    $0x10,%esp
f010212b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102130:	0f 86 ca 08 00 00    	jbe    f0102a00 <mem_init+0x167a>
f0102136:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102139:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010213f:	8b 0a                	mov    (%edx),%ecx
f0102141:	c1 e1 03             	shl    $0x3,%ecx
f0102144:	83 ec 08             	sub    $0x8,%esp
f0102147:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102149:	05 00 00 00 10       	add    $0x10000000,%eax
f010214e:	50                   	push   %eax
f010214f:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102154:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f010215a:	8b 00                	mov    (%eax),%eax
f010215c:	e8 6e f0 ff ff       	call   f01011cf <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102161:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f0102167:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010216a:	83 c4 10             	add    $0x10,%esp
f010216d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102172:	0f 86 a4 08 00 00    	jbe    f0102a1c <mem_init+0x1696>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102178:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010217b:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0102181:	83 ec 08             	sub    $0x8,%esp
f0102184:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f0102186:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102189:	05 00 00 00 10       	add    $0x10000000,%eax
f010218e:	50                   	push   %eax
f010218f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102194:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102199:	8b 03                	mov    (%ebx),%eax
f010219b:	e8 2f f0 ff ff       	call   f01011cf <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0x100000000 - KERNBASE, 0, PTE_W);
f01021a0:	83 c4 08             	add    $0x8,%esp
f01021a3:	6a 02                	push   $0x2
f01021a5:	6a 00                	push   $0x0
f01021a7:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021ac:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021b1:	8b 03                	mov    (%ebx),%eax
f01021b3:	e8 17 f0 ff ff       	call   f01011cf <boot_map_region>
	pgdir = kern_pgdir;
f01021b8:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021ba:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01021c0:	8b 00                	mov    (%eax),%eax
f01021c2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01021c5:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021cc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021d1:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021d4:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01021da:	8b 00                	mov    (%eax),%eax
f01021dc:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01021df:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01021e2:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f01021e8:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f01021eb:	bf 00 00 00 00       	mov    $0x0,%edi
f01021f0:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f01021f3:	0f 86 84 08 00 00    	jbe    f0102a7d <mem_init+0x16f7>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021f9:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f01021ff:	89 f0                	mov    %esi,%eax
f0102201:	e8 2f e9 ff ff       	call   f0100b35 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102206:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f010220d:	0f 86 2a 08 00 00    	jbe    f0102a3d <mem_init+0x16b7>
f0102213:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102216:	39 c2                	cmp    %eax,%edx
f0102218:	0f 85 3d 08 00 00    	jne    f0102a5b <mem_init+0x16d5>
	for (i = 0; i < n; i += PGSIZE)
f010221e:	81 c7 00 10 00 00    	add    $0x1000,%edi
f0102224:	eb ca                	jmp    f01021f0 <mem_init+0xe6a>
	assert(nfree == 0);
f0102226:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102229:	8d 83 4b dd fe ff    	lea    -0x122b5(%ebx),%eax
f010222f:	50                   	push   %eax
f0102230:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102236:	50                   	push   %eax
f0102237:	68 b2 02 00 00       	push   $0x2b2
f010223c:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102242:	50                   	push   %eax
f0102243:	e8 51 de ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102248:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010224b:	8d 83 59 dc fe ff    	lea    -0x123a7(%ebx),%eax
f0102251:	50                   	push   %eax
f0102252:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102258:	50                   	push   %eax
f0102259:	68 0b 03 00 00       	push   $0x30b
f010225e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102264:	50                   	push   %eax
f0102265:	e8 2f de ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010226a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010226d:	8d 83 6f dc fe ff    	lea    -0x12391(%ebx),%eax
f0102273:	50                   	push   %eax
f0102274:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010227a:	50                   	push   %eax
f010227b:	68 0c 03 00 00       	push   $0x30c
f0102280:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102286:	50                   	push   %eax
f0102287:	e8 0d de ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010228c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010228f:	8d 83 85 dc fe ff    	lea    -0x1237b(%ebx),%eax
f0102295:	50                   	push   %eax
f0102296:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010229c:	50                   	push   %eax
f010229d:	68 0d 03 00 00       	push   $0x30d
f01022a2:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01022a8:	50                   	push   %eax
f01022a9:	e8 eb dd ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01022ae:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022b1:	8d 83 9b dc fe ff    	lea    -0x12365(%ebx),%eax
f01022b7:	50                   	push   %eax
f01022b8:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01022be:	50                   	push   %eax
f01022bf:	68 10 03 00 00       	push   $0x310
f01022c4:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01022ca:	50                   	push   %eax
f01022cb:	e8 c9 dd ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022d0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022d3:	8d 83 9c d5 fe ff    	lea    -0x12a64(%ebx),%eax
f01022d9:	50                   	push   %eax
f01022da:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01022e0:	50                   	push   %eax
f01022e1:	68 11 03 00 00       	push   $0x311
f01022e6:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01022ec:	50                   	push   %eax
f01022ed:	e8 a7 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01022f2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022f5:	8d 83 04 dd fe ff    	lea    -0x122fc(%ebx),%eax
f01022fb:	50                   	push   %eax
f01022fc:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102302:	50                   	push   %eax
f0102303:	68 18 03 00 00       	push   $0x318
f0102308:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010230e:	50                   	push   %eax
f010230f:	e8 85 dd ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102314:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102317:	8d 83 dc d5 fe ff    	lea    -0x12a24(%ebx),%eax
f010231d:	50                   	push   %eax
f010231e:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102324:	50                   	push   %eax
f0102325:	68 1b 03 00 00       	push   $0x31b
f010232a:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102330:	50                   	push   %eax
f0102331:	e8 63 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102336:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102339:	8d 83 14 d6 fe ff    	lea    -0x129ec(%ebx),%eax
f010233f:	50                   	push   %eax
f0102340:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102346:	50                   	push   %eax
f0102347:	68 1e 03 00 00       	push   $0x31e
f010234c:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102352:	50                   	push   %eax
f0102353:	e8 41 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102358:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010235b:	8d 83 44 d6 fe ff    	lea    -0x129bc(%ebx),%eax
f0102361:	50                   	push   %eax
f0102362:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102368:	50                   	push   %eax
f0102369:	68 22 03 00 00       	push   $0x322
f010236e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102374:	50                   	push   %eax
f0102375:	e8 1f dd ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010237a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010237d:	8d 83 74 d6 fe ff    	lea    -0x1298c(%ebx),%eax
f0102383:	50                   	push   %eax
f0102384:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010238a:	50                   	push   %eax
f010238b:	68 23 03 00 00       	push   $0x323
f0102390:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102396:	50                   	push   %eax
f0102397:	e8 fd dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010239c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010239f:	8d 83 9c d6 fe ff    	lea    -0x12964(%ebx),%eax
f01023a5:	50                   	push   %eax
f01023a6:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01023ac:	50                   	push   %eax
f01023ad:	68 24 03 00 00       	push   $0x324
f01023b2:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01023b8:	50                   	push   %eax
f01023b9:	e8 db dc ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01023be:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023c1:	8d 83 56 dd fe ff    	lea    -0x122aa(%ebx),%eax
f01023c7:	50                   	push   %eax
f01023c8:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01023ce:	50                   	push   %eax
f01023cf:	68 25 03 00 00       	push   $0x325
f01023d4:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01023da:	50                   	push   %eax
f01023db:	e8 b9 dc ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01023e0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023e3:	8d 83 67 dd fe ff    	lea    -0x12299(%ebx),%eax
f01023e9:	50                   	push   %eax
f01023ea:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01023f0:	50                   	push   %eax
f01023f1:	68 26 03 00 00       	push   $0x326
f01023f6:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01023fc:	50                   	push   %eax
f01023fd:	e8 97 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102402:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102405:	8d 83 cc d6 fe ff    	lea    -0x12934(%ebx),%eax
f010240b:	50                   	push   %eax
f010240c:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102412:	50                   	push   %eax
f0102413:	68 29 03 00 00       	push   $0x329
f0102418:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010241e:	50                   	push   %eax
f010241f:	e8 75 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102424:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102427:	8d 83 08 d7 fe ff    	lea    -0x128f8(%ebx),%eax
f010242d:	50                   	push   %eax
f010242e:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102434:	50                   	push   %eax
f0102435:	68 2a 03 00 00       	push   $0x32a
f010243a:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102440:	50                   	push   %eax
f0102441:	e8 53 dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102446:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102449:	8d 83 78 dd fe ff    	lea    -0x12288(%ebx),%eax
f010244f:	50                   	push   %eax
f0102450:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102456:	50                   	push   %eax
f0102457:	68 2b 03 00 00       	push   $0x32b
f010245c:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102462:	50                   	push   %eax
f0102463:	e8 31 dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102468:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010246b:	8d 83 04 dd fe ff    	lea    -0x122fc(%ebx),%eax
f0102471:	50                   	push   %eax
f0102472:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102478:	50                   	push   %eax
f0102479:	68 2e 03 00 00       	push   $0x32e
f010247e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102484:	50                   	push   %eax
f0102485:	e8 0f dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010248a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010248d:	8d 83 cc d6 fe ff    	lea    -0x12934(%ebx),%eax
f0102493:	50                   	push   %eax
f0102494:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010249a:	50                   	push   %eax
f010249b:	68 31 03 00 00       	push   $0x331
f01024a0:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01024a6:	50                   	push   %eax
f01024a7:	e8 ed db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024ac:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024af:	8d 83 08 d7 fe ff    	lea    -0x128f8(%ebx),%eax
f01024b5:	50                   	push   %eax
f01024b6:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01024bc:	50                   	push   %eax
f01024bd:	68 32 03 00 00       	push   $0x332
f01024c2:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01024c8:	50                   	push   %eax
f01024c9:	e8 cb db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01024ce:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024d1:	8d 83 78 dd fe ff    	lea    -0x12288(%ebx),%eax
f01024d7:	50                   	push   %eax
f01024d8:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01024de:	50                   	push   %eax
f01024df:	68 33 03 00 00       	push   $0x333
f01024e4:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01024ea:	50                   	push   %eax
f01024eb:	e8 a9 db ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01024f0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024f3:	8d 83 04 dd fe ff    	lea    -0x122fc(%ebx),%eax
f01024f9:	50                   	push   %eax
f01024fa:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102500:	50                   	push   %eax
f0102501:	68 37 03 00 00       	push   $0x337
f0102506:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010250c:	50                   	push   %eax
f010250d:	e8 87 db ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102512:	50                   	push   %eax
f0102513:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102516:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f010251c:	50                   	push   %eax
f010251d:	68 3a 03 00 00       	push   $0x33a
f0102522:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102528:	50                   	push   %eax
f0102529:	e8 6b db ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010252e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102531:	8d 83 38 d7 fe ff    	lea    -0x128c8(%ebx),%eax
f0102537:	50                   	push   %eax
f0102538:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010253e:	50                   	push   %eax
f010253f:	68 3b 03 00 00       	push   $0x33b
f0102544:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010254a:	50                   	push   %eax
f010254b:	e8 49 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102550:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102553:	8d 83 78 d7 fe ff    	lea    -0x12888(%ebx),%eax
f0102559:	50                   	push   %eax
f010255a:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102560:	50                   	push   %eax
f0102561:	68 3e 03 00 00       	push   $0x33e
f0102566:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010256c:	50                   	push   %eax
f010256d:	e8 27 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102572:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102575:	8d 83 08 d7 fe ff    	lea    -0x128f8(%ebx),%eax
f010257b:	50                   	push   %eax
f010257c:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102582:	50                   	push   %eax
f0102583:	68 3f 03 00 00       	push   $0x33f
f0102588:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010258e:	50                   	push   %eax
f010258f:	e8 05 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102594:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102597:	8d 83 78 dd fe ff    	lea    -0x12288(%ebx),%eax
f010259d:	50                   	push   %eax
f010259e:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01025a4:	50                   	push   %eax
f01025a5:	68 40 03 00 00       	push   $0x340
f01025aa:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01025b0:	50                   	push   %eax
f01025b1:	e8 e3 da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01025b6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025b9:	8d 83 b8 d7 fe ff    	lea    -0x12848(%ebx),%eax
f01025bf:	50                   	push   %eax
f01025c0:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01025c6:	50                   	push   %eax
f01025c7:	68 41 03 00 00       	push   $0x341
f01025cc:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01025d2:	50                   	push   %eax
f01025d3:	e8 c1 da ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01025d8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025db:	8d 83 89 dd fe ff    	lea    -0x12277(%ebx),%eax
f01025e1:	50                   	push   %eax
f01025e2:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01025e8:	50                   	push   %eax
f01025e9:	68 42 03 00 00       	push   $0x342
f01025ee:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01025f4:	50                   	push   %eax
f01025f5:	e8 9f da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01025fa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025fd:	8d 83 cc d6 fe ff    	lea    -0x12934(%ebx),%eax
f0102603:	50                   	push   %eax
f0102604:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010260a:	50                   	push   %eax
f010260b:	68 45 03 00 00       	push   $0x345
f0102610:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102616:	50                   	push   %eax
f0102617:	e8 7d da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010261c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010261f:	8d 83 ec d7 fe ff    	lea    -0x12814(%ebx),%eax
f0102625:	50                   	push   %eax
f0102626:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010262c:	50                   	push   %eax
f010262d:	68 46 03 00 00       	push   $0x346
f0102632:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102638:	50                   	push   %eax
f0102639:	e8 5b da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010263e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102641:	8d 83 20 d8 fe ff    	lea    -0x127e0(%ebx),%eax
f0102647:	50                   	push   %eax
f0102648:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010264e:	50                   	push   %eax
f010264f:	68 47 03 00 00       	push   $0x347
f0102654:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010265a:	50                   	push   %eax
f010265b:	e8 39 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102660:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102663:	8d 83 58 d8 fe ff    	lea    -0x127a8(%ebx),%eax
f0102669:	50                   	push   %eax
f010266a:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102670:	50                   	push   %eax
f0102671:	68 4a 03 00 00       	push   $0x34a
f0102676:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010267c:	50                   	push   %eax
f010267d:	e8 17 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102682:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102685:	8d 83 90 d8 fe ff    	lea    -0x12770(%ebx),%eax
f010268b:	50                   	push   %eax
f010268c:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102692:	50                   	push   %eax
f0102693:	68 4d 03 00 00       	push   $0x34d
f0102698:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010269e:	50                   	push   %eax
f010269f:	e8 f5 d9 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026a4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026a7:	8d 83 20 d8 fe ff    	lea    -0x127e0(%ebx),%eax
f01026ad:	50                   	push   %eax
f01026ae:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01026b4:	50                   	push   %eax
f01026b5:	68 4e 03 00 00       	push   $0x34e
f01026ba:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01026c0:	50                   	push   %eax
f01026c1:	e8 d3 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01026c6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026c9:	8d 83 cc d8 fe ff    	lea    -0x12734(%ebx),%eax
f01026cf:	50                   	push   %eax
f01026d0:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01026d6:	50                   	push   %eax
f01026d7:	68 51 03 00 00       	push   $0x351
f01026dc:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01026e2:	50                   	push   %eax
f01026e3:	e8 b1 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026e8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026eb:	8d 83 f8 d8 fe ff    	lea    -0x12708(%ebx),%eax
f01026f1:	50                   	push   %eax
f01026f2:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01026f8:	50                   	push   %eax
f01026f9:	68 52 03 00 00       	push   $0x352
f01026fe:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102704:	50                   	push   %eax
f0102705:	e8 8f d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f010270a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010270d:	8d 83 9f dd fe ff    	lea    -0x12261(%ebx),%eax
f0102713:	50                   	push   %eax
f0102714:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010271a:	50                   	push   %eax
f010271b:	68 54 03 00 00       	push   $0x354
f0102720:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102726:	50                   	push   %eax
f0102727:	e8 6d d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010272c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010272f:	8d 83 b0 dd fe ff    	lea    -0x12250(%ebx),%eax
f0102735:	50                   	push   %eax
f0102736:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010273c:	50                   	push   %eax
f010273d:	68 55 03 00 00       	push   $0x355
f0102742:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102748:	50                   	push   %eax
f0102749:	e8 4b d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f010274e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102751:	8d 83 28 d9 fe ff    	lea    -0x126d8(%ebx),%eax
f0102757:	50                   	push   %eax
f0102758:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010275e:	50                   	push   %eax
f010275f:	68 58 03 00 00       	push   $0x358
f0102764:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010276a:	50                   	push   %eax
f010276b:	e8 29 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102770:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102773:	8d 83 4c d9 fe ff    	lea    -0x126b4(%ebx),%eax
f0102779:	50                   	push   %eax
f010277a:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102780:	50                   	push   %eax
f0102781:	68 5c 03 00 00       	push   $0x35c
f0102786:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010278c:	50                   	push   %eax
f010278d:	e8 07 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102792:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102795:	8d 83 f8 d8 fe ff    	lea    -0x12708(%ebx),%eax
f010279b:	50                   	push   %eax
f010279c:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01027a2:	50                   	push   %eax
f01027a3:	68 5d 03 00 00       	push   $0x35d
f01027a8:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01027ae:	50                   	push   %eax
f01027af:	e8 e5 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01027b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027b7:	8d 83 56 dd fe ff    	lea    -0x122aa(%ebx),%eax
f01027bd:	50                   	push   %eax
f01027be:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01027c4:	50                   	push   %eax
f01027c5:	68 5e 03 00 00       	push   $0x35e
f01027ca:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01027d0:	50                   	push   %eax
f01027d1:	e8 c3 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01027d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027d9:	8d 83 b0 dd fe ff    	lea    -0x12250(%ebx),%eax
f01027df:	50                   	push   %eax
f01027e0:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01027e6:	50                   	push   %eax
f01027e7:	68 5f 03 00 00       	push   $0x35f
f01027ec:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01027f2:	50                   	push   %eax
f01027f3:	e8 a1 d8 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01027f8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027fb:	8d 83 70 d9 fe ff    	lea    -0x12690(%ebx),%eax
f0102801:	50                   	push   %eax
f0102802:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102808:	50                   	push   %eax
f0102809:	68 62 03 00 00       	push   $0x362
f010280e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102814:	50                   	push   %eax
f0102815:	e8 7f d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f010281a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010281d:	8d 83 c1 dd fe ff    	lea    -0x1223f(%ebx),%eax
f0102823:	50                   	push   %eax
f0102824:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010282a:	50                   	push   %eax
f010282b:	68 63 03 00 00       	push   $0x363
f0102830:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102836:	50                   	push   %eax
f0102837:	e8 5d d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f010283c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010283f:	8d 83 cd dd fe ff    	lea    -0x12233(%ebx),%eax
f0102845:	50                   	push   %eax
f0102846:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010284c:	50                   	push   %eax
f010284d:	68 64 03 00 00       	push   $0x364
f0102852:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102858:	50                   	push   %eax
f0102859:	e8 3b d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010285e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102861:	8d 83 4c d9 fe ff    	lea    -0x126b4(%ebx),%eax
f0102867:	50                   	push   %eax
f0102868:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010286e:	50                   	push   %eax
f010286f:	68 68 03 00 00       	push   $0x368
f0102874:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010287a:	50                   	push   %eax
f010287b:	e8 19 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102880:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102883:	8d 83 a8 d9 fe ff    	lea    -0x12658(%ebx),%eax
f0102889:	50                   	push   %eax
f010288a:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102890:	50                   	push   %eax
f0102891:	68 69 03 00 00       	push   $0x369
f0102896:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010289c:	50                   	push   %eax
f010289d:	e8 f7 d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f01028a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028a5:	8d 83 e2 dd fe ff    	lea    -0x1221e(%ebx),%eax
f01028ab:	50                   	push   %eax
f01028ac:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01028b2:	50                   	push   %eax
f01028b3:	68 6a 03 00 00       	push   $0x36a
f01028b8:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01028be:	50                   	push   %eax
f01028bf:	e8 d5 d7 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01028c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028c7:	8d 83 b0 dd fe ff    	lea    -0x12250(%ebx),%eax
f01028cd:	50                   	push   %eax
f01028ce:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01028d4:	50                   	push   %eax
f01028d5:	68 6b 03 00 00       	push   $0x36b
f01028da:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01028e0:	50                   	push   %eax
f01028e1:	e8 b3 d7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01028e6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028e9:	8d 83 d0 d9 fe ff    	lea    -0x12630(%ebx),%eax
f01028ef:	50                   	push   %eax
f01028f0:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01028f6:	50                   	push   %eax
f01028f7:	68 6e 03 00 00       	push   $0x36e
f01028fc:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102902:	50                   	push   %eax
f0102903:	e8 91 d7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102908:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010290b:	8d 83 04 dd fe ff    	lea    -0x122fc(%ebx),%eax
f0102911:	50                   	push   %eax
f0102912:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102918:	50                   	push   %eax
f0102919:	68 71 03 00 00       	push   $0x371
f010291e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102924:	50                   	push   %eax
f0102925:	e8 6f d7 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010292a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010292d:	8d 83 74 d6 fe ff    	lea    -0x1298c(%ebx),%eax
f0102933:	50                   	push   %eax
f0102934:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010293a:	50                   	push   %eax
f010293b:	68 74 03 00 00       	push   $0x374
f0102940:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102946:	50                   	push   %eax
f0102947:	e8 4d d7 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f010294c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010294f:	8d 83 67 dd fe ff    	lea    -0x12299(%ebx),%eax
f0102955:	50                   	push   %eax
f0102956:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010295c:	50                   	push   %eax
f010295d:	68 76 03 00 00       	push   $0x376
f0102962:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102968:	50                   	push   %eax
f0102969:	e8 2b d7 ff ff       	call   f0100099 <_panic>
f010296e:	52                   	push   %edx
f010296f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102972:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f0102978:	50                   	push   %eax
f0102979:	68 7d 03 00 00       	push   $0x37d
f010297e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102984:	50                   	push   %eax
f0102985:	e8 0f d7 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010298a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010298d:	8d 83 f3 dd fe ff    	lea    -0x1220d(%ebx),%eax
f0102993:	50                   	push   %eax
f0102994:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010299a:	50                   	push   %eax
f010299b:	68 7e 03 00 00       	push   $0x37e
f01029a0:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01029a6:	50                   	push   %eax
f01029a7:	e8 ed d6 ff ff       	call   f0100099 <_panic>
f01029ac:	50                   	push   %eax
f01029ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029b0:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f01029b6:	50                   	push   %eax
f01029b7:	6a 59                	push   $0x59
f01029b9:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f01029bf:	50                   	push   %eax
f01029c0:	e8 d4 d6 ff ff       	call   f0100099 <_panic>
f01029c5:	52                   	push   %edx
f01029c6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029c9:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f01029cf:	50                   	push   %eax
f01029d0:	6a 59                	push   $0x59
f01029d2:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f01029d8:	50                   	push   %eax
f01029d9:	e8 bb d6 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01029de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029e1:	8d 83 0b de fe ff    	lea    -0x121f5(%ebx),%eax
f01029e7:	50                   	push   %eax
f01029e8:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f01029ee:	50                   	push   %eax
f01029ef:	68 88 03 00 00       	push   $0x388
f01029f4:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f01029fa:	50                   	push   %eax
f01029fb:	e8 99 d6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a00:	50                   	push   %eax
f0102a01:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a04:	8d 83 d8 d4 fe ff    	lea    -0x12b28(%ebx),%eax
f0102a0a:	50                   	push   %eax
f0102a0b:	68 c0 00 00 00       	push   $0xc0
f0102a10:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102a16:	50                   	push   %eax
f0102a17:	e8 7d d6 ff ff       	call   f0100099 <_panic>
f0102a1c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a1f:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102a25:	8d 83 d8 d4 fe ff    	lea    -0x12b28(%ebx),%eax
f0102a2b:	50                   	push   %eax
f0102a2c:	68 cd 00 00 00       	push   $0xcd
f0102a31:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102a37:	50                   	push   %eax
f0102a38:	e8 5c d6 ff ff       	call   f0100099 <_panic>
f0102a3d:	ff 75 c0             	pushl  -0x40(%ebp)
f0102a40:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a43:	8d 83 d8 d4 fe ff    	lea    -0x12b28(%ebx),%eax
f0102a49:	50                   	push   %eax
f0102a4a:	68 ca 02 00 00       	push   $0x2ca
f0102a4f:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102a55:	50                   	push   %eax
f0102a56:	e8 3e d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a5b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a5e:	8d 83 f4 d9 fe ff    	lea    -0x1260c(%ebx),%eax
f0102a64:	50                   	push   %eax
f0102a65:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102a6b:	50                   	push   %eax
f0102a6c:	68 ca 02 00 00       	push   $0x2ca
f0102a71:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102a77:	50                   	push   %eax
f0102a78:	e8 1c d6 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a7d:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102a80:	c1 e7 0c             	shl    $0xc,%edi
f0102a83:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a88:	eb 17                	jmp    f0102aa1 <mem_init+0x171b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a8a:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102a90:	89 f0                	mov    %esi,%eax
f0102a92:	e8 9e e0 ff ff       	call   f0100b35 <check_va2pa>
f0102a97:	39 c3                	cmp    %eax,%ebx
f0102a99:	75 51                	jne    f0102aec <mem_init+0x1766>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a9b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102aa1:	39 fb                	cmp    %edi,%ebx
f0102aa3:	72 e5                	jb     f0102a8a <mem_init+0x1704>
f0102aa5:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102aaa:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102aad:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102ab3:	89 da                	mov    %ebx,%edx
f0102ab5:	89 f0                	mov    %esi,%eax
f0102ab7:	e8 79 e0 ff ff       	call   f0100b35 <check_va2pa>
f0102abc:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102abf:	39 c2                	cmp    %eax,%edx
f0102ac1:	75 4b                	jne    f0102b0e <mem_init+0x1788>
f0102ac3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102ac9:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102acf:	75 e2                	jne    f0102ab3 <mem_init+0x172d>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102ad1:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102ad6:	89 f0                	mov    %esi,%eax
f0102ad8:	e8 58 e0 ff ff       	call   f0100b35 <check_va2pa>
f0102add:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102ae0:	75 4e                	jne    f0102b30 <mem_init+0x17aa>
	for (i = 0; i < NPDENTRIES; i++) {
f0102ae2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ae7:	e9 8f 00 00 00       	jmp    f0102b7b <mem_init+0x17f5>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102aec:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aef:	8d 83 28 da fe ff    	lea    -0x125d8(%ebx),%eax
f0102af5:	50                   	push   %eax
f0102af6:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102afc:	50                   	push   %eax
f0102afd:	68 cf 02 00 00       	push   $0x2cf
f0102b02:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102b08:	50                   	push   %eax
f0102b09:	e8 8b d5 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b0e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b11:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f0102b17:	50                   	push   %eax
f0102b18:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102b1e:	50                   	push   %eax
f0102b1f:	68 d3 02 00 00       	push   $0x2d3
f0102b24:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102b2a:	50                   	push   %eax
f0102b2b:	e8 69 d5 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b30:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b33:	8d 83 98 da fe ff    	lea    -0x12568(%ebx),%eax
f0102b39:	50                   	push   %eax
f0102b3a:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102b40:	50                   	push   %eax
f0102b41:	68 d4 02 00 00       	push   $0x2d4
f0102b46:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102b4c:	50                   	push   %eax
f0102b4d:	e8 47 d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b52:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102b56:	74 52                	je     f0102baa <mem_init+0x1824>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b58:	83 c0 01             	add    $0x1,%eax
f0102b5b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102b60:	0f 87 bb 00 00 00    	ja     f0102c21 <mem_init+0x189b>
		switch (i) {
f0102b66:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102b6b:	72 0e                	jb     f0102b7b <mem_init+0x17f5>
f0102b6d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102b72:	76 de                	jbe    f0102b52 <mem_init+0x17cc>
f0102b74:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b79:	74 d7                	je     f0102b52 <mem_init+0x17cc>
			if (i >= PDX(KERNBASE)) {
f0102b7b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b80:	77 4a                	ja     f0102bcc <mem_init+0x1846>
				assert(pgdir[i] == 0);
f0102b82:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102b86:	74 d0                	je     f0102b58 <mem_init+0x17d2>
f0102b88:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b8b:	8d 83 5d de fe ff    	lea    -0x121a3(%ebx),%eax
f0102b91:	50                   	push   %eax
f0102b92:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102b98:	50                   	push   %eax
f0102b99:	68 e3 02 00 00       	push   $0x2e3
f0102b9e:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102ba4:	50                   	push   %eax
f0102ba5:	e8 ef d4 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102baa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bad:	8d 83 3b de fe ff    	lea    -0x121c5(%ebx),%eax
f0102bb3:	50                   	push   %eax
f0102bb4:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102bba:	50                   	push   %eax
f0102bbb:	68 dc 02 00 00       	push   $0x2dc
f0102bc0:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102bc6:	50                   	push   %eax
f0102bc7:	e8 cd d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bcc:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102bcf:	f6 c2 01             	test   $0x1,%dl
f0102bd2:	74 2b                	je     f0102bff <mem_init+0x1879>
				assert(pgdir[i] & PTE_W);
f0102bd4:	f6 c2 02             	test   $0x2,%dl
f0102bd7:	0f 85 7b ff ff ff    	jne    f0102b58 <mem_init+0x17d2>
f0102bdd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102be0:	8d 83 4c de fe ff    	lea    -0x121b4(%ebx),%eax
f0102be6:	50                   	push   %eax
f0102be7:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102bed:	50                   	push   %eax
f0102bee:	68 e1 02 00 00       	push   $0x2e1
f0102bf3:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102bf9:	50                   	push   %eax
f0102bfa:	e8 9a d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c02:	8d 83 3b de fe ff    	lea    -0x121c5(%ebx),%eax
f0102c08:	50                   	push   %eax
f0102c09:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102c0f:	50                   	push   %eax
f0102c10:	68 e0 02 00 00       	push   $0x2e0
f0102c15:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102c1b:	50                   	push   %eax
f0102c1c:	e8 78 d4 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c21:	83 ec 0c             	sub    $0xc,%esp
f0102c24:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c27:	8d 87 c8 da fe ff    	lea    -0x12538(%edi),%eax
f0102c2d:	50                   	push   %eax
f0102c2e:	89 fb                	mov    %edi,%ebx
f0102c30:	e8 f2 04 00 00       	call   f0103127 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102c35:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102c3b:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102c3d:	83 c4 10             	add    $0x10,%esp
f0102c40:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c45:	0f 86 44 02 00 00    	jbe    f0102e8f <mem_init+0x1b09>
	return (physaddr_t)kva - KERNBASE;
f0102c4b:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c50:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c53:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c58:	e8 55 df ff ff       	call   f0100bb2 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c5d:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c60:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c63:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c68:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c6b:	83 ec 0c             	sub    $0xc,%esp
f0102c6e:	6a 00                	push   $0x0
f0102c70:	e8 af e3 ff ff       	call   f0101024 <page_alloc>
f0102c75:	89 c6                	mov    %eax,%esi
f0102c77:	83 c4 10             	add    $0x10,%esp
f0102c7a:	85 c0                	test   %eax,%eax
f0102c7c:	0f 84 29 02 00 00    	je     f0102eab <mem_init+0x1b25>
	assert((pp1 = page_alloc(0)));
f0102c82:	83 ec 0c             	sub    $0xc,%esp
f0102c85:	6a 00                	push   $0x0
f0102c87:	e8 98 e3 ff ff       	call   f0101024 <page_alloc>
f0102c8c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c8f:	83 c4 10             	add    $0x10,%esp
f0102c92:	85 c0                	test   %eax,%eax
f0102c94:	0f 84 33 02 00 00    	je     f0102ecd <mem_init+0x1b47>
	assert((pp2 = page_alloc(0)));
f0102c9a:	83 ec 0c             	sub    $0xc,%esp
f0102c9d:	6a 00                	push   $0x0
f0102c9f:	e8 80 e3 ff ff       	call   f0101024 <page_alloc>
f0102ca4:	89 c7                	mov    %eax,%edi
f0102ca6:	83 c4 10             	add    $0x10,%esp
f0102ca9:	85 c0                	test   %eax,%eax
f0102cab:	0f 84 3e 02 00 00    	je     f0102eef <mem_init+0x1b69>
	page_free(pp0);
f0102cb1:	83 ec 0c             	sub    $0xc,%esp
f0102cb4:	56                   	push   %esi
f0102cb5:	e8 f2 e3 ff ff       	call   f01010ac <page_free>
	return (pp - pages) << PGSHIFT;
f0102cba:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cbd:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102cc3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102cc6:	2b 08                	sub    (%eax),%ecx
f0102cc8:	89 c8                	mov    %ecx,%eax
f0102cca:	c1 f8 03             	sar    $0x3,%eax
f0102ccd:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102cd0:	89 c1                	mov    %eax,%ecx
f0102cd2:	c1 e9 0c             	shr    $0xc,%ecx
f0102cd5:	83 c4 10             	add    $0x10,%esp
f0102cd8:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102cde:	3b 0a                	cmp    (%edx),%ecx
f0102ce0:	0f 83 2b 02 00 00    	jae    f0102f11 <mem_init+0x1b8b>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ce6:	83 ec 04             	sub    $0x4,%esp
f0102ce9:	68 00 10 00 00       	push   $0x1000
f0102cee:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102cf0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102cf5:	50                   	push   %eax
f0102cf6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cf9:	e8 3a 10 00 00       	call   f0103d38 <memset>
	return (pp - pages) << PGSHIFT;
f0102cfe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d01:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102d07:	89 f9                	mov    %edi,%ecx
f0102d09:	2b 08                	sub    (%eax),%ecx
f0102d0b:	89 c8                	mov    %ecx,%eax
f0102d0d:	c1 f8 03             	sar    $0x3,%eax
f0102d10:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d13:	89 c1                	mov    %eax,%ecx
f0102d15:	c1 e9 0c             	shr    $0xc,%ecx
f0102d18:	83 c4 10             	add    $0x10,%esp
f0102d1b:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102d21:	3b 0a                	cmp    (%edx),%ecx
f0102d23:	0f 83 fe 01 00 00    	jae    f0102f27 <mem_init+0x1ba1>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d29:	83 ec 04             	sub    $0x4,%esp
f0102d2c:	68 00 10 00 00       	push   $0x1000
f0102d31:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102d33:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102d38:	50                   	push   %eax
f0102d39:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d3c:	e8 f7 0f 00 00       	call   f0103d38 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d41:	6a 02                	push   $0x2
f0102d43:	68 00 10 00 00       	push   $0x1000
f0102d48:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102d4b:	53                   	push   %ebx
f0102d4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d4f:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d55:	ff 30                	pushl  (%eax)
f0102d57:	e8 ac e5 ff ff       	call   f0101308 <page_insert>
	assert(pp1->pp_ref == 1);
f0102d5c:	83 c4 20             	add    $0x20,%esp
f0102d5f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d64:	0f 85 d3 01 00 00    	jne    f0102f3d <mem_init+0x1bb7>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d6a:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d71:	01 01 01 
f0102d74:	0f 85 e5 01 00 00    	jne    f0102f5f <mem_init+0x1bd9>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d7a:	6a 02                	push   $0x2
f0102d7c:	68 00 10 00 00       	push   $0x1000
f0102d81:	57                   	push   %edi
f0102d82:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d85:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d8b:	ff 30                	pushl  (%eax)
f0102d8d:	e8 76 e5 ff ff       	call   f0101308 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d92:	83 c4 10             	add    $0x10,%esp
f0102d95:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d9c:	02 02 02 
f0102d9f:	0f 85 dc 01 00 00    	jne    f0102f81 <mem_init+0x1bfb>
	assert(pp2->pp_ref == 1);
f0102da5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102daa:	0f 85 f3 01 00 00    	jne    f0102fa3 <mem_init+0x1c1d>
	assert(pp1->pp_ref == 0);
f0102db0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102db3:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102db8:	0f 85 07 02 00 00    	jne    f0102fc5 <mem_init+0x1c3f>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102dbe:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102dc5:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102dc8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dcb:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102dd1:	89 f9                	mov    %edi,%ecx
f0102dd3:	2b 08                	sub    (%eax),%ecx
f0102dd5:	89 c8                	mov    %ecx,%eax
f0102dd7:	c1 f8 03             	sar    $0x3,%eax
f0102dda:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102ddd:	89 c1                	mov    %eax,%ecx
f0102ddf:	c1 e9 0c             	shr    $0xc,%ecx
f0102de2:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102de8:	3b 0a                	cmp    (%edx),%ecx
f0102dea:	0f 83 f7 01 00 00    	jae    f0102fe7 <mem_init+0x1c61>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102df0:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102df7:	03 03 03 
f0102dfa:	0f 85 fd 01 00 00    	jne    f0102ffd <mem_init+0x1c77>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102e00:	83 ec 08             	sub    $0x8,%esp
f0102e03:	68 00 10 00 00       	push   $0x1000
f0102e08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e0b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102e11:	ff 30                	pushl  (%eax)
f0102e13:	e8 b3 e4 ff ff       	call   f01012cb <page_remove>
	assert(pp2->pp_ref == 0);
f0102e18:	83 c4 10             	add    $0x10,%esp
f0102e1b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e20:	0f 85 f9 01 00 00    	jne    f010301f <mem_init+0x1c99>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e26:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e29:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102e2f:	8b 08                	mov    (%eax),%ecx
f0102e31:	8b 11                	mov    (%ecx),%edx
f0102e33:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102e39:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102e3f:	89 f7                	mov    %esi,%edi
f0102e41:	2b 38                	sub    (%eax),%edi
f0102e43:	89 f8                	mov    %edi,%eax
f0102e45:	c1 f8 03             	sar    $0x3,%eax
f0102e48:	c1 e0 0c             	shl    $0xc,%eax
f0102e4b:	39 c2                	cmp    %eax,%edx
f0102e4d:	0f 85 ee 01 00 00    	jne    f0103041 <mem_init+0x1cbb>
	kern_pgdir[0] = 0;
f0102e53:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e59:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e5e:	0f 85 ff 01 00 00    	jne    f0103063 <mem_init+0x1cdd>
	pp0->pp_ref = 0;
f0102e64:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e6a:	83 ec 0c             	sub    $0xc,%esp
f0102e6d:	56                   	push   %esi
f0102e6e:	e8 39 e2 ff ff       	call   f01010ac <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e73:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e76:	8d 83 5c db fe ff    	lea    -0x124a4(%ebx),%eax
f0102e7c:	89 04 24             	mov    %eax,(%esp)
f0102e7f:	e8 a3 02 00 00       	call   f0103127 <cprintf>
}
f0102e84:	83 c4 10             	add    $0x10,%esp
f0102e87:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e8a:	5b                   	pop    %ebx
f0102e8b:	5e                   	pop    %esi
f0102e8c:	5f                   	pop    %edi
f0102e8d:	5d                   	pop    %ebp
f0102e8e:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e8f:	50                   	push   %eax
f0102e90:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e93:	8d 83 d8 d4 fe ff    	lea    -0x12b28(%ebx),%eax
f0102e99:	50                   	push   %eax
f0102e9a:	68 e1 00 00 00       	push   $0xe1
f0102e9f:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102ea5:	50                   	push   %eax
f0102ea6:	e8 ee d1 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102eab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eae:	8d 83 59 dc fe ff    	lea    -0x123a7(%ebx),%eax
f0102eb4:	50                   	push   %eax
f0102eb5:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102ebb:	50                   	push   %eax
f0102ebc:	68 a3 03 00 00       	push   $0x3a3
f0102ec1:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102ec7:	50                   	push   %eax
f0102ec8:	e8 cc d1 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102ecd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ed0:	8d 83 6f dc fe ff    	lea    -0x12391(%ebx),%eax
f0102ed6:	50                   	push   %eax
f0102ed7:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102edd:	50                   	push   %eax
f0102ede:	68 a4 03 00 00       	push   $0x3a4
f0102ee3:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102ee9:	50                   	push   %eax
f0102eea:	e8 aa d1 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102eef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ef2:	8d 83 85 dc fe ff    	lea    -0x1237b(%ebx),%eax
f0102ef8:	50                   	push   %eax
f0102ef9:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102eff:	50                   	push   %eax
f0102f00:	68 a5 03 00 00       	push   $0x3a5
f0102f05:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102f0b:	50                   	push   %eax
f0102f0c:	e8 88 d1 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f11:	50                   	push   %eax
f0102f12:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f0102f18:	50                   	push   %eax
f0102f19:	6a 59                	push   $0x59
f0102f1b:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f0102f21:	50                   	push   %eax
f0102f22:	e8 72 d1 ff ff       	call   f0100099 <_panic>
f0102f27:	50                   	push   %eax
f0102f28:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f0102f2e:	50                   	push   %eax
f0102f2f:	6a 59                	push   $0x59
f0102f31:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f0102f37:	50                   	push   %eax
f0102f38:	e8 5c d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102f3d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f40:	8d 83 56 dd fe ff    	lea    -0x122aa(%ebx),%eax
f0102f46:	50                   	push   %eax
f0102f47:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102f4d:	50                   	push   %eax
f0102f4e:	68 aa 03 00 00       	push   $0x3aa
f0102f53:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102f59:	50                   	push   %eax
f0102f5a:	e8 3a d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f5f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f62:	8d 83 e8 da fe ff    	lea    -0x12518(%ebx),%eax
f0102f68:	50                   	push   %eax
f0102f69:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102f6f:	50                   	push   %eax
f0102f70:	68 ab 03 00 00       	push   $0x3ab
f0102f75:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102f7b:	50                   	push   %eax
f0102f7c:	e8 18 d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f81:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f84:	8d 83 0c db fe ff    	lea    -0x124f4(%ebx),%eax
f0102f8a:	50                   	push   %eax
f0102f8b:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102f91:	50                   	push   %eax
f0102f92:	68 ad 03 00 00       	push   $0x3ad
f0102f97:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102f9d:	50                   	push   %eax
f0102f9e:	e8 f6 d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102fa3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fa6:	8d 83 78 dd fe ff    	lea    -0x12288(%ebx),%eax
f0102fac:	50                   	push   %eax
f0102fad:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102fb3:	50                   	push   %eax
f0102fb4:	68 ae 03 00 00       	push   $0x3ae
f0102fb9:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102fbf:	50                   	push   %eax
f0102fc0:	e8 d4 d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102fc5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fc8:	8d 83 e2 dd fe ff    	lea    -0x1221e(%ebx),%eax
f0102fce:	50                   	push   %eax
f0102fcf:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0102fd5:	50                   	push   %eax
f0102fd6:	68 af 03 00 00       	push   $0x3af
f0102fdb:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0102fe1:	50                   	push   %eax
f0102fe2:	e8 b2 d0 ff ff       	call   f0100099 <_panic>
f0102fe7:	50                   	push   %eax
f0102fe8:	8d 83 cc d3 fe ff    	lea    -0x12c34(%ebx),%eax
f0102fee:	50                   	push   %eax
f0102fef:	6a 59                	push   $0x59
f0102ff1:	8d 83 94 db fe ff    	lea    -0x1246c(%ebx),%eax
f0102ff7:	50                   	push   %eax
f0102ff8:	e8 9c d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ffd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103000:	8d 83 30 db fe ff    	lea    -0x124d0(%ebx),%eax
f0103006:	50                   	push   %eax
f0103007:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010300d:	50                   	push   %eax
f010300e:	68 b1 03 00 00       	push   $0x3b1
f0103013:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f0103019:	50                   	push   %eax
f010301a:	e8 7a d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010301f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103022:	8d 83 b0 dd fe ff    	lea    -0x12250(%ebx),%eax
f0103028:	50                   	push   %eax
f0103029:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f010302f:	50                   	push   %eax
f0103030:	68 b3 03 00 00       	push   $0x3b3
f0103035:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010303b:	50                   	push   %eax
f010303c:	e8 58 d0 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103041:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103044:	8d 83 74 d6 fe ff    	lea    -0x1298c(%ebx),%eax
f010304a:	50                   	push   %eax
f010304b:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0103051:	50                   	push   %eax
f0103052:	68 b6 03 00 00       	push   $0x3b6
f0103057:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010305d:	50                   	push   %eax
f010305e:	e8 36 d0 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0103063:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103066:	8d 83 67 dd fe ff    	lea    -0x12299(%ebx),%eax
f010306c:	50                   	push   %eax
f010306d:	8d 83 ae db fe ff    	lea    -0x12452(%ebx),%eax
f0103073:	50                   	push   %eax
f0103074:	68 b8 03 00 00       	push   $0x3b8
f0103079:	8d 83 88 db fe ff    	lea    -0x12478(%ebx),%eax
f010307f:	50                   	push   %eax
f0103080:	e8 14 d0 ff ff       	call   f0100099 <_panic>

f0103085 <tlb_invalidate>:
{
f0103085:	55                   	push   %ebp
f0103086:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103088:	8b 45 0c             	mov    0xc(%ebp),%eax
f010308b:	0f 01 38             	invlpg (%eax)
}
f010308e:	5d                   	pop    %ebp
f010308f:	c3                   	ret    

f0103090 <__x86.get_pc_thunk.dx>:
f0103090:	8b 14 24             	mov    (%esp),%edx
f0103093:	c3                   	ret    

f0103094 <__x86.get_pc_thunk.cx>:
f0103094:	8b 0c 24             	mov    (%esp),%ecx
f0103097:	c3                   	ret    

f0103098 <__x86.get_pc_thunk.si>:
f0103098:	8b 34 24             	mov    (%esp),%esi
f010309b:	c3                   	ret    

f010309c <__x86.get_pc_thunk.di>:
f010309c:	8b 3c 24             	mov    (%esp),%edi
f010309f:	c3                   	ret    

f01030a0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01030a0:	55                   	push   %ebp
f01030a1:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01030a6:	ba 70 00 00 00       	mov    $0x70,%edx
f01030ab:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01030ac:	ba 71 00 00 00       	mov    $0x71,%edx
f01030b1:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01030b2:	0f b6 c0             	movzbl %al,%eax
}
f01030b5:	5d                   	pop    %ebp
f01030b6:	c3                   	ret    

f01030b7 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01030b7:	55                   	push   %ebp
f01030b8:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01030bd:	ba 70 00 00 00       	mov    $0x70,%edx
f01030c2:	ee                   	out    %al,(%dx)
f01030c3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030c6:	ba 71 00 00 00       	mov    $0x71,%edx
f01030cb:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01030cc:	5d                   	pop    %ebp
f01030cd:	c3                   	ret    

f01030ce <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01030ce:	55                   	push   %ebp
f01030cf:	89 e5                	mov    %esp,%ebp
f01030d1:	53                   	push   %ebx
f01030d2:	83 ec 10             	sub    $0x10,%esp
f01030d5:	e8 75 d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01030da:	81 c3 32 42 01 00    	add    $0x14232,%ebx
	cputchar(ch);
f01030e0:	ff 75 08             	pushl  0x8(%ebp)
f01030e3:	e8 de d5 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f01030e8:	83 c4 10             	add    $0x10,%esp
f01030eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030ee:	c9                   	leave  
f01030ef:	c3                   	ret    

f01030f0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01030f0:	55                   	push   %ebp
f01030f1:	89 e5                	mov    %esp,%ebp
f01030f3:	53                   	push   %ebx
f01030f4:	83 ec 14             	sub    $0x14,%esp
f01030f7:	e8 53 d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01030fc:	81 c3 10 42 01 00    	add    $0x14210,%ebx
	int cnt = 0;
f0103102:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103109:	ff 75 0c             	pushl  0xc(%ebp)
f010310c:	ff 75 08             	pushl  0x8(%ebp)
f010310f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103112:	50                   	push   %eax
f0103113:	8d 83 c2 bd fe ff    	lea    -0x1423e(%ebx),%eax
f0103119:	50                   	push   %eax
f010311a:	e8 98 04 00 00       	call   f01035b7 <vprintfmt>
	return cnt;
}
f010311f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103122:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103125:	c9                   	leave  
f0103126:	c3                   	ret    

f0103127 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103127:	55                   	push   %ebp
f0103128:	89 e5                	mov    %esp,%ebp
f010312a:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010312d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103130:	50                   	push   %eax
f0103131:	ff 75 08             	pushl  0x8(%ebp)
f0103134:	e8 b7 ff ff ff       	call   f01030f0 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103139:	c9                   	leave  
f010313a:	c3                   	ret    

f010313b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010313b:	55                   	push   %ebp
f010313c:	89 e5                	mov    %esp,%ebp
f010313e:	57                   	push   %edi
f010313f:	56                   	push   %esi
f0103140:	53                   	push   %ebx
f0103141:	83 ec 14             	sub    $0x14,%esp
f0103144:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103147:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010314a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010314d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103150:	8b 32                	mov    (%edx),%esi
f0103152:	8b 01                	mov    (%ecx),%eax
f0103154:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103157:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010315e:	eb 2f                	jmp    f010318f <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103160:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103163:	39 c6                	cmp    %eax,%esi
f0103165:	7f 49                	jg     f01031b0 <stab_binsearch+0x75>
f0103167:	0f b6 0a             	movzbl (%edx),%ecx
f010316a:	83 ea 0c             	sub    $0xc,%edx
f010316d:	39 f9                	cmp    %edi,%ecx
f010316f:	75 ef                	jne    f0103160 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103171:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103174:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103177:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010317b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010317e:	73 35                	jae    f01031b5 <stab_binsearch+0x7a>
			*region_left = m;
f0103180:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103183:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0103185:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0103188:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f010318f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103192:	7f 4e                	jg     f01031e2 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0103194:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103197:	01 f0                	add    %esi,%eax
f0103199:	89 c3                	mov    %eax,%ebx
f010319b:	c1 eb 1f             	shr    $0x1f,%ebx
f010319e:	01 c3                	add    %eax,%ebx
f01031a0:	d1 fb                	sar    %ebx
f01031a2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01031a5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01031a8:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01031ac:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01031ae:	eb b3                	jmp    f0103163 <stab_binsearch+0x28>
			l = true_m + 1;
f01031b0:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01031b3:	eb da                	jmp    f010318f <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01031b5:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01031b8:	76 14                	jbe    f01031ce <stab_binsearch+0x93>
			*region_right = m - 1;
f01031ba:	83 e8 01             	sub    $0x1,%eax
f01031bd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01031c0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01031c3:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f01031c5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031cc:	eb c1                	jmp    f010318f <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01031ce:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031d1:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01031d3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01031d7:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f01031d9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031e0:	eb ad                	jmp    f010318f <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01031e2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01031e6:	74 16                	je     f01031fe <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01031e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031eb:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01031ed:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031f0:	8b 0e                	mov    (%esi),%ecx
f01031f2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031f5:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01031f8:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01031fc:	eb 12                	jmp    f0103210 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01031fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103201:	8b 00                	mov    (%eax),%eax
f0103203:	83 e8 01             	sub    $0x1,%eax
f0103206:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103209:	89 07                	mov    %eax,(%edi)
f010320b:	eb 16                	jmp    f0103223 <stab_binsearch+0xe8>
		     l--)
f010320d:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103210:	39 c1                	cmp    %eax,%ecx
f0103212:	7d 0a                	jge    f010321e <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103214:	0f b6 1a             	movzbl (%edx),%ebx
f0103217:	83 ea 0c             	sub    $0xc,%edx
f010321a:	39 fb                	cmp    %edi,%ebx
f010321c:	75 ef                	jne    f010320d <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f010321e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103221:	89 07                	mov    %eax,(%edi)
	}
}
f0103223:	83 c4 14             	add    $0x14,%esp
f0103226:	5b                   	pop    %ebx
f0103227:	5e                   	pop    %esi
f0103228:	5f                   	pop    %edi
f0103229:	5d                   	pop    %ebp
f010322a:	c3                   	ret    

f010322b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010322b:	55                   	push   %ebp
f010322c:	89 e5                	mov    %esp,%ebp
f010322e:	57                   	push   %edi
f010322f:	56                   	push   %esi
f0103230:	53                   	push   %ebx
f0103231:	83 ec 3c             	sub    $0x3c,%esp
f0103234:	e8 16 cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103239:	81 c3 d3 40 01 00    	add    $0x140d3,%ebx
f010323f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103242:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103245:	8d 83 6b de fe ff    	lea    -0x12195(%ebx),%eax
f010324b:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f010324d:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103254:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103257:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010325e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103261:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103268:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010326e:	0f 86 37 01 00 00    	jbe    f01033ab <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103274:	c7 c0 15 bd 10 f0    	mov    $0xf010bd15,%eax
f010327a:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f0103280:	0f 86 04 02 00 00    	jbe    f010348a <debuginfo_eip+0x25f>
f0103286:	c7 c0 6d db 10 f0    	mov    $0xf010db6d,%eax
f010328c:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103290:	0f 85 fb 01 00 00    	jne    f0103491 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103296:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010329d:	c7 c0 90 53 10 f0    	mov    $0xf0105390,%eax
f01032a3:	c7 c2 14 bd 10 f0    	mov    $0xf010bd14,%edx
f01032a9:	29 c2                	sub    %eax,%edx
f01032ab:	c1 fa 02             	sar    $0x2,%edx
f01032ae:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032b4:	83 ea 01             	sub    $0x1,%edx
f01032b7:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01032ba:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01032bd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01032c0:	83 ec 08             	sub    $0x8,%esp
f01032c3:	57                   	push   %edi
f01032c4:	6a 64                	push   $0x64
f01032c6:	e8 70 fe ff ff       	call   f010313b <stab_binsearch>
	if (lfile == 0)
f01032cb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032ce:	83 c4 10             	add    $0x10,%esp
f01032d1:	85 c0                	test   %eax,%eax
f01032d3:	0f 84 bf 01 00 00    	je     f0103498 <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01032d9:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01032dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032df:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01032e2:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01032e5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01032e8:	83 ec 08             	sub    $0x8,%esp
f01032eb:	57                   	push   %edi
f01032ec:	6a 24                	push   $0x24
f01032ee:	c7 c0 90 53 10 f0    	mov    $0xf0105390,%eax
f01032f4:	e8 42 fe ff ff       	call   f010313b <stab_binsearch>

	if (lfun <= rfun) {
f01032f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01032fc:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01032ff:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0103302:	83 c4 10             	add    $0x10,%esp
f0103305:	39 c8                	cmp    %ecx,%eax
f0103307:	0f 8f b6 00 00 00    	jg     f01033c3 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010330d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103310:	c7 c1 90 53 10 f0    	mov    $0xf0105390,%ecx
f0103316:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0103319:	8b 11                	mov    (%ecx),%edx
f010331b:	89 55 c0             	mov    %edx,-0x40(%ebp)
f010331e:	c7 c2 6d db 10 f0    	mov    $0xf010db6d,%edx
f0103324:	81 ea 15 bd 10 f0    	sub    $0xf010bd15,%edx
f010332a:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f010332d:	73 0c                	jae    f010333b <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010332f:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103332:	81 c2 15 bd 10 f0    	add    $0xf010bd15,%edx
f0103338:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010333b:	8b 51 08             	mov    0x8(%ecx),%edx
f010333e:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103341:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0103343:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103346:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103349:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010334c:	83 ec 08             	sub    $0x8,%esp
f010334f:	6a 3a                	push   $0x3a
f0103351:	ff 76 08             	pushl  0x8(%esi)
f0103354:	e8 c3 09 00 00       	call   f0103d1c <strfind>
f0103359:	2b 46 08             	sub    0x8(%esi),%eax
f010335c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010335f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103362:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103365:	83 c4 08             	add    $0x8,%esp
f0103368:	57                   	push   %edi
f0103369:	6a 44                	push   $0x44
f010336b:	c7 c0 90 53 10 f0    	mov    $0xf0105390,%eax
f0103371:	e8 c5 fd ff ff       	call   f010313b <stab_binsearch>
	if(lline<=rline){
f0103376:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103379:	83 c4 10             	add    $0x10,%esp
f010337c:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f010337f:	0f 8f 1a 01 00 00    	jg     f010349f <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f0103385:	89 d0                	mov    %edx,%eax
f0103387:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010338a:	c1 e2 02             	shl    $0x2,%edx
f010338d:	c7 c1 90 53 10 f0    	mov    $0xf0105390,%ecx
f0103393:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0103398:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010339b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010339e:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f01033a2:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01033a6:	89 75 0c             	mov    %esi,0xc(%ebp)
f01033a9:	eb 36                	jmp    f01033e1 <debuginfo_eip+0x1b6>
  	        panic("User address");
f01033ab:	83 ec 04             	sub    $0x4,%esp
f01033ae:	8d 83 75 de fe ff    	lea    -0x1218b(%ebx),%eax
f01033b4:	50                   	push   %eax
f01033b5:	6a 7f                	push   $0x7f
f01033b7:	8d 83 82 de fe ff    	lea    -0x1217e(%ebx),%eax
f01033bd:	50                   	push   %eax
f01033be:	e8 d6 cc ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f01033c3:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01033c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01033cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033cf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01033d2:	e9 75 ff ff ff       	jmp    f010334c <debuginfo_eip+0x121>
f01033d7:	83 e8 01             	sub    $0x1,%eax
f01033da:	83 ea 0c             	sub    $0xc,%edx
f01033dd:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01033e1:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f01033e4:	39 c7                	cmp    %eax,%edi
f01033e6:	7f 24                	jg     f010340c <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f01033e8:	0f b6 0a             	movzbl (%edx),%ecx
f01033eb:	80 f9 84             	cmp    $0x84,%cl
f01033ee:	74 46                	je     f0103436 <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01033f0:	80 f9 64             	cmp    $0x64,%cl
f01033f3:	75 e2                	jne    f01033d7 <debuginfo_eip+0x1ac>
f01033f5:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f01033f9:	74 dc                	je     f01033d7 <debuginfo_eip+0x1ac>
f01033fb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033fe:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103402:	74 3b                	je     f010343f <debuginfo_eip+0x214>
f0103404:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103407:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010340a:	eb 33                	jmp    f010343f <debuginfo_eip+0x214>
f010340c:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010340f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103412:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103415:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f010341a:	39 fa                	cmp    %edi,%edx
f010341c:	0f 8d 89 00 00 00    	jge    f01034ab <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0103422:	83 c2 01             	add    $0x1,%edx
f0103425:	89 d0                	mov    %edx,%eax
f0103427:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f010342a:	c7 c2 90 53 10 f0    	mov    $0xf0105390,%edx
f0103430:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0103434:	eb 3b                	jmp    f0103471 <debuginfo_eip+0x246>
f0103436:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103439:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010343d:	75 26                	jne    f0103465 <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010343f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103442:	c7 c0 90 53 10 f0    	mov    $0xf0105390,%eax
f0103448:	8b 14 90             	mov    (%eax,%edx,4),%edx
f010344b:	c7 c0 6d db 10 f0    	mov    $0xf010db6d,%eax
f0103451:	81 e8 15 bd 10 f0    	sub    $0xf010bd15,%eax
f0103457:	39 c2                	cmp    %eax,%edx
f0103459:	73 b4                	jae    f010340f <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010345b:	81 c2 15 bd 10 f0    	add    $0xf010bd15,%edx
f0103461:	89 16                	mov    %edx,(%esi)
f0103463:	eb aa                	jmp    f010340f <debuginfo_eip+0x1e4>
f0103465:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103468:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010346b:	eb d2                	jmp    f010343f <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f010346d:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0103471:	39 c7                	cmp    %eax,%edi
f0103473:	7e 31                	jle    f01034a6 <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103475:	0f b6 0a             	movzbl (%edx),%ecx
f0103478:	83 c0 01             	add    $0x1,%eax
f010347b:	83 c2 0c             	add    $0xc,%edx
f010347e:	80 f9 a0             	cmp    $0xa0,%cl
f0103481:	74 ea                	je     f010346d <debuginfo_eip+0x242>
	return 0;
f0103483:	b8 00 00 00 00       	mov    $0x0,%eax
f0103488:	eb 21                	jmp    f01034ab <debuginfo_eip+0x280>
		return -1;
f010348a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010348f:	eb 1a                	jmp    f01034ab <debuginfo_eip+0x280>
f0103491:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103496:	eb 13                	jmp    f01034ab <debuginfo_eip+0x280>
		return -1;
f0103498:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010349d:	eb 0c                	jmp    f01034ab <debuginfo_eip+0x280>
		return -1;
f010349f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034a4:	eb 05                	jmp    f01034ab <debuginfo_eip+0x280>
	return 0;
f01034a6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034ae:	5b                   	pop    %ebx
f01034af:	5e                   	pop    %esi
f01034b0:	5f                   	pop    %edi
f01034b1:	5d                   	pop    %ebp
f01034b2:	c3                   	ret    

f01034b3 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01034b3:	55                   	push   %ebp
f01034b4:	89 e5                	mov    %esp,%ebp
f01034b6:	57                   	push   %edi
f01034b7:	56                   	push   %esi
f01034b8:	53                   	push   %ebx
f01034b9:	83 ec 2c             	sub    $0x2c,%esp
f01034bc:	e8 d3 fb ff ff       	call   f0103094 <__x86.get_pc_thunk.cx>
f01034c1:	81 c1 4b 3e 01 00    	add    $0x13e4b,%ecx
f01034c7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01034ca:	89 c7                	mov    %eax,%edi
f01034cc:	89 d6                	mov    %edx,%esi
f01034ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01034d1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034d4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01034d7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01034da:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01034dd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01034e2:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01034e5:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01034e8:	39 d3                	cmp    %edx,%ebx
f01034ea:	72 09                	jb     f01034f5 <printnum+0x42>
f01034ec:	39 45 10             	cmp    %eax,0x10(%ebp)
f01034ef:	0f 87 83 00 00 00    	ja     f0103578 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01034f5:	83 ec 0c             	sub    $0xc,%esp
f01034f8:	ff 75 18             	pushl  0x18(%ebp)
f01034fb:	8b 45 14             	mov    0x14(%ebp),%eax
f01034fe:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103501:	53                   	push   %ebx
f0103502:	ff 75 10             	pushl  0x10(%ebp)
f0103505:	83 ec 08             	sub    $0x8,%esp
f0103508:	ff 75 dc             	pushl  -0x24(%ebp)
f010350b:	ff 75 d8             	pushl  -0x28(%ebp)
f010350e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103511:	ff 75 d0             	pushl  -0x30(%ebp)
f0103514:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103517:	e8 24 0a 00 00       	call   f0103f40 <__udivdi3>
f010351c:	83 c4 18             	add    $0x18,%esp
f010351f:	52                   	push   %edx
f0103520:	50                   	push   %eax
f0103521:	89 f2                	mov    %esi,%edx
f0103523:	89 f8                	mov    %edi,%eax
f0103525:	e8 89 ff ff ff       	call   f01034b3 <printnum>
f010352a:	83 c4 20             	add    $0x20,%esp
f010352d:	eb 13                	jmp    f0103542 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010352f:	83 ec 08             	sub    $0x8,%esp
f0103532:	56                   	push   %esi
f0103533:	ff 75 18             	pushl  0x18(%ebp)
f0103536:	ff d7                	call   *%edi
f0103538:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f010353b:	83 eb 01             	sub    $0x1,%ebx
f010353e:	85 db                	test   %ebx,%ebx
f0103540:	7f ed                	jg     f010352f <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103542:	83 ec 08             	sub    $0x8,%esp
f0103545:	56                   	push   %esi
f0103546:	83 ec 04             	sub    $0x4,%esp
f0103549:	ff 75 dc             	pushl  -0x24(%ebp)
f010354c:	ff 75 d8             	pushl  -0x28(%ebp)
f010354f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103552:	ff 75 d0             	pushl  -0x30(%ebp)
f0103555:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103558:	89 f3                	mov    %esi,%ebx
f010355a:	e8 01 0b 00 00       	call   f0104060 <__umoddi3>
f010355f:	83 c4 14             	add    $0x14,%esp
f0103562:	0f be 84 06 90 de fe 	movsbl -0x12170(%esi,%eax,1),%eax
f0103569:	ff 
f010356a:	50                   	push   %eax
f010356b:	ff d7                	call   *%edi
}
f010356d:	83 c4 10             	add    $0x10,%esp
f0103570:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103573:	5b                   	pop    %ebx
f0103574:	5e                   	pop    %esi
f0103575:	5f                   	pop    %edi
f0103576:	5d                   	pop    %ebp
f0103577:	c3                   	ret    
f0103578:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010357b:	eb be                	jmp    f010353b <printnum+0x88>

f010357d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010357d:	55                   	push   %ebp
f010357e:	89 e5                	mov    %esp,%ebp
f0103580:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103583:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103587:	8b 10                	mov    (%eax),%edx
f0103589:	3b 50 04             	cmp    0x4(%eax),%edx
f010358c:	73 0a                	jae    f0103598 <sprintputch+0x1b>
		*b->buf++ = ch;
f010358e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103591:	89 08                	mov    %ecx,(%eax)
f0103593:	8b 45 08             	mov    0x8(%ebp),%eax
f0103596:	88 02                	mov    %al,(%edx)
}
f0103598:	5d                   	pop    %ebp
f0103599:	c3                   	ret    

f010359a <printfmt>:
{
f010359a:	55                   	push   %ebp
f010359b:	89 e5                	mov    %esp,%ebp
f010359d:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01035a0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01035a3:	50                   	push   %eax
f01035a4:	ff 75 10             	pushl  0x10(%ebp)
f01035a7:	ff 75 0c             	pushl  0xc(%ebp)
f01035aa:	ff 75 08             	pushl  0x8(%ebp)
f01035ad:	e8 05 00 00 00       	call   f01035b7 <vprintfmt>
}
f01035b2:	83 c4 10             	add    $0x10,%esp
f01035b5:	c9                   	leave  
f01035b6:	c3                   	ret    

f01035b7 <vprintfmt>:
{
f01035b7:	55                   	push   %ebp
f01035b8:	89 e5                	mov    %esp,%ebp
f01035ba:	57                   	push   %edi
f01035bb:	56                   	push   %esi
f01035bc:	53                   	push   %ebx
f01035bd:	83 ec 2c             	sub    $0x2c,%esp
f01035c0:	e8 8a cb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01035c5:	81 c3 47 3d 01 00    	add    $0x13d47,%ebx
f01035cb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01035ce:	8b 7d 10             	mov    0x10(%ebp),%edi
f01035d1:	e9 c3 03 00 00       	jmp    f0103999 <.L35+0x48>
		padc = ' ';
f01035d6:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01035da:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01035e1:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f01035e8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01035ef:	b9 00 00 00 00       	mov    $0x0,%ecx
f01035f4:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035f7:	8d 47 01             	lea    0x1(%edi),%eax
f01035fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01035fd:	0f b6 17             	movzbl (%edi),%edx
f0103600:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103603:	3c 55                	cmp    $0x55,%al
f0103605:	0f 87 16 04 00 00    	ja     f0103a21 <.L22>
f010360b:	0f b6 c0             	movzbl %al,%eax
f010360e:	89 d9                	mov    %ebx,%ecx
f0103610:	03 8c 83 1c df fe ff 	add    -0x120e4(%ebx,%eax,4),%ecx
f0103617:	ff e1                	jmp    *%ecx

f0103619 <.L69>:
f0103619:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f010361c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0103620:	eb d5                	jmp    f01035f7 <vprintfmt+0x40>

f0103622 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0103622:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0103625:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103629:	eb cc                	jmp    f01035f7 <vprintfmt+0x40>

f010362b <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f010362b:	0f b6 d2             	movzbl %dl,%edx
f010362e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103631:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0103636:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103639:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010363d:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103640:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103643:	83 f9 09             	cmp    $0x9,%ecx
f0103646:	77 55                	ja     f010369d <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0103648:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010364b:	eb e9                	jmp    f0103636 <.L29+0xb>

f010364d <.L26>:
			precision = va_arg(ap, int);
f010364d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103650:	8b 00                	mov    (%eax),%eax
f0103652:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103655:	8b 45 14             	mov    0x14(%ebp),%eax
f0103658:	8d 40 04             	lea    0x4(%eax),%eax
f010365b:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010365e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103661:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103665:	79 90                	jns    f01035f7 <vprintfmt+0x40>
				width = precision, precision = -1;
f0103667:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010366a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010366d:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0103674:	eb 81                	jmp    f01035f7 <vprintfmt+0x40>

f0103676 <.L27>:
f0103676:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103679:	85 c0                	test   %eax,%eax
f010367b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103680:	0f 49 d0             	cmovns %eax,%edx
f0103683:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103686:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103689:	e9 69 ff ff ff       	jmp    f01035f7 <vprintfmt+0x40>

f010368e <.L23>:
f010368e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103691:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103698:	e9 5a ff ff ff       	jmp    f01035f7 <vprintfmt+0x40>
f010369d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01036a0:	eb bf                	jmp    f0103661 <.L26+0x14>

f01036a2 <.L33>:
			lflag++;
f01036a2:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01036a6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01036a9:	e9 49 ff ff ff       	jmp    f01035f7 <vprintfmt+0x40>

f01036ae <.L30>:
			putch(va_arg(ap, int), putdat);
f01036ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01036b1:	8d 78 04             	lea    0x4(%eax),%edi
f01036b4:	83 ec 08             	sub    $0x8,%esp
f01036b7:	56                   	push   %esi
f01036b8:	ff 30                	pushl  (%eax)
f01036ba:	ff 55 08             	call   *0x8(%ebp)
			break;
f01036bd:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01036c0:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01036c3:	e9 ce 02 00 00       	jmp    f0103996 <.L35+0x45>

f01036c8 <.L32>:
			err = va_arg(ap, int);
f01036c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01036cb:	8d 78 04             	lea    0x4(%eax),%edi
f01036ce:	8b 00                	mov    (%eax),%eax
f01036d0:	99                   	cltd   
f01036d1:	31 d0                	xor    %edx,%eax
f01036d3:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01036d5:	83 f8 06             	cmp    $0x6,%eax
f01036d8:	7f 27                	jg     f0103701 <.L32+0x39>
f01036da:	8b 94 83 44 1d 00 00 	mov    0x1d44(%ebx,%eax,4),%edx
f01036e1:	85 d2                	test   %edx,%edx
f01036e3:	74 1c                	je     f0103701 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01036e5:	52                   	push   %edx
f01036e6:	8d 83 c0 db fe ff    	lea    -0x12440(%ebx),%eax
f01036ec:	50                   	push   %eax
f01036ed:	56                   	push   %esi
f01036ee:	ff 75 08             	pushl  0x8(%ebp)
f01036f1:	e8 a4 fe ff ff       	call   f010359a <printfmt>
f01036f6:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01036f9:	89 7d 14             	mov    %edi,0x14(%ebp)
f01036fc:	e9 95 02 00 00       	jmp    f0103996 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103701:	50                   	push   %eax
f0103702:	8d 83 a8 de fe ff    	lea    -0x12158(%ebx),%eax
f0103708:	50                   	push   %eax
f0103709:	56                   	push   %esi
f010370a:	ff 75 08             	pushl  0x8(%ebp)
f010370d:	e8 88 fe ff ff       	call   f010359a <printfmt>
f0103712:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103715:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103718:	e9 79 02 00 00       	jmp    f0103996 <.L35+0x45>

f010371d <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f010371d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103720:	83 c0 04             	add    $0x4,%eax
f0103723:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103726:	8b 45 14             	mov    0x14(%ebp),%eax
f0103729:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010372b:	85 ff                	test   %edi,%edi
f010372d:	8d 83 a1 de fe ff    	lea    -0x1215f(%ebx),%eax
f0103733:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103736:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010373a:	0f 8e b5 00 00 00    	jle    f01037f5 <.L36+0xd8>
f0103740:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103744:	75 08                	jne    f010374e <.L36+0x31>
f0103746:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103749:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010374c:	eb 6d                	jmp    f01037bb <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f010374e:	83 ec 08             	sub    $0x8,%esp
f0103751:	ff 75 cc             	pushl  -0x34(%ebp)
f0103754:	57                   	push   %edi
f0103755:	e8 7e 04 00 00       	call   f0103bd8 <strnlen>
f010375a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010375d:	29 c2                	sub    %eax,%edx
f010375f:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0103762:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103765:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103769:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010376c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010376f:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103771:	eb 10                	jmp    f0103783 <.L36+0x66>
					putch(padc, putdat);
f0103773:	83 ec 08             	sub    $0x8,%esp
f0103776:	56                   	push   %esi
f0103777:	ff 75 e0             	pushl  -0x20(%ebp)
f010377a:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010377d:	83 ef 01             	sub    $0x1,%edi
f0103780:	83 c4 10             	add    $0x10,%esp
f0103783:	85 ff                	test   %edi,%edi
f0103785:	7f ec                	jg     f0103773 <.L36+0x56>
f0103787:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010378a:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010378d:	85 d2                	test   %edx,%edx
f010378f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103794:	0f 49 c2             	cmovns %edx,%eax
f0103797:	29 c2                	sub    %eax,%edx
f0103799:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010379c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010379f:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01037a2:	eb 17                	jmp    f01037bb <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01037a4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01037a8:	75 30                	jne    f01037da <.L36+0xbd>
					putch(ch, putdat);
f01037aa:	83 ec 08             	sub    $0x8,%esp
f01037ad:	ff 75 0c             	pushl  0xc(%ebp)
f01037b0:	50                   	push   %eax
f01037b1:	ff 55 08             	call   *0x8(%ebp)
f01037b4:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01037b7:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01037bb:	83 c7 01             	add    $0x1,%edi
f01037be:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01037c2:	0f be c2             	movsbl %dl,%eax
f01037c5:	85 c0                	test   %eax,%eax
f01037c7:	74 52                	je     f010381b <.L36+0xfe>
f01037c9:	85 f6                	test   %esi,%esi
f01037cb:	78 d7                	js     f01037a4 <.L36+0x87>
f01037cd:	83 ee 01             	sub    $0x1,%esi
f01037d0:	79 d2                	jns    f01037a4 <.L36+0x87>
f01037d2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01037d5:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01037d8:	eb 32                	jmp    f010380c <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01037da:	0f be d2             	movsbl %dl,%edx
f01037dd:	83 ea 20             	sub    $0x20,%edx
f01037e0:	83 fa 5e             	cmp    $0x5e,%edx
f01037e3:	76 c5                	jbe    f01037aa <.L36+0x8d>
					putch('?', putdat);
f01037e5:	83 ec 08             	sub    $0x8,%esp
f01037e8:	ff 75 0c             	pushl  0xc(%ebp)
f01037eb:	6a 3f                	push   $0x3f
f01037ed:	ff 55 08             	call   *0x8(%ebp)
f01037f0:	83 c4 10             	add    $0x10,%esp
f01037f3:	eb c2                	jmp    f01037b7 <.L36+0x9a>
f01037f5:	89 75 0c             	mov    %esi,0xc(%ebp)
f01037f8:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01037fb:	eb be                	jmp    f01037bb <.L36+0x9e>
				putch(' ', putdat);
f01037fd:	83 ec 08             	sub    $0x8,%esp
f0103800:	56                   	push   %esi
f0103801:	6a 20                	push   $0x20
f0103803:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0103806:	83 ef 01             	sub    $0x1,%edi
f0103809:	83 c4 10             	add    $0x10,%esp
f010380c:	85 ff                	test   %edi,%edi
f010380e:	7f ed                	jg     f01037fd <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0103810:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103813:	89 45 14             	mov    %eax,0x14(%ebp)
f0103816:	e9 7b 01 00 00       	jmp    f0103996 <.L35+0x45>
f010381b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010381e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103821:	eb e9                	jmp    f010380c <.L36+0xef>

f0103823 <.L31>:
f0103823:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103826:	83 f9 01             	cmp    $0x1,%ecx
f0103829:	7e 40                	jle    f010386b <.L31+0x48>
		return va_arg(*ap, long long);
f010382b:	8b 45 14             	mov    0x14(%ebp),%eax
f010382e:	8b 50 04             	mov    0x4(%eax),%edx
f0103831:	8b 00                	mov    (%eax),%eax
f0103833:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103836:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103839:	8b 45 14             	mov    0x14(%ebp),%eax
f010383c:	8d 40 08             	lea    0x8(%eax),%eax
f010383f:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103842:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103846:	79 55                	jns    f010389d <.L31+0x7a>
				putch('-', putdat);
f0103848:	83 ec 08             	sub    $0x8,%esp
f010384b:	56                   	push   %esi
f010384c:	6a 2d                	push   $0x2d
f010384e:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103851:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103854:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103857:	f7 da                	neg    %edx
f0103859:	83 d1 00             	adc    $0x0,%ecx
f010385c:	f7 d9                	neg    %ecx
f010385e:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103861:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103866:	e9 10 01 00 00       	jmp    f010397b <.L35+0x2a>
	else if (lflag)
f010386b:	85 c9                	test   %ecx,%ecx
f010386d:	75 17                	jne    f0103886 <.L31+0x63>
		return va_arg(*ap, int);
f010386f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103872:	8b 00                	mov    (%eax),%eax
f0103874:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103877:	99                   	cltd   
f0103878:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010387b:	8b 45 14             	mov    0x14(%ebp),%eax
f010387e:	8d 40 04             	lea    0x4(%eax),%eax
f0103881:	89 45 14             	mov    %eax,0x14(%ebp)
f0103884:	eb bc                	jmp    f0103842 <.L31+0x1f>
		return va_arg(*ap, long);
f0103886:	8b 45 14             	mov    0x14(%ebp),%eax
f0103889:	8b 00                	mov    (%eax),%eax
f010388b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010388e:	99                   	cltd   
f010388f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103892:	8b 45 14             	mov    0x14(%ebp),%eax
f0103895:	8d 40 04             	lea    0x4(%eax),%eax
f0103898:	89 45 14             	mov    %eax,0x14(%ebp)
f010389b:	eb a5                	jmp    f0103842 <.L31+0x1f>
			num = getint(&ap, lflag);
f010389d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01038a0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01038a3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038a8:	e9 ce 00 00 00       	jmp    f010397b <.L35+0x2a>

f01038ad <.L37>:
f01038ad:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01038b0:	83 f9 01             	cmp    $0x1,%ecx
f01038b3:	7e 18                	jle    f01038cd <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f01038b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01038b8:	8b 10                	mov    (%eax),%edx
f01038ba:	8b 48 04             	mov    0x4(%eax),%ecx
f01038bd:	8d 40 08             	lea    0x8(%eax),%eax
f01038c0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038c3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038c8:	e9 ae 00 00 00       	jmp    f010397b <.L35+0x2a>
	else if (lflag)
f01038cd:	85 c9                	test   %ecx,%ecx
f01038cf:	75 1a                	jne    f01038eb <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f01038d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01038d4:	8b 10                	mov    (%eax),%edx
f01038d6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038db:	8d 40 04             	lea    0x4(%eax),%eax
f01038de:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038e1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038e6:	e9 90 00 00 00       	jmp    f010397b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01038eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ee:	8b 10                	mov    (%eax),%edx
f01038f0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038f5:	8d 40 04             	lea    0x4(%eax),%eax
f01038f8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038fb:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103900:	eb 79                	jmp    f010397b <.L35+0x2a>

f0103902 <.L34>:
f0103902:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103905:	83 f9 01             	cmp    $0x1,%ecx
f0103908:	7e 15                	jle    f010391f <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f010390a:	8b 45 14             	mov    0x14(%ebp),%eax
f010390d:	8b 10                	mov    (%eax),%edx
f010390f:	8b 48 04             	mov    0x4(%eax),%ecx
f0103912:	8d 40 08             	lea    0x8(%eax),%eax
f0103915:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103918:	b8 08 00 00 00       	mov    $0x8,%eax
f010391d:	eb 5c                	jmp    f010397b <.L35+0x2a>
	else if (lflag)
f010391f:	85 c9                	test   %ecx,%ecx
f0103921:	75 17                	jne    f010393a <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0103923:	8b 45 14             	mov    0x14(%ebp),%eax
f0103926:	8b 10                	mov    (%eax),%edx
f0103928:	b9 00 00 00 00       	mov    $0x0,%ecx
f010392d:	8d 40 04             	lea    0x4(%eax),%eax
f0103930:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103933:	b8 08 00 00 00       	mov    $0x8,%eax
f0103938:	eb 41                	jmp    f010397b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010393a:	8b 45 14             	mov    0x14(%ebp),%eax
f010393d:	8b 10                	mov    (%eax),%edx
f010393f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103944:	8d 40 04             	lea    0x4(%eax),%eax
f0103947:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010394a:	b8 08 00 00 00       	mov    $0x8,%eax
f010394f:	eb 2a                	jmp    f010397b <.L35+0x2a>

f0103951 <.L35>:
			putch('0', putdat);
f0103951:	83 ec 08             	sub    $0x8,%esp
f0103954:	56                   	push   %esi
f0103955:	6a 30                	push   $0x30
f0103957:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010395a:	83 c4 08             	add    $0x8,%esp
f010395d:	56                   	push   %esi
f010395e:	6a 78                	push   $0x78
f0103960:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0103963:	8b 45 14             	mov    0x14(%ebp),%eax
f0103966:	8b 10                	mov    (%eax),%edx
f0103968:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010396d:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103970:	8d 40 04             	lea    0x4(%eax),%eax
f0103973:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103976:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010397b:	83 ec 0c             	sub    $0xc,%esp
f010397e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103982:	57                   	push   %edi
f0103983:	ff 75 e0             	pushl  -0x20(%ebp)
f0103986:	50                   	push   %eax
f0103987:	51                   	push   %ecx
f0103988:	52                   	push   %edx
f0103989:	89 f2                	mov    %esi,%edx
f010398b:	8b 45 08             	mov    0x8(%ebp),%eax
f010398e:	e8 20 fb ff ff       	call   f01034b3 <printnum>
			break;
f0103993:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103996:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103999:	83 c7 01             	add    $0x1,%edi
f010399c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01039a0:	83 f8 25             	cmp    $0x25,%eax
f01039a3:	0f 84 2d fc ff ff    	je     f01035d6 <vprintfmt+0x1f>
			if (ch == '\0')
f01039a9:	85 c0                	test   %eax,%eax
f01039ab:	0f 84 91 00 00 00    	je     f0103a42 <.L22+0x21>
			putch(ch, putdat);
f01039b1:	83 ec 08             	sub    $0x8,%esp
f01039b4:	56                   	push   %esi
f01039b5:	50                   	push   %eax
f01039b6:	ff 55 08             	call   *0x8(%ebp)
f01039b9:	83 c4 10             	add    $0x10,%esp
f01039bc:	eb db                	jmp    f0103999 <.L35+0x48>

f01039be <.L38>:
f01039be:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01039c1:	83 f9 01             	cmp    $0x1,%ecx
f01039c4:	7e 15                	jle    f01039db <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01039c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01039c9:	8b 10                	mov    (%eax),%edx
f01039cb:	8b 48 04             	mov    0x4(%eax),%ecx
f01039ce:	8d 40 08             	lea    0x8(%eax),%eax
f01039d1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01039d4:	b8 10 00 00 00       	mov    $0x10,%eax
f01039d9:	eb a0                	jmp    f010397b <.L35+0x2a>
	else if (lflag)
f01039db:	85 c9                	test   %ecx,%ecx
f01039dd:	75 17                	jne    f01039f6 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01039df:	8b 45 14             	mov    0x14(%ebp),%eax
f01039e2:	8b 10                	mov    (%eax),%edx
f01039e4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01039e9:	8d 40 04             	lea    0x4(%eax),%eax
f01039ec:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01039ef:	b8 10 00 00 00       	mov    $0x10,%eax
f01039f4:	eb 85                	jmp    f010397b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01039f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01039f9:	8b 10                	mov    (%eax),%edx
f01039fb:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a00:	8d 40 04             	lea    0x4(%eax),%eax
f0103a03:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103a06:	b8 10 00 00 00       	mov    $0x10,%eax
f0103a0b:	e9 6b ff ff ff       	jmp    f010397b <.L35+0x2a>

f0103a10 <.L25>:
			putch(ch, putdat);
f0103a10:	83 ec 08             	sub    $0x8,%esp
f0103a13:	56                   	push   %esi
f0103a14:	6a 25                	push   $0x25
f0103a16:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103a19:	83 c4 10             	add    $0x10,%esp
f0103a1c:	e9 75 ff ff ff       	jmp    f0103996 <.L35+0x45>

f0103a21 <.L22>:
			putch('%', putdat);
f0103a21:	83 ec 08             	sub    $0x8,%esp
f0103a24:	56                   	push   %esi
f0103a25:	6a 25                	push   $0x25
f0103a27:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103a2a:	83 c4 10             	add    $0x10,%esp
f0103a2d:	89 f8                	mov    %edi,%eax
f0103a2f:	eb 03                	jmp    f0103a34 <.L22+0x13>
f0103a31:	83 e8 01             	sub    $0x1,%eax
f0103a34:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103a38:	75 f7                	jne    f0103a31 <.L22+0x10>
f0103a3a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a3d:	e9 54 ff ff ff       	jmp    f0103996 <.L35+0x45>
}
f0103a42:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a45:	5b                   	pop    %ebx
f0103a46:	5e                   	pop    %esi
f0103a47:	5f                   	pop    %edi
f0103a48:	5d                   	pop    %ebp
f0103a49:	c3                   	ret    

f0103a4a <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103a4a:	55                   	push   %ebp
f0103a4b:	89 e5                	mov    %esp,%ebp
f0103a4d:	53                   	push   %ebx
f0103a4e:	83 ec 14             	sub    $0x14,%esp
f0103a51:	e8 f9 c6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103a56:	81 c3 b6 38 01 00    	add    $0x138b6,%ebx
f0103a5c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a5f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103a62:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103a65:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103a69:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103a6c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103a73:	85 c0                	test   %eax,%eax
f0103a75:	74 2b                	je     f0103aa2 <vsnprintf+0x58>
f0103a77:	85 d2                	test   %edx,%edx
f0103a79:	7e 27                	jle    f0103aa2 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103a7b:	ff 75 14             	pushl  0x14(%ebp)
f0103a7e:	ff 75 10             	pushl  0x10(%ebp)
f0103a81:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103a84:	50                   	push   %eax
f0103a85:	8d 83 71 c2 fe ff    	lea    -0x13d8f(%ebx),%eax
f0103a8b:	50                   	push   %eax
f0103a8c:	e8 26 fb ff ff       	call   f01035b7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103a91:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a94:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a9a:	83 c4 10             	add    $0x10,%esp
}
f0103a9d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103aa0:	c9                   	leave  
f0103aa1:	c3                   	ret    
		return -E_INVAL;
f0103aa2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103aa7:	eb f4                	jmp    f0103a9d <vsnprintf+0x53>

f0103aa9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103aa9:	55                   	push   %ebp
f0103aaa:	89 e5                	mov    %esp,%ebp
f0103aac:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103aaf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103ab2:	50                   	push   %eax
f0103ab3:	ff 75 10             	pushl  0x10(%ebp)
f0103ab6:	ff 75 0c             	pushl  0xc(%ebp)
f0103ab9:	ff 75 08             	pushl  0x8(%ebp)
f0103abc:	e8 89 ff ff ff       	call   f0103a4a <vsnprintf>
	va_end(ap);

	return rc;
}
f0103ac1:	c9                   	leave  
f0103ac2:	c3                   	ret    

f0103ac3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103ac3:	55                   	push   %ebp
f0103ac4:	89 e5                	mov    %esp,%ebp
f0103ac6:	57                   	push   %edi
f0103ac7:	56                   	push   %esi
f0103ac8:	53                   	push   %ebx
f0103ac9:	83 ec 1c             	sub    $0x1c,%esp
f0103acc:	e8 7e c6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103ad1:	81 c3 3b 38 01 00    	add    $0x1383b,%ebx
f0103ad7:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103ada:	85 c0                	test   %eax,%eax
f0103adc:	74 13                	je     f0103af1 <readline+0x2e>
		cprintf("%s", prompt);
f0103ade:	83 ec 08             	sub    $0x8,%esp
f0103ae1:	50                   	push   %eax
f0103ae2:	8d 83 c0 db fe ff    	lea    -0x12440(%ebx),%eax
f0103ae8:	50                   	push   %eax
f0103ae9:	e8 39 f6 ff ff       	call   f0103127 <cprintf>
f0103aee:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103af1:	83 ec 0c             	sub    $0xc,%esp
f0103af4:	6a 00                	push   $0x0
f0103af6:	e8 ec cb ff ff       	call   f01006e7 <iscons>
f0103afb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103afe:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103b01:	bf 00 00 00 00       	mov    $0x0,%edi
f0103b06:	eb 46                	jmp    f0103b4e <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103b08:	83 ec 08             	sub    $0x8,%esp
f0103b0b:	50                   	push   %eax
f0103b0c:	8d 83 74 e0 fe ff    	lea    -0x11f8c(%ebx),%eax
f0103b12:	50                   	push   %eax
f0103b13:	e8 0f f6 ff ff       	call   f0103127 <cprintf>
			return NULL;
f0103b18:	83 c4 10             	add    $0x10,%esp
f0103b1b:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103b20:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b23:	5b                   	pop    %ebx
f0103b24:	5e                   	pop    %esi
f0103b25:	5f                   	pop    %edi
f0103b26:	5d                   	pop    %ebp
f0103b27:	c3                   	ret    
			if (echoing)
f0103b28:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b2c:	75 05                	jne    f0103b33 <readline+0x70>
			i--;
f0103b2e:	83 ef 01             	sub    $0x1,%edi
f0103b31:	eb 1b                	jmp    f0103b4e <readline+0x8b>
				cputchar('\b');
f0103b33:	83 ec 0c             	sub    $0xc,%esp
f0103b36:	6a 08                	push   $0x8
f0103b38:	e8 89 cb ff ff       	call   f01006c6 <cputchar>
f0103b3d:	83 c4 10             	add    $0x10,%esp
f0103b40:	eb ec                	jmp    f0103b2e <readline+0x6b>
			buf[i++] = c;
f0103b42:	89 f0                	mov    %esi,%eax
f0103b44:	88 84 3b b4 1f 00 00 	mov    %al,0x1fb4(%ebx,%edi,1)
f0103b4b:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103b4e:	e8 83 cb ff ff       	call   f01006d6 <getchar>
f0103b53:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103b55:	85 c0                	test   %eax,%eax
f0103b57:	78 af                	js     f0103b08 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103b59:	83 f8 08             	cmp    $0x8,%eax
f0103b5c:	0f 94 c2             	sete   %dl
f0103b5f:	83 f8 7f             	cmp    $0x7f,%eax
f0103b62:	0f 94 c0             	sete   %al
f0103b65:	08 c2                	or     %al,%dl
f0103b67:	74 04                	je     f0103b6d <readline+0xaa>
f0103b69:	85 ff                	test   %edi,%edi
f0103b6b:	7f bb                	jg     f0103b28 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103b6d:	83 fe 1f             	cmp    $0x1f,%esi
f0103b70:	7e 1c                	jle    f0103b8e <readline+0xcb>
f0103b72:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103b78:	7f 14                	jg     f0103b8e <readline+0xcb>
			if (echoing)
f0103b7a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b7e:	74 c2                	je     f0103b42 <readline+0x7f>
				cputchar(c);
f0103b80:	83 ec 0c             	sub    $0xc,%esp
f0103b83:	56                   	push   %esi
f0103b84:	e8 3d cb ff ff       	call   f01006c6 <cputchar>
f0103b89:	83 c4 10             	add    $0x10,%esp
f0103b8c:	eb b4                	jmp    f0103b42 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103b8e:	83 fe 0a             	cmp    $0xa,%esi
f0103b91:	74 05                	je     f0103b98 <readline+0xd5>
f0103b93:	83 fe 0d             	cmp    $0xd,%esi
f0103b96:	75 b6                	jne    f0103b4e <readline+0x8b>
			if (echoing)
f0103b98:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b9c:	75 13                	jne    f0103bb1 <readline+0xee>
			buf[i] = 0;
f0103b9e:	c6 84 3b b4 1f 00 00 	movb   $0x0,0x1fb4(%ebx,%edi,1)
f0103ba5:	00 
			return buf;
f0103ba6:	8d 83 b4 1f 00 00    	lea    0x1fb4(%ebx),%eax
f0103bac:	e9 6f ff ff ff       	jmp    f0103b20 <readline+0x5d>
				cputchar('\n');
f0103bb1:	83 ec 0c             	sub    $0xc,%esp
f0103bb4:	6a 0a                	push   $0xa
f0103bb6:	e8 0b cb ff ff       	call   f01006c6 <cputchar>
f0103bbb:	83 c4 10             	add    $0x10,%esp
f0103bbe:	eb de                	jmp    f0103b9e <readline+0xdb>

f0103bc0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103bc0:	55                   	push   %ebp
f0103bc1:	89 e5                	mov    %esp,%ebp
f0103bc3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103bc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bcb:	eb 03                	jmp    f0103bd0 <strlen+0x10>
		n++;
f0103bcd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103bd0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103bd4:	75 f7                	jne    f0103bcd <strlen+0xd>
	return n;
}
f0103bd6:	5d                   	pop    %ebp
f0103bd7:	c3                   	ret    

f0103bd8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103bd8:	55                   	push   %ebp
f0103bd9:	89 e5                	mov    %esp,%ebp
f0103bdb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103bde:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103be1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103be6:	eb 03                	jmp    f0103beb <strnlen+0x13>
		n++;
f0103be8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103beb:	39 d0                	cmp    %edx,%eax
f0103bed:	74 06                	je     f0103bf5 <strnlen+0x1d>
f0103bef:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103bf3:	75 f3                	jne    f0103be8 <strnlen+0x10>
	return n;
}
f0103bf5:	5d                   	pop    %ebp
f0103bf6:	c3                   	ret    

f0103bf7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103bf7:	55                   	push   %ebp
f0103bf8:	89 e5                	mov    %esp,%ebp
f0103bfa:	53                   	push   %ebx
f0103bfb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bfe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103c01:	89 c2                	mov    %eax,%edx
f0103c03:	83 c1 01             	add    $0x1,%ecx
f0103c06:	83 c2 01             	add    $0x1,%edx
f0103c09:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103c0d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103c10:	84 db                	test   %bl,%bl
f0103c12:	75 ef                	jne    f0103c03 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103c14:	5b                   	pop    %ebx
f0103c15:	5d                   	pop    %ebp
f0103c16:	c3                   	ret    

f0103c17 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103c17:	55                   	push   %ebp
f0103c18:	89 e5                	mov    %esp,%ebp
f0103c1a:	53                   	push   %ebx
f0103c1b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103c1e:	53                   	push   %ebx
f0103c1f:	e8 9c ff ff ff       	call   f0103bc0 <strlen>
f0103c24:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103c27:	ff 75 0c             	pushl  0xc(%ebp)
f0103c2a:	01 d8                	add    %ebx,%eax
f0103c2c:	50                   	push   %eax
f0103c2d:	e8 c5 ff ff ff       	call   f0103bf7 <strcpy>
	return dst;
}
f0103c32:	89 d8                	mov    %ebx,%eax
f0103c34:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c37:	c9                   	leave  
f0103c38:	c3                   	ret    

f0103c39 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103c39:	55                   	push   %ebp
f0103c3a:	89 e5                	mov    %esp,%ebp
f0103c3c:	56                   	push   %esi
f0103c3d:	53                   	push   %ebx
f0103c3e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c41:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103c44:	89 f3                	mov    %esi,%ebx
f0103c46:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103c49:	89 f2                	mov    %esi,%edx
f0103c4b:	eb 0f                	jmp    f0103c5c <strncpy+0x23>
		*dst++ = *src;
f0103c4d:	83 c2 01             	add    $0x1,%edx
f0103c50:	0f b6 01             	movzbl (%ecx),%eax
f0103c53:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103c56:	80 39 01             	cmpb   $0x1,(%ecx)
f0103c59:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103c5c:	39 da                	cmp    %ebx,%edx
f0103c5e:	75 ed                	jne    f0103c4d <strncpy+0x14>
	}
	return ret;
}
f0103c60:	89 f0                	mov    %esi,%eax
f0103c62:	5b                   	pop    %ebx
f0103c63:	5e                   	pop    %esi
f0103c64:	5d                   	pop    %ebp
f0103c65:	c3                   	ret    

f0103c66 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103c66:	55                   	push   %ebp
f0103c67:	89 e5                	mov    %esp,%ebp
f0103c69:	56                   	push   %esi
f0103c6a:	53                   	push   %ebx
f0103c6b:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c6e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c71:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103c74:	89 f0                	mov    %esi,%eax
f0103c76:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103c7a:	85 c9                	test   %ecx,%ecx
f0103c7c:	75 0b                	jne    f0103c89 <strlcpy+0x23>
f0103c7e:	eb 17                	jmp    f0103c97 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103c80:	83 c2 01             	add    $0x1,%edx
f0103c83:	83 c0 01             	add    $0x1,%eax
f0103c86:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103c89:	39 d8                	cmp    %ebx,%eax
f0103c8b:	74 07                	je     f0103c94 <strlcpy+0x2e>
f0103c8d:	0f b6 0a             	movzbl (%edx),%ecx
f0103c90:	84 c9                	test   %cl,%cl
f0103c92:	75 ec                	jne    f0103c80 <strlcpy+0x1a>
		*dst = '\0';
f0103c94:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103c97:	29 f0                	sub    %esi,%eax
}
f0103c99:	5b                   	pop    %ebx
f0103c9a:	5e                   	pop    %esi
f0103c9b:	5d                   	pop    %ebp
f0103c9c:	c3                   	ret    

f0103c9d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103c9d:	55                   	push   %ebp
f0103c9e:	89 e5                	mov    %esp,%ebp
f0103ca0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ca3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103ca6:	eb 06                	jmp    f0103cae <strcmp+0x11>
		p++, q++;
f0103ca8:	83 c1 01             	add    $0x1,%ecx
f0103cab:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103cae:	0f b6 01             	movzbl (%ecx),%eax
f0103cb1:	84 c0                	test   %al,%al
f0103cb3:	74 04                	je     f0103cb9 <strcmp+0x1c>
f0103cb5:	3a 02                	cmp    (%edx),%al
f0103cb7:	74 ef                	je     f0103ca8 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103cb9:	0f b6 c0             	movzbl %al,%eax
f0103cbc:	0f b6 12             	movzbl (%edx),%edx
f0103cbf:	29 d0                	sub    %edx,%eax
}
f0103cc1:	5d                   	pop    %ebp
f0103cc2:	c3                   	ret    

f0103cc3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103cc3:	55                   	push   %ebp
f0103cc4:	89 e5                	mov    %esp,%ebp
f0103cc6:	53                   	push   %ebx
f0103cc7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cca:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ccd:	89 c3                	mov    %eax,%ebx
f0103ccf:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103cd2:	eb 06                	jmp    f0103cda <strncmp+0x17>
		n--, p++, q++;
f0103cd4:	83 c0 01             	add    $0x1,%eax
f0103cd7:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103cda:	39 d8                	cmp    %ebx,%eax
f0103cdc:	74 16                	je     f0103cf4 <strncmp+0x31>
f0103cde:	0f b6 08             	movzbl (%eax),%ecx
f0103ce1:	84 c9                	test   %cl,%cl
f0103ce3:	74 04                	je     f0103ce9 <strncmp+0x26>
f0103ce5:	3a 0a                	cmp    (%edx),%cl
f0103ce7:	74 eb                	je     f0103cd4 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103ce9:	0f b6 00             	movzbl (%eax),%eax
f0103cec:	0f b6 12             	movzbl (%edx),%edx
f0103cef:	29 d0                	sub    %edx,%eax
}
f0103cf1:	5b                   	pop    %ebx
f0103cf2:	5d                   	pop    %ebp
f0103cf3:	c3                   	ret    
		return 0;
f0103cf4:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cf9:	eb f6                	jmp    f0103cf1 <strncmp+0x2e>

f0103cfb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103cfb:	55                   	push   %ebp
f0103cfc:	89 e5                	mov    %esp,%ebp
f0103cfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d01:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103d05:	0f b6 10             	movzbl (%eax),%edx
f0103d08:	84 d2                	test   %dl,%dl
f0103d0a:	74 09                	je     f0103d15 <strchr+0x1a>
		if (*s == c)
f0103d0c:	38 ca                	cmp    %cl,%dl
f0103d0e:	74 0a                	je     f0103d1a <strchr+0x1f>
	for (; *s; s++)
f0103d10:	83 c0 01             	add    $0x1,%eax
f0103d13:	eb f0                	jmp    f0103d05 <strchr+0xa>
			return (char *) s;
	return 0;
f0103d15:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d1a:	5d                   	pop    %ebp
f0103d1b:	c3                   	ret    

f0103d1c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103d1c:	55                   	push   %ebp
f0103d1d:	89 e5                	mov    %esp,%ebp
f0103d1f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d22:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103d26:	eb 03                	jmp    f0103d2b <strfind+0xf>
f0103d28:	83 c0 01             	add    $0x1,%eax
f0103d2b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103d2e:	38 ca                	cmp    %cl,%dl
f0103d30:	74 04                	je     f0103d36 <strfind+0x1a>
f0103d32:	84 d2                	test   %dl,%dl
f0103d34:	75 f2                	jne    f0103d28 <strfind+0xc>
			break;
	return (char *) s;
}
f0103d36:	5d                   	pop    %ebp
f0103d37:	c3                   	ret    

f0103d38 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103d38:	55                   	push   %ebp
f0103d39:	89 e5                	mov    %esp,%ebp
f0103d3b:	57                   	push   %edi
f0103d3c:	56                   	push   %esi
f0103d3d:	53                   	push   %ebx
f0103d3e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103d41:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103d44:	85 c9                	test   %ecx,%ecx
f0103d46:	74 13                	je     f0103d5b <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103d48:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103d4e:	75 05                	jne    f0103d55 <memset+0x1d>
f0103d50:	f6 c1 03             	test   $0x3,%cl
f0103d53:	74 0d                	je     f0103d62 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103d55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d58:	fc                   	cld    
f0103d59:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103d5b:	89 f8                	mov    %edi,%eax
f0103d5d:	5b                   	pop    %ebx
f0103d5e:	5e                   	pop    %esi
f0103d5f:	5f                   	pop    %edi
f0103d60:	5d                   	pop    %ebp
f0103d61:	c3                   	ret    
		c &= 0xFF;
f0103d62:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103d66:	89 d3                	mov    %edx,%ebx
f0103d68:	c1 e3 08             	shl    $0x8,%ebx
f0103d6b:	89 d0                	mov    %edx,%eax
f0103d6d:	c1 e0 18             	shl    $0x18,%eax
f0103d70:	89 d6                	mov    %edx,%esi
f0103d72:	c1 e6 10             	shl    $0x10,%esi
f0103d75:	09 f0                	or     %esi,%eax
f0103d77:	09 c2                	or     %eax,%edx
f0103d79:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103d7b:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103d7e:	89 d0                	mov    %edx,%eax
f0103d80:	fc                   	cld    
f0103d81:	f3 ab                	rep stos %eax,%es:(%edi)
f0103d83:	eb d6                	jmp    f0103d5b <memset+0x23>

f0103d85 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103d85:	55                   	push   %ebp
f0103d86:	89 e5                	mov    %esp,%ebp
f0103d88:	57                   	push   %edi
f0103d89:	56                   	push   %esi
f0103d8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d8d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d90:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103d93:	39 c6                	cmp    %eax,%esi
f0103d95:	73 35                	jae    f0103dcc <memmove+0x47>
f0103d97:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103d9a:	39 c2                	cmp    %eax,%edx
f0103d9c:	76 2e                	jbe    f0103dcc <memmove+0x47>
		s += n;
		d += n;
f0103d9e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103da1:	89 d6                	mov    %edx,%esi
f0103da3:	09 fe                	or     %edi,%esi
f0103da5:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103dab:	74 0c                	je     f0103db9 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103dad:	83 ef 01             	sub    $0x1,%edi
f0103db0:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103db3:	fd                   	std    
f0103db4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103db6:	fc                   	cld    
f0103db7:	eb 21                	jmp    f0103dda <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103db9:	f6 c1 03             	test   $0x3,%cl
f0103dbc:	75 ef                	jne    f0103dad <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103dbe:	83 ef 04             	sub    $0x4,%edi
f0103dc1:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103dc4:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103dc7:	fd                   	std    
f0103dc8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103dca:	eb ea                	jmp    f0103db6 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103dcc:	89 f2                	mov    %esi,%edx
f0103dce:	09 c2                	or     %eax,%edx
f0103dd0:	f6 c2 03             	test   $0x3,%dl
f0103dd3:	74 09                	je     f0103dde <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103dd5:	89 c7                	mov    %eax,%edi
f0103dd7:	fc                   	cld    
f0103dd8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103dda:	5e                   	pop    %esi
f0103ddb:	5f                   	pop    %edi
f0103ddc:	5d                   	pop    %ebp
f0103ddd:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103dde:	f6 c1 03             	test   $0x3,%cl
f0103de1:	75 f2                	jne    f0103dd5 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103de3:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103de6:	89 c7                	mov    %eax,%edi
f0103de8:	fc                   	cld    
f0103de9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103deb:	eb ed                	jmp    f0103dda <memmove+0x55>

f0103ded <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103ded:	55                   	push   %ebp
f0103dee:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103df0:	ff 75 10             	pushl  0x10(%ebp)
f0103df3:	ff 75 0c             	pushl  0xc(%ebp)
f0103df6:	ff 75 08             	pushl  0x8(%ebp)
f0103df9:	e8 87 ff ff ff       	call   f0103d85 <memmove>
}
f0103dfe:	c9                   	leave  
f0103dff:	c3                   	ret    

f0103e00 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103e00:	55                   	push   %ebp
f0103e01:	89 e5                	mov    %esp,%ebp
f0103e03:	56                   	push   %esi
f0103e04:	53                   	push   %ebx
f0103e05:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e08:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e0b:	89 c6                	mov    %eax,%esi
f0103e0d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103e10:	39 f0                	cmp    %esi,%eax
f0103e12:	74 1c                	je     f0103e30 <memcmp+0x30>
		if (*s1 != *s2)
f0103e14:	0f b6 08             	movzbl (%eax),%ecx
f0103e17:	0f b6 1a             	movzbl (%edx),%ebx
f0103e1a:	38 d9                	cmp    %bl,%cl
f0103e1c:	75 08                	jne    f0103e26 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103e1e:	83 c0 01             	add    $0x1,%eax
f0103e21:	83 c2 01             	add    $0x1,%edx
f0103e24:	eb ea                	jmp    f0103e10 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103e26:	0f b6 c1             	movzbl %cl,%eax
f0103e29:	0f b6 db             	movzbl %bl,%ebx
f0103e2c:	29 d8                	sub    %ebx,%eax
f0103e2e:	eb 05                	jmp    f0103e35 <memcmp+0x35>
	}

	return 0;
f0103e30:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e35:	5b                   	pop    %ebx
f0103e36:	5e                   	pop    %esi
f0103e37:	5d                   	pop    %ebp
f0103e38:	c3                   	ret    

f0103e39 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103e39:	55                   	push   %ebp
f0103e3a:	89 e5                	mov    %esp,%ebp
f0103e3c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e3f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103e42:	89 c2                	mov    %eax,%edx
f0103e44:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103e47:	39 d0                	cmp    %edx,%eax
f0103e49:	73 09                	jae    f0103e54 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103e4b:	38 08                	cmp    %cl,(%eax)
f0103e4d:	74 05                	je     f0103e54 <memfind+0x1b>
	for (; s < ends; s++)
f0103e4f:	83 c0 01             	add    $0x1,%eax
f0103e52:	eb f3                	jmp    f0103e47 <memfind+0xe>
			break;
	return (void *) s;
}
f0103e54:	5d                   	pop    %ebp
f0103e55:	c3                   	ret    

f0103e56 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103e56:	55                   	push   %ebp
f0103e57:	89 e5                	mov    %esp,%ebp
f0103e59:	57                   	push   %edi
f0103e5a:	56                   	push   %esi
f0103e5b:	53                   	push   %ebx
f0103e5c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103e5f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103e62:	eb 03                	jmp    f0103e67 <strtol+0x11>
		s++;
f0103e64:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103e67:	0f b6 01             	movzbl (%ecx),%eax
f0103e6a:	3c 20                	cmp    $0x20,%al
f0103e6c:	74 f6                	je     f0103e64 <strtol+0xe>
f0103e6e:	3c 09                	cmp    $0x9,%al
f0103e70:	74 f2                	je     f0103e64 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103e72:	3c 2b                	cmp    $0x2b,%al
f0103e74:	74 2e                	je     f0103ea4 <strtol+0x4e>
	int neg = 0;
f0103e76:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103e7b:	3c 2d                	cmp    $0x2d,%al
f0103e7d:	74 2f                	je     f0103eae <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e7f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103e85:	75 05                	jne    f0103e8c <strtol+0x36>
f0103e87:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e8a:	74 2c                	je     f0103eb8 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e8c:	85 db                	test   %ebx,%ebx
f0103e8e:	75 0a                	jne    f0103e9a <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103e90:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103e95:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e98:	74 28                	je     f0103ec2 <strtol+0x6c>
		base = 10;
f0103e9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e9f:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103ea2:	eb 50                	jmp    f0103ef4 <strtol+0x9e>
		s++;
f0103ea4:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103ea7:	bf 00 00 00 00       	mov    $0x0,%edi
f0103eac:	eb d1                	jmp    f0103e7f <strtol+0x29>
		s++, neg = 1;
f0103eae:	83 c1 01             	add    $0x1,%ecx
f0103eb1:	bf 01 00 00 00       	mov    $0x1,%edi
f0103eb6:	eb c7                	jmp    f0103e7f <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103eb8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103ebc:	74 0e                	je     f0103ecc <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103ebe:	85 db                	test   %ebx,%ebx
f0103ec0:	75 d8                	jne    f0103e9a <strtol+0x44>
		s++, base = 8;
f0103ec2:	83 c1 01             	add    $0x1,%ecx
f0103ec5:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103eca:	eb ce                	jmp    f0103e9a <strtol+0x44>
		s += 2, base = 16;
f0103ecc:	83 c1 02             	add    $0x2,%ecx
f0103ecf:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103ed4:	eb c4                	jmp    f0103e9a <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103ed6:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103ed9:	89 f3                	mov    %esi,%ebx
f0103edb:	80 fb 19             	cmp    $0x19,%bl
f0103ede:	77 29                	ja     f0103f09 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103ee0:	0f be d2             	movsbl %dl,%edx
f0103ee3:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103ee6:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103ee9:	7d 30                	jge    f0103f1b <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103eeb:	83 c1 01             	add    $0x1,%ecx
f0103eee:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103ef2:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103ef4:	0f b6 11             	movzbl (%ecx),%edx
f0103ef7:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103efa:	89 f3                	mov    %esi,%ebx
f0103efc:	80 fb 09             	cmp    $0x9,%bl
f0103eff:	77 d5                	ja     f0103ed6 <strtol+0x80>
			dig = *s - '0';
f0103f01:	0f be d2             	movsbl %dl,%edx
f0103f04:	83 ea 30             	sub    $0x30,%edx
f0103f07:	eb dd                	jmp    f0103ee6 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103f09:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103f0c:	89 f3                	mov    %esi,%ebx
f0103f0e:	80 fb 19             	cmp    $0x19,%bl
f0103f11:	77 08                	ja     f0103f1b <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103f13:	0f be d2             	movsbl %dl,%edx
f0103f16:	83 ea 37             	sub    $0x37,%edx
f0103f19:	eb cb                	jmp    f0103ee6 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103f1b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103f1f:	74 05                	je     f0103f26 <strtol+0xd0>
		*endptr = (char *) s;
f0103f21:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103f24:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103f26:	89 c2                	mov    %eax,%edx
f0103f28:	f7 da                	neg    %edx
f0103f2a:	85 ff                	test   %edi,%edi
f0103f2c:	0f 45 c2             	cmovne %edx,%eax
}
f0103f2f:	5b                   	pop    %ebx
f0103f30:	5e                   	pop    %esi
f0103f31:	5f                   	pop    %edi
f0103f32:	5d                   	pop    %ebp
f0103f33:	c3                   	ret    
f0103f34:	66 90                	xchg   %ax,%ax
f0103f36:	66 90                	xchg   %ax,%ax
f0103f38:	66 90                	xchg   %ax,%ax
f0103f3a:	66 90                	xchg   %ax,%ax
f0103f3c:	66 90                	xchg   %ax,%ax
f0103f3e:	66 90                	xchg   %ax,%ax

f0103f40 <__udivdi3>:
f0103f40:	55                   	push   %ebp
f0103f41:	57                   	push   %edi
f0103f42:	56                   	push   %esi
f0103f43:	53                   	push   %ebx
f0103f44:	83 ec 1c             	sub    $0x1c,%esp
f0103f47:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103f4b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103f4f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103f53:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103f57:	85 d2                	test   %edx,%edx
f0103f59:	75 35                	jne    f0103f90 <__udivdi3+0x50>
f0103f5b:	39 f3                	cmp    %esi,%ebx
f0103f5d:	0f 87 bd 00 00 00    	ja     f0104020 <__udivdi3+0xe0>
f0103f63:	85 db                	test   %ebx,%ebx
f0103f65:	89 d9                	mov    %ebx,%ecx
f0103f67:	75 0b                	jne    f0103f74 <__udivdi3+0x34>
f0103f69:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f6e:	31 d2                	xor    %edx,%edx
f0103f70:	f7 f3                	div    %ebx
f0103f72:	89 c1                	mov    %eax,%ecx
f0103f74:	31 d2                	xor    %edx,%edx
f0103f76:	89 f0                	mov    %esi,%eax
f0103f78:	f7 f1                	div    %ecx
f0103f7a:	89 c6                	mov    %eax,%esi
f0103f7c:	89 e8                	mov    %ebp,%eax
f0103f7e:	89 f7                	mov    %esi,%edi
f0103f80:	f7 f1                	div    %ecx
f0103f82:	89 fa                	mov    %edi,%edx
f0103f84:	83 c4 1c             	add    $0x1c,%esp
f0103f87:	5b                   	pop    %ebx
f0103f88:	5e                   	pop    %esi
f0103f89:	5f                   	pop    %edi
f0103f8a:	5d                   	pop    %ebp
f0103f8b:	c3                   	ret    
f0103f8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f90:	39 f2                	cmp    %esi,%edx
f0103f92:	77 7c                	ja     f0104010 <__udivdi3+0xd0>
f0103f94:	0f bd fa             	bsr    %edx,%edi
f0103f97:	83 f7 1f             	xor    $0x1f,%edi
f0103f9a:	0f 84 98 00 00 00    	je     f0104038 <__udivdi3+0xf8>
f0103fa0:	89 f9                	mov    %edi,%ecx
f0103fa2:	b8 20 00 00 00       	mov    $0x20,%eax
f0103fa7:	29 f8                	sub    %edi,%eax
f0103fa9:	d3 e2                	shl    %cl,%edx
f0103fab:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103faf:	89 c1                	mov    %eax,%ecx
f0103fb1:	89 da                	mov    %ebx,%edx
f0103fb3:	d3 ea                	shr    %cl,%edx
f0103fb5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103fb9:	09 d1                	or     %edx,%ecx
f0103fbb:	89 f2                	mov    %esi,%edx
f0103fbd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103fc1:	89 f9                	mov    %edi,%ecx
f0103fc3:	d3 e3                	shl    %cl,%ebx
f0103fc5:	89 c1                	mov    %eax,%ecx
f0103fc7:	d3 ea                	shr    %cl,%edx
f0103fc9:	89 f9                	mov    %edi,%ecx
f0103fcb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103fcf:	d3 e6                	shl    %cl,%esi
f0103fd1:	89 eb                	mov    %ebp,%ebx
f0103fd3:	89 c1                	mov    %eax,%ecx
f0103fd5:	d3 eb                	shr    %cl,%ebx
f0103fd7:	09 de                	or     %ebx,%esi
f0103fd9:	89 f0                	mov    %esi,%eax
f0103fdb:	f7 74 24 08          	divl   0x8(%esp)
f0103fdf:	89 d6                	mov    %edx,%esi
f0103fe1:	89 c3                	mov    %eax,%ebx
f0103fe3:	f7 64 24 0c          	mull   0xc(%esp)
f0103fe7:	39 d6                	cmp    %edx,%esi
f0103fe9:	72 0c                	jb     f0103ff7 <__udivdi3+0xb7>
f0103feb:	89 f9                	mov    %edi,%ecx
f0103fed:	d3 e5                	shl    %cl,%ebp
f0103fef:	39 c5                	cmp    %eax,%ebp
f0103ff1:	73 5d                	jae    f0104050 <__udivdi3+0x110>
f0103ff3:	39 d6                	cmp    %edx,%esi
f0103ff5:	75 59                	jne    f0104050 <__udivdi3+0x110>
f0103ff7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103ffa:	31 ff                	xor    %edi,%edi
f0103ffc:	89 fa                	mov    %edi,%edx
f0103ffe:	83 c4 1c             	add    $0x1c,%esp
f0104001:	5b                   	pop    %ebx
f0104002:	5e                   	pop    %esi
f0104003:	5f                   	pop    %edi
f0104004:	5d                   	pop    %ebp
f0104005:	c3                   	ret    
f0104006:	8d 76 00             	lea    0x0(%esi),%esi
f0104009:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104010:	31 ff                	xor    %edi,%edi
f0104012:	31 c0                	xor    %eax,%eax
f0104014:	89 fa                	mov    %edi,%edx
f0104016:	83 c4 1c             	add    $0x1c,%esp
f0104019:	5b                   	pop    %ebx
f010401a:	5e                   	pop    %esi
f010401b:	5f                   	pop    %edi
f010401c:	5d                   	pop    %ebp
f010401d:	c3                   	ret    
f010401e:	66 90                	xchg   %ax,%ax
f0104020:	31 ff                	xor    %edi,%edi
f0104022:	89 e8                	mov    %ebp,%eax
f0104024:	89 f2                	mov    %esi,%edx
f0104026:	f7 f3                	div    %ebx
f0104028:	89 fa                	mov    %edi,%edx
f010402a:	83 c4 1c             	add    $0x1c,%esp
f010402d:	5b                   	pop    %ebx
f010402e:	5e                   	pop    %esi
f010402f:	5f                   	pop    %edi
f0104030:	5d                   	pop    %ebp
f0104031:	c3                   	ret    
f0104032:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104038:	39 f2                	cmp    %esi,%edx
f010403a:	72 06                	jb     f0104042 <__udivdi3+0x102>
f010403c:	31 c0                	xor    %eax,%eax
f010403e:	39 eb                	cmp    %ebp,%ebx
f0104040:	77 d2                	ja     f0104014 <__udivdi3+0xd4>
f0104042:	b8 01 00 00 00       	mov    $0x1,%eax
f0104047:	eb cb                	jmp    f0104014 <__udivdi3+0xd4>
f0104049:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104050:	89 d8                	mov    %ebx,%eax
f0104052:	31 ff                	xor    %edi,%edi
f0104054:	eb be                	jmp    f0104014 <__udivdi3+0xd4>
f0104056:	66 90                	xchg   %ax,%ax
f0104058:	66 90                	xchg   %ax,%ax
f010405a:	66 90                	xchg   %ax,%ax
f010405c:	66 90                	xchg   %ax,%ax
f010405e:	66 90                	xchg   %ax,%ax

f0104060 <__umoddi3>:
f0104060:	55                   	push   %ebp
f0104061:	57                   	push   %edi
f0104062:	56                   	push   %esi
f0104063:	53                   	push   %ebx
f0104064:	83 ec 1c             	sub    $0x1c,%esp
f0104067:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010406b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010406f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104073:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104077:	85 ed                	test   %ebp,%ebp
f0104079:	89 f0                	mov    %esi,%eax
f010407b:	89 da                	mov    %ebx,%edx
f010407d:	75 19                	jne    f0104098 <__umoddi3+0x38>
f010407f:	39 df                	cmp    %ebx,%edi
f0104081:	0f 86 b1 00 00 00    	jbe    f0104138 <__umoddi3+0xd8>
f0104087:	f7 f7                	div    %edi
f0104089:	89 d0                	mov    %edx,%eax
f010408b:	31 d2                	xor    %edx,%edx
f010408d:	83 c4 1c             	add    $0x1c,%esp
f0104090:	5b                   	pop    %ebx
f0104091:	5e                   	pop    %esi
f0104092:	5f                   	pop    %edi
f0104093:	5d                   	pop    %ebp
f0104094:	c3                   	ret    
f0104095:	8d 76 00             	lea    0x0(%esi),%esi
f0104098:	39 dd                	cmp    %ebx,%ebp
f010409a:	77 f1                	ja     f010408d <__umoddi3+0x2d>
f010409c:	0f bd cd             	bsr    %ebp,%ecx
f010409f:	83 f1 1f             	xor    $0x1f,%ecx
f01040a2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01040a6:	0f 84 b4 00 00 00    	je     f0104160 <__umoddi3+0x100>
f01040ac:	b8 20 00 00 00       	mov    $0x20,%eax
f01040b1:	89 c2                	mov    %eax,%edx
f01040b3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01040b7:	29 c2                	sub    %eax,%edx
f01040b9:	89 c1                	mov    %eax,%ecx
f01040bb:	89 f8                	mov    %edi,%eax
f01040bd:	d3 e5                	shl    %cl,%ebp
f01040bf:	89 d1                	mov    %edx,%ecx
f01040c1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01040c5:	d3 e8                	shr    %cl,%eax
f01040c7:	09 c5                	or     %eax,%ebp
f01040c9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01040cd:	89 c1                	mov    %eax,%ecx
f01040cf:	d3 e7                	shl    %cl,%edi
f01040d1:	89 d1                	mov    %edx,%ecx
f01040d3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01040d7:	89 df                	mov    %ebx,%edi
f01040d9:	d3 ef                	shr    %cl,%edi
f01040db:	89 c1                	mov    %eax,%ecx
f01040dd:	89 f0                	mov    %esi,%eax
f01040df:	d3 e3                	shl    %cl,%ebx
f01040e1:	89 d1                	mov    %edx,%ecx
f01040e3:	89 fa                	mov    %edi,%edx
f01040e5:	d3 e8                	shr    %cl,%eax
f01040e7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01040ec:	09 d8                	or     %ebx,%eax
f01040ee:	f7 f5                	div    %ebp
f01040f0:	d3 e6                	shl    %cl,%esi
f01040f2:	89 d1                	mov    %edx,%ecx
f01040f4:	f7 64 24 08          	mull   0x8(%esp)
f01040f8:	39 d1                	cmp    %edx,%ecx
f01040fa:	89 c3                	mov    %eax,%ebx
f01040fc:	89 d7                	mov    %edx,%edi
f01040fe:	72 06                	jb     f0104106 <__umoddi3+0xa6>
f0104100:	75 0e                	jne    f0104110 <__umoddi3+0xb0>
f0104102:	39 c6                	cmp    %eax,%esi
f0104104:	73 0a                	jae    f0104110 <__umoddi3+0xb0>
f0104106:	2b 44 24 08          	sub    0x8(%esp),%eax
f010410a:	19 ea                	sbb    %ebp,%edx
f010410c:	89 d7                	mov    %edx,%edi
f010410e:	89 c3                	mov    %eax,%ebx
f0104110:	89 ca                	mov    %ecx,%edx
f0104112:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104117:	29 de                	sub    %ebx,%esi
f0104119:	19 fa                	sbb    %edi,%edx
f010411b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010411f:	89 d0                	mov    %edx,%eax
f0104121:	d3 e0                	shl    %cl,%eax
f0104123:	89 d9                	mov    %ebx,%ecx
f0104125:	d3 ee                	shr    %cl,%esi
f0104127:	d3 ea                	shr    %cl,%edx
f0104129:	09 f0                	or     %esi,%eax
f010412b:	83 c4 1c             	add    $0x1c,%esp
f010412e:	5b                   	pop    %ebx
f010412f:	5e                   	pop    %esi
f0104130:	5f                   	pop    %edi
f0104131:	5d                   	pop    %ebp
f0104132:	c3                   	ret    
f0104133:	90                   	nop
f0104134:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104138:	85 ff                	test   %edi,%edi
f010413a:	89 f9                	mov    %edi,%ecx
f010413c:	75 0b                	jne    f0104149 <__umoddi3+0xe9>
f010413e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104143:	31 d2                	xor    %edx,%edx
f0104145:	f7 f7                	div    %edi
f0104147:	89 c1                	mov    %eax,%ecx
f0104149:	89 d8                	mov    %ebx,%eax
f010414b:	31 d2                	xor    %edx,%edx
f010414d:	f7 f1                	div    %ecx
f010414f:	89 f0                	mov    %esi,%eax
f0104151:	f7 f1                	div    %ecx
f0104153:	e9 31 ff ff ff       	jmp    f0104089 <__umoddi3+0x29>
f0104158:	90                   	nop
f0104159:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104160:	39 dd                	cmp    %ebx,%ebp
f0104162:	72 08                	jb     f010416c <__umoddi3+0x10c>
f0104164:	39 f7                	cmp    %esi,%edi
f0104166:	0f 87 21 ff ff ff    	ja     f010408d <__umoddi3+0x2d>
f010416c:	89 da                	mov    %ebx,%edx
f010416e:	89 f0                	mov    %esi,%eax
f0104170:	29 f8                	sub    %edi,%eax
f0104172:	19 ea                	sbb    %ebp,%edx
f0104174:	e9 14 ff ff ff       	jmp    f010408d <__umoddi3+0x2d>
