
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f010004c:	81 c3 bc 32 01 00    	add    $0x132bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 50 11 f0    	mov    $0xf0115060,%edx
f0100058:	c7 c0 a0 56 11 f0    	mov    $0xf01156a0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 f7 1c 00 00       	call   f0101d60 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 98 ee fe ff    	lea    -0x11168(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 c9 10 00 00       	call   f010114b <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 aa 0b 00 00       	call   f0100c31 <mem_init>
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
f01000a7:	81 c3 61 32 01 00    	add    $0x13261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 a4 56 11 f0    	mov    $0xf01156a4,%eax
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
f01000da:	8d 83 b3 ee fe ff    	lea    -0x1114d(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 65 10 00 00       	call   f010114b <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 24 10 00 00       	call   f0101114 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 ef ee fe ff    	lea    -0x11111(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 4d 10 00 00       	call   f010114b <cprintf>
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
f010010d:	81 c3 fb 31 01 00    	add    $0x131fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 cb ee fe ff    	lea    -0x11135(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 20 10 00 00       	call   f010114b <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 dd 0f 00 00       	call   f0101114 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 ef ee fe ff    	lea    -0x11111(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 06 10 00 00       	call   f010114b <cprintf>
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
f010017c:	81 c3 8c 31 01 00    	add    $0x1318c,%ebx
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
f01001c7:	81 c3 41 31 01 00    	add    $0x13141,%ebx
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
f0100217:	0f b6 84 13 18 f0 fe 	movzbl -0x10fe8(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 18 ef fe 	movzbl -0x110e8(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 e5 ee fe ff    	lea    -0x1111b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 d5 0e 00 00       	call   f010114b <cprintf>
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
f01002b1:	0f b6 84 13 18 f0 fe 	movzbl -0x10fe8(%ebx,%edx,1),%eax
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
f01002fd:	81 c3 0b 30 01 00    	add    $0x1300b,%ebx
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
f01004d2:	e8 d6 18 00 00       	call   f0101dad <memmove>
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
f010050a:	05 fe 2d 01 00       	add    $0x12dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b ce fe ff    	lea    -0x131b5(%eax),%eax
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
f0100538:	05 d0 2d 01 00       	add    $0x12dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 ce fe ff    	lea    -0x1314b(%eax),%eax
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
f0100556:	81 c3 b2 2d 01 00    	add    $0x12db2,%ebx
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
f01005b2:	81 c3 56 2d 01 00    	add    $0x12d56,%ebx
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
f01006b5:	8d 83 f1 ee fe ff    	lea    -0x1110f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 8a 0a 00 00       	call   f010114b <cprintf>
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
f01006ff:	81 c3 09 2c 01 00    	add    $0x12c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 18 f1 fe ff    	lea    -0x10ee8(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 36 f1 fe ff    	lea    -0x10eca(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 3b f1 fe ff    	lea    -0x10ec5(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 29 0a 00 00       	call   f010114b <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 f8 f1 fe ff    	lea    -0x10e08(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 44 f1 fe ff    	lea    -0x10ebc(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 12 0a 00 00       	call   f010114b <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 20 f2 fe ff    	lea    -0x10de0(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 4d f1 fe ff    	lea    -0x10eb3(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 fb 09 00 00       	call   f010114b <cprintf>
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
f010076a:	81 c3 9e 2b 01 00    	add    $0x12b9e,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100770:	8d 83 57 f1 fe ff    	lea    -0x10ea9(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 cf 09 00 00       	call   f010114b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f0100785:	8d 83 44 f2 fe ff    	lea    -0x10dbc(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 ba 09 00 00       	call   f010114b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 6c f2 fe ff    	lea    -0x10d94(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 9d 09 00 00       	call   f010114b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 99 21 10 f0    	mov    $0xf0102199,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 90 f2 fe ff    	lea    -0x10d70(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 80 09 00 00       	call   f010114b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 50 11 f0    	mov    $0xf0115060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 b4 f2 fe ff    	lea    -0x10d4c(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 63 09 00 00       	call   f010114b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 a0 56 11 f0    	mov    $0xf01156a0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 d8 f2 fe ff    	lea    -0x10d28(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 46 09 00 00       	call   f010114b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 fc f2 fe ff    	lea    -0x10d04(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 2b 09 00 00       	call   f010114b <cprintf>
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
f010083b:	81 c3 cd 2a 01 00    	add    $0x12acd,%ebx
	// Your code here.
	cprintf("Stack backtrace:\n");
f0100841:	8d 83 70 f1 fe ff    	lea    -0x10e90(%ebx),%eax
f0100847:	50                   	push   %eax
f0100848:	e8 fe 08 00 00       	call   f010114b <cprintf>

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
f0100852:	8d 83 82 f1 fe ff    	lea    -0x10e7e(%ebx),%eax
f0100858:	89 45 b8             	mov    %eax,-0x48(%ebp)
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
f010085b:	8d 83 9d f1 fe ff    	lea    -0x10e63(%ebx),%eax
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
f010087c:	e8 ca 08 00 00       	call   f010114b <cprintf>
f0100881:	8d 77 08             	lea    0x8(%edi),%esi
f0100884:	83 c7 1c             	add    $0x1c,%edi
f0100887:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	ff 36                	pushl  (%esi)
f010088f:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100892:	e8 b4 08 00 00       	call   f010114b <cprintf>
f0100897:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	39 fe                	cmp    %edi,%esi
f010089f:	75 e9                	jne    f010088a <mon_backtrace+0x5d>
		}
		cprintf("\n");
f01008a1:	83 ec 0c             	sub    $0xc,%esp
f01008a4:	8d 83 ef ee fe ff    	lea    -0x11111(%ebx),%eax
f01008aa:	50                   	push   %eax
f01008ab:	e8 9b 08 00 00       	call   f010114b <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008b0:	83 c4 08             	add    $0x8,%esp
f01008b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008b6:	50                   	push   %eax
f01008b7:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008ba:	57                   	push   %edi
f01008bb:	e8 8f 09 00 00       	call   f010124f <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f01008c0:	83 c4 0c             	add    $0xc,%esp
f01008c3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008c9:	8d 83 a3 f1 fe ff    	lea    -0x10e5d(%ebx),%eax
f01008cf:	50                   	push   %eax
f01008d0:	e8 76 08 00 00       	call   f010114b <cprintf>
		// for (int i = 0; i < info.eip_fn_namelen;++i){
		// 	cprintf("%c", info.eip_fn_name[i]);
		// }
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f01008d5:	89 f8                	mov    %edi,%eax
f01008d7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008da:	50                   	push   %eax
f01008db:	ff 75 d8             	pushl  -0x28(%ebp)
f01008de:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e1:	8d 83 b3 f1 fe ff    	lea    -0x10e4d(%ebx),%eax
f01008e7:	50                   	push   %eax
f01008e8:	e8 5e 08 00 00       	call   f010114b <cprintf>
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
f0100916:	81 c3 f2 29 01 00    	add    $0x129f2,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010091c:	8d 83 28 f3 fe ff    	lea    -0x10cd8(%ebx),%eax
f0100922:	50                   	push   %eax
f0100923:	e8 23 08 00 00       	call   f010114b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100928:	8d 83 4c f3 fe ff    	lea    -0x10cb4(%ebx),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 15 08 00 00       	call   f010114b <cprintf>
f0100936:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100939:	8d bb c0 f1 fe ff    	lea    -0x10e40(%ebx),%edi
f010093f:	eb 4a                	jmp    f010098b <monitor+0x83>
f0100941:	83 ec 08             	sub    $0x8,%esp
f0100944:	0f be c0             	movsbl %al,%eax
f0100947:	50                   	push   %eax
f0100948:	57                   	push   %edi
f0100949:	e8 d5 13 00 00       	call   f0101d23 <strchr>
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
f010097c:	8d 83 c5 f1 fe ff    	lea    -0x10e3b(%ebx),%eax
f0100982:	50                   	push   %eax
f0100983:	e8 c3 07 00 00       	call   f010114b <cprintf>
f0100988:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010098b:	8d 83 bc f1 fe ff    	lea    -0x10e44(%ebx),%eax
f0100991:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100994:	83 ec 0c             	sub    $0xc,%esp
f0100997:	ff 75 a4             	pushl  -0x5c(%ebp)
f010099a:	e8 4c 11 00 00       	call   f0101aeb <readline>
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
f01009ca:	e8 54 13 00 00       	call   f0101d23 <strchr>
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
f0100a05:	e8 bb 12 00 00       	call   f0101cc5 <strcmp>
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
f0100a26:	8d 83 e2 f1 fe ff    	lea    -0x10e1e(%ebx),%eax
f0100a2c:	50                   	push   %eax
f0100a2d:	e8 19 07 00 00       	call   f010114b <cprintf>
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
f0100a6a:	e8 51 06 00 00       	call   f01010c0 <__x86.get_pc_thunk.dx>
f0100a6f:	81 c2 99 28 01 00    	add    $0x12899,%edx
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
f0100a8c:	c7 c1 a0 56 11 f0    	mov    $0xf01156a0,%ecx
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
f0100ace:	81 c3 3a 28 01 00    	add    $0x1283a,%ebx
f0100ad4:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ad6:	50                   	push   %eax
f0100ad7:	e8 e8 05 00 00       	call   f01010c4 <mc146818_read>
f0100adc:	89 c6                	mov    %eax,%esi
f0100ade:	83 c7 01             	add    $0x1,%edi
f0100ae1:	89 3c 24             	mov    %edi,(%esp)
f0100ae4:	e8 db 05 00 00       	call   f01010c4 <mc146818_read>
f0100ae9:	c1 e0 08             	shl    $0x8,%eax
f0100aec:	09 f0                	or     %esi,%eax
}
f0100aee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100af1:	5b                   	pop    %ebx
f0100af2:	5e                   	pop    %esi
f0100af3:	5f                   	pop    %edi
f0100af4:	5d                   	pop    %ebp
f0100af5:	c3                   	ret    

f0100af6 <page_init>:
// memory via the page_free_list.
//
// 完成这个操作后，将只能使用page_alloc 和 page_free 函数分配释放页面，不能在使用boot_alloc
void
page_init(void)
{
f0100af6:	55                   	push   %ebp
f0100af7:	89 e5                	mov    %esp,%ebp
f0100af9:	57                   	push   %edi
f0100afa:	56                   	push   %esi
f0100afb:	53                   	push   %ebx
f0100afc:	83 ec 3c             	sub    $0x3c,%esp
f0100aff:	e8 ed fb ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100b04:	05 04 28 01 00       	add    $0x12804,%eax
f0100b09:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b0c:	8b 88 94 1f 00 00    	mov    0x1f94(%eax),%ecx
f0100b12:	89 4d d8             	mov    %ecx,-0x28(%ebp)
	//     page tables and other data structures?
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100b15:	c6 45 d7 00          	movb   $0x0,-0x29(%ebp)
f0100b19:	be 00 00 00 00       	mov    $0x0,%esi
f0100b1e:	c7 c1 a8 56 11 f0    	mov    $0xf01156a8,%ecx
f0100b24:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		if(i==0){
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
			continue;
		}
		physaddr_t addr_i = page2pa(pages + i);
f0100b27:	c7 c1 b0 56 11 f0    	mov    $0xf01156b0,%ecx
f0100b2d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
			continue;
		}
		addr_i = (physaddr_t)page2kva(pages + i);
		if(addr_i>=(physaddr_t)kern_pgdir&&addr_i<(physaddr_t)(pages+npages)){
f0100b30:	c7 c1 ac 56 11 f0    	mov    $0xf01156ac,%ecx
f0100b36:	89 4d d0             	mov    %ecx,-0x30(%ebp)
			pages[i].pp_link = NULL;
			continue;
		}
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100b39:	c7 c1 b0 56 11 f0    	mov    $0xf01156b0,%ecx
f0100b3f:	89 4d c8             	mov    %ecx,-0x38(%ebp)
			pages[i].pp_ref = 1;
f0100b42:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	for (i = 0; i < npages; i++) {
f0100b45:	eb 14                	jmp    f0100b5b <page_init+0x65>
			pages[i].pp_ref = 1;
f0100b47:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100b4a:	8b 00                	mov    (%eax),%eax
f0100b4c:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100b52:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for (i = 0; i < npages; i++) {
f0100b58:	83 c6 01             	add    $0x1,%esi
f0100b5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b5e:	8b 00                	mov    (%eax),%eax
f0100b60:	39 f0                	cmp    %esi,%eax
f0100b62:	0f 86 ad 00 00 00    	jbe    f0100c15 <page_init+0x11f>
		if(i==0){
f0100b68:	85 f6                	test   %esi,%esi
f0100b6a:	74 db                	je     f0100b47 <page_init+0x51>
		physaddr_t addr_i = page2pa(pages + i);
f0100b6c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b6f:	8b 1f                	mov    (%edi),%ebx
f0100b71:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100b74:	8d 0c f5 00 00 00 00 	lea    0x0(,%esi,8),%ecx
f0100b7b:	01 cb                	add    %ecx,%ebx

// (pp - pages)为页号，(pp - pages) << PGSHIFT 为页号左移12位，也就是该页的物理地址
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b7d:	89 ca                	mov    %ecx,%edx
f0100b7f:	c1 e2 09             	shl    $0x9,%edx
		if(addr_i>=IOPHYSMEM&&addr_i<EXTPHYSMEM){
f0100b82:	8d ba 00 00 f6 ff    	lea    -0xa0000(%edx),%edi
f0100b88:	81 ff ff ff 05 00    	cmp    $0x5ffff,%edi
f0100b8e:	77 0e                	ja     f0100b9e <page_init+0xa8>
			pages[i].pp_ref = 1;
f0100b90:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
			pages[i].pp_link = NULL;
f0100b96:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
			continue;
f0100b9c:	eb ba                	jmp    f0100b58 <page_init+0x62>
	if (PGNUM(pa) >= npages)
f0100b9e:	89 d7                	mov    %edx,%edi
f0100ba0:	c1 ef 0c             	shr    $0xc,%edi
f0100ba3:	39 f8                	cmp    %edi,%eax
f0100ba5:	76 30                	jbe    f0100bd7 <page_init+0xe1>
	return (void *)(pa + KERNBASE);
f0100ba7:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
		if(addr_i>=(physaddr_t)kern_pgdir&&addr_i<(physaddr_t)(pages+npages)){
f0100bad:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0100bb0:	39 17                	cmp    %edx,(%edi)
f0100bb2:	77 0a                	ja     f0100bbe <page_init+0xc8>
f0100bb4:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100bb7:	8d 04 c7             	lea    (%edi,%eax,8),%eax
f0100bba:	39 d0                	cmp    %edx,%eax
f0100bbc:	77 46                	ja     f0100c04 <page_init+0x10e>
		pages[i].pp_ref = 0;
f0100bbe:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0100bc4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100bc7:	89 03                	mov    %eax,(%ebx)
		page_free_list = &pages[i];
f0100bc9:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100bcc:	03 08                	add    (%eax),%ecx
f0100bce:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100bd1:	c6 45 d7 01          	movb   $0x1,-0x29(%ebp)
f0100bd5:	eb 81                	jmp    f0100b58 <page_init+0x62>
f0100bd7:	80 7d d7 00          	cmpb   $0x0,-0x29(%ebp)
f0100bdb:	75 19                	jne    f0100bf6 <page_init+0x100>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bdd:	52                   	push   %edx
f0100bde:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100be1:	8d 83 74 f3 fe ff    	lea    -0x10c8c(%ebx),%eax
f0100be7:	50                   	push   %eax
f0100be8:	6a 59                	push   $0x59
f0100bea:	8d 83 e0 f4 fe ff    	lea    -0x10b20(%ebx),%eax
f0100bf0:	50                   	push   %eax
f0100bf1:	e8 a3 f4 ff ff       	call   f0100099 <_panic>
f0100bf6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100bf9:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100bfc:	89 b0 94 1f 00 00    	mov    %esi,0x1f94(%eax)
f0100c02:	eb d9                	jmp    f0100bdd <page_init+0xe7>
			pages[i].pp_ref = 1;
f0100c04:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
			pages[i].pp_link = NULL;
f0100c0a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
			continue;
f0100c10:	e9 43 ff ff ff       	jmp    f0100b58 <page_init+0x62>
f0100c15:	80 7d d7 00          	cmpb   $0x0,-0x29(%ebp)
f0100c19:	75 08                	jne    f0100c23 <page_init+0x12d>
	}
}
f0100c1b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c1e:	5b                   	pop    %ebx
f0100c1f:	5e                   	pop    %esi
f0100c20:	5f                   	pop    %edi
f0100c21:	5d                   	pop    %ebp
f0100c22:	c3                   	ret    
f0100c23:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100c26:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100c29:	89 b0 94 1f 00 00    	mov    %esi,0x1f94(%eax)
f0100c2f:	eb ea                	jmp    f0100c1b <page_init+0x125>

f0100c31 <mem_init>:
{
f0100c31:	55                   	push   %ebp
f0100c32:	89 e5                	mov    %esp,%ebp
f0100c34:	57                   	push   %edi
f0100c35:	56                   	push   %esi
f0100c36:	53                   	push   %ebx
f0100c37:	83 ec 3c             	sub    $0x3c,%esp
f0100c3a:	e8 10 f5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c3f:	81 c3 c9 26 01 00    	add    $0x126c9,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100c45:	b8 15 00 00 00       	mov    $0x15,%eax
f0100c4a:	e8 71 fe ff ff       	call   f0100ac0 <nvram_read>
f0100c4f:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f0100c51:	b8 17 00 00 00       	mov    $0x17,%eax
f0100c56:	e8 65 fe ff ff       	call   f0100ac0 <nvram_read>
f0100c5b:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100c5d:	b8 34 00 00 00       	mov    $0x34,%eax
f0100c62:	e8 59 fe ff ff       	call   f0100ac0 <nvram_read>
f0100c67:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100c6a:	85 c0                	test   %eax,%eax
f0100c6c:	75 0e                	jne    f0100c7c <mem_init+0x4b>
		totalmem = basemem;
f0100c6e:	89 f0                	mov    %esi,%eax
	else if (extmem)
f0100c70:	85 ff                	test   %edi,%edi
f0100c72:	74 0d                	je     f0100c81 <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f0100c74:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f0100c7a:	eb 05                	jmp    f0100c81 <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100c7c:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100c81:	89 c1                	mov    %eax,%ecx
f0100c83:	c1 e9 02             	shr    $0x2,%ecx
f0100c86:	c7 c2 a8 56 11 f0    	mov    $0xf01156a8,%edx
f0100c8c:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100c8e:	89 c2                	mov    %eax,%edx
f0100c90:	29 f2                	sub    %esi,%edx
f0100c92:	52                   	push   %edx
f0100c93:	56                   	push   %esi
f0100c94:	50                   	push   %eax
f0100c95:	8d 83 98 f3 fe ff    	lea    -0x10c68(%ebx),%eax
f0100c9b:	50                   	push   %eax
f0100c9c:	e8 aa 04 00 00       	call   f010114b <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);    // 初始占一整页
f0100ca1:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100ca6:	e8 bc fd ff ff       	call   f0100a67 <boot_alloc>
f0100cab:	c7 c6 ac 56 11 f0    	mov    $0xf01156ac,%esi
f0100cb1:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);   // 初始化为0
f0100cb3:	83 c4 0c             	add    $0xc,%esp
f0100cb6:	68 00 10 00 00       	push   $0x1000
f0100cbb:	6a 00                	push   $0x0
f0100cbd:	50                   	push   %eax
f0100cbe:	e8 9d 10 00 00       	call   f0101d60 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100cc3:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0100cc5:	83 c4 10             	add    $0x10,%esp
f0100cc8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ccd:	77 19                	ja     f0100ce8 <mem_init+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ccf:	50                   	push   %eax
f0100cd0:	8d 83 d4 f3 fe ff    	lea    -0x10c2c(%ebx),%eax
f0100cd6:	50                   	push   %eax
f0100cd7:	68 9b 00 00 00       	push   $0x9b
f0100cdc:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100ce2:	50                   	push   %eax
f0100ce3:	e8 b1 f3 ff ff       	call   f0100099 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100ce8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100cee:	83 ca 05             	or     $0x5,%edx
f0100cf1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0100cf7:	c7 c6 a8 56 11 f0    	mov    $0xf01156a8,%esi
f0100cfd:	8b 06                	mov    (%esi),%eax
f0100cff:	c1 e0 03             	shl    $0x3,%eax
f0100d02:	e8 60 fd ff ff       	call   f0100a67 <boot_alloc>
f0100d07:	c7 c2 b0 56 11 f0    	mov    $0xf01156b0,%edx
f0100d0d:	89 02                	mov    %eax,(%edx)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100d0f:	83 ec 04             	sub    $0x4,%esp
f0100d12:	8b 16                	mov    (%esi),%edx
f0100d14:	c1 e2 03             	shl    $0x3,%edx
f0100d17:	52                   	push   %edx
f0100d18:	6a 00                	push   $0x0
f0100d1a:	50                   	push   %eax
f0100d1b:	e8 40 10 00 00       	call   f0101d60 <memset>
	page_init();
f0100d20:	e8 d1 fd ff ff       	call   f0100af6 <page_init>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d25:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0100d2b:	83 c4 10             	add    $0x10,%esp
f0100d2e:	85 c0                	test   %eax,%eax
f0100d30:	74 5d                	je     f0100d8f <mem_init+0x15e>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100d32:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100d35:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100d38:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d3b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100d3e:	c7 c6 b0 56 11 f0    	mov    $0xf01156b0,%esi
f0100d44:	89 c2                	mov    %eax,%edx
f0100d46:	2b 16                	sub    (%esi),%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100d48:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100d4e:	0f 95 c2             	setne  %dl
f0100d51:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100d54:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100d58:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100d5a:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d5e:	8b 00                	mov    (%eax),%eax
f0100d60:	85 c0                	test   %eax,%eax
f0100d62:	75 e0                	jne    f0100d44 <mem_init+0x113>
		}
		*tp[1] = 0;
f0100d64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d67:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100d6d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d70:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d73:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100d75:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100d78:	89 b3 94 1f 00 00    	mov    %esi,0x1f94(%ebx)
f0100d7e:	c7 c7 b0 56 11 f0    	mov    $0xf01156b0,%edi
	if (PGNUM(pa) >= npages)
f0100d84:	c7 c0 a8 56 11 f0    	mov    $0xf01156a8,%eax
f0100d8a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d8d:	eb 33                	jmp    f0100dc2 <mem_init+0x191>
		panic("'page_free_list' is a null pointer!");
f0100d8f:	83 ec 04             	sub    $0x4,%esp
f0100d92:	8d 83 f8 f3 fe ff    	lea    -0x10c08(%ebx),%eax
f0100d98:	50                   	push   %eax
f0100d99:	68 e3 01 00 00       	push   $0x1e3
f0100d9e:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100da4:	50                   	push   %eax
f0100da5:	e8 ef f2 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100daa:	52                   	push   %edx
f0100dab:	8d 83 74 f3 fe ff    	lea    -0x10c8c(%ebx),%eax
f0100db1:	50                   	push   %eax
f0100db2:	6a 59                	push   $0x59
f0100db4:	8d 83 e0 f4 fe ff    	lea    -0x10b20(%ebx),%eax
f0100dba:	50                   	push   %eax
f0100dbb:	e8 d9 f2 ff ff       	call   f0100099 <_panic>
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dc0:	8b 36                	mov    (%esi),%esi
f0100dc2:	85 f6                	test   %esi,%esi
f0100dc4:	74 3d                	je     f0100e03 <mem_init+0x1d2>
	return (pp - pages) << PGSHIFT;
f0100dc6:	89 f0                	mov    %esi,%eax
f0100dc8:	2b 07                	sub    (%edi),%eax
f0100dca:	c1 f8 03             	sar    $0x3,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100dcd:	89 c2                	mov    %eax,%edx
f0100dcf:	c1 e2 0c             	shl    $0xc,%edx
f0100dd2:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100dd7:	75 e7                	jne    f0100dc0 <mem_init+0x18f>
	if (PGNUM(pa) >= npages)
f0100dd9:	89 d0                	mov    %edx,%eax
f0100ddb:	c1 e8 0c             	shr    $0xc,%eax
f0100dde:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100de1:	3b 01                	cmp    (%ecx),%eax
f0100de3:	73 c5                	jae    f0100daa <mem_init+0x179>
			memset(page2kva(pp), 0x97, 128);
f0100de5:	83 ec 04             	sub    $0x4,%esp
f0100de8:	68 80 00 00 00       	push   $0x80
f0100ded:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100df2:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100df8:	52                   	push   %edx
f0100df9:	e8 62 0f 00 00       	call   f0101d60 <memset>
f0100dfe:	83 c4 10             	add    $0x10,%esp
f0100e01:	eb bd                	jmp    f0100dc0 <mem_init+0x18f>

	first_free_page = (char *) boot_alloc(0);
f0100e03:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e08:	e8 5a fc ff ff       	call   f0100a67 <boot_alloc>
f0100e0d:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e10:	8b 93 94 1f 00 00    	mov    0x1f94(%ebx),%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e16:	c7 c0 b0 56 11 f0    	mov    $0xf01156b0,%eax
f0100e1c:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100e1e:	c7 c0 a8 56 11 f0    	mov    $0xf01156a8,%eax
f0100e24:	8b 00                	mov    (%eax),%eax
f0100e26:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100e29:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100e2c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e2f:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100e32:	bf 00 00 00 00       	mov    $0x0,%edi
f0100e37:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0100e3a:	e9 f2 00 00 00       	jmp    f0100f31 <mem_init+0x300>
		assert(pp >= pages);
f0100e3f:	8d 83 fa f4 fe ff    	lea    -0x10b06(%ebx),%eax
f0100e45:	50                   	push   %eax
f0100e46:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0100e4c:	50                   	push   %eax
f0100e4d:	68 fd 01 00 00       	push   $0x1fd
f0100e52:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100e58:	50                   	push   %eax
f0100e59:	e8 3b f2 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100e5e:	8d 83 1b f5 fe ff    	lea    -0x10ae5(%ebx),%eax
f0100e64:	50                   	push   %eax
f0100e65:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0100e6b:	50                   	push   %eax
f0100e6c:	68 fe 01 00 00       	push   $0x1fe
f0100e71:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100e77:	50                   	push   %eax
f0100e78:	e8 1c f2 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e7d:	8d 83 1c f4 fe ff    	lea    -0x10be4(%ebx),%eax
f0100e83:	50                   	push   %eax
f0100e84:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0100e8a:	50                   	push   %eax
f0100e8b:	68 ff 01 00 00       	push   $0x1ff
f0100e90:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100e96:	50                   	push   %eax
f0100e97:	e8 fd f1 ff ff       	call   f0100099 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100e9c:	8d 83 2f f5 fe ff    	lea    -0x10ad1(%ebx),%eax
f0100ea2:	50                   	push   %eax
f0100ea3:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0100ea9:	50                   	push   %eax
f0100eaa:	68 02 02 00 00       	push   $0x202
f0100eaf:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100eb5:	50                   	push   %eax
f0100eb6:	e8 de f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ebb:	8d 83 40 f5 fe ff    	lea    -0x10ac0(%ebx),%eax
f0100ec1:	50                   	push   %eax
f0100ec2:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0100ec8:	50                   	push   %eax
f0100ec9:	68 03 02 00 00       	push   $0x203
f0100ece:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100ed4:	50                   	push   %eax
f0100ed5:	e8 bf f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100eda:	8d 83 50 f4 fe ff    	lea    -0x10bb0(%ebx),%eax
f0100ee0:	50                   	push   %eax
f0100ee1:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0100ee7:	50                   	push   %eax
f0100ee8:	68 04 02 00 00       	push   $0x204
f0100eed:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100ef3:	50                   	push   %eax
f0100ef4:	e8 a0 f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ef9:	8d 83 59 f5 fe ff    	lea    -0x10aa7(%ebx),%eax
f0100eff:	50                   	push   %eax
f0100f00:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0100f06:	50                   	push   %eax
f0100f07:	68 05 02 00 00       	push   $0x205
f0100f0c:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100f12:	50                   	push   %eax
f0100f13:	e8 81 f1 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100f18:	89 c6                	mov    %eax,%esi
f0100f1a:	c1 ee 0c             	shr    $0xc,%esi
f0100f1d:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f0100f20:	76 71                	jbe    f0100f93 <mem_init+0x362>
	return (void *)(pa + KERNBASE);
f0100f22:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f27:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100f2a:	77 7d                	ja     f0100fa9 <mem_init+0x378>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
		else
			++nfree_extmem;
f0100f2c:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f2f:	8b 12                	mov    (%edx),%edx
f0100f31:	85 d2                	test   %edx,%edx
f0100f33:	0f 84 8f 00 00 00    	je     f0100fc8 <mem_init+0x397>
		assert(pp >= pages);
f0100f39:	39 d1                	cmp    %edx,%ecx
f0100f3b:	0f 87 fe fe ff ff    	ja     f0100e3f <mem_init+0x20e>
		assert(pp < pages + npages);
f0100f41:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100f44:	0f 83 14 ff ff ff    	jae    f0100e5e <mem_init+0x22d>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f4a:	89 d0                	mov    %edx,%eax
f0100f4c:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f4f:	a8 07                	test   $0x7,%al
f0100f51:	0f 85 26 ff ff ff    	jne    f0100e7d <mem_init+0x24c>
	return (pp - pages) << PGSHIFT;
f0100f57:	c1 f8 03             	sar    $0x3,%eax
f0100f5a:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100f5d:	85 c0                	test   %eax,%eax
f0100f5f:	0f 84 37 ff ff ff    	je     f0100e9c <mem_init+0x26b>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f65:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f6a:	0f 84 4b ff ff ff    	je     f0100ebb <mem_init+0x28a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f70:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f75:	0f 84 5f ff ff ff    	je     f0100eda <mem_init+0x2a9>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f7b:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f80:	0f 84 73 ff ff ff    	je     f0100ef9 <mem_init+0x2c8>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f86:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f8b:	77 8b                	ja     f0100f18 <mem_init+0x2e7>
			++nfree_basemem;
f0100f8d:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100f91:	eb 9c                	jmp    f0100f2f <mem_init+0x2fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f93:	50                   	push   %eax
f0100f94:	8d 83 74 f3 fe ff    	lea    -0x10c8c(%ebx),%eax
f0100f9a:	50                   	push   %eax
f0100f9b:	6a 59                	push   $0x59
f0100f9d:	8d 83 e0 f4 fe ff    	lea    -0x10b20(%ebx),%eax
f0100fa3:	50                   	push   %eax
f0100fa4:	e8 f0 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fa9:	8d 83 74 f4 fe ff    	lea    -0x10b8c(%ebx),%eax
f0100faf:	50                   	push   %eax
f0100fb0:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0100fb6:	50                   	push   %eax
f0100fb7:	68 06 02 00 00       	push   $0x206
f0100fbc:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0100fc2:	50                   	push   %eax
f0100fc3:	e8 d1 f0 ff ff       	call   f0100099 <_panic>
f0100fc8:	8b 75 cc             	mov    -0x34(%ebp),%esi
	}

	assert(nfree_basemem > 0);
f0100fcb:	85 f6                	test   %esi,%esi
f0100fcd:	7e 29                	jle    f0100ff8 <mem_init+0x3c7>
	assert(nfree_extmem > 0);
f0100fcf:	85 ff                	test   %edi,%edi
f0100fd1:	7e 44                	jle    f0101017 <mem_init+0x3e6>

	cprintf("check_page_free_list() succeeded!\n");
f0100fd3:	83 ec 0c             	sub    $0xc,%esp
f0100fd6:	8d 83 bc f4 fe ff    	lea    -0x10b44(%ebx),%eax
f0100fdc:	50                   	push   %eax
f0100fdd:	e8 69 01 00 00       	call   f010114b <cprintf>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100fe2:	83 c4 10             	add    $0x10,%esp
f0100fe5:	c7 c0 b0 56 11 f0    	mov    $0xf01156b0,%eax
f0100feb:	83 38 00             	cmpl   $0x0,(%eax)
f0100fee:	74 46                	je     f0101036 <mem_init+0x405>
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100ff0:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0100ff6:	eb 5b                	jmp    f0101053 <mem_init+0x422>
	assert(nfree_basemem > 0);
f0100ff8:	8d 83 73 f5 fe ff    	lea    -0x10a8d(%ebx),%eax
f0100ffe:	50                   	push   %eax
f0100fff:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0101005:	50                   	push   %eax
f0101006:	68 0e 02 00 00       	push   $0x20e
f010100b:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0101011:	50                   	push   %eax
f0101012:	e8 82 f0 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0101017:	8d 83 85 f5 fe ff    	lea    -0x10a7b(%ebx),%eax
f010101d:	50                   	push   %eax
f010101e:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0101024:	50                   	push   %eax
f0101025:	68 0f 02 00 00       	push   $0x20f
f010102a:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0101030:	50                   	push   %eax
f0101031:	e8 63 f0 ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101036:	83 ec 04             	sub    $0x4,%esp
f0101039:	8d 83 96 f5 fe ff    	lea    -0x10a6a(%ebx),%eax
f010103f:	50                   	push   %eax
f0101040:	68 22 02 00 00       	push   $0x222
f0101045:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f010104b:	50                   	push   %eax
f010104c:	e8 48 f0 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101051:	8b 00                	mov    (%eax),%eax
f0101053:	85 c0                	test   %eax,%eax
f0101055:	75 fa                	jne    f0101051 <mem_init+0x420>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101057:	8d 83 b1 f5 fe ff    	lea    -0x10a4f(%ebx),%eax
f010105d:	50                   	push   %eax
f010105e:	8d 83 06 f5 fe ff    	lea    -0x10afa(%ebx),%eax
f0101064:	50                   	push   %eax
f0101065:	68 2a 02 00 00       	push   $0x22a
f010106a:	8d 83 ee f4 fe ff    	lea    -0x10b12(%ebx),%eax
f0101070:	50                   	push   %eax
f0101071:	e8 23 f0 ff ff       	call   f0100099 <_panic>

f0101076 <page_alloc>:
{
f0101076:	55                   	push   %ebp
f0101077:	89 e5                	mov    %esp,%ebp
}
f0101079:	b8 00 00 00 00       	mov    $0x0,%eax
f010107e:	5d                   	pop    %ebp
f010107f:	c3                   	ret    

f0101080 <page_free>:
{
f0101080:	55                   	push   %ebp
f0101081:	89 e5                	mov    %esp,%ebp
}
f0101083:	5d                   	pop    %ebp
f0101084:	c3                   	ret    

f0101085 <page_decref>:
{
f0101085:	55                   	push   %ebp
f0101086:	89 e5                	mov    %esp,%ebp
f0101088:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010108b:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
}
f0101090:	5d                   	pop    %ebp
f0101091:	c3                   	ret    

f0101092 <pgdir_walk>:
{
f0101092:	55                   	push   %ebp
f0101093:	89 e5                	mov    %esp,%ebp
}
f0101095:	b8 00 00 00 00       	mov    $0x0,%eax
f010109a:	5d                   	pop    %ebp
f010109b:	c3                   	ret    

f010109c <page_insert>:
{
f010109c:	55                   	push   %ebp
f010109d:	89 e5                	mov    %esp,%ebp
}
f010109f:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a4:	5d                   	pop    %ebp
f01010a5:	c3                   	ret    

f01010a6 <page_lookup>:
{
f01010a6:	55                   	push   %ebp
f01010a7:	89 e5                	mov    %esp,%ebp
}
f01010a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ae:	5d                   	pop    %ebp
f01010af:	c3                   	ret    

f01010b0 <page_remove>:
{
f01010b0:	55                   	push   %ebp
f01010b1:	89 e5                	mov    %esp,%ebp
}
f01010b3:	5d                   	pop    %ebp
f01010b4:	c3                   	ret    

f01010b5 <tlb_invalidate>:
{
f01010b5:	55                   	push   %ebp
f01010b6:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010bb:	0f 01 38             	invlpg (%eax)
}
f01010be:	5d                   	pop    %ebp
f01010bf:	c3                   	ret    

f01010c0 <__x86.get_pc_thunk.dx>:
f01010c0:	8b 14 24             	mov    (%esp),%edx
f01010c3:	c3                   	ret    

f01010c4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01010c4:	55                   	push   %ebp
f01010c5:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01010c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01010ca:	ba 70 00 00 00       	mov    $0x70,%edx
f01010cf:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01010d0:	ba 71 00 00 00       	mov    $0x71,%edx
f01010d5:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01010d6:	0f b6 c0             	movzbl %al,%eax
}
f01010d9:	5d                   	pop    %ebp
f01010da:	c3                   	ret    

f01010db <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01010db:	55                   	push   %ebp
f01010dc:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01010de:	8b 45 08             	mov    0x8(%ebp),%eax
f01010e1:	ba 70 00 00 00       	mov    $0x70,%edx
f01010e6:	ee                   	out    %al,(%dx)
f01010e7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010ea:	ba 71 00 00 00       	mov    $0x71,%edx
f01010ef:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01010f0:	5d                   	pop    %ebp
f01010f1:	c3                   	ret    

f01010f2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01010f2:	55                   	push   %ebp
f01010f3:	89 e5                	mov    %esp,%ebp
f01010f5:	53                   	push   %ebx
f01010f6:	83 ec 10             	sub    $0x10,%esp
f01010f9:	e8 51 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01010fe:	81 c3 0a 22 01 00    	add    $0x1220a,%ebx
	cputchar(ch);
f0101104:	ff 75 08             	pushl  0x8(%ebp)
f0101107:	e8 ba f5 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f010110c:	83 c4 10             	add    $0x10,%esp
f010110f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101112:	c9                   	leave  
f0101113:	c3                   	ret    

f0101114 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101114:	55                   	push   %ebp
f0101115:	89 e5                	mov    %esp,%ebp
f0101117:	53                   	push   %ebx
f0101118:	83 ec 14             	sub    $0x14,%esp
f010111b:	e8 2f f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101120:	81 c3 e8 21 01 00    	add    $0x121e8,%ebx
	int cnt = 0;
f0101126:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010112d:	ff 75 0c             	pushl  0xc(%ebp)
f0101130:	ff 75 08             	pushl  0x8(%ebp)
f0101133:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101136:	50                   	push   %eax
f0101137:	8d 83 ea dd fe ff    	lea    -0x12216(%ebx),%eax
f010113d:	50                   	push   %eax
f010113e:	e8 98 04 00 00       	call   f01015db <vprintfmt>
	return cnt;
}
f0101143:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101146:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101149:	c9                   	leave  
f010114a:	c3                   	ret    

f010114b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010114b:	55                   	push   %ebp
f010114c:	89 e5                	mov    %esp,%ebp
f010114e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101151:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101154:	50                   	push   %eax
f0101155:	ff 75 08             	pushl  0x8(%ebp)
f0101158:	e8 b7 ff ff ff       	call   f0101114 <vcprintf>
	va_end(ap);

	return cnt;
}
f010115d:	c9                   	leave  
f010115e:	c3                   	ret    

f010115f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010115f:	55                   	push   %ebp
f0101160:	89 e5                	mov    %esp,%ebp
f0101162:	57                   	push   %edi
f0101163:	56                   	push   %esi
f0101164:	53                   	push   %ebx
f0101165:	83 ec 14             	sub    $0x14,%esp
f0101168:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010116b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010116e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101171:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101174:	8b 32                	mov    (%edx),%esi
f0101176:	8b 01                	mov    (%ecx),%eax
f0101178:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010117b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101182:	eb 2f                	jmp    f01011b3 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0101184:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0101187:	39 c6                	cmp    %eax,%esi
f0101189:	7f 49                	jg     f01011d4 <stab_binsearch+0x75>
f010118b:	0f b6 0a             	movzbl (%edx),%ecx
f010118e:	83 ea 0c             	sub    $0xc,%edx
f0101191:	39 f9                	cmp    %edi,%ecx
f0101193:	75 ef                	jne    f0101184 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101195:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101198:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010119b:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010119f:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01011a2:	73 35                	jae    f01011d9 <stab_binsearch+0x7a>
			*region_left = m;
f01011a4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01011a7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f01011a9:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01011ac:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01011b3:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01011b6:	7f 4e                	jg     f0101206 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01011b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01011bb:	01 f0                	add    %esi,%eax
f01011bd:	89 c3                	mov    %eax,%ebx
f01011bf:	c1 eb 1f             	shr    $0x1f,%ebx
f01011c2:	01 c3                	add    %eax,%ebx
f01011c4:	d1 fb                	sar    %ebx
f01011c6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01011c9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01011cc:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01011d0:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01011d2:	eb b3                	jmp    f0101187 <stab_binsearch+0x28>
			l = true_m + 1;
f01011d4:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01011d7:	eb da                	jmp    f01011b3 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01011d9:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01011dc:	76 14                	jbe    f01011f2 <stab_binsearch+0x93>
			*region_right = m - 1;
f01011de:	83 e8 01             	sub    $0x1,%eax
f01011e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01011e4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01011e7:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f01011e9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01011f0:	eb c1                	jmp    f01011b3 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01011f2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01011f5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01011f7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01011fb:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f01011fd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101204:	eb ad                	jmp    f01011b3 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0101206:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010120a:	74 16                	je     f0101222 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010120c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010120f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101211:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101214:	8b 0e                	mov    (%esi),%ecx
f0101216:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101219:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010121c:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0101220:	eb 12                	jmp    f0101234 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0101222:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101225:	8b 00                	mov    (%eax),%eax
f0101227:	83 e8 01             	sub    $0x1,%eax
f010122a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010122d:	89 07                	mov    %eax,(%edi)
f010122f:	eb 16                	jmp    f0101247 <stab_binsearch+0xe8>
		     l--)
f0101231:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0101234:	39 c1                	cmp    %eax,%ecx
f0101236:	7d 0a                	jge    f0101242 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0101238:	0f b6 1a             	movzbl (%edx),%ebx
f010123b:	83 ea 0c             	sub    $0xc,%edx
f010123e:	39 fb                	cmp    %edi,%ebx
f0101240:	75 ef                	jne    f0101231 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0101242:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101245:	89 07                	mov    %eax,(%edi)
	}
}
f0101247:	83 c4 14             	add    $0x14,%esp
f010124a:	5b                   	pop    %ebx
f010124b:	5e                   	pop    %esi
f010124c:	5f                   	pop    %edi
f010124d:	5d                   	pop    %ebp
f010124e:	c3                   	ret    

f010124f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010124f:	55                   	push   %ebp
f0101250:	89 e5                	mov    %esp,%ebp
f0101252:	57                   	push   %edi
f0101253:	56                   	push   %esi
f0101254:	53                   	push   %ebx
f0101255:	83 ec 3c             	sub    $0x3c,%esp
f0101258:	e8 f2 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010125d:	81 c3 ab 20 01 00    	add    $0x120ab,%ebx
f0101263:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101266:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101269:	8d 83 c7 f5 fe ff    	lea    -0x10a39(%ebx),%eax
f010126f:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0101271:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0101278:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f010127b:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0101282:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0101285:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010128c:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0101292:	0f 86 37 01 00 00    	jbe    f01013cf <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101298:	c7 c0 69 77 10 f0    	mov    $0xf0107769,%eax
f010129e:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f01012a4:	0f 86 04 02 00 00    	jbe    f01014ae <debuginfo_eip+0x25f>
f01012aa:	c7 c0 63 94 10 f0    	mov    $0xf0109463,%eax
f01012b0:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01012b4:	0f 85 fb 01 00 00    	jne    f01014b5 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01012ba:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01012c1:	c7 c0 e8 2a 10 f0    	mov    $0xf0102ae8,%eax
f01012c7:	c7 c2 68 77 10 f0    	mov    $0xf0107768,%edx
f01012cd:	29 c2                	sub    %eax,%edx
f01012cf:	c1 fa 02             	sar    $0x2,%edx
f01012d2:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01012d8:	83 ea 01             	sub    $0x1,%edx
f01012db:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01012de:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01012e1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01012e4:	83 ec 08             	sub    $0x8,%esp
f01012e7:	57                   	push   %edi
f01012e8:	6a 64                	push   $0x64
f01012ea:	e8 70 fe ff ff       	call   f010115f <stab_binsearch>
	if (lfile == 0)
f01012ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012f2:	83 c4 10             	add    $0x10,%esp
f01012f5:	85 c0                	test   %eax,%eax
f01012f7:	0f 84 bf 01 00 00    	je     f01014bc <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01012fd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101300:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101303:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101306:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101309:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010130c:	83 ec 08             	sub    $0x8,%esp
f010130f:	57                   	push   %edi
f0101310:	6a 24                	push   $0x24
f0101312:	c7 c0 e8 2a 10 f0    	mov    $0xf0102ae8,%eax
f0101318:	e8 42 fe ff ff       	call   f010115f <stab_binsearch>

	if (lfun <= rfun) {
f010131d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101320:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0101323:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0101326:	83 c4 10             	add    $0x10,%esp
f0101329:	39 c8                	cmp    %ecx,%eax
f010132b:	0f 8f b6 00 00 00    	jg     f01013e7 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101331:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101334:	c7 c1 e8 2a 10 f0    	mov    $0xf0102ae8,%ecx
f010133a:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f010133d:	8b 11                	mov    (%ecx),%edx
f010133f:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0101342:	c7 c2 63 94 10 f0    	mov    $0xf0109463,%edx
f0101348:	81 ea 69 77 10 f0    	sub    $0xf0107769,%edx
f010134e:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0101351:	73 0c                	jae    f010135f <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101353:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0101356:	81 c2 69 77 10 f0    	add    $0xf0107769,%edx
f010135c:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010135f:	8b 51 08             	mov    0x8(%ecx),%edx
f0101362:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0101365:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0101367:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010136a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010136d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101370:	83 ec 08             	sub    $0x8,%esp
f0101373:	6a 3a                	push   $0x3a
f0101375:	ff 76 08             	pushl  0x8(%esi)
f0101378:	e8 c7 09 00 00       	call   f0101d44 <strfind>
f010137d:	2b 46 08             	sub    0x8(%esi),%eax
f0101380:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101383:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101386:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101389:	83 c4 08             	add    $0x8,%esp
f010138c:	57                   	push   %edi
f010138d:	6a 44                	push   $0x44
f010138f:	c7 c0 e8 2a 10 f0    	mov    $0xf0102ae8,%eax
f0101395:	e8 c5 fd ff ff       	call   f010115f <stab_binsearch>
	if(lline<=rline){
f010139a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010139d:	83 c4 10             	add    $0x10,%esp
f01013a0:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01013a3:	0f 8f 1a 01 00 00    	jg     f01014c3 <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f01013a9:	89 d0                	mov    %edx,%eax
f01013ab:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01013ae:	c1 e2 02             	shl    $0x2,%edx
f01013b1:	c7 c1 e8 2a 10 f0    	mov    $0xf0102ae8,%ecx
f01013b7:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f01013bc:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01013bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01013c2:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f01013c6:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01013ca:	89 75 0c             	mov    %esi,0xc(%ebp)
f01013cd:	eb 36                	jmp    f0101405 <debuginfo_eip+0x1b6>
  	        panic("User address");
f01013cf:	83 ec 04             	sub    $0x4,%esp
f01013d2:	8d 83 d1 f5 fe ff    	lea    -0x10a2f(%ebx),%eax
f01013d8:	50                   	push   %eax
f01013d9:	6a 7f                	push   $0x7f
f01013db:	8d 83 de f5 fe ff    	lea    -0x10a22(%ebx),%eax
f01013e1:	50                   	push   %eax
f01013e2:	e8 b2 ec ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f01013e7:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01013ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01013ed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01013f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01013f3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01013f6:	e9 75 ff ff ff       	jmp    f0101370 <debuginfo_eip+0x121>
f01013fb:	83 e8 01             	sub    $0x1,%eax
f01013fe:	83 ea 0c             	sub    $0xc,%edx
f0101401:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0101405:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0101408:	39 c7                	cmp    %eax,%edi
f010140a:	7f 24                	jg     f0101430 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f010140c:	0f b6 0a             	movzbl (%edx),%ecx
f010140f:	80 f9 84             	cmp    $0x84,%cl
f0101412:	74 46                	je     f010145a <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101414:	80 f9 64             	cmp    $0x64,%cl
f0101417:	75 e2                	jne    f01013fb <debuginfo_eip+0x1ac>
f0101419:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f010141d:	74 dc                	je     f01013fb <debuginfo_eip+0x1ac>
f010141f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101422:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0101426:	74 3b                	je     f0101463 <debuginfo_eip+0x214>
f0101428:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010142b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010142e:	eb 33                	jmp    f0101463 <debuginfo_eip+0x214>
f0101430:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101433:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101436:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101439:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f010143e:	39 fa                	cmp    %edi,%edx
f0101440:	0f 8d 89 00 00 00    	jge    f01014cf <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0101446:	83 c2 01             	add    $0x1,%edx
f0101449:	89 d0                	mov    %edx,%eax
f010144b:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f010144e:	c7 c2 e8 2a 10 f0    	mov    $0xf0102ae8,%edx
f0101454:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0101458:	eb 3b                	jmp    f0101495 <debuginfo_eip+0x246>
f010145a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010145d:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0101461:	75 26                	jne    f0101489 <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101463:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101466:	c7 c0 e8 2a 10 f0    	mov    $0xf0102ae8,%eax
f010146c:	8b 14 90             	mov    (%eax,%edx,4),%edx
f010146f:	c7 c0 63 94 10 f0    	mov    $0xf0109463,%eax
f0101475:	81 e8 69 77 10 f0    	sub    $0xf0107769,%eax
f010147b:	39 c2                	cmp    %eax,%edx
f010147d:	73 b4                	jae    f0101433 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010147f:	81 c2 69 77 10 f0    	add    $0xf0107769,%edx
f0101485:	89 16                	mov    %edx,(%esi)
f0101487:	eb aa                	jmp    f0101433 <debuginfo_eip+0x1e4>
f0101489:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010148c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010148f:	eb d2                	jmp    f0101463 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0101491:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0101495:	39 c7                	cmp    %eax,%edi
f0101497:	7e 31                	jle    f01014ca <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101499:	0f b6 0a             	movzbl (%edx),%ecx
f010149c:	83 c0 01             	add    $0x1,%eax
f010149f:	83 c2 0c             	add    $0xc,%edx
f01014a2:	80 f9 a0             	cmp    $0xa0,%cl
f01014a5:	74 ea                	je     f0101491 <debuginfo_eip+0x242>
	return 0;
f01014a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01014ac:	eb 21                	jmp    f01014cf <debuginfo_eip+0x280>
		return -1;
f01014ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01014b3:	eb 1a                	jmp    f01014cf <debuginfo_eip+0x280>
f01014b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01014ba:	eb 13                	jmp    f01014cf <debuginfo_eip+0x280>
		return -1;
f01014bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01014c1:	eb 0c                	jmp    f01014cf <debuginfo_eip+0x280>
		return -1;
f01014c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01014c8:	eb 05                	jmp    f01014cf <debuginfo_eip+0x280>
	return 0;
f01014ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014d2:	5b                   	pop    %ebx
f01014d3:	5e                   	pop    %esi
f01014d4:	5f                   	pop    %edi
f01014d5:	5d                   	pop    %ebp
f01014d6:	c3                   	ret    

f01014d7 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01014d7:	55                   	push   %ebp
f01014d8:	89 e5                	mov    %esp,%ebp
f01014da:	57                   	push   %edi
f01014db:	56                   	push   %esi
f01014dc:	53                   	push   %ebx
f01014dd:	83 ec 2c             	sub    $0x2c,%esp
f01014e0:	e8 02 06 00 00       	call   f0101ae7 <__x86.get_pc_thunk.cx>
f01014e5:	81 c1 23 1e 01 00    	add    $0x11e23,%ecx
f01014eb:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01014ee:	89 c7                	mov    %eax,%edi
f01014f0:	89 d6                	mov    %edx,%esi
f01014f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014f8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01014fb:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01014fe:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101501:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101506:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0101509:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010150c:	39 d3                	cmp    %edx,%ebx
f010150e:	72 09                	jb     f0101519 <printnum+0x42>
f0101510:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101513:	0f 87 83 00 00 00    	ja     f010159c <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101519:	83 ec 0c             	sub    $0xc,%esp
f010151c:	ff 75 18             	pushl  0x18(%ebp)
f010151f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101522:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101525:	53                   	push   %ebx
f0101526:	ff 75 10             	pushl  0x10(%ebp)
f0101529:	83 ec 08             	sub    $0x8,%esp
f010152c:	ff 75 dc             	pushl  -0x24(%ebp)
f010152f:	ff 75 d8             	pushl  -0x28(%ebp)
f0101532:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101535:	ff 75 d0             	pushl  -0x30(%ebp)
f0101538:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010153b:	e8 20 0a 00 00       	call   f0101f60 <__udivdi3>
f0101540:	83 c4 18             	add    $0x18,%esp
f0101543:	52                   	push   %edx
f0101544:	50                   	push   %eax
f0101545:	89 f2                	mov    %esi,%edx
f0101547:	89 f8                	mov    %edi,%eax
f0101549:	e8 89 ff ff ff       	call   f01014d7 <printnum>
f010154e:	83 c4 20             	add    $0x20,%esp
f0101551:	eb 13                	jmp    f0101566 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101553:	83 ec 08             	sub    $0x8,%esp
f0101556:	56                   	push   %esi
f0101557:	ff 75 18             	pushl  0x18(%ebp)
f010155a:	ff d7                	call   *%edi
f010155c:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f010155f:	83 eb 01             	sub    $0x1,%ebx
f0101562:	85 db                	test   %ebx,%ebx
f0101564:	7f ed                	jg     f0101553 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101566:	83 ec 08             	sub    $0x8,%esp
f0101569:	56                   	push   %esi
f010156a:	83 ec 04             	sub    $0x4,%esp
f010156d:	ff 75 dc             	pushl  -0x24(%ebp)
f0101570:	ff 75 d8             	pushl  -0x28(%ebp)
f0101573:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101576:	ff 75 d0             	pushl  -0x30(%ebp)
f0101579:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010157c:	89 f3                	mov    %esi,%ebx
f010157e:	e8 fd 0a 00 00       	call   f0102080 <__umoddi3>
f0101583:	83 c4 14             	add    $0x14,%esp
f0101586:	0f be 84 06 ec f5 fe 	movsbl -0x10a14(%esi,%eax,1),%eax
f010158d:	ff 
f010158e:	50                   	push   %eax
f010158f:	ff d7                	call   *%edi
}
f0101591:	83 c4 10             	add    $0x10,%esp
f0101594:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101597:	5b                   	pop    %ebx
f0101598:	5e                   	pop    %esi
f0101599:	5f                   	pop    %edi
f010159a:	5d                   	pop    %ebp
f010159b:	c3                   	ret    
f010159c:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010159f:	eb be                	jmp    f010155f <printnum+0x88>

f01015a1 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01015a1:	55                   	push   %ebp
f01015a2:	89 e5                	mov    %esp,%ebp
f01015a4:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01015a7:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01015ab:	8b 10                	mov    (%eax),%edx
f01015ad:	3b 50 04             	cmp    0x4(%eax),%edx
f01015b0:	73 0a                	jae    f01015bc <sprintputch+0x1b>
		*b->buf++ = ch;
f01015b2:	8d 4a 01             	lea    0x1(%edx),%ecx
f01015b5:	89 08                	mov    %ecx,(%eax)
f01015b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ba:	88 02                	mov    %al,(%edx)
}
f01015bc:	5d                   	pop    %ebp
f01015bd:	c3                   	ret    

f01015be <printfmt>:
{
f01015be:	55                   	push   %ebp
f01015bf:	89 e5                	mov    %esp,%ebp
f01015c1:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01015c4:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01015c7:	50                   	push   %eax
f01015c8:	ff 75 10             	pushl  0x10(%ebp)
f01015cb:	ff 75 0c             	pushl  0xc(%ebp)
f01015ce:	ff 75 08             	pushl  0x8(%ebp)
f01015d1:	e8 05 00 00 00       	call   f01015db <vprintfmt>
}
f01015d6:	83 c4 10             	add    $0x10,%esp
f01015d9:	c9                   	leave  
f01015da:	c3                   	ret    

f01015db <vprintfmt>:
{
f01015db:	55                   	push   %ebp
f01015dc:	89 e5                	mov    %esp,%ebp
f01015de:	57                   	push   %edi
f01015df:	56                   	push   %esi
f01015e0:	53                   	push   %ebx
f01015e1:	83 ec 2c             	sub    $0x2c,%esp
f01015e4:	e8 66 eb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01015e9:	81 c3 1f 1d 01 00    	add    $0x11d1f,%ebx
f01015ef:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015f2:	8b 7d 10             	mov    0x10(%ebp),%edi
f01015f5:	e9 c3 03 00 00       	jmp    f01019bd <.L35+0x48>
		padc = ' ';
f01015fa:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01015fe:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0101605:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010160c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101613:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101618:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010161b:	8d 47 01             	lea    0x1(%edi),%eax
f010161e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101621:	0f b6 17             	movzbl (%edi),%edx
f0101624:	8d 42 dd             	lea    -0x23(%edx),%eax
f0101627:	3c 55                	cmp    $0x55,%al
f0101629:	0f 87 16 04 00 00    	ja     f0101a45 <.L22>
f010162f:	0f b6 c0             	movzbl %al,%eax
f0101632:	89 d9                	mov    %ebx,%ecx
f0101634:	03 8c 83 78 f6 fe ff 	add    -0x10988(%ebx,%eax,4),%ecx
f010163b:	ff e1                	jmp    *%ecx

f010163d <.L69>:
f010163d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101640:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101644:	eb d5                	jmp    f010161b <vprintfmt+0x40>

f0101646 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101646:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0101649:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010164d:	eb cc                	jmp    f010161b <vprintfmt+0x40>

f010164f <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f010164f:	0f b6 d2             	movzbl %dl,%edx
f0101652:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101655:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010165a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010165d:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101661:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101664:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101667:	83 f9 09             	cmp    $0x9,%ecx
f010166a:	77 55                	ja     f01016c1 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010166c:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010166f:	eb e9                	jmp    f010165a <.L29+0xb>

f0101671 <.L26>:
			precision = va_arg(ap, int);
f0101671:	8b 45 14             	mov    0x14(%ebp),%eax
f0101674:	8b 00                	mov    (%eax),%eax
f0101676:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101679:	8b 45 14             	mov    0x14(%ebp),%eax
f010167c:	8d 40 04             	lea    0x4(%eax),%eax
f010167f:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101682:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0101685:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101689:	79 90                	jns    f010161b <vprintfmt+0x40>
				width = precision, precision = -1;
f010168b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010168e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101691:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0101698:	eb 81                	jmp    f010161b <vprintfmt+0x40>

f010169a <.L27>:
f010169a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010169d:	85 c0                	test   %eax,%eax
f010169f:	ba 00 00 00 00       	mov    $0x0,%edx
f01016a4:	0f 49 d0             	cmovns %eax,%edx
f01016a7:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01016aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01016ad:	e9 69 ff ff ff       	jmp    f010161b <vprintfmt+0x40>

f01016b2 <.L23>:
f01016b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01016b5:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01016bc:	e9 5a ff ff ff       	jmp    f010161b <vprintfmt+0x40>
f01016c1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016c4:	eb bf                	jmp    f0101685 <.L26+0x14>

f01016c6 <.L33>:
			lflag++;
f01016c6:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01016ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01016cd:	e9 49 ff ff ff       	jmp    f010161b <vprintfmt+0x40>

f01016d2 <.L30>:
			putch(va_arg(ap, int), putdat);
f01016d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01016d5:	8d 78 04             	lea    0x4(%eax),%edi
f01016d8:	83 ec 08             	sub    $0x8,%esp
f01016db:	56                   	push   %esi
f01016dc:	ff 30                	pushl  (%eax)
f01016de:	ff 55 08             	call   *0x8(%ebp)
			break;
f01016e1:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01016e4:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01016e7:	e9 ce 02 00 00       	jmp    f01019ba <.L35+0x45>

f01016ec <.L32>:
			err = va_arg(ap, int);
f01016ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01016ef:	8d 78 04             	lea    0x4(%eax),%edi
f01016f2:	8b 00                	mov    (%eax),%eax
f01016f4:	99                   	cltd   
f01016f5:	31 d0                	xor    %edx,%eax
f01016f7:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01016f9:	83 f8 06             	cmp    $0x6,%eax
f01016fc:	7f 27                	jg     f0101725 <.L32+0x39>
f01016fe:	8b 94 83 3c 1d 00 00 	mov    0x1d3c(%ebx,%eax,4),%edx
f0101705:	85 d2                	test   %edx,%edx
f0101707:	74 1c                	je     f0101725 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0101709:	52                   	push   %edx
f010170a:	8d 83 18 f5 fe ff    	lea    -0x10ae8(%ebx),%eax
f0101710:	50                   	push   %eax
f0101711:	56                   	push   %esi
f0101712:	ff 75 08             	pushl  0x8(%ebp)
f0101715:	e8 a4 fe ff ff       	call   f01015be <printfmt>
f010171a:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010171d:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101720:	e9 95 02 00 00       	jmp    f01019ba <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0101725:	50                   	push   %eax
f0101726:	8d 83 04 f6 fe ff    	lea    -0x109fc(%ebx),%eax
f010172c:	50                   	push   %eax
f010172d:	56                   	push   %esi
f010172e:	ff 75 08             	pushl  0x8(%ebp)
f0101731:	e8 88 fe ff ff       	call   f01015be <printfmt>
f0101736:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101739:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010173c:	e9 79 02 00 00       	jmp    f01019ba <.L35+0x45>

f0101741 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101741:	8b 45 14             	mov    0x14(%ebp),%eax
f0101744:	83 c0 04             	add    $0x4,%eax
f0101747:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010174a:	8b 45 14             	mov    0x14(%ebp),%eax
f010174d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010174f:	85 ff                	test   %edi,%edi
f0101751:	8d 83 fd f5 fe ff    	lea    -0x10a03(%ebx),%eax
f0101757:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010175a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010175e:	0f 8e b5 00 00 00    	jle    f0101819 <.L36+0xd8>
f0101764:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101768:	75 08                	jne    f0101772 <.L36+0x31>
f010176a:	89 75 0c             	mov    %esi,0xc(%ebp)
f010176d:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101770:	eb 6d                	jmp    f01017df <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101772:	83 ec 08             	sub    $0x8,%esp
f0101775:	ff 75 cc             	pushl  -0x34(%ebp)
f0101778:	57                   	push   %edi
f0101779:	e8 82 04 00 00       	call   f0101c00 <strnlen>
f010177e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101781:	29 c2                	sub    %eax,%edx
f0101783:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101786:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101789:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010178d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101790:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101793:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101795:	eb 10                	jmp    f01017a7 <.L36+0x66>
					putch(padc, putdat);
f0101797:	83 ec 08             	sub    $0x8,%esp
f010179a:	56                   	push   %esi
f010179b:	ff 75 e0             	pushl  -0x20(%ebp)
f010179e:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01017a1:	83 ef 01             	sub    $0x1,%edi
f01017a4:	83 c4 10             	add    $0x10,%esp
f01017a7:	85 ff                	test   %edi,%edi
f01017a9:	7f ec                	jg     f0101797 <.L36+0x56>
f01017ab:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01017ae:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01017b1:	85 d2                	test   %edx,%edx
f01017b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01017b8:	0f 49 c2             	cmovns %edx,%eax
f01017bb:	29 c2                	sub    %eax,%edx
f01017bd:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01017c0:	89 75 0c             	mov    %esi,0xc(%ebp)
f01017c3:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01017c6:	eb 17                	jmp    f01017df <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01017c8:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01017cc:	75 30                	jne    f01017fe <.L36+0xbd>
					putch(ch, putdat);
f01017ce:	83 ec 08             	sub    $0x8,%esp
f01017d1:	ff 75 0c             	pushl  0xc(%ebp)
f01017d4:	50                   	push   %eax
f01017d5:	ff 55 08             	call   *0x8(%ebp)
f01017d8:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01017db:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01017df:	83 c7 01             	add    $0x1,%edi
f01017e2:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01017e6:	0f be c2             	movsbl %dl,%eax
f01017e9:	85 c0                	test   %eax,%eax
f01017eb:	74 52                	je     f010183f <.L36+0xfe>
f01017ed:	85 f6                	test   %esi,%esi
f01017ef:	78 d7                	js     f01017c8 <.L36+0x87>
f01017f1:	83 ee 01             	sub    $0x1,%esi
f01017f4:	79 d2                	jns    f01017c8 <.L36+0x87>
f01017f6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017f9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01017fc:	eb 32                	jmp    f0101830 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01017fe:	0f be d2             	movsbl %dl,%edx
f0101801:	83 ea 20             	sub    $0x20,%edx
f0101804:	83 fa 5e             	cmp    $0x5e,%edx
f0101807:	76 c5                	jbe    f01017ce <.L36+0x8d>
					putch('?', putdat);
f0101809:	83 ec 08             	sub    $0x8,%esp
f010180c:	ff 75 0c             	pushl  0xc(%ebp)
f010180f:	6a 3f                	push   $0x3f
f0101811:	ff 55 08             	call   *0x8(%ebp)
f0101814:	83 c4 10             	add    $0x10,%esp
f0101817:	eb c2                	jmp    f01017db <.L36+0x9a>
f0101819:	89 75 0c             	mov    %esi,0xc(%ebp)
f010181c:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010181f:	eb be                	jmp    f01017df <.L36+0x9e>
				putch(' ', putdat);
f0101821:	83 ec 08             	sub    $0x8,%esp
f0101824:	56                   	push   %esi
f0101825:	6a 20                	push   $0x20
f0101827:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010182a:	83 ef 01             	sub    $0x1,%edi
f010182d:	83 c4 10             	add    $0x10,%esp
f0101830:	85 ff                	test   %edi,%edi
f0101832:	7f ed                	jg     f0101821 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0101834:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101837:	89 45 14             	mov    %eax,0x14(%ebp)
f010183a:	e9 7b 01 00 00       	jmp    f01019ba <.L35+0x45>
f010183f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101842:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101845:	eb e9                	jmp    f0101830 <.L36+0xef>

f0101847 <.L31>:
f0101847:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010184a:	83 f9 01             	cmp    $0x1,%ecx
f010184d:	7e 40                	jle    f010188f <.L31+0x48>
		return va_arg(*ap, long long);
f010184f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101852:	8b 50 04             	mov    0x4(%eax),%edx
f0101855:	8b 00                	mov    (%eax),%eax
f0101857:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010185a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010185d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101860:	8d 40 08             	lea    0x8(%eax),%eax
f0101863:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101866:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010186a:	79 55                	jns    f01018c1 <.L31+0x7a>
				putch('-', putdat);
f010186c:	83 ec 08             	sub    $0x8,%esp
f010186f:	56                   	push   %esi
f0101870:	6a 2d                	push   $0x2d
f0101872:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101875:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101878:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010187b:	f7 da                	neg    %edx
f010187d:	83 d1 00             	adc    $0x0,%ecx
f0101880:	f7 d9                	neg    %ecx
f0101882:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101885:	b8 0a 00 00 00       	mov    $0xa,%eax
f010188a:	e9 10 01 00 00       	jmp    f010199f <.L35+0x2a>
	else if (lflag)
f010188f:	85 c9                	test   %ecx,%ecx
f0101891:	75 17                	jne    f01018aa <.L31+0x63>
		return va_arg(*ap, int);
f0101893:	8b 45 14             	mov    0x14(%ebp),%eax
f0101896:	8b 00                	mov    (%eax),%eax
f0101898:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010189b:	99                   	cltd   
f010189c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010189f:	8b 45 14             	mov    0x14(%ebp),%eax
f01018a2:	8d 40 04             	lea    0x4(%eax),%eax
f01018a5:	89 45 14             	mov    %eax,0x14(%ebp)
f01018a8:	eb bc                	jmp    f0101866 <.L31+0x1f>
		return va_arg(*ap, long);
f01018aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01018ad:	8b 00                	mov    (%eax),%eax
f01018af:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01018b2:	99                   	cltd   
f01018b3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01018b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01018b9:	8d 40 04             	lea    0x4(%eax),%eax
f01018bc:	89 45 14             	mov    %eax,0x14(%ebp)
f01018bf:	eb a5                	jmp    f0101866 <.L31+0x1f>
			num = getint(&ap, lflag);
f01018c1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01018c4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01018c7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01018cc:	e9 ce 00 00 00       	jmp    f010199f <.L35+0x2a>

f01018d1 <.L37>:
f01018d1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01018d4:	83 f9 01             	cmp    $0x1,%ecx
f01018d7:	7e 18                	jle    f01018f1 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f01018d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01018dc:	8b 10                	mov    (%eax),%edx
f01018de:	8b 48 04             	mov    0x4(%eax),%ecx
f01018e1:	8d 40 08             	lea    0x8(%eax),%eax
f01018e4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01018e7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01018ec:	e9 ae 00 00 00       	jmp    f010199f <.L35+0x2a>
	else if (lflag)
f01018f1:	85 c9                	test   %ecx,%ecx
f01018f3:	75 1a                	jne    f010190f <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f01018f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01018f8:	8b 10                	mov    (%eax),%edx
f01018fa:	b9 00 00 00 00       	mov    $0x0,%ecx
f01018ff:	8d 40 04             	lea    0x4(%eax),%eax
f0101902:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101905:	b8 0a 00 00 00       	mov    $0xa,%eax
f010190a:	e9 90 00 00 00       	jmp    f010199f <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010190f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101912:	8b 10                	mov    (%eax),%edx
f0101914:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101919:	8d 40 04             	lea    0x4(%eax),%eax
f010191c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010191f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101924:	eb 79                	jmp    f010199f <.L35+0x2a>

f0101926 <.L34>:
f0101926:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101929:	83 f9 01             	cmp    $0x1,%ecx
f010192c:	7e 15                	jle    f0101943 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f010192e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101931:	8b 10                	mov    (%eax),%edx
f0101933:	8b 48 04             	mov    0x4(%eax),%ecx
f0101936:	8d 40 08             	lea    0x8(%eax),%eax
f0101939:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010193c:	b8 08 00 00 00       	mov    $0x8,%eax
f0101941:	eb 5c                	jmp    f010199f <.L35+0x2a>
	else if (lflag)
f0101943:	85 c9                	test   %ecx,%ecx
f0101945:	75 17                	jne    f010195e <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0101947:	8b 45 14             	mov    0x14(%ebp),%eax
f010194a:	8b 10                	mov    (%eax),%edx
f010194c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101951:	8d 40 04             	lea    0x4(%eax),%eax
f0101954:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101957:	b8 08 00 00 00       	mov    $0x8,%eax
f010195c:	eb 41                	jmp    f010199f <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010195e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101961:	8b 10                	mov    (%eax),%edx
f0101963:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101968:	8d 40 04             	lea    0x4(%eax),%eax
f010196b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010196e:	b8 08 00 00 00       	mov    $0x8,%eax
f0101973:	eb 2a                	jmp    f010199f <.L35+0x2a>

f0101975 <.L35>:
			putch('0', putdat);
f0101975:	83 ec 08             	sub    $0x8,%esp
f0101978:	56                   	push   %esi
f0101979:	6a 30                	push   $0x30
f010197b:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010197e:	83 c4 08             	add    $0x8,%esp
f0101981:	56                   	push   %esi
f0101982:	6a 78                	push   $0x78
f0101984:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101987:	8b 45 14             	mov    0x14(%ebp),%eax
f010198a:	8b 10                	mov    (%eax),%edx
f010198c:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101991:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101994:	8d 40 04             	lea    0x4(%eax),%eax
f0101997:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010199a:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010199f:	83 ec 0c             	sub    $0xc,%esp
f01019a2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01019a6:	57                   	push   %edi
f01019a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01019aa:	50                   	push   %eax
f01019ab:	51                   	push   %ecx
f01019ac:	52                   	push   %edx
f01019ad:	89 f2                	mov    %esi,%edx
f01019af:	8b 45 08             	mov    0x8(%ebp),%eax
f01019b2:	e8 20 fb ff ff       	call   f01014d7 <printnum>
			break;
f01019b7:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01019ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01019bd:	83 c7 01             	add    $0x1,%edi
f01019c0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01019c4:	83 f8 25             	cmp    $0x25,%eax
f01019c7:	0f 84 2d fc ff ff    	je     f01015fa <vprintfmt+0x1f>
			if (ch == '\0')
f01019cd:	85 c0                	test   %eax,%eax
f01019cf:	0f 84 91 00 00 00    	je     f0101a66 <.L22+0x21>
			putch(ch, putdat);
f01019d5:	83 ec 08             	sub    $0x8,%esp
f01019d8:	56                   	push   %esi
f01019d9:	50                   	push   %eax
f01019da:	ff 55 08             	call   *0x8(%ebp)
f01019dd:	83 c4 10             	add    $0x10,%esp
f01019e0:	eb db                	jmp    f01019bd <.L35+0x48>

f01019e2 <.L38>:
f01019e2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01019e5:	83 f9 01             	cmp    $0x1,%ecx
f01019e8:	7e 15                	jle    f01019ff <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01019ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01019ed:	8b 10                	mov    (%eax),%edx
f01019ef:	8b 48 04             	mov    0x4(%eax),%ecx
f01019f2:	8d 40 08             	lea    0x8(%eax),%eax
f01019f5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01019f8:	b8 10 00 00 00       	mov    $0x10,%eax
f01019fd:	eb a0                	jmp    f010199f <.L35+0x2a>
	else if (lflag)
f01019ff:	85 c9                	test   %ecx,%ecx
f0101a01:	75 17                	jne    f0101a1a <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0101a03:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a06:	8b 10                	mov    (%eax),%edx
f0101a08:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101a0d:	8d 40 04             	lea    0x4(%eax),%eax
f0101a10:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101a13:	b8 10 00 00 00       	mov    $0x10,%eax
f0101a18:	eb 85                	jmp    f010199f <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101a1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a1d:	8b 10                	mov    (%eax),%edx
f0101a1f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101a24:	8d 40 04             	lea    0x4(%eax),%eax
f0101a27:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101a2a:	b8 10 00 00 00       	mov    $0x10,%eax
f0101a2f:	e9 6b ff ff ff       	jmp    f010199f <.L35+0x2a>

f0101a34 <.L25>:
			putch(ch, putdat);
f0101a34:	83 ec 08             	sub    $0x8,%esp
f0101a37:	56                   	push   %esi
f0101a38:	6a 25                	push   $0x25
f0101a3a:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101a3d:	83 c4 10             	add    $0x10,%esp
f0101a40:	e9 75 ff ff ff       	jmp    f01019ba <.L35+0x45>

f0101a45 <.L22>:
			putch('%', putdat);
f0101a45:	83 ec 08             	sub    $0x8,%esp
f0101a48:	56                   	push   %esi
f0101a49:	6a 25                	push   $0x25
f0101a4b:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101a4e:	83 c4 10             	add    $0x10,%esp
f0101a51:	89 f8                	mov    %edi,%eax
f0101a53:	eb 03                	jmp    f0101a58 <.L22+0x13>
f0101a55:	83 e8 01             	sub    $0x1,%eax
f0101a58:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101a5c:	75 f7                	jne    f0101a55 <.L22+0x10>
f0101a5e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101a61:	e9 54 ff ff ff       	jmp    f01019ba <.L35+0x45>
}
f0101a66:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101a69:	5b                   	pop    %ebx
f0101a6a:	5e                   	pop    %esi
f0101a6b:	5f                   	pop    %edi
f0101a6c:	5d                   	pop    %ebp
f0101a6d:	c3                   	ret    

f0101a6e <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101a6e:	55                   	push   %ebp
f0101a6f:	89 e5                	mov    %esp,%ebp
f0101a71:	53                   	push   %ebx
f0101a72:	83 ec 14             	sub    $0x14,%esp
f0101a75:	e8 d5 e6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101a7a:	81 c3 8e 18 01 00    	add    $0x1188e,%ebx
f0101a80:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a83:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101a86:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101a89:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101a8d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101a90:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101a97:	85 c0                	test   %eax,%eax
f0101a99:	74 2b                	je     f0101ac6 <vsnprintf+0x58>
f0101a9b:	85 d2                	test   %edx,%edx
f0101a9d:	7e 27                	jle    f0101ac6 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101a9f:	ff 75 14             	pushl  0x14(%ebp)
f0101aa2:	ff 75 10             	pushl  0x10(%ebp)
f0101aa5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101aa8:	50                   	push   %eax
f0101aa9:	8d 83 99 e2 fe ff    	lea    -0x11d67(%ebx),%eax
f0101aaf:	50                   	push   %eax
f0101ab0:	e8 26 fb ff ff       	call   f01015db <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101ab5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ab8:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101abb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101abe:	83 c4 10             	add    $0x10,%esp
}
f0101ac1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101ac4:	c9                   	leave  
f0101ac5:	c3                   	ret    
		return -E_INVAL;
f0101ac6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101acb:	eb f4                	jmp    f0101ac1 <vsnprintf+0x53>

f0101acd <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101acd:	55                   	push   %ebp
f0101ace:	89 e5                	mov    %esp,%ebp
f0101ad0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101ad3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101ad6:	50                   	push   %eax
f0101ad7:	ff 75 10             	pushl  0x10(%ebp)
f0101ada:	ff 75 0c             	pushl  0xc(%ebp)
f0101add:	ff 75 08             	pushl  0x8(%ebp)
f0101ae0:	e8 89 ff ff ff       	call   f0101a6e <vsnprintf>
	va_end(ap);

	return rc;
}
f0101ae5:	c9                   	leave  
f0101ae6:	c3                   	ret    

f0101ae7 <__x86.get_pc_thunk.cx>:
f0101ae7:	8b 0c 24             	mov    (%esp),%ecx
f0101aea:	c3                   	ret    

f0101aeb <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101aeb:	55                   	push   %ebp
f0101aec:	89 e5                	mov    %esp,%ebp
f0101aee:	57                   	push   %edi
f0101aef:	56                   	push   %esi
f0101af0:	53                   	push   %ebx
f0101af1:	83 ec 1c             	sub    $0x1c,%esp
f0101af4:	e8 56 e6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101af9:	81 c3 0f 18 01 00    	add    $0x1180f,%ebx
f0101aff:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101b02:	85 c0                	test   %eax,%eax
f0101b04:	74 13                	je     f0101b19 <readline+0x2e>
		cprintf("%s", prompt);
f0101b06:	83 ec 08             	sub    $0x8,%esp
f0101b09:	50                   	push   %eax
f0101b0a:	8d 83 18 f5 fe ff    	lea    -0x10ae8(%ebx),%eax
f0101b10:	50                   	push   %eax
f0101b11:	e8 35 f6 ff ff       	call   f010114b <cprintf>
f0101b16:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101b19:	83 ec 0c             	sub    $0xc,%esp
f0101b1c:	6a 00                	push   $0x0
f0101b1e:	e8 c4 eb ff ff       	call   f01006e7 <iscons>
f0101b23:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101b26:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101b29:	bf 00 00 00 00       	mov    $0x0,%edi
f0101b2e:	eb 46                	jmp    f0101b76 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101b30:	83 ec 08             	sub    $0x8,%esp
f0101b33:	50                   	push   %eax
f0101b34:	8d 83 d0 f7 fe ff    	lea    -0x10830(%ebx),%eax
f0101b3a:	50                   	push   %eax
f0101b3b:	e8 0b f6 ff ff       	call   f010114b <cprintf>
			return NULL;
f0101b40:	83 c4 10             	add    $0x10,%esp
f0101b43:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101b48:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101b4b:	5b                   	pop    %ebx
f0101b4c:	5e                   	pop    %esi
f0101b4d:	5f                   	pop    %edi
f0101b4e:	5d                   	pop    %ebp
f0101b4f:	c3                   	ret    
			if (echoing)
f0101b50:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101b54:	75 05                	jne    f0101b5b <readline+0x70>
			i--;
f0101b56:	83 ef 01             	sub    $0x1,%edi
f0101b59:	eb 1b                	jmp    f0101b76 <readline+0x8b>
				cputchar('\b');
f0101b5b:	83 ec 0c             	sub    $0xc,%esp
f0101b5e:	6a 08                	push   $0x8
f0101b60:	e8 61 eb ff ff       	call   f01006c6 <cputchar>
f0101b65:	83 c4 10             	add    $0x10,%esp
f0101b68:	eb ec                	jmp    f0101b56 <readline+0x6b>
			buf[i++] = c;
f0101b6a:	89 f0                	mov    %esi,%eax
f0101b6c:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f0101b73:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101b76:	e8 5b eb ff ff       	call   f01006d6 <getchar>
f0101b7b:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0101b7d:	85 c0                	test   %eax,%eax
f0101b7f:	78 af                	js     f0101b30 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101b81:	83 f8 08             	cmp    $0x8,%eax
f0101b84:	0f 94 c2             	sete   %dl
f0101b87:	83 f8 7f             	cmp    $0x7f,%eax
f0101b8a:	0f 94 c0             	sete   %al
f0101b8d:	08 c2                	or     %al,%dl
f0101b8f:	74 04                	je     f0101b95 <readline+0xaa>
f0101b91:	85 ff                	test   %edi,%edi
f0101b93:	7f bb                	jg     f0101b50 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101b95:	83 fe 1f             	cmp    $0x1f,%esi
f0101b98:	7e 1c                	jle    f0101bb6 <readline+0xcb>
f0101b9a:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101ba0:	7f 14                	jg     f0101bb6 <readline+0xcb>
			if (echoing)
f0101ba2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101ba6:	74 c2                	je     f0101b6a <readline+0x7f>
				cputchar(c);
f0101ba8:	83 ec 0c             	sub    $0xc,%esp
f0101bab:	56                   	push   %esi
f0101bac:	e8 15 eb ff ff       	call   f01006c6 <cputchar>
f0101bb1:	83 c4 10             	add    $0x10,%esp
f0101bb4:	eb b4                	jmp    f0101b6a <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0101bb6:	83 fe 0a             	cmp    $0xa,%esi
f0101bb9:	74 05                	je     f0101bc0 <readline+0xd5>
f0101bbb:	83 fe 0d             	cmp    $0xd,%esi
f0101bbe:	75 b6                	jne    f0101b76 <readline+0x8b>
			if (echoing)
f0101bc0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101bc4:	75 13                	jne    f0101bd9 <readline+0xee>
			buf[i] = 0;
f0101bc6:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f0101bcd:	00 
			return buf;
f0101bce:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f0101bd4:	e9 6f ff ff ff       	jmp    f0101b48 <readline+0x5d>
				cputchar('\n');
f0101bd9:	83 ec 0c             	sub    $0xc,%esp
f0101bdc:	6a 0a                	push   $0xa
f0101bde:	e8 e3 ea ff ff       	call   f01006c6 <cputchar>
f0101be3:	83 c4 10             	add    $0x10,%esp
f0101be6:	eb de                	jmp    f0101bc6 <readline+0xdb>

f0101be8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101be8:	55                   	push   %ebp
f0101be9:	89 e5                	mov    %esp,%ebp
f0101beb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101bee:	b8 00 00 00 00       	mov    $0x0,%eax
f0101bf3:	eb 03                	jmp    f0101bf8 <strlen+0x10>
		n++;
f0101bf5:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101bf8:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101bfc:	75 f7                	jne    f0101bf5 <strlen+0xd>
	return n;
}
f0101bfe:	5d                   	pop    %ebp
f0101bff:	c3                   	ret    

f0101c00 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101c00:	55                   	push   %ebp
f0101c01:	89 e5                	mov    %esp,%ebp
f0101c03:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101c06:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101c09:	b8 00 00 00 00       	mov    $0x0,%eax
f0101c0e:	eb 03                	jmp    f0101c13 <strnlen+0x13>
		n++;
f0101c10:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101c13:	39 d0                	cmp    %edx,%eax
f0101c15:	74 06                	je     f0101c1d <strnlen+0x1d>
f0101c17:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101c1b:	75 f3                	jne    f0101c10 <strnlen+0x10>
	return n;
}
f0101c1d:	5d                   	pop    %ebp
f0101c1e:	c3                   	ret    

f0101c1f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101c1f:	55                   	push   %ebp
f0101c20:	89 e5                	mov    %esp,%ebp
f0101c22:	53                   	push   %ebx
f0101c23:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c26:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101c29:	89 c2                	mov    %eax,%edx
f0101c2b:	83 c1 01             	add    $0x1,%ecx
f0101c2e:	83 c2 01             	add    $0x1,%edx
f0101c31:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101c35:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101c38:	84 db                	test   %bl,%bl
f0101c3a:	75 ef                	jne    f0101c2b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101c3c:	5b                   	pop    %ebx
f0101c3d:	5d                   	pop    %ebp
f0101c3e:	c3                   	ret    

f0101c3f <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101c3f:	55                   	push   %ebp
f0101c40:	89 e5                	mov    %esp,%ebp
f0101c42:	53                   	push   %ebx
f0101c43:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101c46:	53                   	push   %ebx
f0101c47:	e8 9c ff ff ff       	call   f0101be8 <strlen>
f0101c4c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101c4f:	ff 75 0c             	pushl  0xc(%ebp)
f0101c52:	01 d8                	add    %ebx,%eax
f0101c54:	50                   	push   %eax
f0101c55:	e8 c5 ff ff ff       	call   f0101c1f <strcpy>
	return dst;
}
f0101c5a:	89 d8                	mov    %ebx,%eax
f0101c5c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101c5f:	c9                   	leave  
f0101c60:	c3                   	ret    

f0101c61 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101c61:	55                   	push   %ebp
f0101c62:	89 e5                	mov    %esp,%ebp
f0101c64:	56                   	push   %esi
f0101c65:	53                   	push   %ebx
f0101c66:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c69:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101c6c:	89 f3                	mov    %esi,%ebx
f0101c6e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101c71:	89 f2                	mov    %esi,%edx
f0101c73:	eb 0f                	jmp    f0101c84 <strncpy+0x23>
		*dst++ = *src;
f0101c75:	83 c2 01             	add    $0x1,%edx
f0101c78:	0f b6 01             	movzbl (%ecx),%eax
f0101c7b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101c7e:	80 39 01             	cmpb   $0x1,(%ecx)
f0101c81:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101c84:	39 da                	cmp    %ebx,%edx
f0101c86:	75 ed                	jne    f0101c75 <strncpy+0x14>
	}
	return ret;
}
f0101c88:	89 f0                	mov    %esi,%eax
f0101c8a:	5b                   	pop    %ebx
f0101c8b:	5e                   	pop    %esi
f0101c8c:	5d                   	pop    %ebp
f0101c8d:	c3                   	ret    

f0101c8e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101c8e:	55                   	push   %ebp
f0101c8f:	89 e5                	mov    %esp,%ebp
f0101c91:	56                   	push   %esi
f0101c92:	53                   	push   %ebx
f0101c93:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c96:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101c99:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101c9c:	89 f0                	mov    %esi,%eax
f0101c9e:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101ca2:	85 c9                	test   %ecx,%ecx
f0101ca4:	75 0b                	jne    f0101cb1 <strlcpy+0x23>
f0101ca6:	eb 17                	jmp    f0101cbf <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101ca8:	83 c2 01             	add    $0x1,%edx
f0101cab:	83 c0 01             	add    $0x1,%eax
f0101cae:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101cb1:	39 d8                	cmp    %ebx,%eax
f0101cb3:	74 07                	je     f0101cbc <strlcpy+0x2e>
f0101cb5:	0f b6 0a             	movzbl (%edx),%ecx
f0101cb8:	84 c9                	test   %cl,%cl
f0101cba:	75 ec                	jne    f0101ca8 <strlcpy+0x1a>
		*dst = '\0';
f0101cbc:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101cbf:	29 f0                	sub    %esi,%eax
}
f0101cc1:	5b                   	pop    %ebx
f0101cc2:	5e                   	pop    %esi
f0101cc3:	5d                   	pop    %ebp
f0101cc4:	c3                   	ret    

f0101cc5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101cc5:	55                   	push   %ebp
f0101cc6:	89 e5                	mov    %esp,%ebp
f0101cc8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101ccb:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101cce:	eb 06                	jmp    f0101cd6 <strcmp+0x11>
		p++, q++;
f0101cd0:	83 c1 01             	add    $0x1,%ecx
f0101cd3:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101cd6:	0f b6 01             	movzbl (%ecx),%eax
f0101cd9:	84 c0                	test   %al,%al
f0101cdb:	74 04                	je     f0101ce1 <strcmp+0x1c>
f0101cdd:	3a 02                	cmp    (%edx),%al
f0101cdf:	74 ef                	je     f0101cd0 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101ce1:	0f b6 c0             	movzbl %al,%eax
f0101ce4:	0f b6 12             	movzbl (%edx),%edx
f0101ce7:	29 d0                	sub    %edx,%eax
}
f0101ce9:	5d                   	pop    %ebp
f0101cea:	c3                   	ret    

f0101ceb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101ceb:	55                   	push   %ebp
f0101cec:	89 e5                	mov    %esp,%ebp
f0101cee:	53                   	push   %ebx
f0101cef:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cf2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101cf5:	89 c3                	mov    %eax,%ebx
f0101cf7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101cfa:	eb 06                	jmp    f0101d02 <strncmp+0x17>
		n--, p++, q++;
f0101cfc:	83 c0 01             	add    $0x1,%eax
f0101cff:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101d02:	39 d8                	cmp    %ebx,%eax
f0101d04:	74 16                	je     f0101d1c <strncmp+0x31>
f0101d06:	0f b6 08             	movzbl (%eax),%ecx
f0101d09:	84 c9                	test   %cl,%cl
f0101d0b:	74 04                	je     f0101d11 <strncmp+0x26>
f0101d0d:	3a 0a                	cmp    (%edx),%cl
f0101d0f:	74 eb                	je     f0101cfc <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101d11:	0f b6 00             	movzbl (%eax),%eax
f0101d14:	0f b6 12             	movzbl (%edx),%edx
f0101d17:	29 d0                	sub    %edx,%eax
}
f0101d19:	5b                   	pop    %ebx
f0101d1a:	5d                   	pop    %ebp
f0101d1b:	c3                   	ret    
		return 0;
f0101d1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101d21:	eb f6                	jmp    f0101d19 <strncmp+0x2e>

f0101d23 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101d23:	55                   	push   %ebp
f0101d24:	89 e5                	mov    %esp,%ebp
f0101d26:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d29:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101d2d:	0f b6 10             	movzbl (%eax),%edx
f0101d30:	84 d2                	test   %dl,%dl
f0101d32:	74 09                	je     f0101d3d <strchr+0x1a>
		if (*s == c)
f0101d34:	38 ca                	cmp    %cl,%dl
f0101d36:	74 0a                	je     f0101d42 <strchr+0x1f>
	for (; *s; s++)
f0101d38:	83 c0 01             	add    $0x1,%eax
f0101d3b:	eb f0                	jmp    f0101d2d <strchr+0xa>
			return (char *) s;
	return 0;
f0101d3d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101d42:	5d                   	pop    %ebp
f0101d43:	c3                   	ret    

f0101d44 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101d44:	55                   	push   %ebp
f0101d45:	89 e5                	mov    %esp,%ebp
f0101d47:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d4a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101d4e:	eb 03                	jmp    f0101d53 <strfind+0xf>
f0101d50:	83 c0 01             	add    $0x1,%eax
f0101d53:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101d56:	38 ca                	cmp    %cl,%dl
f0101d58:	74 04                	je     f0101d5e <strfind+0x1a>
f0101d5a:	84 d2                	test   %dl,%dl
f0101d5c:	75 f2                	jne    f0101d50 <strfind+0xc>
			break;
	return (char *) s;
}
f0101d5e:	5d                   	pop    %ebp
f0101d5f:	c3                   	ret    

f0101d60 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101d60:	55                   	push   %ebp
f0101d61:	89 e5                	mov    %esp,%ebp
f0101d63:	57                   	push   %edi
f0101d64:	56                   	push   %esi
f0101d65:	53                   	push   %ebx
f0101d66:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101d69:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101d6c:	85 c9                	test   %ecx,%ecx
f0101d6e:	74 13                	je     f0101d83 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101d70:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101d76:	75 05                	jne    f0101d7d <memset+0x1d>
f0101d78:	f6 c1 03             	test   $0x3,%cl
f0101d7b:	74 0d                	je     f0101d8a <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101d7d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101d80:	fc                   	cld    
f0101d81:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101d83:	89 f8                	mov    %edi,%eax
f0101d85:	5b                   	pop    %ebx
f0101d86:	5e                   	pop    %esi
f0101d87:	5f                   	pop    %edi
f0101d88:	5d                   	pop    %ebp
f0101d89:	c3                   	ret    
		c &= 0xFF;
f0101d8a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101d8e:	89 d3                	mov    %edx,%ebx
f0101d90:	c1 e3 08             	shl    $0x8,%ebx
f0101d93:	89 d0                	mov    %edx,%eax
f0101d95:	c1 e0 18             	shl    $0x18,%eax
f0101d98:	89 d6                	mov    %edx,%esi
f0101d9a:	c1 e6 10             	shl    $0x10,%esi
f0101d9d:	09 f0                	or     %esi,%eax
f0101d9f:	09 c2                	or     %eax,%edx
f0101da1:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101da3:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101da6:	89 d0                	mov    %edx,%eax
f0101da8:	fc                   	cld    
f0101da9:	f3 ab                	rep stos %eax,%es:(%edi)
f0101dab:	eb d6                	jmp    f0101d83 <memset+0x23>

f0101dad <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101dad:	55                   	push   %ebp
f0101dae:	89 e5                	mov    %esp,%ebp
f0101db0:	57                   	push   %edi
f0101db1:	56                   	push   %esi
f0101db2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101db5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101db8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101dbb:	39 c6                	cmp    %eax,%esi
f0101dbd:	73 35                	jae    f0101df4 <memmove+0x47>
f0101dbf:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101dc2:	39 c2                	cmp    %eax,%edx
f0101dc4:	76 2e                	jbe    f0101df4 <memmove+0x47>
		s += n;
		d += n;
f0101dc6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101dc9:	89 d6                	mov    %edx,%esi
f0101dcb:	09 fe                	or     %edi,%esi
f0101dcd:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101dd3:	74 0c                	je     f0101de1 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101dd5:	83 ef 01             	sub    $0x1,%edi
f0101dd8:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101ddb:	fd                   	std    
f0101ddc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101dde:	fc                   	cld    
f0101ddf:	eb 21                	jmp    f0101e02 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101de1:	f6 c1 03             	test   $0x3,%cl
f0101de4:	75 ef                	jne    f0101dd5 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101de6:	83 ef 04             	sub    $0x4,%edi
f0101de9:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101dec:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101def:	fd                   	std    
f0101df0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101df2:	eb ea                	jmp    f0101dde <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101df4:	89 f2                	mov    %esi,%edx
f0101df6:	09 c2                	or     %eax,%edx
f0101df8:	f6 c2 03             	test   $0x3,%dl
f0101dfb:	74 09                	je     f0101e06 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101dfd:	89 c7                	mov    %eax,%edi
f0101dff:	fc                   	cld    
f0101e00:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101e02:	5e                   	pop    %esi
f0101e03:	5f                   	pop    %edi
f0101e04:	5d                   	pop    %ebp
f0101e05:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101e06:	f6 c1 03             	test   $0x3,%cl
f0101e09:	75 f2                	jne    f0101dfd <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101e0b:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101e0e:	89 c7                	mov    %eax,%edi
f0101e10:	fc                   	cld    
f0101e11:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101e13:	eb ed                	jmp    f0101e02 <memmove+0x55>

f0101e15 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101e15:	55                   	push   %ebp
f0101e16:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101e18:	ff 75 10             	pushl  0x10(%ebp)
f0101e1b:	ff 75 0c             	pushl  0xc(%ebp)
f0101e1e:	ff 75 08             	pushl  0x8(%ebp)
f0101e21:	e8 87 ff ff ff       	call   f0101dad <memmove>
}
f0101e26:	c9                   	leave  
f0101e27:	c3                   	ret    

f0101e28 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101e28:	55                   	push   %ebp
f0101e29:	89 e5                	mov    %esp,%ebp
f0101e2b:	56                   	push   %esi
f0101e2c:	53                   	push   %ebx
f0101e2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e30:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101e33:	89 c6                	mov    %eax,%esi
f0101e35:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101e38:	39 f0                	cmp    %esi,%eax
f0101e3a:	74 1c                	je     f0101e58 <memcmp+0x30>
		if (*s1 != *s2)
f0101e3c:	0f b6 08             	movzbl (%eax),%ecx
f0101e3f:	0f b6 1a             	movzbl (%edx),%ebx
f0101e42:	38 d9                	cmp    %bl,%cl
f0101e44:	75 08                	jne    f0101e4e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101e46:	83 c0 01             	add    $0x1,%eax
f0101e49:	83 c2 01             	add    $0x1,%edx
f0101e4c:	eb ea                	jmp    f0101e38 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0101e4e:	0f b6 c1             	movzbl %cl,%eax
f0101e51:	0f b6 db             	movzbl %bl,%ebx
f0101e54:	29 d8                	sub    %ebx,%eax
f0101e56:	eb 05                	jmp    f0101e5d <memcmp+0x35>
	}

	return 0;
