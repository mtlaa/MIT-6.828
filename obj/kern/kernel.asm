
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
f0100052:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f0100058:	c7 c0 a0 96 11 f0    	mov    $0xf01196a0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 90 3c 00 00       	call   f0103cf9 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 34 ce fe ff    	lea    -0x131cc(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 66 30 00 00       	call   f01030e8 <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 c0 12 00 00       	call   f0101347 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 74 08 00 00       	call   f0100908 <monitor>
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
f01000b0:	c7 c0 a4 96 11 f0    	mov    $0xf01196a4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 43 08 00 00       	call   f0100908 <monitor>
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
f01000da:	8d 83 4f ce fe ff    	lea    -0x131b1(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 02 30 00 00       	call   f01030e8 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 c1 2f 00 00       	call   f01030b1 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 7d dd fe ff    	lea    -0x12283(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 ea 2f 00 00       	call   f01030e8 <cprintf>
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
f010011f:	8d 83 67 ce fe ff    	lea    -0x13199(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 bd 2f 00 00       	call   f01030e8 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 7a 2f 00 00       	call   f01030b1 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 7d dd fe ff    	lea    -0x12283(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 a3 2f 00 00       	call   f01030e8 <cprintf>
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
f010018f:	8b 8b 78 1f 00 00    	mov    0x1f78(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 78 1f 00 00    	mov    %edx,0x1f78(%ebx)
f010019e:	88 84 0b 74 1d 00 00 	mov    %al,0x1d74(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
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
f01001fb:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 54 1d 00 00    	mov    %ecx,0x1d54(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 b4 cf fe 	movzbl -0x1304c(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 b4 ce fe 	movzbl -0x1314c(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
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
f010026a:	8d 83 81 ce fe ff    	lea    -0x1317f(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 72 2e 00 00       	call   f01030e8 <cprintf>
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
f0100286:	83 8b 54 1d 00 00 40 	orl    $0x40,0x1d54(%ebx)
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
f010029b:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 b4 cf fe 	movzbl -0x1304c(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
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
f01003bc:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 7c 1f 00 00 	cmpw   $0x7cf,0x1f7c(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%ebx
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
f0100423:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 80 1f 00 00    	mov    0x1f80(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 7c 1f 00 00 	addw   $0x50,0x1f7c(%ebx)
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
f0100495:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 7c 1f 00 00 	mov    %dx,0x1f7c(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 80 1f 00 00    	mov    0x1f80(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 6f 38 00 00       	call   f0103d46 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 7c 1f 00 00 	subw   $0x50,0x1f7c(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 02 6e 01 00       	add    $0x16e02,%eax
	if (serial_exists)
f010050f:	80 b8 88 1f 00 00 00 	cmpb   $0x0,0x1f88(%eax)
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
f0100566:	8b 93 74 1f 00 00    	mov    0x1f74(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 78 1f 00 00    	cmp    0x1f78(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 74 1f 00 00    	mov    %ecx,0x1f74(%ebx)
f0100582:	0f b6 84 13 74 1d 00 	movzbl 0x1d74(%ebx,%edx,1),%eax
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
f0100598:	c7 83 74 1f 00 00 00 	movl   $0x0,0x1f74(%ebx)
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
f01005d9:	c7 83 84 1f 00 00 b4 	movl   $0x3b4,0x1f84(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 84 1f 00 00    	mov    0x1f84(%ebx),%edi
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
f0100612:	89 bb 80 1f 00 00    	mov    %edi,0x1f80(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 7c 1f 00 00 	mov    %si,0x1f7c(%ebx)
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
f0100675:	0f 95 83 88 1f 00 00 	setne  0x1f88(%ebx)
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
f010069c:	c7 83 84 1f 00 00 d4 	movl   $0x3d4,0x1f84(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 8d ce fe ff    	lea    -0x13173(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 27 2a 00 00       	call   f01030e8 <cprintf>
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
f0100708:	8d 83 b4 d0 fe ff    	lea    -0x12f4c(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 d2 d0 fe ff    	lea    -0x12f2e(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 d7 d0 fe ff    	lea    -0x12f29(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 c6 29 00 00       	call   f01030e8 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 e0 d0 fe ff    	lea    -0x12f20(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 af 29 00 00       	call   f01030e8 <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 bc d1 fe ff    	lea    -0x12e44(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 e9 d0 fe ff    	lea    -0x12f17(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 98 29 00 00       	call   f01030e8 <cprintf>
	return 0;
}
f0100750:	b8 00 00 00 00       	mov    $0x0,%eax
f0100755:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100758:	5b                   	pop    %ebx
f0100759:	5e                   	pop    %esi
f010075a:	5d                   	pop    %ebp
f010075b:	c3                   	ret    

f010075c <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010075c:	55                   	push   %ebp
f010075d:	89 e5                	mov    %esp,%ebp
f010075f:	57                   	push   %edi
f0100760:	56                   	push   %esi
f0100761:	53                   	push   %ebx
f0100762:	83 ec 18             	sub    $0x18,%esp
f0100765:	e8 e5 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010076a:	81 c3 a2 6b 01 00    	add    $0x16ba2,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100770:	8d 83 f3 d0 fe ff    	lea    -0x12f0d(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 6c 29 00 00       	call   f01030e8 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f0100785:	8d 83 e0 d1 fe ff    	lea    -0x12e20(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 57 29 00 00       	call   f01030e8 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 08 d2 fe ff    	lea    -0x12df8(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 3a 29 00 00       	call   f01030e8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 39 41 10 f0    	mov    $0xf0104139,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 2c d2 fe ff    	lea    -0x12dd4(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 1d 29 00 00       	call   f01030e8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 50 d2 fe ff    	lea    -0x12db0(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 00 29 00 00       	call   f01030e8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 a0 96 11 f0    	mov    $0xf01196a0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 74 d2 fe ff    	lea    -0x12d8c(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 e3 28 00 00       	call   f01030e8 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 98 d2 fe ff    	lea    -0x12d68(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 c8 28 00 00       	call   f01030e8 <cprintf>
	return 0;
}
f0100820:	b8 00 00 00 00       	mov    $0x0,%eax
f0100825:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100828:	5b                   	pop    %ebx
f0100829:	5e                   	pop    %esi
f010082a:	5f                   	pop    %edi
f010082b:	5d                   	pop    %ebp
f010082c:	c3                   	ret    

f010082d <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010082d:	55                   	push   %ebp
f010082e:	89 e5                	mov    %esp,%ebp
f0100830:	57                   	push   %edi
f0100831:	56                   	push   %esi
f0100832:	53                   	push   %ebx
f0100833:	83 ec 48             	sub    $0x48,%esp
f0100836:	e8 14 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010083b:	81 c3 d1 6a 01 00    	add    $0x16ad1,%ebx
	// Your code here.
	cprintf("Stack backtrace:\n");
f0100841:	8d 83 0c d1 fe ff    	lea    -0x12ef4(%ebx),%eax
f0100847:	50                   	push   %eax
f0100848:	e8 9b 28 00 00       	call   f01030e8 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010084d:	89 ef                	mov    %ebp,%edi
	uint32_t *this_ebp = (uint32_t*)read_ebp();
	while(this_ebp!=0){
f010084f:	83 c4 10             	add    $0x10,%esp
		uint32_t pre_ebp = *this_ebp;
		uintptr_t eip = *(this_ebp + 1);
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
f0100852:	8d 83 1e d1 fe ff    	lea    -0x12ee2(%ebx),%eax
f0100858:	89 45 b8             	mov    %eax,-0x48(%ebp)
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
f010085b:	8d 83 39 d1 fe ff    	lea    -0x12ec7(%ebx),%eax
f0100861:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	while(this_ebp!=0){
f0100864:	e9 8a 00 00 00       	jmp    f01008f3 <mon_backtrace+0xc6>
		uint32_t pre_ebp = *this_ebp;
f0100869:	8b 07                	mov    (%edi),%eax
f010086b:	89 45 c0             	mov    %eax,-0x40(%ebp)
		uintptr_t eip = *(this_ebp + 1);
f010086e:	8b 47 04             	mov    0x4(%edi),%eax
f0100871:	89 45 bc             	mov    %eax,-0x44(%ebp)
		cprintf("  ebp %08x  eip %08x  args", this_ebp, eip);
f0100874:	83 ec 04             	sub    $0x4,%esp
f0100877:	50                   	push   %eax
f0100878:	57                   	push   %edi
f0100879:	ff 75 b8             	pushl  -0x48(%ebp)
f010087c:	e8 67 28 00 00       	call   f01030e8 <cprintf>
f0100881:	8d 77 08             	lea    0x8(%edi),%esi
f0100884:	83 c7 1c             	add    $0x1c,%edi
f0100887:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	ff 36                	pushl  (%esi)
f010088f:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100892:	e8 51 28 00 00       	call   f01030e8 <cprintf>
f0100897:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	39 fe                	cmp    %edi,%esi
f010089f:	75 e9                	jne    f010088a <mon_backtrace+0x5d>
		}
		cprintf("\n");
f01008a1:	83 ec 0c             	sub    $0xc,%esp
f01008a4:	8d 83 7d dd fe ff    	lea    -0x12283(%ebx),%eax
f01008aa:	50                   	push   %eax
f01008ab:	e8 38 28 00 00       	call   f01030e8 <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008b0:	83 c4 08             	add    $0x8,%esp
f01008b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008b6:	50                   	push   %eax
f01008b7:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008ba:	57                   	push   %edi
f01008bb:	e8 2c 29 00 00       	call   f01031ec <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f01008c0:	83 c4 0c             	add    $0xc,%esp
f01008c3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008c9:	8d 83 3f d1 fe ff    	lea    -0x12ec1(%ebx),%eax
f01008cf:	50                   	push   %eax
f01008d0:	e8 13 28 00 00       	call   f01030e8 <cprintf>
		// for (int i = 0; i < info.eip_fn_namelen;++i){
		// 	cprintf("%c", info.eip_fn_name[i]);
		// }
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f01008d5:	89 f8                	mov    %edi,%eax
f01008d7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008da:	50                   	push   %eax
f01008db:	ff 75 d8             	pushl  -0x28(%ebp)
f01008de:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e1:	8d 83 4f d1 fe ff    	lea    -0x12eb1(%ebx),%eax
f01008e7:	50                   	push   %eax
f01008e8:	e8 fb 27 00 00       	call   f01030e8 <cprintf>
		this_ebp = (uint32_t *)pre_ebp;
f01008ed:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01008f0:	83 c4 20             	add    $0x20,%esp
	while(this_ebp!=0){
f01008f3:	85 ff                	test   %edi,%edi
f01008f5:	0f 85 6e ff ff ff    	jne    f0100869 <mon_backtrace+0x3c>
	}
	return 0;
}
f01008fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100900:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100903:	5b                   	pop    %ebx
f0100904:	5e                   	pop    %esi
f0100905:	5f                   	pop    %edi
f0100906:	5d                   	pop    %ebp
f0100907:	c3                   	ret    

f0100908 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100908:	55                   	push   %ebp
f0100909:	89 e5                	mov    %esp,%ebp
f010090b:	57                   	push   %edi
f010090c:	56                   	push   %esi
f010090d:	53                   	push   %ebx
f010090e:	83 ec 68             	sub    $0x68,%esp
f0100911:	e8 39 f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100916:	81 c3 f6 69 01 00    	add    $0x169f6,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010091c:	8d 83 c4 d2 fe ff    	lea    -0x12d3c(%ebx),%eax
f0100922:	50                   	push   %eax
f0100923:	e8 c0 27 00 00       	call   f01030e8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100928:	8d 83 e8 d2 fe ff    	lea    -0x12d18(%ebx),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 b2 27 00 00       	call   f01030e8 <cprintf>
f0100936:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100939:	8d bb 5c d1 fe ff    	lea    -0x12ea4(%ebx),%edi
f010093f:	eb 4a                	jmp    f010098b <monitor+0x83>
f0100941:	83 ec 08             	sub    $0x8,%esp
f0100944:	0f be c0             	movsbl %al,%eax
f0100947:	50                   	push   %eax
f0100948:	57                   	push   %edi
f0100949:	e8 6e 33 00 00       	call   f0103cbc <strchr>
f010094e:	83 c4 10             	add    $0x10,%esp
f0100951:	85 c0                	test   %eax,%eax
f0100953:	74 08                	je     f010095d <monitor+0x55>
			*buf++ = 0;
f0100955:	c6 06 00             	movb   $0x0,(%esi)
f0100958:	8d 76 01             	lea    0x1(%esi),%esi
f010095b:	eb 79                	jmp    f01009d6 <monitor+0xce>
		if (*buf == 0)
f010095d:	80 3e 00             	cmpb   $0x0,(%esi)
f0100960:	74 7f                	je     f01009e1 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100962:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100966:	74 0f                	je     f0100977 <monitor+0x6f>
		argv[argc++] = buf;
f0100968:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010096b:	8d 48 01             	lea    0x1(%eax),%ecx
f010096e:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100971:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100975:	eb 44                	jmp    f01009bb <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100977:	83 ec 08             	sub    $0x8,%esp
f010097a:	6a 10                	push   $0x10
f010097c:	8d 83 61 d1 fe ff    	lea    -0x12e9f(%ebx),%eax
f0100982:	50                   	push   %eax
f0100983:	e8 60 27 00 00       	call   f01030e8 <cprintf>
f0100988:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010098b:	8d 83 58 d1 fe ff    	lea    -0x12ea8(%ebx),%eax
f0100991:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100994:	83 ec 0c             	sub    $0xc,%esp
f0100997:	ff 75 a4             	pushl  -0x5c(%ebp)
f010099a:	e8 e5 30 00 00       	call   f0103a84 <readline>
f010099f:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009a1:	83 c4 10             	add    $0x10,%esp
f01009a4:	85 c0                	test   %eax,%eax
f01009a6:	74 ec                	je     f0100994 <monitor+0x8c>
	argv[argc] = 0;
f01009a8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009af:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009b6:	eb 1e                	jmp    f01009d6 <monitor+0xce>
			buf++;
f01009b8:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009bb:	0f b6 06             	movzbl (%esi),%eax
f01009be:	84 c0                	test   %al,%al
f01009c0:	74 14                	je     f01009d6 <monitor+0xce>
f01009c2:	83 ec 08             	sub    $0x8,%esp
f01009c5:	0f be c0             	movsbl %al,%eax
f01009c8:	50                   	push   %eax
f01009c9:	57                   	push   %edi
f01009ca:	e8 ed 32 00 00       	call   f0103cbc <strchr>
f01009cf:	83 c4 10             	add    $0x10,%esp
f01009d2:	85 c0                	test   %eax,%eax
f01009d4:	74 e2                	je     f01009b8 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f01009d6:	0f b6 06             	movzbl (%esi),%eax
f01009d9:	84 c0                	test   %al,%al
f01009db:	0f 85 60 ff ff ff    	jne    f0100941 <monitor+0x39>
	argv[argc] = 0;
f01009e1:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009e4:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009eb:	00 
	if (argc == 0)
f01009ec:	85 c0                	test   %eax,%eax
f01009ee:	74 9b                	je     f010098b <monitor+0x83>
f01009f0:	8d b3 14 1d 00 00    	lea    0x1d14(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009f6:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f01009fd:	83 ec 08             	sub    $0x8,%esp
f0100a00:	ff 36                	pushl  (%esi)
f0100a02:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a05:	e8 54 32 00 00       	call   f0103c5e <strcmp>
f0100a0a:	83 c4 10             	add    $0x10,%esp
f0100a0d:	85 c0                	test   %eax,%eax
f0100a0f:	74 29                	je     f0100a3a <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a11:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f0100a15:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a18:	83 c6 0c             	add    $0xc,%esi
f0100a1b:	83 f8 03             	cmp    $0x3,%eax
f0100a1e:	75 dd                	jne    f01009fd <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a20:	83 ec 08             	sub    $0x8,%esp
f0100a23:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a26:	8d 83 7e d1 fe ff    	lea    -0x12e82(%ebx),%eax
f0100a2c:	50                   	push   %eax
f0100a2d:	e8 b6 26 00 00       	call   f01030e8 <cprintf>
f0100a32:	83 c4 10             	add    $0x10,%esp
f0100a35:	e9 51 ff ff ff       	jmp    f010098b <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100a3a:	83 ec 04             	sub    $0x4,%esp
f0100a3d:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a40:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a43:	ff 75 08             	pushl  0x8(%ebp)
f0100a46:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a49:	52                   	push   %edx
f0100a4a:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a4d:	ff 94 83 1c 1d 00 00 	call   *0x1d1c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a54:	83 c4 10             	add    $0x10,%esp
f0100a57:	85 c0                	test   %eax,%eax
f0100a59:	0f 89 2c ff ff ff    	jns    f010098b <monitor+0x83>
				break;
	}
}
f0100a5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a62:	5b                   	pop    %ebx
f0100a63:	5e                   	pop    %esi
f0100a64:	5f                   	pop    %edi
f0100a65:	5d                   	pop    %ebp
f0100a66:	c3                   	ret    

f0100a67 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a67:	55                   	push   %ebp
f0100a68:	89 e5                	mov    %esp,%ebp
f0100a6a:	e8 e2 25 00 00       	call   f0103051 <__x86.get_pc_thunk.dx>
f0100a6f:	81 c2 9d 68 01 00    	add    $0x1689d,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a75:	83 ba 8c 1f 00 00 00 	cmpl   $0x0,0x1f8c(%edx)
f0100a7c:	74 0e                	je     f0100a8c <boot_alloc+0x25>
	// LAB 2: Your code here.********************************************************************

	// 两步：1、分配一个足够大的页面  2、更新 nextfree ，要为4096的整数倍
	// 并不需要真正的分配内存，就只是先占个坑
	// 如果n>0，就返回分配空间的首地址
	if(n>0){
f0100a7e:	85 c0                	test   %eax,%eax
f0100a80:	75 24                	jne    f0100aa6 <boot_alloc+0x3f>
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
		return result;
	}
	// 如果n==0，就返回nextfree
	if(n==0){
		return nextfree;
f0100a82:	8b 8a 8c 1f 00 00    	mov    0x1f8c(%edx),%ecx
	}

	return NULL;
}
f0100a88:	89 c8                	mov    %ecx,%eax
f0100a8a:	5d                   	pop    %ebp
f0100a8b:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a8c:	c7 c1 a0 96 11 f0    	mov    $0xf01196a0,%ecx
f0100a92:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100a98:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100a9e:	89 8a 8c 1f 00 00    	mov    %ecx,0x1f8c(%edx)
f0100aa4:	eb d8                	jmp    f0100a7e <boot_alloc+0x17>
		result = nextfree;
f0100aa6:	8b 8a 8c 1f 00 00    	mov    0x1f8c(%edx),%ecx
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100aac:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0100ab3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ab8:	89 82 8c 1f 00 00    	mov    %eax,0x1f8c(%edx)
		return result;
f0100abe:	eb c8                	jmp    f0100a88 <boot_alloc+0x21>

f0100ac0 <nvram_read>:
{
f0100ac0:	55                   	push   %ebp
f0100ac1:	89 e5                	mov    %esp,%ebp
f0100ac3:	57                   	push   %edi
f0100ac4:	56                   	push   %esi
f0100ac5:	53                   	push   %ebx
f0100ac6:	83 ec 18             	sub    $0x18,%esp
f0100ac9:	e8 81 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100ace:	81 c3 3e 68 01 00    	add    $0x1683e,%ebx
f0100ad4:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ad6:	50                   	push   %eax
f0100ad7:	e8 85 25 00 00       	call   f0103061 <mc146818_read>
f0100adc:	89 c6                	mov    %eax,%esi
f0100ade:	83 c7 01             	add    $0x1,%edi
f0100ae1:	89 3c 24             	mov    %edi,(%esp)
f0100ae4:	e8 78 25 00 00       	call   f0103061 <mc146818_read>
f0100ae9:	c1 e0 08             	shl    $0x8,%eax
f0100aec:	09 f0                	or     %esi,%eax
}
f0100aee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100af1:	5b                   	pop    %ebx
f0100af2:	5e                   	pop    %esi
f0100af3:	5f                   	pop    %edi
f0100af4:	5d                   	pop    %ebp
f0100af5:	c3                   	ret    

f0100af6 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100af6:	55                   	push   %ebp
f0100af7:	89 e5                	mov    %esp,%ebp
f0100af9:	56                   	push   %esi
f0100afa:	53                   	push   %ebx
f0100afb:	e8 55 25 00 00       	call   f0103055 <__x86.get_pc_thunk.cx>
f0100b00:	81 c1 0c 68 01 00    	add    $0x1680c,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b06:	89 d3                	mov    %edx,%ebx
f0100b08:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b0b:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b0e:	a8 01                	test   $0x1,%al
f0100b10:	74 5a                	je     f0100b6c <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b12:	25 00 f0 ff ff       	and    $0xfffff000,%eax
// 这个宏把真实的物理地址转化为‘Remapped Physical Memory’段的虚拟地址，与 PADDR 相反

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b17:	89 c6                	mov    %eax,%esi
f0100b19:	c1 ee 0c             	shr    $0xc,%esi
f0100b1c:	c7 c3 a8 96 11 f0    	mov    $0xf01196a8,%ebx
f0100b22:	3b 33                	cmp    (%ebx),%esi
f0100b24:	73 2b                	jae    f0100b51 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b26:	c1 ea 0c             	shr    $0xc,%edx
f0100b29:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b2f:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b36:	89 c2                	mov    %eax,%edx
f0100b38:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b3b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b40:	85 d2                	test   %edx,%edx
f0100b42:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b47:	0f 44 c2             	cmove  %edx,%eax
}
f0100b4a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b4d:	5b                   	pop    %ebx
f0100b4e:	5e                   	pop    %esi
f0100b4f:	5d                   	pop    %ebp
f0100b50:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b51:	50                   	push   %eax
f0100b52:	8d 81 10 d3 fe ff    	lea    -0x12cf0(%ecx),%eax
f0100b58:	50                   	push   %eax
f0100b59:	68 f7 02 00 00       	push   $0x2f7
f0100b5e:	8d 81 cc da fe ff    	lea    -0x12534(%ecx),%eax
f0100b64:	50                   	push   %eax
f0100b65:	89 cb                	mov    %ecx,%ebx
f0100b67:	e8 2d f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100b6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b71:	eb d7                	jmp    f0100b4a <check_va2pa+0x54>

f0100b73 <check_page_free_list>:
{
f0100b73:	55                   	push   %ebp
f0100b74:	89 e5                	mov    %esp,%ebp
f0100b76:	57                   	push   %edi
f0100b77:	56                   	push   %esi
f0100b78:	53                   	push   %ebx
f0100b79:	83 ec 3c             	sub    $0x3c,%esp
f0100b7c:	e8 dc 24 00 00       	call   f010305d <__x86.get_pc_thunk.di>
f0100b81:	81 c7 8b 67 01 00    	add    $0x1678b,%edi
f0100b87:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b8a:	84 c0                	test   %al,%al
f0100b8c:	0f 85 dd 02 00 00    	jne    f0100e6f <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100b92:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100b95:	83 b8 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%eax)
f0100b9c:	74 0c                	je     f0100baa <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b9e:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100ba5:	e9 2f 03 00 00       	jmp    f0100ed9 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100baa:	83 ec 04             	sub    $0x4,%esp
f0100bad:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bb0:	8d 83 34 d3 fe ff    	lea    -0x12ccc(%ebx),%eax
f0100bb6:	50                   	push   %eax
f0100bb7:	68 38 02 00 00       	push   $0x238
f0100bbc:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100bc2:	50                   	push   %eax
f0100bc3:	e8 d1 f4 ff ff       	call   f0100099 <_panic>
f0100bc8:	50                   	push   %eax
f0100bc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bcc:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100bd2:	50                   	push   %eax
f0100bd3:	6a 59                	push   $0x59
f0100bd5:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0100bdb:	50                   	push   %eax
f0100bdc:	e8 b8 f4 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100be1:	8b 36                	mov    (%esi),%esi
f0100be3:	85 f6                	test   %esi,%esi
f0100be5:	74 40                	je     f0100c27 <check_page_free_list+0xb4>

// (pp - pages)为页号，(pp - pages) << PGSHIFT 为页号左移12位，也就是该页的物理地址
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100be7:	89 f0                	mov    %esi,%eax
f0100be9:	2b 07                	sub    (%edi),%eax
f0100beb:	c1 f8 03             	sar    $0x3,%eax
f0100bee:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bf1:	89 c2                	mov    %eax,%edx
f0100bf3:	c1 ea 16             	shr    $0x16,%edx
f0100bf6:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bf9:	73 e6                	jae    f0100be1 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100bfb:	89 c2                	mov    %eax,%edx
f0100bfd:	c1 ea 0c             	shr    $0xc,%edx
f0100c00:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c03:	3b 11                	cmp    (%ecx),%edx
f0100c05:	73 c1                	jae    f0100bc8 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100c07:	83 ec 04             	sub    $0x4,%esp
f0100c0a:	68 80 00 00 00       	push   $0x80
f0100c0f:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c14:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c19:	50                   	push   %eax
f0100c1a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c1d:	e8 d7 30 00 00       	call   f0103cf9 <memset>
f0100c22:	83 c4 10             	add    $0x10,%esp
f0100c25:	eb ba                	jmp    f0100be1 <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100c27:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c2c:	e8 36 fe ff ff       	call   f0100a67 <boot_alloc>
f0100c31:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c34:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c37:	8b 97 90 1f 00 00    	mov    0x1f90(%edi),%edx
		assert(pp >= pages);
f0100c3d:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0100c43:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100c45:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0100c4b:	8b 00                	mov    (%eax),%eax
f0100c4d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c50:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c53:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c56:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c5b:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c5e:	e9 08 01 00 00       	jmp    f0100d6b <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100c63:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c66:	8d 83 e6 da fe ff    	lea    -0x1251a(%ebx),%eax
f0100c6c:	50                   	push   %eax
f0100c6d:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100c73:	50                   	push   %eax
f0100c74:	68 52 02 00 00       	push   $0x252
f0100c79:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100c7f:	50                   	push   %eax
f0100c80:	e8 14 f4 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100c85:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c88:	8d 83 07 db fe ff    	lea    -0x124f9(%ebx),%eax
f0100c8e:	50                   	push   %eax
f0100c8f:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100c95:	50                   	push   %eax
f0100c96:	68 53 02 00 00       	push   $0x253
f0100c9b:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100ca1:	50                   	push   %eax
f0100ca2:	e8 f2 f3 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100caa:	8d 83 58 d3 fe ff    	lea    -0x12ca8(%ebx),%eax
f0100cb0:	50                   	push   %eax
f0100cb1:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100cb7:	50                   	push   %eax
f0100cb8:	68 54 02 00 00       	push   $0x254
f0100cbd:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100cc3:	50                   	push   %eax
f0100cc4:	e8 d0 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100cc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ccc:	8d 83 1b db fe ff    	lea    -0x124e5(%ebx),%eax
f0100cd2:	50                   	push   %eax
f0100cd3:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100cd9:	50                   	push   %eax
f0100cda:	68 57 02 00 00       	push   $0x257
f0100cdf:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100ce5:	50                   	push   %eax
f0100ce6:	e8 ae f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ceb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cee:	8d 83 2c db fe ff    	lea    -0x124d4(%ebx),%eax
f0100cf4:	50                   	push   %eax
f0100cf5:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100cfb:	50                   	push   %eax
f0100cfc:	68 58 02 00 00       	push   $0x258
f0100d01:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100d07:	50                   	push   %eax
f0100d08:	e8 8c f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d0d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d10:	8d 83 8c d3 fe ff    	lea    -0x12c74(%ebx),%eax
f0100d16:	50                   	push   %eax
f0100d17:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100d1d:	50                   	push   %eax
f0100d1e:	68 59 02 00 00       	push   $0x259
f0100d23:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100d29:	50                   	push   %eax
f0100d2a:	e8 6a f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d2f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d32:	8d 83 45 db fe ff    	lea    -0x124bb(%ebx),%eax
f0100d38:	50                   	push   %eax
f0100d39:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100d3f:	50                   	push   %eax
f0100d40:	68 5a 02 00 00       	push   $0x25a
f0100d45:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100d4b:	50                   	push   %eax
f0100d4c:	e8 48 f3 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100d51:	89 c6                	mov    %eax,%esi
f0100d53:	c1 ee 0c             	shr    $0xc,%esi
f0100d56:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100d59:	76 70                	jbe    f0100dcb <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100d5b:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d60:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d63:	77 7f                	ja     f0100de4 <check_page_free_list+0x271>
			++nfree_extmem;
f0100d65:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d69:	8b 12                	mov    (%edx),%edx
f0100d6b:	85 d2                	test   %edx,%edx
f0100d6d:	0f 84 93 00 00 00    	je     f0100e06 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100d73:	39 d1                	cmp    %edx,%ecx
f0100d75:	0f 87 e8 fe ff ff    	ja     f0100c63 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100d7b:	39 d3                	cmp    %edx,%ebx
f0100d7d:	0f 86 02 ff ff ff    	jbe    f0100c85 <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d83:	89 d0                	mov    %edx,%eax
f0100d85:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100d88:	a8 07                	test   $0x7,%al
f0100d8a:	0f 85 17 ff ff ff    	jne    f0100ca7 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100d90:	c1 f8 03             	sar    $0x3,%eax
f0100d93:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100d96:	85 c0                	test   %eax,%eax
f0100d98:	0f 84 2b ff ff ff    	je     f0100cc9 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d9e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100da3:	0f 84 42 ff ff ff    	je     f0100ceb <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100da9:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dae:	0f 84 59 ff ff ff    	je     f0100d0d <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100db4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100db9:	0f 84 70 ff ff ff    	je     f0100d2f <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dbf:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100dc4:	77 8b                	ja     f0100d51 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100dc6:	83 c7 01             	add    $0x1,%edi
f0100dc9:	eb 9e                	jmp    f0100d69 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dcb:	50                   	push   %eax
f0100dcc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100dcf:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100dd5:	50                   	push   %eax
f0100dd6:	6a 59                	push   $0x59
f0100dd8:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0100dde:	50                   	push   %eax
f0100ddf:	e8 b5 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100de4:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100de7:	8d 83 b0 d3 fe ff    	lea    -0x12c50(%ebx),%eax
f0100ded:	50                   	push   %eax
f0100dee:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100df4:	50                   	push   %eax
f0100df5:	68 5b 02 00 00       	push   $0x25b
f0100dfa:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100e00:	50                   	push   %eax
f0100e01:	e8 93 f2 ff ff       	call   f0100099 <_panic>
f0100e06:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100e09:	85 ff                	test   %edi,%edi
f0100e0b:	7e 1e                	jle    f0100e2b <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100e0d:	85 f6                	test   %esi,%esi
f0100e0f:	7e 3c                	jle    f0100e4d <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e11:	83 ec 0c             	sub    $0xc,%esp
f0100e14:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e17:	8d 83 f8 d3 fe ff    	lea    -0x12c08(%ebx),%eax
f0100e1d:	50                   	push   %eax
f0100e1e:	e8 c5 22 00 00       	call   f01030e8 <cprintf>
}
f0100e23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e26:	5b                   	pop    %ebx
f0100e27:	5e                   	pop    %esi
f0100e28:	5f                   	pop    %edi
f0100e29:	5d                   	pop    %ebp
f0100e2a:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e2b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e2e:	8d 83 5f db fe ff    	lea    -0x124a1(%ebx),%eax
f0100e34:	50                   	push   %eax
f0100e35:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100e3b:	50                   	push   %eax
f0100e3c:	68 63 02 00 00       	push   $0x263
f0100e41:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100e47:	50                   	push   %eax
f0100e48:	e8 4c f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e4d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e50:	8d 83 71 db fe ff    	lea    -0x1248f(%ebx),%eax
f0100e56:	50                   	push   %eax
f0100e57:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0100e5d:	50                   	push   %eax
f0100e5e:	68 64 02 00 00       	push   $0x264
f0100e63:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0100e69:	50                   	push   %eax
f0100e6a:	e8 2a f2 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100e6f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e72:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0100e78:	85 c0                	test   %eax,%eax
f0100e7a:	0f 84 2a fd ff ff    	je     f0100baa <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e80:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e83:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e86:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e89:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e8c:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100e8f:	c7 c3 b0 96 11 f0    	mov    $0xf01196b0,%ebx
f0100e95:	89 c2                	mov    %eax,%edx
f0100e97:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e99:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e9f:	0f 95 c2             	setne  %dl
f0100ea2:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ea5:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ea9:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100eab:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100eaf:	8b 00                	mov    (%eax),%eax
f0100eb1:	85 c0                	test   %eax,%eax
f0100eb3:	75 e0                	jne    f0100e95 <check_page_free_list+0x322>
		*tp[1] = 0;
f0100eb5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100eb8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ebe:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ec1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ec4:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ec6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ec9:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ecc:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ed2:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ed9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100edc:	8b b0 90 1f 00 00    	mov    0x1f90(%eax),%esi
f0100ee2:	c7 c7 b0 96 11 f0    	mov    $0xf01196b0,%edi
	if (PGNUM(pa) >= npages)
f0100ee8:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0100eee:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ef1:	e9 ed fc ff ff       	jmp    f0100be3 <check_page_free_list+0x70>

f0100ef6 <page_init>:
{
f0100ef6:	55                   	push   %ebp
f0100ef7:	89 e5                	mov    %esp,%ebp
f0100ef9:	57                   	push   %edi
f0100efa:	56                   	push   %esi
f0100efb:	53                   	push   %ebx
f0100efc:	83 ec 2c             	sub    $0x2c,%esp
f0100eff:	e8 55 21 00 00       	call   f0103059 <__x86.get_pc_thunk.si>
f0100f04:	81 c6 08 64 01 00    	add    $0x16408,%esi
	physaddr_t truly_end = PADDR(boot_alloc(0));
f0100f0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f0f:	e8 53 fb ff ff       	call   f0100a67 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100f14:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f19:	76 33                	jbe    f0100f4e <page_init+0x58>
	return (physaddr_t)kva - KERNBASE;
f0100f1b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f20:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f23:	8b 86 90 1f 00 00    	mov    0x1f90(%esi),%eax
f0100f29:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < npages; i++)
f0100f2c:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
f0100f30:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f35:	c7 c3 a8 96 11 f0    	mov    $0xf01196a8,%ebx
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
f0100f3b:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0100f41:	89 55 d8             	mov    %edx,-0x28(%ebp)
			page_free_list = &pages[i];
f0100f44:	89 55 d0             	mov    %edx,-0x30(%ebp)
			pages[i].pp_ref = 1;
f0100f47:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100f4a:	89 c1                	mov    %eax,%ecx
	for (i = 0; i < npages; i++)
f0100f4c:	eb 55                	jmp    f0100fa3 <page_init+0xad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f4e:	50                   	push   %eax
f0100f4f:	8d 86 1c d4 fe ff    	lea    -0x12be4(%esi),%eax
f0100f55:	50                   	push   %eax
f0100f56:	68 13 01 00 00       	push   $0x113
f0100f5b:	8d 86 cc da fe ff    	lea    -0x12534(%esi),%eax
f0100f61:	50                   	push   %eax
f0100f62:	89 f3                	mov    %esi,%ebx
f0100f64:	e8 30 f1 ff ff       	call   f0100099 <_panic>
f0100f69:	8d 04 cd 00 00 00 00 	lea    0x0(,%ecx,8),%eax
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
f0100f70:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100f73:	89 c2                	mov    %eax,%edx
f0100f75:	03 17                	add    (%edi),%edx
	return (pp - pages) << PGSHIFT;
f0100f77:	89 c7                	mov    %eax,%edi
f0100f79:	c1 e7 09             	shl    $0x9,%edi
f0100f7c:	39 7d dc             	cmp    %edi,-0x24(%ebp)
f0100f7f:	76 08                	jbe    f0100f89 <page_init+0x93>
f0100f81:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f0100f87:	77 35                	ja     f0100fbe <page_init+0xc8>
			pages[i].pp_ref = 0;
f0100f89:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100f8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f92:	89 3a                	mov    %edi,(%edx)
			page_free_list = &pages[i];
f0100f94:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f97:	03 02                	add    (%edx),%eax
f0100f99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f9c:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
	for (i = 0; i < npages; i++)
f0100fa0:	83 c1 01             	add    $0x1,%ecx
f0100fa3:	39 0b                	cmp    %ecx,(%ebx)
f0100fa5:	76 25                	jbe    f0100fcc <page_init+0xd6>
		if(i==0){
f0100fa7:	85 c9                	test   %ecx,%ecx
f0100fa9:	75 be                	jne    f0100f69 <page_init+0x73>
			pages[i].pp_ref = 1;
f0100fab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fae:	8b 00                	mov    (%eax),%eax
f0100fb0:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100fb6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fbc:	eb e2                	jmp    f0100fa0 <page_init+0xaa>
			pages[i].pp_ref = 1;
f0100fbe:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100fc4:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100fca:	eb d4                	jmp    f0100fa0 <page_init+0xaa>
f0100fcc:	80 7d e3 00          	cmpb   $0x0,-0x1d(%ebp)
f0100fd0:	75 08                	jne    f0100fda <page_init+0xe4>
}
f0100fd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fd5:	5b                   	pop    %ebx
f0100fd6:	5e                   	pop    %esi
f0100fd7:	5f                   	pop    %edi
f0100fd8:	5d                   	pop    %ebp
f0100fd9:	c3                   	ret    
f0100fda:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fdd:	89 86 90 1f 00 00    	mov    %eax,0x1f90(%esi)
f0100fe3:	eb ed                	jmp    f0100fd2 <page_init+0xdc>

f0100fe5 <page_alloc>:
{
f0100fe5:	55                   	push   %ebp
f0100fe6:	89 e5                	mov    %esp,%ebp
f0100fe8:	56                   	push   %esi
f0100fe9:	53                   	push   %ebx
f0100fea:	e8 60 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100fef:	81 c3 1d 63 01 00    	add    $0x1631d,%ebx
	if(page_free_list){
f0100ff5:	8b b3 90 1f 00 00    	mov    0x1f90(%ebx),%esi
f0100ffb:	85 f6                	test   %esi,%esi
f0100ffd:	74 14                	je     f0101013 <page_alloc+0x2e>
		page_free_list = freePage->pp_link;
f0100fff:	8b 06                	mov    (%esi),%eax
f0101001:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
		freePage->pp_link = NULL;
f0101007:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if(alloc_flags&ALLOC_ZERO){    // 只有这个条件满足时才把内存页面初始化为0
f010100d:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101011:	75 09                	jne    f010101c <page_alloc+0x37>
}
f0101013:	89 f0                	mov    %esi,%eax
f0101015:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101018:	5b                   	pop    %ebx
f0101019:	5e                   	pop    %esi
f010101a:	5d                   	pop    %ebp
f010101b:	c3                   	ret    
f010101c:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101022:	89 f2                	mov    %esi,%edx
f0101024:	2b 10                	sub    (%eax),%edx
f0101026:	89 d0                	mov    %edx,%eax
f0101028:	c1 f8 03             	sar    $0x3,%eax
f010102b:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010102e:	89 c1                	mov    %eax,%ecx
f0101030:	c1 e9 0c             	shr    $0xc,%ecx
f0101033:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101039:	3b 0a                	cmp    (%edx),%ecx
f010103b:	73 1a                	jae    f0101057 <page_alloc+0x72>
			memset(page2kva(freePage), 0, PGSIZE);
f010103d:	83 ec 04             	sub    $0x4,%esp
f0101040:	68 00 10 00 00       	push   $0x1000
f0101045:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101047:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010104c:	50                   	push   %eax
f010104d:	e8 a7 2c 00 00       	call   f0103cf9 <memset>
f0101052:	83 c4 10             	add    $0x10,%esp
f0101055:	eb bc                	jmp    f0101013 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101057:	50                   	push   %eax
f0101058:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010105e:	50                   	push   %eax
f010105f:	6a 59                	push   $0x59
f0101061:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0101067:	50                   	push   %eax
f0101068:	e8 2c f0 ff ff       	call   f0100099 <_panic>

f010106d <page_free>:
{
f010106d:	55                   	push   %ebp
f010106e:	89 e5                	mov    %esp,%ebp
f0101070:	53                   	push   %ebx
f0101071:	83 ec 04             	sub    $0x4,%esp
f0101074:	e8 d6 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101079:	81 c3 93 62 01 00    	add    $0x16293,%ebx
f010107f:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_ref||pp->pp_link){
f0101082:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101087:	75 18                	jne    f01010a1 <page_free+0x34>
f0101089:	83 38 00             	cmpl   $0x0,(%eax)
f010108c:	75 13                	jne    f01010a1 <page_free+0x34>
	pp->pp_link = page_free_list;
f010108e:	8b 8b 90 1f 00 00    	mov    0x1f90(%ebx),%ecx
f0101094:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0101096:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
}
f010109c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010109f:	c9                   	leave  
f01010a0:	c3                   	ret    
		panic("Page is free, have not to free\n");
f01010a1:	83 ec 04             	sub    $0x4,%esp
f01010a4:	8d 83 40 d4 fe ff    	lea    -0x12bc0(%ebx),%eax
f01010aa:	50                   	push   %eax
f01010ab:	68 4d 01 00 00       	push   $0x14d
f01010b0:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01010b6:	50                   	push   %eax
f01010b7:	e8 dd ef ff ff       	call   f0100099 <_panic>

f01010bc <page_decref>:
{
f01010bc:	55                   	push   %ebp
f01010bd:	89 e5                	mov    %esp,%ebp
f01010bf:	83 ec 08             	sub    $0x8,%esp
f01010c2:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01010c5:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01010c9:	83 e8 01             	sub    $0x1,%eax
f01010cc:	66 89 42 04          	mov    %ax,0x4(%edx)
f01010d0:	66 85 c0             	test   %ax,%ax
f01010d3:	74 02                	je     f01010d7 <page_decref+0x1b>
}
f01010d5:	c9                   	leave  
f01010d6:	c3                   	ret    
		page_free(pp);
f01010d7:	83 ec 0c             	sub    $0xc,%esp
f01010da:	52                   	push   %edx
f01010db:	e8 8d ff ff ff       	call   f010106d <page_free>
f01010e0:	83 c4 10             	add    $0x10,%esp
}
f01010e3:	eb f0                	jmp    f01010d5 <page_decref+0x19>

f01010e5 <pgdir_walk>:
{
f01010e5:	55                   	push   %ebp
f01010e6:	89 e5                	mov    %esp,%ebp
f01010e8:	57                   	push   %edi
f01010e9:	56                   	push   %esi
f01010ea:	53                   	push   %ebx
f01010eb:	83 ec 0c             	sub    $0xc,%esp
f01010ee:	e8 5c f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01010f3:	81 c3 19 62 01 00    	add    $0x16219,%ebx
f01010f9:	8b 75 0c             	mov    0xc(%ebp),%esi
	size_t pgt_index = PTX(va);  // 页表索引
f01010fc:	89 f7                	mov    %esi,%edi
f01010fe:	c1 ef 0c             	shr    $0xc,%edi
f0101101:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
	size_t pgdir_index = PDX(va);  // 页目录索引
f0101107:	c1 ee 16             	shr    $0x16,%esi
	pde_t* pde = pgdir+pgdir_index;   // 页目录项指针
f010110a:	c1 e6 02             	shl    $0x2,%esi
f010110d:	03 75 08             	add    0x8(%ebp),%esi
	if (!*pde & PTE_P)
f0101110:	83 3e 00             	cmpl   $0x0,(%esi)
f0101113:	75 2f                	jne    f0101144 <pgdir_walk+0x5f>
		if(!create)
f0101115:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101119:	74 67                	je     f0101182 <pgdir_walk+0x9d>
		struct PageInfo *new_page = page_alloc(1);
f010111b:	83 ec 0c             	sub    $0xc,%esp
f010111e:	6a 01                	push   $0x1
f0101120:	e8 c0 fe ff ff       	call   f0100fe5 <page_alloc>
		if(!new_page)
f0101125:	83 c4 10             	add    $0x10,%esp
f0101128:	85 c0                	test   %eax,%eax
f010112a:	74 5d                	je     f0101189 <pgdir_walk+0xa4>
		new_page->pp_ref++;
f010112c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101131:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101137:	2b 02                	sub    (%edx),%eax
f0101139:	c1 f8 03             	sar    $0x3,%eax
f010113c:	c1 e0 0c             	shl    $0xc,%eax
		*pde = page2pa(new_page) | PTE_P | PTE_W | PTE_U;   // 更新页目录项,为什么要设置 PTE_W  PTE_U 这两位?
f010113f:	83 c8 07             	or     $0x7,%eax
f0101142:	89 06                	mov    %eax,(%esi)
	pte = (pte_t *)KADDR(PTE_ADDR(*pde));
f0101144:	8b 06                	mov    (%esi),%eax
f0101146:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010114b:	89 c1                	mov    %eax,%ecx
f010114d:	c1 e9 0c             	shr    $0xc,%ecx
f0101150:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101156:	3b 0a                	cmp    (%edx),%ecx
f0101158:	73 0f                	jae    f0101169 <pgdir_walk+0x84>
	return pte + pgt_index;    // 返回页表项的指针
f010115a:	8d 84 b8 00 00 00 f0 	lea    -0x10000000(%eax,%edi,4),%eax
}
f0101161:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101164:	5b                   	pop    %ebx
f0101165:	5e                   	pop    %esi
f0101166:	5f                   	pop    %edi
f0101167:	5d                   	pop    %ebp
f0101168:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101169:	50                   	push   %eax
f010116a:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101170:	50                   	push   %eax
f0101171:	68 8f 01 00 00       	push   $0x18f
f0101176:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010117c:	50                   	push   %eax
f010117d:	e8 17 ef ff ff       	call   f0100099 <_panic>
			return NULL;
f0101182:	b8 00 00 00 00       	mov    $0x0,%eax
f0101187:	eb d8                	jmp    f0101161 <pgdir_walk+0x7c>
			return NULL;
f0101189:	b8 00 00 00 00       	mov    $0x0,%eax
f010118e:	eb d1                	jmp    f0101161 <pgdir_walk+0x7c>

f0101190 <boot_map_region>:
{
f0101190:	55                   	push   %ebp
f0101191:	89 e5                	mov    %esp,%ebp
f0101193:	57                   	push   %edi
f0101194:	56                   	push   %esi
f0101195:	53                   	push   %ebx
f0101196:	83 ec 1c             	sub    $0x1c,%esp
f0101199:	e8 bf 1e 00 00       	call   f010305d <__x86.get_pc_thunk.di>
f010119e:	81 c7 6e 61 01 00    	add    $0x1616e,%edi
f01011a4:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01011a7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011aa:	8b 45 08             	mov    0x8(%ebp),%eax
	for (size_t i = 0; i < size/PGSIZE;++i){
f01011ad:	c1 e9 0c             	shr    $0xc,%ecx
f01011b0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01011b3:	89 c3                	mov    %eax,%ebx
f01011b5:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t *pte = pgdir_walk(pgdir, (void*)va, 1);
f01011ba:	89 d7                	mov    %edx,%edi
f01011bc:	29 c7                	sub    %eax,%edi
		*pte = pa | perm | PTE_P;  // 要修改va对应的页表项，使其指向pa
f01011be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011c1:	83 c8 01             	or     $0x1,%eax
f01011c4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (size_t i = 0; i < size/PGSIZE;++i){
f01011c7:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f01011ca:	74 48                	je     f0101214 <boot_map_region+0x84>
		pte_t *pte = pgdir_walk(pgdir, (void*)va, 1);
f01011cc:	83 ec 04             	sub    $0x4,%esp
f01011cf:	6a 01                	push   $0x1
f01011d1:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01011d4:	50                   	push   %eax
f01011d5:	ff 75 e0             	pushl  -0x20(%ebp)
f01011d8:	e8 08 ff ff ff       	call   f01010e5 <pgdir_walk>
		if(!pte)
f01011dd:	83 c4 10             	add    $0x10,%esp
f01011e0:	85 c0                	test   %eax,%eax
f01011e2:	74 12                	je     f01011f6 <boot_map_region+0x66>
		*pte = pa | perm | PTE_P;  // 要修改va对应的页表项，使其指向pa
f01011e4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011e7:	09 da                	or     %ebx,%edx
f01011e9:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f01011eb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (size_t i = 0; i < size/PGSIZE;++i){
f01011f1:	83 c6 01             	add    $0x1,%esi
f01011f4:	eb d1                	jmp    f01011c7 <boot_map_region+0x37>
			panic("boot_map_region(): out of memory\n");
f01011f6:	83 ec 04             	sub    $0x4,%esp
f01011f9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01011fc:	8d 83 60 d4 fe ff    	lea    -0x12ba0(%ebx),%eax
f0101202:	50                   	push   %eax
f0101203:	68 a9 01 00 00       	push   $0x1a9
f0101208:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010120e:	50                   	push   %eax
f010120f:	e8 85 ee ff ff       	call   f0100099 <_panic>
}
f0101214:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101217:	5b                   	pop    %ebx
f0101218:	5e                   	pop    %esi
f0101219:	5f                   	pop    %edi
f010121a:	5d                   	pop    %ebp
f010121b:	c3                   	ret    

f010121c <page_lookup>:
{
f010121c:	55                   	push   %ebp
f010121d:	89 e5                	mov    %esp,%ebp
f010121f:	56                   	push   %esi
f0101220:	53                   	push   %ebx
f0101221:	e8 29 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101226:	81 c3 e6 60 01 00    	add    $0x160e6,%ebx
f010122c:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);   // 只返回va对应的页表项，不分配新的页表页
f010122f:	83 ec 04             	sub    $0x4,%esp
f0101232:	6a 00                	push   $0x0
f0101234:	ff 75 0c             	pushl  0xc(%ebp)
f0101237:	ff 75 08             	pushl  0x8(%ebp)
f010123a:	e8 a6 fe ff ff       	call   f01010e5 <pgdir_walk>
	if(pte_store){
f010123f:	83 c4 10             	add    $0x10,%esp
f0101242:	85 f6                	test   %esi,%esi
f0101244:	74 02                	je     f0101248 <page_lookup+0x2c>
		*pte_store = pte;
f0101246:	89 06                	mov    %eax,(%esi)
	if(pte){
f0101248:	85 c0                	test   %eax,%eax
f010124a:	74 39                	je     f0101285 <page_lookup+0x69>
f010124c:	8b 00                	mov    (%eax),%eax
f010124e:	c1 e8 0c             	shr    $0xc,%eax

// pa为物理地址，PGNUM(pa)为该页的页号，函数功能与 page2pa 相反
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101251:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101257:	39 02                	cmp    %eax,(%edx)
f0101259:	76 12                	jbe    f010126d <page_lookup+0x51>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010125b:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101261:	8b 12                	mov    (%edx),%edx
f0101263:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101266:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101269:	5b                   	pop    %ebx
f010126a:	5e                   	pop    %esi
f010126b:	5d                   	pop    %ebp
f010126c:	c3                   	ret    
		panic("pa2page called with invalid pa");
f010126d:	83 ec 04             	sub    $0x4,%esp
f0101270:	8d 83 84 d4 fe ff    	lea    -0x12b7c(%ebx),%eax
f0101276:	50                   	push   %eax
f0101277:	6a 52                	push   $0x52
f0101279:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f010127f:	50                   	push   %eax
f0101280:	e8 14 ee ff ff       	call   f0100099 <_panic>
	return NULL;
f0101285:	b8 00 00 00 00       	mov    $0x0,%eax
f010128a:	eb da                	jmp    f0101266 <page_lookup+0x4a>

f010128c <page_remove>:
{
f010128c:	55                   	push   %ebp
f010128d:	89 e5                	mov    %esp,%ebp
f010128f:	53                   	push   %ebx
f0101290:	83 ec 18             	sub    $0x18,%esp
f0101293:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0101296:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101299:	50                   	push   %eax
f010129a:	53                   	push   %ebx
f010129b:	ff 75 08             	pushl  0x8(%ebp)
f010129e:	e8 79 ff ff ff       	call   f010121c <page_lookup>
	if (!pp)
f01012a3:	83 c4 10             	add    $0x10,%esp
f01012a6:	85 c0                	test   %eax,%eax
f01012a8:	75 05                	jne    f01012af <page_remove+0x23>
}
f01012aa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012ad:	c9                   	leave  
f01012ae:	c3                   	ret    
	page_decref(pp);
f01012af:	83 ec 0c             	sub    $0xc,%esp
f01012b2:	50                   	push   %eax
f01012b3:	e8 04 fe ff ff       	call   f01010bc <page_decref>
	*pte = 0;
f01012b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012bb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012c1:	0f 01 3b             	invlpg (%ebx)
f01012c4:	83 c4 10             	add    $0x10,%esp
f01012c7:	eb e1                	jmp    f01012aa <page_remove+0x1e>

f01012c9 <page_insert>:
{
f01012c9:	55                   	push   %ebp
f01012ca:	89 e5                	mov    %esp,%ebp
f01012cc:	57                   	push   %edi
f01012cd:	56                   	push   %esi
f01012ce:	53                   	push   %ebx
f01012cf:	83 ec 10             	sub    $0x10,%esp
f01012d2:	e8 86 1d 00 00       	call   f010305d <__x86.get_pc_thunk.di>
f01012d7:	81 c7 35 60 01 00    	add    $0x16035,%edi
f01012dd:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f01012e0:	6a 01                	push   $0x1
f01012e2:	ff 75 10             	pushl  0x10(%ebp)
f01012e5:	ff 75 08             	pushl  0x8(%ebp)
f01012e8:	e8 f8 fd ff ff       	call   f01010e5 <pgdir_walk>
	if (!pte)
f01012ed:	83 c4 10             	add    $0x10,%esp
f01012f0:	85 c0                	test   %eax,%eax
f01012f2:	74 4c                	je     f0101340 <page_insert+0x77>
f01012f4:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;   // 引用计数的增加必须在 page_remove 前面！！  this is an elegant way to handle
f01012f6:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	pp->pp_link = NULL;
f01012fb:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if(*pte&PTE_P){
f0101301:	f6 00 01             	testb  $0x1,(%eax)
f0101304:	75 27                	jne    f010132d <page_insert+0x64>
	return (pp - pages) << PGSHIFT;
f0101306:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f010130c:	2b 30                	sub    (%eax),%esi
f010130e:	89 f0                	mov    %esi,%eax
f0101310:	c1 f8 03             	sar    $0x3,%eax
f0101313:	c1 e0 0c             	shl    $0xc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
f0101316:	8b 55 14             	mov    0x14(%ebp),%edx
f0101319:	83 ca 01             	or     $0x1,%edx
f010131c:	09 d0                	or     %edx,%eax
f010131e:	89 03                	mov    %eax,(%ebx)
	return 0;
f0101320:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101325:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101328:	5b                   	pop    %ebx
f0101329:	5e                   	pop    %esi
f010132a:	5f                   	pop    %edi
f010132b:	5d                   	pop    %ebp
f010132c:	c3                   	ret    
		page_remove(pgdir, va);
f010132d:	83 ec 08             	sub    $0x8,%esp
f0101330:	ff 75 10             	pushl  0x10(%ebp)
f0101333:	ff 75 08             	pushl  0x8(%ebp)
f0101336:	e8 51 ff ff ff       	call   f010128c <page_remove>
f010133b:	83 c4 10             	add    $0x10,%esp
f010133e:	eb c6                	jmp    f0101306 <page_insert+0x3d>
		return -E_NO_MEM;
f0101340:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101345:	eb de                	jmp    f0101325 <page_insert+0x5c>

f0101347 <mem_init>:
{
f0101347:	55                   	push   %ebp
f0101348:	89 e5                	mov    %esp,%ebp
f010134a:	57                   	push   %edi
f010134b:	56                   	push   %esi
f010134c:	53                   	push   %ebx
f010134d:	83 ec 3c             	sub    $0x3c,%esp
f0101350:	e8 9c f3 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0101355:	05 b7 5f 01 00       	add    $0x15fb7,%eax
f010135a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f010135d:	b8 15 00 00 00       	mov    $0x15,%eax
f0101362:	e8 59 f7 ff ff       	call   f0100ac0 <nvram_read>
f0101367:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101369:	b8 17 00 00 00       	mov    $0x17,%eax
f010136e:	e8 4d f7 ff ff       	call   f0100ac0 <nvram_read>
f0101373:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101375:	b8 34 00 00 00       	mov    $0x34,%eax
f010137a:	e8 41 f7 ff ff       	call   f0100ac0 <nvram_read>
f010137f:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101382:	85 c0                	test   %eax,%eax
f0101384:	0f 85 c2 00 00 00    	jne    f010144c <mem_init+0x105>
		totalmem = 1 * 1024 + extmem;
f010138a:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101390:	85 f6                	test   %esi,%esi
f0101392:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101395:	89 c1                	mov    %eax,%ecx
f0101397:	c1 e9 02             	shr    $0x2,%ecx
f010139a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010139d:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f01013a3:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013a5:	89 c2                	mov    %eax,%edx
f01013a7:	29 da                	sub    %ebx,%edx
f01013a9:	52                   	push   %edx
f01013aa:	53                   	push   %ebx
f01013ab:	50                   	push   %eax
f01013ac:	8d 87 a4 d4 fe ff    	lea    -0x12b5c(%edi),%eax
f01013b2:	50                   	push   %eax
f01013b3:	89 fb                	mov    %edi,%ebx
f01013b5:	e8 2e 1d 00 00       	call   f01030e8 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);    // 初始占一整页
f01013ba:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013bf:	e8 a3 f6 ff ff       	call   f0100a67 <boot_alloc>
f01013c4:	c7 c6 ac 96 11 f0    	mov    $0xf01196ac,%esi
f01013ca:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);   // 初始化为0
f01013cc:	83 c4 0c             	add    $0xc,%esp
f01013cf:	68 00 10 00 00       	push   $0x1000
f01013d4:	6a 00                	push   $0x0
f01013d6:	50                   	push   %eax
f01013d7:	e8 1d 29 00 00       	call   f0103cf9 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013dc:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01013de:	83 c4 10             	add    $0x10,%esp
f01013e1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013e6:	76 6e                	jbe    f0101456 <mem_init+0x10f>
	return (physaddr_t)kva - KERNBASE;
f01013e8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013ee:	83 ca 05             	or     $0x5,%edx
f01013f1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f01013f7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01013fa:	c7 c3 a8 96 11 f0    	mov    $0xf01196a8,%ebx
f0101400:	8b 03                	mov    (%ebx),%eax
f0101402:	c1 e0 03             	shl    $0x3,%eax
f0101405:	e8 5d f6 ff ff       	call   f0100a67 <boot_alloc>
f010140a:	c7 c6 b0 96 11 f0    	mov    $0xf01196b0,%esi
f0101410:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101412:	83 ec 04             	sub    $0x4,%esp
f0101415:	8b 13                	mov    (%ebx),%edx
f0101417:	c1 e2 03             	shl    $0x3,%edx
f010141a:	52                   	push   %edx
f010141b:	6a 00                	push   $0x0
f010141d:	50                   	push   %eax
f010141e:	89 fb                	mov    %edi,%ebx
f0101420:	e8 d4 28 00 00       	call   f0103cf9 <memset>
	page_init();
f0101425:	e8 cc fa ff ff       	call   f0100ef6 <page_init>
	check_page_free_list(1);
f010142a:	b8 01 00 00 00       	mov    $0x1,%eax
f010142f:	e8 3f f7 ff ff       	call   f0100b73 <check_page_free_list>
	if (!pages)
f0101434:	83 c4 10             	add    $0x10,%esp
f0101437:	83 3e 00             	cmpl   $0x0,(%esi)
f010143a:	74 36                	je     f0101472 <mem_init+0x12b>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010143c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010143f:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0101445:	be 00 00 00 00       	mov    $0x0,%esi
f010144a:	eb 49                	jmp    f0101495 <mem_init+0x14e>
		totalmem = 16 * 1024 + ext16mem;
f010144c:	05 00 40 00 00       	add    $0x4000,%eax
f0101451:	e9 3f ff ff ff       	jmp    f0101395 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101456:	50                   	push   %eax
f0101457:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010145a:	8d 83 1c d4 fe ff    	lea    -0x12be4(%ebx),%eax
f0101460:	50                   	push   %eax
f0101461:	68 9b 00 00 00       	push   $0x9b
f0101466:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010146c:	50                   	push   %eax
f010146d:	e8 27 ec ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101472:	83 ec 04             	sub    $0x4,%esp
f0101475:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101478:	8d 83 82 db fe ff    	lea    -0x1247e(%ebx),%eax
f010147e:	50                   	push   %eax
f010147f:	68 77 02 00 00       	push   $0x277
f0101484:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010148a:	50                   	push   %eax
f010148b:	e8 09 ec ff ff       	call   f0100099 <_panic>
		++nfree;
f0101490:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101493:	8b 00                	mov    (%eax),%eax
f0101495:	85 c0                	test   %eax,%eax
f0101497:	75 f7                	jne    f0101490 <mem_init+0x149>
	assert((pp0 = page_alloc(0)));
f0101499:	83 ec 0c             	sub    $0xc,%esp
f010149c:	6a 00                	push   $0x0
f010149e:	e8 42 fb ff ff       	call   f0100fe5 <page_alloc>
f01014a3:	89 c3                	mov    %eax,%ebx
f01014a5:	83 c4 10             	add    $0x10,%esp
f01014a8:	85 c0                	test   %eax,%eax
f01014aa:	0f 84 3b 02 00 00    	je     f01016eb <mem_init+0x3a4>
	assert((pp1 = page_alloc(0)));
f01014b0:	83 ec 0c             	sub    $0xc,%esp
f01014b3:	6a 00                	push   $0x0
f01014b5:	e8 2b fb ff ff       	call   f0100fe5 <page_alloc>
f01014ba:	89 c7                	mov    %eax,%edi
f01014bc:	83 c4 10             	add    $0x10,%esp
f01014bf:	85 c0                	test   %eax,%eax
f01014c1:	0f 84 46 02 00 00    	je     f010170d <mem_init+0x3c6>
	assert((pp2 = page_alloc(0)));
f01014c7:	83 ec 0c             	sub    $0xc,%esp
f01014ca:	6a 00                	push   $0x0
f01014cc:	e8 14 fb ff ff       	call   f0100fe5 <page_alloc>
f01014d1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01014d4:	83 c4 10             	add    $0x10,%esp
f01014d7:	85 c0                	test   %eax,%eax
f01014d9:	0f 84 50 02 00 00    	je     f010172f <mem_init+0x3e8>
	assert(pp1 && pp1 != pp0);
f01014df:	39 fb                	cmp    %edi,%ebx
f01014e1:	0f 84 6a 02 00 00    	je     f0101751 <mem_init+0x40a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014e7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014ea:	39 c3                	cmp    %eax,%ebx
f01014ec:	0f 84 81 02 00 00    	je     f0101773 <mem_init+0x42c>
f01014f2:	39 c7                	cmp    %eax,%edi
f01014f4:	0f 84 79 02 00 00    	je     f0101773 <mem_init+0x42c>
	return (pp - pages) << PGSHIFT;
f01014fa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01014fd:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101503:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101505:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f010150b:	8b 10                	mov    (%eax),%edx
f010150d:	c1 e2 0c             	shl    $0xc,%edx
f0101510:	89 d8                	mov    %ebx,%eax
f0101512:	29 c8                	sub    %ecx,%eax
f0101514:	c1 f8 03             	sar    $0x3,%eax
f0101517:	c1 e0 0c             	shl    $0xc,%eax
f010151a:	39 d0                	cmp    %edx,%eax
f010151c:	0f 83 73 02 00 00    	jae    f0101795 <mem_init+0x44e>
f0101522:	89 f8                	mov    %edi,%eax
f0101524:	29 c8                	sub    %ecx,%eax
f0101526:	c1 f8 03             	sar    $0x3,%eax
f0101529:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010152c:	39 c2                	cmp    %eax,%edx
f010152e:	0f 86 83 02 00 00    	jbe    f01017b7 <mem_init+0x470>
f0101534:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101537:	29 c8                	sub    %ecx,%eax
f0101539:	c1 f8 03             	sar    $0x3,%eax
f010153c:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010153f:	39 c2                	cmp    %eax,%edx
f0101541:	0f 86 92 02 00 00    	jbe    f01017d9 <mem_init+0x492>
	fl = page_free_list;
f0101547:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010154a:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f0101550:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101553:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f010155a:	00 00 00 
	assert(!page_alloc(0));
f010155d:	83 ec 0c             	sub    $0xc,%esp
f0101560:	6a 00                	push   $0x0
f0101562:	e8 7e fa ff ff       	call   f0100fe5 <page_alloc>
f0101567:	83 c4 10             	add    $0x10,%esp
f010156a:	85 c0                	test   %eax,%eax
f010156c:	0f 85 89 02 00 00    	jne    f01017fb <mem_init+0x4b4>
	page_free(pp0);
f0101572:	83 ec 0c             	sub    $0xc,%esp
f0101575:	53                   	push   %ebx
f0101576:	e8 f2 fa ff ff       	call   f010106d <page_free>
	page_free(pp1);
f010157b:	89 3c 24             	mov    %edi,(%esp)
f010157e:	e8 ea fa ff ff       	call   f010106d <page_free>
	page_free(pp2);
f0101583:	83 c4 04             	add    $0x4,%esp
f0101586:	ff 75 d0             	pushl  -0x30(%ebp)
f0101589:	e8 df fa ff ff       	call   f010106d <page_free>
	assert((pp0 = page_alloc(0)));
f010158e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101595:	e8 4b fa ff ff       	call   f0100fe5 <page_alloc>
f010159a:	89 c7                	mov    %eax,%edi
f010159c:	83 c4 10             	add    $0x10,%esp
f010159f:	85 c0                	test   %eax,%eax
f01015a1:	0f 84 76 02 00 00    	je     f010181d <mem_init+0x4d6>
	assert((pp1 = page_alloc(0)));
f01015a7:	83 ec 0c             	sub    $0xc,%esp
f01015aa:	6a 00                	push   $0x0
f01015ac:	e8 34 fa ff ff       	call   f0100fe5 <page_alloc>
f01015b1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015b4:	83 c4 10             	add    $0x10,%esp
f01015b7:	85 c0                	test   %eax,%eax
f01015b9:	0f 84 80 02 00 00    	je     f010183f <mem_init+0x4f8>
	assert((pp2 = page_alloc(0)));
f01015bf:	83 ec 0c             	sub    $0xc,%esp
f01015c2:	6a 00                	push   $0x0
f01015c4:	e8 1c fa ff ff       	call   f0100fe5 <page_alloc>
f01015c9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01015cc:	83 c4 10             	add    $0x10,%esp
f01015cf:	85 c0                	test   %eax,%eax
f01015d1:	0f 84 8a 02 00 00    	je     f0101861 <mem_init+0x51a>
	assert(pp1 && pp1 != pp0);
f01015d7:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f01015da:	0f 84 a3 02 00 00    	je     f0101883 <mem_init+0x53c>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015e0:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01015e3:	39 c7                	cmp    %eax,%edi
f01015e5:	0f 84 ba 02 00 00    	je     f01018a5 <mem_init+0x55e>
f01015eb:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01015ee:	0f 84 b1 02 00 00    	je     f01018a5 <mem_init+0x55e>
	assert(!page_alloc(0));
f01015f4:	83 ec 0c             	sub    $0xc,%esp
f01015f7:	6a 00                	push   $0x0
f01015f9:	e8 e7 f9 ff ff       	call   f0100fe5 <page_alloc>
f01015fe:	83 c4 10             	add    $0x10,%esp
f0101601:	85 c0                	test   %eax,%eax
f0101603:	0f 85 be 02 00 00    	jne    f01018c7 <mem_init+0x580>
f0101609:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010160c:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101612:	89 f9                	mov    %edi,%ecx
f0101614:	2b 08                	sub    (%eax),%ecx
f0101616:	89 c8                	mov    %ecx,%eax
f0101618:	c1 f8 03             	sar    $0x3,%eax
f010161b:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010161e:	89 c1                	mov    %eax,%ecx
f0101620:	c1 e9 0c             	shr    $0xc,%ecx
f0101623:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101629:	3b 0a                	cmp    (%edx),%ecx
f010162b:	0f 83 b8 02 00 00    	jae    f01018e9 <mem_init+0x5a2>
	memset(page2kva(pp0), 1, PGSIZE);
f0101631:	83 ec 04             	sub    $0x4,%esp
f0101634:	68 00 10 00 00       	push   $0x1000
f0101639:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010163b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101640:	50                   	push   %eax
f0101641:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101644:	e8 b0 26 00 00       	call   f0103cf9 <memset>
	page_free(pp0);
f0101649:	89 3c 24             	mov    %edi,(%esp)
f010164c:	e8 1c fa ff ff       	call   f010106d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101651:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101658:	e8 88 f9 ff ff       	call   f0100fe5 <page_alloc>
f010165d:	83 c4 10             	add    $0x10,%esp
f0101660:	85 c0                	test   %eax,%eax
f0101662:	0f 84 97 02 00 00    	je     f01018ff <mem_init+0x5b8>
	assert(pp && pp0 == pp);
f0101668:	39 c7                	cmp    %eax,%edi
f010166a:	0f 85 b1 02 00 00    	jne    f0101921 <mem_init+0x5da>
	return (pp - pages) << PGSHIFT;
f0101670:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101673:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101679:	89 fa                	mov    %edi,%edx
f010167b:	2b 10                	sub    (%eax),%edx
f010167d:	c1 fa 03             	sar    $0x3,%edx
f0101680:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101683:	89 d1                	mov    %edx,%ecx
f0101685:	c1 e9 0c             	shr    $0xc,%ecx
f0101688:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f010168e:	3b 08                	cmp    (%eax),%ecx
f0101690:	0f 83 ad 02 00 00    	jae    f0101943 <mem_init+0x5fc>
	return (void *)(pa + KERNBASE);
f0101696:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f010169c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01016a2:	80 38 00             	cmpb   $0x0,(%eax)
f01016a5:	0f 85 ae 02 00 00    	jne    f0101959 <mem_init+0x612>
f01016ab:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016ae:	39 d0                	cmp    %edx,%eax
f01016b0:	75 f0                	jne    f01016a2 <mem_init+0x35b>
	page_free_list = fl;
f01016b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016b5:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01016b8:	89 8b 90 1f 00 00    	mov    %ecx,0x1f90(%ebx)
	page_free(pp0);
f01016be:	83 ec 0c             	sub    $0xc,%esp
f01016c1:	57                   	push   %edi
f01016c2:	e8 a6 f9 ff ff       	call   f010106d <page_free>
	page_free(pp1);
f01016c7:	83 c4 04             	add    $0x4,%esp
f01016ca:	ff 75 d0             	pushl  -0x30(%ebp)
f01016cd:	e8 9b f9 ff ff       	call   f010106d <page_free>
	page_free(pp2);
f01016d2:	83 c4 04             	add    $0x4,%esp
f01016d5:	ff 75 cc             	pushl  -0x34(%ebp)
f01016d8:	e8 90 f9 ff ff       	call   f010106d <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016dd:	8b 83 90 1f 00 00    	mov    0x1f90(%ebx),%eax
f01016e3:	83 c4 10             	add    $0x10,%esp
f01016e6:	e9 95 02 00 00       	jmp    f0101980 <mem_init+0x639>
	assert((pp0 = page_alloc(0)));
f01016eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016ee:	8d 83 9d db fe ff    	lea    -0x12463(%ebx),%eax
f01016f4:	50                   	push   %eax
f01016f5:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01016fb:	50                   	push   %eax
f01016fc:	68 7f 02 00 00       	push   $0x27f
f0101701:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0101707:	50                   	push   %eax
f0101708:	e8 8c e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010170d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101710:	8d 83 b3 db fe ff    	lea    -0x1244d(%ebx),%eax
f0101716:	50                   	push   %eax
f0101717:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010171d:	50                   	push   %eax
f010171e:	68 80 02 00 00       	push   $0x280
f0101723:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0101729:	50                   	push   %eax
f010172a:	e8 6a e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010172f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101732:	8d 83 c9 db fe ff    	lea    -0x12437(%ebx),%eax
f0101738:	50                   	push   %eax
f0101739:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010173f:	50                   	push   %eax
f0101740:	68 81 02 00 00       	push   $0x281
f0101745:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010174b:	50                   	push   %eax
f010174c:	e8 48 e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101751:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101754:	8d 83 df db fe ff    	lea    -0x12421(%ebx),%eax
f010175a:	50                   	push   %eax
f010175b:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0101761:	50                   	push   %eax
f0101762:	68 84 02 00 00       	push   $0x284
f0101767:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010176d:	50                   	push   %eax
f010176e:	e8 26 e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101773:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101776:	8d 83 e0 d4 fe ff    	lea    -0x12b20(%ebx),%eax
f010177c:	50                   	push   %eax
f010177d:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0101783:	50                   	push   %eax
f0101784:	68 85 02 00 00       	push   $0x285
f0101789:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010178f:	50                   	push   %eax
f0101790:	e8 04 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101795:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101798:	8d 83 f1 db fe ff    	lea    -0x1240f(%ebx),%eax
f010179e:	50                   	push   %eax
f010179f:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01017a5:	50                   	push   %eax
f01017a6:	68 86 02 00 00       	push   $0x286
f01017ab:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01017b1:	50                   	push   %eax
f01017b2:	e8 e2 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01017b7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017ba:	8d 83 0e dc fe ff    	lea    -0x123f2(%ebx),%eax
f01017c0:	50                   	push   %eax
f01017c1:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01017c7:	50                   	push   %eax
f01017c8:	68 87 02 00 00       	push   $0x287
f01017cd:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01017d3:	50                   	push   %eax
f01017d4:	e8 c0 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01017d9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017dc:	8d 83 2b dc fe ff    	lea    -0x123d5(%ebx),%eax
f01017e2:	50                   	push   %eax
f01017e3:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01017e9:	50                   	push   %eax
f01017ea:	68 88 02 00 00       	push   $0x288
f01017ef:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01017f5:	50                   	push   %eax
f01017f6:	e8 9e e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01017fb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017fe:	8d 83 48 dc fe ff    	lea    -0x123b8(%ebx),%eax
f0101804:	50                   	push   %eax
f0101805:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010180b:	50                   	push   %eax
f010180c:	68 8f 02 00 00       	push   $0x28f
f0101811:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0101817:	50                   	push   %eax
f0101818:	e8 7c e8 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010181d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101820:	8d 83 9d db fe ff    	lea    -0x12463(%ebx),%eax
f0101826:	50                   	push   %eax
f0101827:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010182d:	50                   	push   %eax
f010182e:	68 96 02 00 00       	push   $0x296
f0101833:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0101839:	50                   	push   %eax
f010183a:	e8 5a e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010183f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101842:	8d 83 b3 db fe ff    	lea    -0x1244d(%ebx),%eax
f0101848:	50                   	push   %eax
f0101849:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010184f:	50                   	push   %eax
f0101850:	68 97 02 00 00       	push   $0x297
f0101855:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010185b:	50                   	push   %eax
f010185c:	e8 38 e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101861:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101864:	8d 83 c9 db fe ff    	lea    -0x12437(%ebx),%eax
f010186a:	50                   	push   %eax
f010186b:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0101871:	50                   	push   %eax
f0101872:	68 98 02 00 00       	push   $0x298
f0101877:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010187d:	50                   	push   %eax
f010187e:	e8 16 e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101883:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101886:	8d 83 df db fe ff    	lea    -0x12421(%ebx),%eax
f010188c:	50                   	push   %eax
f010188d:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0101893:	50                   	push   %eax
f0101894:	68 9a 02 00 00       	push   $0x29a
f0101899:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010189f:	50                   	push   %eax
f01018a0:	e8 f4 e7 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018a5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018a8:	8d 83 e0 d4 fe ff    	lea    -0x12b20(%ebx),%eax
f01018ae:	50                   	push   %eax
f01018af:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01018b5:	50                   	push   %eax
f01018b6:	68 9b 02 00 00       	push   $0x29b
f01018bb:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01018c1:	50                   	push   %eax
f01018c2:	e8 d2 e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01018c7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018ca:	8d 83 48 dc fe ff    	lea    -0x123b8(%ebx),%eax
f01018d0:	50                   	push   %eax
f01018d1:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01018d7:	50                   	push   %eax
f01018d8:	68 9c 02 00 00       	push   $0x29c
f01018dd:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01018e3:	50                   	push   %eax
f01018e4:	e8 b0 e7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018e9:	50                   	push   %eax
f01018ea:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01018f0:	50                   	push   %eax
f01018f1:	6a 59                	push   $0x59
f01018f3:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f01018f9:	50                   	push   %eax
f01018fa:	e8 9a e7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01018ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101902:	8d 83 57 dc fe ff    	lea    -0x123a9(%ebx),%eax
f0101908:	50                   	push   %eax
f0101909:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010190f:	50                   	push   %eax
f0101910:	68 a1 02 00 00       	push   $0x2a1
f0101915:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010191b:	50                   	push   %eax
f010191c:	e8 78 e7 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101921:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101924:	8d 83 75 dc fe ff    	lea    -0x1238b(%ebx),%eax
f010192a:	50                   	push   %eax
f010192b:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0101931:	50                   	push   %eax
f0101932:	68 a2 02 00 00       	push   $0x2a2
f0101937:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010193d:	50                   	push   %eax
f010193e:	e8 56 e7 ff ff       	call   f0100099 <_panic>
f0101943:	52                   	push   %edx
f0101944:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010194a:	50                   	push   %eax
f010194b:	6a 59                	push   $0x59
f010194d:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0101953:	50                   	push   %eax
f0101954:	e8 40 e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101959:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010195c:	8d 83 85 dc fe ff    	lea    -0x1237b(%ebx),%eax
f0101962:	50                   	push   %eax
f0101963:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0101969:	50                   	push   %eax
f010196a:	68 a5 02 00 00       	push   $0x2a5
f010196f:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0101975:	50                   	push   %eax
f0101976:	e8 1e e7 ff ff       	call   f0100099 <_panic>
		--nfree;
f010197b:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010197e:	8b 00                	mov    (%eax),%eax
f0101980:	85 c0                	test   %eax,%eax
f0101982:	75 f7                	jne    f010197b <mem_init+0x634>
	assert(nfree == 0);
f0101984:	85 f6                	test   %esi,%esi
f0101986:	0f 85 5b 08 00 00    	jne    f01021e7 <mem_init+0xea0>
	cprintf("check_page_alloc() succeeded!\n");
f010198c:	83 ec 0c             	sub    $0xc,%esp
f010198f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101992:	8d 83 00 d5 fe ff    	lea    -0x12b00(%ebx),%eax
f0101998:	50                   	push   %eax
f0101999:	e8 4a 17 00 00       	call   f01030e8 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010199e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a5:	e8 3b f6 ff ff       	call   f0100fe5 <page_alloc>
f01019aa:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019ad:	83 c4 10             	add    $0x10,%esp
f01019b0:	85 c0                	test   %eax,%eax
f01019b2:	0f 84 51 08 00 00    	je     f0102209 <mem_init+0xec2>
	assert((pp1 = page_alloc(0)));
f01019b8:	83 ec 0c             	sub    $0xc,%esp
f01019bb:	6a 00                	push   $0x0
f01019bd:	e8 23 f6 ff ff       	call   f0100fe5 <page_alloc>
f01019c2:	89 c7                	mov    %eax,%edi
f01019c4:	83 c4 10             	add    $0x10,%esp
f01019c7:	85 c0                	test   %eax,%eax
f01019c9:	0f 84 5c 08 00 00    	je     f010222b <mem_init+0xee4>
	assert((pp2 = page_alloc(0)));
f01019cf:	83 ec 0c             	sub    $0xc,%esp
f01019d2:	6a 00                	push   $0x0
f01019d4:	e8 0c f6 ff ff       	call   f0100fe5 <page_alloc>
f01019d9:	89 c6                	mov    %eax,%esi
f01019db:	83 c4 10             	add    $0x10,%esp
f01019de:	85 c0                	test   %eax,%eax
f01019e0:	0f 84 67 08 00 00    	je     f010224d <mem_init+0xf06>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019e6:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f01019e9:	0f 84 80 08 00 00    	je     f010226f <mem_init+0xf28>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019ef:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01019f2:	0f 84 99 08 00 00    	je     f0102291 <mem_init+0xf4a>
f01019f8:	39 c7                	cmp    %eax,%edi
f01019fa:	0f 84 91 08 00 00    	je     f0102291 <mem_init+0xf4a>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a00:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a03:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f0101a09:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101a0c:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f0101a13:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a16:	83 ec 0c             	sub    $0xc,%esp
f0101a19:	6a 00                	push   $0x0
f0101a1b:	e8 c5 f5 ff ff       	call   f0100fe5 <page_alloc>
f0101a20:	83 c4 10             	add    $0x10,%esp
f0101a23:	85 c0                	test   %eax,%eax
f0101a25:	0f 85 88 08 00 00    	jne    f01022b3 <mem_init+0xf6c>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a2b:	83 ec 04             	sub    $0x4,%esp
f0101a2e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a31:	50                   	push   %eax
f0101a32:	6a 00                	push   $0x0
f0101a34:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a37:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a3d:	ff 30                	pushl  (%eax)
f0101a3f:	e8 d8 f7 ff ff       	call   f010121c <page_lookup>
f0101a44:	83 c4 10             	add    $0x10,%esp
f0101a47:	85 c0                	test   %eax,%eax
f0101a49:	0f 85 86 08 00 00    	jne    f01022d5 <mem_init+0xf8e>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a4f:	6a 02                	push   $0x2
f0101a51:	6a 00                	push   $0x0
f0101a53:	57                   	push   %edi
f0101a54:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a57:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a5d:	ff 30                	pushl  (%eax)
f0101a5f:	e8 65 f8 ff ff       	call   f01012c9 <page_insert>
f0101a64:	83 c4 10             	add    $0x10,%esp
f0101a67:	85 c0                	test   %eax,%eax
f0101a69:	0f 89 88 08 00 00    	jns    f01022f7 <mem_init+0xfb0>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a6f:	83 ec 0c             	sub    $0xc,%esp
f0101a72:	ff 75 d0             	pushl  -0x30(%ebp)
f0101a75:	e8 f3 f5 ff ff       	call   f010106d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a7a:	6a 02                	push   $0x2
f0101a7c:	6a 00                	push   $0x0
f0101a7e:	57                   	push   %edi
f0101a7f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a82:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a88:	ff 30                	pushl  (%eax)
f0101a8a:	e8 3a f8 ff ff       	call   f01012c9 <page_insert>
f0101a8f:	83 c4 20             	add    $0x20,%esp
f0101a92:	85 c0                	test   %eax,%eax
f0101a94:	0f 85 7f 08 00 00    	jne    f0102319 <mem_init+0xfd2>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a9a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a9d:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101aa3:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101aa5:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101aab:	8b 08                	mov    (%eax),%ecx
f0101aad:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101ab0:	8b 13                	mov    (%ebx),%edx
f0101ab2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ab8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101abb:	29 c8                	sub    %ecx,%eax
f0101abd:	c1 f8 03             	sar    $0x3,%eax
f0101ac0:	c1 e0 0c             	shl    $0xc,%eax
f0101ac3:	39 c2                	cmp    %eax,%edx
f0101ac5:	0f 85 70 08 00 00    	jne    f010233b <mem_init+0xff4>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101acb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ad0:	89 d8                	mov    %ebx,%eax
f0101ad2:	e8 1f f0 ff ff       	call   f0100af6 <check_va2pa>
f0101ad7:	89 fa                	mov    %edi,%edx
f0101ad9:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101adc:	c1 fa 03             	sar    $0x3,%edx
f0101adf:	c1 e2 0c             	shl    $0xc,%edx
f0101ae2:	39 d0                	cmp    %edx,%eax
f0101ae4:	0f 85 73 08 00 00    	jne    f010235d <mem_init+0x1016>
	assert(pp1->pp_ref == 1);
f0101aea:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101aef:	0f 85 8a 08 00 00    	jne    f010237f <mem_init+0x1038>
	assert(pp0->pp_ref == 1);
f0101af5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101af8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101afd:	0f 85 9e 08 00 00    	jne    f01023a1 <mem_init+0x105a>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b03:	6a 02                	push   $0x2
f0101b05:	68 00 10 00 00       	push   $0x1000
f0101b0a:	56                   	push   %esi
f0101b0b:	53                   	push   %ebx
f0101b0c:	e8 b8 f7 ff ff       	call   f01012c9 <page_insert>
f0101b11:	83 c4 10             	add    $0x10,%esp
f0101b14:	85 c0                	test   %eax,%eax
f0101b16:	0f 85 a7 08 00 00    	jne    f01023c3 <mem_init+0x107c>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b1c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b21:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b24:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b2a:	8b 00                	mov    (%eax),%eax
f0101b2c:	e8 c5 ef ff ff       	call   f0100af6 <check_va2pa>
f0101b31:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101b37:	89 f1                	mov    %esi,%ecx
f0101b39:	2b 0a                	sub    (%edx),%ecx
f0101b3b:	89 ca                	mov    %ecx,%edx
f0101b3d:	c1 fa 03             	sar    $0x3,%edx
f0101b40:	c1 e2 0c             	shl    $0xc,%edx
f0101b43:	39 d0                	cmp    %edx,%eax
f0101b45:	0f 85 9a 08 00 00    	jne    f01023e5 <mem_init+0x109e>
	assert(pp2->pp_ref == 1);
f0101b4b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b50:	0f 85 b1 08 00 00    	jne    f0102407 <mem_init+0x10c0>

	// should be no free memory
	assert(!page_alloc(0));
f0101b56:	83 ec 0c             	sub    $0xc,%esp
f0101b59:	6a 00                	push   $0x0
f0101b5b:	e8 85 f4 ff ff       	call   f0100fe5 <page_alloc>
f0101b60:	83 c4 10             	add    $0x10,%esp
f0101b63:	85 c0                	test   %eax,%eax
f0101b65:	0f 85 be 08 00 00    	jne    f0102429 <mem_init+0x10e2>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b6b:	6a 02                	push   $0x2
f0101b6d:	68 00 10 00 00       	push   $0x1000
f0101b72:	56                   	push   %esi
f0101b73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b76:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b7c:	ff 30                	pushl  (%eax)
f0101b7e:	e8 46 f7 ff ff       	call   f01012c9 <page_insert>
f0101b83:	83 c4 10             	add    $0x10,%esp
f0101b86:	85 c0                	test   %eax,%eax
f0101b88:	0f 85 bd 08 00 00    	jne    f010244b <mem_init+0x1104>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b8e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b93:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b96:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b9c:	8b 00                	mov    (%eax),%eax
f0101b9e:	e8 53 ef ff ff       	call   f0100af6 <check_va2pa>
f0101ba3:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101ba9:	89 f1                	mov    %esi,%ecx
f0101bab:	2b 0a                	sub    (%edx),%ecx
f0101bad:	89 ca                	mov    %ecx,%edx
f0101baf:	c1 fa 03             	sar    $0x3,%edx
f0101bb2:	c1 e2 0c             	shl    $0xc,%edx
f0101bb5:	39 d0                	cmp    %edx,%eax
f0101bb7:	0f 85 b0 08 00 00    	jne    f010246d <mem_init+0x1126>
	assert(pp2->pp_ref == 1);
f0101bbd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bc2:	0f 85 c7 08 00 00    	jne    f010248f <mem_init+0x1148>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bc8:	83 ec 0c             	sub    $0xc,%esp
f0101bcb:	6a 00                	push   $0x0
f0101bcd:	e8 13 f4 ff ff       	call   f0100fe5 <page_alloc>
f0101bd2:	83 c4 10             	add    $0x10,%esp
f0101bd5:	85 c0                	test   %eax,%eax
f0101bd7:	0f 85 d4 08 00 00    	jne    f01024b1 <mem_init+0x116a>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bdd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101be0:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101be6:	8b 10                	mov    (%eax),%edx
f0101be8:	8b 02                	mov    (%edx),%eax
f0101bea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101bef:	89 c3                	mov    %eax,%ebx
f0101bf1:	c1 eb 0c             	shr    $0xc,%ebx
f0101bf4:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f0101bfa:	3b 19                	cmp    (%ecx),%ebx
f0101bfc:	0f 83 d1 08 00 00    	jae    f01024d3 <mem_init+0x118c>
	return (void *)(pa + KERNBASE);
f0101c02:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c07:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c0a:	83 ec 04             	sub    $0x4,%esp
f0101c0d:	6a 00                	push   $0x0
f0101c0f:	68 00 10 00 00       	push   $0x1000
f0101c14:	52                   	push   %edx
f0101c15:	e8 cb f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c1a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c1d:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c20:	83 c4 10             	add    $0x10,%esp
f0101c23:	39 d0                	cmp    %edx,%eax
f0101c25:	0f 85 c4 08 00 00    	jne    f01024ef <mem_init+0x11a8>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c2b:	6a 06                	push   $0x6
f0101c2d:	68 00 10 00 00       	push   $0x1000
f0101c32:	56                   	push   %esi
f0101c33:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c36:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c3c:	ff 30                	pushl  (%eax)
f0101c3e:	e8 86 f6 ff ff       	call   f01012c9 <page_insert>
f0101c43:	83 c4 10             	add    $0x10,%esp
f0101c46:	85 c0                	test   %eax,%eax
f0101c48:	0f 85 c3 08 00 00    	jne    f0102511 <mem_init+0x11ca>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c51:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c57:	8b 18                	mov    (%eax),%ebx
f0101c59:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c5e:	89 d8                	mov    %ebx,%eax
f0101c60:	e8 91 ee ff ff       	call   f0100af6 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101c65:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c68:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101c6e:	89 f1                	mov    %esi,%ecx
f0101c70:	2b 0a                	sub    (%edx),%ecx
f0101c72:	89 ca                	mov    %ecx,%edx
f0101c74:	c1 fa 03             	sar    $0x3,%edx
f0101c77:	c1 e2 0c             	shl    $0xc,%edx
f0101c7a:	39 d0                	cmp    %edx,%eax
f0101c7c:	0f 85 b1 08 00 00    	jne    f0102533 <mem_init+0x11ec>
	assert(pp2->pp_ref == 1);
f0101c82:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c87:	0f 85 c8 08 00 00    	jne    f0102555 <mem_init+0x120e>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c8d:	83 ec 04             	sub    $0x4,%esp
f0101c90:	6a 00                	push   $0x0
f0101c92:	68 00 10 00 00       	push   $0x1000
f0101c97:	53                   	push   %ebx
f0101c98:	e8 48 f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c9d:	83 c4 10             	add    $0x10,%esp
f0101ca0:	f6 00 04             	testb  $0x4,(%eax)
f0101ca3:	0f 84 ce 08 00 00    	je     f0102577 <mem_init+0x1230>
	assert(kern_pgdir[0] & PTE_U);
f0101ca9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cac:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101cb2:	8b 00                	mov    (%eax),%eax
f0101cb4:	f6 00 04             	testb  $0x4,(%eax)
f0101cb7:	0f 84 dc 08 00 00    	je     f0102599 <mem_init+0x1252>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cbd:	6a 02                	push   $0x2
f0101cbf:	68 00 10 00 00       	push   $0x1000
f0101cc4:	56                   	push   %esi
f0101cc5:	50                   	push   %eax
f0101cc6:	e8 fe f5 ff ff       	call   f01012c9 <page_insert>
f0101ccb:	83 c4 10             	add    $0x10,%esp
f0101cce:	85 c0                	test   %eax,%eax
f0101cd0:	0f 85 e5 08 00 00    	jne    f01025bb <mem_init+0x1274>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101cd6:	83 ec 04             	sub    $0x4,%esp
f0101cd9:	6a 00                	push   $0x0
f0101cdb:	68 00 10 00 00       	push   $0x1000
f0101ce0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ce3:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101ce9:	ff 30                	pushl  (%eax)
f0101ceb:	e8 f5 f3 ff ff       	call   f01010e5 <pgdir_walk>
f0101cf0:	83 c4 10             	add    $0x10,%esp
f0101cf3:	f6 00 02             	testb  $0x2,(%eax)
f0101cf6:	0f 84 e1 08 00 00    	je     f01025dd <mem_init+0x1296>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cfc:	83 ec 04             	sub    $0x4,%esp
f0101cff:	6a 00                	push   $0x0
f0101d01:	68 00 10 00 00       	push   $0x1000
f0101d06:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d09:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d0f:	ff 30                	pushl  (%eax)
f0101d11:	e8 cf f3 ff ff       	call   f01010e5 <pgdir_walk>
f0101d16:	83 c4 10             	add    $0x10,%esp
f0101d19:	f6 00 04             	testb  $0x4,(%eax)
f0101d1c:	0f 85 dd 08 00 00    	jne    f01025ff <mem_init+0x12b8>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d22:	6a 02                	push   $0x2
f0101d24:	68 00 00 40 00       	push   $0x400000
f0101d29:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d2c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d2f:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d35:	ff 30                	pushl  (%eax)
f0101d37:	e8 8d f5 ff ff       	call   f01012c9 <page_insert>
f0101d3c:	83 c4 10             	add    $0x10,%esp
f0101d3f:	85 c0                	test   %eax,%eax
f0101d41:	0f 89 da 08 00 00    	jns    f0102621 <mem_init+0x12da>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d47:	6a 02                	push   $0x2
f0101d49:	68 00 10 00 00       	push   $0x1000
f0101d4e:	57                   	push   %edi
f0101d4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d52:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d58:	ff 30                	pushl  (%eax)
f0101d5a:	e8 6a f5 ff ff       	call   f01012c9 <page_insert>
f0101d5f:	83 c4 10             	add    $0x10,%esp
f0101d62:	85 c0                	test   %eax,%eax
f0101d64:	0f 85 d9 08 00 00    	jne    f0102643 <mem_init+0x12fc>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d6a:	83 ec 04             	sub    $0x4,%esp
f0101d6d:	6a 00                	push   $0x0
f0101d6f:	68 00 10 00 00       	push   $0x1000
f0101d74:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d77:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d7d:	ff 30                	pushl  (%eax)
f0101d7f:	e8 61 f3 ff ff       	call   f01010e5 <pgdir_walk>
f0101d84:	83 c4 10             	add    $0x10,%esp
f0101d87:	f6 00 04             	testb  $0x4,(%eax)
f0101d8a:	0f 85 d5 08 00 00    	jne    f0102665 <mem_init+0x131e>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d93:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d99:	8b 18                	mov    (%eax),%ebx
f0101d9b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101da0:	89 d8                	mov    %ebx,%eax
f0101da2:	e8 4f ed ff ff       	call   f0100af6 <check_va2pa>
f0101da7:	89 c2                	mov    %eax,%edx
f0101da9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101dac:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101daf:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101db5:	89 f9                	mov    %edi,%ecx
f0101db7:	2b 08                	sub    (%eax),%ecx
f0101db9:	89 c8                	mov    %ecx,%eax
f0101dbb:	c1 f8 03             	sar    $0x3,%eax
f0101dbe:	c1 e0 0c             	shl    $0xc,%eax
f0101dc1:	39 c2                	cmp    %eax,%edx
f0101dc3:	0f 85 be 08 00 00    	jne    f0102687 <mem_init+0x1340>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dce:	89 d8                	mov    %ebx,%eax
f0101dd0:	e8 21 ed ff ff       	call   f0100af6 <check_va2pa>
f0101dd5:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101dd8:	0f 85 cb 08 00 00    	jne    f01026a9 <mem_init+0x1362>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101dde:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101de3:	0f 85 e2 08 00 00    	jne    f01026cb <mem_init+0x1384>
	assert(pp2->pp_ref == 0);
f0101de9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dee:	0f 85 f9 08 00 00    	jne    f01026ed <mem_init+0x13a6>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101df4:	83 ec 0c             	sub    $0xc,%esp
f0101df7:	6a 00                	push   $0x0
f0101df9:	e8 e7 f1 ff ff       	call   f0100fe5 <page_alloc>
f0101dfe:	83 c4 10             	add    $0x10,%esp
f0101e01:	39 c6                	cmp    %eax,%esi
f0101e03:	0f 85 06 09 00 00    	jne    f010270f <mem_init+0x13c8>
f0101e09:	85 c0                	test   %eax,%eax
f0101e0b:	0f 84 fe 08 00 00    	je     f010270f <mem_init+0x13c8>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e11:	83 ec 08             	sub    $0x8,%esp
f0101e14:	6a 00                	push   $0x0
f0101e16:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e19:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101e1f:	ff 33                	pushl  (%ebx)
f0101e21:	e8 66 f4 ff ff       	call   f010128c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e26:	8b 1b                	mov    (%ebx),%ebx
f0101e28:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e2d:	89 d8                	mov    %ebx,%eax
f0101e2f:	e8 c2 ec ff ff       	call   f0100af6 <check_va2pa>
f0101e34:	83 c4 10             	add    $0x10,%esp
f0101e37:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e3a:	0f 85 f1 08 00 00    	jne    f0102731 <mem_init+0x13ea>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e40:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e45:	89 d8                	mov    %ebx,%eax
f0101e47:	e8 aa ec ff ff       	call   f0100af6 <check_va2pa>
f0101e4c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e4f:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101e55:	89 f9                	mov    %edi,%ecx
f0101e57:	2b 0a                	sub    (%edx),%ecx
f0101e59:	89 ca                	mov    %ecx,%edx
f0101e5b:	c1 fa 03             	sar    $0x3,%edx
f0101e5e:	c1 e2 0c             	shl    $0xc,%edx
f0101e61:	39 d0                	cmp    %edx,%eax
f0101e63:	0f 85 ea 08 00 00    	jne    f0102753 <mem_init+0x140c>
	assert(pp1->pp_ref == 1);
f0101e69:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101e6e:	0f 85 01 09 00 00    	jne    f0102775 <mem_init+0x142e>
	assert(pp2->pp_ref == 0);
f0101e74:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e79:	0f 85 18 09 00 00    	jne    f0102797 <mem_init+0x1450>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e7f:	6a 00                	push   $0x0
f0101e81:	68 00 10 00 00       	push   $0x1000
f0101e86:	57                   	push   %edi
f0101e87:	53                   	push   %ebx
f0101e88:	e8 3c f4 ff ff       	call   f01012c9 <page_insert>
f0101e8d:	83 c4 10             	add    $0x10,%esp
f0101e90:	85 c0                	test   %eax,%eax
f0101e92:	0f 85 21 09 00 00    	jne    f01027b9 <mem_init+0x1472>
	assert(pp1->pp_ref);
f0101e98:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101e9d:	0f 84 38 09 00 00    	je     f01027db <mem_init+0x1494>
	assert(pp1->pp_link == NULL);
f0101ea3:	83 3f 00             	cmpl   $0x0,(%edi)
f0101ea6:	0f 85 51 09 00 00    	jne    f01027fd <mem_init+0x14b6>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101eac:	83 ec 08             	sub    $0x8,%esp
f0101eaf:	68 00 10 00 00       	push   $0x1000
f0101eb4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eb7:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101ebd:	ff 33                	pushl  (%ebx)
f0101ebf:	e8 c8 f3 ff ff       	call   f010128c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ec4:	8b 1b                	mov    (%ebx),%ebx
f0101ec6:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ecb:	89 d8                	mov    %ebx,%eax
f0101ecd:	e8 24 ec ff ff       	call   f0100af6 <check_va2pa>
f0101ed2:	83 c4 10             	add    $0x10,%esp
f0101ed5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ed8:	0f 85 41 09 00 00    	jne    f010281f <mem_init+0x14d8>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101ede:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ee3:	89 d8                	mov    %ebx,%eax
f0101ee5:	e8 0c ec ff ff       	call   f0100af6 <check_va2pa>
f0101eea:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101eed:	0f 85 4e 09 00 00    	jne    f0102841 <mem_init+0x14fa>
	assert(pp1->pp_ref == 0);
f0101ef3:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101ef8:	0f 85 65 09 00 00    	jne    f0102863 <mem_init+0x151c>
	assert(pp2->pp_ref == 0);
f0101efe:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f03:	0f 85 7c 09 00 00    	jne    f0102885 <mem_init+0x153e>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f09:	83 ec 0c             	sub    $0xc,%esp
f0101f0c:	6a 00                	push   $0x0
f0101f0e:	e8 d2 f0 ff ff       	call   f0100fe5 <page_alloc>
f0101f13:	83 c4 10             	add    $0x10,%esp
f0101f16:	39 c7                	cmp    %eax,%edi
f0101f18:	0f 85 89 09 00 00    	jne    f01028a7 <mem_init+0x1560>
f0101f1e:	85 c0                	test   %eax,%eax
f0101f20:	0f 84 81 09 00 00    	je     f01028a7 <mem_init+0x1560>

	// should be no free memory
	assert(!page_alloc(0));
f0101f26:	83 ec 0c             	sub    $0xc,%esp
f0101f29:	6a 00                	push   $0x0
f0101f2b:	e8 b5 f0 ff ff       	call   f0100fe5 <page_alloc>
f0101f30:	83 c4 10             	add    $0x10,%esp
f0101f33:	85 c0                	test   %eax,%eax
f0101f35:	0f 85 8e 09 00 00    	jne    f01028c9 <mem_init+0x1582>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f3b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f3e:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101f44:	8b 08                	mov    (%eax),%ecx
f0101f46:	8b 11                	mov    (%ecx),%edx
f0101f48:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f4e:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101f54:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f57:	2b 18                	sub    (%eax),%ebx
f0101f59:	89 d8                	mov    %ebx,%eax
f0101f5b:	c1 f8 03             	sar    $0x3,%eax
f0101f5e:	c1 e0 0c             	shl    $0xc,%eax
f0101f61:	39 c2                	cmp    %eax,%edx
f0101f63:	0f 85 82 09 00 00    	jne    f01028eb <mem_init+0x15a4>
	kern_pgdir[0] = 0;
f0101f69:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f6f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f72:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f77:	0f 85 90 09 00 00    	jne    f010290d <mem_init+0x15c6>
	pp0->pp_ref = 0;
f0101f7d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f80:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f86:	83 ec 0c             	sub    $0xc,%esp
f0101f89:	50                   	push   %eax
f0101f8a:	e8 de f0 ff ff       	call   f010106d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f8f:	83 c4 0c             	add    $0xc,%esp
f0101f92:	6a 01                	push   $0x1
f0101f94:	68 00 10 40 00       	push   $0x401000
f0101f99:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f9c:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101fa2:	ff 33                	pushl  (%ebx)
f0101fa4:	e8 3c f1 ff ff       	call   f01010e5 <pgdir_walk>
f0101fa9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101faf:	8b 1b                	mov    (%ebx),%ebx
f0101fb1:	8b 53 04             	mov    0x4(%ebx),%edx
f0101fb4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101fba:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101fbd:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f0101fc3:	8b 09                	mov    (%ecx),%ecx
f0101fc5:	89 d0                	mov    %edx,%eax
f0101fc7:	c1 e8 0c             	shr    $0xc,%eax
f0101fca:	83 c4 10             	add    $0x10,%esp
f0101fcd:	39 c8                	cmp    %ecx,%eax
f0101fcf:	0f 83 5a 09 00 00    	jae    f010292f <mem_init+0x15e8>
	assert(ptep == ptep1 + PTX(va));
f0101fd5:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101fdb:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101fde:	0f 85 67 09 00 00    	jne    f010294b <mem_init+0x1604>
	kern_pgdir[PDX(va)] = 0;
f0101fe4:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0101feb:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101fee:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0101ff4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ff7:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101ffd:	2b 18                	sub    (%eax),%ebx
f0101fff:	89 d8                	mov    %ebx,%eax
f0102001:	c1 f8 03             	sar    $0x3,%eax
f0102004:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102007:	89 c2                	mov    %eax,%edx
f0102009:	c1 ea 0c             	shr    $0xc,%edx
f010200c:	39 d1                	cmp    %edx,%ecx
f010200e:	0f 86 59 09 00 00    	jbe    f010296d <mem_init+0x1626>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102014:	83 ec 04             	sub    $0x4,%esp
f0102017:	68 00 10 00 00       	push   $0x1000
f010201c:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102021:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102026:	50                   	push   %eax
f0102027:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010202a:	e8 ca 1c 00 00       	call   f0103cf9 <memset>
	page_free(pp0);
f010202f:	83 c4 04             	add    $0x4,%esp
f0102032:	ff 75 d0             	pushl  -0x30(%ebp)
f0102035:	e8 33 f0 ff ff       	call   f010106d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010203a:	83 c4 0c             	add    $0xc,%esp
f010203d:	6a 01                	push   $0x1
f010203f:	6a 00                	push   $0x0
f0102041:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102044:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f010204a:	ff 30                	pushl  (%eax)
f010204c:	e8 94 f0 ff ff       	call   f01010e5 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102051:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102057:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010205a:	2b 10                	sub    (%eax),%edx
f010205c:	c1 fa 03             	sar    $0x3,%edx
f010205f:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102062:	89 d1                	mov    %edx,%ecx
f0102064:	c1 e9 0c             	shr    $0xc,%ecx
f0102067:	83 c4 10             	add    $0x10,%esp
f010206a:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0102070:	3b 08                	cmp    (%eax),%ecx
f0102072:	0f 83 0e 09 00 00    	jae    f0102986 <mem_init+0x163f>
	return (void *)(pa + KERNBASE);
f0102078:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010207e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102081:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102087:	f6 00 01             	testb  $0x1,(%eax)
f010208a:	0f 85 0f 09 00 00    	jne    f010299f <mem_init+0x1658>
f0102090:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102093:	39 d0                	cmp    %edx,%eax
f0102095:	75 f0                	jne    f0102087 <mem_init+0xd40>
	kern_pgdir[0] = 0;
f0102097:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010209a:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f01020a0:	8b 00                	mov    (%eax),%eax
f01020a2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020a8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020ab:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020b1:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01020b4:	89 93 90 1f 00 00    	mov    %edx,0x1f90(%ebx)

	// free the pages we took
	page_free(pp0);
f01020ba:	83 ec 0c             	sub    $0xc,%esp
f01020bd:	50                   	push   %eax
f01020be:	e8 aa ef ff ff       	call   f010106d <page_free>
	page_free(pp1);
f01020c3:	89 3c 24             	mov    %edi,(%esp)
f01020c6:	e8 a2 ef ff ff       	call   f010106d <page_free>
	page_free(pp2);
f01020cb:	89 34 24             	mov    %esi,(%esp)
f01020ce:	e8 9a ef ff ff       	call   f010106d <page_free>

	cprintf("check_page() succeeded!\n");
f01020d3:	8d 83 66 dd fe ff    	lea    -0x1229a(%ebx),%eax
f01020d9:	89 04 24             	mov    %eax,(%esp)
f01020dc:	e8 07 10 00 00       	call   f01030e8 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f01020e1:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f01020e7:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01020e9:	83 c4 10             	add    $0x10,%esp
f01020ec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020f1:	0f 86 ca 08 00 00    	jbe    f01029c1 <mem_init+0x167a>
f01020f7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020fa:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102100:	8b 0a                	mov    (%edx),%ecx
f0102102:	c1 e1 03             	shl    $0x3,%ecx
f0102105:	83 ec 08             	sub    $0x8,%esp
f0102108:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f010210a:	05 00 00 00 10       	add    $0x10000000,%eax
f010210f:	50                   	push   %eax
f0102110:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102115:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f010211b:	8b 00                	mov    (%eax),%eax
f010211d:	e8 6e f0 ff ff       	call   f0101190 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102122:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f0102128:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010212b:	83 c4 10             	add    $0x10,%esp
f010212e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102133:	0f 86 a4 08 00 00    	jbe    f01029dd <mem_init+0x1696>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102139:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010213c:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0102142:	83 ec 08             	sub    $0x8,%esp
f0102145:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f0102147:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010214a:	05 00 00 00 10       	add    $0x10000000,%eax
f010214f:	50                   	push   %eax
f0102150:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102155:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010215a:	8b 03                	mov    (%ebx),%eax
f010215c:	e8 2f f0 ff ff       	call   f0101190 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0x100000000 - KERNBASE, 0, PTE_W);
f0102161:	83 c4 08             	add    $0x8,%esp
f0102164:	6a 02                	push   $0x2
f0102166:	6a 00                	push   $0x0
f0102168:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010216d:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102172:	8b 03                	mov    (%ebx),%eax
f0102174:	e8 17 f0 ff ff       	call   f0101190 <boot_map_region>
	pgdir = kern_pgdir;
f0102179:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010217b:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0102181:	8b 00                	mov    (%eax),%eax
f0102183:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102186:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010218d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102192:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102195:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f010219b:	8b 00                	mov    (%eax),%eax
f010219d:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01021a0:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01021a3:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f01021a9:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f01021ac:	bf 00 00 00 00       	mov    $0x0,%edi
f01021b1:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f01021b4:	0f 86 84 08 00 00    	jbe    f0102a3e <mem_init+0x16f7>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ba:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f01021c0:	89 f0                	mov    %esi,%eax
f01021c2:	e8 2f e9 ff ff       	call   f0100af6 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01021c7:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01021ce:	0f 86 2a 08 00 00    	jbe    f01029fe <mem_init+0x16b7>
f01021d4:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f01021d7:	39 c2                	cmp    %eax,%edx
f01021d9:	0f 85 3d 08 00 00    	jne    f0102a1c <mem_init+0x16d5>
	for (i = 0; i < n; i += PGSIZE)
f01021df:	81 c7 00 10 00 00    	add    $0x1000,%edi
f01021e5:	eb ca                	jmp    f01021b1 <mem_init+0xe6a>
	assert(nfree == 0);
f01021e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021ea:	8d 83 8f dc fe ff    	lea    -0x12371(%ebx),%eax
f01021f0:	50                   	push   %eax
f01021f1:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01021f7:	50                   	push   %eax
f01021f8:	68 b2 02 00 00       	push   $0x2b2
f01021fd:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102203:	50                   	push   %eax
f0102204:	e8 90 de ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102209:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010220c:	8d 83 9d db fe ff    	lea    -0x12463(%ebx),%eax
f0102212:	50                   	push   %eax
f0102213:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102219:	50                   	push   %eax
f010221a:	68 0b 03 00 00       	push   $0x30b
f010221f:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102225:	50                   	push   %eax
f0102226:	e8 6e de ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010222b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010222e:	8d 83 b3 db fe ff    	lea    -0x1244d(%ebx),%eax
f0102234:	50                   	push   %eax
f0102235:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010223b:	50                   	push   %eax
f010223c:	68 0c 03 00 00       	push   $0x30c
f0102241:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102247:	50                   	push   %eax
f0102248:	e8 4c de ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010224d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102250:	8d 83 c9 db fe ff    	lea    -0x12437(%ebx),%eax
f0102256:	50                   	push   %eax
f0102257:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010225d:	50                   	push   %eax
f010225e:	68 0d 03 00 00       	push   $0x30d
f0102263:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102269:	50                   	push   %eax
f010226a:	e8 2a de ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010226f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102272:	8d 83 df db fe ff    	lea    -0x12421(%ebx),%eax
f0102278:	50                   	push   %eax
f0102279:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010227f:	50                   	push   %eax
f0102280:	68 10 03 00 00       	push   $0x310
f0102285:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010228b:	50                   	push   %eax
f010228c:	e8 08 de ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102291:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102294:	8d 83 e0 d4 fe ff    	lea    -0x12b20(%ebx),%eax
f010229a:	50                   	push   %eax
f010229b:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01022a1:	50                   	push   %eax
f01022a2:	68 11 03 00 00       	push   $0x311
f01022a7:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01022ad:	50                   	push   %eax
f01022ae:	e8 e6 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01022b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022b6:	8d 83 48 dc fe ff    	lea    -0x123b8(%ebx),%eax
f01022bc:	50                   	push   %eax
f01022bd:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01022c3:	50                   	push   %eax
f01022c4:	68 18 03 00 00       	push   $0x318
f01022c9:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01022cf:	50                   	push   %eax
f01022d0:	e8 c4 dd ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01022d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022d8:	8d 83 20 d5 fe ff    	lea    -0x12ae0(%ebx),%eax
f01022de:	50                   	push   %eax
f01022df:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01022e5:	50                   	push   %eax
f01022e6:	68 1b 03 00 00       	push   $0x31b
f01022eb:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01022f1:	50                   	push   %eax
f01022f2:	e8 a2 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01022f7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022fa:	8d 83 58 d5 fe ff    	lea    -0x12aa8(%ebx),%eax
f0102300:	50                   	push   %eax
f0102301:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102307:	50                   	push   %eax
f0102308:	68 1e 03 00 00       	push   $0x31e
f010230d:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102313:	50                   	push   %eax
f0102314:	e8 80 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102319:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010231c:	8d 83 88 d5 fe ff    	lea    -0x12a78(%ebx),%eax
f0102322:	50                   	push   %eax
f0102323:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102329:	50                   	push   %eax
f010232a:	68 22 03 00 00       	push   $0x322
f010232f:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102335:	50                   	push   %eax
f0102336:	e8 5e dd ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010233b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010233e:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f0102344:	50                   	push   %eax
f0102345:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010234b:	50                   	push   %eax
f010234c:	68 23 03 00 00       	push   $0x323
f0102351:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102357:	50                   	push   %eax
f0102358:	e8 3c dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010235d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102360:	8d 83 e0 d5 fe ff    	lea    -0x12a20(%ebx),%eax
f0102366:	50                   	push   %eax
f0102367:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010236d:	50                   	push   %eax
f010236e:	68 24 03 00 00       	push   $0x324
f0102373:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102379:	50                   	push   %eax
f010237a:	e8 1a dd ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f010237f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102382:	8d 83 9a dc fe ff    	lea    -0x12366(%ebx),%eax
f0102388:	50                   	push   %eax
f0102389:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010238f:	50                   	push   %eax
f0102390:	68 25 03 00 00       	push   $0x325
f0102395:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010239b:	50                   	push   %eax
f010239c:	e8 f8 dc ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01023a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023a4:	8d 83 ab dc fe ff    	lea    -0x12355(%ebx),%eax
f01023aa:	50                   	push   %eax
f01023ab:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01023b1:	50                   	push   %eax
f01023b2:	68 26 03 00 00       	push   $0x326
f01023b7:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01023bd:	50                   	push   %eax
f01023be:	e8 d6 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023c6:	8d 83 10 d6 fe ff    	lea    -0x129f0(%ebx),%eax
f01023cc:	50                   	push   %eax
f01023cd:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01023d3:	50                   	push   %eax
f01023d4:	68 29 03 00 00       	push   $0x329
f01023d9:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01023df:	50                   	push   %eax
f01023e0:	e8 b4 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023e5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023e8:	8d 83 4c d6 fe ff    	lea    -0x129b4(%ebx),%eax
f01023ee:	50                   	push   %eax
f01023ef:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01023f5:	50                   	push   %eax
f01023f6:	68 2a 03 00 00       	push   $0x32a
f01023fb:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102401:	50                   	push   %eax
f0102402:	e8 92 dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102407:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010240a:	8d 83 bc dc fe ff    	lea    -0x12344(%ebx),%eax
f0102410:	50                   	push   %eax
f0102411:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102417:	50                   	push   %eax
f0102418:	68 2b 03 00 00       	push   $0x32b
f010241d:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102423:	50                   	push   %eax
f0102424:	e8 70 dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102429:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010242c:	8d 83 48 dc fe ff    	lea    -0x123b8(%ebx),%eax
f0102432:	50                   	push   %eax
f0102433:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102439:	50                   	push   %eax
f010243a:	68 2e 03 00 00       	push   $0x32e
f010243f:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102445:	50                   	push   %eax
f0102446:	e8 4e dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010244b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010244e:	8d 83 10 d6 fe ff    	lea    -0x129f0(%ebx),%eax
f0102454:	50                   	push   %eax
f0102455:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010245b:	50                   	push   %eax
f010245c:	68 31 03 00 00       	push   $0x331
f0102461:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102467:	50                   	push   %eax
f0102468:	e8 2c dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010246d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102470:	8d 83 4c d6 fe ff    	lea    -0x129b4(%ebx),%eax
f0102476:	50                   	push   %eax
f0102477:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010247d:	50                   	push   %eax
f010247e:	68 32 03 00 00       	push   $0x332
f0102483:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102489:	50                   	push   %eax
f010248a:	e8 0a dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010248f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102492:	8d 83 bc dc fe ff    	lea    -0x12344(%ebx),%eax
f0102498:	50                   	push   %eax
f0102499:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010249f:	50                   	push   %eax
f01024a0:	68 33 03 00 00       	push   $0x333
f01024a5:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01024ab:	50                   	push   %eax
f01024ac:	e8 e8 db ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01024b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024b4:	8d 83 48 dc fe ff    	lea    -0x123b8(%ebx),%eax
f01024ba:	50                   	push   %eax
f01024bb:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01024c1:	50                   	push   %eax
f01024c2:	68 37 03 00 00       	push   $0x337
f01024c7:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01024cd:	50                   	push   %eax
f01024ce:	e8 c6 db ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024d3:	50                   	push   %eax
f01024d4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024d7:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01024dd:	50                   	push   %eax
f01024de:	68 3a 03 00 00       	push   $0x33a
f01024e3:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01024e9:	50                   	push   %eax
f01024ea:	e8 aa db ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01024ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024f2:	8d 83 7c d6 fe ff    	lea    -0x12984(%ebx),%eax
f01024f8:	50                   	push   %eax
f01024f9:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01024ff:	50                   	push   %eax
f0102500:	68 3b 03 00 00       	push   $0x33b
f0102505:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010250b:	50                   	push   %eax
f010250c:	e8 88 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102511:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102514:	8d 83 bc d6 fe ff    	lea    -0x12944(%ebx),%eax
f010251a:	50                   	push   %eax
f010251b:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102521:	50                   	push   %eax
f0102522:	68 3e 03 00 00       	push   $0x33e
f0102527:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010252d:	50                   	push   %eax
f010252e:	e8 66 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102533:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102536:	8d 83 4c d6 fe ff    	lea    -0x129b4(%ebx),%eax
f010253c:	50                   	push   %eax
f010253d:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102543:	50                   	push   %eax
f0102544:	68 3f 03 00 00       	push   $0x33f
f0102549:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010254f:	50                   	push   %eax
f0102550:	e8 44 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102555:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102558:	8d 83 bc dc fe ff    	lea    -0x12344(%ebx),%eax
f010255e:	50                   	push   %eax
f010255f:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102565:	50                   	push   %eax
f0102566:	68 40 03 00 00       	push   $0x340
f010256b:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102571:	50                   	push   %eax
f0102572:	e8 22 db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102577:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010257a:	8d 83 fc d6 fe ff    	lea    -0x12904(%ebx),%eax
f0102580:	50                   	push   %eax
f0102581:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102587:	50                   	push   %eax
f0102588:	68 41 03 00 00       	push   $0x341
f010258d:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102593:	50                   	push   %eax
f0102594:	e8 00 db ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102599:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010259c:	8d 83 cd dc fe ff    	lea    -0x12333(%ebx),%eax
f01025a2:	50                   	push   %eax
f01025a3:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01025a9:	50                   	push   %eax
f01025aa:	68 42 03 00 00       	push   $0x342
f01025af:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01025b5:	50                   	push   %eax
f01025b6:	e8 de da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01025bb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025be:	8d 83 10 d6 fe ff    	lea    -0x129f0(%ebx),%eax
f01025c4:	50                   	push   %eax
f01025c5:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01025cb:	50                   	push   %eax
f01025cc:	68 45 03 00 00       	push   $0x345
f01025d1:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01025d7:	50                   	push   %eax
f01025d8:	e8 bc da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01025dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025e0:	8d 83 30 d7 fe ff    	lea    -0x128d0(%ebx),%eax
f01025e6:	50                   	push   %eax
f01025e7:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01025ed:	50                   	push   %eax
f01025ee:	68 46 03 00 00       	push   $0x346
f01025f3:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01025f9:	50                   	push   %eax
f01025fa:	e8 9a da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01025ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102602:	8d 83 64 d7 fe ff    	lea    -0x1289c(%ebx),%eax
f0102608:	50                   	push   %eax
f0102609:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010260f:	50                   	push   %eax
f0102610:	68 47 03 00 00       	push   $0x347
f0102615:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010261b:	50                   	push   %eax
f010261c:	e8 78 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102621:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102624:	8d 83 9c d7 fe ff    	lea    -0x12864(%ebx),%eax
f010262a:	50                   	push   %eax
f010262b:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102631:	50                   	push   %eax
f0102632:	68 4a 03 00 00       	push   $0x34a
f0102637:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010263d:	50                   	push   %eax
f010263e:	e8 56 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102643:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102646:	8d 83 d4 d7 fe ff    	lea    -0x1282c(%ebx),%eax
f010264c:	50                   	push   %eax
f010264d:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102653:	50                   	push   %eax
f0102654:	68 4d 03 00 00       	push   $0x34d
f0102659:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010265f:	50                   	push   %eax
f0102660:	e8 34 da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102665:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102668:	8d 83 64 d7 fe ff    	lea    -0x1289c(%ebx),%eax
f010266e:	50                   	push   %eax
f010266f:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102675:	50                   	push   %eax
f0102676:	68 4e 03 00 00       	push   $0x34e
f010267b:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102681:	50                   	push   %eax
f0102682:	e8 12 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102687:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010268a:	8d 83 10 d8 fe ff    	lea    -0x127f0(%ebx),%eax
f0102690:	50                   	push   %eax
f0102691:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102697:	50                   	push   %eax
f0102698:	68 51 03 00 00       	push   $0x351
f010269d:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01026a3:	50                   	push   %eax
f01026a4:	e8 f0 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026a9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026ac:	8d 83 3c d8 fe ff    	lea    -0x127c4(%ebx),%eax
f01026b2:	50                   	push   %eax
f01026b3:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01026b9:	50                   	push   %eax
f01026ba:	68 52 03 00 00       	push   $0x352
f01026bf:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01026c5:	50                   	push   %eax
f01026c6:	e8 ce d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f01026cb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026ce:	8d 83 e3 dc fe ff    	lea    -0x1231d(%ebx),%eax
f01026d4:	50                   	push   %eax
f01026d5:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01026db:	50                   	push   %eax
f01026dc:	68 54 03 00 00       	push   $0x354
f01026e1:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01026e7:	50                   	push   %eax
f01026e8:	e8 ac d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01026ed:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026f0:	8d 83 f4 dc fe ff    	lea    -0x1230c(%ebx),%eax
f01026f6:	50                   	push   %eax
f01026f7:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01026fd:	50                   	push   %eax
f01026fe:	68 55 03 00 00       	push   $0x355
f0102703:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102709:	50                   	push   %eax
f010270a:	e8 8a d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f010270f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102712:	8d 83 6c d8 fe ff    	lea    -0x12794(%ebx),%eax
f0102718:	50                   	push   %eax
f0102719:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010271f:	50                   	push   %eax
f0102720:	68 58 03 00 00       	push   $0x358
f0102725:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010272b:	50                   	push   %eax
f010272c:	e8 68 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102731:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102734:	8d 83 90 d8 fe ff    	lea    -0x12770(%ebx),%eax
f010273a:	50                   	push   %eax
f010273b:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102741:	50                   	push   %eax
f0102742:	68 5c 03 00 00       	push   $0x35c
f0102747:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010274d:	50                   	push   %eax
f010274e:	e8 46 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102753:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102756:	8d 83 3c d8 fe ff    	lea    -0x127c4(%ebx),%eax
f010275c:	50                   	push   %eax
f010275d:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102763:	50                   	push   %eax
f0102764:	68 5d 03 00 00       	push   $0x35d
f0102769:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010276f:	50                   	push   %eax
f0102770:	e8 24 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102775:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102778:	8d 83 9a dc fe ff    	lea    -0x12366(%ebx),%eax
f010277e:	50                   	push   %eax
f010277f:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102785:	50                   	push   %eax
f0102786:	68 5e 03 00 00       	push   $0x35e
f010278b:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102791:	50                   	push   %eax
f0102792:	e8 02 d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102797:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010279a:	8d 83 f4 dc fe ff    	lea    -0x1230c(%ebx),%eax
f01027a0:	50                   	push   %eax
f01027a1:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01027a7:	50                   	push   %eax
f01027a8:	68 5f 03 00 00       	push   $0x35f
f01027ad:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01027b3:	50                   	push   %eax
f01027b4:	e8 e0 d8 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01027b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027bc:	8d 83 b4 d8 fe ff    	lea    -0x1274c(%ebx),%eax
f01027c2:	50                   	push   %eax
f01027c3:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01027c9:	50                   	push   %eax
f01027ca:	68 62 03 00 00       	push   $0x362
f01027cf:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01027d5:	50                   	push   %eax
f01027d6:	e8 be d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f01027db:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027de:	8d 83 05 dd fe ff    	lea    -0x122fb(%ebx),%eax
f01027e4:	50                   	push   %eax
f01027e5:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01027eb:	50                   	push   %eax
f01027ec:	68 63 03 00 00       	push   $0x363
f01027f1:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01027f7:	50                   	push   %eax
f01027f8:	e8 9c d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f01027fd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102800:	8d 83 11 dd fe ff    	lea    -0x122ef(%ebx),%eax
f0102806:	50                   	push   %eax
f0102807:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010280d:	50                   	push   %eax
f010280e:	68 64 03 00 00       	push   $0x364
f0102813:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102819:	50                   	push   %eax
f010281a:	e8 7a d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010281f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102822:	8d 83 90 d8 fe ff    	lea    -0x12770(%ebx),%eax
f0102828:	50                   	push   %eax
f0102829:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010282f:	50                   	push   %eax
f0102830:	68 68 03 00 00       	push   $0x368
f0102835:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010283b:	50                   	push   %eax
f010283c:	e8 58 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102841:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102844:	8d 83 ec d8 fe ff    	lea    -0x12714(%ebx),%eax
f010284a:	50                   	push   %eax
f010284b:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102851:	50                   	push   %eax
f0102852:	68 69 03 00 00       	push   $0x369
f0102857:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010285d:	50                   	push   %eax
f010285e:	e8 36 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102863:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102866:	8d 83 26 dd fe ff    	lea    -0x122da(%ebx),%eax
f010286c:	50                   	push   %eax
f010286d:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102873:	50                   	push   %eax
f0102874:	68 6a 03 00 00       	push   $0x36a
f0102879:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010287f:	50                   	push   %eax
f0102880:	e8 14 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102885:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102888:	8d 83 f4 dc fe ff    	lea    -0x1230c(%ebx),%eax
f010288e:	50                   	push   %eax
f010288f:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102895:	50                   	push   %eax
f0102896:	68 6b 03 00 00       	push   $0x36b
f010289b:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01028a1:	50                   	push   %eax
f01028a2:	e8 f2 d7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01028a7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028aa:	8d 83 14 d9 fe ff    	lea    -0x126ec(%ebx),%eax
f01028b0:	50                   	push   %eax
f01028b1:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01028b7:	50                   	push   %eax
f01028b8:	68 6e 03 00 00       	push   $0x36e
f01028bd:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01028c3:	50                   	push   %eax
f01028c4:	e8 d0 d7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01028c9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028cc:	8d 83 48 dc fe ff    	lea    -0x123b8(%ebx),%eax
f01028d2:	50                   	push   %eax
f01028d3:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01028d9:	50                   	push   %eax
f01028da:	68 71 03 00 00       	push   $0x371
f01028df:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01028e5:	50                   	push   %eax
f01028e6:	e8 ae d7 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01028eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028ee:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f01028f4:	50                   	push   %eax
f01028f5:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01028fb:	50                   	push   %eax
f01028fc:	68 74 03 00 00       	push   $0x374
f0102901:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102907:	50                   	push   %eax
f0102908:	e8 8c d7 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f010290d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102910:	8d 83 ab dc fe ff    	lea    -0x12355(%ebx),%eax
f0102916:	50                   	push   %eax
f0102917:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010291d:	50                   	push   %eax
f010291e:	68 76 03 00 00       	push   $0x376
f0102923:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102929:	50                   	push   %eax
f010292a:	e8 6a d7 ff ff       	call   f0100099 <_panic>
f010292f:	52                   	push   %edx
f0102930:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102933:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102939:	50                   	push   %eax
f010293a:	68 7d 03 00 00       	push   $0x37d
f010293f:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102945:	50                   	push   %eax
f0102946:	e8 4e d7 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010294b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010294e:	8d 83 37 dd fe ff    	lea    -0x122c9(%ebx),%eax
f0102954:	50                   	push   %eax
f0102955:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f010295b:	50                   	push   %eax
f010295c:	68 7e 03 00 00       	push   $0x37e
f0102961:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102967:	50                   	push   %eax
f0102968:	e8 2c d7 ff ff       	call   f0100099 <_panic>
f010296d:	50                   	push   %eax
f010296e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102971:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102977:	50                   	push   %eax
f0102978:	6a 59                	push   $0x59
f010297a:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0102980:	50                   	push   %eax
f0102981:	e8 13 d7 ff ff       	call   f0100099 <_panic>
f0102986:	52                   	push   %edx
f0102987:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010298a:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102990:	50                   	push   %eax
f0102991:	6a 59                	push   $0x59
f0102993:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0102999:	50                   	push   %eax
f010299a:	e8 fa d6 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f010299f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029a2:	8d 83 4f dd fe ff    	lea    -0x122b1(%ebx),%eax
f01029a8:	50                   	push   %eax
f01029a9:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f01029af:	50                   	push   %eax
f01029b0:	68 88 03 00 00       	push   $0x388
f01029b5:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01029bb:	50                   	push   %eax
f01029bc:	e8 d8 d6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029c1:	50                   	push   %eax
f01029c2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029c5:	8d 83 1c d4 fe ff    	lea    -0x12be4(%ebx),%eax
f01029cb:	50                   	push   %eax
f01029cc:	68 c0 00 00 00       	push   $0xc0
f01029d1:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01029d7:	50                   	push   %eax
f01029d8:	e8 bc d6 ff ff       	call   f0100099 <_panic>
f01029dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029e0:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f01029e6:	8d 83 1c d4 fe ff    	lea    -0x12be4(%ebx),%eax
f01029ec:	50                   	push   %eax
f01029ed:	68 cd 00 00 00       	push   $0xcd
f01029f2:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f01029f8:	50                   	push   %eax
f01029f9:	e8 9b d6 ff ff       	call   f0100099 <_panic>
f01029fe:	ff 75 c0             	pushl  -0x40(%ebp)
f0102a01:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a04:	8d 83 1c d4 fe ff    	lea    -0x12be4(%ebx),%eax
f0102a0a:	50                   	push   %eax
f0102a0b:	68 ca 02 00 00       	push   $0x2ca
f0102a10:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102a16:	50                   	push   %eax
f0102a17:	e8 7d d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a1c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a1f:	8d 83 38 d9 fe ff    	lea    -0x126c8(%ebx),%eax
f0102a25:	50                   	push   %eax
f0102a26:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102a2c:	50                   	push   %eax
f0102a2d:	68 ca 02 00 00       	push   $0x2ca
f0102a32:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102a38:	50                   	push   %eax
f0102a39:	e8 5b d6 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a3e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102a41:	c1 e7 0c             	shl    $0xc,%edi
f0102a44:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a49:	eb 17                	jmp    f0102a62 <mem_init+0x171b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a4b:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102a51:	89 f0                	mov    %esi,%eax
f0102a53:	e8 9e e0 ff ff       	call   f0100af6 <check_va2pa>
f0102a58:	39 c3                	cmp    %eax,%ebx
f0102a5a:	75 51                	jne    f0102aad <mem_init+0x1766>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a5c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a62:	39 fb                	cmp    %edi,%ebx
f0102a64:	72 e5                	jb     f0102a4b <mem_init+0x1704>
f0102a66:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a6b:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102a6e:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102a74:	89 da                	mov    %ebx,%edx
f0102a76:	89 f0                	mov    %esi,%eax
f0102a78:	e8 79 e0 ff ff       	call   f0100af6 <check_va2pa>
f0102a7d:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102a80:	39 c2                	cmp    %eax,%edx
f0102a82:	75 4b                	jne    f0102acf <mem_init+0x1788>
f0102a84:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a8a:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102a90:	75 e2                	jne    f0102a74 <mem_init+0x172d>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a92:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102a97:	89 f0                	mov    %esi,%eax
f0102a99:	e8 58 e0 ff ff       	call   f0100af6 <check_va2pa>
f0102a9e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102aa1:	75 4e                	jne    f0102af1 <mem_init+0x17aa>
	for (i = 0; i < NPDENTRIES; i++) {
f0102aa3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aa8:	e9 8f 00 00 00       	jmp    f0102b3c <mem_init+0x17f5>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102aad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ab0:	8d 83 6c d9 fe ff    	lea    -0x12694(%ebx),%eax
f0102ab6:	50                   	push   %eax
f0102ab7:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102abd:	50                   	push   %eax
f0102abe:	68 cf 02 00 00       	push   $0x2cf
f0102ac3:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102ac9:	50                   	push   %eax
f0102aca:	e8 ca d5 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102acf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ad2:	8d 83 94 d9 fe ff    	lea    -0x1266c(%ebx),%eax
f0102ad8:	50                   	push   %eax
f0102ad9:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102adf:	50                   	push   %eax
f0102ae0:	68 d3 02 00 00       	push   $0x2d3
f0102ae5:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102aeb:	50                   	push   %eax
f0102aec:	e8 a8 d5 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102af1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102af4:	8d 83 dc d9 fe ff    	lea    -0x12624(%ebx),%eax
f0102afa:	50                   	push   %eax
f0102afb:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102b01:	50                   	push   %eax
f0102b02:	68 d4 02 00 00       	push   $0x2d4
f0102b07:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102b0d:	50                   	push   %eax
f0102b0e:	e8 86 d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b13:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102b17:	74 52                	je     f0102b6b <mem_init+0x1824>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b19:	83 c0 01             	add    $0x1,%eax
f0102b1c:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102b21:	0f 87 bb 00 00 00    	ja     f0102be2 <mem_init+0x189b>
		switch (i) {
f0102b27:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102b2c:	72 0e                	jb     f0102b3c <mem_init+0x17f5>
f0102b2e:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102b33:	76 de                	jbe    f0102b13 <mem_init+0x17cc>
f0102b35:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b3a:	74 d7                	je     f0102b13 <mem_init+0x17cc>
			if (i >= PDX(KERNBASE)) {
f0102b3c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b41:	77 4a                	ja     f0102b8d <mem_init+0x1846>
				assert(pgdir[i] == 0);
f0102b43:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102b47:	74 d0                	je     f0102b19 <mem_init+0x17d2>
f0102b49:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b4c:	8d 83 a1 dd fe ff    	lea    -0x1225f(%ebx),%eax
f0102b52:	50                   	push   %eax
f0102b53:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102b59:	50                   	push   %eax
f0102b5a:	68 e3 02 00 00       	push   $0x2e3
f0102b5f:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102b65:	50                   	push   %eax
f0102b66:	e8 2e d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b6b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b6e:	8d 83 7f dd fe ff    	lea    -0x12281(%ebx),%eax
f0102b74:	50                   	push   %eax
f0102b75:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102b7b:	50                   	push   %eax
f0102b7c:	68 dc 02 00 00       	push   $0x2dc
f0102b81:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102b87:	50                   	push   %eax
f0102b88:	e8 0c d5 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b8d:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102b90:	f6 c2 01             	test   $0x1,%dl
f0102b93:	74 2b                	je     f0102bc0 <mem_init+0x1879>
				assert(pgdir[i] & PTE_W);
f0102b95:	f6 c2 02             	test   $0x2,%dl
f0102b98:	0f 85 7b ff ff ff    	jne    f0102b19 <mem_init+0x17d2>
f0102b9e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ba1:	8d 83 90 dd fe ff    	lea    -0x12270(%ebx),%eax
f0102ba7:	50                   	push   %eax
f0102ba8:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102bae:	50                   	push   %eax
f0102baf:	68 e1 02 00 00       	push   $0x2e1
f0102bb4:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102bba:	50                   	push   %eax
f0102bbb:	e8 d9 d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bc0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bc3:	8d 83 7f dd fe ff    	lea    -0x12281(%ebx),%eax
f0102bc9:	50                   	push   %eax
f0102bca:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102bd0:	50                   	push   %eax
f0102bd1:	68 e0 02 00 00       	push   $0x2e0
f0102bd6:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102bdc:	50                   	push   %eax
f0102bdd:	e8 b7 d4 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102be2:	83 ec 0c             	sub    $0xc,%esp
f0102be5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102be8:	8d 87 0c da fe ff    	lea    -0x125f4(%edi),%eax
f0102bee:	50                   	push   %eax
f0102bef:	89 fb                	mov    %edi,%ebx
f0102bf1:	e8 f2 04 00 00       	call   f01030e8 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102bf6:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102bfc:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102bfe:	83 c4 10             	add    $0x10,%esp
f0102c01:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c06:	0f 86 44 02 00 00    	jbe    f0102e50 <mem_init+0x1b09>
	return (physaddr_t)kva - KERNBASE;
f0102c0c:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c11:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c14:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c19:	e8 55 df ff ff       	call   f0100b73 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c1e:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c21:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c24:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c29:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c2c:	83 ec 0c             	sub    $0xc,%esp
f0102c2f:	6a 00                	push   $0x0
f0102c31:	e8 af e3 ff ff       	call   f0100fe5 <page_alloc>
f0102c36:	89 c6                	mov    %eax,%esi
f0102c38:	83 c4 10             	add    $0x10,%esp
f0102c3b:	85 c0                	test   %eax,%eax
f0102c3d:	0f 84 29 02 00 00    	je     f0102e6c <mem_init+0x1b25>
	assert((pp1 = page_alloc(0)));
f0102c43:	83 ec 0c             	sub    $0xc,%esp
f0102c46:	6a 00                	push   $0x0
f0102c48:	e8 98 e3 ff ff       	call   f0100fe5 <page_alloc>
f0102c4d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c50:	83 c4 10             	add    $0x10,%esp
f0102c53:	85 c0                	test   %eax,%eax
f0102c55:	0f 84 33 02 00 00    	je     f0102e8e <mem_init+0x1b47>
	assert((pp2 = page_alloc(0)));
f0102c5b:	83 ec 0c             	sub    $0xc,%esp
f0102c5e:	6a 00                	push   $0x0
f0102c60:	e8 80 e3 ff ff       	call   f0100fe5 <page_alloc>
f0102c65:	89 c7                	mov    %eax,%edi
f0102c67:	83 c4 10             	add    $0x10,%esp
f0102c6a:	85 c0                	test   %eax,%eax
f0102c6c:	0f 84 3e 02 00 00    	je     f0102eb0 <mem_init+0x1b69>
	page_free(pp0);
f0102c72:	83 ec 0c             	sub    $0xc,%esp
f0102c75:	56                   	push   %esi
f0102c76:	e8 f2 e3 ff ff       	call   f010106d <page_free>
	return (pp - pages) << PGSHIFT;
f0102c7b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c7e:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102c84:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102c87:	2b 08                	sub    (%eax),%ecx
f0102c89:	89 c8                	mov    %ecx,%eax
f0102c8b:	c1 f8 03             	sar    $0x3,%eax
f0102c8e:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102c91:	89 c1                	mov    %eax,%ecx
f0102c93:	c1 e9 0c             	shr    $0xc,%ecx
f0102c96:	83 c4 10             	add    $0x10,%esp
f0102c99:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102c9f:	3b 0a                	cmp    (%edx),%ecx
f0102ca1:	0f 83 2b 02 00 00    	jae    f0102ed2 <mem_init+0x1b8b>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ca7:	83 ec 04             	sub    $0x4,%esp
f0102caa:	68 00 10 00 00       	push   $0x1000
f0102caf:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102cb1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102cb6:	50                   	push   %eax
f0102cb7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cba:	e8 3a 10 00 00       	call   f0103cf9 <memset>
	return (pp - pages) << PGSHIFT;
f0102cbf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cc2:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102cc8:	89 f9                	mov    %edi,%ecx
f0102cca:	2b 08                	sub    (%eax),%ecx
f0102ccc:	89 c8                	mov    %ecx,%eax
f0102cce:	c1 f8 03             	sar    $0x3,%eax
f0102cd1:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102cd4:	89 c1                	mov    %eax,%ecx
f0102cd6:	c1 e9 0c             	shr    $0xc,%ecx
f0102cd9:	83 c4 10             	add    $0x10,%esp
f0102cdc:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102ce2:	3b 0a                	cmp    (%edx),%ecx
f0102ce4:	0f 83 fe 01 00 00    	jae    f0102ee8 <mem_init+0x1ba1>
	memset(page2kva(pp2), 2, PGSIZE);
f0102cea:	83 ec 04             	sub    $0x4,%esp
f0102ced:	68 00 10 00 00       	push   $0x1000
f0102cf2:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102cf4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102cf9:	50                   	push   %eax
f0102cfa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cfd:	e8 f7 0f 00 00       	call   f0103cf9 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d02:	6a 02                	push   $0x2
f0102d04:	68 00 10 00 00       	push   $0x1000
f0102d09:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102d0c:	53                   	push   %ebx
f0102d0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d10:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102d16:	ff 30                	pushl  (%eax)
f0102d18:	e8 ac e5 ff ff       	call   f01012c9 <page_insert>
	assert(pp1->pp_ref == 1);
f0102d1d:	83 c4 20             	add    $0x20,%esp
f0102d20:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d25:	0f 85 d3 01 00 00    	jne    f0102efe <mem_init+0x1bb7>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d2b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d32:	01 01 01 
f0102d35:	0f 85 e5 01 00 00    	jne    f0102f20 <mem_init+0x1bd9>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d3b:	6a 02                	push   $0x2
f0102d3d:	68 00 10 00 00       	push   $0x1000
f0102d42:	57                   	push   %edi
f0102d43:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d46:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102d4c:	ff 30                	pushl  (%eax)
f0102d4e:	e8 76 e5 ff ff       	call   f01012c9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d53:	83 c4 10             	add    $0x10,%esp
f0102d56:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d5d:	02 02 02 
f0102d60:	0f 85 dc 01 00 00    	jne    f0102f42 <mem_init+0x1bfb>
	assert(pp2->pp_ref == 1);
f0102d66:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d6b:	0f 85 f3 01 00 00    	jne    f0102f64 <mem_init+0x1c1d>
	assert(pp1->pp_ref == 0);
f0102d71:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d74:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102d79:	0f 85 07 02 00 00    	jne    f0102f86 <mem_init+0x1c3f>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d7f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d86:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d89:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d8c:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102d92:	89 f9                	mov    %edi,%ecx
f0102d94:	2b 08                	sub    (%eax),%ecx
f0102d96:	89 c8                	mov    %ecx,%eax
f0102d98:	c1 f8 03             	sar    $0x3,%eax
f0102d9b:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d9e:	89 c1                	mov    %eax,%ecx
f0102da0:	c1 e9 0c             	shr    $0xc,%ecx
f0102da3:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102da9:	3b 0a                	cmp    (%edx),%ecx
f0102dab:	0f 83 f7 01 00 00    	jae    f0102fa8 <mem_init+0x1c61>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102db1:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102db8:	03 03 03 
f0102dbb:	0f 85 fd 01 00 00    	jne    f0102fbe <mem_init+0x1c77>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102dc1:	83 ec 08             	sub    $0x8,%esp
f0102dc4:	68 00 10 00 00       	push   $0x1000
f0102dc9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102dcc:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102dd2:	ff 30                	pushl  (%eax)
f0102dd4:	e8 b3 e4 ff ff       	call   f010128c <page_remove>
	assert(pp2->pp_ref == 0);
f0102dd9:	83 c4 10             	add    $0x10,%esp
f0102ddc:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102de1:	0f 85 f9 01 00 00    	jne    f0102fe0 <mem_init+0x1c99>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102de7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102dea:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102df0:	8b 08                	mov    (%eax),%ecx
f0102df2:	8b 11                	mov    (%ecx),%edx
f0102df4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102dfa:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102e00:	89 f7                	mov    %esi,%edi
f0102e02:	2b 38                	sub    (%eax),%edi
f0102e04:	89 f8                	mov    %edi,%eax
f0102e06:	c1 f8 03             	sar    $0x3,%eax
f0102e09:	c1 e0 0c             	shl    $0xc,%eax
f0102e0c:	39 c2                	cmp    %eax,%edx
f0102e0e:	0f 85 ee 01 00 00    	jne    f0103002 <mem_init+0x1cbb>
	kern_pgdir[0] = 0;
f0102e14:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e1a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e1f:	0f 85 ff 01 00 00    	jne    f0103024 <mem_init+0x1cdd>
	pp0->pp_ref = 0;
f0102e25:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e2b:	83 ec 0c             	sub    $0xc,%esp
f0102e2e:	56                   	push   %esi
f0102e2f:	e8 39 e2 ff ff       	call   f010106d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e34:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e37:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102e3d:	89 04 24             	mov    %eax,(%esp)
f0102e40:	e8 a3 02 00 00       	call   f01030e8 <cprintf>
}
f0102e45:	83 c4 10             	add    $0x10,%esp
f0102e48:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e4b:	5b                   	pop    %ebx
f0102e4c:	5e                   	pop    %esi
f0102e4d:	5f                   	pop    %edi
f0102e4e:	5d                   	pop    %ebp
f0102e4f:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e50:	50                   	push   %eax
f0102e51:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e54:	8d 83 1c d4 fe ff    	lea    -0x12be4(%ebx),%eax
f0102e5a:	50                   	push   %eax
f0102e5b:	68 e1 00 00 00       	push   $0xe1
f0102e60:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102e66:	50                   	push   %eax
f0102e67:	e8 2d d2 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102e6c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e6f:	8d 83 9d db fe ff    	lea    -0x12463(%ebx),%eax
f0102e75:	50                   	push   %eax
f0102e76:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102e7c:	50                   	push   %eax
f0102e7d:	68 a3 03 00 00       	push   $0x3a3
f0102e82:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102e88:	50                   	push   %eax
f0102e89:	e8 0b d2 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e8e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e91:	8d 83 b3 db fe ff    	lea    -0x1244d(%ebx),%eax
f0102e97:	50                   	push   %eax
f0102e98:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102e9e:	50                   	push   %eax
f0102e9f:	68 a4 03 00 00       	push   $0x3a4
f0102ea4:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102eaa:	50                   	push   %eax
f0102eab:	e8 e9 d1 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102eb0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eb3:	8d 83 c9 db fe ff    	lea    -0x12437(%ebx),%eax
f0102eb9:	50                   	push   %eax
f0102eba:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102ec0:	50                   	push   %eax
f0102ec1:	68 a5 03 00 00       	push   $0x3a5
f0102ec6:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102ecc:	50                   	push   %eax
f0102ecd:	e8 c7 d1 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ed2:	50                   	push   %eax
f0102ed3:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102ed9:	50                   	push   %eax
f0102eda:	6a 59                	push   $0x59
f0102edc:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0102ee2:	50                   	push   %eax
f0102ee3:	e8 b1 d1 ff ff       	call   f0100099 <_panic>
f0102ee8:	50                   	push   %eax
f0102ee9:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102eef:	50                   	push   %eax
f0102ef0:	6a 59                	push   $0x59
f0102ef2:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0102ef8:	50                   	push   %eax
f0102ef9:	e8 9b d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102efe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f01:	8d 83 9a dc fe ff    	lea    -0x12366(%ebx),%eax
f0102f07:	50                   	push   %eax
f0102f08:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102f0e:	50                   	push   %eax
f0102f0f:	68 aa 03 00 00       	push   $0x3aa
f0102f14:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102f1a:	50                   	push   %eax
f0102f1b:	e8 79 d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f20:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f23:	8d 83 2c da fe ff    	lea    -0x125d4(%ebx),%eax
f0102f29:	50                   	push   %eax
f0102f2a:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102f30:	50                   	push   %eax
f0102f31:	68 ab 03 00 00       	push   $0x3ab
f0102f36:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102f3c:	50                   	push   %eax
f0102f3d:	e8 57 d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f42:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f45:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f0102f4b:	50                   	push   %eax
f0102f4c:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102f52:	50                   	push   %eax
f0102f53:	68 ad 03 00 00       	push   $0x3ad
f0102f58:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102f5e:	50                   	push   %eax
f0102f5f:	e8 35 d1 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102f64:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f67:	8d 83 bc dc fe ff    	lea    -0x12344(%ebx),%eax
f0102f6d:	50                   	push   %eax
f0102f6e:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102f74:	50                   	push   %eax
f0102f75:	68 ae 03 00 00       	push   $0x3ae
f0102f7a:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102f80:	50                   	push   %eax
f0102f81:	e8 13 d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102f86:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f89:	8d 83 26 dd fe ff    	lea    -0x122da(%ebx),%eax
f0102f8f:	50                   	push   %eax
f0102f90:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102f96:	50                   	push   %eax
f0102f97:	68 af 03 00 00       	push   $0x3af
f0102f9c:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102fa2:	50                   	push   %eax
f0102fa3:	e8 f1 d0 ff ff       	call   f0100099 <_panic>
f0102fa8:	50                   	push   %eax
f0102fa9:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102faf:	50                   	push   %eax
f0102fb0:	6a 59                	push   $0x59
f0102fb2:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0102fb8:	50                   	push   %eax
f0102fb9:	e8 db d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102fbe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fc1:	8d 83 74 da fe ff    	lea    -0x1258c(%ebx),%eax
f0102fc7:	50                   	push   %eax
f0102fc8:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102fce:	50                   	push   %eax
f0102fcf:	68 b1 03 00 00       	push   $0x3b1
f0102fd4:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102fda:	50                   	push   %eax
f0102fdb:	e8 b9 d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102fe0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fe3:	8d 83 f4 dc fe ff    	lea    -0x1230c(%ebx),%eax
f0102fe9:	50                   	push   %eax
f0102fea:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0102ff0:	50                   	push   %eax
f0102ff1:	68 b3 03 00 00       	push   $0x3b3
f0102ff6:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0102ffc:	50                   	push   %eax
f0102ffd:	e8 97 d0 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103002:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103005:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f010300b:	50                   	push   %eax
f010300c:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0103012:	50                   	push   %eax
f0103013:	68 b6 03 00 00       	push   $0x3b6
f0103018:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010301e:	50                   	push   %eax
f010301f:	e8 75 d0 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0103024:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103027:	8d 83 ab dc fe ff    	lea    -0x12355(%ebx),%eax
f010302d:	50                   	push   %eax
f010302e:	8d 83 f2 da fe ff    	lea    -0x1250e(%ebx),%eax
f0103034:	50                   	push   %eax
f0103035:	68 b8 03 00 00       	push   $0x3b8
f010303a:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f0103040:	50                   	push   %eax
f0103041:	e8 53 d0 ff ff       	call   f0100099 <_panic>

f0103046 <tlb_invalidate>:
{
f0103046:	55                   	push   %ebp
f0103047:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103049:	8b 45 0c             	mov    0xc(%ebp),%eax
f010304c:	0f 01 38             	invlpg (%eax)
}
f010304f:	5d                   	pop    %ebp
f0103050:	c3                   	ret    

f0103051 <__x86.get_pc_thunk.dx>:
f0103051:	8b 14 24             	mov    (%esp),%edx
f0103054:	c3                   	ret    

f0103055 <__x86.get_pc_thunk.cx>:
f0103055:	8b 0c 24             	mov    (%esp),%ecx
f0103058:	c3                   	ret    

f0103059 <__x86.get_pc_thunk.si>:
f0103059:	8b 34 24             	mov    (%esp),%esi
f010305c:	c3                   	ret    

f010305d <__x86.get_pc_thunk.di>:
f010305d:	8b 3c 24             	mov    (%esp),%edi
f0103060:	c3                   	ret    

f0103061 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103061:	55                   	push   %ebp
f0103062:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103064:	8b 45 08             	mov    0x8(%ebp),%eax
f0103067:	ba 70 00 00 00       	mov    $0x70,%edx
f010306c:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010306d:	ba 71 00 00 00       	mov    $0x71,%edx
f0103072:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103073:	0f b6 c0             	movzbl %al,%eax
}
f0103076:	5d                   	pop    %ebp
f0103077:	c3                   	ret    

f0103078 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103078:	55                   	push   %ebp
f0103079:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010307b:	8b 45 08             	mov    0x8(%ebp),%eax
f010307e:	ba 70 00 00 00       	mov    $0x70,%edx
f0103083:	ee                   	out    %al,(%dx)
f0103084:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103087:	ba 71 00 00 00       	mov    $0x71,%edx
f010308c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010308d:	5d                   	pop    %ebp
f010308e:	c3                   	ret    

f010308f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010308f:	55                   	push   %ebp
f0103090:	89 e5                	mov    %esp,%ebp
f0103092:	53                   	push   %ebx
f0103093:	83 ec 10             	sub    $0x10,%esp
f0103096:	e8 b4 d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010309b:	81 c3 71 42 01 00    	add    $0x14271,%ebx
	cputchar(ch);
f01030a1:	ff 75 08             	pushl  0x8(%ebp)
f01030a4:	e8 1d d6 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f01030a9:	83 c4 10             	add    $0x10,%esp
f01030ac:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030af:	c9                   	leave  
f01030b0:	c3                   	ret    

f01030b1 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01030b1:	55                   	push   %ebp
f01030b2:	89 e5                	mov    %esp,%ebp
f01030b4:	53                   	push   %ebx
f01030b5:	83 ec 14             	sub    $0x14,%esp
f01030b8:	e8 92 d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01030bd:	81 c3 4f 42 01 00    	add    $0x1424f,%ebx
	int cnt = 0;
f01030c3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01030ca:	ff 75 0c             	pushl  0xc(%ebp)
f01030cd:	ff 75 08             	pushl  0x8(%ebp)
f01030d0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01030d3:	50                   	push   %eax
f01030d4:	8d 83 83 bd fe ff    	lea    -0x1427d(%ebx),%eax
f01030da:	50                   	push   %eax
f01030db:	e8 98 04 00 00       	call   f0103578 <vprintfmt>
	return cnt;
}
f01030e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01030e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030e6:	c9                   	leave  
f01030e7:	c3                   	ret    

f01030e8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01030e8:	55                   	push   %ebp
f01030e9:	89 e5                	mov    %esp,%ebp
f01030eb:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01030ee:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01030f1:	50                   	push   %eax
f01030f2:	ff 75 08             	pushl  0x8(%ebp)
f01030f5:	e8 b7 ff ff ff       	call   f01030b1 <vcprintf>
	va_end(ap);

	return cnt;
}
f01030fa:	c9                   	leave  
f01030fb:	c3                   	ret    

f01030fc <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01030fc:	55                   	push   %ebp
f01030fd:	89 e5                	mov    %esp,%ebp
f01030ff:	57                   	push   %edi
f0103100:	56                   	push   %esi
f0103101:	53                   	push   %ebx
f0103102:	83 ec 14             	sub    $0x14,%esp
f0103105:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103108:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010310b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010310e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103111:	8b 32                	mov    (%edx),%esi
f0103113:	8b 01                	mov    (%ecx),%eax
f0103115:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103118:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010311f:	eb 2f                	jmp    f0103150 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103121:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103124:	39 c6                	cmp    %eax,%esi
f0103126:	7f 49                	jg     f0103171 <stab_binsearch+0x75>
f0103128:	0f b6 0a             	movzbl (%edx),%ecx
f010312b:	83 ea 0c             	sub    $0xc,%edx
f010312e:	39 f9                	cmp    %edi,%ecx
f0103130:	75 ef                	jne    f0103121 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103132:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103135:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103138:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010313c:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010313f:	73 35                	jae    f0103176 <stab_binsearch+0x7a>
			*region_left = m;
f0103141:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103144:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0103146:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0103149:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103150:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103153:	7f 4e                	jg     f01031a3 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0103155:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103158:	01 f0                	add    %esi,%eax
f010315a:	89 c3                	mov    %eax,%ebx
f010315c:	c1 eb 1f             	shr    $0x1f,%ebx
f010315f:	01 c3                	add    %eax,%ebx
f0103161:	d1 fb                	sar    %ebx
f0103163:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103166:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103169:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010316d:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f010316f:	eb b3                	jmp    f0103124 <stab_binsearch+0x28>
			l = true_m + 1;
f0103171:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103174:	eb da                	jmp    f0103150 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0103176:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103179:	76 14                	jbe    f010318f <stab_binsearch+0x93>
			*region_right = m - 1;
f010317b:	83 e8 01             	sub    $0x1,%eax
f010317e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103181:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103184:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103186:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010318d:	eb c1                	jmp    f0103150 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010318f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103192:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103194:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103198:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010319a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031a1:	eb ad                	jmp    f0103150 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01031a3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01031a7:	74 16                	je     f01031bf <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01031a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031ac:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01031ae:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031b1:	8b 0e                	mov    (%esi),%ecx
f01031b3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031b6:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01031b9:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01031bd:	eb 12                	jmp    f01031d1 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01031bf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031c2:	8b 00                	mov    (%eax),%eax
f01031c4:	83 e8 01             	sub    $0x1,%eax
f01031c7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01031ca:	89 07                	mov    %eax,(%edi)
f01031cc:	eb 16                	jmp    f01031e4 <stab_binsearch+0xe8>
		     l--)
f01031ce:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01031d1:	39 c1                	cmp    %eax,%ecx
f01031d3:	7d 0a                	jge    f01031df <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01031d5:	0f b6 1a             	movzbl (%edx),%ebx
f01031d8:	83 ea 0c             	sub    $0xc,%edx
f01031db:	39 fb                	cmp    %edi,%ebx
f01031dd:	75 ef                	jne    f01031ce <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01031df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01031e2:	89 07                	mov    %eax,(%edi)
	}
}
f01031e4:	83 c4 14             	add    $0x14,%esp
f01031e7:	5b                   	pop    %ebx
f01031e8:	5e                   	pop    %esi
f01031e9:	5f                   	pop    %edi
f01031ea:	5d                   	pop    %ebp
f01031eb:	c3                   	ret    

f01031ec <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01031ec:	55                   	push   %ebp
f01031ed:	89 e5                	mov    %esp,%ebp
f01031ef:	57                   	push   %edi
f01031f0:	56                   	push   %esi
f01031f1:	53                   	push   %ebx
f01031f2:	83 ec 3c             	sub    $0x3c,%esp
f01031f5:	e8 55 cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01031fa:	81 c3 12 41 01 00    	add    $0x14112,%ebx
f0103200:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103203:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103206:	8d 83 af dd fe ff    	lea    -0x12251(%ebx),%eax
f010320c:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f010320e:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103215:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103218:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010321f:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103222:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103229:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010322f:	0f 86 37 01 00 00    	jbe    f010336c <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103235:	c7 c0 f9 bb 10 f0    	mov    $0xf010bbf9,%eax
f010323b:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f0103241:	0f 86 04 02 00 00    	jbe    f010344b <debuginfo_eip+0x25f>
f0103247:	c7 c0 39 da 10 f0    	mov    $0xf010da39,%eax
f010324d:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103251:	0f 85 fb 01 00 00    	jne    f0103452 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103257:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010325e:	c7 c0 d4 52 10 f0    	mov    $0xf01052d4,%eax
f0103264:	c7 c2 f8 bb 10 f0    	mov    $0xf010bbf8,%edx
f010326a:	29 c2                	sub    %eax,%edx
f010326c:	c1 fa 02             	sar    $0x2,%edx
f010326f:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103275:	83 ea 01             	sub    $0x1,%edx
f0103278:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010327b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010327e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103281:	83 ec 08             	sub    $0x8,%esp
f0103284:	57                   	push   %edi
f0103285:	6a 64                	push   $0x64
f0103287:	e8 70 fe ff ff       	call   f01030fc <stab_binsearch>
	if (lfile == 0)
f010328c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010328f:	83 c4 10             	add    $0x10,%esp
f0103292:	85 c0                	test   %eax,%eax
f0103294:	0f 84 bf 01 00 00    	je     f0103459 <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010329a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010329d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032a0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01032a3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01032a6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01032a9:	83 ec 08             	sub    $0x8,%esp
f01032ac:	57                   	push   %edi
f01032ad:	6a 24                	push   $0x24
f01032af:	c7 c0 d4 52 10 f0    	mov    $0xf01052d4,%eax
f01032b5:	e8 42 fe ff ff       	call   f01030fc <stab_binsearch>

	if (lfun <= rfun) {
f01032ba:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01032bd:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01032c0:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01032c3:	83 c4 10             	add    $0x10,%esp
f01032c6:	39 c8                	cmp    %ecx,%eax
f01032c8:	0f 8f b6 00 00 00    	jg     f0103384 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01032ce:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01032d1:	c7 c1 d4 52 10 f0    	mov    $0xf01052d4,%ecx
f01032d7:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f01032da:	8b 11                	mov    (%ecx),%edx
f01032dc:	89 55 c0             	mov    %edx,-0x40(%ebp)
f01032df:	c7 c2 39 da 10 f0    	mov    $0xf010da39,%edx
f01032e5:	81 ea f9 bb 10 f0    	sub    $0xf010bbf9,%edx
f01032eb:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f01032ee:	73 0c                	jae    f01032fc <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01032f0:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01032f3:	81 c2 f9 bb 10 f0    	add    $0xf010bbf9,%edx
f01032f9:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01032fc:	8b 51 08             	mov    0x8(%ecx),%edx
f01032ff:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103302:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0103304:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103307:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010330a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010330d:	83 ec 08             	sub    $0x8,%esp
f0103310:	6a 3a                	push   $0x3a
f0103312:	ff 76 08             	pushl  0x8(%esi)
f0103315:	e8 c3 09 00 00       	call   f0103cdd <strfind>
f010331a:	2b 46 08             	sub    0x8(%esi),%eax
f010331d:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103320:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103323:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103326:	83 c4 08             	add    $0x8,%esp
f0103329:	57                   	push   %edi
f010332a:	6a 44                	push   $0x44
f010332c:	c7 c0 d4 52 10 f0    	mov    $0xf01052d4,%eax
f0103332:	e8 c5 fd ff ff       	call   f01030fc <stab_binsearch>
	if(lline<=rline){
f0103337:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010333a:	83 c4 10             	add    $0x10,%esp
f010333d:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103340:	0f 8f 1a 01 00 00    	jg     f0103460 <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f0103346:	89 d0                	mov    %edx,%eax
f0103348:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010334b:	c1 e2 02             	shl    $0x2,%edx
f010334e:	c7 c1 d4 52 10 f0    	mov    $0xf01052d4,%ecx
f0103354:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0103359:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010335c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010335f:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0103363:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103367:	89 75 0c             	mov    %esi,0xc(%ebp)
f010336a:	eb 36                	jmp    f01033a2 <debuginfo_eip+0x1b6>
  	        panic("User address");
f010336c:	83 ec 04             	sub    $0x4,%esp
f010336f:	8d 83 b9 dd fe ff    	lea    -0x12247(%ebx),%eax
f0103375:	50                   	push   %eax
f0103376:	6a 7f                	push   $0x7f
f0103378:	8d 83 c6 dd fe ff    	lea    -0x1223a(%ebx),%eax
f010337e:	50                   	push   %eax
f010337f:	e8 15 cd ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0103384:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103387:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010338a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010338d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103390:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103393:	e9 75 ff ff ff       	jmp    f010330d <debuginfo_eip+0x121>
f0103398:	83 e8 01             	sub    $0x1,%eax
f010339b:	83 ea 0c             	sub    $0xc,%edx
f010339e:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01033a2:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f01033a5:	39 c7                	cmp    %eax,%edi
f01033a7:	7f 24                	jg     f01033cd <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f01033a9:	0f b6 0a             	movzbl (%edx),%ecx
f01033ac:	80 f9 84             	cmp    $0x84,%cl
f01033af:	74 46                	je     f01033f7 <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01033b1:	80 f9 64             	cmp    $0x64,%cl
f01033b4:	75 e2                	jne    f0103398 <debuginfo_eip+0x1ac>
f01033b6:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f01033ba:	74 dc                	je     f0103398 <debuginfo_eip+0x1ac>
f01033bc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033bf:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01033c3:	74 3b                	je     f0103400 <debuginfo_eip+0x214>
f01033c5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01033c8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01033cb:	eb 33                	jmp    f0103400 <debuginfo_eip+0x214>
f01033cd:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01033d0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01033d3:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01033d6:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01033db:	39 fa                	cmp    %edi,%edx
f01033dd:	0f 8d 89 00 00 00    	jge    f010346c <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f01033e3:	83 c2 01             	add    $0x1,%edx
f01033e6:	89 d0                	mov    %edx,%eax
f01033e8:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f01033eb:	c7 c2 d4 52 10 f0    	mov    $0xf01052d4,%edx
f01033f1:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f01033f5:	eb 3b                	jmp    f0103432 <debuginfo_eip+0x246>
f01033f7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033fa:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01033fe:	75 26                	jne    f0103426 <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103400:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103403:	c7 c0 d4 52 10 f0    	mov    $0xf01052d4,%eax
f0103409:	8b 14 90             	mov    (%eax,%edx,4),%edx
f010340c:	c7 c0 39 da 10 f0    	mov    $0xf010da39,%eax
f0103412:	81 e8 f9 bb 10 f0    	sub    $0xf010bbf9,%eax
f0103418:	39 c2                	cmp    %eax,%edx
f010341a:	73 b4                	jae    f01033d0 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010341c:	81 c2 f9 bb 10 f0    	add    $0xf010bbf9,%edx
f0103422:	89 16                	mov    %edx,(%esi)
f0103424:	eb aa                	jmp    f01033d0 <debuginfo_eip+0x1e4>
f0103426:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103429:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010342c:	eb d2                	jmp    f0103400 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f010342e:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0103432:	39 c7                	cmp    %eax,%edi
f0103434:	7e 31                	jle    f0103467 <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103436:	0f b6 0a             	movzbl (%edx),%ecx
f0103439:	83 c0 01             	add    $0x1,%eax
f010343c:	83 c2 0c             	add    $0xc,%edx
f010343f:	80 f9 a0             	cmp    $0xa0,%cl
f0103442:	74 ea                	je     f010342e <debuginfo_eip+0x242>
	return 0;
f0103444:	b8 00 00 00 00       	mov    $0x0,%eax
f0103449:	eb 21                	jmp    f010346c <debuginfo_eip+0x280>
		return -1;
f010344b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103450:	eb 1a                	jmp    f010346c <debuginfo_eip+0x280>
f0103452:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103457:	eb 13                	jmp    f010346c <debuginfo_eip+0x280>
		return -1;
f0103459:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010345e:	eb 0c                	jmp    f010346c <debuginfo_eip+0x280>
		return -1;
f0103460:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103465:	eb 05                	jmp    f010346c <debuginfo_eip+0x280>
	return 0;
f0103467:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010346c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010346f:	5b                   	pop    %ebx
f0103470:	5e                   	pop    %esi
f0103471:	5f                   	pop    %edi
f0103472:	5d                   	pop    %ebp
f0103473:	c3                   	ret    

f0103474 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103474:	55                   	push   %ebp
f0103475:	89 e5                	mov    %esp,%ebp
f0103477:	57                   	push   %edi
f0103478:	56                   	push   %esi
f0103479:	53                   	push   %ebx
f010347a:	83 ec 2c             	sub    $0x2c,%esp
f010347d:	e8 d3 fb ff ff       	call   f0103055 <__x86.get_pc_thunk.cx>
f0103482:	81 c1 8a 3e 01 00    	add    $0x13e8a,%ecx
f0103488:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010348b:	89 c7                	mov    %eax,%edi
f010348d:	89 d6                	mov    %edx,%esi
f010348f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103492:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103495:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103498:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010349b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010349e:	bb 00 00 00 00       	mov    $0x0,%ebx
f01034a3:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01034a6:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01034a9:	39 d3                	cmp    %edx,%ebx
f01034ab:	72 09                	jb     f01034b6 <printnum+0x42>
f01034ad:	39 45 10             	cmp    %eax,0x10(%ebp)
f01034b0:	0f 87 83 00 00 00    	ja     f0103539 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01034b6:	83 ec 0c             	sub    $0xc,%esp
f01034b9:	ff 75 18             	pushl  0x18(%ebp)
f01034bc:	8b 45 14             	mov    0x14(%ebp),%eax
f01034bf:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01034c2:	53                   	push   %ebx
f01034c3:	ff 75 10             	pushl  0x10(%ebp)
f01034c6:	83 ec 08             	sub    $0x8,%esp
f01034c9:	ff 75 dc             	pushl  -0x24(%ebp)
f01034cc:	ff 75 d8             	pushl  -0x28(%ebp)
f01034cf:	ff 75 d4             	pushl  -0x2c(%ebp)
f01034d2:	ff 75 d0             	pushl  -0x30(%ebp)
f01034d5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01034d8:	e8 23 0a 00 00       	call   f0103f00 <__udivdi3>
f01034dd:	83 c4 18             	add    $0x18,%esp
f01034e0:	52                   	push   %edx
f01034e1:	50                   	push   %eax
f01034e2:	89 f2                	mov    %esi,%edx
f01034e4:	89 f8                	mov    %edi,%eax
f01034e6:	e8 89 ff ff ff       	call   f0103474 <printnum>
f01034eb:	83 c4 20             	add    $0x20,%esp
f01034ee:	eb 13                	jmp    f0103503 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01034f0:	83 ec 08             	sub    $0x8,%esp
f01034f3:	56                   	push   %esi
f01034f4:	ff 75 18             	pushl  0x18(%ebp)
f01034f7:	ff d7                	call   *%edi
f01034f9:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01034fc:	83 eb 01             	sub    $0x1,%ebx
f01034ff:	85 db                	test   %ebx,%ebx
f0103501:	7f ed                	jg     f01034f0 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103503:	83 ec 08             	sub    $0x8,%esp
f0103506:	56                   	push   %esi
f0103507:	83 ec 04             	sub    $0x4,%esp
f010350a:	ff 75 dc             	pushl  -0x24(%ebp)
f010350d:	ff 75 d8             	pushl  -0x28(%ebp)
f0103510:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103513:	ff 75 d0             	pushl  -0x30(%ebp)
f0103516:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103519:	89 f3                	mov    %esi,%ebx
f010351b:	e8 00 0b 00 00       	call   f0104020 <__umoddi3>
f0103520:	83 c4 14             	add    $0x14,%esp
f0103523:	0f be 84 06 d4 dd fe 	movsbl -0x1222c(%esi,%eax,1),%eax
f010352a:	ff 
f010352b:	50                   	push   %eax
f010352c:	ff d7                	call   *%edi
}
f010352e:	83 c4 10             	add    $0x10,%esp
f0103531:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103534:	5b                   	pop    %ebx
f0103535:	5e                   	pop    %esi
f0103536:	5f                   	pop    %edi
f0103537:	5d                   	pop    %ebp
f0103538:	c3                   	ret    
f0103539:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010353c:	eb be                	jmp    f01034fc <printnum+0x88>

f010353e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010353e:	55                   	push   %ebp
f010353f:	89 e5                	mov    %esp,%ebp
f0103541:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103544:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103548:	8b 10                	mov    (%eax),%edx
f010354a:	3b 50 04             	cmp    0x4(%eax),%edx
f010354d:	73 0a                	jae    f0103559 <sprintputch+0x1b>
		*b->buf++ = ch;
f010354f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103552:	89 08                	mov    %ecx,(%eax)
f0103554:	8b 45 08             	mov    0x8(%ebp),%eax
f0103557:	88 02                	mov    %al,(%edx)
}
f0103559:	5d                   	pop    %ebp
f010355a:	c3                   	ret    

f010355b <printfmt>:
{
f010355b:	55                   	push   %ebp
f010355c:	89 e5                	mov    %esp,%ebp
f010355e:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103561:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103564:	50                   	push   %eax
f0103565:	ff 75 10             	pushl  0x10(%ebp)
f0103568:	ff 75 0c             	pushl  0xc(%ebp)
f010356b:	ff 75 08             	pushl  0x8(%ebp)
f010356e:	e8 05 00 00 00       	call   f0103578 <vprintfmt>
}
f0103573:	83 c4 10             	add    $0x10,%esp
f0103576:	c9                   	leave  
f0103577:	c3                   	ret    

f0103578 <vprintfmt>:
{
f0103578:	55                   	push   %ebp
f0103579:	89 e5                	mov    %esp,%ebp
f010357b:	57                   	push   %edi
f010357c:	56                   	push   %esi
f010357d:	53                   	push   %ebx
f010357e:	83 ec 2c             	sub    $0x2c,%esp
f0103581:	e8 c9 cb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103586:	81 c3 86 3d 01 00    	add    $0x13d86,%ebx
f010358c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010358f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103592:	e9 c3 03 00 00       	jmp    f010395a <.L35+0x48>
		padc = ' ';
f0103597:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010359b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01035a2:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f01035a9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01035b0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01035b5:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035b8:	8d 47 01             	lea    0x1(%edi),%eax
f01035bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01035be:	0f b6 17             	movzbl (%edi),%edx
f01035c1:	8d 42 dd             	lea    -0x23(%edx),%eax
f01035c4:	3c 55                	cmp    $0x55,%al
f01035c6:	0f 87 16 04 00 00    	ja     f01039e2 <.L22>
f01035cc:	0f b6 c0             	movzbl %al,%eax
f01035cf:	89 d9                	mov    %ebx,%ecx
f01035d1:	03 8c 83 60 de fe ff 	add    -0x121a0(%ebx,%eax,4),%ecx
f01035d8:	ff e1                	jmp    *%ecx

f01035da <.L69>:
f01035da:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01035dd:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01035e1:	eb d5                	jmp    f01035b8 <vprintfmt+0x40>

f01035e3 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01035e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01035e6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01035ea:	eb cc                	jmp    f01035b8 <vprintfmt+0x40>

f01035ec <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01035ec:	0f b6 d2             	movzbl %dl,%edx
f01035ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01035f2:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f01035f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01035fa:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01035fe:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103601:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103604:	83 f9 09             	cmp    $0x9,%ecx
f0103607:	77 55                	ja     f010365e <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0103609:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010360c:	eb e9                	jmp    f01035f7 <.L29+0xb>

f010360e <.L26>:
			precision = va_arg(ap, int);
f010360e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103611:	8b 00                	mov    (%eax),%eax
f0103613:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103616:	8b 45 14             	mov    0x14(%ebp),%eax
f0103619:	8d 40 04             	lea    0x4(%eax),%eax
f010361c:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010361f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103622:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103626:	79 90                	jns    f01035b8 <vprintfmt+0x40>
				width = precision, precision = -1;
f0103628:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010362b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010362e:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0103635:	eb 81                	jmp    f01035b8 <vprintfmt+0x40>

f0103637 <.L27>:
f0103637:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010363a:	85 c0                	test   %eax,%eax
f010363c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103641:	0f 49 d0             	cmovns %eax,%edx
f0103644:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103647:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010364a:	e9 69 ff ff ff       	jmp    f01035b8 <vprintfmt+0x40>

f010364f <.L23>:
f010364f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103652:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103659:	e9 5a ff ff ff       	jmp    f01035b8 <vprintfmt+0x40>
f010365e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103661:	eb bf                	jmp    f0103622 <.L26+0x14>

f0103663 <.L33>:
			lflag++;
f0103663:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103667:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010366a:	e9 49 ff ff ff       	jmp    f01035b8 <vprintfmt+0x40>

f010366f <.L30>:
			putch(va_arg(ap, int), putdat);
f010366f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103672:	8d 78 04             	lea    0x4(%eax),%edi
f0103675:	83 ec 08             	sub    $0x8,%esp
f0103678:	56                   	push   %esi
f0103679:	ff 30                	pushl  (%eax)
f010367b:	ff 55 08             	call   *0x8(%ebp)
			break;
f010367e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103681:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103684:	e9 ce 02 00 00       	jmp    f0103957 <.L35+0x45>

f0103689 <.L32>:
			err = va_arg(ap, int);
f0103689:	8b 45 14             	mov    0x14(%ebp),%eax
f010368c:	8d 78 04             	lea    0x4(%eax),%edi
f010368f:	8b 00                	mov    (%eax),%eax
f0103691:	99                   	cltd   
f0103692:	31 d0                	xor    %edx,%eax
f0103694:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103696:	83 f8 06             	cmp    $0x6,%eax
f0103699:	7f 27                	jg     f01036c2 <.L32+0x39>
f010369b:	8b 94 83 38 1d 00 00 	mov    0x1d38(%ebx,%eax,4),%edx
f01036a2:	85 d2                	test   %edx,%edx
f01036a4:	74 1c                	je     f01036c2 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01036a6:	52                   	push   %edx
f01036a7:	8d 83 04 db fe ff    	lea    -0x124fc(%ebx),%eax
f01036ad:	50                   	push   %eax
f01036ae:	56                   	push   %esi
f01036af:	ff 75 08             	pushl  0x8(%ebp)
f01036b2:	e8 a4 fe ff ff       	call   f010355b <printfmt>
f01036b7:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01036ba:	89 7d 14             	mov    %edi,0x14(%ebp)
f01036bd:	e9 95 02 00 00       	jmp    f0103957 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01036c2:	50                   	push   %eax
f01036c3:	8d 83 ec dd fe ff    	lea    -0x12214(%ebx),%eax
f01036c9:	50                   	push   %eax
f01036ca:	56                   	push   %esi
f01036cb:	ff 75 08             	pushl  0x8(%ebp)
f01036ce:	e8 88 fe ff ff       	call   f010355b <printfmt>
f01036d3:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01036d6:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01036d9:	e9 79 02 00 00       	jmp    f0103957 <.L35+0x45>

f01036de <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01036de:	8b 45 14             	mov    0x14(%ebp),%eax
f01036e1:	83 c0 04             	add    $0x4,%eax
f01036e4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01036e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ea:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01036ec:	85 ff                	test   %edi,%edi
f01036ee:	8d 83 e5 dd fe ff    	lea    -0x1221b(%ebx),%eax
f01036f4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01036f7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01036fb:	0f 8e b5 00 00 00    	jle    f01037b6 <.L36+0xd8>
f0103701:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103705:	75 08                	jne    f010370f <.L36+0x31>
f0103707:	89 75 0c             	mov    %esi,0xc(%ebp)
f010370a:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010370d:	eb 6d                	jmp    f010377c <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f010370f:	83 ec 08             	sub    $0x8,%esp
f0103712:	ff 75 cc             	pushl  -0x34(%ebp)
f0103715:	57                   	push   %edi
f0103716:	e8 7e 04 00 00       	call   f0103b99 <strnlen>
f010371b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010371e:	29 c2                	sub    %eax,%edx
f0103720:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0103723:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103726:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010372a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010372d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103730:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103732:	eb 10                	jmp    f0103744 <.L36+0x66>
					putch(padc, putdat);
f0103734:	83 ec 08             	sub    $0x8,%esp
f0103737:	56                   	push   %esi
f0103738:	ff 75 e0             	pushl  -0x20(%ebp)
f010373b:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010373e:	83 ef 01             	sub    $0x1,%edi
f0103741:	83 c4 10             	add    $0x10,%esp
f0103744:	85 ff                	test   %edi,%edi
f0103746:	7f ec                	jg     f0103734 <.L36+0x56>
f0103748:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010374b:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010374e:	85 d2                	test   %edx,%edx
f0103750:	b8 00 00 00 00       	mov    $0x0,%eax
f0103755:	0f 49 c2             	cmovns %edx,%eax
f0103758:	29 c2                	sub    %eax,%edx
f010375a:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010375d:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103760:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103763:	eb 17                	jmp    f010377c <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103765:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103769:	75 30                	jne    f010379b <.L36+0xbd>
					putch(ch, putdat);
f010376b:	83 ec 08             	sub    $0x8,%esp
f010376e:	ff 75 0c             	pushl  0xc(%ebp)
f0103771:	50                   	push   %eax
f0103772:	ff 55 08             	call   *0x8(%ebp)
f0103775:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103778:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010377c:	83 c7 01             	add    $0x1,%edi
f010377f:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103783:	0f be c2             	movsbl %dl,%eax
f0103786:	85 c0                	test   %eax,%eax
f0103788:	74 52                	je     f01037dc <.L36+0xfe>
f010378a:	85 f6                	test   %esi,%esi
f010378c:	78 d7                	js     f0103765 <.L36+0x87>
f010378e:	83 ee 01             	sub    $0x1,%esi
f0103791:	79 d2                	jns    f0103765 <.L36+0x87>
f0103793:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103796:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103799:	eb 32                	jmp    f01037cd <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010379b:	0f be d2             	movsbl %dl,%edx
f010379e:	83 ea 20             	sub    $0x20,%edx
f01037a1:	83 fa 5e             	cmp    $0x5e,%edx
f01037a4:	76 c5                	jbe    f010376b <.L36+0x8d>
					putch('?', putdat);
f01037a6:	83 ec 08             	sub    $0x8,%esp
f01037a9:	ff 75 0c             	pushl  0xc(%ebp)
f01037ac:	6a 3f                	push   $0x3f
f01037ae:	ff 55 08             	call   *0x8(%ebp)
f01037b1:	83 c4 10             	add    $0x10,%esp
f01037b4:	eb c2                	jmp    f0103778 <.L36+0x9a>
f01037b6:	89 75 0c             	mov    %esi,0xc(%ebp)
f01037b9:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01037bc:	eb be                	jmp    f010377c <.L36+0x9e>
				putch(' ', putdat);
f01037be:	83 ec 08             	sub    $0x8,%esp
f01037c1:	56                   	push   %esi
f01037c2:	6a 20                	push   $0x20
f01037c4:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01037c7:	83 ef 01             	sub    $0x1,%edi
f01037ca:	83 c4 10             	add    $0x10,%esp
f01037cd:	85 ff                	test   %edi,%edi
f01037cf:	7f ed                	jg     f01037be <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01037d1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01037d4:	89 45 14             	mov    %eax,0x14(%ebp)
f01037d7:	e9 7b 01 00 00       	jmp    f0103957 <.L35+0x45>
f01037dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01037df:	8b 75 0c             	mov    0xc(%ebp),%esi
f01037e2:	eb e9                	jmp    f01037cd <.L36+0xef>

f01037e4 <.L31>:
f01037e4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01037e7:	83 f9 01             	cmp    $0x1,%ecx
f01037ea:	7e 40                	jle    f010382c <.L31+0x48>
		return va_arg(*ap, long long);
f01037ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01037ef:	8b 50 04             	mov    0x4(%eax),%edx
f01037f2:	8b 00                	mov    (%eax),%eax
f01037f4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037f7:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01037fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01037fd:	8d 40 08             	lea    0x8(%eax),%eax
f0103800:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103803:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103807:	79 55                	jns    f010385e <.L31+0x7a>
				putch('-', putdat);
f0103809:	83 ec 08             	sub    $0x8,%esp
f010380c:	56                   	push   %esi
f010380d:	6a 2d                	push   $0x2d
f010380f:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103812:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103815:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103818:	f7 da                	neg    %edx
f010381a:	83 d1 00             	adc    $0x0,%ecx
f010381d:	f7 d9                	neg    %ecx
f010381f:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103822:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103827:	e9 10 01 00 00       	jmp    f010393c <.L35+0x2a>
	else if (lflag)
f010382c:	85 c9                	test   %ecx,%ecx
f010382e:	75 17                	jne    f0103847 <.L31+0x63>
		return va_arg(*ap, int);
f0103830:	8b 45 14             	mov    0x14(%ebp),%eax
f0103833:	8b 00                	mov    (%eax),%eax
f0103835:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103838:	99                   	cltd   
f0103839:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010383c:	8b 45 14             	mov    0x14(%ebp),%eax
f010383f:	8d 40 04             	lea    0x4(%eax),%eax
f0103842:	89 45 14             	mov    %eax,0x14(%ebp)
f0103845:	eb bc                	jmp    f0103803 <.L31+0x1f>
		return va_arg(*ap, long);
f0103847:	8b 45 14             	mov    0x14(%ebp),%eax
f010384a:	8b 00                	mov    (%eax),%eax
f010384c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010384f:	99                   	cltd   
f0103850:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103853:	8b 45 14             	mov    0x14(%ebp),%eax
f0103856:	8d 40 04             	lea    0x4(%eax),%eax
f0103859:	89 45 14             	mov    %eax,0x14(%ebp)
f010385c:	eb a5                	jmp    f0103803 <.L31+0x1f>
			num = getint(&ap, lflag);
f010385e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103861:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103864:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103869:	e9 ce 00 00 00       	jmp    f010393c <.L35+0x2a>

f010386e <.L37>:
f010386e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103871:	83 f9 01             	cmp    $0x1,%ecx
f0103874:	7e 18                	jle    f010388e <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0103876:	8b 45 14             	mov    0x14(%ebp),%eax
f0103879:	8b 10                	mov    (%eax),%edx
f010387b:	8b 48 04             	mov    0x4(%eax),%ecx
f010387e:	8d 40 08             	lea    0x8(%eax),%eax
f0103881:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103884:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103889:	e9 ae 00 00 00       	jmp    f010393c <.L35+0x2a>
	else if (lflag)
f010388e:	85 c9                	test   %ecx,%ecx
f0103890:	75 1a                	jne    f01038ac <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0103892:	8b 45 14             	mov    0x14(%ebp),%eax
f0103895:	8b 10                	mov    (%eax),%edx
f0103897:	b9 00 00 00 00       	mov    $0x0,%ecx
f010389c:	8d 40 04             	lea    0x4(%eax),%eax
f010389f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038a2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038a7:	e9 90 00 00 00       	jmp    f010393c <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01038ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01038af:	8b 10                	mov    (%eax),%edx
f01038b1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038b6:	8d 40 04             	lea    0x4(%eax),%eax
f01038b9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038bc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038c1:	eb 79                	jmp    f010393c <.L35+0x2a>

f01038c3 <.L34>:
f01038c3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01038c6:	83 f9 01             	cmp    $0x1,%ecx
f01038c9:	7e 15                	jle    f01038e0 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f01038cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ce:	8b 10                	mov    (%eax),%edx
f01038d0:	8b 48 04             	mov    0x4(%eax),%ecx
f01038d3:	8d 40 08             	lea    0x8(%eax),%eax
f01038d6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01038d9:	b8 08 00 00 00       	mov    $0x8,%eax
f01038de:	eb 5c                	jmp    f010393c <.L35+0x2a>
	else if (lflag)
f01038e0:	85 c9                	test   %ecx,%ecx
f01038e2:	75 17                	jne    f01038fb <.L34+0x38>
		return va_arg(*ap, unsigned int);
f01038e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01038e7:	8b 10                	mov    (%eax),%edx
f01038e9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038ee:	8d 40 04             	lea    0x4(%eax),%eax
f01038f1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01038f4:	b8 08 00 00 00       	mov    $0x8,%eax
f01038f9:	eb 41                	jmp    f010393c <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01038fb:	8b 45 14             	mov    0x14(%ebp),%eax
f01038fe:	8b 10                	mov    (%eax),%edx
f0103900:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103905:	8d 40 04             	lea    0x4(%eax),%eax
f0103908:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010390b:	b8 08 00 00 00       	mov    $0x8,%eax
f0103910:	eb 2a                	jmp    f010393c <.L35+0x2a>

f0103912 <.L35>:
			putch('0', putdat);
f0103912:	83 ec 08             	sub    $0x8,%esp
f0103915:	56                   	push   %esi
f0103916:	6a 30                	push   $0x30
f0103918:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010391b:	83 c4 08             	add    $0x8,%esp
f010391e:	56                   	push   %esi
f010391f:	6a 78                	push   $0x78
f0103921:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0103924:	8b 45 14             	mov    0x14(%ebp),%eax
f0103927:	8b 10                	mov    (%eax),%edx
f0103929:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010392e:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103931:	8d 40 04             	lea    0x4(%eax),%eax
f0103934:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103937:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010393c:	83 ec 0c             	sub    $0xc,%esp
f010393f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103943:	57                   	push   %edi
f0103944:	ff 75 e0             	pushl  -0x20(%ebp)
f0103947:	50                   	push   %eax
f0103948:	51                   	push   %ecx
f0103949:	52                   	push   %edx
f010394a:	89 f2                	mov    %esi,%edx
f010394c:	8b 45 08             	mov    0x8(%ebp),%eax
f010394f:	e8 20 fb ff ff       	call   f0103474 <printnum>
			break;
f0103954:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103957:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010395a:	83 c7 01             	add    $0x1,%edi
f010395d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103961:	83 f8 25             	cmp    $0x25,%eax
f0103964:	0f 84 2d fc ff ff    	je     f0103597 <vprintfmt+0x1f>
			if (ch == '\0')
f010396a:	85 c0                	test   %eax,%eax
f010396c:	0f 84 91 00 00 00    	je     f0103a03 <.L22+0x21>
			putch(ch, putdat);
f0103972:	83 ec 08             	sub    $0x8,%esp
f0103975:	56                   	push   %esi
f0103976:	50                   	push   %eax
f0103977:	ff 55 08             	call   *0x8(%ebp)
f010397a:	83 c4 10             	add    $0x10,%esp
f010397d:	eb db                	jmp    f010395a <.L35+0x48>

f010397f <.L38>:
f010397f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103982:	83 f9 01             	cmp    $0x1,%ecx
f0103985:	7e 15                	jle    f010399c <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0103987:	8b 45 14             	mov    0x14(%ebp),%eax
f010398a:	8b 10                	mov    (%eax),%edx
f010398c:	8b 48 04             	mov    0x4(%eax),%ecx
f010398f:	8d 40 08             	lea    0x8(%eax),%eax
f0103992:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103995:	b8 10 00 00 00       	mov    $0x10,%eax
f010399a:	eb a0                	jmp    f010393c <.L35+0x2a>
	else if (lflag)
f010399c:	85 c9                	test   %ecx,%ecx
f010399e:	75 17                	jne    f01039b7 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01039a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01039a3:	8b 10                	mov    (%eax),%edx
f01039a5:	b9 00 00 00 00       	mov    $0x0,%ecx
f01039aa:	8d 40 04             	lea    0x4(%eax),%eax
f01039ad:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01039b0:	b8 10 00 00 00       	mov    $0x10,%eax
f01039b5:	eb 85                	jmp    f010393c <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01039b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ba:	8b 10                	mov    (%eax),%edx
f01039bc:	b9 00 00 00 00       	mov    $0x0,%ecx
f01039c1:	8d 40 04             	lea    0x4(%eax),%eax
f01039c4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01039c7:	b8 10 00 00 00       	mov    $0x10,%eax
f01039cc:	e9 6b ff ff ff       	jmp    f010393c <.L35+0x2a>

f01039d1 <.L25>:
			putch(ch, putdat);
f01039d1:	83 ec 08             	sub    $0x8,%esp
f01039d4:	56                   	push   %esi
f01039d5:	6a 25                	push   $0x25
f01039d7:	ff 55 08             	call   *0x8(%ebp)
			break;
f01039da:	83 c4 10             	add    $0x10,%esp
f01039dd:	e9 75 ff ff ff       	jmp    f0103957 <.L35+0x45>

f01039e2 <.L22>:
			putch('%', putdat);
f01039e2:	83 ec 08             	sub    $0x8,%esp
f01039e5:	56                   	push   %esi
f01039e6:	6a 25                	push   $0x25
f01039e8:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01039eb:	83 c4 10             	add    $0x10,%esp
f01039ee:	89 f8                	mov    %edi,%eax
f01039f0:	eb 03                	jmp    f01039f5 <.L22+0x13>
f01039f2:	83 e8 01             	sub    $0x1,%eax
f01039f5:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01039f9:	75 f7                	jne    f01039f2 <.L22+0x10>
f01039fb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01039fe:	e9 54 ff ff ff       	jmp    f0103957 <.L35+0x45>
}
f0103a03:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a06:	5b                   	pop    %ebx
f0103a07:	5e                   	pop    %esi
f0103a08:	5f                   	pop    %edi
f0103a09:	5d                   	pop    %ebp
f0103a0a:	c3                   	ret    

f0103a0b <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103a0b:	55                   	push   %ebp
f0103a0c:	89 e5                	mov    %esp,%ebp
f0103a0e:	53                   	push   %ebx
f0103a0f:	83 ec 14             	sub    $0x14,%esp
f0103a12:	e8 38 c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103a17:	81 c3 f5 38 01 00    	add    $0x138f5,%ebx
f0103a1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a20:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103a23:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103a26:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103a2a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103a2d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103a34:	85 c0                	test   %eax,%eax
f0103a36:	74 2b                	je     f0103a63 <vsnprintf+0x58>
f0103a38:	85 d2                	test   %edx,%edx
f0103a3a:	7e 27                	jle    f0103a63 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103a3c:	ff 75 14             	pushl  0x14(%ebp)
f0103a3f:	ff 75 10             	pushl  0x10(%ebp)
f0103a42:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103a45:	50                   	push   %eax
f0103a46:	8d 83 32 c2 fe ff    	lea    -0x13dce(%ebx),%eax
f0103a4c:	50                   	push   %eax
f0103a4d:	e8 26 fb ff ff       	call   f0103578 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103a52:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a55:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103a58:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a5b:	83 c4 10             	add    $0x10,%esp
}
f0103a5e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a61:	c9                   	leave  
f0103a62:	c3                   	ret    
		return -E_INVAL;
f0103a63:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103a68:	eb f4                	jmp    f0103a5e <vsnprintf+0x53>

f0103a6a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103a6a:	55                   	push   %ebp
f0103a6b:	89 e5                	mov    %esp,%ebp
f0103a6d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103a70:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103a73:	50                   	push   %eax
f0103a74:	ff 75 10             	pushl  0x10(%ebp)
f0103a77:	ff 75 0c             	pushl  0xc(%ebp)
f0103a7a:	ff 75 08             	pushl  0x8(%ebp)
f0103a7d:	e8 89 ff ff ff       	call   f0103a0b <vsnprintf>
	va_end(ap);

	return rc;
}
f0103a82:	c9                   	leave  
f0103a83:	c3                   	ret    

f0103a84 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103a84:	55                   	push   %ebp
f0103a85:	89 e5                	mov    %esp,%ebp
f0103a87:	57                   	push   %edi
f0103a88:	56                   	push   %esi
f0103a89:	53                   	push   %ebx
f0103a8a:	83 ec 1c             	sub    $0x1c,%esp
f0103a8d:	e8 bd c6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103a92:	81 c3 7a 38 01 00    	add    $0x1387a,%ebx
f0103a98:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103a9b:	85 c0                	test   %eax,%eax
f0103a9d:	74 13                	je     f0103ab2 <readline+0x2e>
		cprintf("%s", prompt);
f0103a9f:	83 ec 08             	sub    $0x8,%esp
f0103aa2:	50                   	push   %eax
f0103aa3:	8d 83 04 db fe ff    	lea    -0x124fc(%ebx),%eax
f0103aa9:	50                   	push   %eax
f0103aaa:	e8 39 f6 ff ff       	call   f01030e8 <cprintf>
f0103aaf:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103ab2:	83 ec 0c             	sub    $0xc,%esp
f0103ab5:	6a 00                	push   $0x0
f0103ab7:	e8 2b cc ff ff       	call   f01006e7 <iscons>
f0103abc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103abf:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103ac2:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ac7:	eb 46                	jmp    f0103b0f <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103ac9:	83 ec 08             	sub    $0x8,%esp
f0103acc:	50                   	push   %eax
f0103acd:	8d 83 b8 df fe ff    	lea    -0x12048(%ebx),%eax
f0103ad3:	50                   	push   %eax
f0103ad4:	e8 0f f6 ff ff       	call   f01030e8 <cprintf>
			return NULL;
f0103ad9:	83 c4 10             	add    $0x10,%esp
f0103adc:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103ae1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ae4:	5b                   	pop    %ebx
f0103ae5:	5e                   	pop    %esi
f0103ae6:	5f                   	pop    %edi
f0103ae7:	5d                   	pop    %ebp
f0103ae8:	c3                   	ret    
			if (echoing)
f0103ae9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103aed:	75 05                	jne    f0103af4 <readline+0x70>
			i--;
f0103aef:	83 ef 01             	sub    $0x1,%edi
f0103af2:	eb 1b                	jmp    f0103b0f <readline+0x8b>
				cputchar('\b');
f0103af4:	83 ec 0c             	sub    $0xc,%esp
f0103af7:	6a 08                	push   $0x8
f0103af9:	e8 c8 cb ff ff       	call   f01006c6 <cputchar>
f0103afe:	83 c4 10             	add    $0x10,%esp
f0103b01:	eb ec                	jmp    f0103aef <readline+0x6b>
			buf[i++] = c;
f0103b03:	89 f0                	mov    %esi,%eax
f0103b05:	88 84 3b 94 1f 00 00 	mov    %al,0x1f94(%ebx,%edi,1)
f0103b0c:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103b0f:	e8 c2 cb ff ff       	call   f01006d6 <getchar>
f0103b14:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103b16:	85 c0                	test   %eax,%eax
f0103b18:	78 af                	js     f0103ac9 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103b1a:	83 f8 08             	cmp    $0x8,%eax
f0103b1d:	0f 94 c2             	sete   %dl
f0103b20:	83 f8 7f             	cmp    $0x7f,%eax
f0103b23:	0f 94 c0             	sete   %al
f0103b26:	08 c2                	or     %al,%dl
f0103b28:	74 04                	je     f0103b2e <readline+0xaa>
f0103b2a:	85 ff                	test   %edi,%edi
f0103b2c:	7f bb                	jg     f0103ae9 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103b2e:	83 fe 1f             	cmp    $0x1f,%esi
f0103b31:	7e 1c                	jle    f0103b4f <readline+0xcb>
f0103b33:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103b39:	7f 14                	jg     f0103b4f <readline+0xcb>
			if (echoing)
f0103b3b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b3f:	74 c2                	je     f0103b03 <readline+0x7f>
				cputchar(c);
f0103b41:	83 ec 0c             	sub    $0xc,%esp
f0103b44:	56                   	push   %esi
f0103b45:	e8 7c cb ff ff       	call   f01006c6 <cputchar>
f0103b4a:	83 c4 10             	add    $0x10,%esp
f0103b4d:	eb b4                	jmp    f0103b03 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103b4f:	83 fe 0a             	cmp    $0xa,%esi
f0103b52:	74 05                	je     f0103b59 <readline+0xd5>
f0103b54:	83 fe 0d             	cmp    $0xd,%esi
f0103b57:	75 b6                	jne    f0103b0f <readline+0x8b>
			if (echoing)
f0103b59:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b5d:	75 13                	jne    f0103b72 <readline+0xee>
			buf[i] = 0;
f0103b5f:	c6 84 3b 94 1f 00 00 	movb   $0x0,0x1f94(%ebx,%edi,1)
f0103b66:	00 
			return buf;
f0103b67:	8d 83 94 1f 00 00    	lea    0x1f94(%ebx),%eax
f0103b6d:	e9 6f ff ff ff       	jmp    f0103ae1 <readline+0x5d>
				cputchar('\n');
f0103b72:	83 ec 0c             	sub    $0xc,%esp
f0103b75:	6a 0a                	push   $0xa
f0103b77:	e8 4a cb ff ff       	call   f01006c6 <cputchar>
f0103b7c:	83 c4 10             	add    $0x10,%esp
f0103b7f:	eb de                	jmp    f0103b5f <readline+0xdb>

f0103b81 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103b81:	55                   	push   %ebp
f0103b82:	89 e5                	mov    %esp,%ebp
f0103b84:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b87:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b8c:	eb 03                	jmp    f0103b91 <strlen+0x10>
		n++;
f0103b8e:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103b91:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103b95:	75 f7                	jne    f0103b8e <strlen+0xd>
	return n;
}
f0103b97:	5d                   	pop    %ebp
f0103b98:	c3                   	ret    

f0103b99 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103b99:	55                   	push   %ebp
f0103b9a:	89 e5                	mov    %esp,%ebp
f0103b9c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b9f:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103ba2:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ba7:	eb 03                	jmp    f0103bac <strnlen+0x13>
		n++;
f0103ba9:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103bac:	39 d0                	cmp    %edx,%eax
f0103bae:	74 06                	je     f0103bb6 <strnlen+0x1d>
f0103bb0:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103bb4:	75 f3                	jne    f0103ba9 <strnlen+0x10>
	return n;
}
f0103bb6:	5d                   	pop    %ebp
f0103bb7:	c3                   	ret    

f0103bb8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103bb8:	55                   	push   %ebp
f0103bb9:	89 e5                	mov    %esp,%ebp
f0103bbb:	53                   	push   %ebx
f0103bbc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bbf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103bc2:	89 c2                	mov    %eax,%edx
f0103bc4:	83 c1 01             	add    $0x1,%ecx
f0103bc7:	83 c2 01             	add    $0x1,%edx
f0103bca:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103bce:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103bd1:	84 db                	test   %bl,%bl
f0103bd3:	75 ef                	jne    f0103bc4 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103bd5:	5b                   	pop    %ebx
f0103bd6:	5d                   	pop    %ebp
f0103bd7:	c3                   	ret    

f0103bd8 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103bd8:	55                   	push   %ebp
f0103bd9:	89 e5                	mov    %esp,%ebp
f0103bdb:	53                   	push   %ebx
f0103bdc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103bdf:	53                   	push   %ebx
f0103be0:	e8 9c ff ff ff       	call   f0103b81 <strlen>
f0103be5:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103be8:	ff 75 0c             	pushl  0xc(%ebp)
f0103beb:	01 d8                	add    %ebx,%eax
f0103bed:	50                   	push   %eax
f0103bee:	e8 c5 ff ff ff       	call   f0103bb8 <strcpy>
	return dst;
}
f0103bf3:	89 d8                	mov    %ebx,%eax
f0103bf5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103bf8:	c9                   	leave  
f0103bf9:	c3                   	ret    

f0103bfa <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103bfa:	55                   	push   %ebp
f0103bfb:	89 e5                	mov    %esp,%ebp
f0103bfd:	56                   	push   %esi
f0103bfe:	53                   	push   %ebx
f0103bff:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c02:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103c05:	89 f3                	mov    %esi,%ebx
f0103c07:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103c0a:	89 f2                	mov    %esi,%edx
f0103c0c:	eb 0f                	jmp    f0103c1d <strncpy+0x23>
		*dst++ = *src;
f0103c0e:	83 c2 01             	add    $0x1,%edx
f0103c11:	0f b6 01             	movzbl (%ecx),%eax
f0103c14:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103c17:	80 39 01             	cmpb   $0x1,(%ecx)
f0103c1a:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103c1d:	39 da                	cmp    %ebx,%edx
f0103c1f:	75 ed                	jne    f0103c0e <strncpy+0x14>
	}
	return ret;
}
f0103c21:	89 f0                	mov    %esi,%eax
f0103c23:	5b                   	pop    %ebx
f0103c24:	5e                   	pop    %esi
f0103c25:	5d                   	pop    %ebp
f0103c26:	c3                   	ret    

f0103c27 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103c27:	55                   	push   %ebp
f0103c28:	89 e5                	mov    %esp,%ebp
f0103c2a:	56                   	push   %esi
f0103c2b:	53                   	push   %ebx
f0103c2c:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c2f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c32:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103c35:	89 f0                	mov    %esi,%eax
f0103c37:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103c3b:	85 c9                	test   %ecx,%ecx
f0103c3d:	75 0b                	jne    f0103c4a <strlcpy+0x23>
f0103c3f:	eb 17                	jmp    f0103c58 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103c41:	83 c2 01             	add    $0x1,%edx
f0103c44:	83 c0 01             	add    $0x1,%eax
f0103c47:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103c4a:	39 d8                	cmp    %ebx,%eax
f0103c4c:	74 07                	je     f0103c55 <strlcpy+0x2e>
f0103c4e:	0f b6 0a             	movzbl (%edx),%ecx
f0103c51:	84 c9                	test   %cl,%cl
f0103c53:	75 ec                	jne    f0103c41 <strlcpy+0x1a>
		*dst = '\0';
f0103c55:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103c58:	29 f0                	sub    %esi,%eax
}
f0103c5a:	5b                   	pop    %ebx
f0103c5b:	5e                   	pop    %esi
f0103c5c:	5d                   	pop    %ebp
f0103c5d:	c3                   	ret    

f0103c5e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103c5e:	55                   	push   %ebp
f0103c5f:	89 e5                	mov    %esp,%ebp
f0103c61:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c64:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103c67:	eb 06                	jmp    f0103c6f <strcmp+0x11>
		p++, q++;
f0103c69:	83 c1 01             	add    $0x1,%ecx
f0103c6c:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103c6f:	0f b6 01             	movzbl (%ecx),%eax
f0103c72:	84 c0                	test   %al,%al
f0103c74:	74 04                	je     f0103c7a <strcmp+0x1c>
f0103c76:	3a 02                	cmp    (%edx),%al
f0103c78:	74 ef                	je     f0103c69 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c7a:	0f b6 c0             	movzbl %al,%eax
f0103c7d:	0f b6 12             	movzbl (%edx),%edx
f0103c80:	29 d0                	sub    %edx,%eax
}
f0103c82:	5d                   	pop    %ebp
f0103c83:	c3                   	ret    

f0103c84 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103c84:	55                   	push   %ebp
f0103c85:	89 e5                	mov    %esp,%ebp
f0103c87:	53                   	push   %ebx
f0103c88:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c8b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c8e:	89 c3                	mov    %eax,%ebx
f0103c90:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103c93:	eb 06                	jmp    f0103c9b <strncmp+0x17>
		n--, p++, q++;
f0103c95:	83 c0 01             	add    $0x1,%eax
f0103c98:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103c9b:	39 d8                	cmp    %ebx,%eax
f0103c9d:	74 16                	je     f0103cb5 <strncmp+0x31>
f0103c9f:	0f b6 08             	movzbl (%eax),%ecx
f0103ca2:	84 c9                	test   %cl,%cl
f0103ca4:	74 04                	je     f0103caa <strncmp+0x26>
f0103ca6:	3a 0a                	cmp    (%edx),%cl
f0103ca8:	74 eb                	je     f0103c95 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103caa:	0f b6 00             	movzbl (%eax),%eax
f0103cad:	0f b6 12             	movzbl (%edx),%edx
f0103cb0:	29 d0                	sub    %edx,%eax
}
f0103cb2:	5b                   	pop    %ebx
f0103cb3:	5d                   	pop    %ebp
f0103cb4:	c3                   	ret    
		return 0;
f0103cb5:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cba:	eb f6                	jmp    f0103cb2 <strncmp+0x2e>

f0103cbc <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103cbc:	55                   	push   %ebp
f0103cbd:	89 e5                	mov    %esp,%ebp
f0103cbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cc2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103cc6:	0f b6 10             	movzbl (%eax),%edx
f0103cc9:	84 d2                	test   %dl,%dl
f0103ccb:	74 09                	je     f0103cd6 <strchr+0x1a>
		if (*s == c)
f0103ccd:	38 ca                	cmp    %cl,%dl
f0103ccf:	74 0a                	je     f0103cdb <strchr+0x1f>
	for (; *s; s++)
f0103cd1:	83 c0 01             	add    $0x1,%eax
f0103cd4:	eb f0                	jmp    f0103cc6 <strchr+0xa>
			return (char *) s;
	return 0;
f0103cd6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103cdb:	5d                   	pop    %ebp
f0103cdc:	c3                   	ret    

f0103cdd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103cdd:	55                   	push   %ebp
f0103cde:	89 e5                	mov    %esp,%ebp
f0103ce0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ce3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ce7:	eb 03                	jmp    f0103cec <strfind+0xf>
f0103ce9:	83 c0 01             	add    $0x1,%eax
f0103cec:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103cef:	38 ca                	cmp    %cl,%dl
f0103cf1:	74 04                	je     f0103cf7 <strfind+0x1a>
f0103cf3:	84 d2                	test   %dl,%dl
f0103cf5:	75 f2                	jne    f0103ce9 <strfind+0xc>
			break;
	return (char *) s;
}
f0103cf7:	5d                   	pop    %ebp
f0103cf8:	c3                   	ret    

f0103cf9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103cf9:	55                   	push   %ebp
f0103cfa:	89 e5                	mov    %esp,%ebp
f0103cfc:	57                   	push   %edi
f0103cfd:	56                   	push   %esi
f0103cfe:	53                   	push   %ebx
f0103cff:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103d02:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103d05:	85 c9                	test   %ecx,%ecx
f0103d07:	74 13                	je     f0103d1c <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103d09:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103d0f:	75 05                	jne    f0103d16 <memset+0x1d>
f0103d11:	f6 c1 03             	test   $0x3,%cl
f0103d14:	74 0d                	je     f0103d23 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103d16:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d19:	fc                   	cld    
f0103d1a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103d1c:	89 f8                	mov    %edi,%eax
f0103d1e:	5b                   	pop    %ebx
f0103d1f:	5e                   	pop    %esi
f0103d20:	5f                   	pop    %edi
f0103d21:	5d                   	pop    %ebp
f0103d22:	c3                   	ret    
		c &= 0xFF;
f0103d23:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103d27:	89 d3                	mov    %edx,%ebx
f0103d29:	c1 e3 08             	shl    $0x8,%ebx
f0103d2c:	89 d0                	mov    %edx,%eax
f0103d2e:	c1 e0 18             	shl    $0x18,%eax
f0103d31:	89 d6                	mov    %edx,%esi
f0103d33:	c1 e6 10             	shl    $0x10,%esi
f0103d36:	09 f0                	or     %esi,%eax
f0103d38:	09 c2                	or     %eax,%edx
f0103d3a:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103d3c:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103d3f:	89 d0                	mov    %edx,%eax
f0103d41:	fc                   	cld    
f0103d42:	f3 ab                	rep stos %eax,%es:(%edi)
f0103d44:	eb d6                	jmp    f0103d1c <memset+0x23>

f0103d46 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103d46:	55                   	push   %ebp
f0103d47:	89 e5                	mov    %esp,%ebp
f0103d49:	57                   	push   %edi
f0103d4a:	56                   	push   %esi
f0103d4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d4e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d51:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103d54:	39 c6                	cmp    %eax,%esi
f0103d56:	73 35                	jae    f0103d8d <memmove+0x47>
f0103d58:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103d5b:	39 c2                	cmp    %eax,%edx
f0103d5d:	76 2e                	jbe    f0103d8d <memmove+0x47>
		s += n;
		d += n;
f0103d5f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d62:	89 d6                	mov    %edx,%esi
f0103d64:	09 fe                	or     %edi,%esi
f0103d66:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103d6c:	74 0c                	je     f0103d7a <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103d6e:	83 ef 01             	sub    $0x1,%edi
f0103d71:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103d74:	fd                   	std    
f0103d75:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103d77:	fc                   	cld    
f0103d78:	eb 21                	jmp    f0103d9b <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d7a:	f6 c1 03             	test   $0x3,%cl
f0103d7d:	75 ef                	jne    f0103d6e <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103d7f:	83 ef 04             	sub    $0x4,%edi
f0103d82:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103d85:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103d88:	fd                   	std    
f0103d89:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d8b:	eb ea                	jmp    f0103d77 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d8d:	89 f2                	mov    %esi,%edx
f0103d8f:	09 c2                	or     %eax,%edx
f0103d91:	f6 c2 03             	test   $0x3,%dl
f0103d94:	74 09                	je     f0103d9f <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103d96:	89 c7                	mov    %eax,%edi
f0103d98:	fc                   	cld    
f0103d99:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103d9b:	5e                   	pop    %esi
f0103d9c:	5f                   	pop    %edi
f0103d9d:	5d                   	pop    %ebp
f0103d9e:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d9f:	f6 c1 03             	test   $0x3,%cl
f0103da2:	75 f2                	jne    f0103d96 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103da4:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103da7:	89 c7                	mov    %eax,%edi
f0103da9:	fc                   	cld    
f0103daa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103dac:	eb ed                	jmp    f0103d9b <memmove+0x55>

f0103dae <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103dae:	55                   	push   %ebp
f0103daf:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103db1:	ff 75 10             	pushl  0x10(%ebp)
f0103db4:	ff 75 0c             	pushl  0xc(%ebp)
f0103db7:	ff 75 08             	pushl  0x8(%ebp)
f0103dba:	e8 87 ff ff ff       	call   f0103d46 <memmove>
}
f0103dbf:	c9                   	leave  
f0103dc0:	c3                   	ret    

f0103dc1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103dc1:	55                   	push   %ebp
f0103dc2:	89 e5                	mov    %esp,%ebp
f0103dc4:	56                   	push   %esi
f0103dc5:	53                   	push   %ebx
f0103dc6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dc9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103dcc:	89 c6                	mov    %eax,%esi
f0103dce:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103dd1:	39 f0                	cmp    %esi,%eax
f0103dd3:	74 1c                	je     f0103df1 <memcmp+0x30>
		if (*s1 != *s2)
f0103dd5:	0f b6 08             	movzbl (%eax),%ecx
f0103dd8:	0f b6 1a             	movzbl (%edx),%ebx
f0103ddb:	38 d9                	cmp    %bl,%cl
f0103ddd:	75 08                	jne    f0103de7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103ddf:	83 c0 01             	add    $0x1,%eax
f0103de2:	83 c2 01             	add    $0x1,%edx
f0103de5:	eb ea                	jmp    f0103dd1 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103de7:	0f b6 c1             	movzbl %cl,%eax
f0103dea:	0f b6 db             	movzbl %bl,%ebx
f0103ded:	29 d8                	sub    %ebx,%eax
f0103def:	eb 05                	jmp    f0103df6 <memcmp+0x35>
	}

	return 0;
f0103df1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103df6:	5b                   	pop    %ebx
f0103df7:	5e                   	pop    %esi
f0103df8:	5d                   	pop    %ebp
f0103df9:	c3                   	ret    

f0103dfa <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103dfa:	55                   	push   %ebp
f0103dfb:	89 e5                	mov    %esp,%ebp
f0103dfd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e00:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103e03:	89 c2                	mov    %eax,%edx
f0103e05:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103e08:	39 d0                	cmp    %edx,%eax
f0103e0a:	73 09                	jae    f0103e15 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103e0c:	38 08                	cmp    %cl,(%eax)
f0103e0e:	74 05                	je     f0103e15 <memfind+0x1b>
	for (; s < ends; s++)
f0103e10:	83 c0 01             	add    $0x1,%eax
f0103e13:	eb f3                	jmp    f0103e08 <memfind+0xe>
			break;
	return (void *) s;
}
f0103e15:	5d                   	pop    %ebp
f0103e16:	c3                   	ret    

f0103e17 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103e17:	55                   	push   %ebp
f0103e18:	89 e5                	mov    %esp,%ebp
f0103e1a:	57                   	push   %edi
f0103e1b:	56                   	push   %esi
f0103e1c:	53                   	push   %ebx
f0103e1d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103e20:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103e23:	eb 03                	jmp    f0103e28 <strtol+0x11>
		s++;
f0103e25:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103e28:	0f b6 01             	movzbl (%ecx),%eax
f0103e2b:	3c 20                	cmp    $0x20,%al
f0103e2d:	74 f6                	je     f0103e25 <strtol+0xe>
f0103e2f:	3c 09                	cmp    $0x9,%al
f0103e31:	74 f2                	je     f0103e25 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103e33:	3c 2b                	cmp    $0x2b,%al
f0103e35:	74 2e                	je     f0103e65 <strtol+0x4e>
	int neg = 0;
f0103e37:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103e3c:	3c 2d                	cmp    $0x2d,%al
f0103e3e:	74 2f                	je     f0103e6f <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e40:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103e46:	75 05                	jne    f0103e4d <strtol+0x36>
f0103e48:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e4b:	74 2c                	je     f0103e79 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e4d:	85 db                	test   %ebx,%ebx
f0103e4f:	75 0a                	jne    f0103e5b <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103e51:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103e56:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e59:	74 28                	je     f0103e83 <strtol+0x6c>
		base = 10;
f0103e5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e60:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103e63:	eb 50                	jmp    f0103eb5 <strtol+0x9e>
		s++;
f0103e65:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103e68:	bf 00 00 00 00       	mov    $0x0,%edi
f0103e6d:	eb d1                	jmp    f0103e40 <strtol+0x29>
		s++, neg = 1;
f0103e6f:	83 c1 01             	add    $0x1,%ecx
f0103e72:	bf 01 00 00 00       	mov    $0x1,%edi
f0103e77:	eb c7                	jmp    f0103e40 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e79:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103e7d:	74 0e                	je     f0103e8d <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103e7f:	85 db                	test   %ebx,%ebx
f0103e81:	75 d8                	jne    f0103e5b <strtol+0x44>
		s++, base = 8;
f0103e83:	83 c1 01             	add    $0x1,%ecx
f0103e86:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103e8b:	eb ce                	jmp    f0103e5b <strtol+0x44>
		s += 2, base = 16;
f0103e8d:	83 c1 02             	add    $0x2,%ecx
f0103e90:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103e95:	eb c4                	jmp    f0103e5b <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103e97:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103e9a:	89 f3                	mov    %esi,%ebx
f0103e9c:	80 fb 19             	cmp    $0x19,%bl
f0103e9f:	77 29                	ja     f0103eca <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103ea1:	0f be d2             	movsbl %dl,%edx
f0103ea4:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103ea7:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103eaa:	7d 30                	jge    f0103edc <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103eac:	83 c1 01             	add    $0x1,%ecx
f0103eaf:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103eb3:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103eb5:	0f b6 11             	movzbl (%ecx),%edx
f0103eb8:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103ebb:	89 f3                	mov    %esi,%ebx
f0103ebd:	80 fb 09             	cmp    $0x9,%bl
f0103ec0:	77 d5                	ja     f0103e97 <strtol+0x80>
			dig = *s - '0';
f0103ec2:	0f be d2             	movsbl %dl,%edx
f0103ec5:	83 ea 30             	sub    $0x30,%edx
f0103ec8:	eb dd                	jmp    f0103ea7 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103eca:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103ecd:	89 f3                	mov    %esi,%ebx
f0103ecf:	80 fb 19             	cmp    $0x19,%bl
f0103ed2:	77 08                	ja     f0103edc <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103ed4:	0f be d2             	movsbl %dl,%edx
f0103ed7:	83 ea 37             	sub    $0x37,%edx
f0103eda:	eb cb                	jmp    f0103ea7 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103edc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103ee0:	74 05                	je     f0103ee7 <strtol+0xd0>
		*endptr = (char *) s;
f0103ee2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ee5:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103ee7:	89 c2                	mov    %eax,%edx
f0103ee9:	f7 da                	neg    %edx
f0103eeb:	85 ff                	test   %edi,%edi
f0103eed:	0f 45 c2             	cmovne %edx,%eax
}
f0103ef0:	5b                   	pop    %ebx
f0103ef1:	5e                   	pop    %esi
f0103ef2:	5f                   	pop    %edi
f0103ef3:	5d                   	pop    %ebp
f0103ef4:	c3                   	ret    
f0103ef5:	66 90                	xchg   %ax,%ax
f0103ef7:	66 90                	xchg   %ax,%ax
f0103ef9:	66 90                	xchg   %ax,%ax
f0103efb:	66 90                	xchg   %ax,%ax
f0103efd:	66 90                	xchg   %ax,%ax
f0103eff:	90                   	nop

f0103f00 <__udivdi3>:
f0103f00:	55                   	push   %ebp
f0103f01:	57                   	push   %edi
f0103f02:	56                   	push   %esi
f0103f03:	53                   	push   %ebx
f0103f04:	83 ec 1c             	sub    $0x1c,%esp
f0103f07:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103f0b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103f0f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103f13:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103f17:	85 d2                	test   %edx,%edx
f0103f19:	75 35                	jne    f0103f50 <__udivdi3+0x50>
f0103f1b:	39 f3                	cmp    %esi,%ebx
f0103f1d:	0f 87 bd 00 00 00    	ja     f0103fe0 <__udivdi3+0xe0>
f0103f23:	85 db                	test   %ebx,%ebx
f0103f25:	89 d9                	mov    %ebx,%ecx
f0103f27:	75 0b                	jne    f0103f34 <__udivdi3+0x34>
f0103f29:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f2e:	31 d2                	xor    %edx,%edx
f0103f30:	f7 f3                	div    %ebx
f0103f32:	89 c1                	mov    %eax,%ecx
f0103f34:	31 d2                	xor    %edx,%edx
f0103f36:	89 f0                	mov    %esi,%eax
f0103f38:	f7 f1                	div    %ecx
f0103f3a:	89 c6                	mov    %eax,%esi
f0103f3c:	89 e8                	mov    %ebp,%eax
f0103f3e:	89 f7                	mov    %esi,%edi
f0103f40:	f7 f1                	div    %ecx
f0103f42:	89 fa                	mov    %edi,%edx
f0103f44:	83 c4 1c             	add    $0x1c,%esp
f0103f47:	5b                   	pop    %ebx
f0103f48:	5e                   	pop    %esi
f0103f49:	5f                   	pop    %edi
f0103f4a:	5d                   	pop    %ebp
f0103f4b:	c3                   	ret    
f0103f4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f50:	39 f2                	cmp    %esi,%edx
f0103f52:	77 7c                	ja     f0103fd0 <__udivdi3+0xd0>
f0103f54:	0f bd fa             	bsr    %edx,%edi
f0103f57:	83 f7 1f             	xor    $0x1f,%edi
f0103f5a:	0f 84 98 00 00 00    	je     f0103ff8 <__udivdi3+0xf8>
f0103f60:	89 f9                	mov    %edi,%ecx
f0103f62:	b8 20 00 00 00       	mov    $0x20,%eax
f0103f67:	29 f8                	sub    %edi,%eax
f0103f69:	d3 e2                	shl    %cl,%edx
f0103f6b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103f6f:	89 c1                	mov    %eax,%ecx
f0103f71:	89 da                	mov    %ebx,%edx
f0103f73:	d3 ea                	shr    %cl,%edx
f0103f75:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103f79:	09 d1                	or     %edx,%ecx
f0103f7b:	89 f2                	mov    %esi,%edx
f0103f7d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f81:	89 f9                	mov    %edi,%ecx
f0103f83:	d3 e3                	shl    %cl,%ebx
f0103f85:	89 c1                	mov    %eax,%ecx
f0103f87:	d3 ea                	shr    %cl,%edx
f0103f89:	89 f9                	mov    %edi,%ecx
f0103f8b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103f8f:	d3 e6                	shl    %cl,%esi
f0103f91:	89 eb                	mov    %ebp,%ebx
f0103f93:	89 c1                	mov    %eax,%ecx
f0103f95:	d3 eb                	shr    %cl,%ebx
f0103f97:	09 de                	or     %ebx,%esi
f0103f99:	89 f0                	mov    %esi,%eax
f0103f9b:	f7 74 24 08          	divl   0x8(%esp)
f0103f9f:	89 d6                	mov    %edx,%esi
f0103fa1:	89 c3                	mov    %eax,%ebx
f0103fa3:	f7 64 24 0c          	mull   0xc(%esp)
f0103fa7:	39 d6                	cmp    %edx,%esi
f0103fa9:	72 0c                	jb     f0103fb7 <__udivdi3+0xb7>
f0103fab:	89 f9                	mov    %edi,%ecx
f0103fad:	d3 e5                	shl    %cl,%ebp
f0103faf:	39 c5                	cmp    %eax,%ebp
f0103fb1:	73 5d                	jae    f0104010 <__udivdi3+0x110>
f0103fb3:	39 d6                	cmp    %edx,%esi
f0103fb5:	75 59                	jne    f0104010 <__udivdi3+0x110>
f0103fb7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103fba:	31 ff                	xor    %edi,%edi
f0103fbc:	89 fa                	mov    %edi,%edx
f0103fbe:	83 c4 1c             	add    $0x1c,%esp
f0103fc1:	5b                   	pop    %ebx
f0103fc2:	5e                   	pop    %esi
f0103fc3:	5f                   	pop    %edi
f0103fc4:	5d                   	pop    %ebp
f0103fc5:	c3                   	ret    
f0103fc6:	8d 76 00             	lea    0x0(%esi),%esi
f0103fc9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103fd0:	31 ff                	xor    %edi,%edi
f0103fd2:	31 c0                	xor    %eax,%eax
f0103fd4:	89 fa                	mov    %edi,%edx
f0103fd6:	83 c4 1c             	add    $0x1c,%esp
f0103fd9:	5b                   	pop    %ebx
f0103fda:	5e                   	pop    %esi
f0103fdb:	5f                   	pop    %edi
f0103fdc:	5d                   	pop    %ebp
f0103fdd:	c3                   	ret    
f0103fde:	66 90                	xchg   %ax,%ax
f0103fe0:	31 ff                	xor    %edi,%edi
f0103fe2:	89 e8                	mov    %ebp,%eax
f0103fe4:	89 f2                	mov    %esi,%edx
f0103fe6:	f7 f3                	div    %ebx
f0103fe8:	89 fa                	mov    %edi,%edx
f0103fea:	83 c4 1c             	add    $0x1c,%esp
f0103fed:	5b                   	pop    %ebx
f0103fee:	5e                   	pop    %esi
f0103fef:	5f                   	pop    %edi
f0103ff0:	5d                   	pop    %ebp
f0103ff1:	c3                   	ret    
f0103ff2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ff8:	39 f2                	cmp    %esi,%edx
f0103ffa:	72 06                	jb     f0104002 <__udivdi3+0x102>
f0103ffc:	31 c0                	xor    %eax,%eax
f0103ffe:	39 eb                	cmp    %ebp,%ebx
f0104000:	77 d2                	ja     f0103fd4 <__udivdi3+0xd4>
f0104002:	b8 01 00 00 00       	mov    $0x1,%eax
f0104007:	eb cb                	jmp    f0103fd4 <__udivdi3+0xd4>
f0104009:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104010:	89 d8                	mov    %ebx,%eax
f0104012:	31 ff                	xor    %edi,%edi
f0104014:	eb be                	jmp    f0103fd4 <__udivdi3+0xd4>
f0104016:	66 90                	xchg   %ax,%ax
f0104018:	66 90                	xchg   %ax,%ax
f010401a:	66 90                	xchg   %ax,%ax
f010401c:	66 90                	xchg   %ax,%ax
f010401e:	66 90                	xchg   %ax,%ax

f0104020 <__umoddi3>:
f0104020:	55                   	push   %ebp
f0104021:	57                   	push   %edi
f0104022:	56                   	push   %esi
f0104023:	53                   	push   %ebx
f0104024:	83 ec 1c             	sub    $0x1c,%esp
f0104027:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010402b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010402f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104033:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104037:	85 ed                	test   %ebp,%ebp
f0104039:	89 f0                	mov    %esi,%eax
f010403b:	89 da                	mov    %ebx,%edx
f010403d:	75 19                	jne    f0104058 <__umoddi3+0x38>
f010403f:	39 df                	cmp    %ebx,%edi
f0104041:	0f 86 b1 00 00 00    	jbe    f01040f8 <__umoddi3+0xd8>
f0104047:	f7 f7                	div    %edi
f0104049:	89 d0                	mov    %edx,%eax
f010404b:	31 d2                	xor    %edx,%edx
f010404d:	83 c4 1c             	add    $0x1c,%esp
f0104050:	5b                   	pop    %ebx
f0104051:	5e                   	pop    %esi
f0104052:	5f                   	pop    %edi
f0104053:	5d                   	pop    %ebp
f0104054:	c3                   	ret    
f0104055:	8d 76 00             	lea    0x0(%esi),%esi
f0104058:	39 dd                	cmp    %ebx,%ebp
f010405a:	77 f1                	ja     f010404d <__umoddi3+0x2d>
f010405c:	0f bd cd             	bsr    %ebp,%ecx
f010405f:	83 f1 1f             	xor    $0x1f,%ecx
f0104062:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104066:	0f 84 b4 00 00 00    	je     f0104120 <__umoddi3+0x100>
f010406c:	b8 20 00 00 00       	mov    $0x20,%eax
f0104071:	89 c2                	mov    %eax,%edx
f0104073:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104077:	29 c2                	sub    %eax,%edx
f0104079:	89 c1                	mov    %eax,%ecx
f010407b:	89 f8                	mov    %edi,%eax
f010407d:	d3 e5                	shl    %cl,%ebp
f010407f:	89 d1                	mov    %edx,%ecx
f0104081:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104085:	d3 e8                	shr    %cl,%eax
f0104087:	09 c5                	or     %eax,%ebp
f0104089:	8b 44 24 04          	mov    0x4(%esp),%eax
f010408d:	89 c1                	mov    %eax,%ecx
f010408f:	d3 e7                	shl    %cl,%edi
f0104091:	89 d1                	mov    %edx,%ecx
f0104093:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104097:	89 df                	mov    %ebx,%edi
f0104099:	d3 ef                	shr    %cl,%edi
f010409b:	89 c1                	mov    %eax,%ecx
f010409d:	89 f0                	mov    %esi,%eax
f010409f:	d3 e3                	shl    %cl,%ebx
f01040a1:	89 d1                	mov    %edx,%ecx
f01040a3:	89 fa                	mov    %edi,%edx
f01040a5:	d3 e8                	shr    %cl,%eax
f01040a7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01040ac:	09 d8                	or     %ebx,%eax
f01040ae:	f7 f5                	div    %ebp
f01040b0:	d3 e6                	shl    %cl,%esi
f01040b2:	89 d1                	mov    %edx,%ecx
f01040b4:	f7 64 24 08          	mull   0x8(%esp)
f01040b8:	39 d1                	cmp    %edx,%ecx
f01040ba:	89 c3                	mov    %eax,%ebx
f01040bc:	89 d7                	mov    %edx,%edi
f01040be:	72 06                	jb     f01040c6 <__umoddi3+0xa6>
f01040c0:	75 0e                	jne    f01040d0 <__umoddi3+0xb0>
f01040c2:	39 c6                	cmp    %eax,%esi
f01040c4:	73 0a                	jae    f01040d0 <__umoddi3+0xb0>
f01040c6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01040ca:	19 ea                	sbb    %ebp,%edx
f01040cc:	89 d7                	mov    %edx,%edi
f01040ce:	89 c3                	mov    %eax,%ebx
f01040d0:	89 ca                	mov    %ecx,%edx
f01040d2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01040d7:	29 de                	sub    %ebx,%esi
f01040d9:	19 fa                	sbb    %edi,%edx
f01040db:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01040df:	89 d0                	mov    %edx,%eax
f01040e1:	d3 e0                	shl    %cl,%eax
f01040e3:	89 d9                	mov    %ebx,%ecx
f01040e5:	d3 ee                	shr    %cl,%esi
f01040e7:	d3 ea                	shr    %cl,%edx
f01040e9:	09 f0                	or     %esi,%eax
f01040eb:	83 c4 1c             	add    $0x1c,%esp
f01040ee:	5b                   	pop    %ebx
f01040ef:	5e                   	pop    %esi
f01040f0:	5f                   	pop    %edi
f01040f1:	5d                   	pop    %ebp
f01040f2:	c3                   	ret    
f01040f3:	90                   	nop
f01040f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01040f8:	85 ff                	test   %edi,%edi
f01040fa:	89 f9                	mov    %edi,%ecx
f01040fc:	75 0b                	jne    f0104109 <__umoddi3+0xe9>
f01040fe:	b8 01 00 00 00       	mov    $0x1,%eax
f0104103:	31 d2                	xor    %edx,%edx
f0104105:	f7 f7                	div    %edi
f0104107:	89 c1                	mov    %eax,%ecx
f0104109:	89 d8                	mov    %ebx,%eax
f010410b:	31 d2                	xor    %edx,%edx
f010410d:	f7 f1                	div    %ecx
f010410f:	89 f0                	mov    %esi,%eax
f0104111:	f7 f1                	div    %ecx
f0104113:	e9 31 ff ff ff       	jmp    f0104049 <__umoddi3+0x29>
f0104118:	90                   	nop
f0104119:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104120:	39 dd                	cmp    %ebx,%ebp
f0104122:	72 08                	jb     f010412c <__umoddi3+0x10c>
f0104124:	39 f7                	cmp    %esi,%edi
f0104126:	0f 87 21 ff ff ff    	ja     f010404d <__umoddi3+0x2d>
f010412c:	89 da                	mov    %ebx,%edx
f010412e:	89 f0                	mov    %esi,%eax
f0104130:	29 f8                	sub    %edi,%eax
f0104132:	19 ea                	sbb    %ebp,%edx
f0104134:	e9 14 ff ff ff       	jmp    f010404d <__umoddi3+0x2d>
