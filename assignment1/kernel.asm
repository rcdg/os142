
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 47 34 10 80       	mov    $0x80103447,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 e0 81 10 	movl   $0x801081e0,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 74 4b 00 00       	call   80104bc2 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 db 10 80 84 	movl   $0x8010db84,0x8010db90
80100055:	db 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 db 10 80 84 	movl   $0x8010db84,0x8010db94
8010005f:	db 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 db 10 80       	mov    0x8010db94,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 db 10 80       	mov    %eax,0x8010db94

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate fresh block.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 21 4b 00 00       	call   80104be3 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 db 10 80       	mov    0x8010db94,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	89 c2                	mov    %eax,%edx
801000f5:	83 ca 01             	or     $0x1,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 3c 4b 00 00       	call   80104c45 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 e1 47 00 00       	call   80104905 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 db 10 80       	mov    0x8010db90,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 c4 4a 00 00       	call   80104c45 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 e7 81 10 80 	movl   $0x801081e7,(%esp)
8010019f:	e8 99 03 00 00       	call   8010053d <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 1c 26 00 00       	call   801027f4 <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 f8 81 10 80 	movl   $0x801081f8,(%esp)
801001f6:	e8 42 03 00 00       	call   8010053d <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	89 c2                	mov    %eax,%edx
80100202:	83 ca 04             	or     $0x4,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 df 25 00 00       	call   801027f4 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 ff 81 10 80 	movl   $0x801081ff,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 a2 49 00 00       	call   80104be3 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 db 10 80       	mov    0x8010db94,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 db 10 80       	mov    %eax,0x8010db94

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	89 c2                	mov    %eax,%edx
8010028f:	83 e2 fe             	and    $0xfffffffe,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 3c 47 00 00       	call   801049de <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 97 49 00 00       	call   80104c45 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	53                   	push   %ebx
801002b4:	83 ec 14             	sub    $0x14,%esp
801002b7:	8b 45 08             	mov    0x8(%ebp),%eax
801002ba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801002c2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801002c6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801002ca:	ec                   	in     (%dx),%al
801002cb:	89 c3                	mov    %eax,%ebx
801002cd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801002d0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801002d4:	83 c4 14             	add    $0x14,%esp
801002d7:	5b                   	pop    %ebx
801002d8:	5d                   	pop    %ebp
801002d9:	c3                   	ret    

801002da <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 08             	sub    $0x8,%esp
801002e0:	8b 55 08             	mov    0x8(%ebp),%edx
801002e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801002e6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002ea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002ed:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002f1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002f5:	ee                   	out    %al,(%dx)
}
801002f6:	c9                   	leave  
801002f7:	c3                   	ret    

801002f8 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002f8:	55                   	push   %ebp
801002f9:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002fb:	fa                   	cli    
}
801002fc:	5d                   	pop    %ebp
801002fd:	c3                   	ret    

801002fe <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002fe:	55                   	push   %ebp
801002ff:	89 e5                	mov    %esp,%ebp
80100301:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100304:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100308:	74 19                	je     80100323 <printint+0x25>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	89 45 10             	mov    %eax,0x10(%ebp)
80100313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100317:	74 0a                	je     80100323 <printint+0x25>
    x = -xx;
80100319:	8b 45 08             	mov    0x8(%ebp),%eax
8010031c:	f7 d8                	neg    %eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100321:	eb 06                	jmp    80100329 <printint+0x2b>
  else
    x = xx;
80100323:	8b 45 08             	mov    0x8(%ebp),%eax
80100326:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100329:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100330:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100336:	ba 00 00 00 00       	mov    $0x0,%edx
8010033b:	f7 f1                	div    %ecx
8010033d:	89 d0                	mov    %edx,%eax
8010033f:	0f b6 90 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%edx
80100346:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100349:	03 45 f4             	add    -0xc(%ebp),%eax
8010034c:	88 10                	mov    %dl,(%eax)
8010034e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100352:	8b 55 0c             	mov    0xc(%ebp),%edx
80100355:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80100358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035b:	ba 00 00 00 00       	mov    $0x0,%edx
80100360:	f7 75 d4             	divl   -0x2c(%ebp)
80100363:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036a:	75 c4                	jne    80100330 <printint+0x32>

  if(sign)
8010036c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100370:	74 23                	je     80100395 <printint+0x97>
    buf[i++] = '-';
80100372:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100375:	03 45 f4             	add    -0xc(%ebp),%eax
80100378:	c6 00 2d             	movb   $0x2d,(%eax)
8010037b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
8010037f:	eb 14                	jmp    80100395 <printint+0x97>
    consputc(buf[i]);
80100381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100384:	03 45 f4             	add    -0xc(%ebp),%eax
80100387:	0f b6 00             	movzbl (%eax),%eax
8010038a:	0f be c0             	movsbl %al,%eax
8010038d:	89 04 24             	mov    %eax,(%esp)
80100390:	e8 bb 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
80100395:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010039d:	79 e2                	jns    80100381 <printint+0x83>
    consputc(buf[i]);
}
8010039f:	c9                   	leave  
801003a0:	c3                   	ret    

801003a1 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a1:	55                   	push   %ebp
801003a2:	89 e5                	mov    %esp,%ebp
801003a4:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a7:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bc:	e8 22 48 00 00       	call   80104be3 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 06 82 10 80 	movl   $0x80108206,(%esp)
801003cf:	e8 69 01 00 00       	call   8010053d <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d4:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e1:	e9 20 01 00 00       	jmp    80100506 <cprintf+0x165>
    if(c != '%'){
801003e6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003ea:	74 10                	je     801003fc <cprintf+0x5b>
      consputc(c);
801003ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ef:	89 04 24             	mov    %eax,(%esp)
801003f2:	e8 59 03 00 00       	call   80100750 <consputc>
      continue;
801003f7:	e9 06 01 00 00       	jmp    80100502 <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100406:	01 d0                	add    %edx,%eax
80100408:	0f b6 00             	movzbl (%eax),%eax
8010040b:	0f be c0             	movsbl %al,%eax
8010040e:	25 ff 00 00 00       	and    $0xff,%eax
80100413:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100416:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010041a:	0f 84 08 01 00 00    	je     80100528 <cprintf+0x187>
      break;
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4d                	je     80100475 <cprintf+0xd4>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0x9f>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13b>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xae>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x149>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 53                	je     80100498 <cprintf+0xf7>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2b                	je     80100475 <cprintf+0xd4>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8b 00                	mov    (%eax),%eax
80100454:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100458:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010045f:	00 
80100460:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100467:	00 
80100468:	89 04 24             	mov    %eax,(%esp)
8010046b:	e8 8e fe ff ff       	call   801002fe <printint>
      break;
80100470:	e9 8d 00 00 00       	jmp    80100502 <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100475:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100478:	8b 00                	mov    (%eax),%eax
8010047a:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
8010047e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100485:	00 
80100486:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010048d:	00 
8010048e:	89 04 24             	mov    %eax,(%esp)
80100491:	e8 68 fe ff ff       	call   801002fe <printint>
      break;
80100496:	eb 6a                	jmp    80100502 <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
80100498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049b:	8b 00                	mov    (%eax),%eax
8010049d:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004a4:	0f 94 c0             	sete   %al
801004a7:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004ab:	84 c0                	test   %al,%al
801004ad:	74 20                	je     801004cf <cprintf+0x12e>
        s = "(null)";
801004af:	c7 45 ec 0f 82 10 80 	movl   $0x8010820f,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 87 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004c9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004cd:	eb 01                	jmp    801004d0 <cprintf+0x12f>
801004cf:	90                   	nop
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 de                	jne    801004b8 <cprintf+0x117>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x161>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 c0 fe ff ff    	jne    801003e6 <cprintf+0x45>
80100526:	eb 01                	jmp    80100529 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100528:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100529:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052d:	74 0c                	je     8010053b <cprintf+0x19a>
    release(&cons.lock);
8010052f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100536:	e8 0a 47 00 00       	call   80104c45 <release>
}
8010053b:	c9                   	leave  
8010053c:	c3                   	ret    

8010053d <panic>:

void
panic(char *s)
{
8010053d:	55                   	push   %ebp
8010053e:	89 e5                	mov    %esp,%ebp
80100540:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100543:	e8 b0 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100548:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 16 82 10 80 	movl   $0x80108216,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 25 82 10 80 	movl   $0x80108225,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 fd 46 00 00       	call   80104c94 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 27 82 10 80 	movl   $0x80108227,(%esp)
801005b2:	e8 ea fd ff ff       	call   801003a1 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005bb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bf:	7e df                	jle    801005a0 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005c1:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c8:	00 00 00 
  for(;;)
    ;
801005cb:	eb fe                	jmp    801005cb <panic+0x8e>

801005cd <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005cd:	55                   	push   %ebp
801005ce:	89 e5                	mov    %esp,%ebp
801005d0:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d3:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005da:	00 
801005db:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005e2:	e8 f3 fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005e7:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005ee:	e8 bd fc ff ff       	call   801002b0 <inb>
801005f3:	0f b6 c0             	movzbl %al,%eax
801005f6:	c1 e0 08             	shl    $0x8,%eax
801005f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005fc:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100603:	00 
80100604:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010060b:	e8 ca fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100610:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100617:	e8 94 fc ff ff       	call   801002b0 <inb>
8010061c:	0f b6 c0             	movzbl %al,%eax
8010061f:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100622:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100626:	75 30                	jne    80100658 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100628:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010062b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100630:	89 c8                	mov    %ecx,%eax
80100632:	f7 ea                	imul   %edx
80100634:	c1 fa 05             	sar    $0x5,%edx
80100637:	89 c8                	mov    %ecx,%eax
80100639:	c1 f8 1f             	sar    $0x1f,%eax
8010063c:	29 c2                	sub    %eax,%edx
8010063e:	89 d0                	mov    %edx,%eax
80100640:	c1 e0 02             	shl    $0x2,%eax
80100643:	01 d0                	add    %edx,%eax
80100645:	c1 e0 04             	shl    $0x4,%eax
80100648:	89 ca                	mov    %ecx,%edx
8010064a:	29 c2                	sub    %eax,%edx
8010064c:	b8 50 00 00 00       	mov    $0x50,%eax
80100651:	29 d0                	sub    %edx,%eax
80100653:	01 45 f4             	add    %eax,-0xc(%ebp)
80100656:	eb 32                	jmp    8010068a <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	75 0c                	jne    8010066d <cgaputc+0xa0>
    if(pos > 0) --pos;
80100661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100665:	7e 23                	jle    8010068a <cgaputc+0xbd>
80100667:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
8010066b:	eb 1d                	jmp    8010068a <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100675:	01 d2                	add    %edx,%edx
80100677:	01 c2                	add    %eax,%edx
80100679:	8b 45 08             	mov    0x8(%ebp),%eax
8010067c:	66 25 ff 00          	and    $0xff,%ax
80100680:	80 cc 07             	or     $0x7,%ah
80100683:	66 89 02             	mov    %ax,(%edx)
80100686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x119>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 4e 48 00 00       	call   80104f05 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 4c 47 00 00       	call   80104e32 <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 e0 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 c7 fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 b3 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 9d fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 94 fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 ca 60 00 00       	call   80106845 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 be 60 00 00       	call   80106845 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 b2 60 00 00       	call   80106845 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 a5 60 00 00       	call   80106845 <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 22 fe ff ff       	call   801005cd <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
801007ba:	e8 24 44 00 00       	call   80104be3 <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 41 01 00 00       	jmp    80100905 <consoleintr+0x158>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 68                	je     8010083e <consoleintr+0x91>
801007d6:	e9 94 00 00 00       	jmp    8010086f <consoleintr+0xc2>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 59                	je     8010083e <consoleintr+0x91>
801007e5:	e9 85 00 00 00       	jmp    8010086f <consoleintr+0xc2>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 92 42 00 00       	call   80104a81 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100816:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 d4 dd 10 80 	movzbl -0x7fef222c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100835:	3c 0a                	cmp    $0xa,%al
80100837:	75 bb                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100839:	e9 c0 00 00 00       	jmp    801008fe <consoleintr+0x151>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083e:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100844:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
8010085e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100865:	e8 e6 fe ff ff       	call   80100750 <consputc>
      }
      break;
8010086a:	e9 92 00 00 00       	jmp    80100901 <consoleintr+0x154>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100873:	0f 84 8b 00 00 00    	je     80100904 <consoleintr+0x157>
80100879:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
8010087f:	a1 54 de 10 80       	mov    0x8010de54,%eax
80100884:	89 d1                	mov    %edx,%ecx
80100886:	29 c1                	sub    %eax,%ecx
80100888:	89 c8                	mov    %ecx,%eax
8010088a:	83 f8 7f             	cmp    $0x7f,%eax
8010088d:	77 75                	ja     80100904 <consoleintr+0x157>
        c = (c == '\r') ? '\n' : c;
8010088f:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
80100893:	74 05                	je     8010089a <consoleintr+0xed>
80100895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100898:	eb 05                	jmp    8010089f <consoleintr+0xf2>
8010089a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008a2:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 d4 dd 10 80    	mov    %dl,-0x7fef222c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008d9:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008eb:	a3 58 de 10 80       	mov    %eax,0x8010de58
          wakeup(&input.r);
801008f0:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
801008f7:	e8 e2 40 00 00       	call   801049de <wakeup>
        }
      }
      break;
801008fc:	eb 06                	jmp    80100904 <consoleintr+0x157>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008fe:	90                   	nop
801008ff:	eb 04                	jmp    80100905 <consoleintr+0x158>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100901:	90                   	nop
80100902:	eb 01                	jmp    80100905 <consoleintr+0x158>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
80100904:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
80100905:	8b 45 08             	mov    0x8(%ebp),%eax
80100908:	ff d0                	call   *%eax
8010090a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010090d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100911:	0f 89 ad fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100917:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
8010091e:	e8 22 43 00 00       	call   80104c45 <release>
}
80100923:	c9                   	leave  
80100924:	c3                   	ret    

80100925 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100925:	55                   	push   %ebp
80100926:	89 e5                	mov    %esp,%ebp
80100928:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
8010092b:	8b 45 08             	mov    0x8(%ebp),%eax
8010092e:	89 04 24             	mov    %eax,(%esp)
80100931:	e8 c0 10 00 00       	call   801019f6 <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100943:	e8 9b 42 00 00       	call   80104be3 <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100961:	e8 df 42 00 00       	call   80104c45 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 37 0f 00 00       	call   801018a8 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
8010098a:	e8 76 3f 00 00       	call   80104905 <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
80100998:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 d4 dd 10 80 	movzbl -0x7fef222c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 54 de 10 80       	mov    %eax,0x8010de54
    if(c == C('D')){  // EOF
801009c0:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009c4:	75 17                	jne    801009dd <consoleread+0xb8>
      if(n < target){
801009c6:	8b 45 10             	mov    0x10(%ebp),%eax
801009c9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009cc:	73 2f                	jae    801009fd <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009ce:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 54 de 10 80       	mov    %eax,0x8010de54
      }
      break;
801009db:	eb 20                	jmp    801009fd <consoleread+0xd8>
    }
    *dst++ = c;
801009dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801009e0:	89 c2                	mov    %eax,%edx
801009e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801009e5:	88 10                	mov    %dl,(%eax)
801009e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
801009eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009ef:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009f3:	74 0b                	je     80100a00 <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f9:	7f 96                	jg     80100991 <consoleread+0x6c>
801009fb:	eb 04                	jmp    80100a01 <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
801009fd:	90                   	nop
801009fe:	eb 01                	jmp    80100a01 <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a00:	90                   	nop
  }
  release(&input.lock);
80100a01:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100a08:	e8 38 42 00 00       	call   80104c45 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 90 0e 00 00       	call   801018a8 <ilock>

  return target - n;
80100a18:	8b 45 10             	mov    0x10(%ebp),%eax
80100a1b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a1e:	89 d1                	mov    %edx,%ecx
80100a20:	29 c1                	sub    %eax,%ecx
80100a22:	89 c8                	mov    %ecx,%eax
}
80100a24:	c9                   	leave  
80100a25:	c3                   	ret    

80100a26 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a26:	55                   	push   %ebp
80100a27:	89 e5                	mov    %esp,%ebp
80100a29:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a2c:	8b 45 08             	mov    0x8(%ebp),%eax
80100a2f:	89 04 24             	mov    %eax,(%esp)
80100a32:	e8 bf 0f 00 00       	call   801019f6 <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a3e:	e8 a0 41 00 00       	call   80104be3 <acquire>
  for(i = 0; i < n; i++)
80100a43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a4a:	eb 1d                	jmp    80100a69 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a4f:	03 45 0c             	add    0xc(%ebp),%eax
80100a52:	0f b6 00             	movzbl (%eax),%eax
80100a55:	0f be c0             	movsbl %al,%eax
80100a58:	25 ff 00 00 00       	and    $0xff,%eax
80100a5d:	89 04 24             	mov    %eax,(%esp)
80100a60:	e8 eb fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a65:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a6c:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a6f:	7c db                	jl     80100a4c <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a71:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a78:	e8 c8 41 00 00       	call   80104c45 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 20 0e 00 00       	call   801018a8 <ilock>

  return n;
80100a88:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a8b:	c9                   	leave  
80100a8c:	c3                   	ret    

80100a8d <consoleinit>:

void
consoleinit(void)
{
80100a8d:	55                   	push   %ebp
80100a8e:	89 e5                	mov    %esp,%ebp
80100a90:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a93:	c7 44 24 04 2b 82 10 	movl   $0x8010822b,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aa2:	e8 1b 41 00 00       	call   80104bc2 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 33 82 10 	movl   $0x80108233,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100ab6:	e8 07 41 00 00       	call   80104bc2 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 2c ed 10 80 26 	movl   $0x80100a26,0x8010ed2c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 28 ed 10 80 25 	movl   $0x80100925,0x8010ed28
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 1c 30 00 00       	call   80103b01 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 bd 1e 00 00       	call   801029b6 <ioapicenable>
}
80100af9:	c9                   	leave  
80100afa:	c3                   	ret    
	...

80100afc <exec>:
#include "defs.h"
char path_set[10][128];
int path_num;
int
exec(char *path, char **argv)
{
80100afc:	55                   	push   %ebp
80100afd:	89 e5                	mov    %esp,%ebp
80100aff:	81 ec 38 01 00 00    	sub    $0x138,%esp
  char *s, *last;
  int i, off,j = 0;
80100b05:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  path_num = 1;
80100b0c:	c7 05 60 de 10 80 01 	movl   $0x1,0x8010de60
80100b13:	00 00 00 
  if((ip = namei(path)) == 0){
80100b16:	8b 45 08             	mov    0x8(%ebp),%eax
80100b19:	89 04 24             	mov    %eax,(%esp)
80100b1c:	e8 29 19 00 00       	call   8010244a <namei>
80100b21:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b24:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b28:	75 38                	jne    80100b62 <exec+0x66>
    while(j < path_num && ( (ip = namei(path) ) == 0) ) 
80100b2a:	eb 04                	jmp    80100b30 <exec+0x34>
    j++; 
80100b2c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  path_num = 1;
  if((ip = namei(path)) == 0){
    while(j < path_num && ( (ip = namei(path) ) == 0) ) 
80100b30:	a1 60 de 10 80       	mov    0x8010de60,%eax
80100b35:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
80100b38:	7d 14                	jge    80100b4e <exec+0x52>
80100b3a:	8b 45 08             	mov    0x8(%ebp),%eax
80100b3d:	89 04 24             	mov    %eax,(%esp)
80100b40:	e8 05 19 00 00       	call   8010244a <namei>
80100b45:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b48:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b4c:	74 de                	je     80100b2c <exec+0x30>
    j++; 
    if(j>path_num)
80100b4e:	a1 60 de 10 80       	mov    0x8010de60,%eax
80100b53:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
80100b56:	7e 0a                	jle    80100b62 <exec+0x66>
      return -1;
80100b58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b5d:	e9 da 03 00 00       	jmp    80100f3c <exec+0x440>
    }
  ilock(ip);
80100b62:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100b65:	89 04 24             	mov    %eax,(%esp)
80100b68:	e8 3b 0d 00 00       	call   801018a8 <ilock>
  pgdir = 0;
80100b6d:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b74:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b7b:	00 
80100b7c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b83:	00 
80100b84:	8d 85 08 ff ff ff    	lea    -0xf8(%ebp),%eax
80100b8a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b8e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100b91:	89 04 24             	mov    %eax,(%esp)
80100b94:	e8 05 12 00 00       	call   80101d9e <readi>
80100b99:	83 f8 33             	cmp    $0x33,%eax
80100b9c:	0f 86 54 03 00 00    	jbe    80100ef6 <exec+0x3fa>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100ba2:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100ba8:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100bad:	0f 85 46 03 00 00    	jne    80100ef9 <exec+0x3fd>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100bb3:	c7 04 24 3f 2b 10 80 	movl   $0x80102b3f,(%esp)
80100bba:	e8 ca 6d 00 00       	call   80107989 <setupkvm>
80100bbf:	89 45 d0             	mov    %eax,-0x30(%ebp)
80100bc2:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80100bc6:	0f 84 30 03 00 00    	je     80100efc <exec+0x400>
    goto bad;

  // Load program into memory.
  sz = 0;
80100bcc:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100bd3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100bda:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100be0:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100be3:	e9 c5 00 00 00       	jmp    80100cad <exec+0x1b1>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100be8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100beb:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bf2:	00 
80100bf3:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bf7:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100bfd:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c04:	89 04 24             	mov    %eax,(%esp)
80100c07:	e8 92 11 00 00       	call   80101d9e <readi>
80100c0c:	83 f8 20             	cmp    $0x20,%eax
80100c0f:	0f 85 ea 02 00 00    	jne    80100eff <exec+0x403>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100c15:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100c1b:	83 f8 01             	cmp    $0x1,%eax
80100c1e:	75 7f                	jne    80100c9f <exec+0x1a3>
      continue;
    if(ph.memsz < ph.filesz)
80100c20:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100c26:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100c2c:	39 c2                	cmp    %eax,%edx
80100c2e:	0f 82 ce 02 00 00    	jb     80100f02 <exec+0x406>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100c34:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c3a:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100c40:	01 d0                	add    %edx,%eax
80100c42:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c46:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100c49:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c4d:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100c50:	89 04 24             	mov    %eax,(%esp)
80100c53:	e8 03 71 00 00       	call   80107d5b <allocuvm>
80100c58:	89 45 dc             	mov    %eax,-0x24(%ebp)
80100c5b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80100c5f:	0f 84 a0 02 00 00    	je     80100f05 <exec+0x409>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c65:	8b 8d f8 fe ff ff    	mov    -0x108(%ebp),%ecx
80100c6b:	8b 95 ec fe ff ff    	mov    -0x114(%ebp),%edx
80100c71:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100c77:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c7b:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c7f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100c82:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c86:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c8a:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100c8d:	89 04 24             	mov    %eax,(%esp)
80100c90:	e8 d7 6f 00 00       	call   80107c6c <loaduvm>
80100c95:	85 c0                	test   %eax,%eax
80100c97:	0f 88 6b 02 00 00    	js     80100f08 <exec+0x40c>
80100c9d:	eb 01                	jmp    80100ca0 <exec+0x1a4>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100c9f:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100ca0:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100ca4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100ca7:	83 c0 20             	add    $0x20,%eax
80100caa:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100cad:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100cb4:	0f b7 c0             	movzwl %ax,%eax
80100cb7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100cba:	0f 8f 28 ff ff ff    	jg     80100be8 <exec+0xec>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100cc0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cc3:	89 04 24             	mov    %eax,(%esp)
80100cc6:	e8 61 0e 00 00       	call   80101b2c <iunlockput>
  ip = 0;
80100ccb:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100cd2:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100cd5:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cda:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cdf:	89 45 dc             	mov    %eax,-0x24(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100ce2:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ce5:	05 00 20 00 00       	add    $0x2000,%eax
80100cea:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cee:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100cf1:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cf5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100cf8:	89 04 24             	mov    %eax,(%esp)
80100cfb:	e8 5b 70 00 00       	call   80107d5b <allocuvm>
80100d00:	89 45 dc             	mov    %eax,-0x24(%ebp)
80100d03:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80100d07:	0f 84 fe 01 00 00    	je     80100f0b <exec+0x40f>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100d0d:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d10:	2d 00 20 00 00       	sub    $0x2000,%eax
80100d15:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d19:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100d1c:	89 04 24             	mov    %eax,(%esp)
80100d1f:	e8 5b 72 00 00       	call   80107f7f <clearpteu>
  sp = sz;
80100d24:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d27:	89 45 d8             	mov    %eax,-0x28(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d2a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
80100d31:	e9 81 00 00 00       	jmp    80100db7 <exec+0x2bb>
    if(argc >= MAXARG)
80100d36:	83 7d e0 1f          	cmpl   $0x1f,-0x20(%ebp)
80100d3a:	0f 87 ce 01 00 00    	ja     80100f0e <exec+0x412>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d40:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d43:	c1 e0 02             	shl    $0x2,%eax
80100d46:	03 45 0c             	add    0xc(%ebp),%eax
80100d49:	8b 00                	mov    (%eax),%eax
80100d4b:	89 04 24             	mov    %eax,(%esp)
80100d4e:	e8 5d 43 00 00       	call   801050b0 <strlen>
80100d53:	f7 d0                	not    %eax
80100d55:	03 45 d8             	add    -0x28(%ebp),%eax
80100d58:	83 e0 fc             	and    $0xfffffffc,%eax
80100d5b:	89 45 d8             	mov    %eax,-0x28(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d61:	c1 e0 02             	shl    $0x2,%eax
80100d64:	03 45 0c             	add    0xc(%ebp),%eax
80100d67:	8b 00                	mov    (%eax),%eax
80100d69:	89 04 24             	mov    %eax,(%esp)
80100d6c:	e8 3f 43 00 00       	call   801050b0 <strlen>
80100d71:	83 c0 01             	add    $0x1,%eax
80100d74:	89 c2                	mov    %eax,%edx
80100d76:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d79:	c1 e0 02             	shl    $0x2,%eax
80100d7c:	03 45 0c             	add    0xc(%ebp),%eax
80100d7f:	8b 00                	mov    (%eax),%eax
80100d81:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d85:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d89:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100d8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d90:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100d93:	89 04 24             	mov    %eax,(%esp)
80100d96:	e8 98 73 00 00       	call   80108133 <copyout>
80100d9b:	85 c0                	test   %eax,%eax
80100d9d:	0f 88 6e 01 00 00    	js     80100f11 <exec+0x415>
      goto bad;
    ustack[3+argc] = sp;
80100da3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100da6:	8d 50 03             	lea    0x3(%eax),%edx
80100da9:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100dac:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100db3:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
80100db7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100dba:	c1 e0 02             	shl    $0x2,%eax
80100dbd:	03 45 0c             	add    0xc(%ebp),%eax
80100dc0:	8b 00                	mov    (%eax),%eax
80100dc2:	85 c0                	test   %eax,%eax
80100dc4:	0f 85 6c ff ff ff    	jne    80100d36 <exec+0x23a>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100dca:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100dcd:	83 c0 03             	add    $0x3,%eax
80100dd0:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100dd7:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100ddb:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100de2:	ff ff ff 
  ustack[1] = argc;
80100de5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100de8:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100dee:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100df1:	83 c0 01             	add    $0x1,%eax
80100df4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dfb:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100dfe:	29 d0                	sub    %edx,%eax
80100e00:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100e06:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100e09:	83 c0 04             	add    $0x4,%eax
80100e0c:	c1 e0 02             	shl    $0x2,%eax
80100e0f:	29 45 d8             	sub    %eax,-0x28(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e12:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100e15:	83 c0 04             	add    $0x4,%eax
80100e18:	c1 e0 02             	shl    $0x2,%eax
80100e1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e1f:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100e25:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e29:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100e2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e30:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100e33:	89 04 24             	mov    %eax,(%esp)
80100e36:	e8 f8 72 00 00       	call   80108133 <copyout>
80100e3b:	85 c0                	test   %eax,%eax
80100e3d:	0f 88 d1 00 00 00    	js     80100f14 <exec+0x418>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e43:	8b 45 08             	mov    0x8(%ebp),%eax
80100e46:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e4c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e4f:	eb 17                	jmp    80100e68 <exec+0x36c>
    if(*s == '/')
80100e51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e54:	0f b6 00             	movzbl (%eax),%eax
80100e57:	3c 2f                	cmp    $0x2f,%al
80100e59:	75 09                	jne    80100e64 <exec+0x368>
      last = s+1;
80100e5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e5e:	83 c0 01             	add    $0x1,%eax
80100e61:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e64:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e6b:	0f b6 00             	movzbl (%eax),%eax
80100e6e:	84 c0                	test   %al,%al
80100e70:	75 df                	jne    80100e51 <exec+0x355>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e72:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e78:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e7b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e82:	00 
80100e83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e86:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e8a:	89 14 24             	mov    %edx,(%esp)
80100e8d:	e8 d0 41 00 00       	call   80105062 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e92:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e98:	8b 40 04             	mov    0x4(%eax),%eax
80100e9b:	89 45 cc             	mov    %eax,-0x34(%ebp)
  proc->pgdir = pgdir;
80100e9e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea4:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100ea7:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100eaa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb0:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100eb3:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100eb5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ebb:	8b 40 18             	mov    0x18(%eax),%eax
80100ebe:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100ec4:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100ec7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ecd:	8b 40 18             	mov    0x18(%eax),%eax
80100ed0:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100ed3:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ed6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100edc:	89 04 24             	mov    %eax,(%esp)
80100edf:	e8 96 6b 00 00       	call   80107a7a <switchuvm>
  freevm(oldpgdir);
80100ee4:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100ee7:	89 04 24             	mov    %eax,(%esp)
80100eea:	e8 02 70 00 00       	call   80107ef1 <freevm>
  return 0;
80100eef:	b8 00 00 00 00       	mov    $0x0,%eax
80100ef4:	eb 46                	jmp    80100f3c <exec+0x440>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100ef6:	90                   	nop
80100ef7:	eb 1c                	jmp    80100f15 <exec+0x419>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100ef9:	90                   	nop
80100efa:	eb 19                	jmp    80100f15 <exec+0x419>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80100efc:	90                   	nop
80100efd:	eb 16                	jmp    80100f15 <exec+0x419>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100eff:	90                   	nop
80100f00:	eb 13                	jmp    80100f15 <exec+0x419>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100f02:	90                   	nop
80100f03:	eb 10                	jmp    80100f15 <exec+0x419>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100f05:	90                   	nop
80100f06:	eb 0d                	jmp    80100f15 <exec+0x419>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100f08:	90                   	nop
80100f09:	eb 0a                	jmp    80100f15 <exec+0x419>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100f0b:	90                   	nop
80100f0c:	eb 07                	jmp    80100f15 <exec+0x419>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100f0e:	90                   	nop
80100f0f:	eb 04                	jmp    80100f15 <exec+0x419>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100f11:	90                   	nop
80100f12:	eb 01                	jmp    80100f15 <exec+0x419>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100f14:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100f15:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80100f19:	74 0b                	je     80100f26 <exec+0x42a>
    freevm(pgdir);
80100f1b:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f1e:	89 04 24             	mov    %eax,(%esp)
80100f21:	e8 cb 6f 00 00       	call   80107ef1 <freevm>
  if(ip)
80100f26:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100f2a:	74 0b                	je     80100f37 <exec+0x43b>
    iunlockput(ip);
80100f2c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f2f:	89 04 24             	mov    %eax,(%esp)
80100f32:	e8 f5 0b 00 00       	call   80101b2c <iunlockput>
  return -1;
80100f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f3c:	c9                   	leave  
80100f3d:	c3                   	ret    
	...

80100f40 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f40:	55                   	push   %ebp
80100f41:	89 e5                	mov    %esp,%ebp
80100f43:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f46:	c7 44 24 04 39 82 10 	movl   $0x80108239,0x4(%esp)
80100f4d:	80 
80100f4e:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80100f55:	e8 68 3c 00 00       	call   80104bc2 <initlock>
}
80100f5a:	c9                   	leave  
80100f5b:	c3                   	ret    

80100f5c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f5c:	55                   	push   %ebp
80100f5d:	89 e5                	mov    %esp,%ebp
80100f5f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f62:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80100f69:	e8 75 3c 00 00       	call   80104be3 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f6e:	c7 45 f4 b4 e3 10 80 	movl   $0x8010e3b4,-0xc(%ebp)
80100f75:	eb 29                	jmp    80100fa0 <filealloc+0x44>
    if(f->ref == 0){
80100f77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f7a:	8b 40 04             	mov    0x4(%eax),%eax
80100f7d:	85 c0                	test   %eax,%eax
80100f7f:	75 1b                	jne    80100f9c <filealloc+0x40>
      f->ref = 1;
80100f81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f84:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f8b:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80100f92:	e8 ae 3c 00 00       	call   80104c45 <release>
      return f;
80100f97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f9a:	eb 1e                	jmp    80100fba <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f9c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100fa0:	81 7d f4 14 ed 10 80 	cmpl   $0x8010ed14,-0xc(%ebp)
80100fa7:	72 ce                	jb     80100f77 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100fa9:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80100fb0:	e8 90 3c 00 00       	call   80104c45 <release>
  return 0;
80100fb5:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100fba:	c9                   	leave  
80100fbb:	c3                   	ret    

80100fbc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100fbc:	55                   	push   %ebp
80100fbd:	89 e5                	mov    %esp,%ebp
80100fbf:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100fc2:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80100fc9:	e8 15 3c 00 00       	call   80104be3 <acquire>
  if(f->ref < 1)
80100fce:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd1:	8b 40 04             	mov    0x4(%eax),%eax
80100fd4:	85 c0                	test   %eax,%eax
80100fd6:	7f 0c                	jg     80100fe4 <filedup+0x28>
    panic("filedup");
80100fd8:	c7 04 24 40 82 10 80 	movl   $0x80108240,(%esp)
80100fdf:	e8 59 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fe4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe7:	8b 40 04             	mov    0x4(%eax),%eax
80100fea:	8d 50 01             	lea    0x1(%eax),%edx
80100fed:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100ff3:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80100ffa:	e8 46 3c 00 00       	call   80104c45 <release>
  return f;
80100fff:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101002:	c9                   	leave  
80101003:	c3                   	ret    

80101004 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80101004:	55                   	push   %ebp
80101005:	89 e5                	mov    %esp,%ebp
80101007:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
8010100a:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101011:	e8 cd 3b 00 00       	call   80104be3 <acquire>
  if(f->ref < 1)
80101016:	8b 45 08             	mov    0x8(%ebp),%eax
80101019:	8b 40 04             	mov    0x4(%eax),%eax
8010101c:	85 c0                	test   %eax,%eax
8010101e:	7f 0c                	jg     8010102c <fileclose+0x28>
    panic("fileclose");
80101020:	c7 04 24 48 82 10 80 	movl   $0x80108248,(%esp)
80101027:	e8 11 f5 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
8010102c:	8b 45 08             	mov    0x8(%ebp),%eax
8010102f:	8b 40 04             	mov    0x4(%eax),%eax
80101032:	8d 50 ff             	lea    -0x1(%eax),%edx
80101035:	8b 45 08             	mov    0x8(%ebp),%eax
80101038:	89 50 04             	mov    %edx,0x4(%eax)
8010103b:	8b 45 08             	mov    0x8(%ebp),%eax
8010103e:	8b 40 04             	mov    0x4(%eax),%eax
80101041:	85 c0                	test   %eax,%eax
80101043:	7e 11                	jle    80101056 <fileclose+0x52>
    release(&ftable.lock);
80101045:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
8010104c:	e8 f4 3b 00 00       	call   80104c45 <release>
    return;
80101051:	e9 82 00 00 00       	jmp    801010d8 <fileclose+0xd4>
  }
  ff = *f;
80101056:	8b 45 08             	mov    0x8(%ebp),%eax
80101059:	8b 10                	mov    (%eax),%edx
8010105b:	89 55 e0             	mov    %edx,-0x20(%ebp)
8010105e:	8b 50 04             	mov    0x4(%eax),%edx
80101061:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101064:	8b 50 08             	mov    0x8(%eax),%edx
80101067:	89 55 e8             	mov    %edx,-0x18(%ebp)
8010106a:	8b 50 0c             	mov    0xc(%eax),%edx
8010106d:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101070:	8b 50 10             	mov    0x10(%eax),%edx
80101073:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101076:	8b 40 14             	mov    0x14(%eax),%eax
80101079:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
8010107c:	8b 45 08             	mov    0x8(%ebp),%eax
8010107f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101086:	8b 45 08             	mov    0x8(%ebp),%eax
80101089:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
8010108f:	c7 04 24 80 e3 10 80 	movl   $0x8010e380,(%esp)
80101096:	e8 aa 3b 00 00       	call   80104c45 <release>
  
  if(ff.type == FD_PIPE)
8010109b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010109e:	83 f8 01             	cmp    $0x1,%eax
801010a1:	75 18                	jne    801010bb <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
801010a3:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
801010a7:	0f be d0             	movsbl %al,%edx
801010aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801010ad:	89 54 24 04          	mov    %edx,0x4(%esp)
801010b1:	89 04 24             	mov    %eax,(%esp)
801010b4:	e8 02 2d 00 00       	call   80103dbb <pipeclose>
801010b9:	eb 1d                	jmp    801010d8 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801010bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010be:	83 f8 02             	cmp    $0x2,%eax
801010c1:	75 15                	jne    801010d8 <fileclose+0xd4>
    begin_trans();
801010c3:	e8 95 21 00 00       	call   8010325d <begin_trans>
    iput(ff.ip);
801010c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010cb:	89 04 24             	mov    %eax,(%esp)
801010ce:	e8 88 09 00 00       	call   80101a5b <iput>
    commit_trans();
801010d3:	e8 ce 21 00 00       	call   801032a6 <commit_trans>
  }
}
801010d8:	c9                   	leave  
801010d9:	c3                   	ret    

801010da <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010da:	55                   	push   %ebp
801010db:	89 e5                	mov    %esp,%ebp
801010dd:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010e0:	8b 45 08             	mov    0x8(%ebp),%eax
801010e3:	8b 00                	mov    (%eax),%eax
801010e5:	83 f8 02             	cmp    $0x2,%eax
801010e8:	75 38                	jne    80101122 <filestat+0x48>
    ilock(f->ip);
801010ea:	8b 45 08             	mov    0x8(%ebp),%eax
801010ed:	8b 40 10             	mov    0x10(%eax),%eax
801010f0:	89 04 24             	mov    %eax,(%esp)
801010f3:	e8 b0 07 00 00       	call   801018a8 <ilock>
    stati(f->ip, st);
801010f8:	8b 45 08             	mov    0x8(%ebp),%eax
801010fb:	8b 40 10             	mov    0x10(%eax),%eax
801010fe:	8b 55 0c             	mov    0xc(%ebp),%edx
80101101:	89 54 24 04          	mov    %edx,0x4(%esp)
80101105:	89 04 24             	mov    %eax,(%esp)
80101108:	e8 4c 0c 00 00       	call   80101d59 <stati>
    iunlock(f->ip);
8010110d:	8b 45 08             	mov    0x8(%ebp),%eax
80101110:	8b 40 10             	mov    0x10(%eax),%eax
80101113:	89 04 24             	mov    %eax,(%esp)
80101116:	e8 db 08 00 00       	call   801019f6 <iunlock>
    return 0;
8010111b:	b8 00 00 00 00       	mov    $0x0,%eax
80101120:	eb 05                	jmp    80101127 <filestat+0x4d>
  }
  return -1;
80101122:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101127:	c9                   	leave  
80101128:	c3                   	ret    

80101129 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101129:	55                   	push   %ebp
8010112a:	89 e5                	mov    %esp,%ebp
8010112c:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
8010112f:	8b 45 08             	mov    0x8(%ebp),%eax
80101132:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101136:	84 c0                	test   %al,%al
80101138:	75 0a                	jne    80101144 <fileread+0x1b>
    return -1;
8010113a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010113f:	e9 9f 00 00 00       	jmp    801011e3 <fileread+0xba>
  if(f->type == FD_PIPE)
80101144:	8b 45 08             	mov    0x8(%ebp),%eax
80101147:	8b 00                	mov    (%eax),%eax
80101149:	83 f8 01             	cmp    $0x1,%eax
8010114c:	75 1e                	jne    8010116c <fileread+0x43>
    return piperead(f->pipe, addr, n);
8010114e:	8b 45 08             	mov    0x8(%ebp),%eax
80101151:	8b 40 0c             	mov    0xc(%eax),%eax
80101154:	8b 55 10             	mov    0x10(%ebp),%edx
80101157:	89 54 24 08          	mov    %edx,0x8(%esp)
8010115b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010115e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101162:	89 04 24             	mov    %eax,(%esp)
80101165:	e8 d3 2d 00 00       	call   80103f3d <piperead>
8010116a:	eb 77                	jmp    801011e3 <fileread+0xba>
  if(f->type == FD_INODE){
8010116c:	8b 45 08             	mov    0x8(%ebp),%eax
8010116f:	8b 00                	mov    (%eax),%eax
80101171:	83 f8 02             	cmp    $0x2,%eax
80101174:	75 61                	jne    801011d7 <fileread+0xae>
    ilock(f->ip);
80101176:	8b 45 08             	mov    0x8(%ebp),%eax
80101179:	8b 40 10             	mov    0x10(%eax),%eax
8010117c:	89 04 24             	mov    %eax,(%esp)
8010117f:	e8 24 07 00 00       	call   801018a8 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80101184:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101187:	8b 45 08             	mov    0x8(%ebp),%eax
8010118a:	8b 50 14             	mov    0x14(%eax),%edx
8010118d:	8b 45 08             	mov    0x8(%ebp),%eax
80101190:	8b 40 10             	mov    0x10(%eax),%eax
80101193:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101197:	89 54 24 08          	mov    %edx,0x8(%esp)
8010119b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010119e:	89 54 24 04          	mov    %edx,0x4(%esp)
801011a2:	89 04 24             	mov    %eax,(%esp)
801011a5:	e8 f4 0b 00 00       	call   80101d9e <readi>
801011aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801011ad:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801011b1:	7e 11                	jle    801011c4 <fileread+0x9b>
      f->off += r;
801011b3:	8b 45 08             	mov    0x8(%ebp),%eax
801011b6:	8b 50 14             	mov    0x14(%eax),%edx
801011b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011bc:	01 c2                	add    %eax,%edx
801011be:	8b 45 08             	mov    0x8(%ebp),%eax
801011c1:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801011c4:	8b 45 08             	mov    0x8(%ebp),%eax
801011c7:	8b 40 10             	mov    0x10(%eax),%eax
801011ca:	89 04 24             	mov    %eax,(%esp)
801011cd:	e8 24 08 00 00       	call   801019f6 <iunlock>
    return r;
801011d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011d5:	eb 0c                	jmp    801011e3 <fileread+0xba>
  }
  panic("fileread");
801011d7:	c7 04 24 52 82 10 80 	movl   $0x80108252,(%esp)
801011de:	e8 5a f3 ff ff       	call   8010053d <panic>
}
801011e3:	c9                   	leave  
801011e4:	c3                   	ret    

801011e5 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011e5:	55                   	push   %ebp
801011e6:	89 e5                	mov    %esp,%ebp
801011e8:	53                   	push   %ebx
801011e9:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011ec:	8b 45 08             	mov    0x8(%ebp),%eax
801011ef:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011f3:	84 c0                	test   %al,%al
801011f5:	75 0a                	jne    80101201 <filewrite+0x1c>
    return -1;
801011f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011fc:	e9 23 01 00 00       	jmp    80101324 <filewrite+0x13f>
  if(f->type == FD_PIPE)
80101201:	8b 45 08             	mov    0x8(%ebp),%eax
80101204:	8b 00                	mov    (%eax),%eax
80101206:	83 f8 01             	cmp    $0x1,%eax
80101209:	75 21                	jne    8010122c <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
8010120b:	8b 45 08             	mov    0x8(%ebp),%eax
8010120e:	8b 40 0c             	mov    0xc(%eax),%eax
80101211:	8b 55 10             	mov    0x10(%ebp),%edx
80101214:	89 54 24 08          	mov    %edx,0x8(%esp)
80101218:	8b 55 0c             	mov    0xc(%ebp),%edx
8010121b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010121f:	89 04 24             	mov    %eax,(%esp)
80101222:	e8 26 2c 00 00       	call   80103e4d <pipewrite>
80101227:	e9 f8 00 00 00       	jmp    80101324 <filewrite+0x13f>
  if(f->type == FD_INODE){
8010122c:	8b 45 08             	mov    0x8(%ebp),%eax
8010122f:	8b 00                	mov    (%eax),%eax
80101231:	83 f8 02             	cmp    $0x2,%eax
80101234:	0f 85 de 00 00 00    	jne    80101318 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
8010123a:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101241:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101248:	e9 a8 00 00 00       	jmp    801012f5 <filewrite+0x110>
      int n1 = n - i;
8010124d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101250:	8b 55 10             	mov    0x10(%ebp),%edx
80101253:	89 d1                	mov    %edx,%ecx
80101255:	29 c1                	sub    %eax,%ecx
80101257:	89 c8                	mov    %ecx,%eax
80101259:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
8010125c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010125f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101262:	7e 06                	jle    8010126a <filewrite+0x85>
        n1 = max;
80101264:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101267:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
8010126a:	e8 ee 1f 00 00       	call   8010325d <begin_trans>
      ilock(f->ip);
8010126f:	8b 45 08             	mov    0x8(%ebp),%eax
80101272:	8b 40 10             	mov    0x10(%eax),%eax
80101275:	89 04 24             	mov    %eax,(%esp)
80101278:	e8 2b 06 00 00       	call   801018a8 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
8010127d:	8b 5d f0             	mov    -0x10(%ebp),%ebx
80101280:	8b 45 08             	mov    0x8(%ebp),%eax
80101283:	8b 48 14             	mov    0x14(%eax),%ecx
80101286:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101289:	89 c2                	mov    %eax,%edx
8010128b:	03 55 0c             	add    0xc(%ebp),%edx
8010128e:	8b 45 08             	mov    0x8(%ebp),%eax
80101291:	8b 40 10             	mov    0x10(%eax),%eax
80101294:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80101298:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010129c:	89 54 24 04          	mov    %edx,0x4(%esp)
801012a0:	89 04 24             	mov    %eax,(%esp)
801012a3:	e8 61 0c 00 00       	call   80101f09 <writei>
801012a8:	89 45 e8             	mov    %eax,-0x18(%ebp)
801012ab:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012af:	7e 11                	jle    801012c2 <filewrite+0xdd>
        f->off += r;
801012b1:	8b 45 08             	mov    0x8(%ebp),%eax
801012b4:	8b 50 14             	mov    0x14(%eax),%edx
801012b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012ba:	01 c2                	add    %eax,%edx
801012bc:	8b 45 08             	mov    0x8(%ebp),%eax
801012bf:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801012c2:	8b 45 08             	mov    0x8(%ebp),%eax
801012c5:	8b 40 10             	mov    0x10(%eax),%eax
801012c8:	89 04 24             	mov    %eax,(%esp)
801012cb:	e8 26 07 00 00       	call   801019f6 <iunlock>
      commit_trans();
801012d0:	e8 d1 1f 00 00       	call   801032a6 <commit_trans>

      if(r < 0)
801012d5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012d9:	78 28                	js     80101303 <filewrite+0x11e>
        break;
      if(r != n1)
801012db:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012de:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012e1:	74 0c                	je     801012ef <filewrite+0x10a>
        panic("short filewrite");
801012e3:	c7 04 24 5b 82 10 80 	movl   $0x8010825b,(%esp)
801012ea:	e8 4e f2 ff ff       	call   8010053d <panic>
      i += r;
801012ef:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012f2:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012f8:	3b 45 10             	cmp    0x10(%ebp),%eax
801012fb:	0f 8c 4c ff ff ff    	jl     8010124d <filewrite+0x68>
80101301:	eb 01                	jmp    80101304 <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
80101303:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
80101304:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101307:	3b 45 10             	cmp    0x10(%ebp),%eax
8010130a:	75 05                	jne    80101311 <filewrite+0x12c>
8010130c:	8b 45 10             	mov    0x10(%ebp),%eax
8010130f:	eb 05                	jmp    80101316 <filewrite+0x131>
80101311:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101316:	eb 0c                	jmp    80101324 <filewrite+0x13f>
  }
  panic("filewrite");
80101318:	c7 04 24 6b 82 10 80 	movl   $0x8010826b,(%esp)
8010131f:	e8 19 f2 ff ff       	call   8010053d <panic>
}
80101324:	83 c4 24             	add    $0x24,%esp
80101327:	5b                   	pop    %ebx
80101328:	5d                   	pop    %ebp
80101329:	c3                   	ret    
	...

8010132c <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
8010132c:	55                   	push   %ebp
8010132d:	89 e5                	mov    %esp,%ebp
8010132f:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101332:	8b 45 08             	mov    0x8(%ebp),%eax
80101335:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010133c:	00 
8010133d:	89 04 24             	mov    %eax,(%esp)
80101340:	e8 61 ee ff ff       	call   801001a6 <bread>
80101345:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101348:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010134b:	83 c0 18             	add    $0x18,%eax
8010134e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101355:	00 
80101356:	89 44 24 04          	mov    %eax,0x4(%esp)
8010135a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010135d:	89 04 24             	mov    %eax,(%esp)
80101360:	e8 a0 3b 00 00       	call   80104f05 <memmove>
  brelse(bp);
80101365:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101368:	89 04 24             	mov    %eax,(%esp)
8010136b:	e8 a7 ee ff ff       	call   80100217 <brelse>
}
80101370:	c9                   	leave  
80101371:	c3                   	ret    

80101372 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101372:	55                   	push   %ebp
80101373:	89 e5                	mov    %esp,%ebp
80101375:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101378:	8b 55 0c             	mov    0xc(%ebp),%edx
8010137b:	8b 45 08             	mov    0x8(%ebp),%eax
8010137e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101382:	89 04 24             	mov    %eax,(%esp)
80101385:	e8 1c ee ff ff       	call   801001a6 <bread>
8010138a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
8010138d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101390:	83 c0 18             	add    $0x18,%eax
80101393:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010139a:	00 
8010139b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801013a2:	00 
801013a3:	89 04 24             	mov    %eax,(%esp)
801013a6:	e8 87 3a 00 00       	call   80104e32 <memset>
  log_write(bp);
801013ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013ae:	89 04 24             	mov    %eax,(%esp)
801013b1:	e8 48 1f 00 00       	call   801032fe <log_write>
  brelse(bp);
801013b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b9:	89 04 24             	mov    %eax,(%esp)
801013bc:	e8 56 ee ff ff       	call   80100217 <brelse>
}
801013c1:	c9                   	leave  
801013c2:	c3                   	ret    

801013c3 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801013c3:	55                   	push   %ebp
801013c4:	89 e5                	mov    %esp,%ebp
801013c6:	53                   	push   %ebx
801013c7:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801013ca:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
801013d1:	8b 45 08             	mov    0x8(%ebp),%eax
801013d4:	8d 55 d8             	lea    -0x28(%ebp),%edx
801013d7:	89 54 24 04          	mov    %edx,0x4(%esp)
801013db:	89 04 24             	mov    %eax,(%esp)
801013de:	e8 49 ff ff ff       	call   8010132c <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013ea:	e9 11 01 00 00       	jmp    80101500 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013f2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013f8:	85 c0                	test   %eax,%eax
801013fa:	0f 48 c2             	cmovs  %edx,%eax
801013fd:	c1 f8 0c             	sar    $0xc,%eax
80101400:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101403:	c1 ea 03             	shr    $0x3,%edx
80101406:	01 d0                	add    %edx,%eax
80101408:	83 c0 03             	add    $0x3,%eax
8010140b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010140f:	8b 45 08             	mov    0x8(%ebp),%eax
80101412:	89 04 24             	mov    %eax,(%esp)
80101415:	e8 8c ed ff ff       	call   801001a6 <bread>
8010141a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010141d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101424:	e9 a7 00 00 00       	jmp    801014d0 <balloc+0x10d>
      m = 1 << (bi % 8);
80101429:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010142c:	89 c2                	mov    %eax,%edx
8010142e:	c1 fa 1f             	sar    $0x1f,%edx
80101431:	c1 ea 1d             	shr    $0x1d,%edx
80101434:	01 d0                	add    %edx,%eax
80101436:	83 e0 07             	and    $0x7,%eax
80101439:	29 d0                	sub    %edx,%eax
8010143b:	ba 01 00 00 00       	mov    $0x1,%edx
80101440:	89 d3                	mov    %edx,%ebx
80101442:	89 c1                	mov    %eax,%ecx
80101444:	d3 e3                	shl    %cl,%ebx
80101446:	89 d8                	mov    %ebx,%eax
80101448:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010144b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010144e:	8d 50 07             	lea    0x7(%eax),%edx
80101451:	85 c0                	test   %eax,%eax
80101453:	0f 48 c2             	cmovs  %edx,%eax
80101456:	c1 f8 03             	sar    $0x3,%eax
80101459:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010145c:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101461:	0f b6 c0             	movzbl %al,%eax
80101464:	23 45 e8             	and    -0x18(%ebp),%eax
80101467:	85 c0                	test   %eax,%eax
80101469:	75 61                	jne    801014cc <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
8010146b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010146e:	8d 50 07             	lea    0x7(%eax),%edx
80101471:	85 c0                	test   %eax,%eax
80101473:	0f 48 c2             	cmovs  %edx,%eax
80101476:	c1 f8 03             	sar    $0x3,%eax
80101479:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010147c:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101481:	89 d1                	mov    %edx,%ecx
80101483:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101486:	09 ca                	or     %ecx,%edx
80101488:	89 d1                	mov    %edx,%ecx
8010148a:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010148d:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101491:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101494:	89 04 24             	mov    %eax,(%esp)
80101497:	e8 62 1e 00 00       	call   801032fe <log_write>
        brelse(bp);
8010149c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010149f:	89 04 24             	mov    %eax,(%esp)
801014a2:	e8 70 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
801014a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014ad:	01 c2                	add    %eax,%edx
801014af:	8b 45 08             	mov    0x8(%ebp),%eax
801014b2:	89 54 24 04          	mov    %edx,0x4(%esp)
801014b6:	89 04 24             	mov    %eax,(%esp)
801014b9:	e8 b4 fe ff ff       	call   80101372 <bzero>
        return b + bi;
801014be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014c4:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
801014c6:	83 c4 34             	add    $0x34,%esp
801014c9:	5b                   	pop    %ebx
801014ca:	5d                   	pop    %ebp
801014cb:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014cc:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801014d0:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801014d7:	7f 15                	jg     801014ee <balloc+0x12b>
801014d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014df:	01 d0                	add    %edx,%eax
801014e1:	89 c2                	mov    %eax,%edx
801014e3:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014e6:	39 c2                	cmp    %eax,%edx
801014e8:	0f 82 3b ff ff ff    	jb     80101429 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014f1:	89 04 24             	mov    %eax,(%esp)
801014f4:	e8 1e ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014f9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101500:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101503:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101506:	39 c2                	cmp    %eax,%edx
80101508:	0f 82 e1 fe ff ff    	jb     801013ef <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
8010150e:	c7 04 24 75 82 10 80 	movl   $0x80108275,(%esp)
80101515:	e8 23 f0 ff ff       	call   8010053d <panic>

8010151a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
8010151a:	55                   	push   %ebp
8010151b:	89 e5                	mov    %esp,%ebp
8010151d:	53                   	push   %ebx
8010151e:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101521:	8d 45 dc             	lea    -0x24(%ebp),%eax
80101524:	89 44 24 04          	mov    %eax,0x4(%esp)
80101528:	8b 45 08             	mov    0x8(%ebp),%eax
8010152b:	89 04 24             	mov    %eax,(%esp)
8010152e:	e8 f9 fd ff ff       	call   8010132c <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80101533:	8b 45 0c             	mov    0xc(%ebp),%eax
80101536:	89 c2                	mov    %eax,%edx
80101538:	c1 ea 0c             	shr    $0xc,%edx
8010153b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010153e:	c1 e8 03             	shr    $0x3,%eax
80101541:	01 d0                	add    %edx,%eax
80101543:	8d 50 03             	lea    0x3(%eax),%edx
80101546:	8b 45 08             	mov    0x8(%ebp),%eax
80101549:	89 54 24 04          	mov    %edx,0x4(%esp)
8010154d:	89 04 24             	mov    %eax,(%esp)
80101550:	e8 51 ec ff ff       	call   801001a6 <bread>
80101555:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101558:	8b 45 0c             	mov    0xc(%ebp),%eax
8010155b:	25 ff 0f 00 00       	and    $0xfff,%eax
80101560:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101563:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101566:	89 c2                	mov    %eax,%edx
80101568:	c1 fa 1f             	sar    $0x1f,%edx
8010156b:	c1 ea 1d             	shr    $0x1d,%edx
8010156e:	01 d0                	add    %edx,%eax
80101570:	83 e0 07             	and    $0x7,%eax
80101573:	29 d0                	sub    %edx,%eax
80101575:	ba 01 00 00 00       	mov    $0x1,%edx
8010157a:	89 d3                	mov    %edx,%ebx
8010157c:	89 c1                	mov    %eax,%ecx
8010157e:	d3 e3                	shl    %cl,%ebx
80101580:	89 d8                	mov    %ebx,%eax
80101582:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101585:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101588:	8d 50 07             	lea    0x7(%eax),%edx
8010158b:	85 c0                	test   %eax,%eax
8010158d:	0f 48 c2             	cmovs  %edx,%eax
80101590:	c1 f8 03             	sar    $0x3,%eax
80101593:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101596:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010159b:	0f b6 c0             	movzbl %al,%eax
8010159e:	23 45 ec             	and    -0x14(%ebp),%eax
801015a1:	85 c0                	test   %eax,%eax
801015a3:	75 0c                	jne    801015b1 <bfree+0x97>
    panic("freeing free block");
801015a5:	c7 04 24 8b 82 10 80 	movl   $0x8010828b,(%esp)
801015ac:	e8 8c ef ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
801015b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015b4:	8d 50 07             	lea    0x7(%eax),%edx
801015b7:	85 c0                	test   %eax,%eax
801015b9:	0f 48 c2             	cmovs  %edx,%eax
801015bc:	c1 f8 03             	sar    $0x3,%eax
801015bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015c2:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801015c7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801015ca:	f7 d1                	not    %ecx
801015cc:	21 ca                	and    %ecx,%edx
801015ce:	89 d1                	mov    %edx,%ecx
801015d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015d3:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801015d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015da:	89 04 24             	mov    %eax,(%esp)
801015dd:	e8 1c 1d 00 00       	call   801032fe <log_write>
  brelse(bp);
801015e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015e5:	89 04 24             	mov    %eax,(%esp)
801015e8:	e8 2a ec ff ff       	call   80100217 <brelse>
}
801015ed:	83 c4 34             	add    $0x34,%esp
801015f0:	5b                   	pop    %ebx
801015f1:	5d                   	pop    %ebp
801015f2:	c3                   	ret    

801015f3 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015f3:	55                   	push   %ebp
801015f4:	89 e5                	mov    %esp,%ebp
801015f6:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015f9:	c7 44 24 04 9e 82 10 	movl   $0x8010829e,0x4(%esp)
80101600:	80 
80101601:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101608:	e8 b5 35 00 00       	call   80104bc2 <initlock>
}
8010160d:	c9                   	leave  
8010160e:	c3                   	ret    

8010160f <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
8010160f:	55                   	push   %ebp
80101610:	89 e5                	mov    %esp,%ebp
80101612:	83 ec 48             	sub    $0x48,%esp
80101615:	8b 45 0c             	mov    0xc(%ebp),%eax
80101618:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
8010161c:	8b 45 08             	mov    0x8(%ebp),%eax
8010161f:	8d 55 dc             	lea    -0x24(%ebp),%edx
80101622:	89 54 24 04          	mov    %edx,0x4(%esp)
80101626:	89 04 24             	mov    %eax,(%esp)
80101629:	e8 fe fc ff ff       	call   8010132c <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
8010162e:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101635:	e9 98 00 00 00       	jmp    801016d2 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
8010163a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010163d:	c1 e8 03             	shr    $0x3,%eax
80101640:	83 c0 02             	add    $0x2,%eax
80101643:	89 44 24 04          	mov    %eax,0x4(%esp)
80101647:	8b 45 08             	mov    0x8(%ebp),%eax
8010164a:	89 04 24             	mov    %eax,(%esp)
8010164d:	e8 54 eb ff ff       	call   801001a6 <bread>
80101652:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101655:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101658:	8d 50 18             	lea    0x18(%eax),%edx
8010165b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010165e:	83 e0 07             	and    $0x7,%eax
80101661:	c1 e0 06             	shl    $0x6,%eax
80101664:	01 d0                	add    %edx,%eax
80101666:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101669:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010166c:	0f b7 00             	movzwl (%eax),%eax
8010166f:	66 85 c0             	test   %ax,%ax
80101672:	75 4f                	jne    801016c3 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101674:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010167b:	00 
8010167c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101683:	00 
80101684:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101687:	89 04 24             	mov    %eax,(%esp)
8010168a:	e8 a3 37 00 00       	call   80104e32 <memset>
      dip->type = type;
8010168f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101692:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101696:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101699:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010169c:	89 04 24             	mov    %eax,(%esp)
8010169f:	e8 5a 1c 00 00       	call   801032fe <log_write>
      brelse(bp);
801016a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016a7:	89 04 24             	mov    %eax,(%esp)
801016aa:	e8 68 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801016af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801016b6:	8b 45 08             	mov    0x8(%ebp),%eax
801016b9:	89 04 24             	mov    %eax,(%esp)
801016bc:	e8 e3 00 00 00       	call   801017a4 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
801016c1:	c9                   	leave  
801016c2:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
801016c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016c6:	89 04 24             	mov    %eax,(%esp)
801016c9:	e8 49 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
801016ce:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801016d2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801016d8:	39 c2                	cmp    %eax,%edx
801016da:	0f 82 5a ff ff ff    	jb     8010163a <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801016e0:	c7 04 24 a5 82 10 80 	movl   $0x801082a5,(%esp)
801016e7:	e8 51 ee ff ff       	call   8010053d <panic>

801016ec <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801016ec:	55                   	push   %ebp
801016ed:	89 e5                	mov    %esp,%ebp
801016ef:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016f2:	8b 45 08             	mov    0x8(%ebp),%eax
801016f5:	8b 40 04             	mov    0x4(%eax),%eax
801016f8:	c1 e8 03             	shr    $0x3,%eax
801016fb:	8d 50 02             	lea    0x2(%eax),%edx
801016fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101701:	8b 00                	mov    (%eax),%eax
80101703:	89 54 24 04          	mov    %edx,0x4(%esp)
80101707:	89 04 24             	mov    %eax,(%esp)
8010170a:	e8 97 ea ff ff       	call   801001a6 <bread>
8010170f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101712:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101715:	8d 50 18             	lea    0x18(%eax),%edx
80101718:	8b 45 08             	mov    0x8(%ebp),%eax
8010171b:	8b 40 04             	mov    0x4(%eax),%eax
8010171e:	83 e0 07             	and    $0x7,%eax
80101721:	c1 e0 06             	shl    $0x6,%eax
80101724:	01 d0                	add    %edx,%eax
80101726:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101729:	8b 45 08             	mov    0x8(%ebp),%eax
8010172c:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101730:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101733:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101736:	8b 45 08             	mov    0x8(%ebp),%eax
80101739:	0f b7 50 12          	movzwl 0x12(%eax),%edx
8010173d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101740:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101744:	8b 45 08             	mov    0x8(%ebp),%eax
80101747:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010174b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010174e:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101752:	8b 45 08             	mov    0x8(%ebp),%eax
80101755:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101759:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010175c:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101760:	8b 45 08             	mov    0x8(%ebp),%eax
80101763:	8b 50 18             	mov    0x18(%eax),%edx
80101766:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101769:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010176c:	8b 45 08             	mov    0x8(%ebp),%eax
8010176f:	8d 50 1c             	lea    0x1c(%eax),%edx
80101772:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101775:	83 c0 0c             	add    $0xc,%eax
80101778:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
8010177f:	00 
80101780:	89 54 24 04          	mov    %edx,0x4(%esp)
80101784:	89 04 24             	mov    %eax,(%esp)
80101787:	e8 79 37 00 00       	call   80104f05 <memmove>
  log_write(bp);
8010178c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010178f:	89 04 24             	mov    %eax,(%esp)
80101792:	e8 67 1b 00 00       	call   801032fe <log_write>
  brelse(bp);
80101797:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179a:	89 04 24             	mov    %eax,(%esp)
8010179d:	e8 75 ea ff ff       	call   80100217 <brelse>
}
801017a2:	c9                   	leave  
801017a3:	c3                   	ret    

801017a4 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801017a4:	55                   	push   %ebp
801017a5:	89 e5                	mov    %esp,%ebp
801017a7:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801017aa:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801017b1:	e8 2d 34 00 00       	call   80104be3 <acquire>

  // Is the inode already cached?
  empty = 0;
801017b6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017bd:	c7 45 f4 b4 ed 10 80 	movl   $0x8010edb4,-0xc(%ebp)
801017c4:	eb 59                	jmp    8010181f <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801017c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c9:	8b 40 08             	mov    0x8(%eax),%eax
801017cc:	85 c0                	test   %eax,%eax
801017ce:	7e 35                	jle    80101805 <iget+0x61>
801017d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d3:	8b 00                	mov    (%eax),%eax
801017d5:	3b 45 08             	cmp    0x8(%ebp),%eax
801017d8:	75 2b                	jne    80101805 <iget+0x61>
801017da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017dd:	8b 40 04             	mov    0x4(%eax),%eax
801017e0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801017e3:	75 20                	jne    80101805 <iget+0x61>
      ip->ref++;
801017e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017e8:	8b 40 08             	mov    0x8(%eax),%eax
801017eb:	8d 50 01             	lea    0x1(%eax),%edx
801017ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f1:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017f4:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801017fb:	e8 45 34 00 00       	call   80104c45 <release>
      return ip;
80101800:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101803:	eb 6f                	jmp    80101874 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101805:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101809:	75 10                	jne    8010181b <iget+0x77>
8010180b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010180e:	8b 40 08             	mov    0x8(%eax),%eax
80101811:	85 c0                	test   %eax,%eax
80101813:	75 06                	jne    8010181b <iget+0x77>
      empty = ip;
80101815:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101818:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010181b:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010181f:	81 7d f4 54 fd 10 80 	cmpl   $0x8010fd54,-0xc(%ebp)
80101826:	72 9e                	jb     801017c6 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101828:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010182c:	75 0c                	jne    8010183a <iget+0x96>
    panic("iget: no inodes");
8010182e:	c7 04 24 b7 82 10 80 	movl   $0x801082b7,(%esp)
80101835:	e8 03 ed ff ff       	call   8010053d <panic>

  ip = empty;
8010183a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010183d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101840:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101843:	8b 55 08             	mov    0x8(%ebp),%edx
80101846:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101848:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010184e:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101854:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010185b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010185e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101865:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
8010186c:	e8 d4 33 00 00       	call   80104c45 <release>

  return ip;
80101871:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101874:	c9                   	leave  
80101875:	c3                   	ret    

80101876 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101876:	55                   	push   %ebp
80101877:	89 e5                	mov    %esp,%ebp
80101879:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010187c:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101883:	e8 5b 33 00 00       	call   80104be3 <acquire>
  ip->ref++;
80101888:	8b 45 08             	mov    0x8(%ebp),%eax
8010188b:	8b 40 08             	mov    0x8(%eax),%eax
8010188e:	8d 50 01             	lea    0x1(%eax),%edx
80101891:	8b 45 08             	mov    0x8(%ebp),%eax
80101894:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101897:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
8010189e:	e8 a2 33 00 00       	call   80104c45 <release>
  return ip;
801018a3:	8b 45 08             	mov    0x8(%ebp),%eax
}
801018a6:	c9                   	leave  
801018a7:	c3                   	ret    

801018a8 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801018a8:	55                   	push   %ebp
801018a9:	89 e5                	mov    %esp,%ebp
801018ab:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801018ae:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801018b2:	74 0a                	je     801018be <ilock+0x16>
801018b4:	8b 45 08             	mov    0x8(%ebp),%eax
801018b7:	8b 40 08             	mov    0x8(%eax),%eax
801018ba:	85 c0                	test   %eax,%eax
801018bc:	7f 0c                	jg     801018ca <ilock+0x22>
    panic("ilock");
801018be:	c7 04 24 c7 82 10 80 	movl   $0x801082c7,(%esp)
801018c5:	e8 73 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
801018ca:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
801018d1:	e8 0d 33 00 00       	call   80104be3 <acquire>
  while(ip->flags & I_BUSY)
801018d6:	eb 13                	jmp    801018eb <ilock+0x43>
    sleep(ip, &icache.lock);
801018d8:	c7 44 24 04 80 ed 10 	movl   $0x8010ed80,0x4(%esp)
801018df:	80 
801018e0:	8b 45 08             	mov    0x8(%ebp),%eax
801018e3:	89 04 24             	mov    %eax,(%esp)
801018e6:	e8 1a 30 00 00       	call   80104905 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801018eb:	8b 45 08             	mov    0x8(%ebp),%eax
801018ee:	8b 40 0c             	mov    0xc(%eax),%eax
801018f1:	83 e0 01             	and    $0x1,%eax
801018f4:	84 c0                	test   %al,%al
801018f6:	75 e0                	jne    801018d8 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018f8:	8b 45 08             	mov    0x8(%ebp),%eax
801018fb:	8b 40 0c             	mov    0xc(%eax),%eax
801018fe:	89 c2                	mov    %eax,%edx
80101900:	83 ca 01             	or     $0x1,%edx
80101903:	8b 45 08             	mov    0x8(%ebp),%eax
80101906:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101909:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101910:	e8 30 33 00 00       	call   80104c45 <release>

  if(!(ip->flags & I_VALID)){
80101915:	8b 45 08             	mov    0x8(%ebp),%eax
80101918:	8b 40 0c             	mov    0xc(%eax),%eax
8010191b:	83 e0 02             	and    $0x2,%eax
8010191e:	85 c0                	test   %eax,%eax
80101920:	0f 85 ce 00 00 00    	jne    801019f4 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80101926:	8b 45 08             	mov    0x8(%ebp),%eax
80101929:	8b 40 04             	mov    0x4(%eax),%eax
8010192c:	c1 e8 03             	shr    $0x3,%eax
8010192f:	8d 50 02             	lea    0x2(%eax),%edx
80101932:	8b 45 08             	mov    0x8(%ebp),%eax
80101935:	8b 00                	mov    (%eax),%eax
80101937:	89 54 24 04          	mov    %edx,0x4(%esp)
8010193b:	89 04 24             	mov    %eax,(%esp)
8010193e:	e8 63 e8 ff ff       	call   801001a6 <bread>
80101943:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101946:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101949:	8d 50 18             	lea    0x18(%eax),%edx
8010194c:	8b 45 08             	mov    0x8(%ebp),%eax
8010194f:	8b 40 04             	mov    0x4(%eax),%eax
80101952:	83 e0 07             	and    $0x7,%eax
80101955:	c1 e0 06             	shl    $0x6,%eax
80101958:	01 d0                	add    %edx,%eax
8010195a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
8010195d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101960:	0f b7 10             	movzwl (%eax),%edx
80101963:	8b 45 08             	mov    0x8(%ebp),%eax
80101966:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010196a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010196d:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101971:	8b 45 08             	mov    0x8(%ebp),%eax
80101974:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101978:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010197b:	0f b7 50 04          	movzwl 0x4(%eax),%edx
8010197f:	8b 45 08             	mov    0x8(%ebp),%eax
80101982:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101986:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101989:	0f b7 50 06          	movzwl 0x6(%eax),%edx
8010198d:	8b 45 08             	mov    0x8(%ebp),%eax
80101990:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101994:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101997:	8b 50 08             	mov    0x8(%eax),%edx
8010199a:	8b 45 08             	mov    0x8(%ebp),%eax
8010199d:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801019a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019a3:	8d 50 0c             	lea    0xc(%eax),%edx
801019a6:	8b 45 08             	mov    0x8(%ebp),%eax
801019a9:	83 c0 1c             	add    $0x1c,%eax
801019ac:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801019b3:	00 
801019b4:	89 54 24 04          	mov    %edx,0x4(%esp)
801019b8:	89 04 24             	mov    %eax,(%esp)
801019bb:	e8 45 35 00 00       	call   80104f05 <memmove>
    brelse(bp);
801019c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019c3:	89 04 24             	mov    %eax,(%esp)
801019c6:	e8 4c e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
801019cb:	8b 45 08             	mov    0x8(%ebp),%eax
801019ce:	8b 40 0c             	mov    0xc(%eax),%eax
801019d1:	89 c2                	mov    %eax,%edx
801019d3:	83 ca 02             	or     $0x2,%edx
801019d6:	8b 45 08             	mov    0x8(%ebp),%eax
801019d9:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
801019dc:	8b 45 08             	mov    0x8(%ebp),%eax
801019df:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801019e3:	66 85 c0             	test   %ax,%ax
801019e6:	75 0c                	jne    801019f4 <ilock+0x14c>
      panic("ilock: no type");
801019e8:	c7 04 24 cd 82 10 80 	movl   $0x801082cd,(%esp)
801019ef:	e8 49 eb ff ff       	call   8010053d <panic>
  }
}
801019f4:	c9                   	leave  
801019f5:	c3                   	ret    

801019f6 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019f6:	55                   	push   %ebp
801019f7:	89 e5                	mov    %esp,%ebp
801019f9:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019fc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a00:	74 17                	je     80101a19 <iunlock+0x23>
80101a02:	8b 45 08             	mov    0x8(%ebp),%eax
80101a05:	8b 40 0c             	mov    0xc(%eax),%eax
80101a08:	83 e0 01             	and    $0x1,%eax
80101a0b:	85 c0                	test   %eax,%eax
80101a0d:	74 0a                	je     80101a19 <iunlock+0x23>
80101a0f:	8b 45 08             	mov    0x8(%ebp),%eax
80101a12:	8b 40 08             	mov    0x8(%eax),%eax
80101a15:	85 c0                	test   %eax,%eax
80101a17:	7f 0c                	jg     80101a25 <iunlock+0x2f>
    panic("iunlock");
80101a19:	c7 04 24 dc 82 10 80 	movl   $0x801082dc,(%esp)
80101a20:	e8 18 eb ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101a25:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101a2c:	e8 b2 31 00 00       	call   80104be3 <acquire>
  ip->flags &= ~I_BUSY;
80101a31:	8b 45 08             	mov    0x8(%ebp),%eax
80101a34:	8b 40 0c             	mov    0xc(%eax),%eax
80101a37:	89 c2                	mov    %eax,%edx
80101a39:	83 e2 fe             	and    $0xfffffffe,%edx
80101a3c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a3f:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101a42:	8b 45 08             	mov    0x8(%ebp),%eax
80101a45:	89 04 24             	mov    %eax,(%esp)
80101a48:	e8 91 2f 00 00       	call   801049de <wakeup>
  release(&icache.lock);
80101a4d:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101a54:	e8 ec 31 00 00       	call   80104c45 <release>
}
80101a59:	c9                   	leave  
80101a5a:	c3                   	ret    

80101a5b <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101a5b:	55                   	push   %ebp
80101a5c:	89 e5                	mov    %esp,%ebp
80101a5e:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a61:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101a68:	e8 76 31 00 00       	call   80104be3 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a70:	8b 40 08             	mov    0x8(%eax),%eax
80101a73:	83 f8 01             	cmp    $0x1,%eax
80101a76:	0f 85 93 00 00 00    	jne    80101b0f <iput+0xb4>
80101a7c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a7f:	8b 40 0c             	mov    0xc(%eax),%eax
80101a82:	83 e0 02             	and    $0x2,%eax
80101a85:	85 c0                	test   %eax,%eax
80101a87:	0f 84 82 00 00 00    	je     80101b0f <iput+0xb4>
80101a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a90:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a94:	66 85 c0             	test   %ax,%ax
80101a97:	75 76                	jne    80101b0f <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101a99:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9c:	8b 40 0c             	mov    0xc(%eax),%eax
80101a9f:	83 e0 01             	and    $0x1,%eax
80101aa2:	84 c0                	test   %al,%al
80101aa4:	74 0c                	je     80101ab2 <iput+0x57>
      panic("iput busy");
80101aa6:	c7 04 24 e4 82 10 80 	movl   $0x801082e4,(%esp)
80101aad:	e8 8b ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101ab2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab5:	8b 40 0c             	mov    0xc(%eax),%eax
80101ab8:	89 c2                	mov    %eax,%edx
80101aba:	83 ca 01             	or     $0x1,%edx
80101abd:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac0:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101ac3:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101aca:	e8 76 31 00 00       	call   80104c45 <release>
    itrunc(ip);
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	89 04 24             	mov    %eax,(%esp)
80101ad5:	e8 72 01 00 00       	call   80101c4c <itrunc>
    ip->type = 0;
80101ada:	8b 45 08             	mov    0x8(%ebp),%eax
80101add:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101ae3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae6:	89 04 24             	mov    %eax,(%esp)
80101ae9:	e8 fe fb ff ff       	call   801016ec <iupdate>
    acquire(&icache.lock);
80101aee:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101af5:	e8 e9 30 00 00       	call   80104be3 <acquire>
    ip->flags = 0;
80101afa:	8b 45 08             	mov    0x8(%ebp),%eax
80101afd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101b04:	8b 45 08             	mov    0x8(%ebp),%eax
80101b07:	89 04 24             	mov    %eax,(%esp)
80101b0a:	e8 cf 2e 00 00       	call   801049de <wakeup>
  }
  ip->ref--;
80101b0f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b12:	8b 40 08             	mov    0x8(%eax),%eax
80101b15:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b18:	8b 45 08             	mov    0x8(%ebp),%eax
80101b1b:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b1e:	c7 04 24 80 ed 10 80 	movl   $0x8010ed80,(%esp)
80101b25:	e8 1b 31 00 00       	call   80104c45 <release>
}
80101b2a:	c9                   	leave  
80101b2b:	c3                   	ret    

80101b2c <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b2c:	55                   	push   %ebp
80101b2d:	89 e5                	mov    %esp,%ebp
80101b2f:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b32:	8b 45 08             	mov    0x8(%ebp),%eax
80101b35:	89 04 24             	mov    %eax,(%esp)
80101b38:	e8 b9 fe ff ff       	call   801019f6 <iunlock>
  iput(ip);
80101b3d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b40:	89 04 24             	mov    %eax,(%esp)
80101b43:	e8 13 ff ff ff       	call   80101a5b <iput>
}
80101b48:	c9                   	leave  
80101b49:	c3                   	ret    

80101b4a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b4a:	55                   	push   %ebp
80101b4b:	89 e5                	mov    %esp,%ebp
80101b4d:	53                   	push   %ebx
80101b4e:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b51:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b55:	77 3e                	ja     80101b95 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b57:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5a:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b5d:	83 c2 04             	add    $0x4,%edx
80101b60:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b64:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b67:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b6b:	75 20                	jne    80101b8d <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b70:	8b 00                	mov    (%eax),%eax
80101b72:	89 04 24             	mov    %eax,(%esp)
80101b75:	e8 49 f8 ff ff       	call   801013c3 <balloc>
80101b7a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b80:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b83:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b86:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b89:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b90:	e9 b1 00 00 00       	jmp    80101c46 <bmap+0xfc>
  }
  bn -= NDIRECT;
80101b95:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b99:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b9d:	0f 87 97 00 00 00    	ja     80101c3a <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101ba3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba6:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ba9:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bac:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bb0:	75 19                	jne    80101bcb <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101bb2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb5:	8b 00                	mov    (%eax),%eax
80101bb7:	89 04 24             	mov    %eax,(%esp)
80101bba:	e8 04 f8 ff ff       	call   801013c3 <balloc>
80101bbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bc8:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101bcb:	8b 45 08             	mov    0x8(%ebp),%eax
80101bce:	8b 00                	mov    (%eax),%eax
80101bd0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bd3:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bd7:	89 04 24             	mov    %eax,(%esp)
80101bda:	e8 c7 e5 ff ff       	call   801001a6 <bread>
80101bdf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101be2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101be5:	83 c0 18             	add    $0x18,%eax
80101be8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101beb:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bee:	c1 e0 02             	shl    $0x2,%eax
80101bf1:	03 45 ec             	add    -0x14(%ebp),%eax
80101bf4:	8b 00                	mov    (%eax),%eax
80101bf6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bf9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bfd:	75 2b                	jne    80101c2a <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101bff:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c02:	c1 e0 02             	shl    $0x2,%eax
80101c05:	89 c3                	mov    %eax,%ebx
80101c07:	03 5d ec             	add    -0x14(%ebp),%ebx
80101c0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0d:	8b 00                	mov    (%eax),%eax
80101c0f:	89 04 24             	mov    %eax,(%esp)
80101c12:	e8 ac f7 ff ff       	call   801013c3 <balloc>
80101c17:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c1d:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c22:	89 04 24             	mov    %eax,(%esp)
80101c25:	e8 d4 16 00 00       	call   801032fe <log_write>
    }
    brelse(bp);
80101c2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c2d:	89 04 24             	mov    %eax,(%esp)
80101c30:	e8 e2 e5 ff ff       	call   80100217 <brelse>
    return addr;
80101c35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c38:	eb 0c                	jmp    80101c46 <bmap+0xfc>
  }

  panic("bmap: out of range");
80101c3a:	c7 04 24 ee 82 10 80 	movl   $0x801082ee,(%esp)
80101c41:	e8 f7 e8 ff ff       	call   8010053d <panic>
}
80101c46:	83 c4 24             	add    $0x24,%esp
80101c49:	5b                   	pop    %ebx
80101c4a:	5d                   	pop    %ebp
80101c4b:	c3                   	ret    

80101c4c <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c4c:	55                   	push   %ebp
80101c4d:	89 e5                	mov    %esp,%ebp
80101c4f:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c52:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c59:	eb 44                	jmp    80101c9f <itrunc+0x53>
    if(ip->addrs[i]){
80101c5b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c5e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c61:	83 c2 04             	add    $0x4,%edx
80101c64:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c68:	85 c0                	test   %eax,%eax
80101c6a:	74 2f                	je     80101c9b <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c6c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c6f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c72:	83 c2 04             	add    $0x4,%edx
80101c75:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c79:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7c:	8b 00                	mov    (%eax),%eax
80101c7e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c82:	89 04 24             	mov    %eax,(%esp)
80101c85:	e8 90 f8 ff ff       	call   8010151a <bfree>
      ip->addrs[i] = 0;
80101c8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c90:	83 c2 04             	add    $0x4,%edx
80101c93:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c9a:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c9b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c9f:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101ca3:	7e b6                	jle    80101c5b <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101ca5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca8:	8b 40 4c             	mov    0x4c(%eax),%eax
80101cab:	85 c0                	test   %eax,%eax
80101cad:	0f 84 8f 00 00 00    	je     80101d42 <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101cb3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb6:	8b 50 4c             	mov    0x4c(%eax),%edx
80101cb9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbc:	8b 00                	mov    (%eax),%eax
80101cbe:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cc2:	89 04 24             	mov    %eax,(%esp)
80101cc5:	e8 dc e4 ff ff       	call   801001a6 <bread>
80101cca:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101ccd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cd0:	83 c0 18             	add    $0x18,%eax
80101cd3:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101cd6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101cdd:	eb 2f                	jmp    80101d0e <itrunc+0xc2>
      if(a[j])
80101cdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ce2:	c1 e0 02             	shl    $0x2,%eax
80101ce5:	03 45 e8             	add    -0x18(%ebp),%eax
80101ce8:	8b 00                	mov    (%eax),%eax
80101cea:	85 c0                	test   %eax,%eax
80101cec:	74 1c                	je     80101d0a <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101cee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cf1:	c1 e0 02             	shl    $0x2,%eax
80101cf4:	03 45 e8             	add    -0x18(%ebp),%eax
80101cf7:	8b 10                	mov    (%eax),%edx
80101cf9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cfc:	8b 00                	mov    (%eax),%eax
80101cfe:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d02:	89 04 24             	mov    %eax,(%esp)
80101d05:	e8 10 f8 ff ff       	call   8010151a <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101d0a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d11:	83 f8 7f             	cmp    $0x7f,%eax
80101d14:	76 c9                	jbe    80101cdf <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101d16:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d19:	89 04 24             	mov    %eax,(%esp)
80101d1c:	e8 f6 e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101d21:	8b 45 08             	mov    0x8(%ebp),%eax
80101d24:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d27:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2a:	8b 00                	mov    (%eax),%eax
80101d2c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d30:	89 04 24             	mov    %eax,(%esp)
80101d33:	e8 e2 f7 ff ff       	call   8010151a <bfree>
    ip->addrs[NDIRECT] = 0;
80101d38:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3b:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d42:	8b 45 08             	mov    0x8(%ebp),%eax
80101d45:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4f:	89 04 24             	mov    %eax,(%esp)
80101d52:	e8 95 f9 ff ff       	call   801016ec <iupdate>
}
80101d57:	c9                   	leave  
80101d58:	c3                   	ret    

80101d59 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d59:	55                   	push   %ebp
80101d5a:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d5c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d5f:	8b 00                	mov    (%eax),%eax
80101d61:	89 c2                	mov    %eax,%edx
80101d63:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d66:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d69:	8b 45 08             	mov    0x8(%ebp),%eax
80101d6c:	8b 50 04             	mov    0x4(%eax),%edx
80101d6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d72:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d75:	8b 45 08             	mov    0x8(%ebp),%eax
80101d78:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d7c:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d7f:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d82:	8b 45 08             	mov    0x8(%ebp),%eax
80101d85:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d89:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d8c:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d90:	8b 45 08             	mov    0x8(%ebp),%eax
80101d93:	8b 50 18             	mov    0x18(%eax),%edx
80101d96:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d99:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d9c:	5d                   	pop    %ebp
80101d9d:	c3                   	ret    

80101d9e <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101d9e:	55                   	push   %ebp
80101d9f:	89 e5                	mov    %esp,%ebp
80101da1:	53                   	push   %ebx
80101da2:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101da5:	8b 45 08             	mov    0x8(%ebp),%eax
80101da8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101dac:	66 83 f8 03          	cmp    $0x3,%ax
80101db0:	75 60                	jne    80101e12 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101db2:	8b 45 08             	mov    0x8(%ebp),%eax
80101db5:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101db9:	66 85 c0             	test   %ax,%ax
80101dbc:	78 20                	js     80101dde <readi+0x40>
80101dbe:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc1:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dc5:	66 83 f8 09          	cmp    $0x9,%ax
80101dc9:	7f 13                	jg     80101dde <readi+0x40>
80101dcb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dce:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dd2:	98                   	cwtl   
80101dd3:	8b 04 c5 20 ed 10 80 	mov    -0x7fef12e0(,%eax,8),%eax
80101dda:	85 c0                	test   %eax,%eax
80101ddc:	75 0a                	jne    80101de8 <readi+0x4a>
      return -1;
80101dde:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101de3:	e9 1b 01 00 00       	jmp    80101f03 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101de8:	8b 45 08             	mov    0x8(%ebp),%eax
80101deb:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101def:	98                   	cwtl   
80101df0:	8b 14 c5 20 ed 10 80 	mov    -0x7fef12e0(,%eax,8),%edx
80101df7:	8b 45 14             	mov    0x14(%ebp),%eax
80101dfa:	89 44 24 08          	mov    %eax,0x8(%esp)
80101dfe:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e01:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e05:	8b 45 08             	mov    0x8(%ebp),%eax
80101e08:	89 04 24             	mov    %eax,(%esp)
80101e0b:	ff d2                	call   *%edx
80101e0d:	e9 f1 00 00 00       	jmp    80101f03 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80101e12:	8b 45 08             	mov    0x8(%ebp),%eax
80101e15:	8b 40 18             	mov    0x18(%eax),%eax
80101e18:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e1b:	72 0d                	jb     80101e2a <readi+0x8c>
80101e1d:	8b 45 14             	mov    0x14(%ebp),%eax
80101e20:	8b 55 10             	mov    0x10(%ebp),%edx
80101e23:	01 d0                	add    %edx,%eax
80101e25:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e28:	73 0a                	jae    80101e34 <readi+0x96>
    return -1;
80101e2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e2f:	e9 cf 00 00 00       	jmp    80101f03 <readi+0x165>
  if(off + n > ip->size)
80101e34:	8b 45 14             	mov    0x14(%ebp),%eax
80101e37:	8b 55 10             	mov    0x10(%ebp),%edx
80101e3a:	01 c2                	add    %eax,%edx
80101e3c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e3f:	8b 40 18             	mov    0x18(%eax),%eax
80101e42:	39 c2                	cmp    %eax,%edx
80101e44:	76 0c                	jbe    80101e52 <readi+0xb4>
    n = ip->size - off;
80101e46:	8b 45 08             	mov    0x8(%ebp),%eax
80101e49:	8b 40 18             	mov    0x18(%eax),%eax
80101e4c:	2b 45 10             	sub    0x10(%ebp),%eax
80101e4f:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e52:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e59:	e9 96 00 00 00       	jmp    80101ef4 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e5e:	8b 45 10             	mov    0x10(%ebp),%eax
80101e61:	c1 e8 09             	shr    $0x9,%eax
80101e64:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e68:	8b 45 08             	mov    0x8(%ebp),%eax
80101e6b:	89 04 24             	mov    %eax,(%esp)
80101e6e:	e8 d7 fc ff ff       	call   80101b4a <bmap>
80101e73:	8b 55 08             	mov    0x8(%ebp),%edx
80101e76:	8b 12                	mov    (%edx),%edx
80101e78:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e7c:	89 14 24             	mov    %edx,(%esp)
80101e7f:	e8 22 e3 ff ff       	call   801001a6 <bread>
80101e84:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e87:	8b 45 10             	mov    0x10(%ebp),%eax
80101e8a:	89 c2                	mov    %eax,%edx
80101e8c:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101e92:	b8 00 02 00 00       	mov    $0x200,%eax
80101e97:	89 c1                	mov    %eax,%ecx
80101e99:	29 d1                	sub    %edx,%ecx
80101e9b:	89 ca                	mov    %ecx,%edx
80101e9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ea0:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101ea3:	89 cb                	mov    %ecx,%ebx
80101ea5:	29 c3                	sub    %eax,%ebx
80101ea7:	89 d8                	mov    %ebx,%eax
80101ea9:	39 c2                	cmp    %eax,%edx
80101eab:	0f 46 c2             	cmovbe %edx,%eax
80101eae:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101eb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101eb4:	8d 50 18             	lea    0x18(%eax),%edx
80101eb7:	8b 45 10             	mov    0x10(%ebp),%eax
80101eba:	25 ff 01 00 00       	and    $0x1ff,%eax
80101ebf:	01 c2                	add    %eax,%edx
80101ec1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ec4:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ec8:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ecc:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ecf:	89 04 24             	mov    %eax,(%esp)
80101ed2:	e8 2e 30 00 00       	call   80104f05 <memmove>
    brelse(bp);
80101ed7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101eda:	89 04 24             	mov    %eax,(%esp)
80101edd:	e8 35 e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ee2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ee5:	01 45 f4             	add    %eax,-0xc(%ebp)
80101ee8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eeb:	01 45 10             	add    %eax,0x10(%ebp)
80101eee:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ef1:	01 45 0c             	add    %eax,0xc(%ebp)
80101ef4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ef7:	3b 45 14             	cmp    0x14(%ebp),%eax
80101efa:	0f 82 5e ff ff ff    	jb     80101e5e <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101f00:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101f03:	83 c4 24             	add    $0x24,%esp
80101f06:	5b                   	pop    %ebx
80101f07:	5d                   	pop    %ebp
80101f08:	c3                   	ret    

80101f09 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f09:	55                   	push   %ebp
80101f0a:	89 e5                	mov    %esp,%ebp
80101f0c:	53                   	push   %ebx
80101f0d:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f10:	8b 45 08             	mov    0x8(%ebp),%eax
80101f13:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f17:	66 83 f8 03          	cmp    $0x3,%ax
80101f1b:	75 60                	jne    80101f7d <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101f1d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f20:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f24:	66 85 c0             	test   %ax,%ax
80101f27:	78 20                	js     80101f49 <writei+0x40>
80101f29:	8b 45 08             	mov    0x8(%ebp),%eax
80101f2c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f30:	66 83 f8 09          	cmp    $0x9,%ax
80101f34:	7f 13                	jg     80101f49 <writei+0x40>
80101f36:	8b 45 08             	mov    0x8(%ebp),%eax
80101f39:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f3d:	98                   	cwtl   
80101f3e:	8b 04 c5 24 ed 10 80 	mov    -0x7fef12dc(,%eax,8),%eax
80101f45:	85 c0                	test   %eax,%eax
80101f47:	75 0a                	jne    80101f53 <writei+0x4a>
      return -1;
80101f49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f4e:	e9 46 01 00 00       	jmp    80102099 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f53:	8b 45 08             	mov    0x8(%ebp),%eax
80101f56:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f5a:	98                   	cwtl   
80101f5b:	8b 14 c5 24 ed 10 80 	mov    -0x7fef12dc(,%eax,8),%edx
80101f62:	8b 45 14             	mov    0x14(%ebp),%eax
80101f65:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f69:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f6c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f70:	8b 45 08             	mov    0x8(%ebp),%eax
80101f73:	89 04 24             	mov    %eax,(%esp)
80101f76:	ff d2                	call   *%edx
80101f78:	e9 1c 01 00 00       	jmp    80102099 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80101f7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f80:	8b 40 18             	mov    0x18(%eax),%eax
80101f83:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f86:	72 0d                	jb     80101f95 <writei+0x8c>
80101f88:	8b 45 14             	mov    0x14(%ebp),%eax
80101f8b:	8b 55 10             	mov    0x10(%ebp),%edx
80101f8e:	01 d0                	add    %edx,%eax
80101f90:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f93:	73 0a                	jae    80101f9f <writei+0x96>
    return -1;
80101f95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f9a:	e9 fa 00 00 00       	jmp    80102099 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80101f9f:	8b 45 14             	mov    0x14(%ebp),%eax
80101fa2:	8b 55 10             	mov    0x10(%ebp),%edx
80101fa5:	01 d0                	add    %edx,%eax
80101fa7:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101fac:	76 0a                	jbe    80101fb8 <writei+0xaf>
    return -1;
80101fae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fb3:	e9 e1 00 00 00       	jmp    80102099 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101fb8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fbf:	e9 a1 00 00 00       	jmp    80102065 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fc4:	8b 45 10             	mov    0x10(%ebp),%eax
80101fc7:	c1 e8 09             	shr    $0x9,%eax
80101fca:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fce:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd1:	89 04 24             	mov    %eax,(%esp)
80101fd4:	e8 71 fb ff ff       	call   80101b4a <bmap>
80101fd9:	8b 55 08             	mov    0x8(%ebp),%edx
80101fdc:	8b 12                	mov    (%edx),%edx
80101fde:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fe2:	89 14 24             	mov    %edx,(%esp)
80101fe5:	e8 bc e1 ff ff       	call   801001a6 <bread>
80101fea:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fed:	8b 45 10             	mov    0x10(%ebp),%eax
80101ff0:	89 c2                	mov    %eax,%edx
80101ff2:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101ff8:	b8 00 02 00 00       	mov    $0x200,%eax
80101ffd:	89 c1                	mov    %eax,%ecx
80101fff:	29 d1                	sub    %edx,%ecx
80102001:	89 ca                	mov    %ecx,%edx
80102003:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102006:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102009:	89 cb                	mov    %ecx,%ebx
8010200b:	29 c3                	sub    %eax,%ebx
8010200d:	89 d8                	mov    %ebx,%eax
8010200f:	39 c2                	cmp    %eax,%edx
80102011:	0f 46 c2             	cmovbe %edx,%eax
80102014:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102017:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010201a:	8d 50 18             	lea    0x18(%eax),%edx
8010201d:	8b 45 10             	mov    0x10(%ebp),%eax
80102020:	25 ff 01 00 00       	and    $0x1ff,%eax
80102025:	01 c2                	add    %eax,%edx
80102027:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010202a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010202e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102031:	89 44 24 04          	mov    %eax,0x4(%esp)
80102035:	89 14 24             	mov    %edx,(%esp)
80102038:	e8 c8 2e 00 00       	call   80104f05 <memmove>
    log_write(bp);
8010203d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102040:	89 04 24             	mov    %eax,(%esp)
80102043:	e8 b6 12 00 00       	call   801032fe <log_write>
    brelse(bp);
80102048:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010204b:	89 04 24             	mov    %eax,(%esp)
8010204e:	e8 c4 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102053:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102056:	01 45 f4             	add    %eax,-0xc(%ebp)
80102059:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010205c:	01 45 10             	add    %eax,0x10(%ebp)
8010205f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102062:	01 45 0c             	add    %eax,0xc(%ebp)
80102065:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102068:	3b 45 14             	cmp    0x14(%ebp),%eax
8010206b:	0f 82 53 ff ff ff    	jb     80101fc4 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102071:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102075:	74 1f                	je     80102096 <writei+0x18d>
80102077:	8b 45 08             	mov    0x8(%ebp),%eax
8010207a:	8b 40 18             	mov    0x18(%eax),%eax
8010207d:	3b 45 10             	cmp    0x10(%ebp),%eax
80102080:	73 14                	jae    80102096 <writei+0x18d>
    ip->size = off;
80102082:	8b 45 08             	mov    0x8(%ebp),%eax
80102085:	8b 55 10             	mov    0x10(%ebp),%edx
80102088:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
8010208b:	8b 45 08             	mov    0x8(%ebp),%eax
8010208e:	89 04 24             	mov    %eax,(%esp)
80102091:	e8 56 f6 ff ff       	call   801016ec <iupdate>
  }
  return n;
80102096:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102099:	83 c4 24             	add    $0x24,%esp
8010209c:	5b                   	pop    %ebx
8010209d:	5d                   	pop    %ebp
8010209e:	c3                   	ret    

8010209f <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
8010209f:	55                   	push   %ebp
801020a0:	89 e5                	mov    %esp,%ebp
801020a2:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801020a5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801020ac:	00 
801020ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801020b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801020b4:	8b 45 08             	mov    0x8(%ebp),%eax
801020b7:	89 04 24             	mov    %eax,(%esp)
801020ba:	e8 ea 2e 00 00       	call   80104fa9 <strncmp>
}
801020bf:	c9                   	leave  
801020c0:	c3                   	ret    

801020c1 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801020c1:	55                   	push   %ebp
801020c2:	89 e5                	mov    %esp,%ebp
801020c4:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801020c7:	8b 45 08             	mov    0x8(%ebp),%eax
801020ca:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801020ce:	66 83 f8 01          	cmp    $0x1,%ax
801020d2:	74 0c                	je     801020e0 <dirlookup+0x1f>
    panic("dirlookup not DIR");
801020d4:	c7 04 24 01 83 10 80 	movl   $0x80108301,(%esp)
801020db:	e8 5d e4 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801020e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020e7:	e9 87 00 00 00       	jmp    80102173 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801020ec:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801020f3:	00 
801020f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020f7:	89 44 24 08          	mov    %eax,0x8(%esp)
801020fb:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80102102:	8b 45 08             	mov    0x8(%ebp),%eax
80102105:	89 04 24             	mov    %eax,(%esp)
80102108:	e8 91 fc ff ff       	call   80101d9e <readi>
8010210d:	83 f8 10             	cmp    $0x10,%eax
80102110:	74 0c                	je     8010211e <dirlookup+0x5d>
      panic("dirlink read");
80102112:	c7 04 24 13 83 10 80 	movl   $0x80108313,(%esp)
80102119:	e8 1f e4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
8010211e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102122:	66 85 c0             	test   %ax,%ax
80102125:	74 47                	je     8010216e <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102127:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010212a:	83 c0 02             	add    $0x2,%eax
8010212d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102131:	8b 45 0c             	mov    0xc(%ebp),%eax
80102134:	89 04 24             	mov    %eax,(%esp)
80102137:	e8 63 ff ff ff       	call   8010209f <namecmp>
8010213c:	85 c0                	test   %eax,%eax
8010213e:	75 2f                	jne    8010216f <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102140:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102144:	74 08                	je     8010214e <dirlookup+0x8d>
        *poff = off;
80102146:	8b 45 10             	mov    0x10(%ebp),%eax
80102149:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010214c:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010214e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102152:	0f b7 c0             	movzwl %ax,%eax
80102155:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102158:	8b 45 08             	mov    0x8(%ebp),%eax
8010215b:	8b 00                	mov    (%eax),%eax
8010215d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102160:	89 54 24 04          	mov    %edx,0x4(%esp)
80102164:	89 04 24             	mov    %eax,(%esp)
80102167:	e8 38 f6 ff ff       	call   801017a4 <iget>
8010216c:	eb 19                	jmp    80102187 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
8010216e:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010216f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102173:	8b 45 08             	mov    0x8(%ebp),%eax
80102176:	8b 40 18             	mov    0x18(%eax),%eax
80102179:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010217c:	0f 87 6a ff ff ff    	ja     801020ec <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102182:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102187:	c9                   	leave  
80102188:	c3                   	ret    

80102189 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102189:	55                   	push   %ebp
8010218a:	89 e5                	mov    %esp,%ebp
8010218c:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
8010218f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102196:	00 
80102197:	8b 45 0c             	mov    0xc(%ebp),%eax
8010219a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010219e:	8b 45 08             	mov    0x8(%ebp),%eax
801021a1:	89 04 24             	mov    %eax,(%esp)
801021a4:	e8 18 ff ff ff       	call   801020c1 <dirlookup>
801021a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801021ac:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801021b0:	74 15                	je     801021c7 <dirlink+0x3e>
    iput(ip);
801021b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021b5:	89 04 24             	mov    %eax,(%esp)
801021b8:	e8 9e f8 ff ff       	call   80101a5b <iput>
    return -1;
801021bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021c2:	e9 b8 00 00 00       	jmp    8010227f <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801021c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021ce:	eb 44                	jmp    80102214 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801021d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021d3:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801021da:	00 
801021db:	89 44 24 08          	mov    %eax,0x8(%esp)
801021df:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021e2:	89 44 24 04          	mov    %eax,0x4(%esp)
801021e6:	8b 45 08             	mov    0x8(%ebp),%eax
801021e9:	89 04 24             	mov    %eax,(%esp)
801021ec:	e8 ad fb ff ff       	call   80101d9e <readi>
801021f1:	83 f8 10             	cmp    $0x10,%eax
801021f4:	74 0c                	je     80102202 <dirlink+0x79>
      panic("dirlink read");
801021f6:	c7 04 24 13 83 10 80 	movl   $0x80108313,(%esp)
801021fd:	e8 3b e3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102202:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102206:	66 85 c0             	test   %ax,%ax
80102209:	74 18                	je     80102223 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010220b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010220e:	83 c0 10             	add    $0x10,%eax
80102211:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102214:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102217:	8b 45 08             	mov    0x8(%ebp),%eax
8010221a:	8b 40 18             	mov    0x18(%eax),%eax
8010221d:	39 c2                	cmp    %eax,%edx
8010221f:	72 af                	jb     801021d0 <dirlink+0x47>
80102221:	eb 01                	jmp    80102224 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102223:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102224:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010222b:	00 
8010222c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010222f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102233:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102236:	83 c0 02             	add    $0x2,%eax
80102239:	89 04 24             	mov    %eax,(%esp)
8010223c:	e8 c0 2d 00 00       	call   80105001 <strncpy>
  de.inum = inum;
80102241:	8b 45 10             	mov    0x10(%ebp),%eax
80102244:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102248:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010224b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102252:	00 
80102253:	89 44 24 08          	mov    %eax,0x8(%esp)
80102257:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010225a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010225e:	8b 45 08             	mov    0x8(%ebp),%eax
80102261:	89 04 24             	mov    %eax,(%esp)
80102264:	e8 a0 fc ff ff       	call   80101f09 <writei>
80102269:	83 f8 10             	cmp    $0x10,%eax
8010226c:	74 0c                	je     8010227a <dirlink+0xf1>
    panic("dirlink");
8010226e:	c7 04 24 20 83 10 80 	movl   $0x80108320,(%esp)
80102275:	e8 c3 e2 ff ff       	call   8010053d <panic>
  
  return 0;
8010227a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010227f:	c9                   	leave  
80102280:	c3                   	ret    

80102281 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102281:	55                   	push   %ebp
80102282:	89 e5                	mov    %esp,%ebp
80102284:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102287:	eb 04                	jmp    8010228d <skipelem+0xc>
    path++;
80102289:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
8010228d:	8b 45 08             	mov    0x8(%ebp),%eax
80102290:	0f b6 00             	movzbl (%eax),%eax
80102293:	3c 2f                	cmp    $0x2f,%al
80102295:	74 f2                	je     80102289 <skipelem+0x8>
    path++;
  if(*path == 0)
80102297:	8b 45 08             	mov    0x8(%ebp),%eax
8010229a:	0f b6 00             	movzbl (%eax),%eax
8010229d:	84 c0                	test   %al,%al
8010229f:	75 0a                	jne    801022ab <skipelem+0x2a>
    return 0;
801022a1:	b8 00 00 00 00       	mov    $0x0,%eax
801022a6:	e9 86 00 00 00       	jmp    80102331 <skipelem+0xb0>
  s = path;
801022ab:	8b 45 08             	mov    0x8(%ebp),%eax
801022ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801022b1:	eb 04                	jmp    801022b7 <skipelem+0x36>
    path++;
801022b3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801022b7:	8b 45 08             	mov    0x8(%ebp),%eax
801022ba:	0f b6 00             	movzbl (%eax),%eax
801022bd:	3c 2f                	cmp    $0x2f,%al
801022bf:	74 0a                	je     801022cb <skipelem+0x4a>
801022c1:	8b 45 08             	mov    0x8(%ebp),%eax
801022c4:	0f b6 00             	movzbl (%eax),%eax
801022c7:	84 c0                	test   %al,%al
801022c9:	75 e8                	jne    801022b3 <skipelem+0x32>
    path++;
  len = path - s;
801022cb:	8b 55 08             	mov    0x8(%ebp),%edx
801022ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022d1:	89 d1                	mov    %edx,%ecx
801022d3:	29 c1                	sub    %eax,%ecx
801022d5:	89 c8                	mov    %ecx,%eax
801022d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801022da:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801022de:	7e 1c                	jle    801022fc <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801022e0:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022e7:	00 
801022e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801022f2:	89 04 24             	mov    %eax,(%esp)
801022f5:	e8 0b 2c 00 00       	call   80104f05 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022fa:	eb 28                	jmp    80102324 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801022fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022ff:	89 44 24 08          	mov    %eax,0x8(%esp)
80102303:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102306:	89 44 24 04          	mov    %eax,0x4(%esp)
8010230a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010230d:	89 04 24             	mov    %eax,(%esp)
80102310:	e8 f0 2b 00 00       	call   80104f05 <memmove>
    name[len] = 0;
80102315:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102318:	03 45 0c             	add    0xc(%ebp),%eax
8010231b:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010231e:	eb 04                	jmp    80102324 <skipelem+0xa3>
    path++;
80102320:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102324:	8b 45 08             	mov    0x8(%ebp),%eax
80102327:	0f b6 00             	movzbl (%eax),%eax
8010232a:	3c 2f                	cmp    $0x2f,%al
8010232c:	74 f2                	je     80102320 <skipelem+0x9f>
    path++;
  return path;
8010232e:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102331:	c9                   	leave  
80102332:	c3                   	ret    

80102333 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102333:	55                   	push   %ebp
80102334:	89 e5                	mov    %esp,%ebp
80102336:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102339:	8b 45 08             	mov    0x8(%ebp),%eax
8010233c:	0f b6 00             	movzbl (%eax),%eax
8010233f:	3c 2f                	cmp    $0x2f,%al
80102341:	75 1c                	jne    8010235f <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102343:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010234a:	00 
8010234b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102352:	e8 4d f4 ff ff       	call   801017a4 <iget>
80102357:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010235a:	e9 af 00 00 00       	jmp    8010240e <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010235f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102365:	8b 40 68             	mov    0x68(%eax),%eax
80102368:	89 04 24             	mov    %eax,(%esp)
8010236b:	e8 06 f5 ff ff       	call   80101876 <idup>
80102370:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102373:	e9 96 00 00 00       	jmp    8010240e <namex+0xdb>
    ilock(ip);
80102378:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010237b:	89 04 24             	mov    %eax,(%esp)
8010237e:	e8 25 f5 ff ff       	call   801018a8 <ilock>
    if(ip->type != T_DIR){
80102383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102386:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010238a:	66 83 f8 01          	cmp    $0x1,%ax
8010238e:	74 15                	je     801023a5 <namex+0x72>
      iunlockput(ip);
80102390:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102393:	89 04 24             	mov    %eax,(%esp)
80102396:	e8 91 f7 ff ff       	call   80101b2c <iunlockput>
      return 0;
8010239b:	b8 00 00 00 00       	mov    $0x0,%eax
801023a0:	e9 a3 00 00 00       	jmp    80102448 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801023a5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023a9:	74 1d                	je     801023c8 <namex+0x95>
801023ab:	8b 45 08             	mov    0x8(%ebp),%eax
801023ae:	0f b6 00             	movzbl (%eax),%eax
801023b1:	84 c0                	test   %al,%al
801023b3:	75 13                	jne    801023c8 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
801023b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023b8:	89 04 24             	mov    %eax,(%esp)
801023bb:	e8 36 f6 ff ff       	call   801019f6 <iunlock>
      return ip;
801023c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023c3:	e9 80 00 00 00       	jmp    80102448 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801023c8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801023cf:	00 
801023d0:	8b 45 10             	mov    0x10(%ebp),%eax
801023d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801023d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023da:	89 04 24             	mov    %eax,(%esp)
801023dd:	e8 df fc ff ff       	call   801020c1 <dirlookup>
801023e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
801023e5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023e9:	75 12                	jne    801023fd <namex+0xca>
      iunlockput(ip);
801023eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ee:	89 04 24             	mov    %eax,(%esp)
801023f1:	e8 36 f7 ff ff       	call   80101b2c <iunlockput>
      return 0;
801023f6:	b8 00 00 00 00       	mov    $0x0,%eax
801023fb:	eb 4b                	jmp    80102448 <namex+0x115>
    }
    iunlockput(ip);
801023fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102400:	89 04 24             	mov    %eax,(%esp)
80102403:	e8 24 f7 ff ff       	call   80101b2c <iunlockput>
    ip = next;
80102408:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010240b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010240e:	8b 45 10             	mov    0x10(%ebp),%eax
80102411:	89 44 24 04          	mov    %eax,0x4(%esp)
80102415:	8b 45 08             	mov    0x8(%ebp),%eax
80102418:	89 04 24             	mov    %eax,(%esp)
8010241b:	e8 61 fe ff ff       	call   80102281 <skipelem>
80102420:	89 45 08             	mov    %eax,0x8(%ebp)
80102423:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102427:	0f 85 4b ff ff ff    	jne    80102378 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
8010242d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102431:	74 12                	je     80102445 <namex+0x112>
    iput(ip);
80102433:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102436:	89 04 24             	mov    %eax,(%esp)
80102439:	e8 1d f6 ff ff       	call   80101a5b <iput>
    return 0;
8010243e:	b8 00 00 00 00       	mov    $0x0,%eax
80102443:	eb 03                	jmp    80102448 <namex+0x115>
  }
  return ip;
80102445:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102448:	c9                   	leave  
80102449:	c3                   	ret    

8010244a <namei>:

struct inode*
namei(char *path)
{
8010244a:	55                   	push   %ebp
8010244b:	89 e5                	mov    %esp,%ebp
8010244d:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102450:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102453:	89 44 24 08          	mov    %eax,0x8(%esp)
80102457:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010245e:	00 
8010245f:	8b 45 08             	mov    0x8(%ebp),%eax
80102462:	89 04 24             	mov    %eax,(%esp)
80102465:	e8 c9 fe ff ff       	call   80102333 <namex>
}
8010246a:	c9                   	leave  
8010246b:	c3                   	ret    

8010246c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
8010246c:	55                   	push   %ebp
8010246d:	89 e5                	mov    %esp,%ebp
8010246f:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102472:	8b 45 0c             	mov    0xc(%ebp),%eax
80102475:	89 44 24 08          	mov    %eax,0x8(%esp)
80102479:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102480:	00 
80102481:	8b 45 08             	mov    0x8(%ebp),%eax
80102484:	89 04 24             	mov    %eax,(%esp)
80102487:	e8 a7 fe ff ff       	call   80102333 <namex>
}
8010248c:	c9                   	leave  
8010248d:	c3                   	ret    
	...

80102490 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102490:	55                   	push   %ebp
80102491:	89 e5                	mov    %esp,%ebp
80102493:	53                   	push   %ebx
80102494:	83 ec 14             	sub    $0x14,%esp
80102497:	8b 45 08             	mov    0x8(%ebp),%eax
8010249a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010249e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801024a2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801024a6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801024aa:	ec                   	in     (%dx),%al
801024ab:	89 c3                	mov    %eax,%ebx
801024ad:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801024b0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801024b4:	83 c4 14             	add    $0x14,%esp
801024b7:	5b                   	pop    %ebx
801024b8:	5d                   	pop    %ebp
801024b9:	c3                   	ret    

801024ba <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801024ba:	55                   	push   %ebp
801024bb:	89 e5                	mov    %esp,%ebp
801024bd:	57                   	push   %edi
801024be:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801024bf:	8b 55 08             	mov    0x8(%ebp),%edx
801024c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801024c5:	8b 45 10             	mov    0x10(%ebp),%eax
801024c8:	89 cb                	mov    %ecx,%ebx
801024ca:	89 df                	mov    %ebx,%edi
801024cc:	89 c1                	mov    %eax,%ecx
801024ce:	fc                   	cld    
801024cf:	f3 6d                	rep insl (%dx),%es:(%edi)
801024d1:	89 c8                	mov    %ecx,%eax
801024d3:	89 fb                	mov    %edi,%ebx
801024d5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801024d8:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801024db:	5b                   	pop    %ebx
801024dc:	5f                   	pop    %edi
801024dd:	5d                   	pop    %ebp
801024de:	c3                   	ret    

801024df <outb>:

static inline void
outb(ushort port, uchar data)
{
801024df:	55                   	push   %ebp
801024e0:	89 e5                	mov    %esp,%ebp
801024e2:	83 ec 08             	sub    $0x8,%esp
801024e5:	8b 55 08             	mov    0x8(%ebp),%edx
801024e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801024eb:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801024ef:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024f2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801024f6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801024fa:	ee                   	out    %al,(%dx)
}
801024fb:	c9                   	leave  
801024fc:	c3                   	ret    

801024fd <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801024fd:	55                   	push   %ebp
801024fe:	89 e5                	mov    %esp,%ebp
80102500:	56                   	push   %esi
80102501:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102502:	8b 55 08             	mov    0x8(%ebp),%edx
80102505:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102508:	8b 45 10             	mov    0x10(%ebp),%eax
8010250b:	89 cb                	mov    %ecx,%ebx
8010250d:	89 de                	mov    %ebx,%esi
8010250f:	89 c1                	mov    %eax,%ecx
80102511:	fc                   	cld    
80102512:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102514:	89 c8                	mov    %ecx,%eax
80102516:	89 f3                	mov    %esi,%ebx
80102518:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010251b:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010251e:	5b                   	pop    %ebx
8010251f:	5e                   	pop    %esi
80102520:	5d                   	pop    %ebp
80102521:	c3                   	ret    

80102522 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102522:	55                   	push   %ebp
80102523:	89 e5                	mov    %esp,%ebp
80102525:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102528:	90                   	nop
80102529:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102530:	e8 5b ff ff ff       	call   80102490 <inb>
80102535:	0f b6 c0             	movzbl %al,%eax
80102538:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010253b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010253e:	25 c0 00 00 00       	and    $0xc0,%eax
80102543:	83 f8 40             	cmp    $0x40,%eax
80102546:	75 e1                	jne    80102529 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102548:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010254c:	74 11                	je     8010255f <idewait+0x3d>
8010254e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102551:	83 e0 21             	and    $0x21,%eax
80102554:	85 c0                	test   %eax,%eax
80102556:	74 07                	je     8010255f <idewait+0x3d>
    return -1;
80102558:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010255d:	eb 05                	jmp    80102564 <idewait+0x42>
  return 0;
8010255f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102564:	c9                   	leave  
80102565:	c3                   	ret    

80102566 <ideinit>:

void
ideinit(void)
{
80102566:	55                   	push   %ebp
80102567:	89 e5                	mov    %esp,%ebp
80102569:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
8010256c:	c7 44 24 04 28 83 10 	movl   $0x80108328,0x4(%esp)
80102573:	80 
80102574:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010257b:	e8 42 26 00 00       	call   80104bc2 <initlock>
  picenable(IRQ_IDE);
80102580:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102587:	e8 75 15 00 00       	call   80103b01 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
8010258c:	a1 20 04 11 80       	mov    0x80110420,%eax
80102591:	83 e8 01             	sub    $0x1,%eax
80102594:	89 44 24 04          	mov    %eax,0x4(%esp)
80102598:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010259f:	e8 12 04 00 00       	call   801029b6 <ioapicenable>
  idewait(0);
801025a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025ab:	e8 72 ff ff ff       	call   80102522 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801025b0:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801025b7:	00 
801025b8:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025bf:	e8 1b ff ff ff       	call   801024df <outb>
  for(i=0; i<1000; i++){
801025c4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801025cb:	eb 20                	jmp    801025ed <ideinit+0x87>
    if(inb(0x1f7) != 0){
801025cd:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801025d4:	e8 b7 fe ff ff       	call   80102490 <inb>
801025d9:	84 c0                	test   %al,%al
801025db:	74 0c                	je     801025e9 <ideinit+0x83>
      havedisk1 = 1;
801025dd:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
801025e4:	00 00 00 
      break;
801025e7:	eb 0d                	jmp    801025f6 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801025e9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801025ed:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801025f4:	7e d7                	jle    801025cd <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801025f6:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801025fd:	00 
801025fe:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102605:	e8 d5 fe ff ff       	call   801024df <outb>
}
8010260a:	c9                   	leave  
8010260b:	c3                   	ret    

8010260c <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
8010260c:	55                   	push   %ebp
8010260d:	89 e5                	mov    %esp,%ebp
8010260f:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80102612:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102616:	75 0c                	jne    80102624 <idestart+0x18>
    panic("idestart");
80102618:	c7 04 24 2c 83 10 80 	movl   $0x8010832c,(%esp)
8010261f:	e8 19 df ff ff       	call   8010053d <panic>

  idewait(0);
80102624:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010262b:	e8 f2 fe ff ff       	call   80102522 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102630:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102637:	00 
80102638:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
8010263f:	e8 9b fe ff ff       	call   801024df <outb>
  outb(0x1f2, 1);  // number of sectors
80102644:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010264b:	00 
8010264c:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102653:	e8 87 fe ff ff       	call   801024df <outb>
  outb(0x1f3, b->sector & 0xff);
80102658:	8b 45 08             	mov    0x8(%ebp),%eax
8010265b:	8b 40 08             	mov    0x8(%eax),%eax
8010265e:	0f b6 c0             	movzbl %al,%eax
80102661:	89 44 24 04          	mov    %eax,0x4(%esp)
80102665:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
8010266c:	e8 6e fe ff ff       	call   801024df <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102671:	8b 45 08             	mov    0x8(%ebp),%eax
80102674:	8b 40 08             	mov    0x8(%eax),%eax
80102677:	c1 e8 08             	shr    $0x8,%eax
8010267a:	0f b6 c0             	movzbl %al,%eax
8010267d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102681:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102688:	e8 52 fe ff ff       	call   801024df <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
8010268d:	8b 45 08             	mov    0x8(%ebp),%eax
80102690:	8b 40 08             	mov    0x8(%eax),%eax
80102693:	c1 e8 10             	shr    $0x10,%eax
80102696:	0f b6 c0             	movzbl %al,%eax
80102699:	89 44 24 04          	mov    %eax,0x4(%esp)
8010269d:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
801026a4:	e8 36 fe ff ff       	call   801024df <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801026a9:	8b 45 08             	mov    0x8(%ebp),%eax
801026ac:	8b 40 04             	mov    0x4(%eax),%eax
801026af:	83 e0 01             	and    $0x1,%eax
801026b2:	89 c2                	mov    %eax,%edx
801026b4:	c1 e2 04             	shl    $0x4,%edx
801026b7:	8b 45 08             	mov    0x8(%ebp),%eax
801026ba:	8b 40 08             	mov    0x8(%eax),%eax
801026bd:	c1 e8 18             	shr    $0x18,%eax
801026c0:	83 e0 0f             	and    $0xf,%eax
801026c3:	09 d0                	or     %edx,%eax
801026c5:	83 c8 e0             	or     $0xffffffe0,%eax
801026c8:	0f b6 c0             	movzbl %al,%eax
801026cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801026cf:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026d6:	e8 04 fe ff ff       	call   801024df <outb>
  if(b->flags & B_DIRTY){
801026db:	8b 45 08             	mov    0x8(%ebp),%eax
801026de:	8b 00                	mov    (%eax),%eax
801026e0:	83 e0 04             	and    $0x4,%eax
801026e3:	85 c0                	test   %eax,%eax
801026e5:	74 34                	je     8010271b <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801026e7:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801026ee:	00 
801026ef:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026f6:	e8 e4 fd ff ff       	call   801024df <outb>
    outsl(0x1f0, b->data, 512/4);
801026fb:	8b 45 08             	mov    0x8(%ebp),%eax
801026fe:	83 c0 18             	add    $0x18,%eax
80102701:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102708:	00 
80102709:	89 44 24 04          	mov    %eax,0x4(%esp)
8010270d:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102714:	e8 e4 fd ff ff       	call   801024fd <outsl>
80102719:	eb 14                	jmp    8010272f <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
8010271b:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102722:	00 
80102723:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010272a:	e8 b0 fd ff ff       	call   801024df <outb>
  }
}
8010272f:	c9                   	leave  
80102730:	c3                   	ret    

80102731 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102731:	55                   	push   %ebp
80102732:	89 e5                	mov    %esp,%ebp
80102734:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102737:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010273e:	e8 a0 24 00 00       	call   80104be3 <acquire>
  if((b = idequeue) == 0){
80102743:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102748:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010274b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010274f:	75 11                	jne    80102762 <ideintr+0x31>
    release(&idelock);
80102751:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102758:	e8 e8 24 00 00       	call   80104c45 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
8010275d:	e9 90 00 00 00       	jmp    801027f2 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102762:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102765:	8b 40 14             	mov    0x14(%eax),%eax
80102768:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
8010276d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102770:	8b 00                	mov    (%eax),%eax
80102772:	83 e0 04             	and    $0x4,%eax
80102775:	85 c0                	test   %eax,%eax
80102777:	75 2e                	jne    801027a7 <ideintr+0x76>
80102779:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102780:	e8 9d fd ff ff       	call   80102522 <idewait>
80102785:	85 c0                	test   %eax,%eax
80102787:	78 1e                	js     801027a7 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102789:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010278c:	83 c0 18             	add    $0x18,%eax
8010278f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102796:	00 
80102797:	89 44 24 04          	mov    %eax,0x4(%esp)
8010279b:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801027a2:	e8 13 fd ff ff       	call   801024ba <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801027a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027aa:	8b 00                	mov    (%eax),%eax
801027ac:	89 c2                	mov    %eax,%edx
801027ae:	83 ca 02             	or     $0x2,%edx
801027b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027b4:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801027b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027b9:	8b 00                	mov    (%eax),%eax
801027bb:	89 c2                	mov    %eax,%edx
801027bd:	83 e2 fb             	and    $0xfffffffb,%edx
801027c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027c3:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801027c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027c8:	89 04 24             	mov    %eax,(%esp)
801027cb:	e8 0e 22 00 00       	call   801049de <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801027d0:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027d5:	85 c0                	test   %eax,%eax
801027d7:	74 0d                	je     801027e6 <ideintr+0xb5>
    idestart(idequeue);
801027d9:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027de:	89 04 24             	mov    %eax,(%esp)
801027e1:	e8 26 fe ff ff       	call   8010260c <idestart>

  release(&idelock);
801027e6:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027ed:	e8 53 24 00 00       	call   80104c45 <release>
}
801027f2:	c9                   	leave  
801027f3:	c3                   	ret    

801027f4 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801027f4:	55                   	push   %ebp
801027f5:	89 e5                	mov    %esp,%ebp
801027f7:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801027fa:	8b 45 08             	mov    0x8(%ebp),%eax
801027fd:	8b 00                	mov    (%eax),%eax
801027ff:	83 e0 01             	and    $0x1,%eax
80102802:	85 c0                	test   %eax,%eax
80102804:	75 0c                	jne    80102812 <iderw+0x1e>
    panic("iderw: buf not busy");
80102806:	c7 04 24 35 83 10 80 	movl   $0x80108335,(%esp)
8010280d:	e8 2b dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102812:	8b 45 08             	mov    0x8(%ebp),%eax
80102815:	8b 00                	mov    (%eax),%eax
80102817:	83 e0 06             	and    $0x6,%eax
8010281a:	83 f8 02             	cmp    $0x2,%eax
8010281d:	75 0c                	jne    8010282b <iderw+0x37>
    panic("iderw: nothing to do");
8010281f:	c7 04 24 49 83 10 80 	movl   $0x80108349,(%esp)
80102826:	e8 12 dd ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
8010282b:	8b 45 08             	mov    0x8(%ebp),%eax
8010282e:	8b 40 04             	mov    0x4(%eax),%eax
80102831:	85 c0                	test   %eax,%eax
80102833:	74 15                	je     8010284a <iderw+0x56>
80102835:	a1 38 b6 10 80       	mov    0x8010b638,%eax
8010283a:	85 c0                	test   %eax,%eax
8010283c:	75 0c                	jne    8010284a <iderw+0x56>
    panic("iderw: ide disk 1 not present");
8010283e:	c7 04 24 5e 83 10 80 	movl   $0x8010835e,(%esp)
80102845:	e8 f3 dc ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
8010284a:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102851:	e8 8d 23 00 00       	call   80104be3 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102856:	8b 45 08             	mov    0x8(%ebp),%eax
80102859:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80102860:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
80102867:	eb 0b                	jmp    80102874 <iderw+0x80>
80102869:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010286c:	8b 00                	mov    (%eax),%eax
8010286e:	83 c0 14             	add    $0x14,%eax
80102871:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102874:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102877:	8b 00                	mov    (%eax),%eax
80102879:	85 c0                	test   %eax,%eax
8010287b:	75 ec                	jne    80102869 <iderw+0x75>
    ;
  *pp = b;
8010287d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102880:	8b 55 08             	mov    0x8(%ebp),%edx
80102883:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102885:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010288a:	3b 45 08             	cmp    0x8(%ebp),%eax
8010288d:	75 22                	jne    801028b1 <iderw+0xbd>
    idestart(b);
8010288f:	8b 45 08             	mov    0x8(%ebp),%eax
80102892:	89 04 24             	mov    %eax,(%esp)
80102895:	e8 72 fd ff ff       	call   8010260c <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
8010289a:	eb 15                	jmp    801028b1 <iderw+0xbd>
    sleep(b, &idelock);
8010289c:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
801028a3:	80 
801028a4:	8b 45 08             	mov    0x8(%ebp),%eax
801028a7:	89 04 24             	mov    %eax,(%esp)
801028aa:	e8 56 20 00 00       	call   80104905 <sleep>
801028af:	eb 01                	jmp    801028b2 <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801028b1:	90                   	nop
801028b2:	8b 45 08             	mov    0x8(%ebp),%eax
801028b5:	8b 00                	mov    (%eax),%eax
801028b7:	83 e0 06             	and    $0x6,%eax
801028ba:	83 f8 02             	cmp    $0x2,%eax
801028bd:	75 dd                	jne    8010289c <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
801028bf:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028c6:	e8 7a 23 00 00       	call   80104c45 <release>
}
801028cb:	c9                   	leave  
801028cc:	c3                   	ret    
801028cd:	00 00                	add    %al,(%eax)
	...

801028d0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
801028d0:	55                   	push   %ebp
801028d1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028d3:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801028d8:	8b 55 08             	mov    0x8(%ebp),%edx
801028db:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028dd:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801028e2:	8b 40 10             	mov    0x10(%eax),%eax
}
801028e5:	5d                   	pop    %ebp
801028e6:	c3                   	ret    

801028e7 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801028e7:	55                   	push   %ebp
801028e8:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028ea:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801028ef:	8b 55 08             	mov    0x8(%ebp),%edx
801028f2:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028f4:	a1 54 fd 10 80       	mov    0x8010fd54,%eax
801028f9:	8b 55 0c             	mov    0xc(%ebp),%edx
801028fc:	89 50 10             	mov    %edx,0x10(%eax)
}
801028ff:	5d                   	pop    %ebp
80102900:	c3                   	ret    

80102901 <ioapicinit>:

void
ioapicinit(void)
{
80102901:	55                   	push   %ebp
80102902:	89 e5                	mov    %esp,%ebp
80102904:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102907:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
8010290c:	85 c0                	test   %eax,%eax
8010290e:	0f 84 9f 00 00 00    	je     801029b3 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102914:	c7 05 54 fd 10 80 00 	movl   $0xfec00000,0x8010fd54
8010291b:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
8010291e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102925:	e8 a6 ff ff ff       	call   801028d0 <ioapicread>
8010292a:	c1 e8 10             	shr    $0x10,%eax
8010292d:	25 ff 00 00 00       	and    $0xff,%eax
80102932:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102935:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010293c:	e8 8f ff ff ff       	call   801028d0 <ioapicread>
80102941:	c1 e8 18             	shr    $0x18,%eax
80102944:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102947:	0f b6 05 20 fe 10 80 	movzbl 0x8010fe20,%eax
8010294e:	0f b6 c0             	movzbl %al,%eax
80102951:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102954:	74 0c                	je     80102962 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102956:	c7 04 24 7c 83 10 80 	movl   $0x8010837c,(%esp)
8010295d:	e8 3f da ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102962:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102969:	eb 3e                	jmp    801029a9 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
8010296b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010296e:	83 c0 20             	add    $0x20,%eax
80102971:	0d 00 00 01 00       	or     $0x10000,%eax
80102976:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102979:	83 c2 08             	add    $0x8,%edx
8010297c:	01 d2                	add    %edx,%edx
8010297e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102982:	89 14 24             	mov    %edx,(%esp)
80102985:	e8 5d ff ff ff       	call   801028e7 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
8010298a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010298d:	83 c0 08             	add    $0x8,%eax
80102990:	01 c0                	add    %eax,%eax
80102992:	83 c0 01             	add    $0x1,%eax
80102995:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010299c:	00 
8010299d:	89 04 24             	mov    %eax,(%esp)
801029a0:	e8 42 ff ff ff       	call   801028e7 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801029a5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801029a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029ac:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801029af:	7e ba                	jle    8010296b <ioapicinit+0x6a>
801029b1:	eb 01                	jmp    801029b4 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
801029b3:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
801029b4:	c9                   	leave  
801029b5:	c3                   	ret    

801029b6 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
801029b6:	55                   	push   %ebp
801029b7:	89 e5                	mov    %esp,%ebp
801029b9:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
801029bc:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
801029c1:	85 c0                	test   %eax,%eax
801029c3:	74 39                	je     801029fe <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
801029c5:	8b 45 08             	mov    0x8(%ebp),%eax
801029c8:	83 c0 20             	add    $0x20,%eax
801029cb:	8b 55 08             	mov    0x8(%ebp),%edx
801029ce:	83 c2 08             	add    $0x8,%edx
801029d1:	01 d2                	add    %edx,%edx
801029d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801029d7:	89 14 24             	mov    %edx,(%esp)
801029da:	e8 08 ff ff ff       	call   801028e7 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801029df:	8b 45 0c             	mov    0xc(%ebp),%eax
801029e2:	c1 e0 18             	shl    $0x18,%eax
801029e5:	8b 55 08             	mov    0x8(%ebp),%edx
801029e8:	83 c2 08             	add    $0x8,%edx
801029eb:	01 d2                	add    %edx,%edx
801029ed:	83 c2 01             	add    $0x1,%edx
801029f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801029f4:	89 14 24             	mov    %edx,(%esp)
801029f7:	e8 eb fe ff ff       	call   801028e7 <ioapicwrite>
801029fc:	eb 01                	jmp    801029ff <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
801029fe:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
801029ff:	c9                   	leave  
80102a00:	c3                   	ret    
80102a01:	00 00                	add    %al,(%eax)
	...

80102a04 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102a04:	55                   	push   %ebp
80102a05:	89 e5                	mov    %esp,%ebp
80102a07:	8b 45 08             	mov    0x8(%ebp),%eax
80102a0a:	05 00 00 00 80       	add    $0x80000000,%eax
80102a0f:	5d                   	pop    %ebp
80102a10:	c3                   	ret    

80102a11 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102a11:	55                   	push   %ebp
80102a12:	89 e5                	mov    %esp,%ebp
80102a14:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102a17:	c7 44 24 04 ae 83 10 	movl   $0x801083ae,0x4(%esp)
80102a1e:	80 
80102a1f:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102a26:	e8 97 21 00 00       	call   80104bc2 <initlock>
  kmem.use_lock = 0;
80102a2b:	c7 05 94 fd 10 80 00 	movl   $0x0,0x8010fd94
80102a32:	00 00 00 
  freerange(vstart, vend);
80102a35:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a38:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a3c:	8b 45 08             	mov    0x8(%ebp),%eax
80102a3f:	89 04 24             	mov    %eax,(%esp)
80102a42:	e8 26 00 00 00       	call   80102a6d <freerange>
}
80102a47:	c9                   	leave  
80102a48:	c3                   	ret    

80102a49 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a49:	55                   	push   %ebp
80102a4a:	89 e5                	mov    %esp,%ebp
80102a4c:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a4f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a52:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a56:	8b 45 08             	mov    0x8(%ebp),%eax
80102a59:	89 04 24             	mov    %eax,(%esp)
80102a5c:	e8 0c 00 00 00       	call   80102a6d <freerange>
  kmem.use_lock = 1;
80102a61:	c7 05 94 fd 10 80 01 	movl   $0x1,0x8010fd94
80102a68:	00 00 00 
}
80102a6b:	c9                   	leave  
80102a6c:	c3                   	ret    

80102a6d <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a6d:	55                   	push   %ebp
80102a6e:	89 e5                	mov    %esp,%ebp
80102a70:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a73:	8b 45 08             	mov    0x8(%ebp),%eax
80102a76:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a7b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a80:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a83:	eb 12                	jmp    80102a97 <freerange+0x2a>
    kfree(p);
80102a85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a88:	89 04 24             	mov    %eax,(%esp)
80102a8b:	e8 16 00 00 00       	call   80102aa6 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a90:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a9a:	05 00 10 00 00       	add    $0x1000,%eax
80102a9f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102aa2:	76 e1                	jbe    80102a85 <freerange+0x18>
    kfree(p);
}
80102aa4:	c9                   	leave  
80102aa5:	c3                   	ret    

80102aa6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102aa6:	55                   	push   %ebp
80102aa7:	89 e5                	mov    %esp,%ebp
80102aa9:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102aac:	8b 45 08             	mov    0x8(%ebp),%eax
80102aaf:	25 ff 0f 00 00       	and    $0xfff,%eax
80102ab4:	85 c0                	test   %eax,%eax
80102ab6:	75 1b                	jne    80102ad3 <kfree+0x2d>
80102ab8:	81 7d 08 1c 2c 11 80 	cmpl   $0x80112c1c,0x8(%ebp)
80102abf:	72 12                	jb     80102ad3 <kfree+0x2d>
80102ac1:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac4:	89 04 24             	mov    %eax,(%esp)
80102ac7:	e8 38 ff ff ff       	call   80102a04 <v2p>
80102acc:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102ad1:	76 0c                	jbe    80102adf <kfree+0x39>
    panic("kfree");
80102ad3:	c7 04 24 b3 83 10 80 	movl   $0x801083b3,(%esp)
80102ada:	e8 5e da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102adf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ae6:	00 
80102ae7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102aee:	00 
80102aef:	8b 45 08             	mov    0x8(%ebp),%eax
80102af2:	89 04 24             	mov    %eax,(%esp)
80102af5:	e8 38 23 00 00       	call   80104e32 <memset>

  if(kmem.use_lock)
80102afa:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102aff:	85 c0                	test   %eax,%eax
80102b01:	74 0c                	je     80102b0f <kfree+0x69>
    acquire(&kmem.lock);
80102b03:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102b0a:	e8 d4 20 00 00       	call   80104be3 <acquire>
  r = (struct run*)v;
80102b0f:	8b 45 08             	mov    0x8(%ebp),%eax
80102b12:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102b15:	8b 15 98 fd 10 80    	mov    0x8010fd98,%edx
80102b1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b1e:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b23:	a3 98 fd 10 80       	mov    %eax,0x8010fd98
  if(kmem.use_lock)
80102b28:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102b2d:	85 c0                	test   %eax,%eax
80102b2f:	74 0c                	je     80102b3d <kfree+0x97>
    release(&kmem.lock);
80102b31:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102b38:	e8 08 21 00 00       	call   80104c45 <release>
}
80102b3d:	c9                   	leave  
80102b3e:	c3                   	ret    

80102b3f <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102b3f:	55                   	push   %ebp
80102b40:	89 e5                	mov    %esp,%ebp
80102b42:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102b45:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102b4a:	85 c0                	test   %eax,%eax
80102b4c:	74 0c                	je     80102b5a <kalloc+0x1b>
    acquire(&kmem.lock);
80102b4e:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102b55:	e8 89 20 00 00       	call   80104be3 <acquire>
  r = kmem.freelist;
80102b5a:	a1 98 fd 10 80       	mov    0x8010fd98,%eax
80102b5f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b62:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b66:	74 0a                	je     80102b72 <kalloc+0x33>
    kmem.freelist = r->next;
80102b68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b6b:	8b 00                	mov    (%eax),%eax
80102b6d:	a3 98 fd 10 80       	mov    %eax,0x8010fd98
  if(kmem.use_lock)
80102b72:	a1 94 fd 10 80       	mov    0x8010fd94,%eax
80102b77:	85 c0                	test   %eax,%eax
80102b79:	74 0c                	je     80102b87 <kalloc+0x48>
    release(&kmem.lock);
80102b7b:	c7 04 24 60 fd 10 80 	movl   $0x8010fd60,(%esp)
80102b82:	e8 be 20 00 00       	call   80104c45 <release>
  return (char*)r;
80102b87:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b8a:	c9                   	leave  
80102b8b:	c3                   	ret    

80102b8c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b8c:	55                   	push   %ebp
80102b8d:	89 e5                	mov    %esp,%ebp
80102b8f:	53                   	push   %ebx
80102b90:	83 ec 14             	sub    $0x14,%esp
80102b93:	8b 45 08             	mov    0x8(%ebp),%eax
80102b96:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b9a:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102b9e:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102ba2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102ba6:	ec                   	in     (%dx),%al
80102ba7:	89 c3                	mov    %eax,%ebx
80102ba9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102bac:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102bb0:	83 c4 14             	add    $0x14,%esp
80102bb3:	5b                   	pop    %ebx
80102bb4:	5d                   	pop    %ebp
80102bb5:	c3                   	ret    

80102bb6 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102bb6:	55                   	push   %ebp
80102bb7:	89 e5                	mov    %esp,%ebp
80102bb9:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102bbc:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102bc3:	e8 c4 ff ff ff       	call   80102b8c <inb>
80102bc8:	0f b6 c0             	movzbl %al,%eax
80102bcb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102bce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bd1:	83 e0 01             	and    $0x1,%eax
80102bd4:	85 c0                	test   %eax,%eax
80102bd6:	75 0a                	jne    80102be2 <kbdgetc+0x2c>
    return -1;
80102bd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102bdd:	e9 23 01 00 00       	jmp    80102d05 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102be2:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102be9:	e8 9e ff ff ff       	call   80102b8c <inb>
80102bee:	0f b6 c0             	movzbl %al,%eax
80102bf1:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102bf4:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102bfb:	75 17                	jne    80102c14 <kbdgetc+0x5e>
    shift |= E0ESC;
80102bfd:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c02:	83 c8 40             	or     $0x40,%eax
80102c05:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c0a:	b8 00 00 00 00       	mov    $0x0,%eax
80102c0f:	e9 f1 00 00 00       	jmp    80102d05 <kbdgetc+0x14f>
  } else if(data & 0x80){
80102c14:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c17:	25 80 00 00 00       	and    $0x80,%eax
80102c1c:	85 c0                	test   %eax,%eax
80102c1e:	74 45                	je     80102c65 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102c20:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c25:	83 e0 40             	and    $0x40,%eax
80102c28:	85 c0                	test   %eax,%eax
80102c2a:	75 08                	jne    80102c34 <kbdgetc+0x7e>
80102c2c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c2f:	83 e0 7f             	and    $0x7f,%eax
80102c32:	eb 03                	jmp    80102c37 <kbdgetc+0x81>
80102c34:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c37:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102c3a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c3d:	05 20 90 10 80       	add    $0x80109020,%eax
80102c42:	0f b6 00             	movzbl (%eax),%eax
80102c45:	83 c8 40             	or     $0x40,%eax
80102c48:	0f b6 c0             	movzbl %al,%eax
80102c4b:	f7 d0                	not    %eax
80102c4d:	89 c2                	mov    %eax,%edx
80102c4f:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c54:	21 d0                	and    %edx,%eax
80102c56:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c5b:	b8 00 00 00 00       	mov    $0x0,%eax
80102c60:	e9 a0 00 00 00       	jmp    80102d05 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102c65:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c6a:	83 e0 40             	and    $0x40,%eax
80102c6d:	85 c0                	test   %eax,%eax
80102c6f:	74 14                	je     80102c85 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c71:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c78:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c7d:	83 e0 bf             	and    $0xffffffbf,%eax
80102c80:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102c85:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c88:	05 20 90 10 80       	add    $0x80109020,%eax
80102c8d:	0f b6 00             	movzbl (%eax),%eax
80102c90:	0f b6 d0             	movzbl %al,%edx
80102c93:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c98:	09 d0                	or     %edx,%eax
80102c9a:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102c9f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ca2:	05 20 91 10 80       	add    $0x80109120,%eax
80102ca7:	0f b6 00             	movzbl (%eax),%eax
80102caa:	0f b6 d0             	movzbl %al,%edx
80102cad:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cb2:	31 d0                	xor    %edx,%eax
80102cb4:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102cb9:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cbe:	83 e0 03             	and    $0x3,%eax
80102cc1:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102cc8:	03 45 fc             	add    -0x4(%ebp),%eax
80102ccb:	0f b6 00             	movzbl (%eax),%eax
80102cce:	0f b6 c0             	movzbl %al,%eax
80102cd1:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102cd4:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cd9:	83 e0 08             	and    $0x8,%eax
80102cdc:	85 c0                	test   %eax,%eax
80102cde:	74 22                	je     80102d02 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102ce0:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102ce4:	76 0c                	jbe    80102cf2 <kbdgetc+0x13c>
80102ce6:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102cea:	77 06                	ja     80102cf2 <kbdgetc+0x13c>
      c += 'A' - 'a';
80102cec:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102cf0:	eb 10                	jmp    80102d02 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102cf2:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102cf6:	76 0a                	jbe    80102d02 <kbdgetc+0x14c>
80102cf8:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102cfc:	77 04                	ja     80102d02 <kbdgetc+0x14c>
      c += 'a' - 'A';
80102cfe:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102d02:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d05:	c9                   	leave  
80102d06:	c3                   	ret    

80102d07 <kbdintr>:

void
kbdintr(void)
{
80102d07:	55                   	push   %ebp
80102d08:	89 e5                	mov    %esp,%ebp
80102d0a:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102d0d:	c7 04 24 b6 2b 10 80 	movl   $0x80102bb6,(%esp)
80102d14:	e8 94 da ff ff       	call   801007ad <consoleintr>
}
80102d19:	c9                   	leave  
80102d1a:	c3                   	ret    
	...

80102d1c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102d1c:	55                   	push   %ebp
80102d1d:	89 e5                	mov    %esp,%ebp
80102d1f:	83 ec 08             	sub    $0x8,%esp
80102d22:	8b 55 08             	mov    0x8(%ebp),%edx
80102d25:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d28:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102d2c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d2f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102d33:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102d37:	ee                   	out    %al,(%dx)
}
80102d38:	c9                   	leave  
80102d39:	c3                   	ret    

80102d3a <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102d3a:	55                   	push   %ebp
80102d3b:	89 e5                	mov    %esp,%ebp
80102d3d:	53                   	push   %ebx
80102d3e:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102d41:	9c                   	pushf  
80102d42:	5b                   	pop    %ebx
80102d43:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102d46:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d49:	83 c4 10             	add    $0x10,%esp
80102d4c:	5b                   	pop    %ebx
80102d4d:	5d                   	pop    %ebp
80102d4e:	c3                   	ret    

80102d4f <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102d4f:	55                   	push   %ebp
80102d50:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102d52:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102d57:	8b 55 08             	mov    0x8(%ebp),%edx
80102d5a:	c1 e2 02             	shl    $0x2,%edx
80102d5d:	01 c2                	add    %eax,%edx
80102d5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d62:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d64:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102d69:	83 c0 20             	add    $0x20,%eax
80102d6c:	8b 00                	mov    (%eax),%eax
}
80102d6e:	5d                   	pop    %ebp
80102d6f:	c3                   	ret    

80102d70 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102d70:	55                   	push   %ebp
80102d71:	89 e5                	mov    %esp,%ebp
80102d73:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102d76:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102d7b:	85 c0                	test   %eax,%eax
80102d7d:	0f 84 47 01 00 00    	je     80102eca <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102d83:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102d8a:	00 
80102d8b:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102d92:	e8 b8 ff ff ff       	call   80102d4f <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102d97:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102d9e:	00 
80102d9f:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102da6:	e8 a4 ff ff ff       	call   80102d4f <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102dab:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102db2:	00 
80102db3:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102dba:	e8 90 ff ff ff       	call   80102d4f <lapicw>
  lapicw(TICR, 10000000); 
80102dbf:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102dc6:	00 
80102dc7:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102dce:	e8 7c ff ff ff       	call   80102d4f <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102dd3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dda:	00 
80102ddb:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102de2:	e8 68 ff ff ff       	call   80102d4f <lapicw>
  lapicw(LINT1, MASKED);
80102de7:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dee:	00 
80102def:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102df6:	e8 54 ff ff ff       	call   80102d4f <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102dfb:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102e00:	83 c0 30             	add    $0x30,%eax
80102e03:	8b 00                	mov    (%eax),%eax
80102e05:	c1 e8 10             	shr    $0x10,%eax
80102e08:	25 ff 00 00 00       	and    $0xff,%eax
80102e0d:	83 f8 03             	cmp    $0x3,%eax
80102e10:	76 14                	jbe    80102e26 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102e12:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e19:	00 
80102e1a:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102e21:	e8 29 ff ff ff       	call   80102d4f <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102e26:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102e2d:	00 
80102e2e:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102e35:	e8 15 ff ff ff       	call   80102d4f <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102e3a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e41:	00 
80102e42:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e49:	e8 01 ff ff ff       	call   80102d4f <lapicw>
  lapicw(ESR, 0);
80102e4e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e55:	00 
80102e56:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e5d:	e8 ed fe ff ff       	call   80102d4f <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102e62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e69:	00 
80102e6a:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102e71:	e8 d9 fe ff ff       	call   80102d4f <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102e76:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e7d:	00 
80102e7e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102e85:	e8 c5 fe ff ff       	call   80102d4f <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102e8a:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102e91:	00 
80102e92:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102e99:	e8 b1 fe ff ff       	call   80102d4f <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102e9e:	90                   	nop
80102e9f:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102ea4:	05 00 03 00 00       	add    $0x300,%eax
80102ea9:	8b 00                	mov    (%eax),%eax
80102eab:	25 00 10 00 00       	and    $0x1000,%eax
80102eb0:	85 c0                	test   %eax,%eax
80102eb2:	75 eb                	jne    80102e9f <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102eb4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ebb:	00 
80102ebc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102ec3:	e8 87 fe ff ff       	call   80102d4f <lapicw>
80102ec8:	eb 01                	jmp    80102ecb <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80102eca:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102ecb:	c9                   	leave  
80102ecc:	c3                   	ret    

80102ecd <cpunum>:

int
cpunum(void)
{
80102ecd:	55                   	push   %ebp
80102ece:	89 e5                	mov    %esp,%ebp
80102ed0:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102ed3:	e8 62 fe ff ff       	call   80102d3a <readeflags>
80102ed8:	25 00 02 00 00       	and    $0x200,%eax
80102edd:	85 c0                	test   %eax,%eax
80102edf:	74 29                	je     80102f0a <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102ee1:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102ee6:	85 c0                	test   %eax,%eax
80102ee8:	0f 94 c2             	sete   %dl
80102eeb:	83 c0 01             	add    $0x1,%eax
80102eee:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102ef3:	84 d2                	test   %dl,%dl
80102ef5:	74 13                	je     80102f0a <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102ef7:	8b 45 04             	mov    0x4(%ebp),%eax
80102efa:	89 44 24 04          	mov    %eax,0x4(%esp)
80102efe:	c7 04 24 bc 83 10 80 	movl   $0x801083bc,(%esp)
80102f05:	e8 97 d4 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102f0a:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102f0f:	85 c0                	test   %eax,%eax
80102f11:	74 0f                	je     80102f22 <cpunum+0x55>
    return lapic[ID]>>24;
80102f13:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102f18:	83 c0 20             	add    $0x20,%eax
80102f1b:	8b 00                	mov    (%eax),%eax
80102f1d:	c1 e8 18             	shr    $0x18,%eax
80102f20:	eb 05                	jmp    80102f27 <cpunum+0x5a>
  return 0;
80102f22:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102f27:	c9                   	leave  
80102f28:	c3                   	ret    

80102f29 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102f29:	55                   	push   %ebp
80102f2a:	89 e5                	mov    %esp,%ebp
80102f2c:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102f2f:	a1 9c fd 10 80       	mov    0x8010fd9c,%eax
80102f34:	85 c0                	test   %eax,%eax
80102f36:	74 14                	je     80102f4c <lapiceoi+0x23>
    lapicw(EOI, 0);
80102f38:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f3f:	00 
80102f40:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f47:	e8 03 fe ff ff       	call   80102d4f <lapicw>
}
80102f4c:	c9                   	leave  
80102f4d:	c3                   	ret    

80102f4e <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102f4e:	55                   	push   %ebp
80102f4f:	89 e5                	mov    %esp,%ebp
}
80102f51:	5d                   	pop    %ebp
80102f52:	c3                   	ret    

80102f53 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102f53:	55                   	push   %ebp
80102f54:	89 e5                	mov    %esp,%ebp
80102f56:	83 ec 1c             	sub    $0x1c,%esp
80102f59:	8b 45 08             	mov    0x8(%ebp),%eax
80102f5c:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80102f5f:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f66:	00 
80102f67:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f6e:	e8 a9 fd ff ff       	call   80102d1c <outb>
  outb(IO_RTC+1, 0x0A);
80102f73:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102f7a:	00 
80102f7b:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102f82:	e8 95 fd ff ff       	call   80102d1c <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102f87:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102f8e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f91:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102f96:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f99:	8d 50 02             	lea    0x2(%eax),%edx
80102f9c:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f9f:	c1 e8 04             	shr    $0x4,%eax
80102fa2:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102fa5:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fa9:	c1 e0 18             	shl    $0x18,%eax
80102fac:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fb0:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102fb7:	e8 93 fd ff ff       	call   80102d4f <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102fbc:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102fc3:	00 
80102fc4:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fcb:	e8 7f fd ff ff       	call   80102d4f <lapicw>
  microdelay(200);
80102fd0:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102fd7:	e8 72 ff ff ff       	call   80102f4e <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80102fdc:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80102fe3:	00 
80102fe4:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102feb:	e8 5f fd ff ff       	call   80102d4f <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80102ff0:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102ff7:	e8 52 ff ff ff       	call   80102f4e <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80102ffc:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103003:	eb 40                	jmp    80103045 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103005:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103009:	c1 e0 18             	shl    $0x18,%eax
8010300c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103010:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103017:	e8 33 fd ff ff       	call   80102d4f <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010301c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010301f:	c1 e8 0c             	shr    $0xc,%eax
80103022:	80 cc 06             	or     $0x6,%ah
80103025:	89 44 24 04          	mov    %eax,0x4(%esp)
80103029:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103030:	e8 1a fd ff ff       	call   80102d4f <lapicw>
    microdelay(200);
80103035:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010303c:	e8 0d ff ff ff       	call   80102f4e <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103041:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103045:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103049:	7e ba                	jle    80103005 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010304b:	c9                   	leave  
8010304c:	c3                   	ret    
8010304d:	00 00                	add    %al,(%eax)
	...

80103050 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103050:	55                   	push   %ebp
80103051:	89 e5                	mov    %esp,%ebp
80103053:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103056:	c7 44 24 04 e8 83 10 	movl   $0x801083e8,0x4(%esp)
8010305d:	80 
8010305e:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
80103065:	e8 58 1b 00 00       	call   80104bc2 <initlock>
  readsb(ROOTDEV, &sb);
8010306a:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010306d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103071:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103078:	e8 af e2 ff ff       	call   8010132c <readsb>
  log.start = sb.size - sb.nlog;
8010307d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103080:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103083:	89 d1                	mov    %edx,%ecx
80103085:	29 c1                	sub    %eax,%ecx
80103087:	89 c8                	mov    %ecx,%eax
80103089:	a3 d4 fd 10 80       	mov    %eax,0x8010fdd4
  log.size = sb.nlog;
8010308e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103091:	a3 d8 fd 10 80       	mov    %eax,0x8010fdd8
  log.dev = ROOTDEV;
80103096:	c7 05 e0 fd 10 80 01 	movl   $0x1,0x8010fde0
8010309d:	00 00 00 
  recover_from_log();
801030a0:	e8 97 01 00 00       	call   8010323c <recover_from_log>
}
801030a5:	c9                   	leave  
801030a6:	c3                   	ret    

801030a7 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801030a7:	55                   	push   %ebp
801030a8:	89 e5                	mov    %esp,%ebp
801030aa:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801030ad:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801030b4:	e9 89 00 00 00       	jmp    80103142 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801030b9:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
801030be:	03 45 f4             	add    -0xc(%ebp),%eax
801030c1:	83 c0 01             	add    $0x1,%eax
801030c4:	89 c2                	mov    %eax,%edx
801030c6:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
801030cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801030cf:	89 04 24             	mov    %eax,(%esp)
801030d2:	e8 cf d0 ff ff       	call   801001a6 <bread>
801030d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801030da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030dd:	83 c0 10             	add    $0x10,%eax
801030e0:	8b 04 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%eax
801030e7:	89 c2                	mov    %eax,%edx
801030e9:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
801030ee:	89 54 24 04          	mov    %edx,0x4(%esp)
801030f2:	89 04 24             	mov    %eax,(%esp)
801030f5:	e8 ac d0 ff ff       	call   801001a6 <bread>
801030fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801030fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103100:	8d 50 18             	lea    0x18(%eax),%edx
80103103:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103106:	83 c0 18             	add    $0x18,%eax
80103109:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103110:	00 
80103111:	89 54 24 04          	mov    %edx,0x4(%esp)
80103115:	89 04 24             	mov    %eax,(%esp)
80103118:	e8 e8 1d 00 00       	call   80104f05 <memmove>
    bwrite(dbuf);  // write dst to disk
8010311d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103120:	89 04 24             	mov    %eax,(%esp)
80103123:	e8 b5 d0 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103128:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010312b:	89 04 24             	mov    %eax,(%esp)
8010312e:	e8 e4 d0 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103133:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103136:	89 04 24             	mov    %eax,(%esp)
80103139:	e8 d9 d0 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010313e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103142:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103147:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010314a:	0f 8f 69 ff ff ff    	jg     801030b9 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103150:	c9                   	leave  
80103151:	c3                   	ret    

80103152 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103152:	55                   	push   %ebp
80103153:	89 e5                	mov    %esp,%ebp
80103155:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103158:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
8010315d:	89 c2                	mov    %eax,%edx
8010315f:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
80103164:	89 54 24 04          	mov    %edx,0x4(%esp)
80103168:	89 04 24             	mov    %eax,(%esp)
8010316b:	e8 36 d0 ff ff       	call   801001a6 <bread>
80103170:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103173:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103176:	83 c0 18             	add    $0x18,%eax
80103179:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
8010317c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010317f:	8b 00                	mov    (%eax),%eax
80103181:	a3 e4 fd 10 80       	mov    %eax,0x8010fde4
  for (i = 0; i < log.lh.n; i++) {
80103186:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010318d:	eb 1b                	jmp    801031aa <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010318f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103192:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103195:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103199:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010319c:	83 c2 10             	add    $0x10,%edx
8010319f:	89 04 95 a8 fd 10 80 	mov    %eax,-0x7fef0258(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801031a6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801031aa:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801031af:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801031b2:	7f db                	jg     8010318f <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801031b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031b7:	89 04 24             	mov    %eax,(%esp)
801031ba:	e8 58 d0 ff ff       	call   80100217 <brelse>
}
801031bf:	c9                   	leave  
801031c0:	c3                   	ret    

801031c1 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801031c1:	55                   	push   %ebp
801031c2:	89 e5                	mov    %esp,%ebp
801031c4:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801031c7:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
801031cc:	89 c2                	mov    %eax,%edx
801031ce:	a1 e0 fd 10 80       	mov    0x8010fde0,%eax
801031d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801031d7:	89 04 24             	mov    %eax,(%esp)
801031da:	e8 c7 cf ff ff       	call   801001a6 <bread>
801031df:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801031e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031e5:	83 c0 18             	add    $0x18,%eax
801031e8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801031eb:	8b 15 e4 fd 10 80    	mov    0x8010fde4,%edx
801031f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031f4:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801031f6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801031fd:	eb 1b                	jmp    8010321a <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801031ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103202:	83 c0 10             	add    $0x10,%eax
80103205:	8b 0c 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%ecx
8010320c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010320f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103212:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103216:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010321a:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
8010321f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103222:	7f db                	jg     801031ff <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103224:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103227:	89 04 24             	mov    %eax,(%esp)
8010322a:	e8 ae cf ff ff       	call   801001dd <bwrite>
  brelse(buf);
8010322f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103232:	89 04 24             	mov    %eax,(%esp)
80103235:	e8 dd cf ff ff       	call   80100217 <brelse>
}
8010323a:	c9                   	leave  
8010323b:	c3                   	ret    

8010323c <recover_from_log>:

static void
recover_from_log(void)
{
8010323c:	55                   	push   %ebp
8010323d:	89 e5                	mov    %esp,%ebp
8010323f:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103242:	e8 0b ff ff ff       	call   80103152 <read_head>
  install_trans(); // if committed, copy from log to disk
80103247:	e8 5b fe ff ff       	call   801030a7 <install_trans>
  log.lh.n = 0;
8010324c:	c7 05 e4 fd 10 80 00 	movl   $0x0,0x8010fde4
80103253:	00 00 00 
  write_head(); // clear the log
80103256:	e8 66 ff ff ff       	call   801031c1 <write_head>
}
8010325b:	c9                   	leave  
8010325c:	c3                   	ret    

8010325d <begin_trans>:

void
begin_trans(void)
{
8010325d:	55                   	push   %ebp
8010325e:	89 e5                	mov    %esp,%ebp
80103260:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103263:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
8010326a:	e8 74 19 00 00       	call   80104be3 <acquire>
  while (log.busy) {
8010326f:	eb 14                	jmp    80103285 <begin_trans+0x28>
    sleep(&log, &log.lock);
80103271:	c7 44 24 04 a0 fd 10 	movl   $0x8010fda0,0x4(%esp)
80103278:	80 
80103279:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
80103280:	e8 80 16 00 00       	call   80104905 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103285:	a1 dc fd 10 80       	mov    0x8010fddc,%eax
8010328a:	85 c0                	test   %eax,%eax
8010328c:	75 e3                	jne    80103271 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
8010328e:	c7 05 dc fd 10 80 01 	movl   $0x1,0x8010fddc
80103295:	00 00 00 
  release(&log.lock);
80103298:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
8010329f:	e8 a1 19 00 00       	call   80104c45 <release>
}
801032a4:	c9                   	leave  
801032a5:	c3                   	ret    

801032a6 <commit_trans>:

void
commit_trans(void)
{
801032a6:	55                   	push   %ebp
801032a7:	89 e5                	mov    %esp,%ebp
801032a9:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801032ac:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801032b1:	85 c0                	test   %eax,%eax
801032b3:	7e 19                	jle    801032ce <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801032b5:	e8 07 ff ff ff       	call   801031c1 <write_head>
    install_trans(); // Now install writes to home locations
801032ba:	e8 e8 fd ff ff       	call   801030a7 <install_trans>
    log.lh.n = 0; 
801032bf:	c7 05 e4 fd 10 80 00 	movl   $0x0,0x8010fde4
801032c6:	00 00 00 
    write_head();    // Erase the transaction from the log
801032c9:	e8 f3 fe ff ff       	call   801031c1 <write_head>
  }
  
  acquire(&log.lock);
801032ce:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
801032d5:	e8 09 19 00 00       	call   80104be3 <acquire>
  log.busy = 0;
801032da:	c7 05 dc fd 10 80 00 	movl   $0x0,0x8010fddc
801032e1:	00 00 00 
  wakeup(&log);
801032e4:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
801032eb:	e8 ee 16 00 00       	call   801049de <wakeup>
  release(&log.lock);
801032f0:	c7 04 24 a0 fd 10 80 	movl   $0x8010fda0,(%esp)
801032f7:	e8 49 19 00 00       	call   80104c45 <release>
}
801032fc:	c9                   	leave  
801032fd:	c3                   	ret    

801032fe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801032fe:	55                   	push   %ebp
801032ff:	89 e5                	mov    %esp,%ebp
80103301:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103304:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103309:	83 f8 09             	cmp    $0x9,%eax
8010330c:	7f 12                	jg     80103320 <log_write+0x22>
8010330e:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
80103313:	8b 15 d8 fd 10 80    	mov    0x8010fdd8,%edx
80103319:	83 ea 01             	sub    $0x1,%edx
8010331c:	39 d0                	cmp    %edx,%eax
8010331e:	7c 0c                	jl     8010332c <log_write+0x2e>
    panic("too big a transaction");
80103320:	c7 04 24 ec 83 10 80 	movl   $0x801083ec,(%esp)
80103327:	e8 11 d2 ff ff       	call   8010053d <panic>
  if (!log.busy)
8010332c:	a1 dc fd 10 80       	mov    0x8010fddc,%eax
80103331:	85 c0                	test   %eax,%eax
80103333:	75 0c                	jne    80103341 <log_write+0x43>
    panic("write outside of trans");
80103335:	c7 04 24 02 84 10 80 	movl   $0x80108402,(%esp)
8010333c:	e8 fc d1 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103341:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103348:	eb 1d                	jmp    80103367 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
8010334a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010334d:	83 c0 10             	add    $0x10,%eax
80103350:	8b 04 85 a8 fd 10 80 	mov    -0x7fef0258(,%eax,4),%eax
80103357:	89 c2                	mov    %eax,%edx
80103359:	8b 45 08             	mov    0x8(%ebp),%eax
8010335c:	8b 40 08             	mov    0x8(%eax),%eax
8010335f:	39 c2                	cmp    %eax,%edx
80103361:	74 10                	je     80103373 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103363:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103367:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
8010336c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010336f:	7f d9                	jg     8010334a <log_write+0x4c>
80103371:	eb 01                	jmp    80103374 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103373:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103374:	8b 45 08             	mov    0x8(%ebp),%eax
80103377:	8b 40 08             	mov    0x8(%eax),%eax
8010337a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010337d:	83 c2 10             	add    $0x10,%edx
80103380:	89 04 95 a8 fd 10 80 	mov    %eax,-0x7fef0258(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103387:	a1 d4 fd 10 80       	mov    0x8010fdd4,%eax
8010338c:	03 45 f4             	add    -0xc(%ebp),%eax
8010338f:	83 c0 01             	add    $0x1,%eax
80103392:	89 c2                	mov    %eax,%edx
80103394:	8b 45 08             	mov    0x8(%ebp),%eax
80103397:	8b 40 04             	mov    0x4(%eax),%eax
8010339a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010339e:	89 04 24             	mov    %eax,(%esp)
801033a1:	e8 00 ce ff ff       	call   801001a6 <bread>
801033a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801033a9:	8b 45 08             	mov    0x8(%ebp),%eax
801033ac:	8d 50 18             	lea    0x18(%eax),%edx
801033af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033b2:	83 c0 18             	add    $0x18,%eax
801033b5:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801033bc:	00 
801033bd:	89 54 24 04          	mov    %edx,0x4(%esp)
801033c1:	89 04 24             	mov    %eax,(%esp)
801033c4:	e8 3c 1b 00 00       	call   80104f05 <memmove>
  bwrite(lbuf);
801033c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033cc:	89 04 24             	mov    %eax,(%esp)
801033cf:	e8 09 ce ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801033d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033d7:	89 04 24             	mov    %eax,(%esp)
801033da:	e8 38 ce ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801033df:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801033e4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033e7:	75 0d                	jne    801033f6 <log_write+0xf8>
    log.lh.n++;
801033e9:	a1 e4 fd 10 80       	mov    0x8010fde4,%eax
801033ee:	83 c0 01             	add    $0x1,%eax
801033f1:	a3 e4 fd 10 80       	mov    %eax,0x8010fde4
  b->flags |= B_DIRTY; // XXX prevent eviction
801033f6:	8b 45 08             	mov    0x8(%ebp),%eax
801033f9:	8b 00                	mov    (%eax),%eax
801033fb:	89 c2                	mov    %eax,%edx
801033fd:	83 ca 04             	or     $0x4,%edx
80103400:	8b 45 08             	mov    0x8(%ebp),%eax
80103403:	89 10                	mov    %edx,(%eax)
}
80103405:	c9                   	leave  
80103406:	c3                   	ret    
	...

80103408 <v2p>:
80103408:	55                   	push   %ebp
80103409:	89 e5                	mov    %esp,%ebp
8010340b:	8b 45 08             	mov    0x8(%ebp),%eax
8010340e:	05 00 00 00 80       	add    $0x80000000,%eax
80103413:	5d                   	pop    %ebp
80103414:	c3                   	ret    

80103415 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103415:	55                   	push   %ebp
80103416:	89 e5                	mov    %esp,%ebp
80103418:	8b 45 08             	mov    0x8(%ebp),%eax
8010341b:	05 00 00 00 80       	add    $0x80000000,%eax
80103420:	5d                   	pop    %ebp
80103421:	c3                   	ret    

80103422 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103422:	55                   	push   %ebp
80103423:	89 e5                	mov    %esp,%ebp
80103425:	53                   	push   %ebx
80103426:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103429:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010342c:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
8010342f:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103432:	89 c3                	mov    %eax,%ebx
80103434:	89 d8                	mov    %ebx,%eax
80103436:	f0 87 02             	lock xchg %eax,(%edx)
80103439:	89 c3                	mov    %eax,%ebx
8010343b:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010343e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103441:	83 c4 10             	add    $0x10,%esp
80103444:	5b                   	pop    %ebx
80103445:	5d                   	pop    %ebp
80103446:	c3                   	ret    

80103447 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103447:	55                   	push   %ebp
80103448:	89 e5                	mov    %esp,%ebp
8010344a:	83 e4 f0             	and    $0xfffffff0,%esp
8010344d:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103450:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103457:	80 
80103458:	c7 04 24 1c 2c 11 80 	movl   $0x80112c1c,(%esp)
8010345f:	e8 ad f5 ff ff       	call   80102a11 <kinit1>
  kvmalloc();      // kernel page table
80103464:	e8 dd 45 00 00       	call   80107a46 <kvmalloc>
  mpinit();        // collect info about this machine
80103469:	e8 63 04 00 00       	call   801038d1 <mpinit>
  lapicinit(mpbcpu());
8010346e:	e8 2e 02 00 00       	call   801036a1 <mpbcpu>
80103473:	89 04 24             	mov    %eax,(%esp)
80103476:	e8 f5 f8 ff ff       	call   80102d70 <lapicinit>
  seginit();       // set up segments
8010347b:	e8 69 3f 00 00       	call   801073e9 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103480:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103486:	0f b6 00             	movzbl (%eax),%eax
80103489:	0f b6 c0             	movzbl %al,%eax
8010348c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103490:	c7 04 24 19 84 10 80 	movl   $0x80108419,(%esp)
80103497:	e8 05 cf ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
8010349c:	e8 95 06 00 00       	call   80103b36 <picinit>
  ioapicinit();    // another interrupt controller
801034a1:	e8 5b f4 ff ff       	call   80102901 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801034a6:	e8 e2 d5 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
801034ab:	e8 84 32 00 00       	call   80106734 <uartinit>
  pinit();         // process table
801034b0:	e8 96 0b 00 00       	call   8010404b <pinit>
  tvinit();        // trap vectors
801034b5:	e8 1d 2e 00 00       	call   801062d7 <tvinit>
  binit();         // buffer cache
801034ba:	e8 75 cb ff ff       	call   80100034 <binit>
  fileinit();      // file table
801034bf:	e8 7c da ff ff       	call   80100f40 <fileinit>
  iinit();         // inode cache
801034c4:	e8 2a e1 ff ff       	call   801015f3 <iinit>
  ideinit();       // disk
801034c9:	e8 98 f0 ff ff       	call   80102566 <ideinit>
  if(!ismp)
801034ce:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
801034d3:	85 c0                	test   %eax,%eax
801034d5:	75 05                	jne    801034dc <main+0x95>
    timerinit();   // uniprocessor timer
801034d7:	e8 3e 2d 00 00       	call   8010621a <timerinit>
  startothers();   // start other processors
801034dc:	e8 87 00 00 00       	call   80103568 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801034e1:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801034e8:	8e 
801034e9:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801034f0:	e8 54 f5 ff ff       	call   80102a49 <kinit2>
  userinit();      // first user process
801034f5:	e8 6c 0c 00 00       	call   80104166 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801034fa:	e8 22 00 00 00       	call   80103521 <mpmain>

801034ff <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801034ff:	55                   	push   %ebp
80103500:	89 e5                	mov    %esp,%ebp
80103502:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103505:	e8 53 45 00 00       	call   80107a5d <switchkvm>
  seginit();
8010350a:	e8 da 3e 00 00       	call   801073e9 <seginit>
  lapicinit(cpunum());
8010350f:	e8 b9 f9 ff ff       	call   80102ecd <cpunum>
80103514:	89 04 24             	mov    %eax,(%esp)
80103517:	e8 54 f8 ff ff       	call   80102d70 <lapicinit>
  mpmain();
8010351c:	e8 00 00 00 00       	call   80103521 <mpmain>

80103521 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103521:	55                   	push   %ebp
80103522:	89 e5                	mov    %esp,%ebp
80103524:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103527:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010352d:	0f b6 00             	movzbl (%eax),%eax
80103530:	0f b6 c0             	movzbl %al,%eax
80103533:	89 44 24 04          	mov    %eax,0x4(%esp)
80103537:	c7 04 24 30 84 10 80 	movl   $0x80108430,(%esp)
8010353e:	e8 5e ce ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103543:	e8 03 2f 00 00       	call   8010644b <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103548:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010354e:	05 a8 00 00 00       	add    $0xa8,%eax
80103553:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010355a:	00 
8010355b:	89 04 24             	mov    %eax,(%esp)
8010355e:	e8 bf fe ff ff       	call   80103422 <xchg>
  scheduler();     // start running processes
80103563:	e8 f4 11 00 00       	call   8010475c <scheduler>

80103568 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103568:	55                   	push   %ebp
80103569:	89 e5                	mov    %esp,%ebp
8010356b:	53                   	push   %ebx
8010356c:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
8010356f:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103576:	e8 9a fe ff ff       	call   80103415 <p2v>
8010357b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
8010357e:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103583:	89 44 24 08          	mov    %eax,0x8(%esp)
80103587:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
8010358e:	80 
8010358f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103592:	89 04 24             	mov    %eax,(%esp)
80103595:	e8 6b 19 00 00       	call   80104f05 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
8010359a:	c7 45 f4 40 fe 10 80 	movl   $0x8010fe40,-0xc(%ebp)
801035a1:	e9 86 00 00 00       	jmp    8010362c <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
801035a6:	e8 22 f9 ff ff       	call   80102ecd <cpunum>
801035ab:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801035b1:	05 40 fe 10 80       	add    $0x8010fe40,%eax
801035b6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035b9:	74 69                	je     80103624 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801035bb:	e8 7f f5 ff ff       	call   80102b3f <kalloc>
801035c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801035c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035c6:	83 e8 04             	sub    $0x4,%eax
801035c9:	8b 55 ec             	mov    -0x14(%ebp),%edx
801035cc:	81 c2 00 10 00 00    	add    $0x1000,%edx
801035d2:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801035d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035d7:	83 e8 08             	sub    $0x8,%eax
801035da:	c7 00 ff 34 10 80    	movl   $0x801034ff,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801035e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035e3:	8d 58 f4             	lea    -0xc(%eax),%ebx
801035e6:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
801035ed:	e8 16 fe ff ff       	call   80103408 <v2p>
801035f2:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801035f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035f7:	89 04 24             	mov    %eax,(%esp)
801035fa:	e8 09 fe ff ff       	call   80103408 <v2p>
801035ff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103602:	0f b6 12             	movzbl (%edx),%edx
80103605:	0f b6 d2             	movzbl %dl,%edx
80103608:	89 44 24 04          	mov    %eax,0x4(%esp)
8010360c:	89 14 24             	mov    %edx,(%esp)
8010360f:	e8 3f f9 ff ff       	call   80102f53 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103614:	90                   	nop
80103615:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103618:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010361e:	85 c0                	test   %eax,%eax
80103620:	74 f3                	je     80103615 <startothers+0xad>
80103622:	eb 01                	jmp    80103625 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103624:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103625:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
8010362c:	a1 20 04 11 80       	mov    0x80110420,%eax
80103631:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103637:	05 40 fe 10 80       	add    $0x8010fe40,%eax
8010363c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010363f:	0f 87 61 ff ff ff    	ja     801035a6 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103645:	83 c4 24             	add    $0x24,%esp
80103648:	5b                   	pop    %ebx
80103649:	5d                   	pop    %ebp
8010364a:	c3                   	ret    
	...

8010364c <p2v>:
8010364c:	55                   	push   %ebp
8010364d:	89 e5                	mov    %esp,%ebp
8010364f:	8b 45 08             	mov    0x8(%ebp),%eax
80103652:	05 00 00 00 80       	add    $0x80000000,%eax
80103657:	5d                   	pop    %ebp
80103658:	c3                   	ret    

80103659 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103659:	55                   	push   %ebp
8010365a:	89 e5                	mov    %esp,%ebp
8010365c:	53                   	push   %ebx
8010365d:	83 ec 14             	sub    $0x14,%esp
80103660:	8b 45 08             	mov    0x8(%ebp),%eax
80103663:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103667:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010366b:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010366f:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103673:	ec                   	in     (%dx),%al
80103674:	89 c3                	mov    %eax,%ebx
80103676:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103679:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010367d:	83 c4 14             	add    $0x14,%esp
80103680:	5b                   	pop    %ebx
80103681:	5d                   	pop    %ebp
80103682:	c3                   	ret    

80103683 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103683:	55                   	push   %ebp
80103684:	89 e5                	mov    %esp,%ebp
80103686:	83 ec 08             	sub    $0x8,%esp
80103689:	8b 55 08             	mov    0x8(%ebp),%edx
8010368c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010368f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103693:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103696:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010369a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010369e:	ee                   	out    %al,(%dx)
}
8010369f:	c9                   	leave  
801036a0:	c3                   	ret    

801036a1 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801036a1:	55                   	push   %ebp
801036a2:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801036a4:	a1 44 b6 10 80       	mov    0x8010b644,%eax
801036a9:	89 c2                	mov    %eax,%edx
801036ab:	b8 40 fe 10 80       	mov    $0x8010fe40,%eax
801036b0:	89 d1                	mov    %edx,%ecx
801036b2:	29 c1                	sub    %eax,%ecx
801036b4:	89 c8                	mov    %ecx,%eax
801036b6:	c1 f8 02             	sar    $0x2,%eax
801036b9:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801036bf:	5d                   	pop    %ebp
801036c0:	c3                   	ret    

801036c1 <sum>:

static uchar
sum(uchar *addr, int len)
{
801036c1:	55                   	push   %ebp
801036c2:	89 e5                	mov    %esp,%ebp
801036c4:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801036c7:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801036ce:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801036d5:	eb 13                	jmp    801036ea <sum+0x29>
    sum += addr[i];
801036d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801036da:	03 45 08             	add    0x8(%ebp),%eax
801036dd:	0f b6 00             	movzbl (%eax),%eax
801036e0:	0f b6 c0             	movzbl %al,%eax
801036e3:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801036e6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801036ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
801036ed:	3b 45 0c             	cmp    0xc(%ebp),%eax
801036f0:	7c e5                	jl     801036d7 <sum+0x16>
    sum += addr[i];
  return sum;
801036f2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801036f5:	c9                   	leave  
801036f6:	c3                   	ret    

801036f7 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801036f7:	55                   	push   %ebp
801036f8:	89 e5                	mov    %esp,%ebp
801036fa:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801036fd:	8b 45 08             	mov    0x8(%ebp),%eax
80103700:	89 04 24             	mov    %eax,(%esp)
80103703:	e8 44 ff ff ff       	call   8010364c <p2v>
80103708:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
8010370b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010370e:	03 45 f0             	add    -0x10(%ebp),%eax
80103711:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103714:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103717:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010371a:	eb 3f                	jmp    8010375b <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
8010371c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103723:	00 
80103724:	c7 44 24 04 44 84 10 	movl   $0x80108444,0x4(%esp)
8010372b:	80 
8010372c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010372f:	89 04 24             	mov    %eax,(%esp)
80103732:	e8 72 17 00 00       	call   80104ea9 <memcmp>
80103737:	85 c0                	test   %eax,%eax
80103739:	75 1c                	jne    80103757 <mpsearch1+0x60>
8010373b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103742:	00 
80103743:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103746:	89 04 24             	mov    %eax,(%esp)
80103749:	e8 73 ff ff ff       	call   801036c1 <sum>
8010374e:	84 c0                	test   %al,%al
80103750:	75 05                	jne    80103757 <mpsearch1+0x60>
      return (struct mp*)p;
80103752:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103755:	eb 11                	jmp    80103768 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103757:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010375b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010375e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103761:	72 b9                	jb     8010371c <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103763:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103768:	c9                   	leave  
80103769:	c3                   	ret    

8010376a <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
8010376a:	55                   	push   %ebp
8010376b:	89 e5                	mov    %esp,%ebp
8010376d:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103770:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103777:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010377a:	83 c0 0f             	add    $0xf,%eax
8010377d:	0f b6 00             	movzbl (%eax),%eax
80103780:	0f b6 c0             	movzbl %al,%eax
80103783:	89 c2                	mov    %eax,%edx
80103785:	c1 e2 08             	shl    $0x8,%edx
80103788:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010378b:	83 c0 0e             	add    $0xe,%eax
8010378e:	0f b6 00             	movzbl (%eax),%eax
80103791:	0f b6 c0             	movzbl %al,%eax
80103794:	09 d0                	or     %edx,%eax
80103796:	c1 e0 04             	shl    $0x4,%eax
80103799:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010379c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801037a0:	74 21                	je     801037c3 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801037a2:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801037a9:	00 
801037aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037ad:	89 04 24             	mov    %eax,(%esp)
801037b0:	e8 42 ff ff ff       	call   801036f7 <mpsearch1>
801037b5:	89 45 ec             	mov    %eax,-0x14(%ebp)
801037b8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801037bc:	74 50                	je     8010380e <mpsearch+0xa4>
      return mp;
801037be:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037c1:	eb 5f                	jmp    80103822 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801037c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037c6:	83 c0 14             	add    $0x14,%eax
801037c9:	0f b6 00             	movzbl (%eax),%eax
801037cc:	0f b6 c0             	movzbl %al,%eax
801037cf:	89 c2                	mov    %eax,%edx
801037d1:	c1 e2 08             	shl    $0x8,%edx
801037d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037d7:	83 c0 13             	add    $0x13,%eax
801037da:	0f b6 00             	movzbl (%eax),%eax
801037dd:	0f b6 c0             	movzbl %al,%eax
801037e0:	09 d0                	or     %edx,%eax
801037e2:	c1 e0 0a             	shl    $0xa,%eax
801037e5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801037e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037eb:	2d 00 04 00 00       	sub    $0x400,%eax
801037f0:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801037f7:	00 
801037f8:	89 04 24             	mov    %eax,(%esp)
801037fb:	e8 f7 fe ff ff       	call   801036f7 <mpsearch1>
80103800:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103803:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103807:	74 05                	je     8010380e <mpsearch+0xa4>
      return mp;
80103809:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010380c:	eb 14                	jmp    80103822 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
8010380e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103815:	00 
80103816:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
8010381d:	e8 d5 fe ff ff       	call   801036f7 <mpsearch1>
}
80103822:	c9                   	leave  
80103823:	c3                   	ret    

80103824 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103824:	55                   	push   %ebp
80103825:	89 e5                	mov    %esp,%ebp
80103827:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
8010382a:	e8 3b ff ff ff       	call   8010376a <mpsearch>
8010382f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103832:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103836:	74 0a                	je     80103842 <mpconfig+0x1e>
80103838:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010383b:	8b 40 04             	mov    0x4(%eax),%eax
8010383e:	85 c0                	test   %eax,%eax
80103840:	75 0a                	jne    8010384c <mpconfig+0x28>
    return 0;
80103842:	b8 00 00 00 00       	mov    $0x0,%eax
80103847:	e9 83 00 00 00       	jmp    801038cf <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
8010384c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010384f:	8b 40 04             	mov    0x4(%eax),%eax
80103852:	89 04 24             	mov    %eax,(%esp)
80103855:	e8 f2 fd ff ff       	call   8010364c <p2v>
8010385a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
8010385d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103864:	00 
80103865:	c7 44 24 04 49 84 10 	movl   $0x80108449,0x4(%esp)
8010386c:	80 
8010386d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103870:	89 04 24             	mov    %eax,(%esp)
80103873:	e8 31 16 00 00       	call   80104ea9 <memcmp>
80103878:	85 c0                	test   %eax,%eax
8010387a:	74 07                	je     80103883 <mpconfig+0x5f>
    return 0;
8010387c:	b8 00 00 00 00       	mov    $0x0,%eax
80103881:	eb 4c                	jmp    801038cf <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103883:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103886:	0f b6 40 06          	movzbl 0x6(%eax),%eax
8010388a:	3c 01                	cmp    $0x1,%al
8010388c:	74 12                	je     801038a0 <mpconfig+0x7c>
8010388e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103891:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103895:	3c 04                	cmp    $0x4,%al
80103897:	74 07                	je     801038a0 <mpconfig+0x7c>
    return 0;
80103899:	b8 00 00 00 00       	mov    $0x0,%eax
8010389e:	eb 2f                	jmp    801038cf <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801038a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038a3:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801038a7:	0f b7 c0             	movzwl %ax,%eax
801038aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801038ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038b1:	89 04 24             	mov    %eax,(%esp)
801038b4:	e8 08 fe ff ff       	call   801036c1 <sum>
801038b9:	84 c0                	test   %al,%al
801038bb:	74 07                	je     801038c4 <mpconfig+0xa0>
    return 0;
801038bd:	b8 00 00 00 00       	mov    $0x0,%eax
801038c2:	eb 0b                	jmp    801038cf <mpconfig+0xab>
  *pmp = mp;
801038c4:	8b 45 08             	mov    0x8(%ebp),%eax
801038c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038ca:	89 10                	mov    %edx,(%eax)
  return conf;
801038cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801038cf:	c9                   	leave  
801038d0:	c3                   	ret    

801038d1 <mpinit>:

void
mpinit(void)
{
801038d1:	55                   	push   %ebp
801038d2:	89 e5                	mov    %esp,%ebp
801038d4:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801038d7:	c7 05 44 b6 10 80 40 	movl   $0x8010fe40,0x8010b644
801038de:	fe 10 80 
  if((conf = mpconfig(&mp)) == 0)
801038e1:	8d 45 e0             	lea    -0x20(%ebp),%eax
801038e4:	89 04 24             	mov    %eax,(%esp)
801038e7:	e8 38 ff ff ff       	call   80103824 <mpconfig>
801038ec:	89 45 f0             	mov    %eax,-0x10(%ebp)
801038ef:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038f3:	0f 84 9c 01 00 00    	je     80103a95 <mpinit+0x1c4>
    return;
  ismp = 1;
801038f9:	c7 05 24 fe 10 80 01 	movl   $0x1,0x8010fe24
80103900:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103903:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103906:	8b 40 24             	mov    0x24(%eax),%eax
80103909:	a3 9c fd 10 80       	mov    %eax,0x8010fd9c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010390e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103911:	83 c0 2c             	add    $0x2c,%eax
80103914:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103917:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010391a:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010391e:	0f b7 c0             	movzwl %ax,%eax
80103921:	03 45 f0             	add    -0x10(%ebp),%eax
80103924:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103927:	e9 f4 00 00 00       	jmp    80103a20 <mpinit+0x14f>
    switch(*p){
8010392c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010392f:	0f b6 00             	movzbl (%eax),%eax
80103932:	0f b6 c0             	movzbl %al,%eax
80103935:	83 f8 04             	cmp    $0x4,%eax
80103938:	0f 87 bf 00 00 00    	ja     801039fd <mpinit+0x12c>
8010393e:	8b 04 85 8c 84 10 80 	mov    -0x7fef7b74(,%eax,4),%eax
80103945:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103947:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010394a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
8010394d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103950:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103954:	0f b6 d0             	movzbl %al,%edx
80103957:	a1 20 04 11 80       	mov    0x80110420,%eax
8010395c:	39 c2                	cmp    %eax,%edx
8010395e:	74 2d                	je     8010398d <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103960:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103963:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103967:	0f b6 d0             	movzbl %al,%edx
8010396a:	a1 20 04 11 80       	mov    0x80110420,%eax
8010396f:	89 54 24 08          	mov    %edx,0x8(%esp)
80103973:	89 44 24 04          	mov    %eax,0x4(%esp)
80103977:	c7 04 24 4e 84 10 80 	movl   $0x8010844e,(%esp)
8010397e:	e8 1e ca ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103983:	c7 05 24 fe 10 80 00 	movl   $0x0,0x8010fe24
8010398a:	00 00 00 
      }
      if(proc->flags & MPBOOT)
8010398d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103990:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103994:	0f b6 c0             	movzbl %al,%eax
80103997:	83 e0 02             	and    $0x2,%eax
8010399a:	85 c0                	test   %eax,%eax
8010399c:	74 15                	je     801039b3 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
8010399e:	a1 20 04 11 80       	mov    0x80110420,%eax
801039a3:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801039a9:	05 40 fe 10 80       	add    $0x8010fe40,%eax
801039ae:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
801039b3:	8b 15 20 04 11 80    	mov    0x80110420,%edx
801039b9:	a1 20 04 11 80       	mov    0x80110420,%eax
801039be:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
801039c4:	81 c2 40 fe 10 80    	add    $0x8010fe40,%edx
801039ca:	88 02                	mov    %al,(%edx)
      ncpu++;
801039cc:	a1 20 04 11 80       	mov    0x80110420,%eax
801039d1:	83 c0 01             	add    $0x1,%eax
801039d4:	a3 20 04 11 80       	mov    %eax,0x80110420
      p += sizeof(struct mpproc);
801039d9:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
801039dd:	eb 41                	jmp    80103a20 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
801039df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
801039e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801039e8:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801039ec:	a2 20 fe 10 80       	mov    %al,0x8010fe20
      p += sizeof(struct mpioapic);
801039f1:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801039f5:	eb 29                	jmp    80103a20 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
801039f7:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801039fb:	eb 23                	jmp    80103a20 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
801039fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a00:	0f b6 00             	movzbl (%eax),%eax
80103a03:	0f b6 c0             	movzbl %al,%eax
80103a06:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a0a:	c7 04 24 6c 84 10 80 	movl   $0x8010846c,(%esp)
80103a11:	e8 8b c9 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103a16:	c7 05 24 fe 10 80 00 	movl   $0x0,0x8010fe24
80103a1d:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103a20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a23:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103a26:	0f 82 00 ff ff ff    	jb     8010392c <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103a2c:	a1 24 fe 10 80       	mov    0x8010fe24,%eax
80103a31:	85 c0                	test   %eax,%eax
80103a33:	75 1d                	jne    80103a52 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103a35:	c7 05 20 04 11 80 01 	movl   $0x1,0x80110420
80103a3c:	00 00 00 
    lapic = 0;
80103a3f:	c7 05 9c fd 10 80 00 	movl   $0x0,0x8010fd9c
80103a46:	00 00 00 
    ioapicid = 0;
80103a49:	c6 05 20 fe 10 80 00 	movb   $0x0,0x8010fe20
    return;
80103a50:	eb 44                	jmp    80103a96 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103a52:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103a55:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103a59:	84 c0                	test   %al,%al
80103a5b:	74 39                	je     80103a96 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103a5d:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103a64:	00 
80103a65:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103a6c:	e8 12 fc ff ff       	call   80103683 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103a71:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103a78:	e8 dc fb ff ff       	call   80103659 <inb>
80103a7d:	83 c8 01             	or     $0x1,%eax
80103a80:	0f b6 c0             	movzbl %al,%eax
80103a83:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a87:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103a8e:	e8 f0 fb ff ff       	call   80103683 <outb>
80103a93:	eb 01                	jmp    80103a96 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103a95:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103a96:	c9                   	leave  
80103a97:	c3                   	ret    

80103a98 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103a98:	55                   	push   %ebp
80103a99:	89 e5                	mov    %esp,%ebp
80103a9b:	83 ec 08             	sub    $0x8,%esp
80103a9e:	8b 55 08             	mov    0x8(%ebp),%edx
80103aa1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103aa4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103aa8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103aab:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103aaf:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103ab3:	ee                   	out    %al,(%dx)
}
80103ab4:	c9                   	leave  
80103ab5:	c3                   	ret    

80103ab6 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103ab6:	55                   	push   %ebp
80103ab7:	89 e5                	mov    %esp,%ebp
80103ab9:	83 ec 0c             	sub    $0xc,%esp
80103abc:	8b 45 08             	mov    0x8(%ebp),%eax
80103abf:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103ac3:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ac7:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103acd:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ad1:	0f b6 c0             	movzbl %al,%eax
80103ad4:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ad8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103adf:	e8 b4 ff ff ff       	call   80103a98 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103ae4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ae8:	66 c1 e8 08          	shr    $0x8,%ax
80103aec:	0f b6 c0             	movzbl %al,%eax
80103aef:	89 44 24 04          	mov    %eax,0x4(%esp)
80103af3:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103afa:	e8 99 ff ff ff       	call   80103a98 <outb>
}
80103aff:	c9                   	leave  
80103b00:	c3                   	ret    

80103b01 <picenable>:

void
picenable(int irq)
{
80103b01:	55                   	push   %ebp
80103b02:	89 e5                	mov    %esp,%ebp
80103b04:	53                   	push   %ebx
80103b05:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103b08:	8b 45 08             	mov    0x8(%ebp),%eax
80103b0b:	ba 01 00 00 00       	mov    $0x1,%edx
80103b10:	89 d3                	mov    %edx,%ebx
80103b12:	89 c1                	mov    %eax,%ecx
80103b14:	d3 e3                	shl    %cl,%ebx
80103b16:	89 d8                	mov    %ebx,%eax
80103b18:	89 c2                	mov    %eax,%edx
80103b1a:	f7 d2                	not    %edx
80103b1c:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103b23:	21 d0                	and    %edx,%eax
80103b25:	0f b7 c0             	movzwl %ax,%eax
80103b28:	89 04 24             	mov    %eax,(%esp)
80103b2b:	e8 86 ff ff ff       	call   80103ab6 <picsetmask>
}
80103b30:	83 c4 04             	add    $0x4,%esp
80103b33:	5b                   	pop    %ebx
80103b34:	5d                   	pop    %ebp
80103b35:	c3                   	ret    

80103b36 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103b36:	55                   	push   %ebp
80103b37:	89 e5                	mov    %esp,%ebp
80103b39:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103b3c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103b43:	00 
80103b44:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b4b:	e8 48 ff ff ff       	call   80103a98 <outb>
  outb(IO_PIC2+1, 0xFF);
80103b50:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103b57:	00 
80103b58:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b5f:	e8 34 ff ff ff       	call   80103a98 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103b64:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103b6b:	00 
80103b6c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103b73:	e8 20 ff ff ff       	call   80103a98 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103b78:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103b7f:	00 
80103b80:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b87:	e8 0c ff ff ff       	call   80103a98 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103b8c:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103b93:	00 
80103b94:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b9b:	e8 f8 fe ff ff       	call   80103a98 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103ba0:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103ba7:	00 
80103ba8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103baf:	e8 e4 fe ff ff       	call   80103a98 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103bb4:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103bbb:	00 
80103bbc:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103bc3:	e8 d0 fe ff ff       	call   80103a98 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103bc8:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103bcf:	00 
80103bd0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103bd7:	e8 bc fe ff ff       	call   80103a98 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103bdc:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103be3:	00 
80103be4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103beb:	e8 a8 fe ff ff       	call   80103a98 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103bf0:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103bf7:	00 
80103bf8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103bff:	e8 94 fe ff ff       	call   80103a98 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103c04:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103c0b:	00 
80103c0c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c13:	e8 80 fe ff ff       	call   80103a98 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103c18:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103c1f:	00 
80103c20:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c27:	e8 6c fe ff ff       	call   80103a98 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103c2c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103c33:	00 
80103c34:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c3b:	e8 58 fe ff ff       	call   80103a98 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103c40:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103c47:	00 
80103c48:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c4f:	e8 44 fe ff ff       	call   80103a98 <outb>

  if(irqmask != 0xFFFF)
80103c54:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c5b:	66 83 f8 ff          	cmp    $0xffff,%ax
80103c5f:	74 12                	je     80103c73 <picinit+0x13d>
    picsetmask(irqmask);
80103c61:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c68:	0f b7 c0             	movzwl %ax,%eax
80103c6b:	89 04 24             	mov    %eax,(%esp)
80103c6e:	e8 43 fe ff ff       	call   80103ab6 <picsetmask>
}
80103c73:	c9                   	leave  
80103c74:	c3                   	ret    
80103c75:	00 00                	add    %al,(%eax)
	...

80103c78 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103c78:	55                   	push   %ebp
80103c79:	89 e5                	mov    %esp,%ebp
80103c7b:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103c7e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103c85:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c88:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c91:	8b 10                	mov    (%eax),%edx
80103c93:	8b 45 08             	mov    0x8(%ebp),%eax
80103c96:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103c98:	e8 bf d2 ff ff       	call   80100f5c <filealloc>
80103c9d:	8b 55 08             	mov    0x8(%ebp),%edx
80103ca0:	89 02                	mov    %eax,(%edx)
80103ca2:	8b 45 08             	mov    0x8(%ebp),%eax
80103ca5:	8b 00                	mov    (%eax),%eax
80103ca7:	85 c0                	test   %eax,%eax
80103ca9:	0f 84 c8 00 00 00    	je     80103d77 <pipealloc+0xff>
80103caf:	e8 a8 d2 ff ff       	call   80100f5c <filealloc>
80103cb4:	8b 55 0c             	mov    0xc(%ebp),%edx
80103cb7:	89 02                	mov    %eax,(%edx)
80103cb9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cbc:	8b 00                	mov    (%eax),%eax
80103cbe:	85 c0                	test   %eax,%eax
80103cc0:	0f 84 b1 00 00 00    	je     80103d77 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103cc6:	e8 74 ee ff ff       	call   80102b3f <kalloc>
80103ccb:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103cce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103cd2:	0f 84 9e 00 00 00    	je     80103d76 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cdb:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103ce2:	00 00 00 
  p->writeopen = 1;
80103ce5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ce8:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103cef:	00 00 00 
  p->nwrite = 0;
80103cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cf5:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103cfc:	00 00 00 
  p->nread = 0;
80103cff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d02:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103d09:	00 00 00 
  initlock(&p->lock, "pipe");
80103d0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d0f:	c7 44 24 04 a0 84 10 	movl   $0x801084a0,0x4(%esp)
80103d16:	80 
80103d17:	89 04 24             	mov    %eax,(%esp)
80103d1a:	e8 a3 0e 00 00       	call   80104bc2 <initlock>
  (*f0)->type = FD_PIPE;
80103d1f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d22:	8b 00                	mov    (%eax),%eax
80103d24:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80103d2d:	8b 00                	mov    (%eax),%eax
80103d2f:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103d33:	8b 45 08             	mov    0x8(%ebp),%eax
80103d36:	8b 00                	mov    (%eax),%eax
80103d38:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103d3c:	8b 45 08             	mov    0x8(%ebp),%eax
80103d3f:	8b 00                	mov    (%eax),%eax
80103d41:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d44:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103d47:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d4a:	8b 00                	mov    (%eax),%eax
80103d4c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103d52:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d55:	8b 00                	mov    (%eax),%eax
80103d57:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103d5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d5e:	8b 00                	mov    (%eax),%eax
80103d60:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103d64:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d67:	8b 00                	mov    (%eax),%eax
80103d69:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d6c:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103d6f:	b8 00 00 00 00       	mov    $0x0,%eax
80103d74:	eb 43                	jmp    80103db9 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103d76:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103d77:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d7b:	74 0b                	je     80103d88 <pipealloc+0x110>
    kfree((char*)p);
80103d7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d80:	89 04 24             	mov    %eax,(%esp)
80103d83:	e8 1e ed ff ff       	call   80102aa6 <kfree>
  if(*f0)
80103d88:	8b 45 08             	mov    0x8(%ebp),%eax
80103d8b:	8b 00                	mov    (%eax),%eax
80103d8d:	85 c0                	test   %eax,%eax
80103d8f:	74 0d                	je     80103d9e <pipealloc+0x126>
    fileclose(*f0);
80103d91:	8b 45 08             	mov    0x8(%ebp),%eax
80103d94:	8b 00                	mov    (%eax),%eax
80103d96:	89 04 24             	mov    %eax,(%esp)
80103d99:	e8 66 d2 ff ff       	call   80101004 <fileclose>
  if(*f1)
80103d9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103da1:	8b 00                	mov    (%eax),%eax
80103da3:	85 c0                	test   %eax,%eax
80103da5:	74 0d                	je     80103db4 <pipealloc+0x13c>
    fileclose(*f1);
80103da7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103daa:	8b 00                	mov    (%eax),%eax
80103dac:	89 04 24             	mov    %eax,(%esp)
80103daf:	e8 50 d2 ff ff       	call   80101004 <fileclose>
  return -1;
80103db4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103db9:	c9                   	leave  
80103dba:	c3                   	ret    

80103dbb <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103dbb:	55                   	push   %ebp
80103dbc:	89 e5                	mov    %esp,%ebp
80103dbe:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103dc1:	8b 45 08             	mov    0x8(%ebp),%eax
80103dc4:	89 04 24             	mov    %eax,(%esp)
80103dc7:	e8 17 0e 00 00       	call   80104be3 <acquire>
  if(writable){
80103dcc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103dd0:	74 1f                	je     80103df1 <pipeclose+0x36>
    p->writeopen = 0;
80103dd2:	8b 45 08             	mov    0x8(%ebp),%eax
80103dd5:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103ddc:	00 00 00 
    wakeup(&p->nread);
80103ddf:	8b 45 08             	mov    0x8(%ebp),%eax
80103de2:	05 34 02 00 00       	add    $0x234,%eax
80103de7:	89 04 24             	mov    %eax,(%esp)
80103dea:	e8 ef 0b 00 00       	call   801049de <wakeup>
80103def:	eb 1d                	jmp    80103e0e <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103df1:	8b 45 08             	mov    0x8(%ebp),%eax
80103df4:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103dfb:	00 00 00 
    wakeup(&p->nwrite);
80103dfe:	8b 45 08             	mov    0x8(%ebp),%eax
80103e01:	05 38 02 00 00       	add    $0x238,%eax
80103e06:	89 04 24             	mov    %eax,(%esp)
80103e09:	e8 d0 0b 00 00       	call   801049de <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103e0e:	8b 45 08             	mov    0x8(%ebp),%eax
80103e11:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e17:	85 c0                	test   %eax,%eax
80103e19:	75 25                	jne    80103e40 <pipeclose+0x85>
80103e1b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e1e:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103e24:	85 c0                	test   %eax,%eax
80103e26:	75 18                	jne    80103e40 <pipeclose+0x85>
    release(&p->lock);
80103e28:	8b 45 08             	mov    0x8(%ebp),%eax
80103e2b:	89 04 24             	mov    %eax,(%esp)
80103e2e:	e8 12 0e 00 00       	call   80104c45 <release>
    kfree((char*)p);
80103e33:	8b 45 08             	mov    0x8(%ebp),%eax
80103e36:	89 04 24             	mov    %eax,(%esp)
80103e39:	e8 68 ec ff ff       	call   80102aa6 <kfree>
80103e3e:	eb 0b                	jmp    80103e4b <pipeclose+0x90>
  } else
    release(&p->lock);
80103e40:	8b 45 08             	mov    0x8(%ebp),%eax
80103e43:	89 04 24             	mov    %eax,(%esp)
80103e46:	e8 fa 0d 00 00       	call   80104c45 <release>
}
80103e4b:	c9                   	leave  
80103e4c:	c3                   	ret    

80103e4d <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103e4d:	55                   	push   %ebp
80103e4e:	89 e5                	mov    %esp,%ebp
80103e50:	53                   	push   %ebx
80103e51:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103e54:	8b 45 08             	mov    0x8(%ebp),%eax
80103e57:	89 04 24             	mov    %eax,(%esp)
80103e5a:	e8 84 0d 00 00       	call   80104be3 <acquire>
  for(i = 0; i < n; i++){
80103e5f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e66:	e9 a6 00 00 00       	jmp    80103f11 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80103e6b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6e:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e74:	85 c0                	test   %eax,%eax
80103e76:	74 0d                	je     80103e85 <pipewrite+0x38>
80103e78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103e7e:	8b 40 24             	mov    0x24(%eax),%eax
80103e81:	85 c0                	test   %eax,%eax
80103e83:	74 15                	je     80103e9a <pipewrite+0x4d>
        release(&p->lock);
80103e85:	8b 45 08             	mov    0x8(%ebp),%eax
80103e88:	89 04 24             	mov    %eax,(%esp)
80103e8b:	e8 b5 0d 00 00       	call   80104c45 <release>
        return -1;
80103e90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103e95:	e9 9d 00 00 00       	jmp    80103f37 <pipewrite+0xea>
      }
      wakeup(&p->nread);
80103e9a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9d:	05 34 02 00 00       	add    $0x234,%eax
80103ea2:	89 04 24             	mov    %eax,(%esp)
80103ea5:	e8 34 0b 00 00       	call   801049de <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103eaa:	8b 45 08             	mov    0x8(%ebp),%eax
80103ead:	8b 55 08             	mov    0x8(%ebp),%edx
80103eb0:	81 c2 38 02 00 00    	add    $0x238,%edx
80103eb6:	89 44 24 04          	mov    %eax,0x4(%esp)
80103eba:	89 14 24             	mov    %edx,(%esp)
80103ebd:	e8 43 0a 00 00       	call   80104905 <sleep>
80103ec2:	eb 01                	jmp    80103ec5 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103ec4:	90                   	nop
80103ec5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec8:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103ece:	8b 45 08             	mov    0x8(%ebp),%eax
80103ed1:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103ed7:	05 00 02 00 00       	add    $0x200,%eax
80103edc:	39 c2                	cmp    %eax,%edx
80103ede:	74 8b                	je     80103e6b <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103ee0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee3:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103ee9:	89 c3                	mov    %eax,%ebx
80103eeb:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103ef1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ef4:	03 55 0c             	add    0xc(%ebp),%edx
80103ef7:	0f b6 0a             	movzbl (%edx),%ecx
80103efa:	8b 55 08             	mov    0x8(%ebp),%edx
80103efd:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80103f01:	8d 50 01             	lea    0x1(%eax),%edx
80103f04:	8b 45 08             	mov    0x8(%ebp),%eax
80103f07:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80103f0d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103f11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f14:	3b 45 10             	cmp    0x10(%ebp),%eax
80103f17:	7c ab                	jl     80103ec4 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103f19:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1c:	05 34 02 00 00       	add    $0x234,%eax
80103f21:	89 04 24             	mov    %eax,(%esp)
80103f24:	e8 b5 0a 00 00       	call   801049de <wakeup>
  release(&p->lock);
80103f29:	8b 45 08             	mov    0x8(%ebp),%eax
80103f2c:	89 04 24             	mov    %eax,(%esp)
80103f2f:	e8 11 0d 00 00       	call   80104c45 <release>
  return n;
80103f34:	8b 45 10             	mov    0x10(%ebp),%eax
}
80103f37:	83 c4 24             	add    $0x24,%esp
80103f3a:	5b                   	pop    %ebx
80103f3b:	5d                   	pop    %ebp
80103f3c:	c3                   	ret    

80103f3d <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103f3d:	55                   	push   %ebp
80103f3e:	89 e5                	mov    %esp,%ebp
80103f40:	53                   	push   %ebx
80103f41:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103f44:	8b 45 08             	mov    0x8(%ebp),%eax
80103f47:	89 04 24             	mov    %eax,(%esp)
80103f4a:	e8 94 0c 00 00       	call   80104be3 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103f4f:	eb 3a                	jmp    80103f8b <piperead+0x4e>
    if(proc->killed){
80103f51:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103f57:	8b 40 24             	mov    0x24(%eax),%eax
80103f5a:	85 c0                	test   %eax,%eax
80103f5c:	74 15                	je     80103f73 <piperead+0x36>
      release(&p->lock);
80103f5e:	8b 45 08             	mov    0x8(%ebp),%eax
80103f61:	89 04 24             	mov    %eax,(%esp)
80103f64:	e8 dc 0c 00 00       	call   80104c45 <release>
      return -1;
80103f69:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f6e:	e9 b6 00 00 00       	jmp    80104029 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103f73:	8b 45 08             	mov    0x8(%ebp),%eax
80103f76:	8b 55 08             	mov    0x8(%ebp),%edx
80103f79:	81 c2 34 02 00 00    	add    $0x234,%edx
80103f7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f83:	89 14 24             	mov    %edx,(%esp)
80103f86:	e8 7a 09 00 00       	call   80104905 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103f8b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f8e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103f94:	8b 45 08             	mov    0x8(%ebp),%eax
80103f97:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103f9d:	39 c2                	cmp    %eax,%edx
80103f9f:	75 0d                	jne    80103fae <piperead+0x71>
80103fa1:	8b 45 08             	mov    0x8(%ebp),%eax
80103fa4:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103faa:	85 c0                	test   %eax,%eax
80103fac:	75 a3                	jne    80103f51 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103fae:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103fb5:	eb 49                	jmp    80104000 <piperead+0xc3>
    if(p->nread == p->nwrite)
80103fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80103fba:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103fc0:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc3:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103fc9:	39 c2                	cmp    %eax,%edx
80103fcb:	74 3d                	je     8010400a <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103fcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fd0:	89 c2                	mov    %eax,%edx
80103fd2:	03 55 0c             	add    0xc(%ebp),%edx
80103fd5:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd8:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103fde:	89 c3                	mov    %eax,%ebx
80103fe0:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103fe6:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103fe9:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80103fee:	88 0a                	mov    %cl,(%edx)
80103ff0:	8d 50 01             	lea    0x1(%eax),%edx
80103ff3:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff6:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103ffc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104000:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104003:	3b 45 10             	cmp    0x10(%ebp),%eax
80104006:	7c af                	jl     80103fb7 <piperead+0x7a>
80104008:	eb 01                	jmp    8010400b <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
8010400a:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010400b:	8b 45 08             	mov    0x8(%ebp),%eax
8010400e:	05 38 02 00 00       	add    $0x238,%eax
80104013:	89 04 24             	mov    %eax,(%esp)
80104016:	e8 c3 09 00 00       	call   801049de <wakeup>
  release(&p->lock);
8010401b:	8b 45 08             	mov    0x8(%ebp),%eax
8010401e:	89 04 24             	mov    %eax,(%esp)
80104021:	e8 1f 0c 00 00       	call   80104c45 <release>
  return i;
80104026:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104029:	83 c4 24             	add    $0x24,%esp
8010402c:	5b                   	pop    %ebx
8010402d:	5d                   	pop    %ebp
8010402e:	c3                   	ret    
	...

80104030 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104030:	55                   	push   %ebp
80104031:	89 e5                	mov    %esp,%ebp
80104033:	53                   	push   %ebx
80104034:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104037:	9c                   	pushf  
80104038:	5b                   	pop    %ebx
80104039:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
8010403c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010403f:	83 c4 10             	add    $0x10,%esp
80104042:	5b                   	pop    %ebx
80104043:	5d                   	pop    %ebp
80104044:	c3                   	ret    

80104045 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104045:	55                   	push   %ebp
80104046:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104048:	fb                   	sti    
}
80104049:	5d                   	pop    %ebp
8010404a:	c3                   	ret    

8010404b <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
8010404b:	55                   	push   %ebp
8010404c:	89 e5                	mov    %esp,%ebp
8010404e:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104051:	c7 44 24 04 a5 84 10 	movl   $0x801084a5,0x4(%esp)
80104058:	80 
80104059:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104060:	e8 5d 0b 00 00       	call   80104bc2 <initlock>
}
80104065:	c9                   	leave  
80104066:	c3                   	ret    

80104067 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104067:	55                   	push   %ebp
80104068:	89 e5                	mov    %esp,%ebp
8010406a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
8010406d:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104074:	e8 6a 0b 00 00       	call   80104be3 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104079:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104080:	eb 0e                	jmp    80104090 <allocproc+0x29>
    if(p->state == UNUSED)
80104082:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104085:	8b 40 0c             	mov    0xc(%eax),%eax
80104088:	85 c0                	test   %eax,%eax
8010408a:	74 23                	je     801040af <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010408c:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104090:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
80104097:	72 e9                	jb     80104082 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104099:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801040a0:	e8 a0 0b 00 00       	call   80104c45 <release>
  return 0;
801040a5:	b8 00 00 00 00       	mov    $0x0,%eax
801040aa:	e9 b5 00 00 00       	jmp    80104164 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801040af:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801040b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040b3:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801040ba:	a1 04 b0 10 80       	mov    0x8010b004,%eax
801040bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040c2:	89 42 10             	mov    %eax,0x10(%edx)
801040c5:	83 c0 01             	add    $0x1,%eax
801040c8:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
801040cd:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801040d4:	e8 6c 0b 00 00       	call   80104c45 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801040d9:	e8 61 ea ff ff       	call   80102b3f <kalloc>
801040de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040e1:	89 42 08             	mov    %eax,0x8(%edx)
801040e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040e7:	8b 40 08             	mov    0x8(%eax),%eax
801040ea:	85 c0                	test   %eax,%eax
801040ec:	75 11                	jne    801040ff <allocproc+0x98>
    p->state = UNUSED;
801040ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040f1:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801040f8:	b8 00 00 00 00       	mov    $0x0,%eax
801040fd:	eb 65                	jmp    80104164 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
801040ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104102:	8b 40 08             	mov    0x8(%eax),%eax
80104105:	05 00 10 00 00       	add    $0x1000,%eax
8010410a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
8010410d:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104111:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104114:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104117:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
8010411a:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
8010411e:	ba 8c 62 10 80       	mov    $0x8010628c,%edx
80104123:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104126:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104128:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
8010412c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010412f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104132:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104135:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104138:	8b 40 1c             	mov    0x1c(%eax),%eax
8010413b:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104142:	00 
80104143:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010414a:	00 
8010414b:	89 04 24             	mov    %eax,(%esp)
8010414e:	e8 df 0c 00 00       	call   80104e32 <memset>
  p->context->eip = (uint)forkret;
80104153:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104156:	8b 40 1c             	mov    0x1c(%eax),%eax
80104159:	ba d9 48 10 80       	mov    $0x801048d9,%edx
8010415e:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104161:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104164:	c9                   	leave  
80104165:	c3                   	ret    

80104166 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104166:	55                   	push   %ebp
80104167:	89 e5                	mov    %esp,%ebp
80104169:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
8010416c:	e8 f6 fe ff ff       	call   80104067 <allocproc>
80104171:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104174:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104177:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm(kalloc)) == 0)
8010417c:	c7 04 24 3f 2b 10 80 	movl   $0x80102b3f,(%esp)
80104183:	e8 01 38 00 00       	call   80107989 <setupkvm>
80104188:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010418b:	89 42 04             	mov    %eax,0x4(%edx)
8010418e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104191:	8b 40 04             	mov    0x4(%eax),%eax
80104194:	85 c0                	test   %eax,%eax
80104196:	75 0c                	jne    801041a4 <userinit+0x3e>
    panic("userinit: out of memory?");
80104198:	c7 04 24 ac 84 10 80 	movl   $0x801084ac,(%esp)
8010419f:	e8 99 c3 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801041a4:	ba 2c 00 00 00       	mov    $0x2c,%edx
801041a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ac:	8b 40 04             	mov    0x4(%eax),%eax
801041af:	89 54 24 08          	mov    %edx,0x8(%esp)
801041b3:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
801041ba:	80 
801041bb:	89 04 24             	mov    %eax,(%esp)
801041be:	e8 1e 3a 00 00       	call   80107be1 <inituvm>
  p->sz = PGSIZE;
801041c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c6:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801041cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041cf:	8b 40 18             	mov    0x18(%eax),%eax
801041d2:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801041d9:	00 
801041da:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801041e1:	00 
801041e2:	89 04 24             	mov    %eax,(%esp)
801041e5:	e8 48 0c 00 00       	call   80104e32 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801041ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ed:	8b 40 18             	mov    0x18(%eax),%eax
801041f0:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801041f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041f9:	8b 40 18             	mov    0x18(%eax),%eax
801041fc:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104202:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104205:	8b 40 18             	mov    0x18(%eax),%eax
80104208:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010420b:	8b 52 18             	mov    0x18(%edx),%edx
8010420e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104212:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104216:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104219:	8b 40 18             	mov    0x18(%eax),%eax
8010421c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010421f:	8b 52 18             	mov    0x18(%edx),%edx
80104222:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104226:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010422a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010422d:	8b 40 18             	mov    0x18(%eax),%eax
80104230:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104237:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010423a:	8b 40 18             	mov    0x18(%eax),%eax
8010423d:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104244:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104247:	8b 40 18             	mov    0x18(%eax),%eax
8010424a:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104251:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104254:	83 c0 6c             	add    $0x6c,%eax
80104257:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010425e:	00 
8010425f:	c7 44 24 04 c5 84 10 	movl   $0x801084c5,0x4(%esp)
80104266:	80 
80104267:	89 04 24             	mov    %eax,(%esp)
8010426a:	e8 f3 0d 00 00       	call   80105062 <safestrcpy>
  p->cwd = namei("/");
8010426f:	c7 04 24 ce 84 10 80 	movl   $0x801084ce,(%esp)
80104276:	e8 cf e1 ff ff       	call   8010244a <namei>
8010427b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010427e:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104281:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104284:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
8010428b:	c9                   	leave  
8010428c:	c3                   	ret    

8010428d <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
8010428d:	55                   	push   %ebp
8010428e:	89 e5                	mov    %esp,%ebp
80104290:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104293:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104299:	8b 00                	mov    (%eax),%eax
8010429b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010429e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801042a2:	7e 34                	jle    801042d8 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801042a4:	8b 45 08             	mov    0x8(%ebp),%eax
801042a7:	89 c2                	mov    %eax,%edx
801042a9:	03 55 f4             	add    -0xc(%ebp),%edx
801042ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801042b2:	8b 40 04             	mov    0x4(%eax),%eax
801042b5:	89 54 24 08          	mov    %edx,0x8(%esp)
801042b9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042bc:	89 54 24 04          	mov    %edx,0x4(%esp)
801042c0:	89 04 24             	mov    %eax,(%esp)
801042c3:	e8 93 3a 00 00       	call   80107d5b <allocuvm>
801042c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801042cb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801042cf:	75 41                	jne    80104312 <growproc+0x85>
      return -1;
801042d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042d6:	eb 58                	jmp    80104330 <growproc+0xa3>
  } else if(n < 0){
801042d8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801042dc:	79 34                	jns    80104312 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801042de:	8b 45 08             	mov    0x8(%ebp),%eax
801042e1:	89 c2                	mov    %eax,%edx
801042e3:	03 55 f4             	add    -0xc(%ebp),%edx
801042e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801042ec:	8b 40 04             	mov    0x4(%eax),%eax
801042ef:	89 54 24 08          	mov    %edx,0x8(%esp)
801042f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042f6:	89 54 24 04          	mov    %edx,0x4(%esp)
801042fa:	89 04 24             	mov    %eax,(%esp)
801042fd:	e8 33 3b 00 00       	call   80107e35 <deallocuvm>
80104302:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104305:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104309:	75 07                	jne    80104312 <growproc+0x85>
      return -1;
8010430b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104310:	eb 1e                	jmp    80104330 <growproc+0xa3>
  }
  proc->sz = sz;
80104312:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104318:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010431b:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
8010431d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104323:	89 04 24             	mov    %eax,(%esp)
80104326:	e8 4f 37 00 00       	call   80107a7a <switchuvm>
  return 0;
8010432b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104330:	c9                   	leave  
80104331:	c3                   	ret    

80104332 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104332:	55                   	push   %ebp
80104333:	89 e5                	mov    %esp,%ebp
80104335:	57                   	push   %edi
80104336:	56                   	push   %esi
80104337:	53                   	push   %ebx
80104338:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
8010433b:	e8 27 fd ff ff       	call   80104067 <allocproc>
80104340:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104343:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104347:	75 0a                	jne    80104353 <fork+0x21>
    return -1;
80104349:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010434e:	e9 3a 01 00 00       	jmp    8010448d <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104353:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104359:	8b 10                	mov    (%eax),%edx
8010435b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104361:	8b 40 04             	mov    0x4(%eax),%eax
80104364:	89 54 24 04          	mov    %edx,0x4(%esp)
80104368:	89 04 24             	mov    %eax,(%esp)
8010436b:	e8 55 3c 00 00       	call   80107fc5 <copyuvm>
80104370:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104373:	89 42 04             	mov    %eax,0x4(%edx)
80104376:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104379:	8b 40 04             	mov    0x4(%eax),%eax
8010437c:	85 c0                	test   %eax,%eax
8010437e:	75 2c                	jne    801043ac <fork+0x7a>
    kfree(np->kstack);
80104380:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104383:	8b 40 08             	mov    0x8(%eax),%eax
80104386:	89 04 24             	mov    %eax,(%esp)
80104389:	e8 18 e7 ff ff       	call   80102aa6 <kfree>
    np->kstack = 0;
8010438e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104391:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104398:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010439b:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801043a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043a7:	e9 e1 00 00 00       	jmp    8010448d <fork+0x15b>
  }
  np->sz = proc->sz;
801043ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043b2:	8b 10                	mov    (%eax),%edx
801043b4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043b7:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801043b9:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801043c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043c3:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801043c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043c9:	8b 50 18             	mov    0x18(%eax),%edx
801043cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043d2:	8b 40 18             	mov    0x18(%eax),%eax
801043d5:	89 c3                	mov    %eax,%ebx
801043d7:	b8 13 00 00 00       	mov    $0x13,%eax
801043dc:	89 d7                	mov    %edx,%edi
801043de:	89 de                	mov    %ebx,%esi
801043e0:	89 c1                	mov    %eax,%ecx
801043e2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801043e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043e7:	8b 40 18             	mov    0x18(%eax),%eax
801043ea:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801043f1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801043f8:	eb 3d                	jmp    80104437 <fork+0x105>
    if(proc->ofile[i])
801043fa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104400:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104403:	83 c2 08             	add    $0x8,%edx
80104406:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010440a:	85 c0                	test   %eax,%eax
8010440c:	74 25                	je     80104433 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
8010440e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104414:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104417:	83 c2 08             	add    $0x8,%edx
8010441a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010441e:	89 04 24             	mov    %eax,(%esp)
80104421:	e8 96 cb ff ff       	call   80100fbc <filedup>
80104426:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104429:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010442c:	83 c1 08             	add    $0x8,%ecx
8010442f:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104433:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104437:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
8010443b:	7e bd                	jle    801043fa <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
8010443d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104443:	8b 40 68             	mov    0x68(%eax),%eax
80104446:	89 04 24             	mov    %eax,(%esp)
80104449:	e8 28 d4 ff ff       	call   80101876 <idup>
8010444e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104451:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104454:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104457:	8b 40 10             	mov    0x10(%eax),%eax
8010445a:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
8010445d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104460:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104467:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010446d:	8d 50 6c             	lea    0x6c(%eax),%edx
80104470:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104473:	83 c0 6c             	add    $0x6c,%eax
80104476:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010447d:	00 
8010447e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104482:	89 04 24             	mov    %eax,(%esp)
80104485:	e8 d8 0b 00 00       	call   80105062 <safestrcpy>
  return pid;
8010448a:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010448d:	83 c4 2c             	add    $0x2c,%esp
80104490:	5b                   	pop    %ebx
80104491:	5e                   	pop    %esi
80104492:	5f                   	pop    %edi
80104493:	5d                   	pop    %ebp
80104494:	c3                   	ret    

80104495 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104495:	55                   	push   %ebp
80104496:	89 e5                	mov    %esp,%ebp
80104498:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010449b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801044a2:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801044a7:	39 c2                	cmp    %eax,%edx
801044a9:	75 0c                	jne    801044b7 <exit+0x22>
    panic("init exiting");
801044ab:	c7 04 24 d0 84 10 80 	movl   $0x801084d0,(%esp)
801044b2:	e8 86 c0 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801044b7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801044be:	eb 44                	jmp    80104504 <exit+0x6f>
    if(proc->ofile[fd]){
801044c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044c6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044c9:	83 c2 08             	add    $0x8,%edx
801044cc:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801044d0:	85 c0                	test   %eax,%eax
801044d2:	74 2c                	je     80104500 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801044d4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044da:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044dd:	83 c2 08             	add    $0x8,%edx
801044e0:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801044e4:	89 04 24             	mov    %eax,(%esp)
801044e7:	e8 18 cb ff ff       	call   80101004 <fileclose>
      proc->ofile[fd] = 0;
801044ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044f2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801044f5:	83 c2 08             	add    $0x8,%edx
801044f8:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801044ff:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104500:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104504:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104508:	7e b6                	jle    801044c0 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
8010450a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104510:	8b 40 68             	mov    0x68(%eax),%eax
80104513:	89 04 24             	mov    %eax,(%esp)
80104516:	e8 40 d5 ff ff       	call   80101a5b <iput>
  proc->cwd = 0;
8010451b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104521:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104528:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010452f:	e8 af 06 00 00       	call   80104be3 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104534:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010453a:	8b 40 14             	mov    0x14(%eax),%eax
8010453d:	89 04 24             	mov    %eax,(%esp)
80104540:	e8 5b 04 00 00       	call   801049a0 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104545:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
8010454c:	eb 38                	jmp    80104586 <exit+0xf1>
    if(p->parent == proc){
8010454e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104551:	8b 50 14             	mov    0x14(%eax),%edx
80104554:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010455a:	39 c2                	cmp    %eax,%edx
8010455c:	75 24                	jne    80104582 <exit+0xed>
      p->parent = initproc;
8010455e:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104564:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104567:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010456a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010456d:	8b 40 0c             	mov    0xc(%eax),%eax
80104570:	83 f8 05             	cmp    $0x5,%eax
80104573:	75 0d                	jne    80104582 <exit+0xed>
        wakeup1(initproc);
80104575:	a1 48 b6 10 80       	mov    0x8010b648,%eax
8010457a:	89 04 24             	mov    %eax,(%esp)
8010457d:	e8 1e 04 00 00       	call   801049a0 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104582:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104586:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
8010458d:	72 bf                	jb     8010454e <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
8010458f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104595:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010459c:	e8 54 02 00 00       	call   801047f5 <sched>
  panic("zombie exit");
801045a1:	c7 04 24 dd 84 10 80 	movl   $0x801084dd,(%esp)
801045a8:	e8 90 bf ff ff       	call   8010053d <panic>

801045ad <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801045ad:	55                   	push   %ebp
801045ae:	89 e5                	mov    %esp,%ebp
801045b0:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801045b3:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801045ba:	e8 24 06 00 00       	call   80104be3 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801045bf:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801045c6:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
801045cd:	e9 9a 00 00 00       	jmp    8010466c <wait+0xbf>
      if(p->parent != proc)
801045d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d5:	8b 50 14             	mov    0x14(%eax),%edx
801045d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045de:	39 c2                	cmp    %eax,%edx
801045e0:	0f 85 81 00 00 00    	jne    80104667 <wait+0xba>
        continue;
      havekids = 1;
801045e6:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801045ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f0:	8b 40 0c             	mov    0xc(%eax),%eax
801045f3:	83 f8 05             	cmp    $0x5,%eax
801045f6:	75 70                	jne    80104668 <wait+0xbb>
        // Found one.
        pid = p->pid;
801045f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045fb:	8b 40 10             	mov    0x10(%eax),%eax
801045fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104601:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104604:	8b 40 08             	mov    0x8(%eax),%eax
80104607:	89 04 24             	mov    %eax,(%esp)
8010460a:	e8 97 e4 ff ff       	call   80102aa6 <kfree>
        p->kstack = 0;
8010460f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104612:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010461c:	8b 40 04             	mov    0x4(%eax),%eax
8010461f:	89 04 24             	mov    %eax,(%esp)
80104622:	e8 ca 38 00 00       	call   80107ef1 <freevm>
        p->state = UNUSED;
80104627:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010462a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104631:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104634:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
8010463b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104645:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104648:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
8010464c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010464f:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104656:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010465d:	e8 e3 05 00 00       	call   80104c45 <release>
        return pid;
80104662:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104665:	eb 53                	jmp    801046ba <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104667:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104668:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010466c:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
80104673:	0f 82 59 ff ff ff    	jb     801045d2 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104679:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010467d:	74 0d                	je     8010468c <wait+0xdf>
8010467f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104685:	8b 40 24             	mov    0x24(%eax),%eax
80104688:	85 c0                	test   %eax,%eax
8010468a:	74 13                	je     8010469f <wait+0xf2>
      release(&ptable.lock);
8010468c:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104693:	e8 ad 05 00 00       	call   80104c45 <release>
      return -1;
80104698:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010469d:	eb 1b                	jmp    801046ba <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
8010469f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a5:	c7 44 24 04 40 04 11 	movl   $0x80110440,0x4(%esp)
801046ac:	80 
801046ad:	89 04 24             	mov    %eax,(%esp)
801046b0:	e8 50 02 00 00       	call   80104905 <sleep>
  }
801046b5:	e9 05 ff ff ff       	jmp    801045bf <wait+0x12>
}
801046ba:	c9                   	leave  
801046bb:	c3                   	ret    

801046bc <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801046bc:	55                   	push   %ebp
801046bd:	89 e5                	mov    %esp,%ebp
801046bf:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801046c2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046c8:	8b 40 18             	mov    0x18(%eax),%eax
801046cb:	8b 40 44             	mov    0x44(%eax),%eax
801046ce:	89 c2                	mov    %eax,%edx
801046d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046d6:	8b 40 04             	mov    0x4(%eax),%eax
801046d9:	89 54 24 04          	mov    %edx,0x4(%esp)
801046dd:	89 04 24             	mov    %eax,(%esp)
801046e0:	e8 f1 39 00 00       	call   801080d6 <uva2ka>
801046e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
801046e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046ee:	8b 40 18             	mov    0x18(%eax),%eax
801046f1:	8b 40 44             	mov    0x44(%eax),%eax
801046f4:	25 ff 0f 00 00       	and    $0xfff,%eax
801046f9:	85 c0                	test   %eax,%eax
801046fb:	75 0c                	jne    80104709 <register_handler+0x4d>
    panic("esp_offset == 0");
801046fd:	c7 04 24 e9 84 10 80 	movl   $0x801084e9,(%esp)
80104704:	e8 34 be ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104709:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010470f:	8b 40 18             	mov    0x18(%eax),%eax
80104712:	8b 40 44             	mov    0x44(%eax),%eax
80104715:	83 e8 04             	sub    $0x4,%eax
80104718:	25 ff 0f 00 00       	and    $0xfff,%eax
8010471d:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80104720:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104727:	8b 52 18             	mov    0x18(%edx),%edx
8010472a:	8b 52 38             	mov    0x38(%edx),%edx
8010472d:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
8010472f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104735:	8b 40 18             	mov    0x18(%eax),%eax
80104738:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010473f:	8b 52 18             	mov    0x18(%edx),%edx
80104742:	8b 52 44             	mov    0x44(%edx),%edx
80104745:	83 ea 04             	sub    $0x4,%edx
80104748:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
8010474b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104751:	8b 40 18             	mov    0x18(%eax),%eax
80104754:	8b 55 08             	mov    0x8(%ebp),%edx
80104757:	89 50 38             	mov    %edx,0x38(%eax)
}
8010475a:	c9                   	leave  
8010475b:	c3                   	ret    

8010475c <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
8010475c:	55                   	push   %ebp
8010475d:	89 e5                	mov    %esp,%ebp
8010475f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104762:	e8 de f8 ff ff       	call   80104045 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104767:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010476e:	e8 70 04 00 00       	call   80104be3 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104773:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
8010477a:	eb 5f                	jmp    801047db <scheduler+0x7f>
      if(p->state != RUNNABLE)
8010477c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010477f:	8b 40 0c             	mov    0xc(%eax),%eax
80104782:	83 f8 03             	cmp    $0x3,%eax
80104785:	75 4f                	jne    801047d6 <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104787:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010478a:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104790:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104793:	89 04 24             	mov    %eax,(%esp)
80104796:	e8 df 32 00 00       	call   80107a7a <switchuvm>
      p->state = RUNNING;
8010479b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010479e:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801047a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047ab:	8b 40 1c             	mov    0x1c(%eax),%eax
801047ae:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801047b5:	83 c2 04             	add    $0x4,%edx
801047b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801047bc:	89 14 24             	mov    %edx,(%esp)
801047bf:	e8 14 09 00 00       	call   801050d8 <swtch>
      switchkvm();
801047c4:	e8 94 32 00 00       	call   80107a5d <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801047c9:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801047d0:	00 00 00 00 
801047d4:	eb 01                	jmp    801047d7 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801047d6:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047d7:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801047db:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
801047e2:	72 98                	jb     8010477c <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
801047e4:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801047eb:	e8 55 04 00 00       	call   80104c45 <release>

  }
801047f0:	e9 6d ff ff ff       	jmp    80104762 <scheduler+0x6>

801047f5 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
801047f5:	55                   	push   %ebp
801047f6:	89 e5                	mov    %esp,%ebp
801047f8:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
801047fb:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104802:	e8 fa 04 00 00       	call   80104d01 <holding>
80104807:	85 c0                	test   %eax,%eax
80104809:	75 0c                	jne    80104817 <sched+0x22>
    panic("sched ptable.lock");
8010480b:	c7 04 24 f9 84 10 80 	movl   $0x801084f9,(%esp)
80104812:	e8 26 bd ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104817:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010481d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104823:	83 f8 01             	cmp    $0x1,%eax
80104826:	74 0c                	je     80104834 <sched+0x3f>
    panic("sched locks");
80104828:	c7 04 24 0b 85 10 80 	movl   $0x8010850b,(%esp)
8010482f:	e8 09 bd ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104834:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010483a:	8b 40 0c             	mov    0xc(%eax),%eax
8010483d:	83 f8 04             	cmp    $0x4,%eax
80104840:	75 0c                	jne    8010484e <sched+0x59>
    panic("sched running");
80104842:	c7 04 24 17 85 10 80 	movl   $0x80108517,(%esp)
80104849:	e8 ef bc ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
8010484e:	e8 dd f7 ff ff       	call   80104030 <readeflags>
80104853:	25 00 02 00 00       	and    $0x200,%eax
80104858:	85 c0                	test   %eax,%eax
8010485a:	74 0c                	je     80104868 <sched+0x73>
    panic("sched interruptible");
8010485c:	c7 04 24 25 85 10 80 	movl   $0x80108525,(%esp)
80104863:	e8 d5 bc ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80104868:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010486e:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104874:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104877:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010487d:	8b 40 04             	mov    0x4(%eax),%eax
80104880:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104887:	83 c2 1c             	add    $0x1c,%edx
8010488a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010488e:	89 14 24             	mov    %edx,(%esp)
80104891:	e8 42 08 00 00       	call   801050d8 <swtch>
  cpu->intena = intena;
80104896:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010489c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010489f:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801048a5:	c9                   	leave  
801048a6:	c3                   	ret    

801048a7 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801048a7:	55                   	push   %ebp
801048a8:	89 e5                	mov    %esp,%ebp
801048aa:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801048ad:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801048b4:	e8 2a 03 00 00       	call   80104be3 <acquire>
  proc->state = RUNNABLE;
801048b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048bf:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801048c6:	e8 2a ff ff ff       	call   801047f5 <sched>
  release(&ptable.lock);
801048cb:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801048d2:	e8 6e 03 00 00       	call   80104c45 <release>
}
801048d7:	c9                   	leave  
801048d8:	c3                   	ret    

801048d9 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801048d9:	55                   	push   %ebp
801048da:	89 e5                	mov    %esp,%ebp
801048dc:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801048df:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801048e6:	e8 5a 03 00 00       	call   80104c45 <release>

  if (first) {
801048eb:	a1 20 b0 10 80       	mov    0x8010b020,%eax
801048f0:	85 c0                	test   %eax,%eax
801048f2:	74 0f                	je     80104903 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
801048f4:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
801048fb:	00 00 00 
    initlog();
801048fe:	e8 4d e7 ff ff       	call   80103050 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104903:	c9                   	leave  
80104904:	c3                   	ret    

80104905 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104905:	55                   	push   %ebp
80104906:	89 e5                	mov    %esp,%ebp
80104908:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010490b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104911:	85 c0                	test   %eax,%eax
80104913:	75 0c                	jne    80104921 <sleep+0x1c>
    panic("sleep");
80104915:	c7 04 24 39 85 10 80 	movl   $0x80108539,(%esp)
8010491c:	e8 1c bc ff ff       	call   8010053d <panic>

  if(lk == 0)
80104921:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104925:	75 0c                	jne    80104933 <sleep+0x2e>
    panic("sleep without lk");
80104927:	c7 04 24 3f 85 10 80 	movl   $0x8010853f,(%esp)
8010492e:	e8 0a bc ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104933:	81 7d 0c 40 04 11 80 	cmpl   $0x80110440,0xc(%ebp)
8010493a:	74 17                	je     80104953 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010493c:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104943:	e8 9b 02 00 00       	call   80104be3 <acquire>
    release(lk);
80104948:	8b 45 0c             	mov    0xc(%ebp),%eax
8010494b:	89 04 24             	mov    %eax,(%esp)
8010494e:	e8 f2 02 00 00       	call   80104c45 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104953:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104959:	8b 55 08             	mov    0x8(%ebp),%edx
8010495c:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
8010495f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104965:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
8010496c:	e8 84 fe ff ff       	call   801047f5 <sched>

  // Tidy up.
  proc->chan = 0;
80104971:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104977:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
8010497e:	81 7d 0c 40 04 11 80 	cmpl   $0x80110440,0xc(%ebp)
80104985:	74 17                	je     8010499e <sleep+0x99>
    release(&ptable.lock);
80104987:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
8010498e:	e8 b2 02 00 00       	call   80104c45 <release>
    acquire(lk);
80104993:	8b 45 0c             	mov    0xc(%ebp),%eax
80104996:	89 04 24             	mov    %eax,(%esp)
80104999:	e8 45 02 00 00       	call   80104be3 <acquire>
  }
}
8010499e:	c9                   	leave  
8010499f:	c3                   	ret    

801049a0 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801049a0:	55                   	push   %ebp
801049a1:	89 e5                	mov    %esp,%ebp
801049a3:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801049a6:	c7 45 fc 74 04 11 80 	movl   $0x80110474,-0x4(%ebp)
801049ad:	eb 24                	jmp    801049d3 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
801049af:	8b 45 fc             	mov    -0x4(%ebp),%eax
801049b2:	8b 40 0c             	mov    0xc(%eax),%eax
801049b5:	83 f8 02             	cmp    $0x2,%eax
801049b8:	75 15                	jne    801049cf <wakeup1+0x2f>
801049ba:	8b 45 fc             	mov    -0x4(%ebp),%eax
801049bd:	8b 40 20             	mov    0x20(%eax),%eax
801049c0:	3b 45 08             	cmp    0x8(%ebp),%eax
801049c3:	75 0a                	jne    801049cf <wakeup1+0x2f>
      p->state = RUNNABLE;
801049c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801049c8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801049cf:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
801049d3:	81 7d fc 74 23 11 80 	cmpl   $0x80112374,-0x4(%ebp)
801049da:	72 d3                	jb     801049af <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
801049dc:	c9                   	leave  
801049dd:	c3                   	ret    

801049de <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801049de:	55                   	push   %ebp
801049df:	89 e5                	mov    %esp,%ebp
801049e1:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
801049e4:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
801049eb:	e8 f3 01 00 00       	call   80104be3 <acquire>
  wakeup1(chan);
801049f0:	8b 45 08             	mov    0x8(%ebp),%eax
801049f3:	89 04 24             	mov    %eax,(%esp)
801049f6:	e8 a5 ff ff ff       	call   801049a0 <wakeup1>
  release(&ptable.lock);
801049fb:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104a02:	e8 3e 02 00 00       	call   80104c45 <release>
}
80104a07:	c9                   	leave  
80104a08:	c3                   	ret    

80104a09 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104a09:	55                   	push   %ebp
80104a0a:	89 e5                	mov    %esp,%ebp
80104a0c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104a0f:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104a16:	e8 c8 01 00 00       	call   80104be3 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a1b:	c7 45 f4 74 04 11 80 	movl   $0x80110474,-0xc(%ebp)
80104a22:	eb 41                	jmp    80104a65 <kill+0x5c>
    if(p->pid == pid){
80104a24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a27:	8b 40 10             	mov    0x10(%eax),%eax
80104a2a:	3b 45 08             	cmp    0x8(%ebp),%eax
80104a2d:	75 32                	jne    80104a61 <kill+0x58>
      p->killed = 1;
80104a2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a32:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104a39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a3c:	8b 40 0c             	mov    0xc(%eax),%eax
80104a3f:	83 f8 02             	cmp    $0x2,%eax
80104a42:	75 0a                	jne    80104a4e <kill+0x45>
        p->state = RUNNABLE;
80104a44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a47:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104a4e:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104a55:	e8 eb 01 00 00       	call   80104c45 <release>
      return 0;
80104a5a:	b8 00 00 00 00       	mov    $0x0,%eax
80104a5f:	eb 1e                	jmp    80104a7f <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a61:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104a65:	81 7d f4 74 23 11 80 	cmpl   $0x80112374,-0xc(%ebp)
80104a6c:	72 b6                	jb     80104a24 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104a6e:	c7 04 24 40 04 11 80 	movl   $0x80110440,(%esp)
80104a75:	e8 cb 01 00 00       	call   80104c45 <release>
  return -1;
80104a7a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104a7f:	c9                   	leave  
80104a80:	c3                   	ret    

80104a81 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104a81:	55                   	push   %ebp
80104a82:	89 e5                	mov    %esp,%ebp
80104a84:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a87:	c7 45 f0 74 04 11 80 	movl   $0x80110474,-0x10(%ebp)
80104a8e:	e9 d8 00 00 00       	jmp    80104b6b <procdump+0xea>
    if(p->state == UNUSED)
80104a93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a96:	8b 40 0c             	mov    0xc(%eax),%eax
80104a99:	85 c0                	test   %eax,%eax
80104a9b:	0f 84 c5 00 00 00    	je     80104b66 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104aa1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aa4:	8b 40 0c             	mov    0xc(%eax),%eax
80104aa7:	83 f8 05             	cmp    $0x5,%eax
80104aaa:	77 23                	ja     80104acf <procdump+0x4e>
80104aac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aaf:	8b 40 0c             	mov    0xc(%eax),%eax
80104ab2:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104ab9:	85 c0                	test   %eax,%eax
80104abb:	74 12                	je     80104acf <procdump+0x4e>
      state = states[p->state];
80104abd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ac0:	8b 40 0c             	mov    0xc(%eax),%eax
80104ac3:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104aca:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104acd:	eb 07                	jmp    80104ad6 <procdump+0x55>
    else
      state = "???";
80104acf:	c7 45 ec 50 85 10 80 	movl   $0x80108550,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104ad6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ad9:	8d 50 6c             	lea    0x6c(%eax),%edx
80104adc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104adf:	8b 40 10             	mov    0x10(%eax),%eax
80104ae2:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104ae6:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104ae9:	89 54 24 08          	mov    %edx,0x8(%esp)
80104aed:	89 44 24 04          	mov    %eax,0x4(%esp)
80104af1:	c7 04 24 54 85 10 80 	movl   $0x80108554,(%esp)
80104af8:	e8 a4 b8 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80104afd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b00:	8b 40 0c             	mov    0xc(%eax),%eax
80104b03:	83 f8 02             	cmp    $0x2,%eax
80104b06:	75 50                	jne    80104b58 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104b08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b0b:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b0e:	8b 40 0c             	mov    0xc(%eax),%eax
80104b11:	83 c0 08             	add    $0x8,%eax
80104b14:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104b17:	89 54 24 04          	mov    %edx,0x4(%esp)
80104b1b:	89 04 24             	mov    %eax,(%esp)
80104b1e:	e8 71 01 00 00       	call   80104c94 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104b23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104b2a:	eb 1b                	jmp    80104b47 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104b2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b2f:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104b33:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b37:	c7 04 24 5d 85 10 80 	movl   $0x8010855d,(%esp)
80104b3e:	e8 5e b8 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104b43:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104b47:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104b4b:	7f 0b                	jg     80104b58 <procdump+0xd7>
80104b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b50:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104b54:	85 c0                	test   %eax,%eax
80104b56:	75 d4                	jne    80104b2c <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104b58:	c7 04 24 61 85 10 80 	movl   $0x80108561,(%esp)
80104b5f:	e8 3d b8 ff ff       	call   801003a1 <cprintf>
80104b64:	eb 01                	jmp    80104b67 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104b66:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b67:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104b6b:	81 7d f0 74 23 11 80 	cmpl   $0x80112374,-0x10(%ebp)
80104b72:	0f 82 1b ff ff ff    	jb     80104a93 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104b78:	c9                   	leave  
80104b79:	c3                   	ret    
	...

80104b7c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104b7c:	55                   	push   %ebp
80104b7d:	89 e5                	mov    %esp,%ebp
80104b7f:	53                   	push   %ebx
80104b80:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104b83:	9c                   	pushf  
80104b84:	5b                   	pop    %ebx
80104b85:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104b88:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104b8b:	83 c4 10             	add    $0x10,%esp
80104b8e:	5b                   	pop    %ebx
80104b8f:	5d                   	pop    %ebp
80104b90:	c3                   	ret    

80104b91 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104b91:	55                   	push   %ebp
80104b92:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104b94:	fa                   	cli    
}
80104b95:	5d                   	pop    %ebp
80104b96:	c3                   	ret    

80104b97 <sti>:

static inline void
sti(void)
{
80104b97:	55                   	push   %ebp
80104b98:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104b9a:	fb                   	sti    
}
80104b9b:	5d                   	pop    %ebp
80104b9c:	c3                   	ret    

80104b9d <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104b9d:	55                   	push   %ebp
80104b9e:	89 e5                	mov    %esp,%ebp
80104ba0:	53                   	push   %ebx
80104ba1:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104ba4:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104ba7:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104baa:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104bad:	89 c3                	mov    %eax,%ebx
80104baf:	89 d8                	mov    %ebx,%eax
80104bb1:	f0 87 02             	lock xchg %eax,(%edx)
80104bb4:	89 c3                	mov    %eax,%ebx
80104bb6:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104bb9:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104bbc:	83 c4 10             	add    $0x10,%esp
80104bbf:	5b                   	pop    %ebx
80104bc0:	5d                   	pop    %ebp
80104bc1:	c3                   	ret    

80104bc2 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104bc2:	55                   	push   %ebp
80104bc3:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104bc5:	8b 45 08             	mov    0x8(%ebp),%eax
80104bc8:	8b 55 0c             	mov    0xc(%ebp),%edx
80104bcb:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104bce:	8b 45 08             	mov    0x8(%ebp),%eax
80104bd1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104bd7:	8b 45 08             	mov    0x8(%ebp),%eax
80104bda:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104be1:	5d                   	pop    %ebp
80104be2:	c3                   	ret    

80104be3 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104be3:	55                   	push   %ebp
80104be4:	89 e5                	mov    %esp,%ebp
80104be6:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104be9:	e8 3d 01 00 00       	call   80104d2b <pushcli>
  if(holding(lk))
80104bee:	8b 45 08             	mov    0x8(%ebp),%eax
80104bf1:	89 04 24             	mov    %eax,(%esp)
80104bf4:	e8 08 01 00 00       	call   80104d01 <holding>
80104bf9:	85 c0                	test   %eax,%eax
80104bfb:	74 0c                	je     80104c09 <acquire+0x26>
    panic("acquire");
80104bfd:	c7 04 24 8d 85 10 80 	movl   $0x8010858d,(%esp)
80104c04:	e8 34 b9 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104c09:	90                   	nop
80104c0a:	8b 45 08             	mov    0x8(%ebp),%eax
80104c0d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104c14:	00 
80104c15:	89 04 24             	mov    %eax,(%esp)
80104c18:	e8 80 ff ff ff       	call   80104b9d <xchg>
80104c1d:	85 c0                	test   %eax,%eax
80104c1f:	75 e9                	jne    80104c0a <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104c21:	8b 45 08             	mov    0x8(%ebp),%eax
80104c24:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104c2b:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104c2e:	8b 45 08             	mov    0x8(%ebp),%eax
80104c31:	83 c0 0c             	add    $0xc,%eax
80104c34:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c38:	8d 45 08             	lea    0x8(%ebp),%eax
80104c3b:	89 04 24             	mov    %eax,(%esp)
80104c3e:	e8 51 00 00 00       	call   80104c94 <getcallerpcs>
}
80104c43:	c9                   	leave  
80104c44:	c3                   	ret    

80104c45 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104c45:	55                   	push   %ebp
80104c46:	89 e5                	mov    %esp,%ebp
80104c48:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104c4b:	8b 45 08             	mov    0x8(%ebp),%eax
80104c4e:	89 04 24             	mov    %eax,(%esp)
80104c51:	e8 ab 00 00 00       	call   80104d01 <holding>
80104c56:	85 c0                	test   %eax,%eax
80104c58:	75 0c                	jne    80104c66 <release+0x21>
    panic("release");
80104c5a:	c7 04 24 95 85 10 80 	movl   $0x80108595,(%esp)
80104c61:	e8 d7 b8 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80104c66:	8b 45 08             	mov    0x8(%ebp),%eax
80104c69:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104c70:	8b 45 08             	mov    0x8(%ebp),%eax
80104c73:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104c7a:	8b 45 08             	mov    0x8(%ebp),%eax
80104c7d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104c84:	00 
80104c85:	89 04 24             	mov    %eax,(%esp)
80104c88:	e8 10 ff ff ff       	call   80104b9d <xchg>

  popcli();
80104c8d:	e8 e1 00 00 00       	call   80104d73 <popcli>
}
80104c92:	c9                   	leave  
80104c93:	c3                   	ret    

80104c94 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104c94:	55                   	push   %ebp
80104c95:	89 e5                	mov    %esp,%ebp
80104c97:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104c9a:	8b 45 08             	mov    0x8(%ebp),%eax
80104c9d:	83 e8 08             	sub    $0x8,%eax
80104ca0:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104ca3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104caa:	eb 32                	jmp    80104cde <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104cac:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104cb0:	74 47                	je     80104cf9 <getcallerpcs+0x65>
80104cb2:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104cb9:	76 3e                	jbe    80104cf9 <getcallerpcs+0x65>
80104cbb:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104cbf:	74 38                	je     80104cf9 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104cc1:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104cc4:	c1 e0 02             	shl    $0x2,%eax
80104cc7:	03 45 0c             	add    0xc(%ebp),%eax
80104cca:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104ccd:	8b 52 04             	mov    0x4(%edx),%edx
80104cd0:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80104cd2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cd5:	8b 00                	mov    (%eax),%eax
80104cd7:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104cda:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104cde:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104ce2:	7e c8                	jle    80104cac <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104ce4:	eb 13                	jmp    80104cf9 <getcallerpcs+0x65>
    pcs[i] = 0;
80104ce6:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ce9:	c1 e0 02             	shl    $0x2,%eax
80104cec:	03 45 0c             	add    0xc(%ebp),%eax
80104cef:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104cf5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104cf9:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104cfd:	7e e7                	jle    80104ce6 <getcallerpcs+0x52>
    pcs[i] = 0;
}
80104cff:	c9                   	leave  
80104d00:	c3                   	ret    

80104d01 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104d01:	55                   	push   %ebp
80104d02:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104d04:	8b 45 08             	mov    0x8(%ebp),%eax
80104d07:	8b 00                	mov    (%eax),%eax
80104d09:	85 c0                	test   %eax,%eax
80104d0b:	74 17                	je     80104d24 <holding+0x23>
80104d0d:	8b 45 08             	mov    0x8(%ebp),%eax
80104d10:	8b 50 08             	mov    0x8(%eax),%edx
80104d13:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d19:	39 c2                	cmp    %eax,%edx
80104d1b:	75 07                	jne    80104d24 <holding+0x23>
80104d1d:	b8 01 00 00 00       	mov    $0x1,%eax
80104d22:	eb 05                	jmp    80104d29 <holding+0x28>
80104d24:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d29:	5d                   	pop    %ebp
80104d2a:	c3                   	ret    

80104d2b <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104d2b:	55                   	push   %ebp
80104d2c:	89 e5                	mov    %esp,%ebp
80104d2e:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104d31:	e8 46 fe ff ff       	call   80104b7c <readeflags>
80104d36:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104d39:	e8 53 fe ff ff       	call   80104b91 <cli>
  if(cpu->ncli++ == 0)
80104d3e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d44:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104d4a:	85 d2                	test   %edx,%edx
80104d4c:	0f 94 c1             	sete   %cl
80104d4f:	83 c2 01             	add    $0x1,%edx
80104d52:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104d58:	84 c9                	test   %cl,%cl
80104d5a:	74 15                	je     80104d71 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80104d5c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d62:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104d65:	81 e2 00 02 00 00    	and    $0x200,%edx
80104d6b:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104d71:	c9                   	leave  
80104d72:	c3                   	ret    

80104d73 <popcli>:

void
popcli(void)
{
80104d73:	55                   	push   %ebp
80104d74:	89 e5                	mov    %esp,%ebp
80104d76:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104d79:	e8 fe fd ff ff       	call   80104b7c <readeflags>
80104d7e:	25 00 02 00 00       	and    $0x200,%eax
80104d83:	85 c0                	test   %eax,%eax
80104d85:	74 0c                	je     80104d93 <popcli+0x20>
    panic("popcli - interruptible");
80104d87:	c7 04 24 9d 85 10 80 	movl   $0x8010859d,(%esp)
80104d8e:	e8 aa b7 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80104d93:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d99:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104d9f:	83 ea 01             	sub    $0x1,%edx
80104da2:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104da8:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104dae:	85 c0                	test   %eax,%eax
80104db0:	79 0c                	jns    80104dbe <popcli+0x4b>
    panic("popcli");
80104db2:	c7 04 24 b4 85 10 80 	movl   $0x801085b4,(%esp)
80104db9:	e8 7f b7 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104dbe:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104dc4:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104dca:	85 c0                	test   %eax,%eax
80104dcc:	75 15                	jne    80104de3 <popcli+0x70>
80104dce:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104dd4:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104dda:	85 c0                	test   %eax,%eax
80104ddc:	74 05                	je     80104de3 <popcli+0x70>
    sti();
80104dde:	e8 b4 fd ff ff       	call   80104b97 <sti>
}
80104de3:	c9                   	leave  
80104de4:	c3                   	ret    
80104de5:	00 00                	add    %al,(%eax)
	...

80104de8 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80104de8:	55                   	push   %ebp
80104de9:	89 e5                	mov    %esp,%ebp
80104deb:	57                   	push   %edi
80104dec:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80104ded:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104df0:	8b 55 10             	mov    0x10(%ebp),%edx
80104df3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104df6:	89 cb                	mov    %ecx,%ebx
80104df8:	89 df                	mov    %ebx,%edi
80104dfa:	89 d1                	mov    %edx,%ecx
80104dfc:	fc                   	cld    
80104dfd:	f3 aa                	rep stos %al,%es:(%edi)
80104dff:	89 ca                	mov    %ecx,%edx
80104e01:	89 fb                	mov    %edi,%ebx
80104e03:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104e06:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104e09:	5b                   	pop    %ebx
80104e0a:	5f                   	pop    %edi
80104e0b:	5d                   	pop    %ebp
80104e0c:	c3                   	ret    

80104e0d <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80104e0d:	55                   	push   %ebp
80104e0e:	89 e5                	mov    %esp,%ebp
80104e10:	57                   	push   %edi
80104e11:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80104e12:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e15:	8b 55 10             	mov    0x10(%ebp),%edx
80104e18:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e1b:	89 cb                	mov    %ecx,%ebx
80104e1d:	89 df                	mov    %ebx,%edi
80104e1f:	89 d1                	mov    %edx,%ecx
80104e21:	fc                   	cld    
80104e22:	f3 ab                	rep stos %eax,%es:(%edi)
80104e24:	89 ca                	mov    %ecx,%edx
80104e26:	89 fb                	mov    %edi,%ebx
80104e28:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104e2b:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104e2e:	5b                   	pop    %ebx
80104e2f:	5f                   	pop    %edi
80104e30:	5d                   	pop    %ebp
80104e31:	c3                   	ret    

80104e32 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104e32:	55                   	push   %ebp
80104e33:	89 e5                	mov    %esp,%ebp
80104e35:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80104e38:	8b 45 08             	mov    0x8(%ebp),%eax
80104e3b:	83 e0 03             	and    $0x3,%eax
80104e3e:	85 c0                	test   %eax,%eax
80104e40:	75 49                	jne    80104e8b <memset+0x59>
80104e42:	8b 45 10             	mov    0x10(%ebp),%eax
80104e45:	83 e0 03             	and    $0x3,%eax
80104e48:	85 c0                	test   %eax,%eax
80104e4a:	75 3f                	jne    80104e8b <memset+0x59>
    c &= 0xFF;
80104e4c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104e53:	8b 45 10             	mov    0x10(%ebp),%eax
80104e56:	c1 e8 02             	shr    $0x2,%eax
80104e59:	89 c2                	mov    %eax,%edx
80104e5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e5e:	89 c1                	mov    %eax,%ecx
80104e60:	c1 e1 18             	shl    $0x18,%ecx
80104e63:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e66:	c1 e0 10             	shl    $0x10,%eax
80104e69:	09 c1                	or     %eax,%ecx
80104e6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e6e:	c1 e0 08             	shl    $0x8,%eax
80104e71:	09 c8                	or     %ecx,%eax
80104e73:	0b 45 0c             	or     0xc(%ebp),%eax
80104e76:	89 54 24 08          	mov    %edx,0x8(%esp)
80104e7a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e7e:	8b 45 08             	mov    0x8(%ebp),%eax
80104e81:	89 04 24             	mov    %eax,(%esp)
80104e84:	e8 84 ff ff ff       	call   80104e0d <stosl>
80104e89:	eb 19                	jmp    80104ea4 <memset+0x72>
  } else
    stosb(dst, c, n);
80104e8b:	8b 45 10             	mov    0x10(%ebp),%eax
80104e8e:	89 44 24 08          	mov    %eax,0x8(%esp)
80104e92:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e95:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e99:	8b 45 08             	mov    0x8(%ebp),%eax
80104e9c:	89 04 24             	mov    %eax,(%esp)
80104e9f:	e8 44 ff ff ff       	call   80104de8 <stosb>
  return dst;
80104ea4:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104ea7:	c9                   	leave  
80104ea8:	c3                   	ret    

80104ea9 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104ea9:	55                   	push   %ebp
80104eaa:	89 e5                	mov    %esp,%ebp
80104eac:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80104eaf:	8b 45 08             	mov    0x8(%ebp),%eax
80104eb2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80104eb5:	8b 45 0c             	mov    0xc(%ebp),%eax
80104eb8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80104ebb:	eb 32                	jmp    80104eef <memcmp+0x46>
    if(*s1 != *s2)
80104ebd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ec0:	0f b6 10             	movzbl (%eax),%edx
80104ec3:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ec6:	0f b6 00             	movzbl (%eax),%eax
80104ec9:	38 c2                	cmp    %al,%dl
80104ecb:	74 1a                	je     80104ee7 <memcmp+0x3e>
      return *s1 - *s2;
80104ecd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ed0:	0f b6 00             	movzbl (%eax),%eax
80104ed3:	0f b6 d0             	movzbl %al,%edx
80104ed6:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ed9:	0f b6 00             	movzbl (%eax),%eax
80104edc:	0f b6 c0             	movzbl %al,%eax
80104edf:	89 d1                	mov    %edx,%ecx
80104ee1:	29 c1                	sub    %eax,%ecx
80104ee3:	89 c8                	mov    %ecx,%eax
80104ee5:	eb 1c                	jmp    80104f03 <memcmp+0x5a>
    s1++, s2++;
80104ee7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104eeb:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104eef:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104ef3:	0f 95 c0             	setne  %al
80104ef6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104efa:	84 c0                	test   %al,%al
80104efc:	75 bf                	jne    80104ebd <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80104efe:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f03:	c9                   	leave  
80104f04:	c3                   	ret    

80104f05 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104f05:	55                   	push   %ebp
80104f06:	89 e5                	mov    %esp,%ebp
80104f08:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80104f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f0e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80104f11:	8b 45 08             	mov    0x8(%ebp),%eax
80104f14:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80104f17:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f1a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104f1d:	73 54                	jae    80104f73 <memmove+0x6e>
80104f1f:	8b 45 10             	mov    0x10(%ebp),%eax
80104f22:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104f25:	01 d0                	add    %edx,%eax
80104f27:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104f2a:	76 47                	jbe    80104f73 <memmove+0x6e>
    s += n;
80104f2c:	8b 45 10             	mov    0x10(%ebp),%eax
80104f2f:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80104f32:	8b 45 10             	mov    0x10(%ebp),%eax
80104f35:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80104f38:	eb 13                	jmp    80104f4d <memmove+0x48>
      *--d = *--s;
80104f3a:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80104f3e:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80104f42:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f45:	0f b6 10             	movzbl (%eax),%edx
80104f48:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f4b:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80104f4d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f51:	0f 95 c0             	setne  %al
80104f54:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104f58:	84 c0                	test   %al,%al
80104f5a:	75 de                	jne    80104f3a <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104f5c:	eb 25                	jmp    80104f83 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80104f5e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f61:	0f b6 10             	movzbl (%eax),%edx
80104f64:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f67:	88 10                	mov    %dl,(%eax)
80104f69:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104f6d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104f71:	eb 01                	jmp    80104f74 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80104f73:	90                   	nop
80104f74:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f78:	0f 95 c0             	setne  %al
80104f7b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104f7f:	84 c0                	test   %al,%al
80104f81:	75 db                	jne    80104f5e <memmove+0x59>
      *d++ = *s++;

  return dst;
80104f83:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104f86:	c9                   	leave  
80104f87:	c3                   	ret    

80104f88 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104f88:	55                   	push   %ebp
80104f89:	89 e5                	mov    %esp,%ebp
80104f8b:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80104f8e:	8b 45 10             	mov    0x10(%ebp),%eax
80104f91:	89 44 24 08          	mov    %eax,0x8(%esp)
80104f95:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f98:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f9c:	8b 45 08             	mov    0x8(%ebp),%eax
80104f9f:	89 04 24             	mov    %eax,(%esp)
80104fa2:	e8 5e ff ff ff       	call   80104f05 <memmove>
}
80104fa7:	c9                   	leave  
80104fa8:	c3                   	ret    

80104fa9 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80104fa9:	55                   	push   %ebp
80104faa:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80104fac:	eb 0c                	jmp    80104fba <strncmp+0x11>
    n--, p++, q++;
80104fae:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104fb2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80104fb6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80104fba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104fbe:	74 1a                	je     80104fda <strncmp+0x31>
80104fc0:	8b 45 08             	mov    0x8(%ebp),%eax
80104fc3:	0f b6 00             	movzbl (%eax),%eax
80104fc6:	84 c0                	test   %al,%al
80104fc8:	74 10                	je     80104fda <strncmp+0x31>
80104fca:	8b 45 08             	mov    0x8(%ebp),%eax
80104fcd:	0f b6 10             	movzbl (%eax),%edx
80104fd0:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fd3:	0f b6 00             	movzbl (%eax),%eax
80104fd6:	38 c2                	cmp    %al,%dl
80104fd8:	74 d4                	je     80104fae <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80104fda:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104fde:	75 07                	jne    80104fe7 <strncmp+0x3e>
    return 0;
80104fe0:	b8 00 00 00 00       	mov    $0x0,%eax
80104fe5:	eb 18                	jmp    80104fff <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80104fe7:	8b 45 08             	mov    0x8(%ebp),%eax
80104fea:	0f b6 00             	movzbl (%eax),%eax
80104fed:	0f b6 d0             	movzbl %al,%edx
80104ff0:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ff3:	0f b6 00             	movzbl (%eax),%eax
80104ff6:	0f b6 c0             	movzbl %al,%eax
80104ff9:	89 d1                	mov    %edx,%ecx
80104ffb:	29 c1                	sub    %eax,%ecx
80104ffd:	89 c8                	mov    %ecx,%eax
}
80104fff:	5d                   	pop    %ebp
80105000:	c3                   	ret    

80105001 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105001:	55                   	push   %ebp
80105002:	89 e5                	mov    %esp,%ebp
80105004:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105007:	8b 45 08             	mov    0x8(%ebp),%eax
8010500a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
8010500d:	90                   	nop
8010500e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105012:	0f 9f c0             	setg   %al
80105015:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105019:	84 c0                	test   %al,%al
8010501b:	74 30                	je     8010504d <strncpy+0x4c>
8010501d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105020:	0f b6 10             	movzbl (%eax),%edx
80105023:	8b 45 08             	mov    0x8(%ebp),%eax
80105026:	88 10                	mov    %dl,(%eax)
80105028:	8b 45 08             	mov    0x8(%ebp),%eax
8010502b:	0f b6 00             	movzbl (%eax),%eax
8010502e:	84 c0                	test   %al,%al
80105030:	0f 95 c0             	setne  %al
80105033:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105037:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
8010503b:	84 c0                	test   %al,%al
8010503d:	75 cf                	jne    8010500e <strncpy+0xd>
    ;
  while(n-- > 0)
8010503f:	eb 0c                	jmp    8010504d <strncpy+0x4c>
    *s++ = 0;
80105041:	8b 45 08             	mov    0x8(%ebp),%eax
80105044:	c6 00 00             	movb   $0x0,(%eax)
80105047:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010504b:	eb 01                	jmp    8010504e <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
8010504d:	90                   	nop
8010504e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105052:	0f 9f c0             	setg   %al
80105055:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105059:	84 c0                	test   %al,%al
8010505b:	75 e4                	jne    80105041 <strncpy+0x40>
    *s++ = 0;
  return os;
8010505d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105060:	c9                   	leave  
80105061:	c3                   	ret    

80105062 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105062:	55                   	push   %ebp
80105063:	89 e5                	mov    %esp,%ebp
80105065:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105068:	8b 45 08             	mov    0x8(%ebp),%eax
8010506b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010506e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105072:	7f 05                	jg     80105079 <safestrcpy+0x17>
    return os;
80105074:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105077:	eb 35                	jmp    801050ae <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105079:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010507d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105081:	7e 22                	jle    801050a5 <safestrcpy+0x43>
80105083:	8b 45 0c             	mov    0xc(%ebp),%eax
80105086:	0f b6 10             	movzbl (%eax),%edx
80105089:	8b 45 08             	mov    0x8(%ebp),%eax
8010508c:	88 10                	mov    %dl,(%eax)
8010508e:	8b 45 08             	mov    0x8(%ebp),%eax
80105091:	0f b6 00             	movzbl (%eax),%eax
80105094:	84 c0                	test   %al,%al
80105096:	0f 95 c0             	setne  %al
80105099:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010509d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801050a1:	84 c0                	test   %al,%al
801050a3:	75 d4                	jne    80105079 <safestrcpy+0x17>
    ;
  *s = 0;
801050a5:	8b 45 08             	mov    0x8(%ebp),%eax
801050a8:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801050ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801050ae:	c9                   	leave  
801050af:	c3                   	ret    

801050b0 <strlen>:

int
strlen(const char *s)
{
801050b0:	55                   	push   %ebp
801050b1:	89 e5                	mov    %esp,%ebp
801050b3:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801050b6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801050bd:	eb 04                	jmp    801050c3 <strlen+0x13>
801050bf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801050c3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050c6:	03 45 08             	add    0x8(%ebp),%eax
801050c9:	0f b6 00             	movzbl (%eax),%eax
801050cc:	84 c0                	test   %al,%al
801050ce:	75 ef                	jne    801050bf <strlen+0xf>
    ;
  return n;
801050d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801050d3:	c9                   	leave  
801050d4:	c3                   	ret    
801050d5:	00 00                	add    %al,(%eax)
	...

801050d8 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801050d8:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801050dc:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801050e0:	55                   	push   %ebp
  pushl %ebx
801050e1:	53                   	push   %ebx
  pushl %esi
801050e2:	56                   	push   %esi
  pushl %edi
801050e3:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801050e4:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801050e6:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801050e8:	5f                   	pop    %edi
  popl %esi
801050e9:	5e                   	pop    %esi
  popl %ebx
801050ea:	5b                   	pop    %ebx
  popl %ebp
801050eb:	5d                   	pop    %ebp
  ret
801050ec:	c3                   	ret    
801050ed:	00 00                	add    %al,(%eax)
	...

801050f0 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
801050f0:	55                   	push   %ebp
801050f1:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
801050f3:	8b 45 08             	mov    0x8(%ebp),%eax
801050f6:	8b 00                	mov    (%eax),%eax
801050f8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801050fb:	76 0f                	jbe    8010510c <fetchint+0x1c>
801050fd:	8b 45 0c             	mov    0xc(%ebp),%eax
80105100:	8d 50 04             	lea    0x4(%eax),%edx
80105103:	8b 45 08             	mov    0x8(%ebp),%eax
80105106:	8b 00                	mov    (%eax),%eax
80105108:	39 c2                	cmp    %eax,%edx
8010510a:	76 07                	jbe    80105113 <fetchint+0x23>
    return -1;
8010510c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105111:	eb 0f                	jmp    80105122 <fetchint+0x32>
  *ip = *(int*)(addr);
80105113:	8b 45 0c             	mov    0xc(%ebp),%eax
80105116:	8b 10                	mov    (%eax),%edx
80105118:	8b 45 10             	mov    0x10(%ebp),%eax
8010511b:	89 10                	mov    %edx,(%eax)
  return 0;
8010511d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105122:	5d                   	pop    %ebp
80105123:	c3                   	ret    

80105124 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105124:	55                   	push   %ebp
80105125:	89 e5                	mov    %esp,%ebp
80105127:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
8010512a:	8b 45 08             	mov    0x8(%ebp),%eax
8010512d:	8b 00                	mov    (%eax),%eax
8010512f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105132:	77 07                	ja     8010513b <fetchstr+0x17>
    return -1;
80105134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105139:	eb 45                	jmp    80105180 <fetchstr+0x5c>
  *pp = (char*)addr;
8010513b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010513e:	8b 45 10             	mov    0x10(%ebp),%eax
80105141:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80105143:	8b 45 08             	mov    0x8(%ebp),%eax
80105146:	8b 00                	mov    (%eax),%eax
80105148:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010514b:	8b 45 10             	mov    0x10(%ebp),%eax
8010514e:	8b 00                	mov    (%eax),%eax
80105150:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105153:	eb 1e                	jmp    80105173 <fetchstr+0x4f>
    if(*s == 0)
80105155:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105158:	0f b6 00             	movzbl (%eax),%eax
8010515b:	84 c0                	test   %al,%al
8010515d:	75 10                	jne    8010516f <fetchstr+0x4b>
      return s - *pp;
8010515f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105162:	8b 45 10             	mov    0x10(%ebp),%eax
80105165:	8b 00                	mov    (%eax),%eax
80105167:	89 d1                	mov    %edx,%ecx
80105169:	29 c1                	sub    %eax,%ecx
8010516b:	89 c8                	mov    %ecx,%eax
8010516d:	eb 11                	jmp    80105180 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
8010516f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105173:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105176:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105179:	72 da                	jb     80105155 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
8010517b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105180:	c9                   	leave  
80105181:	c3                   	ret    

80105182 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105182:	55                   	push   %ebp
80105183:	89 e5                	mov    %esp,%ebp
80105185:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105188:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010518e:	8b 40 18             	mov    0x18(%eax),%eax
80105191:	8b 50 44             	mov    0x44(%eax),%edx
80105194:	8b 45 08             	mov    0x8(%ebp),%eax
80105197:	c1 e0 02             	shl    $0x2,%eax
8010519a:	01 d0                	add    %edx,%eax
8010519c:	8d 48 04             	lea    0x4(%eax),%ecx
8010519f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051a5:	8b 55 0c             	mov    0xc(%ebp),%edx
801051a8:	89 54 24 08          	mov    %edx,0x8(%esp)
801051ac:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801051b0:	89 04 24             	mov    %eax,(%esp)
801051b3:	e8 38 ff ff ff       	call   801050f0 <fetchint>
}
801051b8:	c9                   	leave  
801051b9:	c3                   	ret    

801051ba <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801051ba:	55                   	push   %ebp
801051bb:	89 e5                	mov    %esp,%ebp
801051bd:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801051c0:	8d 45 fc             	lea    -0x4(%ebp),%eax
801051c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801051c7:	8b 45 08             	mov    0x8(%ebp),%eax
801051ca:	89 04 24             	mov    %eax,(%esp)
801051cd:	e8 b0 ff ff ff       	call   80105182 <argint>
801051d2:	85 c0                	test   %eax,%eax
801051d4:	79 07                	jns    801051dd <argptr+0x23>
    return -1;
801051d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051db:	eb 3d                	jmp    8010521a <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801051dd:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051e0:	89 c2                	mov    %eax,%edx
801051e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051e8:	8b 00                	mov    (%eax),%eax
801051ea:	39 c2                	cmp    %eax,%edx
801051ec:	73 16                	jae    80105204 <argptr+0x4a>
801051ee:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051f1:	89 c2                	mov    %eax,%edx
801051f3:	8b 45 10             	mov    0x10(%ebp),%eax
801051f6:	01 c2                	add    %eax,%edx
801051f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051fe:	8b 00                	mov    (%eax),%eax
80105200:	39 c2                	cmp    %eax,%edx
80105202:	76 07                	jbe    8010520b <argptr+0x51>
    return -1;
80105204:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105209:	eb 0f                	jmp    8010521a <argptr+0x60>
  *pp = (char*)i;
8010520b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010520e:	89 c2                	mov    %eax,%edx
80105210:	8b 45 0c             	mov    0xc(%ebp),%eax
80105213:	89 10                	mov    %edx,(%eax)
  return 0;
80105215:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010521a:	c9                   	leave  
8010521b:	c3                   	ret    

8010521c <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010521c:	55                   	push   %ebp
8010521d:	89 e5                	mov    %esp,%ebp
8010521f:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105222:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105225:	89 44 24 04          	mov    %eax,0x4(%esp)
80105229:	8b 45 08             	mov    0x8(%ebp),%eax
8010522c:	89 04 24             	mov    %eax,(%esp)
8010522f:	e8 4e ff ff ff       	call   80105182 <argint>
80105234:	85 c0                	test   %eax,%eax
80105236:	79 07                	jns    8010523f <argstr+0x23>
    return -1;
80105238:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010523d:	eb 1e                	jmp    8010525d <argstr+0x41>
  return fetchstr(proc, addr, pp);
8010523f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105242:	89 c2                	mov    %eax,%edx
80105244:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010524a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010524d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105251:	89 54 24 04          	mov    %edx,0x4(%esp)
80105255:	89 04 24             	mov    %eax,(%esp)
80105258:	e8 c7 fe ff ff       	call   80105124 <fetchstr>
}
8010525d:	c9                   	leave  
8010525e:	c3                   	ret    

8010525f <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
8010525f:	55                   	push   %ebp
80105260:	89 e5                	mov    %esp,%ebp
80105262:	53                   	push   %ebx
80105263:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105266:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010526c:	8b 40 18             	mov    0x18(%eax),%eax
8010526f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105272:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80105275:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105279:	78 2e                	js     801052a9 <syscall+0x4a>
8010527b:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
8010527f:	7f 28                	jg     801052a9 <syscall+0x4a>
80105281:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105284:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010528b:	85 c0                	test   %eax,%eax
8010528d:	74 1a                	je     801052a9 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
8010528f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105295:	8b 58 18             	mov    0x18(%eax),%ebx
80105298:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010529b:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801052a2:	ff d0                	call   *%eax
801052a4:	89 43 1c             	mov    %eax,0x1c(%ebx)
801052a7:	eb 73                	jmp    8010531c <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801052a9:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801052ad:	7e 30                	jle    801052df <syscall+0x80>
801052af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052b2:	83 f8 15             	cmp    $0x15,%eax
801052b5:	77 28                	ja     801052df <syscall+0x80>
801052b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ba:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801052c1:	85 c0                	test   %eax,%eax
801052c3:	74 1a                	je     801052df <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801052c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052cb:	8b 58 18             	mov    0x18(%eax),%ebx
801052ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052d1:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801052d8:	ff d0                	call   *%eax
801052da:	89 43 1c             	mov    %eax,0x1c(%ebx)
801052dd:	eb 3d                	jmp    8010531c <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801052df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052e5:	8d 48 6c             	lea    0x6c(%eax),%ecx
801052e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801052ee:	8b 40 10             	mov    0x10(%eax),%eax
801052f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801052f4:	89 54 24 0c          	mov    %edx,0xc(%esp)
801052f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801052fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80105300:	c7 04 24 bb 85 10 80 	movl   $0x801085bb,(%esp)
80105307:	e8 95 b0 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
8010530c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105312:	8b 40 18             	mov    0x18(%eax),%eax
80105315:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
8010531c:	83 c4 24             	add    $0x24,%esp
8010531f:	5b                   	pop    %ebx
80105320:	5d                   	pop    %ebp
80105321:	c3                   	ret    
	...

80105324 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105324:	55                   	push   %ebp
80105325:	89 e5                	mov    %esp,%ebp
80105327:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010532a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010532d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105331:	8b 45 08             	mov    0x8(%ebp),%eax
80105334:	89 04 24             	mov    %eax,(%esp)
80105337:	e8 46 fe ff ff       	call   80105182 <argint>
8010533c:	85 c0                	test   %eax,%eax
8010533e:	79 07                	jns    80105347 <argfd+0x23>
    return -1;
80105340:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105345:	eb 50                	jmp    80105397 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105347:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010534a:	85 c0                	test   %eax,%eax
8010534c:	78 21                	js     8010536f <argfd+0x4b>
8010534e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105351:	83 f8 0f             	cmp    $0xf,%eax
80105354:	7f 19                	jg     8010536f <argfd+0x4b>
80105356:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010535c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010535f:	83 c2 08             	add    $0x8,%edx
80105362:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105366:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105369:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010536d:	75 07                	jne    80105376 <argfd+0x52>
    return -1;
8010536f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105374:	eb 21                	jmp    80105397 <argfd+0x73>
  if(pfd)
80105376:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010537a:	74 08                	je     80105384 <argfd+0x60>
    *pfd = fd;
8010537c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010537f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105382:	89 10                	mov    %edx,(%eax)
  if(pf)
80105384:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105388:	74 08                	je     80105392 <argfd+0x6e>
    *pf = f;
8010538a:	8b 45 10             	mov    0x10(%ebp),%eax
8010538d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105390:	89 10                	mov    %edx,(%eax)
  return 0;
80105392:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105397:	c9                   	leave  
80105398:	c3                   	ret    

80105399 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105399:	55                   	push   %ebp
8010539a:	89 e5                	mov    %esp,%ebp
8010539c:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010539f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801053a6:	eb 30                	jmp    801053d8 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801053a8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053ae:	8b 55 fc             	mov    -0x4(%ebp),%edx
801053b1:	83 c2 08             	add    $0x8,%edx
801053b4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801053b8:	85 c0                	test   %eax,%eax
801053ba:	75 18                	jne    801053d4 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801053bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053c2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801053c5:	8d 4a 08             	lea    0x8(%edx),%ecx
801053c8:	8b 55 08             	mov    0x8(%ebp),%edx
801053cb:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801053cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053d2:	eb 0f                	jmp    801053e3 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801053d4:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801053d8:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801053dc:	7e ca                	jle    801053a8 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801053de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801053e3:	c9                   	leave  
801053e4:	c3                   	ret    

801053e5 <sys_dup>:

int
sys_dup(void)
{
801053e5:	55                   	push   %ebp
801053e6:	89 e5                	mov    %esp,%ebp
801053e8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801053eb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801053ee:	89 44 24 08          	mov    %eax,0x8(%esp)
801053f2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801053f9:	00 
801053fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105401:	e8 1e ff ff ff       	call   80105324 <argfd>
80105406:	85 c0                	test   %eax,%eax
80105408:	79 07                	jns    80105411 <sys_dup+0x2c>
    return -1;
8010540a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010540f:	eb 29                	jmp    8010543a <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105411:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105414:	89 04 24             	mov    %eax,(%esp)
80105417:	e8 7d ff ff ff       	call   80105399 <fdalloc>
8010541c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010541f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105423:	79 07                	jns    8010542c <sys_dup+0x47>
    return -1;
80105425:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010542a:	eb 0e                	jmp    8010543a <sys_dup+0x55>
  filedup(f);
8010542c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010542f:	89 04 24             	mov    %eax,(%esp)
80105432:	e8 85 bb ff ff       	call   80100fbc <filedup>
  return fd;
80105437:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010543a:	c9                   	leave  
8010543b:	c3                   	ret    

8010543c <sys_read>:

int
sys_read(void)
{
8010543c:	55                   	push   %ebp
8010543d:	89 e5                	mov    %esp,%ebp
8010543f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105442:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105445:	89 44 24 08          	mov    %eax,0x8(%esp)
80105449:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105450:	00 
80105451:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105458:	e8 c7 fe ff ff       	call   80105324 <argfd>
8010545d:	85 c0                	test   %eax,%eax
8010545f:	78 35                	js     80105496 <sys_read+0x5a>
80105461:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105464:	89 44 24 04          	mov    %eax,0x4(%esp)
80105468:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010546f:	e8 0e fd ff ff       	call   80105182 <argint>
80105474:	85 c0                	test   %eax,%eax
80105476:	78 1e                	js     80105496 <sys_read+0x5a>
80105478:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010547b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010547f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105482:	89 44 24 04          	mov    %eax,0x4(%esp)
80105486:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010548d:	e8 28 fd ff ff       	call   801051ba <argptr>
80105492:	85 c0                	test   %eax,%eax
80105494:	79 07                	jns    8010549d <sys_read+0x61>
    return -1;
80105496:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010549b:	eb 19                	jmp    801054b6 <sys_read+0x7a>
  return fileread(f, p, n);
8010549d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801054a0:	8b 55 ec             	mov    -0x14(%ebp),%edx
801054a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054a6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801054aa:	89 54 24 04          	mov    %edx,0x4(%esp)
801054ae:	89 04 24             	mov    %eax,(%esp)
801054b1:	e8 73 bc ff ff       	call   80101129 <fileread>
}
801054b6:	c9                   	leave  
801054b7:	c3                   	ret    

801054b8 <sys_write>:

int
sys_write(void)
{
801054b8:	55                   	push   %ebp
801054b9:	89 e5                	mov    %esp,%ebp
801054bb:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801054be:	8d 45 f4             	lea    -0xc(%ebp),%eax
801054c1:	89 44 24 08          	mov    %eax,0x8(%esp)
801054c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801054cc:	00 
801054cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801054d4:	e8 4b fe ff ff       	call   80105324 <argfd>
801054d9:	85 c0                	test   %eax,%eax
801054db:	78 35                	js     80105512 <sys_write+0x5a>
801054dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801054e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801054e4:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801054eb:	e8 92 fc ff ff       	call   80105182 <argint>
801054f0:	85 c0                	test   %eax,%eax
801054f2:	78 1e                	js     80105512 <sys_write+0x5a>
801054f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054f7:	89 44 24 08          	mov    %eax,0x8(%esp)
801054fb:	8d 45 ec             	lea    -0x14(%ebp),%eax
801054fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105502:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105509:	e8 ac fc ff ff       	call   801051ba <argptr>
8010550e:	85 c0                	test   %eax,%eax
80105510:	79 07                	jns    80105519 <sys_write+0x61>
    return -1;
80105512:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105517:	eb 19                	jmp    80105532 <sys_write+0x7a>
  return filewrite(f, p, n);
80105519:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010551c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010551f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105522:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105526:	89 54 24 04          	mov    %edx,0x4(%esp)
8010552a:	89 04 24             	mov    %eax,(%esp)
8010552d:	e8 b3 bc ff ff       	call   801011e5 <filewrite>
}
80105532:	c9                   	leave  
80105533:	c3                   	ret    

80105534 <sys_close>:

int
sys_close(void)
{
80105534:	55                   	push   %ebp
80105535:	89 e5                	mov    %esp,%ebp
80105537:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010553a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010553d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105541:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105544:	89 44 24 04          	mov    %eax,0x4(%esp)
80105548:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010554f:	e8 d0 fd ff ff       	call   80105324 <argfd>
80105554:	85 c0                	test   %eax,%eax
80105556:	79 07                	jns    8010555f <sys_close+0x2b>
    return -1;
80105558:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010555d:	eb 24                	jmp    80105583 <sys_close+0x4f>
  proc->ofile[fd] = 0;
8010555f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105565:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105568:	83 c2 08             	add    $0x8,%edx
8010556b:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105572:	00 
  fileclose(f);
80105573:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105576:	89 04 24             	mov    %eax,(%esp)
80105579:	e8 86 ba ff ff       	call   80101004 <fileclose>
  return 0;
8010557e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105583:	c9                   	leave  
80105584:	c3                   	ret    

80105585 <sys_fstat>:

int
sys_fstat(void)
{
80105585:	55                   	push   %ebp
80105586:	89 e5                	mov    %esp,%ebp
80105588:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010558b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010558e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105592:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105599:	00 
8010559a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801055a1:	e8 7e fd ff ff       	call   80105324 <argfd>
801055a6:	85 c0                	test   %eax,%eax
801055a8:	78 1f                	js     801055c9 <sys_fstat+0x44>
801055aa:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801055b1:	00 
801055b2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801055b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801055b9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801055c0:	e8 f5 fb ff ff       	call   801051ba <argptr>
801055c5:	85 c0                	test   %eax,%eax
801055c7:	79 07                	jns    801055d0 <sys_fstat+0x4b>
    return -1;
801055c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055ce:	eb 12                	jmp    801055e2 <sys_fstat+0x5d>
  return filestat(f, st);
801055d0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801055d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801055da:	89 04 24             	mov    %eax,(%esp)
801055dd:	e8 f8 ba ff ff       	call   801010da <filestat>
}
801055e2:	c9                   	leave  
801055e3:	c3                   	ret    

801055e4 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801055e4:	55                   	push   %ebp
801055e5:	89 e5                	mov    %esp,%ebp
801055e7:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801055ea:	8d 45 d8             	lea    -0x28(%ebp),%eax
801055ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801055f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801055f8:	e8 1f fc ff ff       	call   8010521c <argstr>
801055fd:	85 c0                	test   %eax,%eax
801055ff:	78 17                	js     80105618 <sys_link+0x34>
80105601:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105604:	89 44 24 04          	mov    %eax,0x4(%esp)
80105608:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010560f:	e8 08 fc ff ff       	call   8010521c <argstr>
80105614:	85 c0                	test   %eax,%eax
80105616:	79 0a                	jns    80105622 <sys_link+0x3e>
    return -1;
80105618:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010561d:	e9 3c 01 00 00       	jmp    8010575e <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80105622:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105625:	89 04 24             	mov    %eax,(%esp)
80105628:	e8 1d ce ff ff       	call   8010244a <namei>
8010562d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105630:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105634:	75 0a                	jne    80105640 <sys_link+0x5c>
    return -1;
80105636:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010563b:	e9 1e 01 00 00       	jmp    8010575e <sys_link+0x17a>

  begin_trans();
80105640:	e8 18 dc ff ff       	call   8010325d <begin_trans>

  ilock(ip);
80105645:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105648:	89 04 24             	mov    %eax,(%esp)
8010564b:	e8 58 c2 ff ff       	call   801018a8 <ilock>
  if(ip->type == T_DIR){
80105650:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105653:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105657:	66 83 f8 01          	cmp    $0x1,%ax
8010565b:	75 1a                	jne    80105677 <sys_link+0x93>
    iunlockput(ip);
8010565d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105660:	89 04 24             	mov    %eax,(%esp)
80105663:	e8 c4 c4 ff ff       	call   80101b2c <iunlockput>
    commit_trans();
80105668:	e8 39 dc ff ff       	call   801032a6 <commit_trans>
    return -1;
8010566d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105672:	e9 e7 00 00 00       	jmp    8010575e <sys_link+0x17a>
  }

  ip->nlink++;
80105677:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010567a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010567e:	8d 50 01             	lea    0x1(%eax),%edx
80105681:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105684:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105688:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010568b:	89 04 24             	mov    %eax,(%esp)
8010568e:	e8 59 c0 ff ff       	call   801016ec <iupdate>
  iunlock(ip);
80105693:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105696:	89 04 24             	mov    %eax,(%esp)
80105699:	e8 58 c3 ff ff       	call   801019f6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
8010569e:	8b 45 dc             	mov    -0x24(%ebp),%eax
801056a1:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801056a4:	89 54 24 04          	mov    %edx,0x4(%esp)
801056a8:	89 04 24             	mov    %eax,(%esp)
801056ab:	e8 bc cd ff ff       	call   8010246c <nameiparent>
801056b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801056b3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801056b7:	74 68                	je     80105721 <sys_link+0x13d>
    goto bad;
  ilock(dp);
801056b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056bc:	89 04 24             	mov    %eax,(%esp)
801056bf:	e8 e4 c1 ff ff       	call   801018a8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801056c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056c7:	8b 10                	mov    (%eax),%edx
801056c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056cc:	8b 00                	mov    (%eax),%eax
801056ce:	39 c2                	cmp    %eax,%edx
801056d0:	75 20                	jne    801056f2 <sys_link+0x10e>
801056d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056d5:	8b 40 04             	mov    0x4(%eax),%eax
801056d8:	89 44 24 08          	mov    %eax,0x8(%esp)
801056dc:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801056df:	89 44 24 04          	mov    %eax,0x4(%esp)
801056e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056e6:	89 04 24             	mov    %eax,(%esp)
801056e9:	e8 9b ca ff ff       	call   80102189 <dirlink>
801056ee:	85 c0                	test   %eax,%eax
801056f0:	79 0d                	jns    801056ff <sys_link+0x11b>
    iunlockput(dp);
801056f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056f5:	89 04 24             	mov    %eax,(%esp)
801056f8:	e8 2f c4 ff ff       	call   80101b2c <iunlockput>
    goto bad;
801056fd:	eb 23                	jmp    80105722 <sys_link+0x13e>
  }
  iunlockput(dp);
801056ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105702:	89 04 24             	mov    %eax,(%esp)
80105705:	e8 22 c4 ff ff       	call   80101b2c <iunlockput>
  iput(ip);
8010570a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010570d:	89 04 24             	mov    %eax,(%esp)
80105710:	e8 46 c3 ff ff       	call   80101a5b <iput>

  commit_trans();
80105715:	e8 8c db ff ff       	call   801032a6 <commit_trans>

  return 0;
8010571a:	b8 00 00 00 00       	mov    $0x0,%eax
8010571f:	eb 3d                	jmp    8010575e <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105721:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80105722:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105725:	89 04 24             	mov    %eax,(%esp)
80105728:	e8 7b c1 ff ff       	call   801018a8 <ilock>
  ip->nlink--;
8010572d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105730:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105734:	8d 50 ff             	lea    -0x1(%eax),%edx
80105737:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010573a:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010573e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105741:	89 04 24             	mov    %eax,(%esp)
80105744:	e8 a3 bf ff ff       	call   801016ec <iupdate>
  iunlockput(ip);
80105749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010574c:	89 04 24             	mov    %eax,(%esp)
8010574f:	e8 d8 c3 ff ff       	call   80101b2c <iunlockput>
  commit_trans();
80105754:	e8 4d db ff ff       	call   801032a6 <commit_trans>
  return -1;
80105759:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010575e:	c9                   	leave  
8010575f:	c3                   	ret    

80105760 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105760:	55                   	push   %ebp
80105761:	89 e5                	mov    %esp,%ebp
80105763:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105766:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
8010576d:	eb 4b                	jmp    801057ba <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010576f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105772:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105779:	00 
8010577a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010577e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105781:	89 44 24 04          	mov    %eax,0x4(%esp)
80105785:	8b 45 08             	mov    0x8(%ebp),%eax
80105788:	89 04 24             	mov    %eax,(%esp)
8010578b:	e8 0e c6 ff ff       	call   80101d9e <readi>
80105790:	83 f8 10             	cmp    $0x10,%eax
80105793:	74 0c                	je     801057a1 <isdirempty+0x41>
      panic("isdirempty: readi");
80105795:	c7 04 24 d7 85 10 80 	movl   $0x801085d7,(%esp)
8010579c:	e8 9c ad ff ff       	call   8010053d <panic>
    if(de.inum != 0)
801057a1:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801057a5:	66 85 c0             	test   %ax,%ax
801057a8:	74 07                	je     801057b1 <isdirempty+0x51>
      return 0;
801057aa:	b8 00 00 00 00       	mov    $0x0,%eax
801057af:	eb 1b                	jmp    801057cc <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801057b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b4:	83 c0 10             	add    $0x10,%eax
801057b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801057ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801057bd:	8b 45 08             	mov    0x8(%ebp),%eax
801057c0:	8b 40 18             	mov    0x18(%eax),%eax
801057c3:	39 c2                	cmp    %eax,%edx
801057c5:	72 a8                	jb     8010576f <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801057c7:	b8 01 00 00 00       	mov    $0x1,%eax
}
801057cc:	c9                   	leave  
801057cd:	c3                   	ret    

801057ce <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801057ce:	55                   	push   %ebp
801057cf:	89 e5                	mov    %esp,%ebp
801057d1:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
801057d4:	8d 45 cc             	lea    -0x34(%ebp),%eax
801057d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801057db:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801057e2:	e8 35 fa ff ff       	call   8010521c <argstr>
801057e7:	85 c0                	test   %eax,%eax
801057e9:	79 0a                	jns    801057f5 <sys_unlink+0x27>
    return -1;
801057eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057f0:	e9 aa 01 00 00       	jmp    8010599f <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
801057f5:	8b 45 cc             	mov    -0x34(%ebp),%eax
801057f8:	8d 55 d2             	lea    -0x2e(%ebp),%edx
801057fb:	89 54 24 04          	mov    %edx,0x4(%esp)
801057ff:	89 04 24             	mov    %eax,(%esp)
80105802:	e8 65 cc ff ff       	call   8010246c <nameiparent>
80105807:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010580a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010580e:	75 0a                	jne    8010581a <sys_unlink+0x4c>
    return -1;
80105810:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105815:	e9 85 01 00 00       	jmp    8010599f <sys_unlink+0x1d1>

  begin_trans();
8010581a:	e8 3e da ff ff       	call   8010325d <begin_trans>

  ilock(dp);
8010581f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105822:	89 04 24             	mov    %eax,(%esp)
80105825:	e8 7e c0 ff ff       	call   801018a8 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010582a:	c7 44 24 04 e9 85 10 	movl   $0x801085e9,0x4(%esp)
80105831:	80 
80105832:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105835:	89 04 24             	mov    %eax,(%esp)
80105838:	e8 62 c8 ff ff       	call   8010209f <namecmp>
8010583d:	85 c0                	test   %eax,%eax
8010583f:	0f 84 45 01 00 00    	je     8010598a <sys_unlink+0x1bc>
80105845:	c7 44 24 04 eb 85 10 	movl   $0x801085eb,0x4(%esp)
8010584c:	80 
8010584d:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105850:	89 04 24             	mov    %eax,(%esp)
80105853:	e8 47 c8 ff ff       	call   8010209f <namecmp>
80105858:	85 c0                	test   %eax,%eax
8010585a:	0f 84 2a 01 00 00    	je     8010598a <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105860:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105863:	89 44 24 08          	mov    %eax,0x8(%esp)
80105867:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010586a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010586e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105871:	89 04 24             	mov    %eax,(%esp)
80105874:	e8 48 c8 ff ff       	call   801020c1 <dirlookup>
80105879:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010587c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105880:	0f 84 03 01 00 00    	je     80105989 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80105886:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105889:	89 04 24             	mov    %eax,(%esp)
8010588c:	e8 17 c0 ff ff       	call   801018a8 <ilock>

  if(ip->nlink < 1)
80105891:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105894:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105898:	66 85 c0             	test   %ax,%ax
8010589b:	7f 0c                	jg     801058a9 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
8010589d:	c7 04 24 ee 85 10 80 	movl   $0x801085ee,(%esp)
801058a4:	e8 94 ac ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801058a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058ac:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801058b0:	66 83 f8 01          	cmp    $0x1,%ax
801058b4:	75 1f                	jne    801058d5 <sys_unlink+0x107>
801058b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058b9:	89 04 24             	mov    %eax,(%esp)
801058bc:	e8 9f fe ff ff       	call   80105760 <isdirempty>
801058c1:	85 c0                	test   %eax,%eax
801058c3:	75 10                	jne    801058d5 <sys_unlink+0x107>
    iunlockput(ip);
801058c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058c8:	89 04 24             	mov    %eax,(%esp)
801058cb:	e8 5c c2 ff ff       	call   80101b2c <iunlockput>
    goto bad;
801058d0:	e9 b5 00 00 00       	jmp    8010598a <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
801058d5:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801058dc:	00 
801058dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801058e4:	00 
801058e5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801058e8:	89 04 24             	mov    %eax,(%esp)
801058eb:	e8 42 f5 ff ff       	call   80104e32 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801058f0:	8b 45 c8             	mov    -0x38(%ebp),%eax
801058f3:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801058fa:	00 
801058fb:	89 44 24 08          	mov    %eax,0x8(%esp)
801058ff:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105902:	89 44 24 04          	mov    %eax,0x4(%esp)
80105906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105909:	89 04 24             	mov    %eax,(%esp)
8010590c:	e8 f8 c5 ff ff       	call   80101f09 <writei>
80105911:	83 f8 10             	cmp    $0x10,%eax
80105914:	74 0c                	je     80105922 <sys_unlink+0x154>
    panic("unlink: writei");
80105916:	c7 04 24 00 86 10 80 	movl   $0x80108600,(%esp)
8010591d:	e8 1b ac ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80105922:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105925:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105929:	66 83 f8 01          	cmp    $0x1,%ax
8010592d:	75 1c                	jne    8010594b <sys_unlink+0x17d>
    dp->nlink--;
8010592f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105932:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105936:	8d 50 ff             	lea    -0x1(%eax),%edx
80105939:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010593c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105940:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105943:	89 04 24             	mov    %eax,(%esp)
80105946:	e8 a1 bd ff ff       	call   801016ec <iupdate>
  }
  iunlockput(dp);
8010594b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010594e:	89 04 24             	mov    %eax,(%esp)
80105951:	e8 d6 c1 ff ff       	call   80101b2c <iunlockput>

  ip->nlink--;
80105956:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105959:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010595d:	8d 50 ff             	lea    -0x1(%eax),%edx
80105960:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105963:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105967:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010596a:	89 04 24             	mov    %eax,(%esp)
8010596d:	e8 7a bd ff ff       	call   801016ec <iupdate>
  iunlockput(ip);
80105972:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105975:	89 04 24             	mov    %eax,(%esp)
80105978:	e8 af c1 ff ff       	call   80101b2c <iunlockput>

  commit_trans();
8010597d:	e8 24 d9 ff ff       	call   801032a6 <commit_trans>

  return 0;
80105982:	b8 00 00 00 00       	mov    $0x0,%eax
80105987:	eb 16                	jmp    8010599f <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105989:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
8010598a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010598d:	89 04 24             	mov    %eax,(%esp)
80105990:	e8 97 c1 ff ff       	call   80101b2c <iunlockput>
  commit_trans();
80105995:	e8 0c d9 ff ff       	call   801032a6 <commit_trans>
  return -1;
8010599a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010599f:	c9                   	leave  
801059a0:	c3                   	ret    

801059a1 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801059a1:	55                   	push   %ebp
801059a2:	89 e5                	mov    %esp,%ebp
801059a4:	83 ec 48             	sub    $0x48,%esp
801059a7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801059aa:	8b 55 10             	mov    0x10(%ebp),%edx
801059ad:	8b 45 14             	mov    0x14(%ebp),%eax
801059b0:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801059b4:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801059b8:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801059bc:	8d 45 de             	lea    -0x22(%ebp),%eax
801059bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801059c3:	8b 45 08             	mov    0x8(%ebp),%eax
801059c6:	89 04 24             	mov    %eax,(%esp)
801059c9:	e8 9e ca ff ff       	call   8010246c <nameiparent>
801059ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
801059d1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801059d5:	75 0a                	jne    801059e1 <create+0x40>
    return 0;
801059d7:	b8 00 00 00 00       	mov    $0x0,%eax
801059dc:	e9 7e 01 00 00       	jmp    80105b5f <create+0x1be>
  ilock(dp);
801059e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059e4:	89 04 24             	mov    %eax,(%esp)
801059e7:	e8 bc be ff ff       	call   801018a8 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801059ec:	8d 45 ec             	lea    -0x14(%ebp),%eax
801059ef:	89 44 24 08          	mov    %eax,0x8(%esp)
801059f3:	8d 45 de             	lea    -0x22(%ebp),%eax
801059f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801059fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059fd:	89 04 24             	mov    %eax,(%esp)
80105a00:	e8 bc c6 ff ff       	call   801020c1 <dirlookup>
80105a05:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a08:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105a0c:	74 47                	je     80105a55 <create+0xb4>
    iunlockput(dp);
80105a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a11:	89 04 24             	mov    %eax,(%esp)
80105a14:	e8 13 c1 ff ff       	call   80101b2c <iunlockput>
    ilock(ip);
80105a19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a1c:	89 04 24             	mov    %eax,(%esp)
80105a1f:	e8 84 be ff ff       	call   801018a8 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105a24:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105a29:	75 15                	jne    80105a40 <create+0x9f>
80105a2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a2e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105a32:	66 83 f8 02          	cmp    $0x2,%ax
80105a36:	75 08                	jne    80105a40 <create+0x9f>
      return ip;
80105a38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a3b:	e9 1f 01 00 00       	jmp    80105b5f <create+0x1be>
    iunlockput(ip);
80105a40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a43:	89 04 24             	mov    %eax,(%esp)
80105a46:	e8 e1 c0 ff ff       	call   80101b2c <iunlockput>
    return 0;
80105a4b:	b8 00 00 00 00       	mov    $0x0,%eax
80105a50:	e9 0a 01 00 00       	jmp    80105b5f <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105a55:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105a59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a5c:	8b 00                	mov    (%eax),%eax
80105a5e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a62:	89 04 24             	mov    %eax,(%esp)
80105a65:	e8 a5 bb ff ff       	call   8010160f <ialloc>
80105a6a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a6d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105a71:	75 0c                	jne    80105a7f <create+0xde>
    panic("create: ialloc");
80105a73:	c7 04 24 0f 86 10 80 	movl   $0x8010860f,(%esp)
80105a7a:	e8 be aa ff ff       	call   8010053d <panic>

  ilock(ip);
80105a7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a82:	89 04 24             	mov    %eax,(%esp)
80105a85:	e8 1e be ff ff       	call   801018a8 <ilock>
  ip->major = major;
80105a8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a8d:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105a91:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105a95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a98:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105a9c:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105aa0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aa3:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105aa9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aac:	89 04 24             	mov    %eax,(%esp)
80105aaf:	e8 38 bc ff ff       	call   801016ec <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105ab4:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105ab9:	75 6a                	jne    80105b25 <create+0x184>
    dp->nlink++;  // for ".."
80105abb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105abe:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105ac2:	8d 50 01             	lea    0x1(%eax),%edx
80105ac5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ac8:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105acf:	89 04 24             	mov    %eax,(%esp)
80105ad2:	e8 15 bc ff ff       	call   801016ec <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105ad7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ada:	8b 40 04             	mov    0x4(%eax),%eax
80105add:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ae1:	c7 44 24 04 e9 85 10 	movl   $0x801085e9,0x4(%esp)
80105ae8:	80 
80105ae9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aec:	89 04 24             	mov    %eax,(%esp)
80105aef:	e8 95 c6 ff ff       	call   80102189 <dirlink>
80105af4:	85 c0                	test   %eax,%eax
80105af6:	78 21                	js     80105b19 <create+0x178>
80105af8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105afb:	8b 40 04             	mov    0x4(%eax),%eax
80105afe:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b02:	c7 44 24 04 eb 85 10 	movl   $0x801085eb,0x4(%esp)
80105b09:	80 
80105b0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b0d:	89 04 24             	mov    %eax,(%esp)
80105b10:	e8 74 c6 ff ff       	call   80102189 <dirlink>
80105b15:	85 c0                	test   %eax,%eax
80105b17:	79 0c                	jns    80105b25 <create+0x184>
      panic("create dots");
80105b19:	c7 04 24 1e 86 10 80 	movl   $0x8010861e,(%esp)
80105b20:	e8 18 aa ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105b25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b28:	8b 40 04             	mov    0x4(%eax),%eax
80105b2b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b2f:	8d 45 de             	lea    -0x22(%ebp),%eax
80105b32:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b39:	89 04 24             	mov    %eax,(%esp)
80105b3c:	e8 48 c6 ff ff       	call   80102189 <dirlink>
80105b41:	85 c0                	test   %eax,%eax
80105b43:	79 0c                	jns    80105b51 <create+0x1b0>
    panic("create: dirlink");
80105b45:	c7 04 24 2a 86 10 80 	movl   $0x8010862a,(%esp)
80105b4c:	e8 ec a9 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80105b51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b54:	89 04 24             	mov    %eax,(%esp)
80105b57:	e8 d0 bf ff ff       	call   80101b2c <iunlockput>

  return ip;
80105b5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105b5f:	c9                   	leave  
80105b60:	c3                   	ret    

80105b61 <sys_open>:

int
sys_open(void)
{
80105b61:	55                   	push   %ebp
80105b62:	89 e5                	mov    %esp,%ebp
80105b64:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105b67:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105b6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b6e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105b75:	e8 a2 f6 ff ff       	call   8010521c <argstr>
80105b7a:	85 c0                	test   %eax,%eax
80105b7c:	78 17                	js     80105b95 <sys_open+0x34>
80105b7e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105b81:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b85:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105b8c:	e8 f1 f5 ff ff       	call   80105182 <argint>
80105b91:	85 c0                	test   %eax,%eax
80105b93:	79 0a                	jns    80105b9f <sys_open+0x3e>
    return -1;
80105b95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b9a:	e9 46 01 00 00       	jmp    80105ce5 <sys_open+0x184>
  if(omode & O_CREATE){
80105b9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ba2:	25 00 02 00 00       	and    $0x200,%eax
80105ba7:	85 c0                	test   %eax,%eax
80105ba9:	74 40                	je     80105beb <sys_open+0x8a>
    begin_trans();
80105bab:	e8 ad d6 ff ff       	call   8010325d <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105bb0:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105bb3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105bba:	00 
80105bbb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105bc2:	00 
80105bc3:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105bca:	00 
80105bcb:	89 04 24             	mov    %eax,(%esp)
80105bce:	e8 ce fd ff ff       	call   801059a1 <create>
80105bd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105bd6:	e8 cb d6 ff ff       	call   801032a6 <commit_trans>
    if(ip == 0)
80105bdb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105bdf:	75 5c                	jne    80105c3d <sys_open+0xdc>
      return -1;
80105be1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105be6:	e9 fa 00 00 00       	jmp    80105ce5 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80105beb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105bee:	89 04 24             	mov    %eax,(%esp)
80105bf1:	e8 54 c8 ff ff       	call   8010244a <namei>
80105bf6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105bf9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105bfd:	75 0a                	jne    80105c09 <sys_open+0xa8>
      return -1;
80105bff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c04:	e9 dc 00 00 00       	jmp    80105ce5 <sys_open+0x184>
    ilock(ip);
80105c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c0c:	89 04 24             	mov    %eax,(%esp)
80105c0f:	e8 94 bc ff ff       	call   801018a8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105c14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c17:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c1b:	66 83 f8 01          	cmp    $0x1,%ax
80105c1f:	75 1c                	jne    80105c3d <sys_open+0xdc>
80105c21:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c24:	85 c0                	test   %eax,%eax
80105c26:	74 15                	je     80105c3d <sys_open+0xdc>
      iunlockput(ip);
80105c28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c2b:	89 04 24             	mov    %eax,(%esp)
80105c2e:	e8 f9 be ff ff       	call   80101b2c <iunlockput>
      return -1;
80105c33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c38:	e9 a8 00 00 00       	jmp    80105ce5 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105c3d:	e8 1a b3 ff ff       	call   80100f5c <filealloc>
80105c42:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c45:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c49:	74 14                	je     80105c5f <sys_open+0xfe>
80105c4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c4e:	89 04 24             	mov    %eax,(%esp)
80105c51:	e8 43 f7 ff ff       	call   80105399 <fdalloc>
80105c56:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105c59:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105c5d:	79 23                	jns    80105c82 <sys_open+0x121>
    if(f)
80105c5f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c63:	74 0b                	je     80105c70 <sys_open+0x10f>
      fileclose(f);
80105c65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c68:	89 04 24             	mov    %eax,(%esp)
80105c6b:	e8 94 b3 ff ff       	call   80101004 <fileclose>
    iunlockput(ip);
80105c70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c73:	89 04 24             	mov    %eax,(%esp)
80105c76:	e8 b1 be ff ff       	call   80101b2c <iunlockput>
    return -1;
80105c7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c80:	eb 63                	jmp    80105ce5 <sys_open+0x184>
  }
  iunlock(ip);
80105c82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c85:	89 04 24             	mov    %eax,(%esp)
80105c88:	e8 69 bd ff ff       	call   801019f6 <iunlock>

  f->type = FD_INODE;
80105c8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c90:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105c96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c99:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105c9c:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105c9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ca2:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105ca9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105cac:	83 e0 01             	and    $0x1,%eax
80105caf:	85 c0                	test   %eax,%eax
80105cb1:	0f 94 c2             	sete   %dl
80105cb4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cb7:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105cba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105cbd:	83 e0 01             	and    $0x1,%eax
80105cc0:	84 c0                	test   %al,%al
80105cc2:	75 0a                	jne    80105cce <sys_open+0x16d>
80105cc4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105cc7:	83 e0 02             	and    $0x2,%eax
80105cca:	85 c0                	test   %eax,%eax
80105ccc:	74 07                	je     80105cd5 <sys_open+0x174>
80105cce:	b8 01 00 00 00       	mov    $0x1,%eax
80105cd3:	eb 05                	jmp    80105cda <sys_open+0x179>
80105cd5:	b8 00 00 00 00       	mov    $0x0,%eax
80105cda:	89 c2                	mov    %eax,%edx
80105cdc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cdf:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105ce2:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105ce5:	c9                   	leave  
80105ce6:	c3                   	ret    

80105ce7 <sys_mkdir>:

int
sys_mkdir(void)
{
80105ce7:	55                   	push   %ebp
80105ce8:	89 e5                	mov    %esp,%ebp
80105cea:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80105ced:	e8 6b d5 ff ff       	call   8010325d <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105cf2:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105cf5:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cf9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d00:	e8 17 f5 ff ff       	call   8010521c <argstr>
80105d05:	85 c0                	test   %eax,%eax
80105d07:	78 2c                	js     80105d35 <sys_mkdir+0x4e>
80105d09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d0c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105d13:	00 
80105d14:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105d1b:	00 
80105d1c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105d23:	00 
80105d24:	89 04 24             	mov    %eax,(%esp)
80105d27:	e8 75 fc ff ff       	call   801059a1 <create>
80105d2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d2f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d33:	75 0c                	jne    80105d41 <sys_mkdir+0x5a>
    commit_trans();
80105d35:	e8 6c d5 ff ff       	call   801032a6 <commit_trans>
    return -1;
80105d3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d3f:	eb 15                	jmp    80105d56 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105d41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d44:	89 04 24             	mov    %eax,(%esp)
80105d47:	e8 e0 bd ff ff       	call   80101b2c <iunlockput>
  commit_trans();
80105d4c:	e8 55 d5 ff ff       	call   801032a6 <commit_trans>
  return 0;
80105d51:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d56:	c9                   	leave  
80105d57:	c3                   	ret    

80105d58 <sys_mknod>:

int
sys_mknod(void)
{
80105d58:	55                   	push   %ebp
80105d59:	89 e5                	mov    %esp,%ebp
80105d5b:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80105d5e:	e8 fa d4 ff ff       	call   8010325d <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80105d63:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105d66:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d6a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d71:	e8 a6 f4 ff ff       	call   8010521c <argstr>
80105d76:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d79:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d7d:	78 5e                	js     80105ddd <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80105d7f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105d82:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d86:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105d8d:	e8 f0 f3 ff ff       	call   80105182 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80105d92:	85 c0                	test   %eax,%eax
80105d94:	78 47                	js     80105ddd <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105d96:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105d99:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d9d:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105da4:	e8 d9 f3 ff ff       	call   80105182 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80105da9:	85 c0                	test   %eax,%eax
80105dab:	78 30                	js     80105ddd <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80105dad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105db0:	0f bf c8             	movswl %ax,%ecx
80105db3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105db6:	0f bf d0             	movswl %ax,%edx
80105db9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105dbc:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80105dc0:	89 54 24 08          	mov    %edx,0x8(%esp)
80105dc4:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80105dcb:	00 
80105dcc:	89 04 24             	mov    %eax,(%esp)
80105dcf:	e8 cd fb ff ff       	call   801059a1 <create>
80105dd4:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105dd7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ddb:	75 0c                	jne    80105de9 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80105ddd:	e8 c4 d4 ff ff       	call   801032a6 <commit_trans>
    return -1;
80105de2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105de7:	eb 15                	jmp    80105dfe <sys_mknod+0xa6>
  }
  iunlockput(ip);
80105de9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dec:	89 04 24             	mov    %eax,(%esp)
80105def:	e8 38 bd ff ff       	call   80101b2c <iunlockput>
  commit_trans();
80105df4:	e8 ad d4 ff ff       	call   801032a6 <commit_trans>
  return 0;
80105df9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dfe:	c9                   	leave  
80105dff:	c3                   	ret    

80105e00 <sys_chdir>:

int
sys_chdir(void)
{
80105e00:	55                   	push   %ebp
80105e01:	89 e5                	mov    %esp,%ebp
80105e03:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80105e06:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e09:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e0d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e14:	e8 03 f4 ff ff       	call   8010521c <argstr>
80105e19:	85 c0                	test   %eax,%eax
80105e1b:	78 14                	js     80105e31 <sys_chdir+0x31>
80105e1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e20:	89 04 24             	mov    %eax,(%esp)
80105e23:	e8 22 c6 ff ff       	call   8010244a <namei>
80105e28:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e2b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e2f:	75 07                	jne    80105e38 <sys_chdir+0x38>
    return -1;
80105e31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e36:	eb 57                	jmp    80105e8f <sys_chdir+0x8f>
  ilock(ip);
80105e38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e3b:	89 04 24             	mov    %eax,(%esp)
80105e3e:	e8 65 ba ff ff       	call   801018a8 <ilock>
  if(ip->type != T_DIR){
80105e43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e46:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105e4a:	66 83 f8 01          	cmp    $0x1,%ax
80105e4e:	74 12                	je     80105e62 <sys_chdir+0x62>
    iunlockput(ip);
80105e50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e53:	89 04 24             	mov    %eax,(%esp)
80105e56:	e8 d1 bc ff ff       	call   80101b2c <iunlockput>
    return -1;
80105e5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e60:	eb 2d                	jmp    80105e8f <sys_chdir+0x8f>
  }
  iunlock(ip);
80105e62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e65:	89 04 24             	mov    %eax,(%esp)
80105e68:	e8 89 bb ff ff       	call   801019f6 <iunlock>
  iput(proc->cwd);
80105e6d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e73:	8b 40 68             	mov    0x68(%eax),%eax
80105e76:	89 04 24             	mov    %eax,(%esp)
80105e79:	e8 dd bb ff ff       	call   80101a5b <iput>
  proc->cwd = ip;
80105e7e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e84:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e87:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80105e8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e8f:	c9                   	leave  
80105e90:	c3                   	ret    

80105e91 <sys_exec>:

int
sys_exec(void)
{
80105e91:	55                   	push   %ebp
80105e92:	89 e5                	mov    %esp,%ebp
80105e94:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80105e9a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e9d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ea1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ea8:	e8 6f f3 ff ff       	call   8010521c <argstr>
80105ead:	85 c0                	test   %eax,%eax
80105eaf:	78 1a                	js     80105ecb <sys_exec+0x3a>
80105eb1:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80105eb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ebb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ec2:	e8 bb f2 ff ff       	call   80105182 <argint>
80105ec7:	85 c0                	test   %eax,%eax
80105ec9:	79 0a                	jns    80105ed5 <sys_exec+0x44>
    return -1;
80105ecb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ed0:	e9 e2 00 00 00       	jmp    80105fb7 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80105ed5:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80105edc:	00 
80105edd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105ee4:	00 
80105ee5:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105eeb:	89 04 24             	mov    %eax,(%esp)
80105eee:	e8 3f ef ff ff       	call   80104e32 <memset>
  for(i=0;; i++){
80105ef3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80105efa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105efd:	83 f8 1f             	cmp    $0x1f,%eax
80105f00:	76 0a                	jbe    80105f0c <sys_exec+0x7b>
      return -1;
80105f02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f07:	e9 ab 00 00 00       	jmp    80105fb7 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80105f0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f0f:	c1 e0 02             	shl    $0x2,%eax
80105f12:	89 c2                	mov    %eax,%edx
80105f14:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80105f1a:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80105f1d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f23:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80105f29:	89 54 24 08          	mov    %edx,0x8(%esp)
80105f2d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105f31:	89 04 24             	mov    %eax,(%esp)
80105f34:	e8 b7 f1 ff ff       	call   801050f0 <fetchint>
80105f39:	85 c0                	test   %eax,%eax
80105f3b:	79 07                	jns    80105f44 <sys_exec+0xb3>
      return -1;
80105f3d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f42:	eb 73                	jmp    80105fb7 <sys_exec+0x126>
    if(uarg == 0){
80105f44:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80105f4a:	85 c0                	test   %eax,%eax
80105f4c:	75 26                	jne    80105f74 <sys_exec+0xe3>
      argv[i] = 0;
80105f4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f51:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80105f58:	00 00 00 00 
      break;
80105f5c:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80105f5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f60:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80105f66:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f6a:	89 04 24             	mov    %eax,(%esp)
80105f6d:	e8 8a ab ff ff       	call   80100afc <exec>
80105f72:	eb 43                	jmp    80105fb7 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80105f74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f77:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105f7e:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105f84:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80105f87:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80105f8d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105f97:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f9b:	89 04 24             	mov    %eax,(%esp)
80105f9e:	e8 81 f1 ff ff       	call   80105124 <fetchstr>
80105fa3:	85 c0                	test   %eax,%eax
80105fa5:	79 07                	jns    80105fae <sys_exec+0x11d>
      return -1;
80105fa7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fac:	eb 09                	jmp    80105fb7 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80105fae:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80105fb2:	e9 43 ff ff ff       	jmp    80105efa <sys_exec+0x69>
  return exec(path, argv);
}
80105fb7:	c9                   	leave  
80105fb8:	c3                   	ret    

80105fb9 <sys_pipe>:

int
sys_pipe(void)
{
80105fb9:	55                   	push   %ebp
80105fba:	89 e5                	mov    %esp,%ebp
80105fbc:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80105fbf:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80105fc6:	00 
80105fc7:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105fca:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fd5:	e8 e0 f1 ff ff       	call   801051ba <argptr>
80105fda:	85 c0                	test   %eax,%eax
80105fdc:	79 0a                	jns    80105fe8 <sys_pipe+0x2f>
    return -1;
80105fde:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fe3:	e9 9b 00 00 00       	jmp    80106083 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80105fe8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105feb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fef:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105ff2:	89 04 24             	mov    %eax,(%esp)
80105ff5:	e8 7e dc ff ff       	call   80103c78 <pipealloc>
80105ffa:	85 c0                	test   %eax,%eax
80105ffc:	79 07                	jns    80106005 <sys_pipe+0x4c>
    return -1;
80105ffe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106003:	eb 7e                	jmp    80106083 <sys_pipe+0xca>
  fd0 = -1;
80106005:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010600c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010600f:	89 04 24             	mov    %eax,(%esp)
80106012:	e8 82 f3 ff ff       	call   80105399 <fdalloc>
80106017:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010601a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010601e:	78 14                	js     80106034 <sys_pipe+0x7b>
80106020:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106023:	89 04 24             	mov    %eax,(%esp)
80106026:	e8 6e f3 ff ff       	call   80105399 <fdalloc>
8010602b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010602e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106032:	79 37                	jns    8010606b <sys_pipe+0xb2>
    if(fd0 >= 0)
80106034:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106038:	78 14                	js     8010604e <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
8010603a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106040:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106043:	83 c2 08             	add    $0x8,%edx
80106046:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010604d:	00 
    fileclose(rf);
8010604e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106051:	89 04 24             	mov    %eax,(%esp)
80106054:	e8 ab af ff ff       	call   80101004 <fileclose>
    fileclose(wf);
80106059:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010605c:	89 04 24             	mov    %eax,(%esp)
8010605f:	e8 a0 af ff ff       	call   80101004 <fileclose>
    return -1;
80106064:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106069:	eb 18                	jmp    80106083 <sys_pipe+0xca>
  }
  fd[0] = fd0;
8010606b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010606e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106071:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106073:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106076:	8d 50 04             	lea    0x4(%eax),%edx
80106079:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010607c:	89 02                	mov    %eax,(%edx)
  return 0;
8010607e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106083:	c9                   	leave  
80106084:	c3                   	ret    
80106085:	00 00                	add    %al,(%eax)
	...

80106088 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106088:	55                   	push   %ebp
80106089:	89 e5                	mov    %esp,%ebp
8010608b:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010608e:	e8 9f e2 ff ff       	call   80104332 <fork>
}
80106093:	c9                   	leave  
80106094:	c3                   	ret    

80106095 <sys_exit>:

int
sys_exit(void)
{
80106095:	55                   	push   %ebp
80106096:	89 e5                	mov    %esp,%ebp
80106098:	83 ec 08             	sub    $0x8,%esp
  exit();
8010609b:	e8 f5 e3 ff ff       	call   80104495 <exit>
  return 0;  // not reached
801060a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060a5:	c9                   	leave  
801060a6:	c3                   	ret    

801060a7 <sys_wait>:

int
sys_wait(void)
{
801060a7:	55                   	push   %ebp
801060a8:	89 e5                	mov    %esp,%ebp
801060aa:	83 ec 08             	sub    $0x8,%esp
  return wait();
801060ad:	e8 fb e4 ff ff       	call   801045ad <wait>
}
801060b2:	c9                   	leave  
801060b3:	c3                   	ret    

801060b4 <sys_kill>:

int
sys_kill(void)
{
801060b4:	55                   	push   %ebp
801060b5:	89 e5                	mov    %esp,%ebp
801060b7:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801060ba:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801060c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060c8:	e8 b5 f0 ff ff       	call   80105182 <argint>
801060cd:	85 c0                	test   %eax,%eax
801060cf:	79 07                	jns    801060d8 <sys_kill+0x24>
    return -1;
801060d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060d6:	eb 0b                	jmp    801060e3 <sys_kill+0x2f>
  return kill(pid);
801060d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060db:	89 04 24             	mov    %eax,(%esp)
801060de:	e8 26 e9 ff ff       	call   80104a09 <kill>
}
801060e3:	c9                   	leave  
801060e4:	c3                   	ret    

801060e5 <sys_getpid>:

int
sys_getpid(void)
{
801060e5:	55                   	push   %ebp
801060e6:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801060e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060ee:	8b 40 10             	mov    0x10(%eax),%eax
}
801060f1:	5d                   	pop    %ebp
801060f2:	c3                   	ret    

801060f3 <sys_sbrk>:

int
sys_sbrk(void)
{
801060f3:	55                   	push   %ebp
801060f4:	89 e5                	mov    %esp,%ebp
801060f6:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801060f9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80106100:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106107:	e8 76 f0 ff ff       	call   80105182 <argint>
8010610c:	85 c0                	test   %eax,%eax
8010610e:	79 07                	jns    80106117 <sys_sbrk+0x24>
    return -1;
80106110:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106115:	eb 24                	jmp    8010613b <sys_sbrk+0x48>
  addr = proc->sz;
80106117:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010611d:	8b 00                	mov    (%eax),%eax
8010611f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106122:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106125:	89 04 24             	mov    %eax,(%esp)
80106128:	e8 60 e1 ff ff       	call   8010428d <growproc>
8010612d:	85 c0                	test   %eax,%eax
8010612f:	79 07                	jns    80106138 <sys_sbrk+0x45>
    return -1;
80106131:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106136:	eb 03                	jmp    8010613b <sys_sbrk+0x48>
  return addr;
80106138:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010613b:	c9                   	leave  
8010613c:	c3                   	ret    

8010613d <sys_sleep>:

int
sys_sleep(void)
{
8010613d:	55                   	push   %ebp
8010613e:	89 e5                	mov    %esp,%ebp
80106140:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106143:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106146:	89 44 24 04          	mov    %eax,0x4(%esp)
8010614a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106151:	e8 2c f0 ff ff       	call   80105182 <argint>
80106156:	85 c0                	test   %eax,%eax
80106158:	79 07                	jns    80106161 <sys_sleep+0x24>
    return -1;
8010615a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010615f:	eb 6c                	jmp    801061cd <sys_sleep+0x90>
  acquire(&tickslock);
80106161:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106168:	e8 76 ea ff ff       	call   80104be3 <acquire>
  ticks0 = ticks;
8010616d:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
80106172:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106175:	eb 34                	jmp    801061ab <sys_sleep+0x6e>
    if(proc->killed){
80106177:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010617d:	8b 40 24             	mov    0x24(%eax),%eax
80106180:	85 c0                	test   %eax,%eax
80106182:	74 13                	je     80106197 <sys_sleep+0x5a>
      release(&tickslock);
80106184:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
8010618b:	e8 b5 ea ff ff       	call   80104c45 <release>
      return -1;
80106190:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106195:	eb 36                	jmp    801061cd <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106197:	c7 44 24 04 80 23 11 	movl   $0x80112380,0x4(%esp)
8010619e:	80 
8010619f:	c7 04 24 c0 2b 11 80 	movl   $0x80112bc0,(%esp)
801061a6:	e8 5a e7 ff ff       	call   80104905 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801061ab:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
801061b0:	89 c2                	mov    %eax,%edx
801061b2:	2b 55 f4             	sub    -0xc(%ebp),%edx
801061b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b8:	39 c2                	cmp    %eax,%edx
801061ba:	72 bb                	jb     80106177 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801061bc:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801061c3:	e8 7d ea ff ff       	call   80104c45 <release>
  return 0;
801061c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061cd:	c9                   	leave  
801061ce:	c3                   	ret    

801061cf <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801061cf:	55                   	push   %ebp
801061d0:	89 e5                	mov    %esp,%ebp
801061d2:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801061d5:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801061dc:	e8 02 ea ff ff       	call   80104be3 <acquire>
  xticks = ticks;
801061e1:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
801061e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801061e9:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801061f0:	e8 50 ea ff ff       	call   80104c45 <release>
  return xticks;
801061f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801061f8:	c9                   	leave  
801061f9:	c3                   	ret    
	...

801061fc <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801061fc:	55                   	push   %ebp
801061fd:	89 e5                	mov    %esp,%ebp
801061ff:	83 ec 08             	sub    $0x8,%esp
80106202:	8b 55 08             	mov    0x8(%ebp),%edx
80106205:	8b 45 0c             	mov    0xc(%ebp),%eax
80106208:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010620c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010620f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106213:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106217:	ee                   	out    %al,(%dx)
}
80106218:	c9                   	leave  
80106219:	c3                   	ret    

8010621a <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010621a:	55                   	push   %ebp
8010621b:	89 e5                	mov    %esp,%ebp
8010621d:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106220:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106227:	00 
80106228:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010622f:	e8 c8 ff ff ff       	call   801061fc <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106234:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010623b:	00 
8010623c:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106243:	e8 b4 ff ff ff       	call   801061fc <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106248:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
8010624f:	00 
80106250:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106257:	e8 a0 ff ff ff       	call   801061fc <outb>
  picenable(IRQ_TIMER);
8010625c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106263:	e8 99 d8 ff ff       	call   80103b01 <picenable>
}
80106268:	c9                   	leave  
80106269:	c3                   	ret    
	...

8010626c <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
8010626c:	1e                   	push   %ds
  pushl %es
8010626d:	06                   	push   %es
  pushl %fs
8010626e:	0f a0                	push   %fs
  pushl %gs
80106270:	0f a8                	push   %gs
  pushal
80106272:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106273:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106277:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106279:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
8010627b:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010627f:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106281:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106283:	54                   	push   %esp
  call trap
80106284:	e8 de 01 00 00       	call   80106467 <trap>
  addl $4, %esp
80106289:	83 c4 04             	add    $0x4,%esp

8010628c <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
8010628c:	61                   	popa   
  popl %gs
8010628d:	0f a9                	pop    %gs
  popl %fs
8010628f:	0f a1                	pop    %fs
  popl %es
80106291:	07                   	pop    %es
  popl %ds
80106292:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106293:	83 c4 08             	add    $0x8,%esp
  iret
80106296:	cf                   	iret   
	...

80106298 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106298:	55                   	push   %ebp
80106299:	89 e5                	mov    %esp,%ebp
8010629b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010629e:	8b 45 0c             	mov    0xc(%ebp),%eax
801062a1:	83 e8 01             	sub    $0x1,%eax
801062a4:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801062a8:	8b 45 08             	mov    0x8(%ebp),%eax
801062ab:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801062af:	8b 45 08             	mov    0x8(%ebp),%eax
801062b2:	c1 e8 10             	shr    $0x10,%eax
801062b5:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801062b9:	8d 45 fa             	lea    -0x6(%ebp),%eax
801062bc:	0f 01 18             	lidtl  (%eax)
}
801062bf:	c9                   	leave  
801062c0:	c3                   	ret    

801062c1 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801062c1:	55                   	push   %ebp
801062c2:	89 e5                	mov    %esp,%ebp
801062c4:	53                   	push   %ebx
801062c5:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801062c8:	0f 20 d3             	mov    %cr2,%ebx
801062cb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801062ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801062d1:	83 c4 10             	add    $0x10,%esp
801062d4:	5b                   	pop    %ebx
801062d5:	5d                   	pop    %ebp
801062d6:	c3                   	ret    

801062d7 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801062d7:	55                   	push   %ebp
801062d8:	89 e5                	mov    %esp,%ebp
801062da:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801062dd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801062e4:	e9 c3 00 00 00       	jmp    801063ac <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801062e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ec:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801062f3:	89 c2                	mov    %eax,%edx
801062f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f8:	66 89 14 c5 c0 23 11 	mov    %dx,-0x7feedc40(,%eax,8)
801062ff:	80 
80106300:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106303:	66 c7 04 c5 c2 23 11 	movw   $0x8,-0x7feedc3e(,%eax,8)
8010630a:	80 08 00 
8010630d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106310:	0f b6 14 c5 c4 23 11 	movzbl -0x7feedc3c(,%eax,8),%edx
80106317:	80 
80106318:	83 e2 e0             	and    $0xffffffe0,%edx
8010631b:	88 14 c5 c4 23 11 80 	mov    %dl,-0x7feedc3c(,%eax,8)
80106322:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106325:	0f b6 14 c5 c4 23 11 	movzbl -0x7feedc3c(,%eax,8),%edx
8010632c:	80 
8010632d:	83 e2 1f             	and    $0x1f,%edx
80106330:	88 14 c5 c4 23 11 80 	mov    %dl,-0x7feedc3c(,%eax,8)
80106337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010633a:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106341:	80 
80106342:	83 e2 f0             	and    $0xfffffff0,%edx
80106345:	83 ca 0e             	or     $0xe,%edx
80106348:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
8010634f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106352:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106359:	80 
8010635a:	83 e2 ef             	and    $0xffffffef,%edx
8010635d:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
80106364:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106367:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
8010636e:	80 
8010636f:	83 e2 9f             	and    $0xffffff9f,%edx
80106372:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
80106379:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010637c:	0f b6 14 c5 c5 23 11 	movzbl -0x7feedc3b(,%eax,8),%edx
80106383:	80 
80106384:	83 ca 80             	or     $0xffffff80,%edx
80106387:	88 14 c5 c5 23 11 80 	mov    %dl,-0x7feedc3b(,%eax,8)
8010638e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106391:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106398:	c1 e8 10             	shr    $0x10,%eax
8010639b:	89 c2                	mov    %eax,%edx
8010639d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063a0:	66 89 14 c5 c6 23 11 	mov    %dx,-0x7feedc3a(,%eax,8)
801063a7:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801063a8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801063ac:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801063b3:	0f 8e 30 ff ff ff    	jle    801062e9 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801063b9:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801063be:	66 a3 c0 25 11 80    	mov    %ax,0x801125c0
801063c4:	66 c7 05 c2 25 11 80 	movw   $0x8,0x801125c2
801063cb:	08 00 
801063cd:	0f b6 05 c4 25 11 80 	movzbl 0x801125c4,%eax
801063d4:	83 e0 e0             	and    $0xffffffe0,%eax
801063d7:	a2 c4 25 11 80       	mov    %al,0x801125c4
801063dc:	0f b6 05 c4 25 11 80 	movzbl 0x801125c4,%eax
801063e3:	83 e0 1f             	and    $0x1f,%eax
801063e6:	a2 c4 25 11 80       	mov    %al,0x801125c4
801063eb:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
801063f2:	83 c8 0f             	or     $0xf,%eax
801063f5:	a2 c5 25 11 80       	mov    %al,0x801125c5
801063fa:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
80106401:	83 e0 ef             	and    $0xffffffef,%eax
80106404:	a2 c5 25 11 80       	mov    %al,0x801125c5
80106409:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
80106410:	83 c8 60             	or     $0x60,%eax
80106413:	a2 c5 25 11 80       	mov    %al,0x801125c5
80106418:	0f b6 05 c5 25 11 80 	movzbl 0x801125c5,%eax
8010641f:	83 c8 80             	or     $0xffffff80,%eax
80106422:	a2 c5 25 11 80       	mov    %al,0x801125c5
80106427:	a1 98 b1 10 80       	mov    0x8010b198,%eax
8010642c:	c1 e8 10             	shr    $0x10,%eax
8010642f:	66 a3 c6 25 11 80    	mov    %ax,0x801125c6
  
  initlock(&tickslock, "time");
80106435:	c7 44 24 04 3c 86 10 	movl   $0x8010863c,0x4(%esp)
8010643c:	80 
8010643d:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
80106444:	e8 79 e7 ff ff       	call   80104bc2 <initlock>
}
80106449:	c9                   	leave  
8010644a:	c3                   	ret    

8010644b <idtinit>:

void
idtinit(void)
{
8010644b:	55                   	push   %ebp
8010644c:	89 e5                	mov    %esp,%ebp
8010644e:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106451:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106458:	00 
80106459:	c7 04 24 c0 23 11 80 	movl   $0x801123c0,(%esp)
80106460:	e8 33 fe ff ff       	call   80106298 <lidt>
}
80106465:	c9                   	leave  
80106466:	c3                   	ret    

80106467 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106467:	55                   	push   %ebp
80106468:	89 e5                	mov    %esp,%ebp
8010646a:	57                   	push   %edi
8010646b:	56                   	push   %esi
8010646c:	53                   	push   %ebx
8010646d:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106470:	8b 45 08             	mov    0x8(%ebp),%eax
80106473:	8b 40 30             	mov    0x30(%eax),%eax
80106476:	83 f8 40             	cmp    $0x40,%eax
80106479:	75 3e                	jne    801064b9 <trap+0x52>
    if(proc->killed)
8010647b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106481:	8b 40 24             	mov    0x24(%eax),%eax
80106484:	85 c0                	test   %eax,%eax
80106486:	74 05                	je     8010648d <trap+0x26>
      exit();
80106488:	e8 08 e0 ff ff       	call   80104495 <exit>
    proc->tf = tf;
8010648d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106493:	8b 55 08             	mov    0x8(%ebp),%edx
80106496:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106499:	e8 c1 ed ff ff       	call   8010525f <syscall>
    if(proc->killed)
8010649e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064a4:	8b 40 24             	mov    0x24(%eax),%eax
801064a7:	85 c0                	test   %eax,%eax
801064a9:	0f 84 34 02 00 00    	je     801066e3 <trap+0x27c>
      exit();
801064af:	e8 e1 df ff ff       	call   80104495 <exit>
    return;
801064b4:	e9 2a 02 00 00       	jmp    801066e3 <trap+0x27c>
  }

  switch(tf->trapno){
801064b9:	8b 45 08             	mov    0x8(%ebp),%eax
801064bc:	8b 40 30             	mov    0x30(%eax),%eax
801064bf:	83 e8 20             	sub    $0x20,%eax
801064c2:	83 f8 1f             	cmp    $0x1f,%eax
801064c5:	0f 87 bc 00 00 00    	ja     80106587 <trap+0x120>
801064cb:	8b 04 85 e4 86 10 80 	mov    -0x7fef791c(,%eax,4),%eax
801064d2:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801064d4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801064da:	0f b6 00             	movzbl (%eax),%eax
801064dd:	84 c0                	test   %al,%al
801064df:	75 31                	jne    80106512 <trap+0xab>
      acquire(&tickslock);
801064e1:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
801064e8:	e8 f6 e6 ff ff       	call   80104be3 <acquire>
      ticks++;
801064ed:	a1 c0 2b 11 80       	mov    0x80112bc0,%eax
801064f2:	83 c0 01             	add    $0x1,%eax
801064f5:	a3 c0 2b 11 80       	mov    %eax,0x80112bc0
      wakeup(&ticks);
801064fa:	c7 04 24 c0 2b 11 80 	movl   $0x80112bc0,(%esp)
80106501:	e8 d8 e4 ff ff       	call   801049de <wakeup>
      release(&tickslock);
80106506:	c7 04 24 80 23 11 80 	movl   $0x80112380,(%esp)
8010650d:	e8 33 e7 ff ff       	call   80104c45 <release>
    }
    lapiceoi();
80106512:	e8 12 ca ff ff       	call   80102f29 <lapiceoi>
    break;
80106517:	e9 41 01 00 00       	jmp    8010665d <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
8010651c:	e8 10 c2 ff ff       	call   80102731 <ideintr>
    lapiceoi();
80106521:	e8 03 ca ff ff       	call   80102f29 <lapiceoi>
    break;
80106526:	e9 32 01 00 00       	jmp    8010665d <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010652b:	e8 d7 c7 ff ff       	call   80102d07 <kbdintr>
    lapiceoi();
80106530:	e8 f4 c9 ff ff       	call   80102f29 <lapiceoi>
    break;
80106535:	e9 23 01 00 00       	jmp    8010665d <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010653a:	e8 a9 03 00 00       	call   801068e8 <uartintr>
    lapiceoi();
8010653f:	e8 e5 c9 ff ff       	call   80102f29 <lapiceoi>
    break;
80106544:	e9 14 01 00 00       	jmp    8010665d <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106549:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010654c:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
8010654f:	8b 45 08             	mov    0x8(%ebp),%eax
80106552:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106556:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106559:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010655f:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106562:	0f b6 c0             	movzbl %al,%eax
80106565:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106569:	89 54 24 08          	mov    %edx,0x8(%esp)
8010656d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106571:	c7 04 24 44 86 10 80 	movl   $0x80108644,(%esp)
80106578:	e8 24 9e ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
8010657d:	e8 a7 c9 ff ff       	call   80102f29 <lapiceoi>
    break;
80106582:	e9 d6 00 00 00       	jmp    8010665d <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106587:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010658d:	85 c0                	test   %eax,%eax
8010658f:	74 11                	je     801065a2 <trap+0x13b>
80106591:	8b 45 08             	mov    0x8(%ebp),%eax
80106594:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106598:	0f b7 c0             	movzwl %ax,%eax
8010659b:	83 e0 03             	and    $0x3,%eax
8010659e:	85 c0                	test   %eax,%eax
801065a0:	75 46                	jne    801065e8 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801065a2:	e8 1a fd ff ff       	call   801062c1 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
801065a7:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801065aa:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801065ad:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801065b4:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801065b7:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
801065ba:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801065bd:	8b 52 30             	mov    0x30(%edx),%edx
801065c0:	89 44 24 10          	mov    %eax,0x10(%esp)
801065c4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801065c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801065cc:	89 54 24 04          	mov    %edx,0x4(%esp)
801065d0:	c7 04 24 68 86 10 80 	movl   $0x80108668,(%esp)
801065d7:	e8 c5 9d ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801065dc:	c7 04 24 9a 86 10 80 	movl   $0x8010869a,(%esp)
801065e3:	e8 55 9f ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801065e8:	e8 d4 fc ff ff       	call   801062c1 <rcr2>
801065ed:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801065ef:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801065f2:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801065f5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801065fb:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801065fe:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106601:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106604:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106607:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010660a:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010660d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106613:	83 c0 6c             	add    $0x6c,%eax
80106616:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106619:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010661f:	8b 40 10             	mov    0x10(%eax),%eax
80106622:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106626:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010662a:	89 74 24 14          	mov    %esi,0x14(%esp)
8010662e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106632:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106636:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106639:	89 54 24 08          	mov    %edx,0x8(%esp)
8010663d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106641:	c7 04 24 a0 86 10 80 	movl   $0x801086a0,(%esp)
80106648:	e8 54 9d ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010664d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106653:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010665a:	eb 01                	jmp    8010665d <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010665c:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010665d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106663:	85 c0                	test   %eax,%eax
80106665:	74 24                	je     8010668b <trap+0x224>
80106667:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010666d:	8b 40 24             	mov    0x24(%eax),%eax
80106670:	85 c0                	test   %eax,%eax
80106672:	74 17                	je     8010668b <trap+0x224>
80106674:	8b 45 08             	mov    0x8(%ebp),%eax
80106677:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010667b:	0f b7 c0             	movzwl %ax,%eax
8010667e:	83 e0 03             	and    $0x3,%eax
80106681:	83 f8 03             	cmp    $0x3,%eax
80106684:	75 05                	jne    8010668b <trap+0x224>
    exit();
80106686:	e8 0a de ff ff       	call   80104495 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010668b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106691:	85 c0                	test   %eax,%eax
80106693:	74 1e                	je     801066b3 <trap+0x24c>
80106695:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010669b:	8b 40 0c             	mov    0xc(%eax),%eax
8010669e:	83 f8 04             	cmp    $0x4,%eax
801066a1:	75 10                	jne    801066b3 <trap+0x24c>
801066a3:	8b 45 08             	mov    0x8(%ebp),%eax
801066a6:	8b 40 30             	mov    0x30(%eax),%eax
801066a9:	83 f8 20             	cmp    $0x20,%eax
801066ac:	75 05                	jne    801066b3 <trap+0x24c>
    yield();
801066ae:	e8 f4 e1 ff ff       	call   801048a7 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801066b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066b9:	85 c0                	test   %eax,%eax
801066bb:	74 27                	je     801066e4 <trap+0x27d>
801066bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066c3:	8b 40 24             	mov    0x24(%eax),%eax
801066c6:	85 c0                	test   %eax,%eax
801066c8:	74 1a                	je     801066e4 <trap+0x27d>
801066ca:	8b 45 08             	mov    0x8(%ebp),%eax
801066cd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801066d1:	0f b7 c0             	movzwl %ax,%eax
801066d4:	83 e0 03             	and    $0x3,%eax
801066d7:	83 f8 03             	cmp    $0x3,%eax
801066da:	75 08                	jne    801066e4 <trap+0x27d>
    exit();
801066dc:	e8 b4 dd ff ff       	call   80104495 <exit>
801066e1:	eb 01                	jmp    801066e4 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
801066e3:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801066e4:	83 c4 3c             	add    $0x3c,%esp
801066e7:	5b                   	pop    %ebx
801066e8:	5e                   	pop    %esi
801066e9:	5f                   	pop    %edi
801066ea:	5d                   	pop    %ebp
801066eb:	c3                   	ret    

801066ec <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801066ec:	55                   	push   %ebp
801066ed:	89 e5                	mov    %esp,%ebp
801066ef:	53                   	push   %ebx
801066f0:	83 ec 14             	sub    $0x14,%esp
801066f3:	8b 45 08             	mov    0x8(%ebp),%eax
801066f6:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801066fa:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801066fe:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80106702:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80106706:	ec                   	in     (%dx),%al
80106707:	89 c3                	mov    %eax,%ebx
80106709:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
8010670c:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106710:	83 c4 14             	add    $0x14,%esp
80106713:	5b                   	pop    %ebx
80106714:	5d                   	pop    %ebp
80106715:	c3                   	ret    

80106716 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106716:	55                   	push   %ebp
80106717:	89 e5                	mov    %esp,%ebp
80106719:	83 ec 08             	sub    $0x8,%esp
8010671c:	8b 55 08             	mov    0x8(%ebp),%edx
8010671f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106722:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106726:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106729:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010672d:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106731:	ee                   	out    %al,(%dx)
}
80106732:	c9                   	leave  
80106733:	c3                   	ret    

80106734 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106734:	55                   	push   %ebp
80106735:	89 e5                	mov    %esp,%ebp
80106737:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010673a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106741:	00 
80106742:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106749:	e8 c8 ff ff ff       	call   80106716 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010674e:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106755:	00 
80106756:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010675d:	e8 b4 ff ff ff       	call   80106716 <outb>
  outb(COM1+0, 115200/9600);
80106762:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106769:	00 
8010676a:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106771:	e8 a0 ff ff ff       	call   80106716 <outb>
  outb(COM1+1, 0);
80106776:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010677d:	00 
8010677e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106785:	e8 8c ff ff ff       	call   80106716 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010678a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106791:	00 
80106792:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106799:	e8 78 ff ff ff       	call   80106716 <outb>
  outb(COM1+4, 0);
8010679e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067a5:	00 
801067a6:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801067ad:	e8 64 ff ff ff       	call   80106716 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801067b2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801067b9:	00 
801067ba:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801067c1:	e8 50 ff ff ff       	call   80106716 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801067c6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801067cd:	e8 1a ff ff ff       	call   801066ec <inb>
801067d2:	3c ff                	cmp    $0xff,%al
801067d4:	74 6c                	je     80106842 <uartinit+0x10e>
    return;
  uart = 1;
801067d6:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
801067dd:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801067e0:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801067e7:	e8 00 ff ff ff       	call   801066ec <inb>
  inb(COM1+0);
801067ec:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801067f3:	e8 f4 fe ff ff       	call   801066ec <inb>
  picenable(IRQ_COM1);
801067f8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801067ff:	e8 fd d2 ff ff       	call   80103b01 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106804:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010680b:	00 
8010680c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106813:	e8 9e c1 ff ff       	call   801029b6 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106818:	c7 45 f4 64 87 10 80 	movl   $0x80108764,-0xc(%ebp)
8010681f:	eb 15                	jmp    80106836 <uartinit+0x102>
    uartputc(*p);
80106821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106824:	0f b6 00             	movzbl (%eax),%eax
80106827:	0f be c0             	movsbl %al,%eax
8010682a:	89 04 24             	mov    %eax,(%esp)
8010682d:	e8 13 00 00 00       	call   80106845 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106832:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106836:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106839:	0f b6 00             	movzbl (%eax),%eax
8010683c:	84 c0                	test   %al,%al
8010683e:	75 e1                	jne    80106821 <uartinit+0xed>
80106840:	eb 01                	jmp    80106843 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106842:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106843:	c9                   	leave  
80106844:	c3                   	ret    

80106845 <uartputc>:

void
uartputc(int c)
{
80106845:	55                   	push   %ebp
80106846:	89 e5                	mov    %esp,%ebp
80106848:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010684b:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106850:	85 c0                	test   %eax,%eax
80106852:	74 4d                	je     801068a1 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106854:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010685b:	eb 10                	jmp    8010686d <uartputc+0x28>
    microdelay(10);
8010685d:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106864:	e8 e5 c6 ff ff       	call   80102f4e <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106869:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010686d:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106871:	7f 16                	jg     80106889 <uartputc+0x44>
80106873:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010687a:	e8 6d fe ff ff       	call   801066ec <inb>
8010687f:	0f b6 c0             	movzbl %al,%eax
80106882:	83 e0 20             	and    $0x20,%eax
80106885:	85 c0                	test   %eax,%eax
80106887:	74 d4                	je     8010685d <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106889:	8b 45 08             	mov    0x8(%ebp),%eax
8010688c:	0f b6 c0             	movzbl %al,%eax
8010688f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106893:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010689a:	e8 77 fe ff ff       	call   80106716 <outb>
8010689f:	eb 01                	jmp    801068a2 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
801068a1:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
801068a2:	c9                   	leave  
801068a3:	c3                   	ret    

801068a4 <uartgetc>:

static int
uartgetc(void)
{
801068a4:	55                   	push   %ebp
801068a5:	89 e5                	mov    %esp,%ebp
801068a7:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801068aa:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
801068af:	85 c0                	test   %eax,%eax
801068b1:	75 07                	jne    801068ba <uartgetc+0x16>
    return -1;
801068b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068b8:	eb 2c                	jmp    801068e6 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801068ba:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801068c1:	e8 26 fe ff ff       	call   801066ec <inb>
801068c6:	0f b6 c0             	movzbl %al,%eax
801068c9:	83 e0 01             	and    $0x1,%eax
801068cc:	85 c0                	test   %eax,%eax
801068ce:	75 07                	jne    801068d7 <uartgetc+0x33>
    return -1;
801068d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068d5:	eb 0f                	jmp    801068e6 <uartgetc+0x42>
  return inb(COM1+0);
801068d7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801068de:	e8 09 fe ff ff       	call   801066ec <inb>
801068e3:	0f b6 c0             	movzbl %al,%eax
}
801068e6:	c9                   	leave  
801068e7:	c3                   	ret    

801068e8 <uartintr>:

void
uartintr(void)
{
801068e8:	55                   	push   %ebp
801068e9:	89 e5                	mov    %esp,%ebp
801068eb:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801068ee:	c7 04 24 a4 68 10 80 	movl   $0x801068a4,(%esp)
801068f5:	e8 b3 9e ff ff       	call   801007ad <consoleintr>
}
801068fa:	c9                   	leave  
801068fb:	c3                   	ret    

801068fc <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801068fc:	6a 00                	push   $0x0
  pushl $0
801068fe:	6a 00                	push   $0x0
  jmp alltraps
80106900:	e9 67 f9 ff ff       	jmp    8010626c <alltraps>

80106905 <vector1>:
.globl vector1
vector1:
  pushl $0
80106905:	6a 00                	push   $0x0
  pushl $1
80106907:	6a 01                	push   $0x1
  jmp alltraps
80106909:	e9 5e f9 ff ff       	jmp    8010626c <alltraps>

8010690e <vector2>:
.globl vector2
vector2:
  pushl $0
8010690e:	6a 00                	push   $0x0
  pushl $2
80106910:	6a 02                	push   $0x2
  jmp alltraps
80106912:	e9 55 f9 ff ff       	jmp    8010626c <alltraps>

80106917 <vector3>:
.globl vector3
vector3:
  pushl $0
80106917:	6a 00                	push   $0x0
  pushl $3
80106919:	6a 03                	push   $0x3
  jmp alltraps
8010691b:	e9 4c f9 ff ff       	jmp    8010626c <alltraps>

80106920 <vector4>:
.globl vector4
vector4:
  pushl $0
80106920:	6a 00                	push   $0x0
  pushl $4
80106922:	6a 04                	push   $0x4
  jmp alltraps
80106924:	e9 43 f9 ff ff       	jmp    8010626c <alltraps>

80106929 <vector5>:
.globl vector5
vector5:
  pushl $0
80106929:	6a 00                	push   $0x0
  pushl $5
8010692b:	6a 05                	push   $0x5
  jmp alltraps
8010692d:	e9 3a f9 ff ff       	jmp    8010626c <alltraps>

80106932 <vector6>:
.globl vector6
vector6:
  pushl $0
80106932:	6a 00                	push   $0x0
  pushl $6
80106934:	6a 06                	push   $0x6
  jmp alltraps
80106936:	e9 31 f9 ff ff       	jmp    8010626c <alltraps>

8010693b <vector7>:
.globl vector7
vector7:
  pushl $0
8010693b:	6a 00                	push   $0x0
  pushl $7
8010693d:	6a 07                	push   $0x7
  jmp alltraps
8010693f:	e9 28 f9 ff ff       	jmp    8010626c <alltraps>

80106944 <vector8>:
.globl vector8
vector8:
  pushl $8
80106944:	6a 08                	push   $0x8
  jmp alltraps
80106946:	e9 21 f9 ff ff       	jmp    8010626c <alltraps>

8010694b <vector9>:
.globl vector9
vector9:
  pushl $0
8010694b:	6a 00                	push   $0x0
  pushl $9
8010694d:	6a 09                	push   $0x9
  jmp alltraps
8010694f:	e9 18 f9 ff ff       	jmp    8010626c <alltraps>

80106954 <vector10>:
.globl vector10
vector10:
  pushl $10
80106954:	6a 0a                	push   $0xa
  jmp alltraps
80106956:	e9 11 f9 ff ff       	jmp    8010626c <alltraps>

8010695b <vector11>:
.globl vector11
vector11:
  pushl $11
8010695b:	6a 0b                	push   $0xb
  jmp alltraps
8010695d:	e9 0a f9 ff ff       	jmp    8010626c <alltraps>

80106962 <vector12>:
.globl vector12
vector12:
  pushl $12
80106962:	6a 0c                	push   $0xc
  jmp alltraps
80106964:	e9 03 f9 ff ff       	jmp    8010626c <alltraps>

80106969 <vector13>:
.globl vector13
vector13:
  pushl $13
80106969:	6a 0d                	push   $0xd
  jmp alltraps
8010696b:	e9 fc f8 ff ff       	jmp    8010626c <alltraps>

80106970 <vector14>:
.globl vector14
vector14:
  pushl $14
80106970:	6a 0e                	push   $0xe
  jmp alltraps
80106972:	e9 f5 f8 ff ff       	jmp    8010626c <alltraps>

80106977 <vector15>:
.globl vector15
vector15:
  pushl $0
80106977:	6a 00                	push   $0x0
  pushl $15
80106979:	6a 0f                	push   $0xf
  jmp alltraps
8010697b:	e9 ec f8 ff ff       	jmp    8010626c <alltraps>

80106980 <vector16>:
.globl vector16
vector16:
  pushl $0
80106980:	6a 00                	push   $0x0
  pushl $16
80106982:	6a 10                	push   $0x10
  jmp alltraps
80106984:	e9 e3 f8 ff ff       	jmp    8010626c <alltraps>

80106989 <vector17>:
.globl vector17
vector17:
  pushl $17
80106989:	6a 11                	push   $0x11
  jmp alltraps
8010698b:	e9 dc f8 ff ff       	jmp    8010626c <alltraps>

80106990 <vector18>:
.globl vector18
vector18:
  pushl $0
80106990:	6a 00                	push   $0x0
  pushl $18
80106992:	6a 12                	push   $0x12
  jmp alltraps
80106994:	e9 d3 f8 ff ff       	jmp    8010626c <alltraps>

80106999 <vector19>:
.globl vector19
vector19:
  pushl $0
80106999:	6a 00                	push   $0x0
  pushl $19
8010699b:	6a 13                	push   $0x13
  jmp alltraps
8010699d:	e9 ca f8 ff ff       	jmp    8010626c <alltraps>

801069a2 <vector20>:
.globl vector20
vector20:
  pushl $0
801069a2:	6a 00                	push   $0x0
  pushl $20
801069a4:	6a 14                	push   $0x14
  jmp alltraps
801069a6:	e9 c1 f8 ff ff       	jmp    8010626c <alltraps>

801069ab <vector21>:
.globl vector21
vector21:
  pushl $0
801069ab:	6a 00                	push   $0x0
  pushl $21
801069ad:	6a 15                	push   $0x15
  jmp alltraps
801069af:	e9 b8 f8 ff ff       	jmp    8010626c <alltraps>

801069b4 <vector22>:
.globl vector22
vector22:
  pushl $0
801069b4:	6a 00                	push   $0x0
  pushl $22
801069b6:	6a 16                	push   $0x16
  jmp alltraps
801069b8:	e9 af f8 ff ff       	jmp    8010626c <alltraps>

801069bd <vector23>:
.globl vector23
vector23:
  pushl $0
801069bd:	6a 00                	push   $0x0
  pushl $23
801069bf:	6a 17                	push   $0x17
  jmp alltraps
801069c1:	e9 a6 f8 ff ff       	jmp    8010626c <alltraps>

801069c6 <vector24>:
.globl vector24
vector24:
  pushl $0
801069c6:	6a 00                	push   $0x0
  pushl $24
801069c8:	6a 18                	push   $0x18
  jmp alltraps
801069ca:	e9 9d f8 ff ff       	jmp    8010626c <alltraps>

801069cf <vector25>:
.globl vector25
vector25:
  pushl $0
801069cf:	6a 00                	push   $0x0
  pushl $25
801069d1:	6a 19                	push   $0x19
  jmp alltraps
801069d3:	e9 94 f8 ff ff       	jmp    8010626c <alltraps>

801069d8 <vector26>:
.globl vector26
vector26:
  pushl $0
801069d8:	6a 00                	push   $0x0
  pushl $26
801069da:	6a 1a                	push   $0x1a
  jmp alltraps
801069dc:	e9 8b f8 ff ff       	jmp    8010626c <alltraps>

801069e1 <vector27>:
.globl vector27
vector27:
  pushl $0
801069e1:	6a 00                	push   $0x0
  pushl $27
801069e3:	6a 1b                	push   $0x1b
  jmp alltraps
801069e5:	e9 82 f8 ff ff       	jmp    8010626c <alltraps>

801069ea <vector28>:
.globl vector28
vector28:
  pushl $0
801069ea:	6a 00                	push   $0x0
  pushl $28
801069ec:	6a 1c                	push   $0x1c
  jmp alltraps
801069ee:	e9 79 f8 ff ff       	jmp    8010626c <alltraps>

801069f3 <vector29>:
.globl vector29
vector29:
  pushl $0
801069f3:	6a 00                	push   $0x0
  pushl $29
801069f5:	6a 1d                	push   $0x1d
  jmp alltraps
801069f7:	e9 70 f8 ff ff       	jmp    8010626c <alltraps>

801069fc <vector30>:
.globl vector30
vector30:
  pushl $0
801069fc:	6a 00                	push   $0x0
  pushl $30
801069fe:	6a 1e                	push   $0x1e
  jmp alltraps
80106a00:	e9 67 f8 ff ff       	jmp    8010626c <alltraps>

80106a05 <vector31>:
.globl vector31
vector31:
  pushl $0
80106a05:	6a 00                	push   $0x0
  pushl $31
80106a07:	6a 1f                	push   $0x1f
  jmp alltraps
80106a09:	e9 5e f8 ff ff       	jmp    8010626c <alltraps>

80106a0e <vector32>:
.globl vector32
vector32:
  pushl $0
80106a0e:	6a 00                	push   $0x0
  pushl $32
80106a10:	6a 20                	push   $0x20
  jmp alltraps
80106a12:	e9 55 f8 ff ff       	jmp    8010626c <alltraps>

80106a17 <vector33>:
.globl vector33
vector33:
  pushl $0
80106a17:	6a 00                	push   $0x0
  pushl $33
80106a19:	6a 21                	push   $0x21
  jmp alltraps
80106a1b:	e9 4c f8 ff ff       	jmp    8010626c <alltraps>

80106a20 <vector34>:
.globl vector34
vector34:
  pushl $0
80106a20:	6a 00                	push   $0x0
  pushl $34
80106a22:	6a 22                	push   $0x22
  jmp alltraps
80106a24:	e9 43 f8 ff ff       	jmp    8010626c <alltraps>

80106a29 <vector35>:
.globl vector35
vector35:
  pushl $0
80106a29:	6a 00                	push   $0x0
  pushl $35
80106a2b:	6a 23                	push   $0x23
  jmp alltraps
80106a2d:	e9 3a f8 ff ff       	jmp    8010626c <alltraps>

80106a32 <vector36>:
.globl vector36
vector36:
  pushl $0
80106a32:	6a 00                	push   $0x0
  pushl $36
80106a34:	6a 24                	push   $0x24
  jmp alltraps
80106a36:	e9 31 f8 ff ff       	jmp    8010626c <alltraps>

80106a3b <vector37>:
.globl vector37
vector37:
  pushl $0
80106a3b:	6a 00                	push   $0x0
  pushl $37
80106a3d:	6a 25                	push   $0x25
  jmp alltraps
80106a3f:	e9 28 f8 ff ff       	jmp    8010626c <alltraps>

80106a44 <vector38>:
.globl vector38
vector38:
  pushl $0
80106a44:	6a 00                	push   $0x0
  pushl $38
80106a46:	6a 26                	push   $0x26
  jmp alltraps
80106a48:	e9 1f f8 ff ff       	jmp    8010626c <alltraps>

80106a4d <vector39>:
.globl vector39
vector39:
  pushl $0
80106a4d:	6a 00                	push   $0x0
  pushl $39
80106a4f:	6a 27                	push   $0x27
  jmp alltraps
80106a51:	e9 16 f8 ff ff       	jmp    8010626c <alltraps>

80106a56 <vector40>:
.globl vector40
vector40:
  pushl $0
80106a56:	6a 00                	push   $0x0
  pushl $40
80106a58:	6a 28                	push   $0x28
  jmp alltraps
80106a5a:	e9 0d f8 ff ff       	jmp    8010626c <alltraps>

80106a5f <vector41>:
.globl vector41
vector41:
  pushl $0
80106a5f:	6a 00                	push   $0x0
  pushl $41
80106a61:	6a 29                	push   $0x29
  jmp alltraps
80106a63:	e9 04 f8 ff ff       	jmp    8010626c <alltraps>

80106a68 <vector42>:
.globl vector42
vector42:
  pushl $0
80106a68:	6a 00                	push   $0x0
  pushl $42
80106a6a:	6a 2a                	push   $0x2a
  jmp alltraps
80106a6c:	e9 fb f7 ff ff       	jmp    8010626c <alltraps>

80106a71 <vector43>:
.globl vector43
vector43:
  pushl $0
80106a71:	6a 00                	push   $0x0
  pushl $43
80106a73:	6a 2b                	push   $0x2b
  jmp alltraps
80106a75:	e9 f2 f7 ff ff       	jmp    8010626c <alltraps>

80106a7a <vector44>:
.globl vector44
vector44:
  pushl $0
80106a7a:	6a 00                	push   $0x0
  pushl $44
80106a7c:	6a 2c                	push   $0x2c
  jmp alltraps
80106a7e:	e9 e9 f7 ff ff       	jmp    8010626c <alltraps>

80106a83 <vector45>:
.globl vector45
vector45:
  pushl $0
80106a83:	6a 00                	push   $0x0
  pushl $45
80106a85:	6a 2d                	push   $0x2d
  jmp alltraps
80106a87:	e9 e0 f7 ff ff       	jmp    8010626c <alltraps>

80106a8c <vector46>:
.globl vector46
vector46:
  pushl $0
80106a8c:	6a 00                	push   $0x0
  pushl $46
80106a8e:	6a 2e                	push   $0x2e
  jmp alltraps
80106a90:	e9 d7 f7 ff ff       	jmp    8010626c <alltraps>

80106a95 <vector47>:
.globl vector47
vector47:
  pushl $0
80106a95:	6a 00                	push   $0x0
  pushl $47
80106a97:	6a 2f                	push   $0x2f
  jmp alltraps
80106a99:	e9 ce f7 ff ff       	jmp    8010626c <alltraps>

80106a9e <vector48>:
.globl vector48
vector48:
  pushl $0
80106a9e:	6a 00                	push   $0x0
  pushl $48
80106aa0:	6a 30                	push   $0x30
  jmp alltraps
80106aa2:	e9 c5 f7 ff ff       	jmp    8010626c <alltraps>

80106aa7 <vector49>:
.globl vector49
vector49:
  pushl $0
80106aa7:	6a 00                	push   $0x0
  pushl $49
80106aa9:	6a 31                	push   $0x31
  jmp alltraps
80106aab:	e9 bc f7 ff ff       	jmp    8010626c <alltraps>

80106ab0 <vector50>:
.globl vector50
vector50:
  pushl $0
80106ab0:	6a 00                	push   $0x0
  pushl $50
80106ab2:	6a 32                	push   $0x32
  jmp alltraps
80106ab4:	e9 b3 f7 ff ff       	jmp    8010626c <alltraps>

80106ab9 <vector51>:
.globl vector51
vector51:
  pushl $0
80106ab9:	6a 00                	push   $0x0
  pushl $51
80106abb:	6a 33                	push   $0x33
  jmp alltraps
80106abd:	e9 aa f7 ff ff       	jmp    8010626c <alltraps>

80106ac2 <vector52>:
.globl vector52
vector52:
  pushl $0
80106ac2:	6a 00                	push   $0x0
  pushl $52
80106ac4:	6a 34                	push   $0x34
  jmp alltraps
80106ac6:	e9 a1 f7 ff ff       	jmp    8010626c <alltraps>

80106acb <vector53>:
.globl vector53
vector53:
  pushl $0
80106acb:	6a 00                	push   $0x0
  pushl $53
80106acd:	6a 35                	push   $0x35
  jmp alltraps
80106acf:	e9 98 f7 ff ff       	jmp    8010626c <alltraps>

80106ad4 <vector54>:
.globl vector54
vector54:
  pushl $0
80106ad4:	6a 00                	push   $0x0
  pushl $54
80106ad6:	6a 36                	push   $0x36
  jmp alltraps
80106ad8:	e9 8f f7 ff ff       	jmp    8010626c <alltraps>

80106add <vector55>:
.globl vector55
vector55:
  pushl $0
80106add:	6a 00                	push   $0x0
  pushl $55
80106adf:	6a 37                	push   $0x37
  jmp alltraps
80106ae1:	e9 86 f7 ff ff       	jmp    8010626c <alltraps>

80106ae6 <vector56>:
.globl vector56
vector56:
  pushl $0
80106ae6:	6a 00                	push   $0x0
  pushl $56
80106ae8:	6a 38                	push   $0x38
  jmp alltraps
80106aea:	e9 7d f7 ff ff       	jmp    8010626c <alltraps>

80106aef <vector57>:
.globl vector57
vector57:
  pushl $0
80106aef:	6a 00                	push   $0x0
  pushl $57
80106af1:	6a 39                	push   $0x39
  jmp alltraps
80106af3:	e9 74 f7 ff ff       	jmp    8010626c <alltraps>

80106af8 <vector58>:
.globl vector58
vector58:
  pushl $0
80106af8:	6a 00                	push   $0x0
  pushl $58
80106afa:	6a 3a                	push   $0x3a
  jmp alltraps
80106afc:	e9 6b f7 ff ff       	jmp    8010626c <alltraps>

80106b01 <vector59>:
.globl vector59
vector59:
  pushl $0
80106b01:	6a 00                	push   $0x0
  pushl $59
80106b03:	6a 3b                	push   $0x3b
  jmp alltraps
80106b05:	e9 62 f7 ff ff       	jmp    8010626c <alltraps>

80106b0a <vector60>:
.globl vector60
vector60:
  pushl $0
80106b0a:	6a 00                	push   $0x0
  pushl $60
80106b0c:	6a 3c                	push   $0x3c
  jmp alltraps
80106b0e:	e9 59 f7 ff ff       	jmp    8010626c <alltraps>

80106b13 <vector61>:
.globl vector61
vector61:
  pushl $0
80106b13:	6a 00                	push   $0x0
  pushl $61
80106b15:	6a 3d                	push   $0x3d
  jmp alltraps
80106b17:	e9 50 f7 ff ff       	jmp    8010626c <alltraps>

80106b1c <vector62>:
.globl vector62
vector62:
  pushl $0
80106b1c:	6a 00                	push   $0x0
  pushl $62
80106b1e:	6a 3e                	push   $0x3e
  jmp alltraps
80106b20:	e9 47 f7 ff ff       	jmp    8010626c <alltraps>

80106b25 <vector63>:
.globl vector63
vector63:
  pushl $0
80106b25:	6a 00                	push   $0x0
  pushl $63
80106b27:	6a 3f                	push   $0x3f
  jmp alltraps
80106b29:	e9 3e f7 ff ff       	jmp    8010626c <alltraps>

80106b2e <vector64>:
.globl vector64
vector64:
  pushl $0
80106b2e:	6a 00                	push   $0x0
  pushl $64
80106b30:	6a 40                	push   $0x40
  jmp alltraps
80106b32:	e9 35 f7 ff ff       	jmp    8010626c <alltraps>

80106b37 <vector65>:
.globl vector65
vector65:
  pushl $0
80106b37:	6a 00                	push   $0x0
  pushl $65
80106b39:	6a 41                	push   $0x41
  jmp alltraps
80106b3b:	e9 2c f7 ff ff       	jmp    8010626c <alltraps>

80106b40 <vector66>:
.globl vector66
vector66:
  pushl $0
80106b40:	6a 00                	push   $0x0
  pushl $66
80106b42:	6a 42                	push   $0x42
  jmp alltraps
80106b44:	e9 23 f7 ff ff       	jmp    8010626c <alltraps>

80106b49 <vector67>:
.globl vector67
vector67:
  pushl $0
80106b49:	6a 00                	push   $0x0
  pushl $67
80106b4b:	6a 43                	push   $0x43
  jmp alltraps
80106b4d:	e9 1a f7 ff ff       	jmp    8010626c <alltraps>

80106b52 <vector68>:
.globl vector68
vector68:
  pushl $0
80106b52:	6a 00                	push   $0x0
  pushl $68
80106b54:	6a 44                	push   $0x44
  jmp alltraps
80106b56:	e9 11 f7 ff ff       	jmp    8010626c <alltraps>

80106b5b <vector69>:
.globl vector69
vector69:
  pushl $0
80106b5b:	6a 00                	push   $0x0
  pushl $69
80106b5d:	6a 45                	push   $0x45
  jmp alltraps
80106b5f:	e9 08 f7 ff ff       	jmp    8010626c <alltraps>

80106b64 <vector70>:
.globl vector70
vector70:
  pushl $0
80106b64:	6a 00                	push   $0x0
  pushl $70
80106b66:	6a 46                	push   $0x46
  jmp alltraps
80106b68:	e9 ff f6 ff ff       	jmp    8010626c <alltraps>

80106b6d <vector71>:
.globl vector71
vector71:
  pushl $0
80106b6d:	6a 00                	push   $0x0
  pushl $71
80106b6f:	6a 47                	push   $0x47
  jmp alltraps
80106b71:	e9 f6 f6 ff ff       	jmp    8010626c <alltraps>

80106b76 <vector72>:
.globl vector72
vector72:
  pushl $0
80106b76:	6a 00                	push   $0x0
  pushl $72
80106b78:	6a 48                	push   $0x48
  jmp alltraps
80106b7a:	e9 ed f6 ff ff       	jmp    8010626c <alltraps>

80106b7f <vector73>:
.globl vector73
vector73:
  pushl $0
80106b7f:	6a 00                	push   $0x0
  pushl $73
80106b81:	6a 49                	push   $0x49
  jmp alltraps
80106b83:	e9 e4 f6 ff ff       	jmp    8010626c <alltraps>

80106b88 <vector74>:
.globl vector74
vector74:
  pushl $0
80106b88:	6a 00                	push   $0x0
  pushl $74
80106b8a:	6a 4a                	push   $0x4a
  jmp alltraps
80106b8c:	e9 db f6 ff ff       	jmp    8010626c <alltraps>

80106b91 <vector75>:
.globl vector75
vector75:
  pushl $0
80106b91:	6a 00                	push   $0x0
  pushl $75
80106b93:	6a 4b                	push   $0x4b
  jmp alltraps
80106b95:	e9 d2 f6 ff ff       	jmp    8010626c <alltraps>

80106b9a <vector76>:
.globl vector76
vector76:
  pushl $0
80106b9a:	6a 00                	push   $0x0
  pushl $76
80106b9c:	6a 4c                	push   $0x4c
  jmp alltraps
80106b9e:	e9 c9 f6 ff ff       	jmp    8010626c <alltraps>

80106ba3 <vector77>:
.globl vector77
vector77:
  pushl $0
80106ba3:	6a 00                	push   $0x0
  pushl $77
80106ba5:	6a 4d                	push   $0x4d
  jmp alltraps
80106ba7:	e9 c0 f6 ff ff       	jmp    8010626c <alltraps>

80106bac <vector78>:
.globl vector78
vector78:
  pushl $0
80106bac:	6a 00                	push   $0x0
  pushl $78
80106bae:	6a 4e                	push   $0x4e
  jmp alltraps
80106bb0:	e9 b7 f6 ff ff       	jmp    8010626c <alltraps>

80106bb5 <vector79>:
.globl vector79
vector79:
  pushl $0
80106bb5:	6a 00                	push   $0x0
  pushl $79
80106bb7:	6a 4f                	push   $0x4f
  jmp alltraps
80106bb9:	e9 ae f6 ff ff       	jmp    8010626c <alltraps>

80106bbe <vector80>:
.globl vector80
vector80:
  pushl $0
80106bbe:	6a 00                	push   $0x0
  pushl $80
80106bc0:	6a 50                	push   $0x50
  jmp alltraps
80106bc2:	e9 a5 f6 ff ff       	jmp    8010626c <alltraps>

80106bc7 <vector81>:
.globl vector81
vector81:
  pushl $0
80106bc7:	6a 00                	push   $0x0
  pushl $81
80106bc9:	6a 51                	push   $0x51
  jmp alltraps
80106bcb:	e9 9c f6 ff ff       	jmp    8010626c <alltraps>

80106bd0 <vector82>:
.globl vector82
vector82:
  pushl $0
80106bd0:	6a 00                	push   $0x0
  pushl $82
80106bd2:	6a 52                	push   $0x52
  jmp alltraps
80106bd4:	e9 93 f6 ff ff       	jmp    8010626c <alltraps>

80106bd9 <vector83>:
.globl vector83
vector83:
  pushl $0
80106bd9:	6a 00                	push   $0x0
  pushl $83
80106bdb:	6a 53                	push   $0x53
  jmp alltraps
80106bdd:	e9 8a f6 ff ff       	jmp    8010626c <alltraps>

80106be2 <vector84>:
.globl vector84
vector84:
  pushl $0
80106be2:	6a 00                	push   $0x0
  pushl $84
80106be4:	6a 54                	push   $0x54
  jmp alltraps
80106be6:	e9 81 f6 ff ff       	jmp    8010626c <alltraps>

80106beb <vector85>:
.globl vector85
vector85:
  pushl $0
80106beb:	6a 00                	push   $0x0
  pushl $85
80106bed:	6a 55                	push   $0x55
  jmp alltraps
80106bef:	e9 78 f6 ff ff       	jmp    8010626c <alltraps>

80106bf4 <vector86>:
.globl vector86
vector86:
  pushl $0
80106bf4:	6a 00                	push   $0x0
  pushl $86
80106bf6:	6a 56                	push   $0x56
  jmp alltraps
80106bf8:	e9 6f f6 ff ff       	jmp    8010626c <alltraps>

80106bfd <vector87>:
.globl vector87
vector87:
  pushl $0
80106bfd:	6a 00                	push   $0x0
  pushl $87
80106bff:	6a 57                	push   $0x57
  jmp alltraps
80106c01:	e9 66 f6 ff ff       	jmp    8010626c <alltraps>

80106c06 <vector88>:
.globl vector88
vector88:
  pushl $0
80106c06:	6a 00                	push   $0x0
  pushl $88
80106c08:	6a 58                	push   $0x58
  jmp alltraps
80106c0a:	e9 5d f6 ff ff       	jmp    8010626c <alltraps>

80106c0f <vector89>:
.globl vector89
vector89:
  pushl $0
80106c0f:	6a 00                	push   $0x0
  pushl $89
80106c11:	6a 59                	push   $0x59
  jmp alltraps
80106c13:	e9 54 f6 ff ff       	jmp    8010626c <alltraps>

80106c18 <vector90>:
.globl vector90
vector90:
  pushl $0
80106c18:	6a 00                	push   $0x0
  pushl $90
80106c1a:	6a 5a                	push   $0x5a
  jmp alltraps
80106c1c:	e9 4b f6 ff ff       	jmp    8010626c <alltraps>

80106c21 <vector91>:
.globl vector91
vector91:
  pushl $0
80106c21:	6a 00                	push   $0x0
  pushl $91
80106c23:	6a 5b                	push   $0x5b
  jmp alltraps
80106c25:	e9 42 f6 ff ff       	jmp    8010626c <alltraps>

80106c2a <vector92>:
.globl vector92
vector92:
  pushl $0
80106c2a:	6a 00                	push   $0x0
  pushl $92
80106c2c:	6a 5c                	push   $0x5c
  jmp alltraps
80106c2e:	e9 39 f6 ff ff       	jmp    8010626c <alltraps>

80106c33 <vector93>:
.globl vector93
vector93:
  pushl $0
80106c33:	6a 00                	push   $0x0
  pushl $93
80106c35:	6a 5d                	push   $0x5d
  jmp alltraps
80106c37:	e9 30 f6 ff ff       	jmp    8010626c <alltraps>

80106c3c <vector94>:
.globl vector94
vector94:
  pushl $0
80106c3c:	6a 00                	push   $0x0
  pushl $94
80106c3e:	6a 5e                	push   $0x5e
  jmp alltraps
80106c40:	e9 27 f6 ff ff       	jmp    8010626c <alltraps>

80106c45 <vector95>:
.globl vector95
vector95:
  pushl $0
80106c45:	6a 00                	push   $0x0
  pushl $95
80106c47:	6a 5f                	push   $0x5f
  jmp alltraps
80106c49:	e9 1e f6 ff ff       	jmp    8010626c <alltraps>

80106c4e <vector96>:
.globl vector96
vector96:
  pushl $0
80106c4e:	6a 00                	push   $0x0
  pushl $96
80106c50:	6a 60                	push   $0x60
  jmp alltraps
80106c52:	e9 15 f6 ff ff       	jmp    8010626c <alltraps>

80106c57 <vector97>:
.globl vector97
vector97:
  pushl $0
80106c57:	6a 00                	push   $0x0
  pushl $97
80106c59:	6a 61                	push   $0x61
  jmp alltraps
80106c5b:	e9 0c f6 ff ff       	jmp    8010626c <alltraps>

80106c60 <vector98>:
.globl vector98
vector98:
  pushl $0
80106c60:	6a 00                	push   $0x0
  pushl $98
80106c62:	6a 62                	push   $0x62
  jmp alltraps
80106c64:	e9 03 f6 ff ff       	jmp    8010626c <alltraps>

80106c69 <vector99>:
.globl vector99
vector99:
  pushl $0
80106c69:	6a 00                	push   $0x0
  pushl $99
80106c6b:	6a 63                	push   $0x63
  jmp alltraps
80106c6d:	e9 fa f5 ff ff       	jmp    8010626c <alltraps>

80106c72 <vector100>:
.globl vector100
vector100:
  pushl $0
80106c72:	6a 00                	push   $0x0
  pushl $100
80106c74:	6a 64                	push   $0x64
  jmp alltraps
80106c76:	e9 f1 f5 ff ff       	jmp    8010626c <alltraps>

80106c7b <vector101>:
.globl vector101
vector101:
  pushl $0
80106c7b:	6a 00                	push   $0x0
  pushl $101
80106c7d:	6a 65                	push   $0x65
  jmp alltraps
80106c7f:	e9 e8 f5 ff ff       	jmp    8010626c <alltraps>

80106c84 <vector102>:
.globl vector102
vector102:
  pushl $0
80106c84:	6a 00                	push   $0x0
  pushl $102
80106c86:	6a 66                	push   $0x66
  jmp alltraps
80106c88:	e9 df f5 ff ff       	jmp    8010626c <alltraps>

80106c8d <vector103>:
.globl vector103
vector103:
  pushl $0
80106c8d:	6a 00                	push   $0x0
  pushl $103
80106c8f:	6a 67                	push   $0x67
  jmp alltraps
80106c91:	e9 d6 f5 ff ff       	jmp    8010626c <alltraps>

80106c96 <vector104>:
.globl vector104
vector104:
  pushl $0
80106c96:	6a 00                	push   $0x0
  pushl $104
80106c98:	6a 68                	push   $0x68
  jmp alltraps
80106c9a:	e9 cd f5 ff ff       	jmp    8010626c <alltraps>

80106c9f <vector105>:
.globl vector105
vector105:
  pushl $0
80106c9f:	6a 00                	push   $0x0
  pushl $105
80106ca1:	6a 69                	push   $0x69
  jmp alltraps
80106ca3:	e9 c4 f5 ff ff       	jmp    8010626c <alltraps>

80106ca8 <vector106>:
.globl vector106
vector106:
  pushl $0
80106ca8:	6a 00                	push   $0x0
  pushl $106
80106caa:	6a 6a                	push   $0x6a
  jmp alltraps
80106cac:	e9 bb f5 ff ff       	jmp    8010626c <alltraps>

80106cb1 <vector107>:
.globl vector107
vector107:
  pushl $0
80106cb1:	6a 00                	push   $0x0
  pushl $107
80106cb3:	6a 6b                	push   $0x6b
  jmp alltraps
80106cb5:	e9 b2 f5 ff ff       	jmp    8010626c <alltraps>

80106cba <vector108>:
.globl vector108
vector108:
  pushl $0
80106cba:	6a 00                	push   $0x0
  pushl $108
80106cbc:	6a 6c                	push   $0x6c
  jmp alltraps
80106cbe:	e9 a9 f5 ff ff       	jmp    8010626c <alltraps>

80106cc3 <vector109>:
.globl vector109
vector109:
  pushl $0
80106cc3:	6a 00                	push   $0x0
  pushl $109
80106cc5:	6a 6d                	push   $0x6d
  jmp alltraps
80106cc7:	e9 a0 f5 ff ff       	jmp    8010626c <alltraps>

80106ccc <vector110>:
.globl vector110
vector110:
  pushl $0
80106ccc:	6a 00                	push   $0x0
  pushl $110
80106cce:	6a 6e                	push   $0x6e
  jmp alltraps
80106cd0:	e9 97 f5 ff ff       	jmp    8010626c <alltraps>

80106cd5 <vector111>:
.globl vector111
vector111:
  pushl $0
80106cd5:	6a 00                	push   $0x0
  pushl $111
80106cd7:	6a 6f                	push   $0x6f
  jmp alltraps
80106cd9:	e9 8e f5 ff ff       	jmp    8010626c <alltraps>

80106cde <vector112>:
.globl vector112
vector112:
  pushl $0
80106cde:	6a 00                	push   $0x0
  pushl $112
80106ce0:	6a 70                	push   $0x70
  jmp alltraps
80106ce2:	e9 85 f5 ff ff       	jmp    8010626c <alltraps>

80106ce7 <vector113>:
.globl vector113
vector113:
  pushl $0
80106ce7:	6a 00                	push   $0x0
  pushl $113
80106ce9:	6a 71                	push   $0x71
  jmp alltraps
80106ceb:	e9 7c f5 ff ff       	jmp    8010626c <alltraps>

80106cf0 <vector114>:
.globl vector114
vector114:
  pushl $0
80106cf0:	6a 00                	push   $0x0
  pushl $114
80106cf2:	6a 72                	push   $0x72
  jmp alltraps
80106cf4:	e9 73 f5 ff ff       	jmp    8010626c <alltraps>

80106cf9 <vector115>:
.globl vector115
vector115:
  pushl $0
80106cf9:	6a 00                	push   $0x0
  pushl $115
80106cfb:	6a 73                	push   $0x73
  jmp alltraps
80106cfd:	e9 6a f5 ff ff       	jmp    8010626c <alltraps>

80106d02 <vector116>:
.globl vector116
vector116:
  pushl $0
80106d02:	6a 00                	push   $0x0
  pushl $116
80106d04:	6a 74                	push   $0x74
  jmp alltraps
80106d06:	e9 61 f5 ff ff       	jmp    8010626c <alltraps>

80106d0b <vector117>:
.globl vector117
vector117:
  pushl $0
80106d0b:	6a 00                	push   $0x0
  pushl $117
80106d0d:	6a 75                	push   $0x75
  jmp alltraps
80106d0f:	e9 58 f5 ff ff       	jmp    8010626c <alltraps>

80106d14 <vector118>:
.globl vector118
vector118:
  pushl $0
80106d14:	6a 00                	push   $0x0
  pushl $118
80106d16:	6a 76                	push   $0x76
  jmp alltraps
80106d18:	e9 4f f5 ff ff       	jmp    8010626c <alltraps>

80106d1d <vector119>:
.globl vector119
vector119:
  pushl $0
80106d1d:	6a 00                	push   $0x0
  pushl $119
80106d1f:	6a 77                	push   $0x77
  jmp alltraps
80106d21:	e9 46 f5 ff ff       	jmp    8010626c <alltraps>

80106d26 <vector120>:
.globl vector120
vector120:
  pushl $0
80106d26:	6a 00                	push   $0x0
  pushl $120
80106d28:	6a 78                	push   $0x78
  jmp alltraps
80106d2a:	e9 3d f5 ff ff       	jmp    8010626c <alltraps>

80106d2f <vector121>:
.globl vector121
vector121:
  pushl $0
80106d2f:	6a 00                	push   $0x0
  pushl $121
80106d31:	6a 79                	push   $0x79
  jmp alltraps
80106d33:	e9 34 f5 ff ff       	jmp    8010626c <alltraps>

80106d38 <vector122>:
.globl vector122
vector122:
  pushl $0
80106d38:	6a 00                	push   $0x0
  pushl $122
80106d3a:	6a 7a                	push   $0x7a
  jmp alltraps
80106d3c:	e9 2b f5 ff ff       	jmp    8010626c <alltraps>

80106d41 <vector123>:
.globl vector123
vector123:
  pushl $0
80106d41:	6a 00                	push   $0x0
  pushl $123
80106d43:	6a 7b                	push   $0x7b
  jmp alltraps
80106d45:	e9 22 f5 ff ff       	jmp    8010626c <alltraps>

80106d4a <vector124>:
.globl vector124
vector124:
  pushl $0
80106d4a:	6a 00                	push   $0x0
  pushl $124
80106d4c:	6a 7c                	push   $0x7c
  jmp alltraps
80106d4e:	e9 19 f5 ff ff       	jmp    8010626c <alltraps>

80106d53 <vector125>:
.globl vector125
vector125:
  pushl $0
80106d53:	6a 00                	push   $0x0
  pushl $125
80106d55:	6a 7d                	push   $0x7d
  jmp alltraps
80106d57:	e9 10 f5 ff ff       	jmp    8010626c <alltraps>

80106d5c <vector126>:
.globl vector126
vector126:
  pushl $0
80106d5c:	6a 00                	push   $0x0
  pushl $126
80106d5e:	6a 7e                	push   $0x7e
  jmp alltraps
80106d60:	e9 07 f5 ff ff       	jmp    8010626c <alltraps>

80106d65 <vector127>:
.globl vector127
vector127:
  pushl $0
80106d65:	6a 00                	push   $0x0
  pushl $127
80106d67:	6a 7f                	push   $0x7f
  jmp alltraps
80106d69:	e9 fe f4 ff ff       	jmp    8010626c <alltraps>

80106d6e <vector128>:
.globl vector128
vector128:
  pushl $0
80106d6e:	6a 00                	push   $0x0
  pushl $128
80106d70:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106d75:	e9 f2 f4 ff ff       	jmp    8010626c <alltraps>

80106d7a <vector129>:
.globl vector129
vector129:
  pushl $0
80106d7a:	6a 00                	push   $0x0
  pushl $129
80106d7c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106d81:	e9 e6 f4 ff ff       	jmp    8010626c <alltraps>

80106d86 <vector130>:
.globl vector130
vector130:
  pushl $0
80106d86:	6a 00                	push   $0x0
  pushl $130
80106d88:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106d8d:	e9 da f4 ff ff       	jmp    8010626c <alltraps>

80106d92 <vector131>:
.globl vector131
vector131:
  pushl $0
80106d92:	6a 00                	push   $0x0
  pushl $131
80106d94:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106d99:	e9 ce f4 ff ff       	jmp    8010626c <alltraps>

80106d9e <vector132>:
.globl vector132
vector132:
  pushl $0
80106d9e:	6a 00                	push   $0x0
  pushl $132
80106da0:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80106da5:	e9 c2 f4 ff ff       	jmp    8010626c <alltraps>

80106daa <vector133>:
.globl vector133
vector133:
  pushl $0
80106daa:	6a 00                	push   $0x0
  pushl $133
80106dac:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80106db1:	e9 b6 f4 ff ff       	jmp    8010626c <alltraps>

80106db6 <vector134>:
.globl vector134
vector134:
  pushl $0
80106db6:	6a 00                	push   $0x0
  pushl $134
80106db8:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80106dbd:	e9 aa f4 ff ff       	jmp    8010626c <alltraps>

80106dc2 <vector135>:
.globl vector135
vector135:
  pushl $0
80106dc2:	6a 00                	push   $0x0
  pushl $135
80106dc4:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80106dc9:	e9 9e f4 ff ff       	jmp    8010626c <alltraps>

80106dce <vector136>:
.globl vector136
vector136:
  pushl $0
80106dce:	6a 00                	push   $0x0
  pushl $136
80106dd0:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80106dd5:	e9 92 f4 ff ff       	jmp    8010626c <alltraps>

80106dda <vector137>:
.globl vector137
vector137:
  pushl $0
80106dda:	6a 00                	push   $0x0
  pushl $137
80106ddc:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80106de1:	e9 86 f4 ff ff       	jmp    8010626c <alltraps>

80106de6 <vector138>:
.globl vector138
vector138:
  pushl $0
80106de6:	6a 00                	push   $0x0
  pushl $138
80106de8:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80106ded:	e9 7a f4 ff ff       	jmp    8010626c <alltraps>

80106df2 <vector139>:
.globl vector139
vector139:
  pushl $0
80106df2:	6a 00                	push   $0x0
  pushl $139
80106df4:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80106df9:	e9 6e f4 ff ff       	jmp    8010626c <alltraps>

80106dfe <vector140>:
.globl vector140
vector140:
  pushl $0
80106dfe:	6a 00                	push   $0x0
  pushl $140
80106e00:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80106e05:	e9 62 f4 ff ff       	jmp    8010626c <alltraps>

80106e0a <vector141>:
.globl vector141
vector141:
  pushl $0
80106e0a:	6a 00                	push   $0x0
  pushl $141
80106e0c:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80106e11:	e9 56 f4 ff ff       	jmp    8010626c <alltraps>

80106e16 <vector142>:
.globl vector142
vector142:
  pushl $0
80106e16:	6a 00                	push   $0x0
  pushl $142
80106e18:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80106e1d:	e9 4a f4 ff ff       	jmp    8010626c <alltraps>

80106e22 <vector143>:
.globl vector143
vector143:
  pushl $0
80106e22:	6a 00                	push   $0x0
  pushl $143
80106e24:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80106e29:	e9 3e f4 ff ff       	jmp    8010626c <alltraps>

80106e2e <vector144>:
.globl vector144
vector144:
  pushl $0
80106e2e:	6a 00                	push   $0x0
  pushl $144
80106e30:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80106e35:	e9 32 f4 ff ff       	jmp    8010626c <alltraps>

80106e3a <vector145>:
.globl vector145
vector145:
  pushl $0
80106e3a:	6a 00                	push   $0x0
  pushl $145
80106e3c:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80106e41:	e9 26 f4 ff ff       	jmp    8010626c <alltraps>

80106e46 <vector146>:
.globl vector146
vector146:
  pushl $0
80106e46:	6a 00                	push   $0x0
  pushl $146
80106e48:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80106e4d:	e9 1a f4 ff ff       	jmp    8010626c <alltraps>

80106e52 <vector147>:
.globl vector147
vector147:
  pushl $0
80106e52:	6a 00                	push   $0x0
  pushl $147
80106e54:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80106e59:	e9 0e f4 ff ff       	jmp    8010626c <alltraps>

80106e5e <vector148>:
.globl vector148
vector148:
  pushl $0
80106e5e:	6a 00                	push   $0x0
  pushl $148
80106e60:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80106e65:	e9 02 f4 ff ff       	jmp    8010626c <alltraps>

80106e6a <vector149>:
.globl vector149
vector149:
  pushl $0
80106e6a:	6a 00                	push   $0x0
  pushl $149
80106e6c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80106e71:	e9 f6 f3 ff ff       	jmp    8010626c <alltraps>

80106e76 <vector150>:
.globl vector150
vector150:
  pushl $0
80106e76:	6a 00                	push   $0x0
  pushl $150
80106e78:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80106e7d:	e9 ea f3 ff ff       	jmp    8010626c <alltraps>

80106e82 <vector151>:
.globl vector151
vector151:
  pushl $0
80106e82:	6a 00                	push   $0x0
  pushl $151
80106e84:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80106e89:	e9 de f3 ff ff       	jmp    8010626c <alltraps>

80106e8e <vector152>:
.globl vector152
vector152:
  pushl $0
80106e8e:	6a 00                	push   $0x0
  pushl $152
80106e90:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80106e95:	e9 d2 f3 ff ff       	jmp    8010626c <alltraps>

80106e9a <vector153>:
.globl vector153
vector153:
  pushl $0
80106e9a:	6a 00                	push   $0x0
  pushl $153
80106e9c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80106ea1:	e9 c6 f3 ff ff       	jmp    8010626c <alltraps>

80106ea6 <vector154>:
.globl vector154
vector154:
  pushl $0
80106ea6:	6a 00                	push   $0x0
  pushl $154
80106ea8:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80106ead:	e9 ba f3 ff ff       	jmp    8010626c <alltraps>

80106eb2 <vector155>:
.globl vector155
vector155:
  pushl $0
80106eb2:	6a 00                	push   $0x0
  pushl $155
80106eb4:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80106eb9:	e9 ae f3 ff ff       	jmp    8010626c <alltraps>

80106ebe <vector156>:
.globl vector156
vector156:
  pushl $0
80106ebe:	6a 00                	push   $0x0
  pushl $156
80106ec0:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80106ec5:	e9 a2 f3 ff ff       	jmp    8010626c <alltraps>

80106eca <vector157>:
.globl vector157
vector157:
  pushl $0
80106eca:	6a 00                	push   $0x0
  pushl $157
80106ecc:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80106ed1:	e9 96 f3 ff ff       	jmp    8010626c <alltraps>

80106ed6 <vector158>:
.globl vector158
vector158:
  pushl $0
80106ed6:	6a 00                	push   $0x0
  pushl $158
80106ed8:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80106edd:	e9 8a f3 ff ff       	jmp    8010626c <alltraps>

80106ee2 <vector159>:
.globl vector159
vector159:
  pushl $0
80106ee2:	6a 00                	push   $0x0
  pushl $159
80106ee4:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80106ee9:	e9 7e f3 ff ff       	jmp    8010626c <alltraps>

80106eee <vector160>:
.globl vector160
vector160:
  pushl $0
80106eee:	6a 00                	push   $0x0
  pushl $160
80106ef0:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80106ef5:	e9 72 f3 ff ff       	jmp    8010626c <alltraps>

80106efa <vector161>:
.globl vector161
vector161:
  pushl $0
80106efa:	6a 00                	push   $0x0
  pushl $161
80106efc:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80106f01:	e9 66 f3 ff ff       	jmp    8010626c <alltraps>

80106f06 <vector162>:
.globl vector162
vector162:
  pushl $0
80106f06:	6a 00                	push   $0x0
  pushl $162
80106f08:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80106f0d:	e9 5a f3 ff ff       	jmp    8010626c <alltraps>

80106f12 <vector163>:
.globl vector163
vector163:
  pushl $0
80106f12:	6a 00                	push   $0x0
  pushl $163
80106f14:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80106f19:	e9 4e f3 ff ff       	jmp    8010626c <alltraps>

80106f1e <vector164>:
.globl vector164
vector164:
  pushl $0
80106f1e:	6a 00                	push   $0x0
  pushl $164
80106f20:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80106f25:	e9 42 f3 ff ff       	jmp    8010626c <alltraps>

80106f2a <vector165>:
.globl vector165
vector165:
  pushl $0
80106f2a:	6a 00                	push   $0x0
  pushl $165
80106f2c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80106f31:	e9 36 f3 ff ff       	jmp    8010626c <alltraps>

80106f36 <vector166>:
.globl vector166
vector166:
  pushl $0
80106f36:	6a 00                	push   $0x0
  pushl $166
80106f38:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80106f3d:	e9 2a f3 ff ff       	jmp    8010626c <alltraps>

80106f42 <vector167>:
.globl vector167
vector167:
  pushl $0
80106f42:	6a 00                	push   $0x0
  pushl $167
80106f44:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80106f49:	e9 1e f3 ff ff       	jmp    8010626c <alltraps>

80106f4e <vector168>:
.globl vector168
vector168:
  pushl $0
80106f4e:	6a 00                	push   $0x0
  pushl $168
80106f50:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80106f55:	e9 12 f3 ff ff       	jmp    8010626c <alltraps>

80106f5a <vector169>:
.globl vector169
vector169:
  pushl $0
80106f5a:	6a 00                	push   $0x0
  pushl $169
80106f5c:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80106f61:	e9 06 f3 ff ff       	jmp    8010626c <alltraps>

80106f66 <vector170>:
.globl vector170
vector170:
  pushl $0
80106f66:	6a 00                	push   $0x0
  pushl $170
80106f68:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80106f6d:	e9 fa f2 ff ff       	jmp    8010626c <alltraps>

80106f72 <vector171>:
.globl vector171
vector171:
  pushl $0
80106f72:	6a 00                	push   $0x0
  pushl $171
80106f74:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80106f79:	e9 ee f2 ff ff       	jmp    8010626c <alltraps>

80106f7e <vector172>:
.globl vector172
vector172:
  pushl $0
80106f7e:	6a 00                	push   $0x0
  pushl $172
80106f80:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80106f85:	e9 e2 f2 ff ff       	jmp    8010626c <alltraps>

80106f8a <vector173>:
.globl vector173
vector173:
  pushl $0
80106f8a:	6a 00                	push   $0x0
  pushl $173
80106f8c:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80106f91:	e9 d6 f2 ff ff       	jmp    8010626c <alltraps>

80106f96 <vector174>:
.globl vector174
vector174:
  pushl $0
80106f96:	6a 00                	push   $0x0
  pushl $174
80106f98:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80106f9d:	e9 ca f2 ff ff       	jmp    8010626c <alltraps>

80106fa2 <vector175>:
.globl vector175
vector175:
  pushl $0
80106fa2:	6a 00                	push   $0x0
  pushl $175
80106fa4:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80106fa9:	e9 be f2 ff ff       	jmp    8010626c <alltraps>

80106fae <vector176>:
.globl vector176
vector176:
  pushl $0
80106fae:	6a 00                	push   $0x0
  pushl $176
80106fb0:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80106fb5:	e9 b2 f2 ff ff       	jmp    8010626c <alltraps>

80106fba <vector177>:
.globl vector177
vector177:
  pushl $0
80106fba:	6a 00                	push   $0x0
  pushl $177
80106fbc:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80106fc1:	e9 a6 f2 ff ff       	jmp    8010626c <alltraps>

80106fc6 <vector178>:
.globl vector178
vector178:
  pushl $0
80106fc6:	6a 00                	push   $0x0
  pushl $178
80106fc8:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80106fcd:	e9 9a f2 ff ff       	jmp    8010626c <alltraps>

80106fd2 <vector179>:
.globl vector179
vector179:
  pushl $0
80106fd2:	6a 00                	push   $0x0
  pushl $179
80106fd4:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80106fd9:	e9 8e f2 ff ff       	jmp    8010626c <alltraps>

80106fde <vector180>:
.globl vector180
vector180:
  pushl $0
80106fde:	6a 00                	push   $0x0
  pushl $180
80106fe0:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80106fe5:	e9 82 f2 ff ff       	jmp    8010626c <alltraps>

80106fea <vector181>:
.globl vector181
vector181:
  pushl $0
80106fea:	6a 00                	push   $0x0
  pushl $181
80106fec:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80106ff1:	e9 76 f2 ff ff       	jmp    8010626c <alltraps>

80106ff6 <vector182>:
.globl vector182
vector182:
  pushl $0
80106ff6:	6a 00                	push   $0x0
  pushl $182
80106ff8:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80106ffd:	e9 6a f2 ff ff       	jmp    8010626c <alltraps>

80107002 <vector183>:
.globl vector183
vector183:
  pushl $0
80107002:	6a 00                	push   $0x0
  pushl $183
80107004:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107009:	e9 5e f2 ff ff       	jmp    8010626c <alltraps>

8010700e <vector184>:
.globl vector184
vector184:
  pushl $0
8010700e:	6a 00                	push   $0x0
  pushl $184
80107010:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107015:	e9 52 f2 ff ff       	jmp    8010626c <alltraps>

8010701a <vector185>:
.globl vector185
vector185:
  pushl $0
8010701a:	6a 00                	push   $0x0
  pushl $185
8010701c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107021:	e9 46 f2 ff ff       	jmp    8010626c <alltraps>

80107026 <vector186>:
.globl vector186
vector186:
  pushl $0
80107026:	6a 00                	push   $0x0
  pushl $186
80107028:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
8010702d:	e9 3a f2 ff ff       	jmp    8010626c <alltraps>

80107032 <vector187>:
.globl vector187
vector187:
  pushl $0
80107032:	6a 00                	push   $0x0
  pushl $187
80107034:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107039:	e9 2e f2 ff ff       	jmp    8010626c <alltraps>

8010703e <vector188>:
.globl vector188
vector188:
  pushl $0
8010703e:	6a 00                	push   $0x0
  pushl $188
80107040:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107045:	e9 22 f2 ff ff       	jmp    8010626c <alltraps>

8010704a <vector189>:
.globl vector189
vector189:
  pushl $0
8010704a:	6a 00                	push   $0x0
  pushl $189
8010704c:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107051:	e9 16 f2 ff ff       	jmp    8010626c <alltraps>

80107056 <vector190>:
.globl vector190
vector190:
  pushl $0
80107056:	6a 00                	push   $0x0
  pushl $190
80107058:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010705d:	e9 0a f2 ff ff       	jmp    8010626c <alltraps>

80107062 <vector191>:
.globl vector191
vector191:
  pushl $0
80107062:	6a 00                	push   $0x0
  pushl $191
80107064:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107069:	e9 fe f1 ff ff       	jmp    8010626c <alltraps>

8010706e <vector192>:
.globl vector192
vector192:
  pushl $0
8010706e:	6a 00                	push   $0x0
  pushl $192
80107070:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107075:	e9 f2 f1 ff ff       	jmp    8010626c <alltraps>

8010707a <vector193>:
.globl vector193
vector193:
  pushl $0
8010707a:	6a 00                	push   $0x0
  pushl $193
8010707c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107081:	e9 e6 f1 ff ff       	jmp    8010626c <alltraps>

80107086 <vector194>:
.globl vector194
vector194:
  pushl $0
80107086:	6a 00                	push   $0x0
  pushl $194
80107088:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010708d:	e9 da f1 ff ff       	jmp    8010626c <alltraps>

80107092 <vector195>:
.globl vector195
vector195:
  pushl $0
80107092:	6a 00                	push   $0x0
  pushl $195
80107094:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107099:	e9 ce f1 ff ff       	jmp    8010626c <alltraps>

8010709e <vector196>:
.globl vector196
vector196:
  pushl $0
8010709e:	6a 00                	push   $0x0
  pushl $196
801070a0:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801070a5:	e9 c2 f1 ff ff       	jmp    8010626c <alltraps>

801070aa <vector197>:
.globl vector197
vector197:
  pushl $0
801070aa:	6a 00                	push   $0x0
  pushl $197
801070ac:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801070b1:	e9 b6 f1 ff ff       	jmp    8010626c <alltraps>

801070b6 <vector198>:
.globl vector198
vector198:
  pushl $0
801070b6:	6a 00                	push   $0x0
  pushl $198
801070b8:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801070bd:	e9 aa f1 ff ff       	jmp    8010626c <alltraps>

801070c2 <vector199>:
.globl vector199
vector199:
  pushl $0
801070c2:	6a 00                	push   $0x0
  pushl $199
801070c4:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801070c9:	e9 9e f1 ff ff       	jmp    8010626c <alltraps>

801070ce <vector200>:
.globl vector200
vector200:
  pushl $0
801070ce:	6a 00                	push   $0x0
  pushl $200
801070d0:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801070d5:	e9 92 f1 ff ff       	jmp    8010626c <alltraps>

801070da <vector201>:
.globl vector201
vector201:
  pushl $0
801070da:	6a 00                	push   $0x0
  pushl $201
801070dc:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801070e1:	e9 86 f1 ff ff       	jmp    8010626c <alltraps>

801070e6 <vector202>:
.globl vector202
vector202:
  pushl $0
801070e6:	6a 00                	push   $0x0
  pushl $202
801070e8:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801070ed:	e9 7a f1 ff ff       	jmp    8010626c <alltraps>

801070f2 <vector203>:
.globl vector203
vector203:
  pushl $0
801070f2:	6a 00                	push   $0x0
  pushl $203
801070f4:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801070f9:	e9 6e f1 ff ff       	jmp    8010626c <alltraps>

801070fe <vector204>:
.globl vector204
vector204:
  pushl $0
801070fe:	6a 00                	push   $0x0
  pushl $204
80107100:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107105:	e9 62 f1 ff ff       	jmp    8010626c <alltraps>

8010710a <vector205>:
.globl vector205
vector205:
  pushl $0
8010710a:	6a 00                	push   $0x0
  pushl $205
8010710c:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107111:	e9 56 f1 ff ff       	jmp    8010626c <alltraps>

80107116 <vector206>:
.globl vector206
vector206:
  pushl $0
80107116:	6a 00                	push   $0x0
  pushl $206
80107118:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
8010711d:	e9 4a f1 ff ff       	jmp    8010626c <alltraps>

80107122 <vector207>:
.globl vector207
vector207:
  pushl $0
80107122:	6a 00                	push   $0x0
  pushl $207
80107124:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107129:	e9 3e f1 ff ff       	jmp    8010626c <alltraps>

8010712e <vector208>:
.globl vector208
vector208:
  pushl $0
8010712e:	6a 00                	push   $0x0
  pushl $208
80107130:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107135:	e9 32 f1 ff ff       	jmp    8010626c <alltraps>

8010713a <vector209>:
.globl vector209
vector209:
  pushl $0
8010713a:	6a 00                	push   $0x0
  pushl $209
8010713c:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107141:	e9 26 f1 ff ff       	jmp    8010626c <alltraps>

80107146 <vector210>:
.globl vector210
vector210:
  pushl $0
80107146:	6a 00                	push   $0x0
  pushl $210
80107148:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
8010714d:	e9 1a f1 ff ff       	jmp    8010626c <alltraps>

80107152 <vector211>:
.globl vector211
vector211:
  pushl $0
80107152:	6a 00                	push   $0x0
  pushl $211
80107154:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107159:	e9 0e f1 ff ff       	jmp    8010626c <alltraps>

8010715e <vector212>:
.globl vector212
vector212:
  pushl $0
8010715e:	6a 00                	push   $0x0
  pushl $212
80107160:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107165:	e9 02 f1 ff ff       	jmp    8010626c <alltraps>

8010716a <vector213>:
.globl vector213
vector213:
  pushl $0
8010716a:	6a 00                	push   $0x0
  pushl $213
8010716c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107171:	e9 f6 f0 ff ff       	jmp    8010626c <alltraps>

80107176 <vector214>:
.globl vector214
vector214:
  pushl $0
80107176:	6a 00                	push   $0x0
  pushl $214
80107178:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010717d:	e9 ea f0 ff ff       	jmp    8010626c <alltraps>

80107182 <vector215>:
.globl vector215
vector215:
  pushl $0
80107182:	6a 00                	push   $0x0
  pushl $215
80107184:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107189:	e9 de f0 ff ff       	jmp    8010626c <alltraps>

8010718e <vector216>:
.globl vector216
vector216:
  pushl $0
8010718e:	6a 00                	push   $0x0
  pushl $216
80107190:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107195:	e9 d2 f0 ff ff       	jmp    8010626c <alltraps>

8010719a <vector217>:
.globl vector217
vector217:
  pushl $0
8010719a:	6a 00                	push   $0x0
  pushl $217
8010719c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801071a1:	e9 c6 f0 ff ff       	jmp    8010626c <alltraps>

801071a6 <vector218>:
.globl vector218
vector218:
  pushl $0
801071a6:	6a 00                	push   $0x0
  pushl $218
801071a8:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801071ad:	e9 ba f0 ff ff       	jmp    8010626c <alltraps>

801071b2 <vector219>:
.globl vector219
vector219:
  pushl $0
801071b2:	6a 00                	push   $0x0
  pushl $219
801071b4:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801071b9:	e9 ae f0 ff ff       	jmp    8010626c <alltraps>

801071be <vector220>:
.globl vector220
vector220:
  pushl $0
801071be:	6a 00                	push   $0x0
  pushl $220
801071c0:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801071c5:	e9 a2 f0 ff ff       	jmp    8010626c <alltraps>

801071ca <vector221>:
.globl vector221
vector221:
  pushl $0
801071ca:	6a 00                	push   $0x0
  pushl $221
801071cc:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801071d1:	e9 96 f0 ff ff       	jmp    8010626c <alltraps>

801071d6 <vector222>:
.globl vector222
vector222:
  pushl $0
801071d6:	6a 00                	push   $0x0
  pushl $222
801071d8:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801071dd:	e9 8a f0 ff ff       	jmp    8010626c <alltraps>

801071e2 <vector223>:
.globl vector223
vector223:
  pushl $0
801071e2:	6a 00                	push   $0x0
  pushl $223
801071e4:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801071e9:	e9 7e f0 ff ff       	jmp    8010626c <alltraps>

801071ee <vector224>:
.globl vector224
vector224:
  pushl $0
801071ee:	6a 00                	push   $0x0
  pushl $224
801071f0:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801071f5:	e9 72 f0 ff ff       	jmp    8010626c <alltraps>

801071fa <vector225>:
.globl vector225
vector225:
  pushl $0
801071fa:	6a 00                	push   $0x0
  pushl $225
801071fc:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107201:	e9 66 f0 ff ff       	jmp    8010626c <alltraps>

80107206 <vector226>:
.globl vector226
vector226:
  pushl $0
80107206:	6a 00                	push   $0x0
  pushl $226
80107208:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
8010720d:	e9 5a f0 ff ff       	jmp    8010626c <alltraps>

80107212 <vector227>:
.globl vector227
vector227:
  pushl $0
80107212:	6a 00                	push   $0x0
  pushl $227
80107214:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107219:	e9 4e f0 ff ff       	jmp    8010626c <alltraps>

8010721e <vector228>:
.globl vector228
vector228:
  pushl $0
8010721e:	6a 00                	push   $0x0
  pushl $228
80107220:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107225:	e9 42 f0 ff ff       	jmp    8010626c <alltraps>

8010722a <vector229>:
.globl vector229
vector229:
  pushl $0
8010722a:	6a 00                	push   $0x0
  pushl $229
8010722c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107231:	e9 36 f0 ff ff       	jmp    8010626c <alltraps>

80107236 <vector230>:
.globl vector230
vector230:
  pushl $0
80107236:	6a 00                	push   $0x0
  pushl $230
80107238:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010723d:	e9 2a f0 ff ff       	jmp    8010626c <alltraps>

80107242 <vector231>:
.globl vector231
vector231:
  pushl $0
80107242:	6a 00                	push   $0x0
  pushl $231
80107244:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107249:	e9 1e f0 ff ff       	jmp    8010626c <alltraps>

8010724e <vector232>:
.globl vector232
vector232:
  pushl $0
8010724e:	6a 00                	push   $0x0
  pushl $232
80107250:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107255:	e9 12 f0 ff ff       	jmp    8010626c <alltraps>

8010725a <vector233>:
.globl vector233
vector233:
  pushl $0
8010725a:	6a 00                	push   $0x0
  pushl $233
8010725c:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107261:	e9 06 f0 ff ff       	jmp    8010626c <alltraps>

80107266 <vector234>:
.globl vector234
vector234:
  pushl $0
80107266:	6a 00                	push   $0x0
  pushl $234
80107268:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010726d:	e9 fa ef ff ff       	jmp    8010626c <alltraps>

80107272 <vector235>:
.globl vector235
vector235:
  pushl $0
80107272:	6a 00                	push   $0x0
  pushl $235
80107274:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107279:	e9 ee ef ff ff       	jmp    8010626c <alltraps>

8010727e <vector236>:
.globl vector236
vector236:
  pushl $0
8010727e:	6a 00                	push   $0x0
  pushl $236
80107280:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107285:	e9 e2 ef ff ff       	jmp    8010626c <alltraps>

8010728a <vector237>:
.globl vector237
vector237:
  pushl $0
8010728a:	6a 00                	push   $0x0
  pushl $237
8010728c:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107291:	e9 d6 ef ff ff       	jmp    8010626c <alltraps>

80107296 <vector238>:
.globl vector238
vector238:
  pushl $0
80107296:	6a 00                	push   $0x0
  pushl $238
80107298:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010729d:	e9 ca ef ff ff       	jmp    8010626c <alltraps>

801072a2 <vector239>:
.globl vector239
vector239:
  pushl $0
801072a2:	6a 00                	push   $0x0
  pushl $239
801072a4:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801072a9:	e9 be ef ff ff       	jmp    8010626c <alltraps>

801072ae <vector240>:
.globl vector240
vector240:
  pushl $0
801072ae:	6a 00                	push   $0x0
  pushl $240
801072b0:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801072b5:	e9 b2 ef ff ff       	jmp    8010626c <alltraps>

801072ba <vector241>:
.globl vector241
vector241:
  pushl $0
801072ba:	6a 00                	push   $0x0
  pushl $241
801072bc:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801072c1:	e9 a6 ef ff ff       	jmp    8010626c <alltraps>

801072c6 <vector242>:
.globl vector242
vector242:
  pushl $0
801072c6:	6a 00                	push   $0x0
  pushl $242
801072c8:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801072cd:	e9 9a ef ff ff       	jmp    8010626c <alltraps>

801072d2 <vector243>:
.globl vector243
vector243:
  pushl $0
801072d2:	6a 00                	push   $0x0
  pushl $243
801072d4:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801072d9:	e9 8e ef ff ff       	jmp    8010626c <alltraps>

801072de <vector244>:
.globl vector244
vector244:
  pushl $0
801072de:	6a 00                	push   $0x0
  pushl $244
801072e0:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801072e5:	e9 82 ef ff ff       	jmp    8010626c <alltraps>

801072ea <vector245>:
.globl vector245
vector245:
  pushl $0
801072ea:	6a 00                	push   $0x0
  pushl $245
801072ec:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801072f1:	e9 76 ef ff ff       	jmp    8010626c <alltraps>

801072f6 <vector246>:
.globl vector246
vector246:
  pushl $0
801072f6:	6a 00                	push   $0x0
  pushl $246
801072f8:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801072fd:	e9 6a ef ff ff       	jmp    8010626c <alltraps>

80107302 <vector247>:
.globl vector247
vector247:
  pushl $0
80107302:	6a 00                	push   $0x0
  pushl $247
80107304:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107309:	e9 5e ef ff ff       	jmp    8010626c <alltraps>

8010730e <vector248>:
.globl vector248
vector248:
  pushl $0
8010730e:	6a 00                	push   $0x0
  pushl $248
80107310:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107315:	e9 52 ef ff ff       	jmp    8010626c <alltraps>

8010731a <vector249>:
.globl vector249
vector249:
  pushl $0
8010731a:	6a 00                	push   $0x0
  pushl $249
8010731c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107321:	e9 46 ef ff ff       	jmp    8010626c <alltraps>

80107326 <vector250>:
.globl vector250
vector250:
  pushl $0
80107326:	6a 00                	push   $0x0
  pushl $250
80107328:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010732d:	e9 3a ef ff ff       	jmp    8010626c <alltraps>

80107332 <vector251>:
.globl vector251
vector251:
  pushl $0
80107332:	6a 00                	push   $0x0
  pushl $251
80107334:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107339:	e9 2e ef ff ff       	jmp    8010626c <alltraps>

8010733e <vector252>:
.globl vector252
vector252:
  pushl $0
8010733e:	6a 00                	push   $0x0
  pushl $252
80107340:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107345:	e9 22 ef ff ff       	jmp    8010626c <alltraps>

8010734a <vector253>:
.globl vector253
vector253:
  pushl $0
8010734a:	6a 00                	push   $0x0
  pushl $253
8010734c:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107351:	e9 16 ef ff ff       	jmp    8010626c <alltraps>

80107356 <vector254>:
.globl vector254
vector254:
  pushl $0
80107356:	6a 00                	push   $0x0
  pushl $254
80107358:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010735d:	e9 0a ef ff ff       	jmp    8010626c <alltraps>

80107362 <vector255>:
.globl vector255
vector255:
  pushl $0
80107362:	6a 00                	push   $0x0
  pushl $255
80107364:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107369:	e9 fe ee ff ff       	jmp    8010626c <alltraps>
	...

80107370 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107370:	55                   	push   %ebp
80107371:	89 e5                	mov    %esp,%ebp
80107373:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107376:	8b 45 0c             	mov    0xc(%ebp),%eax
80107379:	83 e8 01             	sub    $0x1,%eax
8010737c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107380:	8b 45 08             	mov    0x8(%ebp),%eax
80107383:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107387:	8b 45 08             	mov    0x8(%ebp),%eax
8010738a:	c1 e8 10             	shr    $0x10,%eax
8010738d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107391:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107394:	0f 01 10             	lgdtl  (%eax)
}
80107397:	c9                   	leave  
80107398:	c3                   	ret    

80107399 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107399:	55                   	push   %ebp
8010739a:	89 e5                	mov    %esp,%ebp
8010739c:	83 ec 04             	sub    $0x4,%esp
8010739f:	8b 45 08             	mov    0x8(%ebp),%eax
801073a2:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801073a6:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801073aa:	0f 00 d8             	ltr    %ax
}
801073ad:	c9                   	leave  
801073ae:	c3                   	ret    

801073af <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801073af:	55                   	push   %ebp
801073b0:	89 e5                	mov    %esp,%ebp
801073b2:	83 ec 04             	sub    $0x4,%esp
801073b5:	8b 45 08             	mov    0x8(%ebp),%eax
801073b8:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801073bc:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801073c0:	8e e8                	mov    %eax,%gs
}
801073c2:	c9                   	leave  
801073c3:	c3                   	ret    

801073c4 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801073c4:	55                   	push   %ebp
801073c5:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801073c7:	8b 45 08             	mov    0x8(%ebp),%eax
801073ca:	0f 22 d8             	mov    %eax,%cr3
}
801073cd:	5d                   	pop    %ebp
801073ce:	c3                   	ret    

801073cf <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801073cf:	55                   	push   %ebp
801073d0:	89 e5                	mov    %esp,%ebp
801073d2:	8b 45 08             	mov    0x8(%ebp),%eax
801073d5:	05 00 00 00 80       	add    $0x80000000,%eax
801073da:	5d                   	pop    %ebp
801073db:	c3                   	ret    

801073dc <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801073dc:	55                   	push   %ebp
801073dd:	89 e5                	mov    %esp,%ebp
801073df:	8b 45 08             	mov    0x8(%ebp),%eax
801073e2:	05 00 00 00 80       	add    $0x80000000,%eax
801073e7:	5d                   	pop    %ebp
801073e8:	c3                   	ret    

801073e9 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801073e9:	55                   	push   %ebp
801073ea:	89 e5                	mov    %esp,%ebp
801073ec:	53                   	push   %ebx
801073ed:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801073f0:	e8 d8 ba ff ff       	call   80102ecd <cpunum>
801073f5:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801073fb:	05 40 fe 10 80       	add    $0x8010fe40,%eax
80107400:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107406:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
8010740c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010740f:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107415:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107418:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
8010741c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010741f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107423:	83 e2 f0             	and    $0xfffffff0,%edx
80107426:	83 ca 0a             	or     $0xa,%edx
80107429:	88 50 7d             	mov    %dl,0x7d(%eax)
8010742c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010742f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107433:	83 ca 10             	or     $0x10,%edx
80107436:	88 50 7d             	mov    %dl,0x7d(%eax)
80107439:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010743c:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107440:	83 e2 9f             	and    $0xffffff9f,%edx
80107443:	88 50 7d             	mov    %dl,0x7d(%eax)
80107446:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107449:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010744d:	83 ca 80             	or     $0xffffff80,%edx
80107450:	88 50 7d             	mov    %dl,0x7d(%eax)
80107453:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107456:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010745a:	83 ca 0f             	or     $0xf,%edx
8010745d:	88 50 7e             	mov    %dl,0x7e(%eax)
80107460:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107463:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107467:	83 e2 ef             	and    $0xffffffef,%edx
8010746a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010746d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107470:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107474:	83 e2 df             	and    $0xffffffdf,%edx
80107477:	88 50 7e             	mov    %dl,0x7e(%eax)
8010747a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010747d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107481:	83 ca 40             	or     $0x40,%edx
80107484:	88 50 7e             	mov    %dl,0x7e(%eax)
80107487:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010748a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010748e:	83 ca 80             	or     $0xffffff80,%edx
80107491:	88 50 7e             	mov    %dl,0x7e(%eax)
80107494:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107497:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010749b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010749e:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801074a5:	ff ff 
801074a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074aa:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801074b1:	00 00 
801074b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074b6:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801074bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074c0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801074c7:	83 e2 f0             	and    $0xfffffff0,%edx
801074ca:	83 ca 02             	or     $0x2,%edx
801074cd:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801074d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074d6:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801074dd:	83 ca 10             	or     $0x10,%edx
801074e0:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801074e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074e9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801074f0:	83 e2 9f             	and    $0xffffff9f,%edx
801074f3:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801074f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074fc:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107503:	83 ca 80             	or     $0xffffff80,%edx
80107506:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010750c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010750f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107516:	83 ca 0f             	or     $0xf,%edx
80107519:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010751f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107522:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107529:	83 e2 ef             	and    $0xffffffef,%edx
8010752c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107532:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107535:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010753c:	83 e2 df             	and    $0xffffffdf,%edx
8010753f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107545:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107548:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010754f:	83 ca 40             	or     $0x40,%edx
80107552:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107558:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010755b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107562:	83 ca 80             	or     $0xffffff80,%edx
80107565:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010756b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010756e:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107575:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107578:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010757f:	ff ff 
80107581:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107584:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010758b:	00 00 
8010758d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107590:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010759a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801075a1:	83 e2 f0             	and    $0xfffffff0,%edx
801075a4:	83 ca 0a             	or     $0xa,%edx
801075a7:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801075ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075b0:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801075b7:	83 ca 10             	or     $0x10,%edx
801075ba:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801075c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075c3:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801075ca:	83 ca 60             	or     $0x60,%edx
801075cd:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801075d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075d6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801075dd:	83 ca 80             	or     $0xffffff80,%edx
801075e0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801075e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075e9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801075f0:	83 ca 0f             	or     $0xf,%edx
801075f3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801075f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075fc:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107603:	83 e2 ef             	and    $0xffffffef,%edx
80107606:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010760c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010760f:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107616:	83 e2 df             	and    $0xffffffdf,%edx
80107619:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010761f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107622:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107629:	83 ca 40             	or     $0x40,%edx
8010762c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107635:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010763c:	83 ca 80             	or     $0xffffff80,%edx
8010763f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107645:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107648:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010764f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107652:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107659:	ff ff 
8010765b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010765e:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107665:	00 00 
80107667:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010766a:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107671:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107674:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010767b:	83 e2 f0             	and    $0xfffffff0,%edx
8010767e:	83 ca 02             	or     $0x2,%edx
80107681:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107687:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010768a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107691:	83 ca 10             	or     $0x10,%edx
80107694:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010769a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010769d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801076a4:	83 ca 60             	or     $0x60,%edx
801076a7:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801076ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076b0:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801076b7:	83 ca 80             	or     $0xffffff80,%edx
801076ba:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801076c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c3:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801076ca:	83 ca 0f             	or     $0xf,%edx
801076cd:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801076d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d6:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801076dd:	83 e2 ef             	and    $0xffffffef,%edx
801076e0:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801076e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e9:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801076f0:	83 e2 df             	and    $0xffffffdf,%edx
801076f3:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801076f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076fc:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107703:	83 ca 40             	or     $0x40,%edx
80107706:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010770c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010770f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107716:	83 ca 80             	or     $0xffffff80,%edx
80107719:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010771f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107722:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107729:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010772c:	05 b4 00 00 00       	add    $0xb4,%eax
80107731:	89 c3                	mov    %eax,%ebx
80107733:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107736:	05 b4 00 00 00       	add    $0xb4,%eax
8010773b:	c1 e8 10             	shr    $0x10,%eax
8010773e:	89 c1                	mov    %eax,%ecx
80107740:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107743:	05 b4 00 00 00       	add    $0xb4,%eax
80107748:	c1 e8 18             	shr    $0x18,%eax
8010774b:	89 c2                	mov    %eax,%edx
8010774d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107750:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107757:	00 00 
80107759:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010775c:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107763:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107766:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
8010776c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010776f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107776:	83 e1 f0             	and    $0xfffffff0,%ecx
80107779:	83 c9 02             	or     $0x2,%ecx
8010777c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107782:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107785:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010778c:	83 c9 10             	or     $0x10,%ecx
8010778f:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107795:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107798:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010779f:	83 e1 9f             	and    $0xffffff9f,%ecx
801077a2:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801077a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ab:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801077b2:	83 c9 80             	or     $0xffffff80,%ecx
801077b5:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801077bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077be:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801077c5:	83 e1 f0             	and    $0xfffffff0,%ecx
801077c8:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801077ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d1:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801077d8:	83 e1 ef             	and    $0xffffffef,%ecx
801077db:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801077e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e4:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801077eb:	83 e1 df             	and    $0xffffffdf,%ecx
801077ee:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801077f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801077fe:	83 c9 40             	or     $0x40,%ecx
80107801:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107807:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107811:	83 c9 80             	or     $0xffffff80,%ecx
80107814:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010781a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010781d:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107823:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107826:	83 c0 70             	add    $0x70,%eax
80107829:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107830:	00 
80107831:	89 04 24             	mov    %eax,(%esp)
80107834:	e8 37 fb ff ff       	call   80107370 <lgdt>
  loadgs(SEG_KCPU << 3);
80107839:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107840:	e8 6a fb ff ff       	call   801073af <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107845:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107848:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010784e:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107855:	00 00 00 00 
}
80107859:	83 c4 24             	add    $0x24,%esp
8010785c:	5b                   	pop    %ebx
8010785d:	5d                   	pop    %ebp
8010785e:	c3                   	ret    

8010785f <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010785f:	55                   	push   %ebp
80107860:	89 e5                	mov    %esp,%ebp
80107862:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107865:	8b 45 0c             	mov    0xc(%ebp),%eax
80107868:	c1 e8 16             	shr    $0x16,%eax
8010786b:	c1 e0 02             	shl    $0x2,%eax
8010786e:	03 45 08             	add    0x8(%ebp),%eax
80107871:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107874:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107877:	8b 00                	mov    (%eax),%eax
80107879:	83 e0 01             	and    $0x1,%eax
8010787c:	84 c0                	test   %al,%al
8010787e:	74 17                	je     80107897 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107880:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107883:	8b 00                	mov    (%eax),%eax
80107885:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010788a:	89 04 24             	mov    %eax,(%esp)
8010788d:	e8 4a fb ff ff       	call   801073dc <p2v>
80107892:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107895:	eb 4b                	jmp    801078e2 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107897:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010789b:	74 0e                	je     801078ab <walkpgdir+0x4c>
8010789d:	e8 9d b2 ff ff       	call   80102b3f <kalloc>
801078a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801078a5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801078a9:	75 07                	jne    801078b2 <walkpgdir+0x53>
      return 0;
801078ab:	b8 00 00 00 00       	mov    $0x0,%eax
801078b0:	eb 41                	jmp    801078f3 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801078b2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801078b9:	00 
801078ba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801078c1:	00 
801078c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c5:	89 04 24             	mov    %eax,(%esp)
801078c8:	e8 65 d5 ff ff       	call   80104e32 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801078cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d0:	89 04 24             	mov    %eax,(%esp)
801078d3:	e8 f7 fa ff ff       	call   801073cf <v2p>
801078d8:	89 c2                	mov    %eax,%edx
801078da:	83 ca 07             	or     $0x7,%edx
801078dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801078e0:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801078e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801078e5:	c1 e8 0c             	shr    $0xc,%eax
801078e8:	25 ff 03 00 00       	and    $0x3ff,%eax
801078ed:	c1 e0 02             	shl    $0x2,%eax
801078f0:	03 45 f4             	add    -0xc(%ebp),%eax
}
801078f3:	c9                   	leave  
801078f4:	c3                   	ret    

801078f5 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801078f5:	55                   	push   %ebp
801078f6:	89 e5                	mov    %esp,%ebp
801078f8:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801078fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801078fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107903:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107906:	8b 45 0c             	mov    0xc(%ebp),%eax
80107909:	03 45 10             	add    0x10(%ebp),%eax
8010790c:	83 e8 01             	sub    $0x1,%eax
8010790f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107914:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107917:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010791e:	00 
8010791f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107922:	89 44 24 04          	mov    %eax,0x4(%esp)
80107926:	8b 45 08             	mov    0x8(%ebp),%eax
80107929:	89 04 24             	mov    %eax,(%esp)
8010792c:	e8 2e ff ff ff       	call   8010785f <walkpgdir>
80107931:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107934:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107938:	75 07                	jne    80107941 <mappages+0x4c>
      return -1;
8010793a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010793f:	eb 46                	jmp    80107987 <mappages+0x92>
    if(*pte & PTE_P)
80107941:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107944:	8b 00                	mov    (%eax),%eax
80107946:	83 e0 01             	and    $0x1,%eax
80107949:	84 c0                	test   %al,%al
8010794b:	74 0c                	je     80107959 <mappages+0x64>
      panic("remap");
8010794d:	c7 04 24 6c 87 10 80 	movl   $0x8010876c,(%esp)
80107954:	e8 e4 8b ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80107959:	8b 45 18             	mov    0x18(%ebp),%eax
8010795c:	0b 45 14             	or     0x14(%ebp),%eax
8010795f:	89 c2                	mov    %eax,%edx
80107961:	83 ca 01             	or     $0x1,%edx
80107964:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107967:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107969:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010796c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010796f:	74 10                	je     80107981 <mappages+0x8c>
      break;
    a += PGSIZE;
80107971:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107978:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
8010797f:	eb 96                	jmp    80107917 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107981:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107982:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107987:	c9                   	leave  
80107988:	c3                   	ret    

80107989 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80107989:	55                   	push   %ebp
8010798a:	89 e5                	mov    %esp,%ebp
8010798c:	53                   	push   %ebx
8010798d:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107990:	e8 aa b1 ff ff       	call   80102b3f <kalloc>
80107995:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107998:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010799c:	75 0a                	jne    801079a8 <setupkvm+0x1f>
    return 0;
8010799e:	b8 00 00 00 00       	mov    $0x0,%eax
801079a3:	e9 98 00 00 00       	jmp    80107a40 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801079a8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801079af:	00 
801079b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801079b7:	00 
801079b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801079bb:	89 04 24             	mov    %eax,(%esp)
801079be:	e8 6f d4 ff ff       	call   80104e32 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801079c3:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801079ca:	e8 0d fa ff ff       	call   801073dc <p2v>
801079cf:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801079d4:	76 0c                	jbe    801079e2 <setupkvm+0x59>
    panic("PHYSTOP too high");
801079d6:	c7 04 24 72 87 10 80 	movl   $0x80108772,(%esp)
801079dd:	e8 5b 8b ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801079e2:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
801079e9:	eb 49                	jmp    80107a34 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
801079eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801079ee:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
801079f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801079f4:	8b 50 04             	mov    0x4(%eax),%edx
801079f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079fa:	8b 58 08             	mov    0x8(%eax),%ebx
801079fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a00:	8b 40 04             	mov    0x4(%eax),%eax
80107a03:	29 c3                	sub    %eax,%ebx
80107a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a08:	8b 00                	mov    (%eax),%eax
80107a0a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107a0e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107a12:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107a16:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a1d:	89 04 24             	mov    %eax,(%esp)
80107a20:	e8 d0 fe ff ff       	call   801078f5 <mappages>
80107a25:	85 c0                	test   %eax,%eax
80107a27:	79 07                	jns    80107a30 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107a29:	b8 00 00 00 00       	mov    $0x0,%eax
80107a2e:	eb 10                	jmp    80107a40 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107a30:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107a34:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107a3b:	72 ae                	jb     801079eb <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107a3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107a40:	83 c4 34             	add    $0x34,%esp
80107a43:	5b                   	pop    %ebx
80107a44:	5d                   	pop    %ebp
80107a45:	c3                   	ret    

80107a46 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107a46:	55                   	push   %ebp
80107a47:	89 e5                	mov    %esp,%ebp
80107a49:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107a4c:	e8 38 ff ff ff       	call   80107989 <setupkvm>
80107a51:	a3 18 2c 11 80       	mov    %eax,0x80112c18
  switchkvm();
80107a56:	e8 02 00 00 00       	call   80107a5d <switchkvm>
}
80107a5b:	c9                   	leave  
80107a5c:	c3                   	ret    

80107a5d <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107a5d:	55                   	push   %ebp
80107a5e:	89 e5                	mov    %esp,%ebp
80107a60:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107a63:	a1 18 2c 11 80       	mov    0x80112c18,%eax
80107a68:	89 04 24             	mov    %eax,(%esp)
80107a6b:	e8 5f f9 ff ff       	call   801073cf <v2p>
80107a70:	89 04 24             	mov    %eax,(%esp)
80107a73:	e8 4c f9 ff ff       	call   801073c4 <lcr3>
}
80107a78:	c9                   	leave  
80107a79:	c3                   	ret    

80107a7a <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107a7a:	55                   	push   %ebp
80107a7b:	89 e5                	mov    %esp,%ebp
80107a7d:	53                   	push   %ebx
80107a7e:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107a81:	e8 a5 d2 ff ff       	call   80104d2b <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107a86:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107a8c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107a93:	83 c2 08             	add    $0x8,%edx
80107a96:	89 d3                	mov    %edx,%ebx
80107a98:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107a9f:	83 c2 08             	add    $0x8,%edx
80107aa2:	c1 ea 10             	shr    $0x10,%edx
80107aa5:	89 d1                	mov    %edx,%ecx
80107aa7:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107aae:	83 c2 08             	add    $0x8,%edx
80107ab1:	c1 ea 18             	shr    $0x18,%edx
80107ab4:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107abb:	67 00 
80107abd:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107ac4:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107aca:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ad1:	83 e1 f0             	and    $0xfffffff0,%ecx
80107ad4:	83 c9 09             	or     $0x9,%ecx
80107ad7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107add:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ae4:	83 c9 10             	or     $0x10,%ecx
80107ae7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107aed:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107af4:	83 e1 9f             	and    $0xffffff9f,%ecx
80107af7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107afd:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b04:	83 c9 80             	or     $0xffffff80,%ecx
80107b07:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b0d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b14:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b17:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b1d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b24:	83 e1 ef             	and    $0xffffffef,%ecx
80107b27:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b2d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b34:	83 e1 df             	and    $0xffffffdf,%ecx
80107b37:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b3d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b44:	83 c9 40             	or     $0x40,%ecx
80107b47:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b4d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b54:	83 e1 7f             	and    $0x7f,%ecx
80107b57:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b5d:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107b63:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b69:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107b70:	83 e2 ef             	and    $0xffffffef,%edx
80107b73:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107b79:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b7f:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107b85:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b8b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107b92:	8b 52 08             	mov    0x8(%edx),%edx
80107b95:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107b9b:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107b9e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107ba5:	e8 ef f7 ff ff       	call   80107399 <ltr>
  if(p->pgdir == 0)
80107baa:	8b 45 08             	mov    0x8(%ebp),%eax
80107bad:	8b 40 04             	mov    0x4(%eax),%eax
80107bb0:	85 c0                	test   %eax,%eax
80107bb2:	75 0c                	jne    80107bc0 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107bb4:	c7 04 24 83 87 10 80 	movl   $0x80108783,(%esp)
80107bbb:	e8 7d 89 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107bc0:	8b 45 08             	mov    0x8(%ebp),%eax
80107bc3:	8b 40 04             	mov    0x4(%eax),%eax
80107bc6:	89 04 24             	mov    %eax,(%esp)
80107bc9:	e8 01 f8 ff ff       	call   801073cf <v2p>
80107bce:	89 04 24             	mov    %eax,(%esp)
80107bd1:	e8 ee f7 ff ff       	call   801073c4 <lcr3>
  popcli();
80107bd6:	e8 98 d1 ff ff       	call   80104d73 <popcli>
}
80107bdb:	83 c4 14             	add    $0x14,%esp
80107bde:	5b                   	pop    %ebx
80107bdf:	5d                   	pop    %ebp
80107be0:	c3                   	ret    

80107be1 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107be1:	55                   	push   %ebp
80107be2:	89 e5                	mov    %esp,%ebp
80107be4:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107be7:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107bee:	76 0c                	jbe    80107bfc <inituvm+0x1b>
    panic("inituvm: more than a page");
80107bf0:	c7 04 24 97 87 10 80 	movl   $0x80108797,(%esp)
80107bf7:	e8 41 89 ff ff       	call   8010053d <panic>
  mem = kalloc();
80107bfc:	e8 3e af ff ff       	call   80102b3f <kalloc>
80107c01:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107c04:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c0b:	00 
80107c0c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c13:	00 
80107c14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c17:	89 04 24             	mov    %eax,(%esp)
80107c1a:	e8 13 d2 ff ff       	call   80104e32 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107c1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c22:	89 04 24             	mov    %eax,(%esp)
80107c25:	e8 a5 f7 ff ff       	call   801073cf <v2p>
80107c2a:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107c31:	00 
80107c32:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107c36:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c3d:	00 
80107c3e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c45:	00 
80107c46:	8b 45 08             	mov    0x8(%ebp),%eax
80107c49:	89 04 24             	mov    %eax,(%esp)
80107c4c:	e8 a4 fc ff ff       	call   801078f5 <mappages>
  memmove(mem, init, sz);
80107c51:	8b 45 10             	mov    0x10(%ebp),%eax
80107c54:	89 44 24 08          	mov    %eax,0x8(%esp)
80107c58:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c5b:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c62:	89 04 24             	mov    %eax,(%esp)
80107c65:	e8 9b d2 ff ff       	call   80104f05 <memmove>
}
80107c6a:	c9                   	leave  
80107c6b:	c3                   	ret    

80107c6c <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107c6c:	55                   	push   %ebp
80107c6d:	89 e5                	mov    %esp,%ebp
80107c6f:	53                   	push   %ebx
80107c70:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107c73:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c76:	25 ff 0f 00 00       	and    $0xfff,%eax
80107c7b:	85 c0                	test   %eax,%eax
80107c7d:	74 0c                	je     80107c8b <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107c7f:	c7 04 24 b4 87 10 80 	movl   $0x801087b4,(%esp)
80107c86:	e8 b2 88 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107c8b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107c92:	e9 ad 00 00 00       	jmp    80107d44 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c9a:	8b 55 0c             	mov    0xc(%ebp),%edx
80107c9d:	01 d0                	add    %edx,%eax
80107c9f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107ca6:	00 
80107ca7:	89 44 24 04          	mov    %eax,0x4(%esp)
80107cab:	8b 45 08             	mov    0x8(%ebp),%eax
80107cae:	89 04 24             	mov    %eax,(%esp)
80107cb1:	e8 a9 fb ff ff       	call   8010785f <walkpgdir>
80107cb6:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107cb9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107cbd:	75 0c                	jne    80107ccb <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107cbf:	c7 04 24 d7 87 10 80 	movl   $0x801087d7,(%esp)
80107cc6:	e8 72 88 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80107ccb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107cce:	8b 00                	mov    (%eax),%eax
80107cd0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107cd5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cdb:	8b 55 18             	mov    0x18(%ebp),%edx
80107cde:	89 d1                	mov    %edx,%ecx
80107ce0:	29 c1                	sub    %eax,%ecx
80107ce2:	89 c8                	mov    %ecx,%eax
80107ce4:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107ce9:	77 11                	ja     80107cfc <loaduvm+0x90>
      n = sz - i;
80107ceb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cee:	8b 55 18             	mov    0x18(%ebp),%edx
80107cf1:	89 d1                	mov    %edx,%ecx
80107cf3:	29 c1                	sub    %eax,%ecx
80107cf5:	89 c8                	mov    %ecx,%eax
80107cf7:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107cfa:	eb 07                	jmp    80107d03 <loaduvm+0x97>
    else
      n = PGSIZE;
80107cfc:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107d03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d06:	8b 55 14             	mov    0x14(%ebp),%edx
80107d09:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107d0c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107d0f:	89 04 24             	mov    %eax,(%esp)
80107d12:	e8 c5 f6 ff ff       	call   801073dc <p2v>
80107d17:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107d1a:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107d1e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107d22:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d26:	8b 45 10             	mov    0x10(%ebp),%eax
80107d29:	89 04 24             	mov    %eax,(%esp)
80107d2c:	e8 6d a0 ff ff       	call   80101d9e <readi>
80107d31:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107d34:	74 07                	je     80107d3d <loaduvm+0xd1>
      return -1;
80107d36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107d3b:	eb 18                	jmp    80107d55 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107d3d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107d44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d47:	3b 45 18             	cmp    0x18(%ebp),%eax
80107d4a:	0f 82 47 ff ff ff    	jb     80107c97 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107d50:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107d55:	83 c4 24             	add    $0x24,%esp
80107d58:	5b                   	pop    %ebx
80107d59:	5d                   	pop    %ebp
80107d5a:	c3                   	ret    

80107d5b <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107d5b:	55                   	push   %ebp
80107d5c:	89 e5                	mov    %esp,%ebp
80107d5e:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107d61:	8b 45 10             	mov    0x10(%ebp),%eax
80107d64:	85 c0                	test   %eax,%eax
80107d66:	79 0a                	jns    80107d72 <allocuvm+0x17>
    return 0;
80107d68:	b8 00 00 00 00       	mov    $0x0,%eax
80107d6d:	e9 c1 00 00 00       	jmp    80107e33 <allocuvm+0xd8>
  if(newsz < oldsz)
80107d72:	8b 45 10             	mov    0x10(%ebp),%eax
80107d75:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107d78:	73 08                	jae    80107d82 <allocuvm+0x27>
    return oldsz;
80107d7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d7d:	e9 b1 00 00 00       	jmp    80107e33 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107d82:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d85:	05 ff 0f 00 00       	add    $0xfff,%eax
80107d8a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107d92:	e9 8d 00 00 00       	jmp    80107e24 <allocuvm+0xc9>
    mem = kalloc();
80107d97:	e8 a3 ad ff ff       	call   80102b3f <kalloc>
80107d9c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107d9f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107da3:	75 2c                	jne    80107dd1 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80107da5:	c7 04 24 f5 87 10 80 	movl   $0x801087f5,(%esp)
80107dac:	e8 f0 85 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107db1:	8b 45 0c             	mov    0xc(%ebp),%eax
80107db4:	89 44 24 08          	mov    %eax,0x8(%esp)
80107db8:	8b 45 10             	mov    0x10(%ebp),%eax
80107dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
80107dbf:	8b 45 08             	mov    0x8(%ebp),%eax
80107dc2:	89 04 24             	mov    %eax,(%esp)
80107dc5:	e8 6b 00 00 00       	call   80107e35 <deallocuvm>
      return 0;
80107dca:	b8 00 00 00 00       	mov    $0x0,%eax
80107dcf:	eb 62                	jmp    80107e33 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80107dd1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107dd8:	00 
80107dd9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107de0:	00 
80107de1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107de4:	89 04 24             	mov    %eax,(%esp)
80107de7:	e8 46 d0 ff ff       	call   80104e32 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107dec:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107def:	89 04 24             	mov    %eax,(%esp)
80107df2:	e8 d8 f5 ff ff       	call   801073cf <v2p>
80107df7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107dfa:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107e01:	00 
80107e02:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107e06:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e0d:	00 
80107e0e:	89 54 24 04          	mov    %edx,0x4(%esp)
80107e12:	8b 45 08             	mov    0x8(%ebp),%eax
80107e15:	89 04 24             	mov    %eax,(%esp)
80107e18:	e8 d8 fa ff ff       	call   801078f5 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107e1d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107e24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e27:	3b 45 10             	cmp    0x10(%ebp),%eax
80107e2a:	0f 82 67 ff ff ff    	jb     80107d97 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80107e30:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107e33:	c9                   	leave  
80107e34:	c3                   	ret    

80107e35 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107e35:	55                   	push   %ebp
80107e36:	89 e5                	mov    %esp,%ebp
80107e38:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107e3b:	8b 45 10             	mov    0x10(%ebp),%eax
80107e3e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107e41:	72 08                	jb     80107e4b <deallocuvm+0x16>
    return oldsz;
80107e43:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e46:	e9 a4 00 00 00       	jmp    80107eef <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80107e4b:	8b 45 10             	mov    0x10(%ebp),%eax
80107e4e:	05 ff 0f 00 00       	add    $0xfff,%eax
80107e53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e58:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107e5b:	e9 80 00 00 00       	jmp    80107ee0 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107e60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e63:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107e6a:	00 
80107e6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e6f:	8b 45 08             	mov    0x8(%ebp),%eax
80107e72:	89 04 24             	mov    %eax,(%esp)
80107e75:	e8 e5 f9 ff ff       	call   8010785f <walkpgdir>
80107e7a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107e7d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107e81:	75 09                	jne    80107e8c <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80107e83:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80107e8a:	eb 4d                	jmp    80107ed9 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80107e8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e8f:	8b 00                	mov    (%eax),%eax
80107e91:	83 e0 01             	and    $0x1,%eax
80107e94:	84 c0                	test   %al,%al
80107e96:	74 41                	je     80107ed9 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80107e98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e9b:	8b 00                	mov    (%eax),%eax
80107e9d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ea2:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107ea5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107ea9:	75 0c                	jne    80107eb7 <deallocuvm+0x82>
        panic("kfree");
80107eab:	c7 04 24 0d 88 10 80 	movl   $0x8010880d,(%esp)
80107eb2:	e8 86 86 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80107eb7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107eba:	89 04 24             	mov    %eax,(%esp)
80107ebd:	e8 1a f5 ff ff       	call   801073dc <p2v>
80107ec2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80107ec5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107ec8:	89 04 24             	mov    %eax,(%esp)
80107ecb:	e8 d6 ab ff ff       	call   80102aa6 <kfree>
      *pte = 0;
80107ed0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ed3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80107ed9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107ee0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ee3:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107ee6:	0f 82 74 ff ff ff    	jb     80107e60 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80107eec:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107eef:	c9                   	leave  
80107ef0:	c3                   	ret    

80107ef1 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80107ef1:	55                   	push   %ebp
80107ef2:	89 e5                	mov    %esp,%ebp
80107ef4:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80107ef7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107efb:	75 0c                	jne    80107f09 <freevm+0x18>
    panic("freevm: no pgdir");
80107efd:	c7 04 24 13 88 10 80 	movl   $0x80108813,(%esp)
80107f04:	e8 34 86 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80107f09:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f10:	00 
80107f11:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80107f18:	80 
80107f19:	8b 45 08             	mov    0x8(%ebp),%eax
80107f1c:	89 04 24             	mov    %eax,(%esp)
80107f1f:	e8 11 ff ff ff       	call   80107e35 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80107f24:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107f2b:	eb 3c                	jmp    80107f69 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80107f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f30:	c1 e0 02             	shl    $0x2,%eax
80107f33:	03 45 08             	add    0x8(%ebp),%eax
80107f36:	8b 00                	mov    (%eax),%eax
80107f38:	83 e0 01             	and    $0x1,%eax
80107f3b:	84 c0                	test   %al,%al
80107f3d:	74 26                	je     80107f65 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80107f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f42:	c1 e0 02             	shl    $0x2,%eax
80107f45:	03 45 08             	add    0x8(%ebp),%eax
80107f48:	8b 00                	mov    (%eax),%eax
80107f4a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f4f:	89 04 24             	mov    %eax,(%esp)
80107f52:	e8 85 f4 ff ff       	call   801073dc <p2v>
80107f57:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80107f5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f5d:	89 04 24             	mov    %eax,(%esp)
80107f60:	e8 41 ab ff ff       	call   80102aa6 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80107f65:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107f69:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80107f70:	76 bb                	jbe    80107f2d <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80107f72:	8b 45 08             	mov    0x8(%ebp),%eax
80107f75:	89 04 24             	mov    %eax,(%esp)
80107f78:	e8 29 ab ff ff       	call   80102aa6 <kfree>
}
80107f7d:	c9                   	leave  
80107f7e:	c3                   	ret    

80107f7f <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80107f7f:	55                   	push   %ebp
80107f80:	89 e5                	mov    %esp,%ebp
80107f82:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80107f85:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f8c:	00 
80107f8d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f90:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f94:	8b 45 08             	mov    0x8(%ebp),%eax
80107f97:	89 04 24             	mov    %eax,(%esp)
80107f9a:	e8 c0 f8 ff ff       	call   8010785f <walkpgdir>
80107f9f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80107fa2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107fa6:	75 0c                	jne    80107fb4 <clearpteu+0x35>
    panic("clearpteu");
80107fa8:	c7 04 24 24 88 10 80 	movl   $0x80108824,(%esp)
80107faf:	e8 89 85 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80107fb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fb7:	8b 00                	mov    (%eax),%eax
80107fb9:	89 c2                	mov    %eax,%edx
80107fbb:	83 e2 fb             	and    $0xfffffffb,%edx
80107fbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fc1:	89 10                	mov    %edx,(%eax)
}
80107fc3:	c9                   	leave  
80107fc4:	c3                   	ret    

80107fc5 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80107fc5:	55                   	push   %ebp
80107fc6:	89 e5                	mov    %esp,%ebp
80107fc8:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80107fcb:	e8 b9 f9 ff ff       	call   80107989 <setupkvm>
80107fd0:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107fd3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107fd7:	75 0a                	jne    80107fe3 <copyuvm+0x1e>
    return 0;
80107fd9:	b8 00 00 00 00       	mov    $0x0,%eax
80107fde:	e9 f1 00 00 00       	jmp    801080d4 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80107fe3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107fea:	e9 c0 00 00 00       	jmp    801080af <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80107fef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107ff9:	00 
80107ffa:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ffe:	8b 45 08             	mov    0x8(%ebp),%eax
80108001:	89 04 24             	mov    %eax,(%esp)
80108004:	e8 56 f8 ff ff       	call   8010785f <walkpgdir>
80108009:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010800c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108010:	75 0c                	jne    8010801e <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80108012:	c7 04 24 2e 88 10 80 	movl   $0x8010882e,(%esp)
80108019:	e8 1f 85 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
8010801e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108021:	8b 00                	mov    (%eax),%eax
80108023:	83 e0 01             	and    $0x1,%eax
80108026:	85 c0                	test   %eax,%eax
80108028:	75 0c                	jne    80108036 <copyuvm+0x71>
      panic("copyuvm: page not present");
8010802a:	c7 04 24 48 88 10 80 	movl   $0x80108848,(%esp)
80108031:	e8 07 85 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108036:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108039:	8b 00                	mov    (%eax),%eax
8010803b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108040:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80108043:	e8 f7 aa ff ff       	call   80102b3f <kalloc>
80108048:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010804b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010804f:	74 6f                	je     801080c0 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108051:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108054:	89 04 24             	mov    %eax,(%esp)
80108057:	e8 80 f3 ff ff       	call   801073dc <p2v>
8010805c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108063:	00 
80108064:	89 44 24 04          	mov    %eax,0x4(%esp)
80108068:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010806b:	89 04 24             	mov    %eax,(%esp)
8010806e:	e8 92 ce ff ff       	call   80104f05 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80108073:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108076:	89 04 24             	mov    %eax,(%esp)
80108079:	e8 51 f3 ff ff       	call   801073cf <v2p>
8010807e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108081:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108088:	00 
80108089:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010808d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108094:	00 
80108095:	89 54 24 04          	mov    %edx,0x4(%esp)
80108099:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010809c:	89 04 24             	mov    %eax,(%esp)
8010809f:	e8 51 f8 ff ff       	call   801078f5 <mappages>
801080a4:	85 c0                	test   %eax,%eax
801080a6:	78 1b                	js     801080c3 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801080a8:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801080af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b2:	3b 45 0c             	cmp    0xc(%ebp),%eax
801080b5:	0f 82 34 ff ff ff    	jb     80107fef <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801080bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080be:	eb 14                	jmp    801080d4 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801080c0:	90                   	nop
801080c1:	eb 01                	jmp    801080c4 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801080c3:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801080c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080c7:	89 04 24             	mov    %eax,(%esp)
801080ca:	e8 22 fe ff ff       	call   80107ef1 <freevm>
  return 0;
801080cf:	b8 00 00 00 00       	mov    $0x0,%eax
}
801080d4:	c9                   	leave  
801080d5:	c3                   	ret    

801080d6 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801080d6:	55                   	push   %ebp
801080d7:	89 e5                	mov    %esp,%ebp
801080d9:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801080dc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801080e3:	00 
801080e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801080e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801080eb:	8b 45 08             	mov    0x8(%ebp),%eax
801080ee:	89 04 24             	mov    %eax,(%esp)
801080f1:	e8 69 f7 ff ff       	call   8010785f <walkpgdir>
801080f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801080f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080fc:	8b 00                	mov    (%eax),%eax
801080fe:	83 e0 01             	and    $0x1,%eax
80108101:	85 c0                	test   %eax,%eax
80108103:	75 07                	jne    8010810c <uva2ka+0x36>
    return 0;
80108105:	b8 00 00 00 00       	mov    $0x0,%eax
8010810a:	eb 25                	jmp    80108131 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
8010810c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010810f:	8b 00                	mov    (%eax),%eax
80108111:	83 e0 04             	and    $0x4,%eax
80108114:	85 c0                	test   %eax,%eax
80108116:	75 07                	jne    8010811f <uva2ka+0x49>
    return 0;
80108118:	b8 00 00 00 00       	mov    $0x0,%eax
8010811d:	eb 12                	jmp    80108131 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
8010811f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108122:	8b 00                	mov    (%eax),%eax
80108124:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108129:	89 04 24             	mov    %eax,(%esp)
8010812c:	e8 ab f2 ff ff       	call   801073dc <p2v>
}
80108131:	c9                   	leave  
80108132:	c3                   	ret    

80108133 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108133:	55                   	push   %ebp
80108134:	89 e5                	mov    %esp,%ebp
80108136:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108139:	8b 45 10             	mov    0x10(%ebp),%eax
8010813c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010813f:	e9 8b 00 00 00       	jmp    801081cf <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80108144:	8b 45 0c             	mov    0xc(%ebp),%eax
80108147:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010814c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010814f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108152:	89 44 24 04          	mov    %eax,0x4(%esp)
80108156:	8b 45 08             	mov    0x8(%ebp),%eax
80108159:	89 04 24             	mov    %eax,(%esp)
8010815c:	e8 75 ff ff ff       	call   801080d6 <uva2ka>
80108161:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108164:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108168:	75 07                	jne    80108171 <copyout+0x3e>
      return -1;
8010816a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010816f:	eb 6d                	jmp    801081de <copyout+0xab>
    n = PGSIZE - (va - va0);
80108171:	8b 45 0c             	mov    0xc(%ebp),%eax
80108174:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108177:	89 d1                	mov    %edx,%ecx
80108179:	29 c1                	sub    %eax,%ecx
8010817b:	89 c8                	mov    %ecx,%eax
8010817d:	05 00 10 00 00       	add    $0x1000,%eax
80108182:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108185:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108188:	3b 45 14             	cmp    0x14(%ebp),%eax
8010818b:	76 06                	jbe    80108193 <copyout+0x60>
      n = len;
8010818d:	8b 45 14             	mov    0x14(%ebp),%eax
80108190:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108193:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108196:	8b 55 0c             	mov    0xc(%ebp),%edx
80108199:	89 d1                	mov    %edx,%ecx
8010819b:	29 c1                	sub    %eax,%ecx
8010819d:	89 c8                	mov    %ecx,%eax
8010819f:	03 45 e8             	add    -0x18(%ebp),%eax
801081a2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801081a5:	89 54 24 08          	mov    %edx,0x8(%esp)
801081a9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801081ac:	89 54 24 04          	mov    %edx,0x4(%esp)
801081b0:	89 04 24             	mov    %eax,(%esp)
801081b3:	e8 4d cd ff ff       	call   80104f05 <memmove>
    len -= n;
801081b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081bb:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801081be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081c1:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801081c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081c7:	05 00 10 00 00       	add    $0x1000,%eax
801081cc:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801081cf:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801081d3:	0f 85 6b ff ff ff    	jne    80108144 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801081d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801081de:	c9                   	leave  
801081df:	c3                   	ret    
