
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 30 11 f0       	mov    $0xf0113000,%esp

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
f010004c:	81 c3 bc 42 01 00    	add    $0x142bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 60 11 f0    	mov    $0xf0116060,%edx
f0100058:	c7 c0 a0 66 11 f0    	mov    $0xf01166a0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 ff 23 00 00       	call   f0102468 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 b8 e5 fe ff    	lea    -0x11a48(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 d5 17 00 00       	call   f0101857 <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 03 0d 00 00       	call   f0100d8a <mem_init>
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
f01000a7:	81 c3 61 42 01 00    	add    $0x14261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 a4 66 11 f0    	mov    $0xf01166a4,%eax
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
f01000da:	8d 83 d3 e5 fe ff    	lea    -0x11a2d(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 71 17 00 00       	call   f0101857 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 30 17 00 00       	call   f0101820 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 0f e6 fe ff    	lea    -0x119f1(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 59 17 00 00       	call   f0101857 <cprintf>
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
f010010d:	81 c3 fb 41 01 00    	add    $0x141fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 eb e5 fe ff    	lea    -0x11a15(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 2c 17 00 00       	call   f0101857 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 e9 16 00 00       	call   f0101820 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 0f e6 fe ff    	lea    -0x119f1(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 12 17 00 00       	call   f0101857 <cprintf>
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
f010017c:	81 c3 8c 41 01 00    	add    $0x1418c,%ebx
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
f010018f:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010019e:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
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
f01001c7:	81 c3 41 41 01 00    	add    $0x14141,%ebx
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
f01001fb:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 38 e7 fe 	movzbl -0x118c8(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 38 e6 fe 	movzbl -0x119c8(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
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
f010026a:	8d 83 05 e6 fe ff    	lea    -0x119fb(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 e1 15 00 00       	call   f0101857 <cprintf>
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
f0100286:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
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
f010029b:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 38 e7 fe 	movzbl -0x118c8(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
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
f01002fd:	81 c3 0b 40 01 00    	add    $0x1400b,%ebx
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
f01003bc:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
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
f0100423:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
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
f0100495:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 de 1f 00 00       	call   f01024b5 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 fe 3d 01 00       	add    $0x13dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b be fe ff    	lea    -0x141b5(%eax),%eax
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
f0100538:	05 d0 3d 01 00       	add    $0x13dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 be fe ff    	lea    -0x1414b(%eax),%eax
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
f0100556:	81 c3 b2 3d 01 00    	add    $0x13db2,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f0100582:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
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
f0100598:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
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
f01005b2:	81 c3 56 3d 01 00    	add    $0x13d56,%ebx
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
f01005d9:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
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
f0100612:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
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
f0100675:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
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
f010069c:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 11 e6 fe ff    	lea    -0x119ef(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 96 11 00 00       	call   f0101857 <cprintf>
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
f01006ff:	81 c3 09 3c 01 00    	add    $0x13c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 38 e8 fe ff    	lea    -0x117c8(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 56 e8 fe ff    	lea    -0x117aa(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 5b e8 fe ff    	lea    -0x117a5(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 35 11 00 00       	call   f0101857 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 18 e9 fe ff    	lea    -0x116e8(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 64 e8 fe ff    	lea    -0x1179c(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 1e 11 00 00       	call   f0101857 <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 40 e9 fe ff    	lea    -0x116c0(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 6d e8 fe ff    	lea    -0x11793(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 07 11 00 00       	call   f0101857 <cprintf>
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
f010076a:	81 c3 9e 3b 01 00    	add    $0x13b9e,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100770:	8d 83 77 e8 fe ff    	lea    -0x11789(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 db 10 00 00       	call   f0101857 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f0100785:	8d 83 64 e9 fe ff    	lea    -0x1169c(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 c6 10 00 00       	call   f0101857 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 8c e9 fe ff    	lea    -0x11674(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 a9 10 00 00       	call   f0101857 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 a9 28 10 f0    	mov    $0xf01028a9,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 b0 e9 fe ff    	lea    -0x11650(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 8c 10 00 00       	call   f0101857 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 60 11 f0    	mov    $0xf0116060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 d4 e9 fe ff    	lea    -0x1162c(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 6f 10 00 00       	call   f0101857 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 a0 66 11 f0    	mov    $0xf01166a0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 f8 e9 fe ff    	lea    -0x11608(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 52 10 00 00       	call   f0101857 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 1c ea fe ff    	lea    -0x115e4(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 37 10 00 00       	call   f0101857 <cprintf>
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
f010083b:	81 c3 cd 3a 01 00    	add    $0x13acd,%ebx
	// Your code here.
	cprintf("Stack backtrace:\n");
f0100841:	8d 83 90 e8 fe ff    	lea    -0x11770(%ebx),%eax
f0100847:	50                   	push   %eax
f0100848:	e8 0a 10 00 00       	call   f0101857 <cprintf>

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
f0100852:	8d 83 a2 e8 fe ff    	lea    -0x1175e(%ebx),%eax
f0100858:	89 45 b8             	mov    %eax,-0x48(%ebp)
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
f010085b:	8d 83 bd e8 fe ff    	lea    -0x11743(%ebx),%eax
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
f010087c:	e8 d6 0f 00 00       	call   f0101857 <cprintf>
f0100881:	8d 77 08             	lea    0x8(%edi),%esi
f0100884:	83 c7 1c             	add    $0x1c,%edi
f0100887:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	ff 36                	pushl  (%esi)
f010088f:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100892:	e8 c0 0f 00 00       	call   f0101857 <cprintf>
f0100897:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	39 fe                	cmp    %edi,%esi
f010089f:	75 e9                	jne    f010088a <mon_backtrace+0x5d>
		}
		cprintf("\n");
f01008a1:	83 ec 0c             	sub    $0xc,%esp
f01008a4:	8d 83 0f e6 fe ff    	lea    -0x119f1(%ebx),%eax
f01008aa:	50                   	push   %eax
f01008ab:	e8 a7 0f 00 00       	call   f0101857 <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008b0:	83 c4 08             	add    $0x8,%esp
f01008b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008b6:	50                   	push   %eax
f01008b7:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008ba:	57                   	push   %edi
f01008bb:	e8 9b 10 00 00       	call   f010195b <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f01008c0:	83 c4 0c             	add    $0xc,%esp
f01008c3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008c9:	8d 83 c3 e8 fe ff    	lea    -0x1173d(%ebx),%eax
f01008cf:	50                   	push   %eax
f01008d0:	e8 82 0f 00 00       	call   f0101857 <cprintf>
		// for (int i = 0; i < info.eip_fn_namelen;++i){
		// 	cprintf("%c", info.eip_fn_name[i]);
		// }
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f01008d5:	89 f8                	mov    %edi,%eax
f01008d7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008da:	50                   	push   %eax
f01008db:	ff 75 d8             	pushl  -0x28(%ebp)
f01008de:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e1:	8d 83 d3 e8 fe ff    	lea    -0x1172d(%ebx),%eax
f01008e7:	50                   	push   %eax
f01008e8:	e8 6a 0f 00 00       	call   f0101857 <cprintf>
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
f0100916:	81 c3 f2 39 01 00    	add    $0x139f2,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010091c:	8d 83 48 ea fe ff    	lea    -0x115b8(%ebx),%eax
f0100922:	50                   	push   %eax
f0100923:	e8 2f 0f 00 00       	call   f0101857 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100928:	8d 83 6c ea fe ff    	lea    -0x11594(%ebx),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 21 0f 00 00       	call   f0101857 <cprintf>
f0100936:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100939:	8d bb e0 e8 fe ff    	lea    -0x11720(%ebx),%edi
f010093f:	eb 4a                	jmp    f010098b <monitor+0x83>
f0100941:	83 ec 08             	sub    $0x8,%esp
f0100944:	0f be c0             	movsbl %al,%eax
f0100947:	50                   	push   %eax
f0100948:	57                   	push   %edi
f0100949:	e8 dd 1a 00 00       	call   f010242b <strchr>
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
f010097c:	8d 83 e5 e8 fe ff    	lea    -0x1171b(%ebx),%eax
f0100982:	50                   	push   %eax
f0100983:	e8 cf 0e 00 00       	call   f0101857 <cprintf>
f0100988:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010098b:	8d 83 dc e8 fe ff    	lea    -0x11724(%ebx),%eax
f0100991:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100994:	83 ec 0c             	sub    $0xc,%esp
f0100997:	ff 75 a4             	pushl  -0x5c(%ebp)
f010099a:	e8 54 18 00 00       	call   f01021f3 <readline>
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
f01009ca:	e8 5c 1a 00 00       	call   f010242b <strchr>
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
f01009f0:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009f6:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f01009fd:	83 ec 08             	sub    $0x8,%esp
f0100a00:	ff 36                	pushl  (%esi)
f0100a02:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a05:	e8 c3 19 00 00       	call   f01023cd <strcmp>
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
f0100a26:	8d 83 02 e9 fe ff    	lea    -0x116fe(%ebx),%eax
f0100a2c:	50                   	push   %eax
f0100a2d:	e8 25 0e 00 00       	call   f0101857 <cprintf>
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
f0100a4d:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
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
f0100a6a:	e8 55 0d 00 00       	call   f01017c4 <__x86.get_pc_thunk.dx>
f0100a6f:	81 c2 99 38 01 00    	add    $0x13899,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a75:	83 ba 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%edx)
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
f0100a82:	8b 8a 90 1f 00 00    	mov    0x1f90(%edx),%ecx
	}

	return NULL;
}
f0100a88:	89 c8                	mov    %ecx,%eax
f0100a8a:	5d                   	pop    %ebp
f0100a8b:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a8c:	c7 c1 a0 66 11 f0    	mov    $0xf01166a0,%ecx
f0100a92:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100a98:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100a9e:	89 8a 90 1f 00 00    	mov    %ecx,0x1f90(%edx)
f0100aa4:	eb d8                	jmp    f0100a7e <boot_alloc+0x17>
		result = nextfree;
f0100aa6:	8b 8a 90 1f 00 00    	mov    0x1f90(%edx),%ecx
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100aac:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0100ab3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ab8:	89 82 90 1f 00 00    	mov    %eax,0x1f90(%edx)
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
f0100ace:	81 c3 3a 38 01 00    	add    $0x1383a,%ebx
f0100ad4:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ad6:	50                   	push   %eax
f0100ad7:	e8 f4 0c 00 00       	call   f01017d0 <mc146818_read>
f0100adc:	89 c6                	mov    %eax,%esi
f0100ade:	83 c7 01             	add    $0x1,%edi
f0100ae1:	89 3c 24             	mov    %edi,(%esp)
f0100ae4:	e8 e7 0c 00 00       	call   f01017d0 <mc146818_read>
f0100ae9:	c1 e0 08             	shl    $0x8,%eax
f0100aec:	09 f0                	or     %esi,%eax
}
f0100aee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100af1:	5b                   	pop    %ebx
f0100af2:	5e                   	pop    %esi
f0100af3:	5f                   	pop    %edi
f0100af4:	5d                   	pop    %ebp
f0100af5:	c3                   	ret    

f0100af6 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100af6:	55                   	push   %ebp
f0100af7:	89 e5                	mov    %esp,%ebp
f0100af9:	53                   	push   %ebx
f0100afa:	83 ec 04             	sub    $0x4,%esp
f0100afd:	e8 c2 0c 00 00       	call   f01017c4 <__x86.get_pc_thunk.dx>
f0100b02:	81 c2 06 38 01 00    	add    $0x13806,%edx
	return (pp - pages) << PGSHIFT;
f0100b08:	c7 c1 b0 66 11 f0    	mov    $0xf01166b0,%ecx
f0100b0e:	2b 01                	sub    (%ecx),%eax
f0100b10:	c1 f8 03             	sar    $0x3,%eax
f0100b13:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100b16:	89 c1                	mov    %eax,%ecx
f0100b18:	c1 e9 0c             	shr    $0xc,%ecx
f0100b1b:	c7 c3 a8 66 11 f0    	mov    $0xf01166a8,%ebx
f0100b21:	39 0b                	cmp    %ecx,(%ebx)
f0100b23:	76 0a                	jbe    f0100b2f <page2kva+0x39>
	return (void *)(pa + KERNBASE);
f0100b25:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return KADDR(page2pa(pp));
}
f0100b2a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b2d:	c9                   	leave  
f0100b2e:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b2f:	50                   	push   %eax
f0100b30:	8d 82 94 ea fe ff    	lea    -0x1156c(%edx),%eax
f0100b36:	50                   	push   %eax
f0100b37:	6a 59                	push   $0x59
f0100b39:	8d 82 90 ec fe ff    	lea    -0x11370(%edx),%eax
f0100b3f:	50                   	push   %eax
f0100b40:	89 d3                	mov    %edx,%ebx
f0100b42:	e8 52 f5 ff ff       	call   f0100099 <_panic>

f0100b47 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b47:	55                   	push   %ebp
f0100b48:	89 e5                	mov    %esp,%ebp
f0100b4a:	56                   	push   %esi
f0100b4b:	53                   	push   %ebx
f0100b4c:	e8 77 0c 00 00       	call   f01017c8 <__x86.get_pc_thunk.cx>
f0100b51:	81 c1 b7 37 01 00    	add    $0x137b7,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b57:	89 d3                	mov    %edx,%ebx
f0100b59:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b5c:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b5f:	a8 01                	test   $0x1,%al
f0100b61:	74 5a                	je     f0100bbd <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b63:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100b68:	89 c6                	mov    %eax,%esi
f0100b6a:	c1 ee 0c             	shr    $0xc,%esi
f0100b6d:	c7 c3 a8 66 11 f0    	mov    $0xf01166a8,%ebx
f0100b73:	3b 33                	cmp    (%ebx),%esi
f0100b75:	73 2b                	jae    f0100ba2 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b77:	c1 ea 0c             	shr    $0xc,%edx
f0100b7a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b80:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b87:	89 c2                	mov    %eax,%edx
f0100b89:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b8c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b91:	85 d2                	test   %edx,%edx
f0100b93:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b98:	0f 44 c2             	cmove  %edx,%eax
}
f0100b9b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b9e:	5b                   	pop    %ebx
f0100b9f:	5e                   	pop    %esi
f0100ba0:	5d                   	pop    %ebp
f0100ba1:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba2:	50                   	push   %eax
f0100ba3:	8d 81 94 ea fe ff    	lea    -0x1156c(%ecx),%eax
f0100ba9:	50                   	push   %eax
f0100baa:	68 ae 02 00 00       	push   $0x2ae
f0100baf:	8d 81 9e ec fe ff    	lea    -0x11362(%ecx),%eax
f0100bb5:	50                   	push   %eax
f0100bb6:	89 cb                	mov    %ecx,%ebx
f0100bb8:	e8 dc f4 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100bbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bc2:	eb d7                	jmp    f0100b9b <check_va2pa+0x54>

f0100bc4 <page_init>:
{
f0100bc4:	55                   	push   %ebp
f0100bc5:	89 e5                	mov    %esp,%ebp
f0100bc7:	57                   	push   %edi
f0100bc8:	56                   	push   %esi
f0100bc9:	53                   	push   %ebx
f0100bca:	83 ec 2c             	sub    $0x2c,%esp
f0100bcd:	e8 fa 0b 00 00       	call   f01017cc <__x86.get_pc_thunk.si>
f0100bd2:	81 c6 36 37 01 00    	add    $0x13736,%esi
	physaddr_t truly_end = PADDR(boot_alloc(0));
f0100bd8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bdd:	e8 85 fe ff ff       	call   f0100a67 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100be2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100be7:	76 33                	jbe    f0100c1c <page_init+0x58>
	return (physaddr_t)kva - KERNBASE;
f0100be9:	05 00 00 00 10       	add    $0x10000000,%eax
f0100bee:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100bf1:	8b 86 94 1f 00 00    	mov    0x1f94(%esi),%eax
f0100bf7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < npages; i++)
f0100bfa:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
f0100bfe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c03:	c7 c3 a8 66 11 f0    	mov    $0xf01166a8,%ebx
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
f0100c09:	c7 c2 b0 66 11 f0    	mov    $0xf01166b0,%edx
f0100c0f:	89 55 d8             	mov    %edx,-0x28(%ebp)
			page_free_list = &pages[i];
f0100c12:	89 55 d0             	mov    %edx,-0x30(%ebp)
			pages[i].pp_ref = 1;
f0100c15:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100c18:	89 c1                	mov    %eax,%ecx
	for (i = 0; i < npages; i++)
f0100c1a:	eb 55                	jmp    f0100c71 <page_init+0xad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c1c:	50                   	push   %eax
f0100c1d:	8d 86 b8 ea fe ff    	lea    -0x11548(%esi),%eax
f0100c23:	50                   	push   %eax
f0100c24:	68 11 01 00 00       	push   $0x111
f0100c29:	8d 86 9e ec fe ff    	lea    -0x11362(%esi),%eax
f0100c2f:	50                   	push   %eax
f0100c30:	89 f3                	mov    %esi,%ebx
f0100c32:	e8 62 f4 ff ff       	call   f0100099 <_panic>
f0100c37:	8d 04 cd 00 00 00 00 	lea    0x0(,%ecx,8),%eax
		}else if(page2pa(pages+i)>=IOPHYSMEM&&page2pa(pages+i)<truly_end){
f0100c3e:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100c41:	89 c2                	mov    %eax,%edx
f0100c43:	03 17                	add    (%edi),%edx
	return (pp - pages) << PGSHIFT;
f0100c45:	89 c7                	mov    %eax,%edi
f0100c47:	c1 e7 09             	shl    $0x9,%edi
f0100c4a:	39 7d dc             	cmp    %edi,-0x24(%ebp)
f0100c4d:	76 08                	jbe    f0100c57 <page_init+0x93>
f0100c4f:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f0100c55:	77 35                	ja     f0100c8c <page_init+0xc8>
			pages[i].pp_ref = 0;
f0100c57:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100c5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c60:	89 3a                	mov    %edi,(%edx)
			page_free_list = &pages[i];
f0100c62:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100c65:	03 02                	add    (%edx),%eax
f0100c67:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c6a:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
	for (i = 0; i < npages; i++)
f0100c6e:	83 c1 01             	add    $0x1,%ecx
f0100c71:	39 0b                	cmp    %ecx,(%ebx)
f0100c73:	76 25                	jbe    f0100c9a <page_init+0xd6>
		if(i==0){
f0100c75:	85 c9                	test   %ecx,%ecx
f0100c77:	75 be                	jne    f0100c37 <page_init+0x73>
			pages[i].pp_ref = 1;
f0100c79:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c7c:	8b 00                	mov    (%eax),%eax
f0100c7e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100c84:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100c8a:	eb e2                	jmp    f0100c6e <page_init+0xaa>
			pages[i].pp_ref = 1;
f0100c8c:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f0100c92:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100c98:	eb d4                	jmp    f0100c6e <page_init+0xaa>
f0100c9a:	80 7d e3 00          	cmpb   $0x0,-0x1d(%ebp)
f0100c9e:	75 08                	jne    f0100ca8 <page_init+0xe4>
}
f0100ca0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ca3:	5b                   	pop    %ebx
f0100ca4:	5e                   	pop    %esi
f0100ca5:	5f                   	pop    %edi
f0100ca6:	5d                   	pop    %ebp
f0100ca7:	c3                   	ret    
f0100ca8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cab:	89 86 94 1f 00 00    	mov    %eax,0x1f94(%esi)
f0100cb1:	eb ed                	jmp    f0100ca0 <page_init+0xdc>

f0100cb3 <page_alloc>:
{
f0100cb3:	55                   	push   %ebp
f0100cb4:	89 e5                	mov    %esp,%ebp
f0100cb6:	56                   	push   %esi
f0100cb7:	53                   	push   %ebx
f0100cb8:	e8 92 f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100cbd:	81 c3 4b 36 01 00    	add    $0x1364b,%ebx
	if(page_free_list){
f0100cc3:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
f0100cc9:	85 f6                	test   %esi,%esi
f0100ccb:	74 14                	je     f0100ce1 <page_alloc+0x2e>
		page_free_list = freePage->pp_link;
f0100ccd:	8b 06                	mov    (%esi),%eax
f0100ccf:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
		freePage->pp_link = NULL;
f0100cd5:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if(alloc_flags&ALLOC_ZERO){    // 只有这个条件满足时才把内存页面初始化为0
f0100cdb:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100cdf:	75 09                	jne    f0100cea <page_alloc+0x37>
}
f0100ce1:	89 f0                	mov    %esi,%eax
f0100ce3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ce6:	5b                   	pop    %ebx
f0100ce7:	5e                   	pop    %esi
f0100ce8:	5d                   	pop    %ebp
f0100ce9:	c3                   	ret    
f0100cea:	c7 c0 b0 66 11 f0    	mov    $0xf01166b0,%eax
f0100cf0:	89 f2                	mov    %esi,%edx
f0100cf2:	2b 10                	sub    (%eax),%edx
f0100cf4:	89 d0                	mov    %edx,%eax
f0100cf6:	c1 f8 03             	sar    $0x3,%eax
f0100cf9:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100cfc:	89 c1                	mov    %eax,%ecx
f0100cfe:	c1 e9 0c             	shr    $0xc,%ecx
f0100d01:	c7 c2 a8 66 11 f0    	mov    $0xf01166a8,%edx
f0100d07:	3b 0a                	cmp    (%edx),%ecx
f0100d09:	73 1a                	jae    f0100d25 <page_alloc+0x72>
			memset(page2kva(freePage), 0, PGSIZE);
f0100d0b:	83 ec 04             	sub    $0x4,%esp
f0100d0e:	68 00 10 00 00       	push   $0x1000
f0100d13:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100d15:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d1a:	50                   	push   %eax
f0100d1b:	e8 48 17 00 00       	call   f0102468 <memset>
f0100d20:	83 c4 10             	add    $0x10,%esp
f0100d23:	eb bc                	jmp    f0100ce1 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d25:	50                   	push   %eax
f0100d26:	8d 83 94 ea fe ff    	lea    -0x1156c(%ebx),%eax
f0100d2c:	50                   	push   %eax
f0100d2d:	6a 59                	push   $0x59
f0100d2f:	8d 83 90 ec fe ff    	lea    -0x11370(%ebx),%eax
f0100d35:	50                   	push   %eax
f0100d36:	e8 5e f3 ff ff       	call   f0100099 <_panic>

f0100d3b <page_free>:
{
f0100d3b:	55                   	push   %ebp
f0100d3c:	89 e5                	mov    %esp,%ebp
f0100d3e:	53                   	push   %ebx
f0100d3f:	83 ec 04             	sub    $0x4,%esp
f0100d42:	e8 08 f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100d47:	81 c3 c1 35 01 00    	add    $0x135c1,%ebx
f0100d4d:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_ref||pp->pp_link){
f0100d50:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d55:	75 18                	jne    f0100d6f <page_free+0x34>
f0100d57:	83 38 00             	cmpl   $0x0,(%eax)
f0100d5a:	75 13                	jne    f0100d6f <page_free+0x34>
	pp->pp_link = page_free_list;
f0100d5c:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f0100d62:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0100d64:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f0100d6a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d6d:	c9                   	leave  
f0100d6e:	c3                   	ret    
		panic("Page is free, have not to free\n");
f0100d6f:	83 ec 04             	sub    $0x4,%esp
f0100d72:	8d 83 dc ea fe ff    	lea    -0x11524(%ebx),%eax
f0100d78:	50                   	push   %eax
f0100d79:	68 4b 01 00 00       	push   $0x14b
f0100d7e:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0100d84:	50                   	push   %eax
f0100d85:	e8 0f f3 ff ff       	call   f0100099 <_panic>

f0100d8a <mem_init>:
{
f0100d8a:	55                   	push   %ebp
f0100d8b:	89 e5                	mov    %esp,%ebp
f0100d8d:	57                   	push   %edi
f0100d8e:	56                   	push   %esi
f0100d8f:	53                   	push   %ebx
f0100d90:	83 ec 3c             	sub    $0x3c,%esp
f0100d93:	e8 b7 f3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100d98:	81 c3 70 35 01 00    	add    $0x13570,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100d9e:	b8 15 00 00 00       	mov    $0x15,%eax
f0100da3:	e8 18 fd ff ff       	call   f0100ac0 <nvram_read>
f0100da8:	89 c7                	mov    %eax,%edi
	extmem = nvram_read(NVRAM_EXTLO);
f0100daa:	b8 17 00 00 00       	mov    $0x17,%eax
f0100daf:	e8 0c fd ff ff       	call   f0100ac0 <nvram_read>
f0100db4:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100db6:	b8 34 00 00 00       	mov    $0x34,%eax
f0100dbb:	e8 00 fd ff ff       	call   f0100ac0 <nvram_read>
f0100dc0:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100dc3:	85 c0                	test   %eax,%eax
f0100dc5:	75 0e                	jne    f0100dd5 <mem_init+0x4b>
		totalmem = basemem;
f0100dc7:	89 f8                	mov    %edi,%eax
	else if (extmem)
f0100dc9:	85 f6                	test   %esi,%esi
f0100dcb:	74 0d                	je     f0100dda <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f0100dcd:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100dd3:	eb 05                	jmp    f0100dda <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100dd5:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100dda:	89 c1                	mov    %eax,%ecx
f0100ddc:	c1 e9 02             	shr    $0x2,%ecx
f0100ddf:	c7 c2 a8 66 11 f0    	mov    $0xf01166a8,%edx
f0100de5:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100de7:	89 c2                	mov    %eax,%edx
f0100de9:	29 fa                	sub    %edi,%edx
f0100deb:	52                   	push   %edx
f0100dec:	57                   	push   %edi
f0100ded:	50                   	push   %eax
f0100dee:	8d 83 fc ea fe ff    	lea    -0x11504(%ebx),%eax
f0100df4:	50                   	push   %eax
f0100df5:	e8 5d 0a 00 00       	call   f0101857 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);    // 初始占一整页
f0100dfa:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100dff:	e8 63 fc ff ff       	call   f0100a67 <boot_alloc>
f0100e04:	c7 c6 ac 66 11 f0    	mov    $0xf01166ac,%esi
f0100e0a:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);   // 初始化为0
f0100e0c:	83 c4 0c             	add    $0xc,%esp
f0100e0f:	68 00 10 00 00       	push   $0x1000
f0100e14:	6a 00                	push   $0x0
f0100e16:	50                   	push   %eax
f0100e17:	e8 4c 16 00 00       	call   f0102468 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100e1c:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0100e1e:	83 c4 10             	add    $0x10,%esp
f0100e21:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e26:	77 19                	ja     f0100e41 <mem_init+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e28:	50                   	push   %eax
f0100e29:	8d 83 b8 ea fe ff    	lea    -0x11548(%ebx),%eax
f0100e2f:	50                   	push   %eax
f0100e30:	68 9b 00 00 00       	push   $0x9b
f0100e35:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0100e3b:	50                   	push   %eax
f0100e3c:	e8 58 f2 ff ff       	call   f0100099 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e41:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100e47:	83 ca 05             	or     $0x5,%edx
f0100e4a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0100e50:	c7 c6 a8 66 11 f0    	mov    $0xf01166a8,%esi
f0100e56:	8b 06                	mov    (%esi),%eax
f0100e58:	c1 e0 03             	shl    $0x3,%eax
f0100e5b:	e8 07 fc ff ff       	call   f0100a67 <boot_alloc>
f0100e60:	c7 c2 b0 66 11 f0    	mov    $0xf01166b0,%edx
f0100e66:	89 02                	mov    %eax,(%edx)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100e68:	83 ec 04             	sub    $0x4,%esp
f0100e6b:	8b 16                	mov    (%esi),%edx
f0100e6d:	c1 e2 03             	shl    $0x3,%edx
f0100e70:	52                   	push   %edx
f0100e71:	6a 00                	push   $0x0
f0100e73:	50                   	push   %eax
f0100e74:	e8 ef 15 00 00       	call   f0102468 <memset>
	page_init();
f0100e79:	e8 46 fd ff ff       	call   f0100bc4 <page_init>
	if (!page_free_list)
f0100e7e:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0100e84:	83 c4 10             	add    $0x10,%esp
f0100e87:	85 c0                	test   %eax,%eax
f0100e89:	74 5d                	je     f0100ee8 <mem_init+0x15e>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e8b:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e8e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e91:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e94:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e97:	c7 c1 b0 66 11 f0    	mov    $0xf01166b0,%ecx
f0100e9d:	89 c2                	mov    %eax,%edx
f0100e9f:	2b 11                	sub    (%ecx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ea1:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ea7:	0f 95 c2             	setne  %dl
f0100eaa:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ead:	8b 74 95 e0          	mov    -0x20(%ebp,%edx,4),%esi
f0100eb1:	89 06                	mov    %eax,(%esi)
			tp[pagetype] = &pp->pp_link;
f0100eb3:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100eb7:	8b 00                	mov    (%eax),%eax
f0100eb9:	85 c0                	test   %eax,%eax
f0100ebb:	75 e0                	jne    f0100e9d <mem_init+0x113>
		*tp[1] = 0;
f0100ebd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ec0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ec6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ec9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ecc:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ece:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100ed1:	89 b3 94 1f 00 00    	mov    %esi,0x1f94(%ebx)
f0100ed7:	c7 c7 b0 66 11 f0    	mov    $0xf01166b0,%edi
	if (PGNUM(pa) >= npages)
f0100edd:	c7 c0 a8 66 11 f0    	mov    $0xf01166a8,%eax
f0100ee3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100ee6:	eb 33                	jmp    f0100f1b <mem_init+0x191>
		panic("'page_free_list' is a null pointer!");
f0100ee8:	83 ec 04             	sub    $0x4,%esp
f0100eeb:	8d 83 38 eb fe ff    	lea    -0x114c8(%ebx),%eax
f0100ef1:	50                   	push   %eax
f0100ef2:	68 ef 01 00 00       	push   $0x1ef
f0100ef7:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0100efd:	50                   	push   %eax
f0100efe:	e8 96 f1 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f03:	52                   	push   %edx
f0100f04:	8d 83 94 ea fe ff    	lea    -0x1156c(%ebx),%eax
f0100f0a:	50                   	push   %eax
f0100f0b:	6a 59                	push   $0x59
f0100f0d:	8d 83 90 ec fe ff    	lea    -0x11370(%ebx),%eax
f0100f13:	50                   	push   %eax
f0100f14:	e8 80 f1 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f19:	8b 36                	mov    (%esi),%esi
f0100f1b:	85 f6                	test   %esi,%esi
f0100f1d:	74 3d                	je     f0100f5c <mem_init+0x1d2>
	return (pp - pages) << PGSHIFT;
f0100f1f:	89 f0                	mov    %esi,%eax
f0100f21:	2b 07                	sub    (%edi),%eax
f0100f23:	c1 f8 03             	sar    $0x3,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100f26:	89 c2                	mov    %eax,%edx
f0100f28:	c1 e2 0c             	shl    $0xc,%edx
f0100f2b:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100f30:	75 e7                	jne    f0100f19 <mem_init+0x18f>
	if (PGNUM(pa) >= npages)
f0100f32:	89 d0                	mov    %edx,%eax
f0100f34:	c1 e8 0c             	shr    $0xc,%eax
f0100f37:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100f3a:	3b 01                	cmp    (%ecx),%eax
f0100f3c:	73 c5                	jae    f0100f03 <mem_init+0x179>
			memset(page2kva(pp), 0x97, 128);
f0100f3e:	83 ec 04             	sub    $0x4,%esp
f0100f41:	68 80 00 00 00       	push   $0x80
f0100f46:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100f4b:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100f51:	52                   	push   %edx
f0100f52:	e8 11 15 00 00       	call   f0102468 <memset>
f0100f57:	83 c4 10             	add    $0x10,%esp
f0100f5a:	eb bd                	jmp    f0100f19 <mem_init+0x18f>
	first_free_page = (char *) boot_alloc(0);
f0100f5c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f61:	e8 01 fb ff ff       	call   f0100a67 <boot_alloc>
f0100f66:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f69:	8b 93 94 1f 00 00    	mov    0x1f94(%ebx),%edx
		assert(pp >= pages);
f0100f6f:	c7 c0 b0 66 11 f0    	mov    $0xf01166b0,%eax
f0100f75:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100f77:	c7 c0 a8 66 11 f0    	mov    $0xf01166a8,%eax
f0100f7d:	8b 00                	mov    (%eax),%eax
f0100f7f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100f82:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100f85:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f88:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100f8b:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f90:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0100f93:	e9 f3 00 00 00       	jmp    f010108b <mem_init+0x301>
		assert(pp >= pages);
f0100f98:	8d 83 aa ec fe ff    	lea    -0x11356(%ebx),%eax
f0100f9e:	50                   	push   %eax
f0100f9f:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0100fa5:	50                   	push   %eax
f0100fa6:	68 09 02 00 00       	push   $0x209
f0100fab:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0100fb1:	50                   	push   %eax
f0100fb2:	e8 e2 f0 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100fb7:	8d 83 cb ec fe ff    	lea    -0x11335(%ebx),%eax
f0100fbd:	50                   	push   %eax
f0100fbe:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0100fc4:	50                   	push   %eax
f0100fc5:	68 0a 02 00 00       	push   $0x20a
f0100fca:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0100fd0:	50                   	push   %eax
f0100fd1:	e8 c3 f0 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100fd6:	8d 83 5c eb fe ff    	lea    -0x114a4(%ebx),%eax
f0100fdc:	50                   	push   %eax
f0100fdd:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0100fe3:	50                   	push   %eax
f0100fe4:	68 0b 02 00 00       	push   $0x20b
f0100fe9:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0100fef:	50                   	push   %eax
f0100ff0:	e8 a4 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100ff5:	8d 83 df ec fe ff    	lea    -0x11321(%ebx),%eax
f0100ffb:	50                   	push   %eax
f0100ffc:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101002:	50                   	push   %eax
f0101003:	68 0e 02 00 00       	push   $0x20e
f0101008:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010100e:	50                   	push   %eax
f010100f:	e8 85 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101014:	8d 83 f0 ec fe ff    	lea    -0x11310(%ebx),%eax
f010101a:	50                   	push   %eax
f010101b:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101021:	50                   	push   %eax
f0101022:	68 0f 02 00 00       	push   $0x20f
f0101027:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010102d:	50                   	push   %eax
f010102e:	e8 66 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101033:	8d 83 90 eb fe ff    	lea    -0x11470(%ebx),%eax
f0101039:	50                   	push   %eax
f010103a:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101040:	50                   	push   %eax
f0101041:	68 10 02 00 00       	push   $0x210
f0101046:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010104c:	50                   	push   %eax
f010104d:	e8 47 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101052:	8d 83 09 ed fe ff    	lea    -0x112f7(%ebx),%eax
f0101058:	50                   	push   %eax
f0101059:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f010105f:	50                   	push   %eax
f0101060:	68 11 02 00 00       	push   $0x211
f0101065:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010106b:	50                   	push   %eax
f010106c:	e8 28 f0 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0101071:	89 c6                	mov    %eax,%esi
f0101073:	c1 ee 0c             	shr    $0xc,%esi
f0101076:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f0101079:	76 71                	jbe    f01010ec <mem_init+0x362>
	return (void *)(pa + KERNBASE);
f010107b:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101080:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101083:	77 7d                	ja     f0101102 <mem_init+0x378>
			++nfree_extmem;
f0101085:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101089:	8b 12                	mov    (%edx),%edx
f010108b:	85 d2                	test   %edx,%edx
f010108d:	0f 84 8e 00 00 00    	je     f0101121 <mem_init+0x397>
		assert(pp >= pages);
f0101093:	39 d1                	cmp    %edx,%ecx
f0101095:	0f 87 fd fe ff ff    	ja     f0100f98 <mem_init+0x20e>
		assert(pp < pages + npages);
f010109b:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f010109e:	0f 83 13 ff ff ff    	jae    f0100fb7 <mem_init+0x22d>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010a4:	89 d0                	mov    %edx,%eax
f01010a6:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01010a9:	a8 07                	test   $0x7,%al
f01010ab:	0f 85 25 ff ff ff    	jne    f0100fd6 <mem_init+0x24c>
	return (pp - pages) << PGSHIFT;
f01010b1:	c1 f8 03             	sar    $0x3,%eax
f01010b4:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f01010b7:	85 c0                	test   %eax,%eax
f01010b9:	0f 84 36 ff ff ff    	je     f0100ff5 <mem_init+0x26b>
		assert(page2pa(pp) != IOPHYSMEM);
f01010bf:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01010c4:	0f 84 4a ff ff ff    	je     f0101014 <mem_init+0x28a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01010ca:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f01010cf:	0f 84 5e ff ff ff    	je     f0101033 <mem_init+0x2a9>
		assert(page2pa(pp) != EXTPHYSMEM);
f01010d5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01010da:	0f 84 72 ff ff ff    	je     f0101052 <mem_init+0x2c8>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01010e0:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01010e5:	77 8a                	ja     f0101071 <mem_init+0x2e7>
			++nfree_basemem;
f01010e7:	83 c7 01             	add    $0x1,%edi
f01010ea:	eb 9d                	jmp    f0101089 <mem_init+0x2ff>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010ec:	50                   	push   %eax
f01010ed:	8d 83 94 ea fe ff    	lea    -0x1156c(%ebx),%eax
f01010f3:	50                   	push   %eax
f01010f4:	6a 59                	push   $0x59
f01010f6:	8d 83 90 ec fe ff    	lea    -0x11370(%ebx),%eax
f01010fc:	50                   	push   %eax
f01010fd:	e8 97 ef ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101102:	8d 83 b4 eb fe ff    	lea    -0x1144c(%ebx),%eax
f0101108:	50                   	push   %eax
f0101109:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f010110f:	50                   	push   %eax
f0101110:	68 12 02 00 00       	push   $0x212
f0101115:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010111b:	50                   	push   %eax
f010111c:	e8 78 ef ff ff       	call   f0100099 <_panic>
f0101121:	8b 75 cc             	mov    -0x34(%ebp),%esi
	assert(nfree_basemem > 0);
f0101124:	85 ff                	test   %edi,%edi
f0101126:	7e 2e                	jle    f0101156 <mem_init+0x3cc>
	assert(nfree_extmem > 0);
f0101128:	85 f6                	test   %esi,%esi
f010112a:	7e 49                	jle    f0101175 <mem_init+0x3eb>
	cprintf("check_page_free_list() succeeded!\n");
f010112c:	83 ec 0c             	sub    $0xc,%esp
f010112f:	8d 83 fc eb fe ff    	lea    -0x11404(%ebx),%eax
f0101135:	50                   	push   %eax
f0101136:	e8 1c 07 00 00       	call   f0101857 <cprintf>
	if (!pages)
f010113b:	83 c4 10             	add    $0x10,%esp
f010113e:	c7 c0 b0 66 11 f0    	mov    $0xf01166b0,%eax
f0101144:	83 38 00             	cmpl   $0x0,(%eax)
f0101147:	74 4b                	je     f0101194 <mem_init+0x40a>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101149:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f010114f:	be 00 00 00 00       	mov    $0x0,%esi
f0101154:	eb 5e                	jmp    f01011b4 <mem_init+0x42a>
	assert(nfree_basemem > 0);
f0101156:	8d 83 23 ed fe ff    	lea    -0x112dd(%ebx),%eax
f010115c:	50                   	push   %eax
f010115d:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101163:	50                   	push   %eax
f0101164:	68 1a 02 00 00       	push   $0x21a
f0101169:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010116f:	50                   	push   %eax
f0101170:	e8 24 ef ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0101175:	8d 83 35 ed fe ff    	lea    -0x112cb(%ebx),%eax
f010117b:	50                   	push   %eax
f010117c:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101182:	50                   	push   %eax
f0101183:	68 1b 02 00 00       	push   $0x21b
f0101188:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010118e:	50                   	push   %eax
f010118f:	e8 05 ef ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101194:	83 ec 04             	sub    $0x4,%esp
f0101197:	8d 83 46 ed fe ff    	lea    -0x112ba(%ebx),%eax
f010119d:	50                   	push   %eax
f010119e:	68 2e 02 00 00       	push   $0x22e
f01011a3:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01011a9:	50                   	push   %eax
f01011aa:	e8 ea ee ff ff       	call   f0100099 <_panic>
		++nfree;
f01011af:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011b2:	8b 00                	mov    (%eax),%eax
f01011b4:	85 c0                	test   %eax,%eax
f01011b6:	75 f7                	jne    f01011af <mem_init+0x425>
	assert((pp0 = page_alloc(0)));
f01011b8:	83 ec 0c             	sub    $0xc,%esp
f01011bb:	6a 00                	push   $0x0
f01011bd:	e8 f1 fa ff ff       	call   f0100cb3 <page_alloc>
f01011c2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011c5:	83 c4 10             	add    $0x10,%esp
f01011c8:	85 c0                	test   %eax,%eax
f01011ca:	0f 84 e7 01 00 00    	je     f01013b7 <mem_init+0x62d>
	assert((pp1 = page_alloc(0)));
f01011d0:	83 ec 0c             	sub    $0xc,%esp
f01011d3:	6a 00                	push   $0x0
f01011d5:	e8 d9 fa ff ff       	call   f0100cb3 <page_alloc>
f01011da:	89 c7                	mov    %eax,%edi
f01011dc:	83 c4 10             	add    $0x10,%esp
f01011df:	85 c0                	test   %eax,%eax
f01011e1:	0f 84 ef 01 00 00    	je     f01013d6 <mem_init+0x64c>
	assert((pp2 = page_alloc(0)));
f01011e7:	83 ec 0c             	sub    $0xc,%esp
f01011ea:	6a 00                	push   $0x0
f01011ec:	e8 c2 fa ff ff       	call   f0100cb3 <page_alloc>
f01011f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01011f4:	83 c4 10             	add    $0x10,%esp
f01011f7:	85 c0                	test   %eax,%eax
f01011f9:	0f 84 f6 01 00 00    	je     f01013f5 <mem_init+0x66b>
	assert(pp1 && pp1 != pp0);
f01011ff:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f0101202:	0f 84 0c 02 00 00    	je     f0101414 <mem_init+0x68a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101208:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010120b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010120e:	0f 84 1f 02 00 00    	je     f0101433 <mem_init+0x6a9>
f0101214:	39 c7                	cmp    %eax,%edi
f0101216:	0f 84 17 02 00 00    	je     f0101433 <mem_init+0x6a9>
	return (pp - pages) << PGSHIFT;
f010121c:	c7 c0 b0 66 11 f0    	mov    $0xf01166b0,%eax
f0101222:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101224:	c7 c0 a8 66 11 f0    	mov    $0xf01166a8,%eax
f010122a:	8b 10                	mov    (%eax),%edx
f010122c:	c1 e2 0c             	shl    $0xc,%edx
f010122f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101232:	29 c8                	sub    %ecx,%eax
f0101234:	c1 f8 03             	sar    $0x3,%eax
f0101237:	c1 e0 0c             	shl    $0xc,%eax
f010123a:	39 d0                	cmp    %edx,%eax
f010123c:	0f 83 10 02 00 00    	jae    f0101452 <mem_init+0x6c8>
f0101242:	89 f8                	mov    %edi,%eax
f0101244:	29 c8                	sub    %ecx,%eax
f0101246:	c1 f8 03             	sar    $0x3,%eax
f0101249:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010124c:	39 c2                	cmp    %eax,%edx
f010124e:	0f 86 1d 02 00 00    	jbe    f0101471 <mem_init+0x6e7>
f0101254:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101257:	29 c8                	sub    %ecx,%eax
f0101259:	c1 f8 03             	sar    $0x3,%eax
f010125c:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010125f:	39 c2                	cmp    %eax,%edx
f0101261:	0f 86 29 02 00 00    	jbe    f0101490 <mem_init+0x706>
	fl = page_free_list;
f0101267:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f010126d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101270:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f0101277:	00 00 00 
	assert(!page_alloc(0));
f010127a:	83 ec 0c             	sub    $0xc,%esp
f010127d:	6a 00                	push   $0x0
f010127f:	e8 2f fa ff ff       	call   f0100cb3 <page_alloc>
f0101284:	83 c4 10             	add    $0x10,%esp
f0101287:	85 c0                	test   %eax,%eax
f0101289:	0f 85 20 02 00 00    	jne    f01014af <mem_init+0x725>
	page_free(pp0);
f010128f:	83 ec 0c             	sub    $0xc,%esp
f0101292:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101295:	e8 a1 fa ff ff       	call   f0100d3b <page_free>
	page_free(pp1);
f010129a:	89 3c 24             	mov    %edi,(%esp)
f010129d:	e8 99 fa ff ff       	call   f0100d3b <page_free>
	page_free(pp2);
f01012a2:	83 c4 04             	add    $0x4,%esp
f01012a5:	ff 75 d0             	pushl  -0x30(%ebp)
f01012a8:	e8 8e fa ff ff       	call   f0100d3b <page_free>
	assert((pp0 = page_alloc(0)));
f01012ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012b4:	e8 fa f9 ff ff       	call   f0100cb3 <page_alloc>
f01012b9:	89 c7                	mov    %eax,%edi
f01012bb:	83 c4 10             	add    $0x10,%esp
f01012be:	85 c0                	test   %eax,%eax
f01012c0:	0f 84 08 02 00 00    	je     f01014ce <mem_init+0x744>
	assert((pp1 = page_alloc(0)));
f01012c6:	83 ec 0c             	sub    $0xc,%esp
f01012c9:	6a 00                	push   $0x0
f01012cb:	e8 e3 f9 ff ff       	call   f0100cb3 <page_alloc>
f01012d0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012d3:	83 c4 10             	add    $0x10,%esp
f01012d6:	85 c0                	test   %eax,%eax
f01012d8:	0f 84 0f 02 00 00    	je     f01014ed <mem_init+0x763>
	assert((pp2 = page_alloc(0)));
f01012de:	83 ec 0c             	sub    $0xc,%esp
f01012e1:	6a 00                	push   $0x0
f01012e3:	e8 cb f9 ff ff       	call   f0100cb3 <page_alloc>
f01012e8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01012eb:	83 c4 10             	add    $0x10,%esp
f01012ee:	85 c0                	test   %eax,%eax
f01012f0:	0f 84 16 02 00 00    	je     f010150c <mem_init+0x782>
	assert(pp1 && pp1 != pp0);
f01012f6:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01012f9:	0f 84 2c 02 00 00    	je     f010152b <mem_init+0x7a1>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012ff:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101302:	39 c7                	cmp    %eax,%edi
f0101304:	0f 84 40 02 00 00    	je     f010154a <mem_init+0x7c0>
f010130a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010130d:	0f 84 37 02 00 00    	je     f010154a <mem_init+0x7c0>
	assert(!page_alloc(0));
f0101313:	83 ec 0c             	sub    $0xc,%esp
f0101316:	6a 00                	push   $0x0
f0101318:	e8 96 f9 ff ff       	call   f0100cb3 <page_alloc>
f010131d:	83 c4 10             	add    $0x10,%esp
f0101320:	85 c0                	test   %eax,%eax
f0101322:	0f 85 41 02 00 00    	jne    f0101569 <mem_init+0x7df>
	memset(page2kva(pp0), 1, PGSIZE);
f0101328:	89 f8                	mov    %edi,%eax
f010132a:	e8 c7 f7 ff ff       	call   f0100af6 <page2kva>
f010132f:	83 ec 04             	sub    $0x4,%esp
f0101332:	68 00 10 00 00       	push   $0x1000
f0101337:	6a 01                	push   $0x1
f0101339:	50                   	push   %eax
f010133a:	e8 29 11 00 00       	call   f0102468 <memset>
	page_free(pp0);
f010133f:	89 3c 24             	mov    %edi,(%esp)
f0101342:	e8 f4 f9 ff ff       	call   f0100d3b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101347:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010134e:	e8 60 f9 ff ff       	call   f0100cb3 <page_alloc>
f0101353:	83 c4 10             	add    $0x10,%esp
f0101356:	85 c0                	test   %eax,%eax
f0101358:	0f 84 2a 02 00 00    	je     f0101588 <mem_init+0x7fe>
	assert(pp && pp0 == pp);
f010135e:	39 c7                	cmp    %eax,%edi
f0101360:	0f 85 41 02 00 00    	jne    f01015a7 <mem_init+0x81d>
	c = page2kva(pp);
f0101366:	e8 8b f7 ff ff       	call   f0100af6 <page2kva>
f010136b:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
		assert(c[i] == 0);
f0101371:	80 38 00             	cmpb   $0x0,(%eax)
f0101374:	0f 85 4c 02 00 00    	jne    f01015c6 <mem_init+0x83c>
f010137a:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f010137d:	39 c2                	cmp    %eax,%edx
f010137f:	75 f0                	jne    f0101371 <mem_init+0x5e7>
	page_free_list = fl;
f0101381:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101384:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_free(pp0);
f010138a:	83 ec 0c             	sub    $0xc,%esp
f010138d:	57                   	push   %edi
f010138e:	e8 a8 f9 ff ff       	call   f0100d3b <page_free>
	page_free(pp1);
f0101393:	83 c4 04             	add    $0x4,%esp
f0101396:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101399:	e8 9d f9 ff ff       	call   f0100d3b <page_free>
	page_free(pp2);
f010139e:	83 c4 04             	add    $0x4,%esp
f01013a1:	ff 75 d0             	pushl  -0x30(%ebp)
f01013a4:	e8 92 f9 ff ff       	call   f0100d3b <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01013a9:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01013af:	83 c4 10             	add    $0x10,%esp
f01013b2:	e9 33 02 00 00       	jmp    f01015ea <mem_init+0x860>
	assert((pp0 = page_alloc(0)));
f01013b7:	8d 83 61 ed fe ff    	lea    -0x1129f(%ebx),%eax
f01013bd:	50                   	push   %eax
f01013be:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01013c4:	50                   	push   %eax
f01013c5:	68 36 02 00 00       	push   $0x236
f01013ca:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01013d0:	50                   	push   %eax
f01013d1:	e8 c3 ec ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01013d6:	8d 83 77 ed fe ff    	lea    -0x11289(%ebx),%eax
f01013dc:	50                   	push   %eax
f01013dd:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01013e3:	50                   	push   %eax
f01013e4:	68 37 02 00 00       	push   $0x237
f01013e9:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01013ef:	50                   	push   %eax
f01013f0:	e8 a4 ec ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01013f5:	8d 83 8d ed fe ff    	lea    -0x11273(%ebx),%eax
f01013fb:	50                   	push   %eax
f01013fc:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101402:	50                   	push   %eax
f0101403:	68 38 02 00 00       	push   $0x238
f0101408:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010140e:	50                   	push   %eax
f010140f:	e8 85 ec ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101414:	8d 83 a3 ed fe ff    	lea    -0x1125d(%ebx),%eax
f010141a:	50                   	push   %eax
f010141b:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101421:	50                   	push   %eax
f0101422:	68 3b 02 00 00       	push   $0x23b
f0101427:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010142d:	50                   	push   %eax
f010142e:	e8 66 ec ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101433:	8d 83 20 ec fe ff    	lea    -0x113e0(%ebx),%eax
f0101439:	50                   	push   %eax
f010143a:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101440:	50                   	push   %eax
f0101441:	68 3c 02 00 00       	push   $0x23c
f0101446:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010144c:	50                   	push   %eax
f010144d:	e8 47 ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101452:	8d 83 b5 ed fe ff    	lea    -0x1124b(%ebx),%eax
f0101458:	50                   	push   %eax
f0101459:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f010145f:	50                   	push   %eax
f0101460:	68 3d 02 00 00       	push   $0x23d
f0101465:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010146b:	50                   	push   %eax
f010146c:	e8 28 ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101471:	8d 83 d2 ed fe ff    	lea    -0x1122e(%ebx),%eax
f0101477:	50                   	push   %eax
f0101478:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f010147e:	50                   	push   %eax
f010147f:	68 3e 02 00 00       	push   $0x23e
f0101484:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010148a:	50                   	push   %eax
f010148b:	e8 09 ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101490:	8d 83 ef ed fe ff    	lea    -0x11211(%ebx),%eax
f0101496:	50                   	push   %eax
f0101497:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f010149d:	50                   	push   %eax
f010149e:	68 3f 02 00 00       	push   $0x23f
f01014a3:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01014a9:	50                   	push   %eax
f01014aa:	e8 ea eb ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01014af:	8d 83 0c ee fe ff    	lea    -0x111f4(%ebx),%eax
f01014b5:	50                   	push   %eax
f01014b6:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01014bc:	50                   	push   %eax
f01014bd:	68 46 02 00 00       	push   $0x246
f01014c2:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01014c8:	50                   	push   %eax
f01014c9:	e8 cb eb ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01014ce:	8d 83 61 ed fe ff    	lea    -0x1129f(%ebx),%eax
f01014d4:	50                   	push   %eax
f01014d5:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01014db:	50                   	push   %eax
f01014dc:	68 4d 02 00 00       	push   $0x24d
f01014e1:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01014e7:	50                   	push   %eax
f01014e8:	e8 ac eb ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01014ed:	8d 83 77 ed fe ff    	lea    -0x11289(%ebx),%eax
f01014f3:	50                   	push   %eax
f01014f4:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01014fa:	50                   	push   %eax
f01014fb:	68 4e 02 00 00       	push   $0x24e
f0101500:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101506:	50                   	push   %eax
f0101507:	e8 8d eb ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010150c:	8d 83 8d ed fe ff    	lea    -0x11273(%ebx),%eax
f0101512:	50                   	push   %eax
f0101513:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101519:	50                   	push   %eax
f010151a:	68 4f 02 00 00       	push   $0x24f
f010151f:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101525:	50                   	push   %eax
f0101526:	e8 6e eb ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010152b:	8d 83 a3 ed fe ff    	lea    -0x1125d(%ebx),%eax
f0101531:	50                   	push   %eax
f0101532:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101538:	50                   	push   %eax
f0101539:	68 51 02 00 00       	push   $0x251
f010153e:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101544:	50                   	push   %eax
f0101545:	e8 4f eb ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010154a:	8d 83 20 ec fe ff    	lea    -0x113e0(%ebx),%eax
f0101550:	50                   	push   %eax
f0101551:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101557:	50                   	push   %eax
f0101558:	68 52 02 00 00       	push   $0x252
f010155d:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101563:	50                   	push   %eax
f0101564:	e8 30 eb ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101569:	8d 83 0c ee fe ff    	lea    -0x111f4(%ebx),%eax
f010156f:	50                   	push   %eax
f0101570:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101576:	50                   	push   %eax
f0101577:	68 53 02 00 00       	push   $0x253
f010157c:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101582:	50                   	push   %eax
f0101583:	e8 11 eb ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101588:	8d 83 1b ee fe ff    	lea    -0x111e5(%ebx),%eax
f010158e:	50                   	push   %eax
f010158f:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101595:	50                   	push   %eax
f0101596:	68 58 02 00 00       	push   $0x258
f010159b:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01015a1:	50                   	push   %eax
f01015a2:	e8 f2 ea ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f01015a7:	8d 83 39 ee fe ff    	lea    -0x111c7(%ebx),%eax
f01015ad:	50                   	push   %eax
f01015ae:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01015b4:	50                   	push   %eax
f01015b5:	68 59 02 00 00       	push   $0x259
f01015ba:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01015c0:	50                   	push   %eax
f01015c1:	e8 d3 ea ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f01015c6:	8d 83 49 ee fe ff    	lea    -0x111b7(%ebx),%eax
f01015cc:	50                   	push   %eax
f01015cd:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01015d3:	50                   	push   %eax
f01015d4:	68 5c 02 00 00       	push   $0x25c
f01015d9:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01015df:	50                   	push   %eax
f01015e0:	e8 b4 ea ff ff       	call   f0100099 <_panic>
		--nfree;
f01015e5:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015e8:	8b 00                	mov    (%eax),%eax
f01015ea:	85 c0                	test   %eax,%eax
f01015ec:	75 f7                	jne    f01015e5 <mem_init+0x85b>
	assert(nfree == 0);
f01015ee:	85 f6                	test   %esi,%esi
f01015f0:	0f 85 83 00 00 00    	jne    f0101679 <mem_init+0x8ef>
	cprintf("check_page_alloc() succeeded!\n");
f01015f6:	83 ec 0c             	sub    $0xc,%esp
f01015f9:	8d 83 40 ec fe ff    	lea    -0x113c0(%ebx),%eax
f01015ff:	50                   	push   %eax
f0101600:	e8 52 02 00 00       	call   f0101857 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101605:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010160c:	e8 a2 f6 ff ff       	call   f0100cb3 <page_alloc>
f0101611:	89 c7                	mov    %eax,%edi
f0101613:	83 c4 10             	add    $0x10,%esp
f0101616:	85 c0                	test   %eax,%eax
f0101618:	74 7e                	je     f0101698 <mem_init+0x90e>
	assert((pp1 = page_alloc(0)));
f010161a:	83 ec 0c             	sub    $0xc,%esp
f010161d:	6a 00                	push   $0x0
f010161f:	e8 8f f6 ff ff       	call   f0100cb3 <page_alloc>
f0101624:	89 c6                	mov    %eax,%esi
f0101626:	83 c4 10             	add    $0x10,%esp
f0101629:	85 c0                	test   %eax,%eax
f010162b:	0f 84 86 00 00 00    	je     f01016b7 <mem_init+0x92d>
	assert((pp2 = page_alloc(0)));
f0101631:	83 ec 0c             	sub    $0xc,%esp
f0101634:	6a 00                	push   $0x0
f0101636:	e8 78 f6 ff ff       	call   f0100cb3 <page_alloc>
f010163b:	83 c4 10             	add    $0x10,%esp
f010163e:	85 c0                	test   %eax,%eax
f0101640:	0f 84 90 00 00 00    	je     f01016d6 <mem_init+0x94c>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101646:	39 f7                	cmp    %esi,%edi
f0101648:	0f 84 a7 00 00 00    	je     f01016f5 <mem_init+0x96b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010164e:	39 c7                	cmp    %eax,%edi
f0101650:	74 08                	je     f010165a <mem_init+0x8d0>
f0101652:	39 c6                	cmp    %eax,%esi
f0101654:	0f 85 ba 00 00 00    	jne    f0101714 <mem_init+0x98a>
f010165a:	8d 83 20 ec fe ff    	lea    -0x113e0(%ebx),%eax
f0101660:	50                   	push   %eax
f0101661:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101667:	50                   	push   %eax
f0101668:	68 c8 02 00 00       	push   $0x2c8
f010166d:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101673:	50                   	push   %eax
f0101674:	e8 20 ea ff ff       	call   f0100099 <_panic>
	assert(nfree == 0);
f0101679:	8d 83 53 ee fe ff    	lea    -0x111ad(%ebx),%eax
f010167f:	50                   	push   %eax
f0101680:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101686:	50                   	push   %eax
f0101687:	68 69 02 00 00       	push   $0x269
f010168c:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101692:	50                   	push   %eax
f0101693:	e8 01 ea ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101698:	8d 83 61 ed fe ff    	lea    -0x1129f(%ebx),%eax
f010169e:	50                   	push   %eax
f010169f:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01016a5:	50                   	push   %eax
f01016a6:	68 c2 02 00 00       	push   $0x2c2
f01016ab:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01016b1:	50                   	push   %eax
f01016b2:	e8 e2 e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01016b7:	8d 83 77 ed fe ff    	lea    -0x11289(%ebx),%eax
f01016bd:	50                   	push   %eax
f01016be:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01016c4:	50                   	push   %eax
f01016c5:	68 c3 02 00 00       	push   $0x2c3
f01016ca:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01016d0:	50                   	push   %eax
f01016d1:	e8 c3 e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01016d6:	8d 83 8d ed fe ff    	lea    -0x11273(%ebx),%eax
f01016dc:	50                   	push   %eax
f01016dd:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f01016e3:	50                   	push   %eax
f01016e4:	68 c4 02 00 00       	push   $0x2c4
f01016e9:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f01016ef:	50                   	push   %eax
f01016f0:	e8 a4 e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01016f5:	8d 83 a3 ed fe ff    	lea    -0x1125d(%ebx),%eax
f01016fb:	50                   	push   %eax
f01016fc:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101702:	50                   	push   %eax
f0101703:	68 c7 02 00 00       	push   $0x2c7
f0101708:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f010170e:	50                   	push   %eax
f010170f:	e8 85 e9 ff ff       	call   f0100099 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101714:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f010171b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010171e:	83 ec 0c             	sub    $0xc,%esp
f0101721:	6a 00                	push   $0x0
f0101723:	e8 8b f5 ff ff       	call   f0100cb3 <page_alloc>
f0101728:	83 c4 10             	add    $0x10,%esp
f010172b:	85 c0                	test   %eax,%eax
f010172d:	74 1f                	je     f010174e <mem_init+0x9c4>
f010172f:	8d 83 0c ee fe ff    	lea    -0x111f4(%ebx),%eax
f0101735:	50                   	push   %eax
f0101736:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f010173c:	50                   	push   %eax
f010173d:	68 cf 02 00 00       	push   $0x2cf
f0101742:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101748:	50                   	push   %eax
f0101749:	e8 4b e9 ff ff       	call   f0100099 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010174e:	8d 83 60 ec fe ff    	lea    -0x113a0(%ebx),%eax
f0101754:	50                   	push   %eax
f0101755:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f010175b:	50                   	push   %eax
f010175c:	68 d5 02 00 00       	push   $0x2d5
f0101761:	8d 83 9e ec fe ff    	lea    -0x11362(%ebx),%eax
f0101767:	50                   	push   %eax
f0101768:	e8 2c e9 ff ff       	call   f0100099 <_panic>

f010176d <page_decref>:
{
f010176d:	55                   	push   %ebp
f010176e:	89 e5                	mov    %esp,%ebp
f0101770:	83 ec 08             	sub    $0x8,%esp
f0101773:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101776:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010177a:	83 e8 01             	sub    $0x1,%eax
f010177d:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101781:	66 85 c0             	test   %ax,%ax
f0101784:	74 02                	je     f0101788 <page_decref+0x1b>
}
f0101786:	c9                   	leave  
f0101787:	c3                   	ret    
		page_free(pp);
f0101788:	83 ec 0c             	sub    $0xc,%esp
f010178b:	52                   	push   %edx
f010178c:	e8 aa f5 ff ff       	call   f0100d3b <page_free>
f0101791:	83 c4 10             	add    $0x10,%esp
}
f0101794:	eb f0                	jmp    f0101786 <page_decref+0x19>

f0101796 <pgdir_walk>:
{
f0101796:	55                   	push   %ebp
f0101797:	89 e5                	mov    %esp,%ebp
}
f0101799:	b8 00 00 00 00       	mov    $0x0,%eax
f010179e:	5d                   	pop    %ebp
f010179f:	c3                   	ret    

f01017a0 <page_insert>:
{
f01017a0:	55                   	push   %ebp
f01017a1:	89 e5                	mov    %esp,%ebp
}
f01017a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01017a8:	5d                   	pop    %ebp
f01017a9:	c3                   	ret    

f01017aa <page_lookup>:
{
f01017aa:	55                   	push   %ebp
f01017ab:	89 e5                	mov    %esp,%ebp
}
f01017ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01017b2:	5d                   	pop    %ebp
f01017b3:	c3                   	ret    

f01017b4 <page_remove>:
{
f01017b4:	55                   	push   %ebp
f01017b5:	89 e5                	mov    %esp,%ebp
}
f01017b7:	5d                   	pop    %ebp
f01017b8:	c3                   	ret    

f01017b9 <tlb_invalidate>:
{
f01017b9:	55                   	push   %ebp
f01017ba:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01017bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017bf:	0f 01 38             	invlpg (%eax)
}
f01017c2:	5d                   	pop    %ebp
f01017c3:	c3                   	ret    

f01017c4 <__x86.get_pc_thunk.dx>:
f01017c4:	8b 14 24             	mov    (%esp),%edx
f01017c7:	c3                   	ret    

f01017c8 <__x86.get_pc_thunk.cx>:
f01017c8:	8b 0c 24             	mov    (%esp),%ecx
f01017cb:	c3                   	ret    

f01017cc <__x86.get_pc_thunk.si>:
f01017cc:	8b 34 24             	mov    (%esp),%esi
f01017cf:	c3                   	ret    

f01017d0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01017d0:	55                   	push   %ebp
f01017d1:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01017d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01017d6:	ba 70 00 00 00       	mov    $0x70,%edx
f01017db:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01017dc:	ba 71 00 00 00       	mov    $0x71,%edx
f01017e1:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01017e2:	0f b6 c0             	movzbl %al,%eax
}
f01017e5:	5d                   	pop    %ebp
f01017e6:	c3                   	ret    

f01017e7 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01017e7:	55                   	push   %ebp
f01017e8:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01017ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01017ed:	ba 70 00 00 00       	mov    $0x70,%edx
f01017f2:	ee                   	out    %al,(%dx)
f01017f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017f6:	ba 71 00 00 00       	mov    $0x71,%edx
f01017fb:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01017fc:	5d                   	pop    %ebp
f01017fd:	c3                   	ret    

f01017fe <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01017fe:	55                   	push   %ebp
f01017ff:	89 e5                	mov    %esp,%ebp
f0101801:	53                   	push   %ebx
f0101802:	83 ec 10             	sub    $0x10,%esp
f0101805:	e8 45 e9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010180a:	81 c3 fe 2a 01 00    	add    $0x12afe,%ebx
	cputchar(ch);
f0101810:	ff 75 08             	pushl  0x8(%ebp)
f0101813:	e8 ae ee ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0101818:	83 c4 10             	add    $0x10,%esp
f010181b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010181e:	c9                   	leave  
f010181f:	c3                   	ret    

f0101820 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101820:	55                   	push   %ebp
f0101821:	89 e5                	mov    %esp,%ebp
f0101823:	53                   	push   %ebx
f0101824:	83 ec 14             	sub    $0x14,%esp
f0101827:	e8 23 e9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010182c:	81 c3 dc 2a 01 00    	add    $0x12adc,%ebx
	int cnt = 0;
f0101832:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101839:	ff 75 0c             	pushl  0xc(%ebp)
f010183c:	ff 75 08             	pushl  0x8(%ebp)
f010183f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101842:	50                   	push   %eax
f0101843:	8d 83 f6 d4 fe ff    	lea    -0x12b0a(%ebx),%eax
f0101849:	50                   	push   %eax
f010184a:	e8 98 04 00 00       	call   f0101ce7 <vprintfmt>
	return cnt;
}
f010184f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101852:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101855:	c9                   	leave  
f0101856:	c3                   	ret    

f0101857 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101857:	55                   	push   %ebp
f0101858:	89 e5                	mov    %esp,%ebp
f010185a:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010185d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101860:	50                   	push   %eax
f0101861:	ff 75 08             	pushl  0x8(%ebp)
f0101864:	e8 b7 ff ff ff       	call   f0101820 <vcprintf>
	va_end(ap);

	return cnt;
}
f0101869:	c9                   	leave  
f010186a:	c3                   	ret    

f010186b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010186b:	55                   	push   %ebp
f010186c:	89 e5                	mov    %esp,%ebp
f010186e:	57                   	push   %edi
f010186f:	56                   	push   %esi
f0101870:	53                   	push   %ebx
f0101871:	83 ec 14             	sub    $0x14,%esp
f0101874:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101877:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010187a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010187d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101880:	8b 32                	mov    (%edx),%esi
f0101882:	8b 01                	mov    (%ecx),%eax
f0101884:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101887:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010188e:	eb 2f                	jmp    f01018bf <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0101890:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0101893:	39 c6                	cmp    %eax,%esi
f0101895:	7f 49                	jg     f01018e0 <stab_binsearch+0x75>
f0101897:	0f b6 0a             	movzbl (%edx),%ecx
f010189a:	83 ea 0c             	sub    $0xc,%edx
f010189d:	39 f9                	cmp    %edi,%ecx
f010189f:	75 ef                	jne    f0101890 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01018a1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01018a4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01018a7:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01018ab:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01018ae:	73 35                	jae    f01018e5 <stab_binsearch+0x7a>
			*region_left = m;
f01018b0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01018b3:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f01018b5:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01018b8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01018bf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01018c2:	7f 4e                	jg     f0101912 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01018c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018c7:	01 f0                	add    %esi,%eax
f01018c9:	89 c3                	mov    %eax,%ebx
f01018cb:	c1 eb 1f             	shr    $0x1f,%ebx
f01018ce:	01 c3                	add    %eax,%ebx
f01018d0:	d1 fb                	sar    %ebx
f01018d2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01018d5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01018d8:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01018dc:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01018de:	eb b3                	jmp    f0101893 <stab_binsearch+0x28>
			l = true_m + 1;
f01018e0:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01018e3:	eb da                	jmp    f01018bf <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01018e5:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01018e8:	76 14                	jbe    f01018fe <stab_binsearch+0x93>
			*region_right = m - 1;
f01018ea:	83 e8 01             	sub    $0x1,%eax
f01018ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01018f0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01018f3:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f01018f5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01018fc:	eb c1                	jmp    f01018bf <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01018fe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101901:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101903:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101907:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0101909:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101910:	eb ad                	jmp    f01018bf <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0101912:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101916:	74 16                	je     f010192e <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101918:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010191b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010191d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101920:	8b 0e                	mov    (%esi),%ecx
f0101922:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101925:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101928:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f010192c:	eb 12                	jmp    f0101940 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f010192e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101931:	8b 00                	mov    (%eax),%eax
f0101933:	83 e8 01             	sub    $0x1,%eax
f0101936:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101939:	89 07                	mov    %eax,(%edi)
f010193b:	eb 16                	jmp    f0101953 <stab_binsearch+0xe8>
		     l--)
f010193d:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0101940:	39 c1                	cmp    %eax,%ecx
f0101942:	7d 0a                	jge    f010194e <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0101944:	0f b6 1a             	movzbl (%edx),%ebx
f0101947:	83 ea 0c             	sub    $0xc,%edx
f010194a:	39 fb                	cmp    %edi,%ebx
f010194c:	75 ef                	jne    f010193d <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f010194e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101951:	89 07                	mov    %eax,(%edi)
	}
}
f0101953:	83 c4 14             	add    $0x14,%esp
f0101956:	5b                   	pop    %ebx
f0101957:	5e                   	pop    %esi
f0101958:	5f                   	pop    %edi
f0101959:	5d                   	pop    %ebp
f010195a:	c3                   	ret    

f010195b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010195b:	55                   	push   %ebp
f010195c:	89 e5                	mov    %esp,%ebp
f010195e:	57                   	push   %edi
f010195f:	56                   	push   %esi
f0101960:	53                   	push   %ebx
f0101961:	83 ec 3c             	sub    $0x3c,%esp
f0101964:	e8 e6 e7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101969:	81 c3 9f 29 01 00    	add    $0x1299f,%ebx
f010196f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101972:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101975:	8d 83 5e ee fe ff    	lea    -0x111a2(%ebx),%eax
f010197b:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f010197d:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0101984:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0101987:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010198e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0101991:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101998:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010199e:	0f 86 37 01 00 00    	jbe    f0101adb <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01019a4:	c7 c0 79 86 10 f0    	mov    $0xf0108679,%eax
f01019aa:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f01019b0:	0f 86 04 02 00 00    	jbe    f0101bba <debuginfo_eip+0x25f>
f01019b6:	c7 c0 db a3 10 f0    	mov    $0xf010a3db,%eax
f01019bc:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01019c0:	0f 85 fb 01 00 00    	jne    f0101bc1 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01019c6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01019cd:	c7 c0 80 33 10 f0    	mov    $0xf0103380,%eax
f01019d3:	c7 c2 78 86 10 f0    	mov    $0xf0108678,%edx
f01019d9:	29 c2                	sub    %eax,%edx
f01019db:	c1 fa 02             	sar    $0x2,%edx
f01019de:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01019e4:	83 ea 01             	sub    $0x1,%edx
f01019e7:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01019ea:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01019ed:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01019f0:	83 ec 08             	sub    $0x8,%esp
f01019f3:	57                   	push   %edi
f01019f4:	6a 64                	push   $0x64
f01019f6:	e8 70 fe ff ff       	call   f010186b <stab_binsearch>
	if (lfile == 0)
f01019fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01019fe:	83 c4 10             	add    $0x10,%esp
f0101a01:	85 c0                	test   %eax,%eax
f0101a03:	0f 84 bf 01 00 00    	je     f0101bc8 <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101a09:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101a0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a0f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101a12:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101a15:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101a18:	83 ec 08             	sub    $0x8,%esp
f0101a1b:	57                   	push   %edi
f0101a1c:	6a 24                	push   $0x24
f0101a1e:	c7 c0 80 33 10 f0    	mov    $0xf0103380,%eax
f0101a24:	e8 42 fe ff ff       	call   f010186b <stab_binsearch>

	if (lfun <= rfun) {
f0101a29:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101a2c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0101a2f:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0101a32:	83 c4 10             	add    $0x10,%esp
f0101a35:	39 c8                	cmp    %ecx,%eax
f0101a37:	0f 8f b6 00 00 00    	jg     f0101af3 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101a3d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101a40:	c7 c1 80 33 10 f0    	mov    $0xf0103380,%ecx
f0101a46:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0101a49:	8b 11                	mov    (%ecx),%edx
f0101a4b:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0101a4e:	c7 c2 db a3 10 f0    	mov    $0xf010a3db,%edx
f0101a54:	81 ea 79 86 10 f0    	sub    $0xf0108679,%edx
f0101a5a:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0101a5d:	73 0c                	jae    f0101a6b <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101a5f:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0101a62:	81 c2 79 86 10 f0    	add    $0xf0108679,%edx
f0101a68:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101a6b:	8b 51 08             	mov    0x8(%ecx),%edx
f0101a6e:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0101a71:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0101a73:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101a76:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0101a79:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101a7c:	83 ec 08             	sub    $0x8,%esp
f0101a7f:	6a 3a                	push   $0x3a
f0101a81:	ff 76 08             	pushl  0x8(%esi)
f0101a84:	e8 c3 09 00 00       	call   f010244c <strfind>
f0101a89:	2b 46 08             	sub    0x8(%esi),%eax
f0101a8c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101a8f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101a92:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101a95:	83 c4 08             	add    $0x8,%esp
f0101a98:	57                   	push   %edi
f0101a99:	6a 44                	push   $0x44
f0101a9b:	c7 c0 80 33 10 f0    	mov    $0xf0103380,%eax
f0101aa1:	e8 c5 fd ff ff       	call   f010186b <stab_binsearch>
	if(lline<=rline){
f0101aa6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101aa9:	83 c4 10             	add    $0x10,%esp
f0101aac:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0101aaf:	0f 8f 1a 01 00 00    	jg     f0101bcf <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f0101ab5:	89 d0                	mov    %edx,%eax
f0101ab7:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0101aba:	c1 e2 02             	shl    $0x2,%edx
f0101abd:	c7 c1 80 33 10 f0    	mov    $0xf0103380,%ecx
f0101ac3:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0101ac8:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101acb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101ace:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0101ad2:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0101ad6:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101ad9:	eb 36                	jmp    f0101b11 <debuginfo_eip+0x1b6>
  	        panic("User address");
f0101adb:	83 ec 04             	sub    $0x4,%esp
f0101ade:	8d 83 68 ee fe ff    	lea    -0x11198(%ebx),%eax
f0101ae4:	50                   	push   %eax
f0101ae5:	6a 7f                	push   $0x7f
f0101ae7:	8d 83 75 ee fe ff    	lea    -0x1118b(%ebx),%eax
f0101aed:	50                   	push   %eax
f0101aee:	e8 a6 e5 ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0101af3:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0101af6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101af9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101afc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101aff:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101b02:	e9 75 ff ff ff       	jmp    f0101a7c <debuginfo_eip+0x121>
f0101b07:	83 e8 01             	sub    $0x1,%eax
f0101b0a:	83 ea 0c             	sub    $0xc,%edx
f0101b0d:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0101b11:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0101b14:	39 c7                	cmp    %eax,%edi
f0101b16:	7f 24                	jg     f0101b3c <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f0101b18:	0f b6 0a             	movzbl (%edx),%ecx
f0101b1b:	80 f9 84             	cmp    $0x84,%cl
f0101b1e:	74 46                	je     f0101b66 <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101b20:	80 f9 64             	cmp    $0x64,%cl
f0101b23:	75 e2                	jne    f0101b07 <debuginfo_eip+0x1ac>
f0101b25:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0101b29:	74 dc                	je     f0101b07 <debuginfo_eip+0x1ac>
f0101b2b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101b2e:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0101b32:	74 3b                	je     f0101b6f <debuginfo_eip+0x214>
f0101b34:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0101b37:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101b3a:	eb 33                	jmp    f0101b6f <debuginfo_eip+0x214>
f0101b3c:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101b3f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101b42:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101b45:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0101b4a:	39 fa                	cmp    %edi,%edx
f0101b4c:	0f 8d 89 00 00 00    	jge    f0101bdb <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0101b52:	83 c2 01             	add    $0x1,%edx
f0101b55:	89 d0                	mov    %edx,%eax
f0101b57:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0101b5a:	c7 c2 80 33 10 f0    	mov    $0xf0103380,%edx
f0101b60:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0101b64:	eb 3b                	jmp    f0101ba1 <debuginfo_eip+0x246>
f0101b66:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101b69:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0101b6d:	75 26                	jne    f0101b95 <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101b6f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101b72:	c7 c0 80 33 10 f0    	mov    $0xf0103380,%eax
f0101b78:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0101b7b:	c7 c0 db a3 10 f0    	mov    $0xf010a3db,%eax
f0101b81:	81 e8 79 86 10 f0    	sub    $0xf0108679,%eax
f0101b87:	39 c2                	cmp    %eax,%edx
f0101b89:	73 b4                	jae    f0101b3f <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101b8b:	81 c2 79 86 10 f0    	add    $0xf0108679,%edx
f0101b91:	89 16                	mov    %edx,(%esi)
f0101b93:	eb aa                	jmp    f0101b3f <debuginfo_eip+0x1e4>
f0101b95:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0101b98:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101b9b:	eb d2                	jmp    f0101b6f <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0101b9d:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0101ba1:	39 c7                	cmp    %eax,%edi
f0101ba3:	7e 31                	jle    f0101bd6 <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101ba5:	0f b6 0a             	movzbl (%edx),%ecx
f0101ba8:	83 c0 01             	add    $0x1,%eax
f0101bab:	83 c2 0c             	add    $0xc,%edx
f0101bae:	80 f9 a0             	cmp    $0xa0,%cl
f0101bb1:	74 ea                	je     f0101b9d <debuginfo_eip+0x242>
	return 0;
f0101bb3:	b8 00 00 00 00       	mov    $0x0,%eax
f0101bb8:	eb 21                	jmp    f0101bdb <debuginfo_eip+0x280>
		return -1;
f0101bba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bbf:	eb 1a                	jmp    f0101bdb <debuginfo_eip+0x280>
f0101bc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bc6:	eb 13                	jmp    f0101bdb <debuginfo_eip+0x280>
		return -1;
f0101bc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bcd:	eb 0c                	jmp    f0101bdb <debuginfo_eip+0x280>
		return -1;
f0101bcf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bd4:	eb 05                	jmp    f0101bdb <debuginfo_eip+0x280>
	return 0;
f0101bd6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101bdb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101bde:	5b                   	pop    %ebx
f0101bdf:	5e                   	pop    %esi
f0101be0:	5f                   	pop    %edi
f0101be1:	5d                   	pop    %ebp
f0101be2:	c3                   	ret    

f0101be3 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101be3:	55                   	push   %ebp
f0101be4:	89 e5                	mov    %esp,%ebp
f0101be6:	57                   	push   %edi
f0101be7:	56                   	push   %esi
f0101be8:	53                   	push   %ebx
f0101be9:	83 ec 2c             	sub    $0x2c,%esp
f0101bec:	e8 d7 fb ff ff       	call   f01017c8 <__x86.get_pc_thunk.cx>
f0101bf1:	81 c1 17 27 01 00    	add    $0x12717,%ecx
f0101bf7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101bfa:	89 c7                	mov    %eax,%edi
f0101bfc:	89 d6                	mov    %edx,%esi
f0101bfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c01:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101c04:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c07:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101c0a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101c0d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101c12:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0101c15:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101c18:	39 d3                	cmp    %edx,%ebx
f0101c1a:	72 09                	jb     f0101c25 <printnum+0x42>
f0101c1c:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101c1f:	0f 87 83 00 00 00    	ja     f0101ca8 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101c25:	83 ec 0c             	sub    $0xc,%esp
f0101c28:	ff 75 18             	pushl  0x18(%ebp)
f0101c2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c2e:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101c31:	53                   	push   %ebx
f0101c32:	ff 75 10             	pushl  0x10(%ebp)
f0101c35:	83 ec 08             	sub    $0x8,%esp
f0101c38:	ff 75 dc             	pushl  -0x24(%ebp)
f0101c3b:	ff 75 d8             	pushl  -0x28(%ebp)
f0101c3e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c41:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c44:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101c47:	e8 24 0a 00 00       	call   f0102670 <__udivdi3>
f0101c4c:	83 c4 18             	add    $0x18,%esp
f0101c4f:	52                   	push   %edx
f0101c50:	50                   	push   %eax
f0101c51:	89 f2                	mov    %esi,%edx
f0101c53:	89 f8                	mov    %edi,%eax
f0101c55:	e8 89 ff ff ff       	call   f0101be3 <printnum>
f0101c5a:	83 c4 20             	add    $0x20,%esp
f0101c5d:	eb 13                	jmp    f0101c72 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101c5f:	83 ec 08             	sub    $0x8,%esp
f0101c62:	56                   	push   %esi
f0101c63:	ff 75 18             	pushl  0x18(%ebp)
f0101c66:	ff d7                	call   *%edi
f0101c68:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0101c6b:	83 eb 01             	sub    $0x1,%ebx
f0101c6e:	85 db                	test   %ebx,%ebx
f0101c70:	7f ed                	jg     f0101c5f <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101c72:	83 ec 08             	sub    $0x8,%esp
f0101c75:	56                   	push   %esi
f0101c76:	83 ec 04             	sub    $0x4,%esp
f0101c79:	ff 75 dc             	pushl  -0x24(%ebp)
f0101c7c:	ff 75 d8             	pushl  -0x28(%ebp)
f0101c7f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c82:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c85:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101c88:	89 f3                	mov    %esi,%ebx
f0101c8a:	e8 01 0b 00 00       	call   f0102790 <__umoddi3>
f0101c8f:	83 c4 14             	add    $0x14,%esp
f0101c92:	0f be 84 06 83 ee fe 	movsbl -0x1117d(%esi,%eax,1),%eax
f0101c99:	ff 
f0101c9a:	50                   	push   %eax
f0101c9b:	ff d7                	call   *%edi
}
f0101c9d:	83 c4 10             	add    $0x10,%esp
f0101ca0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101ca3:	5b                   	pop    %ebx
f0101ca4:	5e                   	pop    %esi
f0101ca5:	5f                   	pop    %edi
f0101ca6:	5d                   	pop    %ebp
f0101ca7:	c3                   	ret    
f0101ca8:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101cab:	eb be                	jmp    f0101c6b <printnum+0x88>

f0101cad <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101cad:	55                   	push   %ebp
f0101cae:	89 e5                	mov    %esp,%ebp
f0101cb0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101cb3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101cb7:	8b 10                	mov    (%eax),%edx
f0101cb9:	3b 50 04             	cmp    0x4(%eax),%edx
f0101cbc:	73 0a                	jae    f0101cc8 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101cbe:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101cc1:	89 08                	mov    %ecx,(%eax)
f0101cc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cc6:	88 02                	mov    %al,(%edx)
}
f0101cc8:	5d                   	pop    %ebp
f0101cc9:	c3                   	ret    

f0101cca <printfmt>:
{
f0101cca:	55                   	push   %ebp
f0101ccb:	89 e5                	mov    %esp,%ebp
f0101ccd:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0101cd0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101cd3:	50                   	push   %eax
f0101cd4:	ff 75 10             	pushl  0x10(%ebp)
f0101cd7:	ff 75 0c             	pushl  0xc(%ebp)
f0101cda:	ff 75 08             	pushl  0x8(%ebp)
f0101cdd:	e8 05 00 00 00       	call   f0101ce7 <vprintfmt>
}
f0101ce2:	83 c4 10             	add    $0x10,%esp
f0101ce5:	c9                   	leave  
f0101ce6:	c3                   	ret    

f0101ce7 <vprintfmt>:
{
f0101ce7:	55                   	push   %ebp
f0101ce8:	89 e5                	mov    %esp,%ebp
f0101cea:	57                   	push   %edi
f0101ceb:	56                   	push   %esi
f0101cec:	53                   	push   %ebx
f0101ced:	83 ec 2c             	sub    $0x2c,%esp
f0101cf0:	e8 5a e4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101cf5:	81 c3 13 26 01 00    	add    $0x12613,%ebx
f0101cfb:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101cfe:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101d01:	e9 c3 03 00 00       	jmp    f01020c9 <.L35+0x48>
		padc = ' ';
f0101d06:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0101d0a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0101d11:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0101d18:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101d1f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101d24:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101d27:	8d 47 01             	lea    0x1(%edi),%eax
f0101d2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101d2d:	0f b6 17             	movzbl (%edi),%edx
f0101d30:	8d 42 dd             	lea    -0x23(%edx),%eax
f0101d33:	3c 55                	cmp    $0x55,%al
f0101d35:	0f 87 16 04 00 00    	ja     f0102151 <.L22>
f0101d3b:	0f b6 c0             	movzbl %al,%eax
f0101d3e:	89 d9                	mov    %ebx,%ecx
f0101d40:	03 8c 83 10 ef fe ff 	add    -0x110f0(%ebx,%eax,4),%ecx
f0101d47:	ff e1                	jmp    *%ecx

f0101d49 <.L69>:
f0101d49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101d4c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101d50:	eb d5                	jmp    f0101d27 <vprintfmt+0x40>

f0101d52 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101d52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0101d55:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101d59:	eb cc                	jmp    f0101d27 <vprintfmt+0x40>

f0101d5b <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101d5b:	0f b6 d2             	movzbl %dl,%edx
f0101d5e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101d61:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0101d66:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101d69:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101d6d:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101d70:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101d73:	83 f9 09             	cmp    $0x9,%ecx
f0101d76:	77 55                	ja     f0101dcd <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0101d78:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101d7b:	eb e9                	jmp    f0101d66 <.L29+0xb>

f0101d7d <.L26>:
			precision = va_arg(ap, int);
f0101d7d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d80:	8b 00                	mov    (%eax),%eax
f0101d82:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d85:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d88:	8d 40 04             	lea    0x4(%eax),%eax
f0101d8b:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101d8e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0101d91:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101d95:	79 90                	jns    f0101d27 <vprintfmt+0x40>
				width = precision, precision = -1;
f0101d97:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101d9a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101d9d:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0101da4:	eb 81                	jmp    f0101d27 <vprintfmt+0x40>

f0101da6 <.L27>:
f0101da6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101da9:	85 c0                	test   %eax,%eax
f0101dab:	ba 00 00 00 00       	mov    $0x0,%edx
f0101db0:	0f 49 d0             	cmovns %eax,%edx
f0101db3:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101db6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101db9:	e9 69 ff ff ff       	jmp    f0101d27 <vprintfmt+0x40>

f0101dbe <.L23>:
f0101dbe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0101dc1:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101dc8:	e9 5a ff ff ff       	jmp    f0101d27 <vprintfmt+0x40>
f0101dcd:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101dd0:	eb bf                	jmp    f0101d91 <.L26+0x14>

f0101dd2 <.L33>:
			lflag++;
f0101dd2:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101dd6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101dd9:	e9 49 ff ff ff       	jmp    f0101d27 <vprintfmt+0x40>

f0101dde <.L30>:
			putch(va_arg(ap, int), putdat);
f0101dde:	8b 45 14             	mov    0x14(%ebp),%eax
f0101de1:	8d 78 04             	lea    0x4(%eax),%edi
f0101de4:	83 ec 08             	sub    $0x8,%esp
f0101de7:	56                   	push   %esi
f0101de8:	ff 30                	pushl  (%eax)
f0101dea:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101ded:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101df0:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0101df3:	e9 ce 02 00 00       	jmp    f01020c6 <.L35+0x45>

f0101df8 <.L32>:
			err = va_arg(ap, int);
f0101df8:	8b 45 14             	mov    0x14(%ebp),%eax
f0101dfb:	8d 78 04             	lea    0x4(%eax),%edi
f0101dfe:	8b 00                	mov    (%eax),%eax
f0101e00:	99                   	cltd   
f0101e01:	31 d0                	xor    %edx,%eax
f0101e03:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101e05:	83 f8 06             	cmp    $0x6,%eax
f0101e08:	7f 27                	jg     f0101e31 <.L32+0x39>
f0101e0a:	8b 94 83 3c 1d 00 00 	mov    0x1d3c(%ebx,%eax,4),%edx
f0101e11:	85 d2                	test   %edx,%edx
f0101e13:	74 1c                	je     f0101e31 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0101e15:	52                   	push   %edx
f0101e16:	8d 83 c8 ec fe ff    	lea    -0x11338(%ebx),%eax
f0101e1c:	50                   	push   %eax
f0101e1d:	56                   	push   %esi
f0101e1e:	ff 75 08             	pushl  0x8(%ebp)
f0101e21:	e8 a4 fe ff ff       	call   f0101cca <printfmt>
f0101e26:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101e29:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101e2c:	e9 95 02 00 00       	jmp    f01020c6 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0101e31:	50                   	push   %eax
f0101e32:	8d 83 9b ee fe ff    	lea    -0x11165(%ebx),%eax
f0101e38:	50                   	push   %eax
f0101e39:	56                   	push   %esi
f0101e3a:	ff 75 08             	pushl  0x8(%ebp)
f0101e3d:	e8 88 fe ff ff       	call   f0101cca <printfmt>
f0101e42:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101e45:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0101e48:	e9 79 02 00 00       	jmp    f01020c6 <.L35+0x45>

f0101e4d <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101e4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e50:	83 c0 04             	add    $0x4,%eax
f0101e53:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101e56:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e59:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101e5b:	85 ff                	test   %edi,%edi
f0101e5d:	8d 83 94 ee fe ff    	lea    -0x1116c(%ebx),%eax
f0101e63:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101e66:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101e6a:	0f 8e b5 00 00 00    	jle    f0101f25 <.L36+0xd8>
f0101e70:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101e74:	75 08                	jne    f0101e7e <.L36+0x31>
f0101e76:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101e79:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101e7c:	eb 6d                	jmp    f0101eeb <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101e7e:	83 ec 08             	sub    $0x8,%esp
f0101e81:	ff 75 cc             	pushl  -0x34(%ebp)
f0101e84:	57                   	push   %edi
f0101e85:	e8 7e 04 00 00       	call   f0102308 <strnlen>
f0101e8a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101e8d:	29 c2                	sub    %eax,%edx
f0101e8f:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101e92:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101e95:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101e99:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101e9c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101e9f:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101ea1:	eb 10                	jmp    f0101eb3 <.L36+0x66>
					putch(padc, putdat);
f0101ea3:	83 ec 08             	sub    $0x8,%esp
f0101ea6:	56                   	push   %esi
f0101ea7:	ff 75 e0             	pushl  -0x20(%ebp)
f0101eaa:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101ead:	83 ef 01             	sub    $0x1,%edi
f0101eb0:	83 c4 10             	add    $0x10,%esp
f0101eb3:	85 ff                	test   %edi,%edi
f0101eb5:	7f ec                	jg     f0101ea3 <.L36+0x56>
f0101eb7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101eba:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101ebd:	85 d2                	test   %edx,%edx
f0101ebf:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ec4:	0f 49 c2             	cmovns %edx,%eax
f0101ec7:	29 c2                	sub    %eax,%edx
f0101ec9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101ecc:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101ecf:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101ed2:	eb 17                	jmp    f0101eeb <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101ed4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101ed8:	75 30                	jne    f0101f0a <.L36+0xbd>
					putch(ch, putdat);
f0101eda:	83 ec 08             	sub    $0x8,%esp
f0101edd:	ff 75 0c             	pushl  0xc(%ebp)
f0101ee0:	50                   	push   %eax
f0101ee1:	ff 55 08             	call   *0x8(%ebp)
f0101ee4:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101ee7:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101eeb:	83 c7 01             	add    $0x1,%edi
f0101eee:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101ef2:	0f be c2             	movsbl %dl,%eax
f0101ef5:	85 c0                	test   %eax,%eax
f0101ef7:	74 52                	je     f0101f4b <.L36+0xfe>
f0101ef9:	85 f6                	test   %esi,%esi
f0101efb:	78 d7                	js     f0101ed4 <.L36+0x87>
f0101efd:	83 ee 01             	sub    $0x1,%esi
f0101f00:	79 d2                	jns    f0101ed4 <.L36+0x87>
f0101f02:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101f05:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101f08:	eb 32                	jmp    f0101f3c <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0101f0a:	0f be d2             	movsbl %dl,%edx
f0101f0d:	83 ea 20             	sub    $0x20,%edx
f0101f10:	83 fa 5e             	cmp    $0x5e,%edx
f0101f13:	76 c5                	jbe    f0101eda <.L36+0x8d>
					putch('?', putdat);
f0101f15:	83 ec 08             	sub    $0x8,%esp
f0101f18:	ff 75 0c             	pushl  0xc(%ebp)
f0101f1b:	6a 3f                	push   $0x3f
f0101f1d:	ff 55 08             	call   *0x8(%ebp)
f0101f20:	83 c4 10             	add    $0x10,%esp
f0101f23:	eb c2                	jmp    f0101ee7 <.L36+0x9a>
f0101f25:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101f28:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101f2b:	eb be                	jmp    f0101eeb <.L36+0x9e>
				putch(' ', putdat);
f0101f2d:	83 ec 08             	sub    $0x8,%esp
f0101f30:	56                   	push   %esi
f0101f31:	6a 20                	push   $0x20
f0101f33:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0101f36:	83 ef 01             	sub    $0x1,%edi
f0101f39:	83 c4 10             	add    $0x10,%esp
f0101f3c:	85 ff                	test   %edi,%edi
f0101f3e:	7f ed                	jg     f0101f2d <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0101f40:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f43:	89 45 14             	mov    %eax,0x14(%ebp)
f0101f46:	e9 7b 01 00 00       	jmp    f01020c6 <.L35+0x45>
f0101f4b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101f4e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101f51:	eb e9                	jmp    f0101f3c <.L36+0xef>

f0101f53 <.L31>:
f0101f53:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101f56:	83 f9 01             	cmp    $0x1,%ecx
f0101f59:	7e 40                	jle    f0101f9b <.L31+0x48>
		return va_arg(*ap, long long);
f0101f5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0101f5e:	8b 50 04             	mov    0x4(%eax),%edx
f0101f61:	8b 00                	mov    (%eax),%eax
f0101f63:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101f66:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101f69:	8b 45 14             	mov    0x14(%ebp),%eax
f0101f6c:	8d 40 08             	lea    0x8(%eax),%eax
f0101f6f:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101f72:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101f76:	79 55                	jns    f0101fcd <.L31+0x7a>
				putch('-', putdat);
f0101f78:	83 ec 08             	sub    $0x8,%esp
f0101f7b:	56                   	push   %esi
f0101f7c:	6a 2d                	push   $0x2d
f0101f7e:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101f81:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101f84:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101f87:	f7 da                	neg    %edx
f0101f89:	83 d1 00             	adc    $0x0,%ecx
f0101f8c:	f7 d9                	neg    %ecx
f0101f8e:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101f91:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101f96:	e9 10 01 00 00       	jmp    f01020ab <.L35+0x2a>
	else if (lflag)
f0101f9b:	85 c9                	test   %ecx,%ecx
f0101f9d:	75 17                	jne    f0101fb6 <.L31+0x63>
		return va_arg(*ap, int);
f0101f9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fa2:	8b 00                	mov    (%eax),%eax
f0101fa4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101fa7:	99                   	cltd   
f0101fa8:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101fab:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fae:	8d 40 04             	lea    0x4(%eax),%eax
f0101fb1:	89 45 14             	mov    %eax,0x14(%ebp)
f0101fb4:	eb bc                	jmp    f0101f72 <.L31+0x1f>
		return va_arg(*ap, long);
f0101fb6:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fb9:	8b 00                	mov    (%eax),%eax
f0101fbb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101fbe:	99                   	cltd   
f0101fbf:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101fc2:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fc5:	8d 40 04             	lea    0x4(%eax),%eax
f0101fc8:	89 45 14             	mov    %eax,0x14(%ebp)
f0101fcb:	eb a5                	jmp    f0101f72 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101fcd:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101fd0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101fd3:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101fd8:	e9 ce 00 00 00       	jmp    f01020ab <.L35+0x2a>

f0101fdd <.L37>:
f0101fdd:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101fe0:	83 f9 01             	cmp    $0x1,%ecx
f0101fe3:	7e 18                	jle    f0101ffd <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0101fe5:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fe8:	8b 10                	mov    (%eax),%edx
f0101fea:	8b 48 04             	mov    0x4(%eax),%ecx
f0101fed:	8d 40 08             	lea    0x8(%eax),%eax
f0101ff0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101ff3:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101ff8:	e9 ae 00 00 00       	jmp    f01020ab <.L35+0x2a>
	else if (lflag)
f0101ffd:	85 c9                	test   %ecx,%ecx
f0101fff:	75 1a                	jne    f010201b <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0102001:	8b 45 14             	mov    0x14(%ebp),%eax
f0102004:	8b 10                	mov    (%eax),%edx
f0102006:	b9 00 00 00 00       	mov    $0x0,%ecx
f010200b:	8d 40 04             	lea    0x4(%eax),%eax
f010200e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0102011:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102016:	e9 90 00 00 00       	jmp    f01020ab <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010201b:	8b 45 14             	mov    0x14(%ebp),%eax
f010201e:	8b 10                	mov    (%eax),%edx
f0102020:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102025:	8d 40 04             	lea    0x4(%eax),%eax
f0102028:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010202b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102030:	eb 79                	jmp    f01020ab <.L35+0x2a>

f0102032 <.L34>:
f0102032:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0102035:	83 f9 01             	cmp    $0x1,%ecx
f0102038:	7e 15                	jle    f010204f <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f010203a:	8b 45 14             	mov    0x14(%ebp),%eax
f010203d:	8b 10                	mov    (%eax),%edx
f010203f:	8b 48 04             	mov    0x4(%eax),%ecx
f0102042:	8d 40 08             	lea    0x8(%eax),%eax
f0102045:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0102048:	b8 08 00 00 00       	mov    $0x8,%eax
f010204d:	eb 5c                	jmp    f01020ab <.L35+0x2a>
	else if (lflag)
f010204f:	85 c9                	test   %ecx,%ecx
f0102051:	75 17                	jne    f010206a <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0102053:	8b 45 14             	mov    0x14(%ebp),%eax
f0102056:	8b 10                	mov    (%eax),%edx
f0102058:	b9 00 00 00 00       	mov    $0x0,%ecx
f010205d:	8d 40 04             	lea    0x4(%eax),%eax
f0102060:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0102063:	b8 08 00 00 00       	mov    $0x8,%eax
f0102068:	eb 41                	jmp    f01020ab <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010206a:	8b 45 14             	mov    0x14(%ebp),%eax
f010206d:	8b 10                	mov    (%eax),%edx
f010206f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102074:	8d 40 04             	lea    0x4(%eax),%eax
f0102077:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010207a:	b8 08 00 00 00       	mov    $0x8,%eax
f010207f:	eb 2a                	jmp    f01020ab <.L35+0x2a>

f0102081 <.L35>:
			putch('0', putdat);
f0102081:	83 ec 08             	sub    $0x8,%esp
f0102084:	56                   	push   %esi
f0102085:	6a 30                	push   $0x30
f0102087:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010208a:	83 c4 08             	add    $0x8,%esp
f010208d:	56                   	push   %esi
f010208e:	6a 78                	push   $0x78
f0102090:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0102093:	8b 45 14             	mov    0x14(%ebp),%eax
f0102096:	8b 10                	mov    (%eax),%edx
f0102098:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010209d:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01020a0:	8d 40 04             	lea    0x4(%eax),%eax
f01020a3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01020a6:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01020ab:	83 ec 0c             	sub    $0xc,%esp
f01020ae:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01020b2:	57                   	push   %edi
f01020b3:	ff 75 e0             	pushl  -0x20(%ebp)
f01020b6:	50                   	push   %eax
f01020b7:	51                   	push   %ecx
f01020b8:	52                   	push   %edx
f01020b9:	89 f2                	mov    %esi,%edx
f01020bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01020be:	e8 20 fb ff ff       	call   f0101be3 <printnum>
			break;
f01020c3:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01020c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01020c9:	83 c7 01             	add    $0x1,%edi
f01020cc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01020d0:	83 f8 25             	cmp    $0x25,%eax
f01020d3:	0f 84 2d fc ff ff    	je     f0101d06 <vprintfmt+0x1f>
			if (ch == '\0')
f01020d9:	85 c0                	test   %eax,%eax
f01020db:	0f 84 91 00 00 00    	je     f0102172 <.L22+0x21>
			putch(ch, putdat);
f01020e1:	83 ec 08             	sub    $0x8,%esp
f01020e4:	56                   	push   %esi
f01020e5:	50                   	push   %eax
f01020e6:	ff 55 08             	call   *0x8(%ebp)
f01020e9:	83 c4 10             	add    $0x10,%esp
f01020ec:	eb db                	jmp    f01020c9 <.L35+0x48>

f01020ee <.L38>:
f01020ee:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01020f1:	83 f9 01             	cmp    $0x1,%ecx
f01020f4:	7e 15                	jle    f010210b <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01020f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01020f9:	8b 10                	mov    (%eax),%edx
f01020fb:	8b 48 04             	mov    0x4(%eax),%ecx
f01020fe:	8d 40 08             	lea    0x8(%eax),%eax
f0102101:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102104:	b8 10 00 00 00       	mov    $0x10,%eax
f0102109:	eb a0                	jmp    f01020ab <.L35+0x2a>
	else if (lflag)
f010210b:	85 c9                	test   %ecx,%ecx
f010210d:	75 17                	jne    f0102126 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f010210f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102112:	8b 10                	mov    (%eax),%edx
f0102114:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102119:	8d 40 04             	lea    0x4(%eax),%eax
f010211c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010211f:	b8 10 00 00 00       	mov    $0x10,%eax
f0102124:	eb 85                	jmp    f01020ab <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0102126:	8b 45 14             	mov    0x14(%ebp),%eax
f0102129:	8b 10                	mov    (%eax),%edx
f010212b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102130:	8d 40 04             	lea    0x4(%eax),%eax
f0102133:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102136:	b8 10 00 00 00       	mov    $0x10,%eax
f010213b:	e9 6b ff ff ff       	jmp    f01020ab <.L35+0x2a>

f0102140 <.L25>:
			putch(ch, putdat);
f0102140:	83 ec 08             	sub    $0x8,%esp
f0102143:	56                   	push   %esi
f0102144:	6a 25                	push   $0x25
f0102146:	ff 55 08             	call   *0x8(%ebp)
			break;
f0102149:	83 c4 10             	add    $0x10,%esp
f010214c:	e9 75 ff ff ff       	jmp    f01020c6 <.L35+0x45>

f0102151 <.L22>:
			putch('%', putdat);
f0102151:	83 ec 08             	sub    $0x8,%esp
f0102154:	56                   	push   %esi
f0102155:	6a 25                	push   $0x25
f0102157:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010215a:	83 c4 10             	add    $0x10,%esp
f010215d:	89 f8                	mov    %edi,%eax
f010215f:	eb 03                	jmp    f0102164 <.L22+0x13>
f0102161:	83 e8 01             	sub    $0x1,%eax
f0102164:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0102168:	75 f7                	jne    f0102161 <.L22+0x10>
f010216a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010216d:	e9 54 ff ff ff       	jmp    f01020c6 <.L35+0x45>
}
f0102172:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102175:	5b                   	pop    %ebx
f0102176:	5e                   	pop    %esi
f0102177:	5f                   	pop    %edi
f0102178:	5d                   	pop    %ebp
f0102179:	c3                   	ret    

f010217a <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010217a:	55                   	push   %ebp
f010217b:	89 e5                	mov    %esp,%ebp
f010217d:	53                   	push   %ebx
f010217e:	83 ec 14             	sub    $0x14,%esp
f0102181:	e8 c9 df ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102186:	81 c3 82 21 01 00    	add    $0x12182,%ebx
f010218c:	8b 45 08             	mov    0x8(%ebp),%eax
f010218f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102192:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102195:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102199:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010219c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01021a3:	85 c0                	test   %eax,%eax
f01021a5:	74 2b                	je     f01021d2 <vsnprintf+0x58>
f01021a7:	85 d2                	test   %edx,%edx
f01021a9:	7e 27                	jle    f01021d2 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01021ab:	ff 75 14             	pushl  0x14(%ebp)
f01021ae:	ff 75 10             	pushl  0x10(%ebp)
f01021b1:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01021b4:	50                   	push   %eax
f01021b5:	8d 83 a5 d9 fe ff    	lea    -0x1265b(%ebx),%eax
f01021bb:	50                   	push   %eax
f01021bc:	e8 26 fb ff ff       	call   f0101ce7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01021c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01021c4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01021c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01021ca:	83 c4 10             	add    $0x10,%esp
}
f01021cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01021d0:	c9                   	leave  
f01021d1:	c3                   	ret    
		return -E_INVAL;
f01021d2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01021d7:	eb f4                	jmp    f01021cd <vsnprintf+0x53>

f01021d9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01021d9:	55                   	push   %ebp
f01021da:	89 e5                	mov    %esp,%ebp
f01021dc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01021df:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01021e2:	50                   	push   %eax
f01021e3:	ff 75 10             	pushl  0x10(%ebp)
f01021e6:	ff 75 0c             	pushl  0xc(%ebp)
f01021e9:	ff 75 08             	pushl  0x8(%ebp)
f01021ec:	e8 89 ff ff ff       	call   f010217a <vsnprintf>
	va_end(ap);

	return rc;
}
f01021f1:	c9                   	leave  
f01021f2:	c3                   	ret    

f01021f3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01021f3:	55                   	push   %ebp
f01021f4:	89 e5                	mov    %esp,%ebp
f01021f6:	57                   	push   %edi
f01021f7:	56                   	push   %esi
f01021f8:	53                   	push   %ebx
f01021f9:	83 ec 1c             	sub    $0x1c,%esp
f01021fc:	e8 4e df ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102201:	81 c3 07 21 01 00    	add    $0x12107,%ebx
f0102207:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010220a:	85 c0                	test   %eax,%eax
f010220c:	74 13                	je     f0102221 <readline+0x2e>
		cprintf("%s", prompt);
f010220e:	83 ec 08             	sub    $0x8,%esp
f0102211:	50                   	push   %eax
f0102212:	8d 83 c8 ec fe ff    	lea    -0x11338(%ebx),%eax
f0102218:	50                   	push   %eax
f0102219:	e8 39 f6 ff ff       	call   f0101857 <cprintf>
f010221e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102221:	83 ec 0c             	sub    $0xc,%esp
f0102224:	6a 00                	push   $0x0
f0102226:	e8 bc e4 ff ff       	call   f01006e7 <iscons>
f010222b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010222e:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0102231:	bf 00 00 00 00       	mov    $0x0,%edi
f0102236:	eb 46                	jmp    f010227e <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0102238:	83 ec 08             	sub    $0x8,%esp
f010223b:	50                   	push   %eax
f010223c:	8d 83 68 f0 fe ff    	lea    -0x10f98(%ebx),%eax
f0102242:	50                   	push   %eax
f0102243:	e8 0f f6 ff ff       	call   f0101857 <cprintf>
			return NULL;
f0102248:	83 c4 10             	add    $0x10,%esp
f010224b:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0102250:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102253:	5b                   	pop    %ebx
f0102254:	5e                   	pop    %esi
f0102255:	5f                   	pop    %edi
f0102256:	5d                   	pop    %ebp
f0102257:	c3                   	ret    
			if (echoing)
f0102258:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010225c:	75 05                	jne    f0102263 <readline+0x70>
			i--;
f010225e:	83 ef 01             	sub    $0x1,%edi
f0102261:	eb 1b                	jmp    f010227e <readline+0x8b>
				cputchar('\b');
f0102263:	83 ec 0c             	sub    $0xc,%esp
f0102266:	6a 08                	push   $0x8
f0102268:	e8 59 e4 ff ff       	call   f01006c6 <cputchar>
f010226d:	83 c4 10             	add    $0x10,%esp
f0102270:	eb ec                	jmp    f010225e <readline+0x6b>
			buf[i++] = c;
f0102272:	89 f0                	mov    %esi,%eax
f0102274:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f010227b:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f010227e:	e8 53 e4 ff ff       	call   f01006d6 <getchar>
f0102283:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0102285:	85 c0                	test   %eax,%eax
f0102287:	78 af                	js     f0102238 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102289:	83 f8 08             	cmp    $0x8,%eax
f010228c:	0f 94 c2             	sete   %dl
f010228f:	83 f8 7f             	cmp    $0x7f,%eax
f0102292:	0f 94 c0             	sete   %al
f0102295:	08 c2                	or     %al,%dl
f0102297:	74 04                	je     f010229d <readline+0xaa>
f0102299:	85 ff                	test   %edi,%edi
f010229b:	7f bb                	jg     f0102258 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010229d:	83 fe 1f             	cmp    $0x1f,%esi
f01022a0:	7e 1c                	jle    f01022be <readline+0xcb>
f01022a2:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01022a8:	7f 14                	jg     f01022be <readline+0xcb>
			if (echoing)
f01022aa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01022ae:	74 c2                	je     f0102272 <readline+0x7f>
				cputchar(c);
f01022b0:	83 ec 0c             	sub    $0xc,%esp
f01022b3:	56                   	push   %esi
f01022b4:	e8 0d e4 ff ff       	call   f01006c6 <cputchar>
f01022b9:	83 c4 10             	add    $0x10,%esp
f01022bc:	eb b4                	jmp    f0102272 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01022be:	83 fe 0a             	cmp    $0xa,%esi
f01022c1:	74 05                	je     f01022c8 <readline+0xd5>
f01022c3:	83 fe 0d             	cmp    $0xd,%esi
f01022c6:	75 b6                	jne    f010227e <readline+0x8b>
			if (echoing)
f01022c8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01022cc:	75 13                	jne    f01022e1 <readline+0xee>
			buf[i] = 0;
f01022ce:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f01022d5:	00 
			return buf;
f01022d6:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f01022dc:	e9 6f ff ff ff       	jmp    f0102250 <readline+0x5d>
				cputchar('\n');
f01022e1:	83 ec 0c             	sub    $0xc,%esp
f01022e4:	6a 0a                	push   $0xa
f01022e6:	e8 db e3 ff ff       	call   f01006c6 <cputchar>
f01022eb:	83 c4 10             	add    $0x10,%esp
f01022ee:	eb de                	jmp    f01022ce <readline+0xdb>

f01022f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01022f0:	55                   	push   %ebp
f01022f1:	89 e5                	mov    %esp,%ebp
f01022f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01022f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01022fb:	eb 03                	jmp    f0102300 <strlen+0x10>
		n++;
f01022fd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0102300:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102304:	75 f7                	jne    f01022fd <strlen+0xd>
	return n;
}
f0102306:	5d                   	pop    %ebp
f0102307:	c3                   	ret    

f0102308 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102308:	55                   	push   %ebp
f0102309:	89 e5                	mov    %esp,%ebp
f010230b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010230e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102311:	b8 00 00 00 00       	mov    $0x0,%eax
f0102316:	eb 03                	jmp    f010231b <strnlen+0x13>
		n++;
f0102318:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010231b:	39 d0                	cmp    %edx,%eax
f010231d:	74 06                	je     f0102325 <strnlen+0x1d>
f010231f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0102323:	75 f3                	jne    f0102318 <strnlen+0x10>
	return n;
}
f0102325:	5d                   	pop    %ebp
f0102326:	c3                   	ret    

f0102327 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102327:	55                   	push   %ebp
f0102328:	89 e5                	mov    %esp,%ebp
f010232a:	53                   	push   %ebx
f010232b:	8b 45 08             	mov    0x8(%ebp),%eax
f010232e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102331:	89 c2                	mov    %eax,%edx
f0102333:	83 c1 01             	add    $0x1,%ecx
f0102336:	83 c2 01             	add    $0x1,%edx
f0102339:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010233d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102340:	84 db                	test   %bl,%bl
f0102342:	75 ef                	jne    f0102333 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102344:	5b                   	pop    %ebx
f0102345:	5d                   	pop    %ebp
f0102346:	c3                   	ret    

f0102347 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102347:	55                   	push   %ebp
f0102348:	89 e5                	mov    %esp,%ebp
f010234a:	53                   	push   %ebx
f010234b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010234e:	53                   	push   %ebx
f010234f:	e8 9c ff ff ff       	call   f01022f0 <strlen>
f0102354:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102357:	ff 75 0c             	pushl  0xc(%ebp)
f010235a:	01 d8                	add    %ebx,%eax
f010235c:	50                   	push   %eax
f010235d:	e8 c5 ff ff ff       	call   f0102327 <strcpy>
	return dst;
}
f0102362:	89 d8                	mov    %ebx,%eax
f0102364:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102367:	c9                   	leave  
f0102368:	c3                   	ret    

f0102369 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102369:	55                   	push   %ebp
f010236a:	89 e5                	mov    %esp,%ebp
f010236c:	56                   	push   %esi
f010236d:	53                   	push   %ebx
f010236e:	8b 75 08             	mov    0x8(%ebp),%esi
f0102371:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102374:	89 f3                	mov    %esi,%ebx
f0102376:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102379:	89 f2                	mov    %esi,%edx
f010237b:	eb 0f                	jmp    f010238c <strncpy+0x23>
		*dst++ = *src;
f010237d:	83 c2 01             	add    $0x1,%edx
f0102380:	0f b6 01             	movzbl (%ecx),%eax
f0102383:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102386:	80 39 01             	cmpb   $0x1,(%ecx)
f0102389:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f010238c:	39 da                	cmp    %ebx,%edx
f010238e:	75 ed                	jne    f010237d <strncpy+0x14>
	}
	return ret;
}
f0102390:	89 f0                	mov    %esi,%eax
f0102392:	5b                   	pop    %ebx
f0102393:	5e                   	pop    %esi
f0102394:	5d                   	pop    %ebp
f0102395:	c3                   	ret    

f0102396 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102396:	55                   	push   %ebp
f0102397:	89 e5                	mov    %esp,%ebp
f0102399:	56                   	push   %esi
f010239a:	53                   	push   %ebx
f010239b:	8b 75 08             	mov    0x8(%ebp),%esi
f010239e:	8b 55 0c             	mov    0xc(%ebp),%edx
f01023a1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01023a4:	89 f0                	mov    %esi,%eax
f01023a6:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01023aa:	85 c9                	test   %ecx,%ecx
f01023ac:	75 0b                	jne    f01023b9 <strlcpy+0x23>
f01023ae:	eb 17                	jmp    f01023c7 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01023b0:	83 c2 01             	add    $0x1,%edx
f01023b3:	83 c0 01             	add    $0x1,%eax
f01023b6:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01023b9:	39 d8                	cmp    %ebx,%eax
f01023bb:	74 07                	je     f01023c4 <strlcpy+0x2e>
f01023bd:	0f b6 0a             	movzbl (%edx),%ecx
f01023c0:	84 c9                	test   %cl,%cl
f01023c2:	75 ec                	jne    f01023b0 <strlcpy+0x1a>
		*dst = '\0';
f01023c4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01023c7:	29 f0                	sub    %esi,%eax
}
f01023c9:	5b                   	pop    %ebx
f01023ca:	5e                   	pop    %esi
f01023cb:	5d                   	pop    %ebp
f01023cc:	c3                   	ret    

f01023cd <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01023cd:	55                   	push   %ebp
f01023ce:	89 e5                	mov    %esp,%ebp
f01023d0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01023d3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01023d6:	eb 06                	jmp    f01023de <strcmp+0x11>
		p++, q++;
f01023d8:	83 c1 01             	add    $0x1,%ecx
f01023db:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01023de:	0f b6 01             	movzbl (%ecx),%eax
f01023e1:	84 c0                	test   %al,%al
f01023e3:	74 04                	je     f01023e9 <strcmp+0x1c>
f01023e5:	3a 02                	cmp    (%edx),%al
f01023e7:	74 ef                	je     f01023d8 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01023e9:	0f b6 c0             	movzbl %al,%eax
f01023ec:	0f b6 12             	movzbl (%edx),%edx
f01023ef:	29 d0                	sub    %edx,%eax
}
f01023f1:	5d                   	pop    %ebp
f01023f2:	c3                   	ret    

f01023f3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01023f3:	55                   	push   %ebp
f01023f4:	89 e5                	mov    %esp,%ebp
f01023f6:	53                   	push   %ebx
f01023f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01023fa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01023fd:	89 c3                	mov    %eax,%ebx
f01023ff:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0102402:	eb 06                	jmp    f010240a <strncmp+0x17>
		n--, p++, q++;
f0102404:	83 c0 01             	add    $0x1,%eax
f0102407:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010240a:	39 d8                	cmp    %ebx,%eax
f010240c:	74 16                	je     f0102424 <strncmp+0x31>
f010240e:	0f b6 08             	movzbl (%eax),%ecx
f0102411:	84 c9                	test   %cl,%cl
f0102413:	74 04                	je     f0102419 <strncmp+0x26>
f0102415:	3a 0a                	cmp    (%edx),%cl
f0102417:	74 eb                	je     f0102404 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102419:	0f b6 00             	movzbl (%eax),%eax
f010241c:	0f b6 12             	movzbl (%edx),%edx
f010241f:	29 d0                	sub    %edx,%eax
}
f0102421:	5b                   	pop    %ebx
f0102422:	5d                   	pop    %ebp
f0102423:	c3                   	ret    
		return 0;
f0102424:	b8 00 00 00 00       	mov    $0x0,%eax
f0102429:	eb f6                	jmp    f0102421 <strncmp+0x2e>

f010242b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010242b:	55                   	push   %ebp
f010242c:	89 e5                	mov    %esp,%ebp
f010242e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102431:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102435:	0f b6 10             	movzbl (%eax),%edx
f0102438:	84 d2                	test   %dl,%dl
f010243a:	74 09                	je     f0102445 <strchr+0x1a>
		if (*s == c)
f010243c:	38 ca                	cmp    %cl,%dl
f010243e:	74 0a                	je     f010244a <strchr+0x1f>
	for (; *s; s++)
f0102440:	83 c0 01             	add    $0x1,%eax
f0102443:	eb f0                	jmp    f0102435 <strchr+0xa>
			return (char *) s;
	return 0;
f0102445:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010244a:	5d                   	pop    %ebp
f010244b:	c3                   	ret    

f010244c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010244c:	55                   	push   %ebp
f010244d:	89 e5                	mov    %esp,%ebp
f010244f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102452:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102456:	eb 03                	jmp    f010245b <strfind+0xf>
f0102458:	83 c0 01             	add    $0x1,%eax
f010245b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010245e:	38 ca                	cmp    %cl,%dl
f0102460:	74 04                	je     f0102466 <strfind+0x1a>
f0102462:	84 d2                	test   %dl,%dl
f0102464:	75 f2                	jne    f0102458 <strfind+0xc>
			break;
	return (char *) s;
}
f0102466:	5d                   	pop    %ebp
f0102467:	c3                   	ret    

f0102468 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0102468:	55                   	push   %ebp
f0102469:	89 e5                	mov    %esp,%ebp
f010246b:	57                   	push   %edi
f010246c:	56                   	push   %esi
f010246d:	53                   	push   %ebx
f010246e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102471:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0102474:	85 c9                	test   %ecx,%ecx
f0102476:	74 13                	je     f010248b <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102478:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010247e:	75 05                	jne    f0102485 <memset+0x1d>
f0102480:	f6 c1 03             	test   $0x3,%cl
f0102483:	74 0d                	je     f0102492 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102485:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102488:	fc                   	cld    
f0102489:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010248b:	89 f8                	mov    %edi,%eax
f010248d:	5b                   	pop    %ebx
f010248e:	5e                   	pop    %esi
f010248f:	5f                   	pop    %edi
f0102490:	5d                   	pop    %ebp
f0102491:	c3                   	ret    
		c &= 0xFF;
f0102492:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102496:	89 d3                	mov    %edx,%ebx
f0102498:	c1 e3 08             	shl    $0x8,%ebx
f010249b:	89 d0                	mov    %edx,%eax
f010249d:	c1 e0 18             	shl    $0x18,%eax
f01024a0:	89 d6                	mov    %edx,%esi
f01024a2:	c1 e6 10             	shl    $0x10,%esi
f01024a5:	09 f0                	or     %esi,%eax
f01024a7:	09 c2                	or     %eax,%edx
f01024a9:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01024ab:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01024ae:	89 d0                	mov    %edx,%eax
f01024b0:	fc                   	cld    
f01024b1:	f3 ab                	rep stos %eax,%es:(%edi)
f01024b3:	eb d6                	jmp    f010248b <memset+0x23>

f01024b5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01024b5:	55                   	push   %ebp
f01024b6:	89 e5                	mov    %esp,%ebp
f01024b8:	57                   	push   %edi
f01024b9:	56                   	push   %esi
f01024ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01024bd:	8b 75 0c             	mov    0xc(%ebp),%esi
f01024c0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01024c3:	39 c6                	cmp    %eax,%esi
f01024c5:	73 35                	jae    f01024fc <memmove+0x47>
f01024c7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01024ca:	39 c2                	cmp    %eax,%edx
f01024cc:	76 2e                	jbe    f01024fc <memmove+0x47>
		s += n;
		d += n;
f01024ce:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01024d1:	89 d6                	mov    %edx,%esi
f01024d3:	09 fe                	or     %edi,%esi
f01024d5:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01024db:	74 0c                	je     f01024e9 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01024dd:	83 ef 01             	sub    $0x1,%edi
f01024e0:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01024e3:	fd                   	std    
f01024e4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01024e6:	fc                   	cld    
f01024e7:	eb 21                	jmp    f010250a <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01024e9:	f6 c1 03             	test   $0x3,%cl
f01024ec:	75 ef                	jne    f01024dd <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01024ee:	83 ef 04             	sub    $0x4,%edi
f01024f1:	8d 72 fc             	lea    -0x4(%edx),%esi
f01024f4:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01024f7:	fd                   	std    
f01024f8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01024fa:	eb ea                	jmp    f01024e6 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01024fc:	89 f2                	mov    %esi,%edx
f01024fe:	09 c2                	or     %eax,%edx
f0102500:	f6 c2 03             	test   $0x3,%dl
f0102503:	74 09                	je     f010250e <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102505:	89 c7                	mov    %eax,%edi
f0102507:	fc                   	cld    
f0102508:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010250a:	5e                   	pop    %esi
f010250b:	5f                   	pop    %edi
f010250c:	5d                   	pop    %ebp
f010250d:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010250e:	f6 c1 03             	test   $0x3,%cl
f0102511:	75 f2                	jne    f0102505 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0102513:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0102516:	89 c7                	mov    %eax,%edi
f0102518:	fc                   	cld    
f0102519:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010251b:	eb ed                	jmp    f010250a <memmove+0x55>

f010251d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010251d:	55                   	push   %ebp
f010251e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102520:	ff 75 10             	pushl  0x10(%ebp)
f0102523:	ff 75 0c             	pushl  0xc(%ebp)
f0102526:	ff 75 08             	pushl  0x8(%ebp)
f0102529:	e8 87 ff ff ff       	call   f01024b5 <memmove>
}
f010252e:	c9                   	leave  
f010252f:	c3                   	ret    

f0102530 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102530:	55                   	push   %ebp
f0102531:	89 e5                	mov    %esp,%ebp
f0102533:	56                   	push   %esi
f0102534:	53                   	push   %ebx
f0102535:	8b 45 08             	mov    0x8(%ebp),%eax
f0102538:	8b 55 0c             	mov    0xc(%ebp),%edx
f010253b:	89 c6                	mov    %eax,%esi
f010253d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102540:	39 f0                	cmp    %esi,%eax
f0102542:	74 1c                	je     f0102560 <memcmp+0x30>
		if (*s1 != *s2)
f0102544:	0f b6 08             	movzbl (%eax),%ecx
f0102547:	0f b6 1a             	movzbl (%edx),%ebx
f010254a:	38 d9                	cmp    %bl,%cl
f010254c:	75 08                	jne    f0102556 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010254e:	83 c0 01             	add    $0x1,%eax
f0102551:	83 c2 01             	add    $0x1,%edx
f0102554:	eb ea                	jmp    f0102540 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0102556:	0f b6 c1             	movzbl %cl,%eax
f0102559:	0f b6 db             	movzbl %bl,%ebx
f010255c:	29 d8                	sub    %ebx,%eax
f010255e:	eb 05                	jmp    f0102565 <memcmp+0x35>
	}

	return 0;
