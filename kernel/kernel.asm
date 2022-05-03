
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
    80000068:	fcc78793          	addi	a5,a5,-52 # 80007030 <timervec>
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
    80000130:	79a080e7          	jalr	1946(ra) # 800038c6 <either_copyin>
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
    800001c8:	a00080e7          	jalr	-1536(ra) # 80001bc4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	a10080e7          	jalr	-1520(ra) # 80002be4 <sleep>
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
    80000214:	660080e7          	jalr	1632(ra) # 80003870 <either_copyout>
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
    800002f6:	62a080e7          	jalr	1578(ra) # 8000391c <procdump>
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
    8000044a:	b04080e7          	jalr	-1276(ra) # 80002f4a <wakeup>
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
    800008a4:	6aa080e7          	jalr	1706(ra) # 80002f4a <wakeup>
    
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
    80000930:	2b8080e7          	jalr	696(ra) # 80002be4 <sleep>
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
    80000b82:	01a080e7          	jalr	26(ra) # 80001b98 <mycpu>
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
    80000bb4:	fe8080e7          	jalr	-24(ra) # 80001b98 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	fdc080e7          	jalr	-36(ra) # 80001b98 <mycpu>
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
    80000bd8:	fc4080e7          	jalr	-60(ra) # 80001b98 <mycpu>
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
    80000c18:	f84080e7          	jalr	-124(ra) # 80001b98 <mycpu>
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
    80000c44:	f58080e7          	jalr	-168(ra) # 80001b98 <mycpu>
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
    80000e9a:	cf2080e7          	jalr	-782(ra) # 80001b88 <cpuid>
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
    80000eb6:	cd6080e7          	jalr	-810(ra) # 80001b88 <cpuid>
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
    80000ed8:	b88080e7          	jalr	-1144(ra) # 80003a5c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	194080e7          	jalr	404(ra) # 80007070 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	8f2080e7          	jalr	-1806(ra) # 800027d6 <scheduler>
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
    80000f50:	ad4080e7          	jalr	-1324(ra) # 80001a20 <procinit>
    trapinit();      // trap vectors
    80000f54:	00003097          	auipc	ra,0x3
    80000f58:	ae0080e7          	jalr	-1312(ra) # 80003a34 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00003097          	auipc	ra,0x3
    80000f60:	b00080e7          	jalr	-1280(ra) # 80003a5c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00006097          	auipc	ra,0x6
    80000f68:	0f6080e7          	jalr	246(ra) # 8000705a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00006097          	auipc	ra,0x6
    80000f70:	104080e7          	jalr	260(ra) # 80007070 <plicinithart>
    binit();         // buffer cache
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	2e4080e7          	jalr	740(ra) # 80004258 <binit>
    iinit();         // inode table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	974080e7          	jalr	-1676(ra) # 800048f0 <iinit>
    fileinit();      // file table
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	91e080e7          	jalr	-1762(ra) # 800058a2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00006097          	auipc	ra,0x6
    80000f90:	206080e7          	jalr	518(ra) # 80007192 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	118080e7          	jalr	280(ra) # 800020ac <userinit>
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
    8000124c:	742080e7          	jalr	1858(ra) # 8000198a <proc_mapstacks>
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
    8000188e:	dec080e7          	jalr	-532(ra) # 80007676 <cas>
    80001892:	e51d                	bnez	a0,800018c0 <add_proc_to_list+0x7a>
  {
    p->prev_proc = tail;
    80001894:	0724a223          	sw	s2,100(s1)
    p->next_proc = -1;
    80001898:	57fd                	li	a5,-1
    8000189a:	d0bc                	sw	a5,96(s1)
    printf("&&&&&&&&&&&&&&&adding: %d,     prev:   %d,   next:  %d\n", p->proc_ind, p->prev_proc, p->next_proc);
    8000189c:	56fd                	li	a3,-1
    8000189e:	864a                	mv	a2,s2
    800018a0:	4cec                	lw	a1,92(s1)
    800018a2:	00008517          	auipc	a0,0x8
    800018a6:	93650513          	addi	a0,a0,-1738 # 800091d8 <digits+0x198>
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	cde080e7          	jalr	-802(ra) # 80000588 <printf>
    return 0;
    800018b2:	4501                	li	a0,0
  }
  return -1;
}
    800018b4:	60e2                	ld	ra,24(sp)
    800018b6:	6442                	ld	s0,16(sp)
    800018b8:	64a2                	ld	s1,8(sp)
    800018ba:	6902                	ld	s2,0(sp)
    800018bc:	6105                	addi	sp,sp,32
    800018be:	8082                	ret
  return -1;
    800018c0:	557d                	li	a0,-1
    800018c2:	bfcd                	j	800018b4 <add_proc_to_list+0x6e>

00000000800018c4 <remove_proc_from_list>:

// Ass2
int
remove_proc_from_list(int ind)
{
    800018c4:	1101                	addi	sp,sp,-32
    800018c6:	ec06                	sd	ra,24(sp)
    800018c8:	e822                	sd	s0,16(sp)
    800018ca:	e426                	sd	s1,8(sp)
    800018cc:	e04a                	sd	s2,0(sp)
    800018ce:	1000                	addi	s0,sp,32
    800018d0:	84aa                	mv	s1,a0
  struct proc *p = &proc[ind];

  printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);
    800018d2:	19800913          	li	s2,408
    800018d6:	032507b3          	mul	a5,a0,s2
    800018da:	00011917          	auipc	s2,0x11
    800018de:	e9690913          	addi	s2,s2,-362 # 80012770 <proc>
    800018e2:	993e                	add	s2,s2,a5
    800018e4:	06092683          	lw	a3,96(s2)
    800018e8:	06492603          	lw	a2,100(s2)
    800018ec:	85aa                	mv	a1,a0
    800018ee:	00008517          	auipc	a0,0x8
    800018f2:	92250513          	addi	a0,a0,-1758 # 80009210 <digits+0x1d0>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	c92080e7          	jalr	-878(ra) # 80000588 <printf>

  if (p->prev_proc == -1 && p->next_proc == -1)
    800018fe:	06093703          	ld	a4,96(s2)
    80001902:	57fd                	li	a5,-1
    return 1;  // Need to change head & tail.
    80001904:	4505                	li	a0,1
  if (p->prev_proc == -1 && p->next_proc == -1)
    80001906:	06f70863          	beq	a4,a5,80001976 <remove_proc_from_list+0xb2>
  
  if (p->prev_proc == -1)
    8000190a:	06492783          	lw	a5,100(s2)
    8000190e:	577d                	li	a4,-1
    80001910:	06e78963          	beq	a5,a4,80001982 <remove_proc_from_list+0xbe>
    return 2;  // Need to change head.

  if (p->next_proc == -1)
    80001914:	06092603          	lw	a2,96(s2)
    80001918:	577d                	li	a4,-1
    return 3;  // Need to change tail.
    8000191a:	450d                	li	a0,3
  if (p->next_proc == -1)
    8000191c:	04e60d63          	beq	a2,a4,80001976 <remove_proc_from_list+0xb2>

  int prev = proc[p->prev_proc].next_proc;
    80001920:	00011517          	auipc	a0,0x11
    80001924:	e5050513          	addi	a0,a0,-432 # 80012770 <proc>
    80001928:	19800713          	li	a4,408
    8000192c:	02e787b3          	mul	a5,a5,a4
    80001930:	00f50733          	add	a4,a0,a5
  if (cas(&proc[p->prev_proc].next_proc, prev, p->next_proc) == 0)
    80001934:	06078793          	addi	a5,a5,96
    80001938:	532c                	lw	a1,96(a4)
    8000193a:	953e                	add	a0,a0,a5
    8000193c:	00006097          	auipc	ra,0x6
    80001940:	d3a080e7          	jalr	-710(ra) # 80007676 <cas>
    80001944:	e129                	bnez	a0,80001986 <remove_proc_from_list+0xc2>
  {
    proc[p->next_proc].prev_proc = p->prev_proc;
    80001946:	00011797          	auipc	a5,0x11
    8000194a:	e2a78793          	addi	a5,a5,-470 # 80012770 <proc>
    8000194e:	19800713          	li	a4,408
    80001952:	06092683          	lw	a3,96(s2)
    80001956:	06492603          	lw	a2,100(s2)
    8000195a:	02e68733          	mul	a4,a3,a4
    8000195e:	97ba                	add	a5,a5,a4
    80001960:	d3f0                	sw	a2,100(a5)

    printf("######### remove cur: %d,    prev: %d, next: %d   \n", ind, p->prev_proc, p->next_proc);
    80001962:	85a6                	mv	a1,s1
    80001964:	00008517          	auipc	a0,0x8
    80001968:	8ac50513          	addi	a0,a0,-1876 # 80009210 <digits+0x1d0>
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	c1c080e7          	jalr	-996(ra) # 80000588 <printf>
    return 0;
    80001974:	4501                	li	a0,0
  }
  return -1;
}
    80001976:	60e2                	ld	ra,24(sp)
    80001978:	6442                	ld	s0,16(sp)
    8000197a:	64a2                	ld	s1,8(sp)
    8000197c:	6902                	ld	s2,0(sp)
    8000197e:	6105                	addi	sp,sp,32
    80001980:	8082                	ret
    return 2;  // Need to change head.
    80001982:	4509                	li	a0,2
    80001984:	bfcd                	j	80001976 <remove_proc_from_list+0xb2>
  return -1;
    80001986:	557d                	li	a0,-1
    80001988:	b7fd                	j	80001976 <remove_proc_from_list+0xb2>

000000008000198a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000198a:	7139                	addi	sp,sp,-64
    8000198c:	fc06                	sd	ra,56(sp)
    8000198e:	f822                	sd	s0,48(sp)
    80001990:	f426                	sd	s1,40(sp)
    80001992:	f04a                	sd	s2,32(sp)
    80001994:	ec4e                	sd	s3,24(sp)
    80001996:	e852                	sd	s4,16(sp)
    80001998:	e456                	sd	s5,8(sp)
    8000199a:	e05a                	sd	s6,0(sp)
    8000199c:	0080                	addi	s0,sp,64
    8000199e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a0:	00011497          	auipc	s1,0x11
    800019a4:	dd048493          	addi	s1,s1,-560 # 80012770 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019a8:	8b26                	mv	s6,s1
    800019aa:	00007a97          	auipc	s5,0x7
    800019ae:	656a8a93          	addi	s5,s5,1622 # 80009000 <etext>
    800019b2:	04000937          	lui	s2,0x4000
    800019b6:	197d                	addi	s2,s2,-1
    800019b8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ba:	00017a17          	auipc	s4,0x17
    800019be:	3b6a0a13          	addi	s4,s4,950 # 80018d70 <tickslock>
    char *pa = kalloc();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	132080e7          	jalr	306(ra) # 80000af4 <kalloc>
    800019ca:	862a                	mv	a2,a0
    if(pa == 0)
    800019cc:	c131                	beqz	a0,80001a10 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019ce:	416485b3          	sub	a1,s1,s6
    800019d2:	858d                	srai	a1,a1,0x3
    800019d4:	000ab783          	ld	a5,0(s5)
    800019d8:	02f585b3          	mul	a1,a1,a5
    800019dc:	2585                	addiw	a1,a1,1
    800019de:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019e2:	4719                	li	a4,6
    800019e4:	6685                	lui	a3,0x1
    800019e6:	40b905b3          	sub	a1,s2,a1
    800019ea:	854e                	mv	a0,s3
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	76c080e7          	jalr	1900(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f4:	19848493          	addi	s1,s1,408
    800019f8:	fd4495e3          	bne	s1,s4,800019c2 <proc_mapstacks+0x38>
  }
}
    800019fc:	70e2                	ld	ra,56(sp)
    800019fe:	7442                	ld	s0,48(sp)
    80001a00:	74a2                	ld	s1,40(sp)
    80001a02:	7902                	ld	s2,32(sp)
    80001a04:	69e2                	ld	s3,24(sp)
    80001a06:	6a42                	ld	s4,16(sp)
    80001a08:	6aa2                	ld	s5,8(sp)
    80001a0a:	6b02                	ld	s6,0(sp)
    80001a0c:	6121                	addi	sp,sp,64
    80001a0e:	8082                	ret
      panic("kalloc");
    80001a10:	00008517          	auipc	a0,0x8
    80001a14:	83850513          	addi	a0,a0,-1992 # 80009248 <digits+0x208>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080001a20 <procinit>:


// initialize the proc table at boot time.
	void
	procinit(void)
	{
    80001a20:	711d                	addi	sp,sp,-96
    80001a22:	ec86                	sd	ra,88(sp)
    80001a24:	e8a2                	sd	s0,80(sp)
    80001a26:	e4a6                	sd	s1,72(sp)
    80001a28:	e0ca                	sd	s2,64(sp)
    80001a2a:	fc4e                	sd	s3,56(sp)
    80001a2c:	f852                	sd	s4,48(sp)
    80001a2e:	f456                	sd	s5,40(sp)
    80001a30:	f05a                	sd	s6,32(sp)
    80001a32:	ec5e                	sd	s7,24(sp)
    80001a34:	e862                	sd	s8,16(sp)
    80001a36:	e466                	sd	s9,8(sp)
    80001a38:	1080                	addi	s0,sp,96
	  struct proc *p;
    int i = 0;
	  
	  initlock(&pid_lock, "nextpid");
    80001a3a:	00008597          	auipc	a1,0x8
    80001a3e:	81658593          	addi	a1,a1,-2026 # 80009250 <digits+0x210>
    80001a42:	00011517          	auipc	a0,0x11
    80001a46:	cfe50513          	addi	a0,a0,-770 # 80012740 <pid_lock>
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	10a080e7          	jalr	266(ra) # 80000b54 <initlock>
	  initlock(&wait_lock, "wait_lock");
    80001a52:	00008597          	auipc	a1,0x8
    80001a56:	80658593          	addi	a1,a1,-2042 # 80009258 <digits+0x218>
    80001a5a:	00011517          	auipc	a0,0x11
    80001a5e:	cfe50513          	addi	a0,a0,-770 # 80012758 <wait_lock>
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	0f2080e7          	jalr	242(ra) # 80000b54 <initlock>
	  for(p = proc; p < &proc[NPROC]; p++) {
	      initlock(&p->lock, "proc");
    80001a6a:	00007597          	auipc	a1,0x7
    80001a6e:	7fe58593          	addi	a1,a1,2046 # 80009268 <digits+0x228>
    80001a72:	00011517          	auipc	a0,0x11
    80001a76:	cfe50513          	addi	a0,a0,-770 # 80012770 <proc>
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	0da080e7          	jalr	218(ra) # 80000b54 <initlock>
	      p->kstack = KSTACK((int) (p - proc));
    80001a82:	00011497          	auipc	s1,0x11
    80001a86:	cee48493          	addi	s1,s1,-786 # 80012770 <proc>
    80001a8a:	040007b7          	lui	a5,0x4000
    80001a8e:	17f5                	addi	a5,a5,-3
    80001a90:	07b2                	slli	a5,a5,0xc
    80001a92:	f8bc                	sd	a5,112(s1)

        p->proc_ind = i;                               // Set index to process.
    80001a94:	0404ae23          	sw	zero,92(s1)
        p->prev_proc = -1;
    80001a98:	57fd                	li	a5,-1
    80001a9a:	d0fc                	sw	a5,100(s1)
        p->next_proc = -1;
    80001a9c:	d0bc                	sw	a5,96(s1)
    int i = 0;
    80001a9e:	4901                	li	s2,0
	  for(p = proc; p < &proc[NPROC]; p++) {
    80001aa0:	00017a97          	auipc	s5,0x17
    80001aa4:	2d0a8a93          	addi	s5,s5,720 # 80018d70 <tickslock>
	      p->kstack = KSTACK((int) (p - proc));
    80001aa8:	8ba6                	mv	s7,s1
    80001aaa:	00007b17          	auipc	s6,0x7
    80001aae:	556b0b13          	addi	s6,s6,1366 # 80009000 <etext>
    80001ab2:	04000a37          	lui	s4,0x4000
    80001ab6:	1a7d                	addi	s4,s4,-1
    80001ab8:	0a32                	slli	s4,s4,0xc
        if (i != 0)
        {
          printf("unused");
          add_proc_to_list(unused_list_tail, p);
    80001aba:	00008c17          	auipc	s8,0x8
    80001abe:	f86c0c13          	addi	s8,s8,-122 # 80009a40 <unused_list_tail>
          if (unused_list_head == -1)
    80001ac2:	00008c97          	auipc	s9,0x8
    80001ac6:	f82c8c93          	addi	s9,s9,-126 # 80009a44 <unused_list_head>
    80001aca:	a021                	j	80001ad2 <procinit+0xb2>
          {
            unused_list_head = p->proc_ind;
          }
            unused_list_tail = p->proc_ind;             // After adding to list, updating tail.
    80001acc:	4cfc                	lw	a5,92(s1)
    80001ace:	00fc2023          	sw	a5,0(s8)
        }
        i ++;
    80001ad2:	0019099b          	addiw	s3,s2,1
    80001ad6:	0009891b          	sext.w	s2,s3
	  for(p = proc; p < &proc[NPROC]; p++) {
    80001ada:	19848493          	addi	s1,s1,408
    80001ade:	07548763          	beq	s1,s5,80001b4c <procinit+0x12c>
	      initlock(&p->lock, "proc");
    80001ae2:	00007597          	auipc	a1,0x7
    80001ae6:	78658593          	addi	a1,a1,1926 # 80009268 <digits+0x228>
    80001aea:	8526                	mv	a0,s1
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	068080e7          	jalr	104(ra) # 80000b54 <initlock>
	      p->kstack = KSTACK((int) (p - proc));
    80001af4:	417487b3          	sub	a5,s1,s7
    80001af8:	878d                	srai	a5,a5,0x3
    80001afa:	000b3703          	ld	a4,0(s6)
    80001afe:	02e787b3          	mul	a5,a5,a4
    80001b02:	2785                	addiw	a5,a5,1
    80001b04:	00d7979b          	slliw	a5,a5,0xd
    80001b08:	40fa07b3          	sub	a5,s4,a5
    80001b0c:	f8bc                	sd	a5,112(s1)
        p->proc_ind = i;                               // Set index to process.
    80001b0e:	0534ae23          	sw	s3,92(s1)
        p->prev_proc = -1;
    80001b12:	57fd                	li	a5,-1
    80001b14:	d0fc                	sw	a5,100(s1)
        p->next_proc = -1;
    80001b16:	d0bc                	sw	a5,96(s1)
        if (i != 0)
    80001b18:	fa090de3          	beqz	s2,80001ad2 <procinit+0xb2>
          printf("unused");
    80001b1c:	00007517          	auipc	a0,0x7
    80001b20:	75450513          	addi	a0,a0,1876 # 80009270 <digits+0x230>
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	a64080e7          	jalr	-1436(ra) # 80000588 <printf>
          add_proc_to_list(unused_list_tail, p);
    80001b2c:	85a6                	mv	a1,s1
    80001b2e:	000c2503          	lw	a0,0(s8)
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	d14080e7          	jalr	-748(ra) # 80001846 <add_proc_to_list>
          if (unused_list_head == -1)
    80001b3a:	000ca703          	lw	a4,0(s9)
    80001b3e:	57fd                	li	a5,-1
    80001b40:	f8f716e3          	bne	a4,a5,80001acc <procinit+0xac>
            unused_list_head = p->proc_ind;
    80001b44:	4cfc                	lw	a5,92(s1)
    80001b46:	00fca023          	sw	a5,0(s9)
    80001b4a:	b749                	j	80001acc <procinit+0xac>
      }
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b4c:	00010797          	auipc	a5,0x10
    80001b50:	77478793          	addi	a5,a5,1908 # 800122c0 <cpus>
  {
    c->runnable_list_head = -1;
    80001b54:	577d                	li	a4,-1
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b56:	00011697          	auipc	a3,0x11
    80001b5a:	bea68693          	addi	a3,a3,-1046 # 80012740 <pid_lock>
    c->runnable_list_head = -1;
    80001b5e:	08e7a023          	sw	a4,128(a5)
    c->runnable_list_tail = -1;
    80001b62:	08e7a223          	sw	a4,132(a5)
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b66:	09078793          	addi	a5,a5,144
    80001b6a:	fed79ae3          	bne	a5,a3,80001b5e <procinit+0x13e>
  }
}
    80001b6e:	60e6                	ld	ra,88(sp)
    80001b70:	6446                	ld	s0,80(sp)
    80001b72:	64a6                	ld	s1,72(sp)
    80001b74:	6906                	ld	s2,64(sp)
    80001b76:	79e2                	ld	s3,56(sp)
    80001b78:	7a42                	ld	s4,48(sp)
    80001b7a:	7aa2                	ld	s5,40(sp)
    80001b7c:	7b02                	ld	s6,32(sp)
    80001b7e:	6be2                	ld	s7,24(sp)
    80001b80:	6c42                	ld	s8,16(sp)
    80001b82:	6ca2                	ld	s9,8(sp)
    80001b84:	6125                	addi	sp,sp,96
    80001b86:	8082                	ret

0000000080001b88 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e422                	sd	s0,8(sp)
    80001b8c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b8e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b90:	2501                	sext.w	a0,a0
    80001b92:	6422                	ld	s0,8(sp)
    80001b94:	0141                	addi	sp,sp,16
    80001b96:	8082                	ret

0000000080001b98 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b98:	1141                	addi	sp,sp,-16
    80001b9a:	e422                	sd	s0,8(sp)
    80001b9c:	0800                	addi	s0,sp,16
    80001b9e:	8792                	mv	a5,tp
  int id = r_tp();
    80001ba0:	0007871b          	sext.w	a4,a5
  int id = cpuid();
  struct cpu *c = &cpus[id];
  c->cpu_id = id;
    80001ba4:	00010517          	auipc	a0,0x10
    80001ba8:	71c50513          	addi	a0,a0,1820 # 800122c0 <cpus>
    80001bac:	00371793          	slli	a5,a4,0x3
    80001bb0:	00e786b3          	add	a3,a5,a4
    80001bb4:	0692                	slli	a3,a3,0x4
    80001bb6:	96aa                	add	a3,a3,a0
    80001bb8:	08e6a423          	sw	a4,136(a3)
  return c;
}
    80001bbc:	8536                	mv	a0,a3
    80001bbe:	6422                	ld	s0,8(sp)
    80001bc0:	0141                	addi	sp,sp,16
    80001bc2:	8082                	ret

0000000080001bc4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001bc4:	1101                	addi	sp,sp,-32
    80001bc6:	ec06                	sd	ra,24(sp)
    80001bc8:	e822                	sd	s0,16(sp)
    80001bca:	e426                	sd	s1,8(sp)
    80001bcc:	1000                	addi	s0,sp,32
  push_off();
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	fca080e7          	jalr	-54(ra) # 80000b98 <push_off>
    80001bd6:	8792                	mv	a5,tp
  int id = r_tp();
    80001bd8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80001bdc:	00010617          	auipc	a2,0x10
    80001be0:	6e460613          	addi	a2,a2,1764 # 800122c0 <cpus>
    80001be4:	00371793          	slli	a5,a4,0x3
    80001be8:	00e786b3          	add	a3,a5,a4
    80001bec:	0692                	slli	a3,a3,0x4
    80001bee:	96b2                	add	a3,a3,a2
    80001bf0:	08e6a423          	sw	a4,136(a3)
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bf4:	6284                	ld	s1,0(a3)
  pop_off();
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	042080e7          	jalr	66(ra) # 80000c38 <pop_off>
  return p;
}
    80001bfe:	8526                	mv	a0,s1
    80001c00:	60e2                	ld	ra,24(sp)
    80001c02:	6442                	ld	s0,16(sp)
    80001c04:	64a2                	ld	s1,8(sp)
    80001c06:	6105                	addi	sp,sp,32
    80001c08:	8082                	ret

0000000080001c0a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c0a:	1141                	addi	sp,sp,-16
    80001c0c:	e406                	sd	ra,8(sp)
    80001c0e:	e022                	sd	s0,0(sp)
    80001c10:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	fb2080e7          	jalr	-78(ra) # 80001bc4 <myproc>
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	07e080e7          	jalr	126(ra) # 80000c98 <release>

  if (first) {
    80001c22:	00008797          	auipc	a5,0x8
    80001c26:	e0e7a783          	lw	a5,-498(a5) # 80009a30 <first.1780>
    80001c2a:	eb89                	bnez	a5,80001c3c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c2c:	00002097          	auipc	ra,0x2
    80001c30:	e48080e7          	jalr	-440(ra) # 80003a74 <usertrapret>
}
    80001c34:	60a2                	ld	ra,8(sp)
    80001c36:	6402                	ld	s0,0(sp)
    80001c38:	0141                	addi	sp,sp,16
    80001c3a:	8082                	ret
    first = 0;
    80001c3c:	00008797          	auipc	a5,0x8
    80001c40:	de07aa23          	sw	zero,-524(a5) # 80009a30 <first.1780>
    fsinit(ROOTDEV);
    80001c44:	4505                	li	a0,1
    80001c46:	00003097          	auipc	ra,0x3
    80001c4a:	c2a080e7          	jalr	-982(ra) # 80004870 <fsinit>
    80001c4e:	bff9                	j	80001c2c <forkret+0x22>

0000000080001c50 <allocpid>:
allocpid() {
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	1000                	addi	s0,sp,32
  pid = nextpid;
    80001c5a:	00008517          	auipc	a0,0x8
    80001c5e:	dda50513          	addi	a0,a0,-550 # 80009a34 <nextpid>
    80001c62:	4104                	lw	s1,0(a0)
  if (cas(&nextpid, pid, (nextpid + 1)) == 0)
    80001c64:	0014861b          	addiw	a2,s1,1
    80001c68:	85a6                	mv	a1,s1
    80001c6a:	00006097          	auipc	ra,0x6
    80001c6e:	a0c080e7          	jalr	-1524(ra) # 80007676 <cas>
    80001c72:	e519                	bnez	a0,80001c80 <allocpid+0x30>
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret
  return allocpid();
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	fd0080e7          	jalr	-48(ra) # 80001c50 <allocpid>
    80001c88:	84aa                	mv	s1,a0
    80001c8a:	b7ed                	j	80001c74 <allocpid+0x24>

0000000080001c8c <proc_pagetable>:
{
    80001c8c:	1101                	addi	sp,sp,-32
    80001c8e:	ec06                	sd	ra,24(sp)
    80001c90:	e822                	sd	s0,16(sp)
    80001c92:	e426                	sd	s1,8(sp)
    80001c94:	e04a                	sd	s2,0(sp)
    80001c96:	1000                	addi	s0,sp,32
    80001c98:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	6a8080e7          	jalr	1704(ra) # 80001342 <uvmcreate>
    80001ca2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ca4:	c121                	beqz	a0,80001ce4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ca6:	4729                	li	a4,10
    80001ca8:	00006697          	auipc	a3,0x6
    80001cac:	35868693          	addi	a3,a3,856 # 80008000 <_trampoline>
    80001cb0:	6605                	lui	a2,0x1
    80001cb2:	040005b7          	lui	a1,0x4000
    80001cb6:	15fd                	addi	a1,a1,-1
    80001cb8:	05b2                	slli	a1,a1,0xc
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	3fe080e7          	jalr	1022(ra) # 800010b8 <mappages>
    80001cc2:	02054863          	bltz	a0,80001cf2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cc6:	4719                	li	a4,6
    80001cc8:	08893683          	ld	a3,136(s2) # 4000088 <_entry-0x7bffff78>
    80001ccc:	6605                	lui	a2,0x1
    80001cce:	020005b7          	lui	a1,0x2000
    80001cd2:	15fd                	addi	a1,a1,-1
    80001cd4:	05b6                	slli	a1,a1,0xd
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	3e0080e7          	jalr	992(ra) # 800010b8 <mappages>
    80001ce0:	02054163          	bltz	a0,80001d02 <proc_pagetable+0x76>
}
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6902                	ld	s2,0(sp)
    80001cee:	6105                	addi	sp,sp,32
    80001cf0:	8082                	ret
    uvmfree(pagetable, 0);
    80001cf2:	4581                	li	a1,0
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	848080e7          	jalr	-1976(ra) # 8000153e <uvmfree>
    return 0;
    80001cfe:	4481                	li	s1,0
    80001d00:	b7d5                	j	80001ce4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d02:	4681                	li	a3,0
    80001d04:	4605                	li	a2,1
    80001d06:	040005b7          	lui	a1,0x4000
    80001d0a:	15fd                	addi	a1,a1,-1
    80001d0c:	05b2                	slli	a1,a1,0xc
    80001d0e:	8526                	mv	a0,s1
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	56e080e7          	jalr	1390(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001d18:	4581                	li	a1,0
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	00000097          	auipc	ra,0x0
    80001d20:	822080e7          	jalr	-2014(ra) # 8000153e <uvmfree>
    return 0;
    80001d24:	4481                	li	s1,0
    80001d26:	bf7d                	j	80001ce4 <proc_pagetable+0x58>

0000000080001d28 <proc_freepagetable>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	e04a                	sd	s2,0(sp)
    80001d32:	1000                	addi	s0,sp,32
    80001d34:	84aa                	mv	s1,a0
    80001d36:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d38:	4681                	li	a3,0
    80001d3a:	4605                	li	a2,1
    80001d3c:	040005b7          	lui	a1,0x4000
    80001d40:	15fd                	addi	a1,a1,-1
    80001d42:	05b2                	slli	a1,a1,0xc
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	53a080e7          	jalr	1338(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d4c:	4681                	li	a3,0
    80001d4e:	4605                	li	a2,1
    80001d50:	020005b7          	lui	a1,0x2000
    80001d54:	15fd                	addi	a1,a1,-1
    80001d56:	05b6                	slli	a1,a1,0xd
    80001d58:	8526                	mv	a0,s1
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	524080e7          	jalr	1316(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001d62:	85ca                	mv	a1,s2
    80001d64:	8526                	mv	a0,s1
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	7d8080e7          	jalr	2008(ra) # 8000153e <uvmfree>
}
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6902                	ld	s2,0(sp)
    80001d76:	6105                	addi	sp,sp,32
    80001d78:	8082                	ret

0000000080001d7a <freeproc>:
{
    80001d7a:	1101                	addi	sp,sp,-32
    80001d7c:	ec06                	sd	ra,24(sp)
    80001d7e:	e822                	sd	s0,16(sp)
    80001d80:	e426                	sd	s1,8(sp)
    80001d82:	1000                	addi	s0,sp,32
    80001d84:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d86:	6548                	ld	a0,136(a0)
    80001d88:	c509                	beqz	a0,80001d92 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	c6e080e7          	jalr	-914(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d92:	0804b423          	sd	zero,136(s1)
  if(p->pagetable)
    80001d96:	60c8                	ld	a0,128(s1)
    80001d98:	c511                	beqz	a0,80001da4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d9a:	7cac                	ld	a1,120(s1)
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	f8c080e7          	jalr	-116(ra) # 80001d28 <proc_freepagetable>
  p->pagetable = 0;
    80001da4:	0804b023          	sd	zero,128(s1)
  p->sz = 0;
    80001da8:	0604bc23          	sd	zero,120(s1)
  p->pid = 0;
    80001dac:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001db0:	0604b423          	sd	zero,104(s1)
  p->name[0] = 0;
    80001db4:	18048423          	sb	zero,392(s1)
  p->chan = 0;
    80001db8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dbc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dc0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dc4:	0004ac23          	sw	zero,24(s1)
  printf("zombie");
    80001dc8:	00007517          	auipc	a0,0x7
    80001dcc:	4b050513          	addi	a0,a0,1200 # 80009278 <digits+0x238>
    80001dd0:	ffffe097          	auipc	ra,0xffffe
    80001dd4:	7b8080e7          	jalr	1976(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80001dd8:	4ce8                	lw	a0,92(s1)
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	aea080e7          	jalr	-1302(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1){
    80001de2:	4785                	li	a5,1
    80001de4:	02f50663          	beq	a0,a5,80001e10 <freeproc+0x96>
  if (res == 2){
    80001de8:	4789                	li	a5,2
    80001dea:	06f51463          	bne	a0,a5,80001e52 <freeproc+0xd8>
    zombie_list_head = p->next_proc;
    80001dee:	50bc                	lw	a5,96(s1)
    80001df0:	00008717          	auipc	a4,0x8
    80001df4:	c4f72623          	sw	a5,-948(a4) # 80009a3c <zombie_list_head>
    proc[p->next_proc].prev_proc = -1;
    80001df8:	19800713          	li	a4,408
    80001dfc:	02e787b3          	mul	a5,a5,a4
    80001e00:	00011717          	auipc	a4,0x11
    80001e04:	97070713          	addi	a4,a4,-1680 # 80012770 <proc>
    80001e08:	97ba                	add	a5,a5,a4
    80001e0a:	577d                	li	a4,-1
    80001e0c:	d3f8                	sw	a4,100(a5)
  if (res == 3){
    80001e0e:	a811                	j	80001e22 <freeproc+0xa8>
    zombie_list_head = -1;
    80001e10:	57fd                	li	a5,-1
    80001e12:	00008717          	auipc	a4,0x8
    80001e16:	c2f72523          	sw	a5,-982(a4) # 80009a3c <zombie_list_head>
    zombie_list_tail = -1;
    80001e1a:	00008717          	auipc	a4,0x8
    80001e1e:	c0f72f23          	sw	a5,-994(a4) # 80009a38 <zombie_list_tail>
  p->next_proc = -1;
    80001e22:	57fd                	li	a5,-1
    80001e24:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80001e26:	d0fc                	sw	a5,100(s1)
  if (unused_list_tail != -1){
    80001e28:	00008717          	auipc	a4,0x8
    80001e2c:	c1872703          	lw	a4,-1000(a4) # 80009a40 <unused_list_tail>
    80001e30:	57fd                	li	a5,-1
    80001e32:	04f71463          	bne	a4,a5,80001e7a <freeproc+0x100>
    unused_list_tail = unused_list_head = p->proc_ind;
    80001e36:	4cfc                	lw	a5,92(s1)
    80001e38:	00008717          	auipc	a4,0x8
    80001e3c:	c0f72623          	sw	a5,-1012(a4) # 80009a44 <unused_list_head>
    80001e40:	00008717          	auipc	a4,0x8
    80001e44:	c0f72023          	sw	a5,-1024(a4) # 80009a40 <unused_list_tail>
}
    80001e48:	60e2                	ld	ra,24(sp)
    80001e4a:	6442                	ld	s0,16(sp)
    80001e4c:	64a2                	ld	s1,8(sp)
    80001e4e:	6105                	addi	sp,sp,32
    80001e50:	8082                	ret
  if (res == 3){
    80001e52:	478d                	li	a5,3
    80001e54:	fcf517e3          	bne	a0,a5,80001e22 <freeproc+0xa8>
    zombie_list_tail = p->prev_proc;
    80001e58:	50fc                	lw	a5,100(s1)
    80001e5a:	00008717          	auipc	a4,0x8
    80001e5e:	bcf72f23          	sw	a5,-1058(a4) # 80009a38 <zombie_list_tail>
    proc[p->prev_proc].next_proc = -1;
    80001e62:	19800713          	li	a4,408
    80001e66:	02e787b3          	mul	a5,a5,a4
    80001e6a:	00011717          	auipc	a4,0x11
    80001e6e:	90670713          	addi	a4,a4,-1786 # 80012770 <proc>
    80001e72:	97ba                	add	a5,a5,a4
    80001e74:	577d                	li	a4,-1
    80001e76:	d3b8                	sw	a4,96(a5)
    80001e78:	b76d                	j	80001e22 <freeproc+0xa8>
    printf("unused");
    80001e7a:	00007517          	auipc	a0,0x7
    80001e7e:	3f650513          	addi	a0,a0,1014 # 80009270 <digits+0x230>
    80001e82:	ffffe097          	auipc	ra,0xffffe
    80001e86:	706080e7          	jalr	1798(ra) # 80000588 <printf>
    add_proc_to_list(unused_list_tail, p);
    80001e8a:	85a6                	mv	a1,s1
    80001e8c:	00008517          	auipc	a0,0x8
    80001e90:	bb452503          	lw	a0,-1100(a0) # 80009a40 <unused_list_tail>
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	9b2080e7          	jalr	-1614(ra) # 80001846 <add_proc_to_list>
    if (unused_list_head == -1)
    80001e9c:	00008717          	auipc	a4,0x8
    80001ea0:	ba872703          	lw	a4,-1112(a4) # 80009a44 <unused_list_head>
    80001ea4:	57fd                	li	a5,-1
    80001ea6:	00f70863          	beq	a4,a5,80001eb6 <freeproc+0x13c>
    unused_list_tail = p->proc_ind;
    80001eaa:	4cfc                	lw	a5,92(s1)
    80001eac:	00008717          	auipc	a4,0x8
    80001eb0:	b8f72a23          	sw	a5,-1132(a4) # 80009a40 <unused_list_tail>
    80001eb4:	bf51                	j	80001e48 <freeproc+0xce>
    unused_list_head = p->proc_ind;
    80001eb6:	4cfc                	lw	a5,92(s1)
    80001eb8:	00008717          	auipc	a4,0x8
    80001ebc:	b8f72623          	sw	a5,-1140(a4) # 80009a44 <unused_list_head>
    80001ec0:	b7ed                	j	80001eaa <freeproc+0x130>

0000000080001ec2 <allocproc>:
{
    80001ec2:	7139                	addi	sp,sp,-64
    80001ec4:	fc06                	sd	ra,56(sp)
    80001ec6:	f822                	sd	s0,48(sp)
    80001ec8:	f426                	sd	s1,40(sp)
    80001eca:	f04a                	sd	s2,32(sp)
    80001ecc:	ec4e                	sd	s3,24(sp)
    80001ece:	e852                	sd	s4,16(sp)
    80001ed0:	e456                	sd	s5,8(sp)
    80001ed2:	0080                	addi	s0,sp,64
  if (unused_list_head > -1)
    80001ed4:	00008917          	auipc	s2,0x8
    80001ed8:	b7092903          	lw	s2,-1168(s2) # 80009a44 <unused_list_head>
  return 0;
    80001edc:	4981                	li	s3,0
  if (unused_list_head > -1)
    80001ede:	00095c63          	bgez	s2,80001ef6 <allocproc+0x34>
}
    80001ee2:	854e                	mv	a0,s3
    80001ee4:	70e2                	ld	ra,56(sp)
    80001ee6:	7442                	ld	s0,48(sp)
    80001ee8:	74a2                	ld	s1,40(sp)
    80001eea:	7902                	ld	s2,32(sp)
    80001eec:	69e2                	ld	s3,24(sp)
    80001eee:	6a42                	ld	s4,16(sp)
    80001ef0:	6aa2                	ld	s5,8(sp)
    80001ef2:	6121                	addi	sp,sp,64
    80001ef4:	8082                	ret
    p = &proc[unused_list_head];
    80001ef6:	19800a13          	li	s4,408
    80001efa:	03490a33          	mul	s4,s2,s4
    80001efe:	00011997          	auipc	s3,0x11
    80001f02:	87298993          	addi	s3,s3,-1934 # 80012770 <proc>
    80001f06:	99d2                	add	s3,s3,s4
    acquire(&p->lock);
    80001f08:	854e                	mv	a0,s3
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	cda080e7          	jalr	-806(ra) # 80000be4 <acquire>
    printf("unused");
    80001f12:	00007517          	auipc	a0,0x7
    80001f16:	35e50513          	addi	a0,a0,862 # 80009270 <digits+0x230>
    80001f1a:	ffffe097          	auipc	ra,0xffffe
    80001f1e:	66e080e7          	jalr	1646(ra) # 80000588 <printf>
    int res = remove_proc_from_list(unused_list_head); 
    80001f22:	00008517          	auipc	a0,0x8
    80001f26:	b2252503          	lw	a0,-1246(a0) # 80009a44 <unused_list_head>
    80001f2a:	00000097          	auipc	ra,0x0
    80001f2e:	99a080e7          	jalr	-1638(ra) # 800018c4 <remove_proc_from_list>
    if (res == 1){
    80001f32:	4785                	li	a5,1
    80001f34:	02f50963          	beq	a0,a5,80001f66 <allocproc+0xa4>
    if (res == 2){
    80001f38:	4789                	li	a5,2
    80001f3a:	0ef51663          	bne	a0,a5,80002026 <allocproc+0x164>
      unused_list_head = p->next_proc;      // Update head.
    80001f3e:	00011797          	auipc	a5,0x11
    80001f42:	83278793          	addi	a5,a5,-1998 # 80012770 <proc>
    80001f46:	19800613          	li	a2,408
    80001f4a:	02c906b3          	mul	a3,s2,a2
    80001f4e:	96be                	add	a3,a3,a5
    80001f50:	52b8                	lw	a4,96(a3)
    80001f52:	00008697          	auipc	a3,0x8
    80001f56:	aee6a923          	sw	a4,-1294(a3) # 80009a44 <unused_list_head>
      proc[p->next_proc].prev_proc = -1;    // Remove head's prev.
    80001f5a:	02c70733          	mul	a4,a4,a2
    80001f5e:	97ba                	add	a5,a5,a4
    80001f60:	577d                	li	a4,-1
    80001f62:	d3f8                	sw	a4,100(a5)
    if (res == 3){
    80001f64:	a811                	j	80001f78 <allocproc+0xb6>
      unused_list_head = -1;
    80001f66:	57fd                	li	a5,-1
    80001f68:	00008717          	auipc	a4,0x8
    80001f6c:	acf72e23          	sw	a5,-1316(a4) # 80009a44 <unused_list_head>
      unused_list_tail = -1;
    80001f70:	00008717          	auipc	a4,0x8
    80001f74:	acf72823          	sw	a5,-1328(a4) # 80009a40 <unused_list_tail>
    p->prev_proc = -1;
    80001f78:	19800493          	li	s1,408
    80001f7c:	029907b3          	mul	a5,s2,s1
    80001f80:	00010497          	auipc	s1,0x10
    80001f84:	7f048493          	addi	s1,s1,2032 # 80012770 <proc>
    80001f88:	94be                	add	s1,s1,a5
    80001f8a:	57fd                	li	a5,-1
    80001f8c:	d0fc                	sw	a5,100(s1)
    p->next_proc = -1;
    80001f8e:	d0bc                	sw	a5,96(s1)
  p->pid = allocpid();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	cc0080e7          	jalr	-832(ra) # 80001c50 <allocpid>
    80001f98:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001f9a:	4785                	li	a5,1
    80001f9c:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001f9e:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001fa2:	0204ac23          	sw	zero,56(s1)
  p->paused = 0;
    80001fa6:	0404a023          	sw	zero,64(s1)
  p->sleeping_time = 0;
    80001faa:	0404a623          	sw	zero,76(s1)
  p->running_time = 0;
    80001fae:	0404a223          	sw	zero,68(s1)
  p->runnable_time = 0;
    80001fb2:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	b3e080e7          	jalr	-1218(ra) # 80000af4 <kalloc>
    80001fbe:	8aaa                	mv	s5,a0
    80001fc0:	e4c8                	sd	a0,136(s1)
    80001fc2:	c949                	beqz	a0,80002054 <allocproc+0x192>
  p->pagetable = proc_pagetable(p);
    80001fc4:	854e                	mv	a0,s3
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	cc6080e7          	jalr	-826(ra) # 80001c8c <proc_pagetable>
    80001fce:	84aa                	mv	s1,a0
    80001fd0:	19800793          	li	a5,408
    80001fd4:	02f90733          	mul	a4,s2,a5
    80001fd8:	00010797          	auipc	a5,0x10
    80001fdc:	79878793          	addi	a5,a5,1944 # 80012770 <proc>
    80001fe0:	97ba                	add	a5,a5,a4
    80001fe2:	e3c8                	sd	a0,128(a5)
  if(p->pagetable == 0){
    80001fe4:	c541                	beqz	a0,8000206c <allocproc+0x1aa>
  memset(&p->context, 0, sizeof(p->context));
    80001fe6:	090a0513          	addi	a0,s4,144 # 4000090 <_entry-0x7bffff70>
    80001fea:	00010497          	auipc	s1,0x10
    80001fee:	78648493          	addi	s1,s1,1926 # 80012770 <proc>
    80001ff2:	07000613          	li	a2,112
    80001ff6:	4581                	li	a1,0
    80001ff8:	9526                	add	a0,a0,s1
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	ce6080e7          	jalr	-794(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002002:	19800793          	li	a5,408
    80002006:	02f90933          	mul	s2,s2,a5
    8000200a:	9926                	add	s2,s2,s1
    8000200c:	00000797          	auipc	a5,0x0
    80002010:	bfe78793          	addi	a5,a5,-1026 # 80001c0a <forkret>
    80002014:	08f93823          	sd	a5,144(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002018:	07093783          	ld	a5,112(s2)
    8000201c:	6705                	lui	a4,0x1
    8000201e:	97ba                	add	a5,a5,a4
    80002020:	08f93c23          	sd	a5,152(s2)
  return p;
    80002024:	bd7d                	j	80001ee2 <allocproc+0x20>
    if (res == 3){
    80002026:	478d                	li	a5,3
    80002028:	f4f518e3          	bne	a0,a5,80001f78 <allocproc+0xb6>
      unused_list_tail = p->prev_proc;      // Update tail.
    8000202c:	00010797          	auipc	a5,0x10
    80002030:	74478793          	addi	a5,a5,1860 # 80012770 <proc>
    80002034:	19800613          	li	a2,408
    80002038:	02c906b3          	mul	a3,s2,a2
    8000203c:	96be                	add	a3,a3,a5
    8000203e:	52f8                	lw	a4,100(a3)
    80002040:	00008697          	auipc	a3,0x8
    80002044:	a0e6a023          	sw	a4,-1536(a3) # 80009a40 <unused_list_tail>
      proc[p->prev_proc].next_proc = -1;    // Remove tail's next.
    80002048:	02c70733          	mul	a4,a4,a2
    8000204c:	97ba                	add	a5,a5,a4
    8000204e:	577d                	li	a4,-1
    80002050:	d3b8                	sw	a4,96(a5)
    80002052:	b71d                	j	80001f78 <allocproc+0xb6>
    freeproc(p);
    80002054:	854e                	mv	a0,s3
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	d24080e7          	jalr	-732(ra) # 80001d7a <freeproc>
    release(&p->lock);
    8000205e:	854e                	mv	a0,s3
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	c38080e7          	jalr	-968(ra) # 80000c98 <release>
    return 0;
    80002068:	89d6                	mv	s3,s5
    8000206a:	bda5                	j	80001ee2 <allocproc+0x20>
    freeproc(p);
    8000206c:	854e                	mv	a0,s3
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	d0c080e7          	jalr	-756(ra) # 80001d7a <freeproc>
    release(&p->lock);
    80002076:	854e                	mv	a0,s3
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	c20080e7          	jalr	-992(ra) # 80000c98 <release>
    return 0;
    80002080:	89a6                	mv	s3,s1
    80002082:	b585                	j	80001ee2 <allocproc+0x20>

0000000080002084 <str_compare>:
{
    80002084:	1141                	addi	sp,sp,-16
    80002086:	e422                	sd	s0,8(sp)
    80002088:	0800                	addi	s0,sp,16
      c1 = (unsigned char) *s1++;
    8000208a:	0505                	addi	a0,a0,1
    8000208c:	fff54783          	lbu	a5,-1(a0)
      c2 = (unsigned char) *s2++;
    80002090:	0585                	addi	a1,a1,1
    80002092:	fff5c703          	lbu	a4,-1(a1) # 1ffffff <_entry-0x7e000001>
      if (c1 == '\0')
    80002096:	c791                	beqz	a5,800020a2 <str_compare+0x1e>
  while (c1 == c2);
    80002098:	fee789e3          	beq	a5,a4,8000208a <str_compare+0x6>
  return c1 - c2;
    8000209c:	40e7853b          	subw	a0,a5,a4
    800020a0:	a019                	j	800020a6 <str_compare+0x22>
        return c1 - c2;
    800020a2:	40e0053b          	negw	a0,a4
}
    800020a6:	6422                	ld	s0,8(sp)
    800020a8:	0141                	addi	sp,sp,16
    800020aa:	8082                	ret

00000000800020ac <userinit>:
{
    800020ac:	1101                	addi	sp,sp,-32
    800020ae:	ec06                	sd	ra,24(sp)
    800020b0:	e822                	sd	s0,16(sp)
    800020b2:	e426                	sd	s1,8(sp)
    800020b4:	e04a                	sd	s2,0(sp)
    800020b6:	1000                	addi	s0,sp,32
  p = allocproc();
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	e0a080e7          	jalr	-502(ra) # 80001ec2 <allocproc>
    800020c0:	84aa                	mv	s1,a0
  initproc = p;
    800020c2:	00008797          	auipc	a5,0x8
    800020c6:	f6a7b323          	sd	a0,-154(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800020ca:	03400613          	li	a2,52
    800020ce:	00008597          	auipc	a1,0x8
    800020d2:	99258593          	addi	a1,a1,-1646 # 80009a60 <initcode>
    800020d6:	6148                	ld	a0,128(a0)
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	298080e7          	jalr	664(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    800020e0:	6785                	lui	a5,0x1
    800020e2:	fcbc                	sd	a5,120(s1)
  p->trapframe->epc = 0;      // user program counter
    800020e4:	64d8                	ld	a4,136(s1)
    800020e6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020ea:	64d8                	ld	a4,136(s1)
    800020ec:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020ee:	4641                	li	a2,16
    800020f0:	00007597          	auipc	a1,0x7
    800020f4:	19058593          	addi	a1,a1,400 # 80009280 <digits+0x240>
    800020f8:	18848513          	addi	a0,s1,392
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	d36080e7          	jalr	-714(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002104:	00007517          	auipc	a0,0x7
    80002108:	18c50513          	addi	a0,a0,396 # 80009290 <digits+0x250>
    8000210c:	00003097          	auipc	ra,0x3
    80002110:	192080e7          	jalr	402(ra) # 8000529e <namei>
    80002114:	18a4b023          	sd	a0,384(s1)
  p->state = RUNNABLE;
    80002118:	478d                	li	a5,3
    8000211a:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    8000211c:	00008797          	auipc	a5,0x8
    80002120:	f387a783          	lw	a5,-200(a5) # 8000a054 <ticks>
    80002124:	dcdc                	sw	a5,60(s1)
    80002126:	8792                	mv	a5,tp
  int id = r_tp();
    80002128:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    8000212c:	00010617          	auipc	a2,0x10
    80002130:	19460613          	addi	a2,a2,404 # 800122c0 <cpus>
    80002134:	00371793          	slli	a5,a4,0x3
    80002138:	00e786b3          	add	a3,a5,a4
    8000213c:	0692                	slli	a3,a3,0x4
    8000213e:	96b2                	add	a3,a3,a2
    80002140:	08e6a423          	sw	a4,136(a3)
  if (mycpu()->runnable_list_head == -1)
    80002144:	0806a703          	lw	a4,128(a3)
    80002148:	57fd                	li	a5,-1
    8000214a:	06f70c63          	beq	a4,a5,800021c2 <userinit+0x116>
    printf("runnable");
    8000214e:	00007517          	auipc	a0,0x7
    80002152:	16250513          	addi	a0,a0,354 # 800092b0 <digits+0x270>
    80002156:	ffffe097          	auipc	ra,0xffffe
    8000215a:	432080e7          	jalr	1074(ra) # 80000588 <printf>
    8000215e:	8792                	mv	a5,tp
  int id = r_tp();
    80002160:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002164:	00010917          	auipc	s2,0x10
    80002168:	15c90913          	addi	s2,s2,348 # 800122c0 <cpus>
    8000216c:	00371793          	slli	a5,a4,0x3
    80002170:	00e786b3          	add	a3,a5,a4
    80002174:	0692                	slli	a3,a3,0x4
    80002176:	96ca                	add	a3,a3,s2
    80002178:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    8000217c:	85a6                	mv	a1,s1
    8000217e:	0846a503          	lw	a0,132(a3)
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	6c4080e7          	jalr	1732(ra) # 80001846 <add_proc_to_list>
    8000218a:	8792                	mv	a5,tp
  int id = r_tp();
    8000218c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002190:	00371793          	slli	a5,a4,0x3
    80002194:	00e786b3          	add	a3,a5,a4
    80002198:	0692                	slli	a3,a3,0x4
    8000219a:	96ca                	add	a3,a3,s2
    8000219c:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    800021a0:	4cf4                	lw	a3,92(s1)
    800021a2:	97ba                	add	a5,a5,a4
    800021a4:	0792                	slli	a5,a5,0x4
    800021a6:	993e                	add	s2,s2,a5
    800021a8:	08d92223          	sw	a3,132(s2)
  release(&p->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	aea080e7          	jalr	-1302(ra) # 80000c98 <release>
}
    800021b6:	60e2                	ld	ra,24(sp)
    800021b8:	6442                	ld	s0,16(sp)
    800021ba:	64a2                	ld	s1,8(sp)
    800021bc:	6902                	ld	s2,0(sp)
    800021be:	6105                	addi	sp,sp,32
    800021c0:	8082                	ret
    printf("init runnable: %d\n", p->proc_ind);
    800021c2:	4cec                	lw	a1,92(s1)
    800021c4:	00007517          	auipc	a0,0x7
    800021c8:	0d450513          	addi	a0,a0,212 # 80009298 <digits+0x258>
    800021cc:	ffffe097          	auipc	ra,0xffffe
    800021d0:	3bc080e7          	jalr	956(ra) # 80000588 <printf>
    800021d4:	8792                	mv	a5,tp
  int id = r_tp();
    800021d6:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    800021da:	00010717          	auipc	a4,0x10
    800021de:	0e670713          	addi	a4,a4,230 # 800122c0 <cpus>
    800021e2:	00369793          	slli	a5,a3,0x3
    800021e6:	00d78633          	add	a2,a5,a3
    800021ea:	0612                	slli	a2,a2,0x4
    800021ec:	963a                	add	a2,a2,a4
    800021ee:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    800021f2:	4cf0                	lw	a2,92(s1)
    800021f4:	97b6                	add	a5,a5,a3
    800021f6:	0792                	slli	a5,a5,0x4
    800021f8:	97ba                	add	a5,a5,a4
    800021fa:	08c7a023          	sw	a2,128(a5)
    800021fe:	8792                	mv	a5,tp
  int id = r_tp();
    80002200:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002204:	00369793          	slli	a5,a3,0x3
    80002208:	00d78633          	add	a2,a5,a3
    8000220c:	0612                	slli	a2,a2,0x4
    8000220e:	963a                	add	a2,a2,a4
    80002210:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002214:	4cf0                	lw	a2,92(s1)
    80002216:	97b6                	add	a5,a5,a3
    80002218:	0792                	slli	a5,a5,0x4
    8000221a:	973e                	add	a4,a4,a5
    8000221c:	08c72223          	sw	a2,132(a4)
    80002220:	b771                	j	800021ac <userinit+0x100>

0000000080002222 <growproc>:
{
    80002222:	1101                	addi	sp,sp,-32
    80002224:	ec06                	sd	ra,24(sp)
    80002226:	e822                	sd	s0,16(sp)
    80002228:	e426                	sd	s1,8(sp)
    8000222a:	e04a                	sd	s2,0(sp)
    8000222c:	1000                	addi	s0,sp,32
    8000222e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002230:	00000097          	auipc	ra,0x0
    80002234:	994080e7          	jalr	-1644(ra) # 80001bc4 <myproc>
    80002238:	892a                	mv	s2,a0
  sz = p->sz;
    8000223a:	7d2c                	ld	a1,120(a0)
    8000223c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002240:	00904f63          	bgtz	s1,8000225e <growproc+0x3c>
  } else if(n < 0){
    80002244:	0204cc63          	bltz	s1,8000227c <growproc+0x5a>
  p->sz = sz;
    80002248:	1602                	slli	a2,a2,0x20
    8000224a:	9201                	srli	a2,a2,0x20
    8000224c:	06c93c23          	sd	a2,120(s2)
  return 0;
    80002250:	4501                	li	a0,0
}
    80002252:	60e2                	ld	ra,24(sp)
    80002254:	6442                	ld	s0,16(sp)
    80002256:	64a2                	ld	s1,8(sp)
    80002258:	6902                	ld	s2,0(sp)
    8000225a:	6105                	addi	sp,sp,32
    8000225c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000225e:	9e25                	addw	a2,a2,s1
    80002260:	1602                	slli	a2,a2,0x20
    80002262:	9201                	srli	a2,a2,0x20
    80002264:	1582                	slli	a1,a1,0x20
    80002266:	9181                	srli	a1,a1,0x20
    80002268:	6148                	ld	a0,128(a0)
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	1c0080e7          	jalr	448(ra) # 8000142a <uvmalloc>
    80002272:	0005061b          	sext.w	a2,a0
    80002276:	fa69                	bnez	a2,80002248 <growproc+0x26>
      return -1;
    80002278:	557d                	li	a0,-1
    8000227a:	bfe1                	j	80002252 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000227c:	9e25                	addw	a2,a2,s1
    8000227e:	1602                	slli	a2,a2,0x20
    80002280:	9201                	srli	a2,a2,0x20
    80002282:	1582                	slli	a1,a1,0x20
    80002284:	9181                	srli	a1,a1,0x20
    80002286:	6148                	ld	a0,128(a0)
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	15a080e7          	jalr	346(ra) # 800013e2 <uvmdealloc>
    80002290:	0005061b          	sext.w	a2,a0
    80002294:	bf55                	j	80002248 <growproc+0x26>

0000000080002296 <fork>:
{
    80002296:	7139                	addi	sp,sp,-64
    80002298:	fc06                	sd	ra,56(sp)
    8000229a:	f822                	sd	s0,48(sp)
    8000229c:	f426                	sd	s1,40(sp)
    8000229e:	f04a                	sd	s2,32(sp)
    800022a0:	ec4e                	sd	s3,24(sp)
    800022a2:	e852                	sd	s4,16(sp)
    800022a4:	e456                	sd	s5,8(sp)
    800022a6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	91c080e7          	jalr	-1764(ra) # 80001bc4 <myproc>
    800022b0:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800022b2:	00000097          	auipc	ra,0x0
    800022b6:	c10080e7          	jalr	-1008(ra) # 80001ec2 <allocproc>
    800022ba:	20050663          	beqz	a0,800024c6 <fork+0x230>
    800022be:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022c0:	0789b603          	ld	a2,120(s3)
    800022c4:	614c                	ld	a1,128(a0)
    800022c6:	0809b503          	ld	a0,128(s3)
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	2ac080e7          	jalr	684(ra) # 80001576 <uvmcopy>
    800022d2:	04054663          	bltz	a0,8000231e <fork+0x88>
  np->sz = p->sz;
    800022d6:	0789b783          	ld	a5,120(s3)
    800022da:	06f93c23          	sd	a5,120(s2)
  *(np->trapframe) = *(p->trapframe);
    800022de:	0889b683          	ld	a3,136(s3)
    800022e2:	87b6                	mv	a5,a3
    800022e4:	08893703          	ld	a4,136(s2)
    800022e8:	12068693          	addi	a3,a3,288
    800022ec:	0007b803          	ld	a6,0(a5)
    800022f0:	6788                	ld	a0,8(a5)
    800022f2:	6b8c                	ld	a1,16(a5)
    800022f4:	6f90                	ld	a2,24(a5)
    800022f6:	01073023          	sd	a6,0(a4)
    800022fa:	e708                	sd	a0,8(a4)
    800022fc:	eb0c                	sd	a1,16(a4)
    800022fe:	ef10                	sd	a2,24(a4)
    80002300:	02078793          	addi	a5,a5,32
    80002304:	02070713          	addi	a4,a4,32
    80002308:	fed792e3          	bne	a5,a3,800022ec <fork+0x56>
  np->trapframe->a0 = 0;
    8000230c:	08893783          	ld	a5,136(s2)
    80002310:	0607b823          	sd	zero,112(a5)
    80002314:	10000493          	li	s1,256
  for(i = 0; i < NOFILE; i++)
    80002318:	18000a13          	li	s4,384
    8000231c:	a03d                	j	8000234a <fork+0xb4>
    freeproc(np);
    8000231e:	854a                	mv	a0,s2
    80002320:	00000097          	auipc	ra,0x0
    80002324:	a5a080e7          	jalr	-1446(ra) # 80001d7a <freeproc>
    release(&np->lock);
    80002328:	854a                	mv	a0,s2
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	96e080e7          	jalr	-1682(ra) # 80000c98 <release>
    return -1;
    80002332:	5a7d                	li	s4,-1
    80002334:	aa39                	j	80002452 <fork+0x1bc>
      np->ofile[i] = filedup(p->ofile[i]);
    80002336:	00003097          	auipc	ra,0x3
    8000233a:	5fe080e7          	jalr	1534(ra) # 80005934 <filedup>
    8000233e:	009907b3          	add	a5,s2,s1
    80002342:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002344:	04a1                	addi	s1,s1,8
    80002346:	01448763          	beq	s1,s4,80002354 <fork+0xbe>
    if(p->ofile[i])
    8000234a:	009987b3          	add	a5,s3,s1
    8000234e:	6388                	ld	a0,0(a5)
    80002350:	f17d                	bnez	a0,80002336 <fork+0xa0>
    80002352:	bfcd                	j	80002344 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002354:	1809b503          	ld	a0,384(s3)
    80002358:	00002097          	auipc	ra,0x2
    8000235c:	752080e7          	jalr	1874(ra) # 80004aaa <idup>
    80002360:	18a93023          	sd	a0,384(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002364:	4641                	li	a2,16
    80002366:	18898593          	addi	a1,s3,392
    8000236a:	18890513          	addi	a0,s2,392
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	ac4080e7          	jalr	-1340(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002376:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    8000237a:	854a                	mv	a0,s2
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	91c080e7          	jalr	-1764(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002384:	00010497          	auipc	s1,0x10
    80002388:	f3c48493          	addi	s1,s1,-196 # 800122c0 <cpus>
    8000238c:	00010a97          	auipc	s5,0x10
    80002390:	3cca8a93          	addi	s5,s5,972 # 80012758 <wait_lock>
    80002394:	8556                	mv	a0,s5
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	84e080e7          	jalr	-1970(ra) # 80000be4 <acquire>
  np->parent = p;
    8000239e:	07393423          	sd	s3,104(s2)
  release(&wait_lock);
    800023a2:	8556                	mv	a0,s5
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
  acquire(&np->lock);
    800023ac:	854a                	mv	a0,s2
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	836080e7          	jalr	-1994(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023b6:	478d                	li	a5,3
    800023b8:	00f92c23          	sw	a5,24(s2)
  np->last_runnable_time = ticks;
    800023bc:	00008797          	auipc	a5,0x8
    800023c0:	c987a783          	lw	a5,-872(a5) # 8000a054 <ticks>
    800023c4:	02f92e23          	sw	a5,60(s2)
    800023c8:	8792                	mv	a5,tp
  int id = r_tp();
    800023ca:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800023ce:	00371793          	slli	a5,a4,0x3
    800023d2:	00e786b3          	add	a3,a5,a4
    800023d6:	0692                	slli	a3,a3,0x4
    800023d8:	96a6                	add	a3,a3,s1
    800023da:	08e6a423          	sw	a4,136(a3)
  if (mycpu()->runnable_list_head == -1){
    800023de:	0806a703          	lw	a4,128(a3)
    800023e2:	57fd                	li	a5,-1
    800023e4:	08f70163          	beq	a4,a5,80002466 <fork+0x1d0>
    printf("runnable");
    800023e8:	00007517          	auipc	a0,0x7
    800023ec:	ec850513          	addi	a0,a0,-312 # 800092b0 <digits+0x270>
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	198080e7          	jalr	408(ra) # 80000588 <printf>
    800023f8:	8792                	mv	a5,tp
  int id = r_tp();
    800023fa:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800023fe:	00010497          	auipc	s1,0x10
    80002402:	ec248493          	addi	s1,s1,-318 # 800122c0 <cpus>
    80002406:	00371793          	slli	a5,a4,0x3
    8000240a:	00e786b3          	add	a3,a5,a4
    8000240e:	0692                	slli	a3,a3,0x4
    80002410:	96a6                	add	a3,a3,s1
    80002412:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, np);
    80002416:	85ca                	mv	a1,s2
    80002418:	0846a503          	lw	a0,132(a3)
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	42a080e7          	jalr	1066(ra) # 80001846 <add_proc_to_list>
    80002424:	8792                	mv	a5,tp
  int id = r_tp();
    80002426:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    8000242a:	00371793          	slli	a5,a4,0x3
    8000242e:	00e786b3          	add	a3,a5,a4
    80002432:	0692                	slli	a3,a3,0x4
    80002434:	96a6                	add	a3,a3,s1
    80002436:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = np->proc_ind;
    8000243a:	05c92683          	lw	a3,92(s2)
    8000243e:	97ba                	add	a5,a5,a4
    80002440:	0792                	slli	a5,a5,0x4
    80002442:	94be                	add	s1,s1,a5
    80002444:	08d4a223          	sw	a3,132(s1)
  release(&np->lock);
    80002448:	854a                	mv	a0,s2
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	84e080e7          	jalr	-1970(ra) # 80000c98 <release>
}
    80002452:	8552                	mv	a0,s4
    80002454:	70e2                	ld	ra,56(sp)
    80002456:	7442                	ld	s0,48(sp)
    80002458:	74a2                	ld	s1,40(sp)
    8000245a:	7902                	ld	s2,32(sp)
    8000245c:	69e2                	ld	s3,24(sp)
    8000245e:	6a42                	ld	s4,16(sp)
    80002460:	6aa2                	ld	s5,8(sp)
    80002462:	6121                	addi	sp,sp,64
    80002464:	8082                	ret
    printf("init runnable %d\n", p->proc_ind);
    80002466:	05c9a583          	lw	a1,92(s3)
    8000246a:	00007517          	auipc	a0,0x7
    8000246e:	e5650513          	addi	a0,a0,-426 # 800092c0 <digits+0x280>
    80002472:	ffffe097          	auipc	ra,0xffffe
    80002476:	116080e7          	jalr	278(ra) # 80000588 <printf>
    8000247a:	8792                	mv	a5,tp
  int id = r_tp();
    8000247c:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002480:	00369793          	slli	a5,a3,0x3
    80002484:	00d78633          	add	a2,a5,a3
    80002488:	0612                	slli	a2,a2,0x4
    8000248a:	9626                	add	a2,a2,s1
    8000248c:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = np->proc_ind;
    80002490:	05c92603          	lw	a2,92(s2)
    80002494:	97b6                	add	a5,a5,a3
    80002496:	0792                	slli	a5,a5,0x4
    80002498:	97a6                	add	a5,a5,s1
    8000249a:	08c7a023          	sw	a2,128(a5)
    8000249e:	8792                	mv	a5,tp
  int id = r_tp();
    800024a0:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    800024a4:	00369793          	slli	a5,a3,0x3
    800024a8:	00d78633          	add	a2,a5,a3
    800024ac:	0612                	slli	a2,a2,0x4
    800024ae:	9626                	add	a2,a2,s1
    800024b0:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = np->proc_ind;
    800024b4:	05c92603          	lw	a2,92(s2)
    800024b8:	97b6                	add	a5,a5,a3
    800024ba:	0792                	slli	a5,a5,0x4
    800024bc:	00f48733          	add	a4,s1,a5
    800024c0:	08c72223          	sw	a2,132(a4)
    800024c4:	b751                	j	80002448 <fork+0x1b2>
    return -1;
    800024c6:	5a7d                	li	s4,-1
    800024c8:	b769                	j	80002452 <fork+0x1bc>

00000000800024ca <unpause_system>:
{
    800024ca:	7179                	addi	sp,sp,-48
    800024cc:	f406                	sd	ra,40(sp)
    800024ce:	f022                	sd	s0,32(sp)
    800024d0:	ec26                	sd	s1,24(sp)
    800024d2:	e84a                	sd	s2,16(sp)
    800024d4:	e44e                	sd	s3,8(sp)
    800024d6:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) 
    800024d8:	00010497          	auipc	s1,0x10
    800024dc:	29848493          	addi	s1,s1,664 # 80012770 <proc>
      if(p->paused == 1) 
    800024e0:	4985                	li	s3,1
  for(p = proc; p < &proc[NPROC]; p++) 
    800024e2:	00017917          	auipc	s2,0x17
    800024e6:	88e90913          	addi	s2,s2,-1906 # 80018d70 <tickslock>
    800024ea:	a811                	j	800024fe <unpause_system+0x34>
      release(&p->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	7aa080e7          	jalr	1962(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) 
    800024f6:	19848493          	addi	s1,s1,408
    800024fa:	01248d63          	beq	s1,s2,80002514 <unpause_system+0x4a>
      acquire(&p->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	6e4080e7          	jalr	1764(ra) # 80000be4 <acquire>
      if(p->paused == 1) 
    80002508:	40bc                	lw	a5,64(s1)
    8000250a:	ff3791e3          	bne	a5,s3,800024ec <unpause_system+0x22>
        p->paused = 0;
    8000250e:	0404a023          	sw	zero,64(s1)
    80002512:	bfe9                	j	800024ec <unpause_system+0x22>
} 
    80002514:	70a2                	ld	ra,40(sp)
    80002516:	7402                	ld	s0,32(sp)
    80002518:	64e2                	ld	s1,24(sp)
    8000251a:	6942                	ld	s2,16(sp)
    8000251c:	69a2                	ld	s3,8(sp)
    8000251e:	6145                	addi	sp,sp,48
    80002520:	8082                	ret

0000000080002522 <SJF_scheduler>:
{
    80002522:	711d                	addi	sp,sp,-96
    80002524:	ec86                	sd	ra,88(sp)
    80002526:	e8a2                	sd	s0,80(sp)
    80002528:	e4a6                	sd	s1,72(sp)
    8000252a:	e0ca                	sd	s2,64(sp)
    8000252c:	fc4e                	sd	s3,56(sp)
    8000252e:	f852                	sd	s4,48(sp)
    80002530:	f456                	sd	s5,40(sp)
    80002532:	f05a                	sd	s6,32(sp)
    80002534:	ec5e                	sd	s7,24(sp)
    80002536:	e862                	sd	s8,16(sp)
    80002538:	e466                	sd	s9,8(sp)
    8000253a:	e06a                	sd	s10,0(sp)
    8000253c:	1080                	addi	s0,sp,96
    8000253e:	8792                	mv	a5,tp
  int id = r_tp();
    80002540:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80002542:	00010617          	auipc	a2,0x10
    80002546:	d7e60613          	addi	a2,a2,-642 # 800122c0 <cpus>
    8000254a:	00379713          	slli	a4,a5,0x3
    8000254e:	00f706b3          	add	a3,a4,a5
    80002552:	0692                	slli	a3,a3,0x4
    80002554:	96b2                	add	a3,a3,a2
    80002556:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    8000255a:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p_of_min->context);
    8000255e:	973e                	add	a4,a4,a5
    80002560:	0712                	slli	a4,a4,0x4
    80002562:	0721                	addi	a4,a4,8
    80002564:	00e60d33          	add	s10,a2,a4
    struct proc* p_of_min = proc;
    80002568:	00010a97          	auipc	s5,0x10
    8000256c:	208a8a93          	addi	s5,s5,520 # 80012770 <proc>
    uint min = INT_MAX;
    80002570:	80000b37          	lui	s6,0x80000
    80002574:	fffb4b13          	not	s6,s6
           should_switch = 1;
    80002578:	4a05                	li	s4,1
    8000257a:	89d2                	mv	s3,s4
      c->proc = p_of_min;
    8000257c:	8bb6                	mv	s7,a3
    8000257e:	a091                	j	800025c2 <SJF_scheduler+0xa0>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002580:	19878793          	addi	a5,a5,408
    80002584:	00d78c63          	beq	a5,a3,8000259c <SJF_scheduler+0x7a>
       if(p->state == RUNNABLE) {
    80002588:	4f98                	lw	a4,24(a5)
    8000258a:	fec71be3          	bne	a4,a2,80002580 <SJF_scheduler+0x5e>
         if (p->mean_ticks < min)
    8000258e:	5bd8                	lw	a4,52(a5)
    80002590:	feb778e3          	bgeu	a4,a1,80002580 <SJF_scheduler+0x5e>
    80002594:	84be                	mv	s1,a5
           min = p->mean_ticks;
    80002596:	85ba                	mv	a1,a4
           should_switch = 1;
    80002598:	894e                	mv	s2,s3
    8000259a:	b7dd                	j	80002580 <SJF_scheduler+0x5e>
    acquire(&p_of_min->lock);
    8000259c:	8c26                	mv	s8,s1
    8000259e:	8526                	mv	a0,s1
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    800025a8:	03490d63          	beq	s2,s4,800025e2 <SJF_scheduler+0xc0>
    release(&p_of_min->lock);
    800025ac:	8562                	mv	a0,s8
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    800025b6:	00008797          	auipc	a5,0x8
    800025ba:	a9a7a783          	lw	a5,-1382(a5) # 8000a050 <pause_flag>
    800025be:	0b478163          	beq	a5,s4,80002660 <SJF_scheduler+0x13e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025ca:	10079073          	csrw	sstatus,a5
    int should_switch = 0;
    800025ce:	4901                	li	s2,0
    struct proc* p_of_min = proc;
    800025d0:	84d6                	mv	s1,s5
    uint min = INT_MAX;
    800025d2:	85da                	mv	a1,s6
    for(p = proc; p < &proc[NPROC]; p++) {
    800025d4:	87d6                	mv	a5,s5
       if(p->state == RUNNABLE) {
    800025d6:	460d                	li	a2,3
    for(p = proc; p < &proc[NPROC]; p++) {
    800025d8:	00016697          	auipc	a3,0x16
    800025dc:	79868693          	addi	a3,a3,1944 # 80018d70 <tickslock>
    800025e0:	b765                	j	80002588 <SJF_scheduler+0x66>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    800025e2:	4c98                	lw	a4,24(s1)
    800025e4:	478d                	li	a5,3
    800025e6:	fcf713e3          	bne	a4,a5,800025ac <SJF_scheduler+0x8a>
    800025ea:	40bc                	lw	a5,64(s1)
    800025ec:	f3e1                	bnez	a5,800025ac <SJF_scheduler+0x8a>
      p_of_min->state = RUNNING;
    800025ee:	4791                	li	a5,4
    800025f0:	cc9c                	sw	a5,24(s1)
      p_of_min->start_running_time = ticks;
    800025f2:	00008c97          	auipc	s9,0x8
    800025f6:	a62c8c93          	addi	s9,s9,-1438 # 8000a054 <ticks>
    800025fa:	000ca903          	lw	s2,0(s9)
    800025fe:	0524a823          	sw	s2,80(s1)
      p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    80002602:	44bc                	lw	a5,72(s1)
    80002604:	012787bb          	addw	a5,a5,s2
    80002608:	5cd8                	lw	a4,60(s1)
    8000260a:	9f99                	subw	a5,a5,a4
    8000260c:	c4bc                	sw	a5,72(s1)
      c->proc = p_of_min;
    8000260e:	009bb023          	sd	s1,0(s7) # fffffffffffff000 <end+0xffffffff7ffd7000>
      swtch(&c->context, &p_of_min->context);
    80002612:	09048593          	addi	a1,s1,144
    80002616:	856a                	mv	a0,s10
    80002618:	00001097          	auipc	ra,0x1
    8000261c:	3b2080e7          	jalr	946(ra) # 800039ca <swtch>
      p_of_min->last_ticks= ticks - before_swtch;
    80002620:	000ca783          	lw	a5,0(s9)
    80002624:	4127893b          	subw	s2,a5,s2
    80002628:	0324ac23          	sw	s2,56(s1)
      p_of_min->mean_ticks=((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10 ;
    8000262c:	00007617          	auipc	a2,0x7
    80002630:	42462603          	lw	a2,1060(a2) # 80009a50 <rate>
    80002634:	46a9                	li	a3,10
    80002636:	40c687bb          	subw	a5,a3,a2
    8000263a:	00016717          	auipc	a4,0x16
    8000263e:	13670713          	addi	a4,a4,310 # 80018770 <proc+0x6000>
    80002642:	63472583          	lw	a1,1588(a4)
    80002646:	02b787bb          	mulw	a5,a5,a1
    8000264a:	63872703          	lw	a4,1592(a4)
    8000264e:	02c7073b          	mulw	a4,a4,a2
    80002652:	9fb9                	addw	a5,a5,a4
    80002654:	02d7d7bb          	divuw	a5,a5,a3
    80002658:	d8dc                	sw	a5,52(s1)
      c->proc = 0;
    8000265a:	000bb023          	sd	zero,0(s7)
    8000265e:	b7b9                	j	800025ac <SJF_scheduler+0x8a>
      if (wake_up_time <= ticks) 
    80002660:	00008717          	auipc	a4,0x8
    80002664:	9ec72703          	lw	a4,-1556(a4) # 8000a04c <wake_up_time>
    80002668:	00008797          	auipc	a5,0x8
    8000266c:	9ec7a783          	lw	a5,-1556(a5) # 8000a054 <ticks>
    80002670:	f4e7e9e3          	bltu	a5,a4,800025c2 <SJF_scheduler+0xa0>
        pause_flag = 0;
    80002674:	00008797          	auipc	a5,0x8
    80002678:	9c07ae23          	sw	zero,-1572(a5) # 8000a050 <pause_flag>
        unpause_system();
    8000267c:	00000097          	auipc	ra,0x0
    80002680:	e4e080e7          	jalr	-434(ra) # 800024ca <unpause_system>
    80002684:	bf3d                	j	800025c2 <SJF_scheduler+0xa0>

0000000080002686 <FCFS_scheduler>:
{
    80002686:	7119                	addi	sp,sp,-128
    80002688:	fc86                	sd	ra,120(sp)
    8000268a:	f8a2                	sd	s0,112(sp)
    8000268c:	f4a6                	sd	s1,104(sp)
    8000268e:	f0ca                	sd	s2,96(sp)
    80002690:	ecce                	sd	s3,88(sp)
    80002692:	e8d2                	sd	s4,80(sp)
    80002694:	e4d6                	sd	s5,72(sp)
    80002696:	e0da                	sd	s6,64(sp)
    80002698:	fc5e                	sd	s7,56(sp)
    8000269a:	f862                	sd	s8,48(sp)
    8000269c:	f466                	sd	s9,40(sp)
    8000269e:	f06a                	sd	s10,32(sp)
    800026a0:	ec6e                	sd	s11,24(sp)
    800026a2:	0100                	addi	s0,sp,128
  asm volatile("mv %0, tp" : "=r" (x) );
    800026a4:	8792                	mv	a5,tp
  int id = r_tp();
    800026a6:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800026a8:	00010617          	auipc	a2,0x10
    800026ac:	c1860613          	addi	a2,a2,-1000 # 800122c0 <cpus>
    800026b0:	00379713          	slli	a4,a5,0x3
    800026b4:	00f706b3          	add	a3,a4,a5
    800026b8:	0692                	slli	a3,a3,0x4
    800026ba:	96b2                	add	a3,a3,a2
    800026bc:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    800026c0:	0006b023          	sd	zero,0(a3)
        swtch(&c->context, &p_of_min->context);
    800026c4:	973e                	add	a4,a4,a5
    800026c6:	0712                	slli	a4,a4,0x4
    800026c8:	0721                	addi	a4,a4,8
    800026ca:	9732                	add	a4,a4,a2
    800026cc:	f8e43423          	sd	a4,-120(s0)
  int should_switch = 0;
    800026d0:	4b01                	li	s6,0
    struct proc *p_of_min = proc;
    800026d2:	00010c17          	auipc	s8,0x10
    800026d6:	09ec0c13          	addi	s8,s8,158 # 80012770 <proc>
    uint minlast_runnable = INT_MAX;
    800026da:	80000d37          	lui	s10,0x80000
    800026de:	fffd4d13          	not	s10,s10
          should_switch = 1;
    800026e2:	4c85                	li	s9,1
    800026e4:	8be6                	mv	s7,s9
        c->proc = p_of_min;
    800026e6:	8db6                	mv	s11,a3
    800026e8:	a095                	j	8000274c <FCFS_scheduler+0xc6>
      release(&p->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	5ac080e7          	jalr	1452(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) 
    800026f4:	19848493          	addi	s1,s1,408
    800026f8:	03248463          	beq	s1,s2,80002720 <FCFS_scheduler+0x9a>
      acquire(&p->lock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	4e6080e7          	jalr	1254(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && p->paused == 0) 
    80002706:	4c9c                	lw	a5,24(s1)
    80002708:	ff3791e3          	bne	a5,s3,800026ea <FCFS_scheduler+0x64>
    8000270c:	40bc                	lw	a5,64(s1)
    8000270e:	fff1                	bnez	a5,800026ea <FCFS_scheduler+0x64>
        if(p->last_runnable_time <= minlast_runnable)
    80002710:	5cdc                	lw	a5,60(s1)
    80002712:	fcfa6ce3          	bltu	s4,a5,800026ea <FCFS_scheduler+0x64>
          minlast_runnable = p->mean_ticks;
    80002716:	0344aa03          	lw	s4,52(s1)
    8000271a:	8aa6                	mv	s5,s1
          should_switch = 1;
    8000271c:	8b5e                	mv	s6,s7
    8000271e:	b7f1                	j	800026ea <FCFS_scheduler+0x64>
    acquire(&p_of_min->lock);
    80002720:	8956                	mv	s2,s5
    80002722:	8556                	mv	a0,s5
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	4c0080e7          	jalr	1216(ra) # 80000be4 <acquire>
    if (p_of_min->paused == 0)
    8000272c:	040aa483          	lw	s1,64(s5)
    80002730:	e099                	bnez	s1,80002736 <FCFS_scheduler+0xb0>
      if (should_switch == 1 && p_of_min->pid > -1)
    80002732:	039b0c63          	beq	s6,s9,8000276a <FCFS_scheduler+0xe4>
    release(&p_of_min->lock);
    80002736:	854a                	mv	a0,s2
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	560080e7          	jalr	1376(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    80002740:	00008797          	auipc	a5,0x8
    80002744:	9107a783          	lw	a5,-1776(a5) # 8000a050 <pause_flag>
    80002748:	07978463          	beq	a5,s9,800027b0 <FCFS_scheduler+0x12a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000274c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002750:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002754:	10079073          	csrw	sstatus,a5
    struct proc *p_of_min = proc;
    80002758:	8ae2                	mv	s5,s8
    uint minlast_runnable = INT_MAX;
    8000275a:	8a6a                	mv	s4,s10
    for(p = proc; p < &proc[NPROC]; p++) 
    8000275c:	84e2                	mv	s1,s8
      if(p->state == RUNNABLE && p->paused == 0) 
    8000275e:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) 
    80002760:	00016917          	auipc	s2,0x16
    80002764:	61090913          	addi	s2,s2,1552 # 80018d70 <tickslock>
    80002768:	bf51                	j	800026fc <FCFS_scheduler+0x76>
      if (should_switch == 1 && p_of_min->pid > -1)
    8000276a:	030aa783          	lw	a5,48(s5)
    8000276e:	fc07c4e3          	bltz	a5,80002736 <FCFS_scheduler+0xb0>
        p_of_min->state = RUNNING;
    80002772:	4791                	li	a5,4
    80002774:	00faac23          	sw	a5,24(s5)
        p_of_min->start_running_time = ticks;
    80002778:	00008717          	auipc	a4,0x8
    8000277c:	8dc72703          	lw	a4,-1828(a4) # 8000a054 <ticks>
    80002780:	04eaa823          	sw	a4,80(s5)
        p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    80002784:	048aa783          	lw	a5,72(s5)
    80002788:	9fb9                	addw	a5,a5,a4
    8000278a:	03caa703          	lw	a4,60(s5)
    8000278e:	9f99                	subw	a5,a5,a4
    80002790:	04faa423          	sw	a5,72(s5)
        c->proc = p_of_min;
    80002794:	015db023          	sd	s5,0(s11)
        swtch(&c->context, &p_of_min->context);
    80002798:	090a8593          	addi	a1,s5,144
    8000279c:	f8843503          	ld	a0,-120(s0)
    800027a0:	00001097          	auipc	ra,0x1
    800027a4:	22a080e7          	jalr	554(ra) # 800039ca <swtch>
        c->proc = 0;
    800027a8:	000db023          	sd	zero,0(s11)
        should_switch = 0;
    800027ac:	8b26                	mv	s6,s1
    800027ae:	b761                	j	80002736 <FCFS_scheduler+0xb0>
      if (wake_up_time <= ticks) 
    800027b0:	00008717          	auipc	a4,0x8
    800027b4:	89c72703          	lw	a4,-1892(a4) # 8000a04c <wake_up_time>
    800027b8:	00008797          	auipc	a5,0x8
    800027bc:	89c7a783          	lw	a5,-1892(a5) # 8000a054 <ticks>
    800027c0:	f8e7e6e3          	bltu	a5,a4,8000274c <FCFS_scheduler+0xc6>
        pause_flag = 0;
    800027c4:	00008797          	auipc	a5,0x8
    800027c8:	8807a623          	sw	zero,-1908(a5) # 8000a050 <pause_flag>
        unpause_system();
    800027cc:	00000097          	auipc	ra,0x0
    800027d0:	cfe080e7          	jalr	-770(ra) # 800024ca <unpause_system>
    800027d4:	bfa5                	j	8000274c <FCFS_scheduler+0xc6>

00000000800027d6 <scheduler>:
{
    800027d6:	7159                	addi	sp,sp,-112
    800027d8:	f486                	sd	ra,104(sp)
    800027da:	f0a2                	sd	s0,96(sp)
    800027dc:	eca6                	sd	s1,88(sp)
    800027de:	e8ca                	sd	s2,80(sp)
    800027e0:	e4ce                	sd	s3,72(sp)
    800027e2:	e0d2                	sd	s4,64(sp)
    800027e4:	fc56                	sd	s5,56(sp)
    800027e6:	f85a                	sd	s6,48(sp)
    800027e8:	f45e                	sd	s7,40(sp)
    800027ea:	f062                	sd	s8,32(sp)
    800027ec:	ec66                	sd	s9,24(sp)
    800027ee:	e86a                	sd	s10,16(sp)
    800027f0:	e46e                	sd	s11,8(sp)
    800027f2:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    800027f4:	8792                	mv	a5,tp
  int id = r_tp();
    800027f6:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800027f8:	00010c17          	auipc	s8,0x10
    800027fc:	ac8c0c13          	addi	s8,s8,-1336 # 800122c0 <cpus>
    80002800:	00379713          	slli	a4,a5,0x3
    80002804:	00f706b3          	add	a3,a4,a5
    80002808:	0692                	slli	a3,a3,0x4
    8000280a:	96e2                	add	a3,a3,s8
    8000280c:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    80002810:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    80002814:	973e                	add	a4,a4,a5
    80002816:	0712                	slli	a4,a4,0x4
    80002818:	0721                	addi	a4,a4,8
    8000281a:	9c3a                	add	s8,s8,a4
    printf("start sched\n");
    8000281c:	00007a17          	auipc	s4,0x7
    80002820:	abca0a13          	addi	s4,s4,-1348 # 800092d8 <digits+0x298>
    if (c->runnable_list_head != -1)
    80002824:	8936                	mv	s2,a3
    80002826:	59fd                	li	s3,-1
    80002828:	19800b13          	li	s6,408
      p = &proc[c->runnable_list_head];
    8000282c:	00010a97          	auipc	s5,0x10
    80002830:	f44a8a93          	addi	s5,s5,-188 # 80012770 <proc>
      printf("proc ind: %d\n", c->runnable_list_head);
    80002834:	00007c97          	auipc	s9,0x7
    80002838:	ab4c8c93          	addi	s9,s9,-1356 # 800092e8 <digits+0x2a8>
        proc[p->prev_proc].next_proc = -1;
    8000283c:	5bfd                	li	s7,-1
    8000283e:	a075                	j	800028ea <scheduler+0x114>
        c->runnable_list_head = -1;
    80002840:	09792023          	sw	s7,128(s2)
        c->runnable_list_tail = -1;
    80002844:	09792223          	sw	s7,132(s2)
      acquire(&p->lock);
    80002848:	856a                	mv	a0,s10
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	39a080e7          	jalr	922(ra) # 80000be4 <acquire>
      p->prev_proc = -1;
    80002852:	036487b3          	mul	a5,s1,s6
    80002856:	97d6                	add	a5,a5,s5
    80002858:	0777a223          	sw	s7,100(a5)
      p->next_proc = -1;
    8000285c:	0777a023          	sw	s7,96(a5)
      p->state = RUNNING;
    80002860:	4711                	li	a4,4
    80002862:	cf98                	sw	a4,24(a5)
      p->cpu_num = c->cpu_id;
    80002864:	08892703          	lw	a4,136(s2)
    80002868:	cfb8                	sw	a4,88(a5)
      c->proc = p;
    8000286a:	01a93023          	sd	s10,0(s2)
      swtch(&c->context, &p->context);
    8000286e:	090d8593          	addi	a1,s11,144
    80002872:	95d6                	add	a1,a1,s5
    80002874:	8562                	mv	a0,s8
    80002876:	00001097          	auipc	ra,0x1
    8000287a:	154080e7          	jalr	340(ra) # 800039ca <swtch>
      printf("runable");
    8000287e:	00007517          	auipc	a0,0x7
    80002882:	a8a50513          	addi	a0,a0,-1398 # 80009308 <digits+0x2c8>
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	d02080e7          	jalr	-766(ra) # 80000588 <printf>
      if (c->runnable_list_head == -1)
    8000288e:	08092783          	lw	a5,128(s2)
    80002892:	0f379c63          	bne	a5,s3,8000298a <scheduler+0x1b4>
        printf("init runnable %d\n", p->proc_ind);
    80002896:	036484b3          	mul	s1,s1,s6
    8000289a:	94d6                	add	s1,s1,s5
    8000289c:	4cec                	lw	a1,92(s1)
    8000289e:	00007517          	auipc	a0,0x7
    800028a2:	a2250513          	addi	a0,a0,-1502 # 800092c0 <digits+0x280>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
        c->runnable_list_head = p->proc_ind;
    800028ae:	4cfc                	lw	a5,92(s1)
    800028b0:	08f92023          	sw	a5,128(s2)
        c->runnable_list_tail = p->proc_ind;
    800028b4:	08f92223          	sw	a5,132(s2)
      printf("added back: %d\n", c->runnable_list_tail);
    800028b8:	08492583          	lw	a1,132(s2)
    800028bc:	00007517          	auipc	a0,0x7
    800028c0:	a5450513          	addi	a0,a0,-1452 # 80009310 <digits+0x2d0>
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	cc4080e7          	jalr	-828(ra) # 80000588 <printf>
      c->proc = 0;
    800028cc:	00093023          	sd	zero,0(s2)
      release(&p->lock);
    800028d0:	856a                	mv	a0,s10
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	3c6080e7          	jalr	966(ra) # 80000c98 <release>
      printf("end sched\n");
    800028da:	00007517          	auipc	a0,0x7
    800028de:	a4650513          	addi	a0,a0,-1466 # 80009320 <digits+0x2e0>
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	ca6080e7          	jalr	-858(ra) # 80000588 <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f2:	10079073          	csrw	sstatus,a5
    printf("start sched\n");
    800028f6:	8552                	mv	a0,s4
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	c90080e7          	jalr	-880(ra) # 80000588 <printf>
    if (c->runnable_list_head != -1)
    80002900:	08092483          	lw	s1,128(s2)
    80002904:	ff3483e3          	beq	s1,s3,800028ea <scheduler+0x114>
      p = &proc[c->runnable_list_head];
    80002908:	03648db3          	mul	s11,s1,s6
    8000290c:	015d8d33          	add	s10,s11,s5
      printf("proc ind: %d\n", c->runnable_list_head);
    80002910:	85a6                	mv	a1,s1
    80002912:	8566                	mv	a0,s9
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	c74080e7          	jalr	-908(ra) # 80000588 <printf>
      printf("runnable");
    8000291c:	00007517          	auipc	a0,0x7
    80002920:	99450513          	addi	a0,a0,-1644 # 800092b0 <digits+0x270>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c64080e7          	jalr	-924(ra) # 80000588 <printf>
      int res = remove_proc_from_list(p->proc_ind); 
    8000292c:	05cd2503          	lw	a0,92(s10) # ffffffff8000005c <end+0xfffffffefffd805c>
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	f94080e7          	jalr	-108(ra) # 800018c4 <remove_proc_from_list>
      if (res == 1){
    80002938:	4785                	li	a5,1
    8000293a:	f0f503e3          	beq	a0,a5,80002840 <scheduler+0x6a>
      if (res == 2)
    8000293e:	4789                	li	a5,2
    80002940:	02f50163          	beq	a0,a5,80002962 <scheduler+0x18c>
      if (res == 3){
    80002944:	478d                	li	a5,3
    80002946:	f0f511e3          	bne	a0,a5,80002848 <scheduler+0x72>
        c->runnable_list_tail = p->prev_proc;
    8000294a:	036487b3          	mul	a5,s1,s6
    8000294e:	97d6                	add	a5,a5,s5
    80002950:	53fc                	lw	a5,100(a5)
    80002952:	08f92223          	sw	a5,132(s2)
        proc[p->prev_proc].next_proc = -1;
    80002956:	036787b3          	mul	a5,a5,s6
    8000295a:	97d6                	add	a5,a5,s5
    8000295c:	0777a023          	sw	s7,96(a5)
    80002960:	b5e5                	j	80002848 <scheduler+0x72>
        c->runnable_list_head = p->next_proc;
    80002962:	036487b3          	mul	a5,s1,s6
    80002966:	97d6                	add	a5,a5,s5
    80002968:	53ac                	lw	a1,96(a5)
    8000296a:	08b92023          	sw	a1,128(s2)
        proc[p->next_proc].prev_proc = -1;
    8000296e:	036587b3          	mul	a5,a1,s6
    80002972:	97d6                	add	a5,a5,s5
    80002974:	0777a223          	sw	s7,100(a5)
        printf("New head: %d\n", c->runnable_list_head);
    80002978:	00007517          	auipc	a0,0x7
    8000297c:	98050513          	addi	a0,a0,-1664 # 800092f8 <digits+0x2b8>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c08080e7          	jalr	-1016(ra) # 80000588 <printf>
      if (res == 3){
    80002988:	b5c1                	j	80002848 <scheduler+0x72>
        add_proc_to_list(c->runnable_list_tail, p);
    8000298a:	85ea                	mv	a1,s10
    8000298c:	08492503          	lw	a0,132(s2)
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	eb6080e7          	jalr	-330(ra) # 80001846 <add_proc_to_list>
        c->runnable_list_tail = p->proc_ind;
    80002998:	036484b3          	mul	s1,s1,s6
    8000299c:	94d6                	add	s1,s1,s5
    8000299e:	4cfc                	lw	a5,92(s1)
    800029a0:	08f92223          	sw	a5,132(s2)
    800029a4:	bf11                	j	800028b8 <scheduler+0xe2>

00000000800029a6 <sched>:
{
    800029a6:	7179                	addi	sp,sp,-48
    800029a8:	f406                	sd	ra,40(sp)
    800029aa:	f022                	sd	s0,32(sp)
    800029ac:	ec26                	sd	s1,24(sp)
    800029ae:	e84a                	sd	s2,16(sp)
    800029b0:	e44e                	sd	s3,8(sp)
    800029b2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800029b4:	fffff097          	auipc	ra,0xfffff
    800029b8:	210080e7          	jalr	528(ra) # 80001bc4 <myproc>
    800029bc:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	1ac080e7          	jalr	428(ra) # 80000b6a <holding>
    800029c6:	c55d                	beqz	a0,80002a74 <sched+0xce>
  asm volatile("mv %0, tp" : "=r" (x) );
    800029c8:	8792                	mv	a5,tp
  int id = r_tp();
    800029ca:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800029ce:	00010617          	auipc	a2,0x10
    800029d2:	8f260613          	addi	a2,a2,-1806 # 800122c0 <cpus>
    800029d6:	00371793          	slli	a5,a4,0x3
    800029da:	00e786b3          	add	a3,a5,a4
    800029de:	0692                	slli	a3,a3,0x4
    800029e0:	96b2                	add	a3,a3,a2
    800029e2:	08e6a423          	sw	a4,136(a3)
  if(mycpu()->noff != 1)
    800029e6:	5eb8                	lw	a4,120(a3)
    800029e8:	4785                	li	a5,1
    800029ea:	08f71d63          	bne	a4,a5,80002a84 <sched+0xde>
  if(p->state == RUNNING)
    800029ee:	01892703          	lw	a4,24(s2)
    800029f2:	4791                	li	a5,4
    800029f4:	0af70063          	beq	a4,a5,80002a94 <sched+0xee>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029fc:	8b89                	andi	a5,a5,2
  if(intr_get())
    800029fe:	e3dd                	bnez	a5,80002aa4 <sched+0xfe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a00:	8792                	mv	a5,tp
  int id = r_tp();
    80002a02:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002a06:	00010497          	auipc	s1,0x10
    80002a0a:	8ba48493          	addi	s1,s1,-1862 # 800122c0 <cpus>
    80002a0e:	00371793          	slli	a5,a4,0x3
    80002a12:	00e786b3          	add	a3,a5,a4
    80002a16:	0692                	slli	a3,a3,0x4
    80002a18:	96a6                	add	a3,a3,s1
    80002a1a:	08e6a423          	sw	a4,136(a3)
  intena = mycpu()->intena;
    80002a1e:	07c6a983          	lw	s3,124(a3)
    80002a22:	8592                	mv	a1,tp
  int id = r_tp();
    80002a24:	0005879b          	sext.w	a5,a1
  c->cpu_id = id;
    80002a28:	00379593          	slli	a1,a5,0x3
    80002a2c:	00f58733          	add	a4,a1,a5
    80002a30:	0712                	slli	a4,a4,0x4
    80002a32:	9726                	add	a4,a4,s1
    80002a34:	08f72423          	sw	a5,136(a4)
  swtch(&p->context, &mycpu()->context);
    80002a38:	95be                	add	a1,a1,a5
    80002a3a:	0592                	slli	a1,a1,0x4
    80002a3c:	05a1                	addi	a1,a1,8
    80002a3e:	95a6                	add	a1,a1,s1
    80002a40:	09090513          	addi	a0,s2,144
    80002a44:	00001097          	auipc	ra,0x1
    80002a48:	f86080e7          	jalr	-122(ra) # 800039ca <swtch>
    80002a4c:	8792                	mv	a5,tp
  int id = r_tp();
    80002a4e:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002a52:	00371793          	slli	a5,a4,0x3
    80002a56:	00e786b3          	add	a3,a5,a4
    80002a5a:	0692                	slli	a3,a3,0x4
    80002a5c:	96a6                	add	a3,a3,s1
    80002a5e:	08e6a423          	sw	a4,136(a3)
  mycpu()->intena = intena;
    80002a62:	0736ae23          	sw	s3,124(a3)
}
    80002a66:	70a2                	ld	ra,40(sp)
    80002a68:	7402                	ld	s0,32(sp)
    80002a6a:	64e2                	ld	s1,24(sp)
    80002a6c:	6942                	ld	s2,16(sp)
    80002a6e:	69a2                	ld	s3,8(sp)
    80002a70:	6145                	addi	sp,sp,48
    80002a72:	8082                	ret
    panic("sched p->lock");
    80002a74:	00007517          	auipc	a0,0x7
    80002a78:	8bc50513          	addi	a0,a0,-1860 # 80009330 <digits+0x2f0>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	ac2080e7          	jalr	-1342(ra) # 8000053e <panic>
    panic("sched locks");
    80002a84:	00007517          	auipc	a0,0x7
    80002a88:	8bc50513          	addi	a0,a0,-1860 # 80009340 <digits+0x300>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	ab2080e7          	jalr	-1358(ra) # 8000053e <panic>
    panic("sched running");
    80002a94:	00007517          	auipc	a0,0x7
    80002a98:	8bc50513          	addi	a0,a0,-1860 # 80009350 <digits+0x310>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	aa2080e7          	jalr	-1374(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002aa4:	00007517          	auipc	a0,0x7
    80002aa8:	8bc50513          	addi	a0,a0,-1860 # 80009360 <digits+0x320>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>

0000000080002ab4 <yield>:
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	e04a                	sd	s2,0(sp)
    80002abe:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	104080e7          	jalr	260(ra) # 80001bc4 <myproc>
    80002ac8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	11a080e7          	jalr	282(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002ad2:	478d                	li	a5,3
    80002ad4:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002ad6:	00007797          	auipc	a5,0x7
    80002ada:	57e7a783          	lw	a5,1406(a5) # 8000a054 <ticks>
    80002ade:	dcdc                	sw	a5,60(s1)
    80002ae0:	8792                	mv	a5,tp
  int id = r_tp();
    80002ae2:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002ae6:	0000f617          	auipc	a2,0xf
    80002aea:	7da60613          	addi	a2,a2,2010 # 800122c0 <cpus>
    80002aee:	00371793          	slli	a5,a4,0x3
    80002af2:	00e786b3          	add	a3,a5,a4
    80002af6:	0692                	slli	a3,a3,0x4
    80002af8:	96b2                	add	a3,a3,a2
    80002afa:	08e6a423          	sw	a4,136(a3)
   if (mycpu()->runnable_list_head == -1)
    80002afe:	0806a703          	lw	a4,128(a3)
    80002b02:	57fd                	li	a5,-1
    80002b04:	08f70063          	beq	a4,a5,80002b84 <yield+0xd0>
    printf("runable");
    80002b08:	00007517          	auipc	a0,0x7
    80002b0c:	80050513          	addi	a0,a0,-2048 # 80009308 <digits+0x2c8>
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	a78080e7          	jalr	-1416(ra) # 80000588 <printf>
    80002b18:	8792                	mv	a5,tp
  int id = r_tp();
    80002b1a:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b1e:	0000f917          	auipc	s2,0xf
    80002b22:	7a290913          	addi	s2,s2,1954 # 800122c0 <cpus>
    80002b26:	00371793          	slli	a5,a4,0x3
    80002b2a:	00e786b3          	add	a3,a5,a4
    80002b2e:	0692                	slli	a3,a3,0x4
    80002b30:	96ca                	add	a3,a3,s2
    80002b32:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    80002b36:	85a6                	mv	a1,s1
    80002b38:	0846a503          	lw	a0,132(a3)
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	d0a080e7          	jalr	-758(ra) # 80001846 <add_proc_to_list>
    80002b44:	8792                	mv	a5,tp
  int id = r_tp();
    80002b46:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b4a:	00371793          	slli	a5,a4,0x3
    80002b4e:	00e786b3          	add	a3,a5,a4
    80002b52:	0692                	slli	a3,a3,0x4
    80002b54:	96ca                	add	a3,a3,s2
    80002b56:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002b5a:	4cf4                	lw	a3,92(s1)
    80002b5c:	97ba                	add	a5,a5,a4
    80002b5e:	0792                	slli	a5,a5,0x4
    80002b60:	993e                	add	s2,s2,a5
    80002b62:	08d92223          	sw	a3,132(s2)
  sched();
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	e40080e7          	jalr	-448(ra) # 800029a6 <sched>
  release(&p->lock);
    80002b6e:	8526                	mv	a0,s1
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	128080e7          	jalr	296(ra) # 80000c98 <release>
}
    80002b78:	60e2                	ld	ra,24(sp)
    80002b7a:	6442                	ld	s0,16(sp)
    80002b7c:	64a2                	ld	s1,8(sp)
    80002b7e:	6902                	ld	s2,0(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret
     printf("init runnable : %d", p->proc_ind);
    80002b84:	4cec                	lw	a1,92(s1)
    80002b86:	00006517          	auipc	a0,0x6
    80002b8a:	7f250513          	addi	a0,a0,2034 # 80009378 <digits+0x338>
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	9fa080e7          	jalr	-1542(ra) # 80000588 <printf>
    80002b96:	8792                	mv	a5,tp
  int id = r_tp();
    80002b98:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002b9c:	0000f717          	auipc	a4,0xf
    80002ba0:	72470713          	addi	a4,a4,1828 # 800122c0 <cpus>
    80002ba4:	00369793          	slli	a5,a3,0x3
    80002ba8:	00d78633          	add	a2,a5,a3
    80002bac:	0612                	slli	a2,a2,0x4
    80002bae:	963a                	add	a2,a2,a4
    80002bb0:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    80002bb4:	4cf0                	lw	a2,92(s1)
    80002bb6:	97b6                	add	a5,a5,a3
    80002bb8:	0792                	slli	a5,a5,0x4
    80002bba:	97ba                	add	a5,a5,a4
    80002bbc:	08c7a023          	sw	a2,128(a5)
    80002bc0:	8792                	mv	a5,tp
  int id = r_tp();
    80002bc2:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002bc6:	00369793          	slli	a5,a3,0x3
    80002bca:	00d78633          	add	a2,a5,a3
    80002bce:	0612                	slli	a2,a2,0x4
    80002bd0:	963a                	add	a2,a2,a4
    80002bd2:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002bd6:	4cf0                	lw	a2,92(s1)
    80002bd8:	97b6                	add	a5,a5,a3
    80002bda:	0792                	slli	a5,a5,0x4
    80002bdc:	973e                	add	a4,a4,a5
    80002bde:	08c72223          	sw	a2,132(a4)
    80002be2:	b751                	j	80002b66 <yield+0xb2>

0000000080002be4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002be4:	7179                	addi	sp,sp,-48
    80002be6:	f406                	sd	ra,40(sp)
    80002be8:	f022                	sd	s0,32(sp)
    80002bea:	ec26                	sd	s1,24(sp)
    80002bec:	e84a                	sd	s2,16(sp)
    80002bee:	e44e                	sd	s3,8(sp)
    80002bf0:	1800                	addi	s0,sp,48
    80002bf2:	89aa                	mv	s3,a0
    80002bf4:	892e                	mv	s2,a1
  // TODO: remove from RUNNABLE and add to SLEEPING
  struct proc *p = myproc();
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	fce080e7          	jalr	-50(ra) # 80001bc4 <myproc>
    80002bfe:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	fe4080e7          	jalr	-28(ra) # 80000be4 <acquire>
  release(lk);
    80002c08:	854a                	mv	a0,s2
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	08e080e7          	jalr	142(ra) # 80000c98 <release>

  //Ass2
  printf("runable");
    80002c12:	00006517          	auipc	a0,0x6
    80002c16:	6f650513          	addi	a0,a0,1782 # 80009308 <digits+0x2c8>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	96e080e7          	jalr	-1682(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80002c22:	4ce8                	lw	a0,92(s1)
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	ca0080e7          	jalr	-864(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1){
    80002c2c:	4785                	li	a5,1
    80002c2e:	08f50f63          	beq	a0,a5,80002ccc <sleep+0xe8>
    mycpu()->runnable_list_head = -1;
    mycpu()->runnable_list_tail = -1;
  }
  if (res == 2){
    80002c32:	4789                	li	a5,2
    80002c34:	0cf50c63          	beq	a0,a5,80002d0c <sleep+0x128>
    mycpu()->runnable_list_head = p->next_proc;
    proc[p->next_proc].prev_proc = -1;
  }
  if (res == 3){
    80002c38:	478d                	li	a5,3
    80002c3a:	10f50a63          	beq	a0,a5,80002d4e <sleep+0x16a>
    mycpu()->runnable_list_tail = p->prev_proc;
    proc[p->prev_proc].next_proc = -1;
  }

  p->next_proc = -1;
    80002c3e:	57fd                	li	a5,-1
    80002c40:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80002c42:	d0fc                	sw	a5,100(s1)

  // Go to sleep.
  p->chan = chan;
    80002c44:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002c48:	4789                	li	a5,2
    80002c4a:	cc9c                	sw	a5,24(s1)
  p->start_sleeping_time = ticks;
    80002c4c:	00007797          	auipc	a5,0x7
    80002c50:	4087a783          	lw	a5,1032(a5) # 8000a054 <ticks>
    80002c54:	c8fc                	sw	a5,84(s1)

  if (sleeping_list_tail != -1){
    80002c56:	00007717          	auipc	a4,0x7
    80002c5a:	df272703          	lw	a4,-526(a4) # 80009a48 <sleeping_list_tail>
    80002c5e:	57fd                	li	a5,-1
    80002c60:	12f70e63          	beq	a4,a5,80002d9c <sleep+0x1b8>
    printf("sleeping");
    80002c64:	00006517          	auipc	a0,0x6
    80002c68:	72c50513          	addi	a0,a0,1836 # 80009390 <digits+0x350>
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	91c080e7          	jalr	-1764(ra) # 80000588 <printf>
    add_proc_to_list(sleeping_list_tail, p);
    80002c74:	85a6                	mv	a1,s1
    80002c76:	00007517          	auipc	a0,0x7
    80002c7a:	dd252503          	lw	a0,-558(a0) # 80009a48 <sleeping_list_tail>
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	bc8080e7          	jalr	-1080(ra) # 80001846 <add_proc_to_list>
    if (sleeping_list_head == -1)
    80002c86:	00007717          	auipc	a4,0x7
    80002c8a:	dc672703          	lw	a4,-570(a4) # 80009a4c <sleeping_list_head>
    80002c8e:	57fd                	li	a5,-1
    80002c90:	10f70063          	beq	a4,a5,80002d90 <sleep+0x1ac>
      {
        sleeping_list_head = p->proc_ind;
      }
    sleeping_list_tail = p->proc_ind;
    80002c94:	4cfc                	lw	a5,92(s1)
    80002c96:	00007717          	auipc	a4,0x7
    80002c9a:	daf72923          	sw	a5,-590(a4) # 80009a48 <sleeping_list_tail>
    printf("head in sleeping\n");
    sleeping_list_tail =  p->proc_ind;
    sleeping_list_head = p->proc_ind;
  }

  sched();
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	d08080e7          	jalr	-760(ra) # 800029a6 <sched>

  // Tidy up.
  p->chan = 0;
    80002ca6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002caa:	8526                	mv	a0,s1
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	fec080e7          	jalr	-20(ra) # 80000c98 <release>
  acquire(lk);
    80002cb4:	854a                	mv	a0,s2
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	f2e080e7          	jalr	-210(ra) # 80000be4 <acquire>
}
    80002cbe:	70a2                	ld	ra,40(sp)
    80002cc0:	7402                	ld	s0,32(sp)
    80002cc2:	64e2                	ld	s1,24(sp)
    80002cc4:	6942                	ld	s2,16(sp)
    80002cc6:	69a2                	ld	s3,8(sp)
    80002cc8:	6145                	addi	sp,sp,48
    80002cca:	8082                	ret
    80002ccc:	8792                	mv	a5,tp
  int id = r_tp();
    80002cce:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002cd2:	0000f717          	auipc	a4,0xf
    80002cd6:	5ee70713          	addi	a4,a4,1518 # 800122c0 <cpus>
    80002cda:	00369793          	slli	a5,a3,0x3
    80002cde:	00d78633          	add	a2,a5,a3
    80002ce2:	0612                	slli	a2,a2,0x4
    80002ce4:	963a                	add	a2,a2,a4
    80002ce6:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = -1;
    80002cea:	55fd                	li	a1,-1
    80002cec:	08b62023          	sw	a1,128(a2)
    80002cf0:	8792                	mv	a5,tp
  int id = r_tp();
    80002cf2:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002cf6:	00369793          	slli	a5,a3,0x3
    80002cfa:	00d78633          	add	a2,a5,a3
    80002cfe:	0612                	slli	a2,a2,0x4
    80002d00:	963a                	add	a2,a2,a4
    80002d02:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = -1;
    80002d06:	08b62223          	sw	a1,132(a2)
  if (res == 3){
    80002d0a:	bf15                	j	80002c3e <sleep+0x5a>
    80002d0c:	8792                	mv	a5,tp
  int id = r_tp();
    80002d0e:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002d12:	0000f617          	auipc	a2,0xf
    80002d16:	5ae60613          	addi	a2,a2,1454 # 800122c0 <cpus>
    80002d1a:	00371793          	slli	a5,a4,0x3
    80002d1e:	00e786b3          	add	a3,a5,a4
    80002d22:	0692                	slli	a3,a3,0x4
    80002d24:	96b2                	add	a3,a3,a2
    80002d26:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_head = p->next_proc;
    80002d2a:	50b4                	lw	a3,96(s1)
    80002d2c:	97ba                	add	a5,a5,a4
    80002d2e:	0792                	slli	a5,a5,0x4
    80002d30:	97b2                	add	a5,a5,a2
    80002d32:	08d7a023          	sw	a3,128(a5)
    proc[p->next_proc].prev_proc = -1;
    80002d36:	19800793          	li	a5,408
    80002d3a:	02f686b3          	mul	a3,a3,a5
    80002d3e:	00010797          	auipc	a5,0x10
    80002d42:	a3278793          	addi	a5,a5,-1486 # 80012770 <proc>
    80002d46:	96be                	add	a3,a3,a5
    80002d48:	57fd                	li	a5,-1
    80002d4a:	d2fc                	sw	a5,100(a3)
  if (res == 3){
    80002d4c:	bdcd                	j	80002c3e <sleep+0x5a>
    80002d4e:	8792                	mv	a5,tp
  int id = r_tp();
    80002d50:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002d54:	0000f617          	auipc	a2,0xf
    80002d58:	56c60613          	addi	a2,a2,1388 # 800122c0 <cpus>
    80002d5c:	00371793          	slli	a5,a4,0x3
    80002d60:	00e786b3          	add	a3,a5,a4
    80002d64:	0692                	slli	a3,a3,0x4
    80002d66:	96b2                	add	a3,a3,a2
    80002d68:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->prev_proc;
    80002d6c:	50f4                	lw	a3,100(s1)
    80002d6e:	97ba                	add	a5,a5,a4
    80002d70:	0792                	slli	a5,a5,0x4
    80002d72:	97b2                	add	a5,a5,a2
    80002d74:	08d7a223          	sw	a3,132(a5)
    proc[p->prev_proc].next_proc = -1;
    80002d78:	19800793          	li	a5,408
    80002d7c:	02f686b3          	mul	a3,a3,a5
    80002d80:	00010797          	auipc	a5,0x10
    80002d84:	9f078793          	addi	a5,a5,-1552 # 80012770 <proc>
    80002d88:	96be                	add	a3,a3,a5
    80002d8a:	57fd                	li	a5,-1
    80002d8c:	d2bc                	sw	a5,96(a3)
    80002d8e:	bd45                	j	80002c3e <sleep+0x5a>
        sleeping_list_head = p->proc_ind;
    80002d90:	4cfc                	lw	a5,92(s1)
    80002d92:	00007717          	auipc	a4,0x7
    80002d96:	caf72d23          	sw	a5,-838(a4) # 80009a4c <sleeping_list_head>
    80002d9a:	bded                	j	80002c94 <sleep+0xb0>
    printf("head in sleeping\n");
    80002d9c:	00006517          	auipc	a0,0x6
    80002da0:	60450513          	addi	a0,a0,1540 # 800093a0 <digits+0x360>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	7e4080e7          	jalr	2020(ra) # 80000588 <printf>
    sleeping_list_tail =  p->proc_ind;
    80002dac:	4cfc                	lw	a5,92(s1)
    80002dae:	00007717          	auipc	a4,0x7
    80002db2:	c8f72d23          	sw	a5,-870(a4) # 80009a48 <sleeping_list_tail>
    sleeping_list_head = p->proc_ind;
    80002db6:	00007717          	auipc	a4,0x7
    80002dba:	c8f72b23          	sw	a5,-874(a4) # 80009a4c <sleeping_list_head>
    80002dbe:	b5c5                	j	80002c9e <sleep+0xba>

0000000080002dc0 <wait>:
{
    80002dc0:	711d                	addi	sp,sp,-96
    80002dc2:	ec86                	sd	ra,88(sp)
    80002dc4:	e8a2                	sd	s0,80(sp)
    80002dc6:	e4a6                	sd	s1,72(sp)
    80002dc8:	e0ca                	sd	s2,64(sp)
    80002dca:	fc4e                	sd	s3,56(sp)
    80002dcc:	f852                	sd	s4,48(sp)
    80002dce:	f456                	sd	s5,40(sp)
    80002dd0:	f05a                	sd	s6,32(sp)
    80002dd2:	ec5e                	sd	s7,24(sp)
    80002dd4:	e862                	sd	s8,16(sp)
    80002dd6:	e466                	sd	s9,8(sp)
    80002dd8:	1080                	addi	s0,sp,96
    80002dda:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	de8080e7          	jalr	-536(ra) # 80001bc4 <myproc>
    80002de4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002de6:	00010517          	auipc	a0,0x10
    80002dea:	97250513          	addi	a0,a0,-1678 # 80012758 <wait_lock>
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	df6080e7          	jalr	-522(ra) # 80000be4 <acquire>
    havekids = 0;
    80002df6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002df8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002dfa:	00016997          	auipc	s3,0x16
    80002dfe:	f7698993          	addi	s3,s3,-138 # 80018d70 <tickslock>
        havekids = 1;
    80002e02:	4a85                	li	s5,1
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002e04:	00007c97          	auipc	s9,0x7
    80002e08:	250c8c93          	addi	s9,s9,592 # 8000a054 <ticks>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002e0c:	00010c17          	auipc	s8,0x10
    80002e10:	94cc0c13          	addi	s8,s8,-1716 # 80012758 <wait_lock>
    havekids = 0;
    80002e14:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002e16:	00010497          	auipc	s1,0x10
    80002e1a:	95a48493          	addi	s1,s1,-1702 # 80012770 <proc>
    80002e1e:	a0bd                	j	80002e8c <wait+0xcc>
          pid = np->pid;
    80002e20:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002e24:	000b0e63          	beqz	s6,80002e40 <wait+0x80>
    80002e28:	4691                	li	a3,4
    80002e2a:	02c48613          	addi	a2,s1,44
    80002e2e:	85da                	mv	a1,s6
    80002e30:	08093503          	ld	a0,128(s2)
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	846080e7          	jalr	-1978(ra) # 8000167a <copyout>
    80002e3c:	02054563          	bltz	a0,80002e66 <wait+0xa6>
          freeproc(np);
    80002e40:	8526                	mv	a0,s1
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	f38080e7          	jalr	-200(ra) # 80001d7a <freeproc>
          release(&np->lock);
    80002e4a:	8526                	mv	a0,s1
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	e4c080e7          	jalr	-436(ra) # 80000c98 <release>
          release(&wait_lock);
    80002e54:	00010517          	auipc	a0,0x10
    80002e58:	90450513          	addi	a0,a0,-1788 # 80012758 <wait_lock>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	e3c080e7          	jalr	-452(ra) # 80000c98 <release>
          return pid;
    80002e64:	a09d                	j	80002eca <wait+0x10a>
            release(&np->lock);
    80002e66:	8526                	mv	a0,s1
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	e30080e7          	jalr	-464(ra) # 80000c98 <release>
            release(&wait_lock);
    80002e70:	00010517          	auipc	a0,0x10
    80002e74:	8e850513          	addi	a0,a0,-1816 # 80012758 <wait_lock>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	e20080e7          	jalr	-480(ra) # 80000c98 <release>
            return -1;
    80002e80:	59fd                	li	s3,-1
    80002e82:	a0a1                	j	80002eca <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002e84:	19848493          	addi	s1,s1,408
    80002e88:	03348463          	beq	s1,s3,80002eb0 <wait+0xf0>
      if(np->parent == p){
    80002e8c:	74bc                	ld	a5,104(s1)
    80002e8e:	ff279be3          	bne	a5,s2,80002e84 <wait+0xc4>
        acquire(&np->lock);
    80002e92:	8526                	mv	a0,s1
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	d50080e7          	jalr	-688(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002e9c:	4c9c                	lw	a5,24(s1)
    80002e9e:	f94781e3          	beq	a5,s4,80002e20 <wait+0x60>
        release(&np->lock);
    80002ea2:	8526                	mv	a0,s1
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	df4080e7          	jalr	-524(ra) # 80000c98 <release>
        havekids = 1;
    80002eac:	8756                	mv	a4,s5
    80002eae:	bfd9                	j	80002e84 <wait+0xc4>
    if(!havekids || p->killed){
    80002eb0:	c701                	beqz	a4,80002eb8 <wait+0xf8>
    80002eb2:	02892783          	lw	a5,40(s2)
    80002eb6:	cb85                	beqz	a5,80002ee6 <wait+0x126>
      release(&wait_lock);
    80002eb8:	00010517          	auipc	a0,0x10
    80002ebc:	8a050513          	addi	a0,a0,-1888 # 80012758 <wait_lock>
    80002ec0:	ffffe097          	auipc	ra,0xffffe
    80002ec4:	dd8080e7          	jalr	-552(ra) # 80000c98 <release>
      return -1;
    80002ec8:	59fd                	li	s3,-1
}
    80002eca:	854e                	mv	a0,s3
    80002ecc:	60e6                	ld	ra,88(sp)
    80002ece:	6446                	ld	s0,80(sp)
    80002ed0:	64a6                	ld	s1,72(sp)
    80002ed2:	6906                	ld	s2,64(sp)
    80002ed4:	79e2                	ld	s3,56(sp)
    80002ed6:	7a42                	ld	s4,48(sp)
    80002ed8:	7aa2                	ld	s5,40(sp)
    80002eda:	7b02                	ld	s6,32(sp)
    80002edc:	6be2                	ld	s7,24(sp)
    80002ede:	6c42                	ld	s8,16(sp)
    80002ee0:	6ca2                	ld	s9,8(sp)
    80002ee2:	6125                	addi	sp,sp,96
    80002ee4:	8082                	ret
    if (p->state == RUNNING)
    80002ee6:	01892783          	lw	a5,24(s2)
    80002eea:	4711                	li	a4,4
    80002eec:	02e78063          	beq	a5,a4,80002f0c <wait+0x14c>
     if (p->state == RUNNABLE)
    80002ef0:	470d                	li	a4,3
    80002ef2:	02e79e63          	bne	a5,a4,80002f2e <wait+0x16e>
      p->runnable_time += ticks - p->last_runnable_time;
    80002ef6:	04892783          	lw	a5,72(s2)
    80002efa:	000ca703          	lw	a4,0(s9)
    80002efe:	9fb9                	addw	a5,a5,a4
    80002f00:	03c92703          	lw	a4,60(s2)
    80002f04:	9f99                	subw	a5,a5,a4
    80002f06:	04f92423          	sw	a5,72(s2)
    if (p->state == SLEEPING)
    80002f0a:	a819                	j	80002f20 <wait+0x160>
      p->running_time += ticks - p->start_running_time;
    80002f0c:	04492783          	lw	a5,68(s2)
    80002f10:	000ca703          	lw	a4,0(s9)
    80002f14:	9fb9                	addw	a5,a5,a4
    80002f16:	05092703          	lw	a4,80(s2)
    80002f1a:	9f99                	subw	a5,a5,a4
    80002f1c:	04f92223          	sw	a5,68(s2)
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002f20:	85e2                	mv	a1,s8
    80002f22:	854a                	mv	a0,s2
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	cc0080e7          	jalr	-832(ra) # 80002be4 <sleep>
    havekids = 0;
    80002f2c:	b5e5                	j	80002e14 <wait+0x54>
    if (p->state == SLEEPING)
    80002f2e:	4709                	li	a4,2
    80002f30:	fee798e3          	bne	a5,a4,80002f20 <wait+0x160>
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002f34:	04c92783          	lw	a5,76(s2)
    80002f38:	000ca703          	lw	a4,0(s9)
    80002f3c:	9fb9                	addw	a5,a5,a4
    80002f3e:	05492703          	lw	a4,84(s2)
    80002f42:	9f99                	subw	a5,a5,a4
    80002f44:	04f92623          	sw	a5,76(s2)
    80002f48:	bfe1                	j	80002f20 <wait+0x160>

0000000080002f4a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002f4a:	7179                	addi	sp,sp,-48
    80002f4c:	f406                	sd	ra,40(sp)
    80002f4e:	f022                	sd	s0,32(sp)
    80002f50:	ec26                	sd	s1,24(sp)
    80002f52:	e84a                	sd	s2,16(sp)
    80002f54:	e44e                	sd	s3,8(sp)
    80002f56:	1800                	addi	s0,sp,48
  // TODO: go threw all SLEEPING and pick one to wake up- remove from SLEEPING and add to RUNNABLE.
  // struct proc *p;
  
  // printf("wakeup\n");
  struct proc *p = &proc[sleeping_list_head];
    80002f58:	00007917          	auipc	s2,0x7
    80002f5c:	af492903          	lw	s2,-1292(s2) # 80009a4c <sleeping_list_head>

  if (sleeping_list_head != -1)
    80002f60:	57fd                	li	a5,-1
    80002f62:	00f91963          	bne	s2,a5,80002f74 <wakeup+0x2a>
  //     }
  //     release(&p->lock);
  //   }
  // }
  }
}
    80002f66:	70a2                	ld	ra,40(sp)
    80002f68:	7402                	ld	s0,32(sp)
    80002f6a:	64e2                	ld	s1,24(sp)
    80002f6c:	6942                	ld	s2,16(sp)
    80002f6e:	69a2                	ld	s3,8(sp)
    80002f70:	6145                	addi	sp,sp,48
    80002f72:	8082                	ret
    printf("sleeping");
    80002f74:	00006517          	auipc	a0,0x6
    80002f78:	41c50513          	addi	a0,a0,1052 # 80009390 <digits+0x350>
    80002f7c:	ffffd097          	auipc	ra,0xffffd
    80002f80:	60c080e7          	jalr	1548(ra) # 80000588 <printf>
    int res = remove_proc_from_list(p->proc_ind); 
    80002f84:	19800793          	li	a5,408
    80002f88:	02f90733          	mul	a4,s2,a5
    80002f8c:	0000f797          	auipc	a5,0xf
    80002f90:	7e478793          	addi	a5,a5,2020 # 80012770 <proc>
    80002f94:	97ba                	add	a5,a5,a4
    80002f96:	4fe8                	lw	a0,92(a5)
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	92c080e7          	jalr	-1748(ra) # 800018c4 <remove_proc_from_list>
      if (res == 1){
    80002fa0:	4785                	li	a5,1
    80002fa2:	02f50963          	beq	a0,a5,80002fd4 <wakeup+0x8a>
      if (res == 2)
    80002fa6:	4789                	li	a5,2
    80002fa8:	0ef51363          	bne	a0,a5,8000308e <wakeup+0x144>
        sleeping_list_head = p->next_proc;
    80002fac:	0000f797          	auipc	a5,0xf
    80002fb0:	7c478793          	addi	a5,a5,1988 # 80012770 <proc>
    80002fb4:	19800613          	li	a2,408
    80002fb8:	02c906b3          	mul	a3,s2,a2
    80002fbc:	96be                	add	a3,a3,a5
    80002fbe:	52b8                	lw	a4,96(a3)
    80002fc0:	00007697          	auipc	a3,0x7
    80002fc4:	a8e6a623          	sw	a4,-1396(a3) # 80009a4c <sleeping_list_head>
        proc[p->next_proc].prev_proc = -1;
    80002fc8:	02c70733          	mul	a4,a4,a2
    80002fcc:	97ba                	add	a5,a5,a4
    80002fce:	577d                	li	a4,-1
    80002fd0:	d3f8                	sw	a4,100(a5)
      if (res == 3){
    80002fd2:	a811                	j	80002fe6 <wakeup+0x9c>
        sleeping_list_head = -1;
    80002fd4:	57fd                	li	a5,-1
    80002fd6:	00007717          	auipc	a4,0x7
    80002fda:	a6f72b23          	sw	a5,-1418(a4) # 80009a4c <sleeping_list_head>
        sleeping_list_tail = -1;
    80002fde:	00007717          	auipc	a4,0x7
    80002fe2:	a6f72523          	sw	a5,-1430(a4) # 80009a48 <sleeping_list_tail>
  struct proc *p = &proc[sleeping_list_head];
    80002fe6:	19800493          	li	s1,408
    80002fea:	029904b3          	mul	s1,s2,s1
    80002fee:	0000f797          	auipc	a5,0xf
    80002ff2:	78278793          	addi	a5,a5,1922 # 80012770 <proc>
    80002ff6:	94be                	add	s1,s1,a5
      acquire(&p->lock);
    80002ff8:	8526                	mv	a0,s1
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	bea080e7          	jalr	-1046(ra) # 80000be4 <acquire>
      p->state = RUNNABLE;
    80003002:	478d                	li	a5,3
    80003004:	cc9c                	sw	a5,24(s1)
      p->prev_proc = -1;
    80003006:	57fd                	li	a5,-1
    80003008:	d0fc                	sw	a5,100(s1)
      p->next_proc = -1;
    8000300a:	d0bc                	sw	a5,96(s1)
      release(&p->lock);
    8000300c:	8526                	mv	a0,s1
    8000300e:	ffffe097          	auipc	ra,0xffffe
    80003012:	c8a080e7          	jalr	-886(ra) # 80000c98 <release>
      printf("runnable");
    80003016:	00006517          	auipc	a0,0x6
    8000301a:	29a50513          	addi	a0,a0,666 # 800092b0 <digits+0x270>
    8000301e:	ffffd097          	auipc	ra,0xffffd
    80003022:	56a080e7          	jalr	1386(ra) # 80000588 <printf>
      if (cpus[p->cpu_num].runnable_list_head == -1)
    80003026:	4cb8                	lw	a4,88(s1)
    80003028:	00371793          	slli	a5,a4,0x3
    8000302c:	97ba                	add	a5,a5,a4
    8000302e:	0792                	slli	a5,a5,0x4
    80003030:	0000f697          	auipc	a3,0xf
    80003034:	29068693          	addi	a3,a3,656 # 800122c0 <cpus>
    80003038:	97b6                	add	a5,a5,a3
    8000303a:	0807a683          	lw	a3,128(a5)
    8000303e:	57fd                	li	a5,-1
    80003040:	06f68e63          	beq	a3,a5,800030bc <wakeup+0x172>
        add_proc_to_list(cpus[p->cpu_num].runnable_list_tail, p);
    80003044:	0000f997          	auipc	s3,0xf
    80003048:	27c98993          	addi	s3,s3,636 # 800122c0 <cpus>
    8000304c:	00371793          	slli	a5,a4,0x3
    80003050:	97ba                	add	a5,a5,a4
    80003052:	0792                	slli	a5,a5,0x4
    80003054:	97ce                	add	a5,a5,s3
    80003056:	85a6                	mv	a1,s1
    80003058:	0847a503          	lw	a0,132(a5)
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	7ea080e7          	jalr	2026(ra) # 80001846 <add_proc_to_list>
        cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    80003064:	19800793          	li	a5,408
    80003068:	02f90933          	mul	s2,s2,a5
    8000306c:	0000f797          	auipc	a5,0xf
    80003070:	70478793          	addi	a5,a5,1796 # 80012770 <proc>
    80003074:	993e                	add	s2,s2,a5
    80003076:	05892703          	lw	a4,88(s2)
    8000307a:	00371793          	slli	a5,a4,0x3
    8000307e:	97ba                	add	a5,a5,a4
    80003080:	0792                	slli	a5,a5,0x4
    80003082:	97ce                	add	a5,a5,s3
    80003084:	05c92703          	lw	a4,92(s2)
    80003088:	08e7a223          	sw	a4,132(a5)
}
    8000308c:	bde9                	j	80002f66 <wakeup+0x1c>
      if (res == 3){
    8000308e:	478d                	li	a5,3
    80003090:	f4f51be3          	bne	a0,a5,80002fe6 <wakeup+0x9c>
        sleeping_list_tail = p->prev_proc;
    80003094:	0000f797          	auipc	a5,0xf
    80003098:	6dc78793          	addi	a5,a5,1756 # 80012770 <proc>
    8000309c:	19800613          	li	a2,408
    800030a0:	02c906b3          	mul	a3,s2,a2
    800030a4:	96be                	add	a3,a3,a5
    800030a6:	52f8                	lw	a4,100(a3)
    800030a8:	00007697          	auipc	a3,0x7
    800030ac:	9ae6a023          	sw	a4,-1632(a3) # 80009a48 <sleeping_list_tail>
        proc[p->prev_proc].next_proc = -1;
    800030b0:	02c70733          	mul	a4,a4,a2
    800030b4:	97ba                	add	a5,a5,a4
    800030b6:	577d                	li	a4,-1
    800030b8:	d3b8                	sw	a4,96(a5)
    800030ba:	b735                	j	80002fe6 <wakeup+0x9c>
        printf("init runnable %d\n", p->proc_ind);
    800030bc:	4cec                	lw	a1,92(s1)
    800030be:	00006517          	auipc	a0,0x6
    800030c2:	20250513          	addi	a0,a0,514 # 800092c0 <digits+0x280>
    800030c6:	ffffd097          	auipc	ra,0xffffd
    800030ca:	4c2080e7          	jalr	1218(ra) # 80000588 <printf>
        cpus[p->cpu_num].runnable_list_head = p->proc_ind;
    800030ce:	4cb0                	lw	a2,88(s1)
    800030d0:	4cec                	lw	a1,92(s1)
    800030d2:	0000f697          	auipc	a3,0xf
    800030d6:	1ee68693          	addi	a3,a3,494 # 800122c0 <cpus>
    800030da:	00361793          	slli	a5,a2,0x3
    800030de:	00c78733          	add	a4,a5,a2
    800030e2:	0712                	slli	a4,a4,0x4
    800030e4:	9736                	add	a4,a4,a3
    800030e6:	08b72023          	sw	a1,128(a4)
        cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    800030ea:	08b72223          	sw	a1,132(a4)
    800030ee:	bda5                	j	80002f66 <wakeup+0x1c>

00000000800030f0 <reparent>:
{
    800030f0:	7179                	addi	sp,sp,-48
    800030f2:	f406                	sd	ra,40(sp)
    800030f4:	f022                	sd	s0,32(sp)
    800030f6:	ec26                	sd	s1,24(sp)
    800030f8:	e84a                	sd	s2,16(sp)
    800030fa:	e44e                	sd	s3,8(sp)
    800030fc:	e052                	sd	s4,0(sp)
    800030fe:	1800                	addi	s0,sp,48
    80003100:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003102:	0000f497          	auipc	s1,0xf
    80003106:	66e48493          	addi	s1,s1,1646 # 80012770 <proc>
      pp->parent = initproc;
    8000310a:	00007a17          	auipc	s4,0x7
    8000310e:	f1ea0a13          	addi	s4,s4,-226 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003112:	00016997          	auipc	s3,0x16
    80003116:	c5e98993          	addi	s3,s3,-930 # 80018d70 <tickslock>
    8000311a:	a029                	j	80003124 <reparent+0x34>
    8000311c:	19848493          	addi	s1,s1,408
    80003120:	01348d63          	beq	s1,s3,8000313a <reparent+0x4a>
    if(pp->parent == p){
    80003124:	74bc                	ld	a5,104(s1)
    80003126:	ff279be3          	bne	a5,s2,8000311c <reparent+0x2c>
      pp->parent = initproc;
    8000312a:	000a3503          	ld	a0,0(s4)
    8000312e:	f4a8                	sd	a0,104(s1)
      wakeup(initproc);
    80003130:	00000097          	auipc	ra,0x0
    80003134:	e1a080e7          	jalr	-486(ra) # 80002f4a <wakeup>
    80003138:	b7d5                	j	8000311c <reparent+0x2c>
}
    8000313a:	70a2                	ld	ra,40(sp)
    8000313c:	7402                	ld	s0,32(sp)
    8000313e:	64e2                	ld	s1,24(sp)
    80003140:	6942                	ld	s2,16(sp)
    80003142:	69a2                	ld	s3,8(sp)
    80003144:	6a02                	ld	s4,0(sp)
    80003146:	6145                	addi	sp,sp,48
    80003148:	8082                	ret

000000008000314a <exit>:
{
    8000314a:	7179                	addi	sp,sp,-48
    8000314c:	f406                	sd	ra,40(sp)
    8000314e:	f022                	sd	s0,32(sp)
    80003150:	ec26                	sd	s1,24(sp)
    80003152:	e84a                	sd	s2,16(sp)
    80003154:	e44e                	sd	s3,8(sp)
    80003156:	e052                	sd	s4,0(sp)
    80003158:	1800                	addi	s0,sp,48
    8000315a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	a68080e7          	jalr	-1432(ra) # 80001bc4 <myproc>
    80003164:	892a                	mv	s2,a0
  if(p == initproc)
    80003166:	00007797          	auipc	a5,0x7
    8000316a:	ec27b783          	ld	a5,-318(a5) # 8000a028 <initproc>
    8000316e:	10050493          	addi	s1,a0,256
    80003172:	18050993          	addi	s3,a0,384
    80003176:	02a79363          	bne	a5,a0,8000319c <exit+0x52>
    panic("init exiting");
    8000317a:	00006517          	auipc	a0,0x6
    8000317e:	23e50513          	addi	a0,a0,574 # 800093b8 <digits+0x378>
    80003182:	ffffd097          	auipc	ra,0xffffd
    80003186:	3bc080e7          	jalr	956(ra) # 8000053e <panic>
      fileclose(f);
    8000318a:	00002097          	auipc	ra,0x2
    8000318e:	7fc080e7          	jalr	2044(ra) # 80005986 <fileclose>
      p->ofile[fd] = 0;
    80003192:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80003196:	04a1                	addi	s1,s1,8
    80003198:	00998563          	beq	s3,s1,800031a2 <exit+0x58>
    if(p->ofile[fd]){
    8000319c:	6088                	ld	a0,0(s1)
    8000319e:	f575                	bnez	a0,8000318a <exit+0x40>
    800031a0:	bfdd                	j	80003196 <exit+0x4c>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800031a2:	18890493          	addi	s1,s2,392
    800031a6:	00006597          	auipc	a1,0x6
    800031aa:	22258593          	addi	a1,a1,546 # 800093c8 <digits+0x388>
    800031ae:	8526                	mv	a0,s1
    800031b0:	fffff097          	auipc	ra,0xfffff
    800031b4:	ed4080e7          	jalr	-300(ra) # 80002084 <str_compare>
    800031b8:	e97d                	bnez	a0,800032ae <exit+0x164>
  begin_op();
    800031ba:	00002097          	auipc	ra,0x2
    800031be:	300080e7          	jalr	768(ra) # 800054ba <begin_op>
  iput(p->cwd);
    800031c2:	18093503          	ld	a0,384(s2)
    800031c6:	00002097          	auipc	ra,0x2
    800031ca:	adc080e7          	jalr	-1316(ra) # 80004ca2 <iput>
  end_op();
    800031ce:	00002097          	auipc	ra,0x2
    800031d2:	36c080e7          	jalr	876(ra) # 8000553a <end_op>
  p->cwd = 0;
    800031d6:	18093023          	sd	zero,384(s2)
  acquire(&wait_lock);
    800031da:	0000f517          	auipc	a0,0xf
    800031de:	57e50513          	addi	a0,a0,1406 # 80012758 <wait_lock>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	a02080e7          	jalr	-1534(ra) # 80000be4 <acquire>
  reparent(p);
    800031ea:	854a                	mv	a0,s2
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	f04080e7          	jalr	-252(ra) # 800030f0 <reparent>
  wakeup(p->parent);
    800031f4:	06893503          	ld	a0,104(s2)
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	d52080e7          	jalr	-686(ra) # 80002f4a <wakeup>
  acquire(&p->lock);
    80003200:	854a                	mv	a0,s2
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000320a:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000320e:	4795                	li	a5,5
    80003210:	00f92c23          	sw	a5,24(s2)
  p->running_time += ticks - p->start_running_time;
    80003214:	04492783          	lw	a5,68(s2)
    80003218:	00007717          	auipc	a4,0x7
    8000321c:	e3c72703          	lw	a4,-452(a4) # 8000a054 <ticks>
    80003220:	9fb9                	addw	a5,a5,a4
    80003222:	05092703          	lw	a4,80(s2)
    80003226:	9f99                	subw	a5,a5,a4
    80003228:	04f92223          	sw	a5,68(s2)
  printf("runable");
    8000322c:	00006517          	auipc	a0,0x6
    80003230:	0dc50513          	addi	a0,a0,220 # 80009308 <digits+0x2c8>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	354080e7          	jalr	852(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    8000323c:	05c92503          	lw	a0,92(s2)
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	684080e7          	jalr	1668(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1){
    80003248:	4785                	li	a5,1
    8000324a:	10f50863          	beq	a0,a5,8000335a <exit+0x210>
  if (res == 2){
    8000324e:	4789                	li	a5,2
    80003250:	12f50f63          	beq	a0,a5,8000338e <exit+0x244>
  if (res == 3){
    80003254:	478d                	li	a5,3
    80003256:	16f50963          	beq	a0,a5,800033c8 <exit+0x27e>
  p->next_proc = -1;
    8000325a:	57fd                	li	a5,-1
    8000325c:	06f92023          	sw	a5,96(s2)
  p->prev_proc = -1;
    80003260:	06f92223          	sw	a5,100(s2)
  if (zombie_list_tail != -1){
    80003264:	00006717          	auipc	a4,0x6
    80003268:	7d472703          	lw	a4,2004(a4) # 80009a38 <zombie_list_tail>
    8000326c:	57fd                	li	a5,-1
    8000326e:	18f71a63          	bne	a4,a5,80003402 <exit+0x2b8>
    zombie_list_tail = zombie_list_head = p->proc_ind;
    80003272:	05c92783          	lw	a5,92(s2)
    80003276:	00006717          	auipc	a4,0x6
    8000327a:	7cf72323          	sw	a5,1990(a4) # 80009a3c <zombie_list_head>
    8000327e:	00006717          	auipc	a4,0x6
    80003282:	7af72d23          	sw	a5,1978(a4) # 80009a38 <zombie_list_tail>
  release(&wait_lock);
    80003286:	0000f517          	auipc	a0,0xf
    8000328a:	4d250513          	addi	a0,a0,1234 # 80012758 <wait_lock>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	a0a080e7          	jalr	-1526(ra) # 80000c98 <release>
  sched();
    80003296:	fffff097          	auipc	ra,0xfffff
    8000329a:	710080e7          	jalr	1808(ra) # 800029a6 <sched>
  panic("zombie exit");
    8000329e:	00006517          	auipc	a0,0x6
    800032a2:	13a50513          	addi	a0,a0,314 # 800093d8 <digits+0x398>
    800032a6:	ffffd097          	auipc	ra,0xffffd
    800032aa:	298080e7          	jalr	664(ra) # 8000053e <panic>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800032ae:	00006597          	auipc	a1,0x6
    800032b2:	12258593          	addi	a1,a1,290 # 800093d0 <digits+0x390>
    800032b6:	8526                	mv	a0,s1
    800032b8:	fffff097          	auipc	ra,0xfffff
    800032bc:	dcc080e7          	jalr	-564(ra) # 80002084 <str_compare>
    800032c0:	ee050de3          	beqz	a0,800031ba <exit+0x70>
    sleeping_processes_mean = ((sleeping_processes_mean * p_counter)+ p->sleeping_time)/(p_counter+1);
    800032c4:	00007597          	auipc	a1,0x7
    800032c8:	d7858593          	addi	a1,a1,-648 # 8000a03c <p_counter>
    800032cc:	4194                	lw	a3,0(a1)
    800032ce:	0016871b          	addiw	a4,a3,1
    800032d2:	00007617          	auipc	a2,0x7
    800032d6:	d7660613          	addi	a2,a2,-650 # 8000a048 <sleeping_processes_mean>
    800032da:	421c                	lw	a5,0(a2)
    800032dc:	02d787bb          	mulw	a5,a5,a3
    800032e0:	04c92503          	lw	a0,76(s2)
    800032e4:	9fa9                	addw	a5,a5,a0
    800032e6:	02e7d7bb          	divuw	a5,a5,a4
    800032ea:	c21c                	sw	a5,0(a2)
    running_processes_mean = ((running_processes_mean * p_counter)+ p->running_time)/(p_counter+1);
    800032ec:	04492603          	lw	a2,68(s2)
    800032f0:	00007517          	auipc	a0,0x7
    800032f4:	d5450513          	addi	a0,a0,-684 # 8000a044 <running_processes_mean>
    800032f8:	411c                	lw	a5,0(a0)
    800032fa:	02d787bb          	mulw	a5,a5,a3
    800032fe:	9fb1                	addw	a5,a5,a2
    80003300:	02e7d7bb          	divuw	a5,a5,a4
    80003304:	c11c                	sw	a5,0(a0)
    runnable_processes_mean = ((runnable_processes_mean * p_counter)+ p->runnable_time)/(p_counter+1);
    80003306:	00007517          	auipc	a0,0x7
    8000330a:	d3a50513          	addi	a0,a0,-710 # 8000a040 <runnable_processes_mean>
    8000330e:	411c                	lw	a5,0(a0)
    80003310:	02d787bb          	mulw	a5,a5,a3
    80003314:	04892683          	lw	a3,72(s2)
    80003318:	9fb5                	addw	a5,a5,a3
    8000331a:	02e7d7bb          	divuw	a5,a5,a4
    8000331e:	c11c                	sw	a5,0(a0)
    p_counter += 1;
    80003320:	c198                	sw	a4,0(a1)
    program_time += p->running_time;
    80003322:	00007697          	auipc	a3,0x7
    80003326:	d1668693          	addi	a3,a3,-746 # 8000a038 <program_time>
    8000332a:	429c                	lw	a5,0(a3)
    8000332c:	00c7873b          	addw	a4,a5,a2
    80003330:	c298                	sw	a4,0(a3)
    cpu_utilization = (program_time* 100) / (ticks - start_time) ;
    80003332:	06400793          	li	a5,100
    80003336:	02e787bb          	mulw	a5,a5,a4
    8000333a:	00007717          	auipc	a4,0x7
    8000333e:	d1a72703          	lw	a4,-742(a4) # 8000a054 <ticks>
    80003342:	00007697          	auipc	a3,0x7
    80003346:	cf26a683          	lw	a3,-782(a3) # 8000a034 <start_time>
    8000334a:	9f15                	subw	a4,a4,a3
    8000334c:	02e7d7bb          	divuw	a5,a5,a4
    80003350:	00007717          	auipc	a4,0x7
    80003354:	cef72023          	sw	a5,-800(a4) # 8000a030 <cpu_utilization>
    80003358:	b58d                	j	800031ba <exit+0x70>
    8000335a:	8612                	mv	a2,tp
  int id = r_tp();
    8000335c:	2601                	sext.w	a2,a2
  c->cpu_id = id;
    8000335e:	0000f797          	auipc	a5,0xf
    80003362:	f6278793          	addi	a5,a5,-158 # 800122c0 <cpus>
    80003366:	09000693          	li	a3,144
    8000336a:	02d60733          	mul	a4,a2,a3
    8000336e:	973e                	add	a4,a4,a5
    80003370:	08c72423          	sw	a2,136(a4)
    mycpu()->runnable_list_head = -1;
    80003374:	567d                	li	a2,-1
    80003376:	08c72023          	sw	a2,128(a4)
    8000337a:	8712                	mv	a4,tp
  int id = r_tp();
    8000337c:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    8000337e:	02d706b3          	mul	a3,a4,a3
    80003382:	97b6                	add	a5,a5,a3
    80003384:	08e7a423          	sw	a4,136(a5)
    mycpu()->runnable_list_tail = -1;
    80003388:	08c7a223          	sw	a2,132(a5)
  if (res == 3){
    8000338c:	b5f9                	j	8000325a <exit+0x110>
    8000338e:	8792                	mv	a5,tp
  int id = r_tp();
    80003390:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80003392:	09000713          	li	a4,144
    80003396:	02e786b3          	mul	a3,a5,a4
    8000339a:	0000f717          	auipc	a4,0xf
    8000339e:	f2670713          	addi	a4,a4,-218 # 800122c0 <cpus>
    800033a2:	9736                	add	a4,a4,a3
    800033a4:	08f72423          	sw	a5,136(a4)
    mycpu()->runnable_list_head = p->next_proc;
    800033a8:	06092783          	lw	a5,96(s2)
    800033ac:	08f72023          	sw	a5,128(a4)
    proc[p->next_proc].prev_proc = -1;
    800033b0:	19800713          	li	a4,408
    800033b4:	02e787b3          	mul	a5,a5,a4
    800033b8:	0000f717          	auipc	a4,0xf
    800033bc:	3b870713          	addi	a4,a4,952 # 80012770 <proc>
    800033c0:	97ba                	add	a5,a5,a4
    800033c2:	577d                	li	a4,-1
    800033c4:	d3f8                	sw	a4,100(a5)
  if (res == 3){
    800033c6:	bd51                	j	8000325a <exit+0x110>
    800033c8:	8792                	mv	a5,tp
  int id = r_tp();
    800033ca:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800033cc:	09000713          	li	a4,144
    800033d0:	02e786b3          	mul	a3,a5,a4
    800033d4:	0000f717          	auipc	a4,0xf
    800033d8:	eec70713          	addi	a4,a4,-276 # 800122c0 <cpus>
    800033dc:	9736                	add	a4,a4,a3
    800033de:	08f72423          	sw	a5,136(a4)
    mycpu()->runnable_list_tail = p->prev_proc;
    800033e2:	06492783          	lw	a5,100(s2)
    800033e6:	08f72223          	sw	a5,132(a4)
    proc[p->prev_proc].next_proc = -1;
    800033ea:	19800713          	li	a4,408
    800033ee:	02e787b3          	mul	a5,a5,a4
    800033f2:	0000f717          	auipc	a4,0xf
    800033f6:	37e70713          	addi	a4,a4,894 # 80012770 <proc>
    800033fa:	97ba                	add	a5,a5,a4
    800033fc:	577d                	li	a4,-1
    800033fe:	d3b8                	sw	a4,96(a5)
    80003400:	bda9                	j	8000325a <exit+0x110>
    printf("zombie");
    80003402:	00006517          	auipc	a0,0x6
    80003406:	e7650513          	addi	a0,a0,-394 # 80009278 <digits+0x238>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	17e080e7          	jalr	382(ra) # 80000588 <printf>
    add_proc_to_list(zombie_list_tail, p);
    80003412:	85ca                	mv	a1,s2
    80003414:	00006517          	auipc	a0,0x6
    80003418:	62452503          	lw	a0,1572(a0) # 80009a38 <zombie_list_tail>
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	42a080e7          	jalr	1066(ra) # 80001846 <add_proc_to_list>
     if (zombie_list_head == -1)
    80003424:	00006717          	auipc	a4,0x6
    80003428:	61872703          	lw	a4,1560(a4) # 80009a3c <zombie_list_head>
    8000342c:	57fd                	li	a5,-1
    8000342e:	00f70963          	beq	a4,a5,80003440 <exit+0x2f6>
    zombie_list_tail = p->proc_ind;
    80003432:	05c92783          	lw	a5,92(s2)
    80003436:	00006717          	auipc	a4,0x6
    8000343a:	60f72123          	sw	a5,1538(a4) # 80009a38 <zombie_list_tail>
    8000343e:	b5a1                	j	80003286 <exit+0x13c>
        zombie_list_head = p->proc_ind;
    80003440:	05c92783          	lw	a5,92(s2)
    80003444:	00006717          	auipc	a4,0x6
    80003448:	5ef72c23          	sw	a5,1528(a4) # 80009a3c <zombie_list_head>
    8000344c:	b7dd                	j	80003432 <exit+0x2e8>

000000008000344e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000344e:	7179                	addi	sp,sp,-48
    80003450:	f406                	sd	ra,40(sp)
    80003452:	f022                	sd	s0,32(sp)
    80003454:	ec26                	sd	s1,24(sp)
    80003456:	e84a                	sd	s2,16(sp)
    80003458:	e44e                	sd	s3,8(sp)
    8000345a:	1800                	addi	s0,sp,48
    8000345c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000345e:	0000f497          	auipc	s1,0xf
    80003462:	31248493          	addi	s1,s1,786 # 80012770 <proc>
    80003466:	00016997          	auipc	s3,0x16
    8000346a:	90a98993          	addi	s3,s3,-1782 # 80018d70 <tickslock>
    acquire(&p->lock);
    8000346e:	8526                	mv	a0,s1
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	774080e7          	jalr	1908(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80003478:	589c                	lw	a5,48(s1)
    8000347a:	01278d63          	beq	a5,s2,80003494 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000347e:	8526                	mv	a0,s1
    80003480:	ffffe097          	auipc	ra,0xffffe
    80003484:	818080e7          	jalr	-2024(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003488:	19848493          	addi	s1,s1,408
    8000348c:	ff3491e3          	bne	s1,s3,8000346e <kill+0x20>
  }
  return -1;
    80003490:	557d                	li	a0,-1
    80003492:	a829                	j	800034ac <kill+0x5e>
      p->killed = 1;
    80003494:	4785                	li	a5,1
    80003496:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80003498:	4c98                	lw	a4,24(s1)
    8000349a:	4789                	li	a5,2
    8000349c:	00f70f63          	beq	a4,a5,800034ba <kill+0x6c>
      release(&p->lock);
    800034a0:	8526                	mv	a0,s1
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	7f6080e7          	jalr	2038(ra) # 80000c98 <release>
      return 0;
    800034aa:	4501                	li	a0,0
}
    800034ac:	70a2                	ld	ra,40(sp)
    800034ae:	7402                	ld	s0,32(sp)
    800034b0:	64e2                	ld	s1,24(sp)
    800034b2:	6942                	ld	s2,16(sp)
    800034b4:	69a2                	ld	s3,8(sp)
    800034b6:	6145                	addi	sp,sp,48
    800034b8:	8082                	ret
        p->state = RUNNABLE;
    800034ba:	478d                	li	a5,3
    800034bc:	cc9c                	sw	a5,24(s1)
        p->sleeping_time += ticks - p->start_sleeping_time;
    800034be:	00007717          	auipc	a4,0x7
    800034c2:	b9672703          	lw	a4,-1130(a4) # 8000a054 <ticks>
    800034c6:	44fc                	lw	a5,76(s1)
    800034c8:	9fb9                	addw	a5,a5,a4
    800034ca:	48f4                	lw	a3,84(s1)
    800034cc:	9f95                	subw	a5,a5,a3
    800034ce:	c4fc                	sw	a5,76(s1)
        p->last_runnable_time = ticks;
    800034d0:	dcd8                	sw	a4,60(s1)
    800034d2:	b7f9                	j	800034a0 <kill+0x52>

00000000800034d4 <print_stats>:

int 
print_stats(void)
{
    800034d4:	1141                	addi	sp,sp,-16
    800034d6:	e406                	sd	ra,8(sp)
    800034d8:	e022                	sd	s0,0(sp)
    800034da:	0800                	addi	s0,sp,16
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    800034dc:	00007597          	auipc	a1,0x7
    800034e0:	b6c5a583          	lw	a1,-1172(a1) # 8000a048 <sleeping_processes_mean>
    800034e4:	00006517          	auipc	a0,0x6
    800034e8:	f0450513          	addi	a0,a0,-252 # 800093e8 <digits+0x3a8>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	09c080e7          	jalr	156(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    800034f4:	00007597          	auipc	a1,0x7
    800034f8:	b4c5a583          	lw	a1,-1204(a1) # 8000a040 <runnable_processes_mean>
    800034fc:	00006517          	auipc	a0,0x6
    80003500:	f0c50513          	addi	a0,a0,-244 # 80009408 <digits+0x3c8>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	084080e7          	jalr	132(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    8000350c:	00007597          	auipc	a1,0x7
    80003510:	b385a583          	lw	a1,-1224(a1) # 8000a044 <running_processes_mean>
    80003514:	00006517          	auipc	a0,0x6
    80003518:	f1450513          	addi	a0,a0,-236 # 80009428 <digits+0x3e8>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	06c080e7          	jalr	108(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80003524:	00007597          	auipc	a1,0x7
    80003528:	b145a583          	lw	a1,-1260(a1) # 8000a038 <program_time>
    8000352c:	00006517          	auipc	a0,0x6
    80003530:	f1c50513          	addi	a0,a0,-228 # 80009448 <digits+0x408>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	054080e7          	jalr	84(ra) # 80000588 <printf>
  printf("cpu_utilization: %d\n", cpu_utilization);
    8000353c:	00007597          	auipc	a1,0x7
    80003540:	af45a583          	lw	a1,-1292(a1) # 8000a030 <cpu_utilization>
    80003544:	00006517          	auipc	a0,0x6
    80003548:	f1c50513          	addi	a0,a0,-228 # 80009460 <digits+0x420>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	03c080e7          	jalr	60(ra) # 80000588 <printf>
  printf("ticks: %d\n", ticks);
    80003554:	00007597          	auipc	a1,0x7
    80003558:	b005a583          	lw	a1,-1280(a1) # 8000a054 <ticks>
    8000355c:	00006517          	auipc	a0,0x6
    80003560:	f1c50513          	addi	a0,a0,-228 # 80009478 <digits+0x438>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  return 0;
}
    8000356c:	4501                	li	a0,0
    8000356e:	60a2                	ld	ra,8(sp)
    80003570:	6402                	ld	s0,0(sp)
    80003572:	0141                	addi	sp,sp,16
    80003574:	8082                	ret

0000000080003576 <set_cpu>:
// Ass2
int
set_cpu(int cpu_num)
{
  // TODO
  if (cpu_num > NCPU)
    80003576:	47a1                	li	a5,8
    80003578:	0aa7cd63          	blt	a5,a0,80003632 <set_cpu+0xbc>
{
    8000357c:	1101                	addi	sp,sp,-32
    8000357e:	ec06                	sd	ra,24(sp)
    80003580:	e822                	sd	s0,16(sp)
    80003582:	e426                	sd	s1,8(sp)
    80003584:	e04a                	sd	s2,0(sp)
    80003586:	1000                	addi	s0,sp,32
    return -1;

  struct cpu* c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    80003588:	0000f497          	auipc	s1,0xf
    8000358c:	d3848493          	addi	s1,s1,-712 # 800122c0 <cpus>
    80003590:	0000f717          	auipc	a4,0xf
    80003594:	1b070713          	addi	a4,a4,432 # 80012740 <pid_lock>
  {
    if (c->cpu_id == cpu_num)
    80003598:	0884a783          	lw	a5,136(s1)
    8000359c:	00a78d63          	beq	a5,a0,800035b6 <set_cpu+0x40>
  for(c = cpus; c < &cpus[NCPU]; c++)
    800035a0:	09048493          	addi	s1,s1,144
    800035a4:	fee49ae3          	bne	s1,a4,80003598 <set_cpu+0x22>
      }
      
      return 0;
    }
  }
  return -1;
    800035a8:	557d                	li	a0,-1
}
    800035aa:	60e2                	ld	ra,24(sp)
    800035ac:	6442                	ld	s0,16(sp)
    800035ae:	64a2                	ld	s1,8(sp)
    800035b0:	6902                	ld	s2,0(sp)
    800035b2:	6105                	addi	sp,sp,32
    800035b4:	8082                	ret
      printf("runnable");
    800035b6:	00006517          	auipc	a0,0x6
    800035ba:	cfa50513          	addi	a0,a0,-774 # 800092b0 <digits+0x270>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	fca080e7          	jalr	-54(ra) # 80000588 <printf>
      if (c->runnable_list_head == -1)
    800035c6:	0804a703          	lw	a4,128(s1)
    800035ca:	57fd                	li	a5,-1
    800035cc:	02f70763          	beq	a4,a5,800035fa <set_cpu+0x84>
        add_proc_to_list(c->runnable_list_tail, myproc());
    800035d0:	0844a903          	lw	s2,132(s1)
    800035d4:	ffffe097          	auipc	ra,0xffffe
    800035d8:	5f0080e7          	jalr	1520(ra) # 80001bc4 <myproc>
    800035dc:	85aa                	mv	a1,a0
    800035de:	854a                	mv	a0,s2
    800035e0:	ffffe097          	auipc	ra,0xffffe
    800035e4:	266080e7          	jalr	614(ra) # 80001846 <add_proc_to_list>
        c->runnable_list_tail = myproc()->proc_ind;
    800035e8:	ffffe097          	auipc	ra,0xffffe
    800035ec:	5dc080e7          	jalr	1500(ra) # 80001bc4 <myproc>
    800035f0:	4d7c                	lw	a5,92(a0)
    800035f2:	08f4a223          	sw	a5,132(s1)
      return 0;
    800035f6:	4501                	li	a0,0
    800035f8:	bf4d                	j	800035aa <set_cpu+0x34>
        printf("init runnable %d\n", proc->proc_ind);
    800035fa:	0000f597          	auipc	a1,0xf
    800035fe:	1d25a583          	lw	a1,466(a1) # 800127cc <proc+0x5c>
    80003602:	00006517          	auipc	a0,0x6
    80003606:	cbe50513          	addi	a0,a0,-834 # 800092c0 <digits+0x280>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	f7e080e7          	jalr	-130(ra) # 80000588 <printf>
        c->runnable_list_tail = myproc()->proc_ind;
    80003612:	ffffe097          	auipc	ra,0xffffe
    80003616:	5b2080e7          	jalr	1458(ra) # 80001bc4 <myproc>
    8000361a:	4d7c                	lw	a5,92(a0)
    8000361c:	08f4a223          	sw	a5,132(s1)
        c->runnable_list_head = myproc()->proc_ind;
    80003620:	ffffe097          	auipc	ra,0xffffe
    80003624:	5a4080e7          	jalr	1444(ra) # 80001bc4 <myproc>
    80003628:	4d7c                	lw	a5,92(a0)
    8000362a:	08f4a023          	sw	a5,128(s1)
      return 0;
    8000362e:	4501                	li	a0,0
    80003630:	bfad                	j	800035aa <set_cpu+0x34>
    return -1;
    80003632:	557d                	li	a0,-1
}
    80003634:	8082                	ret

0000000080003636 <get_cpu>:


int
get_cpu()
{
    80003636:	1141                	addi	sp,sp,-16
    80003638:	e422                	sd	s0,8(sp)
    8000363a:	0800                	addi	s0,sp,16
    8000363c:	8512                	mv	a0,tp
  // TODO
  return cpuid();
}
    8000363e:	2501                	sext.w	a0,a0
    80003640:	6422                	ld	s0,8(sp)
    80003642:	0141                	addi	sp,sp,16
    80003644:	8082                	ret

0000000080003646 <pause_system>:


int
pause_system(int seconds)
{
    80003646:	711d                	addi	sp,sp,-96
    80003648:	ec86                	sd	ra,88(sp)
    8000364a:	e8a2                	sd	s0,80(sp)
    8000364c:	e4a6                	sd	s1,72(sp)
    8000364e:	e0ca                	sd	s2,64(sp)
    80003650:	fc4e                	sd	s3,56(sp)
    80003652:	f852                	sd	s4,48(sp)
    80003654:	f456                	sd	s5,40(sp)
    80003656:	f05a                	sd	s6,32(sp)
    80003658:	ec5e                	sd	s7,24(sp)
    8000365a:	e862                	sd	s8,16(sp)
    8000365c:	e466                	sd	s9,8(sp)
    8000365e:	1080                	addi	s0,sp,96
    80003660:	84aa                	mv	s1,a0
  struct proc *p;
  struct proc *myProcess = myproc();
    80003662:	ffffe097          	auipc	ra,0xffffe
    80003666:	562080e7          	jalr	1378(ra) # 80001bc4 <myproc>
    8000366a:	8b2a                	mv	s6,a0

  pause_flag = 1;
    8000366c:	4785                	li	a5,1
    8000366e:	00007717          	auipc	a4,0x7
    80003672:	9ef72123          	sw	a5,-1566(a4) # 8000a050 <pause_flag>

  wake_up_time = ticks + (seconds * 10);
    80003676:	0024979b          	slliw	a5,s1,0x2
    8000367a:	9fa5                	addw	a5,a5,s1
    8000367c:	0017979b          	slliw	a5,a5,0x1
    80003680:	00007717          	auipc	a4,0x7
    80003684:	9d472703          	lw	a4,-1580(a4) # 8000a054 <ticks>
    80003688:	9fb9                	addw	a5,a5,a4
    8000368a:	00007717          	auipc	a4,0x7
    8000368e:	9cf72123          	sw	a5,-1598(a4) # 8000a04c <wake_up_time>

  for(p = proc; p < &proc[NPROC]; p++)
    80003692:	0000f497          	auipc	s1,0xf
    80003696:	0de48493          	addi	s1,s1,222 # 80012770 <proc>
  {
    acquire(&p->lock);
    if(p->state == RUNNING)
    8000369a:	4991                	li	s3,4
    {
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    8000369c:	00006a97          	auipc	s5,0x6
    800036a0:	d2ca8a93          	addi	s5,s5,-724 # 800093c8 <digits+0x388>
    800036a4:	00006b97          	auipc	s7,0x6
    800036a8:	d2cb8b93          	addi	s7,s7,-724 # 800093d0 <digits+0x390>
        if (p != myProcess) {
          p->paused = 1;
    800036ac:	4c85                	li	s9,1
          p->running_time += ticks - p->start_running_time;
    800036ae:	00007c17          	auipc	s8,0x7
    800036b2:	9a6c0c13          	addi	s8,s8,-1626 # 8000a054 <ticks>
  for(p = proc; p < &proc[NPROC]; p++)
    800036b6:	00015917          	auipc	s2,0x15
    800036ba:	6ba90913          	addi	s2,s2,1722 # 80018d70 <tickslock>
    800036be:	a811                	j	800036d2 <pause_system+0x8c>
          yield();
        }
      }
    }
    release(&p->lock);
    800036c0:	8526                	mv	a0,s1
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    800036ca:	19848493          	addi	s1,s1,408
    800036ce:	05248a63          	beq	s1,s2,80003722 <pause_system+0xdc>
    acquire(&p->lock);
    800036d2:	8526                	mv	a0,s1
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	510080e7          	jalr	1296(ra) # 80000be4 <acquire>
    if(p->state == RUNNING)
    800036dc:	4c9c                	lw	a5,24(s1)
    800036de:	ff3791e3          	bne	a5,s3,800036c0 <pause_system+0x7a>
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800036e2:	18848a13          	addi	s4,s1,392
    800036e6:	85d6                	mv	a1,s5
    800036e8:	8552                	mv	a0,s4
    800036ea:	fffff097          	auipc	ra,0xfffff
    800036ee:	99a080e7          	jalr	-1638(ra) # 80002084 <str_compare>
    800036f2:	d579                	beqz	a0,800036c0 <pause_system+0x7a>
    800036f4:	85de                	mv	a1,s7
    800036f6:	8552                	mv	a0,s4
    800036f8:	fffff097          	auipc	ra,0xfffff
    800036fc:	98c080e7          	jalr	-1652(ra) # 80002084 <str_compare>
    80003700:	d161                	beqz	a0,800036c0 <pause_system+0x7a>
        if (p != myProcess) {
    80003702:	fa9b0fe3          	beq	s6,s1,800036c0 <pause_system+0x7a>
          p->paused = 1;
    80003706:	0594a023          	sw	s9,64(s1)
          p->running_time += ticks - p->start_running_time;
    8000370a:	40fc                	lw	a5,68(s1)
    8000370c:	000c2703          	lw	a4,0(s8)
    80003710:	9fb9                	addw	a5,a5,a4
    80003712:	48b8                	lw	a4,80(s1)
    80003714:	9f99                	subw	a5,a5,a4
    80003716:	c0fc                	sw	a5,68(s1)
          yield();
    80003718:	fffff097          	auipc	ra,0xfffff
    8000371c:	39c080e7          	jalr	924(ra) # 80002ab4 <yield>
    80003720:	b745                	j	800036c0 <pause_system+0x7a>
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    80003722:	188b0493          	addi	s1,s6,392 # ffffffff80000188 <end+0xfffffffefffd8188>
    80003726:	00006597          	auipc	a1,0x6
    8000372a:	ca258593          	addi	a1,a1,-862 # 800093c8 <digits+0x388>
    8000372e:	8526                	mv	a0,s1
    80003730:	fffff097          	auipc	ra,0xfffff
    80003734:	954080e7          	jalr	-1708(ra) # 80002084 <str_compare>
    80003738:	ed19                	bnez	a0,80003756 <pause_system+0x110>
    myProcess->running_time += ticks - myProcess->start_running_time;
    release(&myProcess->lock);
    yield();
  }
  return 0;
}
    8000373a:	4501                	li	a0,0
    8000373c:	60e6                	ld	ra,88(sp)
    8000373e:	6446                	ld	s0,80(sp)
    80003740:	64a6                	ld	s1,72(sp)
    80003742:	6906                	ld	s2,64(sp)
    80003744:	79e2                	ld	s3,56(sp)
    80003746:	7a42                	ld	s4,48(sp)
    80003748:	7aa2                	ld	s5,40(sp)
    8000374a:	7b02                	ld	s6,32(sp)
    8000374c:	6be2                	ld	s7,24(sp)
    8000374e:	6c42                	ld	s8,16(sp)
    80003750:	6ca2                	ld	s9,8(sp)
    80003752:	6125                	addi	sp,sp,96
    80003754:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    80003756:	00006597          	auipc	a1,0x6
    8000375a:	c7a58593          	addi	a1,a1,-902 # 800093d0 <digits+0x390>
    8000375e:	8526                	mv	a0,s1
    80003760:	fffff097          	auipc	ra,0xfffff
    80003764:	924080e7          	jalr	-1756(ra) # 80002084 <str_compare>
    80003768:	d969                	beqz	a0,8000373a <pause_system+0xf4>
    acquire(&myProcess->lock);
    8000376a:	855a                	mv	a0,s6
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	478080e7          	jalr	1144(ra) # 80000be4 <acquire>
    myProcess->paused = 1;
    80003774:	4785                	li	a5,1
    80003776:	04fb2023          	sw	a5,64(s6)
    myProcess->running_time += ticks - myProcess->start_running_time;
    8000377a:	044b2783          	lw	a5,68(s6)
    8000377e:	00007717          	auipc	a4,0x7
    80003782:	8d672703          	lw	a4,-1834(a4) # 8000a054 <ticks>
    80003786:	9fb9                	addw	a5,a5,a4
    80003788:	050b2703          	lw	a4,80(s6)
    8000378c:	9f99                	subw	a5,a5,a4
    8000378e:	04fb2223          	sw	a5,68(s6)
    release(&myProcess->lock);
    80003792:	855a                	mv	a0,s6
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	504080e7          	jalr	1284(ra) # 80000c98 <release>
    yield();
    8000379c:	fffff097          	auipc	ra,0xfffff
    800037a0:	318080e7          	jalr	792(ra) # 80002ab4 <yield>
    800037a4:	bf59                	j	8000373a <pause_system+0xf4>

00000000800037a6 <kill_system>:
// depending on usr_dst.
// Returns 0 on success, -1 on error.

int
kill_system(void) 
{
    800037a6:	7139                	addi	sp,sp,-64
    800037a8:	fc06                	sd	ra,56(sp)
    800037aa:	f822                	sd	s0,48(sp)
    800037ac:	f426                	sd	s1,40(sp)
    800037ae:	f04a                	sd	s2,32(sp)
    800037b0:	ec4e                	sd	s3,24(sp)
    800037b2:	e852                	sd	s4,16(sp)
    800037b4:	e456                	sd	s5,8(sp)
    800037b6:	e05a                	sd	s6,0(sp)
    800037b8:	0080                	addi	s0,sp,64
  struct proc *p;
  struct proc *myProcess = myproc();
    800037ba:	ffffe097          	auipc	ra,0xffffe
    800037be:	40a080e7          	jalr	1034(ra) # 80001bc4 <myproc>
    800037c2:	8b2a                	mv	s6,a0

  for (p = proc; p < &proc[NPROC]; p++) {
    800037c4:	0000f497          	auipc	s1,0xf
    800037c8:	13448493          	addi	s1,s1,308 # 800128f8 <proc+0x188>
    800037cc:	00015a17          	auipc	s4,0x15
    800037d0:	72ca0a13          	addi	s4,s4,1836 # 80018ef8 <bcache+0x170>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800037d4:	00006997          	auipc	s3,0x6
    800037d8:	bf498993          	addi	s3,s3,-1036 # 800093c8 <digits+0x388>
    800037dc:	00006a97          	auipc	s5,0x6
    800037e0:	bf4a8a93          	addi	s5,s5,-1036 # 800093d0 <digits+0x390>
    800037e4:	a029                	j	800037ee <kill_system+0x48>
  for (p = proc; p < &proc[NPROC]; p++) {
    800037e6:	19848493          	addi	s1,s1,408
    800037ea:	03448b63          	beq	s1,s4,80003820 <kill_system+0x7a>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800037ee:	85ce                	mv	a1,s3
    800037f0:	8526                	mv	a0,s1
    800037f2:	fffff097          	auipc	ra,0xfffff
    800037f6:	892080e7          	jalr	-1902(ra) # 80002084 <str_compare>
    800037fa:	d575                	beqz	a0,800037e6 <kill_system+0x40>
    800037fc:	85d6                	mv	a1,s5
    800037fe:	8526                	mv	a0,s1
    80003800:	fffff097          	auipc	ra,0xfffff
    80003804:	884080e7          	jalr	-1916(ra) # 80002084 <str_compare>
    80003808:	dd79                	beqz	a0,800037e6 <kill_system+0x40>
      if (p != myProcess) {
    8000380a:	e7848793          	addi	a5,s1,-392
    8000380e:	fcfb0ce3          	beq	s6,a5,800037e6 <kill_system+0x40>
        kill(p->pid);      
    80003812:	ea84a503          	lw	a0,-344(s1)
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	c38080e7          	jalr	-968(ra) # 8000344e <kill>
    8000381e:	b7e1                	j	800037e6 <kill_system+0x40>
      }
    }
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    80003820:	188b0493          	addi	s1,s6,392
    80003824:	00006597          	auipc	a1,0x6
    80003828:	ba458593          	addi	a1,a1,-1116 # 800093c8 <digits+0x388>
    8000382c:	8526                	mv	a0,s1
    8000382e:	fffff097          	auipc	ra,0xfffff
    80003832:	856080e7          	jalr	-1962(ra) # 80002084 <str_compare>
    80003836:	ed01                	bnez	a0,8000384e <kill_system+0xa8>
    kill(myProcess->pid);
  }
  return 0;
}
    80003838:	4501                	li	a0,0
    8000383a:	70e2                	ld	ra,56(sp)
    8000383c:	7442                	ld	s0,48(sp)
    8000383e:	74a2                	ld	s1,40(sp)
    80003840:	7902                	ld	s2,32(sp)
    80003842:	69e2                	ld	s3,24(sp)
    80003844:	6a42                	ld	s4,16(sp)
    80003846:	6aa2                	ld	s5,8(sp)
    80003848:	6b02                	ld	s6,0(sp)
    8000384a:	6121                	addi	sp,sp,64
    8000384c:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    8000384e:	00006597          	auipc	a1,0x6
    80003852:	b8258593          	addi	a1,a1,-1150 # 800093d0 <digits+0x390>
    80003856:	8526                	mv	a0,s1
    80003858:	fffff097          	auipc	ra,0xfffff
    8000385c:	82c080e7          	jalr	-2004(ra) # 80002084 <str_compare>
    80003860:	dd61                	beqz	a0,80003838 <kill_system+0x92>
    kill(myProcess->pid);
    80003862:	030b2503          	lw	a0,48(s6)
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	be8080e7          	jalr	-1048(ra) # 8000344e <kill>
    8000386e:	b7e9                	j	80003838 <kill_system+0x92>

0000000080003870 <either_copyout>:

int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80003870:	7179                	addi	sp,sp,-48
    80003872:	f406                	sd	ra,40(sp)
    80003874:	f022                	sd	s0,32(sp)
    80003876:	ec26                	sd	s1,24(sp)
    80003878:	e84a                	sd	s2,16(sp)
    8000387a:	e44e                	sd	s3,8(sp)
    8000387c:	e052                	sd	s4,0(sp)
    8000387e:	1800                	addi	s0,sp,48
    80003880:	84aa                	mv	s1,a0
    80003882:	892e                	mv	s2,a1
    80003884:	89b2                	mv	s3,a2
    80003886:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003888:	ffffe097          	auipc	ra,0xffffe
    8000388c:	33c080e7          	jalr	828(ra) # 80001bc4 <myproc>
  if(user_dst){
    80003890:	c08d                	beqz	s1,800038b2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003892:	86d2                	mv	a3,s4
    80003894:	864e                	mv	a2,s3
    80003896:	85ca                	mv	a1,s2
    80003898:	6148                	ld	a0,128(a0)
    8000389a:	ffffe097          	auipc	ra,0xffffe
    8000389e:	de0080e7          	jalr	-544(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800038a2:	70a2                	ld	ra,40(sp)
    800038a4:	7402                	ld	s0,32(sp)
    800038a6:	64e2                	ld	s1,24(sp)
    800038a8:	6942                	ld	s2,16(sp)
    800038aa:	69a2                	ld	s3,8(sp)
    800038ac:	6a02                	ld	s4,0(sp)
    800038ae:	6145                	addi	sp,sp,48
    800038b0:	8082                	ret
    memmove((char *)dst, src, len);
    800038b2:	000a061b          	sext.w	a2,s4
    800038b6:	85ce                	mv	a1,s3
    800038b8:	854a                	mv	a0,s2
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	486080e7          	jalr	1158(ra) # 80000d40 <memmove>
    return 0;
    800038c2:	8526                	mv	a0,s1
    800038c4:	bff9                	j	800038a2 <either_copyout+0x32>

00000000800038c6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800038c6:	7179                	addi	sp,sp,-48
    800038c8:	f406                	sd	ra,40(sp)
    800038ca:	f022                	sd	s0,32(sp)
    800038cc:	ec26                	sd	s1,24(sp)
    800038ce:	e84a                	sd	s2,16(sp)
    800038d0:	e44e                	sd	s3,8(sp)
    800038d2:	e052                	sd	s4,0(sp)
    800038d4:	1800                	addi	s0,sp,48
    800038d6:	892a                	mv	s2,a0
    800038d8:	84ae                	mv	s1,a1
    800038da:	89b2                	mv	s3,a2
    800038dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800038de:	ffffe097          	auipc	ra,0xffffe
    800038e2:	2e6080e7          	jalr	742(ra) # 80001bc4 <myproc>
  if(user_src){
    800038e6:	c08d                	beqz	s1,80003908 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800038e8:	86d2                	mv	a3,s4
    800038ea:	864e                	mv	a2,s3
    800038ec:	85ca                	mv	a1,s2
    800038ee:	6148                	ld	a0,128(a0)
    800038f0:	ffffe097          	auipc	ra,0xffffe
    800038f4:	e16080e7          	jalr	-490(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800038f8:	70a2                	ld	ra,40(sp)
    800038fa:	7402                	ld	s0,32(sp)
    800038fc:	64e2                	ld	s1,24(sp)
    800038fe:	6942                	ld	s2,16(sp)
    80003900:	69a2                	ld	s3,8(sp)
    80003902:	6a02                	ld	s4,0(sp)
    80003904:	6145                	addi	sp,sp,48
    80003906:	8082                	ret
    memmove(dst, (char*)src, len);
    80003908:	000a061b          	sext.w	a2,s4
    8000390c:	85ce                	mv	a1,s3
    8000390e:	854a                	mv	a0,s2
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	430080e7          	jalr	1072(ra) # 80000d40 <memmove>
    return 0;
    80003918:	8526                	mv	a0,s1
    8000391a:	bff9                	j	800038f8 <either_copyin+0x32>

000000008000391c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000391c:	715d                	addi	sp,sp,-80
    8000391e:	e486                	sd	ra,72(sp)
    80003920:	e0a2                	sd	s0,64(sp)
    80003922:	fc26                	sd	s1,56(sp)
    80003924:	f84a                	sd	s2,48(sp)
    80003926:	f44e                	sd	s3,40(sp)
    80003928:	f052                	sd	s4,32(sp)
    8000392a:	ec56                	sd	s5,24(sp)
    8000392c:	e85a                	sd	s6,16(sp)
    8000392e:	e45e                	sd	s7,8(sp)
    80003930:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003932:	00006517          	auipc	a0,0x6
    80003936:	b2650513          	addi	a0,a0,-1242 # 80009458 <digits+0x418>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	c4e080e7          	jalr	-946(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003942:	0000f497          	auipc	s1,0xf
    80003946:	fb648493          	addi	s1,s1,-74 # 800128f8 <proc+0x188>
    8000394a:	00015917          	auipc	s2,0x15
    8000394e:	5ae90913          	addi	s2,s2,1454 # 80018ef8 <bcache+0x170>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003952:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003954:	00006997          	auipc	s3,0x6
    80003958:	b3498993          	addi	s3,s3,-1228 # 80009488 <digits+0x448>
    printf("%d %s %s", p->pid, state, p->name);
    8000395c:	00006a97          	auipc	s5,0x6
    80003960:	b34a8a93          	addi	s5,s5,-1228 # 80009490 <digits+0x450>
    printf("\n");
    80003964:	00006a17          	auipc	s4,0x6
    80003968:	af4a0a13          	addi	s4,s4,-1292 # 80009458 <digits+0x418>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000396c:	00006b97          	auipc	s7,0x6
    80003970:	b4cb8b93          	addi	s7,s7,-1204 # 800094b8 <states.1844>
    80003974:	a00d                	j	80003996 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80003976:	ea86a583          	lw	a1,-344(a3)
    8000397a:	8556                	mv	a0,s5
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	c0c080e7          	jalr	-1012(ra) # 80000588 <printf>
    printf("\n");
    80003984:	8552                	mv	a0,s4
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	c02080e7          	jalr	-1022(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000398e:	19848493          	addi	s1,s1,408
    80003992:	03248163          	beq	s1,s2,800039b4 <procdump+0x98>
    if(p->state == UNUSED)
    80003996:	86a6                	mv	a3,s1
    80003998:	e904a783          	lw	a5,-368(s1)
    8000399c:	dbed                	beqz	a5,8000398e <procdump+0x72>
      state = "???";
    8000399e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800039a0:	fcfb6be3          	bltu	s6,a5,80003976 <procdump+0x5a>
    800039a4:	1782                	slli	a5,a5,0x20
    800039a6:	9381                	srli	a5,a5,0x20
    800039a8:	078e                	slli	a5,a5,0x3
    800039aa:	97de                	add	a5,a5,s7
    800039ac:	6390                	ld	a2,0(a5)
    800039ae:	f661                	bnez	a2,80003976 <procdump+0x5a>
      state = "???";
    800039b0:	864e                	mv	a2,s3
    800039b2:	b7d1                	j	80003976 <procdump+0x5a>
  }
}
    800039b4:	60a6                	ld	ra,72(sp)
    800039b6:	6406                	ld	s0,64(sp)
    800039b8:	74e2                	ld	s1,56(sp)
    800039ba:	7942                	ld	s2,48(sp)
    800039bc:	79a2                	ld	s3,40(sp)
    800039be:	7a02                	ld	s4,32(sp)
    800039c0:	6ae2                	ld	s5,24(sp)
    800039c2:	6b42                	ld	s6,16(sp)
    800039c4:	6ba2                	ld	s7,8(sp)
    800039c6:	6161                	addi	sp,sp,80
    800039c8:	8082                	ret

00000000800039ca <swtch>:
    800039ca:	00153023          	sd	ra,0(a0)
    800039ce:	00253423          	sd	sp,8(a0)
    800039d2:	e900                	sd	s0,16(a0)
    800039d4:	ed04                	sd	s1,24(a0)
    800039d6:	03253023          	sd	s2,32(a0)
    800039da:	03353423          	sd	s3,40(a0)
    800039de:	03453823          	sd	s4,48(a0)
    800039e2:	03553c23          	sd	s5,56(a0)
    800039e6:	05653023          	sd	s6,64(a0)
    800039ea:	05753423          	sd	s7,72(a0)
    800039ee:	05853823          	sd	s8,80(a0)
    800039f2:	05953c23          	sd	s9,88(a0)
    800039f6:	07a53023          	sd	s10,96(a0)
    800039fa:	07b53423          	sd	s11,104(a0)
    800039fe:	0005b083          	ld	ra,0(a1)
    80003a02:	0085b103          	ld	sp,8(a1)
    80003a06:	6980                	ld	s0,16(a1)
    80003a08:	6d84                	ld	s1,24(a1)
    80003a0a:	0205b903          	ld	s2,32(a1)
    80003a0e:	0285b983          	ld	s3,40(a1)
    80003a12:	0305ba03          	ld	s4,48(a1)
    80003a16:	0385ba83          	ld	s5,56(a1)
    80003a1a:	0405bb03          	ld	s6,64(a1)
    80003a1e:	0485bb83          	ld	s7,72(a1)
    80003a22:	0505bc03          	ld	s8,80(a1)
    80003a26:	0585bc83          	ld	s9,88(a1)
    80003a2a:	0605bd03          	ld	s10,96(a1)
    80003a2e:	0685bd83          	ld	s11,104(a1)
    80003a32:	8082                	ret

0000000080003a34 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003a34:	1141                	addi	sp,sp,-16
    80003a36:	e406                	sd	ra,8(sp)
    80003a38:	e022                	sd	s0,0(sp)
    80003a3a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003a3c:	00006597          	auipc	a1,0x6
    80003a40:	aac58593          	addi	a1,a1,-1364 # 800094e8 <states.1844+0x30>
    80003a44:	00015517          	auipc	a0,0x15
    80003a48:	32c50513          	addi	a0,a0,812 # 80018d70 <tickslock>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	108080e7          	jalr	264(ra) # 80000b54 <initlock>
}
    80003a54:	60a2                	ld	ra,8(sp)
    80003a56:	6402                	ld	s0,0(sp)
    80003a58:	0141                	addi	sp,sp,16
    80003a5a:	8082                	ret

0000000080003a5c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003a5c:	1141                	addi	sp,sp,-16
    80003a5e:	e422                	sd	s0,8(sp)
    80003a60:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003a62:	00003797          	auipc	a5,0x3
    80003a66:	53e78793          	addi	a5,a5,1342 # 80006fa0 <kernelvec>
    80003a6a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003a6e:	6422                	ld	s0,8(sp)
    80003a70:	0141                	addi	sp,sp,16
    80003a72:	8082                	ret

0000000080003a74 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003a74:	1141                	addi	sp,sp,-16
    80003a76:	e406                	sd	ra,8(sp)
    80003a78:	e022                	sd	s0,0(sp)
    80003a7a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003a7c:	ffffe097          	auipc	ra,0xffffe
    80003a80:	148080e7          	jalr	328(ra) # 80001bc4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003a84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003a88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003a8a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003a8e:	00004617          	auipc	a2,0x4
    80003a92:	57260613          	addi	a2,a2,1394 # 80008000 <_trampoline>
    80003a96:	00004697          	auipc	a3,0x4
    80003a9a:	56a68693          	addi	a3,a3,1386 # 80008000 <_trampoline>
    80003a9e:	8e91                	sub	a3,a3,a2
    80003aa0:	040007b7          	lui	a5,0x4000
    80003aa4:	17fd                	addi	a5,a5,-1
    80003aa6:	07b2                	slli	a5,a5,0xc
    80003aa8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003aaa:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003aae:	6558                	ld	a4,136(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003ab0:	180026f3          	csrr	a3,satp
    80003ab4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003ab6:	6558                	ld	a4,136(a0)
    80003ab8:	7934                	ld	a3,112(a0)
    80003aba:	6585                	lui	a1,0x1
    80003abc:	96ae                	add	a3,a3,a1
    80003abe:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003ac0:	6558                	ld	a4,136(a0)
    80003ac2:	00000697          	auipc	a3,0x0
    80003ac6:	13868693          	addi	a3,a3,312 # 80003bfa <usertrap>
    80003aca:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003acc:	6558                	ld	a4,136(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003ace:	8692                	mv	a3,tp
    80003ad0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003ad2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003ad6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003ada:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003ade:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003ae2:	6558                	ld	a4,136(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003ae4:	6f18                	ld	a4,24(a4)
    80003ae6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003aea:	614c                	ld	a1,128(a0)
    80003aec:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003aee:	00004717          	auipc	a4,0x4
    80003af2:	5a270713          	addi	a4,a4,1442 # 80008090 <userret>
    80003af6:	8f11                	sub	a4,a4,a2
    80003af8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003afa:	577d                	li	a4,-1
    80003afc:	177e                	slli	a4,a4,0x3f
    80003afe:	8dd9                	or	a1,a1,a4
    80003b00:	02000537          	lui	a0,0x2000
    80003b04:	157d                	addi	a0,a0,-1
    80003b06:	0536                	slli	a0,a0,0xd
    80003b08:	9782                	jalr	a5
}
    80003b0a:	60a2                	ld	ra,8(sp)
    80003b0c:	6402                	ld	s0,0(sp)
    80003b0e:	0141                	addi	sp,sp,16
    80003b10:	8082                	ret

0000000080003b12 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003b12:	1101                	addi	sp,sp,-32
    80003b14:	ec06                	sd	ra,24(sp)
    80003b16:	e822                	sd	s0,16(sp)
    80003b18:	e426                	sd	s1,8(sp)
    80003b1a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003b1c:	00015497          	auipc	s1,0x15
    80003b20:	25448493          	addi	s1,s1,596 # 80018d70 <tickslock>
    80003b24:	8526                	mv	a0,s1
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	0be080e7          	jalr	190(ra) # 80000be4 <acquire>
  ticks++;
    80003b2e:	00006517          	auipc	a0,0x6
    80003b32:	52650513          	addi	a0,a0,1318 # 8000a054 <ticks>
    80003b36:	411c                	lw	a5,0(a0)
    80003b38:	2785                	addiw	a5,a5,1
    80003b3a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003b3c:	fffff097          	auipc	ra,0xfffff
    80003b40:	40e080e7          	jalr	1038(ra) # 80002f4a <wakeup>
  release(&tickslock);
    80003b44:	8526                	mv	a0,s1
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	152080e7          	jalr	338(ra) # 80000c98 <release>
}
    80003b4e:	60e2                	ld	ra,24(sp)
    80003b50:	6442                	ld	s0,16(sp)
    80003b52:	64a2                	ld	s1,8(sp)
    80003b54:	6105                	addi	sp,sp,32
    80003b56:	8082                	ret

0000000080003b58 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003b58:	1101                	addi	sp,sp,-32
    80003b5a:	ec06                	sd	ra,24(sp)
    80003b5c:	e822                	sd	s0,16(sp)
    80003b5e:	e426                	sd	s1,8(sp)
    80003b60:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003b62:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003b66:	00074d63          	bltz	a4,80003b80 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003b6a:	57fd                	li	a5,-1
    80003b6c:	17fe                	slli	a5,a5,0x3f
    80003b6e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003b70:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003b72:	06f70363          	beq	a4,a5,80003bd8 <devintr+0x80>
  }
}
    80003b76:	60e2                	ld	ra,24(sp)
    80003b78:	6442                	ld	s0,16(sp)
    80003b7a:	64a2                	ld	s1,8(sp)
    80003b7c:	6105                	addi	sp,sp,32
    80003b7e:	8082                	ret
     (scause & 0xff) == 9){
    80003b80:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003b84:	46a5                	li	a3,9
    80003b86:	fed792e3          	bne	a5,a3,80003b6a <devintr+0x12>
    int irq = plic_claim();
    80003b8a:	00003097          	auipc	ra,0x3
    80003b8e:	51e080e7          	jalr	1310(ra) # 800070a8 <plic_claim>
    80003b92:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003b94:	47a9                	li	a5,10
    80003b96:	02f50763          	beq	a0,a5,80003bc4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003b9a:	4785                	li	a5,1
    80003b9c:	02f50963          	beq	a0,a5,80003bce <devintr+0x76>
    return 1;
    80003ba0:	4505                	li	a0,1
    } else if(irq){
    80003ba2:	d8f1                	beqz	s1,80003b76 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003ba4:	85a6                	mv	a1,s1
    80003ba6:	00006517          	auipc	a0,0x6
    80003baa:	94a50513          	addi	a0,a0,-1718 # 800094f0 <states.1844+0x38>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	9da080e7          	jalr	-1574(ra) # 80000588 <printf>
      plic_complete(irq);
    80003bb6:	8526                	mv	a0,s1
    80003bb8:	00003097          	auipc	ra,0x3
    80003bbc:	514080e7          	jalr	1300(ra) # 800070cc <plic_complete>
    return 1;
    80003bc0:	4505                	li	a0,1
    80003bc2:	bf55                	j	80003b76 <devintr+0x1e>
      uartintr();
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	de4080e7          	jalr	-540(ra) # 800009a8 <uartintr>
    80003bcc:	b7ed                	j	80003bb6 <devintr+0x5e>
      virtio_disk_intr();
    80003bce:	00004097          	auipc	ra,0x4
    80003bd2:	9de080e7          	jalr	-1570(ra) # 800075ac <virtio_disk_intr>
    80003bd6:	b7c5                	j	80003bb6 <devintr+0x5e>
    if(cpuid() == 0){
    80003bd8:	ffffe097          	auipc	ra,0xffffe
    80003bdc:	fb0080e7          	jalr	-80(ra) # 80001b88 <cpuid>
    80003be0:	c901                	beqz	a0,80003bf0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003be2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003be6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003be8:	14479073          	csrw	sip,a5
    return 2;
    80003bec:	4509                	li	a0,2
    80003bee:	b761                	j	80003b76 <devintr+0x1e>
      clockintr();
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	f22080e7          	jalr	-222(ra) # 80003b12 <clockintr>
    80003bf8:	b7ed                	j	80003be2 <devintr+0x8a>

0000000080003bfa <usertrap>:
{
    80003bfa:	1101                	addi	sp,sp,-32
    80003bfc:	ec06                	sd	ra,24(sp)
    80003bfe:	e822                	sd	s0,16(sp)
    80003c00:	e426                	sd	s1,8(sp)
    80003c02:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003c04:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003c08:	1007f793          	andi	a5,a5,256
    80003c0c:	e3a5                	bnez	a5,80003c6c <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003c0e:	00003797          	auipc	a5,0x3
    80003c12:	39278793          	addi	a5,a5,914 # 80006fa0 <kernelvec>
    80003c16:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003c1a:	ffffe097          	auipc	ra,0xffffe
    80003c1e:	faa080e7          	jalr	-86(ra) # 80001bc4 <myproc>
    80003c22:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003c24:	655c                	ld	a5,136(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003c26:	14102773          	csrr	a4,sepc
    80003c2a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003c2c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003c30:	47a1                	li	a5,8
    80003c32:	04f71b63          	bne	a4,a5,80003c88 <usertrap+0x8e>
    if(p->killed)
    80003c36:	551c                	lw	a5,40(a0)
    80003c38:	e3b1                	bnez	a5,80003c7c <usertrap+0x82>
    p->trapframe->epc += 4;
    80003c3a:	64d8                	ld	a4,136(s1)
    80003c3c:	6f1c                	ld	a5,24(a4)
    80003c3e:	0791                	addi	a5,a5,4
    80003c40:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003c4a:	10079073          	csrw	sstatus,a5
    syscall();
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	2f0080e7          	jalr	752(ra) # 80003f3e <syscall>
  if(p->killed)
    80003c56:	549c                	lw	a5,40(s1)
    80003c58:	e7b5                	bnez	a5,80003cc4 <usertrap+0xca>
  usertrapret();
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	e1a080e7          	jalr	-486(ra) # 80003a74 <usertrapret>
}
    80003c62:	60e2                	ld	ra,24(sp)
    80003c64:	6442                	ld	s0,16(sp)
    80003c66:	64a2                	ld	s1,8(sp)
    80003c68:	6105                	addi	sp,sp,32
    80003c6a:	8082                	ret
    panic("usertrap: not from user mode");
    80003c6c:	00006517          	auipc	a0,0x6
    80003c70:	8a450513          	addi	a0,a0,-1884 # 80009510 <states.1844+0x58>
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	8ca080e7          	jalr	-1846(ra) # 8000053e <panic>
      exit(-1);
    80003c7c:	557d                	li	a0,-1
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	4cc080e7          	jalr	1228(ra) # 8000314a <exit>
    80003c86:	bf55                	j	80003c3a <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	ed0080e7          	jalr	-304(ra) # 80003b58 <devintr>
    80003c90:	f179                	bnez	a0,80003c56 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003c92:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003c96:	5890                	lw	a2,48(s1)
    80003c98:	00006517          	auipc	a0,0x6
    80003c9c:	89850513          	addi	a0,a0,-1896 # 80009530 <states.1844+0x78>
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	8e8080e7          	jalr	-1816(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003ca8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003cac:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003cb0:	00006517          	auipc	a0,0x6
    80003cb4:	8b050513          	addi	a0,a0,-1872 # 80009560 <states.1844+0xa8>
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	8d0080e7          	jalr	-1840(ra) # 80000588 <printf>
    p->killed = 1;
    80003cc0:	4785                	li	a5,1
    80003cc2:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003cc4:	557d                	li	a0,-1
    80003cc6:	fffff097          	auipc	ra,0xfffff
    80003cca:	484080e7          	jalr	1156(ra) # 8000314a <exit>
    80003cce:	b771                	j	80003c5a <usertrap+0x60>

0000000080003cd0 <kerneltrap>:
{
    80003cd0:	7179                	addi	sp,sp,-48
    80003cd2:	f406                	sd	ra,40(sp)
    80003cd4:	f022                	sd	s0,32(sp)
    80003cd6:	ec26                	sd	s1,24(sp)
    80003cd8:	e84a                	sd	s2,16(sp)
    80003cda:	e44e                	sd	s3,8(sp)
    80003cdc:	e052                	sd	s4,0(sp)
    80003cde:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003ce0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003ce4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003ce8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0){
    80003cec:	1004f793          	andi	a5,s1,256
    80003cf0:	cb8d                	beqz	a5,80003d22 <kerneltrap+0x52>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003cf2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003cf6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003cf8:	ef8d                	bnez	a5,80003d32 <kerneltrap+0x62>
  if((which_dev = devintr()) == 0){
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	e5e080e7          	jalr	-418(ra) # 80003b58 <devintr>
    80003d02:	c121                	beqz	a0,80003d42 <kerneltrap+0x72>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003d04:	4789                	li	a5,2
    80003d06:	06f50b63          	beq	a0,a5,80003d7c <kerneltrap+0xac>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003d0a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003d0e:	10049073          	csrw	sstatus,s1
}
    80003d12:	70a2                	ld	ra,40(sp)
    80003d14:	7402                	ld	s0,32(sp)
    80003d16:	64e2                	ld	s1,24(sp)
    80003d18:	6942                	ld	s2,16(sp)
    80003d1a:	69a2                	ld	s3,8(sp)
    80003d1c:	6a02                	ld	s4,0(sp)
    80003d1e:	6145                	addi	sp,sp,48
    80003d20:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003d22:	00006517          	auipc	a0,0x6
    80003d26:	85e50513          	addi	a0,a0,-1954 # 80009580 <states.1844+0xc8>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	814080e7          	jalr	-2028(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003d32:	00006517          	auipc	a0,0x6
    80003d36:	87650513          	addi	a0,a0,-1930 # 800095a8 <states.1844+0xf0>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003d42:	85ce                	mv	a1,s3
    80003d44:	00006517          	auipc	a0,0x6
    80003d48:	88450513          	addi	a0,a0,-1916 # 800095c8 <states.1844+0x110>
    80003d4c:	ffffd097          	auipc	ra,0xffffd
    80003d50:	83c080e7          	jalr	-1988(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003d54:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003d58:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003d5c:	00006517          	auipc	a0,0x6
    80003d60:	87c50513          	addi	a0,a0,-1924 # 800095d8 <states.1844+0x120>
    80003d64:	ffffd097          	auipc	ra,0xffffd
    80003d68:	824080e7          	jalr	-2012(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003d6c:	00006517          	auipc	a0,0x6
    80003d70:	88450513          	addi	a0,a0,-1916 # 800095f0 <states.1844+0x138>
    80003d74:	ffffc097          	auipc	ra,0xffffc
    80003d78:	7ca080e7          	jalr	1994(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003d7c:	ffffe097          	auipc	ra,0xffffe
    80003d80:	e48080e7          	jalr	-440(ra) # 80001bc4 <myproc>
    80003d84:	d159                	beqz	a0,80003d0a <kerneltrap+0x3a>
    80003d86:	ffffe097          	auipc	ra,0xffffe
    80003d8a:	e3e080e7          	jalr	-450(ra) # 80001bc4 <myproc>
    80003d8e:	4d18                	lw	a4,24(a0)
    80003d90:	4791                	li	a5,4
    80003d92:	f6f71ce3          	bne	a4,a5,80003d0a <kerneltrap+0x3a>
    myproc()->running_time += ticks - myproc()->start_running_time;
    80003d96:	00006a17          	auipc	s4,0x6
    80003d9a:	2bea2a03          	lw	s4,702(s4) # 8000a054 <ticks>
    80003d9e:	ffffe097          	auipc	ra,0xffffe
    80003da2:	e26080e7          	jalr	-474(ra) # 80001bc4 <myproc>
    80003da6:	05052983          	lw	s3,80(a0)
    80003daa:	ffffe097          	auipc	ra,0xffffe
    80003dae:	e1a080e7          	jalr	-486(ra) # 80001bc4 <myproc>
    80003db2:	417c                	lw	a5,68(a0)
    80003db4:	014787bb          	addw	a5,a5,s4
    80003db8:	413787bb          	subw	a5,a5,s3
    80003dbc:	c17c                	sw	a5,68(a0)
    yield();
    80003dbe:	fffff097          	auipc	ra,0xfffff
    80003dc2:	cf6080e7          	jalr	-778(ra) # 80002ab4 <yield>
    80003dc6:	b791                	j	80003d0a <kerneltrap+0x3a>

0000000080003dc8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003dc8:	1101                	addi	sp,sp,-32
    80003dca:	ec06                	sd	ra,24(sp)
    80003dcc:	e822                	sd	s0,16(sp)
    80003dce:	e426                	sd	s1,8(sp)
    80003dd0:	1000                	addi	s0,sp,32
    80003dd2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003dd4:	ffffe097          	auipc	ra,0xffffe
    80003dd8:	df0080e7          	jalr	-528(ra) # 80001bc4 <myproc>
  switch (n) {
    80003ddc:	4795                	li	a5,5
    80003dde:	0497e163          	bltu	a5,s1,80003e20 <argraw+0x58>
    80003de2:	048a                	slli	s1,s1,0x2
    80003de4:	00006717          	auipc	a4,0x6
    80003de8:	84470713          	addi	a4,a4,-1980 # 80009628 <states.1844+0x170>
    80003dec:	94ba                	add	s1,s1,a4
    80003dee:	409c                	lw	a5,0(s1)
    80003df0:	97ba                	add	a5,a5,a4
    80003df2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003df4:	655c                	ld	a5,136(a0)
    80003df6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003df8:	60e2                	ld	ra,24(sp)
    80003dfa:	6442                	ld	s0,16(sp)
    80003dfc:	64a2                	ld	s1,8(sp)
    80003dfe:	6105                	addi	sp,sp,32
    80003e00:	8082                	ret
    return p->trapframe->a1;
    80003e02:	655c                	ld	a5,136(a0)
    80003e04:	7fa8                	ld	a0,120(a5)
    80003e06:	bfcd                	j	80003df8 <argraw+0x30>
    return p->trapframe->a2;
    80003e08:	655c                	ld	a5,136(a0)
    80003e0a:	63c8                	ld	a0,128(a5)
    80003e0c:	b7f5                	j	80003df8 <argraw+0x30>
    return p->trapframe->a3;
    80003e0e:	655c                	ld	a5,136(a0)
    80003e10:	67c8                	ld	a0,136(a5)
    80003e12:	b7dd                	j	80003df8 <argraw+0x30>
    return p->trapframe->a4;
    80003e14:	655c                	ld	a5,136(a0)
    80003e16:	6bc8                	ld	a0,144(a5)
    80003e18:	b7c5                	j	80003df8 <argraw+0x30>
    return p->trapframe->a5;
    80003e1a:	655c                	ld	a5,136(a0)
    80003e1c:	6fc8                	ld	a0,152(a5)
    80003e1e:	bfe9                	j	80003df8 <argraw+0x30>
  panic("argraw");
    80003e20:	00005517          	auipc	a0,0x5
    80003e24:	7e050513          	addi	a0,a0,2016 # 80009600 <states.1844+0x148>
    80003e28:	ffffc097          	auipc	ra,0xffffc
    80003e2c:	716080e7          	jalr	1814(ra) # 8000053e <panic>

0000000080003e30 <fetchaddr>:
{
    80003e30:	1101                	addi	sp,sp,-32
    80003e32:	ec06                	sd	ra,24(sp)
    80003e34:	e822                	sd	s0,16(sp)
    80003e36:	e426                	sd	s1,8(sp)
    80003e38:	e04a                	sd	s2,0(sp)
    80003e3a:	1000                	addi	s0,sp,32
    80003e3c:	84aa                	mv	s1,a0
    80003e3e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003e40:	ffffe097          	auipc	ra,0xffffe
    80003e44:	d84080e7          	jalr	-636(ra) # 80001bc4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003e48:	7d3c                	ld	a5,120(a0)
    80003e4a:	02f4f863          	bgeu	s1,a5,80003e7a <fetchaddr+0x4a>
    80003e4e:	00848713          	addi	a4,s1,8
    80003e52:	02e7e663          	bltu	a5,a4,80003e7e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003e56:	46a1                	li	a3,8
    80003e58:	8626                	mv	a2,s1
    80003e5a:	85ca                	mv	a1,s2
    80003e5c:	6148                	ld	a0,128(a0)
    80003e5e:	ffffe097          	auipc	ra,0xffffe
    80003e62:	8a8080e7          	jalr	-1880(ra) # 80001706 <copyin>
    80003e66:	00a03533          	snez	a0,a0
    80003e6a:	40a00533          	neg	a0,a0
}
    80003e6e:	60e2                	ld	ra,24(sp)
    80003e70:	6442                	ld	s0,16(sp)
    80003e72:	64a2                	ld	s1,8(sp)
    80003e74:	6902                	ld	s2,0(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret
    return -1;
    80003e7a:	557d                	li	a0,-1
    80003e7c:	bfcd                	j	80003e6e <fetchaddr+0x3e>
    80003e7e:	557d                	li	a0,-1
    80003e80:	b7fd                	j	80003e6e <fetchaddr+0x3e>

0000000080003e82 <fetchstr>:
{
    80003e82:	7179                	addi	sp,sp,-48
    80003e84:	f406                	sd	ra,40(sp)
    80003e86:	f022                	sd	s0,32(sp)
    80003e88:	ec26                	sd	s1,24(sp)
    80003e8a:	e84a                	sd	s2,16(sp)
    80003e8c:	e44e                	sd	s3,8(sp)
    80003e8e:	1800                	addi	s0,sp,48
    80003e90:	892a                	mv	s2,a0
    80003e92:	84ae                	mv	s1,a1
    80003e94:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003e96:	ffffe097          	auipc	ra,0xffffe
    80003e9a:	d2e080e7          	jalr	-722(ra) # 80001bc4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003e9e:	86ce                	mv	a3,s3
    80003ea0:	864a                	mv	a2,s2
    80003ea2:	85a6                	mv	a1,s1
    80003ea4:	6148                	ld	a0,128(a0)
    80003ea6:	ffffe097          	auipc	ra,0xffffe
    80003eaa:	8ec080e7          	jalr	-1812(ra) # 80001792 <copyinstr>
  if(err < 0)
    80003eae:	00054763          	bltz	a0,80003ebc <fetchstr+0x3a>
  return strlen(buf);
    80003eb2:	8526                	mv	a0,s1
    80003eb4:	ffffd097          	auipc	ra,0xffffd
    80003eb8:	fb0080e7          	jalr	-80(ra) # 80000e64 <strlen>
}
    80003ebc:	70a2                	ld	ra,40(sp)
    80003ebe:	7402                	ld	s0,32(sp)
    80003ec0:	64e2                	ld	s1,24(sp)
    80003ec2:	6942                	ld	s2,16(sp)
    80003ec4:	69a2                	ld	s3,8(sp)
    80003ec6:	6145                	addi	sp,sp,48
    80003ec8:	8082                	ret

0000000080003eca <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003eca:	1101                	addi	sp,sp,-32
    80003ecc:	ec06                	sd	ra,24(sp)
    80003ece:	e822                	sd	s0,16(sp)
    80003ed0:	e426                	sd	s1,8(sp)
    80003ed2:	1000                	addi	s0,sp,32
    80003ed4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	ef2080e7          	jalr	-270(ra) # 80003dc8 <argraw>
    80003ede:	c088                	sw	a0,0(s1)
  return 0;
}
    80003ee0:	4501                	li	a0,0
    80003ee2:	60e2                	ld	ra,24(sp)
    80003ee4:	6442                	ld	s0,16(sp)
    80003ee6:	64a2                	ld	s1,8(sp)
    80003ee8:	6105                	addi	sp,sp,32
    80003eea:	8082                	ret

0000000080003eec <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003eec:	1101                	addi	sp,sp,-32
    80003eee:	ec06                	sd	ra,24(sp)
    80003ef0:	e822                	sd	s0,16(sp)
    80003ef2:	e426                	sd	s1,8(sp)
    80003ef4:	1000                	addi	s0,sp,32
    80003ef6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	ed0080e7          	jalr	-304(ra) # 80003dc8 <argraw>
    80003f00:	e088                	sd	a0,0(s1)
  return 0;
}
    80003f02:	4501                	li	a0,0
    80003f04:	60e2                	ld	ra,24(sp)
    80003f06:	6442                	ld	s0,16(sp)
    80003f08:	64a2                	ld	s1,8(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret

0000000080003f0e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003f0e:	1101                	addi	sp,sp,-32
    80003f10:	ec06                	sd	ra,24(sp)
    80003f12:	e822                	sd	s0,16(sp)
    80003f14:	e426                	sd	s1,8(sp)
    80003f16:	e04a                	sd	s2,0(sp)
    80003f18:	1000                	addi	s0,sp,32
    80003f1a:	84ae                	mv	s1,a1
    80003f1c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	eaa080e7          	jalr	-342(ra) # 80003dc8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003f26:	864a                	mv	a2,s2
    80003f28:	85a6                	mv	a1,s1
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	f58080e7          	jalr	-168(ra) # 80003e82 <fetchstr>
}
    80003f32:	60e2                	ld	ra,24(sp)
    80003f34:	6442                	ld	s0,16(sp)
    80003f36:	64a2                	ld	s1,8(sp)
    80003f38:	6902                	ld	s2,0(sp)
    80003f3a:	6105                	addi	sp,sp,32
    80003f3c:	8082                	ret

0000000080003f3e <syscall>:
[SYS_set_cpu]       sys_set_cpu,
};

void
syscall(void)
{
    80003f3e:	1101                	addi	sp,sp,-32
    80003f40:	ec06                	sd	ra,24(sp)
    80003f42:	e822                	sd	s0,16(sp)
    80003f44:	e426                	sd	s1,8(sp)
    80003f46:	e04a                	sd	s2,0(sp)
    80003f48:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003f4a:	ffffe097          	auipc	ra,0xffffe
    80003f4e:	c7a080e7          	jalr	-902(ra) # 80001bc4 <myproc>
    80003f52:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003f54:	08853903          	ld	s2,136(a0)
    80003f58:	0a893783          	ld	a5,168(s2)
    80003f5c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003f60:	37fd                	addiw	a5,a5,-1
    80003f62:	4765                	li	a4,25
    80003f64:	00f76f63          	bltu	a4,a5,80003f82 <syscall+0x44>
    80003f68:	00369713          	slli	a4,a3,0x3
    80003f6c:	00005797          	auipc	a5,0x5
    80003f70:	6d478793          	addi	a5,a5,1748 # 80009640 <syscalls>
    80003f74:	97ba                	add	a5,a5,a4
    80003f76:	639c                	ld	a5,0(a5)
    80003f78:	c789                	beqz	a5,80003f82 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003f7a:	9782                	jalr	a5
    80003f7c:	06a93823          	sd	a0,112(s2)
    80003f80:	a839                	j	80003f9e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003f82:	18848613          	addi	a2,s1,392
    80003f86:	588c                	lw	a1,48(s1)
    80003f88:	00005517          	auipc	a0,0x5
    80003f8c:	68050513          	addi	a0,a0,1664 # 80009608 <states.1844+0x150>
    80003f90:	ffffc097          	auipc	ra,0xffffc
    80003f94:	5f8080e7          	jalr	1528(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003f98:	64dc                	ld	a5,136(s1)
    80003f9a:	577d                	li	a4,-1
    80003f9c:	fbb8                	sd	a4,112(a5)
  }
}
    80003f9e:	60e2                	ld	ra,24(sp)
    80003fa0:	6442                	ld	s0,16(sp)
    80003fa2:	64a2                	ld	s1,8(sp)
    80003fa4:	6902                	ld	s2,0(sp)
    80003fa6:	6105                	addi	sp,sp,32
    80003fa8:	8082                	ret

0000000080003faa <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003faa:	1101                	addi	sp,sp,-32
    80003fac:	ec06                	sd	ra,24(sp)
    80003fae:	e822                	sd	s0,16(sp)
    80003fb0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003fb2:	fec40593          	addi	a1,s0,-20
    80003fb6:	4501                	li	a0,0
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	f12080e7          	jalr	-238(ra) # 80003eca <argint>
    return -1;
    80003fc0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003fc2:	00054963          	bltz	a0,80003fd4 <sys_exit+0x2a>
  exit(n);
    80003fc6:	fec42503          	lw	a0,-20(s0)
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	180080e7          	jalr	384(ra) # 8000314a <exit>
  return 0;  // not reached
    80003fd2:	4781                	li	a5,0
}
    80003fd4:	853e                	mv	a0,a5
    80003fd6:	60e2                	ld	ra,24(sp)
    80003fd8:	6442                	ld	s0,16(sp)
    80003fda:	6105                	addi	sp,sp,32
    80003fdc:	8082                	ret

0000000080003fde <sys_getpid>:

uint64
sys_getpid(void)
{
    80003fde:	1141                	addi	sp,sp,-16
    80003fe0:	e406                	sd	ra,8(sp)
    80003fe2:	e022                	sd	s0,0(sp)
    80003fe4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003fe6:	ffffe097          	auipc	ra,0xffffe
    80003fea:	bde080e7          	jalr	-1058(ra) # 80001bc4 <myproc>
}
    80003fee:	5908                	lw	a0,48(a0)
    80003ff0:	60a2                	ld	ra,8(sp)
    80003ff2:	6402                	ld	s0,0(sp)
    80003ff4:	0141                	addi	sp,sp,16
    80003ff6:	8082                	ret

0000000080003ff8 <sys_fork>:

uint64
sys_fork(void)
{
    80003ff8:	1141                	addi	sp,sp,-16
    80003ffa:	e406                	sd	ra,8(sp)
    80003ffc:	e022                	sd	s0,0(sp)
    80003ffe:	0800                	addi	s0,sp,16
  return fork();
    80004000:	ffffe097          	auipc	ra,0xffffe
    80004004:	296080e7          	jalr	662(ra) # 80002296 <fork>
}
    80004008:	60a2                	ld	ra,8(sp)
    8000400a:	6402                	ld	s0,0(sp)
    8000400c:	0141                	addi	sp,sp,16
    8000400e:	8082                	ret

0000000080004010 <sys_wait>:

uint64
sys_wait(void)
{
    80004010:	1101                	addi	sp,sp,-32
    80004012:	ec06                	sd	ra,24(sp)
    80004014:	e822                	sd	s0,16(sp)
    80004016:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80004018:	fe840593          	addi	a1,s0,-24
    8000401c:	4501                	li	a0,0
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	ece080e7          	jalr	-306(ra) # 80003eec <argaddr>
    80004026:	87aa                	mv	a5,a0
    return -1;
    80004028:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000402a:	0007c863          	bltz	a5,8000403a <sys_wait+0x2a>
  return wait(p);
    8000402e:	fe843503          	ld	a0,-24(s0)
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	d8e080e7          	jalr	-626(ra) # 80002dc0 <wait>
}
    8000403a:	60e2                	ld	ra,24(sp)
    8000403c:	6442                	ld	s0,16(sp)
    8000403e:	6105                	addi	sp,sp,32
    80004040:	8082                	ret

0000000080004042 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80004042:	7179                	addi	sp,sp,-48
    80004044:	f406                	sd	ra,40(sp)
    80004046:	f022                	sd	s0,32(sp)
    80004048:	ec26                	sd	s1,24(sp)
    8000404a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000404c:	fdc40593          	addi	a1,s0,-36
    80004050:	4501                	li	a0,0
    80004052:	00000097          	auipc	ra,0x0
    80004056:	e78080e7          	jalr	-392(ra) # 80003eca <argint>
    8000405a:	87aa                	mv	a5,a0
    return -1;
    8000405c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000405e:	0207c063          	bltz	a5,8000407e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80004062:	ffffe097          	auipc	ra,0xffffe
    80004066:	b62080e7          	jalr	-1182(ra) # 80001bc4 <myproc>
    8000406a:	5d24                	lw	s1,120(a0)
  if(growproc(n) < 0)
    8000406c:	fdc42503          	lw	a0,-36(s0)
    80004070:	ffffe097          	auipc	ra,0xffffe
    80004074:	1b2080e7          	jalr	434(ra) # 80002222 <growproc>
    80004078:	00054863          	bltz	a0,80004088 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000407c:	8526                	mv	a0,s1
}
    8000407e:	70a2                	ld	ra,40(sp)
    80004080:	7402                	ld	s0,32(sp)
    80004082:	64e2                	ld	s1,24(sp)
    80004084:	6145                	addi	sp,sp,48
    80004086:	8082                	ret
    return -1;
    80004088:	557d                	li	a0,-1
    8000408a:	bfd5                	j	8000407e <sys_sbrk+0x3c>

000000008000408c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000408c:	7139                	addi	sp,sp,-64
    8000408e:	fc06                	sd	ra,56(sp)
    80004090:	f822                	sd	s0,48(sp)
    80004092:	f426                	sd	s1,40(sp)
    80004094:	f04a                	sd	s2,32(sp)
    80004096:	ec4e                	sd	s3,24(sp)
    80004098:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000409a:	fcc40593          	addi	a1,s0,-52
    8000409e:	4501                	li	a0,0
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	e2a080e7          	jalr	-470(ra) # 80003eca <argint>
    return -1;
    800040a8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800040aa:	06054563          	bltz	a0,80004114 <sys_sleep+0x88>
  acquire(&tickslock);
    800040ae:	00015517          	auipc	a0,0x15
    800040b2:	cc250513          	addi	a0,a0,-830 # 80018d70 <tickslock>
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	b2e080e7          	jalr	-1234(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800040be:	00006917          	auipc	s2,0x6
    800040c2:	f9692903          	lw	s2,-106(s2) # 8000a054 <ticks>
  
  while(ticks - ticks0 < n){
    800040c6:	fcc42783          	lw	a5,-52(s0)
    800040ca:	cf85                	beqz	a5,80004102 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800040cc:	00015997          	auipc	s3,0x15
    800040d0:	ca498993          	addi	s3,s3,-860 # 80018d70 <tickslock>
    800040d4:	00006497          	auipc	s1,0x6
    800040d8:	f8048493          	addi	s1,s1,-128 # 8000a054 <ticks>
    if(myproc()->killed){
    800040dc:	ffffe097          	auipc	ra,0xffffe
    800040e0:	ae8080e7          	jalr	-1304(ra) # 80001bc4 <myproc>
    800040e4:	551c                	lw	a5,40(a0)
    800040e6:	ef9d                	bnez	a5,80004124 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800040e8:	85ce                	mv	a1,s3
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	af8080e7          	jalr	-1288(ra) # 80002be4 <sleep>
  while(ticks - ticks0 < n){
    800040f4:	409c                	lw	a5,0(s1)
    800040f6:	412787bb          	subw	a5,a5,s2
    800040fa:	fcc42703          	lw	a4,-52(s0)
    800040fe:	fce7efe3          	bltu	a5,a4,800040dc <sys_sleep+0x50>
  }
  release(&tickslock);
    80004102:	00015517          	auipc	a0,0x15
    80004106:	c6e50513          	addi	a0,a0,-914 # 80018d70 <tickslock>
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	b8e080e7          	jalr	-1138(ra) # 80000c98 <release>
  return 0;
    80004112:	4781                	li	a5,0
}
    80004114:	853e                	mv	a0,a5
    80004116:	70e2                	ld	ra,56(sp)
    80004118:	7442                	ld	s0,48(sp)
    8000411a:	74a2                	ld	s1,40(sp)
    8000411c:	7902                	ld	s2,32(sp)
    8000411e:	69e2                	ld	s3,24(sp)
    80004120:	6121                	addi	sp,sp,64
    80004122:	8082                	ret
      release(&tickslock);
    80004124:	00015517          	auipc	a0,0x15
    80004128:	c4c50513          	addi	a0,a0,-948 # 80018d70 <tickslock>
    8000412c:	ffffd097          	auipc	ra,0xffffd
    80004130:	b6c080e7          	jalr	-1172(ra) # 80000c98 <release>
      return -1;
    80004134:	57fd                	li	a5,-1
    80004136:	bff9                	j	80004114 <sys_sleep+0x88>

0000000080004138 <sys_kill>:

uint64
sys_kill(void)
{
    80004138:	1101                	addi	sp,sp,-32
    8000413a:	ec06                	sd	ra,24(sp)
    8000413c:	e822                	sd	s0,16(sp)
    8000413e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80004140:	fec40593          	addi	a1,s0,-20
    80004144:	4501                	li	a0,0
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	d84080e7          	jalr	-636(ra) # 80003eca <argint>
    8000414e:	87aa                	mv	a5,a0
    return -1;
    80004150:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80004152:	0007c863          	bltz	a5,80004162 <sys_kill+0x2a>
  return kill(pid);
    80004156:	fec42503          	lw	a0,-20(s0)
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	2f4080e7          	jalr	756(ra) # 8000344e <kill>
}
    80004162:	60e2                	ld	ra,24(sp)
    80004164:	6442                	ld	s0,16(sp)
    80004166:	6105                	addi	sp,sp,32
    80004168:	8082                	ret

000000008000416a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000416a:	1101                	addi	sp,sp,-32
    8000416c:	ec06                	sd	ra,24(sp)
    8000416e:	e822                	sd	s0,16(sp)
    80004170:	e426                	sd	s1,8(sp)
    80004172:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80004174:	00015517          	auipc	a0,0x15
    80004178:	bfc50513          	addi	a0,a0,-1028 # 80018d70 <tickslock>
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	a68080e7          	jalr	-1432(ra) # 80000be4 <acquire>
  xticks = ticks;
    80004184:	00006497          	auipc	s1,0x6
    80004188:	ed04a483          	lw	s1,-304(s1) # 8000a054 <ticks>
  release(&tickslock);
    8000418c:	00015517          	auipc	a0,0x15
    80004190:	be450513          	addi	a0,a0,-1052 # 80018d70 <tickslock>
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	b04080e7          	jalr	-1276(ra) # 80000c98 <release>
  return xticks;
}
    8000419c:	02049513          	slli	a0,s1,0x20
    800041a0:	9101                	srli	a0,a0,0x20
    800041a2:	60e2                	ld	ra,24(sp)
    800041a4:	6442                	ld	s0,16(sp)
    800041a6:	64a2                	ld	s1,8(sp)
    800041a8:	6105                	addi	sp,sp,32
    800041aa:	8082                	ret

00000000800041ac <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800041ac:	1141                	addi	sp,sp,-16
    800041ae:	e406                	sd	ra,8(sp)
    800041b0:	e022                	sd	s0,0(sp)
    800041b2:	0800                	addi	s0,sp,16
  return print_stats();
    800041b4:	fffff097          	auipc	ra,0xfffff
    800041b8:	320080e7          	jalr	800(ra) # 800034d4 <print_stats>
}
    800041bc:	60a2                	ld	ra,8(sp)
    800041be:	6402                	ld	s0,0(sp)
    800041c0:	0141                	addi	sp,sp,16
    800041c2:	8082                	ret

00000000800041c4 <sys_get_cpu>:

// Ass2
uint64
sys_get_cpu(void)
{
    800041c4:	1141                	addi	sp,sp,-16
    800041c6:	e406                	sd	ra,8(sp)
    800041c8:	e022                	sd	s0,0(sp)
    800041ca:	0800                	addi	s0,sp,16
  return get_cpu();
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	46a080e7          	jalr	1130(ra) # 80003636 <get_cpu>
}
    800041d4:	60a2                	ld	ra,8(sp)
    800041d6:	6402                	ld	s0,0(sp)
    800041d8:	0141                	addi	sp,sp,16
    800041da:	8082                	ret

00000000800041dc <sys_set_cpu>:

// Ass2
uint64
sys_set_cpu(void)
{
    800041dc:	1101                	addi	sp,sp,-32
    800041de:	ec06                	sd	ra,24(sp)
    800041e0:	e822                	sd	s0,16(sp)
    800041e2:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    800041e4:	fec40593          	addi	a1,s0,-20
    800041e8:	4501                	li	a0,0
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	ce0080e7          	jalr	-800(ra) # 80003eca <argint>
    800041f2:	87aa                	mv	a5,a0
    return -1;
    800041f4:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800041f6:	0007c863          	bltz	a5,80004206 <sys_set_cpu+0x2a>

  return set_cpu(cpu_num);
    800041fa:	fec42503          	lw	a0,-20(s0)
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	378080e7          	jalr	888(ra) # 80003576 <set_cpu>
}
    80004206:	60e2                	ld	ra,24(sp)
    80004208:	6442                	ld	s0,16(sp)
    8000420a:	6105                	addi	sp,sp,32
    8000420c:	8082                	ret

000000008000420e <sys_pause_system>:



uint64
sys_pause_system(void)
{
    8000420e:	1101                	addi	sp,sp,-32
    80004210:	ec06                	sd	ra,24(sp)
    80004212:	e822                	sd	s0,16(sp)
    80004214:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80004216:	fec40593          	addi	a1,s0,-20
    8000421a:	4501                	li	a0,0
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	cae080e7          	jalr	-850(ra) # 80003eca <argint>
    80004224:	87aa                	mv	a5,a0
    return -1;
    80004226:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80004228:	0007c863          	bltz	a5,80004238 <sys_pause_system+0x2a>

  return pause_system(seconds);
    8000422c:	fec42503          	lw	a0,-20(s0)
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	416080e7          	jalr	1046(ra) # 80003646 <pause_system>
}
    80004238:	60e2                	ld	ra,24(sp)
    8000423a:	6442                	ld	s0,16(sp)
    8000423c:	6105                	addi	sp,sp,32
    8000423e:	8082                	ret

0000000080004240 <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80004240:	1141                	addi	sp,sp,-16
    80004242:	e406                	sd	ra,8(sp)
    80004244:	e022                	sd	s0,0(sp)
    80004246:	0800                	addi	s0,sp,16
  return kill_system(); 
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	55e080e7          	jalr	1374(ra) # 800037a6 <kill_system>
}
    80004250:	60a2                	ld	ra,8(sp)
    80004252:	6402                	ld	s0,0(sp)
    80004254:	0141                	addi	sp,sp,16
    80004256:	8082                	ret

0000000080004258 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80004258:	7179                	addi	sp,sp,-48
    8000425a:	f406                	sd	ra,40(sp)
    8000425c:	f022                	sd	s0,32(sp)
    8000425e:	ec26                	sd	s1,24(sp)
    80004260:	e84a                	sd	s2,16(sp)
    80004262:	e44e                	sd	s3,8(sp)
    80004264:	e052                	sd	s4,0(sp)
    80004266:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80004268:	00005597          	auipc	a1,0x5
    8000426c:	4b058593          	addi	a1,a1,1200 # 80009718 <syscalls+0xd8>
    80004270:	00015517          	auipc	a0,0x15
    80004274:	b1850513          	addi	a0,a0,-1256 # 80018d88 <bcache>
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	8dc080e7          	jalr	-1828(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80004280:	0001d797          	auipc	a5,0x1d
    80004284:	b0878793          	addi	a5,a5,-1272 # 80020d88 <bcache+0x8000>
    80004288:	0001d717          	auipc	a4,0x1d
    8000428c:	d6870713          	addi	a4,a4,-664 # 80020ff0 <bcache+0x8268>
    80004290:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80004294:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80004298:	00015497          	auipc	s1,0x15
    8000429c:	b0848493          	addi	s1,s1,-1272 # 80018da0 <bcache+0x18>
    b->next = bcache.head.next;
    800042a0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800042a2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800042a4:	00005a17          	auipc	s4,0x5
    800042a8:	47ca0a13          	addi	s4,s4,1148 # 80009720 <syscalls+0xe0>
    b->next = bcache.head.next;
    800042ac:	2b893783          	ld	a5,696(s2)
    800042b0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800042b2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800042b6:	85d2                	mv	a1,s4
    800042b8:	01048513          	addi	a0,s1,16
    800042bc:	00001097          	auipc	ra,0x1
    800042c0:	4bc080e7          	jalr	1212(ra) # 80005778 <initsleeplock>
    bcache.head.next->prev = b;
    800042c4:	2b893783          	ld	a5,696(s2)
    800042c8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800042ca:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800042ce:	45848493          	addi	s1,s1,1112
    800042d2:	fd349de3          	bne	s1,s3,800042ac <binit+0x54>
  }
}
    800042d6:	70a2                	ld	ra,40(sp)
    800042d8:	7402                	ld	s0,32(sp)
    800042da:	64e2                	ld	s1,24(sp)
    800042dc:	6942                	ld	s2,16(sp)
    800042de:	69a2                	ld	s3,8(sp)
    800042e0:	6a02                	ld	s4,0(sp)
    800042e2:	6145                	addi	sp,sp,48
    800042e4:	8082                	ret

00000000800042e6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800042e6:	7179                	addi	sp,sp,-48
    800042e8:	f406                	sd	ra,40(sp)
    800042ea:	f022                	sd	s0,32(sp)
    800042ec:	ec26                	sd	s1,24(sp)
    800042ee:	e84a                	sd	s2,16(sp)
    800042f0:	e44e                	sd	s3,8(sp)
    800042f2:	1800                	addi	s0,sp,48
    800042f4:	89aa                	mv	s3,a0
    800042f6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800042f8:	00015517          	auipc	a0,0x15
    800042fc:	a9050513          	addi	a0,a0,-1392 # 80018d88 <bcache>
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	8e4080e7          	jalr	-1820(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80004308:	0001d497          	auipc	s1,0x1d
    8000430c:	d384b483          	ld	s1,-712(s1) # 80021040 <bcache+0x82b8>
    80004310:	0001d797          	auipc	a5,0x1d
    80004314:	ce078793          	addi	a5,a5,-800 # 80020ff0 <bcache+0x8268>
    80004318:	02f48f63          	beq	s1,a5,80004356 <bread+0x70>
    8000431c:	873e                	mv	a4,a5
    8000431e:	a021                	j	80004326 <bread+0x40>
    80004320:	68a4                	ld	s1,80(s1)
    80004322:	02e48a63          	beq	s1,a4,80004356 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80004326:	449c                	lw	a5,8(s1)
    80004328:	ff379ce3          	bne	a5,s3,80004320 <bread+0x3a>
    8000432c:	44dc                	lw	a5,12(s1)
    8000432e:	ff2799e3          	bne	a5,s2,80004320 <bread+0x3a>
      b->refcnt++;
    80004332:	40bc                	lw	a5,64(s1)
    80004334:	2785                	addiw	a5,a5,1
    80004336:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80004338:	00015517          	auipc	a0,0x15
    8000433c:	a5050513          	addi	a0,a0,-1456 # 80018d88 <bcache>
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	958080e7          	jalr	-1704(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80004348:	01048513          	addi	a0,s1,16
    8000434c:	00001097          	auipc	ra,0x1
    80004350:	466080e7          	jalr	1126(ra) # 800057b2 <acquiresleep>
      return b;
    80004354:	a8b9                	j	800043b2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80004356:	0001d497          	auipc	s1,0x1d
    8000435a:	ce24b483          	ld	s1,-798(s1) # 80021038 <bcache+0x82b0>
    8000435e:	0001d797          	auipc	a5,0x1d
    80004362:	c9278793          	addi	a5,a5,-878 # 80020ff0 <bcache+0x8268>
    80004366:	00f48863          	beq	s1,a5,80004376 <bread+0x90>
    8000436a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000436c:	40bc                	lw	a5,64(s1)
    8000436e:	cf81                	beqz	a5,80004386 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80004370:	64a4                	ld	s1,72(s1)
    80004372:	fee49de3          	bne	s1,a4,8000436c <bread+0x86>
  panic("bget: no buffers");
    80004376:	00005517          	auipc	a0,0x5
    8000437a:	3b250513          	addi	a0,a0,946 # 80009728 <syscalls+0xe8>
    8000437e:	ffffc097          	auipc	ra,0xffffc
    80004382:	1c0080e7          	jalr	448(ra) # 8000053e <panic>
      b->dev = dev;
    80004386:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000438a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000438e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80004392:	4785                	li	a5,1
    80004394:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80004396:	00015517          	auipc	a0,0x15
    8000439a:	9f250513          	addi	a0,a0,-1550 # 80018d88 <bcache>
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	8fa080e7          	jalr	-1798(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800043a6:	01048513          	addi	a0,s1,16
    800043aa:	00001097          	auipc	ra,0x1
    800043ae:	408080e7          	jalr	1032(ra) # 800057b2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800043b2:	409c                	lw	a5,0(s1)
    800043b4:	cb89                	beqz	a5,800043c6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800043b6:	8526                	mv	a0,s1
    800043b8:	70a2                	ld	ra,40(sp)
    800043ba:	7402                	ld	s0,32(sp)
    800043bc:	64e2                	ld	s1,24(sp)
    800043be:	6942                	ld	s2,16(sp)
    800043c0:	69a2                	ld	s3,8(sp)
    800043c2:	6145                	addi	sp,sp,48
    800043c4:	8082                	ret
    virtio_disk_rw(b, 0);
    800043c6:	4581                	li	a1,0
    800043c8:	8526                	mv	a0,s1
    800043ca:	00003097          	auipc	ra,0x3
    800043ce:	f0c080e7          	jalr	-244(ra) # 800072d6 <virtio_disk_rw>
    b->valid = 1;
    800043d2:	4785                	li	a5,1
    800043d4:	c09c                	sw	a5,0(s1)
  return b;
    800043d6:	b7c5                	j	800043b6 <bread+0xd0>

00000000800043d8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800043d8:	1101                	addi	sp,sp,-32
    800043da:	ec06                	sd	ra,24(sp)
    800043dc:	e822                	sd	s0,16(sp)
    800043de:	e426                	sd	s1,8(sp)
    800043e0:	1000                	addi	s0,sp,32
    800043e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800043e4:	0541                	addi	a0,a0,16
    800043e6:	00001097          	auipc	ra,0x1
    800043ea:	466080e7          	jalr	1126(ra) # 8000584c <holdingsleep>
    800043ee:	cd01                	beqz	a0,80004406 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800043f0:	4585                	li	a1,1
    800043f2:	8526                	mv	a0,s1
    800043f4:	00003097          	auipc	ra,0x3
    800043f8:	ee2080e7          	jalr	-286(ra) # 800072d6 <virtio_disk_rw>
}
    800043fc:	60e2                	ld	ra,24(sp)
    800043fe:	6442                	ld	s0,16(sp)
    80004400:	64a2                	ld	s1,8(sp)
    80004402:	6105                	addi	sp,sp,32
    80004404:	8082                	ret
    panic("bwrite");
    80004406:	00005517          	auipc	a0,0x5
    8000440a:	33a50513          	addi	a0,a0,826 # 80009740 <syscalls+0x100>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	130080e7          	jalr	304(ra) # 8000053e <panic>

0000000080004416 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80004416:	1101                	addi	sp,sp,-32
    80004418:	ec06                	sd	ra,24(sp)
    8000441a:	e822                	sd	s0,16(sp)
    8000441c:	e426                	sd	s1,8(sp)
    8000441e:	e04a                	sd	s2,0(sp)
    80004420:	1000                	addi	s0,sp,32
    80004422:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004424:	01050913          	addi	s2,a0,16
    80004428:	854a                	mv	a0,s2
    8000442a:	00001097          	auipc	ra,0x1
    8000442e:	422080e7          	jalr	1058(ra) # 8000584c <holdingsleep>
    80004432:	c92d                	beqz	a0,800044a4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80004434:	854a                	mv	a0,s2
    80004436:	00001097          	auipc	ra,0x1
    8000443a:	3d2080e7          	jalr	978(ra) # 80005808 <releasesleep>

  acquire(&bcache.lock);
    8000443e:	00015517          	auipc	a0,0x15
    80004442:	94a50513          	addi	a0,a0,-1718 # 80018d88 <bcache>
    80004446:	ffffc097          	auipc	ra,0xffffc
    8000444a:	79e080e7          	jalr	1950(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000444e:	40bc                	lw	a5,64(s1)
    80004450:	37fd                	addiw	a5,a5,-1
    80004452:	0007871b          	sext.w	a4,a5
    80004456:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80004458:	eb05                	bnez	a4,80004488 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000445a:	68bc                	ld	a5,80(s1)
    8000445c:	64b8                	ld	a4,72(s1)
    8000445e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80004460:	64bc                	ld	a5,72(s1)
    80004462:	68b8                	ld	a4,80(s1)
    80004464:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80004466:	0001d797          	auipc	a5,0x1d
    8000446a:	92278793          	addi	a5,a5,-1758 # 80020d88 <bcache+0x8000>
    8000446e:	2b87b703          	ld	a4,696(a5)
    80004472:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80004474:	0001d717          	auipc	a4,0x1d
    80004478:	b7c70713          	addi	a4,a4,-1156 # 80020ff0 <bcache+0x8268>
    8000447c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000447e:	2b87b703          	ld	a4,696(a5)
    80004482:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80004484:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80004488:	00015517          	auipc	a0,0x15
    8000448c:	90050513          	addi	a0,a0,-1792 # 80018d88 <bcache>
    80004490:	ffffd097          	auipc	ra,0xffffd
    80004494:	808080e7          	jalr	-2040(ra) # 80000c98 <release>
}
    80004498:	60e2                	ld	ra,24(sp)
    8000449a:	6442                	ld	s0,16(sp)
    8000449c:	64a2                	ld	s1,8(sp)
    8000449e:	6902                	ld	s2,0(sp)
    800044a0:	6105                	addi	sp,sp,32
    800044a2:	8082                	ret
    panic("brelse");
    800044a4:	00005517          	auipc	a0,0x5
    800044a8:	2a450513          	addi	a0,a0,676 # 80009748 <syscalls+0x108>
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	092080e7          	jalr	146(ra) # 8000053e <panic>

00000000800044b4 <bpin>:

void
bpin(struct buf *b) {
    800044b4:	1101                	addi	sp,sp,-32
    800044b6:	ec06                	sd	ra,24(sp)
    800044b8:	e822                	sd	s0,16(sp)
    800044ba:	e426                	sd	s1,8(sp)
    800044bc:	1000                	addi	s0,sp,32
    800044be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800044c0:	00015517          	auipc	a0,0x15
    800044c4:	8c850513          	addi	a0,a0,-1848 # 80018d88 <bcache>
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	71c080e7          	jalr	1820(ra) # 80000be4 <acquire>
  b->refcnt++;
    800044d0:	40bc                	lw	a5,64(s1)
    800044d2:	2785                	addiw	a5,a5,1
    800044d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800044d6:	00015517          	auipc	a0,0x15
    800044da:	8b250513          	addi	a0,a0,-1870 # 80018d88 <bcache>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	7ba080e7          	jalr	1978(ra) # 80000c98 <release>
}
    800044e6:	60e2                	ld	ra,24(sp)
    800044e8:	6442                	ld	s0,16(sp)
    800044ea:	64a2                	ld	s1,8(sp)
    800044ec:	6105                	addi	sp,sp,32
    800044ee:	8082                	ret

00000000800044f0 <bunpin>:

void
bunpin(struct buf *b) {
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
  b->refcnt--;
    8000450c:	40bc                	lw	a5,64(s1)
    8000450e:	37fd                	addiw	a5,a5,-1
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

000000008000452c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000452c:	1101                	addi	sp,sp,-32
    8000452e:	ec06                	sd	ra,24(sp)
    80004530:	e822                	sd	s0,16(sp)
    80004532:	e426                	sd	s1,8(sp)
    80004534:	e04a                	sd	s2,0(sp)
    80004536:	1000                	addi	s0,sp,32
    80004538:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000453a:	00d5d59b          	srliw	a1,a1,0xd
    8000453e:	0001d797          	auipc	a5,0x1d
    80004542:	f267a783          	lw	a5,-218(a5) # 80021464 <sb+0x1c>
    80004546:	9dbd                	addw	a1,a1,a5
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	d9e080e7          	jalr	-610(ra) # 800042e6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80004550:	0074f713          	andi	a4,s1,7
    80004554:	4785                	li	a5,1
    80004556:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000455a:	14ce                	slli	s1,s1,0x33
    8000455c:	90d9                	srli	s1,s1,0x36
    8000455e:	00950733          	add	a4,a0,s1
    80004562:	05874703          	lbu	a4,88(a4)
    80004566:	00e7f6b3          	and	a3,a5,a4
    8000456a:	c69d                	beqz	a3,80004598 <bfree+0x6c>
    8000456c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000456e:	94aa                	add	s1,s1,a0
    80004570:	fff7c793          	not	a5,a5
    80004574:	8ff9                	and	a5,a5,a4
    80004576:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000457a:	00001097          	auipc	ra,0x1
    8000457e:	118080e7          	jalr	280(ra) # 80005692 <log_write>
  brelse(bp);
    80004582:	854a                	mv	a0,s2
    80004584:	00000097          	auipc	ra,0x0
    80004588:	e92080e7          	jalr	-366(ra) # 80004416 <brelse>
}
    8000458c:	60e2                	ld	ra,24(sp)
    8000458e:	6442                	ld	s0,16(sp)
    80004590:	64a2                	ld	s1,8(sp)
    80004592:	6902                	ld	s2,0(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret
    panic("freeing free block");
    80004598:	00005517          	auipc	a0,0x5
    8000459c:	1b850513          	addi	a0,a0,440 # 80009750 <syscalls+0x110>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	f9e080e7          	jalr	-98(ra) # 8000053e <panic>

00000000800045a8 <balloc>:
{
    800045a8:	711d                	addi	sp,sp,-96
    800045aa:	ec86                	sd	ra,88(sp)
    800045ac:	e8a2                	sd	s0,80(sp)
    800045ae:	e4a6                	sd	s1,72(sp)
    800045b0:	e0ca                	sd	s2,64(sp)
    800045b2:	fc4e                	sd	s3,56(sp)
    800045b4:	f852                	sd	s4,48(sp)
    800045b6:	f456                	sd	s5,40(sp)
    800045b8:	f05a                	sd	s6,32(sp)
    800045ba:	ec5e                	sd	s7,24(sp)
    800045bc:	e862                	sd	s8,16(sp)
    800045be:	e466                	sd	s9,8(sp)
    800045c0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800045c2:	0001d797          	auipc	a5,0x1d
    800045c6:	e8a7a783          	lw	a5,-374(a5) # 8002144c <sb+0x4>
    800045ca:	cbd1                	beqz	a5,8000465e <balloc+0xb6>
    800045cc:	8baa                	mv	s7,a0
    800045ce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800045d0:	0001db17          	auipc	s6,0x1d
    800045d4:	e78b0b13          	addi	s6,s6,-392 # 80021448 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800045d8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800045da:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800045dc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800045de:	6c89                	lui	s9,0x2
    800045e0:	a831                	j	800045fc <balloc+0x54>
    brelse(bp);
    800045e2:	854a                	mv	a0,s2
    800045e4:	00000097          	auipc	ra,0x0
    800045e8:	e32080e7          	jalr	-462(ra) # 80004416 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800045ec:	015c87bb          	addw	a5,s9,s5
    800045f0:	00078a9b          	sext.w	s5,a5
    800045f4:	004b2703          	lw	a4,4(s6)
    800045f8:	06eaf363          	bgeu	s5,a4,8000465e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800045fc:	41fad79b          	sraiw	a5,s5,0x1f
    80004600:	0137d79b          	srliw	a5,a5,0x13
    80004604:	015787bb          	addw	a5,a5,s5
    80004608:	40d7d79b          	sraiw	a5,a5,0xd
    8000460c:	01cb2583          	lw	a1,28(s6)
    80004610:	9dbd                	addw	a1,a1,a5
    80004612:	855e                	mv	a0,s7
    80004614:	00000097          	auipc	ra,0x0
    80004618:	cd2080e7          	jalr	-814(ra) # 800042e6 <bread>
    8000461c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000461e:	004b2503          	lw	a0,4(s6)
    80004622:	000a849b          	sext.w	s1,s5
    80004626:	8662                	mv	a2,s8
    80004628:	faa4fde3          	bgeu	s1,a0,800045e2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000462c:	41f6579b          	sraiw	a5,a2,0x1f
    80004630:	01d7d69b          	srliw	a3,a5,0x1d
    80004634:	00c6873b          	addw	a4,a3,a2
    80004638:	00777793          	andi	a5,a4,7
    8000463c:	9f95                	subw	a5,a5,a3
    8000463e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004642:	4037571b          	sraiw	a4,a4,0x3
    80004646:	00e906b3          	add	a3,s2,a4
    8000464a:	0586c683          	lbu	a3,88(a3)
    8000464e:	00d7f5b3          	and	a1,a5,a3
    80004652:	cd91                	beqz	a1,8000466e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004654:	2605                	addiw	a2,a2,1
    80004656:	2485                	addiw	s1,s1,1
    80004658:	fd4618e3          	bne	a2,s4,80004628 <balloc+0x80>
    8000465c:	b759                	j	800045e2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000465e:	00005517          	auipc	a0,0x5
    80004662:	10a50513          	addi	a0,a0,266 # 80009768 <syscalls+0x128>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	ed8080e7          	jalr	-296(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000466e:	974a                	add	a4,a4,s2
    80004670:	8fd5                	or	a5,a5,a3
    80004672:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80004676:	854a                	mv	a0,s2
    80004678:	00001097          	auipc	ra,0x1
    8000467c:	01a080e7          	jalr	26(ra) # 80005692 <log_write>
        brelse(bp);
    80004680:	854a                	mv	a0,s2
    80004682:	00000097          	auipc	ra,0x0
    80004686:	d94080e7          	jalr	-620(ra) # 80004416 <brelse>
  bp = bread(dev, bno);
    8000468a:	85a6                	mv	a1,s1
    8000468c:	855e                	mv	a0,s7
    8000468e:	00000097          	auipc	ra,0x0
    80004692:	c58080e7          	jalr	-936(ra) # 800042e6 <bread>
    80004696:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80004698:	40000613          	li	a2,1024
    8000469c:	4581                	li	a1,0
    8000469e:	05850513          	addi	a0,a0,88
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	63e080e7          	jalr	1598(ra) # 80000ce0 <memset>
  log_write(bp);
    800046aa:	854a                	mv	a0,s2
    800046ac:	00001097          	auipc	ra,0x1
    800046b0:	fe6080e7          	jalr	-26(ra) # 80005692 <log_write>
  brelse(bp);
    800046b4:	854a                	mv	a0,s2
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	d60080e7          	jalr	-672(ra) # 80004416 <brelse>
}
    800046be:	8526                	mv	a0,s1
    800046c0:	60e6                	ld	ra,88(sp)
    800046c2:	6446                	ld	s0,80(sp)
    800046c4:	64a6                	ld	s1,72(sp)
    800046c6:	6906                	ld	s2,64(sp)
    800046c8:	79e2                	ld	s3,56(sp)
    800046ca:	7a42                	ld	s4,48(sp)
    800046cc:	7aa2                	ld	s5,40(sp)
    800046ce:	7b02                	ld	s6,32(sp)
    800046d0:	6be2                	ld	s7,24(sp)
    800046d2:	6c42                	ld	s8,16(sp)
    800046d4:	6ca2                	ld	s9,8(sp)
    800046d6:	6125                	addi	sp,sp,96
    800046d8:	8082                	ret

00000000800046da <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800046da:	7179                	addi	sp,sp,-48
    800046dc:	f406                	sd	ra,40(sp)
    800046de:	f022                	sd	s0,32(sp)
    800046e0:	ec26                	sd	s1,24(sp)
    800046e2:	e84a                	sd	s2,16(sp)
    800046e4:	e44e                	sd	s3,8(sp)
    800046e6:	e052                	sd	s4,0(sp)
    800046e8:	1800                	addi	s0,sp,48
    800046ea:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800046ec:	47ad                	li	a5,11
    800046ee:	04b7fe63          	bgeu	a5,a1,8000474a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800046f2:	ff45849b          	addiw	s1,a1,-12
    800046f6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800046fa:	0ff00793          	li	a5,255
    800046fe:	0ae7e363          	bltu	a5,a4,800047a4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80004702:	08052583          	lw	a1,128(a0)
    80004706:	c5ad                	beqz	a1,80004770 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80004708:	00092503          	lw	a0,0(s2)
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	bda080e7          	jalr	-1062(ra) # 800042e6 <bread>
    80004714:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004716:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000471a:	02049593          	slli	a1,s1,0x20
    8000471e:	9181                	srli	a1,a1,0x20
    80004720:	058a                	slli	a1,a1,0x2
    80004722:	00b784b3          	add	s1,a5,a1
    80004726:	0004a983          	lw	s3,0(s1)
    8000472a:	04098d63          	beqz	s3,80004784 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000472e:	8552                	mv	a0,s4
    80004730:	00000097          	auipc	ra,0x0
    80004734:	ce6080e7          	jalr	-794(ra) # 80004416 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004738:	854e                	mv	a0,s3
    8000473a:	70a2                	ld	ra,40(sp)
    8000473c:	7402                	ld	s0,32(sp)
    8000473e:	64e2                	ld	s1,24(sp)
    80004740:	6942                	ld	s2,16(sp)
    80004742:	69a2                	ld	s3,8(sp)
    80004744:	6a02                	ld	s4,0(sp)
    80004746:	6145                	addi	sp,sp,48
    80004748:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000474a:	02059493          	slli	s1,a1,0x20
    8000474e:	9081                	srli	s1,s1,0x20
    80004750:	048a                	slli	s1,s1,0x2
    80004752:	94aa                	add	s1,s1,a0
    80004754:	0504a983          	lw	s3,80(s1)
    80004758:	fe0990e3          	bnez	s3,80004738 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000475c:	4108                	lw	a0,0(a0)
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	e4a080e7          	jalr	-438(ra) # 800045a8 <balloc>
    80004766:	0005099b          	sext.w	s3,a0
    8000476a:	0534a823          	sw	s3,80(s1)
    8000476e:	b7e9                	j	80004738 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80004770:	4108                	lw	a0,0(a0)
    80004772:	00000097          	auipc	ra,0x0
    80004776:	e36080e7          	jalr	-458(ra) # 800045a8 <balloc>
    8000477a:	0005059b          	sext.w	a1,a0
    8000477e:	08b92023          	sw	a1,128(s2)
    80004782:	b759                	j	80004708 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80004784:	00092503          	lw	a0,0(s2)
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	e20080e7          	jalr	-480(ra) # 800045a8 <balloc>
    80004790:	0005099b          	sext.w	s3,a0
    80004794:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80004798:	8552                	mv	a0,s4
    8000479a:	00001097          	auipc	ra,0x1
    8000479e:	ef8080e7          	jalr	-264(ra) # 80005692 <log_write>
    800047a2:	b771                	j	8000472e <bmap+0x54>
  panic("bmap: out of range");
    800047a4:	00005517          	auipc	a0,0x5
    800047a8:	fdc50513          	addi	a0,a0,-36 # 80009780 <syscalls+0x140>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	d92080e7          	jalr	-622(ra) # 8000053e <panic>

00000000800047b4 <iget>:
{
    800047b4:	7179                	addi	sp,sp,-48
    800047b6:	f406                	sd	ra,40(sp)
    800047b8:	f022                	sd	s0,32(sp)
    800047ba:	ec26                	sd	s1,24(sp)
    800047bc:	e84a                	sd	s2,16(sp)
    800047be:	e44e                	sd	s3,8(sp)
    800047c0:	e052                	sd	s4,0(sp)
    800047c2:	1800                	addi	s0,sp,48
    800047c4:	89aa                	mv	s3,a0
    800047c6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800047c8:	0001d517          	auipc	a0,0x1d
    800047cc:	ca050513          	addi	a0,a0,-864 # 80021468 <itable>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	414080e7          	jalr	1044(ra) # 80000be4 <acquire>
  empty = 0;
    800047d8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800047da:	0001d497          	auipc	s1,0x1d
    800047de:	ca648493          	addi	s1,s1,-858 # 80021480 <itable+0x18>
    800047e2:	0001e697          	auipc	a3,0x1e
    800047e6:	72e68693          	addi	a3,a3,1838 # 80022f10 <log>
    800047ea:	a039                	j	800047f8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800047ec:	02090b63          	beqz	s2,80004822 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800047f0:	08848493          	addi	s1,s1,136
    800047f4:	02d48a63          	beq	s1,a3,80004828 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800047f8:	449c                	lw	a5,8(s1)
    800047fa:	fef059e3          	blez	a5,800047ec <iget+0x38>
    800047fe:	4098                	lw	a4,0(s1)
    80004800:	ff3716e3          	bne	a4,s3,800047ec <iget+0x38>
    80004804:	40d8                	lw	a4,4(s1)
    80004806:	ff4713e3          	bne	a4,s4,800047ec <iget+0x38>
      ip->ref++;
    8000480a:	2785                	addiw	a5,a5,1
    8000480c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000480e:	0001d517          	auipc	a0,0x1d
    80004812:	c5a50513          	addi	a0,a0,-934 # 80021468 <itable>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	482080e7          	jalr	1154(ra) # 80000c98 <release>
      return ip;
    8000481e:	8926                	mv	s2,s1
    80004820:	a03d                	j	8000484e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004822:	f7f9                	bnez	a5,800047f0 <iget+0x3c>
    80004824:	8926                	mv	s2,s1
    80004826:	b7e9                	j	800047f0 <iget+0x3c>
  if(empty == 0)
    80004828:	02090c63          	beqz	s2,80004860 <iget+0xac>
  ip->dev = dev;
    8000482c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004830:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004834:	4785                	li	a5,1
    80004836:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000483a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000483e:	0001d517          	auipc	a0,0x1d
    80004842:	c2a50513          	addi	a0,a0,-982 # 80021468 <itable>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
}
    8000484e:	854a                	mv	a0,s2
    80004850:	70a2                	ld	ra,40(sp)
    80004852:	7402                	ld	s0,32(sp)
    80004854:	64e2                	ld	s1,24(sp)
    80004856:	6942                	ld	s2,16(sp)
    80004858:	69a2                	ld	s3,8(sp)
    8000485a:	6a02                	ld	s4,0(sp)
    8000485c:	6145                	addi	sp,sp,48
    8000485e:	8082                	ret
    panic("iget: no inodes");
    80004860:	00005517          	auipc	a0,0x5
    80004864:	f3850513          	addi	a0,a0,-200 # 80009798 <syscalls+0x158>
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	cd6080e7          	jalr	-810(ra) # 8000053e <panic>

0000000080004870 <fsinit>:
fsinit(int dev) {
    80004870:	7179                	addi	sp,sp,-48
    80004872:	f406                	sd	ra,40(sp)
    80004874:	f022                	sd	s0,32(sp)
    80004876:	ec26                	sd	s1,24(sp)
    80004878:	e84a                	sd	s2,16(sp)
    8000487a:	e44e                	sd	s3,8(sp)
    8000487c:	1800                	addi	s0,sp,48
    8000487e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004880:	4585                	li	a1,1
    80004882:	00000097          	auipc	ra,0x0
    80004886:	a64080e7          	jalr	-1436(ra) # 800042e6 <bread>
    8000488a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000488c:	0001d997          	auipc	s3,0x1d
    80004890:	bbc98993          	addi	s3,s3,-1092 # 80021448 <sb>
    80004894:	02000613          	li	a2,32
    80004898:	05850593          	addi	a1,a0,88
    8000489c:	854e                	mv	a0,s3
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	4a2080e7          	jalr	1186(ra) # 80000d40 <memmove>
  brelse(bp);
    800048a6:	8526                	mv	a0,s1
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	b6e080e7          	jalr	-1170(ra) # 80004416 <brelse>
  if(sb.magic != FSMAGIC)
    800048b0:	0009a703          	lw	a4,0(s3)
    800048b4:	102037b7          	lui	a5,0x10203
    800048b8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800048bc:	02f71263          	bne	a4,a5,800048e0 <fsinit+0x70>
  initlog(dev, &sb);
    800048c0:	0001d597          	auipc	a1,0x1d
    800048c4:	b8858593          	addi	a1,a1,-1144 # 80021448 <sb>
    800048c8:	854a                	mv	a0,s2
    800048ca:	00001097          	auipc	ra,0x1
    800048ce:	b4c080e7          	jalr	-1204(ra) # 80005416 <initlog>
}
    800048d2:	70a2                	ld	ra,40(sp)
    800048d4:	7402                	ld	s0,32(sp)
    800048d6:	64e2                	ld	s1,24(sp)
    800048d8:	6942                	ld	s2,16(sp)
    800048da:	69a2                	ld	s3,8(sp)
    800048dc:	6145                	addi	sp,sp,48
    800048de:	8082                	ret
    panic("invalid file system");
    800048e0:	00005517          	auipc	a0,0x5
    800048e4:	ec850513          	addi	a0,a0,-312 # 800097a8 <syscalls+0x168>
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	c56080e7          	jalr	-938(ra) # 8000053e <panic>

00000000800048f0 <iinit>:
{
    800048f0:	7179                	addi	sp,sp,-48
    800048f2:	f406                	sd	ra,40(sp)
    800048f4:	f022                	sd	s0,32(sp)
    800048f6:	ec26                	sd	s1,24(sp)
    800048f8:	e84a                	sd	s2,16(sp)
    800048fa:	e44e                	sd	s3,8(sp)
    800048fc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800048fe:	00005597          	auipc	a1,0x5
    80004902:	ec258593          	addi	a1,a1,-318 # 800097c0 <syscalls+0x180>
    80004906:	0001d517          	auipc	a0,0x1d
    8000490a:	b6250513          	addi	a0,a0,-1182 # 80021468 <itable>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	246080e7          	jalr	582(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004916:	0001d497          	auipc	s1,0x1d
    8000491a:	b7a48493          	addi	s1,s1,-1158 # 80021490 <itable+0x28>
    8000491e:	0001e997          	auipc	s3,0x1e
    80004922:	60298993          	addi	s3,s3,1538 # 80022f20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004926:	00005917          	auipc	s2,0x5
    8000492a:	ea290913          	addi	s2,s2,-350 # 800097c8 <syscalls+0x188>
    8000492e:	85ca                	mv	a1,s2
    80004930:	8526                	mv	a0,s1
    80004932:	00001097          	auipc	ra,0x1
    80004936:	e46080e7          	jalr	-442(ra) # 80005778 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000493a:	08848493          	addi	s1,s1,136
    8000493e:	ff3498e3          	bne	s1,s3,8000492e <iinit+0x3e>
}
    80004942:	70a2                	ld	ra,40(sp)
    80004944:	7402                	ld	s0,32(sp)
    80004946:	64e2                	ld	s1,24(sp)
    80004948:	6942                	ld	s2,16(sp)
    8000494a:	69a2                	ld	s3,8(sp)
    8000494c:	6145                	addi	sp,sp,48
    8000494e:	8082                	ret

0000000080004950 <ialloc>:
{
    80004950:	715d                	addi	sp,sp,-80
    80004952:	e486                	sd	ra,72(sp)
    80004954:	e0a2                	sd	s0,64(sp)
    80004956:	fc26                	sd	s1,56(sp)
    80004958:	f84a                	sd	s2,48(sp)
    8000495a:	f44e                	sd	s3,40(sp)
    8000495c:	f052                	sd	s4,32(sp)
    8000495e:	ec56                	sd	s5,24(sp)
    80004960:	e85a                	sd	s6,16(sp)
    80004962:	e45e                	sd	s7,8(sp)
    80004964:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004966:	0001d717          	auipc	a4,0x1d
    8000496a:	aee72703          	lw	a4,-1298(a4) # 80021454 <sb+0xc>
    8000496e:	4785                	li	a5,1
    80004970:	04e7fa63          	bgeu	a5,a4,800049c4 <ialloc+0x74>
    80004974:	8aaa                	mv	s5,a0
    80004976:	8bae                	mv	s7,a1
    80004978:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000497a:	0001da17          	auipc	s4,0x1d
    8000497e:	acea0a13          	addi	s4,s4,-1330 # 80021448 <sb>
    80004982:	00048b1b          	sext.w	s6,s1
    80004986:	0044d593          	srli	a1,s1,0x4
    8000498a:	018a2783          	lw	a5,24(s4)
    8000498e:	9dbd                	addw	a1,a1,a5
    80004990:	8556                	mv	a0,s5
    80004992:	00000097          	auipc	ra,0x0
    80004996:	954080e7          	jalr	-1708(ra) # 800042e6 <bread>
    8000499a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000499c:	05850993          	addi	s3,a0,88
    800049a0:	00f4f793          	andi	a5,s1,15
    800049a4:	079a                	slli	a5,a5,0x6
    800049a6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800049a8:	00099783          	lh	a5,0(s3)
    800049ac:	c785                	beqz	a5,800049d4 <ialloc+0x84>
    brelse(bp);
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	a68080e7          	jalr	-1432(ra) # 80004416 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800049b6:	0485                	addi	s1,s1,1
    800049b8:	00ca2703          	lw	a4,12(s4)
    800049bc:	0004879b          	sext.w	a5,s1
    800049c0:	fce7e1e3          	bltu	a5,a4,80004982 <ialloc+0x32>
  panic("ialloc: no inodes");
    800049c4:	00005517          	auipc	a0,0x5
    800049c8:	e0c50513          	addi	a0,a0,-500 # 800097d0 <syscalls+0x190>
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	b72080e7          	jalr	-1166(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800049d4:	04000613          	li	a2,64
    800049d8:	4581                	li	a1,0
    800049da:	854e                	mv	a0,s3
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	304080e7          	jalr	772(ra) # 80000ce0 <memset>
      dip->type = type;
    800049e4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800049e8:	854a                	mv	a0,s2
    800049ea:	00001097          	auipc	ra,0x1
    800049ee:	ca8080e7          	jalr	-856(ra) # 80005692 <log_write>
      brelse(bp);
    800049f2:	854a                	mv	a0,s2
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	a22080e7          	jalr	-1502(ra) # 80004416 <brelse>
      return iget(dev, inum);
    800049fc:	85da                	mv	a1,s6
    800049fe:	8556                	mv	a0,s5
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	db4080e7          	jalr	-588(ra) # 800047b4 <iget>
}
    80004a08:	60a6                	ld	ra,72(sp)
    80004a0a:	6406                	ld	s0,64(sp)
    80004a0c:	74e2                	ld	s1,56(sp)
    80004a0e:	7942                	ld	s2,48(sp)
    80004a10:	79a2                	ld	s3,40(sp)
    80004a12:	7a02                	ld	s4,32(sp)
    80004a14:	6ae2                	ld	s5,24(sp)
    80004a16:	6b42                	ld	s6,16(sp)
    80004a18:	6ba2                	ld	s7,8(sp)
    80004a1a:	6161                	addi	sp,sp,80
    80004a1c:	8082                	ret

0000000080004a1e <iupdate>:
{
    80004a1e:	1101                	addi	sp,sp,-32
    80004a20:	ec06                	sd	ra,24(sp)
    80004a22:	e822                	sd	s0,16(sp)
    80004a24:	e426                	sd	s1,8(sp)
    80004a26:	e04a                	sd	s2,0(sp)
    80004a28:	1000                	addi	s0,sp,32
    80004a2a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004a2c:	415c                	lw	a5,4(a0)
    80004a2e:	0047d79b          	srliw	a5,a5,0x4
    80004a32:	0001d597          	auipc	a1,0x1d
    80004a36:	a2e5a583          	lw	a1,-1490(a1) # 80021460 <sb+0x18>
    80004a3a:	9dbd                	addw	a1,a1,a5
    80004a3c:	4108                	lw	a0,0(a0)
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	8a8080e7          	jalr	-1880(ra) # 800042e6 <bread>
    80004a46:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004a48:	05850793          	addi	a5,a0,88
    80004a4c:	40c8                	lw	a0,4(s1)
    80004a4e:	893d                	andi	a0,a0,15
    80004a50:	051a                	slli	a0,a0,0x6
    80004a52:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004a54:	04449703          	lh	a4,68(s1)
    80004a58:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004a5c:	04649703          	lh	a4,70(s1)
    80004a60:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004a64:	04849703          	lh	a4,72(s1)
    80004a68:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004a6c:	04a49703          	lh	a4,74(s1)
    80004a70:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004a74:	44f8                	lw	a4,76(s1)
    80004a76:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004a78:	03400613          	li	a2,52
    80004a7c:	05048593          	addi	a1,s1,80
    80004a80:	0531                	addi	a0,a0,12
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	2be080e7          	jalr	702(ra) # 80000d40 <memmove>
  log_write(bp);
    80004a8a:	854a                	mv	a0,s2
    80004a8c:	00001097          	auipc	ra,0x1
    80004a90:	c06080e7          	jalr	-1018(ra) # 80005692 <log_write>
  brelse(bp);
    80004a94:	854a                	mv	a0,s2
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	980080e7          	jalr	-1664(ra) # 80004416 <brelse>
}
    80004a9e:	60e2                	ld	ra,24(sp)
    80004aa0:	6442                	ld	s0,16(sp)
    80004aa2:	64a2                	ld	s1,8(sp)
    80004aa4:	6902                	ld	s2,0(sp)
    80004aa6:	6105                	addi	sp,sp,32
    80004aa8:	8082                	ret

0000000080004aaa <idup>:
{
    80004aaa:	1101                	addi	sp,sp,-32
    80004aac:	ec06                	sd	ra,24(sp)
    80004aae:	e822                	sd	s0,16(sp)
    80004ab0:	e426                	sd	s1,8(sp)
    80004ab2:	1000                	addi	s0,sp,32
    80004ab4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004ab6:	0001d517          	auipc	a0,0x1d
    80004aba:	9b250513          	addi	a0,a0,-1614 # 80021468 <itable>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	126080e7          	jalr	294(ra) # 80000be4 <acquire>
  ip->ref++;
    80004ac6:	449c                	lw	a5,8(s1)
    80004ac8:	2785                	addiw	a5,a5,1
    80004aca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004acc:	0001d517          	auipc	a0,0x1d
    80004ad0:	99c50513          	addi	a0,a0,-1636 # 80021468 <itable>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	1c4080e7          	jalr	452(ra) # 80000c98 <release>
}
    80004adc:	8526                	mv	a0,s1
    80004ade:	60e2                	ld	ra,24(sp)
    80004ae0:	6442                	ld	s0,16(sp)
    80004ae2:	64a2                	ld	s1,8(sp)
    80004ae4:	6105                	addi	sp,sp,32
    80004ae6:	8082                	ret

0000000080004ae8 <ilock>:
{
    80004ae8:	1101                	addi	sp,sp,-32
    80004aea:	ec06                	sd	ra,24(sp)
    80004aec:	e822                	sd	s0,16(sp)
    80004aee:	e426                	sd	s1,8(sp)
    80004af0:	e04a                	sd	s2,0(sp)
    80004af2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004af4:	c115                	beqz	a0,80004b18 <ilock+0x30>
    80004af6:	84aa                	mv	s1,a0
    80004af8:	451c                	lw	a5,8(a0)
    80004afa:	00f05f63          	blez	a5,80004b18 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004afe:	0541                	addi	a0,a0,16
    80004b00:	00001097          	auipc	ra,0x1
    80004b04:	cb2080e7          	jalr	-846(ra) # 800057b2 <acquiresleep>
  if(ip->valid == 0){
    80004b08:	40bc                	lw	a5,64(s1)
    80004b0a:	cf99                	beqz	a5,80004b28 <ilock+0x40>
}
    80004b0c:	60e2                	ld	ra,24(sp)
    80004b0e:	6442                	ld	s0,16(sp)
    80004b10:	64a2                	ld	s1,8(sp)
    80004b12:	6902                	ld	s2,0(sp)
    80004b14:	6105                	addi	sp,sp,32
    80004b16:	8082                	ret
    panic("ilock");
    80004b18:	00005517          	auipc	a0,0x5
    80004b1c:	cd050513          	addi	a0,a0,-816 # 800097e8 <syscalls+0x1a8>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	a1e080e7          	jalr	-1506(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004b28:	40dc                	lw	a5,4(s1)
    80004b2a:	0047d79b          	srliw	a5,a5,0x4
    80004b2e:	0001d597          	auipc	a1,0x1d
    80004b32:	9325a583          	lw	a1,-1742(a1) # 80021460 <sb+0x18>
    80004b36:	9dbd                	addw	a1,a1,a5
    80004b38:	4088                	lw	a0,0(s1)
    80004b3a:	fffff097          	auipc	ra,0xfffff
    80004b3e:	7ac080e7          	jalr	1964(ra) # 800042e6 <bread>
    80004b42:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004b44:	05850593          	addi	a1,a0,88
    80004b48:	40dc                	lw	a5,4(s1)
    80004b4a:	8bbd                	andi	a5,a5,15
    80004b4c:	079a                	slli	a5,a5,0x6
    80004b4e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004b50:	00059783          	lh	a5,0(a1)
    80004b54:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004b58:	00259783          	lh	a5,2(a1)
    80004b5c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004b60:	00459783          	lh	a5,4(a1)
    80004b64:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004b68:	00659783          	lh	a5,6(a1)
    80004b6c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004b70:	459c                	lw	a5,8(a1)
    80004b72:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004b74:	03400613          	li	a2,52
    80004b78:	05b1                	addi	a1,a1,12
    80004b7a:	05048513          	addi	a0,s1,80
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	1c2080e7          	jalr	450(ra) # 80000d40 <memmove>
    brelse(bp);
    80004b86:	854a                	mv	a0,s2
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	88e080e7          	jalr	-1906(ra) # 80004416 <brelse>
    ip->valid = 1;
    80004b90:	4785                	li	a5,1
    80004b92:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004b94:	04449783          	lh	a5,68(s1)
    80004b98:	fbb5                	bnez	a5,80004b0c <ilock+0x24>
      panic("ilock: no type");
    80004b9a:	00005517          	auipc	a0,0x5
    80004b9e:	c5650513          	addi	a0,a0,-938 # 800097f0 <syscalls+0x1b0>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	99c080e7          	jalr	-1636(ra) # 8000053e <panic>

0000000080004baa <iunlock>:
{
    80004baa:	1101                	addi	sp,sp,-32
    80004bac:	ec06                	sd	ra,24(sp)
    80004bae:	e822                	sd	s0,16(sp)
    80004bb0:	e426                	sd	s1,8(sp)
    80004bb2:	e04a                	sd	s2,0(sp)
    80004bb4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004bb6:	c905                	beqz	a0,80004be6 <iunlock+0x3c>
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	01050913          	addi	s2,a0,16
    80004bbe:	854a                	mv	a0,s2
    80004bc0:	00001097          	auipc	ra,0x1
    80004bc4:	c8c080e7          	jalr	-884(ra) # 8000584c <holdingsleep>
    80004bc8:	cd19                	beqz	a0,80004be6 <iunlock+0x3c>
    80004bca:	449c                	lw	a5,8(s1)
    80004bcc:	00f05d63          	blez	a5,80004be6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004bd0:	854a                	mv	a0,s2
    80004bd2:	00001097          	auipc	ra,0x1
    80004bd6:	c36080e7          	jalr	-970(ra) # 80005808 <releasesleep>
}
    80004bda:	60e2                	ld	ra,24(sp)
    80004bdc:	6442                	ld	s0,16(sp)
    80004bde:	64a2                	ld	s1,8(sp)
    80004be0:	6902                	ld	s2,0(sp)
    80004be2:	6105                	addi	sp,sp,32
    80004be4:	8082                	ret
    panic("iunlock");
    80004be6:	00005517          	auipc	a0,0x5
    80004bea:	c1a50513          	addi	a0,a0,-998 # 80009800 <syscalls+0x1c0>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	950080e7          	jalr	-1712(ra) # 8000053e <panic>

0000000080004bf6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004bf6:	7179                	addi	sp,sp,-48
    80004bf8:	f406                	sd	ra,40(sp)
    80004bfa:	f022                	sd	s0,32(sp)
    80004bfc:	ec26                	sd	s1,24(sp)
    80004bfe:	e84a                	sd	s2,16(sp)
    80004c00:	e44e                	sd	s3,8(sp)
    80004c02:	e052                	sd	s4,0(sp)
    80004c04:	1800                	addi	s0,sp,48
    80004c06:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004c08:	05050493          	addi	s1,a0,80
    80004c0c:	08050913          	addi	s2,a0,128
    80004c10:	a021                	j	80004c18 <itrunc+0x22>
    80004c12:	0491                	addi	s1,s1,4
    80004c14:	01248d63          	beq	s1,s2,80004c2e <itrunc+0x38>
    if(ip->addrs[i]){
    80004c18:	408c                	lw	a1,0(s1)
    80004c1a:	dde5                	beqz	a1,80004c12 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004c1c:	0009a503          	lw	a0,0(s3)
    80004c20:	00000097          	auipc	ra,0x0
    80004c24:	90c080e7          	jalr	-1780(ra) # 8000452c <bfree>
      ip->addrs[i] = 0;
    80004c28:	0004a023          	sw	zero,0(s1)
    80004c2c:	b7dd                	j	80004c12 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004c2e:	0809a583          	lw	a1,128(s3)
    80004c32:	e185                	bnez	a1,80004c52 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004c34:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004c38:	854e                	mv	a0,s3
    80004c3a:	00000097          	auipc	ra,0x0
    80004c3e:	de4080e7          	jalr	-540(ra) # 80004a1e <iupdate>
}
    80004c42:	70a2                	ld	ra,40(sp)
    80004c44:	7402                	ld	s0,32(sp)
    80004c46:	64e2                	ld	s1,24(sp)
    80004c48:	6942                	ld	s2,16(sp)
    80004c4a:	69a2                	ld	s3,8(sp)
    80004c4c:	6a02                	ld	s4,0(sp)
    80004c4e:	6145                	addi	sp,sp,48
    80004c50:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004c52:	0009a503          	lw	a0,0(s3)
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	690080e7          	jalr	1680(ra) # 800042e6 <bread>
    80004c5e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004c60:	05850493          	addi	s1,a0,88
    80004c64:	45850913          	addi	s2,a0,1112
    80004c68:	a811                	j	80004c7c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004c6a:	0009a503          	lw	a0,0(s3)
    80004c6e:	00000097          	auipc	ra,0x0
    80004c72:	8be080e7          	jalr	-1858(ra) # 8000452c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004c76:	0491                	addi	s1,s1,4
    80004c78:	01248563          	beq	s1,s2,80004c82 <itrunc+0x8c>
      if(a[j])
    80004c7c:	408c                	lw	a1,0(s1)
    80004c7e:	dde5                	beqz	a1,80004c76 <itrunc+0x80>
    80004c80:	b7ed                	j	80004c6a <itrunc+0x74>
    brelse(bp);
    80004c82:	8552                	mv	a0,s4
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	792080e7          	jalr	1938(ra) # 80004416 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004c8c:	0809a583          	lw	a1,128(s3)
    80004c90:	0009a503          	lw	a0,0(s3)
    80004c94:	00000097          	auipc	ra,0x0
    80004c98:	898080e7          	jalr	-1896(ra) # 8000452c <bfree>
    ip->addrs[NDIRECT] = 0;
    80004c9c:	0809a023          	sw	zero,128(s3)
    80004ca0:	bf51                	j	80004c34 <itrunc+0x3e>

0000000080004ca2 <iput>:
{
    80004ca2:	1101                	addi	sp,sp,-32
    80004ca4:	ec06                	sd	ra,24(sp)
    80004ca6:	e822                	sd	s0,16(sp)
    80004ca8:	e426                	sd	s1,8(sp)
    80004caa:	e04a                	sd	s2,0(sp)
    80004cac:	1000                	addi	s0,sp,32
    80004cae:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004cb0:	0001c517          	auipc	a0,0x1c
    80004cb4:	7b850513          	addi	a0,a0,1976 # 80021468 <itable>
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	f2c080e7          	jalr	-212(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004cc0:	4498                	lw	a4,8(s1)
    80004cc2:	4785                	li	a5,1
    80004cc4:	02f70363          	beq	a4,a5,80004cea <iput+0x48>
  ip->ref--;
    80004cc8:	449c                	lw	a5,8(s1)
    80004cca:	37fd                	addiw	a5,a5,-1
    80004ccc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004cce:	0001c517          	auipc	a0,0x1c
    80004cd2:	79a50513          	addi	a0,a0,1946 # 80021468 <itable>
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	fc2080e7          	jalr	-62(ra) # 80000c98 <release>
}
    80004cde:	60e2                	ld	ra,24(sp)
    80004ce0:	6442                	ld	s0,16(sp)
    80004ce2:	64a2                	ld	s1,8(sp)
    80004ce4:	6902                	ld	s2,0(sp)
    80004ce6:	6105                	addi	sp,sp,32
    80004ce8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004cea:	40bc                	lw	a5,64(s1)
    80004cec:	dff1                	beqz	a5,80004cc8 <iput+0x26>
    80004cee:	04a49783          	lh	a5,74(s1)
    80004cf2:	fbf9                	bnez	a5,80004cc8 <iput+0x26>
    acquiresleep(&ip->lock);
    80004cf4:	01048913          	addi	s2,s1,16
    80004cf8:	854a                	mv	a0,s2
    80004cfa:	00001097          	auipc	ra,0x1
    80004cfe:	ab8080e7          	jalr	-1352(ra) # 800057b2 <acquiresleep>
    release(&itable.lock);
    80004d02:	0001c517          	auipc	a0,0x1c
    80004d06:	76650513          	addi	a0,a0,1894 # 80021468 <itable>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	f8e080e7          	jalr	-114(ra) # 80000c98 <release>
    itrunc(ip);
    80004d12:	8526                	mv	a0,s1
    80004d14:	00000097          	auipc	ra,0x0
    80004d18:	ee2080e7          	jalr	-286(ra) # 80004bf6 <itrunc>
    ip->type = 0;
    80004d1c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004d20:	8526                	mv	a0,s1
    80004d22:	00000097          	auipc	ra,0x0
    80004d26:	cfc080e7          	jalr	-772(ra) # 80004a1e <iupdate>
    ip->valid = 0;
    80004d2a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004d2e:	854a                	mv	a0,s2
    80004d30:	00001097          	auipc	ra,0x1
    80004d34:	ad8080e7          	jalr	-1320(ra) # 80005808 <releasesleep>
    acquire(&itable.lock);
    80004d38:	0001c517          	auipc	a0,0x1c
    80004d3c:	73050513          	addi	a0,a0,1840 # 80021468 <itable>
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	ea4080e7          	jalr	-348(ra) # 80000be4 <acquire>
    80004d48:	b741                	j	80004cc8 <iput+0x26>

0000000080004d4a <iunlockput>:
{
    80004d4a:	1101                	addi	sp,sp,-32
    80004d4c:	ec06                	sd	ra,24(sp)
    80004d4e:	e822                	sd	s0,16(sp)
    80004d50:	e426                	sd	s1,8(sp)
    80004d52:	1000                	addi	s0,sp,32
    80004d54:	84aa                	mv	s1,a0
  iunlock(ip);
    80004d56:	00000097          	auipc	ra,0x0
    80004d5a:	e54080e7          	jalr	-428(ra) # 80004baa <iunlock>
  iput(ip);
    80004d5e:	8526                	mv	a0,s1
    80004d60:	00000097          	auipc	ra,0x0
    80004d64:	f42080e7          	jalr	-190(ra) # 80004ca2 <iput>
}
    80004d68:	60e2                	ld	ra,24(sp)
    80004d6a:	6442                	ld	s0,16(sp)
    80004d6c:	64a2                	ld	s1,8(sp)
    80004d6e:	6105                	addi	sp,sp,32
    80004d70:	8082                	ret

0000000080004d72 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004d72:	1141                	addi	sp,sp,-16
    80004d74:	e422                	sd	s0,8(sp)
    80004d76:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004d78:	411c                	lw	a5,0(a0)
    80004d7a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004d7c:	415c                	lw	a5,4(a0)
    80004d7e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004d80:	04451783          	lh	a5,68(a0)
    80004d84:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004d88:	04a51783          	lh	a5,74(a0)
    80004d8c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004d90:	04c56783          	lwu	a5,76(a0)
    80004d94:	e99c                	sd	a5,16(a1)
}
    80004d96:	6422                	ld	s0,8(sp)
    80004d98:	0141                	addi	sp,sp,16
    80004d9a:	8082                	ret

0000000080004d9c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004d9c:	457c                	lw	a5,76(a0)
    80004d9e:	0ed7e963          	bltu	a5,a3,80004e90 <readi+0xf4>
{
    80004da2:	7159                	addi	sp,sp,-112
    80004da4:	f486                	sd	ra,104(sp)
    80004da6:	f0a2                	sd	s0,96(sp)
    80004da8:	eca6                	sd	s1,88(sp)
    80004daa:	e8ca                	sd	s2,80(sp)
    80004dac:	e4ce                	sd	s3,72(sp)
    80004dae:	e0d2                	sd	s4,64(sp)
    80004db0:	fc56                	sd	s5,56(sp)
    80004db2:	f85a                	sd	s6,48(sp)
    80004db4:	f45e                	sd	s7,40(sp)
    80004db6:	f062                	sd	s8,32(sp)
    80004db8:	ec66                	sd	s9,24(sp)
    80004dba:	e86a                	sd	s10,16(sp)
    80004dbc:	e46e                	sd	s11,8(sp)
    80004dbe:	1880                	addi	s0,sp,112
    80004dc0:	8baa                	mv	s7,a0
    80004dc2:	8c2e                	mv	s8,a1
    80004dc4:	8ab2                	mv	s5,a2
    80004dc6:	84b6                	mv	s1,a3
    80004dc8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004dca:	9f35                	addw	a4,a4,a3
    return 0;
    80004dcc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004dce:	0ad76063          	bltu	a4,a3,80004e6e <readi+0xd2>
  if(off + n > ip->size)
    80004dd2:	00e7f463          	bgeu	a5,a4,80004dda <readi+0x3e>
    n = ip->size - off;
    80004dd6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004dda:	0a0b0963          	beqz	s6,80004e8c <readi+0xf0>
    80004dde:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004de0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004de4:	5cfd                	li	s9,-1
    80004de6:	a82d                	j	80004e20 <readi+0x84>
    80004de8:	020a1d93          	slli	s11,s4,0x20
    80004dec:	020ddd93          	srli	s11,s11,0x20
    80004df0:	05890613          	addi	a2,s2,88
    80004df4:	86ee                	mv	a3,s11
    80004df6:	963a                	add	a2,a2,a4
    80004df8:	85d6                	mv	a1,s5
    80004dfa:	8562                	mv	a0,s8
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	a74080e7          	jalr	-1420(ra) # 80003870 <either_copyout>
    80004e04:	05950d63          	beq	a0,s9,80004e5e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004e08:	854a                	mv	a0,s2
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	60c080e7          	jalr	1548(ra) # 80004416 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004e12:	013a09bb          	addw	s3,s4,s3
    80004e16:	009a04bb          	addw	s1,s4,s1
    80004e1a:	9aee                	add	s5,s5,s11
    80004e1c:	0569f763          	bgeu	s3,s6,80004e6a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004e20:	000ba903          	lw	s2,0(s7)
    80004e24:	00a4d59b          	srliw	a1,s1,0xa
    80004e28:	855e                	mv	a0,s7
    80004e2a:	00000097          	auipc	ra,0x0
    80004e2e:	8b0080e7          	jalr	-1872(ra) # 800046da <bmap>
    80004e32:	0005059b          	sext.w	a1,a0
    80004e36:	854a                	mv	a0,s2
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	4ae080e7          	jalr	1198(ra) # 800042e6 <bread>
    80004e40:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004e42:	3ff4f713          	andi	a4,s1,1023
    80004e46:	40ed07bb          	subw	a5,s10,a4
    80004e4a:	413b06bb          	subw	a3,s6,s3
    80004e4e:	8a3e                	mv	s4,a5
    80004e50:	2781                	sext.w	a5,a5
    80004e52:	0006861b          	sext.w	a2,a3
    80004e56:	f8f679e3          	bgeu	a2,a5,80004de8 <readi+0x4c>
    80004e5a:	8a36                	mv	s4,a3
    80004e5c:	b771                	j	80004de8 <readi+0x4c>
      brelse(bp);
    80004e5e:	854a                	mv	a0,s2
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	5b6080e7          	jalr	1462(ra) # 80004416 <brelse>
      tot = -1;
    80004e68:	59fd                	li	s3,-1
  }
  return tot;
    80004e6a:	0009851b          	sext.w	a0,s3
}
    80004e6e:	70a6                	ld	ra,104(sp)
    80004e70:	7406                	ld	s0,96(sp)
    80004e72:	64e6                	ld	s1,88(sp)
    80004e74:	6946                	ld	s2,80(sp)
    80004e76:	69a6                	ld	s3,72(sp)
    80004e78:	6a06                	ld	s4,64(sp)
    80004e7a:	7ae2                	ld	s5,56(sp)
    80004e7c:	7b42                	ld	s6,48(sp)
    80004e7e:	7ba2                	ld	s7,40(sp)
    80004e80:	7c02                	ld	s8,32(sp)
    80004e82:	6ce2                	ld	s9,24(sp)
    80004e84:	6d42                	ld	s10,16(sp)
    80004e86:	6da2                	ld	s11,8(sp)
    80004e88:	6165                	addi	sp,sp,112
    80004e8a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004e8c:	89da                	mv	s3,s6
    80004e8e:	bff1                	j	80004e6a <readi+0xce>
    return 0;
    80004e90:	4501                	li	a0,0
}
    80004e92:	8082                	ret

0000000080004e94 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004e94:	457c                	lw	a5,76(a0)
    80004e96:	10d7e863          	bltu	a5,a3,80004fa6 <writei+0x112>
{
    80004e9a:	7159                	addi	sp,sp,-112
    80004e9c:	f486                	sd	ra,104(sp)
    80004e9e:	f0a2                	sd	s0,96(sp)
    80004ea0:	eca6                	sd	s1,88(sp)
    80004ea2:	e8ca                	sd	s2,80(sp)
    80004ea4:	e4ce                	sd	s3,72(sp)
    80004ea6:	e0d2                	sd	s4,64(sp)
    80004ea8:	fc56                	sd	s5,56(sp)
    80004eaa:	f85a                	sd	s6,48(sp)
    80004eac:	f45e                	sd	s7,40(sp)
    80004eae:	f062                	sd	s8,32(sp)
    80004eb0:	ec66                	sd	s9,24(sp)
    80004eb2:	e86a                	sd	s10,16(sp)
    80004eb4:	e46e                	sd	s11,8(sp)
    80004eb6:	1880                	addi	s0,sp,112
    80004eb8:	8b2a                	mv	s6,a0
    80004eba:	8c2e                	mv	s8,a1
    80004ebc:	8ab2                	mv	s5,a2
    80004ebe:	8936                	mv	s2,a3
    80004ec0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004ec2:	00e687bb          	addw	a5,a3,a4
    80004ec6:	0ed7e263          	bltu	a5,a3,80004faa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004eca:	00043737          	lui	a4,0x43
    80004ece:	0ef76063          	bltu	a4,a5,80004fae <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004ed2:	0c0b8863          	beqz	s7,80004fa2 <writei+0x10e>
    80004ed6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004ed8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004edc:	5cfd                	li	s9,-1
    80004ede:	a091                	j	80004f22 <writei+0x8e>
    80004ee0:	02099d93          	slli	s11,s3,0x20
    80004ee4:	020ddd93          	srli	s11,s11,0x20
    80004ee8:	05848513          	addi	a0,s1,88
    80004eec:	86ee                	mv	a3,s11
    80004eee:	8656                	mv	a2,s5
    80004ef0:	85e2                	mv	a1,s8
    80004ef2:	953a                	add	a0,a0,a4
    80004ef4:	fffff097          	auipc	ra,0xfffff
    80004ef8:	9d2080e7          	jalr	-1582(ra) # 800038c6 <either_copyin>
    80004efc:	07950263          	beq	a0,s9,80004f60 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004f00:	8526                	mv	a0,s1
    80004f02:	00000097          	auipc	ra,0x0
    80004f06:	790080e7          	jalr	1936(ra) # 80005692 <log_write>
    brelse(bp);
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	50a080e7          	jalr	1290(ra) # 80004416 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004f14:	01498a3b          	addw	s4,s3,s4
    80004f18:	0129893b          	addw	s2,s3,s2
    80004f1c:	9aee                	add	s5,s5,s11
    80004f1e:	057a7663          	bgeu	s4,s7,80004f6a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004f22:	000b2483          	lw	s1,0(s6)
    80004f26:	00a9559b          	srliw	a1,s2,0xa
    80004f2a:	855a                	mv	a0,s6
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	7ae080e7          	jalr	1966(ra) # 800046da <bmap>
    80004f34:	0005059b          	sext.w	a1,a0
    80004f38:	8526                	mv	a0,s1
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	3ac080e7          	jalr	940(ra) # 800042e6 <bread>
    80004f42:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004f44:	3ff97713          	andi	a4,s2,1023
    80004f48:	40ed07bb          	subw	a5,s10,a4
    80004f4c:	414b86bb          	subw	a3,s7,s4
    80004f50:	89be                	mv	s3,a5
    80004f52:	2781                	sext.w	a5,a5
    80004f54:	0006861b          	sext.w	a2,a3
    80004f58:	f8f674e3          	bgeu	a2,a5,80004ee0 <writei+0x4c>
    80004f5c:	89b6                	mv	s3,a3
    80004f5e:	b749                	j	80004ee0 <writei+0x4c>
      brelse(bp);
    80004f60:	8526                	mv	a0,s1
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	4b4080e7          	jalr	1204(ra) # 80004416 <brelse>
  }

  if(off > ip->size)
    80004f6a:	04cb2783          	lw	a5,76(s6)
    80004f6e:	0127f463          	bgeu	a5,s2,80004f76 <writei+0xe2>
    ip->size = off;
    80004f72:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004f76:	855a                	mv	a0,s6
    80004f78:	00000097          	auipc	ra,0x0
    80004f7c:	aa6080e7          	jalr	-1370(ra) # 80004a1e <iupdate>

  return tot;
    80004f80:	000a051b          	sext.w	a0,s4
}
    80004f84:	70a6                	ld	ra,104(sp)
    80004f86:	7406                	ld	s0,96(sp)
    80004f88:	64e6                	ld	s1,88(sp)
    80004f8a:	6946                	ld	s2,80(sp)
    80004f8c:	69a6                	ld	s3,72(sp)
    80004f8e:	6a06                	ld	s4,64(sp)
    80004f90:	7ae2                	ld	s5,56(sp)
    80004f92:	7b42                	ld	s6,48(sp)
    80004f94:	7ba2                	ld	s7,40(sp)
    80004f96:	7c02                	ld	s8,32(sp)
    80004f98:	6ce2                	ld	s9,24(sp)
    80004f9a:	6d42                	ld	s10,16(sp)
    80004f9c:	6da2                	ld	s11,8(sp)
    80004f9e:	6165                	addi	sp,sp,112
    80004fa0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004fa2:	8a5e                	mv	s4,s7
    80004fa4:	bfc9                	j	80004f76 <writei+0xe2>
    return -1;
    80004fa6:	557d                	li	a0,-1
}
    80004fa8:	8082                	ret
    return -1;
    80004faa:	557d                	li	a0,-1
    80004fac:	bfe1                	j	80004f84 <writei+0xf0>
    return -1;
    80004fae:	557d                	li	a0,-1
    80004fb0:	bfd1                	j	80004f84 <writei+0xf0>

0000000080004fb2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004fb2:	1141                	addi	sp,sp,-16
    80004fb4:	e406                	sd	ra,8(sp)
    80004fb6:	e022                	sd	s0,0(sp)
    80004fb8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004fba:	4639                	li	a2,14
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	dfc080e7          	jalr	-516(ra) # 80000db8 <strncmp>
}
    80004fc4:	60a2                	ld	ra,8(sp)
    80004fc6:	6402                	ld	s0,0(sp)
    80004fc8:	0141                	addi	sp,sp,16
    80004fca:	8082                	ret

0000000080004fcc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004fcc:	7139                	addi	sp,sp,-64
    80004fce:	fc06                	sd	ra,56(sp)
    80004fd0:	f822                	sd	s0,48(sp)
    80004fd2:	f426                	sd	s1,40(sp)
    80004fd4:	f04a                	sd	s2,32(sp)
    80004fd6:	ec4e                	sd	s3,24(sp)
    80004fd8:	e852                	sd	s4,16(sp)
    80004fda:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004fdc:	04451703          	lh	a4,68(a0)
    80004fe0:	4785                	li	a5,1
    80004fe2:	00f71a63          	bne	a4,a5,80004ff6 <dirlookup+0x2a>
    80004fe6:	892a                	mv	s2,a0
    80004fe8:	89ae                	mv	s3,a1
    80004fea:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004fec:	457c                	lw	a5,76(a0)
    80004fee:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004ff0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004ff2:	e79d                	bnez	a5,80005020 <dirlookup+0x54>
    80004ff4:	a8a5                	j	8000506c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004ff6:	00005517          	auipc	a0,0x5
    80004ffa:	81250513          	addi	a0,a0,-2030 # 80009808 <syscalls+0x1c8>
    80004ffe:	ffffb097          	auipc	ra,0xffffb
    80005002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
      panic("dirlookup read");
    80005006:	00005517          	auipc	a0,0x5
    8000500a:	81a50513          	addi	a0,a0,-2022 # 80009820 <syscalls+0x1e0>
    8000500e:	ffffb097          	auipc	ra,0xffffb
    80005012:	530080e7          	jalr	1328(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005016:	24c1                	addiw	s1,s1,16
    80005018:	04c92783          	lw	a5,76(s2)
    8000501c:	04f4f763          	bgeu	s1,a5,8000506a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005020:	4741                	li	a4,16
    80005022:	86a6                	mv	a3,s1
    80005024:	fc040613          	addi	a2,s0,-64
    80005028:	4581                	li	a1,0
    8000502a:	854a                	mv	a0,s2
    8000502c:	00000097          	auipc	ra,0x0
    80005030:	d70080e7          	jalr	-656(ra) # 80004d9c <readi>
    80005034:	47c1                	li	a5,16
    80005036:	fcf518e3          	bne	a0,a5,80005006 <dirlookup+0x3a>
    if(de.inum == 0)
    8000503a:	fc045783          	lhu	a5,-64(s0)
    8000503e:	dfe1                	beqz	a5,80005016 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80005040:	fc240593          	addi	a1,s0,-62
    80005044:	854e                	mv	a0,s3
    80005046:	00000097          	auipc	ra,0x0
    8000504a:	f6c080e7          	jalr	-148(ra) # 80004fb2 <namecmp>
    8000504e:	f561                	bnez	a0,80005016 <dirlookup+0x4a>
      if(poff)
    80005050:	000a0463          	beqz	s4,80005058 <dirlookup+0x8c>
        *poff = off;
    80005054:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80005058:	fc045583          	lhu	a1,-64(s0)
    8000505c:	00092503          	lw	a0,0(s2)
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	754080e7          	jalr	1876(ra) # 800047b4 <iget>
    80005068:	a011                	j	8000506c <dirlookup+0xa0>
  return 0;
    8000506a:	4501                	li	a0,0
}
    8000506c:	70e2                	ld	ra,56(sp)
    8000506e:	7442                	ld	s0,48(sp)
    80005070:	74a2                	ld	s1,40(sp)
    80005072:	7902                	ld	s2,32(sp)
    80005074:	69e2                	ld	s3,24(sp)
    80005076:	6a42                	ld	s4,16(sp)
    80005078:	6121                	addi	sp,sp,64
    8000507a:	8082                	ret

000000008000507c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000507c:	711d                	addi	sp,sp,-96
    8000507e:	ec86                	sd	ra,88(sp)
    80005080:	e8a2                	sd	s0,80(sp)
    80005082:	e4a6                	sd	s1,72(sp)
    80005084:	e0ca                	sd	s2,64(sp)
    80005086:	fc4e                	sd	s3,56(sp)
    80005088:	f852                	sd	s4,48(sp)
    8000508a:	f456                	sd	s5,40(sp)
    8000508c:	f05a                	sd	s6,32(sp)
    8000508e:	ec5e                	sd	s7,24(sp)
    80005090:	e862                	sd	s8,16(sp)
    80005092:	e466                	sd	s9,8(sp)
    80005094:	1080                	addi	s0,sp,96
    80005096:	84aa                	mv	s1,a0
    80005098:	8b2e                	mv	s6,a1
    8000509a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000509c:	00054703          	lbu	a4,0(a0)
    800050a0:	02f00793          	li	a5,47
    800050a4:	02f70363          	beq	a4,a5,800050ca <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	b1c080e7          	jalr	-1252(ra) # 80001bc4 <myproc>
    800050b0:	18053503          	ld	a0,384(a0)
    800050b4:	00000097          	auipc	ra,0x0
    800050b8:	9f6080e7          	jalr	-1546(ra) # 80004aaa <idup>
    800050bc:	89aa                	mv	s3,a0
  while(*path == '/')
    800050be:	02f00913          	li	s2,47
  len = path - s;
    800050c2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800050c4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800050c6:	4c05                	li	s8,1
    800050c8:	a865                	j	80005180 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800050ca:	4585                	li	a1,1
    800050cc:	4505                	li	a0,1
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	6e6080e7          	jalr	1766(ra) # 800047b4 <iget>
    800050d6:	89aa                	mv	s3,a0
    800050d8:	b7dd                	j	800050be <namex+0x42>
      iunlockput(ip);
    800050da:	854e                	mv	a0,s3
    800050dc:	00000097          	auipc	ra,0x0
    800050e0:	c6e080e7          	jalr	-914(ra) # 80004d4a <iunlockput>
      return 0;
    800050e4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800050e6:	854e                	mv	a0,s3
    800050e8:	60e6                	ld	ra,88(sp)
    800050ea:	6446                	ld	s0,80(sp)
    800050ec:	64a6                	ld	s1,72(sp)
    800050ee:	6906                	ld	s2,64(sp)
    800050f0:	79e2                	ld	s3,56(sp)
    800050f2:	7a42                	ld	s4,48(sp)
    800050f4:	7aa2                	ld	s5,40(sp)
    800050f6:	7b02                	ld	s6,32(sp)
    800050f8:	6be2                	ld	s7,24(sp)
    800050fa:	6c42                	ld	s8,16(sp)
    800050fc:	6ca2                	ld	s9,8(sp)
    800050fe:	6125                	addi	sp,sp,96
    80005100:	8082                	ret
      iunlock(ip);
    80005102:	854e                	mv	a0,s3
    80005104:	00000097          	auipc	ra,0x0
    80005108:	aa6080e7          	jalr	-1370(ra) # 80004baa <iunlock>
      return ip;
    8000510c:	bfe9                	j	800050e6 <namex+0x6a>
      iunlockput(ip);
    8000510e:	854e                	mv	a0,s3
    80005110:	00000097          	auipc	ra,0x0
    80005114:	c3a080e7          	jalr	-966(ra) # 80004d4a <iunlockput>
      return 0;
    80005118:	89d2                	mv	s3,s4
    8000511a:	b7f1                	j	800050e6 <namex+0x6a>
  len = path - s;
    8000511c:	40b48633          	sub	a2,s1,a1
    80005120:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80005124:	094cd463          	bge	s9,s4,800051ac <namex+0x130>
    memmove(name, s, DIRSIZ);
    80005128:	4639                	li	a2,14
    8000512a:	8556                	mv	a0,s5
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	c14080e7          	jalr	-1004(ra) # 80000d40 <memmove>
  while(*path == '/')
    80005134:	0004c783          	lbu	a5,0(s1)
    80005138:	01279763          	bne	a5,s2,80005146 <namex+0xca>
    path++;
    8000513c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000513e:	0004c783          	lbu	a5,0(s1)
    80005142:	ff278de3          	beq	a5,s2,8000513c <namex+0xc0>
    ilock(ip);
    80005146:	854e                	mv	a0,s3
    80005148:	00000097          	auipc	ra,0x0
    8000514c:	9a0080e7          	jalr	-1632(ra) # 80004ae8 <ilock>
    if(ip->type != T_DIR){
    80005150:	04499783          	lh	a5,68(s3)
    80005154:	f98793e3          	bne	a5,s8,800050da <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80005158:	000b0563          	beqz	s6,80005162 <namex+0xe6>
    8000515c:	0004c783          	lbu	a5,0(s1)
    80005160:	d3cd                	beqz	a5,80005102 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80005162:	865e                	mv	a2,s7
    80005164:	85d6                	mv	a1,s5
    80005166:	854e                	mv	a0,s3
    80005168:	00000097          	auipc	ra,0x0
    8000516c:	e64080e7          	jalr	-412(ra) # 80004fcc <dirlookup>
    80005170:	8a2a                	mv	s4,a0
    80005172:	dd51                	beqz	a0,8000510e <namex+0x92>
    iunlockput(ip);
    80005174:	854e                	mv	a0,s3
    80005176:	00000097          	auipc	ra,0x0
    8000517a:	bd4080e7          	jalr	-1068(ra) # 80004d4a <iunlockput>
    ip = next;
    8000517e:	89d2                	mv	s3,s4
  while(*path == '/')
    80005180:	0004c783          	lbu	a5,0(s1)
    80005184:	05279763          	bne	a5,s2,800051d2 <namex+0x156>
    path++;
    80005188:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000518a:	0004c783          	lbu	a5,0(s1)
    8000518e:	ff278de3          	beq	a5,s2,80005188 <namex+0x10c>
  if(*path == 0)
    80005192:	c79d                	beqz	a5,800051c0 <namex+0x144>
    path++;
    80005194:	85a6                	mv	a1,s1
  len = path - s;
    80005196:	8a5e                	mv	s4,s7
    80005198:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000519a:	01278963          	beq	a5,s2,800051ac <namex+0x130>
    8000519e:	dfbd                	beqz	a5,8000511c <namex+0xa0>
    path++;
    800051a0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800051a2:	0004c783          	lbu	a5,0(s1)
    800051a6:	ff279ce3          	bne	a5,s2,8000519e <namex+0x122>
    800051aa:	bf8d                	j	8000511c <namex+0xa0>
    memmove(name, s, len);
    800051ac:	2601                	sext.w	a2,a2
    800051ae:	8556                	mv	a0,s5
    800051b0:	ffffc097          	auipc	ra,0xffffc
    800051b4:	b90080e7          	jalr	-1136(ra) # 80000d40 <memmove>
    name[len] = 0;
    800051b8:	9a56                	add	s4,s4,s5
    800051ba:	000a0023          	sb	zero,0(s4)
    800051be:	bf9d                	j	80005134 <namex+0xb8>
  if(nameiparent){
    800051c0:	f20b03e3          	beqz	s6,800050e6 <namex+0x6a>
    iput(ip);
    800051c4:	854e                	mv	a0,s3
    800051c6:	00000097          	auipc	ra,0x0
    800051ca:	adc080e7          	jalr	-1316(ra) # 80004ca2 <iput>
    return 0;
    800051ce:	4981                	li	s3,0
    800051d0:	bf19                	j	800050e6 <namex+0x6a>
  if(*path == 0)
    800051d2:	d7fd                	beqz	a5,800051c0 <namex+0x144>
  while(*path != '/' && *path != 0)
    800051d4:	0004c783          	lbu	a5,0(s1)
    800051d8:	85a6                	mv	a1,s1
    800051da:	b7d1                	j	8000519e <namex+0x122>

00000000800051dc <dirlink>:
{
    800051dc:	7139                	addi	sp,sp,-64
    800051de:	fc06                	sd	ra,56(sp)
    800051e0:	f822                	sd	s0,48(sp)
    800051e2:	f426                	sd	s1,40(sp)
    800051e4:	f04a                	sd	s2,32(sp)
    800051e6:	ec4e                	sd	s3,24(sp)
    800051e8:	e852                	sd	s4,16(sp)
    800051ea:	0080                	addi	s0,sp,64
    800051ec:	892a                	mv	s2,a0
    800051ee:	8a2e                	mv	s4,a1
    800051f0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800051f2:	4601                	li	a2,0
    800051f4:	00000097          	auipc	ra,0x0
    800051f8:	dd8080e7          	jalr	-552(ra) # 80004fcc <dirlookup>
    800051fc:	e93d                	bnez	a0,80005272 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800051fe:	04c92483          	lw	s1,76(s2)
    80005202:	c49d                	beqz	s1,80005230 <dirlink+0x54>
    80005204:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005206:	4741                	li	a4,16
    80005208:	86a6                	mv	a3,s1
    8000520a:	fc040613          	addi	a2,s0,-64
    8000520e:	4581                	li	a1,0
    80005210:	854a                	mv	a0,s2
    80005212:	00000097          	auipc	ra,0x0
    80005216:	b8a080e7          	jalr	-1142(ra) # 80004d9c <readi>
    8000521a:	47c1                	li	a5,16
    8000521c:	06f51163          	bne	a0,a5,8000527e <dirlink+0xa2>
    if(de.inum == 0)
    80005220:	fc045783          	lhu	a5,-64(s0)
    80005224:	c791                	beqz	a5,80005230 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005226:	24c1                	addiw	s1,s1,16
    80005228:	04c92783          	lw	a5,76(s2)
    8000522c:	fcf4ede3          	bltu	s1,a5,80005206 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80005230:	4639                	li	a2,14
    80005232:	85d2                	mv	a1,s4
    80005234:	fc240513          	addi	a0,s0,-62
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	bbc080e7          	jalr	-1092(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80005240:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005244:	4741                	li	a4,16
    80005246:	86a6                	mv	a3,s1
    80005248:	fc040613          	addi	a2,s0,-64
    8000524c:	4581                	li	a1,0
    8000524e:	854a                	mv	a0,s2
    80005250:	00000097          	auipc	ra,0x0
    80005254:	c44080e7          	jalr	-956(ra) # 80004e94 <writei>
    80005258:	872a                	mv	a4,a0
    8000525a:	47c1                	li	a5,16
  return 0;
    8000525c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000525e:	02f71863          	bne	a4,a5,8000528e <dirlink+0xb2>
}
    80005262:	70e2                	ld	ra,56(sp)
    80005264:	7442                	ld	s0,48(sp)
    80005266:	74a2                	ld	s1,40(sp)
    80005268:	7902                	ld	s2,32(sp)
    8000526a:	69e2                	ld	s3,24(sp)
    8000526c:	6a42                	ld	s4,16(sp)
    8000526e:	6121                	addi	sp,sp,64
    80005270:	8082                	ret
    iput(ip);
    80005272:	00000097          	auipc	ra,0x0
    80005276:	a30080e7          	jalr	-1488(ra) # 80004ca2 <iput>
    return -1;
    8000527a:	557d                	li	a0,-1
    8000527c:	b7dd                	j	80005262 <dirlink+0x86>
      panic("dirlink read");
    8000527e:	00004517          	auipc	a0,0x4
    80005282:	5b250513          	addi	a0,a0,1458 # 80009830 <syscalls+0x1f0>
    80005286:	ffffb097          	auipc	ra,0xffffb
    8000528a:	2b8080e7          	jalr	696(ra) # 8000053e <panic>
    panic("dirlink");
    8000528e:	00004517          	auipc	a0,0x4
    80005292:	6b250513          	addi	a0,a0,1714 # 80009940 <syscalls+0x300>
    80005296:	ffffb097          	auipc	ra,0xffffb
    8000529a:	2a8080e7          	jalr	680(ra) # 8000053e <panic>

000000008000529e <namei>:

struct inode*
namei(char *path)
{
    8000529e:	1101                	addi	sp,sp,-32
    800052a0:	ec06                	sd	ra,24(sp)
    800052a2:	e822                	sd	s0,16(sp)
    800052a4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800052a6:	fe040613          	addi	a2,s0,-32
    800052aa:	4581                	li	a1,0
    800052ac:	00000097          	auipc	ra,0x0
    800052b0:	dd0080e7          	jalr	-560(ra) # 8000507c <namex>
}
    800052b4:	60e2                	ld	ra,24(sp)
    800052b6:	6442                	ld	s0,16(sp)
    800052b8:	6105                	addi	sp,sp,32
    800052ba:	8082                	ret

00000000800052bc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800052bc:	1141                	addi	sp,sp,-16
    800052be:	e406                	sd	ra,8(sp)
    800052c0:	e022                	sd	s0,0(sp)
    800052c2:	0800                	addi	s0,sp,16
    800052c4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800052c6:	4585                	li	a1,1
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	db4080e7          	jalr	-588(ra) # 8000507c <namex>
}
    800052d0:	60a2                	ld	ra,8(sp)
    800052d2:	6402                	ld	s0,0(sp)
    800052d4:	0141                	addi	sp,sp,16
    800052d6:	8082                	ret

00000000800052d8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800052d8:	1101                	addi	sp,sp,-32
    800052da:	ec06                	sd	ra,24(sp)
    800052dc:	e822                	sd	s0,16(sp)
    800052de:	e426                	sd	s1,8(sp)
    800052e0:	e04a                	sd	s2,0(sp)
    800052e2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800052e4:	0001e917          	auipc	s2,0x1e
    800052e8:	c2c90913          	addi	s2,s2,-980 # 80022f10 <log>
    800052ec:	01892583          	lw	a1,24(s2)
    800052f0:	02892503          	lw	a0,40(s2)
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	ff2080e7          	jalr	-14(ra) # 800042e6 <bread>
    800052fc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800052fe:	02c92683          	lw	a3,44(s2)
    80005302:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80005304:	02d05763          	blez	a3,80005332 <write_head+0x5a>
    80005308:	0001e797          	auipc	a5,0x1e
    8000530c:	c3878793          	addi	a5,a5,-968 # 80022f40 <log+0x30>
    80005310:	05c50713          	addi	a4,a0,92
    80005314:	36fd                	addiw	a3,a3,-1
    80005316:	1682                	slli	a3,a3,0x20
    80005318:	9281                	srli	a3,a3,0x20
    8000531a:	068a                	slli	a3,a3,0x2
    8000531c:	0001e617          	auipc	a2,0x1e
    80005320:	c2860613          	addi	a2,a2,-984 # 80022f44 <log+0x34>
    80005324:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80005326:	4390                	lw	a2,0(a5)
    80005328:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000532a:	0791                	addi	a5,a5,4
    8000532c:	0711                	addi	a4,a4,4
    8000532e:	fed79ce3          	bne	a5,a3,80005326 <write_head+0x4e>
  }
  bwrite(buf);
    80005332:	8526                	mv	a0,s1
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	0a4080e7          	jalr	164(ra) # 800043d8 <bwrite>
  brelse(buf);
    8000533c:	8526                	mv	a0,s1
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	0d8080e7          	jalr	216(ra) # 80004416 <brelse>
}
    80005346:	60e2                	ld	ra,24(sp)
    80005348:	6442                	ld	s0,16(sp)
    8000534a:	64a2                	ld	s1,8(sp)
    8000534c:	6902                	ld	s2,0(sp)
    8000534e:	6105                	addi	sp,sp,32
    80005350:	8082                	ret

0000000080005352 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80005352:	0001e797          	auipc	a5,0x1e
    80005356:	bea7a783          	lw	a5,-1046(a5) # 80022f3c <log+0x2c>
    8000535a:	0af05d63          	blez	a5,80005414 <install_trans+0xc2>
{
    8000535e:	7139                	addi	sp,sp,-64
    80005360:	fc06                	sd	ra,56(sp)
    80005362:	f822                	sd	s0,48(sp)
    80005364:	f426                	sd	s1,40(sp)
    80005366:	f04a                	sd	s2,32(sp)
    80005368:	ec4e                	sd	s3,24(sp)
    8000536a:	e852                	sd	s4,16(sp)
    8000536c:	e456                	sd	s5,8(sp)
    8000536e:	e05a                	sd	s6,0(sp)
    80005370:	0080                	addi	s0,sp,64
    80005372:	8b2a                	mv	s6,a0
    80005374:	0001ea97          	auipc	s5,0x1e
    80005378:	bcca8a93          	addi	s5,s5,-1076 # 80022f40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000537c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000537e:	0001e997          	auipc	s3,0x1e
    80005382:	b9298993          	addi	s3,s3,-1134 # 80022f10 <log>
    80005386:	a035                	j	800053b2 <install_trans+0x60>
      bunpin(dbuf);
    80005388:	8526                	mv	a0,s1
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	166080e7          	jalr	358(ra) # 800044f0 <bunpin>
    brelse(lbuf);
    80005392:	854a                	mv	a0,s2
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	082080e7          	jalr	130(ra) # 80004416 <brelse>
    brelse(dbuf);
    8000539c:	8526                	mv	a0,s1
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	078080e7          	jalr	120(ra) # 80004416 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800053a6:	2a05                	addiw	s4,s4,1
    800053a8:	0a91                	addi	s5,s5,4
    800053aa:	02c9a783          	lw	a5,44(s3)
    800053ae:	04fa5963          	bge	s4,a5,80005400 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800053b2:	0189a583          	lw	a1,24(s3)
    800053b6:	014585bb          	addw	a1,a1,s4
    800053ba:	2585                	addiw	a1,a1,1
    800053bc:	0289a503          	lw	a0,40(s3)
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	f26080e7          	jalr	-218(ra) # 800042e6 <bread>
    800053c8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800053ca:	000aa583          	lw	a1,0(s5)
    800053ce:	0289a503          	lw	a0,40(s3)
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	f14080e7          	jalr	-236(ra) # 800042e6 <bread>
    800053da:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800053dc:	40000613          	li	a2,1024
    800053e0:	05890593          	addi	a1,s2,88
    800053e4:	05850513          	addi	a0,a0,88
    800053e8:	ffffc097          	auipc	ra,0xffffc
    800053ec:	958080e7          	jalr	-1704(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800053f0:	8526                	mv	a0,s1
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	fe6080e7          	jalr	-26(ra) # 800043d8 <bwrite>
    if(recovering == 0)
    800053fa:	f80b1ce3          	bnez	s6,80005392 <install_trans+0x40>
    800053fe:	b769                	j	80005388 <install_trans+0x36>
}
    80005400:	70e2                	ld	ra,56(sp)
    80005402:	7442                	ld	s0,48(sp)
    80005404:	74a2                	ld	s1,40(sp)
    80005406:	7902                	ld	s2,32(sp)
    80005408:	69e2                	ld	s3,24(sp)
    8000540a:	6a42                	ld	s4,16(sp)
    8000540c:	6aa2                	ld	s5,8(sp)
    8000540e:	6b02                	ld	s6,0(sp)
    80005410:	6121                	addi	sp,sp,64
    80005412:	8082                	ret
    80005414:	8082                	ret

0000000080005416 <initlog>:
{
    80005416:	7179                	addi	sp,sp,-48
    80005418:	f406                	sd	ra,40(sp)
    8000541a:	f022                	sd	s0,32(sp)
    8000541c:	ec26                	sd	s1,24(sp)
    8000541e:	e84a                	sd	s2,16(sp)
    80005420:	e44e                	sd	s3,8(sp)
    80005422:	1800                	addi	s0,sp,48
    80005424:	892a                	mv	s2,a0
    80005426:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80005428:	0001e497          	auipc	s1,0x1e
    8000542c:	ae848493          	addi	s1,s1,-1304 # 80022f10 <log>
    80005430:	00004597          	auipc	a1,0x4
    80005434:	41058593          	addi	a1,a1,1040 # 80009840 <syscalls+0x200>
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffb097          	auipc	ra,0xffffb
    8000543e:	71a080e7          	jalr	1818(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80005442:	0149a583          	lw	a1,20(s3)
    80005446:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80005448:	0109a783          	lw	a5,16(s3)
    8000544c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000544e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80005452:	854a                	mv	a0,s2
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	e92080e7          	jalr	-366(ra) # 800042e6 <bread>
  log.lh.n = lh->n;
    8000545c:	4d3c                	lw	a5,88(a0)
    8000545e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80005460:	02f05563          	blez	a5,8000548a <initlog+0x74>
    80005464:	05c50713          	addi	a4,a0,92
    80005468:	0001e697          	auipc	a3,0x1e
    8000546c:	ad868693          	addi	a3,a3,-1320 # 80022f40 <log+0x30>
    80005470:	37fd                	addiw	a5,a5,-1
    80005472:	1782                	slli	a5,a5,0x20
    80005474:	9381                	srli	a5,a5,0x20
    80005476:	078a                	slli	a5,a5,0x2
    80005478:	06050613          	addi	a2,a0,96
    8000547c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000547e:	4310                	lw	a2,0(a4)
    80005480:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80005482:	0711                	addi	a4,a4,4
    80005484:	0691                	addi	a3,a3,4
    80005486:	fef71ce3          	bne	a4,a5,8000547e <initlog+0x68>
  brelse(buf);
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	f8c080e7          	jalr	-116(ra) # 80004416 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80005492:	4505                	li	a0,1
    80005494:	00000097          	auipc	ra,0x0
    80005498:	ebe080e7          	jalr	-322(ra) # 80005352 <install_trans>
  log.lh.n = 0;
    8000549c:	0001e797          	auipc	a5,0x1e
    800054a0:	aa07a023          	sw	zero,-1376(a5) # 80022f3c <log+0x2c>
  write_head(); // clear the log
    800054a4:	00000097          	auipc	ra,0x0
    800054a8:	e34080e7          	jalr	-460(ra) # 800052d8 <write_head>
}
    800054ac:	70a2                	ld	ra,40(sp)
    800054ae:	7402                	ld	s0,32(sp)
    800054b0:	64e2                	ld	s1,24(sp)
    800054b2:	6942                	ld	s2,16(sp)
    800054b4:	69a2                	ld	s3,8(sp)
    800054b6:	6145                	addi	sp,sp,48
    800054b8:	8082                	ret

00000000800054ba <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800054ba:	1101                	addi	sp,sp,-32
    800054bc:	ec06                	sd	ra,24(sp)
    800054be:	e822                	sd	s0,16(sp)
    800054c0:	e426                	sd	s1,8(sp)
    800054c2:	e04a                	sd	s2,0(sp)
    800054c4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800054c6:	0001e517          	auipc	a0,0x1e
    800054ca:	a4a50513          	addi	a0,a0,-1462 # 80022f10 <log>
    800054ce:	ffffb097          	auipc	ra,0xffffb
    800054d2:	716080e7          	jalr	1814(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800054d6:	0001e497          	auipc	s1,0x1e
    800054da:	a3a48493          	addi	s1,s1,-1478 # 80022f10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800054de:	4979                	li	s2,30
    800054e0:	a039                	j	800054ee <begin_op+0x34>
      sleep(&log, &log.lock);
    800054e2:	85a6                	mv	a1,s1
    800054e4:	8526                	mv	a0,s1
    800054e6:	ffffd097          	auipc	ra,0xffffd
    800054ea:	6fe080e7          	jalr	1790(ra) # 80002be4 <sleep>
    if(log.committing){
    800054ee:	50dc                	lw	a5,36(s1)
    800054f0:	fbed                	bnez	a5,800054e2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800054f2:	509c                	lw	a5,32(s1)
    800054f4:	0017871b          	addiw	a4,a5,1
    800054f8:	0007069b          	sext.w	a3,a4
    800054fc:	0027179b          	slliw	a5,a4,0x2
    80005500:	9fb9                	addw	a5,a5,a4
    80005502:	0017979b          	slliw	a5,a5,0x1
    80005506:	54d8                	lw	a4,44(s1)
    80005508:	9fb9                	addw	a5,a5,a4
    8000550a:	00f95963          	bge	s2,a5,8000551c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000550e:	85a6                	mv	a1,s1
    80005510:	8526                	mv	a0,s1
    80005512:	ffffd097          	auipc	ra,0xffffd
    80005516:	6d2080e7          	jalr	1746(ra) # 80002be4 <sleep>
    8000551a:	bfd1                	j	800054ee <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000551c:	0001e517          	auipc	a0,0x1e
    80005520:	9f450513          	addi	a0,a0,-1548 # 80022f10 <log>
    80005524:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80005526:	ffffb097          	auipc	ra,0xffffb
    8000552a:	772080e7          	jalr	1906(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000552e:	60e2                	ld	ra,24(sp)
    80005530:	6442                	ld	s0,16(sp)
    80005532:	64a2                	ld	s1,8(sp)
    80005534:	6902                	ld	s2,0(sp)
    80005536:	6105                	addi	sp,sp,32
    80005538:	8082                	ret

000000008000553a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000553a:	7139                	addi	sp,sp,-64
    8000553c:	fc06                	sd	ra,56(sp)
    8000553e:	f822                	sd	s0,48(sp)
    80005540:	f426                	sd	s1,40(sp)
    80005542:	f04a                	sd	s2,32(sp)
    80005544:	ec4e                	sd	s3,24(sp)
    80005546:	e852                	sd	s4,16(sp)
    80005548:	e456                	sd	s5,8(sp)
    8000554a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000554c:	0001e497          	auipc	s1,0x1e
    80005550:	9c448493          	addi	s1,s1,-1596 # 80022f10 <log>
    80005554:	8526                	mv	a0,s1
    80005556:	ffffb097          	auipc	ra,0xffffb
    8000555a:	68e080e7          	jalr	1678(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000555e:	509c                	lw	a5,32(s1)
    80005560:	37fd                	addiw	a5,a5,-1
    80005562:	0007891b          	sext.w	s2,a5
    80005566:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80005568:	50dc                	lw	a5,36(s1)
    8000556a:	efb9                	bnez	a5,800055c8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000556c:	06091663          	bnez	s2,800055d8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80005570:	0001e497          	auipc	s1,0x1e
    80005574:	9a048493          	addi	s1,s1,-1632 # 80022f10 <log>
    80005578:	4785                	li	a5,1
    8000557a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffb097          	auipc	ra,0xffffb
    80005582:	71a080e7          	jalr	1818(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80005586:	54dc                	lw	a5,44(s1)
    80005588:	06f04763          	bgtz	a5,800055f6 <end_op+0xbc>
    acquire(&log.lock);
    8000558c:	0001e497          	auipc	s1,0x1e
    80005590:	98448493          	addi	s1,s1,-1660 # 80022f10 <log>
    80005594:	8526                	mv	a0,s1
    80005596:	ffffb097          	auipc	ra,0xffffb
    8000559a:	64e080e7          	jalr	1614(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000559e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800055a2:	8526                	mv	a0,s1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	9a6080e7          	jalr	-1626(ra) # 80002f4a <wakeup>
    release(&log.lock);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffb097          	auipc	ra,0xffffb
    800055b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
}
    800055b6:	70e2                	ld	ra,56(sp)
    800055b8:	7442                	ld	s0,48(sp)
    800055ba:	74a2                	ld	s1,40(sp)
    800055bc:	7902                	ld	s2,32(sp)
    800055be:	69e2                	ld	s3,24(sp)
    800055c0:	6a42                	ld	s4,16(sp)
    800055c2:	6aa2                	ld	s5,8(sp)
    800055c4:	6121                	addi	sp,sp,64
    800055c6:	8082                	ret
    panic("log.committing");
    800055c8:	00004517          	auipc	a0,0x4
    800055cc:	28050513          	addi	a0,a0,640 # 80009848 <syscalls+0x208>
    800055d0:	ffffb097          	auipc	ra,0xffffb
    800055d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>
    wakeup(&log);
    800055d8:	0001e497          	auipc	s1,0x1e
    800055dc:	93848493          	addi	s1,s1,-1736 # 80022f10 <log>
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	968080e7          	jalr	-1688(ra) # 80002f4a <wakeup>
  release(&log.lock);
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffb097          	auipc	ra,0xffffb
    800055f0:	6ac080e7          	jalr	1708(ra) # 80000c98 <release>
  if(do_commit){
    800055f4:	b7c9                	j	800055b6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800055f6:	0001ea97          	auipc	s5,0x1e
    800055fa:	94aa8a93          	addi	s5,s5,-1718 # 80022f40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800055fe:	0001ea17          	auipc	s4,0x1e
    80005602:	912a0a13          	addi	s4,s4,-1774 # 80022f10 <log>
    80005606:	018a2583          	lw	a1,24(s4)
    8000560a:	012585bb          	addw	a1,a1,s2
    8000560e:	2585                	addiw	a1,a1,1
    80005610:	028a2503          	lw	a0,40(s4)
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	cd2080e7          	jalr	-814(ra) # 800042e6 <bread>
    8000561c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000561e:	000aa583          	lw	a1,0(s5)
    80005622:	028a2503          	lw	a0,40(s4)
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	cc0080e7          	jalr	-832(ra) # 800042e6 <bread>
    8000562e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005630:	40000613          	li	a2,1024
    80005634:	05850593          	addi	a1,a0,88
    80005638:	05848513          	addi	a0,s1,88
    8000563c:	ffffb097          	auipc	ra,0xffffb
    80005640:	704080e7          	jalr	1796(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80005644:	8526                	mv	a0,s1
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	d92080e7          	jalr	-622(ra) # 800043d8 <bwrite>
    brelse(from);
    8000564e:	854e                	mv	a0,s3
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	dc6080e7          	jalr	-570(ra) # 80004416 <brelse>
    brelse(to);
    80005658:	8526                	mv	a0,s1
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	dbc080e7          	jalr	-580(ra) # 80004416 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005662:	2905                	addiw	s2,s2,1
    80005664:	0a91                	addi	s5,s5,4
    80005666:	02ca2783          	lw	a5,44(s4)
    8000566a:	f8f94ee3          	blt	s2,a5,80005606 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000566e:	00000097          	auipc	ra,0x0
    80005672:	c6a080e7          	jalr	-918(ra) # 800052d8 <write_head>
    install_trans(0); // Now install writes to home locations
    80005676:	4501                	li	a0,0
    80005678:	00000097          	auipc	ra,0x0
    8000567c:	cda080e7          	jalr	-806(ra) # 80005352 <install_trans>
    log.lh.n = 0;
    80005680:	0001e797          	auipc	a5,0x1e
    80005684:	8a07ae23          	sw	zero,-1860(a5) # 80022f3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80005688:	00000097          	auipc	ra,0x0
    8000568c:	c50080e7          	jalr	-944(ra) # 800052d8 <write_head>
    80005690:	bdf5                	j	8000558c <end_op+0x52>

0000000080005692 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80005692:	1101                	addi	sp,sp,-32
    80005694:	ec06                	sd	ra,24(sp)
    80005696:	e822                	sd	s0,16(sp)
    80005698:	e426                	sd	s1,8(sp)
    8000569a:	e04a                	sd	s2,0(sp)
    8000569c:	1000                	addi	s0,sp,32
    8000569e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800056a0:	0001e917          	auipc	s2,0x1e
    800056a4:	87090913          	addi	s2,s2,-1936 # 80022f10 <log>
    800056a8:	854a                	mv	a0,s2
    800056aa:	ffffb097          	auipc	ra,0xffffb
    800056ae:	53a080e7          	jalr	1338(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800056b2:	02c92603          	lw	a2,44(s2)
    800056b6:	47f5                	li	a5,29
    800056b8:	06c7c563          	blt	a5,a2,80005722 <log_write+0x90>
    800056bc:	0001e797          	auipc	a5,0x1e
    800056c0:	8707a783          	lw	a5,-1936(a5) # 80022f2c <log+0x1c>
    800056c4:	37fd                	addiw	a5,a5,-1
    800056c6:	04f65e63          	bge	a2,a5,80005722 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800056ca:	0001e797          	auipc	a5,0x1e
    800056ce:	8667a783          	lw	a5,-1946(a5) # 80022f30 <log+0x20>
    800056d2:	06f05063          	blez	a5,80005732 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800056d6:	4781                	li	a5,0
    800056d8:	06c05563          	blez	a2,80005742 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800056dc:	44cc                	lw	a1,12(s1)
    800056de:	0001e717          	auipc	a4,0x1e
    800056e2:	86270713          	addi	a4,a4,-1950 # 80022f40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800056e6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800056e8:	4314                	lw	a3,0(a4)
    800056ea:	04b68c63          	beq	a3,a1,80005742 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800056ee:	2785                	addiw	a5,a5,1
    800056f0:	0711                	addi	a4,a4,4
    800056f2:	fef61be3          	bne	a2,a5,800056e8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800056f6:	0621                	addi	a2,a2,8
    800056f8:	060a                	slli	a2,a2,0x2
    800056fa:	0001e797          	auipc	a5,0x1e
    800056fe:	81678793          	addi	a5,a5,-2026 # 80022f10 <log>
    80005702:	963e                	add	a2,a2,a5
    80005704:	44dc                	lw	a5,12(s1)
    80005706:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005708:	8526                	mv	a0,s1
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	daa080e7          	jalr	-598(ra) # 800044b4 <bpin>
    log.lh.n++;
    80005712:	0001d717          	auipc	a4,0x1d
    80005716:	7fe70713          	addi	a4,a4,2046 # 80022f10 <log>
    8000571a:	575c                	lw	a5,44(a4)
    8000571c:	2785                	addiw	a5,a5,1
    8000571e:	d75c                	sw	a5,44(a4)
    80005720:	a835                	j	8000575c <log_write+0xca>
    panic("too big a transaction");
    80005722:	00004517          	auipc	a0,0x4
    80005726:	13650513          	addi	a0,a0,310 # 80009858 <syscalls+0x218>
    8000572a:	ffffb097          	auipc	ra,0xffffb
    8000572e:	e14080e7          	jalr	-492(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80005732:	00004517          	auipc	a0,0x4
    80005736:	13e50513          	addi	a0,a0,318 # 80009870 <syscalls+0x230>
    8000573a:	ffffb097          	auipc	ra,0xffffb
    8000573e:	e04080e7          	jalr	-508(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80005742:	00878713          	addi	a4,a5,8
    80005746:	00271693          	slli	a3,a4,0x2
    8000574a:	0001d717          	auipc	a4,0x1d
    8000574e:	7c670713          	addi	a4,a4,1990 # 80022f10 <log>
    80005752:	9736                	add	a4,a4,a3
    80005754:	44d4                	lw	a3,12(s1)
    80005756:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005758:	faf608e3          	beq	a2,a5,80005708 <log_write+0x76>
  }
  release(&log.lock);
    8000575c:	0001d517          	auipc	a0,0x1d
    80005760:	7b450513          	addi	a0,a0,1972 # 80022f10 <log>
    80005764:	ffffb097          	auipc	ra,0xffffb
    80005768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000576c:	60e2                	ld	ra,24(sp)
    8000576e:	6442                	ld	s0,16(sp)
    80005770:	64a2                	ld	s1,8(sp)
    80005772:	6902                	ld	s2,0(sp)
    80005774:	6105                	addi	sp,sp,32
    80005776:	8082                	ret

0000000080005778 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005778:	1101                	addi	sp,sp,-32
    8000577a:	ec06                	sd	ra,24(sp)
    8000577c:	e822                	sd	s0,16(sp)
    8000577e:	e426                	sd	s1,8(sp)
    80005780:	e04a                	sd	s2,0(sp)
    80005782:	1000                	addi	s0,sp,32
    80005784:	84aa                	mv	s1,a0
    80005786:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005788:	00004597          	auipc	a1,0x4
    8000578c:	10858593          	addi	a1,a1,264 # 80009890 <syscalls+0x250>
    80005790:	0521                	addi	a0,a0,8
    80005792:	ffffb097          	auipc	ra,0xffffb
    80005796:	3c2080e7          	jalr	962(ra) # 80000b54 <initlock>
  lk->name = name;
    8000579a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000579e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800057a2:	0204a423          	sw	zero,40(s1)
}
    800057a6:	60e2                	ld	ra,24(sp)
    800057a8:	6442                	ld	s0,16(sp)
    800057aa:	64a2                	ld	s1,8(sp)
    800057ac:	6902                	ld	s2,0(sp)
    800057ae:	6105                	addi	sp,sp,32
    800057b0:	8082                	ret

00000000800057b2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800057b2:	1101                	addi	sp,sp,-32
    800057b4:	ec06                	sd	ra,24(sp)
    800057b6:	e822                	sd	s0,16(sp)
    800057b8:	e426                	sd	s1,8(sp)
    800057ba:	e04a                	sd	s2,0(sp)
    800057bc:	1000                	addi	s0,sp,32
    800057be:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800057c0:	00850913          	addi	s2,a0,8
    800057c4:	854a                	mv	a0,s2
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	41e080e7          	jalr	1054(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800057ce:	409c                	lw	a5,0(s1)
    800057d0:	cb89                	beqz	a5,800057e2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800057d2:	85ca                	mv	a1,s2
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffd097          	auipc	ra,0xffffd
    800057da:	40e080e7          	jalr	1038(ra) # 80002be4 <sleep>
  while (lk->locked) {
    800057de:	409c                	lw	a5,0(s1)
    800057e0:	fbed                	bnez	a5,800057d2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800057e2:	4785                	li	a5,1
    800057e4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800057e6:	ffffc097          	auipc	ra,0xffffc
    800057ea:	3de080e7          	jalr	990(ra) # 80001bc4 <myproc>
    800057ee:	591c                	lw	a5,48(a0)
    800057f0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800057f2:	854a                	mv	a0,s2
    800057f4:	ffffb097          	auipc	ra,0xffffb
    800057f8:	4a4080e7          	jalr	1188(ra) # 80000c98 <release>
}
    800057fc:	60e2                	ld	ra,24(sp)
    800057fe:	6442                	ld	s0,16(sp)
    80005800:	64a2                	ld	s1,8(sp)
    80005802:	6902                	ld	s2,0(sp)
    80005804:	6105                	addi	sp,sp,32
    80005806:	8082                	ret

0000000080005808 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005808:	1101                	addi	sp,sp,-32
    8000580a:	ec06                	sd	ra,24(sp)
    8000580c:	e822                	sd	s0,16(sp)
    8000580e:	e426                	sd	s1,8(sp)
    80005810:	e04a                	sd	s2,0(sp)
    80005812:	1000                	addi	s0,sp,32
    80005814:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005816:	00850913          	addi	s2,a0,8
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffb097          	auipc	ra,0xffffb
    80005820:	3c8080e7          	jalr	968(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80005824:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005828:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffd097          	auipc	ra,0xffffd
    80005832:	71c080e7          	jalr	1820(ra) # 80002f4a <wakeup>
  release(&lk->lk);
    80005836:	854a                	mv	a0,s2
    80005838:	ffffb097          	auipc	ra,0xffffb
    8000583c:	460080e7          	jalr	1120(ra) # 80000c98 <release>
}
    80005840:	60e2                	ld	ra,24(sp)
    80005842:	6442                	ld	s0,16(sp)
    80005844:	64a2                	ld	s1,8(sp)
    80005846:	6902                	ld	s2,0(sp)
    80005848:	6105                	addi	sp,sp,32
    8000584a:	8082                	ret

000000008000584c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000584c:	7179                	addi	sp,sp,-48
    8000584e:	f406                	sd	ra,40(sp)
    80005850:	f022                	sd	s0,32(sp)
    80005852:	ec26                	sd	s1,24(sp)
    80005854:	e84a                	sd	s2,16(sp)
    80005856:	e44e                	sd	s3,8(sp)
    80005858:	1800                	addi	s0,sp,48
    8000585a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000585c:	00850913          	addi	s2,a0,8
    80005860:	854a                	mv	a0,s2
    80005862:	ffffb097          	auipc	ra,0xffffb
    80005866:	382080e7          	jalr	898(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000586a:	409c                	lw	a5,0(s1)
    8000586c:	ef99                	bnez	a5,8000588a <holdingsleep+0x3e>
    8000586e:	4481                	li	s1,0
  release(&lk->lk);
    80005870:	854a                	mv	a0,s2
    80005872:	ffffb097          	auipc	ra,0xffffb
    80005876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
  return r;
}
    8000587a:	8526                	mv	a0,s1
    8000587c:	70a2                	ld	ra,40(sp)
    8000587e:	7402                	ld	s0,32(sp)
    80005880:	64e2                	ld	s1,24(sp)
    80005882:	6942                	ld	s2,16(sp)
    80005884:	69a2                	ld	s3,8(sp)
    80005886:	6145                	addi	sp,sp,48
    80005888:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000588a:	0284a983          	lw	s3,40(s1)
    8000588e:	ffffc097          	auipc	ra,0xffffc
    80005892:	336080e7          	jalr	822(ra) # 80001bc4 <myproc>
    80005896:	5904                	lw	s1,48(a0)
    80005898:	413484b3          	sub	s1,s1,s3
    8000589c:	0014b493          	seqz	s1,s1
    800058a0:	bfc1                	j	80005870 <holdingsleep+0x24>

00000000800058a2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800058a2:	1141                	addi	sp,sp,-16
    800058a4:	e406                	sd	ra,8(sp)
    800058a6:	e022                	sd	s0,0(sp)
    800058a8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800058aa:	00004597          	auipc	a1,0x4
    800058ae:	ff658593          	addi	a1,a1,-10 # 800098a0 <syscalls+0x260>
    800058b2:	0001d517          	auipc	a0,0x1d
    800058b6:	7a650513          	addi	a0,a0,1958 # 80023058 <ftable>
    800058ba:	ffffb097          	auipc	ra,0xffffb
    800058be:	29a080e7          	jalr	666(ra) # 80000b54 <initlock>
}
    800058c2:	60a2                	ld	ra,8(sp)
    800058c4:	6402                	ld	s0,0(sp)
    800058c6:	0141                	addi	sp,sp,16
    800058c8:	8082                	ret

00000000800058ca <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800058ca:	1101                	addi	sp,sp,-32
    800058cc:	ec06                	sd	ra,24(sp)
    800058ce:	e822                	sd	s0,16(sp)
    800058d0:	e426                	sd	s1,8(sp)
    800058d2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800058d4:	0001d517          	auipc	a0,0x1d
    800058d8:	78450513          	addi	a0,a0,1924 # 80023058 <ftable>
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800058e4:	0001d497          	auipc	s1,0x1d
    800058e8:	78c48493          	addi	s1,s1,1932 # 80023070 <ftable+0x18>
    800058ec:	0001e717          	auipc	a4,0x1e
    800058f0:	72470713          	addi	a4,a4,1828 # 80024010 <ftable+0xfb8>
    if(f->ref == 0){
    800058f4:	40dc                	lw	a5,4(s1)
    800058f6:	cf99                	beqz	a5,80005914 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800058f8:	02848493          	addi	s1,s1,40
    800058fc:	fee49ce3          	bne	s1,a4,800058f4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005900:	0001d517          	auipc	a0,0x1d
    80005904:	75850513          	addi	a0,a0,1880 # 80023058 <ftable>
    80005908:	ffffb097          	auipc	ra,0xffffb
    8000590c:	390080e7          	jalr	912(ra) # 80000c98 <release>
  return 0;
    80005910:	4481                	li	s1,0
    80005912:	a819                	j	80005928 <filealloc+0x5e>
      f->ref = 1;
    80005914:	4785                	li	a5,1
    80005916:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005918:	0001d517          	auipc	a0,0x1d
    8000591c:	74050513          	addi	a0,a0,1856 # 80023058 <ftable>
    80005920:	ffffb097          	auipc	ra,0xffffb
    80005924:	378080e7          	jalr	888(ra) # 80000c98 <release>
}
    80005928:	8526                	mv	a0,s1
    8000592a:	60e2                	ld	ra,24(sp)
    8000592c:	6442                	ld	s0,16(sp)
    8000592e:	64a2                	ld	s1,8(sp)
    80005930:	6105                	addi	sp,sp,32
    80005932:	8082                	ret

0000000080005934 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005934:	1101                	addi	sp,sp,-32
    80005936:	ec06                	sd	ra,24(sp)
    80005938:	e822                	sd	s0,16(sp)
    8000593a:	e426                	sd	s1,8(sp)
    8000593c:	1000                	addi	s0,sp,32
    8000593e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005940:	0001d517          	auipc	a0,0x1d
    80005944:	71850513          	addi	a0,a0,1816 # 80023058 <ftable>
    80005948:	ffffb097          	auipc	ra,0xffffb
    8000594c:	29c080e7          	jalr	668(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005950:	40dc                	lw	a5,4(s1)
    80005952:	02f05263          	blez	a5,80005976 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005956:	2785                	addiw	a5,a5,1
    80005958:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000595a:	0001d517          	auipc	a0,0x1d
    8000595e:	6fe50513          	addi	a0,a0,1790 # 80023058 <ftable>
    80005962:	ffffb097          	auipc	ra,0xffffb
    80005966:	336080e7          	jalr	822(ra) # 80000c98 <release>
  return f;
}
    8000596a:	8526                	mv	a0,s1
    8000596c:	60e2                	ld	ra,24(sp)
    8000596e:	6442                	ld	s0,16(sp)
    80005970:	64a2                	ld	s1,8(sp)
    80005972:	6105                	addi	sp,sp,32
    80005974:	8082                	ret
    panic("filedup");
    80005976:	00004517          	auipc	a0,0x4
    8000597a:	f3250513          	addi	a0,a0,-206 # 800098a8 <syscalls+0x268>
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	bc0080e7          	jalr	-1088(ra) # 8000053e <panic>

0000000080005986 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005986:	7139                	addi	sp,sp,-64
    80005988:	fc06                	sd	ra,56(sp)
    8000598a:	f822                	sd	s0,48(sp)
    8000598c:	f426                	sd	s1,40(sp)
    8000598e:	f04a                	sd	s2,32(sp)
    80005990:	ec4e                	sd	s3,24(sp)
    80005992:	e852                	sd	s4,16(sp)
    80005994:	e456                	sd	s5,8(sp)
    80005996:	0080                	addi	s0,sp,64
    80005998:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000599a:	0001d517          	auipc	a0,0x1d
    8000599e:	6be50513          	addi	a0,a0,1726 # 80023058 <ftable>
    800059a2:	ffffb097          	auipc	ra,0xffffb
    800059a6:	242080e7          	jalr	578(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800059aa:	40dc                	lw	a5,4(s1)
    800059ac:	06f05163          	blez	a5,80005a0e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800059b0:	37fd                	addiw	a5,a5,-1
    800059b2:	0007871b          	sext.w	a4,a5
    800059b6:	c0dc                	sw	a5,4(s1)
    800059b8:	06e04363          	bgtz	a4,80005a1e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800059bc:	0004a903          	lw	s2,0(s1)
    800059c0:	0094ca83          	lbu	s5,9(s1)
    800059c4:	0104ba03          	ld	s4,16(s1)
    800059c8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800059cc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800059d0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800059d4:	0001d517          	auipc	a0,0x1d
    800059d8:	68450513          	addi	a0,a0,1668 # 80023058 <ftable>
    800059dc:	ffffb097          	auipc	ra,0xffffb
    800059e0:	2bc080e7          	jalr	700(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800059e4:	4785                	li	a5,1
    800059e6:	04f90d63          	beq	s2,a5,80005a40 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800059ea:	3979                	addiw	s2,s2,-2
    800059ec:	4785                	li	a5,1
    800059ee:	0527e063          	bltu	a5,s2,80005a2e <fileclose+0xa8>
    begin_op();
    800059f2:	00000097          	auipc	ra,0x0
    800059f6:	ac8080e7          	jalr	-1336(ra) # 800054ba <begin_op>
    iput(ff.ip);
    800059fa:	854e                	mv	a0,s3
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	2a6080e7          	jalr	678(ra) # 80004ca2 <iput>
    end_op();
    80005a04:	00000097          	auipc	ra,0x0
    80005a08:	b36080e7          	jalr	-1226(ra) # 8000553a <end_op>
    80005a0c:	a00d                	j	80005a2e <fileclose+0xa8>
    panic("fileclose");
    80005a0e:	00004517          	auipc	a0,0x4
    80005a12:	ea250513          	addi	a0,a0,-350 # 800098b0 <syscalls+0x270>
    80005a16:	ffffb097          	auipc	ra,0xffffb
    80005a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005a1e:	0001d517          	auipc	a0,0x1d
    80005a22:	63a50513          	addi	a0,a0,1594 # 80023058 <ftable>
    80005a26:	ffffb097          	auipc	ra,0xffffb
    80005a2a:	272080e7          	jalr	626(ra) # 80000c98 <release>
  }
}
    80005a2e:	70e2                	ld	ra,56(sp)
    80005a30:	7442                	ld	s0,48(sp)
    80005a32:	74a2                	ld	s1,40(sp)
    80005a34:	7902                	ld	s2,32(sp)
    80005a36:	69e2                	ld	s3,24(sp)
    80005a38:	6a42                	ld	s4,16(sp)
    80005a3a:	6aa2                	ld	s5,8(sp)
    80005a3c:	6121                	addi	sp,sp,64
    80005a3e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005a40:	85d6                	mv	a1,s5
    80005a42:	8552                	mv	a0,s4
    80005a44:	00000097          	auipc	ra,0x0
    80005a48:	34c080e7          	jalr	844(ra) # 80005d90 <pipeclose>
    80005a4c:	b7cd                	j	80005a2e <fileclose+0xa8>

0000000080005a4e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005a4e:	715d                	addi	sp,sp,-80
    80005a50:	e486                	sd	ra,72(sp)
    80005a52:	e0a2                	sd	s0,64(sp)
    80005a54:	fc26                	sd	s1,56(sp)
    80005a56:	f84a                	sd	s2,48(sp)
    80005a58:	f44e                	sd	s3,40(sp)
    80005a5a:	0880                	addi	s0,sp,80
    80005a5c:	84aa                	mv	s1,a0
    80005a5e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005a60:	ffffc097          	auipc	ra,0xffffc
    80005a64:	164080e7          	jalr	356(ra) # 80001bc4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005a68:	409c                	lw	a5,0(s1)
    80005a6a:	37f9                	addiw	a5,a5,-2
    80005a6c:	4705                	li	a4,1
    80005a6e:	04f76763          	bltu	a4,a5,80005abc <filestat+0x6e>
    80005a72:	892a                	mv	s2,a0
    ilock(f->ip);
    80005a74:	6c88                	ld	a0,24(s1)
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	072080e7          	jalr	114(ra) # 80004ae8 <ilock>
    stati(f->ip, &st);
    80005a7e:	fb840593          	addi	a1,s0,-72
    80005a82:	6c88                	ld	a0,24(s1)
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	2ee080e7          	jalr	750(ra) # 80004d72 <stati>
    iunlock(f->ip);
    80005a8c:	6c88                	ld	a0,24(s1)
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	11c080e7          	jalr	284(ra) # 80004baa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005a96:	46e1                	li	a3,24
    80005a98:	fb840613          	addi	a2,s0,-72
    80005a9c:	85ce                	mv	a1,s3
    80005a9e:	08093503          	ld	a0,128(s2)
    80005aa2:	ffffc097          	auipc	ra,0xffffc
    80005aa6:	bd8080e7          	jalr	-1064(ra) # 8000167a <copyout>
    80005aaa:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005aae:	60a6                	ld	ra,72(sp)
    80005ab0:	6406                	ld	s0,64(sp)
    80005ab2:	74e2                	ld	s1,56(sp)
    80005ab4:	7942                	ld	s2,48(sp)
    80005ab6:	79a2                	ld	s3,40(sp)
    80005ab8:	6161                	addi	sp,sp,80
    80005aba:	8082                	ret
  return -1;
    80005abc:	557d                	li	a0,-1
    80005abe:	bfc5                	j	80005aae <filestat+0x60>

0000000080005ac0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005ac0:	7179                	addi	sp,sp,-48
    80005ac2:	f406                	sd	ra,40(sp)
    80005ac4:	f022                	sd	s0,32(sp)
    80005ac6:	ec26                	sd	s1,24(sp)
    80005ac8:	e84a                	sd	s2,16(sp)
    80005aca:	e44e                	sd	s3,8(sp)
    80005acc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005ace:	00854783          	lbu	a5,8(a0)
    80005ad2:	c3d5                	beqz	a5,80005b76 <fileread+0xb6>
    80005ad4:	84aa                	mv	s1,a0
    80005ad6:	89ae                	mv	s3,a1
    80005ad8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005ada:	411c                	lw	a5,0(a0)
    80005adc:	4705                	li	a4,1
    80005ade:	04e78963          	beq	a5,a4,80005b30 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005ae2:	470d                	li	a4,3
    80005ae4:	04e78d63          	beq	a5,a4,80005b3e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005ae8:	4709                	li	a4,2
    80005aea:	06e79e63          	bne	a5,a4,80005b66 <fileread+0xa6>
    ilock(f->ip);
    80005aee:	6d08                	ld	a0,24(a0)
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	ff8080e7          	jalr	-8(ra) # 80004ae8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005af8:	874a                	mv	a4,s2
    80005afa:	5094                	lw	a3,32(s1)
    80005afc:	864e                	mv	a2,s3
    80005afe:	4585                	li	a1,1
    80005b00:	6c88                	ld	a0,24(s1)
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	29a080e7          	jalr	666(ra) # 80004d9c <readi>
    80005b0a:	892a                	mv	s2,a0
    80005b0c:	00a05563          	blez	a0,80005b16 <fileread+0x56>
      f->off += r;
    80005b10:	509c                	lw	a5,32(s1)
    80005b12:	9fa9                	addw	a5,a5,a0
    80005b14:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005b16:	6c88                	ld	a0,24(s1)
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	092080e7          	jalr	146(ra) # 80004baa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005b20:	854a                	mv	a0,s2
    80005b22:	70a2                	ld	ra,40(sp)
    80005b24:	7402                	ld	s0,32(sp)
    80005b26:	64e2                	ld	s1,24(sp)
    80005b28:	6942                	ld	s2,16(sp)
    80005b2a:	69a2                	ld	s3,8(sp)
    80005b2c:	6145                	addi	sp,sp,48
    80005b2e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005b30:	6908                	ld	a0,16(a0)
    80005b32:	00000097          	auipc	ra,0x0
    80005b36:	3c8080e7          	jalr	968(ra) # 80005efa <piperead>
    80005b3a:	892a                	mv	s2,a0
    80005b3c:	b7d5                	j	80005b20 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005b3e:	02451783          	lh	a5,36(a0)
    80005b42:	03079693          	slli	a3,a5,0x30
    80005b46:	92c1                	srli	a3,a3,0x30
    80005b48:	4725                	li	a4,9
    80005b4a:	02d76863          	bltu	a4,a3,80005b7a <fileread+0xba>
    80005b4e:	0792                	slli	a5,a5,0x4
    80005b50:	0001d717          	auipc	a4,0x1d
    80005b54:	46870713          	addi	a4,a4,1128 # 80022fb8 <devsw>
    80005b58:	97ba                	add	a5,a5,a4
    80005b5a:	639c                	ld	a5,0(a5)
    80005b5c:	c38d                	beqz	a5,80005b7e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005b5e:	4505                	li	a0,1
    80005b60:	9782                	jalr	a5
    80005b62:	892a                	mv	s2,a0
    80005b64:	bf75                	j	80005b20 <fileread+0x60>
    panic("fileread");
    80005b66:	00004517          	auipc	a0,0x4
    80005b6a:	d5a50513          	addi	a0,a0,-678 # 800098c0 <syscalls+0x280>
    80005b6e:	ffffb097          	auipc	ra,0xffffb
    80005b72:	9d0080e7          	jalr	-1584(ra) # 8000053e <panic>
    return -1;
    80005b76:	597d                	li	s2,-1
    80005b78:	b765                	j	80005b20 <fileread+0x60>
      return -1;
    80005b7a:	597d                	li	s2,-1
    80005b7c:	b755                	j	80005b20 <fileread+0x60>
    80005b7e:	597d                	li	s2,-1
    80005b80:	b745                	j	80005b20 <fileread+0x60>

0000000080005b82 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005b82:	715d                	addi	sp,sp,-80
    80005b84:	e486                	sd	ra,72(sp)
    80005b86:	e0a2                	sd	s0,64(sp)
    80005b88:	fc26                	sd	s1,56(sp)
    80005b8a:	f84a                	sd	s2,48(sp)
    80005b8c:	f44e                	sd	s3,40(sp)
    80005b8e:	f052                	sd	s4,32(sp)
    80005b90:	ec56                	sd	s5,24(sp)
    80005b92:	e85a                	sd	s6,16(sp)
    80005b94:	e45e                	sd	s7,8(sp)
    80005b96:	e062                	sd	s8,0(sp)
    80005b98:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005b9a:	00954783          	lbu	a5,9(a0)
    80005b9e:	10078663          	beqz	a5,80005caa <filewrite+0x128>
    80005ba2:	892a                	mv	s2,a0
    80005ba4:	8aae                	mv	s5,a1
    80005ba6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005ba8:	411c                	lw	a5,0(a0)
    80005baa:	4705                	li	a4,1
    80005bac:	02e78263          	beq	a5,a4,80005bd0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005bb0:	470d                	li	a4,3
    80005bb2:	02e78663          	beq	a5,a4,80005bde <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005bb6:	4709                	li	a4,2
    80005bb8:	0ee79163          	bne	a5,a4,80005c9a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005bbc:	0ac05d63          	blez	a2,80005c76 <filewrite+0xf4>
    int i = 0;
    80005bc0:	4981                	li	s3,0
    80005bc2:	6b05                	lui	s6,0x1
    80005bc4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005bc8:	6b85                	lui	s7,0x1
    80005bca:	c00b8b9b          	addiw	s7,s7,-1024
    80005bce:	a861                	j	80005c66 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005bd0:	6908                	ld	a0,16(a0)
    80005bd2:	00000097          	auipc	ra,0x0
    80005bd6:	22e080e7          	jalr	558(ra) # 80005e00 <pipewrite>
    80005bda:	8a2a                	mv	s4,a0
    80005bdc:	a045                	j	80005c7c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005bde:	02451783          	lh	a5,36(a0)
    80005be2:	03079693          	slli	a3,a5,0x30
    80005be6:	92c1                	srli	a3,a3,0x30
    80005be8:	4725                	li	a4,9
    80005bea:	0cd76263          	bltu	a4,a3,80005cae <filewrite+0x12c>
    80005bee:	0792                	slli	a5,a5,0x4
    80005bf0:	0001d717          	auipc	a4,0x1d
    80005bf4:	3c870713          	addi	a4,a4,968 # 80022fb8 <devsw>
    80005bf8:	97ba                	add	a5,a5,a4
    80005bfa:	679c                	ld	a5,8(a5)
    80005bfc:	cbdd                	beqz	a5,80005cb2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005bfe:	4505                	li	a0,1
    80005c00:	9782                	jalr	a5
    80005c02:	8a2a                	mv	s4,a0
    80005c04:	a8a5                	j	80005c7c <filewrite+0xfa>
    80005c06:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005c0a:	00000097          	auipc	ra,0x0
    80005c0e:	8b0080e7          	jalr	-1872(ra) # 800054ba <begin_op>
      ilock(f->ip);
    80005c12:	01893503          	ld	a0,24(s2)
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	ed2080e7          	jalr	-302(ra) # 80004ae8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005c1e:	8762                	mv	a4,s8
    80005c20:	02092683          	lw	a3,32(s2)
    80005c24:	01598633          	add	a2,s3,s5
    80005c28:	4585                	li	a1,1
    80005c2a:	01893503          	ld	a0,24(s2)
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	266080e7          	jalr	614(ra) # 80004e94 <writei>
    80005c36:	84aa                	mv	s1,a0
    80005c38:	00a05763          	blez	a0,80005c46 <filewrite+0xc4>
        f->off += r;
    80005c3c:	02092783          	lw	a5,32(s2)
    80005c40:	9fa9                	addw	a5,a5,a0
    80005c42:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005c46:	01893503          	ld	a0,24(s2)
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	f60080e7          	jalr	-160(ra) # 80004baa <iunlock>
      end_op();
    80005c52:	00000097          	auipc	ra,0x0
    80005c56:	8e8080e7          	jalr	-1816(ra) # 8000553a <end_op>

      if(r != n1){
    80005c5a:	009c1f63          	bne	s8,s1,80005c78 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005c5e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005c62:	0149db63          	bge	s3,s4,80005c78 <filewrite+0xf6>
      int n1 = n - i;
    80005c66:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005c6a:	84be                	mv	s1,a5
    80005c6c:	2781                	sext.w	a5,a5
    80005c6e:	f8fb5ce3          	bge	s6,a5,80005c06 <filewrite+0x84>
    80005c72:	84de                	mv	s1,s7
    80005c74:	bf49                	j	80005c06 <filewrite+0x84>
    int i = 0;
    80005c76:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005c78:	013a1f63          	bne	s4,s3,80005c96 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005c7c:	8552                	mv	a0,s4
    80005c7e:	60a6                	ld	ra,72(sp)
    80005c80:	6406                	ld	s0,64(sp)
    80005c82:	74e2                	ld	s1,56(sp)
    80005c84:	7942                	ld	s2,48(sp)
    80005c86:	79a2                	ld	s3,40(sp)
    80005c88:	7a02                	ld	s4,32(sp)
    80005c8a:	6ae2                	ld	s5,24(sp)
    80005c8c:	6b42                	ld	s6,16(sp)
    80005c8e:	6ba2                	ld	s7,8(sp)
    80005c90:	6c02                	ld	s8,0(sp)
    80005c92:	6161                	addi	sp,sp,80
    80005c94:	8082                	ret
    ret = (i == n ? n : -1);
    80005c96:	5a7d                	li	s4,-1
    80005c98:	b7d5                	j	80005c7c <filewrite+0xfa>
    panic("filewrite");
    80005c9a:	00004517          	auipc	a0,0x4
    80005c9e:	c3650513          	addi	a0,a0,-970 # 800098d0 <syscalls+0x290>
    80005ca2:	ffffb097          	auipc	ra,0xffffb
    80005ca6:	89c080e7          	jalr	-1892(ra) # 8000053e <panic>
    return -1;
    80005caa:	5a7d                	li	s4,-1
    80005cac:	bfc1                	j	80005c7c <filewrite+0xfa>
      return -1;
    80005cae:	5a7d                	li	s4,-1
    80005cb0:	b7f1                	j	80005c7c <filewrite+0xfa>
    80005cb2:	5a7d                	li	s4,-1
    80005cb4:	b7e1                	j	80005c7c <filewrite+0xfa>

0000000080005cb6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005cb6:	7179                	addi	sp,sp,-48
    80005cb8:	f406                	sd	ra,40(sp)
    80005cba:	f022                	sd	s0,32(sp)
    80005cbc:	ec26                	sd	s1,24(sp)
    80005cbe:	e84a                	sd	s2,16(sp)
    80005cc0:	e44e                	sd	s3,8(sp)
    80005cc2:	e052                	sd	s4,0(sp)
    80005cc4:	1800                	addi	s0,sp,48
    80005cc6:	84aa                	mv	s1,a0
    80005cc8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005cca:	0005b023          	sd	zero,0(a1)
    80005cce:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005cd2:	00000097          	auipc	ra,0x0
    80005cd6:	bf8080e7          	jalr	-1032(ra) # 800058ca <filealloc>
    80005cda:	e088                	sd	a0,0(s1)
    80005cdc:	c551                	beqz	a0,80005d68 <pipealloc+0xb2>
    80005cde:	00000097          	auipc	ra,0x0
    80005ce2:	bec080e7          	jalr	-1044(ra) # 800058ca <filealloc>
    80005ce6:	00aa3023          	sd	a0,0(s4)
    80005cea:	c92d                	beqz	a0,80005d5c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005cec:	ffffb097          	auipc	ra,0xffffb
    80005cf0:	e08080e7          	jalr	-504(ra) # 80000af4 <kalloc>
    80005cf4:	892a                	mv	s2,a0
    80005cf6:	c125                	beqz	a0,80005d56 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005cf8:	4985                	li	s3,1
    80005cfa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005cfe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005d02:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005d06:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005d0a:	00004597          	auipc	a1,0x4
    80005d0e:	bd658593          	addi	a1,a1,-1066 # 800098e0 <syscalls+0x2a0>
    80005d12:	ffffb097          	auipc	ra,0xffffb
    80005d16:	e42080e7          	jalr	-446(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005d1a:	609c                	ld	a5,0(s1)
    80005d1c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005d20:	609c                	ld	a5,0(s1)
    80005d22:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005d26:	609c                	ld	a5,0(s1)
    80005d28:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005d2c:	609c                	ld	a5,0(s1)
    80005d2e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005d32:	000a3783          	ld	a5,0(s4)
    80005d36:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005d3a:	000a3783          	ld	a5,0(s4)
    80005d3e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005d42:	000a3783          	ld	a5,0(s4)
    80005d46:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005d4a:	000a3783          	ld	a5,0(s4)
    80005d4e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005d52:	4501                	li	a0,0
    80005d54:	a025                	j	80005d7c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005d56:	6088                	ld	a0,0(s1)
    80005d58:	e501                	bnez	a0,80005d60 <pipealloc+0xaa>
    80005d5a:	a039                	j	80005d68 <pipealloc+0xb2>
    80005d5c:	6088                	ld	a0,0(s1)
    80005d5e:	c51d                	beqz	a0,80005d8c <pipealloc+0xd6>
    fileclose(*f0);
    80005d60:	00000097          	auipc	ra,0x0
    80005d64:	c26080e7          	jalr	-986(ra) # 80005986 <fileclose>
  if(*f1)
    80005d68:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005d6c:	557d                	li	a0,-1
  if(*f1)
    80005d6e:	c799                	beqz	a5,80005d7c <pipealloc+0xc6>
    fileclose(*f1);
    80005d70:	853e                	mv	a0,a5
    80005d72:	00000097          	auipc	ra,0x0
    80005d76:	c14080e7          	jalr	-1004(ra) # 80005986 <fileclose>
  return -1;
    80005d7a:	557d                	li	a0,-1
}
    80005d7c:	70a2                	ld	ra,40(sp)
    80005d7e:	7402                	ld	s0,32(sp)
    80005d80:	64e2                	ld	s1,24(sp)
    80005d82:	6942                	ld	s2,16(sp)
    80005d84:	69a2                	ld	s3,8(sp)
    80005d86:	6a02                	ld	s4,0(sp)
    80005d88:	6145                	addi	sp,sp,48
    80005d8a:	8082                	ret
  return -1;
    80005d8c:	557d                	li	a0,-1
    80005d8e:	b7fd                	j	80005d7c <pipealloc+0xc6>

0000000080005d90 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005d90:	1101                	addi	sp,sp,-32
    80005d92:	ec06                	sd	ra,24(sp)
    80005d94:	e822                	sd	s0,16(sp)
    80005d96:	e426                	sd	s1,8(sp)
    80005d98:	e04a                	sd	s2,0(sp)
    80005d9a:	1000                	addi	s0,sp,32
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005da0:	ffffb097          	auipc	ra,0xffffb
    80005da4:	e44080e7          	jalr	-444(ra) # 80000be4 <acquire>
  if(writable){
    80005da8:	02090d63          	beqz	s2,80005de2 <pipeclose+0x52>
    pi->writeopen = 0;
    80005dac:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005db0:	21848513          	addi	a0,s1,536
    80005db4:	ffffd097          	auipc	ra,0xffffd
    80005db8:	196080e7          	jalr	406(ra) # 80002f4a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005dbc:	2204b783          	ld	a5,544(s1)
    80005dc0:	eb95                	bnez	a5,80005df4 <pipeclose+0x64>
    release(&pi->lock);
    80005dc2:	8526                	mv	a0,s1
    80005dc4:	ffffb097          	auipc	ra,0xffffb
    80005dc8:	ed4080e7          	jalr	-300(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005dcc:	8526                	mv	a0,s1
    80005dce:	ffffb097          	auipc	ra,0xffffb
    80005dd2:	c2a080e7          	jalr	-982(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005dd6:	60e2                	ld	ra,24(sp)
    80005dd8:	6442                	ld	s0,16(sp)
    80005dda:	64a2                	ld	s1,8(sp)
    80005ddc:	6902                	ld	s2,0(sp)
    80005dde:	6105                	addi	sp,sp,32
    80005de0:	8082                	ret
    pi->readopen = 0;
    80005de2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005de6:	21c48513          	addi	a0,s1,540
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	160080e7          	jalr	352(ra) # 80002f4a <wakeup>
    80005df2:	b7e9                	j	80005dbc <pipeclose+0x2c>
    release(&pi->lock);
    80005df4:	8526                	mv	a0,s1
    80005df6:	ffffb097          	auipc	ra,0xffffb
    80005dfa:	ea2080e7          	jalr	-350(ra) # 80000c98 <release>
}
    80005dfe:	bfe1                	j	80005dd6 <pipeclose+0x46>

0000000080005e00 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005e00:	7159                	addi	sp,sp,-112
    80005e02:	f486                	sd	ra,104(sp)
    80005e04:	f0a2                	sd	s0,96(sp)
    80005e06:	eca6                	sd	s1,88(sp)
    80005e08:	e8ca                	sd	s2,80(sp)
    80005e0a:	e4ce                	sd	s3,72(sp)
    80005e0c:	e0d2                	sd	s4,64(sp)
    80005e0e:	fc56                	sd	s5,56(sp)
    80005e10:	f85a                	sd	s6,48(sp)
    80005e12:	f45e                	sd	s7,40(sp)
    80005e14:	f062                	sd	s8,32(sp)
    80005e16:	ec66                	sd	s9,24(sp)
    80005e18:	1880                	addi	s0,sp,112
    80005e1a:	84aa                	mv	s1,a0
    80005e1c:	8aae                	mv	s5,a1
    80005e1e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005e20:	ffffc097          	auipc	ra,0xffffc
    80005e24:	da4080e7          	jalr	-604(ra) # 80001bc4 <myproc>
    80005e28:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005e2a:	8526                	mv	a0,s1
    80005e2c:	ffffb097          	auipc	ra,0xffffb
    80005e30:	db8080e7          	jalr	-584(ra) # 80000be4 <acquire>
  while(i < n){
    80005e34:	0d405163          	blez	s4,80005ef6 <pipewrite+0xf6>
    80005e38:	8ba6                	mv	s7,s1
  int i = 0;
    80005e3a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005e3c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005e3e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005e42:	21c48c13          	addi	s8,s1,540
    80005e46:	a08d                	j	80005ea8 <pipewrite+0xa8>
      release(&pi->lock);
    80005e48:	8526                	mv	a0,s1
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	e4e080e7          	jalr	-434(ra) # 80000c98 <release>
      return -1;
    80005e52:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005e54:	854a                	mv	a0,s2
    80005e56:	70a6                	ld	ra,104(sp)
    80005e58:	7406                	ld	s0,96(sp)
    80005e5a:	64e6                	ld	s1,88(sp)
    80005e5c:	6946                	ld	s2,80(sp)
    80005e5e:	69a6                	ld	s3,72(sp)
    80005e60:	6a06                	ld	s4,64(sp)
    80005e62:	7ae2                	ld	s5,56(sp)
    80005e64:	7b42                	ld	s6,48(sp)
    80005e66:	7ba2                	ld	s7,40(sp)
    80005e68:	7c02                	ld	s8,32(sp)
    80005e6a:	6ce2                	ld	s9,24(sp)
    80005e6c:	6165                	addi	sp,sp,112
    80005e6e:	8082                	ret
      wakeup(&pi->nread);
    80005e70:	8566                	mv	a0,s9
    80005e72:	ffffd097          	auipc	ra,0xffffd
    80005e76:	0d8080e7          	jalr	216(ra) # 80002f4a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005e7a:	85de                	mv	a1,s7
    80005e7c:	8562                	mv	a0,s8
    80005e7e:	ffffd097          	auipc	ra,0xffffd
    80005e82:	d66080e7          	jalr	-666(ra) # 80002be4 <sleep>
    80005e86:	a839                	j	80005ea4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005e88:	21c4a783          	lw	a5,540(s1)
    80005e8c:	0017871b          	addiw	a4,a5,1
    80005e90:	20e4ae23          	sw	a4,540(s1)
    80005e94:	1ff7f793          	andi	a5,a5,511
    80005e98:	97a6                	add	a5,a5,s1
    80005e9a:	f9f44703          	lbu	a4,-97(s0)
    80005e9e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005ea2:	2905                	addiw	s2,s2,1
  while(i < n){
    80005ea4:	03495d63          	bge	s2,s4,80005ede <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005ea8:	2204a783          	lw	a5,544(s1)
    80005eac:	dfd1                	beqz	a5,80005e48 <pipewrite+0x48>
    80005eae:	0289a783          	lw	a5,40(s3)
    80005eb2:	fbd9                	bnez	a5,80005e48 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005eb4:	2184a783          	lw	a5,536(s1)
    80005eb8:	21c4a703          	lw	a4,540(s1)
    80005ebc:	2007879b          	addiw	a5,a5,512
    80005ec0:	faf708e3          	beq	a4,a5,80005e70 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005ec4:	4685                	li	a3,1
    80005ec6:	01590633          	add	a2,s2,s5
    80005eca:	f9f40593          	addi	a1,s0,-97
    80005ece:	0809b503          	ld	a0,128(s3)
    80005ed2:	ffffc097          	auipc	ra,0xffffc
    80005ed6:	834080e7          	jalr	-1996(ra) # 80001706 <copyin>
    80005eda:	fb6517e3          	bne	a0,s6,80005e88 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005ede:	21848513          	addi	a0,s1,536
    80005ee2:	ffffd097          	auipc	ra,0xffffd
    80005ee6:	068080e7          	jalr	104(ra) # 80002f4a <wakeup>
  release(&pi->lock);
    80005eea:	8526                	mv	a0,s1
    80005eec:	ffffb097          	auipc	ra,0xffffb
    80005ef0:	dac080e7          	jalr	-596(ra) # 80000c98 <release>
  return i;
    80005ef4:	b785                	j	80005e54 <pipewrite+0x54>
  int i = 0;
    80005ef6:	4901                	li	s2,0
    80005ef8:	b7dd                	j	80005ede <pipewrite+0xde>

0000000080005efa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005efa:	715d                	addi	sp,sp,-80
    80005efc:	e486                	sd	ra,72(sp)
    80005efe:	e0a2                	sd	s0,64(sp)
    80005f00:	fc26                	sd	s1,56(sp)
    80005f02:	f84a                	sd	s2,48(sp)
    80005f04:	f44e                	sd	s3,40(sp)
    80005f06:	f052                	sd	s4,32(sp)
    80005f08:	ec56                	sd	s5,24(sp)
    80005f0a:	e85a                	sd	s6,16(sp)
    80005f0c:	0880                	addi	s0,sp,80
    80005f0e:	84aa                	mv	s1,a0
    80005f10:	892e                	mv	s2,a1
    80005f12:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005f14:	ffffc097          	auipc	ra,0xffffc
    80005f18:	cb0080e7          	jalr	-848(ra) # 80001bc4 <myproc>
    80005f1c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005f1e:	8b26                	mv	s6,s1
    80005f20:	8526                	mv	a0,s1
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	cc2080e7          	jalr	-830(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f2a:	2184a703          	lw	a4,536(s1)
    80005f2e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005f32:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f36:	02f71463          	bne	a4,a5,80005f5e <piperead+0x64>
    80005f3a:	2244a783          	lw	a5,548(s1)
    80005f3e:	c385                	beqz	a5,80005f5e <piperead+0x64>
    if(pr->killed){
    80005f40:	028a2783          	lw	a5,40(s4)
    80005f44:	ebc1                	bnez	a5,80005fd4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005f46:	85da                	mv	a1,s6
    80005f48:	854e                	mv	a0,s3
    80005f4a:	ffffd097          	auipc	ra,0xffffd
    80005f4e:	c9a080e7          	jalr	-870(ra) # 80002be4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f52:	2184a703          	lw	a4,536(s1)
    80005f56:	21c4a783          	lw	a5,540(s1)
    80005f5a:	fef700e3          	beq	a4,a5,80005f3a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005f5e:	09505263          	blez	s5,80005fe2 <piperead+0xe8>
    80005f62:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005f64:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005f66:	2184a783          	lw	a5,536(s1)
    80005f6a:	21c4a703          	lw	a4,540(s1)
    80005f6e:	02f70d63          	beq	a4,a5,80005fa8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005f72:	0017871b          	addiw	a4,a5,1
    80005f76:	20e4ac23          	sw	a4,536(s1)
    80005f7a:	1ff7f793          	andi	a5,a5,511
    80005f7e:	97a6                	add	a5,a5,s1
    80005f80:	0187c783          	lbu	a5,24(a5)
    80005f84:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005f88:	4685                	li	a3,1
    80005f8a:	fbf40613          	addi	a2,s0,-65
    80005f8e:	85ca                	mv	a1,s2
    80005f90:	080a3503          	ld	a0,128(s4)
    80005f94:	ffffb097          	auipc	ra,0xffffb
    80005f98:	6e6080e7          	jalr	1766(ra) # 8000167a <copyout>
    80005f9c:	01650663          	beq	a0,s6,80005fa8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005fa0:	2985                	addiw	s3,s3,1
    80005fa2:	0905                	addi	s2,s2,1
    80005fa4:	fd3a91e3          	bne	s5,s3,80005f66 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005fa8:	21c48513          	addi	a0,s1,540
    80005fac:	ffffd097          	auipc	ra,0xffffd
    80005fb0:	f9e080e7          	jalr	-98(ra) # 80002f4a <wakeup>
  release(&pi->lock);
    80005fb4:	8526                	mv	a0,s1
    80005fb6:	ffffb097          	auipc	ra,0xffffb
    80005fba:	ce2080e7          	jalr	-798(ra) # 80000c98 <release>
  return i;
}
    80005fbe:	854e                	mv	a0,s3
    80005fc0:	60a6                	ld	ra,72(sp)
    80005fc2:	6406                	ld	s0,64(sp)
    80005fc4:	74e2                	ld	s1,56(sp)
    80005fc6:	7942                	ld	s2,48(sp)
    80005fc8:	79a2                	ld	s3,40(sp)
    80005fca:	7a02                	ld	s4,32(sp)
    80005fcc:	6ae2                	ld	s5,24(sp)
    80005fce:	6b42                	ld	s6,16(sp)
    80005fd0:	6161                	addi	sp,sp,80
    80005fd2:	8082                	ret
      release(&pi->lock);
    80005fd4:	8526                	mv	a0,s1
    80005fd6:	ffffb097          	auipc	ra,0xffffb
    80005fda:	cc2080e7          	jalr	-830(ra) # 80000c98 <release>
      return -1;
    80005fde:	59fd                	li	s3,-1
    80005fe0:	bff9                	j	80005fbe <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005fe2:	4981                	li	s3,0
    80005fe4:	b7d1                	j	80005fa8 <piperead+0xae>

0000000080005fe6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005fe6:	df010113          	addi	sp,sp,-528
    80005fea:	20113423          	sd	ra,520(sp)
    80005fee:	20813023          	sd	s0,512(sp)
    80005ff2:	ffa6                	sd	s1,504(sp)
    80005ff4:	fbca                	sd	s2,496(sp)
    80005ff6:	f7ce                	sd	s3,488(sp)
    80005ff8:	f3d2                	sd	s4,480(sp)
    80005ffa:	efd6                	sd	s5,472(sp)
    80005ffc:	ebda                	sd	s6,464(sp)
    80005ffe:	e7de                	sd	s7,456(sp)
    80006000:	e3e2                	sd	s8,448(sp)
    80006002:	ff66                	sd	s9,440(sp)
    80006004:	fb6a                	sd	s10,432(sp)
    80006006:	f76e                	sd	s11,424(sp)
    80006008:	0c00                	addi	s0,sp,528
    8000600a:	84aa                	mv	s1,a0
    8000600c:	dea43c23          	sd	a0,-520(s0)
    80006010:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80006014:	ffffc097          	auipc	ra,0xffffc
    80006018:	bb0080e7          	jalr	-1104(ra) # 80001bc4 <myproc>
    8000601c:	892a                	mv	s2,a0

  begin_op();
    8000601e:	fffff097          	auipc	ra,0xfffff
    80006022:	49c080e7          	jalr	1180(ra) # 800054ba <begin_op>

  if((ip = namei(path)) == 0){
    80006026:	8526                	mv	a0,s1
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	276080e7          	jalr	630(ra) # 8000529e <namei>
    80006030:	c92d                	beqz	a0,800060a2 <exec+0xbc>
    80006032:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	ab4080e7          	jalr	-1356(ra) # 80004ae8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000603c:	04000713          	li	a4,64
    80006040:	4681                	li	a3,0
    80006042:	e5040613          	addi	a2,s0,-432
    80006046:	4581                	li	a1,0
    80006048:	8526                	mv	a0,s1
    8000604a:	fffff097          	auipc	ra,0xfffff
    8000604e:	d52080e7          	jalr	-686(ra) # 80004d9c <readi>
    80006052:	04000793          	li	a5,64
    80006056:	00f51a63          	bne	a0,a5,8000606a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000605a:	e5042703          	lw	a4,-432(s0)
    8000605e:	464c47b7          	lui	a5,0x464c4
    80006062:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80006066:	04f70463          	beq	a4,a5,800060ae <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000606a:	8526                	mv	a0,s1
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	cde080e7          	jalr	-802(ra) # 80004d4a <iunlockput>
    end_op();
    80006074:	fffff097          	auipc	ra,0xfffff
    80006078:	4c6080e7          	jalr	1222(ra) # 8000553a <end_op>
  }
  return -1;
    8000607c:	557d                	li	a0,-1
}
    8000607e:	20813083          	ld	ra,520(sp)
    80006082:	20013403          	ld	s0,512(sp)
    80006086:	74fe                	ld	s1,504(sp)
    80006088:	795e                	ld	s2,496(sp)
    8000608a:	79be                	ld	s3,488(sp)
    8000608c:	7a1e                	ld	s4,480(sp)
    8000608e:	6afe                	ld	s5,472(sp)
    80006090:	6b5e                	ld	s6,464(sp)
    80006092:	6bbe                	ld	s7,456(sp)
    80006094:	6c1e                	ld	s8,448(sp)
    80006096:	7cfa                	ld	s9,440(sp)
    80006098:	7d5a                	ld	s10,432(sp)
    8000609a:	7dba                	ld	s11,424(sp)
    8000609c:	21010113          	addi	sp,sp,528
    800060a0:	8082                	ret
    end_op();
    800060a2:	fffff097          	auipc	ra,0xfffff
    800060a6:	498080e7          	jalr	1176(ra) # 8000553a <end_op>
    return -1;
    800060aa:	557d                	li	a0,-1
    800060ac:	bfc9                	j	8000607e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800060ae:	854a                	mv	a0,s2
    800060b0:	ffffc097          	auipc	ra,0xffffc
    800060b4:	bdc080e7          	jalr	-1060(ra) # 80001c8c <proc_pagetable>
    800060b8:	8baa                	mv	s7,a0
    800060ba:	d945                	beqz	a0,8000606a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800060bc:	e7042983          	lw	s3,-400(s0)
    800060c0:	e8845783          	lhu	a5,-376(s0)
    800060c4:	c7ad                	beqz	a5,8000612e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800060c6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800060c8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800060ca:	6c85                	lui	s9,0x1
    800060cc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800060d0:	def43823          	sd	a5,-528(s0)
    800060d4:	a42d                	j	800062fe <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800060d6:	00004517          	auipc	a0,0x4
    800060da:	81250513          	addi	a0,a0,-2030 # 800098e8 <syscalls+0x2a8>
    800060de:	ffffa097          	auipc	ra,0xffffa
    800060e2:	460080e7          	jalr	1120(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800060e6:	8756                	mv	a4,s5
    800060e8:	012d86bb          	addw	a3,s11,s2
    800060ec:	4581                	li	a1,0
    800060ee:	8526                	mv	a0,s1
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	cac080e7          	jalr	-852(ra) # 80004d9c <readi>
    800060f8:	2501                	sext.w	a0,a0
    800060fa:	1aaa9963          	bne	s5,a0,800062ac <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800060fe:	6785                	lui	a5,0x1
    80006100:	0127893b          	addw	s2,a5,s2
    80006104:	77fd                	lui	a5,0xfffff
    80006106:	01478a3b          	addw	s4,a5,s4
    8000610a:	1f897163          	bgeu	s2,s8,800062ec <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000610e:	02091593          	slli	a1,s2,0x20
    80006112:	9181                	srli	a1,a1,0x20
    80006114:	95ea                	add	a1,a1,s10
    80006116:	855e                	mv	a0,s7
    80006118:	ffffb097          	auipc	ra,0xffffb
    8000611c:	f5e080e7          	jalr	-162(ra) # 80001076 <walkaddr>
    80006120:	862a                	mv	a2,a0
    if(pa == 0)
    80006122:	d955                	beqz	a0,800060d6 <exec+0xf0>
      n = PGSIZE;
    80006124:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80006126:	fd9a70e3          	bgeu	s4,s9,800060e6 <exec+0x100>
      n = sz - i;
    8000612a:	8ad2                	mv	s5,s4
    8000612c:	bf6d                	j	800060e6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000612e:	4901                	li	s2,0
  iunlockput(ip);
    80006130:	8526                	mv	a0,s1
    80006132:	fffff097          	auipc	ra,0xfffff
    80006136:	c18080e7          	jalr	-1000(ra) # 80004d4a <iunlockput>
  end_op();
    8000613a:	fffff097          	auipc	ra,0xfffff
    8000613e:	400080e7          	jalr	1024(ra) # 8000553a <end_op>
  p = myproc();
    80006142:	ffffc097          	auipc	ra,0xffffc
    80006146:	a82080e7          	jalr	-1406(ra) # 80001bc4 <myproc>
    8000614a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000614c:	07853d03          	ld	s10,120(a0)
  sz = PGROUNDUP(sz);
    80006150:	6785                	lui	a5,0x1
    80006152:	17fd                	addi	a5,a5,-1
    80006154:	993e                	add	s2,s2,a5
    80006156:	757d                	lui	a0,0xfffff
    80006158:	00a977b3          	and	a5,s2,a0
    8000615c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80006160:	6609                	lui	a2,0x2
    80006162:	963e                	add	a2,a2,a5
    80006164:	85be                	mv	a1,a5
    80006166:	855e                	mv	a0,s7
    80006168:	ffffb097          	auipc	ra,0xffffb
    8000616c:	2c2080e7          	jalr	706(ra) # 8000142a <uvmalloc>
    80006170:	8b2a                	mv	s6,a0
  ip = 0;
    80006172:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80006174:	12050c63          	beqz	a0,800062ac <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80006178:	75f9                	lui	a1,0xffffe
    8000617a:	95aa                	add	a1,a1,a0
    8000617c:	855e                	mv	a0,s7
    8000617e:	ffffb097          	auipc	ra,0xffffb
    80006182:	4ca080e7          	jalr	1226(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80006186:	7c7d                	lui	s8,0xfffff
    80006188:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000618a:	e0043783          	ld	a5,-512(s0)
    8000618e:	6388                	ld	a0,0(a5)
    80006190:	c535                	beqz	a0,800061fc <exec+0x216>
    80006192:	e9040993          	addi	s3,s0,-368
    80006196:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000619a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	cc8080e7          	jalr	-824(ra) # 80000e64 <strlen>
    800061a4:	2505                	addiw	a0,a0,1
    800061a6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800061aa:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800061ae:	13896363          	bltu	s2,s8,800062d4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800061b2:	e0043d83          	ld	s11,-512(s0)
    800061b6:	000dba03          	ld	s4,0(s11)
    800061ba:	8552                	mv	a0,s4
    800061bc:	ffffb097          	auipc	ra,0xffffb
    800061c0:	ca8080e7          	jalr	-856(ra) # 80000e64 <strlen>
    800061c4:	0015069b          	addiw	a3,a0,1
    800061c8:	8652                	mv	a2,s4
    800061ca:	85ca                	mv	a1,s2
    800061cc:	855e                	mv	a0,s7
    800061ce:	ffffb097          	auipc	ra,0xffffb
    800061d2:	4ac080e7          	jalr	1196(ra) # 8000167a <copyout>
    800061d6:	10054363          	bltz	a0,800062dc <exec+0x2f6>
    ustack[argc] = sp;
    800061da:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800061de:	0485                	addi	s1,s1,1
    800061e0:	008d8793          	addi	a5,s11,8
    800061e4:	e0f43023          	sd	a5,-512(s0)
    800061e8:	008db503          	ld	a0,8(s11)
    800061ec:	c911                	beqz	a0,80006200 <exec+0x21a>
    if(argc >= MAXARG)
    800061ee:	09a1                	addi	s3,s3,8
    800061f0:	fb3c96e3          	bne	s9,s3,8000619c <exec+0x1b6>
  sz = sz1;
    800061f4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800061f8:	4481                	li	s1,0
    800061fa:	a84d                	j	800062ac <exec+0x2c6>
  sp = sz;
    800061fc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800061fe:	4481                	li	s1,0
  ustack[argc] = 0;
    80006200:	00349793          	slli	a5,s1,0x3
    80006204:	f9040713          	addi	a4,s0,-112
    80006208:	97ba                	add	a5,a5,a4
    8000620a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000620e:	00148693          	addi	a3,s1,1
    80006212:	068e                	slli	a3,a3,0x3
    80006214:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80006218:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000621c:	01897663          	bgeu	s2,s8,80006228 <exec+0x242>
  sz = sz1;
    80006220:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006224:	4481                	li	s1,0
    80006226:	a059                	j	800062ac <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80006228:	e9040613          	addi	a2,s0,-368
    8000622c:	85ca                	mv	a1,s2
    8000622e:	855e                	mv	a0,s7
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	44a080e7          	jalr	1098(ra) # 8000167a <copyout>
    80006238:	0a054663          	bltz	a0,800062e4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000623c:	088ab783          	ld	a5,136(s5)
    80006240:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80006244:	df843783          	ld	a5,-520(s0)
    80006248:	0007c703          	lbu	a4,0(a5)
    8000624c:	cf11                	beqz	a4,80006268 <exec+0x282>
    8000624e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80006250:	02f00693          	li	a3,47
    80006254:	a039                	j	80006262 <exec+0x27c>
      last = s+1;
    80006256:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000625a:	0785                	addi	a5,a5,1
    8000625c:	fff7c703          	lbu	a4,-1(a5)
    80006260:	c701                	beqz	a4,80006268 <exec+0x282>
    if(*s == '/')
    80006262:	fed71ce3          	bne	a4,a3,8000625a <exec+0x274>
    80006266:	bfc5                	j	80006256 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80006268:	4641                	li	a2,16
    8000626a:	df843583          	ld	a1,-520(s0)
    8000626e:	188a8513          	addi	a0,s5,392
    80006272:	ffffb097          	auipc	ra,0xffffb
    80006276:	bc0080e7          	jalr	-1088(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000627a:	080ab503          	ld	a0,128(s5)
  p->pagetable = pagetable;
    8000627e:	097ab023          	sd	s7,128(s5)
  p->sz = sz;
    80006282:	076abc23          	sd	s6,120(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80006286:	088ab783          	ld	a5,136(s5)
    8000628a:	e6843703          	ld	a4,-408(s0)
    8000628e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80006290:	088ab783          	ld	a5,136(s5)
    80006294:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80006298:	85ea                	mv	a1,s10
    8000629a:	ffffc097          	auipc	ra,0xffffc
    8000629e:	a8e080e7          	jalr	-1394(ra) # 80001d28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800062a2:	0004851b          	sext.w	a0,s1
    800062a6:	bbe1                	j	8000607e <exec+0x98>
    800062a8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800062ac:	e0843583          	ld	a1,-504(s0)
    800062b0:	855e                	mv	a0,s7
    800062b2:	ffffc097          	auipc	ra,0xffffc
    800062b6:	a76080e7          	jalr	-1418(ra) # 80001d28 <proc_freepagetable>
  if(ip){
    800062ba:	da0498e3          	bnez	s1,8000606a <exec+0x84>
  return -1;
    800062be:	557d                	li	a0,-1
    800062c0:	bb7d                	j	8000607e <exec+0x98>
    800062c2:	e1243423          	sd	s2,-504(s0)
    800062c6:	b7dd                	j	800062ac <exec+0x2c6>
    800062c8:	e1243423          	sd	s2,-504(s0)
    800062cc:	b7c5                	j	800062ac <exec+0x2c6>
    800062ce:	e1243423          	sd	s2,-504(s0)
    800062d2:	bfe9                	j	800062ac <exec+0x2c6>
  sz = sz1;
    800062d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800062d8:	4481                	li	s1,0
    800062da:	bfc9                	j	800062ac <exec+0x2c6>
  sz = sz1;
    800062dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800062e0:	4481                	li	s1,0
    800062e2:	b7e9                	j	800062ac <exec+0x2c6>
  sz = sz1;
    800062e4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800062e8:	4481                	li	s1,0
    800062ea:	b7c9                	j	800062ac <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800062ec:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800062f0:	2b05                	addiw	s6,s6,1
    800062f2:	0389899b          	addiw	s3,s3,56
    800062f6:	e8845783          	lhu	a5,-376(s0)
    800062fa:	e2fb5be3          	bge	s6,a5,80006130 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800062fe:	2981                	sext.w	s3,s3
    80006300:	03800713          	li	a4,56
    80006304:	86ce                	mv	a3,s3
    80006306:	e1840613          	addi	a2,s0,-488
    8000630a:	4581                	li	a1,0
    8000630c:	8526                	mv	a0,s1
    8000630e:	fffff097          	auipc	ra,0xfffff
    80006312:	a8e080e7          	jalr	-1394(ra) # 80004d9c <readi>
    80006316:	03800793          	li	a5,56
    8000631a:	f8f517e3          	bne	a0,a5,800062a8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000631e:	e1842783          	lw	a5,-488(s0)
    80006322:	4705                	li	a4,1
    80006324:	fce796e3          	bne	a5,a4,800062f0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80006328:	e4043603          	ld	a2,-448(s0)
    8000632c:	e3843783          	ld	a5,-456(s0)
    80006330:	f8f669e3          	bltu	a2,a5,800062c2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80006334:	e2843783          	ld	a5,-472(s0)
    80006338:	963e                	add	a2,a2,a5
    8000633a:	f8f667e3          	bltu	a2,a5,800062c8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000633e:	85ca                	mv	a1,s2
    80006340:	855e                	mv	a0,s7
    80006342:	ffffb097          	auipc	ra,0xffffb
    80006346:	0e8080e7          	jalr	232(ra) # 8000142a <uvmalloc>
    8000634a:	e0a43423          	sd	a0,-504(s0)
    8000634e:	d141                	beqz	a0,800062ce <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80006350:	e2843d03          	ld	s10,-472(s0)
    80006354:	df043783          	ld	a5,-528(s0)
    80006358:	00fd77b3          	and	a5,s10,a5
    8000635c:	fba1                	bnez	a5,800062ac <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000635e:	e2042d83          	lw	s11,-480(s0)
    80006362:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80006366:	f80c03e3          	beqz	s8,800062ec <exec+0x306>
    8000636a:	8a62                	mv	s4,s8
    8000636c:	4901                	li	s2,0
    8000636e:	b345                	j	8000610e <exec+0x128>

0000000080006370 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80006370:	7179                	addi	sp,sp,-48
    80006372:	f406                	sd	ra,40(sp)
    80006374:	f022                	sd	s0,32(sp)
    80006376:	ec26                	sd	s1,24(sp)
    80006378:	e84a                	sd	s2,16(sp)
    8000637a:	1800                	addi	s0,sp,48
    8000637c:	892e                	mv	s2,a1
    8000637e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80006380:	fdc40593          	addi	a1,s0,-36
    80006384:	ffffe097          	auipc	ra,0xffffe
    80006388:	b46080e7          	jalr	-1210(ra) # 80003eca <argint>
    8000638c:	04054063          	bltz	a0,800063cc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80006390:	fdc42703          	lw	a4,-36(s0)
    80006394:	47bd                	li	a5,15
    80006396:	02e7ed63          	bltu	a5,a4,800063d0 <argfd+0x60>
    8000639a:	ffffc097          	auipc	ra,0xffffc
    8000639e:	82a080e7          	jalr	-2006(ra) # 80001bc4 <myproc>
    800063a2:	fdc42703          	lw	a4,-36(s0)
    800063a6:	02070793          	addi	a5,a4,32
    800063aa:	078e                	slli	a5,a5,0x3
    800063ac:	953e                	add	a0,a0,a5
    800063ae:	611c                	ld	a5,0(a0)
    800063b0:	c395                	beqz	a5,800063d4 <argfd+0x64>
    return -1;
  if(pfd)
    800063b2:	00090463          	beqz	s2,800063ba <argfd+0x4a>
    *pfd = fd;
    800063b6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800063ba:	4501                	li	a0,0
  if(pf)
    800063bc:	c091                	beqz	s1,800063c0 <argfd+0x50>
    *pf = f;
    800063be:	e09c                	sd	a5,0(s1)
}
    800063c0:	70a2                	ld	ra,40(sp)
    800063c2:	7402                	ld	s0,32(sp)
    800063c4:	64e2                	ld	s1,24(sp)
    800063c6:	6942                	ld	s2,16(sp)
    800063c8:	6145                	addi	sp,sp,48
    800063ca:	8082                	ret
    return -1;
    800063cc:	557d                	li	a0,-1
    800063ce:	bfcd                	j	800063c0 <argfd+0x50>
    return -1;
    800063d0:	557d                	li	a0,-1
    800063d2:	b7fd                	j	800063c0 <argfd+0x50>
    800063d4:	557d                	li	a0,-1
    800063d6:	b7ed                	j	800063c0 <argfd+0x50>

00000000800063d8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800063d8:	1101                	addi	sp,sp,-32
    800063da:	ec06                	sd	ra,24(sp)
    800063dc:	e822                	sd	s0,16(sp)
    800063de:	e426                	sd	s1,8(sp)
    800063e0:	1000                	addi	s0,sp,32
    800063e2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800063e4:	ffffb097          	auipc	ra,0xffffb
    800063e8:	7e0080e7          	jalr	2016(ra) # 80001bc4 <myproc>
    800063ec:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800063ee:	10050793          	addi	a5,a0,256 # fffffffffffff100 <end+0xffffffff7ffd7100>
    800063f2:	4501                	li	a0,0
    800063f4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800063f6:	6398                	ld	a4,0(a5)
    800063f8:	cb19                	beqz	a4,8000640e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800063fa:	2505                	addiw	a0,a0,1
    800063fc:	07a1                	addi	a5,a5,8
    800063fe:	fed51ce3          	bne	a0,a3,800063f6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80006402:	557d                	li	a0,-1
}
    80006404:	60e2                	ld	ra,24(sp)
    80006406:	6442                	ld	s0,16(sp)
    80006408:	64a2                	ld	s1,8(sp)
    8000640a:	6105                	addi	sp,sp,32
    8000640c:	8082                	ret
      p->ofile[fd] = f;
    8000640e:	02050793          	addi	a5,a0,32
    80006412:	078e                	slli	a5,a5,0x3
    80006414:	963e                	add	a2,a2,a5
    80006416:	e204                	sd	s1,0(a2)
      return fd;
    80006418:	b7f5                	j	80006404 <fdalloc+0x2c>

000000008000641a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000641a:	715d                	addi	sp,sp,-80
    8000641c:	e486                	sd	ra,72(sp)
    8000641e:	e0a2                	sd	s0,64(sp)
    80006420:	fc26                	sd	s1,56(sp)
    80006422:	f84a                	sd	s2,48(sp)
    80006424:	f44e                	sd	s3,40(sp)
    80006426:	f052                	sd	s4,32(sp)
    80006428:	ec56                	sd	s5,24(sp)
    8000642a:	0880                	addi	s0,sp,80
    8000642c:	89ae                	mv	s3,a1
    8000642e:	8ab2                	mv	s5,a2
    80006430:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006432:	fb040593          	addi	a1,s0,-80
    80006436:	fffff097          	auipc	ra,0xfffff
    8000643a:	e86080e7          	jalr	-378(ra) # 800052bc <nameiparent>
    8000643e:	892a                	mv	s2,a0
    80006440:	12050f63          	beqz	a0,8000657e <create+0x164>
    return 0;

  ilock(dp);
    80006444:	ffffe097          	auipc	ra,0xffffe
    80006448:	6a4080e7          	jalr	1700(ra) # 80004ae8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000644c:	4601                	li	a2,0
    8000644e:	fb040593          	addi	a1,s0,-80
    80006452:	854a                	mv	a0,s2
    80006454:	fffff097          	auipc	ra,0xfffff
    80006458:	b78080e7          	jalr	-1160(ra) # 80004fcc <dirlookup>
    8000645c:	84aa                	mv	s1,a0
    8000645e:	c921                	beqz	a0,800064ae <create+0x94>
    iunlockput(dp);
    80006460:	854a                	mv	a0,s2
    80006462:	fffff097          	auipc	ra,0xfffff
    80006466:	8e8080e7          	jalr	-1816(ra) # 80004d4a <iunlockput>
    ilock(ip);
    8000646a:	8526                	mv	a0,s1
    8000646c:	ffffe097          	auipc	ra,0xffffe
    80006470:	67c080e7          	jalr	1660(ra) # 80004ae8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006474:	2981                	sext.w	s3,s3
    80006476:	4789                	li	a5,2
    80006478:	02f99463          	bne	s3,a5,800064a0 <create+0x86>
    8000647c:	0444d783          	lhu	a5,68(s1)
    80006480:	37f9                	addiw	a5,a5,-2
    80006482:	17c2                	slli	a5,a5,0x30
    80006484:	93c1                	srli	a5,a5,0x30
    80006486:	4705                	li	a4,1
    80006488:	00f76c63          	bltu	a4,a5,800064a0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000648c:	8526                	mv	a0,s1
    8000648e:	60a6                	ld	ra,72(sp)
    80006490:	6406                	ld	s0,64(sp)
    80006492:	74e2                	ld	s1,56(sp)
    80006494:	7942                	ld	s2,48(sp)
    80006496:	79a2                	ld	s3,40(sp)
    80006498:	7a02                	ld	s4,32(sp)
    8000649a:	6ae2                	ld	s5,24(sp)
    8000649c:	6161                	addi	sp,sp,80
    8000649e:	8082                	ret
    iunlockput(ip);
    800064a0:	8526                	mv	a0,s1
    800064a2:	fffff097          	auipc	ra,0xfffff
    800064a6:	8a8080e7          	jalr	-1880(ra) # 80004d4a <iunlockput>
    return 0;
    800064aa:	4481                	li	s1,0
    800064ac:	b7c5                	j	8000648c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800064ae:	85ce                	mv	a1,s3
    800064b0:	00092503          	lw	a0,0(s2)
    800064b4:	ffffe097          	auipc	ra,0xffffe
    800064b8:	49c080e7          	jalr	1180(ra) # 80004950 <ialloc>
    800064bc:	84aa                	mv	s1,a0
    800064be:	c529                	beqz	a0,80006508 <create+0xee>
  ilock(ip);
    800064c0:	ffffe097          	auipc	ra,0xffffe
    800064c4:	628080e7          	jalr	1576(ra) # 80004ae8 <ilock>
  ip->major = major;
    800064c8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800064cc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800064d0:	4785                	li	a5,1
    800064d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800064d6:	8526                	mv	a0,s1
    800064d8:	ffffe097          	auipc	ra,0xffffe
    800064dc:	546080e7          	jalr	1350(ra) # 80004a1e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800064e0:	2981                	sext.w	s3,s3
    800064e2:	4785                	li	a5,1
    800064e4:	02f98a63          	beq	s3,a5,80006518 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800064e8:	40d0                	lw	a2,4(s1)
    800064ea:	fb040593          	addi	a1,s0,-80
    800064ee:	854a                	mv	a0,s2
    800064f0:	fffff097          	auipc	ra,0xfffff
    800064f4:	cec080e7          	jalr	-788(ra) # 800051dc <dirlink>
    800064f8:	06054b63          	bltz	a0,8000656e <create+0x154>
  iunlockput(dp);
    800064fc:	854a                	mv	a0,s2
    800064fe:	fffff097          	auipc	ra,0xfffff
    80006502:	84c080e7          	jalr	-1972(ra) # 80004d4a <iunlockput>
  return ip;
    80006506:	b759                	j	8000648c <create+0x72>
    panic("create: ialloc");
    80006508:	00003517          	auipc	a0,0x3
    8000650c:	40050513          	addi	a0,a0,1024 # 80009908 <syscalls+0x2c8>
    80006510:	ffffa097          	auipc	ra,0xffffa
    80006514:	02e080e7          	jalr	46(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80006518:	04a95783          	lhu	a5,74(s2)
    8000651c:	2785                	addiw	a5,a5,1
    8000651e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006522:	854a                	mv	a0,s2
    80006524:	ffffe097          	auipc	ra,0xffffe
    80006528:	4fa080e7          	jalr	1274(ra) # 80004a1e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000652c:	40d0                	lw	a2,4(s1)
    8000652e:	00003597          	auipc	a1,0x3
    80006532:	3ea58593          	addi	a1,a1,1002 # 80009918 <syscalls+0x2d8>
    80006536:	8526                	mv	a0,s1
    80006538:	fffff097          	auipc	ra,0xfffff
    8000653c:	ca4080e7          	jalr	-860(ra) # 800051dc <dirlink>
    80006540:	00054f63          	bltz	a0,8000655e <create+0x144>
    80006544:	00492603          	lw	a2,4(s2)
    80006548:	00003597          	auipc	a1,0x3
    8000654c:	3d858593          	addi	a1,a1,984 # 80009920 <syscalls+0x2e0>
    80006550:	8526                	mv	a0,s1
    80006552:	fffff097          	auipc	ra,0xfffff
    80006556:	c8a080e7          	jalr	-886(ra) # 800051dc <dirlink>
    8000655a:	f80557e3          	bgez	a0,800064e8 <create+0xce>
      panic("create dots");
    8000655e:	00003517          	auipc	a0,0x3
    80006562:	3ca50513          	addi	a0,a0,970 # 80009928 <syscalls+0x2e8>
    80006566:	ffffa097          	auipc	ra,0xffffa
    8000656a:	fd8080e7          	jalr	-40(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000656e:	00003517          	auipc	a0,0x3
    80006572:	3ca50513          	addi	a0,a0,970 # 80009938 <syscalls+0x2f8>
    80006576:	ffffa097          	auipc	ra,0xffffa
    8000657a:	fc8080e7          	jalr	-56(ra) # 8000053e <panic>
    return 0;
    8000657e:	84aa                	mv	s1,a0
    80006580:	b731                	j	8000648c <create+0x72>

0000000080006582 <sys_dup>:
{
    80006582:	7179                	addi	sp,sp,-48
    80006584:	f406                	sd	ra,40(sp)
    80006586:	f022                	sd	s0,32(sp)
    80006588:	ec26                	sd	s1,24(sp)
    8000658a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000658c:	fd840613          	addi	a2,s0,-40
    80006590:	4581                	li	a1,0
    80006592:	4501                	li	a0,0
    80006594:	00000097          	auipc	ra,0x0
    80006598:	ddc080e7          	jalr	-548(ra) # 80006370 <argfd>
    return -1;
    8000659c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000659e:	02054363          	bltz	a0,800065c4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800065a2:	fd843503          	ld	a0,-40(s0)
    800065a6:	00000097          	auipc	ra,0x0
    800065aa:	e32080e7          	jalr	-462(ra) # 800063d8 <fdalloc>
    800065ae:	84aa                	mv	s1,a0
    return -1;
    800065b0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800065b2:	00054963          	bltz	a0,800065c4 <sys_dup+0x42>
  filedup(f);
    800065b6:	fd843503          	ld	a0,-40(s0)
    800065ba:	fffff097          	auipc	ra,0xfffff
    800065be:	37a080e7          	jalr	890(ra) # 80005934 <filedup>
  return fd;
    800065c2:	87a6                	mv	a5,s1
}
    800065c4:	853e                	mv	a0,a5
    800065c6:	70a2                	ld	ra,40(sp)
    800065c8:	7402                	ld	s0,32(sp)
    800065ca:	64e2                	ld	s1,24(sp)
    800065cc:	6145                	addi	sp,sp,48
    800065ce:	8082                	ret

00000000800065d0 <sys_read>:
{
    800065d0:	7179                	addi	sp,sp,-48
    800065d2:	f406                	sd	ra,40(sp)
    800065d4:	f022                	sd	s0,32(sp)
    800065d6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800065d8:	fe840613          	addi	a2,s0,-24
    800065dc:	4581                	li	a1,0
    800065de:	4501                	li	a0,0
    800065e0:	00000097          	auipc	ra,0x0
    800065e4:	d90080e7          	jalr	-624(ra) # 80006370 <argfd>
    return -1;
    800065e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800065ea:	04054163          	bltz	a0,8000662c <sys_read+0x5c>
    800065ee:	fe440593          	addi	a1,s0,-28
    800065f2:	4509                	li	a0,2
    800065f4:	ffffe097          	auipc	ra,0xffffe
    800065f8:	8d6080e7          	jalr	-1834(ra) # 80003eca <argint>
    return -1;
    800065fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800065fe:	02054763          	bltz	a0,8000662c <sys_read+0x5c>
    80006602:	fd840593          	addi	a1,s0,-40
    80006606:	4505                	li	a0,1
    80006608:	ffffe097          	auipc	ra,0xffffe
    8000660c:	8e4080e7          	jalr	-1820(ra) # 80003eec <argaddr>
    return -1;
    80006610:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006612:	00054d63          	bltz	a0,8000662c <sys_read+0x5c>
  return fileread(f, p, n);
    80006616:	fe442603          	lw	a2,-28(s0)
    8000661a:	fd843583          	ld	a1,-40(s0)
    8000661e:	fe843503          	ld	a0,-24(s0)
    80006622:	fffff097          	auipc	ra,0xfffff
    80006626:	49e080e7          	jalr	1182(ra) # 80005ac0 <fileread>
    8000662a:	87aa                	mv	a5,a0
}
    8000662c:	853e                	mv	a0,a5
    8000662e:	70a2                	ld	ra,40(sp)
    80006630:	7402                	ld	s0,32(sp)
    80006632:	6145                	addi	sp,sp,48
    80006634:	8082                	ret

0000000080006636 <sys_write>:
{
    80006636:	7179                	addi	sp,sp,-48
    80006638:	f406                	sd	ra,40(sp)
    8000663a:	f022                	sd	s0,32(sp)
    8000663c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000663e:	fe840613          	addi	a2,s0,-24
    80006642:	4581                	li	a1,0
    80006644:	4501                	li	a0,0
    80006646:	00000097          	auipc	ra,0x0
    8000664a:	d2a080e7          	jalr	-726(ra) # 80006370 <argfd>
    return -1;
    8000664e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006650:	04054163          	bltz	a0,80006692 <sys_write+0x5c>
    80006654:	fe440593          	addi	a1,s0,-28
    80006658:	4509                	li	a0,2
    8000665a:	ffffe097          	auipc	ra,0xffffe
    8000665e:	870080e7          	jalr	-1936(ra) # 80003eca <argint>
    return -1;
    80006662:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006664:	02054763          	bltz	a0,80006692 <sys_write+0x5c>
    80006668:	fd840593          	addi	a1,s0,-40
    8000666c:	4505                	li	a0,1
    8000666e:	ffffe097          	auipc	ra,0xffffe
    80006672:	87e080e7          	jalr	-1922(ra) # 80003eec <argaddr>
    return -1;
    80006676:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006678:	00054d63          	bltz	a0,80006692 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000667c:	fe442603          	lw	a2,-28(s0)
    80006680:	fd843583          	ld	a1,-40(s0)
    80006684:	fe843503          	ld	a0,-24(s0)
    80006688:	fffff097          	auipc	ra,0xfffff
    8000668c:	4fa080e7          	jalr	1274(ra) # 80005b82 <filewrite>
    80006690:	87aa                	mv	a5,a0
}
    80006692:	853e                	mv	a0,a5
    80006694:	70a2                	ld	ra,40(sp)
    80006696:	7402                	ld	s0,32(sp)
    80006698:	6145                	addi	sp,sp,48
    8000669a:	8082                	ret

000000008000669c <sys_close>:
{
    8000669c:	1101                	addi	sp,sp,-32
    8000669e:	ec06                	sd	ra,24(sp)
    800066a0:	e822                	sd	s0,16(sp)
    800066a2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800066a4:	fe040613          	addi	a2,s0,-32
    800066a8:	fec40593          	addi	a1,s0,-20
    800066ac:	4501                	li	a0,0
    800066ae:	00000097          	auipc	ra,0x0
    800066b2:	cc2080e7          	jalr	-830(ra) # 80006370 <argfd>
    return -1;
    800066b6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800066b8:	02054563          	bltz	a0,800066e2 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    800066bc:	ffffb097          	auipc	ra,0xffffb
    800066c0:	508080e7          	jalr	1288(ra) # 80001bc4 <myproc>
    800066c4:	fec42783          	lw	a5,-20(s0)
    800066c8:	02078793          	addi	a5,a5,32
    800066cc:	078e                	slli	a5,a5,0x3
    800066ce:	97aa                	add	a5,a5,a0
    800066d0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800066d4:	fe043503          	ld	a0,-32(s0)
    800066d8:	fffff097          	auipc	ra,0xfffff
    800066dc:	2ae080e7          	jalr	686(ra) # 80005986 <fileclose>
  return 0;
    800066e0:	4781                	li	a5,0
}
    800066e2:	853e                	mv	a0,a5
    800066e4:	60e2                	ld	ra,24(sp)
    800066e6:	6442                	ld	s0,16(sp)
    800066e8:	6105                	addi	sp,sp,32
    800066ea:	8082                	ret

00000000800066ec <sys_fstat>:
{
    800066ec:	1101                	addi	sp,sp,-32
    800066ee:	ec06                	sd	ra,24(sp)
    800066f0:	e822                	sd	s0,16(sp)
    800066f2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800066f4:	fe840613          	addi	a2,s0,-24
    800066f8:	4581                	li	a1,0
    800066fa:	4501                	li	a0,0
    800066fc:	00000097          	auipc	ra,0x0
    80006700:	c74080e7          	jalr	-908(ra) # 80006370 <argfd>
    return -1;
    80006704:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006706:	02054563          	bltz	a0,80006730 <sys_fstat+0x44>
    8000670a:	fe040593          	addi	a1,s0,-32
    8000670e:	4505                	li	a0,1
    80006710:	ffffd097          	auipc	ra,0xffffd
    80006714:	7dc080e7          	jalr	2012(ra) # 80003eec <argaddr>
    return -1;
    80006718:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000671a:	00054b63          	bltz	a0,80006730 <sys_fstat+0x44>
  return filestat(f, st);
    8000671e:	fe043583          	ld	a1,-32(s0)
    80006722:	fe843503          	ld	a0,-24(s0)
    80006726:	fffff097          	auipc	ra,0xfffff
    8000672a:	328080e7          	jalr	808(ra) # 80005a4e <filestat>
    8000672e:	87aa                	mv	a5,a0
}
    80006730:	853e                	mv	a0,a5
    80006732:	60e2                	ld	ra,24(sp)
    80006734:	6442                	ld	s0,16(sp)
    80006736:	6105                	addi	sp,sp,32
    80006738:	8082                	ret

000000008000673a <sys_link>:
{
    8000673a:	7169                	addi	sp,sp,-304
    8000673c:	f606                	sd	ra,296(sp)
    8000673e:	f222                	sd	s0,288(sp)
    80006740:	ee26                	sd	s1,280(sp)
    80006742:	ea4a                	sd	s2,272(sp)
    80006744:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006746:	08000613          	li	a2,128
    8000674a:	ed040593          	addi	a1,s0,-304
    8000674e:	4501                	li	a0,0
    80006750:	ffffd097          	auipc	ra,0xffffd
    80006754:	7be080e7          	jalr	1982(ra) # 80003f0e <argstr>
    return -1;
    80006758:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000675a:	10054e63          	bltz	a0,80006876 <sys_link+0x13c>
    8000675e:	08000613          	li	a2,128
    80006762:	f5040593          	addi	a1,s0,-176
    80006766:	4505                	li	a0,1
    80006768:	ffffd097          	auipc	ra,0xffffd
    8000676c:	7a6080e7          	jalr	1958(ra) # 80003f0e <argstr>
    return -1;
    80006770:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006772:	10054263          	bltz	a0,80006876 <sys_link+0x13c>
  begin_op();
    80006776:	fffff097          	auipc	ra,0xfffff
    8000677a:	d44080e7          	jalr	-700(ra) # 800054ba <begin_op>
  if((ip = namei(old)) == 0){
    8000677e:	ed040513          	addi	a0,s0,-304
    80006782:	fffff097          	auipc	ra,0xfffff
    80006786:	b1c080e7          	jalr	-1252(ra) # 8000529e <namei>
    8000678a:	84aa                	mv	s1,a0
    8000678c:	c551                	beqz	a0,80006818 <sys_link+0xde>
  ilock(ip);
    8000678e:	ffffe097          	auipc	ra,0xffffe
    80006792:	35a080e7          	jalr	858(ra) # 80004ae8 <ilock>
  if(ip->type == T_DIR){
    80006796:	04449703          	lh	a4,68(s1)
    8000679a:	4785                	li	a5,1
    8000679c:	08f70463          	beq	a4,a5,80006824 <sys_link+0xea>
  ip->nlink++;
    800067a0:	04a4d783          	lhu	a5,74(s1)
    800067a4:	2785                	addiw	a5,a5,1
    800067a6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800067aa:	8526                	mv	a0,s1
    800067ac:	ffffe097          	auipc	ra,0xffffe
    800067b0:	272080e7          	jalr	626(ra) # 80004a1e <iupdate>
  iunlock(ip);
    800067b4:	8526                	mv	a0,s1
    800067b6:	ffffe097          	auipc	ra,0xffffe
    800067ba:	3f4080e7          	jalr	1012(ra) # 80004baa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800067be:	fd040593          	addi	a1,s0,-48
    800067c2:	f5040513          	addi	a0,s0,-176
    800067c6:	fffff097          	auipc	ra,0xfffff
    800067ca:	af6080e7          	jalr	-1290(ra) # 800052bc <nameiparent>
    800067ce:	892a                	mv	s2,a0
    800067d0:	c935                	beqz	a0,80006844 <sys_link+0x10a>
  ilock(dp);
    800067d2:	ffffe097          	auipc	ra,0xffffe
    800067d6:	316080e7          	jalr	790(ra) # 80004ae8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800067da:	00092703          	lw	a4,0(s2)
    800067de:	409c                	lw	a5,0(s1)
    800067e0:	04f71d63          	bne	a4,a5,8000683a <sys_link+0x100>
    800067e4:	40d0                	lw	a2,4(s1)
    800067e6:	fd040593          	addi	a1,s0,-48
    800067ea:	854a                	mv	a0,s2
    800067ec:	fffff097          	auipc	ra,0xfffff
    800067f0:	9f0080e7          	jalr	-1552(ra) # 800051dc <dirlink>
    800067f4:	04054363          	bltz	a0,8000683a <sys_link+0x100>
  iunlockput(dp);
    800067f8:	854a                	mv	a0,s2
    800067fa:	ffffe097          	auipc	ra,0xffffe
    800067fe:	550080e7          	jalr	1360(ra) # 80004d4a <iunlockput>
  iput(ip);
    80006802:	8526                	mv	a0,s1
    80006804:	ffffe097          	auipc	ra,0xffffe
    80006808:	49e080e7          	jalr	1182(ra) # 80004ca2 <iput>
  end_op();
    8000680c:	fffff097          	auipc	ra,0xfffff
    80006810:	d2e080e7          	jalr	-722(ra) # 8000553a <end_op>
  return 0;
    80006814:	4781                	li	a5,0
    80006816:	a085                	j	80006876 <sys_link+0x13c>
    end_op();
    80006818:	fffff097          	auipc	ra,0xfffff
    8000681c:	d22080e7          	jalr	-734(ra) # 8000553a <end_op>
    return -1;
    80006820:	57fd                	li	a5,-1
    80006822:	a891                	j	80006876 <sys_link+0x13c>
    iunlockput(ip);
    80006824:	8526                	mv	a0,s1
    80006826:	ffffe097          	auipc	ra,0xffffe
    8000682a:	524080e7          	jalr	1316(ra) # 80004d4a <iunlockput>
    end_op();
    8000682e:	fffff097          	auipc	ra,0xfffff
    80006832:	d0c080e7          	jalr	-756(ra) # 8000553a <end_op>
    return -1;
    80006836:	57fd                	li	a5,-1
    80006838:	a83d                	j	80006876 <sys_link+0x13c>
    iunlockput(dp);
    8000683a:	854a                	mv	a0,s2
    8000683c:	ffffe097          	auipc	ra,0xffffe
    80006840:	50e080e7          	jalr	1294(ra) # 80004d4a <iunlockput>
  ilock(ip);
    80006844:	8526                	mv	a0,s1
    80006846:	ffffe097          	auipc	ra,0xffffe
    8000684a:	2a2080e7          	jalr	674(ra) # 80004ae8 <ilock>
  ip->nlink--;
    8000684e:	04a4d783          	lhu	a5,74(s1)
    80006852:	37fd                	addiw	a5,a5,-1
    80006854:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006858:	8526                	mv	a0,s1
    8000685a:	ffffe097          	auipc	ra,0xffffe
    8000685e:	1c4080e7          	jalr	452(ra) # 80004a1e <iupdate>
  iunlockput(ip);
    80006862:	8526                	mv	a0,s1
    80006864:	ffffe097          	auipc	ra,0xffffe
    80006868:	4e6080e7          	jalr	1254(ra) # 80004d4a <iunlockput>
  end_op();
    8000686c:	fffff097          	auipc	ra,0xfffff
    80006870:	cce080e7          	jalr	-818(ra) # 8000553a <end_op>
  return -1;
    80006874:	57fd                	li	a5,-1
}
    80006876:	853e                	mv	a0,a5
    80006878:	70b2                	ld	ra,296(sp)
    8000687a:	7412                	ld	s0,288(sp)
    8000687c:	64f2                	ld	s1,280(sp)
    8000687e:	6952                	ld	s2,272(sp)
    80006880:	6155                	addi	sp,sp,304
    80006882:	8082                	ret

0000000080006884 <sys_unlink>:
{
    80006884:	7151                	addi	sp,sp,-240
    80006886:	f586                	sd	ra,232(sp)
    80006888:	f1a2                	sd	s0,224(sp)
    8000688a:	eda6                	sd	s1,216(sp)
    8000688c:	e9ca                	sd	s2,208(sp)
    8000688e:	e5ce                	sd	s3,200(sp)
    80006890:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006892:	08000613          	li	a2,128
    80006896:	f3040593          	addi	a1,s0,-208
    8000689a:	4501                	li	a0,0
    8000689c:	ffffd097          	auipc	ra,0xffffd
    800068a0:	672080e7          	jalr	1650(ra) # 80003f0e <argstr>
    800068a4:	18054163          	bltz	a0,80006a26 <sys_unlink+0x1a2>
  begin_op();
    800068a8:	fffff097          	auipc	ra,0xfffff
    800068ac:	c12080e7          	jalr	-1006(ra) # 800054ba <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800068b0:	fb040593          	addi	a1,s0,-80
    800068b4:	f3040513          	addi	a0,s0,-208
    800068b8:	fffff097          	auipc	ra,0xfffff
    800068bc:	a04080e7          	jalr	-1532(ra) # 800052bc <nameiparent>
    800068c0:	84aa                	mv	s1,a0
    800068c2:	c979                	beqz	a0,80006998 <sys_unlink+0x114>
  ilock(dp);
    800068c4:	ffffe097          	auipc	ra,0xffffe
    800068c8:	224080e7          	jalr	548(ra) # 80004ae8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800068cc:	00003597          	auipc	a1,0x3
    800068d0:	04c58593          	addi	a1,a1,76 # 80009918 <syscalls+0x2d8>
    800068d4:	fb040513          	addi	a0,s0,-80
    800068d8:	ffffe097          	auipc	ra,0xffffe
    800068dc:	6da080e7          	jalr	1754(ra) # 80004fb2 <namecmp>
    800068e0:	14050a63          	beqz	a0,80006a34 <sys_unlink+0x1b0>
    800068e4:	00003597          	auipc	a1,0x3
    800068e8:	03c58593          	addi	a1,a1,60 # 80009920 <syscalls+0x2e0>
    800068ec:	fb040513          	addi	a0,s0,-80
    800068f0:	ffffe097          	auipc	ra,0xffffe
    800068f4:	6c2080e7          	jalr	1730(ra) # 80004fb2 <namecmp>
    800068f8:	12050e63          	beqz	a0,80006a34 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800068fc:	f2c40613          	addi	a2,s0,-212
    80006900:	fb040593          	addi	a1,s0,-80
    80006904:	8526                	mv	a0,s1
    80006906:	ffffe097          	auipc	ra,0xffffe
    8000690a:	6c6080e7          	jalr	1734(ra) # 80004fcc <dirlookup>
    8000690e:	892a                	mv	s2,a0
    80006910:	12050263          	beqz	a0,80006a34 <sys_unlink+0x1b0>
  ilock(ip);
    80006914:	ffffe097          	auipc	ra,0xffffe
    80006918:	1d4080e7          	jalr	468(ra) # 80004ae8 <ilock>
  if(ip->nlink < 1)
    8000691c:	04a91783          	lh	a5,74(s2)
    80006920:	08f05263          	blez	a5,800069a4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006924:	04491703          	lh	a4,68(s2)
    80006928:	4785                	li	a5,1
    8000692a:	08f70563          	beq	a4,a5,800069b4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000692e:	4641                	li	a2,16
    80006930:	4581                	li	a1,0
    80006932:	fc040513          	addi	a0,s0,-64
    80006936:	ffffa097          	auipc	ra,0xffffa
    8000693a:	3aa080e7          	jalr	938(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000693e:	4741                	li	a4,16
    80006940:	f2c42683          	lw	a3,-212(s0)
    80006944:	fc040613          	addi	a2,s0,-64
    80006948:	4581                	li	a1,0
    8000694a:	8526                	mv	a0,s1
    8000694c:	ffffe097          	auipc	ra,0xffffe
    80006950:	548080e7          	jalr	1352(ra) # 80004e94 <writei>
    80006954:	47c1                	li	a5,16
    80006956:	0af51563          	bne	a0,a5,80006a00 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000695a:	04491703          	lh	a4,68(s2)
    8000695e:	4785                	li	a5,1
    80006960:	0af70863          	beq	a4,a5,80006a10 <sys_unlink+0x18c>
  iunlockput(dp);
    80006964:	8526                	mv	a0,s1
    80006966:	ffffe097          	auipc	ra,0xffffe
    8000696a:	3e4080e7          	jalr	996(ra) # 80004d4a <iunlockput>
  ip->nlink--;
    8000696e:	04a95783          	lhu	a5,74(s2)
    80006972:	37fd                	addiw	a5,a5,-1
    80006974:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006978:	854a                	mv	a0,s2
    8000697a:	ffffe097          	auipc	ra,0xffffe
    8000697e:	0a4080e7          	jalr	164(ra) # 80004a1e <iupdate>
  iunlockput(ip);
    80006982:	854a                	mv	a0,s2
    80006984:	ffffe097          	auipc	ra,0xffffe
    80006988:	3c6080e7          	jalr	966(ra) # 80004d4a <iunlockput>
  end_op();
    8000698c:	fffff097          	auipc	ra,0xfffff
    80006990:	bae080e7          	jalr	-1106(ra) # 8000553a <end_op>
  return 0;
    80006994:	4501                	li	a0,0
    80006996:	a84d                	j	80006a48 <sys_unlink+0x1c4>
    end_op();
    80006998:	fffff097          	auipc	ra,0xfffff
    8000699c:	ba2080e7          	jalr	-1118(ra) # 8000553a <end_op>
    return -1;
    800069a0:	557d                	li	a0,-1
    800069a2:	a05d                	j	80006a48 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800069a4:	00003517          	auipc	a0,0x3
    800069a8:	fa450513          	addi	a0,a0,-92 # 80009948 <syscalls+0x308>
    800069ac:	ffffa097          	auipc	ra,0xffffa
    800069b0:	b92080e7          	jalr	-1134(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800069b4:	04c92703          	lw	a4,76(s2)
    800069b8:	02000793          	li	a5,32
    800069bc:	f6e7f9e3          	bgeu	a5,a4,8000692e <sys_unlink+0xaa>
    800069c0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800069c4:	4741                	li	a4,16
    800069c6:	86ce                	mv	a3,s3
    800069c8:	f1840613          	addi	a2,s0,-232
    800069cc:	4581                	li	a1,0
    800069ce:	854a                	mv	a0,s2
    800069d0:	ffffe097          	auipc	ra,0xffffe
    800069d4:	3cc080e7          	jalr	972(ra) # 80004d9c <readi>
    800069d8:	47c1                	li	a5,16
    800069da:	00f51b63          	bne	a0,a5,800069f0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800069de:	f1845783          	lhu	a5,-232(s0)
    800069e2:	e7a1                	bnez	a5,80006a2a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800069e4:	29c1                	addiw	s3,s3,16
    800069e6:	04c92783          	lw	a5,76(s2)
    800069ea:	fcf9ede3          	bltu	s3,a5,800069c4 <sys_unlink+0x140>
    800069ee:	b781                	j	8000692e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800069f0:	00003517          	auipc	a0,0x3
    800069f4:	f7050513          	addi	a0,a0,-144 # 80009960 <syscalls+0x320>
    800069f8:	ffffa097          	auipc	ra,0xffffa
    800069fc:	b46080e7          	jalr	-1210(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006a00:	00003517          	auipc	a0,0x3
    80006a04:	f7850513          	addi	a0,a0,-136 # 80009978 <syscalls+0x338>
    80006a08:	ffffa097          	auipc	ra,0xffffa
    80006a0c:	b36080e7          	jalr	-1226(ra) # 8000053e <panic>
    dp->nlink--;
    80006a10:	04a4d783          	lhu	a5,74(s1)
    80006a14:	37fd                	addiw	a5,a5,-1
    80006a16:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006a1a:	8526                	mv	a0,s1
    80006a1c:	ffffe097          	auipc	ra,0xffffe
    80006a20:	002080e7          	jalr	2(ra) # 80004a1e <iupdate>
    80006a24:	b781                	j	80006964 <sys_unlink+0xe0>
    return -1;
    80006a26:	557d                	li	a0,-1
    80006a28:	a005                	j	80006a48 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006a2a:	854a                	mv	a0,s2
    80006a2c:	ffffe097          	auipc	ra,0xffffe
    80006a30:	31e080e7          	jalr	798(ra) # 80004d4a <iunlockput>
  iunlockput(dp);
    80006a34:	8526                	mv	a0,s1
    80006a36:	ffffe097          	auipc	ra,0xffffe
    80006a3a:	314080e7          	jalr	788(ra) # 80004d4a <iunlockput>
  end_op();
    80006a3e:	fffff097          	auipc	ra,0xfffff
    80006a42:	afc080e7          	jalr	-1284(ra) # 8000553a <end_op>
  return -1;
    80006a46:	557d                	li	a0,-1
}
    80006a48:	70ae                	ld	ra,232(sp)
    80006a4a:	740e                	ld	s0,224(sp)
    80006a4c:	64ee                	ld	s1,216(sp)
    80006a4e:	694e                	ld	s2,208(sp)
    80006a50:	69ae                	ld	s3,200(sp)
    80006a52:	616d                	addi	sp,sp,240
    80006a54:	8082                	ret

0000000080006a56 <sys_open>:

uint64
sys_open(void)
{
    80006a56:	7131                	addi	sp,sp,-192
    80006a58:	fd06                	sd	ra,184(sp)
    80006a5a:	f922                	sd	s0,176(sp)
    80006a5c:	f526                	sd	s1,168(sp)
    80006a5e:	f14a                	sd	s2,160(sp)
    80006a60:	ed4e                	sd	s3,152(sp)
    80006a62:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006a64:	08000613          	li	a2,128
    80006a68:	f5040593          	addi	a1,s0,-176
    80006a6c:	4501                	li	a0,0
    80006a6e:	ffffd097          	auipc	ra,0xffffd
    80006a72:	4a0080e7          	jalr	1184(ra) # 80003f0e <argstr>
    return -1;
    80006a76:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006a78:	0c054163          	bltz	a0,80006b3a <sys_open+0xe4>
    80006a7c:	f4c40593          	addi	a1,s0,-180
    80006a80:	4505                	li	a0,1
    80006a82:	ffffd097          	auipc	ra,0xffffd
    80006a86:	448080e7          	jalr	1096(ra) # 80003eca <argint>
    80006a8a:	0a054863          	bltz	a0,80006b3a <sys_open+0xe4>

  begin_op();
    80006a8e:	fffff097          	auipc	ra,0xfffff
    80006a92:	a2c080e7          	jalr	-1492(ra) # 800054ba <begin_op>

  if(omode & O_CREATE){
    80006a96:	f4c42783          	lw	a5,-180(s0)
    80006a9a:	2007f793          	andi	a5,a5,512
    80006a9e:	cbdd                	beqz	a5,80006b54 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006aa0:	4681                	li	a3,0
    80006aa2:	4601                	li	a2,0
    80006aa4:	4589                	li	a1,2
    80006aa6:	f5040513          	addi	a0,s0,-176
    80006aaa:	00000097          	auipc	ra,0x0
    80006aae:	970080e7          	jalr	-1680(ra) # 8000641a <create>
    80006ab2:	892a                	mv	s2,a0
    if(ip == 0){
    80006ab4:	c959                	beqz	a0,80006b4a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006ab6:	04491703          	lh	a4,68(s2)
    80006aba:	478d                	li	a5,3
    80006abc:	00f71763          	bne	a4,a5,80006aca <sys_open+0x74>
    80006ac0:	04695703          	lhu	a4,70(s2)
    80006ac4:	47a5                	li	a5,9
    80006ac6:	0ce7ec63          	bltu	a5,a4,80006b9e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006aca:	fffff097          	auipc	ra,0xfffff
    80006ace:	e00080e7          	jalr	-512(ra) # 800058ca <filealloc>
    80006ad2:	89aa                	mv	s3,a0
    80006ad4:	10050263          	beqz	a0,80006bd8 <sys_open+0x182>
    80006ad8:	00000097          	auipc	ra,0x0
    80006adc:	900080e7          	jalr	-1792(ra) # 800063d8 <fdalloc>
    80006ae0:	84aa                	mv	s1,a0
    80006ae2:	0e054663          	bltz	a0,80006bce <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006ae6:	04491703          	lh	a4,68(s2)
    80006aea:	478d                	li	a5,3
    80006aec:	0cf70463          	beq	a4,a5,80006bb4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006af0:	4789                	li	a5,2
    80006af2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006af6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006afa:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006afe:	f4c42783          	lw	a5,-180(s0)
    80006b02:	0017c713          	xori	a4,a5,1
    80006b06:	8b05                	andi	a4,a4,1
    80006b08:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006b0c:	0037f713          	andi	a4,a5,3
    80006b10:	00e03733          	snez	a4,a4
    80006b14:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006b18:	4007f793          	andi	a5,a5,1024
    80006b1c:	c791                	beqz	a5,80006b28 <sys_open+0xd2>
    80006b1e:	04491703          	lh	a4,68(s2)
    80006b22:	4789                	li	a5,2
    80006b24:	08f70f63          	beq	a4,a5,80006bc2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006b28:	854a                	mv	a0,s2
    80006b2a:	ffffe097          	auipc	ra,0xffffe
    80006b2e:	080080e7          	jalr	128(ra) # 80004baa <iunlock>
  end_op();
    80006b32:	fffff097          	auipc	ra,0xfffff
    80006b36:	a08080e7          	jalr	-1528(ra) # 8000553a <end_op>

  return fd;
}
    80006b3a:	8526                	mv	a0,s1
    80006b3c:	70ea                	ld	ra,184(sp)
    80006b3e:	744a                	ld	s0,176(sp)
    80006b40:	74aa                	ld	s1,168(sp)
    80006b42:	790a                	ld	s2,160(sp)
    80006b44:	69ea                	ld	s3,152(sp)
    80006b46:	6129                	addi	sp,sp,192
    80006b48:	8082                	ret
      end_op();
    80006b4a:	fffff097          	auipc	ra,0xfffff
    80006b4e:	9f0080e7          	jalr	-1552(ra) # 8000553a <end_op>
      return -1;
    80006b52:	b7e5                	j	80006b3a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006b54:	f5040513          	addi	a0,s0,-176
    80006b58:	ffffe097          	auipc	ra,0xffffe
    80006b5c:	746080e7          	jalr	1862(ra) # 8000529e <namei>
    80006b60:	892a                	mv	s2,a0
    80006b62:	c905                	beqz	a0,80006b92 <sys_open+0x13c>
    ilock(ip);
    80006b64:	ffffe097          	auipc	ra,0xffffe
    80006b68:	f84080e7          	jalr	-124(ra) # 80004ae8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006b6c:	04491703          	lh	a4,68(s2)
    80006b70:	4785                	li	a5,1
    80006b72:	f4f712e3          	bne	a4,a5,80006ab6 <sys_open+0x60>
    80006b76:	f4c42783          	lw	a5,-180(s0)
    80006b7a:	dba1                	beqz	a5,80006aca <sys_open+0x74>
      iunlockput(ip);
    80006b7c:	854a                	mv	a0,s2
    80006b7e:	ffffe097          	auipc	ra,0xffffe
    80006b82:	1cc080e7          	jalr	460(ra) # 80004d4a <iunlockput>
      end_op();
    80006b86:	fffff097          	auipc	ra,0xfffff
    80006b8a:	9b4080e7          	jalr	-1612(ra) # 8000553a <end_op>
      return -1;
    80006b8e:	54fd                	li	s1,-1
    80006b90:	b76d                	j	80006b3a <sys_open+0xe4>
      end_op();
    80006b92:	fffff097          	auipc	ra,0xfffff
    80006b96:	9a8080e7          	jalr	-1624(ra) # 8000553a <end_op>
      return -1;
    80006b9a:	54fd                	li	s1,-1
    80006b9c:	bf79                	j	80006b3a <sys_open+0xe4>
    iunlockput(ip);
    80006b9e:	854a                	mv	a0,s2
    80006ba0:	ffffe097          	auipc	ra,0xffffe
    80006ba4:	1aa080e7          	jalr	426(ra) # 80004d4a <iunlockput>
    end_op();
    80006ba8:	fffff097          	auipc	ra,0xfffff
    80006bac:	992080e7          	jalr	-1646(ra) # 8000553a <end_op>
    return -1;
    80006bb0:	54fd                	li	s1,-1
    80006bb2:	b761                	j	80006b3a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006bb4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006bb8:	04691783          	lh	a5,70(s2)
    80006bbc:	02f99223          	sh	a5,36(s3)
    80006bc0:	bf2d                	j	80006afa <sys_open+0xa4>
    itrunc(ip);
    80006bc2:	854a                	mv	a0,s2
    80006bc4:	ffffe097          	auipc	ra,0xffffe
    80006bc8:	032080e7          	jalr	50(ra) # 80004bf6 <itrunc>
    80006bcc:	bfb1                	j	80006b28 <sys_open+0xd2>
      fileclose(f);
    80006bce:	854e                	mv	a0,s3
    80006bd0:	fffff097          	auipc	ra,0xfffff
    80006bd4:	db6080e7          	jalr	-586(ra) # 80005986 <fileclose>
    iunlockput(ip);
    80006bd8:	854a                	mv	a0,s2
    80006bda:	ffffe097          	auipc	ra,0xffffe
    80006bde:	170080e7          	jalr	368(ra) # 80004d4a <iunlockput>
    end_op();
    80006be2:	fffff097          	auipc	ra,0xfffff
    80006be6:	958080e7          	jalr	-1704(ra) # 8000553a <end_op>
    return -1;
    80006bea:	54fd                	li	s1,-1
    80006bec:	b7b9                	j	80006b3a <sys_open+0xe4>

0000000080006bee <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006bee:	7175                	addi	sp,sp,-144
    80006bf0:	e506                	sd	ra,136(sp)
    80006bf2:	e122                	sd	s0,128(sp)
    80006bf4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006bf6:	fffff097          	auipc	ra,0xfffff
    80006bfa:	8c4080e7          	jalr	-1852(ra) # 800054ba <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006bfe:	08000613          	li	a2,128
    80006c02:	f7040593          	addi	a1,s0,-144
    80006c06:	4501                	li	a0,0
    80006c08:	ffffd097          	auipc	ra,0xffffd
    80006c0c:	306080e7          	jalr	774(ra) # 80003f0e <argstr>
    80006c10:	02054963          	bltz	a0,80006c42 <sys_mkdir+0x54>
    80006c14:	4681                	li	a3,0
    80006c16:	4601                	li	a2,0
    80006c18:	4585                	li	a1,1
    80006c1a:	f7040513          	addi	a0,s0,-144
    80006c1e:	fffff097          	auipc	ra,0xfffff
    80006c22:	7fc080e7          	jalr	2044(ra) # 8000641a <create>
    80006c26:	cd11                	beqz	a0,80006c42 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006c28:	ffffe097          	auipc	ra,0xffffe
    80006c2c:	122080e7          	jalr	290(ra) # 80004d4a <iunlockput>
  end_op();
    80006c30:	fffff097          	auipc	ra,0xfffff
    80006c34:	90a080e7          	jalr	-1782(ra) # 8000553a <end_op>
  return 0;
    80006c38:	4501                	li	a0,0
}
    80006c3a:	60aa                	ld	ra,136(sp)
    80006c3c:	640a                	ld	s0,128(sp)
    80006c3e:	6149                	addi	sp,sp,144
    80006c40:	8082                	ret
    end_op();
    80006c42:	fffff097          	auipc	ra,0xfffff
    80006c46:	8f8080e7          	jalr	-1800(ra) # 8000553a <end_op>
    return -1;
    80006c4a:	557d                	li	a0,-1
    80006c4c:	b7fd                	j	80006c3a <sys_mkdir+0x4c>

0000000080006c4e <sys_mknod>:

uint64
sys_mknod(void)
{
    80006c4e:	7135                	addi	sp,sp,-160
    80006c50:	ed06                	sd	ra,152(sp)
    80006c52:	e922                	sd	s0,144(sp)
    80006c54:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006c56:	fffff097          	auipc	ra,0xfffff
    80006c5a:	864080e7          	jalr	-1948(ra) # 800054ba <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006c5e:	08000613          	li	a2,128
    80006c62:	f7040593          	addi	a1,s0,-144
    80006c66:	4501                	li	a0,0
    80006c68:	ffffd097          	auipc	ra,0xffffd
    80006c6c:	2a6080e7          	jalr	678(ra) # 80003f0e <argstr>
    80006c70:	04054a63          	bltz	a0,80006cc4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006c74:	f6c40593          	addi	a1,s0,-148
    80006c78:	4505                	li	a0,1
    80006c7a:	ffffd097          	auipc	ra,0xffffd
    80006c7e:	250080e7          	jalr	592(ra) # 80003eca <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006c82:	04054163          	bltz	a0,80006cc4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006c86:	f6840593          	addi	a1,s0,-152
    80006c8a:	4509                	li	a0,2
    80006c8c:	ffffd097          	auipc	ra,0xffffd
    80006c90:	23e080e7          	jalr	574(ra) # 80003eca <argint>
     argint(1, &major) < 0 ||
    80006c94:	02054863          	bltz	a0,80006cc4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006c98:	f6841683          	lh	a3,-152(s0)
    80006c9c:	f6c41603          	lh	a2,-148(s0)
    80006ca0:	458d                	li	a1,3
    80006ca2:	f7040513          	addi	a0,s0,-144
    80006ca6:	fffff097          	auipc	ra,0xfffff
    80006caa:	774080e7          	jalr	1908(ra) # 8000641a <create>
     argint(2, &minor) < 0 ||
    80006cae:	c919                	beqz	a0,80006cc4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006cb0:	ffffe097          	auipc	ra,0xffffe
    80006cb4:	09a080e7          	jalr	154(ra) # 80004d4a <iunlockput>
  end_op();
    80006cb8:	fffff097          	auipc	ra,0xfffff
    80006cbc:	882080e7          	jalr	-1918(ra) # 8000553a <end_op>
  return 0;
    80006cc0:	4501                	li	a0,0
    80006cc2:	a031                	j	80006cce <sys_mknod+0x80>
    end_op();
    80006cc4:	fffff097          	auipc	ra,0xfffff
    80006cc8:	876080e7          	jalr	-1930(ra) # 8000553a <end_op>
    return -1;
    80006ccc:	557d                	li	a0,-1
}
    80006cce:	60ea                	ld	ra,152(sp)
    80006cd0:	644a                	ld	s0,144(sp)
    80006cd2:	610d                	addi	sp,sp,160
    80006cd4:	8082                	ret

0000000080006cd6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006cd6:	7135                	addi	sp,sp,-160
    80006cd8:	ed06                	sd	ra,152(sp)
    80006cda:	e922                	sd	s0,144(sp)
    80006cdc:	e526                	sd	s1,136(sp)
    80006cde:	e14a                	sd	s2,128(sp)
    80006ce0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006ce2:	ffffb097          	auipc	ra,0xffffb
    80006ce6:	ee2080e7          	jalr	-286(ra) # 80001bc4 <myproc>
    80006cea:	892a                	mv	s2,a0
  
  begin_op();
    80006cec:	ffffe097          	auipc	ra,0xffffe
    80006cf0:	7ce080e7          	jalr	1998(ra) # 800054ba <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006cf4:	08000613          	li	a2,128
    80006cf8:	f6040593          	addi	a1,s0,-160
    80006cfc:	4501                	li	a0,0
    80006cfe:	ffffd097          	auipc	ra,0xffffd
    80006d02:	210080e7          	jalr	528(ra) # 80003f0e <argstr>
    80006d06:	04054b63          	bltz	a0,80006d5c <sys_chdir+0x86>
    80006d0a:	f6040513          	addi	a0,s0,-160
    80006d0e:	ffffe097          	auipc	ra,0xffffe
    80006d12:	590080e7          	jalr	1424(ra) # 8000529e <namei>
    80006d16:	84aa                	mv	s1,a0
    80006d18:	c131                	beqz	a0,80006d5c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006d1a:	ffffe097          	auipc	ra,0xffffe
    80006d1e:	dce080e7          	jalr	-562(ra) # 80004ae8 <ilock>
  if(ip->type != T_DIR){
    80006d22:	04449703          	lh	a4,68(s1)
    80006d26:	4785                	li	a5,1
    80006d28:	04f71063          	bne	a4,a5,80006d68 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006d2c:	8526                	mv	a0,s1
    80006d2e:	ffffe097          	auipc	ra,0xffffe
    80006d32:	e7c080e7          	jalr	-388(ra) # 80004baa <iunlock>
  iput(p->cwd);
    80006d36:	18093503          	ld	a0,384(s2)
    80006d3a:	ffffe097          	auipc	ra,0xffffe
    80006d3e:	f68080e7          	jalr	-152(ra) # 80004ca2 <iput>
  end_op();
    80006d42:	ffffe097          	auipc	ra,0xffffe
    80006d46:	7f8080e7          	jalr	2040(ra) # 8000553a <end_op>
  p->cwd = ip;
    80006d4a:	18993023          	sd	s1,384(s2)
  return 0;
    80006d4e:	4501                	li	a0,0
}
    80006d50:	60ea                	ld	ra,152(sp)
    80006d52:	644a                	ld	s0,144(sp)
    80006d54:	64aa                	ld	s1,136(sp)
    80006d56:	690a                	ld	s2,128(sp)
    80006d58:	610d                	addi	sp,sp,160
    80006d5a:	8082                	ret
    end_op();
    80006d5c:	ffffe097          	auipc	ra,0xffffe
    80006d60:	7de080e7          	jalr	2014(ra) # 8000553a <end_op>
    return -1;
    80006d64:	557d                	li	a0,-1
    80006d66:	b7ed                	j	80006d50 <sys_chdir+0x7a>
    iunlockput(ip);
    80006d68:	8526                	mv	a0,s1
    80006d6a:	ffffe097          	auipc	ra,0xffffe
    80006d6e:	fe0080e7          	jalr	-32(ra) # 80004d4a <iunlockput>
    end_op();
    80006d72:	ffffe097          	auipc	ra,0xffffe
    80006d76:	7c8080e7          	jalr	1992(ra) # 8000553a <end_op>
    return -1;
    80006d7a:	557d                	li	a0,-1
    80006d7c:	bfd1                	j	80006d50 <sys_chdir+0x7a>

0000000080006d7e <sys_exec>:

uint64
sys_exec(void)
{
    80006d7e:	7145                	addi	sp,sp,-464
    80006d80:	e786                	sd	ra,456(sp)
    80006d82:	e3a2                	sd	s0,448(sp)
    80006d84:	ff26                	sd	s1,440(sp)
    80006d86:	fb4a                	sd	s2,432(sp)
    80006d88:	f74e                	sd	s3,424(sp)
    80006d8a:	f352                	sd	s4,416(sp)
    80006d8c:	ef56                	sd	s5,408(sp)
    80006d8e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006d90:	08000613          	li	a2,128
    80006d94:	f4040593          	addi	a1,s0,-192
    80006d98:	4501                	li	a0,0
    80006d9a:	ffffd097          	auipc	ra,0xffffd
    80006d9e:	174080e7          	jalr	372(ra) # 80003f0e <argstr>
    return -1;
    80006da2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006da4:	0c054a63          	bltz	a0,80006e78 <sys_exec+0xfa>
    80006da8:	e3840593          	addi	a1,s0,-456
    80006dac:	4505                	li	a0,1
    80006dae:	ffffd097          	auipc	ra,0xffffd
    80006db2:	13e080e7          	jalr	318(ra) # 80003eec <argaddr>
    80006db6:	0c054163          	bltz	a0,80006e78 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006dba:	10000613          	li	a2,256
    80006dbe:	4581                	li	a1,0
    80006dc0:	e4040513          	addi	a0,s0,-448
    80006dc4:	ffffa097          	auipc	ra,0xffffa
    80006dc8:	f1c080e7          	jalr	-228(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006dcc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006dd0:	89a6                	mv	s3,s1
    80006dd2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006dd4:	02000a13          	li	s4,32
    80006dd8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006ddc:	00391513          	slli	a0,s2,0x3
    80006de0:	e3040593          	addi	a1,s0,-464
    80006de4:	e3843783          	ld	a5,-456(s0)
    80006de8:	953e                	add	a0,a0,a5
    80006dea:	ffffd097          	auipc	ra,0xffffd
    80006dee:	046080e7          	jalr	70(ra) # 80003e30 <fetchaddr>
    80006df2:	02054a63          	bltz	a0,80006e26 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006df6:	e3043783          	ld	a5,-464(s0)
    80006dfa:	c3b9                	beqz	a5,80006e40 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006dfc:	ffffa097          	auipc	ra,0xffffa
    80006e00:	cf8080e7          	jalr	-776(ra) # 80000af4 <kalloc>
    80006e04:	85aa                	mv	a1,a0
    80006e06:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006e0a:	cd11                	beqz	a0,80006e26 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006e0c:	6605                	lui	a2,0x1
    80006e0e:	e3043503          	ld	a0,-464(s0)
    80006e12:	ffffd097          	auipc	ra,0xffffd
    80006e16:	070080e7          	jalr	112(ra) # 80003e82 <fetchstr>
    80006e1a:	00054663          	bltz	a0,80006e26 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006e1e:	0905                	addi	s2,s2,1
    80006e20:	09a1                	addi	s3,s3,8
    80006e22:	fb491be3          	bne	s2,s4,80006dd8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e26:	10048913          	addi	s2,s1,256
    80006e2a:	6088                	ld	a0,0(s1)
    80006e2c:	c529                	beqz	a0,80006e76 <sys_exec+0xf8>
    kfree(argv[i]);
    80006e2e:	ffffa097          	auipc	ra,0xffffa
    80006e32:	bca080e7          	jalr	-1078(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e36:	04a1                	addi	s1,s1,8
    80006e38:	ff2499e3          	bne	s1,s2,80006e2a <sys_exec+0xac>
  return -1;
    80006e3c:	597d                	li	s2,-1
    80006e3e:	a82d                	j	80006e78 <sys_exec+0xfa>
      argv[i] = 0;
    80006e40:	0a8e                	slli	s5,s5,0x3
    80006e42:	fc040793          	addi	a5,s0,-64
    80006e46:	9abe                	add	s5,s5,a5
    80006e48:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006e4c:	e4040593          	addi	a1,s0,-448
    80006e50:	f4040513          	addi	a0,s0,-192
    80006e54:	fffff097          	auipc	ra,0xfffff
    80006e58:	192080e7          	jalr	402(ra) # 80005fe6 <exec>
    80006e5c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e5e:	10048993          	addi	s3,s1,256
    80006e62:	6088                	ld	a0,0(s1)
    80006e64:	c911                	beqz	a0,80006e78 <sys_exec+0xfa>
    kfree(argv[i]);
    80006e66:	ffffa097          	auipc	ra,0xffffa
    80006e6a:	b92080e7          	jalr	-1134(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e6e:	04a1                	addi	s1,s1,8
    80006e70:	ff3499e3          	bne	s1,s3,80006e62 <sys_exec+0xe4>
    80006e74:	a011                	j	80006e78 <sys_exec+0xfa>
  return -1;
    80006e76:	597d                	li	s2,-1
}
    80006e78:	854a                	mv	a0,s2
    80006e7a:	60be                	ld	ra,456(sp)
    80006e7c:	641e                	ld	s0,448(sp)
    80006e7e:	74fa                	ld	s1,440(sp)
    80006e80:	795a                	ld	s2,432(sp)
    80006e82:	79ba                	ld	s3,424(sp)
    80006e84:	7a1a                	ld	s4,416(sp)
    80006e86:	6afa                	ld	s5,408(sp)
    80006e88:	6179                	addi	sp,sp,464
    80006e8a:	8082                	ret

0000000080006e8c <sys_pipe>:

uint64
sys_pipe(void)
{
    80006e8c:	7139                	addi	sp,sp,-64
    80006e8e:	fc06                	sd	ra,56(sp)
    80006e90:	f822                	sd	s0,48(sp)
    80006e92:	f426                	sd	s1,40(sp)
    80006e94:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006e96:	ffffb097          	auipc	ra,0xffffb
    80006e9a:	d2e080e7          	jalr	-722(ra) # 80001bc4 <myproc>
    80006e9e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006ea0:	fd840593          	addi	a1,s0,-40
    80006ea4:	4501                	li	a0,0
    80006ea6:	ffffd097          	auipc	ra,0xffffd
    80006eaa:	046080e7          	jalr	70(ra) # 80003eec <argaddr>
    return -1;
    80006eae:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006eb0:	0e054263          	bltz	a0,80006f94 <sys_pipe+0x108>
  if(pipealloc(&rf, &wf) < 0)
    80006eb4:	fc840593          	addi	a1,s0,-56
    80006eb8:	fd040513          	addi	a0,s0,-48
    80006ebc:	fffff097          	auipc	ra,0xfffff
    80006ec0:	dfa080e7          	jalr	-518(ra) # 80005cb6 <pipealloc>
    return -1;
    80006ec4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006ec6:	0c054763          	bltz	a0,80006f94 <sys_pipe+0x108>
  fd0 = -1;
    80006eca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006ece:	fd043503          	ld	a0,-48(s0)
    80006ed2:	fffff097          	auipc	ra,0xfffff
    80006ed6:	506080e7          	jalr	1286(ra) # 800063d8 <fdalloc>
    80006eda:	fca42223          	sw	a0,-60(s0)
    80006ede:	08054e63          	bltz	a0,80006f7a <sys_pipe+0xee>
    80006ee2:	fc843503          	ld	a0,-56(s0)
    80006ee6:	fffff097          	auipc	ra,0xfffff
    80006eea:	4f2080e7          	jalr	1266(ra) # 800063d8 <fdalloc>
    80006eee:	fca42023          	sw	a0,-64(s0)
    80006ef2:	06054a63          	bltz	a0,80006f66 <sys_pipe+0xda>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006ef6:	4691                	li	a3,4
    80006ef8:	fc440613          	addi	a2,s0,-60
    80006efc:	fd843583          	ld	a1,-40(s0)
    80006f00:	60c8                	ld	a0,128(s1)
    80006f02:	ffffa097          	auipc	ra,0xffffa
    80006f06:	778080e7          	jalr	1912(ra) # 8000167a <copyout>
    80006f0a:	02054063          	bltz	a0,80006f2a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006f0e:	4691                	li	a3,4
    80006f10:	fc040613          	addi	a2,s0,-64
    80006f14:	fd843583          	ld	a1,-40(s0)
    80006f18:	0591                	addi	a1,a1,4
    80006f1a:	60c8                	ld	a0,128(s1)
    80006f1c:	ffffa097          	auipc	ra,0xffffa
    80006f20:	75e080e7          	jalr	1886(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006f24:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006f26:	06055763          	bgez	a0,80006f94 <sys_pipe+0x108>
    p->ofile[fd0] = 0;
    80006f2a:	fc442783          	lw	a5,-60(s0)
    80006f2e:	02078793          	addi	a5,a5,32
    80006f32:	078e                	slli	a5,a5,0x3
    80006f34:	97a6                	add	a5,a5,s1
    80006f36:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006f3a:	fc042503          	lw	a0,-64(s0)
    80006f3e:	02050513          	addi	a0,a0,32
    80006f42:	050e                	slli	a0,a0,0x3
    80006f44:	9526                	add	a0,a0,s1
    80006f46:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006f4a:	fd043503          	ld	a0,-48(s0)
    80006f4e:	fffff097          	auipc	ra,0xfffff
    80006f52:	a38080e7          	jalr	-1480(ra) # 80005986 <fileclose>
    fileclose(wf);
    80006f56:	fc843503          	ld	a0,-56(s0)
    80006f5a:	fffff097          	auipc	ra,0xfffff
    80006f5e:	a2c080e7          	jalr	-1492(ra) # 80005986 <fileclose>
    return -1;
    80006f62:	57fd                	li	a5,-1
    80006f64:	a805                	j	80006f94 <sys_pipe+0x108>
    if(fd0 >= 0)
    80006f66:	fc442783          	lw	a5,-60(s0)
    80006f6a:	0007c863          	bltz	a5,80006f7a <sys_pipe+0xee>
      p->ofile[fd0] = 0;
    80006f6e:	02078513          	addi	a0,a5,32
    80006f72:	050e                	slli	a0,a0,0x3
    80006f74:	9526                	add	a0,a0,s1
    80006f76:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006f7a:	fd043503          	ld	a0,-48(s0)
    80006f7e:	fffff097          	auipc	ra,0xfffff
    80006f82:	a08080e7          	jalr	-1528(ra) # 80005986 <fileclose>
    fileclose(wf);
    80006f86:	fc843503          	ld	a0,-56(s0)
    80006f8a:	fffff097          	auipc	ra,0xfffff
    80006f8e:	9fc080e7          	jalr	-1540(ra) # 80005986 <fileclose>
    return -1;
    80006f92:	57fd                	li	a5,-1
}
    80006f94:	853e                	mv	a0,a5
    80006f96:	70e2                	ld	ra,56(sp)
    80006f98:	7442                	ld	s0,48(sp)
    80006f9a:	74a2                	ld	s1,40(sp)
    80006f9c:	6121                	addi	sp,sp,64
    80006f9e:	8082                	ret

0000000080006fa0 <kernelvec>:
    80006fa0:	7111                	addi	sp,sp,-256
    80006fa2:	e006                	sd	ra,0(sp)
    80006fa4:	e40a                	sd	sp,8(sp)
    80006fa6:	e80e                	sd	gp,16(sp)
    80006fa8:	ec12                	sd	tp,24(sp)
    80006faa:	f016                	sd	t0,32(sp)
    80006fac:	f41a                	sd	t1,40(sp)
    80006fae:	f81e                	sd	t2,48(sp)
    80006fb0:	fc22                	sd	s0,56(sp)
    80006fb2:	e0a6                	sd	s1,64(sp)
    80006fb4:	e4aa                	sd	a0,72(sp)
    80006fb6:	e8ae                	sd	a1,80(sp)
    80006fb8:	ecb2                	sd	a2,88(sp)
    80006fba:	f0b6                	sd	a3,96(sp)
    80006fbc:	f4ba                	sd	a4,104(sp)
    80006fbe:	f8be                	sd	a5,112(sp)
    80006fc0:	fcc2                	sd	a6,120(sp)
    80006fc2:	e146                	sd	a7,128(sp)
    80006fc4:	e54a                	sd	s2,136(sp)
    80006fc6:	e94e                	sd	s3,144(sp)
    80006fc8:	ed52                	sd	s4,152(sp)
    80006fca:	f156                	sd	s5,160(sp)
    80006fcc:	f55a                	sd	s6,168(sp)
    80006fce:	f95e                	sd	s7,176(sp)
    80006fd0:	fd62                	sd	s8,184(sp)
    80006fd2:	e1e6                	sd	s9,192(sp)
    80006fd4:	e5ea                	sd	s10,200(sp)
    80006fd6:	e9ee                	sd	s11,208(sp)
    80006fd8:	edf2                	sd	t3,216(sp)
    80006fda:	f1f6                	sd	t4,224(sp)
    80006fdc:	f5fa                	sd	t5,232(sp)
    80006fde:	f9fe                	sd	t6,240(sp)
    80006fe0:	cf1fc0ef          	jal	ra,80003cd0 <kerneltrap>
    80006fe4:	6082                	ld	ra,0(sp)
    80006fe6:	6122                	ld	sp,8(sp)
    80006fe8:	61c2                	ld	gp,16(sp)
    80006fea:	7282                	ld	t0,32(sp)
    80006fec:	7322                	ld	t1,40(sp)
    80006fee:	73c2                	ld	t2,48(sp)
    80006ff0:	7462                	ld	s0,56(sp)
    80006ff2:	6486                	ld	s1,64(sp)
    80006ff4:	6526                	ld	a0,72(sp)
    80006ff6:	65c6                	ld	a1,80(sp)
    80006ff8:	6666                	ld	a2,88(sp)
    80006ffa:	7686                	ld	a3,96(sp)
    80006ffc:	7726                	ld	a4,104(sp)
    80006ffe:	77c6                	ld	a5,112(sp)
    80007000:	7866                	ld	a6,120(sp)
    80007002:	688a                	ld	a7,128(sp)
    80007004:	692a                	ld	s2,136(sp)
    80007006:	69ca                	ld	s3,144(sp)
    80007008:	6a6a                	ld	s4,152(sp)
    8000700a:	7a8a                	ld	s5,160(sp)
    8000700c:	7b2a                	ld	s6,168(sp)
    8000700e:	7bca                	ld	s7,176(sp)
    80007010:	7c6a                	ld	s8,184(sp)
    80007012:	6c8e                	ld	s9,192(sp)
    80007014:	6d2e                	ld	s10,200(sp)
    80007016:	6dce                	ld	s11,208(sp)
    80007018:	6e6e                	ld	t3,216(sp)
    8000701a:	7e8e                	ld	t4,224(sp)
    8000701c:	7f2e                	ld	t5,232(sp)
    8000701e:	7fce                	ld	t6,240(sp)
    80007020:	6111                	addi	sp,sp,256
    80007022:	10200073          	sret
    80007026:	00000013          	nop
    8000702a:	00000013          	nop
    8000702e:	0001                	nop

0000000080007030 <timervec>:
    80007030:	34051573          	csrrw	a0,mscratch,a0
    80007034:	e10c                	sd	a1,0(a0)
    80007036:	e510                	sd	a2,8(a0)
    80007038:	e914                	sd	a3,16(a0)
    8000703a:	6d0c                	ld	a1,24(a0)
    8000703c:	7110                	ld	a2,32(a0)
    8000703e:	6194                	ld	a3,0(a1)
    80007040:	96b2                	add	a3,a3,a2
    80007042:	e194                	sd	a3,0(a1)
    80007044:	4589                	li	a1,2
    80007046:	14459073          	csrw	sip,a1
    8000704a:	6914                	ld	a3,16(a0)
    8000704c:	6510                	ld	a2,8(a0)
    8000704e:	610c                	ld	a1,0(a0)
    80007050:	34051573          	csrrw	a0,mscratch,a0
    80007054:	30200073          	mret
	...

000000008000705a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000705a:	1141                	addi	sp,sp,-16
    8000705c:	e422                	sd	s0,8(sp)
    8000705e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80007060:	0c0007b7          	lui	a5,0xc000
    80007064:	4705                	li	a4,1
    80007066:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80007068:	c3d8                	sw	a4,4(a5)
}
    8000706a:	6422                	ld	s0,8(sp)
    8000706c:	0141                	addi	sp,sp,16
    8000706e:	8082                	ret

0000000080007070 <plicinithart>:

void
plicinithart(void)
{
    80007070:	1141                	addi	sp,sp,-16
    80007072:	e406                	sd	ra,8(sp)
    80007074:	e022                	sd	s0,0(sp)
    80007076:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80007078:	ffffb097          	auipc	ra,0xffffb
    8000707c:	b10080e7          	jalr	-1264(ra) # 80001b88 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80007080:	0085171b          	slliw	a4,a0,0x8
    80007084:	0c0027b7          	lui	a5,0xc002
    80007088:	97ba                	add	a5,a5,a4
    8000708a:	40200713          	li	a4,1026
    8000708e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80007092:	00d5151b          	slliw	a0,a0,0xd
    80007096:	0c2017b7          	lui	a5,0xc201
    8000709a:	953e                	add	a0,a0,a5
    8000709c:	00052023          	sw	zero,0(a0)
}
    800070a0:	60a2                	ld	ra,8(sp)
    800070a2:	6402                	ld	s0,0(sp)
    800070a4:	0141                	addi	sp,sp,16
    800070a6:	8082                	ret

00000000800070a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800070a8:	1141                	addi	sp,sp,-16
    800070aa:	e406                	sd	ra,8(sp)
    800070ac:	e022                	sd	s0,0(sp)
    800070ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800070b0:	ffffb097          	auipc	ra,0xffffb
    800070b4:	ad8080e7          	jalr	-1320(ra) # 80001b88 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800070b8:	00d5179b          	slliw	a5,a0,0xd
    800070bc:	0c201537          	lui	a0,0xc201
    800070c0:	953e                	add	a0,a0,a5
  return irq;
}
    800070c2:	4148                	lw	a0,4(a0)
    800070c4:	60a2                	ld	ra,8(sp)
    800070c6:	6402                	ld	s0,0(sp)
    800070c8:	0141                	addi	sp,sp,16
    800070ca:	8082                	ret

00000000800070cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800070cc:	1101                	addi	sp,sp,-32
    800070ce:	ec06                	sd	ra,24(sp)
    800070d0:	e822                	sd	s0,16(sp)
    800070d2:	e426                	sd	s1,8(sp)
    800070d4:	1000                	addi	s0,sp,32
    800070d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800070d8:	ffffb097          	auipc	ra,0xffffb
    800070dc:	ab0080e7          	jalr	-1360(ra) # 80001b88 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800070e0:	00d5151b          	slliw	a0,a0,0xd
    800070e4:	0c2017b7          	lui	a5,0xc201
    800070e8:	97aa                	add	a5,a5,a0
    800070ea:	c3c4                	sw	s1,4(a5)
}
    800070ec:	60e2                	ld	ra,24(sp)
    800070ee:	6442                	ld	s0,16(sp)
    800070f0:	64a2                	ld	s1,8(sp)
    800070f2:	6105                	addi	sp,sp,32
    800070f4:	8082                	ret

00000000800070f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800070f6:	1141                	addi	sp,sp,-16
    800070f8:	e406                	sd	ra,8(sp)
    800070fa:	e022                	sd	s0,0(sp)
    800070fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800070fe:	479d                	li	a5,7
    80007100:	06a7c963          	blt	a5,a0,80007172 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80007104:	0001e797          	auipc	a5,0x1e
    80007108:	efc78793          	addi	a5,a5,-260 # 80025000 <disk>
    8000710c:	00a78733          	add	a4,a5,a0
    80007110:	6789                	lui	a5,0x2
    80007112:	97ba                	add	a5,a5,a4
    80007114:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80007118:	e7ad                	bnez	a5,80007182 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000711a:	00451793          	slli	a5,a0,0x4
    8000711e:	00020717          	auipc	a4,0x20
    80007122:	ee270713          	addi	a4,a4,-286 # 80027000 <disk+0x2000>
    80007126:	6314                	ld	a3,0(a4)
    80007128:	96be                	add	a3,a3,a5
    8000712a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000712e:	6314                	ld	a3,0(a4)
    80007130:	96be                	add	a3,a3,a5
    80007132:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80007136:	6314                	ld	a3,0(a4)
    80007138:	96be                	add	a3,a3,a5
    8000713a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000713e:	6318                	ld	a4,0(a4)
    80007140:	97ba                	add	a5,a5,a4
    80007142:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80007146:	0001e797          	auipc	a5,0x1e
    8000714a:	eba78793          	addi	a5,a5,-326 # 80025000 <disk>
    8000714e:	97aa                	add	a5,a5,a0
    80007150:	6509                	lui	a0,0x2
    80007152:	953e                	add	a0,a0,a5
    80007154:	4785                	li	a5,1
    80007156:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000715a:	00020517          	auipc	a0,0x20
    8000715e:	ebe50513          	addi	a0,a0,-322 # 80027018 <disk+0x2018>
    80007162:	ffffc097          	auipc	ra,0xffffc
    80007166:	de8080e7          	jalr	-536(ra) # 80002f4a <wakeup>
}
    8000716a:	60a2                	ld	ra,8(sp)
    8000716c:	6402                	ld	s0,0(sp)
    8000716e:	0141                	addi	sp,sp,16
    80007170:	8082                	ret
    panic("free_desc 1");
    80007172:	00003517          	auipc	a0,0x3
    80007176:	81650513          	addi	a0,a0,-2026 # 80009988 <syscalls+0x348>
    8000717a:	ffff9097          	auipc	ra,0xffff9
    8000717e:	3c4080e7          	jalr	964(ra) # 8000053e <panic>
    panic("free_desc 2");
    80007182:	00003517          	auipc	a0,0x3
    80007186:	81650513          	addi	a0,a0,-2026 # 80009998 <syscalls+0x358>
    8000718a:	ffff9097          	auipc	ra,0xffff9
    8000718e:	3b4080e7          	jalr	948(ra) # 8000053e <panic>

0000000080007192 <virtio_disk_init>:
{
    80007192:	1101                	addi	sp,sp,-32
    80007194:	ec06                	sd	ra,24(sp)
    80007196:	e822                	sd	s0,16(sp)
    80007198:	e426                	sd	s1,8(sp)
    8000719a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000719c:	00003597          	auipc	a1,0x3
    800071a0:	80c58593          	addi	a1,a1,-2036 # 800099a8 <syscalls+0x368>
    800071a4:	00020517          	auipc	a0,0x20
    800071a8:	f8450513          	addi	a0,a0,-124 # 80027128 <disk+0x2128>
    800071ac:	ffffa097          	auipc	ra,0xffffa
    800071b0:	9a8080e7          	jalr	-1624(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800071b4:	100017b7          	lui	a5,0x10001
    800071b8:	4398                	lw	a4,0(a5)
    800071ba:	2701                	sext.w	a4,a4
    800071bc:	747277b7          	lui	a5,0x74727
    800071c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800071c4:	0ef71163          	bne	a4,a5,800072a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800071c8:	100017b7          	lui	a5,0x10001
    800071cc:	43dc                	lw	a5,4(a5)
    800071ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800071d0:	4705                	li	a4,1
    800071d2:	0ce79a63          	bne	a5,a4,800072a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800071d6:	100017b7          	lui	a5,0x10001
    800071da:	479c                	lw	a5,8(a5)
    800071dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800071de:	4709                	li	a4,2
    800071e0:	0ce79363          	bne	a5,a4,800072a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800071e4:	100017b7          	lui	a5,0x10001
    800071e8:	47d8                	lw	a4,12(a5)
    800071ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800071ec:	554d47b7          	lui	a5,0x554d4
    800071f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800071f4:	0af71963          	bne	a4,a5,800072a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800071f8:	100017b7          	lui	a5,0x10001
    800071fc:	4705                	li	a4,1
    800071fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007200:	470d                	li	a4,3
    80007202:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80007204:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80007206:	c7ffe737          	lui	a4,0xc7ffe
    8000720a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    8000720e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80007210:	2701                	sext.w	a4,a4
    80007212:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007214:	472d                	li	a4,11
    80007216:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007218:	473d                	li	a4,15
    8000721a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000721c:	6705                	lui	a4,0x1
    8000721e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80007220:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80007224:	5bdc                	lw	a5,52(a5)
    80007226:	2781                	sext.w	a5,a5
  if(max == 0)
    80007228:	c7d9                	beqz	a5,800072b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000722a:	471d                	li	a4,7
    8000722c:	08f77d63          	bgeu	a4,a5,800072c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80007230:	100014b7          	lui	s1,0x10001
    80007234:	47a1                	li	a5,8
    80007236:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80007238:	6609                	lui	a2,0x2
    8000723a:	4581                	li	a1,0
    8000723c:	0001e517          	auipc	a0,0x1e
    80007240:	dc450513          	addi	a0,a0,-572 # 80025000 <disk>
    80007244:	ffffa097          	auipc	ra,0xffffa
    80007248:	a9c080e7          	jalr	-1380(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000724c:	0001e717          	auipc	a4,0x1e
    80007250:	db470713          	addi	a4,a4,-588 # 80025000 <disk>
    80007254:	00c75793          	srli	a5,a4,0xc
    80007258:	2781                	sext.w	a5,a5
    8000725a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000725c:	00020797          	auipc	a5,0x20
    80007260:	da478793          	addi	a5,a5,-604 # 80027000 <disk+0x2000>
    80007264:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80007266:	0001e717          	auipc	a4,0x1e
    8000726a:	e1a70713          	addi	a4,a4,-486 # 80025080 <disk+0x80>
    8000726e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80007270:	0001f717          	auipc	a4,0x1f
    80007274:	d9070713          	addi	a4,a4,-624 # 80026000 <disk+0x1000>
    80007278:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000727a:	4705                	li	a4,1
    8000727c:	00e78c23          	sb	a4,24(a5)
    80007280:	00e78ca3          	sb	a4,25(a5)
    80007284:	00e78d23          	sb	a4,26(a5)
    80007288:	00e78da3          	sb	a4,27(a5)
    8000728c:	00e78e23          	sb	a4,28(a5)
    80007290:	00e78ea3          	sb	a4,29(a5)
    80007294:	00e78f23          	sb	a4,30(a5)
    80007298:	00e78fa3          	sb	a4,31(a5)
}
    8000729c:	60e2                	ld	ra,24(sp)
    8000729e:	6442                	ld	s0,16(sp)
    800072a0:	64a2                	ld	s1,8(sp)
    800072a2:	6105                	addi	sp,sp,32
    800072a4:	8082                	ret
    panic("could not find virtio disk");
    800072a6:	00002517          	auipc	a0,0x2
    800072aa:	71250513          	addi	a0,a0,1810 # 800099b8 <syscalls+0x378>
    800072ae:	ffff9097          	auipc	ra,0xffff9
    800072b2:	290080e7          	jalr	656(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800072b6:	00002517          	auipc	a0,0x2
    800072ba:	72250513          	addi	a0,a0,1826 # 800099d8 <syscalls+0x398>
    800072be:	ffff9097          	auipc	ra,0xffff9
    800072c2:	280080e7          	jalr	640(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800072c6:	00002517          	auipc	a0,0x2
    800072ca:	73250513          	addi	a0,a0,1842 # 800099f8 <syscalls+0x3b8>
    800072ce:	ffff9097          	auipc	ra,0xffff9
    800072d2:	270080e7          	jalr	624(ra) # 8000053e <panic>

00000000800072d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800072d6:	7159                	addi	sp,sp,-112
    800072d8:	f486                	sd	ra,104(sp)
    800072da:	f0a2                	sd	s0,96(sp)
    800072dc:	eca6                	sd	s1,88(sp)
    800072de:	e8ca                	sd	s2,80(sp)
    800072e0:	e4ce                	sd	s3,72(sp)
    800072e2:	e0d2                	sd	s4,64(sp)
    800072e4:	fc56                	sd	s5,56(sp)
    800072e6:	f85a                	sd	s6,48(sp)
    800072e8:	f45e                	sd	s7,40(sp)
    800072ea:	f062                	sd	s8,32(sp)
    800072ec:	ec66                	sd	s9,24(sp)
    800072ee:	e86a                	sd	s10,16(sp)
    800072f0:	1880                	addi	s0,sp,112
    800072f2:	892a                	mv	s2,a0
    800072f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800072f6:	00c52c83          	lw	s9,12(a0)
    800072fa:	001c9c9b          	slliw	s9,s9,0x1
    800072fe:	1c82                	slli	s9,s9,0x20
    80007300:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007304:	00020517          	auipc	a0,0x20
    80007308:	e2450513          	addi	a0,a0,-476 # 80027128 <disk+0x2128>
    8000730c:	ffffa097          	auipc	ra,0xffffa
    80007310:	8d8080e7          	jalr	-1832(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80007314:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007316:	4c21                	li	s8,8
      disk.free[i] = 0;
    80007318:	0001eb97          	auipc	s7,0x1e
    8000731c:	ce8b8b93          	addi	s7,s7,-792 # 80025000 <disk>
    80007320:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80007322:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80007324:	8a4e                	mv	s4,s3
    80007326:	a051                	j	800073aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80007328:	00fb86b3          	add	a3,s7,a5
    8000732c:	96da                	add	a3,a3,s6
    8000732e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80007332:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80007334:	0207c563          	bltz	a5,8000735e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80007338:	2485                	addiw	s1,s1,1
    8000733a:	0711                	addi	a4,a4,4
    8000733c:	25548063          	beq	s1,s5,8000757c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80007340:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80007342:	00020697          	auipc	a3,0x20
    80007346:	cd668693          	addi	a3,a3,-810 # 80027018 <disk+0x2018>
    8000734a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000734c:	0006c583          	lbu	a1,0(a3)
    80007350:	fde1                	bnez	a1,80007328 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80007352:	2785                	addiw	a5,a5,1
    80007354:	0685                	addi	a3,a3,1
    80007356:	ff879be3          	bne	a5,s8,8000734c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000735a:	57fd                	li	a5,-1
    8000735c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000735e:	02905a63          	blez	s1,80007392 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007362:	f9042503          	lw	a0,-112(s0)
    80007366:	00000097          	auipc	ra,0x0
    8000736a:	d90080e7          	jalr	-624(ra) # 800070f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000736e:	4785                	li	a5,1
    80007370:	0297d163          	bge	a5,s1,80007392 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007374:	f9442503          	lw	a0,-108(s0)
    80007378:	00000097          	auipc	ra,0x0
    8000737c:	d7e080e7          	jalr	-642(ra) # 800070f6 <free_desc>
      for(int j = 0; j < i; j++)
    80007380:	4789                	li	a5,2
    80007382:	0097d863          	bge	a5,s1,80007392 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80007386:	f9842503          	lw	a0,-104(s0)
    8000738a:	00000097          	auipc	ra,0x0
    8000738e:	d6c080e7          	jalr	-660(ra) # 800070f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80007392:	00020597          	auipc	a1,0x20
    80007396:	d9658593          	addi	a1,a1,-618 # 80027128 <disk+0x2128>
    8000739a:	00020517          	auipc	a0,0x20
    8000739e:	c7e50513          	addi	a0,a0,-898 # 80027018 <disk+0x2018>
    800073a2:	ffffc097          	auipc	ra,0xffffc
    800073a6:	842080e7          	jalr	-1982(ra) # 80002be4 <sleep>
  for(int i = 0; i < 3; i++){
    800073aa:	f9040713          	addi	a4,s0,-112
    800073ae:	84ce                	mv	s1,s3
    800073b0:	bf41                	j	80007340 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800073b2:	20058713          	addi	a4,a1,512
    800073b6:	00471693          	slli	a3,a4,0x4
    800073ba:	0001e717          	auipc	a4,0x1e
    800073be:	c4670713          	addi	a4,a4,-954 # 80025000 <disk>
    800073c2:	9736                	add	a4,a4,a3
    800073c4:	4685                	li	a3,1
    800073c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800073ca:	20058713          	addi	a4,a1,512
    800073ce:	00471693          	slli	a3,a4,0x4
    800073d2:	0001e717          	auipc	a4,0x1e
    800073d6:	c2e70713          	addi	a4,a4,-978 # 80025000 <disk>
    800073da:	9736                	add	a4,a4,a3
    800073dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800073e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800073e4:	7679                	lui	a2,0xffffe
    800073e6:	963e                	add	a2,a2,a5
    800073e8:	00020697          	auipc	a3,0x20
    800073ec:	c1868693          	addi	a3,a3,-1000 # 80027000 <disk+0x2000>
    800073f0:	6298                	ld	a4,0(a3)
    800073f2:	9732                	add	a4,a4,a2
    800073f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800073f6:	6298                	ld	a4,0(a3)
    800073f8:	9732                	add	a4,a4,a2
    800073fa:	4541                	li	a0,16
    800073fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800073fe:	6298                	ld	a4,0(a3)
    80007400:	9732                	add	a4,a4,a2
    80007402:	4505                	li	a0,1
    80007404:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80007408:	f9442703          	lw	a4,-108(s0)
    8000740c:	6288                	ld	a0,0(a3)
    8000740e:	962a                	add	a2,a2,a0
    80007410:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80007414:	0712                	slli	a4,a4,0x4
    80007416:	6290                	ld	a2,0(a3)
    80007418:	963a                	add	a2,a2,a4
    8000741a:	05890513          	addi	a0,s2,88
    8000741e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80007420:	6294                	ld	a3,0(a3)
    80007422:	96ba                	add	a3,a3,a4
    80007424:	40000613          	li	a2,1024
    80007428:	c690                	sw	a2,8(a3)
  if(write)
    8000742a:	140d0063          	beqz	s10,8000756a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000742e:	00020697          	auipc	a3,0x20
    80007432:	bd26b683          	ld	a3,-1070(a3) # 80027000 <disk+0x2000>
    80007436:	96ba                	add	a3,a3,a4
    80007438:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000743c:	0001e817          	auipc	a6,0x1e
    80007440:	bc480813          	addi	a6,a6,-1084 # 80025000 <disk>
    80007444:	00020517          	auipc	a0,0x20
    80007448:	bbc50513          	addi	a0,a0,-1092 # 80027000 <disk+0x2000>
    8000744c:	6114                	ld	a3,0(a0)
    8000744e:	96ba                	add	a3,a3,a4
    80007450:	00c6d603          	lhu	a2,12(a3)
    80007454:	00166613          	ori	a2,a2,1
    80007458:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000745c:	f9842683          	lw	a3,-104(s0)
    80007460:	6110                	ld	a2,0(a0)
    80007462:	9732                	add	a4,a4,a2
    80007464:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80007468:	20058613          	addi	a2,a1,512
    8000746c:	0612                	slli	a2,a2,0x4
    8000746e:	9642                	add	a2,a2,a6
    80007470:	577d                	li	a4,-1
    80007472:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80007476:	00469713          	slli	a4,a3,0x4
    8000747a:	6114                	ld	a3,0(a0)
    8000747c:	96ba                	add	a3,a3,a4
    8000747e:	03078793          	addi	a5,a5,48
    80007482:	97c2                	add	a5,a5,a6
    80007484:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80007486:	611c                	ld	a5,0(a0)
    80007488:	97ba                	add	a5,a5,a4
    8000748a:	4685                	li	a3,1
    8000748c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000748e:	611c                	ld	a5,0(a0)
    80007490:	97ba                	add	a5,a5,a4
    80007492:	4809                	li	a6,2
    80007494:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80007498:	611c                	ld	a5,0(a0)
    8000749a:	973e                	add	a4,a4,a5
    8000749c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800074a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800074a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800074a8:	6518                	ld	a4,8(a0)
    800074aa:	00275783          	lhu	a5,2(a4)
    800074ae:	8b9d                	andi	a5,a5,7
    800074b0:	0786                	slli	a5,a5,0x1
    800074b2:	97ba                	add	a5,a5,a4
    800074b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800074b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800074bc:	6518                	ld	a4,8(a0)
    800074be:	00275783          	lhu	a5,2(a4)
    800074c2:	2785                	addiw	a5,a5,1
    800074c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800074c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800074cc:	100017b7          	lui	a5,0x10001
    800074d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800074d4:	00492703          	lw	a4,4(s2)
    800074d8:	4785                	li	a5,1
    800074da:	02f71163          	bne	a4,a5,800074fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800074de:	00020997          	auipc	s3,0x20
    800074e2:	c4a98993          	addi	s3,s3,-950 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    800074e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800074e8:	85ce                	mv	a1,s3
    800074ea:	854a                	mv	a0,s2
    800074ec:	ffffb097          	auipc	ra,0xffffb
    800074f0:	6f8080e7          	jalr	1784(ra) # 80002be4 <sleep>
  while(b->disk == 1) {
    800074f4:	00492783          	lw	a5,4(s2)
    800074f8:	fe9788e3          	beq	a5,s1,800074e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800074fc:	f9042903          	lw	s2,-112(s0)
    80007500:	20090793          	addi	a5,s2,512
    80007504:	00479713          	slli	a4,a5,0x4
    80007508:	0001e797          	auipc	a5,0x1e
    8000750c:	af878793          	addi	a5,a5,-1288 # 80025000 <disk>
    80007510:	97ba                	add	a5,a5,a4
    80007512:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80007516:	00020997          	auipc	s3,0x20
    8000751a:	aea98993          	addi	s3,s3,-1302 # 80027000 <disk+0x2000>
    8000751e:	00491713          	slli	a4,s2,0x4
    80007522:	0009b783          	ld	a5,0(s3)
    80007526:	97ba                	add	a5,a5,a4
    80007528:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000752c:	854a                	mv	a0,s2
    8000752e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80007532:	00000097          	auipc	ra,0x0
    80007536:	bc4080e7          	jalr	-1084(ra) # 800070f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000753a:	8885                	andi	s1,s1,1
    8000753c:	f0ed                	bnez	s1,8000751e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000753e:	00020517          	auipc	a0,0x20
    80007542:	bea50513          	addi	a0,a0,-1046 # 80027128 <disk+0x2128>
    80007546:	ffff9097          	auipc	ra,0xffff9
    8000754a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
}
    8000754e:	70a6                	ld	ra,104(sp)
    80007550:	7406                	ld	s0,96(sp)
    80007552:	64e6                	ld	s1,88(sp)
    80007554:	6946                	ld	s2,80(sp)
    80007556:	69a6                	ld	s3,72(sp)
    80007558:	6a06                	ld	s4,64(sp)
    8000755a:	7ae2                	ld	s5,56(sp)
    8000755c:	7b42                	ld	s6,48(sp)
    8000755e:	7ba2                	ld	s7,40(sp)
    80007560:	7c02                	ld	s8,32(sp)
    80007562:	6ce2                	ld	s9,24(sp)
    80007564:	6d42                	ld	s10,16(sp)
    80007566:	6165                	addi	sp,sp,112
    80007568:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000756a:	00020697          	auipc	a3,0x20
    8000756e:	a966b683          	ld	a3,-1386(a3) # 80027000 <disk+0x2000>
    80007572:	96ba                	add	a3,a3,a4
    80007574:	4609                	li	a2,2
    80007576:	00c69623          	sh	a2,12(a3)
    8000757a:	b5c9                	j	8000743c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000757c:	f9042583          	lw	a1,-112(s0)
    80007580:	20058793          	addi	a5,a1,512
    80007584:	0792                	slli	a5,a5,0x4
    80007586:	0001e517          	auipc	a0,0x1e
    8000758a:	b2250513          	addi	a0,a0,-1246 # 800250a8 <disk+0xa8>
    8000758e:	953e                	add	a0,a0,a5
  if(write)
    80007590:	e20d11e3          	bnez	s10,800073b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80007594:	20058713          	addi	a4,a1,512
    80007598:	00471693          	slli	a3,a4,0x4
    8000759c:	0001e717          	auipc	a4,0x1e
    800075a0:	a6470713          	addi	a4,a4,-1436 # 80025000 <disk>
    800075a4:	9736                	add	a4,a4,a3
    800075a6:	0a072423          	sw	zero,168(a4)
    800075aa:	b505                	j	800073ca <virtio_disk_rw+0xf4>

00000000800075ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800075ac:	1101                	addi	sp,sp,-32
    800075ae:	ec06                	sd	ra,24(sp)
    800075b0:	e822                	sd	s0,16(sp)
    800075b2:	e426                	sd	s1,8(sp)
    800075b4:	e04a                	sd	s2,0(sp)
    800075b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800075b8:	00020517          	auipc	a0,0x20
    800075bc:	b7050513          	addi	a0,a0,-1168 # 80027128 <disk+0x2128>
    800075c0:	ffff9097          	auipc	ra,0xffff9
    800075c4:	624080e7          	jalr	1572(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800075c8:	10001737          	lui	a4,0x10001
    800075cc:	533c                	lw	a5,96(a4)
    800075ce:	8b8d                	andi	a5,a5,3
    800075d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800075d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800075d6:	00020797          	auipc	a5,0x20
    800075da:	a2a78793          	addi	a5,a5,-1494 # 80027000 <disk+0x2000>
    800075de:	6b94                	ld	a3,16(a5)
    800075e0:	0207d703          	lhu	a4,32(a5)
    800075e4:	0026d783          	lhu	a5,2(a3)
    800075e8:	06f70163          	beq	a4,a5,8000764a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800075ec:	0001e917          	auipc	s2,0x1e
    800075f0:	a1490913          	addi	s2,s2,-1516 # 80025000 <disk>
    800075f4:	00020497          	auipc	s1,0x20
    800075f8:	a0c48493          	addi	s1,s1,-1524 # 80027000 <disk+0x2000>
    __sync_synchronize();
    800075fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007600:	6898                	ld	a4,16(s1)
    80007602:	0204d783          	lhu	a5,32(s1)
    80007606:	8b9d                	andi	a5,a5,7
    80007608:	078e                	slli	a5,a5,0x3
    8000760a:	97ba                	add	a5,a5,a4
    8000760c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000760e:	20078713          	addi	a4,a5,512
    80007612:	0712                	slli	a4,a4,0x4
    80007614:	974a                	add	a4,a4,s2
    80007616:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000761a:	e731                	bnez	a4,80007666 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000761c:	20078793          	addi	a5,a5,512
    80007620:	0792                	slli	a5,a5,0x4
    80007622:	97ca                	add	a5,a5,s2
    80007624:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007626:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000762a:	ffffc097          	auipc	ra,0xffffc
    8000762e:	920080e7          	jalr	-1760(ra) # 80002f4a <wakeup>

    disk.used_idx += 1;
    80007632:	0204d783          	lhu	a5,32(s1)
    80007636:	2785                	addiw	a5,a5,1
    80007638:	17c2                	slli	a5,a5,0x30
    8000763a:	93c1                	srli	a5,a5,0x30
    8000763c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007640:	6898                	ld	a4,16(s1)
    80007642:	00275703          	lhu	a4,2(a4)
    80007646:	faf71be3          	bne	a4,a5,800075fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000764a:	00020517          	auipc	a0,0x20
    8000764e:	ade50513          	addi	a0,a0,-1314 # 80027128 <disk+0x2128>
    80007652:	ffff9097          	auipc	ra,0xffff9
    80007656:	646080e7          	jalr	1606(ra) # 80000c98 <release>
}
    8000765a:	60e2                	ld	ra,24(sp)
    8000765c:	6442                	ld	s0,16(sp)
    8000765e:	64a2                	ld	s1,8(sp)
    80007660:	6902                	ld	s2,0(sp)
    80007662:	6105                	addi	sp,sp,32
    80007664:	8082                	ret
      panic("virtio_disk_intr status");
    80007666:	00002517          	auipc	a0,0x2
    8000766a:	3b250513          	addi	a0,a0,946 # 80009a18 <syscalls+0x3d8>
    8000766e:	ffff9097          	auipc	ra,0xffff9
    80007672:	ed0080e7          	jalr	-304(ra) # 8000053e <panic>

0000000080007676 <cas>:
    80007676:	100522af          	lr.w	t0,(a0)
    8000767a:	00b29563          	bne	t0,a1,80007684 <fail>
    8000767e:	18c5252f          	sc.w	a0,a2,(a0)
    80007682:	8082                	ret

0000000080007684 <fail>:
    80007684:	4505                	li	a0,1
    80007686:	8082                	ret
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