f0101e58:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101e5d:	5b                   	pop    %ebx
f0101e5e:	5e                   	pop    %esi
f0101e5f:	5d                   	pop    %ebp
f0101e60:	c3                   	ret    

f0101e61 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101e61:	55                   	push   %ebp
f0101e62:	89 e5                	mov    %esp,%ebp
f0101e64:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e67:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101e6a:	89 c2                	mov    %eax,%edx
f0101e6c:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101e6f:	39 d0                	cmp    %edx,%eax
f0101e71:	73 09                	jae    f0101e7c <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101e73:	38 08                	cmp    %cl,(%eax)
f0101e75:	74 05                	je     f0101e7c <memfind+0x1b>
	for (; s < ends; s++)
f0101e77:	83 c0 01             	add    $0x1,%eax
f0101e7a:	eb f3                	jmp    f0101e6f <memfind+0xe>
			break;
	return (void *) s;
}
f0101e7c:	5d                   	pop    %ebp
f0101e7d:	c3                   	ret    

f0101e7e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101e7e:	55                   	push   %ebp
f0101e7f:	89 e5                	mov    %esp,%ebp
f0101e81:	57                   	push   %edi
f0101e82:	56                   	push   %esi
f0101e83:	53                   	push   %ebx
f0101e84:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e87:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101e8a:	eb 03                	jmp    f0101e8f <strtol+0x11>
		s++;
