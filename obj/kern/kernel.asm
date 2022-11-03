
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
f0100064:	e8 98 3a 00 00       	call   f0103b01 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 34 cc fe ff    	lea    -0x133cc(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 6e 2e 00 00       	call   f0102ef0 <cprintf>
	// Lab1_exercise8_3:
    // cprintf("H%x Wo%s\n", 57616, &i);
	// cprintf("x=%d y=%d\n", 3);

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 34 12 00 00       	call   f01012bb <mem_init>
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
f01000da:	8d 83 4f cc fe ff    	lea    -0x133b1(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 0a 2e 00 00       	call   f0102ef0 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 c9 2d 00 00       	call   f0102eb9 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 59 db fe ff    	lea    -0x124a7(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 f2 2d 00 00       	call   f0102ef0 <cprintf>
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
f010011f:	8d 83 67 cc fe ff    	lea    -0x13399(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 c5 2d 00 00       	call   f0102ef0 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 82 2d 00 00       	call   f0102eb9 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 59 db fe ff    	lea    -0x124a7(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 ab 2d 00 00       	call   f0102ef0 <cprintf>
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
f0100217:	0f b6 84 13 b4 cd fe 	movzbl -0x1324c(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 b4 cc fe 	movzbl -0x1334c(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 81 cc fe ff    	lea    -0x1337f(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 7a 2c 00 00       	call   f0102ef0 <cprintf>
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
f01002b1:	0f b6 84 13 b4 cd fe 	movzbl -0x1324c(%ebx,%edx,1),%eax
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
f01004d2:	e8 77 36 00 00       	call   f0103b4e <memmove>
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
f01006b5:	8d 83 8d cc fe ff    	lea    -0x13373(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 2f 28 00 00       	call   f0102ef0 <cprintf>
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
f0100708:	8d 83 b4 ce fe ff    	lea    -0x1314c(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 d2 ce fe ff    	lea    -0x1312e(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 d7 ce fe ff    	lea    -0x13129(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 ce 27 00 00       	call   f0102ef0 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 94 cf fe ff    	lea    -0x1306c(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 e0 ce fe ff    	lea    -0x13120(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 b7 27 00 00       	call   f0102ef0 <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 bc cf fe ff    	lea    -0x13044(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 e9 ce fe ff    	lea    -0x13117(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 a0 27 00 00       	call   f0102ef0 <cprintf>
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
f0100770:	8d 83 f3 ce fe ff    	lea    -0x1310d(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 74 27 00 00       	call   f0102ef0 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f0100785:	8d 83 e0 cf fe ff    	lea    -0x13020(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 5f 27 00 00       	call   f0102ef0 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 08 d0 fe ff    	lea    -0x12ff8(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 42 27 00 00       	call   f0102ef0 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 39 3f 10 f0    	mov    $0xf0103f39,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 2c d0 fe ff    	lea    -0x12fd4(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 25 27 00 00       	call   f0102ef0 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 50 d0 fe ff    	lea    -0x12fb0(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 08 27 00 00       	call   f0102ef0 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 a0 96 11 f0    	mov    $0xf01196a0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 74 d0 fe ff    	lea    -0x12f8c(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 eb 26 00 00       	call   f0102ef0 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 98 d0 fe ff    	lea    -0x12f68(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 d0 26 00 00       	call   f0102ef0 <cprintf>
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
f0100841:	8d 83 0c cf fe ff    	lea    -0x130f4(%ebx),%eax
f0100847:	50                   	push   %eax
f0100848:	e8 a3 26 00 00       	call   f0102ef0 <cprintf>

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
f0100852:	8d 83 1e cf fe ff    	lea    -0x130e2(%ebx),%eax
f0100858:	89 45 b8             	mov    %eax,-0x48(%ebp)
		for (int i = 0; i < 5;++i){
			cprintf(" %08x", *(this_ebp + 2 + i));
f010085b:	8d 83 39 cf fe ff    	lea    -0x130c7(%ebx),%eax
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
f010087c:	e8 6f 26 00 00       	call   f0102ef0 <cprintf>
f0100881:	8d 77 08             	lea    0x8(%edi),%esi
f0100884:	83 c7 1c             	add    $0x1c,%edi
f0100887:	83 c4 10             	add    $0x10,%esp
			cprintf(" %08x", *(this_ebp + 2 + i));
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	ff 36                	pushl  (%esi)
f010088f:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100892:	e8 59 26 00 00       	call   f0102ef0 <cprintf>
f0100897:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5;++i){
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	39 fe                	cmp    %edi,%esi
f010089f:	75 e9                	jne    f010088a <mon_backtrace+0x5d>
		}
		cprintf("\n");
f01008a1:	83 ec 0c             	sub    $0xc,%esp
f01008a4:	8d 83 59 db fe ff    	lea    -0x124a7(%ebx),%eax
f01008aa:	50                   	push   %eax
f01008ab:	e8 40 26 00 00       	call   f0102ef0 <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008b0:	83 c4 08             	add    $0x8,%esp
f01008b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008b6:	50                   	push   %eax
f01008b7:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008ba:	57                   	push   %edi
f01008bb:	e8 34 27 00 00       	call   f0102ff4 <debuginfo_eip>
		cprintf("        %s:%d: ", info.eip_file, info.eip_line);
f01008c0:	83 c4 0c             	add    $0xc,%esp
f01008c3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008c9:	8d 83 3f cf fe ff    	lea    -0x130c1(%ebx),%eax
f01008cf:	50                   	push   %eax
f01008d0:	e8 1b 26 00 00       	call   f0102ef0 <cprintf>
		// for (int i = 0; i < info.eip_fn_namelen;++i){
		// 	cprintf("%c", info.eip_fn_name[i]);
		// }
		cprintf("%.*s+%d\n",info.eip_fn_namelen,info.eip_fn_name,eip-info.eip_fn_addr);
f01008d5:	89 f8                	mov    %edi,%eax
f01008d7:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008da:	50                   	push   %eax
f01008db:	ff 75 d8             	pushl  -0x28(%ebp)
f01008de:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e1:	8d 83 4f cf fe ff    	lea    -0x130b1(%ebx),%eax
f01008e7:	50                   	push   %eax
f01008e8:	e8 03 26 00 00       	call   f0102ef0 <cprintf>
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
f010091c:	8d 83 c4 d0 fe ff    	lea    -0x12f3c(%ebx),%eax
f0100922:	50                   	push   %eax
f0100923:	e8 c8 25 00 00       	call   f0102ef0 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100928:	8d 83 e8 d0 fe ff    	lea    -0x12f18(%ebx),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 ba 25 00 00       	call   f0102ef0 <cprintf>
f0100936:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100939:	8d bb 5c cf fe ff    	lea    -0x130a4(%ebx),%edi
f010093f:	eb 4a                	jmp    f010098b <monitor+0x83>
f0100941:	83 ec 08             	sub    $0x8,%esp
f0100944:	0f be c0             	movsbl %al,%eax
f0100947:	50                   	push   %eax
f0100948:	57                   	push   %edi
f0100949:	e8 76 31 00 00       	call   f0103ac4 <strchr>
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
f010097c:	8d 83 61 cf fe ff    	lea    -0x1309f(%ebx),%eax
f0100982:	50                   	push   %eax
f0100983:	e8 68 25 00 00       	call   f0102ef0 <cprintf>
f0100988:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010098b:	8d 83 58 cf fe ff    	lea    -0x130a8(%ebx),%eax
f0100991:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100994:	83 ec 0c             	sub    $0xc,%esp
f0100997:	ff 75 a4             	pushl  -0x5c(%ebp)
f010099a:	e8 ed 2e 00 00       	call   f010388c <readline>
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
f01009ca:	e8 f5 30 00 00       	call   f0103ac4 <strchr>
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
f0100a05:	e8 5c 30 00 00       	call   f0103a66 <strcmp>
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
f0100a26:	8d 83 7e cf fe ff    	lea    -0x13082(%ebx),%eax
f0100a2c:	50                   	push   %eax
f0100a2d:	e8 be 24 00 00       	call   f0102ef0 <cprintf>
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
f0100a6a:	e8 ea 23 00 00       	call   f0102e59 <__x86.get_pc_thunk.dx>
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
f0100ad7:	e8 8d 23 00 00       	call   f0102e69 <mc146818_read>
f0100adc:	89 c6                	mov    %eax,%esi
f0100ade:	83 c7 01             	add    $0x1,%edi
f0100ae1:	89 3c 24             	mov    %edi,(%esp)
f0100ae4:	e8 80 23 00 00       	call   f0102e69 <mc146818_read>
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
f0100afb:	e8 5d 23 00 00       	call   f0102e5d <__x86.get_pc_thunk.cx>
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
f0100b52:	8d 81 10 d1 fe ff    	lea    -0x12ef0(%ecx),%eax
f0100b58:	50                   	push   %eax
f0100b59:	68 f6 02 00 00       	push   $0x2f6
f0100b5e:	8d 81 a8 d8 fe ff    	lea    -0x12758(%ecx),%eax
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
f0100b7c:	e8 e4 22 00 00       	call   f0102e65 <__x86.get_pc_thunk.di>
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
f0100bb0:	8d 83 34 d1 fe ff    	lea    -0x12ecc(%ebx),%eax
f0100bb6:	50                   	push   %eax
f0100bb7:	68 37 02 00 00       	push   $0x237
f0100bbc:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f0100bc2:	50                   	push   %eax
f0100bc3:	e8 d1 f4 ff ff       	call   f0100099 <_panic>
f0100bc8:	50                   	push   %eax
f0100bc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bcc:	8d 83 10 d1 fe ff    	lea    -0x12ef0(%ebx),%eax
f0100bd2:	50                   	push   %eax
f0100bd3:	6a 59                	push   $0x59
f0100bd5:	8d 83 b4 d8 fe ff    	lea    -0x1274c(%ebx),%eax
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
f0100c1d:	e8 df 2e 00 00       	call   f0103b01 <memset>
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
f0100c66:	8d 83 c2 d8 fe ff    	lea    -0x1273e(%ebx),%eax
f0100c6c:	50                   	push   %eax
f0100c6d:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100c73:	50                   	push   %eax
f0100c74:	68 51 02 00 00       	push   $0x251
f0100c79:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f0100c7f:	50                   	push   %eax
f0100c80:	e8 14 f4 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100c85:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c88:	8d 83 e3 d8 fe ff    	lea    -0x1271d(%ebx),%eax
f0100c8e:	50                   	push   %eax
f0100c8f:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100c95:	50                   	push   %eax
f0100c96:	68 52 02 00 00       	push   $0x252
f0100c9b:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f0100ca1:	50                   	push   %eax
f0100ca2:	e8 f2 f3 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100caa:	8d 83 58 d1 fe ff    	lea    -0x12ea8(%ebx),%eax
f0100cb0:	50                   	push   %eax
f0100cb1:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100cb7:	50                   	push   %eax
f0100cb8:	68 53 02 00 00       	push   $0x253
f0100cbd:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f0100cc3:	50                   	push   %eax
f0100cc4:	e8 d0 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100cc9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ccc:	8d 83 f7 d8 fe ff    	lea    -0x12709(%ebx),%eax
f0100cd2:	50                   	push   %eax
f0100cd3:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100cd9:	50                   	push   %eax
f0100cda:	68 56 02 00 00       	push   $0x256
f0100cdf:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f0100ce5:	50                   	push   %eax
f0100ce6:	e8 ae f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ceb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cee:	8d 83 08 d9 fe ff    	lea    -0x126f8(%ebx),%eax
f0100cf4:	50                   	push   %eax
f0100cf5:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100cfb:	50                   	push   %eax
f0100cfc:	68 57 02 00 00       	push   $0x257
f0100d01:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f0100d07:	50                   	push   %eax
f0100d08:	e8 8c f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d0d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d10:	8d 83 8c d1 fe ff    	lea    -0x12e74(%ebx),%eax
f0100d16:	50                   	push   %eax
f0100d17:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100d1d:	50                   	push   %eax
f0100d1e:	68 58 02 00 00       	push   $0x258
f0100d23:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f0100d29:	50                   	push   %eax
f0100d2a:	e8 6a f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d2f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d32:	8d 83 21 d9 fe ff    	lea    -0x126df(%ebx),%eax
f0100d38:	50                   	push   %eax
f0100d39:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100d3f:	50                   	push   %eax
f0100d40:	68 59 02 00 00       	push   $0x259
f0100d45:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
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
f0100dcf:	8d 83 10 d1 fe ff    	lea    -0x12ef0(%ebx),%eax
f0100dd5:	50                   	push   %eax
f0100dd6:	6a 59                	push   $0x59
f0100dd8:	8d 83 b4 d8 fe ff    	lea    -0x1274c(%ebx),%eax
f0100dde:	50                   	push   %eax
f0100ddf:	e8 b5 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100de4:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100de7:	8d 83 b0 d1 fe ff    	lea    -0x12e50(%ebx),%eax
f0100ded:	50                   	push   %eax
f0100dee:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100df4:	50                   	push   %eax
f0100df5:	68 5a 02 00 00       	push   $0x25a
f0100dfa:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
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
f0100e17:	8d 83 f8 d1 fe ff    	lea    -0x12e08(%ebx),%eax
f0100e1d:	50                   	push   %eax
f0100e1e:	e8 cd 20 00 00       	call   f0102ef0 <cprintf>
}
f0100e23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e26:	5b                   	pop    %ebx
f0100e27:	5e                   	pop    %esi
f0100e28:	5f                   	pop    %edi
f0100e29:	5d                   	pop    %ebp
f0100e2a:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e2b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e2e:	8d 83 3b d9 fe ff    	lea    -0x126c5(%ebx),%eax
f0100e34:	50                   	push   %eax
f0100e35:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100e3b:	50                   	push   %eax
f0100e3c:	68 62 02 00 00       	push   $0x262
f0100e41:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f0100e47:	50                   	push   %eax
f0100e48:	e8 4c f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e4d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e50:	8d 83 4d d9 fe ff    	lea    -0x126b3(%ebx),%eax
f0100e56:	50                   	push   %eax
f0100e57:	8d 83 ce d8 fe ff    	lea    -0x12732(%ebx),%eax
f0100e5d:	50                   	push   %eax
f0100e5e:	68 63 02 00 00       	push   $0x263
f0100e63:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
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
f0100eff:	e8 5d 1f 00 00       	call   f0102e61 <__x86.get_pc_thunk.si>
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
f0100f4f:	8d 86 1c d2 fe ff    	lea    -0x12de4(%esi),%eax
f0100f55:	50                   	push   %eax
f0100f56:	68 11 01 00 00       	push   $0x111
f0100f5b:	8d 86 a8 d8 fe ff    	lea    -0x12758(%esi),%eax
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
f010104d:	e8 af 2a 00 00       	call   f0103b01 <memset>
f0101052:	83 c4 10             	add    $0x10,%esp
f0101055:	eb bc                	jmp    f0101013 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101057:	50                   	push   %eax
f0101058:	8d 83 10 d1 fe ff    	lea    -0x12ef0(%ebx),%eax
f010105e:	50                   	push   %eax
f010105f:	6a 59                	push   $0x59
f0101061:	8d 83 b4 d8 fe ff    	lea    -0x1274c(%ebx),%eax
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
f01010a4:	8d 83 40 d2 fe ff    	lea    -0x12dc0(%ebx),%eax
f01010aa:	50                   	push   %eax
f01010ab:	68 4b 01 00 00       	push   $0x14b
f01010b0:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
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
f010116a:	8d 83 10 d1 fe ff    	lea    -0x12ef0(%ebx),%eax
f0101170:	50                   	push   %eax
f0101171:	68 8c 01 00 00       	push   $0x18c
f0101176:	8d 83 a8 d8 fe ff    	lea    -0x12758(%ebx),%eax
f010117c:	50                   	push   %eax
f010117d:	e8 17 ef ff ff       	call   f0100099 <_panic>
			return NULL;
f0101182:	b8 00 00 00 00       	mov    $0x0,%eax
f0101187:	eb d8                	jmp    f0101161 <pgdir_walk+0x7c>
			return NULL;
f0101189:	b8 00 00 00 00       	mov    $0x0,%eax
f010118e:	eb d1                	jmp    f0101161 <pgdir_walk+0x7c>

f0101190 <page_lookup>:
{
f0101190:	55                   	push   %ebp
f0101191:	89 e5                	mov    %esp,%ebp
f0101193:	56                   	push   %esi
f0101194:	53                   	push   %ebx
f0101195:	e8 b5 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010119a:	81 c3 72 61 01 00    	add    $0x16172,%ebx
f01011a0:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);   // 只返回va对应的页表项，不分配新的页表页
f01011a3:	83 ec 04             	sub    $0x4,%esp
f01011a6:	6a 00                	push   $0x0
f01011a8:	ff 75 0c             	pushl  0xc(%ebp)
f01011ab:	ff 75 08             	pushl  0x8(%ebp)
f01011ae:	e8 32 ff ff ff       	call   f01010e5 <pgdir_walk>
	if(pte_store){
f01011b3:	83 c4 10             	add    $0x10,%esp
f01011b6:	85 f6                	test   %esi,%esi
f01011b8:	74 02                	je     f01011bc <page_lookup+0x2c>
		*pte_store = pte;
f01011ba:	89 06                	mov    %eax,(%esi)
	if(pte){
f01011bc:	85 c0                	test   %eax,%eax
f01011be:	74 39                	je     f01011f9 <page_lookup+0x69>
f01011c0:	8b 00                	mov    (%eax),%eax
f01011c2:	c1 e8 0c             	shr    $0xc,%eax

// pa为物理地址，PGNUM(pa)为该页的页号，函数功能与 page2pa 相反
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011c5:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f01011cb:	39 02                	cmp    %eax,(%edx)
f01011cd:	76 12                	jbe    f01011e1 <page_lookup+0x51>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01011cf:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f01011d5:	8b 12                	mov    (%edx),%edx
f01011d7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01011da:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01011dd:	5b                   	pop    %ebx
f01011de:	5e                   	pop    %esi
f01011df:	5d                   	pop    %ebp
f01011e0:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01011e1:	83 ec 04             	sub    $0x4,%esp
f01011e4:	8d 83 60 d2 fe ff    	lea    -0x12da0(%ebx),%eax
f01011ea:	50                   	push   %eax
f01011eb:	6a 52                	push   $0x52
f01011ed:	8d 83 b4 d8 fe ff    	lea    -0x1274c(%ebx),%eax
f01011f3:	50                   	push   %eax
f01011f4:	e8 a0 ee ff ff       	call   f0100099 <_panic>
	return NULL;
f01011f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01011fe:	eb da                	jmp    f01011da <page_lookup+0x4a>

f0101200 <page_remove>:
{
f0101200:	55                   	push   %ebp
f0101201:	89 e5                	mov    %esp,%ebp
f0101203:	53                   	push   %ebx
f0101204:	83 ec 18             	sub    $0x18,%esp
f0101207:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f010120a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010120d:	50                   	push   %eax
f010120e:	53                   	push   %ebx
f010120f:	ff 75 08             	pushl  0x8(%ebp)
f0101212:	e8 79 ff ff ff       	call   f0101190 <page_lookup>
	if (!pp)
f0101217:	83 c4 10             	add    $0x10,%esp
f010121a:	85 c0                	test   %eax,%eax
f010121c:	75 05                	jne    f0101223 <page_remove+0x23>
}
f010121e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101221:	c9                   	leave  
f0101222:	c3                   	ret    
	page_decref(pp);
f0101223:	83 ec 0c             	sub    $0xc,%esp
f0101226:	50                   	push   %eax
f0101227:	e8 90 fe ff ff       	call   f01010bc <page_decref>
	*pte = 0;
f010122c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010122f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101235:	0f 01 3b             	invlpg (%ebx)
f0101238:	83 c4 10             	add    $0x10,%esp
f010123b:	eb e1                	jmp    f010121e <page_remove+0x1e>

f010123d <page_insert>:
{
f010123d:	55                   	push   %ebp
f010123e:	89 e5                	mov    %esp,%ebp
f0101240:	57                   	push   %edi
f0101241:	56                   	push   %esi
f0101242:	53                   	push   %ebx
f0101243:	83 ec 10             	sub    $0x10,%esp
f0101246:	e8 1a 1c 00 00       	call   f0102e65 <__x86.get_pc_thunk.di>
f010124b:	81 c7 c1 60 01 00    	add    $0x160c1,%edi
f0101251:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101254:	6a 01                	push   $0x1
f0101256:	ff 75 10             	pushl  0x10(%ebp)
f0101259:	ff 75 08             	pushl  0x8(%ebp)
f010125c:	e8 84 fe ff ff       	call   f01010e5 <pgdir_walk>
	if (!pte)
f0101261:	83 c4 10             	add    $0x10,%esp
f0101264:	85 c0                	test   %eax,%eax
f0101266:	74 4c                	je     f01012b4 <page_insert+0x77>
f0101268:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;   // 引用计数的增加必须在 page_remove 前面！！  this is an elegant way to handle
f010126a:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	pp->pp_link = NULL;
f010126f:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if(*pte&PTE_P){
f0101275:	f6 00 01             	testb  $0x1,(%eax)
f0101278:	75 27                	jne    f01012a1 <page_insert+0x64>
	return (pp - pages) << PGSHIFT;
f010127a:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101280:	2b 30                	sub    (%eax),%esi
f0101282:	89 f0                	mov    %esi,%eax
f0101284:	c1 f8 03             	sar    $0x3,%eax
f0101287:	c1 e0 0c             	shl    $0xc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
f010128a:	8b 55 14             	mov    0x14(%ebp),%edx
f010128d:	83 ca 01             	or     $0x1,%edx
f0101290:	09 d0                	or     %edx,%eax
f0101292:	89 03                	mov    %eax,(%ebx)
	return 0;
f0101294:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101299:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010129c:	5b                   	pop    %ebx
f010129d:	5e                   	pop    %esi
f010129e:	5f                   	pop    %edi
f010129f:	5d                   	pop    %ebp
f01012a0:	c3                   	ret    
		page_remove(pgdir, va);
f01012a1:	83 ec 08             	sub    $0x8,%esp
f01012a4:	ff 75 10             	pushl  0x10(%ebp)
f01012a7:	ff 75 08             	pushl  0x8(%ebp)
f01012aa:	e8 51 ff ff ff       	call   f0101200 <page_remove>
f01012af:	83 c4 10             	add    $0x10,%esp
f01012b2:	eb c6                	jmp    f010127a <page_insert+0x3d>
		return -E_NO_MEM;
f01012b4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01012b9:	eb de                	jmp    f0101299 <page_insert+0x5c>

f01012bb <mem_init>:
{
f01012bb:	55                   	push   %ebp
f01012bc:	89 e5                	mov    %esp,%ebp
f01012be:	57                   	push   %edi
f01012bf:	56                   	push   %esi
f01012c0:	53                   	push   %ebx
f01012c1:	83 ec 3c             	sub    $0x3c,%esp
f01012c4:	e8 9c 1b 00 00       	call   f0102e65 <__x86.get_pc_thunk.di>
f01012c9:	81 c7 43 60 01 00    	add    $0x16043,%edi
	basemem = nvram_read(NVRAM_BASELO);
f01012cf:	b8 15 00 00 00       	mov    $0x15,%eax
f01012d4:	e8 e7 f7 ff ff       	call   f0100ac0 <nvram_read>
f01012d9:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01012db:	b8 17 00 00 00       	mov    $0x17,%eax
f01012e0:	e8 db f7 ff ff       	call   f0100ac0 <nvram_read>
f01012e5:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01012e7:	b8 34 00 00 00       	mov    $0x34,%eax
f01012ec:	e8 cf f7 ff ff       	call   f0100ac0 <nvram_read>
f01012f1:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01012f4:	85 c0                	test   %eax,%eax
f01012f6:	0f 85 b9 00 00 00    	jne    f01013b5 <mem_init+0xfa>
		totalmem = 1 * 1024 + extmem;
f01012fc:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101302:	85 f6                	test   %esi,%esi
f0101304:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101307:	89 c1                	mov    %eax,%ecx
f0101309:	c1 e9 02             	shr    $0x2,%ecx
f010130c:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101312:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101314:	89 c2                	mov    %eax,%edx
f0101316:	29 da                	sub    %ebx,%edx
f0101318:	52                   	push   %edx
f0101319:	53                   	push   %ebx
f010131a:	50                   	push   %eax
f010131b:	8d 87 80 d2 fe ff    	lea    -0x12d80(%edi),%eax
f0101321:	50                   	push   %eax
f0101322:	89 fb                	mov    %edi,%ebx
f0101324:	e8 c7 1b 00 00       	call   f0102ef0 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);    // 初始占一整页
f0101329:	b8 00 10 00 00       	mov    $0x1000,%eax
f010132e:	e8 34 f7 ff ff       	call   f0100a67 <boot_alloc>
f0101333:	c7 c6 ac 96 11 f0    	mov    $0xf01196ac,%esi
f0101339:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);   // 初始化为0
f010133b:	83 c4 0c             	add    $0xc,%esp
f010133e:	68 00 10 00 00       	push   $0x1000
f0101343:	6a 00                	push   $0x0
f0101345:	50                   	push   %eax
f0101346:	e8 b6 27 00 00       	call   f0103b01 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010134b:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010134d:	83 c4 10             	add    $0x10,%esp
f0101350:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101355:	76 68                	jbe    f01013bf <mem_init+0x104>
	return (physaddr_t)kva - KERNBASE;
f0101357:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010135d:	83 ca 05             	or     $0x5,%edx
f0101360:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101366:	c7 c3 a8 96 11 f0    	mov    $0xf01196a8,%ebx
f010136c:	8b 03                	mov    (%ebx),%eax
f010136e:	c1 e0 03             	shl    $0x3,%eax
f0101371:	e8 f1 f6 ff ff       	call   f0100a67 <boot_alloc>
f0101376:	c7 c6 b0 96 11 f0    	mov    $0xf01196b0,%esi
f010137c:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010137e:	83 ec 04             	sub    $0x4,%esp
f0101381:	8b 13                	mov    (%ebx),%edx
f0101383:	c1 e2 03             	shl    $0x3,%edx
f0101386:	52                   	push   %edx
f0101387:	6a 00                	push   $0x0
f0101389:	50                   	push   %eax
f010138a:	89 fb                	mov    %edi,%ebx
f010138c:	e8 70 27 00 00       	call   f0103b01 <memset>
	page_init();
f0101391:	e8 60 fb ff ff       	call   f0100ef6 <page_init>
	check_page_free_list(1);
f0101396:	b8 01 00 00 00       	mov    $0x1,%eax
f010139b:	e8 d3 f7 ff ff       	call   f0100b73 <check_page_free_list>
	if (!pages)
f01013a0:	83 c4 10             	add    $0x10,%esp
f01013a3:	83 3e 00             	cmpl   $0x0,(%esi)
f01013a6:	74 30                	je     f01013d8 <mem_init+0x11d>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013a8:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f01013ae:	be 00 00 00 00       	mov    $0x0,%esi
f01013b3:	eb 43                	jmp    f01013f8 <mem_init+0x13d>
		totalmem = 16 * 1024 + ext16mem;
f01013b5:	05 00 40 00 00       	add    $0x4000,%eax
f01013ba:	e9 48 ff ff ff       	jmp    f0101307 <mem_init+0x4c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013bf:	50                   	push   %eax
f01013c0:	8d 87 1c d2 fe ff    	lea    -0x12de4(%edi),%eax
f01013c6:	50                   	push   %eax
f01013c7:	68 9b 00 00 00       	push   $0x9b
f01013cc:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01013d2:	50                   	push   %eax
f01013d3:	e8 c1 ec ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f01013d8:	83 ec 04             	sub    $0x4,%esp
f01013db:	8d 87 5e d9 fe ff    	lea    -0x126a2(%edi),%eax
f01013e1:	50                   	push   %eax
f01013e2:	68 76 02 00 00       	push   $0x276
f01013e7:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01013ed:	50                   	push   %eax
f01013ee:	e8 a6 ec ff ff       	call   f0100099 <_panic>
		++nfree;
f01013f3:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013f6:	8b 00                	mov    (%eax),%eax
f01013f8:	85 c0                	test   %eax,%eax
f01013fa:	75 f7                	jne    f01013f3 <mem_init+0x138>
	assert((pp0 = page_alloc(0)));
f01013fc:	83 ec 0c             	sub    $0xc,%esp
f01013ff:	6a 00                	push   $0x0
f0101401:	e8 df fb ff ff       	call   f0100fe5 <page_alloc>
f0101406:	89 c3                	mov    %eax,%ebx
f0101408:	83 c4 10             	add    $0x10,%esp
f010140b:	85 c0                	test   %eax,%eax
f010140d:	0f 84 3f 02 00 00    	je     f0101652 <mem_init+0x397>
	assert((pp1 = page_alloc(0)));
f0101413:	83 ec 0c             	sub    $0xc,%esp
f0101416:	6a 00                	push   $0x0
f0101418:	e8 c8 fb ff ff       	call   f0100fe5 <page_alloc>
f010141d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101420:	83 c4 10             	add    $0x10,%esp
f0101423:	85 c0                	test   %eax,%eax
f0101425:	0f 84 48 02 00 00    	je     f0101673 <mem_init+0x3b8>
	assert((pp2 = page_alloc(0)));
f010142b:	83 ec 0c             	sub    $0xc,%esp
f010142e:	6a 00                	push   $0x0
f0101430:	e8 b0 fb ff ff       	call   f0100fe5 <page_alloc>
f0101435:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101438:	83 c4 10             	add    $0x10,%esp
f010143b:	85 c0                	test   %eax,%eax
f010143d:	0f 84 51 02 00 00    	je     f0101694 <mem_init+0x3d9>
	assert(pp1 && pp1 != pp0);
f0101443:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101446:	0f 84 69 02 00 00    	je     f01016b5 <mem_init+0x3fa>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010144c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010144f:	39 c3                	cmp    %eax,%ebx
f0101451:	0f 84 7f 02 00 00    	je     f01016d6 <mem_init+0x41b>
f0101457:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010145a:	0f 84 76 02 00 00    	je     f01016d6 <mem_init+0x41b>
	return (pp - pages) << PGSHIFT;
f0101460:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101466:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101468:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f010146e:	8b 10                	mov    (%eax),%edx
f0101470:	c1 e2 0c             	shl    $0xc,%edx
f0101473:	89 d8                	mov    %ebx,%eax
f0101475:	29 c8                	sub    %ecx,%eax
f0101477:	c1 f8 03             	sar    $0x3,%eax
f010147a:	c1 e0 0c             	shl    $0xc,%eax
f010147d:	39 d0                	cmp    %edx,%eax
f010147f:	0f 83 72 02 00 00    	jae    f01016f7 <mem_init+0x43c>
f0101485:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101488:	29 c8                	sub    %ecx,%eax
f010148a:	c1 f8 03             	sar    $0x3,%eax
f010148d:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101490:	39 c2                	cmp    %eax,%edx
f0101492:	0f 86 80 02 00 00    	jbe    f0101718 <mem_init+0x45d>
f0101498:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010149b:	29 c8                	sub    %ecx,%eax
f010149d:	c1 f8 03             	sar    $0x3,%eax
f01014a0:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01014a3:	39 c2                	cmp    %eax,%edx
f01014a5:	0f 86 8e 02 00 00    	jbe    f0101739 <mem_init+0x47e>
	fl = page_free_list;
f01014ab:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f01014b1:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f01014b4:	c7 87 90 1f 00 00 00 	movl   $0x0,0x1f90(%edi)
f01014bb:	00 00 00 
	assert(!page_alloc(0));
f01014be:	83 ec 0c             	sub    $0xc,%esp
f01014c1:	6a 00                	push   $0x0
f01014c3:	e8 1d fb ff ff       	call   f0100fe5 <page_alloc>
f01014c8:	83 c4 10             	add    $0x10,%esp
f01014cb:	85 c0                	test   %eax,%eax
f01014cd:	0f 85 87 02 00 00    	jne    f010175a <mem_init+0x49f>
	page_free(pp0);
f01014d3:	83 ec 0c             	sub    $0xc,%esp
f01014d6:	53                   	push   %ebx
f01014d7:	e8 91 fb ff ff       	call   f010106d <page_free>
	page_free(pp1);
f01014dc:	83 c4 04             	add    $0x4,%esp
f01014df:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014e2:	e8 86 fb ff ff       	call   f010106d <page_free>
	page_free(pp2);
f01014e7:	83 c4 04             	add    $0x4,%esp
f01014ea:	ff 75 d0             	pushl  -0x30(%ebp)
f01014ed:	e8 7b fb ff ff       	call   f010106d <page_free>
	assert((pp0 = page_alloc(0)));
f01014f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014f9:	e8 e7 fa ff ff       	call   f0100fe5 <page_alloc>
f01014fe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101501:	83 c4 10             	add    $0x10,%esp
f0101504:	85 c0                	test   %eax,%eax
f0101506:	0f 84 6f 02 00 00    	je     f010177b <mem_init+0x4c0>
	assert((pp1 = page_alloc(0)));
f010150c:	83 ec 0c             	sub    $0xc,%esp
f010150f:	6a 00                	push   $0x0
f0101511:	e8 cf fa ff ff       	call   f0100fe5 <page_alloc>
f0101516:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101519:	83 c4 10             	add    $0x10,%esp
f010151c:	85 c0                	test   %eax,%eax
f010151e:	0f 84 78 02 00 00    	je     f010179c <mem_init+0x4e1>
	assert((pp2 = page_alloc(0)));
f0101524:	83 ec 0c             	sub    $0xc,%esp
f0101527:	6a 00                	push   $0x0
f0101529:	e8 b7 fa ff ff       	call   f0100fe5 <page_alloc>
f010152e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101531:	83 c4 10             	add    $0x10,%esp
f0101534:	85 c0                	test   %eax,%eax
f0101536:	0f 84 81 02 00 00    	je     f01017bd <mem_init+0x502>
	assert(pp1 && pp1 != pp0);
f010153c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010153f:	39 4d d4             	cmp    %ecx,-0x2c(%ebp)
f0101542:	0f 84 96 02 00 00    	je     f01017de <mem_init+0x523>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101548:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010154b:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010154e:	0f 84 ab 02 00 00    	je     f01017ff <mem_init+0x544>
f0101554:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101557:	0f 84 a2 02 00 00    	je     f01017ff <mem_init+0x544>
	assert(!page_alloc(0));
f010155d:	83 ec 0c             	sub    $0xc,%esp
f0101560:	6a 00                	push   $0x0
f0101562:	e8 7e fa ff ff       	call   f0100fe5 <page_alloc>
f0101567:	83 c4 10             	add    $0x10,%esp
f010156a:	85 c0                	test   %eax,%eax
f010156c:	0f 85 ae 02 00 00    	jne    f0101820 <mem_init+0x565>
f0101572:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101578:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010157b:	2b 08                	sub    (%eax),%ecx
f010157d:	89 c8                	mov    %ecx,%eax
f010157f:	c1 f8 03             	sar    $0x3,%eax
f0101582:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101585:	89 c1                	mov    %eax,%ecx
f0101587:	c1 e9 0c             	shr    $0xc,%ecx
f010158a:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0101590:	3b 0a                	cmp    (%edx),%ecx
f0101592:	0f 83 a9 02 00 00    	jae    f0101841 <mem_init+0x586>
	memset(page2kva(pp0), 1, PGSIZE);
f0101598:	83 ec 04             	sub    $0x4,%esp
f010159b:	68 00 10 00 00       	push   $0x1000
f01015a0:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01015a2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015a7:	50                   	push   %eax
f01015a8:	89 fb                	mov    %edi,%ebx
f01015aa:	e8 52 25 00 00       	call   f0103b01 <memset>
	page_free(pp0);
f01015af:	83 c4 04             	add    $0x4,%esp
f01015b2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015b5:	e8 b3 fa ff ff       	call   f010106d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015ba:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015c1:	e8 1f fa ff ff       	call   f0100fe5 <page_alloc>
f01015c6:	83 c4 10             	add    $0x10,%esp
f01015c9:	85 c0                	test   %eax,%eax
f01015cb:	0f 84 88 02 00 00    	je     f0101859 <mem_init+0x59e>
	assert(pp && pp0 == pp);
f01015d1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015d4:	0f 85 9e 02 00 00    	jne    f0101878 <mem_init+0x5bd>
	return (pp - pages) << PGSHIFT;
f01015da:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f01015e0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01015e3:	2b 10                	sub    (%eax),%edx
f01015e5:	c1 fa 03             	sar    $0x3,%edx
f01015e8:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01015eb:	89 d1                	mov    %edx,%ecx
f01015ed:	c1 e9 0c             	shr    $0xc,%ecx
f01015f0:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f01015f6:	3b 08                	cmp    (%eax),%ecx
f01015f8:	0f 83 99 02 00 00    	jae    f0101897 <mem_init+0x5dc>
	return (void *)(pa + KERNBASE);
f01015fe:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101604:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f010160a:	80 38 00             	cmpb   $0x0,(%eax)
f010160d:	0f 85 9a 02 00 00    	jne    f01018ad <mem_init+0x5f2>
f0101613:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101616:	39 d0                	cmp    %edx,%eax
f0101618:	75 f0                	jne    f010160a <mem_init+0x34f>
	page_free_list = fl;
f010161a:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010161d:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	page_free(pp0);
f0101623:	83 ec 0c             	sub    $0xc,%esp
f0101626:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101629:	e8 3f fa ff ff       	call   f010106d <page_free>
	page_free(pp1);
f010162e:	83 c4 04             	add    $0x4,%esp
f0101631:	ff 75 d0             	pushl  -0x30(%ebp)
f0101634:	e8 34 fa ff ff       	call   f010106d <page_free>
	page_free(pp2);
f0101639:	83 c4 04             	add    $0x4,%esp
f010163c:	ff 75 cc             	pushl  -0x34(%ebp)
f010163f:	e8 29 fa ff ff       	call   f010106d <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101644:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f010164a:	83 c4 10             	add    $0x10,%esp
f010164d:	e9 81 02 00 00       	jmp    f01018d3 <mem_init+0x618>
	assert((pp0 = page_alloc(0)));
f0101652:	8d 87 79 d9 fe ff    	lea    -0x12687(%edi),%eax
f0101658:	50                   	push   %eax
f0101659:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010165f:	50                   	push   %eax
f0101660:	68 7e 02 00 00       	push   $0x27e
f0101665:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010166b:	50                   	push   %eax
f010166c:	89 fb                	mov    %edi,%ebx
f010166e:	e8 26 ea ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101673:	8d 87 8f d9 fe ff    	lea    -0x12671(%edi),%eax
f0101679:	50                   	push   %eax
f010167a:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0101680:	50                   	push   %eax
f0101681:	68 7f 02 00 00       	push   $0x27f
f0101686:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010168c:	50                   	push   %eax
f010168d:	89 fb                	mov    %edi,%ebx
f010168f:	e8 05 ea ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101694:	8d 87 a5 d9 fe ff    	lea    -0x1265b(%edi),%eax
f010169a:	50                   	push   %eax
f010169b:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01016a1:	50                   	push   %eax
f01016a2:	68 80 02 00 00       	push   $0x280
f01016a7:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01016ad:	50                   	push   %eax
f01016ae:	89 fb                	mov    %edi,%ebx
f01016b0:	e8 e4 e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01016b5:	8d 87 bb d9 fe ff    	lea    -0x12645(%edi),%eax
f01016bb:	50                   	push   %eax
f01016bc:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01016c2:	50                   	push   %eax
f01016c3:	68 83 02 00 00       	push   $0x283
f01016c8:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01016ce:	50                   	push   %eax
f01016cf:	89 fb                	mov    %edi,%ebx
f01016d1:	e8 c3 e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016d6:	8d 87 bc d2 fe ff    	lea    -0x12d44(%edi),%eax
f01016dc:	50                   	push   %eax
f01016dd:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01016e3:	50                   	push   %eax
f01016e4:	68 84 02 00 00       	push   $0x284
f01016e9:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01016ef:	50                   	push   %eax
f01016f0:	89 fb                	mov    %edi,%ebx
f01016f2:	e8 a2 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01016f7:	8d 87 cd d9 fe ff    	lea    -0x12633(%edi),%eax
f01016fd:	50                   	push   %eax
f01016fe:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0101704:	50                   	push   %eax
f0101705:	68 85 02 00 00       	push   $0x285
f010170a:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101710:	50                   	push   %eax
f0101711:	89 fb                	mov    %edi,%ebx
f0101713:	e8 81 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101718:	8d 87 ea d9 fe ff    	lea    -0x12616(%edi),%eax
f010171e:	50                   	push   %eax
f010171f:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0101725:	50                   	push   %eax
f0101726:	68 86 02 00 00       	push   $0x286
f010172b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101731:	50                   	push   %eax
f0101732:	89 fb                	mov    %edi,%ebx
f0101734:	e8 60 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101739:	8d 87 07 da fe ff    	lea    -0x125f9(%edi),%eax
f010173f:	50                   	push   %eax
f0101740:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0101746:	50                   	push   %eax
f0101747:	68 87 02 00 00       	push   $0x287
f010174c:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101752:	50                   	push   %eax
f0101753:	89 fb                	mov    %edi,%ebx
f0101755:	e8 3f e9 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010175a:	8d 87 24 da fe ff    	lea    -0x125dc(%edi),%eax
f0101760:	50                   	push   %eax
f0101761:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0101767:	50                   	push   %eax
f0101768:	68 8e 02 00 00       	push   $0x28e
f010176d:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101773:	50                   	push   %eax
f0101774:	89 fb                	mov    %edi,%ebx
f0101776:	e8 1e e9 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010177b:	8d 87 79 d9 fe ff    	lea    -0x12687(%edi),%eax
f0101781:	50                   	push   %eax
f0101782:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0101788:	50                   	push   %eax
f0101789:	68 95 02 00 00       	push   $0x295
f010178e:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101794:	50                   	push   %eax
f0101795:	89 fb                	mov    %edi,%ebx
f0101797:	e8 fd e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010179c:	8d 87 8f d9 fe ff    	lea    -0x12671(%edi),%eax
f01017a2:	50                   	push   %eax
f01017a3:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01017a9:	50                   	push   %eax
f01017aa:	68 96 02 00 00       	push   $0x296
f01017af:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01017b5:	50                   	push   %eax
f01017b6:	89 fb                	mov    %edi,%ebx
f01017b8:	e8 dc e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01017bd:	8d 87 a5 d9 fe ff    	lea    -0x1265b(%edi),%eax
f01017c3:	50                   	push   %eax
f01017c4:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01017ca:	50                   	push   %eax
f01017cb:	68 97 02 00 00       	push   $0x297
f01017d0:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01017d6:	50                   	push   %eax
f01017d7:	89 fb                	mov    %edi,%ebx
f01017d9:	e8 bb e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01017de:	8d 87 bb d9 fe ff    	lea    -0x12645(%edi),%eax
f01017e4:	50                   	push   %eax
f01017e5:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01017eb:	50                   	push   %eax
f01017ec:	68 99 02 00 00       	push   $0x299
f01017f1:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01017f7:	50                   	push   %eax
f01017f8:	89 fb                	mov    %edi,%ebx
f01017fa:	e8 9a e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017ff:	8d 87 bc d2 fe ff    	lea    -0x12d44(%edi),%eax
f0101805:	50                   	push   %eax
f0101806:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010180c:	50                   	push   %eax
f010180d:	68 9a 02 00 00       	push   $0x29a
f0101812:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101818:	50                   	push   %eax
f0101819:	89 fb                	mov    %edi,%ebx
f010181b:	e8 79 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101820:	8d 87 24 da fe ff    	lea    -0x125dc(%edi),%eax
f0101826:	50                   	push   %eax
f0101827:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010182d:	50                   	push   %eax
f010182e:	68 9b 02 00 00       	push   $0x29b
f0101833:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101839:	50                   	push   %eax
f010183a:	89 fb                	mov    %edi,%ebx
f010183c:	e8 58 e8 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101841:	50                   	push   %eax
f0101842:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f0101848:	50                   	push   %eax
f0101849:	6a 59                	push   $0x59
f010184b:	8d 87 b4 d8 fe ff    	lea    -0x1274c(%edi),%eax
f0101851:	50                   	push   %eax
f0101852:	89 fb                	mov    %edi,%ebx
f0101854:	e8 40 e8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101859:	8d 87 33 da fe ff    	lea    -0x125cd(%edi),%eax
f010185f:	50                   	push   %eax
f0101860:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0101866:	50                   	push   %eax
f0101867:	68 a0 02 00 00       	push   $0x2a0
f010186c:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101872:	50                   	push   %eax
f0101873:	e8 21 e8 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101878:	8d 87 51 da fe ff    	lea    -0x125af(%edi),%eax
f010187e:	50                   	push   %eax
f010187f:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0101885:	50                   	push   %eax
f0101886:	68 a1 02 00 00       	push   $0x2a1
f010188b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0101891:	50                   	push   %eax
f0101892:	e8 02 e8 ff ff       	call   f0100099 <_panic>
f0101897:	52                   	push   %edx
f0101898:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f010189e:	50                   	push   %eax
f010189f:	6a 59                	push   $0x59
f01018a1:	8d 87 b4 d8 fe ff    	lea    -0x1274c(%edi),%eax
f01018a7:	50                   	push   %eax
f01018a8:	e8 ec e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f01018ad:	8d 87 61 da fe ff    	lea    -0x1259f(%edi),%eax
f01018b3:	50                   	push   %eax
f01018b4:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01018ba:	50                   	push   %eax
f01018bb:	68 a4 02 00 00       	push   $0x2a4
f01018c0:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01018c6:	50                   	push   %eax
f01018c7:	89 fb                	mov    %edi,%ebx
f01018c9:	e8 cb e7 ff ff       	call   f0100099 <_panic>
		--nfree;
f01018ce:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018d1:	8b 00                	mov    (%eax),%eax
f01018d3:	85 c0                	test   %eax,%eax
f01018d5:	75 f7                	jne    f01018ce <mem_init+0x613>
	assert(nfree == 0);
f01018d7:	85 f6                	test   %esi,%esi
f01018d9:	0f 85 69 07 00 00    	jne    f0102048 <mem_init+0xd8d>
	cprintf("check_page_alloc() succeeded!\n");
f01018df:	83 ec 0c             	sub    $0xc,%esp
f01018e2:	8d 87 dc d2 fe ff    	lea    -0x12d24(%edi),%eax
f01018e8:	50                   	push   %eax
f01018e9:	89 fb                	mov    %edi,%ebx
f01018eb:	e8 00 16 00 00       	call   f0102ef0 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018f7:	e8 e9 f6 ff ff       	call   f0100fe5 <page_alloc>
f01018fc:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01018ff:	83 c4 10             	add    $0x10,%esp
f0101902:	85 c0                	test   %eax,%eax
f0101904:	0f 84 5f 07 00 00    	je     f0102069 <mem_init+0xdae>
	assert((pp1 = page_alloc(0)));
f010190a:	83 ec 0c             	sub    $0xc,%esp
f010190d:	6a 00                	push   $0x0
f010190f:	e8 d1 f6 ff ff       	call   f0100fe5 <page_alloc>
f0101914:	89 c6                	mov    %eax,%esi
f0101916:	83 c4 10             	add    $0x10,%esp
f0101919:	85 c0                	test   %eax,%eax
f010191b:	0f 84 67 07 00 00    	je     f0102088 <mem_init+0xdcd>
	assert((pp2 = page_alloc(0)));
f0101921:	83 ec 0c             	sub    $0xc,%esp
f0101924:	6a 00                	push   $0x0
f0101926:	e8 ba f6 ff ff       	call   f0100fe5 <page_alloc>
f010192b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010192e:	83 c4 10             	add    $0x10,%esp
f0101931:	85 c0                	test   %eax,%eax
f0101933:	0f 84 6e 07 00 00    	je     f01020a7 <mem_init+0xdec>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101939:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f010193c:	0f 84 84 07 00 00    	je     f01020c6 <mem_init+0xe0b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101942:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101945:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101948:	0f 84 97 07 00 00    	je     f01020e5 <mem_init+0xe2a>
f010194e:	39 c6                	cmp    %eax,%esi
f0101950:	0f 84 8f 07 00 00    	je     f01020e5 <mem_init+0xe2a>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101956:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f010195c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f010195f:	c7 87 90 1f 00 00 00 	movl   $0x0,0x1f90(%edi)
f0101966:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101969:	83 ec 0c             	sub    $0xc,%esp
f010196c:	6a 00                	push   $0x0
f010196e:	e8 72 f6 ff ff       	call   f0100fe5 <page_alloc>
f0101973:	83 c4 10             	add    $0x10,%esp
f0101976:	85 c0                	test   %eax,%eax
f0101978:	0f 85 88 07 00 00    	jne    f0102106 <mem_init+0xe4b>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010197e:	83 ec 04             	sub    $0x4,%esp
f0101981:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101984:	50                   	push   %eax
f0101985:	6a 00                	push   $0x0
f0101987:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f010198d:	ff 30                	pushl  (%eax)
f010198f:	e8 fc f7 ff ff       	call   f0101190 <page_lookup>
f0101994:	83 c4 10             	add    $0x10,%esp
f0101997:	85 c0                	test   %eax,%eax
f0101999:	0f 85 86 07 00 00    	jne    f0102125 <mem_init+0xe6a>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010199f:	6a 02                	push   $0x2
f01019a1:	6a 00                	push   $0x0
f01019a3:	56                   	push   %esi
f01019a4:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f01019aa:	ff 30                	pushl  (%eax)
f01019ac:	e8 8c f8 ff ff       	call   f010123d <page_insert>
f01019b1:	83 c4 10             	add    $0x10,%esp
f01019b4:	85 c0                	test   %eax,%eax
f01019b6:	0f 89 88 07 00 00    	jns    f0102144 <mem_init+0xe89>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019bc:	83 ec 0c             	sub    $0xc,%esp
f01019bf:	ff 75 d0             	pushl  -0x30(%ebp)
f01019c2:	e8 a6 f6 ff ff       	call   f010106d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019c7:	6a 02                	push   $0x2
f01019c9:	6a 00                	push   $0x0
f01019cb:	56                   	push   %esi
f01019cc:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f01019d2:	ff 30                	pushl  (%eax)
f01019d4:	e8 64 f8 ff ff       	call   f010123d <page_insert>
f01019d9:	83 c4 20             	add    $0x20,%esp
f01019dc:	85 c0                	test   %eax,%eax
f01019de:	0f 85 7f 07 00 00    	jne    f0102163 <mem_init+0xea8>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019e4:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f01019ea:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f01019ec:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f01019f2:	8b 08                	mov    (%eax),%ecx
f01019f4:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01019f7:	8b 13                	mov    (%ebx),%edx
f01019f9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019ff:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a02:	29 c8                	sub    %ecx,%eax
f0101a04:	c1 f8 03             	sar    $0x3,%eax
f0101a07:	c1 e0 0c             	shl    $0xc,%eax
f0101a0a:	39 c2                	cmp    %eax,%edx
f0101a0c:	0f 85 70 07 00 00    	jne    f0102182 <mem_init+0xec7>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a12:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a17:	89 d8                	mov    %ebx,%eax
f0101a19:	e8 d8 f0 ff ff       	call   f0100af6 <check_va2pa>
f0101a1e:	89 f2                	mov    %esi,%edx
f0101a20:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a23:	c1 fa 03             	sar    $0x3,%edx
f0101a26:	c1 e2 0c             	shl    $0xc,%edx
f0101a29:	39 d0                	cmp    %edx,%eax
f0101a2b:	0f 85 72 07 00 00    	jne    f01021a3 <mem_init+0xee8>
	assert(pp1->pp_ref == 1);
f0101a31:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a36:	0f 85 88 07 00 00    	jne    f01021c4 <mem_init+0xf09>
	assert(pp0->pp_ref == 1);
f0101a3c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a3f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a44:	0f 85 9b 07 00 00    	jne    f01021e5 <mem_init+0xf2a>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a4a:	6a 02                	push   $0x2
f0101a4c:	68 00 10 00 00       	push   $0x1000
f0101a51:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a54:	53                   	push   %ebx
f0101a55:	e8 e3 f7 ff ff       	call   f010123d <page_insert>
f0101a5a:	83 c4 10             	add    $0x10,%esp
f0101a5d:	85 c0                	test   %eax,%eax
f0101a5f:	0f 85 a1 07 00 00    	jne    f0102206 <mem_init+0xf4b>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a65:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a6a:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101a70:	8b 00                	mov    (%eax),%eax
f0101a72:	e8 7f f0 ff ff       	call   f0100af6 <check_va2pa>
f0101a77:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101a7d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a80:	2b 0a                	sub    (%edx),%ecx
f0101a82:	89 ca                	mov    %ecx,%edx
f0101a84:	c1 fa 03             	sar    $0x3,%edx
f0101a87:	c1 e2 0c             	shl    $0xc,%edx
f0101a8a:	39 d0                	cmp    %edx,%eax
f0101a8c:	0f 85 95 07 00 00    	jne    f0102227 <mem_init+0xf6c>
	assert(pp2->pp_ref == 1);
f0101a92:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a95:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a9a:	0f 85 a8 07 00 00    	jne    f0102248 <mem_init+0xf8d>

	// should be no free memory
	assert(!page_alloc(0));
f0101aa0:	83 ec 0c             	sub    $0xc,%esp
f0101aa3:	6a 00                	push   $0x0
f0101aa5:	e8 3b f5 ff ff       	call   f0100fe5 <page_alloc>
f0101aaa:	83 c4 10             	add    $0x10,%esp
f0101aad:	85 c0                	test   %eax,%eax
f0101aaf:	0f 85 b4 07 00 00    	jne    f0102269 <mem_init+0xfae>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ab5:	6a 02                	push   $0x2
f0101ab7:	68 00 10 00 00       	push   $0x1000
f0101abc:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101abf:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101ac5:	ff 30                	pushl  (%eax)
f0101ac7:	e8 71 f7 ff ff       	call   f010123d <page_insert>
f0101acc:	83 c4 10             	add    $0x10,%esp
f0101acf:	85 c0                	test   %eax,%eax
f0101ad1:	0f 85 b3 07 00 00    	jne    f010228a <mem_init+0xfcf>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ad7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101adc:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101ae2:	8b 00                	mov    (%eax),%eax
f0101ae4:	e8 0d f0 ff ff       	call   f0100af6 <check_va2pa>
f0101ae9:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101aef:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101af2:	2b 0a                	sub    (%edx),%ecx
f0101af4:	89 ca                	mov    %ecx,%edx
f0101af6:	c1 fa 03             	sar    $0x3,%edx
f0101af9:	c1 e2 0c             	shl    $0xc,%edx
f0101afc:	39 d0                	cmp    %edx,%eax
f0101afe:	0f 85 a7 07 00 00    	jne    f01022ab <mem_init+0xff0>
	assert(pp2->pp_ref == 1);
f0101b04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b07:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b0c:	0f 85 ba 07 00 00    	jne    f01022cc <mem_init+0x1011>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b12:	83 ec 0c             	sub    $0xc,%esp
f0101b15:	6a 00                	push   $0x0
f0101b17:	e8 c9 f4 ff ff       	call   f0100fe5 <page_alloc>
f0101b1c:	83 c4 10             	add    $0x10,%esp
f0101b1f:	85 c0                	test   %eax,%eax
f0101b21:	0f 85 c6 07 00 00    	jne    f01022ed <mem_init+0x1032>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b27:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b2d:	8b 10                	mov    (%eax),%edx
f0101b2f:	8b 02                	mov    (%edx),%eax
f0101b31:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101b36:	89 c3                	mov    %eax,%ebx
f0101b38:	c1 eb 0c             	shr    $0xc,%ebx
f0101b3b:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f0101b41:	3b 19                	cmp    (%ecx),%ebx
f0101b43:	0f 83 c5 07 00 00    	jae    f010230e <mem_init+0x1053>
	return (void *)(pa + KERNBASE);
f0101b49:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b4e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b51:	83 ec 04             	sub    $0x4,%esp
f0101b54:	6a 00                	push   $0x0
f0101b56:	68 00 10 00 00       	push   $0x1000
f0101b5b:	52                   	push   %edx
f0101b5c:	e8 84 f5 ff ff       	call   f01010e5 <pgdir_walk>
f0101b61:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b64:	8d 51 04             	lea    0x4(%ecx),%edx
f0101b67:	83 c4 10             	add    $0x10,%esp
f0101b6a:	39 d0                	cmp    %edx,%eax
f0101b6c:	0f 85 b7 07 00 00    	jne    f0102329 <mem_init+0x106e>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b72:	6a 06                	push   $0x6
f0101b74:	68 00 10 00 00       	push   $0x1000
f0101b79:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b7c:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b82:	ff 30                	pushl  (%eax)
f0101b84:	e8 b4 f6 ff ff       	call   f010123d <page_insert>
f0101b89:	83 c4 10             	add    $0x10,%esp
f0101b8c:	85 c0                	test   %eax,%eax
f0101b8e:	0f 85 b6 07 00 00    	jne    f010234a <mem_init+0x108f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b94:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101b9a:	8b 18                	mov    (%eax),%ebx
f0101b9c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ba1:	89 d8                	mov    %ebx,%eax
f0101ba3:	e8 4e ef ff ff       	call   f0100af6 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101ba8:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101bae:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bb1:	2b 0a                	sub    (%edx),%ecx
f0101bb3:	89 ca                	mov    %ecx,%edx
f0101bb5:	c1 fa 03             	sar    $0x3,%edx
f0101bb8:	c1 e2 0c             	shl    $0xc,%edx
f0101bbb:	39 d0                	cmp    %edx,%eax
f0101bbd:	0f 85 a8 07 00 00    	jne    f010236b <mem_init+0x10b0>
	assert(pp2->pp_ref == 1);
f0101bc3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bc6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bcb:	0f 85 bb 07 00 00    	jne    f010238c <mem_init+0x10d1>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bd1:	83 ec 04             	sub    $0x4,%esp
f0101bd4:	6a 00                	push   $0x0
f0101bd6:	68 00 10 00 00       	push   $0x1000
f0101bdb:	53                   	push   %ebx
f0101bdc:	e8 04 f5 ff ff       	call   f01010e5 <pgdir_walk>
f0101be1:	83 c4 10             	add    $0x10,%esp
f0101be4:	f6 00 04             	testb  $0x4,(%eax)
f0101be7:	0f 84 c0 07 00 00    	je     f01023ad <mem_init+0x10f2>
	assert(kern_pgdir[0] & PTE_U);
f0101bed:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101bf3:	8b 00                	mov    (%eax),%eax
f0101bf5:	f6 00 04             	testb  $0x4,(%eax)
f0101bf8:	0f 84 d0 07 00 00    	je     f01023ce <mem_init+0x1113>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bfe:	6a 02                	push   $0x2
f0101c00:	68 00 10 00 00       	push   $0x1000
f0101c05:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c08:	50                   	push   %eax
f0101c09:	e8 2f f6 ff ff       	call   f010123d <page_insert>
f0101c0e:	83 c4 10             	add    $0x10,%esp
f0101c11:	85 c0                	test   %eax,%eax
f0101c13:	0f 85 d6 07 00 00    	jne    f01023ef <mem_init+0x1134>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c19:	83 ec 04             	sub    $0x4,%esp
f0101c1c:	6a 00                	push   $0x0
f0101c1e:	68 00 10 00 00       	push   $0x1000
f0101c23:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c29:	ff 30                	pushl  (%eax)
f0101c2b:	e8 b5 f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c30:	83 c4 10             	add    $0x10,%esp
f0101c33:	f6 00 02             	testb  $0x2,(%eax)
f0101c36:	0f 84 d4 07 00 00    	je     f0102410 <mem_init+0x1155>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c3c:	83 ec 04             	sub    $0x4,%esp
f0101c3f:	6a 00                	push   $0x0
f0101c41:	68 00 10 00 00       	push   $0x1000
f0101c46:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c4c:	ff 30                	pushl  (%eax)
f0101c4e:	e8 92 f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101c53:	83 c4 10             	add    $0x10,%esp
f0101c56:	f6 00 04             	testb  $0x4,(%eax)
f0101c59:	0f 85 d2 07 00 00    	jne    f0102431 <mem_init+0x1176>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c5f:	6a 02                	push   $0x2
f0101c61:	68 00 00 40 00       	push   $0x400000
f0101c66:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c69:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c6f:	ff 30                	pushl  (%eax)
f0101c71:	e8 c7 f5 ff ff       	call   f010123d <page_insert>
f0101c76:	83 c4 10             	add    $0x10,%esp
f0101c79:	85 c0                	test   %eax,%eax
f0101c7b:	0f 89 d1 07 00 00    	jns    f0102452 <mem_init+0x1197>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c81:	6a 02                	push   $0x2
f0101c83:	68 00 10 00 00       	push   $0x1000
f0101c88:	56                   	push   %esi
f0101c89:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101c8f:	ff 30                	pushl  (%eax)
f0101c91:	e8 a7 f5 ff ff       	call   f010123d <page_insert>
f0101c96:	83 c4 10             	add    $0x10,%esp
f0101c99:	85 c0                	test   %eax,%eax
f0101c9b:	0f 85 d2 07 00 00    	jne    f0102473 <mem_init+0x11b8>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ca1:	83 ec 04             	sub    $0x4,%esp
f0101ca4:	6a 00                	push   $0x0
f0101ca6:	68 00 10 00 00       	push   $0x1000
f0101cab:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101cb1:	ff 30                	pushl  (%eax)
f0101cb3:	e8 2d f4 ff ff       	call   f01010e5 <pgdir_walk>
f0101cb8:	83 c4 10             	add    $0x10,%esp
f0101cbb:	f6 00 04             	testb  $0x4,(%eax)
f0101cbe:	0f 85 d0 07 00 00    	jne    f0102494 <mem_init+0x11d9>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101cc4:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101cca:	8b 18                	mov    (%eax),%ebx
f0101ccc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cd1:	89 d8                	mov    %ebx,%eax
f0101cd3:	e8 1e ee ff ff       	call   f0100af6 <check_va2pa>
f0101cd8:	89 c2                	mov    %eax,%edx
f0101cda:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101cdd:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101ce3:	89 f1                	mov    %esi,%ecx
f0101ce5:	2b 08                	sub    (%eax),%ecx
f0101ce7:	89 c8                	mov    %ecx,%eax
f0101ce9:	c1 f8 03             	sar    $0x3,%eax
f0101cec:	c1 e0 0c             	shl    $0xc,%eax
f0101cef:	39 c2                	cmp    %eax,%edx
f0101cf1:	0f 85 be 07 00 00    	jne    f01024b5 <mem_init+0x11fa>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cf7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cfc:	89 d8                	mov    %ebx,%eax
f0101cfe:	e8 f3 ed ff ff       	call   f0100af6 <check_va2pa>
f0101d03:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d06:	0f 85 ca 07 00 00    	jne    f01024d6 <mem_init+0x121b>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d0c:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101d11:	0f 85 e0 07 00 00    	jne    f01024f7 <mem_init+0x123c>
	assert(pp2->pp_ref == 0);
f0101d17:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d1a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101d1f:	0f 85 f3 07 00 00    	jne    f0102518 <mem_init+0x125d>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d25:	83 ec 0c             	sub    $0xc,%esp
f0101d28:	6a 00                	push   $0x0
f0101d2a:	e8 b6 f2 ff ff       	call   f0100fe5 <page_alloc>
f0101d2f:	83 c4 10             	add    $0x10,%esp
f0101d32:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d35:	0f 85 fe 07 00 00    	jne    f0102539 <mem_init+0x127e>
f0101d3b:	85 c0                	test   %eax,%eax
f0101d3d:	0f 84 f6 07 00 00    	je     f0102539 <mem_init+0x127e>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d43:	83 ec 08             	sub    $0x8,%esp
f0101d46:	6a 00                	push   $0x0
f0101d48:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101d4e:	ff 33                	pushl  (%ebx)
f0101d50:	e8 ab f4 ff ff       	call   f0101200 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d55:	8b 1b                	mov    (%ebx),%ebx
f0101d57:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d5c:	89 d8                	mov    %ebx,%eax
f0101d5e:	e8 93 ed ff ff       	call   f0100af6 <check_va2pa>
f0101d63:	83 c4 10             	add    $0x10,%esp
f0101d66:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d69:	0f 85 eb 07 00 00    	jne    f010255a <mem_init+0x129f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d6f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d74:	89 d8                	mov    %ebx,%eax
f0101d76:	e8 7b ed ff ff       	call   f0100af6 <check_va2pa>
f0101d7b:	c7 c2 b0 96 11 f0    	mov    $0xf01196b0,%edx
f0101d81:	89 f1                	mov    %esi,%ecx
f0101d83:	2b 0a                	sub    (%edx),%ecx
f0101d85:	89 ca                	mov    %ecx,%edx
f0101d87:	c1 fa 03             	sar    $0x3,%edx
f0101d8a:	c1 e2 0c             	shl    $0xc,%edx
f0101d8d:	39 d0                	cmp    %edx,%eax
f0101d8f:	0f 85 e6 07 00 00    	jne    f010257b <mem_init+0x12c0>
	assert(pp1->pp_ref == 1);
f0101d95:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d9a:	0f 85 fc 07 00 00    	jne    f010259c <mem_init+0x12e1>
	assert(pp2->pp_ref == 0);
f0101da0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101da3:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101da8:	0f 85 0f 08 00 00    	jne    f01025bd <mem_init+0x1302>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dae:	6a 00                	push   $0x0
f0101db0:	68 00 10 00 00       	push   $0x1000
f0101db5:	56                   	push   %esi
f0101db6:	53                   	push   %ebx
f0101db7:	e8 81 f4 ff ff       	call   f010123d <page_insert>
f0101dbc:	83 c4 10             	add    $0x10,%esp
f0101dbf:	85 c0                	test   %eax,%eax
f0101dc1:	0f 85 17 08 00 00    	jne    f01025de <mem_init+0x1323>
	assert(pp1->pp_ref);
f0101dc7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dcc:	0f 84 2d 08 00 00    	je     f01025ff <mem_init+0x1344>
	assert(pp1->pp_link == NULL);
f0101dd2:	83 3e 00             	cmpl   $0x0,(%esi)
f0101dd5:	0f 85 45 08 00 00    	jne    f0102620 <mem_init+0x1365>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ddb:	83 ec 08             	sub    $0x8,%esp
f0101dde:	68 00 10 00 00       	push   $0x1000
f0101de3:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101de9:	ff 33                	pushl  (%ebx)
f0101deb:	e8 10 f4 ff ff       	call   f0101200 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101df0:	8b 1b                	mov    (%ebx),%ebx
f0101df2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101df7:	89 d8                	mov    %ebx,%eax
f0101df9:	e8 f8 ec ff ff       	call   f0100af6 <check_va2pa>
f0101dfe:	83 c4 10             	add    $0x10,%esp
f0101e01:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e04:	0f 85 37 08 00 00    	jne    f0102641 <mem_init+0x1386>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e0a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e0f:	89 d8                	mov    %ebx,%eax
f0101e11:	e8 e0 ec ff ff       	call   f0100af6 <check_va2pa>
f0101e16:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e19:	0f 85 43 08 00 00    	jne    f0102662 <mem_init+0x13a7>
	assert(pp1->pp_ref == 0);
f0101e1f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e24:	0f 85 59 08 00 00    	jne    f0102683 <mem_init+0x13c8>
	assert(pp2->pp_ref == 0);
f0101e2a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e2d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e32:	0f 85 6c 08 00 00    	jne    f01026a4 <mem_init+0x13e9>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e38:	83 ec 0c             	sub    $0xc,%esp
f0101e3b:	6a 00                	push   $0x0
f0101e3d:	e8 a3 f1 ff ff       	call   f0100fe5 <page_alloc>
f0101e42:	83 c4 10             	add    $0x10,%esp
f0101e45:	85 c0                	test   %eax,%eax
f0101e47:	0f 84 78 08 00 00    	je     f01026c5 <mem_init+0x140a>
f0101e4d:	39 c6                	cmp    %eax,%esi
f0101e4f:	0f 85 70 08 00 00    	jne    f01026c5 <mem_init+0x140a>

	// should be no free memory
	assert(!page_alloc(0));
f0101e55:	83 ec 0c             	sub    $0xc,%esp
f0101e58:	6a 00                	push   $0x0
f0101e5a:	e8 86 f1 ff ff       	call   f0100fe5 <page_alloc>
f0101e5f:	83 c4 10             	add    $0x10,%esp
f0101e62:	85 c0                	test   %eax,%eax
f0101e64:	0f 85 7c 08 00 00    	jne    f01026e6 <mem_init+0x142b>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e6a:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101e70:	8b 08                	mov    (%eax),%ecx
f0101e72:	8b 11                	mov    (%ecx),%edx
f0101e74:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e7a:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101e80:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101e83:	2b 18                	sub    (%eax),%ebx
f0101e85:	89 d8                	mov    %ebx,%eax
f0101e87:	c1 f8 03             	sar    $0x3,%eax
f0101e8a:	c1 e0 0c             	shl    $0xc,%eax
f0101e8d:	39 c2                	cmp    %eax,%edx
f0101e8f:	0f 85 72 08 00 00    	jne    f0102707 <mem_init+0x144c>
	kern_pgdir[0] = 0;
f0101e95:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e9b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e9e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ea3:	0f 85 7f 08 00 00    	jne    f0102728 <mem_init+0x146d>
	pp0->pp_ref = 0;
f0101ea9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101eac:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101eb2:	83 ec 0c             	sub    $0xc,%esp
f0101eb5:	50                   	push   %eax
f0101eb6:	e8 b2 f1 ff ff       	call   f010106d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ebb:	83 c4 0c             	add    $0xc,%esp
f0101ebe:	6a 01                	push   $0x1
f0101ec0:	68 00 10 40 00       	push   $0x401000
f0101ec5:	c7 c3 ac 96 11 f0    	mov    $0xf01196ac,%ebx
f0101ecb:	ff 33                	pushl  (%ebx)
f0101ecd:	e8 13 f2 ff ff       	call   f01010e5 <pgdir_walk>
f0101ed2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ed5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101ed8:	8b 1b                	mov    (%ebx),%ebx
f0101eda:	8b 53 04             	mov    0x4(%ebx),%edx
f0101edd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101ee3:	c7 c1 a8 96 11 f0    	mov    $0xf01196a8,%ecx
f0101ee9:	8b 09                	mov    (%ecx),%ecx
f0101eeb:	89 d0                	mov    %edx,%eax
f0101eed:	c1 e8 0c             	shr    $0xc,%eax
f0101ef0:	83 c4 10             	add    $0x10,%esp
f0101ef3:	39 c8                	cmp    %ecx,%eax
f0101ef5:	0f 83 4e 08 00 00    	jae    f0102749 <mem_init+0x148e>
	assert(ptep == ptep1 + PTX(va));
f0101efb:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101f01:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101f04:	0f 85 5a 08 00 00    	jne    f0102764 <mem_init+0x14a9>
	kern_pgdir[PDX(va)] = 0;
f0101f0a:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0101f11:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f14:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0101f1a:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101f20:	2b 18                	sub    (%eax),%ebx
f0101f22:	89 d8                	mov    %ebx,%eax
f0101f24:	c1 f8 03             	sar    $0x3,%eax
f0101f27:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101f2a:	89 c2                	mov    %eax,%edx
f0101f2c:	c1 ea 0c             	shr    $0xc,%edx
f0101f2f:	39 d1                	cmp    %edx,%ecx
f0101f31:	0f 86 4e 08 00 00    	jbe    f0102785 <mem_init+0x14ca>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f37:	83 ec 04             	sub    $0x4,%esp
f0101f3a:	68 00 10 00 00       	push   $0x1000
f0101f3f:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101f44:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f49:	50                   	push   %eax
f0101f4a:	89 fb                	mov    %edi,%ebx
f0101f4c:	e8 b0 1b 00 00       	call   f0103b01 <memset>
	page_free(pp0);
f0101f51:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f54:	89 1c 24             	mov    %ebx,(%esp)
f0101f57:	e8 11 f1 ff ff       	call   f010106d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f5c:	83 c4 0c             	add    $0xc,%esp
f0101f5f:	6a 01                	push   $0x1
f0101f61:	6a 00                	push   $0x0
f0101f63:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101f69:	ff 30                	pushl  (%eax)
f0101f6b:	e8 75 f1 ff ff       	call   f01010e5 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101f70:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0101f76:	2b 18                	sub    (%eax),%ebx
f0101f78:	89 da                	mov    %ebx,%edx
f0101f7a:	c1 fa 03             	sar    $0x3,%edx
f0101f7d:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101f80:	89 d1                	mov    %edx,%ecx
f0101f82:	c1 e9 0c             	shr    $0xc,%ecx
f0101f85:	83 c4 10             	add    $0x10,%esp
f0101f88:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f0101f8e:	3b 08                	cmp    (%eax),%ecx
f0101f90:	0f 83 07 08 00 00    	jae    f010279d <mem_init+0x14e2>
	return (void *)(pa + KERNBASE);
f0101f96:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f9c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f9f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101fa5:	f6 00 01             	testb  $0x1,(%eax)
f0101fa8:	0f 85 07 08 00 00    	jne    f01027b5 <mem_init+0x14fa>
f0101fae:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101fb1:	39 d0                	cmp    %edx,%eax
f0101fb3:	75 f0                	jne    f0101fa5 <mem_init+0xcea>
	kern_pgdir[0] = 0;
f0101fb5:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0101fbb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fbe:	8b 00                	mov    (%eax),%eax
f0101fc0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101fc6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101fc9:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)

	// give free list back
	page_free_list = fl;
f0101fcf:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0101fd2:	89 9f 90 1f 00 00    	mov    %ebx,0x1f90(%edi)

	// free the pages we took
	page_free(pp0);
f0101fd8:	83 ec 0c             	sub    $0xc,%esp
f0101fdb:	51                   	push   %ecx
f0101fdc:	e8 8c f0 ff ff       	call   f010106d <page_free>
	page_free(pp1);
f0101fe1:	89 34 24             	mov    %esi,(%esp)
f0101fe4:	e8 84 f0 ff ff       	call   f010106d <page_free>
	page_free(pp2);
f0101fe9:	83 c4 04             	add    $0x4,%esp
f0101fec:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101fef:	e8 79 f0 ff ff       	call   f010106d <page_free>

	cprintf("check_page() succeeded!\n");
f0101ff4:	8d 87 42 db fe ff    	lea    -0x124be(%edi),%eax
f0101ffa:	89 04 24             	mov    %eax,(%esp)
f0101ffd:	89 fb                	mov    %edi,%ebx
f0101fff:	e8 ec 0e 00 00       	call   f0102ef0 <cprintf>
	pgdir = kern_pgdir;
f0102004:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102007:	8b 18                	mov    (%eax),%ebx
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102009:	c7 c0 a8 96 11 f0    	mov    $0xf01196a8,%eax
f010200f:	8b 00                	mov    (%eax),%eax
f0102011:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102014:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010201b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102020:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102023:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102029:	8b 00                	mov    (%eax),%eax
f010202b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if ((uint32_t)kva < KERNBASE)
f010202e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102031:	05 00 00 00 10       	add    $0x10000000,%eax
f0102036:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0102039:	be 00 00 00 00       	mov    $0x0,%esi
f010203e:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0102041:	89 c3                	mov    %eax,%ebx
f0102043:	e9 b1 07 00 00       	jmp    f01027f9 <mem_init+0x153e>
	assert(nfree == 0);
f0102048:	8d 87 6b da fe ff    	lea    -0x12595(%edi),%eax
f010204e:	50                   	push   %eax
f010204f:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102055:	50                   	push   %eax
f0102056:	68 b1 02 00 00       	push   $0x2b1
f010205b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102061:	50                   	push   %eax
f0102062:	89 fb                	mov    %edi,%ebx
f0102064:	e8 30 e0 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102069:	8d 87 79 d9 fe ff    	lea    -0x12687(%edi),%eax
f010206f:	50                   	push   %eax
f0102070:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102076:	50                   	push   %eax
f0102077:	68 0a 03 00 00       	push   $0x30a
f010207c:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102082:	50                   	push   %eax
f0102083:	e8 11 e0 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102088:	8d 87 8f d9 fe ff    	lea    -0x12671(%edi),%eax
f010208e:	50                   	push   %eax
f010208f:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102095:	50                   	push   %eax
f0102096:	68 0b 03 00 00       	push   $0x30b
f010209b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01020a1:	50                   	push   %eax
f01020a2:	e8 f2 df ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01020a7:	8d 87 a5 d9 fe ff    	lea    -0x1265b(%edi),%eax
f01020ad:	50                   	push   %eax
f01020ae:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01020b4:	50                   	push   %eax
f01020b5:	68 0c 03 00 00       	push   $0x30c
f01020ba:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01020c0:	50                   	push   %eax
f01020c1:	e8 d3 df ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01020c6:	8d 87 bb d9 fe ff    	lea    -0x12645(%edi),%eax
f01020cc:	50                   	push   %eax
f01020cd:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01020d3:	50                   	push   %eax
f01020d4:	68 0f 03 00 00       	push   $0x30f
f01020d9:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01020df:	50                   	push   %eax
f01020e0:	e8 b4 df ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01020e5:	8d 87 bc d2 fe ff    	lea    -0x12d44(%edi),%eax
f01020eb:	50                   	push   %eax
f01020ec:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01020f2:	50                   	push   %eax
f01020f3:	68 10 03 00 00       	push   $0x310
f01020f8:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01020fe:	50                   	push   %eax
f01020ff:	89 fb                	mov    %edi,%ebx
f0102101:	e8 93 df ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102106:	8d 87 24 da fe ff    	lea    -0x125dc(%edi),%eax
f010210c:	50                   	push   %eax
f010210d:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102113:	50                   	push   %eax
f0102114:	68 17 03 00 00       	push   $0x317
f0102119:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010211f:	50                   	push   %eax
f0102120:	e8 74 df ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102125:	8d 87 fc d2 fe ff    	lea    -0x12d04(%edi),%eax
f010212b:	50                   	push   %eax
f010212c:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102132:	50                   	push   %eax
f0102133:	68 1a 03 00 00       	push   $0x31a
f0102138:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010213e:	50                   	push   %eax
f010213f:	e8 55 df ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102144:	8d 87 34 d3 fe ff    	lea    -0x12ccc(%edi),%eax
f010214a:	50                   	push   %eax
f010214b:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102151:	50                   	push   %eax
f0102152:	68 1d 03 00 00       	push   $0x31d
f0102157:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010215d:	50                   	push   %eax
f010215e:	e8 36 df ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102163:	8d 87 64 d3 fe ff    	lea    -0x12c9c(%edi),%eax
f0102169:	50                   	push   %eax
f010216a:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102170:	50                   	push   %eax
f0102171:	68 21 03 00 00       	push   $0x321
f0102176:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010217c:	50                   	push   %eax
f010217d:	e8 17 df ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102182:	8d 87 94 d3 fe ff    	lea    -0x12c6c(%edi),%eax
f0102188:	50                   	push   %eax
f0102189:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010218f:	50                   	push   %eax
f0102190:	68 22 03 00 00       	push   $0x322
f0102195:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010219b:	50                   	push   %eax
f010219c:	89 fb                	mov    %edi,%ebx
f010219e:	e8 f6 de ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01021a3:	8d 87 bc d3 fe ff    	lea    -0x12c44(%edi),%eax
f01021a9:	50                   	push   %eax
f01021aa:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01021b0:	50                   	push   %eax
f01021b1:	68 23 03 00 00       	push   $0x323
f01021b6:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01021bc:	50                   	push   %eax
f01021bd:	89 fb                	mov    %edi,%ebx
f01021bf:	e8 d5 de ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01021c4:	8d 87 76 da fe ff    	lea    -0x1258a(%edi),%eax
f01021ca:	50                   	push   %eax
f01021cb:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01021d1:	50                   	push   %eax
f01021d2:	68 24 03 00 00       	push   $0x324
f01021d7:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01021dd:	50                   	push   %eax
f01021de:	89 fb                	mov    %edi,%ebx
f01021e0:	e8 b4 de ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01021e5:	8d 87 87 da fe ff    	lea    -0x12579(%edi),%eax
f01021eb:	50                   	push   %eax
f01021ec:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01021f2:	50                   	push   %eax
f01021f3:	68 25 03 00 00       	push   $0x325
f01021f8:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01021fe:	50                   	push   %eax
f01021ff:	89 fb                	mov    %edi,%ebx
f0102201:	e8 93 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102206:	8d 87 ec d3 fe ff    	lea    -0x12c14(%edi),%eax
f010220c:	50                   	push   %eax
f010220d:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102213:	50                   	push   %eax
f0102214:	68 28 03 00 00       	push   $0x328
f0102219:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010221f:	50                   	push   %eax
f0102220:	89 fb                	mov    %edi,%ebx
f0102222:	e8 72 de ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102227:	8d 87 28 d4 fe ff    	lea    -0x12bd8(%edi),%eax
f010222d:	50                   	push   %eax
f010222e:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102234:	50                   	push   %eax
f0102235:	68 29 03 00 00       	push   $0x329
f010223a:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102240:	50                   	push   %eax
f0102241:	89 fb                	mov    %edi,%ebx
f0102243:	e8 51 de ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102248:	8d 87 98 da fe ff    	lea    -0x12568(%edi),%eax
f010224e:	50                   	push   %eax
f010224f:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102255:	50                   	push   %eax
f0102256:	68 2a 03 00 00       	push   $0x32a
f010225b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102261:	50                   	push   %eax
f0102262:	89 fb                	mov    %edi,%ebx
f0102264:	e8 30 de ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102269:	8d 87 24 da fe ff    	lea    -0x125dc(%edi),%eax
f010226f:	50                   	push   %eax
f0102270:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102276:	50                   	push   %eax
f0102277:	68 2d 03 00 00       	push   $0x32d
f010227c:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102282:	50                   	push   %eax
f0102283:	89 fb                	mov    %edi,%ebx
f0102285:	e8 0f de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010228a:	8d 87 ec d3 fe ff    	lea    -0x12c14(%edi),%eax
f0102290:	50                   	push   %eax
f0102291:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102297:	50                   	push   %eax
f0102298:	68 30 03 00 00       	push   $0x330
f010229d:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01022a3:	50                   	push   %eax
f01022a4:	89 fb                	mov    %edi,%ebx
f01022a6:	e8 ee dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01022ab:	8d 87 28 d4 fe ff    	lea    -0x12bd8(%edi),%eax
f01022b1:	50                   	push   %eax
f01022b2:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01022b8:	50                   	push   %eax
f01022b9:	68 31 03 00 00       	push   $0x331
f01022be:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01022c4:	50                   	push   %eax
f01022c5:	89 fb                	mov    %edi,%ebx
f01022c7:	e8 cd dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01022cc:	8d 87 98 da fe ff    	lea    -0x12568(%edi),%eax
f01022d2:	50                   	push   %eax
f01022d3:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01022d9:	50                   	push   %eax
f01022da:	68 32 03 00 00       	push   $0x332
f01022df:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01022e5:	50                   	push   %eax
f01022e6:	89 fb                	mov    %edi,%ebx
f01022e8:	e8 ac dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01022ed:	8d 87 24 da fe ff    	lea    -0x125dc(%edi),%eax
f01022f3:	50                   	push   %eax
f01022f4:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01022fa:	50                   	push   %eax
f01022fb:	68 36 03 00 00       	push   $0x336
f0102300:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102306:	50                   	push   %eax
f0102307:	89 fb                	mov    %edi,%ebx
f0102309:	e8 8b dd ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010230e:	50                   	push   %eax
f010230f:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f0102315:	50                   	push   %eax
f0102316:	68 39 03 00 00       	push   $0x339
f010231b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102321:	50                   	push   %eax
f0102322:	89 fb                	mov    %edi,%ebx
f0102324:	e8 70 dd ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102329:	8d 87 58 d4 fe ff    	lea    -0x12ba8(%edi),%eax
f010232f:	50                   	push   %eax
f0102330:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102336:	50                   	push   %eax
f0102337:	68 3a 03 00 00       	push   $0x33a
f010233c:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102342:	50                   	push   %eax
f0102343:	89 fb                	mov    %edi,%ebx
f0102345:	e8 4f dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010234a:	8d 87 98 d4 fe ff    	lea    -0x12b68(%edi),%eax
f0102350:	50                   	push   %eax
f0102351:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102357:	50                   	push   %eax
f0102358:	68 3d 03 00 00       	push   $0x33d
f010235d:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102363:	50                   	push   %eax
f0102364:	89 fb                	mov    %edi,%ebx
f0102366:	e8 2e dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010236b:	8d 87 28 d4 fe ff    	lea    -0x12bd8(%edi),%eax
f0102371:	50                   	push   %eax
f0102372:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102378:	50                   	push   %eax
f0102379:	68 3e 03 00 00       	push   $0x33e
f010237e:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102384:	50                   	push   %eax
f0102385:	89 fb                	mov    %edi,%ebx
f0102387:	e8 0d dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010238c:	8d 87 98 da fe ff    	lea    -0x12568(%edi),%eax
f0102392:	50                   	push   %eax
f0102393:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102399:	50                   	push   %eax
f010239a:	68 3f 03 00 00       	push   $0x33f
f010239f:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01023a5:	50                   	push   %eax
f01023a6:	89 fb                	mov    %edi,%ebx
f01023a8:	e8 ec dc ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01023ad:	8d 87 d8 d4 fe ff    	lea    -0x12b28(%edi),%eax
f01023b3:	50                   	push   %eax
f01023b4:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01023ba:	50                   	push   %eax
f01023bb:	68 40 03 00 00       	push   $0x340
f01023c0:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01023c6:	50                   	push   %eax
f01023c7:	89 fb                	mov    %edi,%ebx
f01023c9:	e8 cb dc ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01023ce:	8d 87 a9 da fe ff    	lea    -0x12557(%edi),%eax
f01023d4:	50                   	push   %eax
f01023d5:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01023db:	50                   	push   %eax
f01023dc:	68 41 03 00 00       	push   $0x341
f01023e1:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01023e7:	50                   	push   %eax
f01023e8:	89 fb                	mov    %edi,%ebx
f01023ea:	e8 aa dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023ef:	8d 87 ec d3 fe ff    	lea    -0x12c14(%edi),%eax
f01023f5:	50                   	push   %eax
f01023f6:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01023fc:	50                   	push   %eax
f01023fd:	68 44 03 00 00       	push   $0x344
f0102402:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102408:	50                   	push   %eax
f0102409:	89 fb                	mov    %edi,%ebx
f010240b:	e8 89 dc ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102410:	8d 87 0c d5 fe ff    	lea    -0x12af4(%edi),%eax
f0102416:	50                   	push   %eax
f0102417:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010241d:	50                   	push   %eax
f010241e:	68 45 03 00 00       	push   $0x345
f0102423:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102429:	50                   	push   %eax
f010242a:	89 fb                	mov    %edi,%ebx
f010242c:	e8 68 dc ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102431:	8d 87 40 d5 fe ff    	lea    -0x12ac0(%edi),%eax
f0102437:	50                   	push   %eax
f0102438:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010243e:	50                   	push   %eax
f010243f:	68 46 03 00 00       	push   $0x346
f0102444:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010244a:	50                   	push   %eax
f010244b:	89 fb                	mov    %edi,%ebx
f010244d:	e8 47 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102452:	8d 87 78 d5 fe ff    	lea    -0x12a88(%edi),%eax
f0102458:	50                   	push   %eax
f0102459:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010245f:	50                   	push   %eax
f0102460:	68 49 03 00 00       	push   $0x349
f0102465:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010246b:	50                   	push   %eax
f010246c:	89 fb                	mov    %edi,%ebx
f010246e:	e8 26 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102473:	8d 87 b0 d5 fe ff    	lea    -0x12a50(%edi),%eax
f0102479:	50                   	push   %eax
f010247a:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102480:	50                   	push   %eax
f0102481:	68 4c 03 00 00       	push   $0x34c
f0102486:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010248c:	50                   	push   %eax
f010248d:	89 fb                	mov    %edi,%ebx
f010248f:	e8 05 dc ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102494:	8d 87 40 d5 fe ff    	lea    -0x12ac0(%edi),%eax
f010249a:	50                   	push   %eax
f010249b:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01024a1:	50                   	push   %eax
f01024a2:	68 4d 03 00 00       	push   $0x34d
f01024a7:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01024ad:	50                   	push   %eax
f01024ae:	89 fb                	mov    %edi,%ebx
f01024b0:	e8 e4 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01024b5:	8d 87 ec d5 fe ff    	lea    -0x12a14(%edi),%eax
f01024bb:	50                   	push   %eax
f01024bc:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01024c2:	50                   	push   %eax
f01024c3:	68 50 03 00 00       	push   $0x350
f01024c8:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01024ce:	50                   	push   %eax
f01024cf:	89 fb                	mov    %edi,%ebx
f01024d1:	e8 c3 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01024d6:	8d 87 18 d6 fe ff    	lea    -0x129e8(%edi),%eax
f01024dc:	50                   	push   %eax
f01024dd:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01024e3:	50                   	push   %eax
f01024e4:	68 51 03 00 00       	push   $0x351
f01024e9:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01024ef:	50                   	push   %eax
f01024f0:	89 fb                	mov    %edi,%ebx
f01024f2:	e8 a2 db ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f01024f7:	8d 87 bf da fe ff    	lea    -0x12541(%edi),%eax
f01024fd:	50                   	push   %eax
f01024fe:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102504:	50                   	push   %eax
f0102505:	68 53 03 00 00       	push   $0x353
f010250a:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102510:	50                   	push   %eax
f0102511:	89 fb                	mov    %edi,%ebx
f0102513:	e8 81 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102518:	8d 87 d0 da fe ff    	lea    -0x12530(%edi),%eax
f010251e:	50                   	push   %eax
f010251f:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102525:	50                   	push   %eax
f0102526:	68 54 03 00 00       	push   $0x354
f010252b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102531:	50                   	push   %eax
f0102532:	89 fb                	mov    %edi,%ebx
f0102534:	e8 60 db ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102539:	8d 87 48 d6 fe ff    	lea    -0x129b8(%edi),%eax
f010253f:	50                   	push   %eax
f0102540:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102546:	50                   	push   %eax
f0102547:	68 57 03 00 00       	push   $0x357
f010254c:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102552:	50                   	push   %eax
f0102553:	89 fb                	mov    %edi,%ebx
f0102555:	e8 3f db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010255a:	8d 87 6c d6 fe ff    	lea    -0x12994(%edi),%eax
f0102560:	50                   	push   %eax
f0102561:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102567:	50                   	push   %eax
f0102568:	68 5b 03 00 00       	push   $0x35b
f010256d:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102573:	50                   	push   %eax
f0102574:	89 fb                	mov    %edi,%ebx
f0102576:	e8 1e db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010257b:	8d 87 18 d6 fe ff    	lea    -0x129e8(%edi),%eax
f0102581:	50                   	push   %eax
f0102582:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102588:	50                   	push   %eax
f0102589:	68 5c 03 00 00       	push   $0x35c
f010258e:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102594:	50                   	push   %eax
f0102595:	89 fb                	mov    %edi,%ebx
f0102597:	e8 fd da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f010259c:	8d 87 76 da fe ff    	lea    -0x1258a(%edi),%eax
f01025a2:	50                   	push   %eax
f01025a3:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01025a9:	50                   	push   %eax
f01025aa:	68 5d 03 00 00       	push   $0x35d
f01025af:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01025b5:	50                   	push   %eax
f01025b6:	89 fb                	mov    %edi,%ebx
f01025b8:	e8 dc da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01025bd:	8d 87 d0 da fe ff    	lea    -0x12530(%edi),%eax
f01025c3:	50                   	push   %eax
f01025c4:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01025ca:	50                   	push   %eax
f01025cb:	68 5e 03 00 00       	push   $0x35e
f01025d0:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01025d6:	50                   	push   %eax
f01025d7:	89 fb                	mov    %edi,%ebx
f01025d9:	e8 bb da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01025de:	8d 87 90 d6 fe ff    	lea    -0x12970(%edi),%eax
f01025e4:	50                   	push   %eax
f01025e5:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01025eb:	50                   	push   %eax
f01025ec:	68 61 03 00 00       	push   $0x361
f01025f1:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01025f7:	50                   	push   %eax
f01025f8:	89 fb                	mov    %edi,%ebx
f01025fa:	e8 9a da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f01025ff:	8d 87 e1 da fe ff    	lea    -0x1251f(%edi),%eax
f0102605:	50                   	push   %eax
f0102606:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010260c:	50                   	push   %eax
f010260d:	68 62 03 00 00       	push   $0x362
f0102612:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102618:	50                   	push   %eax
f0102619:	89 fb                	mov    %edi,%ebx
f010261b:	e8 79 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f0102620:	8d 87 ed da fe ff    	lea    -0x12513(%edi),%eax
f0102626:	50                   	push   %eax
f0102627:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010262d:	50                   	push   %eax
f010262e:	68 63 03 00 00       	push   $0x363
f0102633:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102639:	50                   	push   %eax
f010263a:	89 fb                	mov    %edi,%ebx
f010263c:	e8 58 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102641:	8d 87 6c d6 fe ff    	lea    -0x12994(%edi),%eax
f0102647:	50                   	push   %eax
f0102648:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010264e:	50                   	push   %eax
f010264f:	68 67 03 00 00       	push   $0x367
f0102654:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010265a:	50                   	push   %eax
f010265b:	89 fb                	mov    %edi,%ebx
f010265d:	e8 37 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102662:	8d 87 c8 d6 fe ff    	lea    -0x12938(%edi),%eax
f0102668:	50                   	push   %eax
f0102669:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010266f:	50                   	push   %eax
f0102670:	68 68 03 00 00       	push   $0x368
f0102675:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010267b:	50                   	push   %eax
f010267c:	89 fb                	mov    %edi,%ebx
f010267e:	e8 16 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102683:	8d 87 02 db fe ff    	lea    -0x124fe(%edi),%eax
f0102689:	50                   	push   %eax
f010268a:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102690:	50                   	push   %eax
f0102691:	68 69 03 00 00       	push   $0x369
f0102696:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010269c:	50                   	push   %eax
f010269d:	89 fb                	mov    %edi,%ebx
f010269f:	e8 f5 d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01026a4:	8d 87 d0 da fe ff    	lea    -0x12530(%edi),%eax
f01026aa:	50                   	push   %eax
f01026ab:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01026b1:	50                   	push   %eax
f01026b2:	68 6a 03 00 00       	push   $0x36a
f01026b7:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01026bd:	50                   	push   %eax
f01026be:	89 fb                	mov    %edi,%ebx
f01026c0:	e8 d4 d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01026c5:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01026cb:	50                   	push   %eax
f01026cc:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01026d2:	50                   	push   %eax
f01026d3:	68 6d 03 00 00       	push   $0x36d
f01026d8:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01026de:	50                   	push   %eax
f01026df:	89 fb                	mov    %edi,%ebx
f01026e1:	e8 b3 d9 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01026e6:	8d 87 24 da fe ff    	lea    -0x125dc(%edi),%eax
f01026ec:	50                   	push   %eax
f01026ed:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01026f3:	50                   	push   %eax
f01026f4:	68 70 03 00 00       	push   $0x370
f01026f9:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01026ff:	50                   	push   %eax
f0102700:	89 fb                	mov    %edi,%ebx
f0102702:	e8 92 d9 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102707:	8d 87 94 d3 fe ff    	lea    -0x12c6c(%edi),%eax
f010270d:	50                   	push   %eax
f010270e:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102714:	50                   	push   %eax
f0102715:	68 73 03 00 00       	push   $0x373
f010271a:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102720:	50                   	push   %eax
f0102721:	89 fb                	mov    %edi,%ebx
f0102723:	e8 71 d9 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102728:	8d 87 87 da fe ff    	lea    -0x12579(%edi),%eax
f010272e:	50                   	push   %eax
f010272f:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102735:	50                   	push   %eax
f0102736:	68 75 03 00 00       	push   $0x375
f010273b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102741:	50                   	push   %eax
f0102742:	89 fb                	mov    %edi,%ebx
f0102744:	e8 50 d9 ff ff       	call   f0100099 <_panic>
f0102749:	52                   	push   %edx
f010274a:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f0102750:	50                   	push   %eax
f0102751:	68 7c 03 00 00       	push   $0x37c
f0102756:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010275c:	50                   	push   %eax
f010275d:	89 fb                	mov    %edi,%ebx
f010275f:	e8 35 d9 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102764:	8d 87 13 db fe ff    	lea    -0x124ed(%edi),%eax
f010276a:	50                   	push   %eax
f010276b:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102771:	50                   	push   %eax
f0102772:	68 7d 03 00 00       	push   $0x37d
f0102777:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f010277d:	50                   	push   %eax
f010277e:	89 fb                	mov    %edi,%ebx
f0102780:	e8 14 d9 ff ff       	call   f0100099 <_panic>
f0102785:	50                   	push   %eax
f0102786:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f010278c:	50                   	push   %eax
f010278d:	6a 59                	push   $0x59
f010278f:	8d 87 b4 d8 fe ff    	lea    -0x1274c(%edi),%eax
f0102795:	50                   	push   %eax
f0102796:	89 fb                	mov    %edi,%ebx
f0102798:	e8 fc d8 ff ff       	call   f0100099 <_panic>
f010279d:	52                   	push   %edx
f010279e:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f01027a4:	50                   	push   %eax
f01027a5:	6a 59                	push   $0x59
f01027a7:	8d 87 b4 d8 fe ff    	lea    -0x1274c(%edi),%eax
f01027ad:	50                   	push   %eax
f01027ae:	89 fb                	mov    %edi,%ebx
f01027b0:	e8 e4 d8 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01027b5:	8d 87 2b db fe ff    	lea    -0x124d5(%edi),%eax
f01027bb:	50                   	push   %eax
f01027bc:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01027c2:	50                   	push   %eax
f01027c3:	68 87 03 00 00       	push   $0x387
f01027c8:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01027ce:	50                   	push   %eax
f01027cf:	89 fb                	mov    %edi,%ebx
f01027d1:	e8 c3 d8 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027d6:	ff 75 c4             	pushl  -0x3c(%ebp)
f01027d9:	8d 87 1c d2 fe ff    	lea    -0x12de4(%edi),%eax
f01027df:	50                   	push   %eax
f01027e0:	68 c9 02 00 00       	push   $0x2c9
f01027e5:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01027eb:	50                   	push   %eax
f01027ec:	89 fb                	mov    %edi,%ebx
f01027ee:	e8 a6 d8 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f01027f3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01027f9:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01027fc:	76 3f                	jbe    f010283d <mem_init+0x1582>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027fe:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102804:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102807:	e8 ea e2 ff ff       	call   f0100af6 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010280c:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102813:	76 c1                	jbe    f01027d6 <mem_init+0x151b>
f0102815:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102818:	39 d0                	cmp    %edx,%eax
f010281a:	74 d7                	je     f01027f3 <mem_init+0x1538>
f010281c:	8d 87 14 d7 fe ff    	lea    -0x128ec(%edi),%eax
f0102822:	50                   	push   %eax
f0102823:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102829:	50                   	push   %eax
f010282a:	68 c9 02 00 00       	push   $0x2c9
f010282f:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102835:	50                   	push   %eax
f0102836:	89 fb                	mov    %edi,%ebx
f0102838:	e8 5c d8 ff ff       	call   f0100099 <_panic>
f010283d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102840:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102843:	c1 e0 0c             	shl    $0xc,%eax
f0102846:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102849:	be 00 00 00 00       	mov    $0x0,%esi
f010284e:	eb 17                	jmp    f0102867 <mem_init+0x15ac>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102850:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102856:	89 d8                	mov    %ebx,%eax
f0102858:	e8 99 e2 ff ff       	call   f0100af6 <check_va2pa>
f010285d:	39 c6                	cmp    %eax,%esi
f010285f:	75 66                	jne    f01028c7 <mem_init+0x160c>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102861:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102867:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010286a:	72 e4                	jb     f0102850 <mem_init+0x1595>
f010286c:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102871:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f0102877:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010287a:	05 00 80 00 20       	add    $0x20008000,%eax
f010287f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102882:	89 f2                	mov    %esi,%edx
f0102884:	89 d8                	mov    %ebx,%eax
f0102886:	e8 6b e2 ff ff       	call   f0100af6 <check_va2pa>
f010288b:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102892:	76 54                	jbe    f01028e8 <mem_init+0x162d>
f0102894:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102897:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f010289a:	39 c2                	cmp    %eax,%edx
f010289c:	75 6a                	jne    f0102908 <mem_init+0x164d>
f010289e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028a4:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01028aa:	75 d6                	jne    f0102882 <mem_init+0x15c7>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01028ac:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01028b1:	89 d8                	mov    %ebx,%eax
f01028b3:	e8 3e e2 ff ff       	call   f0100af6 <check_va2pa>
f01028b8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028bb:	75 6c                	jne    f0102929 <mem_init+0x166e>
	for (i = 0; i < NPDENTRIES; i++) {
f01028bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01028c2:	e9 ac 00 00 00       	jmp    f0102973 <mem_init+0x16b8>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028c7:	8d 87 48 d7 fe ff    	lea    -0x128b8(%edi),%eax
f01028cd:	50                   	push   %eax
f01028ce:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01028d4:	50                   	push   %eax
f01028d5:	68 ce 02 00 00       	push   $0x2ce
f01028da:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01028e0:	50                   	push   %eax
f01028e1:	89 fb                	mov    %edi,%ebx
f01028e3:	e8 b1 d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028e8:	ff b7 fc ff ff ff    	pushl  -0x4(%edi)
f01028ee:	8d 87 1c d2 fe ff    	lea    -0x12de4(%edi),%eax
f01028f4:	50                   	push   %eax
f01028f5:	68 d2 02 00 00       	push   $0x2d2
f01028fa:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102900:	50                   	push   %eax
f0102901:	89 fb                	mov    %edi,%ebx
f0102903:	e8 91 d7 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102908:	8d 87 70 d7 fe ff    	lea    -0x12890(%edi),%eax
f010290e:	50                   	push   %eax
f010290f:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102915:	50                   	push   %eax
f0102916:	68 d2 02 00 00       	push   $0x2d2
f010291b:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102921:	50                   	push   %eax
f0102922:	89 fb                	mov    %edi,%ebx
f0102924:	e8 70 d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102929:	8d 87 b8 d7 fe ff    	lea    -0x12848(%edi),%eax
f010292f:	50                   	push   %eax
f0102930:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102936:	50                   	push   %eax
f0102937:	68 d3 02 00 00       	push   $0x2d3
f010293c:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102942:	50                   	push   %eax
f0102943:	89 fb                	mov    %edi,%ebx
f0102945:	e8 4f d7 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f010294a:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010294e:	74 51                	je     f01029a1 <mem_init+0x16e6>
	for (i = 0; i < NPDENTRIES; i++) {
f0102950:	83 c0 01             	add    $0x1,%eax
f0102953:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102958:	0f 87 b3 00 00 00    	ja     f0102a11 <mem_init+0x1756>
		switch (i) {
f010295e:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102963:	72 0e                	jb     f0102973 <mem_init+0x16b8>
f0102965:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010296a:	76 de                	jbe    f010294a <mem_init+0x168f>
f010296c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102971:	74 d7                	je     f010294a <mem_init+0x168f>
			if (i >= PDX(KERNBASE)) {
f0102973:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102978:	77 48                	ja     f01029c2 <mem_init+0x1707>
				assert(pgdir[i] == 0);
f010297a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010297e:	74 d0                	je     f0102950 <mem_init+0x1695>
f0102980:	8d 87 7d db fe ff    	lea    -0x12483(%edi),%eax
f0102986:	50                   	push   %eax
f0102987:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f010298d:	50                   	push   %eax
f010298e:	68 e2 02 00 00       	push   $0x2e2
f0102993:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102999:	50                   	push   %eax
f010299a:	89 fb                	mov    %edi,%ebx
f010299c:	e8 f8 d6 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f01029a1:	8d 87 5b db fe ff    	lea    -0x124a5(%edi),%eax
f01029a7:	50                   	push   %eax
f01029a8:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01029ae:	50                   	push   %eax
f01029af:	68 db 02 00 00       	push   $0x2db
f01029b4:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01029ba:	50                   	push   %eax
f01029bb:	89 fb                	mov    %edi,%ebx
f01029bd:	e8 d7 d6 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f01029c2:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01029c5:	f6 c2 01             	test   $0x1,%dl
f01029c8:	74 26                	je     f01029f0 <mem_init+0x1735>
				assert(pgdir[i] & PTE_W);
f01029ca:	f6 c2 02             	test   $0x2,%dl
f01029cd:	75 81                	jne    f0102950 <mem_init+0x1695>
f01029cf:	8d 87 6c db fe ff    	lea    -0x12494(%edi),%eax
f01029d5:	50                   	push   %eax
f01029d6:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01029dc:	50                   	push   %eax
f01029dd:	68 e0 02 00 00       	push   $0x2e0
f01029e2:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f01029e8:	50                   	push   %eax
f01029e9:	89 fb                	mov    %edi,%ebx
f01029eb:	e8 a9 d6 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f01029f0:	8d 87 5b db fe ff    	lea    -0x124a5(%edi),%eax
f01029f6:	50                   	push   %eax
f01029f7:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f01029fd:	50                   	push   %eax
f01029fe:	68 df 02 00 00       	push   $0x2df
f0102a03:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102a09:	50                   	push   %eax
f0102a0a:	89 fb                	mov    %edi,%ebx
f0102a0c:	e8 88 d6 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a11:	83 ec 0c             	sub    $0xc,%esp
f0102a14:	8d 87 e8 d7 fe ff    	lea    -0x12818(%edi),%eax
f0102a1a:	50                   	push   %eax
f0102a1b:	89 fb                	mov    %edi,%ebx
f0102a1d:	e8 ce 04 00 00       	call   f0102ef0 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102a22:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102a28:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102a2a:	83 c4 10             	add    $0x10,%esp
f0102a2d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a32:	0f 86 33 02 00 00    	jbe    f0102c6b <mem_init+0x19b0>
	return (physaddr_t)kva - KERNBASE;
f0102a38:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a3d:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102a40:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a45:	e8 29 e1 ff ff       	call   f0100b73 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a4a:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a4d:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a50:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a55:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a58:	83 ec 0c             	sub    $0xc,%esp
f0102a5b:	6a 00                	push   $0x0
f0102a5d:	e8 83 e5 ff ff       	call   f0100fe5 <page_alloc>
f0102a62:	89 c6                	mov    %eax,%esi
f0102a64:	83 c4 10             	add    $0x10,%esp
f0102a67:	85 c0                	test   %eax,%eax
f0102a69:	0f 84 15 02 00 00    	je     f0102c84 <mem_init+0x19c9>
	assert((pp1 = page_alloc(0)));
f0102a6f:	83 ec 0c             	sub    $0xc,%esp
f0102a72:	6a 00                	push   $0x0
f0102a74:	e8 6c e5 ff ff       	call   f0100fe5 <page_alloc>
f0102a79:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102a7c:	83 c4 10             	add    $0x10,%esp
f0102a7f:	85 c0                	test   %eax,%eax
f0102a81:	0f 84 1c 02 00 00    	je     f0102ca3 <mem_init+0x19e8>
	assert((pp2 = page_alloc(0)));
f0102a87:	83 ec 0c             	sub    $0xc,%esp
f0102a8a:	6a 00                	push   $0x0
f0102a8c:	e8 54 e5 ff ff       	call   f0100fe5 <page_alloc>
f0102a91:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a94:	83 c4 10             	add    $0x10,%esp
f0102a97:	85 c0                	test   %eax,%eax
f0102a99:	0f 84 23 02 00 00    	je     f0102cc2 <mem_init+0x1a07>
	page_free(pp0);
f0102a9f:	83 ec 0c             	sub    $0xc,%esp
f0102aa2:	56                   	push   %esi
f0102aa3:	e8 c5 e5 ff ff       	call   f010106d <page_free>
	return (pp - pages) << PGSHIFT;
f0102aa8:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102aae:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102ab1:	2b 08                	sub    (%eax),%ecx
f0102ab3:	89 c8                	mov    %ecx,%eax
f0102ab5:	c1 f8 03             	sar    $0x3,%eax
f0102ab8:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102abb:	89 c1                	mov    %eax,%ecx
f0102abd:	c1 e9 0c             	shr    $0xc,%ecx
f0102ac0:	83 c4 10             	add    $0x10,%esp
f0102ac3:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102ac9:	3b 0a                	cmp    (%edx),%ecx
f0102acb:	0f 83 10 02 00 00    	jae    f0102ce1 <mem_init+0x1a26>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ad1:	83 ec 04             	sub    $0x4,%esp
f0102ad4:	68 00 10 00 00       	push   $0x1000
f0102ad9:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102adb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ae0:	50                   	push   %eax
f0102ae1:	e8 1b 10 00 00       	call   f0103b01 <memset>
	return (pp - pages) << PGSHIFT;
f0102ae6:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102aec:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
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
f0102b09:	0f 83 e8 01 00 00    	jae    f0102cf7 <mem_init+0x1a3c>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b0f:	83 ec 04             	sub    $0x4,%esp
f0102b12:	68 00 10 00 00       	push   $0x1000
f0102b17:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102b19:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b1e:	50                   	push   %eax
f0102b1f:	e8 dd 0f 00 00       	call   f0103b01 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b24:	6a 02                	push   $0x2
f0102b26:	68 00 10 00 00       	push   $0x1000
f0102b2b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102b2e:	53                   	push   %ebx
f0102b2f:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102b35:	ff 30                	pushl  (%eax)
f0102b37:	e8 01 e7 ff ff       	call   f010123d <page_insert>
	assert(pp1->pp_ref == 1);
f0102b3c:	83 c4 20             	add    $0x20,%esp
f0102b3f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102b44:	0f 85 c3 01 00 00    	jne    f0102d0d <mem_init+0x1a52>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b4a:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b51:	01 01 01 
f0102b54:	0f 85 d4 01 00 00    	jne    f0102d2e <mem_init+0x1a73>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b5a:	6a 02                	push   $0x2
f0102b5c:	68 00 10 00 00       	push   $0x1000
f0102b61:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102b64:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102b6a:	ff 30                	pushl  (%eax)
f0102b6c:	e8 cc e6 ff ff       	call   f010123d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b71:	83 c4 10             	add    $0x10,%esp
f0102b74:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b7b:	02 02 02 
f0102b7e:	0f 85 cb 01 00 00    	jne    f0102d4f <mem_init+0x1a94>
	assert(pp2->pp_ref == 1);
f0102b84:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b87:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102b8c:	0f 85 de 01 00 00    	jne    f0102d70 <mem_init+0x1ab5>
	assert(pp1->pp_ref == 0);
f0102b92:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b95:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102b9a:	0f 85 f1 01 00 00    	jne    f0102d91 <mem_init+0x1ad6>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ba0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102ba7:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102baa:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102bb0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102bb3:	2b 08                	sub    (%eax),%ecx
f0102bb5:	89 c8                	mov    %ecx,%eax
f0102bb7:	c1 f8 03             	sar    $0x3,%eax
f0102bba:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102bbd:	89 c1                	mov    %eax,%ecx
f0102bbf:	c1 e9 0c             	shr    $0xc,%ecx
f0102bc2:	c7 c2 a8 96 11 f0    	mov    $0xf01196a8,%edx
f0102bc8:	3b 0a                	cmp    (%edx),%ecx
f0102bca:	0f 83 e2 01 00 00    	jae    f0102db2 <mem_init+0x1af7>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bd0:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102bd7:	03 03 03 
f0102bda:	0f 85 ea 01 00 00    	jne    f0102dca <mem_init+0x1b0f>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102be0:	83 ec 08             	sub    $0x8,%esp
f0102be3:	68 00 10 00 00       	push   $0x1000
f0102be8:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102bee:	ff 30                	pushl  (%eax)
f0102bf0:	e8 0b e6 ff ff       	call   f0101200 <page_remove>
	assert(pp2->pp_ref == 0);
f0102bf5:	83 c4 10             	add    $0x10,%esp
f0102bf8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bfb:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102c00:	0f 85 e5 01 00 00    	jne    f0102deb <mem_init+0x1b30>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c06:	c7 c0 ac 96 11 f0    	mov    $0xf01196ac,%eax
f0102c0c:	8b 08                	mov    (%eax),%ecx
f0102c0e:	8b 11                	mov    (%ecx),%edx
f0102c10:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102c16:	c7 c0 b0 96 11 f0    	mov    $0xf01196b0,%eax
f0102c1c:	89 f3                	mov    %esi,%ebx
f0102c1e:	2b 18                	sub    (%eax),%ebx
f0102c20:	89 d8                	mov    %ebx,%eax
f0102c22:	c1 f8 03             	sar    $0x3,%eax
f0102c25:	c1 e0 0c             	shl    $0xc,%eax
f0102c28:	39 c2                	cmp    %eax,%edx
f0102c2a:	0f 85 dc 01 00 00    	jne    f0102e0c <mem_init+0x1b51>
	kern_pgdir[0] = 0;
f0102c30:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c36:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c3b:	0f 85 ec 01 00 00    	jne    f0102e2d <mem_init+0x1b72>
	pp0->pp_ref = 0;
f0102c41:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102c47:	83 ec 0c             	sub    $0xc,%esp
f0102c4a:	56                   	push   %esi
f0102c4b:	e8 1d e4 ff ff       	call   f010106d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c50:	8d 87 7c d8 fe ff    	lea    -0x12784(%edi),%eax
f0102c56:	89 04 24             	mov    %eax,(%esp)
f0102c59:	89 fb                	mov    %edi,%ebx
f0102c5b:	e8 90 02 00 00       	call   f0102ef0 <cprintf>
}
f0102c60:	83 c4 10             	add    $0x10,%esp
f0102c63:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c66:	5b                   	pop    %ebx
f0102c67:	5e                   	pop    %esi
f0102c68:	5f                   	pop    %edi
f0102c69:	5d                   	pop    %ebp
f0102c6a:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c6b:	50                   	push   %eax
f0102c6c:	8d 87 1c d2 fe ff    	lea    -0x12de4(%edi),%eax
f0102c72:	50                   	push   %eax
f0102c73:	68 df 00 00 00       	push   $0xdf
f0102c78:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102c7e:	50                   	push   %eax
f0102c7f:	e8 15 d4 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102c84:	8d 87 79 d9 fe ff    	lea    -0x12687(%edi),%eax
f0102c8a:	50                   	push   %eax
f0102c8b:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102c91:	50                   	push   %eax
f0102c92:	68 a2 03 00 00       	push   $0x3a2
f0102c97:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102c9d:	50                   	push   %eax
f0102c9e:	e8 f6 d3 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102ca3:	8d 87 8f d9 fe ff    	lea    -0x12671(%edi),%eax
f0102ca9:	50                   	push   %eax
f0102caa:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102cb0:	50                   	push   %eax
f0102cb1:	68 a3 03 00 00       	push   $0x3a3
f0102cb6:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102cbc:	50                   	push   %eax
f0102cbd:	e8 d7 d3 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102cc2:	8d 87 a5 d9 fe ff    	lea    -0x1265b(%edi),%eax
f0102cc8:	50                   	push   %eax
f0102cc9:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102ccf:	50                   	push   %eax
f0102cd0:	68 a4 03 00 00       	push   $0x3a4
f0102cd5:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102cdb:	50                   	push   %eax
f0102cdc:	e8 b8 d3 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ce1:	50                   	push   %eax
f0102ce2:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f0102ce8:	50                   	push   %eax
f0102ce9:	6a 59                	push   $0x59
f0102ceb:	8d 87 b4 d8 fe ff    	lea    -0x1274c(%edi),%eax
f0102cf1:	50                   	push   %eax
f0102cf2:	e8 a2 d3 ff ff       	call   f0100099 <_panic>
f0102cf7:	50                   	push   %eax
f0102cf8:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f0102cfe:	50                   	push   %eax
f0102cff:	6a 59                	push   $0x59
f0102d01:	8d 87 b4 d8 fe ff    	lea    -0x1274c(%edi),%eax
f0102d07:	50                   	push   %eax
f0102d08:	e8 8c d3 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102d0d:	8d 87 76 da fe ff    	lea    -0x1258a(%edi),%eax
f0102d13:	50                   	push   %eax
f0102d14:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102d1a:	50                   	push   %eax
f0102d1b:	68 a9 03 00 00       	push   $0x3a9
f0102d20:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102d26:	50                   	push   %eax
f0102d27:	89 fb                	mov    %edi,%ebx
f0102d29:	e8 6b d3 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d2e:	8d 87 08 d8 fe ff    	lea    -0x127f8(%edi),%eax
f0102d34:	50                   	push   %eax
f0102d35:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102d3b:	50                   	push   %eax
f0102d3c:	68 aa 03 00 00       	push   $0x3aa
f0102d41:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102d47:	50                   	push   %eax
f0102d48:	89 fb                	mov    %edi,%ebx
f0102d4a:	e8 4a d3 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d4f:	8d 87 2c d8 fe ff    	lea    -0x127d4(%edi),%eax
f0102d55:	50                   	push   %eax
f0102d56:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102d5c:	50                   	push   %eax
f0102d5d:	68 ac 03 00 00       	push   $0x3ac
f0102d62:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102d68:	50                   	push   %eax
f0102d69:	89 fb                	mov    %edi,%ebx
f0102d6b:	e8 29 d3 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102d70:	8d 87 98 da fe ff    	lea    -0x12568(%edi),%eax
f0102d76:	50                   	push   %eax
f0102d77:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102d7d:	50                   	push   %eax
f0102d7e:	68 ad 03 00 00       	push   $0x3ad
f0102d83:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102d89:	50                   	push   %eax
f0102d8a:	89 fb                	mov    %edi,%ebx
f0102d8c:	e8 08 d3 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102d91:	8d 87 02 db fe ff    	lea    -0x124fe(%edi),%eax
f0102d97:	50                   	push   %eax
f0102d98:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102d9e:	50                   	push   %eax
f0102d9f:	68 ae 03 00 00       	push   $0x3ae
f0102da4:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102daa:	50                   	push   %eax
f0102dab:	89 fb                	mov    %edi,%ebx
f0102dad:	e8 e7 d2 ff ff       	call   f0100099 <_panic>
f0102db2:	50                   	push   %eax
f0102db3:	8d 87 10 d1 fe ff    	lea    -0x12ef0(%edi),%eax
f0102db9:	50                   	push   %eax
f0102dba:	6a 59                	push   $0x59
f0102dbc:	8d 87 b4 d8 fe ff    	lea    -0x1274c(%edi),%eax
f0102dc2:	50                   	push   %eax
f0102dc3:	89 fb                	mov    %edi,%ebx
f0102dc5:	e8 cf d2 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102dca:	8d 87 50 d8 fe ff    	lea    -0x127b0(%edi),%eax
f0102dd0:	50                   	push   %eax
f0102dd1:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102dd7:	50                   	push   %eax
f0102dd8:	68 b0 03 00 00       	push   $0x3b0
f0102ddd:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102de3:	50                   	push   %eax
f0102de4:	89 fb                	mov    %edi,%ebx
f0102de6:	e8 ae d2 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102deb:	8d 87 d0 da fe ff    	lea    -0x12530(%edi),%eax
f0102df1:	50                   	push   %eax
f0102df2:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102df8:	50                   	push   %eax
f0102df9:	68 b2 03 00 00       	push   $0x3b2
f0102dfe:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102e04:	50                   	push   %eax
f0102e05:	89 fb                	mov    %edi,%ebx
f0102e07:	e8 8d d2 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e0c:	8d 87 94 d3 fe ff    	lea    -0x12c6c(%edi),%eax
f0102e12:	50                   	push   %eax
f0102e13:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102e19:	50                   	push   %eax
f0102e1a:	68 b5 03 00 00       	push   $0x3b5
f0102e1f:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102e25:	50                   	push   %eax
f0102e26:	89 fb                	mov    %edi,%ebx
f0102e28:	e8 6c d2 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102e2d:	8d 87 87 da fe ff    	lea    -0x12579(%edi),%eax
f0102e33:	50                   	push   %eax
f0102e34:	8d 87 ce d8 fe ff    	lea    -0x12732(%edi),%eax
f0102e3a:	50                   	push   %eax
f0102e3b:	68 b7 03 00 00       	push   $0x3b7
f0102e40:	8d 87 a8 d8 fe ff    	lea    -0x12758(%edi),%eax
f0102e46:	50                   	push   %eax
f0102e47:	89 fb                	mov    %edi,%ebx
f0102e49:	e8 4b d2 ff ff       	call   f0100099 <_panic>

f0102e4e <tlb_invalidate>:
{
f0102e4e:	55                   	push   %ebp
f0102e4f:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102e51:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e54:	0f 01 38             	invlpg (%eax)
}
f0102e57:	5d                   	pop    %ebp
f0102e58:	c3                   	ret    

f0102e59 <__x86.get_pc_thunk.dx>:
f0102e59:	8b 14 24             	mov    (%esp),%edx
f0102e5c:	c3                   	ret    

f0102e5d <__x86.get_pc_thunk.cx>:
f0102e5d:	8b 0c 24             	mov    (%esp),%ecx
f0102e60:	c3                   	ret    

f0102e61 <__x86.get_pc_thunk.si>:
f0102e61:	8b 34 24             	mov    (%esp),%esi
f0102e64:	c3                   	ret    

f0102e65 <__x86.get_pc_thunk.di>:
f0102e65:	8b 3c 24             	mov    (%esp),%edi
f0102e68:	c3                   	ret    

f0102e69 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e69:	55                   	push   %ebp
f0102e6a:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e6c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e6f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e74:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e75:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e7a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e7b:	0f b6 c0             	movzbl %al,%eax
}
f0102e7e:	5d                   	pop    %ebp
f0102e7f:	c3                   	ret    

f0102e80 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e80:	55                   	push   %ebp
f0102e81:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e83:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e86:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e8b:	ee                   	out    %al,(%dx)
f0102e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e8f:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e94:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e95:	5d                   	pop    %ebp
f0102e96:	c3                   	ret    

f0102e97 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e97:	55                   	push   %ebp
f0102e98:	89 e5                	mov    %esp,%ebp
f0102e9a:	53                   	push   %ebx
f0102e9b:	83 ec 10             	sub    $0x10,%esp
f0102e9e:	e8 ac d2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102ea3:	81 c3 69 44 01 00    	add    $0x14469,%ebx
	cputchar(ch);
f0102ea9:	ff 75 08             	pushl  0x8(%ebp)
f0102eac:	e8 15 d8 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0102eb1:	83 c4 10             	add    $0x10,%esp
f0102eb4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102eb7:	c9                   	leave  
f0102eb8:	c3                   	ret    

f0102eb9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102eb9:	55                   	push   %ebp
f0102eba:	89 e5                	mov    %esp,%ebp
f0102ebc:	53                   	push   %ebx
f0102ebd:	83 ec 14             	sub    $0x14,%esp
f0102ec0:	e8 8a d2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102ec5:	81 c3 47 44 01 00    	add    $0x14447,%ebx
	int cnt = 0;
f0102ecb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102ed2:	ff 75 0c             	pushl  0xc(%ebp)
f0102ed5:	ff 75 08             	pushl  0x8(%ebp)
f0102ed8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102edb:	50                   	push   %eax
f0102edc:	8d 83 8b bb fe ff    	lea    -0x14475(%ebx),%eax
f0102ee2:	50                   	push   %eax
f0102ee3:	e8 98 04 00 00       	call   f0103380 <vprintfmt>
	return cnt;
}
f0102ee8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102eeb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102eee:	c9                   	leave  
f0102eef:	c3                   	ret    

f0102ef0 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102ef0:	55                   	push   %ebp
f0102ef1:	89 e5                	mov    %esp,%ebp
f0102ef3:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102ef6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102ef9:	50                   	push   %eax
f0102efa:	ff 75 08             	pushl  0x8(%ebp)
f0102efd:	e8 b7 ff ff ff       	call   f0102eb9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f02:	c9                   	leave  
f0102f03:	c3                   	ret    

f0102f04 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102f04:	55                   	push   %ebp
f0102f05:	89 e5                	mov    %esp,%ebp
f0102f07:	57                   	push   %edi
f0102f08:	56                   	push   %esi
f0102f09:	53                   	push   %ebx
f0102f0a:	83 ec 14             	sub    $0x14,%esp
f0102f0d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f10:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102f13:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102f16:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102f19:	8b 32                	mov    (%edx),%esi
f0102f1b:	8b 01                	mov    (%ecx),%eax
f0102f1d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f20:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102f27:	eb 2f                	jmp    f0102f58 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0102f29:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0102f2c:	39 c6                	cmp    %eax,%esi
f0102f2e:	7f 49                	jg     f0102f79 <stab_binsearch+0x75>
f0102f30:	0f b6 0a             	movzbl (%edx),%ecx
f0102f33:	83 ea 0c             	sub    $0xc,%edx
f0102f36:	39 f9                	cmp    %edi,%ecx
f0102f38:	75 ef                	jne    f0102f29 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102f3a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102f3d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102f40:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102f44:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f47:	73 35                	jae    f0102f7e <stab_binsearch+0x7a>
			*region_left = m;
f0102f49:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102f4c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0102f4e:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0102f51:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0102f58:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0102f5b:	7f 4e                	jg     f0102fab <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0102f5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102f60:	01 f0                	add    %esi,%eax
f0102f62:	89 c3                	mov    %eax,%ebx
f0102f64:	c1 eb 1f             	shr    $0x1f,%ebx
f0102f67:	01 c3                	add    %eax,%ebx
f0102f69:	d1 fb                	sar    %ebx
f0102f6b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102f6e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102f71:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0102f75:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0102f77:	eb b3                	jmp    f0102f2c <stab_binsearch+0x28>
			l = true_m + 1;
f0102f79:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0102f7c:	eb da                	jmp    f0102f58 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0102f7e:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f81:	76 14                	jbe    f0102f97 <stab_binsearch+0x93>
			*region_right = m - 1;
f0102f83:	83 e8 01             	sub    $0x1,%eax
f0102f86:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f89:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102f8c:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0102f8e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102f95:	eb c1                	jmp    f0102f58 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102f97:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102f9a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102f9c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102fa0:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0102fa2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102fa9:	eb ad                	jmp    f0102f58 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0102fab:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102faf:	74 16                	je     f0102fc7 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fb1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fb4:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102fb6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102fb9:	8b 0e                	mov    (%esi),%ecx
f0102fbb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102fbe:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102fc1:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0102fc5:	eb 12                	jmp    f0102fd9 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0102fc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fca:	8b 00                	mov    (%eax),%eax
f0102fcc:	83 e8 01             	sub    $0x1,%eax
f0102fcf:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102fd2:	89 07                	mov    %eax,(%edi)
f0102fd4:	eb 16                	jmp    f0102fec <stab_binsearch+0xe8>
		     l--)
f0102fd6:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0102fd9:	39 c1                	cmp    %eax,%ecx
f0102fdb:	7d 0a                	jge    f0102fe7 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0102fdd:	0f b6 1a             	movzbl (%edx),%ebx
f0102fe0:	83 ea 0c             	sub    $0xc,%edx
f0102fe3:	39 fb                	cmp    %edi,%ebx
f0102fe5:	75 ef                	jne    f0102fd6 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0102fe7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102fea:	89 07                	mov    %eax,(%edi)
	}
}
f0102fec:	83 c4 14             	add    $0x14,%esp
f0102fef:	5b                   	pop    %ebx
f0102ff0:	5e                   	pop    %esi
f0102ff1:	5f                   	pop    %edi
f0102ff2:	5d                   	pop    %ebp
f0102ff3:	c3                   	ret    

f0102ff4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102ff4:	55                   	push   %ebp
f0102ff5:	89 e5                	mov    %esp,%ebp
f0102ff7:	57                   	push   %edi
f0102ff8:	56                   	push   %esi
f0102ff9:	53                   	push   %ebx
f0102ffa:	83 ec 3c             	sub    $0x3c,%esp
f0102ffd:	e8 4d d1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103002:	81 c3 0a 43 01 00    	add    $0x1430a,%ebx
f0103008:	8b 7d 08             	mov    0x8(%ebp),%edi
f010300b:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010300e:	8d 83 8b db fe ff    	lea    -0x12475(%ebx),%eax
f0103014:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0103016:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010301d:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103020:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103027:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010302a:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103031:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103037:	0f 86 37 01 00 00    	jbe    f0103174 <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010303d:	c7 c0 c5 b7 10 f0    	mov    $0xf010b7c5,%eax
f0103043:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f0103049:	0f 86 04 02 00 00    	jbe    f0103253 <debuginfo_eip+0x25f>
f010304f:	c7 c0 b1 d5 10 f0    	mov    $0xf010d5b1,%eax
f0103055:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103059:	0f 85 fb 01 00 00    	jne    f010325a <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010305f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103066:	c7 c0 b0 50 10 f0    	mov    $0xf01050b0,%eax
f010306c:	c7 c2 c4 b7 10 f0    	mov    $0xf010b7c4,%edx
f0103072:	29 c2                	sub    %eax,%edx
f0103074:	c1 fa 02             	sar    $0x2,%edx
f0103077:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010307d:	83 ea 01             	sub    $0x1,%edx
f0103080:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103083:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103086:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103089:	83 ec 08             	sub    $0x8,%esp
f010308c:	57                   	push   %edi
f010308d:	6a 64                	push   $0x64
f010308f:	e8 70 fe ff ff       	call   f0102f04 <stab_binsearch>
	if (lfile == 0)
f0103094:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103097:	83 c4 10             	add    $0x10,%esp
f010309a:	85 c0                	test   %eax,%eax
f010309c:	0f 84 bf 01 00 00    	je     f0103261 <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01030a2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01030a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030a8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01030ab:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01030ae:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01030b1:	83 ec 08             	sub    $0x8,%esp
f01030b4:	57                   	push   %edi
f01030b5:	6a 24                	push   $0x24
f01030b7:	c7 c0 b0 50 10 f0    	mov    $0xf01050b0,%eax
f01030bd:	e8 42 fe ff ff       	call   f0102f04 <stab_binsearch>

	if (lfun <= rfun) {
f01030c2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030c5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01030c8:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01030cb:	83 c4 10             	add    $0x10,%esp
f01030ce:	39 c8                	cmp    %ecx,%eax
f01030d0:	0f 8f b6 00 00 00    	jg     f010318c <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01030d6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01030d9:	c7 c1 b0 50 10 f0    	mov    $0xf01050b0,%ecx
f01030df:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f01030e2:	8b 11                	mov    (%ecx),%edx
f01030e4:	89 55 c0             	mov    %edx,-0x40(%ebp)
f01030e7:	c7 c2 b1 d5 10 f0    	mov    $0xf010d5b1,%edx
f01030ed:	81 ea c5 b7 10 f0    	sub    $0xf010b7c5,%edx
f01030f3:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f01030f6:	73 0c                	jae    f0103104 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01030f8:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01030fb:	81 c2 c5 b7 10 f0    	add    $0xf010b7c5,%edx
f0103101:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103104:	8b 51 08             	mov    0x8(%ecx),%edx
f0103107:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f010310a:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f010310c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010310f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103112:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103115:	83 ec 08             	sub    $0x8,%esp
f0103118:	6a 3a                	push   $0x3a
f010311a:	ff 76 08             	pushl  0x8(%esi)
f010311d:	e8 c3 09 00 00       	call   f0103ae5 <strfind>
f0103122:	2b 46 08             	sub    0x8(%esi),%eax
f0103125:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103128:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010312b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010312e:	83 c4 08             	add    $0x8,%esp
f0103131:	57                   	push   %edi
f0103132:	6a 44                	push   $0x44
f0103134:	c7 c0 b0 50 10 f0    	mov    $0xf01050b0,%eax
f010313a:	e8 c5 fd ff ff       	call   f0102f04 <stab_binsearch>
	if(lline<=rline){
f010313f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103142:	83 c4 10             	add    $0x10,%esp
f0103145:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103148:	0f 8f 1a 01 00 00    	jg     f0103268 <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f010314e:	89 d0                	mov    %edx,%eax
f0103150:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103153:	c1 e2 02             	shl    $0x2,%edx
f0103156:	c7 c1 b0 50 10 f0    	mov    $0xf01050b0,%ecx
f010315c:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0103161:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103164:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103167:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f010316b:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010316f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103172:	eb 36                	jmp    f01031aa <debuginfo_eip+0x1b6>
  	        panic("User address");
f0103174:	83 ec 04             	sub    $0x4,%esp
f0103177:	8d 83 95 db fe ff    	lea    -0x1246b(%ebx),%eax
f010317d:	50                   	push   %eax
f010317e:	6a 7f                	push   $0x7f
f0103180:	8d 83 a2 db fe ff    	lea    -0x1245e(%ebx),%eax
f0103186:	50                   	push   %eax
f0103187:	e8 0d cf ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f010318c:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010318f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103192:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103195:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103198:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010319b:	e9 75 ff ff ff       	jmp    f0103115 <debuginfo_eip+0x121>
f01031a0:	83 e8 01             	sub    $0x1,%eax
f01031a3:	83 ea 0c             	sub    $0xc,%edx
f01031a6:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01031aa:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f01031ad:	39 c7                	cmp    %eax,%edi
f01031af:	7f 24                	jg     f01031d5 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f01031b1:	0f b6 0a             	movzbl (%edx),%ecx
f01031b4:	80 f9 84             	cmp    $0x84,%cl
f01031b7:	74 46                	je     f01031ff <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01031b9:	80 f9 64             	cmp    $0x64,%cl
f01031bc:	75 e2                	jne    f01031a0 <debuginfo_eip+0x1ac>
f01031be:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f01031c2:	74 dc                	je     f01031a0 <debuginfo_eip+0x1ac>
f01031c4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01031c7:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01031cb:	74 3b                	je     f0103208 <debuginfo_eip+0x214>
f01031cd:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01031d0:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01031d3:	eb 33                	jmp    f0103208 <debuginfo_eip+0x214>
f01031d5:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01031d8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01031db:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01031de:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01031e3:	39 fa                	cmp    %edi,%edx
f01031e5:	0f 8d 89 00 00 00    	jge    f0103274 <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f01031eb:	83 c2 01             	add    $0x1,%edx
f01031ee:	89 d0                	mov    %edx,%eax
f01031f0:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f01031f3:	c7 c2 b0 50 10 f0    	mov    $0xf01050b0,%edx
f01031f9:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f01031fd:	eb 3b                	jmp    f010323a <debuginfo_eip+0x246>
f01031ff:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103202:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103206:	75 26                	jne    f010322e <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103208:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010320b:	c7 c0 b0 50 10 f0    	mov    $0xf01050b0,%eax
f0103211:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0103214:	c7 c0 b1 d5 10 f0    	mov    $0xf010d5b1,%eax
f010321a:	81 e8 c5 b7 10 f0    	sub    $0xf010b7c5,%eax
f0103220:	39 c2                	cmp    %eax,%edx
f0103222:	73 b4                	jae    f01031d8 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103224:	81 c2 c5 b7 10 f0    	add    $0xf010b7c5,%edx
f010322a:	89 16                	mov    %edx,(%esi)
f010322c:	eb aa                	jmp    f01031d8 <debuginfo_eip+0x1e4>
f010322e:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103231:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103234:	eb d2                	jmp    f0103208 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0103236:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f010323a:	39 c7                	cmp    %eax,%edi
f010323c:	7e 31                	jle    f010326f <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010323e:	0f b6 0a             	movzbl (%edx),%ecx
f0103241:	83 c0 01             	add    $0x1,%eax
f0103244:	83 c2 0c             	add    $0xc,%edx
f0103247:	80 f9 a0             	cmp    $0xa0,%cl
f010324a:	74 ea                	je     f0103236 <debuginfo_eip+0x242>
	return 0;
f010324c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103251:	eb 21                	jmp    f0103274 <debuginfo_eip+0x280>
		return -1;
f0103253:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103258:	eb 1a                	jmp    f0103274 <debuginfo_eip+0x280>
f010325a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010325f:	eb 13                	jmp    f0103274 <debuginfo_eip+0x280>
		return -1;
f0103261:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103266:	eb 0c                	jmp    f0103274 <debuginfo_eip+0x280>
		return -1;
f0103268:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010326d:	eb 05                	jmp    f0103274 <debuginfo_eip+0x280>
	return 0;
f010326f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103274:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103277:	5b                   	pop    %ebx
f0103278:	5e                   	pop    %esi
f0103279:	5f                   	pop    %edi
f010327a:	5d                   	pop    %ebp
f010327b:	c3                   	ret    

f010327c <printnum>:

// base是要打印数字的进制数，width控制填充，padc为填充字符？
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010327c:	55                   	push   %ebp
f010327d:	89 e5                	mov    %esp,%ebp
f010327f:	57                   	push   %edi
f0103280:	56                   	push   %esi
f0103281:	53                   	push   %ebx
f0103282:	83 ec 2c             	sub    $0x2c,%esp
f0103285:	e8 d3 fb ff ff       	call   f0102e5d <__x86.get_pc_thunk.cx>
f010328a:	81 c1 82 40 01 00    	add    $0x14082,%ecx
f0103290:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103293:	89 c7                	mov    %eax,%edi
f0103295:	89 d6                	mov    %edx,%esi
f0103297:	8b 45 08             	mov    0x8(%ebp),%eax
f010329a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010329d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01032a0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01032a3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01032a6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01032ab:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01032ae:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01032b1:	39 d3                	cmp    %edx,%ebx
f01032b3:	72 09                	jb     f01032be <printnum+0x42>
f01032b5:	39 45 10             	cmp    %eax,0x10(%ebp)
f01032b8:	0f 87 83 00 00 00    	ja     f0103341 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01032be:	83 ec 0c             	sub    $0xc,%esp
f01032c1:	ff 75 18             	pushl  0x18(%ebp)
f01032c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01032c7:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01032ca:	53                   	push   %ebx
f01032cb:	ff 75 10             	pushl  0x10(%ebp)
f01032ce:	83 ec 08             	sub    $0x8,%esp
f01032d1:	ff 75 dc             	pushl  -0x24(%ebp)
f01032d4:	ff 75 d8             	pushl  -0x28(%ebp)
f01032d7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01032da:	ff 75 d0             	pushl  -0x30(%ebp)
f01032dd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01032e0:	e8 1b 0a 00 00       	call   f0103d00 <__udivdi3>
f01032e5:	83 c4 18             	add    $0x18,%esp
f01032e8:	52                   	push   %edx
f01032e9:	50                   	push   %eax
f01032ea:	89 f2                	mov    %esi,%edx
f01032ec:	89 f8                	mov    %edi,%eax
f01032ee:	e8 89 ff ff ff       	call   f010327c <printnum>
f01032f3:	83 c4 20             	add    $0x20,%esp
f01032f6:	eb 13                	jmp    f010330b <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01032f8:	83 ec 08             	sub    $0x8,%esp
f01032fb:	56                   	push   %esi
f01032fc:	ff 75 18             	pushl  0x18(%ebp)
f01032ff:	ff d7                	call   *%edi
f0103301:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103304:	83 eb 01             	sub    $0x1,%ebx
f0103307:	85 db                	test   %ebx,%ebx
f0103309:	7f ed                	jg     f01032f8 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010330b:	83 ec 08             	sub    $0x8,%esp
f010330e:	56                   	push   %esi
f010330f:	83 ec 04             	sub    $0x4,%esp
f0103312:	ff 75 dc             	pushl  -0x24(%ebp)
f0103315:	ff 75 d8             	pushl  -0x28(%ebp)
f0103318:	ff 75 d4             	pushl  -0x2c(%ebp)
f010331b:	ff 75 d0             	pushl  -0x30(%ebp)
f010331e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103321:	89 f3                	mov    %esi,%ebx
f0103323:	e8 f8 0a 00 00       	call   f0103e20 <__umoddi3>
f0103328:	83 c4 14             	add    $0x14,%esp
f010332b:	0f be 84 06 b0 db fe 	movsbl -0x12450(%esi,%eax,1),%eax
f0103332:	ff 
f0103333:	50                   	push   %eax
f0103334:	ff d7                	call   *%edi
}
f0103336:	83 c4 10             	add    $0x10,%esp
f0103339:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010333c:	5b                   	pop    %ebx
f010333d:	5e                   	pop    %esi
f010333e:	5f                   	pop    %edi
f010333f:	5d                   	pop    %ebp
f0103340:	c3                   	ret    
f0103341:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103344:	eb be                	jmp    f0103304 <printnum+0x88>

f0103346 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103346:	55                   	push   %ebp
f0103347:	89 e5                	mov    %esp,%ebp
f0103349:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010334c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103350:	8b 10                	mov    (%eax),%edx
f0103352:	3b 50 04             	cmp    0x4(%eax),%edx
f0103355:	73 0a                	jae    f0103361 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103357:	8d 4a 01             	lea    0x1(%edx),%ecx
f010335a:	89 08                	mov    %ecx,(%eax)
f010335c:	8b 45 08             	mov    0x8(%ebp),%eax
f010335f:	88 02                	mov    %al,(%edx)
}
f0103361:	5d                   	pop    %ebp
f0103362:	c3                   	ret    

f0103363 <printfmt>:
{
f0103363:	55                   	push   %ebp
f0103364:	89 e5                	mov    %esp,%ebp
f0103366:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103369:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010336c:	50                   	push   %eax
f010336d:	ff 75 10             	pushl  0x10(%ebp)
f0103370:	ff 75 0c             	pushl  0xc(%ebp)
f0103373:	ff 75 08             	pushl  0x8(%ebp)
f0103376:	e8 05 00 00 00       	call   f0103380 <vprintfmt>
}
f010337b:	83 c4 10             	add    $0x10,%esp
f010337e:	c9                   	leave  
f010337f:	c3                   	ret    

f0103380 <vprintfmt>:
{
f0103380:	55                   	push   %ebp
f0103381:	89 e5                	mov    %esp,%ebp
f0103383:	57                   	push   %edi
f0103384:	56                   	push   %esi
f0103385:	53                   	push   %ebx
f0103386:	83 ec 2c             	sub    $0x2c,%esp
f0103389:	e8 c1 cd ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010338e:	81 c3 7e 3f 01 00    	add    $0x13f7e,%ebx
f0103394:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103397:	8b 7d 10             	mov    0x10(%ebp),%edi
f010339a:	e9 c3 03 00 00       	jmp    f0103762 <.L35+0x48>
		padc = ' ';
f010339f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01033a3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01033aa:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f01033b1:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01033b8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01033bd:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01033c0:	8d 47 01             	lea    0x1(%edi),%eax
f01033c3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01033c6:	0f b6 17             	movzbl (%edi),%edx
f01033c9:	8d 42 dd             	lea    -0x23(%edx),%eax
f01033cc:	3c 55                	cmp    $0x55,%al
f01033ce:	0f 87 16 04 00 00    	ja     f01037ea <.L22>
f01033d4:	0f b6 c0             	movzbl %al,%eax
f01033d7:	89 d9                	mov    %ebx,%ecx
f01033d9:	03 8c 83 3c dc fe ff 	add    -0x123c4(%ebx,%eax,4),%ecx
f01033e0:	ff e1                	jmp    *%ecx

f01033e2 <.L69>:
f01033e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01033e5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01033e9:	eb d5                	jmp    f01033c0 <vprintfmt+0x40>

f01033eb <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01033eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01033ee:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01033f2:	eb cc                	jmp    f01033c0 <vprintfmt+0x40>

f01033f4 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01033f4:	0f b6 d2             	movzbl %dl,%edx
f01033f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01033fa:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f01033ff:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103402:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103406:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103409:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010340c:	83 f9 09             	cmp    $0x9,%ecx
f010340f:	77 55                	ja     f0103466 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0103411:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103414:	eb e9                	jmp    f01033ff <.L29+0xb>

f0103416 <.L26>:
			precision = va_arg(ap, int);
f0103416:	8b 45 14             	mov    0x14(%ebp),%eax
f0103419:	8b 00                	mov    (%eax),%eax
f010341b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010341e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103421:	8d 40 04             	lea    0x4(%eax),%eax
f0103424:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103427:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f010342a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010342e:	79 90                	jns    f01033c0 <vprintfmt+0x40>
				width = precision, precision = -1;
f0103430:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103433:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103436:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f010343d:	eb 81                	jmp    f01033c0 <vprintfmt+0x40>

f010343f <.L27>:
f010343f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103442:	85 c0                	test   %eax,%eax
f0103444:	ba 00 00 00 00       	mov    $0x0,%edx
f0103449:	0f 49 d0             	cmovns %eax,%edx
f010344c:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010344f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103452:	e9 69 ff ff ff       	jmp    f01033c0 <vprintfmt+0x40>

f0103457 <.L23>:
f0103457:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010345a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103461:	e9 5a ff ff ff       	jmp    f01033c0 <vprintfmt+0x40>
f0103466:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103469:	eb bf                	jmp    f010342a <.L26+0x14>

f010346b <.L33>:
			lflag++;
f010346b:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010346f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0103472:	e9 49 ff ff ff       	jmp    f01033c0 <vprintfmt+0x40>

f0103477 <.L30>:
			putch(va_arg(ap, int), putdat);
f0103477:	8b 45 14             	mov    0x14(%ebp),%eax
f010347a:	8d 78 04             	lea    0x4(%eax),%edi
f010347d:	83 ec 08             	sub    $0x8,%esp
f0103480:	56                   	push   %esi
f0103481:	ff 30                	pushl  (%eax)
f0103483:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103486:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103489:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010348c:	e9 ce 02 00 00       	jmp    f010375f <.L35+0x45>

f0103491 <.L32>:
			err = va_arg(ap, int);
f0103491:	8b 45 14             	mov    0x14(%ebp),%eax
f0103494:	8d 78 04             	lea    0x4(%eax),%edi
f0103497:	8b 00                	mov    (%eax),%eax
f0103499:	99                   	cltd   
f010349a:	31 d0                	xor    %edx,%eax
f010349c:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010349e:	83 f8 06             	cmp    $0x6,%eax
f01034a1:	7f 27                	jg     f01034ca <.L32+0x39>
f01034a3:	8b 94 83 38 1d 00 00 	mov    0x1d38(%ebx,%eax,4),%edx
f01034aa:	85 d2                	test   %edx,%edx
f01034ac:	74 1c                	je     f01034ca <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01034ae:	52                   	push   %edx
f01034af:	8d 83 e0 d8 fe ff    	lea    -0x12720(%ebx),%eax
f01034b5:	50                   	push   %eax
f01034b6:	56                   	push   %esi
f01034b7:	ff 75 08             	pushl  0x8(%ebp)
f01034ba:	e8 a4 fe ff ff       	call   f0103363 <printfmt>
f01034bf:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01034c2:	89 7d 14             	mov    %edi,0x14(%ebp)
f01034c5:	e9 95 02 00 00       	jmp    f010375f <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01034ca:	50                   	push   %eax
f01034cb:	8d 83 c8 db fe ff    	lea    -0x12438(%ebx),%eax
f01034d1:	50                   	push   %eax
f01034d2:	56                   	push   %esi
f01034d3:	ff 75 08             	pushl  0x8(%ebp)
f01034d6:	e8 88 fe ff ff       	call   f0103363 <printfmt>
f01034db:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01034de:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01034e1:	e9 79 02 00 00       	jmp    f010375f <.L35+0x45>

f01034e6 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01034e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01034e9:	83 c0 04             	add    $0x4,%eax
f01034ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01034ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01034f4:	85 ff                	test   %edi,%edi
f01034f6:	8d 83 c1 db fe ff    	lea    -0x1243f(%ebx),%eax
f01034fc:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01034ff:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103503:	0f 8e b5 00 00 00    	jle    f01035be <.L36+0xd8>
f0103509:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010350d:	75 08                	jne    f0103517 <.L36+0x31>
f010350f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103512:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103515:	eb 6d                	jmp    f0103584 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103517:	83 ec 08             	sub    $0x8,%esp
f010351a:	ff 75 cc             	pushl  -0x34(%ebp)
f010351d:	57                   	push   %edi
f010351e:	e8 7e 04 00 00       	call   f01039a1 <strnlen>
f0103523:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103526:	29 c2                	sub    %eax,%edx
f0103528:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010352b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010352e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103532:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103535:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103538:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010353a:	eb 10                	jmp    f010354c <.L36+0x66>
					putch(padc, putdat);
f010353c:	83 ec 08             	sub    $0x8,%esp
f010353f:	56                   	push   %esi
f0103540:	ff 75 e0             	pushl  -0x20(%ebp)
f0103543:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103546:	83 ef 01             	sub    $0x1,%edi
f0103549:	83 c4 10             	add    $0x10,%esp
f010354c:	85 ff                	test   %edi,%edi
f010354e:	7f ec                	jg     f010353c <.L36+0x56>
f0103550:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103553:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103556:	85 d2                	test   %edx,%edx
f0103558:	b8 00 00 00 00       	mov    $0x0,%eax
f010355d:	0f 49 c2             	cmovns %edx,%eax
f0103560:	29 c2                	sub    %eax,%edx
f0103562:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103565:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103568:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010356b:	eb 17                	jmp    f0103584 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010356d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103571:	75 30                	jne    f01035a3 <.L36+0xbd>
					putch(ch, putdat);
f0103573:	83 ec 08             	sub    $0x8,%esp
f0103576:	ff 75 0c             	pushl  0xc(%ebp)
f0103579:	50                   	push   %eax
f010357a:	ff 55 08             	call   *0x8(%ebp)
f010357d:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103580:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0103584:	83 c7 01             	add    $0x1,%edi
f0103587:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010358b:	0f be c2             	movsbl %dl,%eax
f010358e:	85 c0                	test   %eax,%eax
f0103590:	74 52                	je     f01035e4 <.L36+0xfe>
f0103592:	85 f6                	test   %esi,%esi
f0103594:	78 d7                	js     f010356d <.L36+0x87>
f0103596:	83 ee 01             	sub    $0x1,%esi
f0103599:	79 d2                	jns    f010356d <.L36+0x87>
f010359b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010359e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01035a1:	eb 32                	jmp    f01035d5 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01035a3:	0f be d2             	movsbl %dl,%edx
f01035a6:	83 ea 20             	sub    $0x20,%edx
f01035a9:	83 fa 5e             	cmp    $0x5e,%edx
f01035ac:	76 c5                	jbe    f0103573 <.L36+0x8d>
					putch('?', putdat);
f01035ae:	83 ec 08             	sub    $0x8,%esp
f01035b1:	ff 75 0c             	pushl  0xc(%ebp)
f01035b4:	6a 3f                	push   $0x3f
f01035b6:	ff 55 08             	call   *0x8(%ebp)
f01035b9:	83 c4 10             	add    $0x10,%esp
f01035bc:	eb c2                	jmp    f0103580 <.L36+0x9a>
f01035be:	89 75 0c             	mov    %esi,0xc(%ebp)
f01035c1:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01035c4:	eb be                	jmp    f0103584 <.L36+0x9e>
				putch(' ', putdat);
f01035c6:	83 ec 08             	sub    $0x8,%esp
f01035c9:	56                   	push   %esi
f01035ca:	6a 20                	push   $0x20
f01035cc:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01035cf:	83 ef 01             	sub    $0x1,%edi
f01035d2:	83 c4 10             	add    $0x10,%esp
f01035d5:	85 ff                	test   %edi,%edi
f01035d7:	7f ed                	jg     f01035c6 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01035d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01035dc:	89 45 14             	mov    %eax,0x14(%ebp)
f01035df:	e9 7b 01 00 00       	jmp    f010375f <.L35+0x45>
f01035e4:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01035e7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01035ea:	eb e9                	jmp    f01035d5 <.L36+0xef>

f01035ec <.L31>:
f01035ec:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01035ef:	83 f9 01             	cmp    $0x1,%ecx
f01035f2:	7e 40                	jle    f0103634 <.L31+0x48>
		return va_arg(*ap, long long);
f01035f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01035f7:	8b 50 04             	mov    0x4(%eax),%edx
f01035fa:	8b 00                	mov    (%eax),%eax
f01035fc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01035ff:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103602:	8b 45 14             	mov    0x14(%ebp),%eax
f0103605:	8d 40 08             	lea    0x8(%eax),%eax
f0103608:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010360b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010360f:	79 55                	jns    f0103666 <.L31+0x7a>
				putch('-', putdat);
f0103611:	83 ec 08             	sub    $0x8,%esp
f0103614:	56                   	push   %esi
f0103615:	6a 2d                	push   $0x2d
f0103617:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010361a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010361d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103620:	f7 da                	neg    %edx
f0103622:	83 d1 00             	adc    $0x0,%ecx
f0103625:	f7 d9                	neg    %ecx
f0103627:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010362a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010362f:	e9 10 01 00 00       	jmp    f0103744 <.L35+0x2a>
	else if (lflag)
f0103634:	85 c9                	test   %ecx,%ecx
f0103636:	75 17                	jne    f010364f <.L31+0x63>
		return va_arg(*ap, int);
f0103638:	8b 45 14             	mov    0x14(%ebp),%eax
f010363b:	8b 00                	mov    (%eax),%eax
f010363d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103640:	99                   	cltd   
f0103641:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103644:	8b 45 14             	mov    0x14(%ebp),%eax
f0103647:	8d 40 04             	lea    0x4(%eax),%eax
f010364a:	89 45 14             	mov    %eax,0x14(%ebp)
f010364d:	eb bc                	jmp    f010360b <.L31+0x1f>
		return va_arg(*ap, long);
f010364f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103652:	8b 00                	mov    (%eax),%eax
f0103654:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103657:	99                   	cltd   
f0103658:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010365b:	8b 45 14             	mov    0x14(%ebp),%eax
f010365e:	8d 40 04             	lea    0x4(%eax),%eax
f0103661:	89 45 14             	mov    %eax,0x14(%ebp)
f0103664:	eb a5                	jmp    f010360b <.L31+0x1f>
			num = getint(&ap, lflag);
f0103666:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103669:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010366c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103671:	e9 ce 00 00 00       	jmp    f0103744 <.L35+0x2a>

f0103676 <.L37>:
f0103676:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103679:	83 f9 01             	cmp    $0x1,%ecx
f010367c:	7e 18                	jle    f0103696 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f010367e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103681:	8b 10                	mov    (%eax),%edx
f0103683:	8b 48 04             	mov    0x4(%eax),%ecx
f0103686:	8d 40 08             	lea    0x8(%eax),%eax
f0103689:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010368c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103691:	e9 ae 00 00 00       	jmp    f0103744 <.L35+0x2a>
	else if (lflag)
f0103696:	85 c9                	test   %ecx,%ecx
f0103698:	75 1a                	jne    f01036b4 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f010369a:	8b 45 14             	mov    0x14(%ebp),%eax
f010369d:	8b 10                	mov    (%eax),%edx
f010369f:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036a4:	8d 40 04             	lea    0x4(%eax),%eax
f01036a7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01036aa:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036af:	e9 90 00 00 00       	jmp    f0103744 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01036b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01036b7:	8b 10                	mov    (%eax),%edx
f01036b9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036be:	8d 40 04             	lea    0x4(%eax),%eax
f01036c1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01036c4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036c9:	eb 79                	jmp    f0103744 <.L35+0x2a>

f01036cb <.L34>:
f01036cb:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01036ce:	83 f9 01             	cmp    $0x1,%ecx
f01036d1:	7e 15                	jle    f01036e8 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f01036d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01036d6:	8b 10                	mov    (%eax),%edx
f01036d8:	8b 48 04             	mov    0x4(%eax),%ecx
f01036db:	8d 40 08             	lea    0x8(%eax),%eax
f01036de:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01036e1:	b8 08 00 00 00       	mov    $0x8,%eax
f01036e6:	eb 5c                	jmp    f0103744 <.L35+0x2a>
	else if (lflag)
f01036e8:	85 c9                	test   %ecx,%ecx
f01036ea:	75 17                	jne    f0103703 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f01036ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ef:	8b 10                	mov    (%eax),%edx
f01036f1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036f6:	8d 40 04             	lea    0x4(%eax),%eax
f01036f9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01036fc:	b8 08 00 00 00       	mov    $0x8,%eax
f0103701:	eb 41                	jmp    f0103744 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103703:	8b 45 14             	mov    0x14(%ebp),%eax
f0103706:	8b 10                	mov    (%eax),%edx
f0103708:	b9 00 00 00 00       	mov    $0x0,%ecx
f010370d:	8d 40 04             	lea    0x4(%eax),%eax
f0103710:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103713:	b8 08 00 00 00       	mov    $0x8,%eax
f0103718:	eb 2a                	jmp    f0103744 <.L35+0x2a>

f010371a <.L35>:
			putch('0', putdat);
f010371a:	83 ec 08             	sub    $0x8,%esp
f010371d:	56                   	push   %esi
f010371e:	6a 30                	push   $0x30
f0103720:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103723:	83 c4 08             	add    $0x8,%esp
f0103726:	56                   	push   %esi
f0103727:	6a 78                	push   $0x78
f0103729:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010372c:	8b 45 14             	mov    0x14(%ebp),%eax
f010372f:	8b 10                	mov    (%eax),%edx
f0103731:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103736:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103739:	8d 40 04             	lea    0x4(%eax),%eax
f010373c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010373f:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103744:	83 ec 0c             	sub    $0xc,%esp
f0103747:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010374b:	57                   	push   %edi
f010374c:	ff 75 e0             	pushl  -0x20(%ebp)
f010374f:	50                   	push   %eax
f0103750:	51                   	push   %ecx
f0103751:	52                   	push   %edx
f0103752:	89 f2                	mov    %esi,%edx
f0103754:	8b 45 08             	mov    0x8(%ebp),%eax
f0103757:	e8 20 fb ff ff       	call   f010327c <printnum>
			break;
f010375c:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010375f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103762:	83 c7 01             	add    $0x1,%edi
f0103765:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103769:	83 f8 25             	cmp    $0x25,%eax
f010376c:	0f 84 2d fc ff ff    	je     f010339f <vprintfmt+0x1f>
			if (ch == '\0')
f0103772:	85 c0                	test   %eax,%eax
f0103774:	0f 84 91 00 00 00    	je     f010380b <.L22+0x21>
			putch(ch, putdat);
f010377a:	83 ec 08             	sub    $0x8,%esp
f010377d:	56                   	push   %esi
f010377e:	50                   	push   %eax
f010377f:	ff 55 08             	call   *0x8(%ebp)
f0103782:	83 c4 10             	add    $0x10,%esp
f0103785:	eb db                	jmp    f0103762 <.L35+0x48>

f0103787 <.L38>:
f0103787:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010378a:	83 f9 01             	cmp    $0x1,%ecx
f010378d:	7e 15                	jle    f01037a4 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f010378f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103792:	8b 10                	mov    (%eax),%edx
f0103794:	8b 48 04             	mov    0x4(%eax),%ecx
f0103797:	8d 40 08             	lea    0x8(%eax),%eax
f010379a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010379d:	b8 10 00 00 00       	mov    $0x10,%eax
f01037a2:	eb a0                	jmp    f0103744 <.L35+0x2a>
	else if (lflag)
f01037a4:	85 c9                	test   %ecx,%ecx
f01037a6:	75 17                	jne    f01037bf <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01037a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01037ab:	8b 10                	mov    (%eax),%edx
f01037ad:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037b2:	8d 40 04             	lea    0x4(%eax),%eax
f01037b5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01037b8:	b8 10 00 00 00       	mov    $0x10,%eax
f01037bd:	eb 85                	jmp    f0103744 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01037bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01037c2:	8b 10                	mov    (%eax),%edx
f01037c4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037c9:	8d 40 04             	lea    0x4(%eax),%eax
f01037cc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01037cf:	b8 10 00 00 00       	mov    $0x10,%eax
f01037d4:	e9 6b ff ff ff       	jmp    f0103744 <.L35+0x2a>

f01037d9 <.L25>:
			putch(ch, putdat);
f01037d9:	83 ec 08             	sub    $0x8,%esp
f01037dc:	56                   	push   %esi
f01037dd:	6a 25                	push   $0x25
f01037df:	ff 55 08             	call   *0x8(%ebp)
			break;
f01037e2:	83 c4 10             	add    $0x10,%esp
f01037e5:	e9 75 ff ff ff       	jmp    f010375f <.L35+0x45>

f01037ea <.L22>:
			putch('%', putdat);
f01037ea:	83 ec 08             	sub    $0x8,%esp
f01037ed:	56                   	push   %esi
f01037ee:	6a 25                	push   $0x25
f01037f0:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01037f3:	83 c4 10             	add    $0x10,%esp
f01037f6:	89 f8                	mov    %edi,%eax
f01037f8:	eb 03                	jmp    f01037fd <.L22+0x13>
f01037fa:	83 e8 01             	sub    $0x1,%eax
f01037fd:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103801:	75 f7                	jne    f01037fa <.L22+0x10>
f0103803:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103806:	e9 54 ff ff ff       	jmp    f010375f <.L35+0x45>
}
f010380b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010380e:	5b                   	pop    %ebx
f010380f:	5e                   	pop    %esi
f0103810:	5f                   	pop    %edi
f0103811:	5d                   	pop    %ebp
f0103812:	c3                   	ret    

f0103813 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103813:	55                   	push   %ebp
f0103814:	89 e5                	mov    %esp,%ebp
f0103816:	53                   	push   %ebx
f0103817:	83 ec 14             	sub    $0x14,%esp
f010381a:	e8 30 c9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010381f:	81 c3 ed 3a 01 00    	add    $0x13aed,%ebx
f0103825:	8b 45 08             	mov    0x8(%ebp),%eax
f0103828:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010382b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010382e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103832:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103835:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010383c:	85 c0                	test   %eax,%eax
f010383e:	74 2b                	je     f010386b <vsnprintf+0x58>
f0103840:	85 d2                	test   %edx,%edx
f0103842:	7e 27                	jle    f010386b <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103844:	ff 75 14             	pushl  0x14(%ebp)
f0103847:	ff 75 10             	pushl  0x10(%ebp)
f010384a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010384d:	50                   	push   %eax
f010384e:	8d 83 3a c0 fe ff    	lea    -0x13fc6(%ebx),%eax
f0103854:	50                   	push   %eax
f0103855:	e8 26 fb ff ff       	call   f0103380 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010385a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010385d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103860:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103863:	83 c4 10             	add    $0x10,%esp
}
f0103866:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103869:	c9                   	leave  
f010386a:	c3                   	ret    
		return -E_INVAL;
f010386b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103870:	eb f4                	jmp    f0103866 <vsnprintf+0x53>

f0103872 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103872:	55                   	push   %ebp
f0103873:	89 e5                	mov    %esp,%ebp
f0103875:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103878:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010387b:	50                   	push   %eax
f010387c:	ff 75 10             	pushl  0x10(%ebp)
f010387f:	ff 75 0c             	pushl  0xc(%ebp)
f0103882:	ff 75 08             	pushl  0x8(%ebp)
f0103885:	e8 89 ff ff ff       	call   f0103813 <vsnprintf>
	va_end(ap);

	return rc;
}
f010388a:	c9                   	leave  
f010388b:	c3                   	ret    

f010388c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010388c:	55                   	push   %ebp
f010388d:	89 e5                	mov    %esp,%ebp
f010388f:	57                   	push   %edi
f0103890:	56                   	push   %esi
f0103891:	53                   	push   %ebx
f0103892:	83 ec 1c             	sub    $0x1c,%esp
f0103895:	e8 b5 c8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010389a:	81 c3 72 3a 01 00    	add    $0x13a72,%ebx
f01038a0:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01038a3:	85 c0                	test   %eax,%eax
f01038a5:	74 13                	je     f01038ba <readline+0x2e>
		cprintf("%s", prompt);
f01038a7:	83 ec 08             	sub    $0x8,%esp
f01038aa:	50                   	push   %eax
f01038ab:	8d 83 e0 d8 fe ff    	lea    -0x12720(%ebx),%eax
f01038b1:	50                   	push   %eax
f01038b2:	e8 39 f6 ff ff       	call   f0102ef0 <cprintf>
f01038b7:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01038ba:	83 ec 0c             	sub    $0xc,%esp
f01038bd:	6a 00                	push   $0x0
f01038bf:	e8 23 ce ff ff       	call   f01006e7 <iscons>
f01038c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01038c7:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01038ca:	bf 00 00 00 00       	mov    $0x0,%edi
f01038cf:	eb 46                	jmp    f0103917 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01038d1:	83 ec 08             	sub    $0x8,%esp
f01038d4:	50                   	push   %eax
f01038d5:	8d 83 94 dd fe ff    	lea    -0x1226c(%ebx),%eax
f01038db:	50                   	push   %eax
f01038dc:	e8 0f f6 ff ff       	call   f0102ef0 <cprintf>
			return NULL;
f01038e1:	83 c4 10             	add    $0x10,%esp
f01038e4:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01038e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01038ec:	5b                   	pop    %ebx
f01038ed:	5e                   	pop    %esi
f01038ee:	5f                   	pop    %edi
f01038ef:	5d                   	pop    %ebp
f01038f0:	c3                   	ret    
			if (echoing)
f01038f1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01038f5:	75 05                	jne    f01038fc <readline+0x70>
			i--;
f01038f7:	83 ef 01             	sub    $0x1,%edi
f01038fa:	eb 1b                	jmp    f0103917 <readline+0x8b>
				cputchar('\b');
f01038fc:	83 ec 0c             	sub    $0xc,%esp
f01038ff:	6a 08                	push   $0x8
f0103901:	e8 c0 cd ff ff       	call   f01006c6 <cputchar>
f0103906:	83 c4 10             	add    $0x10,%esp
f0103909:	eb ec                	jmp    f01038f7 <readline+0x6b>
			buf[i++] = c;
f010390b:	89 f0                	mov    %esi,%eax
f010390d:	88 84 3b 94 1f 00 00 	mov    %al,0x1f94(%ebx,%edi,1)
f0103914:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103917:	e8 ba cd ff ff       	call   f01006d6 <getchar>
f010391c:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010391e:	85 c0                	test   %eax,%eax
f0103920:	78 af                	js     f01038d1 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103922:	83 f8 08             	cmp    $0x8,%eax
f0103925:	0f 94 c2             	sete   %dl
f0103928:	83 f8 7f             	cmp    $0x7f,%eax
f010392b:	0f 94 c0             	sete   %al
f010392e:	08 c2                	or     %al,%dl
f0103930:	74 04                	je     f0103936 <readline+0xaa>
f0103932:	85 ff                	test   %edi,%edi
f0103934:	7f bb                	jg     f01038f1 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103936:	83 fe 1f             	cmp    $0x1f,%esi
f0103939:	7e 1c                	jle    f0103957 <readline+0xcb>
f010393b:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103941:	7f 14                	jg     f0103957 <readline+0xcb>
			if (echoing)
f0103943:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103947:	74 c2                	je     f010390b <readline+0x7f>
				cputchar(c);
f0103949:	83 ec 0c             	sub    $0xc,%esp
f010394c:	56                   	push   %esi
f010394d:	e8 74 cd ff ff       	call   f01006c6 <cputchar>
f0103952:	83 c4 10             	add    $0x10,%esp
f0103955:	eb b4                	jmp    f010390b <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103957:	83 fe 0a             	cmp    $0xa,%esi
f010395a:	74 05                	je     f0103961 <readline+0xd5>
f010395c:	83 fe 0d             	cmp    $0xd,%esi
f010395f:	75 b6                	jne    f0103917 <readline+0x8b>
			if (echoing)
f0103961:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103965:	75 13                	jne    f010397a <readline+0xee>
			buf[i] = 0;
f0103967:	c6 84 3b 94 1f 00 00 	movb   $0x0,0x1f94(%ebx,%edi,1)
f010396e:	00 
			return buf;
f010396f:	8d 83 94 1f 00 00    	lea    0x1f94(%ebx),%eax
f0103975:	e9 6f ff ff ff       	jmp    f01038e9 <readline+0x5d>
				cputchar('\n');
f010397a:	83 ec 0c             	sub    $0xc,%esp
f010397d:	6a 0a                	push   $0xa
f010397f:	e8 42 cd ff ff       	call   f01006c6 <cputchar>
f0103984:	83 c4 10             	add    $0x10,%esp
f0103987:	eb de                	jmp    f0103967 <readline+0xdb>

f0103989 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103989:	55                   	push   %ebp
f010398a:	89 e5                	mov    %esp,%ebp
f010398c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010398f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103994:	eb 03                	jmp    f0103999 <strlen+0x10>
		n++;
f0103996:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103999:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010399d:	75 f7                	jne    f0103996 <strlen+0xd>
	return n;
}
f010399f:	5d                   	pop    %ebp
f01039a0:	c3                   	ret    

f01039a1 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01039a1:	55                   	push   %ebp
f01039a2:	89 e5                	mov    %esp,%ebp
f01039a4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01039a7:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01039af:	eb 03                	jmp    f01039b4 <strnlen+0x13>
		n++;
f01039b1:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039b4:	39 d0                	cmp    %edx,%eax
f01039b6:	74 06                	je     f01039be <strnlen+0x1d>
f01039b8:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01039bc:	75 f3                	jne    f01039b1 <strnlen+0x10>
	return n;
}
f01039be:	5d                   	pop    %ebp
f01039bf:	c3                   	ret    

f01039c0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01039c0:	55                   	push   %ebp
f01039c1:	89 e5                	mov    %esp,%ebp
f01039c3:	53                   	push   %ebx
f01039c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01039ca:	89 c2                	mov    %eax,%edx
f01039cc:	83 c1 01             	add    $0x1,%ecx
f01039cf:	83 c2 01             	add    $0x1,%edx
f01039d2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01039d6:	88 5a ff             	mov    %bl,-0x1(%edx)
f01039d9:	84 db                	test   %bl,%bl
f01039db:	75 ef                	jne    f01039cc <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01039dd:	5b                   	pop    %ebx
f01039de:	5d                   	pop    %ebp
f01039df:	c3                   	ret    

f01039e0 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01039e0:	55                   	push   %ebp
f01039e1:	89 e5                	mov    %esp,%ebp
f01039e3:	53                   	push   %ebx
f01039e4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01039e7:	53                   	push   %ebx
f01039e8:	e8 9c ff ff ff       	call   f0103989 <strlen>
f01039ed:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01039f0:	ff 75 0c             	pushl  0xc(%ebp)
f01039f3:	01 d8                	add    %ebx,%eax
f01039f5:	50                   	push   %eax
f01039f6:	e8 c5 ff ff ff       	call   f01039c0 <strcpy>
	return dst;
}
f01039fb:	89 d8                	mov    %ebx,%eax
f01039fd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a00:	c9                   	leave  
f0103a01:	c3                   	ret    

f0103a02 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a02:	55                   	push   %ebp
f0103a03:	89 e5                	mov    %esp,%ebp
f0103a05:	56                   	push   %esi
f0103a06:	53                   	push   %ebx
f0103a07:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a0a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a0d:	89 f3                	mov    %esi,%ebx
f0103a0f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a12:	89 f2                	mov    %esi,%edx
f0103a14:	eb 0f                	jmp    f0103a25 <strncpy+0x23>
		*dst++ = *src;
f0103a16:	83 c2 01             	add    $0x1,%edx
f0103a19:	0f b6 01             	movzbl (%ecx),%eax
f0103a1c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103a1f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103a22:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103a25:	39 da                	cmp    %ebx,%edx
f0103a27:	75 ed                	jne    f0103a16 <strncpy+0x14>
	}
	return ret;
}
f0103a29:	89 f0                	mov    %esi,%eax
f0103a2b:	5b                   	pop    %ebx
f0103a2c:	5e                   	pop    %esi
f0103a2d:	5d                   	pop    %ebp
f0103a2e:	c3                   	ret    

f0103a2f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103a2f:	55                   	push   %ebp
f0103a30:	89 e5                	mov    %esp,%ebp
f0103a32:	56                   	push   %esi
f0103a33:	53                   	push   %ebx
f0103a34:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a37:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a3a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103a3d:	89 f0                	mov    %esi,%eax
f0103a3f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103a43:	85 c9                	test   %ecx,%ecx
f0103a45:	75 0b                	jne    f0103a52 <strlcpy+0x23>
f0103a47:	eb 17                	jmp    f0103a60 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103a49:	83 c2 01             	add    $0x1,%edx
f0103a4c:	83 c0 01             	add    $0x1,%eax
f0103a4f:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103a52:	39 d8                	cmp    %ebx,%eax
f0103a54:	74 07                	je     f0103a5d <strlcpy+0x2e>
f0103a56:	0f b6 0a             	movzbl (%edx),%ecx
f0103a59:	84 c9                	test   %cl,%cl
f0103a5b:	75 ec                	jne    f0103a49 <strlcpy+0x1a>
		*dst = '\0';
f0103a5d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103a60:	29 f0                	sub    %esi,%eax
}
f0103a62:	5b                   	pop    %ebx
f0103a63:	5e                   	pop    %esi
f0103a64:	5d                   	pop    %ebp
f0103a65:	c3                   	ret    

f0103a66 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103a66:	55                   	push   %ebp
f0103a67:	89 e5                	mov    %esp,%ebp
f0103a69:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a6c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103a6f:	eb 06                	jmp    f0103a77 <strcmp+0x11>
		p++, q++;
f0103a71:	83 c1 01             	add    $0x1,%ecx
f0103a74:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103a77:	0f b6 01             	movzbl (%ecx),%eax
f0103a7a:	84 c0                	test   %al,%al
f0103a7c:	74 04                	je     f0103a82 <strcmp+0x1c>
f0103a7e:	3a 02                	cmp    (%edx),%al
f0103a80:	74 ef                	je     f0103a71 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103a82:	0f b6 c0             	movzbl %al,%eax
f0103a85:	0f b6 12             	movzbl (%edx),%edx
f0103a88:	29 d0                	sub    %edx,%eax
}
f0103a8a:	5d                   	pop    %ebp
f0103a8b:	c3                   	ret    

f0103a8c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103a8c:	55                   	push   %ebp
f0103a8d:	89 e5                	mov    %esp,%ebp
f0103a8f:	53                   	push   %ebx
f0103a90:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a93:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a96:	89 c3                	mov    %eax,%ebx
f0103a98:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103a9b:	eb 06                	jmp    f0103aa3 <strncmp+0x17>
		n--, p++, q++;
f0103a9d:	83 c0 01             	add    $0x1,%eax
f0103aa0:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103aa3:	39 d8                	cmp    %ebx,%eax
f0103aa5:	74 16                	je     f0103abd <strncmp+0x31>
f0103aa7:	0f b6 08             	movzbl (%eax),%ecx
f0103aaa:	84 c9                	test   %cl,%cl
f0103aac:	74 04                	je     f0103ab2 <strncmp+0x26>
f0103aae:	3a 0a                	cmp    (%edx),%cl
f0103ab0:	74 eb                	je     f0103a9d <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103ab2:	0f b6 00             	movzbl (%eax),%eax
f0103ab5:	0f b6 12             	movzbl (%edx),%edx
f0103ab8:	29 d0                	sub    %edx,%eax
}
f0103aba:	5b                   	pop    %ebx
f0103abb:	5d                   	pop    %ebp
f0103abc:	c3                   	ret    
		return 0;
f0103abd:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ac2:	eb f6                	jmp    f0103aba <strncmp+0x2e>

f0103ac4 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103ac4:	55                   	push   %ebp
f0103ac5:	89 e5                	mov    %esp,%ebp
f0103ac7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aca:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ace:	0f b6 10             	movzbl (%eax),%edx
f0103ad1:	84 d2                	test   %dl,%dl
f0103ad3:	74 09                	je     f0103ade <strchr+0x1a>
		if (*s == c)
f0103ad5:	38 ca                	cmp    %cl,%dl
f0103ad7:	74 0a                	je     f0103ae3 <strchr+0x1f>
	for (; *s; s++)
f0103ad9:	83 c0 01             	add    $0x1,%eax
f0103adc:	eb f0                	jmp    f0103ace <strchr+0xa>
			return (char *) s;
	return 0;
f0103ade:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ae3:	5d                   	pop    %ebp
f0103ae4:	c3                   	ret    

f0103ae5 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103ae5:	55                   	push   %ebp
f0103ae6:	89 e5                	mov    %esp,%ebp
f0103ae8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aeb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103aef:	eb 03                	jmp    f0103af4 <strfind+0xf>
f0103af1:	83 c0 01             	add    $0x1,%eax
f0103af4:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103af7:	38 ca                	cmp    %cl,%dl
f0103af9:	74 04                	je     f0103aff <strfind+0x1a>
f0103afb:	84 d2                	test   %dl,%dl
f0103afd:	75 f2                	jne    f0103af1 <strfind+0xc>
			break;
	return (char *) s;
}
f0103aff:	5d                   	pop    %ebp
f0103b00:	c3                   	ret    

f0103b01 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103b01:	55                   	push   %ebp
f0103b02:	89 e5                	mov    %esp,%ebp
f0103b04:	57                   	push   %edi
f0103b05:	56                   	push   %esi
f0103b06:	53                   	push   %ebx
f0103b07:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103b0a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103b0d:	85 c9                	test   %ecx,%ecx
f0103b0f:	74 13                	je     f0103b24 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103b11:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103b17:	75 05                	jne    f0103b1e <memset+0x1d>
f0103b19:	f6 c1 03             	test   $0x3,%cl
f0103b1c:	74 0d                	je     f0103b2b <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103b1e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b21:	fc                   	cld    
f0103b22:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103b24:	89 f8                	mov    %edi,%eax
f0103b26:	5b                   	pop    %ebx
f0103b27:	5e                   	pop    %esi
f0103b28:	5f                   	pop    %edi
f0103b29:	5d                   	pop    %ebp
f0103b2a:	c3                   	ret    
		c &= 0xFF;
f0103b2b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103b2f:	89 d3                	mov    %edx,%ebx
f0103b31:	c1 e3 08             	shl    $0x8,%ebx
f0103b34:	89 d0                	mov    %edx,%eax
f0103b36:	c1 e0 18             	shl    $0x18,%eax
f0103b39:	89 d6                	mov    %edx,%esi
f0103b3b:	c1 e6 10             	shl    $0x10,%esi
f0103b3e:	09 f0                	or     %esi,%eax
f0103b40:	09 c2                	or     %eax,%edx
f0103b42:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103b44:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103b47:	89 d0                	mov    %edx,%eax
f0103b49:	fc                   	cld    
f0103b4a:	f3 ab                	rep stos %eax,%es:(%edi)
f0103b4c:	eb d6                	jmp    f0103b24 <memset+0x23>

f0103b4e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103b4e:	55                   	push   %ebp
f0103b4f:	89 e5                	mov    %esp,%ebp
f0103b51:	57                   	push   %edi
f0103b52:	56                   	push   %esi
f0103b53:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b56:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b59:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103b5c:	39 c6                	cmp    %eax,%esi
f0103b5e:	73 35                	jae    f0103b95 <memmove+0x47>
f0103b60:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103b63:	39 c2                	cmp    %eax,%edx
f0103b65:	76 2e                	jbe    f0103b95 <memmove+0x47>
		s += n;
		d += n;
f0103b67:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103b6a:	89 d6                	mov    %edx,%esi
f0103b6c:	09 fe                	or     %edi,%esi
f0103b6e:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103b74:	74 0c                	je     f0103b82 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103b76:	83 ef 01             	sub    $0x1,%edi
f0103b79:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103b7c:	fd                   	std    
f0103b7d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103b7f:	fc                   	cld    
f0103b80:	eb 21                	jmp    f0103ba3 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103b82:	f6 c1 03             	test   $0x3,%cl
f0103b85:	75 ef                	jne    f0103b76 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103b87:	83 ef 04             	sub    $0x4,%edi
f0103b8a:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103b8d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103b90:	fd                   	std    
f0103b91:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103b93:	eb ea                	jmp    f0103b7f <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103b95:	89 f2                	mov    %esi,%edx
f0103b97:	09 c2                	or     %eax,%edx
f0103b99:	f6 c2 03             	test   $0x3,%dl
f0103b9c:	74 09                	je     f0103ba7 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103b9e:	89 c7                	mov    %eax,%edi
f0103ba0:	fc                   	cld    
f0103ba1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103ba3:	5e                   	pop    %esi
f0103ba4:	5f                   	pop    %edi
f0103ba5:	5d                   	pop    %ebp
f0103ba6:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ba7:	f6 c1 03             	test   $0x3,%cl
f0103baa:	75 f2                	jne    f0103b9e <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103bac:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103baf:	89 c7                	mov    %eax,%edi
f0103bb1:	fc                   	cld    
f0103bb2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103bb4:	eb ed                	jmp    f0103ba3 <memmove+0x55>

f0103bb6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103bb6:	55                   	push   %ebp
f0103bb7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103bb9:	ff 75 10             	pushl  0x10(%ebp)
f0103bbc:	ff 75 0c             	pushl  0xc(%ebp)
f0103bbf:	ff 75 08             	pushl  0x8(%ebp)
f0103bc2:	e8 87 ff ff ff       	call   f0103b4e <memmove>
}
f0103bc7:	c9                   	leave  
f0103bc8:	c3                   	ret    

f0103bc9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103bc9:	55                   	push   %ebp
f0103bca:	89 e5                	mov    %esp,%ebp
f0103bcc:	56                   	push   %esi
f0103bcd:	53                   	push   %ebx
f0103bce:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bd1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103bd4:	89 c6                	mov    %eax,%esi
f0103bd6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103bd9:	39 f0                	cmp    %esi,%eax
f0103bdb:	74 1c                	je     f0103bf9 <memcmp+0x30>
		if (*s1 != *s2)
f0103bdd:	0f b6 08             	movzbl (%eax),%ecx
f0103be0:	0f b6 1a             	movzbl (%edx),%ebx
f0103be3:	38 d9                	cmp    %bl,%cl
f0103be5:	75 08                	jne    f0103bef <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103be7:	83 c0 01             	add    $0x1,%eax
f0103bea:	83 c2 01             	add    $0x1,%edx
f0103bed:	eb ea                	jmp    f0103bd9 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103bef:	0f b6 c1             	movzbl %cl,%eax
f0103bf2:	0f b6 db             	movzbl %bl,%ebx
f0103bf5:	29 d8                	sub    %ebx,%eax
f0103bf7:	eb 05                	jmp    f0103bfe <memcmp+0x35>
	}

	return 0;
f0103bf9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103bfe:	5b                   	pop    %ebx
f0103bff:	5e                   	pop    %esi
f0103c00:	5d                   	pop    %ebp
f0103c01:	c3                   	ret    

f0103c02 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103c02:	55                   	push   %ebp
f0103c03:	89 e5                	mov    %esp,%ebp
f0103c05:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c08:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103c0b:	89 c2                	mov    %eax,%edx
f0103c0d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103c10:	39 d0                	cmp    %edx,%eax
f0103c12:	73 09                	jae    f0103c1d <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103c14:	38 08                	cmp    %cl,(%eax)
f0103c16:	74 05                	je     f0103c1d <memfind+0x1b>
	for (; s < ends; s++)
f0103c18:	83 c0 01             	add    $0x1,%eax
f0103c1b:	eb f3                	jmp    f0103c10 <memfind+0xe>
			break;
	return (void *) s;
}
f0103c1d:	5d                   	pop    %ebp
f0103c1e:	c3                   	ret    

f0103c1f <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103c1f:	55                   	push   %ebp
f0103c20:	89 e5                	mov    %esp,%ebp
f0103c22:	57                   	push   %edi
f0103c23:	56                   	push   %esi
f0103c24:	53                   	push   %ebx
f0103c25:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c28:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103c2b:	eb 03                	jmp    f0103c30 <strtol+0x11>
		s++;
f0103c2d:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103c30:	0f b6 01             	movzbl (%ecx),%eax
f0103c33:	3c 20                	cmp    $0x20,%al
f0103c35:	74 f6                	je     f0103c2d <strtol+0xe>
f0103c37:	3c 09                	cmp    $0x9,%al
f0103c39:	74 f2                	je     f0103c2d <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103c3b:	3c 2b                	cmp    $0x2b,%al
f0103c3d:	74 2e                	je     f0103c6d <strtol+0x4e>
	int neg = 0;
f0103c3f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103c44:	3c 2d                	cmp    $0x2d,%al
f0103c46:	74 2f                	je     f0103c77 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103c48:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103c4e:	75 05                	jne    f0103c55 <strtol+0x36>
f0103c50:	80 39 30             	cmpb   $0x30,(%ecx)
f0103c53:	74 2c                	je     f0103c81 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103c55:	85 db                	test   %ebx,%ebx
f0103c57:	75 0a                	jne    f0103c63 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103c59:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103c5e:	80 39 30             	cmpb   $0x30,(%ecx)
f0103c61:	74 28                	je     f0103c8b <strtol+0x6c>
		base = 10;
f0103c63:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c68:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103c6b:	eb 50                	jmp    f0103cbd <strtol+0x9e>
		s++;
f0103c6d:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103c70:	bf 00 00 00 00       	mov    $0x0,%edi
f0103c75:	eb d1                	jmp    f0103c48 <strtol+0x29>
		s++, neg = 1;
f0103c77:	83 c1 01             	add    $0x1,%ecx
f0103c7a:	bf 01 00 00 00       	mov    $0x1,%edi
f0103c7f:	eb c7                	jmp    f0103c48 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103c81:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103c85:	74 0e                	je     f0103c95 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103c87:	85 db                	test   %ebx,%ebx
f0103c89:	75 d8                	jne    f0103c63 <strtol+0x44>
		s++, base = 8;
f0103c8b:	83 c1 01             	add    $0x1,%ecx
f0103c8e:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103c93:	eb ce                	jmp    f0103c63 <strtol+0x44>
		s += 2, base = 16;
f0103c95:	83 c1 02             	add    $0x2,%ecx
f0103c98:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103c9d:	eb c4                	jmp    f0103c63 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103c9f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103ca2:	89 f3                	mov    %esi,%ebx
f0103ca4:	80 fb 19             	cmp    $0x19,%bl
f0103ca7:	77 29                	ja     f0103cd2 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103ca9:	0f be d2             	movsbl %dl,%edx
f0103cac:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103caf:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103cb2:	7d 30                	jge    f0103ce4 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103cb4:	83 c1 01             	add    $0x1,%ecx
f0103cb7:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103cbb:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103cbd:	0f b6 11             	movzbl (%ecx),%edx
f0103cc0:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103cc3:	89 f3                	mov    %esi,%ebx
f0103cc5:	80 fb 09             	cmp    $0x9,%bl
f0103cc8:	77 d5                	ja     f0103c9f <strtol+0x80>
			dig = *s - '0';
f0103cca:	0f be d2             	movsbl %dl,%edx
f0103ccd:	83 ea 30             	sub    $0x30,%edx
f0103cd0:	eb dd                	jmp    f0103caf <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103cd2:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103cd5:	89 f3                	mov    %esi,%ebx
f0103cd7:	80 fb 19             	cmp    $0x19,%bl
f0103cda:	77 08                	ja     f0103ce4 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103cdc:	0f be d2             	movsbl %dl,%edx
f0103cdf:	83 ea 37             	sub    $0x37,%edx
f0103ce2:	eb cb                	jmp    f0103caf <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103ce4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103ce8:	74 05                	je     f0103cef <strtol+0xd0>
		*endptr = (char *) s;
f0103cea:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ced:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103cef:	89 c2                	mov    %eax,%edx
f0103cf1:	f7 da                	neg    %edx
f0103cf3:	85 ff                	test   %edi,%edi
f0103cf5:	0f 45 c2             	cmovne %edx,%eax
}
f0103cf8:	5b                   	pop    %ebx
f0103cf9:	5e                   	pop    %esi
f0103cfa:	5f                   	pop    %edi
f0103cfb:	5d                   	pop    %ebp
f0103cfc:	c3                   	ret    
f0103cfd:	66 90                	xchg   %ax,%ax
f0103cff:	90                   	nop

f0103d00 <__udivdi3>:
f0103d00:	55                   	push   %ebp
f0103d01:	57                   	push   %edi
f0103d02:	56                   	push   %esi
f0103d03:	53                   	push   %ebx
f0103d04:	83 ec 1c             	sub    $0x1c,%esp
f0103d07:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103d0b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103d0f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103d13:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103d17:	85 d2                	test   %edx,%edx
f0103d19:	75 35                	jne    f0103d50 <__udivdi3+0x50>
f0103d1b:	39 f3                	cmp    %esi,%ebx
f0103d1d:	0f 87 bd 00 00 00    	ja     f0103de0 <__udivdi3+0xe0>
f0103d23:	85 db                	test   %ebx,%ebx
f0103d25:	89 d9                	mov    %ebx,%ecx
f0103d27:	75 0b                	jne    f0103d34 <__udivdi3+0x34>
f0103d29:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d2e:	31 d2                	xor    %edx,%edx
f0103d30:	f7 f3                	div    %ebx
f0103d32:	89 c1                	mov    %eax,%ecx
f0103d34:	31 d2                	xor    %edx,%edx
f0103d36:	89 f0                	mov    %esi,%eax
f0103d38:	f7 f1                	div    %ecx
f0103d3a:	89 c6                	mov    %eax,%esi
f0103d3c:	89 e8                	mov    %ebp,%eax
f0103d3e:	89 f7                	mov    %esi,%edi
f0103d40:	f7 f1                	div    %ecx
f0103d42:	89 fa                	mov    %edi,%edx
f0103d44:	83 c4 1c             	add    $0x1c,%esp
f0103d47:	5b                   	pop    %ebx
f0103d48:	5e                   	pop    %esi
f0103d49:	5f                   	pop    %edi
f0103d4a:	5d                   	pop    %ebp
f0103d4b:	c3                   	ret    
f0103d4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d50:	39 f2                	cmp    %esi,%edx
f0103d52:	77 7c                	ja     f0103dd0 <__udivdi3+0xd0>
f0103d54:	0f bd fa             	bsr    %edx,%edi
f0103d57:	83 f7 1f             	xor    $0x1f,%edi
f0103d5a:	0f 84 98 00 00 00    	je     f0103df8 <__udivdi3+0xf8>
f0103d60:	89 f9                	mov    %edi,%ecx
f0103d62:	b8 20 00 00 00       	mov    $0x20,%eax
f0103d67:	29 f8                	sub    %edi,%eax
f0103d69:	d3 e2                	shl    %cl,%edx
f0103d6b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103d6f:	89 c1                	mov    %eax,%ecx
f0103d71:	89 da                	mov    %ebx,%edx
f0103d73:	d3 ea                	shr    %cl,%edx
f0103d75:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103d79:	09 d1                	or     %edx,%ecx
f0103d7b:	89 f2                	mov    %esi,%edx
f0103d7d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103d81:	89 f9                	mov    %edi,%ecx
f0103d83:	d3 e3                	shl    %cl,%ebx
f0103d85:	89 c1                	mov    %eax,%ecx
f0103d87:	d3 ea                	shr    %cl,%edx
f0103d89:	89 f9                	mov    %edi,%ecx
f0103d8b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103d8f:	d3 e6                	shl    %cl,%esi
f0103d91:	89 eb                	mov    %ebp,%ebx
f0103d93:	89 c1                	mov    %eax,%ecx
f0103d95:	d3 eb                	shr    %cl,%ebx
f0103d97:	09 de                	or     %ebx,%esi
f0103d99:	89 f0                	mov    %esi,%eax
f0103d9b:	f7 74 24 08          	divl   0x8(%esp)
f0103d9f:	89 d6                	mov    %edx,%esi
f0103da1:	89 c3                	mov    %eax,%ebx
f0103da3:	f7 64 24 0c          	mull   0xc(%esp)
f0103da7:	39 d6                	cmp    %edx,%esi
f0103da9:	72 0c                	jb     f0103db7 <__udivdi3+0xb7>
f0103dab:	89 f9                	mov    %edi,%ecx
f0103dad:	d3 e5                	shl    %cl,%ebp
f0103daf:	39 c5                	cmp    %eax,%ebp
f0103db1:	73 5d                	jae    f0103e10 <__udivdi3+0x110>
f0103db3:	39 d6                	cmp    %edx,%esi
f0103db5:	75 59                	jne    f0103e10 <__udivdi3+0x110>
f0103db7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103dba:	31 ff                	xor    %edi,%edi
f0103dbc:	89 fa                	mov    %edi,%edx
f0103dbe:	83 c4 1c             	add    $0x1c,%esp
f0103dc1:	5b                   	pop    %ebx
f0103dc2:	5e                   	pop    %esi
f0103dc3:	5f                   	pop    %edi
f0103dc4:	5d                   	pop    %ebp
f0103dc5:	c3                   	ret    
f0103dc6:	8d 76 00             	lea    0x0(%esi),%esi
f0103dc9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103dd0:	31 ff                	xor    %edi,%edi
f0103dd2:	31 c0                	xor    %eax,%eax
f0103dd4:	89 fa                	mov    %edi,%edx
f0103dd6:	83 c4 1c             	add    $0x1c,%esp
f0103dd9:	5b                   	pop    %ebx
f0103dda:	5e                   	pop    %esi
f0103ddb:	5f                   	pop    %edi
f0103ddc:	5d                   	pop    %ebp
f0103ddd:	c3                   	ret    
f0103dde:	66 90                	xchg   %ax,%ax
f0103de0:	31 ff                	xor    %edi,%edi
f0103de2:	89 e8                	mov    %ebp,%eax
f0103de4:	89 f2                	mov    %esi,%edx
f0103de6:	f7 f3                	div    %ebx
f0103de8:	89 fa                	mov    %edi,%edx
f0103dea:	83 c4 1c             	add    $0x1c,%esp
f0103ded:	5b                   	pop    %ebx
f0103dee:	5e                   	pop    %esi
f0103def:	5f                   	pop    %edi
f0103df0:	5d                   	pop    %ebp
f0103df1:	c3                   	ret    
f0103df2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103df8:	39 f2                	cmp    %esi,%edx
f0103dfa:	72 06                	jb     f0103e02 <__udivdi3+0x102>
f0103dfc:	31 c0                	xor    %eax,%eax
f0103dfe:	39 eb                	cmp    %ebp,%ebx
f0103e00:	77 d2                	ja     f0103dd4 <__udivdi3+0xd4>
f0103e02:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e07:	eb cb                	jmp    f0103dd4 <__udivdi3+0xd4>
f0103e09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e10:	89 d8                	mov    %ebx,%eax
f0103e12:	31 ff                	xor    %edi,%edi
f0103e14:	eb be                	jmp    f0103dd4 <__udivdi3+0xd4>
f0103e16:	66 90                	xchg   %ax,%ax
f0103e18:	66 90                	xchg   %ax,%ax
f0103e1a:	66 90                	xchg   %ax,%ax
f0103e1c:	66 90                	xchg   %ax,%ax
f0103e1e:	66 90                	xchg   %ax,%ax

f0103e20 <__umoddi3>:
f0103e20:	55                   	push   %ebp
f0103e21:	57                   	push   %edi
f0103e22:	56                   	push   %esi
f0103e23:	53                   	push   %ebx
f0103e24:	83 ec 1c             	sub    $0x1c,%esp
f0103e27:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103e2b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103e2f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103e33:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103e37:	85 ed                	test   %ebp,%ebp
f0103e39:	89 f0                	mov    %esi,%eax
f0103e3b:	89 da                	mov    %ebx,%edx
f0103e3d:	75 19                	jne    f0103e58 <__umoddi3+0x38>
f0103e3f:	39 df                	cmp    %ebx,%edi
f0103e41:	0f 86 b1 00 00 00    	jbe    f0103ef8 <__umoddi3+0xd8>
f0103e47:	f7 f7                	div    %edi
f0103e49:	89 d0                	mov    %edx,%eax
f0103e4b:	31 d2                	xor    %edx,%edx
f0103e4d:	83 c4 1c             	add    $0x1c,%esp
f0103e50:	5b                   	pop    %ebx
f0103e51:	5e                   	pop    %esi
f0103e52:	5f                   	pop    %edi
f0103e53:	5d                   	pop    %ebp
f0103e54:	c3                   	ret    
f0103e55:	8d 76 00             	lea    0x0(%esi),%esi
f0103e58:	39 dd                	cmp    %ebx,%ebp
f0103e5a:	77 f1                	ja     f0103e4d <__umoddi3+0x2d>
f0103e5c:	0f bd cd             	bsr    %ebp,%ecx
f0103e5f:	83 f1 1f             	xor    $0x1f,%ecx
f0103e62:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103e66:	0f 84 b4 00 00 00    	je     f0103f20 <__umoddi3+0x100>
f0103e6c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103e71:	89 c2                	mov    %eax,%edx
f0103e73:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103e77:	29 c2                	sub    %eax,%edx
f0103e79:	89 c1                	mov    %eax,%ecx
f0103e7b:	89 f8                	mov    %edi,%eax
f0103e7d:	d3 e5                	shl    %cl,%ebp
f0103e7f:	89 d1                	mov    %edx,%ecx
f0103e81:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103e85:	d3 e8                	shr    %cl,%eax
f0103e87:	09 c5                	or     %eax,%ebp
f0103e89:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103e8d:	89 c1                	mov    %eax,%ecx
f0103e8f:	d3 e7                	shl    %cl,%edi
f0103e91:	89 d1                	mov    %edx,%ecx
f0103e93:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103e97:	89 df                	mov    %ebx,%edi
f0103e99:	d3 ef                	shr    %cl,%edi
f0103e9b:	89 c1                	mov    %eax,%ecx
f0103e9d:	89 f0                	mov    %esi,%eax
f0103e9f:	d3 e3                	shl    %cl,%ebx
f0103ea1:	89 d1                	mov    %edx,%ecx
f0103ea3:	89 fa                	mov    %edi,%edx
f0103ea5:	d3 e8                	shr    %cl,%eax
f0103ea7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103eac:	09 d8                	or     %ebx,%eax
f0103eae:	f7 f5                	div    %ebp
f0103eb0:	d3 e6                	shl    %cl,%esi
f0103eb2:	89 d1                	mov    %edx,%ecx
f0103eb4:	f7 64 24 08          	mull   0x8(%esp)
f0103eb8:	39 d1                	cmp    %edx,%ecx
f0103eba:	89 c3                	mov    %eax,%ebx
f0103ebc:	89 d7                	mov    %edx,%edi
f0103ebe:	72 06                	jb     f0103ec6 <__umoddi3+0xa6>
f0103ec0:	75 0e                	jne    f0103ed0 <__umoddi3+0xb0>
f0103ec2:	39 c6                	cmp    %eax,%esi
f0103ec4:	73 0a                	jae    f0103ed0 <__umoddi3+0xb0>
f0103ec6:	2b 44 24 08          	sub    0x8(%esp),%eax
f0103eca:	19 ea                	sbb    %ebp,%edx
f0103ecc:	89 d7                	mov    %edx,%edi
f0103ece:	89 c3                	mov    %eax,%ebx
f0103ed0:	89 ca                	mov    %ecx,%edx
f0103ed2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103ed7:	29 de                	sub    %ebx,%esi
f0103ed9:	19 fa                	sbb    %edi,%edx
f0103edb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0103edf:	89 d0                	mov    %edx,%eax
f0103ee1:	d3 e0                	shl    %cl,%eax
f0103ee3:	89 d9                	mov    %ebx,%ecx
f0103ee5:	d3 ee                	shr    %cl,%esi
f0103ee7:	d3 ea                	shr    %cl,%edx
f0103ee9:	09 f0                	or     %esi,%eax
f0103eeb:	83 c4 1c             	add    $0x1c,%esp
f0103eee:	5b                   	pop    %ebx
f0103eef:	5e                   	pop    %esi
f0103ef0:	5f                   	pop    %edi
f0103ef1:	5d                   	pop    %ebp
f0103ef2:	c3                   	ret    
f0103ef3:	90                   	nop
f0103ef4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ef8:	85 ff                	test   %edi,%edi
f0103efa:	89 f9                	mov    %edi,%ecx
f0103efc:	75 0b                	jne    f0103f09 <__umoddi3+0xe9>
f0103efe:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f03:	31 d2                	xor    %edx,%edx
f0103f05:	f7 f7                	div    %edi
f0103f07:	89 c1                	mov    %eax,%ecx
f0103f09:	89 d8                	mov    %ebx,%eax
f0103f0b:	31 d2                	xor    %edx,%edx
f0103f0d:	f7 f1                	div    %ecx
f0103f0f:	89 f0                	mov    %esi,%eax
f0103f11:	f7 f1                	div    %ecx
f0103f13:	e9 31 ff ff ff       	jmp    f0103e49 <__umoddi3+0x29>
f0103f18:	90                   	nop
f0103f19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f20:	39 dd                	cmp    %ebx,%ebp
f0103f22:	72 08                	jb     f0103f2c <__umoddi3+0x10c>
f0103f24:	39 f7                	cmp    %esi,%edi
f0103f26:	0f 87 21 ff ff ff    	ja     f0103e4d <__umoddi3+0x2d>
f0103f2c:	89 da                	mov    %ebx,%edx
f0103f2e:	89 f0                	mov    %esi,%eax
f0103f30:	29 f8                	sub    %edi,%eax
f0103f32:	19 ea                	sbb    %ebp,%edx
f0103f34:	e9 14 ff ff ff       	jmp    f0103e4d <__umoddi3+0x2d>