f0102560:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102565:	5b                   	pop    %ebx
f0102566:	5e                   	pop    %esi
f0102567:	5d                   	pop    %ebp
f0102568:	c3                   	ret    

f0102569 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102569:	55                   	push   %ebp
f010256a:	89 e5                	mov    %esp,%ebp
f010256c:	8b 45 08             	mov    0x8(%ebp),%eax
f010256f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0102572:	89 c2                	mov    %eax,%edx
f0102574:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0102577:	39 d0                	cmp    %edx,%eax
f0102579:	73 09                	jae    f0102584 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f010257b:	38 08                	cmp    %cl,(%eax)
f010257d:	74 05                	je     f0102584 <memfind+0x1b>
	for (; s < ends; s++)
f010257f:	83 c0 01             	add    $0x1,%eax
f0102582:	eb f3                	jmp    f0102577 <memfind+0xe>
			break;
	return (void *) s;
}
f0102584:	5d                   	pop    %ebp
f0102585:	c3                   	ret    

f0102586 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102586:	55                   	push   %ebp
f0102587:	89 e5                	mov    %esp,%ebp
f0102589:	57                   	push   %edi
f010258a:	56                   	push   %esi
f010258b:	53                   	push   %ebx
f010258c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010258f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102592:	eb 03                	jmp    f0102597 <strtol+0x11>
		s++;
