
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	c9013103          	ld	sp,-880(sp) # 80009c90 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	21c78793          	addi	a5,a5,540 # 80007280 <timervec>
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
    8000012c:	00004097          	auipc	ra,0x4
    80000130:	9e8080e7          	jalr	-1560(ra) # 80003b14 <either_copyin>
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
    800001c8:	9d0080e7          	jalr	-1584(ra) # 80001b94 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	aaa080e7          	jalr	-1366(ra) # 80002c7e <sleep>
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
    80000210:	00004097          	auipc	ra,0x4
    80000214:	8ae080e7          	jalr	-1874(ra) # 80003abe <either_copyout>
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
    800002f2:	00004097          	auipc	ra,0x4
    800002f6:	878080e7          	jalr	-1928(ra) # 80003b6a <procdump>
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
    8000044a:	c4e080e7          	jalr	-946(ra) # 80003094 <wakeup>
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
    80000570:	09c50513          	addi	a0,a0,156 # 80009608 <digits+0x5c8>
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
    800008a4:	7f4080e7          	jalr	2036(ra) # 80003094 <wakeup>
    
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
    80000930:	352080e7          	jalr	850(ra) # 80002c7e <sleep>
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
    80000b82:	fea080e7          	jalr	-22(ra) # 80001b68 <mycpu>
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
    80000bb4:	fb8080e7          	jalr	-72(ra) # 80001b68 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	fac080e7          	jalr	-84(ra) # 80001b68 <mycpu>
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
    80000bd8:	f94080e7          	jalr	-108(ra) # 80001b68 <mycpu>
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
    80000c18:	f54080e7          	jalr	-172(ra) # 80001b68 <mycpu>
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
    80000c44:	f28080e7          	jalr	-216(ra) # 80001b68 <mycpu>
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
    80000e9a:	cc2080e7          	jalr	-830(ra) # 80001b58 <cpuid>
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
    80000eb6:	ca6080e7          	jalr	-858(ra) # 80001b58 <cpuid>
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
    80000ed8:	dd6080e7          	jalr	-554(ra) # 80003caa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	3e4080e7          	jalr	996(ra) # 800072c0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	9b2080e7          	jalr	-1614(ra) # 80002896 <scheduler>
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
    80000f08:	70450513          	addi	a0,a0,1796 # 80009608 <digits+0x5c8>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00008517          	auipc	a0,0x8
    80000f18:	18c50513          	addi	a0,a0,396 # 800090a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00008517          	auipc	a0,0x8
    80000f28:	6e450513          	addi	a0,a0,1764 # 80009608 <digits+0x5c8>
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
    80000f58:	d2e080e7          	jalr	-722(ra) # 80003c82 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00003097          	auipc	ra,0x3
    80000f60:	d4e080e7          	jalr	-690(ra) # 80003caa <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00006097          	auipc	ra,0x6
    80000f68:	346080e7          	jalr	838(ra) # 800072aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00006097          	auipc	ra,0x6
    80000f70:	354080e7          	jalr	852(ra) # 800072c0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	532080e7          	jalr	1330(ra) # 800044a6 <binit>
    iinit();         // inode table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	bc2080e7          	jalr	-1086(ra) # 80004b3e <iinit>
    fileinit();      // file table
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	b6c080e7          	jalr	-1172(ra) # 80005af0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00006097          	auipc	ra,0x6
    80000f90:	456080e7          	jalr	1110(ra) # 800073e2 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	1d8080e7          	jalr	472(ra) # 8000216c <userinit>
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
  // if (tail == p->pid)
    // return 0;
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
    8000188e:	03c080e7          	jalr	60(ra) # 800078c6 <cas>
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
    80001940:	f8a080e7          	jalr	-118(ra) # 800078c6 <cas>
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
    80001a38:	e06a                	sd	s10,0(sp)
    80001a3a:	1080                	addi	s0,sp,96
	  struct proc *p;
    int i = 0;
	  
	  initlock(&pid_lock, "nextpid");
    80001a3c:	00008597          	auipc	a1,0x8
    80001a40:	81458593          	addi	a1,a1,-2028 # 80009250 <digits+0x210>
    80001a44:	00011517          	auipc	a0,0x11
    80001a48:	cfc50513          	addi	a0,a0,-772 # 80012740 <pid_lock>
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	108080e7          	jalr	264(ra) # 80000b54 <initlock>
	  initlock(&wait_lock, "wait_lock");
    80001a54:	00008597          	auipc	a1,0x8
    80001a58:	80458593          	addi	a1,a1,-2044 # 80009258 <digits+0x218>
    80001a5c:	00011517          	auipc	a0,0x11
    80001a60:	cfc50513          	addi	a0,a0,-772 # 80012758 <wait_lock>
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	0f0080e7          	jalr	240(ra) # 80000b54 <initlock>
    int i = 0;
    80001a6c:	4901                	li	s2,0
	  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6e:	00011497          	auipc	s1,0x11
    80001a72:	d0248493          	addi	s1,s1,-766 # 80012770 <proc>
	      initlock(&p->lock, "proc");
    80001a76:	00007c97          	auipc	s9,0x7
    80001a7a:	7f2c8c93          	addi	s9,s9,2034 # 80009268 <digits+0x228>
	      p->kstack = KSTACK((int) (p - proc));
    80001a7e:	8c26                	mv	s8,s1
    80001a80:	00007b97          	auipc	s7,0x7
    80001a84:	580b8b93          	addi	s7,s7,1408 # 80009000 <etext>
    80001a88:	04000ab7          	lui	s5,0x4000
    80001a8c:	1afd                	addi	s5,s5,-1
    80001a8e:	0ab2                	slli	s5,s5,0xc

        p->proc_ind = i;                               // Set index to process.
        p->prev_proc = -1;
    80001a90:	59fd                	li	s3,-1
          unused_list_tail = p->proc_ind;
        }
        else
        {
          printf("unused");
          add_proc_to_list(unused_list_tail, p);
    80001a92:	00008a17          	auipc	s4,0x8
    80001a96:	19ea0a13          	addi	s4,s4,414 # 80009c30 <unused_list_tail>
          unused_list_head = p->proc_ind;
    80001a9a:	00008d17          	auipc	s10,0x8
    80001a9e:	19ad0d13          	addi	s10,s10,410 # 80009c34 <unused_list_head>
	  for(p = proc; p < &proc[NPROC]; p++) {
    80001aa2:	00017b17          	auipc	s6,0x17
    80001aa6:	2ceb0b13          	addi	s6,s6,718 # 80018d70 <tickslock>
    80001aaa:	a805                	j	80001ada <procinit+0xba>
          printf("unused");
    80001aac:	00007517          	auipc	a0,0x7
    80001ab0:	7c450513          	addi	a0,a0,1988 # 80009270 <digits+0x230>
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	ad4080e7          	jalr	-1324(ra) # 80000588 <printf>
          add_proc_to_list(unused_list_tail, p);
    80001abc:	85a6                	mv	a1,s1
    80001abe:	000a2503          	lw	a0,0(s4)
    80001ac2:	00000097          	auipc	ra,0x0
    80001ac6:	d84080e7          	jalr	-636(ra) # 80001846 <add_proc_to_list>
          unused_list_tail = p->proc_ind;             // After adding to list, updating tail.
    80001aca:	4cfc                	lw	a5,92(s1)
    80001acc:	00fa2023          	sw	a5,0(s4)
        }
        i ++;
    80001ad0:	2905                	addiw	s2,s2,1
	  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad2:	19848493          	addi	s1,s1,408
    80001ad6:	05648263          	beq	s1,s6,80001b1a <procinit+0xfa>
	      initlock(&p->lock, "proc");
    80001ada:	85e6                	mv	a1,s9
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	076080e7          	jalr	118(ra) # 80000b54 <initlock>
	      p->kstack = KSTACK((int) (p - proc));
    80001ae6:	418487b3          	sub	a5,s1,s8
    80001aea:	878d                	srai	a5,a5,0x3
    80001aec:	000bb703          	ld	a4,0(s7)
    80001af0:	02e787b3          	mul	a5,a5,a4
    80001af4:	2785                	addiw	a5,a5,1
    80001af6:	00d7979b          	slliw	a5,a5,0xd
    80001afa:	40fa87b3          	sub	a5,s5,a5
    80001afe:	f8bc                	sd	a5,112(s1)
        p->proc_ind = i;                               // Set index to process.
    80001b00:	0524ae23          	sw	s2,92(s1)
        p->prev_proc = -1;
    80001b04:	0734a223          	sw	s3,100(s1)
        p->next_proc = -1;
    80001b08:	0734a023          	sw	s3,96(s1)
        if (i == 0)
    80001b0c:	fa0910e3          	bnez	s2,80001aac <procinit+0x8c>
          unused_list_head = p->proc_ind;
    80001b10:	000d2023          	sw	zero,0(s10)
          unused_list_tail = p->proc_ind;
    80001b14:	000a2023          	sw	zero,0(s4)
    80001b18:	bf65                	j	80001ad0 <procinit+0xb0>
      }
  
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b1a:	00010797          	auipc	a5,0x10
    80001b1e:	7a678793          	addi	a5,a5,1958 # 800122c0 <cpus>
  {
    c->runnable_list_head = -1;
    80001b22:	577d                	li	a4,-1
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b24:	00011697          	auipc	a3,0x11
    80001b28:	c1c68693          	addi	a3,a3,-996 # 80012740 <pid_lock>
    c->runnable_list_head = -1;
    80001b2c:	08e7a023          	sw	a4,128(a5)
    c->runnable_list_tail = -1;
    80001b30:	08e7a223          	sw	a4,132(a5)
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001b34:	09078793          	addi	a5,a5,144
    80001b38:	fed79ae3          	bne	a5,a3,80001b2c <procinit+0x10c>
  }
}
    80001b3c:	60e6                	ld	ra,88(sp)
    80001b3e:	6446                	ld	s0,80(sp)
    80001b40:	64a6                	ld	s1,72(sp)
    80001b42:	6906                	ld	s2,64(sp)
    80001b44:	79e2                	ld	s3,56(sp)
    80001b46:	7a42                	ld	s4,48(sp)
    80001b48:	7aa2                	ld	s5,40(sp)
    80001b4a:	7b02                	ld	s6,32(sp)
    80001b4c:	6be2                	ld	s7,24(sp)
    80001b4e:	6c42                	ld	s8,16(sp)
    80001b50:	6ca2                	ld	s9,8(sp)
    80001b52:	6d02                	ld	s10,0(sp)
    80001b54:	6125                	addi	sp,sp,96
    80001b56:	8082                	ret

0000000080001b58 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b58:	1141                	addi	sp,sp,-16
    80001b5a:	e422                	sd	s0,8(sp)
    80001b5c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b5e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b60:	2501                	sext.w	a0,a0
    80001b62:	6422                	ld	s0,8(sp)
    80001b64:	0141                	addi	sp,sp,16
    80001b66:	8082                	ret

0000000080001b68 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b68:	1141                	addi	sp,sp,-16
    80001b6a:	e422                	sd	s0,8(sp)
    80001b6c:	0800                	addi	s0,sp,16
    80001b6e:	8792                	mv	a5,tp
  int id = r_tp();
    80001b70:	0007871b          	sext.w	a4,a5
  int id = cpuid();
  struct cpu *c = &cpus[id];
  c->cpu_id = id;
    80001b74:	00010517          	auipc	a0,0x10
    80001b78:	74c50513          	addi	a0,a0,1868 # 800122c0 <cpus>
    80001b7c:	00371793          	slli	a5,a4,0x3
    80001b80:	00e786b3          	add	a3,a5,a4
    80001b84:	0692                	slli	a3,a3,0x4
    80001b86:	96aa                	add	a3,a3,a0
    80001b88:	08e6a423          	sw	a4,136(a3)
  return c;
}
    80001b8c:	8536                	mv	a0,a3
    80001b8e:	6422                	ld	s0,8(sp)
    80001b90:	0141                	addi	sp,sp,16
    80001b92:	8082                	ret

0000000080001b94 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001b94:	1101                	addi	sp,sp,-32
    80001b96:	ec06                	sd	ra,24(sp)
    80001b98:	e822                	sd	s0,16(sp)
    80001b9a:	e426                	sd	s1,8(sp)
    80001b9c:	1000                	addi	s0,sp,32
  push_off();
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	ffa080e7          	jalr	-6(ra) # 80000b98 <push_off>
    80001ba6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ba8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80001bac:	00010617          	auipc	a2,0x10
    80001bb0:	71460613          	addi	a2,a2,1812 # 800122c0 <cpus>
    80001bb4:	00371793          	slli	a5,a4,0x3
    80001bb8:	00e786b3          	add	a3,a5,a4
    80001bbc:	0692                	slli	a3,a3,0x4
    80001bbe:	96b2                	add	a3,a3,a2
    80001bc0:	08e6a423          	sw	a4,136(a3)
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bc4:	6284                	ld	s1,0(a3)
  pop_off();
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	072080e7          	jalr	114(ra) # 80000c38 <pop_off>
  return p;
}
    80001bce:	8526                	mv	a0,s1
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001bda:	1141                	addi	sp,sp,-16
    80001bdc:	e406                	sd	ra,8(sp)
    80001bde:	e022                	sd	s0,0(sp)
    80001be0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	fb2080e7          	jalr	-78(ra) # 80001b94 <myproc>
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	0ae080e7          	jalr	174(ra) # 80000c98 <release>

  if (first) {
    80001bf2:	00008797          	auipc	a5,0x8
    80001bf6:	02e7a783          	lw	a5,46(a5) # 80009c20 <first.1783>
    80001bfa:	eb89                	bnez	a5,80001c0c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bfc:	00002097          	auipc	ra,0x2
    80001c00:	0c6080e7          	jalr	198(ra) # 80003cc2 <usertrapret>
}
    80001c04:	60a2                	ld	ra,8(sp)
    80001c06:	6402                	ld	s0,0(sp)
    80001c08:	0141                	addi	sp,sp,16
    80001c0a:	8082                	ret
    first = 0;
    80001c0c:	00008797          	auipc	a5,0x8
    80001c10:	0007aa23          	sw	zero,20(a5) # 80009c20 <first.1783>
    fsinit(ROOTDEV);
    80001c14:	4505                	li	a0,1
    80001c16:	00003097          	auipc	ra,0x3
    80001c1a:	ea8080e7          	jalr	-344(ra) # 80004abe <fsinit>
    80001c1e:	bff9                	j	80001bfc <forkret+0x22>

0000000080001c20 <allocpid>:
allocpid() {
    80001c20:	1101                	addi	sp,sp,-32
    80001c22:	ec06                	sd	ra,24(sp)
    80001c24:	e822                	sd	s0,16(sp)
    80001c26:	e426                	sd	s1,8(sp)
    80001c28:	1000                	addi	s0,sp,32
  pid = nextpid;
    80001c2a:	00008517          	auipc	a0,0x8
    80001c2e:	ffa50513          	addi	a0,a0,-6 # 80009c24 <nextpid>
    80001c32:	4104                	lw	s1,0(a0)
  if (cas(&nextpid, pid, (nextpid + 1)) == 0)
    80001c34:	0014861b          	addiw	a2,s1,1
    80001c38:	85a6                	mv	a1,s1
    80001c3a:	00006097          	auipc	ra,0x6
    80001c3e:	c8c080e7          	jalr	-884(ra) # 800078c6 <cas>
    80001c42:	e519                	bnez	a0,80001c50 <allocpid+0x30>
}
    80001c44:	8526                	mv	a0,s1
    80001c46:	60e2                	ld	ra,24(sp)
    80001c48:	6442                	ld	s0,16(sp)
    80001c4a:	64a2                	ld	s1,8(sp)
    80001c4c:	6105                	addi	sp,sp,32
    80001c4e:	8082                	ret
  return allocpid();
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	fd0080e7          	jalr	-48(ra) # 80001c20 <allocpid>
    80001c58:	84aa                	mv	s1,a0
    80001c5a:	b7ed                	j	80001c44 <allocpid+0x24>

0000000080001c5c <proc_pagetable>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
    80001c68:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	6d8080e7          	jalr	1752(ra) # 80001342 <uvmcreate>
    80001c72:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c74:	c121                	beqz	a0,80001cb4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c76:	4729                	li	a4,10
    80001c78:	00006697          	auipc	a3,0x6
    80001c7c:	38868693          	addi	a3,a3,904 # 80008000 <_trampoline>
    80001c80:	6605                	lui	a2,0x1
    80001c82:	040005b7          	lui	a1,0x4000
    80001c86:	15fd                	addi	a1,a1,-1
    80001c88:	05b2                	slli	a1,a1,0xc
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	42e080e7          	jalr	1070(ra) # 800010b8 <mappages>
    80001c92:	02054863          	bltz	a0,80001cc2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c96:	4719                	li	a4,6
    80001c98:	08893683          	ld	a3,136(s2) # 4000088 <_entry-0x7bffff78>
    80001c9c:	6605                	lui	a2,0x1
    80001c9e:	020005b7          	lui	a1,0x2000
    80001ca2:	15fd                	addi	a1,a1,-1
    80001ca4:	05b6                	slli	a1,a1,0xd
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	410080e7          	jalr	1040(ra) # 800010b8 <mappages>
    80001cb0:	02054163          	bltz	a0,80001cd2 <proc_pagetable+0x76>
}
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	60e2                	ld	ra,24(sp)
    80001cb8:	6442                	ld	s0,16(sp)
    80001cba:	64a2                	ld	s1,8(sp)
    80001cbc:	6902                	ld	s2,0(sp)
    80001cbe:	6105                	addi	sp,sp,32
    80001cc0:	8082                	ret
    uvmfree(pagetable, 0);
    80001cc2:	4581                	li	a1,0
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	878080e7          	jalr	-1928(ra) # 8000153e <uvmfree>
    return 0;
    80001cce:	4481                	li	s1,0
    80001cd0:	b7d5                	j	80001cb4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cd2:	4681                	li	a3,0
    80001cd4:	4605                	li	a2,1
    80001cd6:	040005b7          	lui	a1,0x4000
    80001cda:	15fd                	addi	a1,a1,-1
    80001cdc:	05b2                	slli	a1,a1,0xc
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	59e080e7          	jalr	1438(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001ce8:	4581                	li	a1,0
    80001cea:	8526                	mv	a0,s1
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	852080e7          	jalr	-1966(ra) # 8000153e <uvmfree>
    return 0;
    80001cf4:	4481                	li	s1,0
    80001cf6:	bf7d                	j	80001cb4 <proc_pagetable+0x58>

0000000080001cf8 <proc_freepagetable>:
{
    80001cf8:	1101                	addi	sp,sp,-32
    80001cfa:	ec06                	sd	ra,24(sp)
    80001cfc:	e822                	sd	s0,16(sp)
    80001cfe:	e426                	sd	s1,8(sp)
    80001d00:	e04a                	sd	s2,0(sp)
    80001d02:	1000                	addi	s0,sp,32
    80001d04:	84aa                	mv	s1,a0
    80001d06:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d08:	4681                	li	a3,0
    80001d0a:	4605                	li	a2,1
    80001d0c:	040005b7          	lui	a1,0x4000
    80001d10:	15fd                	addi	a1,a1,-1
    80001d12:	05b2                	slli	a1,a1,0xc
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	56a080e7          	jalr	1386(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d1c:	4681                	li	a3,0
    80001d1e:	4605                	li	a2,1
    80001d20:	020005b7          	lui	a1,0x2000
    80001d24:	15fd                	addi	a1,a1,-1
    80001d26:	05b6                	slli	a1,a1,0xd
    80001d28:	8526                	mv	a0,s1
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	554080e7          	jalr	1364(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001d32:	85ca                	mv	a1,s2
    80001d34:	8526                	mv	a0,s1
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	808080e7          	jalr	-2040(ra) # 8000153e <uvmfree>
}
    80001d3e:	60e2                	ld	ra,24(sp)
    80001d40:	6442                	ld	s0,16(sp)
    80001d42:	64a2                	ld	s1,8(sp)
    80001d44:	6902                	ld	s2,0(sp)
    80001d46:	6105                	addi	sp,sp,32
    80001d48:	8082                	ret

0000000080001d4a <freeproc>:
{
    80001d4a:	1101                	addi	sp,sp,-32
    80001d4c:	ec06                	sd	ra,24(sp)
    80001d4e:	e822                	sd	s0,16(sp)
    80001d50:	e426                	sd	s1,8(sp)
    80001d52:	1000                	addi	s0,sp,32
    80001d54:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d56:	6548                	ld	a0,136(a0)
    80001d58:	c509                	beqz	a0,80001d62 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	c9e080e7          	jalr	-866(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d62:	0804b423          	sd	zero,136(s1)
  if(p->pagetable)
    80001d66:	60c8                	ld	a0,128(s1)
    80001d68:	c511                	beqz	a0,80001d74 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d6a:	7cac                	ld	a1,120(s1)
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	f8c080e7          	jalr	-116(ra) # 80001cf8 <proc_freepagetable>
  p->pagetable = 0;
    80001d74:	0804b023          	sd	zero,128(s1)
  p->sz = 0;
    80001d78:	0604bc23          	sd	zero,120(s1)
  p->pid = 0;
    80001d7c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d80:	0604b423          	sd	zero,104(s1)
  p->name[0] = 0;
    80001d84:	18048423          	sb	zero,392(s1)
  p->chan = 0;
    80001d88:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d8c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d90:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d94:	0004ac23          	sw	zero,24(s1)
  printf("zombie");
    80001d98:	00007517          	auipc	a0,0x7
    80001d9c:	4e050513          	addi	a0,a0,1248 # 80009278 <digits+0x238>
    80001da0:	ffffe097          	auipc	ra,0xffffe
    80001da4:	7e8080e7          	jalr	2024(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80001da8:	4ce8                	lw	a0,92(s1)
    80001daa:	00000097          	auipc	ra,0x0
    80001dae:	b1a080e7          	jalr	-1254(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1)
    80001db2:	4785                	li	a5,1
    80001db4:	08f50563          	beq	a0,a5,80001e3e <freeproc+0xf4>
  if (res == 2)
    80001db8:	4789                	li	a5,2
    80001dba:	0af50463          	beq	a0,a5,80001e62 <freeproc+0x118>
  if (res == 3){
    80001dbe:	478d                	li	a5,3
    80001dc0:	04f51763          	bne	a0,a5,80001e0e <freeproc+0xc4>
    zombie_list_tail = p->prev_proc;
    80001dc4:	50fc                	lw	a5,100(s1)
    80001dc6:	00008717          	auipc	a4,0x8
    80001dca:	e6f72123          	sw	a5,-414(a4) # 80009c28 <zombie_list_tail>
     if (proc[p->prev_proc].prev_proc == -1)
    80001dce:	19800713          	li	a4,408
    80001dd2:	02e786b3          	mul	a3,a5,a4
    80001dd6:	00011717          	auipc	a4,0x11
    80001dda:	99a70713          	addi	a4,a4,-1638 # 80012770 <proc>
    80001dde:	9736                	add	a4,a4,a3
    80001de0:	5374                	lw	a3,100(a4)
    80001de2:	577d                	li	a4,-1
    80001de4:	0ce68a63          	beq	a3,a4,80001eb8 <freeproc+0x16e>
    proc[p->prev_proc].next_proc = -1;
    80001de8:	19800713          	li	a4,408
    80001dec:	02e787b3          	mul	a5,a5,a4
    80001df0:	00011717          	auipc	a4,0x11
    80001df4:	98070713          	addi	a4,a4,-1664 # 80012770 <proc>
    80001df8:	97ba                	add	a5,a5,a4
    80001dfa:	577d                	li	a4,-1
    80001dfc:	d3b8                	sw	a4,96(a5)
    printf("1 no tail");
    80001dfe:	00007517          	auipc	a0,0x7
    80001e02:	4aa50513          	addi	a0,a0,1194 # 800092a8 <digits+0x268>
    80001e06:	ffffe097          	auipc	ra,0xffffe
    80001e0a:	782080e7          	jalr	1922(ra) # 80000588 <printf>
  p->next_proc = -1;
    80001e0e:	57fd                	li	a5,-1
    80001e10:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80001e12:	d0fc                	sw	a5,100(s1)
  if (unused_list_tail != -1){
    80001e14:	00008717          	auipc	a4,0x8
    80001e18:	e1c72703          	lw	a4,-484(a4) # 80009c30 <unused_list_tail>
    80001e1c:	57fd                	li	a5,-1
    80001e1e:	0af71263          	bne	a4,a5,80001ec2 <freeproc+0x178>
    unused_list_tail = unused_list_head = p->proc_ind;
    80001e22:	4cfc                	lw	a5,92(s1)
    80001e24:	00008717          	auipc	a4,0x8
    80001e28:	e0f72823          	sw	a5,-496(a4) # 80009c34 <unused_list_head>
    80001e2c:	00008717          	auipc	a4,0x8
    80001e30:	e0f72223          	sw	a5,-508(a4) # 80009c30 <unused_list_tail>
}
    80001e34:	60e2                	ld	ra,24(sp)
    80001e36:	6442                	ld	s0,16(sp)
    80001e38:	64a2                	ld	s1,8(sp)
    80001e3a:	6105                	addi	sp,sp,32
    80001e3c:	8082                	ret
    zombie_list_head = -1;
    80001e3e:	57fd                	li	a5,-1
    80001e40:	00008717          	auipc	a4,0x8
    80001e44:	def72623          	sw	a5,-532(a4) # 80009c2c <zombie_list_head>
    zombie_list_tail = -1;
    80001e48:	00008717          	auipc	a4,0x8
    80001e4c:	def72023          	sw	a5,-544(a4) # 80009c28 <zombie_list_tail>
    printf("2 no head & tail");
    80001e50:	00007517          	auipc	a0,0x7
    80001e54:	43050513          	addi	a0,a0,1072 # 80009280 <digits+0x240>
    80001e58:	ffffe097          	auipc	ra,0xffffe
    80001e5c:	730080e7          	jalr	1840(ra) # 80000588 <printf>
  if (res == 3){
    80001e60:	b77d                	j	80001e0e <freeproc+0xc4>
    zombie_list_head = p->next_proc;
    80001e62:	50bc                	lw	a5,96(s1)
    80001e64:	00008717          	auipc	a4,0x8
    80001e68:	dcf72423          	sw	a5,-568(a4) # 80009c2c <zombie_list_head>
    if (proc[p->next_proc].next_proc == -1)
    80001e6c:	19800713          	li	a4,408
    80001e70:	02e786b3          	mul	a3,a5,a4
    80001e74:	00011717          	auipc	a4,0x11
    80001e78:	8fc70713          	addi	a4,a4,-1796 # 80012770 <proc>
    80001e7c:	9736                	add	a4,a4,a3
    80001e7e:	5334                	lw	a3,96(a4)
    80001e80:	577d                	li	a4,-1
    80001e82:	02e68663          	beq	a3,a4,80001eae <freeproc+0x164>
    proc[p->next_proc].prev_proc = -1;
    80001e86:	19800713          	li	a4,408
    80001e8a:	02e787b3          	mul	a5,a5,a4
    80001e8e:	00011717          	auipc	a4,0x11
    80001e92:	8e270713          	addi	a4,a4,-1822 # 80012770 <proc>
    80001e96:	97ba                	add	a5,a5,a4
    80001e98:	577d                	li	a4,-1
    80001e9a:	d3f8                	sw	a4,100(a5)
    printf("1 no head ");
    80001e9c:	00007517          	auipc	a0,0x7
    80001ea0:	3fc50513          	addi	a0,a0,1020 # 80009298 <digits+0x258>
    80001ea4:	ffffe097          	auipc	ra,0xffffe
    80001ea8:	6e4080e7          	jalr	1764(ra) # 80000588 <printf>
  if (res == 3){
    80001eac:	b78d                	j	80001e0e <freeproc+0xc4>
      zombie_list_tail = p->next_proc;
    80001eae:	00008717          	auipc	a4,0x8
    80001eb2:	d6f72d23          	sw	a5,-646(a4) # 80009c28 <zombie_list_tail>
    80001eb6:	bfc1                	j	80001e86 <freeproc+0x13c>
      zombie_list_head = p->prev_proc;
    80001eb8:	00008717          	auipc	a4,0x8
    80001ebc:	d6f72a23          	sw	a5,-652(a4) # 80009c2c <zombie_list_head>
    80001ec0:	b725                	j	80001de8 <freeproc+0x9e>
    printf("unused");
    80001ec2:	00007517          	auipc	a0,0x7
    80001ec6:	3ae50513          	addi	a0,a0,942 # 80009270 <digits+0x230>
    80001eca:	ffffe097          	auipc	ra,0xffffe
    80001ece:	6be080e7          	jalr	1726(ra) # 80000588 <printf>
    add_proc_to_list(unused_list_tail, p);
    80001ed2:	85a6                	mv	a1,s1
    80001ed4:	00008517          	auipc	a0,0x8
    80001ed8:	d5c52503          	lw	a0,-676(a0) # 80009c30 <unused_list_tail>
    80001edc:	00000097          	auipc	ra,0x0
    80001ee0:	96a080e7          	jalr	-1686(ra) # 80001846 <add_proc_to_list>
    if (unused_list_head == -1)
    80001ee4:	00008717          	auipc	a4,0x8
    80001ee8:	d5072703          	lw	a4,-688(a4) # 80009c34 <unused_list_head>
    80001eec:	57fd                	li	a5,-1
    80001eee:	00f70863          	beq	a4,a5,80001efe <freeproc+0x1b4>
    unused_list_tail = p->proc_ind;
    80001ef2:	4cfc                	lw	a5,92(s1)
    80001ef4:	00008717          	auipc	a4,0x8
    80001ef8:	d2f72e23          	sw	a5,-708(a4) # 80009c30 <unused_list_tail>
    80001efc:	bf25                	j	80001e34 <freeproc+0xea>
    unused_list_head = p->proc_ind;
    80001efe:	4cfc                	lw	a5,92(s1)
    80001f00:	00008717          	auipc	a4,0x8
    80001f04:	d2f72a23          	sw	a5,-716(a4) # 80009c34 <unused_list_head>
    80001f08:	b7ed                	j	80001ef2 <freeproc+0x1a8>

0000000080001f0a <allocproc>:
{
    80001f0a:	7139                	addi	sp,sp,-64
    80001f0c:	fc06                	sd	ra,56(sp)
    80001f0e:	f822                	sd	s0,48(sp)
    80001f10:	f426                	sd	s1,40(sp)
    80001f12:	f04a                	sd	s2,32(sp)
    80001f14:	ec4e                	sd	s3,24(sp)
    80001f16:	e852                	sd	s4,16(sp)
    80001f18:	e456                	sd	s5,8(sp)
    80001f1a:	0080                	addi	s0,sp,64
  while (unused_list_head > -1)
    80001f1c:	00008917          	auipc	s2,0x8
    80001f20:	d1892903          	lw	s2,-744(s2) # 80009c34 <unused_list_head>
  return 0;
    80001f24:	4981                	li	s3,0
  while (unused_list_head > -1)
    80001f26:	00095c63          	bgez	s2,80001f3e <allocproc+0x34>
}
    80001f2a:	854e                	mv	a0,s3
    80001f2c:	70e2                	ld	ra,56(sp)
    80001f2e:	7442                	ld	s0,48(sp)
    80001f30:	74a2                	ld	s1,40(sp)
    80001f32:	7902                	ld	s2,32(sp)
    80001f34:	69e2                	ld	s3,24(sp)
    80001f36:	6a42                	ld	s4,16(sp)
    80001f38:	6aa2                	ld	s5,8(sp)
    80001f3a:	6121                	addi	sp,sp,64
    80001f3c:	8082                	ret
    p = &proc[unused_list_head];
    80001f3e:	19800a13          	li	s4,408
    80001f42:	03490a33          	mul	s4,s2,s4
    80001f46:	00011997          	auipc	s3,0x11
    80001f4a:	82a98993          	addi	s3,s3,-2006 # 80012770 <proc>
    80001f4e:	99d2                	add	s3,s3,s4
    acquire(&p->lock);
    80001f50:	854e                	mv	a0,s3
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	c92080e7          	jalr	-878(ra) # 80000be4 <acquire>
    printf("unused");
    80001f5a:	00007517          	auipc	a0,0x7
    80001f5e:	31650513          	addi	a0,a0,790 # 80009270 <digits+0x230>
    80001f62:	ffffe097          	auipc	ra,0xffffe
    80001f66:	626080e7          	jalr	1574(ra) # 80000588 <printf>
    int res = remove_proc_from_list(unused_list_head); 
    80001f6a:	00008517          	auipc	a0,0x8
    80001f6e:	cca52503          	lw	a0,-822(a0) # 80009c34 <unused_list_head>
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	952080e7          	jalr	-1710(ra) # 800018c4 <remove_proc_from_list>
    if (res == 1)
    80001f7a:	4785                	li	a5,1
    80001f7c:	06f50163          	beq	a0,a5,80001fde <allocproc+0xd4>
    if (res == 2)
    80001f80:	4789                	li	a5,2
    80001f82:	08f50063          	beq	a0,a5,80002002 <allocproc+0xf8>
    if (res == 3)
    80001f86:	478d                	li	a5,3
    80001f88:	0cf51563          	bne	a0,a5,80002052 <allocproc+0x148>
      unused_list_tail = p->prev_proc;      // Update tail.
    80001f8c:	00010717          	auipc	a4,0x10
    80001f90:	7e470713          	addi	a4,a4,2020 # 80012770 <proc>
    80001f94:	19800693          	li	a3,408
    80001f98:	02d907b3          	mul	a5,s2,a3
    80001f9c:	97ba                	add	a5,a5,a4
    80001f9e:	53fc                	lw	a5,100(a5)
    80001fa0:	00008617          	auipc	a2,0x8
    80001fa4:	c8f62823          	sw	a5,-880(a2) # 80009c30 <unused_list_tail>
       if (proc[p->prev_proc].prev_proc == -1)
    80001fa8:	02d786b3          	mul	a3,a5,a3
    80001fac:	9736                	add	a4,a4,a3
    80001fae:	5374                	lw	a3,100(a4)
    80001fb0:	577d                	li	a4,-1
    80001fb2:	14e68c63          	beq	a3,a4,8000210a <allocproc+0x200>
      proc[p->prev_proc].next_proc = -1;    // Remove tail's next.
    80001fb6:	19800713          	li	a4,408
    80001fba:	02e787b3          	mul	a5,a5,a4
    80001fbe:	00010717          	auipc	a4,0x10
    80001fc2:	7b270713          	addi	a4,a4,1970 # 80012770 <proc>
    80001fc6:	97ba                	add	a5,a5,a4
    80001fc8:	577d                	li	a4,-1
    80001fca:	d3b8                	sw	a4,96(a5)
      printf("1 no tail");
    80001fcc:	00007517          	auipc	a0,0x7
    80001fd0:	2dc50513          	addi	a0,a0,732 # 800092a8 <digits+0x268>
    80001fd4:	ffffe097          	auipc	ra,0xffffe
    80001fd8:	5b4080e7          	jalr	1460(ra) # 80000588 <printf>
    80001fdc:	a89d                	j	80002052 <allocproc+0x148>
      unused_list_head = -1;
    80001fde:	57fd                	li	a5,-1
    80001fe0:	00008717          	auipc	a4,0x8
    80001fe4:	c4f72a23          	sw	a5,-940(a4) # 80009c34 <unused_list_head>
      unused_list_tail = -1;
    80001fe8:	00008717          	auipc	a4,0x8
    80001fec:	c4f72423          	sw	a5,-952(a4) # 80009c30 <unused_list_tail>
      printf("1 no head & tail");
    80001ff0:	00007517          	auipc	a0,0x7
    80001ff4:	2c850513          	addi	a0,a0,712 # 800092b8 <digits+0x278>
    80001ff8:	ffffe097          	auipc	ra,0xffffe
    80001ffc:	590080e7          	jalr	1424(ra) # 80000588 <printf>
    if (res == 3)
    80002000:	a889                	j	80002052 <allocproc+0x148>
      unused_list_head = p->next_proc;      // Update head.
    80002002:	00010717          	auipc	a4,0x10
    80002006:	76e70713          	addi	a4,a4,1902 # 80012770 <proc>
    8000200a:	19800693          	li	a3,408
    8000200e:	02d907b3          	mul	a5,s2,a3
    80002012:	97ba                	add	a5,a5,a4
    80002014:	53bc                	lw	a5,96(a5)
    80002016:	00008617          	auipc	a2,0x8
    8000201a:	c0f62f23          	sw	a5,-994(a2) # 80009c34 <unused_list_head>
      if (proc[p->next_proc].next_proc == -1)
    8000201e:	02d786b3          	mul	a3,a5,a3
    80002022:	9736                	add	a4,a4,a3
    80002024:	5334                	lw	a3,96(a4)
    80002026:	577d                	li	a4,-1
    80002028:	0ce68c63          	beq	a3,a4,80002100 <allocproc+0x1f6>
      proc[p->next_proc].prev_proc = -1;    // Remove head's prev.
    8000202c:	19800713          	li	a4,408
    80002030:	02e787b3          	mul	a5,a5,a4
    80002034:	00010717          	auipc	a4,0x10
    80002038:	73c70713          	addi	a4,a4,1852 # 80012770 <proc>
    8000203c:	97ba                	add	a5,a5,a4
    8000203e:	577d                	li	a4,-1
    80002040:	d3f8                	sw	a4,100(a5)
      printf("1 no head");
    80002042:	00007517          	auipc	a0,0x7
    80002046:	28e50513          	addi	a0,a0,654 # 800092d0 <digits+0x290>
    8000204a:	ffffe097          	auipc	ra,0xffffe
    8000204e:	53e080e7          	jalr	1342(ra) # 80000588 <printf>
    p->prev_proc = -1;
    80002052:	19800493          	li	s1,408
    80002056:	029907b3          	mul	a5,s2,s1
    8000205a:	00010497          	auipc	s1,0x10
    8000205e:	71648493          	addi	s1,s1,1814 # 80012770 <proc>
    80002062:	94be                	add	s1,s1,a5
    80002064:	57fd                	li	a5,-1
    80002066:	d0fc                	sw	a5,100(s1)
    p->next_proc = -1;
    80002068:	d0bc                	sw	a5,96(s1)
  p->pid = allocpid();
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	bb6080e7          	jalr	-1098(ra) # 80001c20 <allocpid>
    80002072:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002074:	4785                	li	a5,1
    80002076:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80002078:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    8000207c:	0204ac23          	sw	zero,56(s1)
  p->paused = 0;
    80002080:	0404a023          	sw	zero,64(s1)
  p->sleeping_time = 0;
    80002084:	0404a623          	sw	zero,76(s1)
  p->running_time = 0;
    80002088:	0404a223          	sw	zero,68(s1)
  p->runnable_time = 0;
    8000208c:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	a64080e7          	jalr	-1436(ra) # 80000af4 <kalloc>
    80002098:	8aaa                	mv	s5,a0
    8000209a:	e4c8                	sd	a0,136(s1)
    8000209c:	cd25                	beqz	a0,80002114 <allocproc+0x20a>
  p->pagetable = proc_pagetable(p);
    8000209e:	854e                	mv	a0,s3
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	bbc080e7          	jalr	-1092(ra) # 80001c5c <proc_pagetable>
    800020a8:	84aa                	mv	s1,a0
    800020aa:	19800793          	li	a5,408
    800020ae:	02f90733          	mul	a4,s2,a5
    800020b2:	00010797          	auipc	a5,0x10
    800020b6:	6be78793          	addi	a5,a5,1726 # 80012770 <proc>
    800020ba:	97ba                	add	a5,a5,a4
    800020bc:	e3c8                	sd	a0,128(a5)
  if(p->pagetable == 0){
    800020be:	c53d                	beqz	a0,8000212c <allocproc+0x222>
  memset(&p->context, 0, sizeof(p->context));
    800020c0:	090a0513          	addi	a0,s4,144
    800020c4:	00010497          	auipc	s1,0x10
    800020c8:	6ac48493          	addi	s1,s1,1708 # 80012770 <proc>
    800020cc:	07000613          	li	a2,112
    800020d0:	4581                	li	a1,0
    800020d2:	9526                	add	a0,a0,s1
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	c0c080e7          	jalr	-1012(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    800020dc:	19800793          	li	a5,408
    800020e0:	02f90933          	mul	s2,s2,a5
    800020e4:	9926                	add	s2,s2,s1
    800020e6:	00000797          	auipc	a5,0x0
    800020ea:	af478793          	addi	a5,a5,-1292 # 80001bda <forkret>
    800020ee:	08f93823          	sd	a5,144(s2)
  p->context.sp = p->kstack + PGSIZE;
    800020f2:	07093783          	ld	a5,112(s2)
    800020f6:	6705                	lui	a4,0x1
    800020f8:	97ba                	add	a5,a5,a4
    800020fa:	08f93c23          	sd	a5,152(s2)
  return p;
    800020fe:	b535                	j	80001f2a <allocproc+0x20>
        unused_list_tail = p->next_proc;
    80002100:	00008717          	auipc	a4,0x8
    80002104:	b2f72823          	sw	a5,-1232(a4) # 80009c30 <unused_list_tail>
    80002108:	b715                	j	8000202c <allocproc+0x122>
        unused_list_head = p->prev_proc;
    8000210a:	00008717          	auipc	a4,0x8
    8000210e:	b2f72523          	sw	a5,-1238(a4) # 80009c34 <unused_list_head>
    80002112:	b555                	j	80001fb6 <allocproc+0xac>
    freeproc(p);
    80002114:	854e                	mv	a0,s3
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	c34080e7          	jalr	-972(ra) # 80001d4a <freeproc>
    release(&p->lock);
    8000211e:	854e                	mv	a0,s3
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	b78080e7          	jalr	-1160(ra) # 80000c98 <release>
    return 0;
    80002128:	89d6                	mv	s3,s5
    8000212a:	b501                	j	80001f2a <allocproc+0x20>
    freeproc(p);
    8000212c:	854e                	mv	a0,s3
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	c1c080e7          	jalr	-996(ra) # 80001d4a <freeproc>
    release(&p->lock);
    80002136:	854e                	mv	a0,s3
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b60080e7          	jalr	-1184(ra) # 80000c98 <release>
    return 0;
    80002140:	89a6                	mv	s3,s1
    80002142:	b3e5                	j	80001f2a <allocproc+0x20>

0000000080002144 <str_compare>:
{
    80002144:	1141                	addi	sp,sp,-16
    80002146:	e422                	sd	s0,8(sp)
    80002148:	0800                	addi	s0,sp,16
      c1 = (unsigned char) *s1++;
    8000214a:	0505                	addi	a0,a0,1
    8000214c:	fff54783          	lbu	a5,-1(a0)
      c2 = (unsigned char) *s2++;
    80002150:	0585                	addi	a1,a1,1
    80002152:	fff5c703          	lbu	a4,-1(a1) # 1ffffff <_entry-0x7e000001>
      if (c1 == '\0')
    80002156:	c791                	beqz	a5,80002162 <str_compare+0x1e>
  while (c1 == c2);
    80002158:	fee789e3          	beq	a5,a4,8000214a <str_compare+0x6>
  return c1 - c2;
    8000215c:	40e7853b          	subw	a0,a5,a4
    80002160:	a019                	j	80002166 <str_compare+0x22>
        return c1 - c2;
    80002162:	40e0053b          	negw	a0,a4
}
    80002166:	6422                	ld	s0,8(sp)
    80002168:	0141                	addi	sp,sp,16
    8000216a:	8082                	ret

000000008000216c <userinit>:
{
    8000216c:	1101                	addi	sp,sp,-32
    8000216e:	ec06                	sd	ra,24(sp)
    80002170:	e822                	sd	s0,16(sp)
    80002172:	e426                	sd	s1,8(sp)
    80002174:	e04a                	sd	s2,0(sp)
    80002176:	1000                	addi	s0,sp,32
  p = allocproc();
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	d92080e7          	jalr	-622(ra) # 80001f0a <allocproc>
    80002180:	84aa                	mv	s1,a0
  initproc = p;
    80002182:	00008797          	auipc	a5,0x8
    80002186:	eaa7b323          	sd	a0,-346(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000218a:	03400613          	li	a2,52
    8000218e:	00008597          	auipc	a1,0x8
    80002192:	ac258593          	addi	a1,a1,-1342 # 80009c50 <initcode>
    80002196:	6148                	ld	a0,128(a0)
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	1d8080e7          	jalr	472(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    800021a0:	6785                	lui	a5,0x1
    800021a2:	fcbc                	sd	a5,120(s1)
  p->trapframe->epc = 0;      // user program counter
    800021a4:	64d8                	ld	a4,136(s1)
    800021a6:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021aa:	64d8                	ld	a4,136(s1)
    800021ac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021ae:	4641                	li	a2,16
    800021b0:	00007597          	auipc	a1,0x7
    800021b4:	13058593          	addi	a1,a1,304 # 800092e0 <digits+0x2a0>
    800021b8:	18848513          	addi	a0,s1,392
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	c76080e7          	jalr	-906(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800021c4:	00007517          	auipc	a0,0x7
    800021c8:	12c50513          	addi	a0,a0,300 # 800092f0 <digits+0x2b0>
    800021cc:	00003097          	auipc	ra,0x3
    800021d0:	320080e7          	jalr	800(ra) # 800054ec <namei>
    800021d4:	18a4b023          	sd	a0,384(s1)
  p->state = RUNNABLE;
    800021d8:	478d                	li	a5,3
    800021da:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    800021dc:	00008797          	auipc	a5,0x8
    800021e0:	e787a783          	lw	a5,-392(a5) # 8000a054 <ticks>
    800021e4:	dcdc                	sw	a5,60(s1)
    800021e6:	8792                	mv	a5,tp
  int id = r_tp();
    800021e8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800021ec:	00010617          	auipc	a2,0x10
    800021f0:	0d460613          	addi	a2,a2,212 # 800122c0 <cpus>
    800021f4:	00371793          	slli	a5,a4,0x3
    800021f8:	00e786b3          	add	a3,a5,a4
    800021fc:	0692                	slli	a3,a3,0x4
    800021fe:	96b2                	add	a3,a3,a2
    80002200:	08e6a423          	sw	a4,136(a3)
  if (mycpu()->runnable_list_head == -1)
    80002204:	0806a703          	lw	a4,128(a3)
    80002208:	57fd                	li	a5,-1
    8000220a:	06f70c63          	beq	a4,a5,80002282 <userinit+0x116>
    printf("runnable1");
    8000220e:	00007517          	auipc	a0,0x7
    80002212:	10a50513          	addi	a0,a0,266 # 80009318 <digits+0x2d8>
    80002216:	ffffe097          	auipc	ra,0xffffe
    8000221a:	372080e7          	jalr	882(ra) # 80000588 <printf>
    8000221e:	8792                	mv	a5,tp
  int id = r_tp();
    80002220:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002224:	00010917          	auipc	s2,0x10
    80002228:	09c90913          	addi	s2,s2,156 # 800122c0 <cpus>
    8000222c:	00371793          	slli	a5,a4,0x3
    80002230:	00e786b3          	add	a3,a5,a4
    80002234:	0692                	slli	a3,a3,0x4
    80002236:	96ca                	add	a3,a3,s2
    80002238:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    8000223c:	85a6                	mv	a1,s1
    8000223e:	0846a503          	lw	a0,132(a3)
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	604080e7          	jalr	1540(ra) # 80001846 <add_proc_to_list>
    8000224a:	8792                	mv	a5,tp
  int id = r_tp();
    8000224c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002250:	00371793          	slli	a5,a4,0x3
    80002254:	00e786b3          	add	a3,a5,a4
    80002258:	0692                	slli	a3,a3,0x4
    8000225a:	96ca                	add	a3,a3,s2
    8000225c:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002260:	4cf4                	lw	a3,92(s1)
    80002262:	97ba                	add	a5,a5,a4
    80002264:	0792                	slli	a5,a5,0x4
    80002266:	993e                	add	s2,s2,a5
    80002268:	08d92223          	sw	a3,132(s2)
  release(&p->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	a2a080e7          	jalr	-1494(ra) # 80000c98 <release>
}
    80002276:	60e2                	ld	ra,24(sp)
    80002278:	6442                	ld	s0,16(sp)
    8000227a:	64a2                	ld	s1,8(sp)
    8000227c:	6902                	ld	s2,0(sp)
    8000227e:	6105                	addi	sp,sp,32
    80002280:	8082                	ret
    printf("init runnable: %d            1\n", p->proc_ind);
    80002282:	4cec                	lw	a1,92(s1)
    80002284:	00007517          	auipc	a0,0x7
    80002288:	07450513          	addi	a0,a0,116 # 800092f8 <digits+0x2b8>
    8000228c:	ffffe097          	auipc	ra,0xffffe
    80002290:	2fc080e7          	jalr	764(ra) # 80000588 <printf>
    80002294:	8792                	mv	a5,tp
  int id = r_tp();
    80002296:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    8000229a:	00010717          	auipc	a4,0x10
    8000229e:	02670713          	addi	a4,a4,38 # 800122c0 <cpus>
    800022a2:	00369793          	slli	a5,a3,0x3
    800022a6:	00d78633          	add	a2,a5,a3
    800022aa:	0612                	slli	a2,a2,0x4
    800022ac:	963a                	add	a2,a2,a4
    800022ae:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    800022b2:	4cf0                	lw	a2,92(s1)
    800022b4:	97b6                	add	a5,a5,a3
    800022b6:	0792                	slli	a5,a5,0x4
    800022b8:	97ba                	add	a5,a5,a4
    800022ba:	08c7a023          	sw	a2,128(a5)
    800022be:	8792                	mv	a5,tp
  int id = r_tp();
    800022c0:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    800022c4:	00369793          	slli	a5,a3,0x3
    800022c8:	00d78633          	add	a2,a5,a3
    800022cc:	0612                	slli	a2,a2,0x4
    800022ce:	963a                	add	a2,a2,a4
    800022d0:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    800022d4:	4cf0                	lw	a2,92(s1)
    800022d6:	97b6                	add	a5,a5,a3
    800022d8:	0792                	slli	a5,a5,0x4
    800022da:	973e                	add	a4,a4,a5
    800022dc:	08c72223          	sw	a2,132(a4)
    800022e0:	b771                	j	8000226c <userinit+0x100>

00000000800022e2 <growproc>:
{
    800022e2:	1101                	addi	sp,sp,-32
    800022e4:	ec06                	sd	ra,24(sp)
    800022e6:	e822                	sd	s0,16(sp)
    800022e8:	e426                	sd	s1,8(sp)
    800022ea:	e04a                	sd	s2,0(sp)
    800022ec:	1000                	addi	s0,sp,32
    800022ee:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800022f0:	00000097          	auipc	ra,0x0
    800022f4:	8a4080e7          	jalr	-1884(ra) # 80001b94 <myproc>
    800022f8:	892a                	mv	s2,a0
  sz = p->sz;
    800022fa:	7d2c                	ld	a1,120(a0)
    800022fc:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002300:	00904f63          	bgtz	s1,8000231e <growproc+0x3c>
  } else if(n < 0){
    80002304:	0204cc63          	bltz	s1,8000233c <growproc+0x5a>
  p->sz = sz;
    80002308:	1602                	slli	a2,a2,0x20
    8000230a:	9201                	srli	a2,a2,0x20
    8000230c:	06c93c23          	sd	a2,120(s2)
  return 0;
    80002310:	4501                	li	a0,0
}
    80002312:	60e2                	ld	ra,24(sp)
    80002314:	6442                	ld	s0,16(sp)
    80002316:	64a2                	ld	s1,8(sp)
    80002318:	6902                	ld	s2,0(sp)
    8000231a:	6105                	addi	sp,sp,32
    8000231c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000231e:	9e25                	addw	a2,a2,s1
    80002320:	1602                	slli	a2,a2,0x20
    80002322:	9201                	srli	a2,a2,0x20
    80002324:	1582                	slli	a1,a1,0x20
    80002326:	9181                	srli	a1,a1,0x20
    80002328:	6148                	ld	a0,128(a0)
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	100080e7          	jalr	256(ra) # 8000142a <uvmalloc>
    80002332:	0005061b          	sext.w	a2,a0
    80002336:	fa69                	bnez	a2,80002308 <growproc+0x26>
      return -1;
    80002338:	557d                	li	a0,-1
    8000233a:	bfe1                	j	80002312 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000233c:	9e25                	addw	a2,a2,s1
    8000233e:	1602                	slli	a2,a2,0x20
    80002340:	9201                	srli	a2,a2,0x20
    80002342:	1582                	slli	a1,a1,0x20
    80002344:	9181                	srli	a1,a1,0x20
    80002346:	6148                	ld	a0,128(a0)
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	09a080e7          	jalr	154(ra) # 800013e2 <uvmdealloc>
    80002350:	0005061b          	sext.w	a2,a0
    80002354:	bf55                	j	80002308 <growproc+0x26>

0000000080002356 <fork>:
{
    80002356:	7139                	addi	sp,sp,-64
    80002358:	fc06                	sd	ra,56(sp)
    8000235a:	f822                	sd	s0,48(sp)
    8000235c:	f426                	sd	s1,40(sp)
    8000235e:	f04a                	sd	s2,32(sp)
    80002360:	ec4e                	sd	s3,24(sp)
    80002362:	e852                	sd	s4,16(sp)
    80002364:	e456                	sd	s5,8(sp)
    80002366:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	82c080e7          	jalr	-2004(ra) # 80001b94 <myproc>
    80002370:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002372:	00000097          	auipc	ra,0x0
    80002376:	b98080e7          	jalr	-1128(ra) # 80001f0a <allocproc>
    8000237a:	20050663          	beqz	a0,80002586 <fork+0x230>
    8000237e:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002380:	0789b603          	ld	a2,120(s3)
    80002384:	614c                	ld	a1,128(a0)
    80002386:	0809b503          	ld	a0,128(s3)
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	1ec080e7          	jalr	492(ra) # 80001576 <uvmcopy>
    80002392:	04054663          	bltz	a0,800023de <fork+0x88>
  np->sz = p->sz;
    80002396:	0789b783          	ld	a5,120(s3)
    8000239a:	06f93c23          	sd	a5,120(s2)
  *(np->trapframe) = *(p->trapframe);
    8000239e:	0889b683          	ld	a3,136(s3)
    800023a2:	87b6                	mv	a5,a3
    800023a4:	08893703          	ld	a4,136(s2)
    800023a8:	12068693          	addi	a3,a3,288
    800023ac:	0007b803          	ld	a6,0(a5)
    800023b0:	6788                	ld	a0,8(a5)
    800023b2:	6b8c                	ld	a1,16(a5)
    800023b4:	6f90                	ld	a2,24(a5)
    800023b6:	01073023          	sd	a6,0(a4)
    800023ba:	e708                	sd	a0,8(a4)
    800023bc:	eb0c                	sd	a1,16(a4)
    800023be:	ef10                	sd	a2,24(a4)
    800023c0:	02078793          	addi	a5,a5,32
    800023c4:	02070713          	addi	a4,a4,32
    800023c8:	fed792e3          	bne	a5,a3,800023ac <fork+0x56>
  np->trapframe->a0 = 0;
    800023cc:	08893783          	ld	a5,136(s2)
    800023d0:	0607b823          	sd	zero,112(a5)
    800023d4:	10000493          	li	s1,256
  for(i = 0; i < NOFILE; i++)
    800023d8:	18000a13          	li	s4,384
    800023dc:	a03d                	j	8000240a <fork+0xb4>
    freeproc(np);
    800023de:	854a                	mv	a0,s2
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	96a080e7          	jalr	-1686(ra) # 80001d4a <freeproc>
    release(&np->lock);
    800023e8:	854a                	mv	a0,s2
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8ae080e7          	jalr	-1874(ra) # 80000c98 <release>
    return -1;
    800023f2:	5a7d                	li	s4,-1
    800023f4:	aa39                	j	80002512 <fork+0x1bc>
      np->ofile[i] = filedup(p->ofile[i]);
    800023f6:	00003097          	auipc	ra,0x3
    800023fa:	78c080e7          	jalr	1932(ra) # 80005b82 <filedup>
    800023fe:	009907b3          	add	a5,s2,s1
    80002402:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002404:	04a1                	addi	s1,s1,8
    80002406:	01448763          	beq	s1,s4,80002414 <fork+0xbe>
    if(p->ofile[i])
    8000240a:	009987b3          	add	a5,s3,s1
    8000240e:	6388                	ld	a0,0(a5)
    80002410:	f17d                	bnez	a0,800023f6 <fork+0xa0>
    80002412:	bfcd                	j	80002404 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002414:	1809b503          	ld	a0,384(s3)
    80002418:	00003097          	auipc	ra,0x3
    8000241c:	8e0080e7          	jalr	-1824(ra) # 80004cf8 <idup>
    80002420:	18a93023          	sd	a0,384(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002424:	4641                	li	a2,16
    80002426:	18898593          	addi	a1,s3,392
    8000242a:	18890513          	addi	a0,s2,392
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	a04080e7          	jalr	-1532(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002436:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    8000243a:	854a                	mv	a0,s2
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	85c080e7          	jalr	-1956(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002444:	00010497          	auipc	s1,0x10
    80002448:	e7c48493          	addi	s1,s1,-388 # 800122c0 <cpus>
    8000244c:	00010a97          	auipc	s5,0x10
    80002450:	30ca8a93          	addi	s5,s5,780 # 80012758 <wait_lock>
    80002454:	8556                	mv	a0,s5
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	78e080e7          	jalr	1934(ra) # 80000be4 <acquire>
  np->parent = p;
    8000245e:	07393423          	sd	s3,104(s2)
  release(&wait_lock);
    80002462:	8556                	mv	a0,s5
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	834080e7          	jalr	-1996(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000246c:	854a                	mv	a0,s2
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	776080e7          	jalr	1910(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002476:	478d                	li	a5,3
    80002478:	00f92c23          	sw	a5,24(s2)
  np->last_runnable_time = ticks;
    8000247c:	00008797          	auipc	a5,0x8
    80002480:	bd87a783          	lw	a5,-1064(a5) # 8000a054 <ticks>
    80002484:	02f92e23          	sw	a5,60(s2)
    80002488:	8792                	mv	a5,tp
  int id = r_tp();
    8000248a:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    8000248e:	00371793          	slli	a5,a4,0x3
    80002492:	00e786b3          	add	a3,a5,a4
    80002496:	0692                	slli	a3,a3,0x4
    80002498:	96a6                	add	a3,a3,s1
    8000249a:	08e6a423          	sw	a4,136(a3)
  if (mycpu()->runnable_list_head == -1)
    8000249e:	0806a703          	lw	a4,128(a3)
    800024a2:	57fd                	li	a5,-1
    800024a4:	08f70163          	beq	a4,a5,80002526 <fork+0x1d0>
    printf("runnable2");
    800024a8:	00007517          	auipc	a0,0x7
    800024ac:	ea850513          	addi	a0,a0,-344 # 80009350 <digits+0x310>
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	0d8080e7          	jalr	216(ra) # 80000588 <printf>
    800024b8:	8792                	mv	a5,tp
  int id = r_tp();
    800024ba:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800024be:	00010497          	auipc	s1,0x10
    800024c2:	e0248493          	addi	s1,s1,-510 # 800122c0 <cpus>
    800024c6:	00371793          	slli	a5,a4,0x3
    800024ca:	00e786b3          	add	a3,a5,a4
    800024ce:	0692                	slli	a3,a3,0x4
    800024d0:	96a6                	add	a3,a3,s1
    800024d2:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, np);
    800024d6:	85ca                	mv	a1,s2
    800024d8:	0846a503          	lw	a0,132(a3)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	36a080e7          	jalr	874(ra) # 80001846 <add_proc_to_list>
    800024e4:	8792                	mv	a5,tp
  int id = r_tp();
    800024e6:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    800024ea:	00371793          	slli	a5,a4,0x3
    800024ee:	00e786b3          	add	a3,a5,a4
    800024f2:	0692                	slli	a3,a3,0x4
    800024f4:	96a6                	add	a3,a3,s1
    800024f6:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = np->proc_ind;
    800024fa:	05c92683          	lw	a3,92(s2)
    800024fe:	97ba                	add	a5,a5,a4
    80002500:	0792                	slli	a5,a5,0x4
    80002502:	94be                	add	s1,s1,a5
    80002504:	08d4a223          	sw	a3,132(s1)
  release(&np->lock);
    80002508:	854a                	mv	a0,s2
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	78e080e7          	jalr	1934(ra) # 80000c98 <release>
}
    80002512:	8552                	mv	a0,s4
    80002514:	70e2                	ld	ra,56(sp)
    80002516:	7442                	ld	s0,48(sp)
    80002518:	74a2                	ld	s1,40(sp)
    8000251a:	7902                	ld	s2,32(sp)
    8000251c:	69e2                	ld	s3,24(sp)
    8000251e:	6a42                	ld	s4,16(sp)
    80002520:	6aa2                	ld	s5,8(sp)
    80002522:	6121                	addi	sp,sp,64
    80002524:	8082                	ret
    printf("init runnable %d                 2\n", p->proc_ind);
    80002526:	05c9a583          	lw	a1,92(s3)
    8000252a:	00007517          	auipc	a0,0x7
    8000252e:	dfe50513          	addi	a0,a0,-514 # 80009328 <digits+0x2e8>
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	056080e7          	jalr	86(ra) # 80000588 <printf>
    8000253a:	8792                	mv	a5,tp
  int id = r_tp();
    8000253c:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002540:	00369793          	slli	a5,a3,0x3
    80002544:	00d78633          	add	a2,a5,a3
    80002548:	0612                	slli	a2,a2,0x4
    8000254a:	9626                	add	a2,a2,s1
    8000254c:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = np->proc_ind;
    80002550:	05c92603          	lw	a2,92(s2)
    80002554:	97b6                	add	a5,a5,a3
    80002556:	0792                	slli	a5,a5,0x4
    80002558:	97a6                	add	a5,a5,s1
    8000255a:	08c7a023          	sw	a2,128(a5)
    8000255e:	8792                	mv	a5,tp
  int id = r_tp();
    80002560:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002564:	00369793          	slli	a5,a3,0x3
    80002568:	00d78633          	add	a2,a5,a3
    8000256c:	0612                	slli	a2,a2,0x4
    8000256e:	9626                	add	a2,a2,s1
    80002570:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = np->proc_ind;
    80002574:	05c92603          	lw	a2,92(s2)
    80002578:	97b6                	add	a5,a5,a3
    8000257a:	0792                	slli	a5,a5,0x4
    8000257c:	00f48733          	add	a4,s1,a5
    80002580:	08c72223          	sw	a2,132(a4)
    80002584:	b751                	j	80002508 <fork+0x1b2>
    return -1;
    80002586:	5a7d                	li	s4,-1
    80002588:	b769                	j	80002512 <fork+0x1bc>

000000008000258a <unpause_system>:
{
    8000258a:	7179                	addi	sp,sp,-48
    8000258c:	f406                	sd	ra,40(sp)
    8000258e:	f022                	sd	s0,32(sp)
    80002590:	ec26                	sd	s1,24(sp)
    80002592:	e84a                	sd	s2,16(sp)
    80002594:	e44e                	sd	s3,8(sp)
    80002596:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) 
    80002598:	00010497          	auipc	s1,0x10
    8000259c:	1d848493          	addi	s1,s1,472 # 80012770 <proc>
      if(p->paused == 1) 
    800025a0:	4985                	li	s3,1
  for(p = proc; p < &proc[NPROC]; p++) 
    800025a2:	00016917          	auipc	s2,0x16
    800025a6:	7ce90913          	addi	s2,s2,1998 # 80018d70 <tickslock>
    800025aa:	a811                	j	800025be <unpause_system+0x34>
      release(&p->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) 
    800025b6:	19848493          	addi	s1,s1,408
    800025ba:	01248d63          	beq	s1,s2,800025d4 <unpause_system+0x4a>
      acquire(&p->lock);
    800025be:	8526                	mv	a0,s1
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	624080e7          	jalr	1572(ra) # 80000be4 <acquire>
      if(p->paused == 1) 
    800025c8:	40bc                	lw	a5,64(s1)
    800025ca:	ff3791e3          	bne	a5,s3,800025ac <unpause_system+0x22>
        p->paused = 0;
    800025ce:	0404a023          	sw	zero,64(s1)
    800025d2:	bfe9                	j	800025ac <unpause_system+0x22>
} 
    800025d4:	70a2                	ld	ra,40(sp)
    800025d6:	7402                	ld	s0,32(sp)
    800025d8:	64e2                	ld	s1,24(sp)
    800025da:	6942                	ld	s2,16(sp)
    800025dc:	69a2                	ld	s3,8(sp)
    800025de:	6145                	addi	sp,sp,48
    800025e0:	8082                	ret

00000000800025e2 <SJF_scheduler>:
{
    800025e2:	711d                	addi	sp,sp,-96
    800025e4:	ec86                	sd	ra,88(sp)
    800025e6:	e8a2                	sd	s0,80(sp)
    800025e8:	e4a6                	sd	s1,72(sp)
    800025ea:	e0ca                	sd	s2,64(sp)
    800025ec:	fc4e                	sd	s3,56(sp)
    800025ee:	f852                	sd	s4,48(sp)
    800025f0:	f456                	sd	s5,40(sp)
    800025f2:	f05a                	sd	s6,32(sp)
    800025f4:	ec5e                	sd	s7,24(sp)
    800025f6:	e862                	sd	s8,16(sp)
    800025f8:	e466                	sd	s9,8(sp)
    800025fa:	e06a                	sd	s10,0(sp)
    800025fc:	1080                	addi	s0,sp,96
    800025fe:	8792                	mv	a5,tp
  int id = r_tp();
    80002600:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80002602:	00010617          	auipc	a2,0x10
    80002606:	cbe60613          	addi	a2,a2,-834 # 800122c0 <cpus>
    8000260a:	00379713          	slli	a4,a5,0x3
    8000260e:	00f706b3          	add	a3,a4,a5
    80002612:	0692                	slli	a3,a3,0x4
    80002614:	96b2                	add	a3,a3,a2
    80002616:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    8000261a:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p_of_min->context);
    8000261e:	973e                	add	a4,a4,a5
    80002620:	0712                	slli	a4,a4,0x4
    80002622:	0721                	addi	a4,a4,8
    80002624:	00e60d33          	add	s10,a2,a4
    struct proc* p_of_min = proc;
    80002628:	00010a97          	auipc	s5,0x10
    8000262c:	148a8a93          	addi	s5,s5,328 # 80012770 <proc>
    uint min = INT_MAX;
    80002630:	80000b37          	lui	s6,0x80000
    80002634:	fffb4b13          	not	s6,s6
           should_switch = 1;
    80002638:	4a05                	li	s4,1
    8000263a:	89d2                	mv	s3,s4
      c->proc = p_of_min;
    8000263c:	8bb6                	mv	s7,a3
    8000263e:	a091                	j	80002682 <SJF_scheduler+0xa0>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002640:	19878793          	addi	a5,a5,408
    80002644:	00d78c63          	beq	a5,a3,8000265c <SJF_scheduler+0x7a>
       if(p->state == RUNNABLE) {
    80002648:	4f98                	lw	a4,24(a5)
    8000264a:	fec71be3          	bne	a4,a2,80002640 <SJF_scheduler+0x5e>
         if (p->mean_ticks < min)
    8000264e:	5bd8                	lw	a4,52(a5)
    80002650:	feb778e3          	bgeu	a4,a1,80002640 <SJF_scheduler+0x5e>
    80002654:	84be                	mv	s1,a5
           min = p->mean_ticks;
    80002656:	85ba                	mv	a1,a4
           should_switch = 1;
    80002658:	894e                	mv	s2,s3
    8000265a:	b7dd                	j	80002640 <SJF_scheduler+0x5e>
    acquire(&p_of_min->lock);
    8000265c:	8c26                	mv	s8,s1
    8000265e:	8526                	mv	a0,s1
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	584080e7          	jalr	1412(ra) # 80000be4 <acquire>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    80002668:	03490d63          	beq	s2,s4,800026a2 <SJF_scheduler+0xc0>
    release(&p_of_min->lock);
    8000266c:	8562                	mv	a0,s8
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	62a080e7          	jalr	1578(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    80002676:	00008797          	auipc	a5,0x8
    8000267a:	9da7a783          	lw	a5,-1574(a5) # 8000a050 <pause_flag>
    8000267e:	0b478163          	beq	a5,s4,80002720 <SJF_scheduler+0x13e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002682:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002686:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000268a:	10079073          	csrw	sstatus,a5
    int should_switch = 0;
    8000268e:	4901                	li	s2,0
    struct proc* p_of_min = proc;
    80002690:	84d6                	mv	s1,s5
    uint min = INT_MAX;
    80002692:	85da                	mv	a1,s6
    for(p = proc; p < &proc[NPROC]; p++) {
    80002694:	87d6                	mv	a5,s5
       if(p->state == RUNNABLE) {
    80002696:	460d                	li	a2,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80002698:	00016697          	auipc	a3,0x16
    8000269c:	6d868693          	addi	a3,a3,1752 # 80018d70 <tickslock>
    800026a0:	b765                	j	80002648 <SJF_scheduler+0x66>
    if (should_switch == 1 && p_of_min->state == RUNNABLE && p_of_min->paused == 0){
    800026a2:	4c98                	lw	a4,24(s1)
    800026a4:	478d                	li	a5,3
    800026a6:	fcf713e3          	bne	a4,a5,8000266c <SJF_scheduler+0x8a>
    800026aa:	40bc                	lw	a5,64(s1)
    800026ac:	f3e1                	bnez	a5,8000266c <SJF_scheduler+0x8a>
      p_of_min->state = RUNNING;
    800026ae:	4791                	li	a5,4
    800026b0:	cc9c                	sw	a5,24(s1)
      p_of_min->start_running_time = ticks;
    800026b2:	00008c97          	auipc	s9,0x8
    800026b6:	9a2c8c93          	addi	s9,s9,-1630 # 8000a054 <ticks>
    800026ba:	000ca903          	lw	s2,0(s9)
    800026be:	0524a823          	sw	s2,80(s1)
      p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    800026c2:	44bc                	lw	a5,72(s1)
    800026c4:	012787bb          	addw	a5,a5,s2
    800026c8:	5cd8                	lw	a4,60(s1)
    800026ca:	9f99                	subw	a5,a5,a4
    800026cc:	c4bc                	sw	a5,72(s1)
      c->proc = p_of_min;
    800026ce:	009bb023          	sd	s1,0(s7)
      swtch(&c->context, &p_of_min->context);
    800026d2:	09048593          	addi	a1,s1,144
    800026d6:	856a                	mv	a0,s10
    800026d8:	00001097          	auipc	ra,0x1
    800026dc:	540080e7          	jalr	1344(ra) # 80003c18 <swtch>
      p_of_min->last_ticks= ticks - before_swtch;
    800026e0:	000ca783          	lw	a5,0(s9)
    800026e4:	4127893b          	subw	s2,a5,s2
    800026e8:	0324ac23          	sw	s2,56(s1)
      p_of_min->mean_ticks=((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10 ;
    800026ec:	00007617          	auipc	a2,0x7
    800026f0:	55462603          	lw	a2,1364(a2) # 80009c40 <rate>
    800026f4:	46a9                	li	a3,10
    800026f6:	40c687bb          	subw	a5,a3,a2
    800026fa:	00016717          	auipc	a4,0x16
    800026fe:	07670713          	addi	a4,a4,118 # 80018770 <proc+0x6000>
    80002702:	63472583          	lw	a1,1588(a4)
    80002706:	02b787bb          	mulw	a5,a5,a1
    8000270a:	63872703          	lw	a4,1592(a4)
    8000270e:	02c7073b          	mulw	a4,a4,a2
    80002712:	9fb9                	addw	a5,a5,a4
    80002714:	02d7d7bb          	divuw	a5,a5,a3
    80002718:	d8dc                	sw	a5,52(s1)
      c->proc = 0;
    8000271a:	000bb023          	sd	zero,0(s7)
    8000271e:	b7b9                	j	8000266c <SJF_scheduler+0x8a>
      if (wake_up_time <= ticks) 
    80002720:	00008717          	auipc	a4,0x8
    80002724:	92c72703          	lw	a4,-1748(a4) # 8000a04c <wake_up_time>
    80002728:	00008797          	auipc	a5,0x8
    8000272c:	92c7a783          	lw	a5,-1748(a5) # 8000a054 <ticks>
    80002730:	f4e7e9e3          	bltu	a5,a4,80002682 <SJF_scheduler+0xa0>
        pause_flag = 0;
    80002734:	00008797          	auipc	a5,0x8
    80002738:	9007ae23          	sw	zero,-1764(a5) # 8000a050 <pause_flag>
        unpause_system();
    8000273c:	00000097          	auipc	ra,0x0
    80002740:	e4e080e7          	jalr	-434(ra) # 8000258a <unpause_system>
    80002744:	bf3d                	j	80002682 <SJF_scheduler+0xa0>

0000000080002746 <FCFS_scheduler>:
{
    80002746:	7119                	addi	sp,sp,-128
    80002748:	fc86                	sd	ra,120(sp)
    8000274a:	f8a2                	sd	s0,112(sp)
    8000274c:	f4a6                	sd	s1,104(sp)
    8000274e:	f0ca                	sd	s2,96(sp)
    80002750:	ecce                	sd	s3,88(sp)
    80002752:	e8d2                	sd	s4,80(sp)
    80002754:	e4d6                	sd	s5,72(sp)
    80002756:	e0da                	sd	s6,64(sp)
    80002758:	fc5e                	sd	s7,56(sp)
    8000275a:	f862                	sd	s8,48(sp)
    8000275c:	f466                	sd	s9,40(sp)
    8000275e:	f06a                	sd	s10,32(sp)
    80002760:	ec6e                	sd	s11,24(sp)
    80002762:	0100                	addi	s0,sp,128
  asm volatile("mv %0, tp" : "=r" (x) );
    80002764:	8792                	mv	a5,tp
  int id = r_tp();
    80002766:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    80002768:	00010617          	auipc	a2,0x10
    8000276c:	b5860613          	addi	a2,a2,-1192 # 800122c0 <cpus>
    80002770:	00379713          	slli	a4,a5,0x3
    80002774:	00f706b3          	add	a3,a4,a5
    80002778:	0692                	slli	a3,a3,0x4
    8000277a:	96b2                	add	a3,a3,a2
    8000277c:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    80002780:	0006b023          	sd	zero,0(a3)
        swtch(&c->context, &p_of_min->context);
    80002784:	973e                	add	a4,a4,a5
    80002786:	0712                	slli	a4,a4,0x4
    80002788:	0721                	addi	a4,a4,8
    8000278a:	9732                	add	a4,a4,a2
    8000278c:	f8e43423          	sd	a4,-120(s0)
  int should_switch = 0;
    80002790:	4b01                	li	s6,0
    struct proc *p_of_min = proc;
    80002792:	00010c17          	auipc	s8,0x10
    80002796:	fdec0c13          	addi	s8,s8,-34 # 80012770 <proc>
    uint minlast_runnable = INT_MAX;
    8000279a:	80000d37          	lui	s10,0x80000
    8000279e:	fffd4d13          	not	s10,s10
          should_switch = 1;
    800027a2:	4c85                	li	s9,1
    800027a4:	8be6                	mv	s7,s9
        c->proc = p_of_min;
    800027a6:	8db6                	mv	s11,a3
    800027a8:	a095                	j	8000280c <FCFS_scheduler+0xc6>
      release(&p->lock);
    800027aa:	8526                	mv	a0,s1
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	4ec080e7          	jalr	1260(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) 
    800027b4:	19848493          	addi	s1,s1,408
    800027b8:	03248463          	beq	s1,s2,800027e0 <FCFS_scheduler+0x9a>
      acquire(&p->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	426080e7          	jalr	1062(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && p->paused == 0) 
    800027c6:	4c9c                	lw	a5,24(s1)
    800027c8:	ff3791e3          	bne	a5,s3,800027aa <FCFS_scheduler+0x64>
    800027cc:	40bc                	lw	a5,64(s1)
    800027ce:	fff1                	bnez	a5,800027aa <FCFS_scheduler+0x64>
        if(p->last_runnable_time <= minlast_runnable)
    800027d0:	5cdc                	lw	a5,60(s1)
    800027d2:	fcfa6ce3          	bltu	s4,a5,800027aa <FCFS_scheduler+0x64>
          minlast_runnable = p->mean_ticks;
    800027d6:	0344aa03          	lw	s4,52(s1)
    800027da:	8aa6                	mv	s5,s1
          should_switch = 1;
    800027dc:	8b5e                	mv	s6,s7
    800027de:	b7f1                	j	800027aa <FCFS_scheduler+0x64>
    acquire(&p_of_min->lock);
    800027e0:	8956                	mv	s2,s5
    800027e2:	8556                	mv	a0,s5
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	400080e7          	jalr	1024(ra) # 80000be4 <acquire>
    if (p_of_min->paused == 0)
    800027ec:	040aa483          	lw	s1,64(s5)
    800027f0:	e099                	bnez	s1,800027f6 <FCFS_scheduler+0xb0>
      if (should_switch == 1 && p_of_min->pid > -1)
    800027f2:	039b0c63          	beq	s6,s9,8000282a <FCFS_scheduler+0xe4>
    release(&p_of_min->lock);
    800027f6:	854a                	mv	a0,s2
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	4a0080e7          	jalr	1184(ra) # 80000c98 <release>
    if (pause_flag == 1) 
    80002800:	00008797          	auipc	a5,0x8
    80002804:	8507a783          	lw	a5,-1968(a5) # 8000a050 <pause_flag>
    80002808:	07978463          	beq	a5,s9,80002870 <FCFS_scheduler+0x12a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002810:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002814:	10079073          	csrw	sstatus,a5
    struct proc *p_of_min = proc;
    80002818:	8ae2                	mv	s5,s8
    uint minlast_runnable = INT_MAX;
    8000281a:	8a6a                	mv	s4,s10
    for(p = proc; p < &proc[NPROC]; p++) 
    8000281c:	84e2                	mv	s1,s8
      if(p->state == RUNNABLE && p->paused == 0) 
    8000281e:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) 
    80002820:	00016917          	auipc	s2,0x16
    80002824:	55090913          	addi	s2,s2,1360 # 80018d70 <tickslock>
    80002828:	bf51                	j	800027bc <FCFS_scheduler+0x76>
      if (should_switch == 1 && p_of_min->pid > -1)
    8000282a:	030aa783          	lw	a5,48(s5)
    8000282e:	fc07c4e3          	bltz	a5,800027f6 <FCFS_scheduler+0xb0>
        p_of_min->state = RUNNING;
    80002832:	4791                	li	a5,4
    80002834:	00faac23          	sw	a5,24(s5)
        p_of_min->start_running_time = ticks;
    80002838:	00008717          	auipc	a4,0x8
    8000283c:	81c72703          	lw	a4,-2020(a4) # 8000a054 <ticks>
    80002840:	04eaa823          	sw	a4,80(s5)
        p_of_min->runnable_time += ticks - p_of_min->last_runnable_time;
    80002844:	048aa783          	lw	a5,72(s5)
    80002848:	9fb9                	addw	a5,a5,a4
    8000284a:	03caa703          	lw	a4,60(s5)
    8000284e:	9f99                	subw	a5,a5,a4
    80002850:	04faa423          	sw	a5,72(s5)
        c->proc = p_of_min;
    80002854:	015db023          	sd	s5,0(s11)
        swtch(&c->context, &p_of_min->context);
    80002858:	090a8593          	addi	a1,s5,144
    8000285c:	f8843503          	ld	a0,-120(s0)
    80002860:	00001097          	auipc	ra,0x1
    80002864:	3b8080e7          	jalr	952(ra) # 80003c18 <swtch>
        c->proc = 0;
    80002868:	000db023          	sd	zero,0(s11)
        should_switch = 0;
    8000286c:	8b26                	mv	s6,s1
    8000286e:	b761                	j	800027f6 <FCFS_scheduler+0xb0>
      if (wake_up_time <= ticks) 
    80002870:	00007717          	auipc	a4,0x7
    80002874:	7dc72703          	lw	a4,2012(a4) # 8000a04c <wake_up_time>
    80002878:	00007797          	auipc	a5,0x7
    8000287c:	7dc7a783          	lw	a5,2012(a5) # 8000a054 <ticks>
    80002880:	f8e7e6e3          	bltu	a5,a4,8000280c <FCFS_scheduler+0xc6>
        pause_flag = 0;
    80002884:	00007797          	auipc	a5,0x7
    80002888:	7c07a623          	sw	zero,1996(a5) # 8000a050 <pause_flag>
        unpause_system();
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	cfe080e7          	jalr	-770(ra) # 8000258a <unpause_system>
    80002894:	bfa5                	j	8000280c <FCFS_scheduler+0xc6>

0000000080002896 <scheduler>:
{
    80002896:	7159                	addi	sp,sp,-112
    80002898:	f486                	sd	ra,104(sp)
    8000289a:	f0a2                	sd	s0,96(sp)
    8000289c:	eca6                	sd	s1,88(sp)
    8000289e:	e8ca                	sd	s2,80(sp)
    800028a0:	e4ce                	sd	s3,72(sp)
    800028a2:	e0d2                	sd	s4,64(sp)
    800028a4:	fc56                	sd	s5,56(sp)
    800028a6:	f85a                	sd	s6,48(sp)
    800028a8:	f45e                	sd	s7,40(sp)
    800028aa:	f062                	sd	s8,32(sp)
    800028ac:	ec66                	sd	s9,24(sp)
    800028ae:	e86a                	sd	s10,16(sp)
    800028b0:	e46e                	sd	s11,8(sp)
    800028b2:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    800028b4:	8792                	mv	a5,tp
  int id = r_tp();
    800028b6:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800028b8:	00010c17          	auipc	s8,0x10
    800028bc:	a08c0c13          	addi	s8,s8,-1528 # 800122c0 <cpus>
    800028c0:	00379713          	slli	a4,a5,0x3
    800028c4:	00f706b3          	add	a3,a4,a5
    800028c8:	0692                	slli	a3,a3,0x4
    800028ca:	96e2                	add	a3,a3,s8
    800028cc:	08f6a423          	sw	a5,136(a3)
  c->proc = 0;
    800028d0:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    800028d4:	973e                	add	a4,a4,a5
    800028d6:	0712                	slli	a4,a4,0x4
    800028d8:	0721                	addi	a4,a4,8
    800028da:	9c3a                	add	s8,s8,a4
    printf("start sched\n");
    800028dc:	00007a17          	auipc	s4,0x7
    800028e0:	a84a0a13          	addi	s4,s4,-1404 # 80009360 <digits+0x320>
    if (c->runnable_list_head != -1)
    800028e4:	8936                	mv	s2,a3
    800028e6:	59fd                	li	s3,-1
    800028e8:	19800b13          	li	s6,408
      p = &proc[c->runnable_list_head];
    800028ec:	00010a97          	auipc	s5,0x10
    800028f0:	e84a8a93          	addi	s5,s5,-380 # 80012770 <proc>
      printf("proc ind: %d\n", c->runnable_list_head);
    800028f4:	00007c97          	auipc	s9,0x7
    800028f8:	a7cc8c93          	addi	s9,s9,-1412 # 80009370 <digits+0x330>
        proc[p->prev_proc].next_proc = -1;
    800028fc:	5bfd                	li	s7,-1
    800028fe:	a0d1                	j	800029c2 <scheduler+0x12c>
        c->runnable_list_head = -1;
    80002900:	09792023          	sw	s7,128(s2)
        c->runnable_list_tail = -1;
    80002904:	09792223          	sw	s7,132(s2)
        printf("No head & tail");
    80002908:	00007517          	auipc	a0,0x7
    8000290c:	a8850513          	addi	a0,a0,-1400 # 80009390 <digits+0x350>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	c78080e7          	jalr	-904(ra) # 80000588 <printf>
      if (res == 3){
    80002918:	a899                	j	8000296e <scheduler+0xd8>
        c->runnable_list_head = p->next_proc;
    8000291a:	036487b3          	mul	a5,s1,s6
    8000291e:	97d6                	add	a5,a5,s5
    80002920:	53ac                	lw	a1,96(a5)
    80002922:	08b92023          	sw	a1,128(s2)
        if (proc[p->next_proc].next_proc == -1)
    80002926:	036587b3          	mul	a5,a1,s6
    8000292a:	97d6                	add	a5,a5,s5
    8000292c:	53bc                	lw	a5,96(a5)
    8000292e:	03378063          	beq	a5,s3,8000294e <scheduler+0xb8>
        proc[p->next_proc].prev_proc = -1;
    80002932:	036587b3          	mul	a5,a1,s6
    80002936:	97d6                	add	a5,a5,s5
    80002938:	0777a223          	sw	s7,100(a5)
        printf("New head: %d\n", c->runnable_list_head);
    8000293c:	00007517          	auipc	a0,0x7
    80002940:	a6450513          	addi	a0,a0,-1436 # 800093a0 <digits+0x360>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c44080e7          	jalr	-956(ra) # 80000588 <printf>
      if (res == 3){
    8000294c:	a00d                	j	8000296e <scheduler+0xd8>
          c->runnable_list_tail = p->next_proc;
    8000294e:	08b92223          	sw	a1,132(s2)
    80002952:	b7c5                	j	80002932 <scheduler+0x9c>
        proc[p->prev_proc].next_proc = -1;
    80002954:	036787b3          	mul	a5,a5,s6
    80002958:	97d6                	add	a5,a5,s5
    8000295a:	0777a023          	sw	s7,96(a5)
        printf("No tail");
    8000295e:	00007517          	auipc	a0,0x7
    80002962:	a5250513          	addi	a0,a0,-1454 # 800093b0 <digits+0x370>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	c22080e7          	jalr	-990(ra) # 80000588 <printf>
      acquire(&p->lock);
    8000296e:	856a                	mv	a0,s10
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	274080e7          	jalr	628(ra) # 80000be4 <acquire>
      p->prev_proc = -1;
    80002978:	036484b3          	mul	s1,s1,s6
    8000297c:	94d6                	add	s1,s1,s5
    8000297e:	0774a223          	sw	s7,100(s1)
      p->next_proc = -1;
    80002982:	0774a023          	sw	s7,96(s1)
      p->state = RUNNING;
    80002986:	4791                	li	a5,4
    80002988:	cc9c                	sw	a5,24(s1)
      p->cpu_num = c->cpu_id;
    8000298a:	08892783          	lw	a5,136(s2)
    8000298e:	ccbc                	sw	a5,88(s1)
      c->proc = p;
    80002990:	01a93023          	sd	s10,0(s2)
      swtch(&c->context, &p->context);
    80002994:	090d8593          	addi	a1,s11,144
    80002998:	95d6                	add	a1,a1,s5
    8000299a:	8562                	mv	a0,s8
    8000299c:	00001097          	auipc	ra,0x1
    800029a0:	27c080e7          	jalr	636(ra) # 80003c18 <swtch>
      c->proc = 0;
    800029a4:	00093023          	sd	zero,0(s2)
      release(&p->lock);
    800029a8:	856a                	mv	a0,s10
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	2ee080e7          	jalr	750(ra) # 80000c98 <release>
      printf("end sched\n");
    800029b2:	00007517          	auipc	a0,0x7
    800029b6:	a0650513          	addi	a0,a0,-1530 # 800093b8 <digits+0x378>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	bce080e7          	jalr	-1074(ra) # 80000588 <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ca:	10079073          	csrw	sstatus,a5
    printf("start sched\n");
    800029ce:	8552                	mv	a0,s4
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	bb8080e7          	jalr	-1096(ra) # 80000588 <printf>
    if (c->runnable_list_head != -1)
    800029d8:	08092483          	lw	s1,128(s2)
    800029dc:	ff3483e3          	beq	s1,s3,800029c2 <scheduler+0x12c>
      p = &proc[c->runnable_list_head];
    800029e0:	03648db3          	mul	s11,s1,s6
    800029e4:	015d8d33          	add	s10,s11,s5
      printf("proc ind: %d\n", c->runnable_list_head);
    800029e8:	85a6                	mv	a1,s1
    800029ea:	8566                	mv	a0,s9
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b9c080e7          	jalr	-1124(ra) # 80000588 <printf>
      printf("runnable3");
    800029f4:	00007517          	auipc	a0,0x7
    800029f8:	98c50513          	addi	a0,a0,-1652 # 80009380 <digits+0x340>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b8c080e7          	jalr	-1140(ra) # 80000588 <printf>
      int res = remove_proc_from_list(p->proc_ind); 
    80002a04:	05cd2503          	lw	a0,92(s10) # ffffffff8000005c <end+0xfffffffefffd805c>
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	ebc080e7          	jalr	-324(ra) # 800018c4 <remove_proc_from_list>
      if (res == 1)
    80002a10:	4785                	li	a5,1
    80002a12:	eef507e3          	beq	a0,a5,80002900 <scheduler+0x6a>
      if (res == 2)
    80002a16:	4789                	li	a5,2
    80002a18:	f0f501e3          	beq	a0,a5,8000291a <scheduler+0x84>
      if (res == 3){
    80002a1c:	478d                	li	a5,3
    80002a1e:	f4f518e3          	bne	a0,a5,8000296e <scheduler+0xd8>
        c->runnable_list_tail = p->prev_proc;
    80002a22:	036487b3          	mul	a5,s1,s6
    80002a26:	97d6                	add	a5,a5,s5
    80002a28:	53fc                	lw	a5,100(a5)
    80002a2a:	08f92223          	sw	a5,132(s2)
        if (proc[p->prev_proc].prev_proc == -1)
    80002a2e:	03678733          	mul	a4,a5,s6
    80002a32:	9756                	add	a4,a4,s5
    80002a34:	5378                	lw	a4,100(a4)
    80002a36:	f1371fe3          	bne	a4,s3,80002954 <scheduler+0xbe>
          c->runnable_list_head = p->prev_proc;
    80002a3a:	08f92023          	sw	a5,128(s2)
    80002a3e:	bf19                	j	80002954 <scheduler+0xbe>

0000000080002a40 <sched>:
{
    80002a40:	7179                	addi	sp,sp,-48
    80002a42:	f406                	sd	ra,40(sp)
    80002a44:	f022                	sd	s0,32(sp)
    80002a46:	ec26                	sd	s1,24(sp)
    80002a48:	e84a                	sd	s2,16(sp)
    80002a4a:	e44e                	sd	s3,8(sp)
    80002a4c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	146080e7          	jalr	326(ra) # 80001b94 <myproc>
    80002a56:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	112080e7          	jalr	274(ra) # 80000b6a <holding>
    80002a60:	c55d                	beqz	a0,80002b0e <sched+0xce>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a62:	8792                	mv	a5,tp
  int id = r_tp();
    80002a64:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002a68:	00010617          	auipc	a2,0x10
    80002a6c:	85860613          	addi	a2,a2,-1960 # 800122c0 <cpus>
    80002a70:	00371793          	slli	a5,a4,0x3
    80002a74:	00e786b3          	add	a3,a5,a4
    80002a78:	0692                	slli	a3,a3,0x4
    80002a7a:	96b2                	add	a3,a3,a2
    80002a7c:	08e6a423          	sw	a4,136(a3)
  if(mycpu()->noff != 1)
    80002a80:	5eb8                	lw	a4,120(a3)
    80002a82:	4785                	li	a5,1
    80002a84:	08f71d63          	bne	a4,a5,80002b1e <sched+0xde>
  if(p->state == RUNNING)
    80002a88:	01892703          	lw	a4,24(s2)
    80002a8c:	4791                	li	a5,4
    80002a8e:	0af70063          	beq	a4,a5,80002b2e <sched+0xee>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a96:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002a98:	e3dd                	bnez	a5,80002b3e <sched+0xfe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a9a:	8792                	mv	a5,tp
  int id = r_tp();
    80002a9c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002aa0:	00010497          	auipc	s1,0x10
    80002aa4:	82048493          	addi	s1,s1,-2016 # 800122c0 <cpus>
    80002aa8:	00371793          	slli	a5,a4,0x3
    80002aac:	00e786b3          	add	a3,a5,a4
    80002ab0:	0692                	slli	a3,a3,0x4
    80002ab2:	96a6                	add	a3,a3,s1
    80002ab4:	08e6a423          	sw	a4,136(a3)
  intena = mycpu()->intena;
    80002ab8:	07c6a983          	lw	s3,124(a3)
    80002abc:	8592                	mv	a1,tp
  int id = r_tp();
    80002abe:	0005879b          	sext.w	a5,a1
  c->cpu_id = id;
    80002ac2:	00379593          	slli	a1,a5,0x3
    80002ac6:	00f58733          	add	a4,a1,a5
    80002aca:	0712                	slli	a4,a4,0x4
    80002acc:	9726                	add	a4,a4,s1
    80002ace:	08f72423          	sw	a5,136(a4)
  swtch(&p->context, &mycpu()->context);
    80002ad2:	95be                	add	a1,a1,a5
    80002ad4:	0592                	slli	a1,a1,0x4
    80002ad6:	05a1                	addi	a1,a1,8
    80002ad8:	95a6                	add	a1,a1,s1
    80002ada:	09090513          	addi	a0,s2,144
    80002ade:	00001097          	auipc	ra,0x1
    80002ae2:	13a080e7          	jalr	314(ra) # 80003c18 <swtch>
    80002ae6:	8792                	mv	a5,tp
  int id = r_tp();
    80002ae8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002aec:	00371793          	slli	a5,a4,0x3
    80002af0:	00e786b3          	add	a3,a5,a4
    80002af4:	0692                	slli	a3,a3,0x4
    80002af6:	96a6                	add	a3,a3,s1
    80002af8:	08e6a423          	sw	a4,136(a3)
  mycpu()->intena = intena;
    80002afc:	0736ae23          	sw	s3,124(a3)
}
    80002b00:	70a2                	ld	ra,40(sp)
    80002b02:	7402                	ld	s0,32(sp)
    80002b04:	64e2                	ld	s1,24(sp)
    80002b06:	6942                	ld	s2,16(sp)
    80002b08:	69a2                	ld	s3,8(sp)
    80002b0a:	6145                	addi	sp,sp,48
    80002b0c:	8082                	ret
    panic("sched p->lock");
    80002b0e:	00007517          	auipc	a0,0x7
    80002b12:	8ba50513          	addi	a0,a0,-1862 # 800093c8 <digits+0x388>
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	a28080e7          	jalr	-1496(ra) # 8000053e <panic>
    panic("sched locks");
    80002b1e:	00007517          	auipc	a0,0x7
    80002b22:	8ba50513          	addi	a0,a0,-1862 # 800093d8 <digits+0x398>
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	a18080e7          	jalr	-1512(ra) # 8000053e <panic>
    panic("sched running");
    80002b2e:	00007517          	auipc	a0,0x7
    80002b32:	8ba50513          	addi	a0,a0,-1862 # 800093e8 <digits+0x3a8>
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	a08080e7          	jalr	-1528(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002b3e:	00007517          	auipc	a0,0x7
    80002b42:	8ba50513          	addi	a0,a0,-1862 # 800093f8 <digits+0x3b8>
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	9f8080e7          	jalr	-1544(ra) # 8000053e <panic>

0000000080002b4e <yield>:
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	e426                	sd	s1,8(sp)
    80002b56:	e04a                	sd	s2,0(sp)
    80002b58:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	03a080e7          	jalr	58(ra) # 80001b94 <myproc>
    80002b62:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	080080e7          	jalr	128(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002b6c:	478d                	li	a5,3
    80002b6e:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002b70:	00007797          	auipc	a5,0x7
    80002b74:	4e47a783          	lw	a5,1252(a5) # 8000a054 <ticks>
    80002b78:	dcdc                	sw	a5,60(s1)
    80002b7a:	8792                	mv	a5,tp
  int id = r_tp();
    80002b7c:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002b80:	0000f617          	auipc	a2,0xf
    80002b84:	74060613          	addi	a2,a2,1856 # 800122c0 <cpus>
    80002b88:	00371793          	slli	a5,a4,0x3
    80002b8c:	00e786b3          	add	a3,a5,a4
    80002b90:	0692                	slli	a3,a3,0x4
    80002b92:	96b2                	add	a3,a3,a2
    80002b94:	08e6a423          	sw	a4,136(a3)
   if (mycpu()->runnable_list_head == -1)
    80002b98:	0806a703          	lw	a4,128(a3)
    80002b9c:	57fd                	li	a5,-1
    80002b9e:	08f70063          	beq	a4,a5,80002c1e <yield+0xd0>
    printf("runnable8");
    80002ba2:	00007517          	auipc	a0,0x7
    80002ba6:	89650513          	addi	a0,a0,-1898 # 80009438 <digits+0x3f8>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	9de080e7          	jalr	-1570(ra) # 80000588 <printf>
    80002bb2:	8792                	mv	a5,tp
  int id = r_tp();
    80002bb4:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002bb8:	0000f917          	auipc	s2,0xf
    80002bbc:	70890913          	addi	s2,s2,1800 # 800122c0 <cpus>
    80002bc0:	00371793          	slli	a5,a4,0x3
    80002bc4:	00e786b3          	add	a3,a5,a4
    80002bc8:	0692                	slli	a3,a3,0x4
    80002bca:	96ca                	add	a3,a3,s2
    80002bcc:	08e6a423          	sw	a4,136(a3)
    add_proc_to_list(mycpu()->runnable_list_tail, p);
    80002bd0:	85a6                	mv	a1,s1
    80002bd2:	0846a503          	lw	a0,132(a3)
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	c70080e7          	jalr	-912(ra) # 80001846 <add_proc_to_list>
    80002bde:	8792                	mv	a5,tp
  int id = r_tp();
    80002be0:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002be4:	00371793          	slli	a5,a4,0x3
    80002be8:	00e786b3          	add	a3,a5,a4
    80002bec:	0692                	slli	a3,a3,0x4
    80002bee:	96ca                	add	a3,a3,s2
    80002bf0:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002bf4:	4cf4                	lw	a3,92(s1)
    80002bf6:	97ba                	add	a5,a5,a4
    80002bf8:	0792                	slli	a5,a5,0x4
    80002bfa:	993e                	add	s2,s2,a5
    80002bfc:	08d92223          	sw	a3,132(s2)
  sched();
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	e40080e7          	jalr	-448(ra) # 80002a40 <sched>
  release(&p->lock);
    80002c08:	8526                	mv	a0,s1
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	08e080e7          	jalr	142(ra) # 80000c98 <release>
}
    80002c12:	60e2                	ld	ra,24(sp)
    80002c14:	6442                	ld	s0,16(sp)
    80002c16:	64a2                	ld	s1,8(sp)
    80002c18:	6902                	ld	s2,0(sp)
    80002c1a:	6105                	addi	sp,sp,32
    80002c1c:	8082                	ret
     printf("init runnable : %d                   8\n", p->proc_ind);
    80002c1e:	4cec                	lw	a1,92(s1)
    80002c20:	00006517          	auipc	a0,0x6
    80002c24:	7f050513          	addi	a0,a0,2032 # 80009410 <digits+0x3d0>
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	960080e7          	jalr	-1696(ra) # 80000588 <printf>
    80002c30:	8792                	mv	a5,tp
  int id = r_tp();
    80002c32:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002c36:	0000f717          	auipc	a4,0xf
    80002c3a:	68a70713          	addi	a4,a4,1674 # 800122c0 <cpus>
    80002c3e:	00369793          	slli	a5,a3,0x3
    80002c42:	00d78633          	add	a2,a5,a3
    80002c46:	0612                	slli	a2,a2,0x4
    80002c48:	963a                	add	a2,a2,a4
    80002c4a:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = p->proc_ind;
    80002c4e:	4cf0                	lw	a2,92(s1)
    80002c50:	97b6                	add	a5,a5,a3
    80002c52:	0792                	slli	a5,a5,0x4
    80002c54:	97ba                	add	a5,a5,a4
    80002c56:	08c7a023          	sw	a2,128(a5)
    80002c5a:	8792                	mv	a5,tp
  int id = r_tp();
    80002c5c:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002c60:	00369793          	slli	a5,a3,0x3
    80002c64:	00d78633          	add	a2,a5,a3
    80002c68:	0612                	slli	a2,a2,0x4
    80002c6a:	963a                	add	a2,a2,a4
    80002c6c:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = p->proc_ind;
    80002c70:	4cf0                	lw	a2,92(s1)
    80002c72:	97b6                	add	a5,a5,a3
    80002c74:	0792                	slli	a5,a5,0x4
    80002c76:	973e                	add	a4,a4,a5
    80002c78:	08c72223          	sw	a2,132(a4)
    80002c7c:	b751                	j	80002c00 <yield+0xb2>

0000000080002c7e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002c7e:	7179                	addi	sp,sp,-48
    80002c80:	f406                	sd	ra,40(sp)
    80002c82:	f022                	sd	s0,32(sp)
    80002c84:	ec26                	sd	s1,24(sp)
    80002c86:	e84a                	sd	s2,16(sp)
    80002c88:	e44e                	sd	s3,8(sp)
    80002c8a:	1800                	addi	s0,sp,48
    80002c8c:	89aa                	mv	s3,a0
    80002c8e:	892e                	mv	s2,a1
  // TODO: remove from RUNNABLE and add to SLEEPING
  struct proc *p = myproc();
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	f04080e7          	jalr	-252(ra) # 80001b94 <myproc>
    80002c98:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	f4a080e7          	jalr	-182(ra) # 80000be4 <acquire>
  release(lk);
    80002ca2:	854a                	mv	a0,s2
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	ff4080e7          	jalr	-12(ra) # 80000c98 <release>

  //Ass2
  printf("runnable ");
    80002cac:	00006517          	auipc	a0,0x6
    80002cb0:	79c50513          	addi	a0,a0,1948 # 80009448 <digits+0x408>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	8d4080e7          	jalr	-1836(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    80002cbc:	4ce8                	lw	a0,92(s1)
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	c06080e7          	jalr	-1018(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1)
    80002cc6:	4785                	li	a5,1
    80002cc8:	08f50f63          	beq	a0,a5,80002d66 <sleep+0xe8>
  {
    mycpu()->runnable_list_head = -1;
    mycpu()->runnable_list_tail = -1;
    printf("4 no head & tail");
  }
  if (res == 2)
    80002ccc:	4789                	li	a5,2
    80002cce:	0ef50463          	beq	a0,a5,80002db6 <sleep+0x138>
    if (proc[p->next_proc].next_proc == -1)
      mycpu()->runnable_list_tail = p->next_proc;
    proc[p->next_proc].prev_proc = -1;
    printf("4 no head ");
  }
  if (res == 3){
    80002cd2:	478d                	li	a5,3
    80002cd4:	16f50a63          	beq	a0,a5,80002e48 <sleep+0x1ca>
      mycpu()->runnable_list_head = p->prev_proc;
    proc[p->prev_proc].next_proc = -1;
    printf("4 no tail");
  }

  p->next_proc = -1;
    80002cd8:	57fd                	li	a5,-1
    80002cda:	d0bc                	sw	a5,96(s1)
  p->prev_proc = -1;
    80002cdc:	d0fc                	sw	a5,100(s1)

  // Go to sleep.
  p->chan = chan;
    80002cde:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002ce2:	4789                	li	a5,2
    80002ce4:	cc9c                	sw	a5,24(s1)
  p->start_sleeping_time = ticks;
    80002ce6:	00007797          	auipc	a5,0x7
    80002cea:	36e7a783          	lw	a5,878(a5) # 8000a054 <ticks>
    80002cee:	c8fc                	sw	a5,84(s1)

  if (sleeping_list_tail != -1){
    80002cf0:	00007717          	auipc	a4,0x7
    80002cf4:	f4872703          	lw	a4,-184(a4) # 80009c38 <sleeping_list_tail>
    80002cf8:	57fd                	li	a5,-1
    80002cfa:	1ef70663          	beq	a4,a5,80002ee6 <sleep+0x268>
    printf("sleeping");
    80002cfe:	00006517          	auipc	a0,0x6
    80002d02:	79250513          	addi	a0,a0,1938 # 80009490 <digits+0x450>
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	882080e7          	jalr	-1918(ra) # 80000588 <printf>
    add_proc_to_list(sleeping_list_tail, p);
    80002d0e:	85a6                	mv	a1,s1
    80002d10:	00007517          	auipc	a0,0x7
    80002d14:	f2852503          	lw	a0,-216(a0) # 80009c38 <sleeping_list_tail>
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	b2e080e7          	jalr	-1234(ra) # 80001846 <add_proc_to_list>
    if (sleeping_list_head == -1)
    80002d20:	00007717          	auipc	a4,0x7
    80002d24:	f1c72703          	lw	a4,-228(a4) # 80009c3c <sleeping_list_head>
    80002d28:	57fd                	li	a5,-1
    80002d2a:	1af70863          	beq	a4,a5,80002eda <sleep+0x25c>
      {
        sleeping_list_head = p->proc_ind;
      }
    sleeping_list_tail = p->proc_ind;
    80002d2e:	4cfc                	lw	a5,92(s1)
    80002d30:	00007717          	auipc	a4,0x7
    80002d34:	f0f72423          	sw	a5,-248(a4) # 80009c38 <sleeping_list_tail>
    printf("head in sleeping\n");
    sleeping_list_tail =  p->proc_ind;
    sleeping_list_head = p->proc_ind;
  }

  sched();
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	d08080e7          	jalr	-760(ra) # 80002a40 <sched>

  // Tidy up.
  p->chan = 0;
    80002d40:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002d44:	8526                	mv	a0,s1
    80002d46:	ffffe097          	auipc	ra,0xffffe
    80002d4a:	f52080e7          	jalr	-174(ra) # 80000c98 <release>
  acquire(lk);
    80002d4e:	854a                	mv	a0,s2
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	e94080e7          	jalr	-364(ra) # 80000be4 <acquire>
}
    80002d58:	70a2                	ld	ra,40(sp)
    80002d5a:	7402                	ld	s0,32(sp)
    80002d5c:	64e2                	ld	s1,24(sp)
    80002d5e:	6942                	ld	s2,16(sp)
    80002d60:	69a2                	ld	s3,8(sp)
    80002d62:	6145                	addi	sp,sp,48
    80002d64:	8082                	ret
    80002d66:	8792                	mv	a5,tp
  int id = r_tp();
    80002d68:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002d6c:	0000f717          	auipc	a4,0xf
    80002d70:	55470713          	addi	a4,a4,1364 # 800122c0 <cpus>
    80002d74:	00369793          	slli	a5,a3,0x3
    80002d78:	00d78633          	add	a2,a5,a3
    80002d7c:	0612                	slli	a2,a2,0x4
    80002d7e:	963a                	add	a2,a2,a4
    80002d80:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_head = -1;
    80002d84:	55fd                	li	a1,-1
    80002d86:	08b62023          	sw	a1,128(a2)
    80002d8a:	8792                	mv	a5,tp
  int id = r_tp();
    80002d8c:	0007869b          	sext.w	a3,a5
  c->cpu_id = id;
    80002d90:	00369793          	slli	a5,a3,0x3
    80002d94:	00d78633          	add	a2,a5,a3
    80002d98:	0612                	slli	a2,a2,0x4
    80002d9a:	963a                	add	a2,a2,a4
    80002d9c:	08d62423          	sw	a3,136(a2)
    mycpu()->runnable_list_tail = -1;
    80002da0:	08b62223          	sw	a1,132(a2)
    printf("4 no head & tail");
    80002da4:	00006517          	auipc	a0,0x6
    80002da8:	6b450513          	addi	a0,a0,1716 # 80009458 <digits+0x418>
    80002dac:	ffffd097          	auipc	ra,0xffffd
    80002db0:	7dc080e7          	jalr	2012(ra) # 80000588 <printf>
  if (res == 3){
    80002db4:	b715                	j	80002cd8 <sleep+0x5a>
    80002db6:	8792                	mv	a5,tp
  int id = r_tp();
    80002db8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002dbc:	0000f617          	auipc	a2,0xf
    80002dc0:	50460613          	addi	a2,a2,1284 # 800122c0 <cpus>
    80002dc4:	00371793          	slli	a5,a4,0x3
    80002dc8:	00e786b3          	add	a3,a5,a4
    80002dcc:	0692                	slli	a3,a3,0x4
    80002dce:	96b2                	add	a3,a3,a2
    80002dd0:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_head = p->next_proc;
    80002dd4:	50b4                	lw	a3,96(s1)
    80002dd6:	97ba                	add	a5,a5,a4
    80002dd8:	0792                	slli	a5,a5,0x4
    80002dda:	97b2                	add	a5,a5,a2
    80002ddc:	08d7a023          	sw	a3,128(a5)
    if (proc[p->next_proc].next_proc == -1)
    80002de0:	19800793          	li	a5,408
    80002de4:	02f686b3          	mul	a3,a3,a5
    80002de8:	00010797          	auipc	a5,0x10
    80002dec:	98878793          	addi	a5,a5,-1656 # 80012770 <proc>
    80002df0:	96be                	add	a3,a3,a5
    80002df2:	52b8                	lw	a4,96(a3)
    80002df4:	57fd                	li	a5,-1
    80002df6:	02f70763          	beq	a4,a5,80002e24 <sleep+0x1a6>
    proc[p->next_proc].prev_proc = -1;
    80002dfa:	50bc                	lw	a5,96(s1)
    80002dfc:	19800713          	li	a4,408
    80002e00:	02e78733          	mul	a4,a5,a4
    80002e04:	00010797          	auipc	a5,0x10
    80002e08:	96c78793          	addi	a5,a5,-1684 # 80012770 <proc>
    80002e0c:	97ba                	add	a5,a5,a4
    80002e0e:	577d                	li	a4,-1
    80002e10:	d3f8                	sw	a4,100(a5)
    printf("4 no head ");
    80002e12:	00006517          	auipc	a0,0x6
    80002e16:	65e50513          	addi	a0,a0,1630 # 80009470 <digits+0x430>
    80002e1a:	ffffd097          	auipc	ra,0xffffd
    80002e1e:	76e080e7          	jalr	1902(ra) # 80000588 <printf>
  if (res == 3){
    80002e22:	bd5d                	j	80002cd8 <sleep+0x5a>
    80002e24:	8792                	mv	a5,tp
  int id = r_tp();
    80002e26:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002e2a:	00371793          	slli	a5,a4,0x3
    80002e2e:	00e786b3          	add	a3,a5,a4
    80002e32:	0692                	slli	a3,a3,0x4
    80002e34:	96b2                	add	a3,a3,a2
    80002e36:	08e6a423          	sw	a4,136(a3)
      mycpu()->runnable_list_tail = p->next_proc;
    80002e3a:	50b4                	lw	a3,96(s1)
    80002e3c:	97ba                	add	a5,a5,a4
    80002e3e:	0792                	slli	a5,a5,0x4
    80002e40:	97b2                	add	a5,a5,a2
    80002e42:	08d7a223          	sw	a3,132(a5)
    80002e46:	bf55                	j	80002dfa <sleep+0x17c>
    80002e48:	8792                	mv	a5,tp
  int id = r_tp();
    80002e4a:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002e4e:	0000f617          	auipc	a2,0xf
    80002e52:	47260613          	addi	a2,a2,1138 # 800122c0 <cpus>
    80002e56:	00371793          	slli	a5,a4,0x3
    80002e5a:	00e786b3          	add	a3,a5,a4
    80002e5e:	0692                	slli	a3,a3,0x4
    80002e60:	96b2                	add	a3,a3,a2
    80002e62:	08e6a423          	sw	a4,136(a3)
    mycpu()->runnable_list_tail = p->prev_proc;
    80002e66:	50f4                	lw	a3,100(s1)
    80002e68:	97ba                	add	a5,a5,a4
    80002e6a:	0792                	slli	a5,a5,0x4
    80002e6c:	97b2                	add	a5,a5,a2
    80002e6e:	08d7a223          	sw	a3,132(a5)
    if (proc[p->prev_proc].prev_proc == -1)
    80002e72:	19800793          	li	a5,408
    80002e76:	02f686b3          	mul	a3,a3,a5
    80002e7a:	00010797          	auipc	a5,0x10
    80002e7e:	8f678793          	addi	a5,a5,-1802 # 80012770 <proc>
    80002e82:	96be                	add	a3,a3,a5
    80002e84:	52f8                	lw	a4,100(a3)
    80002e86:	57fd                	li	a5,-1
    80002e88:	02f70763          	beq	a4,a5,80002eb6 <sleep+0x238>
    proc[p->prev_proc].next_proc = -1;
    80002e8c:	50fc                	lw	a5,100(s1)
    80002e8e:	19800713          	li	a4,408
    80002e92:	02e78733          	mul	a4,a5,a4
    80002e96:	00010797          	auipc	a5,0x10
    80002e9a:	8da78793          	addi	a5,a5,-1830 # 80012770 <proc>
    80002e9e:	97ba                	add	a5,a5,a4
    80002ea0:	577d                	li	a4,-1
    80002ea2:	d3b8                	sw	a4,96(a5)
    printf("4 no tail");
    80002ea4:	00006517          	auipc	a0,0x6
    80002ea8:	5dc50513          	addi	a0,a0,1500 # 80009480 <digits+0x440>
    80002eac:	ffffd097          	auipc	ra,0xffffd
    80002eb0:	6dc080e7          	jalr	1756(ra) # 80000588 <printf>
    80002eb4:	b515                	j	80002cd8 <sleep+0x5a>
    80002eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80002eb8:	0007871b          	sext.w	a4,a5
  c->cpu_id = id;
    80002ebc:	00371793          	slli	a5,a4,0x3
    80002ec0:	00e786b3          	add	a3,a5,a4
    80002ec4:	0692                	slli	a3,a3,0x4
    80002ec6:	96b2                	add	a3,a3,a2
    80002ec8:	08e6a423          	sw	a4,136(a3)
      mycpu()->runnable_list_head = p->prev_proc;
    80002ecc:	50f4                	lw	a3,100(s1)
    80002ece:	97ba                	add	a5,a5,a4
    80002ed0:	0792                	slli	a5,a5,0x4
    80002ed2:	97b2                	add	a5,a5,a2
    80002ed4:	08d7a023          	sw	a3,128(a5)
    80002ed8:	bf55                	j	80002e8c <sleep+0x20e>
        sleeping_list_head = p->proc_ind;
    80002eda:	4cfc                	lw	a5,92(s1)
    80002edc:	00007717          	auipc	a4,0x7
    80002ee0:	d6f72023          	sw	a5,-672(a4) # 80009c3c <sleeping_list_head>
    80002ee4:	b5a9                	j	80002d2e <sleep+0xb0>
    printf("head in sleeping\n");
    80002ee6:	00006517          	auipc	a0,0x6
    80002eea:	5ba50513          	addi	a0,a0,1466 # 800094a0 <digits+0x460>
    80002eee:	ffffd097          	auipc	ra,0xffffd
    80002ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    sleeping_list_tail =  p->proc_ind;
    80002ef6:	4cfc                	lw	a5,92(s1)
    80002ef8:	00007717          	auipc	a4,0x7
    80002efc:	d4f72023          	sw	a5,-704(a4) # 80009c38 <sleeping_list_tail>
    sleeping_list_head = p->proc_ind;
    80002f00:	00007717          	auipc	a4,0x7
    80002f04:	d2f72e23          	sw	a5,-708(a4) # 80009c3c <sleeping_list_head>
    80002f08:	bd05                	j	80002d38 <sleep+0xba>

0000000080002f0a <wait>:
{
    80002f0a:	711d                	addi	sp,sp,-96
    80002f0c:	ec86                	sd	ra,88(sp)
    80002f0e:	e8a2                	sd	s0,80(sp)
    80002f10:	e4a6                	sd	s1,72(sp)
    80002f12:	e0ca                	sd	s2,64(sp)
    80002f14:	fc4e                	sd	s3,56(sp)
    80002f16:	f852                	sd	s4,48(sp)
    80002f18:	f456                	sd	s5,40(sp)
    80002f1a:	f05a                	sd	s6,32(sp)
    80002f1c:	ec5e                	sd	s7,24(sp)
    80002f1e:	e862                	sd	s8,16(sp)
    80002f20:	e466                	sd	s9,8(sp)
    80002f22:	1080                	addi	s0,sp,96
    80002f24:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	c6e080e7          	jalr	-914(ra) # 80001b94 <myproc>
    80002f2e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002f30:	00010517          	auipc	a0,0x10
    80002f34:	82850513          	addi	a0,a0,-2008 # 80012758 <wait_lock>
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	cac080e7          	jalr	-852(ra) # 80000be4 <acquire>
    havekids = 0;
    80002f40:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002f42:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002f44:	00016997          	auipc	s3,0x16
    80002f48:	e2c98993          	addi	s3,s3,-468 # 80018d70 <tickslock>
        havekids = 1;
    80002f4c:	4a85                	li	s5,1
      p->sleeping_time += ticks - p->start_sleeping_time;
    80002f4e:	00007c97          	auipc	s9,0x7
    80002f52:	106c8c93          	addi	s9,s9,262 # 8000a054 <ticks>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002f56:	00010c17          	auipc	s8,0x10
    80002f5a:	802c0c13          	addi	s8,s8,-2046 # 80012758 <wait_lock>
    havekids = 0;
    80002f5e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002f60:	00010497          	auipc	s1,0x10
    80002f64:	81048493          	addi	s1,s1,-2032 # 80012770 <proc>
    80002f68:	a0bd                	j	80002fd6 <wait+0xcc>
          pid = np->pid;
    80002f6a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002f6e:	000b0e63          	beqz	s6,80002f8a <wait+0x80>
    80002f72:	4691                	li	a3,4
    80002f74:	02c48613          	addi	a2,s1,44
    80002f78:	85da                	mv	a1,s6
    80002f7a:	08093503          	ld	a0,128(s2)
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	6fc080e7          	jalr	1788(ra) # 8000167a <copyout>
    80002f86:	02054563          	bltz	a0,80002fb0 <wait+0xa6>
          freeproc(np);
    80002f8a:	8526                	mv	a0,s1
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	dbe080e7          	jalr	-578(ra) # 80001d4a <freeproc>
          release(&np->lock);
    80002f94:	8526                	mv	a0,s1
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	d02080e7          	jalr	-766(ra) # 80000c98 <release>
          release(&wait_lock);
    80002f9e:	0000f517          	auipc	a0,0xf
    80002fa2:	7ba50513          	addi	a0,a0,1978 # 80012758 <wait_lock>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	cf2080e7          	jalr	-782(ra) # 80000c98 <release>
          return pid;
    80002fae:	a09d                	j	80003014 <wait+0x10a>
            release(&np->lock);
    80002fb0:	8526                	mv	a0,s1
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
            release(&wait_lock);
    80002fba:	0000f517          	auipc	a0,0xf
    80002fbe:	79e50513          	addi	a0,a0,1950 # 80012758 <wait_lock>
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	cd6080e7          	jalr	-810(ra) # 80000c98 <release>
            return -1;
    80002fca:	59fd                	li	s3,-1
    80002fcc:	a0a1                	j	80003014 <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002fce:	19848493          	addi	s1,s1,408
    80002fd2:	03348463          	beq	s1,s3,80002ffa <wait+0xf0>
      if(np->parent == p){
    80002fd6:	74bc                	ld	a5,104(s1)
    80002fd8:	ff279be3          	bne	a5,s2,80002fce <wait+0xc4>
        acquire(&np->lock);
    80002fdc:	8526                	mv	a0,s1
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	c06080e7          	jalr	-1018(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002fe6:	4c9c                	lw	a5,24(s1)
    80002fe8:	f94781e3          	beq	a5,s4,80002f6a <wait+0x60>
        release(&np->lock);
    80002fec:	8526                	mv	a0,s1
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	caa080e7          	jalr	-854(ra) # 80000c98 <release>
        havekids = 1;
    80002ff6:	8756                	mv	a4,s5
    80002ff8:	bfd9                	j	80002fce <wait+0xc4>
    if(!havekids || p->killed){
    80002ffa:	c701                	beqz	a4,80003002 <wait+0xf8>
    80002ffc:	02892783          	lw	a5,40(s2)
    80003000:	cb85                	beqz	a5,80003030 <wait+0x126>
      release(&wait_lock);
    80003002:	0000f517          	auipc	a0,0xf
    80003006:	75650513          	addi	a0,a0,1878 # 80012758 <wait_lock>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	c8e080e7          	jalr	-882(ra) # 80000c98 <release>
      return -1;
    80003012:	59fd                	li	s3,-1
}
    80003014:	854e                	mv	a0,s3
    80003016:	60e6                	ld	ra,88(sp)
    80003018:	6446                	ld	s0,80(sp)
    8000301a:	64a6                	ld	s1,72(sp)
    8000301c:	6906                	ld	s2,64(sp)
    8000301e:	79e2                	ld	s3,56(sp)
    80003020:	7a42                	ld	s4,48(sp)
    80003022:	7aa2                	ld	s5,40(sp)
    80003024:	7b02                	ld	s6,32(sp)
    80003026:	6be2                	ld	s7,24(sp)
    80003028:	6c42                	ld	s8,16(sp)
    8000302a:	6ca2                	ld	s9,8(sp)
    8000302c:	6125                	addi	sp,sp,96
    8000302e:	8082                	ret
    if (p->state == RUNNING)
    80003030:	01892783          	lw	a5,24(s2)
    80003034:	4711                	li	a4,4
    80003036:	02e78063          	beq	a5,a4,80003056 <wait+0x14c>
     if (p->state == RUNNABLE)
    8000303a:	470d                	li	a4,3
    8000303c:	02e79e63          	bne	a5,a4,80003078 <wait+0x16e>
      p->runnable_time += ticks - p->last_runnable_time;
    80003040:	04892783          	lw	a5,72(s2)
    80003044:	000ca703          	lw	a4,0(s9)
    80003048:	9fb9                	addw	a5,a5,a4
    8000304a:	03c92703          	lw	a4,60(s2)
    8000304e:	9f99                	subw	a5,a5,a4
    80003050:	04f92423          	sw	a5,72(s2)
    if (p->state == SLEEPING)
    80003054:	a819                	j	8000306a <wait+0x160>
      p->running_time += ticks - p->start_running_time;
    80003056:	04492783          	lw	a5,68(s2)
    8000305a:	000ca703          	lw	a4,0(s9)
    8000305e:	9fb9                	addw	a5,a5,a4
    80003060:	05092703          	lw	a4,80(s2)
    80003064:	9f99                	subw	a5,a5,a4
    80003066:	04f92223          	sw	a5,68(s2)
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000306a:	85e2                	mv	a1,s8
    8000306c:	854a                	mv	a0,s2
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	c10080e7          	jalr	-1008(ra) # 80002c7e <sleep>
    havekids = 0;
    80003076:	b5e5                	j	80002f5e <wait+0x54>
    if (p->state == SLEEPING)
    80003078:	4709                	li	a4,2
    8000307a:	fee798e3          	bne	a5,a4,8000306a <wait+0x160>
      p->sleeping_time += ticks - p->start_sleeping_time;
    8000307e:	04c92783          	lw	a5,76(s2)
    80003082:	000ca703          	lw	a4,0(s9)
    80003086:	9fb9                	addw	a5,a5,a4
    80003088:	05492703          	lw	a4,84(s2)
    8000308c:	9f99                	subw	a5,a5,a4
    8000308e:	04f92623          	sw	a5,76(s2)
    80003092:	bfe1                	j	8000306a <wait+0x160>

0000000080003094 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80003094:	711d                	addi	sp,sp,-96
    80003096:	ec86                	sd	ra,88(sp)
    80003098:	e8a2                	sd	s0,80(sp)
    8000309a:	e4a6                	sd	s1,72(sp)
    8000309c:	e0ca                	sd	s2,64(sp)
    8000309e:	fc4e                	sd	s3,56(sp)
    800030a0:	f852                	sd	s4,48(sp)
    800030a2:	f456                	sd	s5,40(sp)
    800030a4:	f05a                	sd	s6,32(sp)
    800030a6:	ec5e                	sd	s7,24(sp)
    800030a8:	e862                	sd	s8,16(sp)
    800030aa:	e466                	sd	s9,8(sp)
    800030ac:	1080                	addi	s0,sp,96
    800030ae:	89aa                	mv	s3,a0
  // TODO: go threw all SLEEPING and pick one to wake up- remove from SLEEPING and add to RUNNABLE.
  struct proc *p;
  
  while (sleeping_list_head != -1)
    800030b0:	00007b97          	auipc	s7,0x7
    800030b4:	b8cb8b93          	addi	s7,s7,-1140 # 80009c3c <sleeping_list_head>
    800030b8:	597d                	li	s2,-1
  {
    p = &proc[sleeping_list_head];
    if (p->chan == chan)
    800030ba:	0000fa97          	auipc	s5,0xf
    800030be:	6b6a8a93          	addi	s5,s5,1718 # 80012770 <proc>
    800030c2:	19800a13          	li	s4,408
            sleeping_list_tail = p->next_proc;
          proc[p->next_proc].prev_proc = -1;
          printf("5 no head ");
        }
        if (res == 3){
          sleeping_list_tail = p->prev_proc;
    800030c6:	00007c17          	auipc	s8,0x7
    800030ca:	b72c0c13          	addi	s8,s8,-1166 # 80009c38 <sleeping_list_tail>
        p->prev_proc = -1;
        p->next_proc = -1;
        release(&p->lock);

        
        if (cpus[p->cpu_num].runnable_list_head == -1)
    800030ce:	0000fb17          	auipc	s6,0xf
    800030d2:	1f2b0b13          	addi	s6,s6,498 # 800122c0 <cpus>
  while (sleeping_list_head != -1)
    800030d6:	000ba483          	lw	s1,0(s7)
    if (p->chan == chan)
    800030da:	03448733          	mul	a4,s1,s4
    800030de:	9756                	add	a4,a4,s5
  while (sleeping_list_head != -1)
    800030e0:	19248863          	beq	s1,s2,80003270 <wakeup+0x1dc>
    if (p->chan == chan)
    800030e4:	731c                	ld	a5,32(a4)
    800030e6:	ff379de3          	bne	a5,s3,800030e0 <wakeup+0x4c>
      printf("wakeup\n"); 
    800030ea:	00006517          	auipc	a0,0x6
    800030ee:	3ce50513          	addi	a0,a0,974 # 800094b8 <digits+0x478>
    800030f2:	ffffd097          	auipc	ra,0xffffd
    800030f6:	496080e7          	jalr	1174(ra) # 80000588 <printf>
      printf("sleeping");
    800030fa:	00006517          	auipc	a0,0x6
    800030fe:	39650513          	addi	a0,a0,918 # 80009490 <digits+0x450>
    80003102:	ffffd097          	auipc	ra,0xffffd
    80003106:	486080e7          	jalr	1158(ra) # 80000588 <printf>
      int res = remove_proc_from_list(p->proc_ind); 
    8000310a:	034487b3          	mul	a5,s1,s4
    8000310e:	97d6                	add	a5,a5,s5
    80003110:	4fe8                	lw	a0,92(a5)
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	7b2080e7          	jalr	1970(ra) # 800018c4 <remove_proc_from_list>
        if (res == 1)
    8000311a:	4785                	li	a5,1
    8000311c:	04f50263          	beq	a0,a5,80003160 <wakeup+0xcc>
        if (res == 2)
    80003120:	4789                	li	a5,2
    80003122:	04f50d63          	beq	a0,a5,8000317c <wakeup+0xe8>
        if (res == 3){
    80003126:	478d                	li	a5,3
    80003128:	08f51363          	bne	a0,a5,800031ae <wakeup+0x11a>
          sleeping_list_tail = p->prev_proc;
    8000312c:	034487b3          	mul	a5,s1,s4
    80003130:	97d6                	add	a5,a5,s5
    80003132:	53fc                	lw	a5,100(a5)
    80003134:	00fc2023          	sw	a5,0(s8)
          if (proc[p->prev_proc].prev_proc == -1)
    80003138:	03478733          	mul	a4,a5,s4
    8000313c:	9756                	add	a4,a4,s5
    8000313e:	5378                	lw	a4,100(a4)
    80003140:	0f270c63          	beq	a4,s2,80003238 <wakeup+0x1a4>
          proc[p->prev_proc].next_proc = -1;
    80003144:	034787b3          	mul	a5,a5,s4
    80003148:	97d6                	add	a5,a5,s5
    8000314a:	577d                	li	a4,-1
    8000314c:	d3b8                	sw	a4,96(a5)
          printf("5 no tail");
    8000314e:	00006517          	auipc	a0,0x6
    80003152:	39a50513          	addi	a0,a0,922 # 800094e8 <digits+0x4a8>
    80003156:	ffffd097          	auipc	ra,0xffffd
    8000315a:	432080e7          	jalr	1074(ra) # 80000588 <printf>
    8000315e:	a881                	j	800031ae <wakeup+0x11a>
          sleeping_list_head = -1;
    80003160:	57fd                	li	a5,-1
    80003162:	00fba023          	sw	a5,0(s7)
          sleeping_list_tail = -1;
    80003166:	00fc2023          	sw	a5,0(s8)
          printf("5 no head & tail");
    8000316a:	00006517          	auipc	a0,0x6
    8000316e:	35650513          	addi	a0,a0,854 # 800094c0 <digits+0x480>
    80003172:	ffffd097          	auipc	ra,0xffffd
    80003176:	416080e7          	jalr	1046(ra) # 80000588 <printf>
        if (res == 3){
    8000317a:	a815                	j	800031ae <wakeup+0x11a>
          sleeping_list_head = p->next_proc;
    8000317c:	034487b3          	mul	a5,s1,s4
    80003180:	97d6                	add	a5,a5,s5
    80003182:	53bc                	lw	a5,96(a5)
    80003184:	00fba023          	sw	a5,0(s7)
          if (proc[p->next_proc].next_proc == -1)
    80003188:	03478733          	mul	a4,a5,s4
    8000318c:	9756                	add	a4,a4,s5
    8000318e:	5338                	lw	a4,96(a4)
    80003190:	0b270163          	beq	a4,s2,80003232 <wakeup+0x19e>
          proc[p->next_proc].prev_proc = -1;
    80003194:	034787b3          	mul	a5,a5,s4
    80003198:	97d6                	add	a5,a5,s5
    8000319a:	577d                	li	a4,-1
    8000319c:	d3f8                	sw	a4,100(a5)
          printf("5 no head ");
    8000319e:	00006517          	auipc	a0,0x6
    800031a2:	33a50513          	addi	a0,a0,826 # 800094d8 <digits+0x498>
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	3e2080e7          	jalr	994(ra) # 80000588 <printf>
    p = &proc[sleeping_list_head];
    800031ae:	03448cb3          	mul	s9,s1,s4
    800031b2:	9cd6                	add	s9,s9,s5
        acquire(&p->lock);
    800031b4:	8566                	mv	a0,s9
    800031b6:	ffffe097          	auipc	ra,0xffffe
    800031ba:	a2e080e7          	jalr	-1490(ra) # 80000be4 <acquire>
        p->state = RUNNABLE;
    800031be:	478d                	li	a5,3
    800031c0:	00fcac23          	sw	a5,24(s9)
        p->prev_proc = -1;
    800031c4:	57fd                	li	a5,-1
    800031c6:	06fca223          	sw	a5,100(s9)
        p->next_proc = -1;
    800031ca:	06fca023          	sw	a5,96(s9)
        release(&p->lock);
    800031ce:	8566                	mv	a0,s9
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	ac8080e7          	jalr	-1336(ra) # 80000c98 <release>
        if (cpus[p->cpu_num].runnable_list_head == -1)
    800031d8:	058ca703          	lw	a4,88(s9)
    800031dc:	00371793          	slli	a5,a4,0x3
    800031e0:	97ba                	add	a5,a5,a4
    800031e2:	0792                	slli	a5,a5,0x4
    800031e4:	97da                	add	a5,a5,s6
    800031e6:	0807a783          	lw	a5,128(a5)
    800031ea:	05278a63          	beq	a5,s2,8000323e <wakeup+0x1aa>
          cpus[p->cpu_num].runnable_list_head = p->proc_ind;
          cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
        }
        else
        {
          printf("runnable4");
    800031ee:	00006517          	auipc	a0,0x6
    800031f2:	33250513          	addi	a0,a0,818 # 80009520 <digits+0x4e0>
    800031f6:	ffffd097          	auipc	ra,0xffffd
    800031fa:	392080e7          	jalr	914(ra) # 80000588 <printf>
          add_proc_to_list(cpus[p->cpu_num].runnable_list_tail, p);
    800031fe:	034484b3          	mul	s1,s1,s4
    80003202:	94d6                	add	s1,s1,s5
    80003204:	4cb8                	lw	a4,88(s1)
    80003206:	00371793          	slli	a5,a4,0x3
    8000320a:	97ba                	add	a5,a5,a4
    8000320c:	0792                	slli	a5,a5,0x4
    8000320e:	97da                	add	a5,a5,s6
    80003210:	85e6                	mv	a1,s9
    80003212:	0847a503          	lw	a0,132(a5)
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	630080e7          	jalr	1584(ra) # 80001846 <add_proc_to_list>
          cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    8000321e:	4cb8                	lw	a4,88(s1)
    80003220:	00371793          	slli	a5,a4,0x3
    80003224:	97ba                	add	a5,a5,a4
    80003226:	0792                	slli	a5,a5,0x4
    80003228:	97da                	add	a5,a5,s6
    8000322a:	4cf8                	lw	a4,92(s1)
    8000322c:	08e7a223          	sw	a4,132(a5)
    80003230:	b55d                	j	800030d6 <wakeup+0x42>
            sleeping_list_tail = p->next_proc;
    80003232:	00fc2023          	sw	a5,0(s8)
    80003236:	bfb9                	j	80003194 <wakeup+0x100>
            sleeping_list_head = p->prev_proc;
    80003238:	00fba023          	sw	a5,0(s7)
    8000323c:	b721                	j	80003144 <wakeup+0xb0>
          printf("init runnable %d                  4\n", p->proc_ind);
    8000323e:	05cca583          	lw	a1,92(s9)
    80003242:	00006517          	auipc	a0,0x6
    80003246:	2b650513          	addi	a0,a0,694 # 800094f8 <digits+0x4b8>
    8000324a:	ffffd097          	auipc	ra,0xffffd
    8000324e:	33e080e7          	jalr	830(ra) # 80000588 <printf>
          cpus[p->cpu_num].runnable_list_head = p->proc_ind;
    80003252:	058ca683          	lw	a3,88(s9)
    80003256:	05cca603          	lw	a2,92(s9)
    8000325a:	00369793          	slli	a5,a3,0x3
    8000325e:	00d78733          	add	a4,a5,a3
    80003262:	0712                	slli	a4,a4,0x4
    80003264:	975a                	add	a4,a4,s6
    80003266:	08c72023          	sw	a2,128(a4)
          cpus[p->cpu_num].runnable_list_tail = p->proc_ind;
    8000326a:	08c72223          	sw	a2,132(a4)
    8000326e:	b5a5                	j	800030d6 <wakeup+0x42>
  //     }
  //     release(&p->lock);
  //   }
  // }
  }
}
    80003270:	60e6                	ld	ra,88(sp)
    80003272:	6446                	ld	s0,80(sp)
    80003274:	64a6                	ld	s1,72(sp)
    80003276:	6906                	ld	s2,64(sp)
    80003278:	79e2                	ld	s3,56(sp)
    8000327a:	7a42                	ld	s4,48(sp)
    8000327c:	7aa2                	ld	s5,40(sp)
    8000327e:	7b02                	ld	s6,32(sp)
    80003280:	6be2                	ld	s7,24(sp)
    80003282:	6c42                	ld	s8,16(sp)
    80003284:	6ca2                	ld	s9,8(sp)
    80003286:	6125                	addi	sp,sp,96
    80003288:	8082                	ret

000000008000328a <reparent>:
{
    8000328a:	7179                	addi	sp,sp,-48
    8000328c:	f406                	sd	ra,40(sp)
    8000328e:	f022                	sd	s0,32(sp)
    80003290:	ec26                	sd	s1,24(sp)
    80003292:	e84a                	sd	s2,16(sp)
    80003294:	e44e                	sd	s3,8(sp)
    80003296:	e052                	sd	s4,0(sp)
    80003298:	1800                	addi	s0,sp,48
    8000329a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000329c:	0000f497          	auipc	s1,0xf
    800032a0:	4d448493          	addi	s1,s1,1236 # 80012770 <proc>
      pp->parent = initproc;
    800032a4:	00007a17          	auipc	s4,0x7
    800032a8:	d84a0a13          	addi	s4,s4,-636 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800032ac:	00016997          	auipc	s3,0x16
    800032b0:	ac498993          	addi	s3,s3,-1340 # 80018d70 <tickslock>
    800032b4:	a029                	j	800032be <reparent+0x34>
    800032b6:	19848493          	addi	s1,s1,408
    800032ba:	01348d63          	beq	s1,s3,800032d4 <reparent+0x4a>
    if(pp->parent == p){
    800032be:	74bc                	ld	a5,104(s1)
    800032c0:	ff279be3          	bne	a5,s2,800032b6 <reparent+0x2c>
      pp->parent = initproc;
    800032c4:	000a3503          	ld	a0,0(s4)
    800032c8:	f4a8                	sd	a0,104(s1)
      wakeup(initproc);
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	dca080e7          	jalr	-566(ra) # 80003094 <wakeup>
    800032d2:	b7d5                	j	800032b6 <reparent+0x2c>
}
    800032d4:	70a2                	ld	ra,40(sp)
    800032d6:	7402                	ld	s0,32(sp)
    800032d8:	64e2                	ld	s1,24(sp)
    800032da:	6942                	ld	s2,16(sp)
    800032dc:	69a2                	ld	s3,8(sp)
    800032de:	6a02                	ld	s4,0(sp)
    800032e0:	6145                	addi	sp,sp,48
    800032e2:	8082                	ret

00000000800032e4 <exit>:
{
    800032e4:	7179                	addi	sp,sp,-48
    800032e6:	f406                	sd	ra,40(sp)
    800032e8:	f022                	sd	s0,32(sp)
    800032ea:	ec26                	sd	s1,24(sp)
    800032ec:	e84a                	sd	s2,16(sp)
    800032ee:	e44e                	sd	s3,8(sp)
    800032f0:	e052                	sd	s4,0(sp)
    800032f2:	1800                	addi	s0,sp,48
    800032f4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800032f6:	fffff097          	auipc	ra,0xfffff
    800032fa:	89e080e7          	jalr	-1890(ra) # 80001b94 <myproc>
    800032fe:	892a                	mv	s2,a0
  if(p == initproc)
    80003300:	00007797          	auipc	a5,0x7
    80003304:	d287b783          	ld	a5,-728(a5) # 8000a028 <initproc>
    80003308:	10050493          	addi	s1,a0,256
    8000330c:	18050993          	addi	s3,a0,384
    80003310:	02a79363          	bne	a5,a0,80003336 <exit+0x52>
    panic("init exiting");
    80003314:	00006517          	auipc	a0,0x6
    80003318:	21c50513          	addi	a0,a0,540 # 80009530 <digits+0x4f0>
    8000331c:	ffffd097          	auipc	ra,0xffffd
    80003320:	222080e7          	jalr	546(ra) # 8000053e <panic>
      fileclose(f);
    80003324:	00003097          	auipc	ra,0x3
    80003328:	8b0080e7          	jalr	-1872(ra) # 80005bd4 <fileclose>
      p->ofile[fd] = 0;
    8000332c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80003330:	04a1                	addi	s1,s1,8
    80003332:	00998563          	beq	s3,s1,8000333c <exit+0x58>
    if(p->ofile[fd]){
    80003336:	6088                	ld	a0,0(s1)
    80003338:	f575                	bnez	a0,80003324 <exit+0x40>
    8000333a:	bfdd                	j	80003330 <exit+0x4c>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    8000333c:	18890493          	addi	s1,s2,392
    80003340:	00006597          	auipc	a1,0x6
    80003344:	20058593          	addi	a1,a1,512 # 80009540 <digits+0x500>
    80003348:	8526                	mv	a0,s1
    8000334a:	fffff097          	auipc	ra,0xfffff
    8000334e:	dfa080e7          	jalr	-518(ra) # 80002144 <str_compare>
    80003352:	e97d                	bnez	a0,80003448 <exit+0x164>
  begin_op();
    80003354:	00002097          	auipc	ra,0x2
    80003358:	3b4080e7          	jalr	948(ra) # 80005708 <begin_op>
  iput(p->cwd);
    8000335c:	18093503          	ld	a0,384(s2)
    80003360:	00002097          	auipc	ra,0x2
    80003364:	b90080e7          	jalr	-1136(ra) # 80004ef0 <iput>
  end_op();
    80003368:	00002097          	auipc	ra,0x2
    8000336c:	420080e7          	jalr	1056(ra) # 80005788 <end_op>
  p->cwd = 0;
    80003370:	18093023          	sd	zero,384(s2)
  acquire(&wait_lock);
    80003374:	0000f517          	auipc	a0,0xf
    80003378:	3e450513          	addi	a0,a0,996 # 80012758 <wait_lock>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	868080e7          	jalr	-1944(ra) # 80000be4 <acquire>
  reparent(p);
    80003384:	854a                	mv	a0,s2
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	f04080e7          	jalr	-252(ra) # 8000328a <reparent>
  wakeup(p->parent);
    8000338e:	06893503          	ld	a0,104(s2)
    80003392:	00000097          	auipc	ra,0x0
    80003396:	d02080e7          	jalr	-766(ra) # 80003094 <wakeup>
  acquire(&p->lock);
    8000339a:	854a                	mv	a0,s2
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	848080e7          	jalr	-1976(ra) # 80000be4 <acquire>
  p->xstate = status;
    800033a4:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    800033a8:	4795                	li	a5,5
    800033aa:	00f92c23          	sw	a5,24(s2)
  p->running_time += ticks - p->start_running_time;
    800033ae:	04492783          	lw	a5,68(s2)
    800033b2:	00007717          	auipc	a4,0x7
    800033b6:	ca272703          	lw	a4,-862(a4) # 8000a054 <ticks>
    800033ba:	9fb9                	addw	a5,a5,a4
    800033bc:	05092703          	lw	a4,80(s2)
    800033c0:	9f99                	subw	a5,a5,a4
    800033c2:	04f92223          	sw	a5,68(s2)
  printf("runnable ");
    800033c6:	00006517          	auipc	a0,0x6
    800033ca:	08250513          	addi	a0,a0,130 # 80009448 <digits+0x408>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	1ba080e7          	jalr	442(ra) # 80000588 <printf>
  int res = remove_proc_from_list(p->proc_ind); 
    800033d6:	05c92503          	lw	a0,92(s2)
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	4ea080e7          	jalr	1258(ra) # 800018c4 <remove_proc_from_list>
  if (res == 1)
    800033e2:	4785                	li	a5,1
    800033e4:	10f50863          	beq	a0,a5,800034f4 <exit+0x210>
  if (res == 2)
    800033e8:	4789                	li	a5,2
    800033ea:	14f50763          	beq	a0,a5,80003538 <exit+0x254>
  if (res == 3){
    800033ee:	478d                	li	a5,3
    800033f0:	1cf50a63          	beq	a0,a5,800035c4 <exit+0x2e0>
  p->next_proc = -1;
    800033f4:	57fd                	li	a5,-1
    800033f6:	06f92023          	sw	a5,96(s2)
  p->prev_proc = -1;
    800033fa:	06f92223          	sw	a5,100(s2)
  if (zombie_list_tail != -1){
    800033fe:	00007717          	auipc	a4,0x7
    80003402:	82a72703          	lw	a4,-2006(a4) # 80009c28 <zombie_list_tail>
    80003406:	57fd                	li	a5,-1
    80003408:	24f71463          	bne	a4,a5,80003650 <exit+0x36c>
    zombie_list_tail = zombie_list_head = p->proc_ind;
    8000340c:	05c92783          	lw	a5,92(s2)
    80003410:	00007717          	auipc	a4,0x7
    80003414:	80f72e23          	sw	a5,-2020(a4) # 80009c2c <zombie_list_head>
    80003418:	00007717          	auipc	a4,0x7
    8000341c:	80f72823          	sw	a5,-2032(a4) # 80009c28 <zombie_list_tail>
  release(&wait_lock);
    80003420:	0000f517          	auipc	a0,0xf
    80003424:	33850513          	addi	a0,a0,824 # 80012758 <wait_lock>
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	870080e7          	jalr	-1936(ra) # 80000c98 <release>
  sched();
    80003430:	fffff097          	auipc	ra,0xfffff
    80003434:	610080e7          	jalr	1552(ra) # 80002a40 <sched>
  panic("zombie exit");
    80003438:	00006517          	auipc	a0,0x6
    8000343c:	15050513          	addi	a0,a0,336 # 80009588 <digits+0x548>
    80003440:	ffffd097          	auipc	ra,0xffffd
    80003444:	0fe080e7          	jalr	254(ra) # 8000053e <panic>
  if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) 
    80003448:	00006597          	auipc	a1,0x6
    8000344c:	10058593          	addi	a1,a1,256 # 80009548 <digits+0x508>
    80003450:	8526                	mv	a0,s1
    80003452:	fffff097          	auipc	ra,0xfffff
    80003456:	cf2080e7          	jalr	-782(ra) # 80002144 <str_compare>
    8000345a:	ee050de3          	beqz	a0,80003354 <exit+0x70>
    sleeping_processes_mean = ((sleeping_processes_mean * p_counter)+ p->sleeping_time)/(p_counter+1);
    8000345e:	00007597          	auipc	a1,0x7
    80003462:	bde58593          	addi	a1,a1,-1058 # 8000a03c <p_counter>
    80003466:	4194                	lw	a3,0(a1)
    80003468:	0016871b          	addiw	a4,a3,1
    8000346c:	00007617          	auipc	a2,0x7
    80003470:	bdc60613          	addi	a2,a2,-1060 # 8000a048 <sleeping_processes_mean>
    80003474:	421c                	lw	a5,0(a2)
    80003476:	02d787bb          	mulw	a5,a5,a3
    8000347a:	04c92503          	lw	a0,76(s2)
    8000347e:	9fa9                	addw	a5,a5,a0
    80003480:	02e7d7bb          	divuw	a5,a5,a4
    80003484:	c21c                	sw	a5,0(a2)
    running_processes_mean = ((running_processes_mean * p_counter)+ p->running_time)/(p_counter+1);
    80003486:	04492603          	lw	a2,68(s2)
    8000348a:	00007517          	auipc	a0,0x7
    8000348e:	bba50513          	addi	a0,a0,-1094 # 8000a044 <running_processes_mean>
    80003492:	411c                	lw	a5,0(a0)
    80003494:	02d787bb          	mulw	a5,a5,a3
    80003498:	9fb1                	addw	a5,a5,a2
    8000349a:	02e7d7bb          	divuw	a5,a5,a4
    8000349e:	c11c                	sw	a5,0(a0)
    runnable_processes_mean = ((runnable_processes_mean * p_counter)+ p->runnable_time)/(p_counter+1);
    800034a0:	00007517          	auipc	a0,0x7
    800034a4:	ba050513          	addi	a0,a0,-1120 # 8000a040 <runnable_processes_mean>
    800034a8:	411c                	lw	a5,0(a0)
    800034aa:	02d787bb          	mulw	a5,a5,a3
    800034ae:	04892683          	lw	a3,72(s2)
    800034b2:	9fb5                	addw	a5,a5,a3
    800034b4:	02e7d7bb          	divuw	a5,a5,a4
    800034b8:	c11c                	sw	a5,0(a0)
    p_counter += 1;
    800034ba:	c198                	sw	a4,0(a1)
    program_time += p->running_time;
    800034bc:	00007697          	auipc	a3,0x7
    800034c0:	b7c68693          	addi	a3,a3,-1156 # 8000a038 <program_time>
    800034c4:	429c                	lw	a5,0(a3)
    800034c6:	00c7873b          	addw	a4,a5,a2
    800034ca:	c298                	sw	a4,0(a3)
    cpu_utilization = (program_time* 100) / (ticks - start_time) ;
    800034cc:	06400793          	li	a5,100
    800034d0:	02e787bb          	mulw	a5,a5,a4
    800034d4:	00007717          	auipc	a4,0x7
    800034d8:	b8072703          	lw	a4,-1152(a4) # 8000a054 <ticks>
    800034dc:	00007697          	auipc	a3,0x7
    800034e0:	b586a683          	lw	a3,-1192(a3) # 8000a034 <start_time>
    800034e4:	9f15                	subw	a4,a4,a3
    800034e6:	02e7d7bb          	divuw	a5,a5,a4
    800034ea:	00007717          	auipc	a4,0x7
    800034ee:	b4f72323          	sw	a5,-1210(a4) # 8000a030 <cpu_utilization>
    800034f2:	b58d                	j	80003354 <exit+0x70>
    800034f4:	8612                	mv	a2,tp
  int id = r_tp();
    800034f6:	2601                	sext.w	a2,a2
  c->cpu_id = id;
    800034f8:	0000f797          	auipc	a5,0xf
    800034fc:	dc878793          	addi	a5,a5,-568 # 800122c0 <cpus>
    80003500:	09000693          	li	a3,144
    80003504:	02d60733          	mul	a4,a2,a3
    80003508:	973e                	add	a4,a4,a5
    8000350a:	08c72423          	sw	a2,136(a4)
    mycpu()->runnable_list_head = -1;
    8000350e:	567d                	li	a2,-1
    80003510:	08c72023          	sw	a2,128(a4)
    80003514:	8712                	mv	a4,tp
  int id = r_tp();
    80003516:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    80003518:	02d706b3          	mul	a3,a4,a3
    8000351c:	97b6                	add	a5,a5,a3
    8000351e:	08e7a423          	sw	a4,136(a5)
    mycpu()->runnable_list_tail = -1;
    80003522:	08c7a223          	sw	a2,132(a5)
    printf("3 no head & tail");
    80003526:	00006517          	auipc	a0,0x6
    8000352a:	02a50513          	addi	a0,a0,42 # 80009550 <digits+0x510>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	05a080e7          	jalr	90(ra) # 80000588 <printf>
  if (res == 3){
    80003536:	bd7d                	j	800033f4 <exit+0x110>
    80003538:	8792                	mv	a5,tp
  int id = r_tp();
    8000353a:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    8000353c:	09000713          	li	a4,144
    80003540:	02e786b3          	mul	a3,a5,a4
    80003544:	0000f717          	auipc	a4,0xf
    80003548:	d7c70713          	addi	a4,a4,-644 # 800122c0 <cpus>
    8000354c:	9736                	add	a4,a4,a3
    8000354e:	08f72423          	sw	a5,136(a4)
    mycpu()->runnable_list_head = p->next_proc;
    80003552:	06092783          	lw	a5,96(s2)
    80003556:	08f72023          	sw	a5,128(a4)
    if (proc[p->next_proc].next_proc == -1)
    8000355a:	19800713          	li	a4,408
    8000355e:	02e787b3          	mul	a5,a5,a4
    80003562:	0000f717          	auipc	a4,0xf
    80003566:	20e70713          	addi	a4,a4,526 # 80012770 <proc>
    8000356a:	97ba                	add	a5,a5,a4
    8000356c:	53b8                	lw	a4,96(a5)
    8000356e:	57fd                	li	a5,-1
    80003570:	02f70863          	beq	a4,a5,800035a0 <exit+0x2bc>
    proc[p->next_proc].prev_proc = -1;
    80003574:	06092783          	lw	a5,96(s2)
    80003578:	19800713          	li	a4,408
    8000357c:	02e78733          	mul	a4,a5,a4
    80003580:	0000f797          	auipc	a5,0xf
    80003584:	1f078793          	addi	a5,a5,496 # 80012770 <proc>
    80003588:	97ba                	add	a5,a5,a4
    8000358a:	577d                	li	a4,-1
    8000358c:	d3f8                	sw	a4,100(a5)
    printf("3 no head");
    8000358e:	00006517          	auipc	a0,0x6
    80003592:	fda50513          	addi	a0,a0,-38 # 80009568 <digits+0x528>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	ff2080e7          	jalr	-14(ra) # 80000588 <printf>
  if (res == 3){
    8000359e:	bd99                	j	800033f4 <exit+0x110>
    800035a0:	8712                	mv	a4,tp
  int id = r_tp();
    800035a2:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    800035a4:	09000793          	li	a5,144
    800035a8:	02f706b3          	mul	a3,a4,a5
    800035ac:	0000f797          	auipc	a5,0xf
    800035b0:	d1478793          	addi	a5,a5,-748 # 800122c0 <cpus>
    800035b4:	97b6                	add	a5,a5,a3
    800035b6:	08e7a423          	sw	a4,136(a5)
      mycpu()->runnable_list_tail = p->next_proc;
    800035ba:	06092703          	lw	a4,96(s2)
    800035be:	08e7a223          	sw	a4,132(a5)
    800035c2:	bf4d                	j	80003574 <exit+0x290>
    800035c4:	8792                	mv	a5,tp
  int id = r_tp();
    800035c6:	2781                	sext.w	a5,a5
  c->cpu_id = id;
    800035c8:	09000713          	li	a4,144
    800035cc:	02e786b3          	mul	a3,a5,a4
    800035d0:	0000f717          	auipc	a4,0xf
    800035d4:	cf070713          	addi	a4,a4,-784 # 800122c0 <cpus>
    800035d8:	9736                	add	a4,a4,a3
    800035da:	08f72423          	sw	a5,136(a4)
    mycpu()->runnable_list_tail = p->prev_proc;
    800035de:	06492783          	lw	a5,100(s2)
    800035e2:	08f72223          	sw	a5,132(a4)
    if (proc[p->prev_proc].prev_proc == -1)
    800035e6:	19800713          	li	a4,408
    800035ea:	02e787b3          	mul	a5,a5,a4
    800035ee:	0000f717          	auipc	a4,0xf
    800035f2:	18270713          	addi	a4,a4,386 # 80012770 <proc>
    800035f6:	97ba                	add	a5,a5,a4
    800035f8:	53f8                	lw	a4,100(a5)
    800035fa:	57fd                	li	a5,-1
    800035fc:	02f70863          	beq	a4,a5,8000362c <exit+0x348>
    proc[p->prev_proc].next_proc = -1;
    80003600:	06492783          	lw	a5,100(s2)
    80003604:	19800713          	li	a4,408
    80003608:	02e78733          	mul	a4,a5,a4
    8000360c:	0000f797          	auipc	a5,0xf
    80003610:	16478793          	addi	a5,a5,356 # 80012770 <proc>
    80003614:	97ba                	add	a5,a5,a4
    80003616:	577d                	li	a4,-1
    80003618:	d3b8                	sw	a4,96(a5)
    printf("3 no tail");
    8000361a:	00006517          	auipc	a0,0x6
    8000361e:	f5e50513          	addi	a0,a0,-162 # 80009578 <digits+0x538>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	f66080e7          	jalr	-154(ra) # 80000588 <printf>
    8000362a:	b3e9                	j	800033f4 <exit+0x110>
    8000362c:	8712                	mv	a4,tp
  int id = r_tp();
    8000362e:	2701                	sext.w	a4,a4
  c->cpu_id = id;
    80003630:	09000793          	li	a5,144
    80003634:	02f706b3          	mul	a3,a4,a5
    80003638:	0000f797          	auipc	a5,0xf
    8000363c:	c8878793          	addi	a5,a5,-888 # 800122c0 <cpus>
    80003640:	97b6                	add	a5,a5,a3
    80003642:	08e7a423          	sw	a4,136(a5)
      mycpu()->runnable_list_head = p->prev_proc;
    80003646:	06492703          	lw	a4,100(s2)
    8000364a:	08e7a023          	sw	a4,128(a5)
    8000364e:	bf4d                	j	80003600 <exit+0x31c>
    printf("zombie");
    80003650:	00006517          	auipc	a0,0x6
    80003654:	c2850513          	addi	a0,a0,-984 # 80009278 <digits+0x238>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	f30080e7          	jalr	-208(ra) # 80000588 <printf>
    add_proc_to_list(zombie_list_tail, p);
    80003660:	85ca                	mv	a1,s2
    80003662:	00006517          	auipc	a0,0x6
    80003666:	5c652503          	lw	a0,1478(a0) # 80009c28 <zombie_list_tail>
    8000366a:	ffffe097          	auipc	ra,0xffffe
    8000366e:	1dc080e7          	jalr	476(ra) # 80001846 <add_proc_to_list>
     if (zombie_list_head == -1)
    80003672:	00006717          	auipc	a4,0x6
    80003676:	5ba72703          	lw	a4,1466(a4) # 80009c2c <zombie_list_head>
    8000367a:	57fd                	li	a5,-1
    8000367c:	00f70963          	beq	a4,a5,8000368e <exit+0x3aa>
    zombie_list_tail = p->proc_ind;
    80003680:	05c92783          	lw	a5,92(s2)
    80003684:	00006717          	auipc	a4,0x6
    80003688:	5af72223          	sw	a5,1444(a4) # 80009c28 <zombie_list_tail>
    8000368c:	bb51                	j	80003420 <exit+0x13c>
        zombie_list_head = p->proc_ind;
    8000368e:	05c92783          	lw	a5,92(s2)
    80003692:	00006717          	auipc	a4,0x6
    80003696:	58f72d23          	sw	a5,1434(a4) # 80009c2c <zombie_list_head>
    8000369a:	b7dd                	j	80003680 <exit+0x39c>

000000008000369c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000369c:	7179                	addi	sp,sp,-48
    8000369e:	f406                	sd	ra,40(sp)
    800036a0:	f022                	sd	s0,32(sp)
    800036a2:	ec26                	sd	s1,24(sp)
    800036a4:	e84a                	sd	s2,16(sp)
    800036a6:	e44e                	sd	s3,8(sp)
    800036a8:	1800                	addi	s0,sp,48
    800036aa:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800036ac:	0000f497          	auipc	s1,0xf
    800036b0:	0c448493          	addi	s1,s1,196 # 80012770 <proc>
    800036b4:	00015997          	auipc	s3,0x15
    800036b8:	6bc98993          	addi	s3,s3,1724 # 80018d70 <tickslock>
    acquire(&p->lock);
    800036bc:	8526                	mv	a0,s1
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	526080e7          	jalr	1318(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800036c6:	589c                	lw	a5,48(s1)
    800036c8:	01278d63          	beq	a5,s2,800036e2 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800036cc:	8526                	mv	a0,s1
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	5ca080e7          	jalr	1482(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800036d6:	19848493          	addi	s1,s1,408
    800036da:	ff3491e3          	bne	s1,s3,800036bc <kill+0x20>
  }
  return -1;
    800036de:	557d                	li	a0,-1
    800036e0:	a829                	j	800036fa <kill+0x5e>
      p->killed = 1;
    800036e2:	4785                	li	a5,1
    800036e4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800036e6:	4c98                	lw	a4,24(s1)
    800036e8:	4789                	li	a5,2
    800036ea:	00f70f63          	beq	a4,a5,80003708 <kill+0x6c>
      release(&p->lock);
    800036ee:	8526                	mv	a0,s1
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	5a8080e7          	jalr	1448(ra) # 80000c98 <release>
      return 0;
    800036f8:	4501                	li	a0,0
}
    800036fa:	70a2                	ld	ra,40(sp)
    800036fc:	7402                	ld	s0,32(sp)
    800036fe:	64e2                	ld	s1,24(sp)
    80003700:	6942                	ld	s2,16(sp)
    80003702:	69a2                	ld	s3,8(sp)
    80003704:	6145                	addi	sp,sp,48
    80003706:	8082                	ret
        p->state = RUNNABLE;
    80003708:	478d                	li	a5,3
    8000370a:	cc9c                	sw	a5,24(s1)
        p->sleeping_time += ticks - p->start_sleeping_time;
    8000370c:	00007717          	auipc	a4,0x7
    80003710:	94872703          	lw	a4,-1720(a4) # 8000a054 <ticks>
    80003714:	44fc                	lw	a5,76(s1)
    80003716:	9fb9                	addw	a5,a5,a4
    80003718:	48f4                	lw	a3,84(s1)
    8000371a:	9f95                	subw	a5,a5,a3
    8000371c:	c4fc                	sw	a5,76(s1)
        p->last_runnable_time = ticks;
    8000371e:	dcd8                	sw	a4,60(s1)
    80003720:	b7f9                	j	800036ee <kill+0x52>

0000000080003722 <print_stats>:

int 
print_stats(void)
{
    80003722:	1141                	addi	sp,sp,-16
    80003724:	e406                	sd	ra,8(sp)
    80003726:	e022                	sd	s0,0(sp)
    80003728:	0800                	addi	s0,sp,16
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    8000372a:	00007597          	auipc	a1,0x7
    8000372e:	91e5a583          	lw	a1,-1762(a1) # 8000a048 <sleeping_processes_mean>
    80003732:	00006517          	auipc	a0,0x6
    80003736:	e6650513          	addi	a0,a0,-410 # 80009598 <digits+0x558>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	e4e080e7          	jalr	-434(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    80003742:	00007597          	auipc	a1,0x7
    80003746:	8fe5a583          	lw	a1,-1794(a1) # 8000a040 <runnable_processes_mean>
    8000374a:	00006517          	auipc	a0,0x6
    8000374e:	e6e50513          	addi	a0,a0,-402 # 800095b8 <digits+0x578>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	e36080e7          	jalr	-458(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    8000375a:	00007597          	auipc	a1,0x7
    8000375e:	8ea5a583          	lw	a1,-1814(a1) # 8000a044 <running_processes_mean>
    80003762:	00006517          	auipc	a0,0x6
    80003766:	e7650513          	addi	a0,a0,-394 # 800095d8 <digits+0x598>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	e1e080e7          	jalr	-482(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80003772:	00007597          	auipc	a1,0x7
    80003776:	8c65a583          	lw	a1,-1850(a1) # 8000a038 <program_time>
    8000377a:	00006517          	auipc	a0,0x6
    8000377e:	e7e50513          	addi	a0,a0,-386 # 800095f8 <digits+0x5b8>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	e06080e7          	jalr	-506(ra) # 80000588 <printf>
  printf("cpu_utilization: %d\n", cpu_utilization);
    8000378a:	00007597          	auipc	a1,0x7
    8000378e:	8a65a583          	lw	a1,-1882(a1) # 8000a030 <cpu_utilization>
    80003792:	00006517          	auipc	a0,0x6
    80003796:	e7e50513          	addi	a0,a0,-386 # 80009610 <digits+0x5d0>
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	dee080e7          	jalr	-530(ra) # 80000588 <printf>
  printf("ticks: %d\n", ticks);
    800037a2:	00007597          	auipc	a1,0x7
    800037a6:	8b25a583          	lw	a1,-1870(a1) # 8000a054 <ticks>
    800037aa:	00006517          	auipc	a0,0x6
    800037ae:	e7e50513          	addi	a0,a0,-386 # 80009628 <digits+0x5e8>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	dd6080e7          	jalr	-554(ra) # 80000588 <printf>
  return 0;
}
    800037ba:	4501                	li	a0,0
    800037bc:	60a2                	ld	ra,8(sp)
    800037be:	6402                	ld	s0,0(sp)
    800037c0:	0141                	addi	sp,sp,16
    800037c2:	8082                	ret

00000000800037c4 <set_cpu>:
// Ass2
int
set_cpu(int cpu_num)
{
  // TODO
  if (cpu_num > NCPU)
    800037c4:	47a1                	li	a5,8
    800037c6:	0aa7cd63          	blt	a5,a0,80003880 <set_cpu+0xbc>
{
    800037ca:	1101                	addi	sp,sp,-32
    800037cc:	ec06                	sd	ra,24(sp)
    800037ce:	e822                	sd	s0,16(sp)
    800037d0:	e426                	sd	s1,8(sp)
    800037d2:	e04a                	sd	s2,0(sp)
    800037d4:	1000                	addi	s0,sp,32
    return -1;

  struct cpu* c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    800037d6:	0000f497          	auipc	s1,0xf
    800037da:	aea48493          	addi	s1,s1,-1302 # 800122c0 <cpus>
    800037de:	0000f717          	auipc	a4,0xf
    800037e2:	f6270713          	addi	a4,a4,-158 # 80012740 <pid_lock>
  {
    if (c->cpu_id == cpu_num)
    800037e6:	0884a783          	lw	a5,136(s1)
    800037ea:	00a78d63          	beq	a5,a0,80003804 <set_cpu+0x40>
  for(c = cpus; c < &cpus[NCPU]; c++)
    800037ee:	09048493          	addi	s1,s1,144
    800037f2:	fee49ae3          	bne	s1,a4,800037e6 <set_cpu+0x22>
      }
      
      return 0;
    }
  }
  return -1;
    800037f6:	557d                	li	a0,-1
}
    800037f8:	60e2                	ld	ra,24(sp)
    800037fa:	6442                	ld	s0,16(sp)
    800037fc:	64a2                	ld	s1,8(sp)
    800037fe:	6902                	ld	s2,0(sp)
    80003800:	6105                	addi	sp,sp,32
    80003802:	8082                	ret
      if (c->runnable_list_head == -1)
    80003804:	0804a703          	lw	a4,128(s1)
    80003808:	57fd                	li	a5,-1
    8000380a:	02f70f63          	beq	a4,a5,80003848 <set_cpu+0x84>
        printf("runnable5");
    8000380e:	00006517          	auipc	a0,0x6
    80003812:	e5250513          	addi	a0,a0,-430 # 80009660 <digits+0x620>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	d72080e7          	jalr	-654(ra) # 80000588 <printf>
        add_proc_to_list(c->runnable_list_tail, myproc());
    8000381e:	0844a903          	lw	s2,132(s1)
    80003822:	ffffe097          	auipc	ra,0xffffe
    80003826:	372080e7          	jalr	882(ra) # 80001b94 <myproc>
    8000382a:	85aa                	mv	a1,a0
    8000382c:	854a                	mv	a0,s2
    8000382e:	ffffe097          	auipc	ra,0xffffe
    80003832:	018080e7          	jalr	24(ra) # 80001846 <add_proc_to_list>
        c->runnable_list_tail = myproc()->proc_ind;
    80003836:	ffffe097          	auipc	ra,0xffffe
    8000383a:	35e080e7          	jalr	862(ra) # 80001b94 <myproc>
    8000383e:	4d7c                	lw	a5,92(a0)
    80003840:	08f4a223          	sw	a5,132(s1)
      return 0;
    80003844:	4501                	li	a0,0
    80003846:	bf4d                	j	800037f8 <set_cpu+0x34>
        printf("init runnable %d                   5\n", proc->proc_ind);
    80003848:	0000f597          	auipc	a1,0xf
    8000384c:	f845a583          	lw	a1,-124(a1) # 800127cc <proc+0x5c>
    80003850:	00006517          	auipc	a0,0x6
    80003854:	de850513          	addi	a0,a0,-536 # 80009638 <digits+0x5f8>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	d30080e7          	jalr	-720(ra) # 80000588 <printf>
        c->runnable_list_tail = myproc()->proc_ind;
    80003860:	ffffe097          	auipc	ra,0xffffe
    80003864:	334080e7          	jalr	820(ra) # 80001b94 <myproc>
    80003868:	4d7c                	lw	a5,92(a0)
    8000386a:	08f4a223          	sw	a5,132(s1)
        c->runnable_list_head = myproc()->proc_ind;
    8000386e:	ffffe097          	auipc	ra,0xffffe
    80003872:	326080e7          	jalr	806(ra) # 80001b94 <myproc>
    80003876:	4d7c                	lw	a5,92(a0)
    80003878:	08f4a023          	sw	a5,128(s1)
      return 0;
    8000387c:	4501                	li	a0,0
    8000387e:	bfad                	j	800037f8 <set_cpu+0x34>
    return -1;
    80003880:	557d                	li	a0,-1
}
    80003882:	8082                	ret

0000000080003884 <get_cpu>:


int
get_cpu()
{
    80003884:	1141                	addi	sp,sp,-16
    80003886:	e422                	sd	s0,8(sp)
    80003888:	0800                	addi	s0,sp,16
    8000388a:	8512                	mv	a0,tp
  // TODO
  return cpuid();
}
    8000388c:	2501                	sext.w	a0,a0
    8000388e:	6422                	ld	s0,8(sp)
    80003890:	0141                	addi	sp,sp,16
    80003892:	8082                	ret

0000000080003894 <pause_system>:


int
pause_system(int seconds)
{
    80003894:	711d                	addi	sp,sp,-96
    80003896:	ec86                	sd	ra,88(sp)
    80003898:	e8a2                	sd	s0,80(sp)
    8000389a:	e4a6                	sd	s1,72(sp)
    8000389c:	e0ca                	sd	s2,64(sp)
    8000389e:	fc4e                	sd	s3,56(sp)
    800038a0:	f852                	sd	s4,48(sp)
    800038a2:	f456                	sd	s5,40(sp)
    800038a4:	f05a                	sd	s6,32(sp)
    800038a6:	ec5e                	sd	s7,24(sp)
    800038a8:	e862                	sd	s8,16(sp)
    800038aa:	e466                	sd	s9,8(sp)
    800038ac:	1080                	addi	s0,sp,96
    800038ae:	84aa                	mv	s1,a0
  struct proc *p;
  struct proc *myProcess = myproc();
    800038b0:	ffffe097          	auipc	ra,0xffffe
    800038b4:	2e4080e7          	jalr	740(ra) # 80001b94 <myproc>
    800038b8:	8b2a                	mv	s6,a0

  pause_flag = 1;
    800038ba:	4785                	li	a5,1
    800038bc:	00006717          	auipc	a4,0x6
    800038c0:	78f72a23          	sw	a5,1940(a4) # 8000a050 <pause_flag>

  wake_up_time = ticks + (seconds * 10);
    800038c4:	0024979b          	slliw	a5,s1,0x2
    800038c8:	9fa5                	addw	a5,a5,s1
    800038ca:	0017979b          	slliw	a5,a5,0x1
    800038ce:	00006717          	auipc	a4,0x6
    800038d2:	78672703          	lw	a4,1926(a4) # 8000a054 <ticks>
    800038d6:	9fb9                	addw	a5,a5,a4
    800038d8:	00006717          	auipc	a4,0x6
    800038dc:	76f72a23          	sw	a5,1908(a4) # 8000a04c <wake_up_time>

  for(p = proc; p < &proc[NPROC]; p++)
    800038e0:	0000f497          	auipc	s1,0xf
    800038e4:	e9048493          	addi	s1,s1,-368 # 80012770 <proc>
  {
    acquire(&p->lock);
    if(p->state == RUNNING)
    800038e8:	4991                	li	s3,4
    {
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    800038ea:	00006a97          	auipc	s5,0x6
    800038ee:	c56a8a93          	addi	s5,s5,-938 # 80009540 <digits+0x500>
    800038f2:	00006b97          	auipc	s7,0x6
    800038f6:	c56b8b93          	addi	s7,s7,-938 # 80009548 <digits+0x508>
        if (p != myProcess) {
          p->paused = 1;
    800038fa:	4c85                	li	s9,1
          p->running_time += ticks - p->start_running_time;
    800038fc:	00006c17          	auipc	s8,0x6
    80003900:	758c0c13          	addi	s8,s8,1880 # 8000a054 <ticks>
  for(p = proc; p < &proc[NPROC]; p++)
    80003904:	00015917          	auipc	s2,0x15
    80003908:	46c90913          	addi	s2,s2,1132 # 80018d70 <tickslock>
    8000390c:	a811                	j	80003920 <pause_system+0x8c>
          yield();
        }
      }
    }
    release(&p->lock);
    8000390e:	8526                	mv	a0,s1
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	388080e7          	jalr	904(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80003918:	19848493          	addi	s1,s1,408
    8000391c:	05248a63          	beq	s1,s2,80003970 <pause_system+0xdc>
    acquire(&p->lock);
    80003920:	8526                	mv	a0,s1
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	2c2080e7          	jalr	706(ra) # 80000be4 <acquire>
    if(p->state == RUNNING)
    8000392a:	4c9c                	lw	a5,24(s1)
    8000392c:	ff3791e3          	bne	a5,s3,8000390e <pause_system+0x7a>
      if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80003930:	18848a13          	addi	s4,s1,392
    80003934:	85d6                	mv	a1,s5
    80003936:	8552                	mv	a0,s4
    80003938:	fffff097          	auipc	ra,0xfffff
    8000393c:	80c080e7          	jalr	-2036(ra) # 80002144 <str_compare>
    80003940:	d579                	beqz	a0,8000390e <pause_system+0x7a>
    80003942:	85de                	mv	a1,s7
    80003944:	8552                	mv	a0,s4
    80003946:	ffffe097          	auipc	ra,0xffffe
    8000394a:	7fe080e7          	jalr	2046(ra) # 80002144 <str_compare>
    8000394e:	d161                	beqz	a0,8000390e <pause_system+0x7a>
        if (p != myProcess) {
    80003950:	fa9b0fe3          	beq	s6,s1,8000390e <pause_system+0x7a>
          p->paused = 1;
    80003954:	0594a023          	sw	s9,64(s1)
          p->running_time += ticks - p->start_running_time;
    80003958:	40fc                	lw	a5,68(s1)
    8000395a:	000c2703          	lw	a4,0(s8)
    8000395e:	9fb9                	addw	a5,a5,a4
    80003960:	48b8                	lw	a4,80(s1)
    80003962:	9f99                	subw	a5,a5,a4
    80003964:	c0fc                	sw	a5,68(s1)
          yield();
    80003966:	fffff097          	auipc	ra,0xfffff
    8000396a:	1e8080e7          	jalr	488(ra) # 80002b4e <yield>
    8000396e:	b745                	j	8000390e <pause_system+0x7a>
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    80003970:	188b0493          	addi	s1,s6,392
    80003974:	00006597          	auipc	a1,0x6
    80003978:	bcc58593          	addi	a1,a1,-1076 # 80009540 <digits+0x500>
    8000397c:	8526                	mv	a0,s1
    8000397e:	ffffe097          	auipc	ra,0xffffe
    80003982:	7c6080e7          	jalr	1990(ra) # 80002144 <str_compare>
    80003986:	ed19                	bnez	a0,800039a4 <pause_system+0x110>
    myProcess->running_time += ticks - myProcess->start_running_time;
    release(&myProcess->lock);
    yield();
  }
  return 0;
}
    80003988:	4501                	li	a0,0
    8000398a:	60e6                	ld	ra,88(sp)
    8000398c:	6446                	ld	s0,80(sp)
    8000398e:	64a6                	ld	s1,72(sp)
    80003990:	6906                	ld	s2,64(sp)
    80003992:	79e2                	ld	s3,56(sp)
    80003994:	7a42                	ld	s4,48(sp)
    80003996:	7aa2                	ld	s5,40(sp)
    80003998:	7b02                	ld	s6,32(sp)
    8000399a:	6be2                	ld	s7,24(sp)
    8000399c:	6c42                	ld	s8,16(sp)
    8000399e:	6ca2                	ld	s9,8(sp)
    800039a0:	6125                	addi	sp,sp,96
    800039a2:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) 
    800039a4:	00006597          	auipc	a1,0x6
    800039a8:	ba458593          	addi	a1,a1,-1116 # 80009548 <digits+0x508>
    800039ac:	8526                	mv	a0,s1
    800039ae:	ffffe097          	auipc	ra,0xffffe
    800039b2:	796080e7          	jalr	1942(ra) # 80002144 <str_compare>
    800039b6:	d969                	beqz	a0,80003988 <pause_system+0xf4>
    acquire(&myProcess->lock);
    800039b8:	855a                	mv	a0,s6
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	22a080e7          	jalr	554(ra) # 80000be4 <acquire>
    myProcess->paused = 1;
    800039c2:	4785                	li	a5,1
    800039c4:	04fb2023          	sw	a5,64(s6)
    myProcess->running_time += ticks - myProcess->start_running_time;
    800039c8:	044b2783          	lw	a5,68(s6)
    800039cc:	00006717          	auipc	a4,0x6
    800039d0:	68872703          	lw	a4,1672(a4) # 8000a054 <ticks>
    800039d4:	9fb9                	addw	a5,a5,a4
    800039d6:	050b2703          	lw	a4,80(s6)
    800039da:	9f99                	subw	a5,a5,a4
    800039dc:	04fb2223          	sw	a5,68(s6)
    release(&myProcess->lock);
    800039e0:	855a                	mv	a0,s6
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	2b6080e7          	jalr	694(ra) # 80000c98 <release>
    yield();
    800039ea:	fffff097          	auipc	ra,0xfffff
    800039ee:	164080e7          	jalr	356(ra) # 80002b4e <yield>
    800039f2:	bf59                	j	80003988 <pause_system+0xf4>

00000000800039f4 <kill_system>:
// depending on usr_dst.
// Returns 0 on success, -1 on error.

int
kill_system(void) 
{
    800039f4:	7139                	addi	sp,sp,-64
    800039f6:	fc06                	sd	ra,56(sp)
    800039f8:	f822                	sd	s0,48(sp)
    800039fa:	f426                	sd	s1,40(sp)
    800039fc:	f04a                	sd	s2,32(sp)
    800039fe:	ec4e                	sd	s3,24(sp)
    80003a00:	e852                	sd	s4,16(sp)
    80003a02:	e456                	sd	s5,8(sp)
    80003a04:	e05a                	sd	s6,0(sp)
    80003a06:	0080                	addi	s0,sp,64
  struct proc *p;
  struct proc *myProcess = myproc();
    80003a08:	ffffe097          	auipc	ra,0xffffe
    80003a0c:	18c080e7          	jalr	396(ra) # 80001b94 <myproc>
    80003a10:	8b2a                	mv	s6,a0

  for (p = proc; p < &proc[NPROC]; p++) {
    80003a12:	0000f497          	auipc	s1,0xf
    80003a16:	ee648493          	addi	s1,s1,-282 # 800128f8 <proc+0x188>
    80003a1a:	00015a17          	auipc	s4,0x15
    80003a1e:	4dea0a13          	addi	s4,s4,1246 # 80018ef8 <bcache+0x170>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80003a22:	00006997          	auipc	s3,0x6
    80003a26:	b1e98993          	addi	s3,s3,-1250 # 80009540 <digits+0x500>
    80003a2a:	00006a97          	auipc	s5,0x6
    80003a2e:	b1ea8a93          	addi	s5,s5,-1250 # 80009548 <digits+0x508>
    80003a32:	a029                	j	80003a3c <kill_system+0x48>
  for (p = proc; p < &proc[NPROC]; p++) {
    80003a34:	19848493          	addi	s1,s1,408
    80003a38:	03448b63          	beq	s1,s4,80003a6e <kill_system+0x7a>
    if ( str_compare(p->name, "init") != 0 && str_compare(p->name, "sh") != 0 ) {
    80003a3c:	85ce                	mv	a1,s3
    80003a3e:	8526                	mv	a0,s1
    80003a40:	ffffe097          	auipc	ra,0xffffe
    80003a44:	704080e7          	jalr	1796(ra) # 80002144 <str_compare>
    80003a48:	d575                	beqz	a0,80003a34 <kill_system+0x40>
    80003a4a:	85d6                	mv	a1,s5
    80003a4c:	8526                	mv	a0,s1
    80003a4e:	ffffe097          	auipc	ra,0xffffe
    80003a52:	6f6080e7          	jalr	1782(ra) # 80002144 <str_compare>
    80003a56:	dd79                	beqz	a0,80003a34 <kill_system+0x40>
      if (p != myProcess) {
    80003a58:	e7848793          	addi	a5,s1,-392
    80003a5c:	fcfb0ce3          	beq	s6,a5,80003a34 <kill_system+0x40>
        kill(p->pid);      
    80003a60:	ea84a503          	lw	a0,-344(s1)
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	c38080e7          	jalr	-968(ra) # 8000369c <kill>
    80003a6c:	b7e1                	j	80003a34 <kill_system+0x40>
      }
    }
  }
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    80003a6e:	188b0493          	addi	s1,s6,392
    80003a72:	00006597          	auipc	a1,0x6
    80003a76:	ace58593          	addi	a1,a1,-1330 # 80009540 <digits+0x500>
    80003a7a:	8526                	mv	a0,s1
    80003a7c:	ffffe097          	auipc	ra,0xffffe
    80003a80:	6c8080e7          	jalr	1736(ra) # 80002144 <str_compare>
    80003a84:	ed01                	bnez	a0,80003a9c <kill_system+0xa8>
    kill(myProcess->pid);
  }
  return 0;
}
    80003a86:	4501                	li	a0,0
    80003a88:	70e2                	ld	ra,56(sp)
    80003a8a:	7442                	ld	s0,48(sp)
    80003a8c:	74a2                	ld	s1,40(sp)
    80003a8e:	7902                	ld	s2,32(sp)
    80003a90:	69e2                	ld	s3,24(sp)
    80003a92:	6a42                	ld	s4,16(sp)
    80003a94:	6aa2                	ld	s5,8(sp)
    80003a96:	6b02                	ld	s6,0(sp)
    80003a98:	6121                	addi	sp,sp,64
    80003a9a:	8082                	ret
  if ( str_compare(myProcess->name, "init") != 0 && str_compare(myProcess->name, "sh") != 0 ) {
    80003a9c:	00006597          	auipc	a1,0x6
    80003aa0:	aac58593          	addi	a1,a1,-1364 # 80009548 <digits+0x508>
    80003aa4:	8526                	mv	a0,s1
    80003aa6:	ffffe097          	auipc	ra,0xffffe
    80003aaa:	69e080e7          	jalr	1694(ra) # 80002144 <str_compare>
    80003aae:	dd61                	beqz	a0,80003a86 <kill_system+0x92>
    kill(myProcess->pid);
    80003ab0:	030b2503          	lw	a0,48(s6)
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	be8080e7          	jalr	-1048(ra) # 8000369c <kill>
    80003abc:	b7e9                	j	80003a86 <kill_system+0x92>

0000000080003abe <either_copyout>:

int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80003abe:	7179                	addi	sp,sp,-48
    80003ac0:	f406                	sd	ra,40(sp)
    80003ac2:	f022                	sd	s0,32(sp)
    80003ac4:	ec26                	sd	s1,24(sp)
    80003ac6:	e84a                	sd	s2,16(sp)
    80003ac8:	e44e                	sd	s3,8(sp)
    80003aca:	e052                	sd	s4,0(sp)
    80003acc:	1800                	addi	s0,sp,48
    80003ace:	84aa                	mv	s1,a0
    80003ad0:	892e                	mv	s2,a1
    80003ad2:	89b2                	mv	s3,a2
    80003ad4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003ad6:	ffffe097          	auipc	ra,0xffffe
    80003ada:	0be080e7          	jalr	190(ra) # 80001b94 <myproc>
  if(user_dst){
    80003ade:	c08d                	beqz	s1,80003b00 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003ae0:	86d2                	mv	a3,s4
    80003ae2:	864e                	mv	a2,s3
    80003ae4:	85ca                	mv	a1,s2
    80003ae6:	6148                	ld	a0,128(a0)
    80003ae8:	ffffe097          	auipc	ra,0xffffe
    80003aec:	b92080e7          	jalr	-1134(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80003af0:	70a2                	ld	ra,40(sp)
    80003af2:	7402                	ld	s0,32(sp)
    80003af4:	64e2                	ld	s1,24(sp)
    80003af6:	6942                	ld	s2,16(sp)
    80003af8:	69a2                	ld	s3,8(sp)
    80003afa:	6a02                	ld	s4,0(sp)
    80003afc:	6145                	addi	sp,sp,48
    80003afe:	8082                	ret
    memmove((char *)dst, src, len);
    80003b00:	000a061b          	sext.w	a2,s4
    80003b04:	85ce                	mv	a1,s3
    80003b06:	854a                	mv	a0,s2
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	238080e7          	jalr	568(ra) # 80000d40 <memmove>
    return 0;
    80003b10:	8526                	mv	a0,s1
    80003b12:	bff9                	j	80003af0 <either_copyout+0x32>

0000000080003b14 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80003b14:	7179                	addi	sp,sp,-48
    80003b16:	f406                	sd	ra,40(sp)
    80003b18:	f022                	sd	s0,32(sp)
    80003b1a:	ec26                	sd	s1,24(sp)
    80003b1c:	e84a                	sd	s2,16(sp)
    80003b1e:	e44e                	sd	s3,8(sp)
    80003b20:	e052                	sd	s4,0(sp)
    80003b22:	1800                	addi	s0,sp,48
    80003b24:	892a                	mv	s2,a0
    80003b26:	84ae                	mv	s1,a1
    80003b28:	89b2                	mv	s3,a2
    80003b2a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003b2c:	ffffe097          	auipc	ra,0xffffe
    80003b30:	068080e7          	jalr	104(ra) # 80001b94 <myproc>
  if(user_src){
    80003b34:	c08d                	beqz	s1,80003b56 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80003b36:	86d2                	mv	a3,s4
    80003b38:	864e                	mv	a2,s3
    80003b3a:	85ca                	mv	a1,s2
    80003b3c:	6148                	ld	a0,128(a0)
    80003b3e:	ffffe097          	auipc	ra,0xffffe
    80003b42:	bc8080e7          	jalr	-1080(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80003b46:	70a2                	ld	ra,40(sp)
    80003b48:	7402                	ld	s0,32(sp)
    80003b4a:	64e2                	ld	s1,24(sp)
    80003b4c:	6942                	ld	s2,16(sp)
    80003b4e:	69a2                	ld	s3,8(sp)
    80003b50:	6a02                	ld	s4,0(sp)
    80003b52:	6145                	addi	sp,sp,48
    80003b54:	8082                	ret
    memmove(dst, (char*)src, len);
    80003b56:	000a061b          	sext.w	a2,s4
    80003b5a:	85ce                	mv	a1,s3
    80003b5c:	854a                	mv	a0,s2
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	1e2080e7          	jalr	482(ra) # 80000d40 <memmove>
    return 0;
    80003b66:	8526                	mv	a0,s1
    80003b68:	bff9                	j	80003b46 <either_copyin+0x32>

0000000080003b6a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80003b6a:	715d                	addi	sp,sp,-80
    80003b6c:	e486                	sd	ra,72(sp)
    80003b6e:	e0a2                	sd	s0,64(sp)
    80003b70:	fc26                	sd	s1,56(sp)
    80003b72:	f84a                	sd	s2,48(sp)
    80003b74:	f44e                	sd	s3,40(sp)
    80003b76:	f052                	sd	s4,32(sp)
    80003b78:	ec56                	sd	s5,24(sp)
    80003b7a:	e85a                	sd	s6,16(sp)
    80003b7c:	e45e                	sd	s7,8(sp)
    80003b7e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003b80:	00006517          	auipc	a0,0x6
    80003b84:	a8850513          	addi	a0,a0,-1400 # 80009608 <digits+0x5c8>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	a00080e7          	jalr	-1536(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003b90:	0000f497          	auipc	s1,0xf
    80003b94:	d6848493          	addi	s1,s1,-664 # 800128f8 <proc+0x188>
    80003b98:	00015917          	auipc	s2,0x15
    80003b9c:	36090913          	addi	s2,s2,864 # 80018ef8 <bcache+0x170>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003ba0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003ba2:	00006997          	auipc	s3,0x6
    80003ba6:	ace98993          	addi	s3,s3,-1330 # 80009670 <digits+0x630>
    printf("%d %s %s", p->pid, state, p->name);
    80003baa:	00006a97          	auipc	s5,0x6
    80003bae:	acea8a93          	addi	s5,s5,-1330 # 80009678 <digits+0x638>
    printf("\n");
    80003bb2:	00006a17          	auipc	s4,0x6
    80003bb6:	a56a0a13          	addi	s4,s4,-1450 # 80009608 <digits+0x5c8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003bba:	00006b97          	auipc	s7,0x6
    80003bbe:	ae6b8b93          	addi	s7,s7,-1306 # 800096a0 <states.1850>
    80003bc2:	a00d                	j	80003be4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80003bc4:	ea86a583          	lw	a1,-344(a3)
    80003bc8:	8556                	mv	a0,s5
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	9be080e7          	jalr	-1602(ra) # 80000588 <printf>
    printf("\n");
    80003bd2:	8552                	mv	a0,s4
    80003bd4:	ffffd097          	auipc	ra,0xffffd
    80003bd8:	9b4080e7          	jalr	-1612(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003bdc:	19848493          	addi	s1,s1,408
    80003be0:	03248163          	beq	s1,s2,80003c02 <procdump+0x98>
    if(p->state == UNUSED)
    80003be4:	86a6                	mv	a3,s1
    80003be6:	e904a783          	lw	a5,-368(s1)
    80003bea:	dbed                	beqz	a5,80003bdc <procdump+0x72>
      state = "???";
    80003bec:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003bee:	fcfb6be3          	bltu	s6,a5,80003bc4 <procdump+0x5a>
    80003bf2:	1782                	slli	a5,a5,0x20
    80003bf4:	9381                	srli	a5,a5,0x20
    80003bf6:	078e                	slli	a5,a5,0x3
    80003bf8:	97de                	add	a5,a5,s7
    80003bfa:	6390                	ld	a2,0(a5)
    80003bfc:	f661                	bnez	a2,80003bc4 <procdump+0x5a>
      state = "???";
    80003bfe:	864e                	mv	a2,s3
    80003c00:	b7d1                	j	80003bc4 <procdump+0x5a>
  }
}
    80003c02:	60a6                	ld	ra,72(sp)
    80003c04:	6406                	ld	s0,64(sp)
    80003c06:	74e2                	ld	s1,56(sp)
    80003c08:	7942                	ld	s2,48(sp)
    80003c0a:	79a2                	ld	s3,40(sp)
    80003c0c:	7a02                	ld	s4,32(sp)
    80003c0e:	6ae2                	ld	s5,24(sp)
    80003c10:	6b42                	ld	s6,16(sp)
    80003c12:	6ba2                	ld	s7,8(sp)
    80003c14:	6161                	addi	sp,sp,80
    80003c16:	8082                	ret

0000000080003c18 <swtch>:
    80003c18:	00153023          	sd	ra,0(a0)
    80003c1c:	00253423          	sd	sp,8(a0)
    80003c20:	e900                	sd	s0,16(a0)
    80003c22:	ed04                	sd	s1,24(a0)
    80003c24:	03253023          	sd	s2,32(a0)
    80003c28:	03353423          	sd	s3,40(a0)
    80003c2c:	03453823          	sd	s4,48(a0)
    80003c30:	03553c23          	sd	s5,56(a0)
    80003c34:	05653023          	sd	s6,64(a0)
    80003c38:	05753423          	sd	s7,72(a0)
    80003c3c:	05853823          	sd	s8,80(a0)
    80003c40:	05953c23          	sd	s9,88(a0)
    80003c44:	07a53023          	sd	s10,96(a0)
    80003c48:	07b53423          	sd	s11,104(a0)
    80003c4c:	0005b083          	ld	ra,0(a1)
    80003c50:	0085b103          	ld	sp,8(a1)
    80003c54:	6980                	ld	s0,16(a1)
    80003c56:	6d84                	ld	s1,24(a1)
    80003c58:	0205b903          	ld	s2,32(a1)
    80003c5c:	0285b983          	ld	s3,40(a1)
    80003c60:	0305ba03          	ld	s4,48(a1)
    80003c64:	0385ba83          	ld	s5,56(a1)
    80003c68:	0405bb03          	ld	s6,64(a1)
    80003c6c:	0485bb83          	ld	s7,72(a1)
    80003c70:	0505bc03          	ld	s8,80(a1)
    80003c74:	0585bc83          	ld	s9,88(a1)
    80003c78:	0605bd03          	ld	s10,96(a1)
    80003c7c:	0685bd83          	ld	s11,104(a1)
    80003c80:	8082                	ret

0000000080003c82 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003c82:	1141                	addi	sp,sp,-16
    80003c84:	e406                	sd	ra,8(sp)
    80003c86:	e022                	sd	s0,0(sp)
    80003c88:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003c8a:	00006597          	auipc	a1,0x6
    80003c8e:	a4658593          	addi	a1,a1,-1466 # 800096d0 <states.1850+0x30>
    80003c92:	00015517          	auipc	a0,0x15
    80003c96:	0de50513          	addi	a0,a0,222 # 80018d70 <tickslock>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	eba080e7          	jalr	-326(ra) # 80000b54 <initlock>
}
    80003ca2:	60a2                	ld	ra,8(sp)
    80003ca4:	6402                	ld	s0,0(sp)
    80003ca6:	0141                	addi	sp,sp,16
    80003ca8:	8082                	ret

0000000080003caa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003caa:	1141                	addi	sp,sp,-16
    80003cac:	e422                	sd	s0,8(sp)
    80003cae:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003cb0:	00003797          	auipc	a5,0x3
    80003cb4:	54078793          	addi	a5,a5,1344 # 800071f0 <kernelvec>
    80003cb8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003cbc:	6422                	ld	s0,8(sp)
    80003cbe:	0141                	addi	sp,sp,16
    80003cc0:	8082                	ret

0000000080003cc2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003cc2:	1141                	addi	sp,sp,-16
    80003cc4:	e406                	sd	ra,8(sp)
    80003cc6:	e022                	sd	s0,0(sp)
    80003cc8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003cca:	ffffe097          	auipc	ra,0xffffe
    80003cce:	eca080e7          	jalr	-310(ra) # 80001b94 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003cd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003cd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003cd8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003cdc:	00004617          	auipc	a2,0x4
    80003ce0:	32460613          	addi	a2,a2,804 # 80008000 <_trampoline>
    80003ce4:	00004697          	auipc	a3,0x4
    80003ce8:	31c68693          	addi	a3,a3,796 # 80008000 <_trampoline>
    80003cec:	8e91                	sub	a3,a3,a2
    80003cee:	040007b7          	lui	a5,0x4000
    80003cf2:	17fd                	addi	a5,a5,-1
    80003cf4:	07b2                	slli	a5,a5,0xc
    80003cf6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003cf8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003cfc:	6558                	ld	a4,136(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003cfe:	180026f3          	csrr	a3,satp
    80003d02:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003d04:	6558                	ld	a4,136(a0)
    80003d06:	7934                	ld	a3,112(a0)
    80003d08:	6585                	lui	a1,0x1
    80003d0a:	96ae                	add	a3,a3,a1
    80003d0c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003d0e:	6558                	ld	a4,136(a0)
    80003d10:	00000697          	auipc	a3,0x0
    80003d14:	13868693          	addi	a3,a3,312 # 80003e48 <usertrap>
    80003d18:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003d1a:	6558                	ld	a4,136(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003d1c:	8692                	mv	a3,tp
    80003d1e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003d20:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003d24:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003d28:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003d2c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003d30:	6558                	ld	a4,136(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003d32:	6f18                	ld	a4,24(a4)
    80003d34:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003d38:	614c                	ld	a1,128(a0)
    80003d3a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003d3c:	00004717          	auipc	a4,0x4
    80003d40:	35470713          	addi	a4,a4,852 # 80008090 <userret>
    80003d44:	8f11                	sub	a4,a4,a2
    80003d46:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003d48:	577d                	li	a4,-1
    80003d4a:	177e                	slli	a4,a4,0x3f
    80003d4c:	8dd9                	or	a1,a1,a4
    80003d4e:	02000537          	lui	a0,0x2000
    80003d52:	157d                	addi	a0,a0,-1
    80003d54:	0536                	slli	a0,a0,0xd
    80003d56:	9782                	jalr	a5
}
    80003d58:	60a2                	ld	ra,8(sp)
    80003d5a:	6402                	ld	s0,0(sp)
    80003d5c:	0141                	addi	sp,sp,16
    80003d5e:	8082                	ret

0000000080003d60 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003d60:	1101                	addi	sp,sp,-32
    80003d62:	ec06                	sd	ra,24(sp)
    80003d64:	e822                	sd	s0,16(sp)
    80003d66:	e426                	sd	s1,8(sp)
    80003d68:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003d6a:	00015497          	auipc	s1,0x15
    80003d6e:	00648493          	addi	s1,s1,6 # 80018d70 <tickslock>
    80003d72:	8526                	mv	a0,s1
    80003d74:	ffffd097          	auipc	ra,0xffffd
    80003d78:	e70080e7          	jalr	-400(ra) # 80000be4 <acquire>
  ticks++;
    80003d7c:	00006517          	auipc	a0,0x6
    80003d80:	2d850513          	addi	a0,a0,728 # 8000a054 <ticks>
    80003d84:	411c                	lw	a5,0(a0)
    80003d86:	2785                	addiw	a5,a5,1
    80003d88:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003d8a:	fffff097          	auipc	ra,0xfffff
    80003d8e:	30a080e7          	jalr	778(ra) # 80003094 <wakeup>
  release(&tickslock);
    80003d92:	8526                	mv	a0,s1
    80003d94:	ffffd097          	auipc	ra,0xffffd
    80003d98:	f04080e7          	jalr	-252(ra) # 80000c98 <release>
}
    80003d9c:	60e2                	ld	ra,24(sp)
    80003d9e:	6442                	ld	s0,16(sp)
    80003da0:	64a2                	ld	s1,8(sp)
    80003da2:	6105                	addi	sp,sp,32
    80003da4:	8082                	ret

0000000080003da6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003da6:	1101                	addi	sp,sp,-32
    80003da8:	ec06                	sd	ra,24(sp)
    80003daa:	e822                	sd	s0,16(sp)
    80003dac:	e426                	sd	s1,8(sp)
    80003dae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003db0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003db4:	00074d63          	bltz	a4,80003dce <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003db8:	57fd                	li	a5,-1
    80003dba:	17fe                	slli	a5,a5,0x3f
    80003dbc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003dbe:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003dc0:	06f70363          	beq	a4,a5,80003e26 <devintr+0x80>
  }
}
    80003dc4:	60e2                	ld	ra,24(sp)
    80003dc6:	6442                	ld	s0,16(sp)
    80003dc8:	64a2                	ld	s1,8(sp)
    80003dca:	6105                	addi	sp,sp,32
    80003dcc:	8082                	ret
     (scause & 0xff) == 9){
    80003dce:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003dd2:	46a5                	li	a3,9
    80003dd4:	fed792e3          	bne	a5,a3,80003db8 <devintr+0x12>
    int irq = plic_claim();
    80003dd8:	00003097          	auipc	ra,0x3
    80003ddc:	520080e7          	jalr	1312(ra) # 800072f8 <plic_claim>
    80003de0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003de2:	47a9                	li	a5,10
    80003de4:	02f50763          	beq	a0,a5,80003e12 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003de8:	4785                	li	a5,1
    80003dea:	02f50963          	beq	a0,a5,80003e1c <devintr+0x76>
    return 1;
    80003dee:	4505                	li	a0,1
    } else if(irq){
    80003df0:	d8f1                	beqz	s1,80003dc4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003df2:	85a6                	mv	a1,s1
    80003df4:	00006517          	auipc	a0,0x6
    80003df8:	8e450513          	addi	a0,a0,-1820 # 800096d8 <states.1850+0x38>
    80003dfc:	ffffc097          	auipc	ra,0xffffc
    80003e00:	78c080e7          	jalr	1932(ra) # 80000588 <printf>
      plic_complete(irq);
    80003e04:	8526                	mv	a0,s1
    80003e06:	00003097          	auipc	ra,0x3
    80003e0a:	516080e7          	jalr	1302(ra) # 8000731c <plic_complete>
    return 1;
    80003e0e:	4505                	li	a0,1
    80003e10:	bf55                	j	80003dc4 <devintr+0x1e>
      uartintr();
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	b96080e7          	jalr	-1130(ra) # 800009a8 <uartintr>
    80003e1a:	b7ed                	j	80003e04 <devintr+0x5e>
      virtio_disk_intr();
    80003e1c:	00004097          	auipc	ra,0x4
    80003e20:	9e0080e7          	jalr	-1568(ra) # 800077fc <virtio_disk_intr>
    80003e24:	b7c5                	j	80003e04 <devintr+0x5e>
    if(cpuid() == 0){
    80003e26:	ffffe097          	auipc	ra,0xffffe
    80003e2a:	d32080e7          	jalr	-718(ra) # 80001b58 <cpuid>
    80003e2e:	c901                	beqz	a0,80003e3e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003e30:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003e34:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003e36:	14479073          	csrw	sip,a5
    return 2;
    80003e3a:	4509                	li	a0,2
    80003e3c:	b761                	j	80003dc4 <devintr+0x1e>
      clockintr();
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	f22080e7          	jalr	-222(ra) # 80003d60 <clockintr>
    80003e46:	b7ed                	j	80003e30 <devintr+0x8a>

0000000080003e48 <usertrap>:
{
    80003e48:	1101                	addi	sp,sp,-32
    80003e4a:	ec06                	sd	ra,24(sp)
    80003e4c:	e822                	sd	s0,16(sp)
    80003e4e:	e426                	sd	s1,8(sp)
    80003e50:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003e52:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003e56:	1007f793          	andi	a5,a5,256
    80003e5a:	e3a5                	bnez	a5,80003eba <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003e5c:	00003797          	auipc	a5,0x3
    80003e60:	39478793          	addi	a5,a5,916 # 800071f0 <kernelvec>
    80003e64:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003e68:	ffffe097          	auipc	ra,0xffffe
    80003e6c:	d2c080e7          	jalr	-724(ra) # 80001b94 <myproc>
    80003e70:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003e72:	655c                	ld	a5,136(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003e74:	14102773          	csrr	a4,sepc
    80003e78:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003e7a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003e7e:	47a1                	li	a5,8
    80003e80:	04f71b63          	bne	a4,a5,80003ed6 <usertrap+0x8e>
    if(p->killed)
    80003e84:	551c                	lw	a5,40(a0)
    80003e86:	e3b1                	bnez	a5,80003eca <usertrap+0x82>
    p->trapframe->epc += 4;
    80003e88:	64d8                	ld	a4,136(s1)
    80003e8a:	6f1c                	ld	a5,24(a4)
    80003e8c:	0791                	addi	a5,a5,4
    80003e8e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003e90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003e94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003e98:	10079073          	csrw	sstatus,a5
    syscall();
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	2f0080e7          	jalr	752(ra) # 8000418c <syscall>
  if(p->killed)
    80003ea4:	549c                	lw	a5,40(s1)
    80003ea6:	e7b5                	bnez	a5,80003f12 <usertrap+0xca>
  usertrapret();
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	e1a080e7          	jalr	-486(ra) # 80003cc2 <usertrapret>
}
    80003eb0:	60e2                	ld	ra,24(sp)
    80003eb2:	6442                	ld	s0,16(sp)
    80003eb4:	64a2                	ld	s1,8(sp)
    80003eb6:	6105                	addi	sp,sp,32
    80003eb8:	8082                	ret
    panic("usertrap: not from user mode");
    80003eba:	00006517          	auipc	a0,0x6
    80003ebe:	83e50513          	addi	a0,a0,-1986 # 800096f8 <states.1850+0x58>
    80003ec2:	ffffc097          	auipc	ra,0xffffc
    80003ec6:	67c080e7          	jalr	1660(ra) # 8000053e <panic>
      exit(-1);
    80003eca:	557d                	li	a0,-1
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	418080e7          	jalr	1048(ra) # 800032e4 <exit>
    80003ed4:	bf55                	j	80003e88 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	ed0080e7          	jalr	-304(ra) # 80003da6 <devintr>
    80003ede:	f179                	bnez	a0,80003ea4 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003ee0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003ee4:	5890                	lw	a2,48(s1)
    80003ee6:	00006517          	auipc	a0,0x6
    80003eea:	83250513          	addi	a0,a0,-1998 # 80009718 <states.1850+0x78>
    80003eee:	ffffc097          	auipc	ra,0xffffc
    80003ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003ef6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003efa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003efe:	00006517          	auipc	a0,0x6
    80003f02:	84a50513          	addi	a0,a0,-1974 # 80009748 <states.1850+0xa8>
    80003f06:	ffffc097          	auipc	ra,0xffffc
    80003f0a:	682080e7          	jalr	1666(ra) # 80000588 <printf>
    p->killed = 1;
    80003f0e:	4785                	li	a5,1
    80003f10:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003f12:	557d                	li	a0,-1
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	3d0080e7          	jalr	976(ra) # 800032e4 <exit>
    80003f1c:	b771                	j	80003ea8 <usertrap+0x60>

0000000080003f1e <kerneltrap>:
{
    80003f1e:	7179                	addi	sp,sp,-48
    80003f20:	f406                	sd	ra,40(sp)
    80003f22:	f022                	sd	s0,32(sp)
    80003f24:	ec26                	sd	s1,24(sp)
    80003f26:	e84a                	sd	s2,16(sp)
    80003f28:	e44e                	sd	s3,8(sp)
    80003f2a:	e052                	sd	s4,0(sp)
    80003f2c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003f2e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003f32:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003f36:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0){
    80003f3a:	1004f793          	andi	a5,s1,256
    80003f3e:	cb8d                	beqz	a5,80003f70 <kerneltrap+0x52>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003f40:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003f44:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003f46:	ef8d                	bnez	a5,80003f80 <kerneltrap+0x62>
  if((which_dev = devintr()) == 0){
    80003f48:	00000097          	auipc	ra,0x0
    80003f4c:	e5e080e7          	jalr	-418(ra) # 80003da6 <devintr>
    80003f50:	c121                	beqz	a0,80003f90 <kerneltrap+0x72>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003f52:	4789                	li	a5,2
    80003f54:	06f50b63          	beq	a0,a5,80003fca <kerneltrap+0xac>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003f58:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003f5c:	10049073          	csrw	sstatus,s1
}
    80003f60:	70a2                	ld	ra,40(sp)
    80003f62:	7402                	ld	s0,32(sp)
    80003f64:	64e2                	ld	s1,24(sp)
    80003f66:	6942                	ld	s2,16(sp)
    80003f68:	69a2                	ld	s3,8(sp)
    80003f6a:	6a02                	ld	s4,0(sp)
    80003f6c:	6145                	addi	sp,sp,48
    80003f6e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003f70:	00005517          	auipc	a0,0x5
    80003f74:	7f850513          	addi	a0,a0,2040 # 80009768 <states.1850+0xc8>
    80003f78:	ffffc097          	auipc	ra,0xffffc
    80003f7c:	5c6080e7          	jalr	1478(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003f80:	00006517          	auipc	a0,0x6
    80003f84:	81050513          	addi	a0,a0,-2032 # 80009790 <states.1850+0xf0>
    80003f88:	ffffc097          	auipc	ra,0xffffc
    80003f8c:	5b6080e7          	jalr	1462(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003f90:	85ce                	mv	a1,s3
    80003f92:	00006517          	auipc	a0,0x6
    80003f96:	81e50513          	addi	a0,a0,-2018 # 800097b0 <states.1850+0x110>
    80003f9a:	ffffc097          	auipc	ra,0xffffc
    80003f9e:	5ee080e7          	jalr	1518(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003fa2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003fa6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003faa:	00006517          	auipc	a0,0x6
    80003fae:	81650513          	addi	a0,a0,-2026 # 800097c0 <states.1850+0x120>
    80003fb2:	ffffc097          	auipc	ra,0xffffc
    80003fb6:	5d6080e7          	jalr	1494(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003fba:	00006517          	auipc	a0,0x6
    80003fbe:	81e50513          	addi	a0,a0,-2018 # 800097d8 <states.1850+0x138>
    80003fc2:	ffffc097          	auipc	ra,0xffffc
    80003fc6:	57c080e7          	jalr	1404(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003fca:	ffffe097          	auipc	ra,0xffffe
    80003fce:	bca080e7          	jalr	-1078(ra) # 80001b94 <myproc>
    80003fd2:	d159                	beqz	a0,80003f58 <kerneltrap+0x3a>
    80003fd4:	ffffe097          	auipc	ra,0xffffe
    80003fd8:	bc0080e7          	jalr	-1088(ra) # 80001b94 <myproc>
    80003fdc:	4d18                	lw	a4,24(a0)
    80003fde:	4791                	li	a5,4
    80003fe0:	f6f71ce3          	bne	a4,a5,80003f58 <kerneltrap+0x3a>
    myproc()->running_time += ticks - myproc()->start_running_time;
    80003fe4:	00006a17          	auipc	s4,0x6
    80003fe8:	070a2a03          	lw	s4,112(s4) # 8000a054 <ticks>
    80003fec:	ffffe097          	auipc	ra,0xffffe
    80003ff0:	ba8080e7          	jalr	-1112(ra) # 80001b94 <myproc>
    80003ff4:	05052983          	lw	s3,80(a0)
    80003ff8:	ffffe097          	auipc	ra,0xffffe
    80003ffc:	b9c080e7          	jalr	-1124(ra) # 80001b94 <myproc>
    80004000:	417c                	lw	a5,68(a0)
    80004002:	014787bb          	addw	a5,a5,s4
    80004006:	413787bb          	subw	a5,a5,s3
    8000400a:	c17c                	sw	a5,68(a0)
    yield();
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	b42080e7          	jalr	-1214(ra) # 80002b4e <yield>
    80004014:	b791                	j	80003f58 <kerneltrap+0x3a>

0000000080004016 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80004016:	1101                	addi	sp,sp,-32
    80004018:	ec06                	sd	ra,24(sp)
    8000401a:	e822                	sd	s0,16(sp)
    8000401c:	e426                	sd	s1,8(sp)
    8000401e:	1000                	addi	s0,sp,32
    80004020:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80004022:	ffffe097          	auipc	ra,0xffffe
    80004026:	b72080e7          	jalr	-1166(ra) # 80001b94 <myproc>
  switch (n) {
    8000402a:	4795                	li	a5,5
    8000402c:	0497e163          	bltu	a5,s1,8000406e <argraw+0x58>
    80004030:	048a                	slli	s1,s1,0x2
    80004032:	00005717          	auipc	a4,0x5
    80004036:	7de70713          	addi	a4,a4,2014 # 80009810 <states.1850+0x170>
    8000403a:	94ba                	add	s1,s1,a4
    8000403c:	409c                	lw	a5,0(s1)
    8000403e:	97ba                	add	a5,a5,a4
    80004040:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80004042:	655c                	ld	a5,136(a0)
    80004044:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80004046:	60e2                	ld	ra,24(sp)
    80004048:	6442                	ld	s0,16(sp)
    8000404a:	64a2                	ld	s1,8(sp)
    8000404c:	6105                	addi	sp,sp,32
    8000404e:	8082                	ret
    return p->trapframe->a1;
    80004050:	655c                	ld	a5,136(a0)
    80004052:	7fa8                	ld	a0,120(a5)
    80004054:	bfcd                	j	80004046 <argraw+0x30>
    return p->trapframe->a2;
    80004056:	655c                	ld	a5,136(a0)
    80004058:	63c8                	ld	a0,128(a5)
    8000405a:	b7f5                	j	80004046 <argraw+0x30>
    return p->trapframe->a3;
    8000405c:	655c                	ld	a5,136(a0)
    8000405e:	67c8                	ld	a0,136(a5)
    80004060:	b7dd                	j	80004046 <argraw+0x30>
    return p->trapframe->a4;
    80004062:	655c                	ld	a5,136(a0)
    80004064:	6bc8                	ld	a0,144(a5)
    80004066:	b7c5                	j	80004046 <argraw+0x30>
    return p->trapframe->a5;
    80004068:	655c                	ld	a5,136(a0)
    8000406a:	6fc8                	ld	a0,152(a5)
    8000406c:	bfe9                	j	80004046 <argraw+0x30>
  panic("argraw");
    8000406e:	00005517          	auipc	a0,0x5
    80004072:	77a50513          	addi	a0,a0,1914 # 800097e8 <states.1850+0x148>
    80004076:	ffffc097          	auipc	ra,0xffffc
    8000407a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>

000000008000407e <fetchaddr>:
{
    8000407e:	1101                	addi	sp,sp,-32
    80004080:	ec06                	sd	ra,24(sp)
    80004082:	e822                	sd	s0,16(sp)
    80004084:	e426                	sd	s1,8(sp)
    80004086:	e04a                	sd	s2,0(sp)
    80004088:	1000                	addi	s0,sp,32
    8000408a:	84aa                	mv	s1,a0
    8000408c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000408e:	ffffe097          	auipc	ra,0xffffe
    80004092:	b06080e7          	jalr	-1274(ra) # 80001b94 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80004096:	7d3c                	ld	a5,120(a0)
    80004098:	02f4f863          	bgeu	s1,a5,800040c8 <fetchaddr+0x4a>
    8000409c:	00848713          	addi	a4,s1,8
    800040a0:	02e7e663          	bltu	a5,a4,800040cc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800040a4:	46a1                	li	a3,8
    800040a6:	8626                	mv	a2,s1
    800040a8:	85ca                	mv	a1,s2
    800040aa:	6148                	ld	a0,128(a0)
    800040ac:	ffffd097          	auipc	ra,0xffffd
    800040b0:	65a080e7          	jalr	1626(ra) # 80001706 <copyin>
    800040b4:	00a03533          	snez	a0,a0
    800040b8:	40a00533          	neg	a0,a0
}
    800040bc:	60e2                	ld	ra,24(sp)
    800040be:	6442                	ld	s0,16(sp)
    800040c0:	64a2                	ld	s1,8(sp)
    800040c2:	6902                	ld	s2,0(sp)
    800040c4:	6105                	addi	sp,sp,32
    800040c6:	8082                	ret
    return -1;
    800040c8:	557d                	li	a0,-1
    800040ca:	bfcd                	j	800040bc <fetchaddr+0x3e>
    800040cc:	557d                	li	a0,-1
    800040ce:	b7fd                	j	800040bc <fetchaddr+0x3e>

00000000800040d0 <fetchstr>:
{
    800040d0:	7179                	addi	sp,sp,-48
    800040d2:	f406                	sd	ra,40(sp)
    800040d4:	f022                	sd	s0,32(sp)
    800040d6:	ec26                	sd	s1,24(sp)
    800040d8:	e84a                	sd	s2,16(sp)
    800040da:	e44e                	sd	s3,8(sp)
    800040dc:	1800                	addi	s0,sp,48
    800040de:	892a                	mv	s2,a0
    800040e0:	84ae                	mv	s1,a1
    800040e2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800040e4:	ffffe097          	auipc	ra,0xffffe
    800040e8:	ab0080e7          	jalr	-1360(ra) # 80001b94 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800040ec:	86ce                	mv	a3,s3
    800040ee:	864a                	mv	a2,s2
    800040f0:	85a6                	mv	a1,s1
    800040f2:	6148                	ld	a0,128(a0)
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	69e080e7          	jalr	1694(ra) # 80001792 <copyinstr>
  if(err < 0)
    800040fc:	00054763          	bltz	a0,8000410a <fetchstr+0x3a>
  return strlen(buf);
    80004100:	8526                	mv	a0,s1
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	d62080e7          	jalr	-670(ra) # 80000e64 <strlen>
}
    8000410a:	70a2                	ld	ra,40(sp)
    8000410c:	7402                	ld	s0,32(sp)
    8000410e:	64e2                	ld	s1,24(sp)
    80004110:	6942                	ld	s2,16(sp)
    80004112:	69a2                	ld	s3,8(sp)
    80004114:	6145                	addi	sp,sp,48
    80004116:	8082                	ret

0000000080004118 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80004118:	1101                	addi	sp,sp,-32
    8000411a:	ec06                	sd	ra,24(sp)
    8000411c:	e822                	sd	s0,16(sp)
    8000411e:	e426                	sd	s1,8(sp)
    80004120:	1000                	addi	s0,sp,32
    80004122:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80004124:	00000097          	auipc	ra,0x0
    80004128:	ef2080e7          	jalr	-270(ra) # 80004016 <argraw>
    8000412c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000412e:	4501                	li	a0,0
    80004130:	60e2                	ld	ra,24(sp)
    80004132:	6442                	ld	s0,16(sp)
    80004134:	64a2                	ld	s1,8(sp)
    80004136:	6105                	addi	sp,sp,32
    80004138:	8082                	ret

000000008000413a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000413a:	1101                	addi	sp,sp,-32
    8000413c:	ec06                	sd	ra,24(sp)
    8000413e:	e822                	sd	s0,16(sp)
    80004140:	e426                	sd	s1,8(sp)
    80004142:	1000                	addi	s0,sp,32
    80004144:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	ed0080e7          	jalr	-304(ra) # 80004016 <argraw>
    8000414e:	e088                	sd	a0,0(s1)
  return 0;
}
    80004150:	4501                	li	a0,0
    80004152:	60e2                	ld	ra,24(sp)
    80004154:	6442                	ld	s0,16(sp)
    80004156:	64a2                	ld	s1,8(sp)
    80004158:	6105                	addi	sp,sp,32
    8000415a:	8082                	ret

000000008000415c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000415c:	1101                	addi	sp,sp,-32
    8000415e:	ec06                	sd	ra,24(sp)
    80004160:	e822                	sd	s0,16(sp)
    80004162:	e426                	sd	s1,8(sp)
    80004164:	e04a                	sd	s2,0(sp)
    80004166:	1000                	addi	s0,sp,32
    80004168:	84ae                	mv	s1,a1
    8000416a:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	eaa080e7          	jalr	-342(ra) # 80004016 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80004174:	864a                	mv	a2,s2
    80004176:	85a6                	mv	a1,s1
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	f58080e7          	jalr	-168(ra) # 800040d0 <fetchstr>
}
    80004180:	60e2                	ld	ra,24(sp)
    80004182:	6442                	ld	s0,16(sp)
    80004184:	64a2                	ld	s1,8(sp)
    80004186:	6902                	ld	s2,0(sp)
    80004188:	6105                	addi	sp,sp,32
    8000418a:	8082                	ret

000000008000418c <syscall>:
[SYS_set_cpu]       sys_set_cpu,
};

void
syscall(void)
{
    8000418c:	1101                	addi	sp,sp,-32
    8000418e:	ec06                	sd	ra,24(sp)
    80004190:	e822                	sd	s0,16(sp)
    80004192:	e426                	sd	s1,8(sp)
    80004194:	e04a                	sd	s2,0(sp)
    80004196:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80004198:	ffffe097          	auipc	ra,0xffffe
    8000419c:	9fc080e7          	jalr	-1540(ra) # 80001b94 <myproc>
    800041a0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800041a2:	08853903          	ld	s2,136(a0)
    800041a6:	0a893783          	ld	a5,168(s2)
    800041aa:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800041ae:	37fd                	addiw	a5,a5,-1
    800041b0:	4765                	li	a4,25
    800041b2:	00f76f63          	bltu	a4,a5,800041d0 <syscall+0x44>
    800041b6:	00369713          	slli	a4,a3,0x3
    800041ba:	00005797          	auipc	a5,0x5
    800041be:	66e78793          	addi	a5,a5,1646 # 80009828 <syscalls>
    800041c2:	97ba                	add	a5,a5,a4
    800041c4:	639c                	ld	a5,0(a5)
    800041c6:	c789                	beqz	a5,800041d0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800041c8:	9782                	jalr	a5
    800041ca:	06a93823          	sd	a0,112(s2)
    800041ce:	a839                	j	800041ec <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800041d0:	18848613          	addi	a2,s1,392
    800041d4:	588c                	lw	a1,48(s1)
    800041d6:	00005517          	auipc	a0,0x5
    800041da:	61a50513          	addi	a0,a0,1562 # 800097f0 <states.1850+0x150>
    800041de:	ffffc097          	auipc	ra,0xffffc
    800041e2:	3aa080e7          	jalr	938(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800041e6:	64dc                	ld	a5,136(s1)
    800041e8:	577d                	li	a4,-1
    800041ea:	fbb8                	sd	a4,112(a5)
  }
}
    800041ec:	60e2                	ld	ra,24(sp)
    800041ee:	6442                	ld	s0,16(sp)
    800041f0:	64a2                	ld	s1,8(sp)
    800041f2:	6902                	ld	s2,0(sp)
    800041f4:	6105                	addi	sp,sp,32
    800041f6:	8082                	ret

00000000800041f8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800041f8:	1101                	addi	sp,sp,-32
    800041fa:	ec06                	sd	ra,24(sp)
    800041fc:	e822                	sd	s0,16(sp)
    800041fe:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80004200:	fec40593          	addi	a1,s0,-20
    80004204:	4501                	li	a0,0
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	f12080e7          	jalr	-238(ra) # 80004118 <argint>
    return -1;
    8000420e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80004210:	00054963          	bltz	a0,80004222 <sys_exit+0x2a>
  exit(n);
    80004214:	fec42503          	lw	a0,-20(s0)
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	0cc080e7          	jalr	204(ra) # 800032e4 <exit>
  return 0;  // not reached
    80004220:	4781                	li	a5,0
}
    80004222:	853e                	mv	a0,a5
    80004224:	60e2                	ld	ra,24(sp)
    80004226:	6442                	ld	s0,16(sp)
    80004228:	6105                	addi	sp,sp,32
    8000422a:	8082                	ret

000000008000422c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000422c:	1141                	addi	sp,sp,-16
    8000422e:	e406                	sd	ra,8(sp)
    80004230:	e022                	sd	s0,0(sp)
    80004232:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80004234:	ffffe097          	auipc	ra,0xffffe
    80004238:	960080e7          	jalr	-1696(ra) # 80001b94 <myproc>
}
    8000423c:	5908                	lw	a0,48(a0)
    8000423e:	60a2                	ld	ra,8(sp)
    80004240:	6402                	ld	s0,0(sp)
    80004242:	0141                	addi	sp,sp,16
    80004244:	8082                	ret

0000000080004246 <sys_fork>:

uint64
sys_fork(void)
{
    80004246:	1141                	addi	sp,sp,-16
    80004248:	e406                	sd	ra,8(sp)
    8000424a:	e022                	sd	s0,0(sp)
    8000424c:	0800                	addi	s0,sp,16
  return fork();
    8000424e:	ffffe097          	auipc	ra,0xffffe
    80004252:	108080e7          	jalr	264(ra) # 80002356 <fork>
}
    80004256:	60a2                	ld	ra,8(sp)
    80004258:	6402                	ld	s0,0(sp)
    8000425a:	0141                	addi	sp,sp,16
    8000425c:	8082                	ret

000000008000425e <sys_wait>:

uint64
sys_wait(void)
{
    8000425e:	1101                	addi	sp,sp,-32
    80004260:	ec06                	sd	ra,24(sp)
    80004262:	e822                	sd	s0,16(sp)
    80004264:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80004266:	fe840593          	addi	a1,s0,-24
    8000426a:	4501                	li	a0,0
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	ece080e7          	jalr	-306(ra) # 8000413a <argaddr>
    80004274:	87aa                	mv	a5,a0
    return -1;
    80004276:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80004278:	0007c863          	bltz	a5,80004288 <sys_wait+0x2a>
  return wait(p);
    8000427c:	fe843503          	ld	a0,-24(s0)
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	c8a080e7          	jalr	-886(ra) # 80002f0a <wait>
}
    80004288:	60e2                	ld	ra,24(sp)
    8000428a:	6442                	ld	s0,16(sp)
    8000428c:	6105                	addi	sp,sp,32
    8000428e:	8082                	ret

0000000080004290 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80004290:	7179                	addi	sp,sp,-48
    80004292:	f406                	sd	ra,40(sp)
    80004294:	f022                	sd	s0,32(sp)
    80004296:	ec26                	sd	s1,24(sp)
    80004298:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000429a:	fdc40593          	addi	a1,s0,-36
    8000429e:	4501                	li	a0,0
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	e78080e7          	jalr	-392(ra) # 80004118 <argint>
    800042a8:	87aa                	mv	a5,a0
    return -1;
    800042aa:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800042ac:	0207c063          	bltz	a5,800042cc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800042b0:	ffffe097          	auipc	ra,0xffffe
    800042b4:	8e4080e7          	jalr	-1820(ra) # 80001b94 <myproc>
    800042b8:	5d24                	lw	s1,120(a0)
  if(growproc(n) < 0)
    800042ba:	fdc42503          	lw	a0,-36(s0)
    800042be:	ffffe097          	auipc	ra,0xffffe
    800042c2:	024080e7          	jalr	36(ra) # 800022e2 <growproc>
    800042c6:	00054863          	bltz	a0,800042d6 <sys_sbrk+0x46>
    return -1;
  return addr;
    800042ca:	8526                	mv	a0,s1
}
    800042cc:	70a2                	ld	ra,40(sp)
    800042ce:	7402                	ld	s0,32(sp)
    800042d0:	64e2                	ld	s1,24(sp)
    800042d2:	6145                	addi	sp,sp,48
    800042d4:	8082                	ret
    return -1;
    800042d6:	557d                	li	a0,-1
    800042d8:	bfd5                	j	800042cc <sys_sbrk+0x3c>

00000000800042da <sys_sleep>:

uint64
sys_sleep(void)
{
    800042da:	7139                	addi	sp,sp,-64
    800042dc:	fc06                	sd	ra,56(sp)
    800042de:	f822                	sd	s0,48(sp)
    800042e0:	f426                	sd	s1,40(sp)
    800042e2:	f04a                	sd	s2,32(sp)
    800042e4:	ec4e                	sd	s3,24(sp)
    800042e6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800042e8:	fcc40593          	addi	a1,s0,-52
    800042ec:	4501                	li	a0,0
    800042ee:	00000097          	auipc	ra,0x0
    800042f2:	e2a080e7          	jalr	-470(ra) # 80004118 <argint>
    return -1;
    800042f6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800042f8:	06054563          	bltz	a0,80004362 <sys_sleep+0x88>
  acquire(&tickslock);
    800042fc:	00015517          	auipc	a0,0x15
    80004300:	a7450513          	addi	a0,a0,-1420 # 80018d70 <tickslock>
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	8e0080e7          	jalr	-1824(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000430c:	00006917          	auipc	s2,0x6
    80004310:	d4892903          	lw	s2,-696(s2) # 8000a054 <ticks>
  
  while(ticks - ticks0 < n){
    80004314:	fcc42783          	lw	a5,-52(s0)
    80004318:	cf85                	beqz	a5,80004350 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000431a:	00015997          	auipc	s3,0x15
    8000431e:	a5698993          	addi	s3,s3,-1450 # 80018d70 <tickslock>
    80004322:	00006497          	auipc	s1,0x6
    80004326:	d3248493          	addi	s1,s1,-718 # 8000a054 <ticks>
    if(myproc()->killed){
    8000432a:	ffffe097          	auipc	ra,0xffffe
    8000432e:	86a080e7          	jalr	-1942(ra) # 80001b94 <myproc>
    80004332:	551c                	lw	a5,40(a0)
    80004334:	ef9d                	bnez	a5,80004372 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80004336:	85ce                	mv	a1,s3
    80004338:	8526                	mv	a0,s1
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	944080e7          	jalr	-1724(ra) # 80002c7e <sleep>
  while(ticks - ticks0 < n){
    80004342:	409c                	lw	a5,0(s1)
    80004344:	412787bb          	subw	a5,a5,s2
    80004348:	fcc42703          	lw	a4,-52(s0)
    8000434c:	fce7efe3          	bltu	a5,a4,8000432a <sys_sleep+0x50>
  }
  release(&tickslock);
    80004350:	00015517          	auipc	a0,0x15
    80004354:	a2050513          	addi	a0,a0,-1504 # 80018d70 <tickslock>
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	940080e7          	jalr	-1728(ra) # 80000c98 <release>
  return 0;
    80004360:	4781                	li	a5,0
}
    80004362:	853e                	mv	a0,a5
    80004364:	70e2                	ld	ra,56(sp)
    80004366:	7442                	ld	s0,48(sp)
    80004368:	74a2                	ld	s1,40(sp)
    8000436a:	7902                	ld	s2,32(sp)
    8000436c:	69e2                	ld	s3,24(sp)
    8000436e:	6121                	addi	sp,sp,64
    80004370:	8082                	ret
      release(&tickslock);
    80004372:	00015517          	auipc	a0,0x15
    80004376:	9fe50513          	addi	a0,a0,-1538 # 80018d70 <tickslock>
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	91e080e7          	jalr	-1762(ra) # 80000c98 <release>
      return -1;
    80004382:	57fd                	li	a5,-1
    80004384:	bff9                	j	80004362 <sys_sleep+0x88>

0000000080004386 <sys_kill>:

uint64
sys_kill(void)
{
    80004386:	1101                	addi	sp,sp,-32
    80004388:	ec06                	sd	ra,24(sp)
    8000438a:	e822                	sd	s0,16(sp)
    8000438c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000438e:	fec40593          	addi	a1,s0,-20
    80004392:	4501                	li	a0,0
    80004394:	00000097          	auipc	ra,0x0
    80004398:	d84080e7          	jalr	-636(ra) # 80004118 <argint>
    8000439c:	87aa                	mv	a5,a0
    return -1;
    8000439e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800043a0:	0007c863          	bltz	a5,800043b0 <sys_kill+0x2a>
  return kill(pid);
    800043a4:	fec42503          	lw	a0,-20(s0)
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	2f4080e7          	jalr	756(ra) # 8000369c <kill>
}
    800043b0:	60e2                	ld	ra,24(sp)
    800043b2:	6442                	ld	s0,16(sp)
    800043b4:	6105                	addi	sp,sp,32
    800043b6:	8082                	ret

00000000800043b8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800043b8:	1101                	addi	sp,sp,-32
    800043ba:	ec06                	sd	ra,24(sp)
    800043bc:	e822                	sd	s0,16(sp)
    800043be:	e426                	sd	s1,8(sp)
    800043c0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800043c2:	00015517          	auipc	a0,0x15
    800043c6:	9ae50513          	addi	a0,a0,-1618 # 80018d70 <tickslock>
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	81a080e7          	jalr	-2022(ra) # 80000be4 <acquire>
  xticks = ticks;
    800043d2:	00006497          	auipc	s1,0x6
    800043d6:	c824a483          	lw	s1,-894(s1) # 8000a054 <ticks>
  release(&tickslock);
    800043da:	00015517          	auipc	a0,0x15
    800043de:	99650513          	addi	a0,a0,-1642 # 80018d70 <tickslock>
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	8b6080e7          	jalr	-1866(ra) # 80000c98 <release>
  return xticks;
}
    800043ea:	02049513          	slli	a0,s1,0x20
    800043ee:	9101                	srli	a0,a0,0x20
    800043f0:	60e2                	ld	ra,24(sp)
    800043f2:	6442                	ld	s0,16(sp)
    800043f4:	64a2                	ld	s1,8(sp)
    800043f6:	6105                	addi	sp,sp,32
    800043f8:	8082                	ret

00000000800043fa <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800043fa:	1141                	addi	sp,sp,-16
    800043fc:	e406                	sd	ra,8(sp)
    800043fe:	e022                	sd	s0,0(sp)
    80004400:	0800                	addi	s0,sp,16
  return print_stats();
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	320080e7          	jalr	800(ra) # 80003722 <print_stats>
}
    8000440a:	60a2                	ld	ra,8(sp)
    8000440c:	6402                	ld	s0,0(sp)
    8000440e:	0141                	addi	sp,sp,16
    80004410:	8082                	ret

0000000080004412 <sys_get_cpu>:

// Ass2
uint64
sys_get_cpu(void)
{
    80004412:	1141                	addi	sp,sp,-16
    80004414:	e406                	sd	ra,8(sp)
    80004416:	e022                	sd	s0,0(sp)
    80004418:	0800                	addi	s0,sp,16
  return get_cpu();
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	46a080e7          	jalr	1130(ra) # 80003884 <get_cpu>
}
    80004422:	60a2                	ld	ra,8(sp)
    80004424:	6402                	ld	s0,0(sp)
    80004426:	0141                	addi	sp,sp,16
    80004428:	8082                	ret

000000008000442a <sys_set_cpu>:

// Ass2
uint64
sys_set_cpu(void)
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	1000                	addi	s0,sp,32
  int cpu_num;
  if(argint(0, &cpu_num) < 0)
    80004432:	fec40593          	addi	a1,s0,-20
    80004436:	4501                	li	a0,0
    80004438:	00000097          	auipc	ra,0x0
    8000443c:	ce0080e7          	jalr	-800(ra) # 80004118 <argint>
    80004440:	87aa                	mv	a5,a0
    return -1;
    80004442:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80004444:	0007c863          	bltz	a5,80004454 <sys_set_cpu+0x2a>

  return set_cpu(cpu_num);
    80004448:	fec42503          	lw	a0,-20(s0)
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	378080e7          	jalr	888(ra) # 800037c4 <set_cpu>
}
    80004454:	60e2                	ld	ra,24(sp)
    80004456:	6442                	ld	s0,16(sp)
    80004458:	6105                	addi	sp,sp,32
    8000445a:	8082                	ret

000000008000445c <sys_pause_system>:



uint64
sys_pause_system(void)
{
    8000445c:	1101                	addi	sp,sp,-32
    8000445e:	ec06                	sd	ra,24(sp)
    80004460:	e822                	sd	s0,16(sp)
    80004462:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80004464:	fec40593          	addi	a1,s0,-20
    80004468:	4501                	li	a0,0
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	cae080e7          	jalr	-850(ra) # 80004118 <argint>
    80004472:	87aa                	mv	a5,a0
    return -1;
    80004474:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80004476:	0007c863          	bltz	a5,80004486 <sys_pause_system+0x2a>

  return pause_system(seconds);
    8000447a:	fec42503          	lw	a0,-20(s0)
    8000447e:	fffff097          	auipc	ra,0xfffff
    80004482:	416080e7          	jalr	1046(ra) # 80003894 <pause_system>
}
    80004486:	60e2                	ld	ra,24(sp)
    80004488:	6442                	ld	s0,16(sp)
    8000448a:	6105                	addi	sp,sp,32
    8000448c:	8082                	ret

000000008000448e <sys_kill_system>:


uint64
sys_kill_system(void)
{
    8000448e:	1141                	addi	sp,sp,-16
    80004490:	e406                	sd	ra,8(sp)
    80004492:	e022                	sd	s0,0(sp)
    80004494:	0800                	addi	s0,sp,16
  return kill_system(); 
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	55e080e7          	jalr	1374(ra) # 800039f4 <kill_system>
}
    8000449e:	60a2                	ld	ra,8(sp)
    800044a0:	6402                	ld	s0,0(sp)
    800044a2:	0141                	addi	sp,sp,16
    800044a4:	8082                	ret

00000000800044a6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800044a6:	7179                	addi	sp,sp,-48
    800044a8:	f406                	sd	ra,40(sp)
    800044aa:	f022                	sd	s0,32(sp)
    800044ac:	ec26                	sd	s1,24(sp)
    800044ae:	e84a                	sd	s2,16(sp)
    800044b0:	e44e                	sd	s3,8(sp)
    800044b2:	e052                	sd	s4,0(sp)
    800044b4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800044b6:	00005597          	auipc	a1,0x5
    800044ba:	44a58593          	addi	a1,a1,1098 # 80009900 <syscalls+0xd8>
    800044be:	00015517          	auipc	a0,0x15
    800044c2:	8ca50513          	addi	a0,a0,-1846 # 80018d88 <bcache>
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	68e080e7          	jalr	1678(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800044ce:	0001d797          	auipc	a5,0x1d
    800044d2:	8ba78793          	addi	a5,a5,-1862 # 80020d88 <bcache+0x8000>
    800044d6:	0001d717          	auipc	a4,0x1d
    800044da:	b1a70713          	addi	a4,a4,-1254 # 80020ff0 <bcache+0x8268>
    800044de:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800044e2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800044e6:	00015497          	auipc	s1,0x15
    800044ea:	8ba48493          	addi	s1,s1,-1862 # 80018da0 <bcache+0x18>
    b->next = bcache.head.next;
    800044ee:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800044f0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800044f2:	00005a17          	auipc	s4,0x5
    800044f6:	416a0a13          	addi	s4,s4,1046 # 80009908 <syscalls+0xe0>
    b->next = bcache.head.next;
    800044fa:	2b893783          	ld	a5,696(s2)
    800044fe:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80004500:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80004504:	85d2                	mv	a1,s4
    80004506:	01048513          	addi	a0,s1,16
    8000450a:	00001097          	auipc	ra,0x1
    8000450e:	4bc080e7          	jalr	1212(ra) # 800059c6 <initsleeplock>
    bcache.head.next->prev = b;
    80004512:	2b893783          	ld	a5,696(s2)
    80004516:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80004518:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000451c:	45848493          	addi	s1,s1,1112
    80004520:	fd349de3          	bne	s1,s3,800044fa <binit+0x54>
  }
}
    80004524:	70a2                	ld	ra,40(sp)
    80004526:	7402                	ld	s0,32(sp)
    80004528:	64e2                	ld	s1,24(sp)
    8000452a:	6942                	ld	s2,16(sp)
    8000452c:	69a2                	ld	s3,8(sp)
    8000452e:	6a02                	ld	s4,0(sp)
    80004530:	6145                	addi	sp,sp,48
    80004532:	8082                	ret

0000000080004534 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80004534:	7179                	addi	sp,sp,-48
    80004536:	f406                	sd	ra,40(sp)
    80004538:	f022                	sd	s0,32(sp)
    8000453a:	ec26                	sd	s1,24(sp)
    8000453c:	e84a                	sd	s2,16(sp)
    8000453e:	e44e                	sd	s3,8(sp)
    80004540:	1800                	addi	s0,sp,48
    80004542:	89aa                	mv	s3,a0
    80004544:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80004546:	00015517          	auipc	a0,0x15
    8000454a:	84250513          	addi	a0,a0,-1982 # 80018d88 <bcache>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	696080e7          	jalr	1686(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80004556:	0001d497          	auipc	s1,0x1d
    8000455a:	aea4b483          	ld	s1,-1302(s1) # 80021040 <bcache+0x82b8>
    8000455e:	0001d797          	auipc	a5,0x1d
    80004562:	a9278793          	addi	a5,a5,-1390 # 80020ff0 <bcache+0x8268>
    80004566:	02f48f63          	beq	s1,a5,800045a4 <bread+0x70>
    8000456a:	873e                	mv	a4,a5
    8000456c:	a021                	j	80004574 <bread+0x40>
    8000456e:	68a4                	ld	s1,80(s1)
    80004570:	02e48a63          	beq	s1,a4,800045a4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80004574:	449c                	lw	a5,8(s1)
    80004576:	ff379ce3          	bne	a5,s3,8000456e <bread+0x3a>
    8000457a:	44dc                	lw	a5,12(s1)
    8000457c:	ff2799e3          	bne	a5,s2,8000456e <bread+0x3a>
      b->refcnt++;
    80004580:	40bc                	lw	a5,64(s1)
    80004582:	2785                	addiw	a5,a5,1
    80004584:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80004586:	00015517          	auipc	a0,0x15
    8000458a:	80250513          	addi	a0,a0,-2046 # 80018d88 <bcache>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80004596:	01048513          	addi	a0,s1,16
    8000459a:	00001097          	auipc	ra,0x1
    8000459e:	466080e7          	jalr	1126(ra) # 80005a00 <acquiresleep>
      return b;
    800045a2:	a8b9                	j	80004600 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800045a4:	0001d497          	auipc	s1,0x1d
    800045a8:	a944b483          	ld	s1,-1388(s1) # 80021038 <bcache+0x82b0>
    800045ac:	0001d797          	auipc	a5,0x1d
    800045b0:	a4478793          	addi	a5,a5,-1468 # 80020ff0 <bcache+0x8268>
    800045b4:	00f48863          	beq	s1,a5,800045c4 <bread+0x90>
    800045b8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800045ba:	40bc                	lw	a5,64(s1)
    800045bc:	cf81                	beqz	a5,800045d4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800045be:	64a4                	ld	s1,72(s1)
    800045c0:	fee49de3          	bne	s1,a4,800045ba <bread+0x86>
  panic("bget: no buffers");
    800045c4:	00005517          	auipc	a0,0x5
    800045c8:	34c50513          	addi	a0,a0,844 # 80009910 <syscalls+0xe8>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	f72080e7          	jalr	-142(ra) # 8000053e <panic>
      b->dev = dev;
    800045d4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800045d8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800045dc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800045e0:	4785                	li	a5,1
    800045e2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800045e4:	00014517          	auipc	a0,0x14
    800045e8:	7a450513          	addi	a0,a0,1956 # 80018d88 <bcache>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	6ac080e7          	jalr	1708(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800045f4:	01048513          	addi	a0,s1,16
    800045f8:	00001097          	auipc	ra,0x1
    800045fc:	408080e7          	jalr	1032(ra) # 80005a00 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80004600:	409c                	lw	a5,0(s1)
    80004602:	cb89                	beqz	a5,80004614 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80004604:	8526                	mv	a0,s1
    80004606:	70a2                	ld	ra,40(sp)
    80004608:	7402                	ld	s0,32(sp)
    8000460a:	64e2                	ld	s1,24(sp)
    8000460c:	6942                	ld	s2,16(sp)
    8000460e:	69a2                	ld	s3,8(sp)
    80004610:	6145                	addi	sp,sp,48
    80004612:	8082                	ret
    virtio_disk_rw(b, 0);
    80004614:	4581                	li	a1,0
    80004616:	8526                	mv	a0,s1
    80004618:	00003097          	auipc	ra,0x3
    8000461c:	f0e080e7          	jalr	-242(ra) # 80007526 <virtio_disk_rw>
    b->valid = 1;
    80004620:	4785                	li	a5,1
    80004622:	c09c                	sw	a5,0(s1)
  return b;
    80004624:	b7c5                	j	80004604 <bread+0xd0>

0000000080004626 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80004626:	1101                	addi	sp,sp,-32
    80004628:	ec06                	sd	ra,24(sp)
    8000462a:	e822                	sd	s0,16(sp)
    8000462c:	e426                	sd	s1,8(sp)
    8000462e:	1000                	addi	s0,sp,32
    80004630:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004632:	0541                	addi	a0,a0,16
    80004634:	00001097          	auipc	ra,0x1
    80004638:	466080e7          	jalr	1126(ra) # 80005a9a <holdingsleep>
    8000463c:	cd01                	beqz	a0,80004654 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000463e:	4585                	li	a1,1
    80004640:	8526                	mv	a0,s1
    80004642:	00003097          	auipc	ra,0x3
    80004646:	ee4080e7          	jalr	-284(ra) # 80007526 <virtio_disk_rw>
}
    8000464a:	60e2                	ld	ra,24(sp)
    8000464c:	6442                	ld	s0,16(sp)
    8000464e:	64a2                	ld	s1,8(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret
    panic("bwrite");
    80004654:	00005517          	auipc	a0,0x5
    80004658:	2d450513          	addi	a0,a0,724 # 80009928 <syscalls+0x100>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>

0000000080004664 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80004664:	1101                	addi	sp,sp,-32
    80004666:	ec06                	sd	ra,24(sp)
    80004668:	e822                	sd	s0,16(sp)
    8000466a:	e426                	sd	s1,8(sp)
    8000466c:	e04a                	sd	s2,0(sp)
    8000466e:	1000                	addi	s0,sp,32
    80004670:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004672:	01050913          	addi	s2,a0,16
    80004676:	854a                	mv	a0,s2
    80004678:	00001097          	auipc	ra,0x1
    8000467c:	422080e7          	jalr	1058(ra) # 80005a9a <holdingsleep>
    80004680:	c92d                	beqz	a0,800046f2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80004682:	854a                	mv	a0,s2
    80004684:	00001097          	auipc	ra,0x1
    80004688:	3d2080e7          	jalr	978(ra) # 80005a56 <releasesleep>

  acquire(&bcache.lock);
    8000468c:	00014517          	auipc	a0,0x14
    80004690:	6fc50513          	addi	a0,a0,1788 # 80018d88 <bcache>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	550080e7          	jalr	1360(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000469c:	40bc                	lw	a5,64(s1)
    8000469e:	37fd                	addiw	a5,a5,-1
    800046a0:	0007871b          	sext.w	a4,a5
    800046a4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800046a6:	eb05                	bnez	a4,800046d6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800046a8:	68bc                	ld	a5,80(s1)
    800046aa:	64b8                	ld	a4,72(s1)
    800046ac:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800046ae:	64bc                	ld	a5,72(s1)
    800046b0:	68b8                	ld	a4,80(s1)
    800046b2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800046b4:	0001c797          	auipc	a5,0x1c
    800046b8:	6d478793          	addi	a5,a5,1748 # 80020d88 <bcache+0x8000>
    800046bc:	2b87b703          	ld	a4,696(a5)
    800046c0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800046c2:	0001d717          	auipc	a4,0x1d
    800046c6:	92e70713          	addi	a4,a4,-1746 # 80020ff0 <bcache+0x8268>
    800046ca:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800046cc:	2b87b703          	ld	a4,696(a5)
    800046d0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800046d2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800046d6:	00014517          	auipc	a0,0x14
    800046da:	6b250513          	addi	a0,a0,1714 # 80018d88 <bcache>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5ba080e7          	jalr	1466(ra) # 80000c98 <release>
}
    800046e6:	60e2                	ld	ra,24(sp)
    800046e8:	6442                	ld	s0,16(sp)
    800046ea:	64a2                	ld	s1,8(sp)
    800046ec:	6902                	ld	s2,0(sp)
    800046ee:	6105                	addi	sp,sp,32
    800046f0:	8082                	ret
    panic("brelse");
    800046f2:	00005517          	auipc	a0,0x5
    800046f6:	23e50513          	addi	a0,a0,574 # 80009930 <syscalls+0x108>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	e44080e7          	jalr	-444(ra) # 8000053e <panic>

0000000080004702 <bpin>:

void
bpin(struct buf *b) {
    80004702:	1101                	addi	sp,sp,-32
    80004704:	ec06                	sd	ra,24(sp)
    80004706:	e822                	sd	s0,16(sp)
    80004708:	e426                	sd	s1,8(sp)
    8000470a:	1000                	addi	s0,sp,32
    8000470c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000470e:	00014517          	auipc	a0,0x14
    80004712:	67a50513          	addi	a0,a0,1658 # 80018d88 <bcache>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	4ce080e7          	jalr	1230(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000471e:	40bc                	lw	a5,64(s1)
    80004720:	2785                	addiw	a5,a5,1
    80004722:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004724:	00014517          	auipc	a0,0x14
    80004728:	66450513          	addi	a0,a0,1636 # 80018d88 <bcache>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	56c080e7          	jalr	1388(ra) # 80000c98 <release>
}
    80004734:	60e2                	ld	ra,24(sp)
    80004736:	6442                	ld	s0,16(sp)
    80004738:	64a2                	ld	s1,8(sp)
    8000473a:	6105                	addi	sp,sp,32
    8000473c:	8082                	ret

000000008000473e <bunpin>:

void
bunpin(struct buf *b) {
    8000473e:	1101                	addi	sp,sp,-32
    80004740:	ec06                	sd	ra,24(sp)
    80004742:	e822                	sd	s0,16(sp)
    80004744:	e426                	sd	s1,8(sp)
    80004746:	1000                	addi	s0,sp,32
    80004748:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000474a:	00014517          	auipc	a0,0x14
    8000474e:	63e50513          	addi	a0,a0,1598 # 80018d88 <bcache>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	492080e7          	jalr	1170(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000475a:	40bc                	lw	a5,64(s1)
    8000475c:	37fd                	addiw	a5,a5,-1
    8000475e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004760:	00014517          	auipc	a0,0x14
    80004764:	62850513          	addi	a0,a0,1576 # 80018d88 <bcache>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	530080e7          	jalr	1328(ra) # 80000c98 <release>
}
    80004770:	60e2                	ld	ra,24(sp)
    80004772:	6442                	ld	s0,16(sp)
    80004774:	64a2                	ld	s1,8(sp)
    80004776:	6105                	addi	sp,sp,32
    80004778:	8082                	ret

000000008000477a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000477a:	1101                	addi	sp,sp,-32
    8000477c:	ec06                	sd	ra,24(sp)
    8000477e:	e822                	sd	s0,16(sp)
    80004780:	e426                	sd	s1,8(sp)
    80004782:	e04a                	sd	s2,0(sp)
    80004784:	1000                	addi	s0,sp,32
    80004786:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80004788:	00d5d59b          	srliw	a1,a1,0xd
    8000478c:	0001d797          	auipc	a5,0x1d
    80004790:	cd87a783          	lw	a5,-808(a5) # 80021464 <sb+0x1c>
    80004794:	9dbd                	addw	a1,a1,a5
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	d9e080e7          	jalr	-610(ra) # 80004534 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000479e:	0074f713          	andi	a4,s1,7
    800047a2:	4785                	li	a5,1
    800047a4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800047a8:	14ce                	slli	s1,s1,0x33
    800047aa:	90d9                	srli	s1,s1,0x36
    800047ac:	00950733          	add	a4,a0,s1
    800047b0:	05874703          	lbu	a4,88(a4)
    800047b4:	00e7f6b3          	and	a3,a5,a4
    800047b8:	c69d                	beqz	a3,800047e6 <bfree+0x6c>
    800047ba:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800047bc:	94aa                	add	s1,s1,a0
    800047be:	fff7c793          	not	a5,a5
    800047c2:	8ff9                	and	a5,a5,a4
    800047c4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800047c8:	00001097          	auipc	ra,0x1
    800047cc:	118080e7          	jalr	280(ra) # 800058e0 <log_write>
  brelse(bp);
    800047d0:	854a                	mv	a0,s2
    800047d2:	00000097          	auipc	ra,0x0
    800047d6:	e92080e7          	jalr	-366(ra) # 80004664 <brelse>
}
    800047da:	60e2                	ld	ra,24(sp)
    800047dc:	6442                	ld	s0,16(sp)
    800047de:	64a2                	ld	s1,8(sp)
    800047e0:	6902                	ld	s2,0(sp)
    800047e2:	6105                	addi	sp,sp,32
    800047e4:	8082                	ret
    panic("freeing free block");
    800047e6:	00005517          	auipc	a0,0x5
    800047ea:	15250513          	addi	a0,a0,338 # 80009938 <syscalls+0x110>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>

00000000800047f6 <balloc>:
{
    800047f6:	711d                	addi	sp,sp,-96
    800047f8:	ec86                	sd	ra,88(sp)
    800047fa:	e8a2                	sd	s0,80(sp)
    800047fc:	e4a6                	sd	s1,72(sp)
    800047fe:	e0ca                	sd	s2,64(sp)
    80004800:	fc4e                	sd	s3,56(sp)
    80004802:	f852                	sd	s4,48(sp)
    80004804:	f456                	sd	s5,40(sp)
    80004806:	f05a                	sd	s6,32(sp)
    80004808:	ec5e                	sd	s7,24(sp)
    8000480a:	e862                	sd	s8,16(sp)
    8000480c:	e466                	sd	s9,8(sp)
    8000480e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80004810:	0001d797          	auipc	a5,0x1d
    80004814:	c3c7a783          	lw	a5,-964(a5) # 8002144c <sb+0x4>
    80004818:	cbd1                	beqz	a5,800048ac <balloc+0xb6>
    8000481a:	8baa                	mv	s7,a0
    8000481c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000481e:	0001db17          	auipc	s6,0x1d
    80004822:	c2ab0b13          	addi	s6,s6,-982 # 80021448 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004826:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80004828:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000482a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000482c:	6c89                	lui	s9,0x2
    8000482e:	a831                	j	8000484a <balloc+0x54>
    brelse(bp);
    80004830:	854a                	mv	a0,s2
    80004832:	00000097          	auipc	ra,0x0
    80004836:	e32080e7          	jalr	-462(ra) # 80004664 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000483a:	015c87bb          	addw	a5,s9,s5
    8000483e:	00078a9b          	sext.w	s5,a5
    80004842:	004b2703          	lw	a4,4(s6)
    80004846:	06eaf363          	bgeu	s5,a4,800048ac <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000484a:	41fad79b          	sraiw	a5,s5,0x1f
    8000484e:	0137d79b          	srliw	a5,a5,0x13
    80004852:	015787bb          	addw	a5,a5,s5
    80004856:	40d7d79b          	sraiw	a5,a5,0xd
    8000485a:	01cb2583          	lw	a1,28(s6)
    8000485e:	9dbd                	addw	a1,a1,a5
    80004860:	855e                	mv	a0,s7
    80004862:	00000097          	auipc	ra,0x0
    80004866:	cd2080e7          	jalr	-814(ra) # 80004534 <bread>
    8000486a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000486c:	004b2503          	lw	a0,4(s6)
    80004870:	000a849b          	sext.w	s1,s5
    80004874:	8662                	mv	a2,s8
    80004876:	faa4fde3          	bgeu	s1,a0,80004830 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000487a:	41f6579b          	sraiw	a5,a2,0x1f
    8000487e:	01d7d69b          	srliw	a3,a5,0x1d
    80004882:	00c6873b          	addw	a4,a3,a2
    80004886:	00777793          	andi	a5,a4,7
    8000488a:	9f95                	subw	a5,a5,a3
    8000488c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004890:	4037571b          	sraiw	a4,a4,0x3
    80004894:	00e906b3          	add	a3,s2,a4
    80004898:	0586c683          	lbu	a3,88(a3)
    8000489c:	00d7f5b3          	and	a1,a5,a3
    800048a0:	cd91                	beqz	a1,800048bc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800048a2:	2605                	addiw	a2,a2,1
    800048a4:	2485                	addiw	s1,s1,1
    800048a6:	fd4618e3          	bne	a2,s4,80004876 <balloc+0x80>
    800048aa:	b759                	j	80004830 <balloc+0x3a>
  panic("balloc: out of blocks");
    800048ac:	00005517          	auipc	a0,0x5
    800048b0:	0a450513          	addi	a0,a0,164 # 80009950 <syscalls+0x128>
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	c8a080e7          	jalr	-886(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800048bc:	974a                	add	a4,a4,s2
    800048be:	8fd5                	or	a5,a5,a3
    800048c0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800048c4:	854a                	mv	a0,s2
    800048c6:	00001097          	auipc	ra,0x1
    800048ca:	01a080e7          	jalr	26(ra) # 800058e0 <log_write>
        brelse(bp);
    800048ce:	854a                	mv	a0,s2
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	d94080e7          	jalr	-620(ra) # 80004664 <brelse>
  bp = bread(dev, bno);
    800048d8:	85a6                	mv	a1,s1
    800048da:	855e                	mv	a0,s7
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	c58080e7          	jalr	-936(ra) # 80004534 <bread>
    800048e4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800048e6:	40000613          	li	a2,1024
    800048ea:	4581                	li	a1,0
    800048ec:	05850513          	addi	a0,a0,88
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	3f0080e7          	jalr	1008(ra) # 80000ce0 <memset>
  log_write(bp);
    800048f8:	854a                	mv	a0,s2
    800048fa:	00001097          	auipc	ra,0x1
    800048fe:	fe6080e7          	jalr	-26(ra) # 800058e0 <log_write>
  brelse(bp);
    80004902:	854a                	mv	a0,s2
    80004904:	00000097          	auipc	ra,0x0
    80004908:	d60080e7          	jalr	-672(ra) # 80004664 <brelse>
}
    8000490c:	8526                	mv	a0,s1
    8000490e:	60e6                	ld	ra,88(sp)
    80004910:	6446                	ld	s0,80(sp)
    80004912:	64a6                	ld	s1,72(sp)
    80004914:	6906                	ld	s2,64(sp)
    80004916:	79e2                	ld	s3,56(sp)
    80004918:	7a42                	ld	s4,48(sp)
    8000491a:	7aa2                	ld	s5,40(sp)
    8000491c:	7b02                	ld	s6,32(sp)
    8000491e:	6be2                	ld	s7,24(sp)
    80004920:	6c42                	ld	s8,16(sp)
    80004922:	6ca2                	ld	s9,8(sp)
    80004924:	6125                	addi	sp,sp,96
    80004926:	8082                	ret

0000000080004928 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80004928:	7179                	addi	sp,sp,-48
    8000492a:	f406                	sd	ra,40(sp)
    8000492c:	f022                	sd	s0,32(sp)
    8000492e:	ec26                	sd	s1,24(sp)
    80004930:	e84a                	sd	s2,16(sp)
    80004932:	e44e                	sd	s3,8(sp)
    80004934:	e052                	sd	s4,0(sp)
    80004936:	1800                	addi	s0,sp,48
    80004938:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000493a:	47ad                	li	a5,11
    8000493c:	04b7fe63          	bgeu	a5,a1,80004998 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80004940:	ff45849b          	addiw	s1,a1,-12
    80004944:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80004948:	0ff00793          	li	a5,255
    8000494c:	0ae7e363          	bltu	a5,a4,800049f2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80004950:	08052583          	lw	a1,128(a0)
    80004954:	c5ad                	beqz	a1,800049be <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80004956:	00092503          	lw	a0,0(s2)
    8000495a:	00000097          	auipc	ra,0x0
    8000495e:	bda080e7          	jalr	-1062(ra) # 80004534 <bread>
    80004962:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004964:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80004968:	02049593          	slli	a1,s1,0x20
    8000496c:	9181                	srli	a1,a1,0x20
    8000496e:	058a                	slli	a1,a1,0x2
    80004970:	00b784b3          	add	s1,a5,a1
    80004974:	0004a983          	lw	s3,0(s1)
    80004978:	04098d63          	beqz	s3,800049d2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000497c:	8552                	mv	a0,s4
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	ce6080e7          	jalr	-794(ra) # 80004664 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004986:	854e                	mv	a0,s3
    80004988:	70a2                	ld	ra,40(sp)
    8000498a:	7402                	ld	s0,32(sp)
    8000498c:	64e2                	ld	s1,24(sp)
    8000498e:	6942                	ld	s2,16(sp)
    80004990:	69a2                	ld	s3,8(sp)
    80004992:	6a02                	ld	s4,0(sp)
    80004994:	6145                	addi	sp,sp,48
    80004996:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80004998:	02059493          	slli	s1,a1,0x20
    8000499c:	9081                	srli	s1,s1,0x20
    8000499e:	048a                	slli	s1,s1,0x2
    800049a0:	94aa                	add	s1,s1,a0
    800049a2:	0504a983          	lw	s3,80(s1)
    800049a6:	fe0990e3          	bnez	s3,80004986 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800049aa:	4108                	lw	a0,0(a0)
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	e4a080e7          	jalr	-438(ra) # 800047f6 <balloc>
    800049b4:	0005099b          	sext.w	s3,a0
    800049b8:	0534a823          	sw	s3,80(s1)
    800049bc:	b7e9                	j	80004986 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800049be:	4108                	lw	a0,0(a0)
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	e36080e7          	jalr	-458(ra) # 800047f6 <balloc>
    800049c8:	0005059b          	sext.w	a1,a0
    800049cc:	08b92023          	sw	a1,128(s2)
    800049d0:	b759                	j	80004956 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800049d2:	00092503          	lw	a0,0(s2)
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	e20080e7          	jalr	-480(ra) # 800047f6 <balloc>
    800049de:	0005099b          	sext.w	s3,a0
    800049e2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800049e6:	8552                	mv	a0,s4
    800049e8:	00001097          	auipc	ra,0x1
    800049ec:	ef8080e7          	jalr	-264(ra) # 800058e0 <log_write>
    800049f0:	b771                	j	8000497c <bmap+0x54>
  panic("bmap: out of range");
    800049f2:	00005517          	auipc	a0,0x5
    800049f6:	f7650513          	addi	a0,a0,-138 # 80009968 <syscalls+0x140>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	b44080e7          	jalr	-1212(ra) # 8000053e <panic>

0000000080004a02 <iget>:
{
    80004a02:	7179                	addi	sp,sp,-48
    80004a04:	f406                	sd	ra,40(sp)
    80004a06:	f022                	sd	s0,32(sp)
    80004a08:	ec26                	sd	s1,24(sp)
    80004a0a:	e84a                	sd	s2,16(sp)
    80004a0c:	e44e                	sd	s3,8(sp)
    80004a0e:	e052                	sd	s4,0(sp)
    80004a10:	1800                	addi	s0,sp,48
    80004a12:	89aa                	mv	s3,a0
    80004a14:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004a16:	0001d517          	auipc	a0,0x1d
    80004a1a:	a5250513          	addi	a0,a0,-1454 # 80021468 <itable>
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1c6080e7          	jalr	454(ra) # 80000be4 <acquire>
  empty = 0;
    80004a26:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004a28:	0001d497          	auipc	s1,0x1d
    80004a2c:	a5848493          	addi	s1,s1,-1448 # 80021480 <itable+0x18>
    80004a30:	0001e697          	auipc	a3,0x1e
    80004a34:	4e068693          	addi	a3,a3,1248 # 80022f10 <log>
    80004a38:	a039                	j	80004a46 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004a3a:	02090b63          	beqz	s2,80004a70 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004a3e:	08848493          	addi	s1,s1,136
    80004a42:	02d48a63          	beq	s1,a3,80004a76 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004a46:	449c                	lw	a5,8(s1)
    80004a48:	fef059e3          	blez	a5,80004a3a <iget+0x38>
    80004a4c:	4098                	lw	a4,0(s1)
    80004a4e:	ff3716e3          	bne	a4,s3,80004a3a <iget+0x38>
    80004a52:	40d8                	lw	a4,4(s1)
    80004a54:	ff4713e3          	bne	a4,s4,80004a3a <iget+0x38>
      ip->ref++;
    80004a58:	2785                	addiw	a5,a5,1
    80004a5a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004a5c:	0001d517          	auipc	a0,0x1d
    80004a60:	a0c50513          	addi	a0,a0,-1524 # 80021468 <itable>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
      return ip;
    80004a6c:	8926                	mv	s2,s1
    80004a6e:	a03d                	j	80004a9c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004a70:	f7f9                	bnez	a5,80004a3e <iget+0x3c>
    80004a72:	8926                	mv	s2,s1
    80004a74:	b7e9                	j	80004a3e <iget+0x3c>
  if(empty == 0)
    80004a76:	02090c63          	beqz	s2,80004aae <iget+0xac>
  ip->dev = dev;
    80004a7a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004a7e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004a82:	4785                	li	a5,1
    80004a84:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004a88:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004a8c:	0001d517          	auipc	a0,0x1d
    80004a90:	9dc50513          	addi	a0,a0,-1572 # 80021468 <itable>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	204080e7          	jalr	516(ra) # 80000c98 <release>
}
    80004a9c:	854a                	mv	a0,s2
    80004a9e:	70a2                	ld	ra,40(sp)
    80004aa0:	7402                	ld	s0,32(sp)
    80004aa2:	64e2                	ld	s1,24(sp)
    80004aa4:	6942                	ld	s2,16(sp)
    80004aa6:	69a2                	ld	s3,8(sp)
    80004aa8:	6a02                	ld	s4,0(sp)
    80004aaa:	6145                	addi	sp,sp,48
    80004aac:	8082                	ret
    panic("iget: no inodes");
    80004aae:	00005517          	auipc	a0,0x5
    80004ab2:	ed250513          	addi	a0,a0,-302 # 80009980 <syscalls+0x158>
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	a88080e7          	jalr	-1400(ra) # 8000053e <panic>

0000000080004abe <fsinit>:
fsinit(int dev) {
    80004abe:	7179                	addi	sp,sp,-48
    80004ac0:	f406                	sd	ra,40(sp)
    80004ac2:	f022                	sd	s0,32(sp)
    80004ac4:	ec26                	sd	s1,24(sp)
    80004ac6:	e84a                	sd	s2,16(sp)
    80004ac8:	e44e                	sd	s3,8(sp)
    80004aca:	1800                	addi	s0,sp,48
    80004acc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004ace:	4585                	li	a1,1
    80004ad0:	00000097          	auipc	ra,0x0
    80004ad4:	a64080e7          	jalr	-1436(ra) # 80004534 <bread>
    80004ad8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004ada:	0001d997          	auipc	s3,0x1d
    80004ade:	96e98993          	addi	s3,s3,-1682 # 80021448 <sb>
    80004ae2:	02000613          	li	a2,32
    80004ae6:	05850593          	addi	a1,a0,88
    80004aea:	854e                	mv	a0,s3
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	254080e7          	jalr	596(ra) # 80000d40 <memmove>
  brelse(bp);
    80004af4:	8526                	mv	a0,s1
    80004af6:	00000097          	auipc	ra,0x0
    80004afa:	b6e080e7          	jalr	-1170(ra) # 80004664 <brelse>
  if(sb.magic != FSMAGIC)
    80004afe:	0009a703          	lw	a4,0(s3)
    80004b02:	102037b7          	lui	a5,0x10203
    80004b06:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004b0a:	02f71263          	bne	a4,a5,80004b2e <fsinit+0x70>
  initlog(dev, &sb);
    80004b0e:	0001d597          	auipc	a1,0x1d
    80004b12:	93a58593          	addi	a1,a1,-1734 # 80021448 <sb>
    80004b16:	854a                	mv	a0,s2
    80004b18:	00001097          	auipc	ra,0x1
    80004b1c:	b4c080e7          	jalr	-1204(ra) # 80005664 <initlog>
}
    80004b20:	70a2                	ld	ra,40(sp)
    80004b22:	7402                	ld	s0,32(sp)
    80004b24:	64e2                	ld	s1,24(sp)
    80004b26:	6942                	ld	s2,16(sp)
    80004b28:	69a2                	ld	s3,8(sp)
    80004b2a:	6145                	addi	sp,sp,48
    80004b2c:	8082                	ret
    panic("invalid file system");
    80004b2e:	00005517          	auipc	a0,0x5
    80004b32:	e6250513          	addi	a0,a0,-414 # 80009990 <syscalls+0x168>
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	a08080e7          	jalr	-1528(ra) # 8000053e <panic>

0000000080004b3e <iinit>:
{
    80004b3e:	7179                	addi	sp,sp,-48
    80004b40:	f406                	sd	ra,40(sp)
    80004b42:	f022                	sd	s0,32(sp)
    80004b44:	ec26                	sd	s1,24(sp)
    80004b46:	e84a                	sd	s2,16(sp)
    80004b48:	e44e                	sd	s3,8(sp)
    80004b4a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004b4c:	00005597          	auipc	a1,0x5
    80004b50:	e5c58593          	addi	a1,a1,-420 # 800099a8 <syscalls+0x180>
    80004b54:	0001d517          	auipc	a0,0x1d
    80004b58:	91450513          	addi	a0,a0,-1772 # 80021468 <itable>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	ff8080e7          	jalr	-8(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004b64:	0001d497          	auipc	s1,0x1d
    80004b68:	92c48493          	addi	s1,s1,-1748 # 80021490 <itable+0x28>
    80004b6c:	0001e997          	auipc	s3,0x1e
    80004b70:	3b498993          	addi	s3,s3,948 # 80022f20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004b74:	00005917          	auipc	s2,0x5
    80004b78:	e3c90913          	addi	s2,s2,-452 # 800099b0 <syscalls+0x188>
    80004b7c:	85ca                	mv	a1,s2
    80004b7e:	8526                	mv	a0,s1
    80004b80:	00001097          	auipc	ra,0x1
    80004b84:	e46080e7          	jalr	-442(ra) # 800059c6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004b88:	08848493          	addi	s1,s1,136
    80004b8c:	ff3498e3          	bne	s1,s3,80004b7c <iinit+0x3e>
}
    80004b90:	70a2                	ld	ra,40(sp)
    80004b92:	7402                	ld	s0,32(sp)
    80004b94:	64e2                	ld	s1,24(sp)
    80004b96:	6942                	ld	s2,16(sp)
    80004b98:	69a2                	ld	s3,8(sp)
    80004b9a:	6145                	addi	sp,sp,48
    80004b9c:	8082                	ret

0000000080004b9e <ialloc>:
{
    80004b9e:	715d                	addi	sp,sp,-80
    80004ba0:	e486                	sd	ra,72(sp)
    80004ba2:	e0a2                	sd	s0,64(sp)
    80004ba4:	fc26                	sd	s1,56(sp)
    80004ba6:	f84a                	sd	s2,48(sp)
    80004ba8:	f44e                	sd	s3,40(sp)
    80004baa:	f052                	sd	s4,32(sp)
    80004bac:	ec56                	sd	s5,24(sp)
    80004bae:	e85a                	sd	s6,16(sp)
    80004bb0:	e45e                	sd	s7,8(sp)
    80004bb2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004bb4:	0001d717          	auipc	a4,0x1d
    80004bb8:	8a072703          	lw	a4,-1888(a4) # 80021454 <sb+0xc>
    80004bbc:	4785                	li	a5,1
    80004bbe:	04e7fa63          	bgeu	a5,a4,80004c12 <ialloc+0x74>
    80004bc2:	8aaa                	mv	s5,a0
    80004bc4:	8bae                	mv	s7,a1
    80004bc6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004bc8:	0001da17          	auipc	s4,0x1d
    80004bcc:	880a0a13          	addi	s4,s4,-1920 # 80021448 <sb>
    80004bd0:	00048b1b          	sext.w	s6,s1
    80004bd4:	0044d593          	srli	a1,s1,0x4
    80004bd8:	018a2783          	lw	a5,24(s4)
    80004bdc:	9dbd                	addw	a1,a1,a5
    80004bde:	8556                	mv	a0,s5
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	954080e7          	jalr	-1708(ra) # 80004534 <bread>
    80004be8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004bea:	05850993          	addi	s3,a0,88
    80004bee:	00f4f793          	andi	a5,s1,15
    80004bf2:	079a                	slli	a5,a5,0x6
    80004bf4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004bf6:	00099783          	lh	a5,0(s3)
    80004bfa:	c785                	beqz	a5,80004c22 <ialloc+0x84>
    brelse(bp);
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	a68080e7          	jalr	-1432(ra) # 80004664 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004c04:	0485                	addi	s1,s1,1
    80004c06:	00ca2703          	lw	a4,12(s4)
    80004c0a:	0004879b          	sext.w	a5,s1
    80004c0e:	fce7e1e3          	bltu	a5,a4,80004bd0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80004c12:	00005517          	auipc	a0,0x5
    80004c16:	da650513          	addi	a0,a0,-602 # 800099b8 <syscalls+0x190>
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	924080e7          	jalr	-1756(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80004c22:	04000613          	li	a2,64
    80004c26:	4581                	li	a1,0
    80004c28:	854e                	mv	a0,s3
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	0b6080e7          	jalr	182(ra) # 80000ce0 <memset>
      dip->type = type;
    80004c32:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004c36:	854a                	mv	a0,s2
    80004c38:	00001097          	auipc	ra,0x1
    80004c3c:	ca8080e7          	jalr	-856(ra) # 800058e0 <log_write>
      brelse(bp);
    80004c40:	854a                	mv	a0,s2
    80004c42:	00000097          	auipc	ra,0x0
    80004c46:	a22080e7          	jalr	-1502(ra) # 80004664 <brelse>
      return iget(dev, inum);
    80004c4a:	85da                	mv	a1,s6
    80004c4c:	8556                	mv	a0,s5
    80004c4e:	00000097          	auipc	ra,0x0
    80004c52:	db4080e7          	jalr	-588(ra) # 80004a02 <iget>
}
    80004c56:	60a6                	ld	ra,72(sp)
    80004c58:	6406                	ld	s0,64(sp)
    80004c5a:	74e2                	ld	s1,56(sp)
    80004c5c:	7942                	ld	s2,48(sp)
    80004c5e:	79a2                	ld	s3,40(sp)
    80004c60:	7a02                	ld	s4,32(sp)
    80004c62:	6ae2                	ld	s5,24(sp)
    80004c64:	6b42                	ld	s6,16(sp)
    80004c66:	6ba2                	ld	s7,8(sp)
    80004c68:	6161                	addi	sp,sp,80
    80004c6a:	8082                	ret

0000000080004c6c <iupdate>:
{
    80004c6c:	1101                	addi	sp,sp,-32
    80004c6e:	ec06                	sd	ra,24(sp)
    80004c70:	e822                	sd	s0,16(sp)
    80004c72:	e426                	sd	s1,8(sp)
    80004c74:	e04a                	sd	s2,0(sp)
    80004c76:	1000                	addi	s0,sp,32
    80004c78:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004c7a:	415c                	lw	a5,4(a0)
    80004c7c:	0047d79b          	srliw	a5,a5,0x4
    80004c80:	0001c597          	auipc	a1,0x1c
    80004c84:	7e05a583          	lw	a1,2016(a1) # 80021460 <sb+0x18>
    80004c88:	9dbd                	addw	a1,a1,a5
    80004c8a:	4108                	lw	a0,0(a0)
    80004c8c:	00000097          	auipc	ra,0x0
    80004c90:	8a8080e7          	jalr	-1880(ra) # 80004534 <bread>
    80004c94:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004c96:	05850793          	addi	a5,a0,88
    80004c9a:	40c8                	lw	a0,4(s1)
    80004c9c:	893d                	andi	a0,a0,15
    80004c9e:	051a                	slli	a0,a0,0x6
    80004ca0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004ca2:	04449703          	lh	a4,68(s1)
    80004ca6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004caa:	04649703          	lh	a4,70(s1)
    80004cae:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004cb2:	04849703          	lh	a4,72(s1)
    80004cb6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004cba:	04a49703          	lh	a4,74(s1)
    80004cbe:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004cc2:	44f8                	lw	a4,76(s1)
    80004cc4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004cc6:	03400613          	li	a2,52
    80004cca:	05048593          	addi	a1,s1,80
    80004cce:	0531                	addi	a0,a0,12
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	070080e7          	jalr	112(ra) # 80000d40 <memmove>
  log_write(bp);
    80004cd8:	854a                	mv	a0,s2
    80004cda:	00001097          	auipc	ra,0x1
    80004cde:	c06080e7          	jalr	-1018(ra) # 800058e0 <log_write>
  brelse(bp);
    80004ce2:	854a                	mv	a0,s2
    80004ce4:	00000097          	auipc	ra,0x0
    80004ce8:	980080e7          	jalr	-1664(ra) # 80004664 <brelse>
}
    80004cec:	60e2                	ld	ra,24(sp)
    80004cee:	6442                	ld	s0,16(sp)
    80004cf0:	64a2                	ld	s1,8(sp)
    80004cf2:	6902                	ld	s2,0(sp)
    80004cf4:	6105                	addi	sp,sp,32
    80004cf6:	8082                	ret

0000000080004cf8 <idup>:
{
    80004cf8:	1101                	addi	sp,sp,-32
    80004cfa:	ec06                	sd	ra,24(sp)
    80004cfc:	e822                	sd	s0,16(sp)
    80004cfe:	e426                	sd	s1,8(sp)
    80004d00:	1000                	addi	s0,sp,32
    80004d02:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004d04:	0001c517          	auipc	a0,0x1c
    80004d08:	76450513          	addi	a0,a0,1892 # 80021468 <itable>
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	ed8080e7          	jalr	-296(ra) # 80000be4 <acquire>
  ip->ref++;
    80004d14:	449c                	lw	a5,8(s1)
    80004d16:	2785                	addiw	a5,a5,1
    80004d18:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004d1a:	0001c517          	auipc	a0,0x1c
    80004d1e:	74e50513          	addi	a0,a0,1870 # 80021468 <itable>
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	f76080e7          	jalr	-138(ra) # 80000c98 <release>
}
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	60e2                	ld	ra,24(sp)
    80004d2e:	6442                	ld	s0,16(sp)
    80004d30:	64a2                	ld	s1,8(sp)
    80004d32:	6105                	addi	sp,sp,32
    80004d34:	8082                	ret

0000000080004d36 <ilock>:
{
    80004d36:	1101                	addi	sp,sp,-32
    80004d38:	ec06                	sd	ra,24(sp)
    80004d3a:	e822                	sd	s0,16(sp)
    80004d3c:	e426                	sd	s1,8(sp)
    80004d3e:	e04a                	sd	s2,0(sp)
    80004d40:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004d42:	c115                	beqz	a0,80004d66 <ilock+0x30>
    80004d44:	84aa                	mv	s1,a0
    80004d46:	451c                	lw	a5,8(a0)
    80004d48:	00f05f63          	blez	a5,80004d66 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004d4c:	0541                	addi	a0,a0,16
    80004d4e:	00001097          	auipc	ra,0x1
    80004d52:	cb2080e7          	jalr	-846(ra) # 80005a00 <acquiresleep>
  if(ip->valid == 0){
    80004d56:	40bc                	lw	a5,64(s1)
    80004d58:	cf99                	beqz	a5,80004d76 <ilock+0x40>
}
    80004d5a:	60e2                	ld	ra,24(sp)
    80004d5c:	6442                	ld	s0,16(sp)
    80004d5e:	64a2                	ld	s1,8(sp)
    80004d60:	6902                	ld	s2,0(sp)
    80004d62:	6105                	addi	sp,sp,32
    80004d64:	8082                	ret
    panic("ilock");
    80004d66:	00005517          	auipc	a0,0x5
    80004d6a:	c6a50513          	addi	a0,a0,-918 # 800099d0 <syscalls+0x1a8>
    80004d6e:	ffffb097          	auipc	ra,0xffffb
    80004d72:	7d0080e7          	jalr	2000(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004d76:	40dc                	lw	a5,4(s1)
    80004d78:	0047d79b          	srliw	a5,a5,0x4
    80004d7c:	0001c597          	auipc	a1,0x1c
    80004d80:	6e45a583          	lw	a1,1764(a1) # 80021460 <sb+0x18>
    80004d84:	9dbd                	addw	a1,a1,a5
    80004d86:	4088                	lw	a0,0(s1)
    80004d88:	fffff097          	auipc	ra,0xfffff
    80004d8c:	7ac080e7          	jalr	1964(ra) # 80004534 <bread>
    80004d90:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004d92:	05850593          	addi	a1,a0,88
    80004d96:	40dc                	lw	a5,4(s1)
    80004d98:	8bbd                	andi	a5,a5,15
    80004d9a:	079a                	slli	a5,a5,0x6
    80004d9c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004d9e:	00059783          	lh	a5,0(a1)
    80004da2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004da6:	00259783          	lh	a5,2(a1)
    80004daa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004dae:	00459783          	lh	a5,4(a1)
    80004db2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004db6:	00659783          	lh	a5,6(a1)
    80004dba:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004dbe:	459c                	lw	a5,8(a1)
    80004dc0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004dc2:	03400613          	li	a2,52
    80004dc6:	05b1                	addi	a1,a1,12
    80004dc8:	05048513          	addi	a0,s1,80
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	f74080e7          	jalr	-140(ra) # 80000d40 <memmove>
    brelse(bp);
    80004dd4:	854a                	mv	a0,s2
    80004dd6:	00000097          	auipc	ra,0x0
    80004dda:	88e080e7          	jalr	-1906(ra) # 80004664 <brelse>
    ip->valid = 1;
    80004dde:	4785                	li	a5,1
    80004de0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004de2:	04449783          	lh	a5,68(s1)
    80004de6:	fbb5                	bnez	a5,80004d5a <ilock+0x24>
      panic("ilock: no type");
    80004de8:	00005517          	auipc	a0,0x5
    80004dec:	bf050513          	addi	a0,a0,-1040 # 800099d8 <syscalls+0x1b0>
    80004df0:	ffffb097          	auipc	ra,0xffffb
    80004df4:	74e080e7          	jalr	1870(ra) # 8000053e <panic>

0000000080004df8 <iunlock>:
{
    80004df8:	1101                	addi	sp,sp,-32
    80004dfa:	ec06                	sd	ra,24(sp)
    80004dfc:	e822                	sd	s0,16(sp)
    80004dfe:	e426                	sd	s1,8(sp)
    80004e00:	e04a                	sd	s2,0(sp)
    80004e02:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004e04:	c905                	beqz	a0,80004e34 <iunlock+0x3c>
    80004e06:	84aa                	mv	s1,a0
    80004e08:	01050913          	addi	s2,a0,16
    80004e0c:	854a                	mv	a0,s2
    80004e0e:	00001097          	auipc	ra,0x1
    80004e12:	c8c080e7          	jalr	-884(ra) # 80005a9a <holdingsleep>
    80004e16:	cd19                	beqz	a0,80004e34 <iunlock+0x3c>
    80004e18:	449c                	lw	a5,8(s1)
    80004e1a:	00f05d63          	blez	a5,80004e34 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004e1e:	854a                	mv	a0,s2
    80004e20:	00001097          	auipc	ra,0x1
    80004e24:	c36080e7          	jalr	-970(ra) # 80005a56 <releasesleep>
}
    80004e28:	60e2                	ld	ra,24(sp)
    80004e2a:	6442                	ld	s0,16(sp)
    80004e2c:	64a2                	ld	s1,8(sp)
    80004e2e:	6902                	ld	s2,0(sp)
    80004e30:	6105                	addi	sp,sp,32
    80004e32:	8082                	ret
    panic("iunlock");
    80004e34:	00005517          	auipc	a0,0x5
    80004e38:	bb450513          	addi	a0,a0,-1100 # 800099e8 <syscalls+0x1c0>
    80004e3c:	ffffb097          	auipc	ra,0xffffb
    80004e40:	702080e7          	jalr	1794(ra) # 8000053e <panic>

0000000080004e44 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004e44:	7179                	addi	sp,sp,-48
    80004e46:	f406                	sd	ra,40(sp)
    80004e48:	f022                	sd	s0,32(sp)
    80004e4a:	ec26                	sd	s1,24(sp)
    80004e4c:	e84a                	sd	s2,16(sp)
    80004e4e:	e44e                	sd	s3,8(sp)
    80004e50:	e052                	sd	s4,0(sp)
    80004e52:	1800                	addi	s0,sp,48
    80004e54:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004e56:	05050493          	addi	s1,a0,80
    80004e5a:	08050913          	addi	s2,a0,128
    80004e5e:	a021                	j	80004e66 <itrunc+0x22>
    80004e60:	0491                	addi	s1,s1,4
    80004e62:	01248d63          	beq	s1,s2,80004e7c <itrunc+0x38>
    if(ip->addrs[i]){
    80004e66:	408c                	lw	a1,0(s1)
    80004e68:	dde5                	beqz	a1,80004e60 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004e6a:	0009a503          	lw	a0,0(s3)
    80004e6e:	00000097          	auipc	ra,0x0
    80004e72:	90c080e7          	jalr	-1780(ra) # 8000477a <bfree>
      ip->addrs[i] = 0;
    80004e76:	0004a023          	sw	zero,0(s1)
    80004e7a:	b7dd                	j	80004e60 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004e7c:	0809a583          	lw	a1,128(s3)
    80004e80:	e185                	bnez	a1,80004ea0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004e82:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004e86:	854e                	mv	a0,s3
    80004e88:	00000097          	auipc	ra,0x0
    80004e8c:	de4080e7          	jalr	-540(ra) # 80004c6c <iupdate>
}
    80004e90:	70a2                	ld	ra,40(sp)
    80004e92:	7402                	ld	s0,32(sp)
    80004e94:	64e2                	ld	s1,24(sp)
    80004e96:	6942                	ld	s2,16(sp)
    80004e98:	69a2                	ld	s3,8(sp)
    80004e9a:	6a02                	ld	s4,0(sp)
    80004e9c:	6145                	addi	sp,sp,48
    80004e9e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004ea0:	0009a503          	lw	a0,0(s3)
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	690080e7          	jalr	1680(ra) # 80004534 <bread>
    80004eac:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004eae:	05850493          	addi	s1,a0,88
    80004eb2:	45850913          	addi	s2,a0,1112
    80004eb6:	a811                	j	80004eca <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004eb8:	0009a503          	lw	a0,0(s3)
    80004ebc:	00000097          	auipc	ra,0x0
    80004ec0:	8be080e7          	jalr	-1858(ra) # 8000477a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004ec4:	0491                	addi	s1,s1,4
    80004ec6:	01248563          	beq	s1,s2,80004ed0 <itrunc+0x8c>
      if(a[j])
    80004eca:	408c                	lw	a1,0(s1)
    80004ecc:	dde5                	beqz	a1,80004ec4 <itrunc+0x80>
    80004ece:	b7ed                	j	80004eb8 <itrunc+0x74>
    brelse(bp);
    80004ed0:	8552                	mv	a0,s4
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	792080e7          	jalr	1938(ra) # 80004664 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004eda:	0809a583          	lw	a1,128(s3)
    80004ede:	0009a503          	lw	a0,0(s3)
    80004ee2:	00000097          	auipc	ra,0x0
    80004ee6:	898080e7          	jalr	-1896(ra) # 8000477a <bfree>
    ip->addrs[NDIRECT] = 0;
    80004eea:	0809a023          	sw	zero,128(s3)
    80004eee:	bf51                	j	80004e82 <itrunc+0x3e>

0000000080004ef0 <iput>:
{
    80004ef0:	1101                	addi	sp,sp,-32
    80004ef2:	ec06                	sd	ra,24(sp)
    80004ef4:	e822                	sd	s0,16(sp)
    80004ef6:	e426                	sd	s1,8(sp)
    80004ef8:	e04a                	sd	s2,0(sp)
    80004efa:	1000                	addi	s0,sp,32
    80004efc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004efe:	0001c517          	auipc	a0,0x1c
    80004f02:	56a50513          	addi	a0,a0,1386 # 80021468 <itable>
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	cde080e7          	jalr	-802(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004f0e:	4498                	lw	a4,8(s1)
    80004f10:	4785                	li	a5,1
    80004f12:	02f70363          	beq	a4,a5,80004f38 <iput+0x48>
  ip->ref--;
    80004f16:	449c                	lw	a5,8(s1)
    80004f18:	37fd                	addiw	a5,a5,-1
    80004f1a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004f1c:	0001c517          	auipc	a0,0x1c
    80004f20:	54c50513          	addi	a0,a0,1356 # 80021468 <itable>
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	d74080e7          	jalr	-652(ra) # 80000c98 <release>
}
    80004f2c:	60e2                	ld	ra,24(sp)
    80004f2e:	6442                	ld	s0,16(sp)
    80004f30:	64a2                	ld	s1,8(sp)
    80004f32:	6902                	ld	s2,0(sp)
    80004f34:	6105                	addi	sp,sp,32
    80004f36:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004f38:	40bc                	lw	a5,64(s1)
    80004f3a:	dff1                	beqz	a5,80004f16 <iput+0x26>
    80004f3c:	04a49783          	lh	a5,74(s1)
    80004f40:	fbf9                	bnez	a5,80004f16 <iput+0x26>
    acquiresleep(&ip->lock);
    80004f42:	01048913          	addi	s2,s1,16
    80004f46:	854a                	mv	a0,s2
    80004f48:	00001097          	auipc	ra,0x1
    80004f4c:	ab8080e7          	jalr	-1352(ra) # 80005a00 <acquiresleep>
    release(&itable.lock);
    80004f50:	0001c517          	auipc	a0,0x1c
    80004f54:	51850513          	addi	a0,a0,1304 # 80021468 <itable>
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	d40080e7          	jalr	-704(ra) # 80000c98 <release>
    itrunc(ip);
    80004f60:	8526                	mv	a0,s1
    80004f62:	00000097          	auipc	ra,0x0
    80004f66:	ee2080e7          	jalr	-286(ra) # 80004e44 <itrunc>
    ip->type = 0;
    80004f6a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004f6e:	8526                	mv	a0,s1
    80004f70:	00000097          	auipc	ra,0x0
    80004f74:	cfc080e7          	jalr	-772(ra) # 80004c6c <iupdate>
    ip->valid = 0;
    80004f78:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004f7c:	854a                	mv	a0,s2
    80004f7e:	00001097          	auipc	ra,0x1
    80004f82:	ad8080e7          	jalr	-1320(ra) # 80005a56 <releasesleep>
    acquire(&itable.lock);
    80004f86:	0001c517          	auipc	a0,0x1c
    80004f8a:	4e250513          	addi	a0,a0,1250 # 80021468 <itable>
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	c56080e7          	jalr	-938(ra) # 80000be4 <acquire>
    80004f96:	b741                	j	80004f16 <iput+0x26>

0000000080004f98 <iunlockput>:
{
    80004f98:	1101                	addi	sp,sp,-32
    80004f9a:	ec06                	sd	ra,24(sp)
    80004f9c:	e822                	sd	s0,16(sp)
    80004f9e:	e426                	sd	s1,8(sp)
    80004fa0:	1000                	addi	s0,sp,32
    80004fa2:	84aa                	mv	s1,a0
  iunlock(ip);
    80004fa4:	00000097          	auipc	ra,0x0
    80004fa8:	e54080e7          	jalr	-428(ra) # 80004df8 <iunlock>
  iput(ip);
    80004fac:	8526                	mv	a0,s1
    80004fae:	00000097          	auipc	ra,0x0
    80004fb2:	f42080e7          	jalr	-190(ra) # 80004ef0 <iput>
}
    80004fb6:	60e2                	ld	ra,24(sp)
    80004fb8:	6442                	ld	s0,16(sp)
    80004fba:	64a2                	ld	s1,8(sp)
    80004fbc:	6105                	addi	sp,sp,32
    80004fbe:	8082                	ret

0000000080004fc0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004fc0:	1141                	addi	sp,sp,-16
    80004fc2:	e422                	sd	s0,8(sp)
    80004fc4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004fc6:	411c                	lw	a5,0(a0)
    80004fc8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004fca:	415c                	lw	a5,4(a0)
    80004fcc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004fce:	04451783          	lh	a5,68(a0)
    80004fd2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004fd6:	04a51783          	lh	a5,74(a0)
    80004fda:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004fde:	04c56783          	lwu	a5,76(a0)
    80004fe2:	e99c                	sd	a5,16(a1)
}
    80004fe4:	6422                	ld	s0,8(sp)
    80004fe6:	0141                	addi	sp,sp,16
    80004fe8:	8082                	ret

0000000080004fea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004fea:	457c                	lw	a5,76(a0)
    80004fec:	0ed7e963          	bltu	a5,a3,800050de <readi+0xf4>
{
    80004ff0:	7159                	addi	sp,sp,-112
    80004ff2:	f486                	sd	ra,104(sp)
    80004ff4:	f0a2                	sd	s0,96(sp)
    80004ff6:	eca6                	sd	s1,88(sp)
    80004ff8:	e8ca                	sd	s2,80(sp)
    80004ffa:	e4ce                	sd	s3,72(sp)
    80004ffc:	e0d2                	sd	s4,64(sp)
    80004ffe:	fc56                	sd	s5,56(sp)
    80005000:	f85a                	sd	s6,48(sp)
    80005002:	f45e                	sd	s7,40(sp)
    80005004:	f062                	sd	s8,32(sp)
    80005006:	ec66                	sd	s9,24(sp)
    80005008:	e86a                	sd	s10,16(sp)
    8000500a:	e46e                	sd	s11,8(sp)
    8000500c:	1880                	addi	s0,sp,112
    8000500e:	8baa                	mv	s7,a0
    80005010:	8c2e                	mv	s8,a1
    80005012:	8ab2                	mv	s5,a2
    80005014:	84b6                	mv	s1,a3
    80005016:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80005018:	9f35                	addw	a4,a4,a3
    return 0;
    8000501a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000501c:	0ad76063          	bltu	a4,a3,800050bc <readi+0xd2>
  if(off + n > ip->size)
    80005020:	00e7f463          	bgeu	a5,a4,80005028 <readi+0x3e>
    n = ip->size - off;
    80005024:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80005028:	0a0b0963          	beqz	s6,800050da <readi+0xf0>
    8000502c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000502e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80005032:	5cfd                	li	s9,-1
    80005034:	a82d                	j	8000506e <readi+0x84>
    80005036:	020a1d93          	slli	s11,s4,0x20
    8000503a:	020ddd93          	srli	s11,s11,0x20
    8000503e:	05890613          	addi	a2,s2,88
    80005042:	86ee                	mv	a3,s11
    80005044:	963a                	add	a2,a2,a4
    80005046:	85d6                	mv	a1,s5
    80005048:	8562                	mv	a0,s8
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	a74080e7          	jalr	-1420(ra) # 80003abe <either_copyout>
    80005052:	05950d63          	beq	a0,s9,800050ac <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80005056:	854a                	mv	a0,s2
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	60c080e7          	jalr	1548(ra) # 80004664 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80005060:	013a09bb          	addw	s3,s4,s3
    80005064:	009a04bb          	addw	s1,s4,s1
    80005068:	9aee                	add	s5,s5,s11
    8000506a:	0569f763          	bgeu	s3,s6,800050b8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000506e:	000ba903          	lw	s2,0(s7)
    80005072:	00a4d59b          	srliw	a1,s1,0xa
    80005076:	855e                	mv	a0,s7
    80005078:	00000097          	auipc	ra,0x0
    8000507c:	8b0080e7          	jalr	-1872(ra) # 80004928 <bmap>
    80005080:	0005059b          	sext.w	a1,a0
    80005084:	854a                	mv	a0,s2
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	4ae080e7          	jalr	1198(ra) # 80004534 <bread>
    8000508e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80005090:	3ff4f713          	andi	a4,s1,1023
    80005094:	40ed07bb          	subw	a5,s10,a4
    80005098:	413b06bb          	subw	a3,s6,s3
    8000509c:	8a3e                	mv	s4,a5
    8000509e:	2781                	sext.w	a5,a5
    800050a0:	0006861b          	sext.w	a2,a3
    800050a4:	f8f679e3          	bgeu	a2,a5,80005036 <readi+0x4c>
    800050a8:	8a36                	mv	s4,a3
    800050aa:	b771                	j	80005036 <readi+0x4c>
      brelse(bp);
    800050ac:	854a                	mv	a0,s2
    800050ae:	fffff097          	auipc	ra,0xfffff
    800050b2:	5b6080e7          	jalr	1462(ra) # 80004664 <brelse>
      tot = -1;
    800050b6:	59fd                	li	s3,-1
  }
  return tot;
    800050b8:	0009851b          	sext.w	a0,s3
}
    800050bc:	70a6                	ld	ra,104(sp)
    800050be:	7406                	ld	s0,96(sp)
    800050c0:	64e6                	ld	s1,88(sp)
    800050c2:	6946                	ld	s2,80(sp)
    800050c4:	69a6                	ld	s3,72(sp)
    800050c6:	6a06                	ld	s4,64(sp)
    800050c8:	7ae2                	ld	s5,56(sp)
    800050ca:	7b42                	ld	s6,48(sp)
    800050cc:	7ba2                	ld	s7,40(sp)
    800050ce:	7c02                	ld	s8,32(sp)
    800050d0:	6ce2                	ld	s9,24(sp)
    800050d2:	6d42                	ld	s10,16(sp)
    800050d4:	6da2                	ld	s11,8(sp)
    800050d6:	6165                	addi	sp,sp,112
    800050d8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800050da:	89da                	mv	s3,s6
    800050dc:	bff1                	j	800050b8 <readi+0xce>
    return 0;
    800050de:	4501                	li	a0,0
}
    800050e0:	8082                	ret

00000000800050e2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800050e2:	457c                	lw	a5,76(a0)
    800050e4:	10d7e863          	bltu	a5,a3,800051f4 <writei+0x112>
{
    800050e8:	7159                	addi	sp,sp,-112
    800050ea:	f486                	sd	ra,104(sp)
    800050ec:	f0a2                	sd	s0,96(sp)
    800050ee:	eca6                	sd	s1,88(sp)
    800050f0:	e8ca                	sd	s2,80(sp)
    800050f2:	e4ce                	sd	s3,72(sp)
    800050f4:	e0d2                	sd	s4,64(sp)
    800050f6:	fc56                	sd	s5,56(sp)
    800050f8:	f85a                	sd	s6,48(sp)
    800050fa:	f45e                	sd	s7,40(sp)
    800050fc:	f062                	sd	s8,32(sp)
    800050fe:	ec66                	sd	s9,24(sp)
    80005100:	e86a                	sd	s10,16(sp)
    80005102:	e46e                	sd	s11,8(sp)
    80005104:	1880                	addi	s0,sp,112
    80005106:	8b2a                	mv	s6,a0
    80005108:	8c2e                	mv	s8,a1
    8000510a:	8ab2                	mv	s5,a2
    8000510c:	8936                	mv	s2,a3
    8000510e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80005110:	00e687bb          	addw	a5,a3,a4
    80005114:	0ed7e263          	bltu	a5,a3,800051f8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80005118:	00043737          	lui	a4,0x43
    8000511c:	0ef76063          	bltu	a4,a5,800051fc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80005120:	0c0b8863          	beqz	s7,800051f0 <writei+0x10e>
    80005124:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80005126:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000512a:	5cfd                	li	s9,-1
    8000512c:	a091                	j	80005170 <writei+0x8e>
    8000512e:	02099d93          	slli	s11,s3,0x20
    80005132:	020ddd93          	srli	s11,s11,0x20
    80005136:	05848513          	addi	a0,s1,88
    8000513a:	86ee                	mv	a3,s11
    8000513c:	8656                	mv	a2,s5
    8000513e:	85e2                	mv	a1,s8
    80005140:	953a                	add	a0,a0,a4
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	9d2080e7          	jalr	-1582(ra) # 80003b14 <either_copyin>
    8000514a:	07950263          	beq	a0,s9,800051ae <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000514e:	8526                	mv	a0,s1
    80005150:	00000097          	auipc	ra,0x0
    80005154:	790080e7          	jalr	1936(ra) # 800058e0 <log_write>
    brelse(bp);
    80005158:	8526                	mv	a0,s1
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	50a080e7          	jalr	1290(ra) # 80004664 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80005162:	01498a3b          	addw	s4,s3,s4
    80005166:	0129893b          	addw	s2,s3,s2
    8000516a:	9aee                	add	s5,s5,s11
    8000516c:	057a7663          	bgeu	s4,s7,800051b8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80005170:	000b2483          	lw	s1,0(s6)
    80005174:	00a9559b          	srliw	a1,s2,0xa
    80005178:	855a                	mv	a0,s6
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	7ae080e7          	jalr	1966(ra) # 80004928 <bmap>
    80005182:	0005059b          	sext.w	a1,a0
    80005186:	8526                	mv	a0,s1
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	3ac080e7          	jalr	940(ra) # 80004534 <bread>
    80005190:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80005192:	3ff97713          	andi	a4,s2,1023
    80005196:	40ed07bb          	subw	a5,s10,a4
    8000519a:	414b86bb          	subw	a3,s7,s4
    8000519e:	89be                	mv	s3,a5
    800051a0:	2781                	sext.w	a5,a5
    800051a2:	0006861b          	sext.w	a2,a3
    800051a6:	f8f674e3          	bgeu	a2,a5,8000512e <writei+0x4c>
    800051aa:	89b6                	mv	s3,a3
    800051ac:	b749                	j	8000512e <writei+0x4c>
      brelse(bp);
    800051ae:	8526                	mv	a0,s1
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	4b4080e7          	jalr	1204(ra) # 80004664 <brelse>
  }

  if(off > ip->size)
    800051b8:	04cb2783          	lw	a5,76(s6)
    800051bc:	0127f463          	bgeu	a5,s2,800051c4 <writei+0xe2>
    ip->size = off;
    800051c0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800051c4:	855a                	mv	a0,s6
    800051c6:	00000097          	auipc	ra,0x0
    800051ca:	aa6080e7          	jalr	-1370(ra) # 80004c6c <iupdate>

  return tot;
    800051ce:	000a051b          	sext.w	a0,s4
}
    800051d2:	70a6                	ld	ra,104(sp)
    800051d4:	7406                	ld	s0,96(sp)
    800051d6:	64e6                	ld	s1,88(sp)
    800051d8:	6946                	ld	s2,80(sp)
    800051da:	69a6                	ld	s3,72(sp)
    800051dc:	6a06                	ld	s4,64(sp)
    800051de:	7ae2                	ld	s5,56(sp)
    800051e0:	7b42                	ld	s6,48(sp)
    800051e2:	7ba2                	ld	s7,40(sp)
    800051e4:	7c02                	ld	s8,32(sp)
    800051e6:	6ce2                	ld	s9,24(sp)
    800051e8:	6d42                	ld	s10,16(sp)
    800051ea:	6da2                	ld	s11,8(sp)
    800051ec:	6165                	addi	sp,sp,112
    800051ee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800051f0:	8a5e                	mv	s4,s7
    800051f2:	bfc9                	j	800051c4 <writei+0xe2>
    return -1;
    800051f4:	557d                	li	a0,-1
}
    800051f6:	8082                	ret
    return -1;
    800051f8:	557d                	li	a0,-1
    800051fa:	bfe1                	j	800051d2 <writei+0xf0>
    return -1;
    800051fc:	557d                	li	a0,-1
    800051fe:	bfd1                	j	800051d2 <writei+0xf0>

0000000080005200 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80005200:	1141                	addi	sp,sp,-16
    80005202:	e406                	sd	ra,8(sp)
    80005204:	e022                	sd	s0,0(sp)
    80005206:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80005208:	4639                	li	a2,14
    8000520a:	ffffc097          	auipc	ra,0xffffc
    8000520e:	bae080e7          	jalr	-1106(ra) # 80000db8 <strncmp>
}
    80005212:	60a2                	ld	ra,8(sp)
    80005214:	6402                	ld	s0,0(sp)
    80005216:	0141                	addi	sp,sp,16
    80005218:	8082                	ret

000000008000521a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000521a:	7139                	addi	sp,sp,-64
    8000521c:	fc06                	sd	ra,56(sp)
    8000521e:	f822                	sd	s0,48(sp)
    80005220:	f426                	sd	s1,40(sp)
    80005222:	f04a                	sd	s2,32(sp)
    80005224:	ec4e                	sd	s3,24(sp)
    80005226:	e852                	sd	s4,16(sp)
    80005228:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000522a:	04451703          	lh	a4,68(a0)
    8000522e:	4785                	li	a5,1
    80005230:	00f71a63          	bne	a4,a5,80005244 <dirlookup+0x2a>
    80005234:	892a                	mv	s2,a0
    80005236:	89ae                	mv	s3,a1
    80005238:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000523a:	457c                	lw	a5,76(a0)
    8000523c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000523e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005240:	e79d                	bnez	a5,8000526e <dirlookup+0x54>
    80005242:	a8a5                	j	800052ba <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80005244:	00004517          	auipc	a0,0x4
    80005248:	7ac50513          	addi	a0,a0,1964 # 800099f0 <syscalls+0x1c8>
    8000524c:	ffffb097          	auipc	ra,0xffffb
    80005250:	2f2080e7          	jalr	754(ra) # 8000053e <panic>
      panic("dirlookup read");
    80005254:	00004517          	auipc	a0,0x4
    80005258:	7b450513          	addi	a0,a0,1972 # 80009a08 <syscalls+0x1e0>
    8000525c:	ffffb097          	auipc	ra,0xffffb
    80005260:	2e2080e7          	jalr	738(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005264:	24c1                	addiw	s1,s1,16
    80005266:	04c92783          	lw	a5,76(s2)
    8000526a:	04f4f763          	bgeu	s1,a5,800052b8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000526e:	4741                	li	a4,16
    80005270:	86a6                	mv	a3,s1
    80005272:	fc040613          	addi	a2,s0,-64
    80005276:	4581                	li	a1,0
    80005278:	854a                	mv	a0,s2
    8000527a:	00000097          	auipc	ra,0x0
    8000527e:	d70080e7          	jalr	-656(ra) # 80004fea <readi>
    80005282:	47c1                	li	a5,16
    80005284:	fcf518e3          	bne	a0,a5,80005254 <dirlookup+0x3a>
    if(de.inum == 0)
    80005288:	fc045783          	lhu	a5,-64(s0)
    8000528c:	dfe1                	beqz	a5,80005264 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000528e:	fc240593          	addi	a1,s0,-62
    80005292:	854e                	mv	a0,s3
    80005294:	00000097          	auipc	ra,0x0
    80005298:	f6c080e7          	jalr	-148(ra) # 80005200 <namecmp>
    8000529c:	f561                	bnez	a0,80005264 <dirlookup+0x4a>
      if(poff)
    8000529e:	000a0463          	beqz	s4,800052a6 <dirlookup+0x8c>
        *poff = off;
    800052a2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800052a6:	fc045583          	lhu	a1,-64(s0)
    800052aa:	00092503          	lw	a0,0(s2)
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	754080e7          	jalr	1876(ra) # 80004a02 <iget>
    800052b6:	a011                	j	800052ba <dirlookup+0xa0>
  return 0;
    800052b8:	4501                	li	a0,0
}
    800052ba:	70e2                	ld	ra,56(sp)
    800052bc:	7442                	ld	s0,48(sp)
    800052be:	74a2                	ld	s1,40(sp)
    800052c0:	7902                	ld	s2,32(sp)
    800052c2:	69e2                	ld	s3,24(sp)
    800052c4:	6a42                	ld	s4,16(sp)
    800052c6:	6121                	addi	sp,sp,64
    800052c8:	8082                	ret

00000000800052ca <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800052ca:	711d                	addi	sp,sp,-96
    800052cc:	ec86                	sd	ra,88(sp)
    800052ce:	e8a2                	sd	s0,80(sp)
    800052d0:	e4a6                	sd	s1,72(sp)
    800052d2:	e0ca                	sd	s2,64(sp)
    800052d4:	fc4e                	sd	s3,56(sp)
    800052d6:	f852                	sd	s4,48(sp)
    800052d8:	f456                	sd	s5,40(sp)
    800052da:	f05a                	sd	s6,32(sp)
    800052dc:	ec5e                	sd	s7,24(sp)
    800052de:	e862                	sd	s8,16(sp)
    800052e0:	e466                	sd	s9,8(sp)
    800052e2:	1080                	addi	s0,sp,96
    800052e4:	84aa                	mv	s1,a0
    800052e6:	8b2e                	mv	s6,a1
    800052e8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800052ea:	00054703          	lbu	a4,0(a0)
    800052ee:	02f00793          	li	a5,47
    800052f2:	02f70363          	beq	a4,a5,80005318 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800052f6:	ffffd097          	auipc	ra,0xffffd
    800052fa:	89e080e7          	jalr	-1890(ra) # 80001b94 <myproc>
    800052fe:	18053503          	ld	a0,384(a0)
    80005302:	00000097          	auipc	ra,0x0
    80005306:	9f6080e7          	jalr	-1546(ra) # 80004cf8 <idup>
    8000530a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000530c:	02f00913          	li	s2,47
  len = path - s;
    80005310:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80005312:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80005314:	4c05                	li	s8,1
    80005316:	a865                	j	800053ce <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80005318:	4585                	li	a1,1
    8000531a:	4505                	li	a0,1
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	6e6080e7          	jalr	1766(ra) # 80004a02 <iget>
    80005324:	89aa                	mv	s3,a0
    80005326:	b7dd                	j	8000530c <namex+0x42>
      iunlockput(ip);
    80005328:	854e                	mv	a0,s3
    8000532a:	00000097          	auipc	ra,0x0
    8000532e:	c6e080e7          	jalr	-914(ra) # 80004f98 <iunlockput>
      return 0;
    80005332:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80005334:	854e                	mv	a0,s3
    80005336:	60e6                	ld	ra,88(sp)
    80005338:	6446                	ld	s0,80(sp)
    8000533a:	64a6                	ld	s1,72(sp)
    8000533c:	6906                	ld	s2,64(sp)
    8000533e:	79e2                	ld	s3,56(sp)
    80005340:	7a42                	ld	s4,48(sp)
    80005342:	7aa2                	ld	s5,40(sp)
    80005344:	7b02                	ld	s6,32(sp)
    80005346:	6be2                	ld	s7,24(sp)
    80005348:	6c42                	ld	s8,16(sp)
    8000534a:	6ca2                	ld	s9,8(sp)
    8000534c:	6125                	addi	sp,sp,96
    8000534e:	8082                	ret
      iunlock(ip);
    80005350:	854e                	mv	a0,s3
    80005352:	00000097          	auipc	ra,0x0
    80005356:	aa6080e7          	jalr	-1370(ra) # 80004df8 <iunlock>
      return ip;
    8000535a:	bfe9                	j	80005334 <namex+0x6a>
      iunlockput(ip);
    8000535c:	854e                	mv	a0,s3
    8000535e:	00000097          	auipc	ra,0x0
    80005362:	c3a080e7          	jalr	-966(ra) # 80004f98 <iunlockput>
      return 0;
    80005366:	89d2                	mv	s3,s4
    80005368:	b7f1                	j	80005334 <namex+0x6a>
  len = path - s;
    8000536a:	40b48633          	sub	a2,s1,a1
    8000536e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80005372:	094cd463          	bge	s9,s4,800053fa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80005376:	4639                	li	a2,14
    80005378:	8556                	mv	a0,s5
    8000537a:	ffffc097          	auipc	ra,0xffffc
    8000537e:	9c6080e7          	jalr	-1594(ra) # 80000d40 <memmove>
  while(*path == '/')
    80005382:	0004c783          	lbu	a5,0(s1)
    80005386:	01279763          	bne	a5,s2,80005394 <namex+0xca>
    path++;
    8000538a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000538c:	0004c783          	lbu	a5,0(s1)
    80005390:	ff278de3          	beq	a5,s2,8000538a <namex+0xc0>
    ilock(ip);
    80005394:	854e                	mv	a0,s3
    80005396:	00000097          	auipc	ra,0x0
    8000539a:	9a0080e7          	jalr	-1632(ra) # 80004d36 <ilock>
    if(ip->type != T_DIR){
    8000539e:	04499783          	lh	a5,68(s3)
    800053a2:	f98793e3          	bne	a5,s8,80005328 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800053a6:	000b0563          	beqz	s6,800053b0 <namex+0xe6>
    800053aa:	0004c783          	lbu	a5,0(s1)
    800053ae:	d3cd                	beqz	a5,80005350 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800053b0:	865e                	mv	a2,s7
    800053b2:	85d6                	mv	a1,s5
    800053b4:	854e                	mv	a0,s3
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	e64080e7          	jalr	-412(ra) # 8000521a <dirlookup>
    800053be:	8a2a                	mv	s4,a0
    800053c0:	dd51                	beqz	a0,8000535c <namex+0x92>
    iunlockput(ip);
    800053c2:	854e                	mv	a0,s3
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	bd4080e7          	jalr	-1068(ra) # 80004f98 <iunlockput>
    ip = next;
    800053cc:	89d2                	mv	s3,s4
  while(*path == '/')
    800053ce:	0004c783          	lbu	a5,0(s1)
    800053d2:	05279763          	bne	a5,s2,80005420 <namex+0x156>
    path++;
    800053d6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800053d8:	0004c783          	lbu	a5,0(s1)
    800053dc:	ff278de3          	beq	a5,s2,800053d6 <namex+0x10c>
  if(*path == 0)
    800053e0:	c79d                	beqz	a5,8000540e <namex+0x144>
    path++;
    800053e2:	85a6                	mv	a1,s1
  len = path - s;
    800053e4:	8a5e                	mv	s4,s7
    800053e6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800053e8:	01278963          	beq	a5,s2,800053fa <namex+0x130>
    800053ec:	dfbd                	beqz	a5,8000536a <namex+0xa0>
    path++;
    800053ee:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800053f0:	0004c783          	lbu	a5,0(s1)
    800053f4:	ff279ce3          	bne	a5,s2,800053ec <namex+0x122>
    800053f8:	bf8d                	j	8000536a <namex+0xa0>
    memmove(name, s, len);
    800053fa:	2601                	sext.w	a2,a2
    800053fc:	8556                	mv	a0,s5
    800053fe:	ffffc097          	auipc	ra,0xffffc
    80005402:	942080e7          	jalr	-1726(ra) # 80000d40 <memmove>
    name[len] = 0;
    80005406:	9a56                	add	s4,s4,s5
    80005408:	000a0023          	sb	zero,0(s4)
    8000540c:	bf9d                	j	80005382 <namex+0xb8>
  if(nameiparent){
    8000540e:	f20b03e3          	beqz	s6,80005334 <namex+0x6a>
    iput(ip);
    80005412:	854e                	mv	a0,s3
    80005414:	00000097          	auipc	ra,0x0
    80005418:	adc080e7          	jalr	-1316(ra) # 80004ef0 <iput>
    return 0;
    8000541c:	4981                	li	s3,0
    8000541e:	bf19                	j	80005334 <namex+0x6a>
  if(*path == 0)
    80005420:	d7fd                	beqz	a5,8000540e <namex+0x144>
  while(*path != '/' && *path != 0)
    80005422:	0004c783          	lbu	a5,0(s1)
    80005426:	85a6                	mv	a1,s1
    80005428:	b7d1                	j	800053ec <namex+0x122>

000000008000542a <dirlink>:
{
    8000542a:	7139                	addi	sp,sp,-64
    8000542c:	fc06                	sd	ra,56(sp)
    8000542e:	f822                	sd	s0,48(sp)
    80005430:	f426                	sd	s1,40(sp)
    80005432:	f04a                	sd	s2,32(sp)
    80005434:	ec4e                	sd	s3,24(sp)
    80005436:	e852                	sd	s4,16(sp)
    80005438:	0080                	addi	s0,sp,64
    8000543a:	892a                	mv	s2,a0
    8000543c:	8a2e                	mv	s4,a1
    8000543e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80005440:	4601                	li	a2,0
    80005442:	00000097          	auipc	ra,0x0
    80005446:	dd8080e7          	jalr	-552(ra) # 8000521a <dirlookup>
    8000544a:	e93d                	bnez	a0,800054c0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000544c:	04c92483          	lw	s1,76(s2)
    80005450:	c49d                	beqz	s1,8000547e <dirlink+0x54>
    80005452:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005454:	4741                	li	a4,16
    80005456:	86a6                	mv	a3,s1
    80005458:	fc040613          	addi	a2,s0,-64
    8000545c:	4581                	li	a1,0
    8000545e:	854a                	mv	a0,s2
    80005460:	00000097          	auipc	ra,0x0
    80005464:	b8a080e7          	jalr	-1142(ra) # 80004fea <readi>
    80005468:	47c1                	li	a5,16
    8000546a:	06f51163          	bne	a0,a5,800054cc <dirlink+0xa2>
    if(de.inum == 0)
    8000546e:	fc045783          	lhu	a5,-64(s0)
    80005472:	c791                	beqz	a5,8000547e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005474:	24c1                	addiw	s1,s1,16
    80005476:	04c92783          	lw	a5,76(s2)
    8000547a:	fcf4ede3          	bltu	s1,a5,80005454 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000547e:	4639                	li	a2,14
    80005480:	85d2                	mv	a1,s4
    80005482:	fc240513          	addi	a0,s0,-62
    80005486:	ffffc097          	auipc	ra,0xffffc
    8000548a:	96e080e7          	jalr	-1682(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000548e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005492:	4741                	li	a4,16
    80005494:	86a6                	mv	a3,s1
    80005496:	fc040613          	addi	a2,s0,-64
    8000549a:	4581                	li	a1,0
    8000549c:	854a                	mv	a0,s2
    8000549e:	00000097          	auipc	ra,0x0
    800054a2:	c44080e7          	jalr	-956(ra) # 800050e2 <writei>
    800054a6:	872a                	mv	a4,a0
    800054a8:	47c1                	li	a5,16
  return 0;
    800054aa:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ac:	02f71863          	bne	a4,a5,800054dc <dirlink+0xb2>
}
    800054b0:	70e2                	ld	ra,56(sp)
    800054b2:	7442                	ld	s0,48(sp)
    800054b4:	74a2                	ld	s1,40(sp)
    800054b6:	7902                	ld	s2,32(sp)
    800054b8:	69e2                	ld	s3,24(sp)
    800054ba:	6a42                	ld	s4,16(sp)
    800054bc:	6121                	addi	sp,sp,64
    800054be:	8082                	ret
    iput(ip);
    800054c0:	00000097          	auipc	ra,0x0
    800054c4:	a30080e7          	jalr	-1488(ra) # 80004ef0 <iput>
    return -1;
    800054c8:	557d                	li	a0,-1
    800054ca:	b7dd                	j	800054b0 <dirlink+0x86>
      panic("dirlink read");
    800054cc:	00004517          	auipc	a0,0x4
    800054d0:	54c50513          	addi	a0,a0,1356 # 80009a18 <syscalls+0x1f0>
    800054d4:	ffffb097          	auipc	ra,0xffffb
    800054d8:	06a080e7          	jalr	106(ra) # 8000053e <panic>
    panic("dirlink");
    800054dc:	00004517          	auipc	a0,0x4
    800054e0:	64c50513          	addi	a0,a0,1612 # 80009b28 <syscalls+0x300>
    800054e4:	ffffb097          	auipc	ra,0xffffb
    800054e8:	05a080e7          	jalr	90(ra) # 8000053e <panic>

00000000800054ec <namei>:

struct inode*
namei(char *path)
{
    800054ec:	1101                	addi	sp,sp,-32
    800054ee:	ec06                	sd	ra,24(sp)
    800054f0:	e822                	sd	s0,16(sp)
    800054f2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800054f4:	fe040613          	addi	a2,s0,-32
    800054f8:	4581                	li	a1,0
    800054fa:	00000097          	auipc	ra,0x0
    800054fe:	dd0080e7          	jalr	-560(ra) # 800052ca <namex>
}
    80005502:	60e2                	ld	ra,24(sp)
    80005504:	6442                	ld	s0,16(sp)
    80005506:	6105                	addi	sp,sp,32
    80005508:	8082                	ret

000000008000550a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000550a:	1141                	addi	sp,sp,-16
    8000550c:	e406                	sd	ra,8(sp)
    8000550e:	e022                	sd	s0,0(sp)
    80005510:	0800                	addi	s0,sp,16
    80005512:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80005514:	4585                	li	a1,1
    80005516:	00000097          	auipc	ra,0x0
    8000551a:	db4080e7          	jalr	-588(ra) # 800052ca <namex>
}
    8000551e:	60a2                	ld	ra,8(sp)
    80005520:	6402                	ld	s0,0(sp)
    80005522:	0141                	addi	sp,sp,16
    80005524:	8082                	ret

0000000080005526 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80005526:	1101                	addi	sp,sp,-32
    80005528:	ec06                	sd	ra,24(sp)
    8000552a:	e822                	sd	s0,16(sp)
    8000552c:	e426                	sd	s1,8(sp)
    8000552e:	e04a                	sd	s2,0(sp)
    80005530:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80005532:	0001e917          	auipc	s2,0x1e
    80005536:	9de90913          	addi	s2,s2,-1570 # 80022f10 <log>
    8000553a:	01892583          	lw	a1,24(s2)
    8000553e:	02892503          	lw	a0,40(s2)
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	ff2080e7          	jalr	-14(ra) # 80004534 <bread>
    8000554a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000554c:	02c92683          	lw	a3,44(s2)
    80005550:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80005552:	02d05763          	blez	a3,80005580 <write_head+0x5a>
    80005556:	0001e797          	auipc	a5,0x1e
    8000555a:	9ea78793          	addi	a5,a5,-1558 # 80022f40 <log+0x30>
    8000555e:	05c50713          	addi	a4,a0,92
    80005562:	36fd                	addiw	a3,a3,-1
    80005564:	1682                	slli	a3,a3,0x20
    80005566:	9281                	srli	a3,a3,0x20
    80005568:	068a                	slli	a3,a3,0x2
    8000556a:	0001e617          	auipc	a2,0x1e
    8000556e:	9da60613          	addi	a2,a2,-1574 # 80022f44 <log+0x34>
    80005572:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80005574:	4390                	lw	a2,0(a5)
    80005576:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80005578:	0791                	addi	a5,a5,4
    8000557a:	0711                	addi	a4,a4,4
    8000557c:	fed79ce3          	bne	a5,a3,80005574 <write_head+0x4e>
  }
  bwrite(buf);
    80005580:	8526                	mv	a0,s1
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	0a4080e7          	jalr	164(ra) # 80004626 <bwrite>
  brelse(buf);
    8000558a:	8526                	mv	a0,s1
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	0d8080e7          	jalr	216(ra) # 80004664 <brelse>
}
    80005594:	60e2                	ld	ra,24(sp)
    80005596:	6442                	ld	s0,16(sp)
    80005598:	64a2                	ld	s1,8(sp)
    8000559a:	6902                	ld	s2,0(sp)
    8000559c:	6105                	addi	sp,sp,32
    8000559e:	8082                	ret

00000000800055a0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800055a0:	0001e797          	auipc	a5,0x1e
    800055a4:	99c7a783          	lw	a5,-1636(a5) # 80022f3c <log+0x2c>
    800055a8:	0af05d63          	blez	a5,80005662 <install_trans+0xc2>
{
    800055ac:	7139                	addi	sp,sp,-64
    800055ae:	fc06                	sd	ra,56(sp)
    800055b0:	f822                	sd	s0,48(sp)
    800055b2:	f426                	sd	s1,40(sp)
    800055b4:	f04a                	sd	s2,32(sp)
    800055b6:	ec4e                	sd	s3,24(sp)
    800055b8:	e852                	sd	s4,16(sp)
    800055ba:	e456                	sd	s5,8(sp)
    800055bc:	e05a                	sd	s6,0(sp)
    800055be:	0080                	addi	s0,sp,64
    800055c0:	8b2a                	mv	s6,a0
    800055c2:	0001ea97          	auipc	s5,0x1e
    800055c6:	97ea8a93          	addi	s5,s5,-1666 # 80022f40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800055ca:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800055cc:	0001e997          	auipc	s3,0x1e
    800055d0:	94498993          	addi	s3,s3,-1724 # 80022f10 <log>
    800055d4:	a035                	j	80005600 <install_trans+0x60>
      bunpin(dbuf);
    800055d6:	8526                	mv	a0,s1
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	166080e7          	jalr	358(ra) # 8000473e <bunpin>
    brelse(lbuf);
    800055e0:	854a                	mv	a0,s2
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	082080e7          	jalr	130(ra) # 80004664 <brelse>
    brelse(dbuf);
    800055ea:	8526                	mv	a0,s1
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	078080e7          	jalr	120(ra) # 80004664 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800055f4:	2a05                	addiw	s4,s4,1
    800055f6:	0a91                	addi	s5,s5,4
    800055f8:	02c9a783          	lw	a5,44(s3)
    800055fc:	04fa5963          	bge	s4,a5,8000564e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005600:	0189a583          	lw	a1,24(s3)
    80005604:	014585bb          	addw	a1,a1,s4
    80005608:	2585                	addiw	a1,a1,1
    8000560a:	0289a503          	lw	a0,40(s3)
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	f26080e7          	jalr	-218(ra) # 80004534 <bread>
    80005616:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80005618:	000aa583          	lw	a1,0(s5)
    8000561c:	0289a503          	lw	a0,40(s3)
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	f14080e7          	jalr	-236(ra) # 80004534 <bread>
    80005628:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000562a:	40000613          	li	a2,1024
    8000562e:	05890593          	addi	a1,s2,88
    80005632:	05850513          	addi	a0,a0,88
    80005636:	ffffb097          	auipc	ra,0xffffb
    8000563a:	70a080e7          	jalr	1802(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000563e:	8526                	mv	a0,s1
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	fe6080e7          	jalr	-26(ra) # 80004626 <bwrite>
    if(recovering == 0)
    80005648:	f80b1ce3          	bnez	s6,800055e0 <install_trans+0x40>
    8000564c:	b769                	j	800055d6 <install_trans+0x36>
}
    8000564e:	70e2                	ld	ra,56(sp)
    80005650:	7442                	ld	s0,48(sp)
    80005652:	74a2                	ld	s1,40(sp)
    80005654:	7902                	ld	s2,32(sp)
    80005656:	69e2                	ld	s3,24(sp)
    80005658:	6a42                	ld	s4,16(sp)
    8000565a:	6aa2                	ld	s5,8(sp)
    8000565c:	6b02                	ld	s6,0(sp)
    8000565e:	6121                	addi	sp,sp,64
    80005660:	8082                	ret
    80005662:	8082                	ret

0000000080005664 <initlog>:
{
    80005664:	7179                	addi	sp,sp,-48
    80005666:	f406                	sd	ra,40(sp)
    80005668:	f022                	sd	s0,32(sp)
    8000566a:	ec26                	sd	s1,24(sp)
    8000566c:	e84a                	sd	s2,16(sp)
    8000566e:	e44e                	sd	s3,8(sp)
    80005670:	1800                	addi	s0,sp,48
    80005672:	892a                	mv	s2,a0
    80005674:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80005676:	0001e497          	auipc	s1,0x1e
    8000567a:	89a48493          	addi	s1,s1,-1894 # 80022f10 <log>
    8000567e:	00004597          	auipc	a1,0x4
    80005682:	3aa58593          	addi	a1,a1,938 # 80009a28 <syscalls+0x200>
    80005686:	8526                	mv	a0,s1
    80005688:	ffffb097          	auipc	ra,0xffffb
    8000568c:	4cc080e7          	jalr	1228(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80005690:	0149a583          	lw	a1,20(s3)
    80005694:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80005696:	0109a783          	lw	a5,16(s3)
    8000569a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000569c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800056a0:	854a                	mv	a0,s2
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	e92080e7          	jalr	-366(ra) # 80004534 <bread>
  log.lh.n = lh->n;
    800056aa:	4d3c                	lw	a5,88(a0)
    800056ac:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800056ae:	02f05563          	blez	a5,800056d8 <initlog+0x74>
    800056b2:	05c50713          	addi	a4,a0,92
    800056b6:	0001e697          	auipc	a3,0x1e
    800056ba:	88a68693          	addi	a3,a3,-1910 # 80022f40 <log+0x30>
    800056be:	37fd                	addiw	a5,a5,-1
    800056c0:	1782                	slli	a5,a5,0x20
    800056c2:	9381                	srli	a5,a5,0x20
    800056c4:	078a                	slli	a5,a5,0x2
    800056c6:	06050613          	addi	a2,a0,96
    800056ca:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800056cc:	4310                	lw	a2,0(a4)
    800056ce:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800056d0:	0711                	addi	a4,a4,4
    800056d2:	0691                	addi	a3,a3,4
    800056d4:	fef71ce3          	bne	a4,a5,800056cc <initlog+0x68>
  brelse(buf);
    800056d8:	fffff097          	auipc	ra,0xfffff
    800056dc:	f8c080e7          	jalr	-116(ra) # 80004664 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800056e0:	4505                	li	a0,1
    800056e2:	00000097          	auipc	ra,0x0
    800056e6:	ebe080e7          	jalr	-322(ra) # 800055a0 <install_trans>
  log.lh.n = 0;
    800056ea:	0001e797          	auipc	a5,0x1e
    800056ee:	8407a923          	sw	zero,-1966(a5) # 80022f3c <log+0x2c>
  write_head(); // clear the log
    800056f2:	00000097          	auipc	ra,0x0
    800056f6:	e34080e7          	jalr	-460(ra) # 80005526 <write_head>
}
    800056fa:	70a2                	ld	ra,40(sp)
    800056fc:	7402                	ld	s0,32(sp)
    800056fe:	64e2                	ld	s1,24(sp)
    80005700:	6942                	ld	s2,16(sp)
    80005702:	69a2                	ld	s3,8(sp)
    80005704:	6145                	addi	sp,sp,48
    80005706:	8082                	ret

0000000080005708 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80005708:	1101                	addi	sp,sp,-32
    8000570a:	ec06                	sd	ra,24(sp)
    8000570c:	e822                	sd	s0,16(sp)
    8000570e:	e426                	sd	s1,8(sp)
    80005710:	e04a                	sd	s2,0(sp)
    80005712:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80005714:	0001d517          	auipc	a0,0x1d
    80005718:	7fc50513          	addi	a0,a0,2044 # 80022f10 <log>
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	4c8080e7          	jalr	1224(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80005724:	0001d497          	auipc	s1,0x1d
    80005728:	7ec48493          	addi	s1,s1,2028 # 80022f10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000572c:	4979                	li	s2,30
    8000572e:	a039                	j	8000573c <begin_op+0x34>
      sleep(&log, &log.lock);
    80005730:	85a6                	mv	a1,s1
    80005732:	8526                	mv	a0,s1
    80005734:	ffffd097          	auipc	ra,0xffffd
    80005738:	54a080e7          	jalr	1354(ra) # 80002c7e <sleep>
    if(log.committing){
    8000573c:	50dc                	lw	a5,36(s1)
    8000573e:	fbed                	bnez	a5,80005730 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005740:	509c                	lw	a5,32(s1)
    80005742:	0017871b          	addiw	a4,a5,1
    80005746:	0007069b          	sext.w	a3,a4
    8000574a:	0027179b          	slliw	a5,a4,0x2
    8000574e:	9fb9                	addw	a5,a5,a4
    80005750:	0017979b          	slliw	a5,a5,0x1
    80005754:	54d8                	lw	a4,44(s1)
    80005756:	9fb9                	addw	a5,a5,a4
    80005758:	00f95963          	bge	s2,a5,8000576a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000575c:	85a6                	mv	a1,s1
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffd097          	auipc	ra,0xffffd
    80005764:	51e080e7          	jalr	1310(ra) # 80002c7e <sleep>
    80005768:	bfd1                	j	8000573c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000576a:	0001d517          	auipc	a0,0x1d
    8000576e:	7a650513          	addi	a0,a0,1958 # 80022f10 <log>
    80005772:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80005774:	ffffb097          	auipc	ra,0xffffb
    80005778:	524080e7          	jalr	1316(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000577c:	60e2                	ld	ra,24(sp)
    8000577e:	6442                	ld	s0,16(sp)
    80005780:	64a2                	ld	s1,8(sp)
    80005782:	6902                	ld	s2,0(sp)
    80005784:	6105                	addi	sp,sp,32
    80005786:	8082                	ret

0000000080005788 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005788:	7139                	addi	sp,sp,-64
    8000578a:	fc06                	sd	ra,56(sp)
    8000578c:	f822                	sd	s0,48(sp)
    8000578e:	f426                	sd	s1,40(sp)
    80005790:	f04a                	sd	s2,32(sp)
    80005792:	ec4e                	sd	s3,24(sp)
    80005794:	e852                	sd	s4,16(sp)
    80005796:	e456                	sd	s5,8(sp)
    80005798:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000579a:	0001d497          	auipc	s1,0x1d
    8000579e:	77648493          	addi	s1,s1,1910 # 80022f10 <log>
    800057a2:	8526                	mv	a0,s1
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	440080e7          	jalr	1088(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800057ac:	509c                	lw	a5,32(s1)
    800057ae:	37fd                	addiw	a5,a5,-1
    800057b0:	0007891b          	sext.w	s2,a5
    800057b4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800057b6:	50dc                	lw	a5,36(s1)
    800057b8:	efb9                	bnez	a5,80005816 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800057ba:	06091663          	bnez	s2,80005826 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800057be:	0001d497          	auipc	s1,0x1d
    800057c2:	75248493          	addi	s1,s1,1874 # 80022f10 <log>
    800057c6:	4785                	li	a5,1
    800057c8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffb097          	auipc	ra,0xffffb
    800057d0:	4cc080e7          	jalr	1228(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800057d4:	54dc                	lw	a5,44(s1)
    800057d6:	06f04763          	bgtz	a5,80005844 <end_op+0xbc>
    acquire(&log.lock);
    800057da:	0001d497          	auipc	s1,0x1d
    800057de:	73648493          	addi	s1,s1,1846 # 80022f10 <log>
    800057e2:	8526                	mv	a0,s1
    800057e4:	ffffb097          	auipc	ra,0xffffb
    800057e8:	400080e7          	jalr	1024(ra) # 80000be4 <acquire>
    log.committing = 0;
    800057ec:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800057f0:	8526                	mv	a0,s1
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	8a2080e7          	jalr	-1886(ra) # 80003094 <wakeup>
    release(&log.lock);
    800057fa:	8526                	mv	a0,s1
    800057fc:	ffffb097          	auipc	ra,0xffffb
    80005800:	49c080e7          	jalr	1180(ra) # 80000c98 <release>
}
    80005804:	70e2                	ld	ra,56(sp)
    80005806:	7442                	ld	s0,48(sp)
    80005808:	74a2                	ld	s1,40(sp)
    8000580a:	7902                	ld	s2,32(sp)
    8000580c:	69e2                	ld	s3,24(sp)
    8000580e:	6a42                	ld	s4,16(sp)
    80005810:	6aa2                	ld	s5,8(sp)
    80005812:	6121                	addi	sp,sp,64
    80005814:	8082                	ret
    panic("log.committing");
    80005816:	00004517          	auipc	a0,0x4
    8000581a:	21a50513          	addi	a0,a0,538 # 80009a30 <syscalls+0x208>
    8000581e:	ffffb097          	auipc	ra,0xffffb
    80005822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>
    wakeup(&log);
    80005826:	0001d497          	auipc	s1,0x1d
    8000582a:	6ea48493          	addi	s1,s1,1770 # 80022f10 <log>
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	864080e7          	jalr	-1948(ra) # 80003094 <wakeup>
  release(&log.lock);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffb097          	auipc	ra,0xffffb
    8000583e:	45e080e7          	jalr	1118(ra) # 80000c98 <release>
  if(do_commit){
    80005842:	b7c9                	j	80005804 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005844:	0001da97          	auipc	s5,0x1d
    80005848:	6fca8a93          	addi	s5,s5,1788 # 80022f40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000584c:	0001da17          	auipc	s4,0x1d
    80005850:	6c4a0a13          	addi	s4,s4,1732 # 80022f10 <log>
    80005854:	018a2583          	lw	a1,24(s4)
    80005858:	012585bb          	addw	a1,a1,s2
    8000585c:	2585                	addiw	a1,a1,1
    8000585e:	028a2503          	lw	a0,40(s4)
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	cd2080e7          	jalr	-814(ra) # 80004534 <bread>
    8000586a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000586c:	000aa583          	lw	a1,0(s5)
    80005870:	028a2503          	lw	a0,40(s4)
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	cc0080e7          	jalr	-832(ra) # 80004534 <bread>
    8000587c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000587e:	40000613          	li	a2,1024
    80005882:	05850593          	addi	a1,a0,88
    80005886:	05848513          	addi	a0,s1,88
    8000588a:	ffffb097          	auipc	ra,0xffffb
    8000588e:	4b6080e7          	jalr	1206(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80005892:	8526                	mv	a0,s1
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	d92080e7          	jalr	-622(ra) # 80004626 <bwrite>
    brelse(from);
    8000589c:	854e                	mv	a0,s3
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	dc6080e7          	jalr	-570(ra) # 80004664 <brelse>
    brelse(to);
    800058a6:	8526                	mv	a0,s1
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	dbc080e7          	jalr	-580(ra) # 80004664 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800058b0:	2905                	addiw	s2,s2,1
    800058b2:	0a91                	addi	s5,s5,4
    800058b4:	02ca2783          	lw	a5,44(s4)
    800058b8:	f8f94ee3          	blt	s2,a5,80005854 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800058bc:	00000097          	auipc	ra,0x0
    800058c0:	c6a080e7          	jalr	-918(ra) # 80005526 <write_head>
    install_trans(0); // Now install writes to home locations
    800058c4:	4501                	li	a0,0
    800058c6:	00000097          	auipc	ra,0x0
    800058ca:	cda080e7          	jalr	-806(ra) # 800055a0 <install_trans>
    log.lh.n = 0;
    800058ce:	0001d797          	auipc	a5,0x1d
    800058d2:	6607a723          	sw	zero,1646(a5) # 80022f3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800058d6:	00000097          	auipc	ra,0x0
    800058da:	c50080e7          	jalr	-944(ra) # 80005526 <write_head>
    800058de:	bdf5                	j	800057da <end_op+0x52>

00000000800058e0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800058e0:	1101                	addi	sp,sp,-32
    800058e2:	ec06                	sd	ra,24(sp)
    800058e4:	e822                	sd	s0,16(sp)
    800058e6:	e426                	sd	s1,8(sp)
    800058e8:	e04a                	sd	s2,0(sp)
    800058ea:	1000                	addi	s0,sp,32
    800058ec:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800058ee:	0001d917          	auipc	s2,0x1d
    800058f2:	62290913          	addi	s2,s2,1570 # 80022f10 <log>
    800058f6:	854a                	mv	a0,s2
    800058f8:	ffffb097          	auipc	ra,0xffffb
    800058fc:	2ec080e7          	jalr	748(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80005900:	02c92603          	lw	a2,44(s2)
    80005904:	47f5                	li	a5,29
    80005906:	06c7c563          	blt	a5,a2,80005970 <log_write+0x90>
    8000590a:	0001d797          	auipc	a5,0x1d
    8000590e:	6227a783          	lw	a5,1570(a5) # 80022f2c <log+0x1c>
    80005912:	37fd                	addiw	a5,a5,-1
    80005914:	04f65e63          	bge	a2,a5,80005970 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005918:	0001d797          	auipc	a5,0x1d
    8000591c:	6187a783          	lw	a5,1560(a5) # 80022f30 <log+0x20>
    80005920:	06f05063          	blez	a5,80005980 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80005924:	4781                	li	a5,0
    80005926:	06c05563          	blez	a2,80005990 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000592a:	44cc                	lw	a1,12(s1)
    8000592c:	0001d717          	auipc	a4,0x1d
    80005930:	61470713          	addi	a4,a4,1556 # 80022f40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80005934:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005936:	4314                	lw	a3,0(a4)
    80005938:	04b68c63          	beq	a3,a1,80005990 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000593c:	2785                	addiw	a5,a5,1
    8000593e:	0711                	addi	a4,a4,4
    80005940:	fef61be3          	bne	a2,a5,80005936 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80005944:	0621                	addi	a2,a2,8
    80005946:	060a                	slli	a2,a2,0x2
    80005948:	0001d797          	auipc	a5,0x1d
    8000594c:	5c878793          	addi	a5,a5,1480 # 80022f10 <log>
    80005950:	963e                	add	a2,a2,a5
    80005952:	44dc                	lw	a5,12(s1)
    80005954:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005956:	8526                	mv	a0,s1
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	daa080e7          	jalr	-598(ra) # 80004702 <bpin>
    log.lh.n++;
    80005960:	0001d717          	auipc	a4,0x1d
    80005964:	5b070713          	addi	a4,a4,1456 # 80022f10 <log>
    80005968:	575c                	lw	a5,44(a4)
    8000596a:	2785                	addiw	a5,a5,1
    8000596c:	d75c                	sw	a5,44(a4)
    8000596e:	a835                	j	800059aa <log_write+0xca>
    panic("too big a transaction");
    80005970:	00004517          	auipc	a0,0x4
    80005974:	0d050513          	addi	a0,a0,208 # 80009a40 <syscalls+0x218>
    80005978:	ffffb097          	auipc	ra,0xffffb
    8000597c:	bc6080e7          	jalr	-1082(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80005980:	00004517          	auipc	a0,0x4
    80005984:	0d850513          	addi	a0,a0,216 # 80009a58 <syscalls+0x230>
    80005988:	ffffb097          	auipc	ra,0xffffb
    8000598c:	bb6080e7          	jalr	-1098(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80005990:	00878713          	addi	a4,a5,8
    80005994:	00271693          	slli	a3,a4,0x2
    80005998:	0001d717          	auipc	a4,0x1d
    8000599c:	57870713          	addi	a4,a4,1400 # 80022f10 <log>
    800059a0:	9736                	add	a4,a4,a3
    800059a2:	44d4                	lw	a3,12(s1)
    800059a4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800059a6:	faf608e3          	beq	a2,a5,80005956 <log_write+0x76>
  }
  release(&log.lock);
    800059aa:	0001d517          	auipc	a0,0x1d
    800059ae:	56650513          	addi	a0,a0,1382 # 80022f10 <log>
    800059b2:	ffffb097          	auipc	ra,0xffffb
    800059b6:	2e6080e7          	jalr	742(ra) # 80000c98 <release>
}
    800059ba:	60e2                	ld	ra,24(sp)
    800059bc:	6442                	ld	s0,16(sp)
    800059be:	64a2                	ld	s1,8(sp)
    800059c0:	6902                	ld	s2,0(sp)
    800059c2:	6105                	addi	sp,sp,32
    800059c4:	8082                	ret

00000000800059c6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800059c6:	1101                	addi	sp,sp,-32
    800059c8:	ec06                	sd	ra,24(sp)
    800059ca:	e822                	sd	s0,16(sp)
    800059cc:	e426                	sd	s1,8(sp)
    800059ce:	e04a                	sd	s2,0(sp)
    800059d0:	1000                	addi	s0,sp,32
    800059d2:	84aa                	mv	s1,a0
    800059d4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800059d6:	00004597          	auipc	a1,0x4
    800059da:	0a258593          	addi	a1,a1,162 # 80009a78 <syscalls+0x250>
    800059de:	0521                	addi	a0,a0,8
    800059e0:	ffffb097          	auipc	ra,0xffffb
    800059e4:	174080e7          	jalr	372(ra) # 80000b54 <initlock>
  lk->name = name;
    800059e8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800059ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800059f0:	0204a423          	sw	zero,40(s1)
}
    800059f4:	60e2                	ld	ra,24(sp)
    800059f6:	6442                	ld	s0,16(sp)
    800059f8:	64a2                	ld	s1,8(sp)
    800059fa:	6902                	ld	s2,0(sp)
    800059fc:	6105                	addi	sp,sp,32
    800059fe:	8082                	ret

0000000080005a00 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005a00:	1101                	addi	sp,sp,-32
    80005a02:	ec06                	sd	ra,24(sp)
    80005a04:	e822                	sd	s0,16(sp)
    80005a06:	e426                	sd	s1,8(sp)
    80005a08:	e04a                	sd	s2,0(sp)
    80005a0a:	1000                	addi	s0,sp,32
    80005a0c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005a0e:	00850913          	addi	s2,a0,8
    80005a12:	854a                	mv	a0,s2
    80005a14:	ffffb097          	auipc	ra,0xffffb
    80005a18:	1d0080e7          	jalr	464(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80005a1c:	409c                	lw	a5,0(s1)
    80005a1e:	cb89                	beqz	a5,80005a30 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005a20:	85ca                	mv	a1,s2
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	25a080e7          	jalr	602(ra) # 80002c7e <sleep>
  while (lk->locked) {
    80005a2c:	409c                	lw	a5,0(s1)
    80005a2e:	fbed                	bnez	a5,80005a20 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005a30:	4785                	li	a5,1
    80005a32:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005a34:	ffffc097          	auipc	ra,0xffffc
    80005a38:	160080e7          	jalr	352(ra) # 80001b94 <myproc>
    80005a3c:	591c                	lw	a5,48(a0)
    80005a3e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005a40:	854a                	mv	a0,s2
    80005a42:	ffffb097          	auipc	ra,0xffffb
    80005a46:	256080e7          	jalr	598(ra) # 80000c98 <release>
}
    80005a4a:	60e2                	ld	ra,24(sp)
    80005a4c:	6442                	ld	s0,16(sp)
    80005a4e:	64a2                	ld	s1,8(sp)
    80005a50:	6902                	ld	s2,0(sp)
    80005a52:	6105                	addi	sp,sp,32
    80005a54:	8082                	ret

0000000080005a56 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005a56:	1101                	addi	sp,sp,-32
    80005a58:	ec06                	sd	ra,24(sp)
    80005a5a:	e822                	sd	s0,16(sp)
    80005a5c:	e426                	sd	s1,8(sp)
    80005a5e:	e04a                	sd	s2,0(sp)
    80005a60:	1000                	addi	s0,sp,32
    80005a62:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005a64:	00850913          	addi	s2,a0,8
    80005a68:	854a                	mv	a0,s2
    80005a6a:	ffffb097          	auipc	ra,0xffffb
    80005a6e:	17a080e7          	jalr	378(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80005a72:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005a76:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005a7a:	8526                	mv	a0,s1
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	618080e7          	jalr	1560(ra) # 80003094 <wakeup>
  release(&lk->lk);
    80005a84:	854a                	mv	a0,s2
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	212080e7          	jalr	530(ra) # 80000c98 <release>
}
    80005a8e:	60e2                	ld	ra,24(sp)
    80005a90:	6442                	ld	s0,16(sp)
    80005a92:	64a2                	ld	s1,8(sp)
    80005a94:	6902                	ld	s2,0(sp)
    80005a96:	6105                	addi	sp,sp,32
    80005a98:	8082                	ret

0000000080005a9a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005a9a:	7179                	addi	sp,sp,-48
    80005a9c:	f406                	sd	ra,40(sp)
    80005a9e:	f022                	sd	s0,32(sp)
    80005aa0:	ec26                	sd	s1,24(sp)
    80005aa2:	e84a                	sd	s2,16(sp)
    80005aa4:	e44e                	sd	s3,8(sp)
    80005aa6:	1800                	addi	s0,sp,48
    80005aa8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005aaa:	00850913          	addi	s2,a0,8
    80005aae:	854a                	mv	a0,s2
    80005ab0:	ffffb097          	auipc	ra,0xffffb
    80005ab4:	134080e7          	jalr	308(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005ab8:	409c                	lw	a5,0(s1)
    80005aba:	ef99                	bnez	a5,80005ad8 <holdingsleep+0x3e>
    80005abc:	4481                	li	s1,0
  release(&lk->lk);
    80005abe:	854a                	mv	a0,s2
    80005ac0:	ffffb097          	auipc	ra,0xffffb
    80005ac4:	1d8080e7          	jalr	472(ra) # 80000c98 <release>
  return r;
}
    80005ac8:	8526                	mv	a0,s1
    80005aca:	70a2                	ld	ra,40(sp)
    80005acc:	7402                	ld	s0,32(sp)
    80005ace:	64e2                	ld	s1,24(sp)
    80005ad0:	6942                	ld	s2,16(sp)
    80005ad2:	69a2                	ld	s3,8(sp)
    80005ad4:	6145                	addi	sp,sp,48
    80005ad6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005ad8:	0284a983          	lw	s3,40(s1)
    80005adc:	ffffc097          	auipc	ra,0xffffc
    80005ae0:	0b8080e7          	jalr	184(ra) # 80001b94 <myproc>
    80005ae4:	5904                	lw	s1,48(a0)
    80005ae6:	413484b3          	sub	s1,s1,s3
    80005aea:	0014b493          	seqz	s1,s1
    80005aee:	bfc1                	j	80005abe <holdingsleep+0x24>

0000000080005af0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005af0:	1141                	addi	sp,sp,-16
    80005af2:	e406                	sd	ra,8(sp)
    80005af4:	e022                	sd	s0,0(sp)
    80005af6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005af8:	00004597          	auipc	a1,0x4
    80005afc:	f9058593          	addi	a1,a1,-112 # 80009a88 <syscalls+0x260>
    80005b00:	0001d517          	auipc	a0,0x1d
    80005b04:	55850513          	addi	a0,a0,1368 # 80023058 <ftable>
    80005b08:	ffffb097          	auipc	ra,0xffffb
    80005b0c:	04c080e7          	jalr	76(ra) # 80000b54 <initlock>
}
    80005b10:	60a2                	ld	ra,8(sp)
    80005b12:	6402                	ld	s0,0(sp)
    80005b14:	0141                	addi	sp,sp,16
    80005b16:	8082                	ret

0000000080005b18 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005b18:	1101                	addi	sp,sp,-32
    80005b1a:	ec06                	sd	ra,24(sp)
    80005b1c:	e822                	sd	s0,16(sp)
    80005b1e:	e426                	sd	s1,8(sp)
    80005b20:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005b22:	0001d517          	auipc	a0,0x1d
    80005b26:	53650513          	addi	a0,a0,1334 # 80023058 <ftable>
    80005b2a:	ffffb097          	auipc	ra,0xffffb
    80005b2e:	0ba080e7          	jalr	186(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005b32:	0001d497          	auipc	s1,0x1d
    80005b36:	53e48493          	addi	s1,s1,1342 # 80023070 <ftable+0x18>
    80005b3a:	0001e717          	auipc	a4,0x1e
    80005b3e:	4d670713          	addi	a4,a4,1238 # 80024010 <ftable+0xfb8>
    if(f->ref == 0){
    80005b42:	40dc                	lw	a5,4(s1)
    80005b44:	cf99                	beqz	a5,80005b62 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005b46:	02848493          	addi	s1,s1,40
    80005b4a:	fee49ce3          	bne	s1,a4,80005b42 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005b4e:	0001d517          	auipc	a0,0x1d
    80005b52:	50a50513          	addi	a0,a0,1290 # 80023058 <ftable>
    80005b56:	ffffb097          	auipc	ra,0xffffb
    80005b5a:	142080e7          	jalr	322(ra) # 80000c98 <release>
  return 0;
    80005b5e:	4481                	li	s1,0
    80005b60:	a819                	j	80005b76 <filealloc+0x5e>
      f->ref = 1;
    80005b62:	4785                	li	a5,1
    80005b64:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005b66:	0001d517          	auipc	a0,0x1d
    80005b6a:	4f250513          	addi	a0,a0,1266 # 80023058 <ftable>
    80005b6e:	ffffb097          	auipc	ra,0xffffb
    80005b72:	12a080e7          	jalr	298(ra) # 80000c98 <release>
}
    80005b76:	8526                	mv	a0,s1
    80005b78:	60e2                	ld	ra,24(sp)
    80005b7a:	6442                	ld	s0,16(sp)
    80005b7c:	64a2                	ld	s1,8(sp)
    80005b7e:	6105                	addi	sp,sp,32
    80005b80:	8082                	ret

0000000080005b82 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005b82:	1101                	addi	sp,sp,-32
    80005b84:	ec06                	sd	ra,24(sp)
    80005b86:	e822                	sd	s0,16(sp)
    80005b88:	e426                	sd	s1,8(sp)
    80005b8a:	1000                	addi	s0,sp,32
    80005b8c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005b8e:	0001d517          	auipc	a0,0x1d
    80005b92:	4ca50513          	addi	a0,a0,1226 # 80023058 <ftable>
    80005b96:	ffffb097          	auipc	ra,0xffffb
    80005b9a:	04e080e7          	jalr	78(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005b9e:	40dc                	lw	a5,4(s1)
    80005ba0:	02f05263          	blez	a5,80005bc4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005ba4:	2785                	addiw	a5,a5,1
    80005ba6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005ba8:	0001d517          	auipc	a0,0x1d
    80005bac:	4b050513          	addi	a0,a0,1200 # 80023058 <ftable>
    80005bb0:	ffffb097          	auipc	ra,0xffffb
    80005bb4:	0e8080e7          	jalr	232(ra) # 80000c98 <release>
  return f;
}
    80005bb8:	8526                	mv	a0,s1
    80005bba:	60e2                	ld	ra,24(sp)
    80005bbc:	6442                	ld	s0,16(sp)
    80005bbe:	64a2                	ld	s1,8(sp)
    80005bc0:	6105                	addi	sp,sp,32
    80005bc2:	8082                	ret
    panic("filedup");
    80005bc4:	00004517          	auipc	a0,0x4
    80005bc8:	ecc50513          	addi	a0,a0,-308 # 80009a90 <syscalls+0x268>
    80005bcc:	ffffb097          	auipc	ra,0xffffb
    80005bd0:	972080e7          	jalr	-1678(ra) # 8000053e <panic>

0000000080005bd4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005bd4:	7139                	addi	sp,sp,-64
    80005bd6:	fc06                	sd	ra,56(sp)
    80005bd8:	f822                	sd	s0,48(sp)
    80005bda:	f426                	sd	s1,40(sp)
    80005bdc:	f04a                	sd	s2,32(sp)
    80005bde:	ec4e                	sd	s3,24(sp)
    80005be0:	e852                	sd	s4,16(sp)
    80005be2:	e456                	sd	s5,8(sp)
    80005be4:	0080                	addi	s0,sp,64
    80005be6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005be8:	0001d517          	auipc	a0,0x1d
    80005bec:	47050513          	addi	a0,a0,1136 # 80023058 <ftable>
    80005bf0:	ffffb097          	auipc	ra,0xffffb
    80005bf4:	ff4080e7          	jalr	-12(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005bf8:	40dc                	lw	a5,4(s1)
    80005bfa:	06f05163          	blez	a5,80005c5c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005bfe:	37fd                	addiw	a5,a5,-1
    80005c00:	0007871b          	sext.w	a4,a5
    80005c04:	c0dc                	sw	a5,4(s1)
    80005c06:	06e04363          	bgtz	a4,80005c6c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005c0a:	0004a903          	lw	s2,0(s1)
    80005c0e:	0094ca83          	lbu	s5,9(s1)
    80005c12:	0104ba03          	ld	s4,16(s1)
    80005c16:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005c1a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005c1e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005c22:	0001d517          	auipc	a0,0x1d
    80005c26:	43650513          	addi	a0,a0,1078 # 80023058 <ftable>
    80005c2a:	ffffb097          	auipc	ra,0xffffb
    80005c2e:	06e080e7          	jalr	110(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80005c32:	4785                	li	a5,1
    80005c34:	04f90d63          	beq	s2,a5,80005c8e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005c38:	3979                	addiw	s2,s2,-2
    80005c3a:	4785                	li	a5,1
    80005c3c:	0527e063          	bltu	a5,s2,80005c7c <fileclose+0xa8>
    begin_op();
    80005c40:	00000097          	auipc	ra,0x0
    80005c44:	ac8080e7          	jalr	-1336(ra) # 80005708 <begin_op>
    iput(ff.ip);
    80005c48:	854e                	mv	a0,s3
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	2a6080e7          	jalr	678(ra) # 80004ef0 <iput>
    end_op();
    80005c52:	00000097          	auipc	ra,0x0
    80005c56:	b36080e7          	jalr	-1226(ra) # 80005788 <end_op>
    80005c5a:	a00d                	j	80005c7c <fileclose+0xa8>
    panic("fileclose");
    80005c5c:	00004517          	auipc	a0,0x4
    80005c60:	e3c50513          	addi	a0,a0,-452 # 80009a98 <syscalls+0x270>
    80005c64:	ffffb097          	auipc	ra,0xffffb
    80005c68:	8da080e7          	jalr	-1830(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005c6c:	0001d517          	auipc	a0,0x1d
    80005c70:	3ec50513          	addi	a0,a0,1004 # 80023058 <ftable>
    80005c74:	ffffb097          	auipc	ra,0xffffb
    80005c78:	024080e7          	jalr	36(ra) # 80000c98 <release>
  }
}
    80005c7c:	70e2                	ld	ra,56(sp)
    80005c7e:	7442                	ld	s0,48(sp)
    80005c80:	74a2                	ld	s1,40(sp)
    80005c82:	7902                	ld	s2,32(sp)
    80005c84:	69e2                	ld	s3,24(sp)
    80005c86:	6a42                	ld	s4,16(sp)
    80005c88:	6aa2                	ld	s5,8(sp)
    80005c8a:	6121                	addi	sp,sp,64
    80005c8c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005c8e:	85d6                	mv	a1,s5
    80005c90:	8552                	mv	a0,s4
    80005c92:	00000097          	auipc	ra,0x0
    80005c96:	34c080e7          	jalr	844(ra) # 80005fde <pipeclose>
    80005c9a:	b7cd                	j	80005c7c <fileclose+0xa8>

0000000080005c9c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005c9c:	715d                	addi	sp,sp,-80
    80005c9e:	e486                	sd	ra,72(sp)
    80005ca0:	e0a2                	sd	s0,64(sp)
    80005ca2:	fc26                	sd	s1,56(sp)
    80005ca4:	f84a                	sd	s2,48(sp)
    80005ca6:	f44e                	sd	s3,40(sp)
    80005ca8:	0880                	addi	s0,sp,80
    80005caa:	84aa                	mv	s1,a0
    80005cac:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005cae:	ffffc097          	auipc	ra,0xffffc
    80005cb2:	ee6080e7          	jalr	-282(ra) # 80001b94 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005cb6:	409c                	lw	a5,0(s1)
    80005cb8:	37f9                	addiw	a5,a5,-2
    80005cba:	4705                	li	a4,1
    80005cbc:	04f76763          	bltu	a4,a5,80005d0a <filestat+0x6e>
    80005cc0:	892a                	mv	s2,a0
    ilock(f->ip);
    80005cc2:	6c88                	ld	a0,24(s1)
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	072080e7          	jalr	114(ra) # 80004d36 <ilock>
    stati(f->ip, &st);
    80005ccc:	fb840593          	addi	a1,s0,-72
    80005cd0:	6c88                	ld	a0,24(s1)
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	2ee080e7          	jalr	750(ra) # 80004fc0 <stati>
    iunlock(f->ip);
    80005cda:	6c88                	ld	a0,24(s1)
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	11c080e7          	jalr	284(ra) # 80004df8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005ce4:	46e1                	li	a3,24
    80005ce6:	fb840613          	addi	a2,s0,-72
    80005cea:	85ce                	mv	a1,s3
    80005cec:	08093503          	ld	a0,128(s2)
    80005cf0:	ffffc097          	auipc	ra,0xffffc
    80005cf4:	98a080e7          	jalr	-1654(ra) # 8000167a <copyout>
    80005cf8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005cfc:	60a6                	ld	ra,72(sp)
    80005cfe:	6406                	ld	s0,64(sp)
    80005d00:	74e2                	ld	s1,56(sp)
    80005d02:	7942                	ld	s2,48(sp)
    80005d04:	79a2                	ld	s3,40(sp)
    80005d06:	6161                	addi	sp,sp,80
    80005d08:	8082                	ret
  return -1;
    80005d0a:	557d                	li	a0,-1
    80005d0c:	bfc5                	j	80005cfc <filestat+0x60>

0000000080005d0e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005d0e:	7179                	addi	sp,sp,-48
    80005d10:	f406                	sd	ra,40(sp)
    80005d12:	f022                	sd	s0,32(sp)
    80005d14:	ec26                	sd	s1,24(sp)
    80005d16:	e84a                	sd	s2,16(sp)
    80005d18:	e44e                	sd	s3,8(sp)
    80005d1a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005d1c:	00854783          	lbu	a5,8(a0)
    80005d20:	c3d5                	beqz	a5,80005dc4 <fileread+0xb6>
    80005d22:	84aa                	mv	s1,a0
    80005d24:	89ae                	mv	s3,a1
    80005d26:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005d28:	411c                	lw	a5,0(a0)
    80005d2a:	4705                	li	a4,1
    80005d2c:	04e78963          	beq	a5,a4,80005d7e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005d30:	470d                	li	a4,3
    80005d32:	04e78d63          	beq	a5,a4,80005d8c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005d36:	4709                	li	a4,2
    80005d38:	06e79e63          	bne	a5,a4,80005db4 <fileread+0xa6>
    ilock(f->ip);
    80005d3c:	6d08                	ld	a0,24(a0)
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	ff8080e7          	jalr	-8(ra) # 80004d36 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005d46:	874a                	mv	a4,s2
    80005d48:	5094                	lw	a3,32(s1)
    80005d4a:	864e                	mv	a2,s3
    80005d4c:	4585                	li	a1,1
    80005d4e:	6c88                	ld	a0,24(s1)
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	29a080e7          	jalr	666(ra) # 80004fea <readi>
    80005d58:	892a                	mv	s2,a0
    80005d5a:	00a05563          	blez	a0,80005d64 <fileread+0x56>
      f->off += r;
    80005d5e:	509c                	lw	a5,32(s1)
    80005d60:	9fa9                	addw	a5,a5,a0
    80005d62:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005d64:	6c88                	ld	a0,24(s1)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	092080e7          	jalr	146(ra) # 80004df8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005d6e:	854a                	mv	a0,s2
    80005d70:	70a2                	ld	ra,40(sp)
    80005d72:	7402                	ld	s0,32(sp)
    80005d74:	64e2                	ld	s1,24(sp)
    80005d76:	6942                	ld	s2,16(sp)
    80005d78:	69a2                	ld	s3,8(sp)
    80005d7a:	6145                	addi	sp,sp,48
    80005d7c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005d7e:	6908                	ld	a0,16(a0)
    80005d80:	00000097          	auipc	ra,0x0
    80005d84:	3c8080e7          	jalr	968(ra) # 80006148 <piperead>
    80005d88:	892a                	mv	s2,a0
    80005d8a:	b7d5                	j	80005d6e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005d8c:	02451783          	lh	a5,36(a0)
    80005d90:	03079693          	slli	a3,a5,0x30
    80005d94:	92c1                	srli	a3,a3,0x30
    80005d96:	4725                	li	a4,9
    80005d98:	02d76863          	bltu	a4,a3,80005dc8 <fileread+0xba>
    80005d9c:	0792                	slli	a5,a5,0x4
    80005d9e:	0001d717          	auipc	a4,0x1d
    80005da2:	21a70713          	addi	a4,a4,538 # 80022fb8 <devsw>
    80005da6:	97ba                	add	a5,a5,a4
    80005da8:	639c                	ld	a5,0(a5)
    80005daa:	c38d                	beqz	a5,80005dcc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005dac:	4505                	li	a0,1
    80005dae:	9782                	jalr	a5
    80005db0:	892a                	mv	s2,a0
    80005db2:	bf75                	j	80005d6e <fileread+0x60>
    panic("fileread");
    80005db4:	00004517          	auipc	a0,0x4
    80005db8:	cf450513          	addi	a0,a0,-780 # 80009aa8 <syscalls+0x280>
    80005dbc:	ffffa097          	auipc	ra,0xffffa
    80005dc0:	782080e7          	jalr	1922(ra) # 8000053e <panic>
    return -1;
    80005dc4:	597d                	li	s2,-1
    80005dc6:	b765                	j	80005d6e <fileread+0x60>
      return -1;
    80005dc8:	597d                	li	s2,-1
    80005dca:	b755                	j	80005d6e <fileread+0x60>
    80005dcc:	597d                	li	s2,-1
    80005dce:	b745                	j	80005d6e <fileread+0x60>

0000000080005dd0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005dd0:	715d                	addi	sp,sp,-80
    80005dd2:	e486                	sd	ra,72(sp)
    80005dd4:	e0a2                	sd	s0,64(sp)
    80005dd6:	fc26                	sd	s1,56(sp)
    80005dd8:	f84a                	sd	s2,48(sp)
    80005dda:	f44e                	sd	s3,40(sp)
    80005ddc:	f052                	sd	s4,32(sp)
    80005dde:	ec56                	sd	s5,24(sp)
    80005de0:	e85a                	sd	s6,16(sp)
    80005de2:	e45e                	sd	s7,8(sp)
    80005de4:	e062                	sd	s8,0(sp)
    80005de6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005de8:	00954783          	lbu	a5,9(a0)
    80005dec:	10078663          	beqz	a5,80005ef8 <filewrite+0x128>
    80005df0:	892a                	mv	s2,a0
    80005df2:	8aae                	mv	s5,a1
    80005df4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005df6:	411c                	lw	a5,0(a0)
    80005df8:	4705                	li	a4,1
    80005dfa:	02e78263          	beq	a5,a4,80005e1e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005dfe:	470d                	li	a4,3
    80005e00:	02e78663          	beq	a5,a4,80005e2c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005e04:	4709                	li	a4,2
    80005e06:	0ee79163          	bne	a5,a4,80005ee8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005e0a:	0ac05d63          	blez	a2,80005ec4 <filewrite+0xf4>
    int i = 0;
    80005e0e:	4981                	li	s3,0
    80005e10:	6b05                	lui	s6,0x1
    80005e12:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005e16:	6b85                	lui	s7,0x1
    80005e18:	c00b8b9b          	addiw	s7,s7,-1024
    80005e1c:	a861                	j	80005eb4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005e1e:	6908                	ld	a0,16(a0)
    80005e20:	00000097          	auipc	ra,0x0
    80005e24:	22e080e7          	jalr	558(ra) # 8000604e <pipewrite>
    80005e28:	8a2a                	mv	s4,a0
    80005e2a:	a045                	j	80005eca <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005e2c:	02451783          	lh	a5,36(a0)
    80005e30:	03079693          	slli	a3,a5,0x30
    80005e34:	92c1                	srli	a3,a3,0x30
    80005e36:	4725                	li	a4,9
    80005e38:	0cd76263          	bltu	a4,a3,80005efc <filewrite+0x12c>
    80005e3c:	0792                	slli	a5,a5,0x4
    80005e3e:	0001d717          	auipc	a4,0x1d
    80005e42:	17a70713          	addi	a4,a4,378 # 80022fb8 <devsw>
    80005e46:	97ba                	add	a5,a5,a4
    80005e48:	679c                	ld	a5,8(a5)
    80005e4a:	cbdd                	beqz	a5,80005f00 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005e4c:	4505                	li	a0,1
    80005e4e:	9782                	jalr	a5
    80005e50:	8a2a                	mv	s4,a0
    80005e52:	a8a5                	j	80005eca <filewrite+0xfa>
    80005e54:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005e58:	00000097          	auipc	ra,0x0
    80005e5c:	8b0080e7          	jalr	-1872(ra) # 80005708 <begin_op>
      ilock(f->ip);
    80005e60:	01893503          	ld	a0,24(s2)
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	ed2080e7          	jalr	-302(ra) # 80004d36 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005e6c:	8762                	mv	a4,s8
    80005e6e:	02092683          	lw	a3,32(s2)
    80005e72:	01598633          	add	a2,s3,s5
    80005e76:	4585                	li	a1,1
    80005e78:	01893503          	ld	a0,24(s2)
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	266080e7          	jalr	614(ra) # 800050e2 <writei>
    80005e84:	84aa                	mv	s1,a0
    80005e86:	00a05763          	blez	a0,80005e94 <filewrite+0xc4>
        f->off += r;
    80005e8a:	02092783          	lw	a5,32(s2)
    80005e8e:	9fa9                	addw	a5,a5,a0
    80005e90:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005e94:	01893503          	ld	a0,24(s2)
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	f60080e7          	jalr	-160(ra) # 80004df8 <iunlock>
      end_op();
    80005ea0:	00000097          	auipc	ra,0x0
    80005ea4:	8e8080e7          	jalr	-1816(ra) # 80005788 <end_op>

      if(r != n1){
    80005ea8:	009c1f63          	bne	s8,s1,80005ec6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005eac:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005eb0:	0149db63          	bge	s3,s4,80005ec6 <filewrite+0xf6>
      int n1 = n - i;
    80005eb4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005eb8:	84be                	mv	s1,a5
    80005eba:	2781                	sext.w	a5,a5
    80005ebc:	f8fb5ce3          	bge	s6,a5,80005e54 <filewrite+0x84>
    80005ec0:	84de                	mv	s1,s7
    80005ec2:	bf49                	j	80005e54 <filewrite+0x84>
    int i = 0;
    80005ec4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005ec6:	013a1f63          	bne	s4,s3,80005ee4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005eca:	8552                	mv	a0,s4
    80005ecc:	60a6                	ld	ra,72(sp)
    80005ece:	6406                	ld	s0,64(sp)
    80005ed0:	74e2                	ld	s1,56(sp)
    80005ed2:	7942                	ld	s2,48(sp)
    80005ed4:	79a2                	ld	s3,40(sp)
    80005ed6:	7a02                	ld	s4,32(sp)
    80005ed8:	6ae2                	ld	s5,24(sp)
    80005eda:	6b42                	ld	s6,16(sp)
    80005edc:	6ba2                	ld	s7,8(sp)
    80005ede:	6c02                	ld	s8,0(sp)
    80005ee0:	6161                	addi	sp,sp,80
    80005ee2:	8082                	ret
    ret = (i == n ? n : -1);
    80005ee4:	5a7d                	li	s4,-1
    80005ee6:	b7d5                	j	80005eca <filewrite+0xfa>
    panic("filewrite");
    80005ee8:	00004517          	auipc	a0,0x4
    80005eec:	bd050513          	addi	a0,a0,-1072 # 80009ab8 <syscalls+0x290>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	64e080e7          	jalr	1614(ra) # 8000053e <panic>
    return -1;
    80005ef8:	5a7d                	li	s4,-1
    80005efa:	bfc1                	j	80005eca <filewrite+0xfa>
      return -1;
    80005efc:	5a7d                	li	s4,-1
    80005efe:	b7f1                	j	80005eca <filewrite+0xfa>
    80005f00:	5a7d                	li	s4,-1
    80005f02:	b7e1                	j	80005eca <filewrite+0xfa>

0000000080005f04 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005f04:	7179                	addi	sp,sp,-48
    80005f06:	f406                	sd	ra,40(sp)
    80005f08:	f022                	sd	s0,32(sp)
    80005f0a:	ec26                	sd	s1,24(sp)
    80005f0c:	e84a                	sd	s2,16(sp)
    80005f0e:	e44e                	sd	s3,8(sp)
    80005f10:	e052                	sd	s4,0(sp)
    80005f12:	1800                	addi	s0,sp,48
    80005f14:	84aa                	mv	s1,a0
    80005f16:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005f18:	0005b023          	sd	zero,0(a1)
    80005f1c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005f20:	00000097          	auipc	ra,0x0
    80005f24:	bf8080e7          	jalr	-1032(ra) # 80005b18 <filealloc>
    80005f28:	e088                	sd	a0,0(s1)
    80005f2a:	c551                	beqz	a0,80005fb6 <pipealloc+0xb2>
    80005f2c:	00000097          	auipc	ra,0x0
    80005f30:	bec080e7          	jalr	-1044(ra) # 80005b18 <filealloc>
    80005f34:	00aa3023          	sd	a0,0(s4)
    80005f38:	c92d                	beqz	a0,80005faa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005f3a:	ffffb097          	auipc	ra,0xffffb
    80005f3e:	bba080e7          	jalr	-1094(ra) # 80000af4 <kalloc>
    80005f42:	892a                	mv	s2,a0
    80005f44:	c125                	beqz	a0,80005fa4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005f46:	4985                	li	s3,1
    80005f48:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005f4c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005f50:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005f54:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005f58:	00004597          	auipc	a1,0x4
    80005f5c:	b7058593          	addi	a1,a1,-1168 # 80009ac8 <syscalls+0x2a0>
    80005f60:	ffffb097          	auipc	ra,0xffffb
    80005f64:	bf4080e7          	jalr	-1036(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005f68:	609c                	ld	a5,0(s1)
    80005f6a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005f6e:	609c                	ld	a5,0(s1)
    80005f70:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005f74:	609c                	ld	a5,0(s1)
    80005f76:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005f7a:	609c                	ld	a5,0(s1)
    80005f7c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005f80:	000a3783          	ld	a5,0(s4)
    80005f84:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005f88:	000a3783          	ld	a5,0(s4)
    80005f8c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005f90:	000a3783          	ld	a5,0(s4)
    80005f94:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005f98:	000a3783          	ld	a5,0(s4)
    80005f9c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005fa0:	4501                	li	a0,0
    80005fa2:	a025                	j	80005fca <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005fa4:	6088                	ld	a0,0(s1)
    80005fa6:	e501                	bnez	a0,80005fae <pipealloc+0xaa>
    80005fa8:	a039                	j	80005fb6 <pipealloc+0xb2>
    80005faa:	6088                	ld	a0,0(s1)
    80005fac:	c51d                	beqz	a0,80005fda <pipealloc+0xd6>
    fileclose(*f0);
    80005fae:	00000097          	auipc	ra,0x0
    80005fb2:	c26080e7          	jalr	-986(ra) # 80005bd4 <fileclose>
  if(*f1)
    80005fb6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005fba:	557d                	li	a0,-1
  if(*f1)
    80005fbc:	c799                	beqz	a5,80005fca <pipealloc+0xc6>
    fileclose(*f1);
    80005fbe:	853e                	mv	a0,a5
    80005fc0:	00000097          	auipc	ra,0x0
    80005fc4:	c14080e7          	jalr	-1004(ra) # 80005bd4 <fileclose>
  return -1;
    80005fc8:	557d                	li	a0,-1
}
    80005fca:	70a2                	ld	ra,40(sp)
    80005fcc:	7402                	ld	s0,32(sp)
    80005fce:	64e2                	ld	s1,24(sp)
    80005fd0:	6942                	ld	s2,16(sp)
    80005fd2:	69a2                	ld	s3,8(sp)
    80005fd4:	6a02                	ld	s4,0(sp)
    80005fd6:	6145                	addi	sp,sp,48
    80005fd8:	8082                	ret
  return -1;
    80005fda:	557d                	li	a0,-1
    80005fdc:	b7fd                	j	80005fca <pipealloc+0xc6>

0000000080005fde <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005fde:	1101                	addi	sp,sp,-32
    80005fe0:	ec06                	sd	ra,24(sp)
    80005fe2:	e822                	sd	s0,16(sp)
    80005fe4:	e426                	sd	s1,8(sp)
    80005fe6:	e04a                	sd	s2,0(sp)
    80005fe8:	1000                	addi	s0,sp,32
    80005fea:	84aa                	mv	s1,a0
    80005fec:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005fee:	ffffb097          	auipc	ra,0xffffb
    80005ff2:	bf6080e7          	jalr	-1034(ra) # 80000be4 <acquire>
  if(writable){
    80005ff6:	02090d63          	beqz	s2,80006030 <pipeclose+0x52>
    pi->writeopen = 0;
    80005ffa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005ffe:	21848513          	addi	a0,s1,536
    80006002:	ffffd097          	auipc	ra,0xffffd
    80006006:	092080e7          	jalr	146(ra) # 80003094 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000600a:	2204b783          	ld	a5,544(s1)
    8000600e:	eb95                	bnez	a5,80006042 <pipeclose+0x64>
    release(&pi->lock);
    80006010:	8526                	mv	a0,s1
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	c86080e7          	jalr	-890(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000601a:	8526                	mv	a0,s1
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	9dc080e7          	jalr	-1572(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80006024:	60e2                	ld	ra,24(sp)
    80006026:	6442                	ld	s0,16(sp)
    80006028:	64a2                	ld	s1,8(sp)
    8000602a:	6902                	ld	s2,0(sp)
    8000602c:	6105                	addi	sp,sp,32
    8000602e:	8082                	ret
    pi->readopen = 0;
    80006030:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80006034:	21c48513          	addi	a0,s1,540
    80006038:	ffffd097          	auipc	ra,0xffffd
    8000603c:	05c080e7          	jalr	92(ra) # 80003094 <wakeup>
    80006040:	b7e9                	j	8000600a <pipeclose+0x2c>
    release(&pi->lock);
    80006042:	8526                	mv	a0,s1
    80006044:	ffffb097          	auipc	ra,0xffffb
    80006048:	c54080e7          	jalr	-940(ra) # 80000c98 <release>
}
    8000604c:	bfe1                	j	80006024 <pipeclose+0x46>

000000008000604e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000604e:	7159                	addi	sp,sp,-112
    80006050:	f486                	sd	ra,104(sp)
    80006052:	f0a2                	sd	s0,96(sp)
    80006054:	eca6                	sd	s1,88(sp)
    80006056:	e8ca                	sd	s2,80(sp)
    80006058:	e4ce                	sd	s3,72(sp)
    8000605a:	e0d2                	sd	s4,64(sp)
    8000605c:	fc56                	sd	s5,56(sp)
    8000605e:	f85a                	sd	s6,48(sp)
    80006060:	f45e                	sd	s7,40(sp)
    80006062:	f062                	sd	s8,32(sp)
    80006064:	ec66                	sd	s9,24(sp)
    80006066:	1880                	addi	s0,sp,112
    80006068:	84aa                	mv	s1,a0
    8000606a:	8aae                	mv	s5,a1
    8000606c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000606e:	ffffc097          	auipc	ra,0xffffc
    80006072:	b26080e7          	jalr	-1242(ra) # 80001b94 <myproc>
    80006076:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80006078:	8526                	mv	a0,s1
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	b6a080e7          	jalr	-1174(ra) # 80000be4 <acquire>
  while(i < n){
    80006082:	0d405163          	blez	s4,80006144 <pipewrite+0xf6>
    80006086:	8ba6                	mv	s7,s1
  int i = 0;
    80006088:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000608a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000608c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80006090:	21c48c13          	addi	s8,s1,540
    80006094:	a08d                	j	800060f6 <pipewrite+0xa8>
      release(&pi->lock);
    80006096:	8526                	mv	a0,s1
    80006098:	ffffb097          	auipc	ra,0xffffb
    8000609c:	c00080e7          	jalr	-1024(ra) # 80000c98 <release>
      return -1;
    800060a0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800060a2:	854a                	mv	a0,s2
    800060a4:	70a6                	ld	ra,104(sp)
    800060a6:	7406                	ld	s0,96(sp)
    800060a8:	64e6                	ld	s1,88(sp)
    800060aa:	6946                	ld	s2,80(sp)
    800060ac:	69a6                	ld	s3,72(sp)
    800060ae:	6a06                	ld	s4,64(sp)
    800060b0:	7ae2                	ld	s5,56(sp)
    800060b2:	7b42                	ld	s6,48(sp)
    800060b4:	7ba2                	ld	s7,40(sp)
    800060b6:	7c02                	ld	s8,32(sp)
    800060b8:	6ce2                	ld	s9,24(sp)
    800060ba:	6165                	addi	sp,sp,112
    800060bc:	8082                	ret
      wakeup(&pi->nread);
    800060be:	8566                	mv	a0,s9
    800060c0:	ffffd097          	auipc	ra,0xffffd
    800060c4:	fd4080e7          	jalr	-44(ra) # 80003094 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800060c8:	85de                	mv	a1,s7
    800060ca:	8562                	mv	a0,s8
    800060cc:	ffffd097          	auipc	ra,0xffffd
    800060d0:	bb2080e7          	jalr	-1102(ra) # 80002c7e <sleep>
    800060d4:	a839                	j	800060f2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800060d6:	21c4a783          	lw	a5,540(s1)
    800060da:	0017871b          	addiw	a4,a5,1
    800060de:	20e4ae23          	sw	a4,540(s1)
    800060e2:	1ff7f793          	andi	a5,a5,511
    800060e6:	97a6                	add	a5,a5,s1
    800060e8:	f9f44703          	lbu	a4,-97(s0)
    800060ec:	00e78c23          	sb	a4,24(a5)
      i++;
    800060f0:	2905                	addiw	s2,s2,1
  while(i < n){
    800060f2:	03495d63          	bge	s2,s4,8000612c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800060f6:	2204a783          	lw	a5,544(s1)
    800060fa:	dfd1                	beqz	a5,80006096 <pipewrite+0x48>
    800060fc:	0289a783          	lw	a5,40(s3)
    80006100:	fbd9                	bnez	a5,80006096 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80006102:	2184a783          	lw	a5,536(s1)
    80006106:	21c4a703          	lw	a4,540(s1)
    8000610a:	2007879b          	addiw	a5,a5,512
    8000610e:	faf708e3          	beq	a4,a5,800060be <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80006112:	4685                	li	a3,1
    80006114:	01590633          	add	a2,s2,s5
    80006118:	f9f40593          	addi	a1,s0,-97
    8000611c:	0809b503          	ld	a0,128(s3)
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	5e6080e7          	jalr	1510(ra) # 80001706 <copyin>
    80006128:	fb6517e3          	bne	a0,s6,800060d6 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000612c:	21848513          	addi	a0,s1,536
    80006130:	ffffd097          	auipc	ra,0xffffd
    80006134:	f64080e7          	jalr	-156(ra) # 80003094 <wakeup>
  release(&pi->lock);
    80006138:	8526                	mv	a0,s1
    8000613a:	ffffb097          	auipc	ra,0xffffb
    8000613e:	b5e080e7          	jalr	-1186(ra) # 80000c98 <release>
  return i;
    80006142:	b785                	j	800060a2 <pipewrite+0x54>
  int i = 0;
    80006144:	4901                	li	s2,0
    80006146:	b7dd                	j	8000612c <pipewrite+0xde>

0000000080006148 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80006148:	715d                	addi	sp,sp,-80
    8000614a:	e486                	sd	ra,72(sp)
    8000614c:	e0a2                	sd	s0,64(sp)
    8000614e:	fc26                	sd	s1,56(sp)
    80006150:	f84a                	sd	s2,48(sp)
    80006152:	f44e                	sd	s3,40(sp)
    80006154:	f052                	sd	s4,32(sp)
    80006156:	ec56                	sd	s5,24(sp)
    80006158:	e85a                	sd	s6,16(sp)
    8000615a:	0880                	addi	s0,sp,80
    8000615c:	84aa                	mv	s1,a0
    8000615e:	892e                	mv	s2,a1
    80006160:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80006162:	ffffc097          	auipc	ra,0xffffc
    80006166:	a32080e7          	jalr	-1486(ra) # 80001b94 <myproc>
    8000616a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000616c:	8b26                	mv	s6,s1
    8000616e:	8526                	mv	a0,s1
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	a74080e7          	jalr	-1420(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006178:	2184a703          	lw	a4,536(s1)
    8000617c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006180:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006184:	02f71463          	bne	a4,a5,800061ac <piperead+0x64>
    80006188:	2244a783          	lw	a5,548(s1)
    8000618c:	c385                	beqz	a5,800061ac <piperead+0x64>
    if(pr->killed){
    8000618e:	028a2783          	lw	a5,40(s4)
    80006192:	ebc1                	bnez	a5,80006222 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006194:	85da                	mv	a1,s6
    80006196:	854e                	mv	a0,s3
    80006198:	ffffd097          	auipc	ra,0xffffd
    8000619c:	ae6080e7          	jalr	-1306(ra) # 80002c7e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800061a0:	2184a703          	lw	a4,536(s1)
    800061a4:	21c4a783          	lw	a5,540(s1)
    800061a8:	fef700e3          	beq	a4,a5,80006188 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800061ac:	09505263          	blez	s5,80006230 <piperead+0xe8>
    800061b0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800061b2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800061b4:	2184a783          	lw	a5,536(s1)
    800061b8:	21c4a703          	lw	a4,540(s1)
    800061bc:	02f70d63          	beq	a4,a5,800061f6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800061c0:	0017871b          	addiw	a4,a5,1
    800061c4:	20e4ac23          	sw	a4,536(s1)
    800061c8:	1ff7f793          	andi	a5,a5,511
    800061cc:	97a6                	add	a5,a5,s1
    800061ce:	0187c783          	lbu	a5,24(a5)
    800061d2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800061d6:	4685                	li	a3,1
    800061d8:	fbf40613          	addi	a2,s0,-65
    800061dc:	85ca                	mv	a1,s2
    800061de:	080a3503          	ld	a0,128(s4)
    800061e2:	ffffb097          	auipc	ra,0xffffb
    800061e6:	498080e7          	jalr	1176(ra) # 8000167a <copyout>
    800061ea:	01650663          	beq	a0,s6,800061f6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800061ee:	2985                	addiw	s3,s3,1
    800061f0:	0905                	addi	s2,s2,1
    800061f2:	fd3a91e3          	bne	s5,s3,800061b4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800061f6:	21c48513          	addi	a0,s1,540
    800061fa:	ffffd097          	auipc	ra,0xffffd
    800061fe:	e9a080e7          	jalr	-358(ra) # 80003094 <wakeup>
  release(&pi->lock);
    80006202:	8526                	mv	a0,s1
    80006204:	ffffb097          	auipc	ra,0xffffb
    80006208:	a94080e7          	jalr	-1388(ra) # 80000c98 <release>
  return i;
}
    8000620c:	854e                	mv	a0,s3
    8000620e:	60a6                	ld	ra,72(sp)
    80006210:	6406                	ld	s0,64(sp)
    80006212:	74e2                	ld	s1,56(sp)
    80006214:	7942                	ld	s2,48(sp)
    80006216:	79a2                	ld	s3,40(sp)
    80006218:	7a02                	ld	s4,32(sp)
    8000621a:	6ae2                	ld	s5,24(sp)
    8000621c:	6b42                	ld	s6,16(sp)
    8000621e:	6161                	addi	sp,sp,80
    80006220:	8082                	ret
      release(&pi->lock);
    80006222:	8526                	mv	a0,s1
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	a74080e7          	jalr	-1420(ra) # 80000c98 <release>
      return -1;
    8000622c:	59fd                	li	s3,-1
    8000622e:	bff9                	j	8000620c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006230:	4981                	li	s3,0
    80006232:	b7d1                	j	800061f6 <piperead+0xae>

0000000080006234 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80006234:	df010113          	addi	sp,sp,-528
    80006238:	20113423          	sd	ra,520(sp)
    8000623c:	20813023          	sd	s0,512(sp)
    80006240:	ffa6                	sd	s1,504(sp)
    80006242:	fbca                	sd	s2,496(sp)
    80006244:	f7ce                	sd	s3,488(sp)
    80006246:	f3d2                	sd	s4,480(sp)
    80006248:	efd6                	sd	s5,472(sp)
    8000624a:	ebda                	sd	s6,464(sp)
    8000624c:	e7de                	sd	s7,456(sp)
    8000624e:	e3e2                	sd	s8,448(sp)
    80006250:	ff66                	sd	s9,440(sp)
    80006252:	fb6a                	sd	s10,432(sp)
    80006254:	f76e                	sd	s11,424(sp)
    80006256:	0c00                	addi	s0,sp,528
    80006258:	84aa                	mv	s1,a0
    8000625a:	dea43c23          	sd	a0,-520(s0)
    8000625e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80006262:	ffffc097          	auipc	ra,0xffffc
    80006266:	932080e7          	jalr	-1742(ra) # 80001b94 <myproc>
    8000626a:	892a                	mv	s2,a0

  begin_op();
    8000626c:	fffff097          	auipc	ra,0xfffff
    80006270:	49c080e7          	jalr	1180(ra) # 80005708 <begin_op>

  if((ip = namei(path)) == 0){
    80006274:	8526                	mv	a0,s1
    80006276:	fffff097          	auipc	ra,0xfffff
    8000627a:	276080e7          	jalr	630(ra) # 800054ec <namei>
    8000627e:	c92d                	beqz	a0,800062f0 <exec+0xbc>
    80006280:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80006282:	fffff097          	auipc	ra,0xfffff
    80006286:	ab4080e7          	jalr	-1356(ra) # 80004d36 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000628a:	04000713          	li	a4,64
    8000628e:	4681                	li	a3,0
    80006290:	e5040613          	addi	a2,s0,-432
    80006294:	4581                	li	a1,0
    80006296:	8526                	mv	a0,s1
    80006298:	fffff097          	auipc	ra,0xfffff
    8000629c:	d52080e7          	jalr	-686(ra) # 80004fea <readi>
    800062a0:	04000793          	li	a5,64
    800062a4:	00f51a63          	bne	a0,a5,800062b8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800062a8:	e5042703          	lw	a4,-432(s0)
    800062ac:	464c47b7          	lui	a5,0x464c4
    800062b0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800062b4:	04f70463          	beq	a4,a5,800062fc <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800062b8:	8526                	mv	a0,s1
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	cde080e7          	jalr	-802(ra) # 80004f98 <iunlockput>
    end_op();
    800062c2:	fffff097          	auipc	ra,0xfffff
    800062c6:	4c6080e7          	jalr	1222(ra) # 80005788 <end_op>
  }
  return -1;
    800062ca:	557d                	li	a0,-1
}
    800062cc:	20813083          	ld	ra,520(sp)
    800062d0:	20013403          	ld	s0,512(sp)
    800062d4:	74fe                	ld	s1,504(sp)
    800062d6:	795e                	ld	s2,496(sp)
    800062d8:	79be                	ld	s3,488(sp)
    800062da:	7a1e                	ld	s4,480(sp)
    800062dc:	6afe                	ld	s5,472(sp)
    800062de:	6b5e                	ld	s6,464(sp)
    800062e0:	6bbe                	ld	s7,456(sp)
    800062e2:	6c1e                	ld	s8,448(sp)
    800062e4:	7cfa                	ld	s9,440(sp)
    800062e6:	7d5a                	ld	s10,432(sp)
    800062e8:	7dba                	ld	s11,424(sp)
    800062ea:	21010113          	addi	sp,sp,528
    800062ee:	8082                	ret
    end_op();
    800062f0:	fffff097          	auipc	ra,0xfffff
    800062f4:	498080e7          	jalr	1176(ra) # 80005788 <end_op>
    return -1;
    800062f8:	557d                	li	a0,-1
    800062fa:	bfc9                	j	800062cc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800062fc:	854a                	mv	a0,s2
    800062fe:	ffffc097          	auipc	ra,0xffffc
    80006302:	95e080e7          	jalr	-1698(ra) # 80001c5c <proc_pagetable>
    80006306:	8baa                	mv	s7,a0
    80006308:	d945                	beqz	a0,800062b8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000630a:	e7042983          	lw	s3,-400(s0)
    8000630e:	e8845783          	lhu	a5,-376(s0)
    80006312:	c7ad                	beqz	a5,8000637c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80006314:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80006316:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80006318:	6c85                	lui	s9,0x1
    8000631a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000631e:	def43823          	sd	a5,-528(s0)
    80006322:	a42d                	j	8000654c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80006324:	00003517          	auipc	a0,0x3
    80006328:	7ac50513          	addi	a0,a0,1964 # 80009ad0 <syscalls+0x2a8>
    8000632c:	ffffa097          	auipc	ra,0xffffa
    80006330:	212080e7          	jalr	530(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80006334:	8756                	mv	a4,s5
    80006336:	012d86bb          	addw	a3,s11,s2
    8000633a:	4581                	li	a1,0
    8000633c:	8526                	mv	a0,s1
    8000633e:	fffff097          	auipc	ra,0xfffff
    80006342:	cac080e7          	jalr	-852(ra) # 80004fea <readi>
    80006346:	2501                	sext.w	a0,a0
    80006348:	1aaa9963          	bne	s5,a0,800064fa <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000634c:	6785                	lui	a5,0x1
    8000634e:	0127893b          	addw	s2,a5,s2
    80006352:	77fd                	lui	a5,0xfffff
    80006354:	01478a3b          	addw	s4,a5,s4
    80006358:	1f897163          	bgeu	s2,s8,8000653a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000635c:	02091593          	slli	a1,s2,0x20
    80006360:	9181                	srli	a1,a1,0x20
    80006362:	95ea                	add	a1,a1,s10
    80006364:	855e                	mv	a0,s7
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	d10080e7          	jalr	-752(ra) # 80001076 <walkaddr>
    8000636e:	862a                	mv	a2,a0
    if(pa == 0)
    80006370:	d955                	beqz	a0,80006324 <exec+0xf0>
      n = PGSIZE;
    80006372:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80006374:	fd9a70e3          	bgeu	s4,s9,80006334 <exec+0x100>
      n = sz - i;
    80006378:	8ad2                	mv	s5,s4
    8000637a:	bf6d                	j	80006334 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000637c:	4901                	li	s2,0
  iunlockput(ip);
    8000637e:	8526                	mv	a0,s1
    80006380:	fffff097          	auipc	ra,0xfffff
    80006384:	c18080e7          	jalr	-1000(ra) # 80004f98 <iunlockput>
  end_op();
    80006388:	fffff097          	auipc	ra,0xfffff
    8000638c:	400080e7          	jalr	1024(ra) # 80005788 <end_op>
  p = myproc();
    80006390:	ffffc097          	auipc	ra,0xffffc
    80006394:	804080e7          	jalr	-2044(ra) # 80001b94 <myproc>
    80006398:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000639a:	07853d03          	ld	s10,120(a0)
  sz = PGROUNDUP(sz);
    8000639e:	6785                	lui	a5,0x1
    800063a0:	17fd                	addi	a5,a5,-1
    800063a2:	993e                	add	s2,s2,a5
    800063a4:	757d                	lui	a0,0xfffff
    800063a6:	00a977b3          	and	a5,s2,a0
    800063aa:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800063ae:	6609                	lui	a2,0x2
    800063b0:	963e                	add	a2,a2,a5
    800063b2:	85be                	mv	a1,a5
    800063b4:	855e                	mv	a0,s7
    800063b6:	ffffb097          	auipc	ra,0xffffb
    800063ba:	074080e7          	jalr	116(ra) # 8000142a <uvmalloc>
    800063be:	8b2a                	mv	s6,a0
  ip = 0;
    800063c0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800063c2:	12050c63          	beqz	a0,800064fa <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800063c6:	75f9                	lui	a1,0xffffe
    800063c8:	95aa                	add	a1,a1,a0
    800063ca:	855e                	mv	a0,s7
    800063cc:	ffffb097          	auipc	ra,0xffffb
    800063d0:	27c080e7          	jalr	636(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    800063d4:	7c7d                	lui	s8,0xfffff
    800063d6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800063d8:	e0043783          	ld	a5,-512(s0)
    800063dc:	6388                	ld	a0,0(a5)
    800063de:	c535                	beqz	a0,8000644a <exec+0x216>
    800063e0:	e9040993          	addi	s3,s0,-368
    800063e4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800063e8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800063ea:	ffffb097          	auipc	ra,0xffffb
    800063ee:	a7a080e7          	jalr	-1414(ra) # 80000e64 <strlen>
    800063f2:	2505                	addiw	a0,a0,1
    800063f4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800063f8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800063fc:	13896363          	bltu	s2,s8,80006522 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80006400:	e0043d83          	ld	s11,-512(s0)
    80006404:	000dba03          	ld	s4,0(s11)
    80006408:	8552                	mv	a0,s4
    8000640a:	ffffb097          	auipc	ra,0xffffb
    8000640e:	a5a080e7          	jalr	-1446(ra) # 80000e64 <strlen>
    80006412:	0015069b          	addiw	a3,a0,1
    80006416:	8652                	mv	a2,s4
    80006418:	85ca                	mv	a1,s2
    8000641a:	855e                	mv	a0,s7
    8000641c:	ffffb097          	auipc	ra,0xffffb
    80006420:	25e080e7          	jalr	606(ra) # 8000167a <copyout>
    80006424:	10054363          	bltz	a0,8000652a <exec+0x2f6>
    ustack[argc] = sp;
    80006428:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000642c:	0485                	addi	s1,s1,1
    8000642e:	008d8793          	addi	a5,s11,8
    80006432:	e0f43023          	sd	a5,-512(s0)
    80006436:	008db503          	ld	a0,8(s11)
    8000643a:	c911                	beqz	a0,8000644e <exec+0x21a>
    if(argc >= MAXARG)
    8000643c:	09a1                	addi	s3,s3,8
    8000643e:	fb3c96e3          	bne	s9,s3,800063ea <exec+0x1b6>
  sz = sz1;
    80006442:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006446:	4481                	li	s1,0
    80006448:	a84d                	j	800064fa <exec+0x2c6>
  sp = sz;
    8000644a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000644c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000644e:	00349793          	slli	a5,s1,0x3
    80006452:	f9040713          	addi	a4,s0,-112
    80006456:	97ba                	add	a5,a5,a4
    80006458:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000645c:	00148693          	addi	a3,s1,1
    80006460:	068e                	slli	a3,a3,0x3
    80006462:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80006466:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000646a:	01897663          	bgeu	s2,s8,80006476 <exec+0x242>
  sz = sz1;
    8000646e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006472:	4481                	li	s1,0
    80006474:	a059                	j	800064fa <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80006476:	e9040613          	addi	a2,s0,-368
    8000647a:	85ca                	mv	a1,s2
    8000647c:	855e                	mv	a0,s7
    8000647e:	ffffb097          	auipc	ra,0xffffb
    80006482:	1fc080e7          	jalr	508(ra) # 8000167a <copyout>
    80006486:	0a054663          	bltz	a0,80006532 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000648a:	088ab783          	ld	a5,136(s5)
    8000648e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80006492:	df843783          	ld	a5,-520(s0)
    80006496:	0007c703          	lbu	a4,0(a5)
    8000649a:	cf11                	beqz	a4,800064b6 <exec+0x282>
    8000649c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000649e:	02f00693          	li	a3,47
    800064a2:	a039                	j	800064b0 <exec+0x27c>
      last = s+1;
    800064a4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800064a8:	0785                	addi	a5,a5,1
    800064aa:	fff7c703          	lbu	a4,-1(a5)
    800064ae:	c701                	beqz	a4,800064b6 <exec+0x282>
    if(*s == '/')
    800064b0:	fed71ce3          	bne	a4,a3,800064a8 <exec+0x274>
    800064b4:	bfc5                	j	800064a4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800064b6:	4641                	li	a2,16
    800064b8:	df843583          	ld	a1,-520(s0)
    800064bc:	188a8513          	addi	a0,s5,392
    800064c0:	ffffb097          	auipc	ra,0xffffb
    800064c4:	972080e7          	jalr	-1678(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800064c8:	080ab503          	ld	a0,128(s5)
  p->pagetable = pagetable;
    800064cc:	097ab023          	sd	s7,128(s5)
  p->sz = sz;
    800064d0:	076abc23          	sd	s6,120(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800064d4:	088ab783          	ld	a5,136(s5)
    800064d8:	e6843703          	ld	a4,-408(s0)
    800064dc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800064de:	088ab783          	ld	a5,136(s5)
    800064e2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800064e6:	85ea                	mv	a1,s10
    800064e8:	ffffc097          	auipc	ra,0xffffc
    800064ec:	810080e7          	jalr	-2032(ra) # 80001cf8 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800064f0:	0004851b          	sext.w	a0,s1
    800064f4:	bbe1                	j	800062cc <exec+0x98>
    800064f6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800064fa:	e0843583          	ld	a1,-504(s0)
    800064fe:	855e                	mv	a0,s7
    80006500:	ffffb097          	auipc	ra,0xffffb
    80006504:	7f8080e7          	jalr	2040(ra) # 80001cf8 <proc_freepagetable>
  if(ip){
    80006508:	da0498e3          	bnez	s1,800062b8 <exec+0x84>
  return -1;
    8000650c:	557d                	li	a0,-1
    8000650e:	bb7d                	j	800062cc <exec+0x98>
    80006510:	e1243423          	sd	s2,-504(s0)
    80006514:	b7dd                	j	800064fa <exec+0x2c6>
    80006516:	e1243423          	sd	s2,-504(s0)
    8000651a:	b7c5                	j	800064fa <exec+0x2c6>
    8000651c:	e1243423          	sd	s2,-504(s0)
    80006520:	bfe9                	j	800064fa <exec+0x2c6>
  sz = sz1;
    80006522:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006526:	4481                	li	s1,0
    80006528:	bfc9                	j	800064fa <exec+0x2c6>
  sz = sz1;
    8000652a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000652e:	4481                	li	s1,0
    80006530:	b7e9                	j	800064fa <exec+0x2c6>
  sz = sz1;
    80006532:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80006536:	4481                	li	s1,0
    80006538:	b7c9                	j	800064fa <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000653a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000653e:	2b05                	addiw	s6,s6,1
    80006540:	0389899b          	addiw	s3,s3,56
    80006544:	e8845783          	lhu	a5,-376(s0)
    80006548:	e2fb5be3          	bge	s6,a5,8000637e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000654c:	2981                	sext.w	s3,s3
    8000654e:	03800713          	li	a4,56
    80006552:	86ce                	mv	a3,s3
    80006554:	e1840613          	addi	a2,s0,-488
    80006558:	4581                	li	a1,0
    8000655a:	8526                	mv	a0,s1
    8000655c:	fffff097          	auipc	ra,0xfffff
    80006560:	a8e080e7          	jalr	-1394(ra) # 80004fea <readi>
    80006564:	03800793          	li	a5,56
    80006568:	f8f517e3          	bne	a0,a5,800064f6 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000656c:	e1842783          	lw	a5,-488(s0)
    80006570:	4705                	li	a4,1
    80006572:	fce796e3          	bne	a5,a4,8000653e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80006576:	e4043603          	ld	a2,-448(s0)
    8000657a:	e3843783          	ld	a5,-456(s0)
    8000657e:	f8f669e3          	bltu	a2,a5,80006510 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80006582:	e2843783          	ld	a5,-472(s0)
    80006586:	963e                	add	a2,a2,a5
    80006588:	f8f667e3          	bltu	a2,a5,80006516 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000658c:	85ca                	mv	a1,s2
    8000658e:	855e                	mv	a0,s7
    80006590:	ffffb097          	auipc	ra,0xffffb
    80006594:	e9a080e7          	jalr	-358(ra) # 8000142a <uvmalloc>
    80006598:	e0a43423          	sd	a0,-504(s0)
    8000659c:	d141                	beqz	a0,8000651c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000659e:	e2843d03          	ld	s10,-472(s0)
    800065a2:	df043783          	ld	a5,-528(s0)
    800065a6:	00fd77b3          	and	a5,s10,a5
    800065aa:	fba1                	bnez	a5,800064fa <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800065ac:	e2042d83          	lw	s11,-480(s0)
    800065b0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800065b4:	f80c03e3          	beqz	s8,8000653a <exec+0x306>
    800065b8:	8a62                	mv	s4,s8
    800065ba:	4901                	li	s2,0
    800065bc:	b345                	j	8000635c <exec+0x128>

00000000800065be <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800065be:	7179                	addi	sp,sp,-48
    800065c0:	f406                	sd	ra,40(sp)
    800065c2:	f022                	sd	s0,32(sp)
    800065c4:	ec26                	sd	s1,24(sp)
    800065c6:	e84a                	sd	s2,16(sp)
    800065c8:	1800                	addi	s0,sp,48
    800065ca:	892e                	mv	s2,a1
    800065cc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800065ce:	fdc40593          	addi	a1,s0,-36
    800065d2:	ffffe097          	auipc	ra,0xffffe
    800065d6:	b46080e7          	jalr	-1210(ra) # 80004118 <argint>
    800065da:	04054063          	bltz	a0,8000661a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800065de:	fdc42703          	lw	a4,-36(s0)
    800065e2:	47bd                	li	a5,15
    800065e4:	02e7ed63          	bltu	a5,a4,8000661e <argfd+0x60>
    800065e8:	ffffb097          	auipc	ra,0xffffb
    800065ec:	5ac080e7          	jalr	1452(ra) # 80001b94 <myproc>
    800065f0:	fdc42703          	lw	a4,-36(s0)
    800065f4:	02070793          	addi	a5,a4,32
    800065f8:	078e                	slli	a5,a5,0x3
    800065fa:	953e                	add	a0,a0,a5
    800065fc:	611c                	ld	a5,0(a0)
    800065fe:	c395                	beqz	a5,80006622 <argfd+0x64>
    return -1;
  if(pfd)
    80006600:	00090463          	beqz	s2,80006608 <argfd+0x4a>
    *pfd = fd;
    80006604:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80006608:	4501                	li	a0,0
  if(pf)
    8000660a:	c091                	beqz	s1,8000660e <argfd+0x50>
    *pf = f;
    8000660c:	e09c                	sd	a5,0(s1)
}
    8000660e:	70a2                	ld	ra,40(sp)
    80006610:	7402                	ld	s0,32(sp)
    80006612:	64e2                	ld	s1,24(sp)
    80006614:	6942                	ld	s2,16(sp)
    80006616:	6145                	addi	sp,sp,48
    80006618:	8082                	ret
    return -1;
    8000661a:	557d                	li	a0,-1
    8000661c:	bfcd                	j	8000660e <argfd+0x50>
    return -1;
    8000661e:	557d                	li	a0,-1
    80006620:	b7fd                	j	8000660e <argfd+0x50>
    80006622:	557d                	li	a0,-1
    80006624:	b7ed                	j	8000660e <argfd+0x50>

0000000080006626 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80006626:	1101                	addi	sp,sp,-32
    80006628:	ec06                	sd	ra,24(sp)
    8000662a:	e822                	sd	s0,16(sp)
    8000662c:	e426                	sd	s1,8(sp)
    8000662e:	1000                	addi	s0,sp,32
    80006630:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80006632:	ffffb097          	auipc	ra,0xffffb
    80006636:	562080e7          	jalr	1378(ra) # 80001b94 <myproc>
    8000663a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000663c:	10050793          	addi	a5,a0,256 # fffffffffffff100 <end+0xffffffff7ffd7100>
    80006640:	4501                	li	a0,0
    80006642:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80006644:	6398                	ld	a4,0(a5)
    80006646:	cb19                	beqz	a4,8000665c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80006648:	2505                	addiw	a0,a0,1
    8000664a:	07a1                	addi	a5,a5,8
    8000664c:	fed51ce3          	bne	a0,a3,80006644 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80006650:	557d                	li	a0,-1
}
    80006652:	60e2                	ld	ra,24(sp)
    80006654:	6442                	ld	s0,16(sp)
    80006656:	64a2                	ld	s1,8(sp)
    80006658:	6105                	addi	sp,sp,32
    8000665a:	8082                	ret
      p->ofile[fd] = f;
    8000665c:	02050793          	addi	a5,a0,32
    80006660:	078e                	slli	a5,a5,0x3
    80006662:	963e                	add	a2,a2,a5
    80006664:	e204                	sd	s1,0(a2)
      return fd;
    80006666:	b7f5                	j	80006652 <fdalloc+0x2c>

0000000080006668 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80006668:	715d                	addi	sp,sp,-80
    8000666a:	e486                	sd	ra,72(sp)
    8000666c:	e0a2                	sd	s0,64(sp)
    8000666e:	fc26                	sd	s1,56(sp)
    80006670:	f84a                	sd	s2,48(sp)
    80006672:	f44e                	sd	s3,40(sp)
    80006674:	f052                	sd	s4,32(sp)
    80006676:	ec56                	sd	s5,24(sp)
    80006678:	0880                	addi	s0,sp,80
    8000667a:	89ae                	mv	s3,a1
    8000667c:	8ab2                	mv	s5,a2
    8000667e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006680:	fb040593          	addi	a1,s0,-80
    80006684:	fffff097          	auipc	ra,0xfffff
    80006688:	e86080e7          	jalr	-378(ra) # 8000550a <nameiparent>
    8000668c:	892a                	mv	s2,a0
    8000668e:	12050f63          	beqz	a0,800067cc <create+0x164>
    return 0;

  ilock(dp);
    80006692:	ffffe097          	auipc	ra,0xffffe
    80006696:	6a4080e7          	jalr	1700(ra) # 80004d36 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000669a:	4601                	li	a2,0
    8000669c:	fb040593          	addi	a1,s0,-80
    800066a0:	854a                	mv	a0,s2
    800066a2:	fffff097          	auipc	ra,0xfffff
    800066a6:	b78080e7          	jalr	-1160(ra) # 8000521a <dirlookup>
    800066aa:	84aa                	mv	s1,a0
    800066ac:	c921                	beqz	a0,800066fc <create+0x94>
    iunlockput(dp);
    800066ae:	854a                	mv	a0,s2
    800066b0:	fffff097          	auipc	ra,0xfffff
    800066b4:	8e8080e7          	jalr	-1816(ra) # 80004f98 <iunlockput>
    ilock(ip);
    800066b8:	8526                	mv	a0,s1
    800066ba:	ffffe097          	auipc	ra,0xffffe
    800066be:	67c080e7          	jalr	1660(ra) # 80004d36 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800066c2:	2981                	sext.w	s3,s3
    800066c4:	4789                	li	a5,2
    800066c6:	02f99463          	bne	s3,a5,800066ee <create+0x86>
    800066ca:	0444d783          	lhu	a5,68(s1)
    800066ce:	37f9                	addiw	a5,a5,-2
    800066d0:	17c2                	slli	a5,a5,0x30
    800066d2:	93c1                	srli	a5,a5,0x30
    800066d4:	4705                	li	a4,1
    800066d6:	00f76c63          	bltu	a4,a5,800066ee <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800066da:	8526                	mv	a0,s1
    800066dc:	60a6                	ld	ra,72(sp)
    800066de:	6406                	ld	s0,64(sp)
    800066e0:	74e2                	ld	s1,56(sp)
    800066e2:	7942                	ld	s2,48(sp)
    800066e4:	79a2                	ld	s3,40(sp)
    800066e6:	7a02                	ld	s4,32(sp)
    800066e8:	6ae2                	ld	s5,24(sp)
    800066ea:	6161                	addi	sp,sp,80
    800066ec:	8082                	ret
    iunlockput(ip);
    800066ee:	8526                	mv	a0,s1
    800066f0:	fffff097          	auipc	ra,0xfffff
    800066f4:	8a8080e7          	jalr	-1880(ra) # 80004f98 <iunlockput>
    return 0;
    800066f8:	4481                	li	s1,0
    800066fa:	b7c5                	j	800066da <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800066fc:	85ce                	mv	a1,s3
    800066fe:	00092503          	lw	a0,0(s2)
    80006702:	ffffe097          	auipc	ra,0xffffe
    80006706:	49c080e7          	jalr	1180(ra) # 80004b9e <ialloc>
    8000670a:	84aa                	mv	s1,a0
    8000670c:	c529                	beqz	a0,80006756 <create+0xee>
  ilock(ip);
    8000670e:	ffffe097          	auipc	ra,0xffffe
    80006712:	628080e7          	jalr	1576(ra) # 80004d36 <ilock>
  ip->major = major;
    80006716:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000671a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000671e:	4785                	li	a5,1
    80006720:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006724:	8526                	mv	a0,s1
    80006726:	ffffe097          	auipc	ra,0xffffe
    8000672a:	546080e7          	jalr	1350(ra) # 80004c6c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000672e:	2981                	sext.w	s3,s3
    80006730:	4785                	li	a5,1
    80006732:	02f98a63          	beq	s3,a5,80006766 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80006736:	40d0                	lw	a2,4(s1)
    80006738:	fb040593          	addi	a1,s0,-80
    8000673c:	854a                	mv	a0,s2
    8000673e:	fffff097          	auipc	ra,0xfffff
    80006742:	cec080e7          	jalr	-788(ra) # 8000542a <dirlink>
    80006746:	06054b63          	bltz	a0,800067bc <create+0x154>
  iunlockput(dp);
    8000674a:	854a                	mv	a0,s2
    8000674c:	fffff097          	auipc	ra,0xfffff
    80006750:	84c080e7          	jalr	-1972(ra) # 80004f98 <iunlockput>
  return ip;
    80006754:	b759                	j	800066da <create+0x72>
    panic("create: ialloc");
    80006756:	00003517          	auipc	a0,0x3
    8000675a:	39a50513          	addi	a0,a0,922 # 80009af0 <syscalls+0x2c8>
    8000675e:	ffffa097          	auipc	ra,0xffffa
    80006762:	de0080e7          	jalr	-544(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80006766:	04a95783          	lhu	a5,74(s2)
    8000676a:	2785                	addiw	a5,a5,1
    8000676c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006770:	854a                	mv	a0,s2
    80006772:	ffffe097          	auipc	ra,0xffffe
    80006776:	4fa080e7          	jalr	1274(ra) # 80004c6c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000677a:	40d0                	lw	a2,4(s1)
    8000677c:	00003597          	auipc	a1,0x3
    80006780:	38458593          	addi	a1,a1,900 # 80009b00 <syscalls+0x2d8>
    80006784:	8526                	mv	a0,s1
    80006786:	fffff097          	auipc	ra,0xfffff
    8000678a:	ca4080e7          	jalr	-860(ra) # 8000542a <dirlink>
    8000678e:	00054f63          	bltz	a0,800067ac <create+0x144>
    80006792:	00492603          	lw	a2,4(s2)
    80006796:	00003597          	auipc	a1,0x3
    8000679a:	37258593          	addi	a1,a1,882 # 80009b08 <syscalls+0x2e0>
    8000679e:	8526                	mv	a0,s1
    800067a0:	fffff097          	auipc	ra,0xfffff
    800067a4:	c8a080e7          	jalr	-886(ra) # 8000542a <dirlink>
    800067a8:	f80557e3          	bgez	a0,80006736 <create+0xce>
      panic("create dots");
    800067ac:	00003517          	auipc	a0,0x3
    800067b0:	36450513          	addi	a0,a0,868 # 80009b10 <syscalls+0x2e8>
    800067b4:	ffffa097          	auipc	ra,0xffffa
    800067b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>
    panic("create: dirlink");
    800067bc:	00003517          	auipc	a0,0x3
    800067c0:	36450513          	addi	a0,a0,868 # 80009b20 <syscalls+0x2f8>
    800067c4:	ffffa097          	auipc	ra,0xffffa
    800067c8:	d7a080e7          	jalr	-646(ra) # 8000053e <panic>
    return 0;
    800067cc:	84aa                	mv	s1,a0
    800067ce:	b731                	j	800066da <create+0x72>

00000000800067d0 <sys_dup>:
{
    800067d0:	7179                	addi	sp,sp,-48
    800067d2:	f406                	sd	ra,40(sp)
    800067d4:	f022                	sd	s0,32(sp)
    800067d6:	ec26                	sd	s1,24(sp)
    800067d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800067da:	fd840613          	addi	a2,s0,-40
    800067de:	4581                	li	a1,0
    800067e0:	4501                	li	a0,0
    800067e2:	00000097          	auipc	ra,0x0
    800067e6:	ddc080e7          	jalr	-548(ra) # 800065be <argfd>
    return -1;
    800067ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800067ec:	02054363          	bltz	a0,80006812 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800067f0:	fd843503          	ld	a0,-40(s0)
    800067f4:	00000097          	auipc	ra,0x0
    800067f8:	e32080e7          	jalr	-462(ra) # 80006626 <fdalloc>
    800067fc:	84aa                	mv	s1,a0
    return -1;
    800067fe:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80006800:	00054963          	bltz	a0,80006812 <sys_dup+0x42>
  filedup(f);
    80006804:	fd843503          	ld	a0,-40(s0)
    80006808:	fffff097          	auipc	ra,0xfffff
    8000680c:	37a080e7          	jalr	890(ra) # 80005b82 <filedup>
  return fd;
    80006810:	87a6                	mv	a5,s1
}
    80006812:	853e                	mv	a0,a5
    80006814:	70a2                	ld	ra,40(sp)
    80006816:	7402                	ld	s0,32(sp)
    80006818:	64e2                	ld	s1,24(sp)
    8000681a:	6145                	addi	sp,sp,48
    8000681c:	8082                	ret

000000008000681e <sys_read>:
{
    8000681e:	7179                	addi	sp,sp,-48
    80006820:	f406                	sd	ra,40(sp)
    80006822:	f022                	sd	s0,32(sp)
    80006824:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006826:	fe840613          	addi	a2,s0,-24
    8000682a:	4581                	li	a1,0
    8000682c:	4501                	li	a0,0
    8000682e:	00000097          	auipc	ra,0x0
    80006832:	d90080e7          	jalr	-624(ra) # 800065be <argfd>
    return -1;
    80006836:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006838:	04054163          	bltz	a0,8000687a <sys_read+0x5c>
    8000683c:	fe440593          	addi	a1,s0,-28
    80006840:	4509                	li	a0,2
    80006842:	ffffe097          	auipc	ra,0xffffe
    80006846:	8d6080e7          	jalr	-1834(ra) # 80004118 <argint>
    return -1;
    8000684a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000684c:	02054763          	bltz	a0,8000687a <sys_read+0x5c>
    80006850:	fd840593          	addi	a1,s0,-40
    80006854:	4505                	li	a0,1
    80006856:	ffffe097          	auipc	ra,0xffffe
    8000685a:	8e4080e7          	jalr	-1820(ra) # 8000413a <argaddr>
    return -1;
    8000685e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006860:	00054d63          	bltz	a0,8000687a <sys_read+0x5c>
  return fileread(f, p, n);
    80006864:	fe442603          	lw	a2,-28(s0)
    80006868:	fd843583          	ld	a1,-40(s0)
    8000686c:	fe843503          	ld	a0,-24(s0)
    80006870:	fffff097          	auipc	ra,0xfffff
    80006874:	49e080e7          	jalr	1182(ra) # 80005d0e <fileread>
    80006878:	87aa                	mv	a5,a0
}
    8000687a:	853e                	mv	a0,a5
    8000687c:	70a2                	ld	ra,40(sp)
    8000687e:	7402                	ld	s0,32(sp)
    80006880:	6145                	addi	sp,sp,48
    80006882:	8082                	ret

0000000080006884 <sys_write>:
{
    80006884:	7179                	addi	sp,sp,-48
    80006886:	f406                	sd	ra,40(sp)
    80006888:	f022                	sd	s0,32(sp)
    8000688a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000688c:	fe840613          	addi	a2,s0,-24
    80006890:	4581                	li	a1,0
    80006892:	4501                	li	a0,0
    80006894:	00000097          	auipc	ra,0x0
    80006898:	d2a080e7          	jalr	-726(ra) # 800065be <argfd>
    return -1;
    8000689c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000689e:	04054163          	bltz	a0,800068e0 <sys_write+0x5c>
    800068a2:	fe440593          	addi	a1,s0,-28
    800068a6:	4509                	li	a0,2
    800068a8:	ffffe097          	auipc	ra,0xffffe
    800068ac:	870080e7          	jalr	-1936(ra) # 80004118 <argint>
    return -1;
    800068b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800068b2:	02054763          	bltz	a0,800068e0 <sys_write+0x5c>
    800068b6:	fd840593          	addi	a1,s0,-40
    800068ba:	4505                	li	a0,1
    800068bc:	ffffe097          	auipc	ra,0xffffe
    800068c0:	87e080e7          	jalr	-1922(ra) # 8000413a <argaddr>
    return -1;
    800068c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800068c6:	00054d63          	bltz	a0,800068e0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800068ca:	fe442603          	lw	a2,-28(s0)
    800068ce:	fd843583          	ld	a1,-40(s0)
    800068d2:	fe843503          	ld	a0,-24(s0)
    800068d6:	fffff097          	auipc	ra,0xfffff
    800068da:	4fa080e7          	jalr	1274(ra) # 80005dd0 <filewrite>
    800068de:	87aa                	mv	a5,a0
}
    800068e0:	853e                	mv	a0,a5
    800068e2:	70a2                	ld	ra,40(sp)
    800068e4:	7402                	ld	s0,32(sp)
    800068e6:	6145                	addi	sp,sp,48
    800068e8:	8082                	ret

00000000800068ea <sys_close>:
{
    800068ea:	1101                	addi	sp,sp,-32
    800068ec:	ec06                	sd	ra,24(sp)
    800068ee:	e822                	sd	s0,16(sp)
    800068f0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800068f2:	fe040613          	addi	a2,s0,-32
    800068f6:	fec40593          	addi	a1,s0,-20
    800068fa:	4501                	li	a0,0
    800068fc:	00000097          	auipc	ra,0x0
    80006900:	cc2080e7          	jalr	-830(ra) # 800065be <argfd>
    return -1;
    80006904:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80006906:	02054563          	bltz	a0,80006930 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    8000690a:	ffffb097          	auipc	ra,0xffffb
    8000690e:	28a080e7          	jalr	650(ra) # 80001b94 <myproc>
    80006912:	fec42783          	lw	a5,-20(s0)
    80006916:	02078793          	addi	a5,a5,32
    8000691a:	078e                	slli	a5,a5,0x3
    8000691c:	97aa                	add	a5,a5,a0
    8000691e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80006922:	fe043503          	ld	a0,-32(s0)
    80006926:	fffff097          	auipc	ra,0xfffff
    8000692a:	2ae080e7          	jalr	686(ra) # 80005bd4 <fileclose>
  return 0;
    8000692e:	4781                	li	a5,0
}
    80006930:	853e                	mv	a0,a5
    80006932:	60e2                	ld	ra,24(sp)
    80006934:	6442                	ld	s0,16(sp)
    80006936:	6105                	addi	sp,sp,32
    80006938:	8082                	ret

000000008000693a <sys_fstat>:
{
    8000693a:	1101                	addi	sp,sp,-32
    8000693c:	ec06                	sd	ra,24(sp)
    8000693e:	e822                	sd	s0,16(sp)
    80006940:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006942:	fe840613          	addi	a2,s0,-24
    80006946:	4581                	li	a1,0
    80006948:	4501                	li	a0,0
    8000694a:	00000097          	auipc	ra,0x0
    8000694e:	c74080e7          	jalr	-908(ra) # 800065be <argfd>
    return -1;
    80006952:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006954:	02054563          	bltz	a0,8000697e <sys_fstat+0x44>
    80006958:	fe040593          	addi	a1,s0,-32
    8000695c:	4505                	li	a0,1
    8000695e:	ffffd097          	auipc	ra,0xffffd
    80006962:	7dc080e7          	jalr	2012(ra) # 8000413a <argaddr>
    return -1;
    80006966:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006968:	00054b63          	bltz	a0,8000697e <sys_fstat+0x44>
  return filestat(f, st);
    8000696c:	fe043583          	ld	a1,-32(s0)
    80006970:	fe843503          	ld	a0,-24(s0)
    80006974:	fffff097          	auipc	ra,0xfffff
    80006978:	328080e7          	jalr	808(ra) # 80005c9c <filestat>
    8000697c:	87aa                	mv	a5,a0
}
    8000697e:	853e                	mv	a0,a5
    80006980:	60e2                	ld	ra,24(sp)
    80006982:	6442                	ld	s0,16(sp)
    80006984:	6105                	addi	sp,sp,32
    80006986:	8082                	ret

0000000080006988 <sys_link>:
{
    80006988:	7169                	addi	sp,sp,-304
    8000698a:	f606                	sd	ra,296(sp)
    8000698c:	f222                	sd	s0,288(sp)
    8000698e:	ee26                	sd	s1,280(sp)
    80006990:	ea4a                	sd	s2,272(sp)
    80006992:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006994:	08000613          	li	a2,128
    80006998:	ed040593          	addi	a1,s0,-304
    8000699c:	4501                	li	a0,0
    8000699e:	ffffd097          	auipc	ra,0xffffd
    800069a2:	7be080e7          	jalr	1982(ra) # 8000415c <argstr>
    return -1;
    800069a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800069a8:	10054e63          	bltz	a0,80006ac4 <sys_link+0x13c>
    800069ac:	08000613          	li	a2,128
    800069b0:	f5040593          	addi	a1,s0,-176
    800069b4:	4505                	li	a0,1
    800069b6:	ffffd097          	auipc	ra,0xffffd
    800069ba:	7a6080e7          	jalr	1958(ra) # 8000415c <argstr>
    return -1;
    800069be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800069c0:	10054263          	bltz	a0,80006ac4 <sys_link+0x13c>
  begin_op();
    800069c4:	fffff097          	auipc	ra,0xfffff
    800069c8:	d44080e7          	jalr	-700(ra) # 80005708 <begin_op>
  if((ip = namei(old)) == 0){
    800069cc:	ed040513          	addi	a0,s0,-304
    800069d0:	fffff097          	auipc	ra,0xfffff
    800069d4:	b1c080e7          	jalr	-1252(ra) # 800054ec <namei>
    800069d8:	84aa                	mv	s1,a0
    800069da:	c551                	beqz	a0,80006a66 <sys_link+0xde>
  ilock(ip);
    800069dc:	ffffe097          	auipc	ra,0xffffe
    800069e0:	35a080e7          	jalr	858(ra) # 80004d36 <ilock>
  if(ip->type == T_DIR){
    800069e4:	04449703          	lh	a4,68(s1)
    800069e8:	4785                	li	a5,1
    800069ea:	08f70463          	beq	a4,a5,80006a72 <sys_link+0xea>
  ip->nlink++;
    800069ee:	04a4d783          	lhu	a5,74(s1)
    800069f2:	2785                	addiw	a5,a5,1
    800069f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800069f8:	8526                	mv	a0,s1
    800069fa:	ffffe097          	auipc	ra,0xffffe
    800069fe:	272080e7          	jalr	626(ra) # 80004c6c <iupdate>
  iunlock(ip);
    80006a02:	8526                	mv	a0,s1
    80006a04:	ffffe097          	auipc	ra,0xffffe
    80006a08:	3f4080e7          	jalr	1012(ra) # 80004df8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006a0c:	fd040593          	addi	a1,s0,-48
    80006a10:	f5040513          	addi	a0,s0,-176
    80006a14:	fffff097          	auipc	ra,0xfffff
    80006a18:	af6080e7          	jalr	-1290(ra) # 8000550a <nameiparent>
    80006a1c:	892a                	mv	s2,a0
    80006a1e:	c935                	beqz	a0,80006a92 <sys_link+0x10a>
  ilock(dp);
    80006a20:	ffffe097          	auipc	ra,0xffffe
    80006a24:	316080e7          	jalr	790(ra) # 80004d36 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006a28:	00092703          	lw	a4,0(s2)
    80006a2c:	409c                	lw	a5,0(s1)
    80006a2e:	04f71d63          	bne	a4,a5,80006a88 <sys_link+0x100>
    80006a32:	40d0                	lw	a2,4(s1)
    80006a34:	fd040593          	addi	a1,s0,-48
    80006a38:	854a                	mv	a0,s2
    80006a3a:	fffff097          	auipc	ra,0xfffff
    80006a3e:	9f0080e7          	jalr	-1552(ra) # 8000542a <dirlink>
    80006a42:	04054363          	bltz	a0,80006a88 <sys_link+0x100>
  iunlockput(dp);
    80006a46:	854a                	mv	a0,s2
    80006a48:	ffffe097          	auipc	ra,0xffffe
    80006a4c:	550080e7          	jalr	1360(ra) # 80004f98 <iunlockput>
  iput(ip);
    80006a50:	8526                	mv	a0,s1
    80006a52:	ffffe097          	auipc	ra,0xffffe
    80006a56:	49e080e7          	jalr	1182(ra) # 80004ef0 <iput>
  end_op();
    80006a5a:	fffff097          	auipc	ra,0xfffff
    80006a5e:	d2e080e7          	jalr	-722(ra) # 80005788 <end_op>
  return 0;
    80006a62:	4781                	li	a5,0
    80006a64:	a085                	j	80006ac4 <sys_link+0x13c>
    end_op();
    80006a66:	fffff097          	auipc	ra,0xfffff
    80006a6a:	d22080e7          	jalr	-734(ra) # 80005788 <end_op>
    return -1;
    80006a6e:	57fd                	li	a5,-1
    80006a70:	a891                	j	80006ac4 <sys_link+0x13c>
    iunlockput(ip);
    80006a72:	8526                	mv	a0,s1
    80006a74:	ffffe097          	auipc	ra,0xffffe
    80006a78:	524080e7          	jalr	1316(ra) # 80004f98 <iunlockput>
    end_op();
    80006a7c:	fffff097          	auipc	ra,0xfffff
    80006a80:	d0c080e7          	jalr	-756(ra) # 80005788 <end_op>
    return -1;
    80006a84:	57fd                	li	a5,-1
    80006a86:	a83d                	j	80006ac4 <sys_link+0x13c>
    iunlockput(dp);
    80006a88:	854a                	mv	a0,s2
    80006a8a:	ffffe097          	auipc	ra,0xffffe
    80006a8e:	50e080e7          	jalr	1294(ra) # 80004f98 <iunlockput>
  ilock(ip);
    80006a92:	8526                	mv	a0,s1
    80006a94:	ffffe097          	auipc	ra,0xffffe
    80006a98:	2a2080e7          	jalr	674(ra) # 80004d36 <ilock>
  ip->nlink--;
    80006a9c:	04a4d783          	lhu	a5,74(s1)
    80006aa0:	37fd                	addiw	a5,a5,-1
    80006aa2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006aa6:	8526                	mv	a0,s1
    80006aa8:	ffffe097          	auipc	ra,0xffffe
    80006aac:	1c4080e7          	jalr	452(ra) # 80004c6c <iupdate>
  iunlockput(ip);
    80006ab0:	8526                	mv	a0,s1
    80006ab2:	ffffe097          	auipc	ra,0xffffe
    80006ab6:	4e6080e7          	jalr	1254(ra) # 80004f98 <iunlockput>
  end_op();
    80006aba:	fffff097          	auipc	ra,0xfffff
    80006abe:	cce080e7          	jalr	-818(ra) # 80005788 <end_op>
  return -1;
    80006ac2:	57fd                	li	a5,-1
}
    80006ac4:	853e                	mv	a0,a5
    80006ac6:	70b2                	ld	ra,296(sp)
    80006ac8:	7412                	ld	s0,288(sp)
    80006aca:	64f2                	ld	s1,280(sp)
    80006acc:	6952                	ld	s2,272(sp)
    80006ace:	6155                	addi	sp,sp,304
    80006ad0:	8082                	ret

0000000080006ad2 <sys_unlink>:
{
    80006ad2:	7151                	addi	sp,sp,-240
    80006ad4:	f586                	sd	ra,232(sp)
    80006ad6:	f1a2                	sd	s0,224(sp)
    80006ad8:	eda6                	sd	s1,216(sp)
    80006ada:	e9ca                	sd	s2,208(sp)
    80006adc:	e5ce                	sd	s3,200(sp)
    80006ade:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006ae0:	08000613          	li	a2,128
    80006ae4:	f3040593          	addi	a1,s0,-208
    80006ae8:	4501                	li	a0,0
    80006aea:	ffffd097          	auipc	ra,0xffffd
    80006aee:	672080e7          	jalr	1650(ra) # 8000415c <argstr>
    80006af2:	18054163          	bltz	a0,80006c74 <sys_unlink+0x1a2>
  begin_op();
    80006af6:	fffff097          	auipc	ra,0xfffff
    80006afa:	c12080e7          	jalr	-1006(ra) # 80005708 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006afe:	fb040593          	addi	a1,s0,-80
    80006b02:	f3040513          	addi	a0,s0,-208
    80006b06:	fffff097          	auipc	ra,0xfffff
    80006b0a:	a04080e7          	jalr	-1532(ra) # 8000550a <nameiparent>
    80006b0e:	84aa                	mv	s1,a0
    80006b10:	c979                	beqz	a0,80006be6 <sys_unlink+0x114>
  ilock(dp);
    80006b12:	ffffe097          	auipc	ra,0xffffe
    80006b16:	224080e7          	jalr	548(ra) # 80004d36 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006b1a:	00003597          	auipc	a1,0x3
    80006b1e:	fe658593          	addi	a1,a1,-26 # 80009b00 <syscalls+0x2d8>
    80006b22:	fb040513          	addi	a0,s0,-80
    80006b26:	ffffe097          	auipc	ra,0xffffe
    80006b2a:	6da080e7          	jalr	1754(ra) # 80005200 <namecmp>
    80006b2e:	14050a63          	beqz	a0,80006c82 <sys_unlink+0x1b0>
    80006b32:	00003597          	auipc	a1,0x3
    80006b36:	fd658593          	addi	a1,a1,-42 # 80009b08 <syscalls+0x2e0>
    80006b3a:	fb040513          	addi	a0,s0,-80
    80006b3e:	ffffe097          	auipc	ra,0xffffe
    80006b42:	6c2080e7          	jalr	1730(ra) # 80005200 <namecmp>
    80006b46:	12050e63          	beqz	a0,80006c82 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006b4a:	f2c40613          	addi	a2,s0,-212
    80006b4e:	fb040593          	addi	a1,s0,-80
    80006b52:	8526                	mv	a0,s1
    80006b54:	ffffe097          	auipc	ra,0xffffe
    80006b58:	6c6080e7          	jalr	1734(ra) # 8000521a <dirlookup>
    80006b5c:	892a                	mv	s2,a0
    80006b5e:	12050263          	beqz	a0,80006c82 <sys_unlink+0x1b0>
  ilock(ip);
    80006b62:	ffffe097          	auipc	ra,0xffffe
    80006b66:	1d4080e7          	jalr	468(ra) # 80004d36 <ilock>
  if(ip->nlink < 1)
    80006b6a:	04a91783          	lh	a5,74(s2)
    80006b6e:	08f05263          	blez	a5,80006bf2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006b72:	04491703          	lh	a4,68(s2)
    80006b76:	4785                	li	a5,1
    80006b78:	08f70563          	beq	a4,a5,80006c02 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006b7c:	4641                	li	a2,16
    80006b7e:	4581                	li	a1,0
    80006b80:	fc040513          	addi	a0,s0,-64
    80006b84:	ffffa097          	auipc	ra,0xffffa
    80006b88:	15c080e7          	jalr	348(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006b8c:	4741                	li	a4,16
    80006b8e:	f2c42683          	lw	a3,-212(s0)
    80006b92:	fc040613          	addi	a2,s0,-64
    80006b96:	4581                	li	a1,0
    80006b98:	8526                	mv	a0,s1
    80006b9a:	ffffe097          	auipc	ra,0xffffe
    80006b9e:	548080e7          	jalr	1352(ra) # 800050e2 <writei>
    80006ba2:	47c1                	li	a5,16
    80006ba4:	0af51563          	bne	a0,a5,80006c4e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006ba8:	04491703          	lh	a4,68(s2)
    80006bac:	4785                	li	a5,1
    80006bae:	0af70863          	beq	a4,a5,80006c5e <sys_unlink+0x18c>
  iunlockput(dp);
    80006bb2:	8526                	mv	a0,s1
    80006bb4:	ffffe097          	auipc	ra,0xffffe
    80006bb8:	3e4080e7          	jalr	996(ra) # 80004f98 <iunlockput>
  ip->nlink--;
    80006bbc:	04a95783          	lhu	a5,74(s2)
    80006bc0:	37fd                	addiw	a5,a5,-1
    80006bc2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006bc6:	854a                	mv	a0,s2
    80006bc8:	ffffe097          	auipc	ra,0xffffe
    80006bcc:	0a4080e7          	jalr	164(ra) # 80004c6c <iupdate>
  iunlockput(ip);
    80006bd0:	854a                	mv	a0,s2
    80006bd2:	ffffe097          	auipc	ra,0xffffe
    80006bd6:	3c6080e7          	jalr	966(ra) # 80004f98 <iunlockput>
  end_op();
    80006bda:	fffff097          	auipc	ra,0xfffff
    80006bde:	bae080e7          	jalr	-1106(ra) # 80005788 <end_op>
  return 0;
    80006be2:	4501                	li	a0,0
    80006be4:	a84d                	j	80006c96 <sys_unlink+0x1c4>
    end_op();
    80006be6:	fffff097          	auipc	ra,0xfffff
    80006bea:	ba2080e7          	jalr	-1118(ra) # 80005788 <end_op>
    return -1;
    80006bee:	557d                	li	a0,-1
    80006bf0:	a05d                	j	80006c96 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006bf2:	00003517          	auipc	a0,0x3
    80006bf6:	f3e50513          	addi	a0,a0,-194 # 80009b30 <syscalls+0x308>
    80006bfa:	ffffa097          	auipc	ra,0xffffa
    80006bfe:	944080e7          	jalr	-1724(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006c02:	04c92703          	lw	a4,76(s2)
    80006c06:	02000793          	li	a5,32
    80006c0a:	f6e7f9e3          	bgeu	a5,a4,80006b7c <sys_unlink+0xaa>
    80006c0e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006c12:	4741                	li	a4,16
    80006c14:	86ce                	mv	a3,s3
    80006c16:	f1840613          	addi	a2,s0,-232
    80006c1a:	4581                	li	a1,0
    80006c1c:	854a                	mv	a0,s2
    80006c1e:	ffffe097          	auipc	ra,0xffffe
    80006c22:	3cc080e7          	jalr	972(ra) # 80004fea <readi>
    80006c26:	47c1                	li	a5,16
    80006c28:	00f51b63          	bne	a0,a5,80006c3e <sys_unlink+0x16c>
    if(de.inum != 0)
    80006c2c:	f1845783          	lhu	a5,-232(s0)
    80006c30:	e7a1                	bnez	a5,80006c78 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006c32:	29c1                	addiw	s3,s3,16
    80006c34:	04c92783          	lw	a5,76(s2)
    80006c38:	fcf9ede3          	bltu	s3,a5,80006c12 <sys_unlink+0x140>
    80006c3c:	b781                	j	80006b7c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006c3e:	00003517          	auipc	a0,0x3
    80006c42:	f0a50513          	addi	a0,a0,-246 # 80009b48 <syscalls+0x320>
    80006c46:	ffffa097          	auipc	ra,0xffffa
    80006c4a:	8f8080e7          	jalr	-1800(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006c4e:	00003517          	auipc	a0,0x3
    80006c52:	f1250513          	addi	a0,a0,-238 # 80009b60 <syscalls+0x338>
    80006c56:	ffffa097          	auipc	ra,0xffffa
    80006c5a:	8e8080e7          	jalr	-1816(ra) # 8000053e <panic>
    dp->nlink--;
    80006c5e:	04a4d783          	lhu	a5,74(s1)
    80006c62:	37fd                	addiw	a5,a5,-1
    80006c64:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006c68:	8526                	mv	a0,s1
    80006c6a:	ffffe097          	auipc	ra,0xffffe
    80006c6e:	002080e7          	jalr	2(ra) # 80004c6c <iupdate>
    80006c72:	b781                	j	80006bb2 <sys_unlink+0xe0>
    return -1;
    80006c74:	557d                	li	a0,-1
    80006c76:	a005                	j	80006c96 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006c78:	854a                	mv	a0,s2
    80006c7a:	ffffe097          	auipc	ra,0xffffe
    80006c7e:	31e080e7          	jalr	798(ra) # 80004f98 <iunlockput>
  iunlockput(dp);
    80006c82:	8526                	mv	a0,s1
    80006c84:	ffffe097          	auipc	ra,0xffffe
    80006c88:	314080e7          	jalr	788(ra) # 80004f98 <iunlockput>
  end_op();
    80006c8c:	fffff097          	auipc	ra,0xfffff
    80006c90:	afc080e7          	jalr	-1284(ra) # 80005788 <end_op>
  return -1;
    80006c94:	557d                	li	a0,-1
}
    80006c96:	70ae                	ld	ra,232(sp)
    80006c98:	740e                	ld	s0,224(sp)
    80006c9a:	64ee                	ld	s1,216(sp)
    80006c9c:	694e                	ld	s2,208(sp)
    80006c9e:	69ae                	ld	s3,200(sp)
    80006ca0:	616d                	addi	sp,sp,240
    80006ca2:	8082                	ret

0000000080006ca4 <sys_open>:

uint64
sys_open(void)
{
    80006ca4:	7131                	addi	sp,sp,-192
    80006ca6:	fd06                	sd	ra,184(sp)
    80006ca8:	f922                	sd	s0,176(sp)
    80006caa:	f526                	sd	s1,168(sp)
    80006cac:	f14a                	sd	s2,160(sp)
    80006cae:	ed4e                	sd	s3,152(sp)
    80006cb0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006cb2:	08000613          	li	a2,128
    80006cb6:	f5040593          	addi	a1,s0,-176
    80006cba:	4501                	li	a0,0
    80006cbc:	ffffd097          	auipc	ra,0xffffd
    80006cc0:	4a0080e7          	jalr	1184(ra) # 8000415c <argstr>
    return -1;
    80006cc4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006cc6:	0c054163          	bltz	a0,80006d88 <sys_open+0xe4>
    80006cca:	f4c40593          	addi	a1,s0,-180
    80006cce:	4505                	li	a0,1
    80006cd0:	ffffd097          	auipc	ra,0xffffd
    80006cd4:	448080e7          	jalr	1096(ra) # 80004118 <argint>
    80006cd8:	0a054863          	bltz	a0,80006d88 <sys_open+0xe4>

  begin_op();
    80006cdc:	fffff097          	auipc	ra,0xfffff
    80006ce0:	a2c080e7          	jalr	-1492(ra) # 80005708 <begin_op>

  if(omode & O_CREATE){
    80006ce4:	f4c42783          	lw	a5,-180(s0)
    80006ce8:	2007f793          	andi	a5,a5,512
    80006cec:	cbdd                	beqz	a5,80006da2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006cee:	4681                	li	a3,0
    80006cf0:	4601                	li	a2,0
    80006cf2:	4589                	li	a1,2
    80006cf4:	f5040513          	addi	a0,s0,-176
    80006cf8:	00000097          	auipc	ra,0x0
    80006cfc:	970080e7          	jalr	-1680(ra) # 80006668 <create>
    80006d00:	892a                	mv	s2,a0
    if(ip == 0){
    80006d02:	c959                	beqz	a0,80006d98 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006d04:	04491703          	lh	a4,68(s2)
    80006d08:	478d                	li	a5,3
    80006d0a:	00f71763          	bne	a4,a5,80006d18 <sys_open+0x74>
    80006d0e:	04695703          	lhu	a4,70(s2)
    80006d12:	47a5                	li	a5,9
    80006d14:	0ce7ec63          	bltu	a5,a4,80006dec <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006d18:	fffff097          	auipc	ra,0xfffff
    80006d1c:	e00080e7          	jalr	-512(ra) # 80005b18 <filealloc>
    80006d20:	89aa                	mv	s3,a0
    80006d22:	10050263          	beqz	a0,80006e26 <sys_open+0x182>
    80006d26:	00000097          	auipc	ra,0x0
    80006d2a:	900080e7          	jalr	-1792(ra) # 80006626 <fdalloc>
    80006d2e:	84aa                	mv	s1,a0
    80006d30:	0e054663          	bltz	a0,80006e1c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006d34:	04491703          	lh	a4,68(s2)
    80006d38:	478d                	li	a5,3
    80006d3a:	0cf70463          	beq	a4,a5,80006e02 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006d3e:	4789                	li	a5,2
    80006d40:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006d44:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006d48:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006d4c:	f4c42783          	lw	a5,-180(s0)
    80006d50:	0017c713          	xori	a4,a5,1
    80006d54:	8b05                	andi	a4,a4,1
    80006d56:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006d5a:	0037f713          	andi	a4,a5,3
    80006d5e:	00e03733          	snez	a4,a4
    80006d62:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006d66:	4007f793          	andi	a5,a5,1024
    80006d6a:	c791                	beqz	a5,80006d76 <sys_open+0xd2>
    80006d6c:	04491703          	lh	a4,68(s2)
    80006d70:	4789                	li	a5,2
    80006d72:	08f70f63          	beq	a4,a5,80006e10 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006d76:	854a                	mv	a0,s2
    80006d78:	ffffe097          	auipc	ra,0xffffe
    80006d7c:	080080e7          	jalr	128(ra) # 80004df8 <iunlock>
  end_op();
    80006d80:	fffff097          	auipc	ra,0xfffff
    80006d84:	a08080e7          	jalr	-1528(ra) # 80005788 <end_op>

  return fd;
}
    80006d88:	8526                	mv	a0,s1
    80006d8a:	70ea                	ld	ra,184(sp)
    80006d8c:	744a                	ld	s0,176(sp)
    80006d8e:	74aa                	ld	s1,168(sp)
    80006d90:	790a                	ld	s2,160(sp)
    80006d92:	69ea                	ld	s3,152(sp)
    80006d94:	6129                	addi	sp,sp,192
    80006d96:	8082                	ret
      end_op();
    80006d98:	fffff097          	auipc	ra,0xfffff
    80006d9c:	9f0080e7          	jalr	-1552(ra) # 80005788 <end_op>
      return -1;
    80006da0:	b7e5                	j	80006d88 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006da2:	f5040513          	addi	a0,s0,-176
    80006da6:	ffffe097          	auipc	ra,0xffffe
    80006daa:	746080e7          	jalr	1862(ra) # 800054ec <namei>
    80006dae:	892a                	mv	s2,a0
    80006db0:	c905                	beqz	a0,80006de0 <sys_open+0x13c>
    ilock(ip);
    80006db2:	ffffe097          	auipc	ra,0xffffe
    80006db6:	f84080e7          	jalr	-124(ra) # 80004d36 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006dba:	04491703          	lh	a4,68(s2)
    80006dbe:	4785                	li	a5,1
    80006dc0:	f4f712e3          	bne	a4,a5,80006d04 <sys_open+0x60>
    80006dc4:	f4c42783          	lw	a5,-180(s0)
    80006dc8:	dba1                	beqz	a5,80006d18 <sys_open+0x74>
      iunlockput(ip);
    80006dca:	854a                	mv	a0,s2
    80006dcc:	ffffe097          	auipc	ra,0xffffe
    80006dd0:	1cc080e7          	jalr	460(ra) # 80004f98 <iunlockput>
      end_op();
    80006dd4:	fffff097          	auipc	ra,0xfffff
    80006dd8:	9b4080e7          	jalr	-1612(ra) # 80005788 <end_op>
      return -1;
    80006ddc:	54fd                	li	s1,-1
    80006dde:	b76d                	j	80006d88 <sys_open+0xe4>
      end_op();
    80006de0:	fffff097          	auipc	ra,0xfffff
    80006de4:	9a8080e7          	jalr	-1624(ra) # 80005788 <end_op>
      return -1;
    80006de8:	54fd                	li	s1,-1
    80006dea:	bf79                	j	80006d88 <sys_open+0xe4>
    iunlockput(ip);
    80006dec:	854a                	mv	a0,s2
    80006dee:	ffffe097          	auipc	ra,0xffffe
    80006df2:	1aa080e7          	jalr	426(ra) # 80004f98 <iunlockput>
    end_op();
    80006df6:	fffff097          	auipc	ra,0xfffff
    80006dfa:	992080e7          	jalr	-1646(ra) # 80005788 <end_op>
    return -1;
    80006dfe:	54fd                	li	s1,-1
    80006e00:	b761                	j	80006d88 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006e02:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006e06:	04691783          	lh	a5,70(s2)
    80006e0a:	02f99223          	sh	a5,36(s3)
    80006e0e:	bf2d                	j	80006d48 <sys_open+0xa4>
    itrunc(ip);
    80006e10:	854a                	mv	a0,s2
    80006e12:	ffffe097          	auipc	ra,0xffffe
    80006e16:	032080e7          	jalr	50(ra) # 80004e44 <itrunc>
    80006e1a:	bfb1                	j	80006d76 <sys_open+0xd2>
      fileclose(f);
    80006e1c:	854e                	mv	a0,s3
    80006e1e:	fffff097          	auipc	ra,0xfffff
    80006e22:	db6080e7          	jalr	-586(ra) # 80005bd4 <fileclose>
    iunlockput(ip);
    80006e26:	854a                	mv	a0,s2
    80006e28:	ffffe097          	auipc	ra,0xffffe
    80006e2c:	170080e7          	jalr	368(ra) # 80004f98 <iunlockput>
    end_op();
    80006e30:	fffff097          	auipc	ra,0xfffff
    80006e34:	958080e7          	jalr	-1704(ra) # 80005788 <end_op>
    return -1;
    80006e38:	54fd                	li	s1,-1
    80006e3a:	b7b9                	j	80006d88 <sys_open+0xe4>

0000000080006e3c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006e3c:	7175                	addi	sp,sp,-144
    80006e3e:	e506                	sd	ra,136(sp)
    80006e40:	e122                	sd	s0,128(sp)
    80006e42:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006e44:	fffff097          	auipc	ra,0xfffff
    80006e48:	8c4080e7          	jalr	-1852(ra) # 80005708 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006e4c:	08000613          	li	a2,128
    80006e50:	f7040593          	addi	a1,s0,-144
    80006e54:	4501                	li	a0,0
    80006e56:	ffffd097          	auipc	ra,0xffffd
    80006e5a:	306080e7          	jalr	774(ra) # 8000415c <argstr>
    80006e5e:	02054963          	bltz	a0,80006e90 <sys_mkdir+0x54>
    80006e62:	4681                	li	a3,0
    80006e64:	4601                	li	a2,0
    80006e66:	4585                	li	a1,1
    80006e68:	f7040513          	addi	a0,s0,-144
    80006e6c:	fffff097          	auipc	ra,0xfffff
    80006e70:	7fc080e7          	jalr	2044(ra) # 80006668 <create>
    80006e74:	cd11                	beqz	a0,80006e90 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006e76:	ffffe097          	auipc	ra,0xffffe
    80006e7a:	122080e7          	jalr	290(ra) # 80004f98 <iunlockput>
  end_op();
    80006e7e:	fffff097          	auipc	ra,0xfffff
    80006e82:	90a080e7          	jalr	-1782(ra) # 80005788 <end_op>
  return 0;
    80006e86:	4501                	li	a0,0
}
    80006e88:	60aa                	ld	ra,136(sp)
    80006e8a:	640a                	ld	s0,128(sp)
    80006e8c:	6149                	addi	sp,sp,144
    80006e8e:	8082                	ret
    end_op();
    80006e90:	fffff097          	auipc	ra,0xfffff
    80006e94:	8f8080e7          	jalr	-1800(ra) # 80005788 <end_op>
    return -1;
    80006e98:	557d                	li	a0,-1
    80006e9a:	b7fd                	j	80006e88 <sys_mkdir+0x4c>

0000000080006e9c <sys_mknod>:

uint64
sys_mknod(void)
{
    80006e9c:	7135                	addi	sp,sp,-160
    80006e9e:	ed06                	sd	ra,152(sp)
    80006ea0:	e922                	sd	s0,144(sp)
    80006ea2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006ea4:	fffff097          	auipc	ra,0xfffff
    80006ea8:	864080e7          	jalr	-1948(ra) # 80005708 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006eac:	08000613          	li	a2,128
    80006eb0:	f7040593          	addi	a1,s0,-144
    80006eb4:	4501                	li	a0,0
    80006eb6:	ffffd097          	auipc	ra,0xffffd
    80006eba:	2a6080e7          	jalr	678(ra) # 8000415c <argstr>
    80006ebe:	04054a63          	bltz	a0,80006f12 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006ec2:	f6c40593          	addi	a1,s0,-148
    80006ec6:	4505                	li	a0,1
    80006ec8:	ffffd097          	auipc	ra,0xffffd
    80006ecc:	250080e7          	jalr	592(ra) # 80004118 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006ed0:	04054163          	bltz	a0,80006f12 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006ed4:	f6840593          	addi	a1,s0,-152
    80006ed8:	4509                	li	a0,2
    80006eda:	ffffd097          	auipc	ra,0xffffd
    80006ede:	23e080e7          	jalr	574(ra) # 80004118 <argint>
     argint(1, &major) < 0 ||
    80006ee2:	02054863          	bltz	a0,80006f12 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006ee6:	f6841683          	lh	a3,-152(s0)
    80006eea:	f6c41603          	lh	a2,-148(s0)
    80006eee:	458d                	li	a1,3
    80006ef0:	f7040513          	addi	a0,s0,-144
    80006ef4:	fffff097          	auipc	ra,0xfffff
    80006ef8:	774080e7          	jalr	1908(ra) # 80006668 <create>
     argint(2, &minor) < 0 ||
    80006efc:	c919                	beqz	a0,80006f12 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006efe:	ffffe097          	auipc	ra,0xffffe
    80006f02:	09a080e7          	jalr	154(ra) # 80004f98 <iunlockput>
  end_op();
    80006f06:	fffff097          	auipc	ra,0xfffff
    80006f0a:	882080e7          	jalr	-1918(ra) # 80005788 <end_op>
  return 0;
    80006f0e:	4501                	li	a0,0
    80006f10:	a031                	j	80006f1c <sys_mknod+0x80>
    end_op();
    80006f12:	fffff097          	auipc	ra,0xfffff
    80006f16:	876080e7          	jalr	-1930(ra) # 80005788 <end_op>
    return -1;
    80006f1a:	557d                	li	a0,-1
}
    80006f1c:	60ea                	ld	ra,152(sp)
    80006f1e:	644a                	ld	s0,144(sp)
    80006f20:	610d                	addi	sp,sp,160
    80006f22:	8082                	ret

0000000080006f24 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006f24:	7135                	addi	sp,sp,-160
    80006f26:	ed06                	sd	ra,152(sp)
    80006f28:	e922                	sd	s0,144(sp)
    80006f2a:	e526                	sd	s1,136(sp)
    80006f2c:	e14a                	sd	s2,128(sp)
    80006f2e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006f30:	ffffb097          	auipc	ra,0xffffb
    80006f34:	c64080e7          	jalr	-924(ra) # 80001b94 <myproc>
    80006f38:	892a                	mv	s2,a0
  
  begin_op();
    80006f3a:	ffffe097          	auipc	ra,0xffffe
    80006f3e:	7ce080e7          	jalr	1998(ra) # 80005708 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006f42:	08000613          	li	a2,128
    80006f46:	f6040593          	addi	a1,s0,-160
    80006f4a:	4501                	li	a0,0
    80006f4c:	ffffd097          	auipc	ra,0xffffd
    80006f50:	210080e7          	jalr	528(ra) # 8000415c <argstr>
    80006f54:	04054b63          	bltz	a0,80006faa <sys_chdir+0x86>
    80006f58:	f6040513          	addi	a0,s0,-160
    80006f5c:	ffffe097          	auipc	ra,0xffffe
    80006f60:	590080e7          	jalr	1424(ra) # 800054ec <namei>
    80006f64:	84aa                	mv	s1,a0
    80006f66:	c131                	beqz	a0,80006faa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006f68:	ffffe097          	auipc	ra,0xffffe
    80006f6c:	dce080e7          	jalr	-562(ra) # 80004d36 <ilock>
  if(ip->type != T_DIR){
    80006f70:	04449703          	lh	a4,68(s1)
    80006f74:	4785                	li	a5,1
    80006f76:	04f71063          	bne	a4,a5,80006fb6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006f7a:	8526                	mv	a0,s1
    80006f7c:	ffffe097          	auipc	ra,0xffffe
    80006f80:	e7c080e7          	jalr	-388(ra) # 80004df8 <iunlock>
  iput(p->cwd);
    80006f84:	18093503          	ld	a0,384(s2)
    80006f88:	ffffe097          	auipc	ra,0xffffe
    80006f8c:	f68080e7          	jalr	-152(ra) # 80004ef0 <iput>
  end_op();
    80006f90:	ffffe097          	auipc	ra,0xffffe
    80006f94:	7f8080e7          	jalr	2040(ra) # 80005788 <end_op>
  p->cwd = ip;
    80006f98:	18993023          	sd	s1,384(s2)
  return 0;
    80006f9c:	4501                	li	a0,0
}
    80006f9e:	60ea                	ld	ra,152(sp)
    80006fa0:	644a                	ld	s0,144(sp)
    80006fa2:	64aa                	ld	s1,136(sp)
    80006fa4:	690a                	ld	s2,128(sp)
    80006fa6:	610d                	addi	sp,sp,160
    80006fa8:	8082                	ret
    end_op();
    80006faa:	ffffe097          	auipc	ra,0xffffe
    80006fae:	7de080e7          	jalr	2014(ra) # 80005788 <end_op>
    return -1;
    80006fb2:	557d                	li	a0,-1
    80006fb4:	b7ed                	j	80006f9e <sys_chdir+0x7a>
    iunlockput(ip);
    80006fb6:	8526                	mv	a0,s1
    80006fb8:	ffffe097          	auipc	ra,0xffffe
    80006fbc:	fe0080e7          	jalr	-32(ra) # 80004f98 <iunlockput>
    end_op();
    80006fc0:	ffffe097          	auipc	ra,0xffffe
    80006fc4:	7c8080e7          	jalr	1992(ra) # 80005788 <end_op>
    return -1;
    80006fc8:	557d                	li	a0,-1
    80006fca:	bfd1                	j	80006f9e <sys_chdir+0x7a>

0000000080006fcc <sys_exec>:

uint64
sys_exec(void)
{
    80006fcc:	7145                	addi	sp,sp,-464
    80006fce:	e786                	sd	ra,456(sp)
    80006fd0:	e3a2                	sd	s0,448(sp)
    80006fd2:	ff26                	sd	s1,440(sp)
    80006fd4:	fb4a                	sd	s2,432(sp)
    80006fd6:	f74e                	sd	s3,424(sp)
    80006fd8:	f352                	sd	s4,416(sp)
    80006fda:	ef56                	sd	s5,408(sp)
    80006fdc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006fde:	08000613          	li	a2,128
    80006fe2:	f4040593          	addi	a1,s0,-192
    80006fe6:	4501                	li	a0,0
    80006fe8:	ffffd097          	auipc	ra,0xffffd
    80006fec:	174080e7          	jalr	372(ra) # 8000415c <argstr>
    return -1;
    80006ff0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006ff2:	0c054a63          	bltz	a0,800070c6 <sys_exec+0xfa>
    80006ff6:	e3840593          	addi	a1,s0,-456
    80006ffa:	4505                	li	a0,1
    80006ffc:	ffffd097          	auipc	ra,0xffffd
    80007000:	13e080e7          	jalr	318(ra) # 8000413a <argaddr>
    80007004:	0c054163          	bltz	a0,800070c6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80007008:	10000613          	li	a2,256
    8000700c:	4581                	li	a1,0
    8000700e:	e4040513          	addi	a0,s0,-448
    80007012:	ffffa097          	auipc	ra,0xffffa
    80007016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000701a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000701e:	89a6                	mv	s3,s1
    80007020:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80007022:	02000a13          	li	s4,32
    80007026:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000702a:	00391513          	slli	a0,s2,0x3
    8000702e:	e3040593          	addi	a1,s0,-464
    80007032:	e3843783          	ld	a5,-456(s0)
    80007036:	953e                	add	a0,a0,a5
    80007038:	ffffd097          	auipc	ra,0xffffd
    8000703c:	046080e7          	jalr	70(ra) # 8000407e <fetchaddr>
    80007040:	02054a63          	bltz	a0,80007074 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80007044:	e3043783          	ld	a5,-464(s0)
    80007048:	c3b9                	beqz	a5,8000708e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000704a:	ffffa097          	auipc	ra,0xffffa
    8000704e:	aaa080e7          	jalr	-1366(ra) # 80000af4 <kalloc>
    80007052:	85aa                	mv	a1,a0
    80007054:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80007058:	cd11                	beqz	a0,80007074 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000705a:	6605                	lui	a2,0x1
    8000705c:	e3043503          	ld	a0,-464(s0)
    80007060:	ffffd097          	auipc	ra,0xffffd
    80007064:	070080e7          	jalr	112(ra) # 800040d0 <fetchstr>
    80007068:	00054663          	bltz	a0,80007074 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000706c:	0905                	addi	s2,s2,1
    8000706e:	09a1                	addi	s3,s3,8
    80007070:	fb491be3          	bne	s2,s4,80007026 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80007074:	10048913          	addi	s2,s1,256
    80007078:	6088                	ld	a0,0(s1)
    8000707a:	c529                	beqz	a0,800070c4 <sys_exec+0xf8>
    kfree(argv[i]);
    8000707c:	ffffa097          	auipc	ra,0xffffa
    80007080:	97c080e7          	jalr	-1668(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80007084:	04a1                	addi	s1,s1,8
    80007086:	ff2499e3          	bne	s1,s2,80007078 <sys_exec+0xac>
  return -1;
    8000708a:	597d                	li	s2,-1
    8000708c:	a82d                	j	800070c6 <sys_exec+0xfa>
      argv[i] = 0;
    8000708e:	0a8e                	slli	s5,s5,0x3
    80007090:	fc040793          	addi	a5,s0,-64
    80007094:	9abe                	add	s5,s5,a5
    80007096:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000709a:	e4040593          	addi	a1,s0,-448
    8000709e:	f4040513          	addi	a0,s0,-192
    800070a2:	fffff097          	auipc	ra,0xfffff
    800070a6:	192080e7          	jalr	402(ra) # 80006234 <exec>
    800070aa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800070ac:	10048993          	addi	s3,s1,256
    800070b0:	6088                	ld	a0,0(s1)
    800070b2:	c911                	beqz	a0,800070c6 <sys_exec+0xfa>
    kfree(argv[i]);
    800070b4:	ffffa097          	auipc	ra,0xffffa
    800070b8:	944080e7          	jalr	-1724(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800070bc:	04a1                	addi	s1,s1,8
    800070be:	ff3499e3          	bne	s1,s3,800070b0 <sys_exec+0xe4>
    800070c2:	a011                	j	800070c6 <sys_exec+0xfa>
  return -1;
    800070c4:	597d                	li	s2,-1
}
    800070c6:	854a                	mv	a0,s2
    800070c8:	60be                	ld	ra,456(sp)
    800070ca:	641e                	ld	s0,448(sp)
    800070cc:	74fa                	ld	s1,440(sp)
    800070ce:	795a                	ld	s2,432(sp)
    800070d0:	79ba                	ld	s3,424(sp)
    800070d2:	7a1a                	ld	s4,416(sp)
    800070d4:	6afa                	ld	s5,408(sp)
    800070d6:	6179                	addi	sp,sp,464
    800070d8:	8082                	ret

00000000800070da <sys_pipe>:

uint64
sys_pipe(void)
{
    800070da:	7139                	addi	sp,sp,-64
    800070dc:	fc06                	sd	ra,56(sp)
    800070de:	f822                	sd	s0,48(sp)
    800070e0:	f426                	sd	s1,40(sp)
    800070e2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800070e4:	ffffb097          	auipc	ra,0xffffb
    800070e8:	ab0080e7          	jalr	-1360(ra) # 80001b94 <myproc>
    800070ec:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800070ee:	fd840593          	addi	a1,s0,-40
    800070f2:	4501                	li	a0,0
    800070f4:	ffffd097          	auipc	ra,0xffffd
    800070f8:	046080e7          	jalr	70(ra) # 8000413a <argaddr>
    return -1;
    800070fc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800070fe:	0e054263          	bltz	a0,800071e2 <sys_pipe+0x108>
  if(pipealloc(&rf, &wf) < 0)
    80007102:	fc840593          	addi	a1,s0,-56
    80007106:	fd040513          	addi	a0,s0,-48
    8000710a:	fffff097          	auipc	ra,0xfffff
    8000710e:	dfa080e7          	jalr	-518(ra) # 80005f04 <pipealloc>
    return -1;
    80007112:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80007114:	0c054763          	bltz	a0,800071e2 <sys_pipe+0x108>
  fd0 = -1;
    80007118:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000711c:	fd043503          	ld	a0,-48(s0)
    80007120:	fffff097          	auipc	ra,0xfffff
    80007124:	506080e7          	jalr	1286(ra) # 80006626 <fdalloc>
    80007128:	fca42223          	sw	a0,-60(s0)
    8000712c:	08054e63          	bltz	a0,800071c8 <sys_pipe+0xee>
    80007130:	fc843503          	ld	a0,-56(s0)
    80007134:	fffff097          	auipc	ra,0xfffff
    80007138:	4f2080e7          	jalr	1266(ra) # 80006626 <fdalloc>
    8000713c:	fca42023          	sw	a0,-64(s0)
    80007140:	06054a63          	bltz	a0,800071b4 <sys_pipe+0xda>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80007144:	4691                	li	a3,4
    80007146:	fc440613          	addi	a2,s0,-60
    8000714a:	fd843583          	ld	a1,-40(s0)
    8000714e:	60c8                	ld	a0,128(s1)
    80007150:	ffffa097          	auipc	ra,0xffffa
    80007154:	52a080e7          	jalr	1322(ra) # 8000167a <copyout>
    80007158:	02054063          	bltz	a0,80007178 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000715c:	4691                	li	a3,4
    8000715e:	fc040613          	addi	a2,s0,-64
    80007162:	fd843583          	ld	a1,-40(s0)
    80007166:	0591                	addi	a1,a1,4
    80007168:	60c8                	ld	a0,128(s1)
    8000716a:	ffffa097          	auipc	ra,0xffffa
    8000716e:	510080e7          	jalr	1296(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80007172:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80007174:	06055763          	bgez	a0,800071e2 <sys_pipe+0x108>
    p->ofile[fd0] = 0;
    80007178:	fc442783          	lw	a5,-60(s0)
    8000717c:	02078793          	addi	a5,a5,32
    80007180:	078e                	slli	a5,a5,0x3
    80007182:	97a6                	add	a5,a5,s1
    80007184:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80007188:	fc042503          	lw	a0,-64(s0)
    8000718c:	02050513          	addi	a0,a0,32
    80007190:	050e                	slli	a0,a0,0x3
    80007192:	9526                	add	a0,a0,s1
    80007194:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80007198:	fd043503          	ld	a0,-48(s0)
    8000719c:	fffff097          	auipc	ra,0xfffff
    800071a0:	a38080e7          	jalr	-1480(ra) # 80005bd4 <fileclose>
    fileclose(wf);
    800071a4:	fc843503          	ld	a0,-56(s0)
    800071a8:	fffff097          	auipc	ra,0xfffff
    800071ac:	a2c080e7          	jalr	-1492(ra) # 80005bd4 <fileclose>
    return -1;
    800071b0:	57fd                	li	a5,-1
    800071b2:	a805                	j	800071e2 <sys_pipe+0x108>
    if(fd0 >= 0)
    800071b4:	fc442783          	lw	a5,-60(s0)
    800071b8:	0007c863          	bltz	a5,800071c8 <sys_pipe+0xee>
      p->ofile[fd0] = 0;
    800071bc:	02078513          	addi	a0,a5,32
    800071c0:	050e                	slli	a0,a0,0x3
    800071c2:	9526                	add	a0,a0,s1
    800071c4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800071c8:	fd043503          	ld	a0,-48(s0)
    800071cc:	fffff097          	auipc	ra,0xfffff
    800071d0:	a08080e7          	jalr	-1528(ra) # 80005bd4 <fileclose>
    fileclose(wf);
    800071d4:	fc843503          	ld	a0,-56(s0)
    800071d8:	fffff097          	auipc	ra,0xfffff
    800071dc:	9fc080e7          	jalr	-1540(ra) # 80005bd4 <fileclose>
    return -1;
    800071e0:	57fd                	li	a5,-1
}
    800071e2:	853e                	mv	a0,a5
    800071e4:	70e2                	ld	ra,56(sp)
    800071e6:	7442                	ld	s0,48(sp)
    800071e8:	74a2                	ld	s1,40(sp)
    800071ea:	6121                	addi	sp,sp,64
    800071ec:	8082                	ret
	...

00000000800071f0 <kernelvec>:
    800071f0:	7111                	addi	sp,sp,-256
    800071f2:	e006                	sd	ra,0(sp)
    800071f4:	e40a                	sd	sp,8(sp)
    800071f6:	e80e                	sd	gp,16(sp)
    800071f8:	ec12                	sd	tp,24(sp)
    800071fa:	f016                	sd	t0,32(sp)
    800071fc:	f41a                	sd	t1,40(sp)
    800071fe:	f81e                	sd	t2,48(sp)
    80007200:	fc22                	sd	s0,56(sp)
    80007202:	e0a6                	sd	s1,64(sp)
    80007204:	e4aa                	sd	a0,72(sp)
    80007206:	e8ae                	sd	a1,80(sp)
    80007208:	ecb2                	sd	a2,88(sp)
    8000720a:	f0b6                	sd	a3,96(sp)
    8000720c:	f4ba                	sd	a4,104(sp)
    8000720e:	f8be                	sd	a5,112(sp)
    80007210:	fcc2                	sd	a6,120(sp)
    80007212:	e146                	sd	a7,128(sp)
    80007214:	e54a                	sd	s2,136(sp)
    80007216:	e94e                	sd	s3,144(sp)
    80007218:	ed52                	sd	s4,152(sp)
    8000721a:	f156                	sd	s5,160(sp)
    8000721c:	f55a                	sd	s6,168(sp)
    8000721e:	f95e                	sd	s7,176(sp)
    80007220:	fd62                	sd	s8,184(sp)
    80007222:	e1e6                	sd	s9,192(sp)
    80007224:	e5ea                	sd	s10,200(sp)
    80007226:	e9ee                	sd	s11,208(sp)
    80007228:	edf2                	sd	t3,216(sp)
    8000722a:	f1f6                	sd	t4,224(sp)
    8000722c:	f5fa                	sd	t5,232(sp)
    8000722e:	f9fe                	sd	t6,240(sp)
    80007230:	ceffc0ef          	jal	ra,80003f1e <kerneltrap>
    80007234:	6082                	ld	ra,0(sp)
    80007236:	6122                	ld	sp,8(sp)
    80007238:	61c2                	ld	gp,16(sp)
    8000723a:	7282                	ld	t0,32(sp)
    8000723c:	7322                	ld	t1,40(sp)
    8000723e:	73c2                	ld	t2,48(sp)
    80007240:	7462                	ld	s0,56(sp)
    80007242:	6486                	ld	s1,64(sp)
    80007244:	6526                	ld	a0,72(sp)
    80007246:	65c6                	ld	a1,80(sp)
    80007248:	6666                	ld	a2,88(sp)
    8000724a:	7686                	ld	a3,96(sp)
    8000724c:	7726                	ld	a4,104(sp)
    8000724e:	77c6                	ld	a5,112(sp)
    80007250:	7866                	ld	a6,120(sp)
    80007252:	688a                	ld	a7,128(sp)
    80007254:	692a                	ld	s2,136(sp)
    80007256:	69ca                	ld	s3,144(sp)
    80007258:	6a6a                	ld	s4,152(sp)
    8000725a:	7a8a                	ld	s5,160(sp)
    8000725c:	7b2a                	ld	s6,168(sp)
    8000725e:	7bca                	ld	s7,176(sp)
    80007260:	7c6a                	ld	s8,184(sp)
    80007262:	6c8e                	ld	s9,192(sp)
    80007264:	6d2e                	ld	s10,200(sp)
    80007266:	6dce                	ld	s11,208(sp)
    80007268:	6e6e                	ld	t3,216(sp)
    8000726a:	7e8e                	ld	t4,224(sp)
    8000726c:	7f2e                	ld	t5,232(sp)
    8000726e:	7fce                	ld	t6,240(sp)
    80007270:	6111                	addi	sp,sp,256
    80007272:	10200073          	sret
    80007276:	00000013          	nop
    8000727a:	00000013          	nop
    8000727e:	0001                	nop

0000000080007280 <timervec>:
    80007280:	34051573          	csrrw	a0,mscratch,a0
    80007284:	e10c                	sd	a1,0(a0)
    80007286:	e510                	sd	a2,8(a0)
    80007288:	e914                	sd	a3,16(a0)
    8000728a:	6d0c                	ld	a1,24(a0)
    8000728c:	7110                	ld	a2,32(a0)
    8000728e:	6194                	ld	a3,0(a1)
    80007290:	96b2                	add	a3,a3,a2
    80007292:	e194                	sd	a3,0(a1)
    80007294:	4589                	li	a1,2
    80007296:	14459073          	csrw	sip,a1
    8000729a:	6914                	ld	a3,16(a0)
    8000729c:	6510                	ld	a2,8(a0)
    8000729e:	610c                	ld	a1,0(a0)
    800072a0:	34051573          	csrrw	a0,mscratch,a0
    800072a4:	30200073          	mret
	...

00000000800072aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800072aa:	1141                	addi	sp,sp,-16
    800072ac:	e422                	sd	s0,8(sp)
    800072ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800072b0:	0c0007b7          	lui	a5,0xc000
    800072b4:	4705                	li	a4,1
    800072b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800072b8:	c3d8                	sw	a4,4(a5)
}
    800072ba:	6422                	ld	s0,8(sp)
    800072bc:	0141                	addi	sp,sp,16
    800072be:	8082                	ret

00000000800072c0 <plicinithart>:

void
plicinithart(void)
{
    800072c0:	1141                	addi	sp,sp,-16
    800072c2:	e406                	sd	ra,8(sp)
    800072c4:	e022                	sd	s0,0(sp)
    800072c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800072c8:	ffffb097          	auipc	ra,0xffffb
    800072cc:	890080e7          	jalr	-1904(ra) # 80001b58 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800072d0:	0085171b          	slliw	a4,a0,0x8
    800072d4:	0c0027b7          	lui	a5,0xc002
    800072d8:	97ba                	add	a5,a5,a4
    800072da:	40200713          	li	a4,1026
    800072de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800072e2:	00d5151b          	slliw	a0,a0,0xd
    800072e6:	0c2017b7          	lui	a5,0xc201
    800072ea:	953e                	add	a0,a0,a5
    800072ec:	00052023          	sw	zero,0(a0)
}
    800072f0:	60a2                	ld	ra,8(sp)
    800072f2:	6402                	ld	s0,0(sp)
    800072f4:	0141                	addi	sp,sp,16
    800072f6:	8082                	ret

00000000800072f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800072f8:	1141                	addi	sp,sp,-16
    800072fa:	e406                	sd	ra,8(sp)
    800072fc:	e022                	sd	s0,0(sp)
    800072fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80007300:	ffffb097          	auipc	ra,0xffffb
    80007304:	858080e7          	jalr	-1960(ra) # 80001b58 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80007308:	00d5179b          	slliw	a5,a0,0xd
    8000730c:	0c201537          	lui	a0,0xc201
    80007310:	953e                	add	a0,a0,a5
  return irq;
}
    80007312:	4148                	lw	a0,4(a0)
    80007314:	60a2                	ld	ra,8(sp)
    80007316:	6402                	ld	s0,0(sp)
    80007318:	0141                	addi	sp,sp,16
    8000731a:	8082                	ret

000000008000731c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000731c:	1101                	addi	sp,sp,-32
    8000731e:	ec06                	sd	ra,24(sp)
    80007320:	e822                	sd	s0,16(sp)
    80007322:	e426                	sd	s1,8(sp)
    80007324:	1000                	addi	s0,sp,32
    80007326:	84aa                	mv	s1,a0
  int hart = cpuid();
    80007328:	ffffb097          	auipc	ra,0xffffb
    8000732c:	830080e7          	jalr	-2000(ra) # 80001b58 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80007330:	00d5151b          	slliw	a0,a0,0xd
    80007334:	0c2017b7          	lui	a5,0xc201
    80007338:	97aa                	add	a5,a5,a0
    8000733a:	c3c4                	sw	s1,4(a5)
}
    8000733c:	60e2                	ld	ra,24(sp)
    8000733e:	6442                	ld	s0,16(sp)
    80007340:	64a2                	ld	s1,8(sp)
    80007342:	6105                	addi	sp,sp,32
    80007344:	8082                	ret

0000000080007346 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80007346:	1141                	addi	sp,sp,-16
    80007348:	e406                	sd	ra,8(sp)
    8000734a:	e022                	sd	s0,0(sp)
    8000734c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000734e:	479d                	li	a5,7
    80007350:	06a7c963          	blt	a5,a0,800073c2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80007354:	0001e797          	auipc	a5,0x1e
    80007358:	cac78793          	addi	a5,a5,-852 # 80025000 <disk>
    8000735c:	00a78733          	add	a4,a5,a0
    80007360:	6789                	lui	a5,0x2
    80007362:	97ba                	add	a5,a5,a4
    80007364:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80007368:	e7ad                	bnez	a5,800073d2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000736a:	00451793          	slli	a5,a0,0x4
    8000736e:	00020717          	auipc	a4,0x20
    80007372:	c9270713          	addi	a4,a4,-878 # 80027000 <disk+0x2000>
    80007376:	6314                	ld	a3,0(a4)
    80007378:	96be                	add	a3,a3,a5
    8000737a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000737e:	6314                	ld	a3,0(a4)
    80007380:	96be                	add	a3,a3,a5
    80007382:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80007386:	6314                	ld	a3,0(a4)
    80007388:	96be                	add	a3,a3,a5
    8000738a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000738e:	6318                	ld	a4,0(a4)
    80007390:	97ba                	add	a5,a5,a4
    80007392:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80007396:	0001e797          	auipc	a5,0x1e
    8000739a:	c6a78793          	addi	a5,a5,-918 # 80025000 <disk>
    8000739e:	97aa                	add	a5,a5,a0
    800073a0:	6509                	lui	a0,0x2
    800073a2:	953e                	add	a0,a0,a5
    800073a4:	4785                	li	a5,1
    800073a6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800073aa:	00020517          	auipc	a0,0x20
    800073ae:	c6e50513          	addi	a0,a0,-914 # 80027018 <disk+0x2018>
    800073b2:	ffffc097          	auipc	ra,0xffffc
    800073b6:	ce2080e7          	jalr	-798(ra) # 80003094 <wakeup>
}
    800073ba:	60a2                	ld	ra,8(sp)
    800073bc:	6402                	ld	s0,0(sp)
    800073be:	0141                	addi	sp,sp,16
    800073c0:	8082                	ret
    panic("free_desc 1");
    800073c2:	00002517          	auipc	a0,0x2
    800073c6:	7ae50513          	addi	a0,a0,1966 # 80009b70 <syscalls+0x348>
    800073ca:	ffff9097          	auipc	ra,0xffff9
    800073ce:	174080e7          	jalr	372(ra) # 8000053e <panic>
    panic("free_desc 2");
    800073d2:	00002517          	auipc	a0,0x2
    800073d6:	7ae50513          	addi	a0,a0,1966 # 80009b80 <syscalls+0x358>
    800073da:	ffff9097          	auipc	ra,0xffff9
    800073de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800073e2 <virtio_disk_init>:
{
    800073e2:	1101                	addi	sp,sp,-32
    800073e4:	ec06                	sd	ra,24(sp)
    800073e6:	e822                	sd	s0,16(sp)
    800073e8:	e426                	sd	s1,8(sp)
    800073ea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800073ec:	00002597          	auipc	a1,0x2
    800073f0:	7a458593          	addi	a1,a1,1956 # 80009b90 <syscalls+0x368>
    800073f4:	00020517          	auipc	a0,0x20
    800073f8:	d3450513          	addi	a0,a0,-716 # 80027128 <disk+0x2128>
    800073fc:	ffff9097          	auipc	ra,0xffff9
    80007400:	758080e7          	jalr	1880(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80007404:	100017b7          	lui	a5,0x10001
    80007408:	4398                	lw	a4,0(a5)
    8000740a:	2701                	sext.w	a4,a4
    8000740c:	747277b7          	lui	a5,0x74727
    80007410:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80007414:	0ef71163          	bne	a4,a5,800074f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80007418:	100017b7          	lui	a5,0x10001
    8000741c:	43dc                	lw	a5,4(a5)
    8000741e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80007420:	4705                	li	a4,1
    80007422:	0ce79a63          	bne	a5,a4,800074f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80007426:	100017b7          	lui	a5,0x10001
    8000742a:	479c                	lw	a5,8(a5)
    8000742c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000742e:	4709                	li	a4,2
    80007430:	0ce79363          	bne	a5,a4,800074f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80007434:	100017b7          	lui	a5,0x10001
    80007438:	47d8                	lw	a4,12(a5)
    8000743a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000743c:	554d47b7          	lui	a5,0x554d4
    80007440:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80007444:	0af71963          	bne	a4,a5,800074f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80007448:	100017b7          	lui	a5,0x10001
    8000744c:	4705                	li	a4,1
    8000744e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007450:	470d                	li	a4,3
    80007452:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80007454:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80007456:	c7ffe737          	lui	a4,0xc7ffe
    8000745a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    8000745e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80007460:	2701                	sext.w	a4,a4
    80007462:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007464:	472d                	li	a4,11
    80007466:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007468:	473d                	li	a4,15
    8000746a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000746c:	6705                	lui	a4,0x1
    8000746e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80007470:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80007474:	5bdc                	lw	a5,52(a5)
    80007476:	2781                	sext.w	a5,a5
  if(max == 0)
    80007478:	c7d9                	beqz	a5,80007506 <virtio_disk_init+0x124>
  if(max < NUM)
    8000747a:	471d                	li	a4,7
    8000747c:	08f77d63          	bgeu	a4,a5,80007516 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80007480:	100014b7          	lui	s1,0x10001
    80007484:	47a1                	li	a5,8
    80007486:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80007488:	6609                	lui	a2,0x2
    8000748a:	4581                	li	a1,0
    8000748c:	0001e517          	auipc	a0,0x1e
    80007490:	b7450513          	addi	a0,a0,-1164 # 80025000 <disk>
    80007494:	ffffa097          	auipc	ra,0xffffa
    80007498:	84c080e7          	jalr	-1972(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000749c:	0001e717          	auipc	a4,0x1e
    800074a0:	b6470713          	addi	a4,a4,-1180 # 80025000 <disk>
    800074a4:	00c75793          	srli	a5,a4,0xc
    800074a8:	2781                	sext.w	a5,a5
    800074aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800074ac:	00020797          	auipc	a5,0x20
    800074b0:	b5478793          	addi	a5,a5,-1196 # 80027000 <disk+0x2000>
    800074b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800074b6:	0001e717          	auipc	a4,0x1e
    800074ba:	bca70713          	addi	a4,a4,-1078 # 80025080 <disk+0x80>
    800074be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800074c0:	0001f717          	auipc	a4,0x1f
    800074c4:	b4070713          	addi	a4,a4,-1216 # 80026000 <disk+0x1000>
    800074c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800074ca:	4705                	li	a4,1
    800074cc:	00e78c23          	sb	a4,24(a5)
    800074d0:	00e78ca3          	sb	a4,25(a5)
    800074d4:	00e78d23          	sb	a4,26(a5)
    800074d8:	00e78da3          	sb	a4,27(a5)
    800074dc:	00e78e23          	sb	a4,28(a5)
    800074e0:	00e78ea3          	sb	a4,29(a5)
    800074e4:	00e78f23          	sb	a4,30(a5)
    800074e8:	00e78fa3          	sb	a4,31(a5)
}
    800074ec:	60e2                	ld	ra,24(sp)
    800074ee:	6442                	ld	s0,16(sp)
    800074f0:	64a2                	ld	s1,8(sp)
    800074f2:	6105                	addi	sp,sp,32
    800074f4:	8082                	ret
    panic("could not find virtio disk");
    800074f6:	00002517          	auipc	a0,0x2
    800074fa:	6aa50513          	addi	a0,a0,1706 # 80009ba0 <syscalls+0x378>
    800074fe:	ffff9097          	auipc	ra,0xffff9
    80007502:	040080e7          	jalr	64(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80007506:	00002517          	auipc	a0,0x2
    8000750a:	6ba50513          	addi	a0,a0,1722 # 80009bc0 <syscalls+0x398>
    8000750e:	ffff9097          	auipc	ra,0xffff9
    80007512:	030080e7          	jalr	48(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80007516:	00002517          	auipc	a0,0x2
    8000751a:	6ca50513          	addi	a0,a0,1738 # 80009be0 <syscalls+0x3b8>
    8000751e:	ffff9097          	auipc	ra,0xffff9
    80007522:	020080e7          	jalr	32(ra) # 8000053e <panic>

0000000080007526 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80007526:	7159                	addi	sp,sp,-112
    80007528:	f486                	sd	ra,104(sp)
    8000752a:	f0a2                	sd	s0,96(sp)
    8000752c:	eca6                	sd	s1,88(sp)
    8000752e:	e8ca                	sd	s2,80(sp)
    80007530:	e4ce                	sd	s3,72(sp)
    80007532:	e0d2                	sd	s4,64(sp)
    80007534:	fc56                	sd	s5,56(sp)
    80007536:	f85a                	sd	s6,48(sp)
    80007538:	f45e                	sd	s7,40(sp)
    8000753a:	f062                	sd	s8,32(sp)
    8000753c:	ec66                	sd	s9,24(sp)
    8000753e:	e86a                	sd	s10,16(sp)
    80007540:	1880                	addi	s0,sp,112
    80007542:	892a                	mv	s2,a0
    80007544:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80007546:	00c52c83          	lw	s9,12(a0)
    8000754a:	001c9c9b          	slliw	s9,s9,0x1
    8000754e:	1c82                	slli	s9,s9,0x20
    80007550:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007554:	00020517          	auipc	a0,0x20
    80007558:	bd450513          	addi	a0,a0,-1068 # 80027128 <disk+0x2128>
    8000755c:	ffff9097          	auipc	ra,0xffff9
    80007560:	688080e7          	jalr	1672(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80007564:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007566:	4c21                	li	s8,8
      disk.free[i] = 0;
    80007568:	0001eb97          	auipc	s7,0x1e
    8000756c:	a98b8b93          	addi	s7,s7,-1384 # 80025000 <disk>
    80007570:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80007572:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80007574:	8a4e                	mv	s4,s3
    80007576:	a051                	j	800075fa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80007578:	00fb86b3          	add	a3,s7,a5
    8000757c:	96da                	add	a3,a3,s6
    8000757e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80007582:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80007584:	0207c563          	bltz	a5,800075ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80007588:	2485                	addiw	s1,s1,1
    8000758a:	0711                	addi	a4,a4,4
    8000758c:	25548063          	beq	s1,s5,800077cc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80007590:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80007592:	00020697          	auipc	a3,0x20
    80007596:	a8668693          	addi	a3,a3,-1402 # 80027018 <disk+0x2018>
    8000759a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000759c:	0006c583          	lbu	a1,0(a3)
    800075a0:	fde1                	bnez	a1,80007578 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800075a2:	2785                	addiw	a5,a5,1
    800075a4:	0685                	addi	a3,a3,1
    800075a6:	ff879be3          	bne	a5,s8,8000759c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800075aa:	57fd                	li	a5,-1
    800075ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800075ae:	02905a63          	blez	s1,800075e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800075b2:	f9042503          	lw	a0,-112(s0)
    800075b6:	00000097          	auipc	ra,0x0
    800075ba:	d90080e7          	jalr	-624(ra) # 80007346 <free_desc>
      for(int j = 0; j < i; j++)
    800075be:	4785                	li	a5,1
    800075c0:	0297d163          	bge	a5,s1,800075e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800075c4:	f9442503          	lw	a0,-108(s0)
    800075c8:	00000097          	auipc	ra,0x0
    800075cc:	d7e080e7          	jalr	-642(ra) # 80007346 <free_desc>
      for(int j = 0; j < i; j++)
    800075d0:	4789                	li	a5,2
    800075d2:	0097d863          	bge	a5,s1,800075e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800075d6:	f9842503          	lw	a0,-104(s0)
    800075da:	00000097          	auipc	ra,0x0
    800075de:	d6c080e7          	jalr	-660(ra) # 80007346 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800075e2:	00020597          	auipc	a1,0x20
    800075e6:	b4658593          	addi	a1,a1,-1210 # 80027128 <disk+0x2128>
    800075ea:	00020517          	auipc	a0,0x20
    800075ee:	a2e50513          	addi	a0,a0,-1490 # 80027018 <disk+0x2018>
    800075f2:	ffffb097          	auipc	ra,0xffffb
    800075f6:	68c080e7          	jalr	1676(ra) # 80002c7e <sleep>
  for(int i = 0; i < 3; i++){
    800075fa:	f9040713          	addi	a4,s0,-112
    800075fe:	84ce                	mv	s1,s3
    80007600:	bf41                	j	80007590 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80007602:	20058713          	addi	a4,a1,512
    80007606:	00471693          	slli	a3,a4,0x4
    8000760a:	0001e717          	auipc	a4,0x1e
    8000760e:	9f670713          	addi	a4,a4,-1546 # 80025000 <disk>
    80007612:	9736                	add	a4,a4,a3
    80007614:	4685                	li	a3,1
    80007616:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000761a:	20058713          	addi	a4,a1,512
    8000761e:	00471693          	slli	a3,a4,0x4
    80007622:	0001e717          	auipc	a4,0x1e
    80007626:	9de70713          	addi	a4,a4,-1570 # 80025000 <disk>
    8000762a:	9736                	add	a4,a4,a3
    8000762c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80007630:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80007634:	7679                	lui	a2,0xffffe
    80007636:	963e                	add	a2,a2,a5
    80007638:	00020697          	auipc	a3,0x20
    8000763c:	9c868693          	addi	a3,a3,-1592 # 80027000 <disk+0x2000>
    80007640:	6298                	ld	a4,0(a3)
    80007642:	9732                	add	a4,a4,a2
    80007644:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80007646:	6298                	ld	a4,0(a3)
    80007648:	9732                	add	a4,a4,a2
    8000764a:	4541                	li	a0,16
    8000764c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000764e:	6298                	ld	a4,0(a3)
    80007650:	9732                	add	a4,a4,a2
    80007652:	4505                	li	a0,1
    80007654:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80007658:	f9442703          	lw	a4,-108(s0)
    8000765c:	6288                	ld	a0,0(a3)
    8000765e:	962a                	add	a2,a2,a0
    80007660:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80007664:	0712                	slli	a4,a4,0x4
    80007666:	6290                	ld	a2,0(a3)
    80007668:	963a                	add	a2,a2,a4
    8000766a:	05890513          	addi	a0,s2,88
    8000766e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80007670:	6294                	ld	a3,0(a3)
    80007672:	96ba                	add	a3,a3,a4
    80007674:	40000613          	li	a2,1024
    80007678:	c690                	sw	a2,8(a3)
  if(write)
    8000767a:	140d0063          	beqz	s10,800077ba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000767e:	00020697          	auipc	a3,0x20
    80007682:	9826b683          	ld	a3,-1662(a3) # 80027000 <disk+0x2000>
    80007686:	96ba                	add	a3,a3,a4
    80007688:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000768c:	0001e817          	auipc	a6,0x1e
    80007690:	97480813          	addi	a6,a6,-1676 # 80025000 <disk>
    80007694:	00020517          	auipc	a0,0x20
    80007698:	96c50513          	addi	a0,a0,-1684 # 80027000 <disk+0x2000>
    8000769c:	6114                	ld	a3,0(a0)
    8000769e:	96ba                	add	a3,a3,a4
    800076a0:	00c6d603          	lhu	a2,12(a3)
    800076a4:	00166613          	ori	a2,a2,1
    800076a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800076ac:	f9842683          	lw	a3,-104(s0)
    800076b0:	6110                	ld	a2,0(a0)
    800076b2:	9732                	add	a4,a4,a2
    800076b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800076b8:	20058613          	addi	a2,a1,512
    800076bc:	0612                	slli	a2,a2,0x4
    800076be:	9642                	add	a2,a2,a6
    800076c0:	577d                	li	a4,-1
    800076c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800076c6:	00469713          	slli	a4,a3,0x4
    800076ca:	6114                	ld	a3,0(a0)
    800076cc:	96ba                	add	a3,a3,a4
    800076ce:	03078793          	addi	a5,a5,48
    800076d2:	97c2                	add	a5,a5,a6
    800076d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800076d6:	611c                	ld	a5,0(a0)
    800076d8:	97ba                	add	a5,a5,a4
    800076da:	4685                	li	a3,1
    800076dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800076de:	611c                	ld	a5,0(a0)
    800076e0:	97ba                	add	a5,a5,a4
    800076e2:	4809                	li	a6,2
    800076e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800076e8:	611c                	ld	a5,0(a0)
    800076ea:	973e                	add	a4,a4,a5
    800076ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800076f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800076f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800076f8:	6518                	ld	a4,8(a0)
    800076fa:	00275783          	lhu	a5,2(a4)
    800076fe:	8b9d                	andi	a5,a5,7
    80007700:	0786                	slli	a5,a5,0x1
    80007702:	97ba                	add	a5,a5,a4
    80007704:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80007708:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000770c:	6518                	ld	a4,8(a0)
    8000770e:	00275783          	lhu	a5,2(a4)
    80007712:	2785                	addiw	a5,a5,1
    80007714:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80007718:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000771c:	100017b7          	lui	a5,0x10001
    80007720:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80007724:	00492703          	lw	a4,4(s2)
    80007728:	4785                	li	a5,1
    8000772a:	02f71163          	bne	a4,a5,8000774c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000772e:	00020997          	auipc	s3,0x20
    80007732:	9fa98993          	addi	s3,s3,-1542 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    80007736:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80007738:	85ce                	mv	a1,s3
    8000773a:	854a                	mv	a0,s2
    8000773c:	ffffb097          	auipc	ra,0xffffb
    80007740:	542080e7          	jalr	1346(ra) # 80002c7e <sleep>
  while(b->disk == 1) {
    80007744:	00492783          	lw	a5,4(s2)
    80007748:	fe9788e3          	beq	a5,s1,80007738 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000774c:	f9042903          	lw	s2,-112(s0)
    80007750:	20090793          	addi	a5,s2,512
    80007754:	00479713          	slli	a4,a5,0x4
    80007758:	0001e797          	auipc	a5,0x1e
    8000775c:	8a878793          	addi	a5,a5,-1880 # 80025000 <disk>
    80007760:	97ba                	add	a5,a5,a4
    80007762:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80007766:	00020997          	auipc	s3,0x20
    8000776a:	89a98993          	addi	s3,s3,-1894 # 80027000 <disk+0x2000>
    8000776e:	00491713          	slli	a4,s2,0x4
    80007772:	0009b783          	ld	a5,0(s3)
    80007776:	97ba                	add	a5,a5,a4
    80007778:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000777c:	854a                	mv	a0,s2
    8000777e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80007782:	00000097          	auipc	ra,0x0
    80007786:	bc4080e7          	jalr	-1084(ra) # 80007346 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000778a:	8885                	andi	s1,s1,1
    8000778c:	f0ed                	bnez	s1,8000776e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000778e:	00020517          	auipc	a0,0x20
    80007792:	99a50513          	addi	a0,a0,-1638 # 80027128 <disk+0x2128>
    80007796:	ffff9097          	auipc	ra,0xffff9
    8000779a:	502080e7          	jalr	1282(ra) # 80000c98 <release>
}
    8000779e:	70a6                	ld	ra,104(sp)
    800077a0:	7406                	ld	s0,96(sp)
    800077a2:	64e6                	ld	s1,88(sp)
    800077a4:	6946                	ld	s2,80(sp)
    800077a6:	69a6                	ld	s3,72(sp)
    800077a8:	6a06                	ld	s4,64(sp)
    800077aa:	7ae2                	ld	s5,56(sp)
    800077ac:	7b42                	ld	s6,48(sp)
    800077ae:	7ba2                	ld	s7,40(sp)
    800077b0:	7c02                	ld	s8,32(sp)
    800077b2:	6ce2                	ld	s9,24(sp)
    800077b4:	6d42                	ld	s10,16(sp)
    800077b6:	6165                	addi	sp,sp,112
    800077b8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800077ba:	00020697          	auipc	a3,0x20
    800077be:	8466b683          	ld	a3,-1978(a3) # 80027000 <disk+0x2000>
    800077c2:	96ba                	add	a3,a3,a4
    800077c4:	4609                	li	a2,2
    800077c6:	00c69623          	sh	a2,12(a3)
    800077ca:	b5c9                	j	8000768c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800077cc:	f9042583          	lw	a1,-112(s0)
    800077d0:	20058793          	addi	a5,a1,512
    800077d4:	0792                	slli	a5,a5,0x4
    800077d6:	0001e517          	auipc	a0,0x1e
    800077da:	8d250513          	addi	a0,a0,-1838 # 800250a8 <disk+0xa8>
    800077de:	953e                	add	a0,a0,a5
  if(write)
    800077e0:	e20d11e3          	bnez	s10,80007602 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800077e4:	20058713          	addi	a4,a1,512
    800077e8:	00471693          	slli	a3,a4,0x4
    800077ec:	0001e717          	auipc	a4,0x1e
    800077f0:	81470713          	addi	a4,a4,-2028 # 80025000 <disk>
    800077f4:	9736                	add	a4,a4,a3
    800077f6:	0a072423          	sw	zero,168(a4)
    800077fa:	b505                	j	8000761a <virtio_disk_rw+0xf4>

00000000800077fc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800077fc:	1101                	addi	sp,sp,-32
    800077fe:	ec06                	sd	ra,24(sp)
    80007800:	e822                	sd	s0,16(sp)
    80007802:	e426                	sd	s1,8(sp)
    80007804:	e04a                	sd	s2,0(sp)
    80007806:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80007808:	00020517          	auipc	a0,0x20
    8000780c:	92050513          	addi	a0,a0,-1760 # 80027128 <disk+0x2128>
    80007810:	ffff9097          	auipc	ra,0xffff9
    80007814:	3d4080e7          	jalr	980(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80007818:	10001737          	lui	a4,0x10001
    8000781c:	533c                	lw	a5,96(a4)
    8000781e:	8b8d                	andi	a5,a5,3
    80007820:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007822:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007826:	0001f797          	auipc	a5,0x1f
    8000782a:	7da78793          	addi	a5,a5,2010 # 80027000 <disk+0x2000>
    8000782e:	6b94                	ld	a3,16(a5)
    80007830:	0207d703          	lhu	a4,32(a5)
    80007834:	0026d783          	lhu	a5,2(a3)
    80007838:	06f70163          	beq	a4,a5,8000789a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000783c:	0001d917          	auipc	s2,0x1d
    80007840:	7c490913          	addi	s2,s2,1988 # 80025000 <disk>
    80007844:	0001f497          	auipc	s1,0x1f
    80007848:	7bc48493          	addi	s1,s1,1980 # 80027000 <disk+0x2000>
    __sync_synchronize();
    8000784c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007850:	6898                	ld	a4,16(s1)
    80007852:	0204d783          	lhu	a5,32(s1)
    80007856:	8b9d                	andi	a5,a5,7
    80007858:	078e                	slli	a5,a5,0x3
    8000785a:	97ba                	add	a5,a5,a4
    8000785c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000785e:	20078713          	addi	a4,a5,512
    80007862:	0712                	slli	a4,a4,0x4
    80007864:	974a                	add	a4,a4,s2
    80007866:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000786a:	e731                	bnez	a4,800078b6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000786c:	20078793          	addi	a5,a5,512
    80007870:	0792                	slli	a5,a5,0x4
    80007872:	97ca                	add	a5,a5,s2
    80007874:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007876:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000787a:	ffffc097          	auipc	ra,0xffffc
    8000787e:	81a080e7          	jalr	-2022(ra) # 80003094 <wakeup>

    disk.used_idx += 1;
    80007882:	0204d783          	lhu	a5,32(s1)
    80007886:	2785                	addiw	a5,a5,1
    80007888:	17c2                	slli	a5,a5,0x30
    8000788a:	93c1                	srli	a5,a5,0x30
    8000788c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007890:	6898                	ld	a4,16(s1)
    80007892:	00275703          	lhu	a4,2(a4)
    80007896:	faf71be3          	bne	a4,a5,8000784c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000789a:	00020517          	auipc	a0,0x20
    8000789e:	88e50513          	addi	a0,a0,-1906 # 80027128 <disk+0x2128>
    800078a2:	ffff9097          	auipc	ra,0xffff9
    800078a6:	3f6080e7          	jalr	1014(ra) # 80000c98 <release>
}
    800078aa:	60e2                	ld	ra,24(sp)
    800078ac:	6442                	ld	s0,16(sp)
    800078ae:	64a2                	ld	s1,8(sp)
    800078b0:	6902                	ld	s2,0(sp)
    800078b2:	6105                	addi	sp,sp,32
    800078b4:	8082                	ret
      panic("virtio_disk_intr status");
    800078b6:	00002517          	auipc	a0,0x2
    800078ba:	34a50513          	addi	a0,a0,842 # 80009c00 <syscalls+0x3d8>
    800078be:	ffff9097          	auipc	ra,0xffff9
    800078c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>

00000000800078c6 <cas>:
    800078c6:	100522af          	lr.w	t0,(a0)
    800078ca:	00b29563          	bne	t0,a1,800078d4 <fail>
    800078ce:	18c5252f          	sc.w	a0,a2,(a0)
    800078d2:	8082                	ret

00000000800078d4 <fail>:
    800078d4:	4505                	li	a0,1
    800078d6:	8082                	ret
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
