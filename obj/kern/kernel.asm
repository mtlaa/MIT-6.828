
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
f0100064:	e8 42 3b 00 00       	call   f0103bab <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 f4 cc fe ff    	lea    -0x1330c(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 18 2f 00 00       	call   f0102f9a <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 de 12 00 00       	call   f0101365 <mem_init>
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
f01000da:	8d 83 0f cd fe ff    	lea    -0x132f1(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 b4 2e 00 00       	call   f0102f9a <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 73 2e 00 00       	call   f0102f63 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 19 dc fe ff    	lea    -0x123e7(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 9c 2e 00 00       	call   f0102f9a <cprintf>
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
f010011f:	8d 83 27 cd fe ff    	lea    -0x132d9(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 6f 2e 00 00       	call   f0102f9a <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 2c 2e 00 00       	call   f0102f63 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 19 dc fe ff    	lea    -0x123e7(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 55 2e 00 00       	call   f0102f9a <cprintf>
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
f0100217:	0f b6 84 13 74 ce fe 	movzbl -0x1318c(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 74 cd fe 	movzbl -0x1328c(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 41 cd fe ff    	lea    -0x132bf(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 24 2d 00 00       	call   f0102f9a <cprintf>
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
f01002b1:	0f b6 84 13 74 ce fe 	movzbl -0x1318c(%ebx,%edx,1),%eax
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
f01004d2:	e8 21 37 00 00       	call   f0103bf8 <memmove>
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
f01006b5:	8d 83 4d cd fe ff    	lea    -0x132b3(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 d9 28 00 00       	call   f0102f9a <cprintf>
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
f0100708:	8d 83 74 cf fe ff    	lea    -0x1308c(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 92 cf fe ff    	lea    -0x1306e(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 97 cf fe ff    	lea    -0x13069(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 78 28 00 00       	call   f0102f9a <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 54 d0 fe ff    	lea    -0x12fac(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 a0 cf fe ff    	lea    -0x13060(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 61 28 00 00       	call   f0102f9a <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 7c d0 fe ff    	lea    -0x12f84(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 a9 cf fe ff    	lea    -0x13057(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 4a 28 00 00       	call   f0102f9a <cprintf>
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
f0100770:	8d 83 b3 cf fe ff    	lea    -0x1304d(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 1e 28 00 00       	call   f0102f9a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f0100785:	8d 83 a0 d0 fe ff    	lea    -0x12f60(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 09 28 00 00       	call   f0102f9a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 c8 d0 fe ff    	lea    -0x12f38(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 ec 27 00 00       	call   f0102f9a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 e9 3f 10 f0    	mov    $0xf0103fe9,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 ec d0 fe ff    	lea    -0x12f14(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 cf 27 00 00       	call   f0102f9a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 10 d1 fe ff    	lea    -0x12ef0(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 b2 27 00 00       	call   f0102f9a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 a0 96 11 f0    	mov    $0xf01196a0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 34 d1 fe ff    	lea    -0x12ecc(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 95 27 00 00       	call   f0102f9a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 58 d1 fe ff    	lea    -0x12ea8(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 7a 27 00 00       	call   f0102f9a <cprintf>
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
f0100841:	8d 83 cc cf fe ff    	lea    -0x13034(%ebx),%eax
f0100847:	50                   	push   %eax
f0100848:	e8 4d 27 00 00       	call   f0102f9a <cprintf>

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
f0100852:	8d 83 de cf fe ff    	lea    -0x13022(%ebx),%eax
f0100858:	89 45 b8             	mov    %eax,-0x48(%ebp)
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
f010085b:	8d 83 f9 cf fe ff    	lea    -0x13007(%ebx),%eax
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
f010087c:	e8 19 27 00 00       	call   f0102f9a <cprintf>
f0100881:	8d 77 08             	lea    0x8(%edi),%esi
f0100884:	83 c7 1c             	add    $0x1c,%edi
f0100887:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	ff 36                	pushl  (%esi)
f010088f:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100892:	e8 03 27 00 00       	call   f0102f9a <cprintf>
f0100897:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	39 fe                	cmp    %edi,%esi
f010089f:	75 e9                	jne    f010088a <mon_backtrace+0x5d>
		}
		cprintf("\n");
f01008a1:	83 ec 0c             	sub    $0xc,%esp
f01008a4:	8d 83 19 dc fe ff    	lea    -0x123e7(%ebx),%eax
f01008aa:	50                   	push   %eax
f01008ab:	e8 ea 26 00 00       	call   f0102f9a <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008b0:	83 c4 08             	add    $0x8,%esp
f01008b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008b6:	50                   	push   %eax
f01008b7:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008ba:	57                   	push   %edi
f01008bb:	e8 de 27 00 00       	call   f010309e <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f01008c0:	83 c4 0c             	add    $0xc,%esp
f01008c3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008c9:	8d 83 ff cf fe ff    	lea    -0x13001(%ebx),%eax
f01008cf:	50                   	push   %eax
f01008d0:	e8 c5 26 00 00       	call   f0102f9a <cprintf>
		// for (int i = 0; i < info.eip_fn_namelen;++i){
		// 	cprintf("%c", info.eip_fn_name[i]);
		// }
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f01008d5:	89 f8                	mov    %edi,%eax
f01008d7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008da:	50                   	push   %eax
f01008db:	ff 75 d8             	pushl  -0x28(%ebp)
f01008de:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e1:	8d 83 0f d0 fe ff    	lea    -0x12ff1(%ebx),%eax
f01008e7:	50                   	push   %eax
f01008e8:	e8 ad 26 00 00       	call   f0102f9a <cprintf>
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
f010091c:	8d 83 84 d1 fe ff    	lea    -0x12e7c(%ebx),%eax
f0100922:	50                   	push   %eax
f0100923:	e8 72 26 00 00       	call   f0102f9a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100928:	8d 83 a8 d1 fe ff    	lea    -0x12e58(%ebx),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 64 26 00 00       	call   f0102f9a <cprintf>
f0100936:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100939:	8d bb 1c d0 fe ff    	lea    -0x12fe4(%ebx),%edi
f010093f:	eb 4a                	jmp    f010098b <monitor+0x83>
f0100941:	83 ec 08             	sub    $0x8,%esp
f0100944:	0f be c0             	movsbl %al,%eax
f0100947:	50                   	push   %eax
f0100948:	57                   	push   %edi
f0100949:	e8 20 32 00 00       	call   f0103b6e <strchr>
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
f010097c:	8d 83 21 d0 fe ff    	lea    -0x12fdf(%ebx),%eax
f0100982:	50                   	push   %eax
f0100983:	e8 12 26 00 00       	call   f0102f9a <cprintf>
f0100988:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010098b:	8d 83 18 d0 fe ff    	lea    -0x12fe8(%ebx),%eax
f0100991:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100994:	83 ec 0c             	sub    $0xc,%esp
f0100997:	ff 75 a4             	pushl  -0x5c(%ebp)
f010099a:	e8 97 2f 00 00       	call   f0103936 <readline>
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
f01009ca:	e8 9f 31 00 00       	call   f0103b6e <strchr>
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
f0100a05:	e8 06 31 00 00       	call   f0103b10 <strcmp>
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
f0100a26:	8d 83 3e d0 fe ff    	lea    -0x12fc2(%ebx),%eax
f0100a2c:	50                   	push   %eax
f0100a2d:	e8 68 25 00 00       	call   f0102f9a <cprintf>
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
f0100a6a:	e8 94 24 00 00       	call   f0102f03 <__x86.get_pc_thunk.dx>
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
f0100ad7:	e8 37 24 00 00       	call   f0102f13 <mc146818_read>
f0100adc:	89 c6                	mov    %eax,%esi
f0100ade:	83 c7 01             	add    $0x1,%edi
f0100ae1:	89 3c 24             	mov    %edi,(%esp)
f0100ae4:	e8 2a 24 00 00       	call   f0102f13 <mc146818_read>
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
f0100afb:	e8 07 24 00 00       	call   f0102f07 <__x86.get_pc_thunk.cx>
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
f0100b52:	8d 81 d0 d1 fe ff    	lea    -0x12e30(%ecx),%eax
f0100b58:	50                   	push   %eax
f0100b59:	68 f9 02 00 00       	push   $0x2f9
f0100b5e:	8d 81 68 d9 fe ff    	lea    -0x12698(%ecx),%eax
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
f0100b7c:	e8 8e 23 00 00       	call   f0102f0f <__x86.get_pc_thunk.di>
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
f0100bb0:	8d 83 f4 d1 fe ff    	lea    -0x12e0c(%ebx),%eax
f0100bb6:	50                   	push   %eax
f0100bb7:	68 3a 02 00 00       	push   $0x23a
f0100bbc:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0100bc2:	50                   	push   %eax
f0100bc3:	e8 d1 f4 ff ff       	call   f0100099 <_panic>
f0100bc8:	50                   	push   %eax
f0100bc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bcc:	8d 83 d0 d1 fe ff    	lea    -0x12e30(%ebx),%eax
f0100bd2:	50                   	push   %eax
f0100bd3:	6a 59                	push   $0x59
f0100bd5:	8d 83 74 d9 fe ff    	lea    -0x1268c(%ebx),%eax
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
f0100c1d:	e8 89 2f 00 00       	call   f0103bab <memset>
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
f0100c66:	8d 83 82 d9 fe ff    	lea    -0x1267e(%ebx),%eax
f0100c6c:	50                   	push   %eax
f0100c6d:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100c73:	50                   	push   %eax
f0100c74:	68 54 02 00 00       	push   $0x254
f0100c79:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0100c7f:	50                   	push   %eax
f0100c80:	e8 14 f4 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100c85:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c88:	8d 83 a3 d9 fe ff    	lea    -0x1265d(%ebx),%eax
f0100c8e:	50                   	push   %eax
f0100c8f:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100c95:	50                   	push   %eax
f0100c96:	68 55 02 00 00       	push   $0x255
f0100c9b:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0100ca1:	50                   	push   %eax
f0100ca2:	e8 f2 f3 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100caa:	8d 83 18 d2 fe ff    	lea    -0x12de8(%ebx),%eax
f0100cb0:	50                   	push   %eax
f0100cb1:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100cb7:	50                   	push   %eax
f0100cb8:	68 56 02 00 00       	push   $0x256
f0100cbd:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0100cc3:	50                   	push   %eax
f0100cc4:	e8 d0 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100cc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ccc:	8d 83 b7 d9 fe ff    	lea    -0x12649(%ebx),%eax
f0100cd2:	50                   	push   %eax
f0100cd3:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100cd9:	50                   	push   %eax
f0100cda:	68 59 02 00 00       	push   $0x259
f0100cdf:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0100ce5:	50                   	push   %eax
f0100ce6:	e8 ae f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ceb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cee:	8d 83 c8 d9 fe ff    	lea    -0x12638(%ebx),%eax
f0100cf4:	50                   	push   %eax
f0100cf5:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100cfb:	50                   	push   %eax
f0100cfc:	68 5a 02 00 00       	push   $0x25a
f0100d01:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0100d07:	50                   	push   %eax
f0100d08:	e8 8c f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d0d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d10:	8d 83 4c d2 fe ff    	lea    -0x12db4(%ebx),%eax
f0100d16:	50                   	push   %eax
f0100d17:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100d1d:	50                   	push   %eax
f0100d1e:	68 5b 02 00 00       	push   $0x25b
f0100d23:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0100d29:	50                   	push   %eax
f0100d2a:	e8 6a f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d2f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d32:	8d 83 e1 d9 fe ff    	lea    -0x1261f(%ebx),%eax
f0100d38:	50                   	push   %eax
f0100d39:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100d3f:	50                   	push   %eax
f0100d40:	68 5c 02 00 00       	push   $0x25c
f0100d45:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
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
f0100dcf:	8d 83 d0 d1 fe ff    	lea    -0x12e30(%ebx),%eax
f0100dd5:	50                   	push   %eax
f0100dd6:	6a 59                	push   $0x59
f0100dd8:	8d 83 74 d9 fe ff    	lea    -0x1268c(%ebx),%eax
f0100dde:	50                   	push   %eax
f0100ddf:	e8 b5 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100de4:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100de7:	8d 83 70 d2 fe ff    	lea    -0x12d90(%ebx),%eax
f0100ded:	50                   	push   %eax
f0100dee:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100df4:	50                   	push   %eax
f0100df5:	68 5d 02 00 00       	push   $0x25d
f0100dfa:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
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
f0100e17:	8d 83 b8 d2 fe ff    	lea    -0x12d48(%ebx),%eax
f0100e1d:	50                   	push   %eax
f0100e1e:	e8 77 21 00 00       	call   f0102f9a <cprintf>
}
f0100e23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e26:	5b                   	pop    %ebx
f0100e27:	5e                   	pop    %esi
f0100e28:	5f                   	pop    %edi
f0100e29:	5d                   	pop    %ebp
f0100e2a:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e2b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e2e:	8d 83 fb d9 fe ff    	lea    -0x12605(%ebx),%eax
f0100e34:	50                   	push   %eax
f0100e35:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100e3b:	50                   	push   %eax
f0100e3c:	68 65 02 00 00       	push   $0x265
f0100e41:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0100e47:	50                   	push   %eax
f0100e48:	e8 4c f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e4d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e50:	8d 83 0d da fe ff    	lea    -0x125f3(%ebx),%eax
f0100e56:	50                   	push   %eax
f0100e57:	8d 83 8e d9 fe ff    	lea    -0x12672(%ebx),%eax
f0100e5d:	50                   	push   %eax
f0100e5e:	68 66 02 00 00       	push   $0x266
f0100e63:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
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
f0100eff:	e8 07 20 00 00       	call   f0102f0b <__x86.get_pc_thunk.si>
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
f0100f4f:	8d 86 dc d2 fe ff    	lea    -0x12d24(%esi),%eax
f0100f55:	50                   	push   %eax
f0100f56:	68 11 01 00 00       	push   $0x111
f0100f5b:	8d 86 68 d9 fe ff    	lea    -0x12698(%esi),%eax
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
f010104d:	e8 59 2b 00 00       	call   f0103bab <memset>
f0101052:	83 c4 10             	add    $0x10,%esp
f0101055:	eb bc                	jmp    f0101013 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101057:	50                   	push   %eax
f0101058:	8d 83 d0 d1 fe ff    	lea    -0x12e30(%ebx),%eax
f010105e:	50                   	push   %eax
f010105f:	6a 59                	push   $0x59
f0101061:	8d 83 74 d9 fe ff    	lea    -0x1268c(%ebx),%eax
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
f01010a4:	8d 83 00 d3 fe ff    	lea    -0x12d00(%ebx),%eax
f01010aa:	50                   	push   %eax
f01010ab:	68 4b 01 00 00       	push   $0x14b
f01010b0:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
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
f0101110:	8b 06                	mov    (%esi),%eax
f0101112:	85 c0                	test   %eax,%eax
f0101114:	75 6d                	jne    f0101183 <pgdir_walk+0x9e>
		if(!create)
f0101116:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010111a:	0f 84 a0 00 00 00    	je     f01011c0 <pgdir_walk+0xdb>
		struct PageInfo *new_page = page_alloc(1);
f0101120:	83 ec 0c             	sub    $0xc,%esp
f0101123:	6a 01                	push   $0x1
f0101125:	e8 bb fe ff ff       	call   f0100fe5 <page_alloc>
		if(!new_page)
f010112a:	83 c4 10             	add    $0x10,%esp
f010112d:	85 c0                	test   %eax,%eax
f010112f:	0f 84 92 00 00 00    	je     f01011c7 <pgdir_walk+0xe2>
		new_page->pp_ref++;
f0101135:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010113a:	c7 c1 b0 96 11 f0    	mov    $0xf01196b0,%ecx
f0101140:	89 c2                	mov    %eax,%edx
f0101142:	2b 11                	sub    (%ecx),%edx
f0101144:	c1 fa 03             	sar    $0x3,%edx
f0101147:	c1 e2 0c             	shl    $0xc,%edx
		*pde = page2pa(new_page) | PTE_P | PTE_W | PTE_U;   // 更新页目录项,为什么要设置 PTE_W  PTE_U 这两位?
f010114a:	83 ca 07             	or     $0x7,%edx
f010114d:	89 16                	mov    %edx,(%esi)
f010114f:	2b 01                	sub    (%ecx),%eax
f0101151:	c1 f8 03             	sar    $0x3,%eax
f0101154:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101157:	89 c1                	mov    %eax,%ecx
f0101159:	c1 e9 0c             	shr    $0xc,%ecx
f010115c:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101162:	3b 0a                	cmp    (%edx),%ecx
f0101164:	73 07                	jae    f010116d <pgdir_walk+0x88>
	return (void *)(pa + KERNBASE);
f0101166:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010116b:	eb 2f                	jmp    f010119c <pgdir_walk+0xb7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010116d:	50                   	push   %eax
f010116e:	8d 83 d0 d1 fe ff    	lea    -0x12e30(%ebx),%eax
f0101174:	50                   	push   %eax
f0101175:	6a 59                	push   $0x59
f0101177:	8d 83 74 d9 fe ff    	lea    -0x1268c(%ebx),%eax
f010117d:	50                   	push   %eax
f010117e:	e8 16 ef ff ff       	call   f0100099 <_panic>
		pte = (pte_t *)KADDR(PTE_ADDR(*pde));
f0101183:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101188:	89 c1                	mov    %eax,%ecx
f010118a:	c1 e9 0c             	shr    $0xc,%ecx
f010118d:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101193:	3b 0a                	cmp    (%edx),%ecx
f0101195:	73 10                	jae    f01011a7 <pgdir_walk+0xc2>
	return (void *)(pa + KERNBASE);
f0101197:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return pte + pgt_index;    // 返回页表项的指针
f010119c:	8d 04 b8             	lea    (%eax,%edi,4),%eax
}
f010119f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a2:	5b                   	pop    %ebx
f01011a3:	5e                   	pop    %esi
f01011a4:	5f                   	pop    %edi
f01011a5:	5d                   	pop    %ebp
f01011a6:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011a7:	50                   	push   %eax
f01011a8:	8d 83 d0 d1 fe ff    	lea    -0x12e30(%ebx),%eax
f01011ae:	50                   	push   %eax
f01011af:	68 8c 01 00 00       	push   $0x18c
f01011b4:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f01011ba:	50                   	push   %eax
f01011bb:	e8 d9 ee ff ff       	call   f0100099 <_panic>
			return NULL;
f01011c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c5:	eb d8                	jmp    f010119f <pgdir_walk+0xba>
			return NULL;
f01011c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01011cc:	eb d1                	jmp    f010119f <pgdir_walk+0xba>

f01011ce <page_lookup>:
{
f01011ce:	55                   	push   %ebp
f01011cf:	89 e5                	mov    %esp,%ebp
f01011d1:	56                   	push   %esi
f01011d2:	53                   	push   %ebx
f01011d3:	e8 77 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01011d8:	81 c3 34 61 01 00    	add    $0x16134,%ebx
f01011de:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);   // 只返回va对应的页表项，不分配新的页表页
f01011e1:	83 ec 04             	sub    $0x4,%esp
f01011e4:	6a 00                	push   $0x0
f01011e6:	ff 75 0c             	pushl  0xc(%ebp)
f01011e9:	ff 75 08             	pushl  0x8(%ebp)
f01011ec:	e8 f4 fe ff ff       	call   f01010e5 <pgdir_walk>
	if(pte_store){
f01011f1:	83 c4 10             	add    $0x10,%esp
f01011f4:	85 f6                	test   %esi,%esi
f01011f6:	74 02                	je     f01011fa <page_lookup+0x2c>
		*pte_store = pte;
f01011f8:	89 06                	mov    %eax,(%esi)
	if(pte){
f01011fa:	85 c0                	test   %eax,%eax
f01011fc:	74 39                	je     f0101237 <page_lookup+0x69>
f01011fe:	8b 00                	mov    (%eax),%eax
f0101200:	c1 e8 0c             	shr    $0xc,%eax

// pa为物理地址，PGNUM(pa)为该页的页号，函数功能与 page2pa 相反
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101203:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101209:	39 02                	cmp    %eax,(%edx)
f010120b:	76 12                	jbe    f010121f <page_lookup+0x51>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010120d:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101213:	8b 12                	mov    (%edx),%edx
f0101215:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101218:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010121b:	5b                   	pop    %ebx
f010121c:	5e                   	pop    %esi
f010121d:	5d                   	pop    %ebp
f010121e:	c3                   	ret    
		panic("pa2page called with invalid pa");
f010121f:	83 ec 04             	sub    $0x4,%esp
f0101222:	8d 83 20 d3 fe ff    	lea    -0x12ce0(%ebx),%eax
f0101228:	50                   	push   %eax
f0101229:	6a 52                	push   $0x52
f010122b:	8d 83 74 d9 fe ff    	lea    -0x1268c(%ebx),%eax
f0101231:	50                   	push   %eax
f0101232:	e8 62 ee ff ff       	call   f0100099 <_panic>
	return NULL;
f0101237:	b8 00 00 00 00       	mov    $0x0,%eax
f010123c:	eb da                	jmp    f0101218 <page_lookup+0x4a>

f010123e <page_remove>:
{
f010123e:	55                   	push   %ebp
f010123f:	89 e5                	mov    %esp,%ebp
f0101241:	53                   	push   %ebx
f0101242:	83 ec 18             	sub    $0x18,%esp
f0101245:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0101248:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010124b:	50                   	push   %eax
f010124c:	53                   	push   %ebx
f010124d:	ff 75 08             	pushl  0x8(%ebp)
f0101250:	e8 79 ff ff ff       	call   f01011ce <page_lookup>
	if (!pp)
f0101255:	83 c4 10             	add    $0x10,%esp
f0101258:	85 c0                	test   %eax,%eax
f010125a:	75 05                	jne    f0101261 <page_remove+0x23>
}
f010125c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010125f:	c9                   	leave  
f0101260:	c3                   	ret    
	page_decref(pp);
f0101261:	83 ec 0c             	sub    $0xc,%esp
f0101264:	50                   	push   %eax
f0101265:	e8 52 fe ff ff       	call   f01010bc <page_decref>
	*pte = 0;
f010126a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010126d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101273:	0f 01 3b             	invlpg (%ebx)
f0101276:	83 c4 10             	add    $0x10,%esp
f0101279:	eb e1                	jmp    f010125c <page_remove+0x1e>

f010127b <page_insert>:
{
f010127b:	55                   	push   %ebp
f010127c:	89 e5                	mov    %esp,%ebp
f010127e:	57                   	push   %edi
f010127f:	56                   	push   %esi
f0101280:	53                   	push   %ebx
f0101281:	83 ec 0c             	sub    $0xc,%esp
f0101284:	e8 c6 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101289:	81 c3 83 60 01 00    	add    $0x16083,%ebx
f010128f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101292:	8b 7d 10             	mov    0x10(%ebp),%edi
	pde_t *pde = pgdir + PDX(va);
f0101295:	89 f8                	mov    %edi,%eax
f0101297:	c1 e8 16             	shr    $0x16,%eax
	if (*pde & PTE_P )
f010129a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010129d:	8b 04 81             	mov    (%ecx,%eax,4),%eax
f01012a0:	a8 01                	test   $0x1,%al
f01012a2:	74 5c                	je     f0101300 <page_insert+0x85>
		pte = (pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f01012a4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01012a9:	89 c2                	mov    %eax,%edx
	if (PGNUM(pa) >= npages)
f01012ab:	c1 e8 0c             	shr    $0xc,%eax
f01012ae:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f01012b4:	39 01                	cmp    %eax,(%ecx)
f01012b6:	0f 86 89 00 00 00    	jbe    f0101345 <page_insert+0xca>
f01012bc:	89 f8                	mov    %edi,%eax
f01012be:	c1 e8 0c             	shr    $0xc,%eax
f01012c1:	25 ff 03 00 00       	and    $0x3ff,%eax
		if(*pte&PTE_P){
f01012c6:	8b 94 82 00 00 00 f0 	mov    -0x10000000(%edx,%eax,4),%edx
f01012cd:	f6 c2 01             	test   $0x1,%dl
f01012d0:	74 2e                	je     f0101300 <page_insert+0x85>
			if(PTE_ADDR(*pte)==page2pa(pp)){
f01012d2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f01012d8:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f01012de:	89 f1                	mov    %esi,%ecx
f01012e0:	2b 08                	sub    (%eax),%ecx
f01012e2:	c1 f9 03             	sar    $0x3,%ecx
f01012e5:	c1 e1 0c             	shl    $0xc,%ecx
				return 0;    // 如果在相同的pgdir中把相同的"pp"重新映射到相同的“va” 则什么也不做
f01012e8:	b8 00 00 00 00       	mov    $0x0,%eax
			if(PTE_ADDR(*pte)==page2pa(pp)){
f01012ed:	39 ca                	cmp    %ecx,%edx
f01012ef:	74 4c                	je     f010133d <page_insert+0xc2>
			page_remove(pgdir, va);
f01012f1:	83 ec 08             	sub    $0x8,%esp
f01012f4:	57                   	push   %edi
f01012f5:	ff 75 08             	pushl  0x8(%ebp)
f01012f8:	e8 41 ff ff ff       	call   f010123e <page_remove>
f01012fd:	83 c4 10             	add    $0x10,%esp
	pte = pgdir_walk(pgdir, va, 1);
f0101300:	83 ec 04             	sub    $0x4,%esp
f0101303:	6a 01                	push   $0x1
f0101305:	57                   	push   %edi
f0101306:	ff 75 08             	pushl  0x8(%ebp)
f0101309:	e8 d7 fd ff ff       	call   f01010e5 <pgdir_walk>
	if(!pte)
f010130e:	83 c4 10             	add    $0x10,%esp
f0101311:	85 c0                	test   %eax,%eax
f0101313:	74 49                	je     f010135e <page_insert+0xe3>
	pp->pp_link = NULL;
f0101315:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	pp->pp_ref++;
f010131b:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f0101320:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101326:	2b 32                	sub    (%edx),%esi
f0101328:	c1 fe 03             	sar    $0x3,%esi
f010132b:	c1 e6 0c             	shl    $0xc,%esi
	*pte = page2pa(pp) | perm | PTE_P;
f010132e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101331:	83 ca 01             	or     $0x1,%edx
f0101334:	09 d6                	or     %edx,%esi
f0101336:	89 30                	mov    %esi,(%eax)
	return 0;
f0101338:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010133d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101340:	5b                   	pop    %ebx
f0101341:	5e                   	pop    %esi
f0101342:	5f                   	pop    %edi
f0101343:	5d                   	pop    %ebp
f0101344:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101345:	52                   	push   %edx
f0101346:	8d 83 d0 d1 fe ff    	lea    -0x12e30(%ebx),%eax
f010134c:	50                   	push   %eax
f010134d:	68 d2 01 00 00       	push   $0x1d2
f0101352:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0101358:	50                   	push   %eax
f0101359:	e8 3b ed ff ff       	call   f0100099 <_panic>
		return -E_NO_MEM;
f010135e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101363:	eb d8                	jmp    f010133d <page_insert+0xc2>

f0101365 <mem_init>:
{
f0101365:	55                   	push   %ebp
f0101366:	89 e5                	mov    %esp,%ebp
f0101368:	57                   	push   %edi
f0101369:	56                   	push   %esi
f010136a:	53                   	push   %ebx
f010136b:	83 ec 3c             	sub    $0x3c,%esp
f010136e:	e8 9c 1b 00 00       	call   f0102f0f <__x86.get_pc_thunk.di>
f0101373:	81 c7 99 5f 01 00    	add    $0x15f99,%edi
	basemem = nvram_read(NVRAM_BASELO);
f0101379:	b8 15 00 00 00       	mov    $0x15,%eax
f010137e:	e8 3d f7 ff ff       	call   f0100ac0 <nvram_read>
f0101383:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101385:	b8 17 00 00 00       	mov    $0x17,%eax
f010138a:	e8 31 f7 ff ff       	call   f0100ac0 <nvram_read>
f010138f:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101391:	b8 34 00 00 00       	mov    $0x34,%eax
f0101396:	e8 25 f7 ff ff       	call   f0100ac0 <nvram_read>
f010139b:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f010139e:	85 c0                	test   %eax,%eax
f01013a0:	0f 85 b9 00 00 00    	jne    f010145f <mem_init+0xfa>
		totalmem = 1 * 1024 + extmem;
f01013a6:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013ac:	85 f6                	test   %esi,%esi
f01013ae:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013b1:	89 c1                	mov    %eax,%ecx
f01013b3:	c1 e9 02             	shr    $0x2,%ecx
f01013b6:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f01013bc:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013be:	89 c2                	mov    %eax,%edx
f01013c0:	29 da                	sub    %ebx,%edx
f01013c2:	52                   	push   %edx
f01013c3:	53                   	push   %ebx
f01013c4:	50                   	push   %eax
f01013c5:	8d 87 40 d3 fe ff    	lea    -0x12cc0(%edi),%eax
f01013cb:	50                   	push   %eax
f01013cc:	89 fb                	mov    %edi,%ebx
f01013ce:	e8 c7 1b 00 00       	call   f0102f9a <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);    // 初始占一整页
f01013d3:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013d8:	e8 8a f6 ff ff       	call   f0100a67 <boot_alloc>
f01013dd:	c7 c6 ac 96 11 f0    	mov    $0xf01196ac,%esi
f01013e3:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);   // 初始化为0
f01013e5:	83 c4 0c             	add    $0xc,%esp
f01013e8:	68 00 10 00 00       	push   $0x1000
f01013ed:	6a 00                	push   $0x0
f01013ef:	50                   	push   %eax
f01013f0:	e8 b6 27 00 00       	call   f0103bab <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013f5:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01013f7:	83 c4 10             	add    $0x10,%esp
f01013fa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013ff:	76 68                	jbe    f0101469 <mem_init+0x104>
	return (physaddr_t)kva - KERNBASE;
f0101401:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101407:	83 ca 05             	or     $0x5,%edx
f010140a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101410:	c7 c3 a8 96 11 f0    	mov    $0xf01196a8,%ebx
f0101416:	8b 03                	mov    (%ebx),%eax
f0101418:	c1 e0 03             	shl    $0x3,%eax
f010141b:	e8 47 f6 ff ff       	call   f0100a67 <boot_alloc>
f0101420:	c7 c6 b0 96 11 f0    	mov    $0xf01196b0,%esi
f0101426:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101428:	83 ec 04             	sub    $0x4,%esp
f010142b:	8b 13                	mov    (%ebx),%edx
f010142d:	c1 e2 03             	shl    $0x3,%edx
f0101430:	52                   	push   %edx
f0101431:	6a 00                	push   $0x0
f0101433:	50                   	push   %eax
f0101434:	89 fb                	mov    %edi,%ebx
f0101436:	e8 70 27 00 00       	call   f0103bab <memset>
	page_init();
f010143b:	e8 b6 fa ff ff       	call   f0100ef6 <page_init>
	check_page_free_list(1);
f0101440:	b8 01 00 00 00       	mov    $0x1,%eax
f0101445:	e8 29 f7 ff ff       	call   f0100b73 <check_page_free_list>
	if (!pages)
f010144a:	83 c4 10             	add    $0x10,%esp
f010144d:	83 3e 00             	cmpl   $0x0,(%esi)
f0101450:	74 30                	je     f0101482 <mem_init+0x11d>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101452:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f0101458:	be 00 00 00 00       	mov    $0x0,%esi
f010145d:	eb 43                	jmp    f01014a2 <mem_init+0x13d>
		totalmem = 16 * 1024 + ext16mem;
f010145f:	05 00 40 00 00       	add    $0x4000,%eax
f0101464:	e9 48 ff ff ff       	jmp    f01013b1 <mem_init+0x4c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101469:	50                   	push   %eax
f010146a:	8d 87 dc d2 fe ff    	lea    -0x12d24(%edi),%eax
f0101470:	50                   	push   %eax
f0101471:	68 9b 00 00 00       	push   $0x9b
f0101476:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010147c:	50                   	push   %eax
f010147d:	e8 17 ec ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101482:	83 ec 04             	sub    $0x4,%esp
f0101485:	8d 87 1e da fe ff    	lea    -0x125e2(%edi),%eax
f010148b:	50                   	push   %eax
f010148c:	68 79 02 00 00       	push   $0x279
f0101491:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0101497:	50                   	push   %eax
f0101498:	e8 fc eb ff ff       	call   f0100099 <_panic>
		++nfree;
f010149d:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014a0:	8b 00                	mov    (%eax),%eax
f01014a2:	85 c0                	test   %eax,%eax
f01014a4:	75 f7                	jne    f010149d <mem_init+0x138>
	assert((pp0 = page_alloc(0)));
f01014a6:	83 ec 0c             	sub    $0xc,%esp
f01014a9:	6a 00                	push   $0x0
f01014ab:	e8 35 fb ff ff       	call   f0100fe5 <page_alloc>
f01014b0:	89 c3                	mov    %eax,%ebx
f01014b2:	83 c4 10             	add    $0x10,%esp
f01014b5:	85 c0                	test   %eax,%eax
f01014b7:	0f 84 3f 02 00 00    	je     f01016fc <mem_init+0x397>
	assert((pp1 = page_alloc(0)));
f01014bd:	83 ec 0c             	sub    $0xc,%esp
f01014c0:	6a 00                	push   $0x0
f01014c2:	e8 1e fb ff ff       	call   f0100fe5 <page_alloc>
f01014c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014ca:	83 c4 10             	add    $0x10,%esp
f01014cd:	85 c0                	test   %eax,%eax
f01014cf:	0f 84 48 02 00 00    	je     f010171d <mem_init+0x3b8>
	assert((pp2 = page_alloc(0)));
f01014d5:	83 ec 0c             	sub    $0xc,%esp
f01014d8:	6a 00                	push   $0x0
f01014da:	e8 06 fb ff ff       	call   f0100fe5 <page_alloc>
f01014df:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01014e2:	83 c4 10             	add    $0x10,%esp
f01014e5:	85 c0                	test   %eax,%eax
f01014e7:	0f 84 51 02 00 00    	je     f010173e <mem_init+0x3d9>
	assert(pp1 && pp1 != pp0);
f01014ed:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01014f0:	0f 84 69 02 00 00    	je     f010175f <mem_init+0x3fa>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014f9:	39 c3                	cmp    %eax,%ebx
f01014fb:	0f 84 7f 02 00 00    	je     f0101780 <mem_init+0x41b>
f0101501:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101504:	0f 84 76 02 00 00    	je     f0101780 <mem_init+0x41b>
	return (pp - pages) << PGSHIFT;
f010150a:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101510:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101512:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0101518:	8b 10                	mov    (%eax),%edx
f010151a:	c1 e2 0c             	shl    $0xc,%edx
f010151d:	89 d8                	mov    %ebx,%eax
f010151f:	29 c8                	sub    %ecx,%eax
f0101521:	c1 f8 03             	sar    $0x3,%eax
f0101524:	c1 e0 0c             	shl    $0xc,%eax
f0101527:	39 d0                	cmp    %edx,%eax
f0101529:	0f 83 72 02 00 00    	jae    f01017a1 <mem_init+0x43c>
f010152f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101532:	29 c8                	sub    %ecx,%eax
f0101534:	c1 f8 03             	sar    $0x3,%eax
f0101537:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010153a:	39 c2                	cmp    %eax,%edx
f010153c:	0f 86 80 02 00 00    	jbe    f01017c2 <mem_init+0x45d>
f0101542:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101545:	29 c8                	sub    %ecx,%eax
f0101547:	c1 f8 03             	sar    $0x3,%eax
f010154a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010154d:	39 c2                	cmp    %eax,%edx
f010154f:	0f 86 8e 02 00 00    	jbe    f01017e3 <mem_init+0x47e>
	fl = page_free_list;
f0101555:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f010155b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f010155e:	c7 87 90 1f 00 00 00 	movl   $0x0,0x1f90(%edi)
f0101565:	00 00 00 
	assert(!page_alloc(0));
f0101568:	83 ec 0c             	sub    $0xc,%esp
f010156b:	6a 00                	push   $0x0
f010156d:	e8 73 fa ff ff       	call   f0100fe5 <page_alloc>
f0101572:	83 c4 10             	add    $0x10,%esp
f0101575:	85 c0                	test   %eax,%eax
f0101577:	0f 85 87 02 00 00    	jne    f0101804 <mem_init+0x49f>
	page_free(pp0);
f010157d:	83 ec 0c             	sub    $0xc,%esp
f0101580:	53                   	push   %ebx
f0101581:	e8 e7 fa ff ff       	call   f010106d <page_free>
	page_free(pp1);
f0101586:	83 c4 04             	add    $0x4,%esp
f0101589:	ff 75 d4             	pushl  -0x2c(%ebp)
f010158c:	e8 dc fa ff ff       	call   f010106d <page_free>
	page_free(pp2);
f0101591:	83 c4 04             	add    $0x4,%esp
f0101594:	ff 75 d0             	pushl  -0x30(%ebp)
f0101597:	e8 d1 fa ff ff       	call   f010106d <page_free>
	assert((pp0 = page_alloc(0)));
f010159c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a3:	e8 3d fa ff ff       	call   f0100fe5 <page_alloc>
f01015a8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015ab:	83 c4 10             	add    $0x10,%esp
f01015ae:	85 c0                	test   %eax,%eax
f01015b0:	0f 84 6f 02 00 00    	je     f0101825 <mem_init+0x4c0>
	assert((pp1 = page_alloc(0)));
f01015b6:	83 ec 0c             	sub    $0xc,%esp
f01015b9:	6a 00                	push   $0x0
f01015bb:	e8 25 fa ff ff       	call   f0100fe5 <page_alloc>
f01015c0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015c3:	83 c4 10             	add    $0x10,%esp
f01015c6:	85 c0                	test   %eax,%eax
f01015c8:	0f 84 78 02 00 00    	je     f0101846 <mem_init+0x4e1>
	assert((pp2 = page_alloc(0)));
f01015ce:	83 ec 0c             	sub    $0xc,%esp
f01015d1:	6a 00                	push   $0x0
f01015d3:	e8 0d fa ff ff       	call   f0100fe5 <page_alloc>
f01015d8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01015db:	83 c4 10             	add    $0x10,%esp
f01015de:	85 c0                	test   %eax,%eax
f01015e0:	0f 84 81 02 00 00    	je     f0101867 <mem_init+0x502>
	assert(pp1 && pp1 != pp0);
f01015e6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01015e9:	39 4d d4             	cmp    %ecx,-0x2c(%ebp)
f01015ec:	0f 84 96 02 00 00    	je     f0101888 <mem_init+0x523>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01015f5:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01015f8:	0f 84 ab 02 00 00    	je     f01018a9 <mem_init+0x544>
f01015fe:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101601:	0f 84 a2 02 00 00    	je     f01018a9 <mem_init+0x544>
	assert(!page_alloc(0));
f0101607:	83 ec 0c             	sub    $0xc,%esp
f010160a:	6a 00                	push   $0x0
f010160c:	e8 d4 f9 ff ff       	call   f0100fe5 <page_alloc>
f0101611:	83 c4 10             	add    $0x10,%esp
f0101614:	85 c0                	test   %eax,%eax
f0101616:	0f 85 ae 02 00 00    	jne    f01018ca <mem_init+0x565>
f010161c:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101622:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101625:	2b 08                	sub    (%eax),%ecx
f0101627:	89 c8                	mov    %ecx,%eax
f0101629:	c1 f8 03             	sar    $0x3,%eax
f010162c:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010162f:	89 c1                	mov    %eax,%ecx
f0101631:	c1 e9 0c             	shr    $0xc,%ecx
f0101634:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f010163a:	3b 0a                	cmp    (%edx),%ecx
f010163c:	0f 83 a9 02 00 00    	jae    f01018eb <mem_init+0x586>
	memset(page2kva(pp0), 1, PGSIZE);
f0101642:	83 ec 04             	sub    $0x4,%esp
f0101645:	68 00 10 00 00       	push   $0x1000
f010164a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010164c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101651:	50                   	push   %eax
f0101652:	89 fb                	mov    %edi,%ebx
f0101654:	e8 52 25 00 00       	call   f0103bab <memset>
	page_free(pp0);
f0101659:	83 c4 04             	add    $0x4,%esp
f010165c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010165f:	e8 09 fa ff ff       	call   f010106d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101664:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010166b:	e8 75 f9 ff ff       	call   f0100fe5 <page_alloc>
f0101670:	83 c4 10             	add    $0x10,%esp
f0101673:	85 c0                	test   %eax,%eax
f0101675:	0f 84 88 02 00 00    	je     f0101903 <mem_init+0x59e>
	assert(pp && pp0 == pp);
f010167b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010167e:	0f 85 9e 02 00 00    	jne    f0101922 <mem_init+0x5bd>
	return (pp - pages) << PGSHIFT;
f0101684:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f010168a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010168d:	2b 10                	sub    (%eax),%edx
f010168f:	c1 fa 03             	sar    $0x3,%edx
f0101692:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101695:	89 d1                	mov    %edx,%ecx
f0101697:	c1 e9 0c             	shr    $0xc,%ecx
f010169a:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f01016a0:	3b 08                	cmp    (%eax),%ecx
f01016a2:	0f 83 99 02 00 00    	jae    f0101941 <mem_init+0x5dc>
	return (void *)(pa + KERNBASE);
f01016a8:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01016ae:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01016b4:	80 38 00             	cmpb   $0x0,(%eax)
f01016b7:	0f 85 9a 02 00 00    	jne    f0101957 <mem_init+0x5f2>
f01016bd:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016c0:	39 d0                	cmp    %edx,%eax
f01016c2:	75 f0                	jne    f01016b4 <mem_init+0x34f>
	page_free_list = fl;
f01016c4:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01016c7:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	page_free(pp0);
f01016cd:	83 ec 0c             	sub    $0xc,%esp
f01016d0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016d3:	e8 95 f9 ff ff       	call   f010106d <page_free>
	page_free(pp1);
f01016d8:	83 c4 04             	add    $0x4,%esp
f01016db:	ff 75 d0             	pushl  -0x30(%ebp)
f01016de:	e8 8a f9 ff ff       	call   f010106d <page_free>
	page_free(pp2);
f01016e3:	83 c4 04             	add    $0x4,%esp
f01016e6:	ff 75 cc             	pushl  -0x34(%ebp)
f01016e9:	e8 7f f9 ff ff       	call   f010106d <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016ee:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f01016f4:	83 c4 10             	add    $0x10,%esp
f01016f7:	e9 81 02 00 00       	jmp    f010197d <mem_init+0x618>
	assert((pp0 = page_alloc(0)));
f01016fc:	8d 87 39 da fe ff    	lea    -0x125c7(%edi),%eax
f0101702:	50                   	push   %eax
f0101703:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0101709:	50                   	push   %eax
f010170a:	68 81 02 00 00       	push   $0x281
f010170f:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0101715:	50                   	push   %eax
f0101716:	89 fb                	mov    %edi,%ebx
f0101718:	e8 7c e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010171d:	8d 87 4f da fe ff    	lea    -0x125b1(%edi),%eax
f0101723:	50                   	push   %eax
f0101724:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010172a:	50                   	push   %eax
f010172b:	68 82 02 00 00       	push   $0x282
f0101730:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0101736:	50                   	push   %eax
f0101737:	89 fb                	mov    %edi,%ebx
f0101739:	e8 5b e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010173e:	8d 87 65 da fe ff    	lea    -0x1259b(%edi),%eax
f0101744:	50                   	push   %eax
f0101745:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010174b:	50                   	push   %eax
f010174c:	68 83 02 00 00       	push   $0x283
f0101751:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0101757:	50                   	push   %eax
f0101758:	89 fb                	mov    %edi,%ebx
f010175a:	e8 3a e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010175f:	8d 87 7b da fe ff    	lea    -0x12585(%edi),%eax
f0101765:	50                   	push   %eax
f0101766:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010176c:	50                   	push   %eax
f010176d:	68 86 02 00 00       	push   $0x286
f0101772:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0101778:	50                   	push   %eax
f0101779:	89 fb                	mov    %edi,%ebx
f010177b:	e8 19 e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101780:	8d 87 7c d3 fe ff    	lea    -0x12c84(%edi),%eax
f0101786:	50                   	push   %eax
f0101787:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010178d:	50                   	push   %eax
f010178e:	68 87 02 00 00       	push   $0x287
f0101793:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0101799:	50                   	push   %eax
f010179a:	89 fb                	mov    %edi,%ebx
f010179c:	e8 f8 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01017a1:	8d 87 8d da fe ff    	lea    -0x12573(%edi),%eax
f01017a7:	50                   	push   %eax
f01017a8:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01017ae:	50                   	push   %eax
f01017af:	68 88 02 00 00       	push   $0x288
f01017b4:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01017ba:	50                   	push   %eax
f01017bb:	89 fb                	mov    %edi,%ebx
f01017bd:	e8 d7 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01017c2:	8d 87 aa da fe ff    	lea    -0x12556(%edi),%eax
f01017c8:	50                   	push   %eax
f01017c9:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01017cf:	50                   	push   %eax
f01017d0:	68 89 02 00 00       	push   $0x289
f01017d5:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01017db:	50                   	push   %eax
f01017dc:	89 fb                	mov    %edi,%ebx
f01017de:	e8 b6 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01017e3:	8d 87 c7 da fe ff    	lea    -0x12539(%edi),%eax
f01017e9:	50                   	push   %eax
f01017ea:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01017f0:	50                   	push   %eax
f01017f1:	68 8a 02 00 00       	push   $0x28a
f01017f6:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01017fc:	50                   	push   %eax
f01017fd:	89 fb                	mov    %edi,%ebx
f01017ff:	e8 95 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101804:	8d 87 e4 da fe ff    	lea    -0x1251c(%edi),%eax
f010180a:	50                   	push   %eax
f010180b:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0101811:	50                   	push   %eax
f0101812:	68 91 02 00 00       	push   $0x291
f0101817:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010181d:	50                   	push   %eax
f010181e:	89 fb                	mov    %edi,%ebx
f0101820:	e8 74 e8 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101825:	8d 87 39 da fe ff    	lea    -0x125c7(%edi),%eax
f010182b:	50                   	push   %eax
f010182c:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0101832:	50                   	push   %eax
f0101833:	68 98 02 00 00       	push   $0x298
f0101838:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010183e:	50                   	push   %eax
f010183f:	89 fb                	mov    %edi,%ebx
f0101841:	e8 53 e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101846:	8d 87 4f da fe ff    	lea    -0x125b1(%edi),%eax
f010184c:	50                   	push   %eax
f010184d:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0101853:	50                   	push   %eax
f0101854:	68 99 02 00 00       	push   $0x299
f0101859:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010185f:	50                   	push   %eax
f0101860:	89 fb                	mov    %edi,%ebx
f0101862:	e8 32 e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101867:	8d 87 65 da fe ff    	lea    -0x1259b(%edi),%eax
f010186d:	50                   	push   %eax
f010186e:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0101874:	50                   	push   %eax
f0101875:	68 9a 02 00 00       	push   $0x29a
f010187a:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0101880:	50                   	push   %eax
f0101881:	89 fb                	mov    %edi,%ebx
f0101883:	e8 11 e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101888:	8d 87 7b da fe ff    	lea    -0x12585(%edi),%eax
f010188e:	50                   	push   %eax
f010188f:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0101895:	50                   	push   %eax
f0101896:	68 9c 02 00 00       	push   $0x29c
f010189b:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01018a1:	50                   	push   %eax
f01018a2:	89 fb                	mov    %edi,%ebx
f01018a4:	e8 f0 e7 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018a9:	8d 87 7c d3 fe ff    	lea    -0x12c84(%edi),%eax
f01018af:	50                   	push   %eax
f01018b0:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01018b6:	50                   	push   %eax
f01018b7:	68 9d 02 00 00       	push   $0x29d
f01018bc:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01018c2:	50                   	push   %eax
f01018c3:	89 fb                	mov    %edi,%ebx
f01018c5:	e8 cf e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01018ca:	8d 87 e4 da fe ff    	lea    -0x1251c(%edi),%eax
f01018d0:	50                   	push   %eax
f01018d1:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01018d7:	50                   	push   %eax
f01018d8:	68 9e 02 00 00       	push   $0x29e
f01018dd:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01018e3:	50                   	push   %eax
f01018e4:	89 fb                	mov    %edi,%ebx
f01018e6:	e8 ae e7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018eb:	50                   	push   %eax
f01018ec:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f01018f2:	50                   	push   %eax
f01018f3:	6a 59                	push   $0x59
f01018f5:	8d 87 74 d9 fe ff    	lea    -0x1268c(%edi),%eax
f01018fb:	50                   	push   %eax
f01018fc:	89 fb                	mov    %edi,%ebx
f01018fe:	e8 96 e7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101903:	8d 87 f3 da fe ff    	lea    -0x1250d(%edi),%eax
f0101909:	50                   	push   %eax
f010190a:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0101910:	50                   	push   %eax
f0101911:	68 a3 02 00 00       	push   $0x2a3
f0101916:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010191c:	50                   	push   %eax
f010191d:	e8 77 e7 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101922:	8d 87 11 db fe ff    	lea    -0x124ef(%edi),%eax
f0101928:	50                   	push   %eax
f0101929:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010192f:	50                   	push   %eax
f0101930:	68 a4 02 00 00       	push   $0x2a4
f0101935:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010193b:	50                   	push   %eax
f010193c:	e8 58 e7 ff ff       	call   f0100099 <_panic>
f0101941:	52                   	push   %edx
f0101942:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f0101948:	50                   	push   %eax
f0101949:	6a 59                	push   $0x59
f010194b:	8d 87 74 d9 fe ff    	lea    -0x1268c(%edi),%eax
f0101951:	50                   	push   %eax
f0101952:	e8 42 e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101957:	8d 87 21 db fe ff    	lea    -0x124df(%edi),%eax
f010195d:	50                   	push   %eax
f010195e:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0101964:	50                   	push   %eax
f0101965:	68 a7 02 00 00       	push   $0x2a7
f010196a:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0101970:	50                   	push   %eax
f0101971:	89 fb                	mov    %edi,%ebx
f0101973:	e8 21 e7 ff ff       	call   f0100099 <_panic>
		--nfree;
f0101978:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010197b:	8b 00                	mov    (%eax),%eax
f010197d:	85 c0                	test   %eax,%eax
f010197f:	75 f7                	jne    f0101978 <mem_init+0x613>
	assert(nfree == 0);
f0101981:	85 f6                	test   %esi,%esi
f0101983:	0f 85 69 07 00 00    	jne    f01020f2 <mem_init+0xd8d>
	cprintf("check_page_alloc() succeeded!\n");
f0101989:	83 ec 0c             	sub    $0xc,%esp
f010198c:	8d 87 9c d3 fe ff    	lea    -0x12c64(%edi),%eax
f0101992:	50                   	push   %eax
f0101993:	89 fb                	mov    %edi,%ebx
f0101995:	e8 00 16 00 00       	call   f0102f9a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010199a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a1:	e8 3f f6 ff ff       	call   f0100fe5 <page_alloc>
f01019a6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019a9:	83 c4 10             	add    $0x10,%esp
f01019ac:	85 c0                	test   %eax,%eax
f01019ae:	0f 84 5f 07 00 00    	je     f0102113 <mem_init+0xdae>
	assert((pp1 = page_alloc(0)));
f01019b4:	83 ec 0c             	sub    $0xc,%esp
f01019b7:	6a 00                	push   $0x0
f01019b9:	e8 27 f6 ff ff       	call   f0100fe5 <page_alloc>
f01019be:	89 c6                	mov    %eax,%esi
f01019c0:	83 c4 10             	add    $0x10,%esp
f01019c3:	85 c0                	test   %eax,%eax
f01019c5:	0f 84 67 07 00 00    	je     f0102132 <mem_init+0xdcd>
	assert((pp2 = page_alloc(0)));
f01019cb:	83 ec 0c             	sub    $0xc,%esp
f01019ce:	6a 00                	push   $0x0
f01019d0:	e8 10 f6 ff ff       	call   f0100fe5 <page_alloc>
f01019d5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019d8:	83 c4 10             	add    $0x10,%esp
f01019db:	85 c0                	test   %eax,%eax
f01019dd:	0f 84 6e 07 00 00    	je     f0102151 <mem_init+0xdec>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019e3:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f01019e6:	0f 84 84 07 00 00    	je     f0102170 <mem_init+0xe0b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019ec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019ef:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01019f2:	0f 84 97 07 00 00    	je     f010218f <mem_init+0xe2a>
f01019f8:	39 c6                	cmp    %eax,%esi
f01019fa:	0f 84 8f 07 00 00    	je     f010218f <mem_init+0xe2a>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a00:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f0101a06:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f0101a09:	c7 87 90 1f 00 00 00 	movl   $0x0,0x1f90(%edi)
f0101a10:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a13:	83 ec 0c             	sub    $0xc,%esp
f0101a16:	6a 00                	push   $0x0
f0101a18:	e8 c8 f5 ff ff       	call   f0100fe5 <page_alloc>
f0101a1d:	83 c4 10             	add    $0x10,%esp
f0101a20:	85 c0                	test   %eax,%eax
f0101a22:	0f 85 88 07 00 00    	jne    f01021b0 <mem_init+0xe4b>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a28:	83 ec 04             	sub    $0x4,%esp
f0101a2b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a2e:	50                   	push   %eax
f0101a2f:	6a 00                	push   $0x0
f0101a31:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a37:	ff 30                	pushl  (%eax)
f0101a39:	e8 90 f7 ff ff       	call   f01011ce <page_lookup>
f0101a3e:	83 c4 10             	add    $0x10,%esp
f0101a41:	85 c0                	test   %eax,%eax
f0101a43:	0f 85 86 07 00 00    	jne    f01021cf <mem_init+0xe6a>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a49:	6a 02                	push   $0x2
f0101a4b:	6a 00                	push   $0x0
f0101a4d:	56                   	push   %esi
f0101a4e:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a54:	ff 30                	pushl  (%eax)
f0101a56:	e8 20 f8 ff ff       	call   f010127b <page_insert>
f0101a5b:	83 c4 10             	add    $0x10,%esp
f0101a5e:	85 c0                	test   %eax,%eax
f0101a60:	0f 89 88 07 00 00    	jns    f01021ee <mem_init+0xe89>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a66:	83 ec 0c             	sub    $0xc,%esp
f0101a69:	ff 75 d0             	pushl  -0x30(%ebp)
f0101a6c:	e8 fc f5 ff ff       	call   f010106d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a71:	6a 02                	push   $0x2
f0101a73:	6a 00                	push   $0x0
f0101a75:	56                   	push   %esi
f0101a76:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a7c:	ff 30                	pushl  (%eax)
f0101a7e:	e8 f8 f7 ff ff       	call   f010127b <page_insert>
f0101a83:	83 c4 20             	add    $0x20,%esp
f0101a86:	85 c0                	test   %eax,%eax
f0101a88:	0f 85 7f 07 00 00    	jne    f010220d <mem_init+0xea8>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a8e:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a94:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101a96:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101a9c:	8b 08                	mov    (%eax),%ecx
f0101a9e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101aa1:	8b 13                	mov    (%ebx),%edx
f0101aa3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101aa9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101aac:	29 c8                	sub    %ecx,%eax
f0101aae:	c1 f8 03             	sar    $0x3,%eax
f0101ab1:	c1 e0 0c             	shl    $0xc,%eax
f0101ab4:	39 c2                	cmp    %eax,%edx
f0101ab6:	0f 85 70 07 00 00    	jne    f010222c <mem_init+0xec7>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101abc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ac1:	89 d8                	mov    %ebx,%eax
f0101ac3:	e8 2e f0 ff ff       	call   f0100af6 <check_va2pa>
f0101ac8:	89 f2                	mov    %esi,%edx
f0101aca:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101acd:	c1 fa 03             	sar    $0x3,%edx
f0101ad0:	c1 e2 0c             	shl    $0xc,%edx
f0101ad3:	39 d0                	cmp    %edx,%eax
f0101ad5:	0f 85 72 07 00 00    	jne    f010224d <mem_init+0xee8>
	assert(pp1->pp_ref == 1);
f0101adb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ae0:	0f 85 88 07 00 00    	jne    f010226e <mem_init+0xf09>
	assert(pp0->pp_ref == 1);
f0101ae6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ae9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101aee:	0f 85 9b 07 00 00    	jne    f010228f <mem_init+0xf2a>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101af4:	6a 02                	push   $0x2
f0101af6:	68 00 10 00 00       	push   $0x1000
f0101afb:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101afe:	53                   	push   %ebx
f0101aff:	e8 77 f7 ff ff       	call   f010127b <page_insert>
f0101b04:	83 c4 10             	add    $0x10,%esp
f0101b07:	85 c0                	test   %eax,%eax
f0101b09:	0f 85 a1 07 00 00    	jne    f01022b0 <mem_init+0xf4b>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b0f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b14:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b1a:	8b 00                	mov    (%eax),%eax
f0101b1c:	e8 d5 ef ff ff       	call   f0100af6 <check_va2pa>
f0101b21:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101b27:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b2a:	2b 0a                	sub    (%edx),%ecx
f0101b2c:	89 ca                	mov    %ecx,%edx
f0101b2e:	c1 fa 03             	sar    $0x3,%edx
f0101b31:	c1 e2 0c             	shl    $0xc,%edx
f0101b34:	39 d0                	cmp    %edx,%eax
f0101b36:	0f 85 95 07 00 00    	jne    f01022d1 <mem_init+0xf6c>
	assert(pp2->pp_ref == 1);
f0101b3c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b3f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b44:	0f 85 a8 07 00 00    	jne    f01022f2 <mem_init+0xf8d>

	// should be no free memory
	assert(!page_alloc(0));
f0101b4a:	83 ec 0c             	sub    $0xc,%esp
f0101b4d:	6a 00                	push   $0x0
f0101b4f:	e8 91 f4 ff ff       	call   f0100fe5 <page_alloc>
f0101b54:	83 c4 10             	add    $0x10,%esp
f0101b57:	85 c0                	test   %eax,%eax
f0101b59:	0f 85 b4 07 00 00    	jne    f0102313 <mem_init+0xfae>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b5f:	6a 02                	push   $0x2
f0101b61:	68 00 10 00 00       	push   $0x1000
f0101b66:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b69:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b6f:	ff 30                	pushl  (%eax)
f0101b71:	e8 05 f7 ff ff       	call   f010127b <page_insert>
f0101b76:	83 c4 10             	add    $0x10,%esp
f0101b79:	85 c0                	test   %eax,%eax
f0101b7b:	0f 85 b3 07 00 00    	jne    f0102334 <mem_init+0xfcf>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b81:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b86:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b8c:	8b 00                	mov    (%eax),%eax
f0101b8e:	e8 63 ef ff ff       	call   f0100af6 <check_va2pa>
f0101b93:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101b99:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b9c:	2b 0a                	sub    (%edx),%ecx
f0101b9e:	89 ca                	mov    %ecx,%edx
f0101ba0:	c1 fa 03             	sar    $0x3,%edx
f0101ba3:	c1 e2 0c             	shl    $0xc,%edx
f0101ba6:	39 d0                	cmp    %edx,%eax
f0101ba8:	0f 85 a7 07 00 00    	jne    f0102355 <mem_init+0xff0>
	assert(pp2->pp_ref == 1);
f0101bae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bb1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bb6:	0f 85 ba 07 00 00    	jne    f0102376 <mem_init+0x1011>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bbc:	83 ec 0c             	sub    $0xc,%esp
f0101bbf:	6a 00                	push   $0x0
f0101bc1:	e8 1f f4 ff ff       	call   f0100fe5 <page_alloc>
f0101bc6:	83 c4 10             	add    $0x10,%esp
f0101bc9:	85 c0                	test   %eax,%eax
f0101bcb:	0f 85 c6 07 00 00    	jne    f0102397 <mem_init+0x1032>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bd1:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101bd7:	8b 10                	mov    (%eax),%edx
f0101bd9:	8b 02                	mov    (%edx),%eax
f0101bdb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101be0:	89 c3                	mov    %eax,%ebx
f0101be2:	c1 eb 0c             	shr    $0xc,%ebx
f0101be5:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f0101beb:	3b 19                	cmp    (%ecx),%ebx
f0101bed:	0f 83 c5 07 00 00    	jae    f01023b8 <mem_init+0x1053>
	return (void *)(pa + KERNBASE);
f0101bf3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101bf8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bfb:	83 ec 04             	sub    $0x4,%esp
f0101bfe:	6a 00                	push   $0x0
f0101c00:	68 00 10 00 00       	push   $0x1000
f0101c05:	52                   	push   %edx
f0101c06:	e8 da f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c0b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c0e:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c11:	83 c4 10             	add    $0x10,%esp
f0101c14:	39 d0                	cmp    %edx,%eax
f0101c16:	0f 85 b7 07 00 00    	jne    f01023d3 <mem_init+0x106e>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c1c:	6a 06                	push   $0x6
f0101c1e:	68 00 10 00 00       	push   $0x1000
f0101c23:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c26:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c2c:	ff 30                	pushl  (%eax)
f0101c2e:	e8 48 f6 ff ff       	call   f010127b <page_insert>
f0101c33:	83 c4 10             	add    $0x10,%esp
f0101c36:	85 c0                	test   %eax,%eax
f0101c38:	0f 85 b6 07 00 00    	jne    f01023f4 <mem_init+0x108f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c3e:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c44:	8b 18                	mov    (%eax),%ebx
f0101c46:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c4b:	89 d8                	mov    %ebx,%eax
f0101c4d:	e8 a4 ee ff ff       	call   f0100af6 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101c52:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101c58:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c5b:	2b 0a                	sub    (%edx),%ecx
f0101c5d:	89 ca                	mov    %ecx,%edx
f0101c5f:	c1 fa 03             	sar    $0x3,%edx
f0101c62:	c1 e2 0c             	shl    $0xc,%edx
f0101c65:	39 d0                	cmp    %edx,%eax
f0101c67:	0f 85 a8 07 00 00    	jne    f0102415 <mem_init+0x10b0>
	assert(pp2->pp_ref == 1);
f0101c6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c70:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c75:	0f 85 bb 07 00 00    	jne    f0102436 <mem_init+0x10d1>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c7b:	83 ec 04             	sub    $0x4,%esp
f0101c7e:	6a 00                	push   $0x0
f0101c80:	68 00 10 00 00       	push   $0x1000
f0101c85:	53                   	push   %ebx
f0101c86:	e8 5a f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c8b:	83 c4 10             	add    $0x10,%esp
f0101c8e:	f6 00 04             	testb  $0x4,(%eax)
f0101c91:	0f 84 c0 07 00 00    	je     f0102457 <mem_init+0x10f2>
	assert(kern_pgdir[0] & PTE_U);
f0101c97:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c9d:	8b 00                	mov    (%eax),%eax
f0101c9f:	f6 00 04             	testb  $0x4,(%eax)
f0101ca2:	0f 84 d0 07 00 00    	je     f0102478 <mem_init+0x1113>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ca8:	6a 02                	push   $0x2
f0101caa:	68 00 10 00 00       	push   $0x1000
f0101caf:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101cb2:	50                   	push   %eax
f0101cb3:	e8 c3 f5 ff ff       	call   f010127b <page_insert>
f0101cb8:	83 c4 10             	add    $0x10,%esp
f0101cbb:	85 c0                	test   %eax,%eax
f0101cbd:	0f 85 d6 07 00 00    	jne    f0102499 <mem_init+0x1134>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101cc3:	83 ec 04             	sub    $0x4,%esp
f0101cc6:	6a 00                	push   $0x0
f0101cc8:	68 00 10 00 00       	push   $0x1000
f0101ccd:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101cd3:	ff 30                	pushl  (%eax)
f0101cd5:	e8 0b f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101cda:	83 c4 10             	add    $0x10,%esp
f0101cdd:	f6 00 02             	testb  $0x2,(%eax)
f0101ce0:	0f 84 d4 07 00 00    	je     f01024ba <mem_init+0x1155>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ce6:	83 ec 04             	sub    $0x4,%esp
f0101ce9:	6a 00                	push   $0x0
f0101ceb:	68 00 10 00 00       	push   $0x1000
f0101cf0:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101cf6:	ff 30                	pushl  (%eax)
f0101cf8:	e8 e8 f3 ff ff       	call   f01010e5 <pgdir_walk>
f0101cfd:	83 c4 10             	add    $0x10,%esp
f0101d00:	f6 00 04             	testb  $0x4,(%eax)
f0101d03:	0f 85 d2 07 00 00    	jne    f01024db <mem_init+0x1176>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d09:	6a 02                	push   $0x2
f0101d0b:	68 00 00 40 00       	push   $0x400000
f0101d10:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d13:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d19:	ff 30                	pushl  (%eax)
f0101d1b:	e8 5b f5 ff ff       	call   f010127b <page_insert>
f0101d20:	83 c4 10             	add    $0x10,%esp
f0101d23:	85 c0                	test   %eax,%eax
f0101d25:	0f 89 d1 07 00 00    	jns    f01024fc <mem_init+0x1197>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d2b:	6a 02                	push   $0x2
f0101d2d:	68 00 10 00 00       	push   $0x1000
f0101d32:	56                   	push   %esi
f0101d33:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d39:	ff 30                	pushl  (%eax)
f0101d3b:	e8 3b f5 ff ff       	call   f010127b <page_insert>
f0101d40:	83 c4 10             	add    $0x10,%esp
f0101d43:	85 c0                	test   %eax,%eax
f0101d45:	0f 85 d2 07 00 00    	jne    f010251d <mem_init+0x11b8>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d4b:	83 ec 04             	sub    $0x4,%esp
f0101d4e:	6a 00                	push   $0x0
f0101d50:	68 00 10 00 00       	push   $0x1000
f0101d55:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d5b:	ff 30                	pushl  (%eax)
f0101d5d:	e8 83 f3 ff ff       	call   f01010e5 <pgdir_walk>
f0101d62:	83 c4 10             	add    $0x10,%esp
f0101d65:	f6 00 04             	testb  $0x4,(%eax)
f0101d68:	0f 85 d0 07 00 00    	jne    f010253e <mem_init+0x11d9>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d6e:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d74:	8b 18                	mov    (%eax),%ebx
f0101d76:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d7b:	89 d8                	mov    %ebx,%eax
f0101d7d:	e8 74 ed ff ff       	call   f0100af6 <check_va2pa>
f0101d82:	89 c2                	mov    %eax,%edx
f0101d84:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d87:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101d8d:	89 f1                	mov    %esi,%ecx
f0101d8f:	2b 08                	sub    (%eax),%ecx
f0101d91:	89 c8                	mov    %ecx,%eax
f0101d93:	c1 f8 03             	sar    $0x3,%eax
f0101d96:	c1 e0 0c             	shl    $0xc,%eax
f0101d99:	39 c2                	cmp    %eax,%edx
f0101d9b:	0f 85 be 07 00 00    	jne    f010255f <mem_init+0x11fa>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101da1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101da6:	89 d8                	mov    %ebx,%eax
f0101da8:	e8 49 ed ff ff       	call   f0100af6 <check_va2pa>
f0101dad:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101db0:	0f 85 ca 07 00 00    	jne    f0102580 <mem_init+0x121b>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101db6:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101dbb:	0f 85 e0 07 00 00    	jne    f01025a1 <mem_init+0x123c>
	assert(pp2->pp_ref == 0);
f0101dc1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc4:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101dc9:	0f 85 f3 07 00 00    	jne    f01025c2 <mem_init+0x125d>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101dcf:	83 ec 0c             	sub    $0xc,%esp
f0101dd2:	6a 00                	push   $0x0
f0101dd4:	e8 0c f2 ff ff       	call   f0100fe5 <page_alloc>
f0101dd9:	83 c4 10             	add    $0x10,%esp
f0101ddc:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101ddf:	0f 85 fe 07 00 00    	jne    f01025e3 <mem_init+0x127e>
f0101de5:	85 c0                	test   %eax,%eax
f0101de7:	0f 84 f6 07 00 00    	je     f01025e3 <mem_init+0x127e>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ded:	83 ec 08             	sub    $0x8,%esp
f0101df0:	6a 00                	push   $0x0
f0101df2:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101df8:	ff 33                	pushl  (%ebx)
f0101dfa:	e8 3f f4 ff ff       	call   f010123e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dff:	8b 1b                	mov    (%ebx),%ebx
f0101e01:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e06:	89 d8                	mov    %ebx,%eax
f0101e08:	e8 e9 ec ff ff       	call   f0100af6 <check_va2pa>
f0101e0d:	83 c4 10             	add    $0x10,%esp
f0101e10:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e13:	0f 85 eb 07 00 00    	jne    f0102604 <mem_init+0x129f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e19:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e1e:	89 d8                	mov    %ebx,%eax
f0101e20:	e8 d1 ec ff ff       	call   f0100af6 <check_va2pa>
f0101e25:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101e2b:	89 f1                	mov    %esi,%ecx
f0101e2d:	2b 0a                	sub    (%edx),%ecx
f0101e2f:	89 ca                	mov    %ecx,%edx
f0101e31:	c1 fa 03             	sar    $0x3,%edx
f0101e34:	c1 e2 0c             	shl    $0xc,%edx
f0101e37:	39 d0                	cmp    %edx,%eax
f0101e39:	0f 85 e6 07 00 00    	jne    f0102625 <mem_init+0x12c0>
	assert(pp1->pp_ref == 1);
f0101e3f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e44:	0f 85 fc 07 00 00    	jne    f0102646 <mem_init+0x12e1>
	assert(pp2->pp_ref == 0);
f0101e4a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e4d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e52:	0f 85 0f 08 00 00    	jne    f0102667 <mem_init+0x1302>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e58:	6a 00                	push   $0x0
f0101e5a:	68 00 10 00 00       	push   $0x1000
f0101e5f:	56                   	push   %esi
f0101e60:	53                   	push   %ebx
f0101e61:	e8 15 f4 ff ff       	call   f010127b <page_insert>
f0101e66:	83 c4 10             	add    $0x10,%esp
f0101e69:	85 c0                	test   %eax,%eax
f0101e6b:	0f 85 17 08 00 00    	jne    f0102688 <mem_init+0x1323>
	assert(pp1->pp_ref);
f0101e71:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e76:	0f 84 2d 08 00 00    	je     f01026a9 <mem_init+0x1344>
	assert(pp1->pp_link == NULL);
f0101e7c:	83 3e 00             	cmpl   $0x0,(%esi)
f0101e7f:	0f 85 45 08 00 00    	jne    f01026ca <mem_init+0x1365>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e85:	83 ec 08             	sub    $0x8,%esp
f0101e88:	68 00 10 00 00       	push   $0x1000
f0101e8d:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101e93:	ff 33                	pushl  (%ebx)
f0101e95:	e8 a4 f3 ff ff       	call   f010123e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e9a:	8b 1b                	mov    (%ebx),%ebx
f0101e9c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ea1:	89 d8                	mov    %ebx,%eax
f0101ea3:	e8 4e ec ff ff       	call   f0100af6 <check_va2pa>
f0101ea8:	83 c4 10             	add    $0x10,%esp
f0101eab:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101eae:	0f 85 37 08 00 00    	jne    f01026eb <mem_init+0x1386>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101eb4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eb9:	89 d8                	mov    %ebx,%eax
f0101ebb:	e8 36 ec ff ff       	call   f0100af6 <check_va2pa>
f0101ec0:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ec3:	0f 85 43 08 00 00    	jne    f010270c <mem_init+0x13a7>
	assert(pp1->pp_ref == 0);
f0101ec9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ece:	0f 85 59 08 00 00    	jne    f010272d <mem_init+0x13c8>
	assert(pp2->pp_ref == 0);
f0101ed4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ed7:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101edc:	0f 85 6c 08 00 00    	jne    f010274e <mem_init+0x13e9>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ee2:	83 ec 0c             	sub    $0xc,%esp
f0101ee5:	6a 00                	push   $0x0
f0101ee7:	e8 f9 f0 ff ff       	call   f0100fe5 <page_alloc>
f0101eec:	83 c4 10             	add    $0x10,%esp
f0101eef:	85 c0                	test   %eax,%eax
f0101ef1:	0f 84 78 08 00 00    	je     f010276f <mem_init+0x140a>
f0101ef7:	39 c6                	cmp    %eax,%esi
f0101ef9:	0f 85 70 08 00 00    	jne    f010276f <mem_init+0x140a>

	// should be no free memory
	assert(!page_alloc(0));
f0101eff:	83 ec 0c             	sub    $0xc,%esp
f0101f02:	6a 00                	push   $0x0
f0101f04:	e8 dc f0 ff ff       	call   f0100fe5 <page_alloc>
f0101f09:	83 c4 10             	add    $0x10,%esp
f0101f0c:	85 c0                	test   %eax,%eax
f0101f0e:	0f 85 7c 08 00 00    	jne    f0102790 <mem_init+0x142b>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f14:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101f1a:	8b 08                	mov    (%eax),%ecx
f0101f1c:	8b 11                	mov    (%ecx),%edx
f0101f1e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f24:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101f2a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f2d:	2b 18                	sub    (%eax),%ebx
f0101f2f:	89 d8                	mov    %ebx,%eax
f0101f31:	c1 f8 03             	sar    $0x3,%eax
f0101f34:	c1 e0 0c             	shl    $0xc,%eax
f0101f37:	39 c2                	cmp    %eax,%edx
f0101f39:	0f 85 72 08 00 00    	jne    f01027b1 <mem_init+0x144c>
	kern_pgdir[0] = 0;
f0101f3f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f45:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f48:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f4d:	0f 85 7f 08 00 00    	jne    f01027d2 <mem_init+0x146d>
	pp0->pp_ref = 0;
f0101f53:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f56:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f5c:	83 ec 0c             	sub    $0xc,%esp
f0101f5f:	50                   	push   %eax
f0101f60:	e8 08 f1 ff ff       	call   f010106d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f65:	83 c4 0c             	add    $0xc,%esp
f0101f68:	6a 01                	push   $0x1
f0101f6a:	68 00 10 40 00       	push   $0x401000
f0101f6f:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101f75:	ff 33                	pushl  (%ebx)
f0101f77:	e8 69 f1 ff ff       	call   f01010e5 <pgdir_walk>
f0101f7c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f7f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f82:	8b 1b                	mov    (%ebx),%ebx
f0101f84:	8b 53 04             	mov    0x4(%ebx),%edx
f0101f87:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101f8d:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f0101f93:	8b 09                	mov    (%ecx),%ecx
f0101f95:	89 d0                	mov    %edx,%eax
f0101f97:	c1 e8 0c             	shr    $0xc,%eax
f0101f9a:	83 c4 10             	add    $0x10,%esp
f0101f9d:	39 c8                	cmp    %ecx,%eax
f0101f9f:	0f 83 4e 08 00 00    	jae    f01027f3 <mem_init+0x148e>
	assert(ptep == ptep1 + PTX(va));
f0101fa5:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101fab:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101fae:	0f 85 5a 08 00 00    	jne    f010280e <mem_init+0x14a9>
	kern_pgdir[PDX(va)] = 0;
f0101fb4:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0101fbb:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101fbe:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0101fc4:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101fca:	2b 18                	sub    (%eax),%ebx
f0101fcc:	89 d8                	mov    %ebx,%eax
f0101fce:	c1 f8 03             	sar    $0x3,%eax
f0101fd1:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101fd4:	89 c2                	mov    %eax,%edx
f0101fd6:	c1 ea 0c             	shr    $0xc,%edx
f0101fd9:	39 d1                	cmp    %edx,%ecx
f0101fdb:	0f 86 4e 08 00 00    	jbe    f010282f <mem_init+0x14ca>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fe1:	83 ec 04             	sub    $0x4,%esp
f0101fe4:	68 00 10 00 00       	push   $0x1000
f0101fe9:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101fee:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ff3:	50                   	push   %eax
f0101ff4:	89 fb                	mov    %edi,%ebx
f0101ff6:	e8 b0 1b 00 00       	call   f0103bab <memset>
	page_free(pp0);
f0101ffb:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101ffe:	89 1c 24             	mov    %ebx,(%esp)
f0102001:	e8 67 f0 ff ff       	call   f010106d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102006:	83 c4 0c             	add    $0xc,%esp
f0102009:	6a 01                	push   $0x1
f010200b:	6a 00                	push   $0x0
f010200d:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102013:	ff 30                	pushl  (%eax)
f0102015:	e8 cb f0 ff ff       	call   f01010e5 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010201a:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102020:	2b 18                	sub    (%eax),%ebx
f0102022:	89 da                	mov    %ebx,%edx
f0102024:	c1 fa 03             	sar    $0x3,%edx
f0102027:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010202a:	89 d1                	mov    %edx,%ecx
f010202c:	c1 e9 0c             	shr    $0xc,%ecx
f010202f:	83 c4 10             	add    $0x10,%esp
f0102032:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0102038:	3b 08                	cmp    (%eax),%ecx
f010203a:	0f 83 07 08 00 00    	jae    f0102847 <mem_init+0x14e2>
	return (void *)(pa + KERNBASE);
f0102040:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102046:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102049:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010204f:	f6 00 01             	testb  $0x1,(%eax)
f0102052:	0f 85 07 08 00 00    	jne    f010285f <mem_init+0x14fa>
f0102058:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f010205b:	39 d0                	cmp    %edx,%eax
f010205d:	75 f0                	jne    f010204f <mem_init+0xcea>
	kern_pgdir[0] = 0;
f010205f:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102065:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102068:	8b 00                	mov    (%eax),%eax
f010206a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102070:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102073:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)

	// give free list back
	page_free_list = fl;
f0102079:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f010207c:	89 9f 90 1f 00 00    	mov    %ebx,0x1f90(%edi)

	// free the pages we took
	page_free(pp0);
f0102082:	83 ec 0c             	sub    $0xc,%esp
f0102085:	51                   	push   %ecx
f0102086:	e8 e2 ef ff ff       	call   f010106d <page_free>
	page_free(pp1);
f010208b:	89 34 24             	mov    %esi,(%esp)
f010208e:	e8 da ef ff ff       	call   f010106d <page_free>
	page_free(pp2);
f0102093:	83 c4 04             	add    $0x4,%esp
f0102096:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102099:	e8 cf ef ff ff       	call   f010106d <page_free>

	cprintf("check_page() succeeded!\n");
f010209e:	8d 87 02 dc fe ff    	lea    -0x123fe(%edi),%eax
f01020a4:	89 04 24             	mov    %eax,(%esp)
f01020a7:	89 fb                	mov    %edi,%ebx
f01020a9:	e8 ec 0e 00 00       	call   f0102f9a <cprintf>
	pgdir = kern_pgdir;
f01020ae:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01020b1:	8b 18                	mov    (%eax),%ebx
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01020b3:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f01020b9:	8b 00                	mov    (%eax),%eax
f01020bb:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01020be:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01020c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01020ca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01020cd:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f01020d3:	8b 00                	mov    (%eax),%eax
f01020d5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01020d8:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01020db:	05 00 00 00 10       	add    $0x10000000,%eax
f01020e0:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f01020e3:	be 00 00 00 00       	mov    $0x0,%esi
f01020e8:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f01020eb:	89 c3                	mov    %eax,%ebx
f01020ed:	e9 b1 07 00 00       	jmp    f01028a3 <mem_init+0x153e>
	assert(nfree == 0);
f01020f2:	8d 87 2b db fe ff    	lea    -0x124d5(%edi),%eax
f01020f8:	50                   	push   %eax
f01020f9:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01020ff:	50                   	push   %eax
f0102100:	68 b4 02 00 00       	push   $0x2b4
f0102105:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010210b:	50                   	push   %eax
f010210c:	89 fb                	mov    %edi,%ebx
f010210e:	e8 86 df ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102113:	8d 87 39 da fe ff    	lea    -0x125c7(%edi),%eax
f0102119:	50                   	push   %eax
f010211a:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102120:	50                   	push   %eax
f0102121:	68 0d 03 00 00       	push   $0x30d
f0102126:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010212c:	50                   	push   %eax
f010212d:	e8 67 df ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102132:	8d 87 4f da fe ff    	lea    -0x125b1(%edi),%eax
f0102138:	50                   	push   %eax
f0102139:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010213f:	50                   	push   %eax
f0102140:	68 0e 03 00 00       	push   $0x30e
f0102145:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010214b:	50                   	push   %eax
f010214c:	e8 48 df ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102151:	8d 87 65 da fe ff    	lea    -0x1259b(%edi),%eax
f0102157:	50                   	push   %eax
f0102158:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010215e:	50                   	push   %eax
f010215f:	68 0f 03 00 00       	push   $0x30f
f0102164:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010216a:	50                   	push   %eax
f010216b:	e8 29 df ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0102170:	8d 87 7b da fe ff    	lea    -0x12585(%edi),%eax
f0102176:	50                   	push   %eax
f0102177:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010217d:	50                   	push   %eax
f010217e:	68 12 03 00 00       	push   $0x312
f0102183:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102189:	50                   	push   %eax
f010218a:	e8 0a df ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010218f:	8d 87 7c d3 fe ff    	lea    -0x12c84(%edi),%eax
f0102195:	50                   	push   %eax
f0102196:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010219c:	50                   	push   %eax
f010219d:	68 13 03 00 00       	push   $0x313
f01021a2:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01021a8:	50                   	push   %eax
f01021a9:	89 fb                	mov    %edi,%ebx
f01021ab:	e8 e9 de ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01021b0:	8d 87 e4 da fe ff    	lea    -0x1251c(%edi),%eax
f01021b6:	50                   	push   %eax
f01021b7:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01021bd:	50                   	push   %eax
f01021be:	68 1a 03 00 00       	push   $0x31a
f01021c3:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01021c9:	50                   	push   %eax
f01021ca:	e8 ca de ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01021cf:	8d 87 bc d3 fe ff    	lea    -0x12c44(%edi),%eax
f01021d5:	50                   	push   %eax
f01021d6:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01021dc:	50                   	push   %eax
f01021dd:	68 1d 03 00 00       	push   $0x31d
f01021e2:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01021e8:	50                   	push   %eax
f01021e9:	e8 ab de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01021ee:	8d 87 f4 d3 fe ff    	lea    -0x12c0c(%edi),%eax
f01021f4:	50                   	push   %eax
f01021f5:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01021fb:	50                   	push   %eax
f01021fc:	68 20 03 00 00       	push   $0x320
f0102201:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102207:	50                   	push   %eax
f0102208:	e8 8c de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010220d:	8d 87 24 d4 fe ff    	lea    -0x12bdc(%edi),%eax
f0102213:	50                   	push   %eax
f0102214:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010221a:	50                   	push   %eax
f010221b:	68 24 03 00 00       	push   $0x324
f0102220:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102226:	50                   	push   %eax
f0102227:	e8 6d de ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010222c:	8d 87 54 d4 fe ff    	lea    -0x12bac(%edi),%eax
f0102232:	50                   	push   %eax
f0102233:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102239:	50                   	push   %eax
f010223a:	68 25 03 00 00       	push   $0x325
f010223f:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102245:	50                   	push   %eax
f0102246:	89 fb                	mov    %edi,%ebx
f0102248:	e8 4c de ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010224d:	8d 87 7c d4 fe ff    	lea    -0x12b84(%edi),%eax
f0102253:	50                   	push   %eax
f0102254:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010225a:	50                   	push   %eax
f010225b:	68 26 03 00 00       	push   $0x326
f0102260:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102266:	50                   	push   %eax
f0102267:	89 fb                	mov    %edi,%ebx
f0102269:	e8 2b de ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f010226e:	8d 87 36 db fe ff    	lea    -0x124ca(%edi),%eax
f0102274:	50                   	push   %eax
f0102275:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010227b:	50                   	push   %eax
f010227c:	68 27 03 00 00       	push   $0x327
f0102281:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102287:	50                   	push   %eax
f0102288:	89 fb                	mov    %edi,%ebx
f010228a:	e8 0a de ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f010228f:	8d 87 47 db fe ff    	lea    -0x124b9(%edi),%eax
f0102295:	50                   	push   %eax
f0102296:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010229c:	50                   	push   %eax
f010229d:	68 28 03 00 00       	push   $0x328
f01022a2:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01022a8:	50                   	push   %eax
f01022a9:	89 fb                	mov    %edi,%ebx
f01022ab:	e8 e9 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022b0:	8d 87 ac d4 fe ff    	lea    -0x12b54(%edi),%eax
f01022b6:	50                   	push   %eax
f01022b7:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01022bd:	50                   	push   %eax
f01022be:	68 2b 03 00 00       	push   $0x32b
f01022c3:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01022c9:	50                   	push   %eax
f01022ca:	89 fb                	mov    %edi,%ebx
f01022cc:	e8 c8 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01022d1:	8d 87 e8 d4 fe ff    	lea    -0x12b18(%edi),%eax
f01022d7:	50                   	push   %eax
f01022d8:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01022de:	50                   	push   %eax
f01022df:	68 2c 03 00 00       	push   $0x32c
f01022e4:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01022ea:	50                   	push   %eax
f01022eb:	89 fb                	mov    %edi,%ebx
f01022ed:	e8 a7 dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01022f2:	8d 87 58 db fe ff    	lea    -0x124a8(%edi),%eax
f01022f8:	50                   	push   %eax
f01022f9:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01022ff:	50                   	push   %eax
f0102300:	68 2d 03 00 00       	push   $0x32d
f0102305:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010230b:	50                   	push   %eax
f010230c:	89 fb                	mov    %edi,%ebx
f010230e:	e8 86 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102313:	8d 87 e4 da fe ff    	lea    -0x1251c(%edi),%eax
f0102319:	50                   	push   %eax
f010231a:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102320:	50                   	push   %eax
f0102321:	68 30 03 00 00       	push   $0x330
f0102326:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010232c:	50                   	push   %eax
f010232d:	89 fb                	mov    %edi,%ebx
f010232f:	e8 65 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102334:	8d 87 ac d4 fe ff    	lea    -0x12b54(%edi),%eax
f010233a:	50                   	push   %eax
f010233b:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102341:	50                   	push   %eax
f0102342:	68 33 03 00 00       	push   $0x333
f0102347:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010234d:	50                   	push   %eax
f010234e:	89 fb                	mov    %edi,%ebx
f0102350:	e8 44 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102355:	8d 87 e8 d4 fe ff    	lea    -0x12b18(%edi),%eax
f010235b:	50                   	push   %eax
f010235c:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102362:	50                   	push   %eax
f0102363:	68 34 03 00 00       	push   $0x334
f0102368:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010236e:	50                   	push   %eax
f010236f:	89 fb                	mov    %edi,%ebx
f0102371:	e8 23 dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102376:	8d 87 58 db fe ff    	lea    -0x124a8(%edi),%eax
f010237c:	50                   	push   %eax
f010237d:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102383:	50                   	push   %eax
f0102384:	68 35 03 00 00       	push   $0x335
f0102389:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010238f:	50                   	push   %eax
f0102390:	89 fb                	mov    %edi,%ebx
f0102392:	e8 02 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102397:	8d 87 e4 da fe ff    	lea    -0x1251c(%edi),%eax
f010239d:	50                   	push   %eax
f010239e:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01023a4:	50                   	push   %eax
f01023a5:	68 39 03 00 00       	push   $0x339
f01023aa:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01023b0:	50                   	push   %eax
f01023b1:	89 fb                	mov    %edi,%ebx
f01023b3:	e8 e1 dc ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023b8:	50                   	push   %eax
f01023b9:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f01023bf:	50                   	push   %eax
f01023c0:	68 3c 03 00 00       	push   $0x33c
f01023c5:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01023cb:	50                   	push   %eax
f01023cc:	89 fb                	mov    %edi,%ebx
f01023ce:	e8 c6 dc ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01023d3:	8d 87 18 d5 fe ff    	lea    -0x12ae8(%edi),%eax
f01023d9:	50                   	push   %eax
f01023da:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01023e0:	50                   	push   %eax
f01023e1:	68 3d 03 00 00       	push   $0x33d
f01023e6:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01023ec:	50                   	push   %eax
f01023ed:	89 fb                	mov    %edi,%ebx
f01023ef:	e8 a5 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01023f4:	8d 87 58 d5 fe ff    	lea    -0x12aa8(%edi),%eax
f01023fa:	50                   	push   %eax
f01023fb:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102401:	50                   	push   %eax
f0102402:	68 40 03 00 00       	push   $0x340
f0102407:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010240d:	50                   	push   %eax
f010240e:	89 fb                	mov    %edi,%ebx
f0102410:	e8 84 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102415:	8d 87 e8 d4 fe ff    	lea    -0x12b18(%edi),%eax
f010241b:	50                   	push   %eax
f010241c:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102422:	50                   	push   %eax
f0102423:	68 41 03 00 00       	push   $0x341
f0102428:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010242e:	50                   	push   %eax
f010242f:	89 fb                	mov    %edi,%ebx
f0102431:	e8 63 dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102436:	8d 87 58 db fe ff    	lea    -0x124a8(%edi),%eax
f010243c:	50                   	push   %eax
f010243d:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102443:	50                   	push   %eax
f0102444:	68 42 03 00 00       	push   $0x342
f0102449:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010244f:	50                   	push   %eax
f0102450:	89 fb                	mov    %edi,%ebx
f0102452:	e8 42 dc ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102457:	8d 87 98 d5 fe ff    	lea    -0x12a68(%edi),%eax
f010245d:	50                   	push   %eax
f010245e:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102464:	50                   	push   %eax
f0102465:	68 43 03 00 00       	push   $0x343
f010246a:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102470:	50                   	push   %eax
f0102471:	89 fb                	mov    %edi,%ebx
f0102473:	e8 21 dc ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102478:	8d 87 69 db fe ff    	lea    -0x12497(%edi),%eax
f010247e:	50                   	push   %eax
f010247f:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102485:	50                   	push   %eax
f0102486:	68 44 03 00 00       	push   $0x344
f010248b:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102491:	50                   	push   %eax
f0102492:	89 fb                	mov    %edi,%ebx
f0102494:	e8 00 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102499:	8d 87 ac d4 fe ff    	lea    -0x12b54(%edi),%eax
f010249f:	50                   	push   %eax
f01024a0:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01024a6:	50                   	push   %eax
f01024a7:	68 47 03 00 00       	push   $0x347
f01024ac:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01024b2:	50                   	push   %eax
f01024b3:	89 fb                	mov    %edi,%ebx
f01024b5:	e8 df db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01024ba:	8d 87 cc d5 fe ff    	lea    -0x12a34(%edi),%eax
f01024c0:	50                   	push   %eax
f01024c1:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01024c7:	50                   	push   %eax
f01024c8:	68 48 03 00 00       	push   $0x348
f01024cd:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01024d3:	50                   	push   %eax
f01024d4:	89 fb                	mov    %edi,%ebx
f01024d6:	e8 be db ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01024db:	8d 87 00 d6 fe ff    	lea    -0x12a00(%edi),%eax
f01024e1:	50                   	push   %eax
f01024e2:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01024e8:	50                   	push   %eax
f01024e9:	68 49 03 00 00       	push   $0x349
f01024ee:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01024f4:	50                   	push   %eax
f01024f5:	89 fb                	mov    %edi,%ebx
f01024f7:	e8 9d db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01024fc:	8d 87 38 d6 fe ff    	lea    -0x129c8(%edi),%eax
f0102502:	50                   	push   %eax
f0102503:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102509:	50                   	push   %eax
f010250a:	68 4c 03 00 00       	push   $0x34c
f010250f:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102515:	50                   	push   %eax
f0102516:	89 fb                	mov    %edi,%ebx
f0102518:	e8 7c db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010251d:	8d 87 70 d6 fe ff    	lea    -0x12990(%edi),%eax
f0102523:	50                   	push   %eax
f0102524:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010252a:	50                   	push   %eax
f010252b:	68 4f 03 00 00       	push   $0x34f
f0102530:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102536:	50                   	push   %eax
f0102537:	89 fb                	mov    %edi,%ebx
f0102539:	e8 5b db ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010253e:	8d 87 00 d6 fe ff    	lea    -0x12a00(%edi),%eax
f0102544:	50                   	push   %eax
f0102545:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010254b:	50                   	push   %eax
f010254c:	68 50 03 00 00       	push   $0x350
f0102551:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102557:	50                   	push   %eax
f0102558:	89 fb                	mov    %edi,%ebx
f010255a:	e8 3a db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010255f:	8d 87 ac d6 fe ff    	lea    -0x12954(%edi),%eax
f0102565:	50                   	push   %eax
f0102566:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010256c:	50                   	push   %eax
f010256d:	68 53 03 00 00       	push   $0x353
f0102572:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102578:	50                   	push   %eax
f0102579:	89 fb                	mov    %edi,%ebx
f010257b:	e8 19 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102580:	8d 87 d8 d6 fe ff    	lea    -0x12928(%edi),%eax
f0102586:	50                   	push   %eax
f0102587:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010258d:	50                   	push   %eax
f010258e:	68 54 03 00 00       	push   $0x354
f0102593:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102599:	50                   	push   %eax
f010259a:	89 fb                	mov    %edi,%ebx
f010259c:	e8 f8 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f01025a1:	8d 87 7f db fe ff    	lea    -0x12481(%edi),%eax
f01025a7:	50                   	push   %eax
f01025a8:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01025ae:	50                   	push   %eax
f01025af:	68 56 03 00 00       	push   $0x356
f01025b4:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01025ba:	50                   	push   %eax
f01025bb:	89 fb                	mov    %edi,%ebx
f01025bd:	e8 d7 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01025c2:	8d 87 90 db fe ff    	lea    -0x12470(%edi),%eax
f01025c8:	50                   	push   %eax
f01025c9:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01025cf:	50                   	push   %eax
f01025d0:	68 57 03 00 00       	push   $0x357
f01025d5:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01025db:	50                   	push   %eax
f01025dc:	89 fb                	mov    %edi,%ebx
f01025de:	e8 b6 da ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01025e3:	8d 87 08 d7 fe ff    	lea    -0x128f8(%edi),%eax
f01025e9:	50                   	push   %eax
f01025ea:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01025f0:	50                   	push   %eax
f01025f1:	68 5a 03 00 00       	push   $0x35a
f01025f6:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01025fc:	50                   	push   %eax
f01025fd:	89 fb                	mov    %edi,%ebx
f01025ff:	e8 95 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102604:	8d 87 2c d7 fe ff    	lea    -0x128d4(%edi),%eax
f010260a:	50                   	push   %eax
f010260b:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102611:	50                   	push   %eax
f0102612:	68 5e 03 00 00       	push   $0x35e
f0102617:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010261d:	50                   	push   %eax
f010261e:	89 fb                	mov    %edi,%ebx
f0102620:	e8 74 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102625:	8d 87 d8 d6 fe ff    	lea    -0x12928(%edi),%eax
f010262b:	50                   	push   %eax
f010262c:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102632:	50                   	push   %eax
f0102633:	68 5f 03 00 00       	push   $0x35f
f0102638:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010263e:	50                   	push   %eax
f010263f:	89 fb                	mov    %edi,%ebx
f0102641:	e8 53 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102646:	8d 87 36 db fe ff    	lea    -0x124ca(%edi),%eax
f010264c:	50                   	push   %eax
f010264d:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102653:	50                   	push   %eax
f0102654:	68 60 03 00 00       	push   $0x360
f0102659:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010265f:	50                   	push   %eax
f0102660:	89 fb                	mov    %edi,%ebx
f0102662:	e8 32 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102667:	8d 87 90 db fe ff    	lea    -0x12470(%edi),%eax
f010266d:	50                   	push   %eax
f010266e:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102674:	50                   	push   %eax
f0102675:	68 61 03 00 00       	push   $0x361
f010267a:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102680:	50                   	push   %eax
f0102681:	89 fb                	mov    %edi,%ebx
f0102683:	e8 11 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102688:	8d 87 50 d7 fe ff    	lea    -0x128b0(%edi),%eax
f010268e:	50                   	push   %eax
f010268f:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102695:	50                   	push   %eax
f0102696:	68 64 03 00 00       	push   $0x364
f010269b:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01026a1:	50                   	push   %eax
f01026a2:	89 fb                	mov    %edi,%ebx
f01026a4:	e8 f0 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f01026a9:	8d 87 a1 db fe ff    	lea    -0x1245f(%edi),%eax
f01026af:	50                   	push   %eax
f01026b0:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01026b6:	50                   	push   %eax
f01026b7:	68 65 03 00 00       	push   $0x365
f01026bc:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01026c2:	50                   	push   %eax
f01026c3:	89 fb                	mov    %edi,%ebx
f01026c5:	e8 cf d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f01026ca:	8d 87 ad db fe ff    	lea    -0x12453(%edi),%eax
f01026d0:	50                   	push   %eax
f01026d1:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01026d7:	50                   	push   %eax
f01026d8:	68 66 03 00 00       	push   $0x366
f01026dd:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01026e3:	50                   	push   %eax
f01026e4:	89 fb                	mov    %edi,%ebx
f01026e6:	e8 ae d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01026eb:	8d 87 2c d7 fe ff    	lea    -0x128d4(%edi),%eax
f01026f1:	50                   	push   %eax
f01026f2:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01026f8:	50                   	push   %eax
f01026f9:	68 6a 03 00 00       	push   $0x36a
f01026fe:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102704:	50                   	push   %eax
f0102705:	89 fb                	mov    %edi,%ebx
f0102707:	e8 8d d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010270c:	8d 87 88 d7 fe ff    	lea    -0x12878(%edi),%eax
f0102712:	50                   	push   %eax
f0102713:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102719:	50                   	push   %eax
f010271a:	68 6b 03 00 00       	push   $0x36b
f010271f:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102725:	50                   	push   %eax
f0102726:	89 fb                	mov    %edi,%ebx
f0102728:	e8 6c d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f010272d:	8d 87 c2 db fe ff    	lea    -0x1243e(%edi),%eax
f0102733:	50                   	push   %eax
f0102734:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010273a:	50                   	push   %eax
f010273b:	68 6c 03 00 00       	push   $0x36c
f0102740:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102746:	50                   	push   %eax
f0102747:	89 fb                	mov    %edi,%ebx
f0102749:	e8 4b d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010274e:	8d 87 90 db fe ff    	lea    -0x12470(%edi),%eax
f0102754:	50                   	push   %eax
f0102755:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010275b:	50                   	push   %eax
f010275c:	68 6d 03 00 00       	push   $0x36d
f0102761:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102767:	50                   	push   %eax
f0102768:	89 fb                	mov    %edi,%ebx
f010276a:	e8 2a d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f010276f:	8d 87 b0 d7 fe ff    	lea    -0x12850(%edi),%eax
f0102775:	50                   	push   %eax
f0102776:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010277c:	50                   	push   %eax
f010277d:	68 70 03 00 00       	push   $0x370
f0102782:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102788:	50                   	push   %eax
f0102789:	89 fb                	mov    %edi,%ebx
f010278b:	e8 09 d9 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102790:	8d 87 e4 da fe ff    	lea    -0x1251c(%edi),%eax
f0102796:	50                   	push   %eax
f0102797:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010279d:	50                   	push   %eax
f010279e:	68 73 03 00 00       	push   $0x373
f01027a3:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01027a9:	50                   	push   %eax
f01027aa:	89 fb                	mov    %edi,%ebx
f01027ac:	e8 e8 d8 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027b1:	8d 87 54 d4 fe ff    	lea    -0x12bac(%edi),%eax
f01027b7:	50                   	push   %eax
f01027b8:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01027be:	50                   	push   %eax
f01027bf:	68 76 03 00 00       	push   $0x376
f01027c4:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01027ca:	50                   	push   %eax
f01027cb:	89 fb                	mov    %edi,%ebx
f01027cd:	e8 c7 d8 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01027d2:	8d 87 47 db fe ff    	lea    -0x124b9(%edi),%eax
f01027d8:	50                   	push   %eax
f01027d9:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01027df:	50                   	push   %eax
f01027e0:	68 78 03 00 00       	push   $0x378
f01027e5:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01027eb:	50                   	push   %eax
f01027ec:	89 fb                	mov    %edi,%ebx
f01027ee:	e8 a6 d8 ff ff       	call   f0100099 <_panic>
f01027f3:	52                   	push   %edx
f01027f4:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f01027fa:	50                   	push   %eax
f01027fb:	68 7f 03 00 00       	push   $0x37f
f0102800:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102806:	50                   	push   %eax
f0102807:	89 fb                	mov    %edi,%ebx
f0102809:	e8 8b d8 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010280e:	8d 87 d3 db fe ff    	lea    -0x1242d(%edi),%eax
f0102814:	50                   	push   %eax
f0102815:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010281b:	50                   	push   %eax
f010281c:	68 80 03 00 00       	push   $0x380
f0102821:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102827:	50                   	push   %eax
f0102828:	89 fb                	mov    %edi,%ebx
f010282a:	e8 6a d8 ff ff       	call   f0100099 <_panic>
f010282f:	50                   	push   %eax
f0102830:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f0102836:	50                   	push   %eax
f0102837:	6a 59                	push   $0x59
f0102839:	8d 87 74 d9 fe ff    	lea    -0x1268c(%edi),%eax
f010283f:	50                   	push   %eax
f0102840:	89 fb                	mov    %edi,%ebx
f0102842:	e8 52 d8 ff ff       	call   f0100099 <_panic>
f0102847:	52                   	push   %edx
f0102848:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f010284e:	50                   	push   %eax
f010284f:	6a 59                	push   $0x59
f0102851:	8d 87 74 d9 fe ff    	lea    -0x1268c(%edi),%eax
f0102857:	50                   	push   %eax
f0102858:	89 fb                	mov    %edi,%ebx
f010285a:	e8 3a d8 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f010285f:	8d 87 eb db fe ff    	lea    -0x12415(%edi),%eax
f0102865:	50                   	push   %eax
f0102866:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010286c:	50                   	push   %eax
f010286d:	68 8a 03 00 00       	push   $0x38a
f0102872:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102878:	50                   	push   %eax
f0102879:	89 fb                	mov    %edi,%ebx
f010287b:	e8 19 d8 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102880:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102883:	8d 87 dc d2 fe ff    	lea    -0x12d24(%edi),%eax
f0102889:	50                   	push   %eax
f010288a:	68 cc 02 00 00       	push   $0x2cc
f010288f:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102895:	50                   	push   %eax
f0102896:	89 fb                	mov    %edi,%ebx
f0102898:	e8 fc d7 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f010289d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028a3:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01028a6:	76 3f                	jbe    f01028e7 <mem_init+0x1582>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01028a8:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f01028ae:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01028b1:	e8 40 e2 ff ff       	call   f0100af6 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01028b6:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01028bd:	76 c1                	jbe    f0102880 <mem_init+0x151b>
f01028bf:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f01028c2:	39 d0                	cmp    %edx,%eax
f01028c4:	74 d7                	je     f010289d <mem_init+0x1538>
f01028c6:	8d 87 d4 d7 fe ff    	lea    -0x1282c(%edi),%eax
f01028cc:	50                   	push   %eax
f01028cd:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01028d3:	50                   	push   %eax
f01028d4:	68 cc 02 00 00       	push   $0x2cc
f01028d9:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01028df:	50                   	push   %eax
f01028e0:	89 fb                	mov    %edi,%ebx
f01028e2:	e8 b2 d7 ff ff       	call   f0100099 <_panic>
f01028e7:	8b 5d d0             	mov    -0x30(%ebp),%ebx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028ea:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01028ed:	c1 e0 0c             	shl    $0xc,%eax
f01028f0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01028f3:	be 00 00 00 00       	mov    $0x0,%esi
f01028f8:	eb 17                	jmp    f0102911 <mem_init+0x15ac>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028fa:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102900:	89 d8                	mov    %ebx,%eax
f0102902:	e8 ef e1 ff ff       	call   f0100af6 <check_va2pa>
f0102907:	39 c6                	cmp    %eax,%esi
f0102909:	75 66                	jne    f0102971 <mem_init+0x160c>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010290b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102911:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102914:	72 e4                	jb     f01028fa <mem_init+0x1595>
f0102916:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010291b:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f0102921:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102924:	05 00 80 00 20       	add    $0x20008000,%eax
f0102929:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010292c:	89 f2                	mov    %esi,%edx
f010292e:	89 d8                	mov    %ebx,%eax
f0102930:	e8 c1 e1 ff ff       	call   f0100af6 <check_va2pa>
f0102935:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010293c:	76 54                	jbe    f0102992 <mem_init+0x162d>
f010293e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102941:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102944:	39 c2                	cmp    %eax,%edx
f0102946:	75 6a                	jne    f01029b2 <mem_init+0x164d>
f0102948:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010294e:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102954:	75 d6                	jne    f010292c <mem_init+0x15c7>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102956:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010295b:	89 d8                	mov    %ebx,%eax
f010295d:	e8 94 e1 ff ff       	call   f0100af6 <check_va2pa>
f0102962:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102965:	75 6c                	jne    f01029d3 <mem_init+0x166e>
	for (i = 0; i < NPDENTRIES; i++) {
f0102967:	b8 00 00 00 00       	mov    $0x0,%eax
f010296c:	e9 ac 00 00 00       	jmp    f0102a1d <mem_init+0x16b8>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102971:	8d 87 08 d8 fe ff    	lea    -0x127f8(%edi),%eax
f0102977:	50                   	push   %eax
f0102978:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f010297e:	50                   	push   %eax
f010297f:	68 d1 02 00 00       	push   $0x2d1
f0102984:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f010298a:	50                   	push   %eax
f010298b:	89 fb                	mov    %edi,%ebx
f010298d:	e8 07 d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102992:	ff b7 fc ff ff ff    	pushl  -0x4(%edi)
f0102998:	8d 87 dc d2 fe ff    	lea    -0x12d24(%edi),%eax
f010299e:	50                   	push   %eax
f010299f:	68 d5 02 00 00       	push   $0x2d5
f01029a4:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01029aa:	50                   	push   %eax
f01029ab:	89 fb                	mov    %edi,%ebx
f01029ad:	e8 e7 d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029b2:	8d 87 30 d8 fe ff    	lea    -0x127d0(%edi),%eax
f01029b8:	50                   	push   %eax
f01029b9:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01029bf:	50                   	push   %eax
f01029c0:	68 d5 02 00 00       	push   $0x2d5
f01029c5:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01029cb:	50                   	push   %eax
f01029cc:	89 fb                	mov    %edi,%ebx
f01029ce:	e8 c6 d6 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029d3:	8d 87 78 d8 fe ff    	lea    -0x12788(%edi),%eax
f01029d9:	50                   	push   %eax
f01029da:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f01029e0:	50                   	push   %eax
f01029e1:	68 d6 02 00 00       	push   $0x2d6
f01029e6:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f01029ec:	50                   	push   %eax
f01029ed:	89 fb                	mov    %edi,%ebx
f01029ef:	e8 a5 d6 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f01029f4:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01029f8:	74 51                	je     f0102a4b <mem_init+0x16e6>
	for (i = 0; i < NPDENTRIES; i++) {
f01029fa:	83 c0 01             	add    $0x1,%eax
f01029fd:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102a02:	0f 87 b3 00 00 00    	ja     f0102abb <mem_init+0x1756>
		switch (i) {
f0102a08:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102a0d:	72 0e                	jb     f0102a1d <mem_init+0x16b8>
f0102a0f:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102a14:	76 de                	jbe    f01029f4 <mem_init+0x168f>
f0102a16:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a1b:	74 d7                	je     f01029f4 <mem_init+0x168f>
			if (i >= PDX(KERNBASE)) {
f0102a1d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a22:	77 48                	ja     f0102a6c <mem_init+0x1707>
				assert(pgdir[i] == 0);
f0102a24:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102a28:	74 d0                	je     f01029fa <mem_init+0x1695>
f0102a2a:	8d 87 3d dc fe ff    	lea    -0x123c3(%edi),%eax
f0102a30:	50                   	push   %eax
f0102a31:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102a37:	50                   	push   %eax
f0102a38:	68 e5 02 00 00       	push   $0x2e5
f0102a3d:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102a43:	50                   	push   %eax
f0102a44:	89 fb                	mov    %edi,%ebx
f0102a46:	e8 4e d6 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102a4b:	8d 87 1b dc fe ff    	lea    -0x123e5(%edi),%eax
f0102a51:	50                   	push   %eax
f0102a52:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102a58:	50                   	push   %eax
f0102a59:	68 de 02 00 00       	push   $0x2de
f0102a5e:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102a64:	50                   	push   %eax
f0102a65:	89 fb                	mov    %edi,%ebx
f0102a67:	e8 2d d6 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102a6c:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102a6f:	f6 c2 01             	test   $0x1,%dl
f0102a72:	74 26                	je     f0102a9a <mem_init+0x1735>
				assert(pgdir[i] & PTE_W);
f0102a74:	f6 c2 02             	test   $0x2,%dl
f0102a77:	75 81                	jne    f01029fa <mem_init+0x1695>
f0102a79:	8d 87 2c dc fe ff    	lea    -0x123d4(%edi),%eax
f0102a7f:	50                   	push   %eax
f0102a80:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102a86:	50                   	push   %eax
f0102a87:	68 e3 02 00 00       	push   $0x2e3
f0102a8c:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102a92:	50                   	push   %eax
f0102a93:	89 fb                	mov    %edi,%ebx
f0102a95:	e8 ff d5 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102a9a:	8d 87 1b dc fe ff    	lea    -0x123e5(%edi),%eax
f0102aa0:	50                   	push   %eax
f0102aa1:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102aa7:	50                   	push   %eax
f0102aa8:	68 e2 02 00 00       	push   $0x2e2
f0102aad:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102ab3:	50                   	push   %eax
f0102ab4:	89 fb                	mov    %edi,%ebx
f0102ab6:	e8 de d5 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102abb:	83 ec 0c             	sub    $0xc,%esp
f0102abe:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102ac4:	50                   	push   %eax
f0102ac5:	89 fb                	mov    %edi,%ebx
f0102ac7:	e8 ce 04 00 00       	call   f0102f9a <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102acc:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102ad2:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102ad4:	83 c4 10             	add    $0x10,%esp
f0102ad7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102adc:	0f 86 33 02 00 00    	jbe    f0102d15 <mem_init+0x19b0>
	return (physaddr_t)kva - KERNBASE;
f0102ae2:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102ae7:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102aea:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aef:	e8 7f e0 ff ff       	call   f0100b73 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102af4:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102af7:	83 e0 f3             	and    $0xfffffff3,%eax
f0102afa:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102aff:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b02:	83 ec 0c             	sub    $0xc,%esp
f0102b05:	6a 00                	push   $0x0
f0102b07:	e8 d9 e4 ff ff       	call   f0100fe5 <page_alloc>
f0102b0c:	89 c6                	mov    %eax,%esi
f0102b0e:	83 c4 10             	add    $0x10,%esp
f0102b11:	85 c0                	test   %eax,%eax
f0102b13:	0f 84 15 02 00 00    	je     f0102d2e <mem_init+0x19c9>
	assert((pp1 = page_alloc(0)));
f0102b19:	83 ec 0c             	sub    $0xc,%esp
f0102b1c:	6a 00                	push   $0x0
f0102b1e:	e8 c2 e4 ff ff       	call   f0100fe5 <page_alloc>
f0102b23:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b26:	83 c4 10             	add    $0x10,%esp
f0102b29:	85 c0                	test   %eax,%eax
f0102b2b:	0f 84 1c 02 00 00    	je     f0102d4d <mem_init+0x19e8>
	assert((pp2 = page_alloc(0)));
f0102b31:	83 ec 0c             	sub    $0xc,%esp
f0102b34:	6a 00                	push   $0x0
f0102b36:	e8 aa e4 ff ff       	call   f0100fe5 <page_alloc>
f0102b3b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b3e:	83 c4 10             	add    $0x10,%esp
f0102b41:	85 c0                	test   %eax,%eax
f0102b43:	0f 84 23 02 00 00    	je     f0102d6c <mem_init+0x1a07>
	page_free(pp0);
f0102b49:	83 ec 0c             	sub    $0xc,%esp
f0102b4c:	56                   	push   %esi
f0102b4d:	e8 1b e5 ff ff       	call   f010106d <page_free>
	return (pp - pages) << PGSHIFT;
f0102b52:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102b58:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102b5b:	2b 08                	sub    (%eax),%ecx
f0102b5d:	89 c8                	mov    %ecx,%eax
f0102b5f:	c1 f8 03             	sar    $0x3,%eax
f0102b62:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102b65:	89 c1                	mov    %eax,%ecx
f0102b67:	c1 e9 0c             	shr    $0xc,%ecx
f0102b6a:	83 c4 10             	add    $0x10,%esp
f0102b6d:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102b73:	3b 0a                	cmp    (%edx),%ecx
f0102b75:	0f 83 10 02 00 00    	jae    f0102d8b <mem_init+0x1a26>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b7b:	83 ec 04             	sub    $0x4,%esp
f0102b7e:	68 00 10 00 00       	push   $0x1000
f0102b83:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102b85:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b8a:	50                   	push   %eax
f0102b8b:	e8 1b 10 00 00       	call   f0103bab <memset>
	return (pp - pages) << PGSHIFT;
f0102b90:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102b96:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102b99:	2b 08                	sub    (%eax),%ecx
f0102b9b:	89 c8                	mov    %ecx,%eax
f0102b9d:	c1 f8 03             	sar    $0x3,%eax
f0102ba0:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102ba3:	89 c1                	mov    %eax,%ecx
f0102ba5:	c1 e9 0c             	shr    $0xc,%ecx
f0102ba8:	83 c4 10             	add    $0x10,%esp
f0102bab:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102bb1:	3b 0a                	cmp    (%edx),%ecx
f0102bb3:	0f 83 e8 01 00 00    	jae    f0102da1 <mem_init+0x1a3c>
	memset(page2kva(pp2), 2, PGSIZE);
f0102bb9:	83 ec 04             	sub    $0x4,%esp
f0102bbc:	68 00 10 00 00       	push   $0x1000
f0102bc1:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102bc3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bc8:	50                   	push   %eax
f0102bc9:	e8 dd 0f 00 00       	call   f0103bab <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102bce:	6a 02                	push   $0x2
f0102bd0:	68 00 10 00 00       	push   $0x1000
f0102bd5:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102bd8:	53                   	push   %ebx
f0102bd9:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102bdf:	ff 30                	pushl  (%eax)
f0102be1:	e8 95 e6 ff ff       	call   f010127b <page_insert>
	assert(pp1->pp_ref == 1);
f0102be6:	83 c4 20             	add    $0x20,%esp
f0102be9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102bee:	0f 85 c3 01 00 00    	jne    f0102db7 <mem_init+0x1a52>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102bf4:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102bfb:	01 01 01 
f0102bfe:	0f 85 d4 01 00 00    	jne    f0102dd8 <mem_init+0x1a73>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c04:	6a 02                	push   $0x2
f0102c06:	68 00 10 00 00       	push   $0x1000
f0102c0b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102c0e:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102c14:	ff 30                	pushl  (%eax)
f0102c16:	e8 60 e6 ff ff       	call   f010127b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c1b:	83 c4 10             	add    $0x10,%esp
f0102c1e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c25:	02 02 02 
f0102c28:	0f 85 cb 01 00 00    	jne    f0102df9 <mem_init+0x1a94>
	assert(pp2->pp_ref == 1);
f0102c2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c31:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102c36:	0f 85 de 01 00 00    	jne    f0102e1a <mem_init+0x1ab5>
	assert(pp1->pp_ref == 0);
f0102c3c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c3f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102c44:	0f 85 f1 01 00 00    	jne    f0102e3b <mem_init+0x1ad6>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c4a:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c51:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102c54:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102c5a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102c5d:	2b 08                	sub    (%eax),%ecx
f0102c5f:	89 c8                	mov    %ecx,%eax
f0102c61:	c1 f8 03             	sar    $0x3,%eax
f0102c64:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102c67:	89 c1                	mov    %eax,%ecx
f0102c69:	c1 e9 0c             	shr    $0xc,%ecx
f0102c6c:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102c72:	3b 0a                	cmp    (%edx),%ecx
f0102c74:	0f 83 e2 01 00 00    	jae    f0102e5c <mem_init+0x1af7>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c7a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c81:	03 03 03 
f0102c84:	0f 85 ea 01 00 00    	jne    f0102e74 <mem_init+0x1b0f>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c8a:	83 ec 08             	sub    $0x8,%esp
f0102c8d:	68 00 10 00 00       	push   $0x1000
f0102c92:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102c98:	ff 30                	pushl  (%eax)
f0102c9a:	e8 9f e5 ff ff       	call   f010123e <page_remove>
	assert(pp2->pp_ref == 0);
f0102c9f:	83 c4 10             	add    $0x10,%esp
f0102ca2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ca5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102caa:	0f 85 e5 01 00 00    	jne    f0102e95 <mem_init+0x1b30>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cb0:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102cb6:	8b 08                	mov    (%eax),%ecx
f0102cb8:	8b 11                	mov    (%ecx),%edx
f0102cba:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102cc0:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102cc6:	89 f3                	mov    %esi,%ebx
f0102cc8:	2b 18                	sub    (%eax),%ebx
f0102cca:	89 d8                	mov    %ebx,%eax
f0102ccc:	c1 f8 03             	sar    $0x3,%eax
f0102ccf:	c1 e0 0c             	shl    $0xc,%eax
f0102cd2:	39 c2                	cmp    %eax,%edx
f0102cd4:	0f 85 dc 01 00 00    	jne    f0102eb6 <mem_init+0x1b51>
	kern_pgdir[0] = 0;
f0102cda:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102ce0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ce5:	0f 85 ec 01 00 00    	jne    f0102ed7 <mem_init+0x1b72>
	pp0->pp_ref = 0;
f0102ceb:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102cf1:	83 ec 0c             	sub    $0xc,%esp
f0102cf4:	56                   	push   %esi
f0102cf5:	e8 73 e3 ff ff       	call   f010106d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102cfa:	8d 87 3c d9 fe ff    	lea    -0x126c4(%edi),%eax
f0102d00:	89 04 24             	mov    %eax,(%esp)
f0102d03:	89 fb                	mov    %edi,%ebx
f0102d05:	e8 90 02 00 00       	call   f0102f9a <cprintf>
}
f0102d0a:	83 c4 10             	add    $0x10,%esp
f0102d0d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d10:	5b                   	pop    %ebx
f0102d11:	5e                   	pop    %esi
f0102d12:	5f                   	pop    %edi
f0102d13:	5d                   	pop    %ebp
f0102d14:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d15:	50                   	push   %eax
f0102d16:	8d 87 dc d2 fe ff    	lea    -0x12d24(%edi),%eax
f0102d1c:	50                   	push   %eax
f0102d1d:	68 df 00 00 00       	push   $0xdf
f0102d22:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102d28:	50                   	push   %eax
f0102d29:	e8 6b d3 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102d2e:	8d 87 39 da fe ff    	lea    -0x125c7(%edi),%eax
f0102d34:	50                   	push   %eax
f0102d35:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102d3b:	50                   	push   %eax
f0102d3c:	68 a5 03 00 00       	push   $0x3a5
f0102d41:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102d47:	50                   	push   %eax
f0102d48:	e8 4c d3 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102d4d:	8d 87 4f da fe ff    	lea    -0x125b1(%edi),%eax
f0102d53:	50                   	push   %eax
f0102d54:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102d5a:	50                   	push   %eax
f0102d5b:	68 a6 03 00 00       	push   $0x3a6
f0102d60:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102d66:	50                   	push   %eax
f0102d67:	e8 2d d3 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102d6c:	8d 87 65 da fe ff    	lea    -0x1259b(%edi),%eax
f0102d72:	50                   	push   %eax
f0102d73:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102d79:	50                   	push   %eax
f0102d7a:	68 a7 03 00 00       	push   $0x3a7
f0102d7f:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102d85:	50                   	push   %eax
f0102d86:	e8 0e d3 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d8b:	50                   	push   %eax
f0102d8c:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f0102d92:	50                   	push   %eax
f0102d93:	6a 59                	push   $0x59
f0102d95:	8d 87 74 d9 fe ff    	lea    -0x1268c(%edi),%eax
f0102d9b:	50                   	push   %eax
f0102d9c:	e8 f8 d2 ff ff       	call   f0100099 <_panic>
f0102da1:	50                   	push   %eax
f0102da2:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f0102da8:	50                   	push   %eax
f0102da9:	6a 59                	push   $0x59
f0102dab:	8d 87 74 d9 fe ff    	lea    -0x1268c(%edi),%eax
f0102db1:	50                   	push   %eax
f0102db2:	e8 e2 d2 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102db7:	8d 87 36 db fe ff    	lea    -0x124ca(%edi),%eax
f0102dbd:	50                   	push   %eax
f0102dbe:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102dc4:	50                   	push   %eax
f0102dc5:	68 ac 03 00 00       	push   $0x3ac
f0102dca:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102dd0:	50                   	push   %eax
f0102dd1:	89 fb                	mov    %edi,%ebx
f0102dd3:	e8 c1 d2 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102dd8:	8d 87 c8 d8 fe ff    	lea    -0x12738(%edi),%eax
f0102dde:	50                   	push   %eax
f0102ddf:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102de5:	50                   	push   %eax
f0102de6:	68 ad 03 00 00       	push   $0x3ad
f0102deb:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102df1:	50                   	push   %eax
f0102df2:	89 fb                	mov    %edi,%ebx
f0102df4:	e8 a0 d2 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102df9:	8d 87 ec d8 fe ff    	lea    -0x12714(%edi),%eax
f0102dff:	50                   	push   %eax
f0102e00:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102e06:	50                   	push   %eax
f0102e07:	68 af 03 00 00       	push   $0x3af
f0102e0c:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102e12:	50                   	push   %eax
f0102e13:	89 fb                	mov    %edi,%ebx
f0102e15:	e8 7f d2 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102e1a:	8d 87 58 db fe ff    	lea    -0x124a8(%edi),%eax
f0102e20:	50                   	push   %eax
f0102e21:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102e27:	50                   	push   %eax
f0102e28:	68 b0 03 00 00       	push   $0x3b0
f0102e2d:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102e33:	50                   	push   %eax
f0102e34:	89 fb                	mov    %edi,%ebx
f0102e36:	e8 5e d2 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102e3b:	8d 87 c2 db fe ff    	lea    -0x1243e(%edi),%eax
f0102e41:	50                   	push   %eax
f0102e42:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102e48:	50                   	push   %eax
f0102e49:	68 b1 03 00 00       	push   $0x3b1
f0102e4e:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102e54:	50                   	push   %eax
f0102e55:	89 fb                	mov    %edi,%ebx
f0102e57:	e8 3d d2 ff ff       	call   f0100099 <_panic>
f0102e5c:	50                   	push   %eax
f0102e5d:	8d 87 d0 d1 fe ff    	lea    -0x12e30(%edi),%eax
f0102e63:	50                   	push   %eax
f0102e64:	6a 59                	push   $0x59
f0102e66:	8d 87 74 d9 fe ff    	lea    -0x1268c(%edi),%eax
f0102e6c:	50                   	push   %eax
f0102e6d:	89 fb                	mov    %edi,%ebx
f0102e6f:	e8 25 d2 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102e74:	8d 87 10 d9 fe ff    	lea    -0x126f0(%edi),%eax
f0102e7a:	50                   	push   %eax
f0102e7b:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102e81:	50                   	push   %eax
f0102e82:	68 b3 03 00 00       	push   $0x3b3
f0102e87:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102e8d:	50                   	push   %eax
f0102e8e:	89 fb                	mov    %edi,%ebx
f0102e90:	e8 04 d2 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102e95:	8d 87 90 db fe ff    	lea    -0x12470(%edi),%eax
f0102e9b:	50                   	push   %eax
f0102e9c:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102ea2:	50                   	push   %eax
f0102ea3:	68 b5 03 00 00       	push   $0x3b5
f0102ea8:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102eae:	50                   	push   %eax
f0102eaf:	89 fb                	mov    %edi,%ebx
f0102eb1:	e8 e3 d1 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102eb6:	8d 87 54 d4 fe ff    	lea    -0x12bac(%edi),%eax
f0102ebc:	50                   	push   %eax
f0102ebd:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102ec3:	50                   	push   %eax
f0102ec4:	68 b8 03 00 00       	push   $0x3b8
f0102ec9:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102ecf:	50                   	push   %eax
f0102ed0:	89 fb                	mov    %edi,%ebx
f0102ed2:	e8 c2 d1 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102ed7:	8d 87 47 db fe ff    	lea    -0x124b9(%edi),%eax
f0102edd:	50                   	push   %eax
f0102ede:	8d 87 8e d9 fe ff    	lea    -0x12672(%edi),%eax
f0102ee4:	50                   	push   %eax
f0102ee5:	68 ba 03 00 00       	push   $0x3ba
f0102eea:	8d 87 68 d9 fe ff    	lea    -0x12698(%edi),%eax
f0102ef0:	50                   	push   %eax
f0102ef1:	89 fb                	mov    %edi,%ebx
f0102ef3:	e8 a1 d1 ff ff       	call   f0100099 <_panic>

f0102ef8 <tlb_invalidate>:
{
f0102ef8:	55                   	push   %ebp
f0102ef9:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102efb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102efe:	0f 01 38             	invlpg (%eax)
}
f0102f01:	5d                   	pop    %ebp
f0102f02:	c3                   	ret    

f0102f03 <__x86.get_pc_thunk.dx>:
f0102f03:	8b 14 24             	mov    (%esp),%edx
f0102f06:	c3                   	ret    

f0102f07 <__x86.get_pc_thunk.cx>:
f0102f07:	8b 0c 24             	mov    (%esp),%ecx
f0102f0a:	c3                   	ret    

f0102f0b <__x86.get_pc_thunk.si>:
f0102f0b:	8b 34 24             	mov    (%esp),%esi
f0102f0e:	c3                   	ret    

f0102f0f <__x86.get_pc_thunk.di>:
f0102f0f:	8b 3c 24             	mov    (%esp),%edi
f0102f12:	c3                   	ret    

f0102f13 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f13:	55                   	push   %ebp
f0102f14:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f16:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f19:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f1e:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f1f:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f24:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f25:	0f b6 c0             	movzbl %al,%eax
}
f0102f28:	5d                   	pop    %ebp
f0102f29:	c3                   	ret    

f0102f2a <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f2a:	55                   	push   %ebp
f0102f2b:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f30:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f35:	ee                   	out    %al,(%dx)
f0102f36:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f39:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f3e:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f3f:	5d                   	pop    %ebp
f0102f40:	c3                   	ret    

f0102f41 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f41:	55                   	push   %ebp
f0102f42:	89 e5                	mov    %esp,%ebp
f0102f44:	53                   	push   %ebx
f0102f45:	83 ec 10             	sub    $0x10,%esp
f0102f48:	e8 02 d2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102f4d:	81 c3 bf 43 01 00    	add    $0x143bf,%ebx
	cputchar(ch);
f0102f53:	ff 75 08             	pushl  0x8(%ebp)
f0102f56:	e8 6b d7 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0102f5b:	83 c4 10             	add    $0x10,%esp
f0102f5e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f61:	c9                   	leave  
f0102f62:	c3                   	ret    

f0102f63 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f63:	55                   	push   %ebp
f0102f64:	89 e5                	mov    %esp,%ebp
f0102f66:	53                   	push   %ebx
f0102f67:	83 ec 14             	sub    $0x14,%esp
f0102f6a:	e8 e0 d1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102f6f:	81 c3 9d 43 01 00    	add    $0x1439d,%ebx
	int cnt = 0;
f0102f75:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f7c:	ff 75 0c             	pushl  0xc(%ebp)
f0102f7f:	ff 75 08             	pushl  0x8(%ebp)
f0102f82:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f85:	50                   	push   %eax
f0102f86:	8d 83 35 bc fe ff    	lea    -0x143cb(%ebx),%eax
f0102f8c:	50                   	push   %eax
f0102f8d:	e8 98 04 00 00       	call   f010342a <vprintfmt>
	return cnt;
}
f0102f92:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f95:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f98:	c9                   	leave  
f0102f99:	c3                   	ret    

f0102f9a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f9a:	55                   	push   %ebp
f0102f9b:	89 e5                	mov    %esp,%ebp
f0102f9d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fa0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fa3:	50                   	push   %eax
f0102fa4:	ff 75 08             	pushl  0x8(%ebp)
f0102fa7:	e8 b7 ff ff ff       	call   f0102f63 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fac:	c9                   	leave  
f0102fad:	c3                   	ret    

f0102fae <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102fae:	55                   	push   %ebp
f0102faf:	89 e5                	mov    %esp,%ebp
f0102fb1:	57                   	push   %edi
f0102fb2:	56                   	push   %esi
f0102fb3:	53                   	push   %ebx
f0102fb4:	83 ec 14             	sub    $0x14,%esp
f0102fb7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fba:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102fbd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102fc0:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102fc3:	8b 32                	mov    (%edx),%esi
f0102fc5:	8b 01                	mov    (%ecx),%eax
f0102fc7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102fca:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102fd1:	eb 2f                	jmp    f0103002 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0102fd3:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0102fd6:	39 c6                	cmp    %eax,%esi
f0102fd8:	7f 49                	jg     f0103023 <stab_binsearch+0x75>
f0102fda:	0f b6 0a             	movzbl (%edx),%ecx
f0102fdd:	83 ea 0c             	sub    $0xc,%edx
f0102fe0:	39 f9                	cmp    %edi,%ecx
f0102fe2:	75 ef                	jne    f0102fd3 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102fe4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102fe7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102fea:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102fee:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102ff1:	73 35                	jae    f0103028 <stab_binsearch+0x7a>
			*region_left = m;
f0102ff3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102ff6:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0102ff8:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0102ffb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103002:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103005:	7f 4e                	jg     f0103055 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0103007:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010300a:	01 f0                	add    %esi,%eax
f010300c:	89 c3                	mov    %eax,%ebx
f010300e:	c1 eb 1f             	shr    $0x1f,%ebx
f0103011:	01 c3                	add    %eax,%ebx
f0103013:	d1 fb                	sar    %ebx
f0103015:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103018:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010301b:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010301f:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0103021:	eb b3                	jmp    f0102fd6 <stab_binsearch+0x28>
			l = true_m + 1;
f0103023:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103026:	eb da                	jmp    f0103002 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0103028:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010302b:	76 14                	jbe    f0103041 <stab_binsearch+0x93>
			*region_right = m - 1;
f010302d:	83 e8 01             	sub    $0x1,%eax
f0103030:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103033:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103036:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0103038:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010303f:	eb c1                	jmp    f0103002 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103041:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103044:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103046:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010304a:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010304c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103053:	eb ad                	jmp    f0103002 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103055:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103059:	74 16                	je     f0103071 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010305b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010305e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103060:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103063:	8b 0e                	mov    (%esi),%ecx
f0103065:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103068:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010306b:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f010306f:	eb 12                	jmp    f0103083 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103071:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103074:	8b 00                	mov    (%eax),%eax
f0103076:	83 e8 01             	sub    $0x1,%eax
f0103079:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010307c:	89 07                	mov    %eax,(%edi)
f010307e:	eb 16                	jmp    f0103096 <stab_binsearch+0xe8>
		     l--)
f0103080:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103083:	39 c1                	cmp    %eax,%ecx
f0103085:	7d 0a                	jge    f0103091 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103087:	0f b6 1a             	movzbl (%edx),%ebx
f010308a:	83 ea 0c             	sub    $0xc,%edx
f010308d:	39 fb                	cmp    %edi,%ebx
f010308f:	75 ef                	jne    f0103080 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103091:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103094:	89 07                	mov    %eax,(%edi)
	}
}
f0103096:	83 c4 14             	add    $0x14,%esp
f0103099:	5b                   	pop    %ebx
f010309a:	5e                   	pop    %esi
f010309b:	5f                   	pop    %edi
f010309c:	5d                   	pop    %ebp
f010309d:	c3                   	ret    

f010309e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010309e:	55                   	push   %ebp
f010309f:	89 e5                	mov    %esp,%ebp
f01030a1:	57                   	push   %edi
f01030a2:	56                   	push   %esi
f01030a3:	53                   	push   %ebx
f01030a4:	83 ec 3c             	sub    $0x3c,%esp
f01030a7:	e8 a3 d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01030ac:	81 c3 60 42 01 00    	add    $0x14260,%ebx
f01030b2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01030b5:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01030b8:	8d 83 4b dc fe ff    	lea    -0x123b5(%ebx),%eax
f01030be:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f01030c0:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01030c7:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f01030ca:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01030d1:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01030d4:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01030db:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01030e1:	0f 86 37 01 00 00    	jbe    f010321e <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01030e7:	c7 c0 b1 b9 10 f0    	mov    $0xf010b9b1,%eax
f01030ed:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f01030f3:	0f 86 04 02 00 00    	jbe    f01032fd <debuginfo_eip+0x25f>
f01030f9:	c7 c0 9d d7 10 f0    	mov    $0xf010d79d,%eax
f01030ff:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103103:	0f 85 fb 01 00 00    	jne    f0103304 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103109:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103110:	c7 c0 70 51 10 f0    	mov    $0xf0105170,%eax
f0103116:	c7 c2 b0 b9 10 f0    	mov    $0xf010b9b0,%edx
f010311c:	29 c2                	sub    %eax,%edx
f010311e:	c1 fa 02             	sar    $0x2,%edx
f0103121:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103127:	83 ea 01             	sub    $0x1,%edx
f010312a:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010312d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103130:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103133:	83 ec 08             	sub    $0x8,%esp
f0103136:	57                   	push   %edi
f0103137:	6a 64                	push   $0x64
f0103139:	e8 70 fe ff ff       	call   f0102fae <stab_binsearch>
	if (lfile == 0)
f010313e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103141:	83 c4 10             	add    $0x10,%esp
f0103144:	85 c0                	test   %eax,%eax
f0103146:	0f 84 bf 01 00 00    	je     f010330b <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010314c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010314f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103152:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103155:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103158:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010315b:	83 ec 08             	sub    $0x8,%esp
f010315e:	57                   	push   %edi
f010315f:	6a 24                	push   $0x24
f0103161:	c7 c0 70 51 10 f0    	mov    $0xf0105170,%eax
f0103167:	e8 42 fe ff ff       	call   f0102fae <stab_binsearch>

	if (lfun <= rfun) {
f010316c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010316f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103172:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0103175:	83 c4 10             	add    $0x10,%esp
f0103178:	39 c8                	cmp    %ecx,%eax
f010317a:	0f 8f b6 00 00 00    	jg     f0103236 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103180:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103183:	c7 c1 70 51 10 f0    	mov    $0xf0105170,%ecx
f0103189:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f010318c:	8b 11                	mov    (%ecx),%edx
f010318e:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0103191:	c7 c2 9d d7 10 f0    	mov    $0xf010d79d,%edx
f0103197:	81 ea b1 b9 10 f0    	sub    $0xf010b9b1,%edx
f010319d:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f01031a0:	73 0c                	jae    f01031ae <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01031a2:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01031a5:	81 c2 b1 b9 10 f0    	add    $0xf010b9b1,%edx
f01031ab:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01031ae:	8b 51 08             	mov    0x8(%ecx),%edx
f01031b1:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f01031b4:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01031b6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01031b9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01031bc:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01031bf:	83 ec 08             	sub    $0x8,%esp
f01031c2:	6a 3a                	push   $0x3a
f01031c4:	ff 76 08             	pushl  0x8(%esi)
f01031c7:	e8 c3 09 00 00       	call   f0103b8f <strfind>
f01031cc:	2b 46 08             	sub    0x8(%esi),%eax
f01031cf:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01031d2:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01031d5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01031d8:	83 c4 08             	add    $0x8,%esp
f01031db:	57                   	push   %edi
f01031dc:	6a 44                	push   $0x44
f01031de:	c7 c0 70 51 10 f0    	mov    $0xf0105170,%eax
f01031e4:	e8 c5 fd ff ff       	call   f0102fae <stab_binsearch>
	if(lline<=rline){
f01031e9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01031ec:	83 c4 10             	add    $0x10,%esp
f01031ef:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01031f2:	0f 8f 1a 01 00 00    	jg     f0103312 <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f01031f8:	89 d0                	mov    %edx,%eax
f01031fa:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01031fd:	c1 e2 02             	shl    $0x2,%edx
f0103200:	c7 c1 70 51 10 f0    	mov    $0xf0105170,%ecx
f0103206:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f010320b:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010320e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103211:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0103215:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103219:	89 75 0c             	mov    %esi,0xc(%ebp)
f010321c:	eb 36                	jmp    f0103254 <debuginfo_eip+0x1b6>
  	        panic("User address");
f010321e:	83 ec 04             	sub    $0x4,%esp
f0103221:	8d 83 55 dc fe ff    	lea    -0x123ab(%ebx),%eax
f0103227:	50                   	push   %eax
f0103228:	6a 7f                	push   $0x7f
f010322a:	8d 83 62 dc fe ff    	lea    -0x1239e(%ebx),%eax
f0103230:	50                   	push   %eax
f0103231:	e8 63 ce ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0103236:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103239:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010323c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010323f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103242:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103245:	e9 75 ff ff ff       	jmp    f01031bf <debuginfo_eip+0x121>
f010324a:	83 e8 01             	sub    $0x1,%eax
f010324d:	83 ea 0c             	sub    $0xc,%edx
f0103250:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103254:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0103257:	39 c7                	cmp    %eax,%edi
f0103259:	7f 24                	jg     f010327f <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f010325b:	0f b6 0a             	movzbl (%edx),%ecx
f010325e:	80 f9 84             	cmp    $0x84,%cl
f0103261:	74 46                	je     f01032a9 <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103263:	80 f9 64             	cmp    $0x64,%cl
f0103266:	75 e2                	jne    f010324a <debuginfo_eip+0x1ac>
f0103268:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f010326c:	74 dc                	je     f010324a <debuginfo_eip+0x1ac>
f010326e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103271:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103275:	74 3b                	je     f01032b2 <debuginfo_eip+0x214>
f0103277:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010327a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010327d:	eb 33                	jmp    f01032b2 <debuginfo_eip+0x214>
f010327f:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103282:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103285:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103288:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f010328d:	39 fa                	cmp    %edi,%edx
f010328f:	0f 8d 89 00 00 00    	jge    f010331e <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0103295:	83 c2 01             	add    $0x1,%edx
f0103298:	89 d0                	mov    %edx,%eax
f010329a:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f010329d:	c7 c2 70 51 10 f0    	mov    $0xf0105170,%edx
f01032a3:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f01032a7:	eb 3b                	jmp    f01032e4 <debuginfo_eip+0x246>
f01032a9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032ac:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01032b0:	75 26                	jne    f01032d8 <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01032b2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01032b5:	c7 c0 70 51 10 f0    	mov    $0xf0105170,%eax
f01032bb:	8b 14 90             	mov    (%eax,%edx,4),%edx
f01032be:	c7 c0 9d d7 10 f0    	mov    $0xf010d79d,%eax
f01032c4:	81 e8 b1 b9 10 f0    	sub    $0xf010b9b1,%eax
f01032ca:	39 c2                	cmp    %eax,%edx
f01032cc:	73 b4                	jae    f0103282 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01032ce:	81 c2 b1 b9 10 f0    	add    $0xf010b9b1,%edx
f01032d4:	89 16                	mov    %edx,(%esi)
f01032d6:	eb aa                	jmp    f0103282 <debuginfo_eip+0x1e4>
f01032d8:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01032db:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01032de:	eb d2                	jmp    f01032b2 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f01032e0:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f01032e4:	39 c7                	cmp    %eax,%edi
f01032e6:	7e 31                	jle    f0103319 <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01032e8:	0f b6 0a             	movzbl (%edx),%ecx
f01032eb:	83 c0 01             	add    $0x1,%eax
f01032ee:	83 c2 0c             	add    $0xc,%edx
f01032f1:	80 f9 a0             	cmp    $0xa0,%cl
f01032f4:	74 ea                	je     f01032e0 <debuginfo_eip+0x242>
	return 0;
f01032f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01032fb:	eb 21                	jmp    f010331e <debuginfo_eip+0x280>
		return -1;
f01032fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103302:	eb 1a                	jmp    f010331e <debuginfo_eip+0x280>
f0103304:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103309:	eb 13                	jmp    f010331e <debuginfo_eip+0x280>
		return -1;
f010330b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103310:	eb 0c                	jmp    f010331e <debuginfo_eip+0x280>
		return -1;
f0103312:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103317:	eb 05                	jmp    f010331e <debuginfo_eip+0x280>
	return 0;
f0103319:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010331e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103321:	5b                   	pop    %ebx
f0103322:	5e                   	pop    %esi
f0103323:	5f                   	pop    %edi
f0103324:	5d                   	pop    %ebp
f0103325:	c3                   	ret    

f0103326 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103326:	55                   	push   %ebp
f0103327:	89 e5                	mov    %esp,%ebp
f0103329:	57                   	push   %edi
f010332a:	56                   	push   %esi
f010332b:	53                   	push   %ebx
f010332c:	83 ec 2c             	sub    $0x2c,%esp
f010332f:	e8 d3 fb ff ff       	call   f0102f07 <__x86.get_pc_thunk.cx>
f0103334:	81 c1 d8 3f 01 00    	add    $0x13fd8,%ecx
f010333a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010333d:	89 c7                	mov    %eax,%edi
f010333f:	89 d6                	mov    %edx,%esi
f0103341:	8b 45 08             	mov    0x8(%ebp),%eax
f0103344:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103347:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010334a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010334d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103350:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103355:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0103358:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010335b:	39 d3                	cmp    %edx,%ebx
f010335d:	72 09                	jb     f0103368 <printnum+0x42>
f010335f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103362:	0f 87 83 00 00 00    	ja     f01033eb <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103368:	83 ec 0c             	sub    $0xc,%esp
f010336b:	ff 75 18             	pushl  0x18(%ebp)
f010336e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103371:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103374:	53                   	push   %ebx
f0103375:	ff 75 10             	pushl  0x10(%ebp)
f0103378:	83 ec 08             	sub    $0x8,%esp
f010337b:	ff 75 dc             	pushl  -0x24(%ebp)
f010337e:	ff 75 d8             	pushl  -0x28(%ebp)
f0103381:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103384:	ff 75 d0             	pushl  -0x30(%ebp)
f0103387:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010338a:	e8 21 0a 00 00       	call   f0103db0 <__udivdi3>
f010338f:	83 c4 18             	add    $0x18,%esp
f0103392:	52                   	push   %edx
f0103393:	50                   	push   %eax
f0103394:	89 f2                	mov    %esi,%edx
f0103396:	89 f8                	mov    %edi,%eax
f0103398:	e8 89 ff ff ff       	call   f0103326 <printnum>
f010339d:	83 c4 20             	add    $0x20,%esp
f01033a0:	eb 13                	jmp    f01033b5 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01033a2:	83 ec 08             	sub    $0x8,%esp
f01033a5:	56                   	push   %esi
f01033a6:	ff 75 18             	pushl  0x18(%ebp)
f01033a9:	ff d7                	call   *%edi
f01033ab:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01033ae:	83 eb 01             	sub    $0x1,%ebx
f01033b1:	85 db                	test   %ebx,%ebx
f01033b3:	7f ed                	jg     f01033a2 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01033b5:	83 ec 08             	sub    $0x8,%esp
f01033b8:	56                   	push   %esi
f01033b9:	83 ec 04             	sub    $0x4,%esp
f01033bc:	ff 75 dc             	pushl  -0x24(%ebp)
f01033bf:	ff 75 d8             	pushl  -0x28(%ebp)
f01033c2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01033c5:	ff 75 d0             	pushl  -0x30(%ebp)
f01033c8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01033cb:	89 f3                	mov    %esi,%ebx
f01033cd:	e8 fe 0a 00 00       	call   f0103ed0 <__umoddi3>
f01033d2:	83 c4 14             	add    $0x14,%esp
f01033d5:	0f be 84 06 70 dc fe 	movsbl -0x12390(%esi,%eax,1),%eax
f01033dc:	ff 
f01033dd:	50                   	push   %eax
f01033de:	ff d7                	call   *%edi
}
f01033e0:	83 c4 10             	add    $0x10,%esp
f01033e3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033e6:	5b                   	pop    %ebx
f01033e7:	5e                   	pop    %esi
f01033e8:	5f                   	pop    %edi
f01033e9:	5d                   	pop    %ebp
f01033ea:	c3                   	ret    
f01033eb:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01033ee:	eb be                	jmp    f01033ae <printnum+0x88>

f01033f0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01033f0:	55                   	push   %ebp
f01033f1:	89 e5                	mov    %esp,%ebp
f01033f3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01033f6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01033fa:	8b 10                	mov    (%eax),%edx
f01033fc:	3b 50 04             	cmp    0x4(%eax),%edx
f01033ff:	73 0a                	jae    f010340b <sprintputch+0x1b>
		*b->buf++ = ch;
f0103401:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103404:	89 08                	mov    %ecx,(%eax)
f0103406:	8b 45 08             	mov    0x8(%ebp),%eax
f0103409:	88 02                	mov    %al,(%edx)
}
f010340b:	5d                   	pop    %ebp
f010340c:	c3                   	ret    

f010340d <printfmt>:
{
f010340d:	55                   	push   %ebp
f010340e:	89 e5                	mov    %esp,%ebp
f0103410:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103413:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103416:	50                   	push   %eax
f0103417:	ff 75 10             	pushl  0x10(%ebp)
f010341a:	ff 75 0c             	pushl  0xc(%ebp)
f010341d:	ff 75 08             	pushl  0x8(%ebp)
f0103420:	e8 05 00 00 00       	call   f010342a <vprintfmt>
}
f0103425:	83 c4 10             	add    $0x10,%esp
f0103428:	c9                   	leave  
f0103429:	c3                   	ret    

f010342a <vprintfmt>:
{
f010342a:	55                   	push   %ebp
f010342b:	89 e5                	mov    %esp,%ebp
f010342d:	57                   	push   %edi
f010342e:	56                   	push   %esi
f010342f:	53                   	push   %ebx
f0103430:	83 ec 2c             	sub    $0x2c,%esp
f0103433:	e8 17 cd ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103438:	81 c3 d4 3e 01 00    	add    $0x13ed4,%ebx
f010343e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103441:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103444:	e9 c3 03 00 00       	jmp    f010380c <.L35+0x48>
		padc = ' ';
f0103449:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010344d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103454:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010345b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103462:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103467:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010346a:	8d 47 01             	lea    0x1(%edi),%eax
f010346d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103470:	0f b6 17             	movzbl (%edi),%edx
f0103473:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103476:	3c 55                	cmp    $0x55,%al
f0103478:	0f 87 16 04 00 00    	ja     f0103894 <.L22>
f010347e:	0f b6 c0             	movzbl %al,%eax
f0103481:	89 d9                	mov    %ebx,%ecx
f0103483:	03 8c 83 fc dc fe ff 	add    -0x12304(%ebx,%eax,4),%ecx
f010348a:	ff e1                	jmp    *%ecx

f010348c <.L69>:
f010348c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f010348f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0103493:	eb d5                	jmp    f010346a <vprintfmt+0x40>

f0103495 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0103495:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0103498:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010349c:	eb cc                	jmp    f010346a <vprintfmt+0x40>

f010349e <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f010349e:	0f b6 d2             	movzbl %dl,%edx
f01034a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01034a4:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f01034a9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01034ac:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01034b0:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01034b3:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01034b6:	83 f9 09             	cmp    $0x9,%ecx
f01034b9:	77 55                	ja     f0103510 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f01034bb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01034be:	eb e9                	jmp    f01034a9 <.L29+0xb>

f01034c0 <.L26>:
			precision = va_arg(ap, int);
f01034c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01034c3:	8b 00                	mov    (%eax),%eax
f01034c5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01034c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01034cb:	8d 40 04             	lea    0x4(%eax),%eax
f01034ce:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01034d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01034d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01034d8:	79 90                	jns    f010346a <vprintfmt+0x40>
				width = precision, precision = -1;
f01034da:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01034dd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034e0:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f01034e7:	eb 81                	jmp    f010346a <vprintfmt+0x40>

f01034e9 <.L27>:
f01034e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034ec:	85 c0                	test   %eax,%eax
f01034ee:	ba 00 00 00 00       	mov    $0x0,%edx
f01034f3:	0f 49 d0             	cmovns %eax,%edx
f01034f6:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01034f9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034fc:	e9 69 ff ff ff       	jmp    f010346a <vprintfmt+0x40>

f0103501 <.L23>:
f0103501:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103504:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010350b:	e9 5a ff ff ff       	jmp    f010346a <vprintfmt+0x40>
f0103510:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103513:	eb bf                	jmp    f01034d4 <.L26+0x14>

f0103515 <.L33>:
			lflag++;
f0103515:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103519:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010351c:	e9 49 ff ff ff       	jmp    f010346a <vprintfmt+0x40>

f0103521 <.L30>:
			putch(va_arg(ap, int), putdat);
f0103521:	8b 45 14             	mov    0x14(%ebp),%eax
f0103524:	8d 78 04             	lea    0x4(%eax),%edi
f0103527:	83 ec 08             	sub    $0x8,%esp
f010352a:	56                   	push   %esi
f010352b:	ff 30                	pushl  (%eax)
f010352d:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103530:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103533:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103536:	e9 ce 02 00 00       	jmp    f0103809 <.L35+0x45>

f010353b <.L32>:
			err = va_arg(ap, int);
f010353b:	8b 45 14             	mov    0x14(%ebp),%eax
f010353e:	8d 78 04             	lea    0x4(%eax),%edi
f0103541:	8b 00                	mov    (%eax),%eax
f0103543:	99                   	cltd   
f0103544:	31 d0                	xor    %edx,%eax
f0103546:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103548:	83 f8 06             	cmp    $0x6,%eax
f010354b:	7f 27                	jg     f0103574 <.L32+0x39>
f010354d:	8b 94 83 38 1d 00 00 	mov    0x1d38(%ebx,%eax,4),%edx
f0103554:	85 d2                	test   %edx,%edx
f0103556:	74 1c                	je     f0103574 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0103558:	52                   	push   %edx
f0103559:	8d 83 a0 d9 fe ff    	lea    -0x12660(%ebx),%eax
f010355f:	50                   	push   %eax
f0103560:	56                   	push   %esi
f0103561:	ff 75 08             	pushl  0x8(%ebp)
f0103564:	e8 a4 fe ff ff       	call   f010340d <printfmt>
f0103569:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010356c:	89 7d 14             	mov    %edi,0x14(%ebp)
f010356f:	e9 95 02 00 00       	jmp    f0103809 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103574:	50                   	push   %eax
f0103575:	8d 83 88 dc fe ff    	lea    -0x12378(%ebx),%eax
f010357b:	50                   	push   %eax
f010357c:	56                   	push   %esi
f010357d:	ff 75 08             	pushl  0x8(%ebp)
f0103580:	e8 88 fe ff ff       	call   f010340d <printfmt>
f0103585:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103588:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010358b:	e9 79 02 00 00       	jmp    f0103809 <.L35+0x45>

f0103590 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0103590:	8b 45 14             	mov    0x14(%ebp),%eax
f0103593:	83 c0 04             	add    $0x4,%eax
f0103596:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103599:	8b 45 14             	mov    0x14(%ebp),%eax
f010359c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010359e:	85 ff                	test   %edi,%edi
f01035a0:	8d 83 81 dc fe ff    	lea    -0x1237f(%ebx),%eax
f01035a6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01035a9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035ad:	0f 8e b5 00 00 00    	jle    f0103668 <.L36+0xd8>
f01035b3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01035b7:	75 08                	jne    f01035c1 <.L36+0x31>
f01035b9:	89 75 0c             	mov    %esi,0xc(%ebp)
f01035bc:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01035bf:	eb 6d                	jmp    f010362e <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f01035c1:	83 ec 08             	sub    $0x8,%esp
f01035c4:	ff 75 cc             	pushl  -0x34(%ebp)
f01035c7:	57                   	push   %edi
f01035c8:	e8 7e 04 00 00       	call   f0103a4b <strnlen>
f01035cd:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035d0:	29 c2                	sub    %eax,%edx
f01035d2:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01035d5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01035d8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01035dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01035df:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01035e2:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01035e4:	eb 10                	jmp    f01035f6 <.L36+0x66>
					putch(padc, putdat);
f01035e6:	83 ec 08             	sub    $0x8,%esp
f01035e9:	56                   	push   %esi
f01035ea:	ff 75 e0             	pushl  -0x20(%ebp)
f01035ed:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01035f0:	83 ef 01             	sub    $0x1,%edi
f01035f3:	83 c4 10             	add    $0x10,%esp
f01035f6:	85 ff                	test   %edi,%edi
f01035f8:	7f ec                	jg     f01035e6 <.L36+0x56>
f01035fa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01035fd:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103600:	85 d2                	test   %edx,%edx
f0103602:	b8 00 00 00 00       	mov    $0x0,%eax
f0103607:	0f 49 c2             	cmovns %edx,%eax
f010360a:	29 c2                	sub    %eax,%edx
f010360c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010360f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103612:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103615:	eb 17                	jmp    f010362e <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103617:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010361b:	75 30                	jne    f010364d <.L36+0xbd>
					putch(ch, putdat);
f010361d:	83 ec 08             	sub    $0x8,%esp
f0103620:	ff 75 0c             	pushl  0xc(%ebp)
f0103623:	50                   	push   %eax
f0103624:	ff 55 08             	call   *0x8(%ebp)
f0103627:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010362a:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010362e:	83 c7 01             	add    $0x1,%edi
f0103631:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103635:	0f be c2             	movsbl %dl,%eax
f0103638:	85 c0                	test   %eax,%eax
f010363a:	74 52                	je     f010368e <.L36+0xfe>
f010363c:	85 f6                	test   %esi,%esi
f010363e:	78 d7                	js     f0103617 <.L36+0x87>
f0103640:	83 ee 01             	sub    $0x1,%esi
f0103643:	79 d2                	jns    f0103617 <.L36+0x87>
f0103645:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103648:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010364b:	eb 32                	jmp    f010367f <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010364d:	0f be d2             	movsbl %dl,%edx
f0103650:	83 ea 20             	sub    $0x20,%edx
f0103653:	83 fa 5e             	cmp    $0x5e,%edx
f0103656:	76 c5                	jbe    f010361d <.L36+0x8d>
					putch('?', putdat);
f0103658:	83 ec 08             	sub    $0x8,%esp
f010365b:	ff 75 0c             	pushl  0xc(%ebp)
f010365e:	6a 3f                	push   $0x3f
f0103660:	ff 55 08             	call   *0x8(%ebp)
f0103663:	83 c4 10             	add    $0x10,%esp
f0103666:	eb c2                	jmp    f010362a <.L36+0x9a>
f0103668:	89 75 0c             	mov    %esi,0xc(%ebp)
f010366b:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010366e:	eb be                	jmp    f010362e <.L36+0x9e>
				putch(' ', putdat);
f0103670:	83 ec 08             	sub    $0x8,%esp
f0103673:	56                   	push   %esi
f0103674:	6a 20                	push   $0x20
f0103676:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0103679:	83 ef 01             	sub    $0x1,%edi
f010367c:	83 c4 10             	add    $0x10,%esp
f010367f:	85 ff                	test   %edi,%edi
f0103681:	7f ed                	jg     f0103670 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0103683:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103686:	89 45 14             	mov    %eax,0x14(%ebp)
f0103689:	e9 7b 01 00 00       	jmp    f0103809 <.L35+0x45>
f010368e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103691:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103694:	eb e9                	jmp    f010367f <.L36+0xef>

f0103696 <.L31>:
f0103696:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103699:	83 f9 01             	cmp    $0x1,%ecx
f010369c:	7e 40                	jle    f01036de <.L31+0x48>
		return va_arg(*ap, long long);
f010369e:	8b 45 14             	mov    0x14(%ebp),%eax
f01036a1:	8b 50 04             	mov    0x4(%eax),%edx
f01036a4:	8b 00                	mov    (%eax),%eax
f01036a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01036a9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01036ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01036af:	8d 40 08             	lea    0x8(%eax),%eax
f01036b2:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01036b5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01036b9:	79 55                	jns    f0103710 <.L31+0x7a>
				putch('-', putdat);
f01036bb:	83 ec 08             	sub    $0x8,%esp
f01036be:	56                   	push   %esi
f01036bf:	6a 2d                	push   $0x2d
f01036c1:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01036c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01036c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01036ca:	f7 da                	neg    %edx
f01036cc:	83 d1 00             	adc    $0x0,%ecx
f01036cf:	f7 d9                	neg    %ecx
f01036d1:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01036d4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036d9:	e9 10 01 00 00       	jmp    f01037ee <.L35+0x2a>
	else if (lflag)
f01036de:	85 c9                	test   %ecx,%ecx
f01036e0:	75 17                	jne    f01036f9 <.L31+0x63>
		return va_arg(*ap, int);
f01036e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01036e5:	8b 00                	mov    (%eax),%eax
f01036e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01036ea:	99                   	cltd   
f01036eb:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01036ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01036f1:	8d 40 04             	lea    0x4(%eax),%eax
f01036f4:	89 45 14             	mov    %eax,0x14(%ebp)
f01036f7:	eb bc                	jmp    f01036b5 <.L31+0x1f>
		return va_arg(*ap, long);
f01036f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01036fc:	8b 00                	mov    (%eax),%eax
f01036fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103701:	99                   	cltd   
f0103702:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103705:	8b 45 14             	mov    0x14(%ebp),%eax
f0103708:	8d 40 04             	lea    0x4(%eax),%eax
f010370b:	89 45 14             	mov    %eax,0x14(%ebp)
f010370e:	eb a5                	jmp    f01036b5 <.L31+0x1f>
			num = getint(&ap, lflag);
f0103710:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103713:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103716:	b8 0a 00 00 00       	mov    $0xa,%eax
f010371b:	e9 ce 00 00 00       	jmp    f01037ee <.L35+0x2a>

f0103720 <.L37>:
f0103720:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103723:	83 f9 01             	cmp    $0x1,%ecx
f0103726:	7e 18                	jle    f0103740 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0103728:	8b 45 14             	mov    0x14(%ebp),%eax
f010372b:	8b 10                	mov    (%eax),%edx
f010372d:	8b 48 04             	mov    0x4(%eax),%ecx
f0103730:	8d 40 08             	lea    0x8(%eax),%eax
f0103733:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103736:	b8 0a 00 00 00       	mov    $0xa,%eax
f010373b:	e9 ae 00 00 00       	jmp    f01037ee <.L35+0x2a>
	else if (lflag)
f0103740:	85 c9                	test   %ecx,%ecx
f0103742:	75 1a                	jne    f010375e <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0103744:	8b 45 14             	mov    0x14(%ebp),%eax
f0103747:	8b 10                	mov    (%eax),%edx
f0103749:	b9 00 00 00 00       	mov    $0x0,%ecx
f010374e:	8d 40 04             	lea    0x4(%eax),%eax
f0103751:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103754:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103759:	e9 90 00 00 00       	jmp    f01037ee <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010375e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103761:	8b 10                	mov    (%eax),%edx
f0103763:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103768:	8d 40 04             	lea    0x4(%eax),%eax
f010376b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010376e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103773:	eb 79                	jmp    f01037ee <.L35+0x2a>

f0103775 <.L34>:
f0103775:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103778:	83 f9 01             	cmp    $0x1,%ecx
f010377b:	7e 15                	jle    f0103792 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f010377d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103780:	8b 10                	mov    (%eax),%edx
f0103782:	8b 48 04             	mov    0x4(%eax),%ecx
f0103785:	8d 40 08             	lea    0x8(%eax),%eax
f0103788:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010378b:	b8 08 00 00 00       	mov    $0x8,%eax
f0103790:	eb 5c                	jmp    f01037ee <.L35+0x2a>
	else if (lflag)
f0103792:	85 c9                	test   %ecx,%ecx
f0103794:	75 17                	jne    f01037ad <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0103796:	8b 45 14             	mov    0x14(%ebp),%eax
f0103799:	8b 10                	mov    (%eax),%edx
f010379b:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037a0:	8d 40 04             	lea    0x4(%eax),%eax
f01037a3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01037a6:	b8 08 00 00 00       	mov    $0x8,%eax
f01037ab:	eb 41                	jmp    f01037ee <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01037ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01037b0:	8b 10                	mov    (%eax),%edx
f01037b2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037b7:	8d 40 04             	lea    0x4(%eax),%eax
f01037ba:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01037bd:	b8 08 00 00 00       	mov    $0x8,%eax
f01037c2:	eb 2a                	jmp    f01037ee <.L35+0x2a>

f01037c4 <.L35>:
			putch('0', putdat);
f01037c4:	83 ec 08             	sub    $0x8,%esp
f01037c7:	56                   	push   %esi
f01037c8:	6a 30                	push   $0x30
f01037ca:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01037cd:	83 c4 08             	add    $0x8,%esp
f01037d0:	56                   	push   %esi
f01037d1:	6a 78                	push   $0x78
f01037d3:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01037d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01037d9:	8b 10                	mov    (%eax),%edx
f01037db:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f01037e0:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01037e3:	8d 40 04             	lea    0x4(%eax),%eax
f01037e6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01037e9:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01037ee:	83 ec 0c             	sub    $0xc,%esp
f01037f1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01037f5:	57                   	push   %edi
f01037f6:	ff 75 e0             	pushl  -0x20(%ebp)
f01037f9:	50                   	push   %eax
f01037fa:	51                   	push   %ecx
f01037fb:	52                   	push   %edx
f01037fc:	89 f2                	mov    %esi,%edx
f01037fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103801:	e8 20 fb ff ff       	call   f0103326 <printnum>
			break;
f0103806:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103809:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010380c:	83 c7 01             	add    $0x1,%edi
f010380f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103813:	83 f8 25             	cmp    $0x25,%eax
f0103816:	0f 84 2d fc ff ff    	je     f0103449 <vprintfmt+0x1f>
			if (ch == '\0')
f010381c:	85 c0                	test   %eax,%eax
f010381e:	0f 84 91 00 00 00    	je     f01038b5 <.L22+0x21>
			putch(ch, putdat);
f0103824:	83 ec 08             	sub    $0x8,%esp
f0103827:	56                   	push   %esi
f0103828:	50                   	push   %eax
f0103829:	ff 55 08             	call   *0x8(%ebp)
f010382c:	83 c4 10             	add    $0x10,%esp
f010382f:	eb db                	jmp    f010380c <.L35+0x48>

f0103831 <.L38>:
f0103831:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103834:	83 f9 01             	cmp    $0x1,%ecx
f0103837:	7e 15                	jle    f010384e <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0103839:	8b 45 14             	mov    0x14(%ebp),%eax
f010383c:	8b 10                	mov    (%eax),%edx
f010383e:	8b 48 04             	mov    0x4(%eax),%ecx
f0103841:	8d 40 08             	lea    0x8(%eax),%eax
f0103844:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103847:	b8 10 00 00 00       	mov    $0x10,%eax
f010384c:	eb a0                	jmp    f01037ee <.L35+0x2a>
	else if (lflag)
f010384e:	85 c9                	test   %ecx,%ecx
f0103850:	75 17                	jne    f0103869 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0103852:	8b 45 14             	mov    0x14(%ebp),%eax
f0103855:	8b 10                	mov    (%eax),%edx
f0103857:	b9 00 00 00 00       	mov    $0x0,%ecx
f010385c:	8d 40 04             	lea    0x4(%eax),%eax
f010385f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103862:	b8 10 00 00 00       	mov    $0x10,%eax
f0103867:	eb 85                	jmp    f01037ee <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103869:	8b 45 14             	mov    0x14(%ebp),%eax
f010386c:	8b 10                	mov    (%eax),%edx
f010386e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103873:	8d 40 04             	lea    0x4(%eax),%eax
f0103876:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103879:	b8 10 00 00 00       	mov    $0x10,%eax
f010387e:	e9 6b ff ff ff       	jmp    f01037ee <.L35+0x2a>

f0103883 <.L25>:
			putch(ch, putdat);
f0103883:	83 ec 08             	sub    $0x8,%esp
f0103886:	56                   	push   %esi
f0103887:	6a 25                	push   $0x25
f0103889:	ff 55 08             	call   *0x8(%ebp)
			break;
f010388c:	83 c4 10             	add    $0x10,%esp
f010388f:	e9 75 ff ff ff       	jmp    f0103809 <.L35+0x45>

f0103894 <.L22>:
			putch('%', putdat);
f0103894:	83 ec 08             	sub    $0x8,%esp
f0103897:	56                   	push   %esi
f0103898:	6a 25                	push   $0x25
f010389a:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010389d:	83 c4 10             	add    $0x10,%esp
f01038a0:	89 f8                	mov    %edi,%eax
f01038a2:	eb 03                	jmp    f01038a7 <.L22+0x13>
f01038a4:	83 e8 01             	sub    $0x1,%eax
f01038a7:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01038ab:	75 f7                	jne    f01038a4 <.L22+0x10>
f01038ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01038b0:	e9 54 ff ff ff       	jmp    f0103809 <.L35+0x45>
}
f01038b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01038b8:	5b                   	pop    %ebx
f01038b9:	5e                   	pop    %esi
f01038ba:	5f                   	pop    %edi
f01038bb:	5d                   	pop    %ebp
f01038bc:	c3                   	ret    

f01038bd <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01038bd:	55                   	push   %ebp
f01038be:	89 e5                	mov    %esp,%ebp
f01038c0:	53                   	push   %ebx
f01038c1:	83 ec 14             	sub    $0x14,%esp
f01038c4:	e8 86 c8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01038c9:	81 c3 43 3a 01 00    	add    $0x13a43,%ebx
f01038cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01038d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01038d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038d8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01038dc:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01038df:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01038e6:	85 c0                	test   %eax,%eax
f01038e8:	74 2b                	je     f0103915 <vsnprintf+0x58>
f01038ea:	85 d2                	test   %edx,%edx
f01038ec:	7e 27                	jle    f0103915 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01038ee:	ff 75 14             	pushl  0x14(%ebp)
f01038f1:	ff 75 10             	pushl  0x10(%ebp)
f01038f4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01038f7:	50                   	push   %eax
f01038f8:	8d 83 e4 c0 fe ff    	lea    -0x13f1c(%ebx),%eax
f01038fe:	50                   	push   %eax
f01038ff:	e8 26 fb ff ff       	call   f010342a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103904:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103907:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010390a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010390d:	83 c4 10             	add    $0x10,%esp
}
f0103910:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103913:	c9                   	leave  
f0103914:	c3                   	ret    
		return -E_INVAL;
f0103915:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010391a:	eb f4                	jmp    f0103910 <vsnprintf+0x53>

f010391c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010391c:	55                   	push   %ebp
f010391d:	89 e5                	mov    %esp,%ebp
f010391f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103922:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103925:	50                   	push   %eax
f0103926:	ff 75 10             	pushl  0x10(%ebp)
f0103929:	ff 75 0c             	pushl  0xc(%ebp)
f010392c:	ff 75 08             	pushl  0x8(%ebp)
f010392f:	e8 89 ff ff ff       	call   f01038bd <vsnprintf>
	va_end(ap);

	return rc;
}
f0103934:	c9                   	leave  
f0103935:	c3                   	ret    

f0103936 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103936:	55                   	push   %ebp
f0103937:	89 e5                	mov    %esp,%ebp
f0103939:	57                   	push   %edi
f010393a:	56                   	push   %esi
f010393b:	53                   	push   %ebx
f010393c:	83 ec 1c             	sub    $0x1c,%esp
f010393f:	e8 0b c8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103944:	81 c3 c8 39 01 00    	add    $0x139c8,%ebx
f010394a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010394d:	85 c0                	test   %eax,%eax
f010394f:	74 13                	je     f0103964 <readline+0x2e>
		cprintf("%s", prompt);
f0103951:	83 ec 08             	sub    $0x8,%esp
f0103954:	50                   	push   %eax
f0103955:	8d 83 a0 d9 fe ff    	lea    -0x12660(%ebx),%eax
f010395b:	50                   	push   %eax
f010395c:	e8 39 f6 ff ff       	call   f0102f9a <cprintf>
f0103961:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103964:	83 ec 0c             	sub    $0xc,%esp
f0103967:	6a 00                	push   $0x0
f0103969:	e8 79 cd ff ff       	call   f01006e7 <iscons>
f010396e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103971:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103974:	bf 00 00 00 00       	mov    $0x0,%edi
f0103979:	eb 46                	jmp    f01039c1 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010397b:	83 ec 08             	sub    $0x8,%esp
f010397e:	50                   	push   %eax
f010397f:	8d 83 54 de fe ff    	lea    -0x121ac(%ebx),%eax
f0103985:	50                   	push   %eax
f0103986:	e8 0f f6 ff ff       	call   f0102f9a <cprintf>
			return NULL;
f010398b:	83 c4 10             	add    $0x10,%esp
f010398e:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103993:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103996:	5b                   	pop    %ebx
f0103997:	5e                   	pop    %esi
f0103998:	5f                   	pop    %edi
f0103999:	5d                   	pop    %ebp
f010399a:	c3                   	ret    
			if (echoing)
f010399b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010399f:	75 05                	jne    f01039a6 <readline+0x70>
			i--;
f01039a1:	83 ef 01             	sub    $0x1,%edi
f01039a4:	eb 1b                	jmp    f01039c1 <readline+0x8b>
				cputchar('\b');
f01039a6:	83 ec 0c             	sub    $0xc,%esp
f01039a9:	6a 08                	push   $0x8
f01039ab:	e8 16 cd ff ff       	call   f01006c6 <cputchar>
f01039b0:	83 c4 10             	add    $0x10,%esp
f01039b3:	eb ec                	jmp    f01039a1 <readline+0x6b>
			buf[i++] = c;
f01039b5:	89 f0                	mov    %esi,%eax
f01039b7:	88 84 3b 94 1f 00 00 	mov    %al,0x1f94(%ebx,%edi,1)
f01039be:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01039c1:	e8 10 cd ff ff       	call   f01006d6 <getchar>
f01039c6:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01039c8:	85 c0                	test   %eax,%eax
f01039ca:	78 af                	js     f010397b <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01039cc:	83 f8 08             	cmp    $0x8,%eax
f01039cf:	0f 94 c2             	sete   %dl
f01039d2:	83 f8 7f             	cmp    $0x7f,%eax
f01039d5:	0f 94 c0             	sete   %al
f01039d8:	08 c2                	or     %al,%dl
f01039da:	74 04                	je     f01039e0 <readline+0xaa>
f01039dc:	85 ff                	test   %edi,%edi
f01039de:	7f bb                	jg     f010399b <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01039e0:	83 fe 1f             	cmp    $0x1f,%esi
f01039e3:	7e 1c                	jle    f0103a01 <readline+0xcb>
f01039e5:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01039eb:	7f 14                	jg     f0103a01 <readline+0xcb>
			if (echoing)
f01039ed:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039f1:	74 c2                	je     f01039b5 <readline+0x7f>
				cputchar(c);
f01039f3:	83 ec 0c             	sub    $0xc,%esp
f01039f6:	56                   	push   %esi
f01039f7:	e8 ca cc ff ff       	call   f01006c6 <cputchar>
f01039fc:	83 c4 10             	add    $0x10,%esp
f01039ff:	eb b4                	jmp    f01039b5 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103a01:	83 fe 0a             	cmp    $0xa,%esi
f0103a04:	74 05                	je     f0103a0b <readline+0xd5>
f0103a06:	83 fe 0d             	cmp    $0xd,%esi
f0103a09:	75 b6                	jne    f01039c1 <readline+0x8b>
			if (echoing)
f0103a0b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103a0f:	75 13                	jne    f0103a24 <readline+0xee>
			buf[i] = 0;
f0103a11:	c6 84 3b 94 1f 00 00 	movb   $0x0,0x1f94(%ebx,%edi,1)
f0103a18:	00 
			return buf;
f0103a19:	8d 83 94 1f 00 00    	lea    0x1f94(%ebx),%eax
f0103a1f:	e9 6f ff ff ff       	jmp    f0103993 <readline+0x5d>
				cputchar('\n');
f0103a24:	83 ec 0c             	sub    $0xc,%esp
f0103a27:	6a 0a                	push   $0xa
f0103a29:	e8 98 cc ff ff       	call   f01006c6 <cputchar>
f0103a2e:	83 c4 10             	add    $0x10,%esp
f0103a31:	eb de                	jmp    f0103a11 <readline+0xdb>

f0103a33 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a33:	55                   	push   %ebp
f0103a34:	89 e5                	mov    %esp,%ebp
f0103a36:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a39:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a3e:	eb 03                	jmp    f0103a43 <strlen+0x10>
		n++;
f0103a40:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103a43:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103a47:	75 f7                	jne    f0103a40 <strlen+0xd>
	return n;
}
f0103a49:	5d                   	pop    %ebp
f0103a4a:	c3                   	ret    

f0103a4b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103a4b:	55                   	push   %ebp
f0103a4c:	89 e5                	mov    %esp,%ebp
f0103a4e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a51:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a54:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a59:	eb 03                	jmp    f0103a5e <strnlen+0x13>
		n++;
f0103a5b:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a5e:	39 d0                	cmp    %edx,%eax
f0103a60:	74 06                	je     f0103a68 <strnlen+0x1d>
f0103a62:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103a66:	75 f3                	jne    f0103a5b <strnlen+0x10>
	return n;
}
f0103a68:	5d                   	pop    %ebp
f0103a69:	c3                   	ret    

f0103a6a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103a6a:	55                   	push   %ebp
f0103a6b:	89 e5                	mov    %esp,%ebp
f0103a6d:	53                   	push   %ebx
f0103a6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a71:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a74:	89 c2                	mov    %eax,%edx
f0103a76:	83 c1 01             	add    $0x1,%ecx
f0103a79:	83 c2 01             	add    $0x1,%edx
f0103a7c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103a80:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103a83:	84 db                	test   %bl,%bl
f0103a85:	75 ef                	jne    f0103a76 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103a87:	5b                   	pop    %ebx
f0103a88:	5d                   	pop    %ebp
f0103a89:	c3                   	ret    

f0103a8a <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103a8a:	55                   	push   %ebp
f0103a8b:	89 e5                	mov    %esp,%ebp
f0103a8d:	53                   	push   %ebx
f0103a8e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a91:	53                   	push   %ebx
f0103a92:	e8 9c ff ff ff       	call   f0103a33 <strlen>
f0103a97:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103a9a:	ff 75 0c             	pushl  0xc(%ebp)
f0103a9d:	01 d8                	add    %ebx,%eax
f0103a9f:	50                   	push   %eax
f0103aa0:	e8 c5 ff ff ff       	call   f0103a6a <strcpy>
	return dst;
}
f0103aa5:	89 d8                	mov    %ebx,%eax
f0103aa7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103aaa:	c9                   	leave  
f0103aab:	c3                   	ret    

f0103aac <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103aac:	55                   	push   %ebp
f0103aad:	89 e5                	mov    %esp,%ebp
f0103aaf:	56                   	push   %esi
f0103ab0:	53                   	push   %ebx
f0103ab1:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ab4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103ab7:	89 f3                	mov    %esi,%ebx
f0103ab9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103abc:	89 f2                	mov    %esi,%edx
f0103abe:	eb 0f                	jmp    f0103acf <strncpy+0x23>
		*dst++ = *src;
f0103ac0:	83 c2 01             	add    $0x1,%edx
f0103ac3:	0f b6 01             	movzbl (%ecx),%eax
f0103ac6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103ac9:	80 39 01             	cmpb   $0x1,(%ecx)
f0103acc:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103acf:	39 da                	cmp    %ebx,%edx
f0103ad1:	75 ed                	jne    f0103ac0 <strncpy+0x14>
	}
	return ret;
}
f0103ad3:	89 f0                	mov    %esi,%eax
f0103ad5:	5b                   	pop    %ebx
f0103ad6:	5e                   	pop    %esi
f0103ad7:	5d                   	pop    %ebp
f0103ad8:	c3                   	ret    

f0103ad9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103ad9:	55                   	push   %ebp
f0103ada:	89 e5                	mov    %esp,%ebp
f0103adc:	56                   	push   %esi
f0103add:	53                   	push   %ebx
f0103ade:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ae1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ae4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103ae7:	89 f0                	mov    %esi,%eax
f0103ae9:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103aed:	85 c9                	test   %ecx,%ecx
f0103aef:	75 0b                	jne    f0103afc <strlcpy+0x23>
f0103af1:	eb 17                	jmp    f0103b0a <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103af3:	83 c2 01             	add    $0x1,%edx
f0103af6:	83 c0 01             	add    $0x1,%eax
f0103af9:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103afc:	39 d8                	cmp    %ebx,%eax
f0103afe:	74 07                	je     f0103b07 <strlcpy+0x2e>
f0103b00:	0f b6 0a             	movzbl (%edx),%ecx
f0103b03:	84 c9                	test   %cl,%cl
f0103b05:	75 ec                	jne    f0103af3 <strlcpy+0x1a>
		*dst = '\0';
f0103b07:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103b0a:	29 f0                	sub    %esi,%eax
}
f0103b0c:	5b                   	pop    %ebx
f0103b0d:	5e                   	pop    %esi
f0103b0e:	5d                   	pop    %ebp
f0103b0f:	c3                   	ret    

f0103b10 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103b10:	55                   	push   %ebp
f0103b11:	89 e5                	mov    %esp,%ebp
f0103b13:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b16:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b19:	eb 06                	jmp    f0103b21 <strcmp+0x11>
		p++, q++;
f0103b1b:	83 c1 01             	add    $0x1,%ecx
f0103b1e:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103b21:	0f b6 01             	movzbl (%ecx),%eax
f0103b24:	84 c0                	test   %al,%al
f0103b26:	74 04                	je     f0103b2c <strcmp+0x1c>
f0103b28:	3a 02                	cmp    (%edx),%al
f0103b2a:	74 ef                	je     f0103b1b <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b2c:	0f b6 c0             	movzbl %al,%eax
f0103b2f:	0f b6 12             	movzbl (%edx),%edx
f0103b32:	29 d0                	sub    %edx,%eax
}
f0103b34:	5d                   	pop    %ebp
f0103b35:	c3                   	ret    

f0103b36 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b36:	55                   	push   %ebp
f0103b37:	89 e5                	mov    %esp,%ebp
f0103b39:	53                   	push   %ebx
f0103b3a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b3d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b40:	89 c3                	mov    %eax,%ebx
f0103b42:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103b45:	eb 06                	jmp    f0103b4d <strncmp+0x17>
		n--, p++, q++;
f0103b47:	83 c0 01             	add    $0x1,%eax
f0103b4a:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103b4d:	39 d8                	cmp    %ebx,%eax
f0103b4f:	74 16                	je     f0103b67 <strncmp+0x31>
f0103b51:	0f b6 08             	movzbl (%eax),%ecx
f0103b54:	84 c9                	test   %cl,%cl
f0103b56:	74 04                	je     f0103b5c <strncmp+0x26>
f0103b58:	3a 0a                	cmp    (%edx),%cl
f0103b5a:	74 eb                	je     f0103b47 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b5c:	0f b6 00             	movzbl (%eax),%eax
f0103b5f:	0f b6 12             	movzbl (%edx),%edx
f0103b62:	29 d0                	sub    %edx,%eax
}
f0103b64:	5b                   	pop    %ebx
f0103b65:	5d                   	pop    %ebp
f0103b66:	c3                   	ret    
		return 0;
f0103b67:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b6c:	eb f6                	jmp    f0103b64 <strncmp+0x2e>

f0103b6e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b6e:	55                   	push   %ebp
f0103b6f:	89 e5                	mov    %esp,%ebp
f0103b71:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b74:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b78:	0f b6 10             	movzbl (%eax),%edx
f0103b7b:	84 d2                	test   %dl,%dl
f0103b7d:	74 09                	je     f0103b88 <strchr+0x1a>
		if (*s == c)
f0103b7f:	38 ca                	cmp    %cl,%dl
f0103b81:	74 0a                	je     f0103b8d <strchr+0x1f>
	for (; *s; s++)
f0103b83:	83 c0 01             	add    $0x1,%eax
f0103b86:	eb f0                	jmp    f0103b78 <strchr+0xa>
			return (char *) s;
	return 0;
f0103b88:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b8d:	5d                   	pop    %ebp
f0103b8e:	c3                   	ret    

f0103b8f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b8f:	55                   	push   %ebp
f0103b90:	89 e5                	mov    %esp,%ebp
f0103b92:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b95:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b99:	eb 03                	jmp    f0103b9e <strfind+0xf>
f0103b9b:	83 c0 01             	add    $0x1,%eax
f0103b9e:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103ba1:	38 ca                	cmp    %cl,%dl
f0103ba3:	74 04                	je     f0103ba9 <strfind+0x1a>
f0103ba5:	84 d2                	test   %dl,%dl
f0103ba7:	75 f2                	jne    f0103b9b <strfind+0xc>
			break;
	return (char *) s;
}
f0103ba9:	5d                   	pop    %ebp
f0103baa:	c3                   	ret    

f0103bab <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103bab:	55                   	push   %ebp
f0103bac:	89 e5                	mov    %esp,%ebp
f0103bae:	57                   	push   %edi
f0103baf:	56                   	push   %esi
f0103bb0:	53                   	push   %ebx
f0103bb1:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bb4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103bb7:	85 c9                	test   %ecx,%ecx
f0103bb9:	74 13                	je     f0103bce <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103bbb:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103bc1:	75 05                	jne    f0103bc8 <memset+0x1d>
f0103bc3:	f6 c1 03             	test   $0x3,%cl
f0103bc6:	74 0d                	je     f0103bd5 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103bc8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bcb:	fc                   	cld    
f0103bcc:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103bce:	89 f8                	mov    %edi,%eax
f0103bd0:	5b                   	pop    %ebx
f0103bd1:	5e                   	pop    %esi
f0103bd2:	5f                   	pop    %edi
f0103bd3:	5d                   	pop    %ebp
f0103bd4:	c3                   	ret    
		c &= 0xFF;
f0103bd5:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103bd9:	89 d3                	mov    %edx,%ebx
f0103bdb:	c1 e3 08             	shl    $0x8,%ebx
f0103bde:	89 d0                	mov    %edx,%eax
f0103be0:	c1 e0 18             	shl    $0x18,%eax
f0103be3:	89 d6                	mov    %edx,%esi
f0103be5:	c1 e6 10             	shl    $0x10,%esi
f0103be8:	09 f0                	or     %esi,%eax
f0103bea:	09 c2                	or     %eax,%edx
f0103bec:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103bee:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103bf1:	89 d0                	mov    %edx,%eax
f0103bf3:	fc                   	cld    
f0103bf4:	f3 ab                	rep stos %eax,%es:(%edi)
f0103bf6:	eb d6                	jmp    f0103bce <memset+0x23>

f0103bf8 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103bf8:	55                   	push   %ebp
f0103bf9:	89 e5                	mov    %esp,%ebp
f0103bfb:	57                   	push   %edi
f0103bfc:	56                   	push   %esi
f0103bfd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c00:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c03:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c06:	39 c6                	cmp    %eax,%esi
f0103c08:	73 35                	jae    f0103c3f <memmove+0x47>
f0103c0a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c0d:	39 c2                	cmp    %eax,%edx
f0103c0f:	76 2e                	jbe    f0103c3f <memmove+0x47>
		s += n;
		d += n;
f0103c11:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c14:	89 d6                	mov    %edx,%esi
f0103c16:	09 fe                	or     %edi,%esi
f0103c18:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c1e:	74 0c                	je     f0103c2c <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103c20:	83 ef 01             	sub    $0x1,%edi
f0103c23:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103c26:	fd                   	std    
f0103c27:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103c29:	fc                   	cld    
f0103c2a:	eb 21                	jmp    f0103c4d <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c2c:	f6 c1 03             	test   $0x3,%cl
f0103c2f:	75 ef                	jne    f0103c20 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103c31:	83 ef 04             	sub    $0x4,%edi
f0103c34:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c37:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103c3a:	fd                   	std    
f0103c3b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c3d:	eb ea                	jmp    f0103c29 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c3f:	89 f2                	mov    %esi,%edx
f0103c41:	09 c2                	or     %eax,%edx
f0103c43:	f6 c2 03             	test   $0x3,%dl
f0103c46:	74 09                	je     f0103c51 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c48:	89 c7                	mov    %eax,%edi
f0103c4a:	fc                   	cld    
f0103c4b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c4d:	5e                   	pop    %esi
f0103c4e:	5f                   	pop    %edi
f0103c4f:	5d                   	pop    %ebp
f0103c50:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c51:	f6 c1 03             	test   $0x3,%cl
f0103c54:	75 f2                	jne    f0103c48 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103c56:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103c59:	89 c7                	mov    %eax,%edi
f0103c5b:	fc                   	cld    
f0103c5c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c5e:	eb ed                	jmp    f0103c4d <memmove+0x55>

f0103c60 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103c60:	55                   	push   %ebp
f0103c61:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103c63:	ff 75 10             	pushl  0x10(%ebp)
f0103c66:	ff 75 0c             	pushl  0xc(%ebp)
f0103c69:	ff 75 08             	pushl  0x8(%ebp)
f0103c6c:	e8 87 ff ff ff       	call   f0103bf8 <memmove>
}
f0103c71:	c9                   	leave  
f0103c72:	c3                   	ret    

f0103c73 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c73:	55                   	push   %ebp
f0103c74:	89 e5                	mov    %esp,%ebp
f0103c76:	56                   	push   %esi
f0103c77:	53                   	push   %ebx
f0103c78:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c7b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c7e:	89 c6                	mov    %eax,%esi
f0103c80:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c83:	39 f0                	cmp    %esi,%eax
f0103c85:	74 1c                	je     f0103ca3 <memcmp+0x30>
		if (*s1 != *s2)
f0103c87:	0f b6 08             	movzbl (%eax),%ecx
f0103c8a:	0f b6 1a             	movzbl (%edx),%ebx
f0103c8d:	38 d9                	cmp    %bl,%cl
f0103c8f:	75 08                	jne    f0103c99 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103c91:	83 c0 01             	add    $0x1,%eax
f0103c94:	83 c2 01             	add    $0x1,%edx
f0103c97:	eb ea                	jmp    f0103c83 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103c99:	0f b6 c1             	movzbl %cl,%eax
f0103c9c:	0f b6 db             	movzbl %bl,%ebx
f0103c9f:	29 d8                	sub    %ebx,%eax
f0103ca1:	eb 05                	jmp    f0103ca8 <memcmp+0x35>
	}

	return 0;
f0103ca3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ca8:	5b                   	pop    %ebx
f0103ca9:	5e                   	pop    %esi
f0103caa:	5d                   	pop    %ebp
f0103cab:	c3                   	ret    

f0103cac <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103cac:	55                   	push   %ebp
f0103cad:	89 e5                	mov    %esp,%ebp
f0103caf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cb2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103cb5:	89 c2                	mov    %eax,%edx
f0103cb7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103cba:	39 d0                	cmp    %edx,%eax
f0103cbc:	73 09                	jae    f0103cc7 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103cbe:	38 08                	cmp    %cl,(%eax)
f0103cc0:	74 05                	je     f0103cc7 <memfind+0x1b>
	for (; s < ends; s++)
f0103cc2:	83 c0 01             	add    $0x1,%eax
f0103cc5:	eb f3                	jmp    f0103cba <memfind+0xe>
			break;
	return (void *) s;
}
f0103cc7:	5d                   	pop    %ebp
f0103cc8:	c3                   	ret    

f0103cc9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103cc9:	55                   	push   %ebp
f0103cca:	89 e5                	mov    %esp,%ebp
f0103ccc:	57                   	push   %edi
f0103ccd:	56                   	push   %esi
f0103cce:	53                   	push   %ebx
f0103ccf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103cd2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103cd5:	eb 03                	jmp    f0103cda <strtol+0x11>
		s++;
f0103cd7:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103cda:	0f b6 01             	movzbl (%ecx),%eax
f0103cdd:	3c 20                	cmp    $0x20,%al
f0103cdf:	74 f6                	je     f0103cd7 <strtol+0xe>
f0103ce1:	3c 09                	cmp    $0x9,%al
f0103ce3:	74 f2                	je     f0103cd7 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103ce5:	3c 2b                	cmp    $0x2b,%al
f0103ce7:	74 2e                	je     f0103d17 <strtol+0x4e>
	int neg = 0;
f0103ce9:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103cee:	3c 2d                	cmp    $0x2d,%al
f0103cf0:	74 2f                	je     f0103d21 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103cf2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103cf8:	75 05                	jne    f0103cff <strtol+0x36>
f0103cfa:	80 39 30             	cmpb   $0x30,(%ecx)
f0103cfd:	74 2c                	je     f0103d2b <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103cff:	85 db                	test   %ebx,%ebx
f0103d01:	75 0a                	jne    f0103d0d <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d03:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103d08:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d0b:	74 28                	je     f0103d35 <strtol+0x6c>
		base = 10;
f0103d0d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d12:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103d15:	eb 50                	jmp    f0103d67 <strtol+0x9e>
		s++;
f0103d17:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103d1a:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d1f:	eb d1                	jmp    f0103cf2 <strtol+0x29>
		s++, neg = 1;
f0103d21:	83 c1 01             	add    $0x1,%ecx
f0103d24:	bf 01 00 00 00       	mov    $0x1,%edi
f0103d29:	eb c7                	jmp    f0103cf2 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d2b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103d2f:	74 0e                	je     f0103d3f <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103d31:	85 db                	test   %ebx,%ebx
f0103d33:	75 d8                	jne    f0103d0d <strtol+0x44>
		s++, base = 8;
f0103d35:	83 c1 01             	add    $0x1,%ecx
f0103d38:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103d3d:	eb ce                	jmp    f0103d0d <strtol+0x44>
		s += 2, base = 16;
f0103d3f:	83 c1 02             	add    $0x2,%ecx
f0103d42:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d47:	eb c4                	jmp    f0103d0d <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103d49:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103d4c:	89 f3                	mov    %esi,%ebx
f0103d4e:	80 fb 19             	cmp    $0x19,%bl
f0103d51:	77 29                	ja     f0103d7c <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103d53:	0f be d2             	movsbl %dl,%edx
f0103d56:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103d59:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103d5c:	7d 30                	jge    f0103d8e <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103d5e:	83 c1 01             	add    $0x1,%ecx
f0103d61:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103d65:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103d67:	0f b6 11             	movzbl (%ecx),%edx
f0103d6a:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103d6d:	89 f3                	mov    %esi,%ebx
f0103d6f:	80 fb 09             	cmp    $0x9,%bl
f0103d72:	77 d5                	ja     f0103d49 <strtol+0x80>
			dig = *s - '0';
f0103d74:	0f be d2             	movsbl %dl,%edx
f0103d77:	83 ea 30             	sub    $0x30,%edx
f0103d7a:	eb dd                	jmp    f0103d59 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103d7c:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103d7f:	89 f3                	mov    %esi,%ebx
f0103d81:	80 fb 19             	cmp    $0x19,%bl
f0103d84:	77 08                	ja     f0103d8e <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103d86:	0f be d2             	movsbl %dl,%edx
f0103d89:	83 ea 37             	sub    $0x37,%edx
f0103d8c:	eb cb                	jmp    f0103d59 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103d8e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103d92:	74 05                	je     f0103d99 <strtol+0xd0>
		*endptr = (char *) s;
f0103d94:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d97:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103d99:	89 c2                	mov    %eax,%edx
f0103d9b:	f7 da                	neg    %edx
f0103d9d:	85 ff                	test   %edi,%edi
f0103d9f:	0f 45 c2             	cmovne %edx,%eax
}
f0103da2:	5b                   	pop    %ebx
f0103da3:	5e                   	pop    %esi
f0103da4:	5f                   	pop    %edi
f0103da5:	5d                   	pop    %ebp
f0103da6:	c3                   	ret    
f0103da7:	66 90                	xchg   %ax,%ax
f0103da9:	66 90                	xchg   %ax,%ax
f0103dab:	66 90                	xchg   %ax,%ax
f0103dad:	66 90                	xchg   %ax,%ax
f0103daf:	90                   	nop

f0103db0 <__udivdi3>:
f0103db0:	55                   	push   %ebp
f0103db1:	57                   	push   %edi
f0103db2:	56                   	push   %esi
f0103db3:	53                   	push   %ebx
f0103db4:	83 ec 1c             	sub    $0x1c,%esp
f0103db7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103dbb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103dbf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103dc3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103dc7:	85 d2                	test   %edx,%edx
f0103dc9:	75 35                	jne    f0103e00 <__udivdi3+0x50>
f0103dcb:	39 f3                	cmp    %esi,%ebx
f0103dcd:	0f 87 bd 00 00 00    	ja     f0103e90 <__udivdi3+0xe0>
f0103dd3:	85 db                	test   %ebx,%ebx
f0103dd5:	89 d9                	mov    %ebx,%ecx
f0103dd7:	75 0b                	jne    f0103de4 <__udivdi3+0x34>
f0103dd9:	b8 01 00 00 00       	mov    $0x1,%eax
f0103dde:	31 d2                	xor    %edx,%edx
f0103de0:	f7 f3                	div    %ebx
f0103de2:	89 c1                	mov    %eax,%ecx
f0103de4:	31 d2                	xor    %edx,%edx
f0103de6:	89 f0                	mov    %esi,%eax
f0103de8:	f7 f1                	div    %ecx
f0103dea:	89 c6                	mov    %eax,%esi
f0103dec:	89 e8                	mov    %ebp,%eax
f0103dee:	89 f7                	mov    %esi,%edi
f0103df0:	f7 f1                	div    %ecx
f0103df2:	89 fa                	mov    %edi,%edx
f0103df4:	83 c4 1c             	add    $0x1c,%esp
f0103df7:	5b                   	pop    %ebx
f0103df8:	5e                   	pop    %esi
f0103df9:	5f                   	pop    %edi
f0103dfa:	5d                   	pop    %ebp
f0103dfb:	c3                   	ret    
f0103dfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e00:	39 f2                	cmp    %esi,%edx
f0103e02:	77 7c                	ja     f0103e80 <__udivdi3+0xd0>
f0103e04:	0f bd fa             	bsr    %edx,%edi
f0103e07:	83 f7 1f             	xor    $0x1f,%edi
f0103e0a:	0f 84 98 00 00 00    	je     f0103ea8 <__udivdi3+0xf8>
f0103e10:	89 f9                	mov    %edi,%ecx
f0103e12:	b8 20 00 00 00       	mov    $0x20,%eax
f0103e17:	29 f8                	sub    %edi,%eax
f0103e19:	d3 e2                	shl    %cl,%edx
f0103e1b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e1f:	89 c1                	mov    %eax,%ecx
f0103e21:	89 da                	mov    %ebx,%edx
f0103e23:	d3 ea                	shr    %cl,%edx
f0103e25:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103e29:	09 d1                	or     %edx,%ecx
f0103e2b:	89 f2                	mov    %esi,%edx
f0103e2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103e31:	89 f9                	mov    %edi,%ecx
f0103e33:	d3 e3                	shl    %cl,%ebx
f0103e35:	89 c1                	mov    %eax,%ecx
f0103e37:	d3 ea                	shr    %cl,%edx
f0103e39:	89 f9                	mov    %edi,%ecx
f0103e3b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103e3f:	d3 e6                	shl    %cl,%esi
f0103e41:	89 eb                	mov    %ebp,%ebx
f0103e43:	89 c1                	mov    %eax,%ecx
f0103e45:	d3 eb                	shr    %cl,%ebx
f0103e47:	09 de                	or     %ebx,%esi
f0103e49:	89 f0                	mov    %esi,%eax
f0103e4b:	f7 74 24 08          	divl   0x8(%esp)
f0103e4f:	89 d6                	mov    %edx,%esi
f0103e51:	89 c3                	mov    %eax,%ebx
f0103e53:	f7 64 24 0c          	mull   0xc(%esp)
f0103e57:	39 d6                	cmp    %edx,%esi
f0103e59:	72 0c                	jb     f0103e67 <__udivdi3+0xb7>
f0103e5b:	89 f9                	mov    %edi,%ecx
f0103e5d:	d3 e5                	shl    %cl,%ebp
f0103e5f:	39 c5                	cmp    %eax,%ebp
f0103e61:	73 5d                	jae    f0103ec0 <__udivdi3+0x110>
f0103e63:	39 d6                	cmp    %edx,%esi
f0103e65:	75 59                	jne    f0103ec0 <__udivdi3+0x110>
f0103e67:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103e6a:	31 ff                	xor    %edi,%edi
f0103e6c:	89 fa                	mov    %edi,%edx
f0103e6e:	83 c4 1c             	add    $0x1c,%esp
f0103e71:	5b                   	pop    %ebx
f0103e72:	5e                   	pop    %esi
f0103e73:	5f                   	pop    %edi
f0103e74:	5d                   	pop    %ebp
f0103e75:	c3                   	ret    
f0103e76:	8d 76 00             	lea    0x0(%esi),%esi
f0103e79:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103e80:	31 ff                	xor    %edi,%edi
f0103e82:	31 c0                	xor    %eax,%eax
f0103e84:	89 fa                	mov    %edi,%edx
f0103e86:	83 c4 1c             	add    $0x1c,%esp
f0103e89:	5b                   	pop    %ebx
f0103e8a:	5e                   	pop    %esi
f0103e8b:	5f                   	pop    %edi
f0103e8c:	5d                   	pop    %ebp
f0103e8d:	c3                   	ret    
f0103e8e:	66 90                	xchg   %ax,%ax
f0103e90:	31 ff                	xor    %edi,%edi
f0103e92:	89 e8                	mov    %ebp,%eax
f0103e94:	89 f2                	mov    %esi,%edx
f0103e96:	f7 f3                	div    %ebx
f0103e98:	89 fa                	mov    %edi,%edx
f0103e9a:	83 c4 1c             	add    $0x1c,%esp
f0103e9d:	5b                   	pop    %ebx
f0103e9e:	5e                   	pop    %esi
f0103e9f:	5f                   	pop    %edi
f0103ea0:	5d                   	pop    %ebp
f0103ea1:	c3                   	ret    
f0103ea2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ea8:	39 f2                	cmp    %esi,%edx
f0103eaa:	72 06                	jb     f0103eb2 <__udivdi3+0x102>
f0103eac:	31 c0                	xor    %eax,%eax
f0103eae:	39 eb                	cmp    %ebp,%ebx
f0103eb0:	77 d2                	ja     f0103e84 <__udivdi3+0xd4>
f0103eb2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103eb7:	eb cb                	jmp    f0103e84 <__udivdi3+0xd4>
f0103eb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ec0:	89 d8                	mov    %ebx,%eax
f0103ec2:	31 ff                	xor    %edi,%edi
f0103ec4:	eb be                	jmp    f0103e84 <__udivdi3+0xd4>
f0103ec6:	66 90                	xchg   %ax,%ax
f0103ec8:	66 90                	xchg   %ax,%ax
f0103eca:	66 90                	xchg   %ax,%ax
f0103ecc:	66 90                	xchg   %ax,%ax
f0103ece:	66 90                	xchg   %ax,%ax

f0103ed0 <__umoddi3>:
f0103ed0:	55                   	push   %ebp
f0103ed1:	57                   	push   %edi
f0103ed2:	56                   	push   %esi
f0103ed3:	53                   	push   %ebx
f0103ed4:	83 ec 1c             	sub    $0x1c,%esp
f0103ed7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103edb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103edf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103ee3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103ee7:	85 ed                	test   %ebp,%ebp
f0103ee9:	89 f0                	mov    %esi,%eax
f0103eeb:	89 da                	mov    %ebx,%edx
f0103eed:	75 19                	jne    f0103f08 <__umoddi3+0x38>
f0103eef:	39 df                	cmp    %ebx,%edi
f0103ef1:	0f 86 b1 00 00 00    	jbe    f0103fa8 <__umoddi3+0xd8>
f0103ef7:	f7 f7                	div    %edi
f0103ef9:	89 d0                	mov    %edx,%eax
f0103efb:	31 d2                	xor    %edx,%edx
f0103efd:	83 c4 1c             	add    $0x1c,%esp
f0103f00:	5b                   	pop    %ebx
f0103f01:	5e                   	pop    %esi
f0103f02:	5f                   	pop    %edi
f0103f03:	5d                   	pop    %ebp
f0103f04:	c3                   	ret    
f0103f05:	8d 76 00             	lea    0x0(%esi),%esi
f0103f08:	39 dd                	cmp    %ebx,%ebp
f0103f0a:	77 f1                	ja     f0103efd <__umoddi3+0x2d>
f0103f0c:	0f bd cd             	bsr    %ebp,%ecx
f0103f0f:	83 f1 1f             	xor    $0x1f,%ecx
f0103f12:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103f16:	0f 84 b4 00 00 00    	je     f0103fd0 <__umoddi3+0x100>
f0103f1c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103f21:	89 c2                	mov    %eax,%edx
f0103f23:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103f27:	29 c2                	sub    %eax,%edx
f0103f29:	89 c1                	mov    %eax,%ecx
f0103f2b:	89 f8                	mov    %edi,%eax
f0103f2d:	d3 e5                	shl    %cl,%ebp
f0103f2f:	89 d1                	mov    %edx,%ecx
f0103f31:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103f35:	d3 e8                	shr    %cl,%eax
f0103f37:	09 c5                	or     %eax,%ebp
f0103f39:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103f3d:	89 c1                	mov    %eax,%ecx
f0103f3f:	d3 e7                	shl    %cl,%edi
f0103f41:	89 d1                	mov    %edx,%ecx
f0103f43:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103f47:	89 df                	mov    %ebx,%edi
f0103f49:	d3 ef                	shr    %cl,%edi
f0103f4b:	89 c1                	mov    %eax,%ecx
f0103f4d:	89 f0                	mov    %esi,%eax
f0103f4f:	d3 e3                	shl    %cl,%ebx
f0103f51:	89 d1                	mov    %edx,%ecx
f0103f53:	89 fa                	mov    %edi,%edx
f0103f55:	d3 e8                	shr    %cl,%eax
f0103f57:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f5c:	09 d8                	or     %ebx,%eax
f0103f5e:	f7 f5                	div    %ebp
f0103f60:	d3 e6                	shl    %cl,%esi
f0103f62:	89 d1                	mov    %edx,%ecx
f0103f64:	f7 64 24 08          	mull   0x8(%esp)
f0103f68:	39 d1                	cmp    %edx,%ecx
f0103f6a:	89 c3                	mov    %eax,%ebx
f0103f6c:	89 d7                	mov    %edx,%edi
f0103f6e:	72 06                	jb     f0103f76 <__umoddi3+0xa6>
f0103f70:	75 0e                	jne    f0103f80 <__umoddi3+0xb0>
f0103f72:	39 c6                	cmp    %eax,%esi
f0103f74:	73 0a                	jae    f0103f80 <__umoddi3+0xb0>
f0103f76:	2b 44 24 08          	sub    0x8(%esp),%eax
f0103f7a:	19 ea                	sbb    %ebp,%edx
f0103f7c:	89 d7                	mov    %edx,%edi
f0103f7e:	89 c3                	mov    %eax,%ebx
f0103f80:	89 ca                	mov    %ecx,%edx
f0103f82:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103f87:	29 de                	sub    %ebx,%esi
f0103f89:	19 fa                	sbb    %edi,%edx
f0103f8b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0103f8f:	89 d0                	mov    %edx,%eax
f0103f91:	d3 e0                	shl    %cl,%eax
f0103f93:	89 d9                	mov    %ebx,%ecx
f0103f95:	d3 ee                	shr    %cl,%esi
f0103f97:	d3 ea                	shr    %cl,%edx
f0103f99:	09 f0                	or     %esi,%eax
f0103f9b:	83 c4 1c             	add    $0x1c,%esp
f0103f9e:	5b                   	pop    %ebx
f0103f9f:	5e                   	pop    %esi
f0103fa0:	5f                   	pop    %edi
f0103fa1:	5d                   	pop    %ebp
f0103fa2:	c3                   	ret    
f0103fa3:	90                   	nop
f0103fa4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103fa8:	85 ff                	test   %edi,%edi
f0103faa:	89 f9                	mov    %edi,%ecx
f0103fac:	75 0b                	jne    f0103fb9 <__umoddi3+0xe9>
f0103fae:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fb3:	31 d2                	xor    %edx,%edx
f0103fb5:	f7 f7                	div    %edi
f0103fb7:	89 c1                	mov    %eax,%ecx
f0103fb9:	89 d8                	mov    %ebx,%eax
f0103fbb:	31 d2                	xor    %edx,%edx
f0103fbd:	f7 f1                	div    %ecx
f0103fbf:	89 f0                	mov    %esi,%eax
f0103fc1:	f7 f1                	div    %ecx
f0103fc3:	e9 31 ff ff ff       	jmp    f0103ef9 <__umoddi3+0x29>
f0103fc8:	90                   	nop
f0103fc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fd0:	39 dd                	cmp    %ebx,%ebp
f0103fd2:	72 08                	jb     f0103fdc <__umoddi3+0x10c>
f0103fd4:	39 f7                	cmp    %esi,%edi
f0103fd6:	0f 87 21 ff ff ff    	ja     f0103efd <__umoddi3+0x2d>
f0103fdc:	89 da                	mov    %ebx,%edx
f0103fde:	89 f0                	mov    %esi,%eax
f0103fe0:	29 f8                	sub    %edi,%eax
f0103fe2:	19 ea                	sbb    %ebp,%edx
f0103fe4:	e9 14 ff ff ff       	jmp    f0103efd <__umoddi3+0x2d>