f0102594:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0102597:	0f b6 01             	movzbl (%ecx),%eax
f010259a:	3c 20                	cmp    $0x20,%al
f010259c:	74 f6                	je     f0102594 <strtol+0xe>
f010259e:	3c 09                	cmp    $0x9,%al
f01025a0:	74 f2                	je     f0102594 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01025a2:	3c 2b                	cmp    $0x2b,%al
f01025a4:	74 2e                	je     f01025d4 <strtol+0x4e>
	int neg = 0;
f01025a6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01025ab:	3c 2d                	cmp    $0x2d,%al
f01025ad:	74 2f                	je     f01025de <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01025af:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01025b5:	75 05                	jne    f01025bc <strtol+0x36>
f01025b7:	80 39 30             	cmpb   $0x30,(%ecx)
f01025ba:	74 2c                	je     f01025e8 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01025bc:	85 db                	test   %ebx,%ebx
f01025be:	75 0a                	jne    f01025ca <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01025c0:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01025c5:	80 39 30             	cmpb   $0x30,(%ecx)
f01025c8:	74 28                	je     f01025f2 <strtol+0x6c>
		base = 10;
f01025ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01025cf:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01025d2:	eb 50                	jmp    f0102624 <strtol+0x9e>
		s++;
f01025d4:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01025d7:	bf 00 00 00 00       	mov    $0x0,%edi
f01025dc:	eb d1                	jmp    f01025af <strtol+0x29>
		s++, neg = 1;