f0101e8c:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101e8f:	0f b6 01             	movzbl (%ecx),%eax
f0101e92:	3c 20                	cmp    $0x20,%al
f0101e94:	74 f6                	je     f0101e8c <strtol+0xe>
f0101e96:	3c 09                	cmp    $0x9,%al
f0101e98:	74 f2                	je     f0101e8c <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101e9a:	3c 2b                	cmp    $0x2b,%al
f0101e9c:	74 2e                	je     f0101ecc <strtol+0x4e>
	int neg = 0;
f0101e9e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101ea3:	3c 2d                	cmp    $0x2d,%al
f0101ea5:	74 2f                	je     f0101ed6 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101ea7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101ead:	75 05                	jne    f0101eb4 <strtol+0x36>
f0101eaf:	80 39 30             	cmpb   $0x30,(%ecx)
f0101eb2:	74 2c                	je     f0101ee0 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101eb4:	85 db                	test   %ebx,%ebx
f0101eb6:	75 0a                	jne    f0101ec2 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101eb8:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101ebd:	80 39 30             	cmpb   $0x30,(%ecx)
f0101ec0:	74 28                	je     f0101eea <strtol+0x6c>
		base = 10;
f0101ec2:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ec7:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101eca:	eb 50                	jmp    f0101f1c <strtol+0x9e>
		s++;
