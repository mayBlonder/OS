
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	a2013103          	ld	sp,-1504(sp) # 80009a20 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	00e70713          	addi	a4,a4,14 # 8000a060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	fac78793          	addi	a5,a5,-84 # 80007010 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	770080e7          	jalr	1904(ra) # 8000389c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	01450513          	addi	a0,a0,20 # 800121a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	00448493          	addi	s1,s1,4 # 800121a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	09290913          	addi	s2,s2,146 # 80012238 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	9e0080e7          	jalr	-1568(ra) # 80001ba4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	a3a080e7          	jalr	-1478(ra) # 80002c0e <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00003097          	auipc	ra,0x3
    80000214:	636080e7          	jalr	1590(ra) # 80003846 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00012517          	auipc	a0,0x12
    80000228:	f7c50513          	addi	a0,a0,-132 # 800121a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00012517          	auipc	a0,0x12
    8000023e:	f6650513          	addi	a0,a0,-154 # 800121a0 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00012717          	auipc	a4,0x12
    80000276:	fcf72323          	sw	a5,-58(a4) # 80012238 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00012517          	auipc	a0,0x12
    800002d0:	ed450513          	addi	a0,a0,-300 # 800121a0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	600080e7          	jalr	1536(ra) # 800038f2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00012517          	auipc	a0,0x12
    800002fe:	ea650513          	addi	a0,a0,-346 # 800121a0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00012717          	auipc	a4,0x12
    80000322:	e8270713          	addi	a4,a4,-382 # 800121a0 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00012797          	auipc	a5,0x12
    8000034c:	e5878793          	addi	a5,a5,-424 # 800121a0 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00012797          	auipc	a5,0x12
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80012238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00012717          	auipc	a4,0x12
    8000038e:	e1670713          	addi	a4,a4,-490 # 800121a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00012497          	auipc	s1,0x12
    8000039e:	e0648493          	addi	s1,s1,-506 # 800121a0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
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
    800003d6:	00012717          	auipc	a4,0x12
    800003da:	dca70713          	addi	a4,a4,-566 # 800121a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00012717          	auipc	a4,0x12
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80012240 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00012797          	auipc	a5,0x12
    80000416:	d8e78793          	addi	a5,a5,-626 # 800121a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00012797          	auipc	a5,0x12
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001223c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00012517          	auipc	a0,0x12
    80000442:	dfa50513          	addi	a0,a0,-518 # 80012238 <cons+0x98>
    80000446:	00003097          	auipc	ra,0x3
    8000044a:	b1e080e7          	jalr	-1250(ra) # 80002f64 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00009597          	auipc	a1,0x9
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80009010 <etext+0x10>
    80000460:	00012517          	auipc	a0,0x12
    80000464:	d4050513          	addi	a0,a0,-704 # 800121a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	b4078793          	addi	a5,a5,-1216 # 80022fb8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00009617          	auipc	a2,0x9
    800004be:	b8660613          	addi	a2,a2,-1146 # 80009040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00012797          	auipc	a5,0x12
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80012260 <pr+0x18>
  printf("panic: ");
    80000552:	00009517          	auipc	a0,0x9
    80000556:	ac650513          	addi	a0,a0,-1338 # 80009018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00009517          	auipc	a0,0x9
    80000570:	e6450513          	addi	a0,a0,-412 # 800093d0 <digits+0x390>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	0000a717          	auipc	a4,0xa
    80000582:	a8f72123          	sw	a5,-1406(a4) # 8000a000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00012d97          	auipc	s11,0x12
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80012260 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00009b97          	auipc	s7,0x9
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80009040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00012517          	auipc	a0,0x12
    800005fc:	c5050513          	addi	a0,a0,-944 # 80012248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00009517          	auipc	a0,0x9
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80009028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00009917          	auipc	s2,0x9
    8000070e:	91690913          	addi	s2,s2,-1770 # 80009020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00012517          	auipc	a0,0x12
    80000760:	aec50513          	addi	a0,a0,-1300 # 80012248 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00012497          	auipc	s1,0x12
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80012248 <pr>
    80000780:	00009597          	auipc	a1,0x9
    80000784:	8b858593          	addi	a1,a1,-1864 # 80009038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00009597          	auipc	a1,0x9
    800007d4:	88858593          	addi	a1,a1,-1912 # 80009058 <digits+0x18>
    800007d8:	00012517          	auipc	a0,0x12
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80012268 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00009797          	auipc	a5,0x9
    80000808:	7fc7a783          	lw	a5,2044(a5) # 8000a000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00009717          	auipc	a4,0x9
    80000844:	7c873703          	ld	a4,1992(a4) # 8000a008 <uart_tx_r>
    80000848:	00009797          	auipc	a5,0x9
    8000084c:	7c87b783          	ld	a5,1992(a5) # 8000a010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00012a17          	auipc	s4,0x12
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80012268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00009497          	auipc	s1,0x9
    80000876:	79648493          	addi	s1,s1,1942 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00009997          	auipc	s3,0x9
    8000087e:	79698993          	addi	s3,s3,1942 # 8000a010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	6c4080e7          	jalr	1732(ra) # 80002f64 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00012517          	auipc	a0,0x12
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80012268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00009797          	auipc	a5,0x9
    800008f0:	7147a783          	lw	a5,1812(a5) # 8000a000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00009797          	auipc	a5,0x9
    800008fc:	7187b783          	ld	a5,1816(a5) # 8000a010 <uart_tx_w>
    80000900:	00009717          	auipc	a4,0x9
    80000904:	70873703          	ld	a4,1800(a4) # 8000a008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00012a17          	auipc	s4,0x12
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80012268 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	6f048493          	addi	s1,s1,1776 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	6f090913          	addi	s2,s2,1776 # 8000a010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	2e2080e7          	jalr	738(ra) # 80002c0e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00012497          	auipc	s1,0x12
    80000946:	92648493          	addi	s1,s1,-1754 # 80012268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00009717          	auipc	a4,0x9
    8000095a:	6af73d23          	sd	a5,1722(a4) # 8000a010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00012497          	auipc	s1,0x12
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80012268 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00027797          	auipc	a5,0x27
    80000a10:	5f478793          	addi	a5,a5,1524 # 80028000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00012917          	auipc	s2,0x12
    80000a30:	87490913          	addi	s2,s2,-1932 # 800122a0 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00008517          	auipc	a0,0x8
    80000a62:	60250513          	addi	a0,a0,1538 # 80009060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00008597          	auipc	a1,0x8
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80009068 <digits+0x28>
    80000ac8:	00011517          	auipc	a0,0x11
    80000acc:	7d850513          	addi	a0,a0,2008 # 800122a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00027517          	auipc	a0,0x27
    80000ae0:	52450513          	addi	a0,a0,1316 # 80028000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00011497          	auipc	s1,0x11
    80000b02:	7a248493          	addi	s1,s1,1954 # 800122a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00011517          	auipc	a0,0x11
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800122a0 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	75e50513          	addi	a0,a0,1886 # 800122a0 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	fee080e7          	jalr	-18(ra) # 80001b6c <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	fbc080e7          	jalr	-68(ra) # 80001b6c <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	fb0080e7          	jalr	-80(ra) # 80001b6c <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f98080e7          	jalr	-104(ra) # 80001b6c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	f58080e7          	jalr	-168(ra) # 80001b6c <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00008517          	auipc	a0,0x8
    80000c2c:	44850513          	addi	a0,a0,1096 # 80009070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	f2c080e7          	jalr	-212(ra) # 80001b6c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00008517          	auipc	a0,0x8
    80000c7c:	40050513          	addi	a0,a0,1024 # 80009078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00008517          	auipc	a0,0x8
    80000c8c:	40850513          	addi	a0,a0,1032 # 80009090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00008517          	auipc	a0,0x8
    80000cd4:	3c850513          	addi	a0,a0,968 # 80009098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	cc6080e7          	jalr	-826(ra) # 80001b5c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00009717          	auipc	a4,0x9
    80000ea2:	17a70713          	addi	a4,a4,378 # 8000a018 <started>
  if(cpuid() == 0){
    80000ea6:	c539                	beqz	a0,80000ef4 <main+0x66>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	caa080e7          	jalr	-854(ra) # 80001b5c <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00008517          	auipc	a0,0x8
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800090b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00003097          	auipc	ra,0x3
    80000ed8:	b5e080e7          	jalr	-1186(ra) # 80003a32 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	174080e7          	jalr	372(ra) # 80007050 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	8f0080e7          	jalr	-1808(ra) # 800027d4 <scheduler>
}
    80000eec:	60a2                	ld	ra,8(sp)
    80000eee:	6402                	ld	s0,0(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    consoleinit();
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	55c080e7          	jalr	1372(ra) # 80000450 <consoleinit>
    printfinit();
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	872080e7          	jalr	-1934(ra) # 8000076e <printfinit>
    printf("\n");
    80000f04:	00008517          	auipc	a0,0x8
    80000f08:	4cc50513          	addi	a0,a0,1228 # 800093d0 <digits+0x390>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00008517          	auipc	a0,0x8
    80000f18:	18c50513          	addi	a0,a0,396 # 800090a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00008517          	auipc	a0,0x8
    80000f28:	4ac50513          	addi	a0,a0,1196 # 800093d0 <digits+0x390>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b84080e7          	jalr	-1148(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	322080e7          	jalr	802(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	aa6080e7          	jalr	-1370(ra) # 800019f2 <procinit>
    trapinit();      // trap vectors
    80000f54:	00003097          	auipc	ra,0x3
    80000f58:	ab6080e7          	jalr	-1354(ra) # 80003a0a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00003097          	auipc	ra,0x3
    80000f60:	ad6080e7          	jalr	-1322(ra) # 80003a32 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00006097          	auipc	ra,0x6
    80000f68:	0d6080e7          	jalr	214(ra) # 8000703a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00006097          	auipc	ra,0x6
    80000f70:	0e4080e7          	jalr	228(ra) # 80007050 <plicinithart>
    binit();         // buffer cache
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	2ba080e7          	jalr	698(ra) # 8000422e <binit>
    iinit();         // inode table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	94a080e7          	jalr	-1718(ra) # 800048c6 <iinit>
    fileinit();      // file table
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	8f4080e7          	jalr	-1804(ra) # 80005878 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00006097          	auipc	ra,0x6
    80000f90:	1e6080e7          	jalr	486(ra) # 80007172 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	0f8080e7          	jalr	248(ra) # 8000208c <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00009717          	auipc	a4,0x9
    80000fa6:	06f72b23          	sw	a5,118(a4) # 8000a018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00009797          	auipc	a5,0x9
    80000fb6:	06e7b783          	ld	a5,110(a5) # 8000a020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00008517          	auipc	a0,0x8
    80000ffa:	0da50513          	addi	a0,a0,218 # 800090d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00008517          	auipc	a0,0x8
    800010f2:	fea50513          	addi	a0,a0,-22 # 800090d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00008517          	auipc	a0,0x8
    80001102:	fea50513          	addi	a0,a0,-22 # 800090e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00008517          	auipc	a0,0x8
    8000117c:	f8050513          	addi	a0,a0,-128 # 800090f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00008917          	auipc	s2,0x8
    800011f2:	e1290913          	addi	s2,s2,-494 # 80009000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80008697          	auipc	a3,0x80008
    800011fc:	e0868693          	addi	a3,a3,-504 # 9000 <_entry-0x7fff7000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00007617          	auipc	a2,0x7
    80001230:	dd460613          	addi	a2,a2,-556 # 80008000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	714080e7          	jalr	1812(ra) # 8000195c <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00009797          	auipc	a5,0x9
    80001272:	daa7b923          	sd	a0,-590(a5) # 8000a020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00008517          	auipc	a0,0x8
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80009100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00008517          	auipc	a0,0x8
    800012d8:	e4450513          	addi	a0,a0,-444 # 80009118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00008517          	auipc	a0,0x8
    800012e8:	e4450513          	addi	a0,a0,-444 # 80009128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00008517          	auipc	a0,0x8
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80009140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00008517          	auipc	a0,0x8
    800013d6:	d8650513          	addi	a0,a0,-634 # 80009158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00008517          	auipc	a0,0x8
    80001518:	c6450513          	addi	a0,a0,-924 # 80009178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00008517          	auipc	a0,0x8
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80009188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00008517          	auipc	a0,0x8
    80001604:	ba850513          	addi	a0,a0,-1112 # 800091a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00008517          	auipc	a0,0x8
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800091c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <add_proc_to_list>:
extern uint64 cas( volatile void *addr, int expected, int newval);

// Ass2
int
add_proc_to_list(int tail, struct proc *p)
{
    80001846:	1101                	addi	sp,sp,-32
    80001848:	ec06                	sd	ra,24(sp)
    8000184a:	e822                	sd	s0,16(sp)
    8000184c:	e426                	sd	s1,8(sp)
    8000184e:	e04a                	sd	s2,0(sp)
    80001850:	1000                	addi	s0,sp,32
    80001852:	892a                	mv	s2,a0
    80001854:	84ae                	mv	s1,a1
  printf("&&&&&&&&&&&&&&&adding: %d\n", p->proc_ind);
    80001856:	4dec                	lw	a1,92(a1)
    80001858:	00008517          	auipc	a0,0x8
    8000185c:	98050513          	addi	a0,a0,-1664 # 800091d8 <digits+0x198>
    80001860:	fffff097          	auipc	ra,0xfffff
    80001864:	d28080e7          	jalr	-728(ra) # 80000588 <printf>
  int p_before = proc[tail].next_proc;
    80001868:	00011517          	auipc	a0,0x11
    8000186c:	f0850513          	addi	a0,a0,-248 # 80012770 <proc>
    80001870:	19800793          	li	a5,408
    80001874:	02f907b3          	mul	a5,s2,a5
    80001878:	00f50733          	add	a4,a0,a5
  if (cas(&proc[tail].next_proc, p_before, p->proc_ind) == 0)
    8000187c:	06078793          	addi	a5,a5,96
    80001880:	4cf0                	lw	a2,92(s1)
    80001882:	532c                	lw	a1,96(a4)
    80001884:	953e                	add	a0,a0,a5
    80001886:	00006097          	auipc	ra,0x6
    8000188a:	dd0080e7          	jalr	-560(ra) # 80007656 <cas>
    8000188e:	e909                	bnez	a0,800018a0 <add_proc_to_list+0x5a>
  {
    p->prev_proc = tail;
    80001890:	0724a223          	sw	s2,100(s1)
    return 0;
  }
  return -1;
}
    80001894:	60e2                	ld	ra,24(sp)
    80001896:	6442                	ld	s0,16(sp)
    80001898:	64a2                	ld	s1,8(sp)
    8000189a:	6902                	ld	s2,0(sp)
    8000189c:	6105                	addi	sp,sp,32
    8000189e:	8082                	ret
  return -1;
    800018a0:	557d                	li	a0,-1
    800018a2:	bfcd                	j	80001894 <add_proc_to_list+0x4e>

00000000800018a4 <remove_proc_from_list>:

// Ass2
int
remove_proc_from_list(int ind)
{
    800018a4:	1101                	addi	sp,sp,-32
    800018a6:	ec06                	sd	ra,24(sp)
    800018a8:	e822                	sd	s0,16(sp)
    800018aa:	e426                	sd	s1,8(sp)
    800018ac:	e04a                	sd	s2,0(sp)
    800018ae:	1000                	addi	s0,sp,32
  struct proc *p = &proc[ind];

  printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);
    800018b0:	19800913          	li	s2,408
    800018b4:	032507b3          	mul	a5,a0,s2
    800018b8:	00011917          	auipc	s2,0x11
    800018bc:	eb890913          	addi	s2,s2,-328 # 80012770 <proc>
    800018c0:	993e                	add	s2,s2,a5
    800018c2:	06092683          	lw	a3,96(s2)
    800018c6:	06492603          	lw	a2,100(s2)
    800018ca:	85aa                	mv	a1,a0
    800018cc:	00008517          	auipc	a0,0x8
    800018d0:	92c50513          	addi	a0,a0,-1748 # 800091f8 <digits+0x1b8>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	cb4080e7          	jalr	-844(ra) # 80000588 <printf>

  if (p->prev_proc == -1 && p->next_proc == -1)
    800018dc:	06093703          	ld	a4,96(s2)
    800018e0:	57fd                	li	a5,-1
    return 1;  // Need to change head & tail.
    800018e2:	4505                	li	a0,1
  if (p->prev_proc == -1 && p->next_proc == -1)
    800018e4:	06f70263          	beq	a4,a5,80001948 <remove_proc_from_list+0xa4>
  
  if (p->prev_proc == -1)
    800018e8:	06492783          	lw	a5,100(s2)
    800018ec:	577d                	li	a4,-1
    800018ee:	06e78363          	beq	a5,a4,80001954 <remove_proc_from_list+0xb0>
    return 2;  // Need to change head.

  if (p->next_proc == -1)
    800018f2:	06092603          	lw	a2,96(s2)
    800018f6:	577d                	li	a4,-1
    return 3;  // Need to change tail.
    800018f8:	450d                	li	a0,3
  if (p->next_proc == -1)
    800018fa:	04e60763          	beq	a2,a4,80001948 <remove_proc_from_list+0xa4>

  int prev = proc[p->prev_proc].next_proc;
    800018fe:	00011517          	auipc	a0,0x11
    80001902:	e7250513          	addi	a0,a0,-398 # 80012770 <proc>
    80001906:	19800713          	li	a4,408
    8000190a:	02e787b3          	mul	a5,a5,a4
    8000190e:	00f50733          	add	a4,a0,a5
  if (cas(&proc[p->prev_proc].next_proc, prev, p->next_proc) == 0)
    80001912:	06078793          	addi	a5,a5,96
    80001916:	532c                	lw	a1,96(a4)
    80001918:	953e                	add	a0,a0,a5
    8000191a:	00006097          	auipc	ra,0x6
    8000191e:	d3c080e7          	jalr	-708(ra) # 80007656 <cas>
    80001922:	e91d                	bnez	a0,80001958 <remove_proc_from_list+0xb4>
  {
    proc[p->next_proc].prev_proc = proc[p->prev_proc].proc_ind;
    80001924:	00011717          	auipc	a4,0x11
    80001928:	e4c70713          	addi	a4,a4,-436 # 80012770 <proc>
    8000192c:	19800613          	li	a2,408
    80001930:	06092783          	lw	a5,96(s2)
    80001934:	02c787b3          	mul	a5,a5,a2
    80001938:	97ba                	add	a5,a5,a4
    8000193a:	06492683          	lw	a3,100(s2)
    8000193e:	02c686b3          	mul	a3,a3,a2
    80001942:	9736                	add	a4,a4,a3
    80001944:	4f78                	lw	a4,92(a4)
    80001946:	d3f8                	sw	a4,100(a5)
    return 0;
  }
  return -1;
}
    80001948:	60e2                	ld	ra,24(sp)
    8000194a:	6442                	ld	s0,16(sp)
    8000194c:	64a2                	ld	s1,8(sp)
    8000194e:	6902                	ld	s2,0(sp)
    80001950:	6105                	addi	sp,sp,32
    80001952:	8082                	ret
    return 2;  // Need to change head.
    80001954:	4509                	li	a0,2
    80001956:	bfcd                	j	80001948 <remove_proc_from_list+0xa4>
  return -1;
    80001958:	557d                	li	a0,-1
    8000195a:	b7fd                	j	80001948 <remove_proc_from_list+0xa4>

000000008000195c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000195c:	7139                	addi	sp,sp,-64
    8000195e:	fc06                	sd	ra,56(sp)
    80001960:	f822                	sd	s0,48(sp)
    80001962:	f426                	sd	s1,40(sp)
    80001964:	f04a                	sd	s2,32(sp)
    80001966:	ec4e                	sd	s3,24(sp)
    80001968:	e852                	sd	s4,16(sp)
    8000196a:	e456                	sd	s5,8(sp)
    8000196c:	e05a                	sd	s6,0(sp)
    8000196e:	0080                	addi	s0,sp,64
    80001970:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001972:	00011497          	auipc	s1,0x11
    80001976:	dfe48493          	addi	s1,s1,-514 # 80012770 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000197a:	8b26                	mv	s6,s1
    8000197c:	00007a97          	auipc	s5,0x7
    80001980:	684a8a93          	addi	s5,s5,1668 # 80009000 <etext>
    80001984:	04000937          	lui	s2,0x4000
    80001988:	197d                	addi	s2,s2,-1
    8000198a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198c:	00017a17          	auipc	s4,0x17
    80001990:	3e4a0a13          	addi	s4,s4,996 # 80018d70 <tickslock>
    char *pa = kalloc();
    80001994:	fffff097          	auipc	ra,0xfffff
    80001998:	160080e7          	jalr	352(ra) # 80000af4 <kalloc>
    8000199c:	862a                	mv	a2,a0
    if(pa == 0)
    8000199e:	c131                	beqz	a0,800019e2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019a0:	416485b3          	sub	a1,s1,s6
    800019a4:	858d                	srai	a1,a1,0x3
    800019a6:	000ab783          	ld	a5,0(s5)
    800019aa:	02f585b3          	mul	a1,a1,a5
    800019ae:	2585                	addiw	a1,a1,1
    800019b0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b4:	4719                	li	a4,6
    800019b6:	6685                	lui	a3,0x1
    800019b8:	40b905b3          	sub	a1,s2,a1
    800019bc:	854e                	mv	a0,s3
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	79a080e7          	jalr	1946(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	19848493          	addi	s1,s1,408
    800019ca:	fd4495e3          	bne	s1,s4,80001994 <proc_mapstacks+0x38>
  }
}
    800019ce:	70e2                	ld	ra,56(sp)
    800019d0:	7442                	ld	s0,48(sp)
    800019d2:	74a2                	ld	s1,40(sp)
    800019d4:	7902                	ld	s2,32(sp)
    800019d6:	69e2                	ld	s3,24(sp)
    800019d8:	6a42                	ld	s4,16(sp)
    800019da:	6aa2                	ld	s5,8(sp)
    800019dc:	6b02                	ld	s6,0(sp)
    800019de:	6121                	addi	sp,sp,64
    800019e0:	8082                	ret
      panic("kalloc");
    800019e2:	00008517          	auipc	a0,0x8
    800019e6:	84e50513          	addi	a0,a0,-1970 # 80009230 <digits+0x1f0>
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	b54080e7          	jalr	-1196(ra) # 8000053e <panic>

00000000800019f2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019f2:	711d                	addi	sp,sp,-96
    800019f4:	ec86                	sd	ra,88(sp)
    800019f6:	e8a2                	sd	s0,80(sp)
    800019f8:	e4a6                	sd	s1,72(sp)
    800019fa:	e0ca                	sd	s2,64(sp)
    800019fc:	fc4e                	sd	s3,56(sp)
    800019fe:	f852                	sd	s4,48(sp)
    80001a00:	f456                	sd	s5,40(sp)
    80001a02:	f05a                	sd	s6,32(sp)
    80001a04:	ec5e                	sd	s7,24(sp)
    80001a06:	e862                	sd	s8,16(sp)
    80001a08:	e466                	sd	s9,8(sp)
    80001a0a:	1080                	addi	s0,sp,96
  // Added
  program_time = 0;
    80001a0c:	00008797          	auipc	a5,0x8
    80001a10:	6207a623          	sw	zero,1580(a5) # 8000a038 <program_time>
  cpu_utilization = 0;
    80001a14:	00008797          	auipc	a5,0x8
    80001a18:	6007ae23          	sw	zero,1564(a5) # 8000a030 <cpu_utilization>
  start_time = ticks;
    80001a1c:	00008797          	auipc	a5,0x8
    80001a20:	6387a783          	lw	a5,1592(a5) # 8000a054 <ticks>
    80001a24:	00008717          	auipc	a4,0x8
    80001a28:	60f72823          	sw	a5,1552(a4) # 8000a034 <start_time>

  // TODO: add all to UNUSED.

  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a2c:	00008597          	auipc	a1,0x8
    80001a30:	80c58593          	addi	a1,a1,-2036 # 80009238 <digits+0x1f8>
    80001a34:	00011517          	auipc	a0,0x11
    80001a38:	88c50513          	addi	a0,a0,-1908 # 800122c0 <pid_lock>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	118080e7          	jalr	280(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a44:	00007597          	auipc	a1,0x7
    80001a48:	7fc58593          	addi	a1,a1,2044 # 80009240 <digits+0x200>
    80001a4c:	00011517          	auipc	a0,0x11
    80001a50:	88c50513          	addi	a0,a0,-1908 # 800122d8 <wait_lock>
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	100080e7          	jalr	256(ra) # 80000b54 <initlock>

  unused_list_head = proc->proc_ind;
    80001a5c:	00011497          	auipc	s1,0x11
    80001a60:	d1448493          	addi	s1,s1,-748 # 80012770 <proc>
    80001a64:	4cfc                	lw	a5,92(s1)
    80001a66:	00008717          	auipc	a4,0x8
    80001a6a:	f4f72f23          	sw	a5,-162(a4) # 800099c4 <unused_list_head>
  proc->prev_proc = -1;
    80001a6e:	577d                	li	a4,-1
    80001a70:	d0f8                	sw	a4,100(s1)
  unused_list_tail = proc->proc_ind;
    80001a72:	00008717          	auipc	a4,0x8
    80001a76:	f4f72723          	sw	a5,-178(a4) # 800099c0 <unused_list_tail>
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
    80001a7a:	00007597          	auipc	a1,0x7
    80001a7e:	7d658593          	addi	a1,a1,2006 # 80009250 <digits+0x210>
    80001a82:	8526                	mv	a0,s1
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	0d0080e7          	jalr	208(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a8c:	040007b7          	lui	a5,0x4000
    80001a90:	17f5                	addi	a5,a5,-3
    80001a92:	07b2                	slli	a5,a5,0xc
    80001a94:	f8bc                	sd	a5,112(s1)

      //Ass2
      p->proc_ind = i;                               // Set index to process.
    80001a96:	0404ae23          	sw	zero,92(s1)
  int i = 0;
    80001a9a:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a9c:	00017a97          	auipc	s5,0x17
    80001aa0:	2d4a8a93          	addi	s5,s5,724 # 80018d70 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001aa4:	8ba6                	mv	s7,s1
    80001aa6:	00007b17          	auipc	s6,0x7
    80001aaa:	55ab0b13          	addi	s6,s6,1370 # 80009000 <etext>
    80001aae:	04000a37          	lui	s4,0x4000
    80001ab2:	1a7d                	addi	s4,s4,-1
    80001ab4:	0a32                	slli	s4,s4,0xc
      if (i != 0)
      {
        printf("unused");
        add_proc_to_list(unused_list_tail, p);
    80001ab6:	00008c17          	auipc	s8,0x8
    80001aba:	f0ac0c13          	addi	s8,s8,-246 # 800099c0 <unused_list_tail>
         if (unused_list_head == -1)
    80001abe:	00008c97          	auipc	s9,0x8
    80001ac2:	f06c8c93          	addi	s9,s9,-250 # 800099c4 <unused_list_head>
    80001ac6:	a021                	j	80001ace <procinit+0xdc>
      {
        unused_list_head = p->proc_ind;
      }
        unused_list_tail = p->proc_ind;             // After adding to list, updating tail.
    80001ac8:	4cfc                	lw	a5,92(s1)
    80001aca:	00fc2023          	sw	a5,0(s8)
      }
      i ++;
    80001ace:	0019099b          	addiw	s3,s2,1
    80001ad2:	0009891b          	sext.w	s2,s3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad6:	19848493          	addi	s1,s1,408
    80001ada:	07548463          	beq	s1,s5,80001b42 <procinit+0x150>
      initlock(&p->lock, "proc");
    80001ade:	00007597          	auipc	a1,0x7
    80001ae2:	77258593          	addi	a1,a1,1906 # 80009250 <digits+0x210>
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	06c080e7          	jalr	108(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001af0:	417487b3          	sub	a5,s1,s7
    80001af4:	878d                	srai	a5,a5,0x3
    80001af6:	000b3703          	ld	a4,0(s6)
    80001afa:	02e787b3          	mul	a5,a5,a4
    80001afe:	2785                	addiw	a5,a5,1
    80001b00:	00d7979b          	slliw	a5,a5,0xd
    80001b04:	40fa07b3          	sub	a5,s4,a5
    80001b08:	f8bc                	sd	a5,112(s1)
      p->proc_ind = i;                               // Set index to process.
    80001b0a:	0534ae23          	sw	s3,92(s1)
      if (i != 0)
    80001b0e:	fc0900e3          	beqz	s2,80001ace <procinit+0xdc>
        printf("unused");
    80001b12:	00007517          	auipc	a0,0x7
    80001b16:	74650513          	addi	a0,a0,1862 # 80009258 <digits+0x218>
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	a6e080e7          	jalr	-1426(ra) # 80000588 <printf>
        add_proc_to_list(unused_list_tail, p);
    80001b22:	85a6                	mv	a1,s1
    80001b24:	000c2503          	lw	a0,0(s8)
    80001b28:	00000097          	auipc	ra,0x0
    80001b2c:	d1e080e7          	jalr	-738(ra) # 80001846 <add_proc_to_list>
         if (unused_list_head == -1)
    80001b30:	000ca703          	lw	a4,0(s9)
    80001b34:	57fd                	li	a5,-1
    80001b36:	f8f719e3          	bne	a4,a5,80001ac8 <procinit+0xd6>
        unused_list_head = p->proc_ind;
    80001b3a:	4cfc                	lw	a5,92(s1)
    80001b3c:	00fca023          	sw	a5,0(s9)
    80001b40:	b761                	j	80001ac8 <procinit+0xd6>
  }
}
    80001b42:	60e6                	ld	ra,88(sp)
    80001b44:	6446                	ld	s0,80(sp)
    80001b46:	64a6                	ld	s1,72(sp)
    80001b48:	6906                	ld	s2,64(sp)
    80001b4a:	79e2                	ld	s3,56(sp)
    80001b4c:	7a42                	ld	s4,48(sp)
    80001b4e:	7aa2                	ld	s5,40(sp)
    80001b50:	7b02                	ld	s6,32(sp)
    80001b52:	6be2                	ld	s7,24(sp)
    80001b54:	6c42                	ld	s8,16(sp)
    80001b56:	6ca2                	ld	s9,8(sp)
    80001b58:	6125                	addi	sp,sp,96
    80001b5a:	8082                	ret

0000000080001b5c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b5c:	1141                	addi	sp,sp,-16
    80001b5e:	e422                	sd	s0,8(sp)
    80001b60:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b62:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b64:	2501                	sext.w	a0,a0
    80001b66:	6422                	ld	s0,8(sp)
    80001b68:	0141                	addi	sp,sp,16
    80001b6a:	8082                	ret

0000000080001b6c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b6c:	1141                	addi	sp,sp,-16
    80001b6e:	e422                	sd	s0,8(sp)
    80001b70:	0800                	addi	s0,sp,16
    80001b72:	8512                	mv	a0,tp
  int id = r_tp();
    80001b74:	0005079b          	sext.w	a5,a0
  int id = cpuid();
  struct cpu *c = &cpus[id];
  c->cpu_id = id;
    80001b78:	00379513          	slli	a0,a5,0x3
    80001b7c:	00f50733          	add	a4,a0,a5
    80001b80:	00471693          	slli	a3,a4,0x4
    80001b84:	00010717          	auipc	a4,0x10
    80001b88:	73c70713          	addi	a4,a4,1852 # 800122c0 <pid_lock>
    80001b8c:	9736                	add	a4,a4,a3
    80001b8e:	0af72c23          	sw	a5,184(a4)
  return c;
}
    80001b92:	00010797          	auipc	a5,0x10
    80001b96:	75e78793          	addi	a5,a5,1886 # 800122f0 <cpus>
    80001b9a:	00d78533          	add	a0,a5,a3
    80001b9e:	6422                	ld	s0,8(sp)
    80001ba0:	0141                	addi	sp,sp,16
    80001ba2:	8082                	ret

0000000080001ba4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ba4:	1101                	addi	sp,sp,-32
    80001ba6:	ec06                	sd	ra,24(sp)
    80001ba8:	e822                	sd	s0,16(sp)
    80001baa:	e426                	sd	s1,8(sp)
    80001bac:	1000                	addi	s0,sp,32
  push_off();
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	fea080e7          	jalr	-22(ra) # 80000b98 <push_off>
    80001bb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001bb8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80001bbc:	00010617          	auipc	a2,0x10
    80001bc0:	70460613          	addi	a2,a2,1796 # 800122c0 <pid_lock>
    80001bc4:	00371793          	slli	a5,a4,0x3
    80001bc8:	00e786b3          	add	a3,a5,a4
    80001bcc:	0692                	slli	a3,a3,0x4
    80001bce:	96b2                	add	a3,a3,a2
    80001bd0:	0ae6ac23          	sw	a4,184(a3) # 10b8 <_entry-0x7fffef48>
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bd4:	7a84                	ld	s1,48(a3)
  pop_off();
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	062080e7          	jalr	98(ra) # 80000c38 <pop_off>
  return p;
}
    80001bde:	8526                	mv	a0,s1
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6105                	addi	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001bea:	1141                	addi	sp,sp,-16
    80001bec:	e406                	sd	ra,8(sp)
    80001bee:	e022                	sd	s0,0(sp)
    80001bf0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bf2:	00000097          	auipc	ra,0x0
    80001bf6:	fb2080e7          	jalr	-78(ra) # 80001ba4 <myproc>
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	09e080e7          	jalr	158(ra) # 80000c98 <release>

  if (first) {
    80001c02:	00008797          	auipc	a5,0x8
    80001c06:	dae7a783          	lw	a5,-594(a5) # 800099b0 <first.1771>
    80001c0a:	eb89                	bnez	a5,80001c1c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c0c:	00002097          	auipc	ra,0x2
    80001c10:	e3e080e7          	jalr	-450(ra) # 80003a4a <usertrapret>
}
    80001c14:	60a2                	ld	ra,8(sp)
    80001c16:	6402                	ld	s0,0(sp)
    80001c18:	0141                	addi	sp,sp,16
    80001c1a:	8082                	ret
    first = 0;
    80001c1c:	00008797          	auipc	a5,0x8
    80001c20:	d807aa23          	sw	zero,-620(a5) # 800099b0 <first.1771>
    fsinit(ROOTDEV);
    80001c24:	4505                	li	a0,1
    80001c26:	00003097          	auipc	ra,0x3
    80001c2a:	c20080e7          	jalr	-992(ra) # 80004846 <fsinit>
    80001c2e:	bff9                	j	80001c0c <forkret+0x22>

0000000080001c30 <allocpid>:
allocpid() {
    80001c30:	1101                	addi	sp,sp,-32
    80001c32:	ec06                	sd	ra,24(sp)
    80001c34:	e822                	sd	s0,16(sp)
    80001c36:	e426                	sd	s1,8(sp)
    80001c38:	1000                	addi	s0,sp,32
  pid = nextpid;
    80001c3a:	00008517          	auipc	a0,0x8
    80001c3e:	d7a50513          	addi	a0,a0,-646 # 800099b4 <nextpid>
    80001c42:	4104                	lw	s1,0(a0)
  if (cas(&nextpid, pid, (nextpid + 1)) == 0)
    80001c44:	0014861b          	addiw	a2,s1,1
    80001c48:	85a6                	mv	a1,s1
    80001c4a:	00006097          	auipc	ra,0x6
    80001c4e:	a0c080e7          	jalr	-1524(ra) # 80007656 <cas>
    80001c52:	e519                	bnez	a0,80001c60 <allocpid+0x30>
}
    80001c54:	8526                	mv	a0,s1
    80001c56:	60e2                	ld	ra,24(sp)
    80001c58:	6442                	ld	s0,16(sp)
    80001c5a:	64a2                	ld	s1,8(sp)
    80001c5c:	6105                	addi	sp,sp,32
    80001c5e:	8082                	ret
  return allocpid();
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	fd0080e7          	jalr	-48(ra) # 80001c30 <allocpid>
    80001c68:	84aa                	mv	s1,a0
    80001c6a:	b7ed                	j	80001c54 <allocpid+0x24>

0000000080001c6c <proc_pagetable>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	e04a                	sd	s2,0(sp)
    80001c76:	1000                	addi	s0,sp,32
    80001c78:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	6c8080e7          	jalr	1736(ra) # 80001342 <uvmcreate>
    80001c82:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c84:	c121                	beqz	a0,80001cc4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c86:	4729                	li	a4,10
    80001c88:	00006697          	auipc	a3,0x6
    80001c8c:	37868693          	addi	a3,a3,888 # 80008000 <_trampoline>
    80001c90:	6605                	lui	a2,0x1
    80001c92:	040005b7          	lui	a1,0x4000
    80001c96:	15fd                	addi	a1,a1,-1
    80001c98:	05b2                	slli	a1,a1,0xc
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	41e080e7          	jalr	1054(ra) # 800010b8 <mappages>
    80001ca2:	02054863          	bltz	a0,80001cd2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ca6:	4719                	li	a4,6
    80001ca8:	08893683          	ld	a3,136(s2) # 4000088 <_entry-0x7bffff78>
    80001cac:	6605                	lui	a2,0x1
    80001cae:	020005b7          	lui	a1,0x2000
    80001cb2:	15fd                	addi	a1,a1,-1
    80001cb4:	05b6                	slli	a1,a1,0xd
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	400080e7          	jalr	1024(ra) # 800010b8 <mappages>
    80001cc0:	02054163          	bltz	a0,80001ce2 <proc_pagetable+0x76>
}
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	60e2                	ld	ra,24(sp)
    80001cc8:	6442                	ld	s0,16(sp)
    80001cca:	64a2                	ld	s1,8(sp)
    80001ccc:	6902                	ld	s2,0(sp)
    80001cce:	6105                	addi	sp,sp,32
    80001cd0:	8082                	ret
    uvmfree(pagetable, 0);
    80001cd2:	4581                	li	a1,0
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	868080e7          	jalr	-1944(ra) # 8000153e <uvmfree>
    return 0;
    80001cde:	4481                	li	s1,0
    80001ce0:	b7d5                	j	80001cc4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ce2:	4681                	li	a3,0
    80001ce4:	4605                	li	a2,1
    80001ce6:	040005b7          	lui	a1,0x4000
    80001cea:	15fd                	addi	a1,a1,-1
    80001cec:	05b2                	slli	a1,a1,0xc
    80001cee:	8526                	mv	a0,s1
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	58e080e7          	jalr	1422(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001cf8:	4581                	li	a1,0
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	842080e7          	jalr	-1982(ra) # 8000153e <uvmfree>
    return 0;
    80001d04:	4481                	li	s1,0
    80001d06:	bf7d                	j	80001cc4 <proc_pagetable+0x58>

0000000080001d08 <proc_freepagetable>:
{
    80001d08:	1101                	addi	sp,sp,-32
    80001d0a:	ec06                	sd	ra,24(sp)
    80001d0c:	e822                	sd	s0,16(sp)
    80001d0e:	e426                	sd	s1,8(sp)
    80001d10:	e04a                	sd	s2,0(sp)
    80001d12:	1000                	addi	s0,sp,32
    80001d14:	84aa                	mv	s1,a0
    80001d16:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d18:	4681                	li	a3,0
    80001d1a:	4605                	li	a2,1
    80001d1c:	040005b7          	lui	a1,0x4000
    80001d20:	15fd                	addi	a1,a1,-1
    80001d22:	05b2                	slli	a1,a1,0xc
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	55a080e7          	jalr	1370(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d2c:	4681                	li	a3,0
    80001d2e:	4605                	li	a2,1
    80001d30:	020005b7          	lui	a1,0x2000
    80001d34:	15fd                	addi	a1,a1,-1
    80001d36:	05b6                	slli	a1,a1,0xd
    80001d38:	8526                	mv	a0,s1
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	544080e7          	jalr	1348(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001d42:	85ca                	mv	a1,s2
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	7f8080e7          	jalr	2040(ra) # 8000153e <uvmfree>
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret

0000000080001d5a <freeproc>:
{
    80001d5a:	1101                	addi	sp,sp,-32
    80001d5c:	ec06                	sd	ra,24(sp)
    80001d5e:	e822                	sd	s0,16(sp)
    80001d60:	e426                	sd	s1,8(sp)
    80001d62:	1000                	addi	s0,sp,32
    80001d64:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d66:	6548                	ld	a0,136(a0)
    80001d68:	c509                	beqz	a0,80001d72 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	c8e080e7          	jalr	-882(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d72:	0804b423          	sd	zero,136(s1)
  if(p->pagetable)
    80001d76:	60c8                	ld	a0,128(s1)
    80001d78:	c511                	beqz	a0,80001d84 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d7a:	7cac                	ld	a1,120(s1)
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	f8c080e7          	jalr	-116(ra) # 80001d08 <proc_freepagetable>
  p->pagetable = 0;
    80001d84:	0804b023          	sd	zero,128(s1)
  p->sz = 0;
    80001d88:	0604bc23          	sd	zero,120(s1)
  p->pid = 0;
    80001d8c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d90:	0604b423          	sd	zero,104(s1)
  p->name[0] = 0;
    80001d94:	18048423          	sb	zero,392(s1)
  p->chan = 0;
    80001d98:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d9c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001da0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001da4:	0004ac23          	sw	zero,24(s1)
  printf("zombie");
    80001da8:	00007517          	auipc	a0,0x7
    80001dac:	4b850513          	addi	a0,a0,1208 # 80009260 <digits+0x220>
    80001db0:	ffffe097          	auipc	ra,0xffffe
    80001db4:	7d8080e7          	jalr	2008(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80001db8:	4ce8                	lw	a0,92(s1)
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	aea080e7          	jalr	-1302(ra) # 800018a4 <remove_proc_from_list>
  if (res == 1){
    80001dc2:	4785                	li	a5,1
    80001dc4:	02f50663          	beq	a0,a5,80001df0 <freeproc+0x96>
  if (res == 2){
    80001dc8:	4789                	li	a5,2
    80001dca:	06f51463          	bne	a0,a5,80001e32 <freeproc+0xd8>
    zombie_list_head = p->next_proc;
    80001dce:	50bc                	lw	a5,96(s1)
    80001dd0:	00008717          	auipc	a4,0x8
    80001dd4:	bef72623          	sw	a5,-1044(a4) # 800099bc <zombie_list_head>
    proc[p->next_proc].prev_proc = -1;
    80001dd8:	19800713          	li	a4,408
    80001ddc:	02e787b3          	mul	a5,a5,a4
    80001de0:	00011717          	auipc	a4,0x11
    80001de4:	99070713          	addi	a4,a4,-1648 # 80012770 <proc>
    80001de8:	97ba                	add	a5,a5,a4
    80001dea:	577d                	li	a4,-1
    80001dec:	d3f8                	sw	a4,100(a5)
  if (res == 3){
    80001dee:	a811                	j	80001e02 <freeproc+0xa8>
    zombie_list_head = -1;
    80001df0:	57fd                	li	a5,-1
    80001df2:	00008717          	auipc	a4,0x8
    80001df6:	bcf72523          	sw	a5,-1078(a4) # 800099bc <zombie_list_head>
    zombie_list_tail = -1;
    80001dfa:	00008717          	auipc	a4,0x8
    80001dfe:	baf72f23          	sw	a5,-1090(a4) # 800099b8 <zombie_list_tail>
  p->next_proc = -1;
    80001e02:	57fd                	li	a5,-1
    80001e04:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80001e06:	d0fc                	sw	a5,100(s1)
  if (unused_list_tail != -1){
    80001e08:	00008717          	auipc	a4,0x8
    80001e0c:	bb872703          	lw	a4,-1096(a4) # 800099c0 <unused_list_tail>
    80001e10:	57fd                	li	a5,-1
    80001e12:	04f71463          	bne	a4,a5,80001e5a <freeproc+0x100>
    unused_list_tail = unused_list_head = p->proc_ind;
    80001e16:	4cfc                	lw	a5,92(s1)
    80001e18:	00008717          	auipc	a4,0x8
    80001e1c:	baf72623          	sw	a5,-1108(a4) # 800099c4 <unused_list_head>
    80001e20:	00008717          	auipc	a4,0x8
    80001e24:	baf72023          	sw	a5,-1120(a4) # 800099c0 <unused_list_tail>
}
    80001e28:	60e2                	ld	ra,24(sp)
    80001e2a:	6442                	ld	s0,16(sp)
    80001e2c:	64a2                	ld	s1,8(sp)
    80001e2e:	6105                	addi	sp,sp,32
    80001e30:	8082                	ret
  if (res == 3){
    80001e32:	478d                	li	a5,3
    80001e34:	fcf517e3          	bne	a0,a5,80001e02 <freeproc+0xa8>
    zombie_list_tail = p->prev_proc;
    80001e38:	50fc                	lw	a5,100(s1)
    80001e3a:	00008717          	auipc	a4,0x8
    80001e3e:	b6f72f23          	sw	a5,-1154(a4) # 800099b8 <zombie_list_tail>
    proc[p->prev_proc].next_proc = -1;
    80001e42:	19800713          	li	a4,408
    80001e46:	02e787b3          	mul	a5,a5,a4
    80001e4a:	00011717          	auipc	a4,0x11
    80001e4e:	92670713          	addi	a4,a4,-1754 # 80012770 <proc>
    80001e52:	97ba                	add	a5,a5,a4
    80001e54:	577d                	li	a4,-1
    80001e56:	d3b8                	sw	a4,96(a5)
    80001e58:	b76d                	j	80001e02 <freeproc+0xa8>
    printf("unused");
    80001e5a:	00007517          	auipc	a0,0x7
    80001e5e:	3fe50513          	addi	a0,a0,1022 # 80009258 <digits+0x218>
    80001e62:	ffffe097          	auipc	ra,0xffffe
    80001e66:	726080e7          	jalr	1830(ra) # 80000588 <printf>
    add_proc_to_list(unused_list_tail, p);
    80001e6a:	85a6                	mv	a1,s1
    80001e6c:	00008517          	auipc	a0,0x8
    80001e70:	b5452503          	lw	a0,-1196(a0) # 800099c0 <unused_list_tail>
    80001e74:	00000097          	auipc	ra,0x0
    80001e78:	9d2080e7          	jalr	-1582(ra) # 80001846 <add_proc_to_list>
    if (unused_list_head == -1)
    80001e7c:	00008717          	auipc	a4,0x8
    80001e80:	b4872703          	lw	a4,-1208(a4) # 800099c4 <unused_list_head>
    80001e84:	57fd                	li	a5,-1
    80001e86:	00f70863          	beq	a4,a5,80001e96 <freeproc+0x13c>
    unused_list_tail = p->proc_ind;
    80001e8a:	4cfc                	lw	a5,92(s1)
    80001e8c:	00008717          	auipc	a4,0x8
    80001e90:	b2f72a23          	sw	a5,-1228(a4) # 800099c0 <unused_list_tail>
    80001e94:	bf51                	j	80001e28 <freeproc+0xce>
    unused_list_head = p->proc_ind;
    80001e96:	4cfc                	lw	a5,92(s1)
    80001e98:	00008717          	auipc	a4,0x8
    80001e9c:	b2f72623          	sw	a5,-1236(a4) # 800099c4 <unused_list_head>
    80001ea0:	b7ed                	j	80001e8a <freeproc+0x130>

0000000080001ea2 <allocproc>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	0080                	addi	s0,sp,64
  if (unused_list_head > -1)
    80001eb4:	00008917          	auipc	s2,0x8
    80001eb8:	b1092903          	lw	s2,-1264(s2) # 800099c4 <unused_list_head>
  return 0;
    80001ebc:	4981                	li	s3,0
  if (unused_list_head > -1)
    80001ebe:	00095c63          	bgez	s2,80001ed6 <allocproc+0x34>
}
    80001ec2:	854e                	mv	a0,s3
    80001ec4:	70e2                	ld	ra,56(sp)
    80001ec6:	7442                	ld	s0,48(sp)
    80001ec8:	74a2                	ld	s1,40(sp)
    80001eca:	7902                	ld	s2,32(sp)
    80001ecc:	69e2                	ld	s3,24(sp)
    80001ece:	6a42                	ld	s4,16(sp)
    80001ed0:	6aa2                	ld	s5,8(sp)
    80001ed2:	6121                	addi	sp,sp,64
    80001ed4:	8082                	ret
    p = &proc[unused_list_head];
    80001ed6:	19800a13          	li	s4,408
    80001eda:	03490a33          	mul	s4,s2,s4
    80001ede:	00011997          	auipc	s3,0x11
    80001ee2:	89298993          	addi	s3,s3,-1902 # 80012770 <proc>
    80001ee6:	99d2                	add	s3,s3,s4
    acquire(&p->lock);
    80001ee8:	854e                	mv	a0,s3
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	cfa080e7          	jalr	-774(ra) # 80000be4 <acquire>
    printf("unused");
    80001ef2:	00007517          	auipc	a0,0x7
    80001ef6:	36650513          	addi	a0,a0,870 # 80009258 <digits+0x218>
    80001efa:	ffffe097          	auipc	ra,0xffffe
    80001efe:	68e080e7          	jalr	1678(ra) # 80000588 <printf>
    int res = remove_proc_from_list(unused_list_head); 
    80001f02:	00008517          	auipc	a0,0x8
    80001f06:	ac252503          	lw	a0,-1342(a0) # 800099c4 <unused_list_head>
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	99a080e7          	jalr	-1638(ra) # 800018a4 <remove_proc_from_list>
    if (res == 1){
    80001f12:	4785                	li	a5,1
    80001f14:	02f50963          	beq	a0,a5,80001f46 <allocproc+0xa4>
    if (res == 2){
    80001f18:	4789                	li	a5,2
    80001f1a:	0ef51663          	bne	a0,a5,80002006 <allocproc+0x164>
      unused_list_head = p->next_proc;      // Update head.
    80001f1e:	00011797          	auipc	a5,0x11
    80001f22:	85278793          	addi	a5,a5,-1966 # 80012770 <proc>
    80001f26:	19800613          	li	a2,408
    80001f2a:	02c906b3          	mul	a3,s2,a2
    80001f2e:	96be                	add	a3,a3,a5
    80001f30:	52b8                	lw	a4,96(a3)
    80001f32:	00008697          	auipc	a3,0x8
    80001f36:	a8e6a923          	sw	a4,-1390(a3) # 800099c4 <unused_list_head>
      proc[p->next_proc].prev_proc = -1;    // Remove head's prev.
    80001f3a:	02c70733          	mul	a4,a4,a2
    80001f3e:	97ba                	add	a5,a5,a4
    80001f40:	577d                	li	a4,-1
    80001f42:	d3f8                	sw	a4,100(a5)
    if (res == 3){
    80001f44:	a811                	j	80001f58 <allocproc+0xb6>
      unused_list_head = -1;
    80001f46:	57fd                	li	a5,-1
    80001f48:	00008717          	auipc	a4,0x8
    80001f4c:	a6f72e23          	sw	a5,-1412(a4) # 800099c4 <unused_list_head>
      unused_list_tail = -1;
    80001f50:	00008717          	auipc	a4,0x8
    80001f54:	a6f72823          	sw	a5,-1424(a4) # 800099c0 <unused_list_tail>
    p->prev_proc = -1;
    80001f58:	19800493          	li	s1,408
    80001f5c:	029907b3          	mul	a5,s2,s1
    80001f60:	00011497          	auipc	s1,0x11
    80001f64:	81048493          	addi	s1,s1,-2032 # 80012770 <proc>
    80001f68:	94be                	add	s1,s1,a5
    80001f6a:	57fd                	li	a5,-1
    80001f6c:	d0fc                	sw	a5,100(s1)
    p->next_proc = -1;
    80001f6e:	d0bc                	sw	a5,96(s1)
  p->pid = allocpid();
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	cc0080e7          	jalr	-832(ra) # 80001c30 <allocpid>
    80001f78:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001f7a:	4785                	li	a5,1
    80001f7c:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001f7e:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001f82:	0204ac23          	sw	zero,56(s1)
  p->paused = 0;
    80001f86:	0404a023          	sw	zero,64(s1)
  p->sleeping_time = 0;
    80001f8a:	0404a623          	sw	zero,76(s1)
  p->running_time = 0;
    80001f8e:	0404a223          	sw	zero,68(s1)
  p->runnable_time = 0;
    80001f92:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	b5e080e7          	jalr	-1186(ra) # 80000af4 <kalloc>
    80001f9e:	8aaa                	mv	s5,a0
    80001fa0:	e4c8                	sd	a0,136(s1)
    80001fa2:	c949                	beqz	a0,80002034 <allocproc+0x192>
  p->pagetable = proc_pagetable(p);
    80001fa4:	854e                	mv	a0,s3
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	cc6080e7          	jalr	-826(ra) # 80001c6c <proc_pagetable>
    80001fae:	84aa                	mv	s1,a0
    80001fb0:	19800793          	li	a5,408
    80001fb4:	02f90733          	mul	a4,s2,a5
    80001fb8:	00010797          	auipc	a5,0x10
    80001fbc:	7b878793          	addi	a5,a5,1976 # 80012770 <proc>
    80001fc0:	97ba                	add	a5,a5,a4
    80001fc2:	e3c8                	sd	a0,128(a5)
  if(p->pagetable == 0){
    80001fc4:	c541                	beqz	a0,8000204c <allocproc+0x1aa>
  memset(&p->context, 0, sizeof(p->context));
    80001fc6:	090a0513          	addi	a0,s4,144 # 4000090 <_entry-0x7bffff70>
    80001fca:	00010497          	auipc	s1,0x10
    80001fce:	7a648493          	addi	s1,s1,1958 # 80012770 <proc>
    80001fd2:	07000613          	li	a2,112
    80001fd6:	4581                	li	a1,0
    80001fd8:	9526                	add	a0,a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	d06080e7          	jalr	-762(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001fe2:	19800793          	li	a5,408
    80001fe6:	02f90933          	mul	s2,s2,a5
    80001fea:	9926                	add	s2,s2,s1
    80001fec:	00000797          	auipc	a5,0x0
    80001ff0:	bfe78793          	addi	a5,a5,-1026 # 80001bea <forkret>
    80001ff4:	08f93823          	sd	a5,144(s2)
  p->context.sp = p->kstack + PGSIZE;
    80001ff8:	07093783          	ld	a5,112(s2)
    80001ffc:	6705                	lui	a4,0x1
    80001ffe:	97ba                	add	a5,a5,a4
    80002000:	08f93c23          	sd	a5,152(s2)
  return p;
    80002004:	bd7d                	j	80001ec2 <allocproc+0x20>
    if (res == 3){
    80002006:	478d                	li	a5,3
    80002008:	f4f518e3          	bne	a0,a5,80001f58 <allocproc+0xb6>
      unused_list_tail = p->prev_proc;      // Update tail.
    8000200c:	00010797          	auipc	a5,0x10
    80002010:	76478793          	addi	a5,a5,1892 # 80012770 <proc>
    80002014:	19800613          	li	a2,408
    80002018:	02c906b3          	mul	a3,s2,a2
    8000201c:	96be                	add	a3,a3,a5
    8000201e:	52f8                	lw	a4,100(a3)
    80002020:	00008697          	auipc	a3,0x8
    80002024:	9ae6a023          	sw	a4,-1632(a3) # 800099c0 <unused_list_tail>
      proc[p->prev_proc].next_proc = -1;    // Remove tail's next.
    80002028:	02c70733          	mul	a4,a4,a2
    8000202c:	97ba                	add	a5,a5,a4
    8000202e:	577d                	li	a4,-1
    80002030:	d3b8                	sw	a4,96(a5)
    80002032:	b71d                	j	80001f58 <allocproc+0xb6>
    freeproc(p);
    80002034:	854e                	mv	a0,s3
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	d24080e7          	jalr	-732(ra) # 80001d5a <freeproc>
    release(&p->lock);
    8000203e:	854e                	mv	a0,s3
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	c58080e7          	jalr	-936(ra) # 80000c98 <release>
    return 0;
    80002048:	89d6                	mv	s3,s5
    8000204a:	bda5                	j	80001ec2 <allocproc+0x20>
    freeproc(p);
    8000204c:	854e                	mv	a0,s3
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	d0c080e7          	jalr	-756(ra) # 80001d5a <freeproc>
    release(&p->lock);
    80002056:	854e                	mv	a0,s3
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c40080e7          	jalr	-960(ra) # 80000c98 <release>
    return 0;
    80002060:	89a6                	mv	s3,s1
    80002062:	b585                	j	80001ec2 <allocproc+0x20>

0000000080002064 <str_compare>:
{
    80002064:	1141                	addi	sp,sp,-16
    80002066:	e422                	sd	s0,8(sp)
    80002068:	0800                	addi	s0,sp,16
      c1 = (unsigned char) *s1++;
    8000206a:	0505                	addi	a0,a0,1
    8000206c:	fff54783          	lbu	a5,-1(a0)
      c2 = (unsigned char) *s2++;
    80002070:	0585                	addi	a1,a1,1
    80002072:	fff5c703          	lbu	a4,-1(a1) # 1ffffff <_entry-0x7e000001>
      if (c1 == '\0')
    80002076:	c791                	beqz	a5,80002082 <str_compare+0x1e>
  while (c1 == c2);
    80002078:	fee789e3          	beq	a5,a4,8000206a <str_compare+0x6>
  return c1 - c2;
    8000207c:	40e7853b          	subw	a0,a5,a4
    80002080:	a019                	j	80002086 <str_compare+0x22>
        return c1 - c2;
    80002082:	40e0053b          	negw	a0,a4
}
    80002086:	6422                	ld	s0,8(sp)
    80002088:	0141                	addi	sp,sp,16
    8000208a:	8082                	ret

000000008000208c <userinit>:
{
    8000208c:	1101                	addi	sp,sp,-32
    8000208e:	ec06                	sd	ra,24(sp)
    80002090:	e822                	sd	s0,16(sp)
    80002092:	e426                	sd	s1,8(sp)
    80002094:	1000                	addi	s0,sp,32
  p = allocproc();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	e0c080e7          	jalr	-500(ra) # 80001ea2 <allocproc>
    8000209e:	84aa                	mv	s1,a0
  initproc = p;
    800020a0:	00008797          	auipc	a5,0x8
    800020a4:	f8a7b423          	sd	a0,-120(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800020a8:	03400613          	li	a2,52
    800020ac:	00008597          	auipc	a1,0x8
    800020b0:	93458593          	addi	a1,a1,-1740 # 800099e0 <initcode>
    800020b4:	6148                	ld	a0,128(a0)
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	2ba080e7          	jalr	698(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    800020be:	6785                	lui	a5,0x1
    800020c0:	fcbc                	sd	a5,120(s1)
  p->trapframe->epc = 0;      // user program counter
    800020c2:	64d8                	ld	a4,136(s1)
    800020c4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020c8:	64d8                	ld	a4,136(s1)
    800020ca:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020cc:	4641                	li	a2,16
    800020ce:	00007597          	auipc	a1,0x7
    800020d2:	19a58593          	addi	a1,a1,410 # 80009268 <digits+0x228>
    800020d6:	18848513          	addi	a0,s1,392
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	d58080e7          	jalr	-680(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800020e2:	00007517          	auipc	a0,0x7
    800020e6:	19650513          	addi	a0,a0,406 # 80009278 <digits+0x238>
    800020ea:	00003097          	auipc	ra,0x3
    800020ee:	18a080e7          	jalr	394(ra) # 80005274 <namei>
    800020f2:	18a4b023          	sd	a0,384(s1)
  p->state = RUNNABLE;
    800020f6:	478d                	li	a5,3
    800020f8:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    800020fa:	00008797          	auipc	a5,0x8
    800020fe:	f5a7a783          	lw	a5,-166(a5) # 8000a054 <ticks>
    80002102:	dcdc                	sw	a5,60(s1)
    80002104:	8792                	mv	a5,tp
  int id = r_tp();
    80002106:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    8000210a:	00010617          	auipc	a2,0x10
    8000210e:	1b660613          	addi	a2,a2,438 # 800122c0 <pid_lock>
    80002112:	00371793          	slli	a5,a4,0x3
    80002116:	00e786b3          	add	a3,a5,a4
    8000211a:	0692                	slli	a3,a3,0x4
    8000211c:	96b2                	add	a3,a3,a2
    8000211e:	0ae6ac23          	sw	a4,184(a3)
  if (mycpu()->runnable_list_head == -1){
    80002122:	0b06a703          	lw	a4,176(a3)
    80002126:	57fd                	li	a5,-1
    80002128:	04f70a63          	beq	a4,a5,8000217c <userinit+0xf0>
    printf("runnable");
    8000212c:	00007517          	auipc	a0,0x7
    80002130:	15450513          	addi	a0,a0,340 # 80009280 <digits+0x240>
    80002134:	ffffe097          	auipc	ra,0xffffe
    80002138:	454080e7          	jalr	1108(ra) # 80000588 <printf>
    8000213c:	8792                	mv	a5,tp
  int id = r_tp();
    8000213e:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002142:	00010617          	auipc	a2,0x10
    80002146:	17e60613          	addi	a2,a2,382 # 800122c0 <pid_lock>
    8000214a:	00371793          	slli	a5,a4,0x3
    8000214e:	00e786b3          	add	a3,a5,a4
    80002152:	0692                	slli	a3,a3,0x4
    80002154:	96b2                	add	a3,a3,a2
    80002156:	0ae6ac23          	sw	a4,184(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    8000215a:	85a6                	mv	a1,s1
    8000215c:	0b46a503          	lw	a0,180(a3)
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	6e6080e7          	jalr	1766(ra) # 80001846 <add_proc_to_list>
  release(&p->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	b2e080e7          	jalr	-1234(ra) # 80000c98 <release>
}
    80002172:	60e2                	ld	ra,24(sp)
    80002174:	6442                	ld	s0,16(sp)
    80002176:	64a2                	ld	s1,8(sp)
    80002178:	6105                	addi	sp,sp,32
    8000217a:	8082                	ret
    8000217c:	8792                	mv	a5,tp
  int id = r_tp();
    8000217e:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002182:	8732                	mv	a4,a2
    80002184:	00369793          	slli	a5,a3,0x3
    80002188:	00d78633          	add	a2,a5,a3
    8000218c:	0612                	slli	a2,a2,0x4
    8000218e:	963a                	add	a2,a2,a4
    80002190:	0ad62c23          	sw	a3,184(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    80002194:	4cf0                	lw	a2,92(s1)
    80002196:	97b6                	add	a5,a5,a3
    80002198:	0792                	slli	a5,a5,0x4
    8000219a:	97ba                	add	a5,a5,a4
    8000219c:	0ac7a823          	sw	a2,176(a5)
    800021a0:	8792                	mv	a5,tp
  int id = r_tp();
    800021a2:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    800021a6:	00369793          	slli	a5,a3,0x3
    800021aa:	00d78633          	add	a2,a5,a3
    800021ae:	0612                	slli	a2,a2,0x4
    800021b0:	963a                	add	a2,a2,a4
    800021b2:	0ad62c23          	sw	a3,184(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    800021b6:	4cf0                	lw	a2,92(s1)
    800021b8:	97b6                	add	a5,a5,a3
    800021ba:	0792                	slli	a5,a5,0x4
    800021bc:	973e                	add	a4,a4,a5
    800021be:	0ac72a23          	sw	a2,180(a4)
    800021c2:	b75d                	j	80002168 <userinit+0xdc>

00000000800021c4 <growproc>:
{
    800021c4:	1101                	addi	sp,sp,-32
    800021c6:	ec06                	sd	ra,24(sp)
    800021c8:	e822                	sd	s0,16(sp)
    800021ca:	e426                	sd	s1,8(sp)
    800021cc:	e04a                	sd	s2,0(sp)
    800021ce:	1000                	addi	s0,sp,32
    800021d0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	9d2080e7          	jalr	-1582(ra) # 80001ba4 <myproc>
    800021da:	892a                	mv	s2,a0
  sz = p->sz;
    800021dc:	7d2c                	ld	a1,120(a0)
    800021de:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800021e2:	00904f63          	bgtz	s1,80002200 <growproc+0x3c>
  } else if(n < 0){
    800021e6:	0204cc63          	bltz	s1,8000221e <growproc+0x5a>
  p->sz = sz;
    800021ea:	1602                	slli	a2,a2,0x20
    800021ec:	9201                	srli	a2,a2,0x20
    800021ee:	06c93c23          	sd	a2,120(s2)
  return 0;
    800021f2:	4501                	li	a0,0
}
    800021f4:	60e2                	ld	ra,24(sp)
    800021f6:	6442                	ld	s0,16(sp)
    800021f8:	64a2                	ld	s1,8(sp)
    800021fa:	6902                	ld	s2,0(sp)
    800021fc:	6105                	addi	sp,sp,32
    800021fe:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002200:	9e25                	addw	a2,a2,s1
    80002202:	1602                	slli	a2,a2,0x20
    80002204:	9201                	srli	a2,a2,0x20
    80002206:	1582                	slli	a1,a1,0x20
    80002208:	9181                	srli	a1,a1,0x20
    8000220a:	6148                	ld	a0,128(a0)
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	21e080e7          	jalr	542(ra) # 8000142a <uvmalloc>
    80002214:	0005061b          	sext.w	a2,a0
    80002218:	fa69                	bnez	a2,800021ea <growproc+0x26>
      return -1;
    8000221a:	557d                	li	a0,-1
    8000221c:	bfe1                	j	800021f4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000221e:	9e25                	addw	a2,a2,s1
    80002220:	1602                	slli	a2,a2,0x20
    80002222:	9201                	srli	a2,a2,0x20
    80002224:	1582                	slli	a1,a1,0x20
    80002226:	9181                	srli	a1,a1,0x20
    80002228:	6148                	ld	a0,128(a0)
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	1b8080e7          	jalr	440(ra) # 800013e2 <uvmdealloc>
    80002232:	0005061b          	sext.w	a2,a0
    80002236:	bf55                	j	800021ea <growproc+0x26>

0000000080002238 <fork>:
{
    80002238:	7139                	addi	sp,sp,-64
    8000223a:	fc06                	sd	ra,56(sp)
    8000223c:	f822                	sd	s0,48(sp)
    8000223e:	f426                	sd	s1,40(sp)
    80002240:	f04a                	sd	s2,32(sp)
    80002242:	ec4e                	sd	s3,24(sp)
    80002244:	e852                	sd	s4,16(sp)
    80002246:	e456                	sd	s5,8(sp)
    80002248:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	95a080e7          	jalr	-1702(ra) # 80001ba4 <myproc>
    80002252:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002254:	00000097          	auipc	ra,0x0
    80002258:	c4e080e7          	jalr	-946(ra) # 80001ea2 <allocproc>
    8000225c:	24050763          	beqz	a0,800024aa <fork+0x272>
    80002260:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002262:	0789b603          	ld	a2,120(s3)
    80002266:	614c                	ld	a1,128(a0)
    80002268:	0809b503          	ld	a0,128(s3)
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	30a080e7          	jalr	778(ra) # 80001576 <uvmcopy>
    80002274:	04054663          	bltz	a0,800022c0 <fork+0x88>
  np->sz = p->sz;
    80002278:	0789b783          	ld	a5,120(s3)
    8000227c:	06f93c23          	sd	a5,120(s2)
  *(np->trapframe) = *(p->trapframe);
    80002280:	0889b683          	ld	a3,136(s3)
    80002284:	87b6                	mv	a5,a3
    80002286:	08893703          	ld	a4,136(s2)
    8000228a:	12068693          	addi	a3,a3,288
    8000228e:	0007b803          	ld	a6,0(a5)
    80002292:	6788                	ld	a0,8(a5)
    80002294:	6b8c                	ld	a1,16(a5)
    80002296:	6f90                	ld	a2,24(a5)
    80002298:	01073023          	sd	a6,0(a4)
    8000229c:	e708                	sd	a0,8(a4)
    8000229e:	eb0c                	sd	a1,16(a4)
    800022a0:	ef10                	sd	a2,24(a4)
    800022a2:	02078793          	addi	a5,a5,32
    800022a6:	02070713          	addi	a4,a4,32
    800022aa:	fed792e3          	bne	a5,a3,8000228e <fork+0x56>
  np->trapframe->a0 = 0;
    800022ae:	08893783          	ld	a5,136(s2)
    800022b2:	0607b823          	sd	zero,112(a5)
    800022b6:	10000493          	li	s1,256
  for(i = 0; i < NOFILE; i++)
    800022ba:	18000a13          	li	s4,384
    800022be:	a03d                	j	800022ec <fork+0xb4>
    freeproc(np);
    800022c0:	854a                	mv	a0,s2
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	a98080e7          	jalr	-1384(ra) # 80001d5a <freeproc>
    release(&np->lock);
    800022ca:	854a                	mv	a0,s2
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9cc080e7          	jalr	-1588(ra) # 80000c98 <release>
    return -1;
    800022d4:	5a7d                	li	s4,-1
    800022d6:	a299                	j	8000241c <fork+0x1e4>
      np->ofile[i] = filedup(p->ofile[i]);
    800022d8:	00003097          	auipc	ra,0x3
    800022dc:	632080e7          	jalr	1586(ra) # 8000590a <filedup>
    800022e0:	009907b3          	add	a5,s2,s1
    800022e4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800022e6:	04a1                	addi	s1,s1,8
    800022e8:	01448763          	beq	s1,s4,800022f6 <fork+0xbe>
    if(p->ofile[i])
    800022ec:	009987b3          	add	a5,s3,s1
    800022f0:	6388                	ld	a0,0(a5)
    800022f2:	f17d                	bnez	a0,800022d8 <fork+0xa0>
    800022f4:	bfcd                	j	800022e6 <fork+0xae>
  np->cwd = idup(p->cwd);
    800022f6:	1809b503          	ld	a0,384(s3)
    800022fa:	00002097          	auipc	ra,0x2
    800022fe:	786080e7          	jalr	1926(ra) # 80004a80 <idup>
    80002302:	18a93023          	sd	a0,384(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002306:	4641                	li	a2,16
    80002308:	18898593          	addi	a1,s3,392
    8000230c:	18890513          	addi	a0,s2,392
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	b22080e7          	jalr	-1246(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002318:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    8000231c:	854a                	mv	a0,s2
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	97a080e7          	jalr	-1670(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002326:	00010497          	auipc	s1,0x10
    8000232a:	f9a48493          	addi	s1,s1,-102 # 800122c0 <pid_lock>
    8000232e:	00010a97          	auipc	s5,0x10
    80002332:	faaa8a93          	addi	s5,s5,-86 # 800122d8 <wait_lock>
    80002336:	8556                	mv	a0,s5
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	8ac080e7          	jalr	-1876(ra) # 80000be4 <acquire>
  np->parent = p;
    80002340:	07393423          	sd	s3,104(s2)
  release(&wait_lock);
    80002344:	8556                	mv	a0,s5
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	952080e7          	jalr	-1710(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000234e:	854a                	mv	a0,s2
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	894080e7          	jalr	-1900(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002358:	478d                	li	a5,3
    8000235a:	00f92c23          	sw	a5,24(s2)
  np->last_runnable_time = ticks;
    8000235e:	00008797          	auipc	a5,0x8
    80002362:	cf67a783          	lw	a5,-778(a5) # 8000a054 <ticks>
    80002366:	02f92e23          	sw	a5,60(s2)
    8000236a:	8792                	mv	a5,tp
  int id = r_tp();
    8000236c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002370:	00371793          	slli	a5,a4,0x3
    80002374:	00e786b3          	add	a3,a5,a4
    80002378:	0692                	slli	a3,a3,0x4
    8000237a:	96a6                	add	a3,a3,s1
    8000237c:	0ae6ac23          	sw	a4,184(a3)
  if (mycpu()->runnable_list_head == -1){
    80002380:	0b06a703          	lw	a4,176(a3)
    80002384:	57fd                	li	a5,-1
    80002386:	0af70563          	beq	a4,a5,80002430 <fork+0x1f8>
    printf("runnable");
    8000238a:	00007517          	auipc	a0,0x7
    8000238e:	ef650513          	addi	a0,a0,-266 # 80009280 <digits+0x240>
    80002392:	ffffe097          	auipc	ra,0xffffe
    80002396:	1f6080e7          	jalr	502(ra) # 80000588 <printf>
    8000239a:	8792                	mv	a5,tp
  int id = r_tp();
    8000239c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800023a0:	00010497          	auipc	s1,0x10
    800023a4:	f2048493          	addi	s1,s1,-224 # 800122c0 <pid_lock>
    800023a8:	00371793          	slli	a5,a4,0x3
    800023ac:	00e786b3          	add	a3,a5,a4
    800023b0:	0692                	slli	a3,a3,0x4
    800023b2:	96a6                	add	a3,a3,s1
    800023b4:	0ae6ac23          	sw	a4,184(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, np);
    800023b8:	85ca                	mv	a1,s2
    800023ba:	0b46a503          	lw	a0,180(a3)
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	488080e7          	jalr	1160(ra) # 80001846 <add_proc_to_list>
    800023c6:	8792                	mv	a5,tp
  int id = r_tp();
    800023c8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800023cc:	00371793          	slli	a5,a4,0x3
    800023d0:	00e786b3          	add	a3,a5,a4
    800023d4:	0692                	slli	a3,a3,0x4
    800023d6:	96a6                	add	a3,a3,s1
    800023d8:	0ae6ac23          	sw	a4,184(a3)
    if (mycpu()->runnable_list_head == -1)
    800023dc:	0b06a703          	lw	a4,176(a3)
    800023e0:	57fd                	li	a5,-1
    800023e2:	08f70d63          	beq	a4,a5,8000247c <fork+0x244>
    800023e6:	8792                	mv	a5,tp
  int id = r_tp();
    800023e8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800023ec:	00010617          	auipc	a2,0x10
    800023f0:	ed460613          	addi	a2,a2,-300 # 800122c0 <pid_lock>
    800023f4:	00371793          	slli	a5,a4,0x3
    800023f8:	00e786b3          	add	a3,a5,a4
    800023fc:	0692                	slli	a3,a3,0x4
    800023fe:	96b2                	add	a3,a3,a2
    80002400:	0ae6ac23          	sw	a4,184(a3)
    mycpu()->runnable_list_tail = np->proc_ind;
    80002404:	05c92683          	lw	a3,92(s2)
    80002408:	97ba                	add	a5,a5,a4
    8000240a:	0792                	slli	a5,a5,0x4
    8000240c:	97b2                	add	a5,a5,a2
    8000240e:	0ad7aa23          	sw	a3,180(a5)
  release(&np->lock);
    80002412:	854a                	mv	a0,s2
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	884080e7          	jalr	-1916(ra) # 80000c98 <release>
}
    8000241c:	8552                	mv	a0,s4
    8000241e:	70e2                	ld	ra,56(sp)
    80002420:	7442                	ld	s0,48(sp)
    80002422:	74a2                	ld	s1,40(sp)
    80002424:	7902                	ld	s2,32(sp)
    80002426:	69e2                	ld	s3,24(sp)
    80002428:	6a42                	ld	s4,16(sp)
    8000242a:	6aa2                	ld	s5,8(sp)
    8000242c:	6121                	addi	sp,sp,64
    8000242e:	8082                	ret
    80002430:	8792                	mv	a5,tp
  int id = r_tp();
    80002432:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002436:	00369793          	slli	a5,a3,0x3
    8000243a:	00d78633          	add	a2,a5,a3
    8000243e:	0612                	slli	a2,a2,0x4
    80002440:	9626                	add	a2,a2,s1
    80002442:	0ad62c23          	sw	a3,184(a2)
    mycpu()->runnable_list_head = np->proc_ind;
    80002446:	05c92603          	lw	a2,92(s2)
    8000244a:	97b6                	add	a5,a5,a3
    8000244c:	0792                	slli	a5,a5,0x4
    8000244e:	97a6                	add	a5,a5,s1
    80002450:	0ac7a823          	sw	a2,176(a5)
    80002454:	8792                	mv	a5,tp
  int id = r_tp();
    80002456:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    8000245a:	00369793          	slli	a5,a3,0x3
    8000245e:	00d78633          	add	a2,a5,a3
    80002462:	0612                	slli	a2,a2,0x4
    80002464:	9626                	add	a2,a2,s1
    80002466:	0ad62c23          	sw	a3,184(a2)
    mycpu()->runnable_list_tail = np->proc_ind;
    8000246a:	05c92603          	lw	a2,92(s2)
    8000246e:	97b6                	add	a5,a5,a3
    80002470:	0792                	slli	a5,a5,0x4
    80002472:	00f48733          	add	a4,s1,a5
    80002476:	0ac72a23          	sw	a2,180(a4)
    8000247a:	bf61                	j	80002412 <fork+0x1da>
    8000247c:	8792                	mv	a5,tp
  int id = r_tp();
    8000247e:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002482:	00010617          	auipc	a2,0x10
    80002486:	e3e60613          	addi	a2,a2,-450 # 800122c0 <pid_lock>
    8000248a:	00371793          	slli	a5,a4,0x3
    8000248e:	00e786b3          	add	a3,a5,a4
    80002492:	0692                	slli	a3,a3,0x4
    80002494:	96b2                	add	a3,a3,a2
    80002496:	0ae6ac23          	sw	a4,184(a3)
      mycpu()->runnable_list_head = np->proc_ind;
    8000249a:	05c92683          	lw	a3,92(s2)
    8000249e:	97ba                	add	a5,a5,a4
    800024a0:	0792                	slli	a5,a5,0x4
    800024a2:	97b2                	add	a5,a5,a2
    800024a4:	0ad7a823          	sw	a3,176(a5)
    800024a8:	bf3d                	j	800023e6 <fork+0x1ae>
    return -1;
    800024aa:	5a7d                	li	s4,-1
    800024ac:	bf85                	j	8000241c <fork+0x1e4>

00000000800024ae <unpause_system>:
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) 
    800024bc:	00010497          	auipc	s1,0x10
    800024c0:	2b448493          	addi	s1,s1,692 # 80012770 <proc>
      if(p->paused == 1) 
    800024c4:	4985                	li	s3,1
  for(p = proc; p < &proc[NPROC]; p++) 
    800024c6:	00017917          	auipc	s2,0x17
    800024ca:	8aa90913          	addi	s2,s2,-1878 # 80018d70 <tickslock>
    800024ce:	a811                	j	800024e2 <unpause_system+0x34>
      release(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7c6080e7          	jalr	1990(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) 
    800024da:	19848493          	addi	s1,s1,408
    800024de:	01248d63          	beq	s1,s2,800024f8 <unpause_system+0x4a>
      acquire(&p->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	700080e7          	jalr	1792(ra) # 80000be4 <acquire>
      if(p->paused == 1) 
    800024ec:	40bc                	lw	a5,64(s1)
    800024ee:	ff3791e3          	bne	a5,s3,800024d0 <unpause_system+0x22>
        p->paused = 0;
    800024f2:	0404a023          	sw	zero,64(s1)
    800024f6:	bfe9                	j	800024d0 <unpause_system+0x22>
} 
    800024f8:	70a2                	ld	ra,40(sp)
    800024fa:	7402                	ld	s0,32(sp)
    800024fc:	64e2                	ld	s1,24(sp)
    800024fe:	6942                	ld	s2,16(sp)
    80002500:	69a2                	ld	s3,8(sp)
    80002502:	6145                	addi	sp,sp,48
    80002504:	8082                	ret

0000000080002506 <SJF_scheduler>:
{
    80002506:	711d                	addi	sp,sp,-96
    80002508:	ec86                	sd	ra,88(sp)
    8000250a:	e8a2                	sd	s0,80(sp)
    8000250c:	e4a6                	sd	s1,72(sp)
    8000250e:	e0ca                	sd	s2,64(sp)
    80002510:	fc4e                	sd	s3,56(sp)
    80002512:	f852                	sd	s4,48(sp)
    80002514:	f456                	sd	s5,40(sp)
    80002516:	f05a                	sd	s6,32(sp)
    80002518:	ec5e                	sd	s7,24(sp)
    8000251a:	e862                	sd	s8,16(sp)
    8000251c:	e466                	sd	s9,8(sp)
    8000251e:	e06a                	sd	s10,0(sp)
    80002520:	1080                	addi	s0,sp,96
    80002522:	8792                	mv	a5,tp
  int id = r_tp();
    80002524:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80002526:	00379713          	slli	a4,a5,0x3
    8000252a:	00f706b3          	add	a3,a4,a5
    8000252e:	00469613          	slli	a2,a3,0x4
    80002532:	00010697          	auipc	a3,0x10
    80002536:	d8e68693          	addi	a3,a3,-626 # 800122c0 <pid_lock>
    8000253a:	96b2                	add	a3,a3,a2
    8000253c:	0af6ac23          	sw	a5,184(a3)
  c->proc = 0;
    80002540:	0206b823          	sd	zero,48(a3)
      swtch(&c->context, &p_of_min->context);
    80002544:	00010697          	auipc	a3,0x10
    80002548:	db468693          	addi	a3,a3,-588 # 800122f8 <cpus+0x8>
    8000254c:	00d60d33          	add	s10,a2,a3
    struct proc* p_of_min = proc;
    80002550:	00010a97          	auipc	s5,0x10
    80002554:	220a8a93          	addi	s5,s5,544 # 80012770 <proc>
    uint min = INT_MAX;
    80002558:	80000b37          	lui	s6,0x80000
    8000255c:	fffb4b13          	not	s6,s6
           should_switch = 1;
    80002560:	4a05                	li	s4,1
    80002562:	89d2                	mv	s3,s4
      c->proc = p_of_min;
    80002564:	00010b97          	auipc	s7,0x10
    80002568:	d5cb8b93          	addi	s7,s7,-676 # 800122c0 <pid_lock>
    8000256c:	9bb2                	add	s7,s7,a2
    8000256e:	a091                	j	800025b2 <SJF_scheduler+0xac>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002570:	19878793          	addi	a5,a5,408
    80002574:	00d78c63          	beq	a5,a3,8000258c <SJF_scheduler+0x86>
       if(p->state == RUNNABLE) {
    80002578:	4f98                	lw	a4,24(a5)
    8000257a:	fec71be3          	bne	a4,a2,80002570 <SJF_scheduler+0x6a>
         if (p->mean_ticks < min)
    8000257e:	5bd8                	lw	a4,52(a5)
    80002580:	feb778e3          	bgeu	a4,a1,80002570 <SJF_scheduler+0x6a>
    80002584:	84be                	mv	s1,a5
           min = p->mean_ticks;
    80002586:	85ba                	mv	a1,a4
           should_switch = 1;
    80002588:	894e                	mv	s2,s3
    8000258a:	b7dd                	j	80002570 <SJF_scheduler+0x6a>
    acquire(&p_of_min->lock);
    8000258c:	8c26                	mv	s8,s1
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	654080e7          	jalr	1620(ra) # 80000be4 <acquire>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    80002598:	03490d63          	beq	s2,s4,800025d2 <SJF_scheduler+0xcc>
    release(&p_of_min->lock);
    8000259c:	8562                	mv	a0,s8
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	6fa080e7          	jalr	1786(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    800025a6:	00008797          	auipc	a5,0x8
    800025aa:	aaa7a783          	lw	a5,-1366(a5) # 8000a050 <pause_flag>
    800025ae:	0b478163          	beq	a5,s4,80002650 <SJF_scheduler+0x14a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025b6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025ba:	10079073          	csrw	sstatus,a5
    int should_switch = 0;
    800025be:	4901                	li	s2,0
    struct proc* p_of_min = proc;
    800025c0:	84d6                	mv	s1,s5
    uint min = INT_MAX;
    800025c2:	85da                	mv	a1,s6
    for(p = proc; p < &proc[NPROC]; p++) {
    800025c4:	87d6                	mv	a5,s5
       if(p->state == RUNNABLE) {
    800025c6:	460d                	li	a2,3
    for(p = proc; p < &proc[NPROC]; p++) {
    800025c8:	00016697          	auipc	a3,0x16
    800025cc:	7a868693          	addi	a3,a3,1960 # 80018d70 <tickslock>
    800025d0:	b765                	j	80002578 <SJF_scheduler+0x72>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    800025d2:	4c98                	lw	a4,24(s1)
    800025d4:	478d                	li	a5,3
    800025d6:	fcf713e3          	bne	a4,a5,8000259c <SJF_scheduler+0x96>
    800025da:	40bc                	lw	a5,64(s1)
    800025dc:	f3e1                	bnez	a5,8000259c <SJF_scheduler+0x96>
      p_of_min->state = RUNNING;
    800025de:	4791                	li	a5,4
    800025e0:	cc9c                	sw	a5,24(s1)
      p_of_min->start_running_time = ticks;
    800025e2:	00008c97          	auipc	s9,0x8
    800025e6:	a72c8c93          	addi	s9,s9,-1422 # 8000a054 <ticks>
    800025ea:	000ca903          	lw	s2,0(s9)
    800025ee:	0524a823          	sw	s2,80(s1)
      p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    800025f2:	44bc                	lw	a5,72(s1)
    800025f4:	012787bb          	addw	a5,a5,s2
    800025f8:	5cd8                	lw	a4,60(s1)
    800025fa:	9f99                	subw	a5,a5,a4
    800025fc:	c4bc                	sw	a5,72(s1)
      c->proc = p_of_min;
    800025fe:	029bb823          	sd	s1,48(s7)
      swtch(&c->context, &p_of_min->context);
    80002602:	09048593          	addi	a1,s1,144
    80002606:	856a                	mv	a0,s10
    80002608:	00001097          	auipc	ra,0x1
    8000260c:	398080e7          	jalr	920(ra) # 800039a0 <swtch>
      p_of_min->last_ticks= ticks - before_swtch;
    80002610:	000ca783          	lw	a5,0(s9)
    80002614:	4127893b          	subw	s2,a5,s2
    80002618:	0324ac23          	sw	s2,56(s1)
      p_of_min->mean_ticks=((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10 ;
    8000261c:	00007617          	auipc	a2,0x7
    80002620:	3b462603          	lw	a2,948(a2) # 800099d0 <rate>
    80002624:	46a9                	li	a3,10
    80002626:	40c687bb          	subw	a5,a3,a2
    8000262a:	00016717          	auipc	a4,0x16
    8000262e:	14670713          	addi	a4,a4,326 # 80018770 <proc+0x6000>
    80002632:	63472583          	lw	a1,1588(a4)
    80002636:	02b787bb          	mulw	a5,a5,a1
    8000263a:	63872703          	lw	a4,1592(a4)
    8000263e:	02c7073b          	mulw	a4,a4,a2
    80002642:	9fb9                	addw	a5,a5,a4
    80002644:	02d7d7bb          	divuw	a5,a5,a3
    80002648:	d8dc                	sw	a5,52(s1)
      c->proc = 0;
    8000264a:	020bb823          	sd	zero,48(s7)
    8000264e:	b7b9                	j	8000259c <SJF_scheduler+0x96>
      if (wake_up_time <= ticks) 
    80002650:	00008717          	auipc	a4,0x8
    80002654:	9fc72703          	lw	a4,-1540(a4) # 8000a04c <wake_up_time>
    80002658:	00008797          	auipc	a5,0x8
    8000265c:	9fc7a783          	lw	a5,-1540(a5) # 8000a054 <ticks>
    80002660:	f4e7e9e3          	bltu	a5,a4,800025b2 <SJF_scheduler+0xac>
        pause_flag = 0;
    80002664:	00008797          	auipc	a5,0x8
    80002668:	9e07a623          	sw	zero,-1556(a5) # 8000a050 <pause_flag>
        unpause_system();
    8000266c:	00000097          	auipc	ra,0x0
    80002670:	e42080e7          	jalr	-446(ra) # 800024ae <unpause_system>
    80002674:	bf3d                	j	800025b2 <SJF_scheduler+0xac>

0000000080002676 <FCFS_scheduler>:
{
    80002676:	7119                	addi	sp,sp,-128
    80002678:	fc86                	sd	ra,120(sp)
    8000267a:	f8a2                	sd	s0,112(sp)
    8000267c:	f4a6                	sd	s1,104(sp)
    8000267e:	f0ca                	sd	s2,96(sp)
    80002680:	ecce                	sd	s3,88(sp)
    80002682:	e8d2                	sd	s4,80(sp)
    80002684:	e4d6                	sd	s5,72(sp)
    80002686:	e0da                	sd	s6,64(sp)
    80002688:	fc5e                	sd	s7,56(sp)
    8000268a:	f862                	sd	s8,48(sp)
    8000268c:	f466                	sd	s9,40(sp)
    8000268e:	f06a                	sd	s10,32(sp)
    80002690:	ec6e                	sd	s11,24(sp)
    80002692:	0100                	addi	s0,sp,128
  asm volatile("mv %0, tp" : "=r" (x) );
    80002694:	8792                	mv	a5,tp
  int id = r_tp();
    80002696:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80002698:	00379713          	slli	a4,a5,0x3
    8000269c:	00f706b3          	add	a3,a4,a5
    800026a0:	00469613          	slli	a2,a3,0x4
    800026a4:	00010697          	auipc	a3,0x10
    800026a8:	c1c68693          	addi	a3,a3,-996 # 800122c0 <pid_lock>
    800026ac:	96b2                	add	a3,a3,a2
    800026ae:	0af6ac23          	sw	a5,184(a3)
  c->proc = 0;
    800026b2:	0206b823          	sd	zero,48(a3)
        swtch(&c->context, &p_of_min->context);
    800026b6:	00010697          	auipc	a3,0x10
    800026ba:	c4268693          	addi	a3,a3,-958 # 800122f8 <cpus+0x8>
    800026be:	00d60733          	add	a4,a2,a3
    800026c2:	f8e43423          	sd	a4,-120(s0)
  int should_switch = 0;
    800026c6:	4b01                	li	s6,0
    struct proc *p_of_min = proc;
    800026c8:	00010c17          	auipc	s8,0x10
    800026cc:	0a8c0c13          	addi	s8,s8,168 # 80012770 <proc>
    uint minlast_runnable = INT_MAX;
    800026d0:	80000d37          	lui	s10,0x80000
    800026d4:	fffd4d13          	not	s10,s10
          should_switch = 1;
    800026d8:	4c85                	li	s9,1
    800026da:	8be6                	mv	s7,s9
        c->proc = p_of_min;
    800026dc:	00010d97          	auipc	s11,0x10
    800026e0:	be4d8d93          	addi	s11,s11,-1052 # 800122c0 <pid_lock>
    800026e4:	9db2                	add	s11,s11,a2
    800026e6:	a095                	j	8000274a <FCFS_scheduler+0xd4>
      release(&p->lock);
    800026e8:	8526                	mv	a0,s1
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	5ae080e7          	jalr	1454(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) 
    800026f2:	19848493          	addi	s1,s1,408
    800026f6:	03248463          	beq	s1,s2,8000271e <FCFS_scheduler+0xa8>
      acquire(&p->lock);
    800026fa:	8526                	mv	a0,s1
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	4e8080e7          	jalr	1256(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && p->paused == 0) 
    80002704:	4c9c                	lw	a5,24(s1)
    80002706:	ff3791e3          	bne	a5,s3,800026e8 <FCFS_scheduler+0x72>
    8000270a:	40bc                	lw	a5,64(s1)
    8000270c:	fff1                	bnez	a5,800026e8 <FCFS_scheduler+0x72>
        if(p->last_runnable_time <= minlast_runnable)
    8000270e:	5cdc                	lw	a5,60(s1)
    80002710:	fcfa6ce3          	bltu	s4,a5,800026e8 <FCFS_scheduler+0x72>
          minlast_runnable = p->mean_ticks;
    80002714:	0344aa03          	lw	s4,52(s1)
    80002718:	8aa6                	mv	s5,s1
          should_switch = 1;
    8000271a:	8b5e                	mv	s6,s7
    8000271c:	b7f1                	j	800026e8 <FCFS_scheduler+0x72>
    acquire(&p_of_min->lock);
    8000271e:	8956                	mv	s2,s5
    80002720:	8556                	mv	a0,s5
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	4c2080e7          	jalr	1218(ra) # 80000be4 <acquire>
    if (p_of_min->paused == 0)
    8000272a:	040aa483          	lw	s1,64(s5)
    8000272e:	e099                	bnez	s1,80002734 <FCFS_scheduler+0xbe>
      if (should_switch == 1 && p_of_min->pid > -1)
    80002730:	039b0c63          	beq	s6,s9,80002768 <FCFS_scheduler+0xf2>
    release(&p_of_min->lock);
    80002734:	854a                	mv	a0,s2
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	562080e7          	jalr	1378(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    8000273e:	00008797          	auipc	a5,0x8
    80002742:	9127a783          	lw	a5,-1774(a5) # 8000a050 <pause_flag>
    80002746:	07978463          	beq	a5,s9,800027ae <FCFS_scheduler+0x138>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000274a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000274e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002752:	10079073          	csrw	sstatus,a5
    struct proc *p_of_min = proc;
    80002756:	8ae2                	mv	s5,s8
    uint minlast_runnable = INT_MAX;
    80002758:	8a6a                	mv	s4,s10
    for(p = proc; p < &proc[NPROC]; p++) 
    8000275a:	84e2                	mv	s1,s8
      if(p->state == RUNNABLE && p->paused == 0) 
    8000275c:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) 
    8000275e:	00016917          	auipc	s2,0x16
    80002762:	61290913          	addi	s2,s2,1554 # 80018d70 <tickslock>
    80002766:	bf51                	j	800026fa <FCFS_scheduler+0x84>
      if (should_switch == 1 && p_of_min->pid > -1)
    80002768:	030aa783          	lw	a5,48(s5)
    8000276c:	fc07c4e3          	bltz	a5,80002734 <FCFS_scheduler+0xbe>
        p_of_min->state = RUNNING;
    80002770:	4791                	li	a5,4
    80002772:	00faac23          	sw	a5,24(s5)
        p_of_min->start_running_time = ticks;
    80002776:	00008717          	auipc	a4,0x8
    8000277a:	8de72703          	lw	a4,-1826(a4) # 8000a054 <ticks>
    8000277e:	04eaa823          	sw	a4,80(s5)
        p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    80002782:	048aa783          	lw	a5,72(s5)
    80002786:	9fb9                	addw	a5,a5,a4
    80002788:	03caa703          	lw	a4,60(s5)
    8000278c:	9f99                	subw	a5,a5,a4
    8000278e:	04faa423          	sw	a5,72(s5)
        c->proc = p_of_min;
    80002792:	035db823          	sd	s5,48(s11)
        swtch(&c->context, &p_of_min->context);
    80002796:	090a8593          	addi	a1,s5,144
    8000279a:	f8843503          	ld	a0,-120(s0)
    8000279e:	00001097          	auipc	ra,0x1
    800027a2:	202080e7          	jalr	514(ra) # 800039a0 <swtch>
        c->proc = 0;
    800027a6:	020db823          	sd	zero,48(s11)
        should_switch = 0;
    800027aa:	8b26                	mv	s6,s1
    800027ac:	b761                	j	80002734 <FCFS_scheduler+0xbe>
      if (wake_up_time <= ticks) 
    800027ae:	00008717          	auipc	a4,0x8
    800027b2:	89e72703          	lw	a4,-1890(a4) # 8000a04c <wake_up_time>
    800027b6:	00008797          	auipc	a5,0x8
    800027ba:	89e7a783          	lw	a5,-1890(a5) # 8000a054 <ticks>
    800027be:	f8e7e6e3          	bltu	a5,a4,8000274a <FCFS_scheduler+0xd4>
        pause_flag = 0;
    800027c2:	00008797          	auipc	a5,0x8
    800027c6:	8807a723          	sw	zero,-1906(a5) # 8000a050 <pause_flag>
        unpause_system();
    800027ca:	00000097          	auipc	ra,0x0
    800027ce:	ce4080e7          	jalr	-796(ra) # 800024ae <unpause_system>
    800027d2:	bfa5                	j	8000274a <FCFS_scheduler+0xd4>

00000000800027d4 <scheduler>:
{
    800027d4:	7159                	addi	sp,sp,-112
    800027d6:	f486                	sd	ra,104(sp)
    800027d8:	f0a2                	sd	s0,96(sp)
    800027da:	eca6                	sd	s1,88(sp)
    800027dc:	e8ca                	sd	s2,80(sp)
    800027de:	e4ce                	sd	s3,72(sp)
    800027e0:	e0d2                	sd	s4,64(sp)
    800027e2:	fc56                	sd	s5,56(sp)
    800027e4:	f85a                	sd	s6,48(sp)
    800027e6:	f45e                	sd	s7,40(sp)
    800027e8:	f062                	sd	s8,32(sp)
    800027ea:	ec66                	sd	s9,24(sp)
    800027ec:	e86a                	sd	s10,16(sp)
    800027ee:	e46e                	sd	s11,8(sp)
    800027f0:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    800027f2:	8792                	mv	a5,tp
  int id = r_tp();
    800027f4:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800027f6:	00379713          	slli	a4,a5,0x3
    800027fa:	00f706b3          	add	a3,a4,a5
    800027fe:	00469613          	slli	a2,a3,0x4
    80002802:	00010697          	auipc	a3,0x10
    80002806:	abe68693          	addi	a3,a3,-1346 # 800122c0 <pid_lock>
    8000280a:	96b2                	add	a3,a3,a2
    8000280c:	0af6ac23          	sw	a5,184(a3)
  c->proc = 0;
    80002810:	0206b823          	sd	zero,48(a3)
      swtch(&c->context, &p->context);
    80002814:	00010717          	auipc	a4,0x10
    80002818:	ae470713          	addi	a4,a4,-1308 # 800122f8 <cpus+0x8>
    8000281c:	00e60c33          	add	s8,a2,a4
    printf("start sched\n");
    80002820:	00007a17          	auipc	s4,0x7
    80002824:	a70a0a13          	addi	s4,s4,-1424 # 80009290 <digits+0x250>
    if (c->runnable_list_head != -1)
    80002828:	8936                	mv	s2,a3
    8000282a:	59fd                	li	s3,-1
    8000282c:	19800b13          	li	s6,408
      p = &proc[c->runnable_list_head];
    80002830:	00010a97          	auipc	s5,0x10
    80002834:	f40a8a93          	addi	s5,s5,-192 # 80012770 <proc>
      printf("proc ind: %d\n", c->runnable_list_head);
    80002838:	00007c97          	auipc	s9,0x7
    8000283c:	a68c8c93          	addi	s9,s9,-1432 # 800092a0 <digits+0x260>
        proc[p->prev_proc].next_proc = -1;
    80002840:	5bfd                	li	s7,-1
    80002842:	a871                	j	800028de <scheduler+0x10a>
        c->runnable_list_head = -1;
    80002844:	0b792823          	sw	s7,176(s2)
        c->runnable_list_tail = -1;
    80002848:	0b792a23          	sw	s7,180(s2)
      acquire(&p->lock);
    8000284c:	856a                	mv	a0,s10
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	396080e7          	jalr	918(ra) # 80000be4 <acquire>
      p->prev_proc = -1;
    80002856:	036487b3          	mul	a5,s1,s6
    8000285a:	97d6                	add	a5,a5,s5
    8000285c:	0777a223          	sw	s7,100(a5)
      p->next_proc = -1;
    80002860:	0777a023          	sw	s7,96(a5)
      p->state = RUNNING;
    80002864:	4711                	li	a4,4
    80002866:	cf98                	sw	a4,24(a5)
      p->cpu_num = c->cpu_id;
    80002868:	0b892703          	lw	a4,184(s2)
    8000286c:	cfb8                	sw	a4,88(a5)
      c->proc = p;
    8000286e:	03a93823          	sd	s10,48(s2)
      swtch(&c->context, &p->context);
    80002872:	090d8593          	addi	a1,s11,144
    80002876:	95d6                	add	a1,a1,s5
    80002878:	8562                	mv	a0,s8
    8000287a:	00001097          	auipc	ra,0x1
    8000287e:	126080e7          	jalr	294(ra) # 800039a0 <swtch>
      printf("runable");
    80002882:	00007517          	auipc	a0,0x7
    80002886:	a3e50513          	addi	a0,a0,-1474 # 800092c0 <digits+0x280>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cfe080e7          	jalr	-770(ra) # 80000588 <printf>
      add_proc_to_list(c->runnable_list_tail, p);
    80002892:	85ea                	mv	a1,s10
    80002894:	0b492503          	lw	a0,180(s2)
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	fae080e7          	jalr	-82(ra) # 80001846 <add_proc_to_list>
      if (c->runnable_list_head == -1)
    800028a0:	0b092783          	lw	a5,176(s2)
    800028a4:	0d378d63          	beq	a5,s3,8000297e <scheduler+0x1aa>
      c->runnable_list_tail = p->proc_ind;
    800028a8:	036484b3          	mul	s1,s1,s6
    800028ac:	94d6                	add	s1,s1,s5
    800028ae:	4cec                	lw	a1,92(s1)
    800028b0:	0ab92a23          	sw	a1,180(s2)
      if (c->runnable_list_head == -1)
    800028b4:	0b092783          	lw	a5,176(s2)
    800028b8:	01379463          	bne	a5,s3,800028c0 <scheduler+0xec>
        c->runnable_list_head = p->proc_ind;
    800028bc:	0ab92823          	sw	a1,176(s2)
      printf("added back: %d\n", c->runnable_list_tail);
    800028c0:	00007517          	auipc	a0,0x7
    800028c4:	a0850513          	addi	a0,a0,-1528 # 800092c8 <digits+0x288>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cc0080e7          	jalr	-832(ra) # 80000588 <printf>
      c->proc = 0;
    800028d0:	02093823          	sd	zero,48(s2)
      release(&p->lock);
    800028d4:	856a                	mv	a0,s10
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	3c2080e7          	jalr	962(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028de:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028e2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e6:	10079073          	csrw	sstatus,a5
    printf("start sched\n");
    800028ea:	8552                	mv	a0,s4
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	c9c080e7          	jalr	-868(ra) # 80000588 <printf>
    if (c->runnable_list_head != -1)
    800028f4:	0b092483          	lw	s1,176(s2)
    800028f8:	ff3483e3          	beq	s1,s3,800028de <scheduler+0x10a>
      p = &proc[c->runnable_list_head];
    800028fc:	03648db3          	mul	s11,s1,s6
    80002900:	015d8d33          	add	s10,s11,s5
      printf("proc ind: %d\n", c->runnable_list_head);
    80002904:	85a6                	mv	a1,s1
    80002906:	8566                	mv	a0,s9
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	c80080e7          	jalr	-896(ra) # 80000588 <printf>
      printf("runnable");
    80002910:	00007517          	auipc	a0,0x7
    80002914:	97050513          	addi	a0,a0,-1680 # 80009280 <digits+0x240>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c70080e7          	jalr	-912(ra) # 80000588 <printf>
      int res = remove_proc_from_list(p->proc_ind); 
    80002920:	05cd2503          	lw	a0,92(s10) # ffffffff8000005c <end+0xfffffffefffd805c>
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	f80080e7          	jalr	-128(ra) # 800018a4 <remove_proc_from_list>
      if (res == 1){
    8000292c:	4785                	li	a5,1
    8000292e:	f0f50be3          	beq	a0,a5,80002844 <scheduler+0x70>
      if (res == 2)
    80002932:	4789                	li	a5,2
    80002934:	02f50163          	beq	a0,a5,80002956 <scheduler+0x182>
      if (res == 3){
    80002938:	478d                	li	a5,3
    8000293a:	f0f519e3          	bne	a0,a5,8000284c <scheduler+0x78>
        c->runnable_list_tail = p->prev_proc;
    8000293e:	036487b3          	mul	a5,s1,s6
    80002942:	97d6                	add	a5,a5,s5
    80002944:	53fc                	lw	a5,100(a5)
    80002946:	0af92a23          	sw	a5,180(s2)
        proc[p->prev_proc].next_proc = -1;
    8000294a:	036787b3          	mul	a5,a5,s6
    8000294e:	97d6                	add	a5,a5,s5
    80002950:	0777a023          	sw	s7,96(a5)
    80002954:	bde5                	j	8000284c <scheduler+0x78>
        c->runnable_list_head = p->next_proc;
    80002956:	036487b3          	mul	a5,s1,s6
    8000295a:	97d6                	add	a5,a5,s5
    8000295c:	53ac                	lw	a1,96(a5)
    8000295e:	0ab92823          	sw	a1,176(s2)
        proc[p->next_proc].prev_proc = -1;
    80002962:	036587b3          	mul	a5,a1,s6
    80002966:	97d6                	add	a5,a5,s5
    80002968:	0777a223          	sw	s7,100(a5)
        printf("New head: %d\n", c->runnable_list_head);
    8000296c:	00007517          	auipc	a0,0x7
    80002970:	94450513          	addi	a0,a0,-1724 # 800092b0 <digits+0x270>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	c14080e7          	jalr	-1004(ra) # 80000588 <printf>
      if (res == 3){
    8000297c:	bdc1                	j	8000284c <scheduler+0x78>
        c->runnable_list_head = p->proc_ind;
    8000297e:	036487b3          	mul	a5,s1,s6
    80002982:	97d6                	add	a5,a5,s5
    80002984:	4ffc                	lw	a5,92(a5)
    80002986:	0af92823          	sw	a5,176(s2)
    8000298a:	bf39                	j	800028a8 <scheduler+0xd4>

000000008000298c <sched>:
{
    8000298c:	7179                	addi	sp,sp,-48
    8000298e:	f406                	sd	ra,40(sp)
    80002990:	f022                	sd	s0,32(sp)
    80002992:	ec26                	sd	s1,24(sp)
    80002994:	e84a                	sd	s2,16(sp)
    80002996:	e44e                	sd	s3,8(sp)
    80002998:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000299a:	fffff097          	auipc	ra,0xfffff
    8000299e:	20a080e7          	jalr	522(ra) # 80001ba4 <myproc>
    800029a2:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	1c6080e7          	jalr	454(ra) # 80000b6a <holding>
    800029ac:	c95d                	beqz	a0,80002a62 <sched+0xd6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800029ae:	8792                	mv	a5,tp
  int id = r_tp();
    800029b0:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800029b4:	00010617          	auipc	a2,0x10
    800029b8:	90c60613          	addi	a2,a2,-1780 # 800122c0 <pid_lock>
    800029bc:	00371793          	slli	a5,a4,0x3
    800029c0:	00e786b3          	add	a3,a5,a4
    800029c4:	0692                	slli	a3,a3,0x4
    800029c6:	96b2                	add	a3,a3,a2
    800029c8:	0ae6ac23          	sw	a4,184(a3)
  if(mycpu()->noff != 1)
    800029cc:	0a86a703          	lw	a4,168(a3)
    800029d0:	4785                	li	a5,1
    800029d2:	0af71063          	bne	a4,a5,80002a72 <sched+0xe6>
  if(p->state == RUNNING)
    800029d6:	01892703          	lw	a4,24(s2)
    800029da:	4791                	li	a5,4
    800029dc:	0af70363          	beq	a4,a5,80002a82 <sched+0xf6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029e4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800029e6:	e7d5                	bnez	a5,80002a92 <sched+0x106>
  asm volatile("mv %0, tp" : "=r" (x) );
    800029e8:	8792                	mv	a5,tp
  int id = r_tp();
    800029ea:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800029ee:	00010497          	auipc	s1,0x10
    800029f2:	8d248493          	addi	s1,s1,-1838 # 800122c0 <pid_lock>
    800029f6:	00371793          	slli	a5,a4,0x3
    800029fa:	00e786b3          	add	a3,a5,a4
    800029fe:	0692                	slli	a3,a3,0x4
    80002a00:	96a6                	add	a3,a3,s1
    80002a02:	0ae6ac23          	sw	a4,184(a3)
  intena = mycpu()->intena;
    80002a06:	0ac6a983          	lw	s3,172(a3)
    80002a0a:	8592                	mv	a1,tp
  int id = r_tp();
    80002a0c:	0005879b          	sext.w	a5,a1
  c->cpu_id = id;
    80002a10:	00379593          	slli	a1,a5,0x3
    80002a14:	00f58733          	add	a4,a1,a5
    80002a18:	0712                	slli	a4,a4,0x4
    80002a1a:	9726                	add	a4,a4,s1
    80002a1c:	0af72c23          	sw	a5,184(a4)
  swtch(&p->context, &mycpu()->context);
    80002a20:	95be                	add	a1,a1,a5
    80002a22:	0592                	slli	a1,a1,0x4
    80002a24:	00010797          	auipc	a5,0x10
    80002a28:	8d478793          	addi	a5,a5,-1836 # 800122f8 <cpus+0x8>
    80002a2c:	95be                	add	a1,a1,a5
    80002a2e:	09090513          	addi	a0,s2,144
    80002a32:	00001097          	auipc	ra,0x1
    80002a36:	f6e080e7          	jalr	-146(ra) # 800039a0 <swtch>
    80002a3a:	8792                	mv	a5,tp
  int id = r_tp();
    80002a3c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002a40:	00371793          	slli	a5,a4,0x3
    80002a44:	00e786b3          	add	a3,a5,a4
    80002a48:	0692                	slli	a3,a3,0x4
    80002a4a:	96a6                	add	a3,a3,s1
    80002a4c:	0ae6ac23          	sw	a4,184(a3)
  mycpu()->intena = intena;
    80002a50:	0b36a623          	sw	s3,172(a3)
}
    80002a54:	70a2                	ld	ra,40(sp)
    80002a56:	7402                	ld	s0,32(sp)
    80002a58:	64e2                	ld	s1,24(sp)
    80002a5a:	6942                	ld	s2,16(sp)
    80002a5c:	69a2                	ld	s3,8(sp)
    80002a5e:	6145                	addi	sp,sp,48
    80002a60:	8082                	ret
    panic("sched p->lock");
    80002a62:	00007517          	auipc	a0,0x7
    80002a66:	87650513          	addi	a0,a0,-1930 # 800092d8 <digits+0x298>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	ad4080e7          	jalr	-1324(ra) # 8000053e <panic>
    panic("sched locks");
    80002a72:	00007517          	auipc	a0,0x7
    80002a76:	87650513          	addi	a0,a0,-1930 # 800092e8 <digits+0x2a8>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	ac4080e7          	jalr	-1340(ra) # 8000053e <panic>
    panic("sched running");
    80002a82:	00007517          	auipc	a0,0x7
    80002a86:	87650513          	addi	a0,a0,-1930 # 800092f8 <digits+0x2b8>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002a92:	00007517          	auipc	a0,0x7
    80002a96:	87650513          	addi	a0,a0,-1930 # 80009308 <digits+0x2c8>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	aa4080e7          	jalr	-1372(ra) # 8000053e <panic>

0000000080002aa2 <yield>:
{
    80002aa2:	1101                	addi	sp,sp,-32
    80002aa4:	ec06                	sd	ra,24(sp)
    80002aa6:	e822                	sd	s0,16(sp)
    80002aa8:	e426                	sd	s1,8(sp)
    80002aaa:	e04a                	sd	s2,0(sp)
    80002aac:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	0f6080e7          	jalr	246(ra) # 80001ba4 <myproc>
    80002ab6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	12c080e7          	jalr	300(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002ac0:	478d                	li	a5,3
    80002ac2:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002ac4:	00007797          	auipc	a5,0x7
    80002ac8:	5907a783          	lw	a5,1424(a5) # 8000a054 <ticks>
    80002acc:	dcdc                	sw	a5,60(s1)
    80002ace:	8792                	mv	a5,tp
  int id = r_tp();
    80002ad0:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002ad4:	0000f617          	auipc	a2,0xf
    80002ad8:	7ec60613          	addi	a2,a2,2028 # 800122c0 <pid_lock>
    80002adc:	00371793          	slli	a5,a4,0x3
    80002ae0:	00e786b3          	add	a3,a5,a4
    80002ae4:	0692                	slli	a3,a3,0x4
    80002ae6:	96b2                	add	a3,a3,a2
    80002ae8:	0ae6ac23          	sw	a4,184(a3)
   if (mycpu()->runnable_list_head == -1)
    80002aec:	0b06a703          	lw	a4,176(a3)
    80002af0:	57fd                	li	a5,-1
    80002af2:	0af70463          	beq	a4,a5,80002b9a <yield+0xf8>
    printf("runable");
    80002af6:	00006517          	auipc	a0,0x6
    80002afa:	7ca50513          	addi	a0,a0,1994 # 800092c0 <digits+0x280>
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a8a080e7          	jalr	-1398(ra) # 80000588 <printf>
    80002b06:	8792                	mv	a5,tp
  int id = r_tp();
    80002b08:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b0c:	0000f917          	auipc	s2,0xf
    80002b10:	7b490913          	addi	s2,s2,1972 # 800122c0 <pid_lock>
    80002b14:	00371793          	slli	a5,a4,0x3
    80002b18:	00e786b3          	add	a3,a5,a4
    80002b1c:	0692                	slli	a3,a3,0x4
    80002b1e:	96ca                	add	a3,a3,s2
    80002b20:	0ae6ac23          	sw	a4,184(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    80002b24:	85a6                	mv	a1,s1
    80002b26:	0b46a503          	lw	a0,180(a3)
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	d1c080e7          	jalr	-740(ra) # 80001846 <add_proc_to_list>
    80002b32:	8792                	mv	a5,tp
  int id = r_tp();
    80002b34:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b38:	00371793          	slli	a5,a4,0x3
    80002b3c:	00e786b3          	add	a3,a5,a4
    80002b40:	0692                	slli	a3,a3,0x4
    80002b42:	96ca                	add	a3,a3,s2
    80002b44:	0ae6ac23          	sw	a4,184(a3)
    if (mycpu()->runnable_list_head == -1)
    80002b48:	0b06a703          	lw	a4,176(a3)
    80002b4c:	57fd                	li	a5,-1
    80002b4e:	08f70a63          	beq	a4,a5,80002be2 <yield+0x140>
    80002b52:	8792                	mv	a5,tp
  int id = r_tp();
    80002b54:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b58:	0000f617          	auipc	a2,0xf
    80002b5c:	76860613          	addi	a2,a2,1896 # 800122c0 <pid_lock>
    80002b60:	00371793          	slli	a5,a4,0x3
    80002b64:	00e786b3          	add	a3,a5,a4
    80002b68:	0692                	slli	a3,a3,0x4
    80002b6a:	96b2                	add	a3,a3,a2
    80002b6c:	0ae6ac23          	sw	a4,184(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002b70:	4cf4                	lw	a3,92(s1)
    80002b72:	97ba                	add	a5,a5,a4
    80002b74:	0792                	slli	a5,a5,0x4
    80002b76:	97b2                	add	a5,a5,a2
    80002b78:	0ad7aa23          	sw	a3,180(a5)
  sched();
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	e10080e7          	jalr	-496(ra) # 8000298c <sched>
  release(&p->lock);
    80002b84:	8526                	mv	a0,s1
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	112080e7          	jalr	274(ra) # 80000c98 <release>
}
    80002b8e:	60e2                	ld	ra,24(sp)
    80002b90:	6442                	ld	s0,16(sp)
    80002b92:	64a2                	ld	s1,8(sp)
    80002b94:	6902                	ld	s2,0(sp)
    80002b96:	6105                	addi	sp,sp,32
    80002b98:	8082                	ret
    80002b9a:	8792                	mv	a5,tp
  int id = r_tp();
    80002b9c:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002ba0:	8732                	mv	a4,a2
    80002ba2:	00369793          	slli	a5,a3,0x3
    80002ba6:	00d78633          	add	a2,a5,a3
    80002baa:	0612                	slli	a2,a2,0x4
    80002bac:	963a                	add	a2,a2,a4
    80002bae:	0ad62c23          	sw	a3,184(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    80002bb2:	4cf0                	lw	a2,92(s1)
    80002bb4:	97b6                	add	a5,a5,a3
    80002bb6:	0792                	slli	a5,a5,0x4
    80002bb8:	97ba                	add	a5,a5,a4
    80002bba:	0ac7a823          	sw	a2,176(a5)
    80002bbe:	8792                	mv	a5,tp
  int id = r_tp();
    80002bc0:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002bc4:	00369793          	slli	a5,a3,0x3
    80002bc8:	00d78633          	add	a2,a5,a3
    80002bcc:	0612                	slli	a2,a2,0x4
    80002bce:	963a                	add	a2,a2,a4
    80002bd0:	0ad62c23          	sw	a3,184(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002bd4:	4cf0                	lw	a2,92(s1)
    80002bd6:	97b6                	add	a5,a5,a3
    80002bd8:	0792                	slli	a5,a5,0x4
    80002bda:	973e                	add	a4,a4,a5
    80002bdc:	0ac72a23          	sw	a2,180(a4)
    80002be0:	bf71                	j	80002b7c <yield+0xda>
    80002be2:	8792                	mv	a5,tp
  int id = r_tp();
    80002be4:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002be8:	0000f617          	auipc	a2,0xf
    80002bec:	6d860613          	addi	a2,a2,1752 # 800122c0 <pid_lock>
    80002bf0:	00371793          	slli	a5,a4,0x3
    80002bf4:	00e786b3          	add	a3,a5,a4
    80002bf8:	0692                	slli	a3,a3,0x4
    80002bfa:	96b2                	add	a3,a3,a2
    80002bfc:	0ae6ac23          	sw	a4,184(a3)
      mycpu()->runnable_list_head = p->proc_ind;
    80002c00:	4cf4                	lw	a3,92(s1)
    80002c02:	97ba                	add	a5,a5,a4
    80002c04:	0792                	slli	a5,a5,0x4
    80002c06:	97b2                	add	a5,a5,a2
    80002c08:	0ad7a823          	sw	a3,176(a5)
    80002c0c:	b799                	j	80002b52 <yield+0xb0>

0000000080002c0e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002c0e:	7179                	addi	sp,sp,-48
    80002c10:	f406                	sd	ra,40(sp)
    80002c12:	f022                	sd	s0,32(sp)
    80002c14:	ec26                	sd	s1,24(sp)
    80002c16:	e84a                	sd	s2,16(sp)
    80002c18:	e44e                	sd	s3,8(sp)
    80002c1a:	1800                	addi	s0,sp,48
    80002c1c:	89aa                	mv	s3,a0
    80002c1e:	892e                	mv	s2,a1
  // TODO: remove from RUNNABLE and add to SLEEPING
  struct proc *p = myproc();
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	f84080e7          	jalr	-124(ra) # 80001ba4 <myproc>
    80002c28:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	fba080e7          	jalr	-70(ra) # 80000be4 <acquire>
  release(lk);
    80002c32:	854a                	mv	a0,s2
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	064080e7          	jalr	100(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002c3c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002c40:	4789                	li	a5,2
    80002c42:	cc9c                	sw	a5,24(s1)
  p->start_sleeping_time = ticks;
    80002c44:	00007797          	auipc	a5,0x7
    80002c48:	4107a783          	lw	a5,1040(a5) # 8000a054 <ticks>
    80002c4c:	c8fc                	sw	a5,84(s1)

  //Ass2
  printf("runable");
    80002c4e:	00006517          	auipc	a0,0x6
    80002c52:	67250513          	addi	a0,a0,1650 # 800092c0 <digits+0x280>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	932080e7          	jalr	-1742(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80002c5e:	4ce8                	lw	a0,92(s1)
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	c44080e7          	jalr	-956(ra) # 800018a4 <remove_proc_from_list>
  if (res == 1){
    80002c68:	4785                	li	a5,1
    80002c6a:	06f50263          	beq	a0,a5,80002cce <sleep+0xc0>
    mycpu()->runnable_list_head = -1;
    mycpu()->runnable_list_tail = -1;
  }
  if (res == 2){
    80002c6e:	4789                	li	a5,2
    80002c70:	08f50f63          	beq	a0,a5,80002d0e <sleep+0x100>
    mycpu()->runnable_list_head = p->next_proc;
    proc[p->next_proc].prev_proc = -1;
  }
  if (res == 3){
    80002c74:	478d                	li	a5,3
    80002c76:	0cf50d63          	beq	a0,a5,80002d50 <sleep+0x142>
    mycpu()->runnable_list_tail = p->prev_proc;
    proc[p->prev_proc].next_proc = -1;
  }

  p->next_proc = -1;
    80002c7a:	57fd                	li	a5,-1
    80002c7c:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80002c7e:	d0fc                	sw	a5,100(s1)

  if (sleeping_list_tail != -1){
    80002c80:	00007717          	auipc	a4,0x7
    80002c84:	d4872703          	lw	a4,-696(a4) # 800099c8 <sleeping_list_tail>
    80002c88:	57fd                	li	a5,-1
    80002c8a:	10f71463          	bne	a4,a5,80002d92 <sleep+0x184>
        sleeping_list_head = p->proc_ind;
      }
    sleeping_list_tail = p->proc_ind;
  }
  else{
    sleeping_list_tail = sleeping_list_head = p->proc_ind;
    80002c8e:	4cfc                	lw	a5,92(s1)
    80002c90:	00007717          	auipc	a4,0x7
    80002c94:	d2f72e23          	sw	a5,-708(a4) # 800099cc <sleeping_list_head>
    80002c98:	00007717          	auipc	a4,0x7
    80002c9c:	d2f72823          	sw	a5,-720(a4) # 800099c8 <sleeping_list_tail>
  }

  sched();
    80002ca0:	00000097          	auipc	ra,0x0
    80002ca4:	cec080e7          	jalr	-788(ra) # 8000298c <sched>

  // Tidy up.
  p->chan = 0;
    80002ca8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002cac:	8526                	mv	a0,s1
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	fea080e7          	jalr	-22(ra) # 80000c98 <release>
  acquire(lk);
    80002cb6:	854a                	mv	a0,s2
    80002cb8:	ffffe097          	auipc	ra,0xffffe
    80002cbc:	f2c080e7          	jalr	-212(ra) # 80000be4 <acquire>
}
    80002cc0:	70a2                	ld	ra,40(sp)
    80002cc2:	7402                	ld	s0,32(sp)
    80002cc4:	64e2                	ld	s1,24(sp)
    80002cc6:	6942                	ld	s2,16(sp)
    80002cc8:	69a2                	ld	s3,8(sp)
    80002cca:	6145                	addi	sp,sp,48
    80002ccc:	8082                	ret
    80002cce:	8792                	mv	a5,tp
  int id = r_tp();
    80002cd0:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002cd4:	0000f717          	auipc	a4,0xf
    80002cd8:	5ec70713          	addi	a4,a4,1516 # 800122c0 <pid_lock>
    80002cdc:	00369793          	slli	a5,a3,0x3
    80002ce0:	00d78633          	add	a2,a5,a3
    80002ce4:	0612                	slli	a2,a2,0x4
    80002ce6:	963a                	add	a2,a2,a4
    80002ce8:	0ad62c23          	sw	a3,184(a2)
    mycpu()->runnable_list_head = -1;
    80002cec:	55fd                	li	a1,-1
    80002cee:	0ab62823          	sw	a1,176(a2)
    80002cf2:	8792                	mv	a5,tp
  int id = r_tp();
    80002cf4:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002cf8:	00369793          	slli	a5,a3,0x3
    80002cfc:	00d78633          	add	a2,a5,a3
    80002d00:	0612                	slli	a2,a2,0x4
    80002d02:	963a                	add	a2,a2,a4
    80002d04:	0ad62c23          	sw	a3,184(a2)
    mycpu()->runnable_list_tail = -1;
    80002d08:	0ab62a23          	sw	a1,180(a2)
  if (res == 3){
    80002d0c:	b7bd                	j	80002c7a <sleep+0x6c>
    80002d0e:	8792                	mv	a5,tp
  int id = r_tp();
    80002d10:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002d14:	0000f617          	auipc	a2,0xf
    80002d18:	5ac60613          	addi	a2,a2,1452 # 800122c0 <pid_lock>
    80002d1c:	00371793          	slli	a5,a4,0x3
    80002d20:	00e786b3          	add	a3,a5,a4
    80002d24:	0692                	slli	a3,a3,0x4
    80002d26:	96b2                	add	a3,a3,a2
    80002d28:	0ae6ac23          	sw	a4,184(a3)
    mycpu()->runnable_list_head = p->next_proc;
    80002d2c:	50b4                	lw	a3,96(s1)
    80002d2e:	97ba                	add	a5,a5,a4
    80002d30:	0792                	slli	a5,a5,0x4
    80002d32:	97b2                	add	a5,a5,a2
    80002d34:	0ad7a823          	sw	a3,176(a5)
    proc[p->next_proc].prev_proc = -1;
    80002d38:	19800793          	li	a5,408
    80002d3c:	02f686b3          	mul	a3,a3,a5
    80002d40:	00010797          	auipc	a5,0x10
    80002d44:	a3078793          	addi	a5,a5,-1488 # 80012770 <proc>
    80002d48:	96be                	add	a3,a3,a5
    80002d4a:	57fd                	li	a5,-1
    80002d4c:	d2fc                	sw	a5,100(a3)
  if (res == 3){
    80002d4e:	b735                	j	80002c7a <sleep+0x6c>
    80002d50:	8792                	mv	a5,tp
  int id = r_tp();
    80002d52:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002d56:	0000f617          	auipc	a2,0xf
    80002d5a:	56a60613          	addi	a2,a2,1386 # 800122c0 <pid_lock>
    80002d5e:	00371793          	slli	a5,a4,0x3
    80002d62:	00e786b3          	add	a3,a5,a4
    80002d66:	0692                	slli	a3,a3,0x4
    80002d68:	96b2                	add	a3,a3,a2
    80002d6a:	0ae6ac23          	sw	a4,184(a3)
    mycpu()->runnable_list_tail = p->prev_proc;
    80002d6e:	50f4                	lw	a3,100(s1)
    80002d70:	97ba                	add	a5,a5,a4
    80002d72:	0792                	slli	a5,a5,0x4
    80002d74:	97b2                	add	a5,a5,a2
    80002d76:	0ad7aa23          	sw	a3,180(a5)
    proc[p->prev_proc].next_proc = -1;
    80002d7a:	19800793          	li	a5,408
    80002d7e:	02f686b3          	mul	a3,a3,a5
    80002d82:	00010797          	auipc	a5,0x10
    80002d86:	9ee78793          	addi	a5,a5,-1554 # 80012770 <proc>
    80002d8a:	96be                	add	a3,a3,a5
    80002d8c:	57fd                	li	a5,-1
    80002d8e:	d2bc                	sw	a5,96(a3)
    80002d90:	b5ed                	j	80002c7a <sleep+0x6c>
    printf("sleeping");
    80002d92:	00006517          	auipc	a0,0x6
    80002d96:	58e50513          	addi	a0,a0,1422 # 80009320 <digits+0x2e0>
    80002d9a:	ffffd097          	auipc	ra,0xffffd
    80002d9e:	7ee080e7          	jalr	2030(ra) # 80000588 <printf>
    add_proc_to_list(sleeping_list_tail, p);
    80002da2:	85a6                	mv	a1,s1
    80002da4:	00007517          	auipc	a0,0x7
    80002da8:	c2452503          	lw	a0,-988(a0) # 800099c8 <sleeping_list_tail>
    80002dac:	fffff097          	auipc	ra,0xfffff
    80002db0:	a9a080e7          	jalr	-1382(ra) # 80001846 <add_proc_to_list>
    if (sleeping_list_head == -1)
    80002db4:	00007717          	auipc	a4,0x7
    80002db8:	c1872703          	lw	a4,-1000(a4) # 800099cc <sleeping_list_head>
    80002dbc:	57fd                	li	a5,-1
    80002dbe:	00f70863          	beq	a4,a5,80002dce <sleep+0x1c0>
    sleeping_list_tail = p->proc_ind;
    80002dc2:	4cfc                	lw	a5,92(s1)
    80002dc4:	00007717          	auipc	a4,0x7
    80002dc8:	c0f72223          	sw	a5,-1020(a4) # 800099c8 <sleeping_list_tail>
    80002dcc:	bdd1                	j	80002ca0 <sleep+0x92>
        sleeping_list_head = p->proc_ind;
    80002dce:	4cfc                	lw	a5,92(s1)
    80002dd0:	00007717          	auipc	a4,0x7
    80002dd4:	bef72e23          	sw	a5,-1028(a4) # 800099cc <sleeping_list_head>
    80002dd8:	b7ed                	j	80002dc2 <sleep+0x1b4>

0000000080002dda <wait>:
{
    80002dda:	711d                	addi	sp,sp,-96
    80002ddc:	ec86                	sd	ra,88(sp)
    80002dde:	e8a2                	sd	s0,80(sp)
    80002de0:	e4a6                	sd	s1,72(sp)
    80002de2:	e0ca                	sd	s2,64(sp)
    80002de4:	fc4e                	sd	s3,56(sp)
    80002de6:	f852                	sd	s4,48(sp)
    80002de8:	f456                	sd	s5,40(sp)
    80002dea:	f05a                	sd	s6,32(sp)
    80002dec:	ec5e                	sd	s7,24(sp)
    80002dee:	e862                	sd	s8,16(sp)
    80002df0:	e466                	sd	s9,8(sp)
    80002df2:	1080                	addi	s0,sp,96
    80002df4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	dae080e7          	jalr	-594(ra) # 80001ba4 <myproc>
    80002dfe:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002e00:	0000f517          	auipc	a0,0xf
    80002e04:	4d850513          	addi	a0,a0,1240 # 800122d8 <wait_lock>
    80002e08:	ffffe097          	auipc	ra,0xffffe
    80002e0c:	ddc080e7          	jalr	-548(ra) # 80000be4 <acquire>
    havekids = 0;
    80002e10:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002e12:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002e14:	00016997          	auipc	s3,0x16
    80002e18:	f5c98993          	addi	s3,s3,-164 # 80018d70 <tickslock>
        havekids = 1;
    80002e1c:	4a85                	li	s5,1
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002e1e:	00007c97          	auipc	s9,0x7
    80002e22:	236c8c93          	addi	s9,s9,566 # 8000a054 <ticks>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002e26:	0000fc17          	auipc	s8,0xf
    80002e2a:	4b2c0c13          	addi	s8,s8,1202 # 800122d8 <wait_lock>
    havekids = 0;
    80002e2e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002e30:	00010497          	auipc	s1,0x10
    80002e34:	94048493          	addi	s1,s1,-1728 # 80012770 <proc>
    80002e38:	a0bd                	j	80002ea6 <wait+0xcc>
          pid = np->pid;
    80002e3a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002e3e:	000b0e63          	beqz	s6,80002e5a <wait+0x80>
    80002e42:	4691                	li	a3,4
    80002e44:	02c48613          	addi	a2,s1,44
    80002e48:	85da                	mv	a1,s6
    80002e4a:	08093503          	ld	a0,128(s2)
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	82c080e7          	jalr	-2004(ra) # 8000167a <copyout>
    80002e56:	02054563          	bltz	a0,80002e80 <wait+0xa6>
          freeproc(np);
    80002e5a:	8526                	mv	a0,s1
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	efe080e7          	jalr	-258(ra) # 80001d5a <freeproc>
          release(&np->lock);
    80002e64:	8526                	mv	a0,s1
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	e32080e7          	jalr	-462(ra) # 80000c98 <release>
          release(&wait_lock);
    80002e6e:	0000f517          	auipc	a0,0xf
    80002e72:	46a50513          	addi	a0,a0,1130 # 800122d8 <wait_lock>
    80002e76:	ffffe097          	auipc	ra,0xffffe
    80002e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
          return pid;
    80002e7e:	a09d                	j	80002ee4 <wait+0x10a>
            release(&np->lock);
    80002e80:	8526                	mv	a0,s1
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
            release(&wait_lock);
    80002e8a:	0000f517          	auipc	a0,0xf
    80002e8e:	44e50513          	addi	a0,a0,1102 # 800122d8 <wait_lock>
    80002e92:	ffffe097          	auipc	ra,0xffffe
    80002e96:	e06080e7          	jalr	-506(ra) # 80000c98 <release>
            return -1;
    80002e9a:	59fd                	li	s3,-1
    80002e9c:	a0a1                	j	80002ee4 <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002e9e:	19848493          	addi	s1,s1,408
    80002ea2:	03348463          	beq	s1,s3,80002eca <wait+0xf0>
      if(np->parent == p){
    80002ea6:	74bc                	ld	a5,104(s1)
    80002ea8:	ff279be3          	bne	a5,s2,80002e9e <wait+0xc4>
        acquire(&np->lock);
    80002eac:	8526                	mv	a0,s1
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	d36080e7          	jalr	-714(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002eb6:	4c9c                	lw	a5,24(s1)
    80002eb8:	f94781e3          	beq	a5,s4,80002e3a <wait+0x60>
        release(&np->lock);
    80002ebc:	8526                	mv	a0,s1
    80002ebe:	ffffe097          	auipc	ra,0xffffe
    80002ec2:	dda080e7          	jalr	-550(ra) # 80000c98 <release>
        havekids = 1;
    80002ec6:	8756                	mv	a4,s5
    80002ec8:	bfd9                	j	80002e9e <wait+0xc4>
    if(!havekids || p->killed){
    80002eca:	c701                	beqz	a4,80002ed2 <wait+0xf8>
    80002ecc:	02892783          	lw	a5,40(s2)
    80002ed0:	cb85                	beqz	a5,80002f00 <wait+0x126>
      release(&wait_lock);
    80002ed2:	0000f517          	auipc	a0,0xf
    80002ed6:	40650513          	addi	a0,a0,1030 # 800122d8 <wait_lock>
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	dbe080e7          	jalr	-578(ra) # 80000c98 <release>
      return -1;
    80002ee2:	59fd                	li	s3,-1
}
    80002ee4:	854e                	mv	a0,s3
    80002ee6:	60e6                	ld	ra,88(sp)
    80002ee8:	6446                	ld	s0,80(sp)
    80002eea:	64a6                	ld	s1,72(sp)
    80002eec:	6906                	ld	s2,64(sp)
    80002eee:	79e2                	ld	s3,56(sp)
    80002ef0:	7a42                	ld	s4,48(sp)
    80002ef2:	7aa2                	ld	s5,40(sp)
    80002ef4:	7b02                	ld	s6,32(sp)
    80002ef6:	6be2                	ld	s7,24(sp)
    80002ef8:	6c42                	ld	s8,16(sp)
    80002efa:	6ca2                	ld	s9,8(sp)
    80002efc:	6125                	addi	sp,sp,96
    80002efe:	8082                	ret
    if (p->state == RUNNING)
    80002f00:	01892783          	lw	a5,24(s2)
    80002f04:	4711                	li	a4,4
    80002f06:	02e78063          	beq	a5,a4,80002f26 <wait+0x14c>
     if (p->state == RUNNABLE)
    80002f0a:	470d                	li	a4,3
    80002f0c:	02e79e63          	bne	a5,a4,80002f48 <wait+0x16e>
      p->runnable_time += ticks - p->last_runnable_time;
    80002f10:	04892783          	lw	a5,72(s2)
    80002f14:	000ca703          	lw	a4,0(s9)
    80002f18:	9fb9                	addw	a5,a5,a4
    80002f1a:	03c92703          	lw	a4,60(s2)
    80002f1e:	9f99                	subw	a5,a5,a4
    80002f20:	04f92423          	sw	a5,72(s2)
    if (p->state == SLEEPING)
    80002f24:	a819                	j	80002f3a <wait+0x160>
      p->running_time += ticks - p->start_running_time;
    80002f26:	04492783          	lw	a5,68(s2)
    80002f2a:	000ca703          	lw	a4,0(s9)
    80002f2e:	9fb9                	addw	a5,a5,a4
    80002f30:	05092703          	lw	a4,80(s2)
    80002f34:	9f99                	subw	a5,a5,a4
    80002f36:	04f92223          	sw	a5,68(s2)
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002f3a:	85e2                	mv	a1,s8
    80002f3c:	854a                	mv	a0,s2
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	cd0080e7          	jalr	-816(ra) # 80002c0e <sleep>
    havekids = 0;
    80002f46:	b5e5                	j	80002e2e <wait+0x54>
    if (p->state == SLEEPING)
    80002f48:	4709                	li	a4,2
    80002f4a:	fee798e3          	bne	a5,a4,80002f3a <wait+0x160>
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002f4e:	04c92783          	lw	a5,76(s2)
    80002f52:	000ca703          	lw	a4,0(s9)
    80002f56:	9fb9                	addw	a5,a5,a4
    80002f58:	05492703          	lw	a4,84(s2)
    80002f5c:	9f99                	subw	a5,a5,a4
    80002f5e:	04f92623          	sw	a5,76(s2)
    80002f62:	bfe1                	j	80002f3a <wait+0x160>

0000000080002f64 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002f64:	7179                	addi	sp,sp,-48
    80002f66:	f406                	sd	ra,40(sp)
    80002f68:	f022                	sd	s0,32(sp)
    80002f6a:	ec26                	sd	s1,24(sp)
    80002f6c:	e84a                	sd	s2,16(sp)
    80002f6e:	e44e                	sd	s3,8(sp)
    80002f70:	e052                	sd	s4,0(sp)
    80002f72:	1800                	addi	s0,sp,48
  // TODO: go threw all SLEEPING and pick one to wake up- remove from SLEEPING and add to RUNNABLE.
  // struct proc *p;
  
  // printf("wakeup\n");
  struct proc *p = &proc[sleeping_list_head];
    80002f74:	00007997          	auipc	s3,0x7
    80002f78:	a589a983          	lw	s3,-1448(s3) # 800099cc <sleeping_list_head>
    80002f7c:	19800493          	li	s1,408
    80002f80:	029984b3          	mul	s1,s3,s1
    80002f84:	0000f797          	auipc	a5,0xf
    80002f88:	7ec78793          	addi	a5,a5,2028 # 80012770 <proc>
    80002f8c:	94be                	add	s1,s1,a5

  printf("sleeping");
    80002f8e:	00006517          	auipc	a0,0x6
    80002f92:	39250513          	addi	a0,a0,914 # 80009320 <digits+0x2e0>
    80002f96:	ffffd097          	auipc	ra,0xffffd
    80002f9a:	5f2080e7          	jalr	1522(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80002f9e:	4ce8                	lw	a0,92(s1)
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	904080e7          	jalr	-1788(ra) # 800018a4 <remove_proc_from_list>
    if (res == 1){
    80002fa8:	4785                	li	a5,1
    80002faa:	02f50963          	beq	a0,a5,80002fdc <wakeup+0x78>
      sleeping_list_head = -1;
      sleeping_list_tail = -1;
    }
    if (res == 2)
    80002fae:	4789                	li	a5,2
    80002fb0:	0ef51e63          	bne	a0,a5,800030ac <wakeup+0x148>
    {
      sleeping_list_head = p->next_proc;
    80002fb4:	0000f797          	auipc	a5,0xf
    80002fb8:	7bc78793          	addi	a5,a5,1980 # 80012770 <proc>
    80002fbc:	19800613          	li	a2,408
    80002fc0:	02c986b3          	mul	a3,s3,a2
    80002fc4:	96be                	add	a3,a3,a5
    80002fc6:	52b8                	lw	a4,96(a3)
    80002fc8:	00007697          	auipc	a3,0x7
    80002fcc:	a0e6a223          	sw	a4,-1532(a3) # 800099cc <sleeping_list_head>
      proc[p->next_proc].prev_proc = -1;
    80002fd0:	02c70733          	mul	a4,a4,a2
    80002fd4:	97ba                	add	a5,a5,a4
    80002fd6:	577d                	li	a4,-1
    80002fd8:	d3f8                	sw	a4,100(a5)
    }
    if (res == 3){
    80002fda:	a811                	j	80002fee <wakeup+0x8a>
      sleeping_list_head = -1;
    80002fdc:	57fd                	li	a5,-1
    80002fde:	00007717          	auipc	a4,0x7
    80002fe2:	9ef72723          	sw	a5,-1554(a4) # 800099cc <sleeping_list_head>
      sleeping_list_tail = -1;
    80002fe6:	00007717          	auipc	a4,0x7
    80002fea:	9ef72123          	sw	a5,-1566(a4) # 800099c8 <sleeping_list_tail>
      sleeping_list_tail = p->prev_proc;
      proc[p->prev_proc].next_proc = -1;
    }

    acquire(&p->lock);
    80002fee:	8526                	mv	a0,s1
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	bf4080e7          	jalr	-1036(ra) # 80000be4 <acquire>
    p->state = RUNNABLE;
    80002ff8:	19800913          	li	s2,408
    80002ffc:	032987b3          	mul	a5,s3,s2
    80003000:	0000f917          	auipc	s2,0xf
    80003004:	77090913          	addi	s2,s2,1904 # 80012770 <proc>
    80003008:	993e                	add	s2,s2,a5
    8000300a:	478d                	li	a5,3
    8000300c:	00f92c23          	sw	a5,24(s2)
    p->prev_proc = -1;
    80003010:	57fd                	li	a5,-1
    80003012:	06f92223          	sw	a5,100(s2)
    p->next_proc = -1;
    80003016:	06f92023          	sw	a5,96(s2)
    release(&p->lock);
    8000301a:	8526                	mv	a0,s1
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	c7c080e7          	jalr	-900(ra) # 80000c98 <release>

    printf("runnable");
    80003024:	00006517          	auipc	a0,0x6
    80003028:	25c50513          	addi	a0,a0,604 # 80009280 <digits+0x240>
    8000302c:	ffffd097          	auipc	ra,0xffffd
    80003030:	55c080e7          	jalr	1372(ra) # 80000588 <printf>

    add_proc_to_list(cpus[p->cpu_num].runnable_list_tail, p);
    80003034:	0000fa17          	auipc	s4,0xf
    80003038:	28ca0a13          	addi	s4,s4,652 # 800122c0 <pid_lock>
    8000303c:	05892703          	lw	a4,88(s2)
    80003040:	00371793          	slli	a5,a4,0x3
    80003044:	97ba                	add	a5,a5,a4
    80003046:	0792                	slli	a5,a5,0x4
    80003048:	97d2                	add	a5,a5,s4
    8000304a:	85a6                	mv	a1,s1
    8000304c:	0b47a503          	lw	a0,180(a5)
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	7f6080e7          	jalr	2038(ra) # 80001846 <add_proc_to_list>
    if (cpus[p->cpu_num].runnable_list_head == -1)
    80003058:	05892683          	lw	a3,88(s2)
    8000305c:	00369713          	slli	a4,a3,0x3
    80003060:	9736                	add	a4,a4,a3
    80003062:	0712                	slli	a4,a4,0x4
    80003064:	9752                	add	a4,a4,s4
    80003066:	0b072703          	lw	a4,176(a4)
    8000306a:	57fd                	li	a5,-1
    8000306c:	06f70763          	beq	a4,a5,800030da <wakeup+0x176>
    {
      cpus[p->cpu_num].runnable_list_head = p->proc_ind;
    }
    cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    80003070:	00369793          	slli	a5,a3,0x3
    80003074:	97b6                	add	a5,a5,a3
    80003076:	0792                	slli	a5,a5,0x4
    80003078:	0000f717          	auipc	a4,0xf
    8000307c:	24870713          	addi	a4,a4,584 # 800122c0 <pid_lock>
    80003080:	97ba                	add	a5,a5,a4
    80003082:	19800713          	li	a4,408
    80003086:	02e989b3          	mul	s3,s3,a4
    8000308a:	0000f717          	auipc	a4,0xf
    8000308e:	6e670713          	addi	a4,a4,1766 # 80012770 <proc>
    80003092:	99ba                	add	s3,s3,a4
    80003094:	05c9a703          	lw	a4,92(s3)
    80003098:	0ae7aa23          	sw	a4,180(a5)
  //       p->last_runnable_time = ticks;
  //     }
  //     release(&p->lock);
  //   }
  // }
}
    8000309c:	70a2                	ld	ra,40(sp)
    8000309e:	7402                	ld	s0,32(sp)
    800030a0:	64e2                	ld	s1,24(sp)
    800030a2:	6942                	ld	s2,16(sp)
    800030a4:	69a2                	ld	s3,8(sp)
    800030a6:	6a02                	ld	s4,0(sp)
    800030a8:	6145                	addi	sp,sp,48
    800030aa:	8082                	ret
    if (res == 3){
    800030ac:	478d                	li	a5,3
    800030ae:	f4f510e3          	bne	a0,a5,80002fee <wakeup+0x8a>
      sleeping_list_tail = p->prev_proc;
    800030b2:	0000f797          	auipc	a5,0xf
    800030b6:	6be78793          	addi	a5,a5,1726 # 80012770 <proc>
    800030ba:	19800613          	li	a2,408
    800030be:	02c986b3          	mul	a3,s3,a2
    800030c2:	96be                	add	a3,a3,a5
    800030c4:	52f8                	lw	a4,100(a3)
    800030c6:	00007697          	auipc	a3,0x7
    800030ca:	90e6a123          	sw	a4,-1790(a3) # 800099c8 <sleeping_list_tail>
      proc[p->prev_proc].next_proc = -1;
    800030ce:	02c70733          	mul	a4,a4,a2
    800030d2:	97ba                	add	a5,a5,a4
    800030d4:	577d                	li	a4,-1
    800030d6:	d3b8                	sw	a4,96(a5)
    800030d8:	bf19                	j	80002fee <wakeup+0x8a>
      cpus[p->cpu_num].runnable_list_head = p->proc_ind;
    800030da:	00369793          	slli	a5,a3,0x3
    800030de:	97b6                	add	a5,a5,a3
    800030e0:	0792                	slli	a5,a5,0x4
    800030e2:	97d2                	add	a5,a5,s4
    800030e4:	05c92703          	lw	a4,92(s2)
    800030e8:	0ae7a823          	sw	a4,176(a5)
    800030ec:	b751                	j	80003070 <wakeup+0x10c>

00000000800030ee <reparent>:
{
    800030ee:	7179                	addi	sp,sp,-48
    800030f0:	f406                	sd	ra,40(sp)
    800030f2:	f022                	sd	s0,32(sp)
    800030f4:	ec26                	sd	s1,24(sp)
    800030f6:	e84a                	sd	s2,16(sp)
    800030f8:	e44e                	sd	s3,8(sp)
    800030fa:	e052                	sd	s4,0(sp)
    800030fc:	1800                	addi	s0,sp,48
    800030fe:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003100:	0000f497          	auipc	s1,0xf
    80003104:	67048493          	addi	s1,s1,1648 # 80012770 <proc>
      pp->parent = initproc;
    80003108:	00007a17          	auipc	s4,0x7
    8000310c:	f20a0a13          	addi	s4,s4,-224 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003110:	00016997          	auipc	s3,0x16
    80003114:	c6098993          	addi	s3,s3,-928 # 80018d70 <tickslock>
    80003118:	a029                	j	80003122 <reparent+0x34>
    8000311a:	19848493          	addi	s1,s1,408
    8000311e:	01348d63          	beq	s1,s3,80003138 <reparent+0x4a>
    if(pp->parent == p){
    80003122:	74bc                	ld	a5,104(s1)
    80003124:	ff279be3          	bne	a5,s2,8000311a <reparent+0x2c>
      pp->parent = initproc;
    80003128:	000a3503          	ld	a0,0(s4)
    8000312c:	f4a8                	sd	a0,104(s1)
      wakeup(initproc);
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	e36080e7          	jalr	-458(ra) # 80002f64 <wakeup>
    80003136:	b7d5                	j	8000311a <reparent+0x2c>
}
    80003138:	70a2                	ld	ra,40(sp)
    8000313a:	7402                	ld	s0,32(sp)
    8000313c:	64e2                	ld	s1,24(sp)
    8000313e:	6942                	ld	s2,16(sp)
    80003140:	69a2                	ld	s3,8(sp)
    80003142:	6a02                	ld	s4,0(sp)
    80003144:	6145                	addi	sp,sp,48
    80003146:	8082                	ret

0000000080003148 <exit>:
{
    80003148:	7179                	addi	sp,sp,-48
    8000314a:	f406                	sd	ra,40(sp)
    8000314c:	f022                	sd	s0,32(sp)
    8000314e:	ec26                	sd	s1,24(sp)
    80003150:	e84a                	sd	s2,16(sp)
    80003152:	e44e                	sd	s3,8(sp)
    80003154:	e052                	sd	s4,0(sp)
    80003156:	1800                	addi	s0,sp,48
    80003158:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	a4a080e7          	jalr	-1462(ra) # 80001ba4 <myproc>
    80003162:	892a                	mv	s2,a0
  if(p == initproc)
    80003164:	00007797          	auipc	a5,0x7
    80003168:	ec47b783          	ld	a5,-316(a5) # 8000a028 <initproc>
    8000316c:	10050493          	addi	s1,a0,256
    80003170:	18050993          	addi	s3,a0,384
    80003174:	02a79363          	bne	a5,a0,8000319a <exit+0x52>
    panic("init exiting");
    80003178:	00006517          	auipc	a0,0x6
    8000317c:	1b850513          	addi	a0,a0,440 # 80009330 <digits+0x2f0>
    80003180:	ffffd097          	auipc	ra,0xffffd
    80003184:	3be080e7          	jalr	958(ra) # 8000053e <panic>
      fileclose(f);
    80003188:	00002097          	auipc	ra,0x2
    8000318c:	7d4080e7          	jalr	2004(ra) # 8000595c <fileclose>
      p->ofile[fd] = 0;
    80003190:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80003194:	04a1                	addi	s1,s1,8
    80003196:	00998563          	beq	s3,s1,800031a0 <exit+0x58>
    if(p->ofile[fd]){
    8000319a:	6088                	ld	a0,0(s1)
    8000319c:	f575                	bnez	a0,80003188 <exit+0x40>
    8000319e:	bfdd                	j	80003194 <exit+0x4c>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800031a0:	18890493          	addi	s1,s2,392
    800031a4:	00006597          	auipc	a1,0x6
    800031a8:	19c58593          	addi	a1,a1,412 # 80009340 <digits+0x300>
    800031ac:	8526                	mv	a0,s1
    800031ae:	fffff097          	auipc	ra,0xfffff
    800031b2:	eb6080e7          	jalr	-330(ra) # 80002064 <str_compare>
    800031b6:	e97d                	bnez	a0,800032ac <exit+0x164>
  begin_op();
    800031b8:	00002097          	auipc	ra,0x2
    800031bc:	2d8080e7          	jalr	728(ra) # 80005490 <begin_op>
  iput(p->cwd);
    800031c0:	18093503          	ld	a0,384(s2)
    800031c4:	00002097          	auipc	ra,0x2
    800031c8:	ab4080e7          	jalr	-1356(ra) # 80004c78 <iput>
  end_op();
    800031cc:	00002097          	auipc	ra,0x2
    800031d0:	344080e7          	jalr	836(ra) # 80005510 <end_op>
  p->cwd = 0;
    800031d4:	18093023          	sd	zero,384(s2)
  acquire(&wait_lock);
    800031d8:	0000f517          	auipc	a0,0xf
    800031dc:	10050513          	addi	a0,a0,256 # 800122d8 <wait_lock>
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	a04080e7          	jalr	-1532(ra) # 80000be4 <acquire>
  reparent(p);
    800031e8:	854a                	mv	a0,s2
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	f04080e7          	jalr	-252(ra) # 800030ee <reparent>
  wakeup(p->parent);
    800031f2:	06893503          	ld	a0,104(s2)
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	d6e080e7          	jalr	-658(ra) # 80002f64 <wakeup>
  acquire(&p->lock);
    800031fe:	854a                	mv	a0,s2
    80003200:	ffffe097          	auipc	ra,0xffffe
    80003204:	9e4080e7          	jalr	-1564(ra) # 80000be4 <acquire>
  p->xstate = status;
    80003208:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000320c:	4795                	li	a5,5
    8000320e:	00f92c23          	sw	a5,24(s2)
  p->running_time += ticks - p->start_running_time;
    80003212:	04492783          	lw	a5,68(s2)
    80003216:	00007717          	auipc	a4,0x7
    8000321a:	e3e72703          	lw	a4,-450(a4) # 8000a054 <ticks>
    8000321e:	9fb9                	addw	a5,a5,a4
    80003220:	05092703          	lw	a4,80(s2)
    80003224:	9f99                	subw	a5,a5,a4
    80003226:	04f92223          	sw	a5,68(s2)
  printf("runable");
    8000322a:	00006517          	auipc	a0,0x6
    8000322e:	09650513          	addi	a0,a0,150 # 800092c0 <digits+0x280>
    80003232:	ffffd097          	auipc	ra,0xffffd
    80003236:	356080e7          	jalr	854(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    8000323a:	05c92503          	lw	a0,92(s2)
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	666080e7          	jalr	1638(ra) # 800018a4 <remove_proc_from_list>
  if (res == 1){
    80003246:	4785                	li	a5,1
    80003248:	10f50863          	beq	a0,a5,80003358 <exit+0x210>
  if (res == 2){
    8000324c:	4789                	li	a5,2
    8000324e:	12f50f63          	beq	a0,a5,8000338c <exit+0x244>
  if (res == 3){
    80003252:	478d                	li	a5,3
    80003254:	16f50963          	beq	a0,a5,800033c6 <exit+0x27e>
  p->next_proc = -1;
    80003258:	57fd                	li	a5,-1
    8000325a:	06f92023          	sw	a5,96(s2)
  p->prev_proc = -1;
    8000325e:	06f92223          	sw	a5,100(s2)
  if (zombie_list_tail != -1){
    80003262:	00006717          	auipc	a4,0x6
    80003266:	75672703          	lw	a4,1878(a4) # 800099b8 <zombie_list_tail>
    8000326a:	57fd                	li	a5,-1
    8000326c:	18f71a63          	bne	a4,a5,80003400 <exit+0x2b8>
    zombie_list_tail = zombie_list_head = p->proc_ind;
    80003270:	05c92783          	lw	a5,92(s2)
    80003274:	00006717          	auipc	a4,0x6
    80003278:	74f72423          	sw	a5,1864(a4) # 800099bc <zombie_list_head>
    8000327c:	00006717          	auipc	a4,0x6
    80003280:	72f72e23          	sw	a5,1852(a4) # 800099b8 <zombie_list_tail>
  release(&wait_lock);
    80003284:	0000f517          	auipc	a0,0xf
    80003288:	05450513          	addi	a0,a0,84 # 800122d8 <wait_lock>
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	a0c080e7          	jalr	-1524(ra) # 80000c98 <release>
  sched();
    80003294:	fffff097          	auipc	ra,0xfffff
    80003298:	6f8080e7          	jalr	1784(ra) # 8000298c <sched>
  panic("zombie exit");
    8000329c:	00006517          	auipc	a0,0x6
    800032a0:	0b450513          	addi	a0,a0,180 # 80009350 <digits+0x310>
    800032a4:	ffffd097          	auipc	ra,0xffffd
    800032a8:	29a080e7          	jalr	666(ra) # 8000053e <panic>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800032ac:	00006597          	auipc	a1,0x6
    800032b0:	09c58593          	addi	a1,a1,156 # 80009348 <digits+0x308>
    800032b4:	8526                	mv	a0,s1
    800032b6:	fffff097          	auipc	ra,0xfffff
    800032ba:	dae080e7          	jalr	-594(ra) # 80002064 <str_compare>
    800032be:	ee050de3          	beqz	a0,800031b8 <exit+0x70>
    sleeping_processes_mean = ((sleeping_processes_mean * p_counter)+ p->sleeping_time)/(p_counter+1);
    800032c2:	00007597          	auipc	a1,0x7
    800032c6:	d7a58593          	addi	a1,a1,-646 # 8000a03c <p_counter>
    800032ca:	4194                	lw	a3,0(a1)
    800032cc:	0016871b          	addiw	a4,a3,1
    800032d0:	00007617          	auipc	a2,0x7
    800032d4:	d7860613          	addi	a2,a2,-648 # 8000a048 <sleeping_processes_mean>
    800032d8:	421c                	lw	a5,0(a2)
    800032da:	02d787bb          	mulw	a5,a5,a3
    800032de:	04c92503          	lw	a0,76(s2)
    800032e2:	9fa9                	addw	a5,a5,a0
    800032e4:	02e7d7bb          	divuw	a5,a5,a4
    800032e8:	c21c                	sw	a5,0(a2)
    running_processes_mean = ((running_processes_mean * p_counter)+ p->running_time)/(p_counter+1);
    800032ea:	04492603          	lw	a2,68(s2)
    800032ee:	00007517          	auipc	a0,0x7
    800032f2:	d5650513          	addi	a0,a0,-682 # 8000a044 <running_processes_mean>
    800032f6:	411c                	lw	a5,0(a0)
    800032f8:	02d787bb          	mulw	a5,a5,a3
    800032fc:	9fb1                	addw	a5,a5,a2
    800032fe:	02e7d7bb          	divuw	a5,a5,a4
    80003302:	c11c                	sw	a5,0(a0)
    runnable_processes_mean = ((runnable_processes_mean * p_counter)+ p->runnable_time)/(p_counter+1);
    80003304:	00007517          	auipc	a0,0x7
    80003308:	d3c50513          	addi	a0,a0,-708 # 8000a040 <runnable_processes_mean>
    8000330c:	411c                	lw	a5,0(a0)
    8000330e:	02d787bb          	mulw	a5,a5,a3
    80003312:	04892683          	lw	a3,72(s2)
    80003316:	9fb5                	addw	a5,a5,a3
    80003318:	02e7d7bb          	divuw	a5,a5,a4
    8000331c:	c11c                	sw	a5,0(a0)
    p_counter += 1;
    8000331e:	c198                	sw	a4,0(a1)
    program_time += p->running_time;
    80003320:	00007697          	auipc	a3,0x7
    80003324:	d1868693          	addi	a3,a3,-744 # 8000a038 <program_time>
    80003328:	429c                	lw	a5,0(a3)
    8000332a:	00c7873b          	addw	a4,a5,a2
    8000332e:	c298                	sw	a4,0(a3)
    cpu_utilization = (program_time* 100) / (ticks - start_time) ;
    80003330:	06400793          	li	a5,100
    80003334:	02e787bb          	mulw	a5,a5,a4
    80003338:	00007717          	auipc	a4,0x7
    8000333c:	d1c72703          	lw	a4,-740(a4) # 8000a054 <ticks>
    80003340:	00007697          	auipc	a3,0x7
    80003344:	cf46a683          	lw	a3,-780(a3) # 8000a034 <start_time>
    80003348:	9f15                	subw	a4,a4,a3
    8000334a:	02e7d7bb          	divuw	a5,a5,a4
    8000334e:	00007717          	auipc	a4,0x7
    80003352:	cef72123          	sw	a5,-798(a4) # 8000a030 <cpu_utilization>
    80003356:	b58d                	j	800031b8 <exit+0x70>
    80003358:	8612                	mv	a2,tp
  int id = r_tp();
    8000335a:	2601                	sext.w	a2,a2
  c->cpu_id = id;
    8000335c:	0000f797          	auipc	a5,0xf
    80003360:	f6478793          	addi	a5,a5,-156 # 800122c0 <pid_lock>
    80003364:	09000693          	li	a3,144
    80003368:	02d60733          	mul	a4,a2,a3
    8000336c:	973e                	add	a4,a4,a5
    8000336e:	0ac72c23          	sw	a2,184(a4)
    mycpu()->runnable_list_head = -1;
    80003372:	567d                	li	a2,-1
    80003374:	0ac72823          	sw	a2,176(a4)
    80003378:	8712                	mv	a4,tp
  int id = r_tp();
    8000337a:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    8000337c:	02d706b3          	mul	a3,a4,a3
    80003380:	97b6                	add	a5,a5,a3
    80003382:	0ae7ac23          	sw	a4,184(a5)
    mycpu()->runnable_list_tail = -1;
    80003386:	0ac7aa23          	sw	a2,180(a5)
  if (res == 3){
    8000338a:	b5f9                	j	80003258 <exit+0x110>
    8000338c:	8792                	mv	a5,tp
  int id = r_tp();
    8000338e:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80003390:	09000713          	li	a4,144
    80003394:	02e786b3          	mul	a3,a5,a4
    80003398:	0000f717          	auipc	a4,0xf
    8000339c:	f2870713          	addi	a4,a4,-216 # 800122c0 <pid_lock>
    800033a0:	9736                	add	a4,a4,a3
    800033a2:	0af72c23          	sw	a5,184(a4)
    mycpu()->runnable_list_head = p->next_proc;
    800033a6:	06092783          	lw	a5,96(s2)
    800033aa:	0af72823          	sw	a5,176(a4)
    proc[p->next_proc].prev_proc = -1;
    800033ae:	19800713          	li	a4,408
    800033b2:	02e787b3          	mul	a5,a5,a4
    800033b6:	0000f717          	auipc	a4,0xf
    800033ba:	3ba70713          	addi	a4,a4,954 # 80012770 <proc>
    800033be:	97ba                	add	a5,a5,a4
    800033c0:	577d                	li	a4,-1
    800033c2:	d3f8                	sw	a4,100(a5)
  if (res == 3){
    800033c4:	bd51                	j	80003258 <exit+0x110>
    800033c6:	8792                	mv	a5,tp
  int id = r_tp();
    800033c8:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800033ca:	09000713          	li	a4,144
    800033ce:	02e786b3          	mul	a3,a5,a4
    800033d2:	0000f717          	auipc	a4,0xf
    800033d6:	eee70713          	addi	a4,a4,-274 # 800122c0 <pid_lock>
    800033da:	9736                	add	a4,a4,a3
    800033dc:	0af72c23          	sw	a5,184(a4)
    mycpu()->runnable_list_tail = p->prev_proc;
    800033e0:	06492783          	lw	a5,100(s2)
    800033e4:	0af72a23          	sw	a5,180(a4)
    proc[p->prev_proc].next_proc = -1;
    800033e8:	19800713          	li	a4,408
    800033ec:	02e787b3          	mul	a5,a5,a4
    800033f0:	0000f717          	auipc	a4,0xf
    800033f4:	38070713          	addi	a4,a4,896 # 80012770 <proc>
    800033f8:	97ba                	add	a5,a5,a4
    800033fa:	577d                	li	a4,-1
    800033fc:	d3b8                	sw	a4,96(a5)
    800033fe:	bda9                	j	80003258 <exit+0x110>
    printf("zombie");
    80003400:	00006517          	auipc	a0,0x6
    80003404:	e6050513          	addi	a0,a0,-416 # 80009260 <digits+0x220>
    80003408:	ffffd097          	auipc	ra,0xffffd
    8000340c:	180080e7          	jalr	384(ra) # 80000588 <printf>
    add_proc_to_list(zombie_list_tail, p);
    80003410:	85ca                	mv	a1,s2
    80003412:	00006517          	auipc	a0,0x6
    80003416:	5a652503          	lw	a0,1446(a0) # 800099b8 <zombie_list_tail>
    8000341a:	ffffe097          	auipc	ra,0xffffe
    8000341e:	42c080e7          	jalr	1068(ra) # 80001846 <add_proc_to_list>
     if (zombie_list_head == -1)
    80003422:	00006717          	auipc	a4,0x6
    80003426:	59a72703          	lw	a4,1434(a4) # 800099bc <zombie_list_head>
    8000342a:	57fd                	li	a5,-1
    8000342c:	00f70963          	beq	a4,a5,8000343e <exit+0x2f6>
    zombie_list_tail = p->proc_ind;
    80003430:	05c92783          	lw	a5,92(s2)
    80003434:	00006717          	auipc	a4,0x6
    80003438:	58f72223          	sw	a5,1412(a4) # 800099b8 <zombie_list_tail>
    8000343c:	b5a1                	j	80003284 <exit+0x13c>
        zombie_list_head = p->proc_ind;
    8000343e:	05c92783          	lw	a5,92(s2)
    80003442:	00006717          	auipc	a4,0x6
    80003446:	56f72d23          	sw	a5,1402(a4) # 800099bc <zombie_list_head>
    8000344a:	b7dd                	j	80003430 <exit+0x2e8>

000000008000344c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000344c:	7179                	addi	sp,sp,-48
    8000344e:	f406                	sd	ra,40(sp)
    80003450:	f022                	sd	s0,32(sp)
    80003452:	ec26                	sd	s1,24(sp)
    80003454:	e84a                	sd	s2,16(sp)
    80003456:	e44e                	sd	s3,8(sp)
    80003458:	1800                	addi	s0,sp,48
    8000345a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000345c:	0000f497          	auipc	s1,0xf
    80003460:	31448493          	addi	s1,s1,788 # 80012770 <proc>
    80003464:	00016997          	auipc	s3,0x16
    80003468:	90c98993          	addi	s3,s3,-1780 # 80018d70 <tickslock>
    acquire(&p->lock);
    8000346c:	8526                	mv	a0,s1
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	776080e7          	jalr	1910(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80003476:	589c                	lw	a5,48(s1)
    80003478:	01278d63          	beq	a5,s2,80003492 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000347c:	8526                	mv	a0,s1
    8000347e:	ffffe097          	auipc	ra,0xffffe
    80003482:	81a080e7          	jalr	-2022(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003486:	19848493          	addi	s1,s1,408
    8000348a:	ff3491e3          	bne	s1,s3,8000346c <kill+0x20>
  }
  return -1;
    8000348e:	557d                	li	a0,-1
    80003490:	a829                	j	800034aa <kill+0x5e>
      p->killed = 1;
    80003492:	4785                	li	a5,1
    80003494:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80003496:	4c98                	lw	a4,24(s1)
    80003498:	4789                	li	a5,2
    8000349a:	00f70f63          	beq	a4,a5,800034b8 <kill+0x6c>
      release(&p->lock);
    8000349e:	8526                	mv	a0,s1
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
      return 0;
    800034a8:	4501                	li	a0,0
}
    800034aa:	70a2                	ld	ra,40(sp)
    800034ac:	7402                	ld	s0,32(sp)
    800034ae:	64e2                	ld	s1,24(sp)
    800034b0:	6942                	ld	s2,16(sp)
    800034b2:	69a2                	ld	s3,8(sp)
    800034b4:	6145                	addi	sp,sp,48
    800034b6:	8082                	ret
        p->state = RUNNABLE;
    800034b8:	478d                	li	a5,3
    800034ba:	cc9c                	sw	a5,24(s1)
        p->sleeping_time += ticks - p->start_sleeping_time;
    800034bc:	00007717          	auipc	a4,0x7
    800034c0:	b9872703          	lw	a4,-1128(a4) # 8000a054 <ticks>
    800034c4:	44fc                	lw	a5,76(s1)
    800034c6:	9fb9                	addw	a5,a5,a4
    800034c8:	48f4                	lw	a3,84(s1)
    800034ca:	9f95                	subw	a5,a5,a3
    800034cc:	c4fc                	sw	a5,76(s1)
        p->last_runnable_time = ticks;
    800034ce:	dcd8                	sw	a4,60(s1)
    800034d0:	b7f9                	j	8000349e <kill+0x52>

00000000800034d2 <print_stats>:

int 
print_stats(void)
{
    800034d2:	1141                	addi	sp,sp,-16
    800034d4:	e406                	sd	ra,8(sp)
    800034d6:	e022                	sd	s0,0(sp)
    800034d8:	0800                	addi	s0,sp,16
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    800034da:	00007597          	auipc	a1,0x7
    800034de:	b6e5a583          	lw	a1,-1170(a1) # 8000a048 <sleeping_processes_mean>
    800034e2:	00006517          	auipc	a0,0x6
    800034e6:	e7e50513          	addi	a0,a0,-386 # 80009360 <digits+0x320>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	09e080e7          	jalr	158(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    800034f2:	00007597          	auipc	a1,0x7
    800034f6:	b4e5a583          	lw	a1,-1202(a1) # 8000a040 <runnable_processes_mean>
    800034fa:	00006517          	auipc	a0,0x6
    800034fe:	e8650513          	addi	a0,a0,-378 # 80009380 <digits+0x340>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	086080e7          	jalr	134(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    8000350a:	00007597          	auipc	a1,0x7
    8000350e:	b3a5a583          	lw	a1,-1222(a1) # 8000a044 <running_processes_mean>
    80003512:	00006517          	auipc	a0,0x6
    80003516:	e8e50513          	addi	a0,a0,-370 # 800093a0 <digits+0x360>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	06e080e7          	jalr	110(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80003522:	00007597          	auipc	a1,0x7
    80003526:	b165a583          	lw	a1,-1258(a1) # 8000a038 <program_time>
    8000352a:	00006517          	auipc	a0,0x6
    8000352e:	e9650513          	addi	a0,a0,-362 # 800093c0 <digits+0x380>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	056080e7          	jalr	86(ra) # 80000588 <printf>
  printf("cpu_utilization: %d\n", cpu_utilization);
    8000353a:	00007597          	auipc	a1,0x7
    8000353e:	af65a583          	lw	a1,-1290(a1) # 8000a030 <cpu_utilization>
    80003542:	00006517          	auipc	a0,0x6
    80003546:	e9650513          	addi	a0,a0,-362 # 800093d8 <digits+0x398>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	03e080e7          	jalr	62(ra) # 80000588 <printf>
  printf("ticks: %d\n", ticks);
    80003552:	00007597          	auipc	a1,0x7
    80003556:	b025a583          	lw	a1,-1278(a1) # 8000a054 <ticks>
    8000355a:	00006517          	auipc	a0,0x6
    8000355e:	e9650513          	addi	a0,a0,-362 # 800093f0 <digits+0x3b0>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	026080e7          	jalr	38(ra) # 80000588 <printf>
  return 0;
}
    8000356a:	4501                	li	a0,0
    8000356c:	60a2                	ld	ra,8(sp)
    8000356e:	6402                	ld	s0,0(sp)
    80003570:	0141                	addi	sp,sp,16
    80003572:	8082                	ret

0000000080003574 <set_cpu>:
// Ass2
int
set_cpu(int cpu_num)
{
  // TODO
  if (cpu_num > NCPU)
    80003574:	47a1                	li	a5,8
    80003576:	08a7c963          	blt	a5,a0,80003608 <set_cpu+0x94>
{
    8000357a:	1101                	addi	sp,sp,-32
    8000357c:	ec06                	sd	ra,24(sp)
    8000357e:	e822                	sd	s0,16(sp)
    80003580:	e426                	sd	s1,8(sp)
    80003582:	e04a                	sd	s2,0(sp)
    80003584:	1000                	addi	s0,sp,32
    return -1;

  struct cpu* c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    80003586:	0000f497          	auipc	s1,0xf
    8000358a:	d6a48493          	addi	s1,s1,-662 # 800122f0 <cpus>
    8000358e:	0000f717          	auipc	a4,0xf
    80003592:	1e270713          	addi	a4,a4,482 # 80012770 <proc>
  {
    if (c->cpu_id == cpu_num)
    80003596:	0884a783          	lw	a5,136(s1)
    8000359a:	00a78d63          	beq	a5,a0,800035b4 <set_cpu+0x40>
  for(c = cpus; c < &cpus[NCPU]; c++)
    8000359e:	09048493          	addi	s1,s1,144
    800035a2:	fee49ae3          	bne	s1,a4,80003596 <set_cpu+0x22>
      }
      c->runnable_list_tail = myproc()->proc_ind;
      return 0;
    }
  }
  return -1;
    800035a6:	557d                	li	a0,-1
}
    800035a8:	60e2                	ld	ra,24(sp)
    800035aa:	6442                	ld	s0,16(sp)
    800035ac:	64a2                	ld	s1,8(sp)
    800035ae:	6902                	ld	s2,0(sp)
    800035b0:	6105                	addi	sp,sp,32
    800035b2:	8082                	ret
      printf("runnable");
    800035b4:	00006517          	auipc	a0,0x6
    800035b8:	ccc50513          	addi	a0,a0,-820 # 80009280 <digits+0x240>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	fcc080e7          	jalr	-52(ra) # 80000588 <printf>
      add_proc_to_list(c->runnable_list_tail, myproc());
    800035c4:	0844a903          	lw	s2,132(s1)
    800035c8:	ffffe097          	auipc	ra,0xffffe
    800035cc:	5dc080e7          	jalr	1500(ra) # 80001ba4 <myproc>
    800035d0:	85aa                	mv	a1,a0
    800035d2:	854a                	mv	a0,s2
    800035d4:	ffffe097          	auipc	ra,0xffffe
    800035d8:	272080e7          	jalr	626(ra) # 80001846 <add_proc_to_list>
      if (c->runnable_list_head == -1)
    800035dc:	0804a703          	lw	a4,128(s1)
    800035e0:	57fd                	li	a5,-1
    800035e2:	00f70b63          	beq	a4,a5,800035f8 <set_cpu+0x84>
      c->runnable_list_tail = myproc()->proc_ind;
    800035e6:	ffffe097          	auipc	ra,0xffffe
    800035ea:	5be080e7          	jalr	1470(ra) # 80001ba4 <myproc>
    800035ee:	4d7c                	lw	a5,92(a0)
    800035f0:	08f4a223          	sw	a5,132(s1)
      return 0;
    800035f4:	4501                	li	a0,0
    800035f6:	bf4d                	j	800035a8 <set_cpu+0x34>
        c->runnable_list_head = myproc()->proc_ind;
    800035f8:	ffffe097          	auipc	ra,0xffffe
    800035fc:	5ac080e7          	jalr	1452(ra) # 80001ba4 <myproc>
    80003600:	4d7c                	lw	a5,92(a0)
    80003602:	08f4a023          	sw	a5,128(s1)
    80003606:	b7c5                	j	800035e6 <set_cpu+0x72>
    return -1;
    80003608:	557d                	li	a0,-1
}
    8000360a:	8082                	ret

000000008000360c <get_cpu>:


int
get_cpu()
{
    8000360c:	1141                	addi	sp,sp,-16
    8000360e:	e422                	sd	s0,8(sp)
    80003610:	0800                	addi	s0,sp,16
    80003612:	8512                	mv	a0,tp
  // TODO
  return cpuid();
}
    80003614:	2501                	sext.w	a0,a0
    80003616:	6422                	ld	s0,8(sp)
    80003618:	0141                	addi	sp,sp,16
    8000361a:	8082                	ret

000000008000361c <pause_system>:


int
pause_system(int seconds)
{
    8000361c:	711d                	addi	sp,sp,-96
    8000361e:	ec86                	sd	ra,88(sp)
    80003620:	e8a2                	sd	s0,80(sp)
    80003622:	e4a6                	sd	s1,72(sp)
    80003624:	e0ca                	sd	s2,64(sp)
    80003626:	fc4e                	sd	s3,56(sp)
    80003628:	f852                	sd	s4,48(sp)
    8000362a:	f456                	sd	s5,40(sp)
    8000362c:	f05a                	sd	s6,32(sp)
    8000362e:	ec5e                	sd	s7,24(sp)
    80003630:	e862                	sd	s8,16(sp)
    80003632:	e466                	sd	s9,8(sp)
    80003634:	1080                	addi	s0,sp,96
    80003636:	84aa                	mv	s1,a0
  struct proc *p;
  struct proc *myProcess = myproc();
    80003638:	ffffe097          	auipc	ra,0xffffe
    8000363c:	56c080e7          	jalr	1388(ra) # 80001ba4 <myproc>
    80003640:	8b2a                	mv	s6,a0

  pause_flag = 1;
    80003642:	4785                	li	a5,1
    80003644:	00007717          	auipc	a4,0x7
    80003648:	a0f72623          	sw	a5,-1524(a4) # 8000a050 <pause_flag>

  wake_up_time = ticks + (seconds * 10);
    8000364c:	0024979b          	slliw	a5,s1,0x2
    80003650:	9fa5                	addw	a5,a5,s1
    80003652:	0017979b          	slliw	a5,a5,0x1
    80003656:	00007717          	auipc	a4,0x7
    8000365a:	9fe72703          	lw	a4,-1538(a4) # 8000a054 <ticks>
    8000365e:	9fb9                	addw	a5,a5,a4
    80003660:	00007717          	auipc	a4,0x7
    80003664:	9ef72623          	sw	a5,-1556(a4) # 8000a04c <wake_up_time>

  for(p = proc; p < &proc[NPROC]; p++)
    80003668:	0000f497          	auipc	s1,0xf
    8000366c:	10848493          	addi	s1,s1,264 # 80012770 <proc>
  {
    acquire(&p->lock);
    if(p->state == RUNNING)
    80003670:	4991                	li	s3,4
    {
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80003672:	00006a97          	auipc	s5,0x6
    80003676:	ccea8a93          	addi	s5,s5,-818 # 80009340 <digits+0x300>
    8000367a:	00006b97          	auipc	s7,0x6
    8000367e:	cceb8b93          	addi	s7,s7,-818 # 80009348 <digits+0x308>
        if (p != myProcess) {
          p->paused = 1;
    80003682:	4c85                	li	s9,1
          p->running_time += ticks - p->start_running_time;
    80003684:	00007c17          	auipc	s8,0x7
    80003688:	9d0c0c13          	addi	s8,s8,-1584 # 8000a054 <ticks>
  for(p = proc; p < &proc[NPROC]; p++)
    8000368c:	00015917          	auipc	s2,0x15
    80003690:	6e490913          	addi	s2,s2,1764 # 80018d70 <tickslock>
    80003694:	a811                	j	800036a8 <pause_system+0x8c>
          yield();
        }
      }
    }
    release(&p->lock);
    80003696:	8526                	mv	a0,s1
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	600080e7          	jalr	1536(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    800036a0:	19848493          	addi	s1,s1,408
    800036a4:	05248a63          	beq	s1,s2,800036f8 <pause_system+0xdc>
    acquire(&p->lock);
    800036a8:	8526                	mv	a0,s1
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	53a080e7          	jalr	1338(ra) # 80000be4 <acquire>
    if(p->state == RUNNING)
    800036b2:	4c9c                	lw	a5,24(s1)
    800036b4:	ff3791e3          	bne	a5,s3,80003696 <pause_system+0x7a>
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800036b8:	18848a13          	addi	s4,s1,392
    800036bc:	85d6                	mv	a1,s5
    800036be:	8552                	mv	a0,s4
    800036c0:	fffff097          	auipc	ra,0xfffff
    800036c4:	9a4080e7          	jalr	-1628(ra) # 80002064 <str_compare>
    800036c8:	d579                	beqz	a0,80003696 <pause_system+0x7a>
    800036ca:	85de                	mv	a1,s7
    800036cc:	8552                	mv	a0,s4
    800036ce:	fffff097          	auipc	ra,0xfffff
    800036d2:	996080e7          	jalr	-1642(ra) # 80002064 <str_compare>
    800036d6:	d161                	beqz	a0,80003696 <pause_system+0x7a>
        if (p != myProcess) {
    800036d8:	fa9b0fe3          	beq	s6,s1,80003696 <pause_system+0x7a>
          p->paused = 1;
    800036dc:	0594a023          	sw	s9,64(s1)
          p->running_time += ticks - p->start_running_time;
    800036e0:	40fc                	lw	a5,68(s1)
    800036e2:	000c2703          	lw	a4,0(s8)
    800036e6:	9fb9                	addw	a5,a5,a4
    800036e8:	48b8                	lw	a4,80(s1)
    800036ea:	9f99                	subw	a5,a5,a4
    800036ec:	c0fc                	sw	a5,68(s1)
          yield();
    800036ee:	fffff097          	auipc	ra,0xfffff
    800036f2:	3b4080e7          	jalr	948(ra) # 80002aa2 <yield>
    800036f6:	b745                	j	80003696 <pause_system+0x7a>
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    800036f8:	188b0493          	addi	s1,s6,392 # ffffffff80000188 <end+0xfffffffefffd8188>
    800036fc:	00006597          	auipc	a1,0x6
    80003700:	c4458593          	addi	a1,a1,-956 # 80009340 <digits+0x300>
    80003704:	8526                	mv	a0,s1
    80003706:	fffff097          	auipc	ra,0xfffff
    8000370a:	95e080e7          	jalr	-1698(ra) # 80002064 <str_compare>
    8000370e:	ed19                	bnez	a0,8000372c <pause_system+0x110>
    myProcess->running_time += ticks - myProcess->start_running_time;
    release(&myProcess->lock);
    yield();
  }
  return 0;
}
    80003710:	4501                	li	a0,0
    80003712:	60e6                	ld	ra,88(sp)
    80003714:	6446                	ld	s0,80(sp)
    80003716:	64a6                	ld	s1,72(sp)
    80003718:	6906                	ld	s2,64(sp)
    8000371a:	79e2                	ld	s3,56(sp)
    8000371c:	7a42                	ld	s4,48(sp)
    8000371e:	7aa2                	ld	s5,40(sp)
    80003720:	7b02                	ld	s6,32(sp)
    80003722:	6be2                	ld	s7,24(sp)
    80003724:	6c42                	ld	s8,16(sp)
    80003726:	6ca2                	ld	s9,8(sp)
    80003728:	6125                	addi	sp,sp,96
    8000372a:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    8000372c:	00006597          	auipc	a1,0x6
    80003730:	c1c58593          	addi	a1,a1,-996 # 80009348 <digits+0x308>
    80003734:	8526                	mv	a0,s1
    80003736:	fffff097          	auipc	ra,0xfffff
    8000373a:	92e080e7          	jalr	-1746(ra) # 80002064 <str_compare>
    8000373e:	d969                	beqz	a0,80003710 <pause_system+0xf4>
    acquire(&myProcess->lock);
    80003740:	855a                	mv	a0,s6
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	4a2080e7          	jalr	1186(ra) # 80000be4 <acquire>
    myProcess->paused = 1;
    8000374a:	4785                	li	a5,1
    8000374c:	04fb2023          	sw	a5,64(s6)
    myProcess->running_time += ticks - myProcess->start_running_time;
    80003750:	044b2783          	lw	a5,68(s6)
    80003754:	00007717          	auipc	a4,0x7
    80003758:	90072703          	lw	a4,-1792(a4) # 8000a054 <ticks>
    8000375c:	9fb9                	addw	a5,a5,a4
    8000375e:	050b2703          	lw	a4,80(s6)
    80003762:	9f99                	subw	a5,a5,a4
    80003764:	04fb2223          	sw	a5,68(s6)
    release(&myProcess->lock);
    80003768:	855a                	mv	a0,s6
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	52e080e7          	jalr	1326(ra) # 80000c98 <release>
    yield();
    80003772:	fffff097          	auipc	ra,0xfffff
    80003776:	330080e7          	jalr	816(ra) # 80002aa2 <yield>
    8000377a:	bf59                	j	80003710 <pause_system+0xf4>

000000008000377c <kill_system>:
// depending on usr_dst.
// Returns 0 on success, -1 on error.

int
kill_system(void) 
{
    8000377c:	7139                	addi	sp,sp,-64
    8000377e:	fc06                	sd	ra,56(sp)
    80003780:	f822                	sd	s0,48(sp)
    80003782:	f426                	sd	s1,40(sp)
    80003784:	f04a                	sd	s2,32(sp)
    80003786:	ec4e                	sd	s3,24(sp)
    80003788:	e852                	sd	s4,16(sp)
    8000378a:	e456                	sd	s5,8(sp)
    8000378c:	e05a                	sd	s6,0(sp)
    8000378e:	0080                	addi	s0,sp,64
  struct proc *p;
  struct proc *myProcess = myproc();
    80003790:	ffffe097          	auipc	ra,0xffffe
    80003794:	414080e7          	jalr	1044(ra) # 80001ba4 <myproc>
    80003798:	8b2a                	mv	s6,a0

  for (p = proc; p < &proc[NPROC]; p++) {
    8000379a:	0000f497          	auipc	s1,0xf
    8000379e:	15e48493          	addi	s1,s1,350 # 800128f8 <proc+0x188>
    800037a2:	00015a17          	auipc	s4,0x15
    800037a6:	756a0a13          	addi	s4,s4,1878 # 80018ef8 <bcache+0x170>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800037aa:	00006997          	auipc	s3,0x6
    800037ae:	b9698993          	addi	s3,s3,-1130 # 80009340 <digits+0x300>
    800037b2:	00006a97          	auipc	s5,0x6
    800037b6:	b96a8a93          	addi	s5,s5,-1130 # 80009348 <digits+0x308>
    800037ba:	a029                	j	800037c4 <kill_system+0x48>
  for (p = proc; p < &proc[NPROC]; p++) {
    800037bc:	19848493          	addi	s1,s1,408
    800037c0:	03448b63          	beq	s1,s4,800037f6 <kill_system+0x7a>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800037c4:	85ce                	mv	a1,s3
    800037c6:	8526                	mv	a0,s1
    800037c8:	fffff097          	auipc	ra,0xfffff
    800037cc:	89c080e7          	jalr	-1892(ra) # 80002064 <str_compare>
    800037d0:	d575                	beqz	a0,800037bc <kill_system+0x40>
    800037d2:	85d6                	mv	a1,s5
    800037d4:	8526                	mv	a0,s1
    800037d6:	fffff097          	auipc	ra,0xfffff
    800037da:	88e080e7          	jalr	-1906(ra) # 80002064 <str_compare>
    800037de:	dd79                	beqz	a0,800037bc <kill_system+0x40>
      if (p != myProcess) {
    800037e0:	e7848793          	addi	a5,s1,-392
    800037e4:	fcfb0ce3          	beq	s6,a5,800037bc <kill_system+0x40>
        kill(p->pid);      
    800037e8:	ea84a503          	lw	a0,-344(s1)
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	c60080e7          	jalr	-928(ra) # 8000344c <kill>
    800037f4:	b7e1                	j	800037bc <kill_system+0x40>
      }
    }
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    800037f6:	188b0493          	addi	s1,s6,392
    800037fa:	00006597          	auipc	a1,0x6
    800037fe:	b4658593          	addi	a1,a1,-1210 # 80009340 <digits+0x300>
    80003802:	8526                	mv	a0,s1
    80003804:	fffff097          	auipc	ra,0xfffff
    80003808:	860080e7          	jalr	-1952(ra) # 80002064 <str_compare>
    8000380c:	ed01                	bnez	a0,80003824 <kill_system+0xa8>
    kill(myProcess->pid);
  }
  return 0;
}
    8000380e:	4501                	li	a0,0
    80003810:	70e2                	ld	ra,56(sp)
    80003812:	7442                	ld	s0,48(sp)
    80003814:	74a2                	ld	s1,40(sp)
    80003816:	7902                	ld	s2,32(sp)
    80003818:	69e2                	ld	s3,24(sp)
    8000381a:	6a42                	ld	s4,16(sp)
    8000381c:	6aa2                	ld	s5,8(sp)
    8000381e:	6b02                	ld	s6,0(sp)
    80003820:	6121                	addi	sp,sp,64
    80003822:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    80003824:	00006597          	auipc	a1,0x6
    80003828:	b2458593          	addi	a1,a1,-1244 # 80009348 <digits+0x308>
    8000382c:	8526                	mv	a0,s1
    8000382e:	fffff097          	auipc	ra,0xfffff
    80003832:	836080e7          	jalr	-1994(ra) # 80002064 <str_compare>
    80003836:	dd61                	beqz	a0,8000380e <kill_system+0x92>
    kill(myProcess->pid);
    80003838:	030b2503          	lw	a0,48(s6)
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	c10080e7          	jalr	-1008(ra) # 8000344c <kill>
    80003844:	b7e9                	j	8000380e <kill_system+0x92>

0000000080003846 <either_copyout>:

int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80003846:	7179                	addi	sp,sp,-48
    80003848:	f406                	sd	ra,40(sp)
    8000384a:	f022                	sd	s0,32(sp)
    8000384c:	ec26                	sd	s1,24(sp)
    8000384e:	e84a                	sd	s2,16(sp)
    80003850:	e44e                	sd	s3,8(sp)
    80003852:	e052                	sd	s4,0(sp)
    80003854:	1800                	addi	s0,sp,48
    80003856:	84aa                	mv	s1,a0
    80003858:	892e                	mv	s2,a1
    8000385a:	89b2                	mv	s3,a2
    8000385c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000385e:	ffffe097          	auipc	ra,0xffffe
    80003862:	346080e7          	jalr	838(ra) # 80001ba4 <myproc>
  if(user_dst){
    80003866:	c08d                	beqz	s1,80003888 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003868:	86d2                	mv	a3,s4
    8000386a:	864e                	mv	a2,s3
    8000386c:	85ca                	mv	a1,s2
    8000386e:	6148                	ld	a0,128(a0)
    80003870:	ffffe097          	auipc	ra,0xffffe
    80003874:	e0a080e7          	jalr	-502(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80003878:	70a2                	ld	ra,40(sp)
    8000387a:	7402                	ld	s0,32(sp)
    8000387c:	64e2                	ld	s1,24(sp)
    8000387e:	6942                	ld	s2,16(sp)
    80003880:	69a2                	ld	s3,8(sp)
    80003882:	6a02                	ld	s4,0(sp)
    80003884:	6145                	addi	sp,sp,48
    80003886:	8082                	ret
    memmove((char *)dst, src, len);
    80003888:	000a061b          	sext.w	a2,s4
    8000388c:	85ce                	mv	a1,s3
    8000388e:	854a                	mv	a0,s2
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	4b0080e7          	jalr	1200(ra) # 80000d40 <memmove>
    return 0;
    80003898:	8526                	mv	a0,s1
    8000389a:	bff9                	j	80003878 <either_copyout+0x32>

000000008000389c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000389c:	7179                	addi	sp,sp,-48
    8000389e:	f406                	sd	ra,40(sp)
    800038a0:	f022                	sd	s0,32(sp)
    800038a2:	ec26                	sd	s1,24(sp)
    800038a4:	e84a                	sd	s2,16(sp)
    800038a6:	e44e                	sd	s3,8(sp)
    800038a8:	e052                	sd	s4,0(sp)
    800038aa:	1800                	addi	s0,sp,48
    800038ac:	892a                	mv	s2,a0
    800038ae:	84ae                	mv	s1,a1
    800038b0:	89b2                	mv	s3,a2
    800038b2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800038b4:	ffffe097          	auipc	ra,0xffffe
    800038b8:	2f0080e7          	jalr	752(ra) # 80001ba4 <myproc>
  if(user_src){
    800038bc:	c08d                	beqz	s1,800038de <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800038be:	86d2                	mv	a3,s4
    800038c0:	864e                	mv	a2,s3
    800038c2:	85ca                	mv	a1,s2
    800038c4:	6148                	ld	a0,128(a0)
    800038c6:	ffffe097          	auipc	ra,0xffffe
    800038ca:	e40080e7          	jalr	-448(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800038ce:	70a2                	ld	ra,40(sp)
    800038d0:	7402                	ld	s0,32(sp)
    800038d2:	64e2                	ld	s1,24(sp)
    800038d4:	6942                	ld	s2,16(sp)
    800038d6:	69a2                	ld	s3,8(sp)
    800038d8:	6a02                	ld	s4,0(sp)
    800038da:	6145                	addi	sp,sp,48
    800038dc:	8082                	ret
    memmove(dst, (char*)src, len);
    800038de:	000a061b          	sext.w	a2,s4
    800038e2:	85ce                	mv	a1,s3
    800038e4:	854a                	mv	a0,s2
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	45a080e7          	jalr	1114(ra) # 80000d40 <memmove>
    return 0;
    800038ee:	8526                	mv	a0,s1
    800038f0:	bff9                	j	800038ce <either_copyin+0x32>

00000000800038f2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800038f2:	715d                	addi	sp,sp,-80
    800038f4:	e486                	sd	ra,72(sp)
    800038f6:	e0a2                	sd	s0,64(sp)
    800038f8:	fc26                	sd	s1,56(sp)
    800038fa:	f84a                	sd	s2,48(sp)
    800038fc:	f44e                	sd	s3,40(sp)
    800038fe:	f052                	sd	s4,32(sp)
    80003900:	ec56                	sd	s5,24(sp)
    80003902:	e85a                	sd	s6,16(sp)
    80003904:	e45e                	sd	s7,8(sp)
    80003906:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003908:	00006517          	auipc	a0,0x6
    8000390c:	ac850513          	addi	a0,a0,-1336 # 800093d0 <digits+0x390>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	c78080e7          	jalr	-904(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003918:	0000f497          	auipc	s1,0xf
    8000391c:	fe048493          	addi	s1,s1,-32 # 800128f8 <proc+0x188>
    80003920:	00015917          	auipc	s2,0x15
    80003924:	5d890913          	addi	s2,s2,1496 # 80018ef8 <bcache+0x170>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003928:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000392a:	00006997          	auipc	s3,0x6
    8000392e:	ad698993          	addi	s3,s3,-1322 # 80009400 <digits+0x3c0>
    printf("%d %s %s", p->pid, state, p->name);
    80003932:	00006a97          	auipc	s5,0x6
    80003936:	ad6a8a93          	addi	s5,s5,-1322 # 80009408 <digits+0x3c8>
    printf("\n");
    8000393a:	00006a17          	auipc	s4,0x6
    8000393e:	a96a0a13          	addi	s4,s4,-1386 # 800093d0 <digits+0x390>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003942:	00006b97          	auipc	s7,0x6
    80003946:	aeeb8b93          	addi	s7,s7,-1298 # 80009430 <states.1835>
    8000394a:	a00d                	j	8000396c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000394c:	ea86a583          	lw	a1,-344(a3)
    80003950:	8556                	mv	a0,s5
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	c36080e7          	jalr	-970(ra) # 80000588 <printf>
    printf("\n");
    8000395a:	8552                	mv	a0,s4
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	c2c080e7          	jalr	-980(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003964:	19848493          	addi	s1,s1,408
    80003968:	03248163          	beq	s1,s2,8000398a <procdump+0x98>
    if(p->state == UNUSED)
    8000396c:	86a6                	mv	a3,s1
    8000396e:	e904a783          	lw	a5,-368(s1)
    80003972:	dbed                	beqz	a5,80003964 <procdump+0x72>
      state = "???";
    80003974:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003976:	fcfb6be3          	bltu	s6,a5,8000394c <procdump+0x5a>
    8000397a:	1782                	slli	a5,a5,0x20
    8000397c:	9381                	srli	a5,a5,0x20
    8000397e:	078e                	slli	a5,a5,0x3
    80003980:	97de                	add	a5,a5,s7
    80003982:	6390                	ld	a2,0(a5)
    80003984:	f661                	bnez	a2,8000394c <procdump+0x5a>
      state = "???";
    80003986:	864e                	mv	a2,s3
    80003988:	b7d1                	j	8000394c <procdump+0x5a>
  }
}
    8000398a:	60a6                	ld	ra,72(sp)
    8000398c:	6406                	ld	s0,64(sp)
    8000398e:	74e2                	ld	s1,56(sp)
    80003990:	7942                	ld	s2,48(sp)
    80003992:	79a2                	ld	s3,40(sp)
    80003994:	7a02                	ld	s4,32(sp)
    80003996:	6ae2                	ld	s5,24(sp)
    80003998:	6b42                	ld	s6,16(sp)
    8000399a:	6ba2                	ld	s7,8(sp)
    8000399c:	6161                	addi	sp,sp,80
    8000399e:	8082                	ret

00000000800039a0 <swtch>:
    800039a0:	00153023          	sd	ra,0(a0)
    800039a4:	00253423          	sd	sp,8(a0)
    800039a8:	e900                	sd	s0,16(a0)
    800039aa:	ed04                	sd	s1,24(a0)
    800039ac:	03253023          	sd	s2,32(a0)
    800039b0:	03353423          	sd	s3,40(a0)
    800039b4:	03453823          	sd	s4,48(a0)
    800039b8:	03553c23          	sd	s5,56(a0)
    800039bc:	05653023          	sd	s6,64(a0)
    800039c0:	05753423          	sd	s7,72(a0)
    800039c4:	05853823          	sd	s8,80(a0)
    800039c8:	05953c23          	sd	s9,88(a0)
    800039cc:	07a53023          	sd	s10,96(a0)
    800039d0:	07b53423          	sd	s11,104(a0)
    800039d4:	0005b083          	ld	ra,0(a1)
    800039d8:	0085b103          	ld	sp,8(a1)
    800039dc:	6980                	ld	s0,16(a1)
    800039de:	6d84                	ld	s1,24(a1)
    800039e0:	0205b903          	ld	s2,32(a1)
    800039e4:	0285b983          	ld	s3,40(a1)
    800039e8:	0305ba03          	ld	s4,48(a1)
    800039ec:	0385ba83          	ld	s5,56(a1)
    800039f0:	0405bb03          	ld	s6,64(a1)
    800039f4:	0485bb83          	ld	s7,72(a1)
    800039f8:	0505bc03          	ld	s8,80(a1)
    800039fc:	0585bc83          	ld	s9,88(a1)
    80003a00:	0605bd03          	ld	s10,96(a1)
    80003a04:	0685bd83          	ld	s11,104(a1)
    80003a08:	8082                	ret

0000000080003a0a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003a0a:	1141                	addi	sp,sp,-16
    80003a0c:	e406                	sd	ra,8(sp)
    80003a0e:	e022                	sd	s0,0(sp)
    80003a10:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003a12:	00006597          	auipc	a1,0x6
    80003a16:	a4e58593          	addi	a1,a1,-1458 # 80009460 <states.1835+0x30>
    80003a1a:	00015517          	auipc	a0,0x15
    80003a1e:	35650513          	addi	a0,a0,854 # 80018d70 <tickslock>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	132080e7          	jalr	306(ra) # 80000b54 <initlock>
}
    80003a2a:	60a2                	ld	ra,8(sp)
    80003a2c:	6402                	ld	s0,0(sp)
    80003a2e:	0141                	addi	sp,sp,16
    80003a30:	8082                	ret

0000000080003a32 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003a32:	1141                	addi	sp,sp,-16
    80003a34:	e422                	sd	s0,8(sp)
    80003a36:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003a38:	00003797          	auipc	a5,0x3
    80003a3c:	54878793          	addi	a5,a5,1352 # 80006f80 <kernelvec>
    80003a40:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003a44:	6422                	ld	s0,8(sp)
    80003a46:	0141                	addi	sp,sp,16
    80003a48:	8082                	ret

0000000080003a4a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003a4a:	1141                	addi	sp,sp,-16
    80003a4c:	e406                	sd	ra,8(sp)
    80003a4e:	e022                	sd	s0,0(sp)
    80003a50:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003a52:	ffffe097          	auipc	ra,0xffffe
    80003a56:	152080e7          	jalr	338(ra) # 80001ba4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003a5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003a5e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003a60:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003a64:	00004617          	auipc	a2,0x4
    80003a68:	59c60613          	addi	a2,a2,1436 # 80008000 <_trampoline>
    80003a6c:	00004697          	auipc	a3,0x4
    80003a70:	59468693          	addi	a3,a3,1428 # 80008000 <_trampoline>
    80003a74:	8e91                	sub	a3,a3,a2
    80003a76:	040007b7          	lui	a5,0x4000
    80003a7a:	17fd                	addi	a5,a5,-1
    80003a7c:	07b2                	slli	a5,a5,0xc
    80003a7e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003a80:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003a84:	6558                	ld	a4,136(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003a86:	180026f3          	csrr	a3,satp
    80003a8a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003a8c:	6558                	ld	a4,136(a0)
    80003a8e:	7934                	ld	a3,112(a0)
    80003a90:	6585                	lui	a1,0x1
    80003a92:	96ae                	add	a3,a3,a1
    80003a94:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003a96:	6558                	ld	a4,136(a0)
    80003a98:	00000697          	auipc	a3,0x0
    80003a9c:	13868693          	addi	a3,a3,312 # 80003bd0 <usertrap>
    80003aa0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003aa2:	6558                	ld	a4,136(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003aa4:	8692                	mv	a3,tp
    80003aa6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003aa8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003aac:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003ab0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003ab4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003ab8:	6558                	ld	a4,136(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003aba:	6f18                	ld	a4,24(a4)
    80003abc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003ac0:	614c                	ld	a1,128(a0)
    80003ac2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003ac4:	00004717          	auipc	a4,0x4
    80003ac8:	5cc70713          	addi	a4,a4,1484 # 80008090 <userret>
    80003acc:	8f11                	sub	a4,a4,a2
    80003ace:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003ad0:	577d                	li	a4,-1
    80003ad2:	177e                	slli	a4,a4,0x3f
    80003ad4:	8dd9                	or	a1,a1,a4
    80003ad6:	02000537          	lui	a0,0x2000
    80003ada:	157d                	addi	a0,a0,-1
    80003adc:	0536                	slli	a0,a0,0xd
    80003ade:	9782                	jalr	a5
}
    80003ae0:	60a2                	ld	ra,8(sp)
    80003ae2:	6402                	ld	s0,0(sp)
    80003ae4:	0141                	addi	sp,sp,16
    80003ae6:	8082                	ret

0000000080003ae8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003ae8:	1101                	addi	sp,sp,-32
    80003aea:	ec06                	sd	ra,24(sp)
    80003aec:	e822                	sd	s0,16(sp)
    80003aee:	e426                	sd	s1,8(sp)
    80003af0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003af2:	00015497          	auipc	s1,0x15
    80003af6:	27e48493          	addi	s1,s1,638 # 80018d70 <tickslock>
    80003afa:	8526                	mv	a0,s1
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	0e8080e7          	jalr	232(ra) # 80000be4 <acquire>
  ticks++;
    80003b04:	00006517          	auipc	a0,0x6
    80003b08:	55050513          	addi	a0,a0,1360 # 8000a054 <ticks>
    80003b0c:	411c                	lw	a5,0(a0)
    80003b0e:	2785                	addiw	a5,a5,1
    80003b10:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	452080e7          	jalr	1106(ra) # 80002f64 <wakeup>
  release(&tickslock);
    80003b1a:	8526                	mv	a0,s1
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	17c080e7          	jalr	380(ra) # 80000c98 <release>
}
    80003b24:	60e2                	ld	ra,24(sp)
    80003b26:	6442                	ld	s0,16(sp)
    80003b28:	64a2                	ld	s1,8(sp)
    80003b2a:	6105                	addi	sp,sp,32
    80003b2c:	8082                	ret

0000000080003b2e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003b2e:	1101                	addi	sp,sp,-32
    80003b30:	ec06                	sd	ra,24(sp)
    80003b32:	e822                	sd	s0,16(sp)
    80003b34:	e426                	sd	s1,8(sp)
    80003b36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003b38:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003b3c:	00074d63          	bltz	a4,80003b56 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003b40:	57fd                	li	a5,-1
    80003b42:	17fe                	slli	a5,a5,0x3f
    80003b44:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003b46:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003b48:	06f70363          	beq	a4,a5,80003bae <devintr+0x80>
  }
}
    80003b4c:	60e2                	ld	ra,24(sp)
    80003b4e:	6442                	ld	s0,16(sp)
    80003b50:	64a2                	ld	s1,8(sp)
    80003b52:	6105                	addi	sp,sp,32
    80003b54:	8082                	ret
     (scause & 0xff) == 9){
    80003b56:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003b5a:	46a5                	li	a3,9
    80003b5c:	fed792e3          	bne	a5,a3,80003b40 <devintr+0x12>
    int irq = plic_claim();
    80003b60:	00003097          	auipc	ra,0x3
    80003b64:	528080e7          	jalr	1320(ra) # 80007088 <plic_claim>
    80003b68:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003b6a:	47a9                	li	a5,10
    80003b6c:	02f50763          	beq	a0,a5,80003b9a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003b70:	4785                	li	a5,1
    80003b72:	02f50963          	beq	a0,a5,80003ba4 <devintr+0x76>
    return 1;
    80003b76:	4505                	li	a0,1
    } else if(irq){
    80003b78:	d8f1                	beqz	s1,80003b4c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003b7a:	85a6                	mv	a1,s1
    80003b7c:	00006517          	auipc	a0,0x6
    80003b80:	8ec50513          	addi	a0,a0,-1812 # 80009468 <states.1835+0x38>
    80003b84:	ffffd097          	auipc	ra,0xffffd
    80003b88:	a04080e7          	jalr	-1532(ra) # 80000588 <printf>
      plic_complete(irq);
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	00003097          	auipc	ra,0x3
    80003b92:	51e080e7          	jalr	1310(ra) # 800070ac <plic_complete>
    return 1;
    80003b96:	4505                	li	a0,1
    80003b98:	bf55                	j	80003b4c <devintr+0x1e>
      uartintr();
    80003b9a:	ffffd097          	auipc	ra,0xffffd
    80003b9e:	e0e080e7          	jalr	-498(ra) # 800009a8 <uartintr>
    80003ba2:	b7ed                	j	80003b8c <devintr+0x5e>
      virtio_disk_intr();
    80003ba4:	00004097          	auipc	ra,0x4
    80003ba8:	9e8080e7          	jalr	-1560(ra) # 8000758c <virtio_disk_intr>
    80003bac:	b7c5                	j	80003b8c <devintr+0x5e>
    if(cpuid() == 0){
    80003bae:	ffffe097          	auipc	ra,0xffffe
    80003bb2:	fae080e7          	jalr	-82(ra) # 80001b5c <cpuid>
    80003bb6:	c901                	beqz	a0,80003bc6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003bb8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003bbc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003bbe:	14479073          	csrw	sip,a5
    return 2;
    80003bc2:	4509                	li	a0,2
    80003bc4:	b761                	j	80003b4c <devintr+0x1e>
      clockintr();
    80003bc6:	00000097          	auipc	ra,0x0
    80003bca:	f22080e7          	jalr	-222(ra) # 80003ae8 <clockintr>
    80003bce:	b7ed                	j	80003bb8 <devintr+0x8a>

0000000080003bd0 <usertrap>:
{
    80003bd0:	1101                	addi	sp,sp,-32
    80003bd2:	ec06                	sd	ra,24(sp)
    80003bd4:	e822                	sd	s0,16(sp)
    80003bd6:	e426                	sd	s1,8(sp)
    80003bd8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003bda:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003bde:	1007f793          	andi	a5,a5,256
    80003be2:	e3a5                	bnez	a5,80003c42 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003be4:	00003797          	auipc	a5,0x3
    80003be8:	39c78793          	addi	a5,a5,924 # 80006f80 <kernelvec>
    80003bec:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003bf0:	ffffe097          	auipc	ra,0xffffe
    80003bf4:	fb4080e7          	jalr	-76(ra) # 80001ba4 <myproc>
    80003bf8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003bfa:	655c                	ld	a5,136(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003bfc:	14102773          	csrr	a4,sepc
    80003c00:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003c02:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003c06:	47a1                	li	a5,8
    80003c08:	04f71b63          	bne	a4,a5,80003c5e <usertrap+0x8e>
    if(p->killed)
    80003c0c:	551c                	lw	a5,40(a0)
    80003c0e:	e3b1                	bnez	a5,80003c52 <usertrap+0x82>
    p->trapframe->epc += 4;
    80003c10:	64d8                	ld	a4,136(s1)
    80003c12:	6f1c                	ld	a5,24(a4)
    80003c14:	0791                	addi	a5,a5,4
    80003c16:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003c18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003c1c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003c20:	10079073          	csrw	sstatus,a5
    syscall();
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	2f0080e7          	jalr	752(ra) # 80003f14 <syscall>
  if(p->killed)
    80003c2c:	549c                	lw	a5,40(s1)
    80003c2e:	e7b5                	bnez	a5,80003c9a <usertrap+0xca>
  usertrapret();
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	e1a080e7          	jalr	-486(ra) # 80003a4a <usertrapret>
}
    80003c38:	60e2                	ld	ra,24(sp)
    80003c3a:	6442                	ld	s0,16(sp)
    80003c3c:	64a2                	ld	s1,8(sp)
    80003c3e:	6105                	addi	sp,sp,32
    80003c40:	8082                	ret
    panic("usertrap: not from user mode");
    80003c42:	00006517          	auipc	a0,0x6
    80003c46:	84650513          	addi	a0,a0,-1978 # 80009488 <states.1835+0x58>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	8f4080e7          	jalr	-1804(ra) # 8000053e <panic>
      exit(-1);
    80003c52:	557d                	li	a0,-1
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	4f4080e7          	jalr	1268(ra) # 80003148 <exit>
    80003c5c:	bf55                	j	80003c10 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	ed0080e7          	jalr	-304(ra) # 80003b2e <devintr>
    80003c66:	f179                	bnez	a0,80003c2c <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003c68:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003c6c:	5890                	lw	a2,48(s1)
    80003c6e:	00006517          	auipc	a0,0x6
    80003c72:	83a50513          	addi	a0,a0,-1990 # 800094a8 <states.1835+0x78>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	912080e7          	jalr	-1774(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003c7e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003c82:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003c86:	00006517          	auipc	a0,0x6
    80003c8a:	85250513          	addi	a0,a0,-1966 # 800094d8 <states.1835+0xa8>
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	8fa080e7          	jalr	-1798(ra) # 80000588 <printf>
    p->killed = 1;
    80003c96:	4785                	li	a5,1
    80003c98:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003c9a:	557d                	li	a0,-1
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	4ac080e7          	jalr	1196(ra) # 80003148 <exit>
    80003ca4:	b771                	j	80003c30 <usertrap+0x60>

0000000080003ca6 <kerneltrap>:
{
    80003ca6:	7179                	addi	sp,sp,-48
    80003ca8:	f406                	sd	ra,40(sp)
    80003caa:	f022                	sd	s0,32(sp)
    80003cac:	ec26                	sd	s1,24(sp)
    80003cae:	e84a                	sd	s2,16(sp)
    80003cb0:	e44e                	sd	s3,8(sp)
    80003cb2:	e052                	sd	s4,0(sp)
    80003cb4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003cb6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003cba:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003cbe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0){
    80003cc2:	1004f793          	andi	a5,s1,256
    80003cc6:	cb8d                	beqz	a5,80003cf8 <kerneltrap+0x52>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003cc8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003ccc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003cce:	ef8d                	bnez	a5,80003d08 <kerneltrap+0x62>
  if((which_dev = devintr()) == 0){
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	e5e080e7          	jalr	-418(ra) # 80003b2e <devintr>
    80003cd8:	c121                	beqz	a0,80003d18 <kerneltrap+0x72>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003cda:	4789                	li	a5,2
    80003cdc:	06f50b63          	beq	a0,a5,80003d52 <kerneltrap+0xac>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003ce0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003ce4:	10049073          	csrw	sstatus,s1
}
    80003ce8:	70a2                	ld	ra,40(sp)
    80003cea:	7402                	ld	s0,32(sp)
    80003cec:	64e2                	ld	s1,24(sp)
    80003cee:	6942                	ld	s2,16(sp)
    80003cf0:	69a2                	ld	s3,8(sp)
    80003cf2:	6a02                	ld	s4,0(sp)
    80003cf4:	6145                	addi	sp,sp,48
    80003cf6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003cf8:	00006517          	auipc	a0,0x6
    80003cfc:	80050513          	addi	a0,a0,-2048 # 800094f8 <states.1835+0xc8>
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	83e080e7          	jalr	-1986(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003d08:	00006517          	auipc	a0,0x6
    80003d0c:	81850513          	addi	a0,a0,-2024 # 80009520 <states.1835+0xf0>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	82e080e7          	jalr	-2002(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003d18:	85ce                	mv	a1,s3
    80003d1a:	00006517          	auipc	a0,0x6
    80003d1e:	82650513          	addi	a0,a0,-2010 # 80009540 <states.1835+0x110>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	866080e7          	jalr	-1946(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003d2a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003d2e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003d32:	00006517          	auipc	a0,0x6
    80003d36:	81e50513          	addi	a0,a0,-2018 # 80009550 <states.1835+0x120>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	84e080e7          	jalr	-1970(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003d42:	00006517          	auipc	a0,0x6
    80003d46:	82650513          	addi	a0,a0,-2010 # 80009568 <states.1835+0x138>
    80003d4a:	ffffc097          	auipc	ra,0xffffc
    80003d4e:	7f4080e7          	jalr	2036(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003d52:	ffffe097          	auipc	ra,0xffffe
    80003d56:	e52080e7          	jalr	-430(ra) # 80001ba4 <myproc>
    80003d5a:	d159                	beqz	a0,80003ce0 <kerneltrap+0x3a>
    80003d5c:	ffffe097          	auipc	ra,0xffffe
    80003d60:	e48080e7          	jalr	-440(ra) # 80001ba4 <myproc>
    80003d64:	4d18                	lw	a4,24(a0)
    80003d66:	4791                	li	a5,4
    80003d68:	f6f71ce3          	bne	a4,a5,80003ce0 <kerneltrap+0x3a>
    myproc()->running_time += ticks - myproc()->start_running_time;
    80003d6c:	00006a17          	auipc	s4,0x6
    80003d70:	2e8a2a03          	lw	s4,744(s4) # 8000a054 <ticks>
    80003d74:	ffffe097          	auipc	ra,0xffffe
    80003d78:	e30080e7          	jalr	-464(ra) # 80001ba4 <myproc>
    80003d7c:	05052983          	lw	s3,80(a0)
    80003d80:	ffffe097          	auipc	ra,0xffffe
    80003d84:	e24080e7          	jalr	-476(ra) # 80001ba4 <myproc>
    80003d88:	417c                	lw	a5,68(a0)
    80003d8a:	014787bb          	addw	a5,a5,s4
    80003d8e:	413787bb          	subw	a5,a5,s3
    80003d92:	c17c                	sw	a5,68(a0)
    yield();
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	d0e080e7          	jalr	-754(ra) # 80002aa2 <yield>
    80003d9c:	b791                	j	80003ce0 <kerneltrap+0x3a>

0000000080003d9e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003d9e:	1101                	addi	sp,sp,-32
    80003da0:	ec06                	sd	ra,24(sp)
    80003da2:	e822                	sd	s0,16(sp)
    80003da4:	e426                	sd	s1,8(sp)
    80003da6:	1000                	addi	s0,sp,32
    80003da8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003daa:	ffffe097          	auipc	ra,0xffffe
    80003dae:	dfa080e7          	jalr	-518(ra) # 80001ba4 <myproc>
  switch (n) {
    80003db2:	4795                	li	a5,5
    80003db4:	0497e163          	bltu	a5,s1,80003df6 <argraw+0x58>
    80003db8:	048a                	slli	s1,s1,0x2
    80003dba:	00005717          	auipc	a4,0x5
    80003dbe:	7e670713          	addi	a4,a4,2022 # 800095a0 <states.1835+0x170>
    80003dc2:	94ba                	add	s1,s1,a4
    80003dc4:	409c                	lw	a5,0(s1)
    80003dc6:	97ba                	add	a5,a5,a4
    80003dc8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003dca:	655c                	ld	a5,136(a0)
    80003dcc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003dce:	60e2                	ld	ra,24(sp)
    80003dd0:	6442                	ld	s0,16(sp)
    80003dd2:	64a2                	ld	s1,8(sp)
    80003dd4:	6105                	addi	sp,sp,32
    80003dd6:	8082                	ret
    return p->trapframe->a1;
    80003dd8:	655c                	ld	a5,136(a0)
    80003dda:	7fa8                	ld	a0,120(a5)
    80003ddc:	bfcd                	j	80003dce <argraw+0x30>
    return p->trapframe->a2;
    80003dde:	655c                	ld	a5,136(a0)
    80003de0:	63c8                	ld	a0,128(a5)
    80003de2:	b7f5                	j	80003dce <argraw+0x30>
    return p->trapframe->a3;
    80003de4:	655c                	ld	a5,136(a0)
    80003de6:	67c8                	ld	a0,136(a5)
    80003de8:	b7dd                	j	80003dce <argraw+0x30>
    return p->trapframe->a4;
    80003dea:	655c                	ld	a5,136(a0)
    80003dec:	6bc8                	ld	a0,144(a5)
    80003dee:	b7c5                	j	80003dce <argraw+0x30>
    return p->trapframe->a5;
    80003df0:	655c                	ld	a5,136(a0)
    80003df2:	6fc8                	ld	a0,152(a5)
    80003df4:	bfe9                	j	80003dce <argraw+0x30>
  panic("argraw");
    80003df6:	00005517          	auipc	a0,0x5
    80003dfa:	78250513          	addi	a0,a0,1922 # 80009578 <states.1835+0x148>
    80003dfe:	ffffc097          	auipc	ra,0xffffc
    80003e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>

0000000080003e06 <fetchaddr>:
{
    80003e06:	1101                	addi	sp,sp,-32
    80003e08:	ec06                	sd	ra,24(sp)
    80003e0a:	e822                	sd	s0,16(sp)
    80003e0c:	e426                	sd	s1,8(sp)
    80003e0e:	e04a                	sd	s2,0(sp)
    80003e10:	1000                	addi	s0,sp,32
    80003e12:	84aa                	mv	s1,a0
    80003e14:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003e16:	ffffe097          	auipc	ra,0xffffe
    80003e1a:	d8e080e7          	jalr	-626(ra) # 80001ba4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003e1e:	7d3c                	ld	a5,120(a0)
    80003e20:	02f4f863          	bgeu	s1,a5,80003e50 <fetchaddr+0x4a>
    80003e24:	00848713          	addi	a4,s1,8
    80003e28:	02e7e663          	bltu	a5,a4,80003e54 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003e2c:	46a1                	li	a3,8
    80003e2e:	8626                	mv	a2,s1
    80003e30:	85ca                	mv	a1,s2
    80003e32:	6148                	ld	a0,128(a0)
    80003e34:	ffffe097          	auipc	ra,0xffffe
    80003e38:	8d2080e7          	jalr	-1838(ra) # 80001706 <copyin>
    80003e3c:	00a03533          	snez	a0,a0
    80003e40:	40a00533          	neg	a0,a0
}
    80003e44:	60e2                	ld	ra,24(sp)
    80003e46:	6442                	ld	s0,16(sp)
    80003e48:	64a2                	ld	s1,8(sp)
    80003e4a:	6902                	ld	s2,0(sp)
    80003e4c:	6105                	addi	sp,sp,32
    80003e4e:	8082                	ret
    return -1;
    80003e50:	557d                	li	a0,-1
    80003e52:	bfcd                	j	80003e44 <fetchaddr+0x3e>
    80003e54:	557d                	li	a0,-1
    80003e56:	b7fd                	j	80003e44 <fetchaddr+0x3e>

0000000080003e58 <fetchstr>:
{
    80003e58:	7179                	addi	sp,sp,-48
    80003e5a:	f406                	sd	ra,40(sp)
    80003e5c:	f022                	sd	s0,32(sp)
    80003e5e:	ec26                	sd	s1,24(sp)
    80003e60:	e84a                	sd	s2,16(sp)
    80003e62:	e44e                	sd	s3,8(sp)
    80003e64:	1800                	addi	s0,sp,48
    80003e66:	892a                	mv	s2,a0
    80003e68:	84ae                	mv	s1,a1
    80003e6a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003e6c:	ffffe097          	auipc	ra,0xffffe
    80003e70:	d38080e7          	jalr	-712(ra) # 80001ba4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003e74:	86ce                	mv	a3,s3
    80003e76:	864a                	mv	a2,s2
    80003e78:	85a6                	mv	a1,s1
    80003e7a:	6148                	ld	a0,128(a0)
    80003e7c:	ffffe097          	auipc	ra,0xffffe
    80003e80:	916080e7          	jalr	-1770(ra) # 80001792 <copyinstr>
  if(err < 0)
    80003e84:	00054763          	bltz	a0,80003e92 <fetchstr+0x3a>
  return strlen(buf);
    80003e88:	8526                	mv	a0,s1
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	fda080e7          	jalr	-38(ra) # 80000e64 <strlen>
}
    80003e92:	70a2                	ld	ra,40(sp)
    80003e94:	7402                	ld	s0,32(sp)
    80003e96:	64e2                	ld	s1,24(sp)
    80003e98:	6942                	ld	s2,16(sp)
    80003e9a:	69a2                	ld	s3,8(sp)
    80003e9c:	6145                	addi	sp,sp,48
    80003e9e:	8082                	ret

0000000080003ea0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003ea0:	1101                	addi	sp,sp,-32
    80003ea2:	ec06                	sd	ra,24(sp)
    80003ea4:	e822                	sd	s0,16(sp)
    80003ea6:	e426                	sd	s1,8(sp)
    80003ea8:	1000                	addi	s0,sp,32
    80003eaa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	ef2080e7          	jalr	-270(ra) # 80003d9e <argraw>
    80003eb4:	c088                	sw	a0,0(s1)
  return 0;
}
    80003eb6:	4501                	li	a0,0
    80003eb8:	60e2                	ld	ra,24(sp)
    80003eba:	6442                	ld	s0,16(sp)
    80003ebc:	64a2                	ld	s1,8(sp)
    80003ebe:	6105                	addi	sp,sp,32
    80003ec0:	8082                	ret

0000000080003ec2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003ec2:	1101                	addi	sp,sp,-32
    80003ec4:	ec06                	sd	ra,24(sp)
    80003ec6:	e822                	sd	s0,16(sp)
    80003ec8:	e426                	sd	s1,8(sp)
    80003eca:	1000                	addi	s0,sp,32
    80003ecc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	ed0080e7          	jalr	-304(ra) # 80003d9e <argraw>
    80003ed6:	e088                	sd	a0,0(s1)
  return 0;
}
    80003ed8:	4501                	li	a0,0
    80003eda:	60e2                	ld	ra,24(sp)
    80003edc:	6442                	ld	s0,16(sp)
    80003ede:	64a2                	ld	s1,8(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret

0000000080003ee4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003ee4:	1101                	addi	sp,sp,-32
    80003ee6:	ec06                	sd	ra,24(sp)
    80003ee8:	e822                	sd	s0,16(sp)
    80003eea:	e426                	sd	s1,8(sp)
    80003eec:	e04a                	sd	s2,0(sp)
    80003eee:	1000                	addi	s0,sp,32
    80003ef0:	84ae                	mv	s1,a1
    80003ef2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	eaa080e7          	jalr	-342(ra) # 80003d9e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003efc:	864a                	mv	a2,s2
    80003efe:	85a6                	mv	a1,s1
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	f58080e7          	jalr	-168(ra) # 80003e58 <fetchstr>
}
    80003f08:	60e2                	ld	ra,24(sp)
    80003f0a:	6442                	ld	s0,16(sp)
    80003f0c:	64a2                	ld	s1,8(sp)
    80003f0e:	6902                	ld	s2,0(sp)
    80003f10:	6105                	addi	sp,sp,32
    80003f12:	8082                	ret

0000000080003f14 <syscall>:
[SYS_set_cpu]       sys_set_cpu,
};

void
syscall(void)
{
    80003f14:	1101                	addi	sp,sp,-32
    80003f16:	ec06                	sd	ra,24(sp)
    80003f18:	e822                	sd	s0,16(sp)
    80003f1a:	e426                	sd	s1,8(sp)
    80003f1c:	e04a                	sd	s2,0(sp)
    80003f1e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003f20:	ffffe097          	auipc	ra,0xffffe
    80003f24:	c84080e7          	jalr	-892(ra) # 80001ba4 <myproc>
    80003f28:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003f2a:	08853903          	ld	s2,136(a0)
    80003f2e:	0a893783          	ld	a5,168(s2)
    80003f32:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003f36:	37fd                	addiw	a5,a5,-1
    80003f38:	4765                	li	a4,25
    80003f3a:	00f76f63          	bltu	a4,a5,80003f58 <syscall+0x44>
    80003f3e:	00369713          	slli	a4,a3,0x3
    80003f42:	00005797          	auipc	a5,0x5
    80003f46:	67678793          	addi	a5,a5,1654 # 800095b8 <syscalls>
    80003f4a:	97ba                	add	a5,a5,a4
    80003f4c:	639c                	ld	a5,0(a5)
    80003f4e:	c789                	beqz	a5,80003f58 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003f50:	9782                	jalr	a5
    80003f52:	06a93823          	sd	a0,112(s2)
    80003f56:	a839                	j	80003f74 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003f58:	18848613          	addi	a2,s1,392
    80003f5c:	588c                	lw	a1,48(s1)
    80003f5e:	00005517          	auipc	a0,0x5
    80003f62:	62250513          	addi	a0,a0,1570 # 80009580 <states.1835+0x150>
    80003f66:	ffffc097          	auipc	ra,0xffffc
    80003f6a:	622080e7          	jalr	1570(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003f6e:	64dc                	ld	a5,136(s1)
    80003f70:	577d                	li	a4,-1
    80003f72:	fbb8                	sd	a4,112(a5)
  }
}
    80003f74:	60e2                	ld	ra,24(sp)
    80003f76:	6442                	ld	s0,16(sp)
    80003f78:	64a2                	ld	s1,8(sp)
    80003f7a:	6902                	ld	s2,0(sp)
    80003f7c:	6105                	addi	sp,sp,32
    80003f7e:	8082                	ret

0000000080003f80 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003f80:	1101                	addi	sp,sp,-32
    80003f82:	ec06                	sd	ra,24(sp)
    80003f84:	e822                	sd	s0,16(sp)
    80003f86:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003f88:	fec40593          	addi	a1,s0,-20
    80003f8c:	4501                	li	a0,0
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	f12080e7          	jalr	-238(ra) # 80003ea0 <argint>
    return -1;
    80003f96:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003f98:	00054963          	bltz	a0,80003faa <sys_exit+0x2a>
  exit(n);
    80003f9c:	fec42503          	lw	a0,-20(s0)
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	1a8080e7          	jalr	424(ra) # 80003148 <exit>
  return 0;  // not reached
    80003fa8:	4781                	li	a5,0
}
    80003faa:	853e                	mv	a0,a5
    80003fac:	60e2                	ld	ra,24(sp)
    80003fae:	6442                	ld	s0,16(sp)
    80003fb0:	6105                	addi	sp,sp,32
    80003fb2:	8082                	ret

0000000080003fb4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003fb4:	1141                	addi	sp,sp,-16
    80003fb6:	e406                	sd	ra,8(sp)
    80003fb8:	e022                	sd	s0,0(sp)
    80003fba:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003fbc:	ffffe097          	auipc	ra,0xffffe
    80003fc0:	be8080e7          	jalr	-1048(ra) # 80001ba4 <myproc>
}
    80003fc4:	5908                	lw	a0,48(a0)
    80003fc6:	60a2                	ld	ra,8(sp)
    80003fc8:	6402                	ld	s0,0(sp)
    80003fca:	0141                	addi	sp,sp,16
    80003fcc:	8082                	ret

0000000080003fce <sys_fork>:

uint64
sys_fork(void)
{
    80003fce:	1141                	addi	sp,sp,-16
    80003fd0:	e406                	sd	ra,8(sp)
    80003fd2:	e022                	sd	s0,0(sp)
    80003fd4:	0800                	addi	s0,sp,16
  return fork();
    80003fd6:	ffffe097          	auipc	ra,0xffffe
    80003fda:	262080e7          	jalr	610(ra) # 80002238 <fork>
}
    80003fde:	60a2                	ld	ra,8(sp)
    80003fe0:	6402                	ld	s0,0(sp)
    80003fe2:	0141                	addi	sp,sp,16
    80003fe4:	8082                	ret

0000000080003fe6 <sys_wait>:

uint64
sys_wait(void)
{
    80003fe6:	1101                	addi	sp,sp,-32
    80003fe8:	ec06                	sd	ra,24(sp)
    80003fea:	e822                	sd	s0,16(sp)
    80003fec:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003fee:	fe840593          	addi	a1,s0,-24
    80003ff2:	4501                	li	a0,0
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	ece080e7          	jalr	-306(ra) # 80003ec2 <argaddr>
    80003ffc:	87aa                	mv	a5,a0
    return -1;
    80003ffe:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80004000:	0007c863          	bltz	a5,80004010 <sys_wait+0x2a>
  return wait(p);
    80004004:	fe843503          	ld	a0,-24(s0)
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	dd2080e7          	jalr	-558(ra) # 80002dda <wait>
}
    80004010:	60e2                	ld	ra,24(sp)
    80004012:	6442                	ld	s0,16(sp)
    80004014:	6105                	addi	sp,sp,32
    80004016:	8082                	ret

0000000080004018 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80004018:	7179                	addi	sp,sp,-48
    8000401a:	f406                	sd	ra,40(sp)
    8000401c:	f022                	sd	s0,32(sp)
    8000401e:	ec26                	sd	s1,24(sp)
    80004020:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80004022:	fdc40593          	addi	a1,s0,-36
    80004026:	4501                	li	a0,0
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	e78080e7          	jalr	-392(ra) # 80003ea0 <argint>
    80004030:	87aa                	mv	a5,a0
    return -1;
    80004032:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80004034:	0207c063          	bltz	a5,80004054 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80004038:	ffffe097          	auipc	ra,0xffffe
    8000403c:	b6c080e7          	jalr	-1172(ra) # 80001ba4 <myproc>
    80004040:	5d24                	lw	s1,120(a0)
  if(growproc(n) < 0)
    80004042:	fdc42503          	lw	a0,-36(s0)
    80004046:	ffffe097          	auipc	ra,0xffffe
    8000404a:	17e080e7          	jalr	382(ra) # 800021c4 <growproc>
    8000404e:	00054863          	bltz	a0,8000405e <sys_sbrk+0x46>
    return -1;
  return addr;
    80004052:	8526                	mv	a0,s1
}
    80004054:	70a2                	ld	ra,40(sp)
    80004056:	7402                	ld	s0,32(sp)
    80004058:	64e2                	ld	s1,24(sp)
    8000405a:	6145                	addi	sp,sp,48
    8000405c:	8082                	ret
    return -1;
    8000405e:	557d                	li	a0,-1
    80004060:	bfd5                	j	80004054 <sys_sbrk+0x3c>

0000000080004062 <sys_sleep>:

uint64
sys_sleep(void)
{
    80004062:	7139                	addi	sp,sp,-64
    80004064:	fc06                	sd	ra,56(sp)
    80004066:	f822                	sd	s0,48(sp)
    80004068:	f426                	sd	s1,40(sp)
    8000406a:	f04a                	sd	s2,32(sp)
    8000406c:	ec4e                	sd	s3,24(sp)
    8000406e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80004070:	fcc40593          	addi	a1,s0,-52
    80004074:	4501                	li	a0,0
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	e2a080e7          	jalr	-470(ra) # 80003ea0 <argint>
    return -1;
    8000407e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80004080:	06054563          	bltz	a0,800040ea <sys_sleep+0x88>
  acquire(&tickslock);
    80004084:	00015517          	auipc	a0,0x15
    80004088:	cec50513          	addi	a0,a0,-788 # 80018d70 <tickslock>
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	b58080e7          	jalr	-1192(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80004094:	00006917          	auipc	s2,0x6
    80004098:	fc092903          	lw	s2,-64(s2) # 8000a054 <ticks>
  
  while(ticks - ticks0 < n){
    8000409c:	fcc42783          	lw	a5,-52(s0)
    800040a0:	cf85                	beqz	a5,800040d8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800040a2:	00015997          	auipc	s3,0x15
    800040a6:	cce98993          	addi	s3,s3,-818 # 80018d70 <tickslock>
    800040aa:	00006497          	auipc	s1,0x6
    800040ae:	faa48493          	addi	s1,s1,-86 # 8000a054 <ticks>
    if(myproc()->killed){
    800040b2:	ffffe097          	auipc	ra,0xffffe
    800040b6:	af2080e7          	jalr	-1294(ra) # 80001ba4 <myproc>
    800040ba:	551c                	lw	a5,40(a0)
    800040bc:	ef9d                	bnez	a5,800040fa <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800040be:	85ce                	mv	a1,s3
    800040c0:	8526                	mv	a0,s1
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	b4c080e7          	jalr	-1204(ra) # 80002c0e <sleep>
  while(ticks - ticks0 < n){
    800040ca:	409c                	lw	a5,0(s1)
    800040cc:	412787bb          	subw	a5,a5,s2
    800040d0:	fcc42703          	lw	a4,-52(s0)
    800040d4:	fce7efe3          	bltu	a5,a4,800040b2 <sys_sleep+0x50>
  }
  release(&tickslock);
    800040d8:	00015517          	auipc	a0,0x15
    800040dc:	c9850513          	addi	a0,a0,-872 # 80018d70 <tickslock>
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	bb8080e7          	jalr	-1096(ra) # 80000c98 <release>
  return 0;
    800040e8:	4781                	li	a5,0
}
    800040ea:	853e                	mv	a0,a5
    800040ec:	70e2                	ld	ra,56(sp)
    800040ee:	7442                	ld	s0,48(sp)
    800040f0:	74a2                	ld	s1,40(sp)
    800040f2:	7902                	ld	s2,32(sp)
    800040f4:	69e2                	ld	s3,24(sp)
    800040f6:	6121                	addi	sp,sp,64
    800040f8:	8082                	ret
      release(&tickslock);
    800040fa:	00015517          	auipc	a0,0x15
    800040fe:	c7650513          	addi	a0,a0,-906 # 80018d70 <tickslock>
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	b96080e7          	jalr	-1130(ra) # 80000c98 <release>
      return -1;
    8000410a:	57fd                	li	a5,-1
    8000410c:	bff9                	j	800040ea <sys_sleep+0x88>

000000008000410e <sys_kill>:

uint64
sys_kill(void)
{
    8000410e:	1101                	addi	sp,sp,-32
    80004110:	ec06                	sd	ra,24(sp)
    80004112:	e822                	sd	s0,16(sp)
    80004114:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80004116:	fec40593          	addi	a1,s0,-20
    8000411a:	4501                	li	a0,0
    8000411c:	00000097          	auipc	ra,0x0
    80004120:	d84080e7          	jalr	-636(ra) # 80003ea0 <argint>
    80004124:	87aa                	mv	a5,a0
    return -1;
    80004126:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80004128:	0007c863          	bltz	a5,80004138 <sys_kill+0x2a>
  return kill(pid);
    8000412c:	fec42503          	lw	a0,-20(s0)
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	31c080e7          	jalr	796(ra) # 8000344c <kill>
}
    80004138:	60e2                	ld	ra,24(sp)
    8000413a:	6442                	ld	s0,16(sp)
    8000413c:	6105                	addi	sp,sp,32
    8000413e:	8082                	ret

0000000080004140 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80004140:	1101                	addi	sp,sp,-32
    80004142:	ec06                	sd	ra,24(sp)
    80004144:	e822                	sd	s0,16(sp)
    80004146:	e426                	sd	s1,8(sp)
    80004148:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000414a:	00015517          	auipc	a0,0x15
    8000414e:	c2650513          	addi	a0,a0,-986 # 80018d70 <tickslock>
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	a92080e7          	jalr	-1390(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000415a:	00006497          	auipc	s1,0x6
    8000415e:	efa4a483          	lw	s1,-262(s1) # 8000a054 <ticks>
  release(&tickslock);
    80004162:	00015517          	auipc	a0,0x15
    80004166:	c0e50513          	addi	a0,a0,-1010 # 80018d70 <tickslock>
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	b2e080e7          	jalr	-1234(ra) # 80000c98 <release>
  return xticks;
}
    80004172:	02049513          	slli	a0,s1,0x20
    80004176:	9101                	srli	a0,a0,0x20
    80004178:	60e2                	ld	ra,24(sp)
    8000417a:	6442                	ld	s0,16(sp)
    8000417c:	64a2                	ld	s1,8(sp)
    8000417e:	6105                	addi	sp,sp,32
    80004180:	8082                	ret

0000000080004182 <sys_print_stats>:

uint64
sys_print_stats(void)
{
    80004182:	1141                	addi	sp,sp,-16
    80004184:	e406                	sd	ra,8(sp)
    80004186:	e022                	sd	s0,0(sp)
    80004188:	0800                	addi	s0,sp,16
  return print_stats();
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	348080e7          	jalr	840(ra) # 800034d2 <print_stats>
}
    80004192:	60a2                	ld	ra,8(sp)
    80004194:	6402                	ld	s0,0(sp)
    80004196:	0141                	addi	sp,sp,16
    80004198:	8082                	ret

000000008000419a <sys_get_cpu>:

// Ass2
uint64
sys_get_cpu(void)
{
    8000419a:	1141                	addi	sp,sp,-16
    8000419c:	e406                	sd	ra,8(sp)
    8000419e:	e022                	sd	s0,0(sp)
    800041a0:	0800                	addi	s0,sp,16
  return get_cpu();
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	46a080e7          	jalr	1130(ra) # 8000360c <get_cpu>
}
    800041aa:	60a2                	ld	ra,8(sp)
    800041ac:	6402                	ld	s0,0(sp)
    800041ae:	0141                	addi	sp,sp,16
    800041b0:	8082                	ret

00000000800041b2 <sys_set_cpu>:

// Ass2
uint64
sys_set_cpu(void)
{
    800041b2:	1101                	addi	sp,sp,-32
    800041b4:	ec06                	sd	ra,24(sp)
    800041b6:	e822                	sd	s0,16(sp)
    800041b8:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    800041ba:	fec40593          	addi	a1,s0,-20
    800041be:	4501                	li	a0,0
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	ce0080e7          	jalr	-800(ra) # 80003ea0 <argint>
    800041c8:	87aa                	mv	a5,a0
    return -1;
    800041ca:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800041cc:	0007c863          	bltz	a5,800041dc <sys_set_cpu+0x2a>

  return set_cpu(cpu_num);
    800041d0:	fec42503          	lw	a0,-20(s0)
    800041d4:	fffff097          	auipc	ra,0xfffff
    800041d8:	3a0080e7          	jalr	928(ra) # 80003574 <set_cpu>
}
    800041dc:	60e2                	ld	ra,24(sp)
    800041de:	6442                	ld	s0,16(sp)
    800041e0:	6105                	addi	sp,sp,32
    800041e2:	8082                	ret

00000000800041e4 <sys_pause_system>:



uint64
sys_pause_system(void)
{
    800041e4:	1101                	addi	sp,sp,-32
    800041e6:	ec06                	sd	ra,24(sp)
    800041e8:	e822                	sd	s0,16(sp)
    800041ea:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    800041ec:	fec40593          	addi	a1,s0,-20
    800041f0:	4501                	li	a0,0
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	cae080e7          	jalr	-850(ra) # 80003ea0 <argint>
    800041fa:	87aa                	mv	a5,a0
    return -1;
    800041fc:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    800041fe:	0007c863          	bltz	a5,8000420e <sys_pause_system+0x2a>

  return pause_system(seconds);
    80004202:	fec42503          	lw	a0,-20(s0)
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	416080e7          	jalr	1046(ra) # 8000361c <pause_system>
}
    8000420e:	60e2                	ld	ra,24(sp)
    80004210:	6442                	ld	s0,16(sp)
    80004212:	6105                	addi	sp,sp,32
    80004214:	8082                	ret

0000000080004216 <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80004216:	1141                	addi	sp,sp,-16
    80004218:	e406                	sd	ra,8(sp)
    8000421a:	e022                	sd	s0,0(sp)
    8000421c:	0800                	addi	s0,sp,16
  return kill_system(); 
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	55e080e7          	jalr	1374(ra) # 8000377c <kill_system>
}
    80004226:	60a2                	ld	ra,8(sp)
    80004228:	6402                	ld	s0,0(sp)
    8000422a:	0141                	addi	sp,sp,16
    8000422c:	8082                	ret

000000008000422e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000422e:	7179                	addi	sp,sp,-48
    80004230:	f406                	sd	ra,40(sp)
    80004232:	f022                	sd	s0,32(sp)
    80004234:	ec26                	sd	s1,24(sp)
    80004236:	e84a                	sd	s2,16(sp)
    80004238:	e44e                	sd	s3,8(sp)
    8000423a:	e052                	sd	s4,0(sp)
    8000423c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000423e:	00005597          	auipc	a1,0x5
    80004242:	45258593          	addi	a1,a1,1106 # 80009690 <syscalls+0xd8>
    80004246:	00015517          	auipc	a0,0x15
    8000424a:	b4250513          	addi	a0,a0,-1214 # 80018d88 <bcache>
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	906080e7          	jalr	-1786(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80004256:	0001d797          	auipc	a5,0x1d
    8000425a:	b3278793          	addi	a5,a5,-1230 # 80020d88 <bcache+0x8000>
    8000425e:	0001d717          	auipc	a4,0x1d
    80004262:	d9270713          	addi	a4,a4,-622 # 80020ff0 <bcache+0x8268>
    80004266:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000426a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000426e:	00015497          	auipc	s1,0x15
    80004272:	b3248493          	addi	s1,s1,-1230 # 80018da0 <bcache+0x18>
    b->next = bcache.head.next;
    80004276:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80004278:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000427a:	00005a17          	auipc	s4,0x5
    8000427e:	41ea0a13          	addi	s4,s4,1054 # 80009698 <syscalls+0xe0>
    b->next = bcache.head.next;
    80004282:	2b893783          	ld	a5,696(s2)
    80004286:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80004288:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000428c:	85d2                	mv	a1,s4
    8000428e:	01048513          	addi	a0,s1,16
    80004292:	00001097          	auipc	ra,0x1
    80004296:	4bc080e7          	jalr	1212(ra) # 8000574e <initsleeplock>
    bcache.head.next->prev = b;
    8000429a:	2b893783          	ld	a5,696(s2)
    8000429e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800042a0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800042a4:	45848493          	addi	s1,s1,1112
    800042a8:	fd349de3          	bne	s1,s3,80004282 <binit+0x54>
  }
}
    800042ac:	70a2                	ld	ra,40(sp)
    800042ae:	7402                	ld	s0,32(sp)
    800042b0:	64e2                	ld	s1,24(sp)
    800042b2:	6942                	ld	s2,16(sp)
    800042b4:	69a2                	ld	s3,8(sp)
    800042b6:	6a02                	ld	s4,0(sp)
    800042b8:	6145                	addi	sp,sp,48
    800042ba:	8082                	ret

00000000800042bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800042bc:	7179                	addi	sp,sp,-48
    800042be:	f406                	sd	ra,40(sp)
    800042c0:	f022                	sd	s0,32(sp)
    800042c2:	ec26                	sd	s1,24(sp)
    800042c4:	e84a                	sd	s2,16(sp)
    800042c6:	e44e                	sd	s3,8(sp)
    800042c8:	1800                	addi	s0,sp,48
    800042ca:	89aa                	mv	s3,a0
    800042cc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800042ce:	00015517          	auipc	a0,0x15
    800042d2:	aba50513          	addi	a0,a0,-1350 # 80018d88 <bcache>
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	90e080e7          	jalr	-1778(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800042de:	0001d497          	auipc	s1,0x1d
    800042e2:	d624b483          	ld	s1,-670(s1) # 80021040 <bcache+0x82b8>
    800042e6:	0001d797          	auipc	a5,0x1d
    800042ea:	d0a78793          	addi	a5,a5,-758 # 80020ff0 <bcache+0x8268>
    800042ee:	02f48f63          	beq	s1,a5,8000432c <bread+0x70>
    800042f2:	873e                	mv	a4,a5
    800042f4:	a021                	j	800042fc <bread+0x40>
    800042f6:	68a4                	ld	s1,80(s1)
    800042f8:	02e48a63          	beq	s1,a4,8000432c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800042fc:	449c                	lw	a5,8(s1)
    800042fe:	ff379ce3          	bne	a5,s3,800042f6 <bread+0x3a>
    80004302:	44dc                	lw	a5,12(s1)
    80004304:	ff2799e3          	bne	a5,s2,800042f6 <bread+0x3a>
      b->refcnt++;
    80004308:	40bc                	lw	a5,64(s1)
    8000430a:	2785                	addiw	a5,a5,1
    8000430c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000430e:	00015517          	auipc	a0,0x15
    80004312:	a7a50513          	addi	a0,a0,-1414 # 80018d88 <bcache>
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000431e:	01048513          	addi	a0,s1,16
    80004322:	00001097          	auipc	ra,0x1
    80004326:	466080e7          	jalr	1126(ra) # 80005788 <acquiresleep>
      return b;
    8000432a:	a8b9                	j	80004388 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000432c:	0001d497          	auipc	s1,0x1d
    80004330:	d0c4b483          	ld	s1,-756(s1) # 80021038 <bcache+0x82b0>
    80004334:	0001d797          	auipc	a5,0x1d
    80004338:	cbc78793          	addi	a5,a5,-836 # 80020ff0 <bcache+0x8268>
    8000433c:	00f48863          	beq	s1,a5,8000434c <bread+0x90>
    80004340:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80004342:	40bc                	lw	a5,64(s1)
    80004344:	cf81                	beqz	a5,8000435c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80004346:	64a4                	ld	s1,72(s1)
    80004348:	fee49de3          	bne	s1,a4,80004342 <bread+0x86>
  panic("bget: no buffers");
    8000434c:	00005517          	auipc	a0,0x5
    80004350:	35450513          	addi	a0,a0,852 # 800096a0 <syscalls+0xe8>
    80004354:	ffffc097          	auipc	ra,0xffffc
    80004358:	1ea080e7          	jalr	490(ra) # 8000053e <panic>
      b->dev = dev;
    8000435c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80004360:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80004364:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80004368:	4785                	li	a5,1
    8000436a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000436c:	00015517          	auipc	a0,0x15
    80004370:	a1c50513          	addi	a0,a0,-1508 # 80018d88 <bcache>
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000437c:	01048513          	addi	a0,s1,16
    80004380:	00001097          	auipc	ra,0x1
    80004384:	408080e7          	jalr	1032(ra) # 80005788 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80004388:	409c                	lw	a5,0(s1)
    8000438a:	cb89                	beqz	a5,8000439c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000438c:	8526                	mv	a0,s1
    8000438e:	70a2                	ld	ra,40(sp)
    80004390:	7402                	ld	s0,32(sp)
    80004392:	64e2                	ld	s1,24(sp)
    80004394:	6942                	ld	s2,16(sp)
    80004396:	69a2                	ld	s3,8(sp)
    80004398:	6145                	addi	sp,sp,48
    8000439a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000439c:	4581                	li	a1,0
    8000439e:	8526                	mv	a0,s1
    800043a0:	00003097          	auipc	ra,0x3
    800043a4:	f16080e7          	jalr	-234(ra) # 800072b6 <virtio_disk_rw>
    b->valid = 1;
    800043a8:	4785                	li	a5,1
    800043aa:	c09c                	sw	a5,0(s1)
  return b;
    800043ac:	b7c5                	j	8000438c <bread+0xd0>

00000000800043ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800043ae:	1101                	addi	sp,sp,-32
    800043b0:	ec06                	sd	ra,24(sp)
    800043b2:	e822                	sd	s0,16(sp)
    800043b4:	e426                	sd	s1,8(sp)
    800043b6:	1000                	addi	s0,sp,32
    800043b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800043ba:	0541                	addi	a0,a0,16
    800043bc:	00001097          	auipc	ra,0x1
    800043c0:	466080e7          	jalr	1126(ra) # 80005822 <holdingsleep>
    800043c4:	cd01                	beqz	a0,800043dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800043c6:	4585                	li	a1,1
    800043c8:	8526                	mv	a0,s1
    800043ca:	00003097          	auipc	ra,0x3
    800043ce:	eec080e7          	jalr	-276(ra) # 800072b6 <virtio_disk_rw>
}
    800043d2:	60e2                	ld	ra,24(sp)
    800043d4:	6442                	ld	s0,16(sp)
    800043d6:	64a2                	ld	s1,8(sp)
    800043d8:	6105                	addi	sp,sp,32
    800043da:	8082                	ret
    panic("bwrite");
    800043dc:	00005517          	auipc	a0,0x5
    800043e0:	2dc50513          	addi	a0,a0,732 # 800096b8 <syscalls+0x100>
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	15a080e7          	jalr	346(ra) # 8000053e <panic>

00000000800043ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800043ec:	1101                	addi	sp,sp,-32
    800043ee:	ec06                	sd	ra,24(sp)
    800043f0:	e822                	sd	s0,16(sp)
    800043f2:	e426                	sd	s1,8(sp)
    800043f4:	e04a                	sd	s2,0(sp)
    800043f6:	1000                	addi	s0,sp,32
    800043f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800043fa:	01050913          	addi	s2,a0,16
    800043fe:	854a                	mv	a0,s2
    80004400:	00001097          	auipc	ra,0x1
    80004404:	422080e7          	jalr	1058(ra) # 80005822 <holdingsleep>
    80004408:	c92d                	beqz	a0,8000447a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000440a:	854a                	mv	a0,s2
    8000440c:	00001097          	auipc	ra,0x1
    80004410:	3d2080e7          	jalr	978(ra) # 800057de <releasesleep>

  acquire(&bcache.lock);
    80004414:	00015517          	auipc	a0,0x15
    80004418:	97450513          	addi	a0,a0,-1676 # 80018d88 <bcache>
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	7c8080e7          	jalr	1992(ra) # 80000be4 <acquire>
  b->refcnt--;
    80004424:	40bc                	lw	a5,64(s1)
    80004426:	37fd                	addiw	a5,a5,-1
    80004428:	0007871b          	sext.w	a4,a5
    8000442c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000442e:	eb05                	bnez	a4,8000445e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80004430:	68bc                	ld	a5,80(s1)
    80004432:	64b8                	ld	a4,72(s1)
    80004434:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80004436:	64bc                	ld	a5,72(s1)
    80004438:	68b8                	ld	a4,80(s1)
    8000443a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000443c:	0001d797          	auipc	a5,0x1d
    80004440:	94c78793          	addi	a5,a5,-1716 # 80020d88 <bcache+0x8000>
    80004444:	2b87b703          	ld	a4,696(a5)
    80004448:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000444a:	0001d717          	auipc	a4,0x1d
    8000444e:	ba670713          	addi	a4,a4,-1114 # 80020ff0 <bcache+0x8268>
    80004452:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80004454:	2b87b703          	ld	a4,696(a5)
    80004458:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000445a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000445e:	00015517          	auipc	a0,0x15
    80004462:	92a50513          	addi	a0,a0,-1750 # 80018d88 <bcache>
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	832080e7          	jalr	-1998(ra) # 80000c98 <release>
}
    8000446e:	60e2                	ld	ra,24(sp)
    80004470:	6442                	ld	s0,16(sp)
    80004472:	64a2                	ld	s1,8(sp)
    80004474:	6902                	ld	s2,0(sp)
    80004476:	6105                	addi	sp,sp,32
    80004478:	8082                	ret
    panic("brelse");
    8000447a:	00005517          	auipc	a0,0x5
    8000447e:	24650513          	addi	a0,a0,582 # 800096c0 <syscalls+0x108>
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>

000000008000448a <bpin>:

void
bpin(struct buf *b) {
    8000448a:	1101                	addi	sp,sp,-32
    8000448c:	ec06                	sd	ra,24(sp)
    8000448e:	e822                	sd	s0,16(sp)
    80004490:	e426                	sd	s1,8(sp)
    80004492:	1000                	addi	s0,sp,32
    80004494:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80004496:	00015517          	auipc	a0,0x15
    8000449a:	8f250513          	addi	a0,a0,-1806 # 80018d88 <bcache>
    8000449e:	ffffc097          	auipc	ra,0xffffc
    800044a2:	746080e7          	jalr	1862(ra) # 80000be4 <acquire>
  b->refcnt++;
    800044a6:	40bc                	lw	a5,64(s1)
    800044a8:	2785                	addiw	a5,a5,1
    800044aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800044ac:	00015517          	auipc	a0,0x15
    800044b0:	8dc50513          	addi	a0,a0,-1828 # 80018d88 <bcache>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	7e4080e7          	jalr	2020(ra) # 80000c98 <release>
}
    800044bc:	60e2                	ld	ra,24(sp)
    800044be:	6442                	ld	s0,16(sp)
    800044c0:	64a2                	ld	s1,8(sp)
    800044c2:	6105                	addi	sp,sp,32
    800044c4:	8082                	ret

00000000800044c6 <bunpin>:

void
bunpin(struct buf *b) {
    800044c6:	1101                	addi	sp,sp,-32
    800044c8:	ec06                	sd	ra,24(sp)
    800044ca:	e822                	sd	s0,16(sp)
    800044cc:	e426                	sd	s1,8(sp)
    800044ce:	1000                	addi	s0,sp,32
    800044d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800044d2:	00015517          	auipc	a0,0x15
    800044d6:	8b650513          	addi	a0,a0,-1866 # 80018d88 <bcache>
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	70a080e7          	jalr	1802(ra) # 80000be4 <acquire>
  b->refcnt--;
    800044e2:	40bc                	lw	a5,64(s1)
    800044e4:	37fd                	addiw	a5,a5,-1
    800044e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800044e8:	00015517          	auipc	a0,0x15
    800044ec:	8a050513          	addi	a0,a0,-1888 # 80018d88 <bcache>
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	7a8080e7          	jalr	1960(ra) # 80000c98 <release>
}
    800044f8:	60e2                	ld	ra,24(sp)
    800044fa:	6442                	ld	s0,16(sp)
    800044fc:	64a2                	ld	s1,8(sp)
    800044fe:	6105                	addi	sp,sp,32
    80004500:	8082                	ret

0000000080004502 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80004502:	1101                	addi	sp,sp,-32
    80004504:	ec06                	sd	ra,24(sp)
    80004506:	e822                	sd	s0,16(sp)
    80004508:	e426                	sd	s1,8(sp)
    8000450a:	e04a                	sd	s2,0(sp)
    8000450c:	1000                	addi	s0,sp,32
    8000450e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80004510:	00d5d59b          	srliw	a1,a1,0xd
    80004514:	0001d797          	auipc	a5,0x1d
    80004518:	f507a783          	lw	a5,-176(a5) # 80021464 <sb+0x1c>
    8000451c:	9dbd                	addw	a1,a1,a5
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	d9e080e7          	jalr	-610(ra) # 800042bc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80004526:	0074f713          	andi	a4,s1,7
    8000452a:	4785                	li	a5,1
    8000452c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80004530:	14ce                	slli	s1,s1,0x33
    80004532:	90d9                	srli	s1,s1,0x36
    80004534:	00950733          	add	a4,a0,s1
    80004538:	05874703          	lbu	a4,88(a4)
    8000453c:	00e7f6b3          	and	a3,a5,a4
    80004540:	c69d                	beqz	a3,8000456e <bfree+0x6c>
    80004542:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80004544:	94aa                	add	s1,s1,a0
    80004546:	fff7c793          	not	a5,a5
    8000454a:	8ff9                	and	a5,a5,a4
    8000454c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80004550:	00001097          	auipc	ra,0x1
    80004554:	118080e7          	jalr	280(ra) # 80005668 <log_write>
  brelse(bp);
    80004558:	854a                	mv	a0,s2
    8000455a:	00000097          	auipc	ra,0x0
    8000455e:	e92080e7          	jalr	-366(ra) # 800043ec <brelse>
}
    80004562:	60e2                	ld	ra,24(sp)
    80004564:	6442                	ld	s0,16(sp)
    80004566:	64a2                	ld	s1,8(sp)
    80004568:	6902                	ld	s2,0(sp)
    8000456a:	6105                	addi	sp,sp,32
    8000456c:	8082                	ret
    panic("freeing free block");
    8000456e:	00005517          	auipc	a0,0x5
    80004572:	15a50513          	addi	a0,a0,346 # 800096c8 <syscalls+0x110>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	fc8080e7          	jalr	-56(ra) # 8000053e <panic>

000000008000457e <balloc>:
{
    8000457e:	711d                	addi	sp,sp,-96
    80004580:	ec86                	sd	ra,88(sp)
    80004582:	e8a2                	sd	s0,80(sp)
    80004584:	e4a6                	sd	s1,72(sp)
    80004586:	e0ca                	sd	s2,64(sp)
    80004588:	fc4e                	sd	s3,56(sp)
    8000458a:	f852                	sd	s4,48(sp)
    8000458c:	f456                	sd	s5,40(sp)
    8000458e:	f05a                	sd	s6,32(sp)
    80004590:	ec5e                	sd	s7,24(sp)
    80004592:	e862                	sd	s8,16(sp)
    80004594:	e466                	sd	s9,8(sp)
    80004596:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80004598:	0001d797          	auipc	a5,0x1d
    8000459c:	eb47a783          	lw	a5,-332(a5) # 8002144c <sb+0x4>
    800045a0:	cbd1                	beqz	a5,80004634 <balloc+0xb6>
    800045a2:	8baa                	mv	s7,a0
    800045a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800045a6:	0001db17          	auipc	s6,0x1d
    800045aa:	ea2b0b13          	addi	s6,s6,-350 # 80021448 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800045ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800045b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800045b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800045b4:	6c89                	lui	s9,0x2
    800045b6:	a831                	j	800045d2 <balloc+0x54>
    brelse(bp);
    800045b8:	854a                	mv	a0,s2
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	e32080e7          	jalr	-462(ra) # 800043ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800045c2:	015c87bb          	addw	a5,s9,s5
    800045c6:	00078a9b          	sext.w	s5,a5
    800045ca:	004b2703          	lw	a4,4(s6)
    800045ce:	06eaf363          	bgeu	s5,a4,80004634 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800045d2:	41fad79b          	sraiw	a5,s5,0x1f
    800045d6:	0137d79b          	srliw	a5,a5,0x13
    800045da:	015787bb          	addw	a5,a5,s5
    800045de:	40d7d79b          	sraiw	a5,a5,0xd
    800045e2:	01cb2583          	lw	a1,28(s6)
    800045e6:	9dbd                	addw	a1,a1,a5
    800045e8:	855e                	mv	a0,s7
    800045ea:	00000097          	auipc	ra,0x0
    800045ee:	cd2080e7          	jalr	-814(ra) # 800042bc <bread>
    800045f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800045f4:	004b2503          	lw	a0,4(s6)
    800045f8:	000a849b          	sext.w	s1,s5
    800045fc:	8662                	mv	a2,s8
    800045fe:	faa4fde3          	bgeu	s1,a0,800045b8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80004602:	41f6579b          	sraiw	a5,a2,0x1f
    80004606:	01d7d69b          	srliw	a3,a5,0x1d
    8000460a:	00c6873b          	addw	a4,a3,a2
    8000460e:	00777793          	andi	a5,a4,7
    80004612:	9f95                	subw	a5,a5,a3
    80004614:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004618:	4037571b          	sraiw	a4,a4,0x3
    8000461c:	00e906b3          	add	a3,s2,a4
    80004620:	0586c683          	lbu	a3,88(a3)
    80004624:	00d7f5b3          	and	a1,a5,a3
    80004628:	cd91                	beqz	a1,80004644 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000462a:	2605                	addiw	a2,a2,1
    8000462c:	2485                	addiw	s1,s1,1
    8000462e:	fd4618e3          	bne	a2,s4,800045fe <balloc+0x80>
    80004632:	b759                	j	800045b8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80004634:	00005517          	auipc	a0,0x5
    80004638:	0ac50513          	addi	a0,a0,172 # 800096e0 <syscalls+0x128>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80004644:	974a                	add	a4,a4,s2
    80004646:	8fd5                	or	a5,a5,a3
    80004648:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000464c:	854a                	mv	a0,s2
    8000464e:	00001097          	auipc	ra,0x1
    80004652:	01a080e7          	jalr	26(ra) # 80005668 <log_write>
        brelse(bp);
    80004656:	854a                	mv	a0,s2
    80004658:	00000097          	auipc	ra,0x0
    8000465c:	d94080e7          	jalr	-620(ra) # 800043ec <brelse>
  bp = bread(dev, bno);
    80004660:	85a6                	mv	a1,s1
    80004662:	855e                	mv	a0,s7
    80004664:	00000097          	auipc	ra,0x0
    80004668:	c58080e7          	jalr	-936(ra) # 800042bc <bread>
    8000466c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000466e:	40000613          	li	a2,1024
    80004672:	4581                	li	a1,0
    80004674:	05850513          	addi	a0,a0,88
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	668080e7          	jalr	1640(ra) # 80000ce0 <memset>
  log_write(bp);
    80004680:	854a                	mv	a0,s2
    80004682:	00001097          	auipc	ra,0x1
    80004686:	fe6080e7          	jalr	-26(ra) # 80005668 <log_write>
  brelse(bp);
    8000468a:	854a                	mv	a0,s2
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	d60080e7          	jalr	-672(ra) # 800043ec <brelse>
}
    80004694:	8526                	mv	a0,s1
    80004696:	60e6                	ld	ra,88(sp)
    80004698:	6446                	ld	s0,80(sp)
    8000469a:	64a6                	ld	s1,72(sp)
    8000469c:	6906                	ld	s2,64(sp)
    8000469e:	79e2                	ld	s3,56(sp)
    800046a0:	7a42                	ld	s4,48(sp)
    800046a2:	7aa2                	ld	s5,40(sp)
    800046a4:	7b02                	ld	s6,32(sp)
    800046a6:	6be2                	ld	s7,24(sp)
    800046a8:	6c42                	ld	s8,16(sp)
    800046aa:	6ca2                	ld	s9,8(sp)
    800046ac:	6125                	addi	sp,sp,96
    800046ae:	8082                	ret

00000000800046b0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800046b0:	7179                	addi	sp,sp,-48
    800046b2:	f406                	sd	ra,40(sp)
    800046b4:	f022                	sd	s0,32(sp)
    800046b6:	ec26                	sd	s1,24(sp)
    800046b8:	e84a                	sd	s2,16(sp)
    800046ba:	e44e                	sd	s3,8(sp)
    800046bc:	e052                	sd	s4,0(sp)
    800046be:	1800                	addi	s0,sp,48
    800046c0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800046c2:	47ad                	li	a5,11
    800046c4:	04b7fe63          	bgeu	a5,a1,80004720 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800046c8:	ff45849b          	addiw	s1,a1,-12
    800046cc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800046d0:	0ff00793          	li	a5,255
    800046d4:	0ae7e363          	bltu	a5,a4,8000477a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800046d8:	08052583          	lw	a1,128(a0)
    800046dc:	c5ad                	beqz	a1,80004746 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800046de:	00092503          	lw	a0,0(s2)
    800046e2:	00000097          	auipc	ra,0x0
    800046e6:	bda080e7          	jalr	-1062(ra) # 800042bc <bread>
    800046ea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800046ec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800046f0:	02049593          	slli	a1,s1,0x20
    800046f4:	9181                	srli	a1,a1,0x20
    800046f6:	058a                	slli	a1,a1,0x2
    800046f8:	00b784b3          	add	s1,a5,a1
    800046fc:	0004a983          	lw	s3,0(s1)
    80004700:	04098d63          	beqz	s3,8000475a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80004704:	8552                	mv	a0,s4
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	ce6080e7          	jalr	-794(ra) # 800043ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000470e:	854e                	mv	a0,s3
    80004710:	70a2                	ld	ra,40(sp)
    80004712:	7402                	ld	s0,32(sp)
    80004714:	64e2                	ld	s1,24(sp)
    80004716:	6942                	ld	s2,16(sp)
    80004718:	69a2                	ld	s3,8(sp)
    8000471a:	6a02                	ld	s4,0(sp)
    8000471c:	6145                	addi	sp,sp,48
    8000471e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80004720:	02059493          	slli	s1,a1,0x20
    80004724:	9081                	srli	s1,s1,0x20
    80004726:	048a                	slli	s1,s1,0x2
    80004728:	94aa                	add	s1,s1,a0
    8000472a:	0504a983          	lw	s3,80(s1)
    8000472e:	fe0990e3          	bnez	s3,8000470e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80004732:	4108                	lw	a0,0(a0)
    80004734:	00000097          	auipc	ra,0x0
    80004738:	e4a080e7          	jalr	-438(ra) # 8000457e <balloc>
    8000473c:	0005099b          	sext.w	s3,a0
    80004740:	0534a823          	sw	s3,80(s1)
    80004744:	b7e9                	j	8000470e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80004746:	4108                	lw	a0,0(a0)
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	e36080e7          	jalr	-458(ra) # 8000457e <balloc>
    80004750:	0005059b          	sext.w	a1,a0
    80004754:	08b92023          	sw	a1,128(s2)
    80004758:	b759                	j	800046de <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000475a:	00092503          	lw	a0,0(s2)
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	e20080e7          	jalr	-480(ra) # 8000457e <balloc>
    80004766:	0005099b          	sext.w	s3,a0
    8000476a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000476e:	8552                	mv	a0,s4
    80004770:	00001097          	auipc	ra,0x1
    80004774:	ef8080e7          	jalr	-264(ra) # 80005668 <log_write>
    80004778:	b771                	j	80004704 <bmap+0x54>
  panic("bmap: out of range");
    8000477a:	00005517          	auipc	a0,0x5
    8000477e:	f7e50513          	addi	a0,a0,-130 # 800096f8 <syscalls+0x140>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	dbc080e7          	jalr	-580(ra) # 8000053e <panic>

000000008000478a <iget>:
{
    8000478a:	7179                	addi	sp,sp,-48
    8000478c:	f406                	sd	ra,40(sp)
    8000478e:	f022                	sd	s0,32(sp)
    80004790:	ec26                	sd	s1,24(sp)
    80004792:	e84a                	sd	s2,16(sp)
    80004794:	e44e                	sd	s3,8(sp)
    80004796:	e052                	sd	s4,0(sp)
    80004798:	1800                	addi	s0,sp,48
    8000479a:	89aa                	mv	s3,a0
    8000479c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000479e:	0001d517          	auipc	a0,0x1d
    800047a2:	cca50513          	addi	a0,a0,-822 # 80021468 <itable>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	43e080e7          	jalr	1086(ra) # 80000be4 <acquire>
  empty = 0;
    800047ae:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800047b0:	0001d497          	auipc	s1,0x1d
    800047b4:	cd048493          	addi	s1,s1,-816 # 80021480 <itable+0x18>
    800047b8:	0001e697          	auipc	a3,0x1e
    800047bc:	75868693          	addi	a3,a3,1880 # 80022f10 <log>
    800047c0:	a039                	j	800047ce <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800047c2:	02090b63          	beqz	s2,800047f8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800047c6:	08848493          	addi	s1,s1,136
    800047ca:	02d48a63          	beq	s1,a3,800047fe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800047ce:	449c                	lw	a5,8(s1)
    800047d0:	fef059e3          	blez	a5,800047c2 <iget+0x38>
    800047d4:	4098                	lw	a4,0(s1)
    800047d6:	ff3716e3          	bne	a4,s3,800047c2 <iget+0x38>
    800047da:	40d8                	lw	a4,4(s1)
    800047dc:	ff4713e3          	bne	a4,s4,800047c2 <iget+0x38>
      ip->ref++;
    800047e0:	2785                	addiw	a5,a5,1
    800047e2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800047e4:	0001d517          	auipc	a0,0x1d
    800047e8:	c8450513          	addi	a0,a0,-892 # 80021468 <itable>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	4ac080e7          	jalr	1196(ra) # 80000c98 <release>
      return ip;
    800047f4:	8926                	mv	s2,s1
    800047f6:	a03d                	j	80004824 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800047f8:	f7f9                	bnez	a5,800047c6 <iget+0x3c>
    800047fa:	8926                	mv	s2,s1
    800047fc:	b7e9                	j	800047c6 <iget+0x3c>
  if(empty == 0)
    800047fe:	02090c63          	beqz	s2,80004836 <iget+0xac>
  ip->dev = dev;
    80004802:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004806:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000480a:	4785                	li	a5,1
    8000480c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004810:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004814:	0001d517          	auipc	a0,0x1d
    80004818:	c5450513          	addi	a0,a0,-940 # 80021468 <itable>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	47c080e7          	jalr	1148(ra) # 80000c98 <release>
}
    80004824:	854a                	mv	a0,s2
    80004826:	70a2                	ld	ra,40(sp)
    80004828:	7402                	ld	s0,32(sp)
    8000482a:	64e2                	ld	s1,24(sp)
    8000482c:	6942                	ld	s2,16(sp)
    8000482e:	69a2                	ld	s3,8(sp)
    80004830:	6a02                	ld	s4,0(sp)
    80004832:	6145                	addi	sp,sp,48
    80004834:	8082                	ret
    panic("iget: no inodes");
    80004836:	00005517          	auipc	a0,0x5
    8000483a:	eda50513          	addi	a0,a0,-294 # 80009710 <syscalls+0x158>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>

0000000080004846 <fsinit>:
fsinit(int dev) {
    80004846:	7179                	addi	sp,sp,-48
    80004848:	f406                	sd	ra,40(sp)
    8000484a:	f022                	sd	s0,32(sp)
    8000484c:	ec26                	sd	s1,24(sp)
    8000484e:	e84a                	sd	s2,16(sp)
    80004850:	e44e                	sd	s3,8(sp)
    80004852:	1800                	addi	s0,sp,48
    80004854:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004856:	4585                	li	a1,1
    80004858:	00000097          	auipc	ra,0x0
    8000485c:	a64080e7          	jalr	-1436(ra) # 800042bc <bread>
    80004860:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004862:	0001d997          	auipc	s3,0x1d
    80004866:	be698993          	addi	s3,s3,-1050 # 80021448 <sb>
    8000486a:	02000613          	li	a2,32
    8000486e:	05850593          	addi	a1,a0,88
    80004872:	854e                	mv	a0,s3
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	4cc080e7          	jalr	1228(ra) # 80000d40 <memmove>
  brelse(bp);
    8000487c:	8526                	mv	a0,s1
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	b6e080e7          	jalr	-1170(ra) # 800043ec <brelse>
  if(sb.magic != FSMAGIC)
    80004886:	0009a703          	lw	a4,0(s3)
    8000488a:	102037b7          	lui	a5,0x10203
    8000488e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004892:	02f71263          	bne	a4,a5,800048b6 <fsinit+0x70>
  initlog(dev, &sb);
    80004896:	0001d597          	auipc	a1,0x1d
    8000489a:	bb258593          	addi	a1,a1,-1102 # 80021448 <sb>
    8000489e:	854a                	mv	a0,s2
    800048a0:	00001097          	auipc	ra,0x1
    800048a4:	b4c080e7          	jalr	-1204(ra) # 800053ec <initlog>
}
    800048a8:	70a2                	ld	ra,40(sp)
    800048aa:	7402                	ld	s0,32(sp)
    800048ac:	64e2                	ld	s1,24(sp)
    800048ae:	6942                	ld	s2,16(sp)
    800048b0:	69a2                	ld	s3,8(sp)
    800048b2:	6145                	addi	sp,sp,48
    800048b4:	8082                	ret
    panic("invalid file system");
    800048b6:	00005517          	auipc	a0,0x5
    800048ba:	e6a50513          	addi	a0,a0,-406 # 80009720 <syscalls+0x168>
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>

00000000800048c6 <iinit>:
{
    800048c6:	7179                	addi	sp,sp,-48
    800048c8:	f406                	sd	ra,40(sp)
    800048ca:	f022                	sd	s0,32(sp)
    800048cc:	ec26                	sd	s1,24(sp)
    800048ce:	e84a                	sd	s2,16(sp)
    800048d0:	e44e                	sd	s3,8(sp)
    800048d2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800048d4:	00005597          	auipc	a1,0x5
    800048d8:	e6458593          	addi	a1,a1,-412 # 80009738 <syscalls+0x180>
    800048dc:	0001d517          	auipc	a0,0x1d
    800048e0:	b8c50513          	addi	a0,a0,-1140 # 80021468 <itable>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	270080e7          	jalr	624(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800048ec:	0001d497          	auipc	s1,0x1d
    800048f0:	ba448493          	addi	s1,s1,-1116 # 80021490 <itable+0x28>
    800048f4:	0001e997          	auipc	s3,0x1e
    800048f8:	62c98993          	addi	s3,s3,1580 # 80022f20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800048fc:	00005917          	auipc	s2,0x5
    80004900:	e4490913          	addi	s2,s2,-444 # 80009740 <syscalls+0x188>
    80004904:	85ca                	mv	a1,s2
    80004906:	8526                	mv	a0,s1
    80004908:	00001097          	auipc	ra,0x1
    8000490c:	e46080e7          	jalr	-442(ra) # 8000574e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004910:	08848493          	addi	s1,s1,136
    80004914:	ff3498e3          	bne	s1,s3,80004904 <iinit+0x3e>
}
    80004918:	70a2                	ld	ra,40(sp)
    8000491a:	7402                	ld	s0,32(sp)
    8000491c:	64e2                	ld	s1,24(sp)
    8000491e:	6942                	ld	s2,16(sp)
    80004920:	69a2                	ld	s3,8(sp)
    80004922:	6145                	addi	sp,sp,48
    80004924:	8082                	ret

0000000080004926 <ialloc>:
{
    80004926:	715d                	addi	sp,sp,-80
    80004928:	e486                	sd	ra,72(sp)
    8000492a:	e0a2                	sd	s0,64(sp)
    8000492c:	fc26                	sd	s1,56(sp)
    8000492e:	f84a                	sd	s2,48(sp)
    80004930:	f44e                	sd	s3,40(sp)
    80004932:	f052                	sd	s4,32(sp)
    80004934:	ec56                	sd	s5,24(sp)
    80004936:	e85a                	sd	s6,16(sp)
    80004938:	e45e                	sd	s7,8(sp)
    8000493a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000493c:	0001d717          	auipc	a4,0x1d
    80004940:	b1872703          	lw	a4,-1256(a4) # 80021454 <sb+0xc>
    80004944:	4785                	li	a5,1
    80004946:	04e7fa63          	bgeu	a5,a4,8000499a <ialloc+0x74>
    8000494a:	8aaa                	mv	s5,a0
    8000494c:	8bae                	mv	s7,a1
    8000494e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004950:	0001da17          	auipc	s4,0x1d
    80004954:	af8a0a13          	addi	s4,s4,-1288 # 80021448 <sb>
    80004958:	00048b1b          	sext.w	s6,s1
    8000495c:	0044d593          	srli	a1,s1,0x4
    80004960:	018a2783          	lw	a5,24(s4)
    80004964:	9dbd                	addw	a1,a1,a5
    80004966:	8556                	mv	a0,s5
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	954080e7          	jalr	-1708(ra) # 800042bc <bread>
    80004970:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004972:	05850993          	addi	s3,a0,88
    80004976:	00f4f793          	andi	a5,s1,15
    8000497a:	079a                	slli	a5,a5,0x6
    8000497c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000497e:	00099783          	lh	a5,0(s3)
    80004982:	c785                	beqz	a5,800049aa <ialloc+0x84>
    brelse(bp);
    80004984:	00000097          	auipc	ra,0x0
    80004988:	a68080e7          	jalr	-1432(ra) # 800043ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000498c:	0485                	addi	s1,s1,1
    8000498e:	00ca2703          	lw	a4,12(s4)
    80004992:	0004879b          	sext.w	a5,s1
    80004996:	fce7e1e3          	bltu	a5,a4,80004958 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000499a:	00005517          	auipc	a0,0x5
    8000499e:	dae50513          	addi	a0,a0,-594 # 80009748 <syscalls+0x190>
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	b9c080e7          	jalr	-1124(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800049aa:	04000613          	li	a2,64
    800049ae:	4581                	li	a1,0
    800049b0:	854e                	mv	a0,s3
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	32e080e7          	jalr	814(ra) # 80000ce0 <memset>
      dip->type = type;
    800049ba:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800049be:	854a                	mv	a0,s2
    800049c0:	00001097          	auipc	ra,0x1
    800049c4:	ca8080e7          	jalr	-856(ra) # 80005668 <log_write>
      brelse(bp);
    800049c8:	854a                	mv	a0,s2
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	a22080e7          	jalr	-1502(ra) # 800043ec <brelse>
      return iget(dev, inum);
    800049d2:	85da                	mv	a1,s6
    800049d4:	8556                	mv	a0,s5
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	db4080e7          	jalr	-588(ra) # 8000478a <iget>
}
    800049de:	60a6                	ld	ra,72(sp)
    800049e0:	6406                	ld	s0,64(sp)
    800049e2:	74e2                	ld	s1,56(sp)
    800049e4:	7942                	ld	s2,48(sp)
    800049e6:	79a2                	ld	s3,40(sp)
    800049e8:	7a02                	ld	s4,32(sp)
    800049ea:	6ae2                	ld	s5,24(sp)
    800049ec:	6b42                	ld	s6,16(sp)
    800049ee:	6ba2                	ld	s7,8(sp)
    800049f0:	6161                	addi	sp,sp,80
    800049f2:	8082                	ret

00000000800049f4 <iupdate>:
{
    800049f4:	1101                	addi	sp,sp,-32
    800049f6:	ec06                	sd	ra,24(sp)
    800049f8:	e822                	sd	s0,16(sp)
    800049fa:	e426                	sd	s1,8(sp)
    800049fc:	e04a                	sd	s2,0(sp)
    800049fe:	1000                	addi	s0,sp,32
    80004a00:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004a02:	415c                	lw	a5,4(a0)
    80004a04:	0047d79b          	srliw	a5,a5,0x4
    80004a08:	0001d597          	auipc	a1,0x1d
    80004a0c:	a585a583          	lw	a1,-1448(a1) # 80021460 <sb+0x18>
    80004a10:	9dbd                	addw	a1,a1,a5
    80004a12:	4108                	lw	a0,0(a0)
    80004a14:	00000097          	auipc	ra,0x0
    80004a18:	8a8080e7          	jalr	-1880(ra) # 800042bc <bread>
    80004a1c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004a1e:	05850793          	addi	a5,a0,88
    80004a22:	40c8                	lw	a0,4(s1)
    80004a24:	893d                	andi	a0,a0,15
    80004a26:	051a                	slli	a0,a0,0x6
    80004a28:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004a2a:	04449703          	lh	a4,68(s1)
    80004a2e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004a32:	04649703          	lh	a4,70(s1)
    80004a36:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004a3a:	04849703          	lh	a4,72(s1)
    80004a3e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004a42:	04a49703          	lh	a4,74(s1)
    80004a46:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004a4a:	44f8                	lw	a4,76(s1)
    80004a4c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004a4e:	03400613          	li	a2,52
    80004a52:	05048593          	addi	a1,s1,80
    80004a56:	0531                	addi	a0,a0,12
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	2e8080e7          	jalr	744(ra) # 80000d40 <memmove>
  log_write(bp);
    80004a60:	854a                	mv	a0,s2
    80004a62:	00001097          	auipc	ra,0x1
    80004a66:	c06080e7          	jalr	-1018(ra) # 80005668 <log_write>
  brelse(bp);
    80004a6a:	854a                	mv	a0,s2
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	980080e7          	jalr	-1664(ra) # 800043ec <brelse>
}
    80004a74:	60e2                	ld	ra,24(sp)
    80004a76:	6442                	ld	s0,16(sp)
    80004a78:	64a2                	ld	s1,8(sp)
    80004a7a:	6902                	ld	s2,0(sp)
    80004a7c:	6105                	addi	sp,sp,32
    80004a7e:	8082                	ret

0000000080004a80 <idup>:
{
    80004a80:	1101                	addi	sp,sp,-32
    80004a82:	ec06                	sd	ra,24(sp)
    80004a84:	e822                	sd	s0,16(sp)
    80004a86:	e426                	sd	s1,8(sp)
    80004a88:	1000                	addi	s0,sp,32
    80004a8a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004a8c:	0001d517          	auipc	a0,0x1d
    80004a90:	9dc50513          	addi	a0,a0,-1572 # 80021468 <itable>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	150080e7          	jalr	336(ra) # 80000be4 <acquire>
  ip->ref++;
    80004a9c:	449c                	lw	a5,8(s1)
    80004a9e:	2785                	addiw	a5,a5,1
    80004aa0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004aa2:	0001d517          	auipc	a0,0x1d
    80004aa6:	9c650513          	addi	a0,a0,-1594 # 80021468 <itable>
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	1ee080e7          	jalr	494(ra) # 80000c98 <release>
}
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	60e2                	ld	ra,24(sp)
    80004ab6:	6442                	ld	s0,16(sp)
    80004ab8:	64a2                	ld	s1,8(sp)
    80004aba:	6105                	addi	sp,sp,32
    80004abc:	8082                	ret

0000000080004abe <ilock>:
{
    80004abe:	1101                	addi	sp,sp,-32
    80004ac0:	ec06                	sd	ra,24(sp)
    80004ac2:	e822                	sd	s0,16(sp)
    80004ac4:	e426                	sd	s1,8(sp)
    80004ac6:	e04a                	sd	s2,0(sp)
    80004ac8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004aca:	c115                	beqz	a0,80004aee <ilock+0x30>
    80004acc:	84aa                	mv	s1,a0
    80004ace:	451c                	lw	a5,8(a0)
    80004ad0:	00f05f63          	blez	a5,80004aee <ilock+0x30>
  acquiresleep(&ip->lock);
    80004ad4:	0541                	addi	a0,a0,16
    80004ad6:	00001097          	auipc	ra,0x1
    80004ada:	cb2080e7          	jalr	-846(ra) # 80005788 <acquiresleep>
  if(ip->valid == 0){
    80004ade:	40bc                	lw	a5,64(s1)
    80004ae0:	cf99                	beqz	a5,80004afe <ilock+0x40>
}
    80004ae2:	60e2                	ld	ra,24(sp)
    80004ae4:	6442                	ld	s0,16(sp)
    80004ae6:	64a2                	ld	s1,8(sp)
    80004ae8:	6902                	ld	s2,0(sp)
    80004aea:	6105                	addi	sp,sp,32
    80004aec:	8082                	ret
    panic("ilock");
    80004aee:	00005517          	auipc	a0,0x5
    80004af2:	c7250513          	addi	a0,a0,-910 # 80009760 <syscalls+0x1a8>
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	a48080e7          	jalr	-1464(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004afe:	40dc                	lw	a5,4(s1)
    80004b00:	0047d79b          	srliw	a5,a5,0x4
    80004b04:	0001d597          	auipc	a1,0x1d
    80004b08:	95c5a583          	lw	a1,-1700(a1) # 80021460 <sb+0x18>
    80004b0c:	9dbd                	addw	a1,a1,a5
    80004b0e:	4088                	lw	a0,0(s1)
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	7ac080e7          	jalr	1964(ra) # 800042bc <bread>
    80004b18:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004b1a:	05850593          	addi	a1,a0,88
    80004b1e:	40dc                	lw	a5,4(s1)
    80004b20:	8bbd                	andi	a5,a5,15
    80004b22:	079a                	slli	a5,a5,0x6
    80004b24:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004b26:	00059783          	lh	a5,0(a1)
    80004b2a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004b2e:	00259783          	lh	a5,2(a1)
    80004b32:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004b36:	00459783          	lh	a5,4(a1)
    80004b3a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004b3e:	00659783          	lh	a5,6(a1)
    80004b42:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004b46:	459c                	lw	a5,8(a1)
    80004b48:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004b4a:	03400613          	li	a2,52
    80004b4e:	05b1                	addi	a1,a1,12
    80004b50:	05048513          	addi	a0,s1,80
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	1ec080e7          	jalr	492(ra) # 80000d40 <memmove>
    brelse(bp);
    80004b5c:	854a                	mv	a0,s2
    80004b5e:	00000097          	auipc	ra,0x0
    80004b62:	88e080e7          	jalr	-1906(ra) # 800043ec <brelse>
    ip->valid = 1;
    80004b66:	4785                	li	a5,1
    80004b68:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004b6a:	04449783          	lh	a5,68(s1)
    80004b6e:	fbb5                	bnez	a5,80004ae2 <ilock+0x24>
      panic("ilock: no type");
    80004b70:	00005517          	auipc	a0,0x5
    80004b74:	bf850513          	addi	a0,a0,-1032 # 80009768 <syscalls+0x1b0>
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	9c6080e7          	jalr	-1594(ra) # 8000053e <panic>

0000000080004b80 <iunlock>:
{
    80004b80:	1101                	addi	sp,sp,-32
    80004b82:	ec06                	sd	ra,24(sp)
    80004b84:	e822                	sd	s0,16(sp)
    80004b86:	e426                	sd	s1,8(sp)
    80004b88:	e04a                	sd	s2,0(sp)
    80004b8a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004b8c:	c905                	beqz	a0,80004bbc <iunlock+0x3c>
    80004b8e:	84aa                	mv	s1,a0
    80004b90:	01050913          	addi	s2,a0,16
    80004b94:	854a                	mv	a0,s2
    80004b96:	00001097          	auipc	ra,0x1
    80004b9a:	c8c080e7          	jalr	-884(ra) # 80005822 <holdingsleep>
    80004b9e:	cd19                	beqz	a0,80004bbc <iunlock+0x3c>
    80004ba0:	449c                	lw	a5,8(s1)
    80004ba2:	00f05d63          	blez	a5,80004bbc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004ba6:	854a                	mv	a0,s2
    80004ba8:	00001097          	auipc	ra,0x1
    80004bac:	c36080e7          	jalr	-970(ra) # 800057de <releasesleep>
}
    80004bb0:	60e2                	ld	ra,24(sp)
    80004bb2:	6442                	ld	s0,16(sp)
    80004bb4:	64a2                	ld	s1,8(sp)
    80004bb6:	6902                	ld	s2,0(sp)
    80004bb8:	6105                	addi	sp,sp,32
    80004bba:	8082                	ret
    panic("iunlock");
    80004bbc:	00005517          	auipc	a0,0x5
    80004bc0:	bbc50513          	addi	a0,a0,-1092 # 80009778 <syscalls+0x1c0>
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	97a080e7          	jalr	-1670(ra) # 8000053e <panic>

0000000080004bcc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004bcc:	7179                	addi	sp,sp,-48
    80004bce:	f406                	sd	ra,40(sp)
    80004bd0:	f022                	sd	s0,32(sp)
    80004bd2:	ec26                	sd	s1,24(sp)
    80004bd4:	e84a                	sd	s2,16(sp)
    80004bd6:	e44e                	sd	s3,8(sp)
    80004bd8:	e052                	sd	s4,0(sp)
    80004bda:	1800                	addi	s0,sp,48
    80004bdc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004bde:	05050493          	addi	s1,a0,80
    80004be2:	08050913          	addi	s2,a0,128
    80004be6:	a021                	j	80004bee <itrunc+0x22>
    80004be8:	0491                	addi	s1,s1,4
    80004bea:	01248d63          	beq	s1,s2,80004c04 <itrunc+0x38>
    if(ip->addrs[i]){
    80004bee:	408c                	lw	a1,0(s1)
    80004bf0:	dde5                	beqz	a1,80004be8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004bf2:	0009a503          	lw	a0,0(s3)
    80004bf6:	00000097          	auipc	ra,0x0
    80004bfa:	90c080e7          	jalr	-1780(ra) # 80004502 <bfree>
      ip->addrs[i] = 0;
    80004bfe:	0004a023          	sw	zero,0(s1)
    80004c02:	b7dd                	j	80004be8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004c04:	0809a583          	lw	a1,128(s3)
    80004c08:	e185                	bnez	a1,80004c28 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004c0a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004c0e:	854e                	mv	a0,s3
    80004c10:	00000097          	auipc	ra,0x0
    80004c14:	de4080e7          	jalr	-540(ra) # 800049f4 <iupdate>
}
    80004c18:	70a2                	ld	ra,40(sp)
    80004c1a:	7402                	ld	s0,32(sp)
    80004c1c:	64e2                	ld	s1,24(sp)
    80004c1e:	6942                	ld	s2,16(sp)
    80004c20:	69a2                	ld	s3,8(sp)
    80004c22:	6a02                	ld	s4,0(sp)
    80004c24:	6145                	addi	sp,sp,48
    80004c26:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004c28:	0009a503          	lw	a0,0(s3)
    80004c2c:	fffff097          	auipc	ra,0xfffff
    80004c30:	690080e7          	jalr	1680(ra) # 800042bc <bread>
    80004c34:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004c36:	05850493          	addi	s1,a0,88
    80004c3a:	45850913          	addi	s2,a0,1112
    80004c3e:	a811                	j	80004c52 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004c40:	0009a503          	lw	a0,0(s3)
    80004c44:	00000097          	auipc	ra,0x0
    80004c48:	8be080e7          	jalr	-1858(ra) # 80004502 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004c4c:	0491                	addi	s1,s1,4
    80004c4e:	01248563          	beq	s1,s2,80004c58 <itrunc+0x8c>
      if(a[j])
    80004c52:	408c                	lw	a1,0(s1)
    80004c54:	dde5                	beqz	a1,80004c4c <itrunc+0x80>
    80004c56:	b7ed                	j	80004c40 <itrunc+0x74>
    brelse(bp);
    80004c58:	8552                	mv	a0,s4
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	792080e7          	jalr	1938(ra) # 800043ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004c62:	0809a583          	lw	a1,128(s3)
    80004c66:	0009a503          	lw	a0,0(s3)
    80004c6a:	00000097          	auipc	ra,0x0
    80004c6e:	898080e7          	jalr	-1896(ra) # 80004502 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004c72:	0809a023          	sw	zero,128(s3)
    80004c76:	bf51                	j	80004c0a <itrunc+0x3e>

0000000080004c78 <iput>:
{
    80004c78:	1101                	addi	sp,sp,-32
    80004c7a:	ec06                	sd	ra,24(sp)
    80004c7c:	e822                	sd	s0,16(sp)
    80004c7e:	e426                	sd	s1,8(sp)
    80004c80:	e04a                	sd	s2,0(sp)
    80004c82:	1000                	addi	s0,sp,32
    80004c84:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004c86:	0001c517          	auipc	a0,0x1c
    80004c8a:	7e250513          	addi	a0,a0,2018 # 80021468 <itable>
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	f56080e7          	jalr	-170(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004c96:	4498                	lw	a4,8(s1)
    80004c98:	4785                	li	a5,1
    80004c9a:	02f70363          	beq	a4,a5,80004cc0 <iput+0x48>
  ip->ref--;
    80004c9e:	449c                	lw	a5,8(s1)
    80004ca0:	37fd                	addiw	a5,a5,-1
    80004ca2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004ca4:	0001c517          	auipc	a0,0x1c
    80004ca8:	7c450513          	addi	a0,a0,1988 # 80021468 <itable>
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	fec080e7          	jalr	-20(ra) # 80000c98 <release>
}
    80004cb4:	60e2                	ld	ra,24(sp)
    80004cb6:	6442                	ld	s0,16(sp)
    80004cb8:	64a2                	ld	s1,8(sp)
    80004cba:	6902                	ld	s2,0(sp)
    80004cbc:	6105                	addi	sp,sp,32
    80004cbe:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004cc0:	40bc                	lw	a5,64(s1)
    80004cc2:	dff1                	beqz	a5,80004c9e <iput+0x26>
    80004cc4:	04a49783          	lh	a5,74(s1)
    80004cc8:	fbf9                	bnez	a5,80004c9e <iput+0x26>
    acquiresleep(&ip->lock);
    80004cca:	01048913          	addi	s2,s1,16
    80004cce:	854a                	mv	a0,s2
    80004cd0:	00001097          	auipc	ra,0x1
    80004cd4:	ab8080e7          	jalr	-1352(ra) # 80005788 <acquiresleep>
    release(&itable.lock);
    80004cd8:	0001c517          	auipc	a0,0x1c
    80004cdc:	79050513          	addi	a0,a0,1936 # 80021468 <itable>
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	fb8080e7          	jalr	-72(ra) # 80000c98 <release>
    itrunc(ip);
    80004ce8:	8526                	mv	a0,s1
    80004cea:	00000097          	auipc	ra,0x0
    80004cee:	ee2080e7          	jalr	-286(ra) # 80004bcc <itrunc>
    ip->type = 0;
    80004cf2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004cf6:	8526                	mv	a0,s1
    80004cf8:	00000097          	auipc	ra,0x0
    80004cfc:	cfc080e7          	jalr	-772(ra) # 800049f4 <iupdate>
    ip->valid = 0;
    80004d00:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004d04:	854a                	mv	a0,s2
    80004d06:	00001097          	auipc	ra,0x1
    80004d0a:	ad8080e7          	jalr	-1320(ra) # 800057de <releasesleep>
    acquire(&itable.lock);
    80004d0e:	0001c517          	auipc	a0,0x1c
    80004d12:	75a50513          	addi	a0,a0,1882 # 80021468 <itable>
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	ece080e7          	jalr	-306(ra) # 80000be4 <acquire>
    80004d1e:	b741                	j	80004c9e <iput+0x26>

0000000080004d20 <iunlockput>:
{
    80004d20:	1101                	addi	sp,sp,-32
    80004d22:	ec06                	sd	ra,24(sp)
    80004d24:	e822                	sd	s0,16(sp)
    80004d26:	e426                	sd	s1,8(sp)
    80004d28:	1000                	addi	s0,sp,32
    80004d2a:	84aa                	mv	s1,a0
  iunlock(ip);
    80004d2c:	00000097          	auipc	ra,0x0
    80004d30:	e54080e7          	jalr	-428(ra) # 80004b80 <iunlock>
  iput(ip);
    80004d34:	8526                	mv	a0,s1
    80004d36:	00000097          	auipc	ra,0x0
    80004d3a:	f42080e7          	jalr	-190(ra) # 80004c78 <iput>
}
    80004d3e:	60e2                	ld	ra,24(sp)
    80004d40:	6442                	ld	s0,16(sp)
    80004d42:	64a2                	ld	s1,8(sp)
    80004d44:	6105                	addi	sp,sp,32
    80004d46:	8082                	ret

0000000080004d48 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004d48:	1141                	addi	sp,sp,-16
    80004d4a:	e422                	sd	s0,8(sp)
    80004d4c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004d4e:	411c                	lw	a5,0(a0)
    80004d50:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004d52:	415c                	lw	a5,4(a0)
    80004d54:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004d56:	04451783          	lh	a5,68(a0)
    80004d5a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004d5e:	04a51783          	lh	a5,74(a0)
    80004d62:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004d66:	04c56783          	lwu	a5,76(a0)
    80004d6a:	e99c                	sd	a5,16(a1)
}
    80004d6c:	6422                	ld	s0,8(sp)
    80004d6e:	0141                	addi	sp,sp,16
    80004d70:	8082                	ret

0000000080004d72 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004d72:	457c                	lw	a5,76(a0)
    80004d74:	0ed7e963          	bltu	a5,a3,80004e66 <readi+0xf4>
{
    80004d78:	7159                	addi	sp,sp,-112
    80004d7a:	f486                	sd	ra,104(sp)
    80004d7c:	f0a2                	sd	s0,96(sp)
    80004d7e:	eca6                	sd	s1,88(sp)
    80004d80:	e8ca                	sd	s2,80(sp)
    80004d82:	e4ce                	sd	s3,72(sp)
    80004d84:	e0d2                	sd	s4,64(sp)
    80004d86:	fc56                	sd	s5,56(sp)
    80004d88:	f85a                	sd	s6,48(sp)
    80004d8a:	f45e                	sd	s7,40(sp)
    80004d8c:	f062                	sd	s8,32(sp)
    80004d8e:	ec66                	sd	s9,24(sp)
    80004d90:	e86a                	sd	s10,16(sp)
    80004d92:	e46e                	sd	s11,8(sp)
    80004d94:	1880                	addi	s0,sp,112
    80004d96:	8baa                	mv	s7,a0
    80004d98:	8c2e                	mv	s8,a1
    80004d9a:	8ab2                	mv	s5,a2
    80004d9c:	84b6                	mv	s1,a3
    80004d9e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004da0:	9f35                	addw	a4,a4,a3
    return 0;
    80004da2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004da4:	0ad76063          	bltu	a4,a3,80004e44 <readi+0xd2>
  if(off + n > ip->size)
    80004da8:	00e7f463          	bgeu	a5,a4,80004db0 <readi+0x3e>
    n = ip->size - off;
    80004dac:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004db0:	0a0b0963          	beqz	s6,80004e62 <readi+0xf0>
    80004db4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004db6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004dba:	5cfd                	li	s9,-1
    80004dbc:	a82d                	j	80004df6 <readi+0x84>
    80004dbe:	020a1d93          	slli	s11,s4,0x20
    80004dc2:	020ddd93          	srli	s11,s11,0x20
    80004dc6:	05890613          	addi	a2,s2,88
    80004dca:	86ee                	mv	a3,s11
    80004dcc:	963a                	add	a2,a2,a4
    80004dce:	85d6                	mv	a1,s5
    80004dd0:	8562                	mv	a0,s8
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	a74080e7          	jalr	-1420(ra) # 80003846 <either_copyout>
    80004dda:	05950d63          	beq	a0,s9,80004e34 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004dde:	854a                	mv	a0,s2
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	60c080e7          	jalr	1548(ra) # 800043ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004de8:	013a09bb          	addw	s3,s4,s3
    80004dec:	009a04bb          	addw	s1,s4,s1
    80004df0:	9aee                	add	s5,s5,s11
    80004df2:	0569f763          	bgeu	s3,s6,80004e40 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004df6:	000ba903          	lw	s2,0(s7)
    80004dfa:	00a4d59b          	srliw	a1,s1,0xa
    80004dfe:	855e                	mv	a0,s7
    80004e00:	00000097          	auipc	ra,0x0
    80004e04:	8b0080e7          	jalr	-1872(ra) # 800046b0 <bmap>
    80004e08:	0005059b          	sext.w	a1,a0
    80004e0c:	854a                	mv	a0,s2
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	4ae080e7          	jalr	1198(ra) # 800042bc <bread>
    80004e16:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004e18:	3ff4f713          	andi	a4,s1,1023
    80004e1c:	40ed07bb          	subw	a5,s10,a4
    80004e20:	413b06bb          	subw	a3,s6,s3
    80004e24:	8a3e                	mv	s4,a5
    80004e26:	2781                	sext.w	a5,a5
    80004e28:	0006861b          	sext.w	a2,a3
    80004e2c:	f8f679e3          	bgeu	a2,a5,80004dbe <readi+0x4c>
    80004e30:	8a36                	mv	s4,a3
    80004e32:	b771                	j	80004dbe <readi+0x4c>
      brelse(bp);
    80004e34:	854a                	mv	a0,s2
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	5b6080e7          	jalr	1462(ra) # 800043ec <brelse>
      tot = -1;
    80004e3e:	59fd                	li	s3,-1
  }
  return tot;
    80004e40:	0009851b          	sext.w	a0,s3
}
    80004e44:	70a6                	ld	ra,104(sp)
    80004e46:	7406                	ld	s0,96(sp)
    80004e48:	64e6                	ld	s1,88(sp)
    80004e4a:	6946                	ld	s2,80(sp)
    80004e4c:	69a6                	ld	s3,72(sp)
    80004e4e:	6a06                	ld	s4,64(sp)
    80004e50:	7ae2                	ld	s5,56(sp)
    80004e52:	7b42                	ld	s6,48(sp)
    80004e54:	7ba2                	ld	s7,40(sp)
    80004e56:	7c02                	ld	s8,32(sp)
    80004e58:	6ce2                	ld	s9,24(sp)
    80004e5a:	6d42                	ld	s10,16(sp)
    80004e5c:	6da2                	ld	s11,8(sp)
    80004e5e:	6165                	addi	sp,sp,112
    80004e60:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004e62:	89da                	mv	s3,s6
    80004e64:	bff1                	j	80004e40 <readi+0xce>
    return 0;
    80004e66:	4501                	li	a0,0
}
    80004e68:	8082                	ret

0000000080004e6a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004e6a:	457c                	lw	a5,76(a0)
    80004e6c:	10d7e863          	bltu	a5,a3,80004f7c <writei+0x112>
{
    80004e70:	7159                	addi	sp,sp,-112
    80004e72:	f486                	sd	ra,104(sp)
    80004e74:	f0a2                	sd	s0,96(sp)
    80004e76:	eca6                	sd	s1,88(sp)
    80004e78:	e8ca                	sd	s2,80(sp)
    80004e7a:	e4ce                	sd	s3,72(sp)
    80004e7c:	e0d2                	sd	s4,64(sp)
    80004e7e:	fc56                	sd	s5,56(sp)
    80004e80:	f85a                	sd	s6,48(sp)
    80004e82:	f45e                	sd	s7,40(sp)
    80004e84:	f062                	sd	s8,32(sp)
    80004e86:	ec66                	sd	s9,24(sp)
    80004e88:	e86a                	sd	s10,16(sp)
    80004e8a:	e46e                	sd	s11,8(sp)
    80004e8c:	1880                	addi	s0,sp,112
    80004e8e:	8b2a                	mv	s6,a0
    80004e90:	8c2e                	mv	s8,a1
    80004e92:	8ab2                	mv	s5,a2
    80004e94:	8936                	mv	s2,a3
    80004e96:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004e98:	00e687bb          	addw	a5,a3,a4
    80004e9c:	0ed7e263          	bltu	a5,a3,80004f80 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004ea0:	00043737          	lui	a4,0x43
    80004ea4:	0ef76063          	bltu	a4,a5,80004f84 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004ea8:	0c0b8863          	beqz	s7,80004f78 <writei+0x10e>
    80004eac:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004eae:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004eb2:	5cfd                	li	s9,-1
    80004eb4:	a091                	j	80004ef8 <writei+0x8e>
    80004eb6:	02099d93          	slli	s11,s3,0x20
    80004eba:	020ddd93          	srli	s11,s11,0x20
    80004ebe:	05848513          	addi	a0,s1,88
    80004ec2:	86ee                	mv	a3,s11
    80004ec4:	8656                	mv	a2,s5
    80004ec6:	85e2                	mv	a1,s8
    80004ec8:	953a                	add	a0,a0,a4
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	9d2080e7          	jalr	-1582(ra) # 8000389c <either_copyin>
    80004ed2:	07950263          	beq	a0,s9,80004f36 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	00000097          	auipc	ra,0x0
    80004edc:	790080e7          	jalr	1936(ra) # 80005668 <log_write>
    brelse(bp);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	50a080e7          	jalr	1290(ra) # 800043ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004eea:	01498a3b          	addw	s4,s3,s4
    80004eee:	0129893b          	addw	s2,s3,s2
    80004ef2:	9aee                	add	s5,s5,s11
    80004ef4:	057a7663          	bgeu	s4,s7,80004f40 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004ef8:	000b2483          	lw	s1,0(s6)
    80004efc:	00a9559b          	srliw	a1,s2,0xa
    80004f00:	855a                	mv	a0,s6
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	7ae080e7          	jalr	1966(ra) # 800046b0 <bmap>
    80004f0a:	0005059b          	sext.w	a1,a0
    80004f0e:	8526                	mv	a0,s1
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	3ac080e7          	jalr	940(ra) # 800042bc <bread>
    80004f18:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004f1a:	3ff97713          	andi	a4,s2,1023
    80004f1e:	40ed07bb          	subw	a5,s10,a4
    80004f22:	414b86bb          	subw	a3,s7,s4
    80004f26:	89be                	mv	s3,a5
    80004f28:	2781                	sext.w	a5,a5
    80004f2a:	0006861b          	sext.w	a2,a3
    80004f2e:	f8f674e3          	bgeu	a2,a5,80004eb6 <writei+0x4c>
    80004f32:	89b6                	mv	s3,a3
    80004f34:	b749                	j	80004eb6 <writei+0x4c>
      brelse(bp);
    80004f36:	8526                	mv	a0,s1
    80004f38:	fffff097          	auipc	ra,0xfffff
    80004f3c:	4b4080e7          	jalr	1204(ra) # 800043ec <brelse>
  }

  if(off > ip->size)
    80004f40:	04cb2783          	lw	a5,76(s6)
    80004f44:	0127f463          	bgeu	a5,s2,80004f4c <writei+0xe2>
    ip->size = off;
    80004f48:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004f4c:	855a                	mv	a0,s6
    80004f4e:	00000097          	auipc	ra,0x0
    80004f52:	aa6080e7          	jalr	-1370(ra) # 800049f4 <iupdate>

  return tot;
    80004f56:	000a051b          	sext.w	a0,s4
}
    80004f5a:	70a6                	ld	ra,104(sp)
    80004f5c:	7406                	ld	s0,96(sp)
    80004f5e:	64e6                	ld	s1,88(sp)
    80004f60:	6946                	ld	s2,80(sp)
    80004f62:	69a6                	ld	s3,72(sp)
    80004f64:	6a06                	ld	s4,64(sp)
    80004f66:	7ae2                	ld	s5,56(sp)
    80004f68:	7b42                	ld	s6,48(sp)
    80004f6a:	7ba2                	ld	s7,40(sp)
    80004f6c:	7c02                	ld	s8,32(sp)
    80004f6e:	6ce2                	ld	s9,24(sp)
    80004f70:	6d42                	ld	s10,16(sp)
    80004f72:	6da2                	ld	s11,8(sp)
    80004f74:	6165                	addi	sp,sp,112
    80004f76:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004f78:	8a5e                	mv	s4,s7
    80004f7a:	bfc9                	j	80004f4c <writei+0xe2>
    return -1;
    80004f7c:	557d                	li	a0,-1
}
    80004f7e:	8082                	ret
    return -1;
    80004f80:	557d                	li	a0,-1
    80004f82:	bfe1                	j	80004f5a <writei+0xf0>
    return -1;
    80004f84:	557d                	li	a0,-1
    80004f86:	bfd1                	j	80004f5a <writei+0xf0>

0000000080004f88 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004f88:	1141                	addi	sp,sp,-16
    80004f8a:	e406                	sd	ra,8(sp)
    80004f8c:	e022                	sd	s0,0(sp)
    80004f8e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004f90:	4639                	li	a2,14
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	e26080e7          	jalr	-474(ra) # 80000db8 <strncmp>
}
    80004f9a:	60a2                	ld	ra,8(sp)
    80004f9c:	6402                	ld	s0,0(sp)
    80004f9e:	0141                	addi	sp,sp,16
    80004fa0:	8082                	ret

0000000080004fa2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004fa2:	7139                	addi	sp,sp,-64
    80004fa4:	fc06                	sd	ra,56(sp)
    80004fa6:	f822                	sd	s0,48(sp)
    80004fa8:	f426                	sd	s1,40(sp)
    80004faa:	f04a                	sd	s2,32(sp)
    80004fac:	ec4e                	sd	s3,24(sp)
    80004fae:	e852                	sd	s4,16(sp)
    80004fb0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004fb2:	04451703          	lh	a4,68(a0)
    80004fb6:	4785                	li	a5,1
    80004fb8:	00f71a63          	bne	a4,a5,80004fcc <dirlookup+0x2a>
    80004fbc:	892a                	mv	s2,a0
    80004fbe:	89ae                	mv	s3,a1
    80004fc0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004fc2:	457c                	lw	a5,76(a0)
    80004fc4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004fc6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004fc8:	e79d                	bnez	a5,80004ff6 <dirlookup+0x54>
    80004fca:	a8a5                	j	80005042 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004fcc:	00004517          	auipc	a0,0x4
    80004fd0:	7b450513          	addi	a0,a0,1972 # 80009780 <syscalls+0x1c8>
    80004fd4:	ffffb097          	auipc	ra,0xffffb
    80004fd8:	56a080e7          	jalr	1386(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004fdc:	00004517          	auipc	a0,0x4
    80004fe0:	7bc50513          	addi	a0,a0,1980 # 80009798 <syscalls+0x1e0>
    80004fe4:	ffffb097          	auipc	ra,0xffffb
    80004fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004fec:	24c1                	addiw	s1,s1,16
    80004fee:	04c92783          	lw	a5,76(s2)
    80004ff2:	04f4f763          	bgeu	s1,a5,80005040 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ff6:	4741                	li	a4,16
    80004ff8:	86a6                	mv	a3,s1
    80004ffa:	fc040613          	addi	a2,s0,-64
    80004ffe:	4581                	li	a1,0
    80005000:	854a                	mv	a0,s2
    80005002:	00000097          	auipc	ra,0x0
    80005006:	d70080e7          	jalr	-656(ra) # 80004d72 <readi>
    8000500a:	47c1                	li	a5,16
    8000500c:	fcf518e3          	bne	a0,a5,80004fdc <dirlookup+0x3a>
    if(de.inum == 0)
    80005010:	fc045783          	lhu	a5,-64(s0)
    80005014:	dfe1                	beqz	a5,80004fec <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80005016:	fc240593          	addi	a1,s0,-62
    8000501a:	854e                	mv	a0,s3
    8000501c:	00000097          	auipc	ra,0x0
    80005020:	f6c080e7          	jalr	-148(ra) # 80004f88 <namecmp>
    80005024:	f561                	bnez	a0,80004fec <dirlookup+0x4a>
      if(poff)
    80005026:	000a0463          	beqz	s4,8000502e <dirlookup+0x8c>
        *poff = off;
    8000502a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000502e:	fc045583          	lhu	a1,-64(s0)
    80005032:	00092503          	lw	a0,0(s2)
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	754080e7          	jalr	1876(ra) # 8000478a <iget>
    8000503e:	a011                	j	80005042 <dirlookup+0xa0>
  return 0;
    80005040:	4501                	li	a0,0
}
    80005042:	70e2                	ld	ra,56(sp)
    80005044:	7442                	ld	s0,48(sp)
    80005046:	74a2                	ld	s1,40(sp)
    80005048:	7902                	ld	s2,32(sp)
    8000504a:	69e2                	ld	s3,24(sp)
    8000504c:	6a42                	ld	s4,16(sp)
    8000504e:	6121                	addi	sp,sp,64
    80005050:	8082                	ret

0000000080005052 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80005052:	711d                	addi	sp,sp,-96
    80005054:	ec86                	sd	ra,88(sp)
    80005056:	e8a2                	sd	s0,80(sp)
    80005058:	e4a6                	sd	s1,72(sp)
    8000505a:	e0ca                	sd	s2,64(sp)
    8000505c:	fc4e                	sd	s3,56(sp)
    8000505e:	f852                	sd	s4,48(sp)
    80005060:	f456                	sd	s5,40(sp)
    80005062:	f05a                	sd	s6,32(sp)
    80005064:	ec5e                	sd	s7,24(sp)
    80005066:	e862                	sd	s8,16(sp)
    80005068:	e466                	sd	s9,8(sp)
    8000506a:	1080                	addi	s0,sp,96
    8000506c:	84aa                	mv	s1,a0
    8000506e:	8b2e                	mv	s6,a1
    80005070:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80005072:	00054703          	lbu	a4,0(a0)
    80005076:	02f00793          	li	a5,47
    8000507a:	02f70363          	beq	a4,a5,800050a0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	b26080e7          	jalr	-1242(ra) # 80001ba4 <myproc>
    80005086:	18053503          	ld	a0,384(a0)
    8000508a:	00000097          	auipc	ra,0x0
    8000508e:	9f6080e7          	jalr	-1546(ra) # 80004a80 <idup>
    80005092:	89aa                	mv	s3,a0
  while(*path == '/')
    80005094:	02f00913          	li	s2,47
  len = path - s;
    80005098:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000509a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000509c:	4c05                	li	s8,1
    8000509e:	a865                	j	80005156 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800050a0:	4585                	li	a1,1
    800050a2:	4505                	li	a0,1
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	6e6080e7          	jalr	1766(ra) # 8000478a <iget>
    800050ac:	89aa                	mv	s3,a0
    800050ae:	b7dd                	j	80005094 <namex+0x42>
      iunlockput(ip);
    800050b0:	854e                	mv	a0,s3
    800050b2:	00000097          	auipc	ra,0x0
    800050b6:	c6e080e7          	jalr	-914(ra) # 80004d20 <iunlockput>
      return 0;
    800050ba:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800050bc:	854e                	mv	a0,s3
    800050be:	60e6                	ld	ra,88(sp)
    800050c0:	6446                	ld	s0,80(sp)
    800050c2:	64a6                	ld	s1,72(sp)
    800050c4:	6906                	ld	s2,64(sp)
    800050c6:	79e2                	ld	s3,56(sp)
    800050c8:	7a42                	ld	s4,48(sp)
    800050ca:	7aa2                	ld	s5,40(sp)
    800050cc:	7b02                	ld	s6,32(sp)
    800050ce:	6be2                	ld	s7,24(sp)
    800050d0:	6c42                	ld	s8,16(sp)
    800050d2:	6ca2                	ld	s9,8(sp)
    800050d4:	6125                	addi	sp,sp,96
    800050d6:	8082                	ret
      iunlock(ip);
    800050d8:	854e                	mv	a0,s3
    800050da:	00000097          	auipc	ra,0x0
    800050de:	aa6080e7          	jalr	-1370(ra) # 80004b80 <iunlock>
      return ip;
    800050e2:	bfe9                	j	800050bc <namex+0x6a>
      iunlockput(ip);
    800050e4:	854e                	mv	a0,s3
    800050e6:	00000097          	auipc	ra,0x0
    800050ea:	c3a080e7          	jalr	-966(ra) # 80004d20 <iunlockput>
      return 0;
    800050ee:	89d2                	mv	s3,s4
    800050f0:	b7f1                	j	800050bc <namex+0x6a>
  len = path - s;
    800050f2:	40b48633          	sub	a2,s1,a1
    800050f6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800050fa:	094cd463          	bge	s9,s4,80005182 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800050fe:	4639                	li	a2,14
    80005100:	8556                	mv	a0,s5
    80005102:	ffffc097          	auipc	ra,0xffffc
    80005106:	c3e080e7          	jalr	-962(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000510a:	0004c783          	lbu	a5,0(s1)
    8000510e:	01279763          	bne	a5,s2,8000511c <namex+0xca>
    path++;
    80005112:	0485                	addi	s1,s1,1
  while(*path == '/')
    80005114:	0004c783          	lbu	a5,0(s1)
    80005118:	ff278de3          	beq	a5,s2,80005112 <namex+0xc0>
    ilock(ip);
    8000511c:	854e                	mv	a0,s3
    8000511e:	00000097          	auipc	ra,0x0
    80005122:	9a0080e7          	jalr	-1632(ra) # 80004abe <ilock>
    if(ip->type != T_DIR){
    80005126:	04499783          	lh	a5,68(s3)
    8000512a:	f98793e3          	bne	a5,s8,800050b0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000512e:	000b0563          	beqz	s6,80005138 <namex+0xe6>
    80005132:	0004c783          	lbu	a5,0(s1)
    80005136:	d3cd                	beqz	a5,800050d8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80005138:	865e                	mv	a2,s7
    8000513a:	85d6                	mv	a1,s5
    8000513c:	854e                	mv	a0,s3
    8000513e:	00000097          	auipc	ra,0x0
    80005142:	e64080e7          	jalr	-412(ra) # 80004fa2 <dirlookup>
    80005146:	8a2a                	mv	s4,a0
    80005148:	dd51                	beqz	a0,800050e4 <namex+0x92>
    iunlockput(ip);
    8000514a:	854e                	mv	a0,s3
    8000514c:	00000097          	auipc	ra,0x0
    80005150:	bd4080e7          	jalr	-1068(ra) # 80004d20 <iunlockput>
    ip = next;
    80005154:	89d2                	mv	s3,s4
  while(*path == '/')
    80005156:	0004c783          	lbu	a5,0(s1)
    8000515a:	05279763          	bne	a5,s2,800051a8 <namex+0x156>
    path++;
    8000515e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80005160:	0004c783          	lbu	a5,0(s1)
    80005164:	ff278de3          	beq	a5,s2,8000515e <namex+0x10c>
  if(*path == 0)
    80005168:	c79d                	beqz	a5,80005196 <namex+0x144>
    path++;
    8000516a:	85a6                	mv	a1,s1
  len = path - s;
    8000516c:	8a5e                	mv	s4,s7
    8000516e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80005170:	01278963          	beq	a5,s2,80005182 <namex+0x130>
    80005174:	dfbd                	beqz	a5,800050f2 <namex+0xa0>
    path++;
    80005176:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80005178:	0004c783          	lbu	a5,0(s1)
    8000517c:	ff279ce3          	bne	a5,s2,80005174 <namex+0x122>
    80005180:	bf8d                	j	800050f2 <namex+0xa0>
    memmove(name, s, len);
    80005182:	2601                	sext.w	a2,a2
    80005184:	8556                	mv	a0,s5
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	bba080e7          	jalr	-1094(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000518e:	9a56                	add	s4,s4,s5
    80005190:	000a0023          	sb	zero,0(s4)
    80005194:	bf9d                	j	8000510a <namex+0xb8>
  if(nameiparent){
    80005196:	f20b03e3          	beqz	s6,800050bc <namex+0x6a>
    iput(ip);
    8000519a:	854e                	mv	a0,s3
    8000519c:	00000097          	auipc	ra,0x0
    800051a0:	adc080e7          	jalr	-1316(ra) # 80004c78 <iput>
    return 0;
    800051a4:	4981                	li	s3,0
    800051a6:	bf19                	j	800050bc <namex+0x6a>
  if(*path == 0)
    800051a8:	d7fd                	beqz	a5,80005196 <namex+0x144>
  while(*path != '/' && *path != 0)
    800051aa:	0004c783          	lbu	a5,0(s1)
    800051ae:	85a6                	mv	a1,s1
    800051b0:	b7d1                	j	80005174 <namex+0x122>

00000000800051b2 <dirlink>:
{
    800051b2:	7139                	addi	sp,sp,-64
    800051b4:	fc06                	sd	ra,56(sp)
    800051b6:	f822                	sd	s0,48(sp)
    800051b8:	f426                	sd	s1,40(sp)
    800051ba:	f04a                	sd	s2,32(sp)
    800051bc:	ec4e                	sd	s3,24(sp)
    800051be:	e852                	sd	s4,16(sp)
    800051c0:	0080                	addi	s0,sp,64
    800051c2:	892a                	mv	s2,a0
    800051c4:	8a2e                	mv	s4,a1
    800051c6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800051c8:	4601                	li	a2,0
    800051ca:	00000097          	auipc	ra,0x0
    800051ce:	dd8080e7          	jalr	-552(ra) # 80004fa2 <dirlookup>
    800051d2:	e93d                	bnez	a0,80005248 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800051d4:	04c92483          	lw	s1,76(s2)
    800051d8:	c49d                	beqz	s1,80005206 <dirlink+0x54>
    800051da:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800051dc:	4741                	li	a4,16
    800051de:	86a6                	mv	a3,s1
    800051e0:	fc040613          	addi	a2,s0,-64
    800051e4:	4581                	li	a1,0
    800051e6:	854a                	mv	a0,s2
    800051e8:	00000097          	auipc	ra,0x0
    800051ec:	b8a080e7          	jalr	-1142(ra) # 80004d72 <readi>
    800051f0:	47c1                	li	a5,16
    800051f2:	06f51163          	bne	a0,a5,80005254 <dirlink+0xa2>
    if(de.inum == 0)
    800051f6:	fc045783          	lhu	a5,-64(s0)
    800051fa:	c791                	beqz	a5,80005206 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800051fc:	24c1                	addiw	s1,s1,16
    800051fe:	04c92783          	lw	a5,76(s2)
    80005202:	fcf4ede3          	bltu	s1,a5,800051dc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80005206:	4639                	li	a2,14
    80005208:	85d2                	mv	a1,s4
    8000520a:	fc240513          	addi	a0,s0,-62
    8000520e:	ffffc097          	auipc	ra,0xffffc
    80005212:	be6080e7          	jalr	-1050(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80005216:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000521a:	4741                	li	a4,16
    8000521c:	86a6                	mv	a3,s1
    8000521e:	fc040613          	addi	a2,s0,-64
    80005222:	4581                	li	a1,0
    80005224:	854a                	mv	a0,s2
    80005226:	00000097          	auipc	ra,0x0
    8000522a:	c44080e7          	jalr	-956(ra) # 80004e6a <writei>
    8000522e:	872a                	mv	a4,a0
    80005230:	47c1                	li	a5,16
  return 0;
    80005232:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005234:	02f71863          	bne	a4,a5,80005264 <dirlink+0xb2>
}
    80005238:	70e2                	ld	ra,56(sp)
    8000523a:	7442                	ld	s0,48(sp)
    8000523c:	74a2                	ld	s1,40(sp)
    8000523e:	7902                	ld	s2,32(sp)
    80005240:	69e2                	ld	s3,24(sp)
    80005242:	6a42                	ld	s4,16(sp)
    80005244:	6121                	addi	sp,sp,64
    80005246:	8082                	ret
    iput(ip);
    80005248:	00000097          	auipc	ra,0x0
    8000524c:	a30080e7          	jalr	-1488(ra) # 80004c78 <iput>
    return -1;
    80005250:	557d                	li	a0,-1
    80005252:	b7dd                	j	80005238 <dirlink+0x86>
      panic("dirlink read");
    80005254:	00004517          	auipc	a0,0x4
    80005258:	55450513          	addi	a0,a0,1364 # 800097a8 <syscalls+0x1f0>
    8000525c:	ffffb097          	auipc	ra,0xffffb
    80005260:	2e2080e7          	jalr	738(ra) # 8000053e <panic>
    panic("dirlink");
    80005264:	00004517          	auipc	a0,0x4
    80005268:	65450513          	addi	a0,a0,1620 # 800098b8 <syscalls+0x300>
    8000526c:	ffffb097          	auipc	ra,0xffffb
    80005270:	2d2080e7          	jalr	722(ra) # 8000053e <panic>

0000000080005274 <namei>:

struct inode*
namei(char *path)
{
    80005274:	1101                	addi	sp,sp,-32
    80005276:	ec06                	sd	ra,24(sp)
    80005278:	e822                	sd	s0,16(sp)
    8000527a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000527c:	fe040613          	addi	a2,s0,-32
    80005280:	4581                	li	a1,0
    80005282:	00000097          	auipc	ra,0x0
    80005286:	dd0080e7          	jalr	-560(ra) # 80005052 <namex>
}
    8000528a:	60e2                	ld	ra,24(sp)
    8000528c:	6442                	ld	s0,16(sp)
    8000528e:	6105                	addi	sp,sp,32
    80005290:	8082                	ret

0000000080005292 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80005292:	1141                	addi	sp,sp,-16
    80005294:	e406                	sd	ra,8(sp)
    80005296:	e022                	sd	s0,0(sp)
    80005298:	0800                	addi	s0,sp,16
    8000529a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000529c:	4585                	li	a1,1
    8000529e:	00000097          	auipc	ra,0x0
    800052a2:	db4080e7          	jalr	-588(ra) # 80005052 <namex>
}
    800052a6:	60a2                	ld	ra,8(sp)
    800052a8:	6402                	ld	s0,0(sp)
    800052aa:	0141                	addi	sp,sp,16
    800052ac:	8082                	ret

00000000800052ae <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800052ae:	1101                	addi	sp,sp,-32
    800052b0:	ec06                	sd	ra,24(sp)
    800052b2:	e822                	sd	s0,16(sp)
    800052b4:	e426                	sd	s1,8(sp)
    800052b6:	e04a                	sd	s2,0(sp)
    800052b8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800052ba:	0001e917          	auipc	s2,0x1e
    800052be:	c5690913          	addi	s2,s2,-938 # 80022f10 <log>
    800052c2:	01892583          	lw	a1,24(s2)
    800052c6:	02892503          	lw	a0,40(s2)
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	ff2080e7          	jalr	-14(ra) # 800042bc <bread>
    800052d2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800052d4:	02c92683          	lw	a3,44(s2)
    800052d8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800052da:	02d05763          	blez	a3,80005308 <write_head+0x5a>
    800052de:	0001e797          	auipc	a5,0x1e
    800052e2:	c6278793          	addi	a5,a5,-926 # 80022f40 <log+0x30>
    800052e6:	05c50713          	addi	a4,a0,92
    800052ea:	36fd                	addiw	a3,a3,-1
    800052ec:	1682                	slli	a3,a3,0x20
    800052ee:	9281                	srli	a3,a3,0x20
    800052f0:	068a                	slli	a3,a3,0x2
    800052f2:	0001e617          	auipc	a2,0x1e
    800052f6:	c5260613          	addi	a2,a2,-942 # 80022f44 <log+0x34>
    800052fa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800052fc:	4390                	lw	a2,0(a5)
    800052fe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80005300:	0791                	addi	a5,a5,4
    80005302:	0711                	addi	a4,a4,4
    80005304:	fed79ce3          	bne	a5,a3,800052fc <write_head+0x4e>
  }
  bwrite(buf);
    80005308:	8526                	mv	a0,s1
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	0a4080e7          	jalr	164(ra) # 800043ae <bwrite>
  brelse(buf);
    80005312:	8526                	mv	a0,s1
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	0d8080e7          	jalr	216(ra) # 800043ec <brelse>
}
    8000531c:	60e2                	ld	ra,24(sp)
    8000531e:	6442                	ld	s0,16(sp)
    80005320:	64a2                	ld	s1,8(sp)
    80005322:	6902                	ld	s2,0(sp)
    80005324:	6105                	addi	sp,sp,32
    80005326:	8082                	ret

0000000080005328 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80005328:	0001e797          	auipc	a5,0x1e
    8000532c:	c147a783          	lw	a5,-1004(a5) # 80022f3c <log+0x2c>
    80005330:	0af05d63          	blez	a5,800053ea <install_trans+0xc2>
{
    80005334:	7139                	addi	sp,sp,-64
    80005336:	fc06                	sd	ra,56(sp)
    80005338:	f822                	sd	s0,48(sp)
    8000533a:	f426                	sd	s1,40(sp)
    8000533c:	f04a                	sd	s2,32(sp)
    8000533e:	ec4e                	sd	s3,24(sp)
    80005340:	e852                	sd	s4,16(sp)
    80005342:	e456                	sd	s5,8(sp)
    80005344:	e05a                	sd	s6,0(sp)
    80005346:	0080                	addi	s0,sp,64
    80005348:	8b2a                	mv	s6,a0
    8000534a:	0001ea97          	auipc	s5,0x1e
    8000534e:	bf6a8a93          	addi	s5,s5,-1034 # 80022f40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005352:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005354:	0001e997          	auipc	s3,0x1e
    80005358:	bbc98993          	addi	s3,s3,-1092 # 80022f10 <log>
    8000535c:	a035                	j	80005388 <install_trans+0x60>
      bunpin(dbuf);
    8000535e:	8526                	mv	a0,s1
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	166080e7          	jalr	358(ra) # 800044c6 <bunpin>
    brelse(lbuf);
    80005368:	854a                	mv	a0,s2
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	082080e7          	jalr	130(ra) # 800043ec <brelse>
    brelse(dbuf);
    80005372:	8526                	mv	a0,s1
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	078080e7          	jalr	120(ra) # 800043ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000537c:	2a05                	addiw	s4,s4,1
    8000537e:	0a91                	addi	s5,s5,4
    80005380:	02c9a783          	lw	a5,44(s3)
    80005384:	04fa5963          	bge	s4,a5,800053d6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005388:	0189a583          	lw	a1,24(s3)
    8000538c:	014585bb          	addw	a1,a1,s4
    80005390:	2585                	addiw	a1,a1,1
    80005392:	0289a503          	lw	a0,40(s3)
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	f26080e7          	jalr	-218(ra) # 800042bc <bread>
    8000539e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800053a0:	000aa583          	lw	a1,0(s5)
    800053a4:	0289a503          	lw	a0,40(s3)
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	f14080e7          	jalr	-236(ra) # 800042bc <bread>
    800053b0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800053b2:	40000613          	li	a2,1024
    800053b6:	05890593          	addi	a1,s2,88
    800053ba:	05850513          	addi	a0,a0,88
    800053be:	ffffc097          	auipc	ra,0xffffc
    800053c2:	982080e7          	jalr	-1662(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800053c6:	8526                	mv	a0,s1
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	fe6080e7          	jalr	-26(ra) # 800043ae <bwrite>
    if(recovering == 0)
    800053d0:	f80b1ce3          	bnez	s6,80005368 <install_trans+0x40>
    800053d4:	b769                	j	8000535e <install_trans+0x36>
}
    800053d6:	70e2                	ld	ra,56(sp)
    800053d8:	7442                	ld	s0,48(sp)
    800053da:	74a2                	ld	s1,40(sp)
    800053dc:	7902                	ld	s2,32(sp)
    800053de:	69e2                	ld	s3,24(sp)
    800053e0:	6a42                	ld	s4,16(sp)
    800053e2:	6aa2                	ld	s5,8(sp)
    800053e4:	6b02                	ld	s6,0(sp)
    800053e6:	6121                	addi	sp,sp,64
    800053e8:	8082                	ret
    800053ea:	8082                	ret

00000000800053ec <initlog>:
{
    800053ec:	7179                	addi	sp,sp,-48
    800053ee:	f406                	sd	ra,40(sp)
    800053f0:	f022                	sd	s0,32(sp)
    800053f2:	ec26                	sd	s1,24(sp)
    800053f4:	e84a                	sd	s2,16(sp)
    800053f6:	e44e                	sd	s3,8(sp)
    800053f8:	1800                	addi	s0,sp,48
    800053fa:	892a                	mv	s2,a0
    800053fc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800053fe:	0001e497          	auipc	s1,0x1e
    80005402:	b1248493          	addi	s1,s1,-1262 # 80022f10 <log>
    80005406:	00004597          	auipc	a1,0x4
    8000540a:	3b258593          	addi	a1,a1,946 # 800097b8 <syscalls+0x200>
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffb097          	auipc	ra,0xffffb
    80005414:	744080e7          	jalr	1860(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80005418:	0149a583          	lw	a1,20(s3)
    8000541c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000541e:	0109a783          	lw	a5,16(s3)
    80005422:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80005424:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80005428:	854a                	mv	a0,s2
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	e92080e7          	jalr	-366(ra) # 800042bc <bread>
  log.lh.n = lh->n;
    80005432:	4d3c                	lw	a5,88(a0)
    80005434:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80005436:	02f05563          	blez	a5,80005460 <initlog+0x74>
    8000543a:	05c50713          	addi	a4,a0,92
    8000543e:	0001e697          	auipc	a3,0x1e
    80005442:	b0268693          	addi	a3,a3,-1278 # 80022f40 <log+0x30>
    80005446:	37fd                	addiw	a5,a5,-1
    80005448:	1782                	slli	a5,a5,0x20
    8000544a:	9381                	srli	a5,a5,0x20
    8000544c:	078a                	slli	a5,a5,0x2
    8000544e:	06050613          	addi	a2,a0,96
    80005452:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80005454:	4310                	lw	a2,0(a4)
    80005456:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80005458:	0711                	addi	a4,a4,4
    8000545a:	0691                	addi	a3,a3,4
    8000545c:	fef71ce3          	bne	a4,a5,80005454 <initlog+0x68>
  brelse(buf);
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	f8c080e7          	jalr	-116(ra) # 800043ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80005468:	4505                	li	a0,1
    8000546a:	00000097          	auipc	ra,0x0
    8000546e:	ebe080e7          	jalr	-322(ra) # 80005328 <install_trans>
  log.lh.n = 0;
    80005472:	0001e797          	auipc	a5,0x1e
    80005476:	ac07a523          	sw	zero,-1334(a5) # 80022f3c <log+0x2c>
  write_head(); // clear the log
    8000547a:	00000097          	auipc	ra,0x0
    8000547e:	e34080e7          	jalr	-460(ra) # 800052ae <write_head>
}
    80005482:	70a2                	ld	ra,40(sp)
    80005484:	7402                	ld	s0,32(sp)
    80005486:	64e2                	ld	s1,24(sp)
    80005488:	6942                	ld	s2,16(sp)
    8000548a:	69a2                	ld	s3,8(sp)
    8000548c:	6145                	addi	sp,sp,48
    8000548e:	8082                	ret

0000000080005490 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80005490:	1101                	addi	sp,sp,-32
    80005492:	ec06                	sd	ra,24(sp)
    80005494:	e822                	sd	s0,16(sp)
    80005496:	e426                	sd	s1,8(sp)
    80005498:	e04a                	sd	s2,0(sp)
    8000549a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000549c:	0001e517          	auipc	a0,0x1e
    800054a0:	a7450513          	addi	a0,a0,-1420 # 80022f10 <log>
    800054a4:	ffffb097          	auipc	ra,0xffffb
    800054a8:	740080e7          	jalr	1856(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800054ac:	0001e497          	auipc	s1,0x1e
    800054b0:	a6448493          	addi	s1,s1,-1436 # 80022f10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800054b4:	4979                	li	s2,30
    800054b6:	a039                	j	800054c4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800054b8:	85a6                	mv	a1,s1
    800054ba:	8526                	mv	a0,s1
    800054bc:	ffffd097          	auipc	ra,0xffffd
    800054c0:	752080e7          	jalr	1874(ra) # 80002c0e <sleep>
    if(log.committing){
    800054c4:	50dc                	lw	a5,36(s1)
    800054c6:	fbed                	bnez	a5,800054b8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800054c8:	509c                	lw	a5,32(s1)
    800054ca:	0017871b          	addiw	a4,a5,1
    800054ce:	0007069b          	sext.w	a3,a4
    800054d2:	0027179b          	slliw	a5,a4,0x2
    800054d6:	9fb9                	addw	a5,a5,a4
    800054d8:	0017979b          	slliw	a5,a5,0x1
    800054dc:	54d8                	lw	a4,44(s1)
    800054de:	9fb9                	addw	a5,a5,a4
    800054e0:	00f95963          	bge	s2,a5,800054f2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800054e4:	85a6                	mv	a1,s1
    800054e6:	8526                	mv	a0,s1
    800054e8:	ffffd097          	auipc	ra,0xffffd
    800054ec:	726080e7          	jalr	1830(ra) # 80002c0e <sleep>
    800054f0:	bfd1                	j	800054c4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800054f2:	0001e517          	auipc	a0,0x1e
    800054f6:	a1e50513          	addi	a0,a0,-1506 # 80022f10 <log>
    800054fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800054fc:	ffffb097          	auipc	ra,0xffffb
    80005500:	79c080e7          	jalr	1948(ra) # 80000c98 <release>
      break;
    }
  }
}
    80005504:	60e2                	ld	ra,24(sp)
    80005506:	6442                	ld	s0,16(sp)
    80005508:	64a2                	ld	s1,8(sp)
    8000550a:	6902                	ld	s2,0(sp)
    8000550c:	6105                	addi	sp,sp,32
    8000550e:	8082                	ret

0000000080005510 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005510:	7139                	addi	sp,sp,-64
    80005512:	fc06                	sd	ra,56(sp)
    80005514:	f822                	sd	s0,48(sp)
    80005516:	f426                	sd	s1,40(sp)
    80005518:	f04a                	sd	s2,32(sp)
    8000551a:	ec4e                	sd	s3,24(sp)
    8000551c:	e852                	sd	s4,16(sp)
    8000551e:	e456                	sd	s5,8(sp)
    80005520:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80005522:	0001e497          	auipc	s1,0x1e
    80005526:	9ee48493          	addi	s1,s1,-1554 # 80022f10 <log>
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffb097          	auipc	ra,0xffffb
    80005530:	6b8080e7          	jalr	1720(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80005534:	509c                	lw	a5,32(s1)
    80005536:	37fd                	addiw	a5,a5,-1
    80005538:	0007891b          	sext.w	s2,a5
    8000553c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000553e:	50dc                	lw	a5,36(s1)
    80005540:	efb9                	bnez	a5,8000559e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80005542:	06091663          	bnez	s2,800055ae <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80005546:	0001e497          	auipc	s1,0x1e
    8000554a:	9ca48493          	addi	s1,s1,-1590 # 80022f10 <log>
    8000554e:	4785                	li	a5,1
    80005550:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80005552:	8526                	mv	a0,s1
    80005554:	ffffb097          	auipc	ra,0xffffb
    80005558:	744080e7          	jalr	1860(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000555c:	54dc                	lw	a5,44(s1)
    8000555e:	06f04763          	bgtz	a5,800055cc <end_op+0xbc>
    acquire(&log.lock);
    80005562:	0001e497          	auipc	s1,0x1e
    80005566:	9ae48493          	addi	s1,s1,-1618 # 80022f10 <log>
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffb097          	auipc	ra,0xffffb
    80005570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
    log.committing = 0;
    80005574:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	9ea080e7          	jalr	-1558(ra) # 80002f64 <wakeup>
    release(&log.lock);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffb097          	auipc	ra,0xffffb
    80005588:	714080e7          	jalr	1812(ra) # 80000c98 <release>
}
    8000558c:	70e2                	ld	ra,56(sp)
    8000558e:	7442                	ld	s0,48(sp)
    80005590:	74a2                	ld	s1,40(sp)
    80005592:	7902                	ld	s2,32(sp)
    80005594:	69e2                	ld	s3,24(sp)
    80005596:	6a42                	ld	s4,16(sp)
    80005598:	6aa2                	ld	s5,8(sp)
    8000559a:	6121                	addi	sp,sp,64
    8000559c:	8082                	ret
    panic("log.committing");
    8000559e:	00004517          	auipc	a0,0x4
    800055a2:	22250513          	addi	a0,a0,546 # 800097c0 <syscalls+0x208>
    800055a6:	ffffb097          	auipc	ra,0xffffb
    800055aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>
    wakeup(&log);
    800055ae:	0001e497          	auipc	s1,0x1e
    800055b2:	96248493          	addi	s1,s1,-1694 # 80022f10 <log>
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	9ac080e7          	jalr	-1620(ra) # 80002f64 <wakeup>
  release(&log.lock);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffb097          	auipc	ra,0xffffb
    800055c6:	6d6080e7          	jalr	1750(ra) # 80000c98 <release>
  if(do_commit){
    800055ca:	b7c9                	j	8000558c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800055cc:	0001ea97          	auipc	s5,0x1e
    800055d0:	974a8a93          	addi	s5,s5,-1676 # 80022f40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800055d4:	0001ea17          	auipc	s4,0x1e
    800055d8:	93ca0a13          	addi	s4,s4,-1732 # 80022f10 <log>
    800055dc:	018a2583          	lw	a1,24(s4)
    800055e0:	012585bb          	addw	a1,a1,s2
    800055e4:	2585                	addiw	a1,a1,1
    800055e6:	028a2503          	lw	a0,40(s4)
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	cd2080e7          	jalr	-814(ra) # 800042bc <bread>
    800055f2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800055f4:	000aa583          	lw	a1,0(s5)
    800055f8:	028a2503          	lw	a0,40(s4)
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	cc0080e7          	jalr	-832(ra) # 800042bc <bread>
    80005604:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005606:	40000613          	li	a2,1024
    8000560a:	05850593          	addi	a1,a0,88
    8000560e:	05848513          	addi	a0,s1,88
    80005612:	ffffb097          	auipc	ra,0xffffb
    80005616:	72e080e7          	jalr	1838(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000561a:	8526                	mv	a0,s1
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	d92080e7          	jalr	-622(ra) # 800043ae <bwrite>
    brelse(from);
    80005624:	854e                	mv	a0,s3
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	dc6080e7          	jalr	-570(ra) # 800043ec <brelse>
    brelse(to);
    8000562e:	8526                	mv	a0,s1
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	dbc080e7          	jalr	-580(ra) # 800043ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005638:	2905                	addiw	s2,s2,1
    8000563a:	0a91                	addi	s5,s5,4
    8000563c:	02ca2783          	lw	a5,44(s4)
    80005640:	f8f94ee3          	blt	s2,a5,800055dc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80005644:	00000097          	auipc	ra,0x0
    80005648:	c6a080e7          	jalr	-918(ra) # 800052ae <write_head>
    install_trans(0); // Now install writes to home locations
    8000564c:	4501                	li	a0,0
    8000564e:	00000097          	auipc	ra,0x0
    80005652:	cda080e7          	jalr	-806(ra) # 80005328 <install_trans>
    log.lh.n = 0;
    80005656:	0001e797          	auipc	a5,0x1e
    8000565a:	8e07a323          	sw	zero,-1818(a5) # 80022f3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000565e:	00000097          	auipc	ra,0x0
    80005662:	c50080e7          	jalr	-944(ra) # 800052ae <write_head>
    80005666:	bdf5                	j	80005562 <end_op+0x52>

0000000080005668 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80005668:	1101                	addi	sp,sp,-32
    8000566a:	ec06                	sd	ra,24(sp)
    8000566c:	e822                	sd	s0,16(sp)
    8000566e:	e426                	sd	s1,8(sp)
    80005670:	e04a                	sd	s2,0(sp)
    80005672:	1000                	addi	s0,sp,32
    80005674:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80005676:	0001e917          	auipc	s2,0x1e
    8000567a:	89a90913          	addi	s2,s2,-1894 # 80022f10 <log>
    8000567e:	854a                	mv	a0,s2
    80005680:	ffffb097          	auipc	ra,0xffffb
    80005684:	564080e7          	jalr	1380(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80005688:	02c92603          	lw	a2,44(s2)
    8000568c:	47f5                	li	a5,29
    8000568e:	06c7c563          	blt	a5,a2,800056f8 <log_write+0x90>
    80005692:	0001e797          	auipc	a5,0x1e
    80005696:	89a7a783          	lw	a5,-1894(a5) # 80022f2c <log+0x1c>
    8000569a:	37fd                	addiw	a5,a5,-1
    8000569c:	04f65e63          	bge	a2,a5,800056f8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800056a0:	0001e797          	auipc	a5,0x1e
    800056a4:	8907a783          	lw	a5,-1904(a5) # 80022f30 <log+0x20>
    800056a8:	06f05063          	blez	a5,80005708 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800056ac:	4781                	li	a5,0
    800056ae:	06c05563          	blez	a2,80005718 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800056b2:	44cc                	lw	a1,12(s1)
    800056b4:	0001e717          	auipc	a4,0x1e
    800056b8:	88c70713          	addi	a4,a4,-1908 # 80022f40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800056bc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800056be:	4314                	lw	a3,0(a4)
    800056c0:	04b68c63          	beq	a3,a1,80005718 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800056c4:	2785                	addiw	a5,a5,1
    800056c6:	0711                	addi	a4,a4,4
    800056c8:	fef61be3          	bne	a2,a5,800056be <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800056cc:	0621                	addi	a2,a2,8
    800056ce:	060a                	slli	a2,a2,0x2
    800056d0:	0001e797          	auipc	a5,0x1e
    800056d4:	84078793          	addi	a5,a5,-1984 # 80022f10 <log>
    800056d8:	963e                	add	a2,a2,a5
    800056da:	44dc                	lw	a5,12(s1)
    800056dc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800056de:	8526                	mv	a0,s1
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	daa080e7          	jalr	-598(ra) # 8000448a <bpin>
    log.lh.n++;
    800056e8:	0001e717          	auipc	a4,0x1e
    800056ec:	82870713          	addi	a4,a4,-2008 # 80022f10 <log>
    800056f0:	575c                	lw	a5,44(a4)
    800056f2:	2785                	addiw	a5,a5,1
    800056f4:	d75c                	sw	a5,44(a4)
    800056f6:	a835                	j	80005732 <log_write+0xca>
    panic("too big a transaction");
    800056f8:	00004517          	auipc	a0,0x4
    800056fc:	0d850513          	addi	a0,a0,216 # 800097d0 <syscalls+0x218>
    80005700:	ffffb097          	auipc	ra,0xffffb
    80005704:	e3e080e7          	jalr	-450(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80005708:	00004517          	auipc	a0,0x4
    8000570c:	0e050513          	addi	a0,a0,224 # 800097e8 <syscalls+0x230>
    80005710:	ffffb097          	auipc	ra,0xffffb
    80005714:	e2e080e7          	jalr	-466(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80005718:	00878713          	addi	a4,a5,8
    8000571c:	00271693          	slli	a3,a4,0x2
    80005720:	0001d717          	auipc	a4,0x1d
    80005724:	7f070713          	addi	a4,a4,2032 # 80022f10 <log>
    80005728:	9736                	add	a4,a4,a3
    8000572a:	44d4                	lw	a3,12(s1)
    8000572c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000572e:	faf608e3          	beq	a2,a5,800056de <log_write+0x76>
  }
  release(&log.lock);
    80005732:	0001d517          	auipc	a0,0x1d
    80005736:	7de50513          	addi	a0,a0,2014 # 80022f10 <log>
    8000573a:	ffffb097          	auipc	ra,0xffffb
    8000573e:	55e080e7          	jalr	1374(ra) # 80000c98 <release>
}
    80005742:	60e2                	ld	ra,24(sp)
    80005744:	6442                	ld	s0,16(sp)
    80005746:	64a2                	ld	s1,8(sp)
    80005748:	6902                	ld	s2,0(sp)
    8000574a:	6105                	addi	sp,sp,32
    8000574c:	8082                	ret

000000008000574e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000574e:	1101                	addi	sp,sp,-32
    80005750:	ec06                	sd	ra,24(sp)
    80005752:	e822                	sd	s0,16(sp)
    80005754:	e426                	sd	s1,8(sp)
    80005756:	e04a                	sd	s2,0(sp)
    80005758:	1000                	addi	s0,sp,32
    8000575a:	84aa                	mv	s1,a0
    8000575c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000575e:	00004597          	auipc	a1,0x4
    80005762:	0aa58593          	addi	a1,a1,170 # 80009808 <syscalls+0x250>
    80005766:	0521                	addi	a0,a0,8
    80005768:	ffffb097          	auipc	ra,0xffffb
    8000576c:	3ec080e7          	jalr	1004(ra) # 80000b54 <initlock>
  lk->name = name;
    80005770:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80005774:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005778:	0204a423          	sw	zero,40(s1)
}
    8000577c:	60e2                	ld	ra,24(sp)
    8000577e:	6442                	ld	s0,16(sp)
    80005780:	64a2                	ld	s1,8(sp)
    80005782:	6902                	ld	s2,0(sp)
    80005784:	6105                	addi	sp,sp,32
    80005786:	8082                	ret

0000000080005788 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005788:	1101                	addi	sp,sp,-32
    8000578a:	ec06                	sd	ra,24(sp)
    8000578c:	e822                	sd	s0,16(sp)
    8000578e:	e426                	sd	s1,8(sp)
    80005790:	e04a                	sd	s2,0(sp)
    80005792:	1000                	addi	s0,sp,32
    80005794:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005796:	00850913          	addi	s2,a0,8
    8000579a:	854a                	mv	a0,s2
    8000579c:	ffffb097          	auipc	ra,0xffffb
    800057a0:	448080e7          	jalr	1096(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800057a4:	409c                	lw	a5,0(s1)
    800057a6:	cb89                	beqz	a5,800057b8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800057a8:	85ca                	mv	a1,s2
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	462080e7          	jalr	1122(ra) # 80002c0e <sleep>
  while (lk->locked) {
    800057b4:	409c                	lw	a5,0(s1)
    800057b6:	fbed                	bnez	a5,800057a8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800057b8:	4785                	li	a5,1
    800057ba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800057bc:	ffffc097          	auipc	ra,0xffffc
    800057c0:	3e8080e7          	jalr	1000(ra) # 80001ba4 <myproc>
    800057c4:	591c                	lw	a5,48(a0)
    800057c6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800057c8:	854a                	mv	a0,s2
    800057ca:	ffffb097          	auipc	ra,0xffffb
    800057ce:	4ce080e7          	jalr	1230(ra) # 80000c98 <release>
}
    800057d2:	60e2                	ld	ra,24(sp)
    800057d4:	6442                	ld	s0,16(sp)
    800057d6:	64a2                	ld	s1,8(sp)
    800057d8:	6902                	ld	s2,0(sp)
    800057da:	6105                	addi	sp,sp,32
    800057dc:	8082                	ret

00000000800057de <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800057de:	1101                	addi	sp,sp,-32
    800057e0:	ec06                	sd	ra,24(sp)
    800057e2:	e822                	sd	s0,16(sp)
    800057e4:	e426                	sd	s1,8(sp)
    800057e6:	e04a                	sd	s2,0(sp)
    800057e8:	1000                	addi	s0,sp,32
    800057ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800057ec:	00850913          	addi	s2,a0,8
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffb097          	auipc	ra,0xffffb
    800057f6:	3f2080e7          	jalr	1010(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800057fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800057fe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffd097          	auipc	ra,0xffffd
    80005808:	760080e7          	jalr	1888(ra) # 80002f64 <wakeup>
  release(&lk->lk);
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffb097          	auipc	ra,0xffffb
    80005812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
}
    80005816:	60e2                	ld	ra,24(sp)
    80005818:	6442                	ld	s0,16(sp)
    8000581a:	64a2                	ld	s1,8(sp)
    8000581c:	6902                	ld	s2,0(sp)
    8000581e:	6105                	addi	sp,sp,32
    80005820:	8082                	ret

0000000080005822 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005822:	7179                	addi	sp,sp,-48
    80005824:	f406                	sd	ra,40(sp)
    80005826:	f022                	sd	s0,32(sp)
    80005828:	ec26                	sd	s1,24(sp)
    8000582a:	e84a                	sd	s2,16(sp)
    8000582c:	e44e                	sd	s3,8(sp)
    8000582e:	1800                	addi	s0,sp,48
    80005830:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005832:	00850913          	addi	s2,a0,8
    80005836:	854a                	mv	a0,s2
    80005838:	ffffb097          	auipc	ra,0xffffb
    8000583c:	3ac080e7          	jalr	940(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005840:	409c                	lw	a5,0(s1)
    80005842:	ef99                	bnez	a5,80005860 <holdingsleep+0x3e>
    80005844:	4481                	li	s1,0
  release(&lk->lk);
    80005846:	854a                	mv	a0,s2
    80005848:	ffffb097          	auipc	ra,0xffffb
    8000584c:	450080e7          	jalr	1104(ra) # 80000c98 <release>
  return r;
}
    80005850:	8526                	mv	a0,s1
    80005852:	70a2                	ld	ra,40(sp)
    80005854:	7402                	ld	s0,32(sp)
    80005856:	64e2                	ld	s1,24(sp)
    80005858:	6942                	ld	s2,16(sp)
    8000585a:	69a2                	ld	s3,8(sp)
    8000585c:	6145                	addi	sp,sp,48
    8000585e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005860:	0284a983          	lw	s3,40(s1)
    80005864:	ffffc097          	auipc	ra,0xffffc
    80005868:	340080e7          	jalr	832(ra) # 80001ba4 <myproc>
    8000586c:	5904                	lw	s1,48(a0)
    8000586e:	413484b3          	sub	s1,s1,s3
    80005872:	0014b493          	seqz	s1,s1
    80005876:	bfc1                	j	80005846 <holdingsleep+0x24>

0000000080005878 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005878:	1141                	addi	sp,sp,-16
    8000587a:	e406                	sd	ra,8(sp)
    8000587c:	e022                	sd	s0,0(sp)
    8000587e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005880:	00004597          	auipc	a1,0x4
    80005884:	f9858593          	addi	a1,a1,-104 # 80009818 <syscalls+0x260>
    80005888:	0001d517          	auipc	a0,0x1d
    8000588c:	7d050513          	addi	a0,a0,2000 # 80023058 <ftable>
    80005890:	ffffb097          	auipc	ra,0xffffb
    80005894:	2c4080e7          	jalr	708(ra) # 80000b54 <initlock>
}
    80005898:	60a2                	ld	ra,8(sp)
    8000589a:	6402                	ld	s0,0(sp)
    8000589c:	0141                	addi	sp,sp,16
    8000589e:	8082                	ret

00000000800058a0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800058a0:	1101                	addi	sp,sp,-32
    800058a2:	ec06                	sd	ra,24(sp)
    800058a4:	e822                	sd	s0,16(sp)
    800058a6:	e426                	sd	s1,8(sp)
    800058a8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800058aa:	0001d517          	auipc	a0,0x1d
    800058ae:	7ae50513          	addi	a0,a0,1966 # 80023058 <ftable>
    800058b2:	ffffb097          	auipc	ra,0xffffb
    800058b6:	332080e7          	jalr	818(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800058ba:	0001d497          	auipc	s1,0x1d
    800058be:	7b648493          	addi	s1,s1,1974 # 80023070 <ftable+0x18>
    800058c2:	0001e717          	auipc	a4,0x1e
    800058c6:	74e70713          	addi	a4,a4,1870 # 80024010 <ftable+0xfb8>
    if(f->ref == 0){
    800058ca:	40dc                	lw	a5,4(s1)
    800058cc:	cf99                	beqz	a5,800058ea <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800058ce:	02848493          	addi	s1,s1,40
    800058d2:	fee49ce3          	bne	s1,a4,800058ca <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800058d6:	0001d517          	auipc	a0,0x1d
    800058da:	78250513          	addi	a0,a0,1922 # 80023058 <ftable>
    800058de:	ffffb097          	auipc	ra,0xffffb
    800058e2:	3ba080e7          	jalr	954(ra) # 80000c98 <release>
  return 0;
    800058e6:	4481                	li	s1,0
    800058e8:	a819                	j	800058fe <filealloc+0x5e>
      f->ref = 1;
    800058ea:	4785                	li	a5,1
    800058ec:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800058ee:	0001d517          	auipc	a0,0x1d
    800058f2:	76a50513          	addi	a0,a0,1898 # 80023058 <ftable>
    800058f6:	ffffb097          	auipc	ra,0xffffb
    800058fa:	3a2080e7          	jalr	930(ra) # 80000c98 <release>
}
    800058fe:	8526                	mv	a0,s1
    80005900:	60e2                	ld	ra,24(sp)
    80005902:	6442                	ld	s0,16(sp)
    80005904:	64a2                	ld	s1,8(sp)
    80005906:	6105                	addi	sp,sp,32
    80005908:	8082                	ret

000000008000590a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000590a:	1101                	addi	sp,sp,-32
    8000590c:	ec06                	sd	ra,24(sp)
    8000590e:	e822                	sd	s0,16(sp)
    80005910:	e426                	sd	s1,8(sp)
    80005912:	1000                	addi	s0,sp,32
    80005914:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005916:	0001d517          	auipc	a0,0x1d
    8000591a:	74250513          	addi	a0,a0,1858 # 80023058 <ftable>
    8000591e:	ffffb097          	auipc	ra,0xffffb
    80005922:	2c6080e7          	jalr	710(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005926:	40dc                	lw	a5,4(s1)
    80005928:	02f05263          	blez	a5,8000594c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000592c:	2785                	addiw	a5,a5,1
    8000592e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005930:	0001d517          	auipc	a0,0x1d
    80005934:	72850513          	addi	a0,a0,1832 # 80023058 <ftable>
    80005938:	ffffb097          	auipc	ra,0xffffb
    8000593c:	360080e7          	jalr	864(ra) # 80000c98 <release>
  return f;
}
    80005940:	8526                	mv	a0,s1
    80005942:	60e2                	ld	ra,24(sp)
    80005944:	6442                	ld	s0,16(sp)
    80005946:	64a2                	ld	s1,8(sp)
    80005948:	6105                	addi	sp,sp,32
    8000594a:	8082                	ret
    panic("filedup");
    8000594c:	00004517          	auipc	a0,0x4
    80005950:	ed450513          	addi	a0,a0,-300 # 80009820 <syscalls+0x268>
    80005954:	ffffb097          	auipc	ra,0xffffb
    80005958:	bea080e7          	jalr	-1046(ra) # 8000053e <panic>

000000008000595c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000595c:	7139                	addi	sp,sp,-64
    8000595e:	fc06                	sd	ra,56(sp)
    80005960:	f822                	sd	s0,48(sp)
    80005962:	f426                	sd	s1,40(sp)
    80005964:	f04a                	sd	s2,32(sp)
    80005966:	ec4e                	sd	s3,24(sp)
    80005968:	e852                	sd	s4,16(sp)
    8000596a:	e456                	sd	s5,8(sp)
    8000596c:	0080                	addi	s0,sp,64
    8000596e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005970:	0001d517          	auipc	a0,0x1d
    80005974:	6e850513          	addi	a0,a0,1768 # 80023058 <ftable>
    80005978:	ffffb097          	auipc	ra,0xffffb
    8000597c:	26c080e7          	jalr	620(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005980:	40dc                	lw	a5,4(s1)
    80005982:	06f05163          	blez	a5,800059e4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005986:	37fd                	addiw	a5,a5,-1
    80005988:	0007871b          	sext.w	a4,a5
    8000598c:	c0dc                	sw	a5,4(s1)
    8000598e:	06e04363          	bgtz	a4,800059f4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005992:	0004a903          	lw	s2,0(s1)
    80005996:	0094ca83          	lbu	s5,9(s1)
    8000599a:	0104ba03          	ld	s4,16(s1)
    8000599e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800059a2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800059a6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800059aa:	0001d517          	auipc	a0,0x1d
    800059ae:	6ae50513          	addi	a0,a0,1710 # 80023058 <ftable>
    800059b2:	ffffb097          	auipc	ra,0xffffb
    800059b6:	2e6080e7          	jalr	742(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800059ba:	4785                	li	a5,1
    800059bc:	04f90d63          	beq	s2,a5,80005a16 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800059c0:	3979                	addiw	s2,s2,-2
    800059c2:	4785                	li	a5,1
    800059c4:	0527e063          	bltu	a5,s2,80005a04 <fileclose+0xa8>
    begin_op();
    800059c8:	00000097          	auipc	ra,0x0
    800059cc:	ac8080e7          	jalr	-1336(ra) # 80005490 <begin_op>
    iput(ff.ip);
    800059d0:	854e                	mv	a0,s3
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	2a6080e7          	jalr	678(ra) # 80004c78 <iput>
    end_op();
    800059da:	00000097          	auipc	ra,0x0
    800059de:	b36080e7          	jalr	-1226(ra) # 80005510 <end_op>
    800059e2:	a00d                	j	80005a04 <fileclose+0xa8>
    panic("fileclose");
    800059e4:	00004517          	auipc	a0,0x4
    800059e8:	e4450513          	addi	a0,a0,-444 # 80009828 <syscalls+0x270>
    800059ec:	ffffb097          	auipc	ra,0xffffb
    800059f0:	b52080e7          	jalr	-1198(ra) # 8000053e <panic>
    release(&ftable.lock);
    800059f4:	0001d517          	auipc	a0,0x1d
    800059f8:	66450513          	addi	a0,a0,1636 # 80023058 <ftable>
    800059fc:	ffffb097          	auipc	ra,0xffffb
    80005a00:	29c080e7          	jalr	668(ra) # 80000c98 <release>
  }
}
    80005a04:	70e2                	ld	ra,56(sp)
    80005a06:	7442                	ld	s0,48(sp)
    80005a08:	74a2                	ld	s1,40(sp)
    80005a0a:	7902                	ld	s2,32(sp)
    80005a0c:	69e2                	ld	s3,24(sp)
    80005a0e:	6a42                	ld	s4,16(sp)
    80005a10:	6aa2                	ld	s5,8(sp)
    80005a12:	6121                	addi	sp,sp,64
    80005a14:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005a16:	85d6                	mv	a1,s5
    80005a18:	8552                	mv	a0,s4
    80005a1a:	00000097          	auipc	ra,0x0
    80005a1e:	34c080e7          	jalr	844(ra) # 80005d66 <pipeclose>
    80005a22:	b7cd                	j	80005a04 <fileclose+0xa8>

0000000080005a24 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005a24:	715d                	addi	sp,sp,-80
    80005a26:	e486                	sd	ra,72(sp)
    80005a28:	e0a2                	sd	s0,64(sp)
    80005a2a:	fc26                	sd	s1,56(sp)
    80005a2c:	f84a                	sd	s2,48(sp)
    80005a2e:	f44e                	sd	s3,40(sp)
    80005a30:	0880                	addi	s0,sp,80
    80005a32:	84aa                	mv	s1,a0
    80005a34:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005a36:	ffffc097          	auipc	ra,0xffffc
    80005a3a:	16e080e7          	jalr	366(ra) # 80001ba4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005a3e:	409c                	lw	a5,0(s1)
    80005a40:	37f9                	addiw	a5,a5,-2
    80005a42:	4705                	li	a4,1
    80005a44:	04f76763          	bltu	a4,a5,80005a92 <filestat+0x6e>
    80005a48:	892a                	mv	s2,a0
    ilock(f->ip);
    80005a4a:	6c88                	ld	a0,24(s1)
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	072080e7          	jalr	114(ra) # 80004abe <ilock>
    stati(f->ip, &st);
    80005a54:	fb840593          	addi	a1,s0,-72
    80005a58:	6c88                	ld	a0,24(s1)
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	2ee080e7          	jalr	750(ra) # 80004d48 <stati>
    iunlock(f->ip);
    80005a62:	6c88                	ld	a0,24(s1)
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	11c080e7          	jalr	284(ra) # 80004b80 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005a6c:	46e1                	li	a3,24
    80005a6e:	fb840613          	addi	a2,s0,-72
    80005a72:	85ce                	mv	a1,s3
    80005a74:	08093503          	ld	a0,128(s2)
    80005a78:	ffffc097          	auipc	ra,0xffffc
    80005a7c:	c02080e7          	jalr	-1022(ra) # 8000167a <copyout>
    80005a80:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005a84:	60a6                	ld	ra,72(sp)
    80005a86:	6406                	ld	s0,64(sp)
    80005a88:	74e2                	ld	s1,56(sp)
    80005a8a:	7942                	ld	s2,48(sp)
    80005a8c:	79a2                	ld	s3,40(sp)
    80005a8e:	6161                	addi	sp,sp,80
    80005a90:	8082                	ret
  return -1;
    80005a92:	557d                	li	a0,-1
    80005a94:	bfc5                	j	80005a84 <filestat+0x60>

0000000080005a96 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005a96:	7179                	addi	sp,sp,-48
    80005a98:	f406                	sd	ra,40(sp)
    80005a9a:	f022                	sd	s0,32(sp)
    80005a9c:	ec26                	sd	s1,24(sp)
    80005a9e:	e84a                	sd	s2,16(sp)
    80005aa0:	e44e                	sd	s3,8(sp)
    80005aa2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005aa4:	00854783          	lbu	a5,8(a0)
    80005aa8:	c3d5                	beqz	a5,80005b4c <fileread+0xb6>
    80005aaa:	84aa                	mv	s1,a0
    80005aac:	89ae                	mv	s3,a1
    80005aae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005ab0:	411c                	lw	a5,0(a0)
    80005ab2:	4705                	li	a4,1
    80005ab4:	04e78963          	beq	a5,a4,80005b06 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005ab8:	470d                	li	a4,3
    80005aba:	04e78d63          	beq	a5,a4,80005b14 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005abe:	4709                	li	a4,2
    80005ac0:	06e79e63          	bne	a5,a4,80005b3c <fileread+0xa6>
    ilock(f->ip);
    80005ac4:	6d08                	ld	a0,24(a0)
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	ff8080e7          	jalr	-8(ra) # 80004abe <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005ace:	874a                	mv	a4,s2
    80005ad0:	5094                	lw	a3,32(s1)
    80005ad2:	864e                	mv	a2,s3
    80005ad4:	4585                	li	a1,1
    80005ad6:	6c88                	ld	a0,24(s1)
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	29a080e7          	jalr	666(ra) # 80004d72 <readi>
    80005ae0:	892a                	mv	s2,a0
    80005ae2:	00a05563          	blez	a0,80005aec <fileread+0x56>
      f->off += r;
    80005ae6:	509c                	lw	a5,32(s1)
    80005ae8:	9fa9                	addw	a5,a5,a0
    80005aea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005aec:	6c88                	ld	a0,24(s1)
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	092080e7          	jalr	146(ra) # 80004b80 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005af6:	854a                	mv	a0,s2
    80005af8:	70a2                	ld	ra,40(sp)
    80005afa:	7402                	ld	s0,32(sp)
    80005afc:	64e2                	ld	s1,24(sp)
    80005afe:	6942                	ld	s2,16(sp)
    80005b00:	69a2                	ld	s3,8(sp)
    80005b02:	6145                	addi	sp,sp,48
    80005b04:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005b06:	6908                	ld	a0,16(a0)
    80005b08:	00000097          	auipc	ra,0x0
    80005b0c:	3c8080e7          	jalr	968(ra) # 80005ed0 <piperead>
    80005b10:	892a                	mv	s2,a0
    80005b12:	b7d5                	j	80005af6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005b14:	02451783          	lh	a5,36(a0)
    80005b18:	03079693          	slli	a3,a5,0x30
    80005b1c:	92c1                	srli	a3,a3,0x30
    80005b1e:	4725                	li	a4,9
    80005b20:	02d76863          	bltu	a4,a3,80005b50 <fileread+0xba>
    80005b24:	0792                	slli	a5,a5,0x4
    80005b26:	0001d717          	auipc	a4,0x1d
    80005b2a:	49270713          	addi	a4,a4,1170 # 80022fb8 <devsw>
    80005b2e:	97ba                	add	a5,a5,a4
    80005b30:	639c                	ld	a5,0(a5)
    80005b32:	c38d                	beqz	a5,80005b54 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005b34:	4505                	li	a0,1
    80005b36:	9782                	jalr	a5
    80005b38:	892a                	mv	s2,a0
    80005b3a:	bf75                	j	80005af6 <fileread+0x60>
    panic("fileread");
    80005b3c:	00004517          	auipc	a0,0x4
    80005b40:	cfc50513          	addi	a0,a0,-772 # 80009838 <syscalls+0x280>
    80005b44:	ffffb097          	auipc	ra,0xffffb
    80005b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>
    return -1;
    80005b4c:	597d                	li	s2,-1
    80005b4e:	b765                	j	80005af6 <fileread+0x60>
      return -1;
    80005b50:	597d                	li	s2,-1
    80005b52:	b755                	j	80005af6 <fileread+0x60>
    80005b54:	597d                	li	s2,-1
    80005b56:	b745                	j	80005af6 <fileread+0x60>

0000000080005b58 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005b58:	715d                	addi	sp,sp,-80
    80005b5a:	e486                	sd	ra,72(sp)
    80005b5c:	e0a2                	sd	s0,64(sp)
    80005b5e:	fc26                	sd	s1,56(sp)
    80005b60:	f84a                	sd	s2,48(sp)
    80005b62:	f44e                	sd	s3,40(sp)
    80005b64:	f052                	sd	s4,32(sp)
    80005b66:	ec56                	sd	s5,24(sp)
    80005b68:	e85a                	sd	s6,16(sp)
    80005b6a:	e45e                	sd	s7,8(sp)
    80005b6c:	e062                	sd	s8,0(sp)
    80005b6e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005b70:	00954783          	lbu	a5,9(a0)
    80005b74:	10078663          	beqz	a5,80005c80 <filewrite+0x128>
    80005b78:	892a                	mv	s2,a0
    80005b7a:	8aae                	mv	s5,a1
    80005b7c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005b7e:	411c                	lw	a5,0(a0)
    80005b80:	4705                	li	a4,1
    80005b82:	02e78263          	beq	a5,a4,80005ba6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005b86:	470d                	li	a4,3
    80005b88:	02e78663          	beq	a5,a4,80005bb4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005b8c:	4709                	li	a4,2
    80005b8e:	0ee79163          	bne	a5,a4,80005c70 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005b92:	0ac05d63          	blez	a2,80005c4c <filewrite+0xf4>
    int i = 0;
    80005b96:	4981                	li	s3,0
    80005b98:	6b05                	lui	s6,0x1
    80005b9a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005b9e:	6b85                	lui	s7,0x1
    80005ba0:	c00b8b9b          	addiw	s7,s7,-1024
    80005ba4:	a861                	j	80005c3c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005ba6:	6908                	ld	a0,16(a0)
    80005ba8:	00000097          	auipc	ra,0x0
    80005bac:	22e080e7          	jalr	558(ra) # 80005dd6 <pipewrite>
    80005bb0:	8a2a                	mv	s4,a0
    80005bb2:	a045                	j	80005c52 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005bb4:	02451783          	lh	a5,36(a0)
    80005bb8:	03079693          	slli	a3,a5,0x30
    80005bbc:	92c1                	srli	a3,a3,0x30
    80005bbe:	4725                	li	a4,9
    80005bc0:	0cd76263          	bltu	a4,a3,80005c84 <filewrite+0x12c>
    80005bc4:	0792                	slli	a5,a5,0x4
    80005bc6:	0001d717          	auipc	a4,0x1d
    80005bca:	3f270713          	addi	a4,a4,1010 # 80022fb8 <devsw>
    80005bce:	97ba                	add	a5,a5,a4
    80005bd0:	679c                	ld	a5,8(a5)
    80005bd2:	cbdd                	beqz	a5,80005c88 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005bd4:	4505                	li	a0,1
    80005bd6:	9782                	jalr	a5
    80005bd8:	8a2a                	mv	s4,a0
    80005bda:	a8a5                	j	80005c52 <filewrite+0xfa>
    80005bdc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005be0:	00000097          	auipc	ra,0x0
    80005be4:	8b0080e7          	jalr	-1872(ra) # 80005490 <begin_op>
      ilock(f->ip);
    80005be8:	01893503          	ld	a0,24(s2)
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	ed2080e7          	jalr	-302(ra) # 80004abe <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005bf4:	8762                	mv	a4,s8
    80005bf6:	02092683          	lw	a3,32(s2)
    80005bfa:	01598633          	add	a2,s3,s5
    80005bfe:	4585                	li	a1,1
    80005c00:	01893503          	ld	a0,24(s2)
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	266080e7          	jalr	614(ra) # 80004e6a <writei>
    80005c0c:	84aa                	mv	s1,a0
    80005c0e:	00a05763          	blez	a0,80005c1c <filewrite+0xc4>
        f->off += r;
    80005c12:	02092783          	lw	a5,32(s2)
    80005c16:	9fa9                	addw	a5,a5,a0
    80005c18:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005c1c:	01893503          	ld	a0,24(s2)
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	f60080e7          	jalr	-160(ra) # 80004b80 <iunlock>
      end_op();
    80005c28:	00000097          	auipc	ra,0x0
    80005c2c:	8e8080e7          	jalr	-1816(ra) # 80005510 <end_op>

      if(r != n1){
    80005c30:	009c1f63          	bne	s8,s1,80005c4e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005c34:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005c38:	0149db63          	bge	s3,s4,80005c4e <filewrite+0xf6>
      int n1 = n - i;
    80005c3c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005c40:	84be                	mv	s1,a5
    80005c42:	2781                	sext.w	a5,a5
    80005c44:	f8fb5ce3          	bge	s6,a5,80005bdc <filewrite+0x84>
    80005c48:	84de                	mv	s1,s7
    80005c4a:	bf49                	j	80005bdc <filewrite+0x84>
    int i = 0;
    80005c4c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005c4e:	013a1f63          	bne	s4,s3,80005c6c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005c52:	8552                	mv	a0,s4
    80005c54:	60a6                	ld	ra,72(sp)
    80005c56:	6406                	ld	s0,64(sp)
    80005c58:	74e2                	ld	s1,56(sp)
    80005c5a:	7942                	ld	s2,48(sp)
    80005c5c:	79a2                	ld	s3,40(sp)
    80005c5e:	7a02                	ld	s4,32(sp)
    80005c60:	6ae2                	ld	s5,24(sp)
    80005c62:	6b42                	ld	s6,16(sp)
    80005c64:	6ba2                	ld	s7,8(sp)
    80005c66:	6c02                	ld	s8,0(sp)
    80005c68:	6161                	addi	sp,sp,80
    80005c6a:	8082                	ret
    ret = (i == n ? n : -1);
    80005c6c:	5a7d                	li	s4,-1
    80005c6e:	b7d5                	j	80005c52 <filewrite+0xfa>
    panic("filewrite");
    80005c70:	00004517          	auipc	a0,0x4
    80005c74:	bd850513          	addi	a0,a0,-1064 # 80009848 <syscalls+0x290>
    80005c78:	ffffb097          	auipc	ra,0xffffb
    80005c7c:	8c6080e7          	jalr	-1850(ra) # 8000053e <panic>
    return -1;
    80005c80:	5a7d                	li	s4,-1
    80005c82:	bfc1                	j	80005c52 <filewrite+0xfa>
      return -1;
    80005c84:	5a7d                	li	s4,-1
    80005c86:	b7f1                	j	80005c52 <filewrite+0xfa>
    80005c88:	5a7d                	li	s4,-1
    80005c8a:	b7e1                	j	80005c52 <filewrite+0xfa>

0000000080005c8c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005c8c:	7179                	addi	sp,sp,-48
    80005c8e:	f406                	sd	ra,40(sp)
    80005c90:	f022                	sd	s0,32(sp)
    80005c92:	ec26                	sd	s1,24(sp)
    80005c94:	e84a                	sd	s2,16(sp)
    80005c96:	e44e                	sd	s3,8(sp)
    80005c98:	e052                	sd	s4,0(sp)
    80005c9a:	1800                	addi	s0,sp,48
    80005c9c:	84aa                	mv	s1,a0
    80005c9e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005ca0:	0005b023          	sd	zero,0(a1)
    80005ca4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005ca8:	00000097          	auipc	ra,0x0
    80005cac:	bf8080e7          	jalr	-1032(ra) # 800058a0 <filealloc>
    80005cb0:	e088                	sd	a0,0(s1)
    80005cb2:	c551                	beqz	a0,80005d3e <pipealloc+0xb2>
    80005cb4:	00000097          	auipc	ra,0x0
    80005cb8:	bec080e7          	jalr	-1044(ra) # 800058a0 <filealloc>
    80005cbc:	00aa3023          	sd	a0,0(s4)
    80005cc0:	c92d                	beqz	a0,80005d32 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005cc2:	ffffb097          	auipc	ra,0xffffb
    80005cc6:	e32080e7          	jalr	-462(ra) # 80000af4 <kalloc>
    80005cca:	892a                	mv	s2,a0
    80005ccc:	c125                	beqz	a0,80005d2c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005cce:	4985                	li	s3,1
    80005cd0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005cd4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005cd8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005cdc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005ce0:	00004597          	auipc	a1,0x4
    80005ce4:	b7858593          	addi	a1,a1,-1160 # 80009858 <syscalls+0x2a0>
    80005ce8:	ffffb097          	auipc	ra,0xffffb
    80005cec:	e6c080e7          	jalr	-404(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005cf0:	609c                	ld	a5,0(s1)
    80005cf2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005cf6:	609c                	ld	a5,0(s1)
    80005cf8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005cfc:	609c                	ld	a5,0(s1)
    80005cfe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005d02:	609c                	ld	a5,0(s1)
    80005d04:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005d08:	000a3783          	ld	a5,0(s4)
    80005d0c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005d10:	000a3783          	ld	a5,0(s4)
    80005d14:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005d18:	000a3783          	ld	a5,0(s4)
    80005d1c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005d20:	000a3783          	ld	a5,0(s4)
    80005d24:	0127b823          	sd	s2,16(a5)
  return 0;
    80005d28:	4501                	li	a0,0
    80005d2a:	a025                	j	80005d52 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005d2c:	6088                	ld	a0,0(s1)
    80005d2e:	e501                	bnez	a0,80005d36 <pipealloc+0xaa>
    80005d30:	a039                	j	80005d3e <pipealloc+0xb2>
    80005d32:	6088                	ld	a0,0(s1)
    80005d34:	c51d                	beqz	a0,80005d62 <pipealloc+0xd6>
    fileclose(*f0);
    80005d36:	00000097          	auipc	ra,0x0
    80005d3a:	c26080e7          	jalr	-986(ra) # 8000595c <fileclose>
  if(*f1)
    80005d3e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005d42:	557d                	li	a0,-1
  if(*f1)
    80005d44:	c799                	beqz	a5,80005d52 <pipealloc+0xc6>
    fileclose(*f1);
    80005d46:	853e                	mv	a0,a5
    80005d48:	00000097          	auipc	ra,0x0
    80005d4c:	c14080e7          	jalr	-1004(ra) # 8000595c <fileclose>
  return -1;
    80005d50:	557d                	li	a0,-1
}
    80005d52:	70a2                	ld	ra,40(sp)
    80005d54:	7402                	ld	s0,32(sp)
    80005d56:	64e2                	ld	s1,24(sp)
    80005d58:	6942                	ld	s2,16(sp)
    80005d5a:	69a2                	ld	s3,8(sp)
    80005d5c:	6a02                	ld	s4,0(sp)
    80005d5e:	6145                	addi	sp,sp,48
    80005d60:	8082                	ret
  return -1;
    80005d62:	557d                	li	a0,-1
    80005d64:	b7fd                	j	80005d52 <pipealloc+0xc6>

0000000080005d66 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005d66:	1101                	addi	sp,sp,-32
    80005d68:	ec06                	sd	ra,24(sp)
    80005d6a:	e822                	sd	s0,16(sp)
    80005d6c:	e426                	sd	s1,8(sp)
    80005d6e:	e04a                	sd	s2,0(sp)
    80005d70:	1000                	addi	s0,sp,32
    80005d72:	84aa                	mv	s1,a0
    80005d74:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005d76:	ffffb097          	auipc	ra,0xffffb
    80005d7a:	e6e080e7          	jalr	-402(ra) # 80000be4 <acquire>
  if(writable){
    80005d7e:	02090d63          	beqz	s2,80005db8 <pipeclose+0x52>
    pi->writeopen = 0;
    80005d82:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005d86:	21848513          	addi	a0,s1,536
    80005d8a:	ffffd097          	auipc	ra,0xffffd
    80005d8e:	1da080e7          	jalr	474(ra) # 80002f64 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005d92:	2204b783          	ld	a5,544(s1)
    80005d96:	eb95                	bnez	a5,80005dca <pipeclose+0x64>
    release(&pi->lock);
    80005d98:	8526                	mv	a0,s1
    80005d9a:	ffffb097          	auipc	ra,0xffffb
    80005d9e:	efe080e7          	jalr	-258(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005da2:	8526                	mv	a0,s1
    80005da4:	ffffb097          	auipc	ra,0xffffb
    80005da8:	c54080e7          	jalr	-940(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6902                	ld	s2,0(sp)
    80005db4:	6105                	addi	sp,sp,32
    80005db6:	8082                	ret
    pi->readopen = 0;
    80005db8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005dbc:	21c48513          	addi	a0,s1,540
    80005dc0:	ffffd097          	auipc	ra,0xffffd
    80005dc4:	1a4080e7          	jalr	420(ra) # 80002f64 <wakeup>
    80005dc8:	b7e9                	j	80005d92 <pipeclose+0x2c>
    release(&pi->lock);
    80005dca:	8526                	mv	a0,s1
    80005dcc:	ffffb097          	auipc	ra,0xffffb
    80005dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
}
    80005dd4:	bfe1                	j	80005dac <pipeclose+0x46>

0000000080005dd6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005dd6:	7159                	addi	sp,sp,-112
    80005dd8:	f486                	sd	ra,104(sp)
    80005dda:	f0a2                	sd	s0,96(sp)
    80005ddc:	eca6                	sd	s1,88(sp)
    80005dde:	e8ca                	sd	s2,80(sp)
    80005de0:	e4ce                	sd	s3,72(sp)
    80005de2:	e0d2                	sd	s4,64(sp)
    80005de4:	fc56                	sd	s5,56(sp)
    80005de6:	f85a                	sd	s6,48(sp)
    80005de8:	f45e                	sd	s7,40(sp)
    80005dea:	f062                	sd	s8,32(sp)
    80005dec:	ec66                	sd	s9,24(sp)
    80005dee:	1880                	addi	s0,sp,112
    80005df0:	84aa                	mv	s1,a0
    80005df2:	8aae                	mv	s5,a1
    80005df4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005df6:	ffffc097          	auipc	ra,0xffffc
    80005dfa:	dae080e7          	jalr	-594(ra) # 80001ba4 <myproc>
    80005dfe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005e00:	8526                	mv	a0,s1
    80005e02:	ffffb097          	auipc	ra,0xffffb
    80005e06:	de2080e7          	jalr	-542(ra) # 80000be4 <acquire>
  while(i < n){
    80005e0a:	0d405163          	blez	s4,80005ecc <pipewrite+0xf6>
    80005e0e:	8ba6                	mv	s7,s1
  int i = 0;
    80005e10:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005e12:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005e14:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005e18:	21c48c13          	addi	s8,s1,540
    80005e1c:	a08d                	j	80005e7e <pipewrite+0xa8>
      release(&pi->lock);
    80005e1e:	8526                	mv	a0,s1
    80005e20:	ffffb097          	auipc	ra,0xffffb
    80005e24:	e78080e7          	jalr	-392(ra) # 80000c98 <release>
      return -1;
    80005e28:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005e2a:	854a                	mv	a0,s2
    80005e2c:	70a6                	ld	ra,104(sp)
    80005e2e:	7406                	ld	s0,96(sp)
    80005e30:	64e6                	ld	s1,88(sp)
    80005e32:	6946                	ld	s2,80(sp)
    80005e34:	69a6                	ld	s3,72(sp)
    80005e36:	6a06                	ld	s4,64(sp)
    80005e38:	7ae2                	ld	s5,56(sp)
    80005e3a:	7b42                	ld	s6,48(sp)
    80005e3c:	7ba2                	ld	s7,40(sp)
    80005e3e:	7c02                	ld	s8,32(sp)
    80005e40:	6ce2                	ld	s9,24(sp)
    80005e42:	6165                	addi	sp,sp,112
    80005e44:	8082                	ret
      wakeup(&pi->nread);
    80005e46:	8566                	mv	a0,s9
    80005e48:	ffffd097          	auipc	ra,0xffffd
    80005e4c:	11c080e7          	jalr	284(ra) # 80002f64 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005e50:	85de                	mv	a1,s7
    80005e52:	8562                	mv	a0,s8
    80005e54:	ffffd097          	auipc	ra,0xffffd
    80005e58:	dba080e7          	jalr	-582(ra) # 80002c0e <sleep>
    80005e5c:	a839                	j	80005e7a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005e5e:	21c4a783          	lw	a5,540(s1)
    80005e62:	0017871b          	addiw	a4,a5,1
    80005e66:	20e4ae23          	sw	a4,540(s1)
    80005e6a:	1ff7f793          	andi	a5,a5,511
    80005e6e:	97a6                	add	a5,a5,s1
    80005e70:	f9f44703          	lbu	a4,-97(s0)
    80005e74:	00e78c23          	sb	a4,24(a5)
      i++;
    80005e78:	2905                	addiw	s2,s2,1
  while(i < n){
    80005e7a:	03495d63          	bge	s2,s4,80005eb4 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005e7e:	2204a783          	lw	a5,544(s1)
    80005e82:	dfd1                	beqz	a5,80005e1e <pipewrite+0x48>
    80005e84:	0289a783          	lw	a5,40(s3)
    80005e88:	fbd9                	bnez	a5,80005e1e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005e8a:	2184a783          	lw	a5,536(s1)
    80005e8e:	21c4a703          	lw	a4,540(s1)
    80005e92:	2007879b          	addiw	a5,a5,512
    80005e96:	faf708e3          	beq	a4,a5,80005e46 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005e9a:	4685                	li	a3,1
    80005e9c:	01590633          	add	a2,s2,s5
    80005ea0:	f9f40593          	addi	a1,s0,-97
    80005ea4:	0809b503          	ld	a0,128(s3)
    80005ea8:	ffffc097          	auipc	ra,0xffffc
    80005eac:	85e080e7          	jalr	-1954(ra) # 80001706 <copyin>
    80005eb0:	fb6517e3          	bne	a0,s6,80005e5e <pipewrite+0x88>
  wakeup(&pi->nread);
    80005eb4:	21848513          	addi	a0,s1,536
    80005eb8:	ffffd097          	auipc	ra,0xffffd
    80005ebc:	0ac080e7          	jalr	172(ra) # 80002f64 <wakeup>
  release(&pi->lock);
    80005ec0:	8526                	mv	a0,s1
    80005ec2:	ffffb097          	auipc	ra,0xffffb
    80005ec6:	dd6080e7          	jalr	-554(ra) # 80000c98 <release>
  return i;
    80005eca:	b785                	j	80005e2a <pipewrite+0x54>
  int i = 0;
    80005ecc:	4901                	li	s2,0
    80005ece:	b7dd                	j	80005eb4 <pipewrite+0xde>

0000000080005ed0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005ed0:	715d                	addi	sp,sp,-80
    80005ed2:	e486                	sd	ra,72(sp)
    80005ed4:	e0a2                	sd	s0,64(sp)
    80005ed6:	fc26                	sd	s1,56(sp)
    80005ed8:	f84a                	sd	s2,48(sp)
    80005eda:	f44e                	sd	s3,40(sp)
    80005edc:	f052                	sd	s4,32(sp)
    80005ede:	ec56                	sd	s5,24(sp)
    80005ee0:	e85a                	sd	s6,16(sp)
    80005ee2:	0880                	addi	s0,sp,80
    80005ee4:	84aa                	mv	s1,a0
    80005ee6:	892e                	mv	s2,a1
    80005ee8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005eea:	ffffc097          	auipc	ra,0xffffc
    80005eee:	cba080e7          	jalr	-838(ra) # 80001ba4 <myproc>
    80005ef2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005ef4:	8b26                	mv	s6,s1
    80005ef6:	8526                	mv	a0,s1
    80005ef8:	ffffb097          	auipc	ra,0xffffb
    80005efc:	cec080e7          	jalr	-788(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f00:	2184a703          	lw	a4,536(s1)
    80005f04:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005f08:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f0c:	02f71463          	bne	a4,a5,80005f34 <piperead+0x64>
    80005f10:	2244a783          	lw	a5,548(s1)
    80005f14:	c385                	beqz	a5,80005f34 <piperead+0x64>
    if(pr->killed){
    80005f16:	028a2783          	lw	a5,40(s4)
    80005f1a:	ebc1                	bnez	a5,80005faa <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005f1c:	85da                	mv	a1,s6
    80005f1e:	854e                	mv	a0,s3
    80005f20:	ffffd097          	auipc	ra,0xffffd
    80005f24:	cee080e7          	jalr	-786(ra) # 80002c0e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f28:	2184a703          	lw	a4,536(s1)
    80005f2c:	21c4a783          	lw	a5,540(s1)
    80005f30:	fef700e3          	beq	a4,a5,80005f10 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005f34:	09505263          	blez	s5,80005fb8 <piperead+0xe8>
    80005f38:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005f3a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005f3c:	2184a783          	lw	a5,536(s1)
    80005f40:	21c4a703          	lw	a4,540(s1)
    80005f44:	02f70d63          	beq	a4,a5,80005f7e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005f48:	0017871b          	addiw	a4,a5,1
    80005f4c:	20e4ac23          	sw	a4,536(s1)
    80005f50:	1ff7f793          	andi	a5,a5,511
    80005f54:	97a6                	add	a5,a5,s1
    80005f56:	0187c783          	lbu	a5,24(a5)
    80005f5a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005f5e:	4685                	li	a3,1
    80005f60:	fbf40613          	addi	a2,s0,-65
    80005f64:	85ca                	mv	a1,s2
    80005f66:	080a3503          	ld	a0,128(s4)
    80005f6a:	ffffb097          	auipc	ra,0xffffb
    80005f6e:	710080e7          	jalr	1808(ra) # 8000167a <copyout>
    80005f72:	01650663          	beq	a0,s6,80005f7e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005f76:	2985                	addiw	s3,s3,1
    80005f78:	0905                	addi	s2,s2,1
    80005f7a:	fd3a91e3          	bne	s5,s3,80005f3c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005f7e:	21c48513          	addi	a0,s1,540
    80005f82:	ffffd097          	auipc	ra,0xffffd
    80005f86:	fe2080e7          	jalr	-30(ra) # 80002f64 <wakeup>
  release(&pi->lock);
    80005f8a:	8526                	mv	a0,s1
    80005f8c:	ffffb097          	auipc	ra,0xffffb
    80005f90:	d0c080e7          	jalr	-756(ra) # 80000c98 <release>
  return i;
}
    80005f94:	854e                	mv	a0,s3
    80005f96:	60a6                	ld	ra,72(sp)
    80005f98:	6406                	ld	s0,64(sp)
    80005f9a:	74e2                	ld	s1,56(sp)
    80005f9c:	7942                	ld	s2,48(sp)
    80005f9e:	79a2                	ld	s3,40(sp)
    80005fa0:	7a02                	ld	s4,32(sp)
    80005fa2:	6ae2                	ld	s5,24(sp)
    80005fa4:	6b42                	ld	s6,16(sp)
    80005fa6:	6161                	addi	sp,sp,80
    80005fa8:	8082                	ret
      release(&pi->lock);
    80005faa:	8526                	mv	a0,s1
    80005fac:	ffffb097          	auipc	ra,0xffffb
    80005fb0:	cec080e7          	jalr	-788(ra) # 80000c98 <release>
      return -1;
    80005fb4:	59fd                	li	s3,-1
    80005fb6:	bff9                	j	80005f94 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005fb8:	4981                	li	s3,0
    80005fba:	b7d1                	j	80005f7e <piperead+0xae>

0000000080005fbc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005fbc:	df010113          	addi	sp,sp,-528
    80005fc0:	20113423          	sd	ra,520(sp)
    80005fc4:	20813023          	sd	s0,512(sp)
    80005fc8:	ffa6                	sd	s1,504(sp)
    80005fca:	fbca                	sd	s2,496(sp)
    80005fcc:	f7ce                	sd	s3,488(sp)
    80005fce:	f3d2                	sd	s4,480(sp)
    80005fd0:	efd6                	sd	s5,472(sp)
    80005fd2:	ebda                	sd	s6,464(sp)
    80005fd4:	e7de                	sd	s7,456(sp)
    80005fd6:	e3e2                	sd	s8,448(sp)
    80005fd8:	ff66                	sd	s9,440(sp)
    80005fda:	fb6a                	sd	s10,432(sp)
    80005fdc:	f76e                	sd	s11,424(sp)
    80005fde:	0c00                	addi	s0,sp,528
    80005fe0:	84aa                	mv	s1,a0
    80005fe2:	dea43c23          	sd	a0,-520(s0)
    80005fe6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005fea:	ffffc097          	auipc	ra,0xffffc
    80005fee:	bba080e7          	jalr	-1094(ra) # 80001ba4 <myproc>
    80005ff2:	892a                	mv	s2,a0

  begin_op();
    80005ff4:	fffff097          	auipc	ra,0xfffff
    80005ff8:	49c080e7          	jalr	1180(ra) # 80005490 <begin_op>

  if((ip = namei(path)) == 0){
    80005ffc:	8526                	mv	a0,s1
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	276080e7          	jalr	630(ra) # 80005274 <namei>
    80006006:	c92d                	beqz	a0,80006078 <exec+0xbc>
    80006008:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	ab4080e7          	jalr	-1356(ra) # 80004abe <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80006012:	04000713          	li	a4,64
    80006016:	4681                	li	a3,0
    80006018:	e5040613          	addi	a2,s0,-432
    8000601c:	4581                	li	a1,0
    8000601e:	8526                	mv	a0,s1
    80006020:	fffff097          	auipc	ra,0xfffff
    80006024:	d52080e7          	jalr	-686(ra) # 80004d72 <readi>
    80006028:	04000793          	li	a5,64
    8000602c:	00f51a63          	bne	a0,a5,80006040 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80006030:	e5042703          	lw	a4,-432(s0)
    80006034:	464c47b7          	lui	a5,0x464c4
    80006038:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000603c:	04f70463          	beq	a4,a5,80006084 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80006040:	8526                	mv	a0,s1
    80006042:	fffff097          	auipc	ra,0xfffff
    80006046:	cde080e7          	jalr	-802(ra) # 80004d20 <iunlockput>
    end_op();
    8000604a:	fffff097          	auipc	ra,0xfffff
    8000604e:	4c6080e7          	jalr	1222(ra) # 80005510 <end_op>
  }
  return -1;
    80006052:	557d                	li	a0,-1
}
    80006054:	20813083          	ld	ra,520(sp)
    80006058:	20013403          	ld	s0,512(sp)
    8000605c:	74fe                	ld	s1,504(sp)
    8000605e:	795e                	ld	s2,496(sp)
    80006060:	79be                	ld	s3,488(sp)
    80006062:	7a1e                	ld	s4,480(sp)
    80006064:	6afe                	ld	s5,472(sp)
    80006066:	6b5e                	ld	s6,464(sp)
    80006068:	6bbe                	ld	s7,456(sp)
    8000606a:	6c1e                	ld	s8,448(sp)
    8000606c:	7cfa                	ld	s9,440(sp)
    8000606e:	7d5a                	ld	s10,432(sp)
    80006070:	7dba                	ld	s11,424(sp)
    80006072:	21010113          	addi	sp,sp,528
    80006076:	8082                	ret
    end_op();
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	498080e7          	jalr	1176(ra) # 80005510 <end_op>
    return -1;
    80006080:	557d                	li	a0,-1
    80006082:	bfc9                	j	80006054 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80006084:	854a                	mv	a0,s2
    80006086:	ffffc097          	auipc	ra,0xffffc
    8000608a:	be6080e7          	jalr	-1050(ra) # 80001c6c <proc_pagetable>
    8000608e:	8baa                	mv	s7,a0
    80006090:	d945                	beqz	a0,80006040 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80006092:	e7042983          	lw	s3,-400(s0)
    80006096:	e8845783          	lhu	a5,-376(s0)
    8000609a:	c7ad                	beqz	a5,80006104 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000609c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000609e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800060a0:	6c85                	lui	s9,0x1
    800060a2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800060a6:	def43823          	sd	a5,-528(s0)
    800060aa:	a42d                	j	800062d4 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800060ac:	00003517          	auipc	a0,0x3
    800060b0:	7b450513          	addi	a0,a0,1972 # 80009860 <syscalls+0x2a8>
    800060b4:	ffffa097          	auipc	ra,0xffffa
    800060b8:	48a080e7          	jalr	1162(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800060bc:	8756                	mv	a4,s5
    800060be:	012d86bb          	addw	a3,s11,s2
    800060c2:	4581                	li	a1,0
    800060c4:	8526                	mv	a0,s1
    800060c6:	fffff097          	auipc	ra,0xfffff
    800060ca:	cac080e7          	jalr	-852(ra) # 80004d72 <readi>
    800060ce:	2501                	sext.w	a0,a0
    800060d0:	1aaa9963          	bne	s5,a0,80006282 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800060d4:	6785                	lui	a5,0x1
    800060d6:	0127893b          	addw	s2,a5,s2
    800060da:	77fd                	lui	a5,0xfffff
    800060dc:	01478a3b          	addw	s4,a5,s4
    800060e0:	1f897163          	bgeu	s2,s8,800062c2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800060e4:	02091593          	slli	a1,s2,0x20
    800060e8:	9181                	srli	a1,a1,0x20
    800060ea:	95ea                	add	a1,a1,s10
    800060ec:	855e                	mv	a0,s7
    800060ee:	ffffb097          	auipc	ra,0xffffb
    800060f2:	f88080e7          	jalr	-120(ra) # 80001076 <walkaddr>
    800060f6:	862a                	mv	a2,a0
    if(pa == 0)
    800060f8:	d955                	beqz	a0,800060ac <exec+0xf0>
      n = PGSIZE;
    800060fa:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800060fc:	fd9a70e3          	bgeu	s4,s9,800060bc <exec+0x100>
      n = sz - i;
    80006100:	8ad2                	mv	s5,s4
    80006102:	bf6d                	j	800060bc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80006104:	4901                	li	s2,0
  iunlockput(ip);
    80006106:	8526                	mv	a0,s1
    80006108:	fffff097          	auipc	ra,0xfffff
    8000610c:	c18080e7          	jalr	-1000(ra) # 80004d20 <iunlockput>
  end_op();
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	400080e7          	jalr	1024(ra) # 80005510 <end_op>
  p = myproc();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	a8c080e7          	jalr	-1396(ra) # 80001ba4 <myproc>
    80006120:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80006122:	07853d03          	ld	s10,120(a0)
  sz = PGROUNDUP(sz);
    80006126:	6785                	lui	a5,0x1
    80006128:	17fd                	addi	a5,a5,-1
    8000612a:	993e                	add	s2,s2,a5
    8000612c:	757d                	lui	a0,0xfffff
    8000612e:	00a977b3          	and	a5,s2,a0
    80006132:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80006136:	6609                	lui	a2,0x2
    80006138:	963e                	add	a2,a2,a5
    8000613a:	85be                	mv	a1,a5
    8000613c:	855e                	mv	a0,s7
    8000613e:	ffffb097          	auipc	ra,0xffffb
    80006142:	2ec080e7          	jalr	748(ra) # 8000142a <uvmalloc>
    80006146:	8b2a                	mv	s6,a0
  ip = 0;
    80006148:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000614a:	12050c63          	beqz	a0,80006282 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000614e:	75f9                	lui	a1,0xffffe
    80006150:	95aa                	add	a1,a1,a0
    80006152:	855e                	mv	a0,s7
    80006154:	ffffb097          	auipc	ra,0xffffb
    80006158:	4f4080e7          	jalr	1268(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    8000615c:	7c7d                	lui	s8,0xfffff
    8000615e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80006160:	e0043783          	ld	a5,-512(s0)
    80006164:	6388                	ld	a0,0(a5)
    80006166:	c535                	beqz	a0,800061d2 <exec+0x216>
    80006168:	e9040993          	addi	s3,s0,-368
    8000616c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80006170:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80006172:	ffffb097          	auipc	ra,0xffffb
    80006176:	cf2080e7          	jalr	-782(ra) # 80000e64 <strlen>
    8000617a:	2505                	addiw	a0,a0,1
    8000617c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80006180:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80006184:	13896363          	bltu	s2,s8,800062aa <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80006188:	e0043d83          	ld	s11,-512(s0)
    8000618c:	000dba03          	ld	s4,0(s11)
    80006190:	8552                	mv	a0,s4
    80006192:	ffffb097          	auipc	ra,0xffffb
    80006196:	cd2080e7          	jalr	-814(ra) # 80000e64 <strlen>
    8000619a:	0015069b          	addiw	a3,a0,1
    8000619e:	8652                	mv	a2,s4
    800061a0:	85ca                	mv	a1,s2
    800061a2:	855e                	mv	a0,s7
    800061a4:	ffffb097          	auipc	ra,0xffffb
    800061a8:	4d6080e7          	jalr	1238(ra) # 8000167a <copyout>
    800061ac:	10054363          	bltz	a0,800062b2 <exec+0x2f6>
    ustack[argc] = sp;
    800061b0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800061b4:	0485                	addi	s1,s1,1
    800061b6:	008d8793          	addi	a5,s11,8
    800061ba:	e0f43023          	sd	a5,-512(s0)
    800061be:	008db503          	ld	a0,8(s11)
    800061c2:	c911                	beqz	a0,800061d6 <exec+0x21a>
    if(argc >= MAXARG)
    800061c4:	09a1                	addi	s3,s3,8
    800061c6:	fb3c96e3          	bne	s9,s3,80006172 <exec+0x1b6>
  sz = sz1;
    800061ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800061ce:	4481                	li	s1,0
    800061d0:	a84d                	j	80006282 <exec+0x2c6>
  sp = sz;
    800061d2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800061d4:	4481                	li	s1,0
  ustack[argc] = 0;
    800061d6:	00349793          	slli	a5,s1,0x3
    800061da:	f9040713          	addi	a4,s0,-112
    800061de:	97ba                	add	a5,a5,a4
    800061e0:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800061e4:	00148693          	addi	a3,s1,1
    800061e8:	068e                	slli	a3,a3,0x3
    800061ea:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800061ee:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800061f2:	01897663          	bgeu	s2,s8,800061fe <exec+0x242>
  sz = sz1;
    800061f6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800061fa:	4481                	li	s1,0
    800061fc:	a059                	j	80006282 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800061fe:	e9040613          	addi	a2,s0,-368
    80006202:	85ca                	mv	a1,s2
    80006204:	855e                	mv	a0,s7
    80006206:	ffffb097          	auipc	ra,0xffffb
    8000620a:	474080e7          	jalr	1140(ra) # 8000167a <copyout>
    8000620e:	0a054663          	bltz	a0,800062ba <exec+0x2fe>
  p->trapframe->a1 = sp;
    80006212:	088ab783          	ld	a5,136(s5)
    80006216:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000621a:	df843783          	ld	a5,-520(s0)
    8000621e:	0007c703          	lbu	a4,0(a5)
    80006222:	cf11                	beqz	a4,8000623e <exec+0x282>
    80006224:	0785                	addi	a5,a5,1
    if(*s == '/')
    80006226:	02f00693          	li	a3,47
    8000622a:	a039                	j	80006238 <exec+0x27c>
      last = s+1;
    8000622c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80006230:	0785                	addi	a5,a5,1
    80006232:	fff7c703          	lbu	a4,-1(a5)
    80006236:	c701                	beqz	a4,8000623e <exec+0x282>
    if(*s == '/')
    80006238:	fed71ce3          	bne	a4,a3,80006230 <exec+0x274>
    8000623c:	bfc5                	j	8000622c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000623e:	4641                	li	a2,16
    80006240:	df843583          	ld	a1,-520(s0)
    80006244:	188a8513          	addi	a0,s5,392
    80006248:	ffffb097          	auipc	ra,0xffffb
    8000624c:	bea080e7          	jalr	-1046(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80006250:	080ab503          	ld	a0,128(s5)
  p->pagetable = pagetable;
    80006254:	097ab023          	sd	s7,128(s5)
  p->sz = sz;
    80006258:	076abc23          	sd	s6,120(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000625c:	088ab783          	ld	a5,136(s5)
    80006260:	e6843703          	ld	a4,-408(s0)
    80006264:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80006266:	088ab783          	ld	a5,136(s5)
    8000626a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000626e:	85ea                	mv	a1,s10
    80006270:	ffffc097          	auipc	ra,0xffffc
    80006274:	a98080e7          	jalr	-1384(ra) # 80001d08 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80006278:	0004851b          	sext.w	a0,s1
    8000627c:	bbe1                	j	80006054 <exec+0x98>
    8000627e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80006282:	e0843583          	ld	a1,-504(s0)
    80006286:	855e                	mv	a0,s7
    80006288:	ffffc097          	auipc	ra,0xffffc
    8000628c:	a80080e7          	jalr	-1408(ra) # 80001d08 <proc_freepagetable>
  if(ip){
    80006290:	da0498e3          	bnez	s1,80006040 <exec+0x84>
  return -1;
    80006294:	557d                	li	a0,-1
    80006296:	bb7d                	j	80006054 <exec+0x98>
    80006298:	e1243423          	sd	s2,-504(s0)
    8000629c:	b7dd                	j	80006282 <exec+0x2c6>
    8000629e:	e1243423          	sd	s2,-504(s0)
    800062a2:	b7c5                	j	80006282 <exec+0x2c6>
    800062a4:	e1243423          	sd	s2,-504(s0)
    800062a8:	bfe9                	j	80006282 <exec+0x2c6>
  sz = sz1;
    800062aa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800062ae:	4481                	li	s1,0
    800062b0:	bfc9                	j	80006282 <exec+0x2c6>
  sz = sz1;
    800062b2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800062b6:	4481                	li	s1,0
    800062b8:	b7e9                	j	80006282 <exec+0x2c6>
  sz = sz1;
    800062ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800062be:	4481                	li	s1,0
    800062c0:	b7c9                	j	80006282 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800062c2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800062c6:	2b05                	addiw	s6,s6,1
    800062c8:	0389899b          	addiw	s3,s3,56
    800062cc:	e8845783          	lhu	a5,-376(s0)
    800062d0:	e2fb5be3          	bge	s6,a5,80006106 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800062d4:	2981                	sext.w	s3,s3
    800062d6:	03800713          	li	a4,56
    800062da:	86ce                	mv	a3,s3
    800062dc:	e1840613          	addi	a2,s0,-488
    800062e0:	4581                	li	a1,0
    800062e2:	8526                	mv	a0,s1
    800062e4:	fffff097          	auipc	ra,0xfffff
    800062e8:	a8e080e7          	jalr	-1394(ra) # 80004d72 <readi>
    800062ec:	03800793          	li	a5,56
    800062f0:	f8f517e3          	bne	a0,a5,8000627e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800062f4:	e1842783          	lw	a5,-488(s0)
    800062f8:	4705                	li	a4,1
    800062fa:	fce796e3          	bne	a5,a4,800062c6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800062fe:	e4043603          	ld	a2,-448(s0)
    80006302:	e3843783          	ld	a5,-456(s0)
    80006306:	f8f669e3          	bltu	a2,a5,80006298 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000630a:	e2843783          	ld	a5,-472(s0)
    8000630e:	963e                	add	a2,a2,a5
    80006310:	f8f667e3          	bltu	a2,a5,8000629e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80006314:	85ca                	mv	a1,s2
    80006316:	855e                	mv	a0,s7
    80006318:	ffffb097          	auipc	ra,0xffffb
    8000631c:	112080e7          	jalr	274(ra) # 8000142a <uvmalloc>
    80006320:	e0a43423          	sd	a0,-504(s0)
    80006324:	d141                	beqz	a0,800062a4 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80006326:	e2843d03          	ld	s10,-472(s0)
    8000632a:	df043783          	ld	a5,-528(s0)
    8000632e:	00fd77b3          	and	a5,s10,a5
    80006332:	fba1                	bnez	a5,80006282 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80006334:	e2042d83          	lw	s11,-480(s0)
    80006338:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000633c:	f80c03e3          	beqz	s8,800062c2 <exec+0x306>
    80006340:	8a62                	mv	s4,s8
    80006342:	4901                	li	s2,0
    80006344:	b345                	j	800060e4 <exec+0x128>

0000000080006346 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80006346:	7179                	addi	sp,sp,-48
    80006348:	f406                	sd	ra,40(sp)
    8000634a:	f022                	sd	s0,32(sp)
    8000634c:	ec26                	sd	s1,24(sp)
    8000634e:	e84a                	sd	s2,16(sp)
    80006350:	1800                	addi	s0,sp,48
    80006352:	892e                	mv	s2,a1
    80006354:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80006356:	fdc40593          	addi	a1,s0,-36
    8000635a:	ffffe097          	auipc	ra,0xffffe
    8000635e:	b46080e7          	jalr	-1210(ra) # 80003ea0 <argint>
    80006362:	04054063          	bltz	a0,800063a2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80006366:	fdc42703          	lw	a4,-36(s0)
    8000636a:	47bd                	li	a5,15
    8000636c:	02e7ed63          	bltu	a5,a4,800063a6 <argfd+0x60>
    80006370:	ffffc097          	auipc	ra,0xffffc
    80006374:	834080e7          	jalr	-1996(ra) # 80001ba4 <myproc>
    80006378:	fdc42703          	lw	a4,-36(s0)
    8000637c:	02070793          	addi	a5,a4,32
    80006380:	078e                	slli	a5,a5,0x3
    80006382:	953e                	add	a0,a0,a5
    80006384:	611c                	ld	a5,0(a0)
    80006386:	c395                	beqz	a5,800063aa <argfd+0x64>
    return -1;
  if(pfd)
    80006388:	00090463          	beqz	s2,80006390 <argfd+0x4a>
    *pfd = fd;
    8000638c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80006390:	4501                	li	a0,0
  if(pf)
    80006392:	c091                	beqz	s1,80006396 <argfd+0x50>
    *pf = f;
    80006394:	e09c                	sd	a5,0(s1)
}
    80006396:	70a2                	ld	ra,40(sp)
    80006398:	7402                	ld	s0,32(sp)
    8000639a:	64e2                	ld	s1,24(sp)
    8000639c:	6942                	ld	s2,16(sp)
    8000639e:	6145                	addi	sp,sp,48
    800063a0:	8082                	ret
    return -1;
    800063a2:	557d                	li	a0,-1
    800063a4:	bfcd                	j	80006396 <argfd+0x50>
    return -1;
    800063a6:	557d                	li	a0,-1
    800063a8:	b7fd                	j	80006396 <argfd+0x50>
    800063aa:	557d                	li	a0,-1
    800063ac:	b7ed                	j	80006396 <argfd+0x50>

00000000800063ae <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800063ae:	1101                	addi	sp,sp,-32
    800063b0:	ec06                	sd	ra,24(sp)
    800063b2:	e822                	sd	s0,16(sp)
    800063b4:	e426                	sd	s1,8(sp)
    800063b6:	1000                	addi	s0,sp,32
    800063b8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800063ba:	ffffb097          	auipc	ra,0xffffb
    800063be:	7ea080e7          	jalr	2026(ra) # 80001ba4 <myproc>
    800063c2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800063c4:	10050793          	addi	a5,a0,256 # fffffffffffff100 <end+0xffffffff7ffd7100>
    800063c8:	4501                	li	a0,0
    800063ca:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800063cc:	6398                	ld	a4,0(a5)
    800063ce:	cb19                	beqz	a4,800063e4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800063d0:	2505                	addiw	a0,a0,1
    800063d2:	07a1                	addi	a5,a5,8
    800063d4:	fed51ce3          	bne	a0,a3,800063cc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800063d8:	557d                	li	a0,-1
}
    800063da:	60e2                	ld	ra,24(sp)
    800063dc:	6442                	ld	s0,16(sp)
    800063de:	64a2                	ld	s1,8(sp)
    800063e0:	6105                	addi	sp,sp,32
    800063e2:	8082                	ret
      p->ofile[fd] = f;
    800063e4:	02050793          	addi	a5,a0,32
    800063e8:	078e                	slli	a5,a5,0x3
    800063ea:	963e                	add	a2,a2,a5
    800063ec:	e204                	sd	s1,0(a2)
      return fd;
    800063ee:	b7f5                	j	800063da <fdalloc+0x2c>

00000000800063f0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800063f0:	715d                	addi	sp,sp,-80
    800063f2:	e486                	sd	ra,72(sp)
    800063f4:	e0a2                	sd	s0,64(sp)
    800063f6:	fc26                	sd	s1,56(sp)
    800063f8:	f84a                	sd	s2,48(sp)
    800063fa:	f44e                	sd	s3,40(sp)
    800063fc:	f052                	sd	s4,32(sp)
    800063fe:	ec56                	sd	s5,24(sp)
    80006400:	0880                	addi	s0,sp,80
    80006402:	89ae                	mv	s3,a1
    80006404:	8ab2                	mv	s5,a2
    80006406:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006408:	fb040593          	addi	a1,s0,-80
    8000640c:	fffff097          	auipc	ra,0xfffff
    80006410:	e86080e7          	jalr	-378(ra) # 80005292 <nameiparent>
    80006414:	892a                	mv	s2,a0
    80006416:	12050f63          	beqz	a0,80006554 <create+0x164>
    return 0;

  ilock(dp);
    8000641a:	ffffe097          	auipc	ra,0xffffe
    8000641e:	6a4080e7          	jalr	1700(ra) # 80004abe <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80006422:	4601                	li	a2,0
    80006424:	fb040593          	addi	a1,s0,-80
    80006428:	854a                	mv	a0,s2
    8000642a:	fffff097          	auipc	ra,0xfffff
    8000642e:	b78080e7          	jalr	-1160(ra) # 80004fa2 <dirlookup>
    80006432:	84aa                	mv	s1,a0
    80006434:	c921                	beqz	a0,80006484 <create+0x94>
    iunlockput(dp);
    80006436:	854a                	mv	a0,s2
    80006438:	fffff097          	auipc	ra,0xfffff
    8000643c:	8e8080e7          	jalr	-1816(ra) # 80004d20 <iunlockput>
    ilock(ip);
    80006440:	8526                	mv	a0,s1
    80006442:	ffffe097          	auipc	ra,0xffffe
    80006446:	67c080e7          	jalr	1660(ra) # 80004abe <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000644a:	2981                	sext.w	s3,s3
    8000644c:	4789                	li	a5,2
    8000644e:	02f99463          	bne	s3,a5,80006476 <create+0x86>
    80006452:	0444d783          	lhu	a5,68(s1)
    80006456:	37f9                	addiw	a5,a5,-2
    80006458:	17c2                	slli	a5,a5,0x30
    8000645a:	93c1                	srli	a5,a5,0x30
    8000645c:	4705                	li	a4,1
    8000645e:	00f76c63          	bltu	a4,a5,80006476 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006462:	8526                	mv	a0,s1
    80006464:	60a6                	ld	ra,72(sp)
    80006466:	6406                	ld	s0,64(sp)
    80006468:	74e2                	ld	s1,56(sp)
    8000646a:	7942                	ld	s2,48(sp)
    8000646c:	79a2                	ld	s3,40(sp)
    8000646e:	7a02                	ld	s4,32(sp)
    80006470:	6ae2                	ld	s5,24(sp)
    80006472:	6161                	addi	sp,sp,80
    80006474:	8082                	ret
    iunlockput(ip);
    80006476:	8526                	mv	a0,s1
    80006478:	fffff097          	auipc	ra,0xfffff
    8000647c:	8a8080e7          	jalr	-1880(ra) # 80004d20 <iunlockput>
    return 0;
    80006480:	4481                	li	s1,0
    80006482:	b7c5                	j	80006462 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80006484:	85ce                	mv	a1,s3
    80006486:	00092503          	lw	a0,0(s2)
    8000648a:	ffffe097          	auipc	ra,0xffffe
    8000648e:	49c080e7          	jalr	1180(ra) # 80004926 <ialloc>
    80006492:	84aa                	mv	s1,a0
    80006494:	c529                	beqz	a0,800064de <create+0xee>
  ilock(ip);
    80006496:	ffffe097          	auipc	ra,0xffffe
    8000649a:	628080e7          	jalr	1576(ra) # 80004abe <ilock>
  ip->major = major;
    8000649e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800064a2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800064a6:	4785                	li	a5,1
    800064a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800064ac:	8526                	mv	a0,s1
    800064ae:	ffffe097          	auipc	ra,0xffffe
    800064b2:	546080e7          	jalr	1350(ra) # 800049f4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800064b6:	2981                	sext.w	s3,s3
    800064b8:	4785                	li	a5,1
    800064ba:	02f98a63          	beq	s3,a5,800064ee <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800064be:	40d0                	lw	a2,4(s1)
    800064c0:	fb040593          	addi	a1,s0,-80
    800064c4:	854a                	mv	a0,s2
    800064c6:	fffff097          	auipc	ra,0xfffff
    800064ca:	cec080e7          	jalr	-788(ra) # 800051b2 <dirlink>
    800064ce:	06054b63          	bltz	a0,80006544 <create+0x154>
  iunlockput(dp);
    800064d2:	854a                	mv	a0,s2
    800064d4:	fffff097          	auipc	ra,0xfffff
    800064d8:	84c080e7          	jalr	-1972(ra) # 80004d20 <iunlockput>
  return ip;
    800064dc:	b759                	j	80006462 <create+0x72>
    panic("create: ialloc");
    800064de:	00003517          	auipc	a0,0x3
    800064e2:	3a250513          	addi	a0,a0,930 # 80009880 <syscalls+0x2c8>
    800064e6:	ffffa097          	auipc	ra,0xffffa
    800064ea:	058080e7          	jalr	88(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800064ee:	04a95783          	lhu	a5,74(s2)
    800064f2:	2785                	addiw	a5,a5,1
    800064f4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800064f8:	854a                	mv	a0,s2
    800064fa:	ffffe097          	auipc	ra,0xffffe
    800064fe:	4fa080e7          	jalr	1274(ra) # 800049f4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006502:	40d0                	lw	a2,4(s1)
    80006504:	00003597          	auipc	a1,0x3
    80006508:	38c58593          	addi	a1,a1,908 # 80009890 <syscalls+0x2d8>
    8000650c:	8526                	mv	a0,s1
    8000650e:	fffff097          	auipc	ra,0xfffff
    80006512:	ca4080e7          	jalr	-860(ra) # 800051b2 <dirlink>
    80006516:	00054f63          	bltz	a0,80006534 <create+0x144>
    8000651a:	00492603          	lw	a2,4(s2)
    8000651e:	00003597          	auipc	a1,0x3
    80006522:	37a58593          	addi	a1,a1,890 # 80009898 <syscalls+0x2e0>
    80006526:	8526                	mv	a0,s1
    80006528:	fffff097          	auipc	ra,0xfffff
    8000652c:	c8a080e7          	jalr	-886(ra) # 800051b2 <dirlink>
    80006530:	f80557e3          	bgez	a0,800064be <create+0xce>
      panic("create dots");
    80006534:	00003517          	auipc	a0,0x3
    80006538:	36c50513          	addi	a0,a0,876 # 800098a0 <syscalls+0x2e8>
    8000653c:	ffffa097          	auipc	ra,0xffffa
    80006540:	002080e7          	jalr	2(ra) # 8000053e <panic>
    panic("create: dirlink");
    80006544:	00003517          	auipc	a0,0x3
    80006548:	36c50513          	addi	a0,a0,876 # 800098b0 <syscalls+0x2f8>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	ff2080e7          	jalr	-14(ra) # 8000053e <panic>
    return 0;
    80006554:	84aa                	mv	s1,a0
    80006556:	b731                	j	80006462 <create+0x72>

0000000080006558 <sys_dup>:
{
    80006558:	7179                	addi	sp,sp,-48
    8000655a:	f406                	sd	ra,40(sp)
    8000655c:	f022                	sd	s0,32(sp)
    8000655e:	ec26                	sd	s1,24(sp)
    80006560:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80006562:	fd840613          	addi	a2,s0,-40
    80006566:	4581                	li	a1,0
    80006568:	4501                	li	a0,0
    8000656a:	00000097          	auipc	ra,0x0
    8000656e:	ddc080e7          	jalr	-548(ra) # 80006346 <argfd>
    return -1;
    80006572:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80006574:	02054363          	bltz	a0,8000659a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80006578:	fd843503          	ld	a0,-40(s0)
    8000657c:	00000097          	auipc	ra,0x0
    80006580:	e32080e7          	jalr	-462(ra) # 800063ae <fdalloc>
    80006584:	84aa                	mv	s1,a0
    return -1;
    80006586:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80006588:	00054963          	bltz	a0,8000659a <sys_dup+0x42>
  filedup(f);
    8000658c:	fd843503          	ld	a0,-40(s0)
    80006590:	fffff097          	auipc	ra,0xfffff
    80006594:	37a080e7          	jalr	890(ra) # 8000590a <filedup>
  return fd;
    80006598:	87a6                	mv	a5,s1
}
    8000659a:	853e                	mv	a0,a5
    8000659c:	70a2                	ld	ra,40(sp)
    8000659e:	7402                	ld	s0,32(sp)
    800065a0:	64e2                	ld	s1,24(sp)
    800065a2:	6145                	addi	sp,sp,48
    800065a4:	8082                	ret

00000000800065a6 <sys_read>:
{
    800065a6:	7179                	addi	sp,sp,-48
    800065a8:	f406                	sd	ra,40(sp)
    800065aa:	f022                	sd	s0,32(sp)
    800065ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800065ae:	fe840613          	addi	a2,s0,-24
    800065b2:	4581                	li	a1,0
    800065b4:	4501                	li	a0,0
    800065b6:	00000097          	auipc	ra,0x0
    800065ba:	d90080e7          	jalr	-624(ra) # 80006346 <argfd>
    return -1;
    800065be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800065c0:	04054163          	bltz	a0,80006602 <sys_read+0x5c>
    800065c4:	fe440593          	addi	a1,s0,-28
    800065c8:	4509                	li	a0,2
    800065ca:	ffffe097          	auipc	ra,0xffffe
    800065ce:	8d6080e7          	jalr	-1834(ra) # 80003ea0 <argint>
    return -1;
    800065d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800065d4:	02054763          	bltz	a0,80006602 <sys_read+0x5c>
    800065d8:	fd840593          	addi	a1,s0,-40
    800065dc:	4505                	li	a0,1
    800065de:	ffffe097          	auipc	ra,0xffffe
    800065e2:	8e4080e7          	jalr	-1820(ra) # 80003ec2 <argaddr>
    return -1;
    800065e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800065e8:	00054d63          	bltz	a0,80006602 <sys_read+0x5c>
  return fileread(f, p, n);
    800065ec:	fe442603          	lw	a2,-28(s0)
    800065f0:	fd843583          	ld	a1,-40(s0)
    800065f4:	fe843503          	ld	a0,-24(s0)
    800065f8:	fffff097          	auipc	ra,0xfffff
    800065fc:	49e080e7          	jalr	1182(ra) # 80005a96 <fileread>
    80006600:	87aa                	mv	a5,a0
}
    80006602:	853e                	mv	a0,a5
    80006604:	70a2                	ld	ra,40(sp)
    80006606:	7402                	ld	s0,32(sp)
    80006608:	6145                	addi	sp,sp,48
    8000660a:	8082                	ret

000000008000660c <sys_write>:
{
    8000660c:	7179                	addi	sp,sp,-48
    8000660e:	f406                	sd	ra,40(sp)
    80006610:	f022                	sd	s0,32(sp)
    80006612:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006614:	fe840613          	addi	a2,s0,-24
    80006618:	4581                	li	a1,0
    8000661a:	4501                	li	a0,0
    8000661c:	00000097          	auipc	ra,0x0
    80006620:	d2a080e7          	jalr	-726(ra) # 80006346 <argfd>
    return -1;
    80006624:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006626:	04054163          	bltz	a0,80006668 <sys_write+0x5c>
    8000662a:	fe440593          	addi	a1,s0,-28
    8000662e:	4509                	li	a0,2
    80006630:	ffffe097          	auipc	ra,0xffffe
    80006634:	870080e7          	jalr	-1936(ra) # 80003ea0 <argint>
    return -1;
    80006638:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000663a:	02054763          	bltz	a0,80006668 <sys_write+0x5c>
    8000663e:	fd840593          	addi	a1,s0,-40
    80006642:	4505                	li	a0,1
    80006644:	ffffe097          	auipc	ra,0xffffe
    80006648:	87e080e7          	jalr	-1922(ra) # 80003ec2 <argaddr>
    return -1;
    8000664c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000664e:	00054d63          	bltz	a0,80006668 <sys_write+0x5c>
  return filewrite(f, p, n);
    80006652:	fe442603          	lw	a2,-28(s0)
    80006656:	fd843583          	ld	a1,-40(s0)
    8000665a:	fe843503          	ld	a0,-24(s0)
    8000665e:	fffff097          	auipc	ra,0xfffff
    80006662:	4fa080e7          	jalr	1274(ra) # 80005b58 <filewrite>
    80006666:	87aa                	mv	a5,a0
}
    80006668:	853e                	mv	a0,a5
    8000666a:	70a2                	ld	ra,40(sp)
    8000666c:	7402                	ld	s0,32(sp)
    8000666e:	6145                	addi	sp,sp,48
    80006670:	8082                	ret

0000000080006672 <sys_close>:
{
    80006672:	1101                	addi	sp,sp,-32
    80006674:	ec06                	sd	ra,24(sp)
    80006676:	e822                	sd	s0,16(sp)
    80006678:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000667a:	fe040613          	addi	a2,s0,-32
    8000667e:	fec40593          	addi	a1,s0,-20
    80006682:	4501                	li	a0,0
    80006684:	00000097          	auipc	ra,0x0
    80006688:	cc2080e7          	jalr	-830(ra) # 80006346 <argfd>
    return -1;
    8000668c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000668e:	02054563          	bltz	a0,800066b8 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80006692:	ffffb097          	auipc	ra,0xffffb
    80006696:	512080e7          	jalr	1298(ra) # 80001ba4 <myproc>
    8000669a:	fec42783          	lw	a5,-20(s0)
    8000669e:	02078793          	addi	a5,a5,32
    800066a2:	078e                	slli	a5,a5,0x3
    800066a4:	97aa                	add	a5,a5,a0
    800066a6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800066aa:	fe043503          	ld	a0,-32(s0)
    800066ae:	fffff097          	auipc	ra,0xfffff
    800066b2:	2ae080e7          	jalr	686(ra) # 8000595c <fileclose>
  return 0;
    800066b6:	4781                	li	a5,0
}
    800066b8:	853e                	mv	a0,a5
    800066ba:	60e2                	ld	ra,24(sp)
    800066bc:	6442                	ld	s0,16(sp)
    800066be:	6105                	addi	sp,sp,32
    800066c0:	8082                	ret

00000000800066c2 <sys_fstat>:
{
    800066c2:	1101                	addi	sp,sp,-32
    800066c4:	ec06                	sd	ra,24(sp)
    800066c6:	e822                	sd	s0,16(sp)
    800066c8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800066ca:	fe840613          	addi	a2,s0,-24
    800066ce:	4581                	li	a1,0
    800066d0:	4501                	li	a0,0
    800066d2:	00000097          	auipc	ra,0x0
    800066d6:	c74080e7          	jalr	-908(ra) # 80006346 <argfd>
    return -1;
    800066da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800066dc:	02054563          	bltz	a0,80006706 <sys_fstat+0x44>
    800066e0:	fe040593          	addi	a1,s0,-32
    800066e4:	4505                	li	a0,1
    800066e6:	ffffd097          	auipc	ra,0xffffd
    800066ea:	7dc080e7          	jalr	2012(ra) # 80003ec2 <argaddr>
    return -1;
    800066ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800066f0:	00054b63          	bltz	a0,80006706 <sys_fstat+0x44>
  return filestat(f, st);
    800066f4:	fe043583          	ld	a1,-32(s0)
    800066f8:	fe843503          	ld	a0,-24(s0)
    800066fc:	fffff097          	auipc	ra,0xfffff
    80006700:	328080e7          	jalr	808(ra) # 80005a24 <filestat>
    80006704:	87aa                	mv	a5,a0
}
    80006706:	853e                	mv	a0,a5
    80006708:	60e2                	ld	ra,24(sp)
    8000670a:	6442                	ld	s0,16(sp)
    8000670c:	6105                	addi	sp,sp,32
    8000670e:	8082                	ret

0000000080006710 <sys_link>:
{
    80006710:	7169                	addi	sp,sp,-304
    80006712:	f606                	sd	ra,296(sp)
    80006714:	f222                	sd	s0,288(sp)
    80006716:	ee26                	sd	s1,280(sp)
    80006718:	ea4a                	sd	s2,272(sp)
    8000671a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000671c:	08000613          	li	a2,128
    80006720:	ed040593          	addi	a1,s0,-304
    80006724:	4501                	li	a0,0
    80006726:	ffffd097          	auipc	ra,0xffffd
    8000672a:	7be080e7          	jalr	1982(ra) # 80003ee4 <argstr>
    return -1;
    8000672e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006730:	10054e63          	bltz	a0,8000684c <sys_link+0x13c>
    80006734:	08000613          	li	a2,128
    80006738:	f5040593          	addi	a1,s0,-176
    8000673c:	4505                	li	a0,1
    8000673e:	ffffd097          	auipc	ra,0xffffd
    80006742:	7a6080e7          	jalr	1958(ra) # 80003ee4 <argstr>
    return -1;
    80006746:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006748:	10054263          	bltz	a0,8000684c <sys_link+0x13c>
  begin_op();
    8000674c:	fffff097          	auipc	ra,0xfffff
    80006750:	d44080e7          	jalr	-700(ra) # 80005490 <begin_op>
  if((ip = namei(old)) == 0){
    80006754:	ed040513          	addi	a0,s0,-304
    80006758:	fffff097          	auipc	ra,0xfffff
    8000675c:	b1c080e7          	jalr	-1252(ra) # 80005274 <namei>
    80006760:	84aa                	mv	s1,a0
    80006762:	c551                	beqz	a0,800067ee <sys_link+0xde>
  ilock(ip);
    80006764:	ffffe097          	auipc	ra,0xffffe
    80006768:	35a080e7          	jalr	858(ra) # 80004abe <ilock>
  if(ip->type == T_DIR){
    8000676c:	04449703          	lh	a4,68(s1)
    80006770:	4785                	li	a5,1
    80006772:	08f70463          	beq	a4,a5,800067fa <sys_link+0xea>
  ip->nlink++;
    80006776:	04a4d783          	lhu	a5,74(s1)
    8000677a:	2785                	addiw	a5,a5,1
    8000677c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006780:	8526                	mv	a0,s1
    80006782:	ffffe097          	auipc	ra,0xffffe
    80006786:	272080e7          	jalr	626(ra) # 800049f4 <iupdate>
  iunlock(ip);
    8000678a:	8526                	mv	a0,s1
    8000678c:	ffffe097          	auipc	ra,0xffffe
    80006790:	3f4080e7          	jalr	1012(ra) # 80004b80 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006794:	fd040593          	addi	a1,s0,-48
    80006798:	f5040513          	addi	a0,s0,-176
    8000679c:	fffff097          	auipc	ra,0xfffff
    800067a0:	af6080e7          	jalr	-1290(ra) # 80005292 <nameiparent>
    800067a4:	892a                	mv	s2,a0
    800067a6:	c935                	beqz	a0,8000681a <sys_link+0x10a>
  ilock(dp);
    800067a8:	ffffe097          	auipc	ra,0xffffe
    800067ac:	316080e7          	jalr	790(ra) # 80004abe <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800067b0:	00092703          	lw	a4,0(s2)
    800067b4:	409c                	lw	a5,0(s1)
    800067b6:	04f71d63          	bne	a4,a5,80006810 <sys_link+0x100>
    800067ba:	40d0                	lw	a2,4(s1)
    800067bc:	fd040593          	addi	a1,s0,-48
    800067c0:	854a                	mv	a0,s2
    800067c2:	fffff097          	auipc	ra,0xfffff
    800067c6:	9f0080e7          	jalr	-1552(ra) # 800051b2 <dirlink>
    800067ca:	04054363          	bltz	a0,80006810 <sys_link+0x100>
  iunlockput(dp);
    800067ce:	854a                	mv	a0,s2
    800067d0:	ffffe097          	auipc	ra,0xffffe
    800067d4:	550080e7          	jalr	1360(ra) # 80004d20 <iunlockput>
  iput(ip);
    800067d8:	8526                	mv	a0,s1
    800067da:	ffffe097          	auipc	ra,0xffffe
    800067de:	49e080e7          	jalr	1182(ra) # 80004c78 <iput>
  end_op();
    800067e2:	fffff097          	auipc	ra,0xfffff
    800067e6:	d2e080e7          	jalr	-722(ra) # 80005510 <end_op>
  return 0;
    800067ea:	4781                	li	a5,0
    800067ec:	a085                	j	8000684c <sys_link+0x13c>
    end_op();
    800067ee:	fffff097          	auipc	ra,0xfffff
    800067f2:	d22080e7          	jalr	-734(ra) # 80005510 <end_op>
    return -1;
    800067f6:	57fd                	li	a5,-1
    800067f8:	a891                	j	8000684c <sys_link+0x13c>
    iunlockput(ip);
    800067fa:	8526                	mv	a0,s1
    800067fc:	ffffe097          	auipc	ra,0xffffe
    80006800:	524080e7          	jalr	1316(ra) # 80004d20 <iunlockput>
    end_op();
    80006804:	fffff097          	auipc	ra,0xfffff
    80006808:	d0c080e7          	jalr	-756(ra) # 80005510 <end_op>
    return -1;
    8000680c:	57fd                	li	a5,-1
    8000680e:	a83d                	j	8000684c <sys_link+0x13c>
    iunlockput(dp);
    80006810:	854a                	mv	a0,s2
    80006812:	ffffe097          	auipc	ra,0xffffe
    80006816:	50e080e7          	jalr	1294(ra) # 80004d20 <iunlockput>
  ilock(ip);
    8000681a:	8526                	mv	a0,s1
    8000681c:	ffffe097          	auipc	ra,0xffffe
    80006820:	2a2080e7          	jalr	674(ra) # 80004abe <ilock>
  ip->nlink--;
    80006824:	04a4d783          	lhu	a5,74(s1)
    80006828:	37fd                	addiw	a5,a5,-1
    8000682a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000682e:	8526                	mv	a0,s1
    80006830:	ffffe097          	auipc	ra,0xffffe
    80006834:	1c4080e7          	jalr	452(ra) # 800049f4 <iupdate>
  iunlockput(ip);
    80006838:	8526                	mv	a0,s1
    8000683a:	ffffe097          	auipc	ra,0xffffe
    8000683e:	4e6080e7          	jalr	1254(ra) # 80004d20 <iunlockput>
  end_op();
    80006842:	fffff097          	auipc	ra,0xfffff
    80006846:	cce080e7          	jalr	-818(ra) # 80005510 <end_op>
  return -1;
    8000684a:	57fd                	li	a5,-1
}
    8000684c:	853e                	mv	a0,a5
    8000684e:	70b2                	ld	ra,296(sp)
    80006850:	7412                	ld	s0,288(sp)
    80006852:	64f2                	ld	s1,280(sp)
    80006854:	6952                	ld	s2,272(sp)
    80006856:	6155                	addi	sp,sp,304
    80006858:	8082                	ret

000000008000685a <sys_unlink>:
{
    8000685a:	7151                	addi	sp,sp,-240
    8000685c:	f586                	sd	ra,232(sp)
    8000685e:	f1a2                	sd	s0,224(sp)
    80006860:	eda6                	sd	s1,216(sp)
    80006862:	e9ca                	sd	s2,208(sp)
    80006864:	e5ce                	sd	s3,200(sp)
    80006866:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006868:	08000613          	li	a2,128
    8000686c:	f3040593          	addi	a1,s0,-208
    80006870:	4501                	li	a0,0
    80006872:	ffffd097          	auipc	ra,0xffffd
    80006876:	672080e7          	jalr	1650(ra) # 80003ee4 <argstr>
    8000687a:	18054163          	bltz	a0,800069fc <sys_unlink+0x1a2>
  begin_op();
    8000687e:	fffff097          	auipc	ra,0xfffff
    80006882:	c12080e7          	jalr	-1006(ra) # 80005490 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006886:	fb040593          	addi	a1,s0,-80
    8000688a:	f3040513          	addi	a0,s0,-208
    8000688e:	fffff097          	auipc	ra,0xfffff
    80006892:	a04080e7          	jalr	-1532(ra) # 80005292 <nameiparent>
    80006896:	84aa                	mv	s1,a0
    80006898:	c979                	beqz	a0,8000696e <sys_unlink+0x114>
  ilock(dp);
    8000689a:	ffffe097          	auipc	ra,0xffffe
    8000689e:	224080e7          	jalr	548(ra) # 80004abe <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800068a2:	00003597          	auipc	a1,0x3
    800068a6:	fee58593          	addi	a1,a1,-18 # 80009890 <syscalls+0x2d8>
    800068aa:	fb040513          	addi	a0,s0,-80
    800068ae:	ffffe097          	auipc	ra,0xffffe
    800068b2:	6da080e7          	jalr	1754(ra) # 80004f88 <namecmp>
    800068b6:	14050a63          	beqz	a0,80006a0a <sys_unlink+0x1b0>
    800068ba:	00003597          	auipc	a1,0x3
    800068be:	fde58593          	addi	a1,a1,-34 # 80009898 <syscalls+0x2e0>
    800068c2:	fb040513          	addi	a0,s0,-80
    800068c6:	ffffe097          	auipc	ra,0xffffe
    800068ca:	6c2080e7          	jalr	1730(ra) # 80004f88 <namecmp>
    800068ce:	12050e63          	beqz	a0,80006a0a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800068d2:	f2c40613          	addi	a2,s0,-212
    800068d6:	fb040593          	addi	a1,s0,-80
    800068da:	8526                	mv	a0,s1
    800068dc:	ffffe097          	auipc	ra,0xffffe
    800068e0:	6c6080e7          	jalr	1734(ra) # 80004fa2 <dirlookup>
    800068e4:	892a                	mv	s2,a0
    800068e6:	12050263          	beqz	a0,80006a0a <sys_unlink+0x1b0>
  ilock(ip);
    800068ea:	ffffe097          	auipc	ra,0xffffe
    800068ee:	1d4080e7          	jalr	468(ra) # 80004abe <ilock>
  if(ip->nlink < 1)
    800068f2:	04a91783          	lh	a5,74(s2)
    800068f6:	08f05263          	blez	a5,8000697a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800068fa:	04491703          	lh	a4,68(s2)
    800068fe:	4785                	li	a5,1
    80006900:	08f70563          	beq	a4,a5,8000698a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006904:	4641                	li	a2,16
    80006906:	4581                	li	a1,0
    80006908:	fc040513          	addi	a0,s0,-64
    8000690c:	ffffa097          	auipc	ra,0xffffa
    80006910:	3d4080e7          	jalr	980(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006914:	4741                	li	a4,16
    80006916:	f2c42683          	lw	a3,-212(s0)
    8000691a:	fc040613          	addi	a2,s0,-64
    8000691e:	4581                	li	a1,0
    80006920:	8526                	mv	a0,s1
    80006922:	ffffe097          	auipc	ra,0xffffe
    80006926:	548080e7          	jalr	1352(ra) # 80004e6a <writei>
    8000692a:	47c1                	li	a5,16
    8000692c:	0af51563          	bne	a0,a5,800069d6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006930:	04491703          	lh	a4,68(s2)
    80006934:	4785                	li	a5,1
    80006936:	0af70863          	beq	a4,a5,800069e6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000693a:	8526                	mv	a0,s1
    8000693c:	ffffe097          	auipc	ra,0xffffe
    80006940:	3e4080e7          	jalr	996(ra) # 80004d20 <iunlockput>
  ip->nlink--;
    80006944:	04a95783          	lhu	a5,74(s2)
    80006948:	37fd                	addiw	a5,a5,-1
    8000694a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000694e:	854a                	mv	a0,s2
    80006950:	ffffe097          	auipc	ra,0xffffe
    80006954:	0a4080e7          	jalr	164(ra) # 800049f4 <iupdate>
  iunlockput(ip);
    80006958:	854a                	mv	a0,s2
    8000695a:	ffffe097          	auipc	ra,0xffffe
    8000695e:	3c6080e7          	jalr	966(ra) # 80004d20 <iunlockput>
  end_op();
    80006962:	fffff097          	auipc	ra,0xfffff
    80006966:	bae080e7          	jalr	-1106(ra) # 80005510 <end_op>
  return 0;
    8000696a:	4501                	li	a0,0
    8000696c:	a84d                	j	80006a1e <sys_unlink+0x1c4>
    end_op();
    8000696e:	fffff097          	auipc	ra,0xfffff
    80006972:	ba2080e7          	jalr	-1118(ra) # 80005510 <end_op>
    return -1;
    80006976:	557d                	li	a0,-1
    80006978:	a05d                	j	80006a1e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000697a:	00003517          	auipc	a0,0x3
    8000697e:	f4650513          	addi	a0,a0,-186 # 800098c0 <syscalls+0x308>
    80006982:	ffffa097          	auipc	ra,0xffffa
    80006986:	bbc080e7          	jalr	-1092(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000698a:	04c92703          	lw	a4,76(s2)
    8000698e:	02000793          	li	a5,32
    80006992:	f6e7f9e3          	bgeu	a5,a4,80006904 <sys_unlink+0xaa>
    80006996:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000699a:	4741                	li	a4,16
    8000699c:	86ce                	mv	a3,s3
    8000699e:	f1840613          	addi	a2,s0,-232
    800069a2:	4581                	li	a1,0
    800069a4:	854a                	mv	a0,s2
    800069a6:	ffffe097          	auipc	ra,0xffffe
    800069aa:	3cc080e7          	jalr	972(ra) # 80004d72 <readi>
    800069ae:	47c1                	li	a5,16
    800069b0:	00f51b63          	bne	a0,a5,800069c6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800069b4:	f1845783          	lhu	a5,-232(s0)
    800069b8:	e7a1                	bnez	a5,80006a00 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800069ba:	29c1                	addiw	s3,s3,16
    800069bc:	04c92783          	lw	a5,76(s2)
    800069c0:	fcf9ede3          	bltu	s3,a5,8000699a <sys_unlink+0x140>
    800069c4:	b781                	j	80006904 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800069c6:	00003517          	auipc	a0,0x3
    800069ca:	f1250513          	addi	a0,a0,-238 # 800098d8 <syscalls+0x320>
    800069ce:	ffffa097          	auipc	ra,0xffffa
    800069d2:	b70080e7          	jalr	-1168(ra) # 8000053e <panic>
    panic("unlink: writei");
    800069d6:	00003517          	auipc	a0,0x3
    800069da:	f1a50513          	addi	a0,a0,-230 # 800098f0 <syscalls+0x338>
    800069de:	ffffa097          	auipc	ra,0xffffa
    800069e2:	b60080e7          	jalr	-1184(ra) # 8000053e <panic>
    dp->nlink--;
    800069e6:	04a4d783          	lhu	a5,74(s1)
    800069ea:	37fd                	addiw	a5,a5,-1
    800069ec:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800069f0:	8526                	mv	a0,s1
    800069f2:	ffffe097          	auipc	ra,0xffffe
    800069f6:	002080e7          	jalr	2(ra) # 800049f4 <iupdate>
    800069fa:	b781                	j	8000693a <sys_unlink+0xe0>
    return -1;
    800069fc:	557d                	li	a0,-1
    800069fe:	a005                	j	80006a1e <sys_unlink+0x1c4>
    iunlockput(ip);
    80006a00:	854a                	mv	a0,s2
    80006a02:	ffffe097          	auipc	ra,0xffffe
    80006a06:	31e080e7          	jalr	798(ra) # 80004d20 <iunlockput>
  iunlockput(dp);
    80006a0a:	8526                	mv	a0,s1
    80006a0c:	ffffe097          	auipc	ra,0xffffe
    80006a10:	314080e7          	jalr	788(ra) # 80004d20 <iunlockput>
  end_op();
    80006a14:	fffff097          	auipc	ra,0xfffff
    80006a18:	afc080e7          	jalr	-1284(ra) # 80005510 <end_op>
  return -1;
    80006a1c:	557d                	li	a0,-1
}
    80006a1e:	70ae                	ld	ra,232(sp)
    80006a20:	740e                	ld	s0,224(sp)
    80006a22:	64ee                	ld	s1,216(sp)
    80006a24:	694e                	ld	s2,208(sp)
    80006a26:	69ae                	ld	s3,200(sp)
    80006a28:	616d                	addi	sp,sp,240
    80006a2a:	8082                	ret

0000000080006a2c <sys_open>:

uint64
sys_open(void)
{
    80006a2c:	7131                	addi	sp,sp,-192
    80006a2e:	fd06                	sd	ra,184(sp)
    80006a30:	f922                	sd	s0,176(sp)
    80006a32:	f526                	sd	s1,168(sp)
    80006a34:	f14a                	sd	s2,160(sp)
    80006a36:	ed4e                	sd	s3,152(sp)
    80006a38:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006a3a:	08000613          	li	a2,128
    80006a3e:	f5040593          	addi	a1,s0,-176
    80006a42:	4501                	li	a0,0
    80006a44:	ffffd097          	auipc	ra,0xffffd
    80006a48:	4a0080e7          	jalr	1184(ra) # 80003ee4 <argstr>
    return -1;
    80006a4c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006a4e:	0c054163          	bltz	a0,80006b10 <sys_open+0xe4>
    80006a52:	f4c40593          	addi	a1,s0,-180
    80006a56:	4505                	li	a0,1
    80006a58:	ffffd097          	auipc	ra,0xffffd
    80006a5c:	448080e7          	jalr	1096(ra) # 80003ea0 <argint>
    80006a60:	0a054863          	bltz	a0,80006b10 <sys_open+0xe4>

  begin_op();
    80006a64:	fffff097          	auipc	ra,0xfffff
    80006a68:	a2c080e7          	jalr	-1492(ra) # 80005490 <begin_op>

  if(omode & O_CREATE){
    80006a6c:	f4c42783          	lw	a5,-180(s0)
    80006a70:	2007f793          	andi	a5,a5,512
    80006a74:	cbdd                	beqz	a5,80006b2a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006a76:	4681                	li	a3,0
    80006a78:	4601                	li	a2,0
    80006a7a:	4589                	li	a1,2
    80006a7c:	f5040513          	addi	a0,s0,-176
    80006a80:	00000097          	auipc	ra,0x0
    80006a84:	970080e7          	jalr	-1680(ra) # 800063f0 <create>
    80006a88:	892a                	mv	s2,a0
    if(ip == 0){
    80006a8a:	c959                	beqz	a0,80006b20 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006a8c:	04491703          	lh	a4,68(s2)
    80006a90:	478d                	li	a5,3
    80006a92:	00f71763          	bne	a4,a5,80006aa0 <sys_open+0x74>
    80006a96:	04695703          	lhu	a4,70(s2)
    80006a9a:	47a5                	li	a5,9
    80006a9c:	0ce7ec63          	bltu	a5,a4,80006b74 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006aa0:	fffff097          	auipc	ra,0xfffff
    80006aa4:	e00080e7          	jalr	-512(ra) # 800058a0 <filealloc>
    80006aa8:	89aa                	mv	s3,a0
    80006aaa:	10050263          	beqz	a0,80006bae <sys_open+0x182>
    80006aae:	00000097          	auipc	ra,0x0
    80006ab2:	900080e7          	jalr	-1792(ra) # 800063ae <fdalloc>
    80006ab6:	84aa                	mv	s1,a0
    80006ab8:	0e054663          	bltz	a0,80006ba4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006abc:	04491703          	lh	a4,68(s2)
    80006ac0:	478d                	li	a5,3
    80006ac2:	0cf70463          	beq	a4,a5,80006b8a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006ac6:	4789                	li	a5,2
    80006ac8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006acc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006ad0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006ad4:	f4c42783          	lw	a5,-180(s0)
    80006ad8:	0017c713          	xori	a4,a5,1
    80006adc:	8b05                	andi	a4,a4,1
    80006ade:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006ae2:	0037f713          	andi	a4,a5,3
    80006ae6:	00e03733          	snez	a4,a4
    80006aea:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006aee:	4007f793          	andi	a5,a5,1024
    80006af2:	c791                	beqz	a5,80006afe <sys_open+0xd2>
    80006af4:	04491703          	lh	a4,68(s2)
    80006af8:	4789                	li	a5,2
    80006afa:	08f70f63          	beq	a4,a5,80006b98 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006afe:	854a                	mv	a0,s2
    80006b00:	ffffe097          	auipc	ra,0xffffe
    80006b04:	080080e7          	jalr	128(ra) # 80004b80 <iunlock>
  end_op();
    80006b08:	fffff097          	auipc	ra,0xfffff
    80006b0c:	a08080e7          	jalr	-1528(ra) # 80005510 <end_op>

  return fd;
}
    80006b10:	8526                	mv	a0,s1
    80006b12:	70ea                	ld	ra,184(sp)
    80006b14:	744a                	ld	s0,176(sp)
    80006b16:	74aa                	ld	s1,168(sp)
    80006b18:	790a                	ld	s2,160(sp)
    80006b1a:	69ea                	ld	s3,152(sp)
    80006b1c:	6129                	addi	sp,sp,192
    80006b1e:	8082                	ret
      end_op();
    80006b20:	fffff097          	auipc	ra,0xfffff
    80006b24:	9f0080e7          	jalr	-1552(ra) # 80005510 <end_op>
      return -1;
    80006b28:	b7e5                	j	80006b10 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006b2a:	f5040513          	addi	a0,s0,-176
    80006b2e:	ffffe097          	auipc	ra,0xffffe
    80006b32:	746080e7          	jalr	1862(ra) # 80005274 <namei>
    80006b36:	892a                	mv	s2,a0
    80006b38:	c905                	beqz	a0,80006b68 <sys_open+0x13c>
    ilock(ip);
    80006b3a:	ffffe097          	auipc	ra,0xffffe
    80006b3e:	f84080e7          	jalr	-124(ra) # 80004abe <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006b42:	04491703          	lh	a4,68(s2)
    80006b46:	4785                	li	a5,1
    80006b48:	f4f712e3          	bne	a4,a5,80006a8c <sys_open+0x60>
    80006b4c:	f4c42783          	lw	a5,-180(s0)
    80006b50:	dba1                	beqz	a5,80006aa0 <sys_open+0x74>
      iunlockput(ip);
    80006b52:	854a                	mv	a0,s2
    80006b54:	ffffe097          	auipc	ra,0xffffe
    80006b58:	1cc080e7          	jalr	460(ra) # 80004d20 <iunlockput>
      end_op();
    80006b5c:	fffff097          	auipc	ra,0xfffff
    80006b60:	9b4080e7          	jalr	-1612(ra) # 80005510 <end_op>
      return -1;
    80006b64:	54fd                	li	s1,-1
    80006b66:	b76d                	j	80006b10 <sys_open+0xe4>
      end_op();
    80006b68:	fffff097          	auipc	ra,0xfffff
    80006b6c:	9a8080e7          	jalr	-1624(ra) # 80005510 <end_op>
      return -1;
    80006b70:	54fd                	li	s1,-1
    80006b72:	bf79                	j	80006b10 <sys_open+0xe4>
    iunlockput(ip);
    80006b74:	854a                	mv	a0,s2
    80006b76:	ffffe097          	auipc	ra,0xffffe
    80006b7a:	1aa080e7          	jalr	426(ra) # 80004d20 <iunlockput>
    end_op();
    80006b7e:	fffff097          	auipc	ra,0xfffff
    80006b82:	992080e7          	jalr	-1646(ra) # 80005510 <end_op>
    return -1;
    80006b86:	54fd                	li	s1,-1
    80006b88:	b761                	j	80006b10 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006b8a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006b8e:	04691783          	lh	a5,70(s2)
    80006b92:	02f99223          	sh	a5,36(s3)
    80006b96:	bf2d                	j	80006ad0 <sys_open+0xa4>
    itrunc(ip);
    80006b98:	854a                	mv	a0,s2
    80006b9a:	ffffe097          	auipc	ra,0xffffe
    80006b9e:	032080e7          	jalr	50(ra) # 80004bcc <itrunc>
    80006ba2:	bfb1                	j	80006afe <sys_open+0xd2>
      fileclose(f);
    80006ba4:	854e                	mv	a0,s3
    80006ba6:	fffff097          	auipc	ra,0xfffff
    80006baa:	db6080e7          	jalr	-586(ra) # 8000595c <fileclose>
    iunlockput(ip);
    80006bae:	854a                	mv	a0,s2
    80006bb0:	ffffe097          	auipc	ra,0xffffe
    80006bb4:	170080e7          	jalr	368(ra) # 80004d20 <iunlockput>
    end_op();
    80006bb8:	fffff097          	auipc	ra,0xfffff
    80006bbc:	958080e7          	jalr	-1704(ra) # 80005510 <end_op>
    return -1;
    80006bc0:	54fd                	li	s1,-1
    80006bc2:	b7b9                	j	80006b10 <sys_open+0xe4>

0000000080006bc4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006bc4:	7175                	addi	sp,sp,-144
    80006bc6:	e506                	sd	ra,136(sp)
    80006bc8:	e122                	sd	s0,128(sp)
    80006bca:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006bcc:	fffff097          	auipc	ra,0xfffff
    80006bd0:	8c4080e7          	jalr	-1852(ra) # 80005490 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006bd4:	08000613          	li	a2,128
    80006bd8:	f7040593          	addi	a1,s0,-144
    80006bdc:	4501                	li	a0,0
    80006bde:	ffffd097          	auipc	ra,0xffffd
    80006be2:	306080e7          	jalr	774(ra) # 80003ee4 <argstr>
    80006be6:	02054963          	bltz	a0,80006c18 <sys_mkdir+0x54>
    80006bea:	4681                	li	a3,0
    80006bec:	4601                	li	a2,0
    80006bee:	4585                	li	a1,1
    80006bf0:	f7040513          	addi	a0,s0,-144
    80006bf4:	fffff097          	auipc	ra,0xfffff
    80006bf8:	7fc080e7          	jalr	2044(ra) # 800063f0 <create>
    80006bfc:	cd11                	beqz	a0,80006c18 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006bfe:	ffffe097          	auipc	ra,0xffffe
    80006c02:	122080e7          	jalr	290(ra) # 80004d20 <iunlockput>
  end_op();
    80006c06:	fffff097          	auipc	ra,0xfffff
    80006c0a:	90a080e7          	jalr	-1782(ra) # 80005510 <end_op>
  return 0;
    80006c0e:	4501                	li	a0,0
}
    80006c10:	60aa                	ld	ra,136(sp)
    80006c12:	640a                	ld	s0,128(sp)
    80006c14:	6149                	addi	sp,sp,144
    80006c16:	8082                	ret
    end_op();
    80006c18:	fffff097          	auipc	ra,0xfffff
    80006c1c:	8f8080e7          	jalr	-1800(ra) # 80005510 <end_op>
    return -1;
    80006c20:	557d                	li	a0,-1
    80006c22:	b7fd                	j	80006c10 <sys_mkdir+0x4c>

0000000080006c24 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006c24:	7135                	addi	sp,sp,-160
    80006c26:	ed06                	sd	ra,152(sp)
    80006c28:	e922                	sd	s0,144(sp)
    80006c2a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006c2c:	fffff097          	auipc	ra,0xfffff
    80006c30:	864080e7          	jalr	-1948(ra) # 80005490 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006c34:	08000613          	li	a2,128
    80006c38:	f7040593          	addi	a1,s0,-144
    80006c3c:	4501                	li	a0,0
    80006c3e:	ffffd097          	auipc	ra,0xffffd
    80006c42:	2a6080e7          	jalr	678(ra) # 80003ee4 <argstr>
    80006c46:	04054a63          	bltz	a0,80006c9a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006c4a:	f6c40593          	addi	a1,s0,-148
    80006c4e:	4505                	li	a0,1
    80006c50:	ffffd097          	auipc	ra,0xffffd
    80006c54:	250080e7          	jalr	592(ra) # 80003ea0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006c58:	04054163          	bltz	a0,80006c9a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006c5c:	f6840593          	addi	a1,s0,-152
    80006c60:	4509                	li	a0,2
    80006c62:	ffffd097          	auipc	ra,0xffffd
    80006c66:	23e080e7          	jalr	574(ra) # 80003ea0 <argint>
     argint(1, &major) < 0 ||
    80006c6a:	02054863          	bltz	a0,80006c9a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006c6e:	f6841683          	lh	a3,-152(s0)
    80006c72:	f6c41603          	lh	a2,-148(s0)
    80006c76:	458d                	li	a1,3
    80006c78:	f7040513          	addi	a0,s0,-144
    80006c7c:	fffff097          	auipc	ra,0xfffff
    80006c80:	774080e7          	jalr	1908(ra) # 800063f0 <create>
     argint(2, &minor) < 0 ||
    80006c84:	c919                	beqz	a0,80006c9a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006c86:	ffffe097          	auipc	ra,0xffffe
    80006c8a:	09a080e7          	jalr	154(ra) # 80004d20 <iunlockput>
  end_op();
    80006c8e:	fffff097          	auipc	ra,0xfffff
    80006c92:	882080e7          	jalr	-1918(ra) # 80005510 <end_op>
  return 0;
    80006c96:	4501                	li	a0,0
    80006c98:	a031                	j	80006ca4 <sys_mknod+0x80>
    end_op();
    80006c9a:	fffff097          	auipc	ra,0xfffff
    80006c9e:	876080e7          	jalr	-1930(ra) # 80005510 <end_op>
    return -1;
    80006ca2:	557d                	li	a0,-1
}
    80006ca4:	60ea                	ld	ra,152(sp)
    80006ca6:	644a                	ld	s0,144(sp)
    80006ca8:	610d                	addi	sp,sp,160
    80006caa:	8082                	ret

0000000080006cac <sys_chdir>:

uint64
sys_chdir(void)
{
    80006cac:	7135                	addi	sp,sp,-160
    80006cae:	ed06                	sd	ra,152(sp)
    80006cb0:	e922                	sd	s0,144(sp)
    80006cb2:	e526                	sd	s1,136(sp)
    80006cb4:	e14a                	sd	s2,128(sp)
    80006cb6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006cb8:	ffffb097          	auipc	ra,0xffffb
    80006cbc:	eec080e7          	jalr	-276(ra) # 80001ba4 <myproc>
    80006cc0:	892a                	mv	s2,a0
  
  begin_op();
    80006cc2:	ffffe097          	auipc	ra,0xffffe
    80006cc6:	7ce080e7          	jalr	1998(ra) # 80005490 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006cca:	08000613          	li	a2,128
    80006cce:	f6040593          	addi	a1,s0,-160
    80006cd2:	4501                	li	a0,0
    80006cd4:	ffffd097          	auipc	ra,0xffffd
    80006cd8:	210080e7          	jalr	528(ra) # 80003ee4 <argstr>
    80006cdc:	04054b63          	bltz	a0,80006d32 <sys_chdir+0x86>
    80006ce0:	f6040513          	addi	a0,s0,-160
    80006ce4:	ffffe097          	auipc	ra,0xffffe
    80006ce8:	590080e7          	jalr	1424(ra) # 80005274 <namei>
    80006cec:	84aa                	mv	s1,a0
    80006cee:	c131                	beqz	a0,80006d32 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006cf0:	ffffe097          	auipc	ra,0xffffe
    80006cf4:	dce080e7          	jalr	-562(ra) # 80004abe <ilock>
  if(ip->type != T_DIR){
    80006cf8:	04449703          	lh	a4,68(s1)
    80006cfc:	4785                	li	a5,1
    80006cfe:	04f71063          	bne	a4,a5,80006d3e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006d02:	8526                	mv	a0,s1
    80006d04:	ffffe097          	auipc	ra,0xffffe
    80006d08:	e7c080e7          	jalr	-388(ra) # 80004b80 <iunlock>
  iput(p->cwd);
    80006d0c:	18093503          	ld	a0,384(s2)
    80006d10:	ffffe097          	auipc	ra,0xffffe
    80006d14:	f68080e7          	jalr	-152(ra) # 80004c78 <iput>
  end_op();
    80006d18:	ffffe097          	auipc	ra,0xffffe
    80006d1c:	7f8080e7          	jalr	2040(ra) # 80005510 <end_op>
  p->cwd = ip;
    80006d20:	18993023          	sd	s1,384(s2)
  return 0;
    80006d24:	4501                	li	a0,0
}
    80006d26:	60ea                	ld	ra,152(sp)
    80006d28:	644a                	ld	s0,144(sp)
    80006d2a:	64aa                	ld	s1,136(sp)
    80006d2c:	690a                	ld	s2,128(sp)
    80006d2e:	610d                	addi	sp,sp,160
    80006d30:	8082                	ret
    end_op();
    80006d32:	ffffe097          	auipc	ra,0xffffe
    80006d36:	7de080e7          	jalr	2014(ra) # 80005510 <end_op>
    return -1;
    80006d3a:	557d                	li	a0,-1
    80006d3c:	b7ed                	j	80006d26 <sys_chdir+0x7a>
    iunlockput(ip);
    80006d3e:	8526                	mv	a0,s1
    80006d40:	ffffe097          	auipc	ra,0xffffe
    80006d44:	fe0080e7          	jalr	-32(ra) # 80004d20 <iunlockput>
    end_op();
    80006d48:	ffffe097          	auipc	ra,0xffffe
    80006d4c:	7c8080e7          	jalr	1992(ra) # 80005510 <end_op>
    return -1;
    80006d50:	557d                	li	a0,-1
    80006d52:	bfd1                	j	80006d26 <sys_chdir+0x7a>

0000000080006d54 <sys_exec>:

uint64
sys_exec(void)
{
    80006d54:	7145                	addi	sp,sp,-464
    80006d56:	e786                	sd	ra,456(sp)
    80006d58:	e3a2                	sd	s0,448(sp)
    80006d5a:	ff26                	sd	s1,440(sp)
    80006d5c:	fb4a                	sd	s2,432(sp)
    80006d5e:	f74e                	sd	s3,424(sp)
    80006d60:	f352                	sd	s4,416(sp)
    80006d62:	ef56                	sd	s5,408(sp)
    80006d64:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006d66:	08000613          	li	a2,128
    80006d6a:	f4040593          	addi	a1,s0,-192
    80006d6e:	4501                	li	a0,0
    80006d70:	ffffd097          	auipc	ra,0xffffd
    80006d74:	174080e7          	jalr	372(ra) # 80003ee4 <argstr>
    return -1;
    80006d78:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006d7a:	0c054a63          	bltz	a0,80006e4e <sys_exec+0xfa>
    80006d7e:	e3840593          	addi	a1,s0,-456
    80006d82:	4505                	li	a0,1
    80006d84:	ffffd097          	auipc	ra,0xffffd
    80006d88:	13e080e7          	jalr	318(ra) # 80003ec2 <argaddr>
    80006d8c:	0c054163          	bltz	a0,80006e4e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006d90:	10000613          	li	a2,256
    80006d94:	4581                	li	a1,0
    80006d96:	e4040513          	addi	a0,s0,-448
    80006d9a:	ffffa097          	auipc	ra,0xffffa
    80006d9e:	f46080e7          	jalr	-186(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006da2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006da6:	89a6                	mv	s3,s1
    80006da8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006daa:	02000a13          	li	s4,32
    80006dae:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006db2:	00391513          	slli	a0,s2,0x3
    80006db6:	e3040593          	addi	a1,s0,-464
    80006dba:	e3843783          	ld	a5,-456(s0)
    80006dbe:	953e                	add	a0,a0,a5
    80006dc0:	ffffd097          	auipc	ra,0xffffd
    80006dc4:	046080e7          	jalr	70(ra) # 80003e06 <fetchaddr>
    80006dc8:	02054a63          	bltz	a0,80006dfc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006dcc:	e3043783          	ld	a5,-464(s0)
    80006dd0:	c3b9                	beqz	a5,80006e16 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006dd2:	ffffa097          	auipc	ra,0xffffa
    80006dd6:	d22080e7          	jalr	-734(ra) # 80000af4 <kalloc>
    80006dda:	85aa                	mv	a1,a0
    80006ddc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006de0:	cd11                	beqz	a0,80006dfc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006de2:	6605                	lui	a2,0x1
    80006de4:	e3043503          	ld	a0,-464(s0)
    80006de8:	ffffd097          	auipc	ra,0xffffd
    80006dec:	070080e7          	jalr	112(ra) # 80003e58 <fetchstr>
    80006df0:	00054663          	bltz	a0,80006dfc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006df4:	0905                	addi	s2,s2,1
    80006df6:	09a1                	addi	s3,s3,8
    80006df8:	fb491be3          	bne	s2,s4,80006dae <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006dfc:	10048913          	addi	s2,s1,256
    80006e00:	6088                	ld	a0,0(s1)
    80006e02:	c529                	beqz	a0,80006e4c <sys_exec+0xf8>
    kfree(argv[i]);
    80006e04:	ffffa097          	auipc	ra,0xffffa
    80006e08:	bf4080e7          	jalr	-1036(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e0c:	04a1                	addi	s1,s1,8
    80006e0e:	ff2499e3          	bne	s1,s2,80006e00 <sys_exec+0xac>
  return -1;
    80006e12:	597d                	li	s2,-1
    80006e14:	a82d                	j	80006e4e <sys_exec+0xfa>
      argv[i] = 0;
    80006e16:	0a8e                	slli	s5,s5,0x3
    80006e18:	fc040793          	addi	a5,s0,-64
    80006e1c:	9abe                	add	s5,s5,a5
    80006e1e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006e22:	e4040593          	addi	a1,s0,-448
    80006e26:	f4040513          	addi	a0,s0,-192
    80006e2a:	fffff097          	auipc	ra,0xfffff
    80006e2e:	192080e7          	jalr	402(ra) # 80005fbc <exec>
    80006e32:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e34:	10048993          	addi	s3,s1,256
    80006e38:	6088                	ld	a0,0(s1)
    80006e3a:	c911                	beqz	a0,80006e4e <sys_exec+0xfa>
    kfree(argv[i]);
    80006e3c:	ffffa097          	auipc	ra,0xffffa
    80006e40:	bbc080e7          	jalr	-1092(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e44:	04a1                	addi	s1,s1,8
    80006e46:	ff3499e3          	bne	s1,s3,80006e38 <sys_exec+0xe4>
    80006e4a:	a011                	j	80006e4e <sys_exec+0xfa>
  return -1;
    80006e4c:	597d                	li	s2,-1
}
    80006e4e:	854a                	mv	a0,s2
    80006e50:	60be                	ld	ra,456(sp)
    80006e52:	641e                	ld	s0,448(sp)
    80006e54:	74fa                	ld	s1,440(sp)
    80006e56:	795a                	ld	s2,432(sp)
    80006e58:	79ba                	ld	s3,424(sp)
    80006e5a:	7a1a                	ld	s4,416(sp)
    80006e5c:	6afa                	ld	s5,408(sp)
    80006e5e:	6179                	addi	sp,sp,464
    80006e60:	8082                	ret

0000000080006e62 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006e62:	7139                	addi	sp,sp,-64
    80006e64:	fc06                	sd	ra,56(sp)
    80006e66:	f822                	sd	s0,48(sp)
    80006e68:	f426                	sd	s1,40(sp)
    80006e6a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006e6c:	ffffb097          	auipc	ra,0xffffb
    80006e70:	d38080e7          	jalr	-712(ra) # 80001ba4 <myproc>
    80006e74:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006e76:	fd840593          	addi	a1,s0,-40
    80006e7a:	4501                	li	a0,0
    80006e7c:	ffffd097          	auipc	ra,0xffffd
    80006e80:	046080e7          	jalr	70(ra) # 80003ec2 <argaddr>
    return -1;
    80006e84:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006e86:	0e054263          	bltz	a0,80006f6a <sys_pipe+0x108>
  if(pipealloc(&rf, &wf) < 0)
    80006e8a:	fc840593          	addi	a1,s0,-56
    80006e8e:	fd040513          	addi	a0,s0,-48
    80006e92:	fffff097          	auipc	ra,0xfffff
    80006e96:	dfa080e7          	jalr	-518(ra) # 80005c8c <pipealloc>
    return -1;
    80006e9a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006e9c:	0c054763          	bltz	a0,80006f6a <sys_pipe+0x108>
  fd0 = -1;
    80006ea0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006ea4:	fd043503          	ld	a0,-48(s0)
    80006ea8:	fffff097          	auipc	ra,0xfffff
    80006eac:	506080e7          	jalr	1286(ra) # 800063ae <fdalloc>
    80006eb0:	fca42223          	sw	a0,-60(s0)
    80006eb4:	08054e63          	bltz	a0,80006f50 <sys_pipe+0xee>
    80006eb8:	fc843503          	ld	a0,-56(s0)
    80006ebc:	fffff097          	auipc	ra,0xfffff
    80006ec0:	4f2080e7          	jalr	1266(ra) # 800063ae <fdalloc>
    80006ec4:	fca42023          	sw	a0,-64(s0)
    80006ec8:	06054a63          	bltz	a0,80006f3c <sys_pipe+0xda>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006ecc:	4691                	li	a3,4
    80006ece:	fc440613          	addi	a2,s0,-60
    80006ed2:	fd843583          	ld	a1,-40(s0)
    80006ed6:	60c8                	ld	a0,128(s1)
    80006ed8:	ffffa097          	auipc	ra,0xffffa
    80006edc:	7a2080e7          	jalr	1954(ra) # 8000167a <copyout>
    80006ee0:	02054063          	bltz	a0,80006f00 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006ee4:	4691                	li	a3,4
    80006ee6:	fc040613          	addi	a2,s0,-64
    80006eea:	fd843583          	ld	a1,-40(s0)
    80006eee:	0591                	addi	a1,a1,4
    80006ef0:	60c8                	ld	a0,128(s1)
    80006ef2:	ffffa097          	auipc	ra,0xffffa
    80006ef6:	788080e7          	jalr	1928(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006efa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006efc:	06055763          	bgez	a0,80006f6a <sys_pipe+0x108>
    p->ofile[fd0] = 0;
    80006f00:	fc442783          	lw	a5,-60(s0)
    80006f04:	02078793          	addi	a5,a5,32
    80006f08:	078e                	slli	a5,a5,0x3
    80006f0a:	97a6                	add	a5,a5,s1
    80006f0c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006f10:	fc042503          	lw	a0,-64(s0)
    80006f14:	02050513          	addi	a0,a0,32
    80006f18:	050e                	slli	a0,a0,0x3
    80006f1a:	9526                	add	a0,a0,s1
    80006f1c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006f20:	fd043503          	ld	a0,-48(s0)
    80006f24:	fffff097          	auipc	ra,0xfffff
    80006f28:	a38080e7          	jalr	-1480(ra) # 8000595c <fileclose>
    fileclose(wf);
    80006f2c:	fc843503          	ld	a0,-56(s0)
    80006f30:	fffff097          	auipc	ra,0xfffff
    80006f34:	a2c080e7          	jalr	-1492(ra) # 8000595c <fileclose>
    return -1;
    80006f38:	57fd                	li	a5,-1
    80006f3a:	a805                	j	80006f6a <sys_pipe+0x108>
    if(fd0 >= 0)
    80006f3c:	fc442783          	lw	a5,-60(s0)
    80006f40:	0007c863          	bltz	a5,80006f50 <sys_pipe+0xee>
      p->ofile[fd0] = 0;
    80006f44:	02078513          	addi	a0,a5,32
    80006f48:	050e                	slli	a0,a0,0x3
    80006f4a:	9526                	add	a0,a0,s1
    80006f4c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006f50:	fd043503          	ld	a0,-48(s0)
    80006f54:	fffff097          	auipc	ra,0xfffff
    80006f58:	a08080e7          	jalr	-1528(ra) # 8000595c <fileclose>
    fileclose(wf);
    80006f5c:	fc843503          	ld	a0,-56(s0)
    80006f60:	fffff097          	auipc	ra,0xfffff
    80006f64:	9fc080e7          	jalr	-1540(ra) # 8000595c <fileclose>
    return -1;
    80006f68:	57fd                	li	a5,-1
}
    80006f6a:	853e                	mv	a0,a5
    80006f6c:	70e2                	ld	ra,56(sp)
    80006f6e:	7442                	ld	s0,48(sp)
    80006f70:	74a2                	ld	s1,40(sp)
    80006f72:	6121                	addi	sp,sp,64
    80006f74:	8082                	ret
	...

0000000080006f80 <kernelvec>:
    80006f80:	7111                	addi	sp,sp,-256
    80006f82:	e006                	sd	ra,0(sp)
    80006f84:	e40a                	sd	sp,8(sp)
    80006f86:	e80e                	sd	gp,16(sp)
    80006f88:	ec12                	sd	tp,24(sp)
    80006f8a:	f016                	sd	t0,32(sp)
    80006f8c:	f41a                	sd	t1,40(sp)
    80006f8e:	f81e                	sd	t2,48(sp)
    80006f90:	fc22                	sd	s0,56(sp)
    80006f92:	e0a6                	sd	s1,64(sp)
    80006f94:	e4aa                	sd	a0,72(sp)
    80006f96:	e8ae                	sd	a1,80(sp)
    80006f98:	ecb2                	sd	a2,88(sp)
    80006f9a:	f0b6                	sd	a3,96(sp)
    80006f9c:	f4ba                	sd	a4,104(sp)
    80006f9e:	f8be                	sd	a5,112(sp)
    80006fa0:	fcc2                	sd	a6,120(sp)
    80006fa2:	e146                	sd	a7,128(sp)
    80006fa4:	e54a                	sd	s2,136(sp)
    80006fa6:	e94e                	sd	s3,144(sp)
    80006fa8:	ed52                	sd	s4,152(sp)
    80006faa:	f156                	sd	s5,160(sp)
    80006fac:	f55a                	sd	s6,168(sp)
    80006fae:	f95e                	sd	s7,176(sp)
    80006fb0:	fd62                	sd	s8,184(sp)
    80006fb2:	e1e6                	sd	s9,192(sp)
    80006fb4:	e5ea                	sd	s10,200(sp)
    80006fb6:	e9ee                	sd	s11,208(sp)
    80006fb8:	edf2                	sd	t3,216(sp)
    80006fba:	f1f6                	sd	t4,224(sp)
    80006fbc:	f5fa                	sd	t5,232(sp)
    80006fbe:	f9fe                	sd	t6,240(sp)
    80006fc0:	ce7fc0ef          	jal	ra,80003ca6 <kerneltrap>
    80006fc4:	6082                	ld	ra,0(sp)
    80006fc6:	6122                	ld	sp,8(sp)
    80006fc8:	61c2                	ld	gp,16(sp)
    80006fca:	7282                	ld	t0,32(sp)
    80006fcc:	7322                	ld	t1,40(sp)
    80006fce:	73c2                	ld	t2,48(sp)
    80006fd0:	7462                	ld	s0,56(sp)
    80006fd2:	6486                	ld	s1,64(sp)
    80006fd4:	6526                	ld	a0,72(sp)
    80006fd6:	65c6                	ld	a1,80(sp)
    80006fd8:	6666                	ld	a2,88(sp)
    80006fda:	7686                	ld	a3,96(sp)
    80006fdc:	7726                	ld	a4,104(sp)
    80006fde:	77c6                	ld	a5,112(sp)
    80006fe0:	7866                	ld	a6,120(sp)
    80006fe2:	688a                	ld	a7,128(sp)
    80006fe4:	692a                	ld	s2,136(sp)
    80006fe6:	69ca                	ld	s3,144(sp)
    80006fe8:	6a6a                	ld	s4,152(sp)
    80006fea:	7a8a                	ld	s5,160(sp)
    80006fec:	7b2a                	ld	s6,168(sp)
    80006fee:	7bca                	ld	s7,176(sp)
    80006ff0:	7c6a                	ld	s8,184(sp)
    80006ff2:	6c8e                	ld	s9,192(sp)
    80006ff4:	6d2e                	ld	s10,200(sp)
    80006ff6:	6dce                	ld	s11,208(sp)
    80006ff8:	6e6e                	ld	t3,216(sp)
    80006ffa:	7e8e                	ld	t4,224(sp)
    80006ffc:	7f2e                	ld	t5,232(sp)
    80006ffe:	7fce                	ld	t6,240(sp)
    80007000:	6111                	addi	sp,sp,256
    80007002:	10200073          	sret
    80007006:	00000013          	nop
    8000700a:	00000013          	nop
    8000700e:	0001                	nop

0000000080007010 <timervec>:
    80007010:	34051573          	csrrw	a0,mscratch,a0
    80007014:	e10c                	sd	a1,0(a0)
    80007016:	e510                	sd	a2,8(a0)
    80007018:	e914                	sd	a3,16(a0)
    8000701a:	6d0c                	ld	a1,24(a0)
    8000701c:	7110                	ld	a2,32(a0)
    8000701e:	6194                	ld	a3,0(a1)
    80007020:	96b2                	add	a3,a3,a2
    80007022:	e194                	sd	a3,0(a1)
    80007024:	4589                	li	a1,2
    80007026:	14459073          	csrw	sip,a1
    8000702a:	6914                	ld	a3,16(a0)
    8000702c:	6510                	ld	a2,8(a0)
    8000702e:	610c                	ld	a1,0(a0)
    80007030:	34051573          	csrrw	a0,mscratch,a0
    80007034:	30200073          	mret
	...

000000008000703a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000703a:	1141                	addi	sp,sp,-16
    8000703c:	e422                	sd	s0,8(sp)
    8000703e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80007040:	0c0007b7          	lui	a5,0xc000
    80007044:	4705                	li	a4,1
    80007046:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80007048:	c3d8                	sw	a4,4(a5)
}
    8000704a:	6422                	ld	s0,8(sp)
    8000704c:	0141                	addi	sp,sp,16
    8000704e:	8082                	ret

0000000080007050 <plicinithart>:

void
plicinithart(void)
{
    80007050:	1141                	addi	sp,sp,-16
    80007052:	e406                	sd	ra,8(sp)
    80007054:	e022                	sd	s0,0(sp)
    80007056:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80007058:	ffffb097          	auipc	ra,0xffffb
    8000705c:	b04080e7          	jalr	-1276(ra) # 80001b5c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80007060:	0085171b          	slliw	a4,a0,0x8
    80007064:	0c0027b7          	lui	a5,0xc002
    80007068:	97ba                	add	a5,a5,a4
    8000706a:	40200713          	li	a4,1026
    8000706e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80007072:	00d5151b          	slliw	a0,a0,0xd
    80007076:	0c2017b7          	lui	a5,0xc201
    8000707a:	953e                	add	a0,a0,a5
    8000707c:	00052023          	sw	zero,0(a0)
}
    80007080:	60a2                	ld	ra,8(sp)
    80007082:	6402                	ld	s0,0(sp)
    80007084:	0141                	addi	sp,sp,16
    80007086:	8082                	ret

0000000080007088 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80007088:	1141                	addi	sp,sp,-16
    8000708a:	e406                	sd	ra,8(sp)
    8000708c:	e022                	sd	s0,0(sp)
    8000708e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80007090:	ffffb097          	auipc	ra,0xffffb
    80007094:	acc080e7          	jalr	-1332(ra) # 80001b5c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80007098:	00d5179b          	slliw	a5,a0,0xd
    8000709c:	0c201537          	lui	a0,0xc201
    800070a0:	953e                	add	a0,a0,a5
  return irq;
}
    800070a2:	4148                	lw	a0,4(a0)
    800070a4:	60a2                	ld	ra,8(sp)
    800070a6:	6402                	ld	s0,0(sp)
    800070a8:	0141                	addi	sp,sp,16
    800070aa:	8082                	ret

00000000800070ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800070ac:	1101                	addi	sp,sp,-32
    800070ae:	ec06                	sd	ra,24(sp)
    800070b0:	e822                	sd	s0,16(sp)
    800070b2:	e426                	sd	s1,8(sp)
    800070b4:	1000                	addi	s0,sp,32
    800070b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800070b8:	ffffb097          	auipc	ra,0xffffb
    800070bc:	aa4080e7          	jalr	-1372(ra) # 80001b5c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800070c0:	00d5151b          	slliw	a0,a0,0xd
    800070c4:	0c2017b7          	lui	a5,0xc201
    800070c8:	97aa                	add	a5,a5,a0
    800070ca:	c3c4                	sw	s1,4(a5)
}
    800070cc:	60e2                	ld	ra,24(sp)
    800070ce:	6442                	ld	s0,16(sp)
    800070d0:	64a2                	ld	s1,8(sp)
    800070d2:	6105                	addi	sp,sp,32
    800070d4:	8082                	ret

00000000800070d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800070d6:	1141                	addi	sp,sp,-16
    800070d8:	e406                	sd	ra,8(sp)
    800070da:	e022                	sd	s0,0(sp)
    800070dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800070de:	479d                	li	a5,7
    800070e0:	06a7c963          	blt	a5,a0,80007152 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800070e4:	0001e797          	auipc	a5,0x1e
    800070e8:	f1c78793          	addi	a5,a5,-228 # 80025000 <disk>
    800070ec:	00a78733          	add	a4,a5,a0
    800070f0:	6789                	lui	a5,0x2
    800070f2:	97ba                	add	a5,a5,a4
    800070f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800070f8:	e7ad                	bnez	a5,80007162 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800070fa:	00451793          	slli	a5,a0,0x4
    800070fe:	00020717          	auipc	a4,0x20
    80007102:	f0270713          	addi	a4,a4,-254 # 80027000 <disk+0x2000>
    80007106:	6314                	ld	a3,0(a4)
    80007108:	96be                	add	a3,a3,a5
    8000710a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000710e:	6314                	ld	a3,0(a4)
    80007110:	96be                	add	a3,a3,a5
    80007112:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80007116:	6314                	ld	a3,0(a4)
    80007118:	96be                	add	a3,a3,a5
    8000711a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000711e:	6318                	ld	a4,0(a4)
    80007120:	97ba                	add	a5,a5,a4
    80007122:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80007126:	0001e797          	auipc	a5,0x1e
    8000712a:	eda78793          	addi	a5,a5,-294 # 80025000 <disk>
    8000712e:	97aa                	add	a5,a5,a0
    80007130:	6509                	lui	a0,0x2
    80007132:	953e                	add	a0,a0,a5
    80007134:	4785                	li	a5,1
    80007136:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000713a:	00020517          	auipc	a0,0x20
    8000713e:	ede50513          	addi	a0,a0,-290 # 80027018 <disk+0x2018>
    80007142:	ffffc097          	auipc	ra,0xffffc
    80007146:	e22080e7          	jalr	-478(ra) # 80002f64 <wakeup>
}
    8000714a:	60a2                	ld	ra,8(sp)
    8000714c:	6402                	ld	s0,0(sp)
    8000714e:	0141                	addi	sp,sp,16
    80007150:	8082                	ret
    panic("free_desc 1");
    80007152:	00002517          	auipc	a0,0x2
    80007156:	7ae50513          	addi	a0,a0,1966 # 80009900 <syscalls+0x348>
    8000715a:	ffff9097          	auipc	ra,0xffff9
    8000715e:	3e4080e7          	jalr	996(ra) # 8000053e <panic>
    panic("free_desc 2");
    80007162:	00002517          	auipc	a0,0x2
    80007166:	7ae50513          	addi	a0,a0,1966 # 80009910 <syscalls+0x358>
    8000716a:	ffff9097          	auipc	ra,0xffff9
    8000716e:	3d4080e7          	jalr	980(ra) # 8000053e <panic>

0000000080007172 <virtio_disk_init>:
{
    80007172:	1101                	addi	sp,sp,-32
    80007174:	ec06                	sd	ra,24(sp)
    80007176:	e822                	sd	s0,16(sp)
    80007178:	e426                	sd	s1,8(sp)
    8000717a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000717c:	00002597          	auipc	a1,0x2
    80007180:	7a458593          	addi	a1,a1,1956 # 80009920 <syscalls+0x368>
    80007184:	00020517          	auipc	a0,0x20
    80007188:	fa450513          	addi	a0,a0,-92 # 80027128 <disk+0x2128>
    8000718c:	ffffa097          	auipc	ra,0xffffa
    80007190:	9c8080e7          	jalr	-1592(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80007194:	100017b7          	lui	a5,0x10001
    80007198:	4398                	lw	a4,0(a5)
    8000719a:	2701                	sext.w	a4,a4
    8000719c:	747277b7          	lui	a5,0x74727
    800071a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800071a4:	0ef71163          	bne	a4,a5,80007286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800071a8:	100017b7          	lui	a5,0x10001
    800071ac:	43dc                	lw	a5,4(a5)
    800071ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800071b0:	4705                	li	a4,1
    800071b2:	0ce79a63          	bne	a5,a4,80007286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800071b6:	100017b7          	lui	a5,0x10001
    800071ba:	479c                	lw	a5,8(a5)
    800071bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800071be:	4709                	li	a4,2
    800071c0:	0ce79363          	bne	a5,a4,80007286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800071c4:	100017b7          	lui	a5,0x10001
    800071c8:	47d8                	lw	a4,12(a5)
    800071ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800071cc:	554d47b7          	lui	a5,0x554d4
    800071d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800071d4:	0af71963          	bne	a4,a5,80007286 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800071d8:	100017b7          	lui	a5,0x10001
    800071dc:	4705                	li	a4,1
    800071de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800071e0:	470d                	li	a4,3
    800071e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800071e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800071e6:	c7ffe737          	lui	a4,0xc7ffe
    800071ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    800071ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800071f0:	2701                	sext.w	a4,a4
    800071f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800071f4:	472d                	li	a4,11
    800071f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800071f8:	473d                	li	a4,15
    800071fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800071fc:	6705                	lui	a4,0x1
    800071fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80007200:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80007204:	5bdc                	lw	a5,52(a5)
    80007206:	2781                	sext.w	a5,a5
  if(max == 0)
    80007208:	c7d9                	beqz	a5,80007296 <virtio_disk_init+0x124>
  if(max < NUM)
    8000720a:	471d                	li	a4,7
    8000720c:	08f77d63          	bgeu	a4,a5,800072a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80007210:	100014b7          	lui	s1,0x10001
    80007214:	47a1                	li	a5,8
    80007216:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80007218:	6609                	lui	a2,0x2
    8000721a:	4581                	li	a1,0
    8000721c:	0001e517          	auipc	a0,0x1e
    80007220:	de450513          	addi	a0,a0,-540 # 80025000 <disk>
    80007224:	ffffa097          	auipc	ra,0xffffa
    80007228:	abc080e7          	jalr	-1348(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000722c:	0001e717          	auipc	a4,0x1e
    80007230:	dd470713          	addi	a4,a4,-556 # 80025000 <disk>
    80007234:	00c75793          	srli	a5,a4,0xc
    80007238:	2781                	sext.w	a5,a5
    8000723a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000723c:	00020797          	auipc	a5,0x20
    80007240:	dc478793          	addi	a5,a5,-572 # 80027000 <disk+0x2000>
    80007244:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80007246:	0001e717          	auipc	a4,0x1e
    8000724a:	e3a70713          	addi	a4,a4,-454 # 80025080 <disk+0x80>
    8000724e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80007250:	0001f717          	auipc	a4,0x1f
    80007254:	db070713          	addi	a4,a4,-592 # 80026000 <disk+0x1000>
    80007258:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000725a:	4705                	li	a4,1
    8000725c:	00e78c23          	sb	a4,24(a5)
    80007260:	00e78ca3          	sb	a4,25(a5)
    80007264:	00e78d23          	sb	a4,26(a5)
    80007268:	00e78da3          	sb	a4,27(a5)
    8000726c:	00e78e23          	sb	a4,28(a5)
    80007270:	00e78ea3          	sb	a4,29(a5)
    80007274:	00e78f23          	sb	a4,30(a5)
    80007278:	00e78fa3          	sb	a4,31(a5)
}
    8000727c:	60e2                	ld	ra,24(sp)
    8000727e:	6442                	ld	s0,16(sp)
    80007280:	64a2                	ld	s1,8(sp)
    80007282:	6105                	addi	sp,sp,32
    80007284:	8082                	ret
    panic("could not find virtio disk");
    80007286:	00002517          	auipc	a0,0x2
    8000728a:	6aa50513          	addi	a0,a0,1706 # 80009930 <syscalls+0x378>
    8000728e:	ffff9097          	auipc	ra,0xffff9
    80007292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80007296:	00002517          	auipc	a0,0x2
    8000729a:	6ba50513          	addi	a0,a0,1722 # 80009950 <syscalls+0x398>
    8000729e:	ffff9097          	auipc	ra,0xffff9
    800072a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800072a6:	00002517          	auipc	a0,0x2
    800072aa:	6ca50513          	addi	a0,a0,1738 # 80009970 <syscalls+0x3b8>
    800072ae:	ffff9097          	auipc	ra,0xffff9
    800072b2:	290080e7          	jalr	656(ra) # 8000053e <panic>

00000000800072b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800072b6:	7159                	addi	sp,sp,-112
    800072b8:	f486                	sd	ra,104(sp)
    800072ba:	f0a2                	sd	s0,96(sp)
    800072bc:	eca6                	sd	s1,88(sp)
    800072be:	e8ca                	sd	s2,80(sp)
    800072c0:	e4ce                	sd	s3,72(sp)
    800072c2:	e0d2                	sd	s4,64(sp)
    800072c4:	fc56                	sd	s5,56(sp)
    800072c6:	f85a                	sd	s6,48(sp)
    800072c8:	f45e                	sd	s7,40(sp)
    800072ca:	f062                	sd	s8,32(sp)
    800072cc:	ec66                	sd	s9,24(sp)
    800072ce:	e86a                	sd	s10,16(sp)
    800072d0:	1880                	addi	s0,sp,112
    800072d2:	892a                	mv	s2,a0
    800072d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800072d6:	00c52c83          	lw	s9,12(a0)
    800072da:	001c9c9b          	slliw	s9,s9,0x1
    800072de:	1c82                	slli	s9,s9,0x20
    800072e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800072e4:	00020517          	auipc	a0,0x20
    800072e8:	e4450513          	addi	a0,a0,-444 # 80027128 <disk+0x2128>
    800072ec:	ffffa097          	auipc	ra,0xffffa
    800072f0:	8f8080e7          	jalr	-1800(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800072f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800072f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800072f8:	0001eb97          	auipc	s7,0x1e
    800072fc:	d08b8b93          	addi	s7,s7,-760 # 80025000 <disk>
    80007300:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80007302:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80007304:	8a4e                	mv	s4,s3
    80007306:	a051                	j	8000738a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80007308:	00fb86b3          	add	a3,s7,a5
    8000730c:	96da                	add	a3,a3,s6
    8000730e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80007312:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80007314:	0207c563          	bltz	a5,8000733e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80007318:	2485                	addiw	s1,s1,1
    8000731a:	0711                	addi	a4,a4,4
    8000731c:	25548063          	beq	s1,s5,8000755c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80007320:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80007322:	00020697          	auipc	a3,0x20
    80007326:	cf668693          	addi	a3,a3,-778 # 80027018 <disk+0x2018>
    8000732a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000732c:	0006c583          	lbu	a1,0(a3)
    80007330:	fde1                	bnez	a1,80007308 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80007332:	2785                	addiw	a5,a5,1
    80007334:	0685                	addi	a3,a3,1
    80007336:	ff879be3          	bne	a5,s8,8000732c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000733a:	57fd                	li	a5,-1
    8000733c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000733e:	02905a63          	blez	s1,80007372 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007342:	f9042503          	lw	a0,-112(s0)
    80007346:	00000097          	auipc	ra,0x0
    8000734a:	d90080e7          	jalr	-624(ra) # 800070d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000734e:	4785                	li	a5,1
    80007350:	0297d163          	bge	a5,s1,80007372 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007354:	f9442503          	lw	a0,-108(s0)
    80007358:	00000097          	auipc	ra,0x0
    8000735c:	d7e080e7          	jalr	-642(ra) # 800070d6 <free_desc>
      for(int j = 0; j < i; j++)
    80007360:	4789                	li	a5,2
    80007362:	0097d863          	bge	a5,s1,80007372 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007366:	f9842503          	lw	a0,-104(s0)
    8000736a:	00000097          	auipc	ra,0x0
    8000736e:	d6c080e7          	jalr	-660(ra) # 800070d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80007372:	00020597          	auipc	a1,0x20
    80007376:	db658593          	addi	a1,a1,-586 # 80027128 <disk+0x2128>
    8000737a:	00020517          	auipc	a0,0x20
    8000737e:	c9e50513          	addi	a0,a0,-866 # 80027018 <disk+0x2018>
    80007382:	ffffc097          	auipc	ra,0xffffc
    80007386:	88c080e7          	jalr	-1908(ra) # 80002c0e <sleep>
  for(int i = 0; i < 3; i++){
    8000738a:	f9040713          	addi	a4,s0,-112
    8000738e:	84ce                	mv	s1,s3
    80007390:	bf41                	j	80007320 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80007392:	20058713          	addi	a4,a1,512
    80007396:	00471693          	slli	a3,a4,0x4
    8000739a:	0001e717          	auipc	a4,0x1e
    8000739e:	c6670713          	addi	a4,a4,-922 # 80025000 <disk>
    800073a2:	9736                	add	a4,a4,a3
    800073a4:	4685                	li	a3,1
    800073a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800073aa:	20058713          	addi	a4,a1,512
    800073ae:	00471693          	slli	a3,a4,0x4
    800073b2:	0001e717          	auipc	a4,0x1e
    800073b6:	c4e70713          	addi	a4,a4,-946 # 80025000 <disk>
    800073ba:	9736                	add	a4,a4,a3
    800073bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800073c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800073c4:	7679                	lui	a2,0xffffe
    800073c6:	963e                	add	a2,a2,a5
    800073c8:	00020697          	auipc	a3,0x20
    800073cc:	c3868693          	addi	a3,a3,-968 # 80027000 <disk+0x2000>
    800073d0:	6298                	ld	a4,0(a3)
    800073d2:	9732                	add	a4,a4,a2
    800073d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800073d6:	6298                	ld	a4,0(a3)
    800073d8:	9732                	add	a4,a4,a2
    800073da:	4541                	li	a0,16
    800073dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800073de:	6298                	ld	a4,0(a3)
    800073e0:	9732                	add	a4,a4,a2
    800073e2:	4505                	li	a0,1
    800073e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800073e8:	f9442703          	lw	a4,-108(s0)
    800073ec:	6288                	ld	a0,0(a3)
    800073ee:	962a                	add	a2,a2,a0
    800073f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800073f4:	0712                	slli	a4,a4,0x4
    800073f6:	6290                	ld	a2,0(a3)
    800073f8:	963a                	add	a2,a2,a4
    800073fa:	05890513          	addi	a0,s2,88
    800073fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80007400:	6294                	ld	a3,0(a3)
    80007402:	96ba                	add	a3,a3,a4
    80007404:	40000613          	li	a2,1024
    80007408:	c690                	sw	a2,8(a3)
  if(write)
    8000740a:	140d0063          	beqz	s10,8000754a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000740e:	00020697          	auipc	a3,0x20
    80007412:	bf26b683          	ld	a3,-1038(a3) # 80027000 <disk+0x2000>
    80007416:	96ba                	add	a3,a3,a4
    80007418:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000741c:	0001e817          	auipc	a6,0x1e
    80007420:	be480813          	addi	a6,a6,-1052 # 80025000 <disk>
    80007424:	00020517          	auipc	a0,0x20
    80007428:	bdc50513          	addi	a0,a0,-1060 # 80027000 <disk+0x2000>
    8000742c:	6114                	ld	a3,0(a0)
    8000742e:	96ba                	add	a3,a3,a4
    80007430:	00c6d603          	lhu	a2,12(a3)
    80007434:	00166613          	ori	a2,a2,1
    80007438:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000743c:	f9842683          	lw	a3,-104(s0)
    80007440:	6110                	ld	a2,0(a0)
    80007442:	9732                	add	a4,a4,a2
    80007444:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80007448:	20058613          	addi	a2,a1,512
    8000744c:	0612                	slli	a2,a2,0x4
    8000744e:	9642                	add	a2,a2,a6
    80007450:	577d                	li	a4,-1
    80007452:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80007456:	00469713          	slli	a4,a3,0x4
    8000745a:	6114                	ld	a3,0(a0)
    8000745c:	96ba                	add	a3,a3,a4
    8000745e:	03078793          	addi	a5,a5,48
    80007462:	97c2                	add	a5,a5,a6
    80007464:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80007466:	611c                	ld	a5,0(a0)
    80007468:	97ba                	add	a5,a5,a4
    8000746a:	4685                	li	a3,1
    8000746c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000746e:	611c                	ld	a5,0(a0)
    80007470:	97ba                	add	a5,a5,a4
    80007472:	4809                	li	a6,2
    80007474:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80007478:	611c                	ld	a5,0(a0)
    8000747a:	973e                	add	a4,a4,a5
    8000747c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80007480:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80007484:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80007488:	6518                	ld	a4,8(a0)
    8000748a:	00275783          	lhu	a5,2(a4)
    8000748e:	8b9d                	andi	a5,a5,7
    80007490:	0786                	slli	a5,a5,0x1
    80007492:	97ba                	add	a5,a5,a4
    80007494:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80007498:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000749c:	6518                	ld	a4,8(a0)
    8000749e:	00275783          	lhu	a5,2(a4)
    800074a2:	2785                	addiw	a5,a5,1
    800074a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800074a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800074ac:	100017b7          	lui	a5,0x10001
    800074b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800074b4:	00492703          	lw	a4,4(s2)
    800074b8:	4785                	li	a5,1
    800074ba:	02f71163          	bne	a4,a5,800074dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800074be:	00020997          	auipc	s3,0x20
    800074c2:	c6a98993          	addi	s3,s3,-918 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    800074c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800074c8:	85ce                	mv	a1,s3
    800074ca:	854a                	mv	a0,s2
    800074cc:	ffffb097          	auipc	ra,0xffffb
    800074d0:	742080e7          	jalr	1858(ra) # 80002c0e <sleep>
  while(b->disk == 1) {
    800074d4:	00492783          	lw	a5,4(s2)
    800074d8:	fe9788e3          	beq	a5,s1,800074c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800074dc:	f9042903          	lw	s2,-112(s0)
    800074e0:	20090793          	addi	a5,s2,512
    800074e4:	00479713          	slli	a4,a5,0x4
    800074e8:	0001e797          	auipc	a5,0x1e
    800074ec:	b1878793          	addi	a5,a5,-1256 # 80025000 <disk>
    800074f0:	97ba                	add	a5,a5,a4
    800074f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800074f6:	00020997          	auipc	s3,0x20
    800074fa:	b0a98993          	addi	s3,s3,-1270 # 80027000 <disk+0x2000>
    800074fe:	00491713          	slli	a4,s2,0x4
    80007502:	0009b783          	ld	a5,0(s3)
    80007506:	97ba                	add	a5,a5,a4
    80007508:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000750c:	854a                	mv	a0,s2
    8000750e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80007512:	00000097          	auipc	ra,0x0
    80007516:	bc4080e7          	jalr	-1084(ra) # 800070d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000751a:	8885                	andi	s1,s1,1
    8000751c:	f0ed                	bnez	s1,800074fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000751e:	00020517          	auipc	a0,0x20
    80007522:	c0a50513          	addi	a0,a0,-1014 # 80027128 <disk+0x2128>
    80007526:	ffff9097          	auipc	ra,0xffff9
    8000752a:	772080e7          	jalr	1906(ra) # 80000c98 <release>
}
    8000752e:	70a6                	ld	ra,104(sp)
    80007530:	7406                	ld	s0,96(sp)
    80007532:	64e6                	ld	s1,88(sp)
    80007534:	6946                	ld	s2,80(sp)
    80007536:	69a6                	ld	s3,72(sp)
    80007538:	6a06                	ld	s4,64(sp)
    8000753a:	7ae2                	ld	s5,56(sp)
    8000753c:	7b42                	ld	s6,48(sp)
    8000753e:	7ba2                	ld	s7,40(sp)
    80007540:	7c02                	ld	s8,32(sp)
    80007542:	6ce2                	ld	s9,24(sp)
    80007544:	6d42                	ld	s10,16(sp)
    80007546:	6165                	addi	sp,sp,112
    80007548:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000754a:	00020697          	auipc	a3,0x20
    8000754e:	ab66b683          	ld	a3,-1354(a3) # 80027000 <disk+0x2000>
    80007552:	96ba                	add	a3,a3,a4
    80007554:	4609                	li	a2,2
    80007556:	00c69623          	sh	a2,12(a3)
    8000755a:	b5c9                	j	8000741c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000755c:	f9042583          	lw	a1,-112(s0)
    80007560:	20058793          	addi	a5,a1,512
    80007564:	0792                	slli	a5,a5,0x4
    80007566:	0001e517          	auipc	a0,0x1e
    8000756a:	b4250513          	addi	a0,a0,-1214 # 800250a8 <disk+0xa8>
    8000756e:	953e                	add	a0,a0,a5
  if(write)
    80007570:	e20d11e3          	bnez	s10,80007392 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80007574:	20058713          	addi	a4,a1,512
    80007578:	00471693          	slli	a3,a4,0x4
    8000757c:	0001e717          	auipc	a4,0x1e
    80007580:	a8470713          	addi	a4,a4,-1404 # 80025000 <disk>
    80007584:	9736                	add	a4,a4,a3
    80007586:	0a072423          	sw	zero,168(a4)
    8000758a:	b505                	j	800073aa <virtio_disk_rw+0xf4>

000000008000758c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000758c:	1101                	addi	sp,sp,-32
    8000758e:	ec06                	sd	ra,24(sp)
    80007590:	e822                	sd	s0,16(sp)
    80007592:	e426                	sd	s1,8(sp)
    80007594:	e04a                	sd	s2,0(sp)
    80007596:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80007598:	00020517          	auipc	a0,0x20
    8000759c:	b9050513          	addi	a0,a0,-1136 # 80027128 <disk+0x2128>
    800075a0:	ffff9097          	auipc	ra,0xffff9
    800075a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800075a8:	10001737          	lui	a4,0x10001
    800075ac:	533c                	lw	a5,96(a4)
    800075ae:	8b8d                	andi	a5,a5,3
    800075b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800075b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800075b6:	00020797          	auipc	a5,0x20
    800075ba:	a4a78793          	addi	a5,a5,-1462 # 80027000 <disk+0x2000>
    800075be:	6b94                	ld	a3,16(a5)
    800075c0:	0207d703          	lhu	a4,32(a5)
    800075c4:	0026d783          	lhu	a5,2(a3)
    800075c8:	06f70163          	beq	a4,a5,8000762a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800075cc:	0001e917          	auipc	s2,0x1e
    800075d0:	a3490913          	addi	s2,s2,-1484 # 80025000 <disk>
    800075d4:	00020497          	auipc	s1,0x20
    800075d8:	a2c48493          	addi	s1,s1,-1492 # 80027000 <disk+0x2000>
    __sync_synchronize();
    800075dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800075e0:	6898                	ld	a4,16(s1)
    800075e2:	0204d783          	lhu	a5,32(s1)
    800075e6:	8b9d                	andi	a5,a5,7
    800075e8:	078e                	slli	a5,a5,0x3
    800075ea:	97ba                	add	a5,a5,a4
    800075ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800075ee:	20078713          	addi	a4,a5,512
    800075f2:	0712                	slli	a4,a4,0x4
    800075f4:	974a                	add	a4,a4,s2
    800075f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800075fa:	e731                	bnez	a4,80007646 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800075fc:	20078793          	addi	a5,a5,512
    80007600:	0792                	slli	a5,a5,0x4
    80007602:	97ca                	add	a5,a5,s2
    80007604:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007606:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000760a:	ffffc097          	auipc	ra,0xffffc
    8000760e:	95a080e7          	jalr	-1702(ra) # 80002f64 <wakeup>

    disk.used_idx += 1;
    80007612:	0204d783          	lhu	a5,32(s1)
    80007616:	2785                	addiw	a5,a5,1
    80007618:	17c2                	slli	a5,a5,0x30
    8000761a:	93c1                	srli	a5,a5,0x30
    8000761c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007620:	6898                	ld	a4,16(s1)
    80007622:	00275703          	lhu	a4,2(a4)
    80007626:	faf71be3          	bne	a4,a5,800075dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000762a:	00020517          	auipc	a0,0x20
    8000762e:	afe50513          	addi	a0,a0,-1282 # 80027128 <disk+0x2128>
    80007632:	ffff9097          	auipc	ra,0xffff9
    80007636:	666080e7          	jalr	1638(ra) # 80000c98 <release>
}
    8000763a:	60e2                	ld	ra,24(sp)
    8000763c:	6442                	ld	s0,16(sp)
    8000763e:	64a2                	ld	s1,8(sp)
    80007640:	6902                	ld	s2,0(sp)
    80007642:	6105                	addi	sp,sp,32
    80007644:	8082                	ret
      panic("virtio_disk_intr status");
    80007646:	00002517          	auipc	a0,0x2
    8000764a:	34a50513          	addi	a0,a0,842 # 80009990 <syscalls+0x3d8>
    8000764e:	ffff9097          	auipc	ra,0xffff9
    80007652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>

0000000080007656 <cas>:
    80007656:	100522af          	lr.w	t0,(a0)
    8000765a:	00b29563          	bne	t0,a1,80007664 <fail>
    8000765e:	18c5252f          	sc.w	a0,a2,(a0)
    80007662:	8082                	ret

0000000080007664 <fail>:
    80007664:	4505                	li	a0,1
    80007666:	8082                	ret
	...

0000000080008000 <_trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret
	...
