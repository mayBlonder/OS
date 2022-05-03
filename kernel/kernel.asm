
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	aa013103          	ld	sp,-1376(sp) # 80009aa0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	00c78793          	addi	a5,a5,12 # 80007070 <timervec>
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
    80000130:	7d6080e7          	jalr	2006(ra) # 80003902 <either_copyin>
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
    800001c8:	a3c080e7          	jalr	-1476(ra) # 80001c00 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	a4c080e7          	jalr	-1460(ra) # 80002c20 <sleep>
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
    80000214:	69c080e7          	jalr	1692(ra) # 800038ac <either_copyout>
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
    800002f6:	666080e7          	jalr	1638(ra) # 80003958 <procdump>
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
    8000044a:	b40080e7          	jalr	-1216(ra) # 80002f86 <wakeup>
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
    80000570:	eec50513          	addi	a0,a0,-276 # 80009458 <digits+0x418>
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
    800008a4:	6e6080e7          	jalr	1766(ra) # 80002f86 <wakeup>
    
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
    80000930:	2f4080e7          	jalr	756(ra) # 80002c20 <sleep>
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
    80000b82:	056080e7          	jalr	86(ra) # 80001bd4 <mycpu>
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
    80000bb4:	024080e7          	jalr	36(ra) # 80001bd4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	018080e7          	jalr	24(ra) # 80001bd4 <mycpu>
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
    80000bd8:	000080e7          	jalr	ra # 80001bd4 <mycpu>
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
    80000c18:	fc0080e7          	jalr	-64(ra) # 80001bd4 <mycpu>
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
    80000c44:	f94080e7          	jalr	-108(ra) # 80001bd4 <mycpu>
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
    80000e9a:	d2e080e7          	jalr	-722(ra) # 80001bc4 <cpuid>
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
    80000eb6:	d12080e7          	jalr	-750(ra) # 80001bc4 <cpuid>
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
    80000ed8:	bc4080e7          	jalr	-1084(ra) # 80003a98 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	1d4080e7          	jalr	468(ra) # 800070b0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	92e080e7          	jalr	-1746(ra) # 80002812 <scheduler>
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
    80000f08:	55450513          	addi	a0,a0,1364 # 80009458 <digits+0x418>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00008517          	auipc	a0,0x8
    80000f18:	18c50513          	addi	a0,a0,396 # 800090a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00008517          	auipc	a0,0x8
    80000f28:	53450513          	addi	a0,a0,1332 # 80009458 <digits+0x418>
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
    80000f50:	adc080e7          	jalr	-1316(ra) # 80001a28 <procinit>
    trapinit();      // trap vectors
    80000f54:	00003097          	auipc	ra,0x3
    80000f58:	b1c080e7          	jalr	-1252(ra) # 80003a70 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00003097          	auipc	ra,0x3
    80000f60:	b3c080e7          	jalr	-1220(ra) # 80003a98 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00006097          	auipc	ra,0x6
    80000f68:	136080e7          	jalr	310(ra) # 8000709a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00006097          	auipc	ra,0x6
    80000f70:	144080e7          	jalr	324(ra) # 800070b0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	320080e7          	jalr	800(ra) # 80004294 <binit>
    iinit();         // inode table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9b0080e7          	jalr	-1616(ra) # 8000492c <iinit>
    fileinit();      // file table
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	95a080e7          	jalr	-1702(ra) # 800058de <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00006097          	auipc	ra,0x6
    80000f90:	246080e7          	jalr	582(ra) # 800071d2 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	154080e7          	jalr	340(ra) # 800020e8 <userinit>
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
    8000124c:	74a080e7          	jalr	1866(ra) # 80001992 <proc_mapstacks>
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
  printf("&&&&&&&&&&&&&&&adding: %d,     prev:   %d,   next:  %d\n", p->proc_ind, p->prev_proc, p->next_proc);
    80001856:	51b4                	lw	a3,96(a1)
    80001858:	51f0                	lw	a2,100(a1)
    8000185a:	4dec                	lw	a1,92(a1)
    8000185c:	00008517          	auipc	a0,0x8
    80001860:	97c50513          	addi	a0,a0,-1668 # 800091d8 <digits+0x198>
    80001864:	fffff097          	auipc	ra,0xfffff
    80001868:	d24080e7          	jalr	-732(ra) # 80000588 <printf>
  int p_before = proc[tail].next_proc;
    8000186c:	00011517          	auipc	a0,0x11
    80001870:	f0450513          	addi	a0,a0,-252 # 80012770 <proc>
    80001874:	19800793          	li	a5,408
    80001878:	02f907b3          	mul	a5,s2,a5
    8000187c:	00f50733          	add	a4,a0,a5
  if (cas(&proc[tail].next_proc, p_before, p->proc_ind) == 0)
    80001880:	06078793          	addi	a5,a5,96
    80001884:	4cf0                	lw	a2,92(s1)
    80001886:	532c                	lw	a1,96(a4)
    80001888:	953e                	add	a0,a0,a5
    8000188a:	00006097          	auipc	ra,0x6
    8000188e:	e2c080e7          	jalr	-468(ra) # 800076b6 <cas>
    80001892:	e50d                	bnez	a0,800018bc <add_proc_to_list+0x76>
  {
    p->prev_proc = tail;
    80001894:	0724a223          	sw	s2,100(s1)
    printf("&&&&&&&&&&&&&&&adding: %d,     prev:   %d,   next:  %d\n", p->proc_ind, p->prev_proc, p->next_proc);
    80001898:	50b4                	lw	a3,96(s1)
    8000189a:	864a                	mv	a2,s2
    8000189c:	4cec                	lw	a1,92(s1)
    8000189e:	00008517          	auipc	a0,0x8
    800018a2:	93a50513          	addi	a0,a0,-1734 # 800091d8 <digits+0x198>
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
    return 0;
    800018ae:	4501                	li	a0,0
  }
  return -1;
}
    800018b0:	60e2                	ld	ra,24(sp)
    800018b2:	6442                	ld	s0,16(sp)
    800018b4:	64a2                	ld	s1,8(sp)
    800018b6:	6902                	ld	s2,0(sp)
    800018b8:	6105                	addi	sp,sp,32
    800018ba:	8082                	ret
  return -1;
    800018bc:	557d                	li	a0,-1
    800018be:	bfcd                	j	800018b0 <add_proc_to_list+0x6a>

00000000800018c0 <remove_proc_from_list>:

// Ass2
int
remove_proc_from_list(int ind)
{
    800018c0:	1101                	addi	sp,sp,-32
    800018c2:	ec06                	sd	ra,24(sp)
    800018c4:	e822                	sd	s0,16(sp)
    800018c6:	e426                	sd	s1,8(sp)
    800018c8:	e04a                	sd	s2,0(sp)
    800018ca:	1000                	addi	s0,sp,32
    800018cc:	84aa                	mv	s1,a0
  struct proc *p = &proc[ind];

  printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);
    800018ce:	19800913          	li	s2,408
    800018d2:	032507b3          	mul	a5,a0,s2
    800018d6:	00011917          	auipc	s2,0x11
    800018da:	e9a90913          	addi	s2,s2,-358 # 80012770 <proc>
    800018de:	993e                	add	s2,s2,a5
    800018e0:	06092683          	lw	a3,96(s2)
    800018e4:	06492603          	lw	a2,100(s2)
    800018e8:	85aa                	mv	a1,a0
    800018ea:	00008517          	auipc	a0,0x8
    800018ee:	92650513          	addi	a0,a0,-1754 # 80009210 <digits+0x1d0>
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	c96080e7          	jalr	-874(ra) # 80000588 <printf>

  if (p->prev_proc == -1 && p->next_proc == -1)
    800018fa:	06093703          	ld	a4,96(s2)
    800018fe:	57fd                	li	a5,-1
    return 1;  // Need to change head & tail.
    80001900:	4505                	li	a0,1
  if (p->prev_proc == -1 && p->next_proc == -1)
    80001902:	06f70e63          	beq	a4,a5,8000197e <remove_proc_from_list+0xbe>
  
  if (p->prev_proc == -1)
    80001906:	06492783          	lw	a5,100(s2)
    8000190a:	577d                	li	a4,-1
    8000190c:	06e78f63          	beq	a5,a4,8000198a <remove_proc_from_list+0xca>
    return 2;  // Need to change head.

  if (p->next_proc == -1)
    80001910:	06092603          	lw	a2,96(s2)
    80001914:	577d                	li	a4,-1
    return 3;  // Need to change tail.
    80001916:	450d                	li	a0,3
  if (p->next_proc == -1)
    80001918:	06e60363          	beq	a2,a4,8000197e <remove_proc_from_list+0xbe>

  int prev = proc[p->prev_proc].next_proc;
    8000191c:	00011517          	auipc	a0,0x11
    80001920:	e5450513          	addi	a0,a0,-428 # 80012770 <proc>
    80001924:	19800713          	li	a4,408
    80001928:	02e787b3          	mul	a5,a5,a4
    8000192c:	00f50733          	add	a4,a0,a5
  if (cas(&proc[p->prev_proc].next_proc, prev, p->next_proc) == 0)
    80001930:	06078793          	addi	a5,a5,96
    80001934:	532c                	lw	a1,96(a4)
    80001936:	953e                	add	a0,a0,a5
    80001938:	00006097          	auipc	ra,0x6
    8000193c:	d7e080e7          	jalr	-642(ra) # 800076b6 <cas>
    80001940:	e539                	bnez	a0,8000198e <remove_proc_from_list+0xce>
  {
    proc[p->next_proc].prev_proc = proc[p->prev_proc].proc_ind;
    80001942:	00011717          	auipc	a4,0x11
    80001946:	e2e70713          	addi	a4,a4,-466 # 80012770 <proc>
    8000194a:	19800513          	li	a0,408
    8000194e:	06092683          	lw	a3,96(s2)
    80001952:	02a68633          	mul	a2,a3,a0
    80001956:	963a                	add	a2,a2,a4
    80001958:	06492583          	lw	a1,100(s2)
    8000195c:	02a585b3          	mul	a1,a1,a0
    80001960:	972e                	add	a4,a4,a1
    80001962:	4f78                	lw	a4,92(a4)
    80001964:	d278                	sw	a4,100(a2)

    printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);
    80001966:	06492603          	lw	a2,100(s2)
    8000196a:	85a6                	mv	a1,s1
    8000196c:	00008517          	auipc	a0,0x8
    80001970:	8a450513          	addi	a0,a0,-1884 # 80009210 <digits+0x1d0>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	c14080e7          	jalr	-1004(ra) # 80000588 <printf>
    return 0;
    8000197c:	4501                	li	a0,0
  }
  return -1;
}
    8000197e:	60e2                	ld	ra,24(sp)
    80001980:	6442                	ld	s0,16(sp)
    80001982:	64a2                	ld	s1,8(sp)
    80001984:	6902                	ld	s2,0(sp)
    80001986:	6105                	addi	sp,sp,32
    80001988:	8082                	ret
    return 2;  // Need to change head.
    8000198a:	4509                	li	a0,2
    8000198c:	bfcd                	j	8000197e <remove_proc_from_list+0xbe>
  return -1;
    8000198e:	557d                	li	a0,-1
    80001990:	b7fd                	j	8000197e <remove_proc_from_list+0xbe>

0000000080001992 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001992:	7139                	addi	sp,sp,-64
    80001994:	fc06                	sd	ra,56(sp)
    80001996:	f822                	sd	s0,48(sp)
    80001998:	f426                	sd	s1,40(sp)
    8000199a:	f04a                	sd	s2,32(sp)
    8000199c:	ec4e                	sd	s3,24(sp)
    8000199e:	e852                	sd	s4,16(sp)
    800019a0:	e456                	sd	s5,8(sp)
    800019a2:	e05a                	sd	s6,0(sp)
    800019a4:	0080                	addi	s0,sp,64
    800019a6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a8:	00011497          	auipc	s1,0x11
    800019ac:	dc848493          	addi	s1,s1,-568 # 80012770 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019b0:	8b26                	mv	s6,s1
    800019b2:	00007a97          	auipc	s5,0x7
    800019b6:	64ea8a93          	addi	s5,s5,1614 # 80009000 <etext>
    800019ba:	04000937          	lui	s2,0x4000
    800019be:	197d                	addi	s2,s2,-1
    800019c0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c2:	00017a17          	auipc	s4,0x17
    800019c6:	3aea0a13          	addi	s4,s4,942 # 80018d70 <tickslock>
    char *pa = kalloc();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	12a080e7          	jalr	298(ra) # 80000af4 <kalloc>
    800019d2:	862a                	mv	a2,a0
    if(pa == 0)
    800019d4:	c131                	beqz	a0,80001a18 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019d6:	416485b3          	sub	a1,s1,s6
    800019da:	858d                	srai	a1,a1,0x3
    800019dc:	000ab783          	ld	a5,0(s5)
    800019e0:	02f585b3          	mul	a1,a1,a5
    800019e4:	2585                	addiw	a1,a1,1
    800019e6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ea:	4719                	li	a4,6
    800019ec:	6685                	lui	a3,0x1
    800019ee:	40b905b3          	sub	a1,s2,a1
    800019f2:	854e                	mv	a0,s3
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	764080e7          	jalr	1892(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019fc:	19848493          	addi	s1,s1,408
    80001a00:	fd4495e3          	bne	s1,s4,800019ca <proc_mapstacks+0x38>
  }
}
    80001a04:	70e2                	ld	ra,56(sp)
    80001a06:	7442                	ld	s0,48(sp)
    80001a08:	74a2                	ld	s1,40(sp)
    80001a0a:	7902                	ld	s2,32(sp)
    80001a0c:	69e2                	ld	s3,24(sp)
    80001a0e:	6a42                	ld	s4,16(sp)
    80001a10:	6aa2                	ld	s5,8(sp)
    80001a12:	6b02                	ld	s6,0(sp)
    80001a14:	6121                	addi	sp,sp,64
    80001a16:	8082                	ret
      panic("kalloc");
    80001a18:	00008517          	auipc	a0,0x8
    80001a1c:	83050513          	addi	a0,a0,-2000 # 80009248 <digits+0x208>
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	b1e080e7          	jalr	-1250(ra) # 8000053e <panic>

0000000080001a28 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a28:	711d                	addi	sp,sp,-96
    80001a2a:	ec86                	sd	ra,88(sp)
    80001a2c:	e8a2                	sd	s0,80(sp)
    80001a2e:	e4a6                	sd	s1,72(sp)
    80001a30:	e0ca                	sd	s2,64(sp)
    80001a32:	fc4e                	sd	s3,56(sp)
    80001a34:	f852                	sd	s4,48(sp)
    80001a36:	f456                	sd	s5,40(sp)
    80001a38:	f05a                	sd	s6,32(sp)
    80001a3a:	ec5e                	sd	s7,24(sp)
    80001a3c:	e862                	sd	s8,16(sp)
    80001a3e:	e466                	sd	s9,8(sp)
    80001a40:	1080                	addi	s0,sp,96
  // Added
  program_time = 0;
    80001a42:	00008797          	auipc	a5,0x8
    80001a46:	5e07ab23          	sw	zero,1526(a5) # 8000a038 <program_time>
  cpu_utilization = 0;
    80001a4a:	00008797          	auipc	a5,0x8
    80001a4e:	5e07a323          	sw	zero,1510(a5) # 8000a030 <cpu_utilization>
  start_time = ticks;
    80001a52:	00008797          	auipc	a5,0x8
    80001a56:	6027a783          	lw	a5,1538(a5) # 8000a054 <ticks>
    80001a5a:	00008717          	auipc	a4,0x8
    80001a5e:	5cf72d23          	sw	a5,1498(a4) # 8000a034 <start_time>

  // TODO: add all to UNUSED.

  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a62:	00007597          	auipc	a1,0x7
    80001a66:	7ee58593          	addi	a1,a1,2030 # 80009250 <digits+0x210>
    80001a6a:	00011517          	auipc	a0,0x11
    80001a6e:	cd650513          	addi	a0,a0,-810 # 80012740 <pid_lock>
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	0e2080e7          	jalr	226(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a7a:	00007597          	auipc	a1,0x7
    80001a7e:	7de58593          	addi	a1,a1,2014 # 80009258 <digits+0x218>
    80001a82:	00011517          	auipc	a0,0x11
    80001a86:	cd650513          	addi	a0,a0,-810 # 80012758 <wait_lock>
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	0ca080e7          	jalr	202(ra) # 80000b54 <initlock>

  unused_list_head = proc->proc_ind;
    80001a92:	00011497          	auipc	s1,0x11
    80001a96:	cde48493          	addi	s1,s1,-802 # 80012770 <proc>
    80001a9a:	4cfc                	lw	a5,92(s1)
    80001a9c:	00008717          	auipc	a4,0x8
    80001aa0:	faf72423          	sw	a5,-88(a4) # 80009a44 <unused_list_head>
  proc->prev_proc = -1;
    80001aa4:	597d                	li	s2,-1
    80001aa6:	0724a223          	sw	s2,100(s1)
  unused_list_tail = proc->proc_ind;
    80001aaa:	00008717          	auipc	a4,0x8
    80001aae:	f8f72b23          	sw	a5,-106(a4) # 80009a40 <unused_list_tail>
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
    80001ab2:	00007597          	auipc	a1,0x7
    80001ab6:	7b658593          	addi	a1,a1,1974 # 80009268 <digits+0x228>
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	098080e7          	jalr	152(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001ac4:	040007b7          	lui	a5,0x4000
    80001ac8:	17f5                	addi	a5,a5,-3
    80001aca:	07b2                	slli	a5,a5,0xc
    80001acc:	f8bc                	sd	a5,112(s1)

      //Ass2
      p->proc_ind = i;                               // Set index to process.
    80001ace:	0404ae23          	sw	zero,92(s1)
      p->prev_proc = -1;
    80001ad2:	0724a223          	sw	s2,100(s1)
      p->next_proc = -1;
    80001ad6:	0724a023          	sw	s2,96(s1)
  int i = 0;
    80001ada:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001adc:	00017a97          	auipc	s5,0x17
    80001ae0:	294a8a93          	addi	s5,s5,660 # 80018d70 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001ae4:	8ba6                	mv	s7,s1
    80001ae6:	00007b17          	auipc	s6,0x7
    80001aea:	51ab0b13          	addi	s6,s6,1306 # 80009000 <etext>
    80001aee:	04000a37          	lui	s4,0x4000
    80001af2:	1a7d                	addi	s4,s4,-1
    80001af4:	0a32                	slli	s4,s4,0xc
      if (i != 0)
      {
        printf("unused");
        add_proc_to_list(unused_list_tail, p);
    80001af6:	00008c17          	auipc	s8,0x8
    80001afa:	f4ac0c13          	addi	s8,s8,-182 # 80009a40 <unused_list_tail>
         if (unused_list_head == -1)
    80001afe:	00008c97          	auipc	s9,0x8
    80001b02:	f46c8c93          	addi	s9,s9,-186 # 80009a44 <unused_list_head>
    80001b06:	a021                	j	80001b0e <procinit+0xe6>
        {
          unused_list_head = p->proc_ind;
        }
          unused_list_tail = p->proc_ind;             // After adding to list, updating tail.
    80001b08:	4cfc                	lw	a5,92(s1)
    80001b0a:	00fc2023          	sw	a5,0(s8)
      }
      i ++;
    80001b0e:	0019099b          	addiw	s3,s2,1
    80001b12:	0009891b          	sext.w	s2,s3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b16:	19848493          	addi	s1,s1,408
    80001b1a:	07548763          	beq	s1,s5,80001b88 <procinit+0x160>
      initlock(&p->lock, "proc");
    80001b1e:	00007597          	auipc	a1,0x7
    80001b22:	74a58593          	addi	a1,a1,1866 # 80009268 <digits+0x228>
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	02c080e7          	jalr	44(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001b30:	417487b3          	sub	a5,s1,s7
    80001b34:	878d                	srai	a5,a5,0x3
    80001b36:	000b3703          	ld	a4,0(s6)
    80001b3a:	02e787b3          	mul	a5,a5,a4
    80001b3e:	2785                	addiw	a5,a5,1
    80001b40:	00d7979b          	slliw	a5,a5,0xd
    80001b44:	40fa07b3          	sub	a5,s4,a5
    80001b48:	f8bc                	sd	a5,112(s1)
      p->proc_ind = i;                               // Set index to process.
    80001b4a:	0534ae23          	sw	s3,92(s1)
      p->prev_proc = -1;
    80001b4e:	57fd                	li	a5,-1
    80001b50:	d0fc                	sw	a5,100(s1)
      p->next_proc = -1;
    80001b52:	d0bc                	sw	a5,96(s1)
      if (i != 0)
    80001b54:	fa090de3          	beqz	s2,80001b0e <procinit+0xe6>
        printf("unused");
    80001b58:	00007517          	auipc	a0,0x7
    80001b5c:	71850513          	addi	a0,a0,1816 # 80009270 <digits+0x230>
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	a28080e7          	jalr	-1496(ra) # 80000588 <printf>
        add_proc_to_list(unused_list_tail, p);
    80001b68:	85a6                	mv	a1,s1
    80001b6a:	000c2503          	lw	a0,0(s8)
    80001b6e:	00000097          	auipc	ra,0x0
    80001b72:	cd8080e7          	jalr	-808(ra) # 80001846 <add_proc_to_list>
         if (unused_list_head == -1)
    80001b76:	000ca703          	lw	a4,0(s9)
    80001b7a:	57fd                	li	a5,-1
    80001b7c:	f8f716e3          	bne	a4,a5,80001b08 <procinit+0xe0>
          unused_list_head = p->proc_ind;
    80001b80:	4cfc                	lw	a5,92(s1)
    80001b82:	00fca023          	sw	a5,0(s9)
    80001b86:	b749                	j	80001b08 <procinit+0xe0>
  }
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b88:	00010797          	auipc	a5,0x10
    80001b8c:	73878793          	addi	a5,a5,1848 # 800122c0 <cpus>
  {
    c->runnable_list_head = -1;
    80001b90:	577d                	li	a4,-1
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b92:	00011697          	auipc	a3,0x11
    80001b96:	bae68693          	addi	a3,a3,-1106 # 80012740 <pid_lock>
    c->runnable_list_head = -1;
    80001b9a:	08e7a023          	sw	a4,128(a5)
    c->runnable_list_tail = -1;
    80001b9e:	08e7a223          	sw	a4,132(a5)
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001ba2:	09078793          	addi	a5,a5,144
    80001ba6:	fed79ae3          	bne	a5,a3,80001b9a <procinit+0x172>
  }

}
    80001baa:	60e6                	ld	ra,88(sp)
    80001bac:	6446                	ld	s0,80(sp)
    80001bae:	64a6                	ld	s1,72(sp)
    80001bb0:	6906                	ld	s2,64(sp)
    80001bb2:	79e2                	ld	s3,56(sp)
    80001bb4:	7a42                	ld	s4,48(sp)
    80001bb6:	7aa2                	ld	s5,40(sp)
    80001bb8:	7b02                	ld	s6,32(sp)
    80001bba:	6be2                	ld	s7,24(sp)
    80001bbc:	6c42                	ld	s8,16(sp)
    80001bbe:	6ca2                	ld	s9,8(sp)
    80001bc0:	6125                	addi	sp,sp,96
    80001bc2:	8082                	ret

0000000080001bc4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001bc4:	1141                	addi	sp,sp,-16
    80001bc6:	e422                	sd	s0,8(sp)
    80001bc8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bca:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bcc:	2501                	sext.w	a0,a0
    80001bce:	6422                	ld	s0,8(sp)
    80001bd0:	0141                	addi	sp,sp,16
    80001bd2:	8082                	ret

0000000080001bd4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001bd4:	1141                	addi	sp,sp,-16
    80001bd6:	e422                	sd	s0,8(sp)
    80001bd8:	0800                	addi	s0,sp,16
    80001bda:	8792                	mv	a5,tp
  int id = r_tp();
    80001bdc:	0007871b          	sext.w	a4,a5
  int id = cpuid();
  struct cpu *c = &cpus[id];
  c->cpu_id = id;
    80001be0:	00010517          	auipc	a0,0x10
    80001be4:	6e050513          	addi	a0,a0,1760 # 800122c0 <cpus>
    80001be8:	00371793          	slli	a5,a4,0x3
    80001bec:	00e786b3          	add	a3,a5,a4
    80001bf0:	0692                	slli	a3,a3,0x4
    80001bf2:	96aa                	add	a3,a3,a0
    80001bf4:	08e6a423          	sw	a4,136(a3)
  return c;
}
    80001bf8:	8536                	mv	a0,a3
    80001bfa:	6422                	ld	s0,8(sp)
    80001bfc:	0141                	addi	sp,sp,16
    80001bfe:	8082                	ret

0000000080001c00 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c00:	1101                	addi	sp,sp,-32
    80001c02:	ec06                	sd	ra,24(sp)
    80001c04:	e822                	sd	s0,16(sp)
    80001c06:	e426                	sd	s1,8(sp)
    80001c08:	1000                	addi	s0,sp,32
  push_off();
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	f8e080e7          	jalr	-114(ra) # 80000b98 <push_off>
    80001c12:	8792                	mv	a5,tp
  int id = r_tp();
    80001c14:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80001c18:	00010617          	auipc	a2,0x10
    80001c1c:	6a860613          	addi	a2,a2,1704 # 800122c0 <cpus>
    80001c20:	00371793          	slli	a5,a4,0x3
    80001c24:	00e786b3          	add	a3,a5,a4
    80001c28:	0692                	slli	a3,a3,0x4
    80001c2a:	96b2                	add	a3,a3,a2
    80001c2c:	08e6a423          	sw	a4,136(a3)
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c30:	6284                	ld	s1,0(a3)
  pop_off();
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	006080e7          	jalr	6(ra) # 80000c38 <pop_off>
  return p;
}
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret

0000000080001c46 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c46:	1141                	addi	sp,sp,-16
    80001c48:	e406                	sd	ra,8(sp)
    80001c4a:	e022                	sd	s0,0(sp)
    80001c4c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	fb2080e7          	jalr	-78(ra) # 80001c00 <myproc>
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	042080e7          	jalr	66(ra) # 80000c98 <release>

  if (first) {
    80001c5e:	00008797          	auipc	a5,0x8
    80001c62:	dd27a783          	lw	a5,-558(a5) # 80009a30 <first.1775>
    80001c66:	eb89                	bnez	a5,80001c78 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c68:	00002097          	auipc	ra,0x2
    80001c6c:	e48080e7          	jalr	-440(ra) # 80003ab0 <usertrapret>
}
    80001c70:	60a2                	ld	ra,8(sp)
    80001c72:	6402                	ld	s0,0(sp)
    80001c74:	0141                	addi	sp,sp,16
    80001c76:	8082                	ret
    first = 0;
    80001c78:	00008797          	auipc	a5,0x8
    80001c7c:	da07ac23          	sw	zero,-584(a5) # 80009a30 <first.1775>
    fsinit(ROOTDEV);
    80001c80:	4505                	li	a0,1
    80001c82:	00003097          	auipc	ra,0x3
    80001c86:	c2a080e7          	jalr	-982(ra) # 800048ac <fsinit>
    80001c8a:	bff9                	j	80001c68 <forkret+0x22>

0000000080001c8c <allocpid>:
allocpid() {
    80001c8c:	1101                	addi	sp,sp,-32
    80001c8e:	ec06                	sd	ra,24(sp)
    80001c90:	e822                	sd	s0,16(sp)
    80001c92:	e426                	sd	s1,8(sp)
    80001c94:	1000                	addi	s0,sp,32
  pid = nextpid;
    80001c96:	00008517          	auipc	a0,0x8
    80001c9a:	d9e50513          	addi	a0,a0,-610 # 80009a34 <nextpid>
    80001c9e:	4104                	lw	s1,0(a0)
  if (cas(&nextpid, pid, (nextpid + 1)) == 0)
    80001ca0:	0014861b          	addiw	a2,s1,1
    80001ca4:	85a6                	mv	a1,s1
    80001ca6:	00006097          	auipc	ra,0x6
    80001caa:	a10080e7          	jalr	-1520(ra) # 800076b6 <cas>
    80001cae:	e519                	bnez	a0,80001cbc <allocpid+0x30>
}
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	60e2                	ld	ra,24(sp)
    80001cb4:	6442                	ld	s0,16(sp)
    80001cb6:	64a2                	ld	s1,8(sp)
    80001cb8:	6105                	addi	sp,sp,32
    80001cba:	8082                	ret
  return allocpid();
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	fd0080e7          	jalr	-48(ra) # 80001c8c <allocpid>
    80001cc4:	84aa                	mv	s1,a0
    80001cc6:	b7ed                	j	80001cb0 <allocpid+0x24>

0000000080001cc8 <proc_pagetable>:
{
    80001cc8:	1101                	addi	sp,sp,-32
    80001cca:	ec06                	sd	ra,24(sp)
    80001ccc:	e822                	sd	s0,16(sp)
    80001cce:	e426                	sd	s1,8(sp)
    80001cd0:	e04a                	sd	s2,0(sp)
    80001cd2:	1000                	addi	s0,sp,32
    80001cd4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	66c080e7          	jalr	1644(ra) # 80001342 <uvmcreate>
    80001cde:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ce0:	c121                	beqz	a0,80001d20 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ce2:	4729                	li	a4,10
    80001ce4:	00006697          	auipc	a3,0x6
    80001ce8:	31c68693          	addi	a3,a3,796 # 80008000 <_trampoline>
    80001cec:	6605                	lui	a2,0x1
    80001cee:	040005b7          	lui	a1,0x4000
    80001cf2:	15fd                	addi	a1,a1,-1
    80001cf4:	05b2                	slli	a1,a1,0xc
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	3c2080e7          	jalr	962(ra) # 800010b8 <mappages>
    80001cfe:	02054863          	bltz	a0,80001d2e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d02:	4719                	li	a4,6
    80001d04:	08893683          	ld	a3,136(s2) # 4000088 <_entry-0x7bffff78>
    80001d08:	6605                	lui	a2,0x1
    80001d0a:	020005b7          	lui	a1,0x2000
    80001d0e:	15fd                	addi	a1,a1,-1
    80001d10:	05b6                	slli	a1,a1,0xd
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	3a4080e7          	jalr	932(ra) # 800010b8 <mappages>
    80001d1c:	02054163          	bltz	a0,80001d3e <proc_pagetable+0x76>
}
    80001d20:	8526                	mv	a0,s1
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6902                	ld	s2,0(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret
    uvmfree(pagetable, 0);
    80001d2e:	4581                	li	a1,0
    80001d30:	8526                	mv	a0,s1
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	80c080e7          	jalr	-2036(ra) # 8000153e <uvmfree>
    return 0;
    80001d3a:	4481                	li	s1,0
    80001d3c:	b7d5                	j	80001d20 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d3e:	4681                	li	a3,0
    80001d40:	4605                	li	a2,1
    80001d42:	040005b7          	lui	a1,0x4000
    80001d46:	15fd                	addi	a1,a1,-1
    80001d48:	05b2                	slli	a1,a1,0xc
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	532080e7          	jalr	1330(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001d54:	4581                	li	a1,0
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	7e6080e7          	jalr	2022(ra) # 8000153e <uvmfree>
    return 0;
    80001d60:	4481                	li	s1,0
    80001d62:	bf7d                	j	80001d20 <proc_pagetable+0x58>

0000000080001d64 <proc_freepagetable>:
{
    80001d64:	1101                	addi	sp,sp,-32
    80001d66:	ec06                	sd	ra,24(sp)
    80001d68:	e822                	sd	s0,16(sp)
    80001d6a:	e426                	sd	s1,8(sp)
    80001d6c:	e04a                	sd	s2,0(sp)
    80001d6e:	1000                	addi	s0,sp,32
    80001d70:	84aa                	mv	s1,a0
    80001d72:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d74:	4681                	li	a3,0
    80001d76:	4605                	li	a2,1
    80001d78:	040005b7          	lui	a1,0x4000
    80001d7c:	15fd                	addi	a1,a1,-1
    80001d7e:	05b2                	slli	a1,a1,0xc
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	4fe080e7          	jalr	1278(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d88:	4681                	li	a3,0
    80001d8a:	4605                	li	a2,1
    80001d8c:	020005b7          	lui	a1,0x2000
    80001d90:	15fd                	addi	a1,a1,-1
    80001d92:	05b6                	slli	a1,a1,0xd
    80001d94:	8526                	mv	a0,s1
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	4e8080e7          	jalr	1256(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001d9e:	85ca                	mv	a1,s2
    80001da0:	8526                	mv	a0,s1
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	79c080e7          	jalr	1948(ra) # 8000153e <uvmfree>
}
    80001daa:	60e2                	ld	ra,24(sp)
    80001dac:	6442                	ld	s0,16(sp)
    80001dae:	64a2                	ld	s1,8(sp)
    80001db0:	6902                	ld	s2,0(sp)
    80001db2:	6105                	addi	sp,sp,32
    80001db4:	8082                	ret

0000000080001db6 <freeproc>:
{
    80001db6:	1101                	addi	sp,sp,-32
    80001db8:	ec06                	sd	ra,24(sp)
    80001dba:	e822                	sd	s0,16(sp)
    80001dbc:	e426                	sd	s1,8(sp)
    80001dbe:	1000                	addi	s0,sp,32
    80001dc0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dc2:	6548                	ld	a0,136(a0)
    80001dc4:	c509                	beqz	a0,80001dce <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	c32080e7          	jalr	-974(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001dce:	0804b423          	sd	zero,136(s1)
  if(p->pagetable)
    80001dd2:	60c8                	ld	a0,128(s1)
    80001dd4:	c511                	beqz	a0,80001de0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dd6:	7cac                	ld	a1,120(s1)
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	f8c080e7          	jalr	-116(ra) # 80001d64 <proc_freepagetable>
  p->pagetable = 0;
    80001de0:	0804b023          	sd	zero,128(s1)
  p->sz = 0;
    80001de4:	0604bc23          	sd	zero,120(s1)
  p->pid = 0;
    80001de8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dec:	0604b423          	sd	zero,104(s1)
  p->name[0] = 0;
    80001df0:	18048423          	sb	zero,392(s1)
  p->chan = 0;
    80001df4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001df8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dfc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e00:	0004ac23          	sw	zero,24(s1)
  printf("zombie");
    80001e04:	00007517          	auipc	a0,0x7
    80001e08:	47450513          	addi	a0,a0,1140 # 80009278 <digits+0x238>
    80001e0c:	ffffe097          	auipc	ra,0xffffe
    80001e10:	77c080e7          	jalr	1916(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80001e14:	4ce8                	lw	a0,92(s1)
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	aaa080e7          	jalr	-1366(ra) # 800018c0 <remove_proc_from_list>
  if (res == 1){
    80001e1e:	4785                	li	a5,1
    80001e20:	02f50663          	beq	a0,a5,80001e4c <freeproc+0x96>
  if (res == 2){
    80001e24:	4789                	li	a5,2
    80001e26:	06f51463          	bne	a0,a5,80001e8e <freeproc+0xd8>
    zombie_list_head = p->next_proc;
    80001e2a:	50bc                	lw	a5,96(s1)
    80001e2c:	00008717          	auipc	a4,0x8
    80001e30:	c0f72823          	sw	a5,-1008(a4) # 80009a3c <zombie_list_head>
    proc[p->next_proc].prev_proc = -1;
    80001e34:	19800713          	li	a4,408
    80001e38:	02e787b3          	mul	a5,a5,a4
    80001e3c:	00011717          	auipc	a4,0x11
    80001e40:	93470713          	addi	a4,a4,-1740 # 80012770 <proc>
    80001e44:	97ba                	add	a5,a5,a4
    80001e46:	577d                	li	a4,-1
    80001e48:	d3f8                	sw	a4,100(a5)
  if (res == 3){
    80001e4a:	a811                	j	80001e5e <freeproc+0xa8>
    zombie_list_head = -1;
    80001e4c:	57fd                	li	a5,-1
    80001e4e:	00008717          	auipc	a4,0x8
    80001e52:	bef72723          	sw	a5,-1042(a4) # 80009a3c <zombie_list_head>
    zombie_list_tail = -1;
    80001e56:	00008717          	auipc	a4,0x8
    80001e5a:	bef72123          	sw	a5,-1054(a4) # 80009a38 <zombie_list_tail>
  p->next_proc = -1;
    80001e5e:	57fd                	li	a5,-1
    80001e60:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80001e62:	d0fc                	sw	a5,100(s1)
  if (unused_list_tail != -1){
    80001e64:	00008717          	auipc	a4,0x8
    80001e68:	bdc72703          	lw	a4,-1060(a4) # 80009a40 <unused_list_tail>
    80001e6c:	57fd                	li	a5,-1
    80001e6e:	04f71463          	bne	a4,a5,80001eb6 <freeproc+0x100>
    unused_list_tail = unused_list_head = p->proc_ind;
    80001e72:	4cfc                	lw	a5,92(s1)
    80001e74:	00008717          	auipc	a4,0x8
    80001e78:	bcf72823          	sw	a5,-1072(a4) # 80009a44 <unused_list_head>
    80001e7c:	00008717          	auipc	a4,0x8
    80001e80:	bcf72223          	sw	a5,-1084(a4) # 80009a40 <unused_list_tail>
}
    80001e84:	60e2                	ld	ra,24(sp)
    80001e86:	6442                	ld	s0,16(sp)
    80001e88:	64a2                	ld	s1,8(sp)
    80001e8a:	6105                	addi	sp,sp,32
    80001e8c:	8082                	ret
  if (res == 3){
    80001e8e:	478d                	li	a5,3
    80001e90:	fcf517e3          	bne	a0,a5,80001e5e <freeproc+0xa8>
    zombie_list_tail = p->prev_proc;
    80001e94:	50fc                	lw	a5,100(s1)
    80001e96:	00008717          	auipc	a4,0x8
    80001e9a:	baf72123          	sw	a5,-1118(a4) # 80009a38 <zombie_list_tail>
    proc[p->prev_proc].next_proc = -1;
    80001e9e:	19800713          	li	a4,408
    80001ea2:	02e787b3          	mul	a5,a5,a4
    80001ea6:	00011717          	auipc	a4,0x11
    80001eaa:	8ca70713          	addi	a4,a4,-1846 # 80012770 <proc>
    80001eae:	97ba                	add	a5,a5,a4
    80001eb0:	577d                	li	a4,-1
    80001eb2:	d3b8                	sw	a4,96(a5)
    80001eb4:	b76d                	j	80001e5e <freeproc+0xa8>
    printf("unused");
    80001eb6:	00007517          	auipc	a0,0x7
    80001eba:	3ba50513          	addi	a0,a0,954 # 80009270 <digits+0x230>
    80001ebe:	ffffe097          	auipc	ra,0xffffe
    80001ec2:	6ca080e7          	jalr	1738(ra) # 80000588 <printf>
    add_proc_to_list(unused_list_tail, p);
    80001ec6:	85a6                	mv	a1,s1
    80001ec8:	00008517          	auipc	a0,0x8
    80001ecc:	b7852503          	lw	a0,-1160(a0) # 80009a40 <unused_list_tail>
    80001ed0:	00000097          	auipc	ra,0x0
    80001ed4:	976080e7          	jalr	-1674(ra) # 80001846 <add_proc_to_list>
    if (unused_list_head == -1)
    80001ed8:	00008717          	auipc	a4,0x8
    80001edc:	b6c72703          	lw	a4,-1172(a4) # 80009a44 <unused_list_head>
    80001ee0:	57fd                	li	a5,-1
    80001ee2:	00f70863          	beq	a4,a5,80001ef2 <freeproc+0x13c>
    unused_list_tail = p->proc_ind;
    80001ee6:	4cfc                	lw	a5,92(s1)
    80001ee8:	00008717          	auipc	a4,0x8
    80001eec:	b4f72c23          	sw	a5,-1192(a4) # 80009a40 <unused_list_tail>
    80001ef0:	bf51                	j	80001e84 <freeproc+0xce>
    unused_list_head = p->proc_ind;
    80001ef2:	4cfc                	lw	a5,92(s1)
    80001ef4:	00008717          	auipc	a4,0x8
    80001ef8:	b4f72823          	sw	a5,-1200(a4) # 80009a44 <unused_list_head>
    80001efc:	b7ed                	j	80001ee6 <freeproc+0x130>

0000000080001efe <allocproc>:
{
    80001efe:	7139                	addi	sp,sp,-64
    80001f00:	fc06                	sd	ra,56(sp)
    80001f02:	f822                	sd	s0,48(sp)
    80001f04:	f426                	sd	s1,40(sp)
    80001f06:	f04a                	sd	s2,32(sp)
    80001f08:	ec4e                	sd	s3,24(sp)
    80001f0a:	e852                	sd	s4,16(sp)
    80001f0c:	e456                	sd	s5,8(sp)
    80001f0e:	0080                	addi	s0,sp,64
  if (unused_list_head > -1)
    80001f10:	00008917          	auipc	s2,0x8
    80001f14:	b3492903          	lw	s2,-1228(s2) # 80009a44 <unused_list_head>
  return 0;
    80001f18:	4981                	li	s3,0
  if (unused_list_head > -1)
    80001f1a:	00095c63          	bgez	s2,80001f32 <allocproc+0x34>
}
    80001f1e:	854e                	mv	a0,s3
    80001f20:	70e2                	ld	ra,56(sp)
    80001f22:	7442                	ld	s0,48(sp)
    80001f24:	74a2                	ld	s1,40(sp)
    80001f26:	7902                	ld	s2,32(sp)
    80001f28:	69e2                	ld	s3,24(sp)
    80001f2a:	6a42                	ld	s4,16(sp)
    80001f2c:	6aa2                	ld	s5,8(sp)
    80001f2e:	6121                	addi	sp,sp,64
    80001f30:	8082                	ret
    p = &proc[unused_list_head];
    80001f32:	19800a13          	li	s4,408
    80001f36:	03490a33          	mul	s4,s2,s4
    80001f3a:	00011997          	auipc	s3,0x11
    80001f3e:	83698993          	addi	s3,s3,-1994 # 80012770 <proc>
    80001f42:	99d2                	add	s3,s3,s4
    acquire(&p->lock);
    80001f44:	854e                	mv	a0,s3
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	c9e080e7          	jalr	-866(ra) # 80000be4 <acquire>
    printf("unused");
    80001f4e:	00007517          	auipc	a0,0x7
    80001f52:	32250513          	addi	a0,a0,802 # 80009270 <digits+0x230>
    80001f56:	ffffe097          	auipc	ra,0xffffe
    80001f5a:	632080e7          	jalr	1586(ra) # 80000588 <printf>
    int res = remove_proc_from_list(unused_list_head); 
    80001f5e:	00008517          	auipc	a0,0x8
    80001f62:	ae652503          	lw	a0,-1306(a0) # 80009a44 <unused_list_head>
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	95a080e7          	jalr	-1702(ra) # 800018c0 <remove_proc_from_list>
    if (res == 1){
    80001f6e:	4785                	li	a5,1
    80001f70:	02f50963          	beq	a0,a5,80001fa2 <allocproc+0xa4>
    if (res == 2){
    80001f74:	4789                	li	a5,2
    80001f76:	0ef51663          	bne	a0,a5,80002062 <allocproc+0x164>
      unused_list_head = p->next_proc;      // Update head.
    80001f7a:	00010797          	auipc	a5,0x10
    80001f7e:	7f678793          	addi	a5,a5,2038 # 80012770 <proc>
    80001f82:	19800613          	li	a2,408
    80001f86:	02c906b3          	mul	a3,s2,a2
    80001f8a:	96be                	add	a3,a3,a5
    80001f8c:	52b8                	lw	a4,96(a3)
    80001f8e:	00008697          	auipc	a3,0x8
    80001f92:	aae6ab23          	sw	a4,-1354(a3) # 80009a44 <unused_list_head>
      proc[p->next_proc].prev_proc = -1;    // Remove head's prev.
    80001f96:	02c70733          	mul	a4,a4,a2
    80001f9a:	97ba                	add	a5,a5,a4
    80001f9c:	577d                	li	a4,-1
    80001f9e:	d3f8                	sw	a4,100(a5)
    if (res == 3){
    80001fa0:	a811                	j	80001fb4 <allocproc+0xb6>
      unused_list_head = -1;
    80001fa2:	57fd                	li	a5,-1
    80001fa4:	00008717          	auipc	a4,0x8
    80001fa8:	aaf72023          	sw	a5,-1376(a4) # 80009a44 <unused_list_head>
      unused_list_tail = -1;
    80001fac:	00008717          	auipc	a4,0x8
    80001fb0:	a8f72a23          	sw	a5,-1388(a4) # 80009a40 <unused_list_tail>
    p->prev_proc = -1;
    80001fb4:	19800493          	li	s1,408
    80001fb8:	029907b3          	mul	a5,s2,s1
    80001fbc:	00010497          	auipc	s1,0x10
    80001fc0:	7b448493          	addi	s1,s1,1972 # 80012770 <proc>
    80001fc4:	94be                	add	s1,s1,a5
    80001fc6:	57fd                	li	a5,-1
    80001fc8:	d0fc                	sw	a5,100(s1)
    p->next_proc = -1;
    80001fca:	d0bc                	sw	a5,96(s1)
  p->pid = allocpid();
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	cc0080e7          	jalr	-832(ra) # 80001c8c <allocpid>
    80001fd4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001fd6:	4785                	li	a5,1
    80001fd8:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001fda:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001fde:	0204ac23          	sw	zero,56(s1)
  p->paused = 0;
    80001fe2:	0404a023          	sw	zero,64(s1)
  p->sleeping_time = 0;
    80001fe6:	0404a623          	sw	zero,76(s1)
  p->running_time = 0;
    80001fea:	0404a223          	sw	zero,68(s1)
  p->runnable_time = 0;
    80001fee:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	b02080e7          	jalr	-1278(ra) # 80000af4 <kalloc>
    80001ffa:	8aaa                	mv	s5,a0
    80001ffc:	e4c8                	sd	a0,136(s1)
    80001ffe:	c949                	beqz	a0,80002090 <allocproc+0x192>
  p->pagetable = proc_pagetable(p);
    80002000:	854e                	mv	a0,s3
    80002002:	00000097          	auipc	ra,0x0
    80002006:	cc6080e7          	jalr	-826(ra) # 80001cc8 <proc_pagetable>
    8000200a:	84aa                	mv	s1,a0
    8000200c:	19800793          	li	a5,408
    80002010:	02f90733          	mul	a4,s2,a5
    80002014:	00010797          	auipc	a5,0x10
    80002018:	75c78793          	addi	a5,a5,1884 # 80012770 <proc>
    8000201c:	97ba                	add	a5,a5,a4
    8000201e:	e3c8                	sd	a0,128(a5)
  if(p->pagetable == 0){
    80002020:	c541                	beqz	a0,800020a8 <allocproc+0x1aa>
  memset(&p->context, 0, sizeof(p->context));
    80002022:	090a0513          	addi	a0,s4,144 # 4000090 <_entry-0x7bffff70>
    80002026:	00010497          	auipc	s1,0x10
    8000202a:	74a48493          	addi	s1,s1,1866 # 80012770 <proc>
    8000202e:	07000613          	li	a2,112
    80002032:	4581                	li	a1,0
    80002034:	9526                	add	a0,a0,s1
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	caa080e7          	jalr	-854(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000203e:	19800793          	li	a5,408
    80002042:	02f90933          	mul	s2,s2,a5
    80002046:	9926                	add	s2,s2,s1
    80002048:	00000797          	auipc	a5,0x0
    8000204c:	bfe78793          	addi	a5,a5,-1026 # 80001c46 <forkret>
    80002050:	08f93823          	sd	a5,144(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002054:	07093783          	ld	a5,112(s2)
    80002058:	6705                	lui	a4,0x1
    8000205a:	97ba                	add	a5,a5,a4
    8000205c:	08f93c23          	sd	a5,152(s2)
  return p;
    80002060:	bd7d                	j	80001f1e <allocproc+0x20>
    if (res == 3){
    80002062:	478d                	li	a5,3
    80002064:	f4f518e3          	bne	a0,a5,80001fb4 <allocproc+0xb6>
      unused_list_tail = p->prev_proc;      // Update tail.
    80002068:	00010797          	auipc	a5,0x10
    8000206c:	70878793          	addi	a5,a5,1800 # 80012770 <proc>
    80002070:	19800613          	li	a2,408
    80002074:	02c906b3          	mul	a3,s2,a2
    80002078:	96be                	add	a3,a3,a5
    8000207a:	52f8                	lw	a4,100(a3)
    8000207c:	00008697          	auipc	a3,0x8
    80002080:	9ce6a223          	sw	a4,-1596(a3) # 80009a40 <unused_list_tail>
      proc[p->prev_proc].next_proc = -1;    // Remove tail's next.
    80002084:	02c70733          	mul	a4,a4,a2
    80002088:	97ba                	add	a5,a5,a4
    8000208a:	577d                	li	a4,-1
    8000208c:	d3b8                	sw	a4,96(a5)
    8000208e:	b71d                	j	80001fb4 <allocproc+0xb6>
    freeproc(p);
    80002090:	854e                	mv	a0,s3
    80002092:	00000097          	auipc	ra,0x0
    80002096:	d24080e7          	jalr	-732(ra) # 80001db6 <freeproc>
    release(&p->lock);
    8000209a:	854e                	mv	a0,s3
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	bfc080e7          	jalr	-1028(ra) # 80000c98 <release>
    return 0;
    800020a4:	89d6                	mv	s3,s5
    800020a6:	bda5                	j	80001f1e <allocproc+0x20>
    freeproc(p);
    800020a8:	854e                	mv	a0,s3
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	d0c080e7          	jalr	-756(ra) # 80001db6 <freeproc>
    release(&p->lock);
    800020b2:	854e                	mv	a0,s3
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	be4080e7          	jalr	-1052(ra) # 80000c98 <release>
    return 0;
    800020bc:	89a6                	mv	s3,s1
    800020be:	b585                	j	80001f1e <allocproc+0x20>

00000000800020c0 <str_compare>:
{
    800020c0:	1141                	addi	sp,sp,-16
    800020c2:	e422                	sd	s0,8(sp)
    800020c4:	0800                	addi	s0,sp,16
      c1 = (unsigned char) *s1++;
    800020c6:	0505                	addi	a0,a0,1
    800020c8:	fff54783          	lbu	a5,-1(a0)
      c2 = (unsigned char) *s2++;
    800020cc:	0585                	addi	a1,a1,1
    800020ce:	fff5c703          	lbu	a4,-1(a1) # 1ffffff <_entry-0x7e000001>
      if (c1 == '\0')
    800020d2:	c791                	beqz	a5,800020de <str_compare+0x1e>
  while (c1 == c2);
    800020d4:	fee789e3          	beq	a5,a4,800020c6 <str_compare+0x6>
  return c1 - c2;
    800020d8:	40e7853b          	subw	a0,a5,a4
    800020dc:	a019                	j	800020e2 <str_compare+0x22>
        return c1 - c2;
    800020de:	40e0053b          	negw	a0,a4
}
    800020e2:	6422                	ld	s0,8(sp)
    800020e4:	0141                	addi	sp,sp,16
    800020e6:	8082                	ret

00000000800020e8 <userinit>:
{
    800020e8:	1101                	addi	sp,sp,-32
    800020ea:	ec06                	sd	ra,24(sp)
    800020ec:	e822                	sd	s0,16(sp)
    800020ee:	e426                	sd	s1,8(sp)
    800020f0:	e04a                	sd	s2,0(sp)
    800020f2:	1000                	addi	s0,sp,32
  p = allocproc();
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	e0a080e7          	jalr	-502(ra) # 80001efe <allocproc>
    800020fc:	84aa                	mv	s1,a0
  initproc = p;
    800020fe:	00008797          	auipc	a5,0x8
    80002102:	f2a7b523          	sd	a0,-214(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002106:	03400613          	li	a2,52
    8000210a:	00008597          	auipc	a1,0x8
    8000210e:	95658593          	addi	a1,a1,-1706 # 80009a60 <initcode>
    80002112:	6148                	ld	a0,128(a0)
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	25c080e7          	jalr	604(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    8000211c:	6785                	lui	a5,0x1
    8000211e:	fcbc                	sd	a5,120(s1)
  p->trapframe->epc = 0;      // user program counter
    80002120:	64d8                	ld	a4,136(s1)
    80002122:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002126:	64d8                	ld	a4,136(s1)
    80002128:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000212a:	4641                	li	a2,16
    8000212c:	00007597          	auipc	a1,0x7
    80002130:	15458593          	addi	a1,a1,340 # 80009280 <digits+0x240>
    80002134:	18848513          	addi	a0,s1,392
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	cfa080e7          	jalr	-774(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002140:	00007517          	auipc	a0,0x7
    80002144:	15050513          	addi	a0,a0,336 # 80009290 <digits+0x250>
    80002148:	00003097          	auipc	ra,0x3
    8000214c:	192080e7          	jalr	402(ra) # 800052da <namei>
    80002150:	18a4b023          	sd	a0,384(s1)
  p->state = RUNNABLE;
    80002154:	478d                	li	a5,3
    80002156:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002158:	00008797          	auipc	a5,0x8
    8000215c:	efc7a783          	lw	a5,-260(a5) # 8000a054 <ticks>
    80002160:	dcdc                	sw	a5,60(s1)
    80002162:	8792                	mv	a5,tp
  int id = r_tp();
    80002164:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002168:	00010617          	auipc	a2,0x10
    8000216c:	15860613          	addi	a2,a2,344 # 800122c0 <cpus>
    80002170:	00371793          	slli	a5,a4,0x3
    80002174:	00e786b3          	add	a3,a5,a4
    80002178:	0692                	slli	a3,a3,0x4
    8000217a:	96b2                	add	a3,a3,a2
    8000217c:	08e6a423          	sw	a4,136(a3)
  if (mycpu()->runnable_list_head == -1)
    80002180:	0806a703          	lw	a4,128(a3)
    80002184:	57fd                	li	a5,-1
    80002186:	06f70c63          	beq	a4,a5,800021fe <userinit+0x116>
    printf("runnable");
    8000218a:	00007517          	auipc	a0,0x7
    8000218e:	12650513          	addi	a0,a0,294 # 800092b0 <digits+0x270>
    80002192:	ffffe097          	auipc	ra,0xffffe
    80002196:	3f6080e7          	jalr	1014(ra) # 80000588 <printf>
    8000219a:	8792                	mv	a5,tp
  int id = r_tp();
    8000219c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800021a0:	00010917          	auipc	s2,0x10
    800021a4:	12090913          	addi	s2,s2,288 # 800122c0 <cpus>
    800021a8:	00371793          	slli	a5,a4,0x3
    800021ac:	00e786b3          	add	a3,a5,a4
    800021b0:	0692                	slli	a3,a3,0x4
    800021b2:	96ca                	add	a3,a3,s2
    800021b4:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    800021b8:	85a6                	mv	a1,s1
    800021ba:	0846a503          	lw	a0,132(a3)
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	688080e7          	jalr	1672(ra) # 80001846 <add_proc_to_list>
    800021c6:	8792                	mv	a5,tp
  int id = r_tp();
    800021c8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800021cc:	00371793          	slli	a5,a4,0x3
    800021d0:	00e786b3          	add	a3,a5,a4
    800021d4:	0692                	slli	a3,a3,0x4
    800021d6:	96ca                	add	a3,a3,s2
    800021d8:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    800021dc:	4cf4                	lw	a3,92(s1)
    800021de:	97ba                	add	a5,a5,a4
    800021e0:	0792                	slli	a5,a5,0x4
    800021e2:	993e                	add	s2,s2,a5
    800021e4:	08d92223          	sw	a3,132(s2)
  release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
}
    800021f2:	60e2                	ld	ra,24(sp)
    800021f4:	6442                	ld	s0,16(sp)
    800021f6:	64a2                	ld	s1,8(sp)
    800021f8:	6902                	ld	s2,0(sp)
    800021fa:	6105                	addi	sp,sp,32
    800021fc:	8082                	ret
    printf("init runnable: %d\n", p->proc_ind);
    800021fe:	4cec                	lw	a1,92(s1)
    80002200:	00007517          	auipc	a0,0x7
    80002204:	09850513          	addi	a0,a0,152 # 80009298 <digits+0x258>
    80002208:	ffffe097          	auipc	ra,0xffffe
    8000220c:	380080e7          	jalr	896(ra) # 80000588 <printf>
    80002210:	8792                	mv	a5,tp
  int id = r_tp();
    80002212:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002216:	00010717          	auipc	a4,0x10
    8000221a:	0aa70713          	addi	a4,a4,170 # 800122c0 <cpus>
    8000221e:	00369793          	slli	a5,a3,0x3
    80002222:	00d78633          	add	a2,a5,a3
    80002226:	0612                	slli	a2,a2,0x4
    80002228:	963a                	add	a2,a2,a4
    8000222a:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    8000222e:	4cf0                	lw	a2,92(s1)
    80002230:	97b6                	add	a5,a5,a3
    80002232:	0792                	slli	a5,a5,0x4
    80002234:	97ba                	add	a5,a5,a4
    80002236:	08c7a023          	sw	a2,128(a5)
    8000223a:	8792                	mv	a5,tp
  int id = r_tp();
    8000223c:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002240:	00369793          	slli	a5,a3,0x3
    80002244:	00d78633          	add	a2,a5,a3
    80002248:	0612                	slli	a2,a2,0x4
    8000224a:	963a                	add	a2,a2,a4
    8000224c:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002250:	4cf0                	lw	a2,92(s1)
    80002252:	97b6                	add	a5,a5,a3
    80002254:	0792                	slli	a5,a5,0x4
    80002256:	973e                	add	a4,a4,a5
    80002258:	08c72223          	sw	a2,132(a4)
    8000225c:	b771                	j	800021e8 <userinit+0x100>

000000008000225e <growproc>:
{
    8000225e:	1101                	addi	sp,sp,-32
    80002260:	ec06                	sd	ra,24(sp)
    80002262:	e822                	sd	s0,16(sp)
    80002264:	e426                	sd	s1,8(sp)
    80002266:	e04a                	sd	s2,0(sp)
    80002268:	1000                	addi	s0,sp,32
    8000226a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	994080e7          	jalr	-1644(ra) # 80001c00 <myproc>
    80002274:	892a                	mv	s2,a0
  sz = p->sz;
    80002276:	7d2c                	ld	a1,120(a0)
    80002278:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000227c:	00904f63          	bgtz	s1,8000229a <growproc+0x3c>
  } else if(n < 0){
    80002280:	0204cc63          	bltz	s1,800022b8 <growproc+0x5a>
  p->sz = sz;
    80002284:	1602                	slli	a2,a2,0x20
    80002286:	9201                	srli	a2,a2,0x20
    80002288:	06c93c23          	sd	a2,120(s2)
  return 0;
    8000228c:	4501                	li	a0,0
}
    8000228e:	60e2                	ld	ra,24(sp)
    80002290:	6442                	ld	s0,16(sp)
    80002292:	64a2                	ld	s1,8(sp)
    80002294:	6902                	ld	s2,0(sp)
    80002296:	6105                	addi	sp,sp,32
    80002298:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000229a:	9e25                	addw	a2,a2,s1
    8000229c:	1602                	slli	a2,a2,0x20
    8000229e:	9201                	srli	a2,a2,0x20
    800022a0:	1582                	slli	a1,a1,0x20
    800022a2:	9181                	srli	a1,a1,0x20
    800022a4:	6148                	ld	a0,128(a0)
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	184080e7          	jalr	388(ra) # 8000142a <uvmalloc>
    800022ae:	0005061b          	sext.w	a2,a0
    800022b2:	fa69                	bnez	a2,80002284 <growproc+0x26>
      return -1;
    800022b4:	557d                	li	a0,-1
    800022b6:	bfe1                	j	8000228e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022b8:	9e25                	addw	a2,a2,s1
    800022ba:	1602                	slli	a2,a2,0x20
    800022bc:	9201                	srli	a2,a2,0x20
    800022be:	1582                	slli	a1,a1,0x20
    800022c0:	9181                	srli	a1,a1,0x20
    800022c2:	6148                	ld	a0,128(a0)
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	11e080e7          	jalr	286(ra) # 800013e2 <uvmdealloc>
    800022cc:	0005061b          	sext.w	a2,a0
    800022d0:	bf55                	j	80002284 <growproc+0x26>

00000000800022d2 <fork>:
{
    800022d2:	7139                	addi	sp,sp,-64
    800022d4:	fc06                	sd	ra,56(sp)
    800022d6:	f822                	sd	s0,48(sp)
    800022d8:	f426                	sd	s1,40(sp)
    800022da:	f04a                	sd	s2,32(sp)
    800022dc:	ec4e                	sd	s3,24(sp)
    800022de:	e852                	sd	s4,16(sp)
    800022e0:	e456                	sd	s5,8(sp)
    800022e2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	91c080e7          	jalr	-1764(ra) # 80001c00 <myproc>
    800022ec:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800022ee:	00000097          	auipc	ra,0x0
    800022f2:	c10080e7          	jalr	-1008(ra) # 80001efe <allocproc>
    800022f6:	20050663          	beqz	a0,80002502 <fork+0x230>
    800022fa:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022fc:	0789b603          	ld	a2,120(s3)
    80002300:	614c                	ld	a1,128(a0)
    80002302:	0809b503          	ld	a0,128(s3)
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	270080e7          	jalr	624(ra) # 80001576 <uvmcopy>
    8000230e:	04054663          	bltz	a0,8000235a <fork+0x88>
  np->sz = p->sz;
    80002312:	0789b783          	ld	a5,120(s3)
    80002316:	06f93c23          	sd	a5,120(s2)
  *(np->trapframe) = *(p->trapframe);
    8000231a:	0889b683          	ld	a3,136(s3)
    8000231e:	87b6                	mv	a5,a3
    80002320:	08893703          	ld	a4,136(s2)
    80002324:	12068693          	addi	a3,a3,288
    80002328:	0007b803          	ld	a6,0(a5)
    8000232c:	6788                	ld	a0,8(a5)
    8000232e:	6b8c                	ld	a1,16(a5)
    80002330:	6f90                	ld	a2,24(a5)
    80002332:	01073023          	sd	a6,0(a4)
    80002336:	e708                	sd	a0,8(a4)
    80002338:	eb0c                	sd	a1,16(a4)
    8000233a:	ef10                	sd	a2,24(a4)
    8000233c:	02078793          	addi	a5,a5,32
    80002340:	02070713          	addi	a4,a4,32
    80002344:	fed792e3          	bne	a5,a3,80002328 <fork+0x56>
  np->trapframe->a0 = 0;
    80002348:	08893783          	ld	a5,136(s2)
    8000234c:	0607b823          	sd	zero,112(a5)
    80002350:	10000493          	li	s1,256
  for(i = 0; i < NOFILE; i++)
    80002354:	18000a13          	li	s4,384
    80002358:	a03d                	j	80002386 <fork+0xb4>
    freeproc(np);
    8000235a:	854a                	mv	a0,s2
    8000235c:	00000097          	auipc	ra,0x0
    80002360:	a5a080e7          	jalr	-1446(ra) # 80001db6 <freeproc>
    release(&np->lock);
    80002364:	854a                	mv	a0,s2
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	932080e7          	jalr	-1742(ra) # 80000c98 <release>
    return -1;
    8000236e:	5a7d                	li	s4,-1
    80002370:	aa39                	j	8000248e <fork+0x1bc>
      np->ofile[i] = filedup(p->ofile[i]);
    80002372:	00003097          	auipc	ra,0x3
    80002376:	5fe080e7          	jalr	1534(ra) # 80005970 <filedup>
    8000237a:	009907b3          	add	a5,s2,s1
    8000237e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002380:	04a1                	addi	s1,s1,8
    80002382:	01448763          	beq	s1,s4,80002390 <fork+0xbe>
    if(p->ofile[i])
    80002386:	009987b3          	add	a5,s3,s1
    8000238a:	6388                	ld	a0,0(a5)
    8000238c:	f17d                	bnez	a0,80002372 <fork+0xa0>
    8000238e:	bfcd                	j	80002380 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002390:	1809b503          	ld	a0,384(s3)
    80002394:	00002097          	auipc	ra,0x2
    80002398:	752080e7          	jalr	1874(ra) # 80004ae6 <idup>
    8000239c:	18a93023          	sd	a0,384(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800023a0:	4641                	li	a2,16
    800023a2:	18898593          	addi	a1,s3,392
    800023a6:	18890513          	addi	a0,s2,392
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	a88080e7          	jalr	-1400(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800023b2:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    800023b6:	854a                	mv	a0,s2
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800023c0:	00010497          	auipc	s1,0x10
    800023c4:	f0048493          	addi	s1,s1,-256 # 800122c0 <cpus>
    800023c8:	00010a97          	auipc	s5,0x10
    800023cc:	390a8a93          	addi	s5,s5,912 # 80012758 <wait_lock>
    800023d0:	8556                	mv	a0,s5
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	812080e7          	jalr	-2030(ra) # 80000be4 <acquire>
  np->parent = p;
    800023da:	07393423          	sd	s3,104(s2)
  release(&wait_lock);
    800023de:	8556                	mv	a0,s5
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8b8080e7          	jalr	-1864(ra) # 80000c98 <release>
  acquire(&np->lock);
    800023e8:	854a                	mv	a0,s2
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	7fa080e7          	jalr	2042(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023f2:	478d                	li	a5,3
    800023f4:	00f92c23          	sw	a5,24(s2)
  np->last_runnable_time = ticks;
    800023f8:	00008797          	auipc	a5,0x8
    800023fc:	c5c7a783          	lw	a5,-932(a5) # 8000a054 <ticks>
    80002400:	02f92e23          	sw	a5,60(s2)
    80002404:	8792                	mv	a5,tp
  int id = r_tp();
    80002406:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    8000240a:	00371793          	slli	a5,a4,0x3
    8000240e:	00e786b3          	add	a3,a5,a4
    80002412:	0692                	slli	a3,a3,0x4
    80002414:	96a6                	add	a3,a3,s1
    80002416:	08e6a423          	sw	a4,136(a3)
  if (mycpu()->runnable_list_head == -1){
    8000241a:	0806a703          	lw	a4,128(a3)
    8000241e:	57fd                	li	a5,-1
    80002420:	08f70163          	beq	a4,a5,800024a2 <fork+0x1d0>
    printf("runnable");
    80002424:	00007517          	auipc	a0,0x7
    80002428:	e8c50513          	addi	a0,a0,-372 # 800092b0 <digits+0x270>
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	15c080e7          	jalr	348(ra) # 80000588 <printf>
    80002434:	8792                	mv	a5,tp
  int id = r_tp();
    80002436:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    8000243a:	00010497          	auipc	s1,0x10
    8000243e:	e8648493          	addi	s1,s1,-378 # 800122c0 <cpus>
    80002442:	00371793          	slli	a5,a4,0x3
    80002446:	00e786b3          	add	a3,a5,a4
    8000244a:	0692                	slli	a3,a3,0x4
    8000244c:	96a6                	add	a3,a3,s1
    8000244e:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, np);
    80002452:	85ca                	mv	a1,s2
    80002454:	0846a503          	lw	a0,132(a3)
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	3ee080e7          	jalr	1006(ra) # 80001846 <add_proc_to_list>
    80002460:	8792                	mv	a5,tp
  int id = r_tp();
    80002462:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002466:	00371793          	slli	a5,a4,0x3
    8000246a:	00e786b3          	add	a3,a5,a4
    8000246e:	0692                	slli	a3,a3,0x4
    80002470:	96a6                	add	a3,a3,s1
    80002472:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = np->proc_ind;
    80002476:	05c92683          	lw	a3,92(s2)
    8000247a:	97ba                	add	a5,a5,a4
    8000247c:	0792                	slli	a5,a5,0x4
    8000247e:	94be                	add	s1,s1,a5
    80002480:	08d4a223          	sw	a3,132(s1)
  release(&np->lock);
    80002484:	854a                	mv	a0,s2
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
}
    8000248e:	8552                	mv	a0,s4
    80002490:	70e2                	ld	ra,56(sp)
    80002492:	7442                	ld	s0,48(sp)
    80002494:	74a2                	ld	s1,40(sp)
    80002496:	7902                	ld	s2,32(sp)
    80002498:	69e2                	ld	s3,24(sp)
    8000249a:	6a42                	ld	s4,16(sp)
    8000249c:	6aa2                	ld	s5,8(sp)
    8000249e:	6121                	addi	sp,sp,64
    800024a0:	8082                	ret
    printf("init runnable %d\n", p->proc_ind);
    800024a2:	05c9a583          	lw	a1,92(s3)
    800024a6:	00007517          	auipc	a0,0x7
    800024aa:	e1a50513          	addi	a0,a0,-486 # 800092c0 <digits+0x280>
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	0da080e7          	jalr	218(ra) # 80000588 <printf>
    800024b6:	8792                	mv	a5,tp
  int id = r_tp();
    800024b8:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    800024bc:	00369793          	slli	a5,a3,0x3
    800024c0:	00d78633          	add	a2,a5,a3
    800024c4:	0612                	slli	a2,a2,0x4
    800024c6:	9626                	add	a2,a2,s1
    800024c8:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = np->proc_ind;
    800024cc:	05c92603          	lw	a2,92(s2)
    800024d0:	97b6                	add	a5,a5,a3
    800024d2:	0792                	slli	a5,a5,0x4
    800024d4:	97a6                	add	a5,a5,s1
    800024d6:	08c7a023          	sw	a2,128(a5)
    800024da:	8792                	mv	a5,tp
  int id = r_tp();
    800024dc:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    800024e0:	00369793          	slli	a5,a3,0x3
    800024e4:	00d78633          	add	a2,a5,a3
    800024e8:	0612                	slli	a2,a2,0x4
    800024ea:	9626                	add	a2,a2,s1
    800024ec:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = np->proc_ind;
    800024f0:	05c92603          	lw	a2,92(s2)
    800024f4:	97b6                	add	a5,a5,a3
    800024f6:	0792                	slli	a5,a5,0x4
    800024f8:	00f48733          	add	a4,s1,a5
    800024fc:	08c72223          	sw	a2,132(a4)
    80002500:	b751                	j	80002484 <fork+0x1b2>
    return -1;
    80002502:	5a7d                	li	s4,-1
    80002504:	b769                	j	8000248e <fork+0x1bc>

0000000080002506 <unpause_system>:
{
    80002506:	7179                	addi	sp,sp,-48
    80002508:	f406                	sd	ra,40(sp)
    8000250a:	f022                	sd	s0,32(sp)
    8000250c:	ec26                	sd	s1,24(sp)
    8000250e:	e84a                	sd	s2,16(sp)
    80002510:	e44e                	sd	s3,8(sp)
    80002512:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) 
    80002514:	00010497          	auipc	s1,0x10
    80002518:	25c48493          	addi	s1,s1,604 # 80012770 <proc>
      if(p->paused == 1) 
    8000251c:	4985                	li	s3,1
  for(p = proc; p < &proc[NPROC]; p++) 
    8000251e:	00017917          	auipc	s2,0x17
    80002522:	85290913          	addi	s2,s2,-1966 # 80018d70 <tickslock>
    80002526:	a811                	j	8000253a <unpause_system+0x34>
      release(&p->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	76e080e7          	jalr	1902(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) 
    80002532:	19848493          	addi	s1,s1,408
    80002536:	01248d63          	beq	s1,s2,80002550 <unpause_system+0x4a>
      acquire(&p->lock);
    8000253a:	8526                	mv	a0,s1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	6a8080e7          	jalr	1704(ra) # 80000be4 <acquire>
      if(p->paused == 1) 
    80002544:	40bc                	lw	a5,64(s1)
    80002546:	ff3791e3          	bne	a5,s3,80002528 <unpause_system+0x22>
        p->paused = 0;
    8000254a:	0404a023          	sw	zero,64(s1)
    8000254e:	bfe9                	j	80002528 <unpause_system+0x22>
} 
    80002550:	70a2                	ld	ra,40(sp)
    80002552:	7402                	ld	s0,32(sp)
    80002554:	64e2                	ld	s1,24(sp)
    80002556:	6942                	ld	s2,16(sp)
    80002558:	69a2                	ld	s3,8(sp)
    8000255a:	6145                	addi	sp,sp,48
    8000255c:	8082                	ret

000000008000255e <SJF_scheduler>:
{
    8000255e:	711d                	addi	sp,sp,-96
    80002560:	ec86                	sd	ra,88(sp)
    80002562:	e8a2                	sd	s0,80(sp)
    80002564:	e4a6                	sd	s1,72(sp)
    80002566:	e0ca                	sd	s2,64(sp)
    80002568:	fc4e                	sd	s3,56(sp)
    8000256a:	f852                	sd	s4,48(sp)
    8000256c:	f456                	sd	s5,40(sp)
    8000256e:	f05a                	sd	s6,32(sp)
    80002570:	ec5e                	sd	s7,24(sp)
    80002572:	e862                	sd	s8,16(sp)
    80002574:	e466                	sd	s9,8(sp)
    80002576:	e06a                	sd	s10,0(sp)
    80002578:	1080                	addi	s0,sp,96
    8000257a:	8792                	mv	a5,tp
  int id = r_tp();
    8000257c:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    8000257e:	00010617          	auipc	a2,0x10
    80002582:	d4260613          	addi	a2,a2,-702 # 800122c0 <cpus>
    80002586:	00379713          	slli	a4,a5,0x3
    8000258a:	00f706b3          	add	a3,a4,a5
    8000258e:	0692                	slli	a3,a3,0x4
    80002590:	96b2                	add	a3,a3,a2
    80002592:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    80002596:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p_of_min->context);
    8000259a:	973e                	add	a4,a4,a5
    8000259c:	0712                	slli	a4,a4,0x4
    8000259e:	0721                	addi	a4,a4,8
    800025a0:	00e60d33          	add	s10,a2,a4
    struct proc* p_of_min = proc;
    800025a4:	00010a97          	auipc	s5,0x10
    800025a8:	1cca8a93          	addi	s5,s5,460 # 80012770 <proc>
    uint min = INT_MAX;
    800025ac:	80000b37          	lui	s6,0x80000
    800025b0:	fffb4b13          	not	s6,s6
           should_switch = 1;
    800025b4:	4a05                	li	s4,1
    800025b6:	89d2                	mv	s3,s4
      c->proc = p_of_min;
    800025b8:	8bb6                	mv	s7,a3
    800025ba:	a091                	j	800025fe <SJF_scheduler+0xa0>
    for(p = proc; p < &proc[NPROC]; p++) {
    800025bc:	19878793          	addi	a5,a5,408
    800025c0:	00d78c63          	beq	a5,a3,800025d8 <SJF_scheduler+0x7a>
       if(p->state == RUNNABLE) {
    800025c4:	4f98                	lw	a4,24(a5)
    800025c6:	fec71be3          	bne	a4,a2,800025bc <SJF_scheduler+0x5e>
         if (p->mean_ticks < min)
    800025ca:	5bd8                	lw	a4,52(a5)
    800025cc:	feb778e3          	bgeu	a4,a1,800025bc <SJF_scheduler+0x5e>
    800025d0:	84be                	mv	s1,a5
           min = p->mean_ticks;
    800025d2:	85ba                	mv	a1,a4
           should_switch = 1;
    800025d4:	894e                	mv	s2,s3
    800025d6:	b7dd                	j	800025bc <SJF_scheduler+0x5e>
    acquire(&p_of_min->lock);
    800025d8:	8c26                	mv	s8,s1
    800025da:	8526                	mv	a0,s1
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	608080e7          	jalr	1544(ra) # 80000be4 <acquire>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    800025e4:	03490d63          	beq	s2,s4,8000261e <SJF_scheduler+0xc0>
    release(&p_of_min->lock);
    800025e8:	8562                	mv	a0,s8
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	6ae080e7          	jalr	1710(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    800025f2:	00008797          	auipc	a5,0x8
    800025f6:	a5e7a783          	lw	a5,-1442(a5) # 8000a050 <pause_flag>
    800025fa:	0b478163          	beq	a5,s4,8000269c <SJF_scheduler+0x13e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002602:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002606:	10079073          	csrw	sstatus,a5
    int should_switch = 0;
    8000260a:	4901                	li	s2,0
    struct proc* p_of_min = proc;
    8000260c:	84d6                	mv	s1,s5
    uint min = INT_MAX;
    8000260e:	85da                	mv	a1,s6
    for(p = proc; p < &proc[NPROC]; p++) {
    80002610:	87d6                	mv	a5,s5
       if(p->state == RUNNABLE) {
    80002612:	460d                	li	a2,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80002614:	00016697          	auipc	a3,0x16
    80002618:	75c68693          	addi	a3,a3,1884 # 80018d70 <tickslock>
    8000261c:	b765                	j	800025c4 <SJF_scheduler+0x66>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    8000261e:	4c98                	lw	a4,24(s1)
    80002620:	478d                	li	a5,3
    80002622:	fcf713e3          	bne	a4,a5,800025e8 <SJF_scheduler+0x8a>
    80002626:	40bc                	lw	a5,64(s1)
    80002628:	f3e1                	bnez	a5,800025e8 <SJF_scheduler+0x8a>
      p_of_min->state = RUNNING;
    8000262a:	4791                	li	a5,4
    8000262c:	cc9c                	sw	a5,24(s1)
      p_of_min->start_running_time = ticks;
    8000262e:	00008c97          	auipc	s9,0x8
    80002632:	a26c8c93          	addi	s9,s9,-1498 # 8000a054 <ticks>
    80002636:	000ca903          	lw	s2,0(s9)
    8000263a:	0524a823          	sw	s2,80(s1)
      p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    8000263e:	44bc                	lw	a5,72(s1)
    80002640:	012787bb          	addw	a5,a5,s2
    80002644:	5cd8                	lw	a4,60(s1)
    80002646:	9f99                	subw	a5,a5,a4
    80002648:	c4bc                	sw	a5,72(s1)
      c->proc = p_of_min;
    8000264a:	009bb023          	sd	s1,0(s7) # fffffffffffff000 <end+0xffffffff7ffd7000>
      swtch(&c->context, &p_of_min->context);
    8000264e:	09048593          	addi	a1,s1,144
    80002652:	856a                	mv	a0,s10
    80002654:	00001097          	auipc	ra,0x1
    80002658:	3b2080e7          	jalr	946(ra) # 80003a06 <swtch>
      p_of_min->last_ticks= ticks - before_swtch;
    8000265c:	000ca783          	lw	a5,0(s9)
    80002660:	4127893b          	subw	s2,a5,s2
    80002664:	0324ac23          	sw	s2,56(s1)
      p_of_min->mean_ticks=((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10 ;
    80002668:	00007617          	auipc	a2,0x7
    8000266c:	3e862603          	lw	a2,1000(a2) # 80009a50 <rate>
    80002670:	46a9                	li	a3,10
    80002672:	40c687bb          	subw	a5,a3,a2
    80002676:	00016717          	auipc	a4,0x16
    8000267a:	0fa70713          	addi	a4,a4,250 # 80018770 <proc+0x6000>
    8000267e:	63472583          	lw	a1,1588(a4)
    80002682:	02b787bb          	mulw	a5,a5,a1
    80002686:	63872703          	lw	a4,1592(a4)
    8000268a:	02c7073b          	mulw	a4,a4,a2
    8000268e:	9fb9                	addw	a5,a5,a4
    80002690:	02d7d7bb          	divuw	a5,a5,a3
    80002694:	d8dc                	sw	a5,52(s1)
      c->proc = 0;
    80002696:	000bb023          	sd	zero,0(s7)
    8000269a:	b7b9                	j	800025e8 <SJF_scheduler+0x8a>
      if (wake_up_time <= ticks) 
    8000269c:	00008717          	auipc	a4,0x8
    800026a0:	9b072703          	lw	a4,-1616(a4) # 8000a04c <wake_up_time>
    800026a4:	00008797          	auipc	a5,0x8
    800026a8:	9b07a783          	lw	a5,-1616(a5) # 8000a054 <ticks>
    800026ac:	f4e7e9e3          	bltu	a5,a4,800025fe <SJF_scheduler+0xa0>
        pause_flag = 0;
    800026b0:	00008797          	auipc	a5,0x8
    800026b4:	9a07a023          	sw	zero,-1632(a5) # 8000a050 <pause_flag>
        unpause_system();
    800026b8:	00000097          	auipc	ra,0x0
    800026bc:	e4e080e7          	jalr	-434(ra) # 80002506 <unpause_system>
    800026c0:	bf3d                	j	800025fe <SJF_scheduler+0xa0>

00000000800026c2 <FCFS_scheduler>:
{
    800026c2:	7119                	addi	sp,sp,-128
    800026c4:	fc86                	sd	ra,120(sp)
    800026c6:	f8a2                	sd	s0,112(sp)
    800026c8:	f4a6                	sd	s1,104(sp)
    800026ca:	f0ca                	sd	s2,96(sp)
    800026cc:	ecce                	sd	s3,88(sp)
    800026ce:	e8d2                	sd	s4,80(sp)
    800026d0:	e4d6                	sd	s5,72(sp)
    800026d2:	e0da                	sd	s6,64(sp)
    800026d4:	fc5e                	sd	s7,56(sp)
    800026d6:	f862                	sd	s8,48(sp)
    800026d8:	f466                	sd	s9,40(sp)
    800026da:	f06a                	sd	s10,32(sp)
    800026dc:	ec6e                	sd	s11,24(sp)
    800026de:	0100                	addi	s0,sp,128
  asm volatile("mv %0, tp" : "=r" (x) );
    800026e0:	8792                	mv	a5,tp
  int id = r_tp();
    800026e2:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800026e4:	00010617          	auipc	a2,0x10
    800026e8:	bdc60613          	addi	a2,a2,-1060 # 800122c0 <cpus>
    800026ec:	00379713          	slli	a4,a5,0x3
    800026f0:	00f706b3          	add	a3,a4,a5
    800026f4:	0692                	slli	a3,a3,0x4
    800026f6:	96b2                	add	a3,a3,a2
    800026f8:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    800026fc:	0006b023          	sd	zero,0(a3)
        swtch(&c->context, &p_of_min->context);
    80002700:	973e                	add	a4,a4,a5
    80002702:	0712                	slli	a4,a4,0x4
    80002704:	0721                	addi	a4,a4,8
    80002706:	9732                	add	a4,a4,a2
    80002708:	f8e43423          	sd	a4,-120(s0)
  int should_switch = 0;
    8000270c:	4b01                	li	s6,0
    struct proc *p_of_min = proc;
    8000270e:	00010c17          	auipc	s8,0x10
    80002712:	062c0c13          	addi	s8,s8,98 # 80012770 <proc>
    uint minlast_runnable = INT_MAX;
    80002716:	80000d37          	lui	s10,0x80000
    8000271a:	fffd4d13          	not	s10,s10
          should_switch = 1;
    8000271e:	4c85                	li	s9,1
    80002720:	8be6                	mv	s7,s9
        c->proc = p_of_min;
    80002722:	8db6                	mv	s11,a3
    80002724:	a095                	j	80002788 <FCFS_scheduler+0xc6>
      release(&p->lock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	570080e7          	jalr	1392(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) 
    80002730:	19848493          	addi	s1,s1,408
    80002734:	03248463          	beq	s1,s2,8000275c <FCFS_scheduler+0x9a>
      acquire(&p->lock);
    80002738:	8526                	mv	a0,s1
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	4aa080e7          	jalr	1194(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && p->paused == 0) 
    80002742:	4c9c                	lw	a5,24(s1)
    80002744:	ff3791e3          	bne	a5,s3,80002726 <FCFS_scheduler+0x64>
    80002748:	40bc                	lw	a5,64(s1)
    8000274a:	fff1                	bnez	a5,80002726 <FCFS_scheduler+0x64>
        if(p->last_runnable_time <= minlast_runnable)
    8000274c:	5cdc                	lw	a5,60(s1)
    8000274e:	fcfa6ce3          	bltu	s4,a5,80002726 <FCFS_scheduler+0x64>
          minlast_runnable = p->mean_ticks;
    80002752:	0344aa03          	lw	s4,52(s1)
    80002756:	8aa6                	mv	s5,s1
          should_switch = 1;
    80002758:	8b5e                	mv	s6,s7
    8000275a:	b7f1                	j	80002726 <FCFS_scheduler+0x64>
    acquire(&p_of_min->lock);
    8000275c:	8956                	mv	s2,s5
    8000275e:	8556                	mv	a0,s5
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	484080e7          	jalr	1156(ra) # 80000be4 <acquire>
    if (p_of_min->paused == 0)
    80002768:	040aa483          	lw	s1,64(s5)
    8000276c:	e099                	bnez	s1,80002772 <FCFS_scheduler+0xb0>
      if (should_switch == 1 && p_of_min->pid > -1)
    8000276e:	039b0c63          	beq	s6,s9,800027a6 <FCFS_scheduler+0xe4>
    release(&p_of_min->lock);
    80002772:	854a                	mv	a0,s2
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	524080e7          	jalr	1316(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    8000277c:	00008797          	auipc	a5,0x8
    80002780:	8d47a783          	lw	a5,-1836(a5) # 8000a050 <pause_flag>
    80002784:	07978463          	beq	a5,s9,800027ec <FCFS_scheduler+0x12a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002788:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000278c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002790:	10079073          	csrw	sstatus,a5
    struct proc *p_of_min = proc;
    80002794:	8ae2                	mv	s5,s8
    uint minlast_runnable = INT_MAX;
    80002796:	8a6a                	mv	s4,s10
    for(p = proc; p < &proc[NPROC]; p++) 
    80002798:	84e2                	mv	s1,s8
      if(p->state == RUNNABLE && p->paused == 0) 
    8000279a:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) 
    8000279c:	00016917          	auipc	s2,0x16
    800027a0:	5d490913          	addi	s2,s2,1492 # 80018d70 <tickslock>
    800027a4:	bf51                	j	80002738 <FCFS_scheduler+0x76>
      if (should_switch == 1 && p_of_min->pid > -1)
    800027a6:	030aa783          	lw	a5,48(s5)
    800027aa:	fc07c4e3          	bltz	a5,80002772 <FCFS_scheduler+0xb0>
        p_of_min->state = RUNNING;
    800027ae:	4791                	li	a5,4
    800027b0:	00faac23          	sw	a5,24(s5)
        p_of_min->start_running_time = ticks;
    800027b4:	00008717          	auipc	a4,0x8
    800027b8:	8a072703          	lw	a4,-1888(a4) # 8000a054 <ticks>
    800027bc:	04eaa823          	sw	a4,80(s5)
        p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    800027c0:	048aa783          	lw	a5,72(s5)
    800027c4:	9fb9                	addw	a5,a5,a4
    800027c6:	03caa703          	lw	a4,60(s5)
    800027ca:	9f99                	subw	a5,a5,a4
    800027cc:	04faa423          	sw	a5,72(s5)
        c->proc = p_of_min;
    800027d0:	015db023          	sd	s5,0(s11)
        swtch(&c->context, &p_of_min->context);
    800027d4:	090a8593          	addi	a1,s5,144
    800027d8:	f8843503          	ld	a0,-120(s0)
    800027dc:	00001097          	auipc	ra,0x1
    800027e0:	22a080e7          	jalr	554(ra) # 80003a06 <swtch>
        c->proc = 0;
    800027e4:	000db023          	sd	zero,0(s11)
        should_switch = 0;
    800027e8:	8b26                	mv	s6,s1
    800027ea:	b761                	j	80002772 <FCFS_scheduler+0xb0>
      if (wake_up_time <= ticks) 
    800027ec:	00008717          	auipc	a4,0x8
    800027f0:	86072703          	lw	a4,-1952(a4) # 8000a04c <wake_up_time>
    800027f4:	00008797          	auipc	a5,0x8
    800027f8:	8607a783          	lw	a5,-1952(a5) # 8000a054 <ticks>
    800027fc:	f8e7e6e3          	bltu	a5,a4,80002788 <FCFS_scheduler+0xc6>
        pause_flag = 0;
    80002800:	00008797          	auipc	a5,0x8
    80002804:	8407a823          	sw	zero,-1968(a5) # 8000a050 <pause_flag>
        unpause_system();
    80002808:	00000097          	auipc	ra,0x0
    8000280c:	cfe080e7          	jalr	-770(ra) # 80002506 <unpause_system>
    80002810:	bfa5                	j	80002788 <FCFS_scheduler+0xc6>

0000000080002812 <scheduler>:
{
    80002812:	7159                	addi	sp,sp,-112
    80002814:	f486                	sd	ra,104(sp)
    80002816:	f0a2                	sd	s0,96(sp)
    80002818:	eca6                	sd	s1,88(sp)
    8000281a:	e8ca                	sd	s2,80(sp)
    8000281c:	e4ce                	sd	s3,72(sp)
    8000281e:	e0d2                	sd	s4,64(sp)
    80002820:	fc56                	sd	s5,56(sp)
    80002822:	f85a                	sd	s6,48(sp)
    80002824:	f45e                	sd	s7,40(sp)
    80002826:	f062                	sd	s8,32(sp)
    80002828:	ec66                	sd	s9,24(sp)
    8000282a:	e86a                	sd	s10,16(sp)
    8000282c:	e46e                	sd	s11,8(sp)
    8000282e:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    80002830:	8792                	mv	a5,tp
  int id = r_tp();
    80002832:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80002834:	00010c17          	auipc	s8,0x10
    80002838:	a8cc0c13          	addi	s8,s8,-1396 # 800122c0 <cpus>
    8000283c:	00379713          	slli	a4,a5,0x3
    80002840:	00f706b3          	add	a3,a4,a5
    80002844:	0692                	slli	a3,a3,0x4
    80002846:	96e2                	add	a3,a3,s8
    80002848:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    8000284c:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    80002850:	973e                	add	a4,a4,a5
    80002852:	0712                	slli	a4,a4,0x4
    80002854:	0721                	addi	a4,a4,8
    80002856:	9c3a                	add	s8,s8,a4
    printf("start sched\n");
    80002858:	00007a17          	auipc	s4,0x7
    8000285c:	a80a0a13          	addi	s4,s4,-1408 # 800092d8 <digits+0x298>
    if (c->runnable_list_head != -1)
    80002860:	8936                	mv	s2,a3
    80002862:	59fd                	li	s3,-1
    80002864:	19800b13          	li	s6,408
      p = &proc[c->runnable_list_head];
    80002868:	00010a97          	auipc	s5,0x10
    8000286c:	f08a8a93          	addi	s5,s5,-248 # 80012770 <proc>
      printf("proc ind: %d\n", c->runnable_list_head);
    80002870:	00007c97          	auipc	s9,0x7
    80002874:	a78c8c93          	addi	s9,s9,-1416 # 800092e8 <digits+0x2a8>
        proc[p->prev_proc].next_proc = -1;
    80002878:	5bfd                	li	s7,-1
    8000287a:	a075                	j	80002926 <scheduler+0x114>
        c->runnable_list_head = -1;
    8000287c:	09792023          	sw	s7,128(s2)
        c->runnable_list_tail = -1;
    80002880:	09792223          	sw	s7,132(s2)
      acquire(&p->lock);
    80002884:	856a                	mv	a0,s10
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	35e080e7          	jalr	862(ra) # 80000be4 <acquire>
      p->prev_proc = -1;
    8000288e:	036487b3          	mul	a5,s1,s6
    80002892:	97d6                	add	a5,a5,s5
    80002894:	0777a223          	sw	s7,100(a5)
      p->next_proc = -1;
    80002898:	0777a023          	sw	s7,96(a5)
      p->state = RUNNING;
    8000289c:	4711                	li	a4,4
    8000289e:	cf98                	sw	a4,24(a5)
      p->cpu_num = c->cpu_id;
    800028a0:	08892703          	lw	a4,136(s2)
    800028a4:	cfb8                	sw	a4,88(a5)
      c->proc = p;
    800028a6:	01a93023          	sd	s10,0(s2)
      swtch(&c->context, &p->context);
    800028aa:	090d8593          	addi	a1,s11,144
    800028ae:	95d6                	add	a1,a1,s5
    800028b0:	8562                	mv	a0,s8
    800028b2:	00001097          	auipc	ra,0x1
    800028b6:	154080e7          	jalr	340(ra) # 80003a06 <swtch>
      printf("runable");
    800028ba:	00007517          	auipc	a0,0x7
    800028be:	a4e50513          	addi	a0,a0,-1458 # 80009308 <digits+0x2c8>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	cc6080e7          	jalr	-826(ra) # 80000588 <printf>
      if (c->runnable_list_head == -1)
    800028ca:	08092783          	lw	a5,128(s2)
    800028ce:	0f379c63          	bne	a5,s3,800029c6 <scheduler+0x1b4>
        printf("init runnable %d\n", p->proc_ind);
    800028d2:	036484b3          	mul	s1,s1,s6
    800028d6:	94d6                	add	s1,s1,s5
    800028d8:	4cec                	lw	a1,92(s1)
    800028da:	00007517          	auipc	a0,0x7
    800028de:	9e650513          	addi	a0,a0,-1562 # 800092c0 <digits+0x280>
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	ca6080e7          	jalr	-858(ra) # 80000588 <printf>
        c->runnable_list_head = p->proc_ind;
    800028ea:	4cfc                	lw	a5,92(s1)
    800028ec:	08f92023          	sw	a5,128(s2)
        c->runnable_list_tail = p->proc_ind;
    800028f0:	08f92223          	sw	a5,132(s2)
      printf("added back: %d\n", c->runnable_list_tail);
    800028f4:	08492583          	lw	a1,132(s2)
    800028f8:	00007517          	auipc	a0,0x7
    800028fc:	a1850513          	addi	a0,a0,-1512 # 80009310 <digits+0x2d0>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c88080e7          	jalr	-888(ra) # 80000588 <printf>
      c->proc = 0;
    80002908:	00093023          	sd	zero,0(s2)
      release(&p->lock);
    8000290c:	856a                	mv	a0,s10
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	38a080e7          	jalr	906(ra) # 80000c98 <release>
      printf("end sched\n");
    80002916:	00007517          	auipc	a0,0x7
    8000291a:	a0a50513          	addi	a0,a0,-1526 # 80009320 <digits+0x2e0>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c6a080e7          	jalr	-918(ra) # 80000588 <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002926:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000292a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000292e:	10079073          	csrw	sstatus,a5
    printf("start sched\n");
    80002932:	8552                	mv	a0,s4
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	c54080e7          	jalr	-940(ra) # 80000588 <printf>
    if (c->runnable_list_head != -1)
    8000293c:	08092483          	lw	s1,128(s2)
    80002940:	ff3483e3          	beq	s1,s3,80002926 <scheduler+0x114>
      p = &proc[c->runnable_list_head];
    80002944:	03648db3          	mul	s11,s1,s6
    80002948:	015d8d33          	add	s10,s11,s5
      printf("proc ind: %d\n", c->runnable_list_head);
    8000294c:	85a6                	mv	a1,s1
    8000294e:	8566                	mv	a0,s9
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	c38080e7          	jalr	-968(ra) # 80000588 <printf>
      printf("runnable");
    80002958:	00007517          	auipc	a0,0x7
    8000295c:	95850513          	addi	a0,a0,-1704 # 800092b0 <digits+0x270>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c28080e7          	jalr	-984(ra) # 80000588 <printf>
      int res = remove_proc_from_list(p->proc_ind); 
    80002968:	05cd2503          	lw	a0,92(s10) # ffffffff8000005c <end+0xfffffffefffd805c>
    8000296c:	fffff097          	auipc	ra,0xfffff
    80002970:	f54080e7          	jalr	-172(ra) # 800018c0 <remove_proc_from_list>
      if (res == 1){
    80002974:	4785                	li	a5,1
    80002976:	f0f503e3          	beq	a0,a5,8000287c <scheduler+0x6a>
      if (res == 2)
    8000297a:	4789                	li	a5,2
    8000297c:	02f50163          	beq	a0,a5,8000299e <scheduler+0x18c>
      if (res == 3){
    80002980:	478d                	li	a5,3
    80002982:	f0f511e3          	bne	a0,a5,80002884 <scheduler+0x72>
        c->runnable_list_tail = p->prev_proc;
    80002986:	036487b3          	mul	a5,s1,s6
    8000298a:	97d6                	add	a5,a5,s5
    8000298c:	53fc                	lw	a5,100(a5)
    8000298e:	08f92223          	sw	a5,132(s2)
        proc[p->prev_proc].next_proc = -1;
    80002992:	036787b3          	mul	a5,a5,s6
    80002996:	97d6                	add	a5,a5,s5
    80002998:	0777a023          	sw	s7,96(a5)
    8000299c:	b5e5                	j	80002884 <scheduler+0x72>
        c->runnable_list_head = p->next_proc;
    8000299e:	036487b3          	mul	a5,s1,s6
    800029a2:	97d6                	add	a5,a5,s5
    800029a4:	53ac                	lw	a1,96(a5)
    800029a6:	08b92023          	sw	a1,128(s2)
        proc[p->next_proc].prev_proc = -1;
    800029aa:	036587b3          	mul	a5,a1,s6
    800029ae:	97d6                	add	a5,a5,s5
    800029b0:	0777a223          	sw	s7,100(a5)
        printf("New head: %d\n", c->runnable_list_head);
    800029b4:	00007517          	auipc	a0,0x7
    800029b8:	94450513          	addi	a0,a0,-1724 # 800092f8 <digits+0x2b8>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bcc080e7          	jalr	-1076(ra) # 80000588 <printf>
      if (res == 3){
    800029c4:	b5c1                	j	80002884 <scheduler+0x72>
        add_proc_to_list(c->runnable_list_tail, p);
    800029c6:	85ea                	mv	a1,s10
    800029c8:	08492503          	lw	a0,132(s2)
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	e7a080e7          	jalr	-390(ra) # 80001846 <add_proc_to_list>
        c->runnable_list_tail = p->proc_ind;
    800029d4:	036484b3          	mul	s1,s1,s6
    800029d8:	94d6                	add	s1,s1,s5
    800029da:	4cfc                	lw	a5,92(s1)
    800029dc:	08f92223          	sw	a5,132(s2)
    800029e0:	bf11                	j	800028f4 <scheduler+0xe2>

00000000800029e2 <sched>:
{
    800029e2:	7179                	addi	sp,sp,-48
    800029e4:	f406                	sd	ra,40(sp)
    800029e6:	f022                	sd	s0,32(sp)
    800029e8:	ec26                	sd	s1,24(sp)
    800029ea:	e84a                	sd	s2,16(sp)
    800029ec:	e44e                	sd	s3,8(sp)
    800029ee:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	210080e7          	jalr	528(ra) # 80001c00 <myproc>
    800029f8:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	170080e7          	jalr	368(ra) # 80000b6a <holding>
    80002a02:	c55d                	beqz	a0,80002ab0 <sched+0xce>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a04:	8792                	mv	a5,tp
  int id = r_tp();
    80002a06:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002a0a:	00010617          	auipc	a2,0x10
    80002a0e:	8b660613          	addi	a2,a2,-1866 # 800122c0 <cpus>
    80002a12:	00371793          	slli	a5,a4,0x3
    80002a16:	00e786b3          	add	a3,a5,a4
    80002a1a:	0692                	slli	a3,a3,0x4
    80002a1c:	96b2                	add	a3,a3,a2
    80002a1e:	08e6a423          	sw	a4,136(a3)
  if(mycpu()->noff != 1)
    80002a22:	5eb8                	lw	a4,120(a3)
    80002a24:	4785                	li	a5,1
    80002a26:	08f71d63          	bne	a4,a5,80002ac0 <sched+0xde>
  if(p->state == RUNNING)
    80002a2a:	01892703          	lw	a4,24(s2)
    80002a2e:	4791                	li	a5,4
    80002a30:	0af70063          	beq	a4,a5,80002ad0 <sched+0xee>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002a3a:	e3dd                	bnez	a5,80002ae0 <sched+0xfe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a3c:	8792                	mv	a5,tp
  int id = r_tp();
    80002a3e:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002a42:	00010497          	auipc	s1,0x10
    80002a46:	87e48493          	addi	s1,s1,-1922 # 800122c0 <cpus>
    80002a4a:	00371793          	slli	a5,a4,0x3
    80002a4e:	00e786b3          	add	a3,a5,a4
    80002a52:	0692                	slli	a3,a3,0x4
    80002a54:	96a6                	add	a3,a3,s1
    80002a56:	08e6a423          	sw	a4,136(a3)
  intena = mycpu()->intena;
    80002a5a:	07c6a983          	lw	s3,124(a3)
    80002a5e:	8592                	mv	a1,tp
  int id = r_tp();
    80002a60:	0005879b          	sext.w	a5,a1
  c->cpu_id = id;
    80002a64:	00379593          	slli	a1,a5,0x3
    80002a68:	00f58733          	add	a4,a1,a5
    80002a6c:	0712                	slli	a4,a4,0x4
    80002a6e:	9726                	add	a4,a4,s1
    80002a70:	08f72423          	sw	a5,136(a4)
  swtch(&p->context, &mycpu()->context);
    80002a74:	95be                	add	a1,a1,a5
    80002a76:	0592                	slli	a1,a1,0x4
    80002a78:	05a1                	addi	a1,a1,8
    80002a7a:	95a6                	add	a1,a1,s1
    80002a7c:	09090513          	addi	a0,s2,144
    80002a80:	00001097          	auipc	ra,0x1
    80002a84:	f86080e7          	jalr	-122(ra) # 80003a06 <swtch>
    80002a88:	8792                	mv	a5,tp
  int id = r_tp();
    80002a8a:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002a8e:	00371793          	slli	a5,a4,0x3
    80002a92:	00e786b3          	add	a3,a5,a4
    80002a96:	0692                	slli	a3,a3,0x4
    80002a98:	96a6                	add	a3,a3,s1
    80002a9a:	08e6a423          	sw	a4,136(a3)
  mycpu()->intena = intena;
    80002a9e:	0736ae23          	sw	s3,124(a3)
}
    80002aa2:	70a2                	ld	ra,40(sp)
    80002aa4:	7402                	ld	s0,32(sp)
    80002aa6:	64e2                	ld	s1,24(sp)
    80002aa8:	6942                	ld	s2,16(sp)
    80002aaa:	69a2                	ld	s3,8(sp)
    80002aac:	6145                	addi	sp,sp,48
    80002aae:	8082                	ret
    panic("sched p->lock");
    80002ab0:	00007517          	auipc	a0,0x7
    80002ab4:	88050513          	addi	a0,a0,-1920 # 80009330 <digits+0x2f0>
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	a86080e7          	jalr	-1402(ra) # 8000053e <panic>
    panic("sched locks");
    80002ac0:	00007517          	auipc	a0,0x7
    80002ac4:	88050513          	addi	a0,a0,-1920 # 80009340 <digits+0x300>
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	a76080e7          	jalr	-1418(ra) # 8000053e <panic>
    panic("sched running");
    80002ad0:	00007517          	auipc	a0,0x7
    80002ad4:	88050513          	addi	a0,a0,-1920 # 80009350 <digits+0x310>
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	a66080e7          	jalr	-1434(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002ae0:	00007517          	auipc	a0,0x7
    80002ae4:	88050513          	addi	a0,a0,-1920 # 80009360 <digits+0x320>
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	a56080e7          	jalr	-1450(ra) # 8000053e <panic>

0000000080002af0 <yield>:
{
    80002af0:	1101                	addi	sp,sp,-32
    80002af2:	ec06                	sd	ra,24(sp)
    80002af4:	e822                	sd	s0,16(sp)
    80002af6:	e426                	sd	s1,8(sp)
    80002af8:	e04a                	sd	s2,0(sp)
    80002afa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	104080e7          	jalr	260(ra) # 80001c00 <myproc>
    80002b04:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	0de080e7          	jalr	222(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002b0e:	478d                	li	a5,3
    80002b10:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002b12:	00007797          	auipc	a5,0x7
    80002b16:	5427a783          	lw	a5,1346(a5) # 8000a054 <ticks>
    80002b1a:	dcdc                	sw	a5,60(s1)
    80002b1c:	8792                	mv	a5,tp
  int id = r_tp();
    80002b1e:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b22:	0000f617          	auipc	a2,0xf
    80002b26:	79e60613          	addi	a2,a2,1950 # 800122c0 <cpus>
    80002b2a:	00371793          	slli	a5,a4,0x3
    80002b2e:	00e786b3          	add	a3,a5,a4
    80002b32:	0692                	slli	a3,a3,0x4
    80002b34:	96b2                	add	a3,a3,a2
    80002b36:	08e6a423          	sw	a4,136(a3)
   if (mycpu()->runnable_list_head == -1)
    80002b3a:	0806a703          	lw	a4,128(a3)
    80002b3e:	57fd                	li	a5,-1
    80002b40:	08f70063          	beq	a4,a5,80002bc0 <yield+0xd0>
    printf("runable");
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	7c450513          	addi	a0,a0,1988 # 80009308 <digits+0x2c8>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	a3c080e7          	jalr	-1476(ra) # 80000588 <printf>
    80002b54:	8792                	mv	a5,tp
  int id = r_tp();
    80002b56:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b5a:	0000f917          	auipc	s2,0xf
    80002b5e:	76690913          	addi	s2,s2,1894 # 800122c0 <cpus>
    80002b62:	00371793          	slli	a5,a4,0x3
    80002b66:	00e786b3          	add	a3,a5,a4
    80002b6a:	0692                	slli	a3,a3,0x4
    80002b6c:	96ca                	add	a3,a3,s2
    80002b6e:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    80002b72:	85a6                	mv	a1,s1
    80002b74:	0846a503          	lw	a0,132(a3)
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	cce080e7          	jalr	-818(ra) # 80001846 <add_proc_to_list>
    80002b80:	8792                	mv	a5,tp
  int id = r_tp();
    80002b82:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b86:	00371793          	slli	a5,a4,0x3
    80002b8a:	00e786b3          	add	a3,a5,a4
    80002b8e:	0692                	slli	a3,a3,0x4
    80002b90:	96ca                	add	a3,a3,s2
    80002b92:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002b96:	4cf4                	lw	a3,92(s1)
    80002b98:	97ba                	add	a5,a5,a4
    80002b9a:	0792                	slli	a5,a5,0x4
    80002b9c:	993e                	add	s2,s2,a5
    80002b9e:	08d92223          	sw	a3,132(s2)
  sched();
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	e40080e7          	jalr	-448(ra) # 800029e2 <sched>
  release(&p->lock);
    80002baa:	8526                	mv	a0,s1
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	0ec080e7          	jalr	236(ra) # 80000c98 <release>
}
    80002bb4:	60e2                	ld	ra,24(sp)
    80002bb6:	6442                	ld	s0,16(sp)
    80002bb8:	64a2                	ld	s1,8(sp)
    80002bba:	6902                	ld	s2,0(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret
     printf("init runnable : %d", p->proc_ind);
    80002bc0:	4cec                	lw	a1,92(s1)
    80002bc2:	00006517          	auipc	a0,0x6
    80002bc6:	7b650513          	addi	a0,a0,1974 # 80009378 <digits+0x338>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	9be080e7          	jalr	-1602(ra) # 80000588 <printf>
    80002bd2:	8792                	mv	a5,tp
  int id = r_tp();
    80002bd4:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002bd8:	0000f717          	auipc	a4,0xf
    80002bdc:	6e870713          	addi	a4,a4,1768 # 800122c0 <cpus>
    80002be0:	00369793          	slli	a5,a3,0x3
    80002be4:	00d78633          	add	a2,a5,a3
    80002be8:	0612                	slli	a2,a2,0x4
    80002bea:	963a                	add	a2,a2,a4
    80002bec:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    80002bf0:	4cf0                	lw	a2,92(s1)
    80002bf2:	97b6                	add	a5,a5,a3
    80002bf4:	0792                	slli	a5,a5,0x4
    80002bf6:	97ba                	add	a5,a5,a4
    80002bf8:	08c7a023          	sw	a2,128(a5)
    80002bfc:	8792                	mv	a5,tp
  int id = r_tp();
    80002bfe:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002c02:	00369793          	slli	a5,a3,0x3
    80002c06:	00d78633          	add	a2,a5,a3
    80002c0a:	0612                	slli	a2,a2,0x4
    80002c0c:	963a                	add	a2,a2,a4
    80002c0e:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002c12:	4cf0                	lw	a2,92(s1)
    80002c14:	97b6                	add	a5,a5,a3
    80002c16:	0792                	slli	a5,a5,0x4
    80002c18:	973e                	add	a4,a4,a5
    80002c1a:	08c72223          	sw	a2,132(a4)
    80002c1e:	b751                	j	80002ba2 <yield+0xb2>

0000000080002c20 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002c20:	7179                	addi	sp,sp,-48
    80002c22:	f406                	sd	ra,40(sp)
    80002c24:	f022                	sd	s0,32(sp)
    80002c26:	ec26                	sd	s1,24(sp)
    80002c28:	e84a                	sd	s2,16(sp)
    80002c2a:	e44e                	sd	s3,8(sp)
    80002c2c:	1800                	addi	s0,sp,48
    80002c2e:	89aa                	mv	s3,a0
    80002c30:	892e                	mv	s2,a1
  // TODO: remove from RUNNABLE and add to SLEEPING
  struct proc *p = myproc();
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	fce080e7          	jalr	-50(ra) # 80001c00 <myproc>
    80002c3a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	fa8080e7          	jalr	-88(ra) # 80000be4 <acquire>
  release(lk);
    80002c44:	854a                	mv	a0,s2
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	052080e7          	jalr	82(ra) # 80000c98 <release>

  //Ass2
  printf("runable");
    80002c4e:	00006517          	auipc	a0,0x6
    80002c52:	6ba50513          	addi	a0,a0,1722 # 80009308 <digits+0x2c8>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	932080e7          	jalr	-1742(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80002c5e:	4ce8                	lw	a0,92(s1)
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	c60080e7          	jalr	-928(ra) # 800018c0 <remove_proc_from_list>
  if (res == 1){
    80002c68:	4785                	li	a5,1
    80002c6a:	08f50f63          	beq	a0,a5,80002d08 <sleep+0xe8>
    mycpu()->runnable_list_head = -1;
    mycpu()->runnable_list_tail = -1;
  }
  if (res == 2){
    80002c6e:	4789                	li	a5,2
    80002c70:	0cf50c63          	beq	a0,a5,80002d48 <sleep+0x128>
    mycpu()->runnable_list_head = p->next_proc;
    proc[p->next_proc].prev_proc = -1;
  }
  if (res == 3){
    80002c74:	478d                	li	a5,3
    80002c76:	10f50a63          	beq	a0,a5,80002d8a <sleep+0x16a>
    mycpu()->runnable_list_tail = p->prev_proc;
    proc[p->prev_proc].next_proc = -1;
  }

  p->next_proc = -1;
    80002c7a:	57fd                	li	a5,-1
    80002c7c:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80002c7e:	d0fc                	sw	a5,100(s1)

  // Go to sleep.
  p->chan = chan;
    80002c80:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002c84:	4789                	li	a5,2
    80002c86:	cc9c                	sw	a5,24(s1)
  p->start_sleeping_time = ticks;
    80002c88:	00007797          	auipc	a5,0x7
    80002c8c:	3cc7a783          	lw	a5,972(a5) # 8000a054 <ticks>
    80002c90:	c8fc                	sw	a5,84(s1)

  if (sleeping_list_tail != -1){
    80002c92:	00007717          	auipc	a4,0x7
    80002c96:	db672703          	lw	a4,-586(a4) # 80009a48 <sleeping_list_tail>
    80002c9a:	57fd                	li	a5,-1
    80002c9c:	12f70e63          	beq	a4,a5,80002dd8 <sleep+0x1b8>
    printf("sleeping");
    80002ca0:	00006517          	auipc	a0,0x6
    80002ca4:	6f050513          	addi	a0,a0,1776 # 80009390 <digits+0x350>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	8e0080e7          	jalr	-1824(ra) # 80000588 <printf>
    add_proc_to_list(sleeping_list_tail, p);
    80002cb0:	85a6                	mv	a1,s1
    80002cb2:	00007517          	auipc	a0,0x7
    80002cb6:	d9652503          	lw	a0,-618(a0) # 80009a48 <sleeping_list_tail>
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	b8c080e7          	jalr	-1140(ra) # 80001846 <add_proc_to_list>
    if (sleeping_list_head == -1)
    80002cc2:	00007717          	auipc	a4,0x7
    80002cc6:	d8a72703          	lw	a4,-630(a4) # 80009a4c <sleeping_list_head>
    80002cca:	57fd                	li	a5,-1
    80002ccc:	10f70063          	beq	a4,a5,80002dcc <sleep+0x1ac>
      {
        sleeping_list_head = p->proc_ind;
      }
    sleeping_list_tail = p->proc_ind;
    80002cd0:	4cfc                	lw	a5,92(s1)
    80002cd2:	00007717          	auipc	a4,0x7
    80002cd6:	d6f72b23          	sw	a5,-650(a4) # 80009a48 <sleeping_list_tail>
    printf("head in sleeping\n");
    sleeping_list_tail =  p->proc_ind;
    sleeping_list_head = p->proc_ind;
  }

  sched();
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	d08080e7          	jalr	-760(ra) # 800029e2 <sched>

  // Tidy up.
  p->chan = 0;
    80002ce2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002ce6:	8526                	mv	a0,s1
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	fb0080e7          	jalr	-80(ra) # 80000c98 <release>
  acquire(lk);
    80002cf0:	854a                	mv	a0,s2
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	ef2080e7          	jalr	-270(ra) # 80000be4 <acquire>
}
    80002cfa:	70a2                	ld	ra,40(sp)
    80002cfc:	7402                	ld	s0,32(sp)
    80002cfe:	64e2                	ld	s1,24(sp)
    80002d00:	6942                	ld	s2,16(sp)
    80002d02:	69a2                	ld	s3,8(sp)
    80002d04:	6145                	addi	sp,sp,48
    80002d06:	8082                	ret
    80002d08:	8792                	mv	a5,tp
  int id = r_tp();
    80002d0a:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002d0e:	0000f717          	auipc	a4,0xf
    80002d12:	5b270713          	addi	a4,a4,1458 # 800122c0 <cpus>
    80002d16:	00369793          	slli	a5,a3,0x3
    80002d1a:	00d78633          	add	a2,a5,a3
    80002d1e:	0612                	slli	a2,a2,0x4
    80002d20:	963a                	add	a2,a2,a4
    80002d22:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = -1;
    80002d26:	55fd                	li	a1,-1
    80002d28:	08b62023          	sw	a1,128(a2)
    80002d2c:	8792                	mv	a5,tp
  int id = r_tp();
    80002d2e:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002d32:	00369793          	slli	a5,a3,0x3
    80002d36:	00d78633          	add	a2,a5,a3
    80002d3a:	0612                	slli	a2,a2,0x4
    80002d3c:	963a                	add	a2,a2,a4
    80002d3e:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = -1;
    80002d42:	08b62223          	sw	a1,132(a2)
  if (res == 3){
    80002d46:	bf15                	j	80002c7a <sleep+0x5a>
    80002d48:	8792                	mv	a5,tp
  int id = r_tp();
    80002d4a:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002d4e:	0000f617          	auipc	a2,0xf
    80002d52:	57260613          	addi	a2,a2,1394 # 800122c0 <cpus>
    80002d56:	00371793          	slli	a5,a4,0x3
    80002d5a:	00e786b3          	add	a3,a5,a4
    80002d5e:	0692                	slli	a3,a3,0x4
    80002d60:	96b2                	add	a3,a3,a2
    80002d62:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_head = p->next_proc;
    80002d66:	50b4                	lw	a3,96(s1)
    80002d68:	97ba                	add	a5,a5,a4
    80002d6a:	0792                	slli	a5,a5,0x4
    80002d6c:	97b2                	add	a5,a5,a2
    80002d6e:	08d7a023          	sw	a3,128(a5)
    proc[p->next_proc].prev_proc = -1;
    80002d72:	19800793          	li	a5,408
    80002d76:	02f686b3          	mul	a3,a3,a5
    80002d7a:	00010797          	auipc	a5,0x10
    80002d7e:	9f678793          	addi	a5,a5,-1546 # 80012770 <proc>
    80002d82:	96be                	add	a3,a3,a5
    80002d84:	57fd                	li	a5,-1
    80002d86:	d2fc                	sw	a5,100(a3)
  if (res == 3){
    80002d88:	bdcd                	j	80002c7a <sleep+0x5a>
    80002d8a:	8792                	mv	a5,tp
  int id = r_tp();
    80002d8c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002d90:	0000f617          	auipc	a2,0xf
    80002d94:	53060613          	addi	a2,a2,1328 # 800122c0 <cpus>
    80002d98:	00371793          	slli	a5,a4,0x3
    80002d9c:	00e786b3          	add	a3,a5,a4
    80002da0:	0692                	slli	a3,a3,0x4
    80002da2:	96b2                	add	a3,a3,a2
    80002da4:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->prev_proc;
    80002da8:	50f4                	lw	a3,100(s1)
    80002daa:	97ba                	add	a5,a5,a4
    80002dac:	0792                	slli	a5,a5,0x4
    80002dae:	97b2                	add	a5,a5,a2
    80002db0:	08d7a223          	sw	a3,132(a5)
    proc[p->prev_proc].next_proc = -1;
    80002db4:	19800793          	li	a5,408
    80002db8:	02f686b3          	mul	a3,a3,a5
    80002dbc:	00010797          	auipc	a5,0x10
    80002dc0:	9b478793          	addi	a5,a5,-1612 # 80012770 <proc>
    80002dc4:	96be                	add	a3,a3,a5
    80002dc6:	57fd                	li	a5,-1
    80002dc8:	d2bc                	sw	a5,96(a3)
    80002dca:	bd45                	j	80002c7a <sleep+0x5a>
        sleeping_list_head = p->proc_ind;
    80002dcc:	4cfc                	lw	a5,92(s1)
    80002dce:	00007717          	auipc	a4,0x7
    80002dd2:	c6f72f23          	sw	a5,-898(a4) # 80009a4c <sleeping_list_head>
    80002dd6:	bded                	j	80002cd0 <sleep+0xb0>
    printf("head in sleeping\n");
    80002dd8:	00006517          	auipc	a0,0x6
    80002ddc:	5c850513          	addi	a0,a0,1480 # 800093a0 <digits+0x360>
    80002de0:	ffffd097          	auipc	ra,0xffffd
    80002de4:	7a8080e7          	jalr	1960(ra) # 80000588 <printf>
    sleeping_list_tail =  p->proc_ind;
    80002de8:	4cfc                	lw	a5,92(s1)
    80002dea:	00007717          	auipc	a4,0x7
    80002dee:	c4f72f23          	sw	a5,-930(a4) # 80009a48 <sleeping_list_tail>
    sleeping_list_head = p->proc_ind;
    80002df2:	00007717          	auipc	a4,0x7
    80002df6:	c4f72d23          	sw	a5,-934(a4) # 80009a4c <sleeping_list_head>
    80002dfa:	b5c5                	j	80002cda <sleep+0xba>

0000000080002dfc <wait>:
{
    80002dfc:	711d                	addi	sp,sp,-96
    80002dfe:	ec86                	sd	ra,88(sp)
    80002e00:	e8a2                	sd	s0,80(sp)
    80002e02:	e4a6                	sd	s1,72(sp)
    80002e04:	e0ca                	sd	s2,64(sp)
    80002e06:	fc4e                	sd	s3,56(sp)
    80002e08:	f852                	sd	s4,48(sp)
    80002e0a:	f456                	sd	s5,40(sp)
    80002e0c:	f05a                	sd	s6,32(sp)
    80002e0e:	ec5e                	sd	s7,24(sp)
    80002e10:	e862                	sd	s8,16(sp)
    80002e12:	e466                	sd	s9,8(sp)
    80002e14:	1080                	addi	s0,sp,96
    80002e16:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	de8080e7          	jalr	-536(ra) # 80001c00 <myproc>
    80002e20:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002e22:	00010517          	auipc	a0,0x10
    80002e26:	93650513          	addi	a0,a0,-1738 # 80012758 <wait_lock>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	dba080e7          	jalr	-582(ra) # 80000be4 <acquire>
    havekids = 0;
    80002e32:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002e34:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002e36:	00016997          	auipc	s3,0x16
    80002e3a:	f3a98993          	addi	s3,s3,-198 # 80018d70 <tickslock>
        havekids = 1;
    80002e3e:	4a85                	li	s5,1
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002e40:	00007c97          	auipc	s9,0x7
    80002e44:	214c8c93          	addi	s9,s9,532 # 8000a054 <ticks>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002e48:	00010c17          	auipc	s8,0x10
    80002e4c:	910c0c13          	addi	s8,s8,-1776 # 80012758 <wait_lock>
    havekids = 0;
    80002e50:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002e52:	00010497          	auipc	s1,0x10
    80002e56:	91e48493          	addi	s1,s1,-1762 # 80012770 <proc>
    80002e5a:	a0bd                	j	80002ec8 <wait+0xcc>
          pid = np->pid;
    80002e5c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002e60:	000b0e63          	beqz	s6,80002e7c <wait+0x80>
    80002e64:	4691                	li	a3,4
    80002e66:	02c48613          	addi	a2,s1,44
    80002e6a:	85da                	mv	a1,s6
    80002e6c:	08093503          	ld	a0,128(s2)
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	80a080e7          	jalr	-2038(ra) # 8000167a <copyout>
    80002e78:	02054563          	bltz	a0,80002ea2 <wait+0xa6>
          freeproc(np);
    80002e7c:	8526                	mv	a0,s1
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	f38080e7          	jalr	-200(ra) # 80001db6 <freeproc>
          release(&np->lock);
    80002e86:	8526                	mv	a0,s1
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	e10080e7          	jalr	-496(ra) # 80000c98 <release>
          release(&wait_lock);
    80002e90:	00010517          	auipc	a0,0x10
    80002e94:	8c850513          	addi	a0,a0,-1848 # 80012758 <wait_lock>
    80002e98:	ffffe097          	auipc	ra,0xffffe
    80002e9c:	e00080e7          	jalr	-512(ra) # 80000c98 <release>
          return pid;
    80002ea0:	a09d                	j	80002f06 <wait+0x10a>
            release(&np->lock);
    80002ea2:	8526                	mv	a0,s1
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	df4080e7          	jalr	-524(ra) # 80000c98 <release>
            release(&wait_lock);
    80002eac:	00010517          	auipc	a0,0x10
    80002eb0:	8ac50513          	addi	a0,a0,-1876 # 80012758 <wait_lock>
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	de4080e7          	jalr	-540(ra) # 80000c98 <release>
            return -1;
    80002ebc:	59fd                	li	s3,-1
    80002ebe:	a0a1                	j	80002f06 <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002ec0:	19848493          	addi	s1,s1,408
    80002ec4:	03348463          	beq	s1,s3,80002eec <wait+0xf0>
      if(np->parent == p){
    80002ec8:	74bc                	ld	a5,104(s1)
    80002eca:	ff279be3          	bne	a5,s2,80002ec0 <wait+0xc4>
        acquire(&np->lock);
    80002ece:	8526                	mv	a0,s1
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	d14080e7          	jalr	-748(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002ed8:	4c9c                	lw	a5,24(s1)
    80002eda:	f94781e3          	beq	a5,s4,80002e5c <wait+0x60>
        release(&np->lock);
    80002ede:	8526                	mv	a0,s1
    80002ee0:	ffffe097          	auipc	ra,0xffffe
    80002ee4:	db8080e7          	jalr	-584(ra) # 80000c98 <release>
        havekids = 1;
    80002ee8:	8756                	mv	a4,s5
    80002eea:	bfd9                	j	80002ec0 <wait+0xc4>
    if(!havekids || p->killed){
    80002eec:	c701                	beqz	a4,80002ef4 <wait+0xf8>
    80002eee:	02892783          	lw	a5,40(s2)
    80002ef2:	cb85                	beqz	a5,80002f22 <wait+0x126>
      release(&wait_lock);
    80002ef4:	00010517          	auipc	a0,0x10
    80002ef8:	86450513          	addi	a0,a0,-1948 # 80012758 <wait_lock>
    80002efc:	ffffe097          	auipc	ra,0xffffe
    80002f00:	d9c080e7          	jalr	-612(ra) # 80000c98 <release>
      return -1;
    80002f04:	59fd                	li	s3,-1
}
    80002f06:	854e                	mv	a0,s3
    80002f08:	60e6                	ld	ra,88(sp)
    80002f0a:	6446                	ld	s0,80(sp)
    80002f0c:	64a6                	ld	s1,72(sp)
    80002f0e:	6906                	ld	s2,64(sp)
    80002f10:	79e2                	ld	s3,56(sp)
    80002f12:	7a42                	ld	s4,48(sp)
    80002f14:	7aa2                	ld	s5,40(sp)
    80002f16:	7b02                	ld	s6,32(sp)
    80002f18:	6be2                	ld	s7,24(sp)
    80002f1a:	6c42                	ld	s8,16(sp)
    80002f1c:	6ca2                	ld	s9,8(sp)
    80002f1e:	6125                	addi	sp,sp,96
    80002f20:	8082                	ret
    if (p->state == RUNNING)
    80002f22:	01892783          	lw	a5,24(s2)
    80002f26:	4711                	li	a4,4
    80002f28:	02e78063          	beq	a5,a4,80002f48 <wait+0x14c>
     if (p->state == RUNNABLE)
    80002f2c:	470d                	li	a4,3
    80002f2e:	02e79e63          	bne	a5,a4,80002f6a <wait+0x16e>
      p->runnable_time += ticks - p->last_runnable_time;
    80002f32:	04892783          	lw	a5,72(s2)
    80002f36:	000ca703          	lw	a4,0(s9)
    80002f3a:	9fb9                	addw	a5,a5,a4
    80002f3c:	03c92703          	lw	a4,60(s2)
    80002f40:	9f99                	subw	a5,a5,a4
    80002f42:	04f92423          	sw	a5,72(s2)
    if (p->state == SLEEPING)
    80002f46:	a819                	j	80002f5c <wait+0x160>
      p->running_time += ticks - p->start_running_time;
    80002f48:	04492783          	lw	a5,68(s2)
    80002f4c:	000ca703          	lw	a4,0(s9)
    80002f50:	9fb9                	addw	a5,a5,a4
    80002f52:	05092703          	lw	a4,80(s2)
    80002f56:	9f99                	subw	a5,a5,a4
    80002f58:	04f92223          	sw	a5,68(s2)
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002f5c:	85e2                	mv	a1,s8
    80002f5e:	854a                	mv	a0,s2
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	cc0080e7          	jalr	-832(ra) # 80002c20 <sleep>
    havekids = 0;
    80002f68:	b5e5                	j	80002e50 <wait+0x54>
    if (p->state == SLEEPING)
    80002f6a:	4709                	li	a4,2
    80002f6c:	fee798e3          	bne	a5,a4,80002f5c <wait+0x160>
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002f70:	04c92783          	lw	a5,76(s2)
    80002f74:	000ca703          	lw	a4,0(s9)
    80002f78:	9fb9                	addw	a5,a5,a4
    80002f7a:	05492703          	lw	a4,84(s2)
    80002f7e:	9f99                	subw	a5,a5,a4
    80002f80:	04f92623          	sw	a5,76(s2)
    80002f84:	bfe1                	j	80002f5c <wait+0x160>

0000000080002f86 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002f86:	7179                	addi	sp,sp,-48
    80002f88:	f406                	sd	ra,40(sp)
    80002f8a:	f022                	sd	s0,32(sp)
    80002f8c:	ec26                	sd	s1,24(sp)
    80002f8e:	e84a                	sd	s2,16(sp)
    80002f90:	e44e                	sd	s3,8(sp)
    80002f92:	1800                	addi	s0,sp,48
  // TODO: go threw all SLEEPING and pick one to wake up- remove from SLEEPING and add to RUNNABLE.
  // struct proc *p;
  
  // printf("wakeup\n");
  struct proc *p = &proc[sleeping_list_head];
    80002f94:	00007917          	auipc	s2,0x7
    80002f98:	ab892903          	lw	s2,-1352(s2) # 80009a4c <sleeping_list_head>

  if (sleeping_list_head != -1)
    80002f9c:	57fd                	li	a5,-1
    80002f9e:	00f91963          	bne	s2,a5,80002fb0 <wakeup+0x2a>
  //     }
  //     release(&p->lock);
  //   }
  // }
  }
}
    80002fa2:	70a2                	ld	ra,40(sp)
    80002fa4:	7402                	ld	s0,32(sp)
    80002fa6:	64e2                	ld	s1,24(sp)
    80002fa8:	6942                	ld	s2,16(sp)
    80002faa:	69a2                	ld	s3,8(sp)
    80002fac:	6145                	addi	sp,sp,48
    80002fae:	8082                	ret
    printf("sleeping");
    80002fb0:	00006517          	auipc	a0,0x6
    80002fb4:	3e050513          	addi	a0,a0,992 # 80009390 <digits+0x350>
    80002fb8:	ffffd097          	auipc	ra,0xffffd
    80002fbc:	5d0080e7          	jalr	1488(ra) # 80000588 <printf>
    int res = remove_proc_from_list(p->proc_ind); 
    80002fc0:	19800793          	li	a5,408
    80002fc4:	02f90733          	mul	a4,s2,a5
    80002fc8:	0000f797          	auipc	a5,0xf
    80002fcc:	7a878793          	addi	a5,a5,1960 # 80012770 <proc>
    80002fd0:	97ba                	add	a5,a5,a4
    80002fd2:	4fe8                	lw	a0,92(a5)
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	8ec080e7          	jalr	-1812(ra) # 800018c0 <remove_proc_from_list>
      if (res == 1){
    80002fdc:	4785                	li	a5,1
    80002fde:	02f50963          	beq	a0,a5,80003010 <wakeup+0x8a>
      if (res == 2)
    80002fe2:	4789                	li	a5,2
    80002fe4:	0ef51363          	bne	a0,a5,800030ca <wakeup+0x144>
        sleeping_list_head = p->next_proc;
    80002fe8:	0000f797          	auipc	a5,0xf
    80002fec:	78878793          	addi	a5,a5,1928 # 80012770 <proc>
    80002ff0:	19800613          	li	a2,408
    80002ff4:	02c906b3          	mul	a3,s2,a2
    80002ff8:	96be                	add	a3,a3,a5
    80002ffa:	52b8                	lw	a4,96(a3)
    80002ffc:	00007697          	auipc	a3,0x7
    80003000:	a4e6a823          	sw	a4,-1456(a3) # 80009a4c <sleeping_list_head>
        proc[p->next_proc].prev_proc = -1;
    80003004:	02c70733          	mul	a4,a4,a2
    80003008:	97ba                	add	a5,a5,a4
    8000300a:	577d                	li	a4,-1
    8000300c:	d3f8                	sw	a4,100(a5)
      if (res == 3){
    8000300e:	a811                	j	80003022 <wakeup+0x9c>
        sleeping_list_head = -1;
    80003010:	57fd                	li	a5,-1
    80003012:	00007717          	auipc	a4,0x7
    80003016:	a2f72d23          	sw	a5,-1478(a4) # 80009a4c <sleeping_list_head>
        sleeping_list_tail = -1;
    8000301a:	00007717          	auipc	a4,0x7
    8000301e:	a2f72723          	sw	a5,-1490(a4) # 80009a48 <sleeping_list_tail>
  struct proc *p = &proc[sleeping_list_head];
    80003022:	19800493          	li	s1,408
    80003026:	029904b3          	mul	s1,s2,s1
    8000302a:	0000f797          	auipc	a5,0xf
    8000302e:	74678793          	addi	a5,a5,1862 # 80012770 <proc>
    80003032:	94be                	add	s1,s1,a5
      acquire(&p->lock);
    80003034:	8526                	mv	a0,s1
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	bae080e7          	jalr	-1106(ra) # 80000be4 <acquire>
      p->state = RUNNABLE;
    8000303e:	478d                	li	a5,3
    80003040:	cc9c                	sw	a5,24(s1)
      p->prev_proc = -1;
    80003042:	57fd                	li	a5,-1
    80003044:	d0fc                	sw	a5,100(s1)
      p->next_proc = -1;
    80003046:	d0bc                	sw	a5,96(s1)
      release(&p->lock);
    80003048:	8526                	mv	a0,s1
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	c4e080e7          	jalr	-946(ra) # 80000c98 <release>
      printf("runnable");
    80003052:	00006517          	auipc	a0,0x6
    80003056:	25e50513          	addi	a0,a0,606 # 800092b0 <digits+0x270>
    8000305a:	ffffd097          	auipc	ra,0xffffd
    8000305e:	52e080e7          	jalr	1326(ra) # 80000588 <printf>
      if (cpus[p->cpu_num].runnable_list_head == -1)
    80003062:	4cb8                	lw	a4,88(s1)
    80003064:	00371793          	slli	a5,a4,0x3
    80003068:	97ba                	add	a5,a5,a4
    8000306a:	0792                	slli	a5,a5,0x4
    8000306c:	0000f697          	auipc	a3,0xf
    80003070:	25468693          	addi	a3,a3,596 # 800122c0 <cpus>
    80003074:	97b6                	add	a5,a5,a3
    80003076:	0807a683          	lw	a3,128(a5)
    8000307a:	57fd                	li	a5,-1
    8000307c:	06f68e63          	beq	a3,a5,800030f8 <wakeup+0x172>
        add_proc_to_list(cpus[p->cpu_num].runnable_list_tail, p);
    80003080:	0000f997          	auipc	s3,0xf
    80003084:	24098993          	addi	s3,s3,576 # 800122c0 <cpus>
    80003088:	00371793          	slli	a5,a4,0x3
    8000308c:	97ba                	add	a5,a5,a4
    8000308e:	0792                	slli	a5,a5,0x4
    80003090:	97ce                	add	a5,a5,s3
    80003092:	85a6                	mv	a1,s1
    80003094:	0847a503          	lw	a0,132(a5)
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	7ae080e7          	jalr	1966(ra) # 80001846 <add_proc_to_list>
        cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    800030a0:	19800793          	li	a5,408
    800030a4:	02f90933          	mul	s2,s2,a5
    800030a8:	0000f797          	auipc	a5,0xf
    800030ac:	6c878793          	addi	a5,a5,1736 # 80012770 <proc>
    800030b0:	993e                	add	s2,s2,a5
    800030b2:	05892703          	lw	a4,88(s2)
    800030b6:	00371793          	slli	a5,a4,0x3
    800030ba:	97ba                	add	a5,a5,a4
    800030bc:	0792                	slli	a5,a5,0x4
    800030be:	97ce                	add	a5,a5,s3
    800030c0:	05c92703          	lw	a4,92(s2)
    800030c4:	08e7a223          	sw	a4,132(a5)
}
    800030c8:	bde9                	j	80002fa2 <wakeup+0x1c>
      if (res == 3){
    800030ca:	478d                	li	a5,3
    800030cc:	f4f51be3          	bne	a0,a5,80003022 <wakeup+0x9c>
        sleeping_list_tail = p->prev_proc;
    800030d0:	0000f797          	auipc	a5,0xf
    800030d4:	6a078793          	addi	a5,a5,1696 # 80012770 <proc>
    800030d8:	19800613          	li	a2,408
    800030dc:	02c906b3          	mul	a3,s2,a2
    800030e0:	96be                	add	a3,a3,a5
    800030e2:	52f8                	lw	a4,100(a3)
    800030e4:	00007697          	auipc	a3,0x7
    800030e8:	96e6a223          	sw	a4,-1692(a3) # 80009a48 <sleeping_list_tail>
        proc[p->prev_proc].next_proc = -1;
    800030ec:	02c70733          	mul	a4,a4,a2
    800030f0:	97ba                	add	a5,a5,a4
    800030f2:	577d                	li	a4,-1
    800030f4:	d3b8                	sw	a4,96(a5)
    800030f6:	b735                	j	80003022 <wakeup+0x9c>
        printf("init runnable %d\n", p->proc_ind);
    800030f8:	4cec                	lw	a1,92(s1)
    800030fa:	00006517          	auipc	a0,0x6
    800030fe:	1c650513          	addi	a0,a0,454 # 800092c0 <digits+0x280>
    80003102:	ffffd097          	auipc	ra,0xffffd
    80003106:	486080e7          	jalr	1158(ra) # 80000588 <printf>
        cpus[p->cpu_num].runnable_list_head = p->proc_ind;
    8000310a:	4cb0                	lw	a2,88(s1)
    8000310c:	4cec                	lw	a1,92(s1)
    8000310e:	0000f697          	auipc	a3,0xf
    80003112:	1b268693          	addi	a3,a3,434 # 800122c0 <cpus>
    80003116:	00361793          	slli	a5,a2,0x3
    8000311a:	00c78733          	add	a4,a5,a2
    8000311e:	0712                	slli	a4,a4,0x4
    80003120:	9736                	add	a4,a4,a3
    80003122:	08b72023          	sw	a1,128(a4)
        cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    80003126:	08b72223          	sw	a1,132(a4)
    8000312a:	bda5                	j	80002fa2 <wakeup+0x1c>

000000008000312c <reparent>:
{
    8000312c:	7179                	addi	sp,sp,-48
    8000312e:	f406                	sd	ra,40(sp)
    80003130:	f022                	sd	s0,32(sp)
    80003132:	ec26                	sd	s1,24(sp)
    80003134:	e84a                	sd	s2,16(sp)
    80003136:	e44e                	sd	s3,8(sp)
    80003138:	e052                	sd	s4,0(sp)
    8000313a:	1800                	addi	s0,sp,48
    8000313c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000313e:	0000f497          	auipc	s1,0xf
    80003142:	63248493          	addi	s1,s1,1586 # 80012770 <proc>
      pp->parent = initproc;
    80003146:	00007a17          	auipc	s4,0x7
    8000314a:	ee2a0a13          	addi	s4,s4,-286 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000314e:	00016997          	auipc	s3,0x16
    80003152:	c2298993          	addi	s3,s3,-990 # 80018d70 <tickslock>
    80003156:	a029                	j	80003160 <reparent+0x34>
    80003158:	19848493          	addi	s1,s1,408
    8000315c:	01348d63          	beq	s1,s3,80003176 <reparent+0x4a>
    if(pp->parent == p){
    80003160:	74bc                	ld	a5,104(s1)
    80003162:	ff279be3          	bne	a5,s2,80003158 <reparent+0x2c>
      pp->parent = initproc;
    80003166:	000a3503          	ld	a0,0(s4)
    8000316a:	f4a8                	sd	a0,104(s1)
      wakeup(initproc);
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	e1a080e7          	jalr	-486(ra) # 80002f86 <wakeup>
    80003174:	b7d5                	j	80003158 <reparent+0x2c>
}
    80003176:	70a2                	ld	ra,40(sp)
    80003178:	7402                	ld	s0,32(sp)
    8000317a:	64e2                	ld	s1,24(sp)
    8000317c:	6942                	ld	s2,16(sp)
    8000317e:	69a2                	ld	s3,8(sp)
    80003180:	6a02                	ld	s4,0(sp)
    80003182:	6145                	addi	sp,sp,48
    80003184:	8082                	ret

0000000080003186 <exit>:
{
    80003186:	7179                	addi	sp,sp,-48
    80003188:	f406                	sd	ra,40(sp)
    8000318a:	f022                	sd	s0,32(sp)
    8000318c:	ec26                	sd	s1,24(sp)
    8000318e:	e84a                	sd	s2,16(sp)
    80003190:	e44e                	sd	s3,8(sp)
    80003192:	e052                	sd	s4,0(sp)
    80003194:	1800                	addi	s0,sp,48
    80003196:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80003198:	fffff097          	auipc	ra,0xfffff
    8000319c:	a68080e7          	jalr	-1432(ra) # 80001c00 <myproc>
    800031a0:	892a                	mv	s2,a0
  if(p == initproc)
    800031a2:	00007797          	auipc	a5,0x7
    800031a6:	e867b783          	ld	a5,-378(a5) # 8000a028 <initproc>
    800031aa:	10050493          	addi	s1,a0,256
    800031ae:	18050993          	addi	s3,a0,384
    800031b2:	02a79363          	bne	a5,a0,800031d8 <exit+0x52>
    panic("init exiting");
    800031b6:	00006517          	auipc	a0,0x6
    800031ba:	20250513          	addi	a0,a0,514 # 800093b8 <digits+0x378>
    800031be:	ffffd097          	auipc	ra,0xffffd
    800031c2:	380080e7          	jalr	896(ra) # 8000053e <panic>
      fileclose(f);
    800031c6:	00002097          	auipc	ra,0x2
    800031ca:	7fc080e7          	jalr	2044(ra) # 800059c2 <fileclose>
      p->ofile[fd] = 0;
    800031ce:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800031d2:	04a1                	addi	s1,s1,8
    800031d4:	00998563          	beq	s3,s1,800031de <exit+0x58>
    if(p->ofile[fd]){
    800031d8:	6088                	ld	a0,0(s1)
    800031da:	f575                	bnez	a0,800031c6 <exit+0x40>
    800031dc:	bfdd                	j	800031d2 <exit+0x4c>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800031de:	18890493          	addi	s1,s2,392
    800031e2:	00006597          	auipc	a1,0x6
    800031e6:	1e658593          	addi	a1,a1,486 # 800093c8 <digits+0x388>
    800031ea:	8526                	mv	a0,s1
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	ed4080e7          	jalr	-300(ra) # 800020c0 <str_compare>
    800031f4:	e97d                	bnez	a0,800032ea <exit+0x164>
  begin_op();
    800031f6:	00002097          	auipc	ra,0x2
    800031fa:	300080e7          	jalr	768(ra) # 800054f6 <begin_op>
  iput(p->cwd);
    800031fe:	18093503          	ld	a0,384(s2)
    80003202:	00002097          	auipc	ra,0x2
    80003206:	adc080e7          	jalr	-1316(ra) # 80004cde <iput>
  end_op();
    8000320a:	00002097          	auipc	ra,0x2
    8000320e:	36c080e7          	jalr	876(ra) # 80005576 <end_op>
  p->cwd = 0;
    80003212:	18093023          	sd	zero,384(s2)
  acquire(&wait_lock);
    80003216:	0000f517          	auipc	a0,0xf
    8000321a:	54250513          	addi	a0,a0,1346 # 80012758 <wait_lock>
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	9c6080e7          	jalr	-1594(ra) # 80000be4 <acquire>
  reparent(p);
    80003226:	854a                	mv	a0,s2
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	f04080e7          	jalr	-252(ra) # 8000312c <reparent>
  wakeup(p->parent);
    80003230:	06893503          	ld	a0,104(s2)
    80003234:	00000097          	auipc	ra,0x0
    80003238:	d52080e7          	jalr	-686(ra) # 80002f86 <wakeup>
  acquire(&p->lock);
    8000323c:	854a                	mv	a0,s2
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	9a6080e7          	jalr	-1626(ra) # 80000be4 <acquire>
  p->xstate = status;
    80003246:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000324a:	4795                	li	a5,5
    8000324c:	00f92c23          	sw	a5,24(s2)
  p->running_time += ticks - p->start_running_time;
    80003250:	04492783          	lw	a5,68(s2)
    80003254:	00007717          	auipc	a4,0x7
    80003258:	e0072703          	lw	a4,-512(a4) # 8000a054 <ticks>
    8000325c:	9fb9                	addw	a5,a5,a4
    8000325e:	05092703          	lw	a4,80(s2)
    80003262:	9f99                	subw	a5,a5,a4
    80003264:	04f92223          	sw	a5,68(s2)
  printf("runable");
    80003268:	00006517          	auipc	a0,0x6
    8000326c:	0a050513          	addi	a0,a0,160 # 80009308 <digits+0x2c8>
    80003270:	ffffd097          	auipc	ra,0xffffd
    80003274:	318080e7          	jalr	792(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80003278:	05c92503          	lw	a0,92(s2)
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	644080e7          	jalr	1604(ra) # 800018c0 <remove_proc_from_list>
  if (res == 1){
    80003284:	4785                	li	a5,1
    80003286:	10f50863          	beq	a0,a5,80003396 <exit+0x210>
  if (res == 2){
    8000328a:	4789                	li	a5,2
    8000328c:	12f50f63          	beq	a0,a5,800033ca <exit+0x244>
  if (res == 3){
    80003290:	478d                	li	a5,3
    80003292:	16f50963          	beq	a0,a5,80003404 <exit+0x27e>
  p->next_proc = -1;
    80003296:	57fd                	li	a5,-1
    80003298:	06f92023          	sw	a5,96(s2)
  p->prev_proc = -1;
    8000329c:	06f92223          	sw	a5,100(s2)
  if (zombie_list_tail != -1){
    800032a0:	00006717          	auipc	a4,0x6
    800032a4:	79872703          	lw	a4,1944(a4) # 80009a38 <zombie_list_tail>
    800032a8:	57fd                	li	a5,-1
    800032aa:	18f71a63          	bne	a4,a5,8000343e <exit+0x2b8>
    zombie_list_tail = zombie_list_head = p->proc_ind;
    800032ae:	05c92783          	lw	a5,92(s2)
    800032b2:	00006717          	auipc	a4,0x6
    800032b6:	78f72523          	sw	a5,1930(a4) # 80009a3c <zombie_list_head>
    800032ba:	00006717          	auipc	a4,0x6
    800032be:	76f72f23          	sw	a5,1918(a4) # 80009a38 <zombie_list_tail>
  release(&wait_lock);
    800032c2:	0000f517          	auipc	a0,0xf
    800032c6:	49650513          	addi	a0,a0,1174 # 80012758 <wait_lock>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	9ce080e7          	jalr	-1586(ra) # 80000c98 <release>
  sched();
    800032d2:	fffff097          	auipc	ra,0xfffff
    800032d6:	710080e7          	jalr	1808(ra) # 800029e2 <sched>
  panic("zombie exit");
    800032da:	00006517          	auipc	a0,0x6
    800032de:	0fe50513          	addi	a0,a0,254 # 800093d8 <digits+0x398>
    800032e2:	ffffd097          	auipc	ra,0xffffd
    800032e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800032ea:	00006597          	auipc	a1,0x6
    800032ee:	0e658593          	addi	a1,a1,230 # 800093d0 <digits+0x390>
    800032f2:	8526                	mv	a0,s1
    800032f4:	fffff097          	auipc	ra,0xfffff
    800032f8:	dcc080e7          	jalr	-564(ra) # 800020c0 <str_compare>
    800032fc:	ee050de3          	beqz	a0,800031f6 <exit+0x70>
    sleeping_processes_mean = ((sleeping_processes_mean * p_counter)+ p->sleeping_time)/(p_counter+1);
    80003300:	00007597          	auipc	a1,0x7
    80003304:	d3c58593          	addi	a1,a1,-708 # 8000a03c <p_counter>
    80003308:	4194                	lw	a3,0(a1)
    8000330a:	0016871b          	addiw	a4,a3,1
    8000330e:	00007617          	auipc	a2,0x7
    80003312:	d3a60613          	addi	a2,a2,-710 # 8000a048 <sleeping_processes_mean>
    80003316:	421c                	lw	a5,0(a2)
    80003318:	02d787bb          	mulw	a5,a5,a3
    8000331c:	04c92503          	lw	a0,76(s2)
    80003320:	9fa9                	addw	a5,a5,a0
    80003322:	02e7d7bb          	divuw	a5,a5,a4
    80003326:	c21c                	sw	a5,0(a2)
    running_processes_mean = ((running_processes_mean * p_counter)+ p->running_time)/(p_counter+1);
    80003328:	04492603          	lw	a2,68(s2)
    8000332c:	00007517          	auipc	a0,0x7
    80003330:	d1850513          	addi	a0,a0,-744 # 8000a044 <running_processes_mean>
    80003334:	411c                	lw	a5,0(a0)
    80003336:	02d787bb          	mulw	a5,a5,a3
    8000333a:	9fb1                	addw	a5,a5,a2
    8000333c:	02e7d7bb          	divuw	a5,a5,a4
    80003340:	c11c                	sw	a5,0(a0)
    runnable_processes_mean = ((runnable_processes_mean * p_counter)+ p->runnable_time)/(p_counter+1);
    80003342:	00007517          	auipc	a0,0x7
    80003346:	cfe50513          	addi	a0,a0,-770 # 8000a040 <runnable_processes_mean>
    8000334a:	411c                	lw	a5,0(a0)
    8000334c:	02d787bb          	mulw	a5,a5,a3
    80003350:	04892683          	lw	a3,72(s2)
    80003354:	9fb5                	addw	a5,a5,a3
    80003356:	02e7d7bb          	divuw	a5,a5,a4
    8000335a:	c11c                	sw	a5,0(a0)
    p_counter += 1;
    8000335c:	c198                	sw	a4,0(a1)
    program_time += p->running_time;
    8000335e:	00007697          	auipc	a3,0x7
    80003362:	cda68693          	addi	a3,a3,-806 # 8000a038 <program_time>
    80003366:	429c                	lw	a5,0(a3)
    80003368:	00c7873b          	addw	a4,a5,a2
    8000336c:	c298                	sw	a4,0(a3)
    cpu_utilization = (program_time* 100) / (ticks - start_time) ;
    8000336e:	06400793          	li	a5,100
    80003372:	02e787bb          	mulw	a5,a5,a4
    80003376:	00007717          	auipc	a4,0x7
    8000337a:	cde72703          	lw	a4,-802(a4) # 8000a054 <ticks>
    8000337e:	00007697          	auipc	a3,0x7
    80003382:	cb66a683          	lw	a3,-842(a3) # 8000a034 <start_time>
    80003386:	9f15                	subw	a4,a4,a3
    80003388:	02e7d7bb          	divuw	a5,a5,a4
    8000338c:	00007717          	auipc	a4,0x7
    80003390:	caf72223          	sw	a5,-860(a4) # 8000a030 <cpu_utilization>
    80003394:	b58d                	j	800031f6 <exit+0x70>
    80003396:	8612                	mv	a2,tp
  int id = r_tp();
    80003398:	2601                	sext.w	a2,a2
  c->cpu_id = id;
    8000339a:	0000f797          	auipc	a5,0xf
    8000339e:	f2678793          	addi	a5,a5,-218 # 800122c0 <cpus>
    800033a2:	09000693          	li	a3,144
    800033a6:	02d60733          	mul	a4,a2,a3
    800033aa:	973e                	add	a4,a4,a5
    800033ac:	08c72423          	sw	a2,136(a4)
    mycpu()->runnable_list_head = -1;
    800033b0:	567d                	li	a2,-1
    800033b2:	08c72023          	sw	a2,128(a4)
    800033b6:	8712                	mv	a4,tp
  int id = r_tp();
    800033b8:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    800033ba:	02d706b3          	mul	a3,a4,a3
    800033be:	97b6                	add	a5,a5,a3
    800033c0:	08e7a423          	sw	a4,136(a5)
    mycpu()->runnable_list_tail = -1;
    800033c4:	08c7a223          	sw	a2,132(a5)
  if (res == 3){
    800033c8:	b5f9                	j	80003296 <exit+0x110>
    800033ca:	8792                	mv	a5,tp
  int id = r_tp();
    800033cc:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800033ce:	09000713          	li	a4,144
    800033d2:	02e786b3          	mul	a3,a5,a4
    800033d6:	0000f717          	auipc	a4,0xf
    800033da:	eea70713          	addi	a4,a4,-278 # 800122c0 <cpus>
    800033de:	9736                	add	a4,a4,a3
    800033e0:	08f72423          	sw	a5,136(a4)
    mycpu()->runnable_list_head = p->next_proc;
    800033e4:	06092783          	lw	a5,96(s2)
    800033e8:	08f72023          	sw	a5,128(a4)
    proc[p->next_proc].prev_proc = -1;
    800033ec:	19800713          	li	a4,408
    800033f0:	02e787b3          	mul	a5,a5,a4
    800033f4:	0000f717          	auipc	a4,0xf
    800033f8:	37c70713          	addi	a4,a4,892 # 80012770 <proc>
    800033fc:	97ba                	add	a5,a5,a4
    800033fe:	577d                	li	a4,-1
    80003400:	d3f8                	sw	a4,100(a5)
  if (res == 3){
    80003402:	bd51                	j	80003296 <exit+0x110>
    80003404:	8792                	mv	a5,tp
  int id = r_tp();
    80003406:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80003408:	09000713          	li	a4,144
    8000340c:	02e786b3          	mul	a3,a5,a4
    80003410:	0000f717          	auipc	a4,0xf
    80003414:	eb070713          	addi	a4,a4,-336 # 800122c0 <cpus>
    80003418:	9736                	add	a4,a4,a3
    8000341a:	08f72423          	sw	a5,136(a4)
    mycpu()->runnable_list_tail = p->prev_proc;
    8000341e:	06492783          	lw	a5,100(s2)
    80003422:	08f72223          	sw	a5,132(a4)
    proc[p->prev_proc].next_proc = -1;
    80003426:	19800713          	li	a4,408
    8000342a:	02e787b3          	mul	a5,a5,a4
    8000342e:	0000f717          	auipc	a4,0xf
    80003432:	34270713          	addi	a4,a4,834 # 80012770 <proc>
    80003436:	97ba                	add	a5,a5,a4
    80003438:	577d                	li	a4,-1
    8000343a:	d3b8                	sw	a4,96(a5)
    8000343c:	bda9                	j	80003296 <exit+0x110>
    printf("zombie");
    8000343e:	00006517          	auipc	a0,0x6
    80003442:	e3a50513          	addi	a0,a0,-454 # 80009278 <digits+0x238>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	142080e7          	jalr	322(ra) # 80000588 <printf>
    add_proc_to_list(zombie_list_tail, p);
    8000344e:	85ca                	mv	a1,s2
    80003450:	00006517          	auipc	a0,0x6
    80003454:	5e852503          	lw	a0,1512(a0) # 80009a38 <zombie_list_tail>
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	3ee080e7          	jalr	1006(ra) # 80001846 <add_proc_to_list>
     if (zombie_list_head == -1)
    80003460:	00006717          	auipc	a4,0x6
    80003464:	5dc72703          	lw	a4,1500(a4) # 80009a3c <zombie_list_head>
    80003468:	57fd                	li	a5,-1
    8000346a:	00f70963          	beq	a4,a5,8000347c <exit+0x2f6>
    zombie_list_tail = p->proc_ind;
    8000346e:	05c92783          	lw	a5,92(s2)
    80003472:	00006717          	auipc	a4,0x6
    80003476:	5cf72323          	sw	a5,1478(a4) # 80009a38 <zombie_list_tail>
    8000347a:	b5a1                	j	800032c2 <exit+0x13c>
        zombie_list_head = p->proc_ind;
    8000347c:	05c92783          	lw	a5,92(s2)
    80003480:	00006717          	auipc	a4,0x6
    80003484:	5af72e23          	sw	a5,1468(a4) # 80009a3c <zombie_list_head>
    80003488:	b7dd                	j	8000346e <exit+0x2e8>

000000008000348a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000348a:	7179                	addi	sp,sp,-48
    8000348c:	f406                	sd	ra,40(sp)
    8000348e:	f022                	sd	s0,32(sp)
    80003490:	ec26                	sd	s1,24(sp)
    80003492:	e84a                	sd	s2,16(sp)
    80003494:	e44e                	sd	s3,8(sp)
    80003496:	1800                	addi	s0,sp,48
    80003498:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000349a:	0000f497          	auipc	s1,0xf
    8000349e:	2d648493          	addi	s1,s1,726 # 80012770 <proc>
    800034a2:	00016997          	auipc	s3,0x16
    800034a6:	8ce98993          	addi	s3,s3,-1842 # 80018d70 <tickslock>
    acquire(&p->lock);
    800034aa:	8526                	mv	a0,s1
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	738080e7          	jalr	1848(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800034b4:	589c                	lw	a5,48(s1)
    800034b6:	01278d63          	beq	a5,s2,800034d0 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800034ba:	8526                	mv	a0,s1
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800034c4:	19848493          	addi	s1,s1,408
    800034c8:	ff3491e3          	bne	s1,s3,800034aa <kill+0x20>
  }
  return -1;
    800034cc:	557d                	li	a0,-1
    800034ce:	a829                	j	800034e8 <kill+0x5e>
      p->killed = 1;
    800034d0:	4785                	li	a5,1
    800034d2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800034d4:	4c98                	lw	a4,24(s1)
    800034d6:	4789                	li	a5,2
    800034d8:	00f70f63          	beq	a4,a5,800034f6 <kill+0x6c>
      release(&p->lock);
    800034dc:	8526                	mv	a0,s1
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	7ba080e7          	jalr	1978(ra) # 80000c98 <release>
      return 0;
    800034e6:	4501                	li	a0,0
}
    800034e8:	70a2                	ld	ra,40(sp)
    800034ea:	7402                	ld	s0,32(sp)
    800034ec:	64e2                	ld	s1,24(sp)
    800034ee:	6942                	ld	s2,16(sp)
    800034f0:	69a2                	ld	s3,8(sp)
    800034f2:	6145                	addi	sp,sp,48
    800034f4:	8082                	ret
        p->state = RUNNABLE;
    800034f6:	478d                	li	a5,3
    800034f8:	cc9c                	sw	a5,24(s1)
        p->sleeping_time += ticks - p->start_sleeping_time;
    800034fa:	00007717          	auipc	a4,0x7
    800034fe:	b5a72703          	lw	a4,-1190(a4) # 8000a054 <ticks>
    80003502:	44fc                	lw	a5,76(s1)
    80003504:	9fb9                	addw	a5,a5,a4
    80003506:	48f4                	lw	a3,84(s1)
    80003508:	9f95                	subw	a5,a5,a3
    8000350a:	c4fc                	sw	a5,76(s1)
        p->last_runnable_time = ticks;
    8000350c:	dcd8                	sw	a4,60(s1)
    8000350e:	b7f9                	j	800034dc <kill+0x52>

0000000080003510 <print_stats>:

int 
print_stats(void)
{
    80003510:	1141                	addi	sp,sp,-16
    80003512:	e406                	sd	ra,8(sp)
    80003514:	e022                	sd	s0,0(sp)
    80003516:	0800                	addi	s0,sp,16
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    80003518:	00007597          	auipc	a1,0x7
    8000351c:	b305a583          	lw	a1,-1232(a1) # 8000a048 <sleeping_processes_mean>
    80003520:	00006517          	auipc	a0,0x6
    80003524:	ec850513          	addi	a0,a0,-312 # 800093e8 <digits+0x3a8>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	060080e7          	jalr	96(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    80003530:	00007597          	auipc	a1,0x7
    80003534:	b105a583          	lw	a1,-1264(a1) # 8000a040 <runnable_processes_mean>
    80003538:	00006517          	auipc	a0,0x6
    8000353c:	ed050513          	addi	a0,a0,-304 # 80009408 <digits+0x3c8>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	048080e7          	jalr	72(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    80003548:	00007597          	auipc	a1,0x7
    8000354c:	afc5a583          	lw	a1,-1284(a1) # 8000a044 <running_processes_mean>
    80003550:	00006517          	auipc	a0,0x6
    80003554:	ed850513          	addi	a0,a0,-296 # 80009428 <digits+0x3e8>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	030080e7          	jalr	48(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80003560:	00007597          	auipc	a1,0x7
    80003564:	ad85a583          	lw	a1,-1320(a1) # 8000a038 <program_time>
    80003568:	00006517          	auipc	a0,0x6
    8000356c:	ee050513          	addi	a0,a0,-288 # 80009448 <digits+0x408>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	018080e7          	jalr	24(ra) # 80000588 <printf>
  printf("cpu_utilization: %d\n", cpu_utilization);
    80003578:	00007597          	auipc	a1,0x7
    8000357c:	ab85a583          	lw	a1,-1352(a1) # 8000a030 <cpu_utilization>
    80003580:	00006517          	auipc	a0,0x6
    80003584:	ee050513          	addi	a0,a0,-288 # 80009460 <digits+0x420>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	000080e7          	jalr	ra # 80000588 <printf>
  printf("ticks: %d\n", ticks);
    80003590:	00007597          	auipc	a1,0x7
    80003594:	ac45a583          	lw	a1,-1340(a1) # 8000a054 <ticks>
    80003598:	00006517          	auipc	a0,0x6
    8000359c:	ee050513          	addi	a0,a0,-288 # 80009478 <digits+0x438>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	fe8080e7          	jalr	-24(ra) # 80000588 <printf>
  return 0;
}
    800035a8:	4501                	li	a0,0
    800035aa:	60a2                	ld	ra,8(sp)
    800035ac:	6402                	ld	s0,0(sp)
    800035ae:	0141                	addi	sp,sp,16
    800035b0:	8082                	ret

00000000800035b2 <set_cpu>:
// Ass2
int
set_cpu(int cpu_num)
{
  // TODO
  if (cpu_num > NCPU)
    800035b2:	47a1                	li	a5,8
    800035b4:	0aa7cd63          	blt	a5,a0,8000366e <set_cpu+0xbc>
{
    800035b8:	1101                	addi	sp,sp,-32
    800035ba:	ec06                	sd	ra,24(sp)
    800035bc:	e822                	sd	s0,16(sp)
    800035be:	e426                	sd	s1,8(sp)
    800035c0:	e04a                	sd	s2,0(sp)
    800035c2:	1000                	addi	s0,sp,32
    return -1;

  struct cpu* c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    800035c4:	0000f497          	auipc	s1,0xf
    800035c8:	cfc48493          	addi	s1,s1,-772 # 800122c0 <cpus>
    800035cc:	0000f717          	auipc	a4,0xf
    800035d0:	17470713          	addi	a4,a4,372 # 80012740 <pid_lock>
  {
    if (c->cpu_id == cpu_num)
    800035d4:	0884a783          	lw	a5,136(s1)
    800035d8:	00a78d63          	beq	a5,a0,800035f2 <set_cpu+0x40>
  for(c = cpus; c < &cpus[NCPU]; c++)
    800035dc:	09048493          	addi	s1,s1,144
    800035e0:	fee49ae3          	bne	s1,a4,800035d4 <set_cpu+0x22>
      }
      
      return 0;
    }
  }
  return -1;
    800035e4:	557d                	li	a0,-1
}
    800035e6:	60e2                	ld	ra,24(sp)
    800035e8:	6442                	ld	s0,16(sp)
    800035ea:	64a2                	ld	s1,8(sp)
    800035ec:	6902                	ld	s2,0(sp)
    800035ee:	6105                	addi	sp,sp,32
    800035f0:	8082                	ret
      printf("runnable");
    800035f2:	00006517          	auipc	a0,0x6
    800035f6:	cbe50513          	addi	a0,a0,-834 # 800092b0 <digits+0x270>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f8e080e7          	jalr	-114(ra) # 80000588 <printf>
      if (c->runnable_list_head == -1)
    80003602:	0804a703          	lw	a4,128(s1)
    80003606:	57fd                	li	a5,-1
    80003608:	02f70763          	beq	a4,a5,80003636 <set_cpu+0x84>
        add_proc_to_list(c->runnable_list_tail, myproc());
    8000360c:	0844a903          	lw	s2,132(s1)
    80003610:	ffffe097          	auipc	ra,0xffffe
    80003614:	5f0080e7          	jalr	1520(ra) # 80001c00 <myproc>
    80003618:	85aa                	mv	a1,a0
    8000361a:	854a                	mv	a0,s2
    8000361c:	ffffe097          	auipc	ra,0xffffe
    80003620:	22a080e7          	jalr	554(ra) # 80001846 <add_proc_to_list>
        c->runnable_list_tail = myproc()->proc_ind;
    80003624:	ffffe097          	auipc	ra,0xffffe
    80003628:	5dc080e7          	jalr	1500(ra) # 80001c00 <myproc>
    8000362c:	4d7c                	lw	a5,92(a0)
    8000362e:	08f4a223          	sw	a5,132(s1)
      return 0;
    80003632:	4501                	li	a0,0
    80003634:	bf4d                	j	800035e6 <set_cpu+0x34>
        printf("init runnable %d\n", proc->proc_ind);
    80003636:	0000f597          	auipc	a1,0xf
    8000363a:	1965a583          	lw	a1,406(a1) # 800127cc <proc+0x5c>
    8000363e:	00006517          	auipc	a0,0x6
    80003642:	c8250513          	addi	a0,a0,-894 # 800092c0 <digits+0x280>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	f42080e7          	jalr	-190(ra) # 80000588 <printf>
        c->runnable_list_tail = myproc()->proc_ind;
    8000364e:	ffffe097          	auipc	ra,0xffffe
    80003652:	5b2080e7          	jalr	1458(ra) # 80001c00 <myproc>
    80003656:	4d7c                	lw	a5,92(a0)
    80003658:	08f4a223          	sw	a5,132(s1)
        c->runnable_list_head = myproc()->proc_ind;
    8000365c:	ffffe097          	auipc	ra,0xffffe
    80003660:	5a4080e7          	jalr	1444(ra) # 80001c00 <myproc>
    80003664:	4d7c                	lw	a5,92(a0)
    80003666:	08f4a023          	sw	a5,128(s1)
      return 0;
    8000366a:	4501                	li	a0,0
    8000366c:	bfad                	j	800035e6 <set_cpu+0x34>
    return -1;
    8000366e:	557d                	li	a0,-1
}
    80003670:	8082                	ret

0000000080003672 <get_cpu>:


int
get_cpu()
{
    80003672:	1141                	addi	sp,sp,-16
    80003674:	e422                	sd	s0,8(sp)
    80003676:	0800                	addi	s0,sp,16
    80003678:	8512                	mv	a0,tp
  // TODO
  return cpuid();
}
    8000367a:	2501                	sext.w	a0,a0
    8000367c:	6422                	ld	s0,8(sp)
    8000367e:	0141                	addi	sp,sp,16
    80003680:	8082                	ret

0000000080003682 <pause_system>:


int
pause_system(int seconds)
{
    80003682:	711d                	addi	sp,sp,-96
    80003684:	ec86                	sd	ra,88(sp)
    80003686:	e8a2                	sd	s0,80(sp)
    80003688:	e4a6                	sd	s1,72(sp)
    8000368a:	e0ca                	sd	s2,64(sp)
    8000368c:	fc4e                	sd	s3,56(sp)
    8000368e:	f852                	sd	s4,48(sp)
    80003690:	f456                	sd	s5,40(sp)
    80003692:	f05a                	sd	s6,32(sp)
    80003694:	ec5e                	sd	s7,24(sp)
    80003696:	e862                	sd	s8,16(sp)
    80003698:	e466                	sd	s9,8(sp)
    8000369a:	1080                	addi	s0,sp,96
    8000369c:	84aa                	mv	s1,a0
  struct proc *p;
  struct proc *myProcess = myproc();
    8000369e:	ffffe097          	auipc	ra,0xffffe
    800036a2:	562080e7          	jalr	1378(ra) # 80001c00 <myproc>
    800036a6:	8b2a                	mv	s6,a0

  pause_flag = 1;
    800036a8:	4785                	li	a5,1
    800036aa:	00007717          	auipc	a4,0x7
    800036ae:	9af72323          	sw	a5,-1626(a4) # 8000a050 <pause_flag>

  wake_up_time = ticks + (seconds * 10);
    800036b2:	0024979b          	slliw	a5,s1,0x2
    800036b6:	9fa5                	addw	a5,a5,s1
    800036b8:	0017979b          	slliw	a5,a5,0x1
    800036bc:	00007717          	auipc	a4,0x7
    800036c0:	99872703          	lw	a4,-1640(a4) # 8000a054 <ticks>
    800036c4:	9fb9                	addw	a5,a5,a4
    800036c6:	00007717          	auipc	a4,0x7
    800036ca:	98f72323          	sw	a5,-1658(a4) # 8000a04c <wake_up_time>

  for(p = proc; p < &proc[NPROC]; p++)
    800036ce:	0000f497          	auipc	s1,0xf
    800036d2:	0a248493          	addi	s1,s1,162 # 80012770 <proc>
  {
    acquire(&p->lock);
    if(p->state == RUNNING)
    800036d6:	4991                	li	s3,4
    {
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800036d8:	00006a97          	auipc	s5,0x6
    800036dc:	cf0a8a93          	addi	s5,s5,-784 # 800093c8 <digits+0x388>
    800036e0:	00006b97          	auipc	s7,0x6
    800036e4:	cf0b8b93          	addi	s7,s7,-784 # 800093d0 <digits+0x390>
        if (p != myProcess) {
          p->paused = 1;
    800036e8:	4c85                	li	s9,1
          p->running_time += ticks - p->start_running_time;
    800036ea:	00007c17          	auipc	s8,0x7
    800036ee:	96ac0c13          	addi	s8,s8,-1686 # 8000a054 <ticks>
  for(p = proc; p < &proc[NPROC]; p++)
    800036f2:	00015917          	auipc	s2,0x15
    800036f6:	67e90913          	addi	s2,s2,1662 # 80018d70 <tickslock>
    800036fa:	a811                	j	8000370e <pause_system+0x8c>
          yield();
        }
      }
    }
    release(&p->lock);
    800036fc:	8526                	mv	a0,s1
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	59a080e7          	jalr	1434(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80003706:	19848493          	addi	s1,s1,408
    8000370a:	05248a63          	beq	s1,s2,8000375e <pause_system+0xdc>
    acquire(&p->lock);
    8000370e:	8526                	mv	a0,s1
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	4d4080e7          	jalr	1236(ra) # 80000be4 <acquire>
    if(p->state == RUNNING)
    80003718:	4c9c                	lw	a5,24(s1)
    8000371a:	ff3791e3          	bne	a5,s3,800036fc <pause_system+0x7a>
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    8000371e:	18848a13          	addi	s4,s1,392
    80003722:	85d6                	mv	a1,s5
    80003724:	8552                	mv	a0,s4
    80003726:	fffff097          	auipc	ra,0xfffff
    8000372a:	99a080e7          	jalr	-1638(ra) # 800020c0 <str_compare>
    8000372e:	d579                	beqz	a0,800036fc <pause_system+0x7a>
    80003730:	85de                	mv	a1,s7
    80003732:	8552                	mv	a0,s4
    80003734:	fffff097          	auipc	ra,0xfffff
    80003738:	98c080e7          	jalr	-1652(ra) # 800020c0 <str_compare>
    8000373c:	d161                	beqz	a0,800036fc <pause_system+0x7a>
        if (p != myProcess) {
    8000373e:	fa9b0fe3          	beq	s6,s1,800036fc <pause_system+0x7a>
          p->paused = 1;
    80003742:	0594a023          	sw	s9,64(s1)
          p->running_time += ticks - p->start_running_time;
    80003746:	40fc                	lw	a5,68(s1)
    80003748:	000c2703          	lw	a4,0(s8)
    8000374c:	9fb9                	addw	a5,a5,a4
    8000374e:	48b8                	lw	a4,80(s1)
    80003750:	9f99                	subw	a5,a5,a4
    80003752:	c0fc                	sw	a5,68(s1)
          yield();
    80003754:	fffff097          	auipc	ra,0xfffff
    80003758:	39c080e7          	jalr	924(ra) # 80002af0 <yield>
    8000375c:	b745                	j	800036fc <pause_system+0x7a>
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    8000375e:	188b0493          	addi	s1,s6,392 # ffffffff80000188 <end+0xfffffffefffd8188>
    80003762:	00006597          	auipc	a1,0x6
    80003766:	c6658593          	addi	a1,a1,-922 # 800093c8 <digits+0x388>
    8000376a:	8526                	mv	a0,s1
    8000376c:	fffff097          	auipc	ra,0xfffff
    80003770:	954080e7          	jalr	-1708(ra) # 800020c0 <str_compare>
    80003774:	ed19                	bnez	a0,80003792 <pause_system+0x110>
    myProcess->running_time += ticks - myProcess->start_running_time;
    release(&myProcess->lock);
    yield();
  }
  return 0;
}
    80003776:	4501                	li	a0,0
    80003778:	60e6                	ld	ra,88(sp)
    8000377a:	6446                	ld	s0,80(sp)
    8000377c:	64a6                	ld	s1,72(sp)
    8000377e:	6906                	ld	s2,64(sp)
    80003780:	79e2                	ld	s3,56(sp)
    80003782:	7a42                	ld	s4,48(sp)
    80003784:	7aa2                	ld	s5,40(sp)
    80003786:	7b02                	ld	s6,32(sp)
    80003788:	6be2                	ld	s7,24(sp)
    8000378a:	6c42                	ld	s8,16(sp)
    8000378c:	6ca2                	ld	s9,8(sp)
    8000378e:	6125                	addi	sp,sp,96
    80003790:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    80003792:	00006597          	auipc	a1,0x6
    80003796:	c3e58593          	addi	a1,a1,-962 # 800093d0 <digits+0x390>
    8000379a:	8526                	mv	a0,s1
    8000379c:	fffff097          	auipc	ra,0xfffff
    800037a0:	924080e7          	jalr	-1756(ra) # 800020c0 <str_compare>
    800037a4:	d969                	beqz	a0,80003776 <pause_system+0xf4>
    acquire(&myProcess->lock);
    800037a6:	855a                	mv	a0,s6
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	43c080e7          	jalr	1084(ra) # 80000be4 <acquire>
    myProcess->paused = 1;
    800037b0:	4785                	li	a5,1
    800037b2:	04fb2023          	sw	a5,64(s6)
    myProcess->running_time += ticks - myProcess->start_running_time;
    800037b6:	044b2783          	lw	a5,68(s6)
    800037ba:	00007717          	auipc	a4,0x7
    800037be:	89a72703          	lw	a4,-1894(a4) # 8000a054 <ticks>
    800037c2:	9fb9                	addw	a5,a5,a4
    800037c4:	050b2703          	lw	a4,80(s6)
    800037c8:	9f99                	subw	a5,a5,a4
    800037ca:	04fb2223          	sw	a5,68(s6)
    release(&myProcess->lock);
    800037ce:	855a                	mv	a0,s6
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	4c8080e7          	jalr	1224(ra) # 80000c98 <release>
    yield();
    800037d8:	fffff097          	auipc	ra,0xfffff
    800037dc:	318080e7          	jalr	792(ra) # 80002af0 <yield>
    800037e0:	bf59                	j	80003776 <pause_system+0xf4>

00000000800037e2 <kill_system>:
// depending on usr_dst.
// Returns 0 on success, -1 on error.

int
kill_system(void) 
{
    800037e2:	7139                	addi	sp,sp,-64
    800037e4:	fc06                	sd	ra,56(sp)
    800037e6:	f822                	sd	s0,48(sp)
    800037e8:	f426                	sd	s1,40(sp)
    800037ea:	f04a                	sd	s2,32(sp)
    800037ec:	ec4e                	sd	s3,24(sp)
    800037ee:	e852                	sd	s4,16(sp)
    800037f0:	e456                	sd	s5,8(sp)
    800037f2:	e05a                	sd	s6,0(sp)
    800037f4:	0080                	addi	s0,sp,64
  struct proc *p;
  struct proc *myProcess = myproc();
    800037f6:	ffffe097          	auipc	ra,0xffffe
    800037fa:	40a080e7          	jalr	1034(ra) # 80001c00 <myproc>
    800037fe:	8b2a                	mv	s6,a0

  for (p = proc; p < &proc[NPROC]; p++) {
    80003800:	0000f497          	auipc	s1,0xf
    80003804:	0f848493          	addi	s1,s1,248 # 800128f8 <proc+0x188>
    80003808:	00015a17          	auipc	s4,0x15
    8000380c:	6f0a0a13          	addi	s4,s4,1776 # 80018ef8 <bcache+0x170>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80003810:	00006997          	auipc	s3,0x6
    80003814:	bb898993          	addi	s3,s3,-1096 # 800093c8 <digits+0x388>
    80003818:	00006a97          	auipc	s5,0x6
    8000381c:	bb8a8a93          	addi	s5,s5,-1096 # 800093d0 <digits+0x390>
    80003820:	a029                	j	8000382a <kill_system+0x48>
  for (p = proc; p < &proc[NPROC]; p++) {
    80003822:	19848493          	addi	s1,s1,408
    80003826:	03448b63          	beq	s1,s4,8000385c <kill_system+0x7a>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    8000382a:	85ce                	mv	a1,s3
    8000382c:	8526                	mv	a0,s1
    8000382e:	fffff097          	auipc	ra,0xfffff
    80003832:	892080e7          	jalr	-1902(ra) # 800020c0 <str_compare>
    80003836:	d575                	beqz	a0,80003822 <kill_system+0x40>
    80003838:	85d6                	mv	a1,s5
    8000383a:	8526                	mv	a0,s1
    8000383c:	fffff097          	auipc	ra,0xfffff
    80003840:	884080e7          	jalr	-1916(ra) # 800020c0 <str_compare>
    80003844:	dd79                	beqz	a0,80003822 <kill_system+0x40>
      if (p != myProcess) {
    80003846:	e7848793          	addi	a5,s1,-392
    8000384a:	fcfb0ce3          	beq	s6,a5,80003822 <kill_system+0x40>
        kill(p->pid);      
    8000384e:	ea84a503          	lw	a0,-344(s1)
    80003852:	00000097          	auipc	ra,0x0
    80003856:	c38080e7          	jalr	-968(ra) # 8000348a <kill>
    8000385a:	b7e1                	j	80003822 <kill_system+0x40>
      }
    }
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    8000385c:	188b0493          	addi	s1,s6,392
    80003860:	00006597          	auipc	a1,0x6
    80003864:	b6858593          	addi	a1,a1,-1176 # 800093c8 <digits+0x388>
    80003868:	8526                	mv	a0,s1
    8000386a:	fffff097          	auipc	ra,0xfffff
    8000386e:	856080e7          	jalr	-1962(ra) # 800020c0 <str_compare>
    80003872:	ed01                	bnez	a0,8000388a <kill_system+0xa8>
    kill(myProcess->pid);
  }
  return 0;
}
    80003874:	4501                	li	a0,0
    80003876:	70e2                	ld	ra,56(sp)
    80003878:	7442                	ld	s0,48(sp)
    8000387a:	74a2                	ld	s1,40(sp)
    8000387c:	7902                	ld	s2,32(sp)
    8000387e:	69e2                	ld	s3,24(sp)
    80003880:	6a42                	ld	s4,16(sp)
    80003882:	6aa2                	ld	s5,8(sp)
    80003884:	6b02                	ld	s6,0(sp)
    80003886:	6121                	addi	sp,sp,64
    80003888:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    8000388a:	00006597          	auipc	a1,0x6
    8000388e:	b4658593          	addi	a1,a1,-1210 # 800093d0 <digits+0x390>
    80003892:	8526                	mv	a0,s1
    80003894:	fffff097          	auipc	ra,0xfffff
    80003898:	82c080e7          	jalr	-2004(ra) # 800020c0 <str_compare>
    8000389c:	dd61                	beqz	a0,80003874 <kill_system+0x92>
    kill(myProcess->pid);
    8000389e:	030b2503          	lw	a0,48(s6)
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	be8080e7          	jalr	-1048(ra) # 8000348a <kill>
    800038aa:	b7e9                	j	80003874 <kill_system+0x92>

00000000800038ac <either_copyout>:

int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800038ac:	7179                	addi	sp,sp,-48
    800038ae:	f406                	sd	ra,40(sp)
    800038b0:	f022                	sd	s0,32(sp)
    800038b2:	ec26                	sd	s1,24(sp)
    800038b4:	e84a                	sd	s2,16(sp)
    800038b6:	e44e                	sd	s3,8(sp)
    800038b8:	e052                	sd	s4,0(sp)
    800038ba:	1800                	addi	s0,sp,48
    800038bc:	84aa                	mv	s1,a0
    800038be:	892e                	mv	s2,a1
    800038c0:	89b2                	mv	s3,a2
    800038c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800038c4:	ffffe097          	auipc	ra,0xffffe
    800038c8:	33c080e7          	jalr	828(ra) # 80001c00 <myproc>
  if(user_dst){
    800038cc:	c08d                	beqz	s1,800038ee <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800038ce:	86d2                	mv	a3,s4
    800038d0:	864e                	mv	a2,s3
    800038d2:	85ca                	mv	a1,s2
    800038d4:	6148                	ld	a0,128(a0)
    800038d6:	ffffe097          	auipc	ra,0xffffe
    800038da:	da4080e7          	jalr	-604(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800038de:	70a2                	ld	ra,40(sp)
    800038e0:	7402                	ld	s0,32(sp)
    800038e2:	64e2                	ld	s1,24(sp)
    800038e4:	6942                	ld	s2,16(sp)
    800038e6:	69a2                	ld	s3,8(sp)
    800038e8:	6a02                	ld	s4,0(sp)
    800038ea:	6145                	addi	sp,sp,48
    800038ec:	8082                	ret
    memmove((char *)dst, src, len);
    800038ee:	000a061b          	sext.w	a2,s4
    800038f2:	85ce                	mv	a1,s3
    800038f4:	854a                	mv	a0,s2
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	44a080e7          	jalr	1098(ra) # 80000d40 <memmove>
    return 0;
    800038fe:	8526                	mv	a0,s1
    80003900:	bff9                	j	800038de <either_copyout+0x32>

0000000080003902 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80003902:	7179                	addi	sp,sp,-48
    80003904:	f406                	sd	ra,40(sp)
    80003906:	f022                	sd	s0,32(sp)
    80003908:	ec26                	sd	s1,24(sp)
    8000390a:	e84a                	sd	s2,16(sp)
    8000390c:	e44e                	sd	s3,8(sp)
    8000390e:	e052                	sd	s4,0(sp)
    80003910:	1800                	addi	s0,sp,48
    80003912:	892a                	mv	s2,a0
    80003914:	84ae                	mv	s1,a1
    80003916:	89b2                	mv	s3,a2
    80003918:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000391a:	ffffe097          	auipc	ra,0xffffe
    8000391e:	2e6080e7          	jalr	742(ra) # 80001c00 <myproc>
  if(user_src){
    80003922:	c08d                	beqz	s1,80003944 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80003924:	86d2                	mv	a3,s4
    80003926:	864e                	mv	a2,s3
    80003928:	85ca                	mv	a1,s2
    8000392a:	6148                	ld	a0,128(a0)
    8000392c:	ffffe097          	auipc	ra,0xffffe
    80003930:	dda080e7          	jalr	-550(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80003934:	70a2                	ld	ra,40(sp)
    80003936:	7402                	ld	s0,32(sp)
    80003938:	64e2                	ld	s1,24(sp)
    8000393a:	6942                	ld	s2,16(sp)
    8000393c:	69a2                	ld	s3,8(sp)
    8000393e:	6a02                	ld	s4,0(sp)
    80003940:	6145                	addi	sp,sp,48
    80003942:	8082                	ret
    memmove(dst, (char*)src, len);
    80003944:	000a061b          	sext.w	a2,s4
    80003948:	85ce                	mv	a1,s3
    8000394a:	854a                	mv	a0,s2
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	3f4080e7          	jalr	1012(ra) # 80000d40 <memmove>
    return 0;
    80003954:	8526                	mv	a0,s1
    80003956:	bff9                	j	80003934 <either_copyin+0x32>

0000000080003958 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80003958:	715d                	addi	sp,sp,-80
    8000395a:	e486                	sd	ra,72(sp)
    8000395c:	e0a2                	sd	s0,64(sp)
    8000395e:	fc26                	sd	s1,56(sp)
    80003960:	f84a                	sd	s2,48(sp)
    80003962:	f44e                	sd	s3,40(sp)
    80003964:	f052                	sd	s4,32(sp)
    80003966:	ec56                	sd	s5,24(sp)
    80003968:	e85a                	sd	s6,16(sp)
    8000396a:	e45e                	sd	s7,8(sp)
    8000396c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000396e:	00006517          	auipc	a0,0x6
    80003972:	aea50513          	addi	a0,a0,-1302 # 80009458 <digits+0x418>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	c12080e7          	jalr	-1006(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000397e:	0000f497          	auipc	s1,0xf
    80003982:	f7a48493          	addi	s1,s1,-134 # 800128f8 <proc+0x188>
    80003986:	00015917          	auipc	s2,0x15
    8000398a:	57290913          	addi	s2,s2,1394 # 80018ef8 <bcache+0x170>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000398e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003990:	00006997          	auipc	s3,0x6
    80003994:	af898993          	addi	s3,s3,-1288 # 80009488 <digits+0x448>
    printf("%d %s %s", p->pid, state, p->name);
    80003998:	00006a97          	auipc	s5,0x6
    8000399c:	af8a8a93          	addi	s5,s5,-1288 # 80009490 <digits+0x450>
    printf("\n");
    800039a0:	00006a17          	auipc	s4,0x6
    800039a4:	ab8a0a13          	addi	s4,s4,-1352 # 80009458 <digits+0x418>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800039a8:	00006b97          	auipc	s7,0x6
    800039ac:	b10b8b93          	addi	s7,s7,-1264 # 800094b8 <states.1839>
    800039b0:	a00d                	j	800039d2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800039b2:	ea86a583          	lw	a1,-344(a3)
    800039b6:	8556                	mv	a0,s5
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	bd0080e7          	jalr	-1072(ra) # 80000588 <printf>
    printf("\n");
    800039c0:	8552                	mv	a0,s4
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	bc6080e7          	jalr	-1082(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800039ca:	19848493          	addi	s1,s1,408
    800039ce:	03248163          	beq	s1,s2,800039f0 <procdump+0x98>
    if(p->state == UNUSED)
    800039d2:	86a6                	mv	a3,s1
    800039d4:	e904a783          	lw	a5,-368(s1)
    800039d8:	dbed                	beqz	a5,800039ca <procdump+0x72>
      state = "???";
    800039da:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800039dc:	fcfb6be3          	bltu	s6,a5,800039b2 <procdump+0x5a>
    800039e0:	1782                	slli	a5,a5,0x20
    800039e2:	9381                	srli	a5,a5,0x20
    800039e4:	078e                	slli	a5,a5,0x3
    800039e6:	97de                	add	a5,a5,s7
    800039e8:	6390                	ld	a2,0(a5)
    800039ea:	f661                	bnez	a2,800039b2 <procdump+0x5a>
      state = "???";
    800039ec:	864e                	mv	a2,s3
    800039ee:	b7d1                	j	800039b2 <procdump+0x5a>
  }
}
    800039f0:	60a6                	ld	ra,72(sp)
    800039f2:	6406                	ld	s0,64(sp)
    800039f4:	74e2                	ld	s1,56(sp)
    800039f6:	7942                	ld	s2,48(sp)
    800039f8:	79a2                	ld	s3,40(sp)
    800039fa:	7a02                	ld	s4,32(sp)
    800039fc:	6ae2                	ld	s5,24(sp)
    800039fe:	6b42                	ld	s6,16(sp)
    80003a00:	6ba2                	ld	s7,8(sp)
    80003a02:	6161                	addi	sp,sp,80
    80003a04:	8082                	ret

0000000080003a06 <swtch>:
    80003a06:	00153023          	sd	ra,0(a0)
    80003a0a:	00253423          	sd	sp,8(a0)
    80003a0e:	e900                	sd	s0,16(a0)
    80003a10:	ed04                	sd	s1,24(a0)
    80003a12:	03253023          	sd	s2,32(a0)
    80003a16:	03353423          	sd	s3,40(a0)
    80003a1a:	03453823          	sd	s4,48(a0)
    80003a1e:	03553c23          	sd	s5,56(a0)
    80003a22:	05653023          	sd	s6,64(a0)
    80003a26:	05753423          	sd	s7,72(a0)
    80003a2a:	05853823          	sd	s8,80(a0)
    80003a2e:	05953c23          	sd	s9,88(a0)
    80003a32:	07a53023          	sd	s10,96(a0)
    80003a36:	07b53423          	sd	s11,104(a0)
    80003a3a:	0005b083          	ld	ra,0(a1)
    80003a3e:	0085b103          	ld	sp,8(a1)
    80003a42:	6980                	ld	s0,16(a1)
    80003a44:	6d84                	ld	s1,24(a1)
    80003a46:	0205b903          	ld	s2,32(a1)
    80003a4a:	0285b983          	ld	s3,40(a1)
    80003a4e:	0305ba03          	ld	s4,48(a1)
    80003a52:	0385ba83          	ld	s5,56(a1)
    80003a56:	0405bb03          	ld	s6,64(a1)
    80003a5a:	0485bb83          	ld	s7,72(a1)
    80003a5e:	0505bc03          	ld	s8,80(a1)
    80003a62:	0585bc83          	ld	s9,88(a1)
    80003a66:	0605bd03          	ld	s10,96(a1)
    80003a6a:	0685bd83          	ld	s11,104(a1)
    80003a6e:	8082                	ret

0000000080003a70 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003a70:	1141                	addi	sp,sp,-16
    80003a72:	e406                	sd	ra,8(sp)
    80003a74:	e022                	sd	s0,0(sp)
    80003a76:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003a78:	00006597          	auipc	a1,0x6
    80003a7c:	a7058593          	addi	a1,a1,-1424 # 800094e8 <states.1839+0x30>
    80003a80:	00015517          	auipc	a0,0x15
    80003a84:	2f050513          	addi	a0,a0,752 # 80018d70 <tickslock>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	0cc080e7          	jalr	204(ra) # 80000b54 <initlock>
}
    80003a90:	60a2                	ld	ra,8(sp)
    80003a92:	6402                	ld	s0,0(sp)
    80003a94:	0141                	addi	sp,sp,16
    80003a96:	8082                	ret

0000000080003a98 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003a98:	1141                	addi	sp,sp,-16
    80003a9a:	e422                	sd	s0,8(sp)
    80003a9c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003a9e:	00003797          	auipc	a5,0x3
    80003aa2:	54278793          	addi	a5,a5,1346 # 80006fe0 <kernelvec>
    80003aa6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003aaa:	6422                	ld	s0,8(sp)
    80003aac:	0141                	addi	sp,sp,16
    80003aae:	8082                	ret

0000000080003ab0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003ab0:	1141                	addi	sp,sp,-16
    80003ab2:	e406                	sd	ra,8(sp)
    80003ab4:	e022                	sd	s0,0(sp)
    80003ab6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003ab8:	ffffe097          	auipc	ra,0xffffe
    80003abc:	148080e7          	jalr	328(ra) # 80001c00 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003ac0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003ac4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003ac6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003aca:	00004617          	auipc	a2,0x4
    80003ace:	53660613          	addi	a2,a2,1334 # 80008000 <_trampoline>
    80003ad2:	00004697          	auipc	a3,0x4
    80003ad6:	52e68693          	addi	a3,a3,1326 # 80008000 <_trampoline>
    80003ada:	8e91                	sub	a3,a3,a2
    80003adc:	040007b7          	lui	a5,0x4000
    80003ae0:	17fd                	addi	a5,a5,-1
    80003ae2:	07b2                	slli	a5,a5,0xc
    80003ae4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003ae6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003aea:	6558                	ld	a4,136(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003aec:	180026f3          	csrr	a3,satp
    80003af0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003af2:	6558                	ld	a4,136(a0)
    80003af4:	7934                	ld	a3,112(a0)
    80003af6:	6585                	lui	a1,0x1
    80003af8:	96ae                	add	a3,a3,a1
    80003afa:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003afc:	6558                	ld	a4,136(a0)
    80003afe:	00000697          	auipc	a3,0x0
    80003b02:	13868693          	addi	a3,a3,312 # 80003c36 <usertrap>
    80003b06:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003b08:	6558                	ld	a4,136(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003b0a:	8692                	mv	a3,tp
    80003b0c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003b0e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003b12:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003b16:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003b1a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003b1e:	6558                	ld	a4,136(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003b20:	6f18                	ld	a4,24(a4)
    80003b22:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003b26:	614c                	ld	a1,128(a0)
    80003b28:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003b2a:	00004717          	auipc	a4,0x4
    80003b2e:	56670713          	addi	a4,a4,1382 # 80008090 <userret>
    80003b32:	8f11                	sub	a4,a4,a2
    80003b34:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003b36:	577d                	li	a4,-1
    80003b38:	177e                	slli	a4,a4,0x3f
    80003b3a:	8dd9                	or	a1,a1,a4
    80003b3c:	02000537          	lui	a0,0x2000
    80003b40:	157d                	addi	a0,a0,-1
    80003b42:	0536                	slli	a0,a0,0xd
    80003b44:	9782                	jalr	a5
}
    80003b46:	60a2                	ld	ra,8(sp)
    80003b48:	6402                	ld	s0,0(sp)
    80003b4a:	0141                	addi	sp,sp,16
    80003b4c:	8082                	ret

0000000080003b4e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003b4e:	1101                	addi	sp,sp,-32
    80003b50:	ec06                	sd	ra,24(sp)
    80003b52:	e822                	sd	s0,16(sp)
    80003b54:	e426                	sd	s1,8(sp)
    80003b56:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003b58:	00015497          	auipc	s1,0x15
    80003b5c:	21848493          	addi	s1,s1,536 # 80018d70 <tickslock>
    80003b60:	8526                	mv	a0,s1
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	082080e7          	jalr	130(ra) # 80000be4 <acquire>
  ticks++;
    80003b6a:	00006517          	auipc	a0,0x6
    80003b6e:	4ea50513          	addi	a0,a0,1258 # 8000a054 <ticks>
    80003b72:	411c                	lw	a5,0(a0)
    80003b74:	2785                	addiw	a5,a5,1
    80003b76:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003b78:	fffff097          	auipc	ra,0xfffff
    80003b7c:	40e080e7          	jalr	1038(ra) # 80002f86 <wakeup>
  release(&tickslock);
    80003b80:	8526                	mv	a0,s1
    80003b82:	ffffd097          	auipc	ra,0xffffd
    80003b86:	116080e7          	jalr	278(ra) # 80000c98 <release>
}
    80003b8a:	60e2                	ld	ra,24(sp)
    80003b8c:	6442                	ld	s0,16(sp)
    80003b8e:	64a2                	ld	s1,8(sp)
    80003b90:	6105                	addi	sp,sp,32
    80003b92:	8082                	ret

0000000080003b94 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003b94:	1101                	addi	sp,sp,-32
    80003b96:	ec06                	sd	ra,24(sp)
    80003b98:	e822                	sd	s0,16(sp)
    80003b9a:	e426                	sd	s1,8(sp)
    80003b9c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003b9e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003ba2:	00074d63          	bltz	a4,80003bbc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003ba6:	57fd                	li	a5,-1
    80003ba8:	17fe                	slli	a5,a5,0x3f
    80003baa:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003bac:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003bae:	06f70363          	beq	a4,a5,80003c14 <devintr+0x80>
  }
}
    80003bb2:	60e2                	ld	ra,24(sp)
    80003bb4:	6442                	ld	s0,16(sp)
    80003bb6:	64a2                	ld	s1,8(sp)
    80003bb8:	6105                	addi	sp,sp,32
    80003bba:	8082                	ret
     (scause & 0xff) == 9){
    80003bbc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003bc0:	46a5                	li	a3,9
    80003bc2:	fed792e3          	bne	a5,a3,80003ba6 <devintr+0x12>
    int irq = plic_claim();
    80003bc6:	00003097          	auipc	ra,0x3
    80003bca:	522080e7          	jalr	1314(ra) # 800070e8 <plic_claim>
    80003bce:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003bd0:	47a9                	li	a5,10
    80003bd2:	02f50763          	beq	a0,a5,80003c00 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003bd6:	4785                	li	a5,1
    80003bd8:	02f50963          	beq	a0,a5,80003c0a <devintr+0x76>
    return 1;
    80003bdc:	4505                	li	a0,1
    } else if(irq){
    80003bde:	d8f1                	beqz	s1,80003bb2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003be0:	85a6                	mv	a1,s1
    80003be2:	00006517          	auipc	a0,0x6
    80003be6:	90e50513          	addi	a0,a0,-1778 # 800094f0 <states.1839+0x38>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	99e080e7          	jalr	-1634(ra) # 80000588 <printf>
      plic_complete(irq);
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	00003097          	auipc	ra,0x3
    80003bf8:	518080e7          	jalr	1304(ra) # 8000710c <plic_complete>
    return 1;
    80003bfc:	4505                	li	a0,1
    80003bfe:	bf55                	j	80003bb2 <devintr+0x1e>
      uartintr();
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	da8080e7          	jalr	-600(ra) # 800009a8 <uartintr>
    80003c08:	b7ed                	j	80003bf2 <devintr+0x5e>
      virtio_disk_intr();
    80003c0a:	00004097          	auipc	ra,0x4
    80003c0e:	9e2080e7          	jalr	-1566(ra) # 800075ec <virtio_disk_intr>
    80003c12:	b7c5                	j	80003bf2 <devintr+0x5e>
    if(cpuid() == 0){
    80003c14:	ffffe097          	auipc	ra,0xffffe
    80003c18:	fb0080e7          	jalr	-80(ra) # 80001bc4 <cpuid>
    80003c1c:	c901                	beqz	a0,80003c2c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003c1e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003c22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003c24:	14479073          	csrw	sip,a5
    return 2;
    80003c28:	4509                	li	a0,2
    80003c2a:	b761                	j	80003bb2 <devintr+0x1e>
      clockintr();
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	f22080e7          	jalr	-222(ra) # 80003b4e <clockintr>
    80003c34:	b7ed                	j	80003c1e <devintr+0x8a>

0000000080003c36 <usertrap>:
{
    80003c36:	1101                	addi	sp,sp,-32
    80003c38:	ec06                	sd	ra,24(sp)
    80003c3a:	e822                	sd	s0,16(sp)
    80003c3c:	e426                	sd	s1,8(sp)
    80003c3e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003c40:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003c44:	1007f793          	andi	a5,a5,256
    80003c48:	e3a5                	bnez	a5,80003ca8 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003c4a:	00003797          	auipc	a5,0x3
    80003c4e:	39678793          	addi	a5,a5,918 # 80006fe0 <kernelvec>
    80003c52:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003c56:	ffffe097          	auipc	ra,0xffffe
    80003c5a:	faa080e7          	jalr	-86(ra) # 80001c00 <myproc>
    80003c5e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003c60:	655c                	ld	a5,136(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003c62:	14102773          	csrr	a4,sepc
    80003c66:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003c68:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003c6c:	47a1                	li	a5,8
    80003c6e:	04f71b63          	bne	a4,a5,80003cc4 <usertrap+0x8e>
    if(p->killed)
    80003c72:	551c                	lw	a5,40(a0)
    80003c74:	e3b1                	bnez	a5,80003cb8 <usertrap+0x82>
    p->trapframe->epc += 4;
    80003c76:	64d8                	ld	a4,136(s1)
    80003c78:	6f1c                	ld	a5,24(a4)
    80003c7a:	0791                	addi	a5,a5,4
    80003c7c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003c82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003c86:	10079073          	csrw	sstatus,a5
    syscall();
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	2f0080e7          	jalr	752(ra) # 80003f7a <syscall>
  if(p->killed)
    80003c92:	549c                	lw	a5,40(s1)
    80003c94:	e7b5                	bnez	a5,80003d00 <usertrap+0xca>
  usertrapret();
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	e1a080e7          	jalr	-486(ra) # 80003ab0 <usertrapret>
}
    80003c9e:	60e2                	ld	ra,24(sp)
    80003ca0:	6442                	ld	s0,16(sp)
    80003ca2:	64a2                	ld	s1,8(sp)
    80003ca4:	6105                	addi	sp,sp,32
    80003ca6:	8082                	ret
    panic("usertrap: not from user mode");
    80003ca8:	00006517          	auipc	a0,0x6
    80003cac:	86850513          	addi	a0,a0,-1944 # 80009510 <states.1839+0x58>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	88e080e7          	jalr	-1906(ra) # 8000053e <panic>
      exit(-1);
    80003cb8:	557d                	li	a0,-1
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	4cc080e7          	jalr	1228(ra) # 80003186 <exit>
    80003cc2:	bf55                	j	80003c76 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	ed0080e7          	jalr	-304(ra) # 80003b94 <devintr>
    80003ccc:	f179                	bnez	a0,80003c92 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003cce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003cd2:	5890                	lw	a2,48(s1)
    80003cd4:	00006517          	auipc	a0,0x6
    80003cd8:	85c50513          	addi	a0,a0,-1956 # 80009530 <states.1839+0x78>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	8ac080e7          	jalr	-1876(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003ce4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003ce8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003cec:	00006517          	auipc	a0,0x6
    80003cf0:	87450513          	addi	a0,a0,-1932 # 80009560 <states.1839+0xa8>
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	894080e7          	jalr	-1900(ra) # 80000588 <printf>
    p->killed = 1;
    80003cfc:	4785                	li	a5,1
    80003cfe:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003d00:	557d                	li	a0,-1
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	484080e7          	jalr	1156(ra) # 80003186 <exit>
    80003d0a:	b771                	j	80003c96 <usertrap+0x60>

0000000080003d0c <kerneltrap>:
{
    80003d0c:	7179                	addi	sp,sp,-48
    80003d0e:	f406                	sd	ra,40(sp)
    80003d10:	f022                	sd	s0,32(sp)
    80003d12:	ec26                	sd	s1,24(sp)
    80003d14:	e84a                	sd	s2,16(sp)
    80003d16:	e44e                	sd	s3,8(sp)
    80003d18:	e052                	sd	s4,0(sp)
    80003d1a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003d1c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003d20:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003d24:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0){
    80003d28:	1004f793          	andi	a5,s1,256
    80003d2c:	cb8d                	beqz	a5,80003d5e <kerneltrap+0x52>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003d2e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003d32:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003d34:	ef8d                	bnez	a5,80003d6e <kerneltrap+0x62>
  if((which_dev = devintr()) == 0){
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	e5e080e7          	jalr	-418(ra) # 80003b94 <devintr>
    80003d3e:	c121                	beqz	a0,80003d7e <kerneltrap+0x72>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003d40:	4789                	li	a5,2
    80003d42:	06f50b63          	beq	a0,a5,80003db8 <kerneltrap+0xac>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003d46:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003d4a:	10049073          	csrw	sstatus,s1
}
    80003d4e:	70a2                	ld	ra,40(sp)
    80003d50:	7402                	ld	s0,32(sp)
    80003d52:	64e2                	ld	s1,24(sp)
    80003d54:	6942                	ld	s2,16(sp)
    80003d56:	69a2                	ld	s3,8(sp)
    80003d58:	6a02                	ld	s4,0(sp)
    80003d5a:	6145                	addi	sp,sp,48
    80003d5c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003d5e:	00006517          	auipc	a0,0x6
    80003d62:	82250513          	addi	a0,a0,-2014 # 80009580 <states.1839+0xc8>
    80003d66:	ffffc097          	auipc	ra,0xffffc
    80003d6a:	7d8080e7          	jalr	2008(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003d6e:	00006517          	auipc	a0,0x6
    80003d72:	83a50513          	addi	a0,a0,-1990 # 800095a8 <states.1839+0xf0>
    80003d76:	ffffc097          	auipc	ra,0xffffc
    80003d7a:	7c8080e7          	jalr	1992(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003d7e:	85ce                	mv	a1,s3
    80003d80:	00006517          	auipc	a0,0x6
    80003d84:	84850513          	addi	a0,a0,-1976 # 800095c8 <states.1839+0x110>
    80003d88:	ffffd097          	auipc	ra,0xffffd
    80003d8c:	800080e7          	jalr	-2048(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003d90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003d94:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003d98:	00006517          	auipc	a0,0x6
    80003d9c:	84050513          	addi	a0,a0,-1984 # 800095d8 <states.1839+0x120>
    80003da0:	ffffc097          	auipc	ra,0xffffc
    80003da4:	7e8080e7          	jalr	2024(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003da8:	00006517          	auipc	a0,0x6
    80003dac:	84850513          	addi	a0,a0,-1976 # 800095f0 <states.1839+0x138>
    80003db0:	ffffc097          	auipc	ra,0xffffc
    80003db4:	78e080e7          	jalr	1934(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003db8:	ffffe097          	auipc	ra,0xffffe
    80003dbc:	e48080e7          	jalr	-440(ra) # 80001c00 <myproc>
    80003dc0:	d159                	beqz	a0,80003d46 <kerneltrap+0x3a>
    80003dc2:	ffffe097          	auipc	ra,0xffffe
    80003dc6:	e3e080e7          	jalr	-450(ra) # 80001c00 <myproc>
    80003dca:	4d18                	lw	a4,24(a0)
    80003dcc:	4791                	li	a5,4
    80003dce:	f6f71ce3          	bne	a4,a5,80003d46 <kerneltrap+0x3a>
    myproc()->running_time += ticks - myproc()->start_running_time;
    80003dd2:	00006a17          	auipc	s4,0x6
    80003dd6:	282a2a03          	lw	s4,642(s4) # 8000a054 <ticks>
    80003dda:	ffffe097          	auipc	ra,0xffffe
    80003dde:	e26080e7          	jalr	-474(ra) # 80001c00 <myproc>
    80003de2:	05052983          	lw	s3,80(a0)
    80003de6:	ffffe097          	auipc	ra,0xffffe
    80003dea:	e1a080e7          	jalr	-486(ra) # 80001c00 <myproc>
    80003dee:	417c                	lw	a5,68(a0)
    80003df0:	014787bb          	addw	a5,a5,s4
    80003df4:	413787bb          	subw	a5,a5,s3
    80003df8:	c17c                	sw	a5,68(a0)
    yield();
    80003dfa:	fffff097          	auipc	ra,0xfffff
    80003dfe:	cf6080e7          	jalr	-778(ra) # 80002af0 <yield>
    80003e02:	b791                	j	80003d46 <kerneltrap+0x3a>

0000000080003e04 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003e04:	1101                	addi	sp,sp,-32
    80003e06:	ec06                	sd	ra,24(sp)
    80003e08:	e822                	sd	s0,16(sp)
    80003e0a:	e426                	sd	s1,8(sp)
    80003e0c:	1000                	addi	s0,sp,32
    80003e0e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003e10:	ffffe097          	auipc	ra,0xffffe
    80003e14:	df0080e7          	jalr	-528(ra) # 80001c00 <myproc>
  switch (n) {
    80003e18:	4795                	li	a5,5
    80003e1a:	0497e163          	bltu	a5,s1,80003e5c <argraw+0x58>
    80003e1e:	048a                	slli	s1,s1,0x2
    80003e20:	00006717          	auipc	a4,0x6
    80003e24:	80870713          	addi	a4,a4,-2040 # 80009628 <states.1839+0x170>
    80003e28:	94ba                	add	s1,s1,a4
    80003e2a:	409c                	lw	a5,0(s1)
    80003e2c:	97ba                	add	a5,a5,a4
    80003e2e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003e30:	655c                	ld	a5,136(a0)
    80003e32:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003e34:	60e2                	ld	ra,24(sp)
    80003e36:	6442                	ld	s0,16(sp)
    80003e38:	64a2                	ld	s1,8(sp)
    80003e3a:	6105                	addi	sp,sp,32
    80003e3c:	8082                	ret
    return p->trapframe->a1;
    80003e3e:	655c                	ld	a5,136(a0)
    80003e40:	7fa8                	ld	a0,120(a5)
    80003e42:	bfcd                	j	80003e34 <argraw+0x30>
    return p->trapframe->a2;
    80003e44:	655c                	ld	a5,136(a0)
    80003e46:	63c8                	ld	a0,128(a5)
    80003e48:	b7f5                	j	80003e34 <argraw+0x30>
    return p->trapframe->a3;
    80003e4a:	655c                	ld	a5,136(a0)
    80003e4c:	67c8                	ld	a0,136(a5)
    80003e4e:	b7dd                	j	80003e34 <argraw+0x30>
    return p->trapframe->a4;
    80003e50:	655c                	ld	a5,136(a0)
    80003e52:	6bc8                	ld	a0,144(a5)
    80003e54:	b7c5                	j	80003e34 <argraw+0x30>
    return p->trapframe->a5;
    80003e56:	655c                	ld	a5,136(a0)
    80003e58:	6fc8                	ld	a0,152(a5)
    80003e5a:	bfe9                	j	80003e34 <argraw+0x30>
  panic("argraw");
    80003e5c:	00005517          	auipc	a0,0x5
    80003e60:	7a450513          	addi	a0,a0,1956 # 80009600 <states.1839+0x148>
    80003e64:	ffffc097          	auipc	ra,0xffffc
    80003e68:	6da080e7          	jalr	1754(ra) # 8000053e <panic>

0000000080003e6c <fetchaddr>:
{
    80003e6c:	1101                	addi	sp,sp,-32
    80003e6e:	ec06                	sd	ra,24(sp)
    80003e70:	e822                	sd	s0,16(sp)
    80003e72:	e426                	sd	s1,8(sp)
    80003e74:	e04a                	sd	s2,0(sp)
    80003e76:	1000                	addi	s0,sp,32
    80003e78:	84aa                	mv	s1,a0
    80003e7a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003e7c:	ffffe097          	auipc	ra,0xffffe
    80003e80:	d84080e7          	jalr	-636(ra) # 80001c00 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003e84:	7d3c                	ld	a5,120(a0)
    80003e86:	02f4f863          	bgeu	s1,a5,80003eb6 <fetchaddr+0x4a>
    80003e8a:	00848713          	addi	a4,s1,8
    80003e8e:	02e7e663          	bltu	a5,a4,80003eba <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003e92:	46a1                	li	a3,8
    80003e94:	8626                	mv	a2,s1
    80003e96:	85ca                	mv	a1,s2
    80003e98:	6148                	ld	a0,128(a0)
    80003e9a:	ffffe097          	auipc	ra,0xffffe
    80003e9e:	86c080e7          	jalr	-1940(ra) # 80001706 <copyin>
    80003ea2:	00a03533          	snez	a0,a0
    80003ea6:	40a00533          	neg	a0,a0
}
    80003eaa:	60e2                	ld	ra,24(sp)
    80003eac:	6442                	ld	s0,16(sp)
    80003eae:	64a2                	ld	s1,8(sp)
    80003eb0:	6902                	ld	s2,0(sp)
    80003eb2:	6105                	addi	sp,sp,32
    80003eb4:	8082                	ret
    return -1;
    80003eb6:	557d                	li	a0,-1
    80003eb8:	bfcd                	j	80003eaa <fetchaddr+0x3e>
    80003eba:	557d                	li	a0,-1
    80003ebc:	b7fd                	j	80003eaa <fetchaddr+0x3e>

0000000080003ebe <fetchstr>:
{
    80003ebe:	7179                	addi	sp,sp,-48
    80003ec0:	f406                	sd	ra,40(sp)
    80003ec2:	f022                	sd	s0,32(sp)
    80003ec4:	ec26                	sd	s1,24(sp)
    80003ec6:	e84a                	sd	s2,16(sp)
    80003ec8:	e44e                	sd	s3,8(sp)
    80003eca:	1800                	addi	s0,sp,48
    80003ecc:	892a                	mv	s2,a0
    80003ece:	84ae                	mv	s1,a1
    80003ed0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003ed2:	ffffe097          	auipc	ra,0xffffe
    80003ed6:	d2e080e7          	jalr	-722(ra) # 80001c00 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003eda:	86ce                	mv	a3,s3
    80003edc:	864a                	mv	a2,s2
    80003ede:	85a6                	mv	a1,s1
    80003ee0:	6148                	ld	a0,128(a0)
    80003ee2:	ffffe097          	auipc	ra,0xffffe
    80003ee6:	8b0080e7          	jalr	-1872(ra) # 80001792 <copyinstr>
  if(err < 0)
    80003eea:	00054763          	bltz	a0,80003ef8 <fetchstr+0x3a>
  return strlen(buf);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	ffffd097          	auipc	ra,0xffffd
    80003ef4:	f74080e7          	jalr	-140(ra) # 80000e64 <strlen>
}
    80003ef8:	70a2                	ld	ra,40(sp)
    80003efa:	7402                	ld	s0,32(sp)
    80003efc:	64e2                	ld	s1,24(sp)
    80003efe:	6942                	ld	s2,16(sp)
    80003f00:	69a2                	ld	s3,8(sp)
    80003f02:	6145                	addi	sp,sp,48
    80003f04:	8082                	ret

0000000080003f06 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003f06:	1101                	addi	sp,sp,-32
    80003f08:	ec06                	sd	ra,24(sp)
    80003f0a:	e822                	sd	s0,16(sp)
    80003f0c:	e426                	sd	s1,8(sp)
    80003f0e:	1000                	addi	s0,sp,32
    80003f10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	ef2080e7          	jalr	-270(ra) # 80003e04 <argraw>
    80003f1a:	c088                	sw	a0,0(s1)
  return 0;
}
    80003f1c:	4501                	li	a0,0
    80003f1e:	60e2                	ld	ra,24(sp)
    80003f20:	6442                	ld	s0,16(sp)
    80003f22:	64a2                	ld	s1,8(sp)
    80003f24:	6105                	addi	sp,sp,32
    80003f26:	8082                	ret

0000000080003f28 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003f28:	1101                	addi	sp,sp,-32
    80003f2a:	ec06                	sd	ra,24(sp)
    80003f2c:	e822                	sd	s0,16(sp)
    80003f2e:	e426                	sd	s1,8(sp)
    80003f30:	1000                	addi	s0,sp,32
    80003f32:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	ed0080e7          	jalr	-304(ra) # 80003e04 <argraw>
    80003f3c:	e088                	sd	a0,0(s1)
  return 0;
}
    80003f3e:	4501                	li	a0,0
    80003f40:	60e2                	ld	ra,24(sp)
    80003f42:	6442                	ld	s0,16(sp)
    80003f44:	64a2                	ld	s1,8(sp)
    80003f46:	6105                	addi	sp,sp,32
    80003f48:	8082                	ret

0000000080003f4a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003f4a:	1101                	addi	sp,sp,-32
    80003f4c:	ec06                	sd	ra,24(sp)
    80003f4e:	e822                	sd	s0,16(sp)
    80003f50:	e426                	sd	s1,8(sp)
    80003f52:	e04a                	sd	s2,0(sp)
    80003f54:	1000                	addi	s0,sp,32
    80003f56:	84ae                	mv	s1,a1
    80003f58:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	eaa080e7          	jalr	-342(ra) # 80003e04 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003f62:	864a                	mv	a2,s2
    80003f64:	85a6                	mv	a1,s1
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	f58080e7          	jalr	-168(ra) # 80003ebe <fetchstr>
}
    80003f6e:	60e2                	ld	ra,24(sp)
    80003f70:	6442                	ld	s0,16(sp)
    80003f72:	64a2                	ld	s1,8(sp)
    80003f74:	6902                	ld	s2,0(sp)
    80003f76:	6105                	addi	sp,sp,32
    80003f78:	8082                	ret

0000000080003f7a <syscall>:
[SYS_set_cpu]       sys_set_cpu,
};

void
syscall(void)
{
    80003f7a:	1101                	addi	sp,sp,-32
    80003f7c:	ec06                	sd	ra,24(sp)
    80003f7e:	e822                	sd	s0,16(sp)
    80003f80:	e426                	sd	s1,8(sp)
    80003f82:	e04a                	sd	s2,0(sp)
    80003f84:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003f86:	ffffe097          	auipc	ra,0xffffe
    80003f8a:	c7a080e7          	jalr	-902(ra) # 80001c00 <myproc>
    80003f8e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003f90:	08853903          	ld	s2,136(a0)
    80003f94:	0a893783          	ld	a5,168(s2)
    80003f98:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003f9c:	37fd                	addiw	a5,a5,-1
    80003f9e:	4765                	li	a4,25
    80003fa0:	00f76f63          	bltu	a4,a5,80003fbe <syscall+0x44>
    80003fa4:	00369713          	slli	a4,a3,0x3
    80003fa8:	00005797          	auipc	a5,0x5
    80003fac:	69878793          	addi	a5,a5,1688 # 80009640 <syscalls>
    80003fb0:	97ba                	add	a5,a5,a4
    80003fb2:	639c                	ld	a5,0(a5)
    80003fb4:	c789                	beqz	a5,80003fbe <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003fb6:	9782                	jalr	a5
    80003fb8:	06a93823          	sd	a0,112(s2)
    80003fbc:	a839                	j	80003fda <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003fbe:	18848613          	addi	a2,s1,392
    80003fc2:	588c                	lw	a1,48(s1)
    80003fc4:	00005517          	auipc	a0,0x5
    80003fc8:	64450513          	addi	a0,a0,1604 # 80009608 <states.1839+0x150>
    80003fcc:	ffffc097          	auipc	ra,0xffffc
    80003fd0:	5bc080e7          	jalr	1468(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003fd4:	64dc                	ld	a5,136(s1)
    80003fd6:	577d                	li	a4,-1
    80003fd8:	fbb8                	sd	a4,112(a5)
  }
}
    80003fda:	60e2                	ld	ra,24(sp)
    80003fdc:	6442                	ld	s0,16(sp)
    80003fde:	64a2                	ld	s1,8(sp)
    80003fe0:	6902                	ld	s2,0(sp)
    80003fe2:	6105                	addi	sp,sp,32
    80003fe4:	8082                	ret

0000000080003fe6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003fe6:	1101                	addi	sp,sp,-32
    80003fe8:	ec06                	sd	ra,24(sp)
    80003fea:	e822                	sd	s0,16(sp)
    80003fec:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003fee:	fec40593          	addi	a1,s0,-20
    80003ff2:	4501                	li	a0,0
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	f12080e7          	jalr	-238(ra) # 80003f06 <argint>
    return -1;
    80003ffc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003ffe:	00054963          	bltz	a0,80004010 <sys_exit+0x2a>
  exit(n);
    80004002:	fec42503          	lw	a0,-20(s0)
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	180080e7          	jalr	384(ra) # 80003186 <exit>
  return 0;  // not reached
    8000400e:	4781                	li	a5,0
}
    80004010:	853e                	mv	a0,a5
    80004012:	60e2                	ld	ra,24(sp)
    80004014:	6442                	ld	s0,16(sp)
    80004016:	6105                	addi	sp,sp,32
    80004018:	8082                	ret

000000008000401a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000401a:	1141                	addi	sp,sp,-16
    8000401c:	e406                	sd	ra,8(sp)
    8000401e:	e022                	sd	s0,0(sp)
    80004020:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80004022:	ffffe097          	auipc	ra,0xffffe
    80004026:	bde080e7          	jalr	-1058(ra) # 80001c00 <myproc>
}
    8000402a:	5908                	lw	a0,48(a0)
    8000402c:	60a2                	ld	ra,8(sp)
    8000402e:	6402                	ld	s0,0(sp)
    80004030:	0141                	addi	sp,sp,16
    80004032:	8082                	ret

0000000080004034 <sys_fork>:

uint64
sys_fork(void)
{
    80004034:	1141                	addi	sp,sp,-16
    80004036:	e406                	sd	ra,8(sp)
    80004038:	e022                	sd	s0,0(sp)
    8000403a:	0800                	addi	s0,sp,16
  return fork();
    8000403c:	ffffe097          	auipc	ra,0xffffe
    80004040:	296080e7          	jalr	662(ra) # 800022d2 <fork>
}
    80004044:	60a2                	ld	ra,8(sp)
    80004046:	6402                	ld	s0,0(sp)
    80004048:	0141                	addi	sp,sp,16
    8000404a:	8082                	ret

000000008000404c <sys_wait>:

uint64
sys_wait(void)
{
    8000404c:	1101                	addi	sp,sp,-32
    8000404e:	ec06                	sd	ra,24(sp)
    80004050:	e822                	sd	s0,16(sp)
    80004052:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80004054:	fe840593          	addi	a1,s0,-24
    80004058:	4501                	li	a0,0
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	ece080e7          	jalr	-306(ra) # 80003f28 <argaddr>
    80004062:	87aa                	mv	a5,a0
    return -1;
    80004064:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80004066:	0007c863          	bltz	a5,80004076 <sys_wait+0x2a>
  return wait(p);
    8000406a:	fe843503          	ld	a0,-24(s0)
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	d8e080e7          	jalr	-626(ra) # 80002dfc <wait>
}
    80004076:	60e2                	ld	ra,24(sp)
    80004078:	6442                	ld	s0,16(sp)
    8000407a:	6105                	addi	sp,sp,32
    8000407c:	8082                	ret

000000008000407e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000407e:	7179                	addi	sp,sp,-48
    80004080:	f406                	sd	ra,40(sp)
    80004082:	f022                	sd	s0,32(sp)
    80004084:	ec26                	sd	s1,24(sp)
    80004086:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80004088:	fdc40593          	addi	a1,s0,-36
    8000408c:	4501                	li	a0,0
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	e78080e7          	jalr	-392(ra) # 80003f06 <argint>
    80004096:	87aa                	mv	a5,a0
    return -1;
    80004098:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000409a:	0207c063          	bltz	a5,800040ba <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000409e:	ffffe097          	auipc	ra,0xffffe
    800040a2:	b62080e7          	jalr	-1182(ra) # 80001c00 <myproc>
    800040a6:	5d24                	lw	s1,120(a0)
  if(growproc(n) < 0)
    800040a8:	fdc42503          	lw	a0,-36(s0)
    800040ac:	ffffe097          	auipc	ra,0xffffe
    800040b0:	1b2080e7          	jalr	434(ra) # 8000225e <growproc>
    800040b4:	00054863          	bltz	a0,800040c4 <sys_sbrk+0x46>
    return -1;
  return addr;
    800040b8:	8526                	mv	a0,s1
}
    800040ba:	70a2                	ld	ra,40(sp)
    800040bc:	7402                	ld	s0,32(sp)
    800040be:	64e2                	ld	s1,24(sp)
    800040c0:	6145                	addi	sp,sp,48
    800040c2:	8082                	ret
    return -1;
    800040c4:	557d                	li	a0,-1
    800040c6:	bfd5                	j	800040ba <sys_sbrk+0x3c>

00000000800040c8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800040c8:	7139                	addi	sp,sp,-64
    800040ca:	fc06                	sd	ra,56(sp)
    800040cc:	f822                	sd	s0,48(sp)
    800040ce:	f426                	sd	s1,40(sp)
    800040d0:	f04a                	sd	s2,32(sp)
    800040d2:	ec4e                	sd	s3,24(sp)
    800040d4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800040d6:	fcc40593          	addi	a1,s0,-52
    800040da:	4501                	li	a0,0
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	e2a080e7          	jalr	-470(ra) # 80003f06 <argint>
    return -1;
    800040e4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800040e6:	06054563          	bltz	a0,80004150 <sys_sleep+0x88>
  acquire(&tickslock);
    800040ea:	00015517          	auipc	a0,0x15
    800040ee:	c8650513          	addi	a0,a0,-890 # 80018d70 <tickslock>
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	af2080e7          	jalr	-1294(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800040fa:	00006917          	auipc	s2,0x6
    800040fe:	f5a92903          	lw	s2,-166(s2) # 8000a054 <ticks>
  
  while(ticks - ticks0 < n){
    80004102:	fcc42783          	lw	a5,-52(s0)
    80004106:	cf85                	beqz	a5,8000413e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80004108:	00015997          	auipc	s3,0x15
    8000410c:	c6898993          	addi	s3,s3,-920 # 80018d70 <tickslock>
    80004110:	00006497          	auipc	s1,0x6
    80004114:	f4448493          	addi	s1,s1,-188 # 8000a054 <ticks>
    if(myproc()->killed){
    80004118:	ffffe097          	auipc	ra,0xffffe
    8000411c:	ae8080e7          	jalr	-1304(ra) # 80001c00 <myproc>
    80004120:	551c                	lw	a5,40(a0)
    80004122:	ef9d                	bnez	a5,80004160 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80004124:	85ce                	mv	a1,s3
    80004126:	8526                	mv	a0,s1
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	af8080e7          	jalr	-1288(ra) # 80002c20 <sleep>
  while(ticks - ticks0 < n){
    80004130:	409c                	lw	a5,0(s1)
    80004132:	412787bb          	subw	a5,a5,s2
    80004136:	fcc42703          	lw	a4,-52(s0)
    8000413a:	fce7efe3          	bltu	a5,a4,80004118 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000413e:	00015517          	auipc	a0,0x15
    80004142:	c3250513          	addi	a0,a0,-974 # 80018d70 <tickslock>
    80004146:	ffffd097          	auipc	ra,0xffffd
    8000414a:	b52080e7          	jalr	-1198(ra) # 80000c98 <release>
  return 0;
    8000414e:	4781                	li	a5,0
}
    80004150:	853e                	mv	a0,a5
    80004152:	70e2                	ld	ra,56(sp)
    80004154:	7442                	ld	s0,48(sp)
    80004156:	74a2                	ld	s1,40(sp)
    80004158:	7902                	ld	s2,32(sp)
    8000415a:	69e2                	ld	s3,24(sp)
    8000415c:	6121                	addi	sp,sp,64
    8000415e:	8082                	ret
      release(&tickslock);
    80004160:	00015517          	auipc	a0,0x15
    80004164:	c1050513          	addi	a0,a0,-1008 # 80018d70 <tickslock>
    80004168:	ffffd097          	auipc	ra,0xffffd
    8000416c:	b30080e7          	jalr	-1232(ra) # 80000c98 <release>
      return -1;
    80004170:	57fd                	li	a5,-1
    80004172:	bff9                	j	80004150 <sys_sleep+0x88>

0000000080004174 <sys_kill>:

uint64
sys_kill(void)
{
    80004174:	1101                	addi	sp,sp,-32
    80004176:	ec06                	sd	ra,24(sp)
    80004178:	e822                	sd	s0,16(sp)
    8000417a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000417c:	fec40593          	addi	a1,s0,-20
    80004180:	4501                	li	a0,0
    80004182:	00000097          	auipc	ra,0x0
    80004186:	d84080e7          	jalr	-636(ra) # 80003f06 <argint>
    8000418a:	87aa                	mv	a5,a0
    return -1;
    8000418c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000418e:	0007c863          	bltz	a5,8000419e <sys_kill+0x2a>
  return kill(pid);
    80004192:	fec42503          	lw	a0,-20(s0)
    80004196:	fffff097          	auipc	ra,0xfffff
    8000419a:	2f4080e7          	jalr	756(ra) # 8000348a <kill>
}
    8000419e:	60e2                	ld	ra,24(sp)
    800041a0:	6442                	ld	s0,16(sp)
    800041a2:	6105                	addi	sp,sp,32
    800041a4:	8082                	ret

00000000800041a6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800041a6:	1101                	addi	sp,sp,-32
    800041a8:	ec06                	sd	ra,24(sp)
    800041aa:	e822                	sd	s0,16(sp)
    800041ac:	e426                	sd	s1,8(sp)
    800041ae:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800041b0:	00015517          	auipc	a0,0x15
    800041b4:	bc050513          	addi	a0,a0,-1088 # 80018d70 <tickslock>
    800041b8:	ffffd097          	auipc	ra,0xffffd
    800041bc:	a2c080e7          	jalr	-1492(ra) # 80000be4 <acquire>
  xticks = ticks;
    800041c0:	00006497          	auipc	s1,0x6
    800041c4:	e944a483          	lw	s1,-364(s1) # 8000a054 <ticks>
  release(&tickslock);
    800041c8:	00015517          	auipc	a0,0x15
    800041cc:	ba850513          	addi	a0,a0,-1112 # 80018d70 <tickslock>
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	ac8080e7          	jalr	-1336(ra) # 80000c98 <release>
  return xticks;
}
    800041d8:	02049513          	slli	a0,s1,0x20
    800041dc:	9101                	srli	a0,a0,0x20
    800041de:	60e2                	ld	ra,24(sp)
    800041e0:	6442                	ld	s0,16(sp)
    800041e2:	64a2                	ld	s1,8(sp)
    800041e4:	6105                	addi	sp,sp,32
    800041e6:	8082                	ret

00000000800041e8 <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800041e8:	1141                	addi	sp,sp,-16
    800041ea:	e406                	sd	ra,8(sp)
    800041ec:	e022                	sd	s0,0(sp)
    800041ee:	0800                	addi	s0,sp,16
  return print_stats();
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	320080e7          	jalr	800(ra) # 80003510 <print_stats>
}
    800041f8:	60a2                	ld	ra,8(sp)
    800041fa:	6402                	ld	s0,0(sp)
    800041fc:	0141                	addi	sp,sp,16
    800041fe:	8082                	ret

0000000080004200 <sys_get_cpu>:

// Ass2
uint64
sys_get_cpu(void)
{
    80004200:	1141                	addi	sp,sp,-16
    80004202:	e406                	sd	ra,8(sp)
    80004204:	e022                	sd	s0,0(sp)
    80004206:	0800                	addi	s0,sp,16
  return get_cpu();
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	46a080e7          	jalr	1130(ra) # 80003672 <get_cpu>
}
    80004210:	60a2                	ld	ra,8(sp)
    80004212:	6402                	ld	s0,0(sp)
    80004214:	0141                	addi	sp,sp,16
    80004216:	8082                	ret

0000000080004218 <sys_set_cpu>:

// Ass2
uint64
sys_set_cpu(void)
{
    80004218:	1101                	addi	sp,sp,-32
    8000421a:	ec06                	sd	ra,24(sp)
    8000421c:	e822                	sd	s0,16(sp)
    8000421e:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    80004220:	fec40593          	addi	a1,s0,-20
    80004224:	4501                	li	a0,0
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	ce0080e7          	jalr	-800(ra) # 80003f06 <argint>
    8000422e:	87aa                	mv	a5,a0
    return -1;
    80004230:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80004232:	0007c863          	bltz	a5,80004242 <sys_set_cpu+0x2a>

  return set_cpu(cpu_num);
    80004236:	fec42503          	lw	a0,-20(s0)
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	378080e7          	jalr	888(ra) # 800035b2 <set_cpu>
}
    80004242:	60e2                	ld	ra,24(sp)
    80004244:	6442                	ld	s0,16(sp)
    80004246:	6105                	addi	sp,sp,32
    80004248:	8082                	ret

000000008000424a <sys_pause_system>:



uint64
sys_pause_system(void)
{
    8000424a:	1101                	addi	sp,sp,-32
    8000424c:	ec06                	sd	ra,24(sp)
    8000424e:	e822                	sd	s0,16(sp)
    80004250:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80004252:	fec40593          	addi	a1,s0,-20
    80004256:	4501                	li	a0,0
    80004258:	00000097          	auipc	ra,0x0
    8000425c:	cae080e7          	jalr	-850(ra) # 80003f06 <argint>
    80004260:	87aa                	mv	a5,a0
    return -1;
    80004262:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80004264:	0007c863          	bltz	a5,80004274 <sys_pause_system+0x2a>

  return pause_system(seconds);
    80004268:	fec42503          	lw	a0,-20(s0)
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	416080e7          	jalr	1046(ra) # 80003682 <pause_system>
}
    80004274:	60e2                	ld	ra,24(sp)
    80004276:	6442                	ld	s0,16(sp)
    80004278:	6105                	addi	sp,sp,32
    8000427a:	8082                	ret

000000008000427c <sys_kill_system>:


uint64
sys_kill_system(void)
{
    8000427c:	1141                	addi	sp,sp,-16
    8000427e:	e406                	sd	ra,8(sp)
    80004280:	e022                	sd	s0,0(sp)
    80004282:	0800                	addi	s0,sp,16
  return kill_system(); 
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	55e080e7          	jalr	1374(ra) # 800037e2 <kill_system>
}
    8000428c:	60a2                	ld	ra,8(sp)
    8000428e:	6402                	ld	s0,0(sp)
    80004290:	0141                	addi	sp,sp,16
    80004292:	8082                	ret

0000000080004294 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80004294:	7179                	addi	sp,sp,-48
    80004296:	f406                	sd	ra,40(sp)
    80004298:	f022                	sd	s0,32(sp)
    8000429a:	ec26                	sd	s1,24(sp)
    8000429c:	e84a                	sd	s2,16(sp)
    8000429e:	e44e                	sd	s3,8(sp)
    800042a0:	e052                	sd	s4,0(sp)
    800042a2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800042a4:	00005597          	auipc	a1,0x5
    800042a8:	47458593          	addi	a1,a1,1140 # 80009718 <syscalls+0xd8>
    800042ac:	00015517          	auipc	a0,0x15
    800042b0:	adc50513          	addi	a0,a0,-1316 # 80018d88 <bcache>
    800042b4:	ffffd097          	auipc	ra,0xffffd
    800042b8:	8a0080e7          	jalr	-1888(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800042bc:	0001d797          	auipc	a5,0x1d
    800042c0:	acc78793          	addi	a5,a5,-1332 # 80020d88 <bcache+0x8000>
    800042c4:	0001d717          	auipc	a4,0x1d
    800042c8:	d2c70713          	addi	a4,a4,-724 # 80020ff0 <bcache+0x8268>
    800042cc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800042d0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800042d4:	00015497          	auipc	s1,0x15
    800042d8:	acc48493          	addi	s1,s1,-1332 # 80018da0 <bcache+0x18>
    b->next = bcache.head.next;
    800042dc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800042de:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800042e0:	00005a17          	auipc	s4,0x5
    800042e4:	440a0a13          	addi	s4,s4,1088 # 80009720 <syscalls+0xe0>
    b->next = bcache.head.next;
    800042e8:	2b893783          	ld	a5,696(s2)
    800042ec:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800042ee:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800042f2:	85d2                	mv	a1,s4
    800042f4:	01048513          	addi	a0,s1,16
    800042f8:	00001097          	auipc	ra,0x1
    800042fc:	4bc080e7          	jalr	1212(ra) # 800057b4 <initsleeplock>
    bcache.head.next->prev = b;
    80004300:	2b893783          	ld	a5,696(s2)
    80004304:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80004306:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000430a:	45848493          	addi	s1,s1,1112
    8000430e:	fd349de3          	bne	s1,s3,800042e8 <binit+0x54>
  }
}
    80004312:	70a2                	ld	ra,40(sp)
    80004314:	7402                	ld	s0,32(sp)
    80004316:	64e2                	ld	s1,24(sp)
    80004318:	6942                	ld	s2,16(sp)
    8000431a:	69a2                	ld	s3,8(sp)
    8000431c:	6a02                	ld	s4,0(sp)
    8000431e:	6145                	addi	sp,sp,48
    80004320:	8082                	ret

0000000080004322 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80004322:	7179                	addi	sp,sp,-48
    80004324:	f406                	sd	ra,40(sp)
    80004326:	f022                	sd	s0,32(sp)
    80004328:	ec26                	sd	s1,24(sp)
    8000432a:	e84a                	sd	s2,16(sp)
    8000432c:	e44e                	sd	s3,8(sp)
    8000432e:	1800                	addi	s0,sp,48
    80004330:	89aa                	mv	s3,a0
    80004332:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80004334:	00015517          	auipc	a0,0x15
    80004338:	a5450513          	addi	a0,a0,-1452 # 80018d88 <bcache>
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	8a8080e7          	jalr	-1880(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80004344:	0001d497          	auipc	s1,0x1d
    80004348:	cfc4b483          	ld	s1,-772(s1) # 80021040 <bcache+0x82b8>
    8000434c:	0001d797          	auipc	a5,0x1d
    80004350:	ca478793          	addi	a5,a5,-860 # 80020ff0 <bcache+0x8268>
    80004354:	02f48f63          	beq	s1,a5,80004392 <bread+0x70>
    80004358:	873e                	mv	a4,a5
    8000435a:	a021                	j	80004362 <bread+0x40>
    8000435c:	68a4                	ld	s1,80(s1)
    8000435e:	02e48a63          	beq	s1,a4,80004392 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80004362:	449c                	lw	a5,8(s1)
    80004364:	ff379ce3          	bne	a5,s3,8000435c <bread+0x3a>
    80004368:	44dc                	lw	a5,12(s1)
    8000436a:	ff2799e3          	bne	a5,s2,8000435c <bread+0x3a>
      b->refcnt++;
    8000436e:	40bc                	lw	a5,64(s1)
    80004370:	2785                	addiw	a5,a5,1
    80004372:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80004374:	00015517          	auipc	a0,0x15
    80004378:	a1450513          	addi	a0,a0,-1516 # 80018d88 <bcache>
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	91c080e7          	jalr	-1764(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80004384:	01048513          	addi	a0,s1,16
    80004388:	00001097          	auipc	ra,0x1
    8000438c:	466080e7          	jalr	1126(ra) # 800057ee <acquiresleep>
      return b;
    80004390:	a8b9                	j	800043ee <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80004392:	0001d497          	auipc	s1,0x1d
    80004396:	ca64b483          	ld	s1,-858(s1) # 80021038 <bcache+0x82b0>
    8000439a:	0001d797          	auipc	a5,0x1d
    8000439e:	c5678793          	addi	a5,a5,-938 # 80020ff0 <bcache+0x8268>
    800043a2:	00f48863          	beq	s1,a5,800043b2 <bread+0x90>
    800043a6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800043a8:	40bc                	lw	a5,64(s1)
    800043aa:	cf81                	beqz	a5,800043c2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800043ac:	64a4                	ld	s1,72(s1)
    800043ae:	fee49de3          	bne	s1,a4,800043a8 <bread+0x86>
  panic("bget: no buffers");
    800043b2:	00005517          	auipc	a0,0x5
    800043b6:	37650513          	addi	a0,a0,886 # 80009728 <syscalls+0xe8>
    800043ba:	ffffc097          	auipc	ra,0xffffc
    800043be:	184080e7          	jalr	388(ra) # 8000053e <panic>
      b->dev = dev;
    800043c2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800043c6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800043ca:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800043ce:	4785                	li	a5,1
    800043d0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800043d2:	00015517          	auipc	a0,0x15
    800043d6:	9b650513          	addi	a0,a0,-1610 # 80018d88 <bcache>
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	8be080e7          	jalr	-1858(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800043e2:	01048513          	addi	a0,s1,16
    800043e6:	00001097          	auipc	ra,0x1
    800043ea:	408080e7          	jalr	1032(ra) # 800057ee <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800043ee:	409c                	lw	a5,0(s1)
    800043f0:	cb89                	beqz	a5,80004402 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800043f2:	8526                	mv	a0,s1
    800043f4:	70a2                	ld	ra,40(sp)
    800043f6:	7402                	ld	s0,32(sp)
    800043f8:	64e2                	ld	s1,24(sp)
    800043fa:	6942                	ld	s2,16(sp)
    800043fc:	69a2                	ld	s3,8(sp)
    800043fe:	6145                	addi	sp,sp,48
    80004400:	8082                	ret
    virtio_disk_rw(b, 0);
    80004402:	4581                	li	a1,0
    80004404:	8526                	mv	a0,s1
    80004406:	00003097          	auipc	ra,0x3
    8000440a:	f10080e7          	jalr	-240(ra) # 80007316 <virtio_disk_rw>
    b->valid = 1;
    8000440e:	4785                	li	a5,1
    80004410:	c09c                	sw	a5,0(s1)
  return b;
    80004412:	b7c5                	j	800043f2 <bread+0xd0>

0000000080004414 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80004414:	1101                	addi	sp,sp,-32
    80004416:	ec06                	sd	ra,24(sp)
    80004418:	e822                	sd	s0,16(sp)
    8000441a:	e426                	sd	s1,8(sp)
    8000441c:	1000                	addi	s0,sp,32
    8000441e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004420:	0541                	addi	a0,a0,16
    80004422:	00001097          	auipc	ra,0x1
    80004426:	466080e7          	jalr	1126(ra) # 80005888 <holdingsleep>
    8000442a:	cd01                	beqz	a0,80004442 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000442c:	4585                	li	a1,1
    8000442e:	8526                	mv	a0,s1
    80004430:	00003097          	auipc	ra,0x3
    80004434:	ee6080e7          	jalr	-282(ra) # 80007316 <virtio_disk_rw>
}
    80004438:	60e2                	ld	ra,24(sp)
    8000443a:	6442                	ld	s0,16(sp)
    8000443c:	64a2                	ld	s1,8(sp)
    8000443e:	6105                	addi	sp,sp,32
    80004440:	8082                	ret
    panic("bwrite");
    80004442:	00005517          	auipc	a0,0x5
    80004446:	2fe50513          	addi	a0,a0,766 # 80009740 <syscalls+0x100>
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	0f4080e7          	jalr	244(ra) # 8000053e <panic>

0000000080004452 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80004452:	1101                	addi	sp,sp,-32
    80004454:	ec06                	sd	ra,24(sp)
    80004456:	e822                	sd	s0,16(sp)
    80004458:	e426                	sd	s1,8(sp)
    8000445a:	e04a                	sd	s2,0(sp)
    8000445c:	1000                	addi	s0,sp,32
    8000445e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004460:	01050913          	addi	s2,a0,16
    80004464:	854a                	mv	a0,s2
    80004466:	00001097          	auipc	ra,0x1
    8000446a:	422080e7          	jalr	1058(ra) # 80005888 <holdingsleep>
    8000446e:	c92d                	beqz	a0,800044e0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80004470:	854a                	mv	a0,s2
    80004472:	00001097          	auipc	ra,0x1
    80004476:	3d2080e7          	jalr	978(ra) # 80005844 <releasesleep>

  acquire(&bcache.lock);
    8000447a:	00015517          	auipc	a0,0x15
    8000447e:	90e50513          	addi	a0,a0,-1778 # 80018d88 <bcache>
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	762080e7          	jalr	1890(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000448a:	40bc                	lw	a5,64(s1)
    8000448c:	37fd                	addiw	a5,a5,-1
    8000448e:	0007871b          	sext.w	a4,a5
    80004492:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80004494:	eb05                	bnez	a4,800044c4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80004496:	68bc                	ld	a5,80(s1)
    80004498:	64b8                	ld	a4,72(s1)
    8000449a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000449c:	64bc                	ld	a5,72(s1)
    8000449e:	68b8                	ld	a4,80(s1)
    800044a0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800044a2:	0001d797          	auipc	a5,0x1d
    800044a6:	8e678793          	addi	a5,a5,-1818 # 80020d88 <bcache+0x8000>
    800044aa:	2b87b703          	ld	a4,696(a5)
    800044ae:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800044b0:	0001d717          	auipc	a4,0x1d
    800044b4:	b4070713          	addi	a4,a4,-1216 # 80020ff0 <bcache+0x8268>
    800044b8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800044ba:	2b87b703          	ld	a4,696(a5)
    800044be:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800044c0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800044c4:	00015517          	auipc	a0,0x15
    800044c8:	8c450513          	addi	a0,a0,-1852 # 80018d88 <bcache>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
}
    800044d4:	60e2                	ld	ra,24(sp)
    800044d6:	6442                	ld	s0,16(sp)
    800044d8:	64a2                	ld	s1,8(sp)
    800044da:	6902                	ld	s2,0(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret
    panic("brelse");
    800044e0:	00005517          	auipc	a0,0x5
    800044e4:	26850513          	addi	a0,a0,616 # 80009748 <syscalls+0x108>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	056080e7          	jalr	86(ra) # 8000053e <panic>

00000000800044f0 <bpin>:

void
bpin(struct buf *b) {
    800044f0:	1101                	addi	sp,sp,-32
    800044f2:	ec06                	sd	ra,24(sp)
    800044f4:	e822                	sd	s0,16(sp)
    800044f6:	e426                	sd	s1,8(sp)
    800044f8:	1000                	addi	s0,sp,32
    800044fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800044fc:	00015517          	auipc	a0,0x15
    80004500:	88c50513          	addi	a0,a0,-1908 # 80018d88 <bcache>
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	6e0080e7          	jalr	1760(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000450c:	40bc                	lw	a5,64(s1)
    8000450e:	2785                	addiw	a5,a5,1
    80004510:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004512:	00015517          	auipc	a0,0x15
    80004516:	87650513          	addi	a0,a0,-1930 # 80018d88 <bcache>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	77e080e7          	jalr	1918(ra) # 80000c98 <release>
}
    80004522:	60e2                	ld	ra,24(sp)
    80004524:	6442                	ld	s0,16(sp)
    80004526:	64a2                	ld	s1,8(sp)
    80004528:	6105                	addi	sp,sp,32
    8000452a:	8082                	ret

000000008000452c <bunpin>:

void
bunpin(struct buf *b) {
    8000452c:	1101                	addi	sp,sp,-32
    8000452e:	ec06                	sd	ra,24(sp)
    80004530:	e822                	sd	s0,16(sp)
    80004532:	e426                	sd	s1,8(sp)
    80004534:	1000                	addi	s0,sp,32
    80004536:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80004538:	00015517          	auipc	a0,0x15
    8000453c:	85050513          	addi	a0,a0,-1968 # 80018d88 <bcache>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	6a4080e7          	jalr	1700(ra) # 80000be4 <acquire>
  b->refcnt--;
    80004548:	40bc                	lw	a5,64(s1)
    8000454a:	37fd                	addiw	a5,a5,-1
    8000454c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000454e:	00015517          	auipc	a0,0x15
    80004552:	83a50513          	addi	a0,a0,-1990 # 80018d88 <bcache>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	742080e7          	jalr	1858(ra) # 80000c98 <release>
}
    8000455e:	60e2                	ld	ra,24(sp)
    80004560:	6442                	ld	s0,16(sp)
    80004562:	64a2                	ld	s1,8(sp)
    80004564:	6105                	addi	sp,sp,32
    80004566:	8082                	ret

0000000080004568 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	e04a                	sd	s2,0(sp)
    80004572:	1000                	addi	s0,sp,32
    80004574:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80004576:	00d5d59b          	srliw	a1,a1,0xd
    8000457a:	0001d797          	auipc	a5,0x1d
    8000457e:	eea7a783          	lw	a5,-278(a5) # 80021464 <sb+0x1c>
    80004582:	9dbd                	addw	a1,a1,a5
    80004584:	00000097          	auipc	ra,0x0
    80004588:	d9e080e7          	jalr	-610(ra) # 80004322 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000458c:	0074f713          	andi	a4,s1,7
    80004590:	4785                	li	a5,1
    80004592:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80004596:	14ce                	slli	s1,s1,0x33
    80004598:	90d9                	srli	s1,s1,0x36
    8000459a:	00950733          	add	a4,a0,s1
    8000459e:	05874703          	lbu	a4,88(a4)
    800045a2:	00e7f6b3          	and	a3,a5,a4
    800045a6:	c69d                	beqz	a3,800045d4 <bfree+0x6c>
    800045a8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800045aa:	94aa                	add	s1,s1,a0
    800045ac:	fff7c793          	not	a5,a5
    800045b0:	8ff9                	and	a5,a5,a4
    800045b2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800045b6:	00001097          	auipc	ra,0x1
    800045ba:	118080e7          	jalr	280(ra) # 800056ce <log_write>
  brelse(bp);
    800045be:	854a                	mv	a0,s2
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	e92080e7          	jalr	-366(ra) # 80004452 <brelse>
}
    800045c8:	60e2                	ld	ra,24(sp)
    800045ca:	6442                	ld	s0,16(sp)
    800045cc:	64a2                	ld	s1,8(sp)
    800045ce:	6902                	ld	s2,0(sp)
    800045d0:	6105                	addi	sp,sp,32
    800045d2:	8082                	ret
    panic("freeing free block");
    800045d4:	00005517          	auipc	a0,0x5
    800045d8:	17c50513          	addi	a0,a0,380 # 80009750 <syscalls+0x110>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	f62080e7          	jalr	-158(ra) # 8000053e <panic>

00000000800045e4 <balloc>:
{
    800045e4:	711d                	addi	sp,sp,-96
    800045e6:	ec86                	sd	ra,88(sp)
    800045e8:	e8a2                	sd	s0,80(sp)
    800045ea:	e4a6                	sd	s1,72(sp)
    800045ec:	e0ca                	sd	s2,64(sp)
    800045ee:	fc4e                	sd	s3,56(sp)
    800045f0:	f852                	sd	s4,48(sp)
    800045f2:	f456                	sd	s5,40(sp)
    800045f4:	f05a                	sd	s6,32(sp)
    800045f6:	ec5e                	sd	s7,24(sp)
    800045f8:	e862                	sd	s8,16(sp)
    800045fa:	e466                	sd	s9,8(sp)
    800045fc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800045fe:	0001d797          	auipc	a5,0x1d
    80004602:	e4e7a783          	lw	a5,-434(a5) # 8002144c <sb+0x4>
    80004606:	cbd1                	beqz	a5,8000469a <balloc+0xb6>
    80004608:	8baa                	mv	s7,a0
    8000460a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000460c:	0001db17          	auipc	s6,0x1d
    80004610:	e3cb0b13          	addi	s6,s6,-452 # 80021448 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004614:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80004616:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004618:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000461a:	6c89                	lui	s9,0x2
    8000461c:	a831                	j	80004638 <balloc+0x54>
    brelse(bp);
    8000461e:	854a                	mv	a0,s2
    80004620:	00000097          	auipc	ra,0x0
    80004624:	e32080e7          	jalr	-462(ra) # 80004452 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80004628:	015c87bb          	addw	a5,s9,s5
    8000462c:	00078a9b          	sext.w	s5,a5
    80004630:	004b2703          	lw	a4,4(s6)
    80004634:	06eaf363          	bgeu	s5,a4,8000469a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80004638:	41fad79b          	sraiw	a5,s5,0x1f
    8000463c:	0137d79b          	srliw	a5,a5,0x13
    80004640:	015787bb          	addw	a5,a5,s5
    80004644:	40d7d79b          	sraiw	a5,a5,0xd
    80004648:	01cb2583          	lw	a1,28(s6)
    8000464c:	9dbd                	addw	a1,a1,a5
    8000464e:	855e                	mv	a0,s7
    80004650:	00000097          	auipc	ra,0x0
    80004654:	cd2080e7          	jalr	-814(ra) # 80004322 <bread>
    80004658:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000465a:	004b2503          	lw	a0,4(s6)
    8000465e:	000a849b          	sext.w	s1,s5
    80004662:	8662                	mv	a2,s8
    80004664:	faa4fde3          	bgeu	s1,a0,8000461e <balloc+0x3a>
      m = 1 << (bi % 8);
    80004668:	41f6579b          	sraiw	a5,a2,0x1f
    8000466c:	01d7d69b          	srliw	a3,a5,0x1d
    80004670:	00c6873b          	addw	a4,a3,a2
    80004674:	00777793          	andi	a5,a4,7
    80004678:	9f95                	subw	a5,a5,a3
    8000467a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000467e:	4037571b          	sraiw	a4,a4,0x3
    80004682:	00e906b3          	add	a3,s2,a4
    80004686:	0586c683          	lbu	a3,88(a3)
    8000468a:	00d7f5b3          	and	a1,a5,a3
    8000468e:	cd91                	beqz	a1,800046aa <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004690:	2605                	addiw	a2,a2,1
    80004692:	2485                	addiw	s1,s1,1
    80004694:	fd4618e3          	bne	a2,s4,80004664 <balloc+0x80>
    80004698:	b759                	j	8000461e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000469a:	00005517          	auipc	a0,0x5
    8000469e:	0ce50513          	addi	a0,a0,206 # 80009768 <syscalls+0x128>
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	e9c080e7          	jalr	-356(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800046aa:	974a                	add	a4,a4,s2
    800046ac:	8fd5                	or	a5,a5,a3
    800046ae:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800046b2:	854a                	mv	a0,s2
    800046b4:	00001097          	auipc	ra,0x1
    800046b8:	01a080e7          	jalr	26(ra) # 800056ce <log_write>
        brelse(bp);
    800046bc:	854a                	mv	a0,s2
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	d94080e7          	jalr	-620(ra) # 80004452 <brelse>
  bp = bread(dev, bno);
    800046c6:	85a6                	mv	a1,s1
    800046c8:	855e                	mv	a0,s7
    800046ca:	00000097          	auipc	ra,0x0
    800046ce:	c58080e7          	jalr	-936(ra) # 80004322 <bread>
    800046d2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800046d4:	40000613          	li	a2,1024
    800046d8:	4581                	li	a1,0
    800046da:	05850513          	addi	a0,a0,88
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	602080e7          	jalr	1538(ra) # 80000ce0 <memset>
  log_write(bp);
    800046e6:	854a                	mv	a0,s2
    800046e8:	00001097          	auipc	ra,0x1
    800046ec:	fe6080e7          	jalr	-26(ra) # 800056ce <log_write>
  brelse(bp);
    800046f0:	854a                	mv	a0,s2
    800046f2:	00000097          	auipc	ra,0x0
    800046f6:	d60080e7          	jalr	-672(ra) # 80004452 <brelse>
}
    800046fa:	8526                	mv	a0,s1
    800046fc:	60e6                	ld	ra,88(sp)
    800046fe:	6446                	ld	s0,80(sp)
    80004700:	64a6                	ld	s1,72(sp)
    80004702:	6906                	ld	s2,64(sp)
    80004704:	79e2                	ld	s3,56(sp)
    80004706:	7a42                	ld	s4,48(sp)
    80004708:	7aa2                	ld	s5,40(sp)
    8000470a:	7b02                	ld	s6,32(sp)
    8000470c:	6be2                	ld	s7,24(sp)
    8000470e:	6c42                	ld	s8,16(sp)
    80004710:	6ca2                	ld	s9,8(sp)
    80004712:	6125                	addi	sp,sp,96
    80004714:	8082                	ret

0000000080004716 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80004716:	7179                	addi	sp,sp,-48
    80004718:	f406                	sd	ra,40(sp)
    8000471a:	f022                	sd	s0,32(sp)
    8000471c:	ec26                	sd	s1,24(sp)
    8000471e:	e84a                	sd	s2,16(sp)
    80004720:	e44e                	sd	s3,8(sp)
    80004722:	e052                	sd	s4,0(sp)
    80004724:	1800                	addi	s0,sp,48
    80004726:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80004728:	47ad                	li	a5,11
    8000472a:	04b7fe63          	bgeu	a5,a1,80004786 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000472e:	ff45849b          	addiw	s1,a1,-12
    80004732:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80004736:	0ff00793          	li	a5,255
    8000473a:	0ae7e363          	bltu	a5,a4,800047e0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000473e:	08052583          	lw	a1,128(a0)
    80004742:	c5ad                	beqz	a1,800047ac <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80004744:	00092503          	lw	a0,0(s2)
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	bda080e7          	jalr	-1062(ra) # 80004322 <bread>
    80004750:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004752:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80004756:	02049593          	slli	a1,s1,0x20
    8000475a:	9181                	srli	a1,a1,0x20
    8000475c:	058a                	slli	a1,a1,0x2
    8000475e:	00b784b3          	add	s1,a5,a1
    80004762:	0004a983          	lw	s3,0(s1)
    80004766:	04098d63          	beqz	s3,800047c0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000476a:	8552                	mv	a0,s4
    8000476c:	00000097          	auipc	ra,0x0
    80004770:	ce6080e7          	jalr	-794(ra) # 80004452 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004774:	854e                	mv	a0,s3
    80004776:	70a2                	ld	ra,40(sp)
    80004778:	7402                	ld	s0,32(sp)
    8000477a:	64e2                	ld	s1,24(sp)
    8000477c:	6942                	ld	s2,16(sp)
    8000477e:	69a2                	ld	s3,8(sp)
    80004780:	6a02                	ld	s4,0(sp)
    80004782:	6145                	addi	sp,sp,48
    80004784:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80004786:	02059493          	slli	s1,a1,0x20
    8000478a:	9081                	srli	s1,s1,0x20
    8000478c:	048a                	slli	s1,s1,0x2
    8000478e:	94aa                	add	s1,s1,a0
    80004790:	0504a983          	lw	s3,80(s1)
    80004794:	fe0990e3          	bnez	s3,80004774 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80004798:	4108                	lw	a0,0(a0)
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	e4a080e7          	jalr	-438(ra) # 800045e4 <balloc>
    800047a2:	0005099b          	sext.w	s3,a0
    800047a6:	0534a823          	sw	s3,80(s1)
    800047aa:	b7e9                	j	80004774 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800047ac:	4108                	lw	a0,0(a0)
    800047ae:	00000097          	auipc	ra,0x0
    800047b2:	e36080e7          	jalr	-458(ra) # 800045e4 <balloc>
    800047b6:	0005059b          	sext.w	a1,a0
    800047ba:	08b92023          	sw	a1,128(s2)
    800047be:	b759                	j	80004744 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800047c0:	00092503          	lw	a0,0(s2)
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	e20080e7          	jalr	-480(ra) # 800045e4 <balloc>
    800047cc:	0005099b          	sext.w	s3,a0
    800047d0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800047d4:	8552                	mv	a0,s4
    800047d6:	00001097          	auipc	ra,0x1
    800047da:	ef8080e7          	jalr	-264(ra) # 800056ce <log_write>
    800047de:	b771                	j	8000476a <bmap+0x54>
  panic("bmap: out of range");
    800047e0:	00005517          	auipc	a0,0x5
    800047e4:	fa050513          	addi	a0,a0,-96 # 80009780 <syscalls+0x140>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	d56080e7          	jalr	-682(ra) # 8000053e <panic>

00000000800047f0 <iget>:
{
    800047f0:	7179                	addi	sp,sp,-48
    800047f2:	f406                	sd	ra,40(sp)
    800047f4:	f022                	sd	s0,32(sp)
    800047f6:	ec26                	sd	s1,24(sp)
    800047f8:	e84a                	sd	s2,16(sp)
    800047fa:	e44e                	sd	s3,8(sp)
    800047fc:	e052                	sd	s4,0(sp)
    800047fe:	1800                	addi	s0,sp,48
    80004800:	89aa                	mv	s3,a0
    80004802:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004804:	0001d517          	auipc	a0,0x1d
    80004808:	c6450513          	addi	a0,a0,-924 # 80021468 <itable>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	3d8080e7          	jalr	984(ra) # 80000be4 <acquire>
  empty = 0;
    80004814:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004816:	0001d497          	auipc	s1,0x1d
    8000481a:	c6a48493          	addi	s1,s1,-918 # 80021480 <itable+0x18>
    8000481e:	0001e697          	auipc	a3,0x1e
    80004822:	6f268693          	addi	a3,a3,1778 # 80022f10 <log>
    80004826:	a039                	j	80004834 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004828:	02090b63          	beqz	s2,8000485e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000482c:	08848493          	addi	s1,s1,136
    80004830:	02d48a63          	beq	s1,a3,80004864 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004834:	449c                	lw	a5,8(s1)
    80004836:	fef059e3          	blez	a5,80004828 <iget+0x38>
    8000483a:	4098                	lw	a4,0(s1)
    8000483c:	ff3716e3          	bne	a4,s3,80004828 <iget+0x38>
    80004840:	40d8                	lw	a4,4(s1)
    80004842:	ff4713e3          	bne	a4,s4,80004828 <iget+0x38>
      ip->ref++;
    80004846:	2785                	addiw	a5,a5,1
    80004848:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000484a:	0001d517          	auipc	a0,0x1d
    8000484e:	c1e50513          	addi	a0,a0,-994 # 80021468 <itable>
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	446080e7          	jalr	1094(ra) # 80000c98 <release>
      return ip;
    8000485a:	8926                	mv	s2,s1
    8000485c:	a03d                	j	8000488a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000485e:	f7f9                	bnez	a5,8000482c <iget+0x3c>
    80004860:	8926                	mv	s2,s1
    80004862:	b7e9                	j	8000482c <iget+0x3c>
  if(empty == 0)
    80004864:	02090c63          	beqz	s2,8000489c <iget+0xac>
  ip->dev = dev;
    80004868:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000486c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004870:	4785                	li	a5,1
    80004872:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004876:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000487a:	0001d517          	auipc	a0,0x1d
    8000487e:	bee50513          	addi	a0,a0,-1042 # 80021468 <itable>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	416080e7          	jalr	1046(ra) # 80000c98 <release>
}
    8000488a:	854a                	mv	a0,s2
    8000488c:	70a2                	ld	ra,40(sp)
    8000488e:	7402                	ld	s0,32(sp)
    80004890:	64e2                	ld	s1,24(sp)
    80004892:	6942                	ld	s2,16(sp)
    80004894:	69a2                	ld	s3,8(sp)
    80004896:	6a02                	ld	s4,0(sp)
    80004898:	6145                	addi	sp,sp,48
    8000489a:	8082                	ret
    panic("iget: no inodes");
    8000489c:	00005517          	auipc	a0,0x5
    800048a0:	efc50513          	addi	a0,a0,-260 # 80009798 <syscalls+0x158>
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	c9a080e7          	jalr	-870(ra) # 8000053e <panic>

00000000800048ac <fsinit>:
fsinit(int dev) {
    800048ac:	7179                	addi	sp,sp,-48
    800048ae:	f406                	sd	ra,40(sp)
    800048b0:	f022                	sd	s0,32(sp)
    800048b2:	ec26                	sd	s1,24(sp)
    800048b4:	e84a                	sd	s2,16(sp)
    800048b6:	e44e                	sd	s3,8(sp)
    800048b8:	1800                	addi	s0,sp,48
    800048ba:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800048bc:	4585                	li	a1,1
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	a64080e7          	jalr	-1436(ra) # 80004322 <bread>
    800048c6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800048c8:	0001d997          	auipc	s3,0x1d
    800048cc:	b8098993          	addi	s3,s3,-1152 # 80021448 <sb>
    800048d0:	02000613          	li	a2,32
    800048d4:	05850593          	addi	a1,a0,88
    800048d8:	854e                	mv	a0,s3
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	466080e7          	jalr	1126(ra) # 80000d40 <memmove>
  brelse(bp);
    800048e2:	8526                	mv	a0,s1
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	b6e080e7          	jalr	-1170(ra) # 80004452 <brelse>
  if(sb.magic != FSMAGIC)
    800048ec:	0009a703          	lw	a4,0(s3)
    800048f0:	102037b7          	lui	a5,0x10203
    800048f4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800048f8:	02f71263          	bne	a4,a5,8000491c <fsinit+0x70>
  initlog(dev, &sb);
    800048fc:	0001d597          	auipc	a1,0x1d
    80004900:	b4c58593          	addi	a1,a1,-1204 # 80021448 <sb>
    80004904:	854a                	mv	a0,s2
    80004906:	00001097          	auipc	ra,0x1
    8000490a:	b4c080e7          	jalr	-1204(ra) # 80005452 <initlog>
}
    8000490e:	70a2                	ld	ra,40(sp)
    80004910:	7402                	ld	s0,32(sp)
    80004912:	64e2                	ld	s1,24(sp)
    80004914:	6942                	ld	s2,16(sp)
    80004916:	69a2                	ld	s3,8(sp)
    80004918:	6145                	addi	sp,sp,48
    8000491a:	8082                	ret
    panic("invalid file system");
    8000491c:	00005517          	auipc	a0,0x5
    80004920:	e8c50513          	addi	a0,a0,-372 # 800097a8 <syscalls+0x168>
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	c1a080e7          	jalr	-998(ra) # 8000053e <panic>

000000008000492c <iinit>:
{
    8000492c:	7179                	addi	sp,sp,-48
    8000492e:	f406                	sd	ra,40(sp)
    80004930:	f022                	sd	s0,32(sp)
    80004932:	ec26                	sd	s1,24(sp)
    80004934:	e84a                	sd	s2,16(sp)
    80004936:	e44e                	sd	s3,8(sp)
    80004938:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000493a:	00005597          	auipc	a1,0x5
    8000493e:	e8658593          	addi	a1,a1,-378 # 800097c0 <syscalls+0x180>
    80004942:	0001d517          	auipc	a0,0x1d
    80004946:	b2650513          	addi	a0,a0,-1242 # 80021468 <itable>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	20a080e7          	jalr	522(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004952:	0001d497          	auipc	s1,0x1d
    80004956:	b3e48493          	addi	s1,s1,-1218 # 80021490 <itable+0x28>
    8000495a:	0001e997          	auipc	s3,0x1e
    8000495e:	5c698993          	addi	s3,s3,1478 # 80022f20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004962:	00005917          	auipc	s2,0x5
    80004966:	e6690913          	addi	s2,s2,-410 # 800097c8 <syscalls+0x188>
    8000496a:	85ca                	mv	a1,s2
    8000496c:	8526                	mv	a0,s1
    8000496e:	00001097          	auipc	ra,0x1
    80004972:	e46080e7          	jalr	-442(ra) # 800057b4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004976:	08848493          	addi	s1,s1,136
    8000497a:	ff3498e3          	bne	s1,s3,8000496a <iinit+0x3e>
}
    8000497e:	70a2                	ld	ra,40(sp)
    80004980:	7402                	ld	s0,32(sp)
    80004982:	64e2                	ld	s1,24(sp)
    80004984:	6942                	ld	s2,16(sp)
    80004986:	69a2                	ld	s3,8(sp)
    80004988:	6145                	addi	sp,sp,48
    8000498a:	8082                	ret

000000008000498c <ialloc>:
{
    8000498c:	715d                	addi	sp,sp,-80
    8000498e:	e486                	sd	ra,72(sp)
    80004990:	e0a2                	sd	s0,64(sp)
    80004992:	fc26                	sd	s1,56(sp)
    80004994:	f84a                	sd	s2,48(sp)
    80004996:	f44e                	sd	s3,40(sp)
    80004998:	f052                	sd	s4,32(sp)
    8000499a:	ec56                	sd	s5,24(sp)
    8000499c:	e85a                	sd	s6,16(sp)
    8000499e:	e45e                	sd	s7,8(sp)
    800049a0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800049a2:	0001d717          	auipc	a4,0x1d
    800049a6:	ab272703          	lw	a4,-1358(a4) # 80021454 <sb+0xc>
    800049aa:	4785                	li	a5,1
    800049ac:	04e7fa63          	bgeu	a5,a4,80004a00 <ialloc+0x74>
    800049b0:	8aaa                	mv	s5,a0
    800049b2:	8bae                	mv	s7,a1
    800049b4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800049b6:	0001da17          	auipc	s4,0x1d
    800049ba:	a92a0a13          	addi	s4,s4,-1390 # 80021448 <sb>
    800049be:	00048b1b          	sext.w	s6,s1
    800049c2:	0044d593          	srli	a1,s1,0x4
    800049c6:	018a2783          	lw	a5,24(s4)
    800049ca:	9dbd                	addw	a1,a1,a5
    800049cc:	8556                	mv	a0,s5
    800049ce:	00000097          	auipc	ra,0x0
    800049d2:	954080e7          	jalr	-1708(ra) # 80004322 <bread>
    800049d6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800049d8:	05850993          	addi	s3,a0,88
    800049dc:	00f4f793          	andi	a5,s1,15
    800049e0:	079a                	slli	a5,a5,0x6
    800049e2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800049e4:	00099783          	lh	a5,0(s3)
    800049e8:	c785                	beqz	a5,80004a10 <ialloc+0x84>
    brelse(bp);
    800049ea:	00000097          	auipc	ra,0x0
    800049ee:	a68080e7          	jalr	-1432(ra) # 80004452 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800049f2:	0485                	addi	s1,s1,1
    800049f4:	00ca2703          	lw	a4,12(s4)
    800049f8:	0004879b          	sext.w	a5,s1
    800049fc:	fce7e1e3          	bltu	a5,a4,800049be <ialloc+0x32>
  panic("ialloc: no inodes");
    80004a00:	00005517          	auipc	a0,0x5
    80004a04:	dd050513          	addi	a0,a0,-560 # 800097d0 <syscalls+0x190>
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	b36080e7          	jalr	-1226(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80004a10:	04000613          	li	a2,64
    80004a14:	4581                	li	a1,0
    80004a16:	854e                	mv	a0,s3
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	2c8080e7          	jalr	712(ra) # 80000ce0 <memset>
      dip->type = type;
    80004a20:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004a24:	854a                	mv	a0,s2
    80004a26:	00001097          	auipc	ra,0x1
    80004a2a:	ca8080e7          	jalr	-856(ra) # 800056ce <log_write>
      brelse(bp);
    80004a2e:	854a                	mv	a0,s2
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	a22080e7          	jalr	-1502(ra) # 80004452 <brelse>
      return iget(dev, inum);
    80004a38:	85da                	mv	a1,s6
    80004a3a:	8556                	mv	a0,s5
    80004a3c:	00000097          	auipc	ra,0x0
    80004a40:	db4080e7          	jalr	-588(ra) # 800047f0 <iget>
}
    80004a44:	60a6                	ld	ra,72(sp)
    80004a46:	6406                	ld	s0,64(sp)
    80004a48:	74e2                	ld	s1,56(sp)
    80004a4a:	7942                	ld	s2,48(sp)
    80004a4c:	79a2                	ld	s3,40(sp)
    80004a4e:	7a02                	ld	s4,32(sp)
    80004a50:	6ae2                	ld	s5,24(sp)
    80004a52:	6b42                	ld	s6,16(sp)
    80004a54:	6ba2                	ld	s7,8(sp)
    80004a56:	6161                	addi	sp,sp,80
    80004a58:	8082                	ret

0000000080004a5a <iupdate>:
{
    80004a5a:	1101                	addi	sp,sp,-32
    80004a5c:	ec06                	sd	ra,24(sp)
    80004a5e:	e822                	sd	s0,16(sp)
    80004a60:	e426                	sd	s1,8(sp)
    80004a62:	e04a                	sd	s2,0(sp)
    80004a64:	1000                	addi	s0,sp,32
    80004a66:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004a68:	415c                	lw	a5,4(a0)
    80004a6a:	0047d79b          	srliw	a5,a5,0x4
    80004a6e:	0001d597          	auipc	a1,0x1d
    80004a72:	9f25a583          	lw	a1,-1550(a1) # 80021460 <sb+0x18>
    80004a76:	9dbd                	addw	a1,a1,a5
    80004a78:	4108                	lw	a0,0(a0)
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	8a8080e7          	jalr	-1880(ra) # 80004322 <bread>
    80004a82:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004a84:	05850793          	addi	a5,a0,88
    80004a88:	40c8                	lw	a0,4(s1)
    80004a8a:	893d                	andi	a0,a0,15
    80004a8c:	051a                	slli	a0,a0,0x6
    80004a8e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004a90:	04449703          	lh	a4,68(s1)
    80004a94:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004a98:	04649703          	lh	a4,70(s1)
    80004a9c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004aa0:	04849703          	lh	a4,72(s1)
    80004aa4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004aa8:	04a49703          	lh	a4,74(s1)
    80004aac:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004ab0:	44f8                	lw	a4,76(s1)
    80004ab2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004ab4:	03400613          	li	a2,52
    80004ab8:	05048593          	addi	a1,s1,80
    80004abc:	0531                	addi	a0,a0,12
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	282080e7          	jalr	642(ra) # 80000d40 <memmove>
  log_write(bp);
    80004ac6:	854a                	mv	a0,s2
    80004ac8:	00001097          	auipc	ra,0x1
    80004acc:	c06080e7          	jalr	-1018(ra) # 800056ce <log_write>
  brelse(bp);
    80004ad0:	854a                	mv	a0,s2
    80004ad2:	00000097          	auipc	ra,0x0
    80004ad6:	980080e7          	jalr	-1664(ra) # 80004452 <brelse>
}
    80004ada:	60e2                	ld	ra,24(sp)
    80004adc:	6442                	ld	s0,16(sp)
    80004ade:	64a2                	ld	s1,8(sp)
    80004ae0:	6902                	ld	s2,0(sp)
    80004ae2:	6105                	addi	sp,sp,32
    80004ae4:	8082                	ret

0000000080004ae6 <idup>:
{
    80004ae6:	1101                	addi	sp,sp,-32
    80004ae8:	ec06                	sd	ra,24(sp)
    80004aea:	e822                	sd	s0,16(sp)
    80004aec:	e426                	sd	s1,8(sp)
    80004aee:	1000                	addi	s0,sp,32
    80004af0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004af2:	0001d517          	auipc	a0,0x1d
    80004af6:	97650513          	addi	a0,a0,-1674 # 80021468 <itable>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	0ea080e7          	jalr	234(ra) # 80000be4 <acquire>
  ip->ref++;
    80004b02:	449c                	lw	a5,8(s1)
    80004b04:	2785                	addiw	a5,a5,1
    80004b06:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004b08:	0001d517          	auipc	a0,0x1d
    80004b0c:	96050513          	addi	a0,a0,-1696 # 80021468 <itable>
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	188080e7          	jalr	392(ra) # 80000c98 <release>
}
    80004b18:	8526                	mv	a0,s1
    80004b1a:	60e2                	ld	ra,24(sp)
    80004b1c:	6442                	ld	s0,16(sp)
    80004b1e:	64a2                	ld	s1,8(sp)
    80004b20:	6105                	addi	sp,sp,32
    80004b22:	8082                	ret

0000000080004b24 <ilock>:
{
    80004b24:	1101                	addi	sp,sp,-32
    80004b26:	ec06                	sd	ra,24(sp)
    80004b28:	e822                	sd	s0,16(sp)
    80004b2a:	e426                	sd	s1,8(sp)
    80004b2c:	e04a                	sd	s2,0(sp)
    80004b2e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004b30:	c115                	beqz	a0,80004b54 <ilock+0x30>
    80004b32:	84aa                	mv	s1,a0
    80004b34:	451c                	lw	a5,8(a0)
    80004b36:	00f05f63          	blez	a5,80004b54 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004b3a:	0541                	addi	a0,a0,16
    80004b3c:	00001097          	auipc	ra,0x1
    80004b40:	cb2080e7          	jalr	-846(ra) # 800057ee <acquiresleep>
  if(ip->valid == 0){
    80004b44:	40bc                	lw	a5,64(s1)
    80004b46:	cf99                	beqz	a5,80004b64 <ilock+0x40>
}
    80004b48:	60e2                	ld	ra,24(sp)
    80004b4a:	6442                	ld	s0,16(sp)
    80004b4c:	64a2                	ld	s1,8(sp)
    80004b4e:	6902                	ld	s2,0(sp)
    80004b50:	6105                	addi	sp,sp,32
    80004b52:	8082                	ret
    panic("ilock");
    80004b54:	00005517          	auipc	a0,0x5
    80004b58:	c9450513          	addi	a0,a0,-876 # 800097e8 <syscalls+0x1a8>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	9e2080e7          	jalr	-1566(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004b64:	40dc                	lw	a5,4(s1)
    80004b66:	0047d79b          	srliw	a5,a5,0x4
    80004b6a:	0001d597          	auipc	a1,0x1d
    80004b6e:	8f65a583          	lw	a1,-1802(a1) # 80021460 <sb+0x18>
    80004b72:	9dbd                	addw	a1,a1,a5
    80004b74:	4088                	lw	a0,0(s1)
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	7ac080e7          	jalr	1964(ra) # 80004322 <bread>
    80004b7e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004b80:	05850593          	addi	a1,a0,88
    80004b84:	40dc                	lw	a5,4(s1)
    80004b86:	8bbd                	andi	a5,a5,15
    80004b88:	079a                	slli	a5,a5,0x6
    80004b8a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004b8c:	00059783          	lh	a5,0(a1)
    80004b90:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004b94:	00259783          	lh	a5,2(a1)
    80004b98:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004b9c:	00459783          	lh	a5,4(a1)
    80004ba0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004ba4:	00659783          	lh	a5,6(a1)
    80004ba8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004bac:	459c                	lw	a5,8(a1)
    80004bae:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004bb0:	03400613          	li	a2,52
    80004bb4:	05b1                	addi	a1,a1,12
    80004bb6:	05048513          	addi	a0,s1,80
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	186080e7          	jalr	390(ra) # 80000d40 <memmove>
    brelse(bp);
    80004bc2:	854a                	mv	a0,s2
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	88e080e7          	jalr	-1906(ra) # 80004452 <brelse>
    ip->valid = 1;
    80004bcc:	4785                	li	a5,1
    80004bce:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004bd0:	04449783          	lh	a5,68(s1)
    80004bd4:	fbb5                	bnez	a5,80004b48 <ilock+0x24>
      panic("ilock: no type");
    80004bd6:	00005517          	auipc	a0,0x5
    80004bda:	c1a50513          	addi	a0,a0,-998 # 800097f0 <syscalls+0x1b0>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	960080e7          	jalr	-1696(ra) # 8000053e <panic>

0000000080004be6 <iunlock>:
{
    80004be6:	1101                	addi	sp,sp,-32
    80004be8:	ec06                	sd	ra,24(sp)
    80004bea:	e822                	sd	s0,16(sp)
    80004bec:	e426                	sd	s1,8(sp)
    80004bee:	e04a                	sd	s2,0(sp)
    80004bf0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004bf2:	c905                	beqz	a0,80004c22 <iunlock+0x3c>
    80004bf4:	84aa                	mv	s1,a0
    80004bf6:	01050913          	addi	s2,a0,16
    80004bfa:	854a                	mv	a0,s2
    80004bfc:	00001097          	auipc	ra,0x1
    80004c00:	c8c080e7          	jalr	-884(ra) # 80005888 <holdingsleep>
    80004c04:	cd19                	beqz	a0,80004c22 <iunlock+0x3c>
    80004c06:	449c                	lw	a5,8(s1)
    80004c08:	00f05d63          	blez	a5,80004c22 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004c0c:	854a                	mv	a0,s2
    80004c0e:	00001097          	auipc	ra,0x1
    80004c12:	c36080e7          	jalr	-970(ra) # 80005844 <releasesleep>
}
    80004c16:	60e2                	ld	ra,24(sp)
    80004c18:	6442                	ld	s0,16(sp)
    80004c1a:	64a2                	ld	s1,8(sp)
    80004c1c:	6902                	ld	s2,0(sp)
    80004c1e:	6105                	addi	sp,sp,32
    80004c20:	8082                	ret
    panic("iunlock");
    80004c22:	00005517          	auipc	a0,0x5
    80004c26:	bde50513          	addi	a0,a0,-1058 # 80009800 <syscalls+0x1c0>
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	914080e7          	jalr	-1772(ra) # 8000053e <panic>

0000000080004c32 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004c32:	7179                	addi	sp,sp,-48
    80004c34:	f406                	sd	ra,40(sp)
    80004c36:	f022                	sd	s0,32(sp)
    80004c38:	ec26                	sd	s1,24(sp)
    80004c3a:	e84a                	sd	s2,16(sp)
    80004c3c:	e44e                	sd	s3,8(sp)
    80004c3e:	e052                	sd	s4,0(sp)
    80004c40:	1800                	addi	s0,sp,48
    80004c42:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004c44:	05050493          	addi	s1,a0,80
    80004c48:	08050913          	addi	s2,a0,128
    80004c4c:	a021                	j	80004c54 <itrunc+0x22>
    80004c4e:	0491                	addi	s1,s1,4
    80004c50:	01248d63          	beq	s1,s2,80004c6a <itrunc+0x38>
    if(ip->addrs[i]){
    80004c54:	408c                	lw	a1,0(s1)
    80004c56:	dde5                	beqz	a1,80004c4e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004c58:	0009a503          	lw	a0,0(s3)
    80004c5c:	00000097          	auipc	ra,0x0
    80004c60:	90c080e7          	jalr	-1780(ra) # 80004568 <bfree>
      ip->addrs[i] = 0;
    80004c64:	0004a023          	sw	zero,0(s1)
    80004c68:	b7dd                	j	80004c4e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004c6a:	0809a583          	lw	a1,128(s3)
    80004c6e:	e185                	bnez	a1,80004c8e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004c70:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004c74:	854e                	mv	a0,s3
    80004c76:	00000097          	auipc	ra,0x0
    80004c7a:	de4080e7          	jalr	-540(ra) # 80004a5a <iupdate>
}
    80004c7e:	70a2                	ld	ra,40(sp)
    80004c80:	7402                	ld	s0,32(sp)
    80004c82:	64e2                	ld	s1,24(sp)
    80004c84:	6942                	ld	s2,16(sp)
    80004c86:	69a2                	ld	s3,8(sp)
    80004c88:	6a02                	ld	s4,0(sp)
    80004c8a:	6145                	addi	sp,sp,48
    80004c8c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004c8e:	0009a503          	lw	a0,0(s3)
    80004c92:	fffff097          	auipc	ra,0xfffff
    80004c96:	690080e7          	jalr	1680(ra) # 80004322 <bread>
    80004c9a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004c9c:	05850493          	addi	s1,a0,88
    80004ca0:	45850913          	addi	s2,a0,1112
    80004ca4:	a811                	j	80004cb8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004ca6:	0009a503          	lw	a0,0(s3)
    80004caa:	00000097          	auipc	ra,0x0
    80004cae:	8be080e7          	jalr	-1858(ra) # 80004568 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004cb2:	0491                	addi	s1,s1,4
    80004cb4:	01248563          	beq	s1,s2,80004cbe <itrunc+0x8c>
      if(a[j])
    80004cb8:	408c                	lw	a1,0(s1)
    80004cba:	dde5                	beqz	a1,80004cb2 <itrunc+0x80>
    80004cbc:	b7ed                	j	80004ca6 <itrunc+0x74>
    brelse(bp);
    80004cbe:	8552                	mv	a0,s4
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	792080e7          	jalr	1938(ra) # 80004452 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004cc8:	0809a583          	lw	a1,128(s3)
    80004ccc:	0009a503          	lw	a0,0(s3)
    80004cd0:	00000097          	auipc	ra,0x0
    80004cd4:	898080e7          	jalr	-1896(ra) # 80004568 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004cd8:	0809a023          	sw	zero,128(s3)
    80004cdc:	bf51                	j	80004c70 <itrunc+0x3e>

0000000080004cde <iput>:
{
    80004cde:	1101                	addi	sp,sp,-32
    80004ce0:	ec06                	sd	ra,24(sp)
    80004ce2:	e822                	sd	s0,16(sp)
    80004ce4:	e426                	sd	s1,8(sp)
    80004ce6:	e04a                	sd	s2,0(sp)
    80004ce8:	1000                	addi	s0,sp,32
    80004cea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004cec:	0001c517          	auipc	a0,0x1c
    80004cf0:	77c50513          	addi	a0,a0,1916 # 80021468 <itable>
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	ef0080e7          	jalr	-272(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004cfc:	4498                	lw	a4,8(s1)
    80004cfe:	4785                	li	a5,1
    80004d00:	02f70363          	beq	a4,a5,80004d26 <iput+0x48>
  ip->ref--;
    80004d04:	449c                	lw	a5,8(s1)
    80004d06:	37fd                	addiw	a5,a5,-1
    80004d08:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004d0a:	0001c517          	auipc	a0,0x1c
    80004d0e:	75e50513          	addi	a0,a0,1886 # 80021468 <itable>
    80004d12:	ffffc097          	auipc	ra,0xffffc
    80004d16:	f86080e7          	jalr	-122(ra) # 80000c98 <release>
}
    80004d1a:	60e2                	ld	ra,24(sp)
    80004d1c:	6442                	ld	s0,16(sp)
    80004d1e:	64a2                	ld	s1,8(sp)
    80004d20:	6902                	ld	s2,0(sp)
    80004d22:	6105                	addi	sp,sp,32
    80004d24:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004d26:	40bc                	lw	a5,64(s1)
    80004d28:	dff1                	beqz	a5,80004d04 <iput+0x26>
    80004d2a:	04a49783          	lh	a5,74(s1)
    80004d2e:	fbf9                	bnez	a5,80004d04 <iput+0x26>
    acquiresleep(&ip->lock);
    80004d30:	01048913          	addi	s2,s1,16
    80004d34:	854a                	mv	a0,s2
    80004d36:	00001097          	auipc	ra,0x1
    80004d3a:	ab8080e7          	jalr	-1352(ra) # 800057ee <acquiresleep>
    release(&itable.lock);
    80004d3e:	0001c517          	auipc	a0,0x1c
    80004d42:	72a50513          	addi	a0,a0,1834 # 80021468 <itable>
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	f52080e7          	jalr	-174(ra) # 80000c98 <release>
    itrunc(ip);
    80004d4e:	8526                	mv	a0,s1
    80004d50:	00000097          	auipc	ra,0x0
    80004d54:	ee2080e7          	jalr	-286(ra) # 80004c32 <itrunc>
    ip->type = 0;
    80004d58:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	00000097          	auipc	ra,0x0
    80004d62:	cfc080e7          	jalr	-772(ra) # 80004a5a <iupdate>
    ip->valid = 0;
    80004d66:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004d6a:	854a                	mv	a0,s2
    80004d6c:	00001097          	auipc	ra,0x1
    80004d70:	ad8080e7          	jalr	-1320(ra) # 80005844 <releasesleep>
    acquire(&itable.lock);
    80004d74:	0001c517          	auipc	a0,0x1c
    80004d78:	6f450513          	addi	a0,a0,1780 # 80021468 <itable>
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	e68080e7          	jalr	-408(ra) # 80000be4 <acquire>
    80004d84:	b741                	j	80004d04 <iput+0x26>

0000000080004d86 <iunlockput>:
{
    80004d86:	1101                	addi	sp,sp,-32
    80004d88:	ec06                	sd	ra,24(sp)
    80004d8a:	e822                	sd	s0,16(sp)
    80004d8c:	e426                	sd	s1,8(sp)
    80004d8e:	1000                	addi	s0,sp,32
    80004d90:	84aa                	mv	s1,a0
  iunlock(ip);
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	e54080e7          	jalr	-428(ra) # 80004be6 <iunlock>
  iput(ip);
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	f42080e7          	jalr	-190(ra) # 80004cde <iput>
}
    80004da4:	60e2                	ld	ra,24(sp)
    80004da6:	6442                	ld	s0,16(sp)
    80004da8:	64a2                	ld	s1,8(sp)
    80004daa:	6105                	addi	sp,sp,32
    80004dac:	8082                	ret

0000000080004dae <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004dae:	1141                	addi	sp,sp,-16
    80004db0:	e422                	sd	s0,8(sp)
    80004db2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004db4:	411c                	lw	a5,0(a0)
    80004db6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004db8:	415c                	lw	a5,4(a0)
    80004dba:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004dbc:	04451783          	lh	a5,68(a0)
    80004dc0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004dc4:	04a51783          	lh	a5,74(a0)
    80004dc8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004dcc:	04c56783          	lwu	a5,76(a0)
    80004dd0:	e99c                	sd	a5,16(a1)
}
    80004dd2:	6422                	ld	s0,8(sp)
    80004dd4:	0141                	addi	sp,sp,16
    80004dd6:	8082                	ret

0000000080004dd8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004dd8:	457c                	lw	a5,76(a0)
    80004dda:	0ed7e963          	bltu	a5,a3,80004ecc <readi+0xf4>
{
    80004dde:	7159                	addi	sp,sp,-112
    80004de0:	f486                	sd	ra,104(sp)
    80004de2:	f0a2                	sd	s0,96(sp)
    80004de4:	eca6                	sd	s1,88(sp)
    80004de6:	e8ca                	sd	s2,80(sp)
    80004de8:	e4ce                	sd	s3,72(sp)
    80004dea:	e0d2                	sd	s4,64(sp)
    80004dec:	fc56                	sd	s5,56(sp)
    80004dee:	f85a                	sd	s6,48(sp)
    80004df0:	f45e                	sd	s7,40(sp)
    80004df2:	f062                	sd	s8,32(sp)
    80004df4:	ec66                	sd	s9,24(sp)
    80004df6:	e86a                	sd	s10,16(sp)
    80004df8:	e46e                	sd	s11,8(sp)
    80004dfa:	1880                	addi	s0,sp,112
    80004dfc:	8baa                	mv	s7,a0
    80004dfe:	8c2e                	mv	s8,a1
    80004e00:	8ab2                	mv	s5,a2
    80004e02:	84b6                	mv	s1,a3
    80004e04:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004e06:	9f35                	addw	a4,a4,a3
    return 0;
    80004e08:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004e0a:	0ad76063          	bltu	a4,a3,80004eaa <readi+0xd2>
  if(off + n > ip->size)
    80004e0e:	00e7f463          	bgeu	a5,a4,80004e16 <readi+0x3e>
    n = ip->size - off;
    80004e12:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004e16:	0a0b0963          	beqz	s6,80004ec8 <readi+0xf0>
    80004e1a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004e1c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004e20:	5cfd                	li	s9,-1
    80004e22:	a82d                	j	80004e5c <readi+0x84>
    80004e24:	020a1d93          	slli	s11,s4,0x20
    80004e28:	020ddd93          	srli	s11,s11,0x20
    80004e2c:	05890613          	addi	a2,s2,88
    80004e30:	86ee                	mv	a3,s11
    80004e32:	963a                	add	a2,a2,a4
    80004e34:	85d6                	mv	a1,s5
    80004e36:	8562                	mv	a0,s8
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	a74080e7          	jalr	-1420(ra) # 800038ac <either_copyout>
    80004e40:	05950d63          	beq	a0,s9,80004e9a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004e44:	854a                	mv	a0,s2
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	60c080e7          	jalr	1548(ra) # 80004452 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004e4e:	013a09bb          	addw	s3,s4,s3
    80004e52:	009a04bb          	addw	s1,s4,s1
    80004e56:	9aee                	add	s5,s5,s11
    80004e58:	0569f763          	bgeu	s3,s6,80004ea6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004e5c:	000ba903          	lw	s2,0(s7)
    80004e60:	00a4d59b          	srliw	a1,s1,0xa
    80004e64:	855e                	mv	a0,s7
    80004e66:	00000097          	auipc	ra,0x0
    80004e6a:	8b0080e7          	jalr	-1872(ra) # 80004716 <bmap>
    80004e6e:	0005059b          	sext.w	a1,a0
    80004e72:	854a                	mv	a0,s2
    80004e74:	fffff097          	auipc	ra,0xfffff
    80004e78:	4ae080e7          	jalr	1198(ra) # 80004322 <bread>
    80004e7c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004e7e:	3ff4f713          	andi	a4,s1,1023
    80004e82:	40ed07bb          	subw	a5,s10,a4
    80004e86:	413b06bb          	subw	a3,s6,s3
    80004e8a:	8a3e                	mv	s4,a5
    80004e8c:	2781                	sext.w	a5,a5
    80004e8e:	0006861b          	sext.w	a2,a3
    80004e92:	f8f679e3          	bgeu	a2,a5,80004e24 <readi+0x4c>
    80004e96:	8a36                	mv	s4,a3
    80004e98:	b771                	j	80004e24 <readi+0x4c>
      brelse(bp);
    80004e9a:	854a                	mv	a0,s2
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	5b6080e7          	jalr	1462(ra) # 80004452 <brelse>
      tot = -1;
    80004ea4:	59fd                	li	s3,-1
  }
  return tot;
    80004ea6:	0009851b          	sext.w	a0,s3
}
    80004eaa:	70a6                	ld	ra,104(sp)
    80004eac:	7406                	ld	s0,96(sp)
    80004eae:	64e6                	ld	s1,88(sp)
    80004eb0:	6946                	ld	s2,80(sp)
    80004eb2:	69a6                	ld	s3,72(sp)
    80004eb4:	6a06                	ld	s4,64(sp)
    80004eb6:	7ae2                	ld	s5,56(sp)
    80004eb8:	7b42                	ld	s6,48(sp)
    80004eba:	7ba2                	ld	s7,40(sp)
    80004ebc:	7c02                	ld	s8,32(sp)
    80004ebe:	6ce2                	ld	s9,24(sp)
    80004ec0:	6d42                	ld	s10,16(sp)
    80004ec2:	6da2                	ld	s11,8(sp)
    80004ec4:	6165                	addi	sp,sp,112
    80004ec6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004ec8:	89da                	mv	s3,s6
    80004eca:	bff1                	j	80004ea6 <readi+0xce>
    return 0;
    80004ecc:	4501                	li	a0,0
}
    80004ece:	8082                	ret

0000000080004ed0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004ed0:	457c                	lw	a5,76(a0)
    80004ed2:	10d7e863          	bltu	a5,a3,80004fe2 <writei+0x112>
{
    80004ed6:	7159                	addi	sp,sp,-112
    80004ed8:	f486                	sd	ra,104(sp)
    80004eda:	f0a2                	sd	s0,96(sp)
    80004edc:	eca6                	sd	s1,88(sp)
    80004ede:	e8ca                	sd	s2,80(sp)
    80004ee0:	e4ce                	sd	s3,72(sp)
    80004ee2:	e0d2                	sd	s4,64(sp)
    80004ee4:	fc56                	sd	s5,56(sp)
    80004ee6:	f85a                	sd	s6,48(sp)
    80004ee8:	f45e                	sd	s7,40(sp)
    80004eea:	f062                	sd	s8,32(sp)
    80004eec:	ec66                	sd	s9,24(sp)
    80004eee:	e86a                	sd	s10,16(sp)
    80004ef0:	e46e                	sd	s11,8(sp)
    80004ef2:	1880                	addi	s0,sp,112
    80004ef4:	8b2a                	mv	s6,a0
    80004ef6:	8c2e                	mv	s8,a1
    80004ef8:	8ab2                	mv	s5,a2
    80004efa:	8936                	mv	s2,a3
    80004efc:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004efe:	00e687bb          	addw	a5,a3,a4
    80004f02:	0ed7e263          	bltu	a5,a3,80004fe6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004f06:	00043737          	lui	a4,0x43
    80004f0a:	0ef76063          	bltu	a4,a5,80004fea <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004f0e:	0c0b8863          	beqz	s7,80004fde <writei+0x10e>
    80004f12:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004f14:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004f18:	5cfd                	li	s9,-1
    80004f1a:	a091                	j	80004f5e <writei+0x8e>
    80004f1c:	02099d93          	slli	s11,s3,0x20
    80004f20:	020ddd93          	srli	s11,s11,0x20
    80004f24:	05848513          	addi	a0,s1,88
    80004f28:	86ee                	mv	a3,s11
    80004f2a:	8656                	mv	a2,s5
    80004f2c:	85e2                	mv	a1,s8
    80004f2e:	953a                	add	a0,a0,a4
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	9d2080e7          	jalr	-1582(ra) # 80003902 <either_copyin>
    80004f38:	07950263          	beq	a0,s9,80004f9c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	00000097          	auipc	ra,0x0
    80004f42:	790080e7          	jalr	1936(ra) # 800056ce <log_write>
    brelse(bp);
    80004f46:	8526                	mv	a0,s1
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	50a080e7          	jalr	1290(ra) # 80004452 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004f50:	01498a3b          	addw	s4,s3,s4
    80004f54:	0129893b          	addw	s2,s3,s2
    80004f58:	9aee                	add	s5,s5,s11
    80004f5a:	057a7663          	bgeu	s4,s7,80004fa6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004f5e:	000b2483          	lw	s1,0(s6)
    80004f62:	00a9559b          	srliw	a1,s2,0xa
    80004f66:	855a                	mv	a0,s6
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	7ae080e7          	jalr	1966(ra) # 80004716 <bmap>
    80004f70:	0005059b          	sext.w	a1,a0
    80004f74:	8526                	mv	a0,s1
    80004f76:	fffff097          	auipc	ra,0xfffff
    80004f7a:	3ac080e7          	jalr	940(ra) # 80004322 <bread>
    80004f7e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004f80:	3ff97713          	andi	a4,s2,1023
    80004f84:	40ed07bb          	subw	a5,s10,a4
    80004f88:	414b86bb          	subw	a3,s7,s4
    80004f8c:	89be                	mv	s3,a5
    80004f8e:	2781                	sext.w	a5,a5
    80004f90:	0006861b          	sext.w	a2,a3
    80004f94:	f8f674e3          	bgeu	a2,a5,80004f1c <writei+0x4c>
    80004f98:	89b6                	mv	s3,a3
    80004f9a:	b749                	j	80004f1c <writei+0x4c>
      brelse(bp);
    80004f9c:	8526                	mv	a0,s1
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	4b4080e7          	jalr	1204(ra) # 80004452 <brelse>
  }

  if(off > ip->size)
    80004fa6:	04cb2783          	lw	a5,76(s6)
    80004faa:	0127f463          	bgeu	a5,s2,80004fb2 <writei+0xe2>
    ip->size = off;
    80004fae:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004fb2:	855a                	mv	a0,s6
    80004fb4:	00000097          	auipc	ra,0x0
    80004fb8:	aa6080e7          	jalr	-1370(ra) # 80004a5a <iupdate>

  return tot;
    80004fbc:	000a051b          	sext.w	a0,s4
}
    80004fc0:	70a6                	ld	ra,104(sp)
    80004fc2:	7406                	ld	s0,96(sp)
    80004fc4:	64e6                	ld	s1,88(sp)
    80004fc6:	6946                	ld	s2,80(sp)
    80004fc8:	69a6                	ld	s3,72(sp)
    80004fca:	6a06                	ld	s4,64(sp)
    80004fcc:	7ae2                	ld	s5,56(sp)
    80004fce:	7b42                	ld	s6,48(sp)
    80004fd0:	7ba2                	ld	s7,40(sp)
    80004fd2:	7c02                	ld	s8,32(sp)
    80004fd4:	6ce2                	ld	s9,24(sp)
    80004fd6:	6d42                	ld	s10,16(sp)
    80004fd8:	6da2                	ld	s11,8(sp)
    80004fda:	6165                	addi	sp,sp,112
    80004fdc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004fde:	8a5e                	mv	s4,s7
    80004fe0:	bfc9                	j	80004fb2 <writei+0xe2>
    return -1;
    80004fe2:	557d                	li	a0,-1
}
    80004fe4:	8082                	ret
    return -1;
    80004fe6:	557d                	li	a0,-1
    80004fe8:	bfe1                	j	80004fc0 <writei+0xf0>
    return -1;
    80004fea:	557d                	li	a0,-1
    80004fec:	bfd1                	j	80004fc0 <writei+0xf0>

0000000080004fee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004fee:	1141                	addi	sp,sp,-16
    80004ff0:	e406                	sd	ra,8(sp)
    80004ff2:	e022                	sd	s0,0(sp)
    80004ff4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004ff6:	4639                	li	a2,14
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	dc0080e7          	jalr	-576(ra) # 80000db8 <strncmp>
}
    80005000:	60a2                	ld	ra,8(sp)
    80005002:	6402                	ld	s0,0(sp)
    80005004:	0141                	addi	sp,sp,16
    80005006:	8082                	ret

0000000080005008 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80005008:	7139                	addi	sp,sp,-64
    8000500a:	fc06                	sd	ra,56(sp)
    8000500c:	f822                	sd	s0,48(sp)
    8000500e:	f426                	sd	s1,40(sp)
    80005010:	f04a                	sd	s2,32(sp)
    80005012:	ec4e                	sd	s3,24(sp)
    80005014:	e852                	sd	s4,16(sp)
    80005016:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80005018:	04451703          	lh	a4,68(a0)
    8000501c:	4785                	li	a5,1
    8000501e:	00f71a63          	bne	a4,a5,80005032 <dirlookup+0x2a>
    80005022:	892a                	mv	s2,a0
    80005024:	89ae                	mv	s3,a1
    80005026:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80005028:	457c                	lw	a5,76(a0)
    8000502a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000502c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000502e:	e79d                	bnez	a5,8000505c <dirlookup+0x54>
    80005030:	a8a5                	j	800050a8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80005032:	00004517          	auipc	a0,0x4
    80005036:	7d650513          	addi	a0,a0,2006 # 80009808 <syscalls+0x1c8>
    8000503a:	ffffb097          	auipc	ra,0xffffb
    8000503e:	504080e7          	jalr	1284(ra) # 8000053e <panic>
      panic("dirlookup read");
    80005042:	00004517          	auipc	a0,0x4
    80005046:	7de50513          	addi	a0,a0,2014 # 80009820 <syscalls+0x1e0>
    8000504a:	ffffb097          	auipc	ra,0xffffb
    8000504e:	4f4080e7          	jalr	1268(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005052:	24c1                	addiw	s1,s1,16
    80005054:	04c92783          	lw	a5,76(s2)
    80005058:	04f4f763          	bgeu	s1,a5,800050a6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000505c:	4741                	li	a4,16
    8000505e:	86a6                	mv	a3,s1
    80005060:	fc040613          	addi	a2,s0,-64
    80005064:	4581                	li	a1,0
    80005066:	854a                	mv	a0,s2
    80005068:	00000097          	auipc	ra,0x0
    8000506c:	d70080e7          	jalr	-656(ra) # 80004dd8 <readi>
    80005070:	47c1                	li	a5,16
    80005072:	fcf518e3          	bne	a0,a5,80005042 <dirlookup+0x3a>
    if(de.inum == 0)
    80005076:	fc045783          	lhu	a5,-64(s0)
    8000507a:	dfe1                	beqz	a5,80005052 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000507c:	fc240593          	addi	a1,s0,-62
    80005080:	854e                	mv	a0,s3
    80005082:	00000097          	auipc	ra,0x0
    80005086:	f6c080e7          	jalr	-148(ra) # 80004fee <namecmp>
    8000508a:	f561                	bnez	a0,80005052 <dirlookup+0x4a>
      if(poff)
    8000508c:	000a0463          	beqz	s4,80005094 <dirlookup+0x8c>
        *poff = off;
    80005090:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80005094:	fc045583          	lhu	a1,-64(s0)
    80005098:	00092503          	lw	a0,0(s2)
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	754080e7          	jalr	1876(ra) # 800047f0 <iget>
    800050a4:	a011                	j	800050a8 <dirlookup+0xa0>
  return 0;
    800050a6:	4501                	li	a0,0
}
    800050a8:	70e2                	ld	ra,56(sp)
    800050aa:	7442                	ld	s0,48(sp)
    800050ac:	74a2                	ld	s1,40(sp)
    800050ae:	7902                	ld	s2,32(sp)
    800050b0:	69e2                	ld	s3,24(sp)
    800050b2:	6a42                	ld	s4,16(sp)
    800050b4:	6121                	addi	sp,sp,64
    800050b6:	8082                	ret

00000000800050b8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800050b8:	711d                	addi	sp,sp,-96
    800050ba:	ec86                	sd	ra,88(sp)
    800050bc:	e8a2                	sd	s0,80(sp)
    800050be:	e4a6                	sd	s1,72(sp)
    800050c0:	e0ca                	sd	s2,64(sp)
    800050c2:	fc4e                	sd	s3,56(sp)
    800050c4:	f852                	sd	s4,48(sp)
    800050c6:	f456                	sd	s5,40(sp)
    800050c8:	f05a                	sd	s6,32(sp)
    800050ca:	ec5e                	sd	s7,24(sp)
    800050cc:	e862                	sd	s8,16(sp)
    800050ce:	e466                	sd	s9,8(sp)
    800050d0:	1080                	addi	s0,sp,96
    800050d2:	84aa                	mv	s1,a0
    800050d4:	8b2e                	mv	s6,a1
    800050d6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800050d8:	00054703          	lbu	a4,0(a0)
    800050dc:	02f00793          	li	a5,47
    800050e0:	02f70363          	beq	a4,a5,80005106 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	b1c080e7          	jalr	-1252(ra) # 80001c00 <myproc>
    800050ec:	18053503          	ld	a0,384(a0)
    800050f0:	00000097          	auipc	ra,0x0
    800050f4:	9f6080e7          	jalr	-1546(ra) # 80004ae6 <idup>
    800050f8:	89aa                	mv	s3,a0
  while(*path == '/')
    800050fa:	02f00913          	li	s2,47
  len = path - s;
    800050fe:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80005100:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80005102:	4c05                	li	s8,1
    80005104:	a865                	j	800051bc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80005106:	4585                	li	a1,1
    80005108:	4505                	li	a0,1
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	6e6080e7          	jalr	1766(ra) # 800047f0 <iget>
    80005112:	89aa                	mv	s3,a0
    80005114:	b7dd                	j	800050fa <namex+0x42>
      iunlockput(ip);
    80005116:	854e                	mv	a0,s3
    80005118:	00000097          	auipc	ra,0x0
    8000511c:	c6e080e7          	jalr	-914(ra) # 80004d86 <iunlockput>
      return 0;
    80005120:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80005122:	854e                	mv	a0,s3
    80005124:	60e6                	ld	ra,88(sp)
    80005126:	6446                	ld	s0,80(sp)
    80005128:	64a6                	ld	s1,72(sp)
    8000512a:	6906                	ld	s2,64(sp)
    8000512c:	79e2                	ld	s3,56(sp)
    8000512e:	7a42                	ld	s4,48(sp)
    80005130:	7aa2                	ld	s5,40(sp)
    80005132:	7b02                	ld	s6,32(sp)
    80005134:	6be2                	ld	s7,24(sp)
    80005136:	6c42                	ld	s8,16(sp)
    80005138:	6ca2                	ld	s9,8(sp)
    8000513a:	6125                	addi	sp,sp,96
    8000513c:	8082                	ret
      iunlock(ip);
    8000513e:	854e                	mv	a0,s3
    80005140:	00000097          	auipc	ra,0x0
    80005144:	aa6080e7          	jalr	-1370(ra) # 80004be6 <iunlock>
      return ip;
    80005148:	bfe9                	j	80005122 <namex+0x6a>
      iunlockput(ip);
    8000514a:	854e                	mv	a0,s3
    8000514c:	00000097          	auipc	ra,0x0
    80005150:	c3a080e7          	jalr	-966(ra) # 80004d86 <iunlockput>
      return 0;
    80005154:	89d2                	mv	s3,s4
    80005156:	b7f1                	j	80005122 <namex+0x6a>
  len = path - s;
    80005158:	40b48633          	sub	a2,s1,a1
    8000515c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80005160:	094cd463          	bge	s9,s4,800051e8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80005164:	4639                	li	a2,14
    80005166:	8556                	mv	a0,s5
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	bd8080e7          	jalr	-1064(ra) # 80000d40 <memmove>
  while(*path == '/')
    80005170:	0004c783          	lbu	a5,0(s1)
    80005174:	01279763          	bne	a5,s2,80005182 <namex+0xca>
    path++;
    80005178:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000517a:	0004c783          	lbu	a5,0(s1)
    8000517e:	ff278de3          	beq	a5,s2,80005178 <namex+0xc0>
    ilock(ip);
    80005182:	854e                	mv	a0,s3
    80005184:	00000097          	auipc	ra,0x0
    80005188:	9a0080e7          	jalr	-1632(ra) # 80004b24 <ilock>
    if(ip->type != T_DIR){
    8000518c:	04499783          	lh	a5,68(s3)
    80005190:	f98793e3          	bne	a5,s8,80005116 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80005194:	000b0563          	beqz	s6,8000519e <namex+0xe6>
    80005198:	0004c783          	lbu	a5,0(s1)
    8000519c:	d3cd                	beqz	a5,8000513e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000519e:	865e                	mv	a2,s7
    800051a0:	85d6                	mv	a1,s5
    800051a2:	854e                	mv	a0,s3
    800051a4:	00000097          	auipc	ra,0x0
    800051a8:	e64080e7          	jalr	-412(ra) # 80005008 <dirlookup>
    800051ac:	8a2a                	mv	s4,a0
    800051ae:	dd51                	beqz	a0,8000514a <namex+0x92>
    iunlockput(ip);
    800051b0:	854e                	mv	a0,s3
    800051b2:	00000097          	auipc	ra,0x0
    800051b6:	bd4080e7          	jalr	-1068(ra) # 80004d86 <iunlockput>
    ip = next;
    800051ba:	89d2                	mv	s3,s4
  while(*path == '/')
    800051bc:	0004c783          	lbu	a5,0(s1)
    800051c0:	05279763          	bne	a5,s2,8000520e <namex+0x156>
    path++;
    800051c4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800051c6:	0004c783          	lbu	a5,0(s1)
    800051ca:	ff278de3          	beq	a5,s2,800051c4 <namex+0x10c>
  if(*path == 0)
    800051ce:	c79d                	beqz	a5,800051fc <namex+0x144>
    path++;
    800051d0:	85a6                	mv	a1,s1
  len = path - s;
    800051d2:	8a5e                	mv	s4,s7
    800051d4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800051d6:	01278963          	beq	a5,s2,800051e8 <namex+0x130>
    800051da:	dfbd                	beqz	a5,80005158 <namex+0xa0>
    path++;
    800051dc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800051de:	0004c783          	lbu	a5,0(s1)
    800051e2:	ff279ce3          	bne	a5,s2,800051da <namex+0x122>
    800051e6:	bf8d                	j	80005158 <namex+0xa0>
    memmove(name, s, len);
    800051e8:	2601                	sext.w	a2,a2
    800051ea:	8556                	mv	a0,s5
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	b54080e7          	jalr	-1196(ra) # 80000d40 <memmove>
    name[len] = 0;
    800051f4:	9a56                	add	s4,s4,s5
    800051f6:	000a0023          	sb	zero,0(s4)
    800051fa:	bf9d                	j	80005170 <namex+0xb8>
  if(nameiparent){
    800051fc:	f20b03e3          	beqz	s6,80005122 <namex+0x6a>
    iput(ip);
    80005200:	854e                	mv	a0,s3
    80005202:	00000097          	auipc	ra,0x0
    80005206:	adc080e7          	jalr	-1316(ra) # 80004cde <iput>
    return 0;
    8000520a:	4981                	li	s3,0
    8000520c:	bf19                	j	80005122 <namex+0x6a>
  if(*path == 0)
    8000520e:	d7fd                	beqz	a5,800051fc <namex+0x144>
  while(*path != '/' && *path != 0)
    80005210:	0004c783          	lbu	a5,0(s1)
    80005214:	85a6                	mv	a1,s1
    80005216:	b7d1                	j	800051da <namex+0x122>

0000000080005218 <dirlink>:
{
    80005218:	7139                	addi	sp,sp,-64
    8000521a:	fc06                	sd	ra,56(sp)
    8000521c:	f822                	sd	s0,48(sp)
    8000521e:	f426                	sd	s1,40(sp)
    80005220:	f04a                	sd	s2,32(sp)
    80005222:	ec4e                	sd	s3,24(sp)
    80005224:	e852                	sd	s4,16(sp)
    80005226:	0080                	addi	s0,sp,64
    80005228:	892a                	mv	s2,a0
    8000522a:	8a2e                	mv	s4,a1
    8000522c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000522e:	4601                	li	a2,0
    80005230:	00000097          	auipc	ra,0x0
    80005234:	dd8080e7          	jalr	-552(ra) # 80005008 <dirlookup>
    80005238:	e93d                	bnez	a0,800052ae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000523a:	04c92483          	lw	s1,76(s2)
    8000523e:	c49d                	beqz	s1,8000526c <dirlink+0x54>
    80005240:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005242:	4741                	li	a4,16
    80005244:	86a6                	mv	a3,s1
    80005246:	fc040613          	addi	a2,s0,-64
    8000524a:	4581                	li	a1,0
    8000524c:	854a                	mv	a0,s2
    8000524e:	00000097          	auipc	ra,0x0
    80005252:	b8a080e7          	jalr	-1142(ra) # 80004dd8 <readi>
    80005256:	47c1                	li	a5,16
    80005258:	06f51163          	bne	a0,a5,800052ba <dirlink+0xa2>
    if(de.inum == 0)
    8000525c:	fc045783          	lhu	a5,-64(s0)
    80005260:	c791                	beqz	a5,8000526c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005262:	24c1                	addiw	s1,s1,16
    80005264:	04c92783          	lw	a5,76(s2)
    80005268:	fcf4ede3          	bltu	s1,a5,80005242 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000526c:	4639                	li	a2,14
    8000526e:	85d2                	mv	a1,s4
    80005270:	fc240513          	addi	a0,s0,-62
    80005274:	ffffc097          	auipc	ra,0xffffc
    80005278:	b80080e7          	jalr	-1152(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000527c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005280:	4741                	li	a4,16
    80005282:	86a6                	mv	a3,s1
    80005284:	fc040613          	addi	a2,s0,-64
    80005288:	4581                	li	a1,0
    8000528a:	854a                	mv	a0,s2
    8000528c:	00000097          	auipc	ra,0x0
    80005290:	c44080e7          	jalr	-956(ra) # 80004ed0 <writei>
    80005294:	872a                	mv	a4,a0
    80005296:	47c1                	li	a5,16
  return 0;
    80005298:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000529a:	02f71863          	bne	a4,a5,800052ca <dirlink+0xb2>
}
    8000529e:	70e2                	ld	ra,56(sp)
    800052a0:	7442                	ld	s0,48(sp)
    800052a2:	74a2                	ld	s1,40(sp)
    800052a4:	7902                	ld	s2,32(sp)
    800052a6:	69e2                	ld	s3,24(sp)
    800052a8:	6a42                	ld	s4,16(sp)
    800052aa:	6121                	addi	sp,sp,64
    800052ac:	8082                	ret
    iput(ip);
    800052ae:	00000097          	auipc	ra,0x0
    800052b2:	a30080e7          	jalr	-1488(ra) # 80004cde <iput>
    return -1;
    800052b6:	557d                	li	a0,-1
    800052b8:	b7dd                	j	8000529e <dirlink+0x86>
      panic("dirlink read");
    800052ba:	00004517          	auipc	a0,0x4
    800052be:	57650513          	addi	a0,a0,1398 # 80009830 <syscalls+0x1f0>
    800052c2:	ffffb097          	auipc	ra,0xffffb
    800052c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
    panic("dirlink");
    800052ca:	00004517          	auipc	a0,0x4
    800052ce:	67650513          	addi	a0,a0,1654 # 80009940 <syscalls+0x300>
    800052d2:	ffffb097          	auipc	ra,0xffffb
    800052d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>

00000000800052da <namei>:

struct inode*
namei(char *path)
{
    800052da:	1101                	addi	sp,sp,-32
    800052dc:	ec06                	sd	ra,24(sp)
    800052de:	e822                	sd	s0,16(sp)
    800052e0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800052e2:	fe040613          	addi	a2,s0,-32
    800052e6:	4581                	li	a1,0
    800052e8:	00000097          	auipc	ra,0x0
    800052ec:	dd0080e7          	jalr	-560(ra) # 800050b8 <namex>
}
    800052f0:	60e2                	ld	ra,24(sp)
    800052f2:	6442                	ld	s0,16(sp)
    800052f4:	6105                	addi	sp,sp,32
    800052f6:	8082                	ret

00000000800052f8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800052f8:	1141                	addi	sp,sp,-16
    800052fa:	e406                	sd	ra,8(sp)
    800052fc:	e022                	sd	s0,0(sp)
    800052fe:	0800                	addi	s0,sp,16
    80005300:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80005302:	4585                	li	a1,1
    80005304:	00000097          	auipc	ra,0x0
    80005308:	db4080e7          	jalr	-588(ra) # 800050b8 <namex>
}
    8000530c:	60a2                	ld	ra,8(sp)
    8000530e:	6402                	ld	s0,0(sp)
    80005310:	0141                	addi	sp,sp,16
    80005312:	8082                	ret

0000000080005314 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80005314:	1101                	addi	sp,sp,-32
    80005316:	ec06                	sd	ra,24(sp)
    80005318:	e822                	sd	s0,16(sp)
    8000531a:	e426                	sd	s1,8(sp)
    8000531c:	e04a                	sd	s2,0(sp)
    8000531e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80005320:	0001e917          	auipc	s2,0x1e
    80005324:	bf090913          	addi	s2,s2,-1040 # 80022f10 <log>
    80005328:	01892583          	lw	a1,24(s2)
    8000532c:	02892503          	lw	a0,40(s2)
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	ff2080e7          	jalr	-14(ra) # 80004322 <bread>
    80005338:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000533a:	02c92683          	lw	a3,44(s2)
    8000533e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80005340:	02d05763          	blez	a3,8000536e <write_head+0x5a>
    80005344:	0001e797          	auipc	a5,0x1e
    80005348:	bfc78793          	addi	a5,a5,-1028 # 80022f40 <log+0x30>
    8000534c:	05c50713          	addi	a4,a0,92
    80005350:	36fd                	addiw	a3,a3,-1
    80005352:	1682                	slli	a3,a3,0x20
    80005354:	9281                	srli	a3,a3,0x20
    80005356:	068a                	slli	a3,a3,0x2
    80005358:	0001e617          	auipc	a2,0x1e
    8000535c:	bec60613          	addi	a2,a2,-1044 # 80022f44 <log+0x34>
    80005360:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80005362:	4390                	lw	a2,0(a5)
    80005364:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80005366:	0791                	addi	a5,a5,4
    80005368:	0711                	addi	a4,a4,4
    8000536a:	fed79ce3          	bne	a5,a3,80005362 <write_head+0x4e>
  }
  bwrite(buf);
    8000536e:	8526                	mv	a0,s1
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	0a4080e7          	jalr	164(ra) # 80004414 <bwrite>
  brelse(buf);
    80005378:	8526                	mv	a0,s1
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	0d8080e7          	jalr	216(ra) # 80004452 <brelse>
}
    80005382:	60e2                	ld	ra,24(sp)
    80005384:	6442                	ld	s0,16(sp)
    80005386:	64a2                	ld	s1,8(sp)
    80005388:	6902                	ld	s2,0(sp)
    8000538a:	6105                	addi	sp,sp,32
    8000538c:	8082                	ret

000000008000538e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000538e:	0001e797          	auipc	a5,0x1e
    80005392:	bae7a783          	lw	a5,-1106(a5) # 80022f3c <log+0x2c>
    80005396:	0af05d63          	blez	a5,80005450 <install_trans+0xc2>
{
    8000539a:	7139                	addi	sp,sp,-64
    8000539c:	fc06                	sd	ra,56(sp)
    8000539e:	f822                	sd	s0,48(sp)
    800053a0:	f426                	sd	s1,40(sp)
    800053a2:	f04a                	sd	s2,32(sp)
    800053a4:	ec4e                	sd	s3,24(sp)
    800053a6:	e852                	sd	s4,16(sp)
    800053a8:	e456                	sd	s5,8(sp)
    800053aa:	e05a                	sd	s6,0(sp)
    800053ac:	0080                	addi	s0,sp,64
    800053ae:	8b2a                	mv	s6,a0
    800053b0:	0001ea97          	auipc	s5,0x1e
    800053b4:	b90a8a93          	addi	s5,s5,-1136 # 80022f40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800053b8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800053ba:	0001e997          	auipc	s3,0x1e
    800053be:	b5698993          	addi	s3,s3,-1194 # 80022f10 <log>
    800053c2:	a035                	j	800053ee <install_trans+0x60>
      bunpin(dbuf);
    800053c4:	8526                	mv	a0,s1
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	166080e7          	jalr	358(ra) # 8000452c <bunpin>
    brelse(lbuf);
    800053ce:	854a                	mv	a0,s2
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	082080e7          	jalr	130(ra) # 80004452 <brelse>
    brelse(dbuf);
    800053d8:	8526                	mv	a0,s1
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	078080e7          	jalr	120(ra) # 80004452 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800053e2:	2a05                	addiw	s4,s4,1
    800053e4:	0a91                	addi	s5,s5,4
    800053e6:	02c9a783          	lw	a5,44(s3)
    800053ea:	04fa5963          	bge	s4,a5,8000543c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800053ee:	0189a583          	lw	a1,24(s3)
    800053f2:	014585bb          	addw	a1,a1,s4
    800053f6:	2585                	addiw	a1,a1,1
    800053f8:	0289a503          	lw	a0,40(s3)
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	f26080e7          	jalr	-218(ra) # 80004322 <bread>
    80005404:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80005406:	000aa583          	lw	a1,0(s5)
    8000540a:	0289a503          	lw	a0,40(s3)
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	f14080e7          	jalr	-236(ra) # 80004322 <bread>
    80005416:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80005418:	40000613          	li	a2,1024
    8000541c:	05890593          	addi	a1,s2,88
    80005420:	05850513          	addi	a0,a0,88
    80005424:	ffffc097          	auipc	ra,0xffffc
    80005428:	91c080e7          	jalr	-1764(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000542c:	8526                	mv	a0,s1
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	fe6080e7          	jalr	-26(ra) # 80004414 <bwrite>
    if(recovering == 0)
    80005436:	f80b1ce3          	bnez	s6,800053ce <install_trans+0x40>
    8000543a:	b769                	j	800053c4 <install_trans+0x36>
}
    8000543c:	70e2                	ld	ra,56(sp)
    8000543e:	7442                	ld	s0,48(sp)
    80005440:	74a2                	ld	s1,40(sp)
    80005442:	7902                	ld	s2,32(sp)
    80005444:	69e2                	ld	s3,24(sp)
    80005446:	6a42                	ld	s4,16(sp)
    80005448:	6aa2                	ld	s5,8(sp)
    8000544a:	6b02                	ld	s6,0(sp)
    8000544c:	6121                	addi	sp,sp,64
    8000544e:	8082                	ret
    80005450:	8082                	ret

0000000080005452 <initlog>:
{
    80005452:	7179                	addi	sp,sp,-48
    80005454:	f406                	sd	ra,40(sp)
    80005456:	f022                	sd	s0,32(sp)
    80005458:	ec26                	sd	s1,24(sp)
    8000545a:	e84a                	sd	s2,16(sp)
    8000545c:	e44e                	sd	s3,8(sp)
    8000545e:	1800                	addi	s0,sp,48
    80005460:	892a                	mv	s2,a0
    80005462:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80005464:	0001e497          	auipc	s1,0x1e
    80005468:	aac48493          	addi	s1,s1,-1364 # 80022f10 <log>
    8000546c:	00004597          	auipc	a1,0x4
    80005470:	3d458593          	addi	a1,a1,980 # 80009840 <syscalls+0x200>
    80005474:	8526                	mv	a0,s1
    80005476:	ffffb097          	auipc	ra,0xffffb
    8000547a:	6de080e7          	jalr	1758(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000547e:	0149a583          	lw	a1,20(s3)
    80005482:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80005484:	0109a783          	lw	a5,16(s3)
    80005488:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000548a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000548e:	854a                	mv	a0,s2
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	e92080e7          	jalr	-366(ra) # 80004322 <bread>
  log.lh.n = lh->n;
    80005498:	4d3c                	lw	a5,88(a0)
    8000549a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000549c:	02f05563          	blez	a5,800054c6 <initlog+0x74>
    800054a0:	05c50713          	addi	a4,a0,92
    800054a4:	0001e697          	auipc	a3,0x1e
    800054a8:	a9c68693          	addi	a3,a3,-1380 # 80022f40 <log+0x30>
    800054ac:	37fd                	addiw	a5,a5,-1
    800054ae:	1782                	slli	a5,a5,0x20
    800054b0:	9381                	srli	a5,a5,0x20
    800054b2:	078a                	slli	a5,a5,0x2
    800054b4:	06050613          	addi	a2,a0,96
    800054b8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800054ba:	4310                	lw	a2,0(a4)
    800054bc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800054be:	0711                	addi	a4,a4,4
    800054c0:	0691                	addi	a3,a3,4
    800054c2:	fef71ce3          	bne	a4,a5,800054ba <initlog+0x68>
  brelse(buf);
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	f8c080e7          	jalr	-116(ra) # 80004452 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800054ce:	4505                	li	a0,1
    800054d0:	00000097          	auipc	ra,0x0
    800054d4:	ebe080e7          	jalr	-322(ra) # 8000538e <install_trans>
  log.lh.n = 0;
    800054d8:	0001e797          	auipc	a5,0x1e
    800054dc:	a607a223          	sw	zero,-1436(a5) # 80022f3c <log+0x2c>
  write_head(); // clear the log
    800054e0:	00000097          	auipc	ra,0x0
    800054e4:	e34080e7          	jalr	-460(ra) # 80005314 <write_head>
}
    800054e8:	70a2                	ld	ra,40(sp)
    800054ea:	7402                	ld	s0,32(sp)
    800054ec:	64e2                	ld	s1,24(sp)
    800054ee:	6942                	ld	s2,16(sp)
    800054f0:	69a2                	ld	s3,8(sp)
    800054f2:	6145                	addi	sp,sp,48
    800054f4:	8082                	ret

00000000800054f6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800054f6:	1101                	addi	sp,sp,-32
    800054f8:	ec06                	sd	ra,24(sp)
    800054fa:	e822                	sd	s0,16(sp)
    800054fc:	e426                	sd	s1,8(sp)
    800054fe:	e04a                	sd	s2,0(sp)
    80005500:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80005502:	0001e517          	auipc	a0,0x1e
    80005506:	a0e50513          	addi	a0,a0,-1522 # 80022f10 <log>
    8000550a:	ffffb097          	auipc	ra,0xffffb
    8000550e:	6da080e7          	jalr	1754(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80005512:	0001e497          	auipc	s1,0x1e
    80005516:	9fe48493          	addi	s1,s1,-1538 # 80022f10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000551a:	4979                	li	s2,30
    8000551c:	a039                	j	8000552a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000551e:	85a6                	mv	a1,s1
    80005520:	8526                	mv	a0,s1
    80005522:	ffffd097          	auipc	ra,0xffffd
    80005526:	6fe080e7          	jalr	1790(ra) # 80002c20 <sleep>
    if(log.committing){
    8000552a:	50dc                	lw	a5,36(s1)
    8000552c:	fbed                	bnez	a5,8000551e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000552e:	509c                	lw	a5,32(s1)
    80005530:	0017871b          	addiw	a4,a5,1
    80005534:	0007069b          	sext.w	a3,a4
    80005538:	0027179b          	slliw	a5,a4,0x2
    8000553c:	9fb9                	addw	a5,a5,a4
    8000553e:	0017979b          	slliw	a5,a5,0x1
    80005542:	54d8                	lw	a4,44(s1)
    80005544:	9fb9                	addw	a5,a5,a4
    80005546:	00f95963          	bge	s2,a5,80005558 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000554a:	85a6                	mv	a1,s1
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	6d2080e7          	jalr	1746(ra) # 80002c20 <sleep>
    80005556:	bfd1                	j	8000552a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80005558:	0001e517          	auipc	a0,0x1e
    8000555c:	9b850513          	addi	a0,a0,-1608 # 80022f10 <log>
    80005560:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80005562:	ffffb097          	auipc	ra,0xffffb
    80005566:	736080e7          	jalr	1846(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000556a:	60e2                	ld	ra,24(sp)
    8000556c:	6442                	ld	s0,16(sp)
    8000556e:	64a2                	ld	s1,8(sp)
    80005570:	6902                	ld	s2,0(sp)
    80005572:	6105                	addi	sp,sp,32
    80005574:	8082                	ret

0000000080005576 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005576:	7139                	addi	sp,sp,-64
    80005578:	fc06                	sd	ra,56(sp)
    8000557a:	f822                	sd	s0,48(sp)
    8000557c:	f426                	sd	s1,40(sp)
    8000557e:	f04a                	sd	s2,32(sp)
    80005580:	ec4e                	sd	s3,24(sp)
    80005582:	e852                	sd	s4,16(sp)
    80005584:	e456                	sd	s5,8(sp)
    80005586:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80005588:	0001e497          	auipc	s1,0x1e
    8000558c:	98848493          	addi	s1,s1,-1656 # 80022f10 <log>
    80005590:	8526                	mv	a0,s1
    80005592:	ffffb097          	auipc	ra,0xffffb
    80005596:	652080e7          	jalr	1618(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000559a:	509c                	lw	a5,32(s1)
    8000559c:	37fd                	addiw	a5,a5,-1
    8000559e:	0007891b          	sext.w	s2,a5
    800055a2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800055a4:	50dc                	lw	a5,36(s1)
    800055a6:	efb9                	bnez	a5,80005604 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800055a8:	06091663          	bnez	s2,80005614 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800055ac:	0001e497          	auipc	s1,0x1e
    800055b0:	96448493          	addi	s1,s1,-1692 # 80022f10 <log>
    800055b4:	4785                	li	a5,1
    800055b6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffb097          	auipc	ra,0xffffb
    800055be:	6de080e7          	jalr	1758(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800055c2:	54dc                	lw	a5,44(s1)
    800055c4:	06f04763          	bgtz	a5,80005632 <end_op+0xbc>
    acquire(&log.lock);
    800055c8:	0001e497          	auipc	s1,0x1e
    800055cc:	94848493          	addi	s1,s1,-1720 # 80022f10 <log>
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffb097          	auipc	ra,0xffffb
    800055d6:	612080e7          	jalr	1554(ra) # 80000be4 <acquire>
    log.committing = 0;
    800055da:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	9a6080e7          	jalr	-1626(ra) # 80002f86 <wakeup>
    release(&log.lock);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffb097          	auipc	ra,0xffffb
    800055ee:	6ae080e7          	jalr	1710(ra) # 80000c98 <release>
}
    800055f2:	70e2                	ld	ra,56(sp)
    800055f4:	7442                	ld	s0,48(sp)
    800055f6:	74a2                	ld	s1,40(sp)
    800055f8:	7902                	ld	s2,32(sp)
    800055fa:	69e2                	ld	s3,24(sp)
    800055fc:	6a42                	ld	s4,16(sp)
    800055fe:	6aa2                	ld	s5,8(sp)
    80005600:	6121                	addi	sp,sp,64
    80005602:	8082                	ret
    panic("log.committing");
    80005604:	00004517          	auipc	a0,0x4
    80005608:	24450513          	addi	a0,a0,580 # 80009848 <syscalls+0x208>
    8000560c:	ffffb097          	auipc	ra,0xffffb
    80005610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>
    wakeup(&log);
    80005614:	0001e497          	auipc	s1,0x1e
    80005618:	8fc48493          	addi	s1,s1,-1796 # 80022f10 <log>
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	968080e7          	jalr	-1688(ra) # 80002f86 <wakeup>
  release(&log.lock);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffb097          	auipc	ra,0xffffb
    8000562c:	670080e7          	jalr	1648(ra) # 80000c98 <release>
  if(do_commit){
    80005630:	b7c9                	j	800055f2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005632:	0001ea97          	auipc	s5,0x1e
    80005636:	90ea8a93          	addi	s5,s5,-1778 # 80022f40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000563a:	0001ea17          	auipc	s4,0x1e
    8000563e:	8d6a0a13          	addi	s4,s4,-1834 # 80022f10 <log>
    80005642:	018a2583          	lw	a1,24(s4)
    80005646:	012585bb          	addw	a1,a1,s2
    8000564a:	2585                	addiw	a1,a1,1
    8000564c:	028a2503          	lw	a0,40(s4)
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	cd2080e7          	jalr	-814(ra) # 80004322 <bread>
    80005658:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000565a:	000aa583          	lw	a1,0(s5)
    8000565e:	028a2503          	lw	a0,40(s4)
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	cc0080e7          	jalr	-832(ra) # 80004322 <bread>
    8000566a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000566c:	40000613          	li	a2,1024
    80005670:	05850593          	addi	a1,a0,88
    80005674:	05848513          	addi	a0,s1,88
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	6c8080e7          	jalr	1736(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80005680:	8526                	mv	a0,s1
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	d92080e7          	jalr	-622(ra) # 80004414 <bwrite>
    brelse(from);
    8000568a:	854e                	mv	a0,s3
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	dc6080e7          	jalr	-570(ra) # 80004452 <brelse>
    brelse(to);
    80005694:	8526                	mv	a0,s1
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	dbc080e7          	jalr	-580(ra) # 80004452 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000569e:	2905                	addiw	s2,s2,1
    800056a0:	0a91                	addi	s5,s5,4
    800056a2:	02ca2783          	lw	a5,44(s4)
    800056a6:	f8f94ee3          	blt	s2,a5,80005642 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800056aa:	00000097          	auipc	ra,0x0
    800056ae:	c6a080e7          	jalr	-918(ra) # 80005314 <write_head>
    install_trans(0); // Now install writes to home locations
    800056b2:	4501                	li	a0,0
    800056b4:	00000097          	auipc	ra,0x0
    800056b8:	cda080e7          	jalr	-806(ra) # 8000538e <install_trans>
    log.lh.n = 0;
    800056bc:	0001e797          	auipc	a5,0x1e
    800056c0:	8807a023          	sw	zero,-1920(a5) # 80022f3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800056c4:	00000097          	auipc	ra,0x0
    800056c8:	c50080e7          	jalr	-944(ra) # 80005314 <write_head>
    800056cc:	bdf5                	j	800055c8 <end_op+0x52>

00000000800056ce <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800056ce:	1101                	addi	sp,sp,-32
    800056d0:	ec06                	sd	ra,24(sp)
    800056d2:	e822                	sd	s0,16(sp)
    800056d4:	e426                	sd	s1,8(sp)
    800056d6:	e04a                	sd	s2,0(sp)
    800056d8:	1000                	addi	s0,sp,32
    800056da:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800056dc:	0001e917          	auipc	s2,0x1e
    800056e0:	83490913          	addi	s2,s2,-1996 # 80022f10 <log>
    800056e4:	854a                	mv	a0,s2
    800056e6:	ffffb097          	auipc	ra,0xffffb
    800056ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800056ee:	02c92603          	lw	a2,44(s2)
    800056f2:	47f5                	li	a5,29
    800056f4:	06c7c563          	blt	a5,a2,8000575e <log_write+0x90>
    800056f8:	0001e797          	auipc	a5,0x1e
    800056fc:	8347a783          	lw	a5,-1996(a5) # 80022f2c <log+0x1c>
    80005700:	37fd                	addiw	a5,a5,-1
    80005702:	04f65e63          	bge	a2,a5,8000575e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005706:	0001e797          	auipc	a5,0x1e
    8000570a:	82a7a783          	lw	a5,-2006(a5) # 80022f30 <log+0x20>
    8000570e:	06f05063          	blez	a5,8000576e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80005712:	4781                	li	a5,0
    80005714:	06c05563          	blez	a2,8000577e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005718:	44cc                	lw	a1,12(s1)
    8000571a:	0001e717          	auipc	a4,0x1e
    8000571e:	82670713          	addi	a4,a4,-2010 # 80022f40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80005722:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005724:	4314                	lw	a3,0(a4)
    80005726:	04b68c63          	beq	a3,a1,8000577e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000572a:	2785                	addiw	a5,a5,1
    8000572c:	0711                	addi	a4,a4,4
    8000572e:	fef61be3          	bne	a2,a5,80005724 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80005732:	0621                	addi	a2,a2,8
    80005734:	060a                	slli	a2,a2,0x2
    80005736:	0001d797          	auipc	a5,0x1d
    8000573a:	7da78793          	addi	a5,a5,2010 # 80022f10 <log>
    8000573e:	963e                	add	a2,a2,a5
    80005740:	44dc                	lw	a5,12(s1)
    80005742:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005744:	8526                	mv	a0,s1
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	daa080e7          	jalr	-598(ra) # 800044f0 <bpin>
    log.lh.n++;
    8000574e:	0001d717          	auipc	a4,0x1d
    80005752:	7c270713          	addi	a4,a4,1986 # 80022f10 <log>
    80005756:	575c                	lw	a5,44(a4)
    80005758:	2785                	addiw	a5,a5,1
    8000575a:	d75c                	sw	a5,44(a4)
    8000575c:	a835                	j	80005798 <log_write+0xca>
    panic("too big a transaction");
    8000575e:	00004517          	auipc	a0,0x4
    80005762:	0fa50513          	addi	a0,a0,250 # 80009858 <syscalls+0x218>
    80005766:	ffffb097          	auipc	ra,0xffffb
    8000576a:	dd8080e7          	jalr	-552(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000576e:	00004517          	auipc	a0,0x4
    80005772:	10250513          	addi	a0,a0,258 # 80009870 <syscalls+0x230>
    80005776:	ffffb097          	auipc	ra,0xffffb
    8000577a:	dc8080e7          	jalr	-568(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000577e:	00878713          	addi	a4,a5,8
    80005782:	00271693          	slli	a3,a4,0x2
    80005786:	0001d717          	auipc	a4,0x1d
    8000578a:	78a70713          	addi	a4,a4,1930 # 80022f10 <log>
    8000578e:	9736                	add	a4,a4,a3
    80005790:	44d4                	lw	a3,12(s1)
    80005792:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005794:	faf608e3          	beq	a2,a5,80005744 <log_write+0x76>
  }
  release(&log.lock);
    80005798:	0001d517          	auipc	a0,0x1d
    8000579c:	77850513          	addi	a0,a0,1912 # 80022f10 <log>
    800057a0:	ffffb097          	auipc	ra,0xffffb
    800057a4:	4f8080e7          	jalr	1272(ra) # 80000c98 <release>
}
    800057a8:	60e2                	ld	ra,24(sp)
    800057aa:	6442                	ld	s0,16(sp)
    800057ac:	64a2                	ld	s1,8(sp)
    800057ae:	6902                	ld	s2,0(sp)
    800057b0:	6105                	addi	sp,sp,32
    800057b2:	8082                	ret

00000000800057b4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800057b4:	1101                	addi	sp,sp,-32
    800057b6:	ec06                	sd	ra,24(sp)
    800057b8:	e822                	sd	s0,16(sp)
    800057ba:	e426                	sd	s1,8(sp)
    800057bc:	e04a                	sd	s2,0(sp)
    800057be:	1000                	addi	s0,sp,32
    800057c0:	84aa                	mv	s1,a0
    800057c2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800057c4:	00004597          	auipc	a1,0x4
    800057c8:	0cc58593          	addi	a1,a1,204 # 80009890 <syscalls+0x250>
    800057cc:	0521                	addi	a0,a0,8
    800057ce:	ffffb097          	auipc	ra,0xffffb
    800057d2:	386080e7          	jalr	902(ra) # 80000b54 <initlock>
  lk->name = name;
    800057d6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800057da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800057de:	0204a423          	sw	zero,40(s1)
}
    800057e2:	60e2                	ld	ra,24(sp)
    800057e4:	6442                	ld	s0,16(sp)
    800057e6:	64a2                	ld	s1,8(sp)
    800057e8:	6902                	ld	s2,0(sp)
    800057ea:	6105                	addi	sp,sp,32
    800057ec:	8082                	ret

00000000800057ee <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800057ee:	1101                	addi	sp,sp,-32
    800057f0:	ec06                	sd	ra,24(sp)
    800057f2:	e822                	sd	s0,16(sp)
    800057f4:	e426                	sd	s1,8(sp)
    800057f6:	e04a                	sd	s2,0(sp)
    800057f8:	1000                	addi	s0,sp,32
    800057fa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800057fc:	00850913          	addi	s2,a0,8
    80005800:	854a                	mv	a0,s2
    80005802:	ffffb097          	auipc	ra,0xffffb
    80005806:	3e2080e7          	jalr	994(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000580a:	409c                	lw	a5,0(s1)
    8000580c:	cb89                	beqz	a5,8000581e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000580e:	85ca                	mv	a1,s2
    80005810:	8526                	mv	a0,s1
    80005812:	ffffd097          	auipc	ra,0xffffd
    80005816:	40e080e7          	jalr	1038(ra) # 80002c20 <sleep>
  while (lk->locked) {
    8000581a:	409c                	lw	a5,0(s1)
    8000581c:	fbed                	bnez	a5,8000580e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000581e:	4785                	li	a5,1
    80005820:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005822:	ffffc097          	auipc	ra,0xffffc
    80005826:	3de080e7          	jalr	990(ra) # 80001c00 <myproc>
    8000582a:	591c                	lw	a5,48(a0)
    8000582c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000582e:	854a                	mv	a0,s2
    80005830:	ffffb097          	auipc	ra,0xffffb
    80005834:	468080e7          	jalr	1128(ra) # 80000c98 <release>
}
    80005838:	60e2                	ld	ra,24(sp)
    8000583a:	6442                	ld	s0,16(sp)
    8000583c:	64a2                	ld	s1,8(sp)
    8000583e:	6902                	ld	s2,0(sp)
    80005840:	6105                	addi	sp,sp,32
    80005842:	8082                	ret

0000000080005844 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005844:	1101                	addi	sp,sp,-32
    80005846:	ec06                	sd	ra,24(sp)
    80005848:	e822                	sd	s0,16(sp)
    8000584a:	e426                	sd	s1,8(sp)
    8000584c:	e04a                	sd	s2,0(sp)
    8000584e:	1000                	addi	s0,sp,32
    80005850:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005852:	00850913          	addi	s2,a0,8
    80005856:	854a                	mv	a0,s2
    80005858:	ffffb097          	auipc	ra,0xffffb
    8000585c:	38c080e7          	jalr	908(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80005860:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005864:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffd097          	auipc	ra,0xffffd
    8000586e:	71c080e7          	jalr	1820(ra) # 80002f86 <wakeup>
  release(&lk->lk);
    80005872:	854a                	mv	a0,s2
    80005874:	ffffb097          	auipc	ra,0xffffb
    80005878:	424080e7          	jalr	1060(ra) # 80000c98 <release>
}
    8000587c:	60e2                	ld	ra,24(sp)
    8000587e:	6442                	ld	s0,16(sp)
    80005880:	64a2                	ld	s1,8(sp)
    80005882:	6902                	ld	s2,0(sp)
    80005884:	6105                	addi	sp,sp,32
    80005886:	8082                	ret

0000000080005888 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005888:	7179                	addi	sp,sp,-48
    8000588a:	f406                	sd	ra,40(sp)
    8000588c:	f022                	sd	s0,32(sp)
    8000588e:	ec26                	sd	s1,24(sp)
    80005890:	e84a                	sd	s2,16(sp)
    80005892:	e44e                	sd	s3,8(sp)
    80005894:	1800                	addi	s0,sp,48
    80005896:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005898:	00850913          	addi	s2,a0,8
    8000589c:	854a                	mv	a0,s2
    8000589e:	ffffb097          	auipc	ra,0xffffb
    800058a2:	346080e7          	jalr	838(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800058a6:	409c                	lw	a5,0(s1)
    800058a8:	ef99                	bnez	a5,800058c6 <holdingsleep+0x3e>
    800058aa:	4481                	li	s1,0
  release(&lk->lk);
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffb097          	auipc	ra,0xffffb
    800058b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
  return r;
}
    800058b6:	8526                	mv	a0,s1
    800058b8:	70a2                	ld	ra,40(sp)
    800058ba:	7402                	ld	s0,32(sp)
    800058bc:	64e2                	ld	s1,24(sp)
    800058be:	6942                	ld	s2,16(sp)
    800058c0:	69a2                	ld	s3,8(sp)
    800058c2:	6145                	addi	sp,sp,48
    800058c4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800058c6:	0284a983          	lw	s3,40(s1)
    800058ca:	ffffc097          	auipc	ra,0xffffc
    800058ce:	336080e7          	jalr	822(ra) # 80001c00 <myproc>
    800058d2:	5904                	lw	s1,48(a0)
    800058d4:	413484b3          	sub	s1,s1,s3
    800058d8:	0014b493          	seqz	s1,s1
    800058dc:	bfc1                	j	800058ac <holdingsleep+0x24>

00000000800058de <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800058de:	1141                	addi	sp,sp,-16
    800058e0:	e406                	sd	ra,8(sp)
    800058e2:	e022                	sd	s0,0(sp)
    800058e4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800058e6:	00004597          	auipc	a1,0x4
    800058ea:	fba58593          	addi	a1,a1,-70 # 800098a0 <syscalls+0x260>
    800058ee:	0001d517          	auipc	a0,0x1d
    800058f2:	76a50513          	addi	a0,a0,1898 # 80023058 <ftable>
    800058f6:	ffffb097          	auipc	ra,0xffffb
    800058fa:	25e080e7          	jalr	606(ra) # 80000b54 <initlock>
}
    800058fe:	60a2                	ld	ra,8(sp)
    80005900:	6402                	ld	s0,0(sp)
    80005902:	0141                	addi	sp,sp,16
    80005904:	8082                	ret

0000000080005906 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005906:	1101                	addi	sp,sp,-32
    80005908:	ec06                	sd	ra,24(sp)
    8000590a:	e822                	sd	s0,16(sp)
    8000590c:	e426                	sd	s1,8(sp)
    8000590e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005910:	0001d517          	auipc	a0,0x1d
    80005914:	74850513          	addi	a0,a0,1864 # 80023058 <ftable>
    80005918:	ffffb097          	auipc	ra,0xffffb
    8000591c:	2cc080e7          	jalr	716(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005920:	0001d497          	auipc	s1,0x1d
    80005924:	75048493          	addi	s1,s1,1872 # 80023070 <ftable+0x18>
    80005928:	0001e717          	auipc	a4,0x1e
    8000592c:	6e870713          	addi	a4,a4,1768 # 80024010 <ftable+0xfb8>
    if(f->ref == 0){
    80005930:	40dc                	lw	a5,4(s1)
    80005932:	cf99                	beqz	a5,80005950 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005934:	02848493          	addi	s1,s1,40
    80005938:	fee49ce3          	bne	s1,a4,80005930 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000593c:	0001d517          	auipc	a0,0x1d
    80005940:	71c50513          	addi	a0,a0,1820 # 80023058 <ftable>
    80005944:	ffffb097          	auipc	ra,0xffffb
    80005948:	354080e7          	jalr	852(ra) # 80000c98 <release>
  return 0;
    8000594c:	4481                	li	s1,0
    8000594e:	a819                	j	80005964 <filealloc+0x5e>
      f->ref = 1;
    80005950:	4785                	li	a5,1
    80005952:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005954:	0001d517          	auipc	a0,0x1d
    80005958:	70450513          	addi	a0,a0,1796 # 80023058 <ftable>
    8000595c:	ffffb097          	auipc	ra,0xffffb
    80005960:	33c080e7          	jalr	828(ra) # 80000c98 <release>
}
    80005964:	8526                	mv	a0,s1
    80005966:	60e2                	ld	ra,24(sp)
    80005968:	6442                	ld	s0,16(sp)
    8000596a:	64a2                	ld	s1,8(sp)
    8000596c:	6105                	addi	sp,sp,32
    8000596e:	8082                	ret

0000000080005970 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005970:	1101                	addi	sp,sp,-32
    80005972:	ec06                	sd	ra,24(sp)
    80005974:	e822                	sd	s0,16(sp)
    80005976:	e426                	sd	s1,8(sp)
    80005978:	1000                	addi	s0,sp,32
    8000597a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000597c:	0001d517          	auipc	a0,0x1d
    80005980:	6dc50513          	addi	a0,a0,1756 # 80023058 <ftable>
    80005984:	ffffb097          	auipc	ra,0xffffb
    80005988:	260080e7          	jalr	608(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000598c:	40dc                	lw	a5,4(s1)
    8000598e:	02f05263          	blez	a5,800059b2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005992:	2785                	addiw	a5,a5,1
    80005994:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005996:	0001d517          	auipc	a0,0x1d
    8000599a:	6c250513          	addi	a0,a0,1730 # 80023058 <ftable>
    8000599e:	ffffb097          	auipc	ra,0xffffb
    800059a2:	2fa080e7          	jalr	762(ra) # 80000c98 <release>
  return f;
}
    800059a6:	8526                	mv	a0,s1
    800059a8:	60e2                	ld	ra,24(sp)
    800059aa:	6442                	ld	s0,16(sp)
    800059ac:	64a2                	ld	s1,8(sp)
    800059ae:	6105                	addi	sp,sp,32
    800059b0:	8082                	ret
    panic("filedup");
    800059b2:	00004517          	auipc	a0,0x4
    800059b6:	ef650513          	addi	a0,a0,-266 # 800098a8 <syscalls+0x268>
    800059ba:	ffffb097          	auipc	ra,0xffffb
    800059be:	b84080e7          	jalr	-1148(ra) # 8000053e <panic>

00000000800059c2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800059c2:	7139                	addi	sp,sp,-64
    800059c4:	fc06                	sd	ra,56(sp)
    800059c6:	f822                	sd	s0,48(sp)
    800059c8:	f426                	sd	s1,40(sp)
    800059ca:	f04a                	sd	s2,32(sp)
    800059cc:	ec4e                	sd	s3,24(sp)
    800059ce:	e852                	sd	s4,16(sp)
    800059d0:	e456                	sd	s5,8(sp)
    800059d2:	0080                	addi	s0,sp,64
    800059d4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800059d6:	0001d517          	auipc	a0,0x1d
    800059da:	68250513          	addi	a0,a0,1666 # 80023058 <ftable>
    800059de:	ffffb097          	auipc	ra,0xffffb
    800059e2:	206080e7          	jalr	518(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800059e6:	40dc                	lw	a5,4(s1)
    800059e8:	06f05163          	blez	a5,80005a4a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800059ec:	37fd                	addiw	a5,a5,-1
    800059ee:	0007871b          	sext.w	a4,a5
    800059f2:	c0dc                	sw	a5,4(s1)
    800059f4:	06e04363          	bgtz	a4,80005a5a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800059f8:	0004a903          	lw	s2,0(s1)
    800059fc:	0094ca83          	lbu	s5,9(s1)
    80005a00:	0104ba03          	ld	s4,16(s1)
    80005a04:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005a08:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005a0c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005a10:	0001d517          	auipc	a0,0x1d
    80005a14:	64850513          	addi	a0,a0,1608 # 80023058 <ftable>
    80005a18:	ffffb097          	auipc	ra,0xffffb
    80005a1c:	280080e7          	jalr	640(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80005a20:	4785                	li	a5,1
    80005a22:	04f90d63          	beq	s2,a5,80005a7c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005a26:	3979                	addiw	s2,s2,-2
    80005a28:	4785                	li	a5,1
    80005a2a:	0527e063          	bltu	a5,s2,80005a6a <fileclose+0xa8>
    begin_op();
    80005a2e:	00000097          	auipc	ra,0x0
    80005a32:	ac8080e7          	jalr	-1336(ra) # 800054f6 <begin_op>
    iput(ff.ip);
    80005a36:	854e                	mv	a0,s3
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	2a6080e7          	jalr	678(ra) # 80004cde <iput>
    end_op();
    80005a40:	00000097          	auipc	ra,0x0
    80005a44:	b36080e7          	jalr	-1226(ra) # 80005576 <end_op>
    80005a48:	a00d                	j	80005a6a <fileclose+0xa8>
    panic("fileclose");
    80005a4a:	00004517          	auipc	a0,0x4
    80005a4e:	e6650513          	addi	a0,a0,-410 # 800098b0 <syscalls+0x270>
    80005a52:	ffffb097          	auipc	ra,0xffffb
    80005a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005a5a:	0001d517          	auipc	a0,0x1d
    80005a5e:	5fe50513          	addi	a0,a0,1534 # 80023058 <ftable>
    80005a62:	ffffb097          	auipc	ra,0xffffb
    80005a66:	236080e7          	jalr	566(ra) # 80000c98 <release>
  }
}
    80005a6a:	70e2                	ld	ra,56(sp)
    80005a6c:	7442                	ld	s0,48(sp)
    80005a6e:	74a2                	ld	s1,40(sp)
    80005a70:	7902                	ld	s2,32(sp)
    80005a72:	69e2                	ld	s3,24(sp)
    80005a74:	6a42                	ld	s4,16(sp)
    80005a76:	6aa2                	ld	s5,8(sp)
    80005a78:	6121                	addi	sp,sp,64
    80005a7a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005a7c:	85d6                	mv	a1,s5
    80005a7e:	8552                	mv	a0,s4
    80005a80:	00000097          	auipc	ra,0x0
    80005a84:	34c080e7          	jalr	844(ra) # 80005dcc <pipeclose>
    80005a88:	b7cd                	j	80005a6a <fileclose+0xa8>

0000000080005a8a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005a8a:	715d                	addi	sp,sp,-80
    80005a8c:	e486                	sd	ra,72(sp)
    80005a8e:	e0a2                	sd	s0,64(sp)
    80005a90:	fc26                	sd	s1,56(sp)
    80005a92:	f84a                	sd	s2,48(sp)
    80005a94:	f44e                	sd	s3,40(sp)
    80005a96:	0880                	addi	s0,sp,80
    80005a98:	84aa                	mv	s1,a0
    80005a9a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005a9c:	ffffc097          	auipc	ra,0xffffc
    80005aa0:	164080e7          	jalr	356(ra) # 80001c00 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005aa4:	409c                	lw	a5,0(s1)
    80005aa6:	37f9                	addiw	a5,a5,-2
    80005aa8:	4705                	li	a4,1
    80005aaa:	04f76763          	bltu	a4,a5,80005af8 <filestat+0x6e>
    80005aae:	892a                	mv	s2,a0
    ilock(f->ip);
    80005ab0:	6c88                	ld	a0,24(s1)
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	072080e7          	jalr	114(ra) # 80004b24 <ilock>
    stati(f->ip, &st);
    80005aba:	fb840593          	addi	a1,s0,-72
    80005abe:	6c88                	ld	a0,24(s1)
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	2ee080e7          	jalr	750(ra) # 80004dae <stati>
    iunlock(f->ip);
    80005ac8:	6c88                	ld	a0,24(s1)
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	11c080e7          	jalr	284(ra) # 80004be6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005ad2:	46e1                	li	a3,24
    80005ad4:	fb840613          	addi	a2,s0,-72
    80005ad8:	85ce                	mv	a1,s3
    80005ada:	08093503          	ld	a0,128(s2)
    80005ade:	ffffc097          	auipc	ra,0xffffc
    80005ae2:	b9c080e7          	jalr	-1124(ra) # 8000167a <copyout>
    80005ae6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005aea:	60a6                	ld	ra,72(sp)
    80005aec:	6406                	ld	s0,64(sp)
    80005aee:	74e2                	ld	s1,56(sp)
    80005af0:	7942                	ld	s2,48(sp)
    80005af2:	79a2                	ld	s3,40(sp)
    80005af4:	6161                	addi	sp,sp,80
    80005af6:	8082                	ret
  return -1;
    80005af8:	557d                	li	a0,-1
    80005afa:	bfc5                	j	80005aea <filestat+0x60>

0000000080005afc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005afc:	7179                	addi	sp,sp,-48
    80005afe:	f406                	sd	ra,40(sp)
    80005b00:	f022                	sd	s0,32(sp)
    80005b02:	ec26                	sd	s1,24(sp)
    80005b04:	e84a                	sd	s2,16(sp)
    80005b06:	e44e                	sd	s3,8(sp)
    80005b08:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005b0a:	00854783          	lbu	a5,8(a0)
    80005b0e:	c3d5                	beqz	a5,80005bb2 <fileread+0xb6>
    80005b10:	84aa                	mv	s1,a0
    80005b12:	89ae                	mv	s3,a1
    80005b14:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005b16:	411c                	lw	a5,0(a0)
    80005b18:	4705                	li	a4,1
    80005b1a:	04e78963          	beq	a5,a4,80005b6c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005b1e:	470d                	li	a4,3
    80005b20:	04e78d63          	beq	a5,a4,80005b7a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005b24:	4709                	li	a4,2
    80005b26:	06e79e63          	bne	a5,a4,80005ba2 <fileread+0xa6>
    ilock(f->ip);
    80005b2a:	6d08                	ld	a0,24(a0)
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	ff8080e7          	jalr	-8(ra) # 80004b24 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005b34:	874a                	mv	a4,s2
    80005b36:	5094                	lw	a3,32(s1)
    80005b38:	864e                	mv	a2,s3
    80005b3a:	4585                	li	a1,1
    80005b3c:	6c88                	ld	a0,24(s1)
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	29a080e7          	jalr	666(ra) # 80004dd8 <readi>
    80005b46:	892a                	mv	s2,a0
    80005b48:	00a05563          	blez	a0,80005b52 <fileread+0x56>
      f->off += r;
    80005b4c:	509c                	lw	a5,32(s1)
    80005b4e:	9fa9                	addw	a5,a5,a0
    80005b50:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005b52:	6c88                	ld	a0,24(s1)
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	092080e7          	jalr	146(ra) # 80004be6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005b5c:	854a                	mv	a0,s2
    80005b5e:	70a2                	ld	ra,40(sp)
    80005b60:	7402                	ld	s0,32(sp)
    80005b62:	64e2                	ld	s1,24(sp)
    80005b64:	6942                	ld	s2,16(sp)
    80005b66:	69a2                	ld	s3,8(sp)
    80005b68:	6145                	addi	sp,sp,48
    80005b6a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005b6c:	6908                	ld	a0,16(a0)
    80005b6e:	00000097          	auipc	ra,0x0
    80005b72:	3c8080e7          	jalr	968(ra) # 80005f36 <piperead>
    80005b76:	892a                	mv	s2,a0
    80005b78:	b7d5                	j	80005b5c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005b7a:	02451783          	lh	a5,36(a0)
    80005b7e:	03079693          	slli	a3,a5,0x30
    80005b82:	92c1                	srli	a3,a3,0x30
    80005b84:	4725                	li	a4,9
    80005b86:	02d76863          	bltu	a4,a3,80005bb6 <fileread+0xba>
    80005b8a:	0792                	slli	a5,a5,0x4
    80005b8c:	0001d717          	auipc	a4,0x1d
    80005b90:	42c70713          	addi	a4,a4,1068 # 80022fb8 <devsw>
    80005b94:	97ba                	add	a5,a5,a4
    80005b96:	639c                	ld	a5,0(a5)
    80005b98:	c38d                	beqz	a5,80005bba <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005b9a:	4505                	li	a0,1
    80005b9c:	9782                	jalr	a5
    80005b9e:	892a                	mv	s2,a0
    80005ba0:	bf75                	j	80005b5c <fileread+0x60>
    panic("fileread");
    80005ba2:	00004517          	auipc	a0,0x4
    80005ba6:	d1e50513          	addi	a0,a0,-738 # 800098c0 <syscalls+0x280>
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	994080e7          	jalr	-1644(ra) # 8000053e <panic>
    return -1;
    80005bb2:	597d                	li	s2,-1
    80005bb4:	b765                	j	80005b5c <fileread+0x60>
      return -1;
    80005bb6:	597d                	li	s2,-1
    80005bb8:	b755                	j	80005b5c <fileread+0x60>
    80005bba:	597d                	li	s2,-1
    80005bbc:	b745                	j	80005b5c <fileread+0x60>

0000000080005bbe <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005bbe:	715d                	addi	sp,sp,-80
    80005bc0:	e486                	sd	ra,72(sp)
    80005bc2:	e0a2                	sd	s0,64(sp)
    80005bc4:	fc26                	sd	s1,56(sp)
    80005bc6:	f84a                	sd	s2,48(sp)
    80005bc8:	f44e                	sd	s3,40(sp)
    80005bca:	f052                	sd	s4,32(sp)
    80005bcc:	ec56                	sd	s5,24(sp)
    80005bce:	e85a                	sd	s6,16(sp)
    80005bd0:	e45e                	sd	s7,8(sp)
    80005bd2:	e062                	sd	s8,0(sp)
    80005bd4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005bd6:	00954783          	lbu	a5,9(a0)
    80005bda:	10078663          	beqz	a5,80005ce6 <filewrite+0x128>
    80005bde:	892a                	mv	s2,a0
    80005be0:	8aae                	mv	s5,a1
    80005be2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005be4:	411c                	lw	a5,0(a0)
    80005be6:	4705                	li	a4,1
    80005be8:	02e78263          	beq	a5,a4,80005c0c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005bec:	470d                	li	a4,3
    80005bee:	02e78663          	beq	a5,a4,80005c1a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005bf2:	4709                	li	a4,2
    80005bf4:	0ee79163          	bne	a5,a4,80005cd6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005bf8:	0ac05d63          	blez	a2,80005cb2 <filewrite+0xf4>
    int i = 0;
    80005bfc:	4981                	li	s3,0
    80005bfe:	6b05                	lui	s6,0x1
    80005c00:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005c04:	6b85                	lui	s7,0x1
    80005c06:	c00b8b9b          	addiw	s7,s7,-1024
    80005c0a:	a861                	j	80005ca2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005c0c:	6908                	ld	a0,16(a0)
    80005c0e:	00000097          	auipc	ra,0x0
    80005c12:	22e080e7          	jalr	558(ra) # 80005e3c <pipewrite>
    80005c16:	8a2a                	mv	s4,a0
    80005c18:	a045                	j	80005cb8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005c1a:	02451783          	lh	a5,36(a0)
    80005c1e:	03079693          	slli	a3,a5,0x30
    80005c22:	92c1                	srli	a3,a3,0x30
    80005c24:	4725                	li	a4,9
    80005c26:	0cd76263          	bltu	a4,a3,80005cea <filewrite+0x12c>
    80005c2a:	0792                	slli	a5,a5,0x4
    80005c2c:	0001d717          	auipc	a4,0x1d
    80005c30:	38c70713          	addi	a4,a4,908 # 80022fb8 <devsw>
    80005c34:	97ba                	add	a5,a5,a4
    80005c36:	679c                	ld	a5,8(a5)
    80005c38:	cbdd                	beqz	a5,80005cee <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005c3a:	4505                	li	a0,1
    80005c3c:	9782                	jalr	a5
    80005c3e:	8a2a                	mv	s4,a0
    80005c40:	a8a5                	j	80005cb8 <filewrite+0xfa>
    80005c42:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005c46:	00000097          	auipc	ra,0x0
    80005c4a:	8b0080e7          	jalr	-1872(ra) # 800054f6 <begin_op>
      ilock(f->ip);
    80005c4e:	01893503          	ld	a0,24(s2)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	ed2080e7          	jalr	-302(ra) # 80004b24 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005c5a:	8762                	mv	a4,s8
    80005c5c:	02092683          	lw	a3,32(s2)
    80005c60:	01598633          	add	a2,s3,s5
    80005c64:	4585                	li	a1,1
    80005c66:	01893503          	ld	a0,24(s2)
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	266080e7          	jalr	614(ra) # 80004ed0 <writei>
    80005c72:	84aa                	mv	s1,a0
    80005c74:	00a05763          	blez	a0,80005c82 <filewrite+0xc4>
        f->off += r;
    80005c78:	02092783          	lw	a5,32(s2)
    80005c7c:	9fa9                	addw	a5,a5,a0
    80005c7e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005c82:	01893503          	ld	a0,24(s2)
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	f60080e7          	jalr	-160(ra) # 80004be6 <iunlock>
      end_op();
    80005c8e:	00000097          	auipc	ra,0x0
    80005c92:	8e8080e7          	jalr	-1816(ra) # 80005576 <end_op>

      if(r != n1){
    80005c96:	009c1f63          	bne	s8,s1,80005cb4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005c9a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005c9e:	0149db63          	bge	s3,s4,80005cb4 <filewrite+0xf6>
      int n1 = n - i;
    80005ca2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005ca6:	84be                	mv	s1,a5
    80005ca8:	2781                	sext.w	a5,a5
    80005caa:	f8fb5ce3          	bge	s6,a5,80005c42 <filewrite+0x84>
    80005cae:	84de                	mv	s1,s7
    80005cb0:	bf49                	j	80005c42 <filewrite+0x84>
    int i = 0;
    80005cb2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005cb4:	013a1f63          	bne	s4,s3,80005cd2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005cb8:	8552                	mv	a0,s4
    80005cba:	60a6                	ld	ra,72(sp)
    80005cbc:	6406                	ld	s0,64(sp)
    80005cbe:	74e2                	ld	s1,56(sp)
    80005cc0:	7942                	ld	s2,48(sp)
    80005cc2:	79a2                	ld	s3,40(sp)
    80005cc4:	7a02                	ld	s4,32(sp)
    80005cc6:	6ae2                	ld	s5,24(sp)
    80005cc8:	6b42                	ld	s6,16(sp)
    80005cca:	6ba2                	ld	s7,8(sp)
    80005ccc:	6c02                	ld	s8,0(sp)
    80005cce:	6161                	addi	sp,sp,80
    80005cd0:	8082                	ret
    ret = (i == n ? n : -1);
    80005cd2:	5a7d                	li	s4,-1
    80005cd4:	b7d5                	j	80005cb8 <filewrite+0xfa>
    panic("filewrite");
    80005cd6:	00004517          	auipc	a0,0x4
    80005cda:	bfa50513          	addi	a0,a0,-1030 # 800098d0 <syscalls+0x290>
    80005cde:	ffffb097          	auipc	ra,0xffffb
    80005ce2:	860080e7          	jalr	-1952(ra) # 8000053e <panic>
    return -1;
    80005ce6:	5a7d                	li	s4,-1
    80005ce8:	bfc1                	j	80005cb8 <filewrite+0xfa>
      return -1;
    80005cea:	5a7d                	li	s4,-1
    80005cec:	b7f1                	j	80005cb8 <filewrite+0xfa>
    80005cee:	5a7d                	li	s4,-1
    80005cf0:	b7e1                	j	80005cb8 <filewrite+0xfa>

0000000080005cf2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005cf2:	7179                	addi	sp,sp,-48
    80005cf4:	f406                	sd	ra,40(sp)
    80005cf6:	f022                	sd	s0,32(sp)
    80005cf8:	ec26                	sd	s1,24(sp)
    80005cfa:	e84a                	sd	s2,16(sp)
    80005cfc:	e44e                	sd	s3,8(sp)
    80005cfe:	e052                	sd	s4,0(sp)
    80005d00:	1800                	addi	s0,sp,48
    80005d02:	84aa                	mv	s1,a0
    80005d04:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005d06:	0005b023          	sd	zero,0(a1)
    80005d0a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005d0e:	00000097          	auipc	ra,0x0
    80005d12:	bf8080e7          	jalr	-1032(ra) # 80005906 <filealloc>
    80005d16:	e088                	sd	a0,0(s1)
    80005d18:	c551                	beqz	a0,80005da4 <pipealloc+0xb2>
    80005d1a:	00000097          	auipc	ra,0x0
    80005d1e:	bec080e7          	jalr	-1044(ra) # 80005906 <filealloc>
    80005d22:	00aa3023          	sd	a0,0(s4)
    80005d26:	c92d                	beqz	a0,80005d98 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005d28:	ffffb097          	auipc	ra,0xffffb
    80005d2c:	dcc080e7          	jalr	-564(ra) # 80000af4 <kalloc>
    80005d30:	892a                	mv	s2,a0
    80005d32:	c125                	beqz	a0,80005d92 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005d34:	4985                	li	s3,1
    80005d36:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005d3a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005d3e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005d42:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005d46:	00004597          	auipc	a1,0x4
    80005d4a:	b9a58593          	addi	a1,a1,-1126 # 800098e0 <syscalls+0x2a0>
    80005d4e:	ffffb097          	auipc	ra,0xffffb
    80005d52:	e06080e7          	jalr	-506(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005d56:	609c                	ld	a5,0(s1)
    80005d58:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005d5c:	609c                	ld	a5,0(s1)
    80005d5e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005d62:	609c                	ld	a5,0(s1)
    80005d64:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005d68:	609c                	ld	a5,0(s1)
    80005d6a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005d6e:	000a3783          	ld	a5,0(s4)
    80005d72:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005d76:	000a3783          	ld	a5,0(s4)
    80005d7a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005d7e:	000a3783          	ld	a5,0(s4)
    80005d82:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005d86:	000a3783          	ld	a5,0(s4)
    80005d8a:	0127b823          	sd	s2,16(a5)
  return 0;
    80005d8e:	4501                	li	a0,0
    80005d90:	a025                	j	80005db8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005d92:	6088                	ld	a0,0(s1)
    80005d94:	e501                	bnez	a0,80005d9c <pipealloc+0xaa>
    80005d96:	a039                	j	80005da4 <pipealloc+0xb2>
    80005d98:	6088                	ld	a0,0(s1)
    80005d9a:	c51d                	beqz	a0,80005dc8 <pipealloc+0xd6>
    fileclose(*f0);
    80005d9c:	00000097          	auipc	ra,0x0
    80005da0:	c26080e7          	jalr	-986(ra) # 800059c2 <fileclose>
  if(*f1)
    80005da4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005da8:	557d                	li	a0,-1
  if(*f1)
    80005daa:	c799                	beqz	a5,80005db8 <pipealloc+0xc6>
    fileclose(*f1);
    80005dac:	853e                	mv	a0,a5
    80005dae:	00000097          	auipc	ra,0x0
    80005db2:	c14080e7          	jalr	-1004(ra) # 800059c2 <fileclose>
  return -1;
    80005db6:	557d                	li	a0,-1
}
    80005db8:	70a2                	ld	ra,40(sp)
    80005dba:	7402                	ld	s0,32(sp)
    80005dbc:	64e2                	ld	s1,24(sp)
    80005dbe:	6942                	ld	s2,16(sp)
    80005dc0:	69a2                	ld	s3,8(sp)
    80005dc2:	6a02                	ld	s4,0(sp)
    80005dc4:	6145                	addi	sp,sp,48
    80005dc6:	8082                	ret
  return -1;
    80005dc8:	557d                	li	a0,-1
    80005dca:	b7fd                	j	80005db8 <pipealloc+0xc6>

0000000080005dcc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005dcc:	1101                	addi	sp,sp,-32
    80005dce:	ec06                	sd	ra,24(sp)
    80005dd0:	e822                	sd	s0,16(sp)
    80005dd2:	e426                	sd	s1,8(sp)
    80005dd4:	e04a                	sd	s2,0(sp)
    80005dd6:	1000                	addi	s0,sp,32
    80005dd8:	84aa                	mv	s1,a0
    80005dda:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005ddc:	ffffb097          	auipc	ra,0xffffb
    80005de0:	e08080e7          	jalr	-504(ra) # 80000be4 <acquire>
  if(writable){
    80005de4:	02090d63          	beqz	s2,80005e1e <pipeclose+0x52>
    pi->writeopen = 0;
    80005de8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005dec:	21848513          	addi	a0,s1,536
    80005df0:	ffffd097          	auipc	ra,0xffffd
    80005df4:	196080e7          	jalr	406(ra) # 80002f86 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005df8:	2204b783          	ld	a5,544(s1)
    80005dfc:	eb95                	bnez	a5,80005e30 <pipeclose+0x64>
    release(&pi->lock);
    80005dfe:	8526                	mv	a0,s1
    80005e00:	ffffb097          	auipc	ra,0xffffb
    80005e04:	e98080e7          	jalr	-360(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005e08:	8526                	mv	a0,s1
    80005e0a:	ffffb097          	auipc	ra,0xffffb
    80005e0e:	bee080e7          	jalr	-1042(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005e12:	60e2                	ld	ra,24(sp)
    80005e14:	6442                	ld	s0,16(sp)
    80005e16:	64a2                	ld	s1,8(sp)
    80005e18:	6902                	ld	s2,0(sp)
    80005e1a:	6105                	addi	sp,sp,32
    80005e1c:	8082                	ret
    pi->readopen = 0;
    80005e1e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005e22:	21c48513          	addi	a0,s1,540
    80005e26:	ffffd097          	auipc	ra,0xffffd
    80005e2a:	160080e7          	jalr	352(ra) # 80002f86 <wakeup>
    80005e2e:	b7e9                	j	80005df8 <pipeclose+0x2c>
    release(&pi->lock);
    80005e30:	8526                	mv	a0,s1
    80005e32:	ffffb097          	auipc	ra,0xffffb
    80005e36:	e66080e7          	jalr	-410(ra) # 80000c98 <release>
}
    80005e3a:	bfe1                	j	80005e12 <pipeclose+0x46>

0000000080005e3c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005e3c:	7159                	addi	sp,sp,-112
    80005e3e:	f486                	sd	ra,104(sp)
    80005e40:	f0a2                	sd	s0,96(sp)
    80005e42:	eca6                	sd	s1,88(sp)
    80005e44:	e8ca                	sd	s2,80(sp)
    80005e46:	e4ce                	sd	s3,72(sp)
    80005e48:	e0d2                	sd	s4,64(sp)
    80005e4a:	fc56                	sd	s5,56(sp)
    80005e4c:	f85a                	sd	s6,48(sp)
    80005e4e:	f45e                	sd	s7,40(sp)
    80005e50:	f062                	sd	s8,32(sp)
    80005e52:	ec66                	sd	s9,24(sp)
    80005e54:	1880                	addi	s0,sp,112
    80005e56:	84aa                	mv	s1,a0
    80005e58:	8aae                	mv	s5,a1
    80005e5a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005e5c:	ffffc097          	auipc	ra,0xffffc
    80005e60:	da4080e7          	jalr	-604(ra) # 80001c00 <myproc>
    80005e64:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005e66:	8526                	mv	a0,s1
    80005e68:	ffffb097          	auipc	ra,0xffffb
    80005e6c:	d7c080e7          	jalr	-644(ra) # 80000be4 <acquire>
  while(i < n){
    80005e70:	0d405163          	blez	s4,80005f32 <pipewrite+0xf6>
    80005e74:	8ba6                	mv	s7,s1
  int i = 0;
    80005e76:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005e78:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005e7a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005e7e:	21c48c13          	addi	s8,s1,540
    80005e82:	a08d                	j	80005ee4 <pipewrite+0xa8>
      release(&pi->lock);
    80005e84:	8526                	mv	a0,s1
    80005e86:	ffffb097          	auipc	ra,0xffffb
    80005e8a:	e12080e7          	jalr	-494(ra) # 80000c98 <release>
      return -1;
    80005e8e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005e90:	854a                	mv	a0,s2
    80005e92:	70a6                	ld	ra,104(sp)
    80005e94:	7406                	ld	s0,96(sp)
    80005e96:	64e6                	ld	s1,88(sp)
    80005e98:	6946                	ld	s2,80(sp)
    80005e9a:	69a6                	ld	s3,72(sp)
    80005e9c:	6a06                	ld	s4,64(sp)
    80005e9e:	7ae2                	ld	s5,56(sp)
    80005ea0:	7b42                	ld	s6,48(sp)
    80005ea2:	7ba2                	ld	s7,40(sp)
    80005ea4:	7c02                	ld	s8,32(sp)
    80005ea6:	6ce2                	ld	s9,24(sp)
    80005ea8:	6165                	addi	sp,sp,112
    80005eaa:	8082                	ret
      wakeup(&pi->nread);
    80005eac:	8566                	mv	a0,s9
    80005eae:	ffffd097          	auipc	ra,0xffffd
    80005eb2:	0d8080e7          	jalr	216(ra) # 80002f86 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005eb6:	85de                	mv	a1,s7
    80005eb8:	8562                	mv	a0,s8
    80005eba:	ffffd097          	auipc	ra,0xffffd
    80005ebe:	d66080e7          	jalr	-666(ra) # 80002c20 <sleep>
    80005ec2:	a839                	j	80005ee0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005ec4:	21c4a783          	lw	a5,540(s1)
    80005ec8:	0017871b          	addiw	a4,a5,1
    80005ecc:	20e4ae23          	sw	a4,540(s1)
    80005ed0:	1ff7f793          	andi	a5,a5,511
    80005ed4:	97a6                	add	a5,a5,s1
    80005ed6:	f9f44703          	lbu	a4,-97(s0)
    80005eda:	00e78c23          	sb	a4,24(a5)
      i++;
    80005ede:	2905                	addiw	s2,s2,1
  while(i < n){
    80005ee0:	03495d63          	bge	s2,s4,80005f1a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005ee4:	2204a783          	lw	a5,544(s1)
    80005ee8:	dfd1                	beqz	a5,80005e84 <pipewrite+0x48>
    80005eea:	0289a783          	lw	a5,40(s3)
    80005eee:	fbd9                	bnez	a5,80005e84 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005ef0:	2184a783          	lw	a5,536(s1)
    80005ef4:	21c4a703          	lw	a4,540(s1)
    80005ef8:	2007879b          	addiw	a5,a5,512
    80005efc:	faf708e3          	beq	a4,a5,80005eac <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005f00:	4685                	li	a3,1
    80005f02:	01590633          	add	a2,s2,s5
    80005f06:	f9f40593          	addi	a1,s0,-97
    80005f0a:	0809b503          	ld	a0,128(s3)
    80005f0e:	ffffb097          	auipc	ra,0xffffb
    80005f12:	7f8080e7          	jalr	2040(ra) # 80001706 <copyin>
    80005f16:	fb6517e3          	bne	a0,s6,80005ec4 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005f1a:	21848513          	addi	a0,s1,536
    80005f1e:	ffffd097          	auipc	ra,0xffffd
    80005f22:	068080e7          	jalr	104(ra) # 80002f86 <wakeup>
  release(&pi->lock);
    80005f26:	8526                	mv	a0,s1
    80005f28:	ffffb097          	auipc	ra,0xffffb
    80005f2c:	d70080e7          	jalr	-656(ra) # 80000c98 <release>
  return i;
    80005f30:	b785                	j	80005e90 <pipewrite+0x54>
  int i = 0;
    80005f32:	4901                	li	s2,0
    80005f34:	b7dd                	j	80005f1a <pipewrite+0xde>

0000000080005f36 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005f36:	715d                	addi	sp,sp,-80
    80005f38:	e486                	sd	ra,72(sp)
    80005f3a:	e0a2                	sd	s0,64(sp)
    80005f3c:	fc26                	sd	s1,56(sp)
    80005f3e:	f84a                	sd	s2,48(sp)
    80005f40:	f44e                	sd	s3,40(sp)
    80005f42:	f052                	sd	s4,32(sp)
    80005f44:	ec56                	sd	s5,24(sp)
    80005f46:	e85a                	sd	s6,16(sp)
    80005f48:	0880                	addi	s0,sp,80
    80005f4a:	84aa                	mv	s1,a0
    80005f4c:	892e                	mv	s2,a1
    80005f4e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005f50:	ffffc097          	auipc	ra,0xffffc
    80005f54:	cb0080e7          	jalr	-848(ra) # 80001c00 <myproc>
    80005f58:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005f5a:	8b26                	mv	s6,s1
    80005f5c:	8526                	mv	a0,s1
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	c86080e7          	jalr	-890(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f66:	2184a703          	lw	a4,536(s1)
    80005f6a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005f6e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f72:	02f71463          	bne	a4,a5,80005f9a <piperead+0x64>
    80005f76:	2244a783          	lw	a5,548(s1)
    80005f7a:	c385                	beqz	a5,80005f9a <piperead+0x64>
    if(pr->killed){
    80005f7c:	028a2783          	lw	a5,40(s4)
    80005f80:	ebc1                	bnez	a5,80006010 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005f82:	85da                	mv	a1,s6
    80005f84:	854e                	mv	a0,s3
    80005f86:	ffffd097          	auipc	ra,0xffffd
    80005f8a:	c9a080e7          	jalr	-870(ra) # 80002c20 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f8e:	2184a703          	lw	a4,536(s1)
    80005f92:	21c4a783          	lw	a5,540(s1)
    80005f96:	fef700e3          	beq	a4,a5,80005f76 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005f9a:	09505263          	blez	s5,8000601e <piperead+0xe8>
    80005f9e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005fa0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005fa2:	2184a783          	lw	a5,536(s1)
    80005fa6:	21c4a703          	lw	a4,540(s1)
    80005faa:	02f70d63          	beq	a4,a5,80005fe4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005fae:	0017871b          	addiw	a4,a5,1
    80005fb2:	20e4ac23          	sw	a4,536(s1)
    80005fb6:	1ff7f793          	andi	a5,a5,511
    80005fba:	97a6                	add	a5,a5,s1
    80005fbc:	0187c783          	lbu	a5,24(a5)
    80005fc0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005fc4:	4685                	li	a3,1
    80005fc6:	fbf40613          	addi	a2,s0,-65
    80005fca:	85ca                	mv	a1,s2
    80005fcc:	080a3503          	ld	a0,128(s4)
    80005fd0:	ffffb097          	auipc	ra,0xffffb
    80005fd4:	6aa080e7          	jalr	1706(ra) # 8000167a <copyout>
    80005fd8:	01650663          	beq	a0,s6,80005fe4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005fdc:	2985                	addiw	s3,s3,1
    80005fde:	0905                	addi	s2,s2,1
    80005fe0:	fd3a91e3          	bne	s5,s3,80005fa2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005fe4:	21c48513          	addi	a0,s1,540
    80005fe8:	ffffd097          	auipc	ra,0xffffd
    80005fec:	f9e080e7          	jalr	-98(ra) # 80002f86 <wakeup>
  release(&pi->lock);
    80005ff0:	8526                	mv	a0,s1
    80005ff2:	ffffb097          	auipc	ra,0xffffb
    80005ff6:	ca6080e7          	jalr	-858(ra) # 80000c98 <release>
  return i;
}
    80005ffa:	854e                	mv	a0,s3
    80005ffc:	60a6                	ld	ra,72(sp)
    80005ffe:	6406                	ld	s0,64(sp)
    80006000:	74e2                	ld	s1,56(sp)
    80006002:	7942                	ld	s2,48(sp)
    80006004:	79a2                	ld	s3,40(sp)
    80006006:	7a02                	ld	s4,32(sp)
    80006008:	6ae2                	ld	s5,24(sp)
    8000600a:	6b42                	ld	s6,16(sp)
    8000600c:	6161                	addi	sp,sp,80
    8000600e:	8082                	ret
      release(&pi->lock);
    80006010:	8526                	mv	a0,s1
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	c86080e7          	jalr	-890(ra) # 80000c98 <release>
      return -1;
    8000601a:	59fd                	li	s3,-1
    8000601c:	bff9                	j	80005ffa <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000601e:	4981                	li	s3,0
    80006020:	b7d1                	j	80005fe4 <piperead+0xae>

0000000080006022 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80006022:	df010113          	addi	sp,sp,-528
    80006026:	20113423          	sd	ra,520(sp)
    8000602a:	20813023          	sd	s0,512(sp)
    8000602e:	ffa6                	sd	s1,504(sp)
    80006030:	fbca                	sd	s2,496(sp)
    80006032:	f7ce                	sd	s3,488(sp)
    80006034:	f3d2                	sd	s4,480(sp)
    80006036:	efd6                	sd	s5,472(sp)
    80006038:	ebda                	sd	s6,464(sp)
    8000603a:	e7de                	sd	s7,456(sp)
    8000603c:	e3e2                	sd	s8,448(sp)
    8000603e:	ff66                	sd	s9,440(sp)
    80006040:	fb6a                	sd	s10,432(sp)
    80006042:	f76e                	sd	s11,424(sp)
    80006044:	0c00                	addi	s0,sp,528
    80006046:	84aa                	mv	s1,a0
    80006048:	dea43c23          	sd	a0,-520(s0)
    8000604c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80006050:	ffffc097          	auipc	ra,0xffffc
    80006054:	bb0080e7          	jalr	-1104(ra) # 80001c00 <myproc>
    80006058:	892a                	mv	s2,a0

  begin_op();
    8000605a:	fffff097          	auipc	ra,0xfffff
    8000605e:	49c080e7          	jalr	1180(ra) # 800054f6 <begin_op>

  if((ip = namei(path)) == 0){
    80006062:	8526                	mv	a0,s1
    80006064:	fffff097          	auipc	ra,0xfffff
    80006068:	276080e7          	jalr	630(ra) # 800052da <namei>
    8000606c:	c92d                	beqz	a0,800060de <exec+0xbc>
    8000606e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80006070:	fffff097          	auipc	ra,0xfffff
    80006074:	ab4080e7          	jalr	-1356(ra) # 80004b24 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80006078:	04000713          	li	a4,64
    8000607c:	4681                	li	a3,0
    8000607e:	e5040613          	addi	a2,s0,-432
    80006082:	4581                	li	a1,0
    80006084:	8526                	mv	a0,s1
    80006086:	fffff097          	auipc	ra,0xfffff
    8000608a:	d52080e7          	jalr	-686(ra) # 80004dd8 <readi>
    8000608e:	04000793          	li	a5,64
    80006092:	00f51a63          	bne	a0,a5,800060a6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80006096:	e5042703          	lw	a4,-432(s0)
    8000609a:	464c47b7          	lui	a5,0x464c4
    8000609e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800060a2:	04f70463          	beq	a4,a5,800060ea <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800060a6:	8526                	mv	a0,s1
    800060a8:	fffff097          	auipc	ra,0xfffff
    800060ac:	cde080e7          	jalr	-802(ra) # 80004d86 <iunlockput>
    end_op();
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	4c6080e7          	jalr	1222(ra) # 80005576 <end_op>
  }
  return -1;
    800060b8:	557d                	li	a0,-1
}
    800060ba:	20813083          	ld	ra,520(sp)
    800060be:	20013403          	ld	s0,512(sp)
    800060c2:	74fe                	ld	s1,504(sp)
    800060c4:	795e                	ld	s2,496(sp)
    800060c6:	79be                	ld	s3,488(sp)
    800060c8:	7a1e                	ld	s4,480(sp)
    800060ca:	6afe                	ld	s5,472(sp)
    800060cc:	6b5e                	ld	s6,464(sp)
    800060ce:	6bbe                	ld	s7,456(sp)
    800060d0:	6c1e                	ld	s8,448(sp)
    800060d2:	7cfa                	ld	s9,440(sp)
    800060d4:	7d5a                	ld	s10,432(sp)
    800060d6:	7dba                	ld	s11,424(sp)
    800060d8:	21010113          	addi	sp,sp,528
    800060dc:	8082                	ret
    end_op();
    800060de:	fffff097          	auipc	ra,0xfffff
    800060e2:	498080e7          	jalr	1176(ra) # 80005576 <end_op>
    return -1;
    800060e6:	557d                	li	a0,-1
    800060e8:	bfc9                	j	800060ba <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800060ea:	854a                	mv	a0,s2
    800060ec:	ffffc097          	auipc	ra,0xffffc
    800060f0:	bdc080e7          	jalr	-1060(ra) # 80001cc8 <proc_pagetable>
    800060f4:	8baa                	mv	s7,a0
    800060f6:	d945                	beqz	a0,800060a6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800060f8:	e7042983          	lw	s3,-400(s0)
    800060fc:	e8845783          	lhu	a5,-376(s0)
    80006100:	c7ad                	beqz	a5,8000616a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80006102:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80006104:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80006106:	6c85                	lui	s9,0x1
    80006108:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000610c:	def43823          	sd	a5,-528(s0)
    80006110:	a42d                	j	8000633a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80006112:	00003517          	auipc	a0,0x3
    80006116:	7d650513          	addi	a0,a0,2006 # 800098e8 <syscalls+0x2a8>
    8000611a:	ffffa097          	auipc	ra,0xffffa
    8000611e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80006122:	8756                	mv	a4,s5
    80006124:	012d86bb          	addw	a3,s11,s2
    80006128:	4581                	li	a1,0
    8000612a:	8526                	mv	a0,s1
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	cac080e7          	jalr	-852(ra) # 80004dd8 <readi>
    80006134:	2501                	sext.w	a0,a0
    80006136:	1aaa9963          	bne	s5,a0,800062e8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000613a:	6785                	lui	a5,0x1
    8000613c:	0127893b          	addw	s2,a5,s2
    80006140:	77fd                	lui	a5,0xfffff
    80006142:	01478a3b          	addw	s4,a5,s4
    80006146:	1f897163          	bgeu	s2,s8,80006328 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000614a:	02091593          	slli	a1,s2,0x20
    8000614e:	9181                	srli	a1,a1,0x20
    80006150:	95ea                	add	a1,a1,s10
    80006152:	855e                	mv	a0,s7
    80006154:	ffffb097          	auipc	ra,0xffffb
    80006158:	f22080e7          	jalr	-222(ra) # 80001076 <walkaddr>
    8000615c:	862a                	mv	a2,a0
    if(pa == 0)
    8000615e:	d955                	beqz	a0,80006112 <exec+0xf0>
      n = PGSIZE;
    80006160:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80006162:	fd9a70e3          	bgeu	s4,s9,80006122 <exec+0x100>
      n = sz - i;
    80006166:	8ad2                	mv	s5,s4
    80006168:	bf6d                	j	80006122 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000616a:	4901                	li	s2,0
  iunlockput(ip);
    8000616c:	8526                	mv	a0,s1
    8000616e:	fffff097          	auipc	ra,0xfffff
    80006172:	c18080e7          	jalr	-1000(ra) # 80004d86 <iunlockput>
  end_op();
    80006176:	fffff097          	auipc	ra,0xfffff
    8000617a:	400080e7          	jalr	1024(ra) # 80005576 <end_op>
  p = myproc();
    8000617e:	ffffc097          	auipc	ra,0xffffc
    80006182:	a82080e7          	jalr	-1406(ra) # 80001c00 <myproc>
    80006186:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80006188:	07853d03          	ld	s10,120(a0)
  sz = PGROUNDUP(sz);
    8000618c:	6785                	lui	a5,0x1
    8000618e:	17fd                	addi	a5,a5,-1
    80006190:	993e                	add	s2,s2,a5
    80006192:	757d                	lui	a0,0xfffff
    80006194:	00a977b3          	and	a5,s2,a0
    80006198:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000619c:	6609                	lui	a2,0x2
    8000619e:	963e                	add	a2,a2,a5
    800061a0:	85be                	mv	a1,a5
    800061a2:	855e                	mv	a0,s7
    800061a4:	ffffb097          	auipc	ra,0xffffb
    800061a8:	286080e7          	jalr	646(ra) # 8000142a <uvmalloc>
    800061ac:	8b2a                	mv	s6,a0
  ip = 0;
    800061ae:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800061b0:	12050c63          	beqz	a0,800062e8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800061b4:	75f9                	lui	a1,0xffffe
    800061b6:	95aa                	add	a1,a1,a0
    800061b8:	855e                	mv	a0,s7
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	48e080e7          	jalr	1166(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    800061c2:	7c7d                	lui	s8,0xfffff
    800061c4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800061c6:	e0043783          	ld	a5,-512(s0)
    800061ca:	6388                	ld	a0,0(a5)
    800061cc:	c535                	beqz	a0,80006238 <exec+0x216>
    800061ce:	e9040993          	addi	s3,s0,-368
    800061d2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800061d6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800061d8:	ffffb097          	auipc	ra,0xffffb
    800061dc:	c8c080e7          	jalr	-884(ra) # 80000e64 <strlen>
    800061e0:	2505                	addiw	a0,a0,1
    800061e2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800061e6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800061ea:	13896363          	bltu	s2,s8,80006310 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800061ee:	e0043d83          	ld	s11,-512(s0)
    800061f2:	000dba03          	ld	s4,0(s11)
    800061f6:	8552                	mv	a0,s4
    800061f8:	ffffb097          	auipc	ra,0xffffb
    800061fc:	c6c080e7          	jalr	-916(ra) # 80000e64 <strlen>
    80006200:	0015069b          	addiw	a3,a0,1
    80006204:	8652                	mv	a2,s4
    80006206:	85ca                	mv	a1,s2
    80006208:	855e                	mv	a0,s7
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	470080e7          	jalr	1136(ra) # 8000167a <copyout>
    80006212:	10054363          	bltz	a0,80006318 <exec+0x2f6>
    ustack[argc] = sp;
    80006216:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000621a:	0485                	addi	s1,s1,1
    8000621c:	008d8793          	addi	a5,s11,8
    80006220:	e0f43023          	sd	a5,-512(s0)
    80006224:	008db503          	ld	a0,8(s11)
    80006228:	c911                	beqz	a0,8000623c <exec+0x21a>
    if(argc >= MAXARG)
    8000622a:	09a1                	addi	s3,s3,8
    8000622c:	fb3c96e3          	bne	s9,s3,800061d8 <exec+0x1b6>
  sz = sz1;
    80006230:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006234:	4481                	li	s1,0
    80006236:	a84d                	j	800062e8 <exec+0x2c6>
  sp = sz;
    80006238:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000623a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000623c:	00349793          	slli	a5,s1,0x3
    80006240:	f9040713          	addi	a4,s0,-112
    80006244:	97ba                	add	a5,a5,a4
    80006246:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000624a:	00148693          	addi	a3,s1,1
    8000624e:	068e                	slli	a3,a3,0x3
    80006250:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80006254:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80006258:	01897663          	bgeu	s2,s8,80006264 <exec+0x242>
  sz = sz1;
    8000625c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006260:	4481                	li	s1,0
    80006262:	a059                	j	800062e8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80006264:	e9040613          	addi	a2,s0,-368
    80006268:	85ca                	mv	a1,s2
    8000626a:	855e                	mv	a0,s7
    8000626c:	ffffb097          	auipc	ra,0xffffb
    80006270:	40e080e7          	jalr	1038(ra) # 8000167a <copyout>
    80006274:	0a054663          	bltz	a0,80006320 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80006278:	088ab783          	ld	a5,136(s5)
    8000627c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80006280:	df843783          	ld	a5,-520(s0)
    80006284:	0007c703          	lbu	a4,0(a5)
    80006288:	cf11                	beqz	a4,800062a4 <exec+0x282>
    8000628a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000628c:	02f00693          	li	a3,47
    80006290:	a039                	j	8000629e <exec+0x27c>
      last = s+1;
    80006292:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80006296:	0785                	addi	a5,a5,1
    80006298:	fff7c703          	lbu	a4,-1(a5)
    8000629c:	c701                	beqz	a4,800062a4 <exec+0x282>
    if(*s == '/')
    8000629e:	fed71ce3          	bne	a4,a3,80006296 <exec+0x274>
    800062a2:	bfc5                	j	80006292 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800062a4:	4641                	li	a2,16
    800062a6:	df843583          	ld	a1,-520(s0)
    800062aa:	188a8513          	addi	a0,s5,392
    800062ae:	ffffb097          	auipc	ra,0xffffb
    800062b2:	b84080e7          	jalr	-1148(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800062b6:	080ab503          	ld	a0,128(s5)
  p->pagetable = pagetable;
    800062ba:	097ab023          	sd	s7,128(s5)
  p->sz = sz;
    800062be:	076abc23          	sd	s6,120(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800062c2:	088ab783          	ld	a5,136(s5)
    800062c6:	e6843703          	ld	a4,-408(s0)
    800062ca:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800062cc:	088ab783          	ld	a5,136(s5)
    800062d0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800062d4:	85ea                	mv	a1,s10
    800062d6:	ffffc097          	auipc	ra,0xffffc
    800062da:	a8e080e7          	jalr	-1394(ra) # 80001d64 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800062de:	0004851b          	sext.w	a0,s1
    800062e2:	bbe1                	j	800060ba <exec+0x98>
    800062e4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800062e8:	e0843583          	ld	a1,-504(s0)
    800062ec:	855e                	mv	a0,s7
    800062ee:	ffffc097          	auipc	ra,0xffffc
    800062f2:	a76080e7          	jalr	-1418(ra) # 80001d64 <proc_freepagetable>
  if(ip){
    800062f6:	da0498e3          	bnez	s1,800060a6 <exec+0x84>
  return -1;
    800062fa:	557d                	li	a0,-1
    800062fc:	bb7d                	j	800060ba <exec+0x98>
    800062fe:	e1243423          	sd	s2,-504(s0)
    80006302:	b7dd                	j	800062e8 <exec+0x2c6>
    80006304:	e1243423          	sd	s2,-504(s0)
    80006308:	b7c5                	j	800062e8 <exec+0x2c6>
    8000630a:	e1243423          	sd	s2,-504(s0)
    8000630e:	bfe9                	j	800062e8 <exec+0x2c6>
  sz = sz1;
    80006310:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006314:	4481                	li	s1,0
    80006316:	bfc9                	j	800062e8 <exec+0x2c6>
  sz = sz1;
    80006318:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000631c:	4481                	li	s1,0
    8000631e:	b7e9                	j	800062e8 <exec+0x2c6>
  sz = sz1;
    80006320:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006324:	4481                	li	s1,0
    80006326:	b7c9                	j	800062e8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80006328:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000632c:	2b05                	addiw	s6,s6,1
    8000632e:	0389899b          	addiw	s3,s3,56
    80006332:	e8845783          	lhu	a5,-376(s0)
    80006336:	e2fb5be3          	bge	s6,a5,8000616c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000633a:	2981                	sext.w	s3,s3
    8000633c:	03800713          	li	a4,56
    80006340:	86ce                	mv	a3,s3
    80006342:	e1840613          	addi	a2,s0,-488
    80006346:	4581                	li	a1,0
    80006348:	8526                	mv	a0,s1
    8000634a:	fffff097          	auipc	ra,0xfffff
    8000634e:	a8e080e7          	jalr	-1394(ra) # 80004dd8 <readi>
    80006352:	03800793          	li	a5,56
    80006356:	f8f517e3          	bne	a0,a5,800062e4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000635a:	e1842783          	lw	a5,-488(s0)
    8000635e:	4705                	li	a4,1
    80006360:	fce796e3          	bne	a5,a4,8000632c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80006364:	e4043603          	ld	a2,-448(s0)
    80006368:	e3843783          	ld	a5,-456(s0)
    8000636c:	f8f669e3          	bltu	a2,a5,800062fe <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80006370:	e2843783          	ld	a5,-472(s0)
    80006374:	963e                	add	a2,a2,a5
    80006376:	f8f667e3          	bltu	a2,a5,80006304 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000637a:	85ca                	mv	a1,s2
    8000637c:	855e                	mv	a0,s7
    8000637e:	ffffb097          	auipc	ra,0xffffb
    80006382:	0ac080e7          	jalr	172(ra) # 8000142a <uvmalloc>
    80006386:	e0a43423          	sd	a0,-504(s0)
    8000638a:	d141                	beqz	a0,8000630a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000638c:	e2843d03          	ld	s10,-472(s0)
    80006390:	df043783          	ld	a5,-528(s0)
    80006394:	00fd77b3          	and	a5,s10,a5
    80006398:	fba1                	bnez	a5,800062e8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000639a:	e2042d83          	lw	s11,-480(s0)
    8000639e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800063a2:	f80c03e3          	beqz	s8,80006328 <exec+0x306>
    800063a6:	8a62                	mv	s4,s8
    800063a8:	4901                	li	s2,0
    800063aa:	b345                	j	8000614a <exec+0x128>

00000000800063ac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800063ac:	7179                	addi	sp,sp,-48
    800063ae:	f406                	sd	ra,40(sp)
    800063b0:	f022                	sd	s0,32(sp)
    800063b2:	ec26                	sd	s1,24(sp)
    800063b4:	e84a                	sd	s2,16(sp)
    800063b6:	1800                	addi	s0,sp,48
    800063b8:	892e                	mv	s2,a1
    800063ba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800063bc:	fdc40593          	addi	a1,s0,-36
    800063c0:	ffffe097          	auipc	ra,0xffffe
    800063c4:	b46080e7          	jalr	-1210(ra) # 80003f06 <argint>
    800063c8:	04054063          	bltz	a0,80006408 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800063cc:	fdc42703          	lw	a4,-36(s0)
    800063d0:	47bd                	li	a5,15
    800063d2:	02e7ed63          	bltu	a5,a4,8000640c <argfd+0x60>
    800063d6:	ffffc097          	auipc	ra,0xffffc
    800063da:	82a080e7          	jalr	-2006(ra) # 80001c00 <myproc>
    800063de:	fdc42703          	lw	a4,-36(s0)
    800063e2:	02070793          	addi	a5,a4,32
    800063e6:	078e                	slli	a5,a5,0x3
    800063e8:	953e                	add	a0,a0,a5
    800063ea:	611c                	ld	a5,0(a0)
    800063ec:	c395                	beqz	a5,80006410 <argfd+0x64>
    return -1;
  if(pfd)
    800063ee:	00090463          	beqz	s2,800063f6 <argfd+0x4a>
    *pfd = fd;
    800063f2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800063f6:	4501                	li	a0,0
  if(pf)
    800063f8:	c091                	beqz	s1,800063fc <argfd+0x50>
    *pf = f;
    800063fa:	e09c                	sd	a5,0(s1)
}
    800063fc:	70a2                	ld	ra,40(sp)
    800063fe:	7402                	ld	s0,32(sp)
    80006400:	64e2                	ld	s1,24(sp)
    80006402:	6942                	ld	s2,16(sp)
    80006404:	6145                	addi	sp,sp,48
    80006406:	8082                	ret
    return -1;
    80006408:	557d                	li	a0,-1
    8000640a:	bfcd                	j	800063fc <argfd+0x50>
    return -1;
    8000640c:	557d                	li	a0,-1
    8000640e:	b7fd                	j	800063fc <argfd+0x50>
    80006410:	557d                	li	a0,-1
    80006412:	b7ed                	j	800063fc <argfd+0x50>

0000000080006414 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80006414:	1101                	addi	sp,sp,-32
    80006416:	ec06                	sd	ra,24(sp)
    80006418:	e822                	sd	s0,16(sp)
    8000641a:	e426                	sd	s1,8(sp)
    8000641c:	1000                	addi	s0,sp,32
    8000641e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80006420:	ffffb097          	auipc	ra,0xffffb
    80006424:	7e0080e7          	jalr	2016(ra) # 80001c00 <myproc>
    80006428:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000642a:	10050793          	addi	a5,a0,256 # fffffffffffff100 <end+0xffffffff7ffd7100>
    8000642e:	4501                	li	a0,0
    80006430:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80006432:	6398                	ld	a4,0(a5)
    80006434:	cb19                	beqz	a4,8000644a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80006436:	2505                	addiw	a0,a0,1
    80006438:	07a1                	addi	a5,a5,8
    8000643a:	fed51ce3          	bne	a0,a3,80006432 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000643e:	557d                	li	a0,-1
}
    80006440:	60e2                	ld	ra,24(sp)
    80006442:	6442                	ld	s0,16(sp)
    80006444:	64a2                	ld	s1,8(sp)
    80006446:	6105                	addi	sp,sp,32
    80006448:	8082                	ret
      p->ofile[fd] = f;
    8000644a:	02050793          	addi	a5,a0,32
    8000644e:	078e                	slli	a5,a5,0x3
    80006450:	963e                	add	a2,a2,a5
    80006452:	e204                	sd	s1,0(a2)
      return fd;
    80006454:	b7f5                	j	80006440 <fdalloc+0x2c>

0000000080006456 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80006456:	715d                	addi	sp,sp,-80
    80006458:	e486                	sd	ra,72(sp)
    8000645a:	e0a2                	sd	s0,64(sp)
    8000645c:	fc26                	sd	s1,56(sp)
    8000645e:	f84a                	sd	s2,48(sp)
    80006460:	f44e                	sd	s3,40(sp)
    80006462:	f052                	sd	s4,32(sp)
    80006464:	ec56                	sd	s5,24(sp)
    80006466:	0880                	addi	s0,sp,80
    80006468:	89ae                	mv	s3,a1
    8000646a:	8ab2                	mv	s5,a2
    8000646c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000646e:	fb040593          	addi	a1,s0,-80
    80006472:	fffff097          	auipc	ra,0xfffff
    80006476:	e86080e7          	jalr	-378(ra) # 800052f8 <nameiparent>
    8000647a:	892a                	mv	s2,a0
    8000647c:	12050f63          	beqz	a0,800065ba <create+0x164>
    return 0;

  ilock(dp);
    80006480:	ffffe097          	auipc	ra,0xffffe
    80006484:	6a4080e7          	jalr	1700(ra) # 80004b24 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80006488:	4601                	li	a2,0
    8000648a:	fb040593          	addi	a1,s0,-80
    8000648e:	854a                	mv	a0,s2
    80006490:	fffff097          	auipc	ra,0xfffff
    80006494:	b78080e7          	jalr	-1160(ra) # 80005008 <dirlookup>
    80006498:	84aa                	mv	s1,a0
    8000649a:	c921                	beqz	a0,800064ea <create+0x94>
    iunlockput(dp);
    8000649c:	854a                	mv	a0,s2
    8000649e:	fffff097          	auipc	ra,0xfffff
    800064a2:	8e8080e7          	jalr	-1816(ra) # 80004d86 <iunlockput>
    ilock(ip);
    800064a6:	8526                	mv	a0,s1
    800064a8:	ffffe097          	auipc	ra,0xffffe
    800064ac:	67c080e7          	jalr	1660(ra) # 80004b24 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800064b0:	2981                	sext.w	s3,s3
    800064b2:	4789                	li	a5,2
    800064b4:	02f99463          	bne	s3,a5,800064dc <create+0x86>
    800064b8:	0444d783          	lhu	a5,68(s1)
    800064bc:	37f9                	addiw	a5,a5,-2
    800064be:	17c2                	slli	a5,a5,0x30
    800064c0:	93c1                	srli	a5,a5,0x30
    800064c2:	4705                	li	a4,1
    800064c4:	00f76c63          	bltu	a4,a5,800064dc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800064c8:	8526                	mv	a0,s1
    800064ca:	60a6                	ld	ra,72(sp)
    800064cc:	6406                	ld	s0,64(sp)
    800064ce:	74e2                	ld	s1,56(sp)
    800064d0:	7942                	ld	s2,48(sp)
    800064d2:	79a2                	ld	s3,40(sp)
    800064d4:	7a02                	ld	s4,32(sp)
    800064d6:	6ae2                	ld	s5,24(sp)
    800064d8:	6161                	addi	sp,sp,80
    800064da:	8082                	ret
    iunlockput(ip);
    800064dc:	8526                	mv	a0,s1
    800064de:	fffff097          	auipc	ra,0xfffff
    800064e2:	8a8080e7          	jalr	-1880(ra) # 80004d86 <iunlockput>
    return 0;
    800064e6:	4481                	li	s1,0
    800064e8:	b7c5                	j	800064c8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800064ea:	85ce                	mv	a1,s3
    800064ec:	00092503          	lw	a0,0(s2)
    800064f0:	ffffe097          	auipc	ra,0xffffe
    800064f4:	49c080e7          	jalr	1180(ra) # 8000498c <ialloc>
    800064f8:	84aa                	mv	s1,a0
    800064fa:	c529                	beqz	a0,80006544 <create+0xee>
  ilock(ip);
    800064fc:	ffffe097          	auipc	ra,0xffffe
    80006500:	628080e7          	jalr	1576(ra) # 80004b24 <ilock>
  ip->major = major;
    80006504:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006508:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000650c:	4785                	li	a5,1
    8000650e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006512:	8526                	mv	a0,s1
    80006514:	ffffe097          	auipc	ra,0xffffe
    80006518:	546080e7          	jalr	1350(ra) # 80004a5a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000651c:	2981                	sext.w	s3,s3
    8000651e:	4785                	li	a5,1
    80006520:	02f98a63          	beq	s3,a5,80006554 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80006524:	40d0                	lw	a2,4(s1)
    80006526:	fb040593          	addi	a1,s0,-80
    8000652a:	854a                	mv	a0,s2
    8000652c:	fffff097          	auipc	ra,0xfffff
    80006530:	cec080e7          	jalr	-788(ra) # 80005218 <dirlink>
    80006534:	06054b63          	bltz	a0,800065aa <create+0x154>
  iunlockput(dp);
    80006538:	854a                	mv	a0,s2
    8000653a:	fffff097          	auipc	ra,0xfffff
    8000653e:	84c080e7          	jalr	-1972(ra) # 80004d86 <iunlockput>
  return ip;
    80006542:	b759                	j	800064c8 <create+0x72>
    panic("create: ialloc");
    80006544:	00003517          	auipc	a0,0x3
    80006548:	3c450513          	addi	a0,a0,964 # 80009908 <syscalls+0x2c8>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	ff2080e7          	jalr	-14(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80006554:	04a95783          	lhu	a5,74(s2)
    80006558:	2785                	addiw	a5,a5,1
    8000655a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000655e:	854a                	mv	a0,s2
    80006560:	ffffe097          	auipc	ra,0xffffe
    80006564:	4fa080e7          	jalr	1274(ra) # 80004a5a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006568:	40d0                	lw	a2,4(s1)
    8000656a:	00003597          	auipc	a1,0x3
    8000656e:	3ae58593          	addi	a1,a1,942 # 80009918 <syscalls+0x2d8>
    80006572:	8526                	mv	a0,s1
    80006574:	fffff097          	auipc	ra,0xfffff
    80006578:	ca4080e7          	jalr	-860(ra) # 80005218 <dirlink>
    8000657c:	00054f63          	bltz	a0,8000659a <create+0x144>
    80006580:	00492603          	lw	a2,4(s2)
    80006584:	00003597          	auipc	a1,0x3
    80006588:	39c58593          	addi	a1,a1,924 # 80009920 <syscalls+0x2e0>
    8000658c:	8526                	mv	a0,s1
    8000658e:	fffff097          	auipc	ra,0xfffff
    80006592:	c8a080e7          	jalr	-886(ra) # 80005218 <dirlink>
    80006596:	f80557e3          	bgez	a0,80006524 <create+0xce>
      panic("create dots");
    8000659a:	00003517          	auipc	a0,0x3
    8000659e:	38e50513          	addi	a0,a0,910 # 80009928 <syscalls+0x2e8>
    800065a2:	ffffa097          	auipc	ra,0xffffa
    800065a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>
    panic("create: dirlink");
    800065aa:	00003517          	auipc	a0,0x3
    800065ae:	38e50513          	addi	a0,a0,910 # 80009938 <syscalls+0x2f8>
    800065b2:	ffffa097          	auipc	ra,0xffffa
    800065b6:	f8c080e7          	jalr	-116(ra) # 8000053e <panic>
    return 0;
    800065ba:	84aa                	mv	s1,a0
    800065bc:	b731                	j	800064c8 <create+0x72>

00000000800065be <sys_dup>:
{
    800065be:	7179                	addi	sp,sp,-48
    800065c0:	f406                	sd	ra,40(sp)
    800065c2:	f022                	sd	s0,32(sp)
    800065c4:	ec26                	sd	s1,24(sp)
    800065c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800065c8:	fd840613          	addi	a2,s0,-40
    800065cc:	4581                	li	a1,0
    800065ce:	4501                	li	a0,0
    800065d0:	00000097          	auipc	ra,0x0
    800065d4:	ddc080e7          	jalr	-548(ra) # 800063ac <argfd>
    return -1;
    800065d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800065da:	02054363          	bltz	a0,80006600 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800065de:	fd843503          	ld	a0,-40(s0)
    800065e2:	00000097          	auipc	ra,0x0
    800065e6:	e32080e7          	jalr	-462(ra) # 80006414 <fdalloc>
    800065ea:	84aa                	mv	s1,a0
    return -1;
    800065ec:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800065ee:	00054963          	bltz	a0,80006600 <sys_dup+0x42>
  filedup(f);
    800065f2:	fd843503          	ld	a0,-40(s0)
    800065f6:	fffff097          	auipc	ra,0xfffff
    800065fa:	37a080e7          	jalr	890(ra) # 80005970 <filedup>
  return fd;
    800065fe:	87a6                	mv	a5,s1
}
    80006600:	853e                	mv	a0,a5
    80006602:	70a2                	ld	ra,40(sp)
    80006604:	7402                	ld	s0,32(sp)
    80006606:	64e2                	ld	s1,24(sp)
    80006608:	6145                	addi	sp,sp,48
    8000660a:	8082                	ret

000000008000660c <sys_read>:
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
    80006620:	d90080e7          	jalr	-624(ra) # 800063ac <argfd>
    return -1;
    80006624:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006626:	04054163          	bltz	a0,80006668 <sys_read+0x5c>
    8000662a:	fe440593          	addi	a1,s0,-28
    8000662e:	4509                	li	a0,2
    80006630:	ffffe097          	auipc	ra,0xffffe
    80006634:	8d6080e7          	jalr	-1834(ra) # 80003f06 <argint>
    return -1;
    80006638:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000663a:	02054763          	bltz	a0,80006668 <sys_read+0x5c>
    8000663e:	fd840593          	addi	a1,s0,-40
    80006642:	4505                	li	a0,1
    80006644:	ffffe097          	auipc	ra,0xffffe
    80006648:	8e4080e7          	jalr	-1820(ra) # 80003f28 <argaddr>
    return -1;
    8000664c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000664e:	00054d63          	bltz	a0,80006668 <sys_read+0x5c>
  return fileread(f, p, n);
    80006652:	fe442603          	lw	a2,-28(s0)
    80006656:	fd843583          	ld	a1,-40(s0)
    8000665a:	fe843503          	ld	a0,-24(s0)
    8000665e:	fffff097          	auipc	ra,0xfffff
    80006662:	49e080e7          	jalr	1182(ra) # 80005afc <fileread>
    80006666:	87aa                	mv	a5,a0
}
    80006668:	853e                	mv	a0,a5
    8000666a:	70a2                	ld	ra,40(sp)
    8000666c:	7402                	ld	s0,32(sp)
    8000666e:	6145                	addi	sp,sp,48
    80006670:	8082                	ret

0000000080006672 <sys_write>:
{
    80006672:	7179                	addi	sp,sp,-48
    80006674:	f406                	sd	ra,40(sp)
    80006676:	f022                	sd	s0,32(sp)
    80006678:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000667a:	fe840613          	addi	a2,s0,-24
    8000667e:	4581                	li	a1,0
    80006680:	4501                	li	a0,0
    80006682:	00000097          	auipc	ra,0x0
    80006686:	d2a080e7          	jalr	-726(ra) # 800063ac <argfd>
    return -1;
    8000668a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000668c:	04054163          	bltz	a0,800066ce <sys_write+0x5c>
    80006690:	fe440593          	addi	a1,s0,-28
    80006694:	4509                	li	a0,2
    80006696:	ffffe097          	auipc	ra,0xffffe
    8000669a:	870080e7          	jalr	-1936(ra) # 80003f06 <argint>
    return -1;
    8000669e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800066a0:	02054763          	bltz	a0,800066ce <sys_write+0x5c>
    800066a4:	fd840593          	addi	a1,s0,-40
    800066a8:	4505                	li	a0,1
    800066aa:	ffffe097          	auipc	ra,0xffffe
    800066ae:	87e080e7          	jalr	-1922(ra) # 80003f28 <argaddr>
    return -1;
    800066b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800066b4:	00054d63          	bltz	a0,800066ce <sys_write+0x5c>
  return filewrite(f, p, n);
    800066b8:	fe442603          	lw	a2,-28(s0)
    800066bc:	fd843583          	ld	a1,-40(s0)
    800066c0:	fe843503          	ld	a0,-24(s0)
    800066c4:	fffff097          	auipc	ra,0xfffff
    800066c8:	4fa080e7          	jalr	1274(ra) # 80005bbe <filewrite>
    800066cc:	87aa                	mv	a5,a0
}
    800066ce:	853e                	mv	a0,a5
    800066d0:	70a2                	ld	ra,40(sp)
    800066d2:	7402                	ld	s0,32(sp)
    800066d4:	6145                	addi	sp,sp,48
    800066d6:	8082                	ret

00000000800066d8 <sys_close>:
{
    800066d8:	1101                	addi	sp,sp,-32
    800066da:	ec06                	sd	ra,24(sp)
    800066dc:	e822                	sd	s0,16(sp)
    800066de:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800066e0:	fe040613          	addi	a2,s0,-32
    800066e4:	fec40593          	addi	a1,s0,-20
    800066e8:	4501                	li	a0,0
    800066ea:	00000097          	auipc	ra,0x0
    800066ee:	cc2080e7          	jalr	-830(ra) # 800063ac <argfd>
    return -1;
    800066f2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800066f4:	02054563          	bltz	a0,8000671e <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    800066f8:	ffffb097          	auipc	ra,0xffffb
    800066fc:	508080e7          	jalr	1288(ra) # 80001c00 <myproc>
    80006700:	fec42783          	lw	a5,-20(s0)
    80006704:	02078793          	addi	a5,a5,32
    80006708:	078e                	slli	a5,a5,0x3
    8000670a:	97aa                	add	a5,a5,a0
    8000670c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80006710:	fe043503          	ld	a0,-32(s0)
    80006714:	fffff097          	auipc	ra,0xfffff
    80006718:	2ae080e7          	jalr	686(ra) # 800059c2 <fileclose>
  return 0;
    8000671c:	4781                	li	a5,0
}
    8000671e:	853e                	mv	a0,a5
    80006720:	60e2                	ld	ra,24(sp)
    80006722:	6442                	ld	s0,16(sp)
    80006724:	6105                	addi	sp,sp,32
    80006726:	8082                	ret

0000000080006728 <sys_fstat>:
{
    80006728:	1101                	addi	sp,sp,-32
    8000672a:	ec06                	sd	ra,24(sp)
    8000672c:	e822                	sd	s0,16(sp)
    8000672e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006730:	fe840613          	addi	a2,s0,-24
    80006734:	4581                	li	a1,0
    80006736:	4501                	li	a0,0
    80006738:	00000097          	auipc	ra,0x0
    8000673c:	c74080e7          	jalr	-908(ra) # 800063ac <argfd>
    return -1;
    80006740:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006742:	02054563          	bltz	a0,8000676c <sys_fstat+0x44>
    80006746:	fe040593          	addi	a1,s0,-32
    8000674a:	4505                	li	a0,1
    8000674c:	ffffd097          	auipc	ra,0xffffd
    80006750:	7dc080e7          	jalr	2012(ra) # 80003f28 <argaddr>
    return -1;
    80006754:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006756:	00054b63          	bltz	a0,8000676c <sys_fstat+0x44>
  return filestat(f, st);
    8000675a:	fe043583          	ld	a1,-32(s0)
    8000675e:	fe843503          	ld	a0,-24(s0)
    80006762:	fffff097          	auipc	ra,0xfffff
    80006766:	328080e7          	jalr	808(ra) # 80005a8a <filestat>
    8000676a:	87aa                	mv	a5,a0
}
    8000676c:	853e                	mv	a0,a5
    8000676e:	60e2                	ld	ra,24(sp)
    80006770:	6442                	ld	s0,16(sp)
    80006772:	6105                	addi	sp,sp,32
    80006774:	8082                	ret

0000000080006776 <sys_link>:
{
    80006776:	7169                	addi	sp,sp,-304
    80006778:	f606                	sd	ra,296(sp)
    8000677a:	f222                	sd	s0,288(sp)
    8000677c:	ee26                	sd	s1,280(sp)
    8000677e:	ea4a                	sd	s2,272(sp)
    80006780:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006782:	08000613          	li	a2,128
    80006786:	ed040593          	addi	a1,s0,-304
    8000678a:	4501                	li	a0,0
    8000678c:	ffffd097          	auipc	ra,0xffffd
    80006790:	7be080e7          	jalr	1982(ra) # 80003f4a <argstr>
    return -1;
    80006794:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006796:	10054e63          	bltz	a0,800068b2 <sys_link+0x13c>
    8000679a:	08000613          	li	a2,128
    8000679e:	f5040593          	addi	a1,s0,-176
    800067a2:	4505                	li	a0,1
    800067a4:	ffffd097          	auipc	ra,0xffffd
    800067a8:	7a6080e7          	jalr	1958(ra) # 80003f4a <argstr>
    return -1;
    800067ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800067ae:	10054263          	bltz	a0,800068b2 <sys_link+0x13c>
  begin_op();
    800067b2:	fffff097          	auipc	ra,0xfffff
    800067b6:	d44080e7          	jalr	-700(ra) # 800054f6 <begin_op>
  if((ip = namei(old)) == 0){
    800067ba:	ed040513          	addi	a0,s0,-304
    800067be:	fffff097          	auipc	ra,0xfffff
    800067c2:	b1c080e7          	jalr	-1252(ra) # 800052da <namei>
    800067c6:	84aa                	mv	s1,a0
    800067c8:	c551                	beqz	a0,80006854 <sys_link+0xde>
  ilock(ip);
    800067ca:	ffffe097          	auipc	ra,0xffffe
    800067ce:	35a080e7          	jalr	858(ra) # 80004b24 <ilock>
  if(ip->type == T_DIR){
    800067d2:	04449703          	lh	a4,68(s1)
    800067d6:	4785                	li	a5,1
    800067d8:	08f70463          	beq	a4,a5,80006860 <sys_link+0xea>
  ip->nlink++;
    800067dc:	04a4d783          	lhu	a5,74(s1)
    800067e0:	2785                	addiw	a5,a5,1
    800067e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800067e6:	8526                	mv	a0,s1
    800067e8:	ffffe097          	auipc	ra,0xffffe
    800067ec:	272080e7          	jalr	626(ra) # 80004a5a <iupdate>
  iunlock(ip);
    800067f0:	8526                	mv	a0,s1
    800067f2:	ffffe097          	auipc	ra,0xffffe
    800067f6:	3f4080e7          	jalr	1012(ra) # 80004be6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800067fa:	fd040593          	addi	a1,s0,-48
    800067fe:	f5040513          	addi	a0,s0,-176
    80006802:	fffff097          	auipc	ra,0xfffff
    80006806:	af6080e7          	jalr	-1290(ra) # 800052f8 <nameiparent>
    8000680a:	892a                	mv	s2,a0
    8000680c:	c935                	beqz	a0,80006880 <sys_link+0x10a>
  ilock(dp);
    8000680e:	ffffe097          	auipc	ra,0xffffe
    80006812:	316080e7          	jalr	790(ra) # 80004b24 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006816:	00092703          	lw	a4,0(s2)
    8000681a:	409c                	lw	a5,0(s1)
    8000681c:	04f71d63          	bne	a4,a5,80006876 <sys_link+0x100>
    80006820:	40d0                	lw	a2,4(s1)
    80006822:	fd040593          	addi	a1,s0,-48
    80006826:	854a                	mv	a0,s2
    80006828:	fffff097          	auipc	ra,0xfffff
    8000682c:	9f0080e7          	jalr	-1552(ra) # 80005218 <dirlink>
    80006830:	04054363          	bltz	a0,80006876 <sys_link+0x100>
  iunlockput(dp);
    80006834:	854a                	mv	a0,s2
    80006836:	ffffe097          	auipc	ra,0xffffe
    8000683a:	550080e7          	jalr	1360(ra) # 80004d86 <iunlockput>
  iput(ip);
    8000683e:	8526                	mv	a0,s1
    80006840:	ffffe097          	auipc	ra,0xffffe
    80006844:	49e080e7          	jalr	1182(ra) # 80004cde <iput>
  end_op();
    80006848:	fffff097          	auipc	ra,0xfffff
    8000684c:	d2e080e7          	jalr	-722(ra) # 80005576 <end_op>
  return 0;
    80006850:	4781                	li	a5,0
    80006852:	a085                	j	800068b2 <sys_link+0x13c>
    end_op();
    80006854:	fffff097          	auipc	ra,0xfffff
    80006858:	d22080e7          	jalr	-734(ra) # 80005576 <end_op>
    return -1;
    8000685c:	57fd                	li	a5,-1
    8000685e:	a891                	j	800068b2 <sys_link+0x13c>
    iunlockput(ip);
    80006860:	8526                	mv	a0,s1
    80006862:	ffffe097          	auipc	ra,0xffffe
    80006866:	524080e7          	jalr	1316(ra) # 80004d86 <iunlockput>
    end_op();
    8000686a:	fffff097          	auipc	ra,0xfffff
    8000686e:	d0c080e7          	jalr	-756(ra) # 80005576 <end_op>
    return -1;
    80006872:	57fd                	li	a5,-1
    80006874:	a83d                	j	800068b2 <sys_link+0x13c>
    iunlockput(dp);
    80006876:	854a                	mv	a0,s2
    80006878:	ffffe097          	auipc	ra,0xffffe
    8000687c:	50e080e7          	jalr	1294(ra) # 80004d86 <iunlockput>
  ilock(ip);
    80006880:	8526                	mv	a0,s1
    80006882:	ffffe097          	auipc	ra,0xffffe
    80006886:	2a2080e7          	jalr	674(ra) # 80004b24 <ilock>
  ip->nlink--;
    8000688a:	04a4d783          	lhu	a5,74(s1)
    8000688e:	37fd                	addiw	a5,a5,-1
    80006890:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006894:	8526                	mv	a0,s1
    80006896:	ffffe097          	auipc	ra,0xffffe
    8000689a:	1c4080e7          	jalr	452(ra) # 80004a5a <iupdate>
  iunlockput(ip);
    8000689e:	8526                	mv	a0,s1
    800068a0:	ffffe097          	auipc	ra,0xffffe
    800068a4:	4e6080e7          	jalr	1254(ra) # 80004d86 <iunlockput>
  end_op();
    800068a8:	fffff097          	auipc	ra,0xfffff
    800068ac:	cce080e7          	jalr	-818(ra) # 80005576 <end_op>
  return -1;
    800068b0:	57fd                	li	a5,-1
}
    800068b2:	853e                	mv	a0,a5
    800068b4:	70b2                	ld	ra,296(sp)
    800068b6:	7412                	ld	s0,288(sp)
    800068b8:	64f2                	ld	s1,280(sp)
    800068ba:	6952                	ld	s2,272(sp)
    800068bc:	6155                	addi	sp,sp,304
    800068be:	8082                	ret

00000000800068c0 <sys_unlink>:
{
    800068c0:	7151                	addi	sp,sp,-240
    800068c2:	f586                	sd	ra,232(sp)
    800068c4:	f1a2                	sd	s0,224(sp)
    800068c6:	eda6                	sd	s1,216(sp)
    800068c8:	e9ca                	sd	s2,208(sp)
    800068ca:	e5ce                	sd	s3,200(sp)
    800068cc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800068ce:	08000613          	li	a2,128
    800068d2:	f3040593          	addi	a1,s0,-208
    800068d6:	4501                	li	a0,0
    800068d8:	ffffd097          	auipc	ra,0xffffd
    800068dc:	672080e7          	jalr	1650(ra) # 80003f4a <argstr>
    800068e0:	18054163          	bltz	a0,80006a62 <sys_unlink+0x1a2>
  begin_op();
    800068e4:	fffff097          	auipc	ra,0xfffff
    800068e8:	c12080e7          	jalr	-1006(ra) # 800054f6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800068ec:	fb040593          	addi	a1,s0,-80
    800068f0:	f3040513          	addi	a0,s0,-208
    800068f4:	fffff097          	auipc	ra,0xfffff
    800068f8:	a04080e7          	jalr	-1532(ra) # 800052f8 <nameiparent>
    800068fc:	84aa                	mv	s1,a0
    800068fe:	c979                	beqz	a0,800069d4 <sys_unlink+0x114>
  ilock(dp);
    80006900:	ffffe097          	auipc	ra,0xffffe
    80006904:	224080e7          	jalr	548(ra) # 80004b24 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006908:	00003597          	auipc	a1,0x3
    8000690c:	01058593          	addi	a1,a1,16 # 80009918 <syscalls+0x2d8>
    80006910:	fb040513          	addi	a0,s0,-80
    80006914:	ffffe097          	auipc	ra,0xffffe
    80006918:	6da080e7          	jalr	1754(ra) # 80004fee <namecmp>
    8000691c:	14050a63          	beqz	a0,80006a70 <sys_unlink+0x1b0>
    80006920:	00003597          	auipc	a1,0x3
    80006924:	00058593          	mv	a1,a1
    80006928:	fb040513          	addi	a0,s0,-80
    8000692c:	ffffe097          	auipc	ra,0xffffe
    80006930:	6c2080e7          	jalr	1730(ra) # 80004fee <namecmp>
    80006934:	12050e63          	beqz	a0,80006a70 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006938:	f2c40613          	addi	a2,s0,-212
    8000693c:	fb040593          	addi	a1,s0,-80
    80006940:	8526                	mv	a0,s1
    80006942:	ffffe097          	auipc	ra,0xffffe
    80006946:	6c6080e7          	jalr	1734(ra) # 80005008 <dirlookup>
    8000694a:	892a                	mv	s2,a0
    8000694c:	12050263          	beqz	a0,80006a70 <sys_unlink+0x1b0>
  ilock(ip);
    80006950:	ffffe097          	auipc	ra,0xffffe
    80006954:	1d4080e7          	jalr	468(ra) # 80004b24 <ilock>
  if(ip->nlink < 1)
    80006958:	04a91783          	lh	a5,74(s2)
    8000695c:	08f05263          	blez	a5,800069e0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006960:	04491703          	lh	a4,68(s2)
    80006964:	4785                	li	a5,1
    80006966:	08f70563          	beq	a4,a5,800069f0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000696a:	4641                	li	a2,16
    8000696c:	4581                	li	a1,0
    8000696e:	fc040513          	addi	a0,s0,-64
    80006972:	ffffa097          	auipc	ra,0xffffa
    80006976:	36e080e7          	jalr	878(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000697a:	4741                	li	a4,16
    8000697c:	f2c42683          	lw	a3,-212(s0)
    80006980:	fc040613          	addi	a2,s0,-64
    80006984:	4581                	li	a1,0
    80006986:	8526                	mv	a0,s1
    80006988:	ffffe097          	auipc	ra,0xffffe
    8000698c:	548080e7          	jalr	1352(ra) # 80004ed0 <writei>
    80006990:	47c1                	li	a5,16
    80006992:	0af51563          	bne	a0,a5,80006a3c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006996:	04491703          	lh	a4,68(s2)
    8000699a:	4785                	li	a5,1
    8000699c:	0af70863          	beq	a4,a5,80006a4c <sys_unlink+0x18c>
  iunlockput(dp);
    800069a0:	8526                	mv	a0,s1
    800069a2:	ffffe097          	auipc	ra,0xffffe
    800069a6:	3e4080e7          	jalr	996(ra) # 80004d86 <iunlockput>
  ip->nlink--;
    800069aa:	04a95783          	lhu	a5,74(s2)
    800069ae:	37fd                	addiw	a5,a5,-1
    800069b0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800069b4:	854a                	mv	a0,s2
    800069b6:	ffffe097          	auipc	ra,0xffffe
    800069ba:	0a4080e7          	jalr	164(ra) # 80004a5a <iupdate>
  iunlockput(ip);
    800069be:	854a                	mv	a0,s2
    800069c0:	ffffe097          	auipc	ra,0xffffe
    800069c4:	3c6080e7          	jalr	966(ra) # 80004d86 <iunlockput>
  end_op();
    800069c8:	fffff097          	auipc	ra,0xfffff
    800069cc:	bae080e7          	jalr	-1106(ra) # 80005576 <end_op>
  return 0;
    800069d0:	4501                	li	a0,0
    800069d2:	a84d                	j	80006a84 <sys_unlink+0x1c4>
    end_op();
    800069d4:	fffff097          	auipc	ra,0xfffff
    800069d8:	ba2080e7          	jalr	-1118(ra) # 80005576 <end_op>
    return -1;
    800069dc:	557d                	li	a0,-1
    800069de:	a05d                	j	80006a84 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800069e0:	00003517          	auipc	a0,0x3
    800069e4:	f6850513          	addi	a0,a0,-152 # 80009948 <syscalls+0x308>
    800069e8:	ffffa097          	auipc	ra,0xffffa
    800069ec:	b56080e7          	jalr	-1194(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800069f0:	04c92703          	lw	a4,76(s2)
    800069f4:	02000793          	li	a5,32
    800069f8:	f6e7f9e3          	bgeu	a5,a4,8000696a <sys_unlink+0xaa>
    800069fc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006a00:	4741                	li	a4,16
    80006a02:	86ce                	mv	a3,s3
    80006a04:	f1840613          	addi	a2,s0,-232
    80006a08:	4581                	li	a1,0
    80006a0a:	854a                	mv	a0,s2
    80006a0c:	ffffe097          	auipc	ra,0xffffe
    80006a10:	3cc080e7          	jalr	972(ra) # 80004dd8 <readi>
    80006a14:	47c1                	li	a5,16
    80006a16:	00f51b63          	bne	a0,a5,80006a2c <sys_unlink+0x16c>
    if(de.inum != 0)
    80006a1a:	f1845783          	lhu	a5,-232(s0)
    80006a1e:	e7a1                	bnez	a5,80006a66 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006a20:	29c1                	addiw	s3,s3,16
    80006a22:	04c92783          	lw	a5,76(s2)
    80006a26:	fcf9ede3          	bltu	s3,a5,80006a00 <sys_unlink+0x140>
    80006a2a:	b781                	j	8000696a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006a2c:	00003517          	auipc	a0,0x3
    80006a30:	f3450513          	addi	a0,a0,-204 # 80009960 <syscalls+0x320>
    80006a34:	ffffa097          	auipc	ra,0xffffa
    80006a38:	b0a080e7          	jalr	-1270(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006a3c:	00003517          	auipc	a0,0x3
    80006a40:	f3c50513          	addi	a0,a0,-196 # 80009978 <syscalls+0x338>
    80006a44:	ffffa097          	auipc	ra,0xffffa
    80006a48:	afa080e7          	jalr	-1286(ra) # 8000053e <panic>
    dp->nlink--;
    80006a4c:	04a4d783          	lhu	a5,74(s1)
    80006a50:	37fd                	addiw	a5,a5,-1
    80006a52:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006a56:	8526                	mv	a0,s1
    80006a58:	ffffe097          	auipc	ra,0xffffe
    80006a5c:	002080e7          	jalr	2(ra) # 80004a5a <iupdate>
    80006a60:	b781                	j	800069a0 <sys_unlink+0xe0>
    return -1;
    80006a62:	557d                	li	a0,-1
    80006a64:	a005                	j	80006a84 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006a66:	854a                	mv	a0,s2
    80006a68:	ffffe097          	auipc	ra,0xffffe
    80006a6c:	31e080e7          	jalr	798(ra) # 80004d86 <iunlockput>
  iunlockput(dp);
    80006a70:	8526                	mv	a0,s1
    80006a72:	ffffe097          	auipc	ra,0xffffe
    80006a76:	314080e7          	jalr	788(ra) # 80004d86 <iunlockput>
  end_op();
    80006a7a:	fffff097          	auipc	ra,0xfffff
    80006a7e:	afc080e7          	jalr	-1284(ra) # 80005576 <end_op>
  return -1;
    80006a82:	557d                	li	a0,-1
}
    80006a84:	70ae                	ld	ra,232(sp)
    80006a86:	740e                	ld	s0,224(sp)
    80006a88:	64ee                	ld	s1,216(sp)
    80006a8a:	694e                	ld	s2,208(sp)
    80006a8c:	69ae                	ld	s3,200(sp)
    80006a8e:	616d                	addi	sp,sp,240
    80006a90:	8082                	ret

0000000080006a92 <sys_open>:

uint64
sys_open(void)
{
    80006a92:	7131                	addi	sp,sp,-192
    80006a94:	fd06                	sd	ra,184(sp)
    80006a96:	f922                	sd	s0,176(sp)
    80006a98:	f526                	sd	s1,168(sp)
    80006a9a:	f14a                	sd	s2,160(sp)
    80006a9c:	ed4e                	sd	s3,152(sp)
    80006a9e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006aa0:	08000613          	li	a2,128
    80006aa4:	f5040593          	addi	a1,s0,-176
    80006aa8:	4501                	li	a0,0
    80006aaa:	ffffd097          	auipc	ra,0xffffd
    80006aae:	4a0080e7          	jalr	1184(ra) # 80003f4a <argstr>
    return -1;
    80006ab2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006ab4:	0c054163          	bltz	a0,80006b76 <sys_open+0xe4>
    80006ab8:	f4c40593          	addi	a1,s0,-180
    80006abc:	4505                	li	a0,1
    80006abe:	ffffd097          	auipc	ra,0xffffd
    80006ac2:	448080e7          	jalr	1096(ra) # 80003f06 <argint>
    80006ac6:	0a054863          	bltz	a0,80006b76 <sys_open+0xe4>

  begin_op();
    80006aca:	fffff097          	auipc	ra,0xfffff
    80006ace:	a2c080e7          	jalr	-1492(ra) # 800054f6 <begin_op>

  if(omode & O_CREATE){
    80006ad2:	f4c42783          	lw	a5,-180(s0)
    80006ad6:	2007f793          	andi	a5,a5,512
    80006ada:	cbdd                	beqz	a5,80006b90 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006adc:	4681                	li	a3,0
    80006ade:	4601                	li	a2,0
    80006ae0:	4589                	li	a1,2
    80006ae2:	f5040513          	addi	a0,s0,-176
    80006ae6:	00000097          	auipc	ra,0x0
    80006aea:	970080e7          	jalr	-1680(ra) # 80006456 <create>
    80006aee:	892a                	mv	s2,a0
    if(ip == 0){
    80006af0:	c959                	beqz	a0,80006b86 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006af2:	04491703          	lh	a4,68(s2)
    80006af6:	478d                	li	a5,3
    80006af8:	00f71763          	bne	a4,a5,80006b06 <sys_open+0x74>
    80006afc:	04695703          	lhu	a4,70(s2)
    80006b00:	47a5                	li	a5,9
    80006b02:	0ce7ec63          	bltu	a5,a4,80006bda <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006b06:	fffff097          	auipc	ra,0xfffff
    80006b0a:	e00080e7          	jalr	-512(ra) # 80005906 <filealloc>
    80006b0e:	89aa                	mv	s3,a0
    80006b10:	10050263          	beqz	a0,80006c14 <sys_open+0x182>
    80006b14:	00000097          	auipc	ra,0x0
    80006b18:	900080e7          	jalr	-1792(ra) # 80006414 <fdalloc>
    80006b1c:	84aa                	mv	s1,a0
    80006b1e:	0e054663          	bltz	a0,80006c0a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006b22:	04491703          	lh	a4,68(s2)
    80006b26:	478d                	li	a5,3
    80006b28:	0cf70463          	beq	a4,a5,80006bf0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006b2c:	4789                	li	a5,2
    80006b2e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006b32:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006b36:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006b3a:	f4c42783          	lw	a5,-180(s0)
    80006b3e:	0017c713          	xori	a4,a5,1
    80006b42:	8b05                	andi	a4,a4,1
    80006b44:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006b48:	0037f713          	andi	a4,a5,3
    80006b4c:	00e03733          	snez	a4,a4
    80006b50:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006b54:	4007f793          	andi	a5,a5,1024
    80006b58:	c791                	beqz	a5,80006b64 <sys_open+0xd2>
    80006b5a:	04491703          	lh	a4,68(s2)
    80006b5e:	4789                	li	a5,2
    80006b60:	08f70f63          	beq	a4,a5,80006bfe <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006b64:	854a                	mv	a0,s2
    80006b66:	ffffe097          	auipc	ra,0xffffe
    80006b6a:	080080e7          	jalr	128(ra) # 80004be6 <iunlock>
  end_op();
    80006b6e:	fffff097          	auipc	ra,0xfffff
    80006b72:	a08080e7          	jalr	-1528(ra) # 80005576 <end_op>

  return fd;
}
    80006b76:	8526                	mv	a0,s1
    80006b78:	70ea                	ld	ra,184(sp)
    80006b7a:	744a                	ld	s0,176(sp)
    80006b7c:	74aa                	ld	s1,168(sp)
    80006b7e:	790a                	ld	s2,160(sp)
    80006b80:	69ea                	ld	s3,152(sp)
    80006b82:	6129                	addi	sp,sp,192
    80006b84:	8082                	ret
      end_op();
    80006b86:	fffff097          	auipc	ra,0xfffff
    80006b8a:	9f0080e7          	jalr	-1552(ra) # 80005576 <end_op>
      return -1;
    80006b8e:	b7e5                	j	80006b76 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006b90:	f5040513          	addi	a0,s0,-176
    80006b94:	ffffe097          	auipc	ra,0xffffe
    80006b98:	746080e7          	jalr	1862(ra) # 800052da <namei>
    80006b9c:	892a                	mv	s2,a0
    80006b9e:	c905                	beqz	a0,80006bce <sys_open+0x13c>
    ilock(ip);
    80006ba0:	ffffe097          	auipc	ra,0xffffe
    80006ba4:	f84080e7          	jalr	-124(ra) # 80004b24 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006ba8:	04491703          	lh	a4,68(s2)
    80006bac:	4785                	li	a5,1
    80006bae:	f4f712e3          	bne	a4,a5,80006af2 <sys_open+0x60>
    80006bb2:	f4c42783          	lw	a5,-180(s0)
    80006bb6:	dba1                	beqz	a5,80006b06 <sys_open+0x74>
      iunlockput(ip);
    80006bb8:	854a                	mv	a0,s2
    80006bba:	ffffe097          	auipc	ra,0xffffe
    80006bbe:	1cc080e7          	jalr	460(ra) # 80004d86 <iunlockput>
      end_op();
    80006bc2:	fffff097          	auipc	ra,0xfffff
    80006bc6:	9b4080e7          	jalr	-1612(ra) # 80005576 <end_op>
      return -1;
    80006bca:	54fd                	li	s1,-1
    80006bcc:	b76d                	j	80006b76 <sys_open+0xe4>
      end_op();
    80006bce:	fffff097          	auipc	ra,0xfffff
    80006bd2:	9a8080e7          	jalr	-1624(ra) # 80005576 <end_op>
      return -1;
    80006bd6:	54fd                	li	s1,-1
    80006bd8:	bf79                	j	80006b76 <sys_open+0xe4>
    iunlockput(ip);
    80006bda:	854a                	mv	a0,s2
    80006bdc:	ffffe097          	auipc	ra,0xffffe
    80006be0:	1aa080e7          	jalr	426(ra) # 80004d86 <iunlockput>
    end_op();
    80006be4:	fffff097          	auipc	ra,0xfffff
    80006be8:	992080e7          	jalr	-1646(ra) # 80005576 <end_op>
    return -1;
    80006bec:	54fd                	li	s1,-1
    80006bee:	b761                	j	80006b76 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006bf0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006bf4:	04691783          	lh	a5,70(s2)
    80006bf8:	02f99223          	sh	a5,36(s3)
    80006bfc:	bf2d                	j	80006b36 <sys_open+0xa4>
    itrunc(ip);
    80006bfe:	854a                	mv	a0,s2
    80006c00:	ffffe097          	auipc	ra,0xffffe
    80006c04:	032080e7          	jalr	50(ra) # 80004c32 <itrunc>
    80006c08:	bfb1                	j	80006b64 <sys_open+0xd2>
      fileclose(f);
    80006c0a:	854e                	mv	a0,s3
    80006c0c:	fffff097          	auipc	ra,0xfffff
    80006c10:	db6080e7          	jalr	-586(ra) # 800059c2 <fileclose>
    iunlockput(ip);
    80006c14:	854a                	mv	a0,s2
    80006c16:	ffffe097          	auipc	ra,0xffffe
    80006c1a:	170080e7          	jalr	368(ra) # 80004d86 <iunlockput>
    end_op();
    80006c1e:	fffff097          	auipc	ra,0xfffff
    80006c22:	958080e7          	jalr	-1704(ra) # 80005576 <end_op>
    return -1;
    80006c26:	54fd                	li	s1,-1
    80006c28:	b7b9                	j	80006b76 <sys_open+0xe4>

0000000080006c2a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006c2a:	7175                	addi	sp,sp,-144
    80006c2c:	e506                	sd	ra,136(sp)
    80006c2e:	e122                	sd	s0,128(sp)
    80006c30:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006c32:	fffff097          	auipc	ra,0xfffff
    80006c36:	8c4080e7          	jalr	-1852(ra) # 800054f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006c3a:	08000613          	li	a2,128
    80006c3e:	f7040593          	addi	a1,s0,-144
    80006c42:	4501                	li	a0,0
    80006c44:	ffffd097          	auipc	ra,0xffffd
    80006c48:	306080e7          	jalr	774(ra) # 80003f4a <argstr>
    80006c4c:	02054963          	bltz	a0,80006c7e <sys_mkdir+0x54>
    80006c50:	4681                	li	a3,0
    80006c52:	4601                	li	a2,0
    80006c54:	4585                	li	a1,1
    80006c56:	f7040513          	addi	a0,s0,-144
    80006c5a:	fffff097          	auipc	ra,0xfffff
    80006c5e:	7fc080e7          	jalr	2044(ra) # 80006456 <create>
    80006c62:	cd11                	beqz	a0,80006c7e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006c64:	ffffe097          	auipc	ra,0xffffe
    80006c68:	122080e7          	jalr	290(ra) # 80004d86 <iunlockput>
  end_op();
    80006c6c:	fffff097          	auipc	ra,0xfffff
    80006c70:	90a080e7          	jalr	-1782(ra) # 80005576 <end_op>
  return 0;
    80006c74:	4501                	li	a0,0
}
    80006c76:	60aa                	ld	ra,136(sp)
    80006c78:	640a                	ld	s0,128(sp)
    80006c7a:	6149                	addi	sp,sp,144
    80006c7c:	8082                	ret
    end_op();
    80006c7e:	fffff097          	auipc	ra,0xfffff
    80006c82:	8f8080e7          	jalr	-1800(ra) # 80005576 <end_op>
    return -1;
    80006c86:	557d                	li	a0,-1
    80006c88:	b7fd                	j	80006c76 <sys_mkdir+0x4c>

0000000080006c8a <sys_mknod>:

uint64
sys_mknod(void)
{
    80006c8a:	7135                	addi	sp,sp,-160
    80006c8c:	ed06                	sd	ra,152(sp)
    80006c8e:	e922                	sd	s0,144(sp)
    80006c90:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006c92:	fffff097          	auipc	ra,0xfffff
    80006c96:	864080e7          	jalr	-1948(ra) # 800054f6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006c9a:	08000613          	li	a2,128
    80006c9e:	f7040593          	addi	a1,s0,-144
    80006ca2:	4501                	li	a0,0
    80006ca4:	ffffd097          	auipc	ra,0xffffd
    80006ca8:	2a6080e7          	jalr	678(ra) # 80003f4a <argstr>
    80006cac:	04054a63          	bltz	a0,80006d00 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006cb0:	f6c40593          	addi	a1,s0,-148
    80006cb4:	4505                	li	a0,1
    80006cb6:	ffffd097          	auipc	ra,0xffffd
    80006cba:	250080e7          	jalr	592(ra) # 80003f06 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006cbe:	04054163          	bltz	a0,80006d00 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006cc2:	f6840593          	addi	a1,s0,-152
    80006cc6:	4509                	li	a0,2
    80006cc8:	ffffd097          	auipc	ra,0xffffd
    80006ccc:	23e080e7          	jalr	574(ra) # 80003f06 <argint>
     argint(1, &major) < 0 ||
    80006cd0:	02054863          	bltz	a0,80006d00 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006cd4:	f6841683          	lh	a3,-152(s0)
    80006cd8:	f6c41603          	lh	a2,-148(s0)
    80006cdc:	458d                	li	a1,3
    80006cde:	f7040513          	addi	a0,s0,-144
    80006ce2:	fffff097          	auipc	ra,0xfffff
    80006ce6:	774080e7          	jalr	1908(ra) # 80006456 <create>
     argint(2, &minor) < 0 ||
    80006cea:	c919                	beqz	a0,80006d00 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006cec:	ffffe097          	auipc	ra,0xffffe
    80006cf0:	09a080e7          	jalr	154(ra) # 80004d86 <iunlockput>
  end_op();
    80006cf4:	fffff097          	auipc	ra,0xfffff
    80006cf8:	882080e7          	jalr	-1918(ra) # 80005576 <end_op>
  return 0;
    80006cfc:	4501                	li	a0,0
    80006cfe:	a031                	j	80006d0a <sys_mknod+0x80>
    end_op();
    80006d00:	fffff097          	auipc	ra,0xfffff
    80006d04:	876080e7          	jalr	-1930(ra) # 80005576 <end_op>
    return -1;
    80006d08:	557d                	li	a0,-1
}
    80006d0a:	60ea                	ld	ra,152(sp)
    80006d0c:	644a                	ld	s0,144(sp)
    80006d0e:	610d                	addi	sp,sp,160
    80006d10:	8082                	ret

0000000080006d12 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006d12:	7135                	addi	sp,sp,-160
    80006d14:	ed06                	sd	ra,152(sp)
    80006d16:	e922                	sd	s0,144(sp)
    80006d18:	e526                	sd	s1,136(sp)
    80006d1a:	e14a                	sd	s2,128(sp)
    80006d1c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006d1e:	ffffb097          	auipc	ra,0xffffb
    80006d22:	ee2080e7          	jalr	-286(ra) # 80001c00 <myproc>
    80006d26:	892a                	mv	s2,a0
  
  begin_op();
    80006d28:	ffffe097          	auipc	ra,0xffffe
    80006d2c:	7ce080e7          	jalr	1998(ra) # 800054f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006d30:	08000613          	li	a2,128
    80006d34:	f6040593          	addi	a1,s0,-160
    80006d38:	4501                	li	a0,0
    80006d3a:	ffffd097          	auipc	ra,0xffffd
    80006d3e:	210080e7          	jalr	528(ra) # 80003f4a <argstr>
    80006d42:	04054b63          	bltz	a0,80006d98 <sys_chdir+0x86>
    80006d46:	f6040513          	addi	a0,s0,-160
    80006d4a:	ffffe097          	auipc	ra,0xffffe
    80006d4e:	590080e7          	jalr	1424(ra) # 800052da <namei>
    80006d52:	84aa                	mv	s1,a0
    80006d54:	c131                	beqz	a0,80006d98 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006d56:	ffffe097          	auipc	ra,0xffffe
    80006d5a:	dce080e7          	jalr	-562(ra) # 80004b24 <ilock>
  if(ip->type != T_DIR){
    80006d5e:	04449703          	lh	a4,68(s1)
    80006d62:	4785                	li	a5,1
    80006d64:	04f71063          	bne	a4,a5,80006da4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006d68:	8526                	mv	a0,s1
    80006d6a:	ffffe097          	auipc	ra,0xffffe
    80006d6e:	e7c080e7          	jalr	-388(ra) # 80004be6 <iunlock>
  iput(p->cwd);
    80006d72:	18093503          	ld	a0,384(s2)
    80006d76:	ffffe097          	auipc	ra,0xffffe
    80006d7a:	f68080e7          	jalr	-152(ra) # 80004cde <iput>
  end_op();
    80006d7e:	ffffe097          	auipc	ra,0xffffe
    80006d82:	7f8080e7          	jalr	2040(ra) # 80005576 <end_op>
  p->cwd = ip;
    80006d86:	18993023          	sd	s1,384(s2)
  return 0;
    80006d8a:	4501                	li	a0,0
}
    80006d8c:	60ea                	ld	ra,152(sp)
    80006d8e:	644a                	ld	s0,144(sp)
    80006d90:	64aa                	ld	s1,136(sp)
    80006d92:	690a                	ld	s2,128(sp)
    80006d94:	610d                	addi	sp,sp,160
    80006d96:	8082                	ret
    end_op();
    80006d98:	ffffe097          	auipc	ra,0xffffe
    80006d9c:	7de080e7          	jalr	2014(ra) # 80005576 <end_op>
    return -1;
    80006da0:	557d                	li	a0,-1
    80006da2:	b7ed                	j	80006d8c <sys_chdir+0x7a>
    iunlockput(ip);
    80006da4:	8526                	mv	a0,s1
    80006da6:	ffffe097          	auipc	ra,0xffffe
    80006daa:	fe0080e7          	jalr	-32(ra) # 80004d86 <iunlockput>
    end_op();
    80006dae:	ffffe097          	auipc	ra,0xffffe
    80006db2:	7c8080e7          	jalr	1992(ra) # 80005576 <end_op>
    return -1;
    80006db6:	557d                	li	a0,-1
    80006db8:	bfd1                	j	80006d8c <sys_chdir+0x7a>

0000000080006dba <sys_exec>:

uint64
sys_exec(void)
{
    80006dba:	7145                	addi	sp,sp,-464
    80006dbc:	e786                	sd	ra,456(sp)
    80006dbe:	e3a2                	sd	s0,448(sp)
    80006dc0:	ff26                	sd	s1,440(sp)
    80006dc2:	fb4a                	sd	s2,432(sp)
    80006dc4:	f74e                	sd	s3,424(sp)
    80006dc6:	f352                	sd	s4,416(sp)
    80006dc8:	ef56                	sd	s5,408(sp)
    80006dca:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006dcc:	08000613          	li	a2,128
    80006dd0:	f4040593          	addi	a1,s0,-192
    80006dd4:	4501                	li	a0,0
    80006dd6:	ffffd097          	auipc	ra,0xffffd
    80006dda:	174080e7          	jalr	372(ra) # 80003f4a <argstr>
    return -1;
    80006dde:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006de0:	0c054a63          	bltz	a0,80006eb4 <sys_exec+0xfa>
    80006de4:	e3840593          	addi	a1,s0,-456
    80006de8:	4505                	li	a0,1
    80006dea:	ffffd097          	auipc	ra,0xffffd
    80006dee:	13e080e7          	jalr	318(ra) # 80003f28 <argaddr>
    80006df2:	0c054163          	bltz	a0,80006eb4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006df6:	10000613          	li	a2,256
    80006dfa:	4581                	li	a1,0
    80006dfc:	e4040513          	addi	a0,s0,-448
    80006e00:	ffffa097          	auipc	ra,0xffffa
    80006e04:	ee0080e7          	jalr	-288(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006e08:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006e0c:	89a6                	mv	s3,s1
    80006e0e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006e10:	02000a13          	li	s4,32
    80006e14:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006e18:	00391513          	slli	a0,s2,0x3
    80006e1c:	e3040593          	addi	a1,s0,-464
    80006e20:	e3843783          	ld	a5,-456(s0)
    80006e24:	953e                	add	a0,a0,a5
    80006e26:	ffffd097          	auipc	ra,0xffffd
    80006e2a:	046080e7          	jalr	70(ra) # 80003e6c <fetchaddr>
    80006e2e:	02054a63          	bltz	a0,80006e62 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006e32:	e3043783          	ld	a5,-464(s0)
    80006e36:	c3b9                	beqz	a5,80006e7c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006e38:	ffffa097          	auipc	ra,0xffffa
    80006e3c:	cbc080e7          	jalr	-836(ra) # 80000af4 <kalloc>
    80006e40:	85aa                	mv	a1,a0
    80006e42:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006e46:	cd11                	beqz	a0,80006e62 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006e48:	6605                	lui	a2,0x1
    80006e4a:	e3043503          	ld	a0,-464(s0)
    80006e4e:	ffffd097          	auipc	ra,0xffffd
    80006e52:	070080e7          	jalr	112(ra) # 80003ebe <fetchstr>
    80006e56:	00054663          	bltz	a0,80006e62 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006e5a:	0905                	addi	s2,s2,1
    80006e5c:	09a1                	addi	s3,s3,8
    80006e5e:	fb491be3          	bne	s2,s4,80006e14 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e62:	10048913          	addi	s2,s1,256
    80006e66:	6088                	ld	a0,0(s1)
    80006e68:	c529                	beqz	a0,80006eb2 <sys_exec+0xf8>
    kfree(argv[i]);
    80006e6a:	ffffa097          	auipc	ra,0xffffa
    80006e6e:	b8e080e7          	jalr	-1138(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e72:	04a1                	addi	s1,s1,8
    80006e74:	ff2499e3          	bne	s1,s2,80006e66 <sys_exec+0xac>
  return -1;
    80006e78:	597d                	li	s2,-1
    80006e7a:	a82d                	j	80006eb4 <sys_exec+0xfa>
      argv[i] = 0;
    80006e7c:	0a8e                	slli	s5,s5,0x3
    80006e7e:	fc040793          	addi	a5,s0,-64
    80006e82:	9abe                	add	s5,s5,a5
    80006e84:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006e88:	e4040593          	addi	a1,s0,-448
    80006e8c:	f4040513          	addi	a0,s0,-192
    80006e90:	fffff097          	auipc	ra,0xfffff
    80006e94:	192080e7          	jalr	402(ra) # 80006022 <exec>
    80006e98:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e9a:	10048993          	addi	s3,s1,256
    80006e9e:	6088                	ld	a0,0(s1)
    80006ea0:	c911                	beqz	a0,80006eb4 <sys_exec+0xfa>
    kfree(argv[i]);
    80006ea2:	ffffa097          	auipc	ra,0xffffa
    80006ea6:	b56080e7          	jalr	-1194(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006eaa:	04a1                	addi	s1,s1,8
    80006eac:	ff3499e3          	bne	s1,s3,80006e9e <sys_exec+0xe4>
    80006eb0:	a011                	j	80006eb4 <sys_exec+0xfa>
  return -1;
    80006eb2:	597d                	li	s2,-1
}
    80006eb4:	854a                	mv	a0,s2
    80006eb6:	60be                	ld	ra,456(sp)
    80006eb8:	641e                	ld	s0,448(sp)
    80006eba:	74fa                	ld	s1,440(sp)
    80006ebc:	795a                	ld	s2,432(sp)
    80006ebe:	79ba                	ld	s3,424(sp)
    80006ec0:	7a1a                	ld	s4,416(sp)
    80006ec2:	6afa                	ld	s5,408(sp)
    80006ec4:	6179                	addi	sp,sp,464
    80006ec6:	8082                	ret

0000000080006ec8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006ec8:	7139                	addi	sp,sp,-64
    80006eca:	fc06                	sd	ra,56(sp)
    80006ecc:	f822                	sd	s0,48(sp)
    80006ece:	f426                	sd	s1,40(sp)
    80006ed0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006ed2:	ffffb097          	auipc	ra,0xffffb
    80006ed6:	d2e080e7          	jalr	-722(ra) # 80001c00 <myproc>
    80006eda:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006edc:	fd840593          	addi	a1,s0,-40
    80006ee0:	4501                	li	a0,0
    80006ee2:	ffffd097          	auipc	ra,0xffffd
    80006ee6:	046080e7          	jalr	70(ra) # 80003f28 <argaddr>
    return -1;
    80006eea:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006eec:	0e054263          	bltz	a0,80006fd0 <sys_pipe+0x108>
  if(pipealloc(&rf, &wf) < 0)
    80006ef0:	fc840593          	addi	a1,s0,-56
    80006ef4:	fd040513          	addi	a0,s0,-48
    80006ef8:	fffff097          	auipc	ra,0xfffff
    80006efc:	dfa080e7          	jalr	-518(ra) # 80005cf2 <pipealloc>
    return -1;
    80006f00:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006f02:	0c054763          	bltz	a0,80006fd0 <sys_pipe+0x108>
  fd0 = -1;
    80006f06:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006f0a:	fd043503          	ld	a0,-48(s0)
    80006f0e:	fffff097          	auipc	ra,0xfffff
    80006f12:	506080e7          	jalr	1286(ra) # 80006414 <fdalloc>
    80006f16:	fca42223          	sw	a0,-60(s0)
    80006f1a:	08054e63          	bltz	a0,80006fb6 <sys_pipe+0xee>
    80006f1e:	fc843503          	ld	a0,-56(s0)
    80006f22:	fffff097          	auipc	ra,0xfffff
    80006f26:	4f2080e7          	jalr	1266(ra) # 80006414 <fdalloc>
    80006f2a:	fca42023          	sw	a0,-64(s0)
    80006f2e:	06054a63          	bltz	a0,80006fa2 <sys_pipe+0xda>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006f32:	4691                	li	a3,4
    80006f34:	fc440613          	addi	a2,s0,-60
    80006f38:	fd843583          	ld	a1,-40(s0)
    80006f3c:	60c8                	ld	a0,128(s1)
    80006f3e:	ffffa097          	auipc	ra,0xffffa
    80006f42:	73c080e7          	jalr	1852(ra) # 8000167a <copyout>
    80006f46:	02054063          	bltz	a0,80006f66 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006f4a:	4691                	li	a3,4
    80006f4c:	fc040613          	addi	a2,s0,-64
    80006f50:	fd843583          	ld	a1,-40(s0)
    80006f54:	0591                	addi	a1,a1,4
    80006f56:	60c8                	ld	a0,128(s1)
    80006f58:	ffffa097          	auipc	ra,0xffffa
    80006f5c:	722080e7          	jalr	1826(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006f60:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006f62:	06055763          	bgez	a0,80006fd0 <sys_pipe+0x108>
    p->ofile[fd0] = 0;
    80006f66:	fc442783          	lw	a5,-60(s0)
    80006f6a:	02078793          	addi	a5,a5,32
    80006f6e:	078e                	slli	a5,a5,0x3
    80006f70:	97a6                	add	a5,a5,s1
    80006f72:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006f76:	fc042503          	lw	a0,-64(s0)
    80006f7a:	02050513          	addi	a0,a0,32
    80006f7e:	050e                	slli	a0,a0,0x3
    80006f80:	9526                	add	a0,a0,s1
    80006f82:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006f86:	fd043503          	ld	a0,-48(s0)
    80006f8a:	fffff097          	auipc	ra,0xfffff
    80006f8e:	a38080e7          	jalr	-1480(ra) # 800059c2 <fileclose>
    fileclose(wf);
    80006f92:	fc843503          	ld	a0,-56(s0)
    80006f96:	fffff097          	auipc	ra,0xfffff
    80006f9a:	a2c080e7          	jalr	-1492(ra) # 800059c2 <fileclose>
    return -1;
    80006f9e:	57fd                	li	a5,-1
    80006fa0:	a805                	j	80006fd0 <sys_pipe+0x108>
    if(fd0 >= 0)
    80006fa2:	fc442783          	lw	a5,-60(s0)
    80006fa6:	0007c863          	bltz	a5,80006fb6 <sys_pipe+0xee>
      p->ofile[fd0] = 0;
    80006faa:	02078513          	addi	a0,a5,32
    80006fae:	050e                	slli	a0,a0,0x3
    80006fb0:	9526                	add	a0,a0,s1
    80006fb2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006fb6:	fd043503          	ld	a0,-48(s0)
    80006fba:	fffff097          	auipc	ra,0xfffff
    80006fbe:	a08080e7          	jalr	-1528(ra) # 800059c2 <fileclose>
    fileclose(wf);
    80006fc2:	fc843503          	ld	a0,-56(s0)
    80006fc6:	fffff097          	auipc	ra,0xfffff
    80006fca:	9fc080e7          	jalr	-1540(ra) # 800059c2 <fileclose>
    return -1;
    80006fce:	57fd                	li	a5,-1
}
    80006fd0:	853e                	mv	a0,a5
    80006fd2:	70e2                	ld	ra,56(sp)
    80006fd4:	7442                	ld	s0,48(sp)
    80006fd6:	74a2                	ld	s1,40(sp)
    80006fd8:	6121                	addi	sp,sp,64
    80006fda:	8082                	ret
    80006fdc:	0000                	unimp
	...

0000000080006fe0 <kernelvec>:
    80006fe0:	7111                	addi	sp,sp,-256
    80006fe2:	e006                	sd	ra,0(sp)
    80006fe4:	e40a                	sd	sp,8(sp)
    80006fe6:	e80e                	sd	gp,16(sp)
    80006fe8:	ec12                	sd	tp,24(sp)
    80006fea:	f016                	sd	t0,32(sp)
    80006fec:	f41a                	sd	t1,40(sp)
    80006fee:	f81e                	sd	t2,48(sp)
    80006ff0:	fc22                	sd	s0,56(sp)
    80006ff2:	e0a6                	sd	s1,64(sp)
    80006ff4:	e4aa                	sd	a0,72(sp)
    80006ff6:	e8ae                	sd	a1,80(sp)
    80006ff8:	ecb2                	sd	a2,88(sp)
    80006ffa:	f0b6                	sd	a3,96(sp)
    80006ffc:	f4ba                	sd	a4,104(sp)
    80006ffe:	f8be                	sd	a5,112(sp)
    80007000:	fcc2                	sd	a6,120(sp)
    80007002:	e146                	sd	a7,128(sp)
    80007004:	e54a                	sd	s2,136(sp)
    80007006:	e94e                	sd	s3,144(sp)
    80007008:	ed52                	sd	s4,152(sp)
    8000700a:	f156                	sd	s5,160(sp)
    8000700c:	f55a                	sd	s6,168(sp)
    8000700e:	f95e                	sd	s7,176(sp)
    80007010:	fd62                	sd	s8,184(sp)
    80007012:	e1e6                	sd	s9,192(sp)
    80007014:	e5ea                	sd	s10,200(sp)
    80007016:	e9ee                	sd	s11,208(sp)
    80007018:	edf2                	sd	t3,216(sp)
    8000701a:	f1f6                	sd	t4,224(sp)
    8000701c:	f5fa                	sd	t5,232(sp)
    8000701e:	f9fe                	sd	t6,240(sp)
    80007020:	cedfc0ef          	jal	ra,80003d0c <kerneltrap>
    80007024:	6082                	ld	ra,0(sp)
    80007026:	6122                	ld	sp,8(sp)
    80007028:	61c2                	ld	gp,16(sp)
    8000702a:	7282                	ld	t0,32(sp)
    8000702c:	7322                	ld	t1,40(sp)
    8000702e:	73c2                	ld	t2,48(sp)
    80007030:	7462                	ld	s0,56(sp)
    80007032:	6486                	ld	s1,64(sp)
    80007034:	6526                	ld	a0,72(sp)
    80007036:	65c6                	ld	a1,80(sp)
    80007038:	6666                	ld	a2,88(sp)
    8000703a:	7686                	ld	a3,96(sp)
    8000703c:	7726                	ld	a4,104(sp)
    8000703e:	77c6                	ld	a5,112(sp)
    80007040:	7866                	ld	a6,120(sp)
    80007042:	688a                	ld	a7,128(sp)
    80007044:	692a                	ld	s2,136(sp)
    80007046:	69ca                	ld	s3,144(sp)
    80007048:	6a6a                	ld	s4,152(sp)
    8000704a:	7a8a                	ld	s5,160(sp)
    8000704c:	7b2a                	ld	s6,168(sp)
    8000704e:	7bca                	ld	s7,176(sp)
    80007050:	7c6a                	ld	s8,184(sp)
    80007052:	6c8e                	ld	s9,192(sp)
    80007054:	6d2e                	ld	s10,200(sp)
    80007056:	6dce                	ld	s11,208(sp)
    80007058:	6e6e                	ld	t3,216(sp)
    8000705a:	7e8e                	ld	t4,224(sp)
    8000705c:	7f2e                	ld	t5,232(sp)
    8000705e:	7fce                	ld	t6,240(sp)
    80007060:	6111                	addi	sp,sp,256
    80007062:	10200073          	sret
    80007066:	00000013          	nop
    8000706a:	00000013          	nop
    8000706e:	0001                	nop

0000000080007070 <timervec>:
    80007070:	34051573          	csrrw	a0,mscratch,a0
    80007074:	e10c                	sd	a1,0(a0)
    80007076:	e510                	sd	a2,8(a0)
    80007078:	e914                	sd	a3,16(a0)
    8000707a:	6d0c                	ld	a1,24(a0)
    8000707c:	7110                	ld	a2,32(a0)
    8000707e:	6194                	ld	a3,0(a1)
    80007080:	96b2                	add	a3,a3,a2
    80007082:	e194                	sd	a3,0(a1)
    80007084:	4589                	li	a1,2
    80007086:	14459073          	csrw	sip,a1
    8000708a:	6914                	ld	a3,16(a0)
    8000708c:	6510                	ld	a2,8(a0)
    8000708e:	610c                	ld	a1,0(a0)
    80007090:	34051573          	csrrw	a0,mscratch,a0
    80007094:	30200073          	mret
	...

000000008000709a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000709a:	1141                	addi	sp,sp,-16
    8000709c:	e422                	sd	s0,8(sp)
    8000709e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800070a0:	0c0007b7          	lui	a5,0xc000
    800070a4:	4705                	li	a4,1
    800070a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800070a8:	c3d8                	sw	a4,4(a5)
}
    800070aa:	6422                	ld	s0,8(sp)
    800070ac:	0141                	addi	sp,sp,16
    800070ae:	8082                	ret

00000000800070b0 <plicinithart>:

void
plicinithart(void)
{
    800070b0:	1141                	addi	sp,sp,-16
    800070b2:	e406                	sd	ra,8(sp)
    800070b4:	e022                	sd	s0,0(sp)
    800070b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800070b8:	ffffb097          	auipc	ra,0xffffb
    800070bc:	b0c080e7          	jalr	-1268(ra) # 80001bc4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800070c0:	0085171b          	slliw	a4,a0,0x8
    800070c4:	0c0027b7          	lui	a5,0xc002
    800070c8:	97ba                	add	a5,a5,a4
    800070ca:	40200713          	li	a4,1026
    800070ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800070d2:	00d5151b          	slliw	a0,a0,0xd
    800070d6:	0c2017b7          	lui	a5,0xc201
    800070da:	953e                	add	a0,a0,a5
    800070dc:	00052023          	sw	zero,0(a0)
}
    800070e0:	60a2                	ld	ra,8(sp)
    800070e2:	6402                	ld	s0,0(sp)
    800070e4:	0141                	addi	sp,sp,16
    800070e6:	8082                	ret

00000000800070e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800070e8:	1141                	addi	sp,sp,-16
    800070ea:	e406                	sd	ra,8(sp)
    800070ec:	e022                	sd	s0,0(sp)
    800070ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800070f0:	ffffb097          	auipc	ra,0xffffb
    800070f4:	ad4080e7          	jalr	-1324(ra) # 80001bc4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800070f8:	00d5179b          	slliw	a5,a0,0xd
    800070fc:	0c201537          	lui	a0,0xc201
    80007100:	953e                	add	a0,a0,a5
  return irq;
}
    80007102:	4148                	lw	a0,4(a0)
    80007104:	60a2                	ld	ra,8(sp)
    80007106:	6402                	ld	s0,0(sp)
    80007108:	0141                	addi	sp,sp,16
    8000710a:	8082                	ret

000000008000710c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000710c:	1101                	addi	sp,sp,-32
    8000710e:	ec06                	sd	ra,24(sp)
    80007110:	e822                	sd	s0,16(sp)
    80007112:	e426                	sd	s1,8(sp)
    80007114:	1000                	addi	s0,sp,32
    80007116:	84aa                	mv	s1,a0
  int hart = cpuid();
    80007118:	ffffb097          	auipc	ra,0xffffb
    8000711c:	aac080e7          	jalr	-1364(ra) # 80001bc4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80007120:	00d5151b          	slliw	a0,a0,0xd
    80007124:	0c2017b7          	lui	a5,0xc201
    80007128:	97aa                	add	a5,a5,a0
    8000712a:	c3c4                	sw	s1,4(a5)
}
    8000712c:	60e2                	ld	ra,24(sp)
    8000712e:	6442                	ld	s0,16(sp)
    80007130:	64a2                	ld	s1,8(sp)
    80007132:	6105                	addi	sp,sp,32
    80007134:	8082                	ret

0000000080007136 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80007136:	1141                	addi	sp,sp,-16
    80007138:	e406                	sd	ra,8(sp)
    8000713a:	e022                	sd	s0,0(sp)
    8000713c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000713e:	479d                	li	a5,7
    80007140:	06a7c963          	blt	a5,a0,800071b2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80007144:	0001e797          	auipc	a5,0x1e
    80007148:	ebc78793          	addi	a5,a5,-324 # 80025000 <disk>
    8000714c:	00a78733          	add	a4,a5,a0
    80007150:	6789                	lui	a5,0x2
    80007152:	97ba                	add	a5,a5,a4
    80007154:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80007158:	e7ad                	bnez	a5,800071c2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000715a:	00451793          	slli	a5,a0,0x4
    8000715e:	00020717          	auipc	a4,0x20
    80007162:	ea270713          	addi	a4,a4,-350 # 80027000 <disk+0x2000>
    80007166:	6314                	ld	a3,0(a4)
    80007168:	96be                	add	a3,a3,a5
    8000716a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000716e:	6314                	ld	a3,0(a4)
    80007170:	96be                	add	a3,a3,a5
    80007172:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80007176:	6314                	ld	a3,0(a4)
    80007178:	96be                	add	a3,a3,a5
    8000717a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000717e:	6318                	ld	a4,0(a4)
    80007180:	97ba                	add	a5,a5,a4
    80007182:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80007186:	0001e797          	auipc	a5,0x1e
    8000718a:	e7a78793          	addi	a5,a5,-390 # 80025000 <disk>
    8000718e:	97aa                	add	a5,a5,a0
    80007190:	6509                	lui	a0,0x2
    80007192:	953e                	add	a0,a0,a5
    80007194:	4785                	li	a5,1
    80007196:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000719a:	00020517          	auipc	a0,0x20
    8000719e:	e7e50513          	addi	a0,a0,-386 # 80027018 <disk+0x2018>
    800071a2:	ffffc097          	auipc	ra,0xffffc
    800071a6:	de4080e7          	jalr	-540(ra) # 80002f86 <wakeup>
}
    800071aa:	60a2                	ld	ra,8(sp)
    800071ac:	6402                	ld	s0,0(sp)
    800071ae:	0141                	addi	sp,sp,16
    800071b0:	8082                	ret
    panic("free_desc 1");
    800071b2:	00002517          	auipc	a0,0x2
    800071b6:	7d650513          	addi	a0,a0,2006 # 80009988 <syscalls+0x348>
    800071ba:	ffff9097          	auipc	ra,0xffff9
    800071be:	384080e7          	jalr	900(ra) # 8000053e <panic>
    panic("free_desc 2");
    800071c2:	00002517          	auipc	a0,0x2
    800071c6:	7d650513          	addi	a0,a0,2006 # 80009998 <syscalls+0x358>
    800071ca:	ffff9097          	auipc	ra,0xffff9
    800071ce:	374080e7          	jalr	884(ra) # 8000053e <panic>

00000000800071d2 <virtio_disk_init>:
{
    800071d2:	1101                	addi	sp,sp,-32
    800071d4:	ec06                	sd	ra,24(sp)
    800071d6:	e822                	sd	s0,16(sp)
    800071d8:	e426                	sd	s1,8(sp)
    800071da:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800071dc:	00002597          	auipc	a1,0x2
    800071e0:	7cc58593          	addi	a1,a1,1996 # 800099a8 <syscalls+0x368>
    800071e4:	00020517          	auipc	a0,0x20
    800071e8:	f4450513          	addi	a0,a0,-188 # 80027128 <disk+0x2128>
    800071ec:	ffffa097          	auipc	ra,0xffffa
    800071f0:	968080e7          	jalr	-1688(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800071f4:	100017b7          	lui	a5,0x10001
    800071f8:	4398                	lw	a4,0(a5)
    800071fa:	2701                	sext.w	a4,a4
    800071fc:	747277b7          	lui	a5,0x74727
    80007200:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80007204:	0ef71163          	bne	a4,a5,800072e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80007208:	100017b7          	lui	a5,0x10001
    8000720c:	43dc                	lw	a5,4(a5)
    8000720e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80007210:	4705                	li	a4,1
    80007212:	0ce79a63          	bne	a5,a4,800072e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80007216:	100017b7          	lui	a5,0x10001
    8000721a:	479c                	lw	a5,8(a5)
    8000721c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000721e:	4709                	li	a4,2
    80007220:	0ce79363          	bne	a5,a4,800072e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80007224:	100017b7          	lui	a5,0x10001
    80007228:	47d8                	lw	a4,12(a5)
    8000722a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000722c:	554d47b7          	lui	a5,0x554d4
    80007230:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80007234:	0af71963          	bne	a4,a5,800072e6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80007238:	100017b7          	lui	a5,0x10001
    8000723c:	4705                	li	a4,1
    8000723e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007240:	470d                	li	a4,3
    80007242:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80007244:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80007246:	c7ffe737          	lui	a4,0xc7ffe
    8000724a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    8000724e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80007250:	2701                	sext.w	a4,a4
    80007252:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007254:	472d                	li	a4,11
    80007256:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007258:	473d                	li	a4,15
    8000725a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000725c:	6705                	lui	a4,0x1
    8000725e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80007260:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80007264:	5bdc                	lw	a5,52(a5)
    80007266:	2781                	sext.w	a5,a5
  if(max == 0)
    80007268:	c7d9                	beqz	a5,800072f6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000726a:	471d                	li	a4,7
    8000726c:	08f77d63          	bgeu	a4,a5,80007306 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80007270:	100014b7          	lui	s1,0x10001
    80007274:	47a1                	li	a5,8
    80007276:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80007278:	6609                	lui	a2,0x2
    8000727a:	4581                	li	a1,0
    8000727c:	0001e517          	auipc	a0,0x1e
    80007280:	d8450513          	addi	a0,a0,-636 # 80025000 <disk>
    80007284:	ffffa097          	auipc	ra,0xffffa
    80007288:	a5c080e7          	jalr	-1444(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000728c:	0001e717          	auipc	a4,0x1e
    80007290:	d7470713          	addi	a4,a4,-652 # 80025000 <disk>
    80007294:	00c75793          	srli	a5,a4,0xc
    80007298:	2781                	sext.w	a5,a5
    8000729a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000729c:	00020797          	auipc	a5,0x20
    800072a0:	d6478793          	addi	a5,a5,-668 # 80027000 <disk+0x2000>
    800072a4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800072a6:	0001e717          	auipc	a4,0x1e
    800072aa:	dda70713          	addi	a4,a4,-550 # 80025080 <disk+0x80>
    800072ae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800072b0:	0001f717          	auipc	a4,0x1f
    800072b4:	d5070713          	addi	a4,a4,-688 # 80026000 <disk+0x1000>
    800072b8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800072ba:	4705                	li	a4,1
    800072bc:	00e78c23          	sb	a4,24(a5)
    800072c0:	00e78ca3          	sb	a4,25(a5)
    800072c4:	00e78d23          	sb	a4,26(a5)
    800072c8:	00e78da3          	sb	a4,27(a5)
    800072cc:	00e78e23          	sb	a4,28(a5)
    800072d0:	00e78ea3          	sb	a4,29(a5)
    800072d4:	00e78f23          	sb	a4,30(a5)
    800072d8:	00e78fa3          	sb	a4,31(a5)
}
    800072dc:	60e2                	ld	ra,24(sp)
    800072de:	6442                	ld	s0,16(sp)
    800072e0:	64a2                	ld	s1,8(sp)
    800072e2:	6105                	addi	sp,sp,32
    800072e4:	8082                	ret
    panic("could not find virtio disk");
    800072e6:	00002517          	auipc	a0,0x2
    800072ea:	6d250513          	addi	a0,a0,1746 # 800099b8 <syscalls+0x378>
    800072ee:	ffff9097          	auipc	ra,0xffff9
    800072f2:	250080e7          	jalr	592(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800072f6:	00002517          	auipc	a0,0x2
    800072fa:	6e250513          	addi	a0,a0,1762 # 800099d8 <syscalls+0x398>
    800072fe:	ffff9097          	auipc	ra,0xffff9
    80007302:	240080e7          	jalr	576(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80007306:	00002517          	auipc	a0,0x2
    8000730a:	6f250513          	addi	a0,a0,1778 # 800099f8 <syscalls+0x3b8>
    8000730e:	ffff9097          	auipc	ra,0xffff9
    80007312:	230080e7          	jalr	560(ra) # 8000053e <panic>

0000000080007316 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80007316:	7159                	addi	sp,sp,-112
    80007318:	f486                	sd	ra,104(sp)
    8000731a:	f0a2                	sd	s0,96(sp)
    8000731c:	eca6                	sd	s1,88(sp)
    8000731e:	e8ca                	sd	s2,80(sp)
    80007320:	e4ce                	sd	s3,72(sp)
    80007322:	e0d2                	sd	s4,64(sp)
    80007324:	fc56                	sd	s5,56(sp)
    80007326:	f85a                	sd	s6,48(sp)
    80007328:	f45e                	sd	s7,40(sp)
    8000732a:	f062                	sd	s8,32(sp)
    8000732c:	ec66                	sd	s9,24(sp)
    8000732e:	e86a                	sd	s10,16(sp)
    80007330:	1880                	addi	s0,sp,112
    80007332:	892a                	mv	s2,a0
    80007334:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80007336:	00c52c83          	lw	s9,12(a0)
    8000733a:	001c9c9b          	slliw	s9,s9,0x1
    8000733e:	1c82                	slli	s9,s9,0x20
    80007340:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007344:	00020517          	auipc	a0,0x20
    80007348:	de450513          	addi	a0,a0,-540 # 80027128 <disk+0x2128>
    8000734c:	ffffa097          	auipc	ra,0xffffa
    80007350:	898080e7          	jalr	-1896(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80007354:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007356:	4c21                	li	s8,8
      disk.free[i] = 0;
    80007358:	0001eb97          	auipc	s7,0x1e
    8000735c:	ca8b8b93          	addi	s7,s7,-856 # 80025000 <disk>
    80007360:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80007362:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80007364:	8a4e                	mv	s4,s3
    80007366:	a051                	j	800073ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80007368:	00fb86b3          	add	a3,s7,a5
    8000736c:	96da                	add	a3,a3,s6
    8000736e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80007372:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80007374:	0207c563          	bltz	a5,8000739e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80007378:	2485                	addiw	s1,s1,1
    8000737a:	0711                	addi	a4,a4,4
    8000737c:	25548063          	beq	s1,s5,800075bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80007380:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80007382:	00020697          	auipc	a3,0x20
    80007386:	c9668693          	addi	a3,a3,-874 # 80027018 <disk+0x2018>
    8000738a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000738c:	0006c583          	lbu	a1,0(a3)
    80007390:	fde1                	bnez	a1,80007368 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80007392:	2785                	addiw	a5,a5,1
    80007394:	0685                	addi	a3,a3,1
    80007396:	ff879be3          	bne	a5,s8,8000738c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000739a:	57fd                	li	a5,-1
    8000739c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000739e:	02905a63          	blez	s1,800073d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800073a2:	f9042503          	lw	a0,-112(s0)
    800073a6:	00000097          	auipc	ra,0x0
    800073aa:	d90080e7          	jalr	-624(ra) # 80007136 <free_desc>
      for(int j = 0; j < i; j++)
    800073ae:	4785                	li	a5,1
    800073b0:	0297d163          	bge	a5,s1,800073d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800073b4:	f9442503          	lw	a0,-108(s0)
    800073b8:	00000097          	auipc	ra,0x0
    800073bc:	d7e080e7          	jalr	-642(ra) # 80007136 <free_desc>
      for(int j = 0; j < i; j++)
    800073c0:	4789                	li	a5,2
    800073c2:	0097d863          	bge	a5,s1,800073d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800073c6:	f9842503          	lw	a0,-104(s0)
    800073ca:	00000097          	auipc	ra,0x0
    800073ce:	d6c080e7          	jalr	-660(ra) # 80007136 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800073d2:	00020597          	auipc	a1,0x20
    800073d6:	d5658593          	addi	a1,a1,-682 # 80027128 <disk+0x2128>
    800073da:	00020517          	auipc	a0,0x20
    800073de:	c3e50513          	addi	a0,a0,-962 # 80027018 <disk+0x2018>
    800073e2:	ffffc097          	auipc	ra,0xffffc
    800073e6:	83e080e7          	jalr	-1986(ra) # 80002c20 <sleep>
  for(int i = 0; i < 3; i++){
    800073ea:	f9040713          	addi	a4,s0,-112
    800073ee:	84ce                	mv	s1,s3
    800073f0:	bf41                	j	80007380 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800073f2:	20058713          	addi	a4,a1,512
    800073f6:	00471693          	slli	a3,a4,0x4
    800073fa:	0001e717          	auipc	a4,0x1e
    800073fe:	c0670713          	addi	a4,a4,-1018 # 80025000 <disk>
    80007402:	9736                	add	a4,a4,a3
    80007404:	4685                	li	a3,1
    80007406:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000740a:	20058713          	addi	a4,a1,512
    8000740e:	00471693          	slli	a3,a4,0x4
    80007412:	0001e717          	auipc	a4,0x1e
    80007416:	bee70713          	addi	a4,a4,-1042 # 80025000 <disk>
    8000741a:	9736                	add	a4,a4,a3
    8000741c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80007420:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80007424:	7679                	lui	a2,0xffffe
    80007426:	963e                	add	a2,a2,a5
    80007428:	00020697          	auipc	a3,0x20
    8000742c:	bd868693          	addi	a3,a3,-1064 # 80027000 <disk+0x2000>
    80007430:	6298                	ld	a4,0(a3)
    80007432:	9732                	add	a4,a4,a2
    80007434:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80007436:	6298                	ld	a4,0(a3)
    80007438:	9732                	add	a4,a4,a2
    8000743a:	4541                	li	a0,16
    8000743c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000743e:	6298                	ld	a4,0(a3)
    80007440:	9732                	add	a4,a4,a2
    80007442:	4505                	li	a0,1
    80007444:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80007448:	f9442703          	lw	a4,-108(s0)
    8000744c:	6288                	ld	a0,0(a3)
    8000744e:	962a                	add	a2,a2,a0
    80007450:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80007454:	0712                	slli	a4,a4,0x4
    80007456:	6290                	ld	a2,0(a3)
    80007458:	963a                	add	a2,a2,a4
    8000745a:	05890513          	addi	a0,s2,88
    8000745e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80007460:	6294                	ld	a3,0(a3)
    80007462:	96ba                	add	a3,a3,a4
    80007464:	40000613          	li	a2,1024
    80007468:	c690                	sw	a2,8(a3)
  if(write)
    8000746a:	140d0063          	beqz	s10,800075aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000746e:	00020697          	auipc	a3,0x20
    80007472:	b926b683          	ld	a3,-1134(a3) # 80027000 <disk+0x2000>
    80007476:	96ba                	add	a3,a3,a4
    80007478:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000747c:	0001e817          	auipc	a6,0x1e
    80007480:	b8480813          	addi	a6,a6,-1148 # 80025000 <disk>
    80007484:	00020517          	auipc	a0,0x20
    80007488:	b7c50513          	addi	a0,a0,-1156 # 80027000 <disk+0x2000>
    8000748c:	6114                	ld	a3,0(a0)
    8000748e:	96ba                	add	a3,a3,a4
    80007490:	00c6d603          	lhu	a2,12(a3)
    80007494:	00166613          	ori	a2,a2,1
    80007498:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000749c:	f9842683          	lw	a3,-104(s0)
    800074a0:	6110                	ld	a2,0(a0)
    800074a2:	9732                	add	a4,a4,a2
    800074a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800074a8:	20058613          	addi	a2,a1,512
    800074ac:	0612                	slli	a2,a2,0x4
    800074ae:	9642                	add	a2,a2,a6
    800074b0:	577d                	li	a4,-1
    800074b2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800074b6:	00469713          	slli	a4,a3,0x4
    800074ba:	6114                	ld	a3,0(a0)
    800074bc:	96ba                	add	a3,a3,a4
    800074be:	03078793          	addi	a5,a5,48
    800074c2:	97c2                	add	a5,a5,a6
    800074c4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800074c6:	611c                	ld	a5,0(a0)
    800074c8:	97ba                	add	a5,a5,a4
    800074ca:	4685                	li	a3,1
    800074cc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800074ce:	611c                	ld	a5,0(a0)
    800074d0:	97ba                	add	a5,a5,a4
    800074d2:	4809                	li	a6,2
    800074d4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800074d8:	611c                	ld	a5,0(a0)
    800074da:	973e                	add	a4,a4,a5
    800074dc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800074e0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800074e4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800074e8:	6518                	ld	a4,8(a0)
    800074ea:	00275783          	lhu	a5,2(a4)
    800074ee:	8b9d                	andi	a5,a5,7
    800074f0:	0786                	slli	a5,a5,0x1
    800074f2:	97ba                	add	a5,a5,a4
    800074f4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800074f8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800074fc:	6518                	ld	a4,8(a0)
    800074fe:	00275783          	lhu	a5,2(a4)
    80007502:	2785                	addiw	a5,a5,1
    80007504:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80007508:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000750c:	100017b7          	lui	a5,0x10001
    80007510:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80007514:	00492703          	lw	a4,4(s2)
    80007518:	4785                	li	a5,1
    8000751a:	02f71163          	bne	a4,a5,8000753c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000751e:	00020997          	auipc	s3,0x20
    80007522:	c0a98993          	addi	s3,s3,-1014 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    80007526:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80007528:	85ce                	mv	a1,s3
    8000752a:	854a                	mv	a0,s2
    8000752c:	ffffb097          	auipc	ra,0xffffb
    80007530:	6f4080e7          	jalr	1780(ra) # 80002c20 <sleep>
  while(b->disk == 1) {
    80007534:	00492783          	lw	a5,4(s2)
    80007538:	fe9788e3          	beq	a5,s1,80007528 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000753c:	f9042903          	lw	s2,-112(s0)
    80007540:	20090793          	addi	a5,s2,512
    80007544:	00479713          	slli	a4,a5,0x4
    80007548:	0001e797          	auipc	a5,0x1e
    8000754c:	ab878793          	addi	a5,a5,-1352 # 80025000 <disk>
    80007550:	97ba                	add	a5,a5,a4
    80007552:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80007556:	00020997          	auipc	s3,0x20
    8000755a:	aaa98993          	addi	s3,s3,-1366 # 80027000 <disk+0x2000>
    8000755e:	00491713          	slli	a4,s2,0x4
    80007562:	0009b783          	ld	a5,0(s3)
    80007566:	97ba                	add	a5,a5,a4
    80007568:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000756c:	854a                	mv	a0,s2
    8000756e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80007572:	00000097          	auipc	ra,0x0
    80007576:	bc4080e7          	jalr	-1084(ra) # 80007136 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000757a:	8885                	andi	s1,s1,1
    8000757c:	f0ed                	bnez	s1,8000755e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000757e:	00020517          	auipc	a0,0x20
    80007582:	baa50513          	addi	a0,a0,-1110 # 80027128 <disk+0x2128>
    80007586:	ffff9097          	auipc	ra,0xffff9
    8000758a:	712080e7          	jalr	1810(ra) # 80000c98 <release>
}
    8000758e:	70a6                	ld	ra,104(sp)
    80007590:	7406                	ld	s0,96(sp)
    80007592:	64e6                	ld	s1,88(sp)
    80007594:	6946                	ld	s2,80(sp)
    80007596:	69a6                	ld	s3,72(sp)
    80007598:	6a06                	ld	s4,64(sp)
    8000759a:	7ae2                	ld	s5,56(sp)
    8000759c:	7b42                	ld	s6,48(sp)
    8000759e:	7ba2                	ld	s7,40(sp)
    800075a0:	7c02                	ld	s8,32(sp)
    800075a2:	6ce2                	ld	s9,24(sp)
    800075a4:	6d42                	ld	s10,16(sp)
    800075a6:	6165                	addi	sp,sp,112
    800075a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800075aa:	00020697          	auipc	a3,0x20
    800075ae:	a566b683          	ld	a3,-1450(a3) # 80027000 <disk+0x2000>
    800075b2:	96ba                	add	a3,a3,a4
    800075b4:	4609                	li	a2,2
    800075b6:	00c69623          	sh	a2,12(a3)
    800075ba:	b5c9                	j	8000747c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800075bc:	f9042583          	lw	a1,-112(s0)
    800075c0:	20058793          	addi	a5,a1,512
    800075c4:	0792                	slli	a5,a5,0x4
    800075c6:	0001e517          	auipc	a0,0x1e
    800075ca:	ae250513          	addi	a0,a0,-1310 # 800250a8 <disk+0xa8>
    800075ce:	953e                	add	a0,a0,a5
  if(write)
    800075d0:	e20d11e3          	bnez	s10,800073f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800075d4:	20058713          	addi	a4,a1,512
    800075d8:	00471693          	slli	a3,a4,0x4
    800075dc:	0001e717          	auipc	a4,0x1e
    800075e0:	a2470713          	addi	a4,a4,-1500 # 80025000 <disk>
    800075e4:	9736                	add	a4,a4,a3
    800075e6:	0a072423          	sw	zero,168(a4)
    800075ea:	b505                	j	8000740a <virtio_disk_rw+0xf4>

00000000800075ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800075ec:	1101                	addi	sp,sp,-32
    800075ee:	ec06                	sd	ra,24(sp)
    800075f0:	e822                	sd	s0,16(sp)
    800075f2:	e426                	sd	s1,8(sp)
    800075f4:	e04a                	sd	s2,0(sp)
    800075f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800075f8:	00020517          	auipc	a0,0x20
    800075fc:	b3050513          	addi	a0,a0,-1232 # 80027128 <disk+0x2128>
    80007600:	ffff9097          	auipc	ra,0xffff9
    80007604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80007608:	10001737          	lui	a4,0x10001
    8000760c:	533c                	lw	a5,96(a4)
    8000760e:	8b8d                	andi	a5,a5,3
    80007610:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007612:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007616:	00020797          	auipc	a5,0x20
    8000761a:	9ea78793          	addi	a5,a5,-1558 # 80027000 <disk+0x2000>
    8000761e:	6b94                	ld	a3,16(a5)
    80007620:	0207d703          	lhu	a4,32(a5)
    80007624:	0026d783          	lhu	a5,2(a3)
    80007628:	06f70163          	beq	a4,a5,8000768a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000762c:	0001e917          	auipc	s2,0x1e
    80007630:	9d490913          	addi	s2,s2,-1580 # 80025000 <disk>
    80007634:	00020497          	auipc	s1,0x20
    80007638:	9cc48493          	addi	s1,s1,-1588 # 80027000 <disk+0x2000>
    __sync_synchronize();
    8000763c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007640:	6898                	ld	a4,16(s1)
    80007642:	0204d783          	lhu	a5,32(s1)
    80007646:	8b9d                	andi	a5,a5,7
    80007648:	078e                	slli	a5,a5,0x3
    8000764a:	97ba                	add	a5,a5,a4
    8000764c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000764e:	20078713          	addi	a4,a5,512
    80007652:	0712                	slli	a4,a4,0x4
    80007654:	974a                	add	a4,a4,s2
    80007656:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000765a:	e731                	bnez	a4,800076a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000765c:	20078793          	addi	a5,a5,512
    80007660:	0792                	slli	a5,a5,0x4
    80007662:	97ca                	add	a5,a5,s2
    80007664:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007666:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000766a:	ffffc097          	auipc	ra,0xffffc
    8000766e:	91c080e7          	jalr	-1764(ra) # 80002f86 <wakeup>

    disk.used_idx += 1;
    80007672:	0204d783          	lhu	a5,32(s1)
    80007676:	2785                	addiw	a5,a5,1
    80007678:	17c2                	slli	a5,a5,0x30
    8000767a:	93c1                	srli	a5,a5,0x30
    8000767c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007680:	6898                	ld	a4,16(s1)
    80007682:	00275703          	lhu	a4,2(a4)
    80007686:	faf71be3          	bne	a4,a5,8000763c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000768a:	00020517          	auipc	a0,0x20
    8000768e:	a9e50513          	addi	a0,a0,-1378 # 80027128 <disk+0x2128>
    80007692:	ffff9097          	auipc	ra,0xffff9
    80007696:	606080e7          	jalr	1542(ra) # 80000c98 <release>
}
    8000769a:	60e2                	ld	ra,24(sp)
    8000769c:	6442                	ld	s0,16(sp)
    8000769e:	64a2                	ld	s1,8(sp)
    800076a0:	6902                	ld	s2,0(sp)
    800076a2:	6105                	addi	sp,sp,32
    800076a4:	8082                	ret
      panic("virtio_disk_intr status");
    800076a6:	00002517          	auipc	a0,0x2
    800076aa:	37250513          	addi	a0,a0,882 # 80009a18 <syscalls+0x3d8>
    800076ae:	ffff9097          	auipc	ra,0xffff9
    800076b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>

00000000800076b6 <cas>:
    800076b6:	100522af          	lr.w	t0,(a0)
    800076ba:	00b29563          	bne	t0,a1,800076c4 <fail>
    800076be:	18c5252f          	sc.w	a0,a2,(a0)
    800076c2:	8082                	ret

00000000800076c4 <fail>:
    800076c4:	4505                	li	a0,1
    800076c6:	8082                	ret
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
