
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
f0100015:	b8 00 30 11 00       	mov    $0x113000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

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
f010004c:	81 c3 bc 22 01 00    	add    $0x122bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 40 11 f0    	mov    $0xf0114060,%edx
f0100058:	c7 c0 a0 46 11 f0    	mov    $0xf01146a0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 18 18 00 00       	call   f0101881 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 b8 f9 fe ff    	lea    -0x10648(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 ea 0b 00 00       	call   f0100c6c <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 16 0a 00 00       	call   f0100a9d <mem_init>
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
f01000a7:	81 c3 61 22 01 00    	add    $0x12261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 a4 46 11 f0    	mov    $0xf01146a4,%eax
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
f01000da:	8d 83 d3 f9 fe ff    	lea    -0x1062d(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 86 0b 00 00       	call   f0100c6c <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 45 0b 00 00       	call   f0100c35 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 0f fa fe ff    	lea    -0x105f1(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 6e 0b 00 00       	call   f0100c6c <cprintf>
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
f010010d:	81 c3 fb 21 01 00    	add    $0x121fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 eb f9 fe ff    	lea    -0x10615(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 41 0b 00 00       	call   f0100c6c <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 fe 0a 00 00       	call   f0100c35 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 0f fa fe ff    	lea    -0x105f1(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 27 0b 00 00       	call   f0100c6c <cprintf>
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
f010017c:	81 c3 8c 21 01 00    	add    $0x1218c,%ebx
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
f01001c7:	81 c3 41 21 01 00    	add    $0x12141,%ebx
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
f0100217:	0f b6 84 13 38 fb fe 	movzbl -0x104c8(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 38 fa fe 	movzbl -0x105c8(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 05 fa fe ff    	lea    -0x105fb(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 f6 09 00 00       	call   f0100c6c <cprintf>
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
f01002b1:	0f b6 84 13 38 fb fe 	movzbl -0x104c8(%ebx,%edx,1),%eax
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
f01002fd:	81 c3 0b 20 01 00    	add    $0x1200b,%ebx
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
f01004d2:	e8 f7 13 00 00       	call   f01018ce <memmove>
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
f010050a:	05 fe 1d 01 00       	add    $0x11dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b de fe ff    	lea    -0x121b5(%eax),%eax
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
f0100538:	05 d0 1d 01 00       	add    $0x11dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 de fe ff    	lea    -0x1214b(%eax),%eax
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
f0100556:	81 c3 b2 1d 01 00    	add    $0x11db2,%ebx
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
f01005b2:	81 c3 56 1d 01 00    	add    $0x11d56,%ebx
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
f01006b5:	8d 83 11 fa fe ff    	lea    -0x105ef(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 ab 05 00 00       	call   f0100c6c <cprintf>
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
f01006ff:	81 c3 09 1c 01 00    	add    $0x11c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 38 fc fe ff    	lea    -0x103c8(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 56 fc fe ff    	lea    -0x103aa(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 5b fc fe ff    	lea    -0x103a5(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 4a 05 00 00       	call   f0100c6c <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 18 fd fe ff    	lea    -0x102e8(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 64 fc fe ff    	lea    -0x1039c(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 33 05 00 00       	call   f0100c6c <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 40 fd fe ff    	lea    -0x102c0(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 6d fc fe ff    	lea    -0x10393(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 1c 05 00 00       	call   f0100c6c <cprintf>
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
f010076a:	81 c3 9e 1b 01 00    	add    $0x11b9e,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100770:	8d 83 77 fc fe ff    	lea    -0x10389(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 f0 04 00 00       	call   f0100c6c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f0100785:	8d 83 64 fd fe ff    	lea    -0x1029c(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 db 04 00 00       	call   f0100c6c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 8c fd fe ff    	lea    -0x10274(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 be 04 00 00       	call   f0100c6c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 b9 1c 10 f0    	mov    $0xf0101cb9,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 b0 fd fe ff    	lea    -0x10250(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 a1 04 00 00       	call   f0100c6c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 40 11 f0    	mov    $0xf0114060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 d4 fd fe ff    	lea    -0x1022c(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 84 04 00 00       	call   f0100c6c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 a0 46 11 f0    	mov    $0xf01146a0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 f8 fd fe ff    	lea    -0x10208(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 67 04 00 00       	call   f0100c6c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 1c fe fe ff    	lea    -0x101e4(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 4c 04 00 00       	call   f0100c6c <cprintf>
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
f010083b:	81 c3 cd 1a 01 00    	add    $0x11acd,%ebx
	// Your code here.
	cprintf("Stack backtrace:\n");
f0100841:	8d 83 90 fc fe ff    	lea    -0x10370(%ebx),%eax
f0100847:	50                   	push   %eax
f0100848:	e8 1f 04 00 00       	call   f0100c6c <cprintf>

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
f0100852:	8d 83 a2 fc fe ff    	lea    -0x1035e(%ebx),%eax
f0100858:	89 45 b8             	mov    %eax,-0x48(%ebp)
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
f010085b:	8d 83 bd fc fe ff    	lea    -0x10343(%ebx),%eax
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
f010087c:	e8 eb 03 00 00       	call   f0100c6c <cprintf>
f0100881:	8d 77 08             	lea    0x8(%edi),%esi
f0100884:	83 c7 1c             	add    $0x1c,%edi
f0100887:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	ff 36                	pushl  (%esi)
f010088f:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100892:	e8 d5 03 00 00       	call   f0100c6c <cprintf>
f0100897:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	39 fe                	cmp    %edi,%esi
f010089f:	75 e9                	jne    f010088a <mon_backtrace+0x5d>
		}
		cprintf("\n");
f01008a1:	83 ec 0c             	sub    $0xc,%esp
f01008a4:	8d 83 0f fa fe ff    	lea    -0x105f1(%ebx),%eax
f01008aa:	50                   	push   %eax
f01008ab:	e8 bc 03 00 00       	call   f0100c6c <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008b0:	83 c4 08             	add    $0x8,%esp
f01008b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008b6:	50                   	push   %eax
f01008b7:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008ba:	57                   	push   %edi
f01008bb:	e8 b0 04 00 00       	call   f0100d70 <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f01008c0:	83 c4 0c             	add    $0xc,%esp
f01008c3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008c9:	8d 83 c3 fc fe ff    	lea    -0x1033d(%ebx),%eax
f01008cf:	50                   	push   %eax
f01008d0:	e8 97 03 00 00       	call   f0100c6c <cprintf>
		// for (int i = 0; i < info.eip_fn_namelen;++i){
		// 	cprintf("%c", info.eip_fn_name[i]);
		// }
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f01008d5:	89 f8                	mov    %edi,%eax
f01008d7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008da:	50                   	push   %eax
f01008db:	ff 75 d8             	pushl  -0x28(%ebp)
f01008de:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e1:	8d 83 d3 fc fe ff    	lea    -0x1032d(%ebx),%eax
f01008e7:	50                   	push   %eax
f01008e8:	e8 7f 03 00 00       	call   f0100c6c <cprintf>
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
f0100916:	81 c3 f2 19 01 00    	add    $0x119f2,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010091c:	8d 83 48 fe fe ff    	lea    -0x101b8(%ebx),%eax
f0100922:	50                   	push   %eax
f0100923:	e8 44 03 00 00       	call   f0100c6c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100928:	8d 83 6c fe fe ff    	lea    -0x10194(%ebx),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 36 03 00 00       	call   f0100c6c <cprintf>
f0100936:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100939:	8d bb e0 fc fe ff    	lea    -0x10320(%ebx),%edi
f010093f:	eb 4a                	jmp    f010098b <monitor+0x83>
f0100941:	83 ec 08             	sub    $0x8,%esp
f0100944:	0f be c0             	movsbl %al,%eax
f0100947:	50                   	push   %eax
f0100948:	57                   	push   %edi
f0100949:	e8 f6 0e 00 00       	call   f0101844 <strchr>
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
f010097c:	8d 83 e5 fc fe ff    	lea    -0x1031b(%ebx),%eax
f0100982:	50                   	push   %eax
f0100983:	e8 e4 02 00 00       	call   f0100c6c <cprintf>
f0100988:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010098b:	8d 83 dc fc fe ff    	lea    -0x10324(%ebx),%eax
f0100991:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100994:	83 ec 0c             	sub    $0xc,%esp
f0100997:	ff 75 a4             	pushl  -0x5c(%ebp)
f010099a:	e8 6d 0c 00 00       	call   f010160c <readline>
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
f01009ca:	e8 75 0e 00 00       	call   f0101844 <strchr>
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
f0100a05:	e8 dc 0d 00 00       	call   f01017e6 <strcmp>
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
f0100a26:	8d 83 02 fd fe ff    	lea    -0x102fe(%ebx),%eax
f0100a2c:	50                   	push   %eax
f0100a2d:	e8 3a 02 00 00       	call   f0100c6c <cprintf>
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

f0100a67 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a67:	55                   	push   %ebp
f0100a68:	89 e5                	mov    %esp,%ebp
f0100a6a:	57                   	push   %edi
f0100a6b:	56                   	push   %esi
f0100a6c:	53                   	push   %ebx
f0100a6d:	83 ec 18             	sub    $0x18,%esp
f0100a70:	e8 da f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a75:	81 c3 93 18 01 00    	add    $0x11893,%ebx
f0100a7b:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a7d:	50                   	push   %eax
f0100a7e:	e8 62 01 00 00       	call   f0100be5 <mc146818_read>
f0100a83:	89 c6                	mov    %eax,%esi
f0100a85:	83 c7 01             	add    $0x1,%edi
f0100a88:	89 3c 24             	mov    %edi,(%esp)
f0100a8b:	e8 55 01 00 00       	call   f0100be5 <mc146818_read>
f0100a90:	c1 e0 08             	shl    $0x8,%eax
f0100a93:	09 f0                	or     %esi,%eax
}
f0100a95:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a98:	5b                   	pop    %ebx
f0100a99:	5e                   	pop    %esi
f0100a9a:	5f                   	pop    %edi
f0100a9b:	5d                   	pop    %ebp
f0100a9c:	c3                   	ret    

f0100a9d <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100a9d:	55                   	push   %ebp
f0100a9e:	89 e5                	mov    %esp,%ebp
f0100aa0:	57                   	push   %edi
f0100aa1:	56                   	push   %esi
f0100aa2:	53                   	push   %ebx
f0100aa3:	83 ec 0c             	sub    $0xc,%esp
f0100aa6:	e8 a4 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100aab:	81 c3 5d 18 01 00    	add    $0x1185d,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100ab1:	b8 15 00 00 00       	mov    $0x15,%eax
f0100ab6:	e8 ac ff ff ff       	call   f0100a67 <nvram_read>
f0100abb:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f0100abd:	b8 17 00 00 00       	mov    $0x17,%eax
f0100ac2:	e8 a0 ff ff ff       	call   f0100a67 <nvram_read>
f0100ac7:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100ac9:	b8 34 00 00 00       	mov    $0x34,%eax
f0100ace:	e8 94 ff ff ff       	call   f0100a67 <nvram_read>
f0100ad3:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100ad6:	85 c0                	test   %eax,%eax
f0100ad8:	75 0e                	jne    f0100ae8 <mem_init+0x4b>
		totalmem = basemem;
f0100ada:	89 f0                	mov    %esi,%eax
	else if (extmem)
f0100adc:	85 ff                	test   %edi,%edi
f0100ade:	74 0d                	je     f0100aed <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f0100ae0:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f0100ae6:	eb 05                	jmp    f0100aed <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100ae8:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100aed:	89 c1                	mov    %eax,%ecx
f0100aef:	c1 e9 02             	shr    $0x2,%ecx
f0100af2:	c7 c2 a8 46 11 f0    	mov    $0xf01146a8,%edx
f0100af8:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100afa:	89 c2                	mov    %eax,%edx
f0100afc:	29 f2                	sub    %esi,%edx
f0100afe:	52                   	push   %edx
f0100aff:	56                   	push   %esi
f0100b00:	50                   	push   %eax
f0100b01:	8d 83 94 fe fe ff    	lea    -0x1016c(%ebx),%eax
f0100b07:	50                   	push   %eax
f0100b08:	e8 5f 01 00 00       	call   f0100c6c <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f0100b0d:	83 c4 0c             	add    $0xc,%esp
f0100b10:	8d 83 d0 fe fe ff    	lea    -0x10130(%ebx),%eax
f0100b16:	50                   	push   %eax
f0100b17:	68 80 00 00 00       	push   $0x80
f0100b1c:	8d 83 fc fe fe ff    	lea    -0x10104(%ebx),%eax
f0100b22:	50                   	push   %eax
f0100b23:	e8 71 f5 ff ff       	call   f0100099 <_panic>

f0100b28 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100b28:	55                   	push   %ebp
f0100b29:	89 e5                	mov    %esp,%ebp
f0100b2b:	57                   	push   %edi
f0100b2c:	56                   	push   %esi
f0100b2d:	53                   	push   %ebx
f0100b2e:	83 ec 04             	sub    $0x4,%esp
f0100b31:	e8 ab 00 00 00       	call   f0100be1 <__x86.get_pc_thunk.si>
f0100b36:	81 c6 d2 17 01 00    	add    $0x117d2,%esi
f0100b3c:	89 75 f0             	mov    %esi,-0x10(%ebp)
f0100b3f:	8b 9e 90 1f 00 00    	mov    0x1f90(%esi),%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100b45:	ba 00 00 00 00       	mov    $0x0,%edx
f0100b4a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b4f:	c7 c7 a8 46 11 f0    	mov    $0xf01146a8,%edi
		pages[i].pp_ref = 0;
f0100b55:	c7 c6 b0 46 11 f0    	mov    $0xf01146b0,%esi
	for (i = 0; i < npages; i++) {
f0100b5b:	eb 1f                	jmp    f0100b7c <page_init+0x54>
f0100b5d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100b64:	89 d1                	mov    %edx,%ecx
f0100b66:	03 0e                	add    (%esi),%ecx
f0100b68:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100b6e:	89 19                	mov    %ebx,(%ecx)
	for (i = 0; i < npages; i++) {
f0100b70:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100b73:	89 d3                	mov    %edx,%ebx
f0100b75:	03 1e                	add    (%esi),%ebx
f0100b77:	ba 01 00 00 00       	mov    $0x1,%edx
	for (i = 0; i < npages; i++) {
f0100b7c:	39 07                	cmp    %eax,(%edi)
f0100b7e:	77 dd                	ja     f0100b5d <page_init+0x35>
f0100b80:	84 d2                	test   %dl,%dl
f0100b82:	75 08                	jne    f0100b8c <page_init+0x64>
	}
}
f0100b84:	83 c4 04             	add    $0x4,%esp
f0100b87:	5b                   	pop    %ebx
f0100b88:	5e                   	pop    %esi
f0100b89:	5f                   	pop    %edi
f0100b8a:	5d                   	pop    %ebp
f0100b8b:	c3                   	ret    
f0100b8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b8f:	89 98 90 1f 00 00    	mov    %ebx,0x1f90(%eax)
f0100b95:	eb ed                	jmp    f0100b84 <page_init+0x5c>

f0100b97 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100b97:	55                   	push   %ebp
f0100b98:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100b9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b9f:	5d                   	pop    %ebp
f0100ba0:	c3                   	ret    

f0100ba1 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ba1:	55                   	push   %ebp
f0100ba2:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100ba4:	5d                   	pop    %ebp
f0100ba5:	c3                   	ret    

f0100ba6 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100ba6:	55                   	push   %ebp
f0100ba7:	89 e5                	mov    %esp,%ebp
f0100ba9:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100bac:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100bb1:	5d                   	pop    %ebp
f0100bb2:	c3                   	ret    

f0100bb3 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100bb3:	55                   	push   %ebp
f0100bb4:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100bb6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bbb:	5d                   	pop    %ebp
f0100bbc:	c3                   	ret    

f0100bbd <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100bbd:	55                   	push   %ebp
f0100bbe:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100bc0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bc5:	5d                   	pop    %ebp
f0100bc6:	c3                   	ret    

f0100bc7 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100bc7:	55                   	push   %ebp
f0100bc8:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100bca:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bcf:	5d                   	pop    %ebp
f0100bd0:	c3                   	ret    

f0100bd1 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100bd1:	55                   	push   %ebp
f0100bd2:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100bd4:	5d                   	pop    %ebp
f0100bd5:	c3                   	ret    

f0100bd6 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100bd6:	55                   	push   %ebp
f0100bd7:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100bd9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bdc:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100bdf:	5d                   	pop    %ebp
f0100be0:	c3                   	ret    

f0100be1 <__x86.get_pc_thunk.si>:
f0100be1:	8b 34 24             	mov    (%esp),%esi
f0100be4:	c3                   	ret    

f0100be5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100be5:	55                   	push   %ebp
f0100be6:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100be8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100beb:	ba 70 00 00 00       	mov    $0x70,%edx
f0100bf0:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100bf1:	ba 71 00 00 00       	mov    $0x71,%edx
f0100bf6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100bf7:	0f b6 c0             	movzbl %al,%eax
}
f0100bfa:	5d                   	pop    %ebp
f0100bfb:	c3                   	ret    

f0100bfc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100bfc:	55                   	push   %ebp
f0100bfd:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100bff:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c02:	ba 70 00 00 00       	mov    $0x70,%edx
f0100c07:	ee                   	out    %al,(%dx)
f0100c08:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c0b:	ba 71 00 00 00       	mov    $0x71,%edx
f0100c10:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100c11:	5d                   	pop    %ebp
f0100c12:	c3                   	ret    

f0100c13 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100c13:	55                   	push   %ebp
f0100c14:	89 e5                	mov    %esp,%ebp
f0100c16:	53                   	push   %ebx
f0100c17:	83 ec 10             	sub    $0x10,%esp
f0100c1a:	e8 30 f5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c1f:	81 c3 e9 16 01 00    	add    $0x116e9,%ebx
	cputchar(ch);
f0100c25:	ff 75 08             	pushl  0x8(%ebp)
f0100c28:	e8 99 fa ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0100c2d:	83 c4 10             	add    $0x10,%esp
f0100c30:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100c33:	c9                   	leave  
f0100c34:	c3                   	ret    

f0100c35 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100c35:	55                   	push   %ebp
f0100c36:	89 e5                	mov    %esp,%ebp
f0100c38:	53                   	push   %ebx
f0100c39:	83 ec 14             	sub    $0x14,%esp
f0100c3c:	e8 0e f5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c41:	81 c3 c7 16 01 00    	add    $0x116c7,%ebx
	int cnt = 0;
f0100c47:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100c4e:	ff 75 0c             	pushl  0xc(%ebp)
f0100c51:	ff 75 08             	pushl  0x8(%ebp)
f0100c54:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100c57:	50                   	push   %eax
f0100c58:	8d 83 0b e9 fe ff    	lea    -0x116f5(%ebx),%eax
f0100c5e:	50                   	push   %eax
f0100c5f:	e8 98 04 00 00       	call   f01010fc <vprintfmt>
	return cnt;
}
f0100c64:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c67:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100c6a:	c9                   	leave  
f0100c6b:	c3                   	ret    

f0100c6c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100c6c:	55                   	push   %ebp
f0100c6d:	89 e5                	mov    %esp,%ebp
f0100c6f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100c72:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100c75:	50                   	push   %eax
f0100c76:	ff 75 08             	pushl  0x8(%ebp)
f0100c79:	e8 b7 ff ff ff       	call   f0100c35 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100c7e:	c9                   	leave  
f0100c7f:	c3                   	ret    

f0100c80 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100c80:	55                   	push   %ebp
f0100c81:	89 e5                	mov    %esp,%ebp
f0100c83:	57                   	push   %edi
f0100c84:	56                   	push   %esi
f0100c85:	53                   	push   %ebx
f0100c86:	83 ec 14             	sub    $0x14,%esp
f0100c89:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100c8c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100c8f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c92:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100c95:	8b 32                	mov    (%edx),%esi
f0100c97:	8b 01                	mov    (%ecx),%eax
f0100c99:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100c9c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100ca3:	eb 2f                	jmp    f0100cd4 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100ca5:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100ca8:	39 c6                	cmp    %eax,%esi
f0100caa:	7f 49                	jg     f0100cf5 <stab_binsearch+0x75>
f0100cac:	0f b6 0a             	movzbl (%edx),%ecx
f0100caf:	83 ea 0c             	sub    $0xc,%edx
f0100cb2:	39 f9                	cmp    %edi,%ecx
f0100cb4:	75 ef                	jne    f0100ca5 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100cb6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100cb9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100cbc:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100cc0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100cc3:	73 35                	jae    f0100cfa <stab_binsearch+0x7a>
			*region_left = m;
f0100cc5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cc8:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100cca:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100ccd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100cd4:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100cd7:	7f 4e                	jg     f0100d27 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100cd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100cdc:	01 f0                	add    %esi,%eax
f0100cde:	89 c3                	mov    %eax,%ebx
f0100ce0:	c1 eb 1f             	shr    $0x1f,%ebx
f0100ce3:	01 c3                	add    %eax,%ebx
f0100ce5:	d1 fb                	sar    %ebx
f0100ce7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100cea:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ced:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100cf1:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100cf3:	eb b3                	jmp    f0100ca8 <stab_binsearch+0x28>
			l = true_m + 1;
f0100cf5:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100cf8:	eb da                	jmp    f0100cd4 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100cfa:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100cfd:	76 14                	jbe    f0100d13 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100cff:	83 e8 01             	sub    $0x1,%eax
f0100d02:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100d05:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100d08:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100d0a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100d11:	eb c1                	jmp    f0100cd4 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100d13:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100d16:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100d18:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100d1c:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100d1e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100d25:	eb ad                	jmp    f0100cd4 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100d27:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100d2b:	74 16                	je     f0100d43 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d30:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100d32:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100d35:	8b 0e                	mov    (%esi),%ecx
f0100d37:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d3a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100d3d:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100d41:	eb 12                	jmp    f0100d55 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100d43:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d46:	8b 00                	mov    (%eax),%eax
f0100d48:	83 e8 01             	sub    $0x1,%eax
f0100d4b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100d4e:	89 07                	mov    %eax,(%edi)
f0100d50:	eb 16                	jmp    f0100d68 <stab_binsearch+0xe8>
		     l--)
f0100d52:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100d55:	39 c1                	cmp    %eax,%ecx
f0100d57:	7d 0a                	jge    f0100d63 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100d59:	0f b6 1a             	movzbl (%edx),%ebx
f0100d5c:	83 ea 0c             	sub    $0xc,%edx
f0100d5f:	39 fb                	cmp    %edi,%ebx
f0100d61:	75 ef                	jne    f0100d52 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100d63:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d66:	89 07                	mov    %eax,(%edi)
	}
}
f0100d68:	83 c4 14             	add    $0x14,%esp
f0100d6b:	5b                   	pop    %ebx
f0100d6c:	5e                   	pop    %esi
f0100d6d:	5f                   	pop    %edi
f0100d6e:	5d                   	pop    %ebp
f0100d6f:	c3                   	ret    

f0100d70 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100d70:	55                   	push   %ebp
f0100d71:	89 e5                	mov    %esp,%ebp
f0100d73:	57                   	push   %edi
f0100d74:	56                   	push   %esi
f0100d75:	53                   	push   %ebx
f0100d76:	83 ec 3c             	sub    $0x3c,%esp
f0100d79:	e8 d1 f3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100d7e:	81 c3 8a 15 01 00    	add    $0x1158a,%ebx
f0100d84:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100d87:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100d8a:	8d 83 08 ff fe ff    	lea    -0x100f8(%ebx),%eax
f0100d90:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0100d92:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100d99:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100d9c:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100da3:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100da6:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100dad:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100db3:	0f 86 37 01 00 00    	jbe    f0100ef0 <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100db9:	c7 c0 99 69 10 f0    	mov    $0xf0106999,%eax
f0100dbf:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0100dc5:	0f 86 04 02 00 00    	jbe    f0100fcf <debuginfo_eip+0x25f>
f0100dcb:	c7 c0 ec 85 10 f0    	mov    $0xf01085ec,%eax
f0100dd1:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100dd5:	0f 85 fb 01 00 00    	jne    f0100fd6 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ddb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100de2:	c7 c0 2c 24 10 f0    	mov    $0xf010242c,%eax
f0100de8:	c7 c2 98 69 10 f0    	mov    $0xf0106998,%edx
f0100dee:	29 c2                	sub    %eax,%edx
f0100df0:	c1 fa 02             	sar    $0x2,%edx
f0100df3:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100df9:	83 ea 01             	sub    $0x1,%edx
f0100dfc:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100dff:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100e02:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100e05:	83 ec 08             	sub    $0x8,%esp
f0100e08:	57                   	push   %edi
f0100e09:	6a 64                	push   $0x64
f0100e0b:	e8 70 fe ff ff       	call   f0100c80 <stab_binsearch>
	if (lfile == 0)
f0100e10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e13:	83 c4 10             	add    $0x10,%esp
f0100e16:	85 c0                	test   %eax,%eax
f0100e18:	0f 84 bf 01 00 00    	je     f0100fdd <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100e1e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100e21:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e24:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100e27:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100e2a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e2d:	83 ec 08             	sub    $0x8,%esp
f0100e30:	57                   	push   %edi
f0100e31:	6a 24                	push   $0x24
f0100e33:	c7 c0 2c 24 10 f0    	mov    $0xf010242c,%eax
f0100e39:	e8 42 fe ff ff       	call   f0100c80 <stab_binsearch>

	if (lfun <= rfun) {
f0100e3e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e41:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100e44:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100e47:	83 c4 10             	add    $0x10,%esp
f0100e4a:	39 c8                	cmp    %ecx,%eax
f0100e4c:	0f 8f b6 00 00 00    	jg     f0100f08 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100e52:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e55:	c7 c1 2c 24 10 f0    	mov    $0xf010242c,%ecx
f0100e5b:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0100e5e:	8b 11                	mov    (%ecx),%edx
f0100e60:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0100e63:	c7 c2 ec 85 10 f0    	mov    $0xf01085ec,%edx
f0100e69:	81 ea 99 69 10 f0    	sub    $0xf0106999,%edx
f0100e6f:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0100e72:	73 0c                	jae    f0100e80 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100e74:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0100e77:	81 c2 99 69 10 f0    	add    $0xf0106999,%edx
f0100e7d:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100e80:	8b 51 08             	mov    0x8(%ecx),%edx
f0100e83:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100e86:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0100e88:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100e8b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e8e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100e91:	83 ec 08             	sub    $0x8,%esp
f0100e94:	6a 3a                	push   $0x3a
f0100e96:	ff 76 08             	pushl  0x8(%esi)
f0100e99:	e8 c7 09 00 00       	call   f0101865 <strfind>
f0100e9e:	2b 46 08             	sub    0x8(%esi),%eax
f0100ea1:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100ea4:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100ea7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100eaa:	83 c4 08             	add    $0x8,%esp
f0100ead:	57                   	push   %edi
f0100eae:	6a 44                	push   $0x44
f0100eb0:	c7 c0 2c 24 10 f0    	mov    $0xf010242c,%eax
f0100eb6:	e8 c5 fd ff ff       	call   f0100c80 <stab_binsearch>
	if(lline<=rline){
f0100ebb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100ebe:	83 c4 10             	add    $0x10,%esp
f0100ec1:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100ec4:	0f 8f 1a 01 00 00    	jg     f0100fe4 <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f0100eca:	89 d0                	mov    %edx,%eax
f0100ecc:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100ecf:	c1 e2 02             	shl    $0x2,%edx
f0100ed2:	c7 c1 2c 24 10 f0    	mov    $0xf010242c,%ecx
f0100ed8:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0100edd:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ee0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ee3:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0100ee7:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0100eeb:	89 75 0c             	mov    %esi,0xc(%ebp)
f0100eee:	eb 36                	jmp    f0100f26 <debuginfo_eip+0x1b6>
  	        panic("User address");
f0100ef0:	83 ec 04             	sub    $0x4,%esp
f0100ef3:	8d 83 12 ff fe ff    	lea    -0x100ee(%ebx),%eax
f0100ef9:	50                   	push   %eax
f0100efa:	6a 7f                	push   $0x7f
f0100efc:	8d 83 1f ff fe ff    	lea    -0x100e1(%ebx),%eax
f0100f02:	50                   	push   %eax
f0100f03:	e8 91 f1 ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0100f08:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100f0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f0e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100f11:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f14:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f17:	e9 75 ff ff ff       	jmp    f0100e91 <debuginfo_eip+0x121>
f0100f1c:	83 e8 01             	sub    $0x1,%eax
f0100f1f:	83 ea 0c             	sub    $0xc,%edx
f0100f22:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0100f26:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0100f29:	39 c7                	cmp    %eax,%edi
f0100f2b:	7f 24                	jg     f0100f51 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f0100f2d:	0f b6 0a             	movzbl (%edx),%ecx
f0100f30:	80 f9 84             	cmp    $0x84,%cl
f0100f33:	74 46                	je     f0100f7b <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100f35:	80 f9 64             	cmp    $0x64,%cl
f0100f38:	75 e2                	jne    f0100f1c <debuginfo_eip+0x1ac>
f0100f3a:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0100f3e:	74 dc                	je     f0100f1c <debuginfo_eip+0x1ac>
f0100f40:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100f43:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0100f47:	74 3b                	je     f0100f84 <debuginfo_eip+0x214>
f0100f49:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100f4c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f4f:	eb 33                	jmp    f0100f84 <debuginfo_eip+0x214>
f0100f51:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100f54:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f57:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100f5a:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100f5f:	39 fa                	cmp    %edi,%edx
f0100f61:	0f 8d 89 00 00 00    	jge    f0100ff0 <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0100f67:	83 c2 01             	add    $0x1,%edx
f0100f6a:	89 d0                	mov    %edx,%eax
f0100f6c:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0100f6f:	c7 c2 2c 24 10 f0    	mov    $0xf010242c,%edx
f0100f75:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0100f79:	eb 3b                	jmp    f0100fb6 <debuginfo_eip+0x246>
f0100f7b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100f7e:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0100f82:	75 26                	jne    f0100faa <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100f84:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100f87:	c7 c0 2c 24 10 f0    	mov    $0xf010242c,%eax
f0100f8d:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100f90:	c7 c0 ec 85 10 f0    	mov    $0xf01085ec,%eax
f0100f96:	81 e8 99 69 10 f0    	sub    $0xf0106999,%eax
f0100f9c:	39 c2                	cmp    %eax,%edx
f0100f9e:	73 b4                	jae    f0100f54 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100fa0:	81 c2 99 69 10 f0    	add    $0xf0106999,%edx
f0100fa6:	89 16                	mov    %edx,(%esi)
f0100fa8:	eb aa                	jmp    f0100f54 <debuginfo_eip+0x1e4>
f0100faa:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100fad:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fb0:	eb d2                	jmp    f0100f84 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0100fb2:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0100fb6:	39 c7                	cmp    %eax,%edi
f0100fb8:	7e 31                	jle    f0100feb <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100fba:	0f b6 0a             	movzbl (%edx),%ecx
f0100fbd:	83 c0 01             	add    $0x1,%eax
f0100fc0:	83 c2 0c             	add    $0xc,%edx
f0100fc3:	80 f9 a0             	cmp    $0xa0,%cl
f0100fc6:	74 ea                	je     f0100fb2 <debuginfo_eip+0x242>
	return 0;
f0100fc8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fcd:	eb 21                	jmp    f0100ff0 <debuginfo_eip+0x280>
		return -1;
f0100fcf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100fd4:	eb 1a                	jmp    f0100ff0 <debuginfo_eip+0x280>
f0100fd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100fdb:	eb 13                	jmp    f0100ff0 <debuginfo_eip+0x280>
		return -1;
f0100fdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100fe2:	eb 0c                	jmp    f0100ff0 <debuginfo_eip+0x280>
		return -1;
f0100fe4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100fe9:	eb 05                	jmp    f0100ff0 <debuginfo_eip+0x280>
	return 0;
f0100feb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ff0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ff3:	5b                   	pop    %ebx
f0100ff4:	5e                   	pop    %esi
f0100ff5:	5f                   	pop    %edi
f0100ff6:	5d                   	pop    %ebp
f0100ff7:	c3                   	ret    

f0100ff8 <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100ff8:	55                   	push   %ebp
f0100ff9:	89 e5                	mov    %esp,%ebp
f0100ffb:	57                   	push   %edi
f0100ffc:	56                   	push   %esi
f0100ffd:	53                   	push   %ebx
f0100ffe:	83 ec 2c             	sub    $0x2c,%esp
f0101001:	e8 02 06 00 00       	call   f0101608 <__x86.get_pc_thunk.cx>
f0101006:	81 c1 02 13 01 00    	add    $0x11302,%ecx
f010100c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010100f:	89 c7                	mov    %eax,%edi
f0101011:	89 d6                	mov    %edx,%esi
f0101013:	8b 45 08             	mov    0x8(%ebp),%eax
f0101016:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101019:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010101c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010101f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101022:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101027:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f010102a:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010102d:	39 d3                	cmp    %edx,%ebx
f010102f:	72 09                	jb     f010103a <printnum+0x42>
f0101031:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101034:	0f 87 83 00 00 00    	ja     f01010bd <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010103a:	83 ec 0c             	sub    $0xc,%esp
f010103d:	ff 75 18             	pushl  0x18(%ebp)
f0101040:	8b 45 14             	mov    0x14(%ebp),%eax
f0101043:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101046:	53                   	push   %ebx
f0101047:	ff 75 10             	pushl  0x10(%ebp)
f010104a:	83 ec 08             	sub    $0x8,%esp
f010104d:	ff 75 dc             	pushl  -0x24(%ebp)
f0101050:	ff 75 d8             	pushl  -0x28(%ebp)
f0101053:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101056:	ff 75 d0             	pushl  -0x30(%ebp)
f0101059:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010105c:	e8 1f 0a 00 00       	call   f0101a80 <__udivdi3>
f0101061:	83 c4 18             	add    $0x18,%esp
f0101064:	52                   	push   %edx
f0101065:	50                   	push   %eax
f0101066:	89 f2                	mov    %esi,%edx
f0101068:	89 f8                	mov    %edi,%eax
f010106a:	e8 89 ff ff ff       	call   f0100ff8 <printnum>
f010106f:	83 c4 20             	add    $0x20,%esp
f0101072:	eb 13                	jmp    f0101087 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101074:	83 ec 08             	sub    $0x8,%esp
f0101077:	56                   	push   %esi
f0101078:	ff 75 18             	pushl  0x18(%ebp)
f010107b:	ff d7                	call   *%edi
f010107d:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0101080:	83 eb 01             	sub    $0x1,%ebx
f0101083:	85 db                	test   %ebx,%ebx
f0101085:	7f ed                	jg     f0101074 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101087:	83 ec 08             	sub    $0x8,%esp
f010108a:	56                   	push   %esi
f010108b:	83 ec 04             	sub    $0x4,%esp
f010108e:	ff 75 dc             	pushl  -0x24(%ebp)
f0101091:	ff 75 d8             	pushl  -0x28(%ebp)
f0101094:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101097:	ff 75 d0             	pushl  -0x30(%ebp)
f010109a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010109d:	89 f3                	mov    %esi,%ebx
f010109f:	e8 fc 0a 00 00       	call   f0101ba0 <__umoddi3>
f01010a4:	83 c4 14             	add    $0x14,%esp
f01010a7:	0f be 84 06 2d ff fe 	movsbl -0x100d3(%esi,%eax,1),%eax
f01010ae:	ff 
f01010af:	50                   	push   %eax
f01010b0:	ff d7                	call   *%edi
}
f01010b2:	83 c4 10             	add    $0x10,%esp
f01010b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010b8:	5b                   	pop    %ebx
f01010b9:	5e                   	pop    %esi
f01010ba:	5f                   	pop    %edi
f01010bb:	5d                   	pop    %ebp
f01010bc:	c3                   	ret    
f01010bd:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01010c0:	eb be                	jmp    f0101080 <printnum+0x88>

f01010c2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01010c2:	55                   	push   %ebp
f01010c3:	89 e5                	mov    %esp,%ebp
f01010c5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01010c8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01010cc:	8b 10                	mov    (%eax),%edx
f01010ce:	3b 50 04             	cmp    0x4(%eax),%edx
f01010d1:	73 0a                	jae    f01010dd <sprintputch+0x1b>
		*b->buf++ = ch;
f01010d3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01010d6:	89 08                	mov    %ecx,(%eax)
f01010d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01010db:	88 02                	mov    %al,(%edx)
}
f01010dd:	5d                   	pop    %ebp
f01010de:	c3                   	ret    

f01010df <printfmt>:
{
f01010df:	55                   	push   %ebp
f01010e0:	89 e5                	mov    %esp,%ebp
f01010e2:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01010e5:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01010e8:	50                   	push   %eax
f01010e9:	ff 75 10             	pushl  0x10(%ebp)
f01010ec:	ff 75 0c             	pushl  0xc(%ebp)
f01010ef:	ff 75 08             	pushl  0x8(%ebp)
f01010f2:	e8 05 00 00 00       	call   f01010fc <vprintfmt>
}
f01010f7:	83 c4 10             	add    $0x10,%esp
f01010fa:	c9                   	leave  
f01010fb:	c3                   	ret    

f01010fc <vprintfmt>:
{
f01010fc:	55                   	push   %ebp
f01010fd:	89 e5                	mov    %esp,%ebp
f01010ff:	57                   	push   %edi
f0101100:	56                   	push   %esi
f0101101:	53                   	push   %ebx
f0101102:	83 ec 2c             	sub    $0x2c,%esp
f0101105:	e8 45 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010110a:	81 c3 fe 11 01 00    	add    $0x111fe,%ebx
f0101110:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101113:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101116:	e9 c3 03 00 00       	jmp    f01014de <.L35+0x48>
		padc = ' ';
f010111b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010111f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0101126:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010112d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101134:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101139:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010113c:	8d 47 01             	lea    0x1(%edi),%eax
f010113f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101142:	0f b6 17             	movzbl (%edi),%edx
f0101145:	8d 42 dd             	lea    -0x23(%edx),%eax
f0101148:	3c 55                	cmp    $0x55,%al
f010114a:	0f 87 16 04 00 00    	ja     f0101566 <.L22>
f0101150:	0f b6 c0             	movzbl %al,%eax
f0101153:	89 d9                	mov    %ebx,%ecx
f0101155:	03 8c 83 bc ff fe ff 	add    -0x10044(%ebx,%eax,4),%ecx
f010115c:	ff e1                	jmp    *%ecx

f010115e <.L69>:
f010115e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101161:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101165:	eb d5                	jmp    f010113c <vprintfmt+0x40>

f0101167 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101167:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010116a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010116e:	eb cc                	jmp    f010113c <vprintfmt+0x40>

f0101170 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101170:	0f b6 d2             	movzbl %dl,%edx
f0101173:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101176:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010117b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010117e:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101182:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101185:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101188:	83 f9 09             	cmp    $0x9,%ecx
f010118b:	77 55                	ja     f01011e2 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010118d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101190:	eb e9                	jmp    f010117b <.L29+0xb>

f0101192 <.L26>:
			precision = va_arg(ap, int);
f0101192:	8b 45 14             	mov    0x14(%ebp),%eax
f0101195:	8b 00                	mov    (%eax),%eax
f0101197:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010119a:	8b 45 14             	mov    0x14(%ebp),%eax
f010119d:	8d 40 04             	lea    0x4(%eax),%eax
f01011a0:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01011a3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01011a6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01011aa:	79 90                	jns    f010113c <vprintfmt+0x40>
				width = precision, precision = -1;
f01011ac:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01011af:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011b2:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f01011b9:	eb 81                	jmp    f010113c <vprintfmt+0x40>

f01011bb <.L27>:
f01011bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011be:	85 c0                	test   %eax,%eax
f01011c0:	ba 00 00 00 00       	mov    $0x0,%edx
f01011c5:	0f 49 d0             	cmovns %eax,%edx
f01011c8:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01011cb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01011ce:	e9 69 ff ff ff       	jmp    f010113c <vprintfmt+0x40>

f01011d3 <.L23>:
f01011d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01011d6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01011dd:	e9 5a ff ff ff       	jmp    f010113c <vprintfmt+0x40>
f01011e2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01011e5:	eb bf                	jmp    f01011a6 <.L26+0x14>

f01011e7 <.L33>:
			lflag++;
f01011e7:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01011eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01011ee:	e9 49 ff ff ff       	jmp    f010113c <vprintfmt+0x40>

f01011f3 <.L30>:
			putch(va_arg(ap, int), putdat);
f01011f3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f6:	8d 78 04             	lea    0x4(%eax),%edi
f01011f9:	83 ec 08             	sub    $0x8,%esp
f01011fc:	56                   	push   %esi
f01011fd:	ff 30                	pushl  (%eax)
f01011ff:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101202:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101205:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0101208:	e9 ce 02 00 00       	jmp    f01014db <.L35+0x45>

f010120d <.L32>:
			err = va_arg(ap, int);
f010120d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101210:	8d 78 04             	lea    0x4(%eax),%edi
f0101213:	8b 00                	mov    (%eax),%eax
f0101215:	99                   	cltd   
f0101216:	31 d0                	xor    %edx,%eax
f0101218:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010121a:	83 f8 06             	cmp    $0x6,%eax
f010121d:	7f 27                	jg     f0101246 <.L32+0x39>
f010121f:	8b 94 83 3c 1d 00 00 	mov    0x1d3c(%ebx,%eax,4),%edx
f0101226:	85 d2                	test   %edx,%edx
f0101228:	74 1c                	je     f0101246 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f010122a:	52                   	push   %edx
f010122b:	8d 83 4e ff fe ff    	lea    -0x100b2(%ebx),%eax
f0101231:	50                   	push   %eax
f0101232:	56                   	push   %esi
f0101233:	ff 75 08             	pushl  0x8(%ebp)
f0101236:	e8 a4 fe ff ff       	call   f01010df <printfmt>
f010123b:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010123e:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101241:	e9 95 02 00 00       	jmp    f01014db <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0101246:	50                   	push   %eax
f0101247:	8d 83 45 ff fe ff    	lea    -0x100bb(%ebx),%eax
f010124d:	50                   	push   %eax
f010124e:	56                   	push   %esi
f010124f:	ff 75 08             	pushl  0x8(%ebp)
f0101252:	e8 88 fe ff ff       	call   f01010df <printfmt>
f0101257:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010125a:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010125d:	e9 79 02 00 00       	jmp    f01014db <.L35+0x45>

f0101262 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101262:	8b 45 14             	mov    0x14(%ebp),%eax
f0101265:	83 c0 04             	add    $0x4,%eax
f0101268:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010126b:	8b 45 14             	mov    0x14(%ebp),%eax
f010126e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101270:	85 ff                	test   %edi,%edi
f0101272:	8d 83 3e ff fe ff    	lea    -0x100c2(%ebx),%eax
f0101278:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010127b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010127f:	0f 8e b5 00 00 00    	jle    f010133a <.L36+0xd8>
f0101285:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101289:	75 08                	jne    f0101293 <.L36+0x31>
f010128b:	89 75 0c             	mov    %esi,0xc(%ebp)
f010128e:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101291:	eb 6d                	jmp    f0101300 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101293:	83 ec 08             	sub    $0x8,%esp
f0101296:	ff 75 cc             	pushl  -0x34(%ebp)
f0101299:	57                   	push   %edi
f010129a:	e8 82 04 00 00       	call   f0101721 <strnlen>
f010129f:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01012a2:	29 c2                	sub    %eax,%edx
f01012a4:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01012a7:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01012aa:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01012ae:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01012b1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01012b4:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01012b6:	eb 10                	jmp    f01012c8 <.L36+0x66>
					putch(padc, putdat);
f01012b8:	83 ec 08             	sub    $0x8,%esp
f01012bb:	56                   	push   %esi
f01012bc:	ff 75 e0             	pushl  -0x20(%ebp)
f01012bf:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01012c2:	83 ef 01             	sub    $0x1,%edi
f01012c5:	83 c4 10             	add    $0x10,%esp
f01012c8:	85 ff                	test   %edi,%edi
f01012ca:	7f ec                	jg     f01012b8 <.L36+0x56>
f01012cc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01012cf:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01012d2:	85 d2                	test   %edx,%edx
f01012d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01012d9:	0f 49 c2             	cmovns %edx,%eax
f01012dc:	29 c2                	sub    %eax,%edx
f01012de:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01012e1:	89 75 0c             	mov    %esi,0xc(%ebp)
f01012e4:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01012e7:	eb 17                	jmp    f0101300 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01012e9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01012ed:	75 30                	jne    f010131f <.L36+0xbd>
					putch(ch, putdat);
f01012ef:	83 ec 08             	sub    $0x8,%esp
f01012f2:	ff 75 0c             	pushl  0xc(%ebp)
f01012f5:	50                   	push   %eax
f01012f6:	ff 55 08             	call   *0x8(%ebp)
f01012f9:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01012fc:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101300:	83 c7 01             	add    $0x1,%edi
f0101303:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101307:	0f be c2             	movsbl %dl,%eax
f010130a:	85 c0                	test   %eax,%eax
f010130c:	74 52                	je     f0101360 <.L36+0xfe>
f010130e:	85 f6                	test   %esi,%esi
f0101310:	78 d7                	js     f01012e9 <.L36+0x87>
f0101312:	83 ee 01             	sub    $0x1,%esi
f0101315:	79 d2                	jns    f01012e9 <.L36+0x87>
f0101317:	8b 75 0c             	mov    0xc(%ebp),%esi
f010131a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010131d:	eb 32                	jmp    f0101351 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010131f:	0f be d2             	movsbl %dl,%edx
f0101322:	83 ea 20             	sub    $0x20,%edx
f0101325:	83 fa 5e             	cmp    $0x5e,%edx
f0101328:	76 c5                	jbe    f01012ef <.L36+0x8d>
					putch('?', putdat);
f010132a:	83 ec 08             	sub    $0x8,%esp
f010132d:	ff 75 0c             	pushl  0xc(%ebp)
f0101330:	6a 3f                	push   $0x3f
f0101332:	ff 55 08             	call   *0x8(%ebp)
f0101335:	83 c4 10             	add    $0x10,%esp
f0101338:	eb c2                	jmp    f01012fc <.L36+0x9a>
f010133a:	89 75 0c             	mov    %esi,0xc(%ebp)
f010133d:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101340:	eb be                	jmp    f0101300 <.L36+0x9e>
				putch(' ', putdat);
f0101342:	83 ec 08             	sub    $0x8,%esp
f0101345:	56                   	push   %esi
f0101346:	6a 20                	push   $0x20
f0101348:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010134b:	83 ef 01             	sub    $0x1,%edi
f010134e:	83 c4 10             	add    $0x10,%esp
f0101351:	85 ff                	test   %edi,%edi
f0101353:	7f ed                	jg     f0101342 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0101355:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101358:	89 45 14             	mov    %eax,0x14(%ebp)
f010135b:	e9 7b 01 00 00       	jmp    f01014db <.L35+0x45>
f0101360:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101363:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101366:	eb e9                	jmp    f0101351 <.L36+0xef>

f0101368 <.L31>:
f0101368:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010136b:	83 f9 01             	cmp    $0x1,%ecx
f010136e:	7e 40                	jle    f01013b0 <.L31+0x48>
		return va_arg(*ap, long long);
f0101370:	8b 45 14             	mov    0x14(%ebp),%eax
f0101373:	8b 50 04             	mov    0x4(%eax),%edx
f0101376:	8b 00                	mov    (%eax),%eax
f0101378:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010137b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010137e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101381:	8d 40 08             	lea    0x8(%eax),%eax
f0101384:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101387:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010138b:	79 55                	jns    f01013e2 <.L31+0x7a>
				putch('-', putdat);
f010138d:	83 ec 08             	sub    $0x8,%esp
f0101390:	56                   	push   %esi
f0101391:	6a 2d                	push   $0x2d
f0101393:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101396:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101399:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010139c:	f7 da                	neg    %edx
f010139e:	83 d1 00             	adc    $0x0,%ecx
f01013a1:	f7 d9                	neg    %ecx
f01013a3:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01013a6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01013ab:	e9 10 01 00 00       	jmp    f01014c0 <.L35+0x2a>
	else if (lflag)
f01013b0:	85 c9                	test   %ecx,%ecx
f01013b2:	75 17                	jne    f01013cb <.L31+0x63>
		return va_arg(*ap, int);
f01013b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01013b7:	8b 00                	mov    (%eax),%eax
f01013b9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01013bc:	99                   	cltd   
f01013bd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01013c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01013c3:	8d 40 04             	lea    0x4(%eax),%eax
f01013c6:	89 45 14             	mov    %eax,0x14(%ebp)
f01013c9:	eb bc                	jmp    f0101387 <.L31+0x1f>
		return va_arg(*ap, long);
f01013cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ce:	8b 00                	mov    (%eax),%eax
f01013d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01013d3:	99                   	cltd   
f01013d4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01013d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01013da:	8d 40 04             	lea    0x4(%eax),%eax
f01013dd:	89 45 14             	mov    %eax,0x14(%ebp)
f01013e0:	eb a5                	jmp    f0101387 <.L31+0x1f>
			num = getint(&ap, lflag);
f01013e2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01013e5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01013e8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01013ed:	e9 ce 00 00 00       	jmp    f01014c0 <.L35+0x2a>

f01013f2 <.L37>:
f01013f2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01013f5:	83 f9 01             	cmp    $0x1,%ecx
f01013f8:	7e 18                	jle    f0101412 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f01013fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01013fd:	8b 10                	mov    (%eax),%edx
f01013ff:	8b 48 04             	mov    0x4(%eax),%ecx
f0101402:	8d 40 08             	lea    0x8(%eax),%eax
f0101405:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101408:	b8 0a 00 00 00       	mov    $0xa,%eax
f010140d:	e9 ae 00 00 00       	jmp    f01014c0 <.L35+0x2a>
	else if (lflag)
f0101412:	85 c9                	test   %ecx,%ecx
f0101414:	75 1a                	jne    f0101430 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0101416:	8b 45 14             	mov    0x14(%ebp),%eax
f0101419:	8b 10                	mov    (%eax),%edx
f010141b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101420:	8d 40 04             	lea    0x4(%eax),%eax
f0101423:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101426:	b8 0a 00 00 00       	mov    $0xa,%eax
f010142b:	e9 90 00 00 00       	jmp    f01014c0 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101430:	8b 45 14             	mov    0x14(%ebp),%eax
f0101433:	8b 10                	mov    (%eax),%edx
f0101435:	b9 00 00 00 00       	mov    $0x0,%ecx
f010143a:	8d 40 04             	lea    0x4(%eax),%eax
f010143d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101440:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101445:	eb 79                	jmp    f01014c0 <.L35+0x2a>

f0101447 <.L34>:
f0101447:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010144a:	83 f9 01             	cmp    $0x1,%ecx
f010144d:	7e 15                	jle    f0101464 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f010144f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101452:	8b 10                	mov    (%eax),%edx
f0101454:	8b 48 04             	mov    0x4(%eax),%ecx
f0101457:	8d 40 08             	lea    0x8(%eax),%eax
f010145a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010145d:	b8 08 00 00 00       	mov    $0x8,%eax
f0101462:	eb 5c                	jmp    f01014c0 <.L35+0x2a>
	else if (lflag)
f0101464:	85 c9                	test   %ecx,%ecx
f0101466:	75 17                	jne    f010147f <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0101468:	8b 45 14             	mov    0x14(%ebp),%eax
f010146b:	8b 10                	mov    (%eax),%edx
f010146d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101472:	8d 40 04             	lea    0x4(%eax),%eax
f0101475:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101478:	b8 08 00 00 00       	mov    $0x8,%eax
f010147d:	eb 41                	jmp    f01014c0 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010147f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101482:	8b 10                	mov    (%eax),%edx
f0101484:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101489:	8d 40 04             	lea    0x4(%eax),%eax
f010148c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010148f:	b8 08 00 00 00       	mov    $0x8,%eax
f0101494:	eb 2a                	jmp    f01014c0 <.L35+0x2a>

f0101496 <.L35>:
			putch('0', putdat);
f0101496:	83 ec 08             	sub    $0x8,%esp
f0101499:	56                   	push   %esi
f010149a:	6a 30                	push   $0x30
f010149c:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010149f:	83 c4 08             	add    $0x8,%esp
f01014a2:	56                   	push   %esi
f01014a3:	6a 78                	push   $0x78
f01014a5:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01014a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01014ab:	8b 10                	mov    (%eax),%edx
f01014ad:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f01014b2:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01014b5:	8d 40 04             	lea    0x4(%eax),%eax
f01014b8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01014bb:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01014c0:	83 ec 0c             	sub    $0xc,%esp
f01014c3:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01014c7:	57                   	push   %edi
f01014c8:	ff 75 e0             	pushl  -0x20(%ebp)
f01014cb:	50                   	push   %eax
f01014cc:	51                   	push   %ecx
f01014cd:	52                   	push   %edx
f01014ce:	89 f2                	mov    %esi,%edx
f01014d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d3:	e8 20 fb ff ff       	call   f0100ff8 <printnum>
			break;
f01014d8:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01014db:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01014de:	83 c7 01             	add    $0x1,%edi
f01014e1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01014e5:	83 f8 25             	cmp    $0x25,%eax
f01014e8:	0f 84 2d fc ff ff    	je     f010111b <vprintfmt+0x1f>
			if (ch == '\0')
f01014ee:	85 c0                	test   %eax,%eax
f01014f0:	0f 84 91 00 00 00    	je     f0101587 <.L22+0x21>
			putch(ch, putdat);
f01014f6:	83 ec 08             	sub    $0x8,%esp
f01014f9:	56                   	push   %esi
f01014fa:	50                   	push   %eax
f01014fb:	ff 55 08             	call   *0x8(%ebp)
f01014fe:	83 c4 10             	add    $0x10,%esp
f0101501:	eb db                	jmp    f01014de <.L35+0x48>

f0101503 <.L38>:
f0101503:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101506:	83 f9 01             	cmp    $0x1,%ecx
f0101509:	7e 15                	jle    f0101520 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f010150b:	8b 45 14             	mov    0x14(%ebp),%eax
f010150e:	8b 10                	mov    (%eax),%edx
f0101510:	8b 48 04             	mov    0x4(%eax),%ecx
f0101513:	8d 40 08             	lea    0x8(%eax),%eax
f0101516:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101519:	b8 10 00 00 00       	mov    $0x10,%eax
f010151e:	eb a0                	jmp    f01014c0 <.L35+0x2a>
	else if (lflag)
f0101520:	85 c9                	test   %ecx,%ecx
f0101522:	75 17                	jne    f010153b <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0101524:	8b 45 14             	mov    0x14(%ebp),%eax
f0101527:	8b 10                	mov    (%eax),%edx
f0101529:	b9 00 00 00 00       	mov    $0x0,%ecx
f010152e:	8d 40 04             	lea    0x4(%eax),%eax
f0101531:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101534:	b8 10 00 00 00       	mov    $0x10,%eax
f0101539:	eb 85                	jmp    f01014c0 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010153b:	8b 45 14             	mov    0x14(%ebp),%eax
f010153e:	8b 10                	mov    (%eax),%edx
f0101540:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101545:	8d 40 04             	lea    0x4(%eax),%eax
f0101548:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010154b:	b8 10 00 00 00       	mov    $0x10,%eax
f0101550:	e9 6b ff ff ff       	jmp    f01014c0 <.L35+0x2a>

f0101555 <.L25>:
			putch(ch, putdat);
f0101555:	83 ec 08             	sub    $0x8,%esp
f0101558:	56                   	push   %esi
f0101559:	6a 25                	push   $0x25
f010155b:	ff 55 08             	call   *0x8(%ebp)
			break;
f010155e:	83 c4 10             	add    $0x10,%esp
f0101561:	e9 75 ff ff ff       	jmp    f01014db <.L35+0x45>

f0101566 <.L22>:
			putch('%', putdat);
f0101566:	83 ec 08             	sub    $0x8,%esp
f0101569:	56                   	push   %esi
f010156a:	6a 25                	push   $0x25
f010156c:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010156f:	83 c4 10             	add    $0x10,%esp
f0101572:	89 f8                	mov    %edi,%eax
f0101574:	eb 03                	jmp    f0101579 <.L22+0x13>
f0101576:	83 e8 01             	sub    $0x1,%eax
f0101579:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010157d:	75 f7                	jne    f0101576 <.L22+0x10>
f010157f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101582:	e9 54 ff ff ff       	jmp    f01014db <.L35+0x45>
}
f0101587:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010158a:	5b                   	pop    %ebx
f010158b:	5e                   	pop    %esi
f010158c:	5f                   	pop    %edi
f010158d:	5d                   	pop    %ebp
f010158e:	c3                   	ret    

f010158f <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010158f:	55                   	push   %ebp
f0101590:	89 e5                	mov    %esp,%ebp
f0101592:	53                   	push   %ebx
f0101593:	83 ec 14             	sub    $0x14,%esp
f0101596:	e8 b4 eb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010159b:	81 c3 6d 0d 01 00    	add    $0x10d6d,%ebx
f01015a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a4:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01015a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01015aa:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01015ae:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01015b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01015b8:	85 c0                	test   %eax,%eax
f01015ba:	74 2b                	je     f01015e7 <vsnprintf+0x58>
f01015bc:	85 d2                	test   %edx,%edx
f01015be:	7e 27                	jle    f01015e7 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01015c0:	ff 75 14             	pushl  0x14(%ebp)
f01015c3:	ff 75 10             	pushl  0x10(%ebp)
f01015c6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01015c9:	50                   	push   %eax
f01015ca:	8d 83 ba ed fe ff    	lea    -0x11246(%ebx),%eax
f01015d0:	50                   	push   %eax
f01015d1:	e8 26 fb ff ff       	call   f01010fc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01015d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01015d9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01015dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01015df:	83 c4 10             	add    $0x10,%esp
}
f01015e2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01015e5:	c9                   	leave  
f01015e6:	c3                   	ret    
		return -E_INVAL;
f01015e7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01015ec:	eb f4                	jmp    f01015e2 <vsnprintf+0x53>

f01015ee <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01015ee:	55                   	push   %ebp
f01015ef:	89 e5                	mov    %esp,%ebp
f01015f1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01015f4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01015f7:	50                   	push   %eax
f01015f8:	ff 75 10             	pushl  0x10(%ebp)
f01015fb:	ff 75 0c             	pushl  0xc(%ebp)
f01015fe:	ff 75 08             	pushl  0x8(%ebp)
f0101601:	e8 89 ff ff ff       	call   f010158f <vsnprintf>
	va_end(ap);

	return rc;
}
f0101606:	c9                   	leave  
f0101607:	c3                   	ret    

f0101608 <__x86.get_pc_thunk.cx>:
f0101608:	8b 0c 24             	mov    (%esp),%ecx
f010160b:	c3                   	ret    

f010160c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010160c:	55                   	push   %ebp
f010160d:	89 e5                	mov    %esp,%ebp
f010160f:	57                   	push   %edi
f0101610:	56                   	push   %esi
f0101611:	53                   	push   %ebx
f0101612:	83 ec 1c             	sub    $0x1c,%esp
f0101615:	e8 35 eb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010161a:	81 c3 ee 0c 01 00    	add    $0x10cee,%ebx
f0101620:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101623:	85 c0                	test   %eax,%eax
f0101625:	74 13                	je     f010163a <readline+0x2e>
		cprintf("%s", prompt);
f0101627:	83 ec 08             	sub    $0x8,%esp
f010162a:	50                   	push   %eax
f010162b:	8d 83 4e ff fe ff    	lea    -0x100b2(%ebx),%eax
f0101631:	50                   	push   %eax
f0101632:	e8 35 f6 ff ff       	call   f0100c6c <cprintf>
f0101637:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010163a:	83 ec 0c             	sub    $0xc,%esp
f010163d:	6a 00                	push   $0x0
f010163f:	e8 a3 f0 ff ff       	call   f01006e7 <iscons>
f0101644:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101647:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010164a:	bf 00 00 00 00       	mov    $0x0,%edi
f010164f:	eb 46                	jmp    f0101697 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101651:	83 ec 08             	sub    $0x8,%esp
f0101654:	50                   	push   %eax
f0101655:	8d 83 14 01 ff ff    	lea    -0xfeec(%ebx),%eax
f010165b:	50                   	push   %eax
f010165c:	e8 0b f6 ff ff       	call   f0100c6c <cprintf>
			return NULL;
f0101661:	83 c4 10             	add    $0x10,%esp
f0101664:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101669:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010166c:	5b                   	pop    %ebx
f010166d:	5e                   	pop    %esi
f010166e:	5f                   	pop    %edi
f010166f:	5d                   	pop    %ebp
f0101670:	c3                   	ret    
			if (echoing)
f0101671:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101675:	75 05                	jne    f010167c <readline+0x70>
			i--;
f0101677:	83 ef 01             	sub    $0x1,%edi
f010167a:	eb 1b                	jmp    f0101697 <readline+0x8b>
				cputchar('\b');
f010167c:	83 ec 0c             	sub    $0xc,%esp
f010167f:	6a 08                	push   $0x8
f0101681:	e8 40 f0 ff ff       	call   f01006c6 <cputchar>
f0101686:	83 c4 10             	add    $0x10,%esp
f0101689:	eb ec                	jmp    f0101677 <readline+0x6b>
			buf[i++] = c;
f010168b:	89 f0                	mov    %esi,%eax
f010168d:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f0101694:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101697:	e8 3a f0 ff ff       	call   f01006d6 <getchar>
f010169c:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010169e:	85 c0                	test   %eax,%eax
f01016a0:	78 af                	js     f0101651 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01016a2:	83 f8 08             	cmp    $0x8,%eax
f01016a5:	0f 94 c2             	sete   %dl
f01016a8:	83 f8 7f             	cmp    $0x7f,%eax
f01016ab:	0f 94 c0             	sete   %al
f01016ae:	08 c2                	or     %al,%dl
f01016b0:	74 04                	je     f01016b6 <readline+0xaa>
f01016b2:	85 ff                	test   %edi,%edi
f01016b4:	7f bb                	jg     f0101671 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01016b6:	83 fe 1f             	cmp    $0x1f,%esi
f01016b9:	7e 1c                	jle    f01016d7 <readline+0xcb>
f01016bb:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01016c1:	7f 14                	jg     f01016d7 <readline+0xcb>
			if (echoing)
f01016c3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01016c7:	74 c2                	je     f010168b <readline+0x7f>
				cputchar(c);
f01016c9:	83 ec 0c             	sub    $0xc,%esp
f01016cc:	56                   	push   %esi
f01016cd:	e8 f4 ef ff ff       	call   f01006c6 <cputchar>
f01016d2:	83 c4 10             	add    $0x10,%esp
f01016d5:	eb b4                	jmp    f010168b <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01016d7:	83 fe 0a             	cmp    $0xa,%esi
f01016da:	74 05                	je     f01016e1 <readline+0xd5>
f01016dc:	83 fe 0d             	cmp    $0xd,%esi
f01016df:	75 b6                	jne    f0101697 <readline+0x8b>
			if (echoing)
f01016e1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01016e5:	75 13                	jne    f01016fa <readline+0xee>
			buf[i] = 0;
f01016e7:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f01016ee:	00 
			return buf;
f01016ef:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f01016f5:	e9 6f ff ff ff       	jmp    f0101669 <readline+0x5d>
				cputchar('\n');
f01016fa:	83 ec 0c             	sub    $0xc,%esp
f01016fd:	6a 0a                	push   $0xa
f01016ff:	e8 c2 ef ff ff       	call   f01006c6 <cputchar>
f0101704:	83 c4 10             	add    $0x10,%esp
f0101707:	eb de                	jmp    f01016e7 <readline+0xdb>

f0101709 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101709:	55                   	push   %ebp
f010170a:	89 e5                	mov    %esp,%ebp
f010170c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010170f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101714:	eb 03                	jmp    f0101719 <strlen+0x10>
		n++;
f0101716:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101719:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010171d:	75 f7                	jne    f0101716 <strlen+0xd>
	return n;
}
f010171f:	5d                   	pop    %ebp
f0101720:	c3                   	ret    

f0101721 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101721:	55                   	push   %ebp
f0101722:	89 e5                	mov    %esp,%ebp
f0101724:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101727:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010172a:	b8 00 00 00 00       	mov    $0x0,%eax
f010172f:	eb 03                	jmp    f0101734 <strnlen+0x13>
		n++;
f0101731:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101734:	39 d0                	cmp    %edx,%eax
f0101736:	74 06                	je     f010173e <strnlen+0x1d>
f0101738:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010173c:	75 f3                	jne    f0101731 <strnlen+0x10>
	return n;
}
f010173e:	5d                   	pop    %ebp
f010173f:	c3                   	ret    

f0101740 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101740:	55                   	push   %ebp
f0101741:	89 e5                	mov    %esp,%ebp
f0101743:	53                   	push   %ebx
f0101744:	8b 45 08             	mov    0x8(%ebp),%eax
f0101747:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010174a:	89 c2                	mov    %eax,%edx
f010174c:	83 c1 01             	add    $0x1,%ecx
f010174f:	83 c2 01             	add    $0x1,%edx
f0101752:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101756:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101759:	84 db                	test   %bl,%bl
f010175b:	75 ef                	jne    f010174c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010175d:	5b                   	pop    %ebx
f010175e:	5d                   	pop    %ebp
f010175f:	c3                   	ret    

f0101760 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101760:	55                   	push   %ebp
f0101761:	89 e5                	mov    %esp,%ebp
f0101763:	53                   	push   %ebx
f0101764:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101767:	53                   	push   %ebx
f0101768:	e8 9c ff ff ff       	call   f0101709 <strlen>
f010176d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101770:	ff 75 0c             	pushl  0xc(%ebp)
f0101773:	01 d8                	add    %ebx,%eax
f0101775:	50                   	push   %eax
f0101776:	e8 c5 ff ff ff       	call   f0101740 <strcpy>
	return dst;
}
f010177b:	89 d8                	mov    %ebx,%eax
f010177d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101780:	c9                   	leave  
f0101781:	c3                   	ret    

f0101782 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101782:	55                   	push   %ebp
f0101783:	89 e5                	mov    %esp,%ebp
f0101785:	56                   	push   %esi
f0101786:	53                   	push   %ebx
f0101787:	8b 75 08             	mov    0x8(%ebp),%esi
f010178a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010178d:	89 f3                	mov    %esi,%ebx
f010178f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101792:	89 f2                	mov    %esi,%edx
f0101794:	eb 0f                	jmp    f01017a5 <strncpy+0x23>
		*dst++ = *src;
f0101796:	83 c2 01             	add    $0x1,%edx
f0101799:	0f b6 01             	movzbl (%ecx),%eax
f010179c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010179f:	80 39 01             	cmpb   $0x1,(%ecx)
f01017a2:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01017a5:	39 da                	cmp    %ebx,%edx
f01017a7:	75 ed                	jne    f0101796 <strncpy+0x14>
	}
	return ret;
}
f01017a9:	89 f0                	mov    %esi,%eax
f01017ab:	5b                   	pop    %ebx
f01017ac:	5e                   	pop    %esi
f01017ad:	5d                   	pop    %ebp
f01017ae:	c3                   	ret    

f01017af <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01017af:	55                   	push   %ebp
f01017b0:	89 e5                	mov    %esp,%ebp
f01017b2:	56                   	push   %esi
f01017b3:	53                   	push   %ebx
f01017b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01017b7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01017ba:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01017bd:	89 f0                	mov    %esi,%eax
f01017bf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01017c3:	85 c9                	test   %ecx,%ecx
f01017c5:	75 0b                	jne    f01017d2 <strlcpy+0x23>
f01017c7:	eb 17                	jmp    f01017e0 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01017c9:	83 c2 01             	add    $0x1,%edx
f01017cc:	83 c0 01             	add    $0x1,%eax
f01017cf:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01017d2:	39 d8                	cmp    %ebx,%eax
f01017d4:	74 07                	je     f01017dd <strlcpy+0x2e>
f01017d6:	0f b6 0a             	movzbl (%edx),%ecx
f01017d9:	84 c9                	test   %cl,%cl
f01017db:	75 ec                	jne    f01017c9 <strlcpy+0x1a>
		*dst = '\0';
f01017dd:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01017e0:	29 f0                	sub    %esi,%eax
}
f01017e2:	5b                   	pop    %ebx
f01017e3:	5e                   	pop    %esi
f01017e4:	5d                   	pop    %ebp
f01017e5:	c3                   	ret    

f01017e6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01017e6:	55                   	push   %ebp
f01017e7:	89 e5                	mov    %esp,%ebp
f01017e9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017ec:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01017ef:	eb 06                	jmp    f01017f7 <strcmp+0x11>
		p++, q++;
f01017f1:	83 c1 01             	add    $0x1,%ecx
f01017f4:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01017f7:	0f b6 01             	movzbl (%ecx),%eax
f01017fa:	84 c0                	test   %al,%al
f01017fc:	74 04                	je     f0101802 <strcmp+0x1c>
f01017fe:	3a 02                	cmp    (%edx),%al
f0101800:	74 ef                	je     f01017f1 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101802:	0f b6 c0             	movzbl %al,%eax
f0101805:	0f b6 12             	movzbl (%edx),%edx
f0101808:	29 d0                	sub    %edx,%eax
}
f010180a:	5d                   	pop    %ebp
f010180b:	c3                   	ret    

f010180c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010180c:	55                   	push   %ebp
f010180d:	89 e5                	mov    %esp,%ebp
f010180f:	53                   	push   %ebx
f0101810:	8b 45 08             	mov    0x8(%ebp),%eax
f0101813:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101816:	89 c3                	mov    %eax,%ebx
f0101818:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010181b:	eb 06                	jmp    f0101823 <strncmp+0x17>
		n--, p++, q++;
f010181d:	83 c0 01             	add    $0x1,%eax
f0101820:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101823:	39 d8                	cmp    %ebx,%eax
f0101825:	74 16                	je     f010183d <strncmp+0x31>
f0101827:	0f b6 08             	movzbl (%eax),%ecx
f010182a:	84 c9                	test   %cl,%cl
f010182c:	74 04                	je     f0101832 <strncmp+0x26>
f010182e:	3a 0a                	cmp    (%edx),%cl
f0101830:	74 eb                	je     f010181d <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101832:	0f b6 00             	movzbl (%eax),%eax
f0101835:	0f b6 12             	movzbl (%edx),%edx
f0101838:	29 d0                	sub    %edx,%eax
}
f010183a:	5b                   	pop    %ebx
f010183b:	5d                   	pop    %ebp
f010183c:	c3                   	ret    
		return 0;
f010183d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101842:	eb f6                	jmp    f010183a <strncmp+0x2e>

f0101844 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101844:	55                   	push   %ebp
f0101845:	89 e5                	mov    %esp,%ebp
f0101847:	8b 45 08             	mov    0x8(%ebp),%eax
f010184a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010184e:	0f b6 10             	movzbl (%eax),%edx
f0101851:	84 d2                	test   %dl,%dl
f0101853:	74 09                	je     f010185e <strchr+0x1a>
		if (*s == c)
f0101855:	38 ca                	cmp    %cl,%dl
f0101857:	74 0a                	je     f0101863 <strchr+0x1f>
	for (; *s; s++)
f0101859:	83 c0 01             	add    $0x1,%eax
f010185c:	eb f0                	jmp    f010184e <strchr+0xa>
			return (char *) s;
	return 0;
f010185e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101863:	5d                   	pop    %ebp
f0101864:	c3                   	ret    

f0101865 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101865:	55                   	push   %ebp
f0101866:	89 e5                	mov    %esp,%ebp
f0101868:	8b 45 08             	mov    0x8(%ebp),%eax
f010186b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010186f:	eb 03                	jmp    f0101874 <strfind+0xf>
f0101871:	83 c0 01             	add    $0x1,%eax
f0101874:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101877:	38 ca                	cmp    %cl,%dl
f0101879:	74 04                	je     f010187f <strfind+0x1a>
f010187b:	84 d2                	test   %dl,%dl
f010187d:	75 f2                	jne    f0101871 <strfind+0xc>
			break;
	return (char *) s;
}
f010187f:	5d                   	pop    %ebp
f0101880:	c3                   	ret    

f0101881 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101881:	55                   	push   %ebp
f0101882:	89 e5                	mov    %esp,%ebp
f0101884:	57                   	push   %edi
f0101885:	56                   	push   %esi
f0101886:	53                   	push   %ebx
f0101887:	8b 7d 08             	mov    0x8(%ebp),%edi
f010188a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010188d:	85 c9                	test   %ecx,%ecx
f010188f:	74 13                	je     f01018a4 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101891:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101897:	75 05                	jne    f010189e <memset+0x1d>
f0101899:	f6 c1 03             	test   $0x3,%cl
f010189c:	74 0d                	je     f01018ab <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010189e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018a1:	fc                   	cld    
f01018a2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01018a4:	89 f8                	mov    %edi,%eax
f01018a6:	5b                   	pop    %ebx
f01018a7:	5e                   	pop    %esi
f01018a8:	5f                   	pop    %edi
f01018a9:	5d                   	pop    %ebp
f01018aa:	c3                   	ret    
		c &= 0xFF;
f01018ab:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01018af:	89 d3                	mov    %edx,%ebx
f01018b1:	c1 e3 08             	shl    $0x8,%ebx
f01018b4:	89 d0                	mov    %edx,%eax
f01018b6:	c1 e0 18             	shl    $0x18,%eax
f01018b9:	89 d6                	mov    %edx,%esi
f01018bb:	c1 e6 10             	shl    $0x10,%esi
f01018be:	09 f0                	or     %esi,%eax
f01018c0:	09 c2                	or     %eax,%edx
f01018c2:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01018c4:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01018c7:	89 d0                	mov    %edx,%eax
f01018c9:	fc                   	cld    
f01018ca:	f3 ab                	rep stos %eax,%es:(%edi)
f01018cc:	eb d6                	jmp    f01018a4 <memset+0x23>

f01018ce <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01018ce:	55                   	push   %ebp
f01018cf:	89 e5                	mov    %esp,%ebp
f01018d1:	57                   	push   %edi
f01018d2:	56                   	push   %esi
f01018d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01018d6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018d9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01018dc:	39 c6                	cmp    %eax,%esi
f01018de:	73 35                	jae    f0101915 <memmove+0x47>
f01018e0:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01018e3:	39 c2                	cmp    %eax,%edx
f01018e5:	76 2e                	jbe    f0101915 <memmove+0x47>
		s += n;
		d += n;
f01018e7:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018ea:	89 d6                	mov    %edx,%esi
f01018ec:	09 fe                	or     %edi,%esi
f01018ee:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01018f4:	74 0c                	je     f0101902 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01018f6:	83 ef 01             	sub    $0x1,%edi
f01018f9:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01018fc:	fd                   	std    
f01018fd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01018ff:	fc                   	cld    
f0101900:	eb 21                	jmp    f0101923 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101902:	f6 c1 03             	test   $0x3,%cl
f0101905:	75 ef                	jne    f01018f6 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101907:	83 ef 04             	sub    $0x4,%edi
f010190a:	8d 72 fc             	lea    -0x4(%edx),%esi
f010190d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101910:	fd                   	std    
f0101911:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101913:	eb ea                	jmp    f01018ff <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101915:	89 f2                	mov    %esi,%edx
f0101917:	09 c2                	or     %eax,%edx
f0101919:	f6 c2 03             	test   $0x3,%dl
f010191c:	74 09                	je     f0101927 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010191e:	89 c7                	mov    %eax,%edi
f0101920:	fc                   	cld    
f0101921:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101923:	5e                   	pop    %esi
f0101924:	5f                   	pop    %edi
f0101925:	5d                   	pop    %ebp
f0101926:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101927:	f6 c1 03             	test   $0x3,%cl
f010192a:	75 f2                	jne    f010191e <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010192c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010192f:	89 c7                	mov    %eax,%edi
f0101931:	fc                   	cld    
f0101932:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101934:	eb ed                	jmp    f0101923 <memmove+0x55>

f0101936 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101936:	55                   	push   %ebp
f0101937:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101939:	ff 75 10             	pushl  0x10(%ebp)
f010193c:	ff 75 0c             	pushl  0xc(%ebp)
f010193f:	ff 75 08             	pushl  0x8(%ebp)
f0101942:	e8 87 ff ff ff       	call   f01018ce <memmove>
}
f0101947:	c9                   	leave  
f0101948:	c3                   	ret    

f0101949 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101949:	55                   	push   %ebp
f010194a:	89 e5                	mov    %esp,%ebp
f010194c:	56                   	push   %esi
f010194d:	53                   	push   %ebx
f010194e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101951:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101954:	89 c6                	mov    %eax,%esi
f0101956:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101959:	39 f0                	cmp    %esi,%eax
f010195b:	74 1c                	je     f0101979 <memcmp+0x30>
		if (*s1 != *s2)
f010195d:	0f b6 08             	movzbl (%eax),%ecx
f0101960:	0f b6 1a             	movzbl (%edx),%ebx
f0101963:	38 d9                	cmp    %bl,%cl
f0101965:	75 08                	jne    f010196f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101967:	83 c0 01             	add    $0x1,%eax
f010196a:	83 c2 01             	add    $0x1,%edx
f010196d:	eb ea                	jmp    f0101959 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f010196f:	0f b6 c1             	movzbl %cl,%eax
f0101972:	0f b6 db             	movzbl %bl,%ebx
f0101975:	29 d8                	sub    %ebx,%eax
f0101977:	eb 05                	jmp    f010197e <memcmp+0x35>
	}

	return 0;
f0101979:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010197e:	5b                   	pop    %ebx
f010197f:	5e                   	pop    %esi
f0101980:	5d                   	pop    %ebp
f0101981:	c3                   	ret    

f0101982 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101982:	55                   	push   %ebp
f0101983:	89 e5                	mov    %esp,%ebp
f0101985:	8b 45 08             	mov    0x8(%ebp),%eax
f0101988:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010198b:	89 c2                	mov    %eax,%edx
f010198d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101990:	39 d0                	cmp    %edx,%eax
f0101992:	73 09                	jae    f010199d <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101994:	38 08                	cmp    %cl,(%eax)
f0101996:	74 05                	je     f010199d <memfind+0x1b>
	for (; s < ends; s++)
f0101998:	83 c0 01             	add    $0x1,%eax
f010199b:	eb f3                	jmp    f0101990 <memfind+0xe>
			break;
	return (void *) s;
}
f010199d:	5d                   	pop    %ebp
f010199e:	c3                   	ret    

f010199f <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010199f:	55                   	push   %ebp
f01019a0:	89 e5                	mov    %esp,%ebp
f01019a2:	57                   	push   %edi
f01019a3:	56                   	push   %esi
f01019a4:	53                   	push   %ebx
f01019a5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01019a8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019ab:	eb 03                	jmp    f01019b0 <strtol+0x11>
		s++;
f01019ad:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01019b0:	0f b6 01             	movzbl (%ecx),%eax
f01019b3:	3c 20                	cmp    $0x20,%al
f01019b5:	74 f6                	je     f01019ad <strtol+0xe>
f01019b7:	3c 09                	cmp    $0x9,%al
f01019b9:	74 f2                	je     f01019ad <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01019bb:	3c 2b                	cmp    $0x2b,%al
f01019bd:	74 2e                	je     f01019ed <strtol+0x4e>
	int neg = 0;
f01019bf:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01019c4:	3c 2d                	cmp    $0x2d,%al
f01019c6:	74 2f                	je     f01019f7 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01019c8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01019ce:	75 05                	jne    f01019d5 <strtol+0x36>
f01019d0:	80 39 30             	cmpb   $0x30,(%ecx)
f01019d3:	74 2c                	je     f0101a01 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01019d5:	85 db                	test   %ebx,%ebx
f01019d7:	75 0a                	jne    f01019e3 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01019d9:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01019de:	80 39 30             	cmpb   $0x30,(%ecx)
f01019e1:	74 28                	je     f0101a0b <strtol+0x6c>
		base = 10;
f01019e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01019e8:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01019eb:	eb 50                	jmp    f0101a3d <strtol+0x9e>
		s++;
f01019ed:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01019f0:	bf 00 00 00 00       	mov    $0x0,%edi
f01019f5:	eb d1                	jmp    f01019c8 <strtol+0x29>
		s++, neg = 1;
f01019f7:	83 c1 01             	add    $0x1,%ecx
f01019fa:	bf 01 00 00 00       	mov    $0x1,%edi
f01019ff:	eb c7                	jmp    f01019c8 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101a01:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101a05:	74 0e                	je     f0101a15 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101a07:	85 db                	test   %ebx,%ebx
f0101a09:	75 d8                	jne    f01019e3 <strtol+0x44>
		s++, base = 8;
f0101a0b:	83 c1 01             	add    $0x1,%ecx
f0101a0e:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101a13:	eb ce                	jmp    f01019e3 <strtol+0x44>
		s += 2, base = 16;
f0101a15:	83 c1 02             	add    $0x2,%ecx
f0101a18:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101a1d:	eb c4                	jmp    f01019e3 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101a1f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101a22:	89 f3                	mov    %esi,%ebx
f0101a24:	80 fb 19             	cmp    $0x19,%bl
f0101a27:	77 29                	ja     f0101a52 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101a29:	0f be d2             	movsbl %dl,%edx
f0101a2c:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101a2f:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101a32:	7d 30                	jge    f0101a64 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101a34:	83 c1 01             	add    $0x1,%ecx
f0101a37:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101a3b:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101a3d:	0f b6 11             	movzbl (%ecx),%edx
f0101a40:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101a43:	89 f3                	mov    %esi,%ebx
f0101a45:	80 fb 09             	cmp    $0x9,%bl
f0101a48:	77 d5                	ja     f0101a1f <strtol+0x80>
			dig = *s - '0';
f0101a4a:	0f be d2             	movsbl %dl,%edx
f0101a4d:	83 ea 30             	sub    $0x30,%edx
f0101a50:	eb dd                	jmp    f0101a2f <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101a52:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101a55:	89 f3                	mov    %esi,%ebx
f0101a57:	80 fb 19             	cmp    $0x19,%bl
f0101a5a:	77 08                	ja     f0101a64 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0101a5c:	0f be d2             	movsbl %dl,%edx
f0101a5f:	83 ea 37             	sub    $0x37,%edx
f0101a62:	eb cb                	jmp    f0101a2f <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101a64:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101a68:	74 05                	je     f0101a6f <strtol+0xd0>
		*endptr = (char *) s;
f0101a6a:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101a6d:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0101a6f:	89 c2                	mov    %eax,%edx
f0101a71:	f7 da                	neg    %edx
f0101a73:	85 ff                	test   %edi,%edi
f0101a75:	0f 45 c2             	cmovne %edx,%eax
}
f0101a78:	5b                   	pop    %ebx
f0101a79:	5e                   	pop    %esi
f0101a7a:	5f                   	pop    %edi
f0101a7b:	5d                   	pop    %ebp
f0101a7c:	c3                   	ret    
f0101a7d:	66 90                	xchg   %ax,%ax
f0101a7f:	90                   	nop

f0101a80 <__udivdi3>:
f0101a80:	55                   	push   %ebp
f0101a81:	57                   	push   %edi
f0101a82:	56                   	push   %esi
f0101a83:	53                   	push   %ebx
f0101a84:	83 ec 1c             	sub    $0x1c,%esp
f0101a87:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0101a8b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101a8f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101a93:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101a97:	85 d2                	test   %edx,%edx
f0101a99:	75 35                	jne    f0101ad0 <__udivdi3+0x50>
f0101a9b:	39 f3                	cmp    %esi,%ebx
f0101a9d:	0f 87 bd 00 00 00    	ja     f0101b60 <__udivdi3+0xe0>
f0101aa3:	85 db                	test   %ebx,%ebx
f0101aa5:	89 d9                	mov    %ebx,%ecx
f0101aa7:	75 0b                	jne    f0101ab4 <__udivdi3+0x34>
f0101aa9:	b8 01 00 00 00       	mov    $0x1,%eax
f0101aae:	31 d2                	xor    %edx,%edx
f0101ab0:	f7 f3                	div    %ebx
f0101ab2:	89 c1                	mov    %eax,%ecx
f0101ab4:	31 d2                	xor    %edx,%edx
f0101ab6:	89 f0                	mov    %esi,%eax
f0101ab8:	f7 f1                	div    %ecx
f0101aba:	89 c6                	mov    %eax,%esi
f0101abc:	89 e8                	mov    %ebp,%eax
f0101abe:	89 f7                	mov    %esi,%edi
f0101ac0:	f7 f1                	div    %ecx
f0101ac2:	89 fa                	mov    %edi,%edx
f0101ac4:	83 c4 1c             	add    $0x1c,%esp
f0101ac7:	5b                   	pop    %ebx
f0101ac8:	5e                   	pop    %esi
f0101ac9:	5f                   	pop    %edi
f0101aca:	5d                   	pop    %ebp
f0101acb:	c3                   	ret    
f0101acc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ad0:	39 f2                	cmp    %esi,%edx
f0101ad2:	77 7c                	ja     f0101b50 <__udivdi3+0xd0>
f0101ad4:	0f bd fa             	bsr    %edx,%edi
f0101ad7:	83 f7 1f             	xor    $0x1f,%edi
f0101ada:	0f 84 98 00 00 00    	je     f0101b78 <__udivdi3+0xf8>
f0101ae0:	89 f9                	mov    %edi,%ecx
f0101ae2:	b8 20 00 00 00       	mov    $0x20,%eax
f0101ae7:	29 f8                	sub    %edi,%eax
f0101ae9:	d3 e2                	shl    %cl,%edx
f0101aeb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101aef:	89 c1                	mov    %eax,%ecx
f0101af1:	89 da                	mov    %ebx,%edx
f0101af3:	d3 ea                	shr    %cl,%edx
f0101af5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101af9:	09 d1                	or     %edx,%ecx
f0101afb:	89 f2                	mov    %esi,%edx
f0101afd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101b01:	89 f9                	mov    %edi,%ecx
f0101b03:	d3 e3                	shl    %cl,%ebx
f0101b05:	89 c1                	mov    %eax,%ecx
f0101b07:	d3 ea                	shr    %cl,%edx
f0101b09:	89 f9                	mov    %edi,%ecx
f0101b0b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101b0f:	d3 e6                	shl    %cl,%esi
f0101b11:	89 eb                	mov    %ebp,%ebx
f0101b13:	89 c1                	mov    %eax,%ecx
f0101b15:	d3 eb                	shr    %cl,%ebx
f0101b17:	09 de                	or     %ebx,%esi
f0101b19:	89 f0                	mov    %esi,%eax
f0101b1b:	f7 74 24 08          	divl   0x8(%esp)
f0101b1f:	89 d6                	mov    %edx,%esi
f0101b21:	89 c3                	mov    %eax,%ebx
f0101b23:	f7 64 24 0c          	mull   0xc(%esp)
f0101b27:	39 d6                	cmp    %edx,%esi
f0101b29:	72 0c                	jb     f0101b37 <__udivdi3+0xb7>
f0101b2b:	89 f9                	mov    %edi,%ecx
f0101b2d:	d3 e5                	shl    %cl,%ebp
f0101b2f:	39 c5                	cmp    %eax,%ebp
f0101b31:	73 5d                	jae    f0101b90 <__udivdi3+0x110>
f0101b33:	39 d6                	cmp    %edx,%esi
f0101b35:	75 59                	jne    f0101b90 <__udivdi3+0x110>
f0101b37:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101b3a:	31 ff                	xor    %edi,%edi
f0101b3c:	89 fa                	mov    %edi,%edx
f0101b3e:	83 c4 1c             	add    $0x1c,%esp
f0101b41:	5b                   	pop    %ebx
f0101b42:	5e                   	pop    %esi
f0101b43:	5f                   	pop    %edi
f0101b44:	5d                   	pop    %ebp
f0101b45:	c3                   	ret    
f0101b46:	8d 76 00             	lea    0x0(%esi),%esi
f0101b49:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101b50:	31 ff                	xor    %edi,%edi
f0101b52:	31 c0                	xor    %eax,%eax
f0101b54:	89 fa                	mov    %edi,%edx
f0101b56:	83 c4 1c             	add    $0x1c,%esp
f0101b59:	5b                   	pop    %ebx
f0101b5a:	5e                   	pop    %esi
f0101b5b:	5f                   	pop    %edi
f0101b5c:	5d                   	pop    %ebp
f0101b5d:	c3                   	ret    
f0101b5e:	66 90                	xchg   %ax,%ax
f0101b60:	31 ff                	xor    %edi,%edi
f0101b62:	89 e8                	mov    %ebp,%eax
f0101b64:	89 f2                	mov    %esi,%edx
f0101b66:	f7 f3                	div    %ebx
f0101b68:	89 fa                	mov    %edi,%edx
f0101b6a:	83 c4 1c             	add    $0x1c,%esp
f0101b6d:	5b                   	pop    %ebx
f0101b6e:	5e                   	pop    %esi
f0101b6f:	5f                   	pop    %edi
f0101b70:	5d                   	pop    %ebp
f0101b71:	c3                   	ret    
f0101b72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101b78:	39 f2                	cmp    %esi,%edx
f0101b7a:	72 06                	jb     f0101b82 <__udivdi3+0x102>
f0101b7c:	31 c0                	xor    %eax,%eax
f0101b7e:	39 eb                	cmp    %ebp,%ebx
f0101b80:	77 d2                	ja     f0101b54 <__udivdi3+0xd4>
f0101b82:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b87:	eb cb                	jmp    f0101b54 <__udivdi3+0xd4>
f0101b89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b90:	89 d8                	mov    %ebx,%eax
f0101b92:	31 ff                	xor    %edi,%edi
f0101b94:	eb be                	jmp    f0101b54 <__udivdi3+0xd4>
f0101b96:	66 90                	xchg   %ax,%ax
f0101b98:	66 90                	xchg   %ax,%ax
f0101b9a:	66 90                	xchg   %ax,%ax
f0101b9c:	66 90                	xchg   %ax,%ax
f0101b9e:	66 90                	xchg   %ax,%ax

f0101ba0 <__umoddi3>:
f0101ba0:	55                   	push   %ebp
f0101ba1:	57                   	push   %edi
f0101ba2:	56                   	push   %esi
f0101ba3:	53                   	push   %ebx
f0101ba4:	83 ec 1c             	sub    $0x1c,%esp
f0101ba7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101bab:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101baf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101bb3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101bb7:	85 ed                	test   %ebp,%ebp
f0101bb9:	89 f0                	mov    %esi,%eax
f0101bbb:	89 da                	mov    %ebx,%edx
f0101bbd:	75 19                	jne    f0101bd8 <__umoddi3+0x38>
f0101bbf:	39 df                	cmp    %ebx,%edi
f0101bc1:	0f 86 b1 00 00 00    	jbe    f0101c78 <__umoddi3+0xd8>
f0101bc7:	f7 f7                	div    %edi
f0101bc9:	89 d0                	mov    %edx,%eax
f0101bcb:	31 d2                	xor    %edx,%edx
f0101bcd:	83 c4 1c             	add    $0x1c,%esp
f0101bd0:	5b                   	pop    %ebx
f0101bd1:	5e                   	pop    %esi
f0101bd2:	5f                   	pop    %edi
f0101bd3:	5d                   	pop    %ebp
f0101bd4:	c3                   	ret    
f0101bd5:	8d 76 00             	lea    0x0(%esi),%esi
f0101bd8:	39 dd                	cmp    %ebx,%ebp
f0101bda:	77 f1                	ja     f0101bcd <__umoddi3+0x2d>
f0101bdc:	0f bd cd             	bsr    %ebp,%ecx
f0101bdf:	83 f1 1f             	xor    $0x1f,%ecx
f0101be2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101be6:	0f 84 b4 00 00 00    	je     f0101ca0 <__umoddi3+0x100>
f0101bec:	b8 20 00 00 00       	mov    $0x20,%eax
f0101bf1:	89 c2                	mov    %eax,%edx
f0101bf3:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101bf7:	29 c2                	sub    %eax,%edx
f0101bf9:	89 c1                	mov    %eax,%ecx
f0101bfb:	89 f8                	mov    %edi,%eax
f0101bfd:	d3 e5                	shl    %cl,%ebp
f0101bff:	89 d1                	mov    %edx,%ecx
f0101c01:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101c05:	d3 e8                	shr    %cl,%eax
f0101c07:	09 c5                	or     %eax,%ebp
f0101c09:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101c0d:	89 c1                	mov    %eax,%ecx
f0101c0f:	d3 e7                	shl    %cl,%edi
f0101c11:	89 d1                	mov    %edx,%ecx
f0101c13:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101c17:	89 df                	mov    %ebx,%edi
f0101c19:	d3 ef                	shr    %cl,%edi
f0101c1b:	89 c1                	mov    %eax,%ecx
f0101c1d:	89 f0                	mov    %esi,%eax
f0101c1f:	d3 e3                	shl    %cl,%ebx
f0101c21:	89 d1                	mov    %edx,%ecx
f0101c23:	89 fa                	mov    %edi,%edx
f0101c25:	d3 e8                	shr    %cl,%eax
f0101c27:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c2c:	09 d8                	or     %ebx,%eax
f0101c2e:	f7 f5                	div    %ebp
f0101c30:	d3 e6                	shl    %cl,%esi
f0101c32:	89 d1                	mov    %edx,%ecx
f0101c34:	f7 64 24 08          	mull   0x8(%esp)
f0101c38:	39 d1                	cmp    %edx,%ecx
f0101c3a:	89 c3                	mov    %eax,%ebx
f0101c3c:	89 d7                	mov    %edx,%edi
f0101c3e:	72 06                	jb     f0101c46 <__umoddi3+0xa6>
f0101c40:	75 0e                	jne    f0101c50 <__umoddi3+0xb0>
f0101c42:	39 c6                	cmp    %eax,%esi
f0101c44:	73 0a                	jae    f0101c50 <__umoddi3+0xb0>
f0101c46:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101c4a:	19 ea                	sbb    %ebp,%edx
f0101c4c:	89 d7                	mov    %edx,%edi
f0101c4e:	89 c3                	mov    %eax,%ebx
f0101c50:	89 ca                	mov    %ecx,%edx
f0101c52:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101c57:	29 de                	sub    %ebx,%esi
f0101c59:	19 fa                	sbb    %edi,%edx
f0101c5b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101c5f:	89 d0                	mov    %edx,%eax
f0101c61:	d3 e0                	shl    %cl,%eax
f0101c63:	89 d9                	mov    %ebx,%ecx
f0101c65:	d3 ee                	shr    %cl,%esi
f0101c67:	d3 ea                	shr    %cl,%edx
f0101c69:	09 f0                	or     %esi,%eax
f0101c6b:	83 c4 1c             	add    $0x1c,%esp
f0101c6e:	5b                   	pop    %ebx
f0101c6f:	5e                   	pop    %esi
f0101c70:	5f                   	pop    %edi
f0101c71:	5d                   	pop    %ebp
f0101c72:	c3                   	ret    
f0101c73:	90                   	nop
f0101c74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c78:	85 ff                	test   %edi,%edi
f0101c7a:	89 f9                	mov    %edi,%ecx
f0101c7c:	75 0b                	jne    f0101c89 <__umoddi3+0xe9>
f0101c7e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c83:	31 d2                	xor    %edx,%edx
f0101c85:	f7 f7                	div    %edi
f0101c87:	89 c1                	mov    %eax,%ecx
f0101c89:	89 d8                	mov    %ebx,%eax
f0101c8b:	31 d2                	xor    %edx,%edx
f0101c8d:	f7 f1                	div    %ecx
f0101c8f:	89 f0                	mov    %esi,%eax
f0101c91:	f7 f1                	div    %ecx
f0101c93:	e9 31 ff ff ff       	jmp    f0101bc9 <__umoddi3+0x29>
f0101c98:	90                   	nop
f0101c99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ca0:	39 dd                	cmp    %ebx,%ebp
f0101ca2:	72 08                	jb     f0101cac <__umoddi3+0x10c>
f0101ca4:	39 f7                	cmp    %esi,%edi
f0101ca6:	0f 87 21 ff ff ff    	ja     f0101bcd <__umoddi3+0x2d>
f0101cac:	89 da                	mov    %ebx,%edx
f0101cae:	89 f0                	mov    %esi,%eax
f0101cb0:	29 f8                	sub    %edi,%eax
f0101cb2:	19 ea                	sbb    %ebp,%edx
f0101cb4:	e9 14 ff ff ff       	jmp    f0101bcd <__umoddi3+0x2d>