f0101ecc:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101ecf:	bf 00 00 00 00       	mov    $0x0,%edi
f0101ed4:	eb d1                	jmp    f0101ea7 <strtol+0x29>
		s++, neg = 1;
f0101ed6:	83 c1 01             	add    $0x1,%ecx
f0101ed9:	bf 01 00 00 00       	mov    $0x1,%edi
f0101ede:	eb c7                	jmp    f0101ea7 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101ee0:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101ee4:	74 0e                	je     f0101ef4 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101ee6:	85 db                	test   %ebx,%ebx
f0101ee8:	75 d8                	jne    f0101ec2 <strtol+0x44>
		s++, base = 8;
f0101eea:	83 c1 01             	add    $0x1,%ecx
f0101eed:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101ef2:	eb ce                	jmp    f0101ec2 <strtol+0x44>
		s += 2, base = 16;
f0101ef4:	83 c1 02             	add    $0x2,%ecx
f0101ef7:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101efc:	eb c4                	jmp    f0101ec2 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101efe:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101f01:	89 f3                	mov    %esi,%ebx
f0101f03:	80 fb 19             	cmp    $0x19,%bl
f0101f06:	77 29                	ja     f0101f31 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101f08:	0f be d2             	movsbl %dl,%edx
f0101f0b:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101f0e:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101f11:	7d 30                	jge    f0101f43 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101f13:	83 c1 01             	add    $0x1,%ecx
f0101f16:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101f1a:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101f1c:	0f b6 11             	movzbl (%ecx),%edx
f0101f1f:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101f22:	89 f3                	mov    %esi,%ebx
f0101f24:	80 fb 09             	cmp    $0x9,%bl
f0101f27:	77 d5                	ja     f0101efe <strtol+0x80>
			dig = *s - '0';
