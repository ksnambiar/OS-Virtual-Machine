
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	e6010113          	add	sp,sp,-416 # 80008e60 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	07a000ef          	jal	80000090 <start>

000000008000001a <_entry_kernel>:
    8000001a:	6cf000ef          	jal	80000ee8 <main>

000000008000001e <_entry_test>:
    8000001e:	a001                	j	8000001e <_entry_test>

0000000080000020 <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000020:	1141                	add	sp,sp,-16
    80000022:	e422                	sd	s0,8(sp)
    80000024:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000026:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    8000002a:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002e:	0037979b          	sllw	a5,a5,0x3
    80000032:	02004737          	lui	a4,0x2004
    80000036:	97ba                	add	a5,a5,a4
    80000038:	0200c737          	lui	a4,0x200c
    8000003c:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000040:	000f4637          	lui	a2,0xf4
    80000044:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000048:	9732                	add	a4,a4,a2
    8000004a:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    8000004c:	00259693          	sll	a3,a1,0x2
    80000050:	96ae                	add	a3,a3,a1
    80000052:	068e                	sll	a3,a3,0x3
    80000054:	00009717          	auipc	a4,0x9
    80000058:	ccc70713          	add	a4,a4,-820 # 80008d20 <timer_scratch>
    8000005c:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005e:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000060:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000062:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000066:	00006797          	auipc	a5,0x6
    8000006a:	c6a78793          	add	a5,a5,-918 # 80005cd0 <timervec>
    8000006e:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000072:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000076:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007a:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007e:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000082:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000086:	30479073          	csrw	mie,a5
}
    8000008a:	6422                	ld	s0,8(sp)
    8000008c:	0141                	add	sp,sp,16
    8000008e:	8082                	ret

0000000080000090 <start>:
{
    80000090:	1141                	add	sp,sp,-16
    80000092:	e406                	sd	ra,8(sp)
    80000094:	e022                	sd	s0,0(sp)
    80000096:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000098:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    8000009c:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000009e:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000a0:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    800000a4:	7779                	lui	a4,0xffffe
    800000a6:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc46f>
    800000aa:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000ac:	6705                	lui	a4,0x1
    800000ae:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000b4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000b8:	00001797          	auipc	a5,0x1
    800000bc:	e3078793          	add	a5,a5,-464 # 80000ee8 <main>
    800000c0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000c4:	4781                	li	a5,0
    800000c6:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000ca:	57fd                	li	a5,-1
    800000cc:	83a9                	srl	a5,a5,0xa
    800000ce:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d2:	47bd                	li	a5,15
    800000d4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f48080e7          	jalr	-184(ra) # 80000020 <timerinit>
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000e0:	67c1                	lui	a5,0x10
    800000e2:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000e4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000e8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ec:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000f0:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000f4:	10479073          	csrw	sie,a5
  asm volatile("mret");
    800000f8:	30200073          	mret
}
    800000fc:	60a2                	ld	ra,8(sp)
    800000fe:	6402                	ld	s0,0(sp)
    80000100:	0141                	add	sp,sp,16
    80000102:	8082                	ret

0000000080000104 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000104:	715d                	add	sp,sp,-80
    80000106:	e486                	sd	ra,72(sp)
    80000108:	e0a2                	sd	s0,64(sp)
    8000010a:	fc26                	sd	s1,56(sp)
    8000010c:	f84a                	sd	s2,48(sp)
    8000010e:	f44e                	sd	s3,40(sp)
    80000110:	f052                	sd	s4,32(sp)
    80000112:	ec56                	sd	s5,24(sp)
    80000114:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000116:	04c05763          	blez	a2,80000164 <consolewrite+0x60>
    8000011a:	8a2a                	mv	s4,a0
    8000011c:	84ae                	mv	s1,a1
    8000011e:	89b2                	mv	s3,a2
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	add	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	42a080e7          	jalr	1066(ra) # 80002558 <either_copyin>
    80000136:	01550d63          	beq	a0,s5,80000150 <consolewrite+0x4c>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7f2080e7          	jalr	2034(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addw	s2,s2,1
    80000148:	0485                	add	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x20>
    8000014e:	894e                	mv	s2,s3
  }

  return i;
}
    80000150:	854a                	mv	a0,s2
    80000152:	60a6                	ld	ra,72(sp)
    80000154:	6406                	ld	s0,64(sp)
    80000156:	74e2                	ld	s1,56(sp)
    80000158:	7942                	ld	s2,48(sp)
    8000015a:	79a2                	ld	s3,40(sp)
    8000015c:	7a02                	ld	s4,32(sp)
    8000015e:	6ae2                	ld	s5,24(sp)
    80000160:	6161                	add	sp,sp,80
    80000162:	8082                	ret
  for(i = 0; i < n; i++){
    80000164:	4901                	li	s2,0
    80000166:	b7ed                	j	80000150 <consolewrite+0x4c>

0000000080000168 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000168:	711d                	add	sp,sp,-96
    8000016a:	ec86                	sd	ra,88(sp)
    8000016c:	e8a2                	sd	s0,80(sp)
    8000016e:	e4a6                	sd	s1,72(sp)
    80000170:	e0ca                	sd	s2,64(sp)
    80000172:	fc4e                	sd	s3,56(sp)
    80000174:	f852                	sd	s4,48(sp)
    80000176:	f456                	sd	s5,40(sp)
    80000178:	f05a                	sd	s6,32(sp)
    8000017a:	ec5e                	sd	s7,24(sp)
    8000017c:	1080                	add	s0,sp,96
    8000017e:	8aaa                	mv	s5,a0
    80000180:	8a2e                	mv	s4,a1
    80000182:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000184:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000188:	00011517          	auipc	a0,0x11
    8000018c:	cd850513          	add	a0,a0,-808 # 80010e60 <cons>
    80000190:	00001097          	auipc	ra,0x1
    80000194:	ab8080e7          	jalr	-1352(ra) # 80000c48 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00011497          	auipc	s1,0x11
    8000019c:	cc848493          	add	s1,s1,-824 # 80010e60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00011917          	auipc	s2,0x11
    800001a4:	d5890913          	add	s2,s2,-680 # 80010ef8 <cons+0x98>
  while(n > 0){
    800001a8:	09305263          	blez	s3,8000022c <consoleread+0xc4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	02f71763          	bne	a4,a5,800001e2 <consoleread+0x7a>
      if(killed(myproc())){
    800001b8:	00002097          	auipc	ra,0x2
    800001bc:	86c080e7          	jalr	-1940(ra) # 80001a24 <myproc>
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	1e2080e7          	jalr	482(ra) # 800023a2 <killed>
    800001c8:	ed2d                	bnez	a0,80000242 <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001ca:	85a6                	mv	a1,s1
    800001cc:	854a                	mv	a0,s2
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	f2c080e7          	jalr	-212(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001d6:	0984a783          	lw	a5,152(s1)
    800001da:	09c4a703          	lw	a4,156(s1)
    800001de:	fcf70de3          	beq	a4,a5,800001b8 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e2:	00011717          	auipc	a4,0x11
    800001e6:	c7e70713          	add	a4,a4,-898 # 80010e60 <cons>
    800001ea:	0017869b          	addw	a3,a5,1
    800001ee:	08d72c23          	sw	a3,152(a4)
    800001f2:	07f7f693          	and	a3,a5,127
    800001f6:	9736                	add	a4,a4,a3
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000200:	4691                	li	a3,4
    80000202:	06db8463          	beq	s7,a3,8000026a <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000206:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	faf40613          	add	a2,s0,-81
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	2ee080e7          	jalr	750(ra) # 80002502 <either_copyout>
    8000021c:	57fd                	li	a5,-1
    8000021e:	00f50763          	beq	a0,a5,8000022c <consoleread+0xc4>
      break;

    dst++;
    80000222:	0a05                	add	s4,s4,1
    --n;
    80000224:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000226:	47a9                	li	a5,10
    80000228:	f8fb90e3          	bne	s7,a5,800001a8 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	c3450513          	add	a0,a0,-972 # 80010e60 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	ac8080e7          	jalr	-1336(ra) # 80000cfc <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xec>
        release(&cons.lock);
    80000242:	00011517          	auipc	a0,0x11
    80000246:	c1e50513          	add	a0,a0,-994 # 80010e60 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	ab2080e7          	jalr	-1358(ra) # 80000cfc <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	60e6                	ld	ra,88(sp)
    80000256:	6446                	ld	s0,80(sp)
    80000258:	64a6                	ld	s1,72(sp)
    8000025a:	6906                	ld	s2,64(sp)
    8000025c:	79e2                	ld	s3,56(sp)
    8000025e:	7a42                	ld	s4,48(sp)
    80000260:	7aa2                	ld	s5,40(sp)
    80000262:	7b02                	ld	s6,32(sp)
    80000264:	6be2                	ld	s7,24(sp)
    80000266:	6125                	add	sp,sp,96
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677fe3          	bgeu	a4,s6,8000022c <consoleread+0xc4>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	c8f72323          	sw	a5,-890(a4) # 80010ef8 <cons+0x98>
    8000027a:	bf4d                	j	8000022c <consoleread+0xc4>

000000008000027c <consputc>:
{
    8000027c:	1141                	add	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	5de080e7          	jalr	1502(ra) # 8000086a <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	add	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	5cc080e7          	jalr	1484(ra) # 8000086a <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	5c0080e7          	jalr	1472(ra) # 8000086a <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5b6080e7          	jalr	1462(ra) # 8000086a <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	add	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	add	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	b9450513          	add	a0,a0,-1132 # 80010e60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	974080e7          	jalr	-1676(ra) # 80000c48 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2bc080e7          	jalr	700(ra) # 800025ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	b6650513          	add	a0,a0,-1178 # 80010e60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9fa080e7          	jalr	-1542(ra) # 80000cfc <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	add	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	b4270713          	add	a4,a4,-1214 # 80010e60 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	b1878793          	add	a5,a5,-1256 # 80010e60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	and	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	b827a783          	lw	a5,-1150(a5) # 80010ef8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	ad670713          	add	a4,a4,-1322 # 80010e60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	ac648493          	add	s1,s1,-1338 # 80010e60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addw	a5,a5,-1
    800003aa:	07f7f713          	and	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	a8a70713          	add	a4,a4,-1398 # 80010e60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	b0f72a23          	sw	a5,-1260(a4) # 80010f00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	a4e78793          	add	a5,a5,-1458 # 80010e60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	and	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	acc7a323          	sw	a2,-1338(a5) # 80010efc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	aba50513          	add	a0,a0,-1350 # 80010ef8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d18080e7          	jalr	-744(ra) # 8000215e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	add	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	add	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	a0050513          	add	a0,a0,-1536 # 80010e60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	750080e7          	jalr	1872(ra) # 80000bb8 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	3aa080e7          	jalr	938(ra) # 8000081a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	d8078793          	add	a5,a5,-640 # 800211f8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce870713          	add	a4,a4,-792 # 80000168 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7a70713          	add	a4,a4,-902 # 80000104 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	add	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	add	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	add	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	sll	a5,a5,0x20
    800004cc:	9381                	srl	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	add	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	add	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	add	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	add	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addw	a4,a4,-1
    80000512:	1702                	sll	a4,a4,0x20
    80000514:	9301                	srl	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	add	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	add	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
  //   release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	add	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	add	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	9c07aa23          	sw	zero,-1580(a5) # 80010f20 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	add	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	48250513          	add	a0,a0,1154 # 800089f0 <syscalls+0x558>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	76f72023          	sw	a5,1888(a4) # 80008ce0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	add	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	add	s0,sp,128
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  if (fmt == 0)
    800005ba:	c90d                	beqz	a0,800005ec <printf+0x62>
    800005bc:	8a2a                	mv	s4,a0
  va_start(ap, fmt);
    800005be:	00840793          	add	a5,s0,8
    800005c2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c6:	00054503          	lbu	a0,0(a0)
    800005ca:	20050063          	beqz	a0,800007ca <printf+0x240>
    800005ce:	4481                	li	s1,0
    if(c != '%'){
    800005d0:	02500b13          	li	s6,37
    switch(c){
    800005d4:	07000b93          	li	s7,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008a97          	auipc	s5,0x8
    800005dc:	a68a8a93          	add	s5,s5,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	03400c13          	li	s8,52
  } while((x /= base) != 0);
    800005e8:	4d3d                	li	s10,15
    800005ea:	a025                	j	80000612 <printf+0x88>
    panic("null fmt");
    800005ec:	00008517          	auipc	a0,0x8
    800005f0:	a3c50513          	add	a0,a0,-1476 # 80008028 <etext+0x28>
    800005f4:	00000097          	auipc	ra,0x0
    800005f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
      consputc(c);
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	c80080e7          	jalr	-896(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000604:	2485                	addw	s1,s1,1
    80000606:	009a07b3          	add	a5,s4,s1
    8000060a:	0007c503          	lbu	a0,0(a5)
    8000060e:	1a050e63          	beqz	a0,800007ca <printf+0x240>
    if(c != '%'){
    80000612:	ff6515e3          	bne	a0,s6,800005fc <printf+0x72>
    c = fmt[++i] & 0xff;
    80000616:	2485                	addw	s1,s1,1
    80000618:	009a07b3          	add	a5,s4,s1
    8000061c:	0007c783          	lbu	a5,0(a5)
    80000620:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000624:	1a078363          	beqz	a5,800007ca <printf+0x240>
    switch(c){
    80000628:	11778563          	beq	a5,s7,80000732 <printf+0x1a8>
    8000062c:	02fbee63          	bltu	s7,a5,80000668 <printf+0xde>
    80000630:	07878063          	beq	a5,s8,80000690 <printf+0x106>
    80000634:	06400713          	li	a4,100
    80000638:	02e79063          	bne	a5,a4,80000658 <printf+0xce>
      printint(va_arg(ap, int), 10, 1);
    8000063c:	f8843783          	ld	a5,-120(s0)
    80000640:	00878713          	add	a4,a5,8
    80000644:	f8e43423          	sd	a4,-120(s0)
    80000648:	4605                	li	a2,1
    8000064a:	45a9                	li	a1,10
    8000064c:	4388                	lw	a0,0(a5)
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	e4e080e7          	jalr	-434(ra) # 8000049c <printint>
      break;
    80000656:	b77d                	j	80000604 <printf+0x7a>
    switch(c){
    80000658:	15679e63          	bne	a5,s6,800007b4 <printf+0x22a>
      consputc('%');
    8000065c:	855a                	mv	a0,s6
    8000065e:	00000097          	auipc	ra,0x0
    80000662:	c1e080e7          	jalr	-994(ra) # 8000027c <consputc>
      break;
    80000666:	bf79                	j	80000604 <printf+0x7a>
    switch(c){
    80000668:	11978863          	beq	a5,s9,80000778 <printf+0x1ee>
    8000066c:	07800713          	li	a4,120
    80000670:	14e79263          	bne	a5,a4,800007b4 <printf+0x22a>
      printint(va_arg(ap, int), 16, 1);
    80000674:	f8843783          	ld	a5,-120(s0)
    80000678:	00878713          	add	a4,a5,8
    8000067c:	f8e43423          	sd	a4,-120(s0)
    80000680:	4605                	li	a2,1
    80000682:	45c1                	li	a1,16
    80000684:	4388                	lw	a0,0(a5)
    80000686:	00000097          	auipc	ra,0x0
    8000068a:	e16080e7          	jalr	-490(ra) # 8000049c <printint>
      break;
    8000068e:	bf9d                	j	80000604 <printf+0x7a>
      print4hex(va_arg(ap, int), 16, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	add	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	438c                	lw	a1,0(a5)
    x = xx;
    8000069e:	0005879b          	sext.w	a5,a1
  if(sign && (sign = xx < 0))
    800006a2:	0805c563          	bltz	a1,8000072c <printf+0x1a2>
    800006a6:	f8040693          	add	a3,s0,-128
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006aa:	4901                	li	s2,0
    buf[i++] = digits[x % base];
    800006ac:	864a                	mv	a2,s2
    800006ae:	2905                	addw	s2,s2,1
    800006b0:	00f7f713          	and	a4,a5,15
    800006b4:	9756                	add	a4,a4,s5
    800006b6:	00074703          	lbu	a4,0(a4)
    800006ba:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800006be:	0007871b          	sext.w	a4,a5
    800006c2:	0047d79b          	srlw	a5,a5,0x4
    800006c6:	0685                	add	a3,a3,1
    800006c8:	feed62e3          	bltu	s10,a4,800006ac <printf+0x122>
  if(sign)
    800006cc:	0005dc63          	bgez	a1,800006e4 <printf+0x15a>
    buf[i++] = '-';
    800006d0:	f9090793          	add	a5,s2,-112
    800006d4:	00878933          	add	s2,a5,s0
    800006d8:	02d00793          	li	a5,45
    800006dc:	fef90823          	sb	a5,-16(s2)
    800006e0:	0026091b          	addw	s2,a2,2
  for (int p=4-i; p>=0; p--)
    800006e4:	4991                	li	s3,4
    800006e6:	412989bb          	subw	s3,s3,s2
    800006ea:	0009cc63          	bltz	s3,80000702 <printf+0x178>
    800006ee:	5dfd                	li	s11,-1
    consputc('0');
    800006f0:	03000513          	li	a0,48
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
  for (int p=4-i; p>=0; p--)
    800006fc:	39fd                	addw	s3,s3,-1
    800006fe:	ffb999e3          	bne	s3,s11,800006f0 <printf+0x166>
  while(--i >= 0)
    80000702:	fff9099b          	addw	s3,s2,-1
    80000706:	f609c7e3          	bltz	s3,80000674 <printf+0xea>
    8000070a:	f9090793          	add	a5,s2,-112
    8000070e:	00878933          	add	s2,a5,s0
    80000712:	193d                	add	s2,s2,-17
    80000714:	5dfd                	li	s11,-1
    consputc(buf[i]);
    80000716:	00094503          	lbu	a0,0(s2)
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000722:	39fd                	addw	s3,s3,-1
    80000724:	197d                	add	s2,s2,-1
    80000726:	ffb998e3          	bne	s3,s11,80000716 <printf+0x18c>
    8000072a:	b7a9                	j	80000674 <printf+0xea>
    x = -xx;
    8000072c:	40b007bb          	negw	a5,a1
    80000730:	bf9d                	j	800006a6 <printf+0x11c>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	add	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b36080e7          	jalr	-1226(ra) # 8000027c <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b2a080e7          	jalr	-1238(ra) # 8000027c <consputc>
    8000075a:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c9d793          	srl	a5,s3,0x3c
    80000760:	97d6                	add	a5,a5,s5
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b16080e7          	jalr	-1258(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0992                	sll	s3,s3,0x4
    80000770:	397d                	addw	s2,s2,-1
    80000772:	fe0915e3          	bnez	s2,8000075c <printf+0x1d2>
    80000776:	b579                	j	80000604 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    80000778:	f8843783          	ld	a5,-120(s0)
    8000077c:	00878713          	add	a4,a5,8
    80000780:	f8e43423          	sd	a4,-120(s0)
    80000784:	0007b903          	ld	s2,0(a5)
    80000788:	00090f63          	beqz	s2,800007a6 <printf+0x21c>
      for(; *s; s++)
    8000078c:	00094503          	lbu	a0,0(s2)
    80000790:	e6050ae3          	beqz	a0,80000604 <printf+0x7a>
        consputc(*s);
    80000794:	00000097          	auipc	ra,0x0
    80000798:	ae8080e7          	jalr	-1304(ra) # 8000027c <consputc>
      for(; *s; s++)
    8000079c:	0905                	add	s2,s2,1
    8000079e:	00094503          	lbu	a0,0(s2)
    800007a2:	f96d                	bnez	a0,80000794 <printf+0x20a>
    800007a4:	b585                	j	80000604 <printf+0x7a>
        s = "(null)";
    800007a6:	00008917          	auipc	s2,0x8
    800007aa:	87a90913          	add	s2,s2,-1926 # 80008020 <etext+0x20>
      for(; *s; s++)
    800007ae:	02800513          	li	a0,40
    800007b2:	b7cd                	j	80000794 <printf+0x20a>
      consputc('%');
    800007b4:	855a                	mv	a0,s6
    800007b6:	00000097          	auipc	ra,0x0
    800007ba:	ac6080e7          	jalr	-1338(ra) # 8000027c <consputc>
      consputc(c);
    800007be:	854a                	mv	a0,s2
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	abc080e7          	jalr	-1348(ra) # 8000027c <consputc>
      break;
    800007c8:	bd35                	j	80000604 <printf+0x7a>
}
    800007ca:	70e6                	ld	ra,120(sp)
    800007cc:	7446                	ld	s0,112(sp)
    800007ce:	74a6                	ld	s1,104(sp)
    800007d0:	7906                	ld	s2,96(sp)
    800007d2:	69e6                	ld	s3,88(sp)
    800007d4:	6a46                	ld	s4,80(sp)
    800007d6:	6aa6                	ld	s5,72(sp)
    800007d8:	6b06                	ld	s6,64(sp)
    800007da:	7be2                	ld	s7,56(sp)
    800007dc:	7c42                	ld	s8,48(sp)
    800007de:	7ca2                	ld	s9,40(sp)
    800007e0:	7d02                	ld	s10,32(sp)
    800007e2:	6de2                	ld	s11,24(sp)
    800007e4:	6129                	add	sp,sp,192
    800007e6:	8082                	ret

00000000800007e8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007e8:	1101                	add	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    800007f2:	00010497          	auipc	s1,0x10
    800007f6:	71648493          	add	s1,s1,1814 # 80010f08 <pr>
    800007fa:	00008597          	auipc	a1,0x8
    800007fe:	83e58593          	add	a1,a1,-1986 # 80008038 <etext+0x38>
    80000802:	8526                	mv	a0,s1
    80000804:	00000097          	auipc	ra,0x0
    80000808:	3b4080e7          	jalr	948(ra) # 80000bb8 <initlock>
  pr.locking = 1;
    8000080c:	4785                	li	a5,1
    8000080e:	cc9c                	sw	a5,24(s1)
}
    80000810:	60e2                	ld	ra,24(sp)
    80000812:	6442                	ld	s0,16(sp)
    80000814:	64a2                	ld	s1,8(sp)
    80000816:	6105                	add	sp,sp,32
    80000818:	8082                	ret

000000008000081a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081a:	1141                	add	sp,sp,-16
    8000081c:	e406                	sd	ra,8(sp)
    8000081e:	e022                	sd	s0,0(sp)
    80000820:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082a:	f8000713          	li	a4,-128
    8000082e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000832:	470d                	li	a4,3
    80000834:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000838:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000083c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000840:	469d                	li	a3,7
    80000842:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000846:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084a:	00008597          	auipc	a1,0x8
    8000084e:	80e58593          	add	a1,a1,-2034 # 80008058 <digits+0x18>
    80000852:	00010517          	auipc	a0,0x10
    80000856:	6d650513          	add	a0,a0,1750 # 80010f28 <uart_tx_lock>
    8000085a:	00000097          	auipc	ra,0x0
    8000085e:	35e080e7          	jalr	862(ra) # 80000bb8 <initlock>
}
    80000862:	60a2                	ld	ra,8(sp)
    80000864:	6402                	ld	s0,0(sp)
    80000866:	0141                	add	sp,sp,16
    80000868:	8082                	ret

000000008000086a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000086a:	1101                	add	sp,sp,-32
    8000086c:	ec06                	sd	ra,24(sp)
    8000086e:	e822                	sd	s0,16(sp)
    80000870:	e426                	sd	s1,8(sp)
    80000872:	1000                	add	s0,sp,32
    80000874:	84aa                	mv	s1,a0
  push_off();
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	386080e7          	jalr	902(ra) # 80000bfc <push_off>
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087e:	10000737          	lui	a4,0x10000
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0207f793          	and	a5,a5,32
    8000088a:	dfe5                	beqz	a5,80000882 <uartputc_sync+0x18>
    ;
  WriteReg(THR, c);
    8000088c:	0ff4f493          	zext.b	s1,s1
    80000890:	100007b7          	lui	a5,0x10000
    80000894:	00978023          	sb	s1,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	404080e7          	jalr	1028(ra) # 80000c9c <pop_off>
}
    800008a0:	60e2                	ld	ra,24(sp)
    800008a2:	6442                	ld	s0,16(sp)
    800008a4:	64a2                	ld	s1,8(sp)
    800008a6:	6105                	add	sp,sp,32
    800008a8:	8082                	ret

00000000800008aa <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008aa:	00008797          	auipc	a5,0x8
    800008ae:	43e7b783          	ld	a5,1086(a5) # 80008ce8 <uart_tx_r>
    800008b2:	00008717          	auipc	a4,0x8
    800008b6:	43e73703          	ld	a4,1086(a4) # 80008cf0 <uart_tx_w>
    800008ba:	06f70a63          	beq	a4,a5,8000092e <uartstart+0x84>
{
    800008be:	7139                	add	sp,sp,-64
    800008c0:	fc06                	sd	ra,56(sp)
    800008c2:	f822                	sd	s0,48(sp)
    800008c4:	f426                	sd	s1,40(sp)
    800008c6:	f04a                	sd	s2,32(sp)
    800008c8:	ec4e                	sd	s3,24(sp)
    800008ca:	e852                	sd	s4,16(sp)
    800008cc:	e456                	sd	s5,8(sp)
    800008ce:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d0:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008d4:	00010a17          	auipc	s4,0x10
    800008d8:	654a0a13          	add	s4,s4,1620 # 80010f28 <uart_tx_lock>
    uart_tx_r += 1;
    800008dc:	00008497          	auipc	s1,0x8
    800008e0:	40c48493          	add	s1,s1,1036 # 80008ce8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e4:	00008997          	auipc	s3,0x8
    800008e8:	40c98993          	add	s3,s3,1036 # 80008cf0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ec:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f0:	02077713          	and	a4,a4,32
    800008f4:	c705                	beqz	a4,8000091c <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008f6:	01f7f713          	and	a4,a5,31
    800008fa:	9752                	add	a4,a4,s4
    800008fc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000900:	0785                	add	a5,a5,1
    80000902:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	858080e7          	jalr	-1960(ra) # 8000215e <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	609c                	ld	a5,0(s1)
    80000914:	0009b703          	ld	a4,0(s3)
    80000918:	fcf71ae3          	bne	a4,a5,800008ec <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	add	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	add	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	add	s0,sp,48
    80000940:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000942:	00010517          	auipc	a0,0x10
    80000946:	5e650513          	add	a0,a0,1510 # 80010f28 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	2fe080e7          	jalr	766(ra) # 80000c48 <acquire>
  if(panicked){
    80000952:	00008797          	auipc	a5,0x8
    80000956:	38e7a783          	lw	a5,910(a5) # 80008ce0 <panicked>
    8000095a:	e7c9                	bnez	a5,800009e4 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000095c:	00008717          	auipc	a4,0x8
    80000960:	39473703          	ld	a4,916(a4) # 80008cf0 <uart_tx_w>
    80000964:	00008797          	auipc	a5,0x8
    80000968:	3847b783          	ld	a5,900(a5) # 80008ce8 <uart_tx_r>
    8000096c:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000970:	00010997          	auipc	s3,0x10
    80000974:	5b898993          	add	s3,s3,1464 # 80010f28 <uart_tx_lock>
    80000978:	00008497          	auipc	s1,0x8
    8000097c:	37048493          	add	s1,s1,880 # 80008ce8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000980:	00008917          	auipc	s2,0x8
    80000984:	37090913          	add	s2,s2,880 # 80008cf0 <uart_tx_w>
    80000988:	00e79f63          	bne	a5,a4,800009a6 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000098c:	85ce                	mv	a1,s3
    8000098e:	8526                	mv	a0,s1
    80000990:	00001097          	auipc	ra,0x1
    80000994:	76a080e7          	jalr	1898(ra) # 800020fa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000998:	00093703          	ld	a4,0(s2)
    8000099c:	609c                	ld	a5,0(s1)
    8000099e:	02078793          	add	a5,a5,32
    800009a2:	fee785e3          	beq	a5,a4,8000098c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    800009a6:	00010497          	auipc	s1,0x10
    800009aa:	58248493          	add	s1,s1,1410 # 80010f28 <uart_tx_lock>
    800009ae:	01f77793          	and	a5,a4,31
    800009b2:	97a6                	add	a5,a5,s1
    800009b4:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009b8:	0705                	add	a4,a4,1
    800009ba:	00008797          	auipc	a5,0x8
    800009be:	32e7bb23          	sd	a4,822(a5) # 80008cf0 <uart_tx_w>
  uartstart();
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	ee8080e7          	jalr	-280(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    800009ca:	8526                	mv	a0,s1
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	330080e7          	jalr	816(ra) # 80000cfc <release>
}
    800009d4:	70a2                	ld	ra,40(sp)
    800009d6:	7402                	ld	s0,32(sp)
    800009d8:	64e2                	ld	s1,24(sp)
    800009da:	6942                	ld	s2,16(sp)
    800009dc:	69a2                	ld	s3,8(sp)
    800009de:	6a02                	ld	s4,0(sp)
    800009e0:	6145                	add	sp,sp,48
    800009e2:	8082                	ret
    for(;;)
    800009e4:	a001                	j	800009e4 <uartputc+0xb4>

00000000800009e6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009e6:	1141                	add	sp,sp,-16
    800009e8:	e422                	sd	s0,8(sp)
    800009ea:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009f4:	8b85                	and	a5,a5,1
    800009f6:	cb81                	beqz	a5,80000a06 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009f8:	100007b7          	lui	a5,0x10000
    800009fc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000a00:	6422                	ld	s0,8(sp)
    80000a02:	0141                	add	sp,sp,16
    80000a04:	8082                	ret
    return -1;
    80000a06:	557d                	li	a0,-1
    80000a08:	bfe5                	j	80000a00 <uartgetc+0x1a>

0000000080000a0a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000a0a:	1101                	add	sp,sp,-32
    80000a0c:	ec06                	sd	ra,24(sp)
    80000a0e:	e822                	sd	s0,16(sp)
    80000a10:	e426                	sd	s1,8(sp)
    80000a12:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a14:	54fd                	li	s1,-1
    80000a16:	a029                	j	80000a20 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	8a6080e7          	jalr	-1882(ra) # 800002be <consoleintr>
    int c = uartgetc();
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	fc6080e7          	jalr	-58(ra) # 800009e6 <uartgetc>
    if(c == -1)
    80000a28:	fe9518e3          	bne	a0,s1,80000a18 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a2c:	00010497          	auipc	s1,0x10
    80000a30:	4fc48493          	add	s1,s1,1276 # 80010f28 <uart_tx_lock>
    80000a34:	8526                	mv	a0,s1
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	212080e7          	jalr	530(ra) # 80000c48 <acquire>
  uartstart();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	e6c080e7          	jalr	-404(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    80000a46:	8526                	mv	a0,s1
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	2b4080e7          	jalr	692(ra) # 80000cfc <release>
}
    80000a50:	60e2                	ld	ra,24(sp)
    80000a52:	6442                	ld	s0,16(sp)
    80000a54:	64a2                	ld	s1,8(sp)
    80000a56:	6105                	add	sp,sp,32
    80000a58:	8082                	ret

0000000080000a5a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a5a:	1101                	add	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	e04a                	sd	s2,0(sp)
    80000a64:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a66:	03451793          	sll	a5,a0,0x34
    80000a6a:	ebb9                	bnez	a5,80000ac0 <kfree+0x66>
    80000a6c:	84aa                	mv	s1,a0
    80000a6e:	00022797          	auipc	a5,0x22
    80000a72:	92278793          	add	a5,a5,-1758 # 80022390 <end>
    80000a76:	04f56563          	bltu	a0,a5,80000ac0 <kfree+0x66>
    80000a7a:	47c5                	li	a5,17
    80000a7c:	07ee                	sll	a5,a5,0x1b
    80000a7e:	04f57163          	bgeu	a0,a5,80000ac0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a82:	6605                	lui	a2,0x1
    80000a84:	4585                	li	a1,1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	2be080e7          	jalr	702(ra) # 80000d44 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a8e:	00010917          	auipc	s2,0x10
    80000a92:	4d290913          	add	s2,s2,1234 # 80010f60 <kmem>
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	1b0080e7          	jalr	432(ra) # 80000c48 <acquire>
  r->next = kmem.freelist;
    80000aa0:	01893783          	ld	a5,24(s2)
    80000aa4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aa6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aaa:	854a                	mv	a0,s2
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	250080e7          	jalr	592(ra) # 80000cfc <release>
}
    80000ab4:	60e2                	ld	ra,24(sp)
    80000ab6:	6442                	ld	s0,16(sp)
    80000ab8:	64a2                	ld	s1,8(sp)
    80000aba:	6902                	ld	s2,0(sp)
    80000abc:	6105                	add	sp,sp,32
    80000abe:	8082                	ret
    panic("kfree");
    80000ac0:	00007517          	auipc	a0,0x7
    80000ac4:	5a050513          	add	a0,a0,1440 # 80008060 <digits+0x20>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	a78080e7          	jalr	-1416(ra) # 80000540 <panic>

0000000080000ad0 <freerange>:
{
    80000ad0:	7179                	add	sp,sp,-48
    80000ad2:	f406                	sd	ra,40(sp)
    80000ad4:	f022                	sd	s0,32(sp)
    80000ad6:	ec26                	sd	s1,24(sp)
    80000ad8:	e84a                	sd	s2,16(sp)
    80000ada:	e44e                	sd	s3,8(sp)
    80000adc:	e052                	sd	s4,0(sp)
    80000ade:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae0:	6785                	lui	a5,0x1
    80000ae2:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae6:	00e504b3          	add	s1,a0,a4
    80000aea:	777d                	lui	a4,0xfffff
    80000aec:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3c>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f5c080e7          	jalr	-164(ra) # 80000a5a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x2a>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	add	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	1141                	add	sp,sp,-16
    80000b1e:	e406                	sd	ra,8(sp)
    80000b20:	e022                	sd	s0,0(sp)
    80000b22:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b24:	00007597          	auipc	a1,0x7
    80000b28:	54458593          	add	a1,a1,1348 # 80008068 <digits+0x28>
    80000b2c:	00010517          	auipc	a0,0x10
    80000b30:	43450513          	add	a0,a0,1076 # 80010f60 <kmem>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	084080e7          	jalr	132(ra) # 80000bb8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b3c:	45c5                	li	a1,17
    80000b3e:	05ee                	sll	a1,a1,0x1b
    80000b40:	00022517          	auipc	a0,0x22
    80000b44:	85050513          	add	a0,a0,-1968 # 80022390 <end>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f88080e7          	jalr	-120(ra) # 80000ad0 <freerange>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	add	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	1101                	add	sp,sp,-32
    80000b5a:	ec06                	sd	ra,24(sp)
    80000b5c:	e822                	sd	s0,16(sp)
    80000b5e:	e426                	sd	s1,8(sp)
    80000b60:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b62:	00010497          	auipc	s1,0x10
    80000b66:	3fe48493          	add	s1,s1,1022 # 80010f60 <kmem>
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	0dc080e7          	jalr	220(ra) # 80000c48 <acquire>
  r = kmem.freelist;
    80000b74:	6c84                	ld	s1,24(s1)
  if(r)
    80000b76:	c885                	beqz	s1,80000ba6 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b78:	609c                	ld	a5,0(s1)
    80000b7a:	00010517          	auipc	a0,0x10
    80000b7e:	3e650513          	add	a0,a0,998 # 80010f60 <kmem>
    80000b82:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	178080e7          	jalr	376(ra) # 80000cfc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b8c:	6605                	lui	a2,0x1
    80000b8e:	4595                	li	a1,5
    80000b90:	8526                	mv	a0,s1
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	1b2080e7          	jalr	434(ra) # 80000d44 <memset>
  return (void*)r;
}
    80000b9a:	8526                	mv	a0,s1
    80000b9c:	60e2                	ld	ra,24(sp)
    80000b9e:	6442                	ld	s0,16(sp)
    80000ba0:	64a2                	ld	s1,8(sp)
    80000ba2:	6105                	add	sp,sp,32
    80000ba4:	8082                	ret
  release(&kmem.lock);
    80000ba6:	00010517          	auipc	a0,0x10
    80000baa:	3ba50513          	add	a0,a0,954 # 80010f60 <kmem>
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	14e080e7          	jalr	334(ra) # 80000cfc <release>
  if(r)
    80000bb6:	b7d5                	j	80000b9a <kalloc+0x42>

0000000080000bb8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bb8:	1141                	add	sp,sp,-16
    80000bba:	e422                	sd	s0,8(sp)
    80000bbc:	0800                	add	s0,sp,16
  lk->name = name;
    80000bbe:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bc4:	00053823          	sd	zero,16(a0)
}
    80000bc8:	6422                	ld	s0,8(sp)
    80000bca:	0141                	add	sp,sp,16
    80000bcc:	8082                	ret

0000000080000bce <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bce:	411c                	lw	a5,0(a0)
    80000bd0:	e399                	bnez	a5,80000bd6 <holding+0x8>
    80000bd2:	4501                	li	a0,0
  return r;
}
    80000bd4:	8082                	ret
{
    80000bd6:	1101                	add	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	6904                	ld	s1,16(a0)
    80000be2:	00001097          	auipc	ra,0x1
    80000be6:	e26080e7          	jalr	-474(ra) # 80001a08 <mycpu>
    80000bea:	40a48533          	sub	a0,s1,a0
    80000bee:	00153513          	seqz	a0,a0
}
    80000bf2:	60e2                	ld	ra,24(sp)
    80000bf4:	6442                	ld	s0,16(sp)
    80000bf6:	64a2                	ld	s1,8(sp)
    80000bf8:	6105                	add	sp,sp,32
    80000bfa:	8082                	ret

0000000080000bfc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bfc:	1101                	add	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c06:	100024f3          	csrr	s1,sstatus
    80000c0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c0e:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c10:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	df4080e7          	jalr	-524(ra) # 80001a08 <mycpu>
    80000c1c:	5d3c                	lw	a5,120(a0)
    80000c1e:	cf89                	beqz	a5,80000c38 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	de8080e7          	jalr	-536(ra) # 80001a08 <mycpu>
    80000c28:	5d3c                	lw	a5,120(a0)
    80000c2a:	2785                	addw	a5,a5,1
    80000c2c:	dd3c                	sw	a5,120(a0)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	add	sp,sp,32
    80000c36:	8082                	ret
    mycpu()->intena = old;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dd0080e7          	jalr	-560(ra) # 80001a08 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c40:	8085                	srl	s1,s1,0x1
    80000c42:	8885                	and	s1,s1,1
    80000c44:	dd64                	sw	s1,124(a0)
    80000c46:	bfe9                	j	80000c20 <push_off+0x24>

0000000080000c48 <acquire>:
{
    80000c48:	1101                	add	sp,sp,-32
    80000c4a:	ec06                	sd	ra,24(sp)
    80000c4c:	e822                	sd	s0,16(sp)
    80000c4e:	e426                	sd	s1,8(sp)
    80000c50:	1000                	add	s0,sp,32
    80000c52:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	fa8080e7          	jalr	-88(ra) # 80000bfc <push_off>
  if(holding(lk))
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	f70080e7          	jalr	-144(ra) # 80000bce <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c66:	4705                	li	a4,1
  if(holding(lk))
    80000c68:	e115                	bnez	a0,80000c8c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6a:	87ba                	mv	a5,a4
    80000c6c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c70:	2781                	sext.w	a5,a5
    80000c72:	ffe5                	bnez	a5,80000c6a <acquire+0x22>
  __sync_synchronize();
    80000c74:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	d90080e7          	jalr	-624(ra) # 80001a08 <mycpu>
    80000c80:	e888                	sd	a0,16(s1)
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	add	sp,sp,32
    80000c8a:	8082                	ret
    panic("acquire");
    80000c8c:	00007517          	auipc	a0,0x7
    80000c90:	3e450513          	add	a0,a0,996 # 80008070 <digits+0x30>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>

0000000080000c9c <pop_off>:

void
pop_off(void)
{
    80000c9c:	1141                	add	sp,sp,-16
    80000c9e:	e406                	sd	ra,8(sp)
    80000ca0:	e022                	sd	s0,0(sp)
    80000ca2:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d64080e7          	jalr	-668(ra) # 80001a08 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb0:	8b89                	and	a5,a5,2
  if(intr_get())
    80000cb2:	e78d                	bnez	a5,80000cdc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	02f05b63          	blez	a5,80000cec <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cba:	37fd                	addw	a5,a5,-1
    80000cbc:	0007871b          	sext.w	a4,a5
    80000cc0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cc2:	eb09                	bnez	a4,80000cd4 <pop_off+0x38>
    80000cc4:	5d7c                	lw	a5,124(a0)
    80000cc6:	c799                	beqz	a5,80000cd4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ccc:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cd4:	60a2                	ld	ra,8(sp)
    80000cd6:	6402                	ld	s0,0(sp)
    80000cd8:	0141                	add	sp,sp,16
    80000cda:	8082                	ret
    panic("pop_off - interruptible");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39c50513          	add	a0,a0,924 # 80008078 <digits+0x38>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	85c080e7          	jalr	-1956(ra) # 80000540 <panic>
    panic("pop_off");
    80000cec:	00007517          	auipc	a0,0x7
    80000cf0:	3a450513          	add	a0,a0,932 # 80008090 <digits+0x50>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>

0000000080000cfc <release>:
{
    80000cfc:	1101                	add	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	add	s0,sp,32
    80000d06:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	ec6080e7          	jalr	-314(ra) # 80000bce <holding>
    80000d10:	c115                	beqz	a0,80000d34 <release+0x38>
  lk->cpu = 0;
    80000d12:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d16:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f7a080e7          	jalr	-134(ra) # 80000c9c <pop_off>
}
    80000d2a:	60e2                	ld	ra,24(sp)
    80000d2c:	6442                	ld	s0,16(sp)
    80000d2e:	64a2                	ld	s1,8(sp)
    80000d30:	6105                	add	sp,sp,32
    80000d32:	8082                	ret
    panic("release");
    80000d34:	00007517          	auipc	a0,0x7
    80000d38:	36450513          	add	a0,a0,868 # 80008098 <digits+0x58>
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	804080e7          	jalr	-2044(ra) # 80000540 <panic>

0000000080000d44 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d44:	1141                	add	sp,sp,-16
    80000d46:	e422                	sd	s0,8(sp)
    80000d48:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d4a:	ca19                	beqz	a2,80000d60 <memset+0x1c>
    80000d4c:	87aa                	mv	a5,a0
    80000d4e:	1602                	sll	a2,a2,0x20
    80000d50:	9201                	srl	a2,a2,0x20
    80000d52:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d56:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d5a:	0785                	add	a5,a5,1
    80000d5c:	fee79de3          	bne	a5,a4,80000d56 <memset+0x12>
  }
  return dst;
}
    80000d60:	6422                	ld	s0,8(sp)
    80000d62:	0141                	add	sp,sp,16
    80000d64:	8082                	ret

0000000080000d66 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d66:	1141                	add	sp,sp,-16
    80000d68:	e422                	sd	s0,8(sp)
    80000d6a:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d6c:	ca05                	beqz	a2,80000d9c <memcmp+0x36>
    80000d6e:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d72:	1682                	sll	a3,a3,0x20
    80000d74:	9281                	srl	a3,a3,0x20
    80000d76:	0685                	add	a3,a3,1
    80000d78:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d7a:	00054783          	lbu	a5,0(a0)
    80000d7e:	0005c703          	lbu	a4,0(a1)
    80000d82:	00e79863          	bne	a5,a4,80000d92 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d86:	0505                	add	a0,a0,1
    80000d88:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d8a:	fed518e3          	bne	a0,a3,80000d7a <memcmp+0x14>
  }

  return 0;
    80000d8e:	4501                	li	a0,0
    80000d90:	a019                	j	80000d96 <memcmp+0x30>
      return *s1 - *s2;
    80000d92:	40e7853b          	subw	a0,a5,a4
}
    80000d96:	6422                	ld	s0,8(sp)
    80000d98:	0141                	add	sp,sp,16
    80000d9a:	8082                	ret
  return 0;
    80000d9c:	4501                	li	a0,0
    80000d9e:	bfe5                	j	80000d96 <memcmp+0x30>

0000000080000da0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da0:	1141                	add	sp,sp,-16
    80000da2:	e422                	sd	s0,8(sp)
    80000da4:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000da6:	c205                	beqz	a2,80000dc6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da8:	02a5e263          	bltu	a1,a0,80000dcc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dac:	1602                	sll	a2,a2,0x20
    80000dae:	9201                	srl	a2,a2,0x20
    80000db0:	00c587b3          	add	a5,a1,a2
{
    80000db4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000db6:	0585                	add	a1,a1,1
    80000db8:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcc71>
    80000dba:	fff5c683          	lbu	a3,-1(a1)
    80000dbe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dc2:	fef59ae3          	bne	a1,a5,80000db6 <memmove+0x16>

  return dst;
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	add	sp,sp,16
    80000dca:	8082                	ret
  if(s < d && s + n > d){
    80000dcc:	02061693          	sll	a3,a2,0x20
    80000dd0:	9281                	srl	a3,a3,0x20
    80000dd2:	00d58733          	add	a4,a1,a3
    80000dd6:	fce57be3          	bgeu	a0,a4,80000dac <memmove+0xc>
    d += n;
    80000dda:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ddc:	fff6079b          	addw	a5,a2,-1
    80000de0:	1782                	sll	a5,a5,0x20
    80000de2:	9381                	srl	a5,a5,0x20
    80000de4:	fff7c793          	not	a5,a5
    80000de8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dea:	177d                	add	a4,a4,-1
    80000dec:	16fd                	add	a3,a3,-1
    80000dee:	00074603          	lbu	a2,0(a4)
    80000df2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000df6:	fee79ae3          	bne	a5,a4,80000dea <memmove+0x4a>
    80000dfa:	b7f1                	j	80000dc6 <memmove+0x26>

0000000080000dfc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dfc:	1141                	add	sp,sp,-16
    80000dfe:	e406                	sd	ra,8(sp)
    80000e00:	e022                	sd	s0,0(sp)
    80000e02:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f9c080e7          	jalr	-100(ra) # 80000da0 <memmove>
}
    80000e0c:	60a2                	ld	ra,8(sp)
    80000e0e:	6402                	ld	s0,0(sp)
    80000e10:	0141                	add	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e14:	1141                	add	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e1a:	ce11                	beqz	a2,80000e36 <strncmp+0x22>
    80000e1c:	00054783          	lbu	a5,0(a0)
    80000e20:	cf89                	beqz	a5,80000e3a <strncmp+0x26>
    80000e22:	0005c703          	lbu	a4,0(a1)
    80000e26:	00f71a63          	bne	a4,a5,80000e3a <strncmp+0x26>
    n--, p++, q++;
    80000e2a:	367d                	addw	a2,a2,-1
    80000e2c:	0505                	add	a0,a0,1
    80000e2e:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e30:	f675                	bnez	a2,80000e1c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e32:	4501                	li	a0,0
    80000e34:	a809                	j	80000e46 <strncmp+0x32>
    80000e36:	4501                	li	a0,0
    80000e38:	a039                	j	80000e46 <strncmp+0x32>
  if(n == 0)
    80000e3a:	ca09                	beqz	a2,80000e4c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e3c:	00054503          	lbu	a0,0(a0)
    80000e40:	0005c783          	lbu	a5,0(a1)
    80000e44:	9d1d                	subw	a0,a0,a5
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	add	sp,sp,16
    80000e4a:	8082                	ret
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	bfe5                	j	80000e46 <strncmp+0x32>

0000000080000e50 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e50:	1141                	add	sp,sp,-16
    80000e52:	e422                	sd	s0,8(sp)
    80000e54:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86b2                	mv	a3,a2
    80000e5a:	367d                	addw	a2,a2,-1
    80000e5c:	00d05963          	blez	a3,80000e6e <strncpy+0x1e>
    80000e60:	0785                	add	a5,a5,1
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	fee78fa3          	sb	a4,-1(a5)
    80000e6a:	0585                	add	a1,a1,1
    80000e6c:	f775                	bnez	a4,80000e58 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e6e:	873e                	mv	a4,a5
    80000e70:	9fb5                	addw	a5,a5,a3
    80000e72:	37fd                	addw	a5,a5,-1
    80000e74:	00c05963          	blez	a2,80000e86 <strncpy+0x36>
    *s++ = 0;
    80000e78:	0705                	add	a4,a4,1
    80000e7a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e7e:	40e786bb          	subw	a3,a5,a4
    80000e82:	fed04be3          	bgtz	a3,80000e78 <strncpy+0x28>
  return os;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	add	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e8c:	1141                	add	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e92:	02c05363          	blez	a2,80000eb8 <safestrcpy+0x2c>
    80000e96:	fff6069b          	addw	a3,a2,-1
    80000e9a:	1682                	sll	a3,a3,0x20
    80000e9c:	9281                	srl	a3,a3,0x20
    80000e9e:	96ae                	add	a3,a3,a1
    80000ea0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ea2:	00d58963          	beq	a1,a3,80000eb4 <safestrcpy+0x28>
    80000ea6:	0585                	add	a1,a1,1
    80000ea8:	0785                	add	a5,a5,1
    80000eaa:	fff5c703          	lbu	a4,-1(a1)
    80000eae:	fee78fa3          	sb	a4,-1(a5)
    80000eb2:	fb65                	bnez	a4,80000ea2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eb4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	add	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <strlen>:

int
strlen(const char *s)
{
    80000ebe:	1141                	add	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ec4:	00054783          	lbu	a5,0(a0)
    80000ec8:	cf91                	beqz	a5,80000ee4 <strlen+0x26>
    80000eca:	0505                	add	a0,a0,1
    80000ecc:	87aa                	mv	a5,a0
    80000ece:	86be                	mv	a3,a5
    80000ed0:	0785                	add	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	ff65                	bnez	a4,80000ece <strlen+0x10>
    80000ed8:	40a6853b          	subw	a0,a3,a0
    80000edc:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	add	sp,sp,16
    80000ee2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ee4:	4501                	li	a0,0
    80000ee6:	bfe5                	j	80000ede <strlen+0x20>

0000000080000ee8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee8:	1141                	add	sp,sp,-16
    80000eea:	e406                	sd	ra,8(sp)
    80000eec:	e022                	sd	s0,0(sp)
    80000eee:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	b08080e7          	jalr	-1272(ra) # 800019f8 <cpuid>
    trap_and_emulate_init();

    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef8:	00008717          	auipc	a4,0x8
    80000efc:	e0070713          	add	a4,a4,-512 # 80008cf8 <started>
  if(cpuid() == 0){
    80000f00:	c139                	beqz	a0,80000f46 <main+0x5e>
    while(started == 0)
    80000f02:	431c                	lw	a5,0(a4)
    80000f04:	2781                	sext.w	a5,a5
    80000f06:	dff5                	beqz	a5,80000f02 <main+0x1a>
      ;
    __sync_synchronize();
    80000f08:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aec080e7          	jalr	-1300(ra) # 800019f8 <cpuid>
    80000f14:	85aa                	mv	a1,a0
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1a250513          	add	a0,a0,418 # 800080b8 <digits+0x78>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66c080e7          	jalr	1644(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	0e0080e7          	jalr	224(ra) # 80001006 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	7c2080e7          	jalr	1986(ra) # 800026f0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	dda080e7          	jalr	-550(ra) # 80005d10 <plicinithart>
  }

  scheduler();        
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	00a080e7          	jalr	10(ra) # 80001f48 <scheduler>
    consoleinit();
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	50a080e7          	jalr	1290(ra) # 80000450 <consoleinit>
    printfinit();
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	89a080e7          	jalr	-1894(ra) # 800007e8 <printfinit>
    printf("\n");
    80000f56:	00008517          	auipc	a0,0x8
    80000f5a:	a9a50513          	add	a0,a0,-1382 # 800089f0 <syscalls+0x558>
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	62c080e7          	jalr	1580(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f66:	00007517          	auipc	a0,0x7
    80000f6a:	13a50513          	add	a0,a0,314 # 800080a0 <digits+0x60>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	61c080e7          	jalr	1564(ra) # 8000058a <printf>
    printf("\n");
    80000f76:	00008517          	auipc	a0,0x8
    80000f7a:	a7a50513          	add	a0,a0,-1414 # 800089f0 <syscalls+0x558>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	60c080e7          	jalr	1548(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	b96080e7          	jalr	-1130(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80000f8e:	00000097          	auipc	ra,0x0
    80000f92:	32e080e7          	jalr	814(ra) # 800012bc <kvminit>
    kvminithart();   // turn on paging
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	070080e7          	jalr	112(ra) # 80001006 <kvminithart>
    procinit();      // process table
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	9a6080e7          	jalr	-1626(ra) # 80001944 <procinit>
    trapinit();      // trap vectors
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	722080e7          	jalr	1826(ra) # 800026c8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	742080e7          	jalr	1858(ra) # 800026f0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	d44080e7          	jalr	-700(ra) # 80005cfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fbe:	00005097          	auipc	ra,0x5
    80000fc2:	d52080e7          	jalr	-686(ra) # 80005d10 <plicinithart>
    binit();         // buffer cache
    80000fc6:	00002097          	auipc	ra,0x2
    80000fca:	ee2080e7          	jalr	-286(ra) # 80002ea8 <binit>
    iinit();         // inode table
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	580080e7          	jalr	1408(ra) # 8000354e <iinit>
    fileinit();      // file table
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	4f6080e7          	jalr	1270(ra) # 800044cc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	e3a080e7          	jalr	-454(ra) # 80005e18 <virtio_disk_init>
    userinit();      // first user process
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	d44080e7          	jalr	-700(ra) # 80001d2a <userinit>
    trap_and_emulate_init();
    80000fee:	00006097          	auipc	ra,0x6
    80000ff2:	ca4080e7          	jalr	-860(ra) # 80006c92 <trap_and_emulate_init>
    __sync_synchronize();
    80000ff6:	0ff0000f          	fence
    started = 1;
    80000ffa:	4785                	li	a5,1
    80000ffc:	00008717          	auipc	a4,0x8
    80001000:	cef72e23          	sw	a5,-772(a4) # 80008cf8 <started>
    80001004:	bf2d                	j	80000f3e <main+0x56>

0000000080001006 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001006:	1141                	add	sp,sp,-16
    80001008:	e422                	sd	s0,8(sp)
    8000100a:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	00008797          	auipc	a5,0x8
    80001014:	cf07b783          	ld	a5,-784(a5) # 80008d00 <kernel_pagetable>
    80001018:	83b1                	srl	a5,a5,0xc
    8000101a:	577d                	li	a4,-1
    8000101c:	177e                	sll	a4,a4,0x3f
    8000101e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001020:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001024:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	add	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102e:	7139                	add	sp,sp,-64
    80001030:	fc06                	sd	ra,56(sp)
    80001032:	f822                	sd	s0,48(sp)
    80001034:	f426                	sd	s1,40(sp)
    80001036:	f04a                	sd	s2,32(sp)
    80001038:	ec4e                	sd	s3,24(sp)
    8000103a:	e852                	sd	s4,16(sp)
    8000103c:	e456                	sd	s5,8(sp)
    8000103e:	e05a                	sd	s6,0(sp)
    80001040:	0080                	add	s0,sp,64
    80001042:	84aa                	mv	s1,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001048:	57fd                	li	a5,-1
    8000104a:	83e9                	srl	a5,a5,0x1a
    8000104c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x66>
    panic("walk");
    80001054:	00007517          	auipc	a0,0x7
    80001058:	07c50513          	add	a0,a0,124 # 800080d0 <digits+0x90>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e4080e7          	jalr	1252(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa2>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	af0080e7          	jalr	-1296(ra) # 80000b58 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6605                	lui	a2,0x1
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	ccc080e7          	jalr	-820(ra) # 80000d44 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00c4d793          	srl	a5,s1,0xc
    80001084:	07aa                	sll	a5,a5,0xa
    80001086:	0017e793          	or	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcc67>
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	and	s2,s2,511
    8000109c:	090e                	sll	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	and	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srl	s1,s1,0xa
    800010ac:	04b2                	sll	s1,s1,0xc
    800010ae:	b7c5                	j	8000108e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00c9d513          	srl	a0,s3,0xc
    800010b4:	1ff57513          	and	a0,a0,511
    800010b8:	050e                	sll	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	add	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x8e>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83e9                	srl	a5,a5,0x1a
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	add	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f44080e7          	jalr	-188(ra) # 8000102e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	and	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	add	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	83a9                	srl	a5,a5,0xa
    8000110c:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	add	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000112c:	c639                	beqz	a2,8000117a <mappages+0x64>
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	fff58993          	add	s3,a1,-1
    8000113c:	99b2                	add	s3,s3,a2
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eda080e7          	jalr	-294(ra) # 8000102e <walk>
    8000115c:	cd1d                	beqz	a0,8000119a <mappages+0x84>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	and	a5,a5,1
    80001162:	e785                	bnez	a5,8000118a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srl	s1,s1,0xc
    80001166:	04aa                	sll	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	or	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	05390063          	beq	s2,s3,800011b2 <mappages+0x9c>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x34>
    panic("mappages: size");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f5e50513          	add	a0,a0,-162 # 800080d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3be080e7          	jalr	958(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f5e50513          	add	a0,a0,-162 # 800080e8 <digits+0xa8>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3ae080e7          	jalr	942(ra) # 80000540 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	add	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x86>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	add	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	add	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f52080e7          	jalr	-174(ra) # 80001116 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	add	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00007517          	auipc	a0,0x7
    800011da:	f2250513          	add	a0,a0,-222 # 800080f8 <digits+0xb8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	362080e7          	jalr	866(ra) # 80000540 <panic>

00000000800011e6 <kvmmake>:
{
    800011e6:	1101                	add	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	966080e7          	jalr	-1690(ra) # 80000b58 <kalloc>
    800011fa:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	b44080e7          	jalr	-1212(ra) # 80000d44 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10000637          	lui	a2,0x10000
    80001210:	100005b7          	lui	a1,0x10000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10001637          	lui	a2,0x10001
    80001226:	100015b7          	lui	a1,0x10001
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f8a080e7          	jalr	-118(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	004006b7          	lui	a3,0x400
    8000123a:	0c000637          	lui	a2,0xc000
    8000123e:	0c0005b7          	lui	a1,0xc000
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f72080e7          	jalr	-142(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000124c:	00007917          	auipc	s2,0x7
    80001250:	db490913          	add	s2,s2,-588 # 80008000 <etext>
    80001254:	4729                	li	a4,10
    80001256:	80007697          	auipc	a3,0x80007
    8000125a:	daa68693          	add	a3,a3,-598 # 8000 <_entry-0x7fff8000>
    8000125e:	4605                	li	a2,1
    80001260:	067e                	sll	a2,a2,0x1f
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f50080e7          	jalr	-176(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	46c5                	li	a3,17
    80001272:	06ee                	sll	a3,a3,0x1b
    80001274:	412686b3          	sub	a3,a3,s2
    80001278:	864a                	mv	a2,s2
    8000127a:	85ca                	mv	a1,s2
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001286:	4729                	li	a4,10
    80001288:	6685                	lui	a3,0x1
    8000128a:	00006617          	auipc	a2,0x6
    8000128e:	d7660613          	add	a2,a2,-650 # 80007000 <_trampoline>
    80001292:	040005b7          	lui	a1,0x4000
    80001296:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001298:	05b2                	sll	a1,a1,0xc
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f1a080e7          	jalr	-230(ra) # 800011b6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	608080e7          	jalr	1544(ra) # 800018ae <proc_mapstacks>
}
    800012ae:	8526                	mv	a0,s1
    800012b0:	60e2                	ld	ra,24(sp)
    800012b2:	6442                	ld	s0,16(sp)
    800012b4:	64a2                	ld	s1,8(sp)
    800012b6:	6902                	ld	s2,0(sp)
    800012b8:	6105                	add	sp,sp,32
    800012ba:	8082                	ret

00000000800012bc <kvminit>:
{
    800012bc:	1141                	add	sp,sp,-16
    800012be:	e406                	sd	ra,8(sp)
    800012c0:	e022                	sd	s0,0(sp)
    800012c2:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f22080e7          	jalr	-222(ra) # 800011e6 <kvmmake>
    800012cc:	00008797          	auipc	a5,0x8
    800012d0:	a2a7ba23          	sd	a0,-1484(a5) # 80008d00 <kernel_pagetable>
}
    800012d4:	60a2                	ld	ra,8(sp)
    800012d6:	6402                	ld	s0,0(sp)
    800012d8:	0141                	add	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012dc:	715d                	add	sp,sp,-80
    800012de:	e486                	sd	ra,72(sp)
    800012e0:	e0a2                	sd	s0,64(sp)
    800012e2:	fc26                	sd	s1,56(sp)
    800012e4:	f84a                	sd	s2,48(sp)
    800012e6:	f44e                	sd	s3,40(sp)
    800012e8:	f052                	sd	s4,32(sp)
    800012ea:	ec56                	sd	s5,24(sp)
    800012ec:	e85a                	sd	s6,16(sp)
    800012ee:	e45e                	sd	s7,8(sp)
    800012f0:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f2:	03459793          	sll	a5,a1,0x34
    800012f6:	e795                	bnez	a5,80001322 <uvmunmap+0x46>
    800012f8:	8a2a                	mv	s4,a0
    800012fa:	892e                	mv	s2,a1
    800012fc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	0632                	sll	a2,a2,0xc
    80001300:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	6b05                	lui	s6,0x1
    80001308:	0735e263          	bltu	a1,s3,8000136c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130c:	60a6                	ld	ra,72(sp)
    8000130e:	6406                	ld	s0,64(sp)
    80001310:	74e2                	ld	s1,56(sp)
    80001312:	7942                	ld	s2,48(sp)
    80001314:	79a2                	ld	s3,40(sp)
    80001316:	7a02                	ld	s4,32(sp)
    80001318:	6ae2                	ld	s5,24(sp)
    8000131a:	6b42                	ld	s6,16(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
    8000131e:	6161                	add	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00007517          	auipc	a0,0x7
    80001326:	dde50513          	add	a0,a0,-546 # 80008100 <digits+0xc0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	216080e7          	jalr	534(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001332:	00007517          	auipc	a0,0x7
    80001336:	de650513          	add	a0,a0,-538 # 80008118 <digits+0xd8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	206080e7          	jalr	518(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001342:	00007517          	auipc	a0,0x7
    80001346:	de650513          	add	a0,a0,-538 # 80008128 <digits+0xe8>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00007517          	auipc	a0,0x7
    80001356:	dee50513          	add	a0,a0,-530 # 80008140 <digits+0x100>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	995a                	add	s2,s2,s6
    80001368:	fb3972e3          	bgeu	s2,s3,8000130c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ca                	mv	a1,s2
    80001370:	8552                	mv	a0,s4
    80001372:	00000097          	auipc	ra,0x0
    80001376:	cbc080e7          	jalr	-836(ra) # 8000102e <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000137e:	6108                	ld	a0,0(a0)
    80001380:	00157793          	and	a5,a0,1
    80001384:	dfdd                	beqz	a5,80001342 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff57793          	and	a5,a0,1023
    8000138a:	fd7784e3          	beq	a5,s7,80001352 <uvmunmap+0x76>
    if(do_free){
    8000138e:	fc0a8ae3          	beqz	s5,80001362 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001392:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    80001394:	0532                	sll	a0,a0,0xc
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	6c4080e7          	jalr	1732(ra) # 80000a5a <kfree>
    8000139e:	b7d1                	j	80001362 <uvmunmap+0x86>

00000000800013a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a0:	1101                	add	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	7ae080e7          	jalr	1966(ra) # 80000b58 <kalloc>
    800013b2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b4:	c519                	beqz	a0,800013c2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	98a080e7          	jalr	-1654(ra) # 80000d44 <memset>
  return pagetable;
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	add	sp,sp,32
    800013cc:	8082                	ret

00000000800013ce <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ce:	7179                	add	sp,sp,-48
    800013d0:	f406                	sd	ra,40(sp)
    800013d2:	f022                	sd	s0,32(sp)
    800013d4:	ec26                	sd	s1,24(sp)
    800013d6:	e84a                	sd	s2,16(sp)
    800013d8:	e44e                	sd	s3,8(sp)
    800013da:	e052                	sd	s4,0(sp)
    800013dc:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013de:	6785                	lui	a5,0x1
    800013e0:	04f67863          	bgeu	a2,a5,80001430 <uvmfirst+0x62>
    800013e4:	8a2a                	mv	s4,a0
    800013e6:	89ae                	mv	s3,a1
    800013e8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	76e080e7          	jalr	1902(ra) # 80000b58 <kalloc>
    800013f2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	94c080e7          	jalr	-1716(ra) # 80000d44 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001400:	4779                	li	a4,30
    80001402:	86ca                	mv	a3,s2
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	8552                	mv	a0,s4
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	d0c080e7          	jalr	-756(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    80001412:	8626                	mv	a2,s1
    80001414:	85ce                	mv	a1,s3
    80001416:	854a                	mv	a0,s2
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	988080e7          	jalr	-1656(ra) # 80000da0 <memmove>
}
    80001420:	70a2                	ld	ra,40(sp)
    80001422:	7402                	ld	s0,32(sp)
    80001424:	64e2                	ld	s1,24(sp)
    80001426:	6942                	ld	s2,16(sp)
    80001428:	69a2                	ld	s3,8(sp)
    8000142a:	6a02                	ld	s4,0(sp)
    8000142c:	6145                	add	sp,sp,48
    8000142e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001430:	00007517          	auipc	a0,0x7
    80001434:	d2850513          	add	a0,a0,-728 # 80008158 <digits+0x118>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	108080e7          	jalr	264(ra) # 80000540 <panic>

0000000080001440 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001440:	1101                	add	sp,sp,-32
    80001442:	ec06                	sd	ra,24(sp)
    80001444:	e822                	sd	s0,16(sp)
    80001446:	e426                	sd	s1,8(sp)
    80001448:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144c:	00b67d63          	bgeu	a2,a1,80001466 <uvmdealloc+0x26>
    80001450:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001452:	6785                	lui	a5,0x1
    80001454:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001456:	00f60733          	add	a4,a2,a5
    8000145a:	76fd                	lui	a3,0xfffff
    8000145c:	8f75                	and	a4,a4,a3
    8000145e:	97ae                	add	a5,a5,a1
    80001460:	8ff5                	and	a5,a5,a3
    80001462:	00f76863          	bltu	a4,a5,80001472 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	add	sp,sp,32
    80001470:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001472:	8f99                	sub	a5,a5,a4
    80001474:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001476:	4685                	li	a3,1
    80001478:	0007861b          	sext.w	a2,a5
    8000147c:	85ba                	mv	a1,a4
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	e5e080e7          	jalr	-418(ra) # 800012dc <uvmunmap>
    80001486:	b7c5                	j	80001466 <uvmdealloc+0x26>

0000000080001488 <uvmalloc>:
  if(newsz < oldsz)
    80001488:	0ab66563          	bltu	a2,a1,80001532 <uvmalloc+0xaa>
{
    8000148c:	7139                	add	sp,sp,-64
    8000148e:	fc06                	sd	ra,56(sp)
    80001490:	f822                	sd	s0,48(sp)
    80001492:	f426                	sd	s1,40(sp)
    80001494:	f04a                	sd	s2,32(sp)
    80001496:	ec4e                	sd	s3,24(sp)
    80001498:	e852                	sd	s4,16(sp)
    8000149a:	e456                	sd	s5,8(sp)
    8000149c:	e05a                	sd	s6,0(sp)
    8000149e:	0080                	add	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a8:	95be                	add	a1,a1,a5
    800014aa:	77fd                	lui	a5,0xfffff
    800014ac:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f363          	bgeu	s3,a2,80001536 <uvmalloc+0xae>
    800014b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	69e080e7          	jalr	1694(ra) # 80000b58 <kalloc>
    800014c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c4:	c51d                	beqz	a0,800014f2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	87a080e7          	jalr	-1926(ra) # 80000d44 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	875a                	mv	a4,s6
    800014d4:	86a6                	mv	a3,s1
    800014d6:	6605                	lui	a2,0x1
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	c3a080e7          	jalr	-966(ra) # 80001116 <mappages>
    800014e4:	e90d                	bnez	a0,80001516 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	6785                	lui	a5,0x1
    800014e8:	993e                	add	s2,s2,a5
    800014ea:	fd4968e3          	bltu	s2,s4,800014ba <uvmalloc+0x32>
  return newsz;
    800014ee:	8552                	mv	a0,s4
    800014f0:	a809                	j	80001502 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f48080e7          	jalr	-184(ra) # 80001440 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
}
    80001502:	70e2                	ld	ra,56(sp)
    80001504:	7442                	ld	s0,48(sp)
    80001506:	74a2                	ld	s1,40(sp)
    80001508:	7902                	ld	s2,32(sp)
    8000150a:	69e2                	ld	s3,24(sp)
    8000150c:	6a42                	ld	s4,16(sp)
    8000150e:	6aa2                	ld	s5,8(sp)
    80001510:	6b02                	ld	s6,0(sp)
    80001512:	6121                	add	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	542080e7          	jalr	1346(ra) # 80000a5a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f1a080e7          	jalr	-230(ra) # 80001440 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfc9                	j	80001502 <uvmalloc+0x7a>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7e9                	j	80001502 <uvmalloc+0x7a>

000000008000153a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153a:	7179                	add	sp,sp,-48
    8000153c:	f406                	sd	ra,40(sp)
    8000153e:	f022                	sd	s0,32(sp)
    80001540:	ec26                	sd	s1,24(sp)
    80001542:	e84a                	sd	s2,16(sp)
    80001544:	e44e                	sd	s3,8(sp)
    80001546:	e052                	sd	s4,0(sp)
    80001548:	1800                	add	s0,sp,48
    8000154a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154c:	84aa                	mv	s1,a0
    8000154e:	6905                	lui	s2,0x1
    80001550:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	4985                	li	s3,1
    80001554:	a829                	j	8000156e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001558:	00c79513          	sll	a0,a5,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fde080e7          	jalr	-34(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	add	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f7f713          	and	a4,a5,15
    80001574:	ff3701e3          	beq	a4,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8b85                	and	a5,a5,1
    8000157a:	d7fd                	beqz	a5,80001568 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bfc50513          	add	a0,a0,-1028 # 80008178 <digits+0x138>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fbc080e7          	jalr	-68(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	4cc080e7          	jalr	1228(ra) # 80000a5a <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	add	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	add	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	add	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f84080e7          	jalr	-124(ra) # 8000153a <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	add	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6785                	lui	a5,0x1
    800015ca:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015cc:	95be                	add	a1,a1,a5
    800015ce:	4685                	li	a3,1
    800015d0:	00c5d613          	srl	a2,a1,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d06080e7          	jalr	-762(ra) # 800012dc <uvmunmap>
    800015de:	bfd9                	j	800015b4 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	add	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	add	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	a28080e7          	jalr	-1496(ra) # 8000102e <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	and	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srl	a1,a4,0xa
    8000161c:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	534080e7          	jalr	1332(ra) # 80000b58 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	76c080e7          	jalr	1900(ra) # 80000da0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	ad0080e7          	jalr	-1328(ra) # 80001116 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00007517          	auipc	a0,0x7
    8000165e:	b2e50513          	add	a0,a0,-1234 # 80008188 <digits+0x148>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ede080e7          	jalr	-290(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b3e50513          	add	a0,a0,-1218 # 800081a8 <digits+0x168>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ece080e7          	jalr	-306(ra) # 80000540 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3de080e7          	jalr	990(ra) # 80000a5a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srl	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c4e080e7          	jalr	-946(ra) # 800012dc <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	add	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	add	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	972080e7          	jalr	-1678(ra) # 8000102e <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	and	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	add	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00007517          	auipc	a0,0x7
    800016d8:	af450513          	add	a0,a0,-1292 # 800081c8 <digits+0x188>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e64080e7          	jalr	-412(ra) # 80000540 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	add	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	add	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	688080e7          	jalr	1672(ra) # 80000da0 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	99e080e7          	jalr	-1634(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	add	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	caa5                	beqz	a3,800017e0 <copyin+0x70>
{
    80001772:	715d                	add	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	add	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8a2e                	mv	s4,a1
    8000178e:	8c32                	mv	s8,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001792:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001794:	6a85                	lui	s5,0x1
    80001796:	a01d                	j	800017bc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001798:	018505b3          	add	a1,a0,s8
    8000179c:	0004861b          	sext.w	a2,s1
    800017a0:	412585b3          	sub	a1,a1,s2
    800017a4:	8552                	mv	a0,s4
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	5fa080e7          	jalr	1530(ra) # 80000da0 <memmove>

    len -= n;
    800017ae:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b8:	02098263          	beqz	s3,800017dc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	855a                	mv	a0,s6
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	910080e7          	jalr	-1776(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800017cc:	cd01                	beqz	a0,800017e4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ce:	418904b3          	sub	s1,s2,s8
    800017d2:	94d6                	add	s1,s1,s5
    800017d4:	fc99f2e3          	bgeu	s3,s1,80001798 <copyin+0x28>
    800017d8:	84ce                	mv	s1,s3
    800017da:	bf7d                	j	80001798 <copyin+0x28>
  }
  return 0;
    800017dc:	4501                	li	a0,0
    800017de:	a021                	j	800017e6 <copyin+0x76>
    800017e0:	4501                	li	a0,0
}
    800017e2:	8082                	ret
      return -1;
    800017e4:	557d                	li	a0,-1
}
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6c02                	ld	s8,0(sp)
    800017fa:	6161                	add	sp,sp,80
    800017fc:	8082                	ret

00000000800017fe <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fe:	c2dd                	beqz	a3,800018a4 <copyinstr+0xa6>
{
    80001800:	715d                	add	sp,sp,-80
    80001802:	e486                	sd	ra,72(sp)
    80001804:	e0a2                	sd	s0,64(sp)
    80001806:	fc26                	sd	s1,56(sp)
    80001808:	f84a                	sd	s2,48(sp)
    8000180a:	f44e                	sd	s3,40(sp)
    8000180c:	f052                	sd	s4,32(sp)
    8000180e:	ec56                	sd	s5,24(sp)
    80001810:	e85a                	sd	s6,16(sp)
    80001812:	e45e                	sd	s7,8(sp)
    80001814:	0880                	add	s0,sp,80
    80001816:	8a2a                	mv	s4,a0
    80001818:	8b2e                	mv	s6,a1
    8000181a:	8bb2                	mv	s7,a2
    8000181c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6985                	lui	s3,0x1
    80001822:	a02d                	j	8000184c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001824:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001828:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000182a:	37fd                	addw	a5,a5,-1
    8000182c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6161                	add	sp,sp,80
    80001844:	8082                	ret
    srcva = va0 + PGSIZE;
    80001846:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000184a:	c8a9                	beqz	s1,8000189c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000184c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001850:	85ca                	mv	a1,s2
    80001852:	8552                	mv	a0,s4
    80001854:	00000097          	auipc	ra,0x0
    80001858:	880080e7          	jalr	-1920(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000185c:	c131                	beqz	a0,800018a0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000185e:	417906b3          	sub	a3,s2,s7
    80001862:	96ce                	add	a3,a3,s3
    80001864:	00d4f363          	bgeu	s1,a3,8000186a <copyinstr+0x6c>
    80001868:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000186a:	955e                	add	a0,a0,s7
    8000186c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001870:	daf9                	beqz	a3,80001846 <copyinstr+0x48>
    80001872:	87da                	mv	a5,s6
    80001874:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001876:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000187a:	96da                	add	a3,a3,s6
    8000187c:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000187e:	00f60733          	add	a4,a2,a5
    80001882:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcc70>
    80001886:	df59                	beqz	a4,80001824 <copyinstr+0x26>
        *dst = *p;
    80001888:	00e78023          	sb	a4,0(a5)
      dst++;
    8000188c:	0785                	add	a5,a5,1
    while(n > 0){
    8000188e:	fed797e3          	bne	a5,a3,8000187c <copyinstr+0x7e>
    80001892:	14fd                	add	s1,s1,-1
    80001894:	94c2                	add	s1,s1,a6
      --max;
    80001896:	8c8d                	sub	s1,s1,a1
      dst++;
    80001898:	8b3e                	mv	s6,a5
    8000189a:	b775                	j	80001846 <copyinstr+0x48>
    8000189c:	4781                	li	a5,0
    8000189e:	b771                	j	8000182a <copyinstr+0x2c>
      return -1;
    800018a0:	557d                	li	a0,-1
    800018a2:	b779                	j	80001830 <copyinstr+0x32>
  int got_null = 0;
    800018a4:	4781                	li	a5,0
  if(got_null){
    800018a6:	37fd                	addw	a5,a5,-1
    800018a8:	0007851b          	sext.w	a0,a5
}
    800018ac:	8082                	ret

00000000800018ae <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018ae:	7139                	add	sp,sp,-64
    800018b0:	fc06                	sd	ra,56(sp)
    800018b2:	f822                	sd	s0,48(sp)
    800018b4:	f426                	sd	s1,40(sp)
    800018b6:	f04a                	sd	s2,32(sp)
    800018b8:	ec4e                	sd	s3,24(sp)
    800018ba:	e852                	sd	s4,16(sp)
    800018bc:	e456                	sd	s5,8(sp)
    800018be:	e05a                	sd	s6,0(sp)
    800018c0:	0080                	add	s0,sp,64
    800018c2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c4:	00010497          	auipc	s1,0x10
    800018c8:	aec48493          	add	s1,s1,-1300 # 800113b0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018cc:	8b26                	mv	s6,s1
    800018ce:	00006a97          	auipc	s5,0x6
    800018d2:	732a8a93          	add	s5,s5,1842 # 80008000 <etext>
    800018d6:	04000937          	lui	s2,0x4000
    800018da:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018dc:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	00015a17          	auipc	s4,0x15
    800018e2:	6d2a0a13          	add	s4,s4,1746 # 80016fb0 <tickslock>
    char *pa = kalloc();
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	272080e7          	jalr	626(ra) # 80000b58 <kalloc>
    800018ee:	862a                	mv	a2,a0
    if(pa == 0)
    800018f0:	c131                	beqz	a0,80001934 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018f2:	416485b3          	sub	a1,s1,s6
    800018f6:	8591                	sra	a1,a1,0x4
    800018f8:	000ab783          	ld	a5,0(s5)
    800018fc:	02f585b3          	mul	a1,a1,a5
    80001900:	2585                	addw	a1,a1,1
    80001902:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001906:	4719                	li	a4,6
    80001908:	6685                	lui	a3,0x1
    8000190a:	40b905b3          	sub	a1,s2,a1
    8000190e:	854e                	mv	a0,s3
    80001910:	00000097          	auipc	ra,0x0
    80001914:	8a6080e7          	jalr	-1882(ra) # 800011b6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	17048493          	add	s1,s1,368
    8000191c:	fd4495e3          	bne	s1,s4,800018e6 <proc_mapstacks+0x38>
  }
}
    80001920:	70e2                	ld	ra,56(sp)
    80001922:	7442                	ld	s0,48(sp)
    80001924:	74a2                	ld	s1,40(sp)
    80001926:	7902                	ld	s2,32(sp)
    80001928:	69e2                	ld	s3,24(sp)
    8000192a:	6a42                	ld	s4,16(sp)
    8000192c:	6aa2                	ld	s5,8(sp)
    8000192e:	6b02                	ld	s6,0(sp)
    80001930:	6121                	add	sp,sp,64
    80001932:	8082                	ret
      panic("kalloc");
    80001934:	00007517          	auipc	a0,0x7
    80001938:	8a450513          	add	a0,a0,-1884 # 800081d8 <digits+0x198>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	c04080e7          	jalr	-1020(ra) # 80000540 <panic>

0000000080001944 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001944:	7139                	add	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	add	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001958:	00007597          	auipc	a1,0x7
    8000195c:	88858593          	add	a1,a1,-1912 # 800081e0 <digits+0x1a0>
    80001960:	0000f517          	auipc	a0,0xf
    80001964:	62050513          	add	a0,a0,1568 # 80010f80 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	250080e7          	jalr	592(ra) # 80000bb8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001970:	00007597          	auipc	a1,0x7
    80001974:	87858593          	add	a1,a1,-1928 # 800081e8 <digits+0x1a8>
    80001978:	0000f517          	auipc	a0,0xf
    8000197c:	62050513          	add	a0,a0,1568 # 80010f98 <wait_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	238080e7          	jalr	568(ra) # 80000bb8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	00010497          	auipc	s1,0x10
    8000198c:	a2848493          	add	s1,s1,-1496 # 800113b0 <proc>
      initlock(&p->lock, "proc");
    80001990:	00007b17          	auipc	s6,0x7
    80001994:	868b0b13          	add	s6,s6,-1944 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001998:	8aa6                	mv	s5,s1
    8000199a:	00006a17          	auipc	s4,0x6
    8000199e:	666a0a13          	add	s4,s4,1638 # 80008000 <etext>
    800019a2:	04000937          	lui	s2,0x4000
    800019a6:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019a8:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	00015997          	auipc	s3,0x15
    800019ae:	60698993          	add	s3,s3,1542 # 80016fb0 <tickslock>
      initlock(&p->lock, "proc");
    800019b2:	85da                	mv	a1,s6
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	202080e7          	jalr	514(ra) # 80000bb8 <initlock>
      p->state = UNUSED;
    800019be:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019c2:	415487b3          	sub	a5,s1,s5
    800019c6:	8791                	sra	a5,a5,0x4
    800019c8:	000a3703          	ld	a4,0(s4)
    800019cc:	02e787b3          	mul	a5,a5,a4
    800019d0:	2785                	addw	a5,a5,1
    800019d2:	00d7979b          	sllw	a5,a5,0xd
    800019d6:	40f907b3          	sub	a5,s2,a5
    800019da:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	17048493          	add	s1,s1,368
    800019e0:	fd3499e3          	bne	s1,s3,800019b2 <procinit+0x6e>
  }
}
    800019e4:	70e2                	ld	ra,56(sp)
    800019e6:	7442                	ld	s0,48(sp)
    800019e8:	74a2                	ld	s1,40(sp)
    800019ea:	7902                	ld	s2,32(sp)
    800019ec:	69e2                	ld	s3,24(sp)
    800019ee:	6a42                	ld	s4,16(sp)
    800019f0:	6aa2                	ld	s5,8(sp)
    800019f2:	6b02                	ld	s6,0(sp)
    800019f4:	6121                	add	sp,sp,64
    800019f6:	8082                	ret

00000000800019f8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019f8:	1141                	add	sp,sp,-16
    800019fa:	e422                	sd	s0,8(sp)
    800019fc:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019fe:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a00:	2501                	sext.w	a0,a0
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	add	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a08:	1141                	add	sp,sp,-16
    80001a0a:	e422                	sd	s0,8(sp)
    80001a0c:	0800                	add	s0,sp,16
    80001a0e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a10:	2781                	sext.w	a5,a5
    80001a12:	079e                	sll	a5,a5,0x7
  return c;
}
    80001a14:	0000f517          	auipc	a0,0xf
    80001a18:	59c50513          	add	a0,a0,1436 # 80010fb0 <cpus>
    80001a1c:	953e                	add	a0,a0,a5
    80001a1e:	6422                	ld	s0,8(sp)
    80001a20:	0141                	add	sp,sp,16
    80001a22:	8082                	ret

0000000080001a24 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a24:	1101                	add	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	1000                	add	s0,sp,32
  push_off();
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	1ce080e7          	jalr	462(ra) # 80000bfc <push_off>
    80001a36:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a38:	2781                	sext.w	a5,a5
    80001a3a:	079e                	sll	a5,a5,0x7
    80001a3c:	0000f717          	auipc	a4,0xf
    80001a40:	54470713          	add	a4,a4,1348 # 80010f80 <pid_lock>
    80001a44:	97ba                	add	a5,a5,a4
    80001a46:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	254080e7          	jalr	596(ra) # 80000c9c <pop_off>
  return p;
}
    80001a50:	8526                	mv	a0,s1
    80001a52:	60e2                	ld	ra,24(sp)
    80001a54:	6442                	ld	s0,16(sp)
    80001a56:	64a2                	ld	s1,8(sp)
    80001a58:	6105                	add	sp,sp,32
    80001a5a:	8082                	ret

0000000080001a5c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a5c:	1141                	add	sp,sp,-16
    80001a5e:	e406                	sd	ra,8(sp)
    80001a60:	e022                	sd	s0,0(sp)
    80001a62:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	fc0080e7          	jalr	-64(ra) # 80001a24 <myproc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	290080e7          	jalr	656(ra) # 80000cfc <release>

  if (first) {
    80001a74:	00007797          	auipc	a5,0x7
    80001a78:	21c7a783          	lw	a5,540(a5) # 80008c90 <first.1>
    80001a7c:	eb89                	bnez	a5,80001a8e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a7e:	00001097          	auipc	ra,0x1
    80001a82:	c8a080e7          	jalr	-886(ra) # 80002708 <usertrapret>
}
    80001a86:	60a2                	ld	ra,8(sp)
    80001a88:	6402                	ld	s0,0(sp)
    80001a8a:	0141                	add	sp,sp,16
    80001a8c:	8082                	ret
    first = 0;
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	2007a123          	sw	zero,514(a5) # 80008c90 <first.1>
    fsinit(ROOTDEV);
    80001a96:	4505                	li	a0,1
    80001a98:	00002097          	auipc	ra,0x2
    80001a9c:	a36080e7          	jalr	-1482(ra) # 800034ce <fsinit>
    80001aa0:	bff9                	j	80001a7e <forkret+0x22>

0000000080001aa2 <allocpid>:
{
    80001aa2:	1101                	add	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001aae:	0000f917          	auipc	s2,0xf
    80001ab2:	4d290913          	add	s2,s2,1234 # 80010f80 <pid_lock>
    80001ab6:	854a                	mv	a0,s2
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	190080e7          	jalr	400(ra) # 80000c48 <acquire>
  pid = nextpid;
    80001ac0:	00007797          	auipc	a5,0x7
    80001ac4:	1d478793          	add	a5,a5,468 # 80008c94 <nextpid>
    80001ac8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aca:	0014871b          	addw	a4,s1,1
    80001ace:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	22a080e7          	jalr	554(ra) # 80000cfc <release>
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6902                	ld	s2,0(sp)
    80001ae4:	6105                	add	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <proc_pagetable>:
{
    80001ae8:	1101                	add	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	add	s0,sp,32
    80001af4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	8aa080e7          	jalr	-1878(ra) # 800013a0 <uvmcreate>
    80001afe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b00:	c121                	beqz	a0,80001b40 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b02:	4729                	li	a4,10
    80001b04:	00005697          	auipc	a3,0x5
    80001b08:	4fc68693          	add	a3,a3,1276 # 80007000 <_trampoline>
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b14:	05b2                	sll	a1,a1,0xc
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	600080e7          	jalr	1536(ra) # 80001116 <mappages>
    80001b1e:	02054863          	bltz	a0,80001b4e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b22:	4719                	li	a4,6
    80001b24:	05893683          	ld	a3,88(s2)
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b30:	05b6                	sll	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	5e2080e7          	jalr	1506(ra) # 80001116 <mappages>
    80001b3c:	02054163          	bltz	a0,80001b5e <proc_pagetable+0x76>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	add	sp,sp,32
    80001b4c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	a54080e7          	jalr	-1452(ra) # 800015a6 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	b7d5                	j	80001b40 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b68:	05b2                	sll	a1,a1,0xc
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	770080e7          	jalr	1904(ra) # 800012dc <uvmunmap>
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2e080e7          	jalr	-1490(ra) # 800015a6 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	bf7d                	j	80001b40 <proc_pagetable+0x58>

0000000080001b84 <proc_freepagetable>:
{
    80001b84:	1101                	add	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	add	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
    80001b92:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	040005b7          	lui	a1,0x4000
    80001b9c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b9e:	05b2                	sll	a1,a1,0xc
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	73c080e7          	jalr	1852(ra) # 800012dc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	020005b7          	lui	a1,0x2000
    80001bb0:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb2:	05b6                	sll	a1,a1,0xd
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	726080e7          	jalr	1830(ra) # 800012dc <uvmunmap>
  uvmfree(pagetable, sz);
    80001bbe:	85ca                	mv	a1,s2
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	9e4080e7          	jalr	-1564(ra) # 800015a6 <uvmfree>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	add	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <freeproc>:
{
    80001bd6:	1101                	add	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	1000                	add	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  if (strncmp(p->name, "vm-", 3) == 0) {
    80001be2:	460d                	li	a2,3
    80001be4:	00006597          	auipc	a1,0x6
    80001be8:	61c58593          	add	a1,a1,1564 # 80008200 <digits+0x1c0>
    80001bec:	15850513          	add	a0,a0,344
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	224080e7          	jalr	548(ra) # 80000e14 <strncmp>
    80001bf8:	c539                	beqz	a0,80001c46 <freeproc+0x70>
  if(p->trapframe)
    80001bfa:	6ca8                	ld	a0,88(s1)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x30>
    kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	e5c080e7          	jalr	-420(ra) # 80000a5a <kfree>
  p->trapframe = 0;
    80001c06:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0a:	68a8                	ld	a0,80(s1)
    80001c0c:	c511                	beqz	a0,80001c18 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0e:	64ac                	ld	a1,72(s1)
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	f74080e7          	jalr	-140(ra) # 80001b84 <proc_freepagetable>
  p->pagetable = 0;
    80001c18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c24:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c38:	0004ac23          	sw	zero,24(s1)
}
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	add	sp,sp,32
    80001c44:	8082                	ret
    uvmunmap(p->pagetable, memaddr_start, memaddr_count, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	40000613          	li	a2,1024
    80001c4c:	4585                	li	a1,1
    80001c4e:	05fe                	sll	a1,a1,0x1f
    80001c50:	68a8                	ld	a0,80(s1)
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	68a080e7          	jalr	1674(ra) # 800012dc <uvmunmap>
    80001c5a:	b745                	j	80001bfa <freeproc+0x24>

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	add	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	0000f497          	auipc	s1,0xf
    80001c6c:	74848493          	add	s1,s1,1864 # 800113b0 <proc>
    80001c70:	00015917          	auipc	s2,0x15
    80001c74:	34090913          	add	s2,s2,832 # 80016fb0 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	fce080e7          	jalr	-50(ra) # 80000c48 <acquire>
    if(p->state == UNUSED) {
    80001c82:	4c9c                	lw	a5,24(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	074080e7          	jalr	116(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	17048493          	add	s1,s1,368
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a889                	j	80001cec <allocproc+0x90>
  p->pid = allocpid();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e06080e7          	jalr	-506(ra) # 80001aa2 <allocpid>
    80001ca4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ca6:	4785                	li	a5,1
    80001ca8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	eae080e7          	jalr	-338(ra) # 80000b58 <kalloc>
    80001cb2:	892a                	mv	s2,a0
    80001cb4:	eca8                	sd	a0,88(s1)
    80001cb6:	c131                	beqz	a0,80001cfa <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	e2e080e7          	jalr	-466(ra) # 80001ae8 <proc_pagetable>
    80001cc2:	892a                	mv	s2,a0
    80001cc4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc6:	c531                	beqz	a0,80001d12 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001cc8:	07000613          	li	a2,112
    80001ccc:	4581                	li	a1,0
    80001cce:	06048513          	add	a0,s1,96
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	072080e7          	jalr	114(ra) # 80000d44 <memset>
  p->context.ra = (uint64)forkret;
    80001cda:	00000797          	auipc	a5,0x0
    80001cde:	d8278793          	add	a5,a5,-638 # 80001a5c <forkret>
    80001ce2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce4:	60bc                	ld	a5,64(s1)
    80001ce6:	6705                	lui	a4,0x1
    80001ce8:	97ba                	add	a5,a5,a4
    80001cea:	f4bc                	sd	a5,104(s1)
}
    80001cec:	8526                	mv	a0,s1
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6902                	ld	s2,0(sp)
    80001cf6:	6105                	add	sp,sp,32
    80001cf8:	8082                	ret
    freeproc(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	eda080e7          	jalr	-294(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	ff6080e7          	jalr	-10(ra) # 80000cfc <release>
    return 0;
    80001d0e:	84ca                	mv	s1,s2
    80001d10:	bff1                	j	80001cec <allocproc+0x90>
    freeproc(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ec2080e7          	jalr	-318(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	fde080e7          	jalr	-34(ra) # 80000cfc <release>
    return 0;
    80001d26:	84ca                	mv	s1,s2
    80001d28:	b7d1                	j	80001cec <allocproc+0x90>

0000000080001d2a <userinit>:
{
    80001d2a:	1101                	add	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	1000                	add	s0,sp,32
  p = allocproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	f28080e7          	jalr	-216(ra) # 80001c5c <allocproc>
    80001d3c:	84aa                	mv	s1,a0
  initproc = p;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	fca7b523          	sd	a0,-54(a5) # 80008d08 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d46:	03400613          	li	a2,52
    80001d4a:	00007597          	auipc	a1,0x7
    80001d4e:	f5658593          	add	a1,a1,-170 # 80008ca0 <initcode>
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	67a080e7          	jalr	1658(ra) # 800013ce <uvmfirst>
  p->sz = PGSIZE;
    80001d5c:	6785                	lui	a5,0x1
    80001d5e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d60:	6cb8                	ld	a4,88(s1)
    80001d62:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d66:	6cb8                	ld	a4,88(s1)
    80001d68:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6a:	4641                	li	a2,16
    80001d6c:	00006597          	auipc	a1,0x6
    80001d70:	49c58593          	add	a1,a1,1180 # 80008208 <digits+0x1c8>
    80001d74:	15848513          	add	a0,s1,344
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	114080e7          	jalr	276(ra) # 80000e8c <safestrcpy>
  p->cwd = namei("/");
    80001d80:	00006517          	auipc	a0,0x6
    80001d84:	49850513          	add	a0,a0,1176 # 80008218 <digits+0x1d8>
    80001d88:	00002097          	auipc	ra,0x2
    80001d8c:	164080e7          	jalr	356(ra) # 80003eec <namei>
    80001d90:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d94:	478d                	li	a5,3
    80001d96:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	f62080e7          	jalr	-158(ra) # 80000cfc <release>
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6105                	add	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <growproc>:
{
    80001dac:	1101                	add	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	e04a                	sd	s2,0(sp)
    80001db6:	1000                	add	s0,sp,32
    80001db8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	c6a080e7          	jalr	-918(ra) # 80001a24 <myproc>
    80001dc2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dc4:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dc6:	01204c63          	bgtz	s2,80001dde <growproc+0x32>
  } else if(n < 0){
    80001dca:	02094663          	bltz	s2,80001df6 <growproc+0x4a>
  p->sz = sz;
    80001dce:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dd0:	4501                	li	a0,0
}
    80001dd2:	60e2                	ld	ra,24(sp)
    80001dd4:	6442                	ld	s0,16(sp)
    80001dd6:	64a2                	ld	s1,8(sp)
    80001dd8:	6902                	ld	s2,0(sp)
    80001dda:	6105                	add	sp,sp,32
    80001ddc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dde:	4691                	li	a3,4
    80001de0:	00b90633          	add	a2,s2,a1
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	6a2080e7          	jalr	1698(ra) # 80001488 <uvmalloc>
    80001dee:	85aa                	mv	a1,a0
    80001df0:	fd79                	bnez	a0,80001dce <growproc+0x22>
      return -1;
    80001df2:	557d                	li	a0,-1
    80001df4:	bff9                	j	80001dd2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df6:	00b90633          	add	a2,s2,a1
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	644080e7          	jalr	1604(ra) # 80001440 <uvmdealloc>
    80001e04:	85aa                	mv	a1,a0
    80001e06:	b7e1                	j	80001dce <growproc+0x22>

0000000080001e08 <fork>:
{
    80001e08:	7139                	add	sp,sp,-64
    80001e0a:	fc06                	sd	ra,56(sp)
    80001e0c:	f822                	sd	s0,48(sp)
    80001e0e:	f426                	sd	s1,40(sp)
    80001e10:	f04a                	sd	s2,32(sp)
    80001e12:	ec4e                	sd	s3,24(sp)
    80001e14:	e852                	sd	s4,16(sp)
    80001e16:	e456                	sd	s5,8(sp)
    80001e18:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c0a080e7          	jalr	-1014(ra) # 80001a24 <myproc>
    80001e22:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	e38080e7          	jalr	-456(ra) # 80001c5c <allocproc>
    80001e2c:	10050c63          	beqz	a0,80001f44 <fork+0x13c>
    80001e30:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	048ab603          	ld	a2,72(s5)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	050ab503          	ld	a0,80(s5)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	7a4080e7          	jalr	1956(ra) # 800015e0 <uvmcopy>
    80001e44:	04054863          	bltz	a0,80001e94 <fork+0x8c>
  np->sz = p->sz;
    80001e48:	048ab783          	ld	a5,72(s5)
    80001e4c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e50:	058ab683          	ld	a3,88(s5)
    80001e54:	87b6                	mv	a5,a3
    80001e56:	058a3703          	ld	a4,88(s4)
    80001e5a:	12068693          	add	a3,a3,288
    80001e5e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e62:	6788                	ld	a0,8(a5)
    80001e64:	6b8c                	ld	a1,16(a5)
    80001e66:	6f90                	ld	a2,24(a5)
    80001e68:	01073023          	sd	a6,0(a4)
    80001e6c:	e708                	sd	a0,8(a4)
    80001e6e:	eb0c                	sd	a1,16(a4)
    80001e70:	ef10                	sd	a2,24(a4)
    80001e72:	02078793          	add	a5,a5,32
    80001e76:	02070713          	add	a4,a4,32
    80001e7a:	fed792e3          	bne	a5,a3,80001e5e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7e:	058a3783          	ld	a5,88(s4)
    80001e82:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e86:	0d0a8493          	add	s1,s5,208
    80001e8a:	0d0a0913          	add	s2,s4,208
    80001e8e:	150a8993          	add	s3,s5,336
    80001e92:	a00d                	j	80001eb4 <fork+0xac>
    freeproc(np);
    80001e94:	8552                	mv	a0,s4
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	d40080e7          	jalr	-704(ra) # 80001bd6 <freeproc>
    release(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	e5c080e7          	jalr	-420(ra) # 80000cfc <release>
    return -1;
    80001ea8:	597d                	li	s2,-1
    80001eaa:	a059                	j	80001f30 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eac:	04a1                	add	s1,s1,8
    80001eae:	0921                	add	s2,s2,8
    80001eb0:	01348b63          	beq	s1,s3,80001ec6 <fork+0xbe>
    if(p->ofile[i])
    80001eb4:	6088                	ld	a0,0(s1)
    80001eb6:	d97d                	beqz	a0,80001eac <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	6a6080e7          	jalr	1702(ra) # 8000455e <filedup>
    80001ec0:	00a93023          	sd	a0,0(s2)
    80001ec4:	b7e5                	j	80001eac <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ec6:	150ab503          	ld	a0,336(s5)
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	83e080e7          	jalr	-1986(ra) # 80003708 <idup>
    80001ed2:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	158a8593          	add	a1,s5,344
    80001edc:	158a0513          	add	a0,s4,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	fac080e7          	jalr	-84(ra) # 80000e8c <safestrcpy>
  pid = np->pid;
    80001ee8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eec:	8552                	mv	a0,s4
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	e0e080e7          	jalr	-498(ra) # 80000cfc <release>
  acquire(&wait_lock);
    80001ef6:	0000f497          	auipc	s1,0xf
    80001efa:	0a248493          	add	s1,s1,162 # 80010f98 <wait_lock>
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d48080e7          	jalr	-696(ra) # 80000c48 <acquire>
  np->parent = p;
    80001f08:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	dee080e7          	jalr	-530(ra) # 80000cfc <release>
  acquire(&np->lock);
    80001f16:	8552                	mv	a0,s4
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d30080e7          	jalr	-720(ra) # 80000c48 <acquire>
  np->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f26:	8552                	mv	a0,s4
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	dd4080e7          	jalr	-556(ra) # 80000cfc <release>
}
    80001f30:	854a                	mv	a0,s2
    80001f32:	70e2                	ld	ra,56(sp)
    80001f34:	7442                	ld	s0,48(sp)
    80001f36:	74a2                	ld	s1,40(sp)
    80001f38:	7902                	ld	s2,32(sp)
    80001f3a:	69e2                	ld	s3,24(sp)
    80001f3c:	6a42                	ld	s4,16(sp)
    80001f3e:	6aa2                	ld	s5,8(sp)
    80001f40:	6121                	add	sp,sp,64
    80001f42:	8082                	ret
    return -1;
    80001f44:	597d                	li	s2,-1
    80001f46:	b7ed                	j	80001f30 <fork+0x128>

0000000080001f48 <scheduler>:
{
    80001f48:	7139                	add	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	e05a                	sd	s6,0(sp)
    80001f5a:	0080                	add	s0,sp,64
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779a93          	sll	s5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	01c70713          	add	a4,a4,28 # 80010f80 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	04670713          	add	a4,a4,70 # 80010fb8 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f7c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7e:	4b11                	li	s6,4
        c->proc = p;
    80001f80:	079e                	sll	a5,a5,0x7
    80001f82:	0000fa17          	auipc	s4,0xf
    80001f86:	ffea0a13          	add	s4,s4,-2 # 80010f80 <pid_lock>
    80001f8a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00015917          	auipc	s2,0x15
    80001f90:	02490913          	add	s2,s2,36 # 80016fb0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    80001fa0:	0000f497          	auipc	s1,0xf
    80001fa4:	41048493          	add	s1,s1,1040 # 800113b0 <proc>
    80001fa8:	a811                	j	80001fbc <scheduler+0x74>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	d50080e7          	jalr	-688(ra) # 80000cfc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	17048493          	add	s1,s1,368
    80001fb8:	fd248ee3          	beq	s1,s2,80001f94 <scheduler+0x4c>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c8a080e7          	jalr	-886(ra) # 80000c48 <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	ff3791e3          	bne	a5,s3,80001faa <scheduler+0x62>
        p->state = RUNNING;
    80001fcc:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fd0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fd4:	06048593          	add	a1,s1,96
    80001fd8:	8556                	mv	a0,s5
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	684080e7          	jalr	1668(ra) # 8000265e <swtch>
        c->proc = 0;
    80001fe2:	020a3823          	sd	zero,48(s4)
    80001fe6:	b7d1                	j	80001faa <scheduler+0x62>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	add	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	a2e080e7          	jalr	-1490(ra) # 80001a24 <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	bce080e7          	jalr	-1074(ra) # 80000bce <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	sll	a5,a5,0x7
    80002010:	0000f717          	auipc	a4,0xf
    80002014:	f7070713          	add	a4,a4,-144 # 80010f80 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if(p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	and	a5,a5,2
  if(intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	0000f917          	auipc	s2,0xf
    8000203a:	f4a90913          	add	s2,s2,-182 # 80010f80 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	sll	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	sll	a5,a5,0x7
    8000204e:	0000f597          	auipc	a1,0xf
    80002052:	f6a58593          	add	a1,a1,-150 # 80010fb8 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06048513          	add	a0,s1,96
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	602080e7          	jalr	1538(ra) # 8000265e <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	sll	a5,a5,0x7
    8000206a:	993e                	add	s2,s2,a5
    8000206c:	0b392623          	sw	s3,172(s2)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	add	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	1a250513          	add	a0,a0,418 # 80008220 <digits+0x1e0>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4ba080e7          	jalr	1210(ra) # 80000540 <panic>
    panic("sched locks");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	1a250513          	add	a0,a0,418 # 80008230 <digits+0x1f0>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4aa080e7          	jalr	1194(ra) # 80000540 <panic>
    panic("sched running");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	1a250513          	add	a0,a0,418 # 80008240 <digits+0x200>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49a080e7          	jalr	1178(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	1a250513          	add	a0,a0,418 # 80008250 <digits+0x210>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48a080e7          	jalr	1162(ra) # 80000540 <panic>

00000000800020be <yield>:
{
    800020be:	1101                	add	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	95c080e7          	jalr	-1700(ra) # 80001a24 <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b76080e7          	jalr	-1162(ra) # 80000c48 <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	c14080e7          	jalr	-1004(ra) # 80000cfc <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	add	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	add	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	add	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	918080e7          	jalr	-1768(ra) # 80001a24 <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b32080e7          	jalr	-1230(ra) # 80000c48 <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	bdc080e7          	jalr	-1060(ra) # 80000cfc <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	bbe080e7          	jalr	-1090(ra) # 80000cfc <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b00080e7          	jalr	-1280(ra) # 80000c48 <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	add	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000215e:	7139                	add	sp,sp,-64
    80002160:	fc06                	sd	ra,56(sp)
    80002162:	f822                	sd	s0,48(sp)
    80002164:	f426                	sd	s1,40(sp)
    80002166:	f04a                	sd	s2,32(sp)
    80002168:	ec4e                	sd	s3,24(sp)
    8000216a:	e852                	sd	s4,16(sp)
    8000216c:	e456                	sd	s5,8(sp)
    8000216e:	0080                	add	s0,sp,64
    80002170:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002172:	0000f497          	auipc	s1,0xf
    80002176:	23e48493          	add	s1,s1,574 # 800113b0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000217a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000217c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00015917          	auipc	s2,0x15
    80002182:	e3290913          	add	s2,s2,-462 # 80016fb0 <tickslock>
    80002186:	a811                	j	8000219a <wakeup+0x3c>
      }
      release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b72080e7          	jalr	-1166(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002192:	17048493          	add	s1,s1,368
    80002196:	03248663          	beq	s1,s2,800021c2 <wakeup+0x64>
    if(p != myproc()){
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	88a080e7          	jalr	-1910(ra) # 80001a24 <myproc>
    800021a2:	fea488e3          	beq	s1,a0,80002192 <wakeup+0x34>
      acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	aa0080e7          	jalr	-1376(ra) # 80000c48 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	fd379be3          	bne	a5,s3,80002188 <wakeup+0x2a>
    800021b6:	709c                	ld	a5,32(s1)
    800021b8:	fd4798e3          	bne	a5,s4,80002188 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021bc:	0154ac23          	sw	s5,24(s1)
    800021c0:	b7e1                	j	80002188 <wakeup+0x2a>
    }
  }
}
    800021c2:	70e2                	ld	ra,56(sp)
    800021c4:	7442                	ld	s0,48(sp)
    800021c6:	74a2                	ld	s1,40(sp)
    800021c8:	7902                	ld	s2,32(sp)
    800021ca:	69e2                	ld	s3,24(sp)
    800021cc:	6a42                	ld	s4,16(sp)
    800021ce:	6aa2                	ld	s5,8(sp)
    800021d0:	6121                	add	sp,sp,64
    800021d2:	8082                	ret

00000000800021d4 <reparent>:
{
    800021d4:	7179                	add	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	add	s0,sp,48
    800021e4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e6:	0000f497          	auipc	s1,0xf
    800021ea:	1ca48493          	add	s1,s1,458 # 800113b0 <proc>
      pp->parent = initproc;
    800021ee:	00007a17          	auipc	s4,0x7
    800021f2:	b1aa0a13          	add	s4,s4,-1254 # 80008d08 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	00015997          	auipc	s3,0x15
    800021fa:	dba98993          	add	s3,s3,-582 # 80016fb0 <tickslock>
    800021fe:	a029                	j	80002208 <reparent+0x34>
    80002200:	17048493          	add	s1,s1,368
    80002204:	01348d63          	beq	s1,s3,8000221e <reparent+0x4a>
    if(pp->parent == p){
    80002208:	7c9c                	ld	a5,56(s1)
    8000220a:	ff279be3          	bne	a5,s2,80002200 <reparent+0x2c>
      pp->parent = initproc;
    8000220e:	000a3503          	ld	a0,0(s4)
    80002212:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f4a080e7          	jalr	-182(ra) # 8000215e <wakeup>
    8000221c:	b7d5                	j	80002200 <reparent+0x2c>
}
    8000221e:	70a2                	ld	ra,40(sp)
    80002220:	7402                	ld	s0,32(sp)
    80002222:	64e2                	ld	s1,24(sp)
    80002224:	6942                	ld	s2,16(sp)
    80002226:	69a2                	ld	s3,8(sp)
    80002228:	6a02                	ld	s4,0(sp)
    8000222a:	6145                	add	sp,sp,48
    8000222c:	8082                	ret

000000008000222e <exit>:
{
    8000222e:	7179                	add	sp,sp,-48
    80002230:	f406                	sd	ra,40(sp)
    80002232:	f022                	sd	s0,32(sp)
    80002234:	ec26                	sd	s1,24(sp)
    80002236:	e84a                	sd	s2,16(sp)
    80002238:	e44e                	sd	s3,8(sp)
    8000223a:	e052                	sd	s4,0(sp)
    8000223c:	1800                	add	s0,sp,48
    8000223e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	7e4080e7          	jalr	2020(ra) # 80001a24 <myproc>
    80002248:	89aa                	mv	s3,a0
  if(p == initproc)
    8000224a:	00007797          	auipc	a5,0x7
    8000224e:	abe7b783          	ld	a5,-1346(a5) # 80008d08 <initproc>
    80002252:	0d050493          	add	s1,a0,208
    80002256:	15050913          	add	s2,a0,336
    8000225a:	02a79363          	bne	a5,a0,80002280 <exit+0x52>
    panic("init exiting");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	00a50513          	add	a0,a0,10 # 80008268 <digits+0x228>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2da080e7          	jalr	730(ra) # 80000540 <panic>
      fileclose(f);
    8000226e:	00002097          	auipc	ra,0x2
    80002272:	342080e7          	jalr	834(ra) # 800045b0 <fileclose>
      p->ofile[fd] = 0;
    80002276:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000227a:	04a1                	add	s1,s1,8
    8000227c:	01248563          	beq	s1,s2,80002286 <exit+0x58>
    if(p->ofile[fd]){
    80002280:	6088                	ld	a0,0(s1)
    80002282:	f575                	bnez	a0,8000226e <exit+0x40>
    80002284:	bfdd                	j	8000227a <exit+0x4c>
  begin_op();
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	e66080e7          	jalr	-410(ra) # 800040ec <begin_op>
  iput(p->cwd);
    8000228e:	1509b503          	ld	a0,336(s3)
    80002292:	00001097          	auipc	ra,0x1
    80002296:	66e080e7          	jalr	1646(ra) # 80003900 <iput>
  end_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	ecc080e7          	jalr	-308(ra) # 80004166 <end_op>
  p->cwd = 0;
    800022a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022a6:	0000f497          	auipc	s1,0xf
    800022aa:	cf248493          	add	s1,s1,-782 # 80010f98 <wait_lock>
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	998080e7          	jalr	-1640(ra) # 80000c48 <acquire>
  reparent(p);
    800022b8:	854e                	mv	a0,s3
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	f1a080e7          	jalr	-230(ra) # 800021d4 <reparent>
  wakeup(p->parent);
    800022c2:	0389b503          	ld	a0,56(s3)
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	e98080e7          	jalr	-360(ra) # 8000215e <wakeup>
  acquire(&p->lock);
    800022ce:	854e                	mv	a0,s3
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	978080e7          	jalr	-1672(ra) # 80000c48 <acquire>
  p->xstate = status;
    800022d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022dc:	4795                	li	a5,5
    800022de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	a18080e7          	jalr	-1512(ra) # 80000cfc <release>
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	cfc080e7          	jalr	-772(ra) # 80001fe8 <sched>
  panic("zombie exit");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	f8450513          	add	a0,a0,-124 # 80008278 <digits+0x238>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	244080e7          	jalr	580(ra) # 80000540 <panic>

0000000080002304 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002304:	7179                	add	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	add	s0,sp,48
    80002312:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	0000f497          	auipc	s1,0xf
    80002318:	09c48493          	add	s1,s1,156 # 800113b0 <proc>
    8000231c:	00015997          	auipc	s3,0x15
    80002320:	c9498993          	add	s3,s3,-876 # 80016fb0 <tickslock>
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	922080e7          	jalr	-1758(ra) # 80000c48 <acquire>
    if(p->pid == pid){
    8000232e:	589c                	lw	a5,48(s1)
    80002330:	01278d63          	beq	a5,s2,8000234a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9c6080e7          	jalr	-1594(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000233e:	17048493          	add	s1,s1,368
    80002342:	ff3491e3          	bne	s1,s3,80002324 <kill+0x20>
  }
  return -1;
    80002346:	557d                	li	a0,-1
    80002348:	a829                	j	80002362 <kill+0x5e>
      p->killed = 1;
    8000234a:	4785                	li	a5,1
    8000234c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	4789                	li	a5,2
    80002352:	00f70f63          	beq	a4,a5,80002370 <kill+0x6c>
      release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	9a4080e7          	jalr	-1628(ra) # 80000cfc <release>
      return 0;
    80002360:	4501                	li	a0,0
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	add	sp,sp,48
    8000236e:	8082                	ret
        p->state = RUNNABLE;
    80002370:	478d                	li	a5,3
    80002372:	cc9c                	sw	a5,24(s1)
    80002374:	b7cd                	j	80002356 <kill+0x52>

0000000080002376 <setkilled>:

void
setkilled(struct proc *p)
{
    80002376:	1101                	add	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	add	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	8c6080e7          	jalr	-1850(ra) # 80000c48 <acquire>
  p->killed = 1;
    8000238a:	4785                	li	a5,1
    8000238c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	96c080e7          	jalr	-1684(ra) # 80000cfc <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	add	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <killed>:

int
killed(struct proc *p)
{
    800023a2:	1101                	add	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	e04a                	sd	s2,0(sp)
    800023ac:	1000                	add	s0,sp,32
    800023ae:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	898080e7          	jalr	-1896(ra) # 80000c48 <acquire>
  k = p->killed;
    800023b8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	93e080e7          	jalr	-1730(ra) # 80000cfc <release>
  return k;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	60e2                	ld	ra,24(sp)
    800023ca:	6442                	ld	s0,16(sp)
    800023cc:	64a2                	ld	s1,8(sp)
    800023ce:	6902                	ld	s2,0(sp)
    800023d0:	6105                	add	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <wait>:
{
    800023d4:	715d                	add	sp,sp,-80
    800023d6:	e486                	sd	ra,72(sp)
    800023d8:	e0a2                	sd	s0,64(sp)
    800023da:	fc26                	sd	s1,56(sp)
    800023dc:	f84a                	sd	s2,48(sp)
    800023de:	f44e                	sd	s3,40(sp)
    800023e0:	f052                	sd	s4,32(sp)
    800023e2:	ec56                	sd	s5,24(sp)
    800023e4:	e85a                	sd	s6,16(sp)
    800023e6:	e45e                	sd	s7,8(sp)
    800023e8:	e062                	sd	s8,0(sp)
    800023ea:	0880                	add	s0,sp,80
    800023ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	636080e7          	jalr	1590(ra) # 80001a24 <myproc>
    800023f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f8:	0000f517          	auipc	a0,0xf
    800023fc:	ba050513          	add	a0,a0,-1120 # 80010f98 <wait_lock>
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	848080e7          	jalr	-1976(ra) # 80000c48 <acquire>
    havekids = 0;
    80002408:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000240a:	4a15                	li	s4,5
        havekids = 1;
    8000240c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	00015997          	auipc	s3,0x15
    80002412:	ba298993          	add	s3,s3,-1118 # 80016fb0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002416:	0000fc17          	auipc	s8,0xf
    8000241a:	b82c0c13          	add	s8,s8,-1150 # 80010f98 <wait_lock>
    8000241e:	a0d1                	j	800024e2 <wait+0x10e>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x6c>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	add	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05093503          	ld	a0,80(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	2b0080e7          	jalr	688(ra) # 800016e4 <copyout>
    8000243c:	04054163          	bltz	a0,8000247e <wait+0xaa>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	794080e7          	jalr	1940(ra) # 80001bd6 <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	8b0080e7          	jalr	-1872(ra) # 80000cfc <release>
          release(&wait_lock);
    80002454:	0000f517          	auipc	a0,0xf
    80002458:	b4450513          	add	a0,a0,-1212 # 80010f98 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	8a0080e7          	jalr	-1888(ra) # 80000cfc <release>
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	add	sp,sp,80
    8000247c:	8082                	ret
            release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	87c080e7          	jalr	-1924(ra) # 80000cfc <release>
            release(&wait_lock);
    80002488:	0000f517          	auipc	a0,0xf
    8000248c:	b1050513          	add	a0,a0,-1264 # 80010f98 <wait_lock>
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	86c080e7          	jalr	-1940(ra) # 80000cfc <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	b7e9                	j	80002464 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249c:	17048493          	add	s1,s1,368
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xf4>
      if(pp->parent == p){
    800024a4:	7c9c                	ld	a5,56(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xc8>
        acquire(&pp->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	79c080e7          	jalr	1948(ra) # 80000c48 <acquire>
        if(pp->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f74785e3          	beq	a5,s4,80002420 <wait+0x4c>
        release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	840080e7          	jalr	-1984(ra) # 80000cfc <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xc8>
    if(!havekids || killed(p)){
    800024c8:	c31d                	beqz	a4,800024ee <wait+0x11a>
    800024ca:	854a                	mv	a0,s2
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	ed6080e7          	jalr	-298(ra) # 800023a2 <killed>
    800024d4:	ed09                	bnez	a0,800024ee <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	c20080e7          	jalr	-992(ra) # 800020fa <sleep>
    havekids = 0;
    800024e2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	ecc48493          	add	s1,s1,-308 # 800113b0 <proc>
    800024ec:	bf65                	j	800024a4 <wait+0xd0>
      release(&wait_lock);
    800024ee:	0000f517          	auipc	a0,0xf
    800024f2:	aaa50513          	add	a0,a0,-1366 # 80010f98 <wait_lock>
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	806080e7          	jalr	-2042(ra) # 80000cfc <release>
      return -1;
    800024fe:	59fd                	li	s3,-1
    80002500:	b795                	j	80002464 <wait+0x90>

0000000080002502 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002502:	7179                	add	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	add	s0,sp,48
    80002512:	84aa                	mv	s1,a0
    80002514:	892e                	mv	s2,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	50a080e7          	jalr	1290(ra) # 80001a24 <myproc>
  if(user_dst){
    80002522:	c08d                	beqz	s1,80002544 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	1b8080e7          	jalr	440(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	add	sp,sp,48
    80002542:	8082                	ret
    memmove((char *)dst, src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	854080e7          	jalr	-1964(ra) # 80000da0 <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyout+0x32>

0000000080002558 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002558:	7179                	add	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	e052                	sd	s4,0(sp)
    80002566:	1800                	add	s0,sp,48
    80002568:	892a                	mv	s2,a0
    8000256a:	84ae                	mv	s1,a1
    8000256c:	89b2                	mv	s3,a2
    8000256e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	4b4080e7          	jalr	1204(ra) # 80001a24 <myproc>
  if(user_src){
    80002578:	c08d                	beqz	s1,8000259a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000257a:	86d2                	mv	a3,s4
    8000257c:	864e                	mv	a2,s3
    8000257e:	85ca                	mv	a1,s2
    80002580:	6928                	ld	a0,80(a0)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	1ee080e7          	jalr	494(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	add	sp,sp,48
    80002598:	8082                	ret
    memmove(dst, (char*)src, len);
    8000259a:	000a061b          	sext.w	a2,s4
    8000259e:	85ce                	mv	a1,s3
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	7fe080e7          	jalr	2046(ra) # 80000da0 <memmove>
    return 0;
    800025aa:	8526                	mv	a0,s1
    800025ac:	bff9                	j	8000258a <either_copyin+0x32>

00000000800025ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ae:	715d                	add	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c4:	00006517          	auipc	a0,0x6
    800025c8:	42c50513          	add	a0,a0,1068 # 800089f0 <syscalls+0x558>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbe080e7          	jalr	-66(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	0000f497          	auipc	s1,0xf
    800025d8:	f3448493          	add	s1,s1,-204 # 80011508 <proc+0x158>
    800025dc:	00015917          	auipc	s2,0x15
    800025e0:	b2c90913          	add	s2,s2,-1236 # 80017108 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e6:	00006997          	auipc	s3,0x6
    800025ea:	ca298993          	add	s3,s3,-862 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	00006a97          	auipc	s5,0x6
    800025f2:	ca2a8a93          	add	s5,s5,-862 # 80008290 <digits+0x250>
    printf("\n");
    800025f6:	00006a17          	auipc	s4,0x6
    800025fa:	3faa0a13          	add	s4,s4,1018 # 800089f0 <syscalls+0x558>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	00006b97          	auipc	s7,0x6
    80002602:	cd2b8b93          	add	s7,s7,-814 # 800082d0 <states.0>
    80002606:	a00d                	j	80002628 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002608:	ed86a583          	lw	a1,-296(a3)
    8000260c:	8556                	mv	a0,s5
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7c080e7          	jalr	-132(ra) # 8000058a <printf>
    printf("\n");
    80002616:	8552                	mv	a0,s4
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002620:	17048493          	add	s1,s1,368
    80002624:	03248263          	beq	s1,s2,80002648 <procdump+0x9a>
    if(p->state == UNUSED)
    80002628:	86a6                	mv	a3,s1
    8000262a:	ec04a783          	lw	a5,-320(s1)
    8000262e:	dbed                	beqz	a5,80002620 <procdump+0x72>
      state = "???";
    80002630:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002632:	fcfb6be3          	bltu	s6,a5,80002608 <procdump+0x5a>
    80002636:	02079713          	sll	a4,a5,0x20
    8000263a:	01d75793          	srl	a5,a4,0x1d
    8000263e:	97de                	add	a5,a5,s7
    80002640:	6390                	ld	a2,0(a5)
    80002642:	f279                	bnez	a2,80002608 <procdump+0x5a>
      state = "???";
    80002644:	864e                	mv	a2,s3
    80002646:	b7c9                	j	80002608 <procdump+0x5a>
  }
}
    80002648:	60a6                	ld	ra,72(sp)
    8000264a:	6406                	ld	s0,64(sp)
    8000264c:	74e2                	ld	s1,56(sp)
    8000264e:	7942                	ld	s2,48(sp)
    80002650:	79a2                	ld	s3,40(sp)
    80002652:	7a02                	ld	s4,32(sp)
    80002654:	6ae2                	ld	s5,24(sp)
    80002656:	6b42                	ld	s6,16(sp)
    80002658:	6ba2                	ld	s7,8(sp)
    8000265a:	6161                	add	sp,sp,80
    8000265c:	8082                	ret

000000008000265e <swtch>:
    8000265e:	00153023          	sd	ra,0(a0)
    80002662:	00253423          	sd	sp,8(a0)
    80002666:	e900                	sd	s0,16(a0)
    80002668:	ed04                	sd	s1,24(a0)
    8000266a:	03253023          	sd	s2,32(a0)
    8000266e:	03353423          	sd	s3,40(a0)
    80002672:	03453823          	sd	s4,48(a0)
    80002676:	03553c23          	sd	s5,56(a0)
    8000267a:	05653023          	sd	s6,64(a0)
    8000267e:	05753423          	sd	s7,72(a0)
    80002682:	05853823          	sd	s8,80(a0)
    80002686:	05953c23          	sd	s9,88(a0)
    8000268a:	07a53023          	sd	s10,96(a0)
    8000268e:	07b53423          	sd	s11,104(a0)
    80002692:	0005b083          	ld	ra,0(a1)
    80002696:	0085b103          	ld	sp,8(a1)
    8000269a:	6980                	ld	s0,16(a1)
    8000269c:	6d84                	ld	s1,24(a1)
    8000269e:	0205b903          	ld	s2,32(a1)
    800026a2:	0285b983          	ld	s3,40(a1)
    800026a6:	0305ba03          	ld	s4,48(a1)
    800026aa:	0385ba83          	ld	s5,56(a1)
    800026ae:	0405bb03          	ld	s6,64(a1)
    800026b2:	0485bb83          	ld	s7,72(a1)
    800026b6:	0505bc03          	ld	s8,80(a1)
    800026ba:	0585bc83          	ld	s9,88(a1)
    800026be:	0605bd03          	ld	s10,96(a1)
    800026c2:	0685bd83          	ld	s11,104(a1)
    800026c6:	8082                	ret

00000000800026c8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c8:	1141                	add	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    800026d0:	00006597          	auipc	a1,0x6
    800026d4:	c3058593          	add	a1,a1,-976 # 80008300 <states.0+0x30>
    800026d8:	00015517          	auipc	a0,0x15
    800026dc:	8d850513          	add	a0,a0,-1832 # 80016fb0 <tickslock>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	4d8080e7          	jalr	1240(ra) # 80000bb8 <initlock>
}
    800026e8:	60a2                	ld	ra,8(sp)
    800026ea:	6402                	ld	s0,0(sp)
    800026ec:	0141                	add	sp,sp,16
    800026ee:	8082                	ret

00000000800026f0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f0:	1141                	add	sp,sp,-16
    800026f2:	e422                	sd	s0,8(sp)
    800026f4:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f6:	00003797          	auipc	a5,0x3
    800026fa:	54a78793          	add	a5,a5,1354 # 80005c40 <kernelvec>
    800026fe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002702:	6422                	ld	s0,8(sp)
    80002704:	0141                	add	sp,sp,16
    80002706:	8082                	ret

0000000080002708 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002708:	1141                	add	sp,sp,-16
    8000270a:	e406                	sd	ra,8(sp)
    8000270c:	e022                	sd	s0,0(sp)
    8000270e:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	314080e7          	jalr	788(ra) # 80001a24 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000271c:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002722:	00005697          	auipc	a3,0x5
    80002726:	8de68693          	add	a3,a3,-1826 # 80007000 <_trampoline>
    8000272a:	00005717          	auipc	a4,0x5
    8000272e:	8d670713          	add	a4,a4,-1834 # 80007000 <_trampoline>
    80002732:	8f15                	sub	a4,a4,a3
    80002734:	040007b7          	lui	a5,0x4000
    80002738:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273a:	07b2                	sll	a5,a5,0xc
    8000273c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002744:	18002673          	csrr	a2,satp
    80002748:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274a:	6d30                	ld	a2,88(a0)
    8000274c:	6138                	ld	a4,64(a0)
    8000274e:	6585                	lui	a1,0x1
    80002750:	972e                	add	a4,a4,a1
    80002752:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002754:	6d38                	ld	a4,88(a0)
    80002756:	00000617          	auipc	a2,0x0
    8000275a:	13460613          	add	a2,a2,308 # 8000288a <usertrap>
    8000275e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002760:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002762:	8612                	mv	a2,tp
    80002764:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002766:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276a:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000276e:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002772:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002776:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002778:	6f18                	ld	a4,24(a4)
    8000277a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000277e:	6928                	ld	a0,80(a0)
    80002780:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002782:	00005717          	auipc	a4,0x5
    80002786:	91a70713          	add	a4,a4,-1766 # 8000709c <userret>
    8000278a:	8f15                	sub	a4,a4,a3
    8000278c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000278e:	577d                	li	a4,-1
    80002790:	177e                	sll	a4,a4,0x3f
    80002792:	8d59                	or	a0,a0,a4
    80002794:	9782                	jalr	a5
}
    80002796:	60a2                	ld	ra,8(sp)
    80002798:	6402                	ld	s0,0(sp)
    8000279a:	0141                	add	sp,sp,16
    8000279c:	8082                	ret

000000008000279e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000279e:	1101                	add	sp,sp,-32
    800027a0:	ec06                	sd	ra,24(sp)
    800027a2:	e822                	sd	s0,16(sp)
    800027a4:	e426                	sd	s1,8(sp)
    800027a6:	1000                	add	s0,sp,32
  acquire(&tickslock);
    800027a8:	00015497          	auipc	s1,0x15
    800027ac:	80848493          	add	s1,s1,-2040 # 80016fb0 <tickslock>
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	496080e7          	jalr	1174(ra) # 80000c48 <acquire>
  ticks++;
    800027ba:	00006517          	auipc	a0,0x6
    800027be:	55650513          	add	a0,a0,1366 # 80008d10 <ticks>
    800027c2:	411c                	lw	a5,0(a0)
    800027c4:	2785                	addw	a5,a5,1
    800027c6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c8:	00000097          	auipc	ra,0x0
    800027cc:	996080e7          	jalr	-1642(ra) # 8000215e <wakeup>
  release(&tickslock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	52a080e7          	jalr	1322(ra) # 80000cfc <release>
}
    800027da:	60e2                	ld	ra,24(sp)
    800027dc:	6442                	ld	s0,16(sp)
    800027de:	64a2                	ld	s1,8(sp)
    800027e0:	6105                	add	sp,sp,32
    800027e2:	8082                	ret

00000000800027e4 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e4:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027e8:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027ea:	0807df63          	bgez	a5,80002888 <devintr+0xa4>
{
    800027ee:	1101                	add	sp,sp,-32
    800027f0:	ec06                	sd	ra,24(sp)
    800027f2:	e822                	sd	s0,16(sp)
    800027f4:	e426                	sd	s1,8(sp)
    800027f6:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    800027f8:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800027fc:	46a5                	li	a3,9
    800027fe:	00d70d63          	beq	a4,a3,80002818 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002802:	577d                	li	a4,-1
    80002804:	177e                	sll	a4,a4,0x3f
    80002806:	0705                	add	a4,a4,1
    return 0;
    80002808:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280a:	04e78e63          	beq	a5,a4,80002866 <devintr+0x82>
  }
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	add	sp,sp,32
    80002816:	8082                	ret
    int irq = plic_claim();
    80002818:	00003097          	auipc	ra,0x3
    8000281c:	530080e7          	jalr	1328(ra) # 80005d48 <plic_claim>
    80002820:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002822:	47a9                	li	a5,10
    80002824:	02f50763          	beq	a0,a5,80002852 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002828:	4785                	li	a5,1
    8000282a:	02f50963          	beq	a0,a5,8000285c <devintr+0x78>
    return 1;
    8000282e:	4505                	li	a0,1
    } else if(irq){
    80002830:	dcf9                	beqz	s1,8000280e <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002832:	85a6                	mv	a1,s1
    80002834:	00006517          	auipc	a0,0x6
    80002838:	ad450513          	add	a0,a0,-1324 # 80008308 <states.0+0x38>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d4e080e7          	jalr	-690(ra) # 8000058a <printf>
      plic_complete(irq);
    80002844:	8526                	mv	a0,s1
    80002846:	00003097          	auipc	ra,0x3
    8000284a:	526080e7          	jalr	1318(ra) # 80005d6c <plic_complete>
    return 1;
    8000284e:	4505                	li	a0,1
    80002850:	bf7d                	j	8000280e <devintr+0x2a>
      uartintr();
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	1b8080e7          	jalr	440(ra) # 80000a0a <uartintr>
    if(irq)
    8000285a:	b7ed                	j	80002844 <devintr+0x60>
      virtio_disk_intr();
    8000285c:	00004097          	auipc	ra,0x4
    80002860:	b88080e7          	jalr	-1144(ra) # 800063e4 <virtio_disk_intr>
    if(irq)
    80002864:	b7c5                	j	80002844 <devintr+0x60>
    if(cpuid() == 0){
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	192080e7          	jalr	402(ra) # 800019f8 <cpuid>
    8000286e:	c901                	beqz	a0,8000287e <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002870:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002874:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002876:	14479073          	csrw	sip,a5
    return 2;
    8000287a:	4509                	li	a0,2
    8000287c:	bf49                	j	8000280e <devintr+0x2a>
      clockintr();
    8000287e:	00000097          	auipc	ra,0x0
    80002882:	f20080e7          	jalr	-224(ra) # 8000279e <clockintr>
    80002886:	b7ed                	j	80002870 <devintr+0x8c>
}
    80002888:	8082                	ret

000000008000288a <usertrap>:
{
    8000288a:	7179                	add	sp,sp,-48
    8000288c:	f406                	sd	ra,40(sp)
    8000288e:	f022                	sd	s0,32(sp)
    80002890:	ec26                	sd	s1,24(sp)
    80002892:	e84a                	sd	s2,16(sp)
    80002894:	e44e                	sd	s3,8(sp)
    80002896:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002898:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289c:	1007f793          	and	a5,a5,256
    800028a0:	efb1                	bnez	a5,800028fc <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a2:	00003797          	auipc	a5,0x3
    800028a6:	39e78793          	add	a5,a5,926 # 80005c40 <kernelvec>
    800028aa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	176080e7          	jalr	374(ra) # 80001a24 <myproc>
    800028b6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ba:	14102773          	csrr	a4,sepc
    800028be:	ef98                	sd	a4,24(a5)
  if(strncmp(p->name, "vm-", 3) == 0) {
    800028c0:	15850993          	add	s3,a0,344
    800028c4:	460d                	li	a2,3
    800028c6:	00006597          	auipc	a1,0x6
    800028ca:	93a58593          	add	a1,a1,-1734 # 80008200 <digits+0x1c0>
    800028ce:	854e                	mv	a0,s3
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	544080e7          	jalr	1348(ra) # 80000e14 <strncmp>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028dc:	47a1                	li	a5,8
    800028de:	02f70763          	beq	a4,a5,8000290c <usertrap+0x82>
  } else if((which_dev = devintr()) != 0){
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	f02080e7          	jalr	-254(ra) # 800027e4 <devintr>
    800028ea:	892a                	mv	s2,a0
    800028ec:	c945                	beqz	a0,8000299c <usertrap+0x112>
  if(killed(p))
    800028ee:	8526                	mv	a0,s1
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	ab2080e7          	jalr	-1358(ra) # 800023a2 <killed>
    800028f8:	c52d                	beqz	a0,80002962 <usertrap+0xd8>
    800028fa:	a8b9                	j	80002958 <usertrap+0xce>
    panic("usertrap: not from user mode");
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	a2c50513          	add	a0,a0,-1492 # 80008328 <states.0+0x58>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c3c080e7          	jalr	-964(ra) # 80000540 <panic>
    if(killed(p))
    8000290c:	8526                	mv	a0,s1
    8000290e:	00000097          	auipc	ra,0x0
    80002912:	a94080e7          	jalr	-1388(ra) # 800023a2 <killed>
    80002916:	e525                	bnez	a0,8000297e <usertrap+0xf4>
    p->trapframe->epc += 4;
    80002918:	6cb8                	ld	a4,88(s1)
    8000291a:	6f1c                	ld	a5,24(a4)
    8000291c:	0791                	add	a5,a5,4
    8000291e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002920:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002924:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002928:	10079073          	csrw	sstatus,a5
    if(strncmp(p->name, "vm-", 3) == 0) {
    8000292c:	460d                	li	a2,3
    8000292e:	00006597          	auipc	a1,0x6
    80002932:	8d258593          	add	a1,a1,-1838 # 80008200 <digits+0x1c0>
    80002936:	854e                	mv	a0,s3
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	4dc080e7          	jalr	1244(ra) # 80000e14 <strncmp>
    80002940:	c529                	beqz	a0,8000298a <usertrap+0x100>
    syscall();
    80002942:	00000097          	auipc	ra,0x0
    80002946:	31a080e7          	jalr	794(ra) # 80002c5c <syscall>
  if(killed(p))
    8000294a:	8526                	mv	a0,s1
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	a56080e7          	jalr	-1450(ra) # 800023a2 <killed>
    80002954:	c911                	beqz	a0,80002968 <usertrap+0xde>
    80002956:	4901                	li	s2,0
    exit(-1);
    80002958:	557d                	li	a0,-1
    8000295a:	00000097          	auipc	ra,0x0
    8000295e:	8d4080e7          	jalr	-1836(ra) # 8000222e <exit>
  if(which_dev == 2)
    80002962:	4789                	li	a5,2
    80002964:	0af90263          	beq	s2,a5,80002a08 <usertrap+0x17e>
  usertrapret();
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	da0080e7          	jalr	-608(ra) # 80002708 <usertrapret>
}
    80002970:	70a2                	ld	ra,40(sp)
    80002972:	7402                	ld	s0,32(sp)
    80002974:	64e2                	ld	s1,24(sp)
    80002976:	6942                	ld	s2,16(sp)
    80002978:	69a2                	ld	s3,8(sp)
    8000297a:	6145                	add	sp,sp,48
    8000297c:	8082                	ret
      exit(-1);
    8000297e:	557d                	li	a0,-1
    80002980:	00000097          	auipc	ra,0x0
    80002984:	8ae080e7          	jalr	-1874(ra) # 8000222e <exit>
    80002988:	bf41                	j	80002918 <usertrap+0x8e>
    printf("ECALL occured");
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	9be50513          	add	a0,a0,-1602 # 80008348 <states.0+0x78>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bf8080e7          	jalr	-1032(ra) # 8000058a <printf>
    8000299a:	b765                	j	80002942 <usertrap+0xb8>
  } else if(strncmp(p->name, "vm-", 3) == 0) {
    8000299c:	460d                	li	a2,3
    8000299e:	00006597          	auipc	a1,0x6
    800029a2:	86258593          	add	a1,a1,-1950 # 80008200 <digits+0x1c0>
    800029a6:	854e                	mv	a0,s3
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	46c080e7          	jalr	1132(ra) # 80000e14 <strncmp>
    800029b0:	ed19                	bnez	a0,800029ce <usertrap+0x144>
    printf("\n USERTRAP: %s, calling trap and emulate\n", p->name);
    800029b2:	85ce                	mv	a1,s3
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	9a450513          	add	a0,a0,-1628 # 80008358 <states.0+0x88>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bce080e7          	jalr	-1074(ra) # 8000058a <printf>
    trap_and_emulate();
    800029c4:	00004097          	auipc	ra,0x4
    800029c8:	150080e7          	jalr	336(ra) # 80006b14 <trap_and_emulate>
    800029cc:	bfbd                	j	8000294a <usertrap+0xc0>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029d2:	5890                	lw	a2,48(s1)
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9b450513          	add	a0,a0,-1612 # 80008388 <states.0+0xb8>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	bae080e7          	jalr	-1106(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029e8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	9cc50513          	add	a0,a0,-1588 # 800083b8 <states.0+0xe8>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b96080e7          	jalr	-1130(ra) # 8000058a <printf>
    setkilled(p);
    800029fc:	8526                	mv	a0,s1
    800029fe:	00000097          	auipc	ra,0x0
    80002a02:	978080e7          	jalr	-1672(ra) # 80002376 <setkilled>
    80002a06:	b791                	j	8000294a <usertrap+0xc0>
    yield();
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	6b6080e7          	jalr	1718(ra) # 800020be <yield>
    80002a10:	bfa1                	j	80002968 <usertrap+0xde>

0000000080002a12 <kerneltrap>:
{
    80002a12:	7179                	add	sp,sp,-48
    80002a14:	f406                	sd	ra,40(sp)
    80002a16:	f022                	sd	s0,32(sp)
    80002a18:	ec26                	sd	s1,24(sp)
    80002a1a:	e84a                	sd	s2,16(sp)
    80002a1c:	e44e                	sd	s3,8(sp)
    80002a1e:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a20:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a24:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a28:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a2c:	1004f793          	and	a5,s1,256
    80002a30:	cb85                	beqz	a5,80002a60 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a32:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a36:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002a38:	ef85                	bnez	a5,80002a70 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	daa080e7          	jalr	-598(ra) # 800027e4 <devintr>
    80002a42:	cd1d                	beqz	a0,80002a80 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a44:	4789                	li	a5,2
    80002a46:	06f50a63          	beq	a0,a5,80002aba <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a4a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a4e:	10049073          	csrw	sstatus,s1
}
    80002a52:	70a2                	ld	ra,40(sp)
    80002a54:	7402                	ld	s0,32(sp)
    80002a56:	64e2                	ld	s1,24(sp)
    80002a58:	6942                	ld	s2,16(sp)
    80002a5a:	69a2                	ld	s3,8(sp)
    80002a5c:	6145                	add	sp,sp,48
    80002a5e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	97850513          	add	a0,a0,-1672 # 800083d8 <states.0+0x108>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	ad8080e7          	jalr	-1320(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	99050513          	add	a0,a0,-1648 # 80008400 <states.0+0x130>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	ac8080e7          	jalr	-1336(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a80:	85ce                	mv	a1,s3
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	99e50513          	add	a0,a0,-1634 # 80008420 <states.0+0x150>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	b00080e7          	jalr	-1280(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a92:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a96:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	99650513          	add	a0,a0,-1642 # 80008430 <states.0+0x160>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	ae8080e7          	jalr	-1304(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	99e50513          	add	a0,a0,-1634 # 80008448 <states.0+0x178>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a8e080e7          	jalr	-1394(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	f6a080e7          	jalr	-150(ra) # 80001a24 <myproc>
    80002ac2:	d541                	beqz	a0,80002a4a <kerneltrap+0x38>
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	f60080e7          	jalr	-160(ra) # 80001a24 <myproc>
    80002acc:	4d18                	lw	a4,24(a0)
    80002ace:	4791                	li	a5,4
    80002ad0:	f6f71de3          	bne	a4,a5,80002a4a <kerneltrap+0x38>
    yield();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	5ea080e7          	jalr	1514(ra) # 800020be <yield>
    80002adc:	b7bd                	j	80002a4a <kerneltrap+0x38>

0000000080002ade <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ade:	1101                	add	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	1000                	add	s0,sp,32
    80002ae8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	f3a080e7          	jalr	-198(ra) # 80001a24 <myproc>
  switch (n) {
    80002af2:	4795                	li	a5,5
    80002af4:	0497e163          	bltu	a5,s1,80002b36 <argraw+0x58>
    80002af8:	048a                	sll	s1,s1,0x2
    80002afa:	00006717          	auipc	a4,0x6
    80002afe:	98670713          	add	a4,a4,-1658 # 80008480 <states.0+0x1b0>
    80002b02:	94ba                	add	s1,s1,a4
    80002b04:	409c                	lw	a5,0(s1)
    80002b06:	97ba                	add	a5,a5,a4
    80002b08:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b0e:	60e2                	ld	ra,24(sp)
    80002b10:	6442                	ld	s0,16(sp)
    80002b12:	64a2                	ld	s1,8(sp)
    80002b14:	6105                	add	sp,sp,32
    80002b16:	8082                	ret
    return p->trapframe->a1;
    80002b18:	6d3c                	ld	a5,88(a0)
    80002b1a:	7fa8                	ld	a0,120(a5)
    80002b1c:	bfcd                	j	80002b0e <argraw+0x30>
    return p->trapframe->a2;
    80002b1e:	6d3c                	ld	a5,88(a0)
    80002b20:	63c8                	ld	a0,128(a5)
    80002b22:	b7f5                	j	80002b0e <argraw+0x30>
    return p->trapframe->a3;
    80002b24:	6d3c                	ld	a5,88(a0)
    80002b26:	67c8                	ld	a0,136(a5)
    80002b28:	b7dd                	j	80002b0e <argraw+0x30>
    return p->trapframe->a4;
    80002b2a:	6d3c                	ld	a5,88(a0)
    80002b2c:	6bc8                	ld	a0,144(a5)
    80002b2e:	b7c5                	j	80002b0e <argraw+0x30>
    return p->trapframe->a5;
    80002b30:	6d3c                	ld	a5,88(a0)
    80002b32:	6fc8                	ld	a0,152(a5)
    80002b34:	bfe9                	j	80002b0e <argraw+0x30>
  panic("argraw");
    80002b36:	00006517          	auipc	a0,0x6
    80002b3a:	92250513          	add	a0,a0,-1758 # 80008458 <states.0+0x188>
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	a02080e7          	jalr	-1534(ra) # 80000540 <panic>

0000000080002b46 <fetchaddr>:
{
    80002b46:	1101                	add	sp,sp,-32
    80002b48:	ec06                	sd	ra,24(sp)
    80002b4a:	e822                	sd	s0,16(sp)
    80002b4c:	e426                	sd	s1,8(sp)
    80002b4e:	e04a                	sd	s2,0(sp)
    80002b50:	1000                	add	s0,sp,32
    80002b52:	84aa                	mv	s1,a0
    80002b54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	ece080e7          	jalr	-306(ra) # 80001a24 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b5e:	653c                	ld	a5,72(a0)
    80002b60:	02f4f863          	bgeu	s1,a5,80002b90 <fetchaddr+0x4a>
    80002b64:	00848713          	add	a4,s1,8
    80002b68:	02e7e663          	bltu	a5,a4,80002b94 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b6c:	46a1                	li	a3,8
    80002b6e:	8626                	mv	a2,s1
    80002b70:	85ca                	mv	a1,s2
    80002b72:	6928                	ld	a0,80(a0)
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	bfc080e7          	jalr	-1028(ra) # 80001770 <copyin>
    80002b7c:	00a03533          	snez	a0,a0
    80002b80:	40a00533          	neg	a0,a0
}
    80002b84:	60e2                	ld	ra,24(sp)
    80002b86:	6442                	ld	s0,16(sp)
    80002b88:	64a2                	ld	s1,8(sp)
    80002b8a:	6902                	ld	s2,0(sp)
    80002b8c:	6105                	add	sp,sp,32
    80002b8e:	8082                	ret
    return -1;
    80002b90:	557d                	li	a0,-1
    80002b92:	bfcd                	j	80002b84 <fetchaddr+0x3e>
    80002b94:	557d                	li	a0,-1
    80002b96:	b7fd                	j	80002b84 <fetchaddr+0x3e>

0000000080002b98 <fetchstr>:
{
    80002b98:	7179                	add	sp,sp,-48
    80002b9a:	f406                	sd	ra,40(sp)
    80002b9c:	f022                	sd	s0,32(sp)
    80002b9e:	ec26                	sd	s1,24(sp)
    80002ba0:	e84a                	sd	s2,16(sp)
    80002ba2:	e44e                	sd	s3,8(sp)
    80002ba4:	1800                	add	s0,sp,48
    80002ba6:	892a                	mv	s2,a0
    80002ba8:	84ae                	mv	s1,a1
    80002baa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	e78080e7          	jalr	-392(ra) # 80001a24 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bb4:	86ce                	mv	a3,s3
    80002bb6:	864a                	mv	a2,s2
    80002bb8:	85a6                	mv	a1,s1
    80002bba:	6928                	ld	a0,80(a0)
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	c42080e7          	jalr	-958(ra) # 800017fe <copyinstr>
    80002bc4:	00054e63          	bltz	a0,80002be0 <fetchstr+0x48>
  return strlen(buf);
    80002bc8:	8526                	mv	a0,s1
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	2f4080e7          	jalr	756(ra) # 80000ebe <strlen>
}
    80002bd2:	70a2                	ld	ra,40(sp)
    80002bd4:	7402                	ld	s0,32(sp)
    80002bd6:	64e2                	ld	s1,24(sp)
    80002bd8:	6942                	ld	s2,16(sp)
    80002bda:	69a2                	ld	s3,8(sp)
    80002bdc:	6145                	add	sp,sp,48
    80002bde:	8082                	ret
    return -1;
    80002be0:	557d                	li	a0,-1
    80002be2:	bfc5                	j	80002bd2 <fetchstr+0x3a>

0000000080002be4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002be4:	1101                	add	sp,sp,-32
    80002be6:	ec06                	sd	ra,24(sp)
    80002be8:	e822                	sd	s0,16(sp)
    80002bea:	e426                	sd	s1,8(sp)
    80002bec:	1000                	add	s0,sp,32
    80002bee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	eee080e7          	jalr	-274(ra) # 80002ade <argraw>
    80002bf8:	c088                	sw	a0,0(s1)
}
    80002bfa:	60e2                	ld	ra,24(sp)
    80002bfc:	6442                	ld	s0,16(sp)
    80002bfe:	64a2                	ld	s1,8(sp)
    80002c00:	6105                	add	sp,sp,32
    80002c02:	8082                	ret

0000000080002c04 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c04:	1101                	add	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	1000                	add	s0,sp,32
    80002c0e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	ece080e7          	jalr	-306(ra) # 80002ade <argraw>
    80002c18:	e088                	sd	a0,0(s1)
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6105                	add	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c24:	7179                	add	sp,sp,-48
    80002c26:	f406                	sd	ra,40(sp)
    80002c28:	f022                	sd	s0,32(sp)
    80002c2a:	ec26                	sd	s1,24(sp)
    80002c2c:	e84a                	sd	s2,16(sp)
    80002c2e:	1800                	add	s0,sp,48
    80002c30:	84ae                	mv	s1,a1
    80002c32:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c34:	fd840593          	add	a1,s0,-40
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	fcc080e7          	jalr	-52(ra) # 80002c04 <argaddr>
  return fetchstr(addr, buf, max);
    80002c40:	864a                	mv	a2,s2
    80002c42:	85a6                	mv	a1,s1
    80002c44:	fd843503          	ld	a0,-40(s0)
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	f50080e7          	jalr	-176(ra) # 80002b98 <fetchstr>
}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6942                	ld	s2,16(sp)
    80002c58:	6145                	add	sp,sp,48
    80002c5a:	8082                	ret

0000000080002c5c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c5c:	1101                	add	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	e04a                	sd	s2,0(sp)
    80002c66:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	dbc080e7          	jalr	-580(ra) # 80001a24 <myproc>
    80002c70:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c72:	05853903          	ld	s2,88(a0)
    80002c76:	0a893783          	ld	a5,168(s2)
    80002c7a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c7e:	37fd                	addw	a5,a5,-1
    80002c80:	4751                	li	a4,20
    80002c82:	00f76f63          	bltu	a4,a5,80002ca0 <syscall+0x44>
    80002c86:	00369713          	sll	a4,a3,0x3
    80002c8a:	00006797          	auipc	a5,0x6
    80002c8e:	80e78793          	add	a5,a5,-2034 # 80008498 <syscalls>
    80002c92:	97ba                	add	a5,a5,a4
    80002c94:	639c                	ld	a5,0(a5)
    80002c96:	c789                	beqz	a5,80002ca0 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c98:	9782                	jalr	a5
    80002c9a:	06a93823          	sd	a0,112(s2)
    80002c9e:	a839                	j	80002cbc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ca0:	15848613          	add	a2,s1,344
    80002ca4:	588c                	lw	a1,48(s1)
    80002ca6:	00005517          	auipc	a0,0x5
    80002caa:	7ba50513          	add	a0,a0,1978 # 80008460 <states.0+0x190>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	8dc080e7          	jalr	-1828(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cb6:	6cbc                	ld	a5,88(s1)
    80002cb8:	577d                	li	a4,-1
    80002cba:	fbb8                	sd	a4,112(a5)
  }
}
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	64a2                	ld	s1,8(sp)
    80002cc2:	6902                	ld	s2,0(sp)
    80002cc4:	6105                	add	sp,sp,32
    80002cc6:	8082                	ret

0000000080002cc8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cc8:	1101                	add	sp,sp,-32
    80002cca:	ec06                	sd	ra,24(sp)
    80002ccc:	e822                	sd	s0,16(sp)
    80002cce:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002cd0:	fec40593          	add	a1,s0,-20
    80002cd4:	4501                	li	a0,0
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	f0e080e7          	jalr	-242(ra) # 80002be4 <argint>
  exit(n);
    80002cde:	fec42503          	lw	a0,-20(s0)
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	54c080e7          	jalr	1356(ra) # 8000222e <exit>
  return 0;  // not reached
}
    80002cea:	4501                	li	a0,0
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	6105                	add	sp,sp,32
    80002cf2:	8082                	ret

0000000080002cf4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cf4:	1141                	add	sp,sp,-16
    80002cf6:	e406                	sd	ra,8(sp)
    80002cf8:	e022                	sd	s0,0(sp)
    80002cfa:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	d28080e7          	jalr	-728(ra) # 80001a24 <myproc>
}
    80002d04:	5908                	lw	a0,48(a0)
    80002d06:	60a2                	ld	ra,8(sp)
    80002d08:	6402                	ld	s0,0(sp)
    80002d0a:	0141                	add	sp,sp,16
    80002d0c:	8082                	ret

0000000080002d0e <sys_fork>:

uint64
sys_fork(void)
{
    80002d0e:	1141                	add	sp,sp,-16
    80002d10:	e406                	sd	ra,8(sp)
    80002d12:	e022                	sd	s0,0(sp)
    80002d14:	0800                	add	s0,sp,16
  return fork();
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	0f2080e7          	jalr	242(ra) # 80001e08 <fork>
}
    80002d1e:	60a2                	ld	ra,8(sp)
    80002d20:	6402                	ld	s0,0(sp)
    80002d22:	0141                	add	sp,sp,16
    80002d24:	8082                	ret

0000000080002d26 <sys_wait>:

uint64
sys_wait(void)
{
    80002d26:	1101                	add	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d2e:	fe840593          	add	a1,s0,-24
    80002d32:	4501                	li	a0,0
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	ed0080e7          	jalr	-304(ra) # 80002c04 <argaddr>
  return wait(p);
    80002d3c:	fe843503          	ld	a0,-24(s0)
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	694080e7          	jalr	1684(ra) # 800023d4 <wait>
}
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	6105                	add	sp,sp,32
    80002d4e:	8082                	ret

0000000080002d50 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d50:	7179                	add	sp,sp,-48
    80002d52:	f406                	sd	ra,40(sp)
    80002d54:	f022                	sd	s0,32(sp)
    80002d56:	ec26                	sd	s1,24(sp)
    80002d58:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d5a:	fdc40593          	add	a1,s0,-36
    80002d5e:	4501                	li	a0,0
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	e84080e7          	jalr	-380(ra) # 80002be4 <argint>
  addr = myproc()->sz;
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	cbc080e7          	jalr	-836(ra) # 80001a24 <myproc>
    80002d70:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d72:	fdc42503          	lw	a0,-36(s0)
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	036080e7          	jalr	54(ra) # 80001dac <growproc>
    80002d7e:	00054863          	bltz	a0,80002d8e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d82:	8526                	mv	a0,s1
    80002d84:	70a2                	ld	ra,40(sp)
    80002d86:	7402                	ld	s0,32(sp)
    80002d88:	64e2                	ld	s1,24(sp)
    80002d8a:	6145                	add	sp,sp,48
    80002d8c:	8082                	ret
    return -1;
    80002d8e:	54fd                	li	s1,-1
    80002d90:	bfcd                	j	80002d82 <sys_sbrk+0x32>

0000000080002d92 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d92:	7139                	add	sp,sp,-64
    80002d94:	fc06                	sd	ra,56(sp)
    80002d96:	f822                	sd	s0,48(sp)
    80002d98:	f426                	sd	s1,40(sp)
    80002d9a:	f04a                	sd	s2,32(sp)
    80002d9c:	ec4e                	sd	s3,24(sp)
    80002d9e:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002da0:	fcc40593          	add	a1,s0,-52
    80002da4:	4501                	li	a0,0
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	e3e080e7          	jalr	-450(ra) # 80002be4 <argint>
  acquire(&tickslock);
    80002dae:	00014517          	auipc	a0,0x14
    80002db2:	20250513          	add	a0,a0,514 # 80016fb0 <tickslock>
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	e92080e7          	jalr	-366(ra) # 80000c48 <acquire>
  ticks0 = ticks;
    80002dbe:	00006917          	auipc	s2,0x6
    80002dc2:	f5292903          	lw	s2,-174(s2) # 80008d10 <ticks>
  while(ticks - ticks0 < n){
    80002dc6:	fcc42783          	lw	a5,-52(s0)
    80002dca:	cf9d                	beqz	a5,80002e08 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dcc:	00014997          	auipc	s3,0x14
    80002dd0:	1e498993          	add	s3,s3,484 # 80016fb0 <tickslock>
    80002dd4:	00006497          	auipc	s1,0x6
    80002dd8:	f3c48493          	add	s1,s1,-196 # 80008d10 <ticks>
    if(killed(myproc())){
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	c48080e7          	jalr	-952(ra) # 80001a24 <myproc>
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	5be080e7          	jalr	1470(ra) # 800023a2 <killed>
    80002dec:	ed15                	bnez	a0,80002e28 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dee:	85ce                	mv	a1,s3
    80002df0:	8526                	mv	a0,s1
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	308080e7          	jalr	776(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    80002dfa:	409c                	lw	a5,0(s1)
    80002dfc:	412787bb          	subw	a5,a5,s2
    80002e00:	fcc42703          	lw	a4,-52(s0)
    80002e04:	fce7ece3          	bltu	a5,a4,80002ddc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e08:	00014517          	auipc	a0,0x14
    80002e0c:	1a850513          	add	a0,a0,424 # 80016fb0 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	eec080e7          	jalr	-276(ra) # 80000cfc <release>
  return 0;
    80002e18:	4501                	li	a0,0
}
    80002e1a:	70e2                	ld	ra,56(sp)
    80002e1c:	7442                	ld	s0,48(sp)
    80002e1e:	74a2                	ld	s1,40(sp)
    80002e20:	7902                	ld	s2,32(sp)
    80002e22:	69e2                	ld	s3,24(sp)
    80002e24:	6121                	add	sp,sp,64
    80002e26:	8082                	ret
      release(&tickslock);
    80002e28:	00014517          	auipc	a0,0x14
    80002e2c:	18850513          	add	a0,a0,392 # 80016fb0 <tickslock>
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	ecc080e7          	jalr	-308(ra) # 80000cfc <release>
      return -1;
    80002e38:	557d                	li	a0,-1
    80002e3a:	b7c5                	j	80002e1a <sys_sleep+0x88>

0000000080002e3c <sys_kill>:

uint64
sys_kill(void)
{
    80002e3c:	1101                	add	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e44:	fec40593          	add	a1,s0,-20
    80002e48:	4501                	li	a0,0
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	d9a080e7          	jalr	-614(ra) # 80002be4 <argint>
  return kill(pid);
    80002e52:	fec42503          	lw	a0,-20(s0)
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	4ae080e7          	jalr	1198(ra) # 80002304 <kill>
}
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	6105                	add	sp,sp,32
    80002e64:	8082                	ret

0000000080002e66 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e66:	1101                	add	sp,sp,-32
    80002e68:	ec06                	sd	ra,24(sp)
    80002e6a:	e822                	sd	s0,16(sp)
    80002e6c:	e426                	sd	s1,8(sp)
    80002e6e:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e70:	00014517          	auipc	a0,0x14
    80002e74:	14050513          	add	a0,a0,320 # 80016fb0 <tickslock>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	dd0080e7          	jalr	-560(ra) # 80000c48 <acquire>
  xticks = ticks;
    80002e80:	00006497          	auipc	s1,0x6
    80002e84:	e904a483          	lw	s1,-368(s1) # 80008d10 <ticks>
  release(&tickslock);
    80002e88:	00014517          	auipc	a0,0x14
    80002e8c:	12850513          	add	a0,a0,296 # 80016fb0 <tickslock>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	e6c080e7          	jalr	-404(ra) # 80000cfc <release>
  return xticks;
}
    80002e98:	02049513          	sll	a0,s1,0x20
    80002e9c:	9101                	srl	a0,a0,0x20
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	64a2                	ld	s1,8(sp)
    80002ea4:	6105                	add	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ea8:	7179                	add	sp,sp,-48
    80002eaa:	f406                	sd	ra,40(sp)
    80002eac:	f022                	sd	s0,32(sp)
    80002eae:	ec26                	sd	s1,24(sp)
    80002eb0:	e84a                	sd	s2,16(sp)
    80002eb2:	e44e                	sd	s3,8(sp)
    80002eb4:	e052                	sd	s4,0(sp)
    80002eb6:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eb8:	00005597          	auipc	a1,0x5
    80002ebc:	69058593          	add	a1,a1,1680 # 80008548 <syscalls+0xb0>
    80002ec0:	00014517          	auipc	a0,0x14
    80002ec4:	10850513          	add	a0,a0,264 # 80016fc8 <bcache>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	cf0080e7          	jalr	-784(ra) # 80000bb8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed0:	0001c797          	auipc	a5,0x1c
    80002ed4:	0f878793          	add	a5,a5,248 # 8001efc8 <bcache+0x8000>
    80002ed8:	0001c717          	auipc	a4,0x1c
    80002edc:	35870713          	add	a4,a4,856 # 8001f230 <bcache+0x8268>
    80002ee0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ee4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee8:	00014497          	auipc	s1,0x14
    80002eec:	0f848493          	add	s1,s1,248 # 80016fe0 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ef2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ef4:	00005a17          	auipc	s4,0x5
    80002ef8:	65ca0a13          	add	s4,s4,1628 # 80008550 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002efc:	2b893783          	ld	a5,696(s2)
    80002f00:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f02:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f06:	85d2                	mv	a1,s4
    80002f08:	01048513          	add	a0,s1,16
    80002f0c:	00001097          	auipc	ra,0x1
    80002f10:	496080e7          	jalr	1174(ra) # 800043a2 <initsleeplock>
    bcache.head.next->prev = b;
    80002f14:	2b893783          	ld	a5,696(s2)
    80002f18:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f1a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f1e:	45848493          	add	s1,s1,1112
    80002f22:	fd349de3          	bne	s1,s3,80002efc <binit+0x54>
  }
}
    80002f26:	70a2                	ld	ra,40(sp)
    80002f28:	7402                	ld	s0,32(sp)
    80002f2a:	64e2                	ld	s1,24(sp)
    80002f2c:	6942                	ld	s2,16(sp)
    80002f2e:	69a2                	ld	s3,8(sp)
    80002f30:	6a02                	ld	s4,0(sp)
    80002f32:	6145                	add	sp,sp,48
    80002f34:	8082                	ret

0000000080002f36 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f36:	7179                	add	sp,sp,-48
    80002f38:	f406                	sd	ra,40(sp)
    80002f3a:	f022                	sd	s0,32(sp)
    80002f3c:	ec26                	sd	s1,24(sp)
    80002f3e:	e84a                	sd	s2,16(sp)
    80002f40:	e44e                	sd	s3,8(sp)
    80002f42:	1800                	add	s0,sp,48
    80002f44:	892a                	mv	s2,a0
    80002f46:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f48:	00014517          	auipc	a0,0x14
    80002f4c:	08050513          	add	a0,a0,128 # 80016fc8 <bcache>
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	cf8080e7          	jalr	-776(ra) # 80000c48 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f58:	0001c497          	auipc	s1,0x1c
    80002f5c:	3284b483          	ld	s1,808(s1) # 8001f280 <bcache+0x82b8>
    80002f60:	0001c797          	auipc	a5,0x1c
    80002f64:	2d078793          	add	a5,a5,720 # 8001f230 <bcache+0x8268>
    80002f68:	02f48f63          	beq	s1,a5,80002fa6 <bread+0x70>
    80002f6c:	873e                	mv	a4,a5
    80002f6e:	a021                	j	80002f76 <bread+0x40>
    80002f70:	68a4                	ld	s1,80(s1)
    80002f72:	02e48a63          	beq	s1,a4,80002fa6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f76:	449c                	lw	a5,8(s1)
    80002f78:	ff279ce3          	bne	a5,s2,80002f70 <bread+0x3a>
    80002f7c:	44dc                	lw	a5,12(s1)
    80002f7e:	ff3799e3          	bne	a5,s3,80002f70 <bread+0x3a>
      b->refcnt++;
    80002f82:	40bc                	lw	a5,64(s1)
    80002f84:	2785                	addw	a5,a5,1
    80002f86:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f88:	00014517          	auipc	a0,0x14
    80002f8c:	04050513          	add	a0,a0,64 # 80016fc8 <bcache>
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	d6c080e7          	jalr	-660(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002f98:	01048513          	add	a0,s1,16
    80002f9c:	00001097          	auipc	ra,0x1
    80002fa0:	440080e7          	jalr	1088(ra) # 800043dc <acquiresleep>
      return b;
    80002fa4:	a8b9                	j	80003002 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa6:	0001c497          	auipc	s1,0x1c
    80002faa:	2d24b483          	ld	s1,722(s1) # 8001f278 <bcache+0x82b0>
    80002fae:	0001c797          	auipc	a5,0x1c
    80002fb2:	28278793          	add	a5,a5,642 # 8001f230 <bcache+0x8268>
    80002fb6:	00f48863          	beq	s1,a5,80002fc6 <bread+0x90>
    80002fba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fbc:	40bc                	lw	a5,64(s1)
    80002fbe:	cf81                	beqz	a5,80002fd6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc0:	64a4                	ld	s1,72(s1)
    80002fc2:	fee49de3          	bne	s1,a4,80002fbc <bread+0x86>
  panic("bget: no buffers");
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	59250513          	add	a0,a0,1426 # 80008558 <syscalls+0xc0>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	572080e7          	jalr	1394(ra) # 80000540 <panic>
      b->dev = dev;
    80002fd6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fda:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fde:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fe2:	4785                	li	a5,1
    80002fe4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe6:	00014517          	auipc	a0,0x14
    80002fea:	fe250513          	add	a0,a0,-30 # 80016fc8 <bcache>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	d0e080e7          	jalr	-754(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002ff6:	01048513          	add	a0,s1,16
    80002ffa:	00001097          	auipc	ra,0x1
    80002ffe:	3e2080e7          	jalr	994(ra) # 800043dc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003002:	409c                	lw	a5,0(s1)
    80003004:	cb89                	beqz	a5,80003016 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003006:	8526                	mv	a0,s1
    80003008:	70a2                	ld	ra,40(sp)
    8000300a:	7402                	ld	s0,32(sp)
    8000300c:	64e2                	ld	s1,24(sp)
    8000300e:	6942                	ld	s2,16(sp)
    80003010:	69a2                	ld	s3,8(sp)
    80003012:	6145                	add	sp,sp,48
    80003014:	8082                	ret
    virtio_disk_rw(b, 0);
    80003016:	4581                	li	a1,0
    80003018:	8526                	mv	a0,s1
    8000301a:	00003097          	auipc	ra,0x3
    8000301e:	19a080e7          	jalr	410(ra) # 800061b4 <virtio_disk_rw>
    b->valid = 1;
    80003022:	4785                	li	a5,1
    80003024:	c09c                	sw	a5,0(s1)
  return b;
    80003026:	b7c5                	j	80003006 <bread+0xd0>

0000000080003028 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003028:	1101                	add	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	1000                	add	s0,sp,32
    80003032:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003034:	0541                	add	a0,a0,16
    80003036:	00001097          	auipc	ra,0x1
    8000303a:	440080e7          	jalr	1088(ra) # 80004476 <holdingsleep>
    8000303e:	cd01                	beqz	a0,80003056 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003040:	4585                	li	a1,1
    80003042:	8526                	mv	a0,s1
    80003044:	00003097          	auipc	ra,0x3
    80003048:	170080e7          	jalr	368(ra) # 800061b4 <virtio_disk_rw>
}
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6105                	add	sp,sp,32
    80003054:	8082                	ret
    panic("bwrite");
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	51a50513          	add	a0,a0,1306 # 80008570 <syscalls+0xd8>
    8000305e:	ffffd097          	auipc	ra,0xffffd
    80003062:	4e2080e7          	jalr	1250(ra) # 80000540 <panic>

0000000080003066 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003066:	1101                	add	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	e426                	sd	s1,8(sp)
    8000306e:	e04a                	sd	s2,0(sp)
    80003070:	1000                	add	s0,sp,32
    80003072:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003074:	01050913          	add	s2,a0,16
    80003078:	854a                	mv	a0,s2
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	3fc080e7          	jalr	1020(ra) # 80004476 <holdingsleep>
    80003082:	c925                	beqz	a0,800030f2 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003084:	854a                	mv	a0,s2
    80003086:	00001097          	auipc	ra,0x1
    8000308a:	3ac080e7          	jalr	940(ra) # 80004432 <releasesleep>

  acquire(&bcache.lock);
    8000308e:	00014517          	auipc	a0,0x14
    80003092:	f3a50513          	add	a0,a0,-198 # 80016fc8 <bcache>
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	bb2080e7          	jalr	-1102(ra) # 80000c48 <acquire>
  b->refcnt--;
    8000309e:	40bc                	lw	a5,64(s1)
    800030a0:	37fd                	addw	a5,a5,-1
    800030a2:	0007871b          	sext.w	a4,a5
    800030a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030a8:	e71d                	bnez	a4,800030d6 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030aa:	68b8                	ld	a4,80(s1)
    800030ac:	64bc                	ld	a5,72(s1)
    800030ae:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800030b0:	68b8                	ld	a4,80(s1)
    800030b2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030b4:	0001c797          	auipc	a5,0x1c
    800030b8:	f1478793          	add	a5,a5,-236 # 8001efc8 <bcache+0x8000>
    800030bc:	2b87b703          	ld	a4,696(a5)
    800030c0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030c2:	0001c717          	auipc	a4,0x1c
    800030c6:	16e70713          	add	a4,a4,366 # 8001f230 <bcache+0x8268>
    800030ca:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030cc:	2b87b703          	ld	a4,696(a5)
    800030d0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030d2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	ef250513          	add	a0,a0,-270 # 80016fc8 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	c1e080e7          	jalr	-994(ra) # 80000cfc <release>
}
    800030e6:	60e2                	ld	ra,24(sp)
    800030e8:	6442                	ld	s0,16(sp)
    800030ea:	64a2                	ld	s1,8(sp)
    800030ec:	6902                	ld	s2,0(sp)
    800030ee:	6105                	add	sp,sp,32
    800030f0:	8082                	ret
    panic("brelse");
    800030f2:	00005517          	auipc	a0,0x5
    800030f6:	48650513          	add	a0,a0,1158 # 80008578 <syscalls+0xe0>
    800030fa:	ffffd097          	auipc	ra,0xffffd
    800030fe:	446080e7          	jalr	1094(ra) # 80000540 <panic>

0000000080003102 <bpin>:

void
bpin(struct buf *b) {
    80003102:	1101                	add	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	e426                	sd	s1,8(sp)
    8000310a:	1000                	add	s0,sp,32
    8000310c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000310e:	00014517          	auipc	a0,0x14
    80003112:	eba50513          	add	a0,a0,-326 # 80016fc8 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b32080e7          	jalr	-1230(ra) # 80000c48 <acquire>
  b->refcnt++;
    8000311e:	40bc                	lw	a5,64(s1)
    80003120:	2785                	addw	a5,a5,1
    80003122:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003124:	00014517          	auipc	a0,0x14
    80003128:	ea450513          	add	a0,a0,-348 # 80016fc8 <bcache>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	bd0080e7          	jalr	-1072(ra) # 80000cfc <release>
}
    80003134:	60e2                	ld	ra,24(sp)
    80003136:	6442                	ld	s0,16(sp)
    80003138:	64a2                	ld	s1,8(sp)
    8000313a:	6105                	add	sp,sp,32
    8000313c:	8082                	ret

000000008000313e <bunpin>:

void
bunpin(struct buf *b) {
    8000313e:	1101                	add	sp,sp,-32
    80003140:	ec06                	sd	ra,24(sp)
    80003142:	e822                	sd	s0,16(sp)
    80003144:	e426                	sd	s1,8(sp)
    80003146:	1000                	add	s0,sp,32
    80003148:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000314a:	00014517          	auipc	a0,0x14
    8000314e:	e7e50513          	add	a0,a0,-386 # 80016fc8 <bcache>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	af6080e7          	jalr	-1290(ra) # 80000c48 <acquire>
  b->refcnt--;
    8000315a:	40bc                	lw	a5,64(s1)
    8000315c:	37fd                	addw	a5,a5,-1
    8000315e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003160:	00014517          	auipc	a0,0x14
    80003164:	e6850513          	add	a0,a0,-408 # 80016fc8 <bcache>
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	b94080e7          	jalr	-1132(ra) # 80000cfc <release>
}
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	64a2                	ld	s1,8(sp)
    80003176:	6105                	add	sp,sp,32
    80003178:	8082                	ret

000000008000317a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000317a:	1101                	add	sp,sp,-32
    8000317c:	ec06                	sd	ra,24(sp)
    8000317e:	e822                	sd	s0,16(sp)
    80003180:	e426                	sd	s1,8(sp)
    80003182:	e04a                	sd	s2,0(sp)
    80003184:	1000                	add	s0,sp,32
    80003186:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003188:	00d5d59b          	srlw	a1,a1,0xd
    8000318c:	0001c797          	auipc	a5,0x1c
    80003190:	5187a783          	lw	a5,1304(a5) # 8001f6a4 <sb+0x1c>
    80003194:	9dbd                	addw	a1,a1,a5
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	da0080e7          	jalr	-608(ra) # 80002f36 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000319e:	0074f713          	and	a4,s1,7
    800031a2:	4785                	li	a5,1
    800031a4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031a8:	14ce                	sll	s1,s1,0x33
    800031aa:	90d9                	srl	s1,s1,0x36
    800031ac:	00950733          	add	a4,a0,s1
    800031b0:	05874703          	lbu	a4,88(a4)
    800031b4:	00e7f6b3          	and	a3,a5,a4
    800031b8:	c69d                	beqz	a3,800031e6 <bfree+0x6c>
    800031ba:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031bc:	94aa                	add	s1,s1,a0
    800031be:	fff7c793          	not	a5,a5
    800031c2:	8f7d                	and	a4,a4,a5
    800031c4:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031c8:	00001097          	auipc	ra,0x1
    800031cc:	0f6080e7          	jalr	246(ra) # 800042be <log_write>
  brelse(bp);
    800031d0:	854a                	mv	a0,s2
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	e94080e7          	jalr	-364(ra) # 80003066 <brelse>
}
    800031da:	60e2                	ld	ra,24(sp)
    800031dc:	6442                	ld	s0,16(sp)
    800031de:	64a2                	ld	s1,8(sp)
    800031e0:	6902                	ld	s2,0(sp)
    800031e2:	6105                	add	sp,sp,32
    800031e4:	8082                	ret
    panic("freeing free block");
    800031e6:	00005517          	auipc	a0,0x5
    800031ea:	39a50513          	add	a0,a0,922 # 80008580 <syscalls+0xe8>
    800031ee:	ffffd097          	auipc	ra,0xffffd
    800031f2:	352080e7          	jalr	850(ra) # 80000540 <panic>

00000000800031f6 <balloc>:
{
    800031f6:	711d                	add	sp,sp,-96
    800031f8:	ec86                	sd	ra,88(sp)
    800031fa:	e8a2                	sd	s0,80(sp)
    800031fc:	e4a6                	sd	s1,72(sp)
    800031fe:	e0ca                	sd	s2,64(sp)
    80003200:	fc4e                	sd	s3,56(sp)
    80003202:	f852                	sd	s4,48(sp)
    80003204:	f456                	sd	s5,40(sp)
    80003206:	f05a                	sd	s6,32(sp)
    80003208:	ec5e                	sd	s7,24(sp)
    8000320a:	e862                	sd	s8,16(sp)
    8000320c:	e466                	sd	s9,8(sp)
    8000320e:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003210:	0001c797          	auipc	a5,0x1c
    80003214:	47c7a783          	lw	a5,1148(a5) # 8001f68c <sb+0x4>
    80003218:	cff5                	beqz	a5,80003314 <balloc+0x11e>
    8000321a:	8baa                	mv	s7,a0
    8000321c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000321e:	0001cb17          	auipc	s6,0x1c
    80003222:	46ab0b13          	add	s6,s6,1130 # 8001f688 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003226:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003228:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000322c:	6c89                	lui	s9,0x2
    8000322e:	a061                	j	800032b6 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003230:	97ca                	add	a5,a5,s2
    80003232:	8e55                	or	a2,a2,a3
    80003234:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003238:	854a                	mv	a0,s2
    8000323a:	00001097          	auipc	ra,0x1
    8000323e:	084080e7          	jalr	132(ra) # 800042be <log_write>
        brelse(bp);
    80003242:	854a                	mv	a0,s2
    80003244:	00000097          	auipc	ra,0x0
    80003248:	e22080e7          	jalr	-478(ra) # 80003066 <brelse>
  bp = bread(dev, bno);
    8000324c:	85a6                	mv	a1,s1
    8000324e:	855e                	mv	a0,s7
    80003250:	00000097          	auipc	ra,0x0
    80003254:	ce6080e7          	jalr	-794(ra) # 80002f36 <bread>
    80003258:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000325a:	40000613          	li	a2,1024
    8000325e:	4581                	li	a1,0
    80003260:	05850513          	add	a0,a0,88
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	ae0080e7          	jalr	-1312(ra) # 80000d44 <memset>
  log_write(bp);
    8000326c:	854a                	mv	a0,s2
    8000326e:	00001097          	auipc	ra,0x1
    80003272:	050080e7          	jalr	80(ra) # 800042be <log_write>
  brelse(bp);
    80003276:	854a                	mv	a0,s2
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	dee080e7          	jalr	-530(ra) # 80003066 <brelse>
}
    80003280:	8526                	mv	a0,s1
    80003282:	60e6                	ld	ra,88(sp)
    80003284:	6446                	ld	s0,80(sp)
    80003286:	64a6                	ld	s1,72(sp)
    80003288:	6906                	ld	s2,64(sp)
    8000328a:	79e2                	ld	s3,56(sp)
    8000328c:	7a42                	ld	s4,48(sp)
    8000328e:	7aa2                	ld	s5,40(sp)
    80003290:	7b02                	ld	s6,32(sp)
    80003292:	6be2                	ld	s7,24(sp)
    80003294:	6c42                	ld	s8,16(sp)
    80003296:	6ca2                	ld	s9,8(sp)
    80003298:	6125                	add	sp,sp,96
    8000329a:	8082                	ret
    brelse(bp);
    8000329c:	854a                	mv	a0,s2
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	dc8080e7          	jalr	-568(ra) # 80003066 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032a6:	015c87bb          	addw	a5,s9,s5
    800032aa:	00078a9b          	sext.w	s5,a5
    800032ae:	004b2703          	lw	a4,4(s6)
    800032b2:	06eaf163          	bgeu	s5,a4,80003314 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800032b6:	41fad79b          	sraw	a5,s5,0x1f
    800032ba:	0137d79b          	srlw	a5,a5,0x13
    800032be:	015787bb          	addw	a5,a5,s5
    800032c2:	40d7d79b          	sraw	a5,a5,0xd
    800032c6:	01cb2583          	lw	a1,28(s6)
    800032ca:	9dbd                	addw	a1,a1,a5
    800032cc:	855e                	mv	a0,s7
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	c68080e7          	jalr	-920(ra) # 80002f36 <bread>
    800032d6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d8:	004b2503          	lw	a0,4(s6)
    800032dc:	000a849b          	sext.w	s1,s5
    800032e0:	8762                	mv	a4,s8
    800032e2:	faa4fde3          	bgeu	s1,a0,8000329c <balloc+0xa6>
      m = 1 << (bi % 8);
    800032e6:	00777693          	and	a3,a4,7
    800032ea:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032ee:	41f7579b          	sraw	a5,a4,0x1f
    800032f2:	01d7d79b          	srlw	a5,a5,0x1d
    800032f6:	9fb9                	addw	a5,a5,a4
    800032f8:	4037d79b          	sraw	a5,a5,0x3
    800032fc:	00f90633          	add	a2,s2,a5
    80003300:	05864603          	lbu	a2,88(a2)
    80003304:	00c6f5b3          	and	a1,a3,a2
    80003308:	d585                	beqz	a1,80003230 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330a:	2705                	addw	a4,a4,1
    8000330c:	2485                	addw	s1,s1,1
    8000330e:	fd471ae3          	bne	a4,s4,800032e2 <balloc+0xec>
    80003312:	b769                	j	8000329c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003314:	00005517          	auipc	a0,0x5
    80003318:	28450513          	add	a0,a0,644 # 80008598 <syscalls+0x100>
    8000331c:	ffffd097          	auipc	ra,0xffffd
    80003320:	26e080e7          	jalr	622(ra) # 8000058a <printf>
  return 0;
    80003324:	4481                	li	s1,0
    80003326:	bfa9                	j	80003280 <balloc+0x8a>

0000000080003328 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003328:	7179                	add	sp,sp,-48
    8000332a:	f406                	sd	ra,40(sp)
    8000332c:	f022                	sd	s0,32(sp)
    8000332e:	ec26                	sd	s1,24(sp)
    80003330:	e84a                	sd	s2,16(sp)
    80003332:	e44e                	sd	s3,8(sp)
    80003334:	e052                	sd	s4,0(sp)
    80003336:	1800                	add	s0,sp,48
    80003338:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000333a:	47ad                	li	a5,11
    8000333c:	02b7e863          	bltu	a5,a1,8000336c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003340:	02059793          	sll	a5,a1,0x20
    80003344:	01e7d593          	srl	a1,a5,0x1e
    80003348:	00b504b3          	add	s1,a0,a1
    8000334c:	0504a903          	lw	s2,80(s1)
    80003350:	06091e63          	bnez	s2,800033cc <bmap+0xa4>
      addr = balloc(ip->dev);
    80003354:	4108                	lw	a0,0(a0)
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	ea0080e7          	jalr	-352(ra) # 800031f6 <balloc>
    8000335e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003362:	06090563          	beqz	s2,800033cc <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003366:	0524a823          	sw	s2,80(s1)
    8000336a:	a08d                	j	800033cc <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000336c:	ff45849b          	addw	s1,a1,-12
    80003370:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003374:	0ff00793          	li	a5,255
    80003378:	08e7e563          	bltu	a5,a4,80003402 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000337c:	08052903          	lw	s2,128(a0)
    80003380:	00091d63          	bnez	s2,8000339a <bmap+0x72>
      addr = balloc(ip->dev);
    80003384:	4108                	lw	a0,0(a0)
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e70080e7          	jalr	-400(ra) # 800031f6 <balloc>
    8000338e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003392:	02090d63          	beqz	s2,800033cc <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003396:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000339a:	85ca                	mv	a1,s2
    8000339c:	0009a503          	lw	a0,0(s3)
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	b96080e7          	jalr	-1130(ra) # 80002f36 <bread>
    800033a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033aa:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ae:	02049713          	sll	a4,s1,0x20
    800033b2:	01e75593          	srl	a1,a4,0x1e
    800033b6:	00b784b3          	add	s1,a5,a1
    800033ba:	0004a903          	lw	s2,0(s1)
    800033be:	02090063          	beqz	s2,800033de <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033c2:	8552                	mv	a0,s4
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	ca2080e7          	jalr	-862(ra) # 80003066 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033cc:	854a                	mv	a0,s2
    800033ce:	70a2                	ld	ra,40(sp)
    800033d0:	7402                	ld	s0,32(sp)
    800033d2:	64e2                	ld	s1,24(sp)
    800033d4:	6942                	ld	s2,16(sp)
    800033d6:	69a2                	ld	s3,8(sp)
    800033d8:	6a02                	ld	s4,0(sp)
    800033da:	6145                	add	sp,sp,48
    800033dc:	8082                	ret
      addr = balloc(ip->dev);
    800033de:	0009a503          	lw	a0,0(s3)
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	e14080e7          	jalr	-492(ra) # 800031f6 <balloc>
    800033ea:	0005091b          	sext.w	s2,a0
      if(addr){
    800033ee:	fc090ae3          	beqz	s2,800033c2 <bmap+0x9a>
        a[bn] = addr;
    800033f2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033f6:	8552                	mv	a0,s4
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	ec6080e7          	jalr	-314(ra) # 800042be <log_write>
    80003400:	b7c9                	j	800033c2 <bmap+0x9a>
  panic("bmap: out of range");
    80003402:	00005517          	auipc	a0,0x5
    80003406:	1ae50513          	add	a0,a0,430 # 800085b0 <syscalls+0x118>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	136080e7          	jalr	310(ra) # 80000540 <panic>

0000000080003412 <iget>:
{
    80003412:	7179                	add	sp,sp,-48
    80003414:	f406                	sd	ra,40(sp)
    80003416:	f022                	sd	s0,32(sp)
    80003418:	ec26                	sd	s1,24(sp)
    8000341a:	e84a                	sd	s2,16(sp)
    8000341c:	e44e                	sd	s3,8(sp)
    8000341e:	e052                	sd	s4,0(sp)
    80003420:	1800                	add	s0,sp,48
    80003422:	89aa                	mv	s3,a0
    80003424:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003426:	0001c517          	auipc	a0,0x1c
    8000342a:	28250513          	add	a0,a0,642 # 8001f6a8 <itable>
    8000342e:	ffffe097          	auipc	ra,0xffffe
    80003432:	81a080e7          	jalr	-2022(ra) # 80000c48 <acquire>
  empty = 0;
    80003436:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003438:	0001c497          	auipc	s1,0x1c
    8000343c:	28848493          	add	s1,s1,648 # 8001f6c0 <itable+0x18>
    80003440:	0001e697          	auipc	a3,0x1e
    80003444:	d1068693          	add	a3,a3,-752 # 80021150 <log>
    80003448:	a039                	j	80003456 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000344a:	02090b63          	beqz	s2,80003480 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000344e:	08848493          	add	s1,s1,136
    80003452:	02d48a63          	beq	s1,a3,80003486 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003456:	449c                	lw	a5,8(s1)
    80003458:	fef059e3          	blez	a5,8000344a <iget+0x38>
    8000345c:	4098                	lw	a4,0(s1)
    8000345e:	ff3716e3          	bne	a4,s3,8000344a <iget+0x38>
    80003462:	40d8                	lw	a4,4(s1)
    80003464:	ff4713e3          	bne	a4,s4,8000344a <iget+0x38>
      ip->ref++;
    80003468:	2785                	addw	a5,a5,1
    8000346a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000346c:	0001c517          	auipc	a0,0x1c
    80003470:	23c50513          	add	a0,a0,572 # 8001f6a8 <itable>
    80003474:	ffffe097          	auipc	ra,0xffffe
    80003478:	888080e7          	jalr	-1912(ra) # 80000cfc <release>
      return ip;
    8000347c:	8926                	mv	s2,s1
    8000347e:	a03d                	j	800034ac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003480:	f7f9                	bnez	a5,8000344e <iget+0x3c>
    80003482:	8926                	mv	s2,s1
    80003484:	b7e9                	j	8000344e <iget+0x3c>
  if(empty == 0)
    80003486:	02090c63          	beqz	s2,800034be <iget+0xac>
  ip->dev = dev;
    8000348a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000348e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003492:	4785                	li	a5,1
    80003494:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003498:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000349c:	0001c517          	auipc	a0,0x1c
    800034a0:	20c50513          	add	a0,a0,524 # 8001f6a8 <itable>
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	858080e7          	jalr	-1960(ra) # 80000cfc <release>
}
    800034ac:	854a                	mv	a0,s2
    800034ae:	70a2                	ld	ra,40(sp)
    800034b0:	7402                	ld	s0,32(sp)
    800034b2:	64e2                	ld	s1,24(sp)
    800034b4:	6942                	ld	s2,16(sp)
    800034b6:	69a2                	ld	s3,8(sp)
    800034b8:	6a02                	ld	s4,0(sp)
    800034ba:	6145                	add	sp,sp,48
    800034bc:	8082                	ret
    panic("iget: no inodes");
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	10a50513          	add	a0,a0,266 # 800085c8 <syscalls+0x130>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	07a080e7          	jalr	122(ra) # 80000540 <panic>

00000000800034ce <fsinit>:
fsinit(int dev) {
    800034ce:	7179                	add	sp,sp,-48
    800034d0:	f406                	sd	ra,40(sp)
    800034d2:	f022                	sd	s0,32(sp)
    800034d4:	ec26                	sd	s1,24(sp)
    800034d6:	e84a                	sd	s2,16(sp)
    800034d8:	e44e                	sd	s3,8(sp)
    800034da:	1800                	add	s0,sp,48
    800034dc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034de:	4585                	li	a1,1
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	a56080e7          	jalr	-1450(ra) # 80002f36 <bread>
    800034e8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ea:	0001c997          	auipc	s3,0x1c
    800034ee:	19e98993          	add	s3,s3,414 # 8001f688 <sb>
    800034f2:	02000613          	li	a2,32
    800034f6:	05850593          	add	a1,a0,88
    800034fa:	854e                	mv	a0,s3
    800034fc:	ffffe097          	auipc	ra,0xffffe
    80003500:	8a4080e7          	jalr	-1884(ra) # 80000da0 <memmove>
  brelse(bp);
    80003504:	8526                	mv	a0,s1
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	b60080e7          	jalr	-1184(ra) # 80003066 <brelse>
  if(sb.magic != FSMAGIC)
    8000350e:	0009a703          	lw	a4,0(s3)
    80003512:	102037b7          	lui	a5,0x10203
    80003516:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000351a:	02f71263          	bne	a4,a5,8000353e <fsinit+0x70>
  initlog(dev, &sb);
    8000351e:	0001c597          	auipc	a1,0x1c
    80003522:	16a58593          	add	a1,a1,362 # 8001f688 <sb>
    80003526:	854a                	mv	a0,s2
    80003528:	00001097          	auipc	ra,0x1
    8000352c:	b2c080e7          	jalr	-1236(ra) # 80004054 <initlog>
}
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6145                	add	sp,sp,48
    8000353c:	8082                	ret
    panic("invalid file system");
    8000353e:	00005517          	auipc	a0,0x5
    80003542:	09a50513          	add	a0,a0,154 # 800085d8 <syscalls+0x140>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	ffa080e7          	jalr	-6(ra) # 80000540 <panic>

000000008000354e <iinit>:
{
    8000354e:	7179                	add	sp,sp,-48
    80003550:	f406                	sd	ra,40(sp)
    80003552:	f022                	sd	s0,32(sp)
    80003554:	ec26                	sd	s1,24(sp)
    80003556:	e84a                	sd	s2,16(sp)
    80003558:	e44e                	sd	s3,8(sp)
    8000355a:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    8000355c:	00005597          	auipc	a1,0x5
    80003560:	09458593          	add	a1,a1,148 # 800085f0 <syscalls+0x158>
    80003564:	0001c517          	auipc	a0,0x1c
    80003568:	14450513          	add	a0,a0,324 # 8001f6a8 <itable>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	64c080e7          	jalr	1612(ra) # 80000bb8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003574:	0001c497          	auipc	s1,0x1c
    80003578:	15c48493          	add	s1,s1,348 # 8001f6d0 <itable+0x28>
    8000357c:	0001e997          	auipc	s3,0x1e
    80003580:	be498993          	add	s3,s3,-1052 # 80021160 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003584:	00005917          	auipc	s2,0x5
    80003588:	07490913          	add	s2,s2,116 # 800085f8 <syscalls+0x160>
    8000358c:	85ca                	mv	a1,s2
    8000358e:	8526                	mv	a0,s1
    80003590:	00001097          	auipc	ra,0x1
    80003594:	e12080e7          	jalr	-494(ra) # 800043a2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003598:	08848493          	add	s1,s1,136
    8000359c:	ff3498e3          	bne	s1,s3,8000358c <iinit+0x3e>
}
    800035a0:	70a2                	ld	ra,40(sp)
    800035a2:	7402                	ld	s0,32(sp)
    800035a4:	64e2                	ld	s1,24(sp)
    800035a6:	6942                	ld	s2,16(sp)
    800035a8:	69a2                	ld	s3,8(sp)
    800035aa:	6145                	add	sp,sp,48
    800035ac:	8082                	ret

00000000800035ae <ialloc>:
{
    800035ae:	7139                	add	sp,sp,-64
    800035b0:	fc06                	sd	ra,56(sp)
    800035b2:	f822                	sd	s0,48(sp)
    800035b4:	f426                	sd	s1,40(sp)
    800035b6:	f04a                	sd	s2,32(sp)
    800035b8:	ec4e                	sd	s3,24(sp)
    800035ba:	e852                	sd	s4,16(sp)
    800035bc:	e456                	sd	s5,8(sp)
    800035be:	e05a                	sd	s6,0(sp)
    800035c0:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035c2:	0001c717          	auipc	a4,0x1c
    800035c6:	0d272703          	lw	a4,210(a4) # 8001f694 <sb+0xc>
    800035ca:	4785                	li	a5,1
    800035cc:	04e7f863          	bgeu	a5,a4,8000361c <ialloc+0x6e>
    800035d0:	8aaa                	mv	s5,a0
    800035d2:	8b2e                	mv	s6,a1
    800035d4:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035d6:	0001ca17          	auipc	s4,0x1c
    800035da:	0b2a0a13          	add	s4,s4,178 # 8001f688 <sb>
    800035de:	00495593          	srl	a1,s2,0x4
    800035e2:	018a2783          	lw	a5,24(s4)
    800035e6:	9dbd                	addw	a1,a1,a5
    800035e8:	8556                	mv	a0,s5
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	94c080e7          	jalr	-1716(ra) # 80002f36 <bread>
    800035f2:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035f4:	05850993          	add	s3,a0,88
    800035f8:	00f97793          	and	a5,s2,15
    800035fc:	079a                	sll	a5,a5,0x6
    800035fe:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003600:	00099783          	lh	a5,0(s3)
    80003604:	cf9d                	beqz	a5,80003642 <ialloc+0x94>
    brelse(bp);
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	a60080e7          	jalr	-1440(ra) # 80003066 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000360e:	0905                	add	s2,s2,1
    80003610:	00ca2703          	lw	a4,12(s4)
    80003614:	0009079b          	sext.w	a5,s2
    80003618:	fce7e3e3          	bltu	a5,a4,800035de <ialloc+0x30>
  printf("ialloc: no inodes\n");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	fe450513          	add	a0,a0,-28 # 80008600 <syscalls+0x168>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f66080e7          	jalr	-154(ra) # 8000058a <printf>
  return 0;
    8000362c:	4501                	li	a0,0
}
    8000362e:	70e2                	ld	ra,56(sp)
    80003630:	7442                	ld	s0,48(sp)
    80003632:	74a2                	ld	s1,40(sp)
    80003634:	7902                	ld	s2,32(sp)
    80003636:	69e2                	ld	s3,24(sp)
    80003638:	6a42                	ld	s4,16(sp)
    8000363a:	6aa2                	ld	s5,8(sp)
    8000363c:	6b02                	ld	s6,0(sp)
    8000363e:	6121                	add	sp,sp,64
    80003640:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003642:	04000613          	li	a2,64
    80003646:	4581                	li	a1,0
    80003648:	854e                	mv	a0,s3
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	6fa080e7          	jalr	1786(ra) # 80000d44 <memset>
      dip->type = type;
    80003652:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003656:	8526                	mv	a0,s1
    80003658:	00001097          	auipc	ra,0x1
    8000365c:	c66080e7          	jalr	-922(ra) # 800042be <log_write>
      brelse(bp);
    80003660:	8526                	mv	a0,s1
    80003662:	00000097          	auipc	ra,0x0
    80003666:	a04080e7          	jalr	-1532(ra) # 80003066 <brelse>
      return iget(dev, inum);
    8000366a:	0009059b          	sext.w	a1,s2
    8000366e:	8556                	mv	a0,s5
    80003670:	00000097          	auipc	ra,0x0
    80003674:	da2080e7          	jalr	-606(ra) # 80003412 <iget>
    80003678:	bf5d                	j	8000362e <ialloc+0x80>

000000008000367a <iupdate>:
{
    8000367a:	1101                	add	sp,sp,-32
    8000367c:	ec06                	sd	ra,24(sp)
    8000367e:	e822                	sd	s0,16(sp)
    80003680:	e426                	sd	s1,8(sp)
    80003682:	e04a                	sd	s2,0(sp)
    80003684:	1000                	add	s0,sp,32
    80003686:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003688:	415c                	lw	a5,4(a0)
    8000368a:	0047d79b          	srlw	a5,a5,0x4
    8000368e:	0001c597          	auipc	a1,0x1c
    80003692:	0125a583          	lw	a1,18(a1) # 8001f6a0 <sb+0x18>
    80003696:	9dbd                	addw	a1,a1,a5
    80003698:	4108                	lw	a0,0(a0)
    8000369a:	00000097          	auipc	ra,0x0
    8000369e:	89c080e7          	jalr	-1892(ra) # 80002f36 <bread>
    800036a2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036a4:	05850793          	add	a5,a0,88
    800036a8:	40d8                	lw	a4,4(s1)
    800036aa:	8b3d                	and	a4,a4,15
    800036ac:	071a                	sll	a4,a4,0x6
    800036ae:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036b0:	04449703          	lh	a4,68(s1)
    800036b4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036b8:	04649703          	lh	a4,70(s1)
    800036bc:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036c0:	04849703          	lh	a4,72(s1)
    800036c4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036c8:	04a49703          	lh	a4,74(s1)
    800036cc:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036d0:	44f8                	lw	a4,76(s1)
    800036d2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036d4:	03400613          	li	a2,52
    800036d8:	05048593          	add	a1,s1,80
    800036dc:	00c78513          	add	a0,a5,12
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	6c0080e7          	jalr	1728(ra) # 80000da0 <memmove>
  log_write(bp);
    800036e8:	854a                	mv	a0,s2
    800036ea:	00001097          	auipc	ra,0x1
    800036ee:	bd4080e7          	jalr	-1068(ra) # 800042be <log_write>
  brelse(bp);
    800036f2:	854a                	mv	a0,s2
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	972080e7          	jalr	-1678(ra) # 80003066 <brelse>
}
    800036fc:	60e2                	ld	ra,24(sp)
    800036fe:	6442                	ld	s0,16(sp)
    80003700:	64a2                	ld	s1,8(sp)
    80003702:	6902                	ld	s2,0(sp)
    80003704:	6105                	add	sp,sp,32
    80003706:	8082                	ret

0000000080003708 <idup>:
{
    80003708:	1101                	add	sp,sp,-32
    8000370a:	ec06                	sd	ra,24(sp)
    8000370c:	e822                	sd	s0,16(sp)
    8000370e:	e426                	sd	s1,8(sp)
    80003710:	1000                	add	s0,sp,32
    80003712:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003714:	0001c517          	auipc	a0,0x1c
    80003718:	f9450513          	add	a0,a0,-108 # 8001f6a8 <itable>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	52c080e7          	jalr	1324(ra) # 80000c48 <acquire>
  ip->ref++;
    80003724:	449c                	lw	a5,8(s1)
    80003726:	2785                	addw	a5,a5,1
    80003728:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000372a:	0001c517          	auipc	a0,0x1c
    8000372e:	f7e50513          	add	a0,a0,-130 # 8001f6a8 <itable>
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	5ca080e7          	jalr	1482(ra) # 80000cfc <release>
}
    8000373a:	8526                	mv	a0,s1
    8000373c:	60e2                	ld	ra,24(sp)
    8000373e:	6442                	ld	s0,16(sp)
    80003740:	64a2                	ld	s1,8(sp)
    80003742:	6105                	add	sp,sp,32
    80003744:	8082                	ret

0000000080003746 <ilock>:
{
    80003746:	1101                	add	sp,sp,-32
    80003748:	ec06                	sd	ra,24(sp)
    8000374a:	e822                	sd	s0,16(sp)
    8000374c:	e426                	sd	s1,8(sp)
    8000374e:	e04a                	sd	s2,0(sp)
    80003750:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003752:	c115                	beqz	a0,80003776 <ilock+0x30>
    80003754:	84aa                	mv	s1,a0
    80003756:	451c                	lw	a5,8(a0)
    80003758:	00f05f63          	blez	a5,80003776 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000375c:	0541                	add	a0,a0,16
    8000375e:	00001097          	auipc	ra,0x1
    80003762:	c7e080e7          	jalr	-898(ra) # 800043dc <acquiresleep>
  if(ip->valid == 0){
    80003766:	40bc                	lw	a5,64(s1)
    80003768:	cf99                	beqz	a5,80003786 <ilock+0x40>
}
    8000376a:	60e2                	ld	ra,24(sp)
    8000376c:	6442                	ld	s0,16(sp)
    8000376e:	64a2                	ld	s1,8(sp)
    80003770:	6902                	ld	s2,0(sp)
    80003772:	6105                	add	sp,sp,32
    80003774:	8082                	ret
    panic("ilock");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	ea250513          	add	a0,a0,-350 # 80008618 <syscalls+0x180>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dc2080e7          	jalr	-574(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003786:	40dc                	lw	a5,4(s1)
    80003788:	0047d79b          	srlw	a5,a5,0x4
    8000378c:	0001c597          	auipc	a1,0x1c
    80003790:	f145a583          	lw	a1,-236(a1) # 8001f6a0 <sb+0x18>
    80003794:	9dbd                	addw	a1,a1,a5
    80003796:	4088                	lw	a0,0(s1)
    80003798:	fffff097          	auipc	ra,0xfffff
    8000379c:	79e080e7          	jalr	1950(ra) # 80002f36 <bread>
    800037a0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a2:	05850593          	add	a1,a0,88
    800037a6:	40dc                	lw	a5,4(s1)
    800037a8:	8bbd                	and	a5,a5,15
    800037aa:	079a                	sll	a5,a5,0x6
    800037ac:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037ae:	00059783          	lh	a5,0(a1)
    800037b2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037b6:	00259783          	lh	a5,2(a1)
    800037ba:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037be:	00459783          	lh	a5,4(a1)
    800037c2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037c6:	00659783          	lh	a5,6(a1)
    800037ca:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037ce:	459c                	lw	a5,8(a1)
    800037d0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037d2:	03400613          	li	a2,52
    800037d6:	05b1                	add	a1,a1,12
    800037d8:	05048513          	add	a0,s1,80
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	5c4080e7          	jalr	1476(ra) # 80000da0 <memmove>
    brelse(bp);
    800037e4:	854a                	mv	a0,s2
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	880080e7          	jalr	-1920(ra) # 80003066 <brelse>
    ip->valid = 1;
    800037ee:	4785                	li	a5,1
    800037f0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037f2:	04449783          	lh	a5,68(s1)
    800037f6:	fbb5                	bnez	a5,8000376a <ilock+0x24>
      panic("ilock: no type");
    800037f8:	00005517          	auipc	a0,0x5
    800037fc:	e2850513          	add	a0,a0,-472 # 80008620 <syscalls+0x188>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	d40080e7          	jalr	-704(ra) # 80000540 <panic>

0000000080003808 <iunlock>:
{
    80003808:	1101                	add	sp,sp,-32
    8000380a:	ec06                	sd	ra,24(sp)
    8000380c:	e822                	sd	s0,16(sp)
    8000380e:	e426                	sd	s1,8(sp)
    80003810:	e04a                	sd	s2,0(sp)
    80003812:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003814:	c905                	beqz	a0,80003844 <iunlock+0x3c>
    80003816:	84aa                	mv	s1,a0
    80003818:	01050913          	add	s2,a0,16
    8000381c:	854a                	mv	a0,s2
    8000381e:	00001097          	auipc	ra,0x1
    80003822:	c58080e7          	jalr	-936(ra) # 80004476 <holdingsleep>
    80003826:	cd19                	beqz	a0,80003844 <iunlock+0x3c>
    80003828:	449c                	lw	a5,8(s1)
    8000382a:	00f05d63          	blez	a5,80003844 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000382e:	854a                	mv	a0,s2
    80003830:	00001097          	auipc	ra,0x1
    80003834:	c02080e7          	jalr	-1022(ra) # 80004432 <releasesleep>
}
    80003838:	60e2                	ld	ra,24(sp)
    8000383a:	6442                	ld	s0,16(sp)
    8000383c:	64a2                	ld	s1,8(sp)
    8000383e:	6902                	ld	s2,0(sp)
    80003840:	6105                	add	sp,sp,32
    80003842:	8082                	ret
    panic("iunlock");
    80003844:	00005517          	auipc	a0,0x5
    80003848:	dec50513          	add	a0,a0,-532 # 80008630 <syscalls+0x198>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	cf4080e7          	jalr	-780(ra) # 80000540 <panic>

0000000080003854 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003854:	7179                	add	sp,sp,-48
    80003856:	f406                	sd	ra,40(sp)
    80003858:	f022                	sd	s0,32(sp)
    8000385a:	ec26                	sd	s1,24(sp)
    8000385c:	e84a                	sd	s2,16(sp)
    8000385e:	e44e                	sd	s3,8(sp)
    80003860:	e052                	sd	s4,0(sp)
    80003862:	1800                	add	s0,sp,48
    80003864:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003866:	05050493          	add	s1,a0,80
    8000386a:	08050913          	add	s2,a0,128
    8000386e:	a021                	j	80003876 <itrunc+0x22>
    80003870:	0491                	add	s1,s1,4
    80003872:	01248d63          	beq	s1,s2,8000388c <itrunc+0x38>
    if(ip->addrs[i]){
    80003876:	408c                	lw	a1,0(s1)
    80003878:	dde5                	beqz	a1,80003870 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000387a:	0009a503          	lw	a0,0(s3)
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	8fc080e7          	jalr	-1796(ra) # 8000317a <bfree>
      ip->addrs[i] = 0;
    80003886:	0004a023          	sw	zero,0(s1)
    8000388a:	b7dd                	j	80003870 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000388c:	0809a583          	lw	a1,128(s3)
    80003890:	e185                	bnez	a1,800038b0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003892:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003896:	854e                	mv	a0,s3
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	de2080e7          	jalr	-542(ra) # 8000367a <iupdate>
}
    800038a0:	70a2                	ld	ra,40(sp)
    800038a2:	7402                	ld	s0,32(sp)
    800038a4:	64e2                	ld	s1,24(sp)
    800038a6:	6942                	ld	s2,16(sp)
    800038a8:	69a2                	ld	s3,8(sp)
    800038aa:	6a02                	ld	s4,0(sp)
    800038ac:	6145                	add	sp,sp,48
    800038ae:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038b0:	0009a503          	lw	a0,0(s3)
    800038b4:	fffff097          	auipc	ra,0xfffff
    800038b8:	682080e7          	jalr	1666(ra) # 80002f36 <bread>
    800038bc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038be:	05850493          	add	s1,a0,88
    800038c2:	45850913          	add	s2,a0,1112
    800038c6:	a021                	j	800038ce <itrunc+0x7a>
    800038c8:	0491                	add	s1,s1,4
    800038ca:	01248b63          	beq	s1,s2,800038e0 <itrunc+0x8c>
      if(a[j])
    800038ce:	408c                	lw	a1,0(s1)
    800038d0:	dde5                	beqz	a1,800038c8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038d2:	0009a503          	lw	a0,0(s3)
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	8a4080e7          	jalr	-1884(ra) # 8000317a <bfree>
    800038de:	b7ed                	j	800038c8 <itrunc+0x74>
    brelse(bp);
    800038e0:	8552                	mv	a0,s4
    800038e2:	fffff097          	auipc	ra,0xfffff
    800038e6:	784080e7          	jalr	1924(ra) # 80003066 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038ea:	0809a583          	lw	a1,128(s3)
    800038ee:	0009a503          	lw	a0,0(s3)
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	888080e7          	jalr	-1912(ra) # 8000317a <bfree>
    ip->addrs[NDIRECT] = 0;
    800038fa:	0809a023          	sw	zero,128(s3)
    800038fe:	bf51                	j	80003892 <itrunc+0x3e>

0000000080003900 <iput>:
{
    80003900:	1101                	add	sp,sp,-32
    80003902:	ec06                	sd	ra,24(sp)
    80003904:	e822                	sd	s0,16(sp)
    80003906:	e426                	sd	s1,8(sp)
    80003908:	e04a                	sd	s2,0(sp)
    8000390a:	1000                	add	s0,sp,32
    8000390c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000390e:	0001c517          	auipc	a0,0x1c
    80003912:	d9a50513          	add	a0,a0,-614 # 8001f6a8 <itable>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	332080e7          	jalr	818(ra) # 80000c48 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000391e:	4498                	lw	a4,8(s1)
    80003920:	4785                	li	a5,1
    80003922:	02f70363          	beq	a4,a5,80003948 <iput+0x48>
  ip->ref--;
    80003926:	449c                	lw	a5,8(s1)
    80003928:	37fd                	addw	a5,a5,-1
    8000392a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000392c:	0001c517          	auipc	a0,0x1c
    80003930:	d7c50513          	add	a0,a0,-644 # 8001f6a8 <itable>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	3c8080e7          	jalr	968(ra) # 80000cfc <release>
}
    8000393c:	60e2                	ld	ra,24(sp)
    8000393e:	6442                	ld	s0,16(sp)
    80003940:	64a2                	ld	s1,8(sp)
    80003942:	6902                	ld	s2,0(sp)
    80003944:	6105                	add	sp,sp,32
    80003946:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003948:	40bc                	lw	a5,64(s1)
    8000394a:	dff1                	beqz	a5,80003926 <iput+0x26>
    8000394c:	04a49783          	lh	a5,74(s1)
    80003950:	fbf9                	bnez	a5,80003926 <iput+0x26>
    acquiresleep(&ip->lock);
    80003952:	01048913          	add	s2,s1,16
    80003956:	854a                	mv	a0,s2
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	a84080e7          	jalr	-1404(ra) # 800043dc <acquiresleep>
    release(&itable.lock);
    80003960:	0001c517          	auipc	a0,0x1c
    80003964:	d4850513          	add	a0,a0,-696 # 8001f6a8 <itable>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	394080e7          	jalr	916(ra) # 80000cfc <release>
    itrunc(ip);
    80003970:	8526                	mv	a0,s1
    80003972:	00000097          	auipc	ra,0x0
    80003976:	ee2080e7          	jalr	-286(ra) # 80003854 <itrunc>
    ip->type = 0;
    8000397a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000397e:	8526                	mv	a0,s1
    80003980:	00000097          	auipc	ra,0x0
    80003984:	cfa080e7          	jalr	-774(ra) # 8000367a <iupdate>
    ip->valid = 0;
    80003988:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000398c:	854a                	mv	a0,s2
    8000398e:	00001097          	auipc	ra,0x1
    80003992:	aa4080e7          	jalr	-1372(ra) # 80004432 <releasesleep>
    acquire(&itable.lock);
    80003996:	0001c517          	auipc	a0,0x1c
    8000399a:	d1250513          	add	a0,a0,-750 # 8001f6a8 <itable>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	2aa080e7          	jalr	682(ra) # 80000c48 <acquire>
    800039a6:	b741                	j	80003926 <iput+0x26>

00000000800039a8 <iunlockput>:
{
    800039a8:	1101                	add	sp,sp,-32
    800039aa:	ec06                	sd	ra,24(sp)
    800039ac:	e822                	sd	s0,16(sp)
    800039ae:	e426                	sd	s1,8(sp)
    800039b0:	1000                	add	s0,sp,32
    800039b2:	84aa                	mv	s1,a0
  iunlock(ip);
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	e54080e7          	jalr	-428(ra) # 80003808 <iunlock>
  iput(ip);
    800039bc:	8526                	mv	a0,s1
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	f42080e7          	jalr	-190(ra) # 80003900 <iput>
}
    800039c6:	60e2                	ld	ra,24(sp)
    800039c8:	6442                	ld	s0,16(sp)
    800039ca:	64a2                	ld	s1,8(sp)
    800039cc:	6105                	add	sp,sp,32
    800039ce:	8082                	ret

00000000800039d0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039d0:	1141                	add	sp,sp,-16
    800039d2:	e422                	sd	s0,8(sp)
    800039d4:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    800039d6:	411c                	lw	a5,0(a0)
    800039d8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039da:	415c                	lw	a5,4(a0)
    800039dc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039de:	04451783          	lh	a5,68(a0)
    800039e2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039e6:	04a51783          	lh	a5,74(a0)
    800039ea:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039ee:	04c56783          	lwu	a5,76(a0)
    800039f2:	e99c                	sd	a5,16(a1)
}
    800039f4:	6422                	ld	s0,8(sp)
    800039f6:	0141                	add	sp,sp,16
    800039f8:	8082                	ret

00000000800039fa <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039fa:	457c                	lw	a5,76(a0)
    800039fc:	0ed7e963          	bltu	a5,a3,80003aee <readi+0xf4>
{
    80003a00:	7159                	add	sp,sp,-112
    80003a02:	f486                	sd	ra,104(sp)
    80003a04:	f0a2                	sd	s0,96(sp)
    80003a06:	eca6                	sd	s1,88(sp)
    80003a08:	e8ca                	sd	s2,80(sp)
    80003a0a:	e4ce                	sd	s3,72(sp)
    80003a0c:	e0d2                	sd	s4,64(sp)
    80003a0e:	fc56                	sd	s5,56(sp)
    80003a10:	f85a                	sd	s6,48(sp)
    80003a12:	f45e                	sd	s7,40(sp)
    80003a14:	f062                	sd	s8,32(sp)
    80003a16:	ec66                	sd	s9,24(sp)
    80003a18:	e86a                	sd	s10,16(sp)
    80003a1a:	e46e                	sd	s11,8(sp)
    80003a1c:	1880                	add	s0,sp,112
    80003a1e:	8b2a                	mv	s6,a0
    80003a20:	8bae                	mv	s7,a1
    80003a22:	8a32                	mv	s4,a2
    80003a24:	84b6                	mv	s1,a3
    80003a26:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a28:	9f35                	addw	a4,a4,a3
    return 0;
    80003a2a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a2c:	0ad76063          	bltu	a4,a3,80003acc <readi+0xd2>
  if(off + n > ip->size)
    80003a30:	00e7f463          	bgeu	a5,a4,80003a38 <readi+0x3e>
    n = ip->size - off;
    80003a34:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a38:	0a0a8963          	beqz	s5,80003aea <readi+0xf0>
    80003a3c:	4981                	li	s3,0
#if 0
    // Adil: Remove later
    printf("ip->dev; %d\n", ip->dev);
#endif

    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a42:	5c7d                	li	s8,-1
    80003a44:	a82d                	j	80003a7e <readi+0x84>
    80003a46:	020d1d93          	sll	s11,s10,0x20
    80003a4a:	020ddd93          	srl	s11,s11,0x20
    80003a4e:	05890613          	add	a2,s2,88
    80003a52:	86ee                	mv	a3,s11
    80003a54:	963a                	add	a2,a2,a4
    80003a56:	85d2                	mv	a1,s4
    80003a58:	855e                	mv	a0,s7
    80003a5a:	fffff097          	auipc	ra,0xfffff
    80003a5e:	aa8080e7          	jalr	-1368(ra) # 80002502 <either_copyout>
    80003a62:	05850d63          	beq	a0,s8,80003abc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a66:	854a                	mv	a0,s2
    80003a68:	fffff097          	auipc	ra,0xfffff
    80003a6c:	5fe080e7          	jalr	1534(ra) # 80003066 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a70:	013d09bb          	addw	s3,s10,s3
    80003a74:	009d04bb          	addw	s1,s10,s1
    80003a78:	9a6e                	add	s4,s4,s11
    80003a7a:	0559f763          	bgeu	s3,s5,80003ac8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a7e:	00a4d59b          	srlw	a1,s1,0xa
    80003a82:	855a                	mv	a0,s6
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	8a4080e7          	jalr	-1884(ra) # 80003328 <bmap>
    80003a8c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a90:	cd85                	beqz	a1,80003ac8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a92:	000b2503          	lw	a0,0(s6)
    80003a96:	fffff097          	auipc	ra,0xfffff
    80003a9a:	4a0080e7          	jalr	1184(ra) # 80002f36 <bread>
    80003a9e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa0:	3ff4f713          	and	a4,s1,1023
    80003aa4:	40ec87bb          	subw	a5,s9,a4
    80003aa8:	413a86bb          	subw	a3,s5,s3
    80003aac:	8d3e                	mv	s10,a5
    80003aae:	2781                	sext.w	a5,a5
    80003ab0:	0006861b          	sext.w	a2,a3
    80003ab4:	f8f679e3          	bgeu	a2,a5,80003a46 <readi+0x4c>
    80003ab8:	8d36                	mv	s10,a3
    80003aba:	b771                	j	80003a46 <readi+0x4c>
      brelse(bp);
    80003abc:	854a                	mv	a0,s2
    80003abe:	fffff097          	auipc	ra,0xfffff
    80003ac2:	5a8080e7          	jalr	1448(ra) # 80003066 <brelse>
      tot = -1;
    80003ac6:	59fd                	li	s3,-1
  }
  return tot;
    80003ac8:	0009851b          	sext.w	a0,s3
}
    80003acc:	70a6                	ld	ra,104(sp)
    80003ace:	7406                	ld	s0,96(sp)
    80003ad0:	64e6                	ld	s1,88(sp)
    80003ad2:	6946                	ld	s2,80(sp)
    80003ad4:	69a6                	ld	s3,72(sp)
    80003ad6:	6a06                	ld	s4,64(sp)
    80003ad8:	7ae2                	ld	s5,56(sp)
    80003ada:	7b42                	ld	s6,48(sp)
    80003adc:	7ba2                	ld	s7,40(sp)
    80003ade:	7c02                	ld	s8,32(sp)
    80003ae0:	6ce2                	ld	s9,24(sp)
    80003ae2:	6d42                	ld	s10,16(sp)
    80003ae4:	6da2                	ld	s11,8(sp)
    80003ae6:	6165                	add	sp,sp,112
    80003ae8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aea:	89d6                	mv	s3,s5
    80003aec:	bff1                	j	80003ac8 <readi+0xce>
    return 0;
    80003aee:	4501                	li	a0,0
}
    80003af0:	8082                	ret

0000000080003af2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af2:	457c                	lw	a5,76(a0)
    80003af4:	10d7e863          	bltu	a5,a3,80003c04 <writei+0x112>
{
    80003af8:	7159                	add	sp,sp,-112
    80003afa:	f486                	sd	ra,104(sp)
    80003afc:	f0a2                	sd	s0,96(sp)
    80003afe:	eca6                	sd	s1,88(sp)
    80003b00:	e8ca                	sd	s2,80(sp)
    80003b02:	e4ce                	sd	s3,72(sp)
    80003b04:	e0d2                	sd	s4,64(sp)
    80003b06:	fc56                	sd	s5,56(sp)
    80003b08:	f85a                	sd	s6,48(sp)
    80003b0a:	f45e                	sd	s7,40(sp)
    80003b0c:	f062                	sd	s8,32(sp)
    80003b0e:	ec66                	sd	s9,24(sp)
    80003b10:	e86a                	sd	s10,16(sp)
    80003b12:	e46e                	sd	s11,8(sp)
    80003b14:	1880                	add	s0,sp,112
    80003b16:	8aaa                	mv	s5,a0
    80003b18:	8bae                	mv	s7,a1
    80003b1a:	8a32                	mv	s4,a2
    80003b1c:	8936                	mv	s2,a3
    80003b1e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b20:	00e687bb          	addw	a5,a3,a4
    80003b24:	0ed7e263          	bltu	a5,a3,80003c08 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b28:	00043737          	lui	a4,0x43
    80003b2c:	0ef76063          	bltu	a4,a5,80003c0c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b30:	0c0b0863          	beqz	s6,80003c00 <writei+0x10e>
    80003b34:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b36:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b3a:	5c7d                	li	s8,-1
    80003b3c:	a091                	j	80003b80 <writei+0x8e>
    80003b3e:	020d1d93          	sll	s11,s10,0x20
    80003b42:	020ddd93          	srl	s11,s11,0x20
    80003b46:	05848513          	add	a0,s1,88
    80003b4a:	86ee                	mv	a3,s11
    80003b4c:	8652                	mv	a2,s4
    80003b4e:	85de                	mv	a1,s7
    80003b50:	953a                	add	a0,a0,a4
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	a06080e7          	jalr	-1530(ra) # 80002558 <either_copyin>
    80003b5a:	07850263          	beq	a0,s8,80003bbe <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b5e:	8526                	mv	a0,s1
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	75e080e7          	jalr	1886(ra) # 800042be <log_write>
    brelse(bp);
    80003b68:	8526                	mv	a0,s1
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	4fc080e7          	jalr	1276(ra) # 80003066 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b72:	013d09bb          	addw	s3,s10,s3
    80003b76:	012d093b          	addw	s2,s10,s2
    80003b7a:	9a6e                	add	s4,s4,s11
    80003b7c:	0569f663          	bgeu	s3,s6,80003bc8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b80:	00a9559b          	srlw	a1,s2,0xa
    80003b84:	8556                	mv	a0,s5
    80003b86:	fffff097          	auipc	ra,0xfffff
    80003b8a:	7a2080e7          	jalr	1954(ra) # 80003328 <bmap>
    80003b8e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b92:	c99d                	beqz	a1,80003bc8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b94:	000aa503          	lw	a0,0(s5)
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	39e080e7          	jalr	926(ra) # 80002f36 <bread>
    80003ba0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba2:	3ff97713          	and	a4,s2,1023
    80003ba6:	40ec87bb          	subw	a5,s9,a4
    80003baa:	413b06bb          	subw	a3,s6,s3
    80003bae:	8d3e                	mv	s10,a5
    80003bb0:	2781                	sext.w	a5,a5
    80003bb2:	0006861b          	sext.w	a2,a3
    80003bb6:	f8f674e3          	bgeu	a2,a5,80003b3e <writei+0x4c>
    80003bba:	8d36                	mv	s10,a3
    80003bbc:	b749                	j	80003b3e <writei+0x4c>
      brelse(bp);
    80003bbe:	8526                	mv	a0,s1
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	4a6080e7          	jalr	1190(ra) # 80003066 <brelse>
  }

  if(off > ip->size)
    80003bc8:	04caa783          	lw	a5,76(s5)
    80003bcc:	0127f463          	bgeu	a5,s2,80003bd4 <writei+0xe2>
    ip->size = off;
    80003bd0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bd4:	8556                	mv	a0,s5
    80003bd6:	00000097          	auipc	ra,0x0
    80003bda:	aa4080e7          	jalr	-1372(ra) # 8000367a <iupdate>

  return tot;
    80003bde:	0009851b          	sext.w	a0,s3
}
    80003be2:	70a6                	ld	ra,104(sp)
    80003be4:	7406                	ld	s0,96(sp)
    80003be6:	64e6                	ld	s1,88(sp)
    80003be8:	6946                	ld	s2,80(sp)
    80003bea:	69a6                	ld	s3,72(sp)
    80003bec:	6a06                	ld	s4,64(sp)
    80003bee:	7ae2                	ld	s5,56(sp)
    80003bf0:	7b42                	ld	s6,48(sp)
    80003bf2:	7ba2                	ld	s7,40(sp)
    80003bf4:	7c02                	ld	s8,32(sp)
    80003bf6:	6ce2                	ld	s9,24(sp)
    80003bf8:	6d42                	ld	s10,16(sp)
    80003bfa:	6da2                	ld	s11,8(sp)
    80003bfc:	6165                	add	sp,sp,112
    80003bfe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c00:	89da                	mv	s3,s6
    80003c02:	bfc9                	j	80003bd4 <writei+0xe2>
    return -1;
    80003c04:	557d                	li	a0,-1
}
    80003c06:	8082                	ret
    return -1;
    80003c08:	557d                	li	a0,-1
    80003c0a:	bfe1                	j	80003be2 <writei+0xf0>
    return -1;
    80003c0c:	557d                	li	a0,-1
    80003c0e:	bfd1                	j	80003be2 <writei+0xf0>

0000000080003c10 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c10:	1141                	add	sp,sp,-16
    80003c12:	e406                	sd	ra,8(sp)
    80003c14:	e022                	sd	s0,0(sp)
    80003c16:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c18:	4639                	li	a2,14
    80003c1a:	ffffd097          	auipc	ra,0xffffd
    80003c1e:	1fa080e7          	jalr	506(ra) # 80000e14 <strncmp>
}
    80003c22:	60a2                	ld	ra,8(sp)
    80003c24:	6402                	ld	s0,0(sp)
    80003c26:	0141                	add	sp,sp,16
    80003c28:	8082                	ret

0000000080003c2a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c2a:	7139                	add	sp,sp,-64
    80003c2c:	fc06                	sd	ra,56(sp)
    80003c2e:	f822                	sd	s0,48(sp)
    80003c30:	f426                	sd	s1,40(sp)
    80003c32:	f04a                	sd	s2,32(sp)
    80003c34:	ec4e                	sd	s3,24(sp)
    80003c36:	e852                	sd	s4,16(sp)
    80003c38:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c3a:	04451703          	lh	a4,68(a0)
    80003c3e:	4785                	li	a5,1
    80003c40:	00f71a63          	bne	a4,a5,80003c54 <dirlookup+0x2a>
    80003c44:	892a                	mv	s2,a0
    80003c46:	89ae                	mv	s3,a1
    80003c48:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c4a:	457c                	lw	a5,76(a0)
    80003c4c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c4e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c50:	e79d                	bnez	a5,80003c7e <dirlookup+0x54>
    80003c52:	a8a5                	j	80003cca <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c54:	00005517          	auipc	a0,0x5
    80003c58:	9e450513          	add	a0,a0,-1564 # 80008638 <syscalls+0x1a0>
    80003c5c:	ffffd097          	auipc	ra,0xffffd
    80003c60:	8e4080e7          	jalr	-1820(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c64:	00005517          	auipc	a0,0x5
    80003c68:	9ec50513          	add	a0,a0,-1556 # 80008650 <syscalls+0x1b8>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	8d4080e7          	jalr	-1836(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c74:	24c1                	addw	s1,s1,16
    80003c76:	04c92783          	lw	a5,76(s2)
    80003c7a:	04f4f763          	bgeu	s1,a5,80003cc8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c7e:	4741                	li	a4,16
    80003c80:	86a6                	mv	a3,s1
    80003c82:	fc040613          	add	a2,s0,-64
    80003c86:	4581                	li	a1,0
    80003c88:	854a                	mv	a0,s2
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	d70080e7          	jalr	-656(ra) # 800039fa <readi>
    80003c92:	47c1                	li	a5,16
    80003c94:	fcf518e3          	bne	a0,a5,80003c64 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c98:	fc045783          	lhu	a5,-64(s0)
    80003c9c:	dfe1                	beqz	a5,80003c74 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c9e:	fc240593          	add	a1,s0,-62
    80003ca2:	854e                	mv	a0,s3
    80003ca4:	00000097          	auipc	ra,0x0
    80003ca8:	f6c080e7          	jalr	-148(ra) # 80003c10 <namecmp>
    80003cac:	f561                	bnez	a0,80003c74 <dirlookup+0x4a>
      if(poff)
    80003cae:	000a0463          	beqz	s4,80003cb6 <dirlookup+0x8c>
        *poff = off;
    80003cb2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cb6:	fc045583          	lhu	a1,-64(s0)
    80003cba:	00092503          	lw	a0,0(s2)
    80003cbe:	fffff097          	auipc	ra,0xfffff
    80003cc2:	754080e7          	jalr	1876(ra) # 80003412 <iget>
    80003cc6:	a011                	j	80003cca <dirlookup+0xa0>
  return 0;
    80003cc8:	4501                	li	a0,0
}
    80003cca:	70e2                	ld	ra,56(sp)
    80003ccc:	7442                	ld	s0,48(sp)
    80003cce:	74a2                	ld	s1,40(sp)
    80003cd0:	7902                	ld	s2,32(sp)
    80003cd2:	69e2                	ld	s3,24(sp)
    80003cd4:	6a42                	ld	s4,16(sp)
    80003cd6:	6121                	add	sp,sp,64
    80003cd8:	8082                	ret

0000000080003cda <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cda:	711d                	add	sp,sp,-96
    80003cdc:	ec86                	sd	ra,88(sp)
    80003cde:	e8a2                	sd	s0,80(sp)
    80003ce0:	e4a6                	sd	s1,72(sp)
    80003ce2:	e0ca                	sd	s2,64(sp)
    80003ce4:	fc4e                	sd	s3,56(sp)
    80003ce6:	f852                	sd	s4,48(sp)
    80003ce8:	f456                	sd	s5,40(sp)
    80003cea:	f05a                	sd	s6,32(sp)
    80003cec:	ec5e                	sd	s7,24(sp)
    80003cee:	e862                	sd	s8,16(sp)
    80003cf0:	e466                	sd	s9,8(sp)
    80003cf2:	1080                	add	s0,sp,96
    80003cf4:	84aa                	mv	s1,a0
    80003cf6:	8b2e                	mv	s6,a1
    80003cf8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cfa:	00054703          	lbu	a4,0(a0)
    80003cfe:	02f00793          	li	a5,47
    80003d02:	02f70263          	beq	a4,a5,80003d26 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d06:	ffffe097          	auipc	ra,0xffffe
    80003d0a:	d1e080e7          	jalr	-738(ra) # 80001a24 <myproc>
    80003d0e:	15053503          	ld	a0,336(a0)
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	9f6080e7          	jalr	-1546(ra) # 80003708 <idup>
    80003d1a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d1c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d20:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d22:	4b85                	li	s7,1
    80003d24:	a875                	j	80003de0 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d26:	4585                	li	a1,1
    80003d28:	4505                	li	a0,1
    80003d2a:	fffff097          	auipc	ra,0xfffff
    80003d2e:	6e8080e7          	jalr	1768(ra) # 80003412 <iget>
    80003d32:	8a2a                	mv	s4,a0
    80003d34:	b7e5                	j	80003d1c <namex+0x42>
      iunlockput(ip);
    80003d36:	8552                	mv	a0,s4
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	c70080e7          	jalr	-912(ra) # 800039a8 <iunlockput>
      return 0;
    80003d40:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d42:	8552                	mv	a0,s4
    80003d44:	60e6                	ld	ra,88(sp)
    80003d46:	6446                	ld	s0,80(sp)
    80003d48:	64a6                	ld	s1,72(sp)
    80003d4a:	6906                	ld	s2,64(sp)
    80003d4c:	79e2                	ld	s3,56(sp)
    80003d4e:	7a42                	ld	s4,48(sp)
    80003d50:	7aa2                	ld	s5,40(sp)
    80003d52:	7b02                	ld	s6,32(sp)
    80003d54:	6be2                	ld	s7,24(sp)
    80003d56:	6c42                	ld	s8,16(sp)
    80003d58:	6ca2                	ld	s9,8(sp)
    80003d5a:	6125                	add	sp,sp,96
    80003d5c:	8082                	ret
      iunlock(ip);
    80003d5e:	8552                	mv	a0,s4
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	aa8080e7          	jalr	-1368(ra) # 80003808 <iunlock>
      return ip;
    80003d68:	bfe9                	j	80003d42 <namex+0x68>
      iunlockput(ip);
    80003d6a:	8552                	mv	a0,s4
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	c3c080e7          	jalr	-964(ra) # 800039a8 <iunlockput>
      return 0;
    80003d74:	8a4e                	mv	s4,s3
    80003d76:	b7f1                	j	80003d42 <namex+0x68>
  len = path - s;
    80003d78:	40998633          	sub	a2,s3,s1
    80003d7c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d80:	099c5863          	bge	s8,s9,80003e10 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003d84:	4639                	li	a2,14
    80003d86:	85a6                	mv	a1,s1
    80003d88:	8556                	mv	a0,s5
    80003d8a:	ffffd097          	auipc	ra,0xffffd
    80003d8e:	016080e7          	jalr	22(ra) # 80000da0 <memmove>
    80003d92:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d94:	0004c783          	lbu	a5,0(s1)
    80003d98:	01279763          	bne	a5,s2,80003da6 <namex+0xcc>
    path++;
    80003d9c:	0485                	add	s1,s1,1
  while(*path == '/')
    80003d9e:	0004c783          	lbu	a5,0(s1)
    80003da2:	ff278de3          	beq	a5,s2,80003d9c <namex+0xc2>
    ilock(ip);
    80003da6:	8552                	mv	a0,s4
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	99e080e7          	jalr	-1634(ra) # 80003746 <ilock>
    if(ip->type != T_DIR){
    80003db0:	044a1783          	lh	a5,68(s4)
    80003db4:	f97791e3          	bne	a5,s7,80003d36 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003db8:	000b0563          	beqz	s6,80003dc2 <namex+0xe8>
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	dfd9                	beqz	a5,80003d5e <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dc2:	4601                	li	a2,0
    80003dc4:	85d6                	mv	a1,s5
    80003dc6:	8552                	mv	a0,s4
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	e62080e7          	jalr	-414(ra) # 80003c2a <dirlookup>
    80003dd0:	89aa                	mv	s3,a0
    80003dd2:	dd41                	beqz	a0,80003d6a <namex+0x90>
    iunlockput(ip);
    80003dd4:	8552                	mv	a0,s4
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	bd2080e7          	jalr	-1070(ra) # 800039a8 <iunlockput>
    ip = next;
    80003dde:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003de0:	0004c783          	lbu	a5,0(s1)
    80003de4:	01279763          	bne	a5,s2,80003df2 <namex+0x118>
    path++;
    80003de8:	0485                	add	s1,s1,1
  while(*path == '/')
    80003dea:	0004c783          	lbu	a5,0(s1)
    80003dee:	ff278de3          	beq	a5,s2,80003de8 <namex+0x10e>
  if(*path == 0)
    80003df2:	cb9d                	beqz	a5,80003e28 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003df4:	0004c783          	lbu	a5,0(s1)
    80003df8:	89a6                	mv	s3,s1
  len = path - s;
    80003dfa:	4c81                	li	s9,0
    80003dfc:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003dfe:	01278963          	beq	a5,s2,80003e10 <namex+0x136>
    80003e02:	dbbd                	beqz	a5,80003d78 <namex+0x9e>
    path++;
    80003e04:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e06:	0009c783          	lbu	a5,0(s3)
    80003e0a:	ff279ce3          	bne	a5,s2,80003e02 <namex+0x128>
    80003e0e:	b7ad                	j	80003d78 <namex+0x9e>
    memmove(name, s, len);
    80003e10:	2601                	sext.w	a2,a2
    80003e12:	85a6                	mv	a1,s1
    80003e14:	8556                	mv	a0,s5
    80003e16:	ffffd097          	auipc	ra,0xffffd
    80003e1a:	f8a080e7          	jalr	-118(ra) # 80000da0 <memmove>
    name[len] = 0;
    80003e1e:	9cd6                	add	s9,s9,s5
    80003e20:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e24:	84ce                	mv	s1,s3
    80003e26:	b7bd                	j	80003d94 <namex+0xba>
  if(nameiparent){
    80003e28:	f00b0de3          	beqz	s6,80003d42 <namex+0x68>
    iput(ip);
    80003e2c:	8552                	mv	a0,s4
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	ad2080e7          	jalr	-1326(ra) # 80003900 <iput>
    return 0;
    80003e36:	4a01                	li	s4,0
    80003e38:	b729                	j	80003d42 <namex+0x68>

0000000080003e3a <dirlink>:
{
    80003e3a:	7139                	add	sp,sp,-64
    80003e3c:	fc06                	sd	ra,56(sp)
    80003e3e:	f822                	sd	s0,48(sp)
    80003e40:	f426                	sd	s1,40(sp)
    80003e42:	f04a                	sd	s2,32(sp)
    80003e44:	ec4e                	sd	s3,24(sp)
    80003e46:	e852                	sd	s4,16(sp)
    80003e48:	0080                	add	s0,sp,64
    80003e4a:	892a                	mv	s2,a0
    80003e4c:	8a2e                	mv	s4,a1
    80003e4e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e50:	4601                	li	a2,0
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	dd8080e7          	jalr	-552(ra) # 80003c2a <dirlookup>
    80003e5a:	e93d                	bnez	a0,80003ed0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5c:	04c92483          	lw	s1,76(s2)
    80003e60:	c49d                	beqz	s1,80003e8e <dirlink+0x54>
    80003e62:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e64:	4741                	li	a4,16
    80003e66:	86a6                	mv	a3,s1
    80003e68:	fc040613          	add	a2,s0,-64
    80003e6c:	4581                	li	a1,0
    80003e6e:	854a                	mv	a0,s2
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	b8a080e7          	jalr	-1142(ra) # 800039fa <readi>
    80003e78:	47c1                	li	a5,16
    80003e7a:	06f51163          	bne	a0,a5,80003edc <dirlink+0xa2>
    if(de.inum == 0)
    80003e7e:	fc045783          	lhu	a5,-64(s0)
    80003e82:	c791                	beqz	a5,80003e8e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e84:	24c1                	addw	s1,s1,16
    80003e86:	04c92783          	lw	a5,76(s2)
    80003e8a:	fcf4ede3          	bltu	s1,a5,80003e64 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e8e:	4639                	li	a2,14
    80003e90:	85d2                	mv	a1,s4
    80003e92:	fc240513          	add	a0,s0,-62
    80003e96:	ffffd097          	auipc	ra,0xffffd
    80003e9a:	fba080e7          	jalr	-70(ra) # 80000e50 <strncpy>
  de.inum = inum;
    80003e9e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea2:	4741                	li	a4,16
    80003ea4:	86a6                	mv	a3,s1
    80003ea6:	fc040613          	add	a2,s0,-64
    80003eaa:	4581                	li	a1,0
    80003eac:	854a                	mv	a0,s2
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	c44080e7          	jalr	-956(ra) # 80003af2 <writei>
    80003eb6:	1541                	add	a0,a0,-16
    80003eb8:	00a03533          	snez	a0,a0
    80003ebc:	40a00533          	neg	a0,a0
}
    80003ec0:	70e2                	ld	ra,56(sp)
    80003ec2:	7442                	ld	s0,48(sp)
    80003ec4:	74a2                	ld	s1,40(sp)
    80003ec6:	7902                	ld	s2,32(sp)
    80003ec8:	69e2                	ld	s3,24(sp)
    80003eca:	6a42                	ld	s4,16(sp)
    80003ecc:	6121                	add	sp,sp,64
    80003ece:	8082                	ret
    iput(ip);
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	a30080e7          	jalr	-1488(ra) # 80003900 <iput>
    return -1;
    80003ed8:	557d                	li	a0,-1
    80003eda:	b7dd                	j	80003ec0 <dirlink+0x86>
      panic("dirlink read");
    80003edc:	00004517          	auipc	a0,0x4
    80003ee0:	78450513          	add	a0,a0,1924 # 80008660 <syscalls+0x1c8>
    80003ee4:	ffffc097          	auipc	ra,0xffffc
    80003ee8:	65c080e7          	jalr	1628(ra) # 80000540 <panic>

0000000080003eec <namei>:

struct inode*
namei(char *path)
{
    80003eec:	1101                	add	sp,sp,-32
    80003eee:	ec06                	sd	ra,24(sp)
    80003ef0:	e822                	sd	s0,16(sp)
    80003ef2:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ef4:	fe040613          	add	a2,s0,-32
    80003ef8:	4581                	li	a1,0
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	de0080e7          	jalr	-544(ra) # 80003cda <namex>
}
    80003f02:	60e2                	ld	ra,24(sp)
    80003f04:	6442                	ld	s0,16(sp)
    80003f06:	6105                	add	sp,sp,32
    80003f08:	8082                	ret

0000000080003f0a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f0a:	1141                	add	sp,sp,-16
    80003f0c:	e406                	sd	ra,8(sp)
    80003f0e:	e022                	sd	s0,0(sp)
    80003f10:	0800                	add	s0,sp,16
    80003f12:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f14:	4585                	li	a1,1
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	dc4080e7          	jalr	-572(ra) # 80003cda <namex>
}
    80003f1e:	60a2                	ld	ra,8(sp)
    80003f20:	6402                	ld	s0,0(sp)
    80003f22:	0141                	add	sp,sp,16
    80003f24:	8082                	ret

0000000080003f26 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f26:	1101                	add	sp,sp,-32
    80003f28:	ec06                	sd	ra,24(sp)
    80003f2a:	e822                	sd	s0,16(sp)
    80003f2c:	e426                	sd	s1,8(sp)
    80003f2e:	e04a                	sd	s2,0(sp)
    80003f30:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f32:	0001d917          	auipc	s2,0x1d
    80003f36:	21e90913          	add	s2,s2,542 # 80021150 <log>
    80003f3a:	01892583          	lw	a1,24(s2)
    80003f3e:	02892503          	lw	a0,40(s2)
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	ff4080e7          	jalr	-12(ra) # 80002f36 <bread>
    80003f4a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f4c:	02c92603          	lw	a2,44(s2)
    80003f50:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f52:	00c05f63          	blez	a2,80003f70 <write_head+0x4a>
    80003f56:	0001d717          	auipc	a4,0x1d
    80003f5a:	22a70713          	add	a4,a4,554 # 80021180 <log+0x30>
    80003f5e:	87aa                	mv	a5,a0
    80003f60:	060a                	sll	a2,a2,0x2
    80003f62:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f64:	4314                	lw	a3,0(a4)
    80003f66:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f68:	0711                	add	a4,a4,4
    80003f6a:	0791                	add	a5,a5,4
    80003f6c:	fec79ce3          	bne	a5,a2,80003f64 <write_head+0x3e>
  }
  bwrite(buf);
    80003f70:	8526                	mv	a0,s1
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	0b6080e7          	jalr	182(ra) # 80003028 <bwrite>
  brelse(buf);
    80003f7a:	8526                	mv	a0,s1
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	0ea080e7          	jalr	234(ra) # 80003066 <brelse>
}
    80003f84:	60e2                	ld	ra,24(sp)
    80003f86:	6442                	ld	s0,16(sp)
    80003f88:	64a2                	ld	s1,8(sp)
    80003f8a:	6902                	ld	s2,0(sp)
    80003f8c:	6105                	add	sp,sp,32
    80003f8e:	8082                	ret

0000000080003f90 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f90:	0001d797          	auipc	a5,0x1d
    80003f94:	1ec7a783          	lw	a5,492(a5) # 8002117c <log+0x2c>
    80003f98:	0af05d63          	blez	a5,80004052 <install_trans+0xc2>
{
    80003f9c:	7139                	add	sp,sp,-64
    80003f9e:	fc06                	sd	ra,56(sp)
    80003fa0:	f822                	sd	s0,48(sp)
    80003fa2:	f426                	sd	s1,40(sp)
    80003fa4:	f04a                	sd	s2,32(sp)
    80003fa6:	ec4e                	sd	s3,24(sp)
    80003fa8:	e852                	sd	s4,16(sp)
    80003faa:	e456                	sd	s5,8(sp)
    80003fac:	e05a                	sd	s6,0(sp)
    80003fae:	0080                	add	s0,sp,64
    80003fb0:	8b2a                	mv	s6,a0
    80003fb2:	0001da97          	auipc	s5,0x1d
    80003fb6:	1cea8a93          	add	s5,s5,462 # 80021180 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fba:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fbc:	0001d997          	auipc	s3,0x1d
    80003fc0:	19498993          	add	s3,s3,404 # 80021150 <log>
    80003fc4:	a00d                	j	80003fe6 <install_trans+0x56>
    brelse(lbuf);
    80003fc6:	854a                	mv	a0,s2
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	09e080e7          	jalr	158(ra) # 80003066 <brelse>
    brelse(dbuf);
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	094080e7          	jalr	148(ra) # 80003066 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fda:	2a05                	addw	s4,s4,1
    80003fdc:	0a91                	add	s5,s5,4
    80003fde:	02c9a783          	lw	a5,44(s3)
    80003fe2:	04fa5e63          	bge	s4,a5,8000403e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fe6:	0189a583          	lw	a1,24(s3)
    80003fea:	014585bb          	addw	a1,a1,s4
    80003fee:	2585                	addw	a1,a1,1
    80003ff0:	0289a503          	lw	a0,40(s3)
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	f42080e7          	jalr	-190(ra) # 80002f36 <bread>
    80003ffc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ffe:	000aa583          	lw	a1,0(s5)
    80004002:	0289a503          	lw	a0,40(s3)
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	f30080e7          	jalr	-208(ra) # 80002f36 <bread>
    8000400e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004010:	40000613          	li	a2,1024
    80004014:	05890593          	add	a1,s2,88
    80004018:	05850513          	add	a0,a0,88
    8000401c:	ffffd097          	auipc	ra,0xffffd
    80004020:	d84080e7          	jalr	-636(ra) # 80000da0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004024:	8526                	mv	a0,s1
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	002080e7          	jalr	2(ra) # 80003028 <bwrite>
    if(recovering == 0)
    8000402e:	f80b1ce3          	bnez	s6,80003fc6 <install_trans+0x36>
      bunpin(dbuf);
    80004032:	8526                	mv	a0,s1
    80004034:	fffff097          	auipc	ra,0xfffff
    80004038:	10a080e7          	jalr	266(ra) # 8000313e <bunpin>
    8000403c:	b769                	j	80003fc6 <install_trans+0x36>
}
    8000403e:	70e2                	ld	ra,56(sp)
    80004040:	7442                	ld	s0,48(sp)
    80004042:	74a2                	ld	s1,40(sp)
    80004044:	7902                	ld	s2,32(sp)
    80004046:	69e2                	ld	s3,24(sp)
    80004048:	6a42                	ld	s4,16(sp)
    8000404a:	6aa2                	ld	s5,8(sp)
    8000404c:	6b02                	ld	s6,0(sp)
    8000404e:	6121                	add	sp,sp,64
    80004050:	8082                	ret
    80004052:	8082                	ret

0000000080004054 <initlog>:
{
    80004054:	7179                	add	sp,sp,-48
    80004056:	f406                	sd	ra,40(sp)
    80004058:	f022                	sd	s0,32(sp)
    8000405a:	ec26                	sd	s1,24(sp)
    8000405c:	e84a                	sd	s2,16(sp)
    8000405e:	e44e                	sd	s3,8(sp)
    80004060:	1800                	add	s0,sp,48
    80004062:	892a                	mv	s2,a0
    80004064:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004066:	0001d497          	auipc	s1,0x1d
    8000406a:	0ea48493          	add	s1,s1,234 # 80021150 <log>
    8000406e:	00004597          	auipc	a1,0x4
    80004072:	60258593          	add	a1,a1,1538 # 80008670 <syscalls+0x1d8>
    80004076:	8526                	mv	a0,s1
    80004078:	ffffd097          	auipc	ra,0xffffd
    8000407c:	b40080e7          	jalr	-1216(ra) # 80000bb8 <initlock>
  log.start = sb->logstart;
    80004080:	0149a583          	lw	a1,20(s3)
    80004084:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004086:	0109a783          	lw	a5,16(s3)
    8000408a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000408c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004090:	854a                	mv	a0,s2
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	ea4080e7          	jalr	-348(ra) # 80002f36 <bread>
  log.lh.n = lh->n;
    8000409a:	4d30                	lw	a2,88(a0)
    8000409c:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000409e:	00c05f63          	blez	a2,800040bc <initlog+0x68>
    800040a2:	87aa                	mv	a5,a0
    800040a4:	0001d717          	auipc	a4,0x1d
    800040a8:	0dc70713          	add	a4,a4,220 # 80021180 <log+0x30>
    800040ac:	060a                	sll	a2,a2,0x2
    800040ae:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800040b0:	4ff4                	lw	a3,92(a5)
    800040b2:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040b4:	0791                	add	a5,a5,4
    800040b6:	0711                	add	a4,a4,4
    800040b8:	fec79ce3          	bne	a5,a2,800040b0 <initlog+0x5c>
  brelse(buf);
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	faa080e7          	jalr	-86(ra) # 80003066 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040c4:	4505                	li	a0,1
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	eca080e7          	jalr	-310(ra) # 80003f90 <install_trans>
  log.lh.n = 0;
    800040ce:	0001d797          	auipc	a5,0x1d
    800040d2:	0a07a723          	sw	zero,174(a5) # 8002117c <log+0x2c>
  write_head(); // clear the log
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	e50080e7          	jalr	-432(ra) # 80003f26 <write_head>
}
    800040de:	70a2                	ld	ra,40(sp)
    800040e0:	7402                	ld	s0,32(sp)
    800040e2:	64e2                	ld	s1,24(sp)
    800040e4:	6942                	ld	s2,16(sp)
    800040e6:	69a2                	ld	s3,8(sp)
    800040e8:	6145                	add	sp,sp,48
    800040ea:	8082                	ret

00000000800040ec <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040ec:	1101                	add	sp,sp,-32
    800040ee:	ec06                	sd	ra,24(sp)
    800040f0:	e822                	sd	s0,16(sp)
    800040f2:	e426                	sd	s1,8(sp)
    800040f4:	e04a                	sd	s2,0(sp)
    800040f6:	1000                	add	s0,sp,32
  acquire(&log.lock);
    800040f8:	0001d517          	auipc	a0,0x1d
    800040fc:	05850513          	add	a0,a0,88 # 80021150 <log>
    80004100:	ffffd097          	auipc	ra,0xffffd
    80004104:	b48080e7          	jalr	-1208(ra) # 80000c48 <acquire>
  while(1){
    if(log.committing){
    80004108:	0001d497          	auipc	s1,0x1d
    8000410c:	04848493          	add	s1,s1,72 # 80021150 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004110:	4979                	li	s2,30
    80004112:	a039                	j	80004120 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004114:	85a6                	mv	a1,s1
    80004116:	8526                	mv	a0,s1
    80004118:	ffffe097          	auipc	ra,0xffffe
    8000411c:	fe2080e7          	jalr	-30(ra) # 800020fa <sleep>
    if(log.committing){
    80004120:	50dc                	lw	a5,36(s1)
    80004122:	fbed                	bnez	a5,80004114 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004124:	5098                	lw	a4,32(s1)
    80004126:	2705                	addw	a4,a4,1
    80004128:	0027179b          	sllw	a5,a4,0x2
    8000412c:	9fb9                	addw	a5,a5,a4
    8000412e:	0017979b          	sllw	a5,a5,0x1
    80004132:	54d4                	lw	a3,44(s1)
    80004134:	9fb5                	addw	a5,a5,a3
    80004136:	00f95963          	bge	s2,a5,80004148 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000413a:	85a6                	mv	a1,s1
    8000413c:	8526                	mv	a0,s1
    8000413e:	ffffe097          	auipc	ra,0xffffe
    80004142:	fbc080e7          	jalr	-68(ra) # 800020fa <sleep>
    80004146:	bfe9                	j	80004120 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004148:	0001d517          	auipc	a0,0x1d
    8000414c:	00850513          	add	a0,a0,8 # 80021150 <log>
    80004150:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	baa080e7          	jalr	-1110(ra) # 80000cfc <release>
      break;
    }
  }
}
    8000415a:	60e2                	ld	ra,24(sp)
    8000415c:	6442                	ld	s0,16(sp)
    8000415e:	64a2                	ld	s1,8(sp)
    80004160:	6902                	ld	s2,0(sp)
    80004162:	6105                	add	sp,sp,32
    80004164:	8082                	ret

0000000080004166 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004166:	7139                	add	sp,sp,-64
    80004168:	fc06                	sd	ra,56(sp)
    8000416a:	f822                	sd	s0,48(sp)
    8000416c:	f426                	sd	s1,40(sp)
    8000416e:	f04a                	sd	s2,32(sp)
    80004170:	ec4e                	sd	s3,24(sp)
    80004172:	e852                	sd	s4,16(sp)
    80004174:	e456                	sd	s5,8(sp)
    80004176:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004178:	0001d497          	auipc	s1,0x1d
    8000417c:	fd848493          	add	s1,s1,-40 # 80021150 <log>
    80004180:	8526                	mv	a0,s1
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	ac6080e7          	jalr	-1338(ra) # 80000c48 <acquire>
  log.outstanding -= 1;
    8000418a:	509c                	lw	a5,32(s1)
    8000418c:	37fd                	addw	a5,a5,-1
    8000418e:	0007891b          	sext.w	s2,a5
    80004192:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004194:	50dc                	lw	a5,36(s1)
    80004196:	e7b9                	bnez	a5,800041e4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004198:	04091e63          	bnez	s2,800041f4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000419c:	0001d497          	auipc	s1,0x1d
    800041a0:	fb448493          	add	s1,s1,-76 # 80021150 <log>
    800041a4:	4785                	li	a5,1
    800041a6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	b52080e7          	jalr	-1198(ra) # 80000cfc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041b2:	54dc                	lw	a5,44(s1)
    800041b4:	06f04763          	bgtz	a5,80004222 <end_op+0xbc>
    acquire(&log.lock);
    800041b8:	0001d497          	auipc	s1,0x1d
    800041bc:	f9848493          	add	s1,s1,-104 # 80021150 <log>
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	a86080e7          	jalr	-1402(ra) # 80000c48 <acquire>
    log.committing = 0;
    800041ca:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffe097          	auipc	ra,0xffffe
    800041d4:	f8e080e7          	jalr	-114(ra) # 8000215e <wakeup>
    release(&log.lock);
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	b22080e7          	jalr	-1246(ra) # 80000cfc <release>
}
    800041e2:	a03d                	j	80004210 <end_op+0xaa>
    panic("log.committing");
    800041e4:	00004517          	auipc	a0,0x4
    800041e8:	49450513          	add	a0,a0,1172 # 80008678 <syscalls+0x1e0>
    800041ec:	ffffc097          	auipc	ra,0xffffc
    800041f0:	354080e7          	jalr	852(ra) # 80000540 <panic>
    wakeup(&log);
    800041f4:	0001d497          	auipc	s1,0x1d
    800041f8:	f5c48493          	add	s1,s1,-164 # 80021150 <log>
    800041fc:	8526                	mv	a0,s1
    800041fe:	ffffe097          	auipc	ra,0xffffe
    80004202:	f60080e7          	jalr	-160(ra) # 8000215e <wakeup>
  release(&log.lock);
    80004206:	8526                	mv	a0,s1
    80004208:	ffffd097          	auipc	ra,0xffffd
    8000420c:	af4080e7          	jalr	-1292(ra) # 80000cfc <release>
}
    80004210:	70e2                	ld	ra,56(sp)
    80004212:	7442                	ld	s0,48(sp)
    80004214:	74a2                	ld	s1,40(sp)
    80004216:	7902                	ld	s2,32(sp)
    80004218:	69e2                	ld	s3,24(sp)
    8000421a:	6a42                	ld	s4,16(sp)
    8000421c:	6aa2                	ld	s5,8(sp)
    8000421e:	6121                	add	sp,sp,64
    80004220:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004222:	0001da97          	auipc	s5,0x1d
    80004226:	f5ea8a93          	add	s5,s5,-162 # 80021180 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000422a:	0001da17          	auipc	s4,0x1d
    8000422e:	f26a0a13          	add	s4,s4,-218 # 80021150 <log>
    80004232:	018a2583          	lw	a1,24(s4)
    80004236:	012585bb          	addw	a1,a1,s2
    8000423a:	2585                	addw	a1,a1,1
    8000423c:	028a2503          	lw	a0,40(s4)
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	cf6080e7          	jalr	-778(ra) # 80002f36 <bread>
    80004248:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000424a:	000aa583          	lw	a1,0(s5)
    8000424e:	028a2503          	lw	a0,40(s4)
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	ce4080e7          	jalr	-796(ra) # 80002f36 <bread>
    8000425a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000425c:	40000613          	li	a2,1024
    80004260:	05850593          	add	a1,a0,88
    80004264:	05848513          	add	a0,s1,88
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	b38080e7          	jalr	-1224(ra) # 80000da0 <memmove>
    bwrite(to);  // write the log
    80004270:	8526                	mv	a0,s1
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	db6080e7          	jalr	-586(ra) # 80003028 <bwrite>
    brelse(from);
    8000427a:	854e                	mv	a0,s3
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	dea080e7          	jalr	-534(ra) # 80003066 <brelse>
    brelse(to);
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	de0080e7          	jalr	-544(ra) # 80003066 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428e:	2905                	addw	s2,s2,1
    80004290:	0a91                	add	s5,s5,4
    80004292:	02ca2783          	lw	a5,44(s4)
    80004296:	f8f94ee3          	blt	s2,a5,80004232 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	c8c080e7          	jalr	-884(ra) # 80003f26 <write_head>
    install_trans(0); // Now install writes to home locations
    800042a2:	4501                	li	a0,0
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	cec080e7          	jalr	-788(ra) # 80003f90 <install_trans>
    log.lh.n = 0;
    800042ac:	0001d797          	auipc	a5,0x1d
    800042b0:	ec07a823          	sw	zero,-304(a5) # 8002117c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	c72080e7          	jalr	-910(ra) # 80003f26 <write_head>
    800042bc:	bdf5                	j	800041b8 <end_op+0x52>

00000000800042be <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042be:	1101                	add	sp,sp,-32
    800042c0:	ec06                	sd	ra,24(sp)
    800042c2:	e822                	sd	s0,16(sp)
    800042c4:	e426                	sd	s1,8(sp)
    800042c6:	e04a                	sd	s2,0(sp)
    800042c8:	1000                	add	s0,sp,32
    800042ca:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042cc:	0001d917          	auipc	s2,0x1d
    800042d0:	e8490913          	add	s2,s2,-380 # 80021150 <log>
    800042d4:	854a                	mv	a0,s2
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	972080e7          	jalr	-1678(ra) # 80000c48 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042de:	02c92603          	lw	a2,44(s2)
    800042e2:	47f5                	li	a5,29
    800042e4:	06c7c563          	blt	a5,a2,8000434e <log_write+0x90>
    800042e8:	0001d797          	auipc	a5,0x1d
    800042ec:	e847a783          	lw	a5,-380(a5) # 8002116c <log+0x1c>
    800042f0:	37fd                	addw	a5,a5,-1
    800042f2:	04f65e63          	bge	a2,a5,8000434e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042f6:	0001d797          	auipc	a5,0x1d
    800042fa:	e7a7a783          	lw	a5,-390(a5) # 80021170 <log+0x20>
    800042fe:	06f05063          	blez	a5,8000435e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004302:	4781                	li	a5,0
    80004304:	06c05563          	blez	a2,8000436e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004308:	44cc                	lw	a1,12(s1)
    8000430a:	0001d717          	auipc	a4,0x1d
    8000430e:	e7670713          	add	a4,a4,-394 # 80021180 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004312:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004314:	4314                	lw	a3,0(a4)
    80004316:	04b68c63          	beq	a3,a1,8000436e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000431a:	2785                	addw	a5,a5,1
    8000431c:	0711                	add	a4,a4,4
    8000431e:	fef61be3          	bne	a2,a5,80004314 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004322:	0621                	add	a2,a2,8
    80004324:	060a                	sll	a2,a2,0x2
    80004326:	0001d797          	auipc	a5,0x1d
    8000432a:	e2a78793          	add	a5,a5,-470 # 80021150 <log>
    8000432e:	97b2                	add	a5,a5,a2
    80004330:	44d8                	lw	a4,12(s1)
    80004332:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004334:	8526                	mv	a0,s1
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	dcc080e7          	jalr	-564(ra) # 80003102 <bpin>
    log.lh.n++;
    8000433e:	0001d717          	auipc	a4,0x1d
    80004342:	e1270713          	add	a4,a4,-494 # 80021150 <log>
    80004346:	575c                	lw	a5,44(a4)
    80004348:	2785                	addw	a5,a5,1
    8000434a:	d75c                	sw	a5,44(a4)
    8000434c:	a82d                	j	80004386 <log_write+0xc8>
    panic("too big a transaction");
    8000434e:	00004517          	auipc	a0,0x4
    80004352:	33a50513          	add	a0,a0,826 # 80008688 <syscalls+0x1f0>
    80004356:	ffffc097          	auipc	ra,0xffffc
    8000435a:	1ea080e7          	jalr	490(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000435e:	00004517          	auipc	a0,0x4
    80004362:	34250513          	add	a0,a0,834 # 800086a0 <syscalls+0x208>
    80004366:	ffffc097          	auipc	ra,0xffffc
    8000436a:	1da080e7          	jalr	474(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000436e:	00878693          	add	a3,a5,8
    80004372:	068a                	sll	a3,a3,0x2
    80004374:	0001d717          	auipc	a4,0x1d
    80004378:	ddc70713          	add	a4,a4,-548 # 80021150 <log>
    8000437c:	9736                	add	a4,a4,a3
    8000437e:	44d4                	lw	a3,12(s1)
    80004380:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004382:	faf609e3          	beq	a2,a5,80004334 <log_write+0x76>
  }
  release(&log.lock);
    80004386:	0001d517          	auipc	a0,0x1d
    8000438a:	dca50513          	add	a0,a0,-566 # 80021150 <log>
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	96e080e7          	jalr	-1682(ra) # 80000cfc <release>
}
    80004396:	60e2                	ld	ra,24(sp)
    80004398:	6442                	ld	s0,16(sp)
    8000439a:	64a2                	ld	s1,8(sp)
    8000439c:	6902                	ld	s2,0(sp)
    8000439e:	6105                	add	sp,sp,32
    800043a0:	8082                	ret

00000000800043a2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043a2:	1101                	add	sp,sp,-32
    800043a4:	ec06                	sd	ra,24(sp)
    800043a6:	e822                	sd	s0,16(sp)
    800043a8:	e426                	sd	s1,8(sp)
    800043aa:	e04a                	sd	s2,0(sp)
    800043ac:	1000                	add	s0,sp,32
    800043ae:	84aa                	mv	s1,a0
    800043b0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043b2:	00004597          	auipc	a1,0x4
    800043b6:	30e58593          	add	a1,a1,782 # 800086c0 <syscalls+0x228>
    800043ba:	0521                	add	a0,a0,8
    800043bc:	ffffc097          	auipc	ra,0xffffc
    800043c0:	7fc080e7          	jalr	2044(ra) # 80000bb8 <initlock>
  lk->name = name;
    800043c4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043c8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043cc:	0204a423          	sw	zero,40(s1)
}
    800043d0:	60e2                	ld	ra,24(sp)
    800043d2:	6442                	ld	s0,16(sp)
    800043d4:	64a2                	ld	s1,8(sp)
    800043d6:	6902                	ld	s2,0(sp)
    800043d8:	6105                	add	sp,sp,32
    800043da:	8082                	ret

00000000800043dc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043dc:	1101                	add	sp,sp,-32
    800043de:	ec06                	sd	ra,24(sp)
    800043e0:	e822                	sd	s0,16(sp)
    800043e2:	e426                	sd	s1,8(sp)
    800043e4:	e04a                	sd	s2,0(sp)
    800043e6:	1000                	add	s0,sp,32
    800043e8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ea:	00850913          	add	s2,a0,8
    800043ee:	854a                	mv	a0,s2
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	858080e7          	jalr	-1960(ra) # 80000c48 <acquire>
  while (lk->locked) {
    800043f8:	409c                	lw	a5,0(s1)
    800043fa:	cb89                	beqz	a5,8000440c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043fc:	85ca                	mv	a1,s2
    800043fe:	8526                	mv	a0,s1
    80004400:	ffffe097          	auipc	ra,0xffffe
    80004404:	cfa080e7          	jalr	-774(ra) # 800020fa <sleep>
  while (lk->locked) {
    80004408:	409c                	lw	a5,0(s1)
    8000440a:	fbed                	bnez	a5,800043fc <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000440c:	4785                	li	a5,1
    8000440e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	614080e7          	jalr	1556(ra) # 80001a24 <myproc>
    80004418:	591c                	lw	a5,48(a0)
    8000441a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000441c:	854a                	mv	a0,s2
    8000441e:	ffffd097          	auipc	ra,0xffffd
    80004422:	8de080e7          	jalr	-1826(ra) # 80000cfc <release>
}
    80004426:	60e2                	ld	ra,24(sp)
    80004428:	6442                	ld	s0,16(sp)
    8000442a:	64a2                	ld	s1,8(sp)
    8000442c:	6902                	ld	s2,0(sp)
    8000442e:	6105                	add	sp,sp,32
    80004430:	8082                	ret

0000000080004432 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004432:	1101                	add	sp,sp,-32
    80004434:	ec06                	sd	ra,24(sp)
    80004436:	e822                	sd	s0,16(sp)
    80004438:	e426                	sd	s1,8(sp)
    8000443a:	e04a                	sd	s2,0(sp)
    8000443c:	1000                	add	s0,sp,32
    8000443e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004440:	00850913          	add	s2,a0,8
    80004444:	854a                	mv	a0,s2
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	802080e7          	jalr	-2046(ra) # 80000c48 <acquire>
  lk->locked = 0;
    8000444e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004452:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004456:	8526                	mv	a0,s1
    80004458:	ffffe097          	auipc	ra,0xffffe
    8000445c:	d06080e7          	jalr	-762(ra) # 8000215e <wakeup>
  release(&lk->lk);
    80004460:	854a                	mv	a0,s2
    80004462:	ffffd097          	auipc	ra,0xffffd
    80004466:	89a080e7          	jalr	-1894(ra) # 80000cfc <release>
}
    8000446a:	60e2                	ld	ra,24(sp)
    8000446c:	6442                	ld	s0,16(sp)
    8000446e:	64a2                	ld	s1,8(sp)
    80004470:	6902                	ld	s2,0(sp)
    80004472:	6105                	add	sp,sp,32
    80004474:	8082                	ret

0000000080004476 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004476:	7179                	add	sp,sp,-48
    80004478:	f406                	sd	ra,40(sp)
    8000447a:	f022                	sd	s0,32(sp)
    8000447c:	ec26                	sd	s1,24(sp)
    8000447e:	e84a                	sd	s2,16(sp)
    80004480:	e44e                	sd	s3,8(sp)
    80004482:	1800                	add	s0,sp,48
    80004484:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004486:	00850913          	add	s2,a0,8
    8000448a:	854a                	mv	a0,s2
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	7bc080e7          	jalr	1980(ra) # 80000c48 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004494:	409c                	lw	a5,0(s1)
    80004496:	ef99                	bnez	a5,800044b4 <holdingsleep+0x3e>
    80004498:	4481                	li	s1,0
  release(&lk->lk);
    8000449a:	854a                	mv	a0,s2
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	860080e7          	jalr	-1952(ra) # 80000cfc <release>
  return r;
}
    800044a4:	8526                	mv	a0,s1
    800044a6:	70a2                	ld	ra,40(sp)
    800044a8:	7402                	ld	s0,32(sp)
    800044aa:	64e2                	ld	s1,24(sp)
    800044ac:	6942                	ld	s2,16(sp)
    800044ae:	69a2                	ld	s3,8(sp)
    800044b0:	6145                	add	sp,sp,48
    800044b2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044b4:	0284a983          	lw	s3,40(s1)
    800044b8:	ffffd097          	auipc	ra,0xffffd
    800044bc:	56c080e7          	jalr	1388(ra) # 80001a24 <myproc>
    800044c0:	5904                	lw	s1,48(a0)
    800044c2:	413484b3          	sub	s1,s1,s3
    800044c6:	0014b493          	seqz	s1,s1
    800044ca:	bfc1                	j	8000449a <holdingsleep+0x24>

00000000800044cc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044cc:	1141                	add	sp,sp,-16
    800044ce:	e406                	sd	ra,8(sp)
    800044d0:	e022                	sd	s0,0(sp)
    800044d2:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044d4:	00004597          	auipc	a1,0x4
    800044d8:	1fc58593          	add	a1,a1,508 # 800086d0 <syscalls+0x238>
    800044dc:	0001d517          	auipc	a0,0x1d
    800044e0:	dbc50513          	add	a0,a0,-580 # 80021298 <ftable>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	6d4080e7          	jalr	1748(ra) # 80000bb8 <initlock>
}
    800044ec:	60a2                	ld	ra,8(sp)
    800044ee:	6402                	ld	s0,0(sp)
    800044f0:	0141                	add	sp,sp,16
    800044f2:	8082                	ret

00000000800044f4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044f4:	1101                	add	sp,sp,-32
    800044f6:	ec06                	sd	ra,24(sp)
    800044f8:	e822                	sd	s0,16(sp)
    800044fa:	e426                	sd	s1,8(sp)
    800044fc:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044fe:	0001d517          	auipc	a0,0x1d
    80004502:	d9a50513          	add	a0,a0,-614 # 80021298 <ftable>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	742080e7          	jalr	1858(ra) # 80000c48 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000450e:	0001d497          	auipc	s1,0x1d
    80004512:	da248493          	add	s1,s1,-606 # 800212b0 <ftable+0x18>
    80004516:	0001e717          	auipc	a4,0x1e
    8000451a:	d3a70713          	add	a4,a4,-710 # 80022250 <disk>
    if(f->ref == 0){
    8000451e:	40dc                	lw	a5,4(s1)
    80004520:	cf99                	beqz	a5,8000453e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004522:	02848493          	add	s1,s1,40
    80004526:	fee49ce3          	bne	s1,a4,8000451e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000452a:	0001d517          	auipc	a0,0x1d
    8000452e:	d6e50513          	add	a0,a0,-658 # 80021298 <ftable>
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	7ca080e7          	jalr	1994(ra) # 80000cfc <release>
  return 0;
    8000453a:	4481                	li	s1,0
    8000453c:	a819                	j	80004552 <filealloc+0x5e>
      f->ref = 1;
    8000453e:	4785                	li	a5,1
    80004540:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004542:	0001d517          	auipc	a0,0x1d
    80004546:	d5650513          	add	a0,a0,-682 # 80021298 <ftable>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	7b2080e7          	jalr	1970(ra) # 80000cfc <release>
}
    80004552:	8526                	mv	a0,s1
    80004554:	60e2                	ld	ra,24(sp)
    80004556:	6442                	ld	s0,16(sp)
    80004558:	64a2                	ld	s1,8(sp)
    8000455a:	6105                	add	sp,sp,32
    8000455c:	8082                	ret

000000008000455e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000455e:	1101                	add	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	1000                	add	s0,sp,32
    80004568:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000456a:	0001d517          	auipc	a0,0x1d
    8000456e:	d2e50513          	add	a0,a0,-722 # 80021298 <ftable>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	6d6080e7          	jalr	1750(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    8000457a:	40dc                	lw	a5,4(s1)
    8000457c:	02f05263          	blez	a5,800045a0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004580:	2785                	addw	a5,a5,1
    80004582:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	d1450513          	add	a0,a0,-748 # 80021298 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	770080e7          	jalr	1904(ra) # 80000cfc <release>
  return f;
}
    80004594:	8526                	mv	a0,s1
    80004596:	60e2                	ld	ra,24(sp)
    80004598:	6442                	ld	s0,16(sp)
    8000459a:	64a2                	ld	s1,8(sp)
    8000459c:	6105                	add	sp,sp,32
    8000459e:	8082                	ret
    panic("filedup");
    800045a0:	00004517          	auipc	a0,0x4
    800045a4:	13850513          	add	a0,a0,312 # 800086d8 <syscalls+0x240>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	f98080e7          	jalr	-104(ra) # 80000540 <panic>

00000000800045b0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045b0:	7139                	add	sp,sp,-64
    800045b2:	fc06                	sd	ra,56(sp)
    800045b4:	f822                	sd	s0,48(sp)
    800045b6:	f426                	sd	s1,40(sp)
    800045b8:	f04a                	sd	s2,32(sp)
    800045ba:	ec4e                	sd	s3,24(sp)
    800045bc:	e852                	sd	s4,16(sp)
    800045be:	e456                	sd	s5,8(sp)
    800045c0:	0080                	add	s0,sp,64
    800045c2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045c4:	0001d517          	auipc	a0,0x1d
    800045c8:	cd450513          	add	a0,a0,-812 # 80021298 <ftable>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	67c080e7          	jalr	1660(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    800045d4:	40dc                	lw	a5,4(s1)
    800045d6:	06f05163          	blez	a5,80004638 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045da:	37fd                	addw	a5,a5,-1
    800045dc:	0007871b          	sext.w	a4,a5
    800045e0:	c0dc                	sw	a5,4(s1)
    800045e2:	06e04363          	bgtz	a4,80004648 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045e6:	0004a903          	lw	s2,0(s1)
    800045ea:	0094ca83          	lbu	s5,9(s1)
    800045ee:	0104ba03          	ld	s4,16(s1)
    800045f2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045f6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045fa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045fe:	0001d517          	auipc	a0,0x1d
    80004602:	c9a50513          	add	a0,a0,-870 # 80021298 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	6f6080e7          	jalr	1782(ra) # 80000cfc <release>

  if(ff.type == FD_PIPE){
    8000460e:	4785                	li	a5,1
    80004610:	04f90d63          	beq	s2,a5,8000466a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004614:	3979                	addw	s2,s2,-2
    80004616:	4785                	li	a5,1
    80004618:	0527e063          	bltu	a5,s2,80004658 <fileclose+0xa8>
    begin_op();
    8000461c:	00000097          	auipc	ra,0x0
    80004620:	ad0080e7          	jalr	-1328(ra) # 800040ec <begin_op>
    iput(ff.ip);
    80004624:	854e                	mv	a0,s3
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	2da080e7          	jalr	730(ra) # 80003900 <iput>
    end_op();
    8000462e:	00000097          	auipc	ra,0x0
    80004632:	b38080e7          	jalr	-1224(ra) # 80004166 <end_op>
    80004636:	a00d                	j	80004658 <fileclose+0xa8>
    panic("fileclose");
    80004638:	00004517          	auipc	a0,0x4
    8000463c:	0a850513          	add	a0,a0,168 # 800086e0 <syscalls+0x248>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	f00080e7          	jalr	-256(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004648:	0001d517          	auipc	a0,0x1d
    8000464c:	c5050513          	add	a0,a0,-944 # 80021298 <ftable>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	6ac080e7          	jalr	1708(ra) # 80000cfc <release>
  }
}
    80004658:	70e2                	ld	ra,56(sp)
    8000465a:	7442                	ld	s0,48(sp)
    8000465c:	74a2                	ld	s1,40(sp)
    8000465e:	7902                	ld	s2,32(sp)
    80004660:	69e2                	ld	s3,24(sp)
    80004662:	6a42                	ld	s4,16(sp)
    80004664:	6aa2                	ld	s5,8(sp)
    80004666:	6121                	add	sp,sp,64
    80004668:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000466a:	85d6                	mv	a1,s5
    8000466c:	8552                	mv	a0,s4
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	348080e7          	jalr	840(ra) # 800049b6 <pipeclose>
    80004676:	b7cd                	j	80004658 <fileclose+0xa8>

0000000080004678 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004678:	715d                	add	sp,sp,-80
    8000467a:	e486                	sd	ra,72(sp)
    8000467c:	e0a2                	sd	s0,64(sp)
    8000467e:	fc26                	sd	s1,56(sp)
    80004680:	f84a                	sd	s2,48(sp)
    80004682:	f44e                	sd	s3,40(sp)
    80004684:	0880                	add	s0,sp,80
    80004686:	84aa                	mv	s1,a0
    80004688:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000468a:	ffffd097          	auipc	ra,0xffffd
    8000468e:	39a080e7          	jalr	922(ra) # 80001a24 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004692:	409c                	lw	a5,0(s1)
    80004694:	37f9                	addw	a5,a5,-2
    80004696:	4705                	li	a4,1
    80004698:	04f76763          	bltu	a4,a5,800046e6 <filestat+0x6e>
    8000469c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000469e:	6c88                	ld	a0,24(s1)
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	0a6080e7          	jalr	166(ra) # 80003746 <ilock>
    stati(f->ip, &st);
    800046a8:	fb840593          	add	a1,s0,-72
    800046ac:	6c88                	ld	a0,24(s1)
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	322080e7          	jalr	802(ra) # 800039d0 <stati>
    iunlock(f->ip);
    800046b6:	6c88                	ld	a0,24(s1)
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	150080e7          	jalr	336(ra) # 80003808 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046c0:	46e1                	li	a3,24
    800046c2:	fb840613          	add	a2,s0,-72
    800046c6:	85ce                	mv	a1,s3
    800046c8:	05093503          	ld	a0,80(s2)
    800046cc:	ffffd097          	auipc	ra,0xffffd
    800046d0:	018080e7          	jalr	24(ra) # 800016e4 <copyout>
    800046d4:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046d8:	60a6                	ld	ra,72(sp)
    800046da:	6406                	ld	s0,64(sp)
    800046dc:	74e2                	ld	s1,56(sp)
    800046de:	7942                	ld	s2,48(sp)
    800046e0:	79a2                	ld	s3,40(sp)
    800046e2:	6161                	add	sp,sp,80
    800046e4:	8082                	ret
  return -1;
    800046e6:	557d                	li	a0,-1
    800046e8:	bfc5                	j	800046d8 <filestat+0x60>

00000000800046ea <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046ea:	7179                	add	sp,sp,-48
    800046ec:	f406                	sd	ra,40(sp)
    800046ee:	f022                	sd	s0,32(sp)
    800046f0:	ec26                	sd	s1,24(sp)
    800046f2:	e84a                	sd	s2,16(sp)
    800046f4:	e44e                	sd	s3,8(sp)
    800046f6:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046f8:	00854783          	lbu	a5,8(a0)
    800046fc:	c3d5                	beqz	a5,800047a0 <fileread+0xb6>
    800046fe:	84aa                	mv	s1,a0
    80004700:	89ae                	mv	s3,a1
    80004702:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004704:	411c                	lw	a5,0(a0)
    80004706:	4705                	li	a4,1
    80004708:	04e78963          	beq	a5,a4,8000475a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000470c:	470d                	li	a4,3
    8000470e:	04e78d63          	beq	a5,a4,80004768 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004712:	4709                	li	a4,2
    80004714:	06e79e63          	bne	a5,a4,80004790 <fileread+0xa6>
    ilock(f->ip);
    80004718:	6d08                	ld	a0,24(a0)
    8000471a:	fffff097          	auipc	ra,0xfffff
    8000471e:	02c080e7          	jalr	44(ra) # 80003746 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004722:	874a                	mv	a4,s2
    80004724:	5094                	lw	a3,32(s1)
    80004726:	864e                	mv	a2,s3
    80004728:	4585                	li	a1,1
    8000472a:	6c88                	ld	a0,24(s1)
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	2ce080e7          	jalr	718(ra) # 800039fa <readi>
    80004734:	892a                	mv	s2,a0
    80004736:	00a05563          	blez	a0,80004740 <fileread+0x56>
      f->off += r;
    8000473a:	509c                	lw	a5,32(s1)
    8000473c:	9fa9                	addw	a5,a5,a0
    8000473e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004740:	6c88                	ld	a0,24(s1)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	0c6080e7          	jalr	198(ra) # 80003808 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000474a:	854a                	mv	a0,s2
    8000474c:	70a2                	ld	ra,40(sp)
    8000474e:	7402                	ld	s0,32(sp)
    80004750:	64e2                	ld	s1,24(sp)
    80004752:	6942                	ld	s2,16(sp)
    80004754:	69a2                	ld	s3,8(sp)
    80004756:	6145                	add	sp,sp,48
    80004758:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000475a:	6908                	ld	a0,16(a0)
    8000475c:	00000097          	auipc	ra,0x0
    80004760:	3c2080e7          	jalr	962(ra) # 80004b1e <piperead>
    80004764:	892a                	mv	s2,a0
    80004766:	b7d5                	j	8000474a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004768:	02451783          	lh	a5,36(a0)
    8000476c:	03079693          	sll	a3,a5,0x30
    80004770:	92c1                	srl	a3,a3,0x30
    80004772:	4725                	li	a4,9
    80004774:	02d76863          	bltu	a4,a3,800047a4 <fileread+0xba>
    80004778:	0792                	sll	a5,a5,0x4
    8000477a:	0001d717          	auipc	a4,0x1d
    8000477e:	a7e70713          	add	a4,a4,-1410 # 800211f8 <devsw>
    80004782:	97ba                	add	a5,a5,a4
    80004784:	639c                	ld	a5,0(a5)
    80004786:	c38d                	beqz	a5,800047a8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004788:	4505                	li	a0,1
    8000478a:	9782                	jalr	a5
    8000478c:	892a                	mv	s2,a0
    8000478e:	bf75                	j	8000474a <fileread+0x60>
    panic("fileread");
    80004790:	00004517          	auipc	a0,0x4
    80004794:	f6050513          	add	a0,a0,-160 # 800086f0 <syscalls+0x258>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	da8080e7          	jalr	-600(ra) # 80000540 <panic>
    return -1;
    800047a0:	597d                	li	s2,-1
    800047a2:	b765                	j	8000474a <fileread+0x60>
      return -1;
    800047a4:	597d                	li	s2,-1
    800047a6:	b755                	j	8000474a <fileread+0x60>
    800047a8:	597d                	li	s2,-1
    800047aa:	b745                	j	8000474a <fileread+0x60>

00000000800047ac <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047ac:	00954783          	lbu	a5,9(a0)
    800047b0:	10078e63          	beqz	a5,800048cc <filewrite+0x120>
{
    800047b4:	715d                	add	sp,sp,-80
    800047b6:	e486                	sd	ra,72(sp)
    800047b8:	e0a2                	sd	s0,64(sp)
    800047ba:	fc26                	sd	s1,56(sp)
    800047bc:	f84a                	sd	s2,48(sp)
    800047be:	f44e                	sd	s3,40(sp)
    800047c0:	f052                	sd	s4,32(sp)
    800047c2:	ec56                	sd	s5,24(sp)
    800047c4:	e85a                	sd	s6,16(sp)
    800047c6:	e45e                	sd	s7,8(sp)
    800047c8:	e062                	sd	s8,0(sp)
    800047ca:	0880                	add	s0,sp,80
    800047cc:	892a                	mv	s2,a0
    800047ce:	8b2e                	mv	s6,a1
    800047d0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047d2:	411c                	lw	a5,0(a0)
    800047d4:	4705                	li	a4,1
    800047d6:	02e78263          	beq	a5,a4,800047fa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047da:	470d                	li	a4,3
    800047dc:	02e78563          	beq	a5,a4,80004806 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047e0:	4709                	li	a4,2
    800047e2:	0ce79d63          	bne	a5,a4,800048bc <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047e6:	0ac05b63          	blez	a2,8000489c <filewrite+0xf0>
    int i = 0;
    800047ea:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800047ec:	6b85                	lui	s7,0x1
    800047ee:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047f2:	6c05                	lui	s8,0x1
    800047f4:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047f8:	a851                	j	8000488c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047fa:	6908                	ld	a0,16(a0)
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	22a080e7          	jalr	554(ra) # 80004a26 <pipewrite>
    80004804:	a045                	j	800048a4 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004806:	02451783          	lh	a5,36(a0)
    8000480a:	03079693          	sll	a3,a5,0x30
    8000480e:	92c1                	srl	a3,a3,0x30
    80004810:	4725                	li	a4,9
    80004812:	0ad76f63          	bltu	a4,a3,800048d0 <filewrite+0x124>
    80004816:	0792                	sll	a5,a5,0x4
    80004818:	0001d717          	auipc	a4,0x1d
    8000481c:	9e070713          	add	a4,a4,-1568 # 800211f8 <devsw>
    80004820:	97ba                	add	a5,a5,a4
    80004822:	679c                	ld	a5,8(a5)
    80004824:	cbc5                	beqz	a5,800048d4 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004826:	4505                	li	a0,1
    80004828:	9782                	jalr	a5
    8000482a:	a8ad                	j	800048a4 <filewrite+0xf8>
      if(n1 > max)
    8000482c:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004830:	00000097          	auipc	ra,0x0
    80004834:	8bc080e7          	jalr	-1860(ra) # 800040ec <begin_op>
      ilock(f->ip);
    80004838:	01893503          	ld	a0,24(s2)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	f0a080e7          	jalr	-246(ra) # 80003746 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004844:	8756                	mv	a4,s5
    80004846:	02092683          	lw	a3,32(s2)
    8000484a:	01698633          	add	a2,s3,s6
    8000484e:	4585                	li	a1,1
    80004850:	01893503          	ld	a0,24(s2)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	29e080e7          	jalr	670(ra) # 80003af2 <writei>
    8000485c:	84aa                	mv	s1,a0
    8000485e:	00a05763          	blez	a0,8000486c <filewrite+0xc0>
        f->off += r;
    80004862:	02092783          	lw	a5,32(s2)
    80004866:	9fa9                	addw	a5,a5,a0
    80004868:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000486c:	01893503          	ld	a0,24(s2)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	f98080e7          	jalr	-104(ra) # 80003808 <iunlock>
      end_op();
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	8ee080e7          	jalr	-1810(ra) # 80004166 <end_op>

      if(r != n1){
    80004880:	009a9f63          	bne	s5,s1,8000489e <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004884:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004888:	0149db63          	bge	s3,s4,8000489e <filewrite+0xf2>
      int n1 = n - i;
    8000488c:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004890:	0004879b          	sext.w	a5,s1
    80004894:	f8fbdce3          	bge	s7,a5,8000482c <filewrite+0x80>
    80004898:	84e2                	mv	s1,s8
    8000489a:	bf49                	j	8000482c <filewrite+0x80>
    int i = 0;
    8000489c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000489e:	033a1d63          	bne	s4,s3,800048d8 <filewrite+0x12c>
    800048a2:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048a4:	60a6                	ld	ra,72(sp)
    800048a6:	6406                	ld	s0,64(sp)
    800048a8:	74e2                	ld	s1,56(sp)
    800048aa:	7942                	ld	s2,48(sp)
    800048ac:	79a2                	ld	s3,40(sp)
    800048ae:	7a02                	ld	s4,32(sp)
    800048b0:	6ae2                	ld	s5,24(sp)
    800048b2:	6b42                	ld	s6,16(sp)
    800048b4:	6ba2                	ld	s7,8(sp)
    800048b6:	6c02                	ld	s8,0(sp)
    800048b8:	6161                	add	sp,sp,80
    800048ba:	8082                	ret
    panic("filewrite");
    800048bc:	00004517          	auipc	a0,0x4
    800048c0:	e4450513          	add	a0,a0,-444 # 80008700 <syscalls+0x268>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>
    return -1;
    800048cc:	557d                	li	a0,-1
}
    800048ce:	8082                	ret
      return -1;
    800048d0:	557d                	li	a0,-1
    800048d2:	bfc9                	j	800048a4 <filewrite+0xf8>
    800048d4:	557d                	li	a0,-1
    800048d6:	b7f9                	j	800048a4 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048d8:	557d                	li	a0,-1
    800048da:	b7e9                	j	800048a4 <filewrite+0xf8>

00000000800048dc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048dc:	7179                	add	sp,sp,-48
    800048de:	f406                	sd	ra,40(sp)
    800048e0:	f022                	sd	s0,32(sp)
    800048e2:	ec26                	sd	s1,24(sp)
    800048e4:	e84a                	sd	s2,16(sp)
    800048e6:	e44e                	sd	s3,8(sp)
    800048e8:	e052                	sd	s4,0(sp)
    800048ea:	1800                	add	s0,sp,48
    800048ec:	84aa                	mv	s1,a0
    800048ee:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048f0:	0005b023          	sd	zero,0(a1)
    800048f4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048f8:	00000097          	auipc	ra,0x0
    800048fc:	bfc080e7          	jalr	-1028(ra) # 800044f4 <filealloc>
    80004900:	e088                	sd	a0,0(s1)
    80004902:	c551                	beqz	a0,8000498e <pipealloc+0xb2>
    80004904:	00000097          	auipc	ra,0x0
    80004908:	bf0080e7          	jalr	-1040(ra) # 800044f4 <filealloc>
    8000490c:	00aa3023          	sd	a0,0(s4)
    80004910:	c92d                	beqz	a0,80004982 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	246080e7          	jalr	582(ra) # 80000b58 <kalloc>
    8000491a:	892a                	mv	s2,a0
    8000491c:	c125                	beqz	a0,8000497c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000491e:	4985                	li	s3,1
    80004920:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004924:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004928:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000492c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004930:	00004597          	auipc	a1,0x4
    80004934:	de058593          	add	a1,a1,-544 # 80008710 <syscalls+0x278>
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	280080e7          	jalr	640(ra) # 80000bb8 <initlock>
  (*f0)->type = FD_PIPE;
    80004940:	609c                	ld	a5,0(s1)
    80004942:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004946:	609c                	ld	a5,0(s1)
    80004948:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000494c:	609c                	ld	a5,0(s1)
    8000494e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004952:	609c                	ld	a5,0(s1)
    80004954:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004958:	000a3783          	ld	a5,0(s4)
    8000495c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004960:	000a3783          	ld	a5,0(s4)
    80004964:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004968:	000a3783          	ld	a5,0(s4)
    8000496c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004970:	000a3783          	ld	a5,0(s4)
    80004974:	0127b823          	sd	s2,16(a5)
  return 0;
    80004978:	4501                	li	a0,0
    8000497a:	a025                	j	800049a2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000497c:	6088                	ld	a0,0(s1)
    8000497e:	e501                	bnez	a0,80004986 <pipealloc+0xaa>
    80004980:	a039                	j	8000498e <pipealloc+0xb2>
    80004982:	6088                	ld	a0,0(s1)
    80004984:	c51d                	beqz	a0,800049b2 <pipealloc+0xd6>
    fileclose(*f0);
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	c2a080e7          	jalr	-982(ra) # 800045b0 <fileclose>
  if(*f1)
    8000498e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004992:	557d                	li	a0,-1
  if(*f1)
    80004994:	c799                	beqz	a5,800049a2 <pipealloc+0xc6>
    fileclose(*f1);
    80004996:	853e                	mv	a0,a5
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	c18080e7          	jalr	-1000(ra) # 800045b0 <fileclose>
  return -1;
    800049a0:	557d                	li	a0,-1
}
    800049a2:	70a2                	ld	ra,40(sp)
    800049a4:	7402                	ld	s0,32(sp)
    800049a6:	64e2                	ld	s1,24(sp)
    800049a8:	6942                	ld	s2,16(sp)
    800049aa:	69a2                	ld	s3,8(sp)
    800049ac:	6a02                	ld	s4,0(sp)
    800049ae:	6145                	add	sp,sp,48
    800049b0:	8082                	ret
  return -1;
    800049b2:	557d                	li	a0,-1
    800049b4:	b7fd                	j	800049a2 <pipealloc+0xc6>

00000000800049b6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049b6:	1101                	add	sp,sp,-32
    800049b8:	ec06                	sd	ra,24(sp)
    800049ba:	e822                	sd	s0,16(sp)
    800049bc:	e426                	sd	s1,8(sp)
    800049be:	e04a                	sd	s2,0(sp)
    800049c0:	1000                	add	s0,sp,32
    800049c2:	84aa                	mv	s1,a0
    800049c4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	282080e7          	jalr	642(ra) # 80000c48 <acquire>
  if(writable){
    800049ce:	02090d63          	beqz	s2,80004a08 <pipeclose+0x52>
    pi->writeopen = 0;
    800049d2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049d6:	21848513          	add	a0,s1,536
    800049da:	ffffd097          	auipc	ra,0xffffd
    800049de:	784080e7          	jalr	1924(ra) # 8000215e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049e2:	2204b783          	ld	a5,544(s1)
    800049e6:	eb95                	bnez	a5,80004a1a <pipeclose+0x64>
    release(&pi->lock);
    800049e8:	8526                	mv	a0,s1
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	312080e7          	jalr	786(ra) # 80000cfc <release>
    kfree((char*)pi);
    800049f2:	8526                	mv	a0,s1
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	066080e7          	jalr	102(ra) # 80000a5a <kfree>
  } else
    release(&pi->lock);
}
    800049fc:	60e2                	ld	ra,24(sp)
    800049fe:	6442                	ld	s0,16(sp)
    80004a00:	64a2                	ld	s1,8(sp)
    80004a02:	6902                	ld	s2,0(sp)
    80004a04:	6105                	add	sp,sp,32
    80004a06:	8082                	ret
    pi->readopen = 0;
    80004a08:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a0c:	21c48513          	add	a0,s1,540
    80004a10:	ffffd097          	auipc	ra,0xffffd
    80004a14:	74e080e7          	jalr	1870(ra) # 8000215e <wakeup>
    80004a18:	b7e9                	j	800049e2 <pipeclose+0x2c>
    release(&pi->lock);
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	2e0080e7          	jalr	736(ra) # 80000cfc <release>
}
    80004a24:	bfe1                	j	800049fc <pipeclose+0x46>

0000000080004a26 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a26:	711d                	add	sp,sp,-96
    80004a28:	ec86                	sd	ra,88(sp)
    80004a2a:	e8a2                	sd	s0,80(sp)
    80004a2c:	e4a6                	sd	s1,72(sp)
    80004a2e:	e0ca                	sd	s2,64(sp)
    80004a30:	fc4e                	sd	s3,56(sp)
    80004a32:	f852                	sd	s4,48(sp)
    80004a34:	f456                	sd	s5,40(sp)
    80004a36:	f05a                	sd	s6,32(sp)
    80004a38:	ec5e                	sd	s7,24(sp)
    80004a3a:	e862                	sd	s8,16(sp)
    80004a3c:	1080                	add	s0,sp,96
    80004a3e:	84aa                	mv	s1,a0
    80004a40:	8aae                	mv	s5,a1
    80004a42:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a44:	ffffd097          	auipc	ra,0xffffd
    80004a48:	fe0080e7          	jalr	-32(ra) # 80001a24 <myproc>
    80004a4c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a4e:	8526                	mv	a0,s1
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	1f8080e7          	jalr	504(ra) # 80000c48 <acquire>
  while(i < n){
    80004a58:	0b405663          	blez	s4,80004b04 <pipewrite+0xde>
  int i = 0;
    80004a5c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a5e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a60:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a64:	21c48b93          	add	s7,s1,540
    80004a68:	a089                	j	80004aaa <pipewrite+0x84>
      release(&pi->lock);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	290080e7          	jalr	656(ra) # 80000cfc <release>
      return -1;
    80004a74:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a76:	854a                	mv	a0,s2
    80004a78:	60e6                	ld	ra,88(sp)
    80004a7a:	6446                	ld	s0,80(sp)
    80004a7c:	64a6                	ld	s1,72(sp)
    80004a7e:	6906                	ld	s2,64(sp)
    80004a80:	79e2                	ld	s3,56(sp)
    80004a82:	7a42                	ld	s4,48(sp)
    80004a84:	7aa2                	ld	s5,40(sp)
    80004a86:	7b02                	ld	s6,32(sp)
    80004a88:	6be2                	ld	s7,24(sp)
    80004a8a:	6c42                	ld	s8,16(sp)
    80004a8c:	6125                	add	sp,sp,96
    80004a8e:	8082                	ret
      wakeup(&pi->nread);
    80004a90:	8562                	mv	a0,s8
    80004a92:	ffffd097          	auipc	ra,0xffffd
    80004a96:	6cc080e7          	jalr	1740(ra) # 8000215e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a9a:	85a6                	mv	a1,s1
    80004a9c:	855e                	mv	a0,s7
    80004a9e:	ffffd097          	auipc	ra,0xffffd
    80004aa2:	65c080e7          	jalr	1628(ra) # 800020fa <sleep>
  while(i < n){
    80004aa6:	07495063          	bge	s2,s4,80004b06 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004aaa:	2204a783          	lw	a5,544(s1)
    80004aae:	dfd5                	beqz	a5,80004a6a <pipewrite+0x44>
    80004ab0:	854e                	mv	a0,s3
    80004ab2:	ffffe097          	auipc	ra,0xffffe
    80004ab6:	8f0080e7          	jalr	-1808(ra) # 800023a2 <killed>
    80004aba:	f945                	bnez	a0,80004a6a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004abc:	2184a783          	lw	a5,536(s1)
    80004ac0:	21c4a703          	lw	a4,540(s1)
    80004ac4:	2007879b          	addw	a5,a5,512
    80004ac8:	fcf704e3          	beq	a4,a5,80004a90 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004acc:	4685                	li	a3,1
    80004ace:	01590633          	add	a2,s2,s5
    80004ad2:	faf40593          	add	a1,s0,-81
    80004ad6:	0509b503          	ld	a0,80(s3)
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	c96080e7          	jalr	-874(ra) # 80001770 <copyin>
    80004ae2:	03650263          	beq	a0,s6,80004b06 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ae6:	21c4a783          	lw	a5,540(s1)
    80004aea:	0017871b          	addw	a4,a5,1
    80004aee:	20e4ae23          	sw	a4,540(s1)
    80004af2:	1ff7f793          	and	a5,a5,511
    80004af6:	97a6                	add	a5,a5,s1
    80004af8:	faf44703          	lbu	a4,-81(s0)
    80004afc:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b00:	2905                	addw	s2,s2,1
    80004b02:	b755                	j	80004aa6 <pipewrite+0x80>
  int i = 0;
    80004b04:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b06:	21848513          	add	a0,s1,536
    80004b0a:	ffffd097          	auipc	ra,0xffffd
    80004b0e:	654080e7          	jalr	1620(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	1e8080e7          	jalr	488(ra) # 80000cfc <release>
  return i;
    80004b1c:	bfa9                	j	80004a76 <pipewrite+0x50>

0000000080004b1e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b1e:	715d                	add	sp,sp,-80
    80004b20:	e486                	sd	ra,72(sp)
    80004b22:	e0a2                	sd	s0,64(sp)
    80004b24:	fc26                	sd	s1,56(sp)
    80004b26:	f84a                	sd	s2,48(sp)
    80004b28:	f44e                	sd	s3,40(sp)
    80004b2a:	f052                	sd	s4,32(sp)
    80004b2c:	ec56                	sd	s5,24(sp)
    80004b2e:	e85a                	sd	s6,16(sp)
    80004b30:	0880                	add	s0,sp,80
    80004b32:	84aa                	mv	s1,a0
    80004b34:	892e                	mv	s2,a1
    80004b36:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b38:	ffffd097          	auipc	ra,0xffffd
    80004b3c:	eec080e7          	jalr	-276(ra) # 80001a24 <myproc>
    80004b40:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	104080e7          	jalr	260(ra) # 80000c48 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b4c:	2184a703          	lw	a4,536(s1)
    80004b50:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b54:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b58:	02f71763          	bne	a4,a5,80004b86 <piperead+0x68>
    80004b5c:	2244a783          	lw	a5,548(s1)
    80004b60:	c39d                	beqz	a5,80004b86 <piperead+0x68>
    if(killed(pr)){
    80004b62:	8552                	mv	a0,s4
    80004b64:	ffffe097          	auipc	ra,0xffffe
    80004b68:	83e080e7          	jalr	-1986(ra) # 800023a2 <killed>
    80004b6c:	e949                	bnez	a0,80004bfe <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b6e:	85a6                	mv	a1,s1
    80004b70:	854e                	mv	a0,s3
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	588080e7          	jalr	1416(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b7a:	2184a703          	lw	a4,536(s1)
    80004b7e:	21c4a783          	lw	a5,540(s1)
    80004b82:	fcf70de3          	beq	a4,a5,80004b5c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b86:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b88:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b8a:	05505463          	blez	s5,80004bd2 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b8e:	2184a783          	lw	a5,536(s1)
    80004b92:	21c4a703          	lw	a4,540(s1)
    80004b96:	02f70e63          	beq	a4,a5,80004bd2 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b9a:	0017871b          	addw	a4,a5,1
    80004b9e:	20e4ac23          	sw	a4,536(s1)
    80004ba2:	1ff7f793          	and	a5,a5,511
    80004ba6:	97a6                	add	a5,a5,s1
    80004ba8:	0187c783          	lbu	a5,24(a5)
    80004bac:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bb0:	4685                	li	a3,1
    80004bb2:	fbf40613          	add	a2,s0,-65
    80004bb6:	85ca                	mv	a1,s2
    80004bb8:	050a3503          	ld	a0,80(s4)
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	b28080e7          	jalr	-1240(ra) # 800016e4 <copyout>
    80004bc4:	01650763          	beq	a0,s6,80004bd2 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc8:	2985                	addw	s3,s3,1
    80004bca:	0905                	add	s2,s2,1
    80004bcc:	fd3a91e3          	bne	s5,s3,80004b8e <piperead+0x70>
    80004bd0:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bd2:	21c48513          	add	a0,s1,540
    80004bd6:	ffffd097          	auipc	ra,0xffffd
    80004bda:	588080e7          	jalr	1416(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004bde:	8526                	mv	a0,s1
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	11c080e7          	jalr	284(ra) # 80000cfc <release>
  return i;
}
    80004be8:	854e                	mv	a0,s3
    80004bea:	60a6                	ld	ra,72(sp)
    80004bec:	6406                	ld	s0,64(sp)
    80004bee:	74e2                	ld	s1,56(sp)
    80004bf0:	7942                	ld	s2,48(sp)
    80004bf2:	79a2                	ld	s3,40(sp)
    80004bf4:	7a02                	ld	s4,32(sp)
    80004bf6:	6ae2                	ld	s5,24(sp)
    80004bf8:	6b42                	ld	s6,16(sp)
    80004bfa:	6161                	add	sp,sp,80
    80004bfc:	8082                	ret
      release(&pi->lock);
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	0fc080e7          	jalr	252(ra) # 80000cfc <release>
      return -1;
    80004c08:	59fd                	li	s3,-1
    80004c0a:	bff9                	j	80004be8 <piperead+0xca>

0000000080004c0c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c0c:	1141                	add	sp,sp,-16
    80004c0e:	e422                	sd	s0,8(sp)
    80004c10:	0800                	add	s0,sp,16
    80004c12:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c14:	8905                	and	a0,a0,1
    80004c16:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c18:	8b89                	and	a5,a5,2
    80004c1a:	c399                	beqz	a5,80004c20 <flags2perm+0x14>
      perm |= PTE_W;
    80004c1c:	00456513          	or	a0,a0,4
    return perm;
}
    80004c20:	6422                	ld	s0,8(sp)
    80004c22:	0141                	add	sp,sp,16
    80004c24:	8082                	ret

0000000080004c26 <exec>:

int
exec(char *path, char **argv)
{
    80004c26:	df010113          	add	sp,sp,-528
    80004c2a:	20113423          	sd	ra,520(sp)
    80004c2e:	20813023          	sd	s0,512(sp)
    80004c32:	ffa6                	sd	s1,504(sp)
    80004c34:	fbca                	sd	s2,496(sp)
    80004c36:	f7ce                	sd	s3,488(sp)
    80004c38:	f3d2                	sd	s4,480(sp)
    80004c3a:	efd6                	sd	s5,472(sp)
    80004c3c:	ebda                	sd	s6,464(sp)
    80004c3e:	e7de                	sd	s7,456(sp)
    80004c40:	e3e2                	sd	s8,448(sp)
    80004c42:	ff66                	sd	s9,440(sp)
    80004c44:	fb6a                	sd	s10,432(sp)
    80004c46:	f76e                	sd	s11,424(sp)
    80004c48:	0c00                	add	s0,sp,528
    80004c4a:	892a                	mv	s2,a0
    80004c4c:	dea43c23          	sd	a0,-520(s0)
    80004c50:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c54:	ffffd097          	auipc	ra,0xffffd
    80004c58:	dd0080e7          	jalr	-560(ra) # 80001a24 <myproc>
    80004c5c:	84aa                	mv	s1,a0

  begin_op();
    80004c5e:	fffff097          	auipc	ra,0xfffff
    80004c62:	48e080e7          	jalr	1166(ra) # 800040ec <begin_op>

  if((ip = namei(path)) == 0){
    80004c66:	854a                	mv	a0,s2
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	284080e7          	jalr	644(ra) # 80003eec <namei>
    80004c70:	c92d                	beqz	a0,80004ce2 <exec+0xbc>
    80004c72:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c74:	fffff097          	auipc	ra,0xfffff
    80004c78:	ad2080e7          	jalr	-1326(ra) # 80003746 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c7c:	04000713          	li	a4,64
    80004c80:	4681                	li	a3,0
    80004c82:	e5040613          	add	a2,s0,-432
    80004c86:	4581                	li	a1,0
    80004c88:	8552                	mv	a0,s4
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	d70080e7          	jalr	-656(ra) # 800039fa <readi>
    80004c92:	04000793          	li	a5,64
    80004c96:	00f51a63          	bne	a0,a5,80004caa <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c9a:	e5042703          	lw	a4,-432(s0)
    80004c9e:	464c47b7          	lui	a5,0x464c4
    80004ca2:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ca6:	04f70463          	beq	a4,a5,80004cee <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004caa:	8552                	mv	a0,s4
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	cfc080e7          	jalr	-772(ra) # 800039a8 <iunlockput>
    end_op();
    80004cb4:	fffff097          	auipc	ra,0xfffff
    80004cb8:	4b2080e7          	jalr	1202(ra) # 80004166 <end_op>
  }
  return -1;
    80004cbc:	557d                	li	a0,-1
}
    80004cbe:	20813083          	ld	ra,520(sp)
    80004cc2:	20013403          	ld	s0,512(sp)
    80004cc6:	74fe                	ld	s1,504(sp)
    80004cc8:	795e                	ld	s2,496(sp)
    80004cca:	79be                	ld	s3,488(sp)
    80004ccc:	7a1e                	ld	s4,480(sp)
    80004cce:	6afe                	ld	s5,472(sp)
    80004cd0:	6b5e                	ld	s6,464(sp)
    80004cd2:	6bbe                	ld	s7,456(sp)
    80004cd4:	6c1e                	ld	s8,448(sp)
    80004cd6:	7cfa                	ld	s9,440(sp)
    80004cd8:	7d5a                	ld	s10,432(sp)
    80004cda:	7dba                	ld	s11,424(sp)
    80004cdc:	21010113          	add	sp,sp,528
    80004ce0:	8082                	ret
    end_op();
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	484080e7          	jalr	1156(ra) # 80004166 <end_op>
    return -1;
    80004cea:	557d                	li	a0,-1
    80004cec:	bfc9                	j	80004cbe <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	df8080e7          	jalr	-520(ra) # 80001ae8 <proc_pagetable>
    80004cf8:	8b2a                	mv	s6,a0
    80004cfa:	d945                	beqz	a0,80004caa <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cfc:	e7042d03          	lw	s10,-400(s0)
    80004d00:	e8845783          	lhu	a5,-376(s0)
    80004d04:	10078463          	beqz	a5,80004e0c <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d08:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d0a:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004d0c:	6c85                	lui	s9,0x1
    80004d0e:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d12:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004d16:	6a85                	lui	s5,0x1
    80004d18:	a0b5                	j	80004d84 <exec+0x15e>
      panic("loadseg: address should exist");
    80004d1a:	00004517          	auipc	a0,0x4
    80004d1e:	9fe50513          	add	a0,a0,-1538 # 80008718 <syscalls+0x280>
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	81e080e7          	jalr	-2018(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
    80004d2a:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d2c:	8726                	mv	a4,s1
    80004d2e:	012c06bb          	addw	a3,s8,s2
    80004d32:	4581                	li	a1,0
    80004d34:	8552                	mv	a0,s4
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	cc4080e7          	jalr	-828(ra) # 800039fa <readi>
    80004d3e:	2501                	sext.w	a0,a0
    80004d40:	2aa49963          	bne	s1,a0,80004ff2 <exec+0x3cc>
  for(i = 0; i < sz; i += PGSIZE){
    80004d44:	012a893b          	addw	s2,s5,s2
    80004d48:	03397563          	bgeu	s2,s3,80004d72 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004d4c:	02091593          	sll	a1,s2,0x20
    80004d50:	9181                	srl	a1,a1,0x20
    80004d52:	95de                	add	a1,a1,s7
    80004d54:	855a                	mv	a0,s6
    80004d56:	ffffc097          	auipc	ra,0xffffc
    80004d5a:	37e080e7          	jalr	894(ra) # 800010d4 <walkaddr>
    80004d5e:	862a                	mv	a2,a0
    if(pa == 0)
    80004d60:	dd4d                	beqz	a0,80004d1a <exec+0xf4>
    if(sz - i < PGSIZE)
    80004d62:	412984bb          	subw	s1,s3,s2
    80004d66:	0004879b          	sext.w	a5,s1
    80004d6a:	fcfcf0e3          	bgeu	s9,a5,80004d2a <exec+0x104>
    80004d6e:	84d6                	mv	s1,s5
    80004d70:	bf6d                	j	80004d2a <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d72:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d76:	2d85                	addw	s11,s11,1
    80004d78:	038d0d1b          	addw	s10,s10,56
    80004d7c:	e8845783          	lhu	a5,-376(s0)
    80004d80:	08fdd763          	bge	s11,a5,80004e0e <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d84:	2d01                	sext.w	s10,s10
    80004d86:	03800713          	li	a4,56
    80004d8a:	86ea                	mv	a3,s10
    80004d8c:	e1840613          	add	a2,s0,-488
    80004d90:	4581                	li	a1,0
    80004d92:	8552                	mv	a0,s4
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	c66080e7          	jalr	-922(ra) # 800039fa <readi>
    80004d9c:	03800793          	li	a5,56
    80004da0:	24f51763          	bne	a0,a5,80004fee <exec+0x3c8>
    if(ph.type != ELF_PROG_LOAD)
    80004da4:	e1842783          	lw	a5,-488(s0)
    80004da8:	4705                	li	a4,1
    80004daa:	fce796e3          	bne	a5,a4,80004d76 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004dae:	e4043483          	ld	s1,-448(s0)
    80004db2:	e3843783          	ld	a5,-456(s0)
    80004db6:	24f4e963          	bltu	s1,a5,80005008 <exec+0x3e2>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004dba:	e2843783          	ld	a5,-472(s0)
    80004dbe:	94be                	add	s1,s1,a5
    80004dc0:	24f4e763          	bltu	s1,a5,8000500e <exec+0x3e8>
    if(ph.vaddr % PGSIZE != 0)
    80004dc4:	df043703          	ld	a4,-528(s0)
    80004dc8:	8ff9                	and	a5,a5,a4
    80004dca:	24079563          	bnez	a5,80005014 <exec+0x3ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004dce:	e1c42503          	lw	a0,-484(s0)
    80004dd2:	00000097          	auipc	ra,0x0
    80004dd6:	e3a080e7          	jalr	-454(ra) # 80004c0c <flags2perm>
    80004dda:	86aa                	mv	a3,a0
    80004ddc:	8626                	mv	a2,s1
    80004dde:	85ca                	mv	a1,s2
    80004de0:	855a                	mv	a0,s6
    80004de2:	ffffc097          	auipc	ra,0xffffc
    80004de6:	6a6080e7          	jalr	1702(ra) # 80001488 <uvmalloc>
    80004dea:	e0a43423          	sd	a0,-504(s0)
    80004dee:	22050663          	beqz	a0,8000501a <exec+0x3f4>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004df2:	e2843b83          	ld	s7,-472(s0)
    80004df6:	e2042c03          	lw	s8,-480(s0)
    80004dfa:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004dfe:	00098463          	beqz	s3,80004e06 <exec+0x1e0>
    80004e02:	4901                	li	s2,0
    80004e04:	b7a1                	j	80004d4c <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e06:	e0843903          	ld	s2,-504(s0)
    80004e0a:	b7b5                	j	80004d76 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e0c:	4901                	li	s2,0
  iunlockput(ip);
    80004e0e:	8552                	mv	a0,s4
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	b98080e7          	jalr	-1128(ra) # 800039a8 <iunlockput>
  end_op();
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	34e080e7          	jalr	846(ra) # 80004166 <end_op>
  p = myproc();
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	c04080e7          	jalr	-1020(ra) # 80001a24 <myproc>
    80004e28:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e2a:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004e2e:	6985                	lui	s3,0x1
    80004e30:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004e32:	99ca                	add	s3,s3,s2
    80004e34:	77fd                	lui	a5,0xfffff
    80004e36:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e3a:	4691                	li	a3,4
    80004e3c:	6609                	lui	a2,0x2
    80004e3e:	964e                	add	a2,a2,s3
    80004e40:	85ce                	mv	a1,s3
    80004e42:	855a                	mv	a0,s6
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	644080e7          	jalr	1604(ra) # 80001488 <uvmalloc>
    80004e4c:	892a                	mv	s2,a0
    80004e4e:	e0a43423          	sd	a0,-504(s0)
    80004e52:	e509                	bnez	a0,80004e5c <exec+0x236>
  if(pagetable)
    80004e54:	e1343423          	sd	s3,-504(s0)
    80004e58:	4a01                	li	s4,0
    80004e5a:	aa61                	j	80004ff2 <exec+0x3cc>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e5c:	75f9                	lui	a1,0xffffe
    80004e5e:	95aa                	add	a1,a1,a0
    80004e60:	855a                	mv	a0,s6
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	850080e7          	jalr	-1968(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e6a:	7bfd                	lui	s7,0xfffff
    80004e6c:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e6e:	e0043783          	ld	a5,-512(s0)
    80004e72:	6388                	ld	a0,0(a5)
    80004e74:	c52d                	beqz	a0,80004ede <exec+0x2b8>
    80004e76:	e9040993          	add	s3,s0,-368
    80004e7a:	f9040c13          	add	s8,s0,-112
    80004e7e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	03e080e7          	jalr	62(ra) # 80000ebe <strlen>
    80004e88:	0015079b          	addw	a5,a0,1
    80004e8c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e90:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80004e94:	19796663          	bltu	s2,s7,80005020 <exec+0x3fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e98:	e0043d03          	ld	s10,-512(s0)
    80004e9c:	000d3a03          	ld	s4,0(s10)
    80004ea0:	8552                	mv	a0,s4
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	01c080e7          	jalr	28(ra) # 80000ebe <strlen>
    80004eaa:	0015069b          	addw	a3,a0,1
    80004eae:	8652                	mv	a2,s4
    80004eb0:	85ca                	mv	a1,s2
    80004eb2:	855a                	mv	a0,s6
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	830080e7          	jalr	-2000(ra) # 800016e4 <copyout>
    80004ebc:	16054463          	bltz	a0,80005024 <exec+0x3fe>
    ustack[argc] = sp;
    80004ec0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec4:	0485                	add	s1,s1,1
    80004ec6:	008d0793          	add	a5,s10,8
    80004eca:	e0f43023          	sd	a5,-512(s0)
    80004ece:	008d3503          	ld	a0,8(s10)
    80004ed2:	c909                	beqz	a0,80004ee4 <exec+0x2be>
    if(argc >= MAXARG)
    80004ed4:	09a1                	add	s3,s3,8
    80004ed6:	fb8995e3          	bne	s3,s8,80004e80 <exec+0x25a>
  ip = 0;
    80004eda:	4a01                	li	s4,0
    80004edc:	aa19                	j	80004ff2 <exec+0x3cc>
  sp = sz;
    80004ede:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004ee2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee4:	00349793          	sll	a5,s1,0x3
    80004ee8:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdcc00>
    80004eec:	97a2                	add	a5,a5,s0
    80004eee:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ef2:	00148693          	add	a3,s1,1
    80004ef6:	068e                	sll	a3,a3,0x3
    80004ef8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004efc:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80004f00:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004f04:	f57968e3          	bltu	s2,s7,80004e54 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f08:	e9040613          	add	a2,s0,-368
    80004f0c:	85ca                	mv	a1,s2
    80004f0e:	855a                	mv	a0,s6
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	7d4080e7          	jalr	2004(ra) # 800016e4 <copyout>
    80004f18:	10054863          	bltz	a0,80005028 <exec+0x402>
  p->trapframe->a1 = sp;
    80004f1c:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004f20:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f24:	df843783          	ld	a5,-520(s0)
    80004f28:	0007c703          	lbu	a4,0(a5)
    80004f2c:	cf11                	beqz	a4,80004f48 <exec+0x322>
    80004f2e:	0785                	add	a5,a5,1
    if(*s == '/')
    80004f30:	02f00693          	li	a3,47
    80004f34:	a039                	j	80004f42 <exec+0x31c>
      last = s+1;
    80004f36:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f3a:	0785                	add	a5,a5,1
    80004f3c:	fff7c703          	lbu	a4,-1(a5)
    80004f40:	c701                	beqz	a4,80004f48 <exec+0x322>
    if(*s == '/')
    80004f42:	fed71ce3          	bne	a4,a3,80004f3a <exec+0x314>
    80004f46:	bfc5                	j	80004f36 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f48:	158a8993          	add	s3,s5,344
    80004f4c:	4641                	li	a2,16
    80004f4e:	df843583          	ld	a1,-520(s0)
    80004f52:	854e                	mv	a0,s3
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	f38080e7          	jalr	-200(ra) # 80000e8c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f5c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f60:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f64:	e0843783          	ld	a5,-504(s0)
    80004f68:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f6c:	058ab783          	ld	a5,88(s5)
    80004f70:	e6843703          	ld	a4,-408(s0)
    80004f74:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f76:	058ab783          	ld	a5,88(s5)
    80004f7a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f7e:	85e6                	mv	a1,s9
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	c04080e7          	jalr	-1020(ra) # 80001b84 <proc_freepagetable>
  if (strncmp(p->name, "vm-", 3) == 0) {
    80004f88:	460d                	li	a2,3
    80004f8a:	00003597          	auipc	a1,0x3
    80004f8e:	27658593          	add	a1,a1,630 # 80008200 <digits+0x1c0>
    80004f92:	854e                	mv	a0,s3
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	e80080e7          	jalr	-384(ra) # 80000e14 <strncmp>
    80004f9c:	c501                	beqz	a0,80004fa4 <exec+0x37e>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f9e:	0004851b          	sext.w	a0,s1
    80004fa2:	bb31                	j	80004cbe <exec+0x98>
    if((sz1 = uvmalloc(pagetable, memaddr, memaddr + 1024*PGSIZE, PTE_W)) == 0) {
    80004fa4:	4691                	li	a3,4
    80004fa6:	20100613          	li	a2,513
    80004faa:	065a                	sll	a2,a2,0x16
    80004fac:	4585                	li	a1,1
    80004fae:	05fe                	sll	a1,a1,0x1f
    80004fb0:	855a                	mv	a0,s6
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	4d6080e7          	jalr	1238(ra) # 80001488 <uvmalloc>
    80004fba:	cd19                	beqz	a0,80004fd8 <exec+0x3b2>
    printf("Created a VM process and allocated memory region (%p - %p).\n", memaddr, memaddr + 1024*PGSIZE);
    80004fbc:	20100613          	li	a2,513
    80004fc0:	065a                	sll	a2,a2,0x16
    80004fc2:	4585                	li	a1,1
    80004fc4:	05fe                	sll	a1,a1,0x1f
    80004fc6:	00003517          	auipc	a0,0x3
    80004fca:	7aa50513          	add	a0,a0,1962 # 80008770 <syscalls+0x2d8>
    80004fce:	ffffb097          	auipc	ra,0xffffb
    80004fd2:	5bc080e7          	jalr	1468(ra) # 8000058a <printf>
    80004fd6:	b7e1                	j	80004f9e <exec+0x378>
      printf("Error: could not allocate memory at 0x80000000 for VM.\n");
    80004fd8:	00003517          	auipc	a0,0x3
    80004fdc:	76050513          	add	a0,a0,1888 # 80008738 <syscalls+0x2a0>
    80004fe0:	ffffb097          	auipc	ra,0xffffb
    80004fe4:	5aa080e7          	jalr	1450(ra) # 8000058a <printf>
  sz = sz1;
    80004fe8:	e0843983          	ld	s3,-504(s0)
      goto bad;
    80004fec:	b5a5                	j	80004e54 <exec+0x22e>
    80004fee:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004ff2:	e0843583          	ld	a1,-504(s0)
    80004ff6:	855a                	mv	a0,s6
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	b8c080e7          	jalr	-1140(ra) # 80001b84 <proc_freepagetable>
  return -1;
    80005000:	557d                	li	a0,-1
  if(ip){
    80005002:	ca0a0ee3          	beqz	s4,80004cbe <exec+0x98>
    80005006:	b155                	j	80004caa <exec+0x84>
    80005008:	e1243423          	sd	s2,-504(s0)
    8000500c:	b7dd                	j	80004ff2 <exec+0x3cc>
    8000500e:	e1243423          	sd	s2,-504(s0)
    80005012:	b7c5                	j	80004ff2 <exec+0x3cc>
    80005014:	e1243423          	sd	s2,-504(s0)
    80005018:	bfe9                	j	80004ff2 <exec+0x3cc>
    8000501a:	e1243423          	sd	s2,-504(s0)
    8000501e:	bfd1                	j	80004ff2 <exec+0x3cc>
  ip = 0;
    80005020:	4a01                	li	s4,0
    80005022:	bfc1                	j	80004ff2 <exec+0x3cc>
    80005024:	4a01                	li	s4,0
  if(pagetable)
    80005026:	b7f1                	j	80004ff2 <exec+0x3cc>
  sz = sz1;
    80005028:	e0843983          	ld	s3,-504(s0)
    8000502c:	b525                	j	80004e54 <exec+0x22e>

000000008000502e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000502e:	7179                	add	sp,sp,-48
    80005030:	f406                	sd	ra,40(sp)
    80005032:	f022                	sd	s0,32(sp)
    80005034:	ec26                	sd	s1,24(sp)
    80005036:	e84a                	sd	s2,16(sp)
    80005038:	1800                	add	s0,sp,48
    8000503a:	892e                	mv	s2,a1
    8000503c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000503e:	fdc40593          	add	a1,s0,-36
    80005042:	ffffe097          	auipc	ra,0xffffe
    80005046:	ba2080e7          	jalr	-1118(ra) # 80002be4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000504a:	fdc42703          	lw	a4,-36(s0)
    8000504e:	47bd                	li	a5,15
    80005050:	02e7eb63          	bltu	a5,a4,80005086 <argfd+0x58>
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	9d0080e7          	jalr	-1584(ra) # 80001a24 <myproc>
    8000505c:	fdc42703          	lw	a4,-36(s0)
    80005060:	01a70793          	add	a5,a4,26
    80005064:	078e                	sll	a5,a5,0x3
    80005066:	953e                	add	a0,a0,a5
    80005068:	611c                	ld	a5,0(a0)
    8000506a:	c385                	beqz	a5,8000508a <argfd+0x5c>
    return -1;
  if(pfd)
    8000506c:	00090463          	beqz	s2,80005074 <argfd+0x46>
    *pfd = fd;
    80005070:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005074:	4501                	li	a0,0
  if(pf)
    80005076:	c091                	beqz	s1,8000507a <argfd+0x4c>
    *pf = f;
    80005078:	e09c                	sd	a5,0(s1)
}
    8000507a:	70a2                	ld	ra,40(sp)
    8000507c:	7402                	ld	s0,32(sp)
    8000507e:	64e2                	ld	s1,24(sp)
    80005080:	6942                	ld	s2,16(sp)
    80005082:	6145                	add	sp,sp,48
    80005084:	8082                	ret
    return -1;
    80005086:	557d                	li	a0,-1
    80005088:	bfcd                	j	8000507a <argfd+0x4c>
    8000508a:	557d                	li	a0,-1
    8000508c:	b7fd                	j	8000507a <argfd+0x4c>

000000008000508e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000508e:	1101                	add	sp,sp,-32
    80005090:	ec06                	sd	ra,24(sp)
    80005092:	e822                	sd	s0,16(sp)
    80005094:	e426                	sd	s1,8(sp)
    80005096:	1000                	add	s0,sp,32
    80005098:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	98a080e7          	jalr	-1654(ra) # 80001a24 <myproc>
    800050a2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050a4:	0d050793          	add	a5,a0,208
    800050a8:	4501                	li	a0,0
    800050aa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ac:	6398                	ld	a4,0(a5)
    800050ae:	cb19                	beqz	a4,800050c4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050b0:	2505                	addw	a0,a0,1
    800050b2:	07a1                	add	a5,a5,8
    800050b4:	fed51ce3          	bne	a0,a3,800050ac <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050b8:	557d                	li	a0,-1
}
    800050ba:	60e2                	ld	ra,24(sp)
    800050bc:	6442                	ld	s0,16(sp)
    800050be:	64a2                	ld	s1,8(sp)
    800050c0:	6105                	add	sp,sp,32
    800050c2:	8082                	ret
      p->ofile[fd] = f;
    800050c4:	01a50793          	add	a5,a0,26
    800050c8:	078e                	sll	a5,a5,0x3
    800050ca:	963e                	add	a2,a2,a5
    800050cc:	e204                	sd	s1,0(a2)
      return fd;
    800050ce:	b7f5                	j	800050ba <fdalloc+0x2c>

00000000800050d0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050d0:	715d                	add	sp,sp,-80
    800050d2:	e486                	sd	ra,72(sp)
    800050d4:	e0a2                	sd	s0,64(sp)
    800050d6:	fc26                	sd	s1,56(sp)
    800050d8:	f84a                	sd	s2,48(sp)
    800050da:	f44e                	sd	s3,40(sp)
    800050dc:	f052                	sd	s4,32(sp)
    800050de:	ec56                	sd	s5,24(sp)
    800050e0:	e85a                	sd	s6,16(sp)
    800050e2:	0880                	add	s0,sp,80
    800050e4:	8b2e                	mv	s6,a1
    800050e6:	89b2                	mv	s3,a2
    800050e8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050ea:	fb040593          	add	a1,s0,-80
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	e1c080e7          	jalr	-484(ra) # 80003f0a <nameiparent>
    800050f6:	84aa                	mv	s1,a0
    800050f8:	14050b63          	beqz	a0,8000524e <create+0x17e>
    return 0;

  ilock(dp);
    800050fc:	ffffe097          	auipc	ra,0xffffe
    80005100:	64a080e7          	jalr	1610(ra) # 80003746 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005104:	4601                	li	a2,0
    80005106:	fb040593          	add	a1,s0,-80
    8000510a:	8526                	mv	a0,s1
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	b1e080e7          	jalr	-1250(ra) # 80003c2a <dirlookup>
    80005114:	8aaa                	mv	s5,a0
    80005116:	c921                	beqz	a0,80005166 <create+0x96>
    iunlockput(dp);
    80005118:	8526                	mv	a0,s1
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	88e080e7          	jalr	-1906(ra) # 800039a8 <iunlockput>
    ilock(ip);
    80005122:	8556                	mv	a0,s5
    80005124:	ffffe097          	auipc	ra,0xffffe
    80005128:	622080e7          	jalr	1570(ra) # 80003746 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000512c:	4789                	li	a5,2
    8000512e:	02fb1563          	bne	s6,a5,80005158 <create+0x88>
    80005132:	044ad783          	lhu	a5,68(s5)
    80005136:	37f9                	addw	a5,a5,-2
    80005138:	17c2                	sll	a5,a5,0x30
    8000513a:	93c1                	srl	a5,a5,0x30
    8000513c:	4705                	li	a4,1
    8000513e:	00f76d63          	bltu	a4,a5,80005158 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005142:	8556                	mv	a0,s5
    80005144:	60a6                	ld	ra,72(sp)
    80005146:	6406                	ld	s0,64(sp)
    80005148:	74e2                	ld	s1,56(sp)
    8000514a:	7942                	ld	s2,48(sp)
    8000514c:	79a2                	ld	s3,40(sp)
    8000514e:	7a02                	ld	s4,32(sp)
    80005150:	6ae2                	ld	s5,24(sp)
    80005152:	6b42                	ld	s6,16(sp)
    80005154:	6161                	add	sp,sp,80
    80005156:	8082                	ret
    iunlockput(ip);
    80005158:	8556                	mv	a0,s5
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	84e080e7          	jalr	-1970(ra) # 800039a8 <iunlockput>
    return 0;
    80005162:	4a81                	li	s5,0
    80005164:	bff9                	j	80005142 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005166:	85da                	mv	a1,s6
    80005168:	4088                	lw	a0,0(s1)
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	444080e7          	jalr	1092(ra) # 800035ae <ialloc>
    80005172:	8a2a                	mv	s4,a0
    80005174:	c529                	beqz	a0,800051be <create+0xee>
  ilock(ip);
    80005176:	ffffe097          	auipc	ra,0xffffe
    8000517a:	5d0080e7          	jalr	1488(ra) # 80003746 <ilock>
  ip->major = major;
    8000517e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005182:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005186:	4905                	li	s2,1
    80005188:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000518c:	8552                	mv	a0,s4
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	4ec080e7          	jalr	1260(ra) # 8000367a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005196:	032b0b63          	beq	s6,s2,800051cc <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000519a:	004a2603          	lw	a2,4(s4)
    8000519e:	fb040593          	add	a1,s0,-80
    800051a2:	8526                	mv	a0,s1
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	c96080e7          	jalr	-874(ra) # 80003e3a <dirlink>
    800051ac:	06054f63          	bltz	a0,8000522a <create+0x15a>
  iunlockput(dp);
    800051b0:	8526                	mv	a0,s1
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	7f6080e7          	jalr	2038(ra) # 800039a8 <iunlockput>
  return ip;
    800051ba:	8ad2                	mv	s5,s4
    800051bc:	b759                	j	80005142 <create+0x72>
    iunlockput(dp);
    800051be:	8526                	mv	a0,s1
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	7e8080e7          	jalr	2024(ra) # 800039a8 <iunlockput>
    return 0;
    800051c8:	8ad2                	mv	s5,s4
    800051ca:	bfa5                	j	80005142 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051cc:	004a2603          	lw	a2,4(s4)
    800051d0:	00003597          	auipc	a1,0x3
    800051d4:	5e058593          	add	a1,a1,1504 # 800087b0 <syscalls+0x318>
    800051d8:	8552                	mv	a0,s4
    800051da:	fffff097          	auipc	ra,0xfffff
    800051de:	c60080e7          	jalr	-928(ra) # 80003e3a <dirlink>
    800051e2:	04054463          	bltz	a0,8000522a <create+0x15a>
    800051e6:	40d0                	lw	a2,4(s1)
    800051e8:	00003597          	auipc	a1,0x3
    800051ec:	5d058593          	add	a1,a1,1488 # 800087b8 <syscalls+0x320>
    800051f0:	8552                	mv	a0,s4
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	c48080e7          	jalr	-952(ra) # 80003e3a <dirlink>
    800051fa:	02054863          	bltz	a0,8000522a <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800051fe:	004a2603          	lw	a2,4(s4)
    80005202:	fb040593          	add	a1,s0,-80
    80005206:	8526                	mv	a0,s1
    80005208:	fffff097          	auipc	ra,0xfffff
    8000520c:	c32080e7          	jalr	-974(ra) # 80003e3a <dirlink>
    80005210:	00054d63          	bltz	a0,8000522a <create+0x15a>
    dp->nlink++;  // for ".."
    80005214:	04a4d783          	lhu	a5,74(s1)
    80005218:	2785                	addw	a5,a5,1
    8000521a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffe097          	auipc	ra,0xffffe
    80005224:	45a080e7          	jalr	1114(ra) # 8000367a <iupdate>
    80005228:	b761                	j	800051b0 <create+0xe0>
  ip->nlink = 0;
    8000522a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000522e:	8552                	mv	a0,s4
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	44a080e7          	jalr	1098(ra) # 8000367a <iupdate>
  iunlockput(ip);
    80005238:	8552                	mv	a0,s4
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	76e080e7          	jalr	1902(ra) # 800039a8 <iunlockput>
  iunlockput(dp);
    80005242:	8526                	mv	a0,s1
    80005244:	ffffe097          	auipc	ra,0xffffe
    80005248:	764080e7          	jalr	1892(ra) # 800039a8 <iunlockput>
  return 0;
    8000524c:	bddd                	j	80005142 <create+0x72>
    return 0;
    8000524e:	8aaa                	mv	s5,a0
    80005250:	bdcd                	j	80005142 <create+0x72>

0000000080005252 <sys_dup>:
{
    80005252:	7179                	add	sp,sp,-48
    80005254:	f406                	sd	ra,40(sp)
    80005256:	f022                	sd	s0,32(sp)
    80005258:	ec26                	sd	s1,24(sp)
    8000525a:	e84a                	sd	s2,16(sp)
    8000525c:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000525e:	fd840613          	add	a2,s0,-40
    80005262:	4581                	li	a1,0
    80005264:	4501                	li	a0,0
    80005266:	00000097          	auipc	ra,0x0
    8000526a:	dc8080e7          	jalr	-568(ra) # 8000502e <argfd>
    return -1;
    8000526e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005270:	02054363          	bltz	a0,80005296 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005274:	fd843903          	ld	s2,-40(s0)
    80005278:	854a                	mv	a0,s2
    8000527a:	00000097          	auipc	ra,0x0
    8000527e:	e14080e7          	jalr	-492(ra) # 8000508e <fdalloc>
    80005282:	84aa                	mv	s1,a0
    return -1;
    80005284:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005286:	00054863          	bltz	a0,80005296 <sys_dup+0x44>
  filedup(f);
    8000528a:	854a                	mv	a0,s2
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	2d2080e7          	jalr	722(ra) # 8000455e <filedup>
  return fd;
    80005294:	87a6                	mv	a5,s1
}
    80005296:	853e                	mv	a0,a5
    80005298:	70a2                	ld	ra,40(sp)
    8000529a:	7402                	ld	s0,32(sp)
    8000529c:	64e2                	ld	s1,24(sp)
    8000529e:	6942                	ld	s2,16(sp)
    800052a0:	6145                	add	sp,sp,48
    800052a2:	8082                	ret

00000000800052a4 <sys_read>:
{
    800052a4:	7179                	add	sp,sp,-48
    800052a6:	f406                	sd	ra,40(sp)
    800052a8:	f022                	sd	s0,32(sp)
    800052aa:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800052ac:	fd840593          	add	a1,s0,-40
    800052b0:	4505                	li	a0,1
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	952080e7          	jalr	-1710(ra) # 80002c04 <argaddr>
  argint(2, &n);
    800052ba:	fe440593          	add	a1,s0,-28
    800052be:	4509                	li	a0,2
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	924080e7          	jalr	-1756(ra) # 80002be4 <argint>
  if(argfd(0, 0, &f) < 0)
    800052c8:	fe840613          	add	a2,s0,-24
    800052cc:	4581                	li	a1,0
    800052ce:	4501                	li	a0,0
    800052d0:	00000097          	auipc	ra,0x0
    800052d4:	d5e080e7          	jalr	-674(ra) # 8000502e <argfd>
    800052d8:	87aa                	mv	a5,a0
    return -1;
    800052da:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052dc:	0007cc63          	bltz	a5,800052f4 <sys_read+0x50>
  return fileread(f, p, n);
    800052e0:	fe442603          	lw	a2,-28(s0)
    800052e4:	fd843583          	ld	a1,-40(s0)
    800052e8:	fe843503          	ld	a0,-24(s0)
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	3fe080e7          	jalr	1022(ra) # 800046ea <fileread>
}
    800052f4:	70a2                	ld	ra,40(sp)
    800052f6:	7402                	ld	s0,32(sp)
    800052f8:	6145                	add	sp,sp,48
    800052fa:	8082                	ret

00000000800052fc <sys_write>:
{
    800052fc:	7179                	add	sp,sp,-48
    800052fe:	f406                	sd	ra,40(sp)
    80005300:	f022                	sd	s0,32(sp)
    80005302:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005304:	fd840593          	add	a1,s0,-40
    80005308:	4505                	li	a0,1
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	8fa080e7          	jalr	-1798(ra) # 80002c04 <argaddr>
  argint(2, &n);
    80005312:	fe440593          	add	a1,s0,-28
    80005316:	4509                	li	a0,2
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	8cc080e7          	jalr	-1844(ra) # 80002be4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005320:	fe840613          	add	a2,s0,-24
    80005324:	4581                	li	a1,0
    80005326:	4501                	li	a0,0
    80005328:	00000097          	auipc	ra,0x0
    8000532c:	d06080e7          	jalr	-762(ra) # 8000502e <argfd>
    80005330:	87aa                	mv	a5,a0
    return -1;
    80005332:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005334:	0007cc63          	bltz	a5,8000534c <sys_write+0x50>
  return filewrite(f, p, n);
    80005338:	fe442603          	lw	a2,-28(s0)
    8000533c:	fd843583          	ld	a1,-40(s0)
    80005340:	fe843503          	ld	a0,-24(s0)
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	468080e7          	jalr	1128(ra) # 800047ac <filewrite>
}
    8000534c:	70a2                	ld	ra,40(sp)
    8000534e:	7402                	ld	s0,32(sp)
    80005350:	6145                	add	sp,sp,48
    80005352:	8082                	ret

0000000080005354 <sys_close>:
{
    80005354:	1101                	add	sp,sp,-32
    80005356:	ec06                	sd	ra,24(sp)
    80005358:	e822                	sd	s0,16(sp)
    8000535a:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000535c:	fe040613          	add	a2,s0,-32
    80005360:	fec40593          	add	a1,s0,-20
    80005364:	4501                	li	a0,0
    80005366:	00000097          	auipc	ra,0x0
    8000536a:	cc8080e7          	jalr	-824(ra) # 8000502e <argfd>
    return -1;
    8000536e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005370:	02054463          	bltz	a0,80005398 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	6b0080e7          	jalr	1712(ra) # 80001a24 <myproc>
    8000537c:	fec42783          	lw	a5,-20(s0)
    80005380:	07e9                	add	a5,a5,26
    80005382:	078e                	sll	a5,a5,0x3
    80005384:	953e                	add	a0,a0,a5
    80005386:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000538a:	fe043503          	ld	a0,-32(s0)
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	222080e7          	jalr	546(ra) # 800045b0 <fileclose>
  return 0;
    80005396:	4781                	li	a5,0
}
    80005398:	853e                	mv	a0,a5
    8000539a:	60e2                	ld	ra,24(sp)
    8000539c:	6442                	ld	s0,16(sp)
    8000539e:	6105                	add	sp,sp,32
    800053a0:	8082                	ret

00000000800053a2 <sys_fstat>:
{
    800053a2:	1101                	add	sp,sp,-32
    800053a4:	ec06                	sd	ra,24(sp)
    800053a6:	e822                	sd	s0,16(sp)
    800053a8:	1000                	add	s0,sp,32
  argaddr(1, &st);
    800053aa:	fe040593          	add	a1,s0,-32
    800053ae:	4505                	li	a0,1
    800053b0:	ffffe097          	auipc	ra,0xffffe
    800053b4:	854080e7          	jalr	-1964(ra) # 80002c04 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053b8:	fe840613          	add	a2,s0,-24
    800053bc:	4581                	li	a1,0
    800053be:	4501                	li	a0,0
    800053c0:	00000097          	auipc	ra,0x0
    800053c4:	c6e080e7          	jalr	-914(ra) # 8000502e <argfd>
    800053c8:	87aa                	mv	a5,a0
    return -1;
    800053ca:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053cc:	0007ca63          	bltz	a5,800053e0 <sys_fstat+0x3e>
  return filestat(f, st);
    800053d0:	fe043583          	ld	a1,-32(s0)
    800053d4:	fe843503          	ld	a0,-24(s0)
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	2a0080e7          	jalr	672(ra) # 80004678 <filestat>
}
    800053e0:	60e2                	ld	ra,24(sp)
    800053e2:	6442                	ld	s0,16(sp)
    800053e4:	6105                	add	sp,sp,32
    800053e6:	8082                	ret

00000000800053e8 <sys_link>:
{
    800053e8:	7169                	add	sp,sp,-304
    800053ea:	f606                	sd	ra,296(sp)
    800053ec:	f222                	sd	s0,288(sp)
    800053ee:	ee26                	sd	s1,280(sp)
    800053f0:	ea4a                	sd	s2,272(sp)
    800053f2:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f4:	08000613          	li	a2,128
    800053f8:	ed040593          	add	a1,s0,-304
    800053fc:	4501                	li	a0,0
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	826080e7          	jalr	-2010(ra) # 80002c24 <argstr>
    return -1;
    80005406:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005408:	10054e63          	bltz	a0,80005524 <sys_link+0x13c>
    8000540c:	08000613          	li	a2,128
    80005410:	f5040593          	add	a1,s0,-176
    80005414:	4505                	li	a0,1
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	80e080e7          	jalr	-2034(ra) # 80002c24 <argstr>
    return -1;
    8000541e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005420:	10054263          	bltz	a0,80005524 <sys_link+0x13c>
  begin_op();
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	cc8080e7          	jalr	-824(ra) # 800040ec <begin_op>
  if((ip = namei(old)) == 0){
    8000542c:	ed040513          	add	a0,s0,-304
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	abc080e7          	jalr	-1348(ra) # 80003eec <namei>
    80005438:	84aa                	mv	s1,a0
    8000543a:	c551                	beqz	a0,800054c6 <sys_link+0xde>
  ilock(ip);
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	30a080e7          	jalr	778(ra) # 80003746 <ilock>
  if(ip->type == T_DIR){
    80005444:	04449703          	lh	a4,68(s1)
    80005448:	4785                	li	a5,1
    8000544a:	08f70463          	beq	a4,a5,800054d2 <sys_link+0xea>
  ip->nlink++;
    8000544e:	04a4d783          	lhu	a5,74(s1)
    80005452:	2785                	addw	a5,a5,1
    80005454:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005458:	8526                	mv	a0,s1
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	220080e7          	jalr	544(ra) # 8000367a <iupdate>
  iunlock(ip);
    80005462:	8526                	mv	a0,s1
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	3a4080e7          	jalr	932(ra) # 80003808 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000546c:	fd040593          	add	a1,s0,-48
    80005470:	f5040513          	add	a0,s0,-176
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	a96080e7          	jalr	-1386(ra) # 80003f0a <nameiparent>
    8000547c:	892a                	mv	s2,a0
    8000547e:	c935                	beqz	a0,800054f2 <sys_link+0x10a>
  ilock(dp);
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	2c6080e7          	jalr	710(ra) # 80003746 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005488:	00092703          	lw	a4,0(s2)
    8000548c:	409c                	lw	a5,0(s1)
    8000548e:	04f71d63          	bne	a4,a5,800054e8 <sys_link+0x100>
    80005492:	40d0                	lw	a2,4(s1)
    80005494:	fd040593          	add	a1,s0,-48
    80005498:	854a                	mv	a0,s2
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	9a0080e7          	jalr	-1632(ra) # 80003e3a <dirlink>
    800054a2:	04054363          	bltz	a0,800054e8 <sys_link+0x100>
  iunlockput(dp);
    800054a6:	854a                	mv	a0,s2
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	500080e7          	jalr	1280(ra) # 800039a8 <iunlockput>
  iput(ip);
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	44e080e7          	jalr	1102(ra) # 80003900 <iput>
  end_op();
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	cac080e7          	jalr	-852(ra) # 80004166 <end_op>
  return 0;
    800054c2:	4781                	li	a5,0
    800054c4:	a085                	j	80005524 <sys_link+0x13c>
    end_op();
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	ca0080e7          	jalr	-864(ra) # 80004166 <end_op>
    return -1;
    800054ce:	57fd                	li	a5,-1
    800054d0:	a891                	j	80005524 <sys_link+0x13c>
    iunlockput(ip);
    800054d2:	8526                	mv	a0,s1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	4d4080e7          	jalr	1236(ra) # 800039a8 <iunlockput>
    end_op();
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	c8a080e7          	jalr	-886(ra) # 80004166 <end_op>
    return -1;
    800054e4:	57fd                	li	a5,-1
    800054e6:	a83d                	j	80005524 <sys_link+0x13c>
    iunlockput(dp);
    800054e8:	854a                	mv	a0,s2
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	4be080e7          	jalr	1214(ra) # 800039a8 <iunlockput>
  ilock(ip);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	252080e7          	jalr	594(ra) # 80003746 <ilock>
  ip->nlink--;
    800054fc:	04a4d783          	lhu	a5,74(s1)
    80005500:	37fd                	addw	a5,a5,-1
    80005502:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	172080e7          	jalr	370(ra) # 8000367a <iupdate>
  iunlockput(ip);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	496080e7          	jalr	1174(ra) # 800039a8 <iunlockput>
  end_op();
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	c4c080e7          	jalr	-948(ra) # 80004166 <end_op>
  return -1;
    80005522:	57fd                	li	a5,-1
}
    80005524:	853e                	mv	a0,a5
    80005526:	70b2                	ld	ra,296(sp)
    80005528:	7412                	ld	s0,288(sp)
    8000552a:	64f2                	ld	s1,280(sp)
    8000552c:	6952                	ld	s2,272(sp)
    8000552e:	6155                	add	sp,sp,304
    80005530:	8082                	ret

0000000080005532 <sys_unlink>:
{
    80005532:	7151                	add	sp,sp,-240
    80005534:	f586                	sd	ra,232(sp)
    80005536:	f1a2                	sd	s0,224(sp)
    80005538:	eda6                	sd	s1,216(sp)
    8000553a:	e9ca                	sd	s2,208(sp)
    8000553c:	e5ce                	sd	s3,200(sp)
    8000553e:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005540:	08000613          	li	a2,128
    80005544:	f3040593          	add	a1,s0,-208
    80005548:	4501                	li	a0,0
    8000554a:	ffffd097          	auipc	ra,0xffffd
    8000554e:	6da080e7          	jalr	1754(ra) # 80002c24 <argstr>
    80005552:	18054163          	bltz	a0,800056d4 <sys_unlink+0x1a2>
  begin_op();
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	b96080e7          	jalr	-1130(ra) # 800040ec <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000555e:	fb040593          	add	a1,s0,-80
    80005562:	f3040513          	add	a0,s0,-208
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	9a4080e7          	jalr	-1628(ra) # 80003f0a <nameiparent>
    8000556e:	84aa                	mv	s1,a0
    80005570:	c979                	beqz	a0,80005646 <sys_unlink+0x114>
  ilock(dp);
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	1d4080e7          	jalr	468(ra) # 80003746 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000557a:	00003597          	auipc	a1,0x3
    8000557e:	23658593          	add	a1,a1,566 # 800087b0 <syscalls+0x318>
    80005582:	fb040513          	add	a0,s0,-80
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	68a080e7          	jalr	1674(ra) # 80003c10 <namecmp>
    8000558e:	14050a63          	beqz	a0,800056e2 <sys_unlink+0x1b0>
    80005592:	00003597          	auipc	a1,0x3
    80005596:	22658593          	add	a1,a1,550 # 800087b8 <syscalls+0x320>
    8000559a:	fb040513          	add	a0,s0,-80
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	672080e7          	jalr	1650(ra) # 80003c10 <namecmp>
    800055a6:	12050e63          	beqz	a0,800056e2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055aa:	f2c40613          	add	a2,s0,-212
    800055ae:	fb040593          	add	a1,s0,-80
    800055b2:	8526                	mv	a0,s1
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	676080e7          	jalr	1654(ra) # 80003c2a <dirlookup>
    800055bc:	892a                	mv	s2,a0
    800055be:	12050263          	beqz	a0,800056e2 <sys_unlink+0x1b0>
  ilock(ip);
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	184080e7          	jalr	388(ra) # 80003746 <ilock>
  if(ip->nlink < 1)
    800055ca:	04a91783          	lh	a5,74(s2)
    800055ce:	08f05263          	blez	a5,80005652 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055d2:	04491703          	lh	a4,68(s2)
    800055d6:	4785                	li	a5,1
    800055d8:	08f70563          	beq	a4,a5,80005662 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055dc:	4641                	li	a2,16
    800055de:	4581                	li	a1,0
    800055e0:	fc040513          	add	a0,s0,-64
    800055e4:	ffffb097          	auipc	ra,0xffffb
    800055e8:	760080e7          	jalr	1888(ra) # 80000d44 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ec:	4741                	li	a4,16
    800055ee:	f2c42683          	lw	a3,-212(s0)
    800055f2:	fc040613          	add	a2,s0,-64
    800055f6:	4581                	li	a1,0
    800055f8:	8526                	mv	a0,s1
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	4f8080e7          	jalr	1272(ra) # 80003af2 <writei>
    80005602:	47c1                	li	a5,16
    80005604:	0af51563          	bne	a0,a5,800056ae <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005608:	04491703          	lh	a4,68(s2)
    8000560c:	4785                	li	a5,1
    8000560e:	0af70863          	beq	a4,a5,800056be <sys_unlink+0x18c>
  iunlockput(dp);
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	394080e7          	jalr	916(ra) # 800039a8 <iunlockput>
  ip->nlink--;
    8000561c:	04a95783          	lhu	a5,74(s2)
    80005620:	37fd                	addw	a5,a5,-1
    80005622:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005626:	854a                	mv	a0,s2
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	052080e7          	jalr	82(ra) # 8000367a <iupdate>
  iunlockput(ip);
    80005630:	854a                	mv	a0,s2
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	376080e7          	jalr	886(ra) # 800039a8 <iunlockput>
  end_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	b2c080e7          	jalr	-1236(ra) # 80004166 <end_op>
  return 0;
    80005642:	4501                	li	a0,0
    80005644:	a84d                	j	800056f6 <sys_unlink+0x1c4>
    end_op();
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	b20080e7          	jalr	-1248(ra) # 80004166 <end_op>
    return -1;
    8000564e:	557d                	li	a0,-1
    80005650:	a05d                	j	800056f6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005652:	00003517          	auipc	a0,0x3
    80005656:	16e50513          	add	a0,a0,366 # 800087c0 <syscalls+0x328>
    8000565a:	ffffb097          	auipc	ra,0xffffb
    8000565e:	ee6080e7          	jalr	-282(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005662:	04c92703          	lw	a4,76(s2)
    80005666:	02000793          	li	a5,32
    8000566a:	f6e7f9e3          	bgeu	a5,a4,800055dc <sys_unlink+0xaa>
    8000566e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005672:	4741                	li	a4,16
    80005674:	86ce                	mv	a3,s3
    80005676:	f1840613          	add	a2,s0,-232
    8000567a:	4581                	li	a1,0
    8000567c:	854a                	mv	a0,s2
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	37c080e7          	jalr	892(ra) # 800039fa <readi>
    80005686:	47c1                	li	a5,16
    80005688:	00f51b63          	bne	a0,a5,8000569e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000568c:	f1845783          	lhu	a5,-232(s0)
    80005690:	e7a1                	bnez	a5,800056d8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005692:	29c1                	addw	s3,s3,16
    80005694:	04c92783          	lw	a5,76(s2)
    80005698:	fcf9ede3          	bltu	s3,a5,80005672 <sys_unlink+0x140>
    8000569c:	b781                	j	800055dc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000569e:	00003517          	auipc	a0,0x3
    800056a2:	13a50513          	add	a0,a0,314 # 800087d8 <syscalls+0x340>
    800056a6:	ffffb097          	auipc	ra,0xffffb
    800056aa:	e9a080e7          	jalr	-358(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056ae:	00003517          	auipc	a0,0x3
    800056b2:	14250513          	add	a0,a0,322 # 800087f0 <syscalls+0x358>
    800056b6:	ffffb097          	auipc	ra,0xffffb
    800056ba:	e8a080e7          	jalr	-374(ra) # 80000540 <panic>
    dp->nlink--;
    800056be:	04a4d783          	lhu	a5,74(s1)
    800056c2:	37fd                	addw	a5,a5,-1
    800056c4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	fb0080e7          	jalr	-80(ra) # 8000367a <iupdate>
    800056d2:	b781                	j	80005612 <sys_unlink+0xe0>
    return -1;
    800056d4:	557d                	li	a0,-1
    800056d6:	a005                	j	800056f6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056d8:	854a                	mv	a0,s2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	2ce080e7          	jalr	718(ra) # 800039a8 <iunlockput>
  iunlockput(dp);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	2c4080e7          	jalr	708(ra) # 800039a8 <iunlockput>
  end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	a7a080e7          	jalr	-1414(ra) # 80004166 <end_op>
  return -1;
    800056f4:	557d                	li	a0,-1
}
    800056f6:	70ae                	ld	ra,232(sp)
    800056f8:	740e                	ld	s0,224(sp)
    800056fa:	64ee                	ld	s1,216(sp)
    800056fc:	694e                	ld	s2,208(sp)
    800056fe:	69ae                	ld	s3,200(sp)
    80005700:	616d                	add	sp,sp,240
    80005702:	8082                	ret

0000000080005704 <sys_open>:

uint64
sys_open(void)
{
    80005704:	7131                	add	sp,sp,-192
    80005706:	fd06                	sd	ra,184(sp)
    80005708:	f922                	sd	s0,176(sp)
    8000570a:	f526                	sd	s1,168(sp)
    8000570c:	f14a                	sd	s2,160(sp)
    8000570e:	ed4e                	sd	s3,152(sp)
    80005710:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005712:	f4c40593          	add	a1,s0,-180
    80005716:	4505                	li	a0,1
    80005718:	ffffd097          	auipc	ra,0xffffd
    8000571c:	4cc080e7          	jalr	1228(ra) # 80002be4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005720:	08000613          	li	a2,128
    80005724:	f5040593          	add	a1,s0,-176
    80005728:	4501                	li	a0,0
    8000572a:	ffffd097          	auipc	ra,0xffffd
    8000572e:	4fa080e7          	jalr	1274(ra) # 80002c24 <argstr>
    80005732:	87aa                	mv	a5,a0
    return -1;
    80005734:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005736:	0a07c863          	bltz	a5,800057e6 <sys_open+0xe2>

  begin_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	9b2080e7          	jalr	-1614(ra) # 800040ec <begin_op>

  if(omode & O_CREATE){
    80005742:	f4c42783          	lw	a5,-180(s0)
    80005746:	2007f793          	and	a5,a5,512
    8000574a:	cbdd                	beqz	a5,80005800 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000574c:	4681                	li	a3,0
    8000574e:	4601                	li	a2,0
    80005750:	4589                	li	a1,2
    80005752:	f5040513          	add	a0,s0,-176
    80005756:	00000097          	auipc	ra,0x0
    8000575a:	97a080e7          	jalr	-1670(ra) # 800050d0 <create>
    8000575e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005760:	c951                	beqz	a0,800057f4 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005762:	04449703          	lh	a4,68(s1)
    80005766:	478d                	li	a5,3
    80005768:	00f71763          	bne	a4,a5,80005776 <sys_open+0x72>
    8000576c:	0464d703          	lhu	a4,70(s1)
    80005770:	47a5                	li	a5,9
    80005772:	0ce7ec63          	bltu	a5,a4,8000584a <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	d7e080e7          	jalr	-642(ra) # 800044f4 <filealloc>
    8000577e:	892a                	mv	s2,a0
    80005780:	c56d                	beqz	a0,8000586a <sys_open+0x166>
    80005782:	00000097          	auipc	ra,0x0
    80005786:	90c080e7          	jalr	-1780(ra) # 8000508e <fdalloc>
    8000578a:	89aa                	mv	s3,a0
    8000578c:	0c054a63          	bltz	a0,80005860 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005790:	04449703          	lh	a4,68(s1)
    80005794:	478d                	li	a5,3
    80005796:	0ef70563          	beq	a4,a5,80005880 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000579a:	4789                	li	a5,2
    8000579c:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800057a0:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800057a4:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800057a8:	f4c42783          	lw	a5,-180(s0)
    800057ac:	0017c713          	xor	a4,a5,1
    800057b0:	8b05                	and	a4,a4,1
    800057b2:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b6:	0037f713          	and	a4,a5,3
    800057ba:	00e03733          	snez	a4,a4
    800057be:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057c2:	4007f793          	and	a5,a5,1024
    800057c6:	c791                	beqz	a5,800057d2 <sys_open+0xce>
    800057c8:	04449703          	lh	a4,68(s1)
    800057cc:	4789                	li	a5,2
    800057ce:	0cf70063          	beq	a4,a5,8000588e <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800057d2:	8526                	mv	a0,s1
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	034080e7          	jalr	52(ra) # 80003808 <iunlock>
  end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	98a080e7          	jalr	-1654(ra) # 80004166 <end_op>

  return fd;
    800057e4:	854e                	mv	a0,s3
}
    800057e6:	70ea                	ld	ra,184(sp)
    800057e8:	744a                	ld	s0,176(sp)
    800057ea:	74aa                	ld	s1,168(sp)
    800057ec:	790a                	ld	s2,160(sp)
    800057ee:	69ea                	ld	s3,152(sp)
    800057f0:	6129                	add	sp,sp,192
    800057f2:	8082                	ret
      end_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	972080e7          	jalr	-1678(ra) # 80004166 <end_op>
      return -1;
    800057fc:	557d                	li	a0,-1
    800057fe:	b7e5                	j	800057e6 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005800:	f5040513          	add	a0,s0,-176
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	6e8080e7          	jalr	1768(ra) # 80003eec <namei>
    8000580c:	84aa                	mv	s1,a0
    8000580e:	c905                	beqz	a0,8000583e <sys_open+0x13a>
    ilock(ip);
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	f36080e7          	jalr	-202(ra) # 80003746 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005818:	04449703          	lh	a4,68(s1)
    8000581c:	4785                	li	a5,1
    8000581e:	f4f712e3          	bne	a4,a5,80005762 <sys_open+0x5e>
    80005822:	f4c42783          	lw	a5,-180(s0)
    80005826:	dba1                	beqz	a5,80005776 <sys_open+0x72>
      iunlockput(ip);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	17e080e7          	jalr	382(ra) # 800039a8 <iunlockput>
      end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	934080e7          	jalr	-1740(ra) # 80004166 <end_op>
      return -1;
    8000583a:	557d                	li	a0,-1
    8000583c:	b76d                	j	800057e6 <sys_open+0xe2>
      end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	928080e7          	jalr	-1752(ra) # 80004166 <end_op>
      return -1;
    80005846:	557d                	li	a0,-1
    80005848:	bf79                	j	800057e6 <sys_open+0xe2>
    iunlockput(ip);
    8000584a:	8526                	mv	a0,s1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	15c080e7          	jalr	348(ra) # 800039a8 <iunlockput>
    end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	912080e7          	jalr	-1774(ra) # 80004166 <end_op>
    return -1;
    8000585c:	557d                	li	a0,-1
    8000585e:	b761                	j	800057e6 <sys_open+0xe2>
      fileclose(f);
    80005860:	854a                	mv	a0,s2
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	d4e080e7          	jalr	-690(ra) # 800045b0 <fileclose>
    iunlockput(ip);
    8000586a:	8526                	mv	a0,s1
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	13c080e7          	jalr	316(ra) # 800039a8 <iunlockput>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	8f2080e7          	jalr	-1806(ra) # 80004166 <end_op>
    return -1;
    8000587c:	557d                	li	a0,-1
    8000587e:	b7a5                	j	800057e6 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005880:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005884:	04649783          	lh	a5,70(s1)
    80005888:	02f91223          	sh	a5,36(s2)
    8000588c:	bf21                	j	800057a4 <sys_open+0xa0>
    itrunc(ip);
    8000588e:	8526                	mv	a0,s1
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	fc4080e7          	jalr	-60(ra) # 80003854 <itrunc>
    80005898:	bf2d                	j	800057d2 <sys_open+0xce>

000000008000589a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000589a:	7175                	add	sp,sp,-144
    8000589c:	e506                	sd	ra,136(sp)
    8000589e:	e122                	sd	s0,128(sp)
    800058a0:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	84a080e7          	jalr	-1974(ra) # 800040ec <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058aa:	08000613          	li	a2,128
    800058ae:	f7040593          	add	a1,s0,-144
    800058b2:	4501                	li	a0,0
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	370080e7          	jalr	880(ra) # 80002c24 <argstr>
    800058bc:	02054963          	bltz	a0,800058ee <sys_mkdir+0x54>
    800058c0:	4681                	li	a3,0
    800058c2:	4601                	li	a2,0
    800058c4:	4585                	li	a1,1
    800058c6:	f7040513          	add	a0,s0,-144
    800058ca:	00000097          	auipc	ra,0x0
    800058ce:	806080e7          	jalr	-2042(ra) # 800050d0 <create>
    800058d2:	cd11                	beqz	a0,800058ee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	0d4080e7          	jalr	212(ra) # 800039a8 <iunlockput>
  end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	88a080e7          	jalr	-1910(ra) # 80004166 <end_op>
  return 0;
    800058e4:	4501                	li	a0,0
}
    800058e6:	60aa                	ld	ra,136(sp)
    800058e8:	640a                	ld	s0,128(sp)
    800058ea:	6149                	add	sp,sp,144
    800058ec:	8082                	ret
    end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	878080e7          	jalr	-1928(ra) # 80004166 <end_op>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	b7fd                	j	800058e6 <sys_mkdir+0x4c>

00000000800058fa <sys_mknod>:

uint64
sys_mknod(void)
{
    800058fa:	7135                	add	sp,sp,-160
    800058fc:	ed06                	sd	ra,152(sp)
    800058fe:	e922                	sd	s0,144(sp)
    80005900:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	7ea080e7          	jalr	2026(ra) # 800040ec <begin_op>
  argint(1, &major);
    8000590a:	f6c40593          	add	a1,s0,-148
    8000590e:	4505                	li	a0,1
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	2d4080e7          	jalr	724(ra) # 80002be4 <argint>
  argint(2, &minor);
    80005918:	f6840593          	add	a1,s0,-152
    8000591c:	4509                	li	a0,2
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	2c6080e7          	jalr	710(ra) # 80002be4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005926:	08000613          	li	a2,128
    8000592a:	f7040593          	add	a1,s0,-144
    8000592e:	4501                	li	a0,0
    80005930:	ffffd097          	auipc	ra,0xffffd
    80005934:	2f4080e7          	jalr	756(ra) # 80002c24 <argstr>
    80005938:	02054b63          	bltz	a0,8000596e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000593c:	f6841683          	lh	a3,-152(s0)
    80005940:	f6c41603          	lh	a2,-148(s0)
    80005944:	458d                	li	a1,3
    80005946:	f7040513          	add	a0,s0,-144
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	786080e7          	jalr	1926(ra) # 800050d0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005952:	cd11                	beqz	a0,8000596e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	054080e7          	jalr	84(ra) # 800039a8 <iunlockput>
  end_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	80a080e7          	jalr	-2038(ra) # 80004166 <end_op>
  return 0;
    80005964:	4501                	li	a0,0
}
    80005966:	60ea                	ld	ra,152(sp)
    80005968:	644a                	ld	s0,144(sp)
    8000596a:	610d                	add	sp,sp,160
    8000596c:	8082                	ret
    end_op();
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	7f8080e7          	jalr	2040(ra) # 80004166 <end_op>
    return -1;
    80005976:	557d                	li	a0,-1
    80005978:	b7fd                	j	80005966 <sys_mknod+0x6c>

000000008000597a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000597a:	7135                	add	sp,sp,-160
    8000597c:	ed06                	sd	ra,152(sp)
    8000597e:	e922                	sd	s0,144(sp)
    80005980:	e526                	sd	s1,136(sp)
    80005982:	e14a                	sd	s2,128(sp)
    80005984:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005986:	ffffc097          	auipc	ra,0xffffc
    8000598a:	09e080e7          	jalr	158(ra) # 80001a24 <myproc>
    8000598e:	892a                	mv	s2,a0
  
  begin_op();
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	75c080e7          	jalr	1884(ra) # 800040ec <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005998:	08000613          	li	a2,128
    8000599c:	f6040593          	add	a1,s0,-160
    800059a0:	4501                	li	a0,0
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	282080e7          	jalr	642(ra) # 80002c24 <argstr>
    800059aa:	04054b63          	bltz	a0,80005a00 <sys_chdir+0x86>
    800059ae:	f6040513          	add	a0,s0,-160
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	53a080e7          	jalr	1338(ra) # 80003eec <namei>
    800059ba:	84aa                	mv	s1,a0
    800059bc:	c131                	beqz	a0,80005a00 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	d88080e7          	jalr	-632(ra) # 80003746 <ilock>
  if(ip->type != T_DIR){
    800059c6:	04449703          	lh	a4,68(s1)
    800059ca:	4785                	li	a5,1
    800059cc:	04f71063          	bne	a4,a5,80005a0c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	e36080e7          	jalr	-458(ra) # 80003808 <iunlock>
  iput(p->cwd);
    800059da:	15093503          	ld	a0,336(s2)
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	f22080e7          	jalr	-222(ra) # 80003900 <iput>
  end_op();
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	780080e7          	jalr	1920(ra) # 80004166 <end_op>
  p->cwd = ip;
    800059ee:	14993823          	sd	s1,336(s2)
  return 0;
    800059f2:	4501                	li	a0,0
}
    800059f4:	60ea                	ld	ra,152(sp)
    800059f6:	644a                	ld	s0,144(sp)
    800059f8:	64aa                	ld	s1,136(sp)
    800059fa:	690a                	ld	s2,128(sp)
    800059fc:	610d                	add	sp,sp,160
    800059fe:	8082                	ret
    end_op();
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	766080e7          	jalr	1894(ra) # 80004166 <end_op>
    return -1;
    80005a08:	557d                	li	a0,-1
    80005a0a:	b7ed                	j	800059f4 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	f9a080e7          	jalr	-102(ra) # 800039a8 <iunlockput>
    end_op();
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	750080e7          	jalr	1872(ra) # 80004166 <end_op>
    return -1;
    80005a1e:	557d                	li	a0,-1
    80005a20:	bfd1                	j	800059f4 <sys_chdir+0x7a>

0000000080005a22 <sys_exec>:

uint64
sys_exec(void)
{
    80005a22:	7121                	add	sp,sp,-448
    80005a24:	ff06                	sd	ra,440(sp)
    80005a26:	fb22                	sd	s0,432(sp)
    80005a28:	f726                	sd	s1,424(sp)
    80005a2a:	f34a                	sd	s2,416(sp)
    80005a2c:	ef4e                	sd	s3,408(sp)
    80005a2e:	eb52                	sd	s4,400(sp)
    80005a30:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a32:	e4840593          	add	a1,s0,-440
    80005a36:	4505                	li	a0,1
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	1cc080e7          	jalr	460(ra) # 80002c04 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a40:	08000613          	li	a2,128
    80005a44:	f5040593          	add	a1,s0,-176
    80005a48:	4501                	li	a0,0
    80005a4a:	ffffd097          	auipc	ra,0xffffd
    80005a4e:	1da080e7          	jalr	474(ra) # 80002c24 <argstr>
    80005a52:	87aa                	mv	a5,a0
    return -1;
    80005a54:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a56:	0c07c263          	bltz	a5,80005b1a <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a5a:	10000613          	li	a2,256
    80005a5e:	4581                	li	a1,0
    80005a60:	e5040513          	add	a0,s0,-432
    80005a64:	ffffb097          	auipc	ra,0xffffb
    80005a68:	2e0080e7          	jalr	736(ra) # 80000d44 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a6c:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a70:	89a6                	mv	s3,s1
    80005a72:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a74:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a78:	00391513          	sll	a0,s2,0x3
    80005a7c:	e4040593          	add	a1,s0,-448
    80005a80:	e4843783          	ld	a5,-440(s0)
    80005a84:	953e                	add	a0,a0,a5
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	0c0080e7          	jalr	192(ra) # 80002b46 <fetchaddr>
    80005a8e:	02054a63          	bltz	a0,80005ac2 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005a92:	e4043783          	ld	a5,-448(s0)
    80005a96:	c3b9                	beqz	a5,80005adc <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	0c0080e7          	jalr	192(ra) # 80000b58 <kalloc>
    80005aa0:	85aa                	mv	a1,a0
    80005aa2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aa6:	cd11                	beqz	a0,80005ac2 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aa8:	6605                	lui	a2,0x1
    80005aaa:	e4043503          	ld	a0,-448(s0)
    80005aae:	ffffd097          	auipc	ra,0xffffd
    80005ab2:	0ea080e7          	jalr	234(ra) # 80002b98 <fetchstr>
    80005ab6:	00054663          	bltz	a0,80005ac2 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005aba:	0905                	add	s2,s2,1
    80005abc:	09a1                	add	s3,s3,8
    80005abe:	fb491de3          	bne	s2,s4,80005a78 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac2:	f5040913          	add	s2,s0,-176
    80005ac6:	6088                	ld	a0,0(s1)
    80005ac8:	c921                	beqz	a0,80005b18 <sys_exec+0xf6>
    kfree(argv[i]);
    80005aca:	ffffb097          	auipc	ra,0xffffb
    80005ace:	f90080e7          	jalr	-112(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad2:	04a1                	add	s1,s1,8
    80005ad4:	ff2499e3          	bne	s1,s2,80005ac6 <sys_exec+0xa4>
  return -1;
    80005ad8:	557d                	li	a0,-1
    80005ada:	a081                	j	80005b1a <sys_exec+0xf8>
      argv[i] = 0;
    80005adc:	0009079b          	sext.w	a5,s2
    80005ae0:	078e                	sll	a5,a5,0x3
    80005ae2:	fd078793          	add	a5,a5,-48
    80005ae6:	97a2                	add	a5,a5,s0
    80005ae8:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005aec:	e5040593          	add	a1,s0,-432
    80005af0:	f5040513          	add	a0,s0,-176
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	132080e7          	jalr	306(ra) # 80004c26 <exec>
    80005afc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005afe:	f5040993          	add	s3,s0,-176
    80005b02:	6088                	ld	a0,0(s1)
    80005b04:	c901                	beqz	a0,80005b14 <sys_exec+0xf2>
    kfree(argv[i]);
    80005b06:	ffffb097          	auipc	ra,0xffffb
    80005b0a:	f54080e7          	jalr	-172(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0e:	04a1                	add	s1,s1,8
    80005b10:	ff3499e3          	bne	s1,s3,80005b02 <sys_exec+0xe0>
  return ret;
    80005b14:	854a                	mv	a0,s2
    80005b16:	a011                	j	80005b1a <sys_exec+0xf8>
  return -1;
    80005b18:	557d                	li	a0,-1
}
    80005b1a:	70fa                	ld	ra,440(sp)
    80005b1c:	745a                	ld	s0,432(sp)
    80005b1e:	74ba                	ld	s1,424(sp)
    80005b20:	791a                	ld	s2,416(sp)
    80005b22:	69fa                	ld	s3,408(sp)
    80005b24:	6a5a                	ld	s4,400(sp)
    80005b26:	6139                	add	sp,sp,448
    80005b28:	8082                	ret

0000000080005b2a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b2a:	7139                	add	sp,sp,-64
    80005b2c:	fc06                	sd	ra,56(sp)
    80005b2e:	f822                	sd	s0,48(sp)
    80005b30:	f426                	sd	s1,40(sp)
    80005b32:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b34:	ffffc097          	auipc	ra,0xffffc
    80005b38:	ef0080e7          	jalr	-272(ra) # 80001a24 <myproc>
    80005b3c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b3e:	fd840593          	add	a1,s0,-40
    80005b42:	4501                	li	a0,0
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	0c0080e7          	jalr	192(ra) # 80002c04 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b4c:	fc840593          	add	a1,s0,-56
    80005b50:	fd040513          	add	a0,s0,-48
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	d88080e7          	jalr	-632(ra) # 800048dc <pipealloc>
    return -1;
    80005b5c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b5e:	0c054463          	bltz	a0,80005c26 <sys_pipe+0xfc>
  fd0 = -1;
    80005b62:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b66:	fd043503          	ld	a0,-48(s0)
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	524080e7          	jalr	1316(ra) # 8000508e <fdalloc>
    80005b72:	fca42223          	sw	a0,-60(s0)
    80005b76:	08054b63          	bltz	a0,80005c0c <sys_pipe+0xe2>
    80005b7a:	fc843503          	ld	a0,-56(s0)
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	510080e7          	jalr	1296(ra) # 8000508e <fdalloc>
    80005b86:	fca42023          	sw	a0,-64(s0)
    80005b8a:	06054863          	bltz	a0,80005bfa <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b8e:	4691                	li	a3,4
    80005b90:	fc440613          	add	a2,s0,-60
    80005b94:	fd843583          	ld	a1,-40(s0)
    80005b98:	68a8                	ld	a0,80(s1)
    80005b9a:	ffffc097          	auipc	ra,0xffffc
    80005b9e:	b4a080e7          	jalr	-1206(ra) # 800016e4 <copyout>
    80005ba2:	02054063          	bltz	a0,80005bc2 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ba6:	4691                	li	a3,4
    80005ba8:	fc040613          	add	a2,s0,-64
    80005bac:	fd843583          	ld	a1,-40(s0)
    80005bb0:	0591                	add	a1,a1,4
    80005bb2:	68a8                	ld	a0,80(s1)
    80005bb4:	ffffc097          	auipc	ra,0xffffc
    80005bb8:	b30080e7          	jalr	-1232(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bbc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bbe:	06055463          	bgez	a0,80005c26 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005bc2:	fc442783          	lw	a5,-60(s0)
    80005bc6:	07e9                	add	a5,a5,26
    80005bc8:	078e                	sll	a5,a5,0x3
    80005bca:	97a6                	add	a5,a5,s1
    80005bcc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bd0:	fc042783          	lw	a5,-64(s0)
    80005bd4:	07e9                	add	a5,a5,26
    80005bd6:	078e                	sll	a5,a5,0x3
    80005bd8:	94be                	add	s1,s1,a5
    80005bda:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bde:	fd043503          	ld	a0,-48(s0)
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	9ce080e7          	jalr	-1586(ra) # 800045b0 <fileclose>
    fileclose(wf);
    80005bea:	fc843503          	ld	a0,-56(s0)
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	9c2080e7          	jalr	-1598(ra) # 800045b0 <fileclose>
    return -1;
    80005bf6:	57fd                	li	a5,-1
    80005bf8:	a03d                	j	80005c26 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bfa:	fc442783          	lw	a5,-60(s0)
    80005bfe:	0007c763          	bltz	a5,80005c0c <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c02:	07e9                	add	a5,a5,26
    80005c04:	078e                	sll	a5,a5,0x3
    80005c06:	97a6                	add	a5,a5,s1
    80005c08:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c0c:	fd043503          	ld	a0,-48(s0)
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	9a0080e7          	jalr	-1632(ra) # 800045b0 <fileclose>
    fileclose(wf);
    80005c18:	fc843503          	ld	a0,-56(s0)
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	994080e7          	jalr	-1644(ra) # 800045b0 <fileclose>
    return -1;
    80005c24:	57fd                	li	a5,-1
}
    80005c26:	853e                	mv	a0,a5
    80005c28:	70e2                	ld	ra,56(sp)
    80005c2a:	7442                	ld	s0,48(sp)
    80005c2c:	74a2                	ld	s1,40(sp)
    80005c2e:	6121                	add	sp,sp,64
    80005c30:	8082                	ret
	...

0000000080005c40 <kernelvec>:
    80005c40:	7111                	add	sp,sp,-256
    80005c42:	e006                	sd	ra,0(sp)
    80005c44:	e40a                	sd	sp,8(sp)
    80005c46:	e80e                	sd	gp,16(sp)
    80005c48:	ec12                	sd	tp,24(sp)
    80005c4a:	f016                	sd	t0,32(sp)
    80005c4c:	f41a                	sd	t1,40(sp)
    80005c4e:	f81e                	sd	t2,48(sp)
    80005c50:	fc22                	sd	s0,56(sp)
    80005c52:	e0a6                	sd	s1,64(sp)
    80005c54:	e4aa                	sd	a0,72(sp)
    80005c56:	e8ae                	sd	a1,80(sp)
    80005c58:	ecb2                	sd	a2,88(sp)
    80005c5a:	f0b6                	sd	a3,96(sp)
    80005c5c:	f4ba                	sd	a4,104(sp)
    80005c5e:	f8be                	sd	a5,112(sp)
    80005c60:	fcc2                	sd	a6,120(sp)
    80005c62:	e146                	sd	a7,128(sp)
    80005c64:	e54a                	sd	s2,136(sp)
    80005c66:	e94e                	sd	s3,144(sp)
    80005c68:	ed52                	sd	s4,152(sp)
    80005c6a:	f156                	sd	s5,160(sp)
    80005c6c:	f55a                	sd	s6,168(sp)
    80005c6e:	f95e                	sd	s7,176(sp)
    80005c70:	fd62                	sd	s8,184(sp)
    80005c72:	e1e6                	sd	s9,192(sp)
    80005c74:	e5ea                	sd	s10,200(sp)
    80005c76:	e9ee                	sd	s11,208(sp)
    80005c78:	edf2                	sd	t3,216(sp)
    80005c7a:	f1f6                	sd	t4,224(sp)
    80005c7c:	f5fa                	sd	t5,232(sp)
    80005c7e:	f9fe                	sd	t6,240(sp)
    80005c80:	d93fc0ef          	jal	80002a12 <kerneltrap>
    80005c84:	6082                	ld	ra,0(sp)
    80005c86:	6122                	ld	sp,8(sp)
    80005c88:	61c2                	ld	gp,16(sp)
    80005c8a:	7282                	ld	t0,32(sp)
    80005c8c:	7322                	ld	t1,40(sp)
    80005c8e:	73c2                	ld	t2,48(sp)
    80005c90:	7462                	ld	s0,56(sp)
    80005c92:	6486                	ld	s1,64(sp)
    80005c94:	6526                	ld	a0,72(sp)
    80005c96:	65c6                	ld	a1,80(sp)
    80005c98:	6666                	ld	a2,88(sp)
    80005c9a:	7686                	ld	a3,96(sp)
    80005c9c:	7726                	ld	a4,104(sp)
    80005c9e:	77c6                	ld	a5,112(sp)
    80005ca0:	7866                	ld	a6,120(sp)
    80005ca2:	688a                	ld	a7,128(sp)
    80005ca4:	692a                	ld	s2,136(sp)
    80005ca6:	69ca                	ld	s3,144(sp)
    80005ca8:	6a6a                	ld	s4,152(sp)
    80005caa:	7a8a                	ld	s5,160(sp)
    80005cac:	7b2a                	ld	s6,168(sp)
    80005cae:	7bca                	ld	s7,176(sp)
    80005cb0:	7c6a                	ld	s8,184(sp)
    80005cb2:	6c8e                	ld	s9,192(sp)
    80005cb4:	6d2e                	ld	s10,200(sp)
    80005cb6:	6dce                	ld	s11,208(sp)
    80005cb8:	6e6e                	ld	t3,216(sp)
    80005cba:	7e8e                	ld	t4,224(sp)
    80005cbc:	7f2e                	ld	t5,232(sp)
    80005cbe:	7fce                	ld	t6,240(sp)
    80005cc0:	6111                	add	sp,sp,256
    80005cc2:	10200073          	sret
    80005cc6:	00000013          	nop
    80005cca:	00000013          	nop
    80005cce:	0001                	nop

0000000080005cd0 <timervec>:
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	e10c                	sd	a1,0(a0)
    80005cd6:	e510                	sd	a2,8(a0)
    80005cd8:	e914                	sd	a3,16(a0)
    80005cda:	6d0c                	ld	a1,24(a0)
    80005cdc:	7110                	ld	a2,32(a0)
    80005cde:	6194                	ld	a3,0(a1)
    80005ce0:	96b2                	add	a3,a3,a2
    80005ce2:	e194                	sd	a3,0(a1)
    80005ce4:	4589                	li	a1,2
    80005ce6:	14459073          	csrw	sip,a1
    80005cea:	6914                	ld	a3,16(a0)
    80005cec:	6510                	ld	a2,8(a0)
    80005cee:	610c                	ld	a1,0(a0)
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	30200073          	mret
	...

0000000080005cfa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cfa:	1141                	add	sp,sp,-16
    80005cfc:	e422                	sd	s0,8(sp)
    80005cfe:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d00:	0c0007b7          	lui	a5,0xc000
    80005d04:	4705                	li	a4,1
    80005d06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d08:	c3d8                	sw	a4,4(a5)
}
    80005d0a:	6422                	ld	s0,8(sp)
    80005d0c:	0141                	add	sp,sp,16
    80005d0e:	8082                	ret

0000000080005d10 <plicinithart>:

void
plicinithart(void)
{
    80005d10:	1141                	add	sp,sp,-16
    80005d12:	e406                	sd	ra,8(sp)
    80005d14:	e022                	sd	s0,0(sp)
    80005d16:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	ce0080e7          	jalr	-800(ra) # 800019f8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d20:	0085171b          	sllw	a4,a0,0x8
    80005d24:	0c0027b7          	lui	a5,0xc002
    80005d28:	97ba                	add	a5,a5,a4
    80005d2a:	40200713          	li	a4,1026
    80005d2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d32:	00d5151b          	sllw	a0,a0,0xd
    80005d36:	0c2017b7          	lui	a5,0xc201
    80005d3a:	97aa                	add	a5,a5,a0
    80005d3c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d40:	60a2                	ld	ra,8(sp)
    80005d42:	6402                	ld	s0,0(sp)
    80005d44:	0141                	add	sp,sp,16
    80005d46:	8082                	ret

0000000080005d48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d48:	1141                	add	sp,sp,-16
    80005d4a:	e406                	sd	ra,8(sp)
    80005d4c:	e022                	sd	s0,0(sp)
    80005d4e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005d50:	ffffc097          	auipc	ra,0xffffc
    80005d54:	ca8080e7          	jalr	-856(ra) # 800019f8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d58:	00d5151b          	sllw	a0,a0,0xd
    80005d5c:	0c2017b7          	lui	a5,0xc201
    80005d60:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d62:	43c8                	lw	a0,4(a5)
    80005d64:	60a2                	ld	ra,8(sp)
    80005d66:	6402                	ld	s0,0(sp)
    80005d68:	0141                	add	sp,sp,16
    80005d6a:	8082                	ret

0000000080005d6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d6c:	1101                	add	sp,sp,-32
    80005d6e:	ec06                	sd	ra,24(sp)
    80005d70:	e822                	sd	s0,16(sp)
    80005d72:	e426                	sd	s1,8(sp)
    80005d74:	1000                	add	s0,sp,32
    80005d76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	c80080e7          	jalr	-896(ra) # 800019f8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d80:	00d5151b          	sllw	a0,a0,0xd
    80005d84:	0c2017b7          	lui	a5,0xc201
    80005d88:	97aa                	add	a5,a5,a0
    80005d8a:	c3c4                	sw	s1,4(a5)
}
    80005d8c:	60e2                	ld	ra,24(sp)
    80005d8e:	6442                	ld	s0,16(sp)
    80005d90:	64a2                	ld	s1,8(sp)
    80005d92:	6105                	add	sp,sp,32
    80005d94:	8082                	ret

0000000080005d96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d96:	1141                	add	sp,sp,-16
    80005d98:	e406                	sd	ra,8(sp)
    80005d9a:	e022                	sd	s0,0(sp)
    80005d9c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005d9e:	479d                	li	a5,7
    80005da0:	04a7cc63          	blt	a5,a0,80005df8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005da4:	0001c797          	auipc	a5,0x1c
    80005da8:	4ac78793          	add	a5,a5,1196 # 80022250 <disk>
    80005dac:	97aa                	add	a5,a5,a0
    80005dae:	0187c783          	lbu	a5,24(a5)
    80005db2:	ebb9                	bnez	a5,80005e08 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005db4:	00451693          	sll	a3,a0,0x4
    80005db8:	0001c797          	auipc	a5,0x1c
    80005dbc:	49878793          	add	a5,a5,1176 # 80022250 <disk>
    80005dc0:	6398                	ld	a4,0(a5)
    80005dc2:	9736                	add	a4,a4,a3
    80005dc4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005dc8:	6398                	ld	a4,0(a5)
    80005dca:	9736                	add	a4,a4,a3
    80005dcc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005dd0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005dd4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	4705                	li	a4,1
    80005ddc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005de0:	0001c517          	auipc	a0,0x1c
    80005de4:	48850513          	add	a0,a0,1160 # 80022268 <disk+0x18>
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	376080e7          	jalr	886(ra) # 8000215e <wakeup>
}
    80005df0:	60a2                	ld	ra,8(sp)
    80005df2:	6402                	ld	s0,0(sp)
    80005df4:	0141                	add	sp,sp,16
    80005df6:	8082                	ret
    panic("free_desc 1");
    80005df8:	00003517          	auipc	a0,0x3
    80005dfc:	a0850513          	add	a0,a0,-1528 # 80008800 <syscalls+0x368>
    80005e00:	ffffa097          	auipc	ra,0xffffa
    80005e04:	740080e7          	jalr	1856(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e08:	00003517          	auipc	a0,0x3
    80005e0c:	a0850513          	add	a0,a0,-1528 # 80008810 <syscalls+0x378>
    80005e10:	ffffa097          	auipc	ra,0xffffa
    80005e14:	730080e7          	jalr	1840(ra) # 80000540 <panic>

0000000080005e18 <virtio_disk_init>:
{
    80005e18:	1101                	add	sp,sp,-32
    80005e1a:	ec06                	sd	ra,24(sp)
    80005e1c:	e822                	sd	s0,16(sp)
    80005e1e:	e426                	sd	s1,8(sp)
    80005e20:	e04a                	sd	s2,0(sp)
    80005e22:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e24:	00003597          	auipc	a1,0x3
    80005e28:	9fc58593          	add	a1,a1,-1540 # 80008820 <syscalls+0x388>
    80005e2c:	0001c517          	auipc	a0,0x1c
    80005e30:	54c50513          	add	a0,a0,1356 # 80022378 <disk+0x128>
    80005e34:	ffffb097          	auipc	ra,0xffffb
    80005e38:	d84080e7          	jalr	-636(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e3c:	100017b7          	lui	a5,0x10001
    80005e40:	4398                	lw	a4,0(a5)
    80005e42:	2701                	sext.w	a4,a4
    80005e44:	747277b7          	lui	a5,0x74727
    80005e48:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e4c:	14f71b63          	bne	a4,a5,80005fa2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e50:	100017b7          	lui	a5,0x10001
    80005e54:	43dc                	lw	a5,4(a5)
    80005e56:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e58:	4709                	li	a4,2
    80005e5a:	14e79463          	bne	a5,a4,80005fa2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	479c                	lw	a5,8(a5)
    80005e64:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e66:	12e79e63          	bne	a5,a4,80005fa2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e6a:	100017b7          	lui	a5,0x10001
    80005e6e:	47d8                	lw	a4,12(a5)
    80005e70:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e72:	554d47b7          	lui	a5,0x554d4
    80005e76:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e7a:	12f71463          	bne	a4,a5,80005fa2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e86:	4705                	li	a4,1
    80005e88:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8a:	470d                	li	a4,3
    80005e8c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e8e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e90:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e94:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc3cf>
    80005e98:	8f75                	and	a4,a4,a3
    80005e9a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e9c:	472d                	li	a4,11
    80005e9e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ea0:	5bbc                	lw	a5,112(a5)
    80005ea2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ea6:	8ba1                	and	a5,a5,8
    80005ea8:	10078563          	beqz	a5,80005fb2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eac:	100017b7          	lui	a5,0x10001
    80005eb0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005eb4:	43fc                	lw	a5,68(a5)
    80005eb6:	2781                	sext.w	a5,a5
    80005eb8:	10079563          	bnez	a5,80005fc2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ebc:	100017b7          	lui	a5,0x10001
    80005ec0:	5bdc                	lw	a5,52(a5)
    80005ec2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ec4:	10078763          	beqz	a5,80005fd2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005ec8:	471d                	li	a4,7
    80005eca:	10f77c63          	bgeu	a4,a5,80005fe2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005ece:	ffffb097          	auipc	ra,0xffffb
    80005ed2:	c8a080e7          	jalr	-886(ra) # 80000b58 <kalloc>
    80005ed6:	0001c497          	auipc	s1,0x1c
    80005eda:	37a48493          	add	s1,s1,890 # 80022250 <disk>
    80005ede:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ee0:	ffffb097          	auipc	ra,0xffffb
    80005ee4:	c78080e7          	jalr	-904(ra) # 80000b58 <kalloc>
    80005ee8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eea:	ffffb097          	auipc	ra,0xffffb
    80005eee:	c6e080e7          	jalr	-914(ra) # 80000b58 <kalloc>
    80005ef2:	87aa                	mv	a5,a0
    80005ef4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ef6:	6088                	ld	a0,0(s1)
    80005ef8:	cd6d                	beqz	a0,80005ff2 <virtio_disk_init+0x1da>
    80005efa:	0001c717          	auipc	a4,0x1c
    80005efe:	35e73703          	ld	a4,862(a4) # 80022258 <disk+0x8>
    80005f02:	cb65                	beqz	a4,80005ff2 <virtio_disk_init+0x1da>
    80005f04:	c7fd                	beqz	a5,80005ff2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f06:	6605                	lui	a2,0x1
    80005f08:	4581                	li	a1,0
    80005f0a:	ffffb097          	auipc	ra,0xffffb
    80005f0e:	e3a080e7          	jalr	-454(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f12:	0001c497          	auipc	s1,0x1c
    80005f16:	33e48493          	add	s1,s1,830 # 80022250 <disk>
    80005f1a:	6605                	lui	a2,0x1
    80005f1c:	4581                	li	a1,0
    80005f1e:	6488                	ld	a0,8(s1)
    80005f20:	ffffb097          	auipc	ra,0xffffb
    80005f24:	e24080e7          	jalr	-476(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f28:	6605                	lui	a2,0x1
    80005f2a:	4581                	li	a1,0
    80005f2c:	6888                	ld	a0,16(s1)
    80005f2e:	ffffb097          	auipc	ra,0xffffb
    80005f32:	e16080e7          	jalr	-490(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f36:	100017b7          	lui	a5,0x10001
    80005f3a:	4721                	li	a4,8
    80005f3c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f3e:	4098                	lw	a4,0(s1)
    80005f40:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f44:	40d8                	lw	a4,4(s1)
    80005f46:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f4a:	6498                	ld	a4,8(s1)
    80005f4c:	0007069b          	sext.w	a3,a4
    80005f50:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f54:	9701                	sra	a4,a4,0x20
    80005f56:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f5a:	6898                	ld	a4,16(s1)
    80005f5c:	0007069b          	sext.w	a3,a4
    80005f60:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f64:	9701                	sra	a4,a4,0x20
    80005f66:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f6a:	4705                	li	a4,1
    80005f6c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f6e:	00e48c23          	sb	a4,24(s1)
    80005f72:	00e48ca3          	sb	a4,25(s1)
    80005f76:	00e48d23          	sb	a4,26(s1)
    80005f7a:	00e48da3          	sb	a4,27(s1)
    80005f7e:	00e48e23          	sb	a4,28(s1)
    80005f82:	00e48ea3          	sb	a4,29(s1)
    80005f86:	00e48f23          	sb	a4,30(s1)
    80005f8a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f8e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f92:	0727a823          	sw	s2,112(a5)
}
    80005f96:	60e2                	ld	ra,24(sp)
    80005f98:	6442                	ld	s0,16(sp)
    80005f9a:	64a2                	ld	s1,8(sp)
    80005f9c:	6902                	ld	s2,0(sp)
    80005f9e:	6105                	add	sp,sp,32
    80005fa0:	8082                	ret
    panic("could not find virtio disk");
    80005fa2:	00003517          	auipc	a0,0x3
    80005fa6:	88e50513          	add	a0,a0,-1906 # 80008830 <syscalls+0x398>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fb2:	00003517          	auipc	a0,0x3
    80005fb6:	89e50513          	add	a0,a0,-1890 # 80008850 <syscalls+0x3b8>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	8ae50513          	add	a0,a0,-1874 # 80008870 <syscalls+0x3d8>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005fd2:	00003517          	auipc	a0,0x3
    80005fd6:	8be50513          	add	a0,a0,-1858 # 80008890 <syscalls+0x3f8>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	8ce50513          	add	a0,a0,-1842 # 800088b0 <syscalls+0x418>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	8de50513          	add	a0,a0,-1826 # 800088d0 <syscalls+0x438>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>

0000000080006002 <virtio_disk_init_bootloader>:
{
    80006002:	1101                	add	sp,sp,-32
    80006004:	ec06                	sd	ra,24(sp)
    80006006:	e822                	sd	s0,16(sp)
    80006008:	e426                	sd	s1,8(sp)
    8000600a:	e04a                	sd	s2,0(sp)
    8000600c:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000600e:	00003597          	auipc	a1,0x3
    80006012:	81258593          	add	a1,a1,-2030 # 80008820 <syscalls+0x388>
    80006016:	0001c517          	auipc	a0,0x1c
    8000601a:	36250513          	add	a0,a0,866 # 80022378 <disk+0x128>
    8000601e:	ffffb097          	auipc	ra,0xffffb
    80006022:	b9a080e7          	jalr	-1126(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006026:	100017b7          	lui	a5,0x10001
    8000602a:	4398                	lw	a4,0(a5)
    8000602c:	2701                	sext.w	a4,a4
    8000602e:	747277b7          	lui	a5,0x74727
    80006032:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006036:	12f71763          	bne	a4,a5,80006164 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000603a:	100017b7          	lui	a5,0x10001
    8000603e:	43dc                	lw	a5,4(a5)
    80006040:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006042:	4709                	li	a4,2
    80006044:	12e79063          	bne	a5,a4,80006164 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006048:	100017b7          	lui	a5,0x10001
    8000604c:	479c                	lw	a5,8(a5)
    8000604e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006050:	10e79a63          	bne	a5,a4,80006164 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006054:	100017b7          	lui	a5,0x10001
    80006058:	47d8                	lw	a4,12(a5)
    8000605a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000605c:	554d47b7          	lui	a5,0x554d4
    80006060:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006064:	10f71063          	bne	a4,a5,80006164 <virtio_disk_init_bootloader+0x162>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006068:	100017b7          	lui	a5,0x10001
    8000606c:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006070:	4705                	li	a4,1
    80006072:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006074:	470d                	li	a4,3
    80006076:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006078:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000607a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000607e:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc3cf>
    80006082:	8f75                	and	a4,a4,a3
    80006084:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006086:	472d                	li	a4,11
    80006088:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000608a:	5bbc                	lw	a5,112(a5)
    8000608c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006090:	8ba1                	and	a5,a5,8
    80006092:	c3ed                	beqz	a5,80006174 <virtio_disk_init_bootloader+0x172>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006094:	100017b7          	lui	a5,0x10001
    80006098:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000609c:	43fc                	lw	a5,68(a5)
    8000609e:	2781                	sext.w	a5,a5
    800060a0:	e3f5                	bnez	a5,80006184 <virtio_disk_init_bootloader+0x182>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060a2:	100017b7          	lui	a5,0x10001
    800060a6:	5bdc                	lw	a5,52(a5)
    800060a8:	2781                	sext.w	a5,a5
  if(max == 0)
    800060aa:	c7ed                	beqz	a5,80006194 <virtio_disk_init_bootloader+0x192>
  if(max < NUM)
    800060ac:	471d                	li	a4,7
    800060ae:	0ef77b63          	bgeu	a4,a5,800061a4 <virtio_disk_init_bootloader+0x1a2>
  disk.desc  = (void*) 0x77000000;
    800060b2:	0001c497          	auipc	s1,0x1c
    800060b6:	19e48493          	add	s1,s1,414 # 80022250 <disk>
    800060ba:	770007b7          	lui	a5,0x77000
    800060be:	e09c                	sd	a5,0(s1)
  disk.avail = (void*) 0x77001000;
    800060c0:	770017b7          	lui	a5,0x77001
    800060c4:	e49c                	sd	a5,8(s1)
  disk.used  = (void*) 0x77002000;
    800060c6:	770027b7          	lui	a5,0x77002
    800060ca:	e89c                	sd	a5,16(s1)
  memset(disk.desc, 0, PGSIZE);
    800060cc:	6605                	lui	a2,0x1
    800060ce:	4581                	li	a1,0
    800060d0:	77000537          	lui	a0,0x77000
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	c70080e7          	jalr	-912(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060dc:	6605                	lui	a2,0x1
    800060de:	4581                	li	a1,0
    800060e0:	6488                	ld	a0,8(s1)
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	c62080e7          	jalr	-926(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    800060ea:	6605                	lui	a2,0x1
    800060ec:	4581                	li	a1,0
    800060ee:	6888                	ld	a0,16(s1)
    800060f0:	ffffb097          	auipc	ra,0xffffb
    800060f4:	c54080e7          	jalr	-940(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060f8:	100017b7          	lui	a5,0x10001
    800060fc:	4721                	li	a4,8
    800060fe:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006100:	4098                	lw	a4,0(s1)
    80006102:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006106:	40d8                	lw	a4,4(s1)
    80006108:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000610c:	6498                	ld	a4,8(s1)
    8000610e:	0007069b          	sext.w	a3,a4
    80006112:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006116:	9701                	sra	a4,a4,0x20
    80006118:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000611c:	6898                	ld	a4,16(s1)
    8000611e:	0007069b          	sext.w	a3,a4
    80006122:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006126:	9701                	sra	a4,a4,0x20
    80006128:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000612c:	4705                	li	a4,1
    8000612e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006130:	00e48c23          	sb	a4,24(s1)
    80006134:	00e48ca3          	sb	a4,25(s1)
    80006138:	00e48d23          	sb	a4,26(s1)
    8000613c:	00e48da3          	sb	a4,27(s1)
    80006140:	00e48e23          	sb	a4,28(s1)
    80006144:	00e48ea3          	sb	a4,29(s1)
    80006148:	00e48f23          	sb	a4,30(s1)
    8000614c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006150:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006154:	0727a823          	sw	s2,112(a5)
}
    80006158:	60e2                	ld	ra,24(sp)
    8000615a:	6442                	ld	s0,16(sp)
    8000615c:	64a2                	ld	s1,8(sp)
    8000615e:	6902                	ld	s2,0(sp)
    80006160:	6105                	add	sp,sp,32
    80006162:	8082                	ret
    panic("could not find virtio disk");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	6cc50513          	add	a0,a0,1740 # 80008830 <syscalls+0x398>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d4080e7          	jalr	980(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006174:	00002517          	auipc	a0,0x2
    80006178:	6dc50513          	add	a0,a0,1756 # 80008850 <syscalls+0x3b8>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c4080e7          	jalr	964(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006184:	00002517          	auipc	a0,0x2
    80006188:	6ec50513          	add	a0,a0,1772 # 80008870 <syscalls+0x3d8>
    8000618c:	ffffa097          	auipc	ra,0xffffa
    80006190:	3b4080e7          	jalr	948(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006194:	00002517          	auipc	a0,0x2
    80006198:	6fc50513          	add	a0,a0,1788 # 80008890 <syscalls+0x3f8>
    8000619c:	ffffa097          	auipc	ra,0xffffa
    800061a0:	3a4080e7          	jalr	932(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800061a4:	00002517          	auipc	a0,0x2
    800061a8:	70c50513          	add	a0,a0,1804 # 800088b0 <syscalls+0x418>
    800061ac:	ffffa097          	auipc	ra,0xffffa
    800061b0:	394080e7          	jalr	916(ra) # 80000540 <panic>

00000000800061b4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061b4:	7159                	add	sp,sp,-112
    800061b6:	f486                	sd	ra,104(sp)
    800061b8:	f0a2                	sd	s0,96(sp)
    800061ba:	eca6                	sd	s1,88(sp)
    800061bc:	e8ca                	sd	s2,80(sp)
    800061be:	e4ce                	sd	s3,72(sp)
    800061c0:	e0d2                	sd	s4,64(sp)
    800061c2:	fc56                	sd	s5,56(sp)
    800061c4:	f85a                	sd	s6,48(sp)
    800061c6:	f45e                	sd	s7,40(sp)
    800061c8:	f062                	sd	s8,32(sp)
    800061ca:	ec66                	sd	s9,24(sp)
    800061cc:	e86a                	sd	s10,16(sp)
    800061ce:	1880                	add	s0,sp,112
    800061d0:	8a2a                	mv	s4,a0
    800061d2:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061d4:	00c52c83          	lw	s9,12(a0)
    800061d8:	001c9c9b          	sllw	s9,s9,0x1
    800061dc:	1c82                	sll	s9,s9,0x20
    800061de:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061e2:	0001c517          	auipc	a0,0x1c
    800061e6:	19650513          	add	a0,a0,406 # 80022378 <disk+0x128>
    800061ea:	ffffb097          	auipc	ra,0xffffb
    800061ee:	a5e080e7          	jalr	-1442(ra) # 80000c48 <acquire>
  for(int i = 0; i < 3; i++){
    800061f2:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800061f4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061f6:	0001cb17          	auipc	s6,0x1c
    800061fa:	05ab0b13          	add	s6,s6,90 # 80022250 <disk>
  for(int i = 0; i < 3; i++){
    800061fe:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006200:	0001cc17          	auipc	s8,0x1c
    80006204:	178c0c13          	add	s8,s8,376 # 80022378 <disk+0x128>
    80006208:	a095                	j	8000626c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000620a:	00fb0733          	add	a4,s6,a5
    8000620e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006212:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006214:	0207c563          	bltz	a5,8000623e <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006218:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    8000621a:	0591                	add	a1,a1,4
    8000621c:	05560d63          	beq	a2,s5,80006276 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006220:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006222:	0001c717          	auipc	a4,0x1c
    80006226:	02e70713          	add	a4,a4,46 # 80022250 <disk>
    8000622a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000622c:	01874683          	lbu	a3,24(a4)
    80006230:	fee9                	bnez	a3,8000620a <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006232:	2785                	addw	a5,a5,1
    80006234:	0705                	add	a4,a4,1
    80006236:	fe979be3          	bne	a5,s1,8000622c <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    8000623a:	57fd                	li	a5,-1
    8000623c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000623e:	00c05e63          	blez	a2,8000625a <virtio_disk_rw+0xa6>
    80006242:	060a                	sll	a2,a2,0x2
    80006244:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006248:	0009a503          	lw	a0,0(s3)
    8000624c:	00000097          	auipc	ra,0x0
    80006250:	b4a080e7          	jalr	-1206(ra) # 80005d96 <free_desc>
      for(int j = 0; j < i; j++)
    80006254:	0991                	add	s3,s3,4
    80006256:	ffa999e3          	bne	s3,s10,80006248 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000625a:	85e2                	mv	a1,s8
    8000625c:	0001c517          	auipc	a0,0x1c
    80006260:	00c50513          	add	a0,a0,12 # 80022268 <disk+0x18>
    80006264:	ffffc097          	auipc	ra,0xffffc
    80006268:	e96080e7          	jalr	-362(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    8000626c:	f9040993          	add	s3,s0,-112
{
    80006270:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006272:	864a                	mv	a2,s2
    80006274:	b775                	j	80006220 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006276:	f9042503          	lw	a0,-112(s0)
    8000627a:	00a50713          	add	a4,a0,10
    8000627e:	0712                	sll	a4,a4,0x4

  if(write)
    80006280:	0001c797          	auipc	a5,0x1c
    80006284:	fd078793          	add	a5,a5,-48 # 80022250 <disk>
    80006288:	00e786b3          	add	a3,a5,a4
    8000628c:	01703633          	snez	a2,s7
    80006290:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006292:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006296:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000629a:	f6070613          	add	a2,a4,-160
    8000629e:	6394                	ld	a3,0(a5)
    800062a0:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062a2:	00870593          	add	a1,a4,8
    800062a6:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062a8:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062aa:	0007b803          	ld	a6,0(a5)
    800062ae:	9642                	add	a2,a2,a6
    800062b0:	46c1                	li	a3,16
    800062b2:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062b4:	4585                	li	a1,1
    800062b6:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800062ba:	f9442683          	lw	a3,-108(s0)
    800062be:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062c2:	0692                	sll	a3,a3,0x4
    800062c4:	9836                	add	a6,a6,a3
    800062c6:	058a0613          	add	a2,s4,88
    800062ca:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062ce:	0007b803          	ld	a6,0(a5)
    800062d2:	96c2                	add	a3,a3,a6
    800062d4:	40000613          	li	a2,1024
    800062d8:	c690                	sw	a2,8(a3)
  if(write)
    800062da:	001bb613          	seqz	a2,s7
    800062de:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062e2:	00166613          	or	a2,a2,1
    800062e6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062ea:	f9842603          	lw	a2,-104(s0)
    800062ee:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062f2:	00250693          	add	a3,a0,2
    800062f6:	0692                	sll	a3,a3,0x4
    800062f8:	96be                	add	a3,a3,a5
    800062fa:	58fd                	li	a7,-1
    800062fc:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006300:	0612                	sll	a2,a2,0x4
    80006302:	9832                	add	a6,a6,a2
    80006304:	f9070713          	add	a4,a4,-112
    80006308:	973e                	add	a4,a4,a5
    8000630a:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000630e:	6398                	ld	a4,0(a5)
    80006310:	9732                	add	a4,a4,a2
    80006312:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006314:	4609                	li	a2,2
    80006316:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    8000631a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000631e:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006322:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006326:	6794                	ld	a3,8(a5)
    80006328:	0026d703          	lhu	a4,2(a3)
    8000632c:	8b1d                	and	a4,a4,7
    8000632e:	0706                	sll	a4,a4,0x1
    80006330:	96ba                	add	a3,a3,a4
    80006332:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006336:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000633a:	6798                	ld	a4,8(a5)
    8000633c:	00275783          	lhu	a5,2(a4)
    80006340:	2785                	addw	a5,a5,1
    80006342:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006346:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000634a:	100017b7          	lui	a5,0x10001
    8000634e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006352:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006356:	0001c917          	auipc	s2,0x1c
    8000635a:	02290913          	add	s2,s2,34 # 80022378 <disk+0x128>
  while(b->disk == 1) {
    8000635e:	4485                	li	s1,1
    80006360:	00b79c63          	bne	a5,a1,80006378 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006364:	85ca                	mv	a1,s2
    80006366:	8552                	mv	a0,s4
    80006368:	ffffc097          	auipc	ra,0xffffc
    8000636c:	d92080e7          	jalr	-622(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    80006370:	004a2783          	lw	a5,4(s4)
    80006374:	fe9788e3          	beq	a5,s1,80006364 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006378:	f9042903          	lw	s2,-112(s0)
    8000637c:	00290713          	add	a4,s2,2
    80006380:	0712                	sll	a4,a4,0x4
    80006382:	0001c797          	auipc	a5,0x1c
    80006386:	ece78793          	add	a5,a5,-306 # 80022250 <disk>
    8000638a:	97ba                	add	a5,a5,a4
    8000638c:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006390:	0001c997          	auipc	s3,0x1c
    80006394:	ec098993          	add	s3,s3,-320 # 80022250 <disk>
    80006398:	00491713          	sll	a4,s2,0x4
    8000639c:	0009b783          	ld	a5,0(s3)
    800063a0:	97ba                	add	a5,a5,a4
    800063a2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063a6:	854a                	mv	a0,s2
    800063a8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063ac:	00000097          	auipc	ra,0x0
    800063b0:	9ea080e7          	jalr	-1558(ra) # 80005d96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063b4:	8885                	and	s1,s1,1
    800063b6:	f0ed                	bnez	s1,80006398 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063b8:	0001c517          	auipc	a0,0x1c
    800063bc:	fc050513          	add	a0,a0,-64 # 80022378 <disk+0x128>
    800063c0:	ffffb097          	auipc	ra,0xffffb
    800063c4:	93c080e7          	jalr	-1732(ra) # 80000cfc <release>
}
    800063c8:	70a6                	ld	ra,104(sp)
    800063ca:	7406                	ld	s0,96(sp)
    800063cc:	64e6                	ld	s1,88(sp)
    800063ce:	6946                	ld	s2,80(sp)
    800063d0:	69a6                	ld	s3,72(sp)
    800063d2:	6a06                	ld	s4,64(sp)
    800063d4:	7ae2                	ld	s5,56(sp)
    800063d6:	7b42                	ld	s6,48(sp)
    800063d8:	7ba2                	ld	s7,40(sp)
    800063da:	7c02                	ld	s8,32(sp)
    800063dc:	6ce2                	ld	s9,24(sp)
    800063de:	6d42                	ld	s10,16(sp)
    800063e0:	6165                	add	sp,sp,112
    800063e2:	8082                	ret

00000000800063e4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063e4:	1101                	add	sp,sp,-32
    800063e6:	ec06                	sd	ra,24(sp)
    800063e8:	e822                	sd	s0,16(sp)
    800063ea:	e426                	sd	s1,8(sp)
    800063ec:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063ee:	0001c497          	auipc	s1,0x1c
    800063f2:	e6248493          	add	s1,s1,-414 # 80022250 <disk>
    800063f6:	0001c517          	auipc	a0,0x1c
    800063fa:	f8250513          	add	a0,a0,-126 # 80022378 <disk+0x128>
    800063fe:	ffffb097          	auipc	ra,0xffffb
    80006402:	84a080e7          	jalr	-1974(ra) # 80000c48 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006406:	10001737          	lui	a4,0x10001
    8000640a:	533c                	lw	a5,96(a4)
    8000640c:	8b8d                	and	a5,a5,3
    8000640e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006410:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006414:	689c                	ld	a5,16(s1)
    80006416:	0204d703          	lhu	a4,32(s1)
    8000641a:	0027d783          	lhu	a5,2(a5)
    8000641e:	04f70863          	beq	a4,a5,8000646e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006422:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006426:	6898                	ld	a4,16(s1)
    80006428:	0204d783          	lhu	a5,32(s1)
    8000642c:	8b9d                	and	a5,a5,7
    8000642e:	078e                	sll	a5,a5,0x3
    80006430:	97ba                	add	a5,a5,a4
    80006432:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006434:	00278713          	add	a4,a5,2
    80006438:	0712                	sll	a4,a4,0x4
    8000643a:	9726                	add	a4,a4,s1
    8000643c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006440:	e721                	bnez	a4,80006488 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006442:	0789                	add	a5,a5,2
    80006444:	0792                	sll	a5,a5,0x4
    80006446:	97a6                	add	a5,a5,s1
    80006448:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000644a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000644e:	ffffc097          	auipc	ra,0xffffc
    80006452:	d10080e7          	jalr	-752(ra) # 8000215e <wakeup>

    disk.used_idx += 1;
    80006456:	0204d783          	lhu	a5,32(s1)
    8000645a:	2785                	addw	a5,a5,1
    8000645c:	17c2                	sll	a5,a5,0x30
    8000645e:	93c1                	srl	a5,a5,0x30
    80006460:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006464:	6898                	ld	a4,16(s1)
    80006466:	00275703          	lhu	a4,2(a4)
    8000646a:	faf71ce3          	bne	a4,a5,80006422 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000646e:	0001c517          	auipc	a0,0x1c
    80006472:	f0a50513          	add	a0,a0,-246 # 80022378 <disk+0x128>
    80006476:	ffffb097          	auipc	ra,0xffffb
    8000647a:	886080e7          	jalr	-1914(ra) # 80000cfc <release>
}
    8000647e:	60e2                	ld	ra,24(sp)
    80006480:	6442                	ld	s0,16(sp)
    80006482:	64a2                	ld	s1,8(sp)
    80006484:	6105                	add	sp,sp,32
    80006486:	8082                	ret
      panic("virtio_disk_intr status");
    80006488:	00002517          	auipc	a0,0x2
    8000648c:	46050513          	add	a0,a0,1120 # 800088e8 <syscalls+0x450>
    80006490:	ffffa097          	auipc	ra,0xffffa
    80006494:	0b0080e7          	jalr	176(ra) # 80000540 <panic>

0000000080006498 <ramdiskinit>:
/* TODO: find the location of the QEMU ramdisk. */
#define RAMDISK 0x84000000

void
ramdiskinit(void)
{
    80006498:	1141                	add	sp,sp,-16
    8000649a:	e422                	sd	s0,8(sp)
    8000649c:	0800                	add	s0,sp,16
}
    8000649e:	6422                	ld	s0,8(sp)
    800064a0:	0141                	add	sp,sp,16
    800064a2:	8082                	ret

00000000800064a4 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
    800064a4:	1101                	add	sp,sp,-32
    800064a6:	ec06                	sd	ra,24(sp)
    800064a8:	e822                	sd	s0,16(sp)
    800064aa:	e426                	sd	s1,8(sp)
    800064ac:	1000                	add	s0,sp,32
    panic("ramdiskrw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("ramdiskrw: nothing to do");
#endif

  if(b->blockno >= FSSIZE)
    800064ae:	454c                	lw	a1,12(a0)
    800064b0:	7cf00793          	li	a5,1999
    800064b4:	02b7ea63          	bltu	a5,a1,800064e8 <ramdiskrw+0x44>
    800064b8:	84aa                	mv	s1,a0
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    800064ba:	00a5959b          	sllw	a1,a1,0xa
    800064be:	1582                	sll	a1,a1,0x20
    800064c0:	9181                	srl	a1,a1,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
    800064c2:	40000613          	li	a2,1024
    800064c6:	02100793          	li	a5,33
    800064ca:	07ea                	sll	a5,a5,0x1a
    800064cc:	95be                	add	a1,a1,a5
    800064ce:	05850513          	add	a0,a0,88
    800064d2:	ffffb097          	auipc	ra,0xffffb
    800064d6:	8ce080e7          	jalr	-1842(ra) # 80000da0 <memmove>
  b->valid = 1;
    800064da:	4785                	li	a5,1
    800064dc:	c09c                	sw	a5,0(s1)
    // read
    memmove(b->data, addr, BSIZE);
    b->flags |= B_VALID;
  }
#endif
}
    800064de:	60e2                	ld	ra,24(sp)
    800064e0:	6442                	ld	s0,16(sp)
    800064e2:	64a2                	ld	s1,8(sp)
    800064e4:	6105                	add	sp,sp,32
    800064e6:	8082                	ret
    panic("ramdiskrw: blockno too big");
    800064e8:	00002517          	auipc	a0,0x2
    800064ec:	41850513          	add	a0,a0,1048 # 80008900 <syscalls+0x468>
    800064f0:	ffffa097          	auipc	ra,0xffffa
    800064f4:	050080e7          	jalr	80(ra) # 80000540 <panic>

00000000800064f8 <dump_hex>:
#include "fs.h"
#include "buf.h"
#include <stddef.h>

/* Acknowledgement: https://gist.github.com/ccbrown/9722406 */
void dump_hex(const void* data, size_t size) {
    800064f8:	7119                	add	sp,sp,-128
    800064fa:	fc86                	sd	ra,120(sp)
    800064fc:	f8a2                	sd	s0,112(sp)
    800064fe:	f4a6                	sd	s1,104(sp)
    80006500:	f0ca                	sd	s2,96(sp)
    80006502:	ecce                	sd	s3,88(sp)
    80006504:	e8d2                	sd	s4,80(sp)
    80006506:	e4d6                	sd	s5,72(sp)
    80006508:	e0da                	sd	s6,64(sp)
    8000650a:	fc5e                	sd	s7,56(sp)
    8000650c:	f862                	sd	s8,48(sp)
    8000650e:	f466                	sd	s9,40(sp)
    80006510:	0100                	add	s0,sp,128
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
    80006512:	f8040c23          	sb	zero,-104(s0)
	for (i = 0; i < size; ++i) {
    80006516:	c5e1                	beqz	a1,800065de <dump_hex+0xe6>
    80006518:	89ae                	mv	s3,a1
    8000651a:	892a                	mv	s2,a0
    8000651c:	4481                	li	s1,0
		printf("%x ", ((unsigned char*)data)[i]);
    8000651e:	00002a97          	auipc	s5,0x2
    80006522:	402a8a93          	add	s5,s5,1026 # 80008920 <syscalls+0x488>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    80006526:	05e00a13          	li	s4,94
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
    8000652a:	02e00b13          	li	s6,46
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
    8000652e:	00002c17          	auipc	s8,0x2
    80006532:	402c0c13          	add	s8,s8,1026 # 80008930 <syscalls+0x498>
			printf(" ");
    80006536:	00002b97          	auipc	s7,0x2
    8000653a:	3f2b8b93          	add	s7,s7,1010 # 80008928 <syscalls+0x490>
    8000653e:	a839                	j	8000655c <dump_hex+0x64>
			ascii[i % 16] = '.';
    80006540:	00f4f793          	and	a5,s1,15
    80006544:	fa078793          	add	a5,a5,-96
    80006548:	97a2                	add	a5,a5,s0
    8000654a:	ff678423          	sb	s6,-24(a5)
		if ((i+1) % 8 == 0 || i+1 == size) {
    8000654e:	0485                	add	s1,s1,1
    80006550:	0074f793          	and	a5,s1,7
    80006554:	cb9d                	beqz	a5,8000658a <dump_hex+0x92>
    80006556:	0b348a63          	beq	s1,s3,8000660a <dump_hex+0x112>
	for (i = 0; i < size; ++i) {
    8000655a:	0905                	add	s2,s2,1
		printf("%x ", ((unsigned char*)data)[i]);
    8000655c:	00094583          	lbu	a1,0(s2)
    80006560:	8556                	mv	a0,s5
    80006562:	ffffa097          	auipc	ra,0xffffa
    80006566:	028080e7          	jalr	40(ra) # 8000058a <printf>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    8000656a:	00094703          	lbu	a4,0(s2)
    8000656e:	fe07079b          	addw	a5,a4,-32
    80006572:	0ff7f793          	zext.b	a5,a5
    80006576:	fcfa65e3          	bltu	s4,a5,80006540 <dump_hex+0x48>
			ascii[i % 16] = ((unsigned char*)data)[i];
    8000657a:	00f4f793          	and	a5,s1,15
    8000657e:	fa078793          	add	a5,a5,-96
    80006582:	97a2                	add	a5,a5,s0
    80006584:	fee78423          	sb	a4,-24(a5)
    80006588:	b7d9                	j	8000654e <dump_hex+0x56>
			printf(" ");
    8000658a:	855e                	mv	a0,s7
    8000658c:	ffffa097          	auipc	ra,0xffffa
    80006590:	ffe080e7          	jalr	-2(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006594:	00f4fc93          	and	s9,s1,15
    80006598:	080c8263          	beqz	s9,8000661c <dump_hex+0x124>
			} else if (i+1 == size) {
    8000659c:	fb349fe3          	bne	s1,s3,8000655a <dump_hex+0x62>
				ascii[(i+1) % 16] = '\0';
    800065a0:	fa0c8793          	add	a5,s9,-96
    800065a4:	97a2                	add	a5,a5,s0
    800065a6:	fe078423          	sb	zero,-24(a5)
				if ((i+1) % 16 <= 8) {
    800065aa:	47a1                	li	a5,8
    800065ac:	0597f663          	bgeu	a5,s9,800065f8 <dump_hex+0x100>
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
    800065b0:	00002917          	auipc	s2,0x2
    800065b4:	38890913          	add	s2,s2,904 # 80008938 <syscalls+0x4a0>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065b8:	44bd                	li	s1,15
					printf("   ");
    800065ba:	854a                	mv	a0,s2
    800065bc:	ffffa097          	auipc	ra,0xffffa
    800065c0:	fce080e7          	jalr	-50(ra) # 8000058a <printf>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065c4:	0c85                	add	s9,s9,1
    800065c6:	ff94fae3          	bgeu	s1,s9,800065ba <dump_hex+0xc2>
				}
				printf("|  %s \n", ascii);
    800065ca:	f8840593          	add	a1,s0,-120
    800065ce:	00002517          	auipc	a0,0x2
    800065d2:	36250513          	add	a0,a0,866 # 80008930 <syscalls+0x498>
    800065d6:	ffffa097          	auipc	ra,0xffffa
    800065da:	fb4080e7          	jalr	-76(ra) # 8000058a <printf>
			}
		}
	}
    800065de:	70e6                	ld	ra,120(sp)
    800065e0:	7446                	ld	s0,112(sp)
    800065e2:	74a6                	ld	s1,104(sp)
    800065e4:	7906                	ld	s2,96(sp)
    800065e6:	69e6                	ld	s3,88(sp)
    800065e8:	6a46                	ld	s4,80(sp)
    800065ea:	6aa6                	ld	s5,72(sp)
    800065ec:	6b06                	ld	s6,64(sp)
    800065ee:	7be2                	ld	s7,56(sp)
    800065f0:	7c42                	ld	s8,48(sp)
    800065f2:	7ca2                	ld	s9,40(sp)
    800065f4:	6109                	add	sp,sp,128
    800065f6:	8082                	ret
					printf(" ");
    800065f8:	00002517          	auipc	a0,0x2
    800065fc:	33050513          	add	a0,a0,816 # 80008928 <syscalls+0x490>
    80006600:	ffffa097          	auipc	ra,0xffffa
    80006604:	f8a080e7          	jalr	-118(ra) # 8000058a <printf>
    80006608:	b765                	j	800065b0 <dump_hex+0xb8>
			printf(" ");
    8000660a:	855e                	mv	a0,s7
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	f7e080e7          	jalr	-130(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006614:	00f9fc93          	and	s9,s3,15
    80006618:	f80c94e3          	bnez	s9,800065a0 <dump_hex+0xa8>
				printf("|  %s \n", ascii);
    8000661c:	f8840593          	add	a1,s0,-120
    80006620:	8562                	mv	a0,s8
    80006622:	ffffa097          	auipc	ra,0xffffa
    80006626:	f68080e7          	jalr	-152(ra) # 8000058a <printf>
	for (i = 0; i < size; ++i) {
    8000662a:	fb348ae3          	beq	s1,s3,800065de <dump_hex+0xe6>
    8000662e:	0905                	add	s2,s2,1
    80006630:	b735                	j	8000655c <dump_hex+0x64>

0000000080006632 <check_status_registers>:
//     }
//     printf("\nget_register_by_code: found nothing %x \n", code);
//     return NULL;
// };

struct vm_reg* check_status_registers(uint32 code){
    80006632:	1141                	add	sp,sp,-16
    80006634:	e422                	sd	s0,8(sp)
    80006636:	0800                	add	s0,sp,16
    switch(code) {
    80006638:	10200713          	li	a4,258
    8000663c:	02e50163          	beq	a0,a4,8000665e <check_status_registers+0x2c>
    80006640:	87aa                	mv	a5,a0
    80006642:	30200713          	li	a4,770
    80006646:	4501                	li	a0,0
    80006648:	00e79863          	bne	a5,a4,80006658 <check_status_registers+0x26>
        case 0x302:
            return &(vm_state->mstatus);
    8000664c:	00002517          	auipc	a0,0x2
    80006650:	6cc53503          	ld	a0,1740(a0) # 80008d18 <vm_state>
    80006654:	15850513          	add	a0,a0,344
        case 0x102:
            return &(vm_state->sstatus);
        default:
            return 0;
    }       
}
    80006658:	6422                	ld	s0,8(sp)
    8000665a:	0141                	add	sp,sp,16
    8000665c:	8082                	ret
            return &(vm_state->sstatus);
    8000665e:	00002517          	auipc	a0,0x2
    80006662:	6ba53503          	ld	a0,1722(a0) # 80008d18 <vm_state>
    80006666:	6785                	lui	a5,0x1
    80006668:	2f878793          	add	a5,a5,760 # 12f8 <_entry-0x7fffed08>
    8000666c:	953e                	add	a0,a0,a5
    8000666e:	b7ed                	j	80006658 <check_status_registers+0x26>

0000000080006670 <get_register_by_code>:

struct vm_reg* get_register_by_code(uint32 code) {
    switch(code) {
    80006670:	18000793          	li	a5,384
    80006674:	0cf50d63          	beq	a0,a5,8000674e <get_register_by_code+0xde>
    80006678:	02a7f863          	bgeu	a5,a0,800066a8 <get_register_by_code+0x38>
    8000667c:	30300793          	li	a5,771
    80006680:	0ef50763          	beq	a0,a5,8000676e <get_register_by_code+0xfe>
    80006684:	08a7fd63          	bgeu	a5,a0,8000671e <get_register_by_code+0xae>
    80006688:	34100793          	li	a5,833
    8000668c:	0cf50a63          	beq	a0,a5,80006760 <get_register_by_code+0xf0>
    80006690:	6785                	lui	a5,0x1
    80006692:	f1478793          	add	a5,a5,-236 # f14 <_entry-0x7ffff0ec>
    80006696:	10f51e63          	bne	a0,a5,800067b2 <get_register_by_code+0x142>
        case 0xf14:
            return &(vm_state->mhartid);
    8000669a:	00002517          	auipc	a0,0x2
    8000669e:	67e53503          	ld	a0,1662(a0) # 80008d18 <vm_state>
    800066a2:	36850513          	add	a0,a0,872
    800066a6:	8082                	ret
    switch(code) {
    800066a8:	10400793          	li	a5,260
    800066ac:	0cf50863          	beq	a0,a5,8000677c <get_register_by_code+0x10c>
    800066b0:	04a7f263          	bgeu	a5,a0,800066f4 <get_register_by_code+0x84>
    800066b4:	10500793          	li	a5,261
    800066b8:	0cf50b63          	beq	a0,a5,8000678e <get_register_by_code+0x11e>
    800066bc:	14100793          	li	a5,321
    800066c0:	04f51d63          	bne	a0,a5,8000671a <get_register_by_code+0xaa>
struct vm_reg* get_register_by_code(uint32 code) {
    800066c4:	1141                	add	sp,sp,-16
    800066c6:	e406                	sd	ra,8(sp)
    800066c8:	e022                	sd	s0,0(sp)
    800066ca:	0800                	add	s0,sp,16
        case 0x105:
            return &(vm_state->stvec);
        case 0x100:
            return &(vm_state->sstatus);
        case 0x141:
            printf("sepc called");
    800066cc:	00002517          	auipc	a0,0x2
    800066d0:	27450513          	add	a0,a0,628 # 80008940 <syscalls+0x4a8>
    800066d4:	ffffa097          	auipc	ra,0xffffa
    800066d8:	eb6080e7          	jalr	-330(ra) # 8000058a <printf>
            return &(vm_state->sepc);
    800066dc:	00002517          	auipc	a0,0x2
    800066e0:	63c53503          	ld	a0,1596(a0) # 80008d18 <vm_state>
    800066e4:	6785                	lui	a5,0x1
    800066e6:	3e878793          	add	a5,a5,1000 # 13e8 <_entry-0x7fffec18>
    800066ea:	953e                	add	a0,a0,a5
        case 0x102:
            return &(vm_state->sedeleg);
        default:
            return 0;
    }
}
    800066ec:	60a2                	ld	ra,8(sp)
    800066ee:	6402                	ld	s0,0(sp)
    800066f0:	0141                	add	sp,sp,16
    800066f2:	8082                	ret
    switch(code) {
    800066f4:	10000793          	li	a5,256
    800066f8:	0af50463          	beq	a0,a5,800067a0 <get_register_by_code+0x130>
    800066fc:	10200793          	li	a5,258
    80006700:	00f51b63          	bne	a0,a5,80006716 <get_register_by_code+0xa6>
            return &(vm_state->sedeleg);
    80006704:	00002517          	auipc	a0,0x2
    80006708:	61453503          	ld	a0,1556(a0) # 80008d18 <vm_state>
    8000670c:	6785                	lui	a5,0x1
    8000670e:	32878793          	add	a5,a5,808 # 1328 <_entry-0x7fffecd8>
    80006712:	953e                	add	a0,a0,a5
    80006714:	8082                	ret
    switch(code) {
    80006716:	4501                	li	a0,0
    80006718:	8082                	ret
    8000671a:	4501                	li	a0,0
    8000671c:	8082                	ret
    8000671e:	30000793          	li	a5,768
    80006722:	00f50f63          	beq	a0,a5,80006740 <get_register_by_code+0xd0>
    80006726:	30200793          	li	a5,770
    8000672a:	00f51963          	bne	a0,a5,8000673c <get_register_by_code+0xcc>
            return &(vm_state->medeleg);
    8000672e:	00002517          	auipc	a0,0x2
    80006732:	5ea53503          	ld	a0,1514(a0) # 80008d18 <vm_state>
    80006736:	1b850513          	add	a0,a0,440
    8000673a:	8082                	ret
    switch(code) {
    8000673c:	4501                	li	a0,0
    8000673e:	8082                	ret
            return &(vm_state->mstatus);
    80006740:	00002517          	auipc	a0,0x2
    80006744:	5d853503          	ld	a0,1496(a0) # 80008d18 <vm_state>
    80006748:	15850513          	add	a0,a0,344
    8000674c:	8082                	ret
            return &(vm_state->satp);
    8000674e:	00002517          	auipc	a0,0x2
    80006752:	5ca53503          	ld	a0,1482(a0) # 80008d18 <vm_state>
    80006756:	6785                	lui	a5,0x1
    80006758:	2c878793          	add	a5,a5,712 # 12c8 <_entry-0x7fffed38>
    8000675c:	953e                	add	a0,a0,a5
    8000675e:	8082                	ret
            return &(vm_state->mepc);
    80006760:	00002517          	auipc	a0,0x2
    80006764:	5b853503          	ld	a0,1464(a0) # 80008d18 <vm_state>
    80006768:	03850513          	add	a0,a0,56
    8000676c:	8082                	ret
            return &(vm_state->mideleg);
    8000676e:	00002517          	auipc	a0,0x2
    80006772:	5aa53503          	ld	a0,1450(a0) # 80008d18 <vm_state>
    80006776:	1e850513          	add	a0,a0,488
    8000677a:	8082                	ret
            return &(vm_state->sie);
    8000677c:	00002517          	auipc	a0,0x2
    80006780:	59c53503          	ld	a0,1436(a0) # 80008d18 <vm_state>
    80006784:	6785                	lui	a5,0x1
    80006786:	35878793          	add	a5,a5,856 # 1358 <_entry-0x7fffeca8>
    8000678a:	953e                	add	a0,a0,a5
    8000678c:	8082                	ret
            return &(vm_state->stvec);
    8000678e:	00002517          	auipc	a0,0x2
    80006792:	58a53503          	ld	a0,1418(a0) # 80008d18 <vm_state>
    80006796:	6785                	lui	a5,0x1
    80006798:	38878793          	add	a5,a5,904 # 1388 <_entry-0x7fffec78>
    8000679c:	953e                	add	a0,a0,a5
    8000679e:	8082                	ret
            return &(vm_state->sstatus);
    800067a0:	00002517          	auipc	a0,0x2
    800067a4:	57853503          	ld	a0,1400(a0) # 80008d18 <vm_state>
    800067a8:	6785                	lui	a5,0x1
    800067aa:	2f878793          	add	a5,a5,760 # 12f8 <_entry-0x7fffed08>
    800067ae:	953e                	add	a0,a0,a5
    800067b0:	8082                	ret
    switch(code) {
    800067b2:	4501                	li	a0,0
}
    800067b4:	8082                	ret

00000000800067b6 <write_to_vm_register>:

void write_to_vm_register(uint32 code, uint64 value) {
    800067b6:	1101                	add	sp,sp,-32
    800067b8:	ec06                	sd	ra,24(sp)
    800067ba:	e822                	sd	s0,16(sp)
    800067bc:	e426                	sd	s1,8(sp)
    800067be:	1000                	add	s0,sp,32
    800067c0:	84ae                	mv	s1,a1
    switch(code) {
    800067c2:	18000793          	li	a5,384
    800067c6:	10f50c63          	beq	a0,a5,800068de <write_to_vm_register+0x128>
    800067ca:	04a7f463          	bgeu	a5,a0,80006812 <write_to_vm_register+0x5c>
    800067ce:	30300793          	li	a5,771
    800067d2:	14f50563          	beq	a0,a5,8000691c <write_to_vm_register+0x166>
    800067d6:	0aa7fe63          	bgeu	a5,a0,80006892 <write_to_vm_register+0xdc>
    800067da:	34100793          	li	a5,833
    800067de:	12f50163          	beq	a0,a5,80006900 <write_to_vm_register+0x14a>
    800067e2:	6785                	lui	a5,0x1
    800067e4:	f1478793          	add	a5,a5,-236 # f14 <_entry-0x7ffff0ec>
    800067e8:	02f51063          	bne	a0,a5,80006808 <write_to_vm_register+0x52>
        case 0xf14:
            printf("\nvalue %x -> mhartid\n", value);
    800067ec:	00002517          	auipc	a0,0x2
    800067f0:	16450513          	add	a0,a0,356 # 80008950 <syscalls+0x4b8>
    800067f4:	ffffa097          	auipc	ra,0xffffa
    800067f8:	d96080e7          	jalr	-618(ra) # 8000058a <printf>
            vm_state->mhartid.val = value;
    800067fc:	00002797          	auipc	a5,0x2
    80006800:	51c7b783          	ld	a5,1308(a5) # 80008d18 <vm_state>
    80006804:	3697b823          	sd	s1,880(a5)
            vm_state->sedeleg.val = value;
            break;
        default:
            break;
    }
}
    80006808:	60e2                	ld	ra,24(sp)
    8000680a:	6442                	ld	s0,16(sp)
    8000680c:	64a2                	ld	s1,8(sp)
    8000680e:	6105                	add	sp,sp,32
    80006810:	8082                	ret
    switch(code) {
    80006812:	10400793          	li	a5,260
    80006816:	12f50263          	beq	a0,a5,8000693a <write_to_vm_register+0x184>
    8000681a:	04a7f363          	bgeu	a5,a0,80006860 <write_to_vm_register+0xaa>
    8000681e:	10500793          	li	a5,261
    80006822:	12f50d63          	beq	a0,a5,8000695c <write_to_vm_register+0x1a6>
    80006826:	14100793          	li	a5,321
    8000682a:	fcf51fe3          	bne	a0,a5,80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> sepc\n", value);
    8000682e:	00002517          	auipc	a0,0x2
    80006832:	1fa50513          	add	a0,a0,506 # 80008a28 <syscalls+0x590>
    80006836:	ffffa097          	auipc	ra,0xffffa
    8000683a:	d54080e7          	jalr	-684(ra) # 8000058a <printf>
            printf("sepc called");
    8000683e:	00002517          	auipc	a0,0x2
    80006842:	10250513          	add	a0,a0,258 # 80008940 <syscalls+0x4a8>
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	d44080e7          	jalr	-700(ra) # 8000058a <printf>
            vm_state->sepc.val = value;
    8000684e:	00002797          	auipc	a5,0x2
    80006852:	4ca7b783          	ld	a5,1226(a5) # 80008d18 <vm_state>
    80006856:	6705                	lui	a4,0x1
    80006858:	97ba                	add	a5,a5,a4
    8000685a:	3e97b823          	sd	s1,1008(a5)
            break;
    8000685e:	b76d                	j	80006808 <write_to_vm_register+0x52>
    switch(code) {
    80006860:	10000793          	li	a5,256
    80006864:	10f50d63          	beq	a0,a5,8000697e <write_to_vm_register+0x1c8>
    80006868:	10200793          	li	a5,258
    8000686c:	f8f51ee3          	bne	a0,a5,80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> sedeleg\n", value);
    80006870:	00002517          	auipc	a0,0x2
    80006874:	1d050513          	add	a0,a0,464 # 80008a40 <syscalls+0x5a8>
    80006878:	ffffa097          	auipc	ra,0xffffa
    8000687c:	d12080e7          	jalr	-750(ra) # 8000058a <printf>
            vm_state->sedeleg.val = value;
    80006880:	00002797          	auipc	a5,0x2
    80006884:	4987b783          	ld	a5,1176(a5) # 80008d18 <vm_state>
    80006888:	6705                	lui	a4,0x1
    8000688a:	97ba                	add	a5,a5,a4
    8000688c:	3297b823          	sd	s1,816(a5)
}
    80006890:	bfa5                	j	80006808 <write_to_vm_register+0x52>
    switch(code) {
    80006892:	30000793          	li	a5,768
    80006896:	02f50563          	beq	a0,a5,800068c0 <write_to_vm_register+0x10a>
    8000689a:	30200793          	li	a5,770
    8000689e:	f6f515e3          	bne	a0,a5,80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> medeleg\n", value);
    800068a2:	00002517          	auipc	a0,0x2
    800068a6:	10e50513          	add	a0,a0,270 # 800089b0 <syscalls+0x518>
    800068aa:	ffffa097          	auipc	ra,0xffffa
    800068ae:	ce0080e7          	jalr	-800(ra) # 8000058a <printf>
            vm_state->medeleg.val = value;
    800068b2:	00002797          	auipc	a5,0x2
    800068b6:	4667b783          	ld	a5,1126(a5) # 80008d18 <vm_state>
    800068ba:	1c97b023          	sd	s1,448(a5)
            break;
    800068be:	b7a9                	j	80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> mstatus\n", value);
    800068c0:	00002517          	auipc	a0,0x2
    800068c4:	0a850513          	add	a0,a0,168 # 80008968 <syscalls+0x4d0>
    800068c8:	ffffa097          	auipc	ra,0xffffa
    800068cc:	cc2080e7          	jalr	-830(ra) # 8000058a <printf>
            vm_state->mstatus.val = value ;
    800068d0:	00002797          	auipc	a5,0x2
    800068d4:	4487b783          	ld	a5,1096(a5) # 80008d18 <vm_state>
    800068d8:	1697b023          	sd	s1,352(a5)
            break;
    800068dc:	b735                	j	80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> satp\n", value);
    800068de:	00002517          	auipc	a0,0x2
    800068e2:	0a250513          	add	a0,a0,162 # 80008980 <syscalls+0x4e8>
    800068e6:	ffffa097          	auipc	ra,0xffffa
    800068ea:	ca4080e7          	jalr	-860(ra) # 8000058a <printf>
            vm_state->satp.val = value;
    800068ee:	00002797          	auipc	a5,0x2
    800068f2:	42a7b783          	ld	a5,1066(a5) # 80008d18 <vm_state>
    800068f6:	6705                	lui	a4,0x1
    800068f8:	97ba                	add	a5,a5,a4
    800068fa:	2c97b823          	sd	s1,720(a5)
            break;
    800068fe:	b729                	j	80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> mepc\n", value);
    80006900:	00002517          	auipc	a0,0x2
    80006904:	09850513          	add	a0,a0,152 # 80008998 <syscalls+0x500>
    80006908:	ffffa097          	auipc	ra,0xffffa
    8000690c:	c82080e7          	jalr	-894(ra) # 8000058a <printf>
            vm_state->mepc.val = value;
    80006910:	00002797          	auipc	a5,0x2
    80006914:	4087b783          	ld	a5,1032(a5) # 80008d18 <vm_state>
    80006918:	e3a4                	sd	s1,64(a5)
            break;
    8000691a:	b5fd                	j	80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> mideleg\n", value);
    8000691c:	00002517          	auipc	a0,0x2
    80006920:	0ac50513          	add	a0,a0,172 # 800089c8 <syscalls+0x530>
    80006924:	ffffa097          	auipc	ra,0xffffa
    80006928:	c66080e7          	jalr	-922(ra) # 8000058a <printf>
            vm_state->mideleg.val = value;
    8000692c:	00002797          	auipc	a5,0x2
    80006930:	3ec7b783          	ld	a5,1004(a5) # 80008d18 <vm_state>
    80006934:	1e97b823          	sd	s1,496(a5)
            break;
    80006938:	bdc1                	j	80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> sie\n", value);
    8000693a:	00002517          	auipc	a0,0x2
    8000693e:	0a650513          	add	a0,a0,166 # 800089e0 <syscalls+0x548>
    80006942:	ffffa097          	auipc	ra,0xffffa
    80006946:	c48080e7          	jalr	-952(ra) # 8000058a <printf>
            vm_state->sie.val = value;
    8000694a:	00002797          	auipc	a5,0x2
    8000694e:	3ce7b783          	ld	a5,974(a5) # 80008d18 <vm_state>
    80006952:	6705                	lui	a4,0x1
    80006954:	97ba                	add	a5,a5,a4
    80006956:	3697b023          	sd	s1,864(a5)
            break;
    8000695a:	b57d                	j	80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> stvec\n", value);
    8000695c:	00002517          	auipc	a0,0x2
    80006960:	09c50513          	add	a0,a0,156 # 800089f8 <syscalls+0x560>
    80006964:	ffffa097          	auipc	ra,0xffffa
    80006968:	c26080e7          	jalr	-986(ra) # 8000058a <printf>
            vm_state->stvec.val = value;
    8000696c:	00002797          	auipc	a5,0x2
    80006970:	3ac7b783          	ld	a5,940(a5) # 80008d18 <vm_state>
    80006974:	6705                	lui	a4,0x1
    80006976:	97ba                	add	a5,a5,a4
    80006978:	3897b823          	sd	s1,912(a5)
            break;
    8000697c:	b571                	j	80006808 <write_to_vm_register+0x52>
            printf("\nvalue %x -> sstatus\n", value);
    8000697e:	00002517          	auipc	a0,0x2
    80006982:	09250513          	add	a0,a0,146 # 80008a10 <syscalls+0x578>
    80006986:	ffffa097          	auipc	ra,0xffffa
    8000698a:	c04080e7          	jalr	-1020(ra) # 8000058a <printf>
            vm_state->sstatus.val = value;
    8000698e:	00002797          	auipc	a5,0x2
    80006992:	38a7b783          	ld	a5,906(a5) # 80008d18 <vm_state>
    80006996:	6705                	lui	a4,0x1
    80006998:	97ba                	add	a5,a5,a4
    8000699a:	3097b023          	sd	s1,768(a5)
            break;
    8000699e:	b5ad                	j	80006808 <write_to_vm_register+0x52>

00000000800069a0 <get_trapframe_register>:

uint64 get_trapframe_register(uint64 code){
    800069a0:	1101                	add	sp,sp,-32
    800069a2:	ec06                	sd	ra,24(sp)
    800069a4:	e822                	sd	s0,16(sp)
    800069a6:	e426                	sd	s1,8(sp)
    800069a8:	1000                	add	s0,sp,32
    800069aa:	84aa                	mv	s1,a0
    struct proc* p = myproc();
    800069ac:	ffffb097          	auipc	ra,0xffffb
    800069b0:	078080e7          	jalr	120(ra) # 80001a24 <myproc>
    switch(code) {
    800069b4:	47bd                	li	a5,15
    800069b6:	0297ed63          	bltu	a5,s1,800069f0 <get_trapframe_register+0x50>
    800069ba:	048a                	sll	s1,s1,0x2
    800069bc:	00002717          	auipc	a4,0x2
    800069c0:	27c70713          	add	a4,a4,636 # 80008c38 <syscalls+0x7a0>
    800069c4:	94ba                	add	s1,s1,a4
    800069c6:	409c                	lw	a5,0(s1)
    800069c8:	97ba                	add	a5,a5,a4
    800069ca:	8782                	jr	a5
        case 0xa:
            return (p->trapframe->a0);
    800069cc:	6d3c                	ld	a5,88(a0)
    800069ce:	7ba8                	ld	a0,112(a5)
    800069d0:	a00d                	j	800069f2 <get_trapframe_register+0x52>
        case 0xb:
            return (p->trapframe->a1);
    800069d2:	6d3c                	ld	a5,88(a0)
    800069d4:	7fa8                	ld	a0,120(a5)
    800069d6:	a831                	j	800069f2 <get_trapframe_register+0x52>
        case 0xc:
            return (p->trapframe->a2);
    800069d8:	6d3c                	ld	a5,88(a0)
    800069da:	63c8                	ld	a0,128(a5)
    800069dc:	a819                	j	800069f2 <get_trapframe_register+0x52>
        case 0xd:
            return (p->trapframe->a3);
    800069de:	6d3c                	ld	a5,88(a0)
    800069e0:	67c8                	ld	a0,136(a5)
    800069e2:	a801                	j	800069f2 <get_trapframe_register+0x52>
        case 0xe:
            return (p->trapframe->a4);
    800069e4:	6d3c                	ld	a5,88(a0)
    800069e6:	6bc8                	ld	a0,144(a5)
    800069e8:	a029                	j	800069f2 <get_trapframe_register+0x52>
        case 0xf:
        case 0x1:
            return (p->trapframe->a5);
    800069ea:	6d3c                	ld	a5,88(a0)
    800069ec:	6fc8                	ld	a0,152(a5)
    800069ee:	a011                	j	800069f2 <get_trapframe_register+0x52>
    switch(code) {
    800069f0:	4501                	li	a0,0
        default:
            return 0;
    }
}
    800069f2:	60e2                	ld	ra,24(sp)
    800069f4:	6442                	ld	s0,16(sp)
    800069f6:	64a2                	ld	s1,8(sp)
    800069f8:	6105                	add	sp,sp,32
    800069fa:	8082                	ret

00000000800069fc <write_to_trapframe_register>:

void write_to_trapframe_register(uint32 code, uint64 value) {
    800069fc:	7179                	add	sp,sp,-48
    800069fe:	f406                	sd	ra,40(sp)
    80006a00:	f022                	sd	s0,32(sp)
    80006a02:	ec26                	sd	s1,24(sp)
    80006a04:	e84a                	sd	s2,16(sp)
    80006a06:	e44e                	sd	s3,8(sp)
    80006a08:	1800                	add	s0,sp,48
    80006a0a:	84aa                	mv	s1,a0
    80006a0c:	892e                	mv	s2,a1
    struct proc* p = myproc();
    80006a0e:	ffffb097          	auipc	ra,0xffffb
    80006a12:	016080e7          	jalr	22(ra) # 80001a24 <myproc>
    80006a16:	89aa                	mv	s3,a0
    printf("\nstarting write\n");
    80006a18:	00002517          	auipc	a0,0x2
    80006a1c:	04050513          	add	a0,a0,64 # 80008a58 <syscalls+0x5c0>
    80006a20:	ffffa097          	auipc	ra,0xffffa
    80006a24:	b6a080e7          	jalr	-1174(ra) # 8000058a <printf>
    switch(code) {
    80006a28:	ff64879b          	addw	a5,s1,-10
    80006a2c:	0007869b          	sext.w	a3,a5
    80006a30:	4715                	li	a4,5
    80006a32:	0cd76863          	bltu	a4,a3,80006b02 <write_to_trapframe_register+0x106>
    80006a36:	02079713          	sll	a4,a5,0x20
    80006a3a:	01e75793          	srl	a5,a4,0x1e
    80006a3e:	00002717          	auipc	a4,0x2
    80006a42:	23a70713          	add	a4,a4,570 # 80008c78 <syscalls+0x7e0>
    80006a46:	97ba                	add	a5,a5,a4
    80006a48:	439c                	lw	a5,0(a5)
    80006a4a:	97ba                	add	a5,a5,a4
    80006a4c:	8782                	jr	a5
        case 0xa:
            printf("\nvalue %x -> a0\n", value);
    80006a4e:	85ca                	mv	a1,s2
    80006a50:	00002517          	auipc	a0,0x2
    80006a54:	02050513          	add	a0,a0,32 # 80008a70 <syscalls+0x5d8>
    80006a58:	ffffa097          	auipc	ra,0xffffa
    80006a5c:	b32080e7          	jalr	-1230(ra) # 8000058a <printf>
            p->trapframe->a0 = value;
    80006a60:	0589b783          	ld	a5,88(s3)
    80006a64:	0727b823          	sd	s2,112(a5)
            break;
        default:
            printf("\ngoing to break\n");
            break;
    }
}
    80006a68:	70a2                	ld	ra,40(sp)
    80006a6a:	7402                	ld	s0,32(sp)
    80006a6c:	64e2                	ld	s1,24(sp)
    80006a6e:	6942                	ld	s2,16(sp)
    80006a70:	69a2                	ld	s3,8(sp)
    80006a72:	6145                	add	sp,sp,48
    80006a74:	8082                	ret
            printf("\nvalue %x -> a1\n", value);
    80006a76:	85ca                	mv	a1,s2
    80006a78:	00002517          	auipc	a0,0x2
    80006a7c:	01050513          	add	a0,a0,16 # 80008a88 <syscalls+0x5f0>
    80006a80:	ffffa097          	auipc	ra,0xffffa
    80006a84:	b0a080e7          	jalr	-1270(ra) # 8000058a <printf>
            p->trapframe->a1 = value;
    80006a88:	0589b783          	ld	a5,88(s3)
    80006a8c:	0727bc23          	sd	s2,120(a5)
            break;
    80006a90:	bfe1                	j	80006a68 <write_to_trapframe_register+0x6c>
            printf("\nvalue %x -> a2\n", value);
    80006a92:	85ca                	mv	a1,s2
    80006a94:	00002517          	auipc	a0,0x2
    80006a98:	00c50513          	add	a0,a0,12 # 80008aa0 <syscalls+0x608>
    80006a9c:	ffffa097          	auipc	ra,0xffffa
    80006aa0:	aee080e7          	jalr	-1298(ra) # 8000058a <printf>
            p->trapframe->a2 = value;
    80006aa4:	0589b783          	ld	a5,88(s3)
    80006aa8:	0927b023          	sd	s2,128(a5)
            break;
    80006aac:	bf75                	j	80006a68 <write_to_trapframe_register+0x6c>
            printf("\nvalue %x -> a3\n", value);
    80006aae:	85ca                	mv	a1,s2
    80006ab0:	00002517          	auipc	a0,0x2
    80006ab4:	00850513          	add	a0,a0,8 # 80008ab8 <syscalls+0x620>
    80006ab8:	ffffa097          	auipc	ra,0xffffa
    80006abc:	ad2080e7          	jalr	-1326(ra) # 8000058a <printf>
            p->trapframe->a3 = value;
    80006ac0:	0589b783          	ld	a5,88(s3)
    80006ac4:	0927b423          	sd	s2,136(a5)
            break;
    80006ac8:	b745                	j	80006a68 <write_to_trapframe_register+0x6c>
            printf("\nvalue %x -> a4\n", value);
    80006aca:	85ca                	mv	a1,s2
    80006acc:	00002517          	auipc	a0,0x2
    80006ad0:	00450513          	add	a0,a0,4 # 80008ad0 <syscalls+0x638>
    80006ad4:	ffffa097          	auipc	ra,0xffffa
    80006ad8:	ab6080e7          	jalr	-1354(ra) # 8000058a <printf>
            p->trapframe->a4 = value;
    80006adc:	0589b783          	ld	a5,88(s3)
    80006ae0:	0927b823          	sd	s2,144(a5)
            break;
    80006ae4:	b751                	j	80006a68 <write_to_trapframe_register+0x6c>
            printf("\nvalue %x -> a5\n", value);
    80006ae6:	85ca                	mv	a1,s2
    80006ae8:	00002517          	auipc	a0,0x2
    80006aec:	00050513          	mv	a0,a0
    80006af0:	ffffa097          	auipc	ra,0xffffa
    80006af4:	a9a080e7          	jalr	-1382(ra) # 8000058a <printf>
            p->trapframe->a5 = value;
    80006af8:	0589b783          	ld	a5,88(s3)
    80006afc:	0927bc23          	sd	s2,152(a5)
            break;
    80006b00:	b7a5                	j	80006a68 <write_to_trapframe_register+0x6c>
            printf("\ngoing to break\n");
    80006b02:	00002517          	auipc	a0,0x2
    80006b06:	ffe50513          	add	a0,a0,-2 # 80008b00 <syscalls+0x668>
    80006b0a:	ffffa097          	auipc	ra,0xffffa
    80006b0e:	a80080e7          	jalr	-1408(ra) # 8000058a <printf>
}
    80006b12:	bf99                	j	80006a68 <write_to_trapframe_register+0x6c>

0000000080006b14 <trap_and_emulate>:

void trap_and_emulate(void) {
    80006b14:	7139                	add	sp,sp,-64
    80006b16:	fc06                	sd	ra,56(sp)
    80006b18:	f822                	sd	s0,48(sp)
    80006b1a:	f426                	sd	s1,40(sp)
    80006b1c:	f04a                	sd	s2,32(sp)
    80006b1e:	ec4e                	sd	s3,24(sp)
    80006b20:	e852                	sd	s4,16(sp)
    80006b22:	e456                	sd	s5,8(sp)
    80006b24:	e05a                	sd	s6,0(sp)
    80006b26:	0080                	add	s0,sp,64
    /* Comes here when a VM tries to execute a supervisor instruction. */
    struct proc* p = myproc();
    80006b28:	ffffb097          	auipc	ra,0xffffb
    80006b2c:	efc080e7          	jalr	-260(ra) # 80001a24 <myproc>
    80006b30:	8a2a                	mv	s4,a0
    80006b32:	14302673          	csrr	a2,stval
    // struct isa *isa_temp = (struct isa*) p->trapframe->epc;
    // uint32 instr = *(uint32*)(myproc()->trapframe->epc + KERNBASE);
    uint64 instr = r_stval();
    uint64 addr     = p->trapframe->epc;
    uint32 op       = instr & 0x7F;
    uint32 rd       = (instr >> 7) & 0x1F;
    80006b36:	00765693          	srl	a3,a2,0x7
    80006b3a:	0006849b          	sext.w	s1,a3
    80006b3e:	01f6f993          	and	s3,a3,31
    uint32 funct3   = (instr >> 12) & 0x7;
    uint32 rs1      = (instr >> 15) & 0x1F;
    80006b42:	00f65793          	srl	a5,a2,0xf
    80006b46:	00078b1b          	sext.w	s6,a5
    80006b4a:	01f7f913          	and	s2,a5,31
    uint32 uimm     = (instr >> 20) & 0xFFF;
    80006b4e:	01465a9b          	srlw	s5,a2,0x14
    uint32 funct3   = (instr >> 12) & 0x7;
    80006b52:	00c65713          	srl	a4,a2,0xc
    uint64 addr     = p->trapframe->epc;
    80006b56:	6d2c                	ld	a1,88(a0)
    /* Print the statement */
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
    80006b58:	8856                	mv	a6,s5
    80006b5a:	87ca                	mv	a5,s2
    80006b5c:	8b1d                	and	a4,a4,7
    80006b5e:	86ce                	mv	a3,s3
    80006b60:	07f67613          	and	a2,a2,127
    80006b64:	6d8c                	ld	a1,24(a1)
    80006b66:	00002517          	auipc	a0,0x2
    80006b6a:	fb250513          	add	a0,a0,-78 # 80008b18 <syscalls+0x680>
    80006b6e:	ffffa097          	auipc	ra,0xffffa
    80006b72:	a1c080e7          	jalr	-1508(ra) # 8000058a <printf>
                addr, op, rd, funct3, rs1, uimm);
    if(rs1 ==0 && rd == 0) {
    80006b76:	0164e4b3          	or	s1,s1,s6
    80006b7a:	88fd                	and	s1,s1,31
    80006b7c:	c4a9                	beqz	s1,80006bc6 <trap_and_emulate+0xb2>
        } else if (vm_state->current_mode == S_MODE){

        }
        p->trapframe->epc+=4;
        //not sure yet
    } else if ( rs1 == 0)
    80006b7e:	0c090963          	beqz	s2,80006c50 <trap_and_emulate+0x13c>
        printf("\nCSRR: %x %x %d\n", priveleged_register->val, priveleged_register->code, vm_state->current_mode);
        // p->trapframe->a1 = priveleged_register->val;
        write_to_trapframe_register(rd, priveleged_register->val);
        p->trapframe->epc+=4;
        // p->trapframe->a0 = vm_state->mhartid.val;
    } else if(rd == 0) {
    80006b82:	08099763          	bnez	s3,80006c10 <trap_and_emulate+0xfc>
        //csrw instruction
        // struct vm_reg *priveleged_register = get_register_by_code(uimm);
        uint64 reg_value = get_trapframe_register(rs1);
    80006b86:	854a                	mv	a0,s2
    80006b88:	00000097          	auipc	ra,0x0
    80006b8c:	e18080e7          	jalr	-488(ra) # 800069a0 <get_trapframe_register>
    80006b90:	84aa                	mv	s1,a0
        printf("\n CSRW: %x %d\n", reg_value, vm_state->current_mode);
    80006b92:	00002797          	auipc	a5,0x2
    80006b96:	1867b783          	ld	a5,390(a5) # 80008d18 <vm_state>
    80006b9a:	4390                	lw	a2,0(a5)
    80006b9c:	85aa                	mv	a1,a0
    80006b9e:	00002517          	auipc	a0,0x2
    80006ba2:	06250513          	add	a0,a0,98 # 80008c00 <syscalls+0x768>
    80006ba6:	ffffa097          	auipc	ra,0xffffa
    80006baa:	9e4080e7          	jalr	-1564(ra) # 8000058a <printf>
        write_to_vm_register(uimm, reg_value);
    80006bae:	85a6                	mv	a1,s1
    80006bb0:	8556                	mv	a0,s5
    80006bb2:	00000097          	auipc	ra,0x0
    80006bb6:	c04080e7          	jalr	-1020(ra) # 800067b6 <write_to_vm_register>
        p->trapframe->epc+=4;
    80006bba:	058a3703          	ld	a4,88(s4)
    80006bbe:	6f1c                	ld	a5,24(a4)
    80006bc0:	0791                	add	a5,a5,4
    80006bc2:	ef1c                	sd	a5,24(a4)
    }
    
    // printf("\n finished else if\n");
    return;
    80006bc4:	a0b1                	j	80006c10 <trap_and_emulate+0xfc>
        printf("\n current mode %d \n  important state register values\n mepc %x, mstatus %x, medeleg %x, mideleg %x, satp %x, sie %x\n", vm_state->current_mode,vm_state->mepc.val, vm_state->mstatus.val, vm_state->medeleg.val, vm_state->mideleg.val, vm_state->satp.val, vm_state->sie.val);
    80006bc6:	00002497          	auipc	s1,0x2
    80006bca:	15248493          	add	s1,s1,338 # 80008d18 <vm_state>
    80006bce:	608c                	ld	a1,0(s1)
    80006bd0:	6785                	lui	a5,0x1
    80006bd2:	97ae                	add	a5,a5,a1
    80006bd4:	3607b883          	ld	a7,864(a5) # 1360 <_entry-0x7fffeca0>
    80006bd8:	2d07b803          	ld	a6,720(a5)
    80006bdc:	1f05b783          	ld	a5,496(a1)
    80006be0:	1c05b703          	ld	a4,448(a1)
    80006be4:	1605b683          	ld	a3,352(a1)
    80006be8:	61b0                	ld	a2,64(a1)
    80006bea:	418c                	lw	a1,0(a1)
    80006bec:	00002517          	auipc	a0,0x2
    80006bf0:	f6c50513          	add	a0,a0,-148 # 80008b58 <syscalls+0x6c0>
    80006bf4:	ffffa097          	auipc	ra,0xffffa
    80006bf8:	996080e7          	jalr	-1642(ra) # 8000058a <printf>
        if(vm_state->current_mode == M_MODE){
    80006bfc:	6084                	ld	s1,0(s1)
    80006bfe:	4098                	lw	a4,0(s1)
    80006c00:	4789                	li	a5,2
    80006c02:	02f70163          	beq	a4,a5,80006c24 <trap_and_emulate+0x110>
        p->trapframe->epc+=4;
    80006c06:	058a3703          	ld	a4,88(s4)
    80006c0a:	6f1c                	ld	a5,24(a4)
    80006c0c:	0791                	add	a5,a5,4
    80006c0e:	ef1c                	sd	a5,24(a4)
}
    80006c10:	70e2                	ld	ra,56(sp)
    80006c12:	7442                	ld	s0,48(sp)
    80006c14:	74a2                	ld	s1,40(sp)
    80006c16:	7902                	ld	s2,32(sp)
    80006c18:	69e2                	ld	s3,24(sp)
    80006c1a:	6a42                	ld	s4,16(sp)
    80006c1c:	6aa2                	ld	s5,8(sp)
    80006c1e:	6b02                	ld	s6,0(sp)
    80006c20:	6121                	add	sp,sp,64
    80006c22:	8082                	ret
            struct vm_reg *reg = check_status_registers(uimm);
    80006c24:	8556                	mv	a0,s5
    80006c26:	00000097          	auipc	ra,0x0
    80006c2a:	a0c080e7          	jalr	-1524(ra) # 80006632 <check_status_registers>
            printf("\n reg value  %x %x\n", reg->val, vm_state);
    80006c2e:	8626                	mv	a2,s1
    80006c30:	650c                	ld	a1,8(a0)
    80006c32:	00002517          	auipc	a0,0x2
    80006c36:	f9e50513          	add	a0,a0,-98 # 80008bd0 <syscalls+0x738>
    80006c3a:	ffffa097          	auipc	ra,0xffffa
    80006c3e:	950080e7          	jalr	-1712(ra) # 8000058a <printf>
            vm_state->current_mode = S_MODE;
    80006c42:	00002797          	auipc	a5,0x2
    80006c46:	0d67b783          	ld	a5,214(a5) # 80008d18 <vm_state>
    80006c4a:	4705                	li	a4,1
    80006c4c:	c398                	sw	a4,0(a5)
    80006c4e:	bf65                	j	80006c06 <trap_and_emulate+0xf2>
        struct vm_reg *priveleged_register = get_register_by_code(uimm);
    80006c50:	8556                	mv	a0,s5
    80006c52:	00000097          	auipc	ra,0x0
    80006c56:	a1e080e7          	jalr	-1506(ra) # 80006670 <get_register_by_code>
    80006c5a:	84aa                	mv	s1,a0
        printf("\nCSRR: %x %x %d\n", priveleged_register->val, priveleged_register->code, vm_state->current_mode);
    80006c5c:	00002797          	auipc	a5,0x2
    80006c60:	0bc7b783          	ld	a5,188(a5) # 80008d18 <vm_state>
    80006c64:	4394                	lw	a3,0(a5)
    80006c66:	4110                	lw	a2,0(a0)
    80006c68:	650c                	ld	a1,8(a0)
    80006c6a:	00002517          	auipc	a0,0x2
    80006c6e:	f7e50513          	add	a0,a0,-130 # 80008be8 <syscalls+0x750>
    80006c72:	ffffa097          	auipc	ra,0xffffa
    80006c76:	918080e7          	jalr	-1768(ra) # 8000058a <printf>
        write_to_trapframe_register(rd, priveleged_register->val);
    80006c7a:	648c                	ld	a1,8(s1)
    80006c7c:	854e                	mv	a0,s3
    80006c7e:	00000097          	auipc	ra,0x0
    80006c82:	d7e080e7          	jalr	-642(ra) # 800069fc <write_to_trapframe_register>
        p->trapframe->epc+=4;
    80006c86:	058a3703          	ld	a4,88(s4)
    80006c8a:	6f1c                	ld	a5,24(a4)
    80006c8c:	0791                	add	a5,a5,4
    80006c8e:	ef1c                	sd	a5,24(a4)
    80006c90:	b741                	j	80006c10 <trap_and_emulate+0xfc>

0000000080006c92 <trap_and_emulate_init>:

void trap_and_emulate_init(void) {
    80006c92:	1141                	add	sp,sp,-16
    80006c94:	e406                	sd	ra,8(sp)
    80006c96:	e022                	sd	s0,0(sp)
    80006c98:	0800                	add	s0,sp,16
    /* Create and initialize all state for the VM */
    printf("INIT: called");
    80006c9a:	00002517          	auipc	a0,0x2
    80006c9e:	f7650513          	add	a0,a0,-138 # 80008c10 <syscalls+0x778>
    80006ca2:	ffffa097          	auipc	ra,0xffffa
    80006ca6:	8e8080e7          	jalr	-1816(ra) # 8000058a <printf>
    
    vm_state = (struct vm_virtual_state*)kalloc();
    80006caa:	ffffa097          	auipc	ra,0xffffa
    80006cae:	eae080e7          	jalr	-338(ra) # 80000b58 <kalloc>
    80006cb2:	00002717          	auipc	a4,0x2
    80006cb6:	06670713          	add	a4,a4,102 # 80008d18 <vm_state>
    80006cba:	e308                	sd	a0,0(a4)
    
    vm_state->current_mode = M_MODE;
    80006cbc:	4789                	li	a5,2
    80006cbe:	c11c                	sw	a5,0(a0)

    vm_state->mscratch.val = 0;
    80006cc0:	6310                	ld	a2,0(a4)
    80006cc2:	00063823          	sd	zero,16(a2)
    vm_state->mscratch.code = 0x340;
    80006cc6:	34000713          	li	a4,832
    80006cca:	c618                	sw	a4,8(a2)
    vm_state->mscratch.mode = M_MODE;
    80006ccc:	c65c                	sw	a5,12(a2)

    vm_state->mepc.val = 0;
    80006cce:	04063023          	sd	zero,64(a2)
    vm_state->mepc.code = 0x341;
    80006cd2:	34100713          	li	a4,833
    80006cd6:	de18                	sw	a4,56(a2)
    vm_state->mepc.mode = M_MODE;
    80006cd8:	de5c                	sw	a5,60(a2)

    vm_state->mcause.val = 0;
    80006cda:	06063823          	sd	zero,112(a2)
    vm_state->mcause.code = 0x342;
    80006cde:	34200713          	li	a4,834
    80006ce2:	d638                	sw	a4,104(a2)
    vm_state->mcause.mode = M_MODE;
    80006ce4:	d67c                	sw	a5,108(a2)

    vm_state->mtval.val = 0;
    80006ce6:	0a063023          	sd	zero,160(a2)
    vm_state->mtval.code = 0x343;
    80006cea:	34300713          	li	a4,835
    80006cee:	08e62c23          	sw	a4,152(a2)
    vm_state->mtval.mode = M_MODE;
    80006cf2:	08f62e23          	sw	a5,156(a2)

    vm_state->mip.val = 0;
    80006cf6:	0c063823          	sd	zero,208(a2)
    vm_state->mip.code = 0x344;
    80006cfa:	34400713          	li	a4,836
    80006cfe:	0ce62423          	sw	a4,200(a2)
    vm_state->mip.mode = M_MODE;
    80006d02:	0cf62623          	sw	a5,204(a2)

    vm_state->mtinst.val = 0;
    80006d06:	10063023          	sd	zero,256(a2)
    vm_state->mtinst.code = 0x34A;
    80006d0a:	34a00713          	li	a4,842
    80006d0e:	0ee62c23          	sw	a4,248(a2)
    vm_state->mtinst.mode = M_MODE;
    80006d12:	0ef62e23          	sw	a5,252(a2)
    
    vm_state->mtval2.val = 0;
    80006d16:	12063823          	sd	zero,304(a2)
    vm_state->mtval2.code = 0x34B;
    80006d1a:	34b00713          	li	a4,843
    80006d1e:	12e62423          	sw	a4,296(a2)
    vm_state->mtval2.mode = M_MODE;
    80006d22:	12f62623          	sw	a5,300(a2)

    // Initializing Machine Trap setup registers

    vm_state->mstatus.val = 0;
    80006d26:	16063023          	sd	zero,352(a2)
    vm_state->mstatus.code = 0x300;
    80006d2a:	30000713          	li	a4,768
    80006d2e:	14e62c23          	sw	a4,344(a2)
    vm_state->mstatus.mode = M_MODE;
    80006d32:	14f62e23          	sw	a5,348(a2)

    vm_state->misa.val = 0;
    80006d36:	18063823          	sd	zero,400(a2)
    vm_state->misa.code = 0x301;
    80006d3a:	30100713          	li	a4,769
    80006d3e:	18e62423          	sw	a4,392(a2)
    vm_state->misa.mode = M_MODE;
    80006d42:	18f62623          	sw	a5,396(a2)

    vm_state->medeleg.val = 0;
    80006d46:	1c063023          	sd	zero,448(a2)
    vm_state->medeleg.code = 0x302;
    80006d4a:	30200713          	li	a4,770
    80006d4e:	1ae62c23          	sw	a4,440(a2)
    vm_state->medeleg.mode = M_MODE;
    80006d52:	1af62e23          	sw	a5,444(a2)

    vm_state->mideleg.val = 0;
    80006d56:	1e063823          	sd	zero,496(a2)
    vm_state->mideleg.code = 0x303;
    80006d5a:	30300713          	li	a4,771
    80006d5e:	1ee62423          	sw	a4,488(a2)
    vm_state->mideleg.mode = M_MODE;
    80006d62:	1ef62623          	sw	a5,492(a2)

    vm_state->mie.val = 0;
    80006d66:	22063023          	sd	zero,544(a2)
    vm_state->mie.code = 0x304;
    80006d6a:	30400713          	li	a4,772
    80006d6e:	20e62c23          	sw	a4,536(a2)
    vm_state->mie.mode = M_MODE;
    80006d72:	20f62e23          	sw	a5,540(a2)

    vm_state->mtvec.val = 0;
    80006d76:	24063823          	sd	zero,592(a2)
    vm_state->mtvec.code = 0x305;
    80006d7a:	30500713          	li	a4,773
    80006d7e:	24e62423          	sw	a4,584(a2)
    vm_state->mtvec.mode = M_MODE;
    80006d82:	24f62623          	sw	a5,588(a2)
    
    vm_state->mcounteren.val = 0;
    80006d86:	28063023          	sd	zero,640(a2)
    vm_state->mcounteren.code = 0x306;
    80006d8a:	30600713          	li	a4,774
    80006d8e:	26e62c23          	sw	a4,632(a2)
    vm_state->mcounteren.mode = M_MODE;
    80006d92:	26f62e23          	sw	a5,636(a2)

    vm_state->mstatush.val = 0;
    80006d96:	2a063823          	sd	zero,688(a2)
    vm_state->mstatush.code = 0x310;
    80006d9a:	31000713          	li	a4,784
    80006d9e:	2ae62423          	sw	a4,680(a2)
    vm_state->mstatush.mode = M_MODE;    
    80006da2:	2af62623          	sw	a5,684(a2)

    // Initializing Machine information state registers
    
    vm_state->mvendorid.val = 0;
    80006da6:	2e063023          	sd	zero,736(a2)
    vm_state->mvendorid.code = 0xf11;
    80006daa:	6705                	lui	a4,0x1
    80006dac:	f1170693          	add	a3,a4,-239 # f11 <_entry-0x7ffff0ef>
    80006db0:	2cd62c23          	sw	a3,728(a2)
    vm_state->mvendorid.mode = M_MODE;
    80006db4:	2cf62e23          	sw	a5,732(a2)
    
    vm_state->marchid.val = 0;
    80006db8:	30063823          	sd	zero,784(a2)
    vm_state->marchid.code = 0xf12;
    80006dbc:	f1270693          	add	a3,a4,-238
    80006dc0:	30d62423          	sw	a3,776(a2)
    vm_state->marchid.mode = M_MODE;
    80006dc4:	30f62623          	sw	a5,780(a2)

    vm_state->mimpid.val = 0;
    80006dc8:	34063023          	sd	zero,832(a2)
    vm_state->mimpid.code = 0xf13;
    80006dcc:	f1370693          	add	a3,a4,-237
    80006dd0:	32d62c23          	sw	a3,824(a2)
    vm_state->mimpid.mode = M_MODE;
    80006dd4:	32f62e23          	sw	a5,828(a2)

    vm_state->mhartid.val = 0;
    80006dd8:	36063823          	sd	zero,880(a2)
    vm_state->mhartid.code = 0xf14;
    80006ddc:	f1470693          	add	a3,a4,-236
    80006de0:	36d62423          	sw	a3,872(a2)
    vm_state->mhartid.mode = M_MODE;
    80006de4:	36f62623          	sw	a5,876(a2)

    vm_state->mconfigptr.val = 0;
    80006de8:	3a063023          	sd	zero,928(a2)
    vm_state->mconfigptr.code = 0xf15;
    80006dec:	f1570713          	add	a4,a4,-235
    80006df0:	38e62c23          	sw	a4,920(a2)
    vm_state->mconfigptr.mode = M_MODE;
    80006df4:	38f62e23          	sw	a5,924(a2)

    // // // Initializing Machine physical memory protection

    for (int i = 0; i < PMP_CFG_NUM; ++i) {
    80006df8:	3c860793          	add	a5,a2,968
    vm_state->mconfigptr.mode = M_MODE;
    80006dfc:	3a000713          	li	a4,928
        vm_state->pmpcfg[i].code = 0x3a0 + i;
        vm_state->pmpcfg[i].val = 0;
        vm_state->pmpcfg[i].mode = M_MODE;
    80006e00:	4589                	li	a1,2
    for (int i = 0; i < PMP_CFG_NUM; ++i) {
    80006e02:	3b000693          	li	a3,944
        vm_state->pmpcfg[i].code = 0x3a0 + i;
    80006e06:	c398                	sw	a4,0(a5)
        vm_state->pmpcfg[i].val = 0;
    80006e08:	0007b423          	sd	zero,8(a5)
        vm_state->pmpcfg[i].mode = M_MODE;
    80006e0c:	c3cc                	sw	a1,4(a5)
    for (int i = 0; i < PMP_CFG_NUM; ++i) {
    80006e0e:	2705                	addw	a4,a4,1
    80006e10:	03078793          	add	a5,a5,48
    80006e14:	fed719e3          	bne	a4,a3,80006e06 <trap_and_emulate_init+0x174>
    // vm_state->satp.val = 0;
    // vm_state->satp.code = 0x180;
    // vm_state->satp.mode = S_MODE;

    // Supervisor Trap setup registers
    vm_state->sstatus.val = 0;
    80006e18:	6785                	lui	a5,0x1
    80006e1a:	97b2                	add	a5,a5,a2
    80006e1c:	3007b023          	sd	zero,768(a5) # 1300 <_entry-0x7fffed00>
    vm_state->sstatus.code = 0x100;
    80006e20:	10000713          	li	a4,256
    80006e24:	2ee7ac23          	sw	a4,760(a5)
    vm_state->sstatus.mode = S_MODE;
    80006e28:	4705                	li	a4,1
    80006e2a:	2ee7ae23          	sw	a4,764(a5)

    vm_state->sedeleg.val = 0;
    80006e2e:	3207b823          	sd	zero,816(a5)
    vm_state->sedeleg.code = 0x102;
    80006e32:	10200693          	li	a3,258
    80006e36:	32d7a423          	sw	a3,808(a5)
    vm_state->sedeleg.mode = S_MODE;
    80006e3a:	32e7a623          	sw	a4,812(a5)

    vm_state->sie.val = 0;
    80006e3e:	3607b023          	sd	zero,864(a5)
    vm_state->sie.code = 0x104;
    80006e42:	10400693          	li	a3,260
    80006e46:	34d7ac23          	sw	a3,856(a5)
    vm_state->sie.mode = S_MODE;
    80006e4a:	34e7ae23          	sw	a4,860(a5)

    vm_state->stvec.val = 0;
    80006e4e:	3807b823          	sd	zero,912(a5)
    vm_state->stvec.code = 0; // 0x105
    80006e52:	3807a423          	sw	zero,904(a5)
    vm_state->stvec.mode = S_MODE;
    80006e56:	38e7a623          	sw	a4,908(a5)

    vm_state->scounteren.val = 0;
    80006e5a:	3c07b023          	sd	zero,960(a5)
    vm_state->scounteren.code = 0x106;
    vm_state->scounteren.mode = S_MODE;

    // supervisor trap handling

    vm_state->sepc.val = 0;
    80006e5e:	3e07b823          	sd	zero,1008(a5)
    vm_state->sepc.code = 0; 
    80006e62:	3e07a423          	sw	zero,1000(a5)
    vm_state->sepc.mode = S_MODE;
    80006e66:	3ee7a623          	sw	a4,1004(a5)

    // User trap handling registers

    vm_state->scounteren.val = 0;
    vm_state->scounteren.code = 0;
    80006e6a:	3a07ac23          	sw	zero,952(a5)
    vm_state->scounteren.mode = U_MODE;
    80006e6e:	3a07ae23          	sw	zero,956(a5)

    // vm_state->uepc.val = 0;
    // vm_state->uepc.code = 0x41;
    // vm_state->uepc.mode = U_MODE;

    vm_state->ucause.val = 0;
    80006e72:	4807b023          	sd	zero,1152(a5)
    vm_state->ucause.code = 0x42;
    80006e76:	04200713          	li	a4,66
    80006e7a:	46e7ac23          	sw	a4,1144(a5)
    vm_state->ucause.mode = U_MODE;
    80006e7e:	4607ae23          	sw	zero,1148(a5)

    vm_state->ubadaddr.val = 0;
    80006e82:	4a07b823          	sd	zero,1200(a5)
    vm_state->ubadaddr.code = 0;
    80006e86:	4a07a423          	sw	zero,1192(a5)
    vm_state->ubadaddr.mode = U_MODE;
    80006e8a:	4a07a623          	sw	zero,1196(a5)

    vm_state->uip.val = 0;
    80006e8e:	4e07b023          	sd	zero,1248(a5)
    vm_state->uip.code = 0x044;
    80006e92:	04400713          	li	a4,68
    80006e96:	4ce7ac23          	sw	a4,1240(a5)
    vm_state->uip.mode = U_MODE;
    80006e9a:	4c07ae23          	sw	zero,1244(a5)

    // // Initialization User trap set-up registers

    vm_state->ustatus.val = 0;
    80006e9e:	5007b823          	sd	zero,1296(a5)
    vm_state->ustatus.code = 0;
    80006ea2:	5007a423          	sw	zero,1288(a5)
    vm_state->ustatus.mode = U_MODE;
    80006ea6:	5007a623          	sw	zero,1292(a5)

    vm_state->uie.val = 0;
    80006eaa:	5407b023          	sd	zero,1344(a5)
    vm_state->uie.code = 0;
    80006eae:	5207ac23          	sw	zero,1336(a5)
    vm_state->uie.mode = U_MODE;
    80006eb2:	5207ae23          	sw	zero,1340(a5)

    vm_state->utvec.val = 0;
    80006eb6:	5607b823          	sd	zero,1392(a5)
    vm_state->utvec.code = 0;
    80006eba:	5607a423          	sw	zero,1384(a5)
    vm_state->utvec.mode = U_MODE;
    80006ebe:	5607a623          	sw	zero,1388(a5)

    // initialize 
    printf("\n current mode - %d %x\n", vm_state->current_mode, vm_state);
    80006ec2:	420c                	lw	a1,0(a2)
    80006ec4:	00002517          	auipc	a0,0x2
    80006ec8:	d5c50513          	add	a0,a0,-676 # 80008c20 <syscalls+0x788>
    80006ecc:	ffff9097          	auipc	ra,0xffff9
    80006ed0:	6be080e7          	jalr	1726(ra) # 8000058a <printf>
    80006ed4:	60a2                	ld	ra,8(sp)
    80006ed6:	6402                	ld	s0,0(sp)
    80006ed8:	0141                	add	sp,sp,16
    80006eda:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