f01025de:	83 c1 01             	add    $0x1,%ecx
f01025e1:	bf 01 00 00 00       	mov    $0x1,%edi
f01025e6:	eb c7                	jmp    f01025af <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01025e8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01025ec:	74 0e                	je     f01025fc <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01025ee:	85 db                	test   %ebx,%ebx
f01025f0:	75 d8                	jne    f01025ca <strtol+0x44>
		s++, base = 8;
f01025f2:	83 c1 01             	add    $0x1,%ecx
f01025f5:	bb 08 00 00 00       	mov    $0x8,%ebx
f01025fa:	eb ce                	jmp    f01025ca <strtol+0x44>
		s += 2, base = 16;
f01025fc:	83 c1 02             	add    $0x2,%ecx
f01025ff:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102604:	eb c4                	jmp    f01025ca <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0102606:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102609:	89 f3                	mov    %esi,%ebx
f010260b:	80 fb 19             	cmp    $0x19,%bl
f010260e:	77 29                	ja     f0102639 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0102610:	0f be d2             	movsbl %dl,%edx
f0102613:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0102616:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102619:	7d 30                	jge    f010264b <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010261b:	83 c1 01             	add    $0x1,%ecx
f010261e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0102622:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0102624:	0f b6 11             	movzbl (%ecx),%edx
f0102627:	8d 72 d0             	lea    -0x30(%edx),%esi
f010262a:	89 f3                	mov    %esi,%ebx
f010262c:	80 fb 09             	cmp    $0x9,%bl
f010262f:	77 d5                	ja     f0102606 <strtol+0x80>
			dig = *s - '0';