f0101f29:	0f be d2             	movsbl %dl,%edx
f0101f2c:	83 ea 30             	sub    $0x30,%edx
f0101f2f:	eb dd                	jmp    f0101f0e <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101f31:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101f34:	89 f3                	mov    %esi,%ebx
f0101f36:	80 fb 19             	cmp    $0x19,%bl
f0101f39:	77 08                	ja     f0101f43 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0101f3b:	0f be d2             	movsbl %dl,%edx
f0101f3e:	83 ea 37             	sub    $0x37,%edx
f0101f41:	eb cb                	jmp    f0101f0e <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101f43:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101f47:	74 05                	je     f0101f4e <strtol+0xd0>
		*endptr = (char *) s;
f0101f49:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101f4c:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0101f4e:	89 c2                	mov    %eax,%edx
f0101f50:	f7 da                	neg    %edx
f0101f52:	85 ff                	test   %edi,%edi
f0101f54:	0f 45 c2             	cmovne %edx,%eax
}
f0101f57:	5b                   	pop    %ebx
f0101f58:	5e                   	pop    %esi
f0101f59:	5f                   	pop    %edi
f0101f5a:	5d                   	pop    %ebp
f0101f5b:	c3                   	ret    
f0101f5c:	66 90                	xchg   %ax,%ax
f0101f5e:	66 90                	xchg   %ax,%ax

