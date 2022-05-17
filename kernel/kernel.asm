
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9a013103          	ld	sp,-1632(sp) # 800089a0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	1ec78793          	addi	a5,a5,492 # 80006250 <timervec>
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
    80000130:	98a080e7          	jalr	-1654(ra) # 80002ab6 <either_copyin>
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
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
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
    800001c8:	c4a080e7          	jalr	-950(ra) # 80001e0e <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	44e080e7          	jalr	1102(ra) # 80002622 <sleep>
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
    80000214:	850080e7          	jalr	-1968(ra) # 80002a60 <either_copyout>
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
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
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
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
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
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
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
    800002f6:	81a080e7          	jalr	-2022(ra) # 80002b0c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
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
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
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
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
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
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
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
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
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
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	37a080e7          	jalr	890(ra) # 800027c0 <wakeup>
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
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	9e078793          	addi	a5,a5,-1568 # 80021e58 <devsw>
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
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
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
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
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
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
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
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
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
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
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
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
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
    800008a4:	f20080e7          	jalr	-224(ra) # 800027c0 <wakeup>
    
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
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
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
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	cf6080e7          	jalr	-778(ra) # 80002622 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
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
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
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
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
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
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
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
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
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
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
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
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
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
    80000b82:	26e080e7          	jalr	622(ra) # 80001dec <mycpu>
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
    80000bb4:	23c080e7          	jalr	572(ra) # 80001dec <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	230080e7          	jalr	560(ra) # 80001dec <mycpu>
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
    80000bd8:	218080e7          	jalr	536(ra) # 80001dec <mycpu>
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
    80000c18:	1d8080e7          	jalr	472(ra) # 80001dec <mycpu>
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
    80000c44:	1ac080e7          	jalr	428(ra) # 80001dec <mycpu>
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
    80000e9a:	f46080e7          	jalr	-186(ra) # 80001ddc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	f2a080e7          	jalr	-214(ra) # 80001ddc <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	e64080e7          	jalr	-412(ra) # 80002d38 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	3b4080e7          	jalr	948(ra) # 80006290 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	532080e7          	jalr	1330(ra) # 80002416 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	d94080e7          	jalr	-620(ra) # 80001cd8 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	dc4080e7          	jalr	-572(ra) # 80002d10 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	de4080e7          	jalr	-540(ra) # 80002d38 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	31e080e7          	jalr	798(ra) # 8000627a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	32c080e7          	jalr	812(ra) # 80006290 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	50e080e7          	jalr	1294(ra) # 8000347a <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	b9e080e7          	jalr	-1122(ra) # 80003b12 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	b48080e7          	jalr	-1208(ra) # 80004ac4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	42e080e7          	jalr	1070(ra) # 800063b2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	20e080e7          	jalr	526(ra) # 8000219a <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00001097          	auipc	ra,0x1
    80001244:	a02080e7          	jalr	-1534(ra) # 80001c42 <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <increment_cpu_process_count>:
struct linked_list unused_list = {-1};   // contains all UNUSED process entries.
struct linked_list sleeping_list = {-1}; // contains all SLEEPING processes.
struct linked_list zombie_list = {-1};   // contains all ZOMBIE processes.

void 
increment_cpu_process_count(struct cpu *c){
    8000183e:	1101                	addi	sp,sp,-32
    80001840:	ec06                	sd	ra,24(sp)
    80001842:	e822                	sd	s0,16(sp)
    80001844:	e426                	sd	s1,8(sp)
    80001846:	e04a                	sd	s2,0(sp)
    80001848:	1000                	addi	s0,sp,32
    8000184a:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->proc_cnt;
  }while(cas(&(c->proc_cnt), curr_count, curr_count+1));
    8000184c:	08050913          	addi	s2,a0,128
    curr_count = c->proc_cnt;
    80001850:	0804a583          	lw	a1,128(s1)
  }while(cas(&(c->proc_cnt), curr_count, curr_count+1));
    80001854:	0015861b          	addiw	a2,a1,1
    80001858:	854a                	mv	a0,s2
    8000185a:	00005097          	auipc	ra,0x5
    8000185e:	03c080e7          	jalr	60(ra) # 80006896 <cas>
    80001862:	2501                	sext.w	a0,a0
    80001864:	f575                	bnez	a0,80001850 <increment_cpu_process_count+0x12>
}
    80001866:	60e2                	ld	ra,24(sp)
    80001868:	6442                	ld	s0,16(sp)
    8000186a:	64a2                	ld	s1,8(sp)
    8000186c:	6902                	ld	s2,0(sp)
    8000186e:	6105                	addi	sp,sp,32
    80001870:	8082                	ret

0000000080001872 <print_list>:

void
print_list(struct linked_list lst){
    80001872:	7139                	addi	sp,sp,-64
    80001874:	fc06                	sd	ra,56(sp)
    80001876:	f822                	sd	s0,48(sp)
    80001878:	f426                	sd	s1,40(sp)
    8000187a:	f04a                	sd	s2,32(sp)
    8000187c:	ec4e                	sd	s3,24(sp)
    8000187e:	e852                	sd	s4,16(sp)
    80001880:	e456                	sd	s5,8(sp)
    80001882:	0080                	addi	s0,sp,64
  int curr = lst.head;
    80001884:	4104                	lw	s1,0(a0)
  printf("\n[ ");
    80001886:	00007517          	auipc	a0,0x7
    8000188a:	95250513          	addi	a0,a0,-1710 # 800081d8 <digits+0x198>
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	cfa080e7          	jalr	-774(ra) # 80000588 <printf>
  while(curr != -1){
    80001896:	57fd                	li	a5,-1
    80001898:	02f48a63          	beq	s1,a5,800018cc <print_list+0x5a>
    printf(" %d,", curr);
    8000189c:	00007a97          	auipc	s5,0x7
    800018a0:	944a8a93          	addi	s5,s5,-1724 # 800081e0 <digits+0x1a0>
    curr = proc[curr].next_proc;
    800018a4:	00010a17          	auipc	s4,0x10
    800018a8:	f6ca0a13          	addi	s4,s4,-148 # 80011810 <proc>
    800018ac:	19000993          	li	s3,400
  while(curr != -1){
    800018b0:	597d                	li	s2,-1
    printf(" %d,", curr);
    800018b2:	85a6                	mv	a1,s1
    800018b4:	8556                	mv	a0,s5
    800018b6:	fffff097          	auipc	ra,0xfffff
    800018ba:	cd2080e7          	jalr	-814(ra) # 80000588 <printf>
    curr = proc[curr].next_proc;
    800018be:	033484b3          	mul	s1,s1,s3
    800018c2:	94d2                	add	s1,s1,s4
    800018c4:	16c4a483          	lw	s1,364(s1)
  while(curr != -1){
    800018c8:	ff2495e3          	bne	s1,s2,800018b2 <print_list+0x40>
  }
  printf(" ]\n");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	91c50513          	addi	a0,a0,-1764 # 800081e8 <digits+0x1a8>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	cb4080e7          	jalr	-844(ra) # 80000588 <printf>
}
    800018dc:	70e2                	ld	ra,56(sp)
    800018de:	7442                	ld	s0,48(sp)
    800018e0:	74a2                	ld	s1,40(sp)
    800018e2:	7902                	ld	s2,32(sp)
    800018e4:	69e2                	ld	s3,24(sp)
    800018e6:	6a42                	ld	s4,16(sp)
    800018e8:	6aa2                	ld	s5,8(sp)
    800018ea:	6121                	addi	sp,sp,64
    800018ec:	8082                	ret

00000000800018ee <initialize_list>:


void initialize_list(struct linked_list *lst){
    800018ee:	1101                	addi	sp,sp,-32
    800018f0:	ec06                	sd	ra,24(sp)
    800018f2:	e822                	sd	s0,16(sp)
    800018f4:	e426                	sd	s1,8(sp)
    800018f6:	e04a                	sd	s2,0(sp)
    800018f8:	1000                	addi	s0,sp,32
    800018fa:	84aa                	mv	s1,a0
  acquire(&lst->head_lock);
    800018fc:	00850913          	addi	s2,a0,8
    80001900:	854a                	mv	a0,s2
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	2e2080e7          	jalr	738(ra) # 80000be4 <acquire>
  lst->head = -1;
    8000190a:	57fd                	li	a5,-1
    8000190c:	c09c                	sw	a5,0(s1)
  acquire(&lst->head_lock);
    8000190e:	854a                	mv	a0,s2
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	2d4080e7          	jalr	724(ra) # 80000be4 <acquire>
}
    80001918:	60e2                	ld	ra,24(sp)
    8000191a:	6442                	ld	s0,16(sp)
    8000191c:	64a2                	ld	s1,8(sp)
    8000191e:	6902                	ld	s2,0(sp)
    80001920:	6105                	addi	sp,sp,32
    80001922:	8082                	ret

0000000080001924 <initialize_lists>:

void initialize_lists(void){
    80001924:	7179                	addi	sp,sp,-48
    80001926:	f406                	sd	ra,40(sp)
    80001928:	f022                	sd	s0,32(sp)
    8000192a:	ec26                	sd	s1,24(sp)
    8000192c:	e84a                	sd	s2,16(sp)
    8000192e:	e44e                	sd	s3,8(sp)
    80001930:	e052                	sd	s4,0(sp)
    80001932:	1800                	addi	s0,sp,48
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001934:	00010497          	auipc	s1,0x10
    80001938:	96c48493          	addi	s1,s1,-1684 # 800112a0 <cpus>
    c->runnable_list = (struct linked_list){-1};
    8000193c:	5a7d                	li	s4,-1
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    8000193e:	00007997          	auipc	s3,0x7
    80001942:	8b298993          	addi	s3,s3,-1870 # 800081f0 <digits+0x1b0>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001946:	00010917          	auipc	s2,0x10
    8000194a:	e9a90913          	addi	s2,s2,-358 # 800117e0 <pid_lock>
    c->runnable_list = (struct linked_list){-1};
    8000194e:	0804b423          	sd	zero,136(s1)
    80001952:	0804b823          	sd	zero,144(s1)
    80001956:	0804bc23          	sd	zero,152(s1)
    8000195a:	0a04b023          	sd	zero,160(s1)
    8000195e:	0944a423          	sw	s4,136(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    80001962:	85ce                	mv	a1,s3
    80001964:	09048513          	addi	a0,s1,144
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	1ec080e7          	jalr	492(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001970:	0a848493          	addi	s1,s1,168
    80001974:	fd249de3          	bne	s1,s2,8000194e <initialize_lists+0x2a>
  }
  initlock(&unused_list.head_lock, "unused_list - head lock");
    80001978:	00007597          	auipc	a1,0x7
    8000197c:	89858593          	addi	a1,a1,-1896 # 80008210 <digits+0x1d0>
    80001980:	00007517          	auipc	a0,0x7
    80001984:	f8850513          	addi	a0,a0,-120 # 80008908 <unused_list+0x8>
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1cc080e7          	jalr	460(ra) # 80000b54 <initlock>
  initlock(&sleeping_list.head_lock, "sleeping_list - head lock");
    80001990:	00007597          	auipc	a1,0x7
    80001994:	89858593          	addi	a1,a1,-1896 # 80008228 <digits+0x1e8>
    80001998:	00007517          	auipc	a0,0x7
    8000199c:	f9050513          	addi	a0,a0,-112 # 80008928 <sleeping_list+0x8>
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1b4080e7          	jalr	436(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list - head lock");
    800019a8:	00007597          	auipc	a1,0x7
    800019ac:	8a058593          	addi	a1,a1,-1888 # 80008248 <digits+0x208>
    800019b0:	00007517          	auipc	a0,0x7
    800019b4:	f9850513          	addi	a0,a0,-104 # 80008948 <zombie_list+0x8>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	19c080e7          	jalr	412(ra) # 80000b54 <initlock>
}
    800019c0:	70a2                	ld	ra,40(sp)
    800019c2:	7402                	ld	s0,32(sp)
    800019c4:	64e2                	ld	s1,24(sp)
    800019c6:	6942                	ld	s2,16(sp)
    800019c8:	69a2                	ld	s3,8(sp)
    800019ca:	6a02                	ld	s4,0(sp)
    800019cc:	6145                	addi	sp,sp,48
    800019ce:	8082                	ret

00000000800019d0 <initialize_proc>:

void
initialize_proc(struct proc *p){
    800019d0:	1141                	addi	sp,sp,-16
    800019d2:	e422                	sd	s0,8(sp)
    800019d4:	0800                	addi	s0,sp,16
  p->next_proc = -1;
    800019d6:	57fd                	li	a5,-1
    800019d8:	16f52623          	sw	a5,364(a0)
  p->prev_proc = -1;
    800019dc:	16f52823          	sw	a5,368(a0)
}
    800019e0:	6422                	ld	s0,8(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret

00000000800019e6 <isEmpty>:

int
isEmpty(struct linked_list *lst){
    800019e6:	1141                	addi	sp,sp,-16
    800019e8:	e422                	sd	s0,8(sp)
    800019ea:	0800                	addi	s0,sp,16
  return lst->head == -1;
    800019ec:	4108                	lw	a0,0(a0)
    800019ee:	0505                	addi	a0,a0,1
}
    800019f0:	00153513          	seqz	a0,a0
    800019f4:	6422                	ld	s0,8(sp)
    800019f6:	0141                	addi	sp,sp,16
    800019f8:	8082                	ret

00000000800019fa <get_head>:

int 
get_head(struct linked_list *lst){
    800019fa:	1101                	addi	sp,sp,-32
    800019fc:	ec06                	sd	ra,24(sp)
    800019fe:	e822                	sd	s0,16(sp)
    80001a00:	e426                	sd	s1,8(sp)
    80001a02:	e04a                	sd	s2,0(sp)
    80001a04:	1000                	addi	s0,sp,32
    80001a06:	84aa                	mv	s1,a0
  acquire(&lst->head_lock); 
    80001a08:	00850913          	addi	s2,a0,8
    80001a0c:	854a                	mv	a0,s2
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	1d6080e7          	jalr	470(ra) # 80000be4 <acquire>
  int output = lst->head;
    80001a16:	4084                	lw	s1,0(s1)
  release(&lst->head_lock);
    80001a18:	854a                	mv	a0,s2
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	27e080e7          	jalr	638(ra) # 80000c98 <release>
  return output;
}
    80001a22:	8526                	mv	a0,s1
    80001a24:	60e2                	ld	ra,24(sp)
    80001a26:	6442                	ld	s0,16(sp)
    80001a28:	64a2                	ld	s1,8(sp)
    80001a2a:	6902                	ld	s2,0(sp)
    80001a2c:	6105                	addi	sp,sp,32
    80001a2e:	8082                	ret

0000000080001a30 <set_prev_proc>:

void set_prev_proc(struct proc *p, int value){
    80001a30:	1141                	addi	sp,sp,-16
    80001a32:	e422                	sd	s0,8(sp)
    80001a34:	0800                	addi	s0,sp,16
  p->prev_proc = value; 
    80001a36:	16b52823          	sw	a1,368(a0)
}
    80001a3a:	6422                	ld	s0,8(sp)
    80001a3c:	0141                	addi	sp,sp,16
    80001a3e:	8082                	ret

0000000080001a40 <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    80001a40:	1141                	addi	sp,sp,-16
    80001a42:	e422                	sd	s0,8(sp)
    80001a44:	0800                	addi	s0,sp,16
  p->next_proc = value; 
    80001a46:	16b52623          	sw	a1,364(a0)
}
    80001a4a:	6422                	ld	s0,8(sp)
    80001a4c:	0141                	addi	sp,sp,16
    80001a4e:	8082                	ret

0000000080001a50 <append>:

void 
append(struct linked_list *lst, struct proc *p){
    80001a50:	7139                	addi	sp,sp,-64
    80001a52:	fc06                	sd	ra,56(sp)
    80001a54:	f822                	sd	s0,48(sp)
    80001a56:	f426                	sd	s1,40(sp)
    80001a58:	f04a                	sd	s2,32(sp)
    80001a5a:	ec4e                	sd	s3,24(sp)
    80001a5c:	e852                	sd	s4,16(sp)
    80001a5e:	e456                	sd	s5,8(sp)
    80001a60:	0080                	addi	s0,sp,64
    80001a62:	84aa                	mv	s1,a0
    80001a64:	8a2e                	mv	s4,a1
  acquire(&lst->head_lock);
    80001a66:	00850913          	addi	s2,a0,8
    80001a6a:	854a                	mv	a0,s2
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	178080e7          	jalr	376(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001a74:	4088                	lw	a0,0(s1)
  if(isEmpty(lst)){
    80001a76:	57fd                	li	a5,-1
    80001a78:	00f51b63          	bne	a0,a5,80001a8e <append+0x3e>
    lst->head = p->proc_ind;
    80001a7c:	174a2783          	lw	a5,372(s4)
    80001a80:	c09c                	sw	a5,0(s1)
    release(&lst->head_lock);
    80001a82:	854a                	mv	a0,s2
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
    80001a8c:	a849                	j	80001b1e <append+0xce>
  }
  else{ 
    struct proc *curr = &proc[lst->head];
    80001a8e:	19000793          	li	a5,400
    80001a92:	02f50533          	mul	a0,a0,a5
    80001a96:	00010797          	auipc	a5,0x10
    80001a9a:	d7a78793          	addi	a5,a5,-646 # 80011810 <proc>
    80001a9e:	00f504b3          	add	s1,a0,a5
    acquire(&curr->list_lock);
    80001aa2:	17850513          	addi	a0,a0,376
    80001aa6:	953e                	add	a0,a0,a5
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	13c080e7          	jalr	316(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001ab0:	854a                	mv	a0,s2
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	1e6080e7          	jalr	486(ra) # 80000c98 <release>
    while(curr->next_proc != -1){ // search tail
    80001aba:	16c4a503          	lw	a0,364(s1)
    80001abe:	57fd                	li	a5,-1
    80001ac0:	04f50163          	beq	a0,a5,80001b02 <append+0xb2>
      acquire(&proc[curr->next_proc].list_lock);
    80001ac4:	19000993          	li	s3,400
    80001ac8:	00010917          	auipc	s2,0x10
    80001acc:	d4890913          	addi	s2,s2,-696 # 80011810 <proc>
    while(curr->next_proc != -1){ // search tail
    80001ad0:	5afd                	li	s5,-1
      acquire(&proc[curr->next_proc].list_lock);
    80001ad2:	03350533          	mul	a0,a0,s3
    80001ad6:	17850513          	addi	a0,a0,376
    80001ada:	954a                	add	a0,a0,s2
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	108080e7          	jalr	264(ra) # 80000be4 <acquire>
      release(&curr->list_lock);
    80001ae4:	17848513          	addi	a0,s1,376
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	1b0080e7          	jalr	432(ra) # 80000c98 <release>
      curr = &proc[curr->next_proc];
    80001af0:	16c4a483          	lw	s1,364(s1)
    80001af4:	033484b3          	mul	s1,s1,s3
    80001af8:	94ca                	add	s1,s1,s2
    while(curr->next_proc != -1){ // search tail
    80001afa:	16c4a503          	lw	a0,364(s1)
    80001afe:	fd551ae3          	bne	a0,s5,80001ad2 <append+0x82>
    }
    set_next_proc(curr, p->proc_ind);  // update next proc of the curr tail
    80001b02:	174a2783          	lw	a5,372(s4)
  p->next_proc = value; 
    80001b06:	16f4a623          	sw	a5,364(s1)
    set_prev_proc(p, curr->proc_ind); // update the prev proc of the new proc
    80001b0a:	1744a783          	lw	a5,372(s1)
  p->prev_proc = value; 
    80001b0e:	16fa2823          	sw	a5,368(s4)
    release(&curr->list_lock);
    80001b12:	17848513          	addi	a0,s1,376
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	182080e7          	jalr	386(ra) # 80000c98 <release>
  }
}
    80001b1e:	70e2                	ld	ra,56(sp)
    80001b20:	7442                	ld	s0,48(sp)
    80001b22:	74a2                	ld	s1,40(sp)
    80001b24:	7902                	ld	s2,32(sp)
    80001b26:	69e2                	ld	s3,24(sp)
    80001b28:	6a42                	ld	s4,16(sp)
    80001b2a:	6aa2                	ld	s5,8(sp)
    80001b2c:	6121                	addi	sp,sp,64
    80001b2e:	8082                	ret

0000000080001b30 <remove>:

void 
remove(struct linked_list *lst, struct proc *p){
    80001b30:	7179                	addi	sp,sp,-48
    80001b32:	f406                	sd	ra,40(sp)
    80001b34:	f022                	sd	s0,32(sp)
    80001b36:	ec26                	sd	s1,24(sp)
    80001b38:	e84a                	sd	s2,16(sp)
    80001b3a:	e44e                	sd	s3,8(sp)
    80001b3c:	e052                	sd	s4,0(sp)
    80001b3e:	1800                	addi	s0,sp,48
    80001b40:	892a                	mv	s2,a0
    80001b42:	84ae                	mv	s1,a1
  acquire(&lst->head_lock);
    80001b44:	00850993          	addi	s3,a0,8
    80001b48:	854e                	mv	a0,s3
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	09a080e7          	jalr	154(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001b52:	00092783          	lw	a5,0(s2)
  if(isEmpty(lst)){
    80001b56:	577d                	li	a4,-1
    80001b58:	02e78f63          	beq	a5,a4,80001b96 <remove+0x66>
    release(&lst->head_lock);
    panic("Fails in removing the process from the list: the list is empty\n");
  }

  if(lst->head == p->proc_ind){ // the required proc is the head
    80001b5c:	1744a703          	lw	a4,372(s1)
    80001b60:	06f71563          	bne	a4,a5,80001bca <remove+0x9a>
    lst->head = p->next_proc;
    80001b64:	16c4a783          	lw	a5,364(s1)
    80001b68:	00f92023          	sw	a5,0(s2)
    if(p->next_proc != -1) {
    80001b6c:	577d                	li	a4,-1
    80001b6e:	04e79163          	bne	a5,a4,80001bb0 <remove+0x80>
      set_prev_proc(&proc[p->next_proc], -1);
    }
    release(&lst->head_lock);
    80001b72:	854e                	mv	a0,s3
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	124080e7          	jalr	292(ra) # 80000c98 <release>
  p->next_proc = -1;
    80001b7c:	57fd                	li	a5,-1
    80001b7e:	16f4a623          	sw	a5,364(s1)
  p->prev_proc = -1;
    80001b82:	16f4a823          	sw	a5,368(s1)
    set_prev_proc(&proc[p->next_proc], p->prev_proc);
    release(&proc[p->prev_proc].list_lock);
    release(&p->list_lock);
  }
  initialize_proc(p);
}
    80001b86:	70a2                	ld	ra,40(sp)
    80001b88:	7402                	ld	s0,32(sp)
    80001b8a:	64e2                	ld	s1,24(sp)
    80001b8c:	6942                	ld	s2,16(sp)
    80001b8e:	69a2                	ld	s3,8(sp)
    80001b90:	6a02                	ld	s4,0(sp)
    80001b92:	6145                	addi	sp,sp,48
    80001b94:	8082                	ret
    release(&lst->head_lock);
    80001b96:	854e                	mv	a0,s3
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	100080e7          	jalr	256(ra) # 80000c98 <release>
    panic("Fails in removing the process from the list: the list is empty\n");
    80001ba0:	00006517          	auipc	a0,0x6
    80001ba4:	6c050513          	addi	a0,a0,1728 # 80008260 <digits+0x220>
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	996080e7          	jalr	-1642(ra) # 8000053e <panic>
  p->prev_proc = value; 
    80001bb0:	19000713          	li	a4,400
    80001bb4:	02e787b3          	mul	a5,a5,a4
    80001bb8:	00010717          	auipc	a4,0x10
    80001bbc:	c5870713          	addi	a4,a4,-936 # 80011810 <proc>
    80001bc0:	97ba                	add	a5,a5,a4
    80001bc2:	577d                	li	a4,-1
    80001bc4:	16e7a823          	sw	a4,368(a5)
}
    80001bc8:	b76d                	j	80001b72 <remove+0x42>
    release(&lst->head_lock);
    80001bca:	854e                	mv	a0,s3
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0cc080e7          	jalr	204(ra) # 80000c98 <release>
    acquire(&p->list_lock);
    80001bd4:	17848993          	addi	s3,s1,376
    80001bd8:	854e                	mv	a0,s3
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	00a080e7          	jalr	10(ra) # 80000be4 <acquire>
    acquire(&proc[p->prev_proc].list_lock);
    80001be2:	1704a503          	lw	a0,368(s1)
    80001be6:	19000a13          	li	s4,400
    80001bea:	03450533          	mul	a0,a0,s4
    80001bee:	17850513          	addi	a0,a0,376
    80001bf2:	00010917          	auipc	s2,0x10
    80001bf6:	c1e90913          	addi	s2,s2,-994 # 80011810 <proc>
    80001bfa:	954a                	add	a0,a0,s2
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	fe8080e7          	jalr	-24(ra) # 80000be4 <acquire>
    set_next_proc(&proc[p->prev_proc], p->next_proc);
    80001c04:	1704a703          	lw	a4,368(s1)
    80001c08:	16c4a783          	lw	a5,364(s1)
  p->next_proc = value; 
    80001c0c:	03470733          	mul	a4,a4,s4
    80001c10:	974a                	add	a4,a4,s2
    80001c12:	16f72623          	sw	a5,364(a4)
    set_prev_proc(&proc[p->next_proc], p->prev_proc);
    80001c16:	1704a503          	lw	a0,368(s1)
  p->prev_proc = value; 
    80001c1a:	034787b3          	mul	a5,a5,s4
    80001c1e:	97ca                	add	a5,a5,s2
    80001c20:	16a7a823          	sw	a0,368(a5)
    release(&proc[p->prev_proc].list_lock);
    80001c24:	03450533          	mul	a0,a0,s4
    80001c28:	17850513          	addi	a0,a0,376
    80001c2c:	954a                	add	a0,a0,s2
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	06a080e7          	jalr	106(ra) # 80000c98 <release>
    release(&p->list_lock);
    80001c36:	854e                	mv	a0,s3
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	060080e7          	jalr	96(ra) # 80000c98 <release>
    80001c40:	bf35                	j	80001b7c <remove+0x4c>

0000000080001c42 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001c42:	7139                	addi	sp,sp,-64
    80001c44:	fc06                	sd	ra,56(sp)
    80001c46:	f822                	sd	s0,48(sp)
    80001c48:	f426                	sd	s1,40(sp)
    80001c4a:	f04a                	sd	s2,32(sp)
    80001c4c:	ec4e                	sd	s3,24(sp)
    80001c4e:	e852                	sd	s4,16(sp)
    80001c50:	e456                	sd	s5,8(sp)
    80001c52:	e05a                	sd	s6,0(sp)
    80001c54:	0080                	addi	s0,sp,64
    80001c56:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c58:	00010497          	auipc	s1,0x10
    80001c5c:	bb848493          	addi	s1,s1,-1096 # 80011810 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001c60:	8b26                	mv	s6,s1
    80001c62:	00006a97          	auipc	s5,0x6
    80001c66:	39ea8a93          	addi	s5,s5,926 # 80008000 <etext>
    80001c6a:	04000937          	lui	s2,0x4000
    80001c6e:	197d                	addi	s2,s2,-1
    80001c70:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c72:	00016a17          	auipc	s4,0x16
    80001c76:	f9ea0a13          	addi	s4,s4,-98 # 80017c10 <tickslock>
    char *pa = kalloc();
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	e7a080e7          	jalr	-390(ra) # 80000af4 <kalloc>
    80001c82:	862a                	mv	a2,a0
    if(pa == 0)
    80001c84:	c131                	beqz	a0,80001cc8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c86:	416485b3          	sub	a1,s1,s6
    80001c8a:	8591                	srai	a1,a1,0x4
    80001c8c:	000ab783          	ld	a5,0(s5)
    80001c90:	02f585b3          	mul	a1,a1,a5
    80001c94:	2585                	addiw	a1,a1,1
    80001c96:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c9a:	4719                	li	a4,6
    80001c9c:	6685                	lui	a3,0x1
    80001c9e:	40b905b3          	sub	a1,s2,a1
    80001ca2:	854e                	mv	a0,s3
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	4ac080e7          	jalr	1196(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cac:	19048493          	addi	s1,s1,400
    80001cb0:	fd4495e3          	bne	s1,s4,80001c7a <proc_mapstacks+0x38>
  }
}
    80001cb4:	70e2                	ld	ra,56(sp)
    80001cb6:	7442                	ld	s0,48(sp)
    80001cb8:	74a2                	ld	s1,40(sp)
    80001cba:	7902                	ld	s2,32(sp)
    80001cbc:	69e2                	ld	s3,24(sp)
    80001cbe:	6a42                	ld	s4,16(sp)
    80001cc0:	6aa2                	ld	s5,8(sp)
    80001cc2:	6b02                	ld	s6,0(sp)
    80001cc4:	6121                	addi	sp,sp,64
    80001cc6:	8082                	ret
      panic("kalloc");
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	5d850513          	addi	a0,a0,1496 # 800082a0 <digits+0x260>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	86e080e7          	jalr	-1938(ra) # 8000053e <panic>

0000000080001cd8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001cd8:	711d                	addi	sp,sp,-96
    80001cda:	ec86                	sd	ra,88(sp)
    80001cdc:	e8a2                	sd	s0,80(sp)
    80001cde:	e4a6                	sd	s1,72(sp)
    80001ce0:	e0ca                	sd	s2,64(sp)
    80001ce2:	fc4e                	sd	s3,56(sp)
    80001ce4:	f852                	sd	s4,48(sp)
    80001ce6:	f456                	sd	s5,40(sp)
    80001ce8:	f05a                	sd	s6,32(sp)
    80001cea:	ec5e                	sd	s7,24(sp)
    80001cec:	e862                	sd	s8,16(sp)
    80001cee:	e466                	sd	s9,8(sp)
    80001cf0:	e06a                	sd	s10,0(sp)
    80001cf2:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	c30080e7          	jalr	-976(ra) # 80001924 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001cfc:	00006597          	auipc	a1,0x6
    80001d00:	5ac58593          	addi	a1,a1,1452 # 800082a8 <digits+0x268>
    80001d04:	00010517          	auipc	a0,0x10
    80001d08:	adc50513          	addi	a0,a0,-1316 # 800117e0 <pid_lock>
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	e48080e7          	jalr	-440(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d14:	00006597          	auipc	a1,0x6
    80001d18:	59c58593          	addi	a1,a1,1436 # 800082b0 <digits+0x270>
    80001d1c:	00010517          	auipc	a0,0x10
    80001d20:	adc50513          	addi	a0,a0,-1316 # 800117f8 <wait_lock>
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	e30080e7          	jalr	-464(ra) # 80000b54 <initlock>

  int i = 0;
    80001d2c:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d2e:	00010497          	auipc	s1,0x10
    80001d32:	ae248493          	addi	s1,s1,-1310 # 80011810 <proc>
      initlock(&p->lock, "proc");
    80001d36:	00006d17          	auipc	s10,0x6
    80001d3a:	58ad0d13          	addi	s10,s10,1418 # 800082c0 <digits+0x280>
      initlock(&p->list_lock, "list_lock");
    80001d3e:	00006c97          	auipc	s9,0x6
    80001d42:	58ac8c93          	addi	s9,s9,1418 # 800082c8 <digits+0x288>
      p->kstack = KSTACK((int) (p - proc));
    80001d46:	8c26                	mv	s8,s1
    80001d48:	00006b97          	auipc	s7,0x6
    80001d4c:	2b8b8b93          	addi	s7,s7,696 # 80008000 <etext>
    80001d50:	04000a37          	lui	s4,0x4000
    80001d54:	1a7d                	addi	s4,s4,-1
    80001d56:	0a32                	slli	s4,s4,0xc
  p->next_proc = -1;
    80001d58:	59fd                	li	s3,-1
      p->proc_ind = i;
      initialize_proc(p);
      append(&unused_list, p); // procinit to admit all UNUSED process entries
    80001d5a:	00007b17          	auipc	s6,0x7
    80001d5e:	ba6b0b13          	addi	s6,s6,-1114 # 80008900 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d62:	00016a97          	auipc	s5,0x16
    80001d66:	eaea8a93          	addi	s5,s5,-338 # 80017c10 <tickslock>
      initlock(&p->lock, "proc");
    80001d6a:	85ea                	mv	a1,s10
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	de6080e7          	jalr	-538(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list_lock");
    80001d76:	85e6                	mv	a1,s9
    80001d78:	17848513          	addi	a0,s1,376
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	dd8080e7          	jalr	-552(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001d84:	418487b3          	sub	a5,s1,s8
    80001d88:	8791                	srai	a5,a5,0x4
    80001d8a:	000bb703          	ld	a4,0(s7)
    80001d8e:	02e787b3          	mul	a5,a5,a4
    80001d92:	2785                	addiw	a5,a5,1
    80001d94:	00d7979b          	slliw	a5,a5,0xd
    80001d98:	40fa07b3          	sub	a5,s4,a5
    80001d9c:	e0bc                	sd	a5,64(s1)
      p->proc_ind = i;
    80001d9e:	1724aa23          	sw	s2,372(s1)
  p->next_proc = -1;
    80001da2:	1734a623          	sw	s3,364(s1)
  p->prev_proc = -1;
    80001da6:	1734a823          	sw	s3,368(s1)
      append(&unused_list, p); // procinit to admit all UNUSED process entries
    80001daa:	85a6                	mv	a1,s1
    80001dac:	855a                	mv	a0,s6
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	ca2080e7          	jalr	-862(ra) # 80001a50 <append>
      i++;
    80001db6:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db8:	19048493          	addi	s1,s1,400
    80001dbc:	fb5497e3          	bne	s1,s5,80001d6a <procinit+0x92>
  }
}
    80001dc0:	60e6                	ld	ra,88(sp)
    80001dc2:	6446                	ld	s0,80(sp)
    80001dc4:	64a6                	ld	s1,72(sp)
    80001dc6:	6906                	ld	s2,64(sp)
    80001dc8:	79e2                	ld	s3,56(sp)
    80001dca:	7a42                	ld	s4,48(sp)
    80001dcc:	7aa2                	ld	s5,40(sp)
    80001dce:	7b02                	ld	s6,32(sp)
    80001dd0:	6be2                	ld	s7,24(sp)
    80001dd2:	6c42                	ld	s8,16(sp)
    80001dd4:	6ca2                	ld	s9,8(sp)
    80001dd6:	6d02                	ld	s10,0(sp)
    80001dd8:	6125                	addi	sp,sp,96
    80001dda:	8082                	ret

0000000080001ddc <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ddc:	1141                	addi	sp,sp,-16
    80001dde:	e422                	sd	s0,8(sp)
    80001de0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001de2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001de4:	2501                	sext.w	a0,a0
    80001de6:	6422                	ld	s0,8(sp)
    80001de8:	0141                	addi	sp,sp,16
    80001dea:	8082                	ret

0000000080001dec <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001dec:	1141                	addi	sp,sp,-16
    80001dee:	e422                	sd	s0,8(sp)
    80001df0:	0800                	addi	s0,sp,16
    80001df2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001df4:	2781                	sext.w	a5,a5
    80001df6:	0a800513          	li	a0,168
    80001dfa:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001dfe:	0000f517          	auipc	a0,0xf
    80001e02:	4a250513          	addi	a0,a0,1186 # 800112a0 <cpus>
    80001e06:	953e                	add	a0,a0,a5
    80001e08:	6422                	ld	s0,8(sp)
    80001e0a:	0141                	addi	sp,sp,16
    80001e0c:	8082                	ret

0000000080001e0e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e0e:	1101                	addi	sp,sp,-32
    80001e10:	ec06                	sd	ra,24(sp)
    80001e12:	e822                	sd	s0,16(sp)
    80001e14:	e426                	sd	s1,8(sp)
    80001e16:	1000                	addi	s0,sp,32
  push_off();
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	d80080e7          	jalr	-640(ra) # 80000b98 <push_off>
    80001e20:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e22:	2781                	sext.w	a5,a5
    80001e24:	0a800713          	li	a4,168
    80001e28:	02e787b3          	mul	a5,a5,a4
    80001e2c:	0000f717          	auipc	a4,0xf
    80001e30:	47470713          	addi	a4,a4,1140 # 800112a0 <cpus>
    80001e34:	97ba                	add	a5,a5,a4
    80001e36:	6384                	ld	s1,0(a5)
  pop_off();
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e00080e7          	jalr	-512(ra) # 80000c38 <pop_off>
  return p;
}
    80001e40:	8526                	mv	a0,s1
    80001e42:	60e2                	ld	ra,24(sp)
    80001e44:	6442                	ld	s0,16(sp)
    80001e46:	64a2                	ld	s1,8(sp)
    80001e48:	6105                	addi	sp,sp,32
    80001e4a:	8082                	ret

0000000080001e4c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e4c:	1141                	addi	sp,sp,-16
    80001e4e:	e406                	sd	ra,8(sp)
    80001e50:	e022                	sd	s0,0(sp)
    80001e52:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	fba080e7          	jalr	-70(ra) # 80001e0e <myproc>
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e3c080e7          	jalr	-452(ra) # 80000c98 <release>

  if (first) {
    80001e64:	00007797          	auipc	a5,0x7
    80001e68:	a8c7a783          	lw	a5,-1396(a5) # 800088f0 <first.1757>
    80001e6c:	eb89                	bnez	a5,80001e7e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e6e:	00001097          	auipc	ra,0x1
    80001e72:	ee2080e7          	jalr	-286(ra) # 80002d50 <usertrapret>
}
    80001e76:	60a2                	ld	ra,8(sp)
    80001e78:	6402                	ld	s0,0(sp)
    80001e7a:	0141                	addi	sp,sp,16
    80001e7c:	8082                	ret
    first = 0;
    80001e7e:	00007797          	auipc	a5,0x7
    80001e82:	a607a923          	sw	zero,-1422(a5) # 800088f0 <first.1757>
    fsinit(ROOTDEV);
    80001e86:	4505                	li	a0,1
    80001e88:	00002097          	auipc	ra,0x2
    80001e8c:	c0a080e7          	jalr	-1014(ra) # 80003a92 <fsinit>
    80001e90:	bff9                	j	80001e6e <forkret+0x22>

0000000080001e92 <allocpid>:
allocpid() {
    80001e92:	1101                	addi	sp,sp,-32
    80001e94:	ec06                	sd	ra,24(sp)
    80001e96:	e822                	sd	s0,16(sp)
    80001e98:	e426                	sd	s1,8(sp)
    80001e9a:	e04a                	sd	s2,0(sp)
    80001e9c:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001e9e:	00007917          	auipc	s2,0x7
    80001ea2:	a5690913          	addi	s2,s2,-1450 # 800088f4 <nextpid>
    80001ea6:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001eaa:	0014861b          	addiw	a2,s1,1
    80001eae:	85a6                	mv	a1,s1
    80001eb0:	854a                	mv	a0,s2
    80001eb2:	00005097          	auipc	ra,0x5
    80001eb6:	9e4080e7          	jalr	-1564(ra) # 80006896 <cas>
    80001eba:	2501                	sext.w	a0,a0
    80001ebc:	f56d                	bnez	a0,80001ea6 <allocpid+0x14>
}
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	60e2                	ld	ra,24(sp)
    80001ec2:	6442                	ld	s0,16(sp)
    80001ec4:	64a2                	ld	s1,8(sp)
    80001ec6:	6902                	ld	s2,0(sp)
    80001ec8:	6105                	addi	sp,sp,32
    80001eca:	8082                	ret

0000000080001ecc <proc_pagetable>:
{
    80001ecc:	1101                	addi	sp,sp,-32
    80001ece:	ec06                	sd	ra,24(sp)
    80001ed0:	e822                	sd	s0,16(sp)
    80001ed2:	e426                	sd	s1,8(sp)
    80001ed4:	e04a                	sd	s2,0(sp)
    80001ed6:	1000                	addi	s0,sp,32
    80001ed8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	460080e7          	jalr	1120(ra) # 8000133a <uvmcreate>
    80001ee2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ee4:	c121                	beqz	a0,80001f24 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ee6:	4729                	li	a4,10
    80001ee8:	00005697          	auipc	a3,0x5
    80001eec:	11868693          	addi	a3,a3,280 # 80007000 <_trampoline>
    80001ef0:	6605                	lui	a2,0x1
    80001ef2:	040005b7          	lui	a1,0x4000
    80001ef6:	15fd                	addi	a1,a1,-1
    80001ef8:	05b2                	slli	a1,a1,0xc
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	1b6080e7          	jalr	438(ra) # 800010b0 <mappages>
    80001f02:	02054863          	bltz	a0,80001f32 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f06:	4719                	li	a4,6
    80001f08:	05893683          	ld	a3,88(s2)
    80001f0c:	6605                	lui	a2,0x1
    80001f0e:	020005b7          	lui	a1,0x2000
    80001f12:	15fd                	addi	a1,a1,-1
    80001f14:	05b6                	slli	a1,a1,0xd
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	198080e7          	jalr	408(ra) # 800010b0 <mappages>
    80001f20:	02054163          	bltz	a0,80001f42 <proc_pagetable+0x76>
}
    80001f24:	8526                	mv	a0,s1
    80001f26:	60e2                	ld	ra,24(sp)
    80001f28:	6442                	ld	s0,16(sp)
    80001f2a:	64a2                	ld	s1,8(sp)
    80001f2c:	6902                	ld	s2,0(sp)
    80001f2e:	6105                	addi	sp,sp,32
    80001f30:	8082                	ret
    uvmfree(pagetable, 0);
    80001f32:	4581                	li	a1,0
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	600080e7          	jalr	1536(ra) # 80001536 <uvmfree>
    return 0;
    80001f3e:	4481                	li	s1,0
    80001f40:	b7d5                	j	80001f24 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f42:	4681                	li	a3,0
    80001f44:	4605                	li	a2,1
    80001f46:	040005b7          	lui	a1,0x4000
    80001f4a:	15fd                	addi	a1,a1,-1
    80001f4c:	05b2                	slli	a1,a1,0xc
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	326080e7          	jalr	806(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f58:	4581                	li	a1,0
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	5da080e7          	jalr	1498(ra) # 80001536 <uvmfree>
    return 0;
    80001f64:	4481                	li	s1,0
    80001f66:	bf7d                	j	80001f24 <proc_pagetable+0x58>

0000000080001f68 <proc_freepagetable>:
{
    80001f68:	1101                	addi	sp,sp,-32
    80001f6a:	ec06                	sd	ra,24(sp)
    80001f6c:	e822                	sd	s0,16(sp)
    80001f6e:	e426                	sd	s1,8(sp)
    80001f70:	e04a                	sd	s2,0(sp)
    80001f72:	1000                	addi	s0,sp,32
    80001f74:	84aa                	mv	s1,a0
    80001f76:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f78:	4681                	li	a3,0
    80001f7a:	4605                	li	a2,1
    80001f7c:	040005b7          	lui	a1,0x4000
    80001f80:	15fd                	addi	a1,a1,-1
    80001f82:	05b2                	slli	a1,a1,0xc
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	2f2080e7          	jalr	754(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f8c:	4681                	li	a3,0
    80001f8e:	4605                	li	a2,1
    80001f90:	020005b7          	lui	a1,0x2000
    80001f94:	15fd                	addi	a1,a1,-1
    80001f96:	05b6                	slli	a1,a1,0xd
    80001f98:	8526                	mv	a0,s1
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	2dc080e7          	jalr	732(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001fa2:	85ca                	mv	a1,s2
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	590080e7          	jalr	1424(ra) # 80001536 <uvmfree>
}
    80001fae:	60e2                	ld	ra,24(sp)
    80001fb0:	6442                	ld	s0,16(sp)
    80001fb2:	64a2                	ld	s1,8(sp)
    80001fb4:	6902                	ld	s2,0(sp)
    80001fb6:	6105                	addi	sp,sp,32
    80001fb8:	8082                	ret

0000000080001fba <freeproc>:
{
    80001fba:	1101                	addi	sp,sp,-32
    80001fbc:	ec06                	sd	ra,24(sp)
    80001fbe:	e822                	sd	s0,16(sp)
    80001fc0:	e426                	sd	s1,8(sp)
    80001fc2:	1000                	addi	s0,sp,32
    80001fc4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fc6:	6d28                	ld	a0,88(a0)
    80001fc8:	c509                	beqz	a0,80001fd2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	a2e080e7          	jalr	-1490(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001fd2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001fd6:	68a8                	ld	a0,80(s1)
    80001fd8:	c511                	beqz	a0,80001fe4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001fda:	64ac                	ld	a1,72(s1)
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	f8c080e7          	jalr	-116(ra) # 80001f68 <proc_freepagetable>
  p->pagetable = 0;
    80001fe4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001fe8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001fec:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ff0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ff4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ff8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ffc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002000:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002004:	0004ac23          	sw	zero,24(s1)
  remove(&zombie_list, p); // remove the freed process from the ZOMBIE list
    80002008:	85a6                	mv	a1,s1
    8000200a:	00007517          	auipc	a0,0x7
    8000200e:	93650513          	addi	a0,a0,-1738 # 80008940 <zombie_list>
    80002012:	00000097          	auipc	ra,0x0
    80002016:	b1e080e7          	jalr	-1250(ra) # 80001b30 <remove>
  append(&unused_list, p); // admit its entry to the UNUSED entry list.
    8000201a:	85a6                	mv	a1,s1
    8000201c:	00007517          	auipc	a0,0x7
    80002020:	8e450513          	addi	a0,a0,-1820 # 80008900 <unused_list>
    80002024:	00000097          	auipc	ra,0x0
    80002028:	a2c080e7          	jalr	-1492(ra) # 80001a50 <append>
}
    8000202c:	60e2                	ld	ra,24(sp)
    8000202e:	6442                	ld	s0,16(sp)
    80002030:	64a2                	ld	s1,8(sp)
    80002032:	6105                	addi	sp,sp,32
    80002034:	8082                	ret

0000000080002036 <allocproc>:
{
    80002036:	715d                	addi	sp,sp,-80
    80002038:	e486                	sd	ra,72(sp)
    8000203a:	e0a2                	sd	s0,64(sp)
    8000203c:	fc26                	sd	s1,56(sp)
    8000203e:	f84a                	sd	s2,48(sp)
    80002040:	f44e                	sd	s3,40(sp)
    80002042:	f052                	sd	s4,32(sp)
    80002044:	ec56                	sd	s5,24(sp)
    80002046:	e85a                	sd	s6,16(sp)
    80002048:	e45e                	sd	s7,8(sp)
    8000204a:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    8000204c:	00007717          	auipc	a4,0x7
    80002050:	8b472703          	lw	a4,-1868(a4) # 80008900 <unused_list>
    80002054:	57fd                	li	a5,-1
    80002056:	14f70063          	beq	a4,a5,80002196 <allocproc+0x160>
    p = &proc[get_head(&unused_list)];
    8000205a:	00007a17          	auipc	s4,0x7
    8000205e:	8a6a0a13          	addi	s4,s4,-1882 # 80008900 <unused_list>
    80002062:	19000b13          	li	s6,400
    80002066:	0000fa97          	auipc	s5,0xf
    8000206a:	7aaa8a93          	addi	s5,s5,1962 # 80011810 <proc>
  while(!isEmpty(&unused_list)){
    8000206e:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    80002070:	8552                	mv	a0,s4
    80002072:	00000097          	auipc	ra,0x0
    80002076:	988080e7          	jalr	-1656(ra) # 800019fa <get_head>
    8000207a:	892a                	mv	s2,a0
    8000207c:	036509b3          	mul	s3,a0,s6
    80002080:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    80002084:	8526                	mv	a0,s1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b5e080e7          	jalr	-1186(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    8000208e:	4c9c                	lw	a5,24(s1)
    80002090:	c79d                	beqz	a5,800020be <allocproc+0x88>
      release(&p->lock);
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	c04080e7          	jalr	-1020(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    8000209c:	000a2783          	lw	a5,0(s4)
    800020a0:	fd7798e3          	bne	a5,s7,80002070 <allocproc+0x3a>
  return 0;
    800020a4:	4481                	li	s1,0
}
    800020a6:	8526                	mv	a0,s1
    800020a8:	60a6                	ld	ra,72(sp)
    800020aa:	6406                	ld	s0,64(sp)
    800020ac:	74e2                	ld	s1,56(sp)
    800020ae:	7942                	ld	s2,48(sp)
    800020b0:	79a2                	ld	s3,40(sp)
    800020b2:	7a02                	ld	s4,32(sp)
    800020b4:	6ae2                	ld	s5,24(sp)
    800020b6:	6b42                	ld	s6,16(sp)
    800020b8:	6ba2                	ld	s7,8(sp)
    800020ba:	6161                	addi	sp,sp,80
    800020bc:	8082                	ret
      remove(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    800020be:	85a6                	mv	a1,s1
    800020c0:	00007517          	auipc	a0,0x7
    800020c4:	84050513          	addi	a0,a0,-1984 # 80008900 <unused_list>
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	a68080e7          	jalr	-1432(ra) # 80001b30 <remove>
  p->pid = allocpid();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	dc2080e7          	jalr	-574(ra) # 80001e92 <allocpid>
    800020d8:	19000a13          	li	s4,400
    800020dc:	034907b3          	mul	a5,s2,s4
    800020e0:	0000fa17          	auipc	s4,0xf
    800020e4:	730a0a13          	addi	s4,s4,1840 # 80011810 <proc>
    800020e8:	9a3e                	add	s4,s4,a5
    800020ea:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    800020ee:	4785                	li	a5,1
    800020f0:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	a00080e7          	jalr	-1536(ra) # 80000af4 <kalloc>
    800020fc:	8aaa                	mv	s5,a0
    800020fe:	04aa3c23          	sd	a0,88(s4)
    80002102:	c135                	beqz	a0,80002166 <allocproc+0x130>
  p->pagetable = proc_pagetable(p);
    80002104:	8526                	mv	a0,s1
    80002106:	00000097          	auipc	ra,0x0
    8000210a:	dc6080e7          	jalr	-570(ra) # 80001ecc <proc_pagetable>
    8000210e:	8a2a                	mv	s4,a0
    80002110:	19000793          	li	a5,400
    80002114:	02f90733          	mul	a4,s2,a5
    80002118:	0000f797          	auipc	a5,0xf
    8000211c:	6f878793          	addi	a5,a5,1784 # 80011810 <proc>
    80002120:	97ba                	add	a5,a5,a4
    80002122:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80002124:	cd29                	beqz	a0,8000217e <allocproc+0x148>
  memset(&p->context, 0, sizeof(p->context));
    80002126:	06098513          	addi	a0,s3,96
    8000212a:	0000f997          	auipc	s3,0xf
    8000212e:	6e698993          	addi	s3,s3,1766 # 80011810 <proc>
    80002132:	07000613          	li	a2,112
    80002136:	4581                	li	a1,0
    80002138:	954e                	add	a0,a0,s3
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	ba6080e7          	jalr	-1114(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002142:	19000793          	li	a5,400
    80002146:	02f90933          	mul	s2,s2,a5
    8000214a:	994e                	add	s2,s2,s3
    8000214c:	00000797          	auipc	a5,0x0
    80002150:	d0078793          	addi	a5,a5,-768 # 80001e4c <forkret>
    80002154:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002158:	04093783          	ld	a5,64(s2)
    8000215c:	6705                	lui	a4,0x1
    8000215e:	97ba                	add	a5,a5,a4
    80002160:	06f93423          	sd	a5,104(s2)
  return p;
    80002164:	b789                	j	800020a6 <allocproc+0x70>
    freeproc(p);
    80002166:	8526                	mv	a0,s1
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	e52080e7          	jalr	-430(ra) # 80001fba <freeproc>
    release(&p->lock);
    80002170:	8526                	mv	a0,s1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	b26080e7          	jalr	-1242(ra) # 80000c98 <release>
    return 0;
    8000217a:	84d6                	mv	s1,s5
    8000217c:	b72d                	j	800020a6 <allocproc+0x70>
    freeproc(p);
    8000217e:	8526                	mv	a0,s1
    80002180:	00000097          	auipc	ra,0x0
    80002184:	e3a080e7          	jalr	-454(ra) # 80001fba <freeproc>
    release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b0e080e7          	jalr	-1266(ra) # 80000c98 <release>
    return 0;
    80002192:	84d2                	mv	s1,s4
    80002194:	bf09                	j	800020a6 <allocproc+0x70>
  return 0;
    80002196:	4481                	li	s1,0
    80002198:	b739                	j	800020a6 <allocproc+0x70>

000000008000219a <userinit>:
{
    8000219a:	1101                	addi	sp,sp,-32
    8000219c:	ec06                	sd	ra,24(sp)
    8000219e:	e822                	sd	s0,16(sp)
    800021a0:	e426                	sd	s1,8(sp)
    800021a2:	1000                	addi	s0,sp,32
  p = allocproc();
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	e92080e7          	jalr	-366(ra) # 80002036 <allocproc>
    800021ac:	84aa                	mv	s1,a0
  initproc = p;
    800021ae:	00007797          	auipc	a5,0x7
    800021b2:	e6a7bd23          	sd	a0,-390(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021b6:	03400613          	li	a2,52
    800021ba:	00006597          	auipc	a1,0x6
    800021be:	7a658593          	addi	a1,a1,1958 # 80008960 <initcode>
    800021c2:	6928                	ld	a0,80(a0)
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	1a4080e7          	jalr	420(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800021cc:	6785                	lui	a5,0x1
    800021ce:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800021d0:	6cb8                	ld	a4,88(s1)
    800021d2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021d6:	6cb8                	ld	a4,88(s1)
    800021d8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021da:	4641                	li	a2,16
    800021dc:	00006597          	auipc	a1,0x6
    800021e0:	0fc58593          	addi	a1,a1,252 # 800082d8 <digits+0x298>
    800021e4:	15848513          	addi	a0,s1,344
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	c4a080e7          	jalr	-950(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800021f0:	00006517          	auipc	a0,0x6
    800021f4:	0f850513          	addi	a0,a0,248 # 800082e8 <digits+0x2a8>
    800021f8:	00002097          	auipc	ra,0x2
    800021fc:	2c8080e7          	jalr	712(ra) # 800044c0 <namei>
    80002200:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002204:	478d                	li	a5,3
    80002206:	cc9c                	sw	a5,24(s1)
  append(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    80002208:	85a6                	mv	a1,s1
    8000220a:	0000f517          	auipc	a0,0xf
    8000220e:	11e50513          	addi	a0,a0,286 # 80011328 <cpus+0x88>
    80002212:	00000097          	auipc	ra,0x0
    80002216:	83e080e7          	jalr	-1986(ra) # 80001a50 <append>
  release(&p->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	a7c080e7          	jalr	-1412(ra) # 80000c98 <release>
}
    80002224:	60e2                	ld	ra,24(sp)
    80002226:	6442                	ld	s0,16(sp)
    80002228:	64a2                	ld	s1,8(sp)
    8000222a:	6105                	addi	sp,sp,32
    8000222c:	8082                	ret

000000008000222e <growproc>:
{
    8000222e:	1101                	addi	sp,sp,-32
    80002230:	ec06                	sd	ra,24(sp)
    80002232:	e822                	sd	s0,16(sp)
    80002234:	e426                	sd	s1,8(sp)
    80002236:	e04a                	sd	s2,0(sp)
    80002238:	1000                	addi	s0,sp,32
    8000223a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000223c:	00000097          	auipc	ra,0x0
    80002240:	bd2080e7          	jalr	-1070(ra) # 80001e0e <myproc>
    80002244:	892a                	mv	s2,a0
  sz = p->sz;
    80002246:	652c                	ld	a1,72(a0)
    80002248:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000224c:	00904f63          	bgtz	s1,8000226a <growproc+0x3c>
  } else if(n < 0){
    80002250:	0204cc63          	bltz	s1,80002288 <growproc+0x5a>
  p->sz = sz;
    80002254:	1602                	slli	a2,a2,0x20
    80002256:	9201                	srli	a2,a2,0x20
    80002258:	04c93423          	sd	a2,72(s2)
  return 0;
    8000225c:	4501                	li	a0,0
}
    8000225e:	60e2                	ld	ra,24(sp)
    80002260:	6442                	ld	s0,16(sp)
    80002262:	64a2                	ld	s1,8(sp)
    80002264:	6902                	ld	s2,0(sp)
    80002266:	6105                	addi	sp,sp,32
    80002268:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000226a:	9e25                	addw	a2,a2,s1
    8000226c:	1602                	slli	a2,a2,0x20
    8000226e:	9201                	srli	a2,a2,0x20
    80002270:	1582                	slli	a1,a1,0x20
    80002272:	9181                	srli	a1,a1,0x20
    80002274:	6928                	ld	a0,80(a0)
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	1ac080e7          	jalr	428(ra) # 80001422 <uvmalloc>
    8000227e:	0005061b          	sext.w	a2,a0
    80002282:	fa69                	bnez	a2,80002254 <growproc+0x26>
      return -1;
    80002284:	557d                	li	a0,-1
    80002286:	bfe1                	j	8000225e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002288:	9e25                	addw	a2,a2,s1
    8000228a:	1602                	slli	a2,a2,0x20
    8000228c:	9201                	srli	a2,a2,0x20
    8000228e:	1582                	slli	a1,a1,0x20
    80002290:	9181                	srli	a1,a1,0x20
    80002292:	6928                	ld	a0,80(a0)
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	146080e7          	jalr	326(ra) # 800013da <uvmdealloc>
    8000229c:	0005061b          	sext.w	a2,a0
    800022a0:	bf55                	j	80002254 <growproc+0x26>

00000000800022a2 <fork>:
{
    800022a2:	7139                	addi	sp,sp,-64
    800022a4:	fc06                	sd	ra,56(sp)
    800022a6:	f822                	sd	s0,48(sp)
    800022a8:	f426                	sd	s1,40(sp)
    800022aa:	f04a                	sd	s2,32(sp)
    800022ac:	ec4e                	sd	s3,24(sp)
    800022ae:	e852                	sd	s4,16(sp)
    800022b0:	e456                	sd	s5,8(sp)
    800022b2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	b5a080e7          	jalr	-1190(ra) # 80001e0e <myproc>
    800022bc:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	d78080e7          	jalr	-648(ra) # 80002036 <allocproc>
    800022c6:	14050663          	beqz	a0,80002412 <fork+0x170>
    800022ca:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022cc:	04893603          	ld	a2,72(s2)
    800022d0:	692c                	ld	a1,80(a0)
    800022d2:	05093503          	ld	a0,80(s2)
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	298080e7          	jalr	664(ra) # 8000156e <uvmcopy>
    800022de:	04054663          	bltz	a0,8000232a <fork+0x88>
  np->sz = p->sz;
    800022e2:	04893783          	ld	a5,72(s2)
    800022e6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800022ea:	05893683          	ld	a3,88(s2)
    800022ee:	87b6                	mv	a5,a3
    800022f0:	0589b703          	ld	a4,88(s3)
    800022f4:	12068693          	addi	a3,a3,288
    800022f8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800022fc:	6788                	ld	a0,8(a5)
    800022fe:	6b8c                	ld	a1,16(a5)
    80002300:	6f90                	ld	a2,24(a5)
    80002302:	01073023          	sd	a6,0(a4)
    80002306:	e708                	sd	a0,8(a4)
    80002308:	eb0c                	sd	a1,16(a4)
    8000230a:	ef10                	sd	a2,24(a4)
    8000230c:	02078793          	addi	a5,a5,32
    80002310:	02070713          	addi	a4,a4,32
    80002314:	fed792e3          	bne	a5,a3,800022f8 <fork+0x56>
  np->trapframe->a0 = 0;
    80002318:	0589b783          	ld	a5,88(s3)
    8000231c:	0607b823          	sd	zero,112(a5)
    80002320:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002324:	15000a13          	li	s4,336
    80002328:	a03d                	j	80002356 <fork+0xb4>
    freeproc(np);
    8000232a:	854e                	mv	a0,s3
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	c8e080e7          	jalr	-882(ra) # 80001fba <freeproc>
    release(&np->lock);
    80002334:	854e                	mv	a0,s3
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
    return -1;
    8000233e:	5afd                	li	s5,-1
    80002340:	a87d                	j	800023fe <fork+0x15c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002342:	00003097          	auipc	ra,0x3
    80002346:	814080e7          	jalr	-2028(ra) # 80004b56 <filedup>
    8000234a:	009987b3          	add	a5,s3,s1
    8000234e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002350:	04a1                	addi	s1,s1,8
    80002352:	01448763          	beq	s1,s4,80002360 <fork+0xbe>
    if(p->ofile[i])
    80002356:	009907b3          	add	a5,s2,s1
    8000235a:	6388                	ld	a0,0(a5)
    8000235c:	f17d                	bnez	a0,80002342 <fork+0xa0>
    8000235e:	bfcd                	j	80002350 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002360:	15093503          	ld	a0,336(s2)
    80002364:	00002097          	auipc	ra,0x2
    80002368:	968080e7          	jalr	-1688(ra) # 80003ccc <idup>
    8000236c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002370:	4641                	li	a2,16
    80002372:	15890593          	addi	a1,s2,344
    80002376:	15898513          	addi	a0,s3,344
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	ab8080e7          	jalr	-1352(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002382:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80002386:	854e                	mv	a0,s3
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002390:	0000fa17          	auipc	s4,0xf
    80002394:	f10a0a13          	addi	s4,s4,-240 # 800112a0 <cpus>
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	46048493          	addi	s1,s1,1120 # 800117f8 <wait_lock>
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	842080e7          	jalr	-1982(ra) # 80000be4 <acquire>
  np->parent = p;
    800023aa:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8e8080e7          	jalr	-1816(ra) # 80000c98 <release>
  acquire(&np->lock);
    800023b8:	854e                	mv	a0,s3
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	82a080e7          	jalr	-2006(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023c2:	478d                	li	a5,3
    800023c4:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    800023c8:	16892483          	lw	s1,360(s2)
    800023cc:	1699a423          	sw	s1,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    800023d0:	0a800513          	li	a0,168
    800023d4:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    800023d8:	009a0533          	add	a0,s4,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	462080e7          	jalr	1122(ra) # 8000183e <increment_cpu_process_count>
  append(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    800023e4:	08848513          	addi	a0,s1,136
    800023e8:	85ce                	mv	a1,s3
    800023ea:	9552                	add	a0,a0,s4
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	664080e7          	jalr	1636(ra) # 80001a50 <append>
  release(&np->lock);
    800023f4:	854e                	mv	a0,s3
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	8a2080e7          	jalr	-1886(ra) # 80000c98 <release>
}
    800023fe:	8556                	mv	a0,s5
    80002400:	70e2                	ld	ra,56(sp)
    80002402:	7442                	ld	s0,48(sp)
    80002404:	74a2                	ld	s1,40(sp)
    80002406:	7902                	ld	s2,32(sp)
    80002408:	69e2                	ld	s3,24(sp)
    8000240a:	6a42                	ld	s4,16(sp)
    8000240c:	6aa2                	ld	s5,8(sp)
    8000240e:	6121                	addi	sp,sp,64
    80002410:	8082                	ret
    return -1;
    80002412:	5afd                	li	s5,-1
    80002414:	b7ed                	j	800023fe <fork+0x15c>

0000000080002416 <scheduler>:
{
    80002416:	715d                	addi	sp,sp,-80
    80002418:	e486                	sd	ra,72(sp)
    8000241a:	e0a2                	sd	s0,64(sp)
    8000241c:	fc26                	sd	s1,56(sp)
    8000241e:	f84a                	sd	s2,48(sp)
    80002420:	f44e                	sd	s3,40(sp)
    80002422:	f052                	sd	s4,32(sp)
    80002424:	ec56                	sd	s5,24(sp)
    80002426:	e85a                	sd	s6,16(sp)
    80002428:	e45e                	sd	s7,8(sp)
    8000242a:	e062                	sd	s8,0(sp)
    8000242c:	0880                	addi	s0,sp,80
    8000242e:	8712                	mv	a4,tp
  int id = r_tp();
    80002430:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002432:	0000fb17          	auipc	s6,0xf
    80002436:	e6eb0b13          	addi	s6,s6,-402 # 800112a0 <cpus>
    8000243a:	0a800793          	li	a5,168
    8000243e:	02f707b3          	mul	a5,a4,a5
    80002442:	00fb06b3          	add	a3,s6,a5
    80002446:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    8000244a:	08878a13          	addi	s4,a5,136
    8000244e:	9a5a                	add	s4,s4,s6
          swtch(&c->context, &p->context);
    80002450:	07a1                	addi	a5,a5,8
    80002452:	9b3e                	add	s6,s6,a5
  return lst->head == -1;
    80002454:	8936                	mv	s2,a3
      if(p->state == RUNNABLE) {
    80002456:	0000f997          	auipc	s3,0xf
    8000245a:	3ba98993          	addi	s3,s3,954 # 80011810 <proc>
    8000245e:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002462:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002466:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000246a:	10079073          	csrw	sstatus,a5
    8000246e:	4b8d                	li	s7,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002470:	54fd                	li	s1,-1
    80002472:	08892783          	lw	a5,136(s2)
    80002476:	fe9786e3          	beq	a5,s1,80002462 <scheduler+0x4c>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000247a:	8552                	mv	a0,s4
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	57e080e7          	jalr	1406(ra) # 800019fa <get_head>
      if(p->state == RUNNABLE) {
    80002484:	035507b3          	mul	a5,a0,s5
    80002488:	97ce                	add	a5,a5,s3
    8000248a:	4f9c                	lw	a5,24(a5)
    8000248c:	ff7793e3          	bne	a5,s7,80002472 <scheduler+0x5c>
    80002490:	035504b3          	mul	s1,a0,s5
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80002494:	01348c33          	add	s8,s1,s3
        acquire(&p->lock);
    80002498:	8562                	mv	a0,s8
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	74a080e7          	jalr	1866(ra) # 80000be4 <acquire>
          remove(&(c->runnable_list), p);
    800024a2:	85e2                	mv	a1,s8
    800024a4:	8552                	mv	a0,s4
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	68a080e7          	jalr	1674(ra) # 80001b30 <remove>
          p->state = RUNNING;
    800024ae:	4791                	li	a5,4
    800024b0:	00fc2c23          	sw	a5,24(s8)
          c->proc = p;
    800024b4:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    800024b8:	08492783          	lw	a5,132(s2)
    800024bc:	16fc2423          	sw	a5,360(s8)
          swtch(&c->context, &p->context);
    800024c0:	06048593          	addi	a1,s1,96
    800024c4:	95ce                	add	a1,a1,s3
    800024c6:	855a                	mv	a0,s6
    800024c8:	00000097          	auipc	ra,0x0
    800024cc:	7de080e7          	jalr	2014(ra) # 80002ca6 <swtch>
          c->proc = 0;
    800024d0:	00093023          	sd	zero,0(s2)
        release(&p->lock);
    800024d4:	8562                	mv	a0,s8
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	7c2080e7          	jalr	1986(ra) # 80000c98 <release>
    800024de:	bf49                	j	80002470 <scheduler+0x5a>

00000000800024e0 <sched>:
{
    800024e0:	7179                	addi	sp,sp,-48
    800024e2:	f406                	sd	ra,40(sp)
    800024e4:	f022                	sd	s0,32(sp)
    800024e6:	ec26                	sd	s1,24(sp)
    800024e8:	e84a                	sd	s2,16(sp)
    800024ea:	e44e                	sd	s3,8(sp)
    800024ec:	e052                	sd	s4,0(sp)
    800024ee:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800024f0:	00000097          	auipc	ra,0x0
    800024f4:	91e080e7          	jalr	-1762(ra) # 80001e0e <myproc>
    800024f8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	670080e7          	jalr	1648(ra) # 80000b6a <holding>
    80002502:	c141                	beqz	a0,80002582 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002504:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002506:	2781                	sext.w	a5,a5
    80002508:	0a800713          	li	a4,168
    8000250c:	02e787b3          	mul	a5,a5,a4
    80002510:	0000f717          	auipc	a4,0xf
    80002514:	d9070713          	addi	a4,a4,-624 # 800112a0 <cpus>
    80002518:	97ba                	add	a5,a5,a4
    8000251a:	5fb8                	lw	a4,120(a5)
    8000251c:	4785                	li	a5,1
    8000251e:	06f71a63          	bne	a4,a5,80002592 <sched+0xb2>
  if(p->state == RUNNING)
    80002522:	4c98                	lw	a4,24(s1)
    80002524:	4791                	li	a5,4
    80002526:	06f70e63          	beq	a4,a5,800025a2 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000252a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000252e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002530:	e3c9                	bnez	a5,800025b2 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002532:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002534:	0000f917          	auipc	s2,0xf
    80002538:	d6c90913          	addi	s2,s2,-660 # 800112a0 <cpus>
    8000253c:	2781                	sext.w	a5,a5
    8000253e:	0a800993          	li	s3,168
    80002542:	033787b3          	mul	a5,a5,s3
    80002546:	97ca                	add	a5,a5,s2
    80002548:	07c7aa03          	lw	s4,124(a5)
    8000254c:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000254e:	2581                	sext.w	a1,a1
    80002550:	033585b3          	mul	a1,a1,s3
    80002554:	05a1                	addi	a1,a1,8
    80002556:	95ca                	add	a1,a1,s2
    80002558:	06048513          	addi	a0,s1,96
    8000255c:	00000097          	auipc	ra,0x0
    80002560:	74a080e7          	jalr	1866(ra) # 80002ca6 <swtch>
    80002564:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002566:	2781                	sext.w	a5,a5
    80002568:	033787b3          	mul	a5,a5,s3
    8000256c:	993e                	add	s2,s2,a5
    8000256e:	07492e23          	sw	s4,124(s2)
}
    80002572:	70a2                	ld	ra,40(sp)
    80002574:	7402                	ld	s0,32(sp)
    80002576:	64e2                	ld	s1,24(sp)
    80002578:	6942                	ld	s2,16(sp)
    8000257a:	69a2                	ld	s3,8(sp)
    8000257c:	6a02                	ld	s4,0(sp)
    8000257e:	6145                	addi	sp,sp,48
    80002580:	8082                	ret
    panic("sched p->lock");
    80002582:	00006517          	auipc	a0,0x6
    80002586:	d6e50513          	addi	a0,a0,-658 # 800082f0 <digits+0x2b0>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>
    panic("sched locks");
    80002592:	00006517          	auipc	a0,0x6
    80002596:	d6e50513          	addi	a0,a0,-658 # 80008300 <digits+0x2c0>
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	fa4080e7          	jalr	-92(ra) # 8000053e <panic>
    panic("sched running");
    800025a2:	00006517          	auipc	a0,0x6
    800025a6:	d6e50513          	addi	a0,a0,-658 # 80008310 <digits+0x2d0>
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	f94080e7          	jalr	-108(ra) # 8000053e <panic>
    panic("sched interruptible");
    800025b2:	00006517          	auipc	a0,0x6
    800025b6:	d6e50513          	addi	a0,a0,-658 # 80008320 <digits+0x2e0>
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	f84080e7          	jalr	-124(ra) # 8000053e <panic>

00000000800025c2 <yield>:
{
    800025c2:	1101                	addi	sp,sp,-32
    800025c4:	ec06                	sd	ra,24(sp)
    800025c6:	e822                	sd	s0,16(sp)
    800025c8:	e426                	sd	s1,8(sp)
    800025ca:	e04a                	sd	s2,0(sp)
    800025cc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	840080e7          	jalr	-1984(ra) # 80001e0e <myproc>
    800025d6:	84aa                	mv	s1,a0
    800025d8:	8912                	mv	s2,tp
  acquire(&p->lock);
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	60a080e7          	jalr	1546(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800025e2:	478d                	li	a5,3
    800025e4:	cc9c                	sw	a5,24(s1)
  append(&(c->runnable_list), p);
    800025e6:	2901                	sext.w	s2,s2
    800025e8:	0a800513          	li	a0,168
    800025ec:	02a90933          	mul	s2,s2,a0
    800025f0:	85a6                	mv	a1,s1
    800025f2:	0000f517          	auipc	a0,0xf
    800025f6:	d3650513          	addi	a0,a0,-714 # 80011328 <cpus+0x88>
    800025fa:	954a                	add	a0,a0,s2
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	454080e7          	jalr	1108(ra) # 80001a50 <append>
  sched();
    80002604:	00000097          	auipc	ra,0x0
    80002608:	edc080e7          	jalr	-292(ra) # 800024e0 <sched>
  release(&p->lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	68a080e7          	jalr	1674(ra) # 80000c98 <release>
}
    80002616:	60e2                	ld	ra,24(sp)
    80002618:	6442                	ld	s0,16(sp)
    8000261a:	64a2                	ld	s1,8(sp)
    8000261c:	6902                	ld	s2,0(sp)
    8000261e:	6105                	addi	sp,sp,32
    80002620:	8082                	ret

0000000080002622 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002622:	7179                	addi	sp,sp,-48
    80002624:	f406                	sd	ra,40(sp)
    80002626:	f022                	sd	s0,32(sp)
    80002628:	ec26                	sd	s1,24(sp)
    8000262a:	e84a                	sd	s2,16(sp)
    8000262c:	e44e                	sd	s3,8(sp)
    8000262e:	1800                	addi	s0,sp,48
    80002630:	89aa                	mv	s3,a0
    80002632:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	7da080e7          	jalr	2010(ra) # 80001e0e <myproc>
    8000263c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	5a6080e7          	jalr	1446(ra) # 80000be4 <acquire>
  release(lk);
    80002646:	854a                	mv	a0,s2
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	650080e7          	jalr	1616(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002650:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002654:	4789                	li	a5,2
    80002656:	cc9c                	sw	a5,24(s1)
  //printf("insert sleep sleep %d\n", p->index); //delete
  append(&sleeping_list, p);
    80002658:	85a6                	mv	a1,s1
    8000265a:	00006517          	auipc	a0,0x6
    8000265e:	2c650513          	addi	a0,a0,710 # 80008920 <sleeping_list>
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	3ee080e7          	jalr	1006(ra) # 80001a50 <append>

  sched();
    8000266a:	00000097          	auipc	ra,0x0
    8000266e:	e76080e7          	jalr	-394(ra) # 800024e0 <sched>

  // Tidy up.
  p->chan = 0;
    80002672:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	620080e7          	jalr	1568(ra) # 80000c98 <release>
  acquire(lk);
    80002680:	854a                	mv	a0,s2
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	562080e7          	jalr	1378(ra) # 80000be4 <acquire>
}
    8000268a:	70a2                	ld	ra,40(sp)
    8000268c:	7402                	ld	s0,32(sp)
    8000268e:	64e2                	ld	s1,24(sp)
    80002690:	6942                	ld	s2,16(sp)
    80002692:	69a2                	ld	s3,8(sp)
    80002694:	6145                	addi	sp,sp,48
    80002696:	8082                	ret

0000000080002698 <wait>:
{
    80002698:	715d                	addi	sp,sp,-80
    8000269a:	e486                	sd	ra,72(sp)
    8000269c:	e0a2                	sd	s0,64(sp)
    8000269e:	fc26                	sd	s1,56(sp)
    800026a0:	f84a                	sd	s2,48(sp)
    800026a2:	f44e                	sd	s3,40(sp)
    800026a4:	f052                	sd	s4,32(sp)
    800026a6:	ec56                	sd	s5,24(sp)
    800026a8:	e85a                	sd	s6,16(sp)
    800026aa:	e45e                	sd	s7,8(sp)
    800026ac:	e062                	sd	s8,0(sp)
    800026ae:	0880                	addi	s0,sp,80
    800026b0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026b2:	fffff097          	auipc	ra,0xfffff
    800026b6:	75c080e7          	jalr	1884(ra) # 80001e0e <myproc>
    800026ba:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026bc:	0000f517          	auipc	a0,0xf
    800026c0:	13c50513          	addi	a0,a0,316 # 800117f8 <wait_lock>
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	520080e7          	jalr	1312(ra) # 80000be4 <acquire>
    havekids = 0;
    800026cc:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800026ce:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800026d0:	00015997          	auipc	s3,0x15
    800026d4:	54098993          	addi	s3,s3,1344 # 80017c10 <tickslock>
        havekids = 1;
    800026d8:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026da:	0000fc17          	auipc	s8,0xf
    800026de:	11ec0c13          	addi	s8,s8,286 # 800117f8 <wait_lock>
    havekids = 0;
    800026e2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800026e4:	0000f497          	auipc	s1,0xf
    800026e8:	12c48493          	addi	s1,s1,300 # 80011810 <proc>
    800026ec:	a0bd                	j	8000275a <wait+0xc2>
          pid = np->pid;
    800026ee:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026f2:	000b0e63          	beqz	s6,8000270e <wait+0x76>
    800026f6:	4691                	li	a3,4
    800026f8:	02c48613          	addi	a2,s1,44
    800026fc:	85da                	mv	a1,s6
    800026fe:	05093503          	ld	a0,80(s2)
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	f70080e7          	jalr	-144(ra) # 80001672 <copyout>
    8000270a:	02054563          	bltz	a0,80002734 <wait+0x9c>
          freeproc(np);
    8000270e:	8526                	mv	a0,s1
    80002710:	00000097          	auipc	ra,0x0
    80002714:	8aa080e7          	jalr	-1878(ra) # 80001fba <freeproc>
          release(&np->lock);
    80002718:	8526                	mv	a0,s1
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	57e080e7          	jalr	1406(ra) # 80000c98 <release>
          release(&wait_lock);
    80002722:	0000f517          	auipc	a0,0xf
    80002726:	0d650513          	addi	a0,a0,214 # 800117f8 <wait_lock>
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	56e080e7          	jalr	1390(ra) # 80000c98 <release>
          return pid;
    80002732:	a09d                	j	80002798 <wait+0x100>
            release(&np->lock);
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	562080e7          	jalr	1378(ra) # 80000c98 <release>
            release(&wait_lock);
    8000273e:	0000f517          	auipc	a0,0xf
    80002742:	0ba50513          	addi	a0,a0,186 # 800117f8 <wait_lock>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	552080e7          	jalr	1362(ra) # 80000c98 <release>
            return -1;
    8000274e:	59fd                	li	s3,-1
    80002750:	a0a1                	j	80002798 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002752:	19048493          	addi	s1,s1,400
    80002756:	03348463          	beq	s1,s3,8000277e <wait+0xe6>
      if(np->parent == p){
    8000275a:	7c9c                	ld	a5,56(s1)
    8000275c:	ff279be3          	bne	a5,s2,80002752 <wait+0xba>
        acquire(&np->lock);
    80002760:	8526                	mv	a0,s1
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	482080e7          	jalr	1154(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000276a:	4c9c                	lw	a5,24(s1)
    8000276c:	f94781e3          	beq	a5,s4,800026ee <wait+0x56>
        release(&np->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	526080e7          	jalr	1318(ra) # 80000c98 <release>
        havekids = 1;
    8000277a:	8756                	mv	a4,s5
    8000277c:	bfd9                	j	80002752 <wait+0xba>
    if(!havekids || p->killed){
    8000277e:	c701                	beqz	a4,80002786 <wait+0xee>
    80002780:	02892783          	lw	a5,40(s2)
    80002784:	c79d                	beqz	a5,800027b2 <wait+0x11a>
      release(&wait_lock);
    80002786:	0000f517          	auipc	a0,0xf
    8000278a:	07250513          	addi	a0,a0,114 # 800117f8 <wait_lock>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	50a080e7          	jalr	1290(ra) # 80000c98 <release>
      return -1;
    80002796:	59fd                	li	s3,-1
}
    80002798:	854e                	mv	a0,s3
    8000279a:	60a6                	ld	ra,72(sp)
    8000279c:	6406                	ld	s0,64(sp)
    8000279e:	74e2                	ld	s1,56(sp)
    800027a0:	7942                	ld	s2,48(sp)
    800027a2:	79a2                	ld	s3,40(sp)
    800027a4:	7a02                	ld	s4,32(sp)
    800027a6:	6ae2                	ld	s5,24(sp)
    800027a8:	6b42                	ld	s6,16(sp)
    800027aa:	6ba2                	ld	s7,8(sp)
    800027ac:	6c02                	ld	s8,0(sp)
    800027ae:	6161                	addi	sp,sp,80
    800027b0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027b2:	85e2                	mv	a1,s8
    800027b4:	854a                	mv	a0,s2
    800027b6:	00000097          	auipc	ra,0x0
    800027ba:	e6c080e7          	jalr	-404(ra) # 80002622 <sleep>
    havekids = 0;
    800027be:	b715                	j	800026e2 <wait+0x4a>

00000000800027c0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800027c0:	7159                	addi	sp,sp,-112
    800027c2:	f486                	sd	ra,104(sp)
    800027c4:	f0a2                	sd	s0,96(sp)
    800027c6:	eca6                	sd	s1,88(sp)
    800027c8:	e8ca                	sd	s2,80(sp)
    800027ca:	e4ce                	sd	s3,72(sp)
    800027cc:	e0d2                	sd	s4,64(sp)
    800027ce:	fc56                	sd	s5,56(sp)
    800027d0:	f85a                	sd	s6,48(sp)
    800027d2:	f45e                	sd	s7,40(sp)
    800027d4:	f062                	sd	s8,32(sp)
    800027d6:	ec66                	sd	s9,24(sp)
    800027d8:	e86a                	sd	s10,16(sp)
    800027da:	e46e                	sd	s11,8(sp)
    800027dc:	1880                	addi	s0,sp,112
    800027de:	8c2a                	mv	s8,a0
  struct proc *p;
  struct cpu *c;
  int curr = get_head(&sleeping_list);
    800027e0:	00006517          	auipc	a0,0x6
    800027e4:	14050513          	addi	a0,a0,320 # 80008920 <sleeping_list>
    800027e8:	fffff097          	auipc	ra,0xfffff
    800027ec:	212080e7          	jalr	530(ra) # 800019fa <get_head>

  while(curr != -1) {
    800027f0:	57fd                	li	a5,-1
    800027f2:	08f50e63          	beq	a0,a5,8000288e <wakeup+0xce>
    800027f6:	892a                	mv	s2,a0
    p = &proc[curr];
    800027f8:	19000a93          	li	s5,400
    800027fc:	0000fa17          	auipc	s4,0xf
    80002800:	014a0a13          	addi	s4,s4,20 # 80011810 <proc>
    curr = p->next_proc;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002804:	4b89                	li	s7,2
        remove(&sleeping_list, p);
        p->state = RUNNABLE;
    80002806:	4d8d                	li	s11,3
    80002808:	0a800d13          	li	s10,168

        #ifdef ON
          p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
        #endif
        c = &cpus[p->last_cpu];
    8000280c:	0000fc97          	auipc	s9,0xf
    80002810:	a94c8c93          	addi	s9,s9,-1388 # 800112a0 <cpus>
  while(curr != -1) {
    80002814:	5b7d                	li	s6,-1
    80002816:	a801                	j	80002826 <wakeup+0x66>
        increment_cpu_process_count(c);

        append(&(c->runnable_list), p);
      }
      release(&p->lock);
    80002818:	8526                	mv	a0,s1
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	47e080e7          	jalr	1150(ra) # 80000c98 <release>
  while(curr != -1) {
    80002822:	07690663          	beq	s2,s6,8000288e <wakeup+0xce>
    p = &proc[curr];
    80002826:	035904b3          	mul	s1,s2,s5
    8000282a:	94d2                	add	s1,s1,s4
    curr = p->next_proc;
    8000282c:	16c4a903          	lw	s2,364(s1)
    if(p != myproc()){
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	5de080e7          	jalr	1502(ra) # 80001e0e <myproc>
    80002838:	fea485e3          	beq	s1,a0,80002822 <wakeup+0x62>
      acquire(&p->lock);
    8000283c:	8526                	mv	a0,s1
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	3a6080e7          	jalr	934(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002846:	4c9c                	lw	a5,24(s1)
    80002848:	fd7798e3          	bne	a5,s7,80002818 <wakeup+0x58>
    8000284c:	709c                	ld	a5,32(s1)
    8000284e:	fd8795e3          	bne	a5,s8,80002818 <wakeup+0x58>
        remove(&sleeping_list, p);
    80002852:	85a6                	mv	a1,s1
    80002854:	00006517          	auipc	a0,0x6
    80002858:	0cc50513          	addi	a0,a0,204 # 80008920 <sleeping_list>
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	2d4080e7          	jalr	724(ra) # 80001b30 <remove>
        p->state = RUNNABLE;
    80002864:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    80002868:	1684a983          	lw	s3,360(s1)
    8000286c:	03a989b3          	mul	s3,s3,s10
        increment_cpu_process_count(c);
    80002870:	013c8533          	add	a0,s9,s3
    80002874:	fffff097          	auipc	ra,0xfffff
    80002878:	fca080e7          	jalr	-54(ra) # 8000183e <increment_cpu_process_count>
        append(&(c->runnable_list), p);
    8000287c:	08898513          	addi	a0,s3,136
    80002880:	85a6                	mv	a1,s1
    80002882:	9566                	add	a0,a0,s9
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	1cc080e7          	jalr	460(ra) # 80001a50 <append>
    8000288c:	b771                	j	80002818 <wakeup+0x58>
    }
  }
}
    8000288e:	70a6                	ld	ra,104(sp)
    80002890:	7406                	ld	s0,96(sp)
    80002892:	64e6                	ld	s1,88(sp)
    80002894:	6946                	ld	s2,80(sp)
    80002896:	69a6                	ld	s3,72(sp)
    80002898:	6a06                	ld	s4,64(sp)
    8000289a:	7ae2                	ld	s5,56(sp)
    8000289c:	7b42                	ld	s6,48(sp)
    8000289e:	7ba2                	ld	s7,40(sp)
    800028a0:	7c02                	ld	s8,32(sp)
    800028a2:	6ce2                	ld	s9,24(sp)
    800028a4:	6d42                	ld	s10,16(sp)
    800028a6:	6da2                	ld	s11,8(sp)
    800028a8:	6165                	addi	sp,sp,112
    800028aa:	8082                	ret

00000000800028ac <reparent>:
{
    800028ac:	7179                	addi	sp,sp,-48
    800028ae:	f406                	sd	ra,40(sp)
    800028b0:	f022                	sd	s0,32(sp)
    800028b2:	ec26                	sd	s1,24(sp)
    800028b4:	e84a                	sd	s2,16(sp)
    800028b6:	e44e                	sd	s3,8(sp)
    800028b8:	e052                	sd	s4,0(sp)
    800028ba:	1800                	addi	s0,sp,48
    800028bc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028be:	0000f497          	auipc	s1,0xf
    800028c2:	f5248493          	addi	s1,s1,-174 # 80011810 <proc>
      pp->parent = initproc;
    800028c6:	00006a17          	auipc	s4,0x6
    800028ca:	762a0a13          	addi	s4,s4,1890 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028ce:	00015997          	auipc	s3,0x15
    800028d2:	34298993          	addi	s3,s3,834 # 80017c10 <tickslock>
    800028d6:	a029                	j	800028e0 <reparent+0x34>
    800028d8:	19048493          	addi	s1,s1,400
    800028dc:	01348d63          	beq	s1,s3,800028f6 <reparent+0x4a>
    if(pp->parent == p){
    800028e0:	7c9c                	ld	a5,56(s1)
    800028e2:	ff279be3          	bne	a5,s2,800028d8 <reparent+0x2c>
      pp->parent = initproc;
    800028e6:	000a3503          	ld	a0,0(s4)
    800028ea:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	ed4080e7          	jalr	-300(ra) # 800027c0 <wakeup>
    800028f4:	b7d5                	j	800028d8 <reparent+0x2c>
}
    800028f6:	70a2                	ld	ra,40(sp)
    800028f8:	7402                	ld	s0,32(sp)
    800028fa:	64e2                	ld	s1,24(sp)
    800028fc:	6942                	ld	s2,16(sp)
    800028fe:	69a2                	ld	s3,8(sp)
    80002900:	6a02                	ld	s4,0(sp)
    80002902:	6145                	addi	sp,sp,48
    80002904:	8082                	ret

0000000080002906 <exit>:
{
    80002906:	7179                	addi	sp,sp,-48
    80002908:	f406                	sd	ra,40(sp)
    8000290a:	f022                	sd	s0,32(sp)
    8000290c:	ec26                	sd	s1,24(sp)
    8000290e:	e84a                	sd	s2,16(sp)
    80002910:	e44e                	sd	s3,8(sp)
    80002912:	e052                	sd	s4,0(sp)
    80002914:	1800                	addi	s0,sp,48
    80002916:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002918:	fffff097          	auipc	ra,0xfffff
    8000291c:	4f6080e7          	jalr	1270(ra) # 80001e0e <myproc>
    80002920:	89aa                	mv	s3,a0
  if(p == initproc)
    80002922:	00006797          	auipc	a5,0x6
    80002926:	7067b783          	ld	a5,1798(a5) # 80009028 <initproc>
    8000292a:	0d050493          	addi	s1,a0,208
    8000292e:	15050913          	addi	s2,a0,336
    80002932:	02a79363          	bne	a5,a0,80002958 <exit+0x52>
    panic("init exiting");
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	a0250513          	addi	a0,a0,-1534 # 80008338 <digits+0x2f8>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>
      fileclose(f);
    80002946:	00002097          	auipc	ra,0x2
    8000294a:	262080e7          	jalr	610(ra) # 80004ba8 <fileclose>
      p->ofile[fd] = 0;
    8000294e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002952:	04a1                	addi	s1,s1,8
    80002954:	01248563          	beq	s1,s2,8000295e <exit+0x58>
    if(p->ofile[fd]){
    80002958:	6088                	ld	a0,0(s1)
    8000295a:	f575                	bnez	a0,80002946 <exit+0x40>
    8000295c:	bfdd                	j	80002952 <exit+0x4c>
  begin_op();
    8000295e:	00002097          	auipc	ra,0x2
    80002962:	d7e080e7          	jalr	-642(ra) # 800046dc <begin_op>
  iput(p->cwd);
    80002966:	1509b503          	ld	a0,336(s3)
    8000296a:	00001097          	auipc	ra,0x1
    8000296e:	55a080e7          	jalr	1370(ra) # 80003ec4 <iput>
  end_op();
    80002972:	00002097          	auipc	ra,0x2
    80002976:	dea080e7          	jalr	-534(ra) # 8000475c <end_op>
  p->cwd = 0;
    8000297a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000297e:	0000f497          	auipc	s1,0xf
    80002982:	e7a48493          	addi	s1,s1,-390 # 800117f8 <wait_lock>
    80002986:	8526                	mv	a0,s1
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	25c080e7          	jalr	604(ra) # 80000be4 <acquire>
  reparent(p);
    80002990:	854e                	mv	a0,s3
    80002992:	00000097          	auipc	ra,0x0
    80002996:	f1a080e7          	jalr	-230(ra) # 800028ac <reparent>
  wakeup(p->parent);
    8000299a:	0389b503          	ld	a0,56(s3)
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	e22080e7          	jalr	-478(ra) # 800027c0 <wakeup>
  acquire(&p->lock);
    800029a6:	854e                	mv	a0,s3
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	23c080e7          	jalr	572(ra) # 80000be4 <acquire>
  p->xstate = status;
    800029b0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800029b4:	4795                	li	a5,5
    800029b6:	00f9ac23          	sw	a5,24(s3)
  append(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    800029ba:	85ce                	mv	a1,s3
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	f8450513          	addi	a0,a0,-124 # 80008940 <zombie_list>
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	08c080e7          	jalr	140(ra) # 80001a50 <append>
  release(&wait_lock);
    800029cc:	8526                	mv	a0,s1
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	2ca080e7          	jalr	714(ra) # 80000c98 <release>
  sched();
    800029d6:	00000097          	auipc	ra,0x0
    800029da:	b0a080e7          	jalr	-1270(ra) # 800024e0 <sched>
  panic("zombie exit");
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	96a50513          	addi	a0,a0,-1686 # 80008348 <digits+0x308>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	b58080e7          	jalr	-1192(ra) # 8000053e <panic>

00000000800029ee <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800029ee:	7179                	addi	sp,sp,-48
    800029f0:	f406                	sd	ra,40(sp)
    800029f2:	f022                	sd	s0,32(sp)
    800029f4:	ec26                	sd	s1,24(sp)
    800029f6:	e84a                	sd	s2,16(sp)
    800029f8:	e44e                	sd	s3,8(sp)
    800029fa:	1800                	addi	s0,sp,48
    800029fc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800029fe:	0000f497          	auipc	s1,0xf
    80002a02:	e1248493          	addi	s1,s1,-494 # 80011810 <proc>
    80002a06:	00015997          	auipc	s3,0x15
    80002a0a:	20a98993          	addi	s3,s3,522 # 80017c10 <tickslock>
    acquire(&p->lock);
    80002a0e:	8526                	mv	a0,s1
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	1d4080e7          	jalr	468(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002a18:	589c                	lw	a5,48(s1)
    80002a1a:	01278d63          	beq	a5,s2,80002a34 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a1e:	8526                	mv	a0,s1
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	278080e7          	jalr	632(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a28:	19048493          	addi	s1,s1,400
    80002a2c:	ff3491e3          	bne	s1,s3,80002a0e <kill+0x20>
  }
  return -1;
    80002a30:	557d                	li	a0,-1
    80002a32:	a829                	j	80002a4c <kill+0x5e>
      p->killed = 1;
    80002a34:	4785                	li	a5,1
    80002a36:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002a38:	4c98                	lw	a4,24(s1)
    80002a3a:	4789                	li	a5,2
    80002a3c:	00f70f63          	beq	a4,a5,80002a5a <kill+0x6c>
      release(&p->lock);
    80002a40:	8526                	mv	a0,s1
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	256080e7          	jalr	598(ra) # 80000c98 <release>
      return 0;
    80002a4a:	4501                	li	a0,0
}
    80002a4c:	70a2                	ld	ra,40(sp)
    80002a4e:	7402                	ld	s0,32(sp)
    80002a50:	64e2                	ld	s1,24(sp)
    80002a52:	6942                	ld	s2,16(sp)
    80002a54:	69a2                	ld	s3,8(sp)
    80002a56:	6145                	addi	sp,sp,48
    80002a58:	8082                	ret
        p->state = RUNNABLE;
    80002a5a:	478d                	li	a5,3
    80002a5c:	cc9c                	sw	a5,24(s1)
    80002a5e:	b7cd                	j	80002a40 <kill+0x52>

0000000080002a60 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a60:	7179                	addi	sp,sp,-48
    80002a62:	f406                	sd	ra,40(sp)
    80002a64:	f022                	sd	s0,32(sp)
    80002a66:	ec26                	sd	s1,24(sp)
    80002a68:	e84a                	sd	s2,16(sp)
    80002a6a:	e44e                	sd	s3,8(sp)
    80002a6c:	e052                	sd	s4,0(sp)
    80002a6e:	1800                	addi	s0,sp,48
    80002a70:	84aa                	mv	s1,a0
    80002a72:	892e                	mv	s2,a1
    80002a74:	89b2                	mv	s3,a2
    80002a76:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	396080e7          	jalr	918(ra) # 80001e0e <myproc>
  if(user_dst){
    80002a80:	c08d                	beqz	s1,80002aa2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002a82:	86d2                	mv	a3,s4
    80002a84:	864e                	mv	a2,s3
    80002a86:	85ca                	mv	a1,s2
    80002a88:	6928                	ld	a0,80(a0)
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	be8080e7          	jalr	-1048(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a92:	70a2                	ld	ra,40(sp)
    80002a94:	7402                	ld	s0,32(sp)
    80002a96:	64e2                	ld	s1,24(sp)
    80002a98:	6942                	ld	s2,16(sp)
    80002a9a:	69a2                	ld	s3,8(sp)
    80002a9c:	6a02                	ld	s4,0(sp)
    80002a9e:	6145                	addi	sp,sp,48
    80002aa0:	8082                	ret
    memmove((char *)dst, src, len);
    80002aa2:	000a061b          	sext.w	a2,s4
    80002aa6:	85ce                	mv	a1,s3
    80002aa8:	854a                	mv	a0,s2
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	296080e7          	jalr	662(ra) # 80000d40 <memmove>
    return 0;
    80002ab2:	8526                	mv	a0,s1
    80002ab4:	bff9                	j	80002a92 <either_copyout+0x32>

0000000080002ab6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002ab6:	7179                	addi	sp,sp,-48
    80002ab8:	f406                	sd	ra,40(sp)
    80002aba:	f022                	sd	s0,32(sp)
    80002abc:	ec26                	sd	s1,24(sp)
    80002abe:	e84a                	sd	s2,16(sp)
    80002ac0:	e44e                	sd	s3,8(sp)
    80002ac2:	e052                	sd	s4,0(sp)
    80002ac4:	1800                	addi	s0,sp,48
    80002ac6:	892a                	mv	s2,a0
    80002ac8:	84ae                	mv	s1,a1
    80002aca:	89b2                	mv	s3,a2
    80002acc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	340080e7          	jalr	832(ra) # 80001e0e <myproc>
  if(user_src){
    80002ad6:	c08d                	beqz	s1,80002af8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002ad8:	86d2                	mv	a3,s4
    80002ada:	864e                	mv	a2,s3
    80002adc:	85ca                	mv	a1,s2
    80002ade:	6928                	ld	a0,80(a0)
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	c1e080e7          	jalr	-994(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002ae8:	70a2                	ld	ra,40(sp)
    80002aea:	7402                	ld	s0,32(sp)
    80002aec:	64e2                	ld	s1,24(sp)
    80002aee:	6942                	ld	s2,16(sp)
    80002af0:	69a2                	ld	s3,8(sp)
    80002af2:	6a02                	ld	s4,0(sp)
    80002af4:	6145                	addi	sp,sp,48
    80002af6:	8082                	ret
    memmove(dst, (char*)src, len);
    80002af8:	000a061b          	sext.w	a2,s4
    80002afc:	85ce                	mv	a1,s3
    80002afe:	854a                	mv	a0,s2
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	240080e7          	jalr	576(ra) # 80000d40 <memmove>
    return 0;
    80002b08:	8526                	mv	a0,s1
    80002b0a:	bff9                	j	80002ae8 <either_copyin+0x32>

0000000080002b0c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002b0c:	715d                	addi	sp,sp,-80
    80002b0e:	e486                	sd	ra,72(sp)
    80002b10:	e0a2                	sd	s0,64(sp)
    80002b12:	fc26                	sd	s1,56(sp)
    80002b14:	f84a                	sd	s2,48(sp)
    80002b16:	f44e                	sd	s3,40(sp)
    80002b18:	f052                	sd	s4,32(sp)
    80002b1a:	ec56                	sd	s5,24(sp)
    80002b1c:	e85a                	sd	s6,16(sp)
    80002b1e:	e45e                	sd	s7,8(sp)
    80002b20:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b22:	00005517          	auipc	a0,0x5
    80002b26:	5a650513          	addi	a0,a0,1446 # 800080c8 <digits+0x88>
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	a5e080e7          	jalr	-1442(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b32:	0000f497          	auipc	s1,0xf
    80002b36:	e3648493          	addi	s1,s1,-458 # 80011968 <proc+0x158>
    80002b3a:	00015917          	auipc	s2,0x15
    80002b3e:	22e90913          	addi	s2,s2,558 # 80017d68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b42:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002b44:	00006997          	auipc	s3,0x6
    80002b48:	81498993          	addi	s3,s3,-2028 # 80008358 <digits+0x318>
    printf("%d %s %s", p->pid, state, p->name);
    80002b4c:	00006a97          	auipc	s5,0x6
    80002b50:	814a8a93          	addi	s5,s5,-2028 # 80008360 <digits+0x320>
    printf("\n");
    80002b54:	00005a17          	auipc	s4,0x5
    80002b58:	574a0a13          	addi	s4,s4,1396 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b5c:	00006b97          	auipc	s7,0x6
    80002b60:	83cb8b93          	addi	s7,s7,-1988 # 80008398 <states.1796>
    80002b64:	a00d                	j	80002b86 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b66:	ed86a583          	lw	a1,-296(a3)
    80002b6a:	8556                	mv	a0,s5
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	a1c080e7          	jalr	-1508(ra) # 80000588 <printf>
    printf("\n");
    80002b74:	8552                	mv	a0,s4
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	a12080e7          	jalr	-1518(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b7e:	19048493          	addi	s1,s1,400
    80002b82:	03248163          	beq	s1,s2,80002ba4 <procdump+0x98>
    if(p->state == UNUSED)
    80002b86:	86a6                	mv	a3,s1
    80002b88:	ec04a783          	lw	a5,-320(s1)
    80002b8c:	dbed                	beqz	a5,80002b7e <procdump+0x72>
      state = "???"; 
    80002b8e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b90:	fcfb6be3          	bltu	s6,a5,80002b66 <procdump+0x5a>
    80002b94:	1782                	slli	a5,a5,0x20
    80002b96:	9381                	srli	a5,a5,0x20
    80002b98:	078e                	slli	a5,a5,0x3
    80002b9a:	97de                	add	a5,a5,s7
    80002b9c:	6390                	ld	a2,0(a5)
    80002b9e:	f661                	bnez	a2,80002b66 <procdump+0x5a>
      state = "???"; 
    80002ba0:	864e                	mv	a2,s3
    80002ba2:	b7d1                	j	80002b66 <procdump+0x5a>
  }
}
    80002ba4:	60a6                	ld	ra,72(sp)
    80002ba6:	6406                	ld	s0,64(sp)
    80002ba8:	74e2                	ld	s1,56(sp)
    80002baa:	7942                	ld	s2,48(sp)
    80002bac:	79a2                	ld	s3,40(sp)
    80002bae:	7a02                	ld	s4,32(sp)
    80002bb0:	6ae2                	ld	s5,24(sp)
    80002bb2:	6b42                	ld	s6,16(sp)
    80002bb4:	6ba2                	ld	s7,8(sp)
    80002bb6:	6161                	addi	sp,sp,80
    80002bb8:	8082                	ret

0000000080002bba <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	e04a                	sd	s2,0(sp)
    80002bc4:	1000                	addi	s0,sp,32
    80002bc6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	246080e7          	jalr	582(ra) # 80001e0e <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002bd0:	0004871b          	sext.w	a4,s1
    80002bd4:	479d                	li	a5,7
    80002bd6:	02e7e963          	bltu	a5,a4,80002c08 <set_cpu+0x4e>
    80002bda:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	008080e7          	jalr	8(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002be4:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002be8:	854a                	mv	a0,s2
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	0ae080e7          	jalr	174(ra) # 80000c98 <release>

    yield();
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	9d0080e7          	jalr	-1584(ra) # 800025c2 <yield>

    return cpu_num;
    80002bfa:	8526                	mv	a0,s1
  }
  return -1;
}
    80002bfc:	60e2                	ld	ra,24(sp)
    80002bfe:	6442                	ld	s0,16(sp)
    80002c00:	64a2                	ld	s1,8(sp)
    80002c02:	6902                	ld	s2,0(sp)
    80002c04:	6105                	addi	sp,sp,32
    80002c06:	8082                	ret
  return -1;
    80002c08:	557d                	li	a0,-1
    80002c0a:	bfcd                	j	80002bfc <set_cpu+0x42>

0000000080002c0c <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002c0c:	1141                	addi	sp,sp,-16
    80002c0e:	e406                	sd	ra,8(sp)
    80002c10:	e022                	sd	s0,0(sp)
    80002c12:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	1fa080e7          	jalr	506(ra) # 80001e0e <myproc>
  return p->last_cpu;
}
    80002c1c:	16852503          	lw	a0,360(a0)
    80002c20:	60a2                	ld	ra,8(sp)
    80002c22:	6402                	ld	s0,0(sp)
    80002c24:	0141                	addi	sp,sp,16
    80002c26:	8082                	ret

0000000080002c28 <min_cpu>:

int
min_cpu(void){
    80002c28:	1141                	addi	sp,sp,-16
    80002c2a:	e422                	sd	s0,8(sp)
    80002c2c:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    80002c2e:	0000e617          	auipc	a2,0xe
    80002c32:	67260613          	addi	a2,a2,1650 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002c36:	0000e797          	auipc	a5,0xe
    80002c3a:	71278793          	addi	a5,a5,1810 # 80011348 <cpus+0xa8>
    80002c3e:	0000f597          	auipc	a1,0xf
    80002c42:	ba258593          	addi	a1,a1,-1118 # 800117e0 <pid_lock>
    80002c46:	a029                	j	80002c50 <min_cpu+0x28>
    80002c48:	0a878793          	addi	a5,a5,168
    80002c4c:	00b78a63          	beq	a5,a1,80002c60 <min_cpu+0x38>
    if (c->proc_cnt < min_cpu->proc_cnt)
    80002c50:	0807a683          	lw	a3,128(a5)
    80002c54:	08062703          	lw	a4,128(a2)
    80002c58:	fee6d8e3          	bge	a3,a4,80002c48 <min_cpu+0x20>
    80002c5c:	863e                	mv	a2,a5
    80002c5e:	b7ed                	j	80002c48 <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002c60:	08462503          	lw	a0,132(a2)
    80002c64:	6422                	ld	s0,8(sp)
    80002c66:	0141                	addi	sp,sp,16
    80002c68:	8082                	ret

0000000080002c6a <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002c6a:	1141                	addi	sp,sp,-16
    80002c6c:	e422                	sd	s0,8(sp)
    80002c6e:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    80002c70:	fff5071b          	addiw	a4,a0,-1
    80002c74:	4799                	li	a5,6
    80002c76:	02e7e063          	bltu	a5,a4,80002c96 <cpu_process_count+0x2c>
    return cpus[cpu_num].proc_cnt;
    80002c7a:	0a800793          	li	a5,168
    80002c7e:	02f50533          	mul	a0,a0,a5
    80002c82:	0000e797          	auipc	a5,0xe
    80002c86:	61e78793          	addi	a5,a5,1566 # 800112a0 <cpus>
    80002c8a:	953e                	add	a0,a0,a5
    80002c8c:	08052503          	lw	a0,128(a0)
  return -1;
}
    80002c90:	6422                	ld	s0,8(sp)
    80002c92:	0141                	addi	sp,sp,16
    80002c94:	8082                	ret
  return -1;
    80002c96:	557d                	li	a0,-1
    80002c98:	bfe5                	j	80002c90 <cpu_process_count+0x26>

0000000080002c9a <steal_process>:




void
steal_process(struct cpu *curr_c){  /*
    80002c9a:	1141                	addi	sp,sp,-16
    80002c9c:	e422                	sd	s0,8(sp)
    80002c9e:	0800                	addi	s0,sp,16
  }
  p = proc[stolen_process];
  append(&c->runnable_list, p);
  p->last_cpu = c->cpu_id;
  increment_cpu_process_count(c); */
    80002ca0:	6422                	ld	s0,8(sp)
    80002ca2:	0141                	addi	sp,sp,16
    80002ca4:	8082                	ret

0000000080002ca6 <swtch>:
    80002ca6:	00153023          	sd	ra,0(a0)
    80002caa:	00253423          	sd	sp,8(a0)
    80002cae:	e900                	sd	s0,16(a0)
    80002cb0:	ed04                	sd	s1,24(a0)
    80002cb2:	03253023          	sd	s2,32(a0)
    80002cb6:	03353423          	sd	s3,40(a0)
    80002cba:	03453823          	sd	s4,48(a0)
    80002cbe:	03553c23          	sd	s5,56(a0)
    80002cc2:	05653023          	sd	s6,64(a0)
    80002cc6:	05753423          	sd	s7,72(a0)
    80002cca:	05853823          	sd	s8,80(a0)
    80002cce:	05953c23          	sd	s9,88(a0)
    80002cd2:	07a53023          	sd	s10,96(a0)
    80002cd6:	07b53423          	sd	s11,104(a0)
    80002cda:	0005b083          	ld	ra,0(a1)
    80002cde:	0085b103          	ld	sp,8(a1)
    80002ce2:	6980                	ld	s0,16(a1)
    80002ce4:	6d84                	ld	s1,24(a1)
    80002ce6:	0205b903          	ld	s2,32(a1)
    80002cea:	0285b983          	ld	s3,40(a1)
    80002cee:	0305ba03          	ld	s4,48(a1)
    80002cf2:	0385ba83          	ld	s5,56(a1)
    80002cf6:	0405bb03          	ld	s6,64(a1)
    80002cfa:	0485bb83          	ld	s7,72(a1)
    80002cfe:	0505bc03          	ld	s8,80(a1)
    80002d02:	0585bc83          	ld	s9,88(a1)
    80002d06:	0605bd03          	ld	s10,96(a1)
    80002d0a:	0685bd83          	ld	s11,104(a1)
    80002d0e:	8082                	ret

0000000080002d10 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002d10:	1141                	addi	sp,sp,-16
    80002d12:	e406                	sd	ra,8(sp)
    80002d14:	e022                	sd	s0,0(sp)
    80002d16:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d18:	00005597          	auipc	a1,0x5
    80002d1c:	6b058593          	addi	a1,a1,1712 # 800083c8 <states.1796+0x30>
    80002d20:	00015517          	auipc	a0,0x15
    80002d24:	ef050513          	addi	a0,a0,-272 # 80017c10 <tickslock>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	e2c080e7          	jalr	-468(ra) # 80000b54 <initlock>
}
    80002d30:	60a2                	ld	ra,8(sp)
    80002d32:	6402                	ld	s0,0(sp)
    80002d34:	0141                	addi	sp,sp,16
    80002d36:	8082                	ret

0000000080002d38 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d38:	1141                	addi	sp,sp,-16
    80002d3a:	e422                	sd	s0,8(sp)
    80002d3c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d3e:	00003797          	auipc	a5,0x3
    80002d42:	48278793          	addi	a5,a5,1154 # 800061c0 <kernelvec>
    80002d46:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d4a:	6422                	ld	s0,8(sp)
    80002d4c:	0141                	addi	sp,sp,16
    80002d4e:	8082                	ret

0000000080002d50 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d50:	1141                	addi	sp,sp,-16
    80002d52:	e406                	sd	ra,8(sp)
    80002d54:	e022                	sd	s0,0(sp)
    80002d56:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	0b6080e7          	jalr	182(ra) # 80001e0e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d64:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d66:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d6a:	00004617          	auipc	a2,0x4
    80002d6e:	29660613          	addi	a2,a2,662 # 80007000 <_trampoline>
    80002d72:	00004697          	auipc	a3,0x4
    80002d76:	28e68693          	addi	a3,a3,654 # 80007000 <_trampoline>
    80002d7a:	8e91                	sub	a3,a3,a2
    80002d7c:	040007b7          	lui	a5,0x4000
    80002d80:	17fd                	addi	a5,a5,-1
    80002d82:	07b2                	slli	a5,a5,0xc
    80002d84:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d86:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d8a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d8c:	180026f3          	csrr	a3,satp
    80002d90:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d92:	6d38                	ld	a4,88(a0)
    80002d94:	6134                	ld	a3,64(a0)
    80002d96:	6585                	lui	a1,0x1
    80002d98:	96ae                	add	a3,a3,a1
    80002d9a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d9c:	6d38                	ld	a4,88(a0)
    80002d9e:	00000697          	auipc	a3,0x0
    80002da2:	13868693          	addi	a3,a3,312 # 80002ed6 <usertrap>
    80002da6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002da8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002daa:	8692                	mv	a3,tp
    80002dac:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dae:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002db2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002db6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dba:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002dbe:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dc0:	6f18                	ld	a4,24(a4)
    80002dc2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002dc6:	692c                	ld	a1,80(a0)
    80002dc8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002dca:	00004717          	auipc	a4,0x4
    80002dce:	2c670713          	addi	a4,a4,710 # 80007090 <userret>
    80002dd2:	8f11                	sub	a4,a4,a2
    80002dd4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002dd6:	577d                	li	a4,-1
    80002dd8:	177e                	slli	a4,a4,0x3f
    80002dda:	8dd9                	or	a1,a1,a4
    80002ddc:	02000537          	lui	a0,0x2000
    80002de0:	157d                	addi	a0,a0,-1
    80002de2:	0536                	slli	a0,a0,0xd
    80002de4:	9782                	jalr	a5
}
    80002de6:	60a2                	ld	ra,8(sp)
    80002de8:	6402                	ld	s0,0(sp)
    80002dea:	0141                	addi	sp,sp,16
    80002dec:	8082                	ret

0000000080002dee <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002dee:	1101                	addi	sp,sp,-32
    80002df0:	ec06                	sd	ra,24(sp)
    80002df2:	e822                	sd	s0,16(sp)
    80002df4:	e426                	sd	s1,8(sp)
    80002df6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002df8:	00015497          	auipc	s1,0x15
    80002dfc:	e1848493          	addi	s1,s1,-488 # 80017c10 <tickslock>
    80002e00:	8526                	mv	a0,s1
    80002e02:	ffffe097          	auipc	ra,0xffffe
    80002e06:	de2080e7          	jalr	-542(ra) # 80000be4 <acquire>
  ticks++;
    80002e0a:	00006517          	auipc	a0,0x6
    80002e0e:	22650513          	addi	a0,a0,550 # 80009030 <ticks>
    80002e12:	411c                	lw	a5,0(a0)
    80002e14:	2785                	addiw	a5,a5,1
    80002e16:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	9a8080e7          	jalr	-1624(ra) # 800027c0 <wakeup>
  release(&tickslock);
    80002e20:	8526                	mv	a0,s1
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	e76080e7          	jalr	-394(ra) # 80000c98 <release>
}
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	e426                	sd	s1,8(sp)
    80002e3c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e3e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e42:	00074d63          	bltz	a4,80002e5c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e46:	57fd                	li	a5,-1
    80002e48:	17fe                	slli	a5,a5,0x3f
    80002e4a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e4c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e4e:	06f70363          	beq	a4,a5,80002eb4 <devintr+0x80>
  }
}
    80002e52:	60e2                	ld	ra,24(sp)
    80002e54:	6442                	ld	s0,16(sp)
    80002e56:	64a2                	ld	s1,8(sp)
    80002e58:	6105                	addi	sp,sp,32
    80002e5a:	8082                	ret
     (scause & 0xff) == 9){
    80002e5c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e60:	46a5                	li	a3,9
    80002e62:	fed792e3          	bne	a5,a3,80002e46 <devintr+0x12>
    int irq = plic_claim();
    80002e66:	00003097          	auipc	ra,0x3
    80002e6a:	462080e7          	jalr	1122(ra) # 800062c8 <plic_claim>
    80002e6e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e70:	47a9                	li	a5,10
    80002e72:	02f50763          	beq	a0,a5,80002ea0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e76:	4785                	li	a5,1
    80002e78:	02f50963          	beq	a0,a5,80002eaa <devintr+0x76>
    return 1;
    80002e7c:	4505                	li	a0,1
    } else if(irq){
    80002e7e:	d8f1                	beqz	s1,80002e52 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e80:	85a6                	mv	a1,s1
    80002e82:	00005517          	auipc	a0,0x5
    80002e86:	54e50513          	addi	a0,a0,1358 # 800083d0 <states.1796+0x38>
    80002e8a:	ffffd097          	auipc	ra,0xffffd
    80002e8e:	6fe080e7          	jalr	1790(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e92:	8526                	mv	a0,s1
    80002e94:	00003097          	auipc	ra,0x3
    80002e98:	458080e7          	jalr	1112(ra) # 800062ec <plic_complete>
    return 1;
    80002e9c:	4505                	li	a0,1
    80002e9e:	bf55                	j	80002e52 <devintr+0x1e>
      uartintr();
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	b08080e7          	jalr	-1272(ra) # 800009a8 <uartintr>
    80002ea8:	b7ed                	j	80002e92 <devintr+0x5e>
      virtio_disk_intr();
    80002eaa:	00004097          	auipc	ra,0x4
    80002eae:	922080e7          	jalr	-1758(ra) # 800067cc <virtio_disk_intr>
    80002eb2:	b7c5                	j	80002e92 <devintr+0x5e>
    if(cpuid() == 0){
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	f28080e7          	jalr	-216(ra) # 80001ddc <cpuid>
    80002ebc:	c901                	beqz	a0,80002ecc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ebe:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ec2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ec4:	14479073          	csrw	sip,a5
    return 2;
    80002ec8:	4509                	li	a0,2
    80002eca:	b761                	j	80002e52 <devintr+0x1e>
      clockintr();
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	f22080e7          	jalr	-222(ra) # 80002dee <clockintr>
    80002ed4:	b7ed                	j	80002ebe <devintr+0x8a>

0000000080002ed6 <usertrap>:
{
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	e426                	sd	s1,8(sp)
    80002ede:	e04a                	sd	s2,0(sp)
    80002ee0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ee2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ee6:	1007f793          	andi	a5,a5,256
    80002eea:	e3ad                	bnez	a5,80002f4c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002eec:	00003797          	auipc	a5,0x3
    80002ef0:	2d478793          	addi	a5,a5,724 # 800061c0 <kernelvec>
    80002ef4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	f16080e7          	jalr	-234(ra) # 80001e0e <myproc>
    80002f00:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f02:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f04:	14102773          	csrr	a4,sepc
    80002f08:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f0a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f0e:	47a1                	li	a5,8
    80002f10:	04f71c63          	bne	a4,a5,80002f68 <usertrap+0x92>
    if(p->killed)
    80002f14:	551c                	lw	a5,40(a0)
    80002f16:	e3b9                	bnez	a5,80002f5c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f18:	6cb8                	ld	a4,88(s1)
    80002f1a:	6f1c                	ld	a5,24(a4)
    80002f1c:	0791                	addi	a5,a5,4
    80002f1e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f28:	10079073          	csrw	sstatus,a5
    syscall();
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	2e0080e7          	jalr	736(ra) # 8000320c <syscall>
  if(p->killed)
    80002f34:	549c                	lw	a5,40(s1)
    80002f36:	ebc1                	bnez	a5,80002fc6 <usertrap+0xf0>
  usertrapret();
    80002f38:	00000097          	auipc	ra,0x0
    80002f3c:	e18080e7          	jalr	-488(ra) # 80002d50 <usertrapret>
}
    80002f40:	60e2                	ld	ra,24(sp)
    80002f42:	6442                	ld	s0,16(sp)
    80002f44:	64a2                	ld	s1,8(sp)
    80002f46:	6902                	ld	s2,0(sp)
    80002f48:	6105                	addi	sp,sp,32
    80002f4a:	8082                	ret
    panic("usertrap: not from user mode");
    80002f4c:	00005517          	auipc	a0,0x5
    80002f50:	4a450513          	addi	a0,a0,1188 # 800083f0 <states.1796+0x58>
    80002f54:	ffffd097          	auipc	ra,0xffffd
    80002f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>
      exit(-1);
    80002f5c:	557d                	li	a0,-1
    80002f5e:	00000097          	auipc	ra,0x0
    80002f62:	9a8080e7          	jalr	-1624(ra) # 80002906 <exit>
    80002f66:	bf4d                	j	80002f18 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	ecc080e7          	jalr	-308(ra) # 80002e34 <devintr>
    80002f70:	892a                	mv	s2,a0
    80002f72:	c501                	beqz	a0,80002f7a <usertrap+0xa4>
  if(p->killed)
    80002f74:	549c                	lw	a5,40(s1)
    80002f76:	c3a1                	beqz	a5,80002fb6 <usertrap+0xe0>
    80002f78:	a815                	j	80002fac <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f7a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f7e:	5890                	lw	a2,48(s1)
    80002f80:	00005517          	auipc	a0,0x5
    80002f84:	49050513          	addi	a0,a0,1168 # 80008410 <states.1796+0x78>
    80002f88:	ffffd097          	auipc	ra,0xffffd
    80002f8c:	600080e7          	jalr	1536(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f94:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	4a850513          	addi	a0,a0,1192 # 80008440 <states.1796+0xa8>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	5e8080e7          	jalr	1512(ra) # 80000588 <printf>
    p->killed = 1;
    80002fa8:	4785                	li	a5,1
    80002faa:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002fac:	557d                	li	a0,-1
    80002fae:	00000097          	auipc	ra,0x0
    80002fb2:	958080e7          	jalr	-1704(ra) # 80002906 <exit>
  if(which_dev == 2)
    80002fb6:	4789                	li	a5,2
    80002fb8:	f8f910e3          	bne	s2,a5,80002f38 <usertrap+0x62>
    yield();
    80002fbc:	fffff097          	auipc	ra,0xfffff
    80002fc0:	606080e7          	jalr	1542(ra) # 800025c2 <yield>
    80002fc4:	bf95                	j	80002f38 <usertrap+0x62>
  int which_dev = 0;
    80002fc6:	4901                	li	s2,0
    80002fc8:	b7d5                	j	80002fac <usertrap+0xd6>

0000000080002fca <kerneltrap>:
{
    80002fca:	7179                	addi	sp,sp,-48
    80002fcc:	f406                	sd	ra,40(sp)
    80002fce:	f022                	sd	s0,32(sp)
    80002fd0:	ec26                	sd	s1,24(sp)
    80002fd2:	e84a                	sd	s2,16(sp)
    80002fd4:	e44e                	sd	s3,8(sp)
    80002fd6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fd8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fdc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fe0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fe4:	1004f793          	andi	a5,s1,256
    80002fe8:	cb85                	beqz	a5,80003018 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fee:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ff0:	ef85                	bnez	a5,80003028 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	e42080e7          	jalr	-446(ra) # 80002e34 <devintr>
    80002ffa:	cd1d                	beqz	a0,80003038 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ffc:	4789                	li	a5,2
    80002ffe:	06f50a63          	beq	a0,a5,80003072 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003002:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003006:	10049073          	csrw	sstatus,s1
}
    8000300a:	70a2                	ld	ra,40(sp)
    8000300c:	7402                	ld	s0,32(sp)
    8000300e:	64e2                	ld	s1,24(sp)
    80003010:	6942                	ld	s2,16(sp)
    80003012:	69a2                	ld	s3,8(sp)
    80003014:	6145                	addi	sp,sp,48
    80003016:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003018:	00005517          	auipc	a0,0x5
    8000301c:	44850513          	addi	a0,a0,1096 # 80008460 <states.1796+0xc8>
    80003020:	ffffd097          	auipc	ra,0xffffd
    80003024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003028:	00005517          	auipc	a0,0x5
    8000302c:	46050513          	addi	a0,a0,1120 # 80008488 <states.1796+0xf0>
    80003030:	ffffd097          	auipc	ra,0xffffd
    80003034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003038:	85ce                	mv	a1,s3
    8000303a:	00005517          	auipc	a0,0x5
    8000303e:	46e50513          	addi	a0,a0,1134 # 800084a8 <states.1796+0x110>
    80003042:	ffffd097          	auipc	ra,0xffffd
    80003046:	546080e7          	jalr	1350(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000304a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000304e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003052:	00005517          	auipc	a0,0x5
    80003056:	46650513          	addi	a0,a0,1126 # 800084b8 <states.1796+0x120>
    8000305a:	ffffd097          	auipc	ra,0xffffd
    8000305e:	52e080e7          	jalr	1326(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003062:	00005517          	auipc	a0,0x5
    80003066:	46e50513          	addi	a0,a0,1134 # 800084d0 <states.1796+0x138>
    8000306a:	ffffd097          	auipc	ra,0xffffd
    8000306e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	d9c080e7          	jalr	-612(ra) # 80001e0e <myproc>
    8000307a:	d541                	beqz	a0,80003002 <kerneltrap+0x38>
    8000307c:	fffff097          	auipc	ra,0xfffff
    80003080:	d92080e7          	jalr	-622(ra) # 80001e0e <myproc>
    80003084:	4d18                	lw	a4,24(a0)
    80003086:	4791                	li	a5,4
    80003088:	f6f71de3          	bne	a4,a5,80003002 <kerneltrap+0x38>
    yield();
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	536080e7          	jalr	1334(ra) # 800025c2 <yield>
    80003094:	b7bd                	j	80003002 <kerneltrap+0x38>

0000000080003096 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	1000                	addi	s0,sp,32
    800030a0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030a2:	fffff097          	auipc	ra,0xfffff
    800030a6:	d6c080e7          	jalr	-660(ra) # 80001e0e <myproc>
  switch (n) {
    800030aa:	4795                	li	a5,5
    800030ac:	0497e163          	bltu	a5,s1,800030ee <argraw+0x58>
    800030b0:	048a                	slli	s1,s1,0x2
    800030b2:	00005717          	auipc	a4,0x5
    800030b6:	45670713          	addi	a4,a4,1110 # 80008508 <states.1796+0x170>
    800030ba:	94ba                	add	s1,s1,a4
    800030bc:	409c                	lw	a5,0(s1)
    800030be:	97ba                	add	a5,a5,a4
    800030c0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030c2:	6d3c                	ld	a5,88(a0)
    800030c4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030c6:	60e2                	ld	ra,24(sp)
    800030c8:	6442                	ld	s0,16(sp)
    800030ca:	64a2                	ld	s1,8(sp)
    800030cc:	6105                	addi	sp,sp,32
    800030ce:	8082                	ret
    return p->trapframe->a1;
    800030d0:	6d3c                	ld	a5,88(a0)
    800030d2:	7fa8                	ld	a0,120(a5)
    800030d4:	bfcd                	j	800030c6 <argraw+0x30>
    return p->trapframe->a2;
    800030d6:	6d3c                	ld	a5,88(a0)
    800030d8:	63c8                	ld	a0,128(a5)
    800030da:	b7f5                	j	800030c6 <argraw+0x30>
    return p->trapframe->a3;
    800030dc:	6d3c                	ld	a5,88(a0)
    800030de:	67c8                	ld	a0,136(a5)
    800030e0:	b7dd                	j	800030c6 <argraw+0x30>
    return p->trapframe->a4;
    800030e2:	6d3c                	ld	a5,88(a0)
    800030e4:	6bc8                	ld	a0,144(a5)
    800030e6:	b7c5                	j	800030c6 <argraw+0x30>
    return p->trapframe->a5;
    800030e8:	6d3c                	ld	a5,88(a0)
    800030ea:	6fc8                	ld	a0,152(a5)
    800030ec:	bfe9                	j	800030c6 <argraw+0x30>
  panic("argraw");
    800030ee:	00005517          	auipc	a0,0x5
    800030f2:	3f250513          	addi	a0,a0,1010 # 800084e0 <states.1796+0x148>
    800030f6:	ffffd097          	auipc	ra,0xffffd
    800030fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>

00000000800030fe <fetchaddr>:
{
    800030fe:	1101                	addi	sp,sp,-32
    80003100:	ec06                	sd	ra,24(sp)
    80003102:	e822                	sd	s0,16(sp)
    80003104:	e426                	sd	s1,8(sp)
    80003106:	e04a                	sd	s2,0(sp)
    80003108:	1000                	addi	s0,sp,32
    8000310a:	84aa                	mv	s1,a0
    8000310c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000310e:	fffff097          	auipc	ra,0xfffff
    80003112:	d00080e7          	jalr	-768(ra) # 80001e0e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003116:	653c                	ld	a5,72(a0)
    80003118:	02f4f863          	bgeu	s1,a5,80003148 <fetchaddr+0x4a>
    8000311c:	00848713          	addi	a4,s1,8
    80003120:	02e7e663          	bltu	a5,a4,8000314c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003124:	46a1                	li	a3,8
    80003126:	8626                	mv	a2,s1
    80003128:	85ca                	mv	a1,s2
    8000312a:	6928                	ld	a0,80(a0)
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	5d2080e7          	jalr	1490(ra) # 800016fe <copyin>
    80003134:	00a03533          	snez	a0,a0
    80003138:	40a00533          	neg	a0,a0
}
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	64a2                	ld	s1,8(sp)
    80003142:	6902                	ld	s2,0(sp)
    80003144:	6105                	addi	sp,sp,32
    80003146:	8082                	ret
    return -1;
    80003148:	557d                	li	a0,-1
    8000314a:	bfcd                	j	8000313c <fetchaddr+0x3e>
    8000314c:	557d                	li	a0,-1
    8000314e:	b7fd                	j	8000313c <fetchaddr+0x3e>

0000000080003150 <fetchstr>:
{
    80003150:	7179                	addi	sp,sp,-48
    80003152:	f406                	sd	ra,40(sp)
    80003154:	f022                	sd	s0,32(sp)
    80003156:	ec26                	sd	s1,24(sp)
    80003158:	e84a                	sd	s2,16(sp)
    8000315a:	e44e                	sd	s3,8(sp)
    8000315c:	1800                	addi	s0,sp,48
    8000315e:	892a                	mv	s2,a0
    80003160:	84ae                	mv	s1,a1
    80003162:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	caa080e7          	jalr	-854(ra) # 80001e0e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000316c:	86ce                	mv	a3,s3
    8000316e:	864a                	mv	a2,s2
    80003170:	85a6                	mv	a1,s1
    80003172:	6928                	ld	a0,80(a0)
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	616080e7          	jalr	1558(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000317c:	00054763          	bltz	a0,8000318a <fetchstr+0x3a>
  return strlen(buf);
    80003180:	8526                	mv	a0,s1
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	ce2080e7          	jalr	-798(ra) # 80000e64 <strlen>
}
    8000318a:	70a2                	ld	ra,40(sp)
    8000318c:	7402                	ld	s0,32(sp)
    8000318e:	64e2                	ld	s1,24(sp)
    80003190:	6942                	ld	s2,16(sp)
    80003192:	69a2                	ld	s3,8(sp)
    80003194:	6145                	addi	sp,sp,48
    80003196:	8082                	ret

0000000080003198 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	1000                	addi	s0,sp,32
    800031a2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031a4:	00000097          	auipc	ra,0x0
    800031a8:	ef2080e7          	jalr	-270(ra) # 80003096 <argraw>
    800031ac:	c088                	sw	a0,0(s1)
  return 0;
}
    800031ae:	4501                	li	a0,0
    800031b0:	60e2                	ld	ra,24(sp)
    800031b2:	6442                	ld	s0,16(sp)
    800031b4:	64a2                	ld	s1,8(sp)
    800031b6:	6105                	addi	sp,sp,32
    800031b8:	8082                	ret

00000000800031ba <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800031ba:	1101                	addi	sp,sp,-32
    800031bc:	ec06                	sd	ra,24(sp)
    800031be:	e822                	sd	s0,16(sp)
    800031c0:	e426                	sd	s1,8(sp)
    800031c2:	1000                	addi	s0,sp,32
    800031c4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	ed0080e7          	jalr	-304(ra) # 80003096 <argraw>
    800031ce:	e088                	sd	a0,0(s1)
  return 0;
}
    800031d0:	4501                	li	a0,0
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	e04a                	sd	s2,0(sp)
    800031e6:	1000                	addi	s0,sp,32
    800031e8:	84ae                	mv	s1,a1
    800031ea:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	eaa080e7          	jalr	-342(ra) # 80003096 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031f4:	864a                	mv	a2,s2
    800031f6:	85a6                	mv	a1,s1
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	f58080e7          	jalr	-168(ra) # 80003150 <fetchstr>
}
    80003200:	60e2                	ld	ra,24(sp)
    80003202:	6442                	ld	s0,16(sp)
    80003204:	64a2                	ld	s1,8(sp)
    80003206:	6902                	ld	s2,0(sp)
    80003208:	6105                	addi	sp,sp,32
    8000320a:	8082                	ret

000000008000320c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000320c:	1101                	addi	sp,sp,-32
    8000320e:	ec06                	sd	ra,24(sp)
    80003210:	e822                	sd	s0,16(sp)
    80003212:	e426                	sd	s1,8(sp)
    80003214:	e04a                	sd	s2,0(sp)
    80003216:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	bf6080e7          	jalr	-1034(ra) # 80001e0e <myproc>
    80003220:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003222:	05853903          	ld	s2,88(a0)
    80003226:	0a893783          	ld	a5,168(s2)
    8000322a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000322e:	37fd                	addiw	a5,a5,-1
    80003230:	4751                	li	a4,20
    80003232:	00f76f63          	bltu	a4,a5,80003250 <syscall+0x44>
    80003236:	00369713          	slli	a4,a3,0x3
    8000323a:	00005797          	auipc	a5,0x5
    8000323e:	2e678793          	addi	a5,a5,742 # 80008520 <syscalls>
    80003242:	97ba                	add	a5,a5,a4
    80003244:	639c                	ld	a5,0(a5)
    80003246:	c789                	beqz	a5,80003250 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003248:	9782                	jalr	a5
    8000324a:	06a93823          	sd	a0,112(s2)
    8000324e:	a839                	j	8000326c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003250:	15848613          	addi	a2,s1,344
    80003254:	588c                	lw	a1,48(s1)
    80003256:	00005517          	auipc	a0,0x5
    8000325a:	29250513          	addi	a0,a0,658 # 800084e8 <states.1796+0x150>
    8000325e:	ffffd097          	auipc	ra,0xffffd
    80003262:	32a080e7          	jalr	810(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003266:	6cbc                	ld	a5,88(s1)
    80003268:	577d                	li	a4,-1
    8000326a:	fbb8                	sd	a4,112(a5)
  }
}
    8000326c:	60e2                	ld	ra,24(sp)
    8000326e:	6442                	ld	s0,16(sp)
    80003270:	64a2                	ld	s1,8(sp)
    80003272:	6902                	ld	s2,0(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret

0000000080003278 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003278:	1101                	addi	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003280:	fec40593          	addi	a1,s0,-20
    80003284:	4501                	li	a0,0
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	f12080e7          	jalr	-238(ra) # 80003198 <argint>
    return -1;
    8000328e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003290:	00054963          	bltz	a0,800032a2 <sys_exit+0x2a>
  exit(n);
    80003294:	fec42503          	lw	a0,-20(s0)
    80003298:	fffff097          	auipc	ra,0xfffff
    8000329c:	66e080e7          	jalr	1646(ra) # 80002906 <exit>
  return 0;  // not reached
    800032a0:	4781                	li	a5,0
}
    800032a2:	853e                	mv	a0,a5
    800032a4:	60e2                	ld	ra,24(sp)
    800032a6:	6442                	ld	s0,16(sp)
    800032a8:	6105                	addi	sp,sp,32
    800032aa:	8082                	ret

00000000800032ac <sys_getpid>:

uint64
sys_getpid(void)
{
    800032ac:	1141                	addi	sp,sp,-16
    800032ae:	e406                	sd	ra,8(sp)
    800032b0:	e022                	sd	s0,0(sp)
    800032b2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032b4:	fffff097          	auipc	ra,0xfffff
    800032b8:	b5a080e7          	jalr	-1190(ra) # 80001e0e <myproc>
}
    800032bc:	5908                	lw	a0,48(a0)
    800032be:	60a2                	ld	ra,8(sp)
    800032c0:	6402                	ld	s0,0(sp)
    800032c2:	0141                	addi	sp,sp,16
    800032c4:	8082                	ret

00000000800032c6 <sys_fork>:

uint64
sys_fork(void)
{
    800032c6:	1141                	addi	sp,sp,-16
    800032c8:	e406                	sd	ra,8(sp)
    800032ca:	e022                	sd	s0,0(sp)
    800032cc:	0800                	addi	s0,sp,16
  return fork();
    800032ce:	fffff097          	auipc	ra,0xfffff
    800032d2:	fd4080e7          	jalr	-44(ra) # 800022a2 <fork>
}
    800032d6:	60a2                	ld	ra,8(sp)
    800032d8:	6402                	ld	s0,0(sp)
    800032da:	0141                	addi	sp,sp,16
    800032dc:	8082                	ret

00000000800032de <sys_wait>:

uint64
sys_wait(void)
{
    800032de:	1101                	addi	sp,sp,-32
    800032e0:	ec06                	sd	ra,24(sp)
    800032e2:	e822                	sd	s0,16(sp)
    800032e4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800032e6:	fe840593          	addi	a1,s0,-24
    800032ea:	4501                	li	a0,0
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	ece080e7          	jalr	-306(ra) # 800031ba <argaddr>
    800032f4:	87aa                	mv	a5,a0
    return -1;
    800032f6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800032f8:	0007c863          	bltz	a5,80003308 <sys_wait+0x2a>
  return wait(p);
    800032fc:	fe843503          	ld	a0,-24(s0)
    80003300:	fffff097          	auipc	ra,0xfffff
    80003304:	398080e7          	jalr	920(ra) # 80002698 <wait>
}
    80003308:	60e2                	ld	ra,24(sp)
    8000330a:	6442                	ld	s0,16(sp)
    8000330c:	6105                	addi	sp,sp,32
    8000330e:	8082                	ret

0000000080003310 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003310:	7179                	addi	sp,sp,-48
    80003312:	f406                	sd	ra,40(sp)
    80003314:	f022                	sd	s0,32(sp)
    80003316:	ec26                	sd	s1,24(sp)
    80003318:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000331a:	fdc40593          	addi	a1,s0,-36
    8000331e:	4501                	li	a0,0
    80003320:	00000097          	auipc	ra,0x0
    80003324:	e78080e7          	jalr	-392(ra) # 80003198 <argint>
    80003328:	87aa                	mv	a5,a0
    return -1;
    8000332a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000332c:	0207c063          	bltz	a5,8000334c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003330:	fffff097          	auipc	ra,0xfffff
    80003334:	ade080e7          	jalr	-1314(ra) # 80001e0e <myproc>
    80003338:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000333a:	fdc42503          	lw	a0,-36(s0)
    8000333e:	fffff097          	auipc	ra,0xfffff
    80003342:	ef0080e7          	jalr	-272(ra) # 8000222e <growproc>
    80003346:	00054863          	bltz	a0,80003356 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000334a:	8526                	mv	a0,s1
}
    8000334c:	70a2                	ld	ra,40(sp)
    8000334e:	7402                	ld	s0,32(sp)
    80003350:	64e2                	ld	s1,24(sp)
    80003352:	6145                	addi	sp,sp,48
    80003354:	8082                	ret
    return -1;
    80003356:	557d                	li	a0,-1
    80003358:	bfd5                	j	8000334c <sys_sbrk+0x3c>

000000008000335a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000335a:	7139                	addi	sp,sp,-64
    8000335c:	fc06                	sd	ra,56(sp)
    8000335e:	f822                	sd	s0,48(sp)
    80003360:	f426                	sd	s1,40(sp)
    80003362:	f04a                	sd	s2,32(sp)
    80003364:	ec4e                	sd	s3,24(sp)
    80003366:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003368:	fcc40593          	addi	a1,s0,-52
    8000336c:	4501                	li	a0,0
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	e2a080e7          	jalr	-470(ra) # 80003198 <argint>
    return -1;
    80003376:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003378:	06054563          	bltz	a0,800033e2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000337c:	00015517          	auipc	a0,0x15
    80003380:	89450513          	addi	a0,a0,-1900 # 80017c10 <tickslock>
    80003384:	ffffe097          	auipc	ra,0xffffe
    80003388:	860080e7          	jalr	-1952(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000338c:	00006917          	auipc	s2,0x6
    80003390:	ca492903          	lw	s2,-860(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003394:	fcc42783          	lw	a5,-52(s0)
    80003398:	cf85                	beqz	a5,800033d0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000339a:	00015997          	auipc	s3,0x15
    8000339e:	87698993          	addi	s3,s3,-1930 # 80017c10 <tickslock>
    800033a2:	00006497          	auipc	s1,0x6
    800033a6:	c8e48493          	addi	s1,s1,-882 # 80009030 <ticks>
    if(myproc()->killed){
    800033aa:	fffff097          	auipc	ra,0xfffff
    800033ae:	a64080e7          	jalr	-1436(ra) # 80001e0e <myproc>
    800033b2:	551c                	lw	a5,40(a0)
    800033b4:	ef9d                	bnez	a5,800033f2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800033b6:	85ce                	mv	a1,s3
    800033b8:	8526                	mv	a0,s1
    800033ba:	fffff097          	auipc	ra,0xfffff
    800033be:	268080e7          	jalr	616(ra) # 80002622 <sleep>
  while(ticks - ticks0 < n){
    800033c2:	409c                	lw	a5,0(s1)
    800033c4:	412787bb          	subw	a5,a5,s2
    800033c8:	fcc42703          	lw	a4,-52(s0)
    800033cc:	fce7efe3          	bltu	a5,a4,800033aa <sys_sleep+0x50>
  }
  release(&tickslock);
    800033d0:	00015517          	auipc	a0,0x15
    800033d4:	84050513          	addi	a0,a0,-1984 # 80017c10 <tickslock>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
  return 0;
    800033e0:	4781                	li	a5,0
}
    800033e2:	853e                	mv	a0,a5
    800033e4:	70e2                	ld	ra,56(sp)
    800033e6:	7442                	ld	s0,48(sp)
    800033e8:	74a2                	ld	s1,40(sp)
    800033ea:	7902                	ld	s2,32(sp)
    800033ec:	69e2                	ld	s3,24(sp)
    800033ee:	6121                	addi	sp,sp,64
    800033f0:	8082                	ret
      release(&tickslock);
    800033f2:	00015517          	auipc	a0,0x15
    800033f6:	81e50513          	addi	a0,a0,-2018 # 80017c10 <tickslock>
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
      return -1;
    80003402:	57fd                	li	a5,-1
    80003404:	bff9                	j	800033e2 <sys_sleep+0x88>

0000000080003406 <sys_kill>:

uint64
sys_kill(void)
{
    80003406:	1101                	addi	sp,sp,-32
    80003408:	ec06                	sd	ra,24(sp)
    8000340a:	e822                	sd	s0,16(sp)
    8000340c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000340e:	fec40593          	addi	a1,s0,-20
    80003412:	4501                	li	a0,0
    80003414:	00000097          	auipc	ra,0x0
    80003418:	d84080e7          	jalr	-636(ra) # 80003198 <argint>
    8000341c:	87aa                	mv	a5,a0
    return -1;
    8000341e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003420:	0007c863          	bltz	a5,80003430 <sys_kill+0x2a>
  return kill(pid);
    80003424:	fec42503          	lw	a0,-20(s0)
    80003428:	fffff097          	auipc	ra,0xfffff
    8000342c:	5c6080e7          	jalr	1478(ra) # 800029ee <kill>
}
    80003430:	60e2                	ld	ra,24(sp)
    80003432:	6442                	ld	s0,16(sp)
    80003434:	6105                	addi	sp,sp,32
    80003436:	8082                	ret

0000000080003438 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003438:	1101                	addi	sp,sp,-32
    8000343a:	ec06                	sd	ra,24(sp)
    8000343c:	e822                	sd	s0,16(sp)
    8000343e:	e426                	sd	s1,8(sp)
    80003440:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003442:	00014517          	auipc	a0,0x14
    80003446:	7ce50513          	addi	a0,a0,1998 # 80017c10 <tickslock>
    8000344a:	ffffd097          	auipc	ra,0xffffd
    8000344e:	79a080e7          	jalr	1946(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003452:	00006497          	auipc	s1,0x6
    80003456:	bde4a483          	lw	s1,-1058(s1) # 80009030 <ticks>
  release(&tickslock);
    8000345a:	00014517          	auipc	a0,0x14
    8000345e:	7b650513          	addi	a0,a0,1974 # 80017c10 <tickslock>
    80003462:	ffffe097          	auipc	ra,0xffffe
    80003466:	836080e7          	jalr	-1994(ra) # 80000c98 <release>
  return xticks;
}
    8000346a:	02049513          	slli	a0,s1,0x20
    8000346e:	9101                	srli	a0,a0,0x20
    80003470:	60e2                	ld	ra,24(sp)
    80003472:	6442                	ld	s0,16(sp)
    80003474:	64a2                	ld	s1,8(sp)
    80003476:	6105                	addi	sp,sp,32
    80003478:	8082                	ret

000000008000347a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000347a:	7179                	addi	sp,sp,-48
    8000347c:	f406                	sd	ra,40(sp)
    8000347e:	f022                	sd	s0,32(sp)
    80003480:	ec26                	sd	s1,24(sp)
    80003482:	e84a                	sd	s2,16(sp)
    80003484:	e44e                	sd	s3,8(sp)
    80003486:	e052                	sd	s4,0(sp)
    80003488:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000348a:	00005597          	auipc	a1,0x5
    8000348e:	14658593          	addi	a1,a1,326 # 800085d0 <syscalls+0xb0>
    80003492:	00014517          	auipc	a0,0x14
    80003496:	79650513          	addi	a0,a0,1942 # 80017c28 <bcache>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	6ba080e7          	jalr	1722(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034a2:	0001c797          	auipc	a5,0x1c
    800034a6:	78678793          	addi	a5,a5,1926 # 8001fc28 <bcache+0x8000>
    800034aa:	0001d717          	auipc	a4,0x1d
    800034ae:	9e670713          	addi	a4,a4,-1562 # 8001fe90 <bcache+0x8268>
    800034b2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034b6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ba:	00014497          	auipc	s1,0x14
    800034be:	78648493          	addi	s1,s1,1926 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    800034c2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034c4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034c6:	00005a17          	auipc	s4,0x5
    800034ca:	112a0a13          	addi	s4,s4,274 # 800085d8 <syscalls+0xb8>
    b->next = bcache.head.next;
    800034ce:	2b893783          	ld	a5,696(s2)
    800034d2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034d4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034d8:	85d2                	mv	a1,s4
    800034da:	01048513          	addi	a0,s1,16
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	4bc080e7          	jalr	1212(ra) # 8000499a <initsleeplock>
    bcache.head.next->prev = b;
    800034e6:	2b893783          	ld	a5,696(s2)
    800034ea:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034ec:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f0:	45848493          	addi	s1,s1,1112
    800034f4:	fd349de3          	bne	s1,s3,800034ce <binit+0x54>
  }
}
    800034f8:	70a2                	ld	ra,40(sp)
    800034fa:	7402                	ld	s0,32(sp)
    800034fc:	64e2                	ld	s1,24(sp)
    800034fe:	6942                	ld	s2,16(sp)
    80003500:	69a2                	ld	s3,8(sp)
    80003502:	6a02                	ld	s4,0(sp)
    80003504:	6145                	addi	sp,sp,48
    80003506:	8082                	ret

0000000080003508 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003508:	7179                	addi	sp,sp,-48
    8000350a:	f406                	sd	ra,40(sp)
    8000350c:	f022                	sd	s0,32(sp)
    8000350e:	ec26                	sd	s1,24(sp)
    80003510:	e84a                	sd	s2,16(sp)
    80003512:	e44e                	sd	s3,8(sp)
    80003514:	1800                	addi	s0,sp,48
    80003516:	89aa                	mv	s3,a0
    80003518:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000351a:	00014517          	auipc	a0,0x14
    8000351e:	70e50513          	addi	a0,a0,1806 # 80017c28 <bcache>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	6c2080e7          	jalr	1730(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000352a:	0001d497          	auipc	s1,0x1d
    8000352e:	9b64b483          	ld	s1,-1610(s1) # 8001fee0 <bcache+0x82b8>
    80003532:	0001d797          	auipc	a5,0x1d
    80003536:	95e78793          	addi	a5,a5,-1698 # 8001fe90 <bcache+0x8268>
    8000353a:	02f48f63          	beq	s1,a5,80003578 <bread+0x70>
    8000353e:	873e                	mv	a4,a5
    80003540:	a021                	j	80003548 <bread+0x40>
    80003542:	68a4                	ld	s1,80(s1)
    80003544:	02e48a63          	beq	s1,a4,80003578 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003548:	449c                	lw	a5,8(s1)
    8000354a:	ff379ce3          	bne	a5,s3,80003542 <bread+0x3a>
    8000354e:	44dc                	lw	a5,12(s1)
    80003550:	ff2799e3          	bne	a5,s2,80003542 <bread+0x3a>
      b->refcnt++;
    80003554:	40bc                	lw	a5,64(s1)
    80003556:	2785                	addiw	a5,a5,1
    80003558:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000355a:	00014517          	auipc	a0,0x14
    8000355e:	6ce50513          	addi	a0,a0,1742 # 80017c28 <bcache>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	736080e7          	jalr	1846(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000356a:	01048513          	addi	a0,s1,16
    8000356e:	00001097          	auipc	ra,0x1
    80003572:	466080e7          	jalr	1126(ra) # 800049d4 <acquiresleep>
      return b;
    80003576:	a8b9                	j	800035d4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003578:	0001d497          	auipc	s1,0x1d
    8000357c:	9604b483          	ld	s1,-1696(s1) # 8001fed8 <bcache+0x82b0>
    80003580:	0001d797          	auipc	a5,0x1d
    80003584:	91078793          	addi	a5,a5,-1776 # 8001fe90 <bcache+0x8268>
    80003588:	00f48863          	beq	s1,a5,80003598 <bread+0x90>
    8000358c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000358e:	40bc                	lw	a5,64(s1)
    80003590:	cf81                	beqz	a5,800035a8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003592:	64a4                	ld	s1,72(s1)
    80003594:	fee49de3          	bne	s1,a4,8000358e <bread+0x86>
  panic("bget: no buffers");
    80003598:	00005517          	auipc	a0,0x5
    8000359c:	04850513          	addi	a0,a0,72 # 800085e0 <syscalls+0xc0>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	f9e080e7          	jalr	-98(ra) # 8000053e <panic>
      b->dev = dev;
    800035a8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035ac:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035b0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035b4:	4785                	li	a5,1
    800035b6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035b8:	00014517          	auipc	a0,0x14
    800035bc:	67050513          	addi	a0,a0,1648 # 80017c28 <bcache>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	6d8080e7          	jalr	1752(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800035c8:	01048513          	addi	a0,s1,16
    800035cc:	00001097          	auipc	ra,0x1
    800035d0:	408080e7          	jalr	1032(ra) # 800049d4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035d4:	409c                	lw	a5,0(s1)
    800035d6:	cb89                	beqz	a5,800035e8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035d8:	8526                	mv	a0,s1
    800035da:	70a2                	ld	ra,40(sp)
    800035dc:	7402                	ld	s0,32(sp)
    800035de:	64e2                	ld	s1,24(sp)
    800035e0:	6942                	ld	s2,16(sp)
    800035e2:	69a2                	ld	s3,8(sp)
    800035e4:	6145                	addi	sp,sp,48
    800035e6:	8082                	ret
    virtio_disk_rw(b, 0);
    800035e8:	4581                	li	a1,0
    800035ea:	8526                	mv	a0,s1
    800035ec:	00003097          	auipc	ra,0x3
    800035f0:	f0a080e7          	jalr	-246(ra) # 800064f6 <virtio_disk_rw>
    b->valid = 1;
    800035f4:	4785                	li	a5,1
    800035f6:	c09c                	sw	a5,0(s1)
  return b;
    800035f8:	b7c5                	j	800035d8 <bread+0xd0>

00000000800035fa <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035fa:	1101                	addi	sp,sp,-32
    800035fc:	ec06                	sd	ra,24(sp)
    800035fe:	e822                	sd	s0,16(sp)
    80003600:	e426                	sd	s1,8(sp)
    80003602:	1000                	addi	s0,sp,32
    80003604:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003606:	0541                	addi	a0,a0,16
    80003608:	00001097          	auipc	ra,0x1
    8000360c:	466080e7          	jalr	1126(ra) # 80004a6e <holdingsleep>
    80003610:	cd01                	beqz	a0,80003628 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003612:	4585                	li	a1,1
    80003614:	8526                	mv	a0,s1
    80003616:	00003097          	auipc	ra,0x3
    8000361a:	ee0080e7          	jalr	-288(ra) # 800064f6 <virtio_disk_rw>
}
    8000361e:	60e2                	ld	ra,24(sp)
    80003620:	6442                	ld	s0,16(sp)
    80003622:	64a2                	ld	s1,8(sp)
    80003624:	6105                	addi	sp,sp,32
    80003626:	8082                	ret
    panic("bwrite");
    80003628:	00005517          	auipc	a0,0x5
    8000362c:	fd050513          	addi	a0,a0,-48 # 800085f8 <syscalls+0xd8>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	f0e080e7          	jalr	-242(ra) # 8000053e <panic>

0000000080003638 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003638:	1101                	addi	sp,sp,-32
    8000363a:	ec06                	sd	ra,24(sp)
    8000363c:	e822                	sd	s0,16(sp)
    8000363e:	e426                	sd	s1,8(sp)
    80003640:	e04a                	sd	s2,0(sp)
    80003642:	1000                	addi	s0,sp,32
    80003644:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003646:	01050913          	addi	s2,a0,16
    8000364a:	854a                	mv	a0,s2
    8000364c:	00001097          	auipc	ra,0x1
    80003650:	422080e7          	jalr	1058(ra) # 80004a6e <holdingsleep>
    80003654:	c92d                	beqz	a0,800036c6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003656:	854a                	mv	a0,s2
    80003658:	00001097          	auipc	ra,0x1
    8000365c:	3d2080e7          	jalr	978(ra) # 80004a2a <releasesleep>

  acquire(&bcache.lock);
    80003660:	00014517          	auipc	a0,0x14
    80003664:	5c850513          	addi	a0,a0,1480 # 80017c28 <bcache>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	57c080e7          	jalr	1404(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003670:	40bc                	lw	a5,64(s1)
    80003672:	37fd                	addiw	a5,a5,-1
    80003674:	0007871b          	sext.w	a4,a5
    80003678:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000367a:	eb05                	bnez	a4,800036aa <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000367c:	68bc                	ld	a5,80(s1)
    8000367e:	64b8                	ld	a4,72(s1)
    80003680:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003682:	64bc                	ld	a5,72(s1)
    80003684:	68b8                	ld	a4,80(s1)
    80003686:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003688:	0001c797          	auipc	a5,0x1c
    8000368c:	5a078793          	addi	a5,a5,1440 # 8001fc28 <bcache+0x8000>
    80003690:	2b87b703          	ld	a4,696(a5)
    80003694:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003696:	0001c717          	auipc	a4,0x1c
    8000369a:	7fa70713          	addi	a4,a4,2042 # 8001fe90 <bcache+0x8268>
    8000369e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036a0:	2b87b703          	ld	a4,696(a5)
    800036a4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036a6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036aa:	00014517          	auipc	a0,0x14
    800036ae:	57e50513          	addi	a0,a0,1406 # 80017c28 <bcache>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	5e6080e7          	jalr	1510(ra) # 80000c98 <release>
}
    800036ba:	60e2                	ld	ra,24(sp)
    800036bc:	6442                	ld	s0,16(sp)
    800036be:	64a2                	ld	s1,8(sp)
    800036c0:	6902                	ld	s2,0(sp)
    800036c2:	6105                	addi	sp,sp,32
    800036c4:	8082                	ret
    panic("brelse");
    800036c6:	00005517          	auipc	a0,0x5
    800036ca:	f3a50513          	addi	a0,a0,-198 # 80008600 <syscalls+0xe0>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	e70080e7          	jalr	-400(ra) # 8000053e <panic>

00000000800036d6 <bpin>:

void
bpin(struct buf *b) {
    800036d6:	1101                	addi	sp,sp,-32
    800036d8:	ec06                	sd	ra,24(sp)
    800036da:	e822                	sd	s0,16(sp)
    800036dc:	e426                	sd	s1,8(sp)
    800036de:	1000                	addi	s0,sp,32
    800036e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e2:	00014517          	auipc	a0,0x14
    800036e6:	54650513          	addi	a0,a0,1350 # 80017c28 <bcache>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	4fa080e7          	jalr	1274(ra) # 80000be4 <acquire>
  b->refcnt++;
    800036f2:	40bc                	lw	a5,64(s1)
    800036f4:	2785                	addiw	a5,a5,1
    800036f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036f8:	00014517          	auipc	a0,0x14
    800036fc:	53050513          	addi	a0,a0,1328 # 80017c28 <bcache>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	598080e7          	jalr	1432(ra) # 80000c98 <release>
}
    80003708:	60e2                	ld	ra,24(sp)
    8000370a:	6442                	ld	s0,16(sp)
    8000370c:	64a2                	ld	s1,8(sp)
    8000370e:	6105                	addi	sp,sp,32
    80003710:	8082                	ret

0000000080003712 <bunpin>:

void
bunpin(struct buf *b) {
    80003712:	1101                	addi	sp,sp,-32
    80003714:	ec06                	sd	ra,24(sp)
    80003716:	e822                	sd	s0,16(sp)
    80003718:	e426                	sd	s1,8(sp)
    8000371a:	1000                	addi	s0,sp,32
    8000371c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000371e:	00014517          	auipc	a0,0x14
    80003722:	50a50513          	addi	a0,a0,1290 # 80017c28 <bcache>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	4be080e7          	jalr	1214(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000372e:	40bc                	lw	a5,64(s1)
    80003730:	37fd                	addiw	a5,a5,-1
    80003732:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003734:	00014517          	auipc	a0,0x14
    80003738:	4f450513          	addi	a0,a0,1268 # 80017c28 <bcache>
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	55c080e7          	jalr	1372(ra) # 80000c98 <release>
}
    80003744:	60e2                	ld	ra,24(sp)
    80003746:	6442                	ld	s0,16(sp)
    80003748:	64a2                	ld	s1,8(sp)
    8000374a:	6105                	addi	sp,sp,32
    8000374c:	8082                	ret

000000008000374e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000374e:	1101                	addi	sp,sp,-32
    80003750:	ec06                	sd	ra,24(sp)
    80003752:	e822                	sd	s0,16(sp)
    80003754:	e426                	sd	s1,8(sp)
    80003756:	e04a                	sd	s2,0(sp)
    80003758:	1000                	addi	s0,sp,32
    8000375a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000375c:	00d5d59b          	srliw	a1,a1,0xd
    80003760:	0001d797          	auipc	a5,0x1d
    80003764:	ba47a783          	lw	a5,-1116(a5) # 80020304 <sb+0x1c>
    80003768:	9dbd                	addw	a1,a1,a5
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	d9e080e7          	jalr	-610(ra) # 80003508 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003772:	0074f713          	andi	a4,s1,7
    80003776:	4785                	li	a5,1
    80003778:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000377c:	14ce                	slli	s1,s1,0x33
    8000377e:	90d9                	srli	s1,s1,0x36
    80003780:	00950733          	add	a4,a0,s1
    80003784:	05874703          	lbu	a4,88(a4)
    80003788:	00e7f6b3          	and	a3,a5,a4
    8000378c:	c69d                	beqz	a3,800037ba <bfree+0x6c>
    8000378e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003790:	94aa                	add	s1,s1,a0
    80003792:	fff7c793          	not	a5,a5
    80003796:	8ff9                	and	a5,a5,a4
    80003798:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000379c:	00001097          	auipc	ra,0x1
    800037a0:	118080e7          	jalr	280(ra) # 800048b4 <log_write>
  brelse(bp);
    800037a4:	854a                	mv	a0,s2
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	e92080e7          	jalr	-366(ra) # 80003638 <brelse>
}
    800037ae:	60e2                	ld	ra,24(sp)
    800037b0:	6442                	ld	s0,16(sp)
    800037b2:	64a2                	ld	s1,8(sp)
    800037b4:	6902                	ld	s2,0(sp)
    800037b6:	6105                	addi	sp,sp,32
    800037b8:	8082                	ret
    panic("freeing free block");
    800037ba:	00005517          	auipc	a0,0x5
    800037be:	e4e50513          	addi	a0,a0,-434 # 80008608 <syscalls+0xe8>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>

00000000800037ca <balloc>:
{
    800037ca:	711d                	addi	sp,sp,-96
    800037cc:	ec86                	sd	ra,88(sp)
    800037ce:	e8a2                	sd	s0,80(sp)
    800037d0:	e4a6                	sd	s1,72(sp)
    800037d2:	e0ca                	sd	s2,64(sp)
    800037d4:	fc4e                	sd	s3,56(sp)
    800037d6:	f852                	sd	s4,48(sp)
    800037d8:	f456                	sd	s5,40(sp)
    800037da:	f05a                	sd	s6,32(sp)
    800037dc:	ec5e                	sd	s7,24(sp)
    800037de:	e862                	sd	s8,16(sp)
    800037e0:	e466                	sd	s9,8(sp)
    800037e2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037e4:	0001d797          	auipc	a5,0x1d
    800037e8:	b087a783          	lw	a5,-1272(a5) # 800202ec <sb+0x4>
    800037ec:	cbd1                	beqz	a5,80003880 <balloc+0xb6>
    800037ee:	8baa                	mv	s7,a0
    800037f0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037f2:	0001db17          	auipc	s6,0x1d
    800037f6:	af6b0b13          	addi	s6,s6,-1290 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037fa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037fc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037fe:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003800:	6c89                	lui	s9,0x2
    80003802:	a831                	j	8000381e <balloc+0x54>
    brelse(bp);
    80003804:	854a                	mv	a0,s2
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	e32080e7          	jalr	-462(ra) # 80003638 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000380e:	015c87bb          	addw	a5,s9,s5
    80003812:	00078a9b          	sext.w	s5,a5
    80003816:	004b2703          	lw	a4,4(s6)
    8000381a:	06eaf363          	bgeu	s5,a4,80003880 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000381e:	41fad79b          	sraiw	a5,s5,0x1f
    80003822:	0137d79b          	srliw	a5,a5,0x13
    80003826:	015787bb          	addw	a5,a5,s5
    8000382a:	40d7d79b          	sraiw	a5,a5,0xd
    8000382e:	01cb2583          	lw	a1,28(s6)
    80003832:	9dbd                	addw	a1,a1,a5
    80003834:	855e                	mv	a0,s7
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	cd2080e7          	jalr	-814(ra) # 80003508 <bread>
    8000383e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003840:	004b2503          	lw	a0,4(s6)
    80003844:	000a849b          	sext.w	s1,s5
    80003848:	8662                	mv	a2,s8
    8000384a:	faa4fde3          	bgeu	s1,a0,80003804 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000384e:	41f6579b          	sraiw	a5,a2,0x1f
    80003852:	01d7d69b          	srliw	a3,a5,0x1d
    80003856:	00c6873b          	addw	a4,a3,a2
    8000385a:	00777793          	andi	a5,a4,7
    8000385e:	9f95                	subw	a5,a5,a3
    80003860:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003864:	4037571b          	sraiw	a4,a4,0x3
    80003868:	00e906b3          	add	a3,s2,a4
    8000386c:	0586c683          	lbu	a3,88(a3)
    80003870:	00d7f5b3          	and	a1,a5,a3
    80003874:	cd91                	beqz	a1,80003890 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003876:	2605                	addiw	a2,a2,1
    80003878:	2485                	addiw	s1,s1,1
    8000387a:	fd4618e3          	bne	a2,s4,8000384a <balloc+0x80>
    8000387e:	b759                	j	80003804 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003880:	00005517          	auipc	a0,0x5
    80003884:	da050513          	addi	a0,a0,-608 # 80008620 <syscalls+0x100>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	cb6080e7          	jalr	-842(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003890:	974a                	add	a4,a4,s2
    80003892:	8fd5                	or	a5,a5,a3
    80003894:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003898:	854a                	mv	a0,s2
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	01a080e7          	jalr	26(ra) # 800048b4 <log_write>
        brelse(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	d94080e7          	jalr	-620(ra) # 80003638 <brelse>
  bp = bread(dev, bno);
    800038ac:	85a6                	mv	a1,s1
    800038ae:	855e                	mv	a0,s7
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	c58080e7          	jalr	-936(ra) # 80003508 <bread>
    800038b8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038ba:	40000613          	li	a2,1024
    800038be:	4581                	li	a1,0
    800038c0:	05850513          	addi	a0,a0,88
    800038c4:	ffffd097          	auipc	ra,0xffffd
    800038c8:	41c080e7          	jalr	1052(ra) # 80000ce0 <memset>
  log_write(bp);
    800038cc:	854a                	mv	a0,s2
    800038ce:	00001097          	auipc	ra,0x1
    800038d2:	fe6080e7          	jalr	-26(ra) # 800048b4 <log_write>
  brelse(bp);
    800038d6:	854a                	mv	a0,s2
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	d60080e7          	jalr	-672(ra) # 80003638 <brelse>
}
    800038e0:	8526                	mv	a0,s1
    800038e2:	60e6                	ld	ra,88(sp)
    800038e4:	6446                	ld	s0,80(sp)
    800038e6:	64a6                	ld	s1,72(sp)
    800038e8:	6906                	ld	s2,64(sp)
    800038ea:	79e2                	ld	s3,56(sp)
    800038ec:	7a42                	ld	s4,48(sp)
    800038ee:	7aa2                	ld	s5,40(sp)
    800038f0:	7b02                	ld	s6,32(sp)
    800038f2:	6be2                	ld	s7,24(sp)
    800038f4:	6c42                	ld	s8,16(sp)
    800038f6:	6ca2                	ld	s9,8(sp)
    800038f8:	6125                	addi	sp,sp,96
    800038fa:	8082                	ret

00000000800038fc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038fc:	7179                	addi	sp,sp,-48
    800038fe:	f406                	sd	ra,40(sp)
    80003900:	f022                	sd	s0,32(sp)
    80003902:	ec26                	sd	s1,24(sp)
    80003904:	e84a                	sd	s2,16(sp)
    80003906:	e44e                	sd	s3,8(sp)
    80003908:	e052                	sd	s4,0(sp)
    8000390a:	1800                	addi	s0,sp,48
    8000390c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000390e:	47ad                	li	a5,11
    80003910:	04b7fe63          	bgeu	a5,a1,8000396c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003914:	ff45849b          	addiw	s1,a1,-12
    80003918:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000391c:	0ff00793          	li	a5,255
    80003920:	0ae7e363          	bltu	a5,a4,800039c6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003924:	08052583          	lw	a1,128(a0)
    80003928:	c5ad                	beqz	a1,80003992 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000392a:	00092503          	lw	a0,0(s2)
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	bda080e7          	jalr	-1062(ra) # 80003508 <bread>
    80003936:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003938:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000393c:	02049593          	slli	a1,s1,0x20
    80003940:	9181                	srli	a1,a1,0x20
    80003942:	058a                	slli	a1,a1,0x2
    80003944:	00b784b3          	add	s1,a5,a1
    80003948:	0004a983          	lw	s3,0(s1)
    8000394c:	04098d63          	beqz	s3,800039a6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003950:	8552                	mv	a0,s4
    80003952:	00000097          	auipc	ra,0x0
    80003956:	ce6080e7          	jalr	-794(ra) # 80003638 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000395a:	854e                	mv	a0,s3
    8000395c:	70a2                	ld	ra,40(sp)
    8000395e:	7402                	ld	s0,32(sp)
    80003960:	64e2                	ld	s1,24(sp)
    80003962:	6942                	ld	s2,16(sp)
    80003964:	69a2                	ld	s3,8(sp)
    80003966:	6a02                	ld	s4,0(sp)
    80003968:	6145                	addi	sp,sp,48
    8000396a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000396c:	02059493          	slli	s1,a1,0x20
    80003970:	9081                	srli	s1,s1,0x20
    80003972:	048a                	slli	s1,s1,0x2
    80003974:	94aa                	add	s1,s1,a0
    80003976:	0504a983          	lw	s3,80(s1)
    8000397a:	fe0990e3          	bnez	s3,8000395a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000397e:	4108                	lw	a0,0(a0)
    80003980:	00000097          	auipc	ra,0x0
    80003984:	e4a080e7          	jalr	-438(ra) # 800037ca <balloc>
    80003988:	0005099b          	sext.w	s3,a0
    8000398c:	0534a823          	sw	s3,80(s1)
    80003990:	b7e9                	j	8000395a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003992:	4108                	lw	a0,0(a0)
    80003994:	00000097          	auipc	ra,0x0
    80003998:	e36080e7          	jalr	-458(ra) # 800037ca <balloc>
    8000399c:	0005059b          	sext.w	a1,a0
    800039a0:	08b92023          	sw	a1,128(s2)
    800039a4:	b759                	j	8000392a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039a6:	00092503          	lw	a0,0(s2)
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	e20080e7          	jalr	-480(ra) # 800037ca <balloc>
    800039b2:	0005099b          	sext.w	s3,a0
    800039b6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039ba:	8552                	mv	a0,s4
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	ef8080e7          	jalr	-264(ra) # 800048b4 <log_write>
    800039c4:	b771                	j	80003950 <bmap+0x54>
  panic("bmap: out of range");
    800039c6:	00005517          	auipc	a0,0x5
    800039ca:	c7250513          	addi	a0,a0,-910 # 80008638 <syscalls+0x118>
    800039ce:	ffffd097          	auipc	ra,0xffffd
    800039d2:	b70080e7          	jalr	-1168(ra) # 8000053e <panic>

00000000800039d6 <iget>:
{
    800039d6:	7179                	addi	sp,sp,-48
    800039d8:	f406                	sd	ra,40(sp)
    800039da:	f022                	sd	s0,32(sp)
    800039dc:	ec26                	sd	s1,24(sp)
    800039de:	e84a                	sd	s2,16(sp)
    800039e0:	e44e                	sd	s3,8(sp)
    800039e2:	e052                	sd	s4,0(sp)
    800039e4:	1800                	addi	s0,sp,48
    800039e6:	89aa                	mv	s3,a0
    800039e8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039ea:	0001d517          	auipc	a0,0x1d
    800039ee:	91e50513          	addi	a0,a0,-1762 # 80020308 <itable>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	1f2080e7          	jalr	498(ra) # 80000be4 <acquire>
  empty = 0;
    800039fa:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039fc:	0001d497          	auipc	s1,0x1d
    80003a00:	92448493          	addi	s1,s1,-1756 # 80020320 <itable+0x18>
    80003a04:	0001e697          	auipc	a3,0x1e
    80003a08:	3ac68693          	addi	a3,a3,940 # 80021db0 <log>
    80003a0c:	a039                	j	80003a1a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a0e:	02090b63          	beqz	s2,80003a44 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a12:	08848493          	addi	s1,s1,136
    80003a16:	02d48a63          	beq	s1,a3,80003a4a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a1a:	449c                	lw	a5,8(s1)
    80003a1c:	fef059e3          	blez	a5,80003a0e <iget+0x38>
    80003a20:	4098                	lw	a4,0(s1)
    80003a22:	ff3716e3          	bne	a4,s3,80003a0e <iget+0x38>
    80003a26:	40d8                	lw	a4,4(s1)
    80003a28:	ff4713e3          	bne	a4,s4,80003a0e <iget+0x38>
      ip->ref++;
    80003a2c:	2785                	addiw	a5,a5,1
    80003a2e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a30:	0001d517          	auipc	a0,0x1d
    80003a34:	8d850513          	addi	a0,a0,-1832 # 80020308 <itable>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	260080e7          	jalr	608(ra) # 80000c98 <release>
      return ip;
    80003a40:	8926                	mv	s2,s1
    80003a42:	a03d                	j	80003a70 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a44:	f7f9                	bnez	a5,80003a12 <iget+0x3c>
    80003a46:	8926                	mv	s2,s1
    80003a48:	b7e9                	j	80003a12 <iget+0x3c>
  if(empty == 0)
    80003a4a:	02090c63          	beqz	s2,80003a82 <iget+0xac>
  ip->dev = dev;
    80003a4e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a52:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a56:	4785                	li	a5,1
    80003a58:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a5c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a60:	0001d517          	auipc	a0,0x1d
    80003a64:	8a850513          	addi	a0,a0,-1880 # 80020308 <itable>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	230080e7          	jalr	560(ra) # 80000c98 <release>
}
    80003a70:	854a                	mv	a0,s2
    80003a72:	70a2                	ld	ra,40(sp)
    80003a74:	7402                	ld	s0,32(sp)
    80003a76:	64e2                	ld	s1,24(sp)
    80003a78:	6942                	ld	s2,16(sp)
    80003a7a:	69a2                	ld	s3,8(sp)
    80003a7c:	6a02                	ld	s4,0(sp)
    80003a7e:	6145                	addi	sp,sp,48
    80003a80:	8082                	ret
    panic("iget: no inodes");
    80003a82:	00005517          	auipc	a0,0x5
    80003a86:	bce50513          	addi	a0,a0,-1074 # 80008650 <syscalls+0x130>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>

0000000080003a92 <fsinit>:
fsinit(int dev) {
    80003a92:	7179                	addi	sp,sp,-48
    80003a94:	f406                	sd	ra,40(sp)
    80003a96:	f022                	sd	s0,32(sp)
    80003a98:	ec26                	sd	s1,24(sp)
    80003a9a:	e84a                	sd	s2,16(sp)
    80003a9c:	e44e                	sd	s3,8(sp)
    80003a9e:	1800                	addi	s0,sp,48
    80003aa0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003aa2:	4585                	li	a1,1
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	a64080e7          	jalr	-1436(ra) # 80003508 <bread>
    80003aac:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003aae:	0001d997          	auipc	s3,0x1d
    80003ab2:	83a98993          	addi	s3,s3,-1990 # 800202e8 <sb>
    80003ab6:	02000613          	li	a2,32
    80003aba:	05850593          	addi	a1,a0,88
    80003abe:	854e                	mv	a0,s3
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	280080e7          	jalr	640(ra) # 80000d40 <memmove>
  brelse(bp);
    80003ac8:	8526                	mv	a0,s1
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	b6e080e7          	jalr	-1170(ra) # 80003638 <brelse>
  if(sb.magic != FSMAGIC)
    80003ad2:	0009a703          	lw	a4,0(s3)
    80003ad6:	102037b7          	lui	a5,0x10203
    80003ada:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ade:	02f71263          	bne	a4,a5,80003b02 <fsinit+0x70>
  initlog(dev, &sb);
    80003ae2:	0001d597          	auipc	a1,0x1d
    80003ae6:	80658593          	addi	a1,a1,-2042 # 800202e8 <sb>
    80003aea:	854a                	mv	a0,s2
    80003aec:	00001097          	auipc	ra,0x1
    80003af0:	b4c080e7          	jalr	-1204(ra) # 80004638 <initlog>
}
    80003af4:	70a2                	ld	ra,40(sp)
    80003af6:	7402                	ld	s0,32(sp)
    80003af8:	64e2                	ld	s1,24(sp)
    80003afa:	6942                	ld	s2,16(sp)
    80003afc:	69a2                	ld	s3,8(sp)
    80003afe:	6145                	addi	sp,sp,48
    80003b00:	8082                	ret
    panic("invalid file system");
    80003b02:	00005517          	auipc	a0,0x5
    80003b06:	b5e50513          	addi	a0,a0,-1186 # 80008660 <syscalls+0x140>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	a34080e7          	jalr	-1484(ra) # 8000053e <panic>

0000000080003b12 <iinit>:
{
    80003b12:	7179                	addi	sp,sp,-48
    80003b14:	f406                	sd	ra,40(sp)
    80003b16:	f022                	sd	s0,32(sp)
    80003b18:	ec26                	sd	s1,24(sp)
    80003b1a:	e84a                	sd	s2,16(sp)
    80003b1c:	e44e                	sd	s3,8(sp)
    80003b1e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b20:	00005597          	auipc	a1,0x5
    80003b24:	b5858593          	addi	a1,a1,-1192 # 80008678 <syscalls+0x158>
    80003b28:	0001c517          	auipc	a0,0x1c
    80003b2c:	7e050513          	addi	a0,a0,2016 # 80020308 <itable>
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	024080e7          	jalr	36(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b38:	0001c497          	auipc	s1,0x1c
    80003b3c:	7f848493          	addi	s1,s1,2040 # 80020330 <itable+0x28>
    80003b40:	0001e997          	auipc	s3,0x1e
    80003b44:	28098993          	addi	s3,s3,640 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b48:	00005917          	auipc	s2,0x5
    80003b4c:	b3890913          	addi	s2,s2,-1224 # 80008680 <syscalls+0x160>
    80003b50:	85ca                	mv	a1,s2
    80003b52:	8526                	mv	a0,s1
    80003b54:	00001097          	auipc	ra,0x1
    80003b58:	e46080e7          	jalr	-442(ra) # 8000499a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b5c:	08848493          	addi	s1,s1,136
    80003b60:	ff3498e3          	bne	s1,s3,80003b50 <iinit+0x3e>
}
    80003b64:	70a2                	ld	ra,40(sp)
    80003b66:	7402                	ld	s0,32(sp)
    80003b68:	64e2                	ld	s1,24(sp)
    80003b6a:	6942                	ld	s2,16(sp)
    80003b6c:	69a2                	ld	s3,8(sp)
    80003b6e:	6145                	addi	sp,sp,48
    80003b70:	8082                	ret

0000000080003b72 <ialloc>:
{
    80003b72:	715d                	addi	sp,sp,-80
    80003b74:	e486                	sd	ra,72(sp)
    80003b76:	e0a2                	sd	s0,64(sp)
    80003b78:	fc26                	sd	s1,56(sp)
    80003b7a:	f84a                	sd	s2,48(sp)
    80003b7c:	f44e                	sd	s3,40(sp)
    80003b7e:	f052                	sd	s4,32(sp)
    80003b80:	ec56                	sd	s5,24(sp)
    80003b82:	e85a                	sd	s6,16(sp)
    80003b84:	e45e                	sd	s7,8(sp)
    80003b86:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b88:	0001c717          	auipc	a4,0x1c
    80003b8c:	76c72703          	lw	a4,1900(a4) # 800202f4 <sb+0xc>
    80003b90:	4785                	li	a5,1
    80003b92:	04e7fa63          	bgeu	a5,a4,80003be6 <ialloc+0x74>
    80003b96:	8aaa                	mv	s5,a0
    80003b98:	8bae                	mv	s7,a1
    80003b9a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b9c:	0001ca17          	auipc	s4,0x1c
    80003ba0:	74ca0a13          	addi	s4,s4,1868 # 800202e8 <sb>
    80003ba4:	00048b1b          	sext.w	s6,s1
    80003ba8:	0044d593          	srli	a1,s1,0x4
    80003bac:	018a2783          	lw	a5,24(s4)
    80003bb0:	9dbd                	addw	a1,a1,a5
    80003bb2:	8556                	mv	a0,s5
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	954080e7          	jalr	-1708(ra) # 80003508 <bread>
    80003bbc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bbe:	05850993          	addi	s3,a0,88
    80003bc2:	00f4f793          	andi	a5,s1,15
    80003bc6:	079a                	slli	a5,a5,0x6
    80003bc8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bca:	00099783          	lh	a5,0(s3)
    80003bce:	c785                	beqz	a5,80003bf6 <ialloc+0x84>
    brelse(bp);
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	a68080e7          	jalr	-1432(ra) # 80003638 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bd8:	0485                	addi	s1,s1,1
    80003bda:	00ca2703          	lw	a4,12(s4)
    80003bde:	0004879b          	sext.w	a5,s1
    80003be2:	fce7e1e3          	bltu	a5,a4,80003ba4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003be6:	00005517          	auipc	a0,0x5
    80003bea:	aa250513          	addi	a0,a0,-1374 # 80008688 <syscalls+0x168>
    80003bee:	ffffd097          	auipc	ra,0xffffd
    80003bf2:	950080e7          	jalr	-1712(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003bf6:	04000613          	li	a2,64
    80003bfa:	4581                	li	a1,0
    80003bfc:	854e                	mv	a0,s3
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	0e2080e7          	jalr	226(ra) # 80000ce0 <memset>
      dip->type = type;
    80003c06:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	00001097          	auipc	ra,0x1
    80003c10:	ca8080e7          	jalr	-856(ra) # 800048b4 <log_write>
      brelse(bp);
    80003c14:	854a                	mv	a0,s2
    80003c16:	00000097          	auipc	ra,0x0
    80003c1a:	a22080e7          	jalr	-1502(ra) # 80003638 <brelse>
      return iget(dev, inum);
    80003c1e:	85da                	mv	a1,s6
    80003c20:	8556                	mv	a0,s5
    80003c22:	00000097          	auipc	ra,0x0
    80003c26:	db4080e7          	jalr	-588(ra) # 800039d6 <iget>
}
    80003c2a:	60a6                	ld	ra,72(sp)
    80003c2c:	6406                	ld	s0,64(sp)
    80003c2e:	74e2                	ld	s1,56(sp)
    80003c30:	7942                	ld	s2,48(sp)
    80003c32:	79a2                	ld	s3,40(sp)
    80003c34:	7a02                	ld	s4,32(sp)
    80003c36:	6ae2                	ld	s5,24(sp)
    80003c38:	6b42                	ld	s6,16(sp)
    80003c3a:	6ba2                	ld	s7,8(sp)
    80003c3c:	6161                	addi	sp,sp,80
    80003c3e:	8082                	ret

0000000080003c40 <iupdate>:
{
    80003c40:	1101                	addi	sp,sp,-32
    80003c42:	ec06                	sd	ra,24(sp)
    80003c44:	e822                	sd	s0,16(sp)
    80003c46:	e426                	sd	s1,8(sp)
    80003c48:	e04a                	sd	s2,0(sp)
    80003c4a:	1000                	addi	s0,sp,32
    80003c4c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c4e:	415c                	lw	a5,4(a0)
    80003c50:	0047d79b          	srliw	a5,a5,0x4
    80003c54:	0001c597          	auipc	a1,0x1c
    80003c58:	6ac5a583          	lw	a1,1708(a1) # 80020300 <sb+0x18>
    80003c5c:	9dbd                	addw	a1,a1,a5
    80003c5e:	4108                	lw	a0,0(a0)
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	8a8080e7          	jalr	-1880(ra) # 80003508 <bread>
    80003c68:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c6a:	05850793          	addi	a5,a0,88
    80003c6e:	40c8                	lw	a0,4(s1)
    80003c70:	893d                	andi	a0,a0,15
    80003c72:	051a                	slli	a0,a0,0x6
    80003c74:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c76:	04449703          	lh	a4,68(s1)
    80003c7a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c7e:	04649703          	lh	a4,70(s1)
    80003c82:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c86:	04849703          	lh	a4,72(s1)
    80003c8a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c8e:	04a49703          	lh	a4,74(s1)
    80003c92:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c96:	44f8                	lw	a4,76(s1)
    80003c98:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c9a:	03400613          	li	a2,52
    80003c9e:	05048593          	addi	a1,s1,80
    80003ca2:	0531                	addi	a0,a0,12
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	09c080e7          	jalr	156(ra) # 80000d40 <memmove>
  log_write(bp);
    80003cac:	854a                	mv	a0,s2
    80003cae:	00001097          	auipc	ra,0x1
    80003cb2:	c06080e7          	jalr	-1018(ra) # 800048b4 <log_write>
  brelse(bp);
    80003cb6:	854a                	mv	a0,s2
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	980080e7          	jalr	-1664(ra) # 80003638 <brelse>
}
    80003cc0:	60e2                	ld	ra,24(sp)
    80003cc2:	6442                	ld	s0,16(sp)
    80003cc4:	64a2                	ld	s1,8(sp)
    80003cc6:	6902                	ld	s2,0(sp)
    80003cc8:	6105                	addi	sp,sp,32
    80003cca:	8082                	ret

0000000080003ccc <idup>:
{
    80003ccc:	1101                	addi	sp,sp,-32
    80003cce:	ec06                	sd	ra,24(sp)
    80003cd0:	e822                	sd	s0,16(sp)
    80003cd2:	e426                	sd	s1,8(sp)
    80003cd4:	1000                	addi	s0,sp,32
    80003cd6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cd8:	0001c517          	auipc	a0,0x1c
    80003cdc:	63050513          	addi	a0,a0,1584 # 80020308 <itable>
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	f04080e7          	jalr	-252(ra) # 80000be4 <acquire>
  ip->ref++;
    80003ce8:	449c                	lw	a5,8(s1)
    80003cea:	2785                	addiw	a5,a5,1
    80003cec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cee:	0001c517          	auipc	a0,0x1c
    80003cf2:	61a50513          	addi	a0,a0,1562 # 80020308 <itable>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	fa2080e7          	jalr	-94(ra) # 80000c98 <release>
}
    80003cfe:	8526                	mv	a0,s1
    80003d00:	60e2                	ld	ra,24(sp)
    80003d02:	6442                	ld	s0,16(sp)
    80003d04:	64a2                	ld	s1,8(sp)
    80003d06:	6105                	addi	sp,sp,32
    80003d08:	8082                	ret

0000000080003d0a <ilock>:
{
    80003d0a:	1101                	addi	sp,sp,-32
    80003d0c:	ec06                	sd	ra,24(sp)
    80003d0e:	e822                	sd	s0,16(sp)
    80003d10:	e426                	sd	s1,8(sp)
    80003d12:	e04a                	sd	s2,0(sp)
    80003d14:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d16:	c115                	beqz	a0,80003d3a <ilock+0x30>
    80003d18:	84aa                	mv	s1,a0
    80003d1a:	451c                	lw	a5,8(a0)
    80003d1c:	00f05f63          	blez	a5,80003d3a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d20:	0541                	addi	a0,a0,16
    80003d22:	00001097          	auipc	ra,0x1
    80003d26:	cb2080e7          	jalr	-846(ra) # 800049d4 <acquiresleep>
  if(ip->valid == 0){
    80003d2a:	40bc                	lw	a5,64(s1)
    80003d2c:	cf99                	beqz	a5,80003d4a <ilock+0x40>
}
    80003d2e:	60e2                	ld	ra,24(sp)
    80003d30:	6442                	ld	s0,16(sp)
    80003d32:	64a2                	ld	s1,8(sp)
    80003d34:	6902                	ld	s2,0(sp)
    80003d36:	6105                	addi	sp,sp,32
    80003d38:	8082                	ret
    panic("ilock");
    80003d3a:	00005517          	auipc	a0,0x5
    80003d3e:	96650513          	addi	a0,a0,-1690 # 800086a0 <syscalls+0x180>
    80003d42:	ffffc097          	auipc	ra,0xffffc
    80003d46:	7fc080e7          	jalr	2044(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d4a:	40dc                	lw	a5,4(s1)
    80003d4c:	0047d79b          	srliw	a5,a5,0x4
    80003d50:	0001c597          	auipc	a1,0x1c
    80003d54:	5b05a583          	lw	a1,1456(a1) # 80020300 <sb+0x18>
    80003d58:	9dbd                	addw	a1,a1,a5
    80003d5a:	4088                	lw	a0,0(s1)
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	7ac080e7          	jalr	1964(ra) # 80003508 <bread>
    80003d64:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d66:	05850593          	addi	a1,a0,88
    80003d6a:	40dc                	lw	a5,4(s1)
    80003d6c:	8bbd                	andi	a5,a5,15
    80003d6e:	079a                	slli	a5,a5,0x6
    80003d70:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d72:	00059783          	lh	a5,0(a1)
    80003d76:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d7a:	00259783          	lh	a5,2(a1)
    80003d7e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d82:	00459783          	lh	a5,4(a1)
    80003d86:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d8a:	00659783          	lh	a5,6(a1)
    80003d8e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d92:	459c                	lw	a5,8(a1)
    80003d94:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d96:	03400613          	li	a2,52
    80003d9a:	05b1                	addi	a1,a1,12
    80003d9c:	05048513          	addi	a0,s1,80
    80003da0:	ffffd097          	auipc	ra,0xffffd
    80003da4:	fa0080e7          	jalr	-96(ra) # 80000d40 <memmove>
    brelse(bp);
    80003da8:	854a                	mv	a0,s2
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	88e080e7          	jalr	-1906(ra) # 80003638 <brelse>
    ip->valid = 1;
    80003db2:	4785                	li	a5,1
    80003db4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003db6:	04449783          	lh	a5,68(s1)
    80003dba:	fbb5                	bnez	a5,80003d2e <ilock+0x24>
      panic("ilock: no type");
    80003dbc:	00005517          	auipc	a0,0x5
    80003dc0:	8ec50513          	addi	a0,a0,-1812 # 800086a8 <syscalls+0x188>
    80003dc4:	ffffc097          	auipc	ra,0xffffc
    80003dc8:	77a080e7          	jalr	1914(ra) # 8000053e <panic>

0000000080003dcc <iunlock>:
{
    80003dcc:	1101                	addi	sp,sp,-32
    80003dce:	ec06                	sd	ra,24(sp)
    80003dd0:	e822                	sd	s0,16(sp)
    80003dd2:	e426                	sd	s1,8(sp)
    80003dd4:	e04a                	sd	s2,0(sp)
    80003dd6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dd8:	c905                	beqz	a0,80003e08 <iunlock+0x3c>
    80003dda:	84aa                	mv	s1,a0
    80003ddc:	01050913          	addi	s2,a0,16
    80003de0:	854a                	mv	a0,s2
    80003de2:	00001097          	auipc	ra,0x1
    80003de6:	c8c080e7          	jalr	-884(ra) # 80004a6e <holdingsleep>
    80003dea:	cd19                	beqz	a0,80003e08 <iunlock+0x3c>
    80003dec:	449c                	lw	a5,8(s1)
    80003dee:	00f05d63          	blez	a5,80003e08 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003df2:	854a                	mv	a0,s2
    80003df4:	00001097          	auipc	ra,0x1
    80003df8:	c36080e7          	jalr	-970(ra) # 80004a2a <releasesleep>
}
    80003dfc:	60e2                	ld	ra,24(sp)
    80003dfe:	6442                	ld	s0,16(sp)
    80003e00:	64a2                	ld	s1,8(sp)
    80003e02:	6902                	ld	s2,0(sp)
    80003e04:	6105                	addi	sp,sp,32
    80003e06:	8082                	ret
    panic("iunlock");
    80003e08:	00005517          	auipc	a0,0x5
    80003e0c:	8b050513          	addi	a0,a0,-1872 # 800086b8 <syscalls+0x198>
    80003e10:	ffffc097          	auipc	ra,0xffffc
    80003e14:	72e080e7          	jalr	1838(ra) # 8000053e <panic>

0000000080003e18 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e18:	7179                	addi	sp,sp,-48
    80003e1a:	f406                	sd	ra,40(sp)
    80003e1c:	f022                	sd	s0,32(sp)
    80003e1e:	ec26                	sd	s1,24(sp)
    80003e20:	e84a                	sd	s2,16(sp)
    80003e22:	e44e                	sd	s3,8(sp)
    80003e24:	e052                	sd	s4,0(sp)
    80003e26:	1800                	addi	s0,sp,48
    80003e28:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e2a:	05050493          	addi	s1,a0,80
    80003e2e:	08050913          	addi	s2,a0,128
    80003e32:	a021                	j	80003e3a <itrunc+0x22>
    80003e34:	0491                	addi	s1,s1,4
    80003e36:	01248d63          	beq	s1,s2,80003e50 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e3a:	408c                	lw	a1,0(s1)
    80003e3c:	dde5                	beqz	a1,80003e34 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e3e:	0009a503          	lw	a0,0(s3)
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	90c080e7          	jalr	-1780(ra) # 8000374e <bfree>
      ip->addrs[i] = 0;
    80003e4a:	0004a023          	sw	zero,0(s1)
    80003e4e:	b7dd                	j	80003e34 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e50:	0809a583          	lw	a1,128(s3)
    80003e54:	e185                	bnez	a1,80003e74 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e56:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e5a:	854e                	mv	a0,s3
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	de4080e7          	jalr	-540(ra) # 80003c40 <iupdate>
}
    80003e64:	70a2                	ld	ra,40(sp)
    80003e66:	7402                	ld	s0,32(sp)
    80003e68:	64e2                	ld	s1,24(sp)
    80003e6a:	6942                	ld	s2,16(sp)
    80003e6c:	69a2                	ld	s3,8(sp)
    80003e6e:	6a02                	ld	s4,0(sp)
    80003e70:	6145                	addi	sp,sp,48
    80003e72:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e74:	0009a503          	lw	a0,0(s3)
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	690080e7          	jalr	1680(ra) # 80003508 <bread>
    80003e80:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e82:	05850493          	addi	s1,a0,88
    80003e86:	45850913          	addi	s2,a0,1112
    80003e8a:	a811                	j	80003e9e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e8c:	0009a503          	lw	a0,0(s3)
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	8be080e7          	jalr	-1858(ra) # 8000374e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e98:	0491                	addi	s1,s1,4
    80003e9a:	01248563          	beq	s1,s2,80003ea4 <itrunc+0x8c>
      if(a[j])
    80003e9e:	408c                	lw	a1,0(s1)
    80003ea0:	dde5                	beqz	a1,80003e98 <itrunc+0x80>
    80003ea2:	b7ed                	j	80003e8c <itrunc+0x74>
    brelse(bp);
    80003ea4:	8552                	mv	a0,s4
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	792080e7          	jalr	1938(ra) # 80003638 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003eae:	0809a583          	lw	a1,128(s3)
    80003eb2:	0009a503          	lw	a0,0(s3)
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	898080e7          	jalr	-1896(ra) # 8000374e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ebe:	0809a023          	sw	zero,128(s3)
    80003ec2:	bf51                	j	80003e56 <itrunc+0x3e>

0000000080003ec4 <iput>:
{
    80003ec4:	1101                	addi	sp,sp,-32
    80003ec6:	ec06                	sd	ra,24(sp)
    80003ec8:	e822                	sd	s0,16(sp)
    80003eca:	e426                	sd	s1,8(sp)
    80003ecc:	e04a                	sd	s2,0(sp)
    80003ece:	1000                	addi	s0,sp,32
    80003ed0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ed2:	0001c517          	auipc	a0,0x1c
    80003ed6:	43650513          	addi	a0,a0,1078 # 80020308 <itable>
    80003eda:	ffffd097          	auipc	ra,0xffffd
    80003ede:	d0a080e7          	jalr	-758(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ee2:	4498                	lw	a4,8(s1)
    80003ee4:	4785                	li	a5,1
    80003ee6:	02f70363          	beq	a4,a5,80003f0c <iput+0x48>
  ip->ref--;
    80003eea:	449c                	lw	a5,8(s1)
    80003eec:	37fd                	addiw	a5,a5,-1
    80003eee:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ef0:	0001c517          	auipc	a0,0x1c
    80003ef4:	41850513          	addi	a0,a0,1048 # 80020308 <itable>
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	da0080e7          	jalr	-608(ra) # 80000c98 <release>
}
    80003f00:	60e2                	ld	ra,24(sp)
    80003f02:	6442                	ld	s0,16(sp)
    80003f04:	64a2                	ld	s1,8(sp)
    80003f06:	6902                	ld	s2,0(sp)
    80003f08:	6105                	addi	sp,sp,32
    80003f0a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f0c:	40bc                	lw	a5,64(s1)
    80003f0e:	dff1                	beqz	a5,80003eea <iput+0x26>
    80003f10:	04a49783          	lh	a5,74(s1)
    80003f14:	fbf9                	bnez	a5,80003eea <iput+0x26>
    acquiresleep(&ip->lock);
    80003f16:	01048913          	addi	s2,s1,16
    80003f1a:	854a                	mv	a0,s2
    80003f1c:	00001097          	auipc	ra,0x1
    80003f20:	ab8080e7          	jalr	-1352(ra) # 800049d4 <acquiresleep>
    release(&itable.lock);
    80003f24:	0001c517          	auipc	a0,0x1c
    80003f28:	3e450513          	addi	a0,a0,996 # 80020308 <itable>
    80003f2c:	ffffd097          	auipc	ra,0xffffd
    80003f30:	d6c080e7          	jalr	-660(ra) # 80000c98 <release>
    itrunc(ip);
    80003f34:	8526                	mv	a0,s1
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	ee2080e7          	jalr	-286(ra) # 80003e18 <itrunc>
    ip->type = 0;
    80003f3e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f42:	8526                	mv	a0,s1
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	cfc080e7          	jalr	-772(ra) # 80003c40 <iupdate>
    ip->valid = 0;
    80003f4c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f50:	854a                	mv	a0,s2
    80003f52:	00001097          	auipc	ra,0x1
    80003f56:	ad8080e7          	jalr	-1320(ra) # 80004a2a <releasesleep>
    acquire(&itable.lock);
    80003f5a:	0001c517          	auipc	a0,0x1c
    80003f5e:	3ae50513          	addi	a0,a0,942 # 80020308 <itable>
    80003f62:	ffffd097          	auipc	ra,0xffffd
    80003f66:	c82080e7          	jalr	-894(ra) # 80000be4 <acquire>
    80003f6a:	b741                	j	80003eea <iput+0x26>

0000000080003f6c <iunlockput>:
{
    80003f6c:	1101                	addi	sp,sp,-32
    80003f6e:	ec06                	sd	ra,24(sp)
    80003f70:	e822                	sd	s0,16(sp)
    80003f72:	e426                	sd	s1,8(sp)
    80003f74:	1000                	addi	s0,sp,32
    80003f76:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	e54080e7          	jalr	-428(ra) # 80003dcc <iunlock>
  iput(ip);
    80003f80:	8526                	mv	a0,s1
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	f42080e7          	jalr	-190(ra) # 80003ec4 <iput>
}
    80003f8a:	60e2                	ld	ra,24(sp)
    80003f8c:	6442                	ld	s0,16(sp)
    80003f8e:	64a2                	ld	s1,8(sp)
    80003f90:	6105                	addi	sp,sp,32
    80003f92:	8082                	ret

0000000080003f94 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f94:	1141                	addi	sp,sp,-16
    80003f96:	e422                	sd	s0,8(sp)
    80003f98:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f9a:	411c                	lw	a5,0(a0)
    80003f9c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f9e:	415c                	lw	a5,4(a0)
    80003fa0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fa2:	04451783          	lh	a5,68(a0)
    80003fa6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003faa:	04a51783          	lh	a5,74(a0)
    80003fae:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fb2:	04c56783          	lwu	a5,76(a0)
    80003fb6:	e99c                	sd	a5,16(a1)
}
    80003fb8:	6422                	ld	s0,8(sp)
    80003fba:	0141                	addi	sp,sp,16
    80003fbc:	8082                	ret

0000000080003fbe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fbe:	457c                	lw	a5,76(a0)
    80003fc0:	0ed7e963          	bltu	a5,a3,800040b2 <readi+0xf4>
{
    80003fc4:	7159                	addi	sp,sp,-112
    80003fc6:	f486                	sd	ra,104(sp)
    80003fc8:	f0a2                	sd	s0,96(sp)
    80003fca:	eca6                	sd	s1,88(sp)
    80003fcc:	e8ca                	sd	s2,80(sp)
    80003fce:	e4ce                	sd	s3,72(sp)
    80003fd0:	e0d2                	sd	s4,64(sp)
    80003fd2:	fc56                	sd	s5,56(sp)
    80003fd4:	f85a                	sd	s6,48(sp)
    80003fd6:	f45e                	sd	s7,40(sp)
    80003fd8:	f062                	sd	s8,32(sp)
    80003fda:	ec66                	sd	s9,24(sp)
    80003fdc:	e86a                	sd	s10,16(sp)
    80003fde:	e46e                	sd	s11,8(sp)
    80003fe0:	1880                	addi	s0,sp,112
    80003fe2:	8baa                	mv	s7,a0
    80003fe4:	8c2e                	mv	s8,a1
    80003fe6:	8ab2                	mv	s5,a2
    80003fe8:	84b6                	mv	s1,a3
    80003fea:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fec:	9f35                	addw	a4,a4,a3
    return 0;
    80003fee:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ff0:	0ad76063          	bltu	a4,a3,80004090 <readi+0xd2>
  if(off + n > ip->size)
    80003ff4:	00e7f463          	bgeu	a5,a4,80003ffc <readi+0x3e>
    n = ip->size - off;
    80003ff8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ffc:	0a0b0963          	beqz	s6,800040ae <readi+0xf0>
    80004000:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004002:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004006:	5cfd                	li	s9,-1
    80004008:	a82d                	j	80004042 <readi+0x84>
    8000400a:	020a1d93          	slli	s11,s4,0x20
    8000400e:	020ddd93          	srli	s11,s11,0x20
    80004012:	05890613          	addi	a2,s2,88
    80004016:	86ee                	mv	a3,s11
    80004018:	963a                	add	a2,a2,a4
    8000401a:	85d6                	mv	a1,s5
    8000401c:	8562                	mv	a0,s8
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	a42080e7          	jalr	-1470(ra) # 80002a60 <either_copyout>
    80004026:	05950d63          	beq	a0,s9,80004080 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000402a:	854a                	mv	a0,s2
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	60c080e7          	jalr	1548(ra) # 80003638 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004034:	013a09bb          	addw	s3,s4,s3
    80004038:	009a04bb          	addw	s1,s4,s1
    8000403c:	9aee                	add	s5,s5,s11
    8000403e:	0569f763          	bgeu	s3,s6,8000408c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004042:	000ba903          	lw	s2,0(s7)
    80004046:	00a4d59b          	srliw	a1,s1,0xa
    8000404a:	855e                	mv	a0,s7
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	8b0080e7          	jalr	-1872(ra) # 800038fc <bmap>
    80004054:	0005059b          	sext.w	a1,a0
    80004058:	854a                	mv	a0,s2
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	4ae080e7          	jalr	1198(ra) # 80003508 <bread>
    80004062:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004064:	3ff4f713          	andi	a4,s1,1023
    80004068:	40ed07bb          	subw	a5,s10,a4
    8000406c:	413b06bb          	subw	a3,s6,s3
    80004070:	8a3e                	mv	s4,a5
    80004072:	2781                	sext.w	a5,a5
    80004074:	0006861b          	sext.w	a2,a3
    80004078:	f8f679e3          	bgeu	a2,a5,8000400a <readi+0x4c>
    8000407c:	8a36                	mv	s4,a3
    8000407e:	b771                	j	8000400a <readi+0x4c>
      brelse(bp);
    80004080:	854a                	mv	a0,s2
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	5b6080e7          	jalr	1462(ra) # 80003638 <brelse>
      tot = -1;
    8000408a:	59fd                	li	s3,-1
  }
  return tot;
    8000408c:	0009851b          	sext.w	a0,s3
}
    80004090:	70a6                	ld	ra,104(sp)
    80004092:	7406                	ld	s0,96(sp)
    80004094:	64e6                	ld	s1,88(sp)
    80004096:	6946                	ld	s2,80(sp)
    80004098:	69a6                	ld	s3,72(sp)
    8000409a:	6a06                	ld	s4,64(sp)
    8000409c:	7ae2                	ld	s5,56(sp)
    8000409e:	7b42                	ld	s6,48(sp)
    800040a0:	7ba2                	ld	s7,40(sp)
    800040a2:	7c02                	ld	s8,32(sp)
    800040a4:	6ce2                	ld	s9,24(sp)
    800040a6:	6d42                	ld	s10,16(sp)
    800040a8:	6da2                	ld	s11,8(sp)
    800040aa:	6165                	addi	sp,sp,112
    800040ac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040ae:	89da                	mv	s3,s6
    800040b0:	bff1                	j	8000408c <readi+0xce>
    return 0;
    800040b2:	4501                	li	a0,0
}
    800040b4:	8082                	ret

00000000800040b6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040b6:	457c                	lw	a5,76(a0)
    800040b8:	10d7e863          	bltu	a5,a3,800041c8 <writei+0x112>
{
    800040bc:	7159                	addi	sp,sp,-112
    800040be:	f486                	sd	ra,104(sp)
    800040c0:	f0a2                	sd	s0,96(sp)
    800040c2:	eca6                	sd	s1,88(sp)
    800040c4:	e8ca                	sd	s2,80(sp)
    800040c6:	e4ce                	sd	s3,72(sp)
    800040c8:	e0d2                	sd	s4,64(sp)
    800040ca:	fc56                	sd	s5,56(sp)
    800040cc:	f85a                	sd	s6,48(sp)
    800040ce:	f45e                	sd	s7,40(sp)
    800040d0:	f062                	sd	s8,32(sp)
    800040d2:	ec66                	sd	s9,24(sp)
    800040d4:	e86a                	sd	s10,16(sp)
    800040d6:	e46e                	sd	s11,8(sp)
    800040d8:	1880                	addi	s0,sp,112
    800040da:	8b2a                	mv	s6,a0
    800040dc:	8c2e                	mv	s8,a1
    800040de:	8ab2                	mv	s5,a2
    800040e0:	8936                	mv	s2,a3
    800040e2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040e4:	00e687bb          	addw	a5,a3,a4
    800040e8:	0ed7e263          	bltu	a5,a3,800041cc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040ec:	00043737          	lui	a4,0x43
    800040f0:	0ef76063          	bltu	a4,a5,800041d0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f4:	0c0b8863          	beqz	s7,800041c4 <writei+0x10e>
    800040f8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040fa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040fe:	5cfd                	li	s9,-1
    80004100:	a091                	j	80004144 <writei+0x8e>
    80004102:	02099d93          	slli	s11,s3,0x20
    80004106:	020ddd93          	srli	s11,s11,0x20
    8000410a:	05848513          	addi	a0,s1,88
    8000410e:	86ee                	mv	a3,s11
    80004110:	8656                	mv	a2,s5
    80004112:	85e2                	mv	a1,s8
    80004114:	953a                	add	a0,a0,a4
    80004116:	fffff097          	auipc	ra,0xfffff
    8000411a:	9a0080e7          	jalr	-1632(ra) # 80002ab6 <either_copyin>
    8000411e:	07950263          	beq	a0,s9,80004182 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004122:	8526                	mv	a0,s1
    80004124:	00000097          	auipc	ra,0x0
    80004128:	790080e7          	jalr	1936(ra) # 800048b4 <log_write>
    brelse(bp);
    8000412c:	8526                	mv	a0,s1
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	50a080e7          	jalr	1290(ra) # 80003638 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004136:	01498a3b          	addw	s4,s3,s4
    8000413a:	0129893b          	addw	s2,s3,s2
    8000413e:	9aee                	add	s5,s5,s11
    80004140:	057a7663          	bgeu	s4,s7,8000418c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004144:	000b2483          	lw	s1,0(s6)
    80004148:	00a9559b          	srliw	a1,s2,0xa
    8000414c:	855a                	mv	a0,s6
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	7ae080e7          	jalr	1966(ra) # 800038fc <bmap>
    80004156:	0005059b          	sext.w	a1,a0
    8000415a:	8526                	mv	a0,s1
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	3ac080e7          	jalr	940(ra) # 80003508 <bread>
    80004164:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004166:	3ff97713          	andi	a4,s2,1023
    8000416a:	40ed07bb          	subw	a5,s10,a4
    8000416e:	414b86bb          	subw	a3,s7,s4
    80004172:	89be                	mv	s3,a5
    80004174:	2781                	sext.w	a5,a5
    80004176:	0006861b          	sext.w	a2,a3
    8000417a:	f8f674e3          	bgeu	a2,a5,80004102 <writei+0x4c>
    8000417e:	89b6                	mv	s3,a3
    80004180:	b749                	j	80004102 <writei+0x4c>
      brelse(bp);
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	4b4080e7          	jalr	1204(ra) # 80003638 <brelse>
  }

  if(off > ip->size)
    8000418c:	04cb2783          	lw	a5,76(s6)
    80004190:	0127f463          	bgeu	a5,s2,80004198 <writei+0xe2>
    ip->size = off;
    80004194:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004198:	855a                	mv	a0,s6
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	aa6080e7          	jalr	-1370(ra) # 80003c40 <iupdate>

  return tot;
    800041a2:	000a051b          	sext.w	a0,s4
}
    800041a6:	70a6                	ld	ra,104(sp)
    800041a8:	7406                	ld	s0,96(sp)
    800041aa:	64e6                	ld	s1,88(sp)
    800041ac:	6946                	ld	s2,80(sp)
    800041ae:	69a6                	ld	s3,72(sp)
    800041b0:	6a06                	ld	s4,64(sp)
    800041b2:	7ae2                	ld	s5,56(sp)
    800041b4:	7b42                	ld	s6,48(sp)
    800041b6:	7ba2                	ld	s7,40(sp)
    800041b8:	7c02                	ld	s8,32(sp)
    800041ba:	6ce2                	ld	s9,24(sp)
    800041bc:	6d42                	ld	s10,16(sp)
    800041be:	6da2                	ld	s11,8(sp)
    800041c0:	6165                	addi	sp,sp,112
    800041c2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041c4:	8a5e                	mv	s4,s7
    800041c6:	bfc9                	j	80004198 <writei+0xe2>
    return -1;
    800041c8:	557d                	li	a0,-1
}
    800041ca:	8082                	ret
    return -1;
    800041cc:	557d                	li	a0,-1
    800041ce:	bfe1                	j	800041a6 <writei+0xf0>
    return -1;
    800041d0:	557d                	li	a0,-1
    800041d2:	bfd1                	j	800041a6 <writei+0xf0>

00000000800041d4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041d4:	1141                	addi	sp,sp,-16
    800041d6:	e406                	sd	ra,8(sp)
    800041d8:	e022                	sd	s0,0(sp)
    800041da:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041dc:	4639                	li	a2,14
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	bda080e7          	jalr	-1062(ra) # 80000db8 <strncmp>
}
    800041e6:	60a2                	ld	ra,8(sp)
    800041e8:	6402                	ld	s0,0(sp)
    800041ea:	0141                	addi	sp,sp,16
    800041ec:	8082                	ret

00000000800041ee <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041ee:	7139                	addi	sp,sp,-64
    800041f0:	fc06                	sd	ra,56(sp)
    800041f2:	f822                	sd	s0,48(sp)
    800041f4:	f426                	sd	s1,40(sp)
    800041f6:	f04a                	sd	s2,32(sp)
    800041f8:	ec4e                	sd	s3,24(sp)
    800041fa:	e852                	sd	s4,16(sp)
    800041fc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041fe:	04451703          	lh	a4,68(a0)
    80004202:	4785                	li	a5,1
    80004204:	00f71a63          	bne	a4,a5,80004218 <dirlookup+0x2a>
    80004208:	892a                	mv	s2,a0
    8000420a:	89ae                	mv	s3,a1
    8000420c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000420e:	457c                	lw	a5,76(a0)
    80004210:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004212:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004214:	e79d                	bnez	a5,80004242 <dirlookup+0x54>
    80004216:	a8a5                	j	8000428e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004218:	00004517          	auipc	a0,0x4
    8000421c:	4a850513          	addi	a0,a0,1192 # 800086c0 <syscalls+0x1a0>
    80004220:	ffffc097          	auipc	ra,0xffffc
    80004224:	31e080e7          	jalr	798(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004228:	00004517          	auipc	a0,0x4
    8000422c:	4b050513          	addi	a0,a0,1200 # 800086d8 <syscalls+0x1b8>
    80004230:	ffffc097          	auipc	ra,0xffffc
    80004234:	30e080e7          	jalr	782(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004238:	24c1                	addiw	s1,s1,16
    8000423a:	04c92783          	lw	a5,76(s2)
    8000423e:	04f4f763          	bgeu	s1,a5,8000428c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004242:	4741                	li	a4,16
    80004244:	86a6                	mv	a3,s1
    80004246:	fc040613          	addi	a2,s0,-64
    8000424a:	4581                	li	a1,0
    8000424c:	854a                	mv	a0,s2
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	d70080e7          	jalr	-656(ra) # 80003fbe <readi>
    80004256:	47c1                	li	a5,16
    80004258:	fcf518e3          	bne	a0,a5,80004228 <dirlookup+0x3a>
    if(de.inum == 0)
    8000425c:	fc045783          	lhu	a5,-64(s0)
    80004260:	dfe1                	beqz	a5,80004238 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004262:	fc240593          	addi	a1,s0,-62
    80004266:	854e                	mv	a0,s3
    80004268:	00000097          	auipc	ra,0x0
    8000426c:	f6c080e7          	jalr	-148(ra) # 800041d4 <namecmp>
    80004270:	f561                	bnez	a0,80004238 <dirlookup+0x4a>
      if(poff)
    80004272:	000a0463          	beqz	s4,8000427a <dirlookup+0x8c>
        *poff = off;
    80004276:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000427a:	fc045583          	lhu	a1,-64(s0)
    8000427e:	00092503          	lw	a0,0(s2)
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	754080e7          	jalr	1876(ra) # 800039d6 <iget>
    8000428a:	a011                	j	8000428e <dirlookup+0xa0>
  return 0;
    8000428c:	4501                	li	a0,0
}
    8000428e:	70e2                	ld	ra,56(sp)
    80004290:	7442                	ld	s0,48(sp)
    80004292:	74a2                	ld	s1,40(sp)
    80004294:	7902                	ld	s2,32(sp)
    80004296:	69e2                	ld	s3,24(sp)
    80004298:	6a42                	ld	s4,16(sp)
    8000429a:	6121                	addi	sp,sp,64
    8000429c:	8082                	ret

000000008000429e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000429e:	711d                	addi	sp,sp,-96
    800042a0:	ec86                	sd	ra,88(sp)
    800042a2:	e8a2                	sd	s0,80(sp)
    800042a4:	e4a6                	sd	s1,72(sp)
    800042a6:	e0ca                	sd	s2,64(sp)
    800042a8:	fc4e                	sd	s3,56(sp)
    800042aa:	f852                	sd	s4,48(sp)
    800042ac:	f456                	sd	s5,40(sp)
    800042ae:	f05a                	sd	s6,32(sp)
    800042b0:	ec5e                	sd	s7,24(sp)
    800042b2:	e862                	sd	s8,16(sp)
    800042b4:	e466                	sd	s9,8(sp)
    800042b6:	1080                	addi	s0,sp,96
    800042b8:	84aa                	mv	s1,a0
    800042ba:	8b2e                	mv	s6,a1
    800042bc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042be:	00054703          	lbu	a4,0(a0)
    800042c2:	02f00793          	li	a5,47
    800042c6:	02f70363          	beq	a4,a5,800042ec <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042ca:	ffffe097          	auipc	ra,0xffffe
    800042ce:	b44080e7          	jalr	-1212(ra) # 80001e0e <myproc>
    800042d2:	15053503          	ld	a0,336(a0)
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	9f6080e7          	jalr	-1546(ra) # 80003ccc <idup>
    800042de:	89aa                	mv	s3,a0
  while(*path == '/')
    800042e0:	02f00913          	li	s2,47
  len = path - s;
    800042e4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800042e6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042e8:	4c05                	li	s8,1
    800042ea:	a865                	j	800043a2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042ec:	4585                	li	a1,1
    800042ee:	4505                	li	a0,1
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	6e6080e7          	jalr	1766(ra) # 800039d6 <iget>
    800042f8:	89aa                	mv	s3,a0
    800042fa:	b7dd                	j	800042e0 <namex+0x42>
      iunlockput(ip);
    800042fc:	854e                	mv	a0,s3
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	c6e080e7          	jalr	-914(ra) # 80003f6c <iunlockput>
      return 0;
    80004306:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004308:	854e                	mv	a0,s3
    8000430a:	60e6                	ld	ra,88(sp)
    8000430c:	6446                	ld	s0,80(sp)
    8000430e:	64a6                	ld	s1,72(sp)
    80004310:	6906                	ld	s2,64(sp)
    80004312:	79e2                	ld	s3,56(sp)
    80004314:	7a42                	ld	s4,48(sp)
    80004316:	7aa2                	ld	s5,40(sp)
    80004318:	7b02                	ld	s6,32(sp)
    8000431a:	6be2                	ld	s7,24(sp)
    8000431c:	6c42                	ld	s8,16(sp)
    8000431e:	6ca2                	ld	s9,8(sp)
    80004320:	6125                	addi	sp,sp,96
    80004322:	8082                	ret
      iunlock(ip);
    80004324:	854e                	mv	a0,s3
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	aa6080e7          	jalr	-1370(ra) # 80003dcc <iunlock>
      return ip;
    8000432e:	bfe9                	j	80004308 <namex+0x6a>
      iunlockput(ip);
    80004330:	854e                	mv	a0,s3
    80004332:	00000097          	auipc	ra,0x0
    80004336:	c3a080e7          	jalr	-966(ra) # 80003f6c <iunlockput>
      return 0;
    8000433a:	89d2                	mv	s3,s4
    8000433c:	b7f1                	j	80004308 <namex+0x6a>
  len = path - s;
    8000433e:	40b48633          	sub	a2,s1,a1
    80004342:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004346:	094cd463          	bge	s9,s4,800043ce <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000434a:	4639                	li	a2,14
    8000434c:	8556                	mv	a0,s5
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	9f2080e7          	jalr	-1550(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004356:	0004c783          	lbu	a5,0(s1)
    8000435a:	01279763          	bne	a5,s2,80004368 <namex+0xca>
    path++;
    8000435e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004360:	0004c783          	lbu	a5,0(s1)
    80004364:	ff278de3          	beq	a5,s2,8000435e <namex+0xc0>
    ilock(ip);
    80004368:	854e                	mv	a0,s3
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	9a0080e7          	jalr	-1632(ra) # 80003d0a <ilock>
    if(ip->type != T_DIR){
    80004372:	04499783          	lh	a5,68(s3)
    80004376:	f98793e3          	bne	a5,s8,800042fc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000437a:	000b0563          	beqz	s6,80004384 <namex+0xe6>
    8000437e:	0004c783          	lbu	a5,0(s1)
    80004382:	d3cd                	beqz	a5,80004324 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004384:	865e                	mv	a2,s7
    80004386:	85d6                	mv	a1,s5
    80004388:	854e                	mv	a0,s3
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	e64080e7          	jalr	-412(ra) # 800041ee <dirlookup>
    80004392:	8a2a                	mv	s4,a0
    80004394:	dd51                	beqz	a0,80004330 <namex+0x92>
    iunlockput(ip);
    80004396:	854e                	mv	a0,s3
    80004398:	00000097          	auipc	ra,0x0
    8000439c:	bd4080e7          	jalr	-1068(ra) # 80003f6c <iunlockput>
    ip = next;
    800043a0:	89d2                	mv	s3,s4
  while(*path == '/')
    800043a2:	0004c783          	lbu	a5,0(s1)
    800043a6:	05279763          	bne	a5,s2,800043f4 <namex+0x156>
    path++;
    800043aa:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043ac:	0004c783          	lbu	a5,0(s1)
    800043b0:	ff278de3          	beq	a5,s2,800043aa <namex+0x10c>
  if(*path == 0)
    800043b4:	c79d                	beqz	a5,800043e2 <namex+0x144>
    path++;
    800043b6:	85a6                	mv	a1,s1
  len = path - s;
    800043b8:	8a5e                	mv	s4,s7
    800043ba:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043bc:	01278963          	beq	a5,s2,800043ce <namex+0x130>
    800043c0:	dfbd                	beqz	a5,8000433e <namex+0xa0>
    path++;
    800043c2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043c4:	0004c783          	lbu	a5,0(s1)
    800043c8:	ff279ce3          	bne	a5,s2,800043c0 <namex+0x122>
    800043cc:	bf8d                	j	8000433e <namex+0xa0>
    memmove(name, s, len);
    800043ce:	2601                	sext.w	a2,a2
    800043d0:	8556                	mv	a0,s5
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	96e080e7          	jalr	-1682(ra) # 80000d40 <memmove>
    name[len] = 0;
    800043da:	9a56                	add	s4,s4,s5
    800043dc:	000a0023          	sb	zero,0(s4)
    800043e0:	bf9d                	j	80004356 <namex+0xb8>
  if(nameiparent){
    800043e2:	f20b03e3          	beqz	s6,80004308 <namex+0x6a>
    iput(ip);
    800043e6:	854e                	mv	a0,s3
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	adc080e7          	jalr	-1316(ra) # 80003ec4 <iput>
    return 0;
    800043f0:	4981                	li	s3,0
    800043f2:	bf19                	j	80004308 <namex+0x6a>
  if(*path == 0)
    800043f4:	d7fd                	beqz	a5,800043e2 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043f6:	0004c783          	lbu	a5,0(s1)
    800043fa:	85a6                	mv	a1,s1
    800043fc:	b7d1                	j	800043c0 <namex+0x122>

00000000800043fe <dirlink>:
{
    800043fe:	7139                	addi	sp,sp,-64
    80004400:	fc06                	sd	ra,56(sp)
    80004402:	f822                	sd	s0,48(sp)
    80004404:	f426                	sd	s1,40(sp)
    80004406:	f04a                	sd	s2,32(sp)
    80004408:	ec4e                	sd	s3,24(sp)
    8000440a:	e852                	sd	s4,16(sp)
    8000440c:	0080                	addi	s0,sp,64
    8000440e:	892a                	mv	s2,a0
    80004410:	8a2e                	mv	s4,a1
    80004412:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004414:	4601                	li	a2,0
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	dd8080e7          	jalr	-552(ra) # 800041ee <dirlookup>
    8000441e:	e93d                	bnez	a0,80004494 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004420:	04c92483          	lw	s1,76(s2)
    80004424:	c49d                	beqz	s1,80004452 <dirlink+0x54>
    80004426:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004428:	4741                	li	a4,16
    8000442a:	86a6                	mv	a3,s1
    8000442c:	fc040613          	addi	a2,s0,-64
    80004430:	4581                	li	a1,0
    80004432:	854a                	mv	a0,s2
    80004434:	00000097          	auipc	ra,0x0
    80004438:	b8a080e7          	jalr	-1142(ra) # 80003fbe <readi>
    8000443c:	47c1                	li	a5,16
    8000443e:	06f51163          	bne	a0,a5,800044a0 <dirlink+0xa2>
    if(de.inum == 0)
    80004442:	fc045783          	lhu	a5,-64(s0)
    80004446:	c791                	beqz	a5,80004452 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004448:	24c1                	addiw	s1,s1,16
    8000444a:	04c92783          	lw	a5,76(s2)
    8000444e:	fcf4ede3          	bltu	s1,a5,80004428 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004452:	4639                	li	a2,14
    80004454:	85d2                	mv	a1,s4
    80004456:	fc240513          	addi	a0,s0,-62
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	99a080e7          	jalr	-1638(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004462:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004466:	4741                	li	a4,16
    80004468:	86a6                	mv	a3,s1
    8000446a:	fc040613          	addi	a2,s0,-64
    8000446e:	4581                	li	a1,0
    80004470:	854a                	mv	a0,s2
    80004472:	00000097          	auipc	ra,0x0
    80004476:	c44080e7          	jalr	-956(ra) # 800040b6 <writei>
    8000447a:	872a                	mv	a4,a0
    8000447c:	47c1                	li	a5,16
  return 0;
    8000447e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004480:	02f71863          	bne	a4,a5,800044b0 <dirlink+0xb2>
}
    80004484:	70e2                	ld	ra,56(sp)
    80004486:	7442                	ld	s0,48(sp)
    80004488:	74a2                	ld	s1,40(sp)
    8000448a:	7902                	ld	s2,32(sp)
    8000448c:	69e2                	ld	s3,24(sp)
    8000448e:	6a42                	ld	s4,16(sp)
    80004490:	6121                	addi	sp,sp,64
    80004492:	8082                	ret
    iput(ip);
    80004494:	00000097          	auipc	ra,0x0
    80004498:	a30080e7          	jalr	-1488(ra) # 80003ec4 <iput>
    return -1;
    8000449c:	557d                	li	a0,-1
    8000449e:	b7dd                	j	80004484 <dirlink+0x86>
      panic("dirlink read");
    800044a0:	00004517          	auipc	a0,0x4
    800044a4:	24850513          	addi	a0,a0,584 # 800086e8 <syscalls+0x1c8>
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	096080e7          	jalr	150(ra) # 8000053e <panic>
    panic("dirlink");
    800044b0:	00004517          	auipc	a0,0x4
    800044b4:	34850513          	addi	a0,a0,840 # 800087f8 <syscalls+0x2d8>
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	086080e7          	jalr	134(ra) # 8000053e <panic>

00000000800044c0 <namei>:

struct inode*
namei(char *path)
{
    800044c0:	1101                	addi	sp,sp,-32
    800044c2:	ec06                	sd	ra,24(sp)
    800044c4:	e822                	sd	s0,16(sp)
    800044c6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044c8:	fe040613          	addi	a2,s0,-32
    800044cc:	4581                	li	a1,0
    800044ce:	00000097          	auipc	ra,0x0
    800044d2:	dd0080e7          	jalr	-560(ra) # 8000429e <namex>
}
    800044d6:	60e2                	ld	ra,24(sp)
    800044d8:	6442                	ld	s0,16(sp)
    800044da:	6105                	addi	sp,sp,32
    800044dc:	8082                	ret

00000000800044de <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044de:	1141                	addi	sp,sp,-16
    800044e0:	e406                	sd	ra,8(sp)
    800044e2:	e022                	sd	s0,0(sp)
    800044e4:	0800                	addi	s0,sp,16
    800044e6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044e8:	4585                	li	a1,1
    800044ea:	00000097          	auipc	ra,0x0
    800044ee:	db4080e7          	jalr	-588(ra) # 8000429e <namex>
}
    800044f2:	60a2                	ld	ra,8(sp)
    800044f4:	6402                	ld	s0,0(sp)
    800044f6:	0141                	addi	sp,sp,16
    800044f8:	8082                	ret

00000000800044fa <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044fa:	1101                	addi	sp,sp,-32
    800044fc:	ec06                	sd	ra,24(sp)
    800044fe:	e822                	sd	s0,16(sp)
    80004500:	e426                	sd	s1,8(sp)
    80004502:	e04a                	sd	s2,0(sp)
    80004504:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004506:	0001e917          	auipc	s2,0x1e
    8000450a:	8aa90913          	addi	s2,s2,-1878 # 80021db0 <log>
    8000450e:	01892583          	lw	a1,24(s2)
    80004512:	02892503          	lw	a0,40(s2)
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	ff2080e7          	jalr	-14(ra) # 80003508 <bread>
    8000451e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004520:	02c92683          	lw	a3,44(s2)
    80004524:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004526:	02d05763          	blez	a3,80004554 <write_head+0x5a>
    8000452a:	0001e797          	auipc	a5,0x1e
    8000452e:	8b678793          	addi	a5,a5,-1866 # 80021de0 <log+0x30>
    80004532:	05c50713          	addi	a4,a0,92
    80004536:	36fd                	addiw	a3,a3,-1
    80004538:	1682                	slli	a3,a3,0x20
    8000453a:	9281                	srli	a3,a3,0x20
    8000453c:	068a                	slli	a3,a3,0x2
    8000453e:	0001e617          	auipc	a2,0x1e
    80004542:	8a660613          	addi	a2,a2,-1882 # 80021de4 <log+0x34>
    80004546:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004548:	4390                	lw	a2,0(a5)
    8000454a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000454c:	0791                	addi	a5,a5,4
    8000454e:	0711                	addi	a4,a4,4
    80004550:	fed79ce3          	bne	a5,a3,80004548 <write_head+0x4e>
  }
  bwrite(buf);
    80004554:	8526                	mv	a0,s1
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	0a4080e7          	jalr	164(ra) # 800035fa <bwrite>
  brelse(buf);
    8000455e:	8526                	mv	a0,s1
    80004560:	fffff097          	auipc	ra,0xfffff
    80004564:	0d8080e7          	jalr	216(ra) # 80003638 <brelse>
}
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6902                	ld	s2,0(sp)
    80004570:	6105                	addi	sp,sp,32
    80004572:	8082                	ret

0000000080004574 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004574:	0001e797          	auipc	a5,0x1e
    80004578:	8687a783          	lw	a5,-1944(a5) # 80021ddc <log+0x2c>
    8000457c:	0af05d63          	blez	a5,80004636 <install_trans+0xc2>
{
    80004580:	7139                	addi	sp,sp,-64
    80004582:	fc06                	sd	ra,56(sp)
    80004584:	f822                	sd	s0,48(sp)
    80004586:	f426                	sd	s1,40(sp)
    80004588:	f04a                	sd	s2,32(sp)
    8000458a:	ec4e                	sd	s3,24(sp)
    8000458c:	e852                	sd	s4,16(sp)
    8000458e:	e456                	sd	s5,8(sp)
    80004590:	e05a                	sd	s6,0(sp)
    80004592:	0080                	addi	s0,sp,64
    80004594:	8b2a                	mv	s6,a0
    80004596:	0001ea97          	auipc	s5,0x1e
    8000459a:	84aa8a93          	addi	s5,s5,-1974 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000459e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045a0:	0001e997          	auipc	s3,0x1e
    800045a4:	81098993          	addi	s3,s3,-2032 # 80021db0 <log>
    800045a8:	a035                	j	800045d4 <install_trans+0x60>
      bunpin(dbuf);
    800045aa:	8526                	mv	a0,s1
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	166080e7          	jalr	358(ra) # 80003712 <bunpin>
    brelse(lbuf);
    800045b4:	854a                	mv	a0,s2
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	082080e7          	jalr	130(ra) # 80003638 <brelse>
    brelse(dbuf);
    800045be:	8526                	mv	a0,s1
    800045c0:	fffff097          	auipc	ra,0xfffff
    800045c4:	078080e7          	jalr	120(ra) # 80003638 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c8:	2a05                	addiw	s4,s4,1
    800045ca:	0a91                	addi	s5,s5,4
    800045cc:	02c9a783          	lw	a5,44(s3)
    800045d0:	04fa5963          	bge	s4,a5,80004622 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d4:	0189a583          	lw	a1,24(s3)
    800045d8:	014585bb          	addw	a1,a1,s4
    800045dc:	2585                	addiw	a1,a1,1
    800045de:	0289a503          	lw	a0,40(s3)
    800045e2:	fffff097          	auipc	ra,0xfffff
    800045e6:	f26080e7          	jalr	-218(ra) # 80003508 <bread>
    800045ea:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045ec:	000aa583          	lw	a1,0(s5)
    800045f0:	0289a503          	lw	a0,40(s3)
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	f14080e7          	jalr	-236(ra) # 80003508 <bread>
    800045fc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045fe:	40000613          	li	a2,1024
    80004602:	05890593          	addi	a1,s2,88
    80004606:	05850513          	addi	a0,a0,88
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	736080e7          	jalr	1846(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004612:	8526                	mv	a0,s1
    80004614:	fffff097          	auipc	ra,0xfffff
    80004618:	fe6080e7          	jalr	-26(ra) # 800035fa <bwrite>
    if(recovering == 0)
    8000461c:	f80b1ce3          	bnez	s6,800045b4 <install_trans+0x40>
    80004620:	b769                	j	800045aa <install_trans+0x36>
}
    80004622:	70e2                	ld	ra,56(sp)
    80004624:	7442                	ld	s0,48(sp)
    80004626:	74a2                	ld	s1,40(sp)
    80004628:	7902                	ld	s2,32(sp)
    8000462a:	69e2                	ld	s3,24(sp)
    8000462c:	6a42                	ld	s4,16(sp)
    8000462e:	6aa2                	ld	s5,8(sp)
    80004630:	6b02                	ld	s6,0(sp)
    80004632:	6121                	addi	sp,sp,64
    80004634:	8082                	ret
    80004636:	8082                	ret

0000000080004638 <initlog>:
{
    80004638:	7179                	addi	sp,sp,-48
    8000463a:	f406                	sd	ra,40(sp)
    8000463c:	f022                	sd	s0,32(sp)
    8000463e:	ec26                	sd	s1,24(sp)
    80004640:	e84a                	sd	s2,16(sp)
    80004642:	e44e                	sd	s3,8(sp)
    80004644:	1800                	addi	s0,sp,48
    80004646:	892a                	mv	s2,a0
    80004648:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000464a:	0001d497          	auipc	s1,0x1d
    8000464e:	76648493          	addi	s1,s1,1894 # 80021db0 <log>
    80004652:	00004597          	auipc	a1,0x4
    80004656:	0a658593          	addi	a1,a1,166 # 800086f8 <syscalls+0x1d8>
    8000465a:	8526                	mv	a0,s1
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	4f8080e7          	jalr	1272(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004664:	0149a583          	lw	a1,20(s3)
    80004668:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000466a:	0109a783          	lw	a5,16(s3)
    8000466e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004670:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004674:	854a                	mv	a0,s2
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	e92080e7          	jalr	-366(ra) # 80003508 <bread>
  log.lh.n = lh->n;
    8000467e:	4d3c                	lw	a5,88(a0)
    80004680:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004682:	02f05563          	blez	a5,800046ac <initlog+0x74>
    80004686:	05c50713          	addi	a4,a0,92
    8000468a:	0001d697          	auipc	a3,0x1d
    8000468e:	75668693          	addi	a3,a3,1878 # 80021de0 <log+0x30>
    80004692:	37fd                	addiw	a5,a5,-1
    80004694:	1782                	slli	a5,a5,0x20
    80004696:	9381                	srli	a5,a5,0x20
    80004698:	078a                	slli	a5,a5,0x2
    8000469a:	06050613          	addi	a2,a0,96
    8000469e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046a0:	4310                	lw	a2,0(a4)
    800046a2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046a4:	0711                	addi	a4,a4,4
    800046a6:	0691                	addi	a3,a3,4
    800046a8:	fef71ce3          	bne	a4,a5,800046a0 <initlog+0x68>
  brelse(buf);
    800046ac:	fffff097          	auipc	ra,0xfffff
    800046b0:	f8c080e7          	jalr	-116(ra) # 80003638 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046b4:	4505                	li	a0,1
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	ebe080e7          	jalr	-322(ra) # 80004574 <install_trans>
  log.lh.n = 0;
    800046be:	0001d797          	auipc	a5,0x1d
    800046c2:	7007af23          	sw	zero,1822(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	e34080e7          	jalr	-460(ra) # 800044fa <write_head>
}
    800046ce:	70a2                	ld	ra,40(sp)
    800046d0:	7402                	ld	s0,32(sp)
    800046d2:	64e2                	ld	s1,24(sp)
    800046d4:	6942                	ld	s2,16(sp)
    800046d6:	69a2                	ld	s3,8(sp)
    800046d8:	6145                	addi	sp,sp,48
    800046da:	8082                	ret

00000000800046dc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046dc:	1101                	addi	sp,sp,-32
    800046de:	ec06                	sd	ra,24(sp)
    800046e0:	e822                	sd	s0,16(sp)
    800046e2:	e426                	sd	s1,8(sp)
    800046e4:	e04a                	sd	s2,0(sp)
    800046e6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046e8:	0001d517          	auipc	a0,0x1d
    800046ec:	6c850513          	addi	a0,a0,1736 # 80021db0 <log>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	4f4080e7          	jalr	1268(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800046f8:	0001d497          	auipc	s1,0x1d
    800046fc:	6b848493          	addi	s1,s1,1720 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004700:	4979                	li	s2,30
    80004702:	a039                	j	80004710 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004704:	85a6                	mv	a1,s1
    80004706:	8526                	mv	a0,s1
    80004708:	ffffe097          	auipc	ra,0xffffe
    8000470c:	f1a080e7          	jalr	-230(ra) # 80002622 <sleep>
    if(log.committing){
    80004710:	50dc                	lw	a5,36(s1)
    80004712:	fbed                	bnez	a5,80004704 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004714:	509c                	lw	a5,32(s1)
    80004716:	0017871b          	addiw	a4,a5,1
    8000471a:	0007069b          	sext.w	a3,a4
    8000471e:	0027179b          	slliw	a5,a4,0x2
    80004722:	9fb9                	addw	a5,a5,a4
    80004724:	0017979b          	slliw	a5,a5,0x1
    80004728:	54d8                	lw	a4,44(s1)
    8000472a:	9fb9                	addw	a5,a5,a4
    8000472c:	00f95963          	bge	s2,a5,8000473e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004730:	85a6                	mv	a1,s1
    80004732:	8526                	mv	a0,s1
    80004734:	ffffe097          	auipc	ra,0xffffe
    80004738:	eee080e7          	jalr	-274(ra) # 80002622 <sleep>
    8000473c:	bfd1                	j	80004710 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000473e:	0001d517          	auipc	a0,0x1d
    80004742:	67250513          	addi	a0,a0,1650 # 80021db0 <log>
    80004746:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	550080e7          	jalr	1360(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6902                	ld	s2,0(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000475c:	7139                	addi	sp,sp,-64
    8000475e:	fc06                	sd	ra,56(sp)
    80004760:	f822                	sd	s0,48(sp)
    80004762:	f426                	sd	s1,40(sp)
    80004764:	f04a                	sd	s2,32(sp)
    80004766:	ec4e                	sd	s3,24(sp)
    80004768:	e852                	sd	s4,16(sp)
    8000476a:	e456                	sd	s5,8(sp)
    8000476c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000476e:	0001d497          	auipc	s1,0x1d
    80004772:	64248493          	addi	s1,s1,1602 # 80021db0 <log>
    80004776:	8526                	mv	a0,s1
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	46c080e7          	jalr	1132(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004780:	509c                	lw	a5,32(s1)
    80004782:	37fd                	addiw	a5,a5,-1
    80004784:	0007891b          	sext.w	s2,a5
    80004788:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000478a:	50dc                	lw	a5,36(s1)
    8000478c:	efb9                	bnez	a5,800047ea <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000478e:	06091663          	bnez	s2,800047fa <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004792:	0001d497          	auipc	s1,0x1d
    80004796:	61e48493          	addi	s1,s1,1566 # 80021db0 <log>
    8000479a:	4785                	li	a5,1
    8000479c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000479e:	8526                	mv	a0,s1
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	4f8080e7          	jalr	1272(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047a8:	54dc                	lw	a5,44(s1)
    800047aa:	06f04763          	bgtz	a5,80004818 <end_op+0xbc>
    acquire(&log.lock);
    800047ae:	0001d497          	auipc	s1,0x1d
    800047b2:	60248493          	addi	s1,s1,1538 # 80021db0 <log>
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	42c080e7          	jalr	1068(ra) # 80000be4 <acquire>
    log.committing = 0;
    800047c0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047c4:	8526                	mv	a0,s1
    800047c6:	ffffe097          	auipc	ra,0xffffe
    800047ca:	ffa080e7          	jalr	-6(ra) # 800027c0 <wakeup>
    release(&log.lock);
    800047ce:	8526                	mv	a0,s1
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	4c8080e7          	jalr	1224(ra) # 80000c98 <release>
}
    800047d8:	70e2                	ld	ra,56(sp)
    800047da:	7442                	ld	s0,48(sp)
    800047dc:	74a2                	ld	s1,40(sp)
    800047de:	7902                	ld	s2,32(sp)
    800047e0:	69e2                	ld	s3,24(sp)
    800047e2:	6a42                	ld	s4,16(sp)
    800047e4:	6aa2                	ld	s5,8(sp)
    800047e6:	6121                	addi	sp,sp,64
    800047e8:	8082                	ret
    panic("log.committing");
    800047ea:	00004517          	auipc	a0,0x4
    800047ee:	f1650513          	addi	a0,a0,-234 # 80008700 <syscalls+0x1e0>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	d4c080e7          	jalr	-692(ra) # 8000053e <panic>
    wakeup(&log);
    800047fa:	0001d497          	auipc	s1,0x1d
    800047fe:	5b648493          	addi	s1,s1,1462 # 80021db0 <log>
    80004802:	8526                	mv	a0,s1
    80004804:	ffffe097          	auipc	ra,0xffffe
    80004808:	fbc080e7          	jalr	-68(ra) # 800027c0 <wakeup>
  release(&log.lock);
    8000480c:	8526                	mv	a0,s1
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
  if(do_commit){
    80004816:	b7c9                	j	800047d8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004818:	0001da97          	auipc	s5,0x1d
    8000481c:	5c8a8a93          	addi	s5,s5,1480 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004820:	0001da17          	auipc	s4,0x1d
    80004824:	590a0a13          	addi	s4,s4,1424 # 80021db0 <log>
    80004828:	018a2583          	lw	a1,24(s4)
    8000482c:	012585bb          	addw	a1,a1,s2
    80004830:	2585                	addiw	a1,a1,1
    80004832:	028a2503          	lw	a0,40(s4)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	cd2080e7          	jalr	-814(ra) # 80003508 <bread>
    8000483e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004840:	000aa583          	lw	a1,0(s5)
    80004844:	028a2503          	lw	a0,40(s4)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	cc0080e7          	jalr	-832(ra) # 80003508 <bread>
    80004850:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004852:	40000613          	li	a2,1024
    80004856:	05850593          	addi	a1,a0,88
    8000485a:	05848513          	addi	a0,s1,88
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	4e2080e7          	jalr	1250(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004866:	8526                	mv	a0,s1
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	d92080e7          	jalr	-622(ra) # 800035fa <bwrite>
    brelse(from);
    80004870:	854e                	mv	a0,s3
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	dc6080e7          	jalr	-570(ra) # 80003638 <brelse>
    brelse(to);
    8000487a:	8526                	mv	a0,s1
    8000487c:	fffff097          	auipc	ra,0xfffff
    80004880:	dbc080e7          	jalr	-580(ra) # 80003638 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004884:	2905                	addiw	s2,s2,1
    80004886:	0a91                	addi	s5,s5,4
    80004888:	02ca2783          	lw	a5,44(s4)
    8000488c:	f8f94ee3          	blt	s2,a5,80004828 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004890:	00000097          	auipc	ra,0x0
    80004894:	c6a080e7          	jalr	-918(ra) # 800044fa <write_head>
    install_trans(0); // Now install writes to home locations
    80004898:	4501                	li	a0,0
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	cda080e7          	jalr	-806(ra) # 80004574 <install_trans>
    log.lh.n = 0;
    800048a2:	0001d797          	auipc	a5,0x1d
    800048a6:	5207ad23          	sw	zero,1338(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	c50080e7          	jalr	-944(ra) # 800044fa <write_head>
    800048b2:	bdf5                	j	800047ae <end_op+0x52>

00000000800048b4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048b4:	1101                	addi	sp,sp,-32
    800048b6:	ec06                	sd	ra,24(sp)
    800048b8:	e822                	sd	s0,16(sp)
    800048ba:	e426                	sd	s1,8(sp)
    800048bc:	e04a                	sd	s2,0(sp)
    800048be:	1000                	addi	s0,sp,32
    800048c0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048c2:	0001d917          	auipc	s2,0x1d
    800048c6:	4ee90913          	addi	s2,s2,1262 # 80021db0 <log>
    800048ca:	854a                	mv	a0,s2
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	318080e7          	jalr	792(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048d4:	02c92603          	lw	a2,44(s2)
    800048d8:	47f5                	li	a5,29
    800048da:	06c7c563          	blt	a5,a2,80004944 <log_write+0x90>
    800048de:	0001d797          	auipc	a5,0x1d
    800048e2:	4ee7a783          	lw	a5,1262(a5) # 80021dcc <log+0x1c>
    800048e6:	37fd                	addiw	a5,a5,-1
    800048e8:	04f65e63          	bge	a2,a5,80004944 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048ec:	0001d797          	auipc	a5,0x1d
    800048f0:	4e47a783          	lw	a5,1252(a5) # 80021dd0 <log+0x20>
    800048f4:	06f05063          	blez	a5,80004954 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048f8:	4781                	li	a5,0
    800048fa:	06c05563          	blez	a2,80004964 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048fe:	44cc                	lw	a1,12(s1)
    80004900:	0001d717          	auipc	a4,0x1d
    80004904:	4e070713          	addi	a4,a4,1248 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004908:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000490a:	4314                	lw	a3,0(a4)
    8000490c:	04b68c63          	beq	a3,a1,80004964 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004910:	2785                	addiw	a5,a5,1
    80004912:	0711                	addi	a4,a4,4
    80004914:	fef61be3          	bne	a2,a5,8000490a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004918:	0621                	addi	a2,a2,8
    8000491a:	060a                	slli	a2,a2,0x2
    8000491c:	0001d797          	auipc	a5,0x1d
    80004920:	49478793          	addi	a5,a5,1172 # 80021db0 <log>
    80004924:	963e                	add	a2,a2,a5
    80004926:	44dc                	lw	a5,12(s1)
    80004928:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000492a:	8526                	mv	a0,s1
    8000492c:	fffff097          	auipc	ra,0xfffff
    80004930:	daa080e7          	jalr	-598(ra) # 800036d6 <bpin>
    log.lh.n++;
    80004934:	0001d717          	auipc	a4,0x1d
    80004938:	47c70713          	addi	a4,a4,1148 # 80021db0 <log>
    8000493c:	575c                	lw	a5,44(a4)
    8000493e:	2785                	addiw	a5,a5,1
    80004940:	d75c                	sw	a5,44(a4)
    80004942:	a835                	j	8000497e <log_write+0xca>
    panic("too big a transaction");
    80004944:	00004517          	auipc	a0,0x4
    80004948:	dcc50513          	addi	a0,a0,-564 # 80008710 <syscalls+0x1f0>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	bf2080e7          	jalr	-1038(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004954:	00004517          	auipc	a0,0x4
    80004958:	dd450513          	addi	a0,a0,-556 # 80008728 <syscalls+0x208>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	be2080e7          	jalr	-1054(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004964:	00878713          	addi	a4,a5,8
    80004968:	00271693          	slli	a3,a4,0x2
    8000496c:	0001d717          	auipc	a4,0x1d
    80004970:	44470713          	addi	a4,a4,1092 # 80021db0 <log>
    80004974:	9736                	add	a4,a4,a3
    80004976:	44d4                	lw	a3,12(s1)
    80004978:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000497a:	faf608e3          	beq	a2,a5,8000492a <log_write+0x76>
  }
  release(&log.lock);
    8000497e:	0001d517          	auipc	a0,0x1d
    80004982:	43250513          	addi	a0,a0,1074 # 80021db0 <log>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	312080e7          	jalr	786(ra) # 80000c98 <release>
}
    8000498e:	60e2                	ld	ra,24(sp)
    80004990:	6442                	ld	s0,16(sp)
    80004992:	64a2                	ld	s1,8(sp)
    80004994:	6902                	ld	s2,0(sp)
    80004996:	6105                	addi	sp,sp,32
    80004998:	8082                	ret

000000008000499a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000499a:	1101                	addi	sp,sp,-32
    8000499c:	ec06                	sd	ra,24(sp)
    8000499e:	e822                	sd	s0,16(sp)
    800049a0:	e426                	sd	s1,8(sp)
    800049a2:	e04a                	sd	s2,0(sp)
    800049a4:	1000                	addi	s0,sp,32
    800049a6:	84aa                	mv	s1,a0
    800049a8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049aa:	00004597          	auipc	a1,0x4
    800049ae:	d9e58593          	addi	a1,a1,-610 # 80008748 <syscalls+0x228>
    800049b2:	0521                	addi	a0,a0,8
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	1a0080e7          	jalr	416(ra) # 80000b54 <initlock>
  lk->name = name;
    800049bc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049c0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c4:	0204a423          	sw	zero,40(s1)
}
    800049c8:	60e2                	ld	ra,24(sp)
    800049ca:	6442                	ld	s0,16(sp)
    800049cc:	64a2                	ld	s1,8(sp)
    800049ce:	6902                	ld	s2,0(sp)
    800049d0:	6105                	addi	sp,sp,32
    800049d2:	8082                	ret

00000000800049d4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049d4:	1101                	addi	sp,sp,-32
    800049d6:	ec06                	sd	ra,24(sp)
    800049d8:	e822                	sd	s0,16(sp)
    800049da:	e426                	sd	s1,8(sp)
    800049dc:	e04a                	sd	s2,0(sp)
    800049de:	1000                	addi	s0,sp,32
    800049e0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049e2:	00850913          	addi	s2,a0,8
    800049e6:	854a                	mv	a0,s2
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	1fc080e7          	jalr	508(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800049f0:	409c                	lw	a5,0(s1)
    800049f2:	cb89                	beqz	a5,80004a04 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049f4:	85ca                	mv	a1,s2
    800049f6:	8526                	mv	a0,s1
    800049f8:	ffffe097          	auipc	ra,0xffffe
    800049fc:	c2a080e7          	jalr	-982(ra) # 80002622 <sleep>
  while (lk->locked) {
    80004a00:	409c                	lw	a5,0(s1)
    80004a02:	fbed                	bnez	a5,800049f4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a04:	4785                	li	a5,1
    80004a06:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a08:	ffffd097          	auipc	ra,0xffffd
    80004a0c:	406080e7          	jalr	1030(ra) # 80001e0e <myproc>
    80004a10:	591c                	lw	a5,48(a0)
    80004a12:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a14:	854a                	mv	a0,s2
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	282080e7          	jalr	642(ra) # 80000c98 <release>
}
    80004a1e:	60e2                	ld	ra,24(sp)
    80004a20:	6442                	ld	s0,16(sp)
    80004a22:	64a2                	ld	s1,8(sp)
    80004a24:	6902                	ld	s2,0(sp)
    80004a26:	6105                	addi	sp,sp,32
    80004a28:	8082                	ret

0000000080004a2a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a2a:	1101                	addi	sp,sp,-32
    80004a2c:	ec06                	sd	ra,24(sp)
    80004a2e:	e822                	sd	s0,16(sp)
    80004a30:	e426                	sd	s1,8(sp)
    80004a32:	e04a                	sd	s2,0(sp)
    80004a34:	1000                	addi	s0,sp,32
    80004a36:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a38:	00850913          	addi	s2,a0,8
    80004a3c:	854a                	mv	a0,s2
    80004a3e:	ffffc097          	auipc	ra,0xffffc
    80004a42:	1a6080e7          	jalr	422(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a46:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a4a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a4e:	8526                	mv	a0,s1
    80004a50:	ffffe097          	auipc	ra,0xffffe
    80004a54:	d70080e7          	jalr	-656(ra) # 800027c0 <wakeup>
  release(&lk->lk);
    80004a58:	854a                	mv	a0,s2
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	23e080e7          	jalr	574(ra) # 80000c98 <release>
}
    80004a62:	60e2                	ld	ra,24(sp)
    80004a64:	6442                	ld	s0,16(sp)
    80004a66:	64a2                	ld	s1,8(sp)
    80004a68:	6902                	ld	s2,0(sp)
    80004a6a:	6105                	addi	sp,sp,32
    80004a6c:	8082                	ret

0000000080004a6e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a6e:	7179                	addi	sp,sp,-48
    80004a70:	f406                	sd	ra,40(sp)
    80004a72:	f022                	sd	s0,32(sp)
    80004a74:	ec26                	sd	s1,24(sp)
    80004a76:	e84a                	sd	s2,16(sp)
    80004a78:	e44e                	sd	s3,8(sp)
    80004a7a:	1800                	addi	s0,sp,48
    80004a7c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a7e:	00850913          	addi	s2,a0,8
    80004a82:	854a                	mv	a0,s2
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	160080e7          	jalr	352(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a8c:	409c                	lw	a5,0(s1)
    80004a8e:	ef99                	bnez	a5,80004aac <holdingsleep+0x3e>
    80004a90:	4481                	li	s1,0
  release(&lk->lk);
    80004a92:	854a                	mv	a0,s2
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	204080e7          	jalr	516(ra) # 80000c98 <release>
  return r;
}
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	70a2                	ld	ra,40(sp)
    80004aa0:	7402                	ld	s0,32(sp)
    80004aa2:	64e2                	ld	s1,24(sp)
    80004aa4:	6942                	ld	s2,16(sp)
    80004aa6:	69a2                	ld	s3,8(sp)
    80004aa8:	6145                	addi	sp,sp,48
    80004aaa:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aac:	0284a983          	lw	s3,40(s1)
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	35e080e7          	jalr	862(ra) # 80001e0e <myproc>
    80004ab8:	5904                	lw	s1,48(a0)
    80004aba:	413484b3          	sub	s1,s1,s3
    80004abe:	0014b493          	seqz	s1,s1
    80004ac2:	bfc1                	j	80004a92 <holdingsleep+0x24>

0000000080004ac4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ac4:	1141                	addi	sp,sp,-16
    80004ac6:	e406                	sd	ra,8(sp)
    80004ac8:	e022                	sd	s0,0(sp)
    80004aca:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004acc:	00004597          	auipc	a1,0x4
    80004ad0:	c8c58593          	addi	a1,a1,-884 # 80008758 <syscalls+0x238>
    80004ad4:	0001d517          	auipc	a0,0x1d
    80004ad8:	42450513          	addi	a0,a0,1060 # 80021ef8 <ftable>
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	078080e7          	jalr	120(ra) # 80000b54 <initlock>
}
    80004ae4:	60a2                	ld	ra,8(sp)
    80004ae6:	6402                	ld	s0,0(sp)
    80004ae8:	0141                	addi	sp,sp,16
    80004aea:	8082                	ret

0000000080004aec <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004aec:	1101                	addi	sp,sp,-32
    80004aee:	ec06                	sd	ra,24(sp)
    80004af0:	e822                	sd	s0,16(sp)
    80004af2:	e426                	sd	s1,8(sp)
    80004af4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004af6:	0001d517          	auipc	a0,0x1d
    80004afa:	40250513          	addi	a0,a0,1026 # 80021ef8 <ftable>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	0e6080e7          	jalr	230(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b06:	0001d497          	auipc	s1,0x1d
    80004b0a:	40a48493          	addi	s1,s1,1034 # 80021f10 <ftable+0x18>
    80004b0e:	0001e717          	auipc	a4,0x1e
    80004b12:	3a270713          	addi	a4,a4,930 # 80022eb0 <ftable+0xfb8>
    if(f->ref == 0){
    80004b16:	40dc                	lw	a5,4(s1)
    80004b18:	cf99                	beqz	a5,80004b36 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b1a:	02848493          	addi	s1,s1,40
    80004b1e:	fee49ce3          	bne	s1,a4,80004b16 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b22:	0001d517          	auipc	a0,0x1d
    80004b26:	3d650513          	addi	a0,a0,982 # 80021ef8 <ftable>
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	16e080e7          	jalr	366(ra) # 80000c98 <release>
  return 0;
    80004b32:	4481                	li	s1,0
    80004b34:	a819                	j	80004b4a <filealloc+0x5e>
      f->ref = 1;
    80004b36:	4785                	li	a5,1
    80004b38:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b3a:	0001d517          	auipc	a0,0x1d
    80004b3e:	3be50513          	addi	a0,a0,958 # 80021ef8 <ftable>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	156080e7          	jalr	342(ra) # 80000c98 <release>
}
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	60e2                	ld	ra,24(sp)
    80004b4e:	6442                	ld	s0,16(sp)
    80004b50:	64a2                	ld	s1,8(sp)
    80004b52:	6105                	addi	sp,sp,32
    80004b54:	8082                	ret

0000000080004b56 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b56:	1101                	addi	sp,sp,-32
    80004b58:	ec06                	sd	ra,24(sp)
    80004b5a:	e822                	sd	s0,16(sp)
    80004b5c:	e426                	sd	s1,8(sp)
    80004b5e:	1000                	addi	s0,sp,32
    80004b60:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b62:	0001d517          	auipc	a0,0x1d
    80004b66:	39650513          	addi	a0,a0,918 # 80021ef8 <ftable>
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	07a080e7          	jalr	122(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b72:	40dc                	lw	a5,4(s1)
    80004b74:	02f05263          	blez	a5,80004b98 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b78:	2785                	addiw	a5,a5,1
    80004b7a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b7c:	0001d517          	auipc	a0,0x1d
    80004b80:	37c50513          	addi	a0,a0,892 # 80021ef8 <ftable>
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	114080e7          	jalr	276(ra) # 80000c98 <release>
  return f;
}
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	60e2                	ld	ra,24(sp)
    80004b90:	6442                	ld	s0,16(sp)
    80004b92:	64a2                	ld	s1,8(sp)
    80004b94:	6105                	addi	sp,sp,32
    80004b96:	8082                	ret
    panic("filedup");
    80004b98:	00004517          	auipc	a0,0x4
    80004b9c:	bc850513          	addi	a0,a0,-1080 # 80008760 <syscalls+0x240>
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	99e080e7          	jalr	-1634(ra) # 8000053e <panic>

0000000080004ba8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ba8:	7139                	addi	sp,sp,-64
    80004baa:	fc06                	sd	ra,56(sp)
    80004bac:	f822                	sd	s0,48(sp)
    80004bae:	f426                	sd	s1,40(sp)
    80004bb0:	f04a                	sd	s2,32(sp)
    80004bb2:	ec4e                	sd	s3,24(sp)
    80004bb4:	e852                	sd	s4,16(sp)
    80004bb6:	e456                	sd	s5,8(sp)
    80004bb8:	0080                	addi	s0,sp,64
    80004bba:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bbc:	0001d517          	auipc	a0,0x1d
    80004bc0:	33c50513          	addi	a0,a0,828 # 80021ef8 <ftable>
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	020080e7          	jalr	32(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004bcc:	40dc                	lw	a5,4(s1)
    80004bce:	06f05163          	blez	a5,80004c30 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bd2:	37fd                	addiw	a5,a5,-1
    80004bd4:	0007871b          	sext.w	a4,a5
    80004bd8:	c0dc                	sw	a5,4(s1)
    80004bda:	06e04363          	bgtz	a4,80004c40 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bde:	0004a903          	lw	s2,0(s1)
    80004be2:	0094ca83          	lbu	s5,9(s1)
    80004be6:	0104ba03          	ld	s4,16(s1)
    80004bea:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bee:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bf2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bf6:	0001d517          	auipc	a0,0x1d
    80004bfa:	30250513          	addi	a0,a0,770 # 80021ef8 <ftable>
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	09a080e7          	jalr	154(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004c06:	4785                	li	a5,1
    80004c08:	04f90d63          	beq	s2,a5,80004c62 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c0c:	3979                	addiw	s2,s2,-2
    80004c0e:	4785                	li	a5,1
    80004c10:	0527e063          	bltu	a5,s2,80004c50 <fileclose+0xa8>
    begin_op();
    80004c14:	00000097          	auipc	ra,0x0
    80004c18:	ac8080e7          	jalr	-1336(ra) # 800046dc <begin_op>
    iput(ff.ip);
    80004c1c:	854e                	mv	a0,s3
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	2a6080e7          	jalr	678(ra) # 80003ec4 <iput>
    end_op();
    80004c26:	00000097          	auipc	ra,0x0
    80004c2a:	b36080e7          	jalr	-1226(ra) # 8000475c <end_op>
    80004c2e:	a00d                	j	80004c50 <fileclose+0xa8>
    panic("fileclose");
    80004c30:	00004517          	auipc	a0,0x4
    80004c34:	b3850513          	addi	a0,a0,-1224 # 80008768 <syscalls+0x248>
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	906080e7          	jalr	-1786(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c40:	0001d517          	auipc	a0,0x1d
    80004c44:	2b850513          	addi	a0,a0,696 # 80021ef8 <ftable>
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	050080e7          	jalr	80(ra) # 80000c98 <release>
  }
}
    80004c50:	70e2                	ld	ra,56(sp)
    80004c52:	7442                	ld	s0,48(sp)
    80004c54:	74a2                	ld	s1,40(sp)
    80004c56:	7902                	ld	s2,32(sp)
    80004c58:	69e2                	ld	s3,24(sp)
    80004c5a:	6a42                	ld	s4,16(sp)
    80004c5c:	6aa2                	ld	s5,8(sp)
    80004c5e:	6121                	addi	sp,sp,64
    80004c60:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c62:	85d6                	mv	a1,s5
    80004c64:	8552                	mv	a0,s4
    80004c66:	00000097          	auipc	ra,0x0
    80004c6a:	34c080e7          	jalr	844(ra) # 80004fb2 <pipeclose>
    80004c6e:	b7cd                	j	80004c50 <fileclose+0xa8>

0000000080004c70 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c70:	715d                	addi	sp,sp,-80
    80004c72:	e486                	sd	ra,72(sp)
    80004c74:	e0a2                	sd	s0,64(sp)
    80004c76:	fc26                	sd	s1,56(sp)
    80004c78:	f84a                	sd	s2,48(sp)
    80004c7a:	f44e                	sd	s3,40(sp)
    80004c7c:	0880                	addi	s0,sp,80
    80004c7e:	84aa                	mv	s1,a0
    80004c80:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	18c080e7          	jalr	396(ra) # 80001e0e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c8a:	409c                	lw	a5,0(s1)
    80004c8c:	37f9                	addiw	a5,a5,-2
    80004c8e:	4705                	li	a4,1
    80004c90:	04f76763          	bltu	a4,a5,80004cde <filestat+0x6e>
    80004c94:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c96:	6c88                	ld	a0,24(s1)
    80004c98:	fffff097          	auipc	ra,0xfffff
    80004c9c:	072080e7          	jalr	114(ra) # 80003d0a <ilock>
    stati(f->ip, &st);
    80004ca0:	fb840593          	addi	a1,s0,-72
    80004ca4:	6c88                	ld	a0,24(s1)
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	2ee080e7          	jalr	750(ra) # 80003f94 <stati>
    iunlock(f->ip);
    80004cae:	6c88                	ld	a0,24(s1)
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	11c080e7          	jalr	284(ra) # 80003dcc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cb8:	46e1                	li	a3,24
    80004cba:	fb840613          	addi	a2,s0,-72
    80004cbe:	85ce                	mv	a1,s3
    80004cc0:	05093503          	ld	a0,80(s2)
    80004cc4:	ffffd097          	auipc	ra,0xffffd
    80004cc8:	9ae080e7          	jalr	-1618(ra) # 80001672 <copyout>
    80004ccc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cd0:	60a6                	ld	ra,72(sp)
    80004cd2:	6406                	ld	s0,64(sp)
    80004cd4:	74e2                	ld	s1,56(sp)
    80004cd6:	7942                	ld	s2,48(sp)
    80004cd8:	79a2                	ld	s3,40(sp)
    80004cda:	6161                	addi	sp,sp,80
    80004cdc:	8082                	ret
  return -1;
    80004cde:	557d                	li	a0,-1
    80004ce0:	bfc5                	j	80004cd0 <filestat+0x60>

0000000080004ce2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ce2:	7179                	addi	sp,sp,-48
    80004ce4:	f406                	sd	ra,40(sp)
    80004ce6:	f022                	sd	s0,32(sp)
    80004ce8:	ec26                	sd	s1,24(sp)
    80004cea:	e84a                	sd	s2,16(sp)
    80004cec:	e44e                	sd	s3,8(sp)
    80004cee:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cf0:	00854783          	lbu	a5,8(a0)
    80004cf4:	c3d5                	beqz	a5,80004d98 <fileread+0xb6>
    80004cf6:	84aa                	mv	s1,a0
    80004cf8:	89ae                	mv	s3,a1
    80004cfa:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cfc:	411c                	lw	a5,0(a0)
    80004cfe:	4705                	li	a4,1
    80004d00:	04e78963          	beq	a5,a4,80004d52 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d04:	470d                	li	a4,3
    80004d06:	04e78d63          	beq	a5,a4,80004d60 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d0a:	4709                	li	a4,2
    80004d0c:	06e79e63          	bne	a5,a4,80004d88 <fileread+0xa6>
    ilock(f->ip);
    80004d10:	6d08                	ld	a0,24(a0)
    80004d12:	fffff097          	auipc	ra,0xfffff
    80004d16:	ff8080e7          	jalr	-8(ra) # 80003d0a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d1a:	874a                	mv	a4,s2
    80004d1c:	5094                	lw	a3,32(s1)
    80004d1e:	864e                	mv	a2,s3
    80004d20:	4585                	li	a1,1
    80004d22:	6c88                	ld	a0,24(s1)
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	29a080e7          	jalr	666(ra) # 80003fbe <readi>
    80004d2c:	892a                	mv	s2,a0
    80004d2e:	00a05563          	blez	a0,80004d38 <fileread+0x56>
      f->off += r;
    80004d32:	509c                	lw	a5,32(s1)
    80004d34:	9fa9                	addw	a5,a5,a0
    80004d36:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d38:	6c88                	ld	a0,24(s1)
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	092080e7          	jalr	146(ra) # 80003dcc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d42:	854a                	mv	a0,s2
    80004d44:	70a2                	ld	ra,40(sp)
    80004d46:	7402                	ld	s0,32(sp)
    80004d48:	64e2                	ld	s1,24(sp)
    80004d4a:	6942                	ld	s2,16(sp)
    80004d4c:	69a2                	ld	s3,8(sp)
    80004d4e:	6145                	addi	sp,sp,48
    80004d50:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d52:	6908                	ld	a0,16(a0)
    80004d54:	00000097          	auipc	ra,0x0
    80004d58:	3c8080e7          	jalr	968(ra) # 8000511c <piperead>
    80004d5c:	892a                	mv	s2,a0
    80004d5e:	b7d5                	j	80004d42 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d60:	02451783          	lh	a5,36(a0)
    80004d64:	03079693          	slli	a3,a5,0x30
    80004d68:	92c1                	srli	a3,a3,0x30
    80004d6a:	4725                	li	a4,9
    80004d6c:	02d76863          	bltu	a4,a3,80004d9c <fileread+0xba>
    80004d70:	0792                	slli	a5,a5,0x4
    80004d72:	0001d717          	auipc	a4,0x1d
    80004d76:	0e670713          	addi	a4,a4,230 # 80021e58 <devsw>
    80004d7a:	97ba                	add	a5,a5,a4
    80004d7c:	639c                	ld	a5,0(a5)
    80004d7e:	c38d                	beqz	a5,80004da0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d80:	4505                	li	a0,1
    80004d82:	9782                	jalr	a5
    80004d84:	892a                	mv	s2,a0
    80004d86:	bf75                	j	80004d42 <fileread+0x60>
    panic("fileread");
    80004d88:	00004517          	auipc	a0,0x4
    80004d8c:	9f050513          	addi	a0,a0,-1552 # 80008778 <syscalls+0x258>
    80004d90:	ffffb097          	auipc	ra,0xffffb
    80004d94:	7ae080e7          	jalr	1966(ra) # 8000053e <panic>
    return -1;
    80004d98:	597d                	li	s2,-1
    80004d9a:	b765                	j	80004d42 <fileread+0x60>
      return -1;
    80004d9c:	597d                	li	s2,-1
    80004d9e:	b755                	j	80004d42 <fileread+0x60>
    80004da0:	597d                	li	s2,-1
    80004da2:	b745                	j	80004d42 <fileread+0x60>

0000000080004da4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004da4:	715d                	addi	sp,sp,-80
    80004da6:	e486                	sd	ra,72(sp)
    80004da8:	e0a2                	sd	s0,64(sp)
    80004daa:	fc26                	sd	s1,56(sp)
    80004dac:	f84a                	sd	s2,48(sp)
    80004dae:	f44e                	sd	s3,40(sp)
    80004db0:	f052                	sd	s4,32(sp)
    80004db2:	ec56                	sd	s5,24(sp)
    80004db4:	e85a                	sd	s6,16(sp)
    80004db6:	e45e                	sd	s7,8(sp)
    80004db8:	e062                	sd	s8,0(sp)
    80004dba:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dbc:	00954783          	lbu	a5,9(a0)
    80004dc0:	10078663          	beqz	a5,80004ecc <filewrite+0x128>
    80004dc4:	892a                	mv	s2,a0
    80004dc6:	8aae                	mv	s5,a1
    80004dc8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dca:	411c                	lw	a5,0(a0)
    80004dcc:	4705                	li	a4,1
    80004dce:	02e78263          	beq	a5,a4,80004df2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dd2:	470d                	li	a4,3
    80004dd4:	02e78663          	beq	a5,a4,80004e00 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dd8:	4709                	li	a4,2
    80004dda:	0ee79163          	bne	a5,a4,80004ebc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dde:	0ac05d63          	blez	a2,80004e98 <filewrite+0xf4>
    int i = 0;
    80004de2:	4981                	li	s3,0
    80004de4:	6b05                	lui	s6,0x1
    80004de6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004dea:	6b85                	lui	s7,0x1
    80004dec:	c00b8b9b          	addiw	s7,s7,-1024
    80004df0:	a861                	j	80004e88 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004df2:	6908                	ld	a0,16(a0)
    80004df4:	00000097          	auipc	ra,0x0
    80004df8:	22e080e7          	jalr	558(ra) # 80005022 <pipewrite>
    80004dfc:	8a2a                	mv	s4,a0
    80004dfe:	a045                	j	80004e9e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e00:	02451783          	lh	a5,36(a0)
    80004e04:	03079693          	slli	a3,a5,0x30
    80004e08:	92c1                	srli	a3,a3,0x30
    80004e0a:	4725                	li	a4,9
    80004e0c:	0cd76263          	bltu	a4,a3,80004ed0 <filewrite+0x12c>
    80004e10:	0792                	slli	a5,a5,0x4
    80004e12:	0001d717          	auipc	a4,0x1d
    80004e16:	04670713          	addi	a4,a4,70 # 80021e58 <devsw>
    80004e1a:	97ba                	add	a5,a5,a4
    80004e1c:	679c                	ld	a5,8(a5)
    80004e1e:	cbdd                	beqz	a5,80004ed4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e20:	4505                	li	a0,1
    80004e22:	9782                	jalr	a5
    80004e24:	8a2a                	mv	s4,a0
    80004e26:	a8a5                	j	80004e9e <filewrite+0xfa>
    80004e28:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e2c:	00000097          	auipc	ra,0x0
    80004e30:	8b0080e7          	jalr	-1872(ra) # 800046dc <begin_op>
      ilock(f->ip);
    80004e34:	01893503          	ld	a0,24(s2)
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	ed2080e7          	jalr	-302(ra) # 80003d0a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e40:	8762                	mv	a4,s8
    80004e42:	02092683          	lw	a3,32(s2)
    80004e46:	01598633          	add	a2,s3,s5
    80004e4a:	4585                	li	a1,1
    80004e4c:	01893503          	ld	a0,24(s2)
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	266080e7          	jalr	614(ra) # 800040b6 <writei>
    80004e58:	84aa                	mv	s1,a0
    80004e5a:	00a05763          	blez	a0,80004e68 <filewrite+0xc4>
        f->off += r;
    80004e5e:	02092783          	lw	a5,32(s2)
    80004e62:	9fa9                	addw	a5,a5,a0
    80004e64:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e68:	01893503          	ld	a0,24(s2)
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	f60080e7          	jalr	-160(ra) # 80003dcc <iunlock>
      end_op();
    80004e74:	00000097          	auipc	ra,0x0
    80004e78:	8e8080e7          	jalr	-1816(ra) # 8000475c <end_op>

      if(r != n1){
    80004e7c:	009c1f63          	bne	s8,s1,80004e9a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e80:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e84:	0149db63          	bge	s3,s4,80004e9a <filewrite+0xf6>
      int n1 = n - i;
    80004e88:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e8c:	84be                	mv	s1,a5
    80004e8e:	2781                	sext.w	a5,a5
    80004e90:	f8fb5ce3          	bge	s6,a5,80004e28 <filewrite+0x84>
    80004e94:	84de                	mv	s1,s7
    80004e96:	bf49                	j	80004e28 <filewrite+0x84>
    int i = 0;
    80004e98:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e9a:	013a1f63          	bne	s4,s3,80004eb8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e9e:	8552                	mv	a0,s4
    80004ea0:	60a6                	ld	ra,72(sp)
    80004ea2:	6406                	ld	s0,64(sp)
    80004ea4:	74e2                	ld	s1,56(sp)
    80004ea6:	7942                	ld	s2,48(sp)
    80004ea8:	79a2                	ld	s3,40(sp)
    80004eaa:	7a02                	ld	s4,32(sp)
    80004eac:	6ae2                	ld	s5,24(sp)
    80004eae:	6b42                	ld	s6,16(sp)
    80004eb0:	6ba2                	ld	s7,8(sp)
    80004eb2:	6c02                	ld	s8,0(sp)
    80004eb4:	6161                	addi	sp,sp,80
    80004eb6:	8082                	ret
    ret = (i == n ? n : -1);
    80004eb8:	5a7d                	li	s4,-1
    80004eba:	b7d5                	j	80004e9e <filewrite+0xfa>
    panic("filewrite");
    80004ebc:	00004517          	auipc	a0,0x4
    80004ec0:	8cc50513          	addi	a0,a0,-1844 # 80008788 <syscalls+0x268>
    80004ec4:	ffffb097          	auipc	ra,0xffffb
    80004ec8:	67a080e7          	jalr	1658(ra) # 8000053e <panic>
    return -1;
    80004ecc:	5a7d                	li	s4,-1
    80004ece:	bfc1                	j	80004e9e <filewrite+0xfa>
      return -1;
    80004ed0:	5a7d                	li	s4,-1
    80004ed2:	b7f1                	j	80004e9e <filewrite+0xfa>
    80004ed4:	5a7d                	li	s4,-1
    80004ed6:	b7e1                	j	80004e9e <filewrite+0xfa>

0000000080004ed8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ed8:	7179                	addi	sp,sp,-48
    80004eda:	f406                	sd	ra,40(sp)
    80004edc:	f022                	sd	s0,32(sp)
    80004ede:	ec26                	sd	s1,24(sp)
    80004ee0:	e84a                	sd	s2,16(sp)
    80004ee2:	e44e                	sd	s3,8(sp)
    80004ee4:	e052                	sd	s4,0(sp)
    80004ee6:	1800                	addi	s0,sp,48
    80004ee8:	84aa                	mv	s1,a0
    80004eea:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004eec:	0005b023          	sd	zero,0(a1)
    80004ef0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ef4:	00000097          	auipc	ra,0x0
    80004ef8:	bf8080e7          	jalr	-1032(ra) # 80004aec <filealloc>
    80004efc:	e088                	sd	a0,0(s1)
    80004efe:	c551                	beqz	a0,80004f8a <pipealloc+0xb2>
    80004f00:	00000097          	auipc	ra,0x0
    80004f04:	bec080e7          	jalr	-1044(ra) # 80004aec <filealloc>
    80004f08:	00aa3023          	sd	a0,0(s4)
    80004f0c:	c92d                	beqz	a0,80004f7e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	be6080e7          	jalr	-1050(ra) # 80000af4 <kalloc>
    80004f16:	892a                	mv	s2,a0
    80004f18:	c125                	beqz	a0,80004f78 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f1a:	4985                	li	s3,1
    80004f1c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f20:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f24:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f28:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f2c:	00004597          	auipc	a1,0x4
    80004f30:	86c58593          	addi	a1,a1,-1940 # 80008798 <syscalls+0x278>
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	c20080e7          	jalr	-992(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004f3c:	609c                	ld	a5,0(s1)
    80004f3e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f42:	609c                	ld	a5,0(s1)
    80004f44:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f48:	609c                	ld	a5,0(s1)
    80004f4a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f4e:	609c                	ld	a5,0(s1)
    80004f50:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f54:	000a3783          	ld	a5,0(s4)
    80004f58:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f5c:	000a3783          	ld	a5,0(s4)
    80004f60:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f64:	000a3783          	ld	a5,0(s4)
    80004f68:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f6c:	000a3783          	ld	a5,0(s4)
    80004f70:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f74:	4501                	li	a0,0
    80004f76:	a025                	j	80004f9e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f78:	6088                	ld	a0,0(s1)
    80004f7a:	e501                	bnez	a0,80004f82 <pipealloc+0xaa>
    80004f7c:	a039                	j	80004f8a <pipealloc+0xb2>
    80004f7e:	6088                	ld	a0,0(s1)
    80004f80:	c51d                	beqz	a0,80004fae <pipealloc+0xd6>
    fileclose(*f0);
    80004f82:	00000097          	auipc	ra,0x0
    80004f86:	c26080e7          	jalr	-986(ra) # 80004ba8 <fileclose>
  if(*f1)
    80004f8a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f8e:	557d                	li	a0,-1
  if(*f1)
    80004f90:	c799                	beqz	a5,80004f9e <pipealloc+0xc6>
    fileclose(*f1);
    80004f92:	853e                	mv	a0,a5
    80004f94:	00000097          	auipc	ra,0x0
    80004f98:	c14080e7          	jalr	-1004(ra) # 80004ba8 <fileclose>
  return -1;
    80004f9c:	557d                	li	a0,-1
}
    80004f9e:	70a2                	ld	ra,40(sp)
    80004fa0:	7402                	ld	s0,32(sp)
    80004fa2:	64e2                	ld	s1,24(sp)
    80004fa4:	6942                	ld	s2,16(sp)
    80004fa6:	69a2                	ld	s3,8(sp)
    80004fa8:	6a02                	ld	s4,0(sp)
    80004faa:	6145                	addi	sp,sp,48
    80004fac:	8082                	ret
  return -1;
    80004fae:	557d                	li	a0,-1
    80004fb0:	b7fd                	j	80004f9e <pipealloc+0xc6>

0000000080004fb2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fb2:	1101                	addi	sp,sp,-32
    80004fb4:	ec06                	sd	ra,24(sp)
    80004fb6:	e822                	sd	s0,16(sp)
    80004fb8:	e426                	sd	s1,8(sp)
    80004fba:	e04a                	sd	s2,0(sp)
    80004fbc:	1000                	addi	s0,sp,32
    80004fbe:	84aa                	mv	s1,a0
    80004fc0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	c22080e7          	jalr	-990(ra) # 80000be4 <acquire>
  if(writable){
    80004fca:	02090d63          	beqz	s2,80005004 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fce:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fd2:	21848513          	addi	a0,s1,536
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	7ea080e7          	jalr	2026(ra) # 800027c0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fde:	2204b783          	ld	a5,544(s1)
    80004fe2:	eb95                	bnez	a5,80005016 <pipeclose+0x64>
    release(&pi->lock);
    80004fe4:	8526                	mv	a0,s1
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	cb2080e7          	jalr	-846(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004fee:	8526                	mv	a0,s1
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	a08080e7          	jalr	-1528(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ff8:	60e2                	ld	ra,24(sp)
    80004ffa:	6442                	ld	s0,16(sp)
    80004ffc:	64a2                	ld	s1,8(sp)
    80004ffe:	6902                	ld	s2,0(sp)
    80005000:	6105                	addi	sp,sp,32
    80005002:	8082                	ret
    pi->readopen = 0;
    80005004:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005008:	21c48513          	addi	a0,s1,540
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	7b4080e7          	jalr	1972(ra) # 800027c0 <wakeup>
    80005014:	b7e9                	j	80004fde <pipeclose+0x2c>
    release(&pi->lock);
    80005016:	8526                	mv	a0,s1
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	c80080e7          	jalr	-896(ra) # 80000c98 <release>
}
    80005020:	bfe1                	j	80004ff8 <pipeclose+0x46>

0000000080005022 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005022:	7159                	addi	sp,sp,-112
    80005024:	f486                	sd	ra,104(sp)
    80005026:	f0a2                	sd	s0,96(sp)
    80005028:	eca6                	sd	s1,88(sp)
    8000502a:	e8ca                	sd	s2,80(sp)
    8000502c:	e4ce                	sd	s3,72(sp)
    8000502e:	e0d2                	sd	s4,64(sp)
    80005030:	fc56                	sd	s5,56(sp)
    80005032:	f85a                	sd	s6,48(sp)
    80005034:	f45e                	sd	s7,40(sp)
    80005036:	f062                	sd	s8,32(sp)
    80005038:	ec66                	sd	s9,24(sp)
    8000503a:	1880                	addi	s0,sp,112
    8000503c:	84aa                	mv	s1,a0
    8000503e:	8aae                	mv	s5,a1
    80005040:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005042:	ffffd097          	auipc	ra,0xffffd
    80005046:	dcc080e7          	jalr	-564(ra) # 80001e0e <myproc>
    8000504a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000504c:	8526                	mv	a0,s1
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	b96080e7          	jalr	-1130(ra) # 80000be4 <acquire>
  while(i < n){
    80005056:	0d405163          	blez	s4,80005118 <pipewrite+0xf6>
    8000505a:	8ba6                	mv	s7,s1
  int i = 0;
    8000505c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000505e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005060:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005064:	21c48c13          	addi	s8,s1,540
    80005068:	a08d                	j	800050ca <pipewrite+0xa8>
      release(&pi->lock);
    8000506a:	8526                	mv	a0,s1
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	c2c080e7          	jalr	-980(ra) # 80000c98 <release>
      return -1;
    80005074:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005076:	854a                	mv	a0,s2
    80005078:	70a6                	ld	ra,104(sp)
    8000507a:	7406                	ld	s0,96(sp)
    8000507c:	64e6                	ld	s1,88(sp)
    8000507e:	6946                	ld	s2,80(sp)
    80005080:	69a6                	ld	s3,72(sp)
    80005082:	6a06                	ld	s4,64(sp)
    80005084:	7ae2                	ld	s5,56(sp)
    80005086:	7b42                	ld	s6,48(sp)
    80005088:	7ba2                	ld	s7,40(sp)
    8000508a:	7c02                	ld	s8,32(sp)
    8000508c:	6ce2                	ld	s9,24(sp)
    8000508e:	6165                	addi	sp,sp,112
    80005090:	8082                	ret
      wakeup(&pi->nread);
    80005092:	8566                	mv	a0,s9
    80005094:	ffffd097          	auipc	ra,0xffffd
    80005098:	72c080e7          	jalr	1836(ra) # 800027c0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000509c:	85de                	mv	a1,s7
    8000509e:	8562                	mv	a0,s8
    800050a0:	ffffd097          	auipc	ra,0xffffd
    800050a4:	582080e7          	jalr	1410(ra) # 80002622 <sleep>
    800050a8:	a839                	j	800050c6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050aa:	21c4a783          	lw	a5,540(s1)
    800050ae:	0017871b          	addiw	a4,a5,1
    800050b2:	20e4ae23          	sw	a4,540(s1)
    800050b6:	1ff7f793          	andi	a5,a5,511
    800050ba:	97a6                	add	a5,a5,s1
    800050bc:	f9f44703          	lbu	a4,-97(s0)
    800050c0:	00e78c23          	sb	a4,24(a5)
      i++;
    800050c4:	2905                	addiw	s2,s2,1
  while(i < n){
    800050c6:	03495d63          	bge	s2,s4,80005100 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800050ca:	2204a783          	lw	a5,544(s1)
    800050ce:	dfd1                	beqz	a5,8000506a <pipewrite+0x48>
    800050d0:	0289a783          	lw	a5,40(s3)
    800050d4:	fbd9                	bnez	a5,8000506a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050d6:	2184a783          	lw	a5,536(s1)
    800050da:	21c4a703          	lw	a4,540(s1)
    800050de:	2007879b          	addiw	a5,a5,512
    800050e2:	faf708e3          	beq	a4,a5,80005092 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050e6:	4685                	li	a3,1
    800050e8:	01590633          	add	a2,s2,s5
    800050ec:	f9f40593          	addi	a1,s0,-97
    800050f0:	0509b503          	ld	a0,80(s3)
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	60a080e7          	jalr	1546(ra) # 800016fe <copyin>
    800050fc:	fb6517e3          	bne	a0,s6,800050aa <pipewrite+0x88>
  wakeup(&pi->nread);
    80005100:	21848513          	addi	a0,s1,536
    80005104:	ffffd097          	auipc	ra,0xffffd
    80005108:	6bc080e7          	jalr	1724(ra) # 800027c0 <wakeup>
  release(&pi->lock);
    8000510c:	8526                	mv	a0,s1
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	b8a080e7          	jalr	-1142(ra) # 80000c98 <release>
  return i;
    80005116:	b785                	j	80005076 <pipewrite+0x54>
  int i = 0;
    80005118:	4901                	li	s2,0
    8000511a:	b7dd                	j	80005100 <pipewrite+0xde>

000000008000511c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000511c:	715d                	addi	sp,sp,-80
    8000511e:	e486                	sd	ra,72(sp)
    80005120:	e0a2                	sd	s0,64(sp)
    80005122:	fc26                	sd	s1,56(sp)
    80005124:	f84a                	sd	s2,48(sp)
    80005126:	f44e                	sd	s3,40(sp)
    80005128:	f052                	sd	s4,32(sp)
    8000512a:	ec56                	sd	s5,24(sp)
    8000512c:	e85a                	sd	s6,16(sp)
    8000512e:	0880                	addi	s0,sp,80
    80005130:	84aa                	mv	s1,a0
    80005132:	892e                	mv	s2,a1
    80005134:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	cd8080e7          	jalr	-808(ra) # 80001e0e <myproc>
    8000513e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005140:	8b26                	mv	s6,s1
    80005142:	8526                	mv	a0,s1
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	aa0080e7          	jalr	-1376(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000514c:	2184a703          	lw	a4,536(s1)
    80005150:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005154:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005158:	02f71463          	bne	a4,a5,80005180 <piperead+0x64>
    8000515c:	2244a783          	lw	a5,548(s1)
    80005160:	c385                	beqz	a5,80005180 <piperead+0x64>
    if(pr->killed){
    80005162:	028a2783          	lw	a5,40(s4)
    80005166:	ebc1                	bnez	a5,800051f6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005168:	85da                	mv	a1,s6
    8000516a:	854e                	mv	a0,s3
    8000516c:	ffffd097          	auipc	ra,0xffffd
    80005170:	4b6080e7          	jalr	1206(ra) # 80002622 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005174:	2184a703          	lw	a4,536(s1)
    80005178:	21c4a783          	lw	a5,540(s1)
    8000517c:	fef700e3          	beq	a4,a5,8000515c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005180:	09505263          	blez	s5,80005204 <piperead+0xe8>
    80005184:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005186:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005188:	2184a783          	lw	a5,536(s1)
    8000518c:	21c4a703          	lw	a4,540(s1)
    80005190:	02f70d63          	beq	a4,a5,800051ca <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005194:	0017871b          	addiw	a4,a5,1
    80005198:	20e4ac23          	sw	a4,536(s1)
    8000519c:	1ff7f793          	andi	a5,a5,511
    800051a0:	97a6                	add	a5,a5,s1
    800051a2:	0187c783          	lbu	a5,24(a5)
    800051a6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051aa:	4685                	li	a3,1
    800051ac:	fbf40613          	addi	a2,s0,-65
    800051b0:	85ca                	mv	a1,s2
    800051b2:	050a3503          	ld	a0,80(s4)
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	4bc080e7          	jalr	1212(ra) # 80001672 <copyout>
    800051be:	01650663          	beq	a0,s6,800051ca <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c2:	2985                	addiw	s3,s3,1
    800051c4:	0905                	addi	s2,s2,1
    800051c6:	fd3a91e3          	bne	s5,s3,80005188 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051ca:	21c48513          	addi	a0,s1,540
    800051ce:	ffffd097          	auipc	ra,0xffffd
    800051d2:	5f2080e7          	jalr	1522(ra) # 800027c0 <wakeup>
  release(&pi->lock);
    800051d6:	8526                	mv	a0,s1
    800051d8:	ffffc097          	auipc	ra,0xffffc
    800051dc:	ac0080e7          	jalr	-1344(ra) # 80000c98 <release>
  return i;
}
    800051e0:	854e                	mv	a0,s3
    800051e2:	60a6                	ld	ra,72(sp)
    800051e4:	6406                	ld	s0,64(sp)
    800051e6:	74e2                	ld	s1,56(sp)
    800051e8:	7942                	ld	s2,48(sp)
    800051ea:	79a2                	ld	s3,40(sp)
    800051ec:	7a02                	ld	s4,32(sp)
    800051ee:	6ae2                	ld	s5,24(sp)
    800051f0:	6b42                	ld	s6,16(sp)
    800051f2:	6161                	addi	sp,sp,80
    800051f4:	8082                	ret
      release(&pi->lock);
    800051f6:	8526                	mv	a0,s1
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	aa0080e7          	jalr	-1376(ra) # 80000c98 <release>
      return -1;
    80005200:	59fd                	li	s3,-1
    80005202:	bff9                	j	800051e0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005204:	4981                	li	s3,0
    80005206:	b7d1                	j	800051ca <piperead+0xae>

0000000080005208 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005208:	df010113          	addi	sp,sp,-528
    8000520c:	20113423          	sd	ra,520(sp)
    80005210:	20813023          	sd	s0,512(sp)
    80005214:	ffa6                	sd	s1,504(sp)
    80005216:	fbca                	sd	s2,496(sp)
    80005218:	f7ce                	sd	s3,488(sp)
    8000521a:	f3d2                	sd	s4,480(sp)
    8000521c:	efd6                	sd	s5,472(sp)
    8000521e:	ebda                	sd	s6,464(sp)
    80005220:	e7de                	sd	s7,456(sp)
    80005222:	e3e2                	sd	s8,448(sp)
    80005224:	ff66                	sd	s9,440(sp)
    80005226:	fb6a                	sd	s10,432(sp)
    80005228:	f76e                	sd	s11,424(sp)
    8000522a:	0c00                	addi	s0,sp,528
    8000522c:	84aa                	mv	s1,a0
    8000522e:	dea43c23          	sd	a0,-520(s0)
    80005232:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005236:	ffffd097          	auipc	ra,0xffffd
    8000523a:	bd8080e7          	jalr	-1064(ra) # 80001e0e <myproc>
    8000523e:	892a                	mv	s2,a0

  begin_op();
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	49c080e7          	jalr	1180(ra) # 800046dc <begin_op>

  if((ip = namei(path)) == 0){
    80005248:	8526                	mv	a0,s1
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	276080e7          	jalr	630(ra) # 800044c0 <namei>
    80005252:	c92d                	beqz	a0,800052c4 <exec+0xbc>
    80005254:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	ab4080e7          	jalr	-1356(ra) # 80003d0a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000525e:	04000713          	li	a4,64
    80005262:	4681                	li	a3,0
    80005264:	e5040613          	addi	a2,s0,-432
    80005268:	4581                	li	a1,0
    8000526a:	8526                	mv	a0,s1
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	d52080e7          	jalr	-686(ra) # 80003fbe <readi>
    80005274:	04000793          	li	a5,64
    80005278:	00f51a63          	bne	a0,a5,8000528c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000527c:	e5042703          	lw	a4,-432(s0)
    80005280:	464c47b7          	lui	a5,0x464c4
    80005284:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005288:	04f70463          	beq	a4,a5,800052d0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000528c:	8526                	mv	a0,s1
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	cde080e7          	jalr	-802(ra) # 80003f6c <iunlockput>
    end_op();
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	4c6080e7          	jalr	1222(ra) # 8000475c <end_op>
  }
  return -1;
    8000529e:	557d                	li	a0,-1
}
    800052a0:	20813083          	ld	ra,520(sp)
    800052a4:	20013403          	ld	s0,512(sp)
    800052a8:	74fe                	ld	s1,504(sp)
    800052aa:	795e                	ld	s2,496(sp)
    800052ac:	79be                	ld	s3,488(sp)
    800052ae:	7a1e                	ld	s4,480(sp)
    800052b0:	6afe                	ld	s5,472(sp)
    800052b2:	6b5e                	ld	s6,464(sp)
    800052b4:	6bbe                	ld	s7,456(sp)
    800052b6:	6c1e                	ld	s8,448(sp)
    800052b8:	7cfa                	ld	s9,440(sp)
    800052ba:	7d5a                	ld	s10,432(sp)
    800052bc:	7dba                	ld	s11,424(sp)
    800052be:	21010113          	addi	sp,sp,528
    800052c2:	8082                	ret
    end_op();
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	498080e7          	jalr	1176(ra) # 8000475c <end_op>
    return -1;
    800052cc:	557d                	li	a0,-1
    800052ce:	bfc9                	j	800052a0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052d0:	854a                	mv	a0,s2
    800052d2:	ffffd097          	auipc	ra,0xffffd
    800052d6:	bfa080e7          	jalr	-1030(ra) # 80001ecc <proc_pagetable>
    800052da:	8baa                	mv	s7,a0
    800052dc:	d945                	beqz	a0,8000528c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052de:	e7042983          	lw	s3,-400(s0)
    800052e2:	e8845783          	lhu	a5,-376(s0)
    800052e6:	c7ad                	beqz	a5,80005350 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052e8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ea:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800052ec:	6c85                	lui	s9,0x1
    800052ee:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052f2:	def43823          	sd	a5,-528(s0)
    800052f6:	a42d                	j	80005520 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052f8:	00003517          	auipc	a0,0x3
    800052fc:	4a850513          	addi	a0,a0,1192 # 800087a0 <syscalls+0x280>
    80005300:	ffffb097          	auipc	ra,0xffffb
    80005304:	23e080e7          	jalr	574(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005308:	8756                	mv	a4,s5
    8000530a:	012d86bb          	addw	a3,s11,s2
    8000530e:	4581                	li	a1,0
    80005310:	8526                	mv	a0,s1
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	cac080e7          	jalr	-852(ra) # 80003fbe <readi>
    8000531a:	2501                	sext.w	a0,a0
    8000531c:	1aaa9963          	bne	s5,a0,800054ce <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005320:	6785                	lui	a5,0x1
    80005322:	0127893b          	addw	s2,a5,s2
    80005326:	77fd                	lui	a5,0xfffff
    80005328:	01478a3b          	addw	s4,a5,s4
    8000532c:	1f897163          	bgeu	s2,s8,8000550e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005330:	02091593          	slli	a1,s2,0x20
    80005334:	9181                	srli	a1,a1,0x20
    80005336:	95ea                	add	a1,a1,s10
    80005338:	855e                	mv	a0,s7
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	d34080e7          	jalr	-716(ra) # 8000106e <walkaddr>
    80005342:	862a                	mv	a2,a0
    if(pa == 0)
    80005344:	d955                	beqz	a0,800052f8 <exec+0xf0>
      n = PGSIZE;
    80005346:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005348:	fd9a70e3          	bgeu	s4,s9,80005308 <exec+0x100>
      n = sz - i;
    8000534c:	8ad2                	mv	s5,s4
    8000534e:	bf6d                	j	80005308 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005350:	4901                	li	s2,0
  iunlockput(ip);
    80005352:	8526                	mv	a0,s1
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	c18080e7          	jalr	-1000(ra) # 80003f6c <iunlockput>
  end_op();
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	400080e7          	jalr	1024(ra) # 8000475c <end_op>
  p = myproc();
    80005364:	ffffd097          	auipc	ra,0xffffd
    80005368:	aaa080e7          	jalr	-1366(ra) # 80001e0e <myproc>
    8000536c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000536e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005372:	6785                	lui	a5,0x1
    80005374:	17fd                	addi	a5,a5,-1
    80005376:	993e                	add	s2,s2,a5
    80005378:	757d                	lui	a0,0xfffff
    8000537a:	00a977b3          	and	a5,s2,a0
    8000537e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005382:	6609                	lui	a2,0x2
    80005384:	963e                	add	a2,a2,a5
    80005386:	85be                	mv	a1,a5
    80005388:	855e                	mv	a0,s7
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	098080e7          	jalr	152(ra) # 80001422 <uvmalloc>
    80005392:	8b2a                	mv	s6,a0
  ip = 0;
    80005394:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005396:	12050c63          	beqz	a0,800054ce <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000539a:	75f9                	lui	a1,0xffffe
    8000539c:	95aa                	add	a1,a1,a0
    8000539e:	855e                	mv	a0,s7
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	2a0080e7          	jalr	672(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800053a8:	7c7d                	lui	s8,0xfffff
    800053aa:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053ac:	e0043783          	ld	a5,-512(s0)
    800053b0:	6388                	ld	a0,0(a5)
    800053b2:	c535                	beqz	a0,8000541e <exec+0x216>
    800053b4:	e9040993          	addi	s3,s0,-368
    800053b8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053bc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053be:	ffffc097          	auipc	ra,0xffffc
    800053c2:	aa6080e7          	jalr	-1370(ra) # 80000e64 <strlen>
    800053c6:	2505                	addiw	a0,a0,1
    800053c8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053cc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053d0:	13896363          	bltu	s2,s8,800054f6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053d4:	e0043d83          	ld	s11,-512(s0)
    800053d8:	000dba03          	ld	s4,0(s11)
    800053dc:	8552                	mv	a0,s4
    800053de:	ffffc097          	auipc	ra,0xffffc
    800053e2:	a86080e7          	jalr	-1402(ra) # 80000e64 <strlen>
    800053e6:	0015069b          	addiw	a3,a0,1
    800053ea:	8652                	mv	a2,s4
    800053ec:	85ca                	mv	a1,s2
    800053ee:	855e                	mv	a0,s7
    800053f0:	ffffc097          	auipc	ra,0xffffc
    800053f4:	282080e7          	jalr	642(ra) # 80001672 <copyout>
    800053f8:	10054363          	bltz	a0,800054fe <exec+0x2f6>
    ustack[argc] = sp;
    800053fc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005400:	0485                	addi	s1,s1,1
    80005402:	008d8793          	addi	a5,s11,8
    80005406:	e0f43023          	sd	a5,-512(s0)
    8000540a:	008db503          	ld	a0,8(s11)
    8000540e:	c911                	beqz	a0,80005422 <exec+0x21a>
    if(argc >= MAXARG)
    80005410:	09a1                	addi	s3,s3,8
    80005412:	fb3c96e3          	bne	s9,s3,800053be <exec+0x1b6>
  sz = sz1;
    80005416:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000541a:	4481                	li	s1,0
    8000541c:	a84d                	j	800054ce <exec+0x2c6>
  sp = sz;
    8000541e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005420:	4481                	li	s1,0
  ustack[argc] = 0;
    80005422:	00349793          	slli	a5,s1,0x3
    80005426:	f9040713          	addi	a4,s0,-112
    8000542a:	97ba                	add	a5,a5,a4
    8000542c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005430:	00148693          	addi	a3,s1,1
    80005434:	068e                	slli	a3,a3,0x3
    80005436:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000543a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000543e:	01897663          	bgeu	s2,s8,8000544a <exec+0x242>
  sz = sz1;
    80005442:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005446:	4481                	li	s1,0
    80005448:	a059                	j	800054ce <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000544a:	e9040613          	addi	a2,s0,-368
    8000544e:	85ca                	mv	a1,s2
    80005450:	855e                	mv	a0,s7
    80005452:	ffffc097          	auipc	ra,0xffffc
    80005456:	220080e7          	jalr	544(ra) # 80001672 <copyout>
    8000545a:	0a054663          	bltz	a0,80005506 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000545e:	058ab783          	ld	a5,88(s5)
    80005462:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005466:	df843783          	ld	a5,-520(s0)
    8000546a:	0007c703          	lbu	a4,0(a5)
    8000546e:	cf11                	beqz	a4,8000548a <exec+0x282>
    80005470:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005472:	02f00693          	li	a3,47
    80005476:	a039                	j	80005484 <exec+0x27c>
      last = s+1;
    80005478:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000547c:	0785                	addi	a5,a5,1
    8000547e:	fff7c703          	lbu	a4,-1(a5)
    80005482:	c701                	beqz	a4,8000548a <exec+0x282>
    if(*s == '/')
    80005484:	fed71ce3          	bne	a4,a3,8000547c <exec+0x274>
    80005488:	bfc5                	j	80005478 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000548a:	4641                	li	a2,16
    8000548c:	df843583          	ld	a1,-520(s0)
    80005490:	158a8513          	addi	a0,s5,344
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	99e080e7          	jalr	-1634(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000549c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054a0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054a4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054a8:	058ab783          	ld	a5,88(s5)
    800054ac:	e6843703          	ld	a4,-408(s0)
    800054b0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054b2:	058ab783          	ld	a5,88(s5)
    800054b6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054ba:	85ea                	mv	a1,s10
    800054bc:	ffffd097          	auipc	ra,0xffffd
    800054c0:	aac080e7          	jalr	-1364(ra) # 80001f68 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054c4:	0004851b          	sext.w	a0,s1
    800054c8:	bbe1                	j	800052a0 <exec+0x98>
    800054ca:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054ce:	e0843583          	ld	a1,-504(s0)
    800054d2:	855e                	mv	a0,s7
    800054d4:	ffffd097          	auipc	ra,0xffffd
    800054d8:	a94080e7          	jalr	-1388(ra) # 80001f68 <proc_freepagetable>
  if(ip){
    800054dc:	da0498e3          	bnez	s1,8000528c <exec+0x84>
  return -1;
    800054e0:	557d                	li	a0,-1
    800054e2:	bb7d                	j	800052a0 <exec+0x98>
    800054e4:	e1243423          	sd	s2,-504(s0)
    800054e8:	b7dd                	j	800054ce <exec+0x2c6>
    800054ea:	e1243423          	sd	s2,-504(s0)
    800054ee:	b7c5                	j	800054ce <exec+0x2c6>
    800054f0:	e1243423          	sd	s2,-504(s0)
    800054f4:	bfe9                	j	800054ce <exec+0x2c6>
  sz = sz1;
    800054f6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054fa:	4481                	li	s1,0
    800054fc:	bfc9                	j	800054ce <exec+0x2c6>
  sz = sz1;
    800054fe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005502:	4481                	li	s1,0
    80005504:	b7e9                	j	800054ce <exec+0x2c6>
  sz = sz1;
    80005506:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000550a:	4481                	li	s1,0
    8000550c:	b7c9                	j	800054ce <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000550e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005512:	2b05                	addiw	s6,s6,1
    80005514:	0389899b          	addiw	s3,s3,56
    80005518:	e8845783          	lhu	a5,-376(s0)
    8000551c:	e2fb5be3          	bge	s6,a5,80005352 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005520:	2981                	sext.w	s3,s3
    80005522:	03800713          	li	a4,56
    80005526:	86ce                	mv	a3,s3
    80005528:	e1840613          	addi	a2,s0,-488
    8000552c:	4581                	li	a1,0
    8000552e:	8526                	mv	a0,s1
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	a8e080e7          	jalr	-1394(ra) # 80003fbe <readi>
    80005538:	03800793          	li	a5,56
    8000553c:	f8f517e3          	bne	a0,a5,800054ca <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005540:	e1842783          	lw	a5,-488(s0)
    80005544:	4705                	li	a4,1
    80005546:	fce796e3          	bne	a5,a4,80005512 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000554a:	e4043603          	ld	a2,-448(s0)
    8000554e:	e3843783          	ld	a5,-456(s0)
    80005552:	f8f669e3          	bltu	a2,a5,800054e4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005556:	e2843783          	ld	a5,-472(s0)
    8000555a:	963e                	add	a2,a2,a5
    8000555c:	f8f667e3          	bltu	a2,a5,800054ea <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005560:	85ca                	mv	a1,s2
    80005562:	855e                	mv	a0,s7
    80005564:	ffffc097          	auipc	ra,0xffffc
    80005568:	ebe080e7          	jalr	-322(ra) # 80001422 <uvmalloc>
    8000556c:	e0a43423          	sd	a0,-504(s0)
    80005570:	d141                	beqz	a0,800054f0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005572:	e2843d03          	ld	s10,-472(s0)
    80005576:	df043783          	ld	a5,-528(s0)
    8000557a:	00fd77b3          	and	a5,s10,a5
    8000557e:	fba1                	bnez	a5,800054ce <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005580:	e2042d83          	lw	s11,-480(s0)
    80005584:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005588:	f80c03e3          	beqz	s8,8000550e <exec+0x306>
    8000558c:	8a62                	mv	s4,s8
    8000558e:	4901                	li	s2,0
    80005590:	b345                	j	80005330 <exec+0x128>

0000000080005592 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005592:	7179                	addi	sp,sp,-48
    80005594:	f406                	sd	ra,40(sp)
    80005596:	f022                	sd	s0,32(sp)
    80005598:	ec26                	sd	s1,24(sp)
    8000559a:	e84a                	sd	s2,16(sp)
    8000559c:	1800                	addi	s0,sp,48
    8000559e:	892e                	mv	s2,a1
    800055a0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055a2:	fdc40593          	addi	a1,s0,-36
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	bf2080e7          	jalr	-1038(ra) # 80003198 <argint>
    800055ae:	04054063          	bltz	a0,800055ee <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055b2:	fdc42703          	lw	a4,-36(s0)
    800055b6:	47bd                	li	a5,15
    800055b8:	02e7ed63          	bltu	a5,a4,800055f2 <argfd+0x60>
    800055bc:	ffffd097          	auipc	ra,0xffffd
    800055c0:	852080e7          	jalr	-1966(ra) # 80001e0e <myproc>
    800055c4:	fdc42703          	lw	a4,-36(s0)
    800055c8:	01a70793          	addi	a5,a4,26
    800055cc:	078e                	slli	a5,a5,0x3
    800055ce:	953e                	add	a0,a0,a5
    800055d0:	611c                	ld	a5,0(a0)
    800055d2:	c395                	beqz	a5,800055f6 <argfd+0x64>
    return -1;
  if(pfd)
    800055d4:	00090463          	beqz	s2,800055dc <argfd+0x4a>
    *pfd = fd;
    800055d8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055dc:	4501                	li	a0,0
  if(pf)
    800055de:	c091                	beqz	s1,800055e2 <argfd+0x50>
    *pf = f;
    800055e0:	e09c                	sd	a5,0(s1)
}
    800055e2:	70a2                	ld	ra,40(sp)
    800055e4:	7402                	ld	s0,32(sp)
    800055e6:	64e2                	ld	s1,24(sp)
    800055e8:	6942                	ld	s2,16(sp)
    800055ea:	6145                	addi	sp,sp,48
    800055ec:	8082                	ret
    return -1;
    800055ee:	557d                	li	a0,-1
    800055f0:	bfcd                	j	800055e2 <argfd+0x50>
    return -1;
    800055f2:	557d                	li	a0,-1
    800055f4:	b7fd                	j	800055e2 <argfd+0x50>
    800055f6:	557d                	li	a0,-1
    800055f8:	b7ed                	j	800055e2 <argfd+0x50>

00000000800055fa <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055fa:	1101                	addi	sp,sp,-32
    800055fc:	ec06                	sd	ra,24(sp)
    800055fe:	e822                	sd	s0,16(sp)
    80005600:	e426                	sd	s1,8(sp)
    80005602:	1000                	addi	s0,sp,32
    80005604:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005606:	ffffd097          	auipc	ra,0xffffd
    8000560a:	808080e7          	jalr	-2040(ra) # 80001e0e <myproc>
    8000560e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005610:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005614:	4501                	li	a0,0
    80005616:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005618:	6398                	ld	a4,0(a5)
    8000561a:	cb19                	beqz	a4,80005630 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000561c:	2505                	addiw	a0,a0,1
    8000561e:	07a1                	addi	a5,a5,8
    80005620:	fed51ce3          	bne	a0,a3,80005618 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005624:	557d                	li	a0,-1
}
    80005626:	60e2                	ld	ra,24(sp)
    80005628:	6442                	ld	s0,16(sp)
    8000562a:	64a2                	ld	s1,8(sp)
    8000562c:	6105                	addi	sp,sp,32
    8000562e:	8082                	ret
      p->ofile[fd] = f;
    80005630:	01a50793          	addi	a5,a0,26
    80005634:	078e                	slli	a5,a5,0x3
    80005636:	963e                	add	a2,a2,a5
    80005638:	e204                	sd	s1,0(a2)
      return fd;
    8000563a:	b7f5                	j	80005626 <fdalloc+0x2c>

000000008000563c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000563c:	715d                	addi	sp,sp,-80
    8000563e:	e486                	sd	ra,72(sp)
    80005640:	e0a2                	sd	s0,64(sp)
    80005642:	fc26                	sd	s1,56(sp)
    80005644:	f84a                	sd	s2,48(sp)
    80005646:	f44e                	sd	s3,40(sp)
    80005648:	f052                	sd	s4,32(sp)
    8000564a:	ec56                	sd	s5,24(sp)
    8000564c:	0880                	addi	s0,sp,80
    8000564e:	89ae                	mv	s3,a1
    80005650:	8ab2                	mv	s5,a2
    80005652:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005654:	fb040593          	addi	a1,s0,-80
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	e86080e7          	jalr	-378(ra) # 800044de <nameiparent>
    80005660:	892a                	mv	s2,a0
    80005662:	12050f63          	beqz	a0,800057a0 <create+0x164>
    return 0;

  ilock(dp);
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	6a4080e7          	jalr	1700(ra) # 80003d0a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000566e:	4601                	li	a2,0
    80005670:	fb040593          	addi	a1,s0,-80
    80005674:	854a                	mv	a0,s2
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	b78080e7          	jalr	-1160(ra) # 800041ee <dirlookup>
    8000567e:	84aa                	mv	s1,a0
    80005680:	c921                	beqz	a0,800056d0 <create+0x94>
    iunlockput(dp);
    80005682:	854a                	mv	a0,s2
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	8e8080e7          	jalr	-1816(ra) # 80003f6c <iunlockput>
    ilock(ip);
    8000568c:	8526                	mv	a0,s1
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	67c080e7          	jalr	1660(ra) # 80003d0a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005696:	2981                	sext.w	s3,s3
    80005698:	4789                	li	a5,2
    8000569a:	02f99463          	bne	s3,a5,800056c2 <create+0x86>
    8000569e:	0444d783          	lhu	a5,68(s1)
    800056a2:	37f9                	addiw	a5,a5,-2
    800056a4:	17c2                	slli	a5,a5,0x30
    800056a6:	93c1                	srli	a5,a5,0x30
    800056a8:	4705                	li	a4,1
    800056aa:	00f76c63          	bltu	a4,a5,800056c2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056ae:	8526                	mv	a0,s1
    800056b0:	60a6                	ld	ra,72(sp)
    800056b2:	6406                	ld	s0,64(sp)
    800056b4:	74e2                	ld	s1,56(sp)
    800056b6:	7942                	ld	s2,48(sp)
    800056b8:	79a2                	ld	s3,40(sp)
    800056ba:	7a02                	ld	s4,32(sp)
    800056bc:	6ae2                	ld	s5,24(sp)
    800056be:	6161                	addi	sp,sp,80
    800056c0:	8082                	ret
    iunlockput(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	8a8080e7          	jalr	-1880(ra) # 80003f6c <iunlockput>
    return 0;
    800056cc:	4481                	li	s1,0
    800056ce:	b7c5                	j	800056ae <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056d0:	85ce                	mv	a1,s3
    800056d2:	00092503          	lw	a0,0(s2)
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	49c080e7          	jalr	1180(ra) # 80003b72 <ialloc>
    800056de:	84aa                	mv	s1,a0
    800056e0:	c529                	beqz	a0,8000572a <create+0xee>
  ilock(ip);
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	628080e7          	jalr	1576(ra) # 80003d0a <ilock>
  ip->major = major;
    800056ea:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800056ee:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800056f2:	4785                	li	a5,1
    800056f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	546080e7          	jalr	1350(ra) # 80003c40 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005702:	2981                	sext.w	s3,s3
    80005704:	4785                	li	a5,1
    80005706:	02f98a63          	beq	s3,a5,8000573a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000570a:	40d0                	lw	a2,4(s1)
    8000570c:	fb040593          	addi	a1,s0,-80
    80005710:	854a                	mv	a0,s2
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	cec080e7          	jalr	-788(ra) # 800043fe <dirlink>
    8000571a:	06054b63          	bltz	a0,80005790 <create+0x154>
  iunlockput(dp);
    8000571e:	854a                	mv	a0,s2
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	84c080e7          	jalr	-1972(ra) # 80003f6c <iunlockput>
  return ip;
    80005728:	b759                	j	800056ae <create+0x72>
    panic("create: ialloc");
    8000572a:	00003517          	auipc	a0,0x3
    8000572e:	09650513          	addi	a0,a0,150 # 800087c0 <syscalls+0x2a0>
    80005732:	ffffb097          	auipc	ra,0xffffb
    80005736:	e0c080e7          	jalr	-500(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000573a:	04a95783          	lhu	a5,74(s2)
    8000573e:	2785                	addiw	a5,a5,1
    80005740:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005744:	854a                	mv	a0,s2
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	4fa080e7          	jalr	1274(ra) # 80003c40 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000574e:	40d0                	lw	a2,4(s1)
    80005750:	00003597          	auipc	a1,0x3
    80005754:	08058593          	addi	a1,a1,128 # 800087d0 <syscalls+0x2b0>
    80005758:	8526                	mv	a0,s1
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	ca4080e7          	jalr	-860(ra) # 800043fe <dirlink>
    80005762:	00054f63          	bltz	a0,80005780 <create+0x144>
    80005766:	00492603          	lw	a2,4(s2)
    8000576a:	00003597          	auipc	a1,0x3
    8000576e:	06e58593          	addi	a1,a1,110 # 800087d8 <syscalls+0x2b8>
    80005772:	8526                	mv	a0,s1
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	c8a080e7          	jalr	-886(ra) # 800043fe <dirlink>
    8000577c:	f80557e3          	bgez	a0,8000570a <create+0xce>
      panic("create dots");
    80005780:	00003517          	auipc	a0,0x3
    80005784:	06050513          	addi	a0,a0,96 # 800087e0 <syscalls+0x2c0>
    80005788:	ffffb097          	auipc	ra,0xffffb
    8000578c:	db6080e7          	jalr	-586(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005790:	00003517          	auipc	a0,0x3
    80005794:	06050513          	addi	a0,a0,96 # 800087f0 <syscalls+0x2d0>
    80005798:	ffffb097          	auipc	ra,0xffffb
    8000579c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>
    return 0;
    800057a0:	84aa                	mv	s1,a0
    800057a2:	b731                	j	800056ae <create+0x72>

00000000800057a4 <sys_dup>:
{
    800057a4:	7179                	addi	sp,sp,-48
    800057a6:	f406                	sd	ra,40(sp)
    800057a8:	f022                	sd	s0,32(sp)
    800057aa:	ec26                	sd	s1,24(sp)
    800057ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057ae:	fd840613          	addi	a2,s0,-40
    800057b2:	4581                	li	a1,0
    800057b4:	4501                	li	a0,0
    800057b6:	00000097          	auipc	ra,0x0
    800057ba:	ddc080e7          	jalr	-548(ra) # 80005592 <argfd>
    return -1;
    800057be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057c0:	02054363          	bltz	a0,800057e6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057c4:	fd843503          	ld	a0,-40(s0)
    800057c8:	00000097          	auipc	ra,0x0
    800057cc:	e32080e7          	jalr	-462(ra) # 800055fa <fdalloc>
    800057d0:	84aa                	mv	s1,a0
    return -1;
    800057d2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057d4:	00054963          	bltz	a0,800057e6 <sys_dup+0x42>
  filedup(f);
    800057d8:	fd843503          	ld	a0,-40(s0)
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	37a080e7          	jalr	890(ra) # 80004b56 <filedup>
  return fd;
    800057e4:	87a6                	mv	a5,s1
}
    800057e6:	853e                	mv	a0,a5
    800057e8:	70a2                	ld	ra,40(sp)
    800057ea:	7402                	ld	s0,32(sp)
    800057ec:	64e2                	ld	s1,24(sp)
    800057ee:	6145                	addi	sp,sp,48
    800057f0:	8082                	ret

00000000800057f2 <sys_read>:
{
    800057f2:	7179                	addi	sp,sp,-48
    800057f4:	f406                	sd	ra,40(sp)
    800057f6:	f022                	sd	s0,32(sp)
    800057f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057fa:	fe840613          	addi	a2,s0,-24
    800057fe:	4581                	li	a1,0
    80005800:	4501                	li	a0,0
    80005802:	00000097          	auipc	ra,0x0
    80005806:	d90080e7          	jalr	-624(ra) # 80005592 <argfd>
    return -1;
    8000580a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000580c:	04054163          	bltz	a0,8000584e <sys_read+0x5c>
    80005810:	fe440593          	addi	a1,s0,-28
    80005814:	4509                	li	a0,2
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	982080e7          	jalr	-1662(ra) # 80003198 <argint>
    return -1;
    8000581e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005820:	02054763          	bltz	a0,8000584e <sys_read+0x5c>
    80005824:	fd840593          	addi	a1,s0,-40
    80005828:	4505                	li	a0,1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	990080e7          	jalr	-1648(ra) # 800031ba <argaddr>
    return -1;
    80005832:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005834:	00054d63          	bltz	a0,8000584e <sys_read+0x5c>
  return fileread(f, p, n);
    80005838:	fe442603          	lw	a2,-28(s0)
    8000583c:	fd843583          	ld	a1,-40(s0)
    80005840:	fe843503          	ld	a0,-24(s0)
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	49e080e7          	jalr	1182(ra) # 80004ce2 <fileread>
    8000584c:	87aa                	mv	a5,a0
}
    8000584e:	853e                	mv	a0,a5
    80005850:	70a2                	ld	ra,40(sp)
    80005852:	7402                	ld	s0,32(sp)
    80005854:	6145                	addi	sp,sp,48
    80005856:	8082                	ret

0000000080005858 <sys_write>:
{
    80005858:	7179                	addi	sp,sp,-48
    8000585a:	f406                	sd	ra,40(sp)
    8000585c:	f022                	sd	s0,32(sp)
    8000585e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005860:	fe840613          	addi	a2,s0,-24
    80005864:	4581                	li	a1,0
    80005866:	4501                	li	a0,0
    80005868:	00000097          	auipc	ra,0x0
    8000586c:	d2a080e7          	jalr	-726(ra) # 80005592 <argfd>
    return -1;
    80005870:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005872:	04054163          	bltz	a0,800058b4 <sys_write+0x5c>
    80005876:	fe440593          	addi	a1,s0,-28
    8000587a:	4509                	li	a0,2
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	91c080e7          	jalr	-1764(ra) # 80003198 <argint>
    return -1;
    80005884:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005886:	02054763          	bltz	a0,800058b4 <sys_write+0x5c>
    8000588a:	fd840593          	addi	a1,s0,-40
    8000588e:	4505                	li	a0,1
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	92a080e7          	jalr	-1750(ra) # 800031ba <argaddr>
    return -1;
    80005898:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000589a:	00054d63          	bltz	a0,800058b4 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000589e:	fe442603          	lw	a2,-28(s0)
    800058a2:	fd843583          	ld	a1,-40(s0)
    800058a6:	fe843503          	ld	a0,-24(s0)
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	4fa080e7          	jalr	1274(ra) # 80004da4 <filewrite>
    800058b2:	87aa                	mv	a5,a0
}
    800058b4:	853e                	mv	a0,a5
    800058b6:	70a2                	ld	ra,40(sp)
    800058b8:	7402                	ld	s0,32(sp)
    800058ba:	6145                	addi	sp,sp,48
    800058bc:	8082                	ret

00000000800058be <sys_close>:
{
    800058be:	1101                	addi	sp,sp,-32
    800058c0:	ec06                	sd	ra,24(sp)
    800058c2:	e822                	sd	s0,16(sp)
    800058c4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058c6:	fe040613          	addi	a2,s0,-32
    800058ca:	fec40593          	addi	a1,s0,-20
    800058ce:	4501                	li	a0,0
    800058d0:	00000097          	auipc	ra,0x0
    800058d4:	cc2080e7          	jalr	-830(ra) # 80005592 <argfd>
    return -1;
    800058d8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058da:	02054463          	bltz	a0,80005902 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058de:	ffffc097          	auipc	ra,0xffffc
    800058e2:	530080e7          	jalr	1328(ra) # 80001e0e <myproc>
    800058e6:	fec42783          	lw	a5,-20(s0)
    800058ea:	07e9                	addi	a5,a5,26
    800058ec:	078e                	slli	a5,a5,0x3
    800058ee:	97aa                	add	a5,a5,a0
    800058f0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800058f4:	fe043503          	ld	a0,-32(s0)
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	2b0080e7          	jalr	688(ra) # 80004ba8 <fileclose>
  return 0;
    80005900:	4781                	li	a5,0
}
    80005902:	853e                	mv	a0,a5
    80005904:	60e2                	ld	ra,24(sp)
    80005906:	6442                	ld	s0,16(sp)
    80005908:	6105                	addi	sp,sp,32
    8000590a:	8082                	ret

000000008000590c <sys_fstat>:
{
    8000590c:	1101                	addi	sp,sp,-32
    8000590e:	ec06                	sd	ra,24(sp)
    80005910:	e822                	sd	s0,16(sp)
    80005912:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005914:	fe840613          	addi	a2,s0,-24
    80005918:	4581                	li	a1,0
    8000591a:	4501                	li	a0,0
    8000591c:	00000097          	auipc	ra,0x0
    80005920:	c76080e7          	jalr	-906(ra) # 80005592 <argfd>
    return -1;
    80005924:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005926:	02054563          	bltz	a0,80005950 <sys_fstat+0x44>
    8000592a:	fe040593          	addi	a1,s0,-32
    8000592e:	4505                	li	a0,1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	88a080e7          	jalr	-1910(ra) # 800031ba <argaddr>
    return -1;
    80005938:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000593a:	00054b63          	bltz	a0,80005950 <sys_fstat+0x44>
  return filestat(f, st);
    8000593e:	fe043583          	ld	a1,-32(s0)
    80005942:	fe843503          	ld	a0,-24(s0)
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	32a080e7          	jalr	810(ra) # 80004c70 <filestat>
    8000594e:	87aa                	mv	a5,a0
}
    80005950:	853e                	mv	a0,a5
    80005952:	60e2                	ld	ra,24(sp)
    80005954:	6442                	ld	s0,16(sp)
    80005956:	6105                	addi	sp,sp,32
    80005958:	8082                	ret

000000008000595a <sys_link>:
{
    8000595a:	7169                	addi	sp,sp,-304
    8000595c:	f606                	sd	ra,296(sp)
    8000595e:	f222                	sd	s0,288(sp)
    80005960:	ee26                	sd	s1,280(sp)
    80005962:	ea4a                	sd	s2,272(sp)
    80005964:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005966:	08000613          	li	a2,128
    8000596a:	ed040593          	addi	a1,s0,-304
    8000596e:	4501                	li	a0,0
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	86c080e7          	jalr	-1940(ra) # 800031dc <argstr>
    return -1;
    80005978:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000597a:	10054e63          	bltz	a0,80005a96 <sys_link+0x13c>
    8000597e:	08000613          	li	a2,128
    80005982:	f5040593          	addi	a1,s0,-176
    80005986:	4505                	li	a0,1
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	854080e7          	jalr	-1964(ra) # 800031dc <argstr>
    return -1;
    80005990:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005992:	10054263          	bltz	a0,80005a96 <sys_link+0x13c>
  begin_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	d46080e7          	jalr	-698(ra) # 800046dc <begin_op>
  if((ip = namei(old)) == 0){
    8000599e:	ed040513          	addi	a0,s0,-304
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	b1e080e7          	jalr	-1250(ra) # 800044c0 <namei>
    800059aa:	84aa                	mv	s1,a0
    800059ac:	c551                	beqz	a0,80005a38 <sys_link+0xde>
  ilock(ip);
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	35c080e7          	jalr	860(ra) # 80003d0a <ilock>
  if(ip->type == T_DIR){
    800059b6:	04449703          	lh	a4,68(s1)
    800059ba:	4785                	li	a5,1
    800059bc:	08f70463          	beq	a4,a5,80005a44 <sys_link+0xea>
  ip->nlink++;
    800059c0:	04a4d783          	lhu	a5,74(s1)
    800059c4:	2785                	addiw	a5,a5,1
    800059c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059ca:	8526                	mv	a0,s1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	274080e7          	jalr	628(ra) # 80003c40 <iupdate>
  iunlock(ip);
    800059d4:	8526                	mv	a0,s1
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	3f6080e7          	jalr	1014(ra) # 80003dcc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059de:	fd040593          	addi	a1,s0,-48
    800059e2:	f5040513          	addi	a0,s0,-176
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	af8080e7          	jalr	-1288(ra) # 800044de <nameiparent>
    800059ee:	892a                	mv	s2,a0
    800059f0:	c935                	beqz	a0,80005a64 <sys_link+0x10a>
  ilock(dp);
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	318080e7          	jalr	792(ra) # 80003d0a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059fa:	00092703          	lw	a4,0(s2)
    800059fe:	409c                	lw	a5,0(s1)
    80005a00:	04f71d63          	bne	a4,a5,80005a5a <sys_link+0x100>
    80005a04:	40d0                	lw	a2,4(s1)
    80005a06:	fd040593          	addi	a1,s0,-48
    80005a0a:	854a                	mv	a0,s2
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	9f2080e7          	jalr	-1550(ra) # 800043fe <dirlink>
    80005a14:	04054363          	bltz	a0,80005a5a <sys_link+0x100>
  iunlockput(dp);
    80005a18:	854a                	mv	a0,s2
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	552080e7          	jalr	1362(ra) # 80003f6c <iunlockput>
  iput(ip);
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	4a0080e7          	jalr	1184(ra) # 80003ec4 <iput>
  end_op();
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	d30080e7          	jalr	-720(ra) # 8000475c <end_op>
  return 0;
    80005a34:	4781                	li	a5,0
    80005a36:	a085                	j	80005a96 <sys_link+0x13c>
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	d24080e7          	jalr	-732(ra) # 8000475c <end_op>
    return -1;
    80005a40:	57fd                	li	a5,-1
    80005a42:	a891                	j	80005a96 <sys_link+0x13c>
    iunlockput(ip);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	526080e7          	jalr	1318(ra) # 80003f6c <iunlockput>
    end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	d0e080e7          	jalr	-754(ra) # 8000475c <end_op>
    return -1;
    80005a56:	57fd                	li	a5,-1
    80005a58:	a83d                	j	80005a96 <sys_link+0x13c>
    iunlockput(dp);
    80005a5a:	854a                	mv	a0,s2
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	510080e7          	jalr	1296(ra) # 80003f6c <iunlockput>
  ilock(ip);
    80005a64:	8526                	mv	a0,s1
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	2a4080e7          	jalr	676(ra) # 80003d0a <ilock>
  ip->nlink--;
    80005a6e:	04a4d783          	lhu	a5,74(s1)
    80005a72:	37fd                	addiw	a5,a5,-1
    80005a74:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	1c6080e7          	jalr	454(ra) # 80003c40 <iupdate>
  iunlockput(ip);
    80005a82:	8526                	mv	a0,s1
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	4e8080e7          	jalr	1256(ra) # 80003f6c <iunlockput>
  end_op();
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	cd0080e7          	jalr	-816(ra) # 8000475c <end_op>
  return -1;
    80005a94:	57fd                	li	a5,-1
}
    80005a96:	853e                	mv	a0,a5
    80005a98:	70b2                	ld	ra,296(sp)
    80005a9a:	7412                	ld	s0,288(sp)
    80005a9c:	64f2                	ld	s1,280(sp)
    80005a9e:	6952                	ld	s2,272(sp)
    80005aa0:	6155                	addi	sp,sp,304
    80005aa2:	8082                	ret

0000000080005aa4 <sys_unlink>:
{
    80005aa4:	7151                	addi	sp,sp,-240
    80005aa6:	f586                	sd	ra,232(sp)
    80005aa8:	f1a2                	sd	s0,224(sp)
    80005aaa:	eda6                	sd	s1,216(sp)
    80005aac:	e9ca                	sd	s2,208(sp)
    80005aae:	e5ce                	sd	s3,200(sp)
    80005ab0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ab2:	08000613          	li	a2,128
    80005ab6:	f3040593          	addi	a1,s0,-208
    80005aba:	4501                	li	a0,0
    80005abc:	ffffd097          	auipc	ra,0xffffd
    80005ac0:	720080e7          	jalr	1824(ra) # 800031dc <argstr>
    80005ac4:	18054163          	bltz	a0,80005c46 <sys_unlink+0x1a2>
  begin_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	c14080e7          	jalr	-1004(ra) # 800046dc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ad0:	fb040593          	addi	a1,s0,-80
    80005ad4:	f3040513          	addi	a0,s0,-208
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	a06080e7          	jalr	-1530(ra) # 800044de <nameiparent>
    80005ae0:	84aa                	mv	s1,a0
    80005ae2:	c979                	beqz	a0,80005bb8 <sys_unlink+0x114>
  ilock(dp);
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	226080e7          	jalr	550(ra) # 80003d0a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005aec:	00003597          	auipc	a1,0x3
    80005af0:	ce458593          	addi	a1,a1,-796 # 800087d0 <syscalls+0x2b0>
    80005af4:	fb040513          	addi	a0,s0,-80
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	6dc080e7          	jalr	1756(ra) # 800041d4 <namecmp>
    80005b00:	14050a63          	beqz	a0,80005c54 <sys_unlink+0x1b0>
    80005b04:	00003597          	auipc	a1,0x3
    80005b08:	cd458593          	addi	a1,a1,-812 # 800087d8 <syscalls+0x2b8>
    80005b0c:	fb040513          	addi	a0,s0,-80
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	6c4080e7          	jalr	1732(ra) # 800041d4 <namecmp>
    80005b18:	12050e63          	beqz	a0,80005c54 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b1c:	f2c40613          	addi	a2,s0,-212
    80005b20:	fb040593          	addi	a1,s0,-80
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	6c8080e7          	jalr	1736(ra) # 800041ee <dirlookup>
    80005b2e:	892a                	mv	s2,a0
    80005b30:	12050263          	beqz	a0,80005c54 <sys_unlink+0x1b0>
  ilock(ip);
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	1d6080e7          	jalr	470(ra) # 80003d0a <ilock>
  if(ip->nlink < 1)
    80005b3c:	04a91783          	lh	a5,74(s2)
    80005b40:	08f05263          	blez	a5,80005bc4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b44:	04491703          	lh	a4,68(s2)
    80005b48:	4785                	li	a5,1
    80005b4a:	08f70563          	beq	a4,a5,80005bd4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b4e:	4641                	li	a2,16
    80005b50:	4581                	li	a1,0
    80005b52:	fc040513          	addi	a0,s0,-64
    80005b56:	ffffb097          	auipc	ra,0xffffb
    80005b5a:	18a080e7          	jalr	394(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b5e:	4741                	li	a4,16
    80005b60:	f2c42683          	lw	a3,-212(s0)
    80005b64:	fc040613          	addi	a2,s0,-64
    80005b68:	4581                	li	a1,0
    80005b6a:	8526                	mv	a0,s1
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	54a080e7          	jalr	1354(ra) # 800040b6 <writei>
    80005b74:	47c1                	li	a5,16
    80005b76:	0af51563          	bne	a0,a5,80005c20 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b7a:	04491703          	lh	a4,68(s2)
    80005b7e:	4785                	li	a5,1
    80005b80:	0af70863          	beq	a4,a5,80005c30 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b84:	8526                	mv	a0,s1
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	3e6080e7          	jalr	998(ra) # 80003f6c <iunlockput>
  ip->nlink--;
    80005b8e:	04a95783          	lhu	a5,74(s2)
    80005b92:	37fd                	addiw	a5,a5,-1
    80005b94:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b98:	854a                	mv	a0,s2
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	0a6080e7          	jalr	166(ra) # 80003c40 <iupdate>
  iunlockput(ip);
    80005ba2:	854a                	mv	a0,s2
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	3c8080e7          	jalr	968(ra) # 80003f6c <iunlockput>
  end_op();
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	bb0080e7          	jalr	-1104(ra) # 8000475c <end_op>
  return 0;
    80005bb4:	4501                	li	a0,0
    80005bb6:	a84d                	j	80005c68 <sys_unlink+0x1c4>
    end_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	ba4080e7          	jalr	-1116(ra) # 8000475c <end_op>
    return -1;
    80005bc0:	557d                	li	a0,-1
    80005bc2:	a05d                	j	80005c68 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bc4:	00003517          	auipc	a0,0x3
    80005bc8:	c3c50513          	addi	a0,a0,-964 # 80008800 <syscalls+0x2e0>
    80005bcc:	ffffb097          	auipc	ra,0xffffb
    80005bd0:	972080e7          	jalr	-1678(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bd4:	04c92703          	lw	a4,76(s2)
    80005bd8:	02000793          	li	a5,32
    80005bdc:	f6e7f9e3          	bgeu	a5,a4,80005b4e <sys_unlink+0xaa>
    80005be0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005be4:	4741                	li	a4,16
    80005be6:	86ce                	mv	a3,s3
    80005be8:	f1840613          	addi	a2,s0,-232
    80005bec:	4581                	li	a1,0
    80005bee:	854a                	mv	a0,s2
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	3ce080e7          	jalr	974(ra) # 80003fbe <readi>
    80005bf8:	47c1                	li	a5,16
    80005bfa:	00f51b63          	bne	a0,a5,80005c10 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005bfe:	f1845783          	lhu	a5,-232(s0)
    80005c02:	e7a1                	bnez	a5,80005c4a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c04:	29c1                	addiw	s3,s3,16
    80005c06:	04c92783          	lw	a5,76(s2)
    80005c0a:	fcf9ede3          	bltu	s3,a5,80005be4 <sys_unlink+0x140>
    80005c0e:	b781                	j	80005b4e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c10:	00003517          	auipc	a0,0x3
    80005c14:	c0850513          	addi	a0,a0,-1016 # 80008818 <syscalls+0x2f8>
    80005c18:	ffffb097          	auipc	ra,0xffffb
    80005c1c:	926080e7          	jalr	-1754(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c20:	00003517          	auipc	a0,0x3
    80005c24:	c1050513          	addi	a0,a0,-1008 # 80008830 <syscalls+0x310>
    80005c28:	ffffb097          	auipc	ra,0xffffb
    80005c2c:	916080e7          	jalr	-1770(ra) # 8000053e <panic>
    dp->nlink--;
    80005c30:	04a4d783          	lhu	a5,74(s1)
    80005c34:	37fd                	addiw	a5,a5,-1
    80005c36:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c3a:	8526                	mv	a0,s1
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	004080e7          	jalr	4(ra) # 80003c40 <iupdate>
    80005c44:	b781                	j	80005b84 <sys_unlink+0xe0>
    return -1;
    80005c46:	557d                	li	a0,-1
    80005c48:	a005                	j	80005c68 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c4a:	854a                	mv	a0,s2
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	320080e7          	jalr	800(ra) # 80003f6c <iunlockput>
  iunlockput(dp);
    80005c54:	8526                	mv	a0,s1
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	316080e7          	jalr	790(ra) # 80003f6c <iunlockput>
  end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	afe080e7          	jalr	-1282(ra) # 8000475c <end_op>
  return -1;
    80005c66:	557d                	li	a0,-1
}
    80005c68:	70ae                	ld	ra,232(sp)
    80005c6a:	740e                	ld	s0,224(sp)
    80005c6c:	64ee                	ld	s1,216(sp)
    80005c6e:	694e                	ld	s2,208(sp)
    80005c70:	69ae                	ld	s3,200(sp)
    80005c72:	616d                	addi	sp,sp,240
    80005c74:	8082                	ret

0000000080005c76 <sys_open>:

uint64
sys_open(void)
{
    80005c76:	7131                	addi	sp,sp,-192
    80005c78:	fd06                	sd	ra,184(sp)
    80005c7a:	f922                	sd	s0,176(sp)
    80005c7c:	f526                	sd	s1,168(sp)
    80005c7e:	f14a                	sd	s2,160(sp)
    80005c80:	ed4e                	sd	s3,152(sp)
    80005c82:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c84:	08000613          	li	a2,128
    80005c88:	f5040593          	addi	a1,s0,-176
    80005c8c:	4501                	li	a0,0
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	54e080e7          	jalr	1358(ra) # 800031dc <argstr>
    return -1;
    80005c96:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c98:	0c054163          	bltz	a0,80005d5a <sys_open+0xe4>
    80005c9c:	f4c40593          	addi	a1,s0,-180
    80005ca0:	4505                	li	a0,1
    80005ca2:	ffffd097          	auipc	ra,0xffffd
    80005ca6:	4f6080e7          	jalr	1270(ra) # 80003198 <argint>
    80005caa:	0a054863          	bltz	a0,80005d5a <sys_open+0xe4>

  begin_op();
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	a2e080e7          	jalr	-1490(ra) # 800046dc <begin_op>

  if(omode & O_CREATE){
    80005cb6:	f4c42783          	lw	a5,-180(s0)
    80005cba:	2007f793          	andi	a5,a5,512
    80005cbe:	cbdd                	beqz	a5,80005d74 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cc0:	4681                	li	a3,0
    80005cc2:	4601                	li	a2,0
    80005cc4:	4589                	li	a1,2
    80005cc6:	f5040513          	addi	a0,s0,-176
    80005cca:	00000097          	auipc	ra,0x0
    80005cce:	972080e7          	jalr	-1678(ra) # 8000563c <create>
    80005cd2:	892a                	mv	s2,a0
    if(ip == 0){
    80005cd4:	c959                	beqz	a0,80005d6a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cd6:	04491703          	lh	a4,68(s2)
    80005cda:	478d                	li	a5,3
    80005cdc:	00f71763          	bne	a4,a5,80005cea <sys_open+0x74>
    80005ce0:	04695703          	lhu	a4,70(s2)
    80005ce4:	47a5                	li	a5,9
    80005ce6:	0ce7ec63          	bltu	a5,a4,80005dbe <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	e02080e7          	jalr	-510(ra) # 80004aec <filealloc>
    80005cf2:	89aa                	mv	s3,a0
    80005cf4:	10050263          	beqz	a0,80005df8 <sys_open+0x182>
    80005cf8:	00000097          	auipc	ra,0x0
    80005cfc:	902080e7          	jalr	-1790(ra) # 800055fa <fdalloc>
    80005d00:	84aa                	mv	s1,a0
    80005d02:	0e054663          	bltz	a0,80005dee <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d06:	04491703          	lh	a4,68(s2)
    80005d0a:	478d                	li	a5,3
    80005d0c:	0cf70463          	beq	a4,a5,80005dd4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d10:	4789                	li	a5,2
    80005d12:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d16:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d1a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d1e:	f4c42783          	lw	a5,-180(s0)
    80005d22:	0017c713          	xori	a4,a5,1
    80005d26:	8b05                	andi	a4,a4,1
    80005d28:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d2c:	0037f713          	andi	a4,a5,3
    80005d30:	00e03733          	snez	a4,a4
    80005d34:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d38:	4007f793          	andi	a5,a5,1024
    80005d3c:	c791                	beqz	a5,80005d48 <sys_open+0xd2>
    80005d3e:	04491703          	lh	a4,68(s2)
    80005d42:	4789                	li	a5,2
    80005d44:	08f70f63          	beq	a4,a5,80005de2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d48:	854a                	mv	a0,s2
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	082080e7          	jalr	130(ra) # 80003dcc <iunlock>
  end_op();
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	a0a080e7          	jalr	-1526(ra) # 8000475c <end_op>

  return fd;
}
    80005d5a:	8526                	mv	a0,s1
    80005d5c:	70ea                	ld	ra,184(sp)
    80005d5e:	744a                	ld	s0,176(sp)
    80005d60:	74aa                	ld	s1,168(sp)
    80005d62:	790a                	ld	s2,160(sp)
    80005d64:	69ea                	ld	s3,152(sp)
    80005d66:	6129                	addi	sp,sp,192
    80005d68:	8082                	ret
      end_op();
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	9f2080e7          	jalr	-1550(ra) # 8000475c <end_op>
      return -1;
    80005d72:	b7e5                	j	80005d5a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d74:	f5040513          	addi	a0,s0,-176
    80005d78:	ffffe097          	auipc	ra,0xffffe
    80005d7c:	748080e7          	jalr	1864(ra) # 800044c0 <namei>
    80005d80:	892a                	mv	s2,a0
    80005d82:	c905                	beqz	a0,80005db2 <sys_open+0x13c>
    ilock(ip);
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	f86080e7          	jalr	-122(ra) # 80003d0a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d8c:	04491703          	lh	a4,68(s2)
    80005d90:	4785                	li	a5,1
    80005d92:	f4f712e3          	bne	a4,a5,80005cd6 <sys_open+0x60>
    80005d96:	f4c42783          	lw	a5,-180(s0)
    80005d9a:	dba1                	beqz	a5,80005cea <sys_open+0x74>
      iunlockput(ip);
    80005d9c:	854a                	mv	a0,s2
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	1ce080e7          	jalr	462(ra) # 80003f6c <iunlockput>
      end_op();
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	9b6080e7          	jalr	-1610(ra) # 8000475c <end_op>
      return -1;
    80005dae:	54fd                	li	s1,-1
    80005db0:	b76d                	j	80005d5a <sys_open+0xe4>
      end_op();
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	9aa080e7          	jalr	-1622(ra) # 8000475c <end_op>
      return -1;
    80005dba:	54fd                	li	s1,-1
    80005dbc:	bf79                	j	80005d5a <sys_open+0xe4>
    iunlockput(ip);
    80005dbe:	854a                	mv	a0,s2
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	1ac080e7          	jalr	428(ra) # 80003f6c <iunlockput>
    end_op();
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	994080e7          	jalr	-1644(ra) # 8000475c <end_op>
    return -1;
    80005dd0:	54fd                	li	s1,-1
    80005dd2:	b761                	j	80005d5a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dd4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005dd8:	04691783          	lh	a5,70(s2)
    80005ddc:	02f99223          	sh	a5,36(s3)
    80005de0:	bf2d                	j	80005d1a <sys_open+0xa4>
    itrunc(ip);
    80005de2:	854a                	mv	a0,s2
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	034080e7          	jalr	52(ra) # 80003e18 <itrunc>
    80005dec:	bfb1                	j	80005d48 <sys_open+0xd2>
      fileclose(f);
    80005dee:	854e                	mv	a0,s3
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	db8080e7          	jalr	-584(ra) # 80004ba8 <fileclose>
    iunlockput(ip);
    80005df8:	854a                	mv	a0,s2
    80005dfa:	ffffe097          	auipc	ra,0xffffe
    80005dfe:	172080e7          	jalr	370(ra) # 80003f6c <iunlockput>
    end_op();
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	95a080e7          	jalr	-1702(ra) # 8000475c <end_op>
    return -1;
    80005e0a:	54fd                	li	s1,-1
    80005e0c:	b7b9                	j	80005d5a <sys_open+0xe4>

0000000080005e0e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e0e:	7175                	addi	sp,sp,-144
    80005e10:	e506                	sd	ra,136(sp)
    80005e12:	e122                	sd	s0,128(sp)
    80005e14:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	8c6080e7          	jalr	-1850(ra) # 800046dc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e1e:	08000613          	li	a2,128
    80005e22:	f7040593          	addi	a1,s0,-144
    80005e26:	4501                	li	a0,0
    80005e28:	ffffd097          	auipc	ra,0xffffd
    80005e2c:	3b4080e7          	jalr	948(ra) # 800031dc <argstr>
    80005e30:	02054963          	bltz	a0,80005e62 <sys_mkdir+0x54>
    80005e34:	4681                	li	a3,0
    80005e36:	4601                	li	a2,0
    80005e38:	4585                	li	a1,1
    80005e3a:	f7040513          	addi	a0,s0,-144
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	7fe080e7          	jalr	2046(ra) # 8000563c <create>
    80005e46:	cd11                	beqz	a0,80005e62 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	124080e7          	jalr	292(ra) # 80003f6c <iunlockput>
  end_op();
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	90c080e7          	jalr	-1780(ra) # 8000475c <end_op>
  return 0;
    80005e58:	4501                	li	a0,0
}
    80005e5a:	60aa                	ld	ra,136(sp)
    80005e5c:	640a                	ld	s0,128(sp)
    80005e5e:	6149                	addi	sp,sp,144
    80005e60:	8082                	ret
    end_op();
    80005e62:	fffff097          	auipc	ra,0xfffff
    80005e66:	8fa080e7          	jalr	-1798(ra) # 8000475c <end_op>
    return -1;
    80005e6a:	557d                	li	a0,-1
    80005e6c:	b7fd                	j	80005e5a <sys_mkdir+0x4c>

0000000080005e6e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e6e:	7135                	addi	sp,sp,-160
    80005e70:	ed06                	sd	ra,152(sp)
    80005e72:	e922                	sd	s0,144(sp)
    80005e74:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	866080e7          	jalr	-1946(ra) # 800046dc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e7e:	08000613          	li	a2,128
    80005e82:	f7040593          	addi	a1,s0,-144
    80005e86:	4501                	li	a0,0
    80005e88:	ffffd097          	auipc	ra,0xffffd
    80005e8c:	354080e7          	jalr	852(ra) # 800031dc <argstr>
    80005e90:	04054a63          	bltz	a0,80005ee4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e94:	f6c40593          	addi	a1,s0,-148
    80005e98:	4505                	li	a0,1
    80005e9a:	ffffd097          	auipc	ra,0xffffd
    80005e9e:	2fe080e7          	jalr	766(ra) # 80003198 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ea2:	04054163          	bltz	a0,80005ee4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ea6:	f6840593          	addi	a1,s0,-152
    80005eaa:	4509                	li	a0,2
    80005eac:	ffffd097          	auipc	ra,0xffffd
    80005eb0:	2ec080e7          	jalr	748(ra) # 80003198 <argint>
     argint(1, &major) < 0 ||
    80005eb4:	02054863          	bltz	a0,80005ee4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005eb8:	f6841683          	lh	a3,-152(s0)
    80005ebc:	f6c41603          	lh	a2,-148(s0)
    80005ec0:	458d                	li	a1,3
    80005ec2:	f7040513          	addi	a0,s0,-144
    80005ec6:	fffff097          	auipc	ra,0xfffff
    80005eca:	776080e7          	jalr	1910(ra) # 8000563c <create>
     argint(2, &minor) < 0 ||
    80005ece:	c919                	beqz	a0,80005ee4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	09c080e7          	jalr	156(ra) # 80003f6c <iunlockput>
  end_op();
    80005ed8:	fffff097          	auipc	ra,0xfffff
    80005edc:	884080e7          	jalr	-1916(ra) # 8000475c <end_op>
  return 0;
    80005ee0:	4501                	li	a0,0
    80005ee2:	a031                	j	80005eee <sys_mknod+0x80>
    end_op();
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	878080e7          	jalr	-1928(ra) # 8000475c <end_op>
    return -1;
    80005eec:	557d                	li	a0,-1
}
    80005eee:	60ea                	ld	ra,152(sp)
    80005ef0:	644a                	ld	s0,144(sp)
    80005ef2:	610d                	addi	sp,sp,160
    80005ef4:	8082                	ret

0000000080005ef6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ef6:	7135                	addi	sp,sp,-160
    80005ef8:	ed06                	sd	ra,152(sp)
    80005efa:	e922                	sd	s0,144(sp)
    80005efc:	e526                	sd	s1,136(sp)
    80005efe:	e14a                	sd	s2,128(sp)
    80005f00:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f02:	ffffc097          	auipc	ra,0xffffc
    80005f06:	f0c080e7          	jalr	-244(ra) # 80001e0e <myproc>
    80005f0a:	892a                	mv	s2,a0
  
  begin_op();
    80005f0c:	ffffe097          	auipc	ra,0xffffe
    80005f10:	7d0080e7          	jalr	2000(ra) # 800046dc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f14:	08000613          	li	a2,128
    80005f18:	f6040593          	addi	a1,s0,-160
    80005f1c:	4501                	li	a0,0
    80005f1e:	ffffd097          	auipc	ra,0xffffd
    80005f22:	2be080e7          	jalr	702(ra) # 800031dc <argstr>
    80005f26:	04054b63          	bltz	a0,80005f7c <sys_chdir+0x86>
    80005f2a:	f6040513          	addi	a0,s0,-160
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	592080e7          	jalr	1426(ra) # 800044c0 <namei>
    80005f36:	84aa                	mv	s1,a0
    80005f38:	c131                	beqz	a0,80005f7c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f3a:	ffffe097          	auipc	ra,0xffffe
    80005f3e:	dd0080e7          	jalr	-560(ra) # 80003d0a <ilock>
  if(ip->type != T_DIR){
    80005f42:	04449703          	lh	a4,68(s1)
    80005f46:	4785                	li	a5,1
    80005f48:	04f71063          	bne	a4,a5,80005f88 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f4c:	8526                	mv	a0,s1
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	e7e080e7          	jalr	-386(ra) # 80003dcc <iunlock>
  iput(p->cwd);
    80005f56:	15093503          	ld	a0,336(s2)
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	f6a080e7          	jalr	-150(ra) # 80003ec4 <iput>
  end_op();
    80005f62:	ffffe097          	auipc	ra,0xffffe
    80005f66:	7fa080e7          	jalr	2042(ra) # 8000475c <end_op>
  p->cwd = ip;
    80005f6a:	14993823          	sd	s1,336(s2)
  return 0;
    80005f6e:	4501                	li	a0,0
}
    80005f70:	60ea                	ld	ra,152(sp)
    80005f72:	644a                	ld	s0,144(sp)
    80005f74:	64aa                	ld	s1,136(sp)
    80005f76:	690a                	ld	s2,128(sp)
    80005f78:	610d                	addi	sp,sp,160
    80005f7a:	8082                	ret
    end_op();
    80005f7c:	ffffe097          	auipc	ra,0xffffe
    80005f80:	7e0080e7          	jalr	2016(ra) # 8000475c <end_op>
    return -1;
    80005f84:	557d                	li	a0,-1
    80005f86:	b7ed                	j	80005f70 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f88:	8526                	mv	a0,s1
    80005f8a:	ffffe097          	auipc	ra,0xffffe
    80005f8e:	fe2080e7          	jalr	-30(ra) # 80003f6c <iunlockput>
    end_op();
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	7ca080e7          	jalr	1994(ra) # 8000475c <end_op>
    return -1;
    80005f9a:	557d                	li	a0,-1
    80005f9c:	bfd1                	j	80005f70 <sys_chdir+0x7a>

0000000080005f9e <sys_exec>:

uint64
sys_exec(void)
{
    80005f9e:	7145                	addi	sp,sp,-464
    80005fa0:	e786                	sd	ra,456(sp)
    80005fa2:	e3a2                	sd	s0,448(sp)
    80005fa4:	ff26                	sd	s1,440(sp)
    80005fa6:	fb4a                	sd	s2,432(sp)
    80005fa8:	f74e                	sd	s3,424(sp)
    80005faa:	f352                	sd	s4,416(sp)
    80005fac:	ef56                	sd	s5,408(sp)
    80005fae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fb0:	08000613          	li	a2,128
    80005fb4:	f4040593          	addi	a1,s0,-192
    80005fb8:	4501                	li	a0,0
    80005fba:	ffffd097          	auipc	ra,0xffffd
    80005fbe:	222080e7          	jalr	546(ra) # 800031dc <argstr>
    return -1;
    80005fc2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fc4:	0c054a63          	bltz	a0,80006098 <sys_exec+0xfa>
    80005fc8:	e3840593          	addi	a1,s0,-456
    80005fcc:	4505                	li	a0,1
    80005fce:	ffffd097          	auipc	ra,0xffffd
    80005fd2:	1ec080e7          	jalr	492(ra) # 800031ba <argaddr>
    80005fd6:	0c054163          	bltz	a0,80006098 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005fda:	10000613          	li	a2,256
    80005fde:	4581                	li	a1,0
    80005fe0:	e4040513          	addi	a0,s0,-448
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	cfc080e7          	jalr	-772(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ff0:	89a6                	mv	s3,s1
    80005ff2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ff4:	02000a13          	li	s4,32
    80005ff8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ffc:	00391513          	slli	a0,s2,0x3
    80006000:	e3040593          	addi	a1,s0,-464
    80006004:	e3843783          	ld	a5,-456(s0)
    80006008:	953e                	add	a0,a0,a5
    8000600a:	ffffd097          	auipc	ra,0xffffd
    8000600e:	0f4080e7          	jalr	244(ra) # 800030fe <fetchaddr>
    80006012:	02054a63          	bltz	a0,80006046 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006016:	e3043783          	ld	a5,-464(s0)
    8000601a:	c3b9                	beqz	a5,80006060 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	ad8080e7          	jalr	-1320(ra) # 80000af4 <kalloc>
    80006024:	85aa                	mv	a1,a0
    80006026:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000602a:	cd11                	beqz	a0,80006046 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000602c:	6605                	lui	a2,0x1
    8000602e:	e3043503          	ld	a0,-464(s0)
    80006032:	ffffd097          	auipc	ra,0xffffd
    80006036:	11e080e7          	jalr	286(ra) # 80003150 <fetchstr>
    8000603a:	00054663          	bltz	a0,80006046 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000603e:	0905                	addi	s2,s2,1
    80006040:	09a1                	addi	s3,s3,8
    80006042:	fb491be3          	bne	s2,s4,80005ff8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006046:	10048913          	addi	s2,s1,256
    8000604a:	6088                	ld	a0,0(s1)
    8000604c:	c529                	beqz	a0,80006096 <sys_exec+0xf8>
    kfree(argv[i]);
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	9aa080e7          	jalr	-1622(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006056:	04a1                	addi	s1,s1,8
    80006058:	ff2499e3          	bne	s1,s2,8000604a <sys_exec+0xac>
  return -1;
    8000605c:	597d                	li	s2,-1
    8000605e:	a82d                	j	80006098 <sys_exec+0xfa>
      argv[i] = 0;
    80006060:	0a8e                	slli	s5,s5,0x3
    80006062:	fc040793          	addi	a5,s0,-64
    80006066:	9abe                	add	s5,s5,a5
    80006068:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000606c:	e4040593          	addi	a1,s0,-448
    80006070:	f4040513          	addi	a0,s0,-192
    80006074:	fffff097          	auipc	ra,0xfffff
    80006078:	194080e7          	jalr	404(ra) # 80005208 <exec>
    8000607c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000607e:	10048993          	addi	s3,s1,256
    80006082:	6088                	ld	a0,0(s1)
    80006084:	c911                	beqz	a0,80006098 <sys_exec+0xfa>
    kfree(argv[i]);
    80006086:	ffffb097          	auipc	ra,0xffffb
    8000608a:	972080e7          	jalr	-1678(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000608e:	04a1                	addi	s1,s1,8
    80006090:	ff3499e3          	bne	s1,s3,80006082 <sys_exec+0xe4>
    80006094:	a011                	j	80006098 <sys_exec+0xfa>
  return -1;
    80006096:	597d                	li	s2,-1
}
    80006098:	854a                	mv	a0,s2
    8000609a:	60be                	ld	ra,456(sp)
    8000609c:	641e                	ld	s0,448(sp)
    8000609e:	74fa                	ld	s1,440(sp)
    800060a0:	795a                	ld	s2,432(sp)
    800060a2:	79ba                	ld	s3,424(sp)
    800060a4:	7a1a                	ld	s4,416(sp)
    800060a6:	6afa                	ld	s5,408(sp)
    800060a8:	6179                	addi	sp,sp,464
    800060aa:	8082                	ret

00000000800060ac <sys_pipe>:

uint64
sys_pipe(void)
{
    800060ac:	7139                	addi	sp,sp,-64
    800060ae:	fc06                	sd	ra,56(sp)
    800060b0:	f822                	sd	s0,48(sp)
    800060b2:	f426                	sd	s1,40(sp)
    800060b4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060b6:	ffffc097          	auipc	ra,0xffffc
    800060ba:	d58080e7          	jalr	-680(ra) # 80001e0e <myproc>
    800060be:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060c0:	fd840593          	addi	a1,s0,-40
    800060c4:	4501                	li	a0,0
    800060c6:	ffffd097          	auipc	ra,0xffffd
    800060ca:	0f4080e7          	jalr	244(ra) # 800031ba <argaddr>
    return -1;
    800060ce:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060d0:	0e054063          	bltz	a0,800061b0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060d4:	fc840593          	addi	a1,s0,-56
    800060d8:	fd040513          	addi	a0,s0,-48
    800060dc:	fffff097          	auipc	ra,0xfffff
    800060e0:	dfc080e7          	jalr	-516(ra) # 80004ed8 <pipealloc>
    return -1;
    800060e4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060e6:	0c054563          	bltz	a0,800061b0 <sys_pipe+0x104>
  fd0 = -1;
    800060ea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060ee:	fd043503          	ld	a0,-48(s0)
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	508080e7          	jalr	1288(ra) # 800055fa <fdalloc>
    800060fa:	fca42223          	sw	a0,-60(s0)
    800060fe:	08054c63          	bltz	a0,80006196 <sys_pipe+0xea>
    80006102:	fc843503          	ld	a0,-56(s0)
    80006106:	fffff097          	auipc	ra,0xfffff
    8000610a:	4f4080e7          	jalr	1268(ra) # 800055fa <fdalloc>
    8000610e:	fca42023          	sw	a0,-64(s0)
    80006112:	06054863          	bltz	a0,80006182 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006116:	4691                	li	a3,4
    80006118:	fc440613          	addi	a2,s0,-60
    8000611c:	fd843583          	ld	a1,-40(s0)
    80006120:	68a8                	ld	a0,80(s1)
    80006122:	ffffb097          	auipc	ra,0xffffb
    80006126:	550080e7          	jalr	1360(ra) # 80001672 <copyout>
    8000612a:	02054063          	bltz	a0,8000614a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000612e:	4691                	li	a3,4
    80006130:	fc040613          	addi	a2,s0,-64
    80006134:	fd843583          	ld	a1,-40(s0)
    80006138:	0591                	addi	a1,a1,4
    8000613a:	68a8                	ld	a0,80(s1)
    8000613c:	ffffb097          	auipc	ra,0xffffb
    80006140:	536080e7          	jalr	1334(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006144:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006146:	06055563          	bgez	a0,800061b0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000614a:	fc442783          	lw	a5,-60(s0)
    8000614e:	07e9                	addi	a5,a5,26
    80006150:	078e                	slli	a5,a5,0x3
    80006152:	97a6                	add	a5,a5,s1
    80006154:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006158:	fc042503          	lw	a0,-64(s0)
    8000615c:	0569                	addi	a0,a0,26
    8000615e:	050e                	slli	a0,a0,0x3
    80006160:	9526                	add	a0,a0,s1
    80006162:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006166:	fd043503          	ld	a0,-48(s0)
    8000616a:	fffff097          	auipc	ra,0xfffff
    8000616e:	a3e080e7          	jalr	-1474(ra) # 80004ba8 <fileclose>
    fileclose(wf);
    80006172:	fc843503          	ld	a0,-56(s0)
    80006176:	fffff097          	auipc	ra,0xfffff
    8000617a:	a32080e7          	jalr	-1486(ra) # 80004ba8 <fileclose>
    return -1;
    8000617e:	57fd                	li	a5,-1
    80006180:	a805                	j	800061b0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006182:	fc442783          	lw	a5,-60(s0)
    80006186:	0007c863          	bltz	a5,80006196 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000618a:	01a78513          	addi	a0,a5,26
    8000618e:	050e                	slli	a0,a0,0x3
    80006190:	9526                	add	a0,a0,s1
    80006192:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006196:	fd043503          	ld	a0,-48(s0)
    8000619a:	fffff097          	auipc	ra,0xfffff
    8000619e:	a0e080e7          	jalr	-1522(ra) # 80004ba8 <fileclose>
    fileclose(wf);
    800061a2:	fc843503          	ld	a0,-56(s0)
    800061a6:	fffff097          	auipc	ra,0xfffff
    800061aa:	a02080e7          	jalr	-1534(ra) # 80004ba8 <fileclose>
    return -1;
    800061ae:	57fd                	li	a5,-1
}
    800061b0:	853e                	mv	a0,a5
    800061b2:	70e2                	ld	ra,56(sp)
    800061b4:	7442                	ld	s0,48(sp)
    800061b6:	74a2                	ld	s1,40(sp)
    800061b8:	6121                	addi	sp,sp,64
    800061ba:	8082                	ret
    800061bc:	0000                	unimp
	...

00000000800061c0 <kernelvec>:
    800061c0:	7111                	addi	sp,sp,-256
    800061c2:	e006                	sd	ra,0(sp)
    800061c4:	e40a                	sd	sp,8(sp)
    800061c6:	e80e                	sd	gp,16(sp)
    800061c8:	ec12                	sd	tp,24(sp)
    800061ca:	f016                	sd	t0,32(sp)
    800061cc:	f41a                	sd	t1,40(sp)
    800061ce:	f81e                	sd	t2,48(sp)
    800061d0:	fc22                	sd	s0,56(sp)
    800061d2:	e0a6                	sd	s1,64(sp)
    800061d4:	e4aa                	sd	a0,72(sp)
    800061d6:	e8ae                	sd	a1,80(sp)
    800061d8:	ecb2                	sd	a2,88(sp)
    800061da:	f0b6                	sd	a3,96(sp)
    800061dc:	f4ba                	sd	a4,104(sp)
    800061de:	f8be                	sd	a5,112(sp)
    800061e0:	fcc2                	sd	a6,120(sp)
    800061e2:	e146                	sd	a7,128(sp)
    800061e4:	e54a                	sd	s2,136(sp)
    800061e6:	e94e                	sd	s3,144(sp)
    800061e8:	ed52                	sd	s4,152(sp)
    800061ea:	f156                	sd	s5,160(sp)
    800061ec:	f55a                	sd	s6,168(sp)
    800061ee:	f95e                	sd	s7,176(sp)
    800061f0:	fd62                	sd	s8,184(sp)
    800061f2:	e1e6                	sd	s9,192(sp)
    800061f4:	e5ea                	sd	s10,200(sp)
    800061f6:	e9ee                	sd	s11,208(sp)
    800061f8:	edf2                	sd	t3,216(sp)
    800061fa:	f1f6                	sd	t4,224(sp)
    800061fc:	f5fa                	sd	t5,232(sp)
    800061fe:	f9fe                	sd	t6,240(sp)
    80006200:	dcbfc0ef          	jal	ra,80002fca <kerneltrap>
    80006204:	6082                	ld	ra,0(sp)
    80006206:	6122                	ld	sp,8(sp)
    80006208:	61c2                	ld	gp,16(sp)
    8000620a:	7282                	ld	t0,32(sp)
    8000620c:	7322                	ld	t1,40(sp)
    8000620e:	73c2                	ld	t2,48(sp)
    80006210:	7462                	ld	s0,56(sp)
    80006212:	6486                	ld	s1,64(sp)
    80006214:	6526                	ld	a0,72(sp)
    80006216:	65c6                	ld	a1,80(sp)
    80006218:	6666                	ld	a2,88(sp)
    8000621a:	7686                	ld	a3,96(sp)
    8000621c:	7726                	ld	a4,104(sp)
    8000621e:	77c6                	ld	a5,112(sp)
    80006220:	7866                	ld	a6,120(sp)
    80006222:	688a                	ld	a7,128(sp)
    80006224:	692a                	ld	s2,136(sp)
    80006226:	69ca                	ld	s3,144(sp)
    80006228:	6a6a                	ld	s4,152(sp)
    8000622a:	7a8a                	ld	s5,160(sp)
    8000622c:	7b2a                	ld	s6,168(sp)
    8000622e:	7bca                	ld	s7,176(sp)
    80006230:	7c6a                	ld	s8,184(sp)
    80006232:	6c8e                	ld	s9,192(sp)
    80006234:	6d2e                	ld	s10,200(sp)
    80006236:	6dce                	ld	s11,208(sp)
    80006238:	6e6e                	ld	t3,216(sp)
    8000623a:	7e8e                	ld	t4,224(sp)
    8000623c:	7f2e                	ld	t5,232(sp)
    8000623e:	7fce                	ld	t6,240(sp)
    80006240:	6111                	addi	sp,sp,256
    80006242:	10200073          	sret
    80006246:	00000013          	nop
    8000624a:	00000013          	nop
    8000624e:	0001                	nop

0000000080006250 <timervec>:
    80006250:	34051573          	csrrw	a0,mscratch,a0
    80006254:	e10c                	sd	a1,0(a0)
    80006256:	e510                	sd	a2,8(a0)
    80006258:	e914                	sd	a3,16(a0)
    8000625a:	6d0c                	ld	a1,24(a0)
    8000625c:	7110                	ld	a2,32(a0)
    8000625e:	6194                	ld	a3,0(a1)
    80006260:	96b2                	add	a3,a3,a2
    80006262:	e194                	sd	a3,0(a1)
    80006264:	4589                	li	a1,2
    80006266:	14459073          	csrw	sip,a1
    8000626a:	6914                	ld	a3,16(a0)
    8000626c:	6510                	ld	a2,8(a0)
    8000626e:	610c                	ld	a1,0(a0)
    80006270:	34051573          	csrrw	a0,mscratch,a0
    80006274:	30200073          	mret
	...

000000008000627a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000627a:	1141                	addi	sp,sp,-16
    8000627c:	e422                	sd	s0,8(sp)
    8000627e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006280:	0c0007b7          	lui	a5,0xc000
    80006284:	4705                	li	a4,1
    80006286:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006288:	c3d8                	sw	a4,4(a5)
}
    8000628a:	6422                	ld	s0,8(sp)
    8000628c:	0141                	addi	sp,sp,16
    8000628e:	8082                	ret

0000000080006290 <plicinithart>:

void
plicinithart(void)
{
    80006290:	1141                	addi	sp,sp,-16
    80006292:	e406                	sd	ra,8(sp)
    80006294:	e022                	sd	s0,0(sp)
    80006296:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006298:	ffffc097          	auipc	ra,0xffffc
    8000629c:	b44080e7          	jalr	-1212(ra) # 80001ddc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062a0:	0085171b          	slliw	a4,a0,0x8
    800062a4:	0c0027b7          	lui	a5,0xc002
    800062a8:	97ba                	add	a5,a5,a4
    800062aa:	40200713          	li	a4,1026
    800062ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062b2:	00d5151b          	slliw	a0,a0,0xd
    800062b6:	0c2017b7          	lui	a5,0xc201
    800062ba:	953e                	add	a0,a0,a5
    800062bc:	00052023          	sw	zero,0(a0)
}
    800062c0:	60a2                	ld	ra,8(sp)
    800062c2:	6402                	ld	s0,0(sp)
    800062c4:	0141                	addi	sp,sp,16
    800062c6:	8082                	ret

00000000800062c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062c8:	1141                	addi	sp,sp,-16
    800062ca:	e406                	sd	ra,8(sp)
    800062cc:	e022                	sd	s0,0(sp)
    800062ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062d0:	ffffc097          	auipc	ra,0xffffc
    800062d4:	b0c080e7          	jalr	-1268(ra) # 80001ddc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062d8:	00d5179b          	slliw	a5,a0,0xd
    800062dc:	0c201537          	lui	a0,0xc201
    800062e0:	953e                	add	a0,a0,a5
  return irq;
}
    800062e2:	4148                	lw	a0,4(a0)
    800062e4:	60a2                	ld	ra,8(sp)
    800062e6:	6402                	ld	s0,0(sp)
    800062e8:	0141                	addi	sp,sp,16
    800062ea:	8082                	ret

00000000800062ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062ec:	1101                	addi	sp,sp,-32
    800062ee:	ec06                	sd	ra,24(sp)
    800062f0:	e822                	sd	s0,16(sp)
    800062f2:	e426                	sd	s1,8(sp)
    800062f4:	1000                	addi	s0,sp,32
    800062f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062f8:	ffffc097          	auipc	ra,0xffffc
    800062fc:	ae4080e7          	jalr	-1308(ra) # 80001ddc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006300:	00d5151b          	slliw	a0,a0,0xd
    80006304:	0c2017b7          	lui	a5,0xc201
    80006308:	97aa                	add	a5,a5,a0
    8000630a:	c3c4                	sw	s1,4(a5)
}
    8000630c:	60e2                	ld	ra,24(sp)
    8000630e:	6442                	ld	s0,16(sp)
    80006310:	64a2                	ld	s1,8(sp)
    80006312:	6105                	addi	sp,sp,32
    80006314:	8082                	ret

0000000080006316 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006316:	1141                	addi	sp,sp,-16
    80006318:	e406                	sd	ra,8(sp)
    8000631a:	e022                	sd	s0,0(sp)
    8000631c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000631e:	479d                	li	a5,7
    80006320:	06a7c963          	blt	a5,a0,80006392 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006324:	0001d797          	auipc	a5,0x1d
    80006328:	cdc78793          	addi	a5,a5,-804 # 80023000 <disk>
    8000632c:	00a78733          	add	a4,a5,a0
    80006330:	6789                	lui	a5,0x2
    80006332:	97ba                	add	a5,a5,a4
    80006334:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006338:	e7ad                	bnez	a5,800063a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000633a:	00451793          	slli	a5,a0,0x4
    8000633e:	0001f717          	auipc	a4,0x1f
    80006342:	cc270713          	addi	a4,a4,-830 # 80025000 <disk+0x2000>
    80006346:	6314                	ld	a3,0(a4)
    80006348:	96be                	add	a3,a3,a5
    8000634a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000634e:	6314                	ld	a3,0(a4)
    80006350:	96be                	add	a3,a3,a5
    80006352:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006356:	6314                	ld	a3,0(a4)
    80006358:	96be                	add	a3,a3,a5
    8000635a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000635e:	6318                	ld	a4,0(a4)
    80006360:	97ba                	add	a5,a5,a4
    80006362:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006366:	0001d797          	auipc	a5,0x1d
    8000636a:	c9a78793          	addi	a5,a5,-870 # 80023000 <disk>
    8000636e:	97aa                	add	a5,a5,a0
    80006370:	6509                	lui	a0,0x2
    80006372:	953e                	add	a0,a0,a5
    80006374:	4785                	li	a5,1
    80006376:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000637a:	0001f517          	auipc	a0,0x1f
    8000637e:	c9e50513          	addi	a0,a0,-866 # 80025018 <disk+0x2018>
    80006382:	ffffc097          	auipc	ra,0xffffc
    80006386:	43e080e7          	jalr	1086(ra) # 800027c0 <wakeup>
}
    8000638a:	60a2                	ld	ra,8(sp)
    8000638c:	6402                	ld	s0,0(sp)
    8000638e:	0141                	addi	sp,sp,16
    80006390:	8082                	ret
    panic("free_desc 1");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	4ae50513          	addi	a0,a0,1198 # 80008840 <syscalls+0x320>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a4080e7          	jalr	420(ra) # 8000053e <panic>
    panic("free_desc 2");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	4ae50513          	addi	a0,a0,1198 # 80008850 <syscalls+0x330>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	194080e7          	jalr	404(ra) # 8000053e <panic>

00000000800063b2 <virtio_disk_init>:
{
    800063b2:	1101                	addi	sp,sp,-32
    800063b4:	ec06                	sd	ra,24(sp)
    800063b6:	e822                	sd	s0,16(sp)
    800063b8:	e426                	sd	s1,8(sp)
    800063ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063bc:	00002597          	auipc	a1,0x2
    800063c0:	4a458593          	addi	a1,a1,1188 # 80008860 <syscalls+0x340>
    800063c4:	0001f517          	auipc	a0,0x1f
    800063c8:	d6450513          	addi	a0,a0,-668 # 80025128 <disk+0x2128>
    800063cc:	ffffa097          	auipc	ra,0xffffa
    800063d0:	788080e7          	jalr	1928(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063d4:	100017b7          	lui	a5,0x10001
    800063d8:	4398                	lw	a4,0(a5)
    800063da:	2701                	sext.w	a4,a4
    800063dc:	747277b7          	lui	a5,0x74727
    800063e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063e4:	0ef71163          	bne	a4,a5,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063e8:	100017b7          	lui	a5,0x10001
    800063ec:	43dc                	lw	a5,4(a5)
    800063ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063f0:	4705                	li	a4,1
    800063f2:	0ce79a63          	bne	a5,a4,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063f6:	100017b7          	lui	a5,0x10001
    800063fa:	479c                	lw	a5,8(a5)
    800063fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063fe:	4709                	li	a4,2
    80006400:	0ce79363          	bne	a5,a4,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006404:	100017b7          	lui	a5,0x10001
    80006408:	47d8                	lw	a4,12(a5)
    8000640a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000640c:	554d47b7          	lui	a5,0x554d4
    80006410:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006414:	0af71963          	bne	a4,a5,800064c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006418:	100017b7          	lui	a5,0x10001
    8000641c:	4705                	li	a4,1
    8000641e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006420:	470d                	li	a4,3
    80006422:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006424:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006426:	c7ffe737          	lui	a4,0xc7ffe
    8000642a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000642e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006430:	2701                	sext.w	a4,a4
    80006432:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006434:	472d                	li	a4,11
    80006436:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006438:	473d                	li	a4,15
    8000643a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000643c:	6705                	lui	a4,0x1
    8000643e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006440:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006444:	5bdc                	lw	a5,52(a5)
    80006446:	2781                	sext.w	a5,a5
  if(max == 0)
    80006448:	c7d9                	beqz	a5,800064d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000644a:	471d                	li	a4,7
    8000644c:	08f77d63          	bgeu	a4,a5,800064e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006450:	100014b7          	lui	s1,0x10001
    80006454:	47a1                	li	a5,8
    80006456:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006458:	6609                	lui	a2,0x2
    8000645a:	4581                	li	a1,0
    8000645c:	0001d517          	auipc	a0,0x1d
    80006460:	ba450513          	addi	a0,a0,-1116 # 80023000 <disk>
    80006464:	ffffb097          	auipc	ra,0xffffb
    80006468:	87c080e7          	jalr	-1924(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000646c:	0001d717          	auipc	a4,0x1d
    80006470:	b9470713          	addi	a4,a4,-1132 # 80023000 <disk>
    80006474:	00c75793          	srli	a5,a4,0xc
    80006478:	2781                	sext.w	a5,a5
    8000647a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000647c:	0001f797          	auipc	a5,0x1f
    80006480:	b8478793          	addi	a5,a5,-1148 # 80025000 <disk+0x2000>
    80006484:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006486:	0001d717          	auipc	a4,0x1d
    8000648a:	bfa70713          	addi	a4,a4,-1030 # 80023080 <disk+0x80>
    8000648e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006490:	0001e717          	auipc	a4,0x1e
    80006494:	b7070713          	addi	a4,a4,-1168 # 80024000 <disk+0x1000>
    80006498:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000649a:	4705                	li	a4,1
    8000649c:	00e78c23          	sb	a4,24(a5)
    800064a0:	00e78ca3          	sb	a4,25(a5)
    800064a4:	00e78d23          	sb	a4,26(a5)
    800064a8:	00e78da3          	sb	a4,27(a5)
    800064ac:	00e78e23          	sb	a4,28(a5)
    800064b0:	00e78ea3          	sb	a4,29(a5)
    800064b4:	00e78f23          	sb	a4,30(a5)
    800064b8:	00e78fa3          	sb	a4,31(a5)
}
    800064bc:	60e2                	ld	ra,24(sp)
    800064be:	6442                	ld	s0,16(sp)
    800064c0:	64a2                	ld	s1,8(sp)
    800064c2:	6105                	addi	sp,sp,32
    800064c4:	8082                	ret
    panic("could not find virtio disk");
    800064c6:	00002517          	auipc	a0,0x2
    800064ca:	3aa50513          	addi	a0,a0,938 # 80008870 <syscalls+0x350>
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	3ba50513          	addi	a0,a0,954 # 80008890 <syscalls+0x370>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	3ca50513          	addi	a0,a0,970 # 800088b0 <syscalls+0x390>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	050080e7          	jalr	80(ra) # 8000053e <panic>

00000000800064f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064f6:	7159                	addi	sp,sp,-112
    800064f8:	f486                	sd	ra,104(sp)
    800064fa:	f0a2                	sd	s0,96(sp)
    800064fc:	eca6                	sd	s1,88(sp)
    800064fe:	e8ca                	sd	s2,80(sp)
    80006500:	e4ce                	sd	s3,72(sp)
    80006502:	e0d2                	sd	s4,64(sp)
    80006504:	fc56                	sd	s5,56(sp)
    80006506:	f85a                	sd	s6,48(sp)
    80006508:	f45e                	sd	s7,40(sp)
    8000650a:	f062                	sd	s8,32(sp)
    8000650c:	ec66                	sd	s9,24(sp)
    8000650e:	e86a                	sd	s10,16(sp)
    80006510:	1880                	addi	s0,sp,112
    80006512:	892a                	mv	s2,a0
    80006514:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006516:	00c52c83          	lw	s9,12(a0)
    8000651a:	001c9c9b          	slliw	s9,s9,0x1
    8000651e:	1c82                	slli	s9,s9,0x20
    80006520:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006524:	0001f517          	auipc	a0,0x1f
    80006528:	c0450513          	addi	a0,a0,-1020 # 80025128 <disk+0x2128>
    8000652c:	ffffa097          	auipc	ra,0xffffa
    80006530:	6b8080e7          	jalr	1720(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006534:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006536:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006538:	0001db97          	auipc	s7,0x1d
    8000653c:	ac8b8b93          	addi	s7,s7,-1336 # 80023000 <disk>
    80006540:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006542:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006544:	8a4e                	mv	s4,s3
    80006546:	a051                	j	800065ca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006548:	00fb86b3          	add	a3,s7,a5
    8000654c:	96da                	add	a3,a3,s6
    8000654e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006552:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006554:	0207c563          	bltz	a5,8000657e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006558:	2485                	addiw	s1,s1,1
    8000655a:	0711                	addi	a4,a4,4
    8000655c:	25548063          	beq	s1,s5,8000679c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006560:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006562:	0001f697          	auipc	a3,0x1f
    80006566:	ab668693          	addi	a3,a3,-1354 # 80025018 <disk+0x2018>
    8000656a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000656c:	0006c583          	lbu	a1,0(a3)
    80006570:	fde1                	bnez	a1,80006548 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006572:	2785                	addiw	a5,a5,1
    80006574:	0685                	addi	a3,a3,1
    80006576:	ff879be3          	bne	a5,s8,8000656c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000657a:	57fd                	li	a5,-1
    8000657c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000657e:	02905a63          	blez	s1,800065b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006582:	f9042503          	lw	a0,-112(s0)
    80006586:	00000097          	auipc	ra,0x0
    8000658a:	d90080e7          	jalr	-624(ra) # 80006316 <free_desc>
      for(int j = 0; j < i; j++)
    8000658e:	4785                	li	a5,1
    80006590:	0297d163          	bge	a5,s1,800065b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006594:	f9442503          	lw	a0,-108(s0)
    80006598:	00000097          	auipc	ra,0x0
    8000659c:	d7e080e7          	jalr	-642(ra) # 80006316 <free_desc>
      for(int j = 0; j < i; j++)
    800065a0:	4789                	li	a5,2
    800065a2:	0097d863          	bge	a5,s1,800065b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065a6:	f9842503          	lw	a0,-104(s0)
    800065aa:	00000097          	auipc	ra,0x0
    800065ae:	d6c080e7          	jalr	-660(ra) # 80006316 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065b2:	0001f597          	auipc	a1,0x1f
    800065b6:	b7658593          	addi	a1,a1,-1162 # 80025128 <disk+0x2128>
    800065ba:	0001f517          	auipc	a0,0x1f
    800065be:	a5e50513          	addi	a0,a0,-1442 # 80025018 <disk+0x2018>
    800065c2:	ffffc097          	auipc	ra,0xffffc
    800065c6:	060080e7          	jalr	96(ra) # 80002622 <sleep>
  for(int i = 0; i < 3; i++){
    800065ca:	f9040713          	addi	a4,s0,-112
    800065ce:	84ce                	mv	s1,s3
    800065d0:	bf41                	j	80006560 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065d2:	20058713          	addi	a4,a1,512
    800065d6:	00471693          	slli	a3,a4,0x4
    800065da:	0001d717          	auipc	a4,0x1d
    800065de:	a2670713          	addi	a4,a4,-1498 # 80023000 <disk>
    800065e2:	9736                	add	a4,a4,a3
    800065e4:	4685                	li	a3,1
    800065e6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065ea:	20058713          	addi	a4,a1,512
    800065ee:	00471693          	slli	a3,a4,0x4
    800065f2:	0001d717          	auipc	a4,0x1d
    800065f6:	a0e70713          	addi	a4,a4,-1522 # 80023000 <disk>
    800065fa:	9736                	add	a4,a4,a3
    800065fc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006600:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006604:	7679                	lui	a2,0xffffe
    80006606:	963e                	add	a2,a2,a5
    80006608:	0001f697          	auipc	a3,0x1f
    8000660c:	9f868693          	addi	a3,a3,-1544 # 80025000 <disk+0x2000>
    80006610:	6298                	ld	a4,0(a3)
    80006612:	9732                	add	a4,a4,a2
    80006614:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006616:	6298                	ld	a4,0(a3)
    80006618:	9732                	add	a4,a4,a2
    8000661a:	4541                	li	a0,16
    8000661c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000661e:	6298                	ld	a4,0(a3)
    80006620:	9732                	add	a4,a4,a2
    80006622:	4505                	li	a0,1
    80006624:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006628:	f9442703          	lw	a4,-108(s0)
    8000662c:	6288                	ld	a0,0(a3)
    8000662e:	962a                	add	a2,a2,a0
    80006630:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006634:	0712                	slli	a4,a4,0x4
    80006636:	6290                	ld	a2,0(a3)
    80006638:	963a                	add	a2,a2,a4
    8000663a:	05890513          	addi	a0,s2,88
    8000663e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006640:	6294                	ld	a3,0(a3)
    80006642:	96ba                	add	a3,a3,a4
    80006644:	40000613          	li	a2,1024
    80006648:	c690                	sw	a2,8(a3)
  if(write)
    8000664a:	140d0063          	beqz	s10,8000678a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000664e:	0001f697          	auipc	a3,0x1f
    80006652:	9b26b683          	ld	a3,-1614(a3) # 80025000 <disk+0x2000>
    80006656:	96ba                	add	a3,a3,a4
    80006658:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000665c:	0001d817          	auipc	a6,0x1d
    80006660:	9a480813          	addi	a6,a6,-1628 # 80023000 <disk>
    80006664:	0001f517          	auipc	a0,0x1f
    80006668:	99c50513          	addi	a0,a0,-1636 # 80025000 <disk+0x2000>
    8000666c:	6114                	ld	a3,0(a0)
    8000666e:	96ba                	add	a3,a3,a4
    80006670:	00c6d603          	lhu	a2,12(a3)
    80006674:	00166613          	ori	a2,a2,1
    80006678:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000667c:	f9842683          	lw	a3,-104(s0)
    80006680:	6110                	ld	a2,0(a0)
    80006682:	9732                	add	a4,a4,a2
    80006684:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006688:	20058613          	addi	a2,a1,512
    8000668c:	0612                	slli	a2,a2,0x4
    8000668e:	9642                	add	a2,a2,a6
    80006690:	577d                	li	a4,-1
    80006692:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006696:	00469713          	slli	a4,a3,0x4
    8000669a:	6114                	ld	a3,0(a0)
    8000669c:	96ba                	add	a3,a3,a4
    8000669e:	03078793          	addi	a5,a5,48
    800066a2:	97c2                	add	a5,a5,a6
    800066a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066a6:	611c                	ld	a5,0(a0)
    800066a8:	97ba                	add	a5,a5,a4
    800066aa:	4685                	li	a3,1
    800066ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066ae:	611c                	ld	a5,0(a0)
    800066b0:	97ba                	add	a5,a5,a4
    800066b2:	4809                	li	a6,2
    800066b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066b8:	611c                	ld	a5,0(a0)
    800066ba:	973e                	add	a4,a4,a5
    800066bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066c8:	6518                	ld	a4,8(a0)
    800066ca:	00275783          	lhu	a5,2(a4)
    800066ce:	8b9d                	andi	a5,a5,7
    800066d0:	0786                	slli	a5,a5,0x1
    800066d2:	97ba                	add	a5,a5,a4
    800066d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800066d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066dc:	6518                	ld	a4,8(a0)
    800066de:	00275783          	lhu	a5,2(a4)
    800066e2:	2785                	addiw	a5,a5,1
    800066e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066ec:	100017b7          	lui	a5,0x10001
    800066f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066f4:	00492703          	lw	a4,4(s2)
    800066f8:	4785                	li	a5,1
    800066fa:	02f71163          	bne	a4,a5,8000671c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800066fe:	0001f997          	auipc	s3,0x1f
    80006702:	a2a98993          	addi	s3,s3,-1494 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006706:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006708:	85ce                	mv	a1,s3
    8000670a:	854a                	mv	a0,s2
    8000670c:	ffffc097          	auipc	ra,0xffffc
    80006710:	f16080e7          	jalr	-234(ra) # 80002622 <sleep>
  while(b->disk == 1) {
    80006714:	00492783          	lw	a5,4(s2)
    80006718:	fe9788e3          	beq	a5,s1,80006708 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000671c:	f9042903          	lw	s2,-112(s0)
    80006720:	20090793          	addi	a5,s2,512
    80006724:	00479713          	slli	a4,a5,0x4
    80006728:	0001d797          	auipc	a5,0x1d
    8000672c:	8d878793          	addi	a5,a5,-1832 # 80023000 <disk>
    80006730:	97ba                	add	a5,a5,a4
    80006732:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006736:	0001f997          	auipc	s3,0x1f
    8000673a:	8ca98993          	addi	s3,s3,-1846 # 80025000 <disk+0x2000>
    8000673e:	00491713          	slli	a4,s2,0x4
    80006742:	0009b783          	ld	a5,0(s3)
    80006746:	97ba                	add	a5,a5,a4
    80006748:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000674c:	854a                	mv	a0,s2
    8000674e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006752:	00000097          	auipc	ra,0x0
    80006756:	bc4080e7          	jalr	-1084(ra) # 80006316 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000675a:	8885                	andi	s1,s1,1
    8000675c:	f0ed                	bnez	s1,8000673e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000675e:	0001f517          	auipc	a0,0x1f
    80006762:	9ca50513          	addi	a0,a0,-1590 # 80025128 <disk+0x2128>
    80006766:	ffffa097          	auipc	ra,0xffffa
    8000676a:	532080e7          	jalr	1330(ra) # 80000c98 <release>
}
    8000676e:	70a6                	ld	ra,104(sp)
    80006770:	7406                	ld	s0,96(sp)
    80006772:	64e6                	ld	s1,88(sp)
    80006774:	6946                	ld	s2,80(sp)
    80006776:	69a6                	ld	s3,72(sp)
    80006778:	6a06                	ld	s4,64(sp)
    8000677a:	7ae2                	ld	s5,56(sp)
    8000677c:	7b42                	ld	s6,48(sp)
    8000677e:	7ba2                	ld	s7,40(sp)
    80006780:	7c02                	ld	s8,32(sp)
    80006782:	6ce2                	ld	s9,24(sp)
    80006784:	6d42                	ld	s10,16(sp)
    80006786:	6165                	addi	sp,sp,112
    80006788:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000678a:	0001f697          	auipc	a3,0x1f
    8000678e:	8766b683          	ld	a3,-1930(a3) # 80025000 <disk+0x2000>
    80006792:	96ba                	add	a3,a3,a4
    80006794:	4609                	li	a2,2
    80006796:	00c69623          	sh	a2,12(a3)
    8000679a:	b5c9                	j	8000665c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000679c:	f9042583          	lw	a1,-112(s0)
    800067a0:	20058793          	addi	a5,a1,512
    800067a4:	0792                	slli	a5,a5,0x4
    800067a6:	0001d517          	auipc	a0,0x1d
    800067aa:	90250513          	addi	a0,a0,-1790 # 800230a8 <disk+0xa8>
    800067ae:	953e                	add	a0,a0,a5
  if(write)
    800067b0:	e20d11e3          	bnez	s10,800065d2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067b4:	20058713          	addi	a4,a1,512
    800067b8:	00471693          	slli	a3,a4,0x4
    800067bc:	0001d717          	auipc	a4,0x1d
    800067c0:	84470713          	addi	a4,a4,-1980 # 80023000 <disk>
    800067c4:	9736                	add	a4,a4,a3
    800067c6:	0a072423          	sw	zero,168(a4)
    800067ca:	b505                	j	800065ea <virtio_disk_rw+0xf4>

00000000800067cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067cc:	1101                	addi	sp,sp,-32
    800067ce:	ec06                	sd	ra,24(sp)
    800067d0:	e822                	sd	s0,16(sp)
    800067d2:	e426                	sd	s1,8(sp)
    800067d4:	e04a                	sd	s2,0(sp)
    800067d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067d8:	0001f517          	auipc	a0,0x1f
    800067dc:	95050513          	addi	a0,a0,-1712 # 80025128 <disk+0x2128>
    800067e0:	ffffa097          	auipc	ra,0xffffa
    800067e4:	404080e7          	jalr	1028(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067e8:	10001737          	lui	a4,0x10001
    800067ec:	533c                	lw	a5,96(a4)
    800067ee:	8b8d                	andi	a5,a5,3
    800067f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067f6:	0001f797          	auipc	a5,0x1f
    800067fa:	80a78793          	addi	a5,a5,-2038 # 80025000 <disk+0x2000>
    800067fe:	6b94                	ld	a3,16(a5)
    80006800:	0207d703          	lhu	a4,32(a5)
    80006804:	0026d783          	lhu	a5,2(a3)
    80006808:	06f70163          	beq	a4,a5,8000686a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000680c:	0001c917          	auipc	s2,0x1c
    80006810:	7f490913          	addi	s2,s2,2036 # 80023000 <disk>
    80006814:	0001e497          	auipc	s1,0x1e
    80006818:	7ec48493          	addi	s1,s1,2028 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000681c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006820:	6898                	ld	a4,16(s1)
    80006822:	0204d783          	lhu	a5,32(s1)
    80006826:	8b9d                	andi	a5,a5,7
    80006828:	078e                	slli	a5,a5,0x3
    8000682a:	97ba                	add	a5,a5,a4
    8000682c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000682e:	20078713          	addi	a4,a5,512
    80006832:	0712                	slli	a4,a4,0x4
    80006834:	974a                	add	a4,a4,s2
    80006836:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000683a:	e731                	bnez	a4,80006886 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000683c:	20078793          	addi	a5,a5,512
    80006840:	0792                	slli	a5,a5,0x4
    80006842:	97ca                	add	a5,a5,s2
    80006844:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006846:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000684a:	ffffc097          	auipc	ra,0xffffc
    8000684e:	f76080e7          	jalr	-138(ra) # 800027c0 <wakeup>

    disk.used_idx += 1;
    80006852:	0204d783          	lhu	a5,32(s1)
    80006856:	2785                	addiw	a5,a5,1
    80006858:	17c2                	slli	a5,a5,0x30
    8000685a:	93c1                	srli	a5,a5,0x30
    8000685c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006860:	6898                	ld	a4,16(s1)
    80006862:	00275703          	lhu	a4,2(a4)
    80006866:	faf71be3          	bne	a4,a5,8000681c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000686a:	0001f517          	auipc	a0,0x1f
    8000686e:	8be50513          	addi	a0,a0,-1858 # 80025128 <disk+0x2128>
    80006872:	ffffa097          	auipc	ra,0xffffa
    80006876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
}
    8000687a:	60e2                	ld	ra,24(sp)
    8000687c:	6442                	ld	s0,16(sp)
    8000687e:	64a2                	ld	s1,8(sp)
    80006880:	6902                	ld	s2,0(sp)
    80006882:	6105                	addi	sp,sp,32
    80006884:	8082                	ret
      panic("virtio_disk_intr status");
    80006886:	00002517          	auipc	a0,0x2
    8000688a:	04a50513          	addi	a0,a0,74 # 800088d0 <syscalls+0x3b0>
    8000688e:	ffffa097          	auipc	ra,0xffffa
    80006892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>

0000000080006896 <cas>:
    80006896:	100522af          	lr.w	t0,(a0)
    8000689a:	00b29563          	bne	t0,a1,800068a4 <fail>
    8000689e:	18c5252f          	sc.w	a0,a2,(a0)
    800068a2:	8082                	ret

00000000800068a4 <fail>:
    800068a4:	4505                	li	a0,1
    800068a6:	8082                	ret
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