f0102631:	0f be d2             	movsbl %dl,%edx
f0102634:	83 ea 30             	sub    $0x30,%edx
f0102637:	eb dd                	jmp    f0102616 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0102639:	8d 72 bf             	lea    -0x41(%edx),%esi
f010263c:	89 f3                	mov    %esi,%ebx
f010263e:	80 fb 19             	cmp    $0x19,%bl
f0102641:	77 08                	ja     f010264b <strtol+0xc5>
			dig = *s - 'A' + 10;
f0102643:	0f be d2             	movsbl %dl,%edx
f0102646:	83 ea 37             	sub    $0x37,%edx
f0102649:	eb cb                	jmp    f0102616 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f010264b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010264f:	74 05                	je     f0102656 <strtol+0xd0>
		*endptr = (char *) s;
f0102651:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102654:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0102656:	89 c2                	mov    %eax,%edx
f0102658:	f7 da                	neg    %edx
f010265a:	85 ff                	test   %edi,%edi
f010265c:	0f 45 c2             	cmovne %edx,%eax
}
f010265f:	5b                   	pop    %ebx
f0102660:	5e                   	pop    %esi
f0102661:	5f                   	pop    %edi
f0102662:	5d                   	pop    %ebp
f0102663:	c3                   	ret    
f0102664:	66 90                	xchg   %ax,%ax
f0102666:	66 90                	xchg   %ax,%ax
f0102668:	66 90                	xchg   %ax,%ax
f010266a:	66 90                	xchg   %ax,%ax
f010266c:	66 90                	xchg   %ax,%ax
f010266e:	66 90                	xchg   %ax,%ax