f0101f60 <__udivdi3>:
f0101f60:	55                   	push   %ebp
f0101f61:	57                   	push   %edi
f0101f62:	56                   	push   %esi
f0101f63:	53                   	push   %ebx
f0101f64:	83 ec 1c             	sub    $0x1c,%esp
f0101f67:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0101f6b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101f6f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101f73:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101f77:	85 d2                	test   %edx,%edx
f0101f79:	75 35                	jne    f0101fb0 <__udivdi3+0x50>
f0101f7b:	39 f3                	cmp    %esi,%ebx
f0101f7d:	0f 87 bd 00 00 00    	ja     f0102040 <__udivdi3+0xe0>
f0101f83:	85 db                	test   %ebx,%ebx
f0101f85:	89 d9                	mov    %ebx,%ecx
f0101f87:	75 0b                	jne    f0101f94 <__udivdi3+0x34>
f0101f89:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f8e:	31 d2                	xor    %edx,%edx
f0101f90:	f7 f3                	div    %ebx
f0101f92:	89 c1                	mov    %eax,%ecx
f0101f94:	31 d2                	xor    %edx,%edx
f0101f96:	89 f0                	mov    %esi,%eax
f0101f98:	f7 f1                	div    %ecx
f0101f9a:	89 c6                	mov    %eax,%esi
f0101f9c:	89 e8                	mov    %ebp,%eax
f0101f9e:	89 f7                	mov    %esi,%edi
f0101fa0:	f7 f1                	div    %ecx
f0101fa2:	89 fa                	mov    %edi,%edx
f0101fa4:	83 c4 1c             	add    $0x1c,%esp
f0101fa7:	5b                   	pop    %ebx
f0101fa8:	5e                   	pop    %esi
f0101fa9:	5f                   	pop    %edi
f0101faa:	5d                   	pop    %ebp
f0101fab:	c3                   	ret    
f0101fac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101fb0:	39 f2                	cmp    %esi,%edx
f0101fb2:	77 7c                	ja     f0102030 <__udivdi3+0xd0>
f0101fb4:	0f bd fa             	bsr    %edx,%edi
f0101fb7:	83 f7 1f             	xor    $0x1f,%edi
f0101fba:	0f 84 98 00 00 00    	je     f0102058 <__udivdi3+0xf8>
f0101fc0:	89 f9                	mov    %edi,%ecx
f0101fc2:	b8 20 00 00 00       	mov    $0x20,%eax
f0101fc7:	29 f8                	sub    %edi,%eax
f0101fc9:	d3 e2                	shl    %cl,%edx
f0101fcb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101fcf:	89 c1                	mov    %eax,%ecx
f0101fd1:	89 da                	mov    %ebx,%edx
f0101fd3:	d3 ea                	shr    %cl,%edx
f0101fd5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101fd9:	09 d1                	or     %edx,%ecx
f0101fdb:	89 f2                	mov    %esi,%edx
f0101fdd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101fe1:	89 f9                	mov    %edi,%ecx
f0101fe3:	d3 e3                	shl    %cl,%ebx
f0101fe5:	89 c1                	mov    %eax,%ecx
f0101fe7:	d3 ea                	shr    %cl,%edx
f0101fe9:	89 f9                	mov    %edi,%ecx
f0101feb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101fef:	d3 e6                	shl    %cl,%esi
f0101ff1:	89 eb                	mov    %ebp,%ebx
f0101ff3:	89 c1                	mov    %eax,%ecx
f0101ff5:	d3 eb                	shr    %cl,%ebx
f0101ff7:	09 de                	or     %ebx,%esi
f0101ff9:	89 f0                	mov    %esi,%eax
f0101ffb:	f7 74 24 08          	divl   0x8(%esp)
f0101fff:	89 d6                	mov    %edx,%esi
f0102001:	89 c3                	mov    %eax,%ebx
f0102003:	f7 64 24 0c          	mull   0xc(%esp)
f0102007:	39 d6                	cmp    %edx,%esi
f0102009:	72 0c                	jb     f0102017 <__udivdi3+0xb7>
f010200b:	89 f9                	mov    %edi,%ecx
f010200d:	d3 e5                	shl    %cl,%ebp
f010200f:	39 c5                	cmp    %eax,%ebp
f0102011:	73 5d                	jae    f0102070 <__udivdi3+0x110>
f0102013:	39 d6                	cmp    %edx,%esi
f0102015:	75 59                	jne    f0102070 <__udivdi3+0x110>
f0102017:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010201a:	31 ff                	xor    %edi,%edi
f010201c:	89 fa                	mov    %edi,%edx
f010201e:	83 c4 1c             	add    $0x1c,%esp
f0102021:	5b                   	pop    %ebx
f0102022:	5e                   	pop    %esi
f0102023:	5f                   	pop    %edi
f0102024:	5d                   	pop    %ebp
f0102025:	c3                   	ret    
f0102026:	8d 76 00             	lea    0x0(%esi),%esi
f0102029:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102030:	31 ff                	xor    %edi,%edi
f0102032:	31 c0                	xor    %eax,%eax
f0102034:	89 fa                	mov    %edi,%edx
f0102036:	83 c4 1c             	add    $0x1c,%esp
f0102039:	5b                   	pop    %ebx
f010203a:	5e                   	pop    %esi
f010203b:	5f                   	pop    %edi
f010203c:	5d                   	pop    %ebp
f010203d:	c3                   	ret    
f010203e:	66 90                	xchg   %ax,%ax
f0102040:	31 ff                	xor    %edi,%edi
f0102042:	89 e8                	mov    %ebp,%eax
f0102044:	89 f2                	mov    %esi,%edx
f0102046:	f7 f3                	div    %ebx
f0102048:	89 fa                	mov    %edi,%edx
f010204a:	83 c4 1c             	add    $0x1c,%esp
f010204d:	5b                   	pop    %ebx
f010204e:	5e                   	pop    %esi
f010204f:	5f                   	pop    %edi
f0102050:	5d                   	pop    %ebp
f0102051:	c3                   	ret    
f0102052:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102058:	39 f2                	cmp    %esi,%edx
f010205a:	72 06                	jb     f0102062 <__udivdi3+0x102>
f010205c:	31 c0                	xor    %eax,%eax
f010205e:	39 eb                	cmp    %ebp,%ebx
f0102060:	77 d2                	ja     f0102034 <__udivdi3+0xd4>
f0102062:	b8 01 00 00 00       	mov    $0x1,%eax
f0102067:	eb cb                	jmp    f0102034 <__udivdi3+0xd4>
f0102069:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102070:	89 d8                	mov    %ebx,%eax
f0102072:	31 ff                	xor    %edi,%edi
f0102074:	eb be                	jmp    f0102034 <__udivdi3+0xd4>
f0102076:	66 90                	xchg   %ax,%ax
f0102078:	66 90                	xchg   %ax,%ax
f010207a:	66 90                	xchg   %ax,%ax
f010207c:	66 90                	xchg   %ax,%ax
f010207e:	66 90                	xchg   %ax,%ax

