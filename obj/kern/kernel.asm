
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
f0100064:	e8 d6 3a 00 00       	call   f0103b3f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 74 cc fe ff    	lea    -0x1338c(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 ac 2e 00 00       	call   f0102f2e <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 72 12 00 00       	call   f01012f9 <mem_init>
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
f01000da:	8d 83 8f cc fe ff    	lea    -0x13371(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 48 2e 00 00       	call   f0102f2e <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 07 2e 00 00       	call   f0102ef7 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 99 db fe ff    	lea    -0x12467(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 30 2e 00 00       	call   f0102f2e <cprintf>
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
f010011f:	8d 83 a7 cc fe ff    	lea    -0x13359(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 03 2e 00 00       	call   f0102f2e <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 c0 2d 00 00       	call   f0102ef7 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 99 db fe ff    	lea    -0x12467(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 e9 2d 00 00       	call   f0102f2e <cprintf>
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
f0100217:	0f b6 84 13 f4 cd fe 	movzbl -0x1320c(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 f4 cc fe 	movzbl -0x1330c(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 c1 cc fe ff    	lea    -0x1333f(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 b8 2c 00 00       	call   f0102f2e <cprintf>
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
f01002b1:	0f b6 84 13 f4 cd fe 	movzbl -0x1320c(%ebx,%edx,1),%eax
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
f01004d2:	e8 b5 36 00 00       	call   f0103b8c <memmove>
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
f01006b5:	8d 83 cd cc fe ff    	lea    -0x13333(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 6d 28 00 00       	call   f0102f2e <cprintf>
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
f0100708:	8d 83 f4 ce fe ff    	lea    -0x1310c(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 12 cf fe ff    	lea    -0x130ee(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 17 cf fe ff    	lea    -0x130e9(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 0c 28 00 00       	call   f0102f2e <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 d4 cf fe ff    	lea    -0x1302c(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 20 cf fe ff    	lea    -0x130e0(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 f5 27 00 00       	call   f0102f2e <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 fc cf fe ff    	lea    -0x13004(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 29 cf fe ff    	lea    -0x130d7(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 de 27 00 00       	call   f0102f2e <cprintf>
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
f0100770:	8d 83 33 cf fe ff    	lea    -0x130cd(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 b2 27 00 00       	call   f0102f2e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f0100785:	8d 83 20 d0 fe ff    	lea    -0x12fe0(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 9d 27 00 00       	call   f0102f2e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 48 d0 fe ff    	lea    -0x12fb8(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 80 27 00 00       	call   f0102f2e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 79 3f 10 f0    	mov    $0xf0103f79,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 6c d0 fe ff    	lea    -0x12f94(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 63 27 00 00       	call   f0102f2e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 90 d0 fe ff    	lea    -0x12f70(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 46 27 00 00       	call   f0102f2e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 a0 96 11 f0    	mov    $0xf01196a0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 b4 d0 fe ff    	lea    -0x12f4c(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 29 27 00 00       	call   f0102f2e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 d8 d0 fe ff    	lea    -0x12f28(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 0e 27 00 00       	call   f0102f2e <cprintf>
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
f0100841:	8d 83 4c cf fe ff    	lea    -0x130b4(%ebx),%eax
f0100847:	50                   	push   %eax
f0100848:	e8 e1 26 00 00       	call   f0102f2e <cprintf>

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
f0100852:	8d 83 5e cf fe ff    	lea    -0x130a2(%ebx),%eax
f0100858:	89 45 b8             	mov    %eax,-0x48(%ebp)
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
f010085b:	8d 83 79 cf fe ff    	lea    -0x13087(%ebx),%eax
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
f010087c:	e8 ad 26 00 00       	call   f0102f2e <cprintf>
f0100881:	8d 77 08             	lea    0x8(%edi),%esi
f0100884:	83 c7 1c             	add    $0x1c,%edi
f0100887:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	ff 36                	pushl  (%esi)
f010088f:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100892:	e8 97 26 00 00       	call   f0102f2e <cprintf>
f0100897:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	39 fe                	cmp    %edi,%esi
f010089f:	75 e9                	jne    f010088a <mon_backtrace+0x5d>
		}
		cprintf("\n");
f01008a1:	83 ec 0c             	sub    $0xc,%esp
f01008a4:	8d 83 99 db fe ff    	lea    -0x12467(%ebx),%eax
f01008aa:	50                   	push   %eax
f01008ab:	e8 7e 26 00 00       	call   f0102f2e <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008b0:	83 c4 08             	add    $0x8,%esp
f01008b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008b6:	50                   	push   %eax
f01008b7:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008ba:	57                   	push   %edi
f01008bb:	e8 72 27 00 00       	call   f0103032 <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f01008c0:	83 c4 0c             	add    $0xc,%esp
f01008c3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008c9:	8d 83 7f cf fe ff    	lea    -0x13081(%ebx),%eax
f01008cf:	50                   	push   %eax
f01008d0:	e8 59 26 00 00       	call   f0102f2e <cprintf>
		// for (int i = 0; i < info.eip_fn_namelen;++i){
		// 	cprintf("%c", info.eip_fn_name[i]);
		// }
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f01008d5:	89 f8                	mov    %edi,%eax
f01008d7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008da:	50                   	push   %eax
f01008db:	ff 75 d8             	pushl  -0x28(%ebp)
f01008de:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e1:	8d 83 8f cf fe ff    	lea    -0x13071(%ebx),%eax
f01008e7:	50                   	push   %eax
f01008e8:	e8 41 26 00 00       	call   f0102f2e <cprintf>
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
f010091c:	8d 83 04 d1 fe ff    	lea    -0x12efc(%ebx),%eax
f0100922:	50                   	push   %eax
f0100923:	e8 06 26 00 00       	call   f0102f2e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100928:	8d 83 28 d1 fe ff    	lea    -0x12ed8(%ebx),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 f8 25 00 00       	call   f0102f2e <cprintf>
f0100936:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100939:	8d bb 9c cf fe ff    	lea    -0x13064(%ebx),%edi
f010093f:	eb 4a                	jmp    f010098b <monitor+0x83>
f0100941:	83 ec 08             	sub    $0x8,%esp
f0100944:	0f be c0             	movsbl %al,%eax
f0100947:	50                   	push   %eax
f0100948:	57                   	push   %edi
f0100949:	e8 b4 31 00 00       	call   f0103b02 <strchr>
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
f010097c:	8d 83 a1 cf fe ff    	lea    -0x1305f(%ebx),%eax
f0100982:	50                   	push   %eax
f0100983:	e8 a6 25 00 00       	call   f0102f2e <cprintf>
f0100988:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010098b:	8d 83 98 cf fe ff    	lea    -0x13068(%ebx),%eax
f0100991:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100994:	83 ec 0c             	sub    $0xc,%esp
f0100997:	ff 75 a4             	pushl  -0x5c(%ebp)
f010099a:	e8 2b 2f 00 00       	call   f01038ca <readline>
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
f01009ca:	e8 33 31 00 00       	call   f0103b02 <strchr>
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
f0100a05:	e8 9a 30 00 00       	call   f0103aa4 <strcmp>
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
f0100a26:	8d 83 be cf fe ff    	lea    -0x13042(%ebx),%eax
f0100a2c:	50                   	push   %eax
f0100a2d:	e8 fc 24 00 00       	call   f0102f2e <cprintf>
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
f0100a6a:	e8 28 24 00 00       	call   f0102e97 <__x86.get_pc_thunk.dx>
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
f0100ad7:	e8 cb 23 00 00       	call   f0102ea7 <mc146818_read>
f0100adc:	89 c6                	mov    %eax,%esi
f0100ade:	83 c7 01             	add    $0x1,%edi
f0100ae1:	89 3c 24             	mov    %edi,(%esp)
f0100ae4:	e8 be 23 00 00       	call   f0102ea7 <mc146818_read>
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
f0100afb:	e8 9b 23 00 00       	call   f0102e9b <__x86.get_pc_thunk.cx>
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
f0100b52:	8d 81 50 d1 fe ff    	lea    -0x12eb0(%ecx),%eax
f0100b58:	50                   	push   %eax
f0100b59:	68 f6 02 00 00       	push   $0x2f6
f0100b5e:	8d 81 e8 d8 fe ff    	lea    -0x12718(%ecx),%eax
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
f0100b7c:	e8 22 23 00 00       	call   f0102ea3 <__x86.get_pc_thunk.di>
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
f0100bb0:	8d 83 74 d1 fe ff    	lea    -0x12e8c(%ebx),%eax
f0100bb6:	50                   	push   %eax
f0100bb7:	68 37 02 00 00       	push   $0x237
f0100bbc:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0100bc2:	50                   	push   %eax
f0100bc3:	e8 d1 f4 ff ff       	call   f0100099 <_panic>
f0100bc8:	50                   	push   %eax
f0100bc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bcc:	8d 83 50 d1 fe ff    	lea    -0x12eb0(%ebx),%eax
f0100bd2:	50                   	push   %eax
f0100bd3:	6a 59                	push   $0x59
f0100bd5:	8d 83 f4 d8 fe ff    	lea    -0x1270c(%ebx),%eax
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
f0100c1d:	e8 1d 2f 00 00       	call   f0103b3f <memset>
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
f0100c66:	8d 83 02 d9 fe ff    	lea    -0x126fe(%ebx),%eax
f0100c6c:	50                   	push   %eax
f0100c6d:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100c73:	50                   	push   %eax
f0100c74:	68 51 02 00 00       	push   $0x251
f0100c79:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0100c7f:	50                   	push   %eax
f0100c80:	e8 14 f4 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100c85:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c88:	8d 83 23 d9 fe ff    	lea    -0x126dd(%ebx),%eax
f0100c8e:	50                   	push   %eax
f0100c8f:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100c95:	50                   	push   %eax
f0100c96:	68 52 02 00 00       	push   $0x252
f0100c9b:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0100ca1:	50                   	push   %eax
f0100ca2:	e8 f2 f3 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100caa:	8d 83 98 d1 fe ff    	lea    -0x12e68(%ebx),%eax
f0100cb0:	50                   	push   %eax
f0100cb1:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100cb7:	50                   	push   %eax
f0100cb8:	68 53 02 00 00       	push   $0x253
f0100cbd:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0100cc3:	50                   	push   %eax
f0100cc4:	e8 d0 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100cc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ccc:	8d 83 37 d9 fe ff    	lea    -0x126c9(%ebx),%eax
f0100cd2:	50                   	push   %eax
f0100cd3:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100cd9:	50                   	push   %eax
f0100cda:	68 56 02 00 00       	push   $0x256
f0100cdf:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0100ce5:	50                   	push   %eax
f0100ce6:	e8 ae f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ceb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cee:	8d 83 48 d9 fe ff    	lea    -0x126b8(%ebx),%eax
f0100cf4:	50                   	push   %eax
f0100cf5:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100cfb:	50                   	push   %eax
f0100cfc:	68 57 02 00 00       	push   $0x257
f0100d01:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0100d07:	50                   	push   %eax
f0100d08:	e8 8c f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d0d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d10:	8d 83 cc d1 fe ff    	lea    -0x12e34(%ebx),%eax
f0100d16:	50                   	push   %eax
f0100d17:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100d1d:	50                   	push   %eax
f0100d1e:	68 58 02 00 00       	push   $0x258
f0100d23:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0100d29:	50                   	push   %eax
f0100d2a:	e8 6a f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d2f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d32:	8d 83 61 d9 fe ff    	lea    -0x1269f(%ebx),%eax
f0100d38:	50                   	push   %eax
f0100d39:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100d3f:	50                   	push   %eax
f0100d40:	68 59 02 00 00       	push   $0x259
f0100d45:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
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
f0100dcf:	8d 83 50 d1 fe ff    	lea    -0x12eb0(%ebx),%eax
f0100dd5:	50                   	push   %eax
f0100dd6:	6a 59                	push   $0x59
f0100dd8:	8d 83 f4 d8 fe ff    	lea    -0x1270c(%ebx),%eax
f0100dde:	50                   	push   %eax
f0100ddf:	e8 b5 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100de4:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100de7:	8d 83 f0 d1 fe ff    	lea    -0x12e10(%ebx),%eax
f0100ded:	50                   	push   %eax
f0100dee:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100df4:	50                   	push   %eax
f0100df5:	68 5a 02 00 00       	push   $0x25a
f0100dfa:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
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
f0100e17:	8d 83 38 d2 fe ff    	lea    -0x12dc8(%ebx),%eax
f0100e1d:	50                   	push   %eax
f0100e1e:	e8 0b 21 00 00       	call   f0102f2e <cprintf>
}
f0100e23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e26:	5b                   	pop    %ebx
f0100e27:	5e                   	pop    %esi
f0100e28:	5f                   	pop    %edi
f0100e29:	5d                   	pop    %ebp
f0100e2a:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e2b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e2e:	8d 83 7b d9 fe ff    	lea    -0x12685(%ebx),%eax
f0100e34:	50                   	push   %eax
f0100e35:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100e3b:	50                   	push   %eax
f0100e3c:	68 62 02 00 00       	push   $0x262
f0100e41:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0100e47:	50                   	push   %eax
f0100e48:	e8 4c f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e4d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e50:	8d 83 8d d9 fe ff    	lea    -0x12673(%ebx),%eax
f0100e56:	50                   	push   %eax
f0100e57:	8d 83 0e d9 fe ff    	lea    -0x126f2(%ebx),%eax
f0100e5d:	50                   	push   %eax
f0100e5e:	68 63 02 00 00       	push   $0x263
f0100e63:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
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
f0100eff:	e8 9b 1f 00 00       	call   f0102e9f <__x86.get_pc_thunk.si>
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
f0100f4f:	8d 86 5c d2 fe ff    	lea    -0x12da4(%esi),%eax
f0100f55:	50                   	push   %eax
f0100f56:	68 11 01 00 00       	push   $0x111
f0100f5b:	8d 86 e8 d8 fe ff    	lea    -0x12718(%esi),%eax
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
f010104d:	e8 ed 2a 00 00       	call   f0103b3f <memset>
f0101052:	83 c4 10             	add    $0x10,%esp
f0101055:	eb bc                	jmp    f0101013 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101057:	50                   	push   %eax
f0101058:	8d 83 50 d1 fe ff    	lea    -0x12eb0(%ebx),%eax
f010105e:	50                   	push   %eax
f010105f:	6a 59                	push   $0x59
f0101061:	8d 83 f4 d8 fe ff    	lea    -0x1270c(%ebx),%eax
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
f01010a4:	8d 83 80 d2 fe ff    	lea    -0x12d80(%ebx),%eax
f01010aa:	50                   	push   %eax
f01010ab:	68 4b 01 00 00       	push   $0x14b
f01010b0:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
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
f010116e:	8d 83 50 d1 fe ff    	lea    -0x12eb0(%ebx),%eax
f0101174:	50                   	push   %eax
f0101175:	6a 59                	push   $0x59
f0101177:	8d 83 f4 d8 fe ff    	lea    -0x1270c(%ebx),%eax
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
f01011a8:	8d 83 50 d1 fe ff    	lea    -0x12eb0(%ebx),%eax
f01011ae:	50                   	push   %eax
f01011af:	68 8c 01 00 00       	push   $0x18c
f01011b4:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
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
f0101222:	8d 83 a0 d2 fe ff    	lea    -0x12d60(%ebx),%eax
f0101228:	50                   	push   %eax
f0101229:	6a 52                	push   $0x52
f010122b:	8d 83 f4 d8 fe ff    	lea    -0x1270c(%ebx),%eax
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
f0101281:	83 ec 10             	sub    $0x10,%esp
f0101284:	e8 1a 1c 00 00       	call   f0102ea3 <__x86.get_pc_thunk.di>
f0101289:	81 c7 83 60 01 00    	add    $0x16083,%edi
f010128f:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101292:	6a 01                	push   $0x1
f0101294:	ff 75 10             	pushl  0x10(%ebp)
f0101297:	ff 75 08             	pushl  0x8(%ebp)
f010129a:	e8 46 fe ff ff       	call   f01010e5 <pgdir_walk>
	if (!pte)
f010129f:	83 c4 10             	add    $0x10,%esp
f01012a2:	85 c0                	test   %eax,%eax
f01012a4:	74 4c                	je     f01012f2 <page_insert+0x77>
f01012a6:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;   // 引用计数的增加必须在 page_remove 前面！！
f01012a8:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	pp->pp_link = NULL;
f01012ad:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if(*pte&PTE_P){
f01012b3:	f6 00 01             	testb  $0x1,(%eax)
f01012b6:	75 27                	jne    f01012df <page_insert+0x64>
	return (pp - pages) << PGSHIFT;
f01012b8:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f01012be:	2b 30                	sub    (%eax),%esi
f01012c0:	89 f0                	mov    %esi,%eax
f01012c2:	c1 f8 03             	sar    $0x3,%eax
f01012c5:	c1 e0 0c             	shl    $0xc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
f01012c8:	8b 55 14             	mov    0x14(%ebp),%edx
f01012cb:	83 ca 01             	or     $0x1,%edx
f01012ce:	09 d0                	or     %edx,%eax
f01012d0:	89 03                	mov    %eax,(%ebx)
	return 0;
f01012d2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012da:	5b                   	pop    %ebx
f01012db:	5e                   	pop    %esi
f01012dc:	5f                   	pop    %edi
f01012dd:	5d                   	pop    %ebp
f01012de:	c3                   	ret    
		page_remove(pgdir, va);
f01012df:	83 ec 08             	sub    $0x8,%esp
f01012e2:	ff 75 10             	pushl  0x10(%ebp)
f01012e5:	ff 75 08             	pushl  0x8(%ebp)
f01012e8:	e8 51 ff ff ff       	call   f010123e <page_remove>
f01012ed:	83 c4 10             	add    $0x10,%esp
f01012f0:	eb c6                	jmp    f01012b8 <page_insert+0x3d>
		return -E_NO_MEM;
f01012f2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01012f7:	eb de                	jmp    f01012d7 <page_insert+0x5c>

f01012f9 <mem_init>:
{
f01012f9:	55                   	push   %ebp
f01012fa:	89 e5                	mov    %esp,%ebp
f01012fc:	57                   	push   %edi
f01012fd:	56                   	push   %esi
f01012fe:	53                   	push   %ebx
f01012ff:	83 ec 3c             	sub    $0x3c,%esp
f0101302:	e8 9c 1b 00 00       	call   f0102ea3 <__x86.get_pc_thunk.di>
f0101307:	81 c7 05 60 01 00    	add    $0x16005,%edi
	basemem = nvram_read(NVRAM_BASELO);
f010130d:	b8 15 00 00 00       	mov    $0x15,%eax
f0101312:	e8 a9 f7 ff ff       	call   f0100ac0 <nvram_read>
f0101317:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101319:	b8 17 00 00 00       	mov    $0x17,%eax
f010131e:	e8 9d f7 ff ff       	call   f0100ac0 <nvram_read>
f0101323:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101325:	b8 34 00 00 00       	mov    $0x34,%eax
f010132a:	e8 91 f7 ff ff       	call   f0100ac0 <nvram_read>
f010132f:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101332:	85 c0                	test   %eax,%eax
f0101334:	0f 85 b9 00 00 00    	jne    f01013f3 <mem_init+0xfa>
		totalmem = 1 * 1024 + extmem;
f010133a:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101340:	85 f6                	test   %esi,%esi
f0101342:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101345:	89 c1                	mov    %eax,%ecx
f0101347:	c1 e9 02             	shr    $0x2,%ecx
f010134a:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101350:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101352:	89 c2                	mov    %eax,%edx
f0101354:	29 da                	sub    %ebx,%edx
f0101356:	52                   	push   %edx
f0101357:	53                   	push   %ebx
f0101358:	50                   	push   %eax
f0101359:	8d 87 c0 d2 fe ff    	lea    -0x12d40(%edi),%eax
f010135f:	50                   	push   %eax
f0101360:	89 fb                	mov    %edi,%ebx
f0101362:	e8 c7 1b 00 00       	call   f0102f2e <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);    // 初始占一整页
f0101367:	b8 00 10 00 00       	mov    $0x1000,%eax
f010136c:	e8 f6 f6 ff ff       	call   f0100a67 <boot_alloc>
f0101371:	c7 c6 ac 96 11 f0    	mov    $0xf01196ac,%esi
f0101377:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);   // 初始化为0
f0101379:	83 c4 0c             	add    $0xc,%esp
f010137c:	68 00 10 00 00       	push   $0x1000
f0101381:	6a 00                	push   $0x0
f0101383:	50                   	push   %eax
f0101384:	e8 b6 27 00 00       	call   f0103b3f <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101389:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010138b:	83 c4 10             	add    $0x10,%esp
f010138e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101393:	76 68                	jbe    f01013fd <mem_init+0x104>
	return (physaddr_t)kva - KERNBASE;
f0101395:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010139b:	83 ca 05             	or     $0x5,%edx
f010139e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f01013a4:	c7 c3 a8 96 11 f0    	mov    $0xf01196a8,%ebx
f01013aa:	8b 03                	mov    (%ebx),%eax
f01013ac:	c1 e0 03             	shl    $0x3,%eax
f01013af:	e8 b3 f6 ff ff       	call   f0100a67 <boot_alloc>
f01013b4:	c7 c6 b0 96 11 f0    	mov    $0xf01196b0,%esi
f01013ba:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01013bc:	83 ec 04             	sub    $0x4,%esp
f01013bf:	8b 13                	mov    (%ebx),%edx
f01013c1:	c1 e2 03             	shl    $0x3,%edx
f01013c4:	52                   	push   %edx
f01013c5:	6a 00                	push   $0x0
f01013c7:	50                   	push   %eax
f01013c8:	89 fb                	mov    %edi,%ebx
f01013ca:	e8 70 27 00 00       	call   f0103b3f <memset>
	page_init();
f01013cf:	e8 22 fb ff ff       	call   f0100ef6 <page_init>
	check_page_free_list(1);
f01013d4:	b8 01 00 00 00       	mov    $0x1,%eax
f01013d9:	e8 95 f7 ff ff       	call   f0100b73 <check_page_free_list>
	if (!pages)
f01013de:	83 c4 10             	add    $0x10,%esp
f01013e1:	83 3e 00             	cmpl   $0x0,(%esi)
f01013e4:	74 30                	je     f0101416 <mem_init+0x11d>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013e6:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f01013ec:	be 00 00 00 00       	mov    $0x0,%esi
f01013f1:	eb 43                	jmp    f0101436 <mem_init+0x13d>
		totalmem = 16 * 1024 + ext16mem;
f01013f3:	05 00 40 00 00       	add    $0x4000,%eax
f01013f8:	e9 48 ff ff ff       	jmp    f0101345 <mem_init+0x4c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013fd:	50                   	push   %eax
f01013fe:	8d 87 5c d2 fe ff    	lea    -0x12da4(%edi),%eax
f0101404:	50                   	push   %eax
f0101405:	68 9b 00 00 00       	push   $0x9b
f010140a:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0101410:	50                   	push   %eax
f0101411:	e8 83 ec ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101416:	83 ec 04             	sub    $0x4,%esp
f0101419:	8d 87 9e d9 fe ff    	lea    -0x12662(%edi),%eax
f010141f:	50                   	push   %eax
f0101420:	68 76 02 00 00       	push   $0x276
f0101425:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010142b:	50                   	push   %eax
f010142c:	e8 68 ec ff ff       	call   f0100099 <_panic>
		++nfree;
f0101431:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101434:	8b 00                	mov    (%eax),%eax
f0101436:	85 c0                	test   %eax,%eax
f0101438:	75 f7                	jne    f0101431 <mem_init+0x138>
	assert((pp0 = page_alloc(0)));
f010143a:	83 ec 0c             	sub    $0xc,%esp
f010143d:	6a 00                	push   $0x0
f010143f:	e8 a1 fb ff ff       	call   f0100fe5 <page_alloc>
f0101444:	89 c3                	mov    %eax,%ebx
f0101446:	83 c4 10             	add    $0x10,%esp
f0101449:	85 c0                	test   %eax,%eax
f010144b:	0f 84 3f 02 00 00    	je     f0101690 <mem_init+0x397>
	assert((pp1 = page_alloc(0)));
f0101451:	83 ec 0c             	sub    $0xc,%esp
f0101454:	6a 00                	push   $0x0
f0101456:	e8 8a fb ff ff       	call   f0100fe5 <page_alloc>
f010145b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010145e:	83 c4 10             	add    $0x10,%esp
f0101461:	85 c0                	test   %eax,%eax
f0101463:	0f 84 48 02 00 00    	je     f01016b1 <mem_init+0x3b8>
	assert((pp2 = page_alloc(0)));
f0101469:	83 ec 0c             	sub    $0xc,%esp
f010146c:	6a 00                	push   $0x0
f010146e:	e8 72 fb ff ff       	call   f0100fe5 <page_alloc>
f0101473:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101476:	83 c4 10             	add    $0x10,%esp
f0101479:	85 c0                	test   %eax,%eax
f010147b:	0f 84 51 02 00 00    	je     f01016d2 <mem_init+0x3d9>
	assert(pp1 && pp1 != pp0);
f0101481:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101484:	0f 84 69 02 00 00    	je     f01016f3 <mem_init+0x3fa>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010148a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010148d:	39 c3                	cmp    %eax,%ebx
f010148f:	0f 84 7f 02 00 00    	je     f0101714 <mem_init+0x41b>
f0101495:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101498:	0f 84 76 02 00 00    	je     f0101714 <mem_init+0x41b>
	return (pp - pages) << PGSHIFT;
f010149e:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f01014a4:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014a6:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f01014ac:	8b 10                	mov    (%eax),%edx
f01014ae:	c1 e2 0c             	shl    $0xc,%edx
f01014b1:	89 d8                	mov    %ebx,%eax
f01014b3:	29 c8                	sub    %ecx,%eax
f01014b5:	c1 f8 03             	sar    $0x3,%eax
f01014b8:	c1 e0 0c             	shl    $0xc,%eax
f01014bb:	39 d0                	cmp    %edx,%eax
f01014bd:	0f 83 72 02 00 00    	jae    f0101735 <mem_init+0x43c>
f01014c3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014c6:	29 c8                	sub    %ecx,%eax
f01014c8:	c1 f8 03             	sar    $0x3,%eax
f01014cb:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01014ce:	39 c2                	cmp    %eax,%edx
f01014d0:	0f 86 80 02 00 00    	jbe    f0101756 <mem_init+0x45d>
f01014d6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014d9:	29 c8                	sub    %ecx,%eax
f01014db:	c1 f8 03             	sar    $0x3,%eax
f01014de:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01014e1:	39 c2                	cmp    %eax,%edx
f01014e3:	0f 86 8e 02 00 00    	jbe    f0101777 <mem_init+0x47e>
	fl = page_free_list;
f01014e9:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f01014ef:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f01014f2:	c7 87 90 1f 00 00 00 	movl   $0x0,0x1f90(%edi)
f01014f9:	00 00 00 
	assert(!page_alloc(0));
f01014fc:	83 ec 0c             	sub    $0xc,%esp
f01014ff:	6a 00                	push   $0x0
f0101501:	e8 df fa ff ff       	call   f0100fe5 <page_alloc>
f0101506:	83 c4 10             	add    $0x10,%esp
f0101509:	85 c0                	test   %eax,%eax
f010150b:	0f 85 87 02 00 00    	jne    f0101798 <mem_init+0x49f>
	page_free(pp0);
f0101511:	83 ec 0c             	sub    $0xc,%esp
f0101514:	53                   	push   %ebx
f0101515:	e8 53 fb ff ff       	call   f010106d <page_free>
	page_free(pp1);
f010151a:	83 c4 04             	add    $0x4,%esp
f010151d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101520:	e8 48 fb ff ff       	call   f010106d <page_free>
	page_free(pp2);
f0101525:	83 c4 04             	add    $0x4,%esp
f0101528:	ff 75 d0             	pushl  -0x30(%ebp)
f010152b:	e8 3d fb ff ff       	call   f010106d <page_free>
	assert((pp0 = page_alloc(0)));
f0101530:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101537:	e8 a9 fa ff ff       	call   f0100fe5 <page_alloc>
f010153c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010153f:	83 c4 10             	add    $0x10,%esp
f0101542:	85 c0                	test   %eax,%eax
f0101544:	0f 84 6f 02 00 00    	je     f01017b9 <mem_init+0x4c0>
	assert((pp1 = page_alloc(0)));
f010154a:	83 ec 0c             	sub    $0xc,%esp
f010154d:	6a 00                	push   $0x0
f010154f:	e8 91 fa ff ff       	call   f0100fe5 <page_alloc>
f0101554:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101557:	83 c4 10             	add    $0x10,%esp
f010155a:	85 c0                	test   %eax,%eax
f010155c:	0f 84 78 02 00 00    	je     f01017da <mem_init+0x4e1>
	assert((pp2 = page_alloc(0)));
f0101562:	83 ec 0c             	sub    $0xc,%esp
f0101565:	6a 00                	push   $0x0
f0101567:	e8 79 fa ff ff       	call   f0100fe5 <page_alloc>
f010156c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010156f:	83 c4 10             	add    $0x10,%esp
f0101572:	85 c0                	test   %eax,%eax
f0101574:	0f 84 81 02 00 00    	je     f01017fb <mem_init+0x502>
	assert(pp1 && pp1 != pp0);
f010157a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010157d:	39 4d d4             	cmp    %ecx,-0x2c(%ebp)
f0101580:	0f 84 96 02 00 00    	je     f010181c <mem_init+0x523>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101586:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101589:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010158c:	0f 84 ab 02 00 00    	je     f010183d <mem_init+0x544>
f0101592:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101595:	0f 84 a2 02 00 00    	je     f010183d <mem_init+0x544>
	assert(!page_alloc(0));
f010159b:	83 ec 0c             	sub    $0xc,%esp
f010159e:	6a 00                	push   $0x0
f01015a0:	e8 40 fa ff ff       	call   f0100fe5 <page_alloc>
f01015a5:	83 c4 10             	add    $0x10,%esp
f01015a8:	85 c0                	test   %eax,%eax
f01015aa:	0f 85 ae 02 00 00    	jne    f010185e <mem_init+0x565>
f01015b0:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f01015b6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01015b9:	2b 08                	sub    (%eax),%ecx
f01015bb:	89 c8                	mov    %ecx,%eax
f01015bd:	c1 f8 03             	sar    $0x3,%eax
f01015c0:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01015c3:	89 c1                	mov    %eax,%ecx
f01015c5:	c1 e9 0c             	shr    $0xc,%ecx
f01015c8:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f01015ce:	3b 0a                	cmp    (%edx),%ecx
f01015d0:	0f 83 a9 02 00 00    	jae    f010187f <mem_init+0x586>
	memset(page2kva(pp0), 1, PGSIZE);
f01015d6:	83 ec 04             	sub    $0x4,%esp
f01015d9:	68 00 10 00 00       	push   $0x1000
f01015de:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01015e0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015e5:	50                   	push   %eax
f01015e6:	89 fb                	mov    %edi,%ebx
f01015e8:	e8 52 25 00 00       	call   f0103b3f <memset>
	page_free(pp0);
f01015ed:	83 c4 04             	add    $0x4,%esp
f01015f0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015f3:	e8 75 fa ff ff       	call   f010106d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015f8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015ff:	e8 e1 f9 ff ff       	call   f0100fe5 <page_alloc>
f0101604:	83 c4 10             	add    $0x10,%esp
f0101607:	85 c0                	test   %eax,%eax
f0101609:	0f 84 88 02 00 00    	je     f0101897 <mem_init+0x59e>
	assert(pp && pp0 == pp);
f010160f:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101612:	0f 85 9e 02 00 00    	jne    f01018b6 <mem_init+0x5bd>
	return (pp - pages) << PGSHIFT;
f0101618:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f010161e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101621:	2b 10                	sub    (%eax),%edx
f0101623:	c1 fa 03             	sar    $0x3,%edx
f0101626:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101629:	89 d1                	mov    %edx,%ecx
f010162b:	c1 e9 0c             	shr    $0xc,%ecx
f010162e:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0101634:	3b 08                	cmp    (%eax),%ecx
f0101636:	0f 83 99 02 00 00    	jae    f01018d5 <mem_init+0x5dc>
	return (void *)(pa + KERNBASE);
f010163c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101642:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101648:	80 38 00             	cmpb   $0x0,(%eax)
f010164b:	0f 85 9a 02 00 00    	jne    f01018eb <mem_init+0x5f2>
f0101651:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101654:	39 d0                	cmp    %edx,%eax
f0101656:	75 f0                	jne    f0101648 <mem_init+0x34f>
	page_free_list = fl;
f0101658:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010165b:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	page_free(pp0);
f0101661:	83 ec 0c             	sub    $0xc,%esp
f0101664:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101667:	e8 01 fa ff ff       	call   f010106d <page_free>
	page_free(pp1);
f010166c:	83 c4 04             	add    $0x4,%esp
f010166f:	ff 75 d0             	pushl  -0x30(%ebp)
f0101672:	e8 f6 f9 ff ff       	call   f010106d <page_free>
	page_free(pp2);
f0101677:	83 c4 04             	add    $0x4,%esp
f010167a:	ff 75 cc             	pushl  -0x34(%ebp)
f010167d:	e8 eb f9 ff ff       	call   f010106d <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101682:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f0101688:	83 c4 10             	add    $0x10,%esp
f010168b:	e9 81 02 00 00       	jmp    f0101911 <mem_init+0x618>
	assert((pp0 = page_alloc(0)));
f0101690:	8d 87 b9 d9 fe ff    	lea    -0x12647(%edi),%eax
f0101696:	50                   	push   %eax
f0101697:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010169d:	50                   	push   %eax
f010169e:	68 7e 02 00 00       	push   $0x27e
f01016a3:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01016a9:	50                   	push   %eax
f01016aa:	89 fb                	mov    %edi,%ebx
f01016ac:	e8 e8 e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01016b1:	8d 87 cf d9 fe ff    	lea    -0x12631(%edi),%eax
f01016b7:	50                   	push   %eax
f01016b8:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01016be:	50                   	push   %eax
f01016bf:	68 7f 02 00 00       	push   $0x27f
f01016c4:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01016ca:	50                   	push   %eax
f01016cb:	89 fb                	mov    %edi,%ebx
f01016cd:	e8 c7 e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01016d2:	8d 87 e5 d9 fe ff    	lea    -0x1261b(%edi),%eax
f01016d8:	50                   	push   %eax
f01016d9:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01016df:	50                   	push   %eax
f01016e0:	68 80 02 00 00       	push   $0x280
f01016e5:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01016eb:	50                   	push   %eax
f01016ec:	89 fb                	mov    %edi,%ebx
f01016ee:	e8 a6 e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01016f3:	8d 87 fb d9 fe ff    	lea    -0x12605(%edi),%eax
f01016f9:	50                   	push   %eax
f01016fa:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0101700:	50                   	push   %eax
f0101701:	68 83 02 00 00       	push   $0x283
f0101706:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010170c:	50                   	push   %eax
f010170d:	89 fb                	mov    %edi,%ebx
f010170f:	e8 85 e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101714:	8d 87 fc d2 fe ff    	lea    -0x12d04(%edi),%eax
f010171a:	50                   	push   %eax
f010171b:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0101721:	50                   	push   %eax
f0101722:	68 84 02 00 00       	push   $0x284
f0101727:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010172d:	50                   	push   %eax
f010172e:	89 fb                	mov    %edi,%ebx
f0101730:	e8 64 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101735:	8d 87 0d da fe ff    	lea    -0x125f3(%edi),%eax
f010173b:	50                   	push   %eax
f010173c:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0101742:	50                   	push   %eax
f0101743:	68 85 02 00 00       	push   $0x285
f0101748:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010174e:	50                   	push   %eax
f010174f:	89 fb                	mov    %edi,%ebx
f0101751:	e8 43 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101756:	8d 87 2a da fe ff    	lea    -0x125d6(%edi),%eax
f010175c:	50                   	push   %eax
f010175d:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0101763:	50                   	push   %eax
f0101764:	68 86 02 00 00       	push   $0x286
f0101769:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010176f:	50                   	push   %eax
f0101770:	89 fb                	mov    %edi,%ebx
f0101772:	e8 22 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101777:	8d 87 47 da fe ff    	lea    -0x125b9(%edi),%eax
f010177d:	50                   	push   %eax
f010177e:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0101784:	50                   	push   %eax
f0101785:	68 87 02 00 00       	push   $0x287
f010178a:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0101790:	50                   	push   %eax
f0101791:	89 fb                	mov    %edi,%ebx
f0101793:	e8 01 e9 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101798:	8d 87 64 da fe ff    	lea    -0x1259c(%edi),%eax
f010179e:	50                   	push   %eax
f010179f:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01017a5:	50                   	push   %eax
f01017a6:	68 8e 02 00 00       	push   $0x28e
f01017ab:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01017b1:	50                   	push   %eax
f01017b2:	89 fb                	mov    %edi,%ebx
f01017b4:	e8 e0 e8 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01017b9:	8d 87 b9 d9 fe ff    	lea    -0x12647(%edi),%eax
f01017bf:	50                   	push   %eax
f01017c0:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01017c6:	50                   	push   %eax
f01017c7:	68 95 02 00 00       	push   $0x295
f01017cc:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01017d2:	50                   	push   %eax
f01017d3:	89 fb                	mov    %edi,%ebx
f01017d5:	e8 bf e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01017da:	8d 87 cf d9 fe ff    	lea    -0x12631(%edi),%eax
f01017e0:	50                   	push   %eax
f01017e1:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01017e7:	50                   	push   %eax
f01017e8:	68 96 02 00 00       	push   $0x296
f01017ed:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01017f3:	50                   	push   %eax
f01017f4:	89 fb                	mov    %edi,%ebx
f01017f6:	e8 9e e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01017fb:	8d 87 e5 d9 fe ff    	lea    -0x1261b(%edi),%eax
f0101801:	50                   	push   %eax
f0101802:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0101808:	50                   	push   %eax
f0101809:	68 97 02 00 00       	push   $0x297
f010180e:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0101814:	50                   	push   %eax
f0101815:	89 fb                	mov    %edi,%ebx
f0101817:	e8 7d e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010181c:	8d 87 fb d9 fe ff    	lea    -0x12605(%edi),%eax
f0101822:	50                   	push   %eax
f0101823:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0101829:	50                   	push   %eax
f010182a:	68 99 02 00 00       	push   $0x299
f010182f:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0101835:	50                   	push   %eax
f0101836:	89 fb                	mov    %edi,%ebx
f0101838:	e8 5c e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010183d:	8d 87 fc d2 fe ff    	lea    -0x12d04(%edi),%eax
f0101843:	50                   	push   %eax
f0101844:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010184a:	50                   	push   %eax
f010184b:	68 9a 02 00 00       	push   $0x29a
f0101850:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0101856:	50                   	push   %eax
f0101857:	89 fb                	mov    %edi,%ebx
f0101859:	e8 3b e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010185e:	8d 87 64 da fe ff    	lea    -0x1259c(%edi),%eax
f0101864:	50                   	push   %eax
f0101865:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010186b:	50                   	push   %eax
f010186c:	68 9b 02 00 00       	push   $0x29b
f0101871:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0101877:	50                   	push   %eax
f0101878:	89 fb                	mov    %edi,%ebx
f010187a:	e8 1a e8 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010187f:	50                   	push   %eax
f0101880:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f0101886:	50                   	push   %eax
f0101887:	6a 59                	push   $0x59
f0101889:	8d 87 f4 d8 fe ff    	lea    -0x1270c(%edi),%eax
f010188f:	50                   	push   %eax
f0101890:	89 fb                	mov    %edi,%ebx
f0101892:	e8 02 e8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101897:	8d 87 73 da fe ff    	lea    -0x1258d(%edi),%eax
f010189d:	50                   	push   %eax
f010189e:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01018a4:	50                   	push   %eax
f01018a5:	68 a0 02 00 00       	push   $0x2a0
f01018aa:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01018b0:	50                   	push   %eax
f01018b1:	e8 e3 e7 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f01018b6:	8d 87 91 da fe ff    	lea    -0x1256f(%edi),%eax
f01018bc:	50                   	push   %eax
f01018bd:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01018c3:	50                   	push   %eax
f01018c4:	68 a1 02 00 00       	push   $0x2a1
f01018c9:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01018cf:	50                   	push   %eax
f01018d0:	e8 c4 e7 ff ff       	call   f0100099 <_panic>
f01018d5:	52                   	push   %edx
f01018d6:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f01018dc:	50                   	push   %eax
f01018dd:	6a 59                	push   $0x59
f01018df:	8d 87 f4 d8 fe ff    	lea    -0x1270c(%edi),%eax
f01018e5:	50                   	push   %eax
f01018e6:	e8 ae e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f01018eb:	8d 87 a1 da fe ff    	lea    -0x1255f(%edi),%eax
f01018f1:	50                   	push   %eax
f01018f2:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01018f8:	50                   	push   %eax
f01018f9:	68 a4 02 00 00       	push   $0x2a4
f01018fe:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0101904:	50                   	push   %eax
f0101905:	89 fb                	mov    %edi,%ebx
f0101907:	e8 8d e7 ff ff       	call   f0100099 <_panic>
		--nfree;
f010190c:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010190f:	8b 00                	mov    (%eax),%eax
f0101911:	85 c0                	test   %eax,%eax
f0101913:	75 f7                	jne    f010190c <mem_init+0x613>
	assert(nfree == 0);
f0101915:	85 f6                	test   %esi,%esi
f0101917:	0f 85 69 07 00 00    	jne    f0102086 <mem_init+0xd8d>
	cprintf("check_page_alloc() succeeded!\n");
f010191d:	83 ec 0c             	sub    $0xc,%esp
f0101920:	8d 87 1c d3 fe ff    	lea    -0x12ce4(%edi),%eax
f0101926:	50                   	push   %eax
f0101927:	89 fb                	mov    %edi,%ebx
f0101929:	e8 00 16 00 00       	call   f0102f2e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010192e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101935:	e8 ab f6 ff ff       	call   f0100fe5 <page_alloc>
f010193a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010193d:	83 c4 10             	add    $0x10,%esp
f0101940:	85 c0                	test   %eax,%eax
f0101942:	0f 84 5f 07 00 00    	je     f01020a7 <mem_init+0xdae>
	assert((pp1 = page_alloc(0)));
f0101948:	83 ec 0c             	sub    $0xc,%esp
f010194b:	6a 00                	push   $0x0
f010194d:	e8 93 f6 ff ff       	call   f0100fe5 <page_alloc>
f0101952:	89 c6                	mov    %eax,%esi
f0101954:	83 c4 10             	add    $0x10,%esp
f0101957:	85 c0                	test   %eax,%eax
f0101959:	0f 84 67 07 00 00    	je     f01020c6 <mem_init+0xdcd>
	assert((pp2 = page_alloc(0)));
f010195f:	83 ec 0c             	sub    $0xc,%esp
f0101962:	6a 00                	push   $0x0
f0101964:	e8 7c f6 ff ff       	call   f0100fe5 <page_alloc>
f0101969:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010196c:	83 c4 10             	add    $0x10,%esp
f010196f:	85 c0                	test   %eax,%eax
f0101971:	0f 84 6e 07 00 00    	je     f01020e5 <mem_init+0xdec>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101977:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f010197a:	0f 84 84 07 00 00    	je     f0102104 <mem_init+0xe0b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101980:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101983:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101986:	0f 84 97 07 00 00    	je     f0102123 <mem_init+0xe2a>
f010198c:	39 c6                	cmp    %eax,%esi
f010198e:	0f 84 8f 07 00 00    	je     f0102123 <mem_init+0xe2a>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101994:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f010199a:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f010199d:	c7 87 90 1f 00 00 00 	movl   $0x0,0x1f90(%edi)
f01019a4:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019a7:	83 ec 0c             	sub    $0xc,%esp
f01019aa:	6a 00                	push   $0x0
f01019ac:	e8 34 f6 ff ff       	call   f0100fe5 <page_alloc>
f01019b1:	83 c4 10             	add    $0x10,%esp
f01019b4:	85 c0                	test   %eax,%eax
f01019b6:	0f 85 88 07 00 00    	jne    f0102144 <mem_init+0xe4b>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019bc:	83 ec 04             	sub    $0x4,%esp
f01019bf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019c2:	50                   	push   %eax
f01019c3:	6a 00                	push   $0x0
f01019c5:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f01019cb:	ff 30                	pushl  (%eax)
f01019cd:	e8 fc f7 ff ff       	call   f01011ce <page_lookup>
f01019d2:	83 c4 10             	add    $0x10,%esp
f01019d5:	85 c0                	test   %eax,%eax
f01019d7:	0f 85 86 07 00 00    	jne    f0102163 <mem_init+0xe6a>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019dd:	6a 02                	push   $0x2
f01019df:	6a 00                	push   $0x0
f01019e1:	56                   	push   %esi
f01019e2:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f01019e8:	ff 30                	pushl  (%eax)
f01019ea:	e8 8c f8 ff ff       	call   f010127b <page_insert>
f01019ef:	83 c4 10             	add    $0x10,%esp
f01019f2:	85 c0                	test   %eax,%eax
f01019f4:	0f 89 88 07 00 00    	jns    f0102182 <mem_init+0xe89>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019fa:	83 ec 0c             	sub    $0xc,%esp
f01019fd:	ff 75 d0             	pushl  -0x30(%ebp)
f0101a00:	e8 68 f6 ff ff       	call   f010106d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a05:	6a 02                	push   $0x2
f0101a07:	6a 00                	push   $0x0
f0101a09:	56                   	push   %esi
f0101a0a:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a10:	ff 30                	pushl  (%eax)
f0101a12:	e8 64 f8 ff ff       	call   f010127b <page_insert>
f0101a17:	83 c4 20             	add    $0x20,%esp
f0101a1a:	85 c0                	test   %eax,%eax
f0101a1c:	0f 85 7f 07 00 00    	jne    f01021a1 <mem_init+0xea8>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a22:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a28:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101a2a:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101a30:	8b 08                	mov    (%eax),%ecx
f0101a32:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101a35:	8b 13                	mov    (%ebx),%edx
f0101a37:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a3d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a40:	29 c8                	sub    %ecx,%eax
f0101a42:	c1 f8 03             	sar    $0x3,%eax
f0101a45:	c1 e0 0c             	shl    $0xc,%eax
f0101a48:	39 c2                	cmp    %eax,%edx
f0101a4a:	0f 85 70 07 00 00    	jne    f01021c0 <mem_init+0xec7>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a50:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a55:	89 d8                	mov    %ebx,%eax
f0101a57:	e8 9a f0 ff ff       	call   f0100af6 <check_va2pa>
f0101a5c:	89 f2                	mov    %esi,%edx
f0101a5e:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a61:	c1 fa 03             	sar    $0x3,%edx
f0101a64:	c1 e2 0c             	shl    $0xc,%edx
f0101a67:	39 d0                	cmp    %edx,%eax
f0101a69:	0f 85 72 07 00 00    	jne    f01021e1 <mem_init+0xee8>
	assert(pp1->pp_ref == 1);
f0101a6f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a74:	0f 85 88 07 00 00    	jne    f0102202 <mem_init+0xf09>
	assert(pp0->pp_ref == 1);
f0101a7a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a7d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a82:	0f 85 9b 07 00 00    	jne    f0102223 <mem_init+0xf2a>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a88:	6a 02                	push   $0x2
f0101a8a:	68 00 10 00 00       	push   $0x1000
f0101a8f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a92:	53                   	push   %ebx
f0101a93:	e8 e3 f7 ff ff       	call   f010127b <page_insert>
f0101a98:	83 c4 10             	add    $0x10,%esp
f0101a9b:	85 c0                	test   %eax,%eax
f0101a9d:	0f 85 a1 07 00 00    	jne    f0102244 <mem_init+0xf4b>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101aa3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aa8:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101aae:	8b 00                	mov    (%eax),%eax
f0101ab0:	e8 41 f0 ff ff       	call   f0100af6 <check_va2pa>
f0101ab5:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101abb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101abe:	2b 0a                	sub    (%edx),%ecx
f0101ac0:	89 ca                	mov    %ecx,%edx
f0101ac2:	c1 fa 03             	sar    $0x3,%edx
f0101ac5:	c1 e2 0c             	shl    $0xc,%edx
f0101ac8:	39 d0                	cmp    %edx,%eax
f0101aca:	0f 85 95 07 00 00    	jne    f0102265 <mem_init+0xf6c>
	assert(pp2->pp_ref == 1);
f0101ad0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ad3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ad8:	0f 85 a8 07 00 00    	jne    f0102286 <mem_init+0xf8d>

	// should be no free memory
	assert(!page_alloc(0));
f0101ade:	83 ec 0c             	sub    $0xc,%esp
f0101ae1:	6a 00                	push   $0x0
f0101ae3:	e8 fd f4 ff ff       	call   f0100fe5 <page_alloc>
f0101ae8:	83 c4 10             	add    $0x10,%esp
f0101aeb:	85 c0                	test   %eax,%eax
f0101aed:	0f 85 b4 07 00 00    	jne    f01022a7 <mem_init+0xfae>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101af3:	6a 02                	push   $0x2
f0101af5:	68 00 10 00 00       	push   $0x1000
f0101afa:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101afd:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b03:	ff 30                	pushl  (%eax)
f0101b05:	e8 71 f7 ff ff       	call   f010127b <page_insert>
f0101b0a:	83 c4 10             	add    $0x10,%esp
f0101b0d:	85 c0                	test   %eax,%eax
f0101b0f:	0f 85 b3 07 00 00    	jne    f01022c8 <mem_init+0xfcf>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b15:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b1a:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b20:	8b 00                	mov    (%eax),%eax
f0101b22:	e8 cf ef ff ff       	call   f0100af6 <check_va2pa>
f0101b27:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101b2d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b30:	2b 0a                	sub    (%edx),%ecx
f0101b32:	89 ca                	mov    %ecx,%edx
f0101b34:	c1 fa 03             	sar    $0x3,%edx
f0101b37:	c1 e2 0c             	shl    $0xc,%edx
f0101b3a:	39 d0                	cmp    %edx,%eax
f0101b3c:	0f 85 a7 07 00 00    	jne    f01022e9 <mem_init+0xff0>
	assert(pp2->pp_ref == 1);
f0101b42:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b45:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b4a:	0f 85 ba 07 00 00    	jne    f010230a <mem_init+0x1011>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b50:	83 ec 0c             	sub    $0xc,%esp
f0101b53:	6a 00                	push   $0x0
f0101b55:	e8 8b f4 ff ff       	call   f0100fe5 <page_alloc>
f0101b5a:	83 c4 10             	add    $0x10,%esp
f0101b5d:	85 c0                	test   %eax,%eax
f0101b5f:	0f 85 c6 07 00 00    	jne    f010232b <mem_init+0x1032>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b65:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b6b:	8b 10                	mov    (%eax),%edx
f0101b6d:	8b 02                	mov    (%edx),%eax
f0101b6f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101b74:	89 c3                	mov    %eax,%ebx
f0101b76:	c1 eb 0c             	shr    $0xc,%ebx
f0101b79:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f0101b7f:	3b 19                	cmp    (%ecx),%ebx
f0101b81:	0f 83 c5 07 00 00    	jae    f010234c <mem_init+0x1053>
	return (void *)(pa + KERNBASE);
f0101b87:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b8c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b8f:	83 ec 04             	sub    $0x4,%esp
f0101b92:	6a 00                	push   $0x0
f0101b94:	68 00 10 00 00       	push   $0x1000
f0101b99:	52                   	push   %edx
f0101b9a:	e8 46 f5 ff ff       	call   f01010e5 <pgdir_walk>
f0101b9f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101ba2:	8d 51 04             	lea    0x4(%ecx),%edx
f0101ba5:	83 c4 10             	add    $0x10,%esp
f0101ba8:	39 d0                	cmp    %edx,%eax
f0101baa:	0f 85 b7 07 00 00    	jne    f0102367 <mem_init+0x106e>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101bb0:	6a 06                	push   $0x6
f0101bb2:	68 00 10 00 00       	push   $0x1000
f0101bb7:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bba:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101bc0:	ff 30                	pushl  (%eax)
f0101bc2:	e8 b4 f6 ff ff       	call   f010127b <page_insert>
f0101bc7:	83 c4 10             	add    $0x10,%esp
f0101bca:	85 c0                	test   %eax,%eax
f0101bcc:	0f 85 b6 07 00 00    	jne    f0102388 <mem_init+0x108f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bd2:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101bd8:	8b 18                	mov    (%eax),%ebx
f0101bda:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bdf:	89 d8                	mov    %ebx,%eax
f0101be1:	e8 10 ef ff ff       	call   f0100af6 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101be6:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101bec:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bef:	2b 0a                	sub    (%edx),%ecx
f0101bf1:	89 ca                	mov    %ecx,%edx
f0101bf3:	c1 fa 03             	sar    $0x3,%edx
f0101bf6:	c1 e2 0c             	shl    $0xc,%edx
f0101bf9:	39 d0                	cmp    %edx,%eax
f0101bfb:	0f 85 a8 07 00 00    	jne    f01023a9 <mem_init+0x10b0>
	assert(pp2->pp_ref == 1);
f0101c01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c04:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c09:	0f 85 bb 07 00 00    	jne    f01023ca <mem_init+0x10d1>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c0f:	83 ec 04             	sub    $0x4,%esp
f0101c12:	6a 00                	push   $0x0
f0101c14:	68 00 10 00 00       	push   $0x1000
f0101c19:	53                   	push   %ebx
f0101c1a:	e8 c6 f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c1f:	83 c4 10             	add    $0x10,%esp
f0101c22:	f6 00 04             	testb  $0x4,(%eax)
f0101c25:	0f 84 c0 07 00 00    	je     f01023eb <mem_init+0x10f2>
	assert(kern_pgdir[0] & PTE_U);
f0101c2b:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c31:	8b 00                	mov    (%eax),%eax
f0101c33:	f6 00 04             	testb  $0x4,(%eax)
f0101c36:	0f 84 d0 07 00 00    	je     f010240c <mem_init+0x1113>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c3c:	6a 02                	push   $0x2
f0101c3e:	68 00 10 00 00       	push   $0x1000
f0101c43:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c46:	50                   	push   %eax
f0101c47:	e8 2f f6 ff ff       	call   f010127b <page_insert>
f0101c4c:	83 c4 10             	add    $0x10,%esp
f0101c4f:	85 c0                	test   %eax,%eax
f0101c51:	0f 85 d6 07 00 00    	jne    f010242d <mem_init+0x1134>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c57:	83 ec 04             	sub    $0x4,%esp
f0101c5a:	6a 00                	push   $0x0
f0101c5c:	68 00 10 00 00       	push   $0x1000
f0101c61:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c67:	ff 30                	pushl  (%eax)
f0101c69:	e8 77 f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c6e:	83 c4 10             	add    $0x10,%esp
f0101c71:	f6 00 02             	testb  $0x2,(%eax)
f0101c74:	0f 84 d4 07 00 00    	je     f010244e <mem_init+0x1155>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c7a:	83 ec 04             	sub    $0x4,%esp
f0101c7d:	6a 00                	push   $0x0
f0101c7f:	68 00 10 00 00       	push   $0x1000
f0101c84:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c8a:	ff 30                	pushl  (%eax)
f0101c8c:	e8 54 f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c91:	83 c4 10             	add    $0x10,%esp
f0101c94:	f6 00 04             	testb  $0x4,(%eax)
f0101c97:	0f 85 d2 07 00 00    	jne    f010246f <mem_init+0x1176>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c9d:	6a 02                	push   $0x2
f0101c9f:	68 00 00 40 00       	push   $0x400000
f0101ca4:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ca7:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101cad:	ff 30                	pushl  (%eax)
f0101caf:	e8 c7 f5 ff ff       	call   f010127b <page_insert>
f0101cb4:	83 c4 10             	add    $0x10,%esp
f0101cb7:	85 c0                	test   %eax,%eax
f0101cb9:	0f 89 d1 07 00 00    	jns    f0102490 <mem_init+0x1197>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101cbf:	6a 02                	push   $0x2
f0101cc1:	68 00 10 00 00       	push   $0x1000
f0101cc6:	56                   	push   %esi
f0101cc7:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101ccd:	ff 30                	pushl  (%eax)
f0101ccf:	e8 a7 f5 ff ff       	call   f010127b <page_insert>
f0101cd4:	83 c4 10             	add    $0x10,%esp
f0101cd7:	85 c0                	test   %eax,%eax
f0101cd9:	0f 85 d2 07 00 00    	jne    f01024b1 <mem_init+0x11b8>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cdf:	83 ec 04             	sub    $0x4,%esp
f0101ce2:	6a 00                	push   $0x0
f0101ce4:	68 00 10 00 00       	push   $0x1000
f0101ce9:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101cef:	ff 30                	pushl  (%eax)
f0101cf1:	e8 ef f3 ff ff       	call   f01010e5 <pgdir_walk>
f0101cf6:	83 c4 10             	add    $0x10,%esp
f0101cf9:	f6 00 04             	testb  $0x4,(%eax)
f0101cfc:	0f 85 d0 07 00 00    	jne    f01024d2 <mem_init+0x11d9>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d02:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101d08:	8b 18                	mov    (%eax),%ebx
f0101d0a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d0f:	89 d8                	mov    %ebx,%eax
f0101d11:	e8 e0 ed ff ff       	call   f0100af6 <check_va2pa>
f0101d16:	89 c2                	mov    %eax,%edx
f0101d18:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d1b:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101d21:	89 f1                	mov    %esi,%ecx
f0101d23:	2b 08                	sub    (%eax),%ecx
f0101d25:	89 c8                	mov    %ecx,%eax
f0101d27:	c1 f8 03             	sar    $0x3,%eax
f0101d2a:	c1 e0 0c             	shl    $0xc,%eax
f0101d2d:	39 c2                	cmp    %eax,%edx
f0101d2f:	0f 85 be 07 00 00    	jne    f01024f3 <mem_init+0x11fa>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d35:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d3a:	89 d8                	mov    %ebx,%eax
f0101d3c:	e8 b5 ed ff ff       	call   f0100af6 <check_va2pa>
f0101d41:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d44:	0f 85 ca 07 00 00    	jne    f0102514 <mem_init+0x121b>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d4a:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101d4f:	0f 85 e0 07 00 00    	jne    f0102535 <mem_init+0x123c>
	assert(pp2->pp_ref == 0);
f0101d55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d58:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101d5d:	0f 85 f3 07 00 00    	jne    f0102556 <mem_init+0x125d>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d63:	83 ec 0c             	sub    $0xc,%esp
f0101d66:	6a 00                	push   $0x0
f0101d68:	e8 78 f2 ff ff       	call   f0100fe5 <page_alloc>
f0101d6d:	83 c4 10             	add    $0x10,%esp
f0101d70:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d73:	0f 85 fe 07 00 00    	jne    f0102577 <mem_init+0x127e>
f0101d79:	85 c0                	test   %eax,%eax
f0101d7b:	0f 84 f6 07 00 00    	je     f0102577 <mem_init+0x127e>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d81:	83 ec 08             	sub    $0x8,%esp
f0101d84:	6a 00                	push   $0x0
f0101d86:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101d8c:	ff 33                	pushl  (%ebx)
f0101d8e:	e8 ab f4 ff ff       	call   f010123e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d93:	8b 1b                	mov    (%ebx),%ebx
f0101d95:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d9a:	89 d8                	mov    %ebx,%eax
f0101d9c:	e8 55 ed ff ff       	call   f0100af6 <check_va2pa>
f0101da1:	83 c4 10             	add    $0x10,%esp
f0101da4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101da7:	0f 85 eb 07 00 00    	jne    f0102598 <mem_init+0x129f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dad:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101db2:	89 d8                	mov    %ebx,%eax
f0101db4:	e8 3d ed ff ff       	call   f0100af6 <check_va2pa>
f0101db9:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101dbf:	89 f1                	mov    %esi,%ecx
f0101dc1:	2b 0a                	sub    (%edx),%ecx
f0101dc3:	89 ca                	mov    %ecx,%edx
f0101dc5:	c1 fa 03             	sar    $0x3,%edx
f0101dc8:	c1 e2 0c             	shl    $0xc,%edx
f0101dcb:	39 d0                	cmp    %edx,%eax
f0101dcd:	0f 85 e6 07 00 00    	jne    f01025b9 <mem_init+0x12c0>
	assert(pp1->pp_ref == 1);
f0101dd3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dd8:	0f 85 fc 07 00 00    	jne    f01025da <mem_init+0x12e1>
	assert(pp2->pp_ref == 0);
f0101dde:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101de6:	0f 85 0f 08 00 00    	jne    f01025fb <mem_init+0x1302>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dec:	6a 00                	push   $0x0
f0101dee:	68 00 10 00 00       	push   $0x1000
f0101df3:	56                   	push   %esi
f0101df4:	53                   	push   %ebx
f0101df5:	e8 81 f4 ff ff       	call   f010127b <page_insert>
f0101dfa:	83 c4 10             	add    $0x10,%esp
f0101dfd:	85 c0                	test   %eax,%eax
f0101dff:	0f 85 17 08 00 00    	jne    f010261c <mem_init+0x1323>
	assert(pp1->pp_ref);
f0101e05:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e0a:	0f 84 2d 08 00 00    	je     f010263d <mem_init+0x1344>
	assert(pp1->pp_link == NULL);
f0101e10:	83 3e 00             	cmpl   $0x0,(%esi)
f0101e13:	0f 85 45 08 00 00    	jne    f010265e <mem_init+0x1365>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e19:	83 ec 08             	sub    $0x8,%esp
f0101e1c:	68 00 10 00 00       	push   $0x1000
f0101e21:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101e27:	ff 33                	pushl  (%ebx)
f0101e29:	e8 10 f4 ff ff       	call   f010123e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e2e:	8b 1b                	mov    (%ebx),%ebx
f0101e30:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e35:	89 d8                	mov    %ebx,%eax
f0101e37:	e8 ba ec ff ff       	call   f0100af6 <check_va2pa>
f0101e3c:	83 c4 10             	add    $0x10,%esp
f0101e3f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e42:	0f 85 37 08 00 00    	jne    f010267f <mem_init+0x1386>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e48:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e4d:	89 d8                	mov    %ebx,%eax
f0101e4f:	e8 a2 ec ff ff       	call   f0100af6 <check_va2pa>
f0101e54:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e57:	0f 85 43 08 00 00    	jne    f01026a0 <mem_init+0x13a7>
	assert(pp1->pp_ref == 0);
f0101e5d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e62:	0f 85 59 08 00 00    	jne    f01026c1 <mem_init+0x13c8>
	assert(pp2->pp_ref == 0);
f0101e68:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e6b:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e70:	0f 85 6c 08 00 00    	jne    f01026e2 <mem_init+0x13e9>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e76:	83 ec 0c             	sub    $0xc,%esp
f0101e79:	6a 00                	push   $0x0
f0101e7b:	e8 65 f1 ff ff       	call   f0100fe5 <page_alloc>
f0101e80:	83 c4 10             	add    $0x10,%esp
f0101e83:	85 c0                	test   %eax,%eax
f0101e85:	0f 84 78 08 00 00    	je     f0102703 <mem_init+0x140a>
f0101e8b:	39 c6                	cmp    %eax,%esi
f0101e8d:	0f 85 70 08 00 00    	jne    f0102703 <mem_init+0x140a>

	// should be no free memory
	assert(!page_alloc(0));
f0101e93:	83 ec 0c             	sub    $0xc,%esp
f0101e96:	6a 00                	push   $0x0
f0101e98:	e8 48 f1 ff ff       	call   f0100fe5 <page_alloc>
f0101e9d:	83 c4 10             	add    $0x10,%esp
f0101ea0:	85 c0                	test   %eax,%eax
f0101ea2:	0f 85 7c 08 00 00    	jne    f0102724 <mem_init+0x142b>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ea8:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101eae:	8b 08                	mov    (%eax),%ecx
f0101eb0:	8b 11                	mov    (%ecx),%edx
f0101eb2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101eb8:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101ebe:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101ec1:	2b 18                	sub    (%eax),%ebx
f0101ec3:	89 d8                	mov    %ebx,%eax
f0101ec5:	c1 f8 03             	sar    $0x3,%eax
f0101ec8:	c1 e0 0c             	shl    $0xc,%eax
f0101ecb:	39 c2                	cmp    %eax,%edx
f0101ecd:	0f 85 72 08 00 00    	jne    f0102745 <mem_init+0x144c>
	kern_pgdir[0] = 0;
f0101ed3:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101ed9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101edc:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ee1:	0f 85 7f 08 00 00    	jne    f0102766 <mem_init+0x146d>
	pp0->pp_ref = 0;
f0101ee7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101eea:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ef0:	83 ec 0c             	sub    $0xc,%esp
f0101ef3:	50                   	push   %eax
f0101ef4:	e8 74 f1 ff ff       	call   f010106d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ef9:	83 c4 0c             	add    $0xc,%esp
f0101efc:	6a 01                	push   $0x1
f0101efe:	68 00 10 40 00       	push   $0x401000
f0101f03:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101f09:	ff 33                	pushl  (%ebx)
f0101f0b:	e8 d5 f1 ff ff       	call   f01010e5 <pgdir_walk>
f0101f10:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f13:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f16:	8b 1b                	mov    (%ebx),%ebx
f0101f18:	8b 53 04             	mov    0x4(%ebx),%edx
f0101f1b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101f21:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f0101f27:	8b 09                	mov    (%ecx),%ecx
f0101f29:	89 d0                	mov    %edx,%eax
f0101f2b:	c1 e8 0c             	shr    $0xc,%eax
f0101f2e:	83 c4 10             	add    $0x10,%esp
f0101f31:	39 c8                	cmp    %ecx,%eax
f0101f33:	0f 83 4e 08 00 00    	jae    f0102787 <mem_init+0x148e>
	assert(ptep == ptep1 + PTX(va));
f0101f39:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101f3f:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101f42:	0f 85 5a 08 00 00    	jne    f01027a2 <mem_init+0x14a9>
	kern_pgdir[PDX(va)] = 0;
f0101f48:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0101f4f:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f52:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0101f58:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101f5e:	2b 18                	sub    (%eax),%ebx
f0101f60:	89 d8                	mov    %ebx,%eax
f0101f62:	c1 f8 03             	sar    $0x3,%eax
f0101f65:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101f68:	89 c2                	mov    %eax,%edx
f0101f6a:	c1 ea 0c             	shr    $0xc,%edx
f0101f6d:	39 d1                	cmp    %edx,%ecx
f0101f6f:	0f 86 4e 08 00 00    	jbe    f01027c3 <mem_init+0x14ca>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f75:	83 ec 04             	sub    $0x4,%esp
f0101f78:	68 00 10 00 00       	push   $0x1000
f0101f7d:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101f82:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f87:	50                   	push   %eax
f0101f88:	89 fb                	mov    %edi,%ebx
f0101f8a:	e8 b0 1b 00 00       	call   f0103b3f <memset>
	page_free(pp0);
f0101f8f:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f92:	89 1c 24             	mov    %ebx,(%esp)
f0101f95:	e8 d3 f0 ff ff       	call   f010106d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f9a:	83 c4 0c             	add    $0xc,%esp
f0101f9d:	6a 01                	push   $0x1
f0101f9f:	6a 00                	push   $0x0
f0101fa1:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101fa7:	ff 30                	pushl  (%eax)
f0101fa9:	e8 37 f1 ff ff       	call   f01010e5 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101fae:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101fb4:	2b 18                	sub    (%eax),%ebx
f0101fb6:	89 da                	mov    %ebx,%edx
f0101fb8:	c1 fa 03             	sar    $0x3,%edx
f0101fbb:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101fbe:	89 d1                	mov    %edx,%ecx
f0101fc0:	c1 e9 0c             	shr    $0xc,%ecx
f0101fc3:	83 c4 10             	add    $0x10,%esp
f0101fc6:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0101fcc:	3b 08                	cmp    (%eax),%ecx
f0101fce:	0f 83 07 08 00 00    	jae    f01027db <mem_init+0x14e2>
	return (void *)(pa + KERNBASE);
f0101fd4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101fda:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101fdd:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101fe3:	f6 00 01             	testb  $0x1,(%eax)
f0101fe6:	0f 85 07 08 00 00    	jne    f01027f3 <mem_init+0x14fa>
f0101fec:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101fef:	39 d0                	cmp    %edx,%eax
f0101ff1:	75 f0                	jne    f0101fe3 <mem_init+0xcea>
	kern_pgdir[0] = 0;
f0101ff3:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101ff9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ffc:	8b 00                	mov    (%eax),%eax
f0101ffe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102004:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102007:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)

	// give free list back
	page_free_list = fl;
f010200d:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0102010:	89 9f 90 1f 00 00    	mov    %ebx,0x1f90(%edi)

	// free the pages we took
	page_free(pp0);
f0102016:	83 ec 0c             	sub    $0xc,%esp
f0102019:	51                   	push   %ecx
f010201a:	e8 4e f0 ff ff       	call   f010106d <page_free>
	page_free(pp1);
f010201f:	89 34 24             	mov    %esi,(%esp)
f0102022:	e8 46 f0 ff ff       	call   f010106d <page_free>
	page_free(pp2);
f0102027:	83 c4 04             	add    $0x4,%esp
f010202a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010202d:	e8 3b f0 ff ff       	call   f010106d <page_free>

	cprintf("check_page() succeeded!\n");
f0102032:	8d 87 82 db fe ff    	lea    -0x1247e(%edi),%eax
f0102038:	89 04 24             	mov    %eax,(%esp)
f010203b:	89 fb                	mov    %edi,%ebx
f010203d:	e8 ec 0e 00 00       	call   f0102f2e <cprintf>
	pgdir = kern_pgdir;
f0102042:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102045:	8b 18                	mov    (%eax),%ebx
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102047:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f010204d:	8b 00                	mov    (%eax),%eax
f010204f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102052:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102059:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010205e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102061:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102067:	8b 00                	mov    (%eax),%eax
f0102069:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if ((uint32_t)kva < KERNBASE)
f010206c:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f010206f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102074:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0102077:	be 00 00 00 00       	mov    $0x0,%esi
f010207c:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f010207f:	89 c3                	mov    %eax,%ebx
f0102081:	e9 b1 07 00 00       	jmp    f0102837 <mem_init+0x153e>
	assert(nfree == 0);
f0102086:	8d 87 ab da fe ff    	lea    -0x12555(%edi),%eax
f010208c:	50                   	push   %eax
f010208d:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102093:	50                   	push   %eax
f0102094:	68 b1 02 00 00       	push   $0x2b1
f0102099:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010209f:	50                   	push   %eax
f01020a0:	89 fb                	mov    %edi,%ebx
f01020a2:	e8 f2 df ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01020a7:	8d 87 b9 d9 fe ff    	lea    -0x12647(%edi),%eax
f01020ad:	50                   	push   %eax
f01020ae:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01020b4:	50                   	push   %eax
f01020b5:	68 0a 03 00 00       	push   $0x30a
f01020ba:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01020c0:	50                   	push   %eax
f01020c1:	e8 d3 df ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01020c6:	8d 87 cf d9 fe ff    	lea    -0x12631(%edi),%eax
f01020cc:	50                   	push   %eax
f01020cd:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01020d3:	50                   	push   %eax
f01020d4:	68 0b 03 00 00       	push   $0x30b
f01020d9:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01020df:	50                   	push   %eax
f01020e0:	e8 b4 df ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01020e5:	8d 87 e5 d9 fe ff    	lea    -0x1261b(%edi),%eax
f01020eb:	50                   	push   %eax
f01020ec:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01020f2:	50                   	push   %eax
f01020f3:	68 0c 03 00 00       	push   $0x30c
f01020f8:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01020fe:	50                   	push   %eax
f01020ff:	e8 95 df ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0102104:	8d 87 fb d9 fe ff    	lea    -0x12605(%edi),%eax
f010210a:	50                   	push   %eax
f010210b:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102111:	50                   	push   %eax
f0102112:	68 0f 03 00 00       	push   $0x30f
f0102117:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010211d:	50                   	push   %eax
f010211e:	e8 76 df ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102123:	8d 87 fc d2 fe ff    	lea    -0x12d04(%edi),%eax
f0102129:	50                   	push   %eax
f010212a:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102130:	50                   	push   %eax
f0102131:	68 10 03 00 00       	push   $0x310
f0102136:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010213c:	50                   	push   %eax
f010213d:	89 fb                	mov    %edi,%ebx
f010213f:	e8 55 df ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102144:	8d 87 64 da fe ff    	lea    -0x1259c(%edi),%eax
f010214a:	50                   	push   %eax
f010214b:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102151:	50                   	push   %eax
f0102152:	68 17 03 00 00       	push   $0x317
f0102157:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010215d:	50                   	push   %eax
f010215e:	e8 36 df ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102163:	8d 87 3c d3 fe ff    	lea    -0x12cc4(%edi),%eax
f0102169:	50                   	push   %eax
f010216a:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102170:	50                   	push   %eax
f0102171:	68 1a 03 00 00       	push   $0x31a
f0102176:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010217c:	50                   	push   %eax
f010217d:	e8 17 df ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102182:	8d 87 74 d3 fe ff    	lea    -0x12c8c(%edi),%eax
f0102188:	50                   	push   %eax
f0102189:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010218f:	50                   	push   %eax
f0102190:	68 1d 03 00 00       	push   $0x31d
f0102195:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010219b:	50                   	push   %eax
f010219c:	e8 f8 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01021a1:	8d 87 a4 d3 fe ff    	lea    -0x12c5c(%edi),%eax
f01021a7:	50                   	push   %eax
f01021a8:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01021ae:	50                   	push   %eax
f01021af:	68 21 03 00 00       	push   $0x321
f01021b4:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01021ba:	50                   	push   %eax
f01021bb:	e8 d9 de ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021c0:	8d 87 d4 d3 fe ff    	lea    -0x12c2c(%edi),%eax
f01021c6:	50                   	push   %eax
f01021c7:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01021cd:	50                   	push   %eax
f01021ce:	68 22 03 00 00       	push   $0x322
f01021d3:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01021d9:	50                   	push   %eax
f01021da:	89 fb                	mov    %edi,%ebx
f01021dc:	e8 b8 de ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01021e1:	8d 87 fc d3 fe ff    	lea    -0x12c04(%edi),%eax
f01021e7:	50                   	push   %eax
f01021e8:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01021ee:	50                   	push   %eax
f01021ef:	68 23 03 00 00       	push   $0x323
f01021f4:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01021fa:	50                   	push   %eax
f01021fb:	89 fb                	mov    %edi,%ebx
f01021fd:	e8 97 de ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102202:	8d 87 b6 da fe ff    	lea    -0x1254a(%edi),%eax
f0102208:	50                   	push   %eax
f0102209:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010220f:	50                   	push   %eax
f0102210:	68 24 03 00 00       	push   $0x324
f0102215:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010221b:	50                   	push   %eax
f010221c:	89 fb                	mov    %edi,%ebx
f010221e:	e8 76 de ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102223:	8d 87 c7 da fe ff    	lea    -0x12539(%edi),%eax
f0102229:	50                   	push   %eax
f010222a:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102230:	50                   	push   %eax
f0102231:	68 25 03 00 00       	push   $0x325
f0102236:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010223c:	50                   	push   %eax
f010223d:	89 fb                	mov    %edi,%ebx
f010223f:	e8 55 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102244:	8d 87 2c d4 fe ff    	lea    -0x12bd4(%edi),%eax
f010224a:	50                   	push   %eax
f010224b:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102251:	50                   	push   %eax
f0102252:	68 28 03 00 00       	push   $0x328
f0102257:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010225d:	50                   	push   %eax
f010225e:	89 fb                	mov    %edi,%ebx
f0102260:	e8 34 de ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102265:	8d 87 68 d4 fe ff    	lea    -0x12b98(%edi),%eax
f010226b:	50                   	push   %eax
f010226c:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102272:	50                   	push   %eax
f0102273:	68 29 03 00 00       	push   $0x329
f0102278:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010227e:	50                   	push   %eax
f010227f:	89 fb                	mov    %edi,%ebx
f0102281:	e8 13 de ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102286:	8d 87 d8 da fe ff    	lea    -0x12528(%edi),%eax
f010228c:	50                   	push   %eax
f010228d:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102293:	50                   	push   %eax
f0102294:	68 2a 03 00 00       	push   $0x32a
f0102299:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010229f:	50                   	push   %eax
f01022a0:	89 fb                	mov    %edi,%ebx
f01022a2:	e8 f2 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01022a7:	8d 87 64 da fe ff    	lea    -0x1259c(%edi),%eax
f01022ad:	50                   	push   %eax
f01022ae:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01022b4:	50                   	push   %eax
f01022b5:	68 2d 03 00 00       	push   $0x32d
f01022ba:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01022c0:	50                   	push   %eax
f01022c1:	89 fb                	mov    %edi,%ebx
f01022c3:	e8 d1 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022c8:	8d 87 2c d4 fe ff    	lea    -0x12bd4(%edi),%eax
f01022ce:	50                   	push   %eax
f01022cf:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01022d5:	50                   	push   %eax
f01022d6:	68 30 03 00 00       	push   $0x330
f01022db:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01022e1:	50                   	push   %eax
f01022e2:	89 fb                	mov    %edi,%ebx
f01022e4:	e8 b0 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01022e9:	8d 87 68 d4 fe ff    	lea    -0x12b98(%edi),%eax
f01022ef:	50                   	push   %eax
f01022f0:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01022f6:	50                   	push   %eax
f01022f7:	68 31 03 00 00       	push   $0x331
f01022fc:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102302:	50                   	push   %eax
f0102303:	89 fb                	mov    %edi,%ebx
f0102305:	e8 8f dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010230a:	8d 87 d8 da fe ff    	lea    -0x12528(%edi),%eax
f0102310:	50                   	push   %eax
f0102311:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102317:	50                   	push   %eax
f0102318:	68 32 03 00 00       	push   $0x332
f010231d:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102323:	50                   	push   %eax
f0102324:	89 fb                	mov    %edi,%ebx
f0102326:	e8 6e dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010232b:	8d 87 64 da fe ff    	lea    -0x1259c(%edi),%eax
f0102331:	50                   	push   %eax
f0102332:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102338:	50                   	push   %eax
f0102339:	68 36 03 00 00       	push   $0x336
f010233e:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102344:	50                   	push   %eax
f0102345:	89 fb                	mov    %edi,%ebx
f0102347:	e8 4d dd ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010234c:	50                   	push   %eax
f010234d:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f0102353:	50                   	push   %eax
f0102354:	68 39 03 00 00       	push   $0x339
f0102359:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010235f:	50                   	push   %eax
f0102360:	89 fb                	mov    %edi,%ebx
f0102362:	e8 32 dd ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102367:	8d 87 98 d4 fe ff    	lea    -0x12b68(%edi),%eax
f010236d:	50                   	push   %eax
f010236e:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102374:	50                   	push   %eax
f0102375:	68 3a 03 00 00       	push   $0x33a
f010237a:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102380:	50                   	push   %eax
f0102381:	89 fb                	mov    %edi,%ebx
f0102383:	e8 11 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102388:	8d 87 d8 d4 fe ff    	lea    -0x12b28(%edi),%eax
f010238e:	50                   	push   %eax
f010238f:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102395:	50                   	push   %eax
f0102396:	68 3d 03 00 00       	push   $0x33d
f010239b:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01023a1:	50                   	push   %eax
f01023a2:	89 fb                	mov    %edi,%ebx
f01023a4:	e8 f0 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023a9:	8d 87 68 d4 fe ff    	lea    -0x12b98(%edi),%eax
f01023af:	50                   	push   %eax
f01023b0:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01023b6:	50                   	push   %eax
f01023b7:	68 3e 03 00 00       	push   $0x33e
f01023bc:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01023c2:	50                   	push   %eax
f01023c3:	89 fb                	mov    %edi,%ebx
f01023c5:	e8 cf dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01023ca:	8d 87 d8 da fe ff    	lea    -0x12528(%edi),%eax
f01023d0:	50                   	push   %eax
f01023d1:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01023d7:	50                   	push   %eax
f01023d8:	68 3f 03 00 00       	push   $0x33f
f01023dd:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01023e3:	50                   	push   %eax
f01023e4:	89 fb                	mov    %edi,%ebx
f01023e6:	e8 ae dc ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01023eb:	8d 87 18 d5 fe ff    	lea    -0x12ae8(%edi),%eax
f01023f1:	50                   	push   %eax
f01023f2:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01023f8:	50                   	push   %eax
f01023f9:	68 40 03 00 00       	push   $0x340
f01023fe:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102404:	50                   	push   %eax
f0102405:	89 fb                	mov    %edi,%ebx
f0102407:	e8 8d dc ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010240c:	8d 87 e9 da fe ff    	lea    -0x12517(%edi),%eax
f0102412:	50                   	push   %eax
f0102413:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102419:	50                   	push   %eax
f010241a:	68 41 03 00 00       	push   $0x341
f010241f:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102425:	50                   	push   %eax
f0102426:	89 fb                	mov    %edi,%ebx
f0102428:	e8 6c dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010242d:	8d 87 2c d4 fe ff    	lea    -0x12bd4(%edi),%eax
f0102433:	50                   	push   %eax
f0102434:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010243a:	50                   	push   %eax
f010243b:	68 44 03 00 00       	push   $0x344
f0102440:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102446:	50                   	push   %eax
f0102447:	89 fb                	mov    %edi,%ebx
f0102449:	e8 4b dc ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010244e:	8d 87 4c d5 fe ff    	lea    -0x12ab4(%edi),%eax
f0102454:	50                   	push   %eax
f0102455:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010245b:	50                   	push   %eax
f010245c:	68 45 03 00 00       	push   $0x345
f0102461:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102467:	50                   	push   %eax
f0102468:	89 fb                	mov    %edi,%ebx
f010246a:	e8 2a dc ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010246f:	8d 87 80 d5 fe ff    	lea    -0x12a80(%edi),%eax
f0102475:	50                   	push   %eax
f0102476:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010247c:	50                   	push   %eax
f010247d:	68 46 03 00 00       	push   $0x346
f0102482:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102488:	50                   	push   %eax
f0102489:	89 fb                	mov    %edi,%ebx
f010248b:	e8 09 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102490:	8d 87 b8 d5 fe ff    	lea    -0x12a48(%edi),%eax
f0102496:	50                   	push   %eax
f0102497:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010249d:	50                   	push   %eax
f010249e:	68 49 03 00 00       	push   $0x349
f01024a3:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01024a9:	50                   	push   %eax
f01024aa:	89 fb                	mov    %edi,%ebx
f01024ac:	e8 e8 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01024b1:	8d 87 f0 d5 fe ff    	lea    -0x12a10(%edi),%eax
f01024b7:	50                   	push   %eax
f01024b8:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01024be:	50                   	push   %eax
f01024bf:	68 4c 03 00 00       	push   $0x34c
f01024c4:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01024ca:	50                   	push   %eax
f01024cb:	89 fb                	mov    %edi,%ebx
f01024cd:	e8 c7 db ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01024d2:	8d 87 80 d5 fe ff    	lea    -0x12a80(%edi),%eax
f01024d8:	50                   	push   %eax
f01024d9:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01024df:	50                   	push   %eax
f01024e0:	68 4d 03 00 00       	push   $0x34d
f01024e5:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01024eb:	50                   	push   %eax
f01024ec:	89 fb                	mov    %edi,%ebx
f01024ee:	e8 a6 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01024f3:	8d 87 2c d6 fe ff    	lea    -0x129d4(%edi),%eax
f01024f9:	50                   	push   %eax
f01024fa:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102500:	50                   	push   %eax
f0102501:	68 50 03 00 00       	push   $0x350
f0102506:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010250c:	50                   	push   %eax
f010250d:	89 fb                	mov    %edi,%ebx
f010250f:	e8 85 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102514:	8d 87 58 d6 fe ff    	lea    -0x129a8(%edi),%eax
f010251a:	50                   	push   %eax
f010251b:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102521:	50                   	push   %eax
f0102522:	68 51 03 00 00       	push   $0x351
f0102527:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010252d:	50                   	push   %eax
f010252e:	89 fb                	mov    %edi,%ebx
f0102530:	e8 64 db ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f0102535:	8d 87 ff da fe ff    	lea    -0x12501(%edi),%eax
f010253b:	50                   	push   %eax
f010253c:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102542:	50                   	push   %eax
f0102543:	68 53 03 00 00       	push   $0x353
f0102548:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010254e:	50                   	push   %eax
f010254f:	89 fb                	mov    %edi,%ebx
f0102551:	e8 43 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102556:	8d 87 10 db fe ff    	lea    -0x124f0(%edi),%eax
f010255c:	50                   	push   %eax
f010255d:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102563:	50                   	push   %eax
f0102564:	68 54 03 00 00       	push   $0x354
f0102569:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010256f:	50                   	push   %eax
f0102570:	89 fb                	mov    %edi,%ebx
f0102572:	e8 22 db ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102577:	8d 87 88 d6 fe ff    	lea    -0x12978(%edi),%eax
f010257d:	50                   	push   %eax
f010257e:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102584:	50                   	push   %eax
f0102585:	68 57 03 00 00       	push   $0x357
f010258a:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102590:	50                   	push   %eax
f0102591:	89 fb                	mov    %edi,%ebx
f0102593:	e8 01 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102598:	8d 87 ac d6 fe ff    	lea    -0x12954(%edi),%eax
f010259e:	50                   	push   %eax
f010259f:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01025a5:	50                   	push   %eax
f01025a6:	68 5b 03 00 00       	push   $0x35b
f01025ab:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01025b1:	50                   	push   %eax
f01025b2:	89 fb                	mov    %edi,%ebx
f01025b4:	e8 e0 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025b9:	8d 87 58 d6 fe ff    	lea    -0x129a8(%edi),%eax
f01025bf:	50                   	push   %eax
f01025c0:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01025c6:	50                   	push   %eax
f01025c7:	68 5c 03 00 00       	push   $0x35c
f01025cc:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01025d2:	50                   	push   %eax
f01025d3:	89 fb                	mov    %edi,%ebx
f01025d5:	e8 bf da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01025da:	8d 87 b6 da fe ff    	lea    -0x1254a(%edi),%eax
f01025e0:	50                   	push   %eax
f01025e1:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01025e7:	50                   	push   %eax
f01025e8:	68 5d 03 00 00       	push   $0x35d
f01025ed:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01025f3:	50                   	push   %eax
f01025f4:	89 fb                	mov    %edi,%ebx
f01025f6:	e8 9e da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01025fb:	8d 87 10 db fe ff    	lea    -0x124f0(%edi),%eax
f0102601:	50                   	push   %eax
f0102602:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102608:	50                   	push   %eax
f0102609:	68 5e 03 00 00       	push   $0x35e
f010260e:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102614:	50                   	push   %eax
f0102615:	89 fb                	mov    %edi,%ebx
f0102617:	e8 7d da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010261c:	8d 87 d0 d6 fe ff    	lea    -0x12930(%edi),%eax
f0102622:	50                   	push   %eax
f0102623:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102629:	50                   	push   %eax
f010262a:	68 61 03 00 00       	push   $0x361
f010262f:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102635:	50                   	push   %eax
f0102636:	89 fb                	mov    %edi,%ebx
f0102638:	e8 5c da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f010263d:	8d 87 21 db fe ff    	lea    -0x124df(%edi),%eax
f0102643:	50                   	push   %eax
f0102644:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010264a:	50                   	push   %eax
f010264b:	68 62 03 00 00       	push   $0x362
f0102650:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102656:	50                   	push   %eax
f0102657:	89 fb                	mov    %edi,%ebx
f0102659:	e8 3b da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f010265e:	8d 87 2d db fe ff    	lea    -0x124d3(%edi),%eax
f0102664:	50                   	push   %eax
f0102665:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010266b:	50                   	push   %eax
f010266c:	68 63 03 00 00       	push   $0x363
f0102671:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102677:	50                   	push   %eax
f0102678:	89 fb                	mov    %edi,%ebx
f010267a:	e8 1a da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010267f:	8d 87 ac d6 fe ff    	lea    -0x12954(%edi),%eax
f0102685:	50                   	push   %eax
f0102686:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f010268c:	50                   	push   %eax
f010268d:	68 67 03 00 00       	push   $0x367
f0102692:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102698:	50                   	push   %eax
f0102699:	89 fb                	mov    %edi,%ebx
f010269b:	e8 f9 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01026a0:	8d 87 08 d7 fe ff    	lea    -0x128f8(%edi),%eax
f01026a6:	50                   	push   %eax
f01026a7:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01026ad:	50                   	push   %eax
f01026ae:	68 68 03 00 00       	push   $0x368
f01026b3:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01026b9:	50                   	push   %eax
f01026ba:	89 fb                	mov    %edi,%ebx
f01026bc:	e8 d8 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f01026c1:	8d 87 42 db fe ff    	lea    -0x124be(%edi),%eax
f01026c7:	50                   	push   %eax
f01026c8:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01026ce:	50                   	push   %eax
f01026cf:	68 69 03 00 00       	push   $0x369
f01026d4:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01026da:	50                   	push   %eax
f01026db:	89 fb                	mov    %edi,%ebx
f01026dd:	e8 b7 d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01026e2:	8d 87 10 db fe ff    	lea    -0x124f0(%edi),%eax
f01026e8:	50                   	push   %eax
f01026e9:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01026ef:	50                   	push   %eax
f01026f0:	68 6a 03 00 00       	push   $0x36a
f01026f5:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01026fb:	50                   	push   %eax
f01026fc:	89 fb                	mov    %edi,%ebx
f01026fe:	e8 96 d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102703:	8d 87 30 d7 fe ff    	lea    -0x128d0(%edi),%eax
f0102709:	50                   	push   %eax
f010270a:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102710:	50                   	push   %eax
f0102711:	68 6d 03 00 00       	push   $0x36d
f0102716:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010271c:	50                   	push   %eax
f010271d:	89 fb                	mov    %edi,%ebx
f010271f:	e8 75 d9 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102724:	8d 87 64 da fe ff    	lea    -0x1259c(%edi),%eax
f010272a:	50                   	push   %eax
f010272b:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102731:	50                   	push   %eax
f0102732:	68 70 03 00 00       	push   $0x370
f0102737:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010273d:	50                   	push   %eax
f010273e:	89 fb                	mov    %edi,%ebx
f0102740:	e8 54 d9 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102745:	8d 87 d4 d3 fe ff    	lea    -0x12c2c(%edi),%eax
f010274b:	50                   	push   %eax
f010274c:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102752:	50                   	push   %eax
f0102753:	68 73 03 00 00       	push   $0x373
f0102758:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010275e:	50                   	push   %eax
f010275f:	89 fb                	mov    %edi,%ebx
f0102761:	e8 33 d9 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102766:	8d 87 c7 da fe ff    	lea    -0x12539(%edi),%eax
f010276c:	50                   	push   %eax
f010276d:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102773:	50                   	push   %eax
f0102774:	68 75 03 00 00       	push   $0x375
f0102779:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010277f:	50                   	push   %eax
f0102780:	89 fb                	mov    %edi,%ebx
f0102782:	e8 12 d9 ff ff       	call   f0100099 <_panic>
f0102787:	52                   	push   %edx
f0102788:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f010278e:	50                   	push   %eax
f010278f:	68 7c 03 00 00       	push   $0x37c
f0102794:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010279a:	50                   	push   %eax
f010279b:	89 fb                	mov    %edi,%ebx
f010279d:	e8 f7 d8 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01027a2:	8d 87 53 db fe ff    	lea    -0x124ad(%edi),%eax
f01027a8:	50                   	push   %eax
f01027a9:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01027af:	50                   	push   %eax
f01027b0:	68 7d 03 00 00       	push   $0x37d
f01027b5:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01027bb:	50                   	push   %eax
f01027bc:	89 fb                	mov    %edi,%ebx
f01027be:	e8 d6 d8 ff ff       	call   f0100099 <_panic>
f01027c3:	50                   	push   %eax
f01027c4:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f01027ca:	50                   	push   %eax
f01027cb:	6a 59                	push   $0x59
f01027cd:	8d 87 f4 d8 fe ff    	lea    -0x1270c(%edi),%eax
f01027d3:	50                   	push   %eax
f01027d4:	89 fb                	mov    %edi,%ebx
f01027d6:	e8 be d8 ff ff       	call   f0100099 <_panic>
f01027db:	52                   	push   %edx
f01027dc:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f01027e2:	50                   	push   %eax
f01027e3:	6a 59                	push   $0x59
f01027e5:	8d 87 f4 d8 fe ff    	lea    -0x1270c(%edi),%eax
f01027eb:	50                   	push   %eax
f01027ec:	89 fb                	mov    %edi,%ebx
f01027ee:	e8 a6 d8 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01027f3:	8d 87 6b db fe ff    	lea    -0x12495(%edi),%eax
f01027f9:	50                   	push   %eax
f01027fa:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102800:	50                   	push   %eax
f0102801:	68 87 03 00 00       	push   $0x387
f0102806:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010280c:	50                   	push   %eax
f010280d:	89 fb                	mov    %edi,%ebx
f010280f:	e8 85 d8 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102814:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102817:	8d 87 5c d2 fe ff    	lea    -0x12da4(%edi),%eax
f010281d:	50                   	push   %eax
f010281e:	68 c9 02 00 00       	push   $0x2c9
f0102823:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102829:	50                   	push   %eax
f010282a:	89 fb                	mov    %edi,%ebx
f010282c:	e8 68 d8 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102831:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102837:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010283a:	76 3f                	jbe    f010287b <mem_init+0x1582>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010283c:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102842:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102845:	e8 ac e2 ff ff       	call   f0100af6 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010284a:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102851:	76 c1                	jbe    f0102814 <mem_init+0x151b>
f0102853:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102856:	39 d0                	cmp    %edx,%eax
f0102858:	74 d7                	je     f0102831 <mem_init+0x1538>
f010285a:	8d 87 54 d7 fe ff    	lea    -0x128ac(%edi),%eax
f0102860:	50                   	push   %eax
f0102861:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102867:	50                   	push   %eax
f0102868:	68 c9 02 00 00       	push   $0x2c9
f010286d:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102873:	50                   	push   %eax
f0102874:	89 fb                	mov    %edi,%ebx
f0102876:	e8 1e d8 ff ff       	call   f0100099 <_panic>
f010287b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010287e:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102881:	c1 e0 0c             	shl    $0xc,%eax
f0102884:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102887:	be 00 00 00 00       	mov    $0x0,%esi
f010288c:	eb 17                	jmp    f01028a5 <mem_init+0x15ac>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010288e:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102894:	89 d8                	mov    %ebx,%eax
f0102896:	e8 5b e2 ff ff       	call   f0100af6 <check_va2pa>
f010289b:	39 c6                	cmp    %eax,%esi
f010289d:	75 66                	jne    f0102905 <mem_init+0x160c>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010289f:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028a5:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01028a8:	72 e4                	jb     f010288e <mem_init+0x1595>
f01028aa:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01028af:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f01028b5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028b8:	05 00 80 00 20       	add    $0x20008000,%eax
f01028bd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01028c0:	89 f2                	mov    %esi,%edx
f01028c2:	89 d8                	mov    %ebx,%eax
f01028c4:	e8 2d e2 ff ff       	call   f0100af6 <check_va2pa>
f01028c9:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01028d0:	76 54                	jbe    f0102926 <mem_init+0x162d>
f01028d2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01028d5:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f01028d8:	39 c2                	cmp    %eax,%edx
f01028da:	75 6a                	jne    f0102946 <mem_init+0x164d>
f01028dc:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028e2:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01028e8:	75 d6                	jne    f01028c0 <mem_init+0x15c7>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01028ea:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01028ef:	89 d8                	mov    %ebx,%eax
f01028f1:	e8 00 e2 ff ff       	call   f0100af6 <check_va2pa>
f01028f6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028f9:	75 6c                	jne    f0102967 <mem_init+0x166e>
	for (i = 0; i < NPDENTRIES; i++) {
f01028fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0102900:	e9 ac 00 00 00       	jmp    f01029b1 <mem_init+0x16b8>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102905:	8d 87 88 d7 fe ff    	lea    -0x12878(%edi),%eax
f010290b:	50                   	push   %eax
f010290c:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102912:	50                   	push   %eax
f0102913:	68 ce 02 00 00       	push   $0x2ce
f0102918:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010291e:	50                   	push   %eax
f010291f:	89 fb                	mov    %edi,%ebx
f0102921:	e8 73 d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102926:	ff b7 fc ff ff ff    	pushl  -0x4(%edi)
f010292c:	8d 87 5c d2 fe ff    	lea    -0x12da4(%edi),%eax
f0102932:	50                   	push   %eax
f0102933:	68 d2 02 00 00       	push   $0x2d2
f0102938:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010293e:	50                   	push   %eax
f010293f:	89 fb                	mov    %edi,%ebx
f0102941:	e8 53 d7 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102946:	8d 87 b0 d7 fe ff    	lea    -0x12850(%edi),%eax
f010294c:	50                   	push   %eax
f010294d:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102953:	50                   	push   %eax
f0102954:	68 d2 02 00 00       	push   $0x2d2
f0102959:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f010295f:	50                   	push   %eax
f0102960:	89 fb                	mov    %edi,%ebx
f0102962:	e8 32 d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102967:	8d 87 f8 d7 fe ff    	lea    -0x12808(%edi),%eax
f010296d:	50                   	push   %eax
f010296e:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102974:	50                   	push   %eax
f0102975:	68 d3 02 00 00       	push   $0x2d3
f010297a:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102980:	50                   	push   %eax
f0102981:	89 fb                	mov    %edi,%ebx
f0102983:	e8 11 d7 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102988:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010298c:	74 51                	je     f01029df <mem_init+0x16e6>
	for (i = 0; i < NPDENTRIES; i++) {
f010298e:	83 c0 01             	add    $0x1,%eax
f0102991:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102996:	0f 87 b3 00 00 00    	ja     f0102a4f <mem_init+0x1756>
		switch (i) {
f010299c:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01029a1:	72 0e                	jb     f01029b1 <mem_init+0x16b8>
f01029a3:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01029a8:	76 de                	jbe    f0102988 <mem_init+0x168f>
f01029aa:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029af:	74 d7                	je     f0102988 <mem_init+0x168f>
			if (i >= PDX(KERNBASE)) {
f01029b1:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029b6:	77 48                	ja     f0102a00 <mem_init+0x1707>
				assert(pgdir[i] == 0);
f01029b8:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01029bc:	74 d0                	je     f010298e <mem_init+0x1695>
f01029be:	8d 87 bd db fe ff    	lea    -0x12443(%edi),%eax
f01029c4:	50                   	push   %eax
f01029c5:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01029cb:	50                   	push   %eax
f01029cc:	68 e2 02 00 00       	push   $0x2e2
f01029d1:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01029d7:	50                   	push   %eax
f01029d8:	89 fb                	mov    %edi,%ebx
f01029da:	e8 ba d6 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f01029df:	8d 87 9b db fe ff    	lea    -0x12465(%edi),%eax
f01029e5:	50                   	push   %eax
f01029e6:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f01029ec:	50                   	push   %eax
f01029ed:	68 db 02 00 00       	push   $0x2db
f01029f2:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f01029f8:	50                   	push   %eax
f01029f9:	89 fb                	mov    %edi,%ebx
f01029fb:	e8 99 d6 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102a00:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102a03:	f6 c2 01             	test   $0x1,%dl
f0102a06:	74 26                	je     f0102a2e <mem_init+0x1735>
				assert(pgdir[i] & PTE_W);
f0102a08:	f6 c2 02             	test   $0x2,%dl
f0102a0b:	75 81                	jne    f010298e <mem_init+0x1695>
f0102a0d:	8d 87 ac db fe ff    	lea    -0x12454(%edi),%eax
f0102a13:	50                   	push   %eax
f0102a14:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102a1a:	50                   	push   %eax
f0102a1b:	68 e0 02 00 00       	push   $0x2e0
f0102a20:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102a26:	50                   	push   %eax
f0102a27:	89 fb                	mov    %edi,%ebx
f0102a29:	e8 6b d6 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102a2e:	8d 87 9b db fe ff    	lea    -0x12465(%edi),%eax
f0102a34:	50                   	push   %eax
f0102a35:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102a3b:	50                   	push   %eax
f0102a3c:	68 df 02 00 00       	push   $0x2df
f0102a41:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102a47:	50                   	push   %eax
f0102a48:	89 fb                	mov    %edi,%ebx
f0102a4a:	e8 4a d6 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a4f:	83 ec 0c             	sub    $0xc,%esp
f0102a52:	8d 87 28 d8 fe ff    	lea    -0x127d8(%edi),%eax
f0102a58:	50                   	push   %eax
f0102a59:	89 fb                	mov    %edi,%ebx
f0102a5b:	e8 ce 04 00 00       	call   f0102f2e <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102a60:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102a66:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102a68:	83 c4 10             	add    $0x10,%esp
f0102a6b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a70:	0f 86 33 02 00 00    	jbe    f0102ca9 <mem_init+0x19b0>
	return (physaddr_t)kva - KERNBASE;
f0102a76:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a7b:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102a7e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a83:	e8 eb e0 ff ff       	call   f0100b73 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a88:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a8b:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a8e:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a93:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a96:	83 ec 0c             	sub    $0xc,%esp
f0102a99:	6a 00                	push   $0x0
f0102a9b:	e8 45 e5 ff ff       	call   f0100fe5 <page_alloc>
f0102aa0:	89 c6                	mov    %eax,%esi
f0102aa2:	83 c4 10             	add    $0x10,%esp
f0102aa5:	85 c0                	test   %eax,%eax
f0102aa7:	0f 84 15 02 00 00    	je     f0102cc2 <mem_init+0x19c9>
	assert((pp1 = page_alloc(0)));
f0102aad:	83 ec 0c             	sub    $0xc,%esp
f0102ab0:	6a 00                	push   $0x0
f0102ab2:	e8 2e e5 ff ff       	call   f0100fe5 <page_alloc>
f0102ab7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102aba:	83 c4 10             	add    $0x10,%esp
f0102abd:	85 c0                	test   %eax,%eax
f0102abf:	0f 84 1c 02 00 00    	je     f0102ce1 <mem_init+0x19e8>
	assert((pp2 = page_alloc(0)));
f0102ac5:	83 ec 0c             	sub    $0xc,%esp
f0102ac8:	6a 00                	push   $0x0
f0102aca:	e8 16 e5 ff ff       	call   f0100fe5 <page_alloc>
f0102acf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102ad2:	83 c4 10             	add    $0x10,%esp
f0102ad5:	85 c0                	test   %eax,%eax
f0102ad7:	0f 84 23 02 00 00    	je     f0102d00 <mem_init+0x1a07>
	page_free(pp0);
f0102add:	83 ec 0c             	sub    $0xc,%esp
f0102ae0:	56                   	push   %esi
f0102ae1:	e8 87 e5 ff ff       	call   f010106d <page_free>
	return (pp - pages) << PGSHIFT;
f0102ae6:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102aec:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102aef:	2b 08                	sub    (%eax),%ecx
f0102af1:	89 c8                	mov    %ecx,%eax
f0102af3:	c1 f8 03             	sar    $0x3,%eax
f0102af6:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102af9:	89 c1                	mov    %eax,%ecx
f0102afb:	c1 e9 0c             	shr    $0xc,%ecx
f0102afe:	83 c4 10             	add    $0x10,%esp
f0102b01:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102b07:	3b 0a                	cmp    (%edx),%ecx
f0102b09:	0f 83 10 02 00 00    	jae    f0102d1f <mem_init+0x1a26>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b0f:	83 ec 04             	sub    $0x4,%esp
f0102b12:	68 00 10 00 00       	push   $0x1000
f0102b17:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102b19:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b1e:	50                   	push   %eax
f0102b1f:	e8 1b 10 00 00       	call   f0103b3f <memset>
	return (pp - pages) << PGSHIFT;
f0102b24:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102b2a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102b2d:	2b 08                	sub    (%eax),%ecx
f0102b2f:	89 c8                	mov    %ecx,%eax
f0102b31:	c1 f8 03             	sar    $0x3,%eax
f0102b34:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102b37:	89 c1                	mov    %eax,%ecx
f0102b39:	c1 e9 0c             	shr    $0xc,%ecx
f0102b3c:	83 c4 10             	add    $0x10,%esp
f0102b3f:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102b45:	3b 0a                	cmp    (%edx),%ecx
f0102b47:	0f 83 e8 01 00 00    	jae    f0102d35 <mem_init+0x1a3c>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b4d:	83 ec 04             	sub    $0x4,%esp
f0102b50:	68 00 10 00 00       	push   $0x1000
f0102b55:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102b57:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b5c:	50                   	push   %eax
f0102b5d:	e8 dd 0f 00 00       	call   f0103b3f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b62:	6a 02                	push   $0x2
f0102b64:	68 00 10 00 00       	push   $0x1000
f0102b69:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102b6c:	53                   	push   %ebx
f0102b6d:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102b73:	ff 30                	pushl  (%eax)
f0102b75:	e8 01 e7 ff ff       	call   f010127b <page_insert>
	assert(pp1->pp_ref == 1);
f0102b7a:	83 c4 20             	add    $0x20,%esp
f0102b7d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102b82:	0f 85 c3 01 00 00    	jne    f0102d4b <mem_init+0x1a52>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b88:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b8f:	01 01 01 
f0102b92:	0f 85 d4 01 00 00    	jne    f0102d6c <mem_init+0x1a73>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b98:	6a 02                	push   $0x2
f0102b9a:	68 00 10 00 00       	push   $0x1000
f0102b9f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102ba2:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102ba8:	ff 30                	pushl  (%eax)
f0102baa:	e8 cc e6 ff ff       	call   f010127b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102baf:	83 c4 10             	add    $0x10,%esp
f0102bb2:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bb9:	02 02 02 
f0102bbc:	0f 85 cb 01 00 00    	jne    f0102d8d <mem_init+0x1a94>
	assert(pp2->pp_ref == 1);
f0102bc2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bc5:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102bca:	0f 85 de 01 00 00    	jne    f0102dae <mem_init+0x1ab5>
	assert(pp1->pp_ref == 0);
f0102bd0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102bd3:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102bd8:	0f 85 f1 01 00 00    	jne    f0102dcf <mem_init+0x1ad6>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102bde:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102be5:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102be8:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102bee:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102bf1:	2b 08                	sub    (%eax),%ecx
f0102bf3:	89 c8                	mov    %ecx,%eax
f0102bf5:	c1 f8 03             	sar    $0x3,%eax
f0102bf8:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102bfb:	89 c1                	mov    %eax,%ecx
f0102bfd:	c1 e9 0c             	shr    $0xc,%ecx
f0102c00:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102c06:	3b 0a                	cmp    (%edx),%ecx
f0102c08:	0f 83 e2 01 00 00    	jae    f0102df0 <mem_init+0x1af7>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c0e:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c15:	03 03 03 
f0102c18:	0f 85 ea 01 00 00    	jne    f0102e08 <mem_init+0x1b0f>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c1e:	83 ec 08             	sub    $0x8,%esp
f0102c21:	68 00 10 00 00       	push   $0x1000
f0102c26:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102c2c:	ff 30                	pushl  (%eax)
f0102c2e:	e8 0b e6 ff ff       	call   f010123e <page_remove>
	assert(pp2->pp_ref == 0);
f0102c33:	83 c4 10             	add    $0x10,%esp
f0102c36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c39:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102c3e:	0f 85 e5 01 00 00    	jne    f0102e29 <mem_init+0x1b30>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c44:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102c4a:	8b 08                	mov    (%eax),%ecx
f0102c4c:	8b 11                	mov    (%ecx),%edx
f0102c4e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102c54:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102c5a:	89 f3                	mov    %esi,%ebx
f0102c5c:	2b 18                	sub    (%eax),%ebx
f0102c5e:	89 d8                	mov    %ebx,%eax
f0102c60:	c1 f8 03             	sar    $0x3,%eax
f0102c63:	c1 e0 0c             	shl    $0xc,%eax
f0102c66:	39 c2                	cmp    %eax,%edx
f0102c68:	0f 85 dc 01 00 00    	jne    f0102e4a <mem_init+0x1b51>
	kern_pgdir[0] = 0;
f0102c6e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c74:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c79:	0f 85 ec 01 00 00    	jne    f0102e6b <mem_init+0x1b72>
	pp0->pp_ref = 0;
f0102c7f:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102c85:	83 ec 0c             	sub    $0xc,%esp
f0102c88:	56                   	push   %esi
f0102c89:	e8 df e3 ff ff       	call   f010106d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c8e:	8d 87 bc d8 fe ff    	lea    -0x12744(%edi),%eax
f0102c94:	89 04 24             	mov    %eax,(%esp)
f0102c97:	89 fb                	mov    %edi,%ebx
f0102c99:	e8 90 02 00 00       	call   f0102f2e <cprintf>
}
f0102c9e:	83 c4 10             	add    $0x10,%esp
f0102ca1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ca4:	5b                   	pop    %ebx
f0102ca5:	5e                   	pop    %esi
f0102ca6:	5f                   	pop    %edi
f0102ca7:	5d                   	pop    %ebp
f0102ca8:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ca9:	50                   	push   %eax
f0102caa:	8d 87 5c d2 fe ff    	lea    -0x12da4(%edi),%eax
f0102cb0:	50                   	push   %eax
f0102cb1:	68 df 00 00 00       	push   $0xdf
f0102cb6:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102cbc:	50                   	push   %eax
f0102cbd:	e8 d7 d3 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102cc2:	8d 87 b9 d9 fe ff    	lea    -0x12647(%edi),%eax
f0102cc8:	50                   	push   %eax
f0102cc9:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102ccf:	50                   	push   %eax
f0102cd0:	68 a2 03 00 00       	push   $0x3a2
f0102cd5:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102cdb:	50                   	push   %eax
f0102cdc:	e8 b8 d3 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102ce1:	8d 87 cf d9 fe ff    	lea    -0x12631(%edi),%eax
f0102ce7:	50                   	push   %eax
f0102ce8:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102cee:	50                   	push   %eax
f0102cef:	68 a3 03 00 00       	push   $0x3a3
f0102cf4:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102cfa:	50                   	push   %eax
f0102cfb:	e8 99 d3 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102d00:	8d 87 e5 d9 fe ff    	lea    -0x1261b(%edi),%eax
f0102d06:	50                   	push   %eax
f0102d07:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102d0d:	50                   	push   %eax
f0102d0e:	68 a4 03 00 00       	push   $0x3a4
f0102d13:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102d19:	50                   	push   %eax
f0102d1a:	e8 7a d3 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d1f:	50                   	push   %eax
f0102d20:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f0102d26:	50                   	push   %eax
f0102d27:	6a 59                	push   $0x59
f0102d29:	8d 87 f4 d8 fe ff    	lea    -0x1270c(%edi),%eax
f0102d2f:	50                   	push   %eax
f0102d30:	e8 64 d3 ff ff       	call   f0100099 <_panic>
f0102d35:	50                   	push   %eax
f0102d36:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f0102d3c:	50                   	push   %eax
f0102d3d:	6a 59                	push   $0x59
f0102d3f:	8d 87 f4 d8 fe ff    	lea    -0x1270c(%edi),%eax
f0102d45:	50                   	push   %eax
f0102d46:	e8 4e d3 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102d4b:	8d 87 b6 da fe ff    	lea    -0x1254a(%edi),%eax
f0102d51:	50                   	push   %eax
f0102d52:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102d58:	50                   	push   %eax
f0102d59:	68 a9 03 00 00       	push   $0x3a9
f0102d5e:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102d64:	50                   	push   %eax
f0102d65:	89 fb                	mov    %edi,%ebx
f0102d67:	e8 2d d3 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d6c:	8d 87 48 d8 fe ff    	lea    -0x127b8(%edi),%eax
f0102d72:	50                   	push   %eax
f0102d73:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102d79:	50                   	push   %eax
f0102d7a:	68 aa 03 00 00       	push   $0x3aa
f0102d7f:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102d85:	50                   	push   %eax
f0102d86:	89 fb                	mov    %edi,%ebx
f0102d88:	e8 0c d3 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d8d:	8d 87 6c d8 fe ff    	lea    -0x12794(%edi),%eax
f0102d93:	50                   	push   %eax
f0102d94:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102d9a:	50                   	push   %eax
f0102d9b:	68 ac 03 00 00       	push   $0x3ac
f0102da0:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102da6:	50                   	push   %eax
f0102da7:	89 fb                	mov    %edi,%ebx
f0102da9:	e8 eb d2 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102dae:	8d 87 d8 da fe ff    	lea    -0x12528(%edi),%eax
f0102db4:	50                   	push   %eax
f0102db5:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102dbb:	50                   	push   %eax
f0102dbc:	68 ad 03 00 00       	push   $0x3ad
f0102dc1:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102dc7:	50                   	push   %eax
f0102dc8:	89 fb                	mov    %edi,%ebx
f0102dca:	e8 ca d2 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102dcf:	8d 87 42 db fe ff    	lea    -0x124be(%edi),%eax
f0102dd5:	50                   	push   %eax
f0102dd6:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102ddc:	50                   	push   %eax
f0102ddd:	68 ae 03 00 00       	push   $0x3ae
f0102de2:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102de8:	50                   	push   %eax
f0102de9:	89 fb                	mov    %edi,%ebx
f0102deb:	e8 a9 d2 ff ff       	call   f0100099 <_panic>
f0102df0:	50                   	push   %eax
f0102df1:	8d 87 50 d1 fe ff    	lea    -0x12eb0(%edi),%eax
f0102df7:	50                   	push   %eax
f0102df8:	6a 59                	push   $0x59
f0102dfa:	8d 87 f4 d8 fe ff    	lea    -0x1270c(%edi),%eax
f0102e00:	50                   	push   %eax
f0102e01:	89 fb                	mov    %edi,%ebx
f0102e03:	e8 91 d2 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102e08:	8d 87 90 d8 fe ff    	lea    -0x12770(%edi),%eax
f0102e0e:	50                   	push   %eax
f0102e0f:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102e15:	50                   	push   %eax
f0102e16:	68 b0 03 00 00       	push   $0x3b0
f0102e1b:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102e21:	50                   	push   %eax
f0102e22:	89 fb                	mov    %edi,%ebx
f0102e24:	e8 70 d2 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102e29:	8d 87 10 db fe ff    	lea    -0x124f0(%edi),%eax
f0102e2f:	50                   	push   %eax
f0102e30:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102e36:	50                   	push   %eax
f0102e37:	68 b2 03 00 00       	push   $0x3b2
f0102e3c:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102e42:	50                   	push   %eax
f0102e43:	89 fb                	mov    %edi,%ebx
f0102e45:	e8 4f d2 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e4a:	8d 87 d4 d3 fe ff    	lea    -0x12c2c(%edi),%eax
f0102e50:	50                   	push   %eax
f0102e51:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102e57:	50                   	push   %eax
f0102e58:	68 b5 03 00 00       	push   $0x3b5
f0102e5d:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102e63:	50                   	push   %eax
f0102e64:	89 fb                	mov    %edi,%ebx
f0102e66:	e8 2e d2 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102e6b:	8d 87 c7 da fe ff    	lea    -0x12539(%edi),%eax
f0102e71:	50                   	push   %eax
f0102e72:	8d 87 0e d9 fe ff    	lea    -0x126f2(%edi),%eax
f0102e78:	50                   	push   %eax
f0102e79:	68 b7 03 00 00       	push   $0x3b7
f0102e7e:	8d 87 e8 d8 fe ff    	lea    -0x12718(%edi),%eax
f0102e84:	50                   	push   %eax
f0102e85:	89 fb                	mov    %edi,%ebx
f0102e87:	e8 0d d2 ff ff       	call   f0100099 <_panic>

f0102e8c <tlb_invalidate>:
{
f0102e8c:	55                   	push   %ebp
f0102e8d:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102e8f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e92:	0f 01 38             	invlpg (%eax)
}
f0102e95:	5d                   	pop    %ebp
f0102e96:	c3                   	ret    

f0102e97 <__x86.get_pc_thunk.dx>:
f0102e97:	8b 14 24             	mov    (%esp),%edx
f0102e9a:	c3                   	ret    

f0102e9b <__x86.get_pc_thunk.cx>:
f0102e9b:	8b 0c 24             	mov    (%esp),%ecx
f0102e9e:	c3                   	ret    

f0102e9f <__x86.get_pc_thunk.si>:
f0102e9f:	8b 34 24             	mov    (%esp),%esi
f0102ea2:	c3                   	ret    

f0102ea3 <__x86.get_pc_thunk.di>:
f0102ea3:	8b 3c 24             	mov    (%esp),%edi
f0102ea6:	c3                   	ret    

f0102ea7 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ea7:	55                   	push   %ebp
f0102ea8:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102eaa:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ead:	ba 70 00 00 00       	mov    $0x70,%edx
f0102eb2:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102eb3:	ba 71 00 00 00       	mov    $0x71,%edx
f0102eb8:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102eb9:	0f b6 c0             	movzbl %al,%eax
}
f0102ebc:	5d                   	pop    %ebp
f0102ebd:	c3                   	ret    

f0102ebe <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ebe:	55                   	push   %ebp
f0102ebf:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ec1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ec4:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ec9:	ee                   	out    %al,(%dx)
f0102eca:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ecd:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ed2:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ed3:	5d                   	pop    %ebp
f0102ed4:	c3                   	ret    

f0102ed5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ed5:	55                   	push   %ebp
f0102ed6:	89 e5                	mov    %esp,%ebp
f0102ed8:	53                   	push   %ebx
f0102ed9:	83 ec 10             	sub    $0x10,%esp
f0102edc:	e8 6e d2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102ee1:	81 c3 2b 44 01 00    	add    $0x1442b,%ebx
	cputchar(ch);
f0102ee7:	ff 75 08             	pushl  0x8(%ebp)
f0102eea:	e8 d7 d7 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0102eef:	83 c4 10             	add    $0x10,%esp
f0102ef2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ef5:	c9                   	leave  
f0102ef6:	c3                   	ret    

f0102ef7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ef7:	55                   	push   %ebp
f0102ef8:	89 e5                	mov    %esp,%ebp
f0102efa:	53                   	push   %ebx
f0102efb:	83 ec 14             	sub    $0x14,%esp
f0102efe:	e8 4c d2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102f03:	81 c3 09 44 01 00    	add    $0x14409,%ebx
	int cnt = 0;
f0102f09:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f10:	ff 75 0c             	pushl  0xc(%ebp)
f0102f13:	ff 75 08             	pushl  0x8(%ebp)
f0102f16:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f19:	50                   	push   %eax
f0102f1a:	8d 83 c9 bb fe ff    	lea    -0x14437(%ebx),%eax
f0102f20:	50                   	push   %eax
f0102f21:	e8 98 04 00 00       	call   f01033be <vprintfmt>
	return cnt;
}
f0102f26:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f29:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f2c:	c9                   	leave  
f0102f2d:	c3                   	ret    

f0102f2e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f2e:	55                   	push   %ebp
f0102f2f:	89 e5                	mov    %esp,%ebp
f0102f31:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f34:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f37:	50                   	push   %eax
f0102f38:	ff 75 08             	pushl  0x8(%ebp)
f0102f3b:	e8 b7 ff ff ff       	call   f0102ef7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f40:	c9                   	leave  
f0102f41:	c3                   	ret    

f0102f42 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102f42:	55                   	push   %ebp
f0102f43:	89 e5                	mov    %esp,%ebp
f0102f45:	57                   	push   %edi
f0102f46:	56                   	push   %esi
f0102f47:	53                   	push   %ebx
f0102f48:	83 ec 14             	sub    $0x14,%esp
f0102f4b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f4e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102f51:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102f54:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102f57:	8b 32                	mov    (%edx),%esi
f0102f59:	8b 01                	mov    (%ecx),%eax
f0102f5b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f5e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102f65:	eb 2f                	jmp    f0102f96 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0102f67:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0102f6a:	39 c6                	cmp    %eax,%esi
f0102f6c:	7f 49                	jg     f0102fb7 <stab_binsearch+0x75>
f0102f6e:	0f b6 0a             	movzbl (%edx),%ecx
f0102f71:	83 ea 0c             	sub    $0xc,%edx
f0102f74:	39 f9                	cmp    %edi,%ecx
f0102f76:	75 ef                	jne    f0102f67 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102f78:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102f7b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102f7e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102f82:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f85:	73 35                	jae    f0102fbc <stab_binsearch+0x7a>
			*region_left = m;
f0102f87:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102f8a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0102f8c:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0102f8f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0102f96:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0102f99:	7f 4e                	jg     f0102fe9 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0102f9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102f9e:	01 f0                	add    %esi,%eax
f0102fa0:	89 c3                	mov    %eax,%ebx
f0102fa2:	c1 eb 1f             	shr    $0x1f,%ebx
f0102fa5:	01 c3                	add    %eax,%ebx
f0102fa7:	d1 fb                	sar    %ebx
f0102fa9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102fac:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102faf:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0102fb3:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0102fb5:	eb b3                	jmp    f0102f6a <stab_binsearch+0x28>
			l = true_m + 1;
f0102fb7:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0102fba:	eb da                	jmp    f0102f96 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0102fbc:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102fbf:	76 14                	jbe    f0102fd5 <stab_binsearch+0x93>
			*region_right = m - 1;
f0102fc1:	83 e8 01             	sub    $0x1,%eax
f0102fc4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102fc7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102fca:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0102fcc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102fd3:	eb c1                	jmp    f0102f96 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102fd5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102fd8:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102fda:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102fde:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0102fe0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102fe7:	eb ad                	jmp    f0102f96 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0102fe9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102fed:	74 16                	je     f0103005 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ff2:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102ff4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102ff7:	8b 0e                	mov    (%esi),%ecx
f0102ff9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102ffc:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102fff:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0103003:	eb 12                	jmp    f0103017 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103005:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103008:	8b 00                	mov    (%eax),%eax
f010300a:	83 e8 01             	sub    $0x1,%eax
f010300d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103010:	89 07                	mov    %eax,(%edi)
f0103012:	eb 16                	jmp    f010302a <stab_binsearch+0xe8>
		     l--)
f0103014:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103017:	39 c1                	cmp    %eax,%ecx
f0103019:	7d 0a                	jge    f0103025 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f010301b:	0f b6 1a             	movzbl (%edx),%ebx
f010301e:	83 ea 0c             	sub    $0xc,%edx
f0103021:	39 fb                	cmp    %edi,%ebx
f0103023:	75 ef                	jne    f0103014 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103025:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103028:	89 07                	mov    %eax,(%edi)
	}
}
f010302a:	83 c4 14             	add    $0x14,%esp
f010302d:	5b                   	pop    %ebx
f010302e:	5e                   	pop    %esi
f010302f:	5f                   	pop    %edi
f0103030:	5d                   	pop    %ebp
f0103031:	c3                   	ret    

f0103032 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103032:	55                   	push   %ebp
f0103033:	89 e5                	mov    %esp,%ebp
f0103035:	57                   	push   %edi
f0103036:	56                   	push   %esi
f0103037:	53                   	push   %ebx
f0103038:	83 ec 3c             	sub    $0x3c,%esp
f010303b:	e8 0f d1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103040:	81 c3 cc 42 01 00    	add    $0x142cc,%ebx
f0103046:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103049:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010304c:	8d 83 cb db fe ff    	lea    -0x12435(%ebx),%eax
f0103052:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0103054:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010305b:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f010305e:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103065:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103068:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010306f:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103075:	0f 86 37 01 00 00    	jbe    f01031b2 <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010307b:	c7 c0 89 b8 10 f0    	mov    $0xf010b889,%eax
f0103081:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f0103087:	0f 86 04 02 00 00    	jbe    f0103291 <debuginfo_eip+0x25f>
f010308d:	c7 c0 75 d6 10 f0    	mov    $0xf010d675,%eax
f0103093:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103097:	0f 85 fb 01 00 00    	jne    f0103298 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010309d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01030a4:	c7 c0 f0 50 10 f0    	mov    $0xf01050f0,%eax
f01030aa:	c7 c2 88 b8 10 f0    	mov    $0xf010b888,%edx
f01030b0:	29 c2                	sub    %eax,%edx
f01030b2:	c1 fa 02             	sar    $0x2,%edx
f01030b5:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01030bb:	83 ea 01             	sub    $0x1,%edx
f01030be:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01030c1:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01030c4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01030c7:	83 ec 08             	sub    $0x8,%esp
f01030ca:	57                   	push   %edi
f01030cb:	6a 64                	push   $0x64
f01030cd:	e8 70 fe ff ff       	call   f0102f42 <stab_binsearch>
	if (lfile == 0)
f01030d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030d5:	83 c4 10             	add    $0x10,%esp
f01030d8:	85 c0                	test   %eax,%eax
f01030da:	0f 84 bf 01 00 00    	je     f010329f <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01030e0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01030e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030e6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01030e9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01030ec:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01030ef:	83 ec 08             	sub    $0x8,%esp
f01030f2:	57                   	push   %edi
f01030f3:	6a 24                	push   $0x24
f01030f5:	c7 c0 f0 50 10 f0    	mov    $0xf01050f0,%eax
f01030fb:	e8 42 fe ff ff       	call   f0102f42 <stab_binsearch>

	if (lfun <= rfun) {
f0103100:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103103:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103106:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0103109:	83 c4 10             	add    $0x10,%esp
f010310c:	39 c8                	cmp    %ecx,%eax
f010310e:	0f 8f b6 00 00 00    	jg     f01031ca <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103114:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103117:	c7 c1 f0 50 10 f0    	mov    $0xf01050f0,%ecx
f010311d:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0103120:	8b 11                	mov    (%ecx),%edx
f0103122:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0103125:	c7 c2 75 d6 10 f0    	mov    $0xf010d675,%edx
f010312b:	81 ea 89 b8 10 f0    	sub    $0xf010b889,%edx
f0103131:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0103134:	73 0c                	jae    f0103142 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103136:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103139:	81 c2 89 b8 10 f0    	add    $0xf010b889,%edx
f010313f:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103142:	8b 51 08             	mov    0x8(%ecx),%edx
f0103145:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103148:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f010314a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010314d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103150:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103153:	83 ec 08             	sub    $0x8,%esp
f0103156:	6a 3a                	push   $0x3a
f0103158:	ff 76 08             	pushl  0x8(%esi)
f010315b:	e8 c3 09 00 00       	call   f0103b23 <strfind>
f0103160:	2b 46 08             	sub    0x8(%esi),%eax
f0103163:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103166:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103169:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010316c:	83 c4 08             	add    $0x8,%esp
f010316f:	57                   	push   %edi
f0103170:	6a 44                	push   $0x44
f0103172:	c7 c0 f0 50 10 f0    	mov    $0xf01050f0,%eax
f0103178:	e8 c5 fd ff ff       	call   f0102f42 <stab_binsearch>
	if(lline<=rline){
f010317d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103180:	83 c4 10             	add    $0x10,%esp
f0103183:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103186:	0f 8f 1a 01 00 00    	jg     f01032a6 <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f010318c:	89 d0                	mov    %edx,%eax
f010318e:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103191:	c1 e2 02             	shl    $0x2,%edx
f0103194:	c7 c1 f0 50 10 f0    	mov    $0xf01050f0,%ecx
f010319a:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f010319f:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01031a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01031a5:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f01031a9:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01031ad:	89 75 0c             	mov    %esi,0xc(%ebp)
f01031b0:	eb 36                	jmp    f01031e8 <debuginfo_eip+0x1b6>
  	        panic("User address");
f01031b2:	83 ec 04             	sub    $0x4,%esp
f01031b5:	8d 83 d5 db fe ff    	lea    -0x1242b(%ebx),%eax
f01031bb:	50                   	push   %eax
f01031bc:	6a 7f                	push   $0x7f
f01031be:	8d 83 e2 db fe ff    	lea    -0x1241e(%ebx),%eax
f01031c4:	50                   	push   %eax
f01031c5:	e8 cf ce ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f01031ca:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01031cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031d0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01031d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031d6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01031d9:	e9 75 ff ff ff       	jmp    f0103153 <debuginfo_eip+0x121>
f01031de:	83 e8 01             	sub    $0x1,%eax
f01031e1:	83 ea 0c             	sub    $0xc,%edx
f01031e4:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01031e8:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f01031eb:	39 c7                	cmp    %eax,%edi
f01031ed:	7f 24                	jg     f0103213 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f01031ef:	0f b6 0a             	movzbl (%edx),%ecx
f01031f2:	80 f9 84             	cmp    $0x84,%cl
f01031f5:	74 46                	je     f010323d <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01031f7:	80 f9 64             	cmp    $0x64,%cl
f01031fa:	75 e2                	jne    f01031de <debuginfo_eip+0x1ac>
f01031fc:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0103200:	74 dc                	je     f01031de <debuginfo_eip+0x1ac>
f0103202:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103205:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103209:	74 3b                	je     f0103246 <debuginfo_eip+0x214>
f010320b:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010320e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103211:	eb 33                	jmp    f0103246 <debuginfo_eip+0x214>
f0103213:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103216:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103219:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010321c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103221:	39 fa                	cmp    %edi,%edx
f0103223:	0f 8d 89 00 00 00    	jge    f01032b2 <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0103229:	83 c2 01             	add    $0x1,%edx
f010322c:	89 d0                	mov    %edx,%eax
f010322e:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0103231:	c7 c2 f0 50 10 f0    	mov    $0xf01050f0,%edx
f0103237:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f010323b:	eb 3b                	jmp    f0103278 <debuginfo_eip+0x246>
f010323d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103240:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103244:	75 26                	jne    f010326c <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103246:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103249:	c7 c0 f0 50 10 f0    	mov    $0xf01050f0,%eax
f010324f:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0103252:	c7 c0 75 d6 10 f0    	mov    $0xf010d675,%eax
f0103258:	81 e8 89 b8 10 f0    	sub    $0xf010b889,%eax
f010325e:	39 c2                	cmp    %eax,%edx
f0103260:	73 b4                	jae    f0103216 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103262:	81 c2 89 b8 10 f0    	add    $0xf010b889,%edx
f0103268:	89 16                	mov    %edx,(%esi)
f010326a:	eb aa                	jmp    f0103216 <debuginfo_eip+0x1e4>
f010326c:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010326f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103272:	eb d2                	jmp    f0103246 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0103274:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0103278:	39 c7                	cmp    %eax,%edi
f010327a:	7e 31                	jle    f01032ad <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010327c:	0f b6 0a             	movzbl (%edx),%ecx
f010327f:	83 c0 01             	add    $0x1,%eax
f0103282:	83 c2 0c             	add    $0xc,%edx
f0103285:	80 f9 a0             	cmp    $0xa0,%cl
f0103288:	74 ea                	je     f0103274 <debuginfo_eip+0x242>
	return 0;
f010328a:	b8 00 00 00 00       	mov    $0x0,%eax
f010328f:	eb 21                	jmp    f01032b2 <debuginfo_eip+0x280>
		return -1;
f0103291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103296:	eb 1a                	jmp    f01032b2 <debuginfo_eip+0x280>
f0103298:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010329d:	eb 13                	jmp    f01032b2 <debuginfo_eip+0x280>
		return -1;
f010329f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032a4:	eb 0c                	jmp    f01032b2 <debuginfo_eip+0x280>
		return -1;
f01032a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032ab:	eb 05                	jmp    f01032b2 <debuginfo_eip+0x280>
	return 0;
f01032ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032b5:	5b                   	pop    %ebx
f01032b6:	5e                   	pop    %esi
f01032b7:	5f                   	pop    %edi
f01032b8:	5d                   	pop    %ebp
f01032b9:	c3                   	ret    

f01032ba <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01032ba:	55                   	push   %ebp
f01032bb:	89 e5                	mov    %esp,%ebp
f01032bd:	57                   	push   %edi
f01032be:	56                   	push   %esi
f01032bf:	53                   	push   %ebx
f01032c0:	83 ec 2c             	sub    $0x2c,%esp
f01032c3:	e8 d3 fb ff ff       	call   f0102e9b <__x86.get_pc_thunk.cx>
f01032c8:	81 c1 44 40 01 00    	add    $0x14044,%ecx
f01032ce:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01032d1:	89 c7                	mov    %eax,%edi
f01032d3:	89 d6                	mov    %edx,%esi
f01032d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01032d8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032db:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01032de:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01032e1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01032e4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01032e9:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01032ec:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01032ef:	39 d3                	cmp    %edx,%ebx
f01032f1:	72 09                	jb     f01032fc <printnum+0x42>
f01032f3:	39 45 10             	cmp    %eax,0x10(%ebp)
f01032f6:	0f 87 83 00 00 00    	ja     f010337f <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01032fc:	83 ec 0c             	sub    $0xc,%esp
f01032ff:	ff 75 18             	pushl  0x18(%ebp)
f0103302:	8b 45 14             	mov    0x14(%ebp),%eax
f0103305:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103308:	53                   	push   %ebx
f0103309:	ff 75 10             	pushl  0x10(%ebp)
f010330c:	83 ec 08             	sub    $0x8,%esp
f010330f:	ff 75 dc             	pushl  -0x24(%ebp)
f0103312:	ff 75 d8             	pushl  -0x28(%ebp)
f0103315:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103318:	ff 75 d0             	pushl  -0x30(%ebp)
f010331b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010331e:	e8 1d 0a 00 00       	call   f0103d40 <__udivdi3>
f0103323:	83 c4 18             	add    $0x18,%esp
f0103326:	52                   	push   %edx
f0103327:	50                   	push   %eax
f0103328:	89 f2                	mov    %esi,%edx
f010332a:	89 f8                	mov    %edi,%eax
f010332c:	e8 89 ff ff ff       	call   f01032ba <printnum>
f0103331:	83 c4 20             	add    $0x20,%esp
f0103334:	eb 13                	jmp    f0103349 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103336:	83 ec 08             	sub    $0x8,%esp
f0103339:	56                   	push   %esi
f010333a:	ff 75 18             	pushl  0x18(%ebp)
f010333d:	ff d7                	call   *%edi
f010333f:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103342:	83 eb 01             	sub    $0x1,%ebx
f0103345:	85 db                	test   %ebx,%ebx
f0103347:	7f ed                	jg     f0103336 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103349:	83 ec 08             	sub    $0x8,%esp
f010334c:	56                   	push   %esi
f010334d:	83 ec 04             	sub    $0x4,%esp
f0103350:	ff 75 dc             	pushl  -0x24(%ebp)
f0103353:	ff 75 d8             	pushl  -0x28(%ebp)
f0103356:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103359:	ff 75 d0             	pushl  -0x30(%ebp)
f010335c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010335f:	89 f3                	mov    %esi,%ebx
f0103361:	e8 fa 0a 00 00       	call   f0103e60 <__umoddi3>
f0103366:	83 c4 14             	add    $0x14,%esp
f0103369:	0f be 84 06 f0 db fe 	movsbl -0x12410(%esi,%eax,1),%eax
f0103370:	ff 
f0103371:	50                   	push   %eax
f0103372:	ff d7                	call   *%edi
}
f0103374:	83 c4 10             	add    $0x10,%esp
f0103377:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010337a:	5b                   	pop    %ebx
f010337b:	5e                   	pop    %esi
f010337c:	5f                   	pop    %edi
f010337d:	5d                   	pop    %ebp
f010337e:	c3                   	ret    
f010337f:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103382:	eb be                	jmp    f0103342 <printnum+0x88>

f0103384 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103384:	55                   	push   %ebp
f0103385:	89 e5                	mov    %esp,%ebp
f0103387:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010338a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010338e:	8b 10                	mov    (%eax),%edx
f0103390:	3b 50 04             	cmp    0x4(%eax),%edx
f0103393:	73 0a                	jae    f010339f <sprintputch+0x1b>
		*b->buf++ = ch;
f0103395:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103398:	89 08                	mov    %ecx,(%eax)
f010339a:	8b 45 08             	mov    0x8(%ebp),%eax
f010339d:	88 02                	mov    %al,(%edx)
}
f010339f:	5d                   	pop    %ebp
f01033a0:	c3                   	ret    

f01033a1 <printfmt>:
{
f01033a1:	55                   	push   %ebp
f01033a2:	89 e5                	mov    %esp,%ebp
f01033a4:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01033a7:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01033aa:	50                   	push   %eax
f01033ab:	ff 75 10             	pushl  0x10(%ebp)
f01033ae:	ff 75 0c             	pushl  0xc(%ebp)
f01033b1:	ff 75 08             	pushl  0x8(%ebp)
f01033b4:	e8 05 00 00 00       	call   f01033be <vprintfmt>
}
f01033b9:	83 c4 10             	add    $0x10,%esp
f01033bc:	c9                   	leave  
f01033bd:	c3                   	ret    

f01033be <vprintfmt>:
{
f01033be:	55                   	push   %ebp
f01033bf:	89 e5                	mov    %esp,%ebp
f01033c1:	57                   	push   %edi
f01033c2:	56                   	push   %esi
f01033c3:	53                   	push   %ebx
f01033c4:	83 ec 2c             	sub    $0x2c,%esp
f01033c7:	e8 83 cd ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01033cc:	81 c3 40 3f 01 00    	add    $0x13f40,%ebx
f01033d2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033d5:	8b 7d 10             	mov    0x10(%ebp),%edi
f01033d8:	e9 c3 03 00 00       	jmp    f01037a0 <.L35+0x48>
		padc = ' ';
f01033dd:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01033e1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01033e8:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f01033ef:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01033f6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033fb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01033fe:	8d 47 01             	lea    0x1(%edi),%eax
f0103401:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103404:	0f b6 17             	movzbl (%edi),%edx
f0103407:	8d 42 dd             	lea    -0x23(%edx),%eax
f010340a:	3c 55                	cmp    $0x55,%al
f010340c:	0f 87 16 04 00 00    	ja     f0103828 <.L22>
f0103412:	0f b6 c0             	movzbl %al,%eax
f0103415:	89 d9                	mov    %ebx,%ecx
f0103417:	03 8c 83 7c dc fe ff 	add    -0x12384(%ebx,%eax,4),%ecx
f010341e:	ff e1                	jmp    *%ecx

f0103420 <.L69>:
f0103420:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0103423:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0103427:	eb d5                	jmp    f01033fe <vprintfmt+0x40>

f0103429 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0103429:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010342c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103430:	eb cc                	jmp    f01033fe <vprintfmt+0x40>

f0103432 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0103432:	0f b6 d2             	movzbl %dl,%edx
f0103435:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103438:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010343d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103440:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103444:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103447:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010344a:	83 f9 09             	cmp    $0x9,%ecx
f010344d:	77 55                	ja     f01034a4 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010344f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103452:	eb e9                	jmp    f010343d <.L29+0xb>

f0103454 <.L26>:
			precision = va_arg(ap, int);
f0103454:	8b 45 14             	mov    0x14(%ebp),%eax
f0103457:	8b 00                	mov    (%eax),%eax
f0103459:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010345c:	8b 45 14             	mov    0x14(%ebp),%eax
f010345f:	8d 40 04             	lea    0x4(%eax),%eax
f0103462:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103465:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103468:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010346c:	79 90                	jns    f01033fe <vprintfmt+0x40>
				width = precision, precision = -1;
f010346e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103471:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103474:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f010347b:	eb 81                	jmp    f01033fe <vprintfmt+0x40>

f010347d <.L27>:
f010347d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103480:	85 c0                	test   %eax,%eax
f0103482:	ba 00 00 00 00       	mov    $0x0,%edx
f0103487:	0f 49 d0             	cmovns %eax,%edx
f010348a:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010348d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103490:	e9 69 ff ff ff       	jmp    f01033fe <vprintfmt+0x40>

f0103495 <.L23>:
f0103495:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103498:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010349f:	e9 5a ff ff ff       	jmp    f01033fe <vprintfmt+0x40>
f01034a4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01034a7:	eb bf                	jmp    f0103468 <.L26+0x14>

f01034a9 <.L33>:
			lflag++;
f01034a9:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01034ad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01034b0:	e9 49 ff ff ff       	jmp    f01033fe <vprintfmt+0x40>

f01034b5 <.L30>:
			putch(va_arg(ap, int), putdat);
f01034b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01034b8:	8d 78 04             	lea    0x4(%eax),%edi
f01034bb:	83 ec 08             	sub    $0x8,%esp
f01034be:	56                   	push   %esi
f01034bf:	ff 30                	pushl  (%eax)
f01034c1:	ff 55 08             	call   *0x8(%ebp)
			break;
f01034c4:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01034c7:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01034ca:	e9 ce 02 00 00       	jmp    f010379d <.L35+0x45>

f01034cf <.L32>:
			err = va_arg(ap, int);
f01034cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01034d2:	8d 78 04             	lea    0x4(%eax),%edi
f01034d5:	8b 00                	mov    (%eax),%eax
f01034d7:	99                   	cltd   
f01034d8:	31 d0                	xor    %edx,%eax
f01034da:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01034dc:	83 f8 06             	cmp    $0x6,%eax
f01034df:	7f 27                	jg     f0103508 <.L32+0x39>
f01034e1:	8b 94 83 38 1d 00 00 	mov    0x1d38(%ebx,%eax,4),%edx
f01034e8:	85 d2                	test   %edx,%edx
f01034ea:	74 1c                	je     f0103508 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01034ec:	52                   	push   %edx
f01034ed:	8d 83 20 d9 fe ff    	lea    -0x126e0(%ebx),%eax
f01034f3:	50                   	push   %eax
f01034f4:	56                   	push   %esi
f01034f5:	ff 75 08             	pushl  0x8(%ebp)
f01034f8:	e8 a4 fe ff ff       	call   f01033a1 <printfmt>
f01034fd:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103500:	89 7d 14             	mov    %edi,0x14(%ebp)
f0103503:	e9 95 02 00 00       	jmp    f010379d <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103508:	50                   	push   %eax
f0103509:	8d 83 08 dc fe ff    	lea    -0x123f8(%ebx),%eax
f010350f:	50                   	push   %eax
f0103510:	56                   	push   %esi
f0103511:	ff 75 08             	pushl  0x8(%ebp)
f0103514:	e8 88 fe ff ff       	call   f01033a1 <printfmt>
f0103519:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010351c:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010351f:	e9 79 02 00 00       	jmp    f010379d <.L35+0x45>

f0103524 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0103524:	8b 45 14             	mov    0x14(%ebp),%eax
f0103527:	83 c0 04             	add    $0x4,%eax
f010352a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010352d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103530:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103532:	85 ff                	test   %edi,%edi
f0103534:	8d 83 01 dc fe ff    	lea    -0x123ff(%ebx),%eax
f010353a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010353d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103541:	0f 8e b5 00 00 00    	jle    f01035fc <.L36+0xd8>
f0103547:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010354b:	75 08                	jne    f0103555 <.L36+0x31>
f010354d:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103550:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103553:	eb 6d                	jmp    f01035c2 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103555:	83 ec 08             	sub    $0x8,%esp
f0103558:	ff 75 cc             	pushl  -0x34(%ebp)
f010355b:	57                   	push   %edi
f010355c:	e8 7e 04 00 00       	call   f01039df <strnlen>
f0103561:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103564:	29 c2                	sub    %eax,%edx
f0103566:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0103569:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010356c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103570:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103573:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103576:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103578:	eb 10                	jmp    f010358a <.L36+0x66>
					putch(padc, putdat);
f010357a:	83 ec 08             	sub    $0x8,%esp
f010357d:	56                   	push   %esi
f010357e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103581:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103584:	83 ef 01             	sub    $0x1,%edi
f0103587:	83 c4 10             	add    $0x10,%esp
f010358a:	85 ff                	test   %edi,%edi
f010358c:	7f ec                	jg     f010357a <.L36+0x56>
f010358e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103591:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103594:	85 d2                	test   %edx,%edx
f0103596:	b8 00 00 00 00       	mov    $0x0,%eax
f010359b:	0f 49 c2             	cmovns %edx,%eax
f010359e:	29 c2                	sub    %eax,%edx
f01035a0:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01035a3:	89 75 0c             	mov    %esi,0xc(%ebp)
f01035a6:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01035a9:	eb 17                	jmp    f01035c2 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01035ab:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01035af:	75 30                	jne    f01035e1 <.L36+0xbd>
					putch(ch, putdat);
f01035b1:	83 ec 08             	sub    $0x8,%esp
f01035b4:	ff 75 0c             	pushl  0xc(%ebp)
f01035b7:	50                   	push   %eax
f01035b8:	ff 55 08             	call   *0x8(%ebp)
f01035bb:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01035be:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01035c2:	83 c7 01             	add    $0x1,%edi
f01035c5:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01035c9:	0f be c2             	movsbl %dl,%eax
f01035cc:	85 c0                	test   %eax,%eax
f01035ce:	74 52                	je     f0103622 <.L36+0xfe>
f01035d0:	85 f6                	test   %esi,%esi
f01035d2:	78 d7                	js     f01035ab <.L36+0x87>
f01035d4:	83 ee 01             	sub    $0x1,%esi
f01035d7:	79 d2                	jns    f01035ab <.L36+0x87>
f01035d9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01035dc:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01035df:	eb 32                	jmp    f0103613 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01035e1:	0f be d2             	movsbl %dl,%edx
f01035e4:	83 ea 20             	sub    $0x20,%edx
f01035e7:	83 fa 5e             	cmp    $0x5e,%edx
f01035ea:	76 c5                	jbe    f01035b1 <.L36+0x8d>
					putch('?', putdat);
f01035ec:	83 ec 08             	sub    $0x8,%esp
f01035ef:	ff 75 0c             	pushl  0xc(%ebp)
f01035f2:	6a 3f                	push   $0x3f
f01035f4:	ff 55 08             	call   *0x8(%ebp)
f01035f7:	83 c4 10             	add    $0x10,%esp
f01035fa:	eb c2                	jmp    f01035be <.L36+0x9a>
f01035fc:	89 75 0c             	mov    %esi,0xc(%ebp)
f01035ff:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103602:	eb be                	jmp    f01035c2 <.L36+0x9e>
				putch(' ', putdat);
f0103604:	83 ec 08             	sub    $0x8,%esp
f0103607:	56                   	push   %esi
f0103608:	6a 20                	push   $0x20
f010360a:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010360d:	83 ef 01             	sub    $0x1,%edi
f0103610:	83 c4 10             	add    $0x10,%esp
f0103613:	85 ff                	test   %edi,%edi
f0103615:	7f ed                	jg     f0103604 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0103617:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010361a:	89 45 14             	mov    %eax,0x14(%ebp)
f010361d:	e9 7b 01 00 00       	jmp    f010379d <.L35+0x45>
f0103622:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103625:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103628:	eb e9                	jmp    f0103613 <.L36+0xef>

f010362a <.L31>:
f010362a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010362d:	83 f9 01             	cmp    $0x1,%ecx
f0103630:	7e 40                	jle    f0103672 <.L31+0x48>
		return va_arg(*ap, long long);
f0103632:	8b 45 14             	mov    0x14(%ebp),%eax
f0103635:	8b 50 04             	mov    0x4(%eax),%edx
f0103638:	8b 00                	mov    (%eax),%eax
f010363a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010363d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103640:	8b 45 14             	mov    0x14(%ebp),%eax
f0103643:	8d 40 08             	lea    0x8(%eax),%eax
f0103646:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103649:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010364d:	79 55                	jns    f01036a4 <.L31+0x7a>
				putch('-', putdat);
f010364f:	83 ec 08             	sub    $0x8,%esp
f0103652:	56                   	push   %esi
f0103653:	6a 2d                	push   $0x2d
f0103655:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103658:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010365b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010365e:	f7 da                	neg    %edx
f0103660:	83 d1 00             	adc    $0x0,%ecx
f0103663:	f7 d9                	neg    %ecx
f0103665:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103668:	b8 0a 00 00 00       	mov    $0xa,%eax
f010366d:	e9 10 01 00 00       	jmp    f0103782 <.L35+0x2a>
	else if (lflag)
f0103672:	85 c9                	test   %ecx,%ecx
f0103674:	75 17                	jne    f010368d <.L31+0x63>
		return va_arg(*ap, int);
f0103676:	8b 45 14             	mov    0x14(%ebp),%eax
f0103679:	8b 00                	mov    (%eax),%eax
f010367b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010367e:	99                   	cltd   
f010367f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103682:	8b 45 14             	mov    0x14(%ebp),%eax
f0103685:	8d 40 04             	lea    0x4(%eax),%eax
f0103688:	89 45 14             	mov    %eax,0x14(%ebp)
f010368b:	eb bc                	jmp    f0103649 <.L31+0x1f>
		return va_arg(*ap, long);
f010368d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103690:	8b 00                	mov    (%eax),%eax
f0103692:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103695:	99                   	cltd   
f0103696:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103699:	8b 45 14             	mov    0x14(%ebp),%eax
f010369c:	8d 40 04             	lea    0x4(%eax),%eax
f010369f:	89 45 14             	mov    %eax,0x14(%ebp)
f01036a2:	eb a5                	jmp    f0103649 <.L31+0x1f>
			num = getint(&ap, lflag);
f01036a4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01036a7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01036aa:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036af:	e9 ce 00 00 00       	jmp    f0103782 <.L35+0x2a>

f01036b4 <.L37>:
f01036b4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01036b7:	83 f9 01             	cmp    $0x1,%ecx
f01036ba:	7e 18                	jle    f01036d4 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f01036bc:	8b 45 14             	mov    0x14(%ebp),%eax
f01036bf:	8b 10                	mov    (%eax),%edx
f01036c1:	8b 48 04             	mov    0x4(%eax),%ecx
f01036c4:	8d 40 08             	lea    0x8(%eax),%eax
f01036c7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01036ca:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036cf:	e9 ae 00 00 00       	jmp    f0103782 <.L35+0x2a>
	else if (lflag)
f01036d4:	85 c9                	test   %ecx,%ecx
f01036d6:	75 1a                	jne    f01036f2 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f01036d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01036db:	8b 10                	mov    (%eax),%edx
f01036dd:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036e2:	8d 40 04             	lea    0x4(%eax),%eax
f01036e5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01036e8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036ed:	e9 90 00 00 00       	jmp    f0103782 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01036f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01036f5:	8b 10                	mov    (%eax),%edx
f01036f7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036fc:	8d 40 04             	lea    0x4(%eax),%eax
f01036ff:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103702:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103707:	eb 79                	jmp    f0103782 <.L35+0x2a>

f0103709 <.L34>:
f0103709:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010370c:	83 f9 01             	cmp    $0x1,%ecx
f010370f:	7e 15                	jle    f0103726 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f0103711:	8b 45 14             	mov    0x14(%ebp),%eax
f0103714:	8b 10                	mov    (%eax),%edx
f0103716:	8b 48 04             	mov    0x4(%eax),%ecx
f0103719:	8d 40 08             	lea    0x8(%eax),%eax
f010371c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010371f:	b8 08 00 00 00       	mov    $0x8,%eax
f0103724:	eb 5c                	jmp    f0103782 <.L35+0x2a>
	else if (lflag)
f0103726:	85 c9                	test   %ecx,%ecx
f0103728:	75 17                	jne    f0103741 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f010372a:	8b 45 14             	mov    0x14(%ebp),%eax
f010372d:	8b 10                	mov    (%eax),%edx
f010372f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103734:	8d 40 04             	lea    0x4(%eax),%eax
f0103737:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010373a:	b8 08 00 00 00       	mov    $0x8,%eax
f010373f:	eb 41                	jmp    f0103782 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103741:	8b 45 14             	mov    0x14(%ebp),%eax
f0103744:	8b 10                	mov    (%eax),%edx
f0103746:	b9 00 00 00 00       	mov    $0x0,%ecx
f010374b:	8d 40 04             	lea    0x4(%eax),%eax
f010374e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103751:	b8 08 00 00 00       	mov    $0x8,%eax
f0103756:	eb 2a                	jmp    f0103782 <.L35+0x2a>

f0103758 <.L35>:
			putch('0', putdat);
f0103758:	83 ec 08             	sub    $0x8,%esp
f010375b:	56                   	push   %esi
f010375c:	6a 30                	push   $0x30
f010375e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103761:	83 c4 08             	add    $0x8,%esp
f0103764:	56                   	push   %esi
f0103765:	6a 78                	push   $0x78
f0103767:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010376a:	8b 45 14             	mov    0x14(%ebp),%eax
f010376d:	8b 10                	mov    (%eax),%edx
f010376f:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103774:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103777:	8d 40 04             	lea    0x4(%eax),%eax
f010377a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010377d:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103782:	83 ec 0c             	sub    $0xc,%esp
f0103785:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103789:	57                   	push   %edi
f010378a:	ff 75 e0             	pushl  -0x20(%ebp)
f010378d:	50                   	push   %eax
f010378e:	51                   	push   %ecx
f010378f:	52                   	push   %edx
f0103790:	89 f2                	mov    %esi,%edx
f0103792:	8b 45 08             	mov    0x8(%ebp),%eax
f0103795:	e8 20 fb ff ff       	call   f01032ba <printnum>
			break;
f010379a:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010379d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01037a0:	83 c7 01             	add    $0x1,%edi
f01037a3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01037a7:	83 f8 25             	cmp    $0x25,%eax
f01037aa:	0f 84 2d fc ff ff    	je     f01033dd <vprintfmt+0x1f>
			if (ch == '\0')
f01037b0:	85 c0                	test   %eax,%eax
f01037b2:	0f 84 91 00 00 00    	je     f0103849 <.L22+0x21>
			putch(ch, putdat);
f01037b8:	83 ec 08             	sub    $0x8,%esp
f01037bb:	56                   	push   %esi
f01037bc:	50                   	push   %eax
f01037bd:	ff 55 08             	call   *0x8(%ebp)
f01037c0:	83 c4 10             	add    $0x10,%esp
f01037c3:	eb db                	jmp    f01037a0 <.L35+0x48>

f01037c5 <.L38>:
f01037c5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01037c8:	83 f9 01             	cmp    $0x1,%ecx
f01037cb:	7e 15                	jle    f01037e2 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01037cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01037d0:	8b 10                	mov    (%eax),%edx
f01037d2:	8b 48 04             	mov    0x4(%eax),%ecx
f01037d5:	8d 40 08             	lea    0x8(%eax),%eax
f01037d8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01037db:	b8 10 00 00 00       	mov    $0x10,%eax
f01037e0:	eb a0                	jmp    f0103782 <.L35+0x2a>
	else if (lflag)
f01037e2:	85 c9                	test   %ecx,%ecx
f01037e4:	75 17                	jne    f01037fd <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01037e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01037e9:	8b 10                	mov    (%eax),%edx
f01037eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037f0:	8d 40 04             	lea    0x4(%eax),%eax
f01037f3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01037f6:	b8 10 00 00 00       	mov    $0x10,%eax
f01037fb:	eb 85                	jmp    f0103782 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01037fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103800:	8b 10                	mov    (%eax),%edx
f0103802:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103807:	8d 40 04             	lea    0x4(%eax),%eax
f010380a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010380d:	b8 10 00 00 00       	mov    $0x10,%eax
f0103812:	e9 6b ff ff ff       	jmp    f0103782 <.L35+0x2a>

f0103817 <.L25>:
			putch(ch, putdat);
f0103817:	83 ec 08             	sub    $0x8,%esp
f010381a:	56                   	push   %esi
f010381b:	6a 25                	push   $0x25
f010381d:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103820:	83 c4 10             	add    $0x10,%esp
f0103823:	e9 75 ff ff ff       	jmp    f010379d <.L35+0x45>

f0103828 <.L22>:
			putch('%', putdat);
f0103828:	83 ec 08             	sub    $0x8,%esp
f010382b:	56                   	push   %esi
f010382c:	6a 25                	push   $0x25
f010382e:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103831:	83 c4 10             	add    $0x10,%esp
f0103834:	89 f8                	mov    %edi,%eax
f0103836:	eb 03                	jmp    f010383b <.L22+0x13>
f0103838:	83 e8 01             	sub    $0x1,%eax
f010383b:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010383f:	75 f7                	jne    f0103838 <.L22+0x10>
f0103841:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103844:	e9 54 ff ff ff       	jmp    f010379d <.L35+0x45>
}
f0103849:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010384c:	5b                   	pop    %ebx
f010384d:	5e                   	pop    %esi
f010384e:	5f                   	pop    %edi
f010384f:	5d                   	pop    %ebp
f0103850:	c3                   	ret    

f0103851 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103851:	55                   	push   %ebp
f0103852:	89 e5                	mov    %esp,%ebp
f0103854:	53                   	push   %ebx
f0103855:	83 ec 14             	sub    $0x14,%esp
f0103858:	e8 f2 c8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010385d:	81 c3 af 3a 01 00    	add    $0x13aaf,%ebx
f0103863:	8b 45 08             	mov    0x8(%ebp),%eax
f0103866:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103869:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010386c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103870:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103873:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010387a:	85 c0                	test   %eax,%eax
f010387c:	74 2b                	je     f01038a9 <vsnprintf+0x58>
f010387e:	85 d2                	test   %edx,%edx
f0103880:	7e 27                	jle    f01038a9 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103882:	ff 75 14             	pushl  0x14(%ebp)
f0103885:	ff 75 10             	pushl  0x10(%ebp)
f0103888:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010388b:	50                   	push   %eax
f010388c:	8d 83 78 c0 fe ff    	lea    -0x13f88(%ebx),%eax
f0103892:	50                   	push   %eax
f0103893:	e8 26 fb ff ff       	call   f01033be <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103898:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010389b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010389e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01038a1:	83 c4 10             	add    $0x10,%esp
}
f01038a4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01038a7:	c9                   	leave  
f01038a8:	c3                   	ret    
		return -E_INVAL;
f01038a9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01038ae:	eb f4                	jmp    f01038a4 <vsnprintf+0x53>

f01038b0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01038b0:	55                   	push   %ebp
f01038b1:	89 e5                	mov    %esp,%ebp
f01038b3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01038b6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01038b9:	50                   	push   %eax
f01038ba:	ff 75 10             	pushl  0x10(%ebp)
f01038bd:	ff 75 0c             	pushl  0xc(%ebp)
f01038c0:	ff 75 08             	pushl  0x8(%ebp)
f01038c3:	e8 89 ff ff ff       	call   f0103851 <vsnprintf>
	va_end(ap);

	return rc;
}
f01038c8:	c9                   	leave  
f01038c9:	c3                   	ret    

f01038ca <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01038ca:	55                   	push   %ebp
f01038cb:	89 e5                	mov    %esp,%ebp
f01038cd:	57                   	push   %edi
f01038ce:	56                   	push   %esi
f01038cf:	53                   	push   %ebx
f01038d0:	83 ec 1c             	sub    $0x1c,%esp
f01038d3:	e8 77 c8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01038d8:	81 c3 34 3a 01 00    	add    $0x13a34,%ebx
f01038de:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01038e1:	85 c0                	test   %eax,%eax
f01038e3:	74 13                	je     f01038f8 <readline+0x2e>
		cprintf("%s", prompt);
f01038e5:	83 ec 08             	sub    $0x8,%esp
f01038e8:	50                   	push   %eax
f01038e9:	8d 83 20 d9 fe ff    	lea    -0x126e0(%ebx),%eax
f01038ef:	50                   	push   %eax
f01038f0:	e8 39 f6 ff ff       	call   f0102f2e <cprintf>
f01038f5:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01038f8:	83 ec 0c             	sub    $0xc,%esp
f01038fb:	6a 00                	push   $0x0
f01038fd:	e8 e5 cd ff ff       	call   f01006e7 <iscons>
f0103902:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103905:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103908:	bf 00 00 00 00       	mov    $0x0,%edi
f010390d:	eb 46                	jmp    f0103955 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010390f:	83 ec 08             	sub    $0x8,%esp
f0103912:	50                   	push   %eax
f0103913:	8d 83 d4 dd fe ff    	lea    -0x1222c(%ebx),%eax
f0103919:	50                   	push   %eax
f010391a:	e8 0f f6 ff ff       	call   f0102f2e <cprintf>
			return NULL;
f010391f:	83 c4 10             	add    $0x10,%esp
f0103922:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103927:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010392a:	5b                   	pop    %ebx
f010392b:	5e                   	pop    %esi
f010392c:	5f                   	pop    %edi
f010392d:	5d                   	pop    %ebp
f010392e:	c3                   	ret    
			if (echoing)
f010392f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103933:	75 05                	jne    f010393a <readline+0x70>
			i--;
f0103935:	83 ef 01             	sub    $0x1,%edi
f0103938:	eb 1b                	jmp    f0103955 <readline+0x8b>
				cputchar('\b');
f010393a:	83 ec 0c             	sub    $0xc,%esp
f010393d:	6a 08                	push   $0x8
f010393f:	e8 82 cd ff ff       	call   f01006c6 <cputchar>
f0103944:	83 c4 10             	add    $0x10,%esp
f0103947:	eb ec                	jmp    f0103935 <readline+0x6b>
			buf[i++] = c;
f0103949:	89 f0                	mov    %esi,%eax
f010394b:	88 84 3b 94 1f 00 00 	mov    %al,0x1f94(%ebx,%edi,1)
f0103952:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103955:	e8 7c cd ff ff       	call   f01006d6 <getchar>
f010395a:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010395c:	85 c0                	test   %eax,%eax
f010395e:	78 af                	js     f010390f <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103960:	83 f8 08             	cmp    $0x8,%eax
f0103963:	0f 94 c2             	sete   %dl
f0103966:	83 f8 7f             	cmp    $0x7f,%eax
f0103969:	0f 94 c0             	sete   %al
f010396c:	08 c2                	or     %al,%dl
f010396e:	74 04                	je     f0103974 <readline+0xaa>
f0103970:	85 ff                	test   %edi,%edi
f0103972:	7f bb                	jg     f010392f <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103974:	83 fe 1f             	cmp    $0x1f,%esi
f0103977:	7e 1c                	jle    f0103995 <readline+0xcb>
f0103979:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010397f:	7f 14                	jg     f0103995 <readline+0xcb>
			if (echoing)
f0103981:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103985:	74 c2                	je     f0103949 <readline+0x7f>
				cputchar(c);
f0103987:	83 ec 0c             	sub    $0xc,%esp
f010398a:	56                   	push   %esi
f010398b:	e8 36 cd ff ff       	call   f01006c6 <cputchar>
f0103990:	83 c4 10             	add    $0x10,%esp
f0103993:	eb b4                	jmp    f0103949 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103995:	83 fe 0a             	cmp    $0xa,%esi
f0103998:	74 05                	je     f010399f <readline+0xd5>
f010399a:	83 fe 0d             	cmp    $0xd,%esi
f010399d:	75 b6                	jne    f0103955 <readline+0x8b>
			if (echoing)
f010399f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039a3:	75 13                	jne    f01039b8 <readline+0xee>
			buf[i] = 0;
f01039a5:	c6 84 3b 94 1f 00 00 	movb   $0x0,0x1f94(%ebx,%edi,1)
f01039ac:	00 
			return buf;
f01039ad:	8d 83 94 1f 00 00    	lea    0x1f94(%ebx),%eax
f01039b3:	e9 6f ff ff ff       	jmp    f0103927 <readline+0x5d>
				cputchar('\n');
f01039b8:	83 ec 0c             	sub    $0xc,%esp
f01039bb:	6a 0a                	push   $0xa
f01039bd:	e8 04 cd ff ff       	call   f01006c6 <cputchar>
f01039c2:	83 c4 10             	add    $0x10,%esp
f01039c5:	eb de                	jmp    f01039a5 <readline+0xdb>

f01039c7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01039c7:	55                   	push   %ebp
f01039c8:	89 e5                	mov    %esp,%ebp
f01039ca:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01039cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01039d2:	eb 03                	jmp    f01039d7 <strlen+0x10>
		n++;
f01039d4:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01039d7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01039db:	75 f7                	jne    f01039d4 <strlen+0xd>
	return n;
}
f01039dd:	5d                   	pop    %ebp
f01039de:	c3                   	ret    

f01039df <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01039df:	55                   	push   %ebp
f01039e0:	89 e5                	mov    %esp,%ebp
f01039e2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01039e5:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01039ed:	eb 03                	jmp    f01039f2 <strnlen+0x13>
		n++;
f01039ef:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039f2:	39 d0                	cmp    %edx,%eax
f01039f4:	74 06                	je     f01039fc <strnlen+0x1d>
f01039f6:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01039fa:	75 f3                	jne    f01039ef <strnlen+0x10>
	return n;
}
f01039fc:	5d                   	pop    %ebp
f01039fd:	c3                   	ret    

f01039fe <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01039fe:	55                   	push   %ebp
f01039ff:	89 e5                	mov    %esp,%ebp
f0103a01:	53                   	push   %ebx
f0103a02:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a08:	89 c2                	mov    %eax,%edx
f0103a0a:	83 c1 01             	add    $0x1,%ecx
f0103a0d:	83 c2 01             	add    $0x1,%edx
f0103a10:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103a14:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103a17:	84 db                	test   %bl,%bl
f0103a19:	75 ef                	jne    f0103a0a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103a1b:	5b                   	pop    %ebx
f0103a1c:	5d                   	pop    %ebp
f0103a1d:	c3                   	ret    

f0103a1e <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103a1e:	55                   	push   %ebp
f0103a1f:	89 e5                	mov    %esp,%ebp
f0103a21:	53                   	push   %ebx
f0103a22:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a25:	53                   	push   %ebx
f0103a26:	e8 9c ff ff ff       	call   f01039c7 <strlen>
f0103a2b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103a2e:	ff 75 0c             	pushl  0xc(%ebp)
f0103a31:	01 d8                	add    %ebx,%eax
f0103a33:	50                   	push   %eax
f0103a34:	e8 c5 ff ff ff       	call   f01039fe <strcpy>
	return dst;
}
f0103a39:	89 d8                	mov    %ebx,%eax
f0103a3b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a3e:	c9                   	leave  
f0103a3f:	c3                   	ret    

f0103a40 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a40:	55                   	push   %ebp
f0103a41:	89 e5                	mov    %esp,%ebp
f0103a43:	56                   	push   %esi
f0103a44:	53                   	push   %ebx
f0103a45:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a48:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a4b:	89 f3                	mov    %esi,%ebx
f0103a4d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a50:	89 f2                	mov    %esi,%edx
f0103a52:	eb 0f                	jmp    f0103a63 <strncpy+0x23>
		*dst++ = *src;
f0103a54:	83 c2 01             	add    $0x1,%edx
f0103a57:	0f b6 01             	movzbl (%ecx),%eax
f0103a5a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103a5d:	80 39 01             	cmpb   $0x1,(%ecx)
f0103a60:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103a63:	39 da                	cmp    %ebx,%edx
f0103a65:	75 ed                	jne    f0103a54 <strncpy+0x14>
	}
	return ret;
}
f0103a67:	89 f0                	mov    %esi,%eax
f0103a69:	5b                   	pop    %ebx
f0103a6a:	5e                   	pop    %esi
f0103a6b:	5d                   	pop    %ebp
f0103a6c:	c3                   	ret    

f0103a6d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103a6d:	55                   	push   %ebp
f0103a6e:	89 e5                	mov    %esp,%ebp
f0103a70:	56                   	push   %esi
f0103a71:	53                   	push   %ebx
f0103a72:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a75:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a78:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103a7b:	89 f0                	mov    %esi,%eax
f0103a7d:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103a81:	85 c9                	test   %ecx,%ecx
f0103a83:	75 0b                	jne    f0103a90 <strlcpy+0x23>
f0103a85:	eb 17                	jmp    f0103a9e <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103a87:	83 c2 01             	add    $0x1,%edx
f0103a8a:	83 c0 01             	add    $0x1,%eax
f0103a8d:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103a90:	39 d8                	cmp    %ebx,%eax
f0103a92:	74 07                	je     f0103a9b <strlcpy+0x2e>
f0103a94:	0f b6 0a             	movzbl (%edx),%ecx
f0103a97:	84 c9                	test   %cl,%cl
f0103a99:	75 ec                	jne    f0103a87 <strlcpy+0x1a>
		*dst = '\0';
f0103a9b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103a9e:	29 f0                	sub    %esi,%eax
}
f0103aa0:	5b                   	pop    %ebx
f0103aa1:	5e                   	pop    %esi
f0103aa2:	5d                   	pop    %ebp
f0103aa3:	c3                   	ret    

f0103aa4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103aa4:	55                   	push   %ebp
f0103aa5:	89 e5                	mov    %esp,%ebp
f0103aa7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103aaa:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103aad:	eb 06                	jmp    f0103ab5 <strcmp+0x11>
		p++, q++;
f0103aaf:	83 c1 01             	add    $0x1,%ecx
f0103ab2:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103ab5:	0f b6 01             	movzbl (%ecx),%eax
f0103ab8:	84 c0                	test   %al,%al
f0103aba:	74 04                	je     f0103ac0 <strcmp+0x1c>
f0103abc:	3a 02                	cmp    (%edx),%al
f0103abe:	74 ef                	je     f0103aaf <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103ac0:	0f b6 c0             	movzbl %al,%eax
f0103ac3:	0f b6 12             	movzbl (%edx),%edx
f0103ac6:	29 d0                	sub    %edx,%eax
}
f0103ac8:	5d                   	pop    %ebp
f0103ac9:	c3                   	ret    

f0103aca <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103aca:	55                   	push   %ebp
f0103acb:	89 e5                	mov    %esp,%ebp
f0103acd:	53                   	push   %ebx
f0103ace:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ad1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ad4:	89 c3                	mov    %eax,%ebx
f0103ad6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103ad9:	eb 06                	jmp    f0103ae1 <strncmp+0x17>
		n--, p++, q++;
f0103adb:	83 c0 01             	add    $0x1,%eax
f0103ade:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103ae1:	39 d8                	cmp    %ebx,%eax
f0103ae3:	74 16                	je     f0103afb <strncmp+0x31>
f0103ae5:	0f b6 08             	movzbl (%eax),%ecx
f0103ae8:	84 c9                	test   %cl,%cl
f0103aea:	74 04                	je     f0103af0 <strncmp+0x26>
f0103aec:	3a 0a                	cmp    (%edx),%cl
f0103aee:	74 eb                	je     f0103adb <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103af0:	0f b6 00             	movzbl (%eax),%eax
f0103af3:	0f b6 12             	movzbl (%edx),%edx
f0103af6:	29 d0                	sub    %edx,%eax
}
f0103af8:	5b                   	pop    %ebx
f0103af9:	5d                   	pop    %ebp
f0103afa:	c3                   	ret    
		return 0;
f0103afb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b00:	eb f6                	jmp    f0103af8 <strncmp+0x2e>

f0103b02 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b02:	55                   	push   %ebp
f0103b03:	89 e5                	mov    %esp,%ebp
f0103b05:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b08:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b0c:	0f b6 10             	movzbl (%eax),%edx
f0103b0f:	84 d2                	test   %dl,%dl
f0103b11:	74 09                	je     f0103b1c <strchr+0x1a>
		if (*s == c)
f0103b13:	38 ca                	cmp    %cl,%dl
f0103b15:	74 0a                	je     f0103b21 <strchr+0x1f>
	for (; *s; s++)
f0103b17:	83 c0 01             	add    $0x1,%eax
f0103b1a:	eb f0                	jmp    f0103b0c <strchr+0xa>
			return (char *) s;
	return 0;
f0103b1c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b21:	5d                   	pop    %ebp
f0103b22:	c3                   	ret    

f0103b23 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b23:	55                   	push   %ebp
f0103b24:	89 e5                	mov    %esp,%ebp
f0103b26:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b29:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b2d:	eb 03                	jmp    f0103b32 <strfind+0xf>
f0103b2f:	83 c0 01             	add    $0x1,%eax
f0103b32:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103b35:	38 ca                	cmp    %cl,%dl
f0103b37:	74 04                	je     f0103b3d <strfind+0x1a>
f0103b39:	84 d2                	test   %dl,%dl
f0103b3b:	75 f2                	jne    f0103b2f <strfind+0xc>
			break;
	return (char *) s;
}
f0103b3d:	5d                   	pop    %ebp
f0103b3e:	c3                   	ret    

f0103b3f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103b3f:	55                   	push   %ebp
f0103b40:	89 e5                	mov    %esp,%ebp
f0103b42:	57                   	push   %edi
f0103b43:	56                   	push   %esi
f0103b44:	53                   	push   %ebx
f0103b45:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103b48:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103b4b:	85 c9                	test   %ecx,%ecx
f0103b4d:	74 13                	je     f0103b62 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103b4f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103b55:	75 05                	jne    f0103b5c <memset+0x1d>
f0103b57:	f6 c1 03             	test   $0x3,%cl
f0103b5a:	74 0d                	je     f0103b69 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103b5c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b5f:	fc                   	cld    
f0103b60:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103b62:	89 f8                	mov    %edi,%eax
f0103b64:	5b                   	pop    %ebx
f0103b65:	5e                   	pop    %esi
f0103b66:	5f                   	pop    %edi
f0103b67:	5d                   	pop    %ebp
f0103b68:	c3                   	ret    
		c &= 0xFF;
f0103b69:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103b6d:	89 d3                	mov    %edx,%ebx
f0103b6f:	c1 e3 08             	shl    $0x8,%ebx
f0103b72:	89 d0                	mov    %edx,%eax
f0103b74:	c1 e0 18             	shl    $0x18,%eax
f0103b77:	89 d6                	mov    %edx,%esi
f0103b79:	c1 e6 10             	shl    $0x10,%esi
f0103b7c:	09 f0                	or     %esi,%eax
f0103b7e:	09 c2                	or     %eax,%edx
f0103b80:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103b82:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103b85:	89 d0                	mov    %edx,%eax
f0103b87:	fc                   	cld    
f0103b88:	f3 ab                	rep stos %eax,%es:(%edi)
f0103b8a:	eb d6                	jmp    f0103b62 <memset+0x23>

f0103b8c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103b8c:	55                   	push   %ebp
f0103b8d:	89 e5                	mov    %esp,%ebp
f0103b8f:	57                   	push   %edi
f0103b90:	56                   	push   %esi
f0103b91:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b94:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b97:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103b9a:	39 c6                	cmp    %eax,%esi
f0103b9c:	73 35                	jae    f0103bd3 <memmove+0x47>
f0103b9e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103ba1:	39 c2                	cmp    %eax,%edx
f0103ba3:	76 2e                	jbe    f0103bd3 <memmove+0x47>
		s += n;
		d += n;
f0103ba5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ba8:	89 d6                	mov    %edx,%esi
f0103baa:	09 fe                	or     %edi,%esi
f0103bac:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103bb2:	74 0c                	je     f0103bc0 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103bb4:	83 ef 01             	sub    $0x1,%edi
f0103bb7:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103bba:	fd                   	std    
f0103bbb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103bbd:	fc                   	cld    
f0103bbe:	eb 21                	jmp    f0103be1 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103bc0:	f6 c1 03             	test   $0x3,%cl
f0103bc3:	75 ef                	jne    f0103bb4 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103bc5:	83 ef 04             	sub    $0x4,%edi
f0103bc8:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103bcb:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103bce:	fd                   	std    
f0103bcf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103bd1:	eb ea                	jmp    f0103bbd <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103bd3:	89 f2                	mov    %esi,%edx
f0103bd5:	09 c2                	or     %eax,%edx
f0103bd7:	f6 c2 03             	test   $0x3,%dl
f0103bda:	74 09                	je     f0103be5 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103bdc:	89 c7                	mov    %eax,%edi
f0103bde:	fc                   	cld    
f0103bdf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103be1:	5e                   	pop    %esi
f0103be2:	5f                   	pop    %edi
f0103be3:	5d                   	pop    %ebp
f0103be4:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103be5:	f6 c1 03             	test   $0x3,%cl
f0103be8:	75 f2                	jne    f0103bdc <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103bea:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103bed:	89 c7                	mov    %eax,%edi
f0103bef:	fc                   	cld    
f0103bf0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103bf2:	eb ed                	jmp    f0103be1 <memmove+0x55>

f0103bf4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103bf4:	55                   	push   %ebp
f0103bf5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103bf7:	ff 75 10             	pushl  0x10(%ebp)
f0103bfa:	ff 75 0c             	pushl  0xc(%ebp)
f0103bfd:	ff 75 08             	pushl  0x8(%ebp)
f0103c00:	e8 87 ff ff ff       	call   f0103b8c <memmove>
}
f0103c05:	c9                   	leave  
f0103c06:	c3                   	ret    

f0103c07 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c07:	55                   	push   %ebp
f0103c08:	89 e5                	mov    %esp,%ebp
f0103c0a:	56                   	push   %esi
f0103c0b:	53                   	push   %ebx
f0103c0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c0f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c12:	89 c6                	mov    %eax,%esi
f0103c14:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c17:	39 f0                	cmp    %esi,%eax
f0103c19:	74 1c                	je     f0103c37 <memcmp+0x30>
		if (*s1 != *s2)
f0103c1b:	0f b6 08             	movzbl (%eax),%ecx
f0103c1e:	0f b6 1a             	movzbl (%edx),%ebx
f0103c21:	38 d9                	cmp    %bl,%cl
f0103c23:	75 08                	jne    f0103c2d <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103c25:	83 c0 01             	add    $0x1,%eax
f0103c28:	83 c2 01             	add    $0x1,%edx
f0103c2b:	eb ea                	jmp    f0103c17 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103c2d:	0f b6 c1             	movzbl %cl,%eax
f0103c30:	0f b6 db             	movzbl %bl,%ebx
f0103c33:	29 d8                	sub    %ebx,%eax
f0103c35:	eb 05                	jmp    f0103c3c <memcmp+0x35>
	}

	return 0;
f0103c37:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c3c:	5b                   	pop    %ebx
f0103c3d:	5e                   	pop    %esi
f0103c3e:	5d                   	pop    %ebp
f0103c3f:	c3                   	ret    

f0103c40 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103c40:	55                   	push   %ebp
f0103c41:	89 e5                	mov    %esp,%ebp
f0103c43:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c46:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103c49:	89 c2                	mov    %eax,%edx
f0103c4b:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103c4e:	39 d0                	cmp    %edx,%eax
f0103c50:	73 09                	jae    f0103c5b <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103c52:	38 08                	cmp    %cl,(%eax)
f0103c54:	74 05                	je     f0103c5b <memfind+0x1b>
	for (; s < ends; s++)
f0103c56:	83 c0 01             	add    $0x1,%eax
f0103c59:	eb f3                	jmp    f0103c4e <memfind+0xe>
			break;
	return (void *) s;
}
f0103c5b:	5d                   	pop    %ebp
f0103c5c:	c3                   	ret    

f0103c5d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103c5d:	55                   	push   %ebp
f0103c5e:	89 e5                	mov    %esp,%ebp
f0103c60:	57                   	push   %edi
f0103c61:	56                   	push   %esi
f0103c62:	53                   	push   %ebx
f0103c63:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c66:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103c69:	eb 03                	jmp    f0103c6e <strtol+0x11>
		s++;
f0103c6b:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103c6e:	0f b6 01             	movzbl (%ecx),%eax
f0103c71:	3c 20                	cmp    $0x20,%al
f0103c73:	74 f6                	je     f0103c6b <strtol+0xe>
f0103c75:	3c 09                	cmp    $0x9,%al
f0103c77:	74 f2                	je     f0103c6b <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103c79:	3c 2b                	cmp    $0x2b,%al
f0103c7b:	74 2e                	je     f0103cab <strtol+0x4e>
	int neg = 0;
f0103c7d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103c82:	3c 2d                	cmp    $0x2d,%al
f0103c84:	74 2f                	je     f0103cb5 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103c86:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103c8c:	75 05                	jne    f0103c93 <strtol+0x36>
f0103c8e:	80 39 30             	cmpb   $0x30,(%ecx)
f0103c91:	74 2c                	je     f0103cbf <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103c93:	85 db                	test   %ebx,%ebx
f0103c95:	75 0a                	jne    f0103ca1 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103c97:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103c9c:	80 39 30             	cmpb   $0x30,(%ecx)
f0103c9f:	74 28                	je     f0103cc9 <strtol+0x6c>
		base = 10;
f0103ca1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ca6:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103ca9:	eb 50                	jmp    f0103cfb <strtol+0x9e>
		s++;
f0103cab:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103cae:	bf 00 00 00 00       	mov    $0x0,%edi
f0103cb3:	eb d1                	jmp    f0103c86 <strtol+0x29>
		s++, neg = 1;
f0103cb5:	83 c1 01             	add    $0x1,%ecx
f0103cb8:	bf 01 00 00 00       	mov    $0x1,%edi
f0103cbd:	eb c7                	jmp    f0103c86 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103cbf:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103cc3:	74 0e                	je     f0103cd3 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103cc5:	85 db                	test   %ebx,%ebx
f0103cc7:	75 d8                	jne    f0103ca1 <strtol+0x44>
		s++, base = 8;
f0103cc9:	83 c1 01             	add    $0x1,%ecx
f0103ccc:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103cd1:	eb ce                	jmp    f0103ca1 <strtol+0x44>
		s += 2, base = 16;
f0103cd3:	83 c1 02             	add    $0x2,%ecx
f0103cd6:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103cdb:	eb c4                	jmp    f0103ca1 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103cdd:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103ce0:	89 f3                	mov    %esi,%ebx
f0103ce2:	80 fb 19             	cmp    $0x19,%bl
f0103ce5:	77 29                	ja     f0103d10 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103ce7:	0f be d2             	movsbl %dl,%edx
f0103cea:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103ced:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103cf0:	7d 30                	jge    f0103d22 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103cf2:	83 c1 01             	add    $0x1,%ecx
f0103cf5:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103cf9:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103cfb:	0f b6 11             	movzbl (%ecx),%edx
f0103cfe:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103d01:	89 f3                	mov    %esi,%ebx
f0103d03:	80 fb 09             	cmp    $0x9,%bl
f0103d06:	77 d5                	ja     f0103cdd <strtol+0x80>
			dig = *s - '0';
f0103d08:	0f be d2             	movsbl %dl,%edx
f0103d0b:	83 ea 30             	sub    $0x30,%edx
f0103d0e:	eb dd                	jmp    f0103ced <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103d10:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103d13:	89 f3                	mov    %esi,%ebx
f0103d15:	80 fb 19             	cmp    $0x19,%bl
f0103d18:	77 08                	ja     f0103d22 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103d1a:	0f be d2             	movsbl %dl,%edx
f0103d1d:	83 ea 37             	sub    $0x37,%edx
f0103d20:	eb cb                	jmp    f0103ced <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103d22:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103d26:	74 05                	je     f0103d2d <strtol+0xd0>
		*endptr = (char *) s;
f0103d28:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d2b:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103d2d:	89 c2                	mov    %eax,%edx
f0103d2f:	f7 da                	neg    %edx
f0103d31:	85 ff                	test   %edi,%edi
f0103d33:	0f 45 c2             	cmovne %edx,%eax
}
f0103d36:	5b                   	pop    %ebx
f0103d37:	5e                   	pop    %esi
f0103d38:	5f                   	pop    %edi
f0103d39:	5d                   	pop    %ebp
f0103d3a:	c3                   	ret    
f0103d3b:	66 90                	xchg   %ax,%ax
f0103d3d:	66 90                	xchg   %ax,%ax
f0103d3f:	90                   	nop

f0103d40 <__udivdi3>:
f0103d40:	55                   	push   %ebp
f0103d41:	57                   	push   %edi
f0103d42:	56                   	push   %esi
f0103d43:	53                   	push   %ebx
f0103d44:	83 ec 1c             	sub    $0x1c,%esp
f0103d47:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103d4b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103d4f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103d53:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103d57:	85 d2                	test   %edx,%edx
f0103d59:	75 35                	jne    f0103d90 <__udivdi3+0x50>
f0103d5b:	39 f3                	cmp    %esi,%ebx
f0103d5d:	0f 87 bd 00 00 00    	ja     f0103e20 <__udivdi3+0xe0>
f0103d63:	85 db                	test   %ebx,%ebx
f0103d65:	89 d9                	mov    %ebx,%ecx
f0103d67:	75 0b                	jne    f0103d74 <__udivdi3+0x34>
f0103d69:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d6e:	31 d2                	xor    %edx,%edx
f0103d70:	f7 f3                	div    %ebx
f0103d72:	89 c1                	mov    %eax,%ecx
f0103d74:	31 d2                	xor    %edx,%edx
f0103d76:	89 f0                	mov    %esi,%eax
f0103d78:	f7 f1                	div    %ecx
f0103d7a:	89 c6                	mov    %eax,%esi
f0103d7c:	89 e8                	mov    %ebp,%eax
f0103d7e:	89 f7                	mov    %esi,%edi
f0103d80:	f7 f1                	div    %ecx
f0103d82:	89 fa                	mov    %edi,%edx
f0103d84:	83 c4 1c             	add    $0x1c,%esp
f0103d87:	5b                   	pop    %ebx
f0103d88:	5e                   	pop    %esi
f0103d89:	5f                   	pop    %edi
f0103d8a:	5d                   	pop    %ebp
f0103d8b:	c3                   	ret    
f0103d8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d90:	39 f2                	cmp    %esi,%edx
f0103d92:	77 7c                	ja     f0103e10 <__udivdi3+0xd0>
f0103d94:	0f bd fa             	bsr    %edx,%edi
f0103d97:	83 f7 1f             	xor    $0x1f,%edi
f0103d9a:	0f 84 98 00 00 00    	je     f0103e38 <__udivdi3+0xf8>
f0103da0:	89 f9                	mov    %edi,%ecx
f0103da2:	b8 20 00 00 00       	mov    $0x20,%eax
f0103da7:	29 f8                	sub    %edi,%eax
f0103da9:	d3 e2                	shl    %cl,%edx
f0103dab:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103daf:	89 c1                	mov    %eax,%ecx
f0103db1:	89 da                	mov    %ebx,%edx
f0103db3:	d3 ea                	shr    %cl,%edx
f0103db5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103db9:	09 d1                	or     %edx,%ecx
f0103dbb:	89 f2                	mov    %esi,%edx
f0103dbd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103dc1:	89 f9                	mov    %edi,%ecx
f0103dc3:	d3 e3                	shl    %cl,%ebx
f0103dc5:	89 c1                	mov    %eax,%ecx
f0103dc7:	d3 ea                	shr    %cl,%edx
f0103dc9:	89 f9                	mov    %edi,%ecx
f0103dcb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103dcf:	d3 e6                	shl    %cl,%esi
f0103dd1:	89 eb                	mov    %ebp,%ebx
f0103dd3:	89 c1                	mov    %eax,%ecx
f0103dd5:	d3 eb                	shr    %cl,%ebx
f0103dd7:	09 de                	or     %ebx,%esi
f0103dd9:	89 f0                	mov    %esi,%eax
f0103ddb:	f7 74 24 08          	divl   0x8(%esp)
f0103ddf:	89 d6                	mov    %edx,%esi
f0103de1:	89 c3                	mov    %eax,%ebx
f0103de3:	f7 64 24 0c          	mull   0xc(%esp)
f0103de7:	39 d6                	cmp    %edx,%esi
f0103de9:	72 0c                	jb     f0103df7 <__udivdi3+0xb7>
f0103deb:	89 f9                	mov    %edi,%ecx
f0103ded:	d3 e5                	shl    %cl,%ebp
f0103def:	39 c5                	cmp    %eax,%ebp
f0103df1:	73 5d                	jae    f0103e50 <__udivdi3+0x110>
f0103df3:	39 d6                	cmp    %edx,%esi
f0103df5:	75 59                	jne    f0103e50 <__udivdi3+0x110>
f0103df7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103dfa:	31 ff                	xor    %edi,%edi
f0103dfc:	89 fa                	mov    %edi,%edx
f0103dfe:	83 c4 1c             	add    $0x1c,%esp
f0103e01:	5b                   	pop    %ebx
f0103e02:	5e                   	pop    %esi
f0103e03:	5f                   	pop    %edi
f0103e04:	5d                   	pop    %ebp
f0103e05:	c3                   	ret    
f0103e06:	8d 76 00             	lea    0x0(%esi),%esi
f0103e09:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103e10:	31 ff                	xor    %edi,%edi
f0103e12:	31 c0                	xor    %eax,%eax
f0103e14:	89 fa                	mov    %edi,%edx
f0103e16:	83 c4 1c             	add    $0x1c,%esp
f0103e19:	5b                   	pop    %ebx
f0103e1a:	5e                   	pop    %esi
f0103e1b:	5f                   	pop    %edi
f0103e1c:	5d                   	pop    %ebp
f0103e1d:	c3                   	ret    
f0103e1e:	66 90                	xchg   %ax,%ax
f0103e20:	31 ff                	xor    %edi,%edi
f0103e22:	89 e8                	mov    %ebp,%eax
f0103e24:	89 f2                	mov    %esi,%edx
f0103e26:	f7 f3                	div    %ebx
f0103e28:	89 fa                	mov    %edi,%edx
f0103e2a:	83 c4 1c             	add    $0x1c,%esp
f0103e2d:	5b                   	pop    %ebx
f0103e2e:	5e                   	pop    %esi
f0103e2f:	5f                   	pop    %edi
f0103e30:	5d                   	pop    %ebp
f0103e31:	c3                   	ret    
f0103e32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103e38:	39 f2                	cmp    %esi,%edx
f0103e3a:	72 06                	jb     f0103e42 <__udivdi3+0x102>
f0103e3c:	31 c0                	xor    %eax,%eax
f0103e3e:	39 eb                	cmp    %ebp,%ebx
f0103e40:	77 d2                	ja     f0103e14 <__udivdi3+0xd4>
f0103e42:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e47:	eb cb                	jmp    f0103e14 <__udivdi3+0xd4>
f0103e49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e50:	89 d8                	mov    %ebx,%eax
f0103e52:	31 ff                	xor    %edi,%edi
f0103e54:	eb be                	jmp    f0103e14 <__udivdi3+0xd4>
f0103e56:	66 90                	xchg   %ax,%ax
f0103e58:	66 90                	xchg   %ax,%ax
f0103e5a:	66 90                	xchg   %ax,%ax
f0103e5c:	66 90                	xchg   %ax,%ax
f0103e5e:	66 90                	xchg   %ax,%ax

f0103e60 <__umoddi3>:
f0103e60:	55                   	push   %ebp
f0103e61:	57                   	push   %edi
f0103e62:	56                   	push   %esi
f0103e63:	53                   	push   %ebx
f0103e64:	83 ec 1c             	sub    $0x1c,%esp
f0103e67:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103e6b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103e6f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103e73:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103e77:	85 ed                	test   %ebp,%ebp
f0103e79:	89 f0                	mov    %esi,%eax
f0103e7b:	89 da                	mov    %ebx,%edx
f0103e7d:	75 19                	jne    f0103e98 <__umoddi3+0x38>
f0103e7f:	39 df                	cmp    %ebx,%edi
f0103e81:	0f 86 b1 00 00 00    	jbe    f0103f38 <__umoddi3+0xd8>
f0103e87:	f7 f7                	div    %edi
f0103e89:	89 d0                	mov    %edx,%eax
f0103e8b:	31 d2                	xor    %edx,%edx
f0103e8d:	83 c4 1c             	add    $0x1c,%esp
f0103e90:	5b                   	pop    %ebx
f0103e91:	5e                   	pop    %esi
f0103e92:	5f                   	pop    %edi
f0103e93:	5d                   	pop    %ebp
f0103e94:	c3                   	ret    
f0103e95:	8d 76 00             	lea    0x0(%esi),%esi
f0103e98:	39 dd                	cmp    %ebx,%ebp
f0103e9a:	77 f1                	ja     f0103e8d <__umoddi3+0x2d>
f0103e9c:	0f bd cd             	bsr    %ebp,%ecx
f0103e9f:	83 f1 1f             	xor    $0x1f,%ecx
f0103ea2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103ea6:	0f 84 b4 00 00 00    	je     f0103f60 <__umoddi3+0x100>
f0103eac:	b8 20 00 00 00       	mov    $0x20,%eax
f0103eb1:	89 c2                	mov    %eax,%edx
f0103eb3:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103eb7:	29 c2                	sub    %eax,%edx
f0103eb9:	89 c1                	mov    %eax,%ecx
f0103ebb:	89 f8                	mov    %edi,%eax
f0103ebd:	d3 e5                	shl    %cl,%ebp
f0103ebf:	89 d1                	mov    %edx,%ecx
f0103ec1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103ec5:	d3 e8                	shr    %cl,%eax
f0103ec7:	09 c5                	or     %eax,%ebp
f0103ec9:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103ecd:	89 c1                	mov    %eax,%ecx
f0103ecf:	d3 e7                	shl    %cl,%edi
f0103ed1:	89 d1                	mov    %edx,%ecx
f0103ed3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103ed7:	89 df                	mov    %ebx,%edi
f0103ed9:	d3 ef                	shr    %cl,%edi
f0103edb:	89 c1                	mov    %eax,%ecx
f0103edd:	89 f0                	mov    %esi,%eax
f0103edf:	d3 e3                	shl    %cl,%ebx
f0103ee1:	89 d1                	mov    %edx,%ecx
f0103ee3:	89 fa                	mov    %edi,%edx
f0103ee5:	d3 e8                	shr    %cl,%eax
f0103ee7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103eec:	09 d8                	or     %ebx,%eax
f0103eee:	f7 f5                	div    %ebp
f0103ef0:	d3 e6                	shl    %cl,%esi
f0103ef2:	89 d1                	mov    %edx,%ecx
f0103ef4:	f7 64 24 08          	mull   0x8(%esp)
f0103ef8:	39 d1                	cmp    %edx,%ecx
f0103efa:	89 c3                	mov    %eax,%ebx
f0103efc:	89 d7                	mov    %edx,%edi
f0103efe:	72 06                	jb     f0103f06 <__umoddi3+0xa6>
f0103f00:	75 0e                	jne    f0103f10 <__umoddi3+0xb0>
f0103f02:	39 c6                	cmp    %eax,%esi
f0103f04:	73 0a                	jae    f0103f10 <__umoddi3+0xb0>
f0103f06:	2b 44 24 08          	sub    0x8(%esp),%eax
f0103f0a:	19 ea                	sbb    %ebp,%edx
f0103f0c:	89 d7                	mov    %edx,%edi
f0103f0e:	89 c3                	mov    %eax,%ebx
f0103f10:	89 ca                	mov    %ecx,%edx
f0103f12:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103f17:	29 de                	sub    %ebx,%esi
f0103f19:	19 fa                	sbb    %edi,%edx
f0103f1b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0103f1f:	89 d0                	mov    %edx,%eax
f0103f21:	d3 e0                	shl    %cl,%eax
f0103f23:	89 d9                	mov    %ebx,%ecx
f0103f25:	d3 ee                	shr    %cl,%esi
f0103f27:	d3 ea                	shr    %cl,%edx
f0103f29:	09 f0                	or     %esi,%eax
f0103f2b:	83 c4 1c             	add    $0x1c,%esp
f0103f2e:	5b                   	pop    %ebx
f0103f2f:	5e                   	pop    %esi
f0103f30:	5f                   	pop    %edi
f0103f31:	5d                   	pop    %ebp
f0103f32:	c3                   	ret    
f0103f33:	90                   	nop
f0103f34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f38:	85 ff                	test   %edi,%edi
f0103f3a:	89 f9                	mov    %edi,%ecx
f0103f3c:	75 0b                	jne    f0103f49 <__umoddi3+0xe9>
f0103f3e:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f43:	31 d2                	xor    %edx,%edx
f0103f45:	f7 f7                	div    %edi
f0103f47:	89 c1                	mov    %eax,%ecx
f0103f49:	89 d8                	mov    %ebx,%eax
f0103f4b:	31 d2                	xor    %edx,%edx
f0103f4d:	f7 f1                	div    %ecx
f0103f4f:	89 f0                	mov    %esi,%eax
f0103f51:	f7 f1                	div    %ecx
f0103f53:	e9 31 ff ff ff       	jmp    f0103e89 <__umoddi3+0x29>
f0103f58:	90                   	nop
f0103f59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f60:	39 dd                	cmp    %ebx,%ebp
f0103f62:	72 08                	jb     f0103f6c <__umoddi3+0x10c>
f0103f64:	39 f7                	cmp    %esi,%edi
f0103f66:	0f 87 21 ff ff ff    	ja     f0103e8d <__umoddi3+0x2d>
f0103f6c:	89 da                	mov    %ebx,%edx
f0103f6e:	89 f0                	mov    %esi,%eax
f0103f70:	29 f8                	sub    %edi,%eax
f0103f72:	19 ea                	sbb    %ebp,%edx
f0103f74:	e9 14 ff ff ff       	jmp    f0103e8d <__umoddi3+0x2d>