f0102670 <__udivdi3>:
f0102670:	55                   	push   %ebp
f0102671:	57                   	push   %edi
f0102672:	56                   	push   %esi
f0102673:	53                   	push   %ebx
f0102674:	83 ec 1c             	sub    $0x1c,%esp
f0102677:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010267b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010267f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102683:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0102687:	85 d2                	test   %edx,%edx
f0102689:	75 35                	jne    f01026c0 <__udivdi3+0x50>
f010268b:	39 f3                	cmp    %esi,%ebx
f010268d:	0f 87 bd 00 00 00    	ja     f0102750 <__udivdi3+0xe0>
f0102693:	85 db                	test   %ebx,%ebx
f0102695:	89 d9                	mov    %ebx,%ecx
f0102697:	75 0b                	jne    f01026a4 <__udivdi3+0x34>
f0102699:	b8 01 00 00 00       	mov    $0x1,%eax
f010269e:	31 d2                	xor    %edx,%edx
f01026a0:	f7 f3                	div    %ebx
f01026a2:	89 c1                	mov    %eax,%ecx
f01026a4:	31 d2                	xor    %edx,%edx
f01026a6:	89 f0                	mov    %esi,%eax
f01026a8:	f7 f1                	div    %ecx
f01026aa:	89 c6                	mov    %eax,%esi
f01026ac:	89 e8                	mov    %ebp,%eax
f01026ae:	89 f7                	mov    %esi,%edi
f01026b0:	f7 f1                	div    %ecx
f01026b2:	89 fa                	mov    %edi,%edx
f01026b4:	83 c4 1c             	add    $0x1c,%esp
f01026b7:	5b                   	pop    %ebx
f01026b8:	5e                   	pop    %esi
f01026b9:	5f                   	pop    %edi
f01026ba:	5d                   	pop    %ebp
f01026bb:	c3                   	ret    
f01026bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01026c0:	39 f2                	cmp    %esi,%edx
f01026c2:	77 7c                	ja     f0102740 <__udivdi3+0xd0>
f01026c4:	0f bd fa             	bsr    %edx,%edi
f01026c7:	83 f7 1f             	xor    $0x1f,%edi
f01026ca:	0f 84 98 00 00 00    	je     f0102768 <__udivdi3+0xf8>
f01026d0:	89 f9                	mov    %edi,%ecx
f01026d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01026d7:	29 f8                	sub    %edi,%eax
f01026d9:	d3 e2                	shl    %cl,%edx
f01026db:	89 54 24 08          	mov    %edx,0x8(%esp)
f01026df:	89 c1                	mov    %eax,%ecx
f01026e1:	89 da                	mov    %ebx,%edx
f01026e3:	d3 ea                	shr    %cl,%edx
f01026e5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01026e9:	09 d1                	or     %edx,%ecx
f01026eb:	89 f2                	mov    %esi,%edx
f01026ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01026f1:	89 f9                	mov    %edi,%ecx
f01026f3:	d3 e3                	shl    %cl,%ebx
f01026f5:	89 c1                	mov    %eax,%ecx
f01026f7:	d3 ea                	shr    %cl,%edx
f01026f9:	89 f9                	mov    %edi,%ecx
f01026fb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01026ff:	d3 e6                	shl    %cl,%esi
f0102701:	89 eb                	mov    %ebp,%ebx
f0102703:	89 c1                	mov    %eax,%ecx
f0102705:	d3 eb                	shr    %cl,%ebx
f0102707:	09 de                	or     %ebx,%esi
f0102709:	89 f0                	mov    %esi,%eax
f010270b:	f7 74 24 08          	divl   0x8(%esp)
f010270f:	89 d6                	mov    %edx,%esi
f0102711:	89 c3                	mov    %eax,%ebx
f0102713:	f7 64 24 0c          	mull   0xc(%esp)
f0102717:	39 d6                	cmp    %edx,%esi
f0102719:	72 0c                	jb     f0102727 <__udivdi3+0xb7>
f010271b:	89 f9                	mov    %edi,%ecx
f010271d:	d3 e5                	shl    %cl,%ebp
f010271f:	39 c5                	cmp    %eax,%ebp
f0102721:	73 5d                	jae    f0102780 <__udivdi3+0x110>
f0102723:	39 d6                	cmp    %edx,%esi
f0102725:	75 59                	jne    f0102780 <__udivdi3+0x110>
f0102727:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010272a:	31 ff                	xor    %edi,%edi
f010272c:	89 fa                	mov    %edi,%edx
f010272e:	83 c4 1c             	add    $0x1c,%esp
f0102731:	5b                   	pop    %ebx
f0102732:	5e                   	pop    %esi
f0102733:	5f                   	pop    %edi
f0102734:	5d                   	pop    %ebp
f0102735:	c3                   	ret    
f0102736:	8d 76 00             	lea    0x0(%esi),%esi
f0102739:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102740:	31 ff                	xor    %edi,%edi
f0102742:	31 c0                	xor    %eax,%eax
f0102744:	89 fa                	mov    %edi,%edx
f0102746:	83 c4 1c             	add    $0x1c,%esp
f0102749:	5b                   	pop    %ebx
f010274a:	5e                   	pop    %esi
f010274b:	5f                   	pop    %edi
f010274c:	5d                   	pop    %ebp
f010274d:	c3                   	ret    
f010274e:	66 90                	xchg   %ax,%ax
f0102750:	31 ff                	xor    %edi,%edi
f0102752:	89 e8                	mov    %ebp,%eax
f0102754:	89 f2                	mov    %esi,%edx
f0102756:	f7 f3                	div    %ebx
f0102758:	89 fa                	mov    %edi,%edx
f010275a:	83 c4 1c             	add    $0x1c,%esp
f010275d:	5b                   	pop    %ebx
f010275e:	5e                   	pop    %esi
f010275f:	5f                   	pop    %edi
f0102760:	5d                   	pop    %ebp
f0102761:	c3                   	ret    
f0102762:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102768:	39 f2                	cmp    %esi,%edx
f010276a:	72 06                	jb     f0102772 <__udivdi3+0x102>
f010276c:	31 c0                	xor    %eax,%eax
f010276e:	39 eb                	cmp    %ebp,%ebx
f0102770:	77 d2                	ja     f0102744 <__udivdi3+0xd4>
f0102772:	b8 01 00 00 00       	mov    $0x1,%eax
f0102777:	eb cb                	jmp    f0102744 <__udivdi3+0xd4>
f0102779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102780:	89 d8                	mov    %ebx,%eax
f0102782:	31 ff                	xor    %edi,%edi
f0102784:	eb be                	jmp    f0102744 <__udivdi3+0xd4>
f0102786:	66 90                	xchg   %ax,%ax
f0102788:	66 90                	xchg   %ax,%ax
f010278a:	66 90                	xchg   %ax,%ax
f010278c:	66 90                	xchg   %ax,%ax
f010278e:	66 90                	xchg   %ax,%ax