f0102080 <__umoddi3>:
f0102080:	55                   	push   %ebp
f0102081:	57                   	push   %edi
f0102082:	56                   	push   %esi
f0102083:	53                   	push   %ebx
f0102084:	83 ec 1c             	sub    $0x1c,%esp
f0102087:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010208b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010208f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0102093:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102097:	85 ed                	test   %ebp,%ebp
f0102099:	89 f0                	mov    %esi,%eax
f010209b:	89 da                	mov    %ebx,%edx
f010209d:	75 19                	jne    f01020b8 <__umoddi3+0x38>
f010209f:	39 df                	cmp    %ebx,%edi
f01020a1:	0f 86 b1 00 00 00    	jbe    f0102158 <__umoddi3+0xd8>
f01020a7:	f7 f7                	div    %edi
f01020a9:	89 d0                	mov    %edx,%eax
f01020ab:	31 d2                	xor    %edx,%edx
f01020ad:	83 c4 1c             	add    $0x1c,%esp
f01020b0:	5b                   	pop    %ebx
f01020b1:	5e                   	pop    %esi
f01020b2:	5f                   	pop    %edi
f01020b3:	5d                   	pop    %ebp
f01020b4:	c3                   	ret    
f01020b5:	8d 76 00             	lea    0x0(%esi),%esi
f01020b8:	39 dd                	cmp    %ebx,%ebp
f01020ba:	77 f1                	ja     f01020ad <__umoddi3+0x2d>
f01020bc:	0f bd cd             	bsr    %ebp,%ecx
f01020bf:	83 f1 1f             	xor    $0x1f,%ecx
f01020c2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01020c6:	0f 84 b4 00 00 00    	je     f0102180 <__umoddi3+0x100>
f01020cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01020d1:	89 c2                	mov    %eax,%edx
f01020d3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01020d7:	29 c2                	sub    %eax,%edx
f01020d9:	89 c1                	mov    %eax,%ecx
f01020db:	89 f8                	mov    %edi,%eax
f01020dd:	d3 e5                	shl    %cl,%ebp
f01020df:	89 d1                	mov    %edx,%ecx
f01020e1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01020e5:	d3 e8                	shr    %cl,%eax
f01020e7:	09 c5                	or     %eax,%ebp
f01020e9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01020ed:	89 c1                	mov    %eax,%ecx
f01020ef:	d3 e7                	shl    %cl,%edi
f01020f1:	89 d1                	mov    %edx,%ecx
f01020f3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01020f7:	89 df                	mov    %ebx,%edi
f01020f9:	d3 ef                	shr    %cl,%edi
f01020fb:	89 c1                	mov    %eax,%ecx
f01020fd:	89 f0                	mov    %esi,%eax
f01020ff:	d3 e3                	shl    %cl,%ebx
f0102101:	89 d1                	mov    %edx,%ecx
f0102103:	89 fa                	mov    %edi,%edx
f0102105:	d3 e8                	shr    %cl,%eax
f0102107:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010210c:	09 d8                	or     %ebx,%eax
f010210e:	f7 f5                	div    %ebp
f0102110:	d3 e6                	shl    %cl,%esi
f0102112:	89 d1                	mov    %edx,%ecx
f0102114:	f7 64 24 08          	mull   0x8(%esp)
f0102118:	39 d1                	cmp    %edx,%ecx
f010211a:	89 c3                	mov    %eax,%ebx
f010211c:	89 d7                	mov    %edx,%edi
f010211e:	72 06                	jb     f0102126 <__umoddi3+0xa6>
f0102120:	75 0e                	jne    f0102130 <__umoddi3+0xb0>
f0102122:	39 c6                	cmp    %eax,%esi
f0102124:	73 0a                	jae    f0102130 <__umoddi3+0xb0>
f0102126:	2b 44 24 08          	sub    0x8(%esp),%eax
f010212a:	19 ea                	sbb    %ebp,%edx
f010212c:	89 d7                	mov    %edx,%edi
f010212e:	89 c3                	mov    %eax,%ebx
f0102130:	89 ca                	mov    %ecx,%edx
f0102132:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0102137:	29 de                	sub    %ebx,%esi
f0102139:	19 fa                	sbb    %edi,%edx
f010213b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010213f:	89 d0                	mov    %edx,%eax
f0102141:	d3 e0                	shl    %cl,%eax
f0102143:	89 d9                	mov    %ebx,%ecx
f0102145:	d3 ee                	shr    %cl,%esi
f0102147:	d3 ea                	shr    %cl,%edx
f0102149:	09 f0                	or     %esi,%eax
f010214b:	83 c4 1c             	add    $0x1c,%esp
f010214e:	5b                   	pop    %ebx
f010214f:	5e                   	pop    %esi
f0102150:	5f                   	pop    %edi
f0102151:	5d                   	pop    %ebp
f0102152:	c3                   	ret    
f0102153:	90                   	nop
f0102154:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102158:	85 ff                	test   %edi,%edi
f010215a:	89 f9                	mov    %edi,%ecx
f010215c:	75 0b                	jne    f0102169 <__umoddi3+0xe9>
f010215e:	b8 01 00 00 00       	mov    $0x1,%eax
f0102163:	31 d2                	xor    %edx,%edx
f0102165:	f7 f7                	div    %edi
f0102167:	89 c1                	mov    %eax,%ecx
f0102169:	89 d8                	mov    %ebx,%eax
f010216b:	31 d2                	xor    %edx,%edx
f010216d:	f7 f1                	div    %ecx
f010216f:	89 f0                	mov    %esi,%eax
f0102171:	f7 f1                	div    %ecx
f0102173:	e9 31 ff ff ff       	jmp    f01020a9 <__umoddi3+0x29>
f0102178:	90                   	nop
f0102179:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102180:	39 dd                	cmp    %ebx,%ebp
f0102182:	72 08                	jb     f010218c <__umoddi3+0x10c>
f0102184:	39 f7                	cmp    %esi,%edi
f0102186:	0f 87 21 ff ff ff    	ja     f01020ad <__umoddi3+0x2d>
f010218c:	89 da                	mov    %ebx,%edx
f010218e:	89 f0                	mov    %esi,%eax
f0102190:	29 f8                	sub    %edi,%eax
f0102192:	19 ea                	sbb    %ebp,%edx
f0102194:	e9 14 ff ff ff       	jmp    f01020ad <__umoddi3+0x2d>
