
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
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
    80000064:	00006797          	auipc	a5,0x6
    80000068:	3cc78793          	addi	a5,a5,972 # 80006430 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
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
    80000130:	b9c080e7          	jalr	-1124(ra) # 80002cc8 <either_copyin>
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
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
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
    800001c8:	814080e7          	jalr	-2028(ra) # 800019d8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	29c080e7          	jalr	668(ra) # 80002470 <sleep>
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
    80000214:	a62080e7          	jalr	-1438(ra) # 80002c72 <either_copyout>
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
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
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
    80000272:	00011717          	auipc	a4,0x11
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
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
    800002f6:	a2c080e7          	jalr	-1492(ra) # 80002d1e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
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
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	222080e7          	jalr	546(ra) # 80002668 <wakeup>
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
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	8c078793          	addi	a5,a5,-1856 # 80021d38 <devsw>
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
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
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
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	d9450513          	addi	a0,a0,-620 # 80008300 <digits+0x2c0>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
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
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
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
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
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
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
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
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
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
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
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
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
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
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
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
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
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
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
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
    800008a4:	dc8080e7          	jalr	-568(ra) # 80002668 <wakeup>
    
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
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	b44080e7          	jalr	-1212(ra) # 80002470 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
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
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
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
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
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
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
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
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
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
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
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
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
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
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
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
    80000b82:	e3e080e7          	jalr	-450(ra) # 800019bc <mycpu>
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
    80000bb4:	e0c080e7          	jalr	-500(ra) # 800019bc <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e00080e7          	jalr	-512(ra) # 800019bc <mycpu>
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
    80000bd8:	de8080e7          	jalr	-536(ra) # 800019bc <mycpu>
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
    80000c18:	da8080e7          	jalr	-600(ra) # 800019bc <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
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
    80000c44:	d7c080e7          	jalr	-644(ra) # 800019bc <mycpu>
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
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
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
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
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
    80000e9a:	b16080e7          	jalr	-1258(ra) # 800019ac <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
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
    80000eb6:	afa080e7          	jalr	-1286(ra) # 800019ac <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	f8a080e7          	jalr	-118(ra) # 80002e5e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	594080e7          	jalr	1428(ra) # 80006470 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	460080e7          	jalr	1120(ra) # 80002344 <scheduler>
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
    80000f04:	00007517          	auipc	a0,0x7
    80000f08:	3fc50513          	addi	a0,a0,1020 # 80008300 <digits+0x2c0>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	3dc50513          	addi	a0,a0,988 # 80008300 <digits+0x2c0>
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
    80000f50:	990080e7          	jalr	-1648(ra) # 800018dc <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	ee2080e7          	jalr	-286(ra) # 80002e36 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	f02080e7          	jalr	-254(ra) # 80002e5e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	4f6080e7          	jalr	1270(ra) # 8000645a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	504080e7          	jalr	1284(ra) # 80006470 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	6e6080e7          	jalr	1766(ra) # 8000365a <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	d76080e7          	jalr	-650(ra) # 80003cf2 <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	d20080e7          	jalr	-736(ra) # 80004ca4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	606080e7          	jalr	1542(ra) # 80006592 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d52080e7          	jalr	-686(ra) # 80001ce6 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
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
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
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
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
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
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
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
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
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
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
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
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	5fe080e7          	jalr	1534(ra) # 80001846 <proc_mapstacks>
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
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
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
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
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
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
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
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
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
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
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
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
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

0000000080001846 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001846:	7139                	addi	sp,sp,-64
    80001848:	fc06                	sd	ra,56(sp)
    8000184a:	f822                	sd	s0,48(sp)
    8000184c:	f426                	sd	s1,40(sp)
    8000184e:	f04a                	sd	s2,32(sp)
    80001850:	ec4e                	sd	s3,24(sp)
    80001852:	e852                	sd	s4,16(sp)
    80001854:	e456                	sd	s5,8(sp)
    80001856:	e05a                	sd	s6,0(sp)
    80001858:	0080                	addi	s0,sp,64
    8000185a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00010497          	auipc	s1,0x10
    80001860:	e9448493          	addi	s1,s1,-364 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	00016a17          	auipc	s4,0x16
    8000187a:	27aa0a13          	addi	s4,s4,634 # 80017af0 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if(pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	8591                	srai	a1,a1,0x4
    80001890:	000ab783          	ld	a5,0(s5)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	854e                	mv	a0,s3
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8b0080e7          	jalr	-1872(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	19048493          	addi	s1,s1,400
    800018b4:	fd4495e3          	bne	s1,s4,8000187e <proc_mapstacks+0x38>
  }
}
    800018b8:	70e2                	ld	ra,56(sp)
    800018ba:	7442                	ld	s0,48(sp)
    800018bc:	74a2                	ld	s1,40(sp)
    800018be:	7902                	ld	s2,32(sp)
    800018c0:	69e2                	ld	s3,24(sp)
    800018c2:	6a42                	ld	s4,16(sp)
    800018c4:	6aa2                	ld	s5,8(sp)
    800018c6:	6b02                	ld	s6,0(sp)
    800018c8:	6121                	addi	sp,sp,64
    800018ca:	8082                	ret
      panic("kalloc");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	90c50513          	addi	a0,a0,-1780 # 800081d8 <digits+0x198>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018dc:	7139                	addi	sp,sp,-64
    800018de:	fc06                	sd	ra,56(sp)
    800018e0:	f822                	sd	s0,48(sp)
    800018e2:	f426                	sd	s1,40(sp)
    800018e4:	f04a                	sd	s2,32(sp)
    800018e6:	ec4e                	sd	s3,24(sp)
    800018e8:	e852                	sd	s4,16(sp)
    800018ea:	e456                	sd	s5,8(sp)
    800018ec:	e05a                	sd	s6,0(sp)
    800018ee:	0080                	addi	s0,sp,64
  // Added
  program_time = 0;
    800018f0:	00007797          	auipc	a5,0x7
    800018f4:	7407a423          	sw	zero,1864(a5) # 80009038 <program_time>
  cpu_utilization = 0;
    800018f8:	00007797          	auipc	a5,0x7
    800018fc:	7207ac23          	sw	zero,1848(a5) # 80009030 <cpu_utilization>
  start_time = ticks;
    80001900:	00007797          	auipc	a5,0x7
    80001904:	7547a783          	lw	a5,1876(a5) # 80009054 <ticks>
    80001908:	00007717          	auipc	a4,0x7
    8000190c:	72f72623          	sw	a5,1836(a4) # 80009034 <start_time>

  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001910:	00007597          	auipc	a1,0x7
    80001914:	8d058593          	addi	a1,a1,-1840 # 800081e0 <digits+0x1a0>
    80001918:	00010517          	auipc	a0,0x10
    8000191c:	9a850513          	addi	a0,a0,-1624 # 800112c0 <pid_lock>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	234080e7          	jalr	564(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001928:	00007597          	auipc	a1,0x7
    8000192c:	8c058593          	addi	a1,a1,-1856 # 800081e8 <digits+0x1a8>
    80001930:	00010517          	auipc	a0,0x10
    80001934:	9a850513          	addi	a0,a0,-1624 # 800112d8 <wait_lock>
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	21c080e7          	jalr	540(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001940:	00010497          	auipc	s1,0x10
    80001944:	db048493          	addi	s1,s1,-592 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001948:	00007b17          	auipc	s6,0x7
    8000194c:	8b0b0b13          	addi	s6,s6,-1872 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001950:	8aa6                	mv	s5,s1
    80001952:	00006a17          	auipc	s4,0x6
    80001956:	6aea0a13          	addi	s4,s4,1710 # 80008000 <etext>
    8000195a:	04000937          	lui	s2,0x4000
    8000195e:	197d                	addi	s2,s2,-1
    80001960:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001962:	00016997          	auipc	s3,0x16
    80001966:	18e98993          	addi	s3,s3,398 # 80017af0 <tickslock>
      initlock(&p->lock, "proc");
    8000196a:	85da                	mv	a1,s6
    8000196c:	8526                	mv	a0,s1
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	1e6080e7          	jalr	486(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001976:	415487b3          	sub	a5,s1,s5
    8000197a:	8791                	srai	a5,a5,0x4
    8000197c:	000a3703          	ld	a4,0(s4)
    80001980:	02e787b3          	mul	a5,a5,a4
    80001984:	2785                	addiw	a5,a5,1
    80001986:	00d7979b          	slliw	a5,a5,0xd
    8000198a:	40f907b3          	sub	a5,s2,a5
    8000198e:	f4bc                	sd	a5,104(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001990:	19048493          	addi	s1,s1,400
    80001994:	fd349be3          	bne	s1,s3,8000196a <procinit+0x8e>
  }
}
    80001998:	70e2                	ld	ra,56(sp)
    8000199a:	7442                	ld	s0,48(sp)
    8000199c:	74a2                	ld	s1,40(sp)
    8000199e:	7902                	ld	s2,32(sp)
    800019a0:	69e2                	ld	s3,24(sp)
    800019a2:	6a42                	ld	s4,16(sp)
    800019a4:	6aa2                	ld	s5,8(sp)
    800019a6:	6b02                	ld	s6,0(sp)
    800019a8:	6121                	addi	sp,sp,64
    800019aa:	8082                	ret

00000000800019ac <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019ac:	1141                	addi	sp,sp,-16
    800019ae:	e422                	sd	s0,8(sp)
    800019b0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019b2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019b4:	2501                	sext.w	a0,a0
    800019b6:	6422                	ld	s0,8(sp)
    800019b8:	0141                	addi	sp,sp,16
    800019ba:	8082                	ret

00000000800019bc <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019bc:	1141                	addi	sp,sp,-16
    800019be:	e422                	sd	s0,8(sp)
    800019c0:	0800                	addi	s0,sp,16
    800019c2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019c8:	00010517          	auipc	a0,0x10
    800019cc:	92850513          	addi	a0,a0,-1752 # 800112f0 <cpus>
    800019d0:	953e                	add	a0,a0,a5
    800019d2:	6422                	ld	s0,8(sp)
    800019d4:	0141                	addi	sp,sp,16
    800019d6:	8082                	ret

00000000800019d8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019d8:	1101                	addi	sp,sp,-32
    800019da:	ec06                	sd	ra,24(sp)
    800019dc:	e822                	sd	s0,16(sp)
    800019de:	e426                	sd	s1,8(sp)
    800019e0:	1000                	addi	s0,sp,32
  push_off();
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	1b6080e7          	jalr	438(ra) # 80000b98 <push_off>
    800019ea:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019ec:	2781                	sext.w	a5,a5
    800019ee:	079e                	slli	a5,a5,0x7
    800019f0:	00010717          	auipc	a4,0x10
    800019f4:	8d070713          	addi	a4,a4,-1840 # 800112c0 <pid_lock>
    800019f8:	97ba                	add	a5,a5,a4
    800019fa:	7b84                	ld	s1,48(a5)
  pop_off();
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	23c080e7          	jalr	572(ra) # 80000c38 <pop_off>
  return p;
}
    80001a04:	8526                	mv	a0,s1
    80001a06:	60e2                	ld	ra,24(sp)
    80001a08:	6442                	ld	s0,16(sp)
    80001a0a:	64a2                	ld	s1,8(sp)
    80001a0c:	6105                	addi	sp,sp,32
    80001a0e:	8082                	ret

0000000080001a10 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a10:	1141                	addi	sp,sp,-16
    80001a12:	e406                	sd	ra,8(sp)
    80001a14:	e022                	sd	s0,0(sp)
    80001a16:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a18:	00000097          	auipc	ra,0x0
    80001a1c:	fc0080e7          	jalr	-64(ra) # 800019d8 <myproc>
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	278080e7          	jalr	632(ra) # 80000c98 <release>

  if (first) {
    80001a28:	00007797          	auipc	a5,0x7
    80001a2c:	ec87a783          	lw	a5,-312(a5) # 800088f0 <first.1753>
    80001a30:	eb89                	bnez	a5,80001a42 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a32:	00001097          	auipc	ra,0x1
    80001a36:	444080e7          	jalr	1092(ra) # 80002e76 <usertrapret>
}
    80001a3a:	60a2                	ld	ra,8(sp)
    80001a3c:	6402                	ld	s0,0(sp)
    80001a3e:	0141                	addi	sp,sp,16
    80001a40:	8082                	ret
    first = 0;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	ea07a723          	sw	zero,-338(a5) # 800088f0 <first.1753>
    fsinit(ROOTDEV);
    80001a4a:	4505                	li	a0,1
    80001a4c:	00002097          	auipc	ra,0x2
    80001a50:	226080e7          	jalr	550(ra) # 80003c72 <fsinit>
    80001a54:	bff9                	j	80001a32 <forkret+0x22>

0000000080001a56 <allocpid>:
allocpid() {
    80001a56:	1101                	addi	sp,sp,-32
    80001a58:	ec06                	sd	ra,24(sp)
    80001a5a:	e822                	sd	s0,16(sp)
    80001a5c:	e426                	sd	s1,8(sp)
    80001a5e:	1000                	addi	s0,sp,32
  pid = nextpid;
    80001a60:	00007517          	auipc	a0,0x7
    80001a64:	e9450513          	addi	a0,a0,-364 # 800088f4 <nextpid>
    80001a68:	4104                	lw	s1,0(a0)
  if (cas(&nextpid, pid, (nextpid + 1)) == 0)
    80001a6a:	0014861b          	addiw	a2,s1,1
    80001a6e:	85a6                	mv	a1,s1
    80001a70:	00005097          	auipc	ra,0x5
    80001a74:	006080e7          	jalr	6(ra) # 80006a76 <cas>
    80001a78:	e519                	bnez	a0,80001a86 <allocpid+0x30>
}
    80001a7a:	8526                	mv	a0,s1
    80001a7c:	60e2                	ld	ra,24(sp)
    80001a7e:	6442                	ld	s0,16(sp)
    80001a80:	64a2                	ld	s1,8(sp)
    80001a82:	6105                	addi	sp,sp,32
    80001a84:	8082                	ret
  return allocpid();
    80001a86:	00000097          	auipc	ra,0x0
    80001a8a:	fd0080e7          	jalr	-48(ra) # 80001a56 <allocpid>
    80001a8e:	84aa                	mv	s1,a0
    80001a90:	b7ed                	j	80001a7a <allocpid+0x24>

0000000080001a92 <proc_pagetable>:
{
    80001a92:	1101                	addi	sp,sp,-32
    80001a94:	ec06                	sd	ra,24(sp)
    80001a96:	e822                	sd	s0,16(sp)
    80001a98:	e426                	sd	s1,8(sp)
    80001a9a:	e04a                	sd	s2,0(sp)
    80001a9c:	1000                	addi	s0,sp,32
    80001a9e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa0:	00000097          	auipc	ra,0x0
    80001aa4:	8a2080e7          	jalr	-1886(ra) # 80001342 <uvmcreate>
    80001aa8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aaa:	c121                	beqz	a0,80001aea <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aac:	4729                	li	a4,10
    80001aae:	00005697          	auipc	a3,0x5
    80001ab2:	55268693          	addi	a3,a3,1362 # 80007000 <_trampoline>
    80001ab6:	6605                	lui	a2,0x1
    80001ab8:	040005b7          	lui	a1,0x4000
    80001abc:	15fd                	addi	a1,a1,-1
    80001abe:	05b2                	slli	a1,a1,0xc
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f8080e7          	jalr	1528(ra) # 800010b8 <mappages>
    80001ac8:	02054863          	bltz	a0,80001af8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001acc:	4719                	li	a4,6
    80001ace:	08093683          	ld	a3,128(s2) # 4000080 <_entry-0x7bffff80>
    80001ad2:	6605                	lui	a2,0x1
    80001ad4:	020005b7          	lui	a1,0x2000
    80001ad8:	15fd                	addi	a1,a1,-1
    80001ada:	05b6                	slli	a1,a1,0xd
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	5da080e7          	jalr	1498(ra) # 800010b8 <mappages>
    80001ae6:	02054163          	bltz	a0,80001b08 <proc_pagetable+0x76>
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6902                	ld	s2,0(sp)
    80001af4:	6105                	addi	sp,sp,32
    80001af6:	8082                	ret
    uvmfree(pagetable, 0);
    80001af8:	4581                	li	a1,0
    80001afa:	8526                	mv	a0,s1
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	a42080e7          	jalr	-1470(ra) # 8000153e <uvmfree>
    return 0;
    80001b04:	4481                	li	s1,0
    80001b06:	b7d5                	j	80001aea <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b08:	4681                	li	a3,0
    80001b0a:	4605                	li	a2,1
    80001b0c:	040005b7          	lui	a1,0x4000
    80001b10:	15fd                	addi	a1,a1,-1
    80001b12:	05b2                	slli	a1,a1,0xc
    80001b14:	8526                	mv	a0,s1
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	768080e7          	jalr	1896(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1e:	4581                	li	a1,0
    80001b20:	8526                	mv	a0,s1
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	a1c080e7          	jalr	-1508(ra) # 8000153e <uvmfree>
    return 0;
    80001b2a:	4481                	li	s1,0
    80001b2c:	bf7d                	j	80001aea <proc_pagetable+0x58>

0000000080001b2e <proc_freepagetable>:
{
    80001b2e:	1101                	addi	sp,sp,-32
    80001b30:	ec06                	sd	ra,24(sp)
    80001b32:	e822                	sd	s0,16(sp)
    80001b34:	e426                	sd	s1,8(sp)
    80001b36:	e04a                	sd	s2,0(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
    80001b3c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3e:	4681                	li	a3,0
    80001b40:	4605                	li	a2,1
    80001b42:	040005b7          	lui	a1,0x4000
    80001b46:	15fd                	addi	a1,a1,-1
    80001b48:	05b2                	slli	a1,a1,0xc
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	734080e7          	jalr	1844(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b52:	4681                	li	a3,0
    80001b54:	4605                	li	a2,1
    80001b56:	020005b7          	lui	a1,0x2000
    80001b5a:	15fd                	addi	a1,a1,-1
    80001b5c:	05b6                	slli	a1,a1,0xd
    80001b5e:	8526                	mv	a0,s1
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	71e080e7          	jalr	1822(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b68:	85ca                	mv	a1,s2
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	9d2080e7          	jalr	-1582(ra) # 8000153e <uvmfree>
}
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	64a2                	ld	s1,8(sp)
    80001b7a:	6902                	ld	s2,0(sp)
    80001b7c:	6105                	addi	sp,sp,32
    80001b7e:	8082                	ret

0000000080001b80 <freeproc>:
{
    80001b80:	1101                	addi	sp,sp,-32
    80001b82:	ec06                	sd	ra,24(sp)
    80001b84:	e822                	sd	s0,16(sp)
    80001b86:	e426                	sd	s1,8(sp)
    80001b88:	1000                	addi	s0,sp,32
    80001b8a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8c:	6148                	ld	a0,128(a0)
    80001b8e:	c509                	beqz	a0,80001b98 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	e68080e7          	jalr	-408(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b98:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    80001b9c:	7ca8                	ld	a0,120(s1)
    80001b9e:	c511                	beqz	a0,80001baa <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba0:	78ac                	ld	a1,112(s1)
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	f8c080e7          	jalr	-116(ra) # 80001b2e <proc_freepagetable>
  p->pagetable = 0;
    80001baa:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80001bae:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80001bb2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb6:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    80001bba:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80001bbe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bca:	0004ac23          	sw	zero,24(s1)
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <allocproc>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	e04a                	sd	s2,0(sp)
    80001be2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	00010497          	auipc	s1,0x10
    80001be8:	b0c48493          	addi	s1,s1,-1268 # 800116f0 <proc>
    80001bec:	00016917          	auipc	s2,0x16
    80001bf0:	f0490913          	addi	s2,s2,-252 # 80017af0 <tickslock>
    acquire(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	fee080e7          	jalr	-18(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bfe:	4c9c                	lw	a5,24(s1)
    80001c00:	cf81                	beqz	a5,80001c18 <allocproc+0x40>
      release(&p->lock);
    80001c02:	8526                	mv	a0,s1
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	094080e7          	jalr	148(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0c:	19048493          	addi	s1,s1,400
    80001c10:	ff2492e3          	bne	s1,s2,80001bf4 <allocproc+0x1c>
  return 0;
    80001c14:	4481                	li	s1,0
    80001c16:	a0ad                	j	80001c80 <allocproc+0xa8>
  p->pid = allocpid();
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e3e080e7          	jalr	-450(ra) # 80001a56 <allocpid>
    80001c20:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c22:	4785                	li	a5,1
    80001c24:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c26:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001c2a:	0204ac23          	sw	zero,56(s1)
  p->paused = 0;
    80001c2e:	0404a023          	sw	zero,64(s1)
  p->sleeping_time = 0;
    80001c32:	0404a623          	sw	zero,76(s1)
  p->running_time = 0;
    80001c36:	0404a223          	sw	zero,68(s1)
  p->runnable_time = 0;
    80001c3a:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	eb6080e7          	jalr	-330(ra) # 80000af4 <kalloc>
    80001c46:	892a                	mv	s2,a0
    80001c48:	e0c8                	sd	a0,128(s1)
    80001c4a:	c131                	beqz	a0,80001c8e <allocproc+0xb6>
  p->pagetable = proc_pagetable(p);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	e44080e7          	jalr	-444(ra) # 80001a92 <proc_pagetable>
    80001c56:	892a                	mv	s2,a0
    80001c58:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80001c5a:	c531                	beqz	a0,80001ca6 <allocproc+0xce>
  memset(&p->context, 0, sizeof(p->context));
    80001c5c:	07000613          	li	a2,112
    80001c60:	4581                	li	a1,0
    80001c62:	08848513          	addi	a0,s1,136
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	07a080e7          	jalr	122(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c6e:	00000797          	auipc	a5,0x0
    80001c72:	da278793          	addi	a5,a5,-606 # 80001a10 <forkret>
    80001c76:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c78:	74bc                	ld	a5,104(s1)
    80001c7a:	6705                	lui	a4,0x1
    80001c7c:	97ba                	add	a5,a5,a4
    80001c7e:	e8dc                	sd	a5,144(s1)
}
    80001c80:	8526                	mv	a0,s1
    80001c82:	60e2                	ld	ra,24(sp)
    80001c84:	6442                	ld	s0,16(sp)
    80001c86:	64a2                	ld	s1,8(sp)
    80001c88:	6902                	ld	s2,0(sp)
    80001c8a:	6105                	addi	sp,sp,32
    80001c8c:	8082                	ret
    freeproc(p);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	ef0080e7          	jalr	-272(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	ffe080e7          	jalr	-2(ra) # 80000c98 <release>
    return 0;
    80001ca2:	84ca                	mv	s1,s2
    80001ca4:	bff1                	j	80001c80 <allocproc+0xa8>
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	ed8080e7          	jalr	-296(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fe6080e7          	jalr	-26(ra) # 80000c98 <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	b7d1                	j	80001c80 <allocproc+0xa8>

0000000080001cbe <str_compare>:
{
    80001cbe:	1141                	addi	sp,sp,-16
    80001cc0:	e422                	sd	s0,8(sp)
    80001cc2:	0800                	addi	s0,sp,16
      c1 = (unsigned char) *s1++;
    80001cc4:	0505                	addi	a0,a0,1
    80001cc6:	fff54783          	lbu	a5,-1(a0)
      c2 = (unsigned char) *s2++;
    80001cca:	0585                	addi	a1,a1,1
    80001ccc:	fff5c703          	lbu	a4,-1(a1) # 1ffffff <_entry-0x7e000001>
      if (c1 == '\0')
    80001cd0:	c791                	beqz	a5,80001cdc <str_compare+0x1e>
  while (c1 == c2);
    80001cd2:	fee789e3          	beq	a5,a4,80001cc4 <str_compare+0x6>
  return c1 - c2;
    80001cd6:	40e7853b          	subw	a0,a5,a4
    80001cda:	a019                	j	80001ce0 <str_compare+0x22>
        return c1 - c2;
    80001cdc:	40e0053b          	negw	a0,a4
}
    80001ce0:	6422                	ld	s0,8(sp)
    80001ce2:	0141                	addi	sp,sp,16
    80001ce4:	8082                	ret

0000000080001ce6 <userinit>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	ee8080e7          	jalr	-280(ra) # 80001bd8 <allocproc>
    80001cf8:	84aa                	mv	s1,a0
  initproc = p;
    80001cfa:	00007797          	auipc	a5,0x7
    80001cfe:	32a7b723          	sd	a0,814(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d02:	03400613          	li	a2,52
    80001d06:	00007597          	auipc	a1,0x7
    80001d0a:	bfa58593          	addi	a1,a1,-1030 # 80008900 <initcode>
    80001d0e:	7d28                	ld	a0,120(a0)
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	660080e7          	jalr	1632(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001d18:	6785                	lui	a5,0x1
    80001d1a:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d1c:	60d8                	ld	a4,128(s1)
    80001d1e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d22:	60d8                	ld	a4,128(s1)
    80001d24:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d26:	4641                	li	a2,16
    80001d28:	00006597          	auipc	a1,0x6
    80001d2c:	4d858593          	addi	a1,a1,1240 # 80008200 <digits+0x1c0>
    80001d30:	18048513          	addi	a0,s1,384
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	0fe080e7          	jalr	254(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d3c:	00006517          	auipc	a0,0x6
    80001d40:	4d450513          	addi	a0,a0,1236 # 80008210 <digits+0x1d0>
    80001d44:	00003097          	auipc	ra,0x3
    80001d48:	95c080e7          	jalr	-1700(ra) # 800046a0 <namei>
    80001d4c:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80001d50:	478d                	li	a5,3
    80001d52:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001d54:	00007797          	auipc	a5,0x7
    80001d58:	3007a783          	lw	a5,768(a5) # 80009054 <ticks>
    80001d5c:	dcdc                	sw	a5,60(s1)
  release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f38080e7          	jalr	-200(ra) # 80000c98 <release>
}
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret

0000000080001d72 <growproc>:
{
    80001d72:	1101                	addi	sp,sp,-32
    80001d74:	ec06                	sd	ra,24(sp)
    80001d76:	e822                	sd	s0,16(sp)
    80001d78:	e426                	sd	s1,8(sp)
    80001d7a:	e04a                	sd	s2,0(sp)
    80001d7c:	1000                	addi	s0,sp,32
    80001d7e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	c58080e7          	jalr	-936(ra) # 800019d8 <myproc>
    80001d88:	892a                	mv	s2,a0
  sz = p->sz;
    80001d8a:	792c                	ld	a1,112(a0)
    80001d8c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d90:	00904f63          	bgtz	s1,80001dae <growproc+0x3c>
  } else if(n < 0){
    80001d94:	0204cc63          	bltz	s1,80001dcc <growproc+0x5a>
  p->sz = sz;
    80001d98:	1602                	slli	a2,a2,0x20
    80001d9a:	9201                	srli	a2,a2,0x20
    80001d9c:	06c93823          	sd	a2,112(s2)
  return 0;
    80001da0:	4501                	li	a0,0
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6902                	ld	s2,0(sp)
    80001daa:	6105                	addi	sp,sp,32
    80001dac:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dae:	9e25                	addw	a2,a2,s1
    80001db0:	1602                	slli	a2,a2,0x20
    80001db2:	9201                	srli	a2,a2,0x20
    80001db4:	1582                	slli	a1,a1,0x20
    80001db6:	9181                	srli	a1,a1,0x20
    80001db8:	7d28                	ld	a0,120(a0)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	670080e7          	jalr	1648(ra) # 8000142a <uvmalloc>
    80001dc2:	0005061b          	sext.w	a2,a0
    80001dc6:	fa69                	bnez	a2,80001d98 <growproc+0x26>
      return -1;
    80001dc8:	557d                	li	a0,-1
    80001dca:	bfe1                	j	80001da2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dcc:	9e25                	addw	a2,a2,s1
    80001dce:	1602                	slli	a2,a2,0x20
    80001dd0:	9201                	srli	a2,a2,0x20
    80001dd2:	1582                	slli	a1,a1,0x20
    80001dd4:	9181                	srli	a1,a1,0x20
    80001dd6:	7d28                	ld	a0,120(a0)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	60a080e7          	jalr	1546(ra) # 800013e2 <uvmdealloc>
    80001de0:	0005061b          	sext.w	a2,a0
    80001de4:	bf55                	j	80001d98 <growproc+0x26>

0000000080001de6 <fork>:
{
    80001de6:	7179                	addi	sp,sp,-48
    80001de8:	f406                	sd	ra,40(sp)
    80001dea:	f022                	sd	s0,32(sp)
    80001dec:	ec26                	sd	s1,24(sp)
    80001dee:	e84a                	sd	s2,16(sp)
    80001df0:	e44e                	sd	s3,8(sp)
    80001df2:	e052                	sd	s4,0(sp)
    80001df4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	be2080e7          	jalr	-1054(ra) # 800019d8 <myproc>
    80001dfe:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	dd8080e7          	jalr	-552(ra) # 80001bd8 <allocproc>
    80001e08:	12050163          	beqz	a0,80001f2a <fork+0x144>
    80001e0c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e0e:	07093603          	ld	a2,112(s2)
    80001e12:	7d2c                	ld	a1,120(a0)
    80001e14:	07893503          	ld	a0,120(s2)
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	75e080e7          	jalr	1886(ra) # 80001576 <uvmcopy>
    80001e20:	04054663          	bltz	a0,80001e6c <fork+0x86>
  np->sz = p->sz;
    80001e24:	07093783          	ld	a5,112(s2)
    80001e28:	06f9b823          	sd	a5,112(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e2c:	08093683          	ld	a3,128(s2)
    80001e30:	87b6                	mv	a5,a3
    80001e32:	0809b703          	ld	a4,128(s3)
    80001e36:	12068693          	addi	a3,a3,288
    80001e3a:	0007b803          	ld	a6,0(a5)
    80001e3e:	6788                	ld	a0,8(a5)
    80001e40:	6b8c                	ld	a1,16(a5)
    80001e42:	6f90                	ld	a2,24(a5)
    80001e44:	01073023          	sd	a6,0(a4)
    80001e48:	e708                	sd	a0,8(a4)
    80001e4a:	eb0c                	sd	a1,16(a4)
    80001e4c:	ef10                	sd	a2,24(a4)
    80001e4e:	02078793          	addi	a5,a5,32
    80001e52:	02070713          	addi	a4,a4,32
    80001e56:	fed792e3          	bne	a5,a3,80001e3a <fork+0x54>
  np->trapframe->a0 = 0;
    80001e5a:	0809b783          	ld	a5,128(s3)
    80001e5e:	0607b823          	sd	zero,112(a5)
    80001e62:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80001e66:	17800a13          	li	s4,376
    80001e6a:	a03d                	j	80001e98 <fork+0xb2>
    freeproc(np);
    80001e6c:	854e                	mv	a0,s3
    80001e6e:	00000097          	auipc	ra,0x0
    80001e72:	d12080e7          	jalr	-750(ra) # 80001b80 <freeproc>
    release(&np->lock);
    80001e76:	854e                	mv	a0,s3
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	e20080e7          	jalr	-480(ra) # 80000c98 <release>
    return -1;
    80001e80:	5a7d                	li	s4,-1
    80001e82:	a859                	j	80001f18 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e84:	00003097          	auipc	ra,0x3
    80001e88:	eb2080e7          	jalr	-334(ra) # 80004d36 <filedup>
    80001e8c:	009987b3          	add	a5,s3,s1
    80001e90:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e92:	04a1                	addi	s1,s1,8
    80001e94:	01448763          	beq	s1,s4,80001ea2 <fork+0xbc>
    if(p->ofile[i])
    80001e98:	009907b3          	add	a5,s2,s1
    80001e9c:	6388                	ld	a0,0(a5)
    80001e9e:	f17d                	bnez	a0,80001e84 <fork+0x9e>
    80001ea0:	bfcd                	j	80001e92 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001ea2:	17893503          	ld	a0,376(s2)
    80001ea6:	00002097          	auipc	ra,0x2
    80001eaa:	006080e7          	jalr	6(ra) # 80003eac <idup>
    80001eae:	16a9bc23          	sd	a0,376(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eb2:	4641                	li	a2,16
    80001eb4:	18090593          	addi	a1,s2,384
    80001eb8:	18098513          	addi	a0,s3,384
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	f76080e7          	jalr	-138(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001ec4:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ec8:	854e                	mv	a0,s3
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dce080e7          	jalr	-562(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ed2:	0000f497          	auipc	s1,0xf
    80001ed6:	40648493          	addi	s1,s1,1030 # 800112d8 <wait_lock>
    80001eda:	8526                	mv	a0,s1
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	d08080e7          	jalr	-760(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ee4:	0729b023          	sd	s2,96(s3)
  release(&wait_lock);
    80001ee8:	8526                	mv	a0,s1
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	dae080e7          	jalr	-594(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ef2:	854e                	mv	a0,s3
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	cf0080e7          	jalr	-784(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001efc:	478d                	li	a5,3
    80001efe:	00f9ac23          	sw	a5,24(s3)
  np->last_runnable_time = ticks;
    80001f02:	00007797          	auipc	a5,0x7
    80001f06:	1527a783          	lw	a5,338(a5) # 80009054 <ticks>
    80001f0a:	02f9ae23          	sw	a5,60(s3)
  release(&np->lock);
    80001f0e:	854e                	mv	a0,s3
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	d88080e7          	jalr	-632(ra) # 80000c98 <release>
}
    80001f18:	8552                	mv	a0,s4
    80001f1a:	70a2                	ld	ra,40(sp)
    80001f1c:	7402                	ld	s0,32(sp)
    80001f1e:	64e2                	ld	s1,24(sp)
    80001f20:	6942                	ld	s2,16(sp)
    80001f22:	69a2                	ld	s3,8(sp)
    80001f24:	6a02                	ld	s4,0(sp)
    80001f26:	6145                	addi	sp,sp,48
    80001f28:	8082                	ret
    return -1;
    80001f2a:	5a7d                	li	s4,-1
    80001f2c:	b7f5                	j	80001f18 <fork+0x132>

0000000080001f2e <unpause_system>:
{
    80001f2e:	7179                	addi	sp,sp,-48
    80001f30:	f406                	sd	ra,40(sp)
    80001f32:	f022                	sd	s0,32(sp)
    80001f34:	ec26                	sd	s1,24(sp)
    80001f36:	e84a                	sd	s2,16(sp)
    80001f38:	e44e                	sd	s3,8(sp)
    80001f3a:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) 
    80001f3c:	0000f497          	auipc	s1,0xf
    80001f40:	7b448493          	addi	s1,s1,1972 # 800116f0 <proc>
      if(p->paused == 1) 
    80001f44:	4985                	li	s3,1
  for(p = proc; p < &proc[NPROC]; p++) 
    80001f46:	00016917          	auipc	s2,0x16
    80001f4a:	baa90913          	addi	s2,s2,-1110 # 80017af0 <tickslock>
    80001f4e:	a811                	j	80001f62 <unpause_system+0x34>
      release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d46080e7          	jalr	-698(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) 
    80001f5a:	19048493          	addi	s1,s1,400
    80001f5e:	01248d63          	beq	s1,s2,80001f78 <unpause_system+0x4a>
      acquire(&p->lock);
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	c80080e7          	jalr	-896(ra) # 80000be4 <acquire>
      if(p->paused == 1) 
    80001f6c:	40bc                	lw	a5,64(s1)
    80001f6e:	ff3791e3          	bne	a5,s3,80001f50 <unpause_system+0x22>
        p->paused = 0;
    80001f72:	0404a023          	sw	zero,64(s1)
    80001f76:	bfe9                	j	80001f50 <unpause_system+0x22>
} 
    80001f78:	70a2                	ld	ra,40(sp)
    80001f7a:	7402                	ld	s0,32(sp)
    80001f7c:	64e2                	ld	s1,24(sp)
    80001f7e:	6942                	ld	s2,16(sp)
    80001f80:	69a2                	ld	s3,8(sp)
    80001f82:	6145                	addi	sp,sp,48
    80001f84:	8082                	ret

0000000080001f86 <SJF_scheduler>:
{
    80001f86:	7159                	addi	sp,sp,-112
    80001f88:	f486                	sd	ra,104(sp)
    80001f8a:	f0a2                	sd	s0,96(sp)
    80001f8c:	eca6                	sd	s1,88(sp)
    80001f8e:	e8ca                	sd	s2,80(sp)
    80001f90:	e4ce                	sd	s3,72(sp)
    80001f92:	e0d2                	sd	s4,64(sp)
    80001f94:	fc56                	sd	s5,56(sp)
    80001f96:	f85a                	sd	s6,48(sp)
    80001f98:	f45e                	sd	s7,40(sp)
    80001f9a:	f062                	sd	s8,32(sp)
    80001f9c:	ec66                	sd	s9,24(sp)
    80001f9e:	e86a                	sd	s10,16(sp)
    80001fa0:	e46e                	sd	s11,8(sp)
    80001fa2:	1880                	addi	s0,sp,112
    80001fa4:	8792                	mv	a5,tp
  int id = r_tp();
    80001fa6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fa8:	00779693          	slli	a3,a5,0x7
    80001fac:	0000f717          	auipc	a4,0xf
    80001fb0:	31470713          	addi	a4,a4,788 # 800112c0 <pid_lock>
    80001fb4:	9736                	add	a4,a4,a3
    80001fb6:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &p_of_min->context);
    80001fba:	0000f717          	auipc	a4,0xf
    80001fbe:	33e70713          	addi	a4,a4,830 # 800112f8 <cpus+0x8>
    80001fc2:	00e68db3          	add	s11,a3,a4
    struct proc* p_of_min = proc;
    80001fc6:	0000fb17          	auipc	s6,0xf
    80001fca:	72ab0b13          	addi	s6,s6,1834 # 800116f0 <proc>
    uint min = INT_MAX;
    80001fce:	80000bb7          	lui	s7,0x80000
    80001fd2:	fffbcb93          	not	s7,s7
           should_switch = 1;
    80001fd6:	4a85                	li	s5,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fd8:	00016497          	auipc	s1,0x16
    80001fdc:	b1848493          	addi	s1,s1,-1256 # 80017af0 <tickslock>
           should_switch = 1;
    80001fe0:	8a56                	mv	s4,s5
      p_of_min->start_running_time = ticks;
    80001fe2:	00007c17          	auipc	s8,0x7
    80001fe6:	072c0c13          	addi	s8,s8,114 # 80009054 <ticks>
      c->proc = p_of_min;
    80001fea:	0000fc97          	auipc	s9,0xf
    80001fee:	2d6c8c93          	addi	s9,s9,726 # 800112c0 <pid_lock>
    80001ff2:	9cb6                	add	s9,s9,a3
    80001ff4:	a091                	j	80002038 <SJF_scheduler+0xb2>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff6:	19078793          	addi	a5,a5,400
    80001ffa:	00978c63          	beq	a5,s1,80002012 <SJF_scheduler+0x8c>
       if(p->state == RUNNABLE) {
    80001ffe:	4f98                	lw	a4,24(a5)
    80002000:	fed71be3          	bne	a4,a3,80001ff6 <SJF_scheduler+0x70>
         if (p->mean_ticks < min)
    80002004:	5bd8                	lw	a4,52(a5)
    80002006:	fec778e3          	bgeu	a4,a2,80001ff6 <SJF_scheduler+0x70>
    8000200a:	893e                	mv	s2,a5
           min = p->mean_ticks;
    8000200c:	863a                	mv	a2,a4
           should_switch = 1;
    8000200e:	89d2                	mv	s3,s4
    80002010:	b7dd                	j	80001ff6 <SJF_scheduler+0x70>
    acquire(&p_of_min->lock);
    80002012:	8d4a                	mv	s10,s2
    80002014:	854a                	mv	a0,s2
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	bce080e7          	jalr	-1074(ra) # 80000be4 <acquire>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    8000201e:	03598963          	beq	s3,s5,80002050 <SJF_scheduler+0xca>
    release(&p_of_min->lock);
    80002022:	856a                	mv	a0,s10
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	c74080e7          	jalr	-908(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    8000202c:	00007797          	auipc	a5,0x7
    80002030:	0247a783          	lw	a5,36(a5) # 80009050 <pause_flag>
    80002034:	0b578063          	beq	a5,s5,800020d4 <SJF_scheduler+0x14e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002038:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000203c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002040:	10079073          	csrw	sstatus,a5
    int should_switch = 0;
    80002044:	4981                	li	s3,0
    struct proc* p_of_min = proc;
    80002046:	895a                	mv	s2,s6
    uint min = INT_MAX;
    80002048:	865e                	mv	a2,s7
    for(p = proc; p < &proc[NPROC]; p++) {
    8000204a:	87da                	mv	a5,s6
       if(p->state == RUNNABLE) {
    8000204c:	468d                	li	a3,3
    8000204e:	bf45                	j	80001ffe <SJF_scheduler+0x78>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    80002050:	01892703          	lw	a4,24(s2)
    80002054:	478d                	li	a5,3
    80002056:	fcf716e3          	bne	a4,a5,80002022 <SJF_scheduler+0x9c>
    8000205a:	04092783          	lw	a5,64(s2)
    8000205e:	f3f1                	bnez	a5,80002022 <SJF_scheduler+0x9c>
      p_of_min->state = RUNNING;
    80002060:	4791                	li	a5,4
    80002062:	00f92c23          	sw	a5,24(s2)
      p_of_min->start_running_time = ticks;
    80002066:	000c2983          	lw	s3,0(s8)
    8000206a:	05392823          	sw	s3,80(s2)
      p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    8000206e:	04892783          	lw	a5,72(s2)
    80002072:	013787bb          	addw	a5,a5,s3
    80002076:	03c92703          	lw	a4,60(s2)
    8000207a:	9f99                	subw	a5,a5,a4
    8000207c:	04f92423          	sw	a5,72(s2)
      c->proc = p_of_min;
    80002080:	032cb823          	sd	s2,48(s9)
      swtch(&c->context, &p_of_min->context);
    80002084:	08890593          	addi	a1,s2,136
    80002088:	856e                	mv	a0,s11
    8000208a:	00001097          	auipc	ra,0x1
    8000208e:	d42080e7          	jalr	-702(ra) # 80002dcc <swtch>
      p_of_min->last_ticks= ticks - before_swtch;
    80002092:	000c2783          	lw	a5,0(s8)
    80002096:	413789bb          	subw	s3,a5,s3
    8000209a:	03392c23          	sw	s3,56(s2)
      p_of_min->mean_ticks=((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10 ;
    8000209e:	00007617          	auipc	a2,0x7
    800020a2:	85a62603          	lw	a2,-1958(a2) # 800088f8 <rate>
    800020a6:	46a9                	li	a3,10
    800020a8:	40c687bb          	subw	a5,a3,a2
    800020ac:	00015717          	auipc	a4,0x15
    800020b0:	64470713          	addi	a4,a4,1604 # 800176f0 <proc+0x6000>
    800020b4:	43472583          	lw	a1,1076(a4)
    800020b8:	02b787bb          	mulw	a5,a5,a1
    800020bc:	43872703          	lw	a4,1080(a4)
    800020c0:	02c7073b          	mulw	a4,a4,a2
    800020c4:	9fb9                	addw	a5,a5,a4
    800020c6:	02d7d7bb          	divuw	a5,a5,a3
    800020ca:	02f92a23          	sw	a5,52(s2)
      c->proc = 0;
    800020ce:	020cb823          	sd	zero,48(s9)
    800020d2:	bf81                	j	80002022 <SJF_scheduler+0x9c>
      if (wake_up_time <= ticks) 
    800020d4:	00007717          	auipc	a4,0x7
    800020d8:	f7872703          	lw	a4,-136(a4) # 8000904c <wake_up_time>
    800020dc:	000c2783          	lw	a5,0(s8)
    800020e0:	f4e7ece3          	bltu	a5,a4,80002038 <SJF_scheduler+0xb2>
        pause_flag = 0;
    800020e4:	00007797          	auipc	a5,0x7
    800020e8:	f607a623          	sw	zero,-148(a5) # 80009050 <pause_flag>
        unpause_system();
    800020ec:	00000097          	auipc	ra,0x0
    800020f0:	e42080e7          	jalr	-446(ra) # 80001f2e <unpause_system>
    800020f4:	b791                	j	80002038 <SJF_scheduler+0xb2>

00000000800020f6 <FCFS_scheduler>:
{
    800020f6:	7119                	addi	sp,sp,-128
    800020f8:	fc86                	sd	ra,120(sp)
    800020fa:	f8a2                	sd	s0,112(sp)
    800020fc:	f4a6                	sd	s1,104(sp)
    800020fe:	f0ca                	sd	s2,96(sp)
    80002100:	ecce                	sd	s3,88(sp)
    80002102:	e8d2                	sd	s4,80(sp)
    80002104:	e4d6                	sd	s5,72(sp)
    80002106:	e0da                	sd	s6,64(sp)
    80002108:	fc5e                	sd	s7,56(sp)
    8000210a:	f862                	sd	s8,48(sp)
    8000210c:	f466                	sd	s9,40(sp)
    8000210e:	f06a                	sd	s10,32(sp)
    80002110:	ec6e                	sd	s11,24(sp)
    80002112:	0100                	addi	s0,sp,128
  asm volatile("mv %0, tp" : "=r" (x) );
    80002114:	8792                	mv	a5,tp
  int id = r_tp();
    80002116:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002118:	00779693          	slli	a3,a5,0x7
    8000211c:	0000f717          	auipc	a4,0xf
    80002120:	1a470713          	addi	a4,a4,420 # 800112c0 <pid_lock>
    80002124:	9736                	add	a4,a4,a3
    80002126:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p_of_min->context);
    8000212a:	0000f717          	auipc	a4,0xf
    8000212e:	1ce70713          	addi	a4,a4,462 # 800112f8 <cpus+0x8>
    80002132:	9736                	add	a4,a4,a3
    80002134:	f8e43423          	sd	a4,-120(s0)
  int should_switch = 0;
    80002138:	4b01                	li	s6,0
    struct proc *p_of_min = proc;
    8000213a:	0000fc17          	auipc	s8,0xf
    8000213e:	5b6c0c13          	addi	s8,s8,1462 # 800116f0 <proc>
    uint minlast_runnable = INT_MAX;
    80002142:	80000d37          	lui	s10,0x80000
    80002146:	fffd4d13          	not	s10,s10
          should_switch = 1;
    8000214a:	4c85                	li	s9,1
    for(p = proc; p < &proc[NPROC]; p++) 
    8000214c:	00016997          	auipc	s3,0x16
    80002150:	9a498993          	addi	s3,s3,-1628 # 80017af0 <tickslock>
          should_switch = 1;
    80002154:	8be6                	mv	s7,s9
        p_of_min->start_running_time = ticks;
    80002156:	00007d97          	auipc	s11,0x7
    8000215a:	efed8d93          	addi	s11,s11,-258 # 80009054 <ticks>
        c->proc = p_of_min;
    8000215e:	0000f717          	auipc	a4,0xf
    80002162:	16270713          	addi	a4,a4,354 # 800112c0 <pid_lock>
    80002166:	00d707b3          	add	a5,a4,a3
    8000216a:	f8f43023          	sd	a5,-128(s0)
    8000216e:	a095                	j	800021d2 <FCFS_scheduler+0xdc>
      release(&p->lock);
    80002170:	8526                	mv	a0,s1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	b26080e7          	jalr	-1242(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) 
    8000217a:	19048493          	addi	s1,s1,400
    8000217e:	03348463          	beq	s1,s3,800021a6 <FCFS_scheduler+0xb0>
      acquire(&p->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	a60080e7          	jalr	-1440(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && p->paused == 0) 
    8000218c:	4c9c                	lw	a5,24(s1)
    8000218e:	ff2791e3          	bne	a5,s2,80002170 <FCFS_scheduler+0x7a>
    80002192:	40bc                	lw	a5,64(s1)
    80002194:	fff1                	bnez	a5,80002170 <FCFS_scheduler+0x7a>
        if(p->last_runnable_time <= minlast_runnable)
    80002196:	5cdc                	lw	a5,60(s1)
    80002198:	fcfa6ce3          	bltu	s4,a5,80002170 <FCFS_scheduler+0x7a>
          minlast_runnable = p->mean_ticks;
    8000219c:	0344aa03          	lw	s4,52(s1)
    800021a0:	8aa6                	mv	s5,s1
          should_switch = 1;
    800021a2:	8b5e                	mv	s6,s7
    800021a4:	b7f1                	j	80002170 <FCFS_scheduler+0x7a>
    acquire(&p_of_min->lock);
    800021a6:	8956                	mv	s2,s5
    800021a8:	8556                	mv	a0,s5
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	a3a080e7          	jalr	-1478(ra) # 80000be4 <acquire>
    if (p_of_min->paused == 0)
    800021b2:	040aa483          	lw	s1,64(s5)
    800021b6:	e099                	bnez	s1,800021bc <FCFS_scheduler+0xc6>
      if (should_switch == 1 && p_of_min->pid > -1)
    800021b8:	039b0863          	beq	s6,s9,800021e8 <FCFS_scheduler+0xf2>
    release(&p_of_min->lock);
    800021bc:	854a                	mv	a0,s2
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	ada080e7          	jalr	-1318(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    800021c6:	00007797          	auipc	a5,0x7
    800021ca:	e8a7a783          	lw	a5,-374(a5) # 80009050 <pause_flag>
    800021ce:	07978063          	beq	a5,s9,8000222e <FCFS_scheduler+0x138>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021d6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021da:	10079073          	csrw	sstatus,a5
    struct proc *p_of_min = proc;
    800021de:	8ae2                	mv	s5,s8
    uint minlast_runnable = INT_MAX;
    800021e0:	8a6a                	mv	s4,s10
    for(p = proc; p < &proc[NPROC]; p++) 
    800021e2:	84e2                	mv	s1,s8
      if(p->state == RUNNABLE && p->paused == 0) 
    800021e4:	490d                	li	s2,3
    800021e6:	bf71                	j	80002182 <FCFS_scheduler+0x8c>
      if (should_switch == 1 && p_of_min->pid > -1)
    800021e8:	030aa783          	lw	a5,48(s5)
    800021ec:	fc07c8e3          	bltz	a5,800021bc <FCFS_scheduler+0xc6>
        p_of_min->state = RUNNING;
    800021f0:	4791                	li	a5,4
    800021f2:	00faac23          	sw	a5,24(s5)
        p_of_min->start_running_time = ticks;
    800021f6:	000da703          	lw	a4,0(s11)
    800021fa:	04eaa823          	sw	a4,80(s5)
        p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    800021fe:	048aa783          	lw	a5,72(s5)
    80002202:	9fb9                	addw	a5,a5,a4
    80002204:	03caa703          	lw	a4,60(s5)
    80002208:	9f99                	subw	a5,a5,a4
    8000220a:	04faa423          	sw	a5,72(s5)
        c->proc = p_of_min;
    8000220e:	f8043a03          	ld	s4,-128(s0)
    80002212:	035a3823          	sd	s5,48(s4)
        swtch(&c->context, &p_of_min->context);
    80002216:	088a8593          	addi	a1,s5,136
    8000221a:	f8843503          	ld	a0,-120(s0)
    8000221e:	00001097          	auipc	ra,0x1
    80002222:	bae080e7          	jalr	-1106(ra) # 80002dcc <swtch>
        c->proc = 0;
    80002226:	020a3823          	sd	zero,48(s4)
        should_switch = 0;
    8000222a:	8b26                	mv	s6,s1
    8000222c:	bf41                	j	800021bc <FCFS_scheduler+0xc6>
      if (wake_up_time <= ticks) 
    8000222e:	00007717          	auipc	a4,0x7
    80002232:	e1e72703          	lw	a4,-482(a4) # 8000904c <wake_up_time>
    80002236:	000da783          	lw	a5,0(s11)
    8000223a:	f8e7ece3          	bltu	a5,a4,800021d2 <FCFS_scheduler+0xdc>
        pause_flag = 0;
    8000223e:	00007797          	auipc	a5,0x7
    80002242:	e007a923          	sw	zero,-494(a5) # 80009050 <pause_flag>
        unpause_system();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	ce8080e7          	jalr	-792(ra) # 80001f2e <unpause_system>
    8000224e:	b751                	j	800021d2 <FCFS_scheduler+0xdc>

0000000080002250 <default_scheduler>:
{
    80002250:	711d                	addi	sp,sp,-96
    80002252:	ec86                	sd	ra,88(sp)
    80002254:	e8a2                	sd	s0,80(sp)
    80002256:	e4a6                	sd	s1,72(sp)
    80002258:	e0ca                	sd	s2,64(sp)
    8000225a:	fc4e                	sd	s3,56(sp)
    8000225c:	f852                	sd	s4,48(sp)
    8000225e:	f456                	sd	s5,40(sp)
    80002260:	f05a                	sd	s6,32(sp)
    80002262:	ec5e                	sd	s7,24(sp)
    80002264:	e862                	sd	s8,16(sp)
    80002266:	e466                	sd	s9,8(sp)
    80002268:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    8000226a:	8792                	mv	a5,tp
  int id = r_tp();
    8000226c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000226e:	00779c13          	slli	s8,a5,0x7
    80002272:	0000f717          	auipc	a4,0xf
    80002276:	04e70713          	addi	a4,a4,78 # 800112c0 <pid_lock>
    8000227a:	9762                	add	a4,a4,s8
    8000227c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002280:	0000f717          	auipc	a4,0xf
    80002284:	07870713          	addi	a4,a4,120 # 800112f8 <cpus+0x8>
    80002288:	9c3a                	add	s8,s8,a4
        p->runnable_time += ticks - p->last_runnable_time;
    8000228a:	00007b97          	auipc	s7,0x7
    8000228e:	dcab8b93          	addi	s7,s7,-566 # 80009054 <ticks>
        c->proc = p;
    80002292:	079e                	slli	a5,a5,0x7
    80002294:	0000fa97          	auipc	s5,0xf
    80002298:	02ca8a93          	addi	s5,s5,44 # 800112c0 <pid_lock>
    8000229c:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000229e:	00016a17          	auipc	s4,0x16
    800022a2:	852a0a13          	addi	s4,s4,-1966 # 80017af0 <tickslock>
    if (pause_flag == 1) 
    800022a6:	00007c97          	auipc	s9,0x7
    800022aa:	daac8c93          	addi	s9,s9,-598 # 80009050 <pause_flag>
    800022ae:	a8b9                	j	8000230c <default_scheduler+0xbc>
        p->runnable_time += ticks - p->last_runnable_time;
    800022b0:	000ba703          	lw	a4,0(s7)
    800022b4:	44bc                	lw	a5,72(s1)
    800022b6:	9fb9                	addw	a5,a5,a4
    800022b8:	5cd4                	lw	a3,60(s1)
    800022ba:	9f95                	subw	a5,a5,a3
    800022bc:	c4bc                	sw	a5,72(s1)
        p->state = RUNNING;
    800022be:	0164ac23          	sw	s6,24(s1)
        p->start_running_time = ticks;
    800022c2:	c8b8                	sw	a4,80(s1)
        c->proc = p;
    800022c4:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    800022c8:	08848593          	addi	a1,s1,136
    800022cc:	8562                	mv	a0,s8
    800022ce:	00001097          	auipc	ra,0x1
    800022d2:	afe080e7          	jalr	-1282(ra) # 80002dcc <swtch>
        c->proc = 0;
    800022d6:	020ab823          	sd	zero,48(s5)
      release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9bc080e7          	jalr	-1604(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022e4:	19048493          	addi	s1,s1,400
    800022e8:	01448d63          	beq	s1,s4,80002302 <default_scheduler+0xb2>
      acquire(&p->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	8f6080e7          	jalr	-1802(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && p->paused == 0) {
    800022f6:	4c9c                	lw	a5,24(s1)
    800022f8:	ff3791e3          	bne	a5,s3,800022da <default_scheduler+0x8a>
    800022fc:	40bc                	lw	a5,64(s1)
    800022fe:	fff1                	bnez	a5,800022da <default_scheduler+0x8a>
    80002300:	bf45                	j	800022b0 <default_scheduler+0x60>
    if (pause_flag == 1) 
    80002302:	000ca703          	lw	a4,0(s9)
    80002306:	4785                	li	a5,1
    80002308:	00f70f63          	beq	a4,a5,80002326 <default_scheduler+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000230c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002310:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002314:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002318:	0000f497          	auipc	s1,0xf
    8000231c:	3d848493          	addi	s1,s1,984 # 800116f0 <proc>
      if(p->state == RUNNABLE && p->paused == 0) {
    80002320:	498d                	li	s3,3
        p->state = RUNNING;
    80002322:	4b11                	li	s6,4
    80002324:	b7e1                	j	800022ec <default_scheduler+0x9c>
      if (wake_up_time <= ticks) 
    80002326:	00007717          	auipc	a4,0x7
    8000232a:	d2672703          	lw	a4,-730(a4) # 8000904c <wake_up_time>
    8000232e:	000ba783          	lw	a5,0(s7)
    80002332:	fce7ede3          	bltu	a5,a4,8000230c <default_scheduler+0xbc>
        pause_flag = 0;
    80002336:	000ca023          	sw	zero,0(s9)
        unpause_system();
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	bf4080e7          	jalr	-1036(ra) # 80001f2e <unpause_system>
    80002342:	b7e9                	j	8000230c <default_scheduler+0xbc>

0000000080002344 <scheduler>:
{
    80002344:	1141                	addi	sp,sp,-16
    80002346:	e406                	sd	ra,8(sp)
    80002348:	e022                	sd	s0,0(sp)
    8000234a:	0800                	addi	s0,sp,16
    default_scheduler();
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	f04080e7          	jalr	-252(ra) # 80002250 <default_scheduler>

0000000080002354 <sched>:
{
    80002354:	7179                	addi	sp,sp,-48
    80002356:	f406                	sd	ra,40(sp)
    80002358:	f022                	sd	s0,32(sp)
    8000235a:	ec26                	sd	s1,24(sp)
    8000235c:	e84a                	sd	s2,16(sp)
    8000235e:	e44e                	sd	s3,8(sp)
    80002360:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	676080e7          	jalr	1654(ra) # 800019d8 <myproc>
    8000236a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000236c:	ffffe097          	auipc	ra,0xffffe
    80002370:	7fe080e7          	jalr	2046(ra) # 80000b6a <holding>
    80002374:	c93d                	beqz	a0,800023ea <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002376:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002378:	2781                	sext.w	a5,a5
    8000237a:	079e                	slli	a5,a5,0x7
    8000237c:	0000f717          	auipc	a4,0xf
    80002380:	f4470713          	addi	a4,a4,-188 # 800112c0 <pid_lock>
    80002384:	97ba                	add	a5,a5,a4
    80002386:	0a87a703          	lw	a4,168(a5)
    8000238a:	4785                	li	a5,1
    8000238c:	06f71763          	bne	a4,a5,800023fa <sched+0xa6>
  if(p->state == RUNNING)
    80002390:	4c98                	lw	a4,24(s1)
    80002392:	4791                	li	a5,4
    80002394:	06f70b63          	beq	a4,a5,8000240a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002398:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000239c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000239e:	efb5                	bnez	a5,8000241a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023a0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023a2:	0000f917          	auipc	s2,0xf
    800023a6:	f1e90913          	addi	s2,s2,-226 # 800112c0 <pid_lock>
    800023aa:	2781                	sext.w	a5,a5
    800023ac:	079e                	slli	a5,a5,0x7
    800023ae:	97ca                	add	a5,a5,s2
    800023b0:	0ac7a983          	lw	s3,172(a5)
    800023b4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023b6:	2781                	sext.w	a5,a5
    800023b8:	079e                	slli	a5,a5,0x7
    800023ba:	0000f597          	auipc	a1,0xf
    800023be:	f3e58593          	addi	a1,a1,-194 # 800112f8 <cpus+0x8>
    800023c2:	95be                	add	a1,a1,a5
    800023c4:	08848513          	addi	a0,s1,136
    800023c8:	00001097          	auipc	ra,0x1
    800023cc:	a04080e7          	jalr	-1532(ra) # 80002dcc <swtch>
    800023d0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023d2:	2781                	sext.w	a5,a5
    800023d4:	079e                	slli	a5,a5,0x7
    800023d6:	97ca                	add	a5,a5,s2
    800023d8:	0b37a623          	sw	s3,172(a5)
}
    800023dc:	70a2                	ld	ra,40(sp)
    800023de:	7402                	ld	s0,32(sp)
    800023e0:	64e2                	ld	s1,24(sp)
    800023e2:	6942                	ld	s2,16(sp)
    800023e4:	69a2                	ld	s3,8(sp)
    800023e6:	6145                	addi	sp,sp,48
    800023e8:	8082                	ret
    panic("sched p->lock");
    800023ea:	00006517          	auipc	a0,0x6
    800023ee:	e2e50513          	addi	a0,a0,-466 # 80008218 <digits+0x1d8>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	14c080e7          	jalr	332(ra) # 8000053e <panic>
    panic("sched locks");
    800023fa:	00006517          	auipc	a0,0x6
    800023fe:	e2e50513          	addi	a0,a0,-466 # 80008228 <digits+0x1e8>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	13c080e7          	jalr	316(ra) # 8000053e <panic>
    panic("sched running");
    8000240a:	00006517          	auipc	a0,0x6
    8000240e:	e2e50513          	addi	a0,a0,-466 # 80008238 <digits+0x1f8>
    80002412:	ffffe097          	auipc	ra,0xffffe
    80002416:	12c080e7          	jalr	300(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000241a:	00006517          	auipc	a0,0x6
    8000241e:	e2e50513          	addi	a0,a0,-466 # 80008248 <digits+0x208>
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	11c080e7          	jalr	284(ra) # 8000053e <panic>

000000008000242a <yield>:
{
    8000242a:	1101                	addi	sp,sp,-32
    8000242c:	ec06                	sd	ra,24(sp)
    8000242e:	e822                	sd	s0,16(sp)
    80002430:	e426                	sd	s1,8(sp)
    80002432:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	5a4080e7          	jalr	1444(ra) # 800019d8 <myproc>
    8000243c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	7a6080e7          	jalr	1958(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002446:	478d                	li	a5,3
    80002448:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    8000244a:	00007797          	auipc	a5,0x7
    8000244e:	c0a7a783          	lw	a5,-1014(a5) # 80009054 <ticks>
    80002452:	dcdc                	sw	a5,60(s1)
  sched();
    80002454:	00000097          	auipc	ra,0x0
    80002458:	f00080e7          	jalr	-256(ra) # 80002354 <sched>
  release(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	83a080e7          	jalr	-1990(ra) # 80000c98 <release>
}
    80002466:	60e2                	ld	ra,24(sp)
    80002468:	6442                	ld	s0,16(sp)
    8000246a:	64a2                	ld	s1,8(sp)
    8000246c:	6105                	addi	sp,sp,32
    8000246e:	8082                	ret

0000000080002470 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002470:	7179                	addi	sp,sp,-48
    80002472:	f406                	sd	ra,40(sp)
    80002474:	f022                	sd	s0,32(sp)
    80002476:	ec26                	sd	s1,24(sp)
    80002478:	e84a                	sd	s2,16(sp)
    8000247a:	e44e                	sd	s3,8(sp)
    8000247c:	1800                	addi	s0,sp,48
    8000247e:	89aa                	mv	s3,a0
    80002480:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	556080e7          	jalr	1366(ra) # 800019d8 <myproc>
    8000248a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	758080e7          	jalr	1880(ra) # 80000be4 <acquire>
  release(lk);
    80002494:	854a                	mv	a0,s2
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	802080e7          	jalr	-2046(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000249e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800024a2:	4789                	li	a5,2
    800024a4:	cc9c                	sw	a5,24(s1)
  p->start_sleeping_time = ticks;
    800024a6:	00007797          	auipc	a5,0x7
    800024aa:	bae7a783          	lw	a5,-1106(a5) # 80009054 <ticks>
    800024ae:	c8fc                	sw	a5,84(s1)

  sched();
    800024b0:	00000097          	auipc	ra,0x0
    800024b4:	ea4080e7          	jalr	-348(ra) # 80002354 <sched>

  // Tidy up.
  p->chan = 0;
    800024b8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	7da080e7          	jalr	2010(ra) # 80000c98 <release>
  acquire(lk);
    800024c6:	854a                	mv	a0,s2
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	71c080e7          	jalr	1820(ra) # 80000be4 <acquire>
}
    800024d0:	70a2                	ld	ra,40(sp)
    800024d2:	7402                	ld	s0,32(sp)
    800024d4:	64e2                	ld	s1,24(sp)
    800024d6:	6942                	ld	s2,16(sp)
    800024d8:	69a2                	ld	s3,8(sp)
    800024da:	6145                	addi	sp,sp,48
    800024dc:	8082                	ret

00000000800024de <wait>:
{
    800024de:	711d                	addi	sp,sp,-96
    800024e0:	ec86                	sd	ra,88(sp)
    800024e2:	e8a2                	sd	s0,80(sp)
    800024e4:	e4a6                	sd	s1,72(sp)
    800024e6:	e0ca                	sd	s2,64(sp)
    800024e8:	fc4e                	sd	s3,56(sp)
    800024ea:	f852                	sd	s4,48(sp)
    800024ec:	f456                	sd	s5,40(sp)
    800024ee:	f05a                	sd	s6,32(sp)
    800024f0:	ec5e                	sd	s7,24(sp)
    800024f2:	e862                	sd	s8,16(sp)
    800024f4:	e466                	sd	s9,8(sp)
    800024f6:	1080                	addi	s0,sp,96
    800024f8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	4de080e7          	jalr	1246(ra) # 800019d8 <myproc>
    80002502:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002504:	0000f517          	auipc	a0,0xf
    80002508:	dd450513          	addi	a0,a0,-556 # 800112d8 <wait_lock>
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	6d8080e7          	jalr	1752(ra) # 80000be4 <acquire>
    havekids = 0;
    80002514:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002516:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002518:	00015997          	auipc	s3,0x15
    8000251c:	5d898993          	addi	s3,s3,1496 # 80017af0 <tickslock>
        havekids = 1;
    80002520:	4a85                	li	s5,1
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002522:	00007c97          	auipc	s9,0x7
    80002526:	b32c8c93          	addi	s9,s9,-1230 # 80009054 <ticks>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000252a:	0000fc17          	auipc	s8,0xf
    8000252e:	daec0c13          	addi	s8,s8,-594 # 800112d8 <wait_lock>
    havekids = 0;
    80002532:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002534:	0000f497          	auipc	s1,0xf
    80002538:	1bc48493          	addi	s1,s1,444 # 800116f0 <proc>
    8000253c:	a0bd                	j	800025aa <wait+0xcc>
          pid = np->pid;
    8000253e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002542:	000b0e63          	beqz	s6,8000255e <wait+0x80>
    80002546:	4691                	li	a3,4
    80002548:	02c48613          	addi	a2,s1,44
    8000254c:	85da                	mv	a1,s6
    8000254e:	07893503          	ld	a0,120(s2)
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	128080e7          	jalr	296(ra) # 8000167a <copyout>
    8000255a:	02054563          	bltz	a0,80002584 <wait+0xa6>
          freeproc(np);
    8000255e:	8526                	mv	a0,s1
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	620080e7          	jalr	1568(ra) # 80001b80 <freeproc>
          release(&np->lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	72e080e7          	jalr	1838(ra) # 80000c98 <release>
          release(&wait_lock);
    80002572:	0000f517          	auipc	a0,0xf
    80002576:	d6650513          	addi	a0,a0,-666 # 800112d8 <wait_lock>
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	71e080e7          	jalr	1822(ra) # 80000c98 <release>
          return pid;
    80002582:	a09d                	j	800025e8 <wait+0x10a>
            release(&np->lock);
    80002584:	8526                	mv	a0,s1
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	712080e7          	jalr	1810(ra) # 80000c98 <release>
            release(&wait_lock);
    8000258e:	0000f517          	auipc	a0,0xf
    80002592:	d4a50513          	addi	a0,a0,-694 # 800112d8 <wait_lock>
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	702080e7          	jalr	1794(ra) # 80000c98 <release>
            return -1;
    8000259e:	59fd                	li	s3,-1
    800025a0:	a0a1                	j	800025e8 <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    800025a2:	19048493          	addi	s1,s1,400
    800025a6:	03348463          	beq	s1,s3,800025ce <wait+0xf0>
      if(np->parent == p){
    800025aa:	70bc                	ld	a5,96(s1)
    800025ac:	ff279be3          	bne	a5,s2,800025a2 <wait+0xc4>
        acquire(&np->lock);
    800025b0:	8526                	mv	a0,s1
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	632080e7          	jalr	1586(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800025ba:	4c9c                	lw	a5,24(s1)
    800025bc:	f94781e3          	beq	a5,s4,8000253e <wait+0x60>
        release(&np->lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	6d6080e7          	jalr	1750(ra) # 80000c98 <release>
        havekids = 1;
    800025ca:	8756                	mv	a4,s5
    800025cc:	bfd9                	j	800025a2 <wait+0xc4>
    if(!havekids || p->killed){
    800025ce:	c701                	beqz	a4,800025d6 <wait+0xf8>
    800025d0:	02892783          	lw	a5,40(s2)
    800025d4:	cb85                	beqz	a5,80002604 <wait+0x126>
      release(&wait_lock);
    800025d6:	0000f517          	auipc	a0,0xf
    800025da:	d0250513          	addi	a0,a0,-766 # 800112d8 <wait_lock>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	6ba080e7          	jalr	1722(ra) # 80000c98 <release>
      return -1;
    800025e6:	59fd                	li	s3,-1
}
    800025e8:	854e                	mv	a0,s3
    800025ea:	60e6                	ld	ra,88(sp)
    800025ec:	6446                	ld	s0,80(sp)
    800025ee:	64a6                	ld	s1,72(sp)
    800025f0:	6906                	ld	s2,64(sp)
    800025f2:	79e2                	ld	s3,56(sp)
    800025f4:	7a42                	ld	s4,48(sp)
    800025f6:	7aa2                	ld	s5,40(sp)
    800025f8:	7b02                	ld	s6,32(sp)
    800025fa:	6be2                	ld	s7,24(sp)
    800025fc:	6c42                	ld	s8,16(sp)
    800025fe:	6ca2                	ld	s9,8(sp)
    80002600:	6125                	addi	sp,sp,96
    80002602:	8082                	ret
    if (p->state == RUNNING)
    80002604:	01892783          	lw	a5,24(s2)
    80002608:	4711                	li	a4,4
    8000260a:	02e78063          	beq	a5,a4,8000262a <wait+0x14c>
     if (p->state == RUNNABLE)
    8000260e:	470d                	li	a4,3
    80002610:	02e79e63          	bne	a5,a4,8000264c <wait+0x16e>
      p->runnable_time += ticks - p->last_runnable_time;
    80002614:	04892783          	lw	a5,72(s2)
    80002618:	000ca703          	lw	a4,0(s9)
    8000261c:	9fb9                	addw	a5,a5,a4
    8000261e:	03c92703          	lw	a4,60(s2)
    80002622:	9f99                	subw	a5,a5,a4
    80002624:	04f92423          	sw	a5,72(s2)
    if (p->state == SLEEPING)
    80002628:	a819                	j	8000263e <wait+0x160>
      p->running_time += ticks - p->start_running_time;
    8000262a:	04492783          	lw	a5,68(s2)
    8000262e:	000ca703          	lw	a4,0(s9)
    80002632:	9fb9                	addw	a5,a5,a4
    80002634:	05092703          	lw	a4,80(s2)
    80002638:	9f99                	subw	a5,a5,a4
    8000263a:	04f92223          	sw	a5,68(s2)
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000263e:	85e2                	mv	a1,s8
    80002640:	854a                	mv	a0,s2
    80002642:	00000097          	auipc	ra,0x0
    80002646:	e2e080e7          	jalr	-466(ra) # 80002470 <sleep>
    havekids = 0;
    8000264a:	b5e5                	j	80002532 <wait+0x54>
    if (p->state == SLEEPING)
    8000264c:	4709                	li	a4,2
    8000264e:	fee798e3          	bne	a5,a4,8000263e <wait+0x160>
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002652:	04c92783          	lw	a5,76(s2)
    80002656:	000ca703          	lw	a4,0(s9)
    8000265a:	9fb9                	addw	a5,a5,a4
    8000265c:	05492703          	lw	a4,84(s2)
    80002660:	9f99                	subw	a5,a5,a4
    80002662:	04f92623          	sw	a5,76(s2)
    80002666:	bfe1                	j	8000263e <wait+0x160>

0000000080002668 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002668:	7139                	addi	sp,sp,-64
    8000266a:	fc06                	sd	ra,56(sp)
    8000266c:	f822                	sd	s0,48(sp)
    8000266e:	f426                	sd	s1,40(sp)
    80002670:	f04a                	sd	s2,32(sp)
    80002672:	ec4e                	sd	s3,24(sp)
    80002674:	e852                	sd	s4,16(sp)
    80002676:	e456                	sd	s5,8(sp)
    80002678:	e05a                	sd	s6,0(sp)
    8000267a:	0080                	addi	s0,sp,64
    8000267c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000267e:	0000f497          	auipc	s1,0xf
    80002682:	07248493          	addi	s1,s1,114 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002686:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002688:	4b0d                	li	s6,3
        p->sleeping_time += ticks - p->start_sleeping_time;
    8000268a:	00007a97          	auipc	s5,0x7
    8000268e:	9caa8a93          	addi	s5,s5,-1590 # 80009054 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002692:	00015917          	auipc	s2,0x15
    80002696:	45e90913          	addi	s2,s2,1118 # 80017af0 <tickslock>
    8000269a:	a025                	j	800026c2 <wakeup+0x5a>
        p->state = RUNNABLE;
    8000269c:	0164ac23          	sw	s6,24(s1)
        p->sleeping_time += ticks - p->start_sleeping_time;
    800026a0:	000aa703          	lw	a4,0(s5)
    800026a4:	44fc                	lw	a5,76(s1)
    800026a6:	9fb9                	addw	a5,a5,a4
    800026a8:	48f4                	lw	a3,84(s1)
    800026aa:	9f95                	subw	a5,a5,a3
    800026ac:	c4fc                	sw	a5,76(s1)
        // added
        p->last_runnable_time = ticks;
    800026ae:	dcd8                	sw	a4,60(s1)
      }
      release(&p->lock);
    800026b0:	8526                	mv	a0,s1
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	5e6080e7          	jalr	1510(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026ba:	19048493          	addi	s1,s1,400
    800026be:	03248463          	beq	s1,s2,800026e6 <wakeup+0x7e>
    if(p != myproc()){
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	316080e7          	jalr	790(ra) # 800019d8 <myproc>
    800026ca:	fea488e3          	beq	s1,a0,800026ba <wakeup+0x52>
      acquire(&p->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	514080e7          	jalr	1300(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800026d8:	4c9c                	lw	a5,24(s1)
    800026da:	fd379be3          	bne	a5,s3,800026b0 <wakeup+0x48>
    800026de:	709c                	ld	a5,32(s1)
    800026e0:	fd4798e3          	bne	a5,s4,800026b0 <wakeup+0x48>
    800026e4:	bf65                	j	8000269c <wakeup+0x34>
    }
  }
}
    800026e6:	70e2                	ld	ra,56(sp)
    800026e8:	7442                	ld	s0,48(sp)
    800026ea:	74a2                	ld	s1,40(sp)
    800026ec:	7902                	ld	s2,32(sp)
    800026ee:	69e2                	ld	s3,24(sp)
    800026f0:	6a42                	ld	s4,16(sp)
    800026f2:	6aa2                	ld	s5,8(sp)
    800026f4:	6b02                	ld	s6,0(sp)
    800026f6:	6121                	addi	sp,sp,64
    800026f8:	8082                	ret

00000000800026fa <reparent>:
{
    800026fa:	7179                	addi	sp,sp,-48
    800026fc:	f406                	sd	ra,40(sp)
    800026fe:	f022                	sd	s0,32(sp)
    80002700:	ec26                	sd	s1,24(sp)
    80002702:	e84a                	sd	s2,16(sp)
    80002704:	e44e                	sd	s3,8(sp)
    80002706:	e052                	sd	s4,0(sp)
    80002708:	1800                	addi	s0,sp,48
    8000270a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000270c:	0000f497          	auipc	s1,0xf
    80002710:	fe448493          	addi	s1,s1,-28 # 800116f0 <proc>
      pp->parent = initproc;
    80002714:	00007a17          	auipc	s4,0x7
    80002718:	914a0a13          	addi	s4,s4,-1772 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000271c:	00015997          	auipc	s3,0x15
    80002720:	3d498993          	addi	s3,s3,980 # 80017af0 <tickslock>
    80002724:	a029                	j	8000272e <reparent+0x34>
    80002726:	19048493          	addi	s1,s1,400
    8000272a:	01348d63          	beq	s1,s3,80002744 <reparent+0x4a>
    if(pp->parent == p){
    8000272e:	70bc                	ld	a5,96(s1)
    80002730:	ff279be3          	bne	a5,s2,80002726 <reparent+0x2c>
      pp->parent = initproc;
    80002734:	000a3503          	ld	a0,0(s4)
    80002738:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    8000273a:	00000097          	auipc	ra,0x0
    8000273e:	f2e080e7          	jalr	-210(ra) # 80002668 <wakeup>
    80002742:	b7d5                	j	80002726 <reparent+0x2c>
}
    80002744:	70a2                	ld	ra,40(sp)
    80002746:	7402                	ld	s0,32(sp)
    80002748:	64e2                	ld	s1,24(sp)
    8000274a:	6942                	ld	s2,16(sp)
    8000274c:	69a2                	ld	s3,8(sp)
    8000274e:	6a02                	ld	s4,0(sp)
    80002750:	6145                	addi	sp,sp,48
    80002752:	8082                	ret

0000000080002754 <exit>:
{
    80002754:	7179                	addi	sp,sp,-48
    80002756:	f406                	sd	ra,40(sp)
    80002758:	f022                	sd	s0,32(sp)
    8000275a:	ec26                	sd	s1,24(sp)
    8000275c:	e84a                	sd	s2,16(sp)
    8000275e:	e44e                	sd	s3,8(sp)
    80002760:	e052                	sd	s4,0(sp)
    80002762:	1800                	addi	s0,sp,48
    80002764:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	272080e7          	jalr	626(ra) # 800019d8 <myproc>
    8000276e:	892a                	mv	s2,a0
  if(p == initproc)
    80002770:	00007797          	auipc	a5,0x7
    80002774:	8b87b783          	ld	a5,-1864(a5) # 80009028 <initproc>
    80002778:	0f850493          	addi	s1,a0,248
    8000277c:	17850993          	addi	s3,a0,376
    80002780:	02a79363          	bne	a5,a0,800027a6 <exit+0x52>
    panic("init exiting");
    80002784:	00006517          	auipc	a0,0x6
    80002788:	adc50513          	addi	a0,a0,-1316 # 80008260 <digits+0x220>
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	db2080e7          	jalr	-590(ra) # 8000053e <panic>
      fileclose(f);
    80002794:	00002097          	auipc	ra,0x2
    80002798:	5f4080e7          	jalr	1524(ra) # 80004d88 <fileclose>
      p->ofile[fd] = 0;
    8000279c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800027a0:	04a1                	addi	s1,s1,8
    800027a2:	01348563          	beq	s1,s3,800027ac <exit+0x58>
    if(p->ofile[fd]){
    800027a6:	6088                	ld	a0,0(s1)
    800027a8:	f575                	bnez	a0,80002794 <exit+0x40>
    800027aa:	bfdd                	j	800027a0 <exit+0x4c>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    800027ac:	18090493          	addi	s1,s2,384
    800027b0:	00006597          	auipc	a1,0x6
    800027b4:	ac058593          	addi	a1,a1,-1344 # 80008270 <digits+0x230>
    800027b8:	8526                	mv	a0,s1
    800027ba:	fffff097          	auipc	ra,0xfffff
    800027be:	504080e7          	jalr	1284(ra) # 80001cbe <str_compare>
    800027c2:	ed41                	bnez	a0,8000285a <exit+0x106>
  begin_op();
    800027c4:	00002097          	auipc	ra,0x2
    800027c8:	0f8080e7          	jalr	248(ra) # 800048bc <begin_op>
  iput(p->cwd);
    800027cc:	17893503          	ld	a0,376(s2)
    800027d0:	00002097          	auipc	ra,0x2
    800027d4:	8d4080e7          	jalr	-1836(ra) # 800040a4 <iput>
  end_op();
    800027d8:	00002097          	auipc	ra,0x2
    800027dc:	164080e7          	jalr	356(ra) # 8000493c <end_op>
  p->cwd = 0;
    800027e0:	16093c23          	sd	zero,376(s2)
  acquire(&wait_lock);
    800027e4:	0000f497          	auipc	s1,0xf
    800027e8:	af448493          	addi	s1,s1,-1292 # 800112d8 <wait_lock>
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	3f6080e7          	jalr	1014(ra) # 80000be4 <acquire>
  reparent(p);
    800027f6:	854a                	mv	a0,s2
    800027f8:	00000097          	auipc	ra,0x0
    800027fc:	f02080e7          	jalr	-254(ra) # 800026fa <reparent>
  wakeup(p->parent);
    80002800:	06093503          	ld	a0,96(s2)
    80002804:	00000097          	auipc	ra,0x0
    80002808:	e64080e7          	jalr	-412(ra) # 80002668 <wakeup>
  acquire(&p->lock);
    8000280c:	854a                	mv	a0,s2
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	3d6080e7          	jalr	982(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002816:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000281a:	4795                	li	a5,5
    8000281c:	00f92c23          	sw	a5,24(s2)
  p->running_time += ticks - p->start_running_time;
    80002820:	04492783          	lw	a5,68(s2)
    80002824:	00007717          	auipc	a4,0x7
    80002828:	83072703          	lw	a4,-2000(a4) # 80009054 <ticks>
    8000282c:	9fb9                	addw	a5,a5,a4
    8000282e:	05092703          	lw	a4,80(s2)
    80002832:	9f99                	subw	a5,a5,a4
    80002834:	04f92223          	sw	a5,68(s2)
  release(&wait_lock);
    80002838:	8526                	mv	a0,s1
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	45e080e7          	jalr	1118(ra) # 80000c98 <release>
  sched();
    80002842:	00000097          	auipc	ra,0x0
    80002846:	b12080e7          	jalr	-1262(ra) # 80002354 <sched>
  panic("zombie exit");
    8000284a:	00006517          	auipc	a0,0x6
    8000284e:	a3650513          	addi	a0,a0,-1482 # 80008280 <digits+0x240>
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	cec080e7          	jalr	-788(ra) # 8000053e <panic>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    8000285a:	00006597          	auipc	a1,0x6
    8000285e:	a1e58593          	addi	a1,a1,-1506 # 80008278 <digits+0x238>
    80002862:	8526                	mv	a0,s1
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	45a080e7          	jalr	1114(ra) # 80001cbe <str_compare>
    8000286c:	dd21                	beqz	a0,800027c4 <exit+0x70>
    sleeping_processes_mean = ((sleeping_processes_mean * p_counter)+ p->sleeping_time)/(p_counter+1);
    8000286e:	00006597          	auipc	a1,0x6
    80002872:	7ce58593          	addi	a1,a1,1998 # 8000903c <p_counter>
    80002876:	4194                	lw	a3,0(a1)
    80002878:	0016871b          	addiw	a4,a3,1
    8000287c:	00006617          	auipc	a2,0x6
    80002880:	7cc60613          	addi	a2,a2,1996 # 80009048 <sleeping_processes_mean>
    80002884:	421c                	lw	a5,0(a2)
    80002886:	02d787bb          	mulw	a5,a5,a3
    8000288a:	04c92503          	lw	a0,76(s2)
    8000288e:	9fa9                	addw	a5,a5,a0
    80002890:	02e7d7bb          	divuw	a5,a5,a4
    80002894:	c21c                	sw	a5,0(a2)
    running_processes_mean = ((running_processes_mean * p_counter)+ p->running_time)/(p_counter+1);
    80002896:	04492603          	lw	a2,68(s2)
    8000289a:	00006517          	auipc	a0,0x6
    8000289e:	7aa50513          	addi	a0,a0,1962 # 80009044 <running_processes_mean>
    800028a2:	411c                	lw	a5,0(a0)
    800028a4:	02d787bb          	mulw	a5,a5,a3
    800028a8:	9fb1                	addw	a5,a5,a2
    800028aa:	02e7d7bb          	divuw	a5,a5,a4
    800028ae:	c11c                	sw	a5,0(a0)
    runnable_processes_mean = ((runnable_processes_mean * p_counter)+ p->runnable_time)/(p_counter+1);
    800028b0:	00006517          	auipc	a0,0x6
    800028b4:	79050513          	addi	a0,a0,1936 # 80009040 <runnable_processes_mean>
    800028b8:	411c                	lw	a5,0(a0)
    800028ba:	02d787bb          	mulw	a5,a5,a3
    800028be:	04892683          	lw	a3,72(s2)
    800028c2:	9fb5                	addw	a5,a5,a3
    800028c4:	02e7d7bb          	divuw	a5,a5,a4
    800028c8:	c11c                	sw	a5,0(a0)
    p_counter += 1;
    800028ca:	c198                	sw	a4,0(a1)
    program_time += p->running_time;
    800028cc:	00006697          	auipc	a3,0x6
    800028d0:	76c68693          	addi	a3,a3,1900 # 80009038 <program_time>
    800028d4:	429c                	lw	a5,0(a3)
    800028d6:	00c7873b          	addw	a4,a5,a2
    800028da:	c298                	sw	a4,0(a3)
    cpu_utilization = (program_time* 100) / (ticks - start_time) ;
    800028dc:	06400793          	li	a5,100
    800028e0:	02e787bb          	mulw	a5,a5,a4
    800028e4:	00006717          	auipc	a4,0x6
    800028e8:	77072703          	lw	a4,1904(a4) # 80009054 <ticks>
    800028ec:	00006697          	auipc	a3,0x6
    800028f0:	7486a683          	lw	a3,1864(a3) # 80009034 <start_time>
    800028f4:	9f15                	subw	a4,a4,a3
    800028f6:	02e7d7bb          	divuw	a5,a5,a4
    800028fa:	00006717          	auipc	a4,0x6
    800028fe:	72f72b23          	sw	a5,1846(a4) # 80009030 <cpu_utilization>
    80002902:	b5c9                	j	800027c4 <exit+0x70>

0000000080002904 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002904:	7179                	addi	sp,sp,-48
    80002906:	f406                	sd	ra,40(sp)
    80002908:	f022                	sd	s0,32(sp)
    8000290a:	ec26                	sd	s1,24(sp)
    8000290c:	e84a                	sd	s2,16(sp)
    8000290e:	e44e                	sd	s3,8(sp)
    80002910:	1800                	addi	s0,sp,48
    80002912:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002914:	0000f497          	auipc	s1,0xf
    80002918:	ddc48493          	addi	s1,s1,-548 # 800116f0 <proc>
    8000291c:	00015997          	auipc	s3,0x15
    80002920:	1d498993          	addi	s3,s3,468 # 80017af0 <tickslock>
    acquire(&p->lock);
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	2be080e7          	jalr	702(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000292e:	589c                	lw	a5,48(s1)
    80002930:	01278d63          	beq	a5,s2,8000294a <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002934:	8526                	mv	a0,s1
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	362080e7          	jalr	866(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000293e:	19048493          	addi	s1,s1,400
    80002942:	ff3491e3          	bne	s1,s3,80002924 <kill+0x20>
  }
  return -1;
    80002946:	557d                	li	a0,-1
    80002948:	a829                	j	80002962 <kill+0x5e>
      p->killed = 1;
    8000294a:	4785                	li	a5,1
    8000294c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000294e:	4c98                	lw	a4,24(s1)
    80002950:	4789                	li	a5,2
    80002952:	00f70f63          	beq	a4,a5,80002970 <kill+0x6c>
      release(&p->lock);
    80002956:	8526                	mv	a0,s1
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	340080e7          	jalr	832(ra) # 80000c98 <release>
      return 0;
    80002960:	4501                	li	a0,0
}
    80002962:	70a2                	ld	ra,40(sp)
    80002964:	7402                	ld	s0,32(sp)
    80002966:	64e2                	ld	s1,24(sp)
    80002968:	6942                	ld	s2,16(sp)
    8000296a:	69a2                	ld	s3,8(sp)
    8000296c:	6145                	addi	sp,sp,48
    8000296e:	8082                	ret
        p->state = RUNNABLE;
    80002970:	478d                	li	a5,3
    80002972:	cc9c                	sw	a5,24(s1)
        p->sleeping_time += ticks - p->start_sleeping_time;
    80002974:	00006717          	auipc	a4,0x6
    80002978:	6e072703          	lw	a4,1760(a4) # 80009054 <ticks>
    8000297c:	44fc                	lw	a5,76(s1)
    8000297e:	9fb9                	addw	a5,a5,a4
    80002980:	48f4                	lw	a3,84(s1)
    80002982:	9f95                	subw	a5,a5,a3
    80002984:	c4fc                	sw	a5,76(s1)
        p->last_runnable_time = ticks;
    80002986:	dcd8                	sw	a4,60(s1)
    80002988:	b7f9                	j	80002956 <kill+0x52>

000000008000298a <print_stats>:

int 
print_stats(void)
{
    8000298a:	1141                	addi	sp,sp,-16
    8000298c:	e406                	sd	ra,8(sp)
    8000298e:	e022                	sd	s0,0(sp)
    80002990:	0800                	addi	s0,sp,16
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    80002992:	00006597          	auipc	a1,0x6
    80002996:	6b65a583          	lw	a1,1718(a1) # 80009048 <sleeping_processes_mean>
    8000299a:	00006517          	auipc	a0,0x6
    8000299e:	8f650513          	addi	a0,a0,-1802 # 80008290 <digits+0x250>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	be6080e7          	jalr	-1050(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    800029aa:	00006597          	auipc	a1,0x6
    800029ae:	6965a583          	lw	a1,1686(a1) # 80009040 <runnable_processes_mean>
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	8fe50513          	addi	a0,a0,-1794 # 800082b0 <digits+0x270>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	bce080e7          	jalr	-1074(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    800029c2:	00006597          	auipc	a1,0x6
    800029c6:	6825a583          	lw	a1,1666(a1) # 80009044 <running_processes_mean>
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	90650513          	addi	a0,a0,-1786 # 800082d0 <digits+0x290>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bb6080e7          	jalr	-1098(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    800029da:	00006597          	auipc	a1,0x6
    800029de:	65e5a583          	lw	a1,1630(a1) # 80009038 <program_time>
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	90e50513          	addi	a0,a0,-1778 # 800082f0 <digits+0x2b0>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	b9e080e7          	jalr	-1122(ra) # 80000588 <printf>
  printf("cpu_utilization: %d\n", cpu_utilization);
    800029f2:	00006597          	auipc	a1,0x6
    800029f6:	63e5a583          	lw	a1,1598(a1) # 80009030 <cpu_utilization>
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	90e50513          	addi	a0,a0,-1778 # 80008308 <digits+0x2c8>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b86080e7          	jalr	-1146(ra) # 80000588 <printf>
  printf("ticks: %d\n", ticks);
    80002a0a:	00006597          	auipc	a1,0x6
    80002a0e:	64a5a583          	lw	a1,1610(a1) # 80009054 <ticks>
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	90e50513          	addi	a0,a0,-1778 # 80008320 <digits+0x2e0>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b6e080e7          	jalr	-1170(ra) # 80000588 <printf>
  return 0;
}
    80002a22:	4501                	li	a0,0
    80002a24:	60a2                	ld	ra,8(sp)
    80002a26:	6402                	ld	s0,0(sp)
    80002a28:	0141                	addi	sp,sp,16
    80002a2a:	8082                	ret

0000000080002a2c <set_cpu>:

// Ass2
int
set_cpu(int cpu_num)
{
    80002a2c:	1141                	addi	sp,sp,-16
    80002a2e:	e422                	sd	s0,8(sp)
    80002a30:	0800                	addi	s0,sp,16
  // TODO
  return 0;
}
    80002a32:	4501                	li	a0,0
    80002a34:	6422                	ld	s0,8(sp)
    80002a36:	0141                	addi	sp,sp,16
    80002a38:	8082                	ret

0000000080002a3a <get_cpu>:


int
get_cpu()
{
    80002a3a:	1141                	addi	sp,sp,-16
    80002a3c:	e422                	sd	s0,8(sp)
    80002a3e:	0800                	addi	s0,sp,16
  // TODO
  return 0;
}
    80002a40:	4501                	li	a0,0
    80002a42:	6422                	ld	s0,8(sp)
    80002a44:	0141                	addi	sp,sp,16
    80002a46:	8082                	ret

0000000080002a48 <pause_system>:


int
pause_system(int seconds)
{
    80002a48:	711d                	addi	sp,sp,-96
    80002a4a:	ec86                	sd	ra,88(sp)
    80002a4c:	e8a2                	sd	s0,80(sp)
    80002a4e:	e4a6                	sd	s1,72(sp)
    80002a50:	e0ca                	sd	s2,64(sp)
    80002a52:	fc4e                	sd	s3,56(sp)
    80002a54:	f852                	sd	s4,48(sp)
    80002a56:	f456                	sd	s5,40(sp)
    80002a58:	f05a                	sd	s6,32(sp)
    80002a5a:	ec5e                	sd	s7,24(sp)
    80002a5c:	e862                	sd	s8,16(sp)
    80002a5e:	e466                	sd	s9,8(sp)
    80002a60:	1080                	addi	s0,sp,96
    80002a62:	84aa                	mv	s1,a0
  struct proc *p;
  struct proc *myProcess = myproc();
    80002a64:	fffff097          	auipc	ra,0xfffff
    80002a68:	f74080e7          	jalr	-140(ra) # 800019d8 <myproc>
    80002a6c:	8b2a                	mv	s6,a0

  pause_flag = 1;
    80002a6e:	4785                	li	a5,1
    80002a70:	00006717          	auipc	a4,0x6
    80002a74:	5ef72023          	sw	a5,1504(a4) # 80009050 <pause_flag>

  wake_up_time = ticks + (seconds * 10);
    80002a78:	0024979b          	slliw	a5,s1,0x2
    80002a7c:	9fa5                	addw	a5,a5,s1
    80002a7e:	0017979b          	slliw	a5,a5,0x1
    80002a82:	00006717          	auipc	a4,0x6
    80002a86:	5d272703          	lw	a4,1490(a4) # 80009054 <ticks>
    80002a8a:	9fb9                	addw	a5,a5,a4
    80002a8c:	00006717          	auipc	a4,0x6
    80002a90:	5cf72023          	sw	a5,1472(a4) # 8000904c <wake_up_time>

  for(p = proc; p < &proc[NPROC]; p++)
    80002a94:	0000f497          	auipc	s1,0xf
    80002a98:	c5c48493          	addi	s1,s1,-932 # 800116f0 <proc>
  {
    acquire(&p->lock);
    if(p->state == RUNNING)
    80002a9c:	4991                	li	s3,4
    {
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80002a9e:	00005a97          	auipc	s5,0x5
    80002aa2:	7d2a8a93          	addi	s5,s5,2002 # 80008270 <digits+0x230>
    80002aa6:	00005b97          	auipc	s7,0x5
    80002aaa:	7d2b8b93          	addi	s7,s7,2002 # 80008278 <digits+0x238>
        if (p != myProcess) {
          p->paused = 1;
    80002aae:	4c85                	li	s9,1
          p->running_time += ticks - p->start_running_time;
    80002ab0:	00006c17          	auipc	s8,0x6
    80002ab4:	5a4c0c13          	addi	s8,s8,1444 # 80009054 <ticks>
  for(p = proc; p < &proc[NPROC]; p++)
    80002ab8:	00015917          	auipc	s2,0x15
    80002abc:	03890913          	addi	s2,s2,56 # 80017af0 <tickslock>
    80002ac0:	a811                	j	80002ad4 <pause_system+0x8c>
          yield();
        }
      }
    }
    release(&p->lock);
    80002ac2:	8526                	mv	a0,s1
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	1d4080e7          	jalr	468(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002acc:	19048493          	addi	s1,s1,400
    80002ad0:	05248a63          	beq	s1,s2,80002b24 <pause_system+0xdc>
    acquire(&p->lock);
    80002ad4:	8526                	mv	a0,s1
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	10e080e7          	jalr	270(ra) # 80000be4 <acquire>
    if(p->state == RUNNING)
    80002ade:	4c9c                	lw	a5,24(s1)
    80002ae0:	ff3791e3          	bne	a5,s3,80002ac2 <pause_system+0x7a>
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80002ae4:	18048a13          	addi	s4,s1,384
    80002ae8:	85d6                	mv	a1,s5
    80002aea:	8552                	mv	a0,s4
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	1d2080e7          	jalr	466(ra) # 80001cbe <str_compare>
    80002af4:	d579                	beqz	a0,80002ac2 <pause_system+0x7a>
    80002af6:	85de                	mv	a1,s7
    80002af8:	8552                	mv	a0,s4
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	1c4080e7          	jalr	452(ra) # 80001cbe <str_compare>
    80002b02:	d161                	beqz	a0,80002ac2 <pause_system+0x7a>
        if (p != myProcess) {
    80002b04:	fa9b0fe3          	beq	s6,s1,80002ac2 <pause_system+0x7a>
          p->paused = 1;
    80002b08:	0594a023          	sw	s9,64(s1)
          p->running_time += ticks - p->start_running_time;
    80002b0c:	40fc                	lw	a5,68(s1)
    80002b0e:	000c2703          	lw	a4,0(s8)
    80002b12:	9fb9                	addw	a5,a5,a4
    80002b14:	48b8                	lw	a4,80(s1)
    80002b16:	9f99                	subw	a5,a5,a4
    80002b18:	c0fc                	sw	a5,68(s1)
          yield();
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	910080e7          	jalr	-1776(ra) # 8000242a <yield>
    80002b22:	b745                	j	80002ac2 <pause_system+0x7a>
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    80002b24:	180b0493          	addi	s1,s6,384
    80002b28:	00005597          	auipc	a1,0x5
    80002b2c:	74858593          	addi	a1,a1,1864 # 80008270 <digits+0x230>
    80002b30:	8526                	mv	a0,s1
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	18c080e7          	jalr	396(ra) # 80001cbe <str_compare>
    80002b3a:	ed19                	bnez	a0,80002b58 <pause_system+0x110>
    myProcess->running_time += ticks - myProcess->start_running_time;
    release(&myProcess->lock);
    yield();
  }
  return 0;
}
    80002b3c:	4501                	li	a0,0
    80002b3e:	60e6                	ld	ra,88(sp)
    80002b40:	6446                	ld	s0,80(sp)
    80002b42:	64a6                	ld	s1,72(sp)
    80002b44:	6906                	ld	s2,64(sp)
    80002b46:	79e2                	ld	s3,56(sp)
    80002b48:	7a42                	ld	s4,48(sp)
    80002b4a:	7aa2                	ld	s5,40(sp)
    80002b4c:	7b02                	ld	s6,32(sp)
    80002b4e:	6be2                	ld	s7,24(sp)
    80002b50:	6c42                	ld	s8,16(sp)
    80002b52:	6ca2                	ld	s9,8(sp)
    80002b54:	6125                	addi	sp,sp,96
    80002b56:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    80002b58:	00005597          	auipc	a1,0x5
    80002b5c:	72058593          	addi	a1,a1,1824 # 80008278 <digits+0x238>
    80002b60:	8526                	mv	a0,s1
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	15c080e7          	jalr	348(ra) # 80001cbe <str_compare>
    80002b6a:	d969                	beqz	a0,80002b3c <pause_system+0xf4>
    acquire(&myProcess->lock);
    80002b6c:	855a                	mv	a0,s6
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	076080e7          	jalr	118(ra) # 80000be4 <acquire>
    myProcess->paused = 1;
    80002b76:	4785                	li	a5,1
    80002b78:	04fb2023          	sw	a5,64(s6)
    myProcess->running_time += ticks - myProcess->start_running_time;
    80002b7c:	044b2783          	lw	a5,68(s6)
    80002b80:	00006717          	auipc	a4,0x6
    80002b84:	4d472703          	lw	a4,1236(a4) # 80009054 <ticks>
    80002b88:	9fb9                	addw	a5,a5,a4
    80002b8a:	050b2703          	lw	a4,80(s6)
    80002b8e:	9f99                	subw	a5,a5,a4
    80002b90:	04fb2223          	sw	a5,68(s6)
    release(&myProcess->lock);
    80002b94:	855a                	mv	a0,s6
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	102080e7          	jalr	258(ra) # 80000c98 <release>
    yield();
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	88c080e7          	jalr	-1908(ra) # 8000242a <yield>
    80002ba6:	bf59                	j	80002b3c <pause_system+0xf4>

0000000080002ba8 <kill_system>:
// depending on usr_dst.
// Returns 0 on success, -1 on error.

int
kill_system(void) 
{
    80002ba8:	7139                	addi	sp,sp,-64
    80002baa:	fc06                	sd	ra,56(sp)
    80002bac:	f822                	sd	s0,48(sp)
    80002bae:	f426                	sd	s1,40(sp)
    80002bb0:	f04a                	sd	s2,32(sp)
    80002bb2:	ec4e                	sd	s3,24(sp)
    80002bb4:	e852                	sd	s4,16(sp)
    80002bb6:	e456                	sd	s5,8(sp)
    80002bb8:	e05a                	sd	s6,0(sp)
    80002bba:	0080                	addi	s0,sp,64
  struct proc *p;
  struct proc *myProcess = myproc();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	e1c080e7          	jalr	-484(ra) # 800019d8 <myproc>
    80002bc4:	8b2a                	mv	s6,a0

  for (p = proc; p < &proc[NPROC]; p++) {
    80002bc6:	0000f497          	auipc	s1,0xf
    80002bca:	caa48493          	addi	s1,s1,-854 # 80011870 <proc+0x180>
    80002bce:	00015a17          	auipc	s4,0x15
    80002bd2:	0a2a0a13          	addi	s4,s4,162 # 80017c70 <bcache+0x168>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80002bd6:	00005997          	auipc	s3,0x5
    80002bda:	69a98993          	addi	s3,s3,1690 # 80008270 <digits+0x230>
    80002bde:	00005a97          	auipc	s5,0x5
    80002be2:	69aa8a93          	addi	s5,s5,1690 # 80008278 <digits+0x238>
    80002be6:	a029                	j	80002bf0 <kill_system+0x48>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002be8:	19048493          	addi	s1,s1,400
    80002bec:	03448b63          	beq	s1,s4,80002c22 <kill_system+0x7a>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80002bf0:	85ce                	mv	a1,s3
    80002bf2:	8526                	mv	a0,s1
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	0ca080e7          	jalr	202(ra) # 80001cbe <str_compare>
    80002bfc:	d575                	beqz	a0,80002be8 <kill_system+0x40>
    80002bfe:	85d6                	mv	a1,s5
    80002c00:	8526                	mv	a0,s1
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	0bc080e7          	jalr	188(ra) # 80001cbe <str_compare>
    80002c0a:	dd79                	beqz	a0,80002be8 <kill_system+0x40>
      if (p != myProcess) {
    80002c0c:	e8048793          	addi	a5,s1,-384
    80002c10:	fcfb0ce3          	beq	s6,a5,80002be8 <kill_system+0x40>
        kill(p->pid);      
    80002c14:	eb04a503          	lw	a0,-336(s1)
    80002c18:	00000097          	auipc	ra,0x0
    80002c1c:	cec080e7          	jalr	-788(ra) # 80002904 <kill>
    80002c20:	b7e1                	j	80002be8 <kill_system+0x40>
      }
    }
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    80002c22:	180b0493          	addi	s1,s6,384
    80002c26:	00005597          	auipc	a1,0x5
    80002c2a:	64a58593          	addi	a1,a1,1610 # 80008270 <digits+0x230>
    80002c2e:	8526                	mv	a0,s1
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	08e080e7          	jalr	142(ra) # 80001cbe <str_compare>
    80002c38:	ed01                	bnez	a0,80002c50 <kill_system+0xa8>
    kill(myProcess->pid);
  }
  return 0;
}
    80002c3a:	4501                	li	a0,0
    80002c3c:	70e2                	ld	ra,56(sp)
    80002c3e:	7442                	ld	s0,48(sp)
    80002c40:	74a2                	ld	s1,40(sp)
    80002c42:	7902                	ld	s2,32(sp)
    80002c44:	69e2                	ld	s3,24(sp)
    80002c46:	6a42                	ld	s4,16(sp)
    80002c48:	6aa2                	ld	s5,8(sp)
    80002c4a:	6b02                	ld	s6,0(sp)
    80002c4c:	6121                	addi	sp,sp,64
    80002c4e:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    80002c50:	00005597          	auipc	a1,0x5
    80002c54:	62858593          	addi	a1,a1,1576 # 80008278 <digits+0x238>
    80002c58:	8526                	mv	a0,s1
    80002c5a:	fffff097          	auipc	ra,0xfffff
    80002c5e:	064080e7          	jalr	100(ra) # 80001cbe <str_compare>
    80002c62:	dd61                	beqz	a0,80002c3a <kill_system+0x92>
    kill(myProcess->pid);
    80002c64:	030b2503          	lw	a0,48(s6)
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	c9c080e7          	jalr	-868(ra) # 80002904 <kill>
    80002c70:	b7e9                	j	80002c3a <kill_system+0x92>

0000000080002c72 <either_copyout>:

int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002c72:	7179                	addi	sp,sp,-48
    80002c74:	f406                	sd	ra,40(sp)
    80002c76:	f022                	sd	s0,32(sp)
    80002c78:	ec26                	sd	s1,24(sp)
    80002c7a:	e84a                	sd	s2,16(sp)
    80002c7c:	e44e                	sd	s3,8(sp)
    80002c7e:	e052                	sd	s4,0(sp)
    80002c80:	1800                	addi	s0,sp,48
    80002c82:	84aa                	mv	s1,a0
    80002c84:	892e                	mv	s2,a1
    80002c86:	89b2                	mv	s3,a2
    80002c88:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	d4e080e7          	jalr	-690(ra) # 800019d8 <myproc>
  if(user_dst){
    80002c92:	c08d                	beqz	s1,80002cb4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002c94:	86d2                	mv	a3,s4
    80002c96:	864e                	mv	a2,s3
    80002c98:	85ca                	mv	a1,s2
    80002c9a:	7d28                	ld	a0,120(a0)
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	9de080e7          	jalr	-1570(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002ca4:	70a2                	ld	ra,40(sp)
    80002ca6:	7402                	ld	s0,32(sp)
    80002ca8:	64e2                	ld	s1,24(sp)
    80002caa:	6942                	ld	s2,16(sp)
    80002cac:	69a2                	ld	s3,8(sp)
    80002cae:	6a02                	ld	s4,0(sp)
    80002cb0:	6145                	addi	sp,sp,48
    80002cb2:	8082                	ret
    memmove((char *)dst, src, len);
    80002cb4:	000a061b          	sext.w	a2,s4
    80002cb8:	85ce                	mv	a1,s3
    80002cba:	854a                	mv	a0,s2
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	084080e7          	jalr	132(ra) # 80000d40 <memmove>
    return 0;
    80002cc4:	8526                	mv	a0,s1
    80002cc6:	bff9                	j	80002ca4 <either_copyout+0x32>

0000000080002cc8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002cc8:	7179                	addi	sp,sp,-48
    80002cca:	f406                	sd	ra,40(sp)
    80002ccc:	f022                	sd	s0,32(sp)
    80002cce:	ec26                	sd	s1,24(sp)
    80002cd0:	e84a                	sd	s2,16(sp)
    80002cd2:	e44e                	sd	s3,8(sp)
    80002cd4:	e052                	sd	s4,0(sp)
    80002cd6:	1800                	addi	s0,sp,48
    80002cd8:	892a                	mv	s2,a0
    80002cda:	84ae                	mv	s1,a1
    80002cdc:	89b2                	mv	s3,a2
    80002cde:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	cf8080e7          	jalr	-776(ra) # 800019d8 <myproc>
  if(user_src){
    80002ce8:	c08d                	beqz	s1,80002d0a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002cea:	86d2                	mv	a3,s4
    80002cec:	864e                	mv	a2,s3
    80002cee:	85ca                	mv	a1,s2
    80002cf0:	7d28                	ld	a0,120(a0)
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	a14080e7          	jalr	-1516(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002cfa:	70a2                	ld	ra,40(sp)
    80002cfc:	7402                	ld	s0,32(sp)
    80002cfe:	64e2                	ld	s1,24(sp)
    80002d00:	6942                	ld	s2,16(sp)
    80002d02:	69a2                	ld	s3,8(sp)
    80002d04:	6a02                	ld	s4,0(sp)
    80002d06:	6145                	addi	sp,sp,48
    80002d08:	8082                	ret
    memmove(dst, (char*)src, len);
    80002d0a:	000a061b          	sext.w	a2,s4
    80002d0e:	85ce                	mv	a1,s3
    80002d10:	854a                	mv	a0,s2
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	02e080e7          	jalr	46(ra) # 80000d40 <memmove>
    return 0;
    80002d1a:	8526                	mv	a0,s1
    80002d1c:	bff9                	j	80002cfa <either_copyin+0x32>

0000000080002d1e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002d1e:	715d                	addi	sp,sp,-80
    80002d20:	e486                	sd	ra,72(sp)
    80002d22:	e0a2                	sd	s0,64(sp)
    80002d24:	fc26                	sd	s1,56(sp)
    80002d26:	f84a                	sd	s2,48(sp)
    80002d28:	f44e                	sd	s3,40(sp)
    80002d2a:	f052                	sd	s4,32(sp)
    80002d2c:	ec56                	sd	s5,24(sp)
    80002d2e:	e85a                	sd	s6,16(sp)
    80002d30:	e45e                	sd	s7,8(sp)
    80002d32:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002d34:	00005517          	auipc	a0,0x5
    80002d38:	5cc50513          	addi	a0,a0,1484 # 80008300 <digits+0x2c0>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	84c080e7          	jalr	-1972(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d44:	0000f497          	auipc	s1,0xf
    80002d48:	b2c48493          	addi	s1,s1,-1236 # 80011870 <proc+0x180>
    80002d4c:	00015917          	auipc	s2,0x15
    80002d50:	f2490913          	addi	s2,s2,-220 # 80017c70 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d54:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002d56:	00005997          	auipc	s3,0x5
    80002d5a:	5da98993          	addi	s3,s3,1498 # 80008330 <digits+0x2f0>
    printf("%d %s %s", p->pid, state, p->name);
    80002d5e:	00005a97          	auipc	s5,0x5
    80002d62:	5daa8a93          	addi	s5,s5,1498 # 80008338 <digits+0x2f8>
    printf("\n");
    80002d66:	00005a17          	auipc	s4,0x5
    80002d6a:	59aa0a13          	addi	s4,s4,1434 # 80008300 <digits+0x2c0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d6e:	00005b97          	auipc	s7,0x5
    80002d72:	602b8b93          	addi	s7,s7,1538 # 80008370 <states.1814>
    80002d76:	a00d                	j	80002d98 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002d78:	eb06a583          	lw	a1,-336(a3)
    80002d7c:	8556                	mv	a0,s5
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	80a080e7          	jalr	-2038(ra) # 80000588 <printf>
    printf("\n");
    80002d86:	8552                	mv	a0,s4
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	800080e7          	jalr	-2048(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d90:	19048493          	addi	s1,s1,400
    80002d94:	03248163          	beq	s1,s2,80002db6 <procdump+0x98>
    if(p->state == UNUSED)
    80002d98:	86a6                	mv	a3,s1
    80002d9a:	e984a783          	lw	a5,-360(s1)
    80002d9e:	dbed                	beqz	a5,80002d90 <procdump+0x72>
      state = "???";
    80002da0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002da2:	fcfb6be3          	bltu	s6,a5,80002d78 <procdump+0x5a>
    80002da6:	1782                	slli	a5,a5,0x20
    80002da8:	9381                	srli	a5,a5,0x20
    80002daa:	078e                	slli	a5,a5,0x3
    80002dac:	97de                	add	a5,a5,s7
    80002dae:	6390                	ld	a2,0(a5)
    80002db0:	f661                	bnez	a2,80002d78 <procdump+0x5a>
      state = "???";
    80002db2:	864e                	mv	a2,s3
    80002db4:	b7d1                	j	80002d78 <procdump+0x5a>
  }
}
    80002db6:	60a6                	ld	ra,72(sp)
    80002db8:	6406                	ld	s0,64(sp)
    80002dba:	74e2                	ld	s1,56(sp)
    80002dbc:	7942                	ld	s2,48(sp)
    80002dbe:	79a2                	ld	s3,40(sp)
    80002dc0:	7a02                	ld	s4,32(sp)
    80002dc2:	6ae2                	ld	s5,24(sp)
    80002dc4:	6b42                	ld	s6,16(sp)
    80002dc6:	6ba2                	ld	s7,8(sp)
    80002dc8:	6161                	addi	sp,sp,80
    80002dca:	8082                	ret

0000000080002dcc <swtch>:
    80002dcc:	00153023          	sd	ra,0(a0)
    80002dd0:	00253423          	sd	sp,8(a0)
    80002dd4:	e900                	sd	s0,16(a0)
    80002dd6:	ed04                	sd	s1,24(a0)
    80002dd8:	03253023          	sd	s2,32(a0)
    80002ddc:	03353423          	sd	s3,40(a0)
    80002de0:	03453823          	sd	s4,48(a0)
    80002de4:	03553c23          	sd	s5,56(a0)
    80002de8:	05653023          	sd	s6,64(a0)
    80002dec:	05753423          	sd	s7,72(a0)
    80002df0:	05853823          	sd	s8,80(a0)
    80002df4:	05953c23          	sd	s9,88(a0)
    80002df8:	07a53023          	sd	s10,96(a0)
    80002dfc:	07b53423          	sd	s11,104(a0)
    80002e00:	0005b083          	ld	ra,0(a1)
    80002e04:	0085b103          	ld	sp,8(a1)
    80002e08:	6980                	ld	s0,16(a1)
    80002e0a:	6d84                	ld	s1,24(a1)
    80002e0c:	0205b903          	ld	s2,32(a1)
    80002e10:	0285b983          	ld	s3,40(a1)
    80002e14:	0305ba03          	ld	s4,48(a1)
    80002e18:	0385ba83          	ld	s5,56(a1)
    80002e1c:	0405bb03          	ld	s6,64(a1)
    80002e20:	0485bb83          	ld	s7,72(a1)
    80002e24:	0505bc03          	ld	s8,80(a1)
    80002e28:	0585bc83          	ld	s9,88(a1)
    80002e2c:	0605bd03          	ld	s10,96(a1)
    80002e30:	0685bd83          	ld	s11,104(a1)
    80002e34:	8082                	ret

0000000080002e36 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002e36:	1141                	addi	sp,sp,-16
    80002e38:	e406                	sd	ra,8(sp)
    80002e3a:	e022                	sd	s0,0(sp)
    80002e3c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e3e:	00005597          	auipc	a1,0x5
    80002e42:	56258593          	addi	a1,a1,1378 # 800083a0 <states.1814+0x30>
    80002e46:	00015517          	auipc	a0,0x15
    80002e4a:	caa50513          	addi	a0,a0,-854 # 80017af0 <tickslock>
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	d06080e7          	jalr	-762(ra) # 80000b54 <initlock>
}
    80002e56:	60a2                	ld	ra,8(sp)
    80002e58:	6402                	ld	s0,0(sp)
    80002e5a:	0141                	addi	sp,sp,16
    80002e5c:	8082                	ret

0000000080002e5e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e5e:	1141                	addi	sp,sp,-16
    80002e60:	e422                	sd	s0,8(sp)
    80002e62:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e64:	00003797          	auipc	a5,0x3
    80002e68:	53c78793          	addi	a5,a5,1340 # 800063a0 <kernelvec>
    80002e6c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e70:	6422                	ld	s0,8(sp)
    80002e72:	0141                	addi	sp,sp,16
    80002e74:	8082                	ret

0000000080002e76 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e76:	1141                	addi	sp,sp,-16
    80002e78:	e406                	sd	ra,8(sp)
    80002e7a:	e022                	sd	s0,0(sp)
    80002e7c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	b5a080e7          	jalr	-1190(ra) # 800019d8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e8a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e8c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e90:	00004617          	auipc	a2,0x4
    80002e94:	17060613          	addi	a2,a2,368 # 80007000 <_trampoline>
    80002e98:	00004697          	auipc	a3,0x4
    80002e9c:	16868693          	addi	a3,a3,360 # 80007000 <_trampoline>
    80002ea0:	8e91                	sub	a3,a3,a2
    80002ea2:	040007b7          	lui	a5,0x4000
    80002ea6:	17fd                	addi	a5,a5,-1
    80002ea8:	07b2                	slli	a5,a5,0xc
    80002eaa:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002eac:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002eb0:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002eb2:	180026f3          	csrr	a3,satp
    80002eb6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002eb8:	6158                	ld	a4,128(a0)
    80002eba:	7534                	ld	a3,104(a0)
    80002ebc:	6585                	lui	a1,0x1
    80002ebe:	96ae                	add	a3,a3,a1
    80002ec0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ec2:	6158                	ld	a4,128(a0)
    80002ec4:	00000697          	auipc	a3,0x0
    80002ec8:	13868693          	addi	a3,a3,312 # 80002ffc <usertrap>
    80002ecc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ece:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ed0:	8692                	mv	a3,tp
    80002ed2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ed4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ed8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002edc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ee0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ee4:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ee6:	6f18                	ld	a4,24(a4)
    80002ee8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002eec:	7d2c                	ld	a1,120(a0)
    80002eee:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ef0:	00004717          	auipc	a4,0x4
    80002ef4:	1a070713          	addi	a4,a4,416 # 80007090 <userret>
    80002ef8:	8f11                	sub	a4,a4,a2
    80002efa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002efc:	577d                	li	a4,-1
    80002efe:	177e                	slli	a4,a4,0x3f
    80002f00:	8dd9                	or	a1,a1,a4
    80002f02:	02000537          	lui	a0,0x2000
    80002f06:	157d                	addi	a0,a0,-1
    80002f08:	0536                	slli	a0,a0,0xd
    80002f0a:	9782                	jalr	a5
}
    80002f0c:	60a2                	ld	ra,8(sp)
    80002f0e:	6402                	ld	s0,0(sp)
    80002f10:	0141                	addi	sp,sp,16
    80002f12:	8082                	ret

0000000080002f14 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002f14:	1101                	addi	sp,sp,-32
    80002f16:	ec06                	sd	ra,24(sp)
    80002f18:	e822                	sd	s0,16(sp)
    80002f1a:	e426                	sd	s1,8(sp)
    80002f1c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002f1e:	00015497          	auipc	s1,0x15
    80002f22:	bd248493          	addi	s1,s1,-1070 # 80017af0 <tickslock>
    80002f26:	8526                	mv	a0,s1
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	cbc080e7          	jalr	-836(ra) # 80000be4 <acquire>
  ticks++;
    80002f30:	00006517          	auipc	a0,0x6
    80002f34:	12450513          	addi	a0,a0,292 # 80009054 <ticks>
    80002f38:	411c                	lw	a5,0(a0)
    80002f3a:	2785                	addiw	a5,a5,1
    80002f3c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	72a080e7          	jalr	1834(ra) # 80002668 <wakeup>
  release(&tickslock);
    80002f46:	8526                	mv	a0,s1
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	d50080e7          	jalr	-688(ra) # 80000c98 <release>
}
    80002f50:	60e2                	ld	ra,24(sp)
    80002f52:	6442                	ld	s0,16(sp)
    80002f54:	64a2                	ld	s1,8(sp)
    80002f56:	6105                	addi	sp,sp,32
    80002f58:	8082                	ret

0000000080002f5a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002f5a:	1101                	addi	sp,sp,-32
    80002f5c:	ec06                	sd	ra,24(sp)
    80002f5e:	e822                	sd	s0,16(sp)
    80002f60:	e426                	sd	s1,8(sp)
    80002f62:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f64:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f68:	00074d63          	bltz	a4,80002f82 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f6c:	57fd                	li	a5,-1
    80002f6e:	17fe                	slli	a5,a5,0x3f
    80002f70:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f72:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f74:	06f70363          	beq	a4,a5,80002fda <devintr+0x80>
  }
}
    80002f78:	60e2                	ld	ra,24(sp)
    80002f7a:	6442                	ld	s0,16(sp)
    80002f7c:	64a2                	ld	s1,8(sp)
    80002f7e:	6105                	addi	sp,sp,32
    80002f80:	8082                	ret
     (scause & 0xff) == 9){
    80002f82:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f86:	46a5                	li	a3,9
    80002f88:	fed792e3          	bne	a5,a3,80002f6c <devintr+0x12>
    int irq = plic_claim();
    80002f8c:	00003097          	auipc	ra,0x3
    80002f90:	51c080e7          	jalr	1308(ra) # 800064a8 <plic_claim>
    80002f94:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f96:	47a9                	li	a5,10
    80002f98:	02f50763          	beq	a0,a5,80002fc6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f9c:	4785                	li	a5,1
    80002f9e:	02f50963          	beq	a0,a5,80002fd0 <devintr+0x76>
    return 1;
    80002fa2:	4505                	li	a0,1
    } else if(irq){
    80002fa4:	d8f1                	beqz	s1,80002f78 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002fa6:	85a6                	mv	a1,s1
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	40050513          	addi	a0,a0,1024 # 800083a8 <states.1814+0x38>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	5d8080e7          	jalr	1496(ra) # 80000588 <printf>
      plic_complete(irq);
    80002fb8:	8526                	mv	a0,s1
    80002fba:	00003097          	auipc	ra,0x3
    80002fbe:	512080e7          	jalr	1298(ra) # 800064cc <plic_complete>
    return 1;
    80002fc2:	4505                	li	a0,1
    80002fc4:	bf55                	j	80002f78 <devintr+0x1e>
      uartintr();
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	9e2080e7          	jalr	-1566(ra) # 800009a8 <uartintr>
    80002fce:	b7ed                	j	80002fb8 <devintr+0x5e>
      virtio_disk_intr();
    80002fd0:	00004097          	auipc	ra,0x4
    80002fd4:	9dc080e7          	jalr	-1572(ra) # 800069ac <virtio_disk_intr>
    80002fd8:	b7c5                	j	80002fb8 <devintr+0x5e>
    if(cpuid() == 0){
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	9d2080e7          	jalr	-1582(ra) # 800019ac <cpuid>
    80002fe2:	c901                	beqz	a0,80002ff2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002fe4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002fe8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002fea:	14479073          	csrw	sip,a5
    return 2;
    80002fee:	4509                	li	a0,2
    80002ff0:	b761                	j	80002f78 <devintr+0x1e>
      clockintr();
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	f22080e7          	jalr	-222(ra) # 80002f14 <clockintr>
    80002ffa:	b7ed                	j	80002fe4 <devintr+0x8a>

0000000080002ffc <usertrap>:
{
    80002ffc:	1101                	addi	sp,sp,-32
    80002ffe:	ec06                	sd	ra,24(sp)
    80003000:	e822                	sd	s0,16(sp)
    80003002:	e426                	sd	s1,8(sp)
    80003004:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003006:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000300a:	1007f793          	andi	a5,a5,256
    8000300e:	e3a5                	bnez	a5,8000306e <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003010:	00003797          	auipc	a5,0x3
    80003014:	39078793          	addi	a5,a5,912 # 800063a0 <kernelvec>
    80003018:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	9bc080e7          	jalr	-1604(ra) # 800019d8 <myproc>
    80003024:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003026:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003028:	14102773          	csrr	a4,sepc
    8000302c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000302e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003032:	47a1                	li	a5,8
    80003034:	04f71b63          	bne	a4,a5,8000308a <usertrap+0x8e>
    if(p->killed)
    80003038:	551c                	lw	a5,40(a0)
    8000303a:	e3b1                	bnez	a5,8000307e <usertrap+0x82>
    p->trapframe->epc += 4;
    8000303c:	60d8                	ld	a4,128(s1)
    8000303e:	6f1c                	ld	a5,24(a4)
    80003040:	0791                	addi	a5,a5,4
    80003042:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003044:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003048:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000304c:	10079073          	csrw	sstatus,a5
    syscall();
    80003050:	00000097          	auipc	ra,0x0
    80003054:	2f0080e7          	jalr	752(ra) # 80003340 <syscall>
  if(p->killed)
    80003058:	549c                	lw	a5,40(s1)
    8000305a:	e7b5                	bnez	a5,800030c6 <usertrap+0xca>
  usertrapret();
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	e1a080e7          	jalr	-486(ra) # 80002e76 <usertrapret>
}
    80003064:	60e2                	ld	ra,24(sp)
    80003066:	6442                	ld	s0,16(sp)
    80003068:	64a2                	ld	s1,8(sp)
    8000306a:	6105                	addi	sp,sp,32
    8000306c:	8082                	ret
    panic("usertrap: not from user mode");
    8000306e:	00005517          	auipc	a0,0x5
    80003072:	35a50513          	addi	a0,a0,858 # 800083c8 <states.1814+0x58>
    80003076:	ffffd097          	auipc	ra,0xffffd
    8000307a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>
      exit(-1);
    8000307e:	557d                	li	a0,-1
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	6d4080e7          	jalr	1748(ra) # 80002754 <exit>
    80003088:	bf55                	j	8000303c <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	ed0080e7          	jalr	-304(ra) # 80002f5a <devintr>
    80003092:	f179                	bnez	a0,80003058 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003094:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003098:	5890                	lw	a2,48(s1)
    8000309a:	00005517          	auipc	a0,0x5
    8000309e:	34e50513          	addi	a0,a0,846 # 800083e8 <states.1814+0x78>
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	4e6080e7          	jalr	1254(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030aa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030ae:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030b2:	00005517          	auipc	a0,0x5
    800030b6:	36650513          	addi	a0,a0,870 # 80008418 <states.1814+0xa8>
    800030ba:	ffffd097          	auipc	ra,0xffffd
    800030be:	4ce080e7          	jalr	1230(ra) # 80000588 <printf>
    p->killed = 1;
    800030c2:	4785                	li	a5,1
    800030c4:	d49c                	sw	a5,40(s1)
    exit(-1);
    800030c6:	557d                	li	a0,-1
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	68c080e7          	jalr	1676(ra) # 80002754 <exit>
    800030d0:	b771                	j	8000305c <usertrap+0x60>

00000000800030d2 <kerneltrap>:
{
    800030d2:	7179                	addi	sp,sp,-48
    800030d4:	f406                	sd	ra,40(sp)
    800030d6:	f022                	sd	s0,32(sp)
    800030d8:	ec26                	sd	s1,24(sp)
    800030da:	e84a                	sd	s2,16(sp)
    800030dc:	e44e                	sd	s3,8(sp)
    800030de:	e052                	sd	s4,0(sp)
    800030e0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030e2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030e6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030ea:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0){
    800030ee:	1004f793          	andi	a5,s1,256
    800030f2:	cb8d                	beqz	a5,80003124 <kerneltrap+0x52>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030f8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800030fa:	ef8d                	bnez	a5,80003134 <kerneltrap+0x62>
  if((which_dev = devintr()) == 0){
    800030fc:	00000097          	auipc	ra,0x0
    80003100:	e5e080e7          	jalr	-418(ra) # 80002f5a <devintr>
    80003104:	c121                	beqz	a0,80003144 <kerneltrap+0x72>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003106:	4789                	li	a5,2
    80003108:	06f50b63          	beq	a0,a5,8000317e <kerneltrap+0xac>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000310c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003110:	10049073          	csrw	sstatus,s1
}
    80003114:	70a2                	ld	ra,40(sp)
    80003116:	7402                	ld	s0,32(sp)
    80003118:	64e2                	ld	s1,24(sp)
    8000311a:	6942                	ld	s2,16(sp)
    8000311c:	69a2                	ld	s3,8(sp)
    8000311e:	6a02                	ld	s4,0(sp)
    80003120:	6145                	addi	sp,sp,48
    80003122:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003124:	00005517          	auipc	a0,0x5
    80003128:	31450513          	addi	a0,a0,788 # 80008438 <states.1814+0xc8>
    8000312c:	ffffd097          	auipc	ra,0xffffd
    80003130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003134:	00005517          	auipc	a0,0x5
    80003138:	32c50513          	addi	a0,a0,812 # 80008460 <states.1814+0xf0>
    8000313c:	ffffd097          	auipc	ra,0xffffd
    80003140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003144:	85ce                	mv	a1,s3
    80003146:	00005517          	auipc	a0,0x5
    8000314a:	33a50513          	addi	a0,a0,826 # 80008480 <states.1814+0x110>
    8000314e:	ffffd097          	auipc	ra,0xffffd
    80003152:	43a080e7          	jalr	1082(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003156:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000315a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000315e:	00005517          	auipc	a0,0x5
    80003162:	33250513          	addi	a0,a0,818 # 80008490 <states.1814+0x120>
    80003166:	ffffd097          	auipc	ra,0xffffd
    8000316a:	422080e7          	jalr	1058(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000316e:	00005517          	auipc	a0,0x5
    80003172:	33a50513          	addi	a0,a0,826 # 800084a8 <states.1814+0x138>
    80003176:	ffffd097          	auipc	ra,0xffffd
    8000317a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	85a080e7          	jalr	-1958(ra) # 800019d8 <myproc>
    80003186:	d159                	beqz	a0,8000310c <kerneltrap+0x3a>
    80003188:	fffff097          	auipc	ra,0xfffff
    8000318c:	850080e7          	jalr	-1968(ra) # 800019d8 <myproc>
    80003190:	4d18                	lw	a4,24(a0)
    80003192:	4791                	li	a5,4
    80003194:	f6f71ce3          	bne	a4,a5,8000310c <kerneltrap+0x3a>
    myproc()->running_time += ticks - myproc()->start_running_time;
    80003198:	00006a17          	auipc	s4,0x6
    8000319c:	ebca2a03          	lw	s4,-324(s4) # 80009054 <ticks>
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	838080e7          	jalr	-1992(ra) # 800019d8 <myproc>
    800031a8:	05052983          	lw	s3,80(a0)
    800031ac:	fffff097          	auipc	ra,0xfffff
    800031b0:	82c080e7          	jalr	-2004(ra) # 800019d8 <myproc>
    800031b4:	417c                	lw	a5,68(a0)
    800031b6:	014787bb          	addw	a5,a5,s4
    800031ba:	413787bb          	subw	a5,a5,s3
    800031be:	c17c                	sw	a5,68(a0)
    yield();
    800031c0:	fffff097          	auipc	ra,0xfffff
    800031c4:	26a080e7          	jalr	618(ra) # 8000242a <yield>
    800031c8:	b791                	j	8000310c <kerneltrap+0x3a>

00000000800031ca <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800031ca:	1101                	addi	sp,sp,-32
    800031cc:	ec06                	sd	ra,24(sp)
    800031ce:	e822                	sd	s0,16(sp)
    800031d0:	e426                	sd	s1,8(sp)
    800031d2:	1000                	addi	s0,sp,32
    800031d4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800031d6:	fffff097          	auipc	ra,0xfffff
    800031da:	802080e7          	jalr	-2046(ra) # 800019d8 <myproc>
  switch (n) {
    800031de:	4795                	li	a5,5
    800031e0:	0497e163          	bltu	a5,s1,80003222 <argraw+0x58>
    800031e4:	048a                	slli	s1,s1,0x2
    800031e6:	00005717          	auipc	a4,0x5
    800031ea:	2fa70713          	addi	a4,a4,762 # 800084e0 <states.1814+0x170>
    800031ee:	94ba                	add	s1,s1,a4
    800031f0:	409c                	lw	a5,0(s1)
    800031f2:	97ba                	add	a5,a5,a4
    800031f4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800031f6:	615c                	ld	a5,128(a0)
    800031f8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031fa:	60e2                	ld	ra,24(sp)
    800031fc:	6442                	ld	s0,16(sp)
    800031fe:	64a2                	ld	s1,8(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret
    return p->trapframe->a1;
    80003204:	615c                	ld	a5,128(a0)
    80003206:	7fa8                	ld	a0,120(a5)
    80003208:	bfcd                	j	800031fa <argraw+0x30>
    return p->trapframe->a2;
    8000320a:	615c                	ld	a5,128(a0)
    8000320c:	63c8                	ld	a0,128(a5)
    8000320e:	b7f5                	j	800031fa <argraw+0x30>
    return p->trapframe->a3;
    80003210:	615c                	ld	a5,128(a0)
    80003212:	67c8                	ld	a0,136(a5)
    80003214:	b7dd                	j	800031fa <argraw+0x30>
    return p->trapframe->a4;
    80003216:	615c                	ld	a5,128(a0)
    80003218:	6bc8                	ld	a0,144(a5)
    8000321a:	b7c5                	j	800031fa <argraw+0x30>
    return p->trapframe->a5;
    8000321c:	615c                	ld	a5,128(a0)
    8000321e:	6fc8                	ld	a0,152(a5)
    80003220:	bfe9                	j	800031fa <argraw+0x30>
  panic("argraw");
    80003222:	00005517          	auipc	a0,0x5
    80003226:	29650513          	addi	a0,a0,662 # 800084b8 <states.1814+0x148>
    8000322a:	ffffd097          	auipc	ra,0xffffd
    8000322e:	314080e7          	jalr	788(ra) # 8000053e <panic>

0000000080003232 <fetchaddr>:
{
    80003232:	1101                	addi	sp,sp,-32
    80003234:	ec06                	sd	ra,24(sp)
    80003236:	e822                	sd	s0,16(sp)
    80003238:	e426                	sd	s1,8(sp)
    8000323a:	e04a                	sd	s2,0(sp)
    8000323c:	1000                	addi	s0,sp,32
    8000323e:	84aa                	mv	s1,a0
    80003240:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	796080e7          	jalr	1942(ra) # 800019d8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000324a:	793c                	ld	a5,112(a0)
    8000324c:	02f4f863          	bgeu	s1,a5,8000327c <fetchaddr+0x4a>
    80003250:	00848713          	addi	a4,s1,8
    80003254:	02e7e663          	bltu	a5,a4,80003280 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003258:	46a1                	li	a3,8
    8000325a:	8626                	mv	a2,s1
    8000325c:	85ca                	mv	a1,s2
    8000325e:	7d28                	ld	a0,120(a0)
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	4a6080e7          	jalr	1190(ra) # 80001706 <copyin>
    80003268:	00a03533          	snez	a0,a0
    8000326c:	40a00533          	neg	a0,a0
}
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	64a2                	ld	s1,8(sp)
    80003276:	6902                	ld	s2,0(sp)
    80003278:	6105                	addi	sp,sp,32
    8000327a:	8082                	ret
    return -1;
    8000327c:	557d                	li	a0,-1
    8000327e:	bfcd                	j	80003270 <fetchaddr+0x3e>
    80003280:	557d                	li	a0,-1
    80003282:	b7fd                	j	80003270 <fetchaddr+0x3e>

0000000080003284 <fetchstr>:
{
    80003284:	7179                	addi	sp,sp,-48
    80003286:	f406                	sd	ra,40(sp)
    80003288:	f022                	sd	s0,32(sp)
    8000328a:	ec26                	sd	s1,24(sp)
    8000328c:	e84a                	sd	s2,16(sp)
    8000328e:	e44e                	sd	s3,8(sp)
    80003290:	1800                	addi	s0,sp,48
    80003292:	892a                	mv	s2,a0
    80003294:	84ae                	mv	s1,a1
    80003296:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	740080e7          	jalr	1856(ra) # 800019d8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800032a0:	86ce                	mv	a3,s3
    800032a2:	864a                	mv	a2,s2
    800032a4:	85a6                	mv	a1,s1
    800032a6:	7d28                	ld	a0,120(a0)
    800032a8:	ffffe097          	auipc	ra,0xffffe
    800032ac:	4ea080e7          	jalr	1258(ra) # 80001792 <copyinstr>
  if(err < 0)
    800032b0:	00054763          	bltz	a0,800032be <fetchstr+0x3a>
  return strlen(buf);
    800032b4:	8526                	mv	a0,s1
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	bae080e7          	jalr	-1106(ra) # 80000e64 <strlen>
}
    800032be:	70a2                	ld	ra,40(sp)
    800032c0:	7402                	ld	s0,32(sp)
    800032c2:	64e2                	ld	s1,24(sp)
    800032c4:	6942                	ld	s2,16(sp)
    800032c6:	69a2                	ld	s3,8(sp)
    800032c8:	6145                	addi	sp,sp,48
    800032ca:	8082                	ret

00000000800032cc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800032cc:	1101                	addi	sp,sp,-32
    800032ce:	ec06                	sd	ra,24(sp)
    800032d0:	e822                	sd	s0,16(sp)
    800032d2:	e426                	sd	s1,8(sp)
    800032d4:	1000                	addi	s0,sp,32
    800032d6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	ef2080e7          	jalr	-270(ra) # 800031ca <argraw>
    800032e0:	c088                	sw	a0,0(s1)
  return 0;
}
    800032e2:	4501                	li	a0,0
    800032e4:	60e2                	ld	ra,24(sp)
    800032e6:	6442                	ld	s0,16(sp)
    800032e8:	64a2                	ld	s1,8(sp)
    800032ea:	6105                	addi	sp,sp,32
    800032ec:	8082                	ret

00000000800032ee <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800032ee:	1101                	addi	sp,sp,-32
    800032f0:	ec06                	sd	ra,24(sp)
    800032f2:	e822                	sd	s0,16(sp)
    800032f4:	e426                	sd	s1,8(sp)
    800032f6:	1000                	addi	s0,sp,32
    800032f8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	ed0080e7          	jalr	-304(ra) # 800031ca <argraw>
    80003302:	e088                	sd	a0,0(s1)
  return 0;
}
    80003304:	4501                	li	a0,0
    80003306:	60e2                	ld	ra,24(sp)
    80003308:	6442                	ld	s0,16(sp)
    8000330a:	64a2                	ld	s1,8(sp)
    8000330c:	6105                	addi	sp,sp,32
    8000330e:	8082                	ret

0000000080003310 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003310:	1101                	addi	sp,sp,-32
    80003312:	ec06                	sd	ra,24(sp)
    80003314:	e822                	sd	s0,16(sp)
    80003316:	e426                	sd	s1,8(sp)
    80003318:	e04a                	sd	s2,0(sp)
    8000331a:	1000                	addi	s0,sp,32
    8000331c:	84ae                	mv	s1,a1
    8000331e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003320:	00000097          	auipc	ra,0x0
    80003324:	eaa080e7          	jalr	-342(ra) # 800031ca <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003328:	864a                	mv	a2,s2
    8000332a:	85a6                	mv	a1,s1
    8000332c:	00000097          	auipc	ra,0x0
    80003330:	f58080e7          	jalr	-168(ra) # 80003284 <fetchstr>
}
    80003334:	60e2                	ld	ra,24(sp)
    80003336:	6442                	ld	s0,16(sp)
    80003338:	64a2                	ld	s1,8(sp)
    8000333a:	6902                	ld	s2,0(sp)
    8000333c:	6105                	addi	sp,sp,32
    8000333e:	8082                	ret

0000000080003340 <syscall>:
[SYS_set_cpu]       sys_set_cpu,
};

void
syscall(void)
{
    80003340:	1101                	addi	sp,sp,-32
    80003342:	ec06                	sd	ra,24(sp)
    80003344:	e822                	sd	s0,16(sp)
    80003346:	e426                	sd	s1,8(sp)
    80003348:	e04a                	sd	s2,0(sp)
    8000334a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000334c:	ffffe097          	auipc	ra,0xffffe
    80003350:	68c080e7          	jalr	1676(ra) # 800019d8 <myproc>
    80003354:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003356:	08053903          	ld	s2,128(a0)
    8000335a:	0a893783          	ld	a5,168(s2)
    8000335e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003362:	37fd                	addiw	a5,a5,-1
    80003364:	4765                	li	a4,25
    80003366:	00f76f63          	bltu	a4,a5,80003384 <syscall+0x44>
    8000336a:	00369713          	slli	a4,a3,0x3
    8000336e:	00005797          	auipc	a5,0x5
    80003372:	18a78793          	addi	a5,a5,394 # 800084f8 <syscalls>
    80003376:	97ba                	add	a5,a5,a4
    80003378:	639c                	ld	a5,0(a5)
    8000337a:	c789                	beqz	a5,80003384 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000337c:	9782                	jalr	a5
    8000337e:	06a93823          	sd	a0,112(s2)
    80003382:	a839                	j	800033a0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003384:	18048613          	addi	a2,s1,384
    80003388:	588c                	lw	a1,48(s1)
    8000338a:	00005517          	auipc	a0,0x5
    8000338e:	13650513          	addi	a0,a0,310 # 800084c0 <states.1814+0x150>
    80003392:	ffffd097          	auipc	ra,0xffffd
    80003396:	1f6080e7          	jalr	502(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000339a:	60dc                	ld	a5,128(s1)
    8000339c:	577d                	li	a4,-1
    8000339e:	fbb8                	sd	a4,112(a5)
  }
}
    800033a0:	60e2                	ld	ra,24(sp)
    800033a2:	6442                	ld	s0,16(sp)
    800033a4:	64a2                	ld	s1,8(sp)
    800033a6:	6902                	ld	s2,0(sp)
    800033a8:	6105                	addi	sp,sp,32
    800033aa:	8082                	ret

00000000800033ac <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800033ac:	1101                	addi	sp,sp,-32
    800033ae:	ec06                	sd	ra,24(sp)
    800033b0:	e822                	sd	s0,16(sp)
    800033b2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800033b4:	fec40593          	addi	a1,s0,-20
    800033b8:	4501                	li	a0,0
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	f12080e7          	jalr	-238(ra) # 800032cc <argint>
    return -1;
    800033c2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033c4:	00054963          	bltz	a0,800033d6 <sys_exit+0x2a>
  exit(n);
    800033c8:	fec42503          	lw	a0,-20(s0)
    800033cc:	fffff097          	auipc	ra,0xfffff
    800033d0:	388080e7          	jalr	904(ra) # 80002754 <exit>
  return 0;  // not reached
    800033d4:	4781                	li	a5,0
}
    800033d6:	853e                	mv	a0,a5
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	6105                	addi	sp,sp,32
    800033de:	8082                	ret

00000000800033e0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800033e0:	1141                	addi	sp,sp,-16
    800033e2:	e406                	sd	ra,8(sp)
    800033e4:	e022                	sd	s0,0(sp)
    800033e6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	5f0080e7          	jalr	1520(ra) # 800019d8 <myproc>
}
    800033f0:	5908                	lw	a0,48(a0)
    800033f2:	60a2                	ld	ra,8(sp)
    800033f4:	6402                	ld	s0,0(sp)
    800033f6:	0141                	addi	sp,sp,16
    800033f8:	8082                	ret

00000000800033fa <sys_fork>:

uint64
sys_fork(void)
{
    800033fa:	1141                	addi	sp,sp,-16
    800033fc:	e406                	sd	ra,8(sp)
    800033fe:	e022                	sd	s0,0(sp)
    80003400:	0800                	addi	s0,sp,16
  return fork();
    80003402:	fffff097          	auipc	ra,0xfffff
    80003406:	9e4080e7          	jalr	-1564(ra) # 80001de6 <fork>
}
    8000340a:	60a2                	ld	ra,8(sp)
    8000340c:	6402                	ld	s0,0(sp)
    8000340e:	0141                	addi	sp,sp,16
    80003410:	8082                	ret

0000000080003412 <sys_wait>:

uint64
sys_wait(void)
{
    80003412:	1101                	addi	sp,sp,-32
    80003414:	ec06                	sd	ra,24(sp)
    80003416:	e822                	sd	s0,16(sp)
    80003418:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000341a:	fe840593          	addi	a1,s0,-24
    8000341e:	4501                	li	a0,0
    80003420:	00000097          	auipc	ra,0x0
    80003424:	ece080e7          	jalr	-306(ra) # 800032ee <argaddr>
    80003428:	87aa                	mv	a5,a0
    return -1;
    8000342a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000342c:	0007c863          	bltz	a5,8000343c <sys_wait+0x2a>
  return wait(p);
    80003430:	fe843503          	ld	a0,-24(s0)
    80003434:	fffff097          	auipc	ra,0xfffff
    80003438:	0aa080e7          	jalr	170(ra) # 800024de <wait>
}
    8000343c:	60e2                	ld	ra,24(sp)
    8000343e:	6442                	ld	s0,16(sp)
    80003440:	6105                	addi	sp,sp,32
    80003442:	8082                	ret

0000000080003444 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000344e:	fdc40593          	addi	a1,s0,-36
    80003452:	4501                	li	a0,0
    80003454:	00000097          	auipc	ra,0x0
    80003458:	e78080e7          	jalr	-392(ra) # 800032cc <argint>
    8000345c:	87aa                	mv	a5,a0
    return -1;
    8000345e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003460:	0207c063          	bltz	a5,80003480 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003464:	ffffe097          	auipc	ra,0xffffe
    80003468:	574080e7          	jalr	1396(ra) # 800019d8 <myproc>
    8000346c:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    8000346e:	fdc42503          	lw	a0,-36(s0)
    80003472:	fffff097          	auipc	ra,0xfffff
    80003476:	900080e7          	jalr	-1792(ra) # 80001d72 <growproc>
    8000347a:	00054863          	bltz	a0,8000348a <sys_sbrk+0x46>
    return -1;
  return addr;
    8000347e:	8526                	mv	a0,s1
}
    80003480:	70a2                	ld	ra,40(sp)
    80003482:	7402                	ld	s0,32(sp)
    80003484:	64e2                	ld	s1,24(sp)
    80003486:	6145                	addi	sp,sp,48
    80003488:	8082                	ret
    return -1;
    8000348a:	557d                	li	a0,-1
    8000348c:	bfd5                	j	80003480 <sys_sbrk+0x3c>

000000008000348e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000348e:	7139                	addi	sp,sp,-64
    80003490:	fc06                	sd	ra,56(sp)
    80003492:	f822                	sd	s0,48(sp)
    80003494:	f426                	sd	s1,40(sp)
    80003496:	f04a                	sd	s2,32(sp)
    80003498:	ec4e                	sd	s3,24(sp)
    8000349a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000349c:	fcc40593          	addi	a1,s0,-52
    800034a0:	4501                	li	a0,0
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	e2a080e7          	jalr	-470(ra) # 800032cc <argint>
    return -1;
    800034aa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034ac:	06054563          	bltz	a0,80003516 <sys_sleep+0x88>
  acquire(&tickslock);
    800034b0:	00014517          	auipc	a0,0x14
    800034b4:	64050513          	addi	a0,a0,1600 # 80017af0 <tickslock>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	72c080e7          	jalr	1836(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800034c0:	00006917          	auipc	s2,0x6
    800034c4:	b9492903          	lw	s2,-1132(s2) # 80009054 <ticks>
  
  while(ticks - ticks0 < n){
    800034c8:	fcc42783          	lw	a5,-52(s0)
    800034cc:	cf85                	beqz	a5,80003504 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034ce:	00014997          	auipc	s3,0x14
    800034d2:	62298993          	addi	s3,s3,1570 # 80017af0 <tickslock>
    800034d6:	00006497          	auipc	s1,0x6
    800034da:	b7e48493          	addi	s1,s1,-1154 # 80009054 <ticks>
    if(myproc()->killed){
    800034de:	ffffe097          	auipc	ra,0xffffe
    800034e2:	4fa080e7          	jalr	1274(ra) # 800019d8 <myproc>
    800034e6:	551c                	lw	a5,40(a0)
    800034e8:	ef9d                	bnez	a5,80003526 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800034ea:	85ce                	mv	a1,s3
    800034ec:	8526                	mv	a0,s1
    800034ee:	fffff097          	auipc	ra,0xfffff
    800034f2:	f82080e7          	jalr	-126(ra) # 80002470 <sleep>
  while(ticks - ticks0 < n){
    800034f6:	409c                	lw	a5,0(s1)
    800034f8:	412787bb          	subw	a5,a5,s2
    800034fc:	fcc42703          	lw	a4,-52(s0)
    80003500:	fce7efe3          	bltu	a5,a4,800034de <sys_sleep+0x50>
  }
  release(&tickslock);
    80003504:	00014517          	auipc	a0,0x14
    80003508:	5ec50513          	addi	a0,a0,1516 # 80017af0 <tickslock>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	78c080e7          	jalr	1932(ra) # 80000c98 <release>
  return 0;
    80003514:	4781                	li	a5,0
}
    80003516:	853e                	mv	a0,a5
    80003518:	70e2                	ld	ra,56(sp)
    8000351a:	7442                	ld	s0,48(sp)
    8000351c:	74a2                	ld	s1,40(sp)
    8000351e:	7902                	ld	s2,32(sp)
    80003520:	69e2                	ld	s3,24(sp)
    80003522:	6121                	addi	sp,sp,64
    80003524:	8082                	ret
      release(&tickslock);
    80003526:	00014517          	auipc	a0,0x14
    8000352a:	5ca50513          	addi	a0,a0,1482 # 80017af0 <tickslock>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	76a080e7          	jalr	1898(ra) # 80000c98 <release>
      return -1;
    80003536:	57fd                	li	a5,-1
    80003538:	bff9                	j	80003516 <sys_sleep+0x88>

000000008000353a <sys_kill>:

uint64
sys_kill(void)
{
    8000353a:	1101                	addi	sp,sp,-32
    8000353c:	ec06                	sd	ra,24(sp)
    8000353e:	e822                	sd	s0,16(sp)
    80003540:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003542:	fec40593          	addi	a1,s0,-20
    80003546:	4501                	li	a0,0
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	d84080e7          	jalr	-636(ra) # 800032cc <argint>
    80003550:	87aa                	mv	a5,a0
    return -1;
    80003552:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003554:	0007c863          	bltz	a5,80003564 <sys_kill+0x2a>
  return kill(pid);
    80003558:	fec42503          	lw	a0,-20(s0)
    8000355c:	fffff097          	auipc	ra,0xfffff
    80003560:	3a8080e7          	jalr	936(ra) # 80002904 <kill>
}
    80003564:	60e2                	ld	ra,24(sp)
    80003566:	6442                	ld	s0,16(sp)
    80003568:	6105                	addi	sp,sp,32
    8000356a:	8082                	ret

000000008000356c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000356c:	1101                	addi	sp,sp,-32
    8000356e:	ec06                	sd	ra,24(sp)
    80003570:	e822                	sd	s0,16(sp)
    80003572:	e426                	sd	s1,8(sp)
    80003574:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003576:	00014517          	auipc	a0,0x14
    8000357a:	57a50513          	addi	a0,a0,1402 # 80017af0 <tickslock>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	666080e7          	jalr	1638(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003586:	00006497          	auipc	s1,0x6
    8000358a:	ace4a483          	lw	s1,-1330(s1) # 80009054 <ticks>
  release(&tickslock);
    8000358e:	00014517          	auipc	a0,0x14
    80003592:	56250513          	addi	a0,a0,1378 # 80017af0 <tickslock>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	702080e7          	jalr	1794(ra) # 80000c98 <release>
  return xticks;
}
    8000359e:	02049513          	slli	a0,s1,0x20
    800035a2:	9101                	srli	a0,a0,0x20
    800035a4:	60e2                	ld	ra,24(sp)
    800035a6:	6442                	ld	s0,16(sp)
    800035a8:	64a2                	ld	s1,8(sp)
    800035aa:	6105                	addi	sp,sp,32
    800035ac:	8082                	ret

00000000800035ae <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800035ae:	1141                	addi	sp,sp,-16
    800035b0:	e406                	sd	ra,8(sp)
    800035b2:	e022                	sd	s0,0(sp)
    800035b4:	0800                	addi	s0,sp,16
  return print_stats();
    800035b6:	fffff097          	auipc	ra,0xfffff
    800035ba:	3d4080e7          	jalr	980(ra) # 8000298a <print_stats>
}
    800035be:	60a2                	ld	ra,8(sp)
    800035c0:	6402                	ld	s0,0(sp)
    800035c2:	0141                	addi	sp,sp,16
    800035c4:	8082                	ret

00000000800035c6 <sys_get_cpu>:

// Ass2
uint64
sys_get_cpu(void)
{
    800035c6:	1141                	addi	sp,sp,-16
    800035c8:	e406                	sd	ra,8(sp)
    800035ca:	e022                	sd	s0,0(sp)
    800035cc:	0800                	addi	s0,sp,16
  return get_cpu();
    800035ce:	fffff097          	auipc	ra,0xfffff
    800035d2:	46c080e7          	jalr	1132(ra) # 80002a3a <get_cpu>
}
    800035d6:	60a2                	ld	ra,8(sp)
    800035d8:	6402                	ld	s0,0(sp)
    800035da:	0141                	addi	sp,sp,16
    800035dc:	8082                	ret

00000000800035de <sys_set_cpu>:

// Ass2
uint64
sys_set_cpu(void)
{
    800035de:	1101                	addi	sp,sp,-32
    800035e0:	ec06                	sd	ra,24(sp)
    800035e2:	e822                	sd	s0,16(sp)
    800035e4:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    800035e6:	fec40593          	addi	a1,s0,-20
    800035ea:	4501                	li	a0,0
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	ce0080e7          	jalr	-800(ra) # 800032cc <argint>
    800035f4:	87aa                	mv	a5,a0
    return -1;
    800035f6:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800035f8:	0007c863          	bltz	a5,80003608 <sys_set_cpu+0x2a>

  return set_cpu(cpu_num);
    800035fc:	fec42503          	lw	a0,-20(s0)
    80003600:	fffff097          	auipc	ra,0xfffff
    80003604:	42c080e7          	jalr	1068(ra) # 80002a2c <set_cpu>
}
    80003608:	60e2                	ld	ra,24(sp)
    8000360a:	6442                	ld	s0,16(sp)
    8000360c:	6105                	addi	sp,sp,32
    8000360e:	8082                	ret

0000000080003610 <sys_pause_system>:



uint64
sys_pause_system(void)
{
    80003610:	1101                	addi	sp,sp,-32
    80003612:	ec06                	sd	ra,24(sp)
    80003614:	e822                	sd	s0,16(sp)
    80003616:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80003618:	fec40593          	addi	a1,s0,-20
    8000361c:	4501                	li	a0,0
    8000361e:	00000097          	auipc	ra,0x0
    80003622:	cae080e7          	jalr	-850(ra) # 800032cc <argint>
    80003626:	87aa                	mv	a5,a0
    return -1;
    80003628:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    8000362a:	0007c863          	bltz	a5,8000363a <sys_pause_system+0x2a>

  return pause_system(seconds);
    8000362e:	fec42503          	lw	a0,-20(s0)
    80003632:	fffff097          	auipc	ra,0xfffff
    80003636:	416080e7          	jalr	1046(ra) # 80002a48 <pause_system>
}
    8000363a:	60e2                	ld	ra,24(sp)
    8000363c:	6442                	ld	s0,16(sp)
    8000363e:	6105                	addi	sp,sp,32
    80003640:	8082                	ret

0000000080003642 <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80003642:	1141                	addi	sp,sp,-16
    80003644:	e406                	sd	ra,8(sp)
    80003646:	e022                	sd	s0,0(sp)
    80003648:	0800                	addi	s0,sp,16
  return kill_system(); 
    8000364a:	fffff097          	auipc	ra,0xfffff
    8000364e:	55e080e7          	jalr	1374(ra) # 80002ba8 <kill_system>
}
    80003652:	60a2                	ld	ra,8(sp)
    80003654:	6402                	ld	s0,0(sp)
    80003656:	0141                	addi	sp,sp,16
    80003658:	8082                	ret

000000008000365a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000365a:	7179                	addi	sp,sp,-48
    8000365c:	f406                	sd	ra,40(sp)
    8000365e:	f022                	sd	s0,32(sp)
    80003660:	ec26                	sd	s1,24(sp)
    80003662:	e84a                	sd	s2,16(sp)
    80003664:	e44e                	sd	s3,8(sp)
    80003666:	e052                	sd	s4,0(sp)
    80003668:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000366a:	00005597          	auipc	a1,0x5
    8000366e:	f6658593          	addi	a1,a1,-154 # 800085d0 <syscalls+0xd8>
    80003672:	00014517          	auipc	a0,0x14
    80003676:	49650513          	addi	a0,a0,1174 # 80017b08 <bcache>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	4da080e7          	jalr	1242(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003682:	0001c797          	auipc	a5,0x1c
    80003686:	48678793          	addi	a5,a5,1158 # 8001fb08 <bcache+0x8000>
    8000368a:	0001c717          	auipc	a4,0x1c
    8000368e:	6e670713          	addi	a4,a4,1766 # 8001fd70 <bcache+0x8268>
    80003692:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003696:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000369a:	00014497          	auipc	s1,0x14
    8000369e:	48648493          	addi	s1,s1,1158 # 80017b20 <bcache+0x18>
    b->next = bcache.head.next;
    800036a2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036a4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800036a6:	00005a17          	auipc	s4,0x5
    800036aa:	f32a0a13          	addi	s4,s4,-206 # 800085d8 <syscalls+0xe0>
    b->next = bcache.head.next;
    800036ae:	2b893783          	ld	a5,696(s2)
    800036b2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036b4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036b8:	85d2                	mv	a1,s4
    800036ba:	01048513          	addi	a0,s1,16
    800036be:	00001097          	auipc	ra,0x1
    800036c2:	4bc080e7          	jalr	1212(ra) # 80004b7a <initsleeplock>
    bcache.head.next->prev = b;
    800036c6:	2b893783          	ld	a5,696(s2)
    800036ca:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036cc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036d0:	45848493          	addi	s1,s1,1112
    800036d4:	fd349de3          	bne	s1,s3,800036ae <binit+0x54>
  }
}
    800036d8:	70a2                	ld	ra,40(sp)
    800036da:	7402                	ld	s0,32(sp)
    800036dc:	64e2                	ld	s1,24(sp)
    800036de:	6942                	ld	s2,16(sp)
    800036e0:	69a2                	ld	s3,8(sp)
    800036e2:	6a02                	ld	s4,0(sp)
    800036e4:	6145                	addi	sp,sp,48
    800036e6:	8082                	ret

00000000800036e8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036e8:	7179                	addi	sp,sp,-48
    800036ea:	f406                	sd	ra,40(sp)
    800036ec:	f022                	sd	s0,32(sp)
    800036ee:	ec26                	sd	s1,24(sp)
    800036f0:	e84a                	sd	s2,16(sp)
    800036f2:	e44e                	sd	s3,8(sp)
    800036f4:	1800                	addi	s0,sp,48
    800036f6:	89aa                	mv	s3,a0
    800036f8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800036fa:	00014517          	auipc	a0,0x14
    800036fe:	40e50513          	addi	a0,a0,1038 # 80017b08 <bcache>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	4e2080e7          	jalr	1250(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000370a:	0001c497          	auipc	s1,0x1c
    8000370e:	6b64b483          	ld	s1,1718(s1) # 8001fdc0 <bcache+0x82b8>
    80003712:	0001c797          	auipc	a5,0x1c
    80003716:	65e78793          	addi	a5,a5,1630 # 8001fd70 <bcache+0x8268>
    8000371a:	02f48f63          	beq	s1,a5,80003758 <bread+0x70>
    8000371e:	873e                	mv	a4,a5
    80003720:	a021                	j	80003728 <bread+0x40>
    80003722:	68a4                	ld	s1,80(s1)
    80003724:	02e48a63          	beq	s1,a4,80003758 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003728:	449c                	lw	a5,8(s1)
    8000372a:	ff379ce3          	bne	a5,s3,80003722 <bread+0x3a>
    8000372e:	44dc                	lw	a5,12(s1)
    80003730:	ff2799e3          	bne	a5,s2,80003722 <bread+0x3a>
      b->refcnt++;
    80003734:	40bc                	lw	a5,64(s1)
    80003736:	2785                	addiw	a5,a5,1
    80003738:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000373a:	00014517          	auipc	a0,0x14
    8000373e:	3ce50513          	addi	a0,a0,974 # 80017b08 <bcache>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	556080e7          	jalr	1366(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000374a:	01048513          	addi	a0,s1,16
    8000374e:	00001097          	auipc	ra,0x1
    80003752:	466080e7          	jalr	1126(ra) # 80004bb4 <acquiresleep>
      return b;
    80003756:	a8b9                	j	800037b4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003758:	0001c497          	auipc	s1,0x1c
    8000375c:	6604b483          	ld	s1,1632(s1) # 8001fdb8 <bcache+0x82b0>
    80003760:	0001c797          	auipc	a5,0x1c
    80003764:	61078793          	addi	a5,a5,1552 # 8001fd70 <bcache+0x8268>
    80003768:	00f48863          	beq	s1,a5,80003778 <bread+0x90>
    8000376c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000376e:	40bc                	lw	a5,64(s1)
    80003770:	cf81                	beqz	a5,80003788 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003772:	64a4                	ld	s1,72(s1)
    80003774:	fee49de3          	bne	s1,a4,8000376e <bread+0x86>
  panic("bget: no buffers");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	e6850513          	addi	a0,a0,-408 # 800085e0 <syscalls+0xe8>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	dbe080e7          	jalr	-578(ra) # 8000053e <panic>
      b->dev = dev;
    80003788:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000378c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003790:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003794:	4785                	li	a5,1
    80003796:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003798:	00014517          	auipc	a0,0x14
    8000379c:	37050513          	addi	a0,a0,880 # 80017b08 <bcache>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	4f8080e7          	jalr	1272(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800037a8:	01048513          	addi	a0,s1,16
    800037ac:	00001097          	auipc	ra,0x1
    800037b0:	408080e7          	jalr	1032(ra) # 80004bb4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037b4:	409c                	lw	a5,0(s1)
    800037b6:	cb89                	beqz	a5,800037c8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037b8:	8526                	mv	a0,s1
    800037ba:	70a2                	ld	ra,40(sp)
    800037bc:	7402                	ld	s0,32(sp)
    800037be:	64e2                	ld	s1,24(sp)
    800037c0:	6942                	ld	s2,16(sp)
    800037c2:	69a2                	ld	s3,8(sp)
    800037c4:	6145                	addi	sp,sp,48
    800037c6:	8082                	ret
    virtio_disk_rw(b, 0);
    800037c8:	4581                	li	a1,0
    800037ca:	8526                	mv	a0,s1
    800037cc:	00003097          	auipc	ra,0x3
    800037d0:	f0a080e7          	jalr	-246(ra) # 800066d6 <virtio_disk_rw>
    b->valid = 1;
    800037d4:	4785                	li	a5,1
    800037d6:	c09c                	sw	a5,0(s1)
  return b;
    800037d8:	b7c5                	j	800037b8 <bread+0xd0>

00000000800037da <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037da:	1101                	addi	sp,sp,-32
    800037dc:	ec06                	sd	ra,24(sp)
    800037de:	e822                	sd	s0,16(sp)
    800037e0:	e426                	sd	s1,8(sp)
    800037e2:	1000                	addi	s0,sp,32
    800037e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037e6:	0541                	addi	a0,a0,16
    800037e8:	00001097          	auipc	ra,0x1
    800037ec:	466080e7          	jalr	1126(ra) # 80004c4e <holdingsleep>
    800037f0:	cd01                	beqz	a0,80003808 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037f2:	4585                	li	a1,1
    800037f4:	8526                	mv	a0,s1
    800037f6:	00003097          	auipc	ra,0x3
    800037fa:	ee0080e7          	jalr	-288(ra) # 800066d6 <virtio_disk_rw>
}
    800037fe:	60e2                	ld	ra,24(sp)
    80003800:	6442                	ld	s0,16(sp)
    80003802:	64a2                	ld	s1,8(sp)
    80003804:	6105                	addi	sp,sp,32
    80003806:	8082                	ret
    panic("bwrite");
    80003808:	00005517          	auipc	a0,0x5
    8000380c:	df050513          	addi	a0,a0,-528 # 800085f8 <syscalls+0x100>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	d2e080e7          	jalr	-722(ra) # 8000053e <panic>

0000000080003818 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003818:	1101                	addi	sp,sp,-32
    8000381a:	ec06                	sd	ra,24(sp)
    8000381c:	e822                	sd	s0,16(sp)
    8000381e:	e426                	sd	s1,8(sp)
    80003820:	e04a                	sd	s2,0(sp)
    80003822:	1000                	addi	s0,sp,32
    80003824:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003826:	01050913          	addi	s2,a0,16
    8000382a:	854a                	mv	a0,s2
    8000382c:	00001097          	auipc	ra,0x1
    80003830:	422080e7          	jalr	1058(ra) # 80004c4e <holdingsleep>
    80003834:	c92d                	beqz	a0,800038a6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003836:	854a                	mv	a0,s2
    80003838:	00001097          	auipc	ra,0x1
    8000383c:	3d2080e7          	jalr	978(ra) # 80004c0a <releasesleep>

  acquire(&bcache.lock);
    80003840:	00014517          	auipc	a0,0x14
    80003844:	2c850513          	addi	a0,a0,712 # 80017b08 <bcache>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	39c080e7          	jalr	924(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003850:	40bc                	lw	a5,64(s1)
    80003852:	37fd                	addiw	a5,a5,-1
    80003854:	0007871b          	sext.w	a4,a5
    80003858:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000385a:	eb05                	bnez	a4,8000388a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000385c:	68bc                	ld	a5,80(s1)
    8000385e:	64b8                	ld	a4,72(s1)
    80003860:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003862:	64bc                	ld	a5,72(s1)
    80003864:	68b8                	ld	a4,80(s1)
    80003866:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003868:	0001c797          	auipc	a5,0x1c
    8000386c:	2a078793          	addi	a5,a5,672 # 8001fb08 <bcache+0x8000>
    80003870:	2b87b703          	ld	a4,696(a5)
    80003874:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003876:	0001c717          	auipc	a4,0x1c
    8000387a:	4fa70713          	addi	a4,a4,1274 # 8001fd70 <bcache+0x8268>
    8000387e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003880:	2b87b703          	ld	a4,696(a5)
    80003884:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003886:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000388a:	00014517          	auipc	a0,0x14
    8000388e:	27e50513          	addi	a0,a0,638 # 80017b08 <bcache>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
}
    8000389a:	60e2                	ld	ra,24(sp)
    8000389c:	6442                	ld	s0,16(sp)
    8000389e:	64a2                	ld	s1,8(sp)
    800038a0:	6902                	ld	s2,0(sp)
    800038a2:	6105                	addi	sp,sp,32
    800038a4:	8082                	ret
    panic("brelse");
    800038a6:	00005517          	auipc	a0,0x5
    800038aa:	d5a50513          	addi	a0,a0,-678 # 80008600 <syscalls+0x108>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	c90080e7          	jalr	-880(ra) # 8000053e <panic>

00000000800038b6 <bpin>:

void
bpin(struct buf *b) {
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	1000                	addi	s0,sp,32
    800038c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038c2:	00014517          	auipc	a0,0x14
    800038c6:	24650513          	addi	a0,a0,582 # 80017b08 <bcache>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	31a080e7          	jalr	794(ra) # 80000be4 <acquire>
  b->refcnt++;
    800038d2:	40bc                	lw	a5,64(s1)
    800038d4:	2785                	addiw	a5,a5,1
    800038d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038d8:	00014517          	auipc	a0,0x14
    800038dc:	23050513          	addi	a0,a0,560 # 80017b08 <bcache>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	3b8080e7          	jalr	952(ra) # 80000c98 <release>
}
    800038e8:	60e2                	ld	ra,24(sp)
    800038ea:	6442                	ld	s0,16(sp)
    800038ec:	64a2                	ld	s1,8(sp)
    800038ee:	6105                	addi	sp,sp,32
    800038f0:	8082                	ret

00000000800038f2 <bunpin>:

void
bunpin(struct buf *b) {
    800038f2:	1101                	addi	sp,sp,-32
    800038f4:	ec06                	sd	ra,24(sp)
    800038f6:	e822                	sd	s0,16(sp)
    800038f8:	e426                	sd	s1,8(sp)
    800038fa:	1000                	addi	s0,sp,32
    800038fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038fe:	00014517          	auipc	a0,0x14
    80003902:	20a50513          	addi	a0,a0,522 # 80017b08 <bcache>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	2de080e7          	jalr	734(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000390e:	40bc                	lw	a5,64(s1)
    80003910:	37fd                	addiw	a5,a5,-1
    80003912:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003914:	00014517          	auipc	a0,0x14
    80003918:	1f450513          	addi	a0,a0,500 # 80017b08 <bcache>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	37c080e7          	jalr	892(ra) # 80000c98 <release>
}
    80003924:	60e2                	ld	ra,24(sp)
    80003926:	6442                	ld	s0,16(sp)
    80003928:	64a2                	ld	s1,8(sp)
    8000392a:	6105                	addi	sp,sp,32
    8000392c:	8082                	ret

000000008000392e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000392e:	1101                	addi	sp,sp,-32
    80003930:	ec06                	sd	ra,24(sp)
    80003932:	e822                	sd	s0,16(sp)
    80003934:	e426                	sd	s1,8(sp)
    80003936:	e04a                	sd	s2,0(sp)
    80003938:	1000                	addi	s0,sp,32
    8000393a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000393c:	00d5d59b          	srliw	a1,a1,0xd
    80003940:	0001d797          	auipc	a5,0x1d
    80003944:	8a47a783          	lw	a5,-1884(a5) # 800201e4 <sb+0x1c>
    80003948:	9dbd                	addw	a1,a1,a5
    8000394a:	00000097          	auipc	ra,0x0
    8000394e:	d9e080e7          	jalr	-610(ra) # 800036e8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003952:	0074f713          	andi	a4,s1,7
    80003956:	4785                	li	a5,1
    80003958:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000395c:	14ce                	slli	s1,s1,0x33
    8000395e:	90d9                	srli	s1,s1,0x36
    80003960:	00950733          	add	a4,a0,s1
    80003964:	05874703          	lbu	a4,88(a4)
    80003968:	00e7f6b3          	and	a3,a5,a4
    8000396c:	c69d                	beqz	a3,8000399a <bfree+0x6c>
    8000396e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003970:	94aa                	add	s1,s1,a0
    80003972:	fff7c793          	not	a5,a5
    80003976:	8ff9                	and	a5,a5,a4
    80003978:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000397c:	00001097          	auipc	ra,0x1
    80003980:	118080e7          	jalr	280(ra) # 80004a94 <log_write>
  brelse(bp);
    80003984:	854a                	mv	a0,s2
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	e92080e7          	jalr	-366(ra) # 80003818 <brelse>
}
    8000398e:	60e2                	ld	ra,24(sp)
    80003990:	6442                	ld	s0,16(sp)
    80003992:	64a2                	ld	s1,8(sp)
    80003994:	6902                	ld	s2,0(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret
    panic("freeing free block");
    8000399a:	00005517          	auipc	a0,0x5
    8000399e:	c6e50513          	addi	a0,a0,-914 # 80008608 <syscalls+0x110>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	b9c080e7          	jalr	-1124(ra) # 8000053e <panic>

00000000800039aa <balloc>:
{
    800039aa:	711d                	addi	sp,sp,-96
    800039ac:	ec86                	sd	ra,88(sp)
    800039ae:	e8a2                	sd	s0,80(sp)
    800039b0:	e4a6                	sd	s1,72(sp)
    800039b2:	e0ca                	sd	s2,64(sp)
    800039b4:	fc4e                	sd	s3,56(sp)
    800039b6:	f852                	sd	s4,48(sp)
    800039b8:	f456                	sd	s5,40(sp)
    800039ba:	f05a                	sd	s6,32(sp)
    800039bc:	ec5e                	sd	s7,24(sp)
    800039be:	e862                	sd	s8,16(sp)
    800039c0:	e466                	sd	s9,8(sp)
    800039c2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039c4:	0001d797          	auipc	a5,0x1d
    800039c8:	8087a783          	lw	a5,-2040(a5) # 800201cc <sb+0x4>
    800039cc:	cbd1                	beqz	a5,80003a60 <balloc+0xb6>
    800039ce:	8baa                	mv	s7,a0
    800039d0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039d2:	0001cb17          	auipc	s6,0x1c
    800039d6:	7f6b0b13          	addi	s6,s6,2038 # 800201c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039da:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039dc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039de:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039e0:	6c89                	lui	s9,0x2
    800039e2:	a831                	j	800039fe <balloc+0x54>
    brelse(bp);
    800039e4:	854a                	mv	a0,s2
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	e32080e7          	jalr	-462(ra) # 80003818 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039ee:	015c87bb          	addw	a5,s9,s5
    800039f2:	00078a9b          	sext.w	s5,a5
    800039f6:	004b2703          	lw	a4,4(s6)
    800039fa:	06eaf363          	bgeu	s5,a4,80003a60 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800039fe:	41fad79b          	sraiw	a5,s5,0x1f
    80003a02:	0137d79b          	srliw	a5,a5,0x13
    80003a06:	015787bb          	addw	a5,a5,s5
    80003a0a:	40d7d79b          	sraiw	a5,a5,0xd
    80003a0e:	01cb2583          	lw	a1,28(s6)
    80003a12:	9dbd                	addw	a1,a1,a5
    80003a14:	855e                	mv	a0,s7
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	cd2080e7          	jalr	-814(ra) # 800036e8 <bread>
    80003a1e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a20:	004b2503          	lw	a0,4(s6)
    80003a24:	000a849b          	sext.w	s1,s5
    80003a28:	8662                	mv	a2,s8
    80003a2a:	faa4fde3          	bgeu	s1,a0,800039e4 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a2e:	41f6579b          	sraiw	a5,a2,0x1f
    80003a32:	01d7d69b          	srliw	a3,a5,0x1d
    80003a36:	00c6873b          	addw	a4,a3,a2
    80003a3a:	00777793          	andi	a5,a4,7
    80003a3e:	9f95                	subw	a5,a5,a3
    80003a40:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a44:	4037571b          	sraiw	a4,a4,0x3
    80003a48:	00e906b3          	add	a3,s2,a4
    80003a4c:	0586c683          	lbu	a3,88(a3)
    80003a50:	00d7f5b3          	and	a1,a5,a3
    80003a54:	cd91                	beqz	a1,80003a70 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a56:	2605                	addiw	a2,a2,1
    80003a58:	2485                	addiw	s1,s1,1
    80003a5a:	fd4618e3          	bne	a2,s4,80003a2a <balloc+0x80>
    80003a5e:	b759                	j	800039e4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a60:	00005517          	auipc	a0,0x5
    80003a64:	bc050513          	addi	a0,a0,-1088 # 80008620 <syscalls+0x128>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	ad6080e7          	jalr	-1322(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a70:	974a                	add	a4,a4,s2
    80003a72:	8fd5                	or	a5,a5,a3
    80003a74:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a78:	854a                	mv	a0,s2
    80003a7a:	00001097          	auipc	ra,0x1
    80003a7e:	01a080e7          	jalr	26(ra) # 80004a94 <log_write>
        brelse(bp);
    80003a82:	854a                	mv	a0,s2
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	d94080e7          	jalr	-620(ra) # 80003818 <brelse>
  bp = bread(dev, bno);
    80003a8c:	85a6                	mv	a1,s1
    80003a8e:	855e                	mv	a0,s7
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	c58080e7          	jalr	-936(ra) # 800036e8 <bread>
    80003a98:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a9a:	40000613          	li	a2,1024
    80003a9e:	4581                	li	a1,0
    80003aa0:	05850513          	addi	a0,a0,88
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	23c080e7          	jalr	572(ra) # 80000ce0 <memset>
  log_write(bp);
    80003aac:	854a                	mv	a0,s2
    80003aae:	00001097          	auipc	ra,0x1
    80003ab2:	fe6080e7          	jalr	-26(ra) # 80004a94 <log_write>
  brelse(bp);
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	d60080e7          	jalr	-672(ra) # 80003818 <brelse>
}
    80003ac0:	8526                	mv	a0,s1
    80003ac2:	60e6                	ld	ra,88(sp)
    80003ac4:	6446                	ld	s0,80(sp)
    80003ac6:	64a6                	ld	s1,72(sp)
    80003ac8:	6906                	ld	s2,64(sp)
    80003aca:	79e2                	ld	s3,56(sp)
    80003acc:	7a42                	ld	s4,48(sp)
    80003ace:	7aa2                	ld	s5,40(sp)
    80003ad0:	7b02                	ld	s6,32(sp)
    80003ad2:	6be2                	ld	s7,24(sp)
    80003ad4:	6c42                	ld	s8,16(sp)
    80003ad6:	6ca2                	ld	s9,8(sp)
    80003ad8:	6125                	addi	sp,sp,96
    80003ada:	8082                	ret

0000000080003adc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003adc:	7179                	addi	sp,sp,-48
    80003ade:	f406                	sd	ra,40(sp)
    80003ae0:	f022                	sd	s0,32(sp)
    80003ae2:	ec26                	sd	s1,24(sp)
    80003ae4:	e84a                	sd	s2,16(sp)
    80003ae6:	e44e                	sd	s3,8(sp)
    80003ae8:	e052                	sd	s4,0(sp)
    80003aea:	1800                	addi	s0,sp,48
    80003aec:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003aee:	47ad                	li	a5,11
    80003af0:	04b7fe63          	bgeu	a5,a1,80003b4c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003af4:	ff45849b          	addiw	s1,a1,-12
    80003af8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003afc:	0ff00793          	li	a5,255
    80003b00:	0ae7e363          	bltu	a5,a4,80003ba6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b04:	08052583          	lw	a1,128(a0)
    80003b08:	c5ad                	beqz	a1,80003b72 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b0a:	00092503          	lw	a0,0(s2)
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	bda080e7          	jalr	-1062(ra) # 800036e8 <bread>
    80003b16:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b18:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b1c:	02049593          	slli	a1,s1,0x20
    80003b20:	9181                	srli	a1,a1,0x20
    80003b22:	058a                	slli	a1,a1,0x2
    80003b24:	00b784b3          	add	s1,a5,a1
    80003b28:	0004a983          	lw	s3,0(s1)
    80003b2c:	04098d63          	beqz	s3,80003b86 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b30:	8552                	mv	a0,s4
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	ce6080e7          	jalr	-794(ra) # 80003818 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b3a:	854e                	mv	a0,s3
    80003b3c:	70a2                	ld	ra,40(sp)
    80003b3e:	7402                	ld	s0,32(sp)
    80003b40:	64e2                	ld	s1,24(sp)
    80003b42:	6942                	ld	s2,16(sp)
    80003b44:	69a2                	ld	s3,8(sp)
    80003b46:	6a02                	ld	s4,0(sp)
    80003b48:	6145                	addi	sp,sp,48
    80003b4a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b4c:	02059493          	slli	s1,a1,0x20
    80003b50:	9081                	srli	s1,s1,0x20
    80003b52:	048a                	slli	s1,s1,0x2
    80003b54:	94aa                	add	s1,s1,a0
    80003b56:	0504a983          	lw	s3,80(s1)
    80003b5a:	fe0990e3          	bnez	s3,80003b3a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b5e:	4108                	lw	a0,0(a0)
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	e4a080e7          	jalr	-438(ra) # 800039aa <balloc>
    80003b68:	0005099b          	sext.w	s3,a0
    80003b6c:	0534a823          	sw	s3,80(s1)
    80003b70:	b7e9                	j	80003b3a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b72:	4108                	lw	a0,0(a0)
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	e36080e7          	jalr	-458(ra) # 800039aa <balloc>
    80003b7c:	0005059b          	sext.w	a1,a0
    80003b80:	08b92023          	sw	a1,128(s2)
    80003b84:	b759                	j	80003b0a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b86:	00092503          	lw	a0,0(s2)
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	e20080e7          	jalr	-480(ra) # 800039aa <balloc>
    80003b92:	0005099b          	sext.w	s3,a0
    80003b96:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b9a:	8552                	mv	a0,s4
    80003b9c:	00001097          	auipc	ra,0x1
    80003ba0:	ef8080e7          	jalr	-264(ra) # 80004a94 <log_write>
    80003ba4:	b771                	j	80003b30 <bmap+0x54>
  panic("bmap: out of range");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	a9250513          	addi	a0,a0,-1390 # 80008638 <syscalls+0x140>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	990080e7          	jalr	-1648(ra) # 8000053e <panic>

0000000080003bb6 <iget>:
{
    80003bb6:	7179                	addi	sp,sp,-48
    80003bb8:	f406                	sd	ra,40(sp)
    80003bba:	f022                	sd	s0,32(sp)
    80003bbc:	ec26                	sd	s1,24(sp)
    80003bbe:	e84a                	sd	s2,16(sp)
    80003bc0:	e44e                	sd	s3,8(sp)
    80003bc2:	e052                	sd	s4,0(sp)
    80003bc4:	1800                	addi	s0,sp,48
    80003bc6:	89aa                	mv	s3,a0
    80003bc8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bca:	0001c517          	auipc	a0,0x1c
    80003bce:	61e50513          	addi	a0,a0,1566 # 800201e8 <itable>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	012080e7          	jalr	18(ra) # 80000be4 <acquire>
  empty = 0;
    80003bda:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bdc:	0001c497          	auipc	s1,0x1c
    80003be0:	62448493          	addi	s1,s1,1572 # 80020200 <itable+0x18>
    80003be4:	0001e697          	auipc	a3,0x1e
    80003be8:	0ac68693          	addi	a3,a3,172 # 80021c90 <log>
    80003bec:	a039                	j	80003bfa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bee:	02090b63          	beqz	s2,80003c24 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bf2:	08848493          	addi	s1,s1,136
    80003bf6:	02d48a63          	beq	s1,a3,80003c2a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bfa:	449c                	lw	a5,8(s1)
    80003bfc:	fef059e3          	blez	a5,80003bee <iget+0x38>
    80003c00:	4098                	lw	a4,0(s1)
    80003c02:	ff3716e3          	bne	a4,s3,80003bee <iget+0x38>
    80003c06:	40d8                	lw	a4,4(s1)
    80003c08:	ff4713e3          	bne	a4,s4,80003bee <iget+0x38>
      ip->ref++;
    80003c0c:	2785                	addiw	a5,a5,1
    80003c0e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c10:	0001c517          	auipc	a0,0x1c
    80003c14:	5d850513          	addi	a0,a0,1496 # 800201e8 <itable>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	080080e7          	jalr	128(ra) # 80000c98 <release>
      return ip;
    80003c20:	8926                	mv	s2,s1
    80003c22:	a03d                	j	80003c50 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c24:	f7f9                	bnez	a5,80003bf2 <iget+0x3c>
    80003c26:	8926                	mv	s2,s1
    80003c28:	b7e9                	j	80003bf2 <iget+0x3c>
  if(empty == 0)
    80003c2a:	02090c63          	beqz	s2,80003c62 <iget+0xac>
  ip->dev = dev;
    80003c2e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c32:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c36:	4785                	li	a5,1
    80003c38:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c3c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c40:	0001c517          	auipc	a0,0x1c
    80003c44:	5a850513          	addi	a0,a0,1448 # 800201e8 <itable>
    80003c48:	ffffd097          	auipc	ra,0xffffd
    80003c4c:	050080e7          	jalr	80(ra) # 80000c98 <release>
}
    80003c50:	854a                	mv	a0,s2
    80003c52:	70a2                	ld	ra,40(sp)
    80003c54:	7402                	ld	s0,32(sp)
    80003c56:	64e2                	ld	s1,24(sp)
    80003c58:	6942                	ld	s2,16(sp)
    80003c5a:	69a2                	ld	s3,8(sp)
    80003c5c:	6a02                	ld	s4,0(sp)
    80003c5e:	6145                	addi	sp,sp,48
    80003c60:	8082                	ret
    panic("iget: no inodes");
    80003c62:	00005517          	auipc	a0,0x5
    80003c66:	9ee50513          	addi	a0,a0,-1554 # 80008650 <syscalls+0x158>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	8d4080e7          	jalr	-1836(ra) # 8000053e <panic>

0000000080003c72 <fsinit>:
fsinit(int dev) {
    80003c72:	7179                	addi	sp,sp,-48
    80003c74:	f406                	sd	ra,40(sp)
    80003c76:	f022                	sd	s0,32(sp)
    80003c78:	ec26                	sd	s1,24(sp)
    80003c7a:	e84a                	sd	s2,16(sp)
    80003c7c:	e44e                	sd	s3,8(sp)
    80003c7e:	1800                	addi	s0,sp,48
    80003c80:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c82:	4585                	li	a1,1
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	a64080e7          	jalr	-1436(ra) # 800036e8 <bread>
    80003c8c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c8e:	0001c997          	auipc	s3,0x1c
    80003c92:	53a98993          	addi	s3,s3,1338 # 800201c8 <sb>
    80003c96:	02000613          	li	a2,32
    80003c9a:	05850593          	addi	a1,a0,88
    80003c9e:	854e                	mv	a0,s3
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	0a0080e7          	jalr	160(ra) # 80000d40 <memmove>
  brelse(bp);
    80003ca8:	8526                	mv	a0,s1
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	b6e080e7          	jalr	-1170(ra) # 80003818 <brelse>
  if(sb.magic != FSMAGIC)
    80003cb2:	0009a703          	lw	a4,0(s3)
    80003cb6:	102037b7          	lui	a5,0x10203
    80003cba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cbe:	02f71263          	bne	a4,a5,80003ce2 <fsinit+0x70>
  initlog(dev, &sb);
    80003cc2:	0001c597          	auipc	a1,0x1c
    80003cc6:	50658593          	addi	a1,a1,1286 # 800201c8 <sb>
    80003cca:	854a                	mv	a0,s2
    80003ccc:	00001097          	auipc	ra,0x1
    80003cd0:	b4c080e7          	jalr	-1204(ra) # 80004818 <initlog>
}
    80003cd4:	70a2                	ld	ra,40(sp)
    80003cd6:	7402                	ld	s0,32(sp)
    80003cd8:	64e2                	ld	s1,24(sp)
    80003cda:	6942                	ld	s2,16(sp)
    80003cdc:	69a2                	ld	s3,8(sp)
    80003cde:	6145                	addi	sp,sp,48
    80003ce0:	8082                	ret
    panic("invalid file system");
    80003ce2:	00005517          	auipc	a0,0x5
    80003ce6:	97e50513          	addi	a0,a0,-1666 # 80008660 <syscalls+0x168>
    80003cea:	ffffd097          	auipc	ra,0xffffd
    80003cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>

0000000080003cf2 <iinit>:
{
    80003cf2:	7179                	addi	sp,sp,-48
    80003cf4:	f406                	sd	ra,40(sp)
    80003cf6:	f022                	sd	s0,32(sp)
    80003cf8:	ec26                	sd	s1,24(sp)
    80003cfa:	e84a                	sd	s2,16(sp)
    80003cfc:	e44e                	sd	s3,8(sp)
    80003cfe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d00:	00005597          	auipc	a1,0x5
    80003d04:	97858593          	addi	a1,a1,-1672 # 80008678 <syscalls+0x180>
    80003d08:	0001c517          	auipc	a0,0x1c
    80003d0c:	4e050513          	addi	a0,a0,1248 # 800201e8 <itable>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	e44080e7          	jalr	-444(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d18:	0001c497          	auipc	s1,0x1c
    80003d1c:	4f848493          	addi	s1,s1,1272 # 80020210 <itable+0x28>
    80003d20:	0001e997          	auipc	s3,0x1e
    80003d24:	f8098993          	addi	s3,s3,-128 # 80021ca0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d28:	00005917          	auipc	s2,0x5
    80003d2c:	95890913          	addi	s2,s2,-1704 # 80008680 <syscalls+0x188>
    80003d30:	85ca                	mv	a1,s2
    80003d32:	8526                	mv	a0,s1
    80003d34:	00001097          	auipc	ra,0x1
    80003d38:	e46080e7          	jalr	-442(ra) # 80004b7a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d3c:	08848493          	addi	s1,s1,136
    80003d40:	ff3498e3          	bne	s1,s3,80003d30 <iinit+0x3e>
}
    80003d44:	70a2                	ld	ra,40(sp)
    80003d46:	7402                	ld	s0,32(sp)
    80003d48:	64e2                	ld	s1,24(sp)
    80003d4a:	6942                	ld	s2,16(sp)
    80003d4c:	69a2                	ld	s3,8(sp)
    80003d4e:	6145                	addi	sp,sp,48
    80003d50:	8082                	ret

0000000080003d52 <ialloc>:
{
    80003d52:	715d                	addi	sp,sp,-80
    80003d54:	e486                	sd	ra,72(sp)
    80003d56:	e0a2                	sd	s0,64(sp)
    80003d58:	fc26                	sd	s1,56(sp)
    80003d5a:	f84a                	sd	s2,48(sp)
    80003d5c:	f44e                	sd	s3,40(sp)
    80003d5e:	f052                	sd	s4,32(sp)
    80003d60:	ec56                	sd	s5,24(sp)
    80003d62:	e85a                	sd	s6,16(sp)
    80003d64:	e45e                	sd	s7,8(sp)
    80003d66:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d68:	0001c717          	auipc	a4,0x1c
    80003d6c:	46c72703          	lw	a4,1132(a4) # 800201d4 <sb+0xc>
    80003d70:	4785                	li	a5,1
    80003d72:	04e7fa63          	bgeu	a5,a4,80003dc6 <ialloc+0x74>
    80003d76:	8aaa                	mv	s5,a0
    80003d78:	8bae                	mv	s7,a1
    80003d7a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d7c:	0001ca17          	auipc	s4,0x1c
    80003d80:	44ca0a13          	addi	s4,s4,1100 # 800201c8 <sb>
    80003d84:	00048b1b          	sext.w	s6,s1
    80003d88:	0044d593          	srli	a1,s1,0x4
    80003d8c:	018a2783          	lw	a5,24(s4)
    80003d90:	9dbd                	addw	a1,a1,a5
    80003d92:	8556                	mv	a0,s5
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	954080e7          	jalr	-1708(ra) # 800036e8 <bread>
    80003d9c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d9e:	05850993          	addi	s3,a0,88
    80003da2:	00f4f793          	andi	a5,s1,15
    80003da6:	079a                	slli	a5,a5,0x6
    80003da8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003daa:	00099783          	lh	a5,0(s3)
    80003dae:	c785                	beqz	a5,80003dd6 <ialloc+0x84>
    brelse(bp);
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	a68080e7          	jalr	-1432(ra) # 80003818 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003db8:	0485                	addi	s1,s1,1
    80003dba:	00ca2703          	lw	a4,12(s4)
    80003dbe:	0004879b          	sext.w	a5,s1
    80003dc2:	fce7e1e3          	bltu	a5,a4,80003d84 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003dc6:	00005517          	auipc	a0,0x5
    80003dca:	8c250513          	addi	a0,a0,-1854 # 80008688 <syscalls+0x190>
    80003dce:	ffffc097          	auipc	ra,0xffffc
    80003dd2:	770080e7          	jalr	1904(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003dd6:	04000613          	li	a2,64
    80003dda:	4581                	li	a1,0
    80003ddc:	854e                	mv	a0,s3
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	f02080e7          	jalr	-254(ra) # 80000ce0 <memset>
      dip->type = type;
    80003de6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dea:	854a                	mv	a0,s2
    80003dec:	00001097          	auipc	ra,0x1
    80003df0:	ca8080e7          	jalr	-856(ra) # 80004a94 <log_write>
      brelse(bp);
    80003df4:	854a                	mv	a0,s2
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	a22080e7          	jalr	-1502(ra) # 80003818 <brelse>
      return iget(dev, inum);
    80003dfe:	85da                	mv	a1,s6
    80003e00:	8556                	mv	a0,s5
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	db4080e7          	jalr	-588(ra) # 80003bb6 <iget>
}
    80003e0a:	60a6                	ld	ra,72(sp)
    80003e0c:	6406                	ld	s0,64(sp)
    80003e0e:	74e2                	ld	s1,56(sp)
    80003e10:	7942                	ld	s2,48(sp)
    80003e12:	79a2                	ld	s3,40(sp)
    80003e14:	7a02                	ld	s4,32(sp)
    80003e16:	6ae2                	ld	s5,24(sp)
    80003e18:	6b42                	ld	s6,16(sp)
    80003e1a:	6ba2                	ld	s7,8(sp)
    80003e1c:	6161                	addi	sp,sp,80
    80003e1e:	8082                	ret

0000000080003e20 <iupdate>:
{
    80003e20:	1101                	addi	sp,sp,-32
    80003e22:	ec06                	sd	ra,24(sp)
    80003e24:	e822                	sd	s0,16(sp)
    80003e26:	e426                	sd	s1,8(sp)
    80003e28:	e04a                	sd	s2,0(sp)
    80003e2a:	1000                	addi	s0,sp,32
    80003e2c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e2e:	415c                	lw	a5,4(a0)
    80003e30:	0047d79b          	srliw	a5,a5,0x4
    80003e34:	0001c597          	auipc	a1,0x1c
    80003e38:	3ac5a583          	lw	a1,940(a1) # 800201e0 <sb+0x18>
    80003e3c:	9dbd                	addw	a1,a1,a5
    80003e3e:	4108                	lw	a0,0(a0)
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	8a8080e7          	jalr	-1880(ra) # 800036e8 <bread>
    80003e48:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e4a:	05850793          	addi	a5,a0,88
    80003e4e:	40c8                	lw	a0,4(s1)
    80003e50:	893d                	andi	a0,a0,15
    80003e52:	051a                	slli	a0,a0,0x6
    80003e54:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e56:	04449703          	lh	a4,68(s1)
    80003e5a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e5e:	04649703          	lh	a4,70(s1)
    80003e62:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e66:	04849703          	lh	a4,72(s1)
    80003e6a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e6e:	04a49703          	lh	a4,74(s1)
    80003e72:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e76:	44f8                	lw	a4,76(s1)
    80003e78:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e7a:	03400613          	li	a2,52
    80003e7e:	05048593          	addi	a1,s1,80
    80003e82:	0531                	addi	a0,a0,12
    80003e84:	ffffd097          	auipc	ra,0xffffd
    80003e88:	ebc080e7          	jalr	-324(ra) # 80000d40 <memmove>
  log_write(bp);
    80003e8c:	854a                	mv	a0,s2
    80003e8e:	00001097          	auipc	ra,0x1
    80003e92:	c06080e7          	jalr	-1018(ra) # 80004a94 <log_write>
  brelse(bp);
    80003e96:	854a                	mv	a0,s2
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	980080e7          	jalr	-1664(ra) # 80003818 <brelse>
}
    80003ea0:	60e2                	ld	ra,24(sp)
    80003ea2:	6442                	ld	s0,16(sp)
    80003ea4:	64a2                	ld	s1,8(sp)
    80003ea6:	6902                	ld	s2,0(sp)
    80003ea8:	6105                	addi	sp,sp,32
    80003eaa:	8082                	ret

0000000080003eac <idup>:
{
    80003eac:	1101                	addi	sp,sp,-32
    80003eae:	ec06                	sd	ra,24(sp)
    80003eb0:	e822                	sd	s0,16(sp)
    80003eb2:	e426                	sd	s1,8(sp)
    80003eb4:	1000                	addi	s0,sp,32
    80003eb6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eb8:	0001c517          	auipc	a0,0x1c
    80003ebc:	33050513          	addi	a0,a0,816 # 800201e8 <itable>
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	d24080e7          	jalr	-732(ra) # 80000be4 <acquire>
  ip->ref++;
    80003ec8:	449c                	lw	a5,8(s1)
    80003eca:	2785                	addiw	a5,a5,1
    80003ecc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ece:	0001c517          	auipc	a0,0x1c
    80003ed2:	31a50513          	addi	a0,a0,794 # 800201e8 <itable>
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	dc2080e7          	jalr	-574(ra) # 80000c98 <release>
}
    80003ede:	8526                	mv	a0,s1
    80003ee0:	60e2                	ld	ra,24(sp)
    80003ee2:	6442                	ld	s0,16(sp)
    80003ee4:	64a2                	ld	s1,8(sp)
    80003ee6:	6105                	addi	sp,sp,32
    80003ee8:	8082                	ret

0000000080003eea <ilock>:
{
    80003eea:	1101                	addi	sp,sp,-32
    80003eec:	ec06                	sd	ra,24(sp)
    80003eee:	e822                	sd	s0,16(sp)
    80003ef0:	e426                	sd	s1,8(sp)
    80003ef2:	e04a                	sd	s2,0(sp)
    80003ef4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ef6:	c115                	beqz	a0,80003f1a <ilock+0x30>
    80003ef8:	84aa                	mv	s1,a0
    80003efa:	451c                	lw	a5,8(a0)
    80003efc:	00f05f63          	blez	a5,80003f1a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f00:	0541                	addi	a0,a0,16
    80003f02:	00001097          	auipc	ra,0x1
    80003f06:	cb2080e7          	jalr	-846(ra) # 80004bb4 <acquiresleep>
  if(ip->valid == 0){
    80003f0a:	40bc                	lw	a5,64(s1)
    80003f0c:	cf99                	beqz	a5,80003f2a <ilock+0x40>
}
    80003f0e:	60e2                	ld	ra,24(sp)
    80003f10:	6442                	ld	s0,16(sp)
    80003f12:	64a2                	ld	s1,8(sp)
    80003f14:	6902                	ld	s2,0(sp)
    80003f16:	6105                	addi	sp,sp,32
    80003f18:	8082                	ret
    panic("ilock");
    80003f1a:	00004517          	auipc	a0,0x4
    80003f1e:	78650513          	addi	a0,a0,1926 # 800086a0 <syscalls+0x1a8>
    80003f22:	ffffc097          	auipc	ra,0xffffc
    80003f26:	61c080e7          	jalr	1564(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f2a:	40dc                	lw	a5,4(s1)
    80003f2c:	0047d79b          	srliw	a5,a5,0x4
    80003f30:	0001c597          	auipc	a1,0x1c
    80003f34:	2b05a583          	lw	a1,688(a1) # 800201e0 <sb+0x18>
    80003f38:	9dbd                	addw	a1,a1,a5
    80003f3a:	4088                	lw	a0,0(s1)
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	7ac080e7          	jalr	1964(ra) # 800036e8 <bread>
    80003f44:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f46:	05850593          	addi	a1,a0,88
    80003f4a:	40dc                	lw	a5,4(s1)
    80003f4c:	8bbd                	andi	a5,a5,15
    80003f4e:	079a                	slli	a5,a5,0x6
    80003f50:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f52:	00059783          	lh	a5,0(a1)
    80003f56:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f5a:	00259783          	lh	a5,2(a1)
    80003f5e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f62:	00459783          	lh	a5,4(a1)
    80003f66:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f6a:	00659783          	lh	a5,6(a1)
    80003f6e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f72:	459c                	lw	a5,8(a1)
    80003f74:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f76:	03400613          	li	a2,52
    80003f7a:	05b1                	addi	a1,a1,12
    80003f7c:	05048513          	addi	a0,s1,80
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	dc0080e7          	jalr	-576(ra) # 80000d40 <memmove>
    brelse(bp);
    80003f88:	854a                	mv	a0,s2
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	88e080e7          	jalr	-1906(ra) # 80003818 <brelse>
    ip->valid = 1;
    80003f92:	4785                	li	a5,1
    80003f94:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f96:	04449783          	lh	a5,68(s1)
    80003f9a:	fbb5                	bnez	a5,80003f0e <ilock+0x24>
      panic("ilock: no type");
    80003f9c:	00004517          	auipc	a0,0x4
    80003fa0:	70c50513          	addi	a0,a0,1804 # 800086a8 <syscalls+0x1b0>
    80003fa4:	ffffc097          	auipc	ra,0xffffc
    80003fa8:	59a080e7          	jalr	1434(ra) # 8000053e <panic>

0000000080003fac <iunlock>:
{
    80003fac:	1101                	addi	sp,sp,-32
    80003fae:	ec06                	sd	ra,24(sp)
    80003fb0:	e822                	sd	s0,16(sp)
    80003fb2:	e426                	sd	s1,8(sp)
    80003fb4:	e04a                	sd	s2,0(sp)
    80003fb6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fb8:	c905                	beqz	a0,80003fe8 <iunlock+0x3c>
    80003fba:	84aa                	mv	s1,a0
    80003fbc:	01050913          	addi	s2,a0,16
    80003fc0:	854a                	mv	a0,s2
    80003fc2:	00001097          	auipc	ra,0x1
    80003fc6:	c8c080e7          	jalr	-884(ra) # 80004c4e <holdingsleep>
    80003fca:	cd19                	beqz	a0,80003fe8 <iunlock+0x3c>
    80003fcc:	449c                	lw	a5,8(s1)
    80003fce:	00f05d63          	blez	a5,80003fe8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fd2:	854a                	mv	a0,s2
    80003fd4:	00001097          	auipc	ra,0x1
    80003fd8:	c36080e7          	jalr	-970(ra) # 80004c0a <releasesleep>
}
    80003fdc:	60e2                	ld	ra,24(sp)
    80003fde:	6442                	ld	s0,16(sp)
    80003fe0:	64a2                	ld	s1,8(sp)
    80003fe2:	6902                	ld	s2,0(sp)
    80003fe4:	6105                	addi	sp,sp,32
    80003fe6:	8082                	ret
    panic("iunlock");
    80003fe8:	00004517          	auipc	a0,0x4
    80003fec:	6d050513          	addi	a0,a0,1744 # 800086b8 <syscalls+0x1c0>
    80003ff0:	ffffc097          	auipc	ra,0xffffc
    80003ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>

0000000080003ff8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ff8:	7179                	addi	sp,sp,-48
    80003ffa:	f406                	sd	ra,40(sp)
    80003ffc:	f022                	sd	s0,32(sp)
    80003ffe:	ec26                	sd	s1,24(sp)
    80004000:	e84a                	sd	s2,16(sp)
    80004002:	e44e                	sd	s3,8(sp)
    80004004:	e052                	sd	s4,0(sp)
    80004006:	1800                	addi	s0,sp,48
    80004008:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000400a:	05050493          	addi	s1,a0,80
    8000400e:	08050913          	addi	s2,a0,128
    80004012:	a021                	j	8000401a <itrunc+0x22>
    80004014:	0491                	addi	s1,s1,4
    80004016:	01248d63          	beq	s1,s2,80004030 <itrunc+0x38>
    if(ip->addrs[i]){
    8000401a:	408c                	lw	a1,0(s1)
    8000401c:	dde5                	beqz	a1,80004014 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000401e:	0009a503          	lw	a0,0(s3)
    80004022:	00000097          	auipc	ra,0x0
    80004026:	90c080e7          	jalr	-1780(ra) # 8000392e <bfree>
      ip->addrs[i] = 0;
    8000402a:	0004a023          	sw	zero,0(s1)
    8000402e:	b7dd                	j	80004014 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004030:	0809a583          	lw	a1,128(s3)
    80004034:	e185                	bnez	a1,80004054 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004036:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000403a:	854e                	mv	a0,s3
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	de4080e7          	jalr	-540(ra) # 80003e20 <iupdate>
}
    80004044:	70a2                	ld	ra,40(sp)
    80004046:	7402                	ld	s0,32(sp)
    80004048:	64e2                	ld	s1,24(sp)
    8000404a:	6942                	ld	s2,16(sp)
    8000404c:	69a2                	ld	s3,8(sp)
    8000404e:	6a02                	ld	s4,0(sp)
    80004050:	6145                	addi	sp,sp,48
    80004052:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004054:	0009a503          	lw	a0,0(s3)
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	690080e7          	jalr	1680(ra) # 800036e8 <bread>
    80004060:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004062:	05850493          	addi	s1,a0,88
    80004066:	45850913          	addi	s2,a0,1112
    8000406a:	a811                	j	8000407e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000406c:	0009a503          	lw	a0,0(s3)
    80004070:	00000097          	auipc	ra,0x0
    80004074:	8be080e7          	jalr	-1858(ra) # 8000392e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004078:	0491                	addi	s1,s1,4
    8000407a:	01248563          	beq	s1,s2,80004084 <itrunc+0x8c>
      if(a[j])
    8000407e:	408c                	lw	a1,0(s1)
    80004080:	dde5                	beqz	a1,80004078 <itrunc+0x80>
    80004082:	b7ed                	j	8000406c <itrunc+0x74>
    brelse(bp);
    80004084:	8552                	mv	a0,s4
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	792080e7          	jalr	1938(ra) # 80003818 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000408e:	0809a583          	lw	a1,128(s3)
    80004092:	0009a503          	lw	a0,0(s3)
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	898080e7          	jalr	-1896(ra) # 8000392e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000409e:	0809a023          	sw	zero,128(s3)
    800040a2:	bf51                	j	80004036 <itrunc+0x3e>

00000000800040a4 <iput>:
{
    800040a4:	1101                	addi	sp,sp,-32
    800040a6:	ec06                	sd	ra,24(sp)
    800040a8:	e822                	sd	s0,16(sp)
    800040aa:	e426                	sd	s1,8(sp)
    800040ac:	e04a                	sd	s2,0(sp)
    800040ae:	1000                	addi	s0,sp,32
    800040b0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040b2:	0001c517          	auipc	a0,0x1c
    800040b6:	13650513          	addi	a0,a0,310 # 800201e8 <itable>
    800040ba:	ffffd097          	auipc	ra,0xffffd
    800040be:	b2a080e7          	jalr	-1238(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040c2:	4498                	lw	a4,8(s1)
    800040c4:	4785                	li	a5,1
    800040c6:	02f70363          	beq	a4,a5,800040ec <iput+0x48>
  ip->ref--;
    800040ca:	449c                	lw	a5,8(s1)
    800040cc:	37fd                	addiw	a5,a5,-1
    800040ce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040d0:	0001c517          	auipc	a0,0x1c
    800040d4:	11850513          	addi	a0,a0,280 # 800201e8 <itable>
    800040d8:	ffffd097          	auipc	ra,0xffffd
    800040dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
}
    800040e0:	60e2                	ld	ra,24(sp)
    800040e2:	6442                	ld	s0,16(sp)
    800040e4:	64a2                	ld	s1,8(sp)
    800040e6:	6902                	ld	s2,0(sp)
    800040e8:	6105                	addi	sp,sp,32
    800040ea:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040ec:	40bc                	lw	a5,64(s1)
    800040ee:	dff1                	beqz	a5,800040ca <iput+0x26>
    800040f0:	04a49783          	lh	a5,74(s1)
    800040f4:	fbf9                	bnez	a5,800040ca <iput+0x26>
    acquiresleep(&ip->lock);
    800040f6:	01048913          	addi	s2,s1,16
    800040fa:	854a                	mv	a0,s2
    800040fc:	00001097          	auipc	ra,0x1
    80004100:	ab8080e7          	jalr	-1352(ra) # 80004bb4 <acquiresleep>
    release(&itable.lock);
    80004104:	0001c517          	auipc	a0,0x1c
    80004108:	0e450513          	addi	a0,a0,228 # 800201e8 <itable>
    8000410c:	ffffd097          	auipc	ra,0xffffd
    80004110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
    itrunc(ip);
    80004114:	8526                	mv	a0,s1
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	ee2080e7          	jalr	-286(ra) # 80003ff8 <itrunc>
    ip->type = 0;
    8000411e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004122:	8526                	mv	a0,s1
    80004124:	00000097          	auipc	ra,0x0
    80004128:	cfc080e7          	jalr	-772(ra) # 80003e20 <iupdate>
    ip->valid = 0;
    8000412c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004130:	854a                	mv	a0,s2
    80004132:	00001097          	auipc	ra,0x1
    80004136:	ad8080e7          	jalr	-1320(ra) # 80004c0a <releasesleep>
    acquire(&itable.lock);
    8000413a:	0001c517          	auipc	a0,0x1c
    8000413e:	0ae50513          	addi	a0,a0,174 # 800201e8 <itable>
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	aa2080e7          	jalr	-1374(ra) # 80000be4 <acquire>
    8000414a:	b741                	j	800040ca <iput+0x26>

000000008000414c <iunlockput>:
{
    8000414c:	1101                	addi	sp,sp,-32
    8000414e:	ec06                	sd	ra,24(sp)
    80004150:	e822                	sd	s0,16(sp)
    80004152:	e426                	sd	s1,8(sp)
    80004154:	1000                	addi	s0,sp,32
    80004156:	84aa                	mv	s1,a0
  iunlock(ip);
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	e54080e7          	jalr	-428(ra) # 80003fac <iunlock>
  iput(ip);
    80004160:	8526                	mv	a0,s1
    80004162:	00000097          	auipc	ra,0x0
    80004166:	f42080e7          	jalr	-190(ra) # 800040a4 <iput>
}
    8000416a:	60e2                	ld	ra,24(sp)
    8000416c:	6442                	ld	s0,16(sp)
    8000416e:	64a2                	ld	s1,8(sp)
    80004170:	6105                	addi	sp,sp,32
    80004172:	8082                	ret

0000000080004174 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004174:	1141                	addi	sp,sp,-16
    80004176:	e422                	sd	s0,8(sp)
    80004178:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000417a:	411c                	lw	a5,0(a0)
    8000417c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000417e:	415c                	lw	a5,4(a0)
    80004180:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004182:	04451783          	lh	a5,68(a0)
    80004186:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000418a:	04a51783          	lh	a5,74(a0)
    8000418e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004192:	04c56783          	lwu	a5,76(a0)
    80004196:	e99c                	sd	a5,16(a1)
}
    80004198:	6422                	ld	s0,8(sp)
    8000419a:	0141                	addi	sp,sp,16
    8000419c:	8082                	ret

000000008000419e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000419e:	457c                	lw	a5,76(a0)
    800041a0:	0ed7e963          	bltu	a5,a3,80004292 <readi+0xf4>
{
    800041a4:	7159                	addi	sp,sp,-112
    800041a6:	f486                	sd	ra,104(sp)
    800041a8:	f0a2                	sd	s0,96(sp)
    800041aa:	eca6                	sd	s1,88(sp)
    800041ac:	e8ca                	sd	s2,80(sp)
    800041ae:	e4ce                	sd	s3,72(sp)
    800041b0:	e0d2                	sd	s4,64(sp)
    800041b2:	fc56                	sd	s5,56(sp)
    800041b4:	f85a                	sd	s6,48(sp)
    800041b6:	f45e                	sd	s7,40(sp)
    800041b8:	f062                	sd	s8,32(sp)
    800041ba:	ec66                	sd	s9,24(sp)
    800041bc:	e86a                	sd	s10,16(sp)
    800041be:	e46e                	sd	s11,8(sp)
    800041c0:	1880                	addi	s0,sp,112
    800041c2:	8baa                	mv	s7,a0
    800041c4:	8c2e                	mv	s8,a1
    800041c6:	8ab2                	mv	s5,a2
    800041c8:	84b6                	mv	s1,a3
    800041ca:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041cc:	9f35                	addw	a4,a4,a3
    return 0;
    800041ce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041d0:	0ad76063          	bltu	a4,a3,80004270 <readi+0xd2>
  if(off + n > ip->size)
    800041d4:	00e7f463          	bgeu	a5,a4,800041dc <readi+0x3e>
    n = ip->size - off;
    800041d8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041dc:	0a0b0963          	beqz	s6,8000428e <readi+0xf0>
    800041e0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041e2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041e6:	5cfd                	li	s9,-1
    800041e8:	a82d                	j	80004222 <readi+0x84>
    800041ea:	020a1d93          	slli	s11,s4,0x20
    800041ee:	020ddd93          	srli	s11,s11,0x20
    800041f2:	05890613          	addi	a2,s2,88
    800041f6:	86ee                	mv	a3,s11
    800041f8:	963a                	add	a2,a2,a4
    800041fa:	85d6                	mv	a1,s5
    800041fc:	8562                	mv	a0,s8
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	a74080e7          	jalr	-1420(ra) # 80002c72 <either_copyout>
    80004206:	05950d63          	beq	a0,s9,80004260 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000420a:	854a                	mv	a0,s2
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	60c080e7          	jalr	1548(ra) # 80003818 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004214:	013a09bb          	addw	s3,s4,s3
    80004218:	009a04bb          	addw	s1,s4,s1
    8000421c:	9aee                	add	s5,s5,s11
    8000421e:	0569f763          	bgeu	s3,s6,8000426c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004222:	000ba903          	lw	s2,0(s7)
    80004226:	00a4d59b          	srliw	a1,s1,0xa
    8000422a:	855e                	mv	a0,s7
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	8b0080e7          	jalr	-1872(ra) # 80003adc <bmap>
    80004234:	0005059b          	sext.w	a1,a0
    80004238:	854a                	mv	a0,s2
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	4ae080e7          	jalr	1198(ra) # 800036e8 <bread>
    80004242:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004244:	3ff4f713          	andi	a4,s1,1023
    80004248:	40ed07bb          	subw	a5,s10,a4
    8000424c:	413b06bb          	subw	a3,s6,s3
    80004250:	8a3e                	mv	s4,a5
    80004252:	2781                	sext.w	a5,a5
    80004254:	0006861b          	sext.w	a2,a3
    80004258:	f8f679e3          	bgeu	a2,a5,800041ea <readi+0x4c>
    8000425c:	8a36                	mv	s4,a3
    8000425e:	b771                	j	800041ea <readi+0x4c>
      brelse(bp);
    80004260:	854a                	mv	a0,s2
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	5b6080e7          	jalr	1462(ra) # 80003818 <brelse>
      tot = -1;
    8000426a:	59fd                	li	s3,-1
  }
  return tot;
    8000426c:	0009851b          	sext.w	a0,s3
}
    80004270:	70a6                	ld	ra,104(sp)
    80004272:	7406                	ld	s0,96(sp)
    80004274:	64e6                	ld	s1,88(sp)
    80004276:	6946                	ld	s2,80(sp)
    80004278:	69a6                	ld	s3,72(sp)
    8000427a:	6a06                	ld	s4,64(sp)
    8000427c:	7ae2                	ld	s5,56(sp)
    8000427e:	7b42                	ld	s6,48(sp)
    80004280:	7ba2                	ld	s7,40(sp)
    80004282:	7c02                	ld	s8,32(sp)
    80004284:	6ce2                	ld	s9,24(sp)
    80004286:	6d42                	ld	s10,16(sp)
    80004288:	6da2                	ld	s11,8(sp)
    8000428a:	6165                	addi	sp,sp,112
    8000428c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000428e:	89da                	mv	s3,s6
    80004290:	bff1                	j	8000426c <readi+0xce>
    return 0;
    80004292:	4501                	li	a0,0
}
    80004294:	8082                	ret

0000000080004296 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004296:	457c                	lw	a5,76(a0)
    80004298:	10d7e863          	bltu	a5,a3,800043a8 <writei+0x112>
{
    8000429c:	7159                	addi	sp,sp,-112
    8000429e:	f486                	sd	ra,104(sp)
    800042a0:	f0a2                	sd	s0,96(sp)
    800042a2:	eca6                	sd	s1,88(sp)
    800042a4:	e8ca                	sd	s2,80(sp)
    800042a6:	e4ce                	sd	s3,72(sp)
    800042a8:	e0d2                	sd	s4,64(sp)
    800042aa:	fc56                	sd	s5,56(sp)
    800042ac:	f85a                	sd	s6,48(sp)
    800042ae:	f45e                	sd	s7,40(sp)
    800042b0:	f062                	sd	s8,32(sp)
    800042b2:	ec66                	sd	s9,24(sp)
    800042b4:	e86a                	sd	s10,16(sp)
    800042b6:	e46e                	sd	s11,8(sp)
    800042b8:	1880                	addi	s0,sp,112
    800042ba:	8b2a                	mv	s6,a0
    800042bc:	8c2e                	mv	s8,a1
    800042be:	8ab2                	mv	s5,a2
    800042c0:	8936                	mv	s2,a3
    800042c2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800042c4:	00e687bb          	addw	a5,a3,a4
    800042c8:	0ed7e263          	bltu	a5,a3,800043ac <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042cc:	00043737          	lui	a4,0x43
    800042d0:	0ef76063          	bltu	a4,a5,800043b0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042d4:	0c0b8863          	beqz	s7,800043a4 <writei+0x10e>
    800042d8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042da:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042de:	5cfd                	li	s9,-1
    800042e0:	a091                	j	80004324 <writei+0x8e>
    800042e2:	02099d93          	slli	s11,s3,0x20
    800042e6:	020ddd93          	srli	s11,s11,0x20
    800042ea:	05848513          	addi	a0,s1,88
    800042ee:	86ee                	mv	a3,s11
    800042f0:	8656                	mv	a2,s5
    800042f2:	85e2                	mv	a1,s8
    800042f4:	953a                	add	a0,a0,a4
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	9d2080e7          	jalr	-1582(ra) # 80002cc8 <either_copyin>
    800042fe:	07950263          	beq	a0,s9,80004362 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004302:	8526                	mv	a0,s1
    80004304:	00000097          	auipc	ra,0x0
    80004308:	790080e7          	jalr	1936(ra) # 80004a94 <log_write>
    brelse(bp);
    8000430c:	8526                	mv	a0,s1
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	50a080e7          	jalr	1290(ra) # 80003818 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004316:	01498a3b          	addw	s4,s3,s4
    8000431a:	0129893b          	addw	s2,s3,s2
    8000431e:	9aee                	add	s5,s5,s11
    80004320:	057a7663          	bgeu	s4,s7,8000436c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004324:	000b2483          	lw	s1,0(s6)
    80004328:	00a9559b          	srliw	a1,s2,0xa
    8000432c:	855a                	mv	a0,s6
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	7ae080e7          	jalr	1966(ra) # 80003adc <bmap>
    80004336:	0005059b          	sext.w	a1,a0
    8000433a:	8526                	mv	a0,s1
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	3ac080e7          	jalr	940(ra) # 800036e8 <bread>
    80004344:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004346:	3ff97713          	andi	a4,s2,1023
    8000434a:	40ed07bb          	subw	a5,s10,a4
    8000434e:	414b86bb          	subw	a3,s7,s4
    80004352:	89be                	mv	s3,a5
    80004354:	2781                	sext.w	a5,a5
    80004356:	0006861b          	sext.w	a2,a3
    8000435a:	f8f674e3          	bgeu	a2,a5,800042e2 <writei+0x4c>
    8000435e:	89b6                	mv	s3,a3
    80004360:	b749                	j	800042e2 <writei+0x4c>
      brelse(bp);
    80004362:	8526                	mv	a0,s1
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	4b4080e7          	jalr	1204(ra) # 80003818 <brelse>
  }

  if(off > ip->size)
    8000436c:	04cb2783          	lw	a5,76(s6)
    80004370:	0127f463          	bgeu	a5,s2,80004378 <writei+0xe2>
    ip->size = off;
    80004374:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004378:	855a                	mv	a0,s6
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	aa6080e7          	jalr	-1370(ra) # 80003e20 <iupdate>

  return tot;
    80004382:	000a051b          	sext.w	a0,s4
}
    80004386:	70a6                	ld	ra,104(sp)
    80004388:	7406                	ld	s0,96(sp)
    8000438a:	64e6                	ld	s1,88(sp)
    8000438c:	6946                	ld	s2,80(sp)
    8000438e:	69a6                	ld	s3,72(sp)
    80004390:	6a06                	ld	s4,64(sp)
    80004392:	7ae2                	ld	s5,56(sp)
    80004394:	7b42                	ld	s6,48(sp)
    80004396:	7ba2                	ld	s7,40(sp)
    80004398:	7c02                	ld	s8,32(sp)
    8000439a:	6ce2                	ld	s9,24(sp)
    8000439c:	6d42                	ld	s10,16(sp)
    8000439e:	6da2                	ld	s11,8(sp)
    800043a0:	6165                	addi	sp,sp,112
    800043a2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043a4:	8a5e                	mv	s4,s7
    800043a6:	bfc9                	j	80004378 <writei+0xe2>
    return -1;
    800043a8:	557d                	li	a0,-1
}
    800043aa:	8082                	ret
    return -1;
    800043ac:	557d                	li	a0,-1
    800043ae:	bfe1                	j	80004386 <writei+0xf0>
    return -1;
    800043b0:	557d                	li	a0,-1
    800043b2:	bfd1                	j	80004386 <writei+0xf0>

00000000800043b4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043b4:	1141                	addi	sp,sp,-16
    800043b6:	e406                	sd	ra,8(sp)
    800043b8:	e022                	sd	s0,0(sp)
    800043ba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043bc:	4639                	li	a2,14
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	9fa080e7          	jalr	-1542(ra) # 80000db8 <strncmp>
}
    800043c6:	60a2                	ld	ra,8(sp)
    800043c8:	6402                	ld	s0,0(sp)
    800043ca:	0141                	addi	sp,sp,16
    800043cc:	8082                	ret

00000000800043ce <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043ce:	7139                	addi	sp,sp,-64
    800043d0:	fc06                	sd	ra,56(sp)
    800043d2:	f822                	sd	s0,48(sp)
    800043d4:	f426                	sd	s1,40(sp)
    800043d6:	f04a                	sd	s2,32(sp)
    800043d8:	ec4e                	sd	s3,24(sp)
    800043da:	e852                	sd	s4,16(sp)
    800043dc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043de:	04451703          	lh	a4,68(a0)
    800043e2:	4785                	li	a5,1
    800043e4:	00f71a63          	bne	a4,a5,800043f8 <dirlookup+0x2a>
    800043e8:	892a                	mv	s2,a0
    800043ea:	89ae                	mv	s3,a1
    800043ec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ee:	457c                	lw	a5,76(a0)
    800043f0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043f2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043f4:	e79d                	bnez	a5,80004422 <dirlookup+0x54>
    800043f6:	a8a5                	j	8000446e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043f8:	00004517          	auipc	a0,0x4
    800043fc:	2c850513          	addi	a0,a0,712 # 800086c0 <syscalls+0x1c8>
    80004400:	ffffc097          	auipc	ra,0xffffc
    80004404:	13e080e7          	jalr	318(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004408:	00004517          	auipc	a0,0x4
    8000440c:	2d050513          	addi	a0,a0,720 # 800086d8 <syscalls+0x1e0>
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	12e080e7          	jalr	302(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004418:	24c1                	addiw	s1,s1,16
    8000441a:	04c92783          	lw	a5,76(s2)
    8000441e:	04f4f763          	bgeu	s1,a5,8000446c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004422:	4741                	li	a4,16
    80004424:	86a6                	mv	a3,s1
    80004426:	fc040613          	addi	a2,s0,-64
    8000442a:	4581                	li	a1,0
    8000442c:	854a                	mv	a0,s2
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	d70080e7          	jalr	-656(ra) # 8000419e <readi>
    80004436:	47c1                	li	a5,16
    80004438:	fcf518e3          	bne	a0,a5,80004408 <dirlookup+0x3a>
    if(de.inum == 0)
    8000443c:	fc045783          	lhu	a5,-64(s0)
    80004440:	dfe1                	beqz	a5,80004418 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004442:	fc240593          	addi	a1,s0,-62
    80004446:	854e                	mv	a0,s3
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	f6c080e7          	jalr	-148(ra) # 800043b4 <namecmp>
    80004450:	f561                	bnez	a0,80004418 <dirlookup+0x4a>
      if(poff)
    80004452:	000a0463          	beqz	s4,8000445a <dirlookup+0x8c>
        *poff = off;
    80004456:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000445a:	fc045583          	lhu	a1,-64(s0)
    8000445e:	00092503          	lw	a0,0(s2)
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	754080e7          	jalr	1876(ra) # 80003bb6 <iget>
    8000446a:	a011                	j	8000446e <dirlookup+0xa0>
  return 0;
    8000446c:	4501                	li	a0,0
}
    8000446e:	70e2                	ld	ra,56(sp)
    80004470:	7442                	ld	s0,48(sp)
    80004472:	74a2                	ld	s1,40(sp)
    80004474:	7902                	ld	s2,32(sp)
    80004476:	69e2                	ld	s3,24(sp)
    80004478:	6a42                	ld	s4,16(sp)
    8000447a:	6121                	addi	sp,sp,64
    8000447c:	8082                	ret

000000008000447e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000447e:	711d                	addi	sp,sp,-96
    80004480:	ec86                	sd	ra,88(sp)
    80004482:	e8a2                	sd	s0,80(sp)
    80004484:	e4a6                	sd	s1,72(sp)
    80004486:	e0ca                	sd	s2,64(sp)
    80004488:	fc4e                	sd	s3,56(sp)
    8000448a:	f852                	sd	s4,48(sp)
    8000448c:	f456                	sd	s5,40(sp)
    8000448e:	f05a                	sd	s6,32(sp)
    80004490:	ec5e                	sd	s7,24(sp)
    80004492:	e862                	sd	s8,16(sp)
    80004494:	e466                	sd	s9,8(sp)
    80004496:	1080                	addi	s0,sp,96
    80004498:	84aa                	mv	s1,a0
    8000449a:	8b2e                	mv	s6,a1
    8000449c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000449e:	00054703          	lbu	a4,0(a0)
    800044a2:	02f00793          	li	a5,47
    800044a6:	02f70363          	beq	a4,a5,800044cc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	52e080e7          	jalr	1326(ra) # 800019d8 <myproc>
    800044b2:	17853503          	ld	a0,376(a0)
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	9f6080e7          	jalr	-1546(ra) # 80003eac <idup>
    800044be:	89aa                	mv	s3,a0
  while(*path == '/')
    800044c0:	02f00913          	li	s2,47
  len = path - s;
    800044c4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800044c6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044c8:	4c05                	li	s8,1
    800044ca:	a865                	j	80004582 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044cc:	4585                	li	a1,1
    800044ce:	4505                	li	a0,1
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	6e6080e7          	jalr	1766(ra) # 80003bb6 <iget>
    800044d8:	89aa                	mv	s3,a0
    800044da:	b7dd                	j	800044c0 <namex+0x42>
      iunlockput(ip);
    800044dc:	854e                	mv	a0,s3
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	c6e080e7          	jalr	-914(ra) # 8000414c <iunlockput>
      return 0;
    800044e6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044e8:	854e                	mv	a0,s3
    800044ea:	60e6                	ld	ra,88(sp)
    800044ec:	6446                	ld	s0,80(sp)
    800044ee:	64a6                	ld	s1,72(sp)
    800044f0:	6906                	ld	s2,64(sp)
    800044f2:	79e2                	ld	s3,56(sp)
    800044f4:	7a42                	ld	s4,48(sp)
    800044f6:	7aa2                	ld	s5,40(sp)
    800044f8:	7b02                	ld	s6,32(sp)
    800044fa:	6be2                	ld	s7,24(sp)
    800044fc:	6c42                	ld	s8,16(sp)
    800044fe:	6ca2                	ld	s9,8(sp)
    80004500:	6125                	addi	sp,sp,96
    80004502:	8082                	ret
      iunlock(ip);
    80004504:	854e                	mv	a0,s3
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	aa6080e7          	jalr	-1370(ra) # 80003fac <iunlock>
      return ip;
    8000450e:	bfe9                	j	800044e8 <namex+0x6a>
      iunlockput(ip);
    80004510:	854e                	mv	a0,s3
    80004512:	00000097          	auipc	ra,0x0
    80004516:	c3a080e7          	jalr	-966(ra) # 8000414c <iunlockput>
      return 0;
    8000451a:	89d2                	mv	s3,s4
    8000451c:	b7f1                	j	800044e8 <namex+0x6a>
  len = path - s;
    8000451e:	40b48633          	sub	a2,s1,a1
    80004522:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004526:	094cd463          	bge	s9,s4,800045ae <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000452a:	4639                	li	a2,14
    8000452c:	8556                	mv	a0,s5
    8000452e:	ffffd097          	auipc	ra,0xffffd
    80004532:	812080e7          	jalr	-2030(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004536:	0004c783          	lbu	a5,0(s1)
    8000453a:	01279763          	bne	a5,s2,80004548 <namex+0xca>
    path++;
    8000453e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004540:	0004c783          	lbu	a5,0(s1)
    80004544:	ff278de3          	beq	a5,s2,8000453e <namex+0xc0>
    ilock(ip);
    80004548:	854e                	mv	a0,s3
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	9a0080e7          	jalr	-1632(ra) # 80003eea <ilock>
    if(ip->type != T_DIR){
    80004552:	04499783          	lh	a5,68(s3)
    80004556:	f98793e3          	bne	a5,s8,800044dc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000455a:	000b0563          	beqz	s6,80004564 <namex+0xe6>
    8000455e:	0004c783          	lbu	a5,0(s1)
    80004562:	d3cd                	beqz	a5,80004504 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004564:	865e                	mv	a2,s7
    80004566:	85d6                	mv	a1,s5
    80004568:	854e                	mv	a0,s3
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	e64080e7          	jalr	-412(ra) # 800043ce <dirlookup>
    80004572:	8a2a                	mv	s4,a0
    80004574:	dd51                	beqz	a0,80004510 <namex+0x92>
    iunlockput(ip);
    80004576:	854e                	mv	a0,s3
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	bd4080e7          	jalr	-1068(ra) # 8000414c <iunlockput>
    ip = next;
    80004580:	89d2                	mv	s3,s4
  while(*path == '/')
    80004582:	0004c783          	lbu	a5,0(s1)
    80004586:	05279763          	bne	a5,s2,800045d4 <namex+0x156>
    path++;
    8000458a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000458c:	0004c783          	lbu	a5,0(s1)
    80004590:	ff278de3          	beq	a5,s2,8000458a <namex+0x10c>
  if(*path == 0)
    80004594:	c79d                	beqz	a5,800045c2 <namex+0x144>
    path++;
    80004596:	85a6                	mv	a1,s1
  len = path - s;
    80004598:	8a5e                	mv	s4,s7
    8000459a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000459c:	01278963          	beq	a5,s2,800045ae <namex+0x130>
    800045a0:	dfbd                	beqz	a5,8000451e <namex+0xa0>
    path++;
    800045a2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800045a4:	0004c783          	lbu	a5,0(s1)
    800045a8:	ff279ce3          	bne	a5,s2,800045a0 <namex+0x122>
    800045ac:	bf8d                	j	8000451e <namex+0xa0>
    memmove(name, s, len);
    800045ae:	2601                	sext.w	a2,a2
    800045b0:	8556                	mv	a0,s5
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	78e080e7          	jalr	1934(ra) # 80000d40 <memmove>
    name[len] = 0;
    800045ba:	9a56                	add	s4,s4,s5
    800045bc:	000a0023          	sb	zero,0(s4)
    800045c0:	bf9d                	j	80004536 <namex+0xb8>
  if(nameiparent){
    800045c2:	f20b03e3          	beqz	s6,800044e8 <namex+0x6a>
    iput(ip);
    800045c6:	854e                	mv	a0,s3
    800045c8:	00000097          	auipc	ra,0x0
    800045cc:	adc080e7          	jalr	-1316(ra) # 800040a4 <iput>
    return 0;
    800045d0:	4981                	li	s3,0
    800045d2:	bf19                	j	800044e8 <namex+0x6a>
  if(*path == 0)
    800045d4:	d7fd                	beqz	a5,800045c2 <namex+0x144>
  while(*path != '/' && *path != 0)
    800045d6:	0004c783          	lbu	a5,0(s1)
    800045da:	85a6                	mv	a1,s1
    800045dc:	b7d1                	j	800045a0 <namex+0x122>

00000000800045de <dirlink>:
{
    800045de:	7139                	addi	sp,sp,-64
    800045e0:	fc06                	sd	ra,56(sp)
    800045e2:	f822                	sd	s0,48(sp)
    800045e4:	f426                	sd	s1,40(sp)
    800045e6:	f04a                	sd	s2,32(sp)
    800045e8:	ec4e                	sd	s3,24(sp)
    800045ea:	e852                	sd	s4,16(sp)
    800045ec:	0080                	addi	s0,sp,64
    800045ee:	892a                	mv	s2,a0
    800045f0:	8a2e                	mv	s4,a1
    800045f2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045f4:	4601                	li	a2,0
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	dd8080e7          	jalr	-552(ra) # 800043ce <dirlookup>
    800045fe:	e93d                	bnez	a0,80004674 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004600:	04c92483          	lw	s1,76(s2)
    80004604:	c49d                	beqz	s1,80004632 <dirlink+0x54>
    80004606:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004608:	4741                	li	a4,16
    8000460a:	86a6                	mv	a3,s1
    8000460c:	fc040613          	addi	a2,s0,-64
    80004610:	4581                	li	a1,0
    80004612:	854a                	mv	a0,s2
    80004614:	00000097          	auipc	ra,0x0
    80004618:	b8a080e7          	jalr	-1142(ra) # 8000419e <readi>
    8000461c:	47c1                	li	a5,16
    8000461e:	06f51163          	bne	a0,a5,80004680 <dirlink+0xa2>
    if(de.inum == 0)
    80004622:	fc045783          	lhu	a5,-64(s0)
    80004626:	c791                	beqz	a5,80004632 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004628:	24c1                	addiw	s1,s1,16
    8000462a:	04c92783          	lw	a5,76(s2)
    8000462e:	fcf4ede3          	bltu	s1,a5,80004608 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004632:	4639                	li	a2,14
    80004634:	85d2                	mv	a1,s4
    80004636:	fc240513          	addi	a0,s0,-62
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	7ba080e7          	jalr	1978(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004642:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004646:	4741                	li	a4,16
    80004648:	86a6                	mv	a3,s1
    8000464a:	fc040613          	addi	a2,s0,-64
    8000464e:	4581                	li	a1,0
    80004650:	854a                	mv	a0,s2
    80004652:	00000097          	auipc	ra,0x0
    80004656:	c44080e7          	jalr	-956(ra) # 80004296 <writei>
    8000465a:	872a                	mv	a4,a0
    8000465c:	47c1                	li	a5,16
  return 0;
    8000465e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004660:	02f71863          	bne	a4,a5,80004690 <dirlink+0xb2>
}
    80004664:	70e2                	ld	ra,56(sp)
    80004666:	7442                	ld	s0,48(sp)
    80004668:	74a2                	ld	s1,40(sp)
    8000466a:	7902                	ld	s2,32(sp)
    8000466c:	69e2                	ld	s3,24(sp)
    8000466e:	6a42                	ld	s4,16(sp)
    80004670:	6121                	addi	sp,sp,64
    80004672:	8082                	ret
    iput(ip);
    80004674:	00000097          	auipc	ra,0x0
    80004678:	a30080e7          	jalr	-1488(ra) # 800040a4 <iput>
    return -1;
    8000467c:	557d                	li	a0,-1
    8000467e:	b7dd                	j	80004664 <dirlink+0x86>
      panic("dirlink read");
    80004680:	00004517          	auipc	a0,0x4
    80004684:	06850513          	addi	a0,a0,104 # 800086e8 <syscalls+0x1f0>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	eb6080e7          	jalr	-330(ra) # 8000053e <panic>
    panic("dirlink");
    80004690:	00004517          	auipc	a0,0x4
    80004694:	16850513          	addi	a0,a0,360 # 800087f8 <syscalls+0x300>
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	ea6080e7          	jalr	-346(ra) # 8000053e <panic>

00000000800046a0 <namei>:

struct inode*
namei(char *path)
{
    800046a0:	1101                	addi	sp,sp,-32
    800046a2:	ec06                	sd	ra,24(sp)
    800046a4:	e822                	sd	s0,16(sp)
    800046a6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046a8:	fe040613          	addi	a2,s0,-32
    800046ac:	4581                	li	a1,0
    800046ae:	00000097          	auipc	ra,0x0
    800046b2:	dd0080e7          	jalr	-560(ra) # 8000447e <namex>
}
    800046b6:	60e2                	ld	ra,24(sp)
    800046b8:	6442                	ld	s0,16(sp)
    800046ba:	6105                	addi	sp,sp,32
    800046bc:	8082                	ret

00000000800046be <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046be:	1141                	addi	sp,sp,-16
    800046c0:	e406                	sd	ra,8(sp)
    800046c2:	e022                	sd	s0,0(sp)
    800046c4:	0800                	addi	s0,sp,16
    800046c6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046c8:	4585                	li	a1,1
    800046ca:	00000097          	auipc	ra,0x0
    800046ce:	db4080e7          	jalr	-588(ra) # 8000447e <namex>
}
    800046d2:	60a2                	ld	ra,8(sp)
    800046d4:	6402                	ld	s0,0(sp)
    800046d6:	0141                	addi	sp,sp,16
    800046d8:	8082                	ret

00000000800046da <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046da:	1101                	addi	sp,sp,-32
    800046dc:	ec06                	sd	ra,24(sp)
    800046de:	e822                	sd	s0,16(sp)
    800046e0:	e426                	sd	s1,8(sp)
    800046e2:	e04a                	sd	s2,0(sp)
    800046e4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046e6:	0001d917          	auipc	s2,0x1d
    800046ea:	5aa90913          	addi	s2,s2,1450 # 80021c90 <log>
    800046ee:	01892583          	lw	a1,24(s2)
    800046f2:	02892503          	lw	a0,40(s2)
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	ff2080e7          	jalr	-14(ra) # 800036e8 <bread>
    800046fe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004700:	02c92683          	lw	a3,44(s2)
    80004704:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004706:	02d05763          	blez	a3,80004734 <write_head+0x5a>
    8000470a:	0001d797          	auipc	a5,0x1d
    8000470e:	5b678793          	addi	a5,a5,1462 # 80021cc0 <log+0x30>
    80004712:	05c50713          	addi	a4,a0,92
    80004716:	36fd                	addiw	a3,a3,-1
    80004718:	1682                	slli	a3,a3,0x20
    8000471a:	9281                	srli	a3,a3,0x20
    8000471c:	068a                	slli	a3,a3,0x2
    8000471e:	0001d617          	auipc	a2,0x1d
    80004722:	5a660613          	addi	a2,a2,1446 # 80021cc4 <log+0x34>
    80004726:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004728:	4390                	lw	a2,0(a5)
    8000472a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000472c:	0791                	addi	a5,a5,4
    8000472e:	0711                	addi	a4,a4,4
    80004730:	fed79ce3          	bne	a5,a3,80004728 <write_head+0x4e>
  }
  bwrite(buf);
    80004734:	8526                	mv	a0,s1
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	0a4080e7          	jalr	164(ra) # 800037da <bwrite>
  brelse(buf);
    8000473e:	8526                	mv	a0,s1
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	0d8080e7          	jalr	216(ra) # 80003818 <brelse>
}
    80004748:	60e2                	ld	ra,24(sp)
    8000474a:	6442                	ld	s0,16(sp)
    8000474c:	64a2                	ld	s1,8(sp)
    8000474e:	6902                	ld	s2,0(sp)
    80004750:	6105                	addi	sp,sp,32
    80004752:	8082                	ret

0000000080004754 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004754:	0001d797          	auipc	a5,0x1d
    80004758:	5687a783          	lw	a5,1384(a5) # 80021cbc <log+0x2c>
    8000475c:	0af05d63          	blez	a5,80004816 <install_trans+0xc2>
{
    80004760:	7139                	addi	sp,sp,-64
    80004762:	fc06                	sd	ra,56(sp)
    80004764:	f822                	sd	s0,48(sp)
    80004766:	f426                	sd	s1,40(sp)
    80004768:	f04a                	sd	s2,32(sp)
    8000476a:	ec4e                	sd	s3,24(sp)
    8000476c:	e852                	sd	s4,16(sp)
    8000476e:	e456                	sd	s5,8(sp)
    80004770:	e05a                	sd	s6,0(sp)
    80004772:	0080                	addi	s0,sp,64
    80004774:	8b2a                	mv	s6,a0
    80004776:	0001da97          	auipc	s5,0x1d
    8000477a:	54aa8a93          	addi	s5,s5,1354 # 80021cc0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000477e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004780:	0001d997          	auipc	s3,0x1d
    80004784:	51098993          	addi	s3,s3,1296 # 80021c90 <log>
    80004788:	a035                	j	800047b4 <install_trans+0x60>
      bunpin(dbuf);
    8000478a:	8526                	mv	a0,s1
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	166080e7          	jalr	358(ra) # 800038f2 <bunpin>
    brelse(lbuf);
    80004794:	854a                	mv	a0,s2
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	082080e7          	jalr	130(ra) # 80003818 <brelse>
    brelse(dbuf);
    8000479e:	8526                	mv	a0,s1
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	078080e7          	jalr	120(ra) # 80003818 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047a8:	2a05                	addiw	s4,s4,1
    800047aa:	0a91                	addi	s5,s5,4
    800047ac:	02c9a783          	lw	a5,44(s3)
    800047b0:	04fa5963          	bge	s4,a5,80004802 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047b4:	0189a583          	lw	a1,24(s3)
    800047b8:	014585bb          	addw	a1,a1,s4
    800047bc:	2585                	addiw	a1,a1,1
    800047be:	0289a503          	lw	a0,40(s3)
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	f26080e7          	jalr	-218(ra) # 800036e8 <bread>
    800047ca:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047cc:	000aa583          	lw	a1,0(s5)
    800047d0:	0289a503          	lw	a0,40(s3)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	f14080e7          	jalr	-236(ra) # 800036e8 <bread>
    800047dc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047de:	40000613          	li	a2,1024
    800047e2:	05890593          	addi	a1,s2,88
    800047e6:	05850513          	addi	a0,a0,88
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	556080e7          	jalr	1366(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800047f2:	8526                	mv	a0,s1
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	fe6080e7          	jalr	-26(ra) # 800037da <bwrite>
    if(recovering == 0)
    800047fc:	f80b1ce3          	bnez	s6,80004794 <install_trans+0x40>
    80004800:	b769                	j	8000478a <install_trans+0x36>
}
    80004802:	70e2                	ld	ra,56(sp)
    80004804:	7442                	ld	s0,48(sp)
    80004806:	74a2                	ld	s1,40(sp)
    80004808:	7902                	ld	s2,32(sp)
    8000480a:	69e2                	ld	s3,24(sp)
    8000480c:	6a42                	ld	s4,16(sp)
    8000480e:	6aa2                	ld	s5,8(sp)
    80004810:	6b02                	ld	s6,0(sp)
    80004812:	6121                	addi	sp,sp,64
    80004814:	8082                	ret
    80004816:	8082                	ret

0000000080004818 <initlog>:
{
    80004818:	7179                	addi	sp,sp,-48
    8000481a:	f406                	sd	ra,40(sp)
    8000481c:	f022                	sd	s0,32(sp)
    8000481e:	ec26                	sd	s1,24(sp)
    80004820:	e84a                	sd	s2,16(sp)
    80004822:	e44e                	sd	s3,8(sp)
    80004824:	1800                	addi	s0,sp,48
    80004826:	892a                	mv	s2,a0
    80004828:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000482a:	0001d497          	auipc	s1,0x1d
    8000482e:	46648493          	addi	s1,s1,1126 # 80021c90 <log>
    80004832:	00004597          	auipc	a1,0x4
    80004836:	ec658593          	addi	a1,a1,-314 # 800086f8 <syscalls+0x200>
    8000483a:	8526                	mv	a0,s1
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	318080e7          	jalr	792(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004844:	0149a583          	lw	a1,20(s3)
    80004848:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000484a:	0109a783          	lw	a5,16(s3)
    8000484e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004850:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004854:	854a                	mv	a0,s2
    80004856:	fffff097          	auipc	ra,0xfffff
    8000485a:	e92080e7          	jalr	-366(ra) # 800036e8 <bread>
  log.lh.n = lh->n;
    8000485e:	4d3c                	lw	a5,88(a0)
    80004860:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004862:	02f05563          	blez	a5,8000488c <initlog+0x74>
    80004866:	05c50713          	addi	a4,a0,92
    8000486a:	0001d697          	auipc	a3,0x1d
    8000486e:	45668693          	addi	a3,a3,1110 # 80021cc0 <log+0x30>
    80004872:	37fd                	addiw	a5,a5,-1
    80004874:	1782                	slli	a5,a5,0x20
    80004876:	9381                	srli	a5,a5,0x20
    80004878:	078a                	slli	a5,a5,0x2
    8000487a:	06050613          	addi	a2,a0,96
    8000487e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004880:	4310                	lw	a2,0(a4)
    80004882:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004884:	0711                	addi	a4,a4,4
    80004886:	0691                	addi	a3,a3,4
    80004888:	fef71ce3          	bne	a4,a5,80004880 <initlog+0x68>
  brelse(buf);
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	f8c080e7          	jalr	-116(ra) # 80003818 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004894:	4505                	li	a0,1
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	ebe080e7          	jalr	-322(ra) # 80004754 <install_trans>
  log.lh.n = 0;
    8000489e:	0001d797          	auipc	a5,0x1d
    800048a2:	4007af23          	sw	zero,1054(a5) # 80021cbc <log+0x2c>
  write_head(); // clear the log
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	e34080e7          	jalr	-460(ra) # 800046da <write_head>
}
    800048ae:	70a2                	ld	ra,40(sp)
    800048b0:	7402                	ld	s0,32(sp)
    800048b2:	64e2                	ld	s1,24(sp)
    800048b4:	6942                	ld	s2,16(sp)
    800048b6:	69a2                	ld	s3,8(sp)
    800048b8:	6145                	addi	sp,sp,48
    800048ba:	8082                	ret

00000000800048bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048bc:	1101                	addi	sp,sp,-32
    800048be:	ec06                	sd	ra,24(sp)
    800048c0:	e822                	sd	s0,16(sp)
    800048c2:	e426                	sd	s1,8(sp)
    800048c4:	e04a                	sd	s2,0(sp)
    800048c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048c8:	0001d517          	auipc	a0,0x1d
    800048cc:	3c850513          	addi	a0,a0,968 # 80021c90 <log>
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	314080e7          	jalr	788(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800048d8:	0001d497          	auipc	s1,0x1d
    800048dc:	3b848493          	addi	s1,s1,952 # 80021c90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048e0:	4979                	li	s2,30
    800048e2:	a039                	j	800048f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800048e4:	85a6                	mv	a1,s1
    800048e6:	8526                	mv	a0,s1
    800048e8:	ffffe097          	auipc	ra,0xffffe
    800048ec:	b88080e7          	jalr	-1144(ra) # 80002470 <sleep>
    if(log.committing){
    800048f0:	50dc                	lw	a5,36(s1)
    800048f2:	fbed                	bnez	a5,800048e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048f4:	509c                	lw	a5,32(s1)
    800048f6:	0017871b          	addiw	a4,a5,1
    800048fa:	0007069b          	sext.w	a3,a4
    800048fe:	0027179b          	slliw	a5,a4,0x2
    80004902:	9fb9                	addw	a5,a5,a4
    80004904:	0017979b          	slliw	a5,a5,0x1
    80004908:	54d8                	lw	a4,44(s1)
    8000490a:	9fb9                	addw	a5,a5,a4
    8000490c:	00f95963          	bge	s2,a5,8000491e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004910:	85a6                	mv	a1,s1
    80004912:	8526                	mv	a0,s1
    80004914:	ffffe097          	auipc	ra,0xffffe
    80004918:	b5c080e7          	jalr	-1188(ra) # 80002470 <sleep>
    8000491c:	bfd1                	j	800048f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000491e:	0001d517          	auipc	a0,0x1d
    80004922:	37250513          	addi	a0,a0,882 # 80021c90 <log>
    80004926:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	370080e7          	jalr	880(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004930:	60e2                	ld	ra,24(sp)
    80004932:	6442                	ld	s0,16(sp)
    80004934:	64a2                	ld	s1,8(sp)
    80004936:	6902                	ld	s2,0(sp)
    80004938:	6105                	addi	sp,sp,32
    8000493a:	8082                	ret

000000008000493c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000493c:	7139                	addi	sp,sp,-64
    8000493e:	fc06                	sd	ra,56(sp)
    80004940:	f822                	sd	s0,48(sp)
    80004942:	f426                	sd	s1,40(sp)
    80004944:	f04a                	sd	s2,32(sp)
    80004946:	ec4e                	sd	s3,24(sp)
    80004948:	e852                	sd	s4,16(sp)
    8000494a:	e456                	sd	s5,8(sp)
    8000494c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000494e:	0001d497          	auipc	s1,0x1d
    80004952:	34248493          	addi	s1,s1,834 # 80021c90 <log>
    80004956:	8526                	mv	a0,s1
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	28c080e7          	jalr	652(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004960:	509c                	lw	a5,32(s1)
    80004962:	37fd                	addiw	a5,a5,-1
    80004964:	0007891b          	sext.w	s2,a5
    80004968:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000496a:	50dc                	lw	a5,36(s1)
    8000496c:	efb9                	bnez	a5,800049ca <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000496e:	06091663          	bnez	s2,800049da <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004972:	0001d497          	auipc	s1,0x1d
    80004976:	31e48493          	addi	s1,s1,798 # 80021c90 <log>
    8000497a:	4785                	li	a5,1
    8000497c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000497e:	8526                	mv	a0,s1
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	318080e7          	jalr	792(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004988:	54dc                	lw	a5,44(s1)
    8000498a:	06f04763          	bgtz	a5,800049f8 <end_op+0xbc>
    acquire(&log.lock);
    8000498e:	0001d497          	auipc	s1,0x1d
    80004992:	30248493          	addi	s1,s1,770 # 80021c90 <log>
    80004996:	8526                	mv	a0,s1
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	24c080e7          	jalr	588(ra) # 80000be4 <acquire>
    log.committing = 0;
    800049a0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800049a4:	8526                	mv	a0,s1
    800049a6:	ffffe097          	auipc	ra,0xffffe
    800049aa:	cc2080e7          	jalr	-830(ra) # 80002668 <wakeup>
    release(&log.lock);
    800049ae:	8526                	mv	a0,s1
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	2e8080e7          	jalr	744(ra) # 80000c98 <release>
}
    800049b8:	70e2                	ld	ra,56(sp)
    800049ba:	7442                	ld	s0,48(sp)
    800049bc:	74a2                	ld	s1,40(sp)
    800049be:	7902                	ld	s2,32(sp)
    800049c0:	69e2                	ld	s3,24(sp)
    800049c2:	6a42                	ld	s4,16(sp)
    800049c4:	6aa2                	ld	s5,8(sp)
    800049c6:	6121                	addi	sp,sp,64
    800049c8:	8082                	ret
    panic("log.committing");
    800049ca:	00004517          	auipc	a0,0x4
    800049ce:	d3650513          	addi	a0,a0,-714 # 80008700 <syscalls+0x208>
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	b6c080e7          	jalr	-1172(ra) # 8000053e <panic>
    wakeup(&log);
    800049da:	0001d497          	auipc	s1,0x1d
    800049de:	2b648493          	addi	s1,s1,694 # 80021c90 <log>
    800049e2:	8526                	mv	a0,s1
    800049e4:	ffffe097          	auipc	ra,0xffffe
    800049e8:	c84080e7          	jalr	-892(ra) # 80002668 <wakeup>
  release(&log.lock);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	2aa080e7          	jalr	682(ra) # 80000c98 <release>
  if(do_commit){
    800049f6:	b7c9                	j	800049b8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049f8:	0001da97          	auipc	s5,0x1d
    800049fc:	2c8a8a93          	addi	s5,s5,712 # 80021cc0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a00:	0001da17          	auipc	s4,0x1d
    80004a04:	290a0a13          	addi	s4,s4,656 # 80021c90 <log>
    80004a08:	018a2583          	lw	a1,24(s4)
    80004a0c:	012585bb          	addw	a1,a1,s2
    80004a10:	2585                	addiw	a1,a1,1
    80004a12:	028a2503          	lw	a0,40(s4)
    80004a16:	fffff097          	auipc	ra,0xfffff
    80004a1a:	cd2080e7          	jalr	-814(ra) # 800036e8 <bread>
    80004a1e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a20:	000aa583          	lw	a1,0(s5)
    80004a24:	028a2503          	lw	a0,40(s4)
    80004a28:	fffff097          	auipc	ra,0xfffff
    80004a2c:	cc0080e7          	jalr	-832(ra) # 800036e8 <bread>
    80004a30:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a32:	40000613          	li	a2,1024
    80004a36:	05850593          	addi	a1,a0,88
    80004a3a:	05848513          	addi	a0,s1,88
    80004a3e:	ffffc097          	auipc	ra,0xffffc
    80004a42:	302080e7          	jalr	770(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004a46:	8526                	mv	a0,s1
    80004a48:	fffff097          	auipc	ra,0xfffff
    80004a4c:	d92080e7          	jalr	-622(ra) # 800037da <bwrite>
    brelse(from);
    80004a50:	854e                	mv	a0,s3
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	dc6080e7          	jalr	-570(ra) # 80003818 <brelse>
    brelse(to);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	fffff097          	auipc	ra,0xfffff
    80004a60:	dbc080e7          	jalr	-580(ra) # 80003818 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a64:	2905                	addiw	s2,s2,1
    80004a66:	0a91                	addi	s5,s5,4
    80004a68:	02ca2783          	lw	a5,44(s4)
    80004a6c:	f8f94ee3          	blt	s2,a5,80004a08 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	c6a080e7          	jalr	-918(ra) # 800046da <write_head>
    install_trans(0); // Now install writes to home locations
    80004a78:	4501                	li	a0,0
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	cda080e7          	jalr	-806(ra) # 80004754 <install_trans>
    log.lh.n = 0;
    80004a82:	0001d797          	auipc	a5,0x1d
    80004a86:	2207ad23          	sw	zero,570(a5) # 80021cbc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	c50080e7          	jalr	-944(ra) # 800046da <write_head>
    80004a92:	bdf5                	j	8000498e <end_op+0x52>

0000000080004a94 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a94:	1101                	addi	sp,sp,-32
    80004a96:	ec06                	sd	ra,24(sp)
    80004a98:	e822                	sd	s0,16(sp)
    80004a9a:	e426                	sd	s1,8(sp)
    80004a9c:	e04a                	sd	s2,0(sp)
    80004a9e:	1000                	addi	s0,sp,32
    80004aa0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004aa2:	0001d917          	auipc	s2,0x1d
    80004aa6:	1ee90913          	addi	s2,s2,494 # 80021c90 <log>
    80004aaa:	854a                	mv	a0,s2
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	138080e7          	jalr	312(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ab4:	02c92603          	lw	a2,44(s2)
    80004ab8:	47f5                	li	a5,29
    80004aba:	06c7c563          	blt	a5,a2,80004b24 <log_write+0x90>
    80004abe:	0001d797          	auipc	a5,0x1d
    80004ac2:	1ee7a783          	lw	a5,494(a5) # 80021cac <log+0x1c>
    80004ac6:	37fd                	addiw	a5,a5,-1
    80004ac8:	04f65e63          	bge	a2,a5,80004b24 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004acc:	0001d797          	auipc	a5,0x1d
    80004ad0:	1e47a783          	lw	a5,484(a5) # 80021cb0 <log+0x20>
    80004ad4:	06f05063          	blez	a5,80004b34 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ad8:	4781                	li	a5,0
    80004ada:	06c05563          	blez	a2,80004b44 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ade:	44cc                	lw	a1,12(s1)
    80004ae0:	0001d717          	auipc	a4,0x1d
    80004ae4:	1e070713          	addi	a4,a4,480 # 80021cc0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ae8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004aea:	4314                	lw	a3,0(a4)
    80004aec:	04b68c63          	beq	a3,a1,80004b44 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004af0:	2785                	addiw	a5,a5,1
    80004af2:	0711                	addi	a4,a4,4
    80004af4:	fef61be3          	bne	a2,a5,80004aea <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004af8:	0621                	addi	a2,a2,8
    80004afa:	060a                	slli	a2,a2,0x2
    80004afc:	0001d797          	auipc	a5,0x1d
    80004b00:	19478793          	addi	a5,a5,404 # 80021c90 <log>
    80004b04:	963e                	add	a2,a2,a5
    80004b06:	44dc                	lw	a5,12(s1)
    80004b08:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	daa080e7          	jalr	-598(ra) # 800038b6 <bpin>
    log.lh.n++;
    80004b14:	0001d717          	auipc	a4,0x1d
    80004b18:	17c70713          	addi	a4,a4,380 # 80021c90 <log>
    80004b1c:	575c                	lw	a5,44(a4)
    80004b1e:	2785                	addiw	a5,a5,1
    80004b20:	d75c                	sw	a5,44(a4)
    80004b22:	a835                	j	80004b5e <log_write+0xca>
    panic("too big a transaction");
    80004b24:	00004517          	auipc	a0,0x4
    80004b28:	bec50513          	addi	a0,a0,-1044 # 80008710 <syscalls+0x218>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	a12080e7          	jalr	-1518(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004b34:	00004517          	auipc	a0,0x4
    80004b38:	bf450513          	addi	a0,a0,-1036 # 80008728 <syscalls+0x230>
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	a02080e7          	jalr	-1534(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b44:	00878713          	addi	a4,a5,8
    80004b48:	00271693          	slli	a3,a4,0x2
    80004b4c:	0001d717          	auipc	a4,0x1d
    80004b50:	14470713          	addi	a4,a4,324 # 80021c90 <log>
    80004b54:	9736                	add	a4,a4,a3
    80004b56:	44d4                	lw	a3,12(s1)
    80004b58:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b5a:	faf608e3          	beq	a2,a5,80004b0a <log_write+0x76>
  }
  release(&log.lock);
    80004b5e:	0001d517          	auipc	a0,0x1d
    80004b62:	13250513          	addi	a0,a0,306 # 80021c90 <log>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	132080e7          	jalr	306(ra) # 80000c98 <release>
}
    80004b6e:	60e2                	ld	ra,24(sp)
    80004b70:	6442                	ld	s0,16(sp)
    80004b72:	64a2                	ld	s1,8(sp)
    80004b74:	6902                	ld	s2,0(sp)
    80004b76:	6105                	addi	sp,sp,32
    80004b78:	8082                	ret

0000000080004b7a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b7a:	1101                	addi	sp,sp,-32
    80004b7c:	ec06                	sd	ra,24(sp)
    80004b7e:	e822                	sd	s0,16(sp)
    80004b80:	e426                	sd	s1,8(sp)
    80004b82:	e04a                	sd	s2,0(sp)
    80004b84:	1000                	addi	s0,sp,32
    80004b86:	84aa                	mv	s1,a0
    80004b88:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b8a:	00004597          	auipc	a1,0x4
    80004b8e:	bbe58593          	addi	a1,a1,-1090 # 80008748 <syscalls+0x250>
    80004b92:	0521                	addi	a0,a0,8
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	fc0080e7          	jalr	-64(ra) # 80000b54 <initlock>
  lk->name = name;
    80004b9c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ba0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ba4:	0204a423          	sw	zero,40(s1)
}
    80004ba8:	60e2                	ld	ra,24(sp)
    80004baa:	6442                	ld	s0,16(sp)
    80004bac:	64a2                	ld	s1,8(sp)
    80004bae:	6902                	ld	s2,0(sp)
    80004bb0:	6105                	addi	sp,sp,32
    80004bb2:	8082                	ret

0000000080004bb4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004bb4:	1101                	addi	sp,sp,-32
    80004bb6:	ec06                	sd	ra,24(sp)
    80004bb8:	e822                	sd	s0,16(sp)
    80004bba:	e426                	sd	s1,8(sp)
    80004bbc:	e04a                	sd	s2,0(sp)
    80004bbe:	1000                	addi	s0,sp,32
    80004bc0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bc2:	00850913          	addi	s2,a0,8
    80004bc6:	854a                	mv	a0,s2
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	01c080e7          	jalr	28(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004bd0:	409c                	lw	a5,0(s1)
    80004bd2:	cb89                	beqz	a5,80004be4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bd4:	85ca                	mv	a1,s2
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	ffffe097          	auipc	ra,0xffffe
    80004bdc:	898080e7          	jalr	-1896(ra) # 80002470 <sleep>
  while (lk->locked) {
    80004be0:	409c                	lw	a5,0(s1)
    80004be2:	fbed                	bnez	a5,80004bd4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004be4:	4785                	li	a5,1
    80004be6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004be8:	ffffd097          	auipc	ra,0xffffd
    80004bec:	df0080e7          	jalr	-528(ra) # 800019d8 <myproc>
    80004bf0:	591c                	lw	a5,48(a0)
    80004bf2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bf4:	854a                	mv	a0,s2
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	0a2080e7          	jalr	162(ra) # 80000c98 <release>
}
    80004bfe:	60e2                	ld	ra,24(sp)
    80004c00:	6442                	ld	s0,16(sp)
    80004c02:	64a2                	ld	s1,8(sp)
    80004c04:	6902                	ld	s2,0(sp)
    80004c06:	6105                	addi	sp,sp,32
    80004c08:	8082                	ret

0000000080004c0a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c0a:	1101                	addi	sp,sp,-32
    80004c0c:	ec06                	sd	ra,24(sp)
    80004c0e:	e822                	sd	s0,16(sp)
    80004c10:	e426                	sd	s1,8(sp)
    80004c12:	e04a                	sd	s2,0(sp)
    80004c14:	1000                	addi	s0,sp,32
    80004c16:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c18:	00850913          	addi	s2,a0,8
    80004c1c:	854a                	mv	a0,s2
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	fc6080e7          	jalr	-58(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004c26:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c2a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffe097          	auipc	ra,0xffffe
    80004c34:	a38080e7          	jalr	-1480(ra) # 80002668 <wakeup>
  release(&lk->lk);
    80004c38:	854a                	mv	a0,s2
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	05e080e7          	jalr	94(ra) # 80000c98 <release>
}
    80004c42:	60e2                	ld	ra,24(sp)
    80004c44:	6442                	ld	s0,16(sp)
    80004c46:	64a2                	ld	s1,8(sp)
    80004c48:	6902                	ld	s2,0(sp)
    80004c4a:	6105                	addi	sp,sp,32
    80004c4c:	8082                	ret

0000000080004c4e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c4e:	7179                	addi	sp,sp,-48
    80004c50:	f406                	sd	ra,40(sp)
    80004c52:	f022                	sd	s0,32(sp)
    80004c54:	ec26                	sd	s1,24(sp)
    80004c56:	e84a                	sd	s2,16(sp)
    80004c58:	e44e                	sd	s3,8(sp)
    80004c5a:	1800                	addi	s0,sp,48
    80004c5c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c5e:	00850913          	addi	s2,a0,8
    80004c62:	854a                	mv	a0,s2
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	f80080e7          	jalr	-128(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c6c:	409c                	lw	a5,0(s1)
    80004c6e:	ef99                	bnez	a5,80004c8c <holdingsleep+0x3e>
    80004c70:	4481                	li	s1,0
  release(&lk->lk);
    80004c72:	854a                	mv	a0,s2
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	024080e7          	jalr	36(ra) # 80000c98 <release>
  return r;
}
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	70a2                	ld	ra,40(sp)
    80004c80:	7402                	ld	s0,32(sp)
    80004c82:	64e2                	ld	s1,24(sp)
    80004c84:	6942                	ld	s2,16(sp)
    80004c86:	69a2                	ld	s3,8(sp)
    80004c88:	6145                	addi	sp,sp,48
    80004c8a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c8c:	0284a983          	lw	s3,40(s1)
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	d48080e7          	jalr	-696(ra) # 800019d8 <myproc>
    80004c98:	5904                	lw	s1,48(a0)
    80004c9a:	413484b3          	sub	s1,s1,s3
    80004c9e:	0014b493          	seqz	s1,s1
    80004ca2:	bfc1                	j	80004c72 <holdingsleep+0x24>

0000000080004ca4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ca4:	1141                	addi	sp,sp,-16
    80004ca6:	e406                	sd	ra,8(sp)
    80004ca8:	e022                	sd	s0,0(sp)
    80004caa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004cac:	00004597          	auipc	a1,0x4
    80004cb0:	aac58593          	addi	a1,a1,-1364 # 80008758 <syscalls+0x260>
    80004cb4:	0001d517          	auipc	a0,0x1d
    80004cb8:	12450513          	addi	a0,a0,292 # 80021dd8 <ftable>
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	e98080e7          	jalr	-360(ra) # 80000b54 <initlock>
}
    80004cc4:	60a2                	ld	ra,8(sp)
    80004cc6:	6402                	ld	s0,0(sp)
    80004cc8:	0141                	addi	sp,sp,16
    80004cca:	8082                	ret

0000000080004ccc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ccc:	1101                	addi	sp,sp,-32
    80004cce:	ec06                	sd	ra,24(sp)
    80004cd0:	e822                	sd	s0,16(sp)
    80004cd2:	e426                	sd	s1,8(sp)
    80004cd4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004cd6:	0001d517          	auipc	a0,0x1d
    80004cda:	10250513          	addi	a0,a0,258 # 80021dd8 <ftable>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	f06080e7          	jalr	-250(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ce6:	0001d497          	auipc	s1,0x1d
    80004cea:	10a48493          	addi	s1,s1,266 # 80021df0 <ftable+0x18>
    80004cee:	0001e717          	auipc	a4,0x1e
    80004cf2:	0a270713          	addi	a4,a4,162 # 80022d90 <ftable+0xfb8>
    if(f->ref == 0){
    80004cf6:	40dc                	lw	a5,4(s1)
    80004cf8:	cf99                	beqz	a5,80004d16 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cfa:	02848493          	addi	s1,s1,40
    80004cfe:	fee49ce3          	bne	s1,a4,80004cf6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d02:	0001d517          	auipc	a0,0x1d
    80004d06:	0d650513          	addi	a0,a0,214 # 80021dd8 <ftable>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	f8e080e7          	jalr	-114(ra) # 80000c98 <release>
  return 0;
    80004d12:	4481                	li	s1,0
    80004d14:	a819                	j	80004d2a <filealloc+0x5e>
      f->ref = 1;
    80004d16:	4785                	li	a5,1
    80004d18:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d1a:	0001d517          	auipc	a0,0x1d
    80004d1e:	0be50513          	addi	a0,a0,190 # 80021dd8 <ftable>
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	f76080e7          	jalr	-138(ra) # 80000c98 <release>
}
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	60e2                	ld	ra,24(sp)
    80004d2e:	6442                	ld	s0,16(sp)
    80004d30:	64a2                	ld	s1,8(sp)
    80004d32:	6105                	addi	sp,sp,32
    80004d34:	8082                	ret

0000000080004d36 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d36:	1101                	addi	sp,sp,-32
    80004d38:	ec06                	sd	ra,24(sp)
    80004d3a:	e822                	sd	s0,16(sp)
    80004d3c:	e426                	sd	s1,8(sp)
    80004d3e:	1000                	addi	s0,sp,32
    80004d40:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d42:	0001d517          	auipc	a0,0x1d
    80004d46:	09650513          	addi	a0,a0,150 # 80021dd8 <ftable>
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	e9a080e7          	jalr	-358(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004d52:	40dc                	lw	a5,4(s1)
    80004d54:	02f05263          	blez	a5,80004d78 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d58:	2785                	addiw	a5,a5,1
    80004d5a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d5c:	0001d517          	auipc	a0,0x1d
    80004d60:	07c50513          	addi	a0,a0,124 # 80021dd8 <ftable>
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	f34080e7          	jalr	-204(ra) # 80000c98 <release>
  return f;
}
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	60e2                	ld	ra,24(sp)
    80004d70:	6442                	ld	s0,16(sp)
    80004d72:	64a2                	ld	s1,8(sp)
    80004d74:	6105                	addi	sp,sp,32
    80004d76:	8082                	ret
    panic("filedup");
    80004d78:	00004517          	auipc	a0,0x4
    80004d7c:	9e850513          	addi	a0,a0,-1560 # 80008760 <syscalls+0x268>
    80004d80:	ffffb097          	auipc	ra,0xffffb
    80004d84:	7be080e7          	jalr	1982(ra) # 8000053e <panic>

0000000080004d88 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d88:	7139                	addi	sp,sp,-64
    80004d8a:	fc06                	sd	ra,56(sp)
    80004d8c:	f822                	sd	s0,48(sp)
    80004d8e:	f426                	sd	s1,40(sp)
    80004d90:	f04a                	sd	s2,32(sp)
    80004d92:	ec4e                	sd	s3,24(sp)
    80004d94:	e852                	sd	s4,16(sp)
    80004d96:	e456                	sd	s5,8(sp)
    80004d98:	0080                	addi	s0,sp,64
    80004d9a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d9c:	0001d517          	auipc	a0,0x1d
    80004da0:	03c50513          	addi	a0,a0,60 # 80021dd8 <ftable>
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	e40080e7          	jalr	-448(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004dac:	40dc                	lw	a5,4(s1)
    80004dae:	06f05163          	blez	a5,80004e10 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004db2:	37fd                	addiw	a5,a5,-1
    80004db4:	0007871b          	sext.w	a4,a5
    80004db8:	c0dc                	sw	a5,4(s1)
    80004dba:	06e04363          	bgtz	a4,80004e20 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004dbe:	0004a903          	lw	s2,0(s1)
    80004dc2:	0094ca83          	lbu	s5,9(s1)
    80004dc6:	0104ba03          	ld	s4,16(s1)
    80004dca:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004dce:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dd2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004dd6:	0001d517          	auipc	a0,0x1d
    80004dda:	00250513          	addi	a0,a0,2 # 80021dd8 <ftable>
    80004dde:	ffffc097          	auipc	ra,0xffffc
    80004de2:	eba080e7          	jalr	-326(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004de6:	4785                	li	a5,1
    80004de8:	04f90d63          	beq	s2,a5,80004e42 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004dec:	3979                	addiw	s2,s2,-2
    80004dee:	4785                	li	a5,1
    80004df0:	0527e063          	bltu	a5,s2,80004e30 <fileclose+0xa8>
    begin_op();
    80004df4:	00000097          	auipc	ra,0x0
    80004df8:	ac8080e7          	jalr	-1336(ra) # 800048bc <begin_op>
    iput(ff.ip);
    80004dfc:	854e                	mv	a0,s3
    80004dfe:	fffff097          	auipc	ra,0xfffff
    80004e02:	2a6080e7          	jalr	678(ra) # 800040a4 <iput>
    end_op();
    80004e06:	00000097          	auipc	ra,0x0
    80004e0a:	b36080e7          	jalr	-1226(ra) # 8000493c <end_op>
    80004e0e:	a00d                	j	80004e30 <fileclose+0xa8>
    panic("fileclose");
    80004e10:	00004517          	auipc	a0,0x4
    80004e14:	95850513          	addi	a0,a0,-1704 # 80008768 <syscalls+0x270>
    80004e18:	ffffb097          	auipc	ra,0xffffb
    80004e1c:	726080e7          	jalr	1830(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e20:	0001d517          	auipc	a0,0x1d
    80004e24:	fb850513          	addi	a0,a0,-72 # 80021dd8 <ftable>
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	e70080e7          	jalr	-400(ra) # 80000c98 <release>
  }
}
    80004e30:	70e2                	ld	ra,56(sp)
    80004e32:	7442                	ld	s0,48(sp)
    80004e34:	74a2                	ld	s1,40(sp)
    80004e36:	7902                	ld	s2,32(sp)
    80004e38:	69e2                	ld	s3,24(sp)
    80004e3a:	6a42                	ld	s4,16(sp)
    80004e3c:	6aa2                	ld	s5,8(sp)
    80004e3e:	6121                	addi	sp,sp,64
    80004e40:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e42:	85d6                	mv	a1,s5
    80004e44:	8552                	mv	a0,s4
    80004e46:	00000097          	auipc	ra,0x0
    80004e4a:	34c080e7          	jalr	844(ra) # 80005192 <pipeclose>
    80004e4e:	b7cd                	j	80004e30 <fileclose+0xa8>

0000000080004e50 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e50:	715d                	addi	sp,sp,-80
    80004e52:	e486                	sd	ra,72(sp)
    80004e54:	e0a2                	sd	s0,64(sp)
    80004e56:	fc26                	sd	s1,56(sp)
    80004e58:	f84a                	sd	s2,48(sp)
    80004e5a:	f44e                	sd	s3,40(sp)
    80004e5c:	0880                	addi	s0,sp,80
    80004e5e:	84aa                	mv	s1,a0
    80004e60:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	b76080e7          	jalr	-1162(ra) # 800019d8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e6a:	409c                	lw	a5,0(s1)
    80004e6c:	37f9                	addiw	a5,a5,-2
    80004e6e:	4705                	li	a4,1
    80004e70:	04f76763          	bltu	a4,a5,80004ebe <filestat+0x6e>
    80004e74:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e76:	6c88                	ld	a0,24(s1)
    80004e78:	fffff097          	auipc	ra,0xfffff
    80004e7c:	072080e7          	jalr	114(ra) # 80003eea <ilock>
    stati(f->ip, &st);
    80004e80:	fb840593          	addi	a1,s0,-72
    80004e84:	6c88                	ld	a0,24(s1)
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	2ee080e7          	jalr	750(ra) # 80004174 <stati>
    iunlock(f->ip);
    80004e8e:	6c88                	ld	a0,24(s1)
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	11c080e7          	jalr	284(ra) # 80003fac <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e98:	46e1                	li	a3,24
    80004e9a:	fb840613          	addi	a2,s0,-72
    80004e9e:	85ce                	mv	a1,s3
    80004ea0:	07893503          	ld	a0,120(s2)
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	7d6080e7          	jalr	2006(ra) # 8000167a <copyout>
    80004eac:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004eb0:	60a6                	ld	ra,72(sp)
    80004eb2:	6406                	ld	s0,64(sp)
    80004eb4:	74e2                	ld	s1,56(sp)
    80004eb6:	7942                	ld	s2,48(sp)
    80004eb8:	79a2                	ld	s3,40(sp)
    80004eba:	6161                	addi	sp,sp,80
    80004ebc:	8082                	ret
  return -1;
    80004ebe:	557d                	li	a0,-1
    80004ec0:	bfc5                	j	80004eb0 <filestat+0x60>

0000000080004ec2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ec2:	7179                	addi	sp,sp,-48
    80004ec4:	f406                	sd	ra,40(sp)
    80004ec6:	f022                	sd	s0,32(sp)
    80004ec8:	ec26                	sd	s1,24(sp)
    80004eca:	e84a                	sd	s2,16(sp)
    80004ecc:	e44e                	sd	s3,8(sp)
    80004ece:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ed0:	00854783          	lbu	a5,8(a0)
    80004ed4:	c3d5                	beqz	a5,80004f78 <fileread+0xb6>
    80004ed6:	84aa                	mv	s1,a0
    80004ed8:	89ae                	mv	s3,a1
    80004eda:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004edc:	411c                	lw	a5,0(a0)
    80004ede:	4705                	li	a4,1
    80004ee0:	04e78963          	beq	a5,a4,80004f32 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ee4:	470d                	li	a4,3
    80004ee6:	04e78d63          	beq	a5,a4,80004f40 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eea:	4709                	li	a4,2
    80004eec:	06e79e63          	bne	a5,a4,80004f68 <fileread+0xa6>
    ilock(f->ip);
    80004ef0:	6d08                	ld	a0,24(a0)
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	ff8080e7          	jalr	-8(ra) # 80003eea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004efa:	874a                	mv	a4,s2
    80004efc:	5094                	lw	a3,32(s1)
    80004efe:	864e                	mv	a2,s3
    80004f00:	4585                	li	a1,1
    80004f02:	6c88                	ld	a0,24(s1)
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	29a080e7          	jalr	666(ra) # 8000419e <readi>
    80004f0c:	892a                	mv	s2,a0
    80004f0e:	00a05563          	blez	a0,80004f18 <fileread+0x56>
      f->off += r;
    80004f12:	509c                	lw	a5,32(s1)
    80004f14:	9fa9                	addw	a5,a5,a0
    80004f16:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f18:	6c88                	ld	a0,24(s1)
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	092080e7          	jalr	146(ra) # 80003fac <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f22:	854a                	mv	a0,s2
    80004f24:	70a2                	ld	ra,40(sp)
    80004f26:	7402                	ld	s0,32(sp)
    80004f28:	64e2                	ld	s1,24(sp)
    80004f2a:	6942                	ld	s2,16(sp)
    80004f2c:	69a2                	ld	s3,8(sp)
    80004f2e:	6145                	addi	sp,sp,48
    80004f30:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f32:	6908                	ld	a0,16(a0)
    80004f34:	00000097          	auipc	ra,0x0
    80004f38:	3c8080e7          	jalr	968(ra) # 800052fc <piperead>
    80004f3c:	892a                	mv	s2,a0
    80004f3e:	b7d5                	j	80004f22 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f40:	02451783          	lh	a5,36(a0)
    80004f44:	03079693          	slli	a3,a5,0x30
    80004f48:	92c1                	srli	a3,a3,0x30
    80004f4a:	4725                	li	a4,9
    80004f4c:	02d76863          	bltu	a4,a3,80004f7c <fileread+0xba>
    80004f50:	0792                	slli	a5,a5,0x4
    80004f52:	0001d717          	auipc	a4,0x1d
    80004f56:	de670713          	addi	a4,a4,-538 # 80021d38 <devsw>
    80004f5a:	97ba                	add	a5,a5,a4
    80004f5c:	639c                	ld	a5,0(a5)
    80004f5e:	c38d                	beqz	a5,80004f80 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f60:	4505                	li	a0,1
    80004f62:	9782                	jalr	a5
    80004f64:	892a                	mv	s2,a0
    80004f66:	bf75                	j	80004f22 <fileread+0x60>
    panic("fileread");
    80004f68:	00004517          	auipc	a0,0x4
    80004f6c:	81050513          	addi	a0,a0,-2032 # 80008778 <syscalls+0x280>
    80004f70:	ffffb097          	auipc	ra,0xffffb
    80004f74:	5ce080e7          	jalr	1486(ra) # 8000053e <panic>
    return -1;
    80004f78:	597d                	li	s2,-1
    80004f7a:	b765                	j	80004f22 <fileread+0x60>
      return -1;
    80004f7c:	597d                	li	s2,-1
    80004f7e:	b755                	j	80004f22 <fileread+0x60>
    80004f80:	597d                	li	s2,-1
    80004f82:	b745                	j	80004f22 <fileread+0x60>

0000000080004f84 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f84:	715d                	addi	sp,sp,-80
    80004f86:	e486                	sd	ra,72(sp)
    80004f88:	e0a2                	sd	s0,64(sp)
    80004f8a:	fc26                	sd	s1,56(sp)
    80004f8c:	f84a                	sd	s2,48(sp)
    80004f8e:	f44e                	sd	s3,40(sp)
    80004f90:	f052                	sd	s4,32(sp)
    80004f92:	ec56                	sd	s5,24(sp)
    80004f94:	e85a                	sd	s6,16(sp)
    80004f96:	e45e                	sd	s7,8(sp)
    80004f98:	e062                	sd	s8,0(sp)
    80004f9a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f9c:	00954783          	lbu	a5,9(a0)
    80004fa0:	10078663          	beqz	a5,800050ac <filewrite+0x128>
    80004fa4:	892a                	mv	s2,a0
    80004fa6:	8aae                	mv	s5,a1
    80004fa8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004faa:	411c                	lw	a5,0(a0)
    80004fac:	4705                	li	a4,1
    80004fae:	02e78263          	beq	a5,a4,80004fd2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fb2:	470d                	li	a4,3
    80004fb4:	02e78663          	beq	a5,a4,80004fe0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fb8:	4709                	li	a4,2
    80004fba:	0ee79163          	bne	a5,a4,8000509c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fbe:	0ac05d63          	blez	a2,80005078 <filewrite+0xf4>
    int i = 0;
    80004fc2:	4981                	li	s3,0
    80004fc4:	6b05                	lui	s6,0x1
    80004fc6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004fca:	6b85                	lui	s7,0x1
    80004fcc:	c00b8b9b          	addiw	s7,s7,-1024
    80004fd0:	a861                	j	80005068 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fd2:	6908                	ld	a0,16(a0)
    80004fd4:	00000097          	auipc	ra,0x0
    80004fd8:	22e080e7          	jalr	558(ra) # 80005202 <pipewrite>
    80004fdc:	8a2a                	mv	s4,a0
    80004fde:	a045                	j	8000507e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fe0:	02451783          	lh	a5,36(a0)
    80004fe4:	03079693          	slli	a3,a5,0x30
    80004fe8:	92c1                	srli	a3,a3,0x30
    80004fea:	4725                	li	a4,9
    80004fec:	0cd76263          	bltu	a4,a3,800050b0 <filewrite+0x12c>
    80004ff0:	0792                	slli	a5,a5,0x4
    80004ff2:	0001d717          	auipc	a4,0x1d
    80004ff6:	d4670713          	addi	a4,a4,-698 # 80021d38 <devsw>
    80004ffa:	97ba                	add	a5,a5,a4
    80004ffc:	679c                	ld	a5,8(a5)
    80004ffe:	cbdd                	beqz	a5,800050b4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005000:	4505                	li	a0,1
    80005002:	9782                	jalr	a5
    80005004:	8a2a                	mv	s4,a0
    80005006:	a8a5                	j	8000507e <filewrite+0xfa>
    80005008:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000500c:	00000097          	auipc	ra,0x0
    80005010:	8b0080e7          	jalr	-1872(ra) # 800048bc <begin_op>
      ilock(f->ip);
    80005014:	01893503          	ld	a0,24(s2)
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	ed2080e7          	jalr	-302(ra) # 80003eea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005020:	8762                	mv	a4,s8
    80005022:	02092683          	lw	a3,32(s2)
    80005026:	01598633          	add	a2,s3,s5
    8000502a:	4585                	li	a1,1
    8000502c:	01893503          	ld	a0,24(s2)
    80005030:	fffff097          	auipc	ra,0xfffff
    80005034:	266080e7          	jalr	614(ra) # 80004296 <writei>
    80005038:	84aa                	mv	s1,a0
    8000503a:	00a05763          	blez	a0,80005048 <filewrite+0xc4>
        f->off += r;
    8000503e:	02092783          	lw	a5,32(s2)
    80005042:	9fa9                	addw	a5,a5,a0
    80005044:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005048:	01893503          	ld	a0,24(s2)
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	f60080e7          	jalr	-160(ra) # 80003fac <iunlock>
      end_op();
    80005054:	00000097          	auipc	ra,0x0
    80005058:	8e8080e7          	jalr	-1816(ra) # 8000493c <end_op>

      if(r != n1){
    8000505c:	009c1f63          	bne	s8,s1,8000507a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005060:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005064:	0149db63          	bge	s3,s4,8000507a <filewrite+0xf6>
      int n1 = n - i;
    80005068:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000506c:	84be                	mv	s1,a5
    8000506e:	2781                	sext.w	a5,a5
    80005070:	f8fb5ce3          	bge	s6,a5,80005008 <filewrite+0x84>
    80005074:	84de                	mv	s1,s7
    80005076:	bf49                	j	80005008 <filewrite+0x84>
    int i = 0;
    80005078:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000507a:	013a1f63          	bne	s4,s3,80005098 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000507e:	8552                	mv	a0,s4
    80005080:	60a6                	ld	ra,72(sp)
    80005082:	6406                	ld	s0,64(sp)
    80005084:	74e2                	ld	s1,56(sp)
    80005086:	7942                	ld	s2,48(sp)
    80005088:	79a2                	ld	s3,40(sp)
    8000508a:	7a02                	ld	s4,32(sp)
    8000508c:	6ae2                	ld	s5,24(sp)
    8000508e:	6b42                	ld	s6,16(sp)
    80005090:	6ba2                	ld	s7,8(sp)
    80005092:	6c02                	ld	s8,0(sp)
    80005094:	6161                	addi	sp,sp,80
    80005096:	8082                	ret
    ret = (i == n ? n : -1);
    80005098:	5a7d                	li	s4,-1
    8000509a:	b7d5                	j	8000507e <filewrite+0xfa>
    panic("filewrite");
    8000509c:	00003517          	auipc	a0,0x3
    800050a0:	6ec50513          	addi	a0,a0,1772 # 80008788 <syscalls+0x290>
    800050a4:	ffffb097          	auipc	ra,0xffffb
    800050a8:	49a080e7          	jalr	1178(ra) # 8000053e <panic>
    return -1;
    800050ac:	5a7d                	li	s4,-1
    800050ae:	bfc1                	j	8000507e <filewrite+0xfa>
      return -1;
    800050b0:	5a7d                	li	s4,-1
    800050b2:	b7f1                	j	8000507e <filewrite+0xfa>
    800050b4:	5a7d                	li	s4,-1
    800050b6:	b7e1                	j	8000507e <filewrite+0xfa>

00000000800050b8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050b8:	7179                	addi	sp,sp,-48
    800050ba:	f406                	sd	ra,40(sp)
    800050bc:	f022                	sd	s0,32(sp)
    800050be:	ec26                	sd	s1,24(sp)
    800050c0:	e84a                	sd	s2,16(sp)
    800050c2:	e44e                	sd	s3,8(sp)
    800050c4:	e052                	sd	s4,0(sp)
    800050c6:	1800                	addi	s0,sp,48
    800050c8:	84aa                	mv	s1,a0
    800050ca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050cc:	0005b023          	sd	zero,0(a1)
    800050d0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050d4:	00000097          	auipc	ra,0x0
    800050d8:	bf8080e7          	jalr	-1032(ra) # 80004ccc <filealloc>
    800050dc:	e088                	sd	a0,0(s1)
    800050de:	c551                	beqz	a0,8000516a <pipealloc+0xb2>
    800050e0:	00000097          	auipc	ra,0x0
    800050e4:	bec080e7          	jalr	-1044(ra) # 80004ccc <filealloc>
    800050e8:	00aa3023          	sd	a0,0(s4)
    800050ec:	c92d                	beqz	a0,8000515e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	a06080e7          	jalr	-1530(ra) # 80000af4 <kalloc>
    800050f6:	892a                	mv	s2,a0
    800050f8:	c125                	beqz	a0,80005158 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050fa:	4985                	li	s3,1
    800050fc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005100:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005104:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005108:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000510c:	00003597          	auipc	a1,0x3
    80005110:	68c58593          	addi	a1,a1,1676 # 80008798 <syscalls+0x2a0>
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	a40080e7          	jalr	-1472(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000511c:	609c                	ld	a5,0(s1)
    8000511e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005122:	609c                	ld	a5,0(s1)
    80005124:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005128:	609c                	ld	a5,0(s1)
    8000512a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000512e:	609c                	ld	a5,0(s1)
    80005130:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005134:	000a3783          	ld	a5,0(s4)
    80005138:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000513c:	000a3783          	ld	a5,0(s4)
    80005140:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005144:	000a3783          	ld	a5,0(s4)
    80005148:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000514c:	000a3783          	ld	a5,0(s4)
    80005150:	0127b823          	sd	s2,16(a5)
  return 0;
    80005154:	4501                	li	a0,0
    80005156:	a025                	j	8000517e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005158:	6088                	ld	a0,0(s1)
    8000515a:	e501                	bnez	a0,80005162 <pipealloc+0xaa>
    8000515c:	a039                	j	8000516a <pipealloc+0xb2>
    8000515e:	6088                	ld	a0,0(s1)
    80005160:	c51d                	beqz	a0,8000518e <pipealloc+0xd6>
    fileclose(*f0);
    80005162:	00000097          	auipc	ra,0x0
    80005166:	c26080e7          	jalr	-986(ra) # 80004d88 <fileclose>
  if(*f1)
    8000516a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000516e:	557d                	li	a0,-1
  if(*f1)
    80005170:	c799                	beqz	a5,8000517e <pipealloc+0xc6>
    fileclose(*f1);
    80005172:	853e                	mv	a0,a5
    80005174:	00000097          	auipc	ra,0x0
    80005178:	c14080e7          	jalr	-1004(ra) # 80004d88 <fileclose>
  return -1;
    8000517c:	557d                	li	a0,-1
}
    8000517e:	70a2                	ld	ra,40(sp)
    80005180:	7402                	ld	s0,32(sp)
    80005182:	64e2                	ld	s1,24(sp)
    80005184:	6942                	ld	s2,16(sp)
    80005186:	69a2                	ld	s3,8(sp)
    80005188:	6a02                	ld	s4,0(sp)
    8000518a:	6145                	addi	sp,sp,48
    8000518c:	8082                	ret
  return -1;
    8000518e:	557d                	li	a0,-1
    80005190:	b7fd                	j	8000517e <pipealloc+0xc6>

0000000080005192 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005192:	1101                	addi	sp,sp,-32
    80005194:	ec06                	sd	ra,24(sp)
    80005196:	e822                	sd	s0,16(sp)
    80005198:	e426                	sd	s1,8(sp)
    8000519a:	e04a                	sd	s2,0(sp)
    8000519c:	1000                	addi	s0,sp,32
    8000519e:	84aa                	mv	s1,a0
    800051a0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051a2:	ffffc097          	auipc	ra,0xffffc
    800051a6:	a42080e7          	jalr	-1470(ra) # 80000be4 <acquire>
  if(writable){
    800051aa:	02090d63          	beqz	s2,800051e4 <pipeclose+0x52>
    pi->writeopen = 0;
    800051ae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051b2:	21848513          	addi	a0,s1,536
    800051b6:	ffffd097          	auipc	ra,0xffffd
    800051ba:	4b2080e7          	jalr	1202(ra) # 80002668 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800051be:	2204b783          	ld	a5,544(s1)
    800051c2:	eb95                	bnez	a5,800051f6 <pipeclose+0x64>
    release(&pi->lock);
    800051c4:	8526                	mv	a0,s1
    800051c6:	ffffc097          	auipc	ra,0xffffc
    800051ca:	ad2080e7          	jalr	-1326(ra) # 80000c98 <release>
    kfree((char*)pi);
    800051ce:	8526                	mv	a0,s1
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	828080e7          	jalr	-2008(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800051d8:	60e2                	ld	ra,24(sp)
    800051da:	6442                	ld	s0,16(sp)
    800051dc:	64a2                	ld	s1,8(sp)
    800051de:	6902                	ld	s2,0(sp)
    800051e0:	6105                	addi	sp,sp,32
    800051e2:	8082                	ret
    pi->readopen = 0;
    800051e4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051e8:	21c48513          	addi	a0,s1,540
    800051ec:	ffffd097          	auipc	ra,0xffffd
    800051f0:	47c080e7          	jalr	1148(ra) # 80002668 <wakeup>
    800051f4:	b7e9                	j	800051be <pipeclose+0x2c>
    release(&pi->lock);
    800051f6:	8526                	mv	a0,s1
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	aa0080e7          	jalr	-1376(ra) # 80000c98 <release>
}
    80005200:	bfe1                	j	800051d8 <pipeclose+0x46>

0000000080005202 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005202:	7159                	addi	sp,sp,-112
    80005204:	f486                	sd	ra,104(sp)
    80005206:	f0a2                	sd	s0,96(sp)
    80005208:	eca6                	sd	s1,88(sp)
    8000520a:	e8ca                	sd	s2,80(sp)
    8000520c:	e4ce                	sd	s3,72(sp)
    8000520e:	e0d2                	sd	s4,64(sp)
    80005210:	fc56                	sd	s5,56(sp)
    80005212:	f85a                	sd	s6,48(sp)
    80005214:	f45e                	sd	s7,40(sp)
    80005216:	f062                	sd	s8,32(sp)
    80005218:	ec66                	sd	s9,24(sp)
    8000521a:	1880                	addi	s0,sp,112
    8000521c:	84aa                	mv	s1,a0
    8000521e:	8aae                	mv	s5,a1
    80005220:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	7b6080e7          	jalr	1974(ra) # 800019d8 <myproc>
    8000522a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000522c:	8526                	mv	a0,s1
    8000522e:	ffffc097          	auipc	ra,0xffffc
    80005232:	9b6080e7          	jalr	-1610(ra) # 80000be4 <acquire>
  while(i < n){
    80005236:	0d405163          	blez	s4,800052f8 <pipewrite+0xf6>
    8000523a:	8ba6                	mv	s7,s1
  int i = 0;
    8000523c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000523e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005240:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005244:	21c48c13          	addi	s8,s1,540
    80005248:	a08d                	j	800052aa <pipewrite+0xa8>
      release(&pi->lock);
    8000524a:	8526                	mv	a0,s1
    8000524c:	ffffc097          	auipc	ra,0xffffc
    80005250:	a4c080e7          	jalr	-1460(ra) # 80000c98 <release>
      return -1;
    80005254:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005256:	854a                	mv	a0,s2
    80005258:	70a6                	ld	ra,104(sp)
    8000525a:	7406                	ld	s0,96(sp)
    8000525c:	64e6                	ld	s1,88(sp)
    8000525e:	6946                	ld	s2,80(sp)
    80005260:	69a6                	ld	s3,72(sp)
    80005262:	6a06                	ld	s4,64(sp)
    80005264:	7ae2                	ld	s5,56(sp)
    80005266:	7b42                	ld	s6,48(sp)
    80005268:	7ba2                	ld	s7,40(sp)
    8000526a:	7c02                	ld	s8,32(sp)
    8000526c:	6ce2                	ld	s9,24(sp)
    8000526e:	6165                	addi	sp,sp,112
    80005270:	8082                	ret
      wakeup(&pi->nread);
    80005272:	8566                	mv	a0,s9
    80005274:	ffffd097          	auipc	ra,0xffffd
    80005278:	3f4080e7          	jalr	1012(ra) # 80002668 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000527c:	85de                	mv	a1,s7
    8000527e:	8562                	mv	a0,s8
    80005280:	ffffd097          	auipc	ra,0xffffd
    80005284:	1f0080e7          	jalr	496(ra) # 80002470 <sleep>
    80005288:	a839                	j	800052a6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000528a:	21c4a783          	lw	a5,540(s1)
    8000528e:	0017871b          	addiw	a4,a5,1
    80005292:	20e4ae23          	sw	a4,540(s1)
    80005296:	1ff7f793          	andi	a5,a5,511
    8000529a:	97a6                	add	a5,a5,s1
    8000529c:	f9f44703          	lbu	a4,-97(s0)
    800052a0:	00e78c23          	sb	a4,24(a5)
      i++;
    800052a4:	2905                	addiw	s2,s2,1
  while(i < n){
    800052a6:	03495d63          	bge	s2,s4,800052e0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800052aa:	2204a783          	lw	a5,544(s1)
    800052ae:	dfd1                	beqz	a5,8000524a <pipewrite+0x48>
    800052b0:	0289a783          	lw	a5,40(s3)
    800052b4:	fbd9                	bnez	a5,8000524a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800052b6:	2184a783          	lw	a5,536(s1)
    800052ba:	21c4a703          	lw	a4,540(s1)
    800052be:	2007879b          	addiw	a5,a5,512
    800052c2:	faf708e3          	beq	a4,a5,80005272 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052c6:	4685                	li	a3,1
    800052c8:	01590633          	add	a2,s2,s5
    800052cc:	f9f40593          	addi	a1,s0,-97
    800052d0:	0789b503          	ld	a0,120(s3)
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	432080e7          	jalr	1074(ra) # 80001706 <copyin>
    800052dc:	fb6517e3          	bne	a0,s6,8000528a <pipewrite+0x88>
  wakeup(&pi->nread);
    800052e0:	21848513          	addi	a0,s1,536
    800052e4:	ffffd097          	auipc	ra,0xffffd
    800052e8:	384080e7          	jalr	900(ra) # 80002668 <wakeup>
  release(&pi->lock);
    800052ec:	8526                	mv	a0,s1
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	9aa080e7          	jalr	-1622(ra) # 80000c98 <release>
  return i;
    800052f6:	b785                	j	80005256 <pipewrite+0x54>
  int i = 0;
    800052f8:	4901                	li	s2,0
    800052fa:	b7dd                	j	800052e0 <pipewrite+0xde>

00000000800052fc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052fc:	715d                	addi	sp,sp,-80
    800052fe:	e486                	sd	ra,72(sp)
    80005300:	e0a2                	sd	s0,64(sp)
    80005302:	fc26                	sd	s1,56(sp)
    80005304:	f84a                	sd	s2,48(sp)
    80005306:	f44e                	sd	s3,40(sp)
    80005308:	f052                	sd	s4,32(sp)
    8000530a:	ec56                	sd	s5,24(sp)
    8000530c:	e85a                	sd	s6,16(sp)
    8000530e:	0880                	addi	s0,sp,80
    80005310:	84aa                	mv	s1,a0
    80005312:	892e                	mv	s2,a1
    80005314:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005316:	ffffc097          	auipc	ra,0xffffc
    8000531a:	6c2080e7          	jalr	1730(ra) # 800019d8 <myproc>
    8000531e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005320:	8b26                	mv	s6,s1
    80005322:	8526                	mv	a0,s1
    80005324:	ffffc097          	auipc	ra,0xffffc
    80005328:	8c0080e7          	jalr	-1856(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000532c:	2184a703          	lw	a4,536(s1)
    80005330:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005334:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005338:	02f71463          	bne	a4,a5,80005360 <piperead+0x64>
    8000533c:	2244a783          	lw	a5,548(s1)
    80005340:	c385                	beqz	a5,80005360 <piperead+0x64>
    if(pr->killed){
    80005342:	028a2783          	lw	a5,40(s4)
    80005346:	ebc1                	bnez	a5,800053d6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005348:	85da                	mv	a1,s6
    8000534a:	854e                	mv	a0,s3
    8000534c:	ffffd097          	auipc	ra,0xffffd
    80005350:	124080e7          	jalr	292(ra) # 80002470 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005354:	2184a703          	lw	a4,536(s1)
    80005358:	21c4a783          	lw	a5,540(s1)
    8000535c:	fef700e3          	beq	a4,a5,8000533c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005360:	09505263          	blez	s5,800053e4 <piperead+0xe8>
    80005364:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005366:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005368:	2184a783          	lw	a5,536(s1)
    8000536c:	21c4a703          	lw	a4,540(s1)
    80005370:	02f70d63          	beq	a4,a5,800053aa <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005374:	0017871b          	addiw	a4,a5,1
    80005378:	20e4ac23          	sw	a4,536(s1)
    8000537c:	1ff7f793          	andi	a5,a5,511
    80005380:	97a6                	add	a5,a5,s1
    80005382:	0187c783          	lbu	a5,24(a5)
    80005386:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000538a:	4685                	li	a3,1
    8000538c:	fbf40613          	addi	a2,s0,-65
    80005390:	85ca                	mv	a1,s2
    80005392:	078a3503          	ld	a0,120(s4)
    80005396:	ffffc097          	auipc	ra,0xffffc
    8000539a:	2e4080e7          	jalr	740(ra) # 8000167a <copyout>
    8000539e:	01650663          	beq	a0,s6,800053aa <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053a2:	2985                	addiw	s3,s3,1
    800053a4:	0905                	addi	s2,s2,1
    800053a6:	fd3a91e3          	bne	s5,s3,80005368 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800053aa:	21c48513          	addi	a0,s1,540
    800053ae:	ffffd097          	auipc	ra,0xffffd
    800053b2:	2ba080e7          	jalr	698(ra) # 80002668 <wakeup>
  release(&pi->lock);
    800053b6:	8526                	mv	a0,s1
    800053b8:	ffffc097          	auipc	ra,0xffffc
    800053bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
  return i;
}
    800053c0:	854e                	mv	a0,s3
    800053c2:	60a6                	ld	ra,72(sp)
    800053c4:	6406                	ld	s0,64(sp)
    800053c6:	74e2                	ld	s1,56(sp)
    800053c8:	7942                	ld	s2,48(sp)
    800053ca:	79a2                	ld	s3,40(sp)
    800053cc:	7a02                	ld	s4,32(sp)
    800053ce:	6ae2                	ld	s5,24(sp)
    800053d0:	6b42                	ld	s6,16(sp)
    800053d2:	6161                	addi	sp,sp,80
    800053d4:	8082                	ret
      release(&pi->lock);
    800053d6:	8526                	mv	a0,s1
    800053d8:	ffffc097          	auipc	ra,0xffffc
    800053dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
      return -1;
    800053e0:	59fd                	li	s3,-1
    800053e2:	bff9                	j	800053c0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053e4:	4981                	li	s3,0
    800053e6:	b7d1                	j	800053aa <piperead+0xae>

00000000800053e8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800053e8:	df010113          	addi	sp,sp,-528
    800053ec:	20113423          	sd	ra,520(sp)
    800053f0:	20813023          	sd	s0,512(sp)
    800053f4:	ffa6                	sd	s1,504(sp)
    800053f6:	fbca                	sd	s2,496(sp)
    800053f8:	f7ce                	sd	s3,488(sp)
    800053fa:	f3d2                	sd	s4,480(sp)
    800053fc:	efd6                	sd	s5,472(sp)
    800053fe:	ebda                	sd	s6,464(sp)
    80005400:	e7de                	sd	s7,456(sp)
    80005402:	e3e2                	sd	s8,448(sp)
    80005404:	ff66                	sd	s9,440(sp)
    80005406:	fb6a                	sd	s10,432(sp)
    80005408:	f76e                	sd	s11,424(sp)
    8000540a:	0c00                	addi	s0,sp,528
    8000540c:	84aa                	mv	s1,a0
    8000540e:	dea43c23          	sd	a0,-520(s0)
    80005412:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	5c2080e7          	jalr	1474(ra) # 800019d8 <myproc>
    8000541e:	892a                	mv	s2,a0

  begin_op();
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	49c080e7          	jalr	1180(ra) # 800048bc <begin_op>

  if((ip = namei(path)) == 0){
    80005428:	8526                	mv	a0,s1
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	276080e7          	jalr	630(ra) # 800046a0 <namei>
    80005432:	c92d                	beqz	a0,800054a4 <exec+0xbc>
    80005434:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	ab4080e7          	jalr	-1356(ra) # 80003eea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000543e:	04000713          	li	a4,64
    80005442:	4681                	li	a3,0
    80005444:	e5040613          	addi	a2,s0,-432
    80005448:	4581                	li	a1,0
    8000544a:	8526                	mv	a0,s1
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	d52080e7          	jalr	-686(ra) # 8000419e <readi>
    80005454:	04000793          	li	a5,64
    80005458:	00f51a63          	bne	a0,a5,8000546c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000545c:	e5042703          	lw	a4,-432(s0)
    80005460:	464c47b7          	lui	a5,0x464c4
    80005464:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005468:	04f70463          	beq	a4,a5,800054b0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000546c:	8526                	mv	a0,s1
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	cde080e7          	jalr	-802(ra) # 8000414c <iunlockput>
    end_op();
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	4c6080e7          	jalr	1222(ra) # 8000493c <end_op>
  }
  return -1;
    8000547e:	557d                	li	a0,-1
}
    80005480:	20813083          	ld	ra,520(sp)
    80005484:	20013403          	ld	s0,512(sp)
    80005488:	74fe                	ld	s1,504(sp)
    8000548a:	795e                	ld	s2,496(sp)
    8000548c:	79be                	ld	s3,488(sp)
    8000548e:	7a1e                	ld	s4,480(sp)
    80005490:	6afe                	ld	s5,472(sp)
    80005492:	6b5e                	ld	s6,464(sp)
    80005494:	6bbe                	ld	s7,456(sp)
    80005496:	6c1e                	ld	s8,448(sp)
    80005498:	7cfa                	ld	s9,440(sp)
    8000549a:	7d5a                	ld	s10,432(sp)
    8000549c:	7dba                	ld	s11,424(sp)
    8000549e:	21010113          	addi	sp,sp,528
    800054a2:	8082                	ret
    end_op();
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	498080e7          	jalr	1176(ra) # 8000493c <end_op>
    return -1;
    800054ac:	557d                	li	a0,-1
    800054ae:	bfc9                	j	80005480 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800054b0:	854a                	mv	a0,s2
    800054b2:	ffffc097          	auipc	ra,0xffffc
    800054b6:	5e0080e7          	jalr	1504(ra) # 80001a92 <proc_pagetable>
    800054ba:	8baa                	mv	s7,a0
    800054bc:	d945                	beqz	a0,8000546c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054be:	e7042983          	lw	s3,-400(s0)
    800054c2:	e8845783          	lhu	a5,-376(s0)
    800054c6:	c7ad                	beqz	a5,80005530 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054c8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054ca:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800054cc:	6c85                	lui	s9,0x1
    800054ce:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800054d2:	def43823          	sd	a5,-528(s0)
    800054d6:	a42d                	j	80005700 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054d8:	00003517          	auipc	a0,0x3
    800054dc:	2c850513          	addi	a0,a0,712 # 800087a0 <syscalls+0x2a8>
    800054e0:	ffffb097          	auipc	ra,0xffffb
    800054e4:	05e080e7          	jalr	94(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054e8:	8756                	mv	a4,s5
    800054ea:	012d86bb          	addw	a3,s11,s2
    800054ee:	4581                	li	a1,0
    800054f0:	8526                	mv	a0,s1
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	cac080e7          	jalr	-852(ra) # 8000419e <readi>
    800054fa:	2501                	sext.w	a0,a0
    800054fc:	1aaa9963          	bne	s5,a0,800056ae <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005500:	6785                	lui	a5,0x1
    80005502:	0127893b          	addw	s2,a5,s2
    80005506:	77fd                	lui	a5,0xfffff
    80005508:	01478a3b          	addw	s4,a5,s4
    8000550c:	1f897163          	bgeu	s2,s8,800056ee <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005510:	02091593          	slli	a1,s2,0x20
    80005514:	9181                	srli	a1,a1,0x20
    80005516:	95ea                	add	a1,a1,s10
    80005518:	855e                	mv	a0,s7
    8000551a:	ffffc097          	auipc	ra,0xffffc
    8000551e:	b5c080e7          	jalr	-1188(ra) # 80001076 <walkaddr>
    80005522:	862a                	mv	a2,a0
    if(pa == 0)
    80005524:	d955                	beqz	a0,800054d8 <exec+0xf0>
      n = PGSIZE;
    80005526:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005528:	fd9a70e3          	bgeu	s4,s9,800054e8 <exec+0x100>
      n = sz - i;
    8000552c:	8ad2                	mv	s5,s4
    8000552e:	bf6d                	j	800054e8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005530:	4901                	li	s2,0
  iunlockput(ip);
    80005532:	8526                	mv	a0,s1
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	c18080e7          	jalr	-1000(ra) # 8000414c <iunlockput>
  end_op();
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	400080e7          	jalr	1024(ra) # 8000493c <end_op>
  p = myproc();
    80005544:	ffffc097          	auipc	ra,0xffffc
    80005548:	494080e7          	jalr	1172(ra) # 800019d8 <myproc>
    8000554c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000554e:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80005552:	6785                	lui	a5,0x1
    80005554:	17fd                	addi	a5,a5,-1
    80005556:	993e                	add	s2,s2,a5
    80005558:	757d                	lui	a0,0xfffff
    8000555a:	00a977b3          	and	a5,s2,a0
    8000555e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005562:	6609                	lui	a2,0x2
    80005564:	963e                	add	a2,a2,a5
    80005566:	85be                	mv	a1,a5
    80005568:	855e                	mv	a0,s7
    8000556a:	ffffc097          	auipc	ra,0xffffc
    8000556e:	ec0080e7          	jalr	-320(ra) # 8000142a <uvmalloc>
    80005572:	8b2a                	mv	s6,a0
  ip = 0;
    80005574:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005576:	12050c63          	beqz	a0,800056ae <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000557a:	75f9                	lui	a1,0xffffe
    8000557c:	95aa                	add	a1,a1,a0
    8000557e:	855e                	mv	a0,s7
    80005580:	ffffc097          	auipc	ra,0xffffc
    80005584:	0c8080e7          	jalr	200(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005588:	7c7d                	lui	s8,0xfffff
    8000558a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000558c:	e0043783          	ld	a5,-512(s0)
    80005590:	6388                	ld	a0,0(a5)
    80005592:	c535                	beqz	a0,800055fe <exec+0x216>
    80005594:	e9040993          	addi	s3,s0,-368
    80005598:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000559c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000559e:	ffffc097          	auipc	ra,0xffffc
    800055a2:	8c6080e7          	jalr	-1850(ra) # 80000e64 <strlen>
    800055a6:	2505                	addiw	a0,a0,1
    800055a8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800055ac:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800055b0:	13896363          	bltu	s2,s8,800056d6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800055b4:	e0043d83          	ld	s11,-512(s0)
    800055b8:	000dba03          	ld	s4,0(s11)
    800055bc:	8552                	mv	a0,s4
    800055be:	ffffc097          	auipc	ra,0xffffc
    800055c2:	8a6080e7          	jalr	-1882(ra) # 80000e64 <strlen>
    800055c6:	0015069b          	addiw	a3,a0,1
    800055ca:	8652                	mv	a2,s4
    800055cc:	85ca                	mv	a1,s2
    800055ce:	855e                	mv	a0,s7
    800055d0:	ffffc097          	auipc	ra,0xffffc
    800055d4:	0aa080e7          	jalr	170(ra) # 8000167a <copyout>
    800055d8:	10054363          	bltz	a0,800056de <exec+0x2f6>
    ustack[argc] = sp;
    800055dc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055e0:	0485                	addi	s1,s1,1
    800055e2:	008d8793          	addi	a5,s11,8
    800055e6:	e0f43023          	sd	a5,-512(s0)
    800055ea:	008db503          	ld	a0,8(s11)
    800055ee:	c911                	beqz	a0,80005602 <exec+0x21a>
    if(argc >= MAXARG)
    800055f0:	09a1                	addi	s3,s3,8
    800055f2:	fb3c96e3          	bne	s9,s3,8000559e <exec+0x1b6>
  sz = sz1;
    800055f6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055fa:	4481                	li	s1,0
    800055fc:	a84d                	j	800056ae <exec+0x2c6>
  sp = sz;
    800055fe:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005600:	4481                	li	s1,0
  ustack[argc] = 0;
    80005602:	00349793          	slli	a5,s1,0x3
    80005606:	f9040713          	addi	a4,s0,-112
    8000560a:	97ba                	add	a5,a5,a4
    8000560c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005610:	00148693          	addi	a3,s1,1
    80005614:	068e                	slli	a3,a3,0x3
    80005616:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000561a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000561e:	01897663          	bgeu	s2,s8,8000562a <exec+0x242>
  sz = sz1;
    80005622:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005626:	4481                	li	s1,0
    80005628:	a059                	j	800056ae <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000562a:	e9040613          	addi	a2,s0,-368
    8000562e:	85ca                	mv	a1,s2
    80005630:	855e                	mv	a0,s7
    80005632:	ffffc097          	auipc	ra,0xffffc
    80005636:	048080e7          	jalr	72(ra) # 8000167a <copyout>
    8000563a:	0a054663          	bltz	a0,800056e6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000563e:	080ab783          	ld	a5,128(s5)
    80005642:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005646:	df843783          	ld	a5,-520(s0)
    8000564a:	0007c703          	lbu	a4,0(a5)
    8000564e:	cf11                	beqz	a4,8000566a <exec+0x282>
    80005650:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005652:	02f00693          	li	a3,47
    80005656:	a039                	j	80005664 <exec+0x27c>
      last = s+1;
    80005658:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000565c:	0785                	addi	a5,a5,1
    8000565e:	fff7c703          	lbu	a4,-1(a5)
    80005662:	c701                	beqz	a4,8000566a <exec+0x282>
    if(*s == '/')
    80005664:	fed71ce3          	bne	a4,a3,8000565c <exec+0x274>
    80005668:	bfc5                	j	80005658 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000566a:	4641                	li	a2,16
    8000566c:	df843583          	ld	a1,-520(s0)
    80005670:	180a8513          	addi	a0,s5,384
    80005674:	ffffb097          	auipc	ra,0xffffb
    80005678:	7be080e7          	jalr	1982(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000567c:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005680:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005684:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005688:	080ab783          	ld	a5,128(s5)
    8000568c:	e6843703          	ld	a4,-408(s0)
    80005690:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005692:	080ab783          	ld	a5,128(s5)
    80005696:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000569a:	85ea                	mv	a1,s10
    8000569c:	ffffc097          	auipc	ra,0xffffc
    800056a0:	492080e7          	jalr	1170(ra) # 80001b2e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056a4:	0004851b          	sext.w	a0,s1
    800056a8:	bbe1                	j	80005480 <exec+0x98>
    800056aa:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800056ae:	e0843583          	ld	a1,-504(s0)
    800056b2:	855e                	mv	a0,s7
    800056b4:	ffffc097          	auipc	ra,0xffffc
    800056b8:	47a080e7          	jalr	1146(ra) # 80001b2e <proc_freepagetable>
  if(ip){
    800056bc:	da0498e3          	bnez	s1,8000546c <exec+0x84>
  return -1;
    800056c0:	557d                	li	a0,-1
    800056c2:	bb7d                	j	80005480 <exec+0x98>
    800056c4:	e1243423          	sd	s2,-504(s0)
    800056c8:	b7dd                	j	800056ae <exec+0x2c6>
    800056ca:	e1243423          	sd	s2,-504(s0)
    800056ce:	b7c5                	j	800056ae <exec+0x2c6>
    800056d0:	e1243423          	sd	s2,-504(s0)
    800056d4:	bfe9                	j	800056ae <exec+0x2c6>
  sz = sz1;
    800056d6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056da:	4481                	li	s1,0
    800056dc:	bfc9                	j	800056ae <exec+0x2c6>
  sz = sz1;
    800056de:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056e2:	4481                	li	s1,0
    800056e4:	b7e9                	j	800056ae <exec+0x2c6>
  sz = sz1;
    800056e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056ea:	4481                	li	s1,0
    800056ec:	b7c9                	j	800056ae <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056ee:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056f2:	2b05                	addiw	s6,s6,1
    800056f4:	0389899b          	addiw	s3,s3,56
    800056f8:	e8845783          	lhu	a5,-376(s0)
    800056fc:	e2fb5be3          	bge	s6,a5,80005532 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005700:	2981                	sext.w	s3,s3
    80005702:	03800713          	li	a4,56
    80005706:	86ce                	mv	a3,s3
    80005708:	e1840613          	addi	a2,s0,-488
    8000570c:	4581                	li	a1,0
    8000570e:	8526                	mv	a0,s1
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	a8e080e7          	jalr	-1394(ra) # 8000419e <readi>
    80005718:	03800793          	li	a5,56
    8000571c:	f8f517e3          	bne	a0,a5,800056aa <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005720:	e1842783          	lw	a5,-488(s0)
    80005724:	4705                	li	a4,1
    80005726:	fce796e3          	bne	a5,a4,800056f2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000572a:	e4043603          	ld	a2,-448(s0)
    8000572e:	e3843783          	ld	a5,-456(s0)
    80005732:	f8f669e3          	bltu	a2,a5,800056c4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005736:	e2843783          	ld	a5,-472(s0)
    8000573a:	963e                	add	a2,a2,a5
    8000573c:	f8f667e3          	bltu	a2,a5,800056ca <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005740:	85ca                	mv	a1,s2
    80005742:	855e                	mv	a0,s7
    80005744:	ffffc097          	auipc	ra,0xffffc
    80005748:	ce6080e7          	jalr	-794(ra) # 8000142a <uvmalloc>
    8000574c:	e0a43423          	sd	a0,-504(s0)
    80005750:	d141                	beqz	a0,800056d0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005752:	e2843d03          	ld	s10,-472(s0)
    80005756:	df043783          	ld	a5,-528(s0)
    8000575a:	00fd77b3          	and	a5,s10,a5
    8000575e:	fba1                	bnez	a5,800056ae <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005760:	e2042d83          	lw	s11,-480(s0)
    80005764:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005768:	f80c03e3          	beqz	s8,800056ee <exec+0x306>
    8000576c:	8a62                	mv	s4,s8
    8000576e:	4901                	li	s2,0
    80005770:	b345                	j	80005510 <exec+0x128>

0000000080005772 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005772:	7179                	addi	sp,sp,-48
    80005774:	f406                	sd	ra,40(sp)
    80005776:	f022                	sd	s0,32(sp)
    80005778:	ec26                	sd	s1,24(sp)
    8000577a:	e84a                	sd	s2,16(sp)
    8000577c:	1800                	addi	s0,sp,48
    8000577e:	892e                	mv	s2,a1
    80005780:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005782:	fdc40593          	addi	a1,s0,-36
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	b46080e7          	jalr	-1210(ra) # 800032cc <argint>
    8000578e:	04054063          	bltz	a0,800057ce <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005792:	fdc42703          	lw	a4,-36(s0)
    80005796:	47bd                	li	a5,15
    80005798:	02e7ed63          	bltu	a5,a4,800057d2 <argfd+0x60>
    8000579c:	ffffc097          	auipc	ra,0xffffc
    800057a0:	23c080e7          	jalr	572(ra) # 800019d8 <myproc>
    800057a4:	fdc42703          	lw	a4,-36(s0)
    800057a8:	01e70793          	addi	a5,a4,30
    800057ac:	078e                	slli	a5,a5,0x3
    800057ae:	953e                	add	a0,a0,a5
    800057b0:	651c                	ld	a5,8(a0)
    800057b2:	c395                	beqz	a5,800057d6 <argfd+0x64>
    return -1;
  if(pfd)
    800057b4:	00090463          	beqz	s2,800057bc <argfd+0x4a>
    *pfd = fd;
    800057b8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057bc:	4501                	li	a0,0
  if(pf)
    800057be:	c091                	beqz	s1,800057c2 <argfd+0x50>
    *pf = f;
    800057c0:	e09c                	sd	a5,0(s1)
}
    800057c2:	70a2                	ld	ra,40(sp)
    800057c4:	7402                	ld	s0,32(sp)
    800057c6:	64e2                	ld	s1,24(sp)
    800057c8:	6942                	ld	s2,16(sp)
    800057ca:	6145                	addi	sp,sp,48
    800057cc:	8082                	ret
    return -1;
    800057ce:	557d                	li	a0,-1
    800057d0:	bfcd                	j	800057c2 <argfd+0x50>
    return -1;
    800057d2:	557d                	li	a0,-1
    800057d4:	b7fd                	j	800057c2 <argfd+0x50>
    800057d6:	557d                	li	a0,-1
    800057d8:	b7ed                	j	800057c2 <argfd+0x50>

00000000800057da <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057da:	1101                	addi	sp,sp,-32
    800057dc:	ec06                	sd	ra,24(sp)
    800057de:	e822                	sd	s0,16(sp)
    800057e0:	e426                	sd	s1,8(sp)
    800057e2:	1000                	addi	s0,sp,32
    800057e4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057e6:	ffffc097          	auipc	ra,0xffffc
    800057ea:	1f2080e7          	jalr	498(ra) # 800019d8 <myproc>
    800057ee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800057f0:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    800057f4:	4501                	li	a0,0
    800057f6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800057f8:	6398                	ld	a4,0(a5)
    800057fa:	cb19                	beqz	a4,80005810 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800057fc:	2505                	addiw	a0,a0,1
    800057fe:	07a1                	addi	a5,a5,8
    80005800:	fed51ce3          	bne	a0,a3,800057f8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005804:	557d                	li	a0,-1
}
    80005806:	60e2                	ld	ra,24(sp)
    80005808:	6442                	ld	s0,16(sp)
    8000580a:	64a2                	ld	s1,8(sp)
    8000580c:	6105                	addi	sp,sp,32
    8000580e:	8082                	ret
      p->ofile[fd] = f;
    80005810:	01e50793          	addi	a5,a0,30
    80005814:	078e                	slli	a5,a5,0x3
    80005816:	963e                	add	a2,a2,a5
    80005818:	e604                	sd	s1,8(a2)
      return fd;
    8000581a:	b7f5                	j	80005806 <fdalloc+0x2c>

000000008000581c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000581c:	715d                	addi	sp,sp,-80
    8000581e:	e486                	sd	ra,72(sp)
    80005820:	e0a2                	sd	s0,64(sp)
    80005822:	fc26                	sd	s1,56(sp)
    80005824:	f84a                	sd	s2,48(sp)
    80005826:	f44e                	sd	s3,40(sp)
    80005828:	f052                	sd	s4,32(sp)
    8000582a:	ec56                	sd	s5,24(sp)
    8000582c:	0880                	addi	s0,sp,80
    8000582e:	89ae                	mv	s3,a1
    80005830:	8ab2                	mv	s5,a2
    80005832:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005834:	fb040593          	addi	a1,s0,-80
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	e86080e7          	jalr	-378(ra) # 800046be <nameiparent>
    80005840:	892a                	mv	s2,a0
    80005842:	12050f63          	beqz	a0,80005980 <create+0x164>
    return 0;

  ilock(dp);
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	6a4080e7          	jalr	1700(ra) # 80003eea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000584e:	4601                	li	a2,0
    80005850:	fb040593          	addi	a1,s0,-80
    80005854:	854a                	mv	a0,s2
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	b78080e7          	jalr	-1160(ra) # 800043ce <dirlookup>
    8000585e:	84aa                	mv	s1,a0
    80005860:	c921                	beqz	a0,800058b0 <create+0x94>
    iunlockput(dp);
    80005862:	854a                	mv	a0,s2
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	8e8080e7          	jalr	-1816(ra) # 8000414c <iunlockput>
    ilock(ip);
    8000586c:	8526                	mv	a0,s1
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	67c080e7          	jalr	1660(ra) # 80003eea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005876:	2981                	sext.w	s3,s3
    80005878:	4789                	li	a5,2
    8000587a:	02f99463          	bne	s3,a5,800058a2 <create+0x86>
    8000587e:	0444d783          	lhu	a5,68(s1)
    80005882:	37f9                	addiw	a5,a5,-2
    80005884:	17c2                	slli	a5,a5,0x30
    80005886:	93c1                	srli	a5,a5,0x30
    80005888:	4705                	li	a4,1
    8000588a:	00f76c63          	bltu	a4,a5,800058a2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000588e:	8526                	mv	a0,s1
    80005890:	60a6                	ld	ra,72(sp)
    80005892:	6406                	ld	s0,64(sp)
    80005894:	74e2                	ld	s1,56(sp)
    80005896:	7942                	ld	s2,48(sp)
    80005898:	79a2                	ld	s3,40(sp)
    8000589a:	7a02                	ld	s4,32(sp)
    8000589c:	6ae2                	ld	s5,24(sp)
    8000589e:	6161                	addi	sp,sp,80
    800058a0:	8082                	ret
    iunlockput(ip);
    800058a2:	8526                	mv	a0,s1
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	8a8080e7          	jalr	-1880(ra) # 8000414c <iunlockput>
    return 0;
    800058ac:	4481                	li	s1,0
    800058ae:	b7c5                	j	8000588e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800058b0:	85ce                	mv	a1,s3
    800058b2:	00092503          	lw	a0,0(s2)
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	49c080e7          	jalr	1180(ra) # 80003d52 <ialloc>
    800058be:	84aa                	mv	s1,a0
    800058c0:	c529                	beqz	a0,8000590a <create+0xee>
  ilock(ip);
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	628080e7          	jalr	1576(ra) # 80003eea <ilock>
  ip->major = major;
    800058ca:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800058ce:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800058d2:	4785                	li	a5,1
    800058d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	546080e7          	jalr	1350(ra) # 80003e20 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800058e2:	2981                	sext.w	s3,s3
    800058e4:	4785                	li	a5,1
    800058e6:	02f98a63          	beq	s3,a5,8000591a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800058ea:	40d0                	lw	a2,4(s1)
    800058ec:	fb040593          	addi	a1,s0,-80
    800058f0:	854a                	mv	a0,s2
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	cec080e7          	jalr	-788(ra) # 800045de <dirlink>
    800058fa:	06054b63          	bltz	a0,80005970 <create+0x154>
  iunlockput(dp);
    800058fe:	854a                	mv	a0,s2
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	84c080e7          	jalr	-1972(ra) # 8000414c <iunlockput>
  return ip;
    80005908:	b759                	j	8000588e <create+0x72>
    panic("create: ialloc");
    8000590a:	00003517          	auipc	a0,0x3
    8000590e:	eb650513          	addi	a0,a0,-330 # 800087c0 <syscalls+0x2c8>
    80005912:	ffffb097          	auipc	ra,0xffffb
    80005916:	c2c080e7          	jalr	-980(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000591a:	04a95783          	lhu	a5,74(s2)
    8000591e:	2785                	addiw	a5,a5,1
    80005920:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005924:	854a                	mv	a0,s2
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	4fa080e7          	jalr	1274(ra) # 80003e20 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000592e:	40d0                	lw	a2,4(s1)
    80005930:	00003597          	auipc	a1,0x3
    80005934:	ea058593          	addi	a1,a1,-352 # 800087d0 <syscalls+0x2d8>
    80005938:	8526                	mv	a0,s1
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	ca4080e7          	jalr	-860(ra) # 800045de <dirlink>
    80005942:	00054f63          	bltz	a0,80005960 <create+0x144>
    80005946:	00492603          	lw	a2,4(s2)
    8000594a:	00003597          	auipc	a1,0x3
    8000594e:	e8e58593          	addi	a1,a1,-370 # 800087d8 <syscalls+0x2e0>
    80005952:	8526                	mv	a0,s1
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	c8a080e7          	jalr	-886(ra) # 800045de <dirlink>
    8000595c:	f80557e3          	bgez	a0,800058ea <create+0xce>
      panic("create dots");
    80005960:	00003517          	auipc	a0,0x3
    80005964:	e8050513          	addi	a0,a0,-384 # 800087e0 <syscalls+0x2e8>
    80005968:	ffffb097          	auipc	ra,0xffffb
    8000596c:	bd6080e7          	jalr	-1066(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005970:	00003517          	auipc	a0,0x3
    80005974:	e8050513          	addi	a0,a0,-384 # 800087f0 <syscalls+0x2f8>
    80005978:	ffffb097          	auipc	ra,0xffffb
    8000597c:	bc6080e7          	jalr	-1082(ra) # 8000053e <panic>
    return 0;
    80005980:	84aa                	mv	s1,a0
    80005982:	b731                	j	8000588e <create+0x72>

0000000080005984 <sys_dup>:
{
    80005984:	7179                	addi	sp,sp,-48
    80005986:	f406                	sd	ra,40(sp)
    80005988:	f022                	sd	s0,32(sp)
    8000598a:	ec26                	sd	s1,24(sp)
    8000598c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000598e:	fd840613          	addi	a2,s0,-40
    80005992:	4581                	li	a1,0
    80005994:	4501                	li	a0,0
    80005996:	00000097          	auipc	ra,0x0
    8000599a:	ddc080e7          	jalr	-548(ra) # 80005772 <argfd>
    return -1;
    8000599e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059a0:	02054363          	bltz	a0,800059c6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800059a4:	fd843503          	ld	a0,-40(s0)
    800059a8:	00000097          	auipc	ra,0x0
    800059ac:	e32080e7          	jalr	-462(ra) # 800057da <fdalloc>
    800059b0:	84aa                	mv	s1,a0
    return -1;
    800059b2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800059b4:	00054963          	bltz	a0,800059c6 <sys_dup+0x42>
  filedup(f);
    800059b8:	fd843503          	ld	a0,-40(s0)
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	37a080e7          	jalr	890(ra) # 80004d36 <filedup>
  return fd;
    800059c4:	87a6                	mv	a5,s1
}
    800059c6:	853e                	mv	a0,a5
    800059c8:	70a2                	ld	ra,40(sp)
    800059ca:	7402                	ld	s0,32(sp)
    800059cc:	64e2                	ld	s1,24(sp)
    800059ce:	6145                	addi	sp,sp,48
    800059d0:	8082                	ret

00000000800059d2 <sys_read>:
{
    800059d2:	7179                	addi	sp,sp,-48
    800059d4:	f406                	sd	ra,40(sp)
    800059d6:	f022                	sd	s0,32(sp)
    800059d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059da:	fe840613          	addi	a2,s0,-24
    800059de:	4581                	li	a1,0
    800059e0:	4501                	li	a0,0
    800059e2:	00000097          	auipc	ra,0x0
    800059e6:	d90080e7          	jalr	-624(ra) # 80005772 <argfd>
    return -1;
    800059ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059ec:	04054163          	bltz	a0,80005a2e <sys_read+0x5c>
    800059f0:	fe440593          	addi	a1,s0,-28
    800059f4:	4509                	li	a0,2
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	8d6080e7          	jalr	-1834(ra) # 800032cc <argint>
    return -1;
    800059fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a00:	02054763          	bltz	a0,80005a2e <sys_read+0x5c>
    80005a04:	fd840593          	addi	a1,s0,-40
    80005a08:	4505                	li	a0,1
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	8e4080e7          	jalr	-1820(ra) # 800032ee <argaddr>
    return -1;
    80005a12:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a14:	00054d63          	bltz	a0,80005a2e <sys_read+0x5c>
  return fileread(f, p, n);
    80005a18:	fe442603          	lw	a2,-28(s0)
    80005a1c:	fd843583          	ld	a1,-40(s0)
    80005a20:	fe843503          	ld	a0,-24(s0)
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	49e080e7          	jalr	1182(ra) # 80004ec2 <fileread>
    80005a2c:	87aa                	mv	a5,a0
}
    80005a2e:	853e                	mv	a0,a5
    80005a30:	70a2                	ld	ra,40(sp)
    80005a32:	7402                	ld	s0,32(sp)
    80005a34:	6145                	addi	sp,sp,48
    80005a36:	8082                	ret

0000000080005a38 <sys_write>:
{
    80005a38:	7179                	addi	sp,sp,-48
    80005a3a:	f406                	sd	ra,40(sp)
    80005a3c:	f022                	sd	s0,32(sp)
    80005a3e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a40:	fe840613          	addi	a2,s0,-24
    80005a44:	4581                	li	a1,0
    80005a46:	4501                	li	a0,0
    80005a48:	00000097          	auipc	ra,0x0
    80005a4c:	d2a080e7          	jalr	-726(ra) # 80005772 <argfd>
    return -1;
    80005a50:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a52:	04054163          	bltz	a0,80005a94 <sys_write+0x5c>
    80005a56:	fe440593          	addi	a1,s0,-28
    80005a5a:	4509                	li	a0,2
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	870080e7          	jalr	-1936(ra) # 800032cc <argint>
    return -1;
    80005a64:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a66:	02054763          	bltz	a0,80005a94 <sys_write+0x5c>
    80005a6a:	fd840593          	addi	a1,s0,-40
    80005a6e:	4505                	li	a0,1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	87e080e7          	jalr	-1922(ra) # 800032ee <argaddr>
    return -1;
    80005a78:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a7a:	00054d63          	bltz	a0,80005a94 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005a7e:	fe442603          	lw	a2,-28(s0)
    80005a82:	fd843583          	ld	a1,-40(s0)
    80005a86:	fe843503          	ld	a0,-24(s0)
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	4fa080e7          	jalr	1274(ra) # 80004f84 <filewrite>
    80005a92:	87aa                	mv	a5,a0
}
    80005a94:	853e                	mv	a0,a5
    80005a96:	70a2                	ld	ra,40(sp)
    80005a98:	7402                	ld	s0,32(sp)
    80005a9a:	6145                	addi	sp,sp,48
    80005a9c:	8082                	ret

0000000080005a9e <sys_close>:
{
    80005a9e:	1101                	addi	sp,sp,-32
    80005aa0:	ec06                	sd	ra,24(sp)
    80005aa2:	e822                	sd	s0,16(sp)
    80005aa4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005aa6:	fe040613          	addi	a2,s0,-32
    80005aaa:	fec40593          	addi	a1,s0,-20
    80005aae:	4501                	li	a0,0
    80005ab0:	00000097          	auipc	ra,0x0
    80005ab4:	cc2080e7          	jalr	-830(ra) # 80005772 <argfd>
    return -1;
    80005ab8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005aba:	02054463          	bltz	a0,80005ae2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005abe:	ffffc097          	auipc	ra,0xffffc
    80005ac2:	f1a080e7          	jalr	-230(ra) # 800019d8 <myproc>
    80005ac6:	fec42783          	lw	a5,-20(s0)
    80005aca:	07f9                	addi	a5,a5,30
    80005acc:	078e                	slli	a5,a5,0x3
    80005ace:	97aa                	add	a5,a5,a0
    80005ad0:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005ad4:	fe043503          	ld	a0,-32(s0)
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	2b0080e7          	jalr	688(ra) # 80004d88 <fileclose>
  return 0;
    80005ae0:	4781                	li	a5,0
}
    80005ae2:	853e                	mv	a0,a5
    80005ae4:	60e2                	ld	ra,24(sp)
    80005ae6:	6442                	ld	s0,16(sp)
    80005ae8:	6105                	addi	sp,sp,32
    80005aea:	8082                	ret

0000000080005aec <sys_fstat>:
{
    80005aec:	1101                	addi	sp,sp,-32
    80005aee:	ec06                	sd	ra,24(sp)
    80005af0:	e822                	sd	s0,16(sp)
    80005af2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005af4:	fe840613          	addi	a2,s0,-24
    80005af8:	4581                	li	a1,0
    80005afa:	4501                	li	a0,0
    80005afc:	00000097          	auipc	ra,0x0
    80005b00:	c76080e7          	jalr	-906(ra) # 80005772 <argfd>
    return -1;
    80005b04:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b06:	02054563          	bltz	a0,80005b30 <sys_fstat+0x44>
    80005b0a:	fe040593          	addi	a1,s0,-32
    80005b0e:	4505                	li	a0,1
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	7de080e7          	jalr	2014(ra) # 800032ee <argaddr>
    return -1;
    80005b18:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b1a:	00054b63          	bltz	a0,80005b30 <sys_fstat+0x44>
  return filestat(f, st);
    80005b1e:	fe043583          	ld	a1,-32(s0)
    80005b22:	fe843503          	ld	a0,-24(s0)
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	32a080e7          	jalr	810(ra) # 80004e50 <filestat>
    80005b2e:	87aa                	mv	a5,a0
}
    80005b30:	853e                	mv	a0,a5
    80005b32:	60e2                	ld	ra,24(sp)
    80005b34:	6442                	ld	s0,16(sp)
    80005b36:	6105                	addi	sp,sp,32
    80005b38:	8082                	ret

0000000080005b3a <sys_link>:
{
    80005b3a:	7169                	addi	sp,sp,-304
    80005b3c:	f606                	sd	ra,296(sp)
    80005b3e:	f222                	sd	s0,288(sp)
    80005b40:	ee26                	sd	s1,280(sp)
    80005b42:	ea4a                	sd	s2,272(sp)
    80005b44:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b46:	08000613          	li	a2,128
    80005b4a:	ed040593          	addi	a1,s0,-304
    80005b4e:	4501                	li	a0,0
    80005b50:	ffffd097          	auipc	ra,0xffffd
    80005b54:	7c0080e7          	jalr	1984(ra) # 80003310 <argstr>
    return -1;
    80005b58:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b5a:	10054e63          	bltz	a0,80005c76 <sys_link+0x13c>
    80005b5e:	08000613          	li	a2,128
    80005b62:	f5040593          	addi	a1,s0,-176
    80005b66:	4505                	li	a0,1
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	7a8080e7          	jalr	1960(ra) # 80003310 <argstr>
    return -1;
    80005b70:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b72:	10054263          	bltz	a0,80005c76 <sys_link+0x13c>
  begin_op();
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	d46080e7          	jalr	-698(ra) # 800048bc <begin_op>
  if((ip = namei(old)) == 0){
    80005b7e:	ed040513          	addi	a0,s0,-304
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	b1e080e7          	jalr	-1250(ra) # 800046a0 <namei>
    80005b8a:	84aa                	mv	s1,a0
    80005b8c:	c551                	beqz	a0,80005c18 <sys_link+0xde>
  ilock(ip);
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	35c080e7          	jalr	860(ra) # 80003eea <ilock>
  if(ip->type == T_DIR){
    80005b96:	04449703          	lh	a4,68(s1)
    80005b9a:	4785                	li	a5,1
    80005b9c:	08f70463          	beq	a4,a5,80005c24 <sys_link+0xea>
  ip->nlink++;
    80005ba0:	04a4d783          	lhu	a5,74(s1)
    80005ba4:	2785                	addiw	a5,a5,1
    80005ba6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005baa:	8526                	mv	a0,s1
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	274080e7          	jalr	628(ra) # 80003e20 <iupdate>
  iunlock(ip);
    80005bb4:	8526                	mv	a0,s1
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	3f6080e7          	jalr	1014(ra) # 80003fac <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005bbe:	fd040593          	addi	a1,s0,-48
    80005bc2:	f5040513          	addi	a0,s0,-176
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	af8080e7          	jalr	-1288(ra) # 800046be <nameiparent>
    80005bce:	892a                	mv	s2,a0
    80005bd0:	c935                	beqz	a0,80005c44 <sys_link+0x10a>
  ilock(dp);
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	318080e7          	jalr	792(ra) # 80003eea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005bda:	00092703          	lw	a4,0(s2)
    80005bde:	409c                	lw	a5,0(s1)
    80005be0:	04f71d63          	bne	a4,a5,80005c3a <sys_link+0x100>
    80005be4:	40d0                	lw	a2,4(s1)
    80005be6:	fd040593          	addi	a1,s0,-48
    80005bea:	854a                	mv	a0,s2
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	9f2080e7          	jalr	-1550(ra) # 800045de <dirlink>
    80005bf4:	04054363          	bltz	a0,80005c3a <sys_link+0x100>
  iunlockput(dp);
    80005bf8:	854a                	mv	a0,s2
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	552080e7          	jalr	1362(ra) # 8000414c <iunlockput>
  iput(ip);
    80005c02:	8526                	mv	a0,s1
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	4a0080e7          	jalr	1184(ra) # 800040a4 <iput>
  end_op();
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	d30080e7          	jalr	-720(ra) # 8000493c <end_op>
  return 0;
    80005c14:	4781                	li	a5,0
    80005c16:	a085                	j	80005c76 <sys_link+0x13c>
    end_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	d24080e7          	jalr	-732(ra) # 8000493c <end_op>
    return -1;
    80005c20:	57fd                	li	a5,-1
    80005c22:	a891                	j	80005c76 <sys_link+0x13c>
    iunlockput(ip);
    80005c24:	8526                	mv	a0,s1
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	526080e7          	jalr	1318(ra) # 8000414c <iunlockput>
    end_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	d0e080e7          	jalr	-754(ra) # 8000493c <end_op>
    return -1;
    80005c36:	57fd                	li	a5,-1
    80005c38:	a83d                	j	80005c76 <sys_link+0x13c>
    iunlockput(dp);
    80005c3a:	854a                	mv	a0,s2
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	510080e7          	jalr	1296(ra) # 8000414c <iunlockput>
  ilock(ip);
    80005c44:	8526                	mv	a0,s1
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	2a4080e7          	jalr	676(ra) # 80003eea <ilock>
  ip->nlink--;
    80005c4e:	04a4d783          	lhu	a5,74(s1)
    80005c52:	37fd                	addiw	a5,a5,-1
    80005c54:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c58:	8526                	mv	a0,s1
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	1c6080e7          	jalr	454(ra) # 80003e20 <iupdate>
  iunlockput(ip);
    80005c62:	8526                	mv	a0,s1
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	4e8080e7          	jalr	1256(ra) # 8000414c <iunlockput>
  end_op();
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	cd0080e7          	jalr	-816(ra) # 8000493c <end_op>
  return -1;
    80005c74:	57fd                	li	a5,-1
}
    80005c76:	853e                	mv	a0,a5
    80005c78:	70b2                	ld	ra,296(sp)
    80005c7a:	7412                	ld	s0,288(sp)
    80005c7c:	64f2                	ld	s1,280(sp)
    80005c7e:	6952                	ld	s2,272(sp)
    80005c80:	6155                	addi	sp,sp,304
    80005c82:	8082                	ret

0000000080005c84 <sys_unlink>:
{
    80005c84:	7151                	addi	sp,sp,-240
    80005c86:	f586                	sd	ra,232(sp)
    80005c88:	f1a2                	sd	s0,224(sp)
    80005c8a:	eda6                	sd	s1,216(sp)
    80005c8c:	e9ca                	sd	s2,208(sp)
    80005c8e:	e5ce                	sd	s3,200(sp)
    80005c90:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c92:	08000613          	li	a2,128
    80005c96:	f3040593          	addi	a1,s0,-208
    80005c9a:	4501                	li	a0,0
    80005c9c:	ffffd097          	auipc	ra,0xffffd
    80005ca0:	674080e7          	jalr	1652(ra) # 80003310 <argstr>
    80005ca4:	18054163          	bltz	a0,80005e26 <sys_unlink+0x1a2>
  begin_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	c14080e7          	jalr	-1004(ra) # 800048bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005cb0:	fb040593          	addi	a1,s0,-80
    80005cb4:	f3040513          	addi	a0,s0,-208
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	a06080e7          	jalr	-1530(ra) # 800046be <nameiparent>
    80005cc0:	84aa                	mv	s1,a0
    80005cc2:	c979                	beqz	a0,80005d98 <sys_unlink+0x114>
  ilock(dp);
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	226080e7          	jalr	550(ra) # 80003eea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ccc:	00003597          	auipc	a1,0x3
    80005cd0:	b0458593          	addi	a1,a1,-1276 # 800087d0 <syscalls+0x2d8>
    80005cd4:	fb040513          	addi	a0,s0,-80
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	6dc080e7          	jalr	1756(ra) # 800043b4 <namecmp>
    80005ce0:	14050a63          	beqz	a0,80005e34 <sys_unlink+0x1b0>
    80005ce4:	00003597          	auipc	a1,0x3
    80005ce8:	af458593          	addi	a1,a1,-1292 # 800087d8 <syscalls+0x2e0>
    80005cec:	fb040513          	addi	a0,s0,-80
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	6c4080e7          	jalr	1732(ra) # 800043b4 <namecmp>
    80005cf8:	12050e63          	beqz	a0,80005e34 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005cfc:	f2c40613          	addi	a2,s0,-212
    80005d00:	fb040593          	addi	a1,s0,-80
    80005d04:	8526                	mv	a0,s1
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	6c8080e7          	jalr	1736(ra) # 800043ce <dirlookup>
    80005d0e:	892a                	mv	s2,a0
    80005d10:	12050263          	beqz	a0,80005e34 <sys_unlink+0x1b0>
  ilock(ip);
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	1d6080e7          	jalr	470(ra) # 80003eea <ilock>
  if(ip->nlink < 1)
    80005d1c:	04a91783          	lh	a5,74(s2)
    80005d20:	08f05263          	blez	a5,80005da4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d24:	04491703          	lh	a4,68(s2)
    80005d28:	4785                	li	a5,1
    80005d2a:	08f70563          	beq	a4,a5,80005db4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d2e:	4641                	li	a2,16
    80005d30:	4581                	li	a1,0
    80005d32:	fc040513          	addi	a0,s0,-64
    80005d36:	ffffb097          	auipc	ra,0xffffb
    80005d3a:	faa080e7          	jalr	-86(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d3e:	4741                	li	a4,16
    80005d40:	f2c42683          	lw	a3,-212(s0)
    80005d44:	fc040613          	addi	a2,s0,-64
    80005d48:	4581                	li	a1,0
    80005d4a:	8526                	mv	a0,s1
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	54a080e7          	jalr	1354(ra) # 80004296 <writei>
    80005d54:	47c1                	li	a5,16
    80005d56:	0af51563          	bne	a0,a5,80005e00 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d5a:	04491703          	lh	a4,68(s2)
    80005d5e:	4785                	li	a5,1
    80005d60:	0af70863          	beq	a4,a5,80005e10 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d64:	8526                	mv	a0,s1
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	3e6080e7          	jalr	998(ra) # 8000414c <iunlockput>
  ip->nlink--;
    80005d6e:	04a95783          	lhu	a5,74(s2)
    80005d72:	37fd                	addiw	a5,a5,-1
    80005d74:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d78:	854a                	mv	a0,s2
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	0a6080e7          	jalr	166(ra) # 80003e20 <iupdate>
  iunlockput(ip);
    80005d82:	854a                	mv	a0,s2
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	3c8080e7          	jalr	968(ra) # 8000414c <iunlockput>
  end_op();
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	bb0080e7          	jalr	-1104(ra) # 8000493c <end_op>
  return 0;
    80005d94:	4501                	li	a0,0
    80005d96:	a84d                	j	80005e48 <sys_unlink+0x1c4>
    end_op();
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	ba4080e7          	jalr	-1116(ra) # 8000493c <end_op>
    return -1;
    80005da0:	557d                	li	a0,-1
    80005da2:	a05d                	j	80005e48 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005da4:	00003517          	auipc	a0,0x3
    80005da8:	a5c50513          	addi	a0,a0,-1444 # 80008800 <syscalls+0x308>
    80005dac:	ffffa097          	auipc	ra,0xffffa
    80005db0:	792080e7          	jalr	1938(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005db4:	04c92703          	lw	a4,76(s2)
    80005db8:	02000793          	li	a5,32
    80005dbc:	f6e7f9e3          	bgeu	a5,a4,80005d2e <sys_unlink+0xaa>
    80005dc0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005dc4:	4741                	li	a4,16
    80005dc6:	86ce                	mv	a3,s3
    80005dc8:	f1840613          	addi	a2,s0,-232
    80005dcc:	4581                	li	a1,0
    80005dce:	854a                	mv	a0,s2
    80005dd0:	ffffe097          	auipc	ra,0xffffe
    80005dd4:	3ce080e7          	jalr	974(ra) # 8000419e <readi>
    80005dd8:	47c1                	li	a5,16
    80005dda:	00f51b63          	bne	a0,a5,80005df0 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005dde:	f1845783          	lhu	a5,-232(s0)
    80005de2:	e7a1                	bnez	a5,80005e2a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005de4:	29c1                	addiw	s3,s3,16
    80005de6:	04c92783          	lw	a5,76(s2)
    80005dea:	fcf9ede3          	bltu	s3,a5,80005dc4 <sys_unlink+0x140>
    80005dee:	b781                	j	80005d2e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005df0:	00003517          	auipc	a0,0x3
    80005df4:	a2850513          	addi	a0,a0,-1496 # 80008818 <syscalls+0x320>
    80005df8:	ffffa097          	auipc	ra,0xffffa
    80005dfc:	746080e7          	jalr	1862(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e00:	00003517          	auipc	a0,0x3
    80005e04:	a3050513          	addi	a0,a0,-1488 # 80008830 <syscalls+0x338>
    80005e08:	ffffa097          	auipc	ra,0xffffa
    80005e0c:	736080e7          	jalr	1846(ra) # 8000053e <panic>
    dp->nlink--;
    80005e10:	04a4d783          	lhu	a5,74(s1)
    80005e14:	37fd                	addiw	a5,a5,-1
    80005e16:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e1a:	8526                	mv	a0,s1
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	004080e7          	jalr	4(ra) # 80003e20 <iupdate>
    80005e24:	b781                	j	80005d64 <sys_unlink+0xe0>
    return -1;
    80005e26:	557d                	li	a0,-1
    80005e28:	a005                	j	80005e48 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e2a:	854a                	mv	a0,s2
    80005e2c:	ffffe097          	auipc	ra,0xffffe
    80005e30:	320080e7          	jalr	800(ra) # 8000414c <iunlockput>
  iunlockput(dp);
    80005e34:	8526                	mv	a0,s1
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	316080e7          	jalr	790(ra) # 8000414c <iunlockput>
  end_op();
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	afe080e7          	jalr	-1282(ra) # 8000493c <end_op>
  return -1;
    80005e46:	557d                	li	a0,-1
}
    80005e48:	70ae                	ld	ra,232(sp)
    80005e4a:	740e                	ld	s0,224(sp)
    80005e4c:	64ee                	ld	s1,216(sp)
    80005e4e:	694e                	ld	s2,208(sp)
    80005e50:	69ae                	ld	s3,200(sp)
    80005e52:	616d                	addi	sp,sp,240
    80005e54:	8082                	ret

0000000080005e56 <sys_open>:

uint64
sys_open(void)
{
    80005e56:	7131                	addi	sp,sp,-192
    80005e58:	fd06                	sd	ra,184(sp)
    80005e5a:	f922                	sd	s0,176(sp)
    80005e5c:	f526                	sd	s1,168(sp)
    80005e5e:	f14a                	sd	s2,160(sp)
    80005e60:	ed4e                	sd	s3,152(sp)
    80005e62:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e64:	08000613          	li	a2,128
    80005e68:	f5040593          	addi	a1,s0,-176
    80005e6c:	4501                	li	a0,0
    80005e6e:	ffffd097          	auipc	ra,0xffffd
    80005e72:	4a2080e7          	jalr	1186(ra) # 80003310 <argstr>
    return -1;
    80005e76:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e78:	0c054163          	bltz	a0,80005f3a <sys_open+0xe4>
    80005e7c:	f4c40593          	addi	a1,s0,-180
    80005e80:	4505                	li	a0,1
    80005e82:	ffffd097          	auipc	ra,0xffffd
    80005e86:	44a080e7          	jalr	1098(ra) # 800032cc <argint>
    80005e8a:	0a054863          	bltz	a0,80005f3a <sys_open+0xe4>

  begin_op();
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	a2e080e7          	jalr	-1490(ra) # 800048bc <begin_op>

  if(omode & O_CREATE){
    80005e96:	f4c42783          	lw	a5,-180(s0)
    80005e9a:	2007f793          	andi	a5,a5,512
    80005e9e:	cbdd                	beqz	a5,80005f54 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ea0:	4681                	li	a3,0
    80005ea2:	4601                	li	a2,0
    80005ea4:	4589                	li	a1,2
    80005ea6:	f5040513          	addi	a0,s0,-176
    80005eaa:	00000097          	auipc	ra,0x0
    80005eae:	972080e7          	jalr	-1678(ra) # 8000581c <create>
    80005eb2:	892a                	mv	s2,a0
    if(ip == 0){
    80005eb4:	c959                	beqz	a0,80005f4a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005eb6:	04491703          	lh	a4,68(s2)
    80005eba:	478d                	li	a5,3
    80005ebc:	00f71763          	bne	a4,a5,80005eca <sys_open+0x74>
    80005ec0:	04695703          	lhu	a4,70(s2)
    80005ec4:	47a5                	li	a5,9
    80005ec6:	0ce7ec63          	bltu	a5,a4,80005f9e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	e02080e7          	jalr	-510(ra) # 80004ccc <filealloc>
    80005ed2:	89aa                	mv	s3,a0
    80005ed4:	10050263          	beqz	a0,80005fd8 <sys_open+0x182>
    80005ed8:	00000097          	auipc	ra,0x0
    80005edc:	902080e7          	jalr	-1790(ra) # 800057da <fdalloc>
    80005ee0:	84aa                	mv	s1,a0
    80005ee2:	0e054663          	bltz	a0,80005fce <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ee6:	04491703          	lh	a4,68(s2)
    80005eea:	478d                	li	a5,3
    80005eec:	0cf70463          	beq	a4,a5,80005fb4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ef0:	4789                	li	a5,2
    80005ef2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ef6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005efa:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005efe:	f4c42783          	lw	a5,-180(s0)
    80005f02:	0017c713          	xori	a4,a5,1
    80005f06:	8b05                	andi	a4,a4,1
    80005f08:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f0c:	0037f713          	andi	a4,a5,3
    80005f10:	00e03733          	snez	a4,a4
    80005f14:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f18:	4007f793          	andi	a5,a5,1024
    80005f1c:	c791                	beqz	a5,80005f28 <sys_open+0xd2>
    80005f1e:	04491703          	lh	a4,68(s2)
    80005f22:	4789                	li	a5,2
    80005f24:	08f70f63          	beq	a4,a5,80005fc2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f28:	854a                	mv	a0,s2
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	082080e7          	jalr	130(ra) # 80003fac <iunlock>
  end_op();
    80005f32:	fffff097          	auipc	ra,0xfffff
    80005f36:	a0a080e7          	jalr	-1526(ra) # 8000493c <end_op>

  return fd;
}
    80005f3a:	8526                	mv	a0,s1
    80005f3c:	70ea                	ld	ra,184(sp)
    80005f3e:	744a                	ld	s0,176(sp)
    80005f40:	74aa                	ld	s1,168(sp)
    80005f42:	790a                	ld	s2,160(sp)
    80005f44:	69ea                	ld	s3,152(sp)
    80005f46:	6129                	addi	sp,sp,192
    80005f48:	8082                	ret
      end_op();
    80005f4a:	fffff097          	auipc	ra,0xfffff
    80005f4e:	9f2080e7          	jalr	-1550(ra) # 8000493c <end_op>
      return -1;
    80005f52:	b7e5                	j	80005f3a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f54:	f5040513          	addi	a0,s0,-176
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	748080e7          	jalr	1864(ra) # 800046a0 <namei>
    80005f60:	892a                	mv	s2,a0
    80005f62:	c905                	beqz	a0,80005f92 <sys_open+0x13c>
    ilock(ip);
    80005f64:	ffffe097          	auipc	ra,0xffffe
    80005f68:	f86080e7          	jalr	-122(ra) # 80003eea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f6c:	04491703          	lh	a4,68(s2)
    80005f70:	4785                	li	a5,1
    80005f72:	f4f712e3          	bne	a4,a5,80005eb6 <sys_open+0x60>
    80005f76:	f4c42783          	lw	a5,-180(s0)
    80005f7a:	dba1                	beqz	a5,80005eca <sys_open+0x74>
      iunlockput(ip);
    80005f7c:	854a                	mv	a0,s2
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	1ce080e7          	jalr	462(ra) # 8000414c <iunlockput>
      end_op();
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	9b6080e7          	jalr	-1610(ra) # 8000493c <end_op>
      return -1;
    80005f8e:	54fd                	li	s1,-1
    80005f90:	b76d                	j	80005f3a <sys_open+0xe4>
      end_op();
    80005f92:	fffff097          	auipc	ra,0xfffff
    80005f96:	9aa080e7          	jalr	-1622(ra) # 8000493c <end_op>
      return -1;
    80005f9a:	54fd                	li	s1,-1
    80005f9c:	bf79                	j	80005f3a <sys_open+0xe4>
    iunlockput(ip);
    80005f9e:	854a                	mv	a0,s2
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	1ac080e7          	jalr	428(ra) # 8000414c <iunlockput>
    end_op();
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	994080e7          	jalr	-1644(ra) # 8000493c <end_op>
    return -1;
    80005fb0:	54fd                	li	s1,-1
    80005fb2:	b761                	j	80005f3a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fb4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fb8:	04691783          	lh	a5,70(s2)
    80005fbc:	02f99223          	sh	a5,36(s3)
    80005fc0:	bf2d                	j	80005efa <sys_open+0xa4>
    itrunc(ip);
    80005fc2:	854a                	mv	a0,s2
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	034080e7          	jalr	52(ra) # 80003ff8 <itrunc>
    80005fcc:	bfb1                	j	80005f28 <sys_open+0xd2>
      fileclose(f);
    80005fce:	854e                	mv	a0,s3
    80005fd0:	fffff097          	auipc	ra,0xfffff
    80005fd4:	db8080e7          	jalr	-584(ra) # 80004d88 <fileclose>
    iunlockput(ip);
    80005fd8:	854a                	mv	a0,s2
    80005fda:	ffffe097          	auipc	ra,0xffffe
    80005fde:	172080e7          	jalr	370(ra) # 8000414c <iunlockput>
    end_op();
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	95a080e7          	jalr	-1702(ra) # 8000493c <end_op>
    return -1;
    80005fea:	54fd                	li	s1,-1
    80005fec:	b7b9                	j	80005f3a <sys_open+0xe4>

0000000080005fee <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005fee:	7175                	addi	sp,sp,-144
    80005ff0:	e506                	sd	ra,136(sp)
    80005ff2:	e122                	sd	s0,128(sp)
    80005ff4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ff6:	fffff097          	auipc	ra,0xfffff
    80005ffa:	8c6080e7          	jalr	-1850(ra) # 800048bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ffe:	08000613          	li	a2,128
    80006002:	f7040593          	addi	a1,s0,-144
    80006006:	4501                	li	a0,0
    80006008:	ffffd097          	auipc	ra,0xffffd
    8000600c:	308080e7          	jalr	776(ra) # 80003310 <argstr>
    80006010:	02054963          	bltz	a0,80006042 <sys_mkdir+0x54>
    80006014:	4681                	li	a3,0
    80006016:	4601                	li	a2,0
    80006018:	4585                	li	a1,1
    8000601a:	f7040513          	addi	a0,s0,-144
    8000601e:	fffff097          	auipc	ra,0xfffff
    80006022:	7fe080e7          	jalr	2046(ra) # 8000581c <create>
    80006026:	cd11                	beqz	a0,80006042 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006028:	ffffe097          	auipc	ra,0xffffe
    8000602c:	124080e7          	jalr	292(ra) # 8000414c <iunlockput>
  end_op();
    80006030:	fffff097          	auipc	ra,0xfffff
    80006034:	90c080e7          	jalr	-1780(ra) # 8000493c <end_op>
  return 0;
    80006038:	4501                	li	a0,0
}
    8000603a:	60aa                	ld	ra,136(sp)
    8000603c:	640a                	ld	s0,128(sp)
    8000603e:	6149                	addi	sp,sp,144
    80006040:	8082                	ret
    end_op();
    80006042:	fffff097          	auipc	ra,0xfffff
    80006046:	8fa080e7          	jalr	-1798(ra) # 8000493c <end_op>
    return -1;
    8000604a:	557d                	li	a0,-1
    8000604c:	b7fd                	j	8000603a <sys_mkdir+0x4c>

000000008000604e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000604e:	7135                	addi	sp,sp,-160
    80006050:	ed06                	sd	ra,152(sp)
    80006052:	e922                	sd	s0,144(sp)
    80006054:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006056:	fffff097          	auipc	ra,0xfffff
    8000605a:	866080e7          	jalr	-1946(ra) # 800048bc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000605e:	08000613          	li	a2,128
    80006062:	f7040593          	addi	a1,s0,-144
    80006066:	4501                	li	a0,0
    80006068:	ffffd097          	auipc	ra,0xffffd
    8000606c:	2a8080e7          	jalr	680(ra) # 80003310 <argstr>
    80006070:	04054a63          	bltz	a0,800060c4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006074:	f6c40593          	addi	a1,s0,-148
    80006078:	4505                	li	a0,1
    8000607a:	ffffd097          	auipc	ra,0xffffd
    8000607e:	252080e7          	jalr	594(ra) # 800032cc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006082:	04054163          	bltz	a0,800060c4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006086:	f6840593          	addi	a1,s0,-152
    8000608a:	4509                	li	a0,2
    8000608c:	ffffd097          	auipc	ra,0xffffd
    80006090:	240080e7          	jalr	576(ra) # 800032cc <argint>
     argint(1, &major) < 0 ||
    80006094:	02054863          	bltz	a0,800060c4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006098:	f6841683          	lh	a3,-152(s0)
    8000609c:	f6c41603          	lh	a2,-148(s0)
    800060a0:	458d                	li	a1,3
    800060a2:	f7040513          	addi	a0,s0,-144
    800060a6:	fffff097          	auipc	ra,0xfffff
    800060aa:	776080e7          	jalr	1910(ra) # 8000581c <create>
     argint(2, &minor) < 0 ||
    800060ae:	c919                	beqz	a0,800060c4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060b0:	ffffe097          	auipc	ra,0xffffe
    800060b4:	09c080e7          	jalr	156(ra) # 8000414c <iunlockput>
  end_op();
    800060b8:	fffff097          	auipc	ra,0xfffff
    800060bc:	884080e7          	jalr	-1916(ra) # 8000493c <end_op>
  return 0;
    800060c0:	4501                	li	a0,0
    800060c2:	a031                	j	800060ce <sys_mknod+0x80>
    end_op();
    800060c4:	fffff097          	auipc	ra,0xfffff
    800060c8:	878080e7          	jalr	-1928(ra) # 8000493c <end_op>
    return -1;
    800060cc:	557d                	li	a0,-1
}
    800060ce:	60ea                	ld	ra,152(sp)
    800060d0:	644a                	ld	s0,144(sp)
    800060d2:	610d                	addi	sp,sp,160
    800060d4:	8082                	ret

00000000800060d6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800060d6:	7135                	addi	sp,sp,-160
    800060d8:	ed06                	sd	ra,152(sp)
    800060da:	e922                	sd	s0,144(sp)
    800060dc:	e526                	sd	s1,136(sp)
    800060de:	e14a                	sd	s2,128(sp)
    800060e0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060e2:	ffffc097          	auipc	ra,0xffffc
    800060e6:	8f6080e7          	jalr	-1802(ra) # 800019d8 <myproc>
    800060ea:	892a                	mv	s2,a0
  
  begin_op();
    800060ec:	ffffe097          	auipc	ra,0xffffe
    800060f0:	7d0080e7          	jalr	2000(ra) # 800048bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800060f4:	08000613          	li	a2,128
    800060f8:	f6040593          	addi	a1,s0,-160
    800060fc:	4501                	li	a0,0
    800060fe:	ffffd097          	auipc	ra,0xffffd
    80006102:	212080e7          	jalr	530(ra) # 80003310 <argstr>
    80006106:	04054b63          	bltz	a0,8000615c <sys_chdir+0x86>
    8000610a:	f6040513          	addi	a0,s0,-160
    8000610e:	ffffe097          	auipc	ra,0xffffe
    80006112:	592080e7          	jalr	1426(ra) # 800046a0 <namei>
    80006116:	84aa                	mv	s1,a0
    80006118:	c131                	beqz	a0,8000615c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000611a:	ffffe097          	auipc	ra,0xffffe
    8000611e:	dd0080e7          	jalr	-560(ra) # 80003eea <ilock>
  if(ip->type != T_DIR){
    80006122:	04449703          	lh	a4,68(s1)
    80006126:	4785                	li	a5,1
    80006128:	04f71063          	bne	a4,a5,80006168 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000612c:	8526                	mv	a0,s1
    8000612e:	ffffe097          	auipc	ra,0xffffe
    80006132:	e7e080e7          	jalr	-386(ra) # 80003fac <iunlock>
  iput(p->cwd);
    80006136:	17893503          	ld	a0,376(s2)
    8000613a:	ffffe097          	auipc	ra,0xffffe
    8000613e:	f6a080e7          	jalr	-150(ra) # 800040a4 <iput>
  end_op();
    80006142:	ffffe097          	auipc	ra,0xffffe
    80006146:	7fa080e7          	jalr	2042(ra) # 8000493c <end_op>
  p->cwd = ip;
    8000614a:	16993c23          	sd	s1,376(s2)
  return 0;
    8000614e:	4501                	li	a0,0
}
    80006150:	60ea                	ld	ra,152(sp)
    80006152:	644a                	ld	s0,144(sp)
    80006154:	64aa                	ld	s1,136(sp)
    80006156:	690a                	ld	s2,128(sp)
    80006158:	610d                	addi	sp,sp,160
    8000615a:	8082                	ret
    end_op();
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	7e0080e7          	jalr	2016(ra) # 8000493c <end_op>
    return -1;
    80006164:	557d                	li	a0,-1
    80006166:	b7ed                	j	80006150 <sys_chdir+0x7a>
    iunlockput(ip);
    80006168:	8526                	mv	a0,s1
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	fe2080e7          	jalr	-30(ra) # 8000414c <iunlockput>
    end_op();
    80006172:	ffffe097          	auipc	ra,0xffffe
    80006176:	7ca080e7          	jalr	1994(ra) # 8000493c <end_op>
    return -1;
    8000617a:	557d                	li	a0,-1
    8000617c:	bfd1                	j	80006150 <sys_chdir+0x7a>

000000008000617e <sys_exec>:

uint64
sys_exec(void)
{
    8000617e:	7145                	addi	sp,sp,-464
    80006180:	e786                	sd	ra,456(sp)
    80006182:	e3a2                	sd	s0,448(sp)
    80006184:	ff26                	sd	s1,440(sp)
    80006186:	fb4a                	sd	s2,432(sp)
    80006188:	f74e                	sd	s3,424(sp)
    8000618a:	f352                	sd	s4,416(sp)
    8000618c:	ef56                	sd	s5,408(sp)
    8000618e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006190:	08000613          	li	a2,128
    80006194:	f4040593          	addi	a1,s0,-192
    80006198:	4501                	li	a0,0
    8000619a:	ffffd097          	auipc	ra,0xffffd
    8000619e:	176080e7          	jalr	374(ra) # 80003310 <argstr>
    return -1;
    800061a2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061a4:	0c054a63          	bltz	a0,80006278 <sys_exec+0xfa>
    800061a8:	e3840593          	addi	a1,s0,-456
    800061ac:	4505                	li	a0,1
    800061ae:	ffffd097          	auipc	ra,0xffffd
    800061b2:	140080e7          	jalr	320(ra) # 800032ee <argaddr>
    800061b6:	0c054163          	bltz	a0,80006278 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061ba:	10000613          	li	a2,256
    800061be:	4581                	li	a1,0
    800061c0:	e4040513          	addi	a0,s0,-448
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	b1c080e7          	jalr	-1252(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061cc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061d0:	89a6                	mv	s3,s1
    800061d2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061d4:	02000a13          	li	s4,32
    800061d8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061dc:	00391513          	slli	a0,s2,0x3
    800061e0:	e3040593          	addi	a1,s0,-464
    800061e4:	e3843783          	ld	a5,-456(s0)
    800061e8:	953e                	add	a0,a0,a5
    800061ea:	ffffd097          	auipc	ra,0xffffd
    800061ee:	048080e7          	jalr	72(ra) # 80003232 <fetchaddr>
    800061f2:	02054a63          	bltz	a0,80006226 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800061f6:	e3043783          	ld	a5,-464(s0)
    800061fa:	c3b9                	beqz	a5,80006240 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800061fc:	ffffb097          	auipc	ra,0xffffb
    80006200:	8f8080e7          	jalr	-1800(ra) # 80000af4 <kalloc>
    80006204:	85aa                	mv	a1,a0
    80006206:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000620a:	cd11                	beqz	a0,80006226 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000620c:	6605                	lui	a2,0x1
    8000620e:	e3043503          	ld	a0,-464(s0)
    80006212:	ffffd097          	auipc	ra,0xffffd
    80006216:	072080e7          	jalr	114(ra) # 80003284 <fetchstr>
    8000621a:	00054663          	bltz	a0,80006226 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000621e:	0905                	addi	s2,s2,1
    80006220:	09a1                	addi	s3,s3,8
    80006222:	fb491be3          	bne	s2,s4,800061d8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006226:	10048913          	addi	s2,s1,256
    8000622a:	6088                	ld	a0,0(s1)
    8000622c:	c529                	beqz	a0,80006276 <sys_exec+0xf8>
    kfree(argv[i]);
    8000622e:	ffffa097          	auipc	ra,0xffffa
    80006232:	7ca080e7          	jalr	1994(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006236:	04a1                	addi	s1,s1,8
    80006238:	ff2499e3          	bne	s1,s2,8000622a <sys_exec+0xac>
  return -1;
    8000623c:	597d                	li	s2,-1
    8000623e:	a82d                	j	80006278 <sys_exec+0xfa>
      argv[i] = 0;
    80006240:	0a8e                	slli	s5,s5,0x3
    80006242:	fc040793          	addi	a5,s0,-64
    80006246:	9abe                	add	s5,s5,a5
    80006248:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000624c:	e4040593          	addi	a1,s0,-448
    80006250:	f4040513          	addi	a0,s0,-192
    80006254:	fffff097          	auipc	ra,0xfffff
    80006258:	194080e7          	jalr	404(ra) # 800053e8 <exec>
    8000625c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000625e:	10048993          	addi	s3,s1,256
    80006262:	6088                	ld	a0,0(s1)
    80006264:	c911                	beqz	a0,80006278 <sys_exec+0xfa>
    kfree(argv[i]);
    80006266:	ffffa097          	auipc	ra,0xffffa
    8000626a:	792080e7          	jalr	1938(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000626e:	04a1                	addi	s1,s1,8
    80006270:	ff3499e3          	bne	s1,s3,80006262 <sys_exec+0xe4>
    80006274:	a011                	j	80006278 <sys_exec+0xfa>
  return -1;
    80006276:	597d                	li	s2,-1
}
    80006278:	854a                	mv	a0,s2
    8000627a:	60be                	ld	ra,456(sp)
    8000627c:	641e                	ld	s0,448(sp)
    8000627e:	74fa                	ld	s1,440(sp)
    80006280:	795a                	ld	s2,432(sp)
    80006282:	79ba                	ld	s3,424(sp)
    80006284:	7a1a                	ld	s4,416(sp)
    80006286:	6afa                	ld	s5,408(sp)
    80006288:	6179                	addi	sp,sp,464
    8000628a:	8082                	ret

000000008000628c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000628c:	7139                	addi	sp,sp,-64
    8000628e:	fc06                	sd	ra,56(sp)
    80006290:	f822                	sd	s0,48(sp)
    80006292:	f426                	sd	s1,40(sp)
    80006294:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006296:	ffffb097          	auipc	ra,0xffffb
    8000629a:	742080e7          	jalr	1858(ra) # 800019d8 <myproc>
    8000629e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800062a0:	fd840593          	addi	a1,s0,-40
    800062a4:	4501                	li	a0,0
    800062a6:	ffffd097          	auipc	ra,0xffffd
    800062aa:	048080e7          	jalr	72(ra) # 800032ee <argaddr>
    return -1;
    800062ae:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800062b0:	0e054063          	bltz	a0,80006390 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800062b4:	fc840593          	addi	a1,s0,-56
    800062b8:	fd040513          	addi	a0,s0,-48
    800062bc:	fffff097          	auipc	ra,0xfffff
    800062c0:	dfc080e7          	jalr	-516(ra) # 800050b8 <pipealloc>
    return -1;
    800062c4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062c6:	0c054563          	bltz	a0,80006390 <sys_pipe+0x104>
  fd0 = -1;
    800062ca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062ce:	fd043503          	ld	a0,-48(s0)
    800062d2:	fffff097          	auipc	ra,0xfffff
    800062d6:	508080e7          	jalr	1288(ra) # 800057da <fdalloc>
    800062da:	fca42223          	sw	a0,-60(s0)
    800062de:	08054c63          	bltz	a0,80006376 <sys_pipe+0xea>
    800062e2:	fc843503          	ld	a0,-56(s0)
    800062e6:	fffff097          	auipc	ra,0xfffff
    800062ea:	4f4080e7          	jalr	1268(ra) # 800057da <fdalloc>
    800062ee:	fca42023          	sw	a0,-64(s0)
    800062f2:	06054863          	bltz	a0,80006362 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062f6:	4691                	li	a3,4
    800062f8:	fc440613          	addi	a2,s0,-60
    800062fc:	fd843583          	ld	a1,-40(s0)
    80006300:	7ca8                	ld	a0,120(s1)
    80006302:	ffffb097          	auipc	ra,0xffffb
    80006306:	378080e7          	jalr	888(ra) # 8000167a <copyout>
    8000630a:	02054063          	bltz	a0,8000632a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000630e:	4691                	li	a3,4
    80006310:	fc040613          	addi	a2,s0,-64
    80006314:	fd843583          	ld	a1,-40(s0)
    80006318:	0591                	addi	a1,a1,4
    8000631a:	7ca8                	ld	a0,120(s1)
    8000631c:	ffffb097          	auipc	ra,0xffffb
    80006320:	35e080e7          	jalr	862(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006324:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006326:	06055563          	bgez	a0,80006390 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000632a:	fc442783          	lw	a5,-60(s0)
    8000632e:	07f9                	addi	a5,a5,30
    80006330:	078e                	slli	a5,a5,0x3
    80006332:	97a6                	add	a5,a5,s1
    80006334:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006338:	fc042503          	lw	a0,-64(s0)
    8000633c:	0579                	addi	a0,a0,30
    8000633e:	050e                	slli	a0,a0,0x3
    80006340:	9526                	add	a0,a0,s1
    80006342:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006346:	fd043503          	ld	a0,-48(s0)
    8000634a:	fffff097          	auipc	ra,0xfffff
    8000634e:	a3e080e7          	jalr	-1474(ra) # 80004d88 <fileclose>
    fileclose(wf);
    80006352:	fc843503          	ld	a0,-56(s0)
    80006356:	fffff097          	auipc	ra,0xfffff
    8000635a:	a32080e7          	jalr	-1486(ra) # 80004d88 <fileclose>
    return -1;
    8000635e:	57fd                	li	a5,-1
    80006360:	a805                	j	80006390 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006362:	fc442783          	lw	a5,-60(s0)
    80006366:	0007c863          	bltz	a5,80006376 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000636a:	01e78513          	addi	a0,a5,30
    8000636e:	050e                	slli	a0,a0,0x3
    80006370:	9526                	add	a0,a0,s1
    80006372:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006376:	fd043503          	ld	a0,-48(s0)
    8000637a:	fffff097          	auipc	ra,0xfffff
    8000637e:	a0e080e7          	jalr	-1522(ra) # 80004d88 <fileclose>
    fileclose(wf);
    80006382:	fc843503          	ld	a0,-56(s0)
    80006386:	fffff097          	auipc	ra,0xfffff
    8000638a:	a02080e7          	jalr	-1534(ra) # 80004d88 <fileclose>
    return -1;
    8000638e:	57fd                	li	a5,-1
}
    80006390:	853e                	mv	a0,a5
    80006392:	70e2                	ld	ra,56(sp)
    80006394:	7442                	ld	s0,48(sp)
    80006396:	74a2                	ld	s1,40(sp)
    80006398:	6121                	addi	sp,sp,64
    8000639a:	8082                	ret
    8000639c:	0000                	unimp
	...

00000000800063a0 <kernelvec>:
    800063a0:	7111                	addi	sp,sp,-256
    800063a2:	e006                	sd	ra,0(sp)
    800063a4:	e40a                	sd	sp,8(sp)
    800063a6:	e80e                	sd	gp,16(sp)
    800063a8:	ec12                	sd	tp,24(sp)
    800063aa:	f016                	sd	t0,32(sp)
    800063ac:	f41a                	sd	t1,40(sp)
    800063ae:	f81e                	sd	t2,48(sp)
    800063b0:	fc22                	sd	s0,56(sp)
    800063b2:	e0a6                	sd	s1,64(sp)
    800063b4:	e4aa                	sd	a0,72(sp)
    800063b6:	e8ae                	sd	a1,80(sp)
    800063b8:	ecb2                	sd	a2,88(sp)
    800063ba:	f0b6                	sd	a3,96(sp)
    800063bc:	f4ba                	sd	a4,104(sp)
    800063be:	f8be                	sd	a5,112(sp)
    800063c0:	fcc2                	sd	a6,120(sp)
    800063c2:	e146                	sd	a7,128(sp)
    800063c4:	e54a                	sd	s2,136(sp)
    800063c6:	e94e                	sd	s3,144(sp)
    800063c8:	ed52                	sd	s4,152(sp)
    800063ca:	f156                	sd	s5,160(sp)
    800063cc:	f55a                	sd	s6,168(sp)
    800063ce:	f95e                	sd	s7,176(sp)
    800063d0:	fd62                	sd	s8,184(sp)
    800063d2:	e1e6                	sd	s9,192(sp)
    800063d4:	e5ea                	sd	s10,200(sp)
    800063d6:	e9ee                	sd	s11,208(sp)
    800063d8:	edf2                	sd	t3,216(sp)
    800063da:	f1f6                	sd	t4,224(sp)
    800063dc:	f5fa                	sd	t5,232(sp)
    800063de:	f9fe                	sd	t6,240(sp)
    800063e0:	cf3fc0ef          	jal	ra,800030d2 <kerneltrap>
    800063e4:	6082                	ld	ra,0(sp)
    800063e6:	6122                	ld	sp,8(sp)
    800063e8:	61c2                	ld	gp,16(sp)
    800063ea:	7282                	ld	t0,32(sp)
    800063ec:	7322                	ld	t1,40(sp)
    800063ee:	73c2                	ld	t2,48(sp)
    800063f0:	7462                	ld	s0,56(sp)
    800063f2:	6486                	ld	s1,64(sp)
    800063f4:	6526                	ld	a0,72(sp)
    800063f6:	65c6                	ld	a1,80(sp)
    800063f8:	6666                	ld	a2,88(sp)
    800063fa:	7686                	ld	a3,96(sp)
    800063fc:	7726                	ld	a4,104(sp)
    800063fe:	77c6                	ld	a5,112(sp)
    80006400:	7866                	ld	a6,120(sp)
    80006402:	688a                	ld	a7,128(sp)
    80006404:	692a                	ld	s2,136(sp)
    80006406:	69ca                	ld	s3,144(sp)
    80006408:	6a6a                	ld	s4,152(sp)
    8000640a:	7a8a                	ld	s5,160(sp)
    8000640c:	7b2a                	ld	s6,168(sp)
    8000640e:	7bca                	ld	s7,176(sp)
    80006410:	7c6a                	ld	s8,184(sp)
    80006412:	6c8e                	ld	s9,192(sp)
    80006414:	6d2e                	ld	s10,200(sp)
    80006416:	6dce                	ld	s11,208(sp)
    80006418:	6e6e                	ld	t3,216(sp)
    8000641a:	7e8e                	ld	t4,224(sp)
    8000641c:	7f2e                	ld	t5,232(sp)
    8000641e:	7fce                	ld	t6,240(sp)
    80006420:	6111                	addi	sp,sp,256
    80006422:	10200073          	sret
    80006426:	00000013          	nop
    8000642a:	00000013          	nop
    8000642e:	0001                	nop

0000000080006430 <timervec>:
    80006430:	34051573          	csrrw	a0,mscratch,a0
    80006434:	e10c                	sd	a1,0(a0)
    80006436:	e510                	sd	a2,8(a0)
    80006438:	e914                	sd	a3,16(a0)
    8000643a:	6d0c                	ld	a1,24(a0)
    8000643c:	7110                	ld	a2,32(a0)
    8000643e:	6194                	ld	a3,0(a1)
    80006440:	96b2                	add	a3,a3,a2
    80006442:	e194                	sd	a3,0(a1)
    80006444:	4589                	li	a1,2
    80006446:	14459073          	csrw	sip,a1
    8000644a:	6914                	ld	a3,16(a0)
    8000644c:	6510                	ld	a2,8(a0)
    8000644e:	610c                	ld	a1,0(a0)
    80006450:	34051573          	csrrw	a0,mscratch,a0
    80006454:	30200073          	mret
	...

000000008000645a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000645a:	1141                	addi	sp,sp,-16
    8000645c:	e422                	sd	s0,8(sp)
    8000645e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006460:	0c0007b7          	lui	a5,0xc000
    80006464:	4705                	li	a4,1
    80006466:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006468:	c3d8                	sw	a4,4(a5)
}
    8000646a:	6422                	ld	s0,8(sp)
    8000646c:	0141                	addi	sp,sp,16
    8000646e:	8082                	ret

0000000080006470 <plicinithart>:

void
plicinithart(void)
{
    80006470:	1141                	addi	sp,sp,-16
    80006472:	e406                	sd	ra,8(sp)
    80006474:	e022                	sd	s0,0(sp)
    80006476:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006478:	ffffb097          	auipc	ra,0xffffb
    8000647c:	534080e7          	jalr	1332(ra) # 800019ac <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006480:	0085171b          	slliw	a4,a0,0x8
    80006484:	0c0027b7          	lui	a5,0xc002
    80006488:	97ba                	add	a5,a5,a4
    8000648a:	40200713          	li	a4,1026
    8000648e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006492:	00d5151b          	slliw	a0,a0,0xd
    80006496:	0c2017b7          	lui	a5,0xc201
    8000649a:	953e                	add	a0,a0,a5
    8000649c:	00052023          	sw	zero,0(a0)
}
    800064a0:	60a2                	ld	ra,8(sp)
    800064a2:	6402                	ld	s0,0(sp)
    800064a4:	0141                	addi	sp,sp,16
    800064a6:	8082                	ret

00000000800064a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064a8:	1141                	addi	sp,sp,-16
    800064aa:	e406                	sd	ra,8(sp)
    800064ac:	e022                	sd	s0,0(sp)
    800064ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	4fc080e7          	jalr	1276(ra) # 800019ac <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064b8:	00d5179b          	slliw	a5,a0,0xd
    800064bc:	0c201537          	lui	a0,0xc201
    800064c0:	953e                	add	a0,a0,a5
  return irq;
}
    800064c2:	4148                	lw	a0,4(a0)
    800064c4:	60a2                	ld	ra,8(sp)
    800064c6:	6402                	ld	s0,0(sp)
    800064c8:	0141                	addi	sp,sp,16
    800064ca:	8082                	ret

00000000800064cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064cc:	1101                	addi	sp,sp,-32
    800064ce:	ec06                	sd	ra,24(sp)
    800064d0:	e822                	sd	s0,16(sp)
    800064d2:	e426                	sd	s1,8(sp)
    800064d4:	1000                	addi	s0,sp,32
    800064d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064d8:	ffffb097          	auipc	ra,0xffffb
    800064dc:	4d4080e7          	jalr	1236(ra) # 800019ac <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064e0:	00d5151b          	slliw	a0,a0,0xd
    800064e4:	0c2017b7          	lui	a5,0xc201
    800064e8:	97aa                	add	a5,a5,a0
    800064ea:	c3c4                	sw	s1,4(a5)
}
    800064ec:	60e2                	ld	ra,24(sp)
    800064ee:	6442                	ld	s0,16(sp)
    800064f0:	64a2                	ld	s1,8(sp)
    800064f2:	6105                	addi	sp,sp,32
    800064f4:	8082                	ret

00000000800064f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800064f6:	1141                	addi	sp,sp,-16
    800064f8:	e406                	sd	ra,8(sp)
    800064fa:	e022                	sd	s0,0(sp)
    800064fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800064fe:	479d                	li	a5,7
    80006500:	06a7c963          	blt	a5,a0,80006572 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006504:	0001d797          	auipc	a5,0x1d
    80006508:	afc78793          	addi	a5,a5,-1284 # 80023000 <disk>
    8000650c:	00a78733          	add	a4,a5,a0
    80006510:	6789                	lui	a5,0x2
    80006512:	97ba                	add	a5,a5,a4
    80006514:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006518:	e7ad                	bnez	a5,80006582 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000651a:	00451793          	slli	a5,a0,0x4
    8000651e:	0001f717          	auipc	a4,0x1f
    80006522:	ae270713          	addi	a4,a4,-1310 # 80025000 <disk+0x2000>
    80006526:	6314                	ld	a3,0(a4)
    80006528:	96be                	add	a3,a3,a5
    8000652a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000652e:	6314                	ld	a3,0(a4)
    80006530:	96be                	add	a3,a3,a5
    80006532:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006536:	6314                	ld	a3,0(a4)
    80006538:	96be                	add	a3,a3,a5
    8000653a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000653e:	6318                	ld	a4,0(a4)
    80006540:	97ba                	add	a5,a5,a4
    80006542:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006546:	0001d797          	auipc	a5,0x1d
    8000654a:	aba78793          	addi	a5,a5,-1350 # 80023000 <disk>
    8000654e:	97aa                	add	a5,a5,a0
    80006550:	6509                	lui	a0,0x2
    80006552:	953e                	add	a0,a0,a5
    80006554:	4785                	li	a5,1
    80006556:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000655a:	0001f517          	auipc	a0,0x1f
    8000655e:	abe50513          	addi	a0,a0,-1346 # 80025018 <disk+0x2018>
    80006562:	ffffc097          	auipc	ra,0xffffc
    80006566:	106080e7          	jalr	262(ra) # 80002668 <wakeup>
}
    8000656a:	60a2                	ld	ra,8(sp)
    8000656c:	6402                	ld	s0,0(sp)
    8000656e:	0141                	addi	sp,sp,16
    80006570:	8082                	ret
    panic("free_desc 1");
    80006572:	00002517          	auipc	a0,0x2
    80006576:	2ce50513          	addi	a0,a0,718 # 80008840 <syscalls+0x348>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006582:	00002517          	auipc	a0,0x2
    80006586:	2ce50513          	addi	a0,a0,718 # 80008850 <syscalls+0x358>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>

0000000080006592 <virtio_disk_init>:
{
    80006592:	1101                	addi	sp,sp,-32
    80006594:	ec06                	sd	ra,24(sp)
    80006596:	e822                	sd	s0,16(sp)
    80006598:	e426                	sd	s1,8(sp)
    8000659a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000659c:	00002597          	auipc	a1,0x2
    800065a0:	2c458593          	addi	a1,a1,708 # 80008860 <syscalls+0x368>
    800065a4:	0001f517          	auipc	a0,0x1f
    800065a8:	b8450513          	addi	a0,a0,-1148 # 80025128 <disk+0x2128>
    800065ac:	ffffa097          	auipc	ra,0xffffa
    800065b0:	5a8080e7          	jalr	1448(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065b4:	100017b7          	lui	a5,0x10001
    800065b8:	4398                	lw	a4,0(a5)
    800065ba:	2701                	sext.w	a4,a4
    800065bc:	747277b7          	lui	a5,0x74727
    800065c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065c4:	0ef71163          	bne	a4,a5,800066a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065c8:	100017b7          	lui	a5,0x10001
    800065cc:	43dc                	lw	a5,4(a5)
    800065ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065d0:	4705                	li	a4,1
    800065d2:	0ce79a63          	bne	a5,a4,800066a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065d6:	100017b7          	lui	a5,0x10001
    800065da:	479c                	lw	a5,8(a5)
    800065dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065de:	4709                	li	a4,2
    800065e0:	0ce79363          	bne	a5,a4,800066a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065e4:	100017b7          	lui	a5,0x10001
    800065e8:	47d8                	lw	a4,12(a5)
    800065ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065ec:	554d47b7          	lui	a5,0x554d4
    800065f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065f4:	0af71963          	bne	a4,a5,800066a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065f8:	100017b7          	lui	a5,0x10001
    800065fc:	4705                	li	a4,1
    800065fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006600:	470d                	li	a4,3
    80006602:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006604:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006606:	c7ffe737          	lui	a4,0xc7ffe
    8000660a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000660e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006610:	2701                	sext.w	a4,a4
    80006612:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006614:	472d                	li	a4,11
    80006616:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006618:	473d                	li	a4,15
    8000661a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000661c:	6705                	lui	a4,0x1
    8000661e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006620:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006624:	5bdc                	lw	a5,52(a5)
    80006626:	2781                	sext.w	a5,a5
  if(max == 0)
    80006628:	c7d9                	beqz	a5,800066b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000662a:	471d                	li	a4,7
    8000662c:	08f77d63          	bgeu	a4,a5,800066c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006630:	100014b7          	lui	s1,0x10001
    80006634:	47a1                	li	a5,8
    80006636:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006638:	6609                	lui	a2,0x2
    8000663a:	4581                	li	a1,0
    8000663c:	0001d517          	auipc	a0,0x1d
    80006640:	9c450513          	addi	a0,a0,-1596 # 80023000 <disk>
    80006644:	ffffa097          	auipc	ra,0xffffa
    80006648:	69c080e7          	jalr	1692(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000664c:	0001d717          	auipc	a4,0x1d
    80006650:	9b470713          	addi	a4,a4,-1612 # 80023000 <disk>
    80006654:	00c75793          	srli	a5,a4,0xc
    80006658:	2781                	sext.w	a5,a5
    8000665a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000665c:	0001f797          	auipc	a5,0x1f
    80006660:	9a478793          	addi	a5,a5,-1628 # 80025000 <disk+0x2000>
    80006664:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006666:	0001d717          	auipc	a4,0x1d
    8000666a:	a1a70713          	addi	a4,a4,-1510 # 80023080 <disk+0x80>
    8000666e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006670:	0001e717          	auipc	a4,0x1e
    80006674:	99070713          	addi	a4,a4,-1648 # 80024000 <disk+0x1000>
    80006678:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000667a:	4705                	li	a4,1
    8000667c:	00e78c23          	sb	a4,24(a5)
    80006680:	00e78ca3          	sb	a4,25(a5)
    80006684:	00e78d23          	sb	a4,26(a5)
    80006688:	00e78da3          	sb	a4,27(a5)
    8000668c:	00e78e23          	sb	a4,28(a5)
    80006690:	00e78ea3          	sb	a4,29(a5)
    80006694:	00e78f23          	sb	a4,30(a5)
    80006698:	00e78fa3          	sb	a4,31(a5)
}
    8000669c:	60e2                	ld	ra,24(sp)
    8000669e:	6442                	ld	s0,16(sp)
    800066a0:	64a2                	ld	s1,8(sp)
    800066a2:	6105                	addi	sp,sp,32
    800066a4:	8082                	ret
    panic("could not find virtio disk");
    800066a6:	00002517          	auipc	a0,0x2
    800066aa:	1ca50513          	addi	a0,a0,458 # 80008870 <syscalls+0x378>
    800066ae:	ffffa097          	auipc	ra,0xffffa
    800066b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800066b6:	00002517          	auipc	a0,0x2
    800066ba:	1da50513          	addi	a0,a0,474 # 80008890 <syscalls+0x398>
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	e80080e7          	jalr	-384(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800066c6:	00002517          	auipc	a0,0x2
    800066ca:	1ea50513          	addi	a0,a0,490 # 800088b0 <syscalls+0x3b8>
    800066ce:	ffffa097          	auipc	ra,0xffffa
    800066d2:	e70080e7          	jalr	-400(ra) # 8000053e <panic>

00000000800066d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066d6:	7159                	addi	sp,sp,-112
    800066d8:	f486                	sd	ra,104(sp)
    800066da:	f0a2                	sd	s0,96(sp)
    800066dc:	eca6                	sd	s1,88(sp)
    800066de:	e8ca                	sd	s2,80(sp)
    800066e0:	e4ce                	sd	s3,72(sp)
    800066e2:	e0d2                	sd	s4,64(sp)
    800066e4:	fc56                	sd	s5,56(sp)
    800066e6:	f85a                	sd	s6,48(sp)
    800066e8:	f45e                	sd	s7,40(sp)
    800066ea:	f062                	sd	s8,32(sp)
    800066ec:	ec66                	sd	s9,24(sp)
    800066ee:	e86a                	sd	s10,16(sp)
    800066f0:	1880                	addi	s0,sp,112
    800066f2:	892a                	mv	s2,a0
    800066f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066f6:	00c52c83          	lw	s9,12(a0)
    800066fa:	001c9c9b          	slliw	s9,s9,0x1
    800066fe:	1c82                	slli	s9,s9,0x20
    80006700:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006704:	0001f517          	auipc	a0,0x1f
    80006708:	a2450513          	addi	a0,a0,-1500 # 80025128 <disk+0x2128>
    8000670c:	ffffa097          	auipc	ra,0xffffa
    80006710:	4d8080e7          	jalr	1240(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006714:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006716:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006718:	0001db97          	auipc	s7,0x1d
    8000671c:	8e8b8b93          	addi	s7,s7,-1816 # 80023000 <disk>
    80006720:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006722:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006724:	8a4e                	mv	s4,s3
    80006726:	a051                	j	800067aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006728:	00fb86b3          	add	a3,s7,a5
    8000672c:	96da                	add	a3,a3,s6
    8000672e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006732:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006734:	0207c563          	bltz	a5,8000675e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006738:	2485                	addiw	s1,s1,1
    8000673a:	0711                	addi	a4,a4,4
    8000673c:	25548063          	beq	s1,s5,8000697c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006740:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006742:	0001f697          	auipc	a3,0x1f
    80006746:	8d668693          	addi	a3,a3,-1834 # 80025018 <disk+0x2018>
    8000674a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000674c:	0006c583          	lbu	a1,0(a3)
    80006750:	fde1                	bnez	a1,80006728 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006752:	2785                	addiw	a5,a5,1
    80006754:	0685                	addi	a3,a3,1
    80006756:	ff879be3          	bne	a5,s8,8000674c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000675a:	57fd                	li	a5,-1
    8000675c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000675e:	02905a63          	blez	s1,80006792 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006762:	f9042503          	lw	a0,-112(s0)
    80006766:	00000097          	auipc	ra,0x0
    8000676a:	d90080e7          	jalr	-624(ra) # 800064f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000676e:	4785                	li	a5,1
    80006770:	0297d163          	bge	a5,s1,80006792 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006774:	f9442503          	lw	a0,-108(s0)
    80006778:	00000097          	auipc	ra,0x0
    8000677c:	d7e080e7          	jalr	-642(ra) # 800064f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006780:	4789                	li	a5,2
    80006782:	0097d863          	bge	a5,s1,80006792 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006786:	f9842503          	lw	a0,-104(s0)
    8000678a:	00000097          	auipc	ra,0x0
    8000678e:	d6c080e7          	jalr	-660(ra) # 800064f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006792:	0001f597          	auipc	a1,0x1f
    80006796:	99658593          	addi	a1,a1,-1642 # 80025128 <disk+0x2128>
    8000679a:	0001f517          	auipc	a0,0x1f
    8000679e:	87e50513          	addi	a0,a0,-1922 # 80025018 <disk+0x2018>
    800067a2:	ffffc097          	auipc	ra,0xffffc
    800067a6:	cce080e7          	jalr	-818(ra) # 80002470 <sleep>
  for(int i = 0; i < 3; i++){
    800067aa:	f9040713          	addi	a4,s0,-112
    800067ae:	84ce                	mv	s1,s3
    800067b0:	bf41                	j	80006740 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800067b2:	20058713          	addi	a4,a1,512
    800067b6:	00471693          	slli	a3,a4,0x4
    800067ba:	0001d717          	auipc	a4,0x1d
    800067be:	84670713          	addi	a4,a4,-1978 # 80023000 <disk>
    800067c2:	9736                	add	a4,a4,a3
    800067c4:	4685                	li	a3,1
    800067c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800067ca:	20058713          	addi	a4,a1,512
    800067ce:	00471693          	slli	a3,a4,0x4
    800067d2:	0001d717          	auipc	a4,0x1d
    800067d6:	82e70713          	addi	a4,a4,-2002 # 80023000 <disk>
    800067da:	9736                	add	a4,a4,a3
    800067dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800067e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800067e4:	7679                	lui	a2,0xffffe
    800067e6:	963e                	add	a2,a2,a5
    800067e8:	0001f697          	auipc	a3,0x1f
    800067ec:	81868693          	addi	a3,a3,-2024 # 80025000 <disk+0x2000>
    800067f0:	6298                	ld	a4,0(a3)
    800067f2:	9732                	add	a4,a4,a2
    800067f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800067f6:	6298                	ld	a4,0(a3)
    800067f8:	9732                	add	a4,a4,a2
    800067fa:	4541                	li	a0,16
    800067fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067fe:	6298                	ld	a4,0(a3)
    80006800:	9732                	add	a4,a4,a2
    80006802:	4505                	li	a0,1
    80006804:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006808:	f9442703          	lw	a4,-108(s0)
    8000680c:	6288                	ld	a0,0(a3)
    8000680e:	962a                	add	a2,a2,a0
    80006810:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006814:	0712                	slli	a4,a4,0x4
    80006816:	6290                	ld	a2,0(a3)
    80006818:	963a                	add	a2,a2,a4
    8000681a:	05890513          	addi	a0,s2,88
    8000681e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006820:	6294                	ld	a3,0(a3)
    80006822:	96ba                	add	a3,a3,a4
    80006824:	40000613          	li	a2,1024
    80006828:	c690                	sw	a2,8(a3)
  if(write)
    8000682a:	140d0063          	beqz	s10,8000696a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000682e:	0001e697          	auipc	a3,0x1e
    80006832:	7d26b683          	ld	a3,2002(a3) # 80025000 <disk+0x2000>
    80006836:	96ba                	add	a3,a3,a4
    80006838:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000683c:	0001c817          	auipc	a6,0x1c
    80006840:	7c480813          	addi	a6,a6,1988 # 80023000 <disk>
    80006844:	0001e517          	auipc	a0,0x1e
    80006848:	7bc50513          	addi	a0,a0,1980 # 80025000 <disk+0x2000>
    8000684c:	6114                	ld	a3,0(a0)
    8000684e:	96ba                	add	a3,a3,a4
    80006850:	00c6d603          	lhu	a2,12(a3)
    80006854:	00166613          	ori	a2,a2,1
    80006858:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000685c:	f9842683          	lw	a3,-104(s0)
    80006860:	6110                	ld	a2,0(a0)
    80006862:	9732                	add	a4,a4,a2
    80006864:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006868:	20058613          	addi	a2,a1,512
    8000686c:	0612                	slli	a2,a2,0x4
    8000686e:	9642                	add	a2,a2,a6
    80006870:	577d                	li	a4,-1
    80006872:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006876:	00469713          	slli	a4,a3,0x4
    8000687a:	6114                	ld	a3,0(a0)
    8000687c:	96ba                	add	a3,a3,a4
    8000687e:	03078793          	addi	a5,a5,48
    80006882:	97c2                	add	a5,a5,a6
    80006884:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006886:	611c                	ld	a5,0(a0)
    80006888:	97ba                	add	a5,a5,a4
    8000688a:	4685                	li	a3,1
    8000688c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000688e:	611c                	ld	a5,0(a0)
    80006890:	97ba                	add	a5,a5,a4
    80006892:	4809                	li	a6,2
    80006894:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006898:	611c                	ld	a5,0(a0)
    8000689a:	973e                	add	a4,a4,a5
    8000689c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800068a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800068a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800068a8:	6518                	ld	a4,8(a0)
    800068aa:	00275783          	lhu	a5,2(a4)
    800068ae:	8b9d                	andi	a5,a5,7
    800068b0:	0786                	slli	a5,a5,0x1
    800068b2:	97ba                	add	a5,a5,a4
    800068b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800068b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800068bc:	6518                	ld	a4,8(a0)
    800068be:	00275783          	lhu	a5,2(a4)
    800068c2:	2785                	addiw	a5,a5,1
    800068c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800068c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800068cc:	100017b7          	lui	a5,0x10001
    800068d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800068d4:	00492703          	lw	a4,4(s2)
    800068d8:	4785                	li	a5,1
    800068da:	02f71163          	bne	a4,a5,800068fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800068de:	0001f997          	auipc	s3,0x1f
    800068e2:	84a98993          	addi	s3,s3,-1974 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800068e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800068e8:	85ce                	mv	a1,s3
    800068ea:	854a                	mv	a0,s2
    800068ec:	ffffc097          	auipc	ra,0xffffc
    800068f0:	b84080e7          	jalr	-1148(ra) # 80002470 <sleep>
  while(b->disk == 1) {
    800068f4:	00492783          	lw	a5,4(s2)
    800068f8:	fe9788e3          	beq	a5,s1,800068e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800068fc:	f9042903          	lw	s2,-112(s0)
    80006900:	20090793          	addi	a5,s2,512
    80006904:	00479713          	slli	a4,a5,0x4
    80006908:	0001c797          	auipc	a5,0x1c
    8000690c:	6f878793          	addi	a5,a5,1784 # 80023000 <disk>
    80006910:	97ba                	add	a5,a5,a4
    80006912:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006916:	0001e997          	auipc	s3,0x1e
    8000691a:	6ea98993          	addi	s3,s3,1770 # 80025000 <disk+0x2000>
    8000691e:	00491713          	slli	a4,s2,0x4
    80006922:	0009b783          	ld	a5,0(s3)
    80006926:	97ba                	add	a5,a5,a4
    80006928:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000692c:	854a                	mv	a0,s2
    8000692e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006932:	00000097          	auipc	ra,0x0
    80006936:	bc4080e7          	jalr	-1084(ra) # 800064f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000693a:	8885                	andi	s1,s1,1
    8000693c:	f0ed                	bnez	s1,8000691e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000693e:	0001e517          	auipc	a0,0x1e
    80006942:	7ea50513          	addi	a0,a0,2026 # 80025128 <disk+0x2128>
    80006946:	ffffa097          	auipc	ra,0xffffa
    8000694a:	352080e7          	jalr	850(ra) # 80000c98 <release>
}
    8000694e:	70a6                	ld	ra,104(sp)
    80006950:	7406                	ld	s0,96(sp)
    80006952:	64e6                	ld	s1,88(sp)
    80006954:	6946                	ld	s2,80(sp)
    80006956:	69a6                	ld	s3,72(sp)
    80006958:	6a06                	ld	s4,64(sp)
    8000695a:	7ae2                	ld	s5,56(sp)
    8000695c:	7b42                	ld	s6,48(sp)
    8000695e:	7ba2                	ld	s7,40(sp)
    80006960:	7c02                	ld	s8,32(sp)
    80006962:	6ce2                	ld	s9,24(sp)
    80006964:	6d42                	ld	s10,16(sp)
    80006966:	6165                	addi	sp,sp,112
    80006968:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000696a:	0001e697          	auipc	a3,0x1e
    8000696e:	6966b683          	ld	a3,1686(a3) # 80025000 <disk+0x2000>
    80006972:	96ba                	add	a3,a3,a4
    80006974:	4609                	li	a2,2
    80006976:	00c69623          	sh	a2,12(a3)
    8000697a:	b5c9                	j	8000683c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000697c:	f9042583          	lw	a1,-112(s0)
    80006980:	20058793          	addi	a5,a1,512
    80006984:	0792                	slli	a5,a5,0x4
    80006986:	0001c517          	auipc	a0,0x1c
    8000698a:	72250513          	addi	a0,a0,1826 # 800230a8 <disk+0xa8>
    8000698e:	953e                	add	a0,a0,a5
  if(write)
    80006990:	e20d11e3          	bnez	s10,800067b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006994:	20058713          	addi	a4,a1,512
    80006998:	00471693          	slli	a3,a4,0x4
    8000699c:	0001c717          	auipc	a4,0x1c
    800069a0:	66470713          	addi	a4,a4,1636 # 80023000 <disk>
    800069a4:	9736                	add	a4,a4,a3
    800069a6:	0a072423          	sw	zero,168(a4)
    800069aa:	b505                	j	800067ca <virtio_disk_rw+0xf4>

00000000800069ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800069ac:	1101                	addi	sp,sp,-32
    800069ae:	ec06                	sd	ra,24(sp)
    800069b0:	e822                	sd	s0,16(sp)
    800069b2:	e426                	sd	s1,8(sp)
    800069b4:	e04a                	sd	s2,0(sp)
    800069b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069b8:	0001e517          	auipc	a0,0x1e
    800069bc:	77050513          	addi	a0,a0,1904 # 80025128 <disk+0x2128>
    800069c0:	ffffa097          	auipc	ra,0xffffa
    800069c4:	224080e7          	jalr	548(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069c8:	10001737          	lui	a4,0x10001
    800069cc:	533c                	lw	a5,96(a4)
    800069ce:	8b8d                	andi	a5,a5,3
    800069d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069d6:	0001e797          	auipc	a5,0x1e
    800069da:	62a78793          	addi	a5,a5,1578 # 80025000 <disk+0x2000>
    800069de:	6b94                	ld	a3,16(a5)
    800069e0:	0207d703          	lhu	a4,32(a5)
    800069e4:	0026d783          	lhu	a5,2(a3)
    800069e8:	06f70163          	beq	a4,a5,80006a4a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069ec:	0001c917          	auipc	s2,0x1c
    800069f0:	61490913          	addi	s2,s2,1556 # 80023000 <disk>
    800069f4:	0001e497          	auipc	s1,0x1e
    800069f8:	60c48493          	addi	s1,s1,1548 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800069fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a00:	6898                	ld	a4,16(s1)
    80006a02:	0204d783          	lhu	a5,32(s1)
    80006a06:	8b9d                	andi	a5,a5,7
    80006a08:	078e                	slli	a5,a5,0x3
    80006a0a:	97ba                	add	a5,a5,a4
    80006a0c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a0e:	20078713          	addi	a4,a5,512
    80006a12:	0712                	slli	a4,a4,0x4
    80006a14:	974a                	add	a4,a4,s2
    80006a16:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006a1a:	e731                	bnez	a4,80006a66 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a1c:	20078793          	addi	a5,a5,512
    80006a20:	0792                	slli	a5,a5,0x4
    80006a22:	97ca                	add	a5,a5,s2
    80006a24:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006a26:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a2a:	ffffc097          	auipc	ra,0xffffc
    80006a2e:	c3e080e7          	jalr	-962(ra) # 80002668 <wakeup>

    disk.used_idx += 1;
    80006a32:	0204d783          	lhu	a5,32(s1)
    80006a36:	2785                	addiw	a5,a5,1
    80006a38:	17c2                	slli	a5,a5,0x30
    80006a3a:	93c1                	srli	a5,a5,0x30
    80006a3c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a40:	6898                	ld	a4,16(s1)
    80006a42:	00275703          	lhu	a4,2(a4)
    80006a46:	faf71be3          	bne	a4,a5,800069fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006a4a:	0001e517          	auipc	a0,0x1e
    80006a4e:	6de50513          	addi	a0,a0,1758 # 80025128 <disk+0x2128>
    80006a52:	ffffa097          	auipc	ra,0xffffa
    80006a56:	246080e7          	jalr	582(ra) # 80000c98 <release>
}
    80006a5a:	60e2                	ld	ra,24(sp)
    80006a5c:	6442                	ld	s0,16(sp)
    80006a5e:	64a2                	ld	s1,8(sp)
    80006a60:	6902                	ld	s2,0(sp)
    80006a62:	6105                	addi	sp,sp,32
    80006a64:	8082                	ret
      panic("virtio_disk_intr status");
    80006a66:	00002517          	auipc	a0,0x2
    80006a6a:	e6a50513          	addi	a0,a0,-406 # 800088d0 <syscalls+0x3d8>
    80006a6e:	ffffa097          	auipc	ra,0xffffa
    80006a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>

0000000080006a76 <cas>:
    80006a76:	100522af          	lr.w	t0,(a0)
    80006a7a:	00b29563          	bne	t0,a1,80006a84 <fail>
    80006a7e:	18c5252f          	sc.w	a0,a2,(a0)
    80006a82:	8082                	ret

0000000080006a84 <fail>:
    80006a84:	4505                	li	a0,1
    80006a86:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