f0102790 <__umoddi3>:
f0102790:	55                   	push   %ebp
f0102791:	57                   	push   %edi
f0102792:	56                   	push   %esi
f0102793:	53                   	push   %ebx
f0102794:	83 ec 1c             	sub    $0x1c,%esp
f0102797:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010279b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010279f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01027a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01027a7:	85 ed                	test   %ebp,%ebp
f01027a9:	89 f0                	mov    %esi,%eax
f01027ab:	89 da                	mov    %ebx,%edx
f01027ad:	75 19                	jne    f01027c8 <__umoddi3+0x38>
f01027af:	39 df                	cmp    %ebx,%edi
f01027b1:	0f 86 b1 00 00 00    	jbe    f0102868 <__umoddi3+0xd8>
f01027b7:	f7 f7                	div    %edi
f01027b9:	89 d0                	mov    %edx,%eax
f01027bb:	31 d2                	xor    %edx,%edx
f01027bd:	83 c4 1c             	add    $0x1c,%esp
f01027c0:	5b                   	pop    %ebx
f01027c1:	5e                   	pop    %esi
f01027c2:	5f                   	pop    %edi
f01027c3:	5d                   	pop    %ebp
f01027c4:	c3                   	ret    
f01027c5:	8d 76 00             	lea    0x0(%esi),%esi
f01027c8:	39 dd                	cmp    %ebx,%ebp
f01027ca:	77 f1                	ja     f01027bd <__umoddi3+0x2d>
f01027cc:	0f bd cd             	bsr    %ebp,%ecx
f01027cf:	83 f1 1f             	xor    $0x1f,%ecx
f01027d2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01027d6:	0f 84 b4 00 00 00    	je     f0102890 <__umoddi3+0x100>
f01027dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01027e1:	89 c2                	mov    %eax,%edx
f01027e3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01027e7:	29 c2                	sub    %eax,%edx
f01027e9:	89 c1                	mov    %eax,%ecx
f01027eb:	89 f8                	mov    %edi,%eax
f01027ed:	d3 e5                	shl    %cl,%ebp
f01027ef:	89 d1                	mov    %edx,%ecx
f01027f1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01027f5:	d3 e8                	shr    %cl,%eax
f01027f7:	09 c5                	or     %eax,%ebp
f01027f9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01027fd:	89 c1                	mov    %eax,%ecx
f01027ff:	d3 e7                	shl    %cl,%edi
f0102801:	89 d1                	mov    %edx,%ecx
f0102803:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0102807:	89 df                	mov    %ebx,%edi
f0102809:	d3 ef                	shr    %cl,%edi
f010280b:	89 c1                	mov    %eax,%ecx
f010280d:	89 f0                	mov    %esi,%eax
f010280f:	d3 e3                	shl    %cl,%ebx
f0102811:	89 d1                	mov    %edx,%ecx
f0102813:	89 fa                	mov    %edi,%edx
f0102815:	d3 e8                	shr    %cl,%eax
f0102817:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010281c:	09 d8                	or     %ebx,%eax
f010281e:	f7 f5                	div    %ebp
f0102820:	d3 e6                	shl    %cl,%esi
f0102822:	89 d1                	mov    %edx,%ecx
f0102824:	f7 64 24 08          	mull   0x8(%esp)
f0102828:	39 d1                	cmp    %edx,%ecx
f010282a:	89 c3                	mov    %eax,%ebx
f010282c:	89 d7                	mov    %edx,%edi
f010282e:	72 06                	jb     f0102836 <__umoddi3+0xa6>
f0102830:	75 0e                	jne    f0102840 <__umoddi3+0xb0>
f0102832:	39 c6                	cmp    %eax,%esi
f0102834:	73 0a                	jae    f0102840 <__umoddi3+0xb0>
f0102836:	2b 44 24 08          	sub    0x8(%esp),%eax
f010283a:	19 ea                	sbb    %ebp,%edx
f010283c:	89 d7                	mov    %edx,%edi
f010283e:	89 c3                	mov    %eax,%ebx
f0102840:	89 ca                	mov    %ecx,%edx
f0102842:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0102847:	29 de                	sub    %ebx,%esi
f0102849:	19 fa                	sbb    %edi,%edx
f010284b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010284f:	89 d0                	mov    %edx,%eax
f0102851:	d3 e0                	shl    %cl,%eax
f0102853:	89 d9                	mov    %ebx,%ecx
f0102855:	d3 ee                	shr    %cl,%esi
f0102857:	d3 ea                	shr    %cl,%edx
f0102859:	09 f0                	or     %esi,%eax
f010285b:	83 c4 1c             	add    $0x1c,%esp
f010285e:	5b                   	pop    %ebx
f010285f:	5e                   	pop    %esi
f0102860:	5f                   	pop    %edi
f0102861:	5d                   	pop    %ebp
f0102862:	c3                   	ret    
f0102863:	90                   	nop
f0102864:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102868:	85 ff                	test   %edi,%edi
f010286a:	89 f9                	mov    %edi,%ecx
f010286c:	75 0b                	jne    f0102879 <__umoddi3+0xe9>
f010286e:	b8 01 00 00 00       	mov    $0x1,%eax
f0102873:	31 d2                	xor    %edx,%edx
f0102875:	f7 f7                	div    %edi
f0102877:	89 c1                	mov    %eax,%ecx
f0102879:	89 d8                	mov    %ebx,%eax
f010287b:	31 d2                	xor    %edx,%edx
f010287d:	f7 f1                	div    %ecx
f010287f:	89 f0                	mov    %esi,%eax
f0102881:	f7 f1                	div    %ecx
f0102883:	e9 31 ff ff ff       	jmp    f01027b9 <__umoddi3+0x29>
f0102888:	90                   	nop
f0102889:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102890:	39 dd                	cmp    %ebx,%ebp
f0102892:	72 08                	jb     f010289c <__umoddi3+0x10c>
f0102894:	39 f7                	cmp    %esi,%edi
f0102896:	0f 87 21 ff ff ff    	ja     f01027bd <__umoddi3+0x2d>
f010289c:	89 da                	mov    %ebx,%edx
f010289e:	89 f0                	mov    %esi,%eax
f01028a0:	29 f8                	sub    %edi,%eax
f01028a2:	19 ea                	sbb    %ebp,%edx
f01028a4:	e9 14 ff ff ff       	jmp    f01027bd <__umoddi3+0x2d>
